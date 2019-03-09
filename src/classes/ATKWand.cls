/**
 * Apex Test Kit
 */
public with sharing class ATKWand {
    private static final ATKCommon.MethodParser METHOD_PARSER = ATKCommon.METHOD_PARSER;
    private static final ParamEvaluator PARAM_EVALUATOR = new ParamEvaluator();

    private static final ISchemator SCHEMATOR = new FieldSchemator(); // have state
    private static final IEvaluator EVALUATOR = new FieldEvaluator(); // have state
    private static final IValidator VALIDATOR = new NodeValidator();  // pure func
    private static final IGenerator GENERATOR = new NodeGenerator();  // pure func
    private static final Distributor DISTRIBUTOR = new Distributor(); // pure func

    private Boolean inMemory { get; set; }

    public void register(ATKSpellBook spellBook) {

    }

    public void generate(ATKSpellBook spellBook, Boolean inMemory) {
        this.inMemory = inMemory;
        SCHEMATOR.build(spellBook);
        VALIDATOR.validate(spellBook);
        GENERATOR.generate(spellBook);
    }

    interface ISchemator {
        void build(ATKSpellBook spellBook);
        String getReferenceFieldName(String objectName, String referenceTypeName);
        String getReferenceFieldType(String objectName, String referenceFieldName);
        Boolean isGeolocationField(Schema.DescribeSObjectResult dsr, Schema.DescribeFieldResult dfr);
        Boolean isAddressField(Schema.DescribeSObjectResult dsr, Schema.DescribeFieldResult dfr);
    }

    interface IValidator {
        void validate(ATKSpellBook spellBook);
    }

    interface IGenerator {
        void generate(ATKSpellBook spellBook);
    }

    interface IEvaluator {
        Object evaluate(Integer recordIndex, EntityNode entityNode, EntityField entityField, Integer depth);
    }

    class FieldSchemator implements ISchemator {
        private Map<String, Set<String>> addressFieldCache { get; set; }
        private Map<String, Set<String>> geolocationFieldCache { get; set; }
        private Map<String, Map<String, String>> referenceFieldNameByTypeCache { get; set; }
        private Map<String, Map<String, String>> referenceFieldTypeByNameCache { get; set; }

        @TestVisible
        FieldSchemator() {
            addressFieldCache = new Map<String, Set<String>>();
            geolocationFieldCache = new Map<String, Set<String>>();
            referenceFieldNameByTypeCache = new Map<String, Map<String, String>>();
            referenceFieldTypeByNameCache = new Map<String, Map<String, String>>();
        }

        public void build(ATKSpellBook spellBook) {
            Iterator<EntityNode> iterator = spellBook.iterator();
            while (iterator.hasNext()) {
                EntityNode entityNode = iterator.next();
                entityNode.xrefFieldCache.sort();
                buildFieldCaches(entityNode);
            }
        }

        void buildFieldCaches(EntityNode entityNode) {
            Schema.SObjectType objectType = entityNode.objectType;
            Schema.DescribeSObjectResult dsr = entityNode.dsr;
            String objectName = entityNode.name;

            Set<String> addressFieldSet;
            Set<String> geolocationFieldSet;
            Map<String, String> referenceFieldNameMap;
            Map<String, String> referenceFieldTypeMap;
            if (addressFieldCache.get(objectName) == null) {
                addressFieldSet = new Set<String>();
                addressFieldCache.put(objectName, addressFieldSet);

                geolocationFieldSet = new Set<String> {};
                geolocationFieldCache.put(objectName, geolocationFieldSet);

                referenceFieldNameMap = new Map<String, String>();
                referenceFieldNameByTypeCache.put(objectName, referenceFieldNameMap);

                referenceFieldTypeMap = new Map<String, String>();
                referenceFieldTypeByNameCache.put(objectName, referenceFieldTypeMap);
            }

            for (Schema.SObjectField field : dsr.fields.getMap().values()) {
                Schema.DescribeFieldResult dfr = field.getDescribe();
                String fieldName = dfr.getName();

                // System.debug(objectName + '.' + fieldName
                //     + ' : isNillable(' + dfr.isNillable()
                //     + '), precision(' + dfr.getPrecision()
                //     + '), scale(' + dfr.getScale()
                //     + '), type(' + dfr.getType()
                //     + ')');

                if (entityNode.guardEnabled
                    && !dfr.isNillable()
                    && isEditableField(dfr)
                    && !entityNode.evalFieldMap.containsKey(field)
                    && !entityNode.xrefFieldMap.containsKey(field)) {
                    entityNode.evalFieldCache.add(new EvalEntityField(field, true));
                }

                // no need to rebuild static caches
                if (addressFieldSet != null) {
                    Schema.DisplayType fieldType = dfr.getType();
                    if (fieldType == Schema.DisplayType.ADDRESS) { // TODO: check camel case names
                        String addressPrefix = dfr.getName().replace('ADDRESS', '');
                        addressFieldSet.add(addressPrefix + 'STREET');
                        addressFieldSet.add(addressPrefix + 'CITY');
                        addressFieldSet.add(addressPrefix + 'STATE');
                        addressFieldSet.add(addressPrefix + 'POSTALCODE');
                        addressFieldSet.add(addressPrefix + 'COUNTRY');
                        addressFieldSet.add(addressPrefix + 'LATITUDE');
                        addressFieldSet.add(addressPrefix + 'LONGITUDE');
                        addressFieldSet.add(addressPrefix + 'GEOCODEACCURACY');
                    } else if (fieldName == 'LONGITUDE' || fieldName == 'LATITUDE' ) {
                        // add standard geolocation field
                        geolocationFieldSet.add(fieldName);
                    } else if (fieldName.endsWith('__LATITUDE__S')) {
                        // add custom geolocation field
                        geolocationFieldSet.add(fieldName.replace('__LATITUDE__S', '__C'));
                    } else if (fieldType == Schema.DisplayType.REFERENCE) {
                        for (Schema.SObjectType rst : dfr.getReferenceTo()) {
                            String toRefType = rst.getDescribe().getName();
                            String fromRefField = dfr.getName();
                            referenceFieldNameMap.put(toRefType, fromRefField);
                            referenceFieldTypeMap.put(fromRefField, toRefType);
                        }
                    }
                }
            }
        }

        public String getReferenceFieldName(String objectName, String referenceTypeName) {
            return referenceFieldNameByTypeCache.get(objectName).get(referenceTypeName);
        }

        public String getReferenceFieldType(String objectName, String referenceFieldName) {
            return referenceFieldTypeByNameCache.get(objectName).get(referenceFieldName);
        }

        public Boolean isGeolocationField(Schema.DescribeSObjectResult dsr, Schema.DescribeFieldResult dfr) {
            Set<String> geolocationFieldSet = geolocationFieldCache.get(dsr.getName());
            return geolocationFieldSet.contains(dfr.getName().toUpperCase());
        }

        public Boolean isAddressField(Schema.DescribeSObjectResult dsr, Schema.DescribeFieldResult dfr) {
            Set<String> addressFieldSet = addressFieldCache.get(dsr.getName());
            return addressFieldSet.contains(dfr.getName().toUpperCase());
        }

        Boolean isEditableField(Schema.DescribeFieldResult dfr) {
            String fieldName = dfr.getName().toUpperCase();
            return !(!dfr.isCreateable()
                || dfr.isCalculated()
                || dfr.isAutoNumber()
                || dfr.getType() == Schema.DisplayType.REFERENCE
                || fieldName == 'CREATEDDATE'
                || fieldName == 'LASTMODIFIEDDATE'
                || fieldName == 'CLEANSTATUS'  // Used by Database.com
                || fieldName == 'JIGSAW'       // Used by Database.com
            );
        }
    }

    @TestVisible
    class NodeValidator implements IValidator {
        public void validate(ATKSpellBook spellBook) {
            Iterator<EntityNode> iterator = spellBook.iterator();
            while (iterator.hasNext()) {
                EntityNode entityNode = iterator.next();
                validateTotalAndList(entityNode);
                validateRelationship(entityNode);
                validateXrefFields(entityNode);
            }
        }

        @TestVisible
        void validateTotalAndList(EntityNode entityNode) {
            if ((entityNode.total == null || entityNode.total == 0) &&
                (entityNode.repository == null || entityNode.repository.size() == 0)
            ) {
                throw new ATKCommon.InsufficientAttributeException(
                    String.format('Please set either total() or fromList() for sObject type {0}.',
                    new List<String> { entityNode.name }));
            }
        }

        @TestVisible
        void validateRelationship(EntityNode entityNode) {
            if (entityNode.referenceToMap != null && entityNode.referenceToMap.size() > 0) {
                for (String fieldName : entityNode.referenceToMap.keySet()) {
                    EntityNode referenceTo = entityNode.referenceToMap.get(fieldName);
                    if (fieldName != referenceTo.Name) {
                        String type = SCHEMATOR.getReferenceFieldType(entityNode.name, fieldName);
                        if (type == null || type != referenceTo.name) {
                            throw new ATKCommon.NotFoundException(
                                String.format('The relationship field {0}.{1} to entity {2} doesn\'t exist.',
                                new List<String> { entityNode.name, fieldName, referenceTo.name }));
                        }
                    } else {
                        autoDetectReferenceFieldName(entityNode, referenceTo);
                    }
                }
            }
        }

        void autoDetectReferenceFieldName(EntityNode entityNode, EntityNode referenceTo) {
            String fieldName = SCHEMATOR.getReferenceFieldName(entityNode.name, referenceTo.name);
            if (fieldName == null) {
                throw new ATKCommon.IncorrectTypeException(
                    String.format('The relationship field {0}.{1} to entity {2} doesn\'t exist.',
                    new List<String> { entityNode.name, referenceTo.name, referenceTo.name }));
            }
            entityNode.referenceToMap.remove(referenceTo.name);
            entityNode.referenceToMap.put(fieldName, referenceTo);
        }

        @TestVisible
        void validateXrefFields(EntityNode entityNode) {
            for (XrefEntityField field : entityNode.xrefFieldCache) {
                if (0 < field.method.level) {
                    for (ATKCommon.XrefParam param : field.method.xrefParams) {
                        if (0 < param.level && field.origin == null) {
                            throw new ATKCommon.NotFoundException(
                                String.format('The cross reference field {0}.{1} must have a corresponding'
                                    + ' eval({0}.{1}).value() or eval({0}.{1}).repeat() to specify its initial values.',
                                new List<String> { entityNode.Name, field.name })
                            );
                        }
                    }
                }
            }
        }
    }

    class NodeGenerator implements IGenerator {
        public void generate(ATKSpellBook spellBook) {
            Iterator<EntityNode> iterator = spellBook.iterator();
            while (iterator.hasNext()) {
                EntityNode entityNode = iterator.next();
                if (entityNode.repository.size() == 0) {
                    Schema.SObjectType objectType = entityNode.objectType;
                    if (entityNode.repository.size() == 0) {
                        for (Integer i = 0; i < entityNode.total; i++) {
                            SObject obj = objectType.newSObject();
                            entityNode.repository.add(obj);
                        }
                    }
                    updateObjects(entityNode);
                    assignReferences(entityNode);
                    Database.insert(entityNode.repository);
                } else {
                    updateObjects(entityNode);
                    assignReferences(entityNode);

                    // upsert doesn't work on list of generic sObject types
                    List<SObject> updateList = new List<SObject>();
                    List<SObject> insertList = new List<SObject>();
                    for (SObject obj : entityNode.repository) {
                        if (obj.Id == null) {
                            insertList.add(obj);
                        } else {
                            updateList.add(obj);
                        }
                    }
                    if (updateList.size() > 0) {
                        Database.update(updateList);
                    }
                    if (insertList.size() > 0) {
                        Database.insert(insertList);
                    }
                }
            }
        }

        void updateObjects(EntityNode entityNode) {
            Schema.SObjectType objectType = entityNode.objectType;
            Schema.DescribeSObjectResult dsr = entityNode.dsr;

            List<SObject> repository = entityNode.repository;
            Integer total = repository.size();
            for (EntityField entityField : entityNode.evalFieldCache) {
                for (Integer i = 0; i < total; i++) {
                    Object value = EVALUATOR.evaluate(i, entityNode, entityField, 10);
                    if (value != null) {
                        SObject record = repository[i];
                        record.put(entityField.name, value);
                    }
                }
            }

            for (Integer i = 0; i < total; i++) {
               for (EntityField entityField : entityNode.xrefFieldCache) {
                    Object value = EVALUATOR.evaluate(i, entityNode, entityField, 10);
                    if (value != null) {
                        SObject record = repository[i];
                        record.put(entityField.name, value);
                    }
                }
            }
        }

        void assignReferences(EntityNode entityNode) {
            if (entityNode.referenceToMap != null
                && entityNode.referenceToMap.size() > 0
                && entityNode.repository != null) {

                List<String> fieldNames = new List<String>(entityNode.referenceToMap.keySet());
                List<SObject> childObjectList = entityNode.repository;

                if (fieldNames.size() >= 2) {
                    List<SObject> leftGroup = entityNode.referenceToMap.get(fieldNames[0]).repository;
                    List<SObject> rightGroup = entityNode.referenceToMap.get(fieldNames[1]).repository;
                    List<List<Object>> pairs = DISTRIBUTOR.product2(leftGroup, rightGroup, entityNode.total);
                    Integer childCount = entityNode.total;
                    Integer pairCount = pairs.size();
                    for (Integer i = 0; i < childCount && i < pairCount; i++) {
                        SObject child = childObjectList[i];
                        SObject left = (SObject)pairs[i][0];
                        SObject right = (SObject)pairs[i][1];
                        child.put(fieldNames[0], left.Id);
                        child.put(fieldNames[1], right.Id);
                    }
                } else {
                    List<SObject> parentObjectList = entityNode.referenceToMap.get(fieldNames[0]).repository;
                    for (List<Object> pair : DISTRIBUTOR.distribute(childObjectList, parentObjectList)) {
                        if (pair.size() == 2) {
                            SObject child = (SObject)pair[0];
                            SObject parent = (SObject)pair[1];
                            if (child != null && parent != null) {
                                child.put(fieldNames[0], parent.Id);
                            }
                        }
                    }
                }
            }
        }
    }

    @TestVisible
    class FieldEvaluator implements IEvaluator {
        private Map<String, List<String>> picklistCache { get; set; }
        private Map<String, Set<Object>> uniqueValueCache { get; set; }
        private List<String> UNIQUE_VALUE_FORMATS { get; set; }

        @TestVisible
        FieldEvaluator() {
            picklistCache = new Map<String, List<String>>();
            uniqueValueCache = new Map<String, Set<Object>>();
            UNIQUE_VALUE_FORMATS = new List<String> {
                '{{?}}',
                '{{?*}}',
                '{{?**}}',
                '{{?***}}',
                '{{?****}}',
                '{{?*****}}'
            };
        }

        public Object evaluate(Integer recordIndex, EntityNode entityNode, EntityField entityField, Integer depth) {
            DescribeSObjectResult dsr = entityNode.dsr;
            Schema.DescribeFieldResult dfr = entityField.dfr;
            Boolean isUnique = dfr.isUnique();
            String key = dsr.getName() + '.' + dfr.getName();

            // if (SCHEMATOR.isGeolocationField(dsr, dfr)) {
            //     return null;
            // }

            if (isUnique && uniqueValueCache.get(key) == null) {
                uniqueValueCache.put(key, new Set<Object>());
            }

            Object value;
            if (isUnique) {
                for (Integer j = 0; j < depth; j++) {
                    value = getValue(recordIndex, entityNode, entityField);
                    if (value == null) {
                        break;
                    } else if (!uniqueValueCache.get(key).contains(value)) {
                        uniqueValueCache.get(key).add(value);
                        break;
                    }

                    if (j + 1 == depth) {
                        throw new ATKCommon.DeepRecursionException(String.format(
                            'Please assign ATKFaker interpolation expression for field {0}.{1} to enforce uniqueness, i.e. {{******}}',
                            new List<String> { dsr.getName(), dfr.getName() }
                        ));
                    }
                }
            } else {
                value = getValue(recordIndex, entityNode, entityField);
            }

            switch on dfr.getType() {
                when DATE {
                    value = ATKCommon.converter.toDate(value);
                }
                when TIME {
                    value = ATKCommon.converter.toTime(value);
                }
                when INTEGER {
                    value = ATKCommon.converter.toInteger(value);
                }
            }
            return value;
        }

        public Object getValue(Integer recordIndex, EntityNode entityNode, EntityField entityField) {
            DescribeSObjectResult dsr = entityNode.dsr;
            Schema.DescribeFieldResult dfr = entityField.dfr;
            Object value;
            if (entityField.needGuess) {
                value = guessValue(dsr, dfr);
            } else {
                PARAM_EVALUATOR.entityNode = entityNode;
                value = entityField.getValue(recordIndex);
            }
            return value;
        }

        Object guessValue(Schema.DescribeSObjectResult dsr, Schema.DescribeFieldResult dfr) {
            // if (SCHEMATOR.isAddressField(dsr, dfr)) {
            //     return null;
            // }

            Object value;
            switch on dfr.getType() {
                when BOOLEAN {
                    value = ATKFaker.random.boolean();
                }
                when DATE {
                    value = ATKFaker.dates.past();
                }
                when DATETIME {
                    value = ATKFaker.dates.past();
                }
                when TIME {
                    value = ATKFaker.dates.past();
                }
                when DOUBLE {
                    String fieldName = dfr.getName().toUpperCase();
                    if (fieldName.endsWith('__LATITUDE__S')) {
                        value = ATKFaker.random.number(-90, 90, dfr.getScale());
                    } else if (fieldName.endsWith('__LONGITUDE__S')) {
                        value = ATKFaker.random.number(-180, 180, dfr.getScale());
                    } else {
                        value = ATKFaker.random.number(dfr.getPrecision(), dfr.getScale());
                    }
                }
                when INTEGER {
                    value = ATKFaker.random.number(dfr.getDigits(), 0);
                }
                when PERCENT {
                    value = ATKFaker.random.number(0, 1, 2);
                }
                when CURRENCY {
                    value = ATKFaker.random.number(dfr.getPrecision(), dfr.getScale());
                }
                when PICKLIST {
                    value = (String)ATKFaker.random.arrayElement(getPicklistValues(dsr, dfr));
                }
                when MULTIPICKLIST {
                    List<String> values = (List<String>)ATKFaker.random.arrayElements(getPicklistValues(dsr, dfr));
                    value = '';
                    for (Integer i = 0; i < values.size();) {
                        value += values[i];
                        i++;
                        if (i != values.size()) {
                            value += ';';
                        }
                    }
                }
                when STRING {
                    Integer length = dfr.getLength();
                    if (dfr.isUnique()) {
                        Integer count = length > 6 ? 6 : length;
                        value = ATKFaker.fake(UNIQUE_VALUE_FORMATS[count - 1]);
                    } else {
                        Integer count = length / 5;
                        count = count > 6 ? 6 : count;
                        String output = ATKFaker.lorem.words(count);
                        if (String.isNotEmpty(output) && output.length() > length) {
                            output = output.left(length);
                        }
                        value = output;
                    }
                }
                when TEXTAREA {
                    String output = ATKFaker.lorem.words();
                    Integer length = dfr.getLength();
                    if (String.isNotEmpty(output) && output.length() > length) {
                        output = output.left(length);
                    }
                    value = output;
                }
                when EMAIL {
                    value = ATKFaker.internet.email();
                }
                when URL {
                    value = ATKFaker.internet.url();
                }
                when PHONE {
                    value = ATKFaker.phone.phoneNumber();
                }
                when ADDRESS {

                }
                when LOCATION {

                }
                when else {

                }
            }
            return value;
        }

        List<String> getPicklistValues(
            Schema.DescribeSObjectResult dsr,
            Schema.DescribeFieldResult dfr) {

            String key = dsr.getName() + '.' + dfr.getName();
            if (picklistCache.get(key) == null) {
                List<Schema.PicklistEntry> picklistEntries = dfr.getPicklistValues();
                List<String> values = new List<String>();
                for (Schema.PicklistEntry entry : picklistEntries) {
                    if (entry.isActive()) {
                        // System.debug('PickList(' + key + '): label(' + entry.getLabel() + '), value(' + entry.getValue() + ')');
                        values.add(entry.getValue());
                    }
                }
                picklistCache.put(key, values);
            }
            return picklistCache.get(key);
        }
    }

    @TestVisible
    class Distributor {
        @TestVisible
        List<List<Object>> product(List<Object> leftGroup, List<Object> rightGroup, Integer lmt) {
            List<List<Object>> groups = new List<List<Object>>();
            if (leftGroup == null || leftGroup.size() == 0 || rightGroup == null || rightGroup.size() == 0) {
                return groups;
            }

            Integer l = leftGroup.size();
            Integer r = rightGroup.size();
            lmt = lmt > l * r ? l * r : lmt;
            Integer s = lmt / r;
            Integer remainder = Math.mod(lmt, r);

            /*
             * Balanced Set Production
             * { A, B, C } X { 1, 2 }; l = 3, r = 2, lmt = 2, s = 2, remainder = 1
             *            ↓↓↓
             *           A - 1
             *           A - 2
             *           B - 1
             *           B - 2
             *           C - 1
             *           C - 2
             */
            for (Integer i = 0; i < l; i++) {
                for (Integer j = 0; j < r; j++) {
                    if (i < remainder) {
                        if (j > s) {
                            break;
                        }
                    } else {
                        if (j >= s) {
                            break;
                        }
                    }
                    groups.add(new List<Object>{
                        leftGroup[i], rightGroup[j]
                    });
                }
            }
            return groups;
        }

        @TestVisible
        List<List<Object>> product2(List<Object> leftGroup, List<Object> rightGroup, Integer lmt) {
            List<List<Object>> groups = new List<List<Object>>();
            if (leftGroup == null || leftGroup.size() == 0 || rightGroup == null || rightGroup.size() == 0) {
                return groups;
            }

            Integer l = leftGroup.size();
            Integer r = rightGroup.size();
            lmt = lmt > l * r ? l * r : lmt;
            Integer s = lmt / r;
            Integer remainder = Math.mod(lmt, r);

            /*
             * Balanced Set Production
             * { A, B, C } X { 1, 2 }
             *            ↓↓↓
             *           A - 1
             *           B - 2
             *           C - 1
             *           A - 2
             *           B - 1
             *           C - 2
             */
            for (Integer i = 0, j = 0; i < lmt; i++) {
                if (Math.mod(i, l) == 0) {
                    j = i / l;
                } else {
                    j++;
                    if (j == r) {
                        j = 0;
                    }
                }
                groups.add(new List<Object>{
                    leftGroup[Math.mod(i, l)], rightGroup[j]
                });
            }
            return groups;
        }

        @TestVisible
        List<List<Object>> distribute(List<Object> leftGroup, List<Object> rightGroup) {
            List<List<Object>> groups = new List<List<Object>>();
            if (leftGroup == null || leftGroup.size() == 0 || rightGroup == null || rightGroup.size() == 0) {
                return groups;
            }

            Integer l = leftGroup.size();
            Integer r = rightGroup.size();
            Integer s = l / r;
            Integer remainder = Math.mod(l, r);

            /*
             * Balanced Set Distribution
             * { i0, i1, i2, i3, i4 } => { j0, j1 }; then s = 2, reminder = 1
             *                       ↓↓↓
             *                     i0 - j0
             *                     i1 - j0
             *                     i2 - j0
             *                     i3 - j1
             *                     i4 - j1
             */
            for (Integer i = 0, j = 0; i < l; i++) {
                if (j < remainder) {
                    j = i / (s + 1);
                } else {
                    j = (i - remainder) / s;
                }
                groups.add(new List<Object>{
                    leftGroup[i], rightGroup[j]
                });
            }
            return groups;
        }
    }

    private class Bag implements ATKCommon.IBag {
        private Map<Schema.SObjectType, List<SObject>> repositoryByType { get; set; }

        Bag() {
            repositoryByType = new Map<Schema.SObjectType, List<SObject>>();
        }

        public List<SObject> get(Schema.SObjectType objectType) {
            return repositoryByType.get(objectType);
        }
    }

    public class ATKSpellBook implements Iterable<EntityNode> {
        @TestVisible
        private EntityNodeMatrix matrix { get; private set; }

        {
            matrix = new EntityNodeMatrix();
        }

        public Iterator<EntityNode> iterator() {
            this.matrix.reset();
            return matrix;
        }

        public void attach(EntityNode entityNode) {
            this.matrix.add(entityNode);
        }

        public void apply(IAttribute attribute) {
            if (attribute instanceOf IEntityAttribute) {
                ((IEntityAttribute)attribute).apply(this.matrix.currentEntityNode);
            } else if (attribute instanceOf IEvalFieldAttribute) {
                ((IEvalFieldAttribute)attribute).apply(this.matrix.currentEntityNode,
                (EvalEntityField)this.matrix.currentEntityNode.currentEntityField);
            } else if (attribute instanceOf IXrefFieldAttribute) {
                ((IXrefFieldAttribute)attribute).apply(this.matrix.currentEntityNode,
                (XrefEntityField)this.matrix.currentEntityNode.currentEntityField);
            }
        }

        public void pop(Integer depth) {
            this.matrix.pop(depth);
        }

        public ATKCommon.IBag toBag() {
            Iterator<EntityNode> iterator = iterator();
            Bag bag = new Bag();
            while(iterator.hasNext()) {
                EntityNode entityNode = iterator.next();
                if (!bag.repositoryByType.containsKey(entityNode.objectType)) {
                    bag.repositoryByType.put(entityNode.objectType, entityNode.repository);
                } else {
                    bag.repositoryByType.get(entityNode.objectType).addAll(entityNode.repository);
                }
            }
            return bag;
        }
    }

    @TestVisible
    private class EntityNodeMatrix implements Iterator<EntityNode> {
        private Integer rowIndex { get; set; }
        private Integer colIndex { get; set; }
        @TestVisible
        private List<List<EntityNode>> entityNodeMatrix { get; set; }
        private List<EntityNode> entityNodeStack { get; set; }
        private EntityNode currentEntityNode { get; set; }

        private EntityNodeMatrix() {
            entityNodeMatrix = new List<List<EntityNode>>();
            entityNodeStack = new List<EntityNode>();
            rowIndex = 0;
            colIndex = -1;
        }

        public Boolean hasNext() {
            return rowIndex + 1 < entityNodeMatrix.size()
                || colIndex + 1 < entityNodeMatrix.get(rowIndex).size();
        }

        public EntityNode next() {
            if (hasNext()) {
                colIndex += 1;
                if (colIndex == entityNodeMatrix.get(rowIndex).size()) {
                    rowIndex += 1;
                    colIndex = 0;
                }
                return entityNodeMatrix.get(rowIndex).get(colIndex);
            }
            return null;
        }

        private void reset() {
            rowIndex = 0;
            colIndex = -1;
        }

        private void pop(Integer depth) {
            while (depth > 0) {
                depth--;
                Integer size = this.entityNodeStack.size();
                if (size > 1) {
                    this.entityNodeStack.remove(size - 1);
                    this.currentEntityNode = this.entityNodeStack[size - 2];
                }
            }
            rowIndex = this.currentEntityNode.rowIndex;
            colIndex = this.currentEntityNode.colIndex;
        }

        private void add(EntityNode entityNode) {
            switch on entityNode.nodeType {
                when WantMany {
                    rowIndex = 0;
                    colIndex = 0;
                    entityNodeMatrix.add(new List<EntityNode>());
                    entityNodeMatrix.get(rowIndex).add(entityNode);
                }
                when BelongTo {
                    if (rowIndex > 0) {
                        rowIndex -= 1;
                        entityNodeMatrix.get(rowIndex).add(entityNode);
                        colIndex = entityNodeMatrix.get(rowIndex).size() - 1;
                    } else {
                        rowIndex = 0;
                        colIndex = 0;
                        entityNodeMatrix.add(rowIndex, new List<EntityNode>());
                        entityNodeMatrix.get(rowIndex).add(entityNode);
                    }
                }
                when HaveMany {
                    rowIndex += 1;
                    if (rowIndex == entityNodeMatrix.size()) {
                        colIndex = 0;
                        entityNodeMatrix.add(new List<EntityNode>());
                        entityNodeMatrix.get(rowIndex).add(entityNode);
                    } else {
                        colIndex += 1;
                        entityNodeMatrix.get(rowIndex).add(entityNode);
                    }
                }
            }
            entityNode.rowIndex = rowIndex;
            entityNode.colIndex = colIndex;
            entityNodeStack.add(entityNode);
            entityNode.parentEntityNode = this.currentEntityNode;
            this.currentEntityNode = entityNode;
        }
    }

    /*
    * ENTITY NODE
    */
    public enum EntityNodeType {
        WantMany,
        BelongTo,
        HaveMany,
        Template
    }

    public class EntityNode {
        // Graph Properties
        Integer rowIndex { get; set; }
        Integer colIndex { get; set; }
        EntityNodeType nodeType { get; set; }
        EntityNode parentEntityNode {
            get;
            set {
                parentEntityNode = value;
                switch on nodeType {
                    when BelongTo {
                        parentEntityNode.referenceToMap.put(this.name, this);
                    }
                    when HaveMany {
                        referenceToMap.put(parentEntityNode.name, parentEntityNode);
                    }
                }
            }
        }

        // Entity Attributes
        public Schema.SObjectType objectType { get; set; }
        public Schema.DescribeSObjectResult dsr { get; set; }
        public String name { get; set; }
        public Integer total { get; set; }
        public Map<String, EntityNode> referenceToMap { get; set; }
        public List<SObject> repository { get; set; }

        public Boolean guardEnabled { get; set; }
        public Map<Schema.SObjectField, EvalEntityField> evalFieldMap { get; set; }
        public Map<Schema.SObjectField, XrefEntityField> xrefFieldMap { get; set; }
        List<EvalEntityField> evalFieldCache { get; set; }
        List<XrefEntityField> xrefFieldCache { get; set; }
        EntityField currentEntityField { get; set; }

        public EntityNode() {

        }

        public EntityNode(Schema.SObjectType objectType, EntityNodeType nodeType) {
            this.objectType = objectType;
            this.dsr = objectType.getDescribe();
            this.name = dsr.getName();
            this.nodeType = nodeType;

            this.referenceToMap = new Map<String, EntityNode>();
            this.repository = new List<SObject>();

            this.guardEnabled = true;
            this.evalFieldMap = new Map<Schema.SObjectField, EvalEntityField>();
            this.xrefFieldMap = new Map<Schema.SObjectField, XrefEntityField>();
            this.evalFieldCache = new List<EvalEntityField>();
            this.xrefFieldCache = new List<XrefEntityField>();
        }
    }

    /*
     * ENTITY FIELD
     */

    private abstract class EntityField  {
        public Schema.SObjectField field { get; set; }
        public Schema.DescribeFieldResult dfr { get; set; }
        public String name { get; set; }
        public ATKCommon.Method method { get; set; }
        public Boolean needGuess { get; set; }

        {
            needGuess = false;
        }

        EntityField(Schema.SObjectField field) {
            this.field = field;
            this.dfr = this.field.getDescribe();
            this.name = this.dfr.getName();
        }

        public virtual Object getValue(Integer recordIndex) {
            return null;
        }
    }

    private class EvalEntityField extends EntityField {
        public Object value { get; set; }
        public String indexFormat { get; set; }
        public String fakerRule { get; set; }
        public List<Object> repeatValues { get; set; }

        EvalEntityField(Schema.SObjectField field) {
            super(field);
        }

        EvalEntityField(Schema.SObjectField field, Boolean needGuess) {
            super(field);
            this.needGuess = needGuess;
        }

        public override Object getValue(Integer recordIndex) {
            if (fakerRule != null) {
                return ATKFaker.fake(fakerRule);
            } else if (indexFormat != null) {
                return String.format(indexFormat, new List<String> { String.valueOf(recordIndex) });
            } else if (repeatValues != null && repeatValues.size() > 0) {
                Integer mod = Math.mod(recordIndex, repeatValues.size());
                return repeatValues[mod];
            } else if (method != null) {
                return method.evaluate(ATKFaker.helperMap);
            }
            return this.value;
        }
    }

    private class XrefEntityField extends EntityField implements Comparable {
        public ATKCommon.XrefMethod method { get; set; }
        public EvalEntityField origin { get; set; }

        XrefEntityField(Schema.SObjectField field) {
            super(field);
        }

        public override Object getValue(Integer recordIndex) {
            if (recordIndex < method.level) {
                return origin.getValue(recordIndex);
            }
            return method.evaluate(ATKFaker.helperMap, recordIndex);
        }

        public Integer compareTo(Object toObj) {
            XrefEntityField field = this;
            XrefEntityField toField = (XrefEntityField)toObj;

            Integer returnValue = 0; // The return value of 0 indicates that both elements are equal.
            if (field.method.level < toField.method.level) {
                returnValue = 1;
            } else if (field.method.level > toField.method.level) {
                returnValue = -1;
            }
            return returnValue;
        }
    }

    public class ParamEvaluator implements ATKCommon.IParamEvaluator {
        EntityNode entityNode { get; set; }

        public Object evaluateParam(String fieldName, Integer recordIndex, Integer level) {
            if (entityNode == null) {
                return null;
            }

            if (level <= recordIndex) {
                SObject record = entityNode.repository[recordIndex - level];
                return record.get(fieldName);
            }
            return null;
        }
    }

    /*
     * ATTRIBUTES
     */

    public interface IAttribute {

    }

    public interface IEntityAttribute extends IAttribute {
        void apply(EntityNode entityNode);
    }

    public interface IFieldAttribute extends IAttribute {
    }

    public interface IEvalFieldAttribute extends IFieldAttribute {
        void apply(EntityNode entityNode, EvalEntityField entityField);
    }

    public interface IXrefFieldAttribute extends IFieldAttribute {
        void apply(EntityNode entityNode, XrefEntityField entityField);
    }

    public class ReferenceByAttribute implements IEntityAttribute {
        private String referenceBy { get; set; }
        public ReferenceByAttribute(Schema.SObjectField referenceBy) {
            this.referenceBy = referenceBy.getDescribe().getName();
        }

        public void apply(EntityNode entityNode) {
            switch on entityNode.nodeType {
                when BelongTo {
                    entityNode.parentEntityNode.referenceToMap.remove(entityNode.name);
                    entityNode.parentEntityNode.referenceToMap.put(referenceBy, entityNode);
                }
                when HaveMany {
                    entityNode.referenceToMap.remove(entityNode.parentEntityNode.name);
                    entityNode.referenceToMap.put(referenceBy, entityNode.parentEntityNode);
                }
            }
        }
    }

    public class TotalAttribute implements IEntityAttribute {
        private Integer total { get; set; }
        public TotalAttribute(Integer total) {
            this.total = total;
        }

        public void apply(EntityNode entityNode) {
            if (entityNode.repository.size() == 0) {
                entityNode.total = total;
            } else {
                entityNode.total = entityNode.repository.size();
            }
        }
    }

    public class UseListAttribute implements IEntityAttribute {
        private List<SObject> repository { get; set; }

        public UseListAttribute(List<SObject> repository) {
            this.repository = repository;
        }

        public void apply(EntityNode entityNode) {
            entityNode.repository.addAll(repository);
            IEntityAttribute totalAttribute = new TotalAttribute(repository.size());
            totalAttribute.apply(entityNode);
        }
    }

    public class GuardAttribute implements IEntityAttribute {
        private Boolean guardEnabled { get; set; }

        public GuardAttribute(Boolean guardEnabled) {
            this.guardEnabled = guardEnabled;
        }

        public void apply(EntityNode entityNode) {
            if (this.guardEnabled != null) {
                entityNode.guardEnabled = this.guardEnabled;
            }
        }
    }

    public virtual class EvalAttribute implements IEntityAttribute {
        public Schema.SObjectField field { get; set; }

        public void apply(EntityNode entityNode) {
            EvalEntityField entityField;

            if (entityNode.xrefFieldMap.containsKey(this.field)) {
                XrefEntityField xrefEntityField = entityNode.xrefFieldMap.get(this.field);
                if (xrefEntityField.origin == null) {
                    entityField = new EvalEntityField(this.field);
                    xrefEntityField.origin = entityField;
                } else {
                    entityField = xrefEntityField.origin;
                }
            }

            if (entityField == null) {
                if (entityNode.evalFieldMap.containsKey(this.field)) {
                    entityField = entityNode.evalFieldMap.get(this.field);
                } else {
                    entityField = new EvalEntityField(this.field);
                    entityNode.evalFieldMap.put(this.field, entityField);
                    entityNode.evalFieldCache.add(entityField);
                }
            }

            entityNode.currentEntityField = entityField;
        }
    }

    public class XrefAttribute implements IEntityAttribute  {
        public Schema.SObjectField field { get; set; }

        public void apply(EntityNode entityNode) {
            XrefEntityField entityField;
            if (entityNode.xrefFieldMap.containsKey(this.field)) {
                entityField = entityNode.xrefFieldMap.get(this.field);
            } else {
                entityField = new XrefEntityField(this.field);
                entityNode.xrefFieldMap.put(this.field, entityField);
                entityNode.xrefFieldCache.add(entityField);
            }

            if (entityNode.evalFieldMap.containsKey(this.field)) {
                EvalEntityField evalEntityField = entityNode.evalFieldMap.get(this.field);
                entityNode.evalFieldMap.remove(this.field);
                entityNode.evalFieldCache.remove(entityNode.evalFieldCache.indexOf(evalEntityField));
                entityField.origin = evalEntityField;
            }

            entityNode.currentEntityField = entityField;
        }
    }

    public class EvalGuessAttribute implements IEvalFieldAttribute {
        public void apply(EntityNode entityNode, EvalEntityField entityField) {
            entityField.needGuess = true;
        }
    }

    public class EvalValueAttribute implements IEvalFieldAttribute {
        Object value { get; set; }

        public EvalValueAttribute(Object value) {
            this.value = value;
        }

        public void apply(EntityNode entityNode, EvalEntityField entityField) {
            entityField.value = this.value;
        }
    }

    public class EvalIndexAttribute implements IEvalFieldAttribute {
        String format { get; set; }

        public EvalIndexAttribute(String format) {
            this.format = format;
        }

        public void apply(EntityNode entityNode, EvalEntityField entityField) {
            entityField.indexFormat = this.format;
        }
    }

    public class EvalRepeatAttribute implements IEvalFieldAttribute {
        List<Object> values { get; set; }

        public EvalRepeatAttribute(List<Object> values) {
            this.values = values;
        }

        public void apply(EntityNode entityNode, EvalEntityField entityField) {
            entityField.repeatValues = this.values;
        }
    }

    public class EvalFakerAttribute implements IEvalFieldAttribute {
        String rule { get; set; }

        public EvalFakerAttribute(String rule) {
            this.rule = rule;
        }

        public void apply(EntityNode entityNode, EvalEntityField entityField) {
            entityField.fakerRule = this.rule;
        }
    }

    public class EvalMethodAttribute implements IEvalFieldAttribute {
        String helperName { get; set; }
        String methodName { get; set; }
        public List<Object> params { get; set; }

        public  EvalMethodAttribute(String helperName, String methodName) {
            this.helperName = helperName;
            this.methodName = methodName;
        }

        public void apply(EntityNode entityNode, EvalEntityField entityField) {
            ATKCommon.Method method = new ATKCommon.Method();
            method.helperName = this.helperName;
            method.name = this.methodName;
            method.params = this.params;
            entityField.method = method;
        }
    }

    public class XrefMethodAttribute implements IXrefFieldAttribute {
        public String helperName { get; set; }
        public String methodName { get; set; }
        public List<Object> params { get; set; }

        public  XrefMethodAttribute() {

        }

        public  XrefMethodAttribute(String helperName, String methodName) {
            this.helperName = helperName;
            this.methodName = methodName;
        }

        public void apply(EntityNode entityNode, XrefEntityField entityField) {
            List<ATKCommon.XrefParam> xrefParams = new List<ATKCommon.XrefParam>();
            List<Object> newParams = new List<Object>();
            for (Integer i = 0; i < this.params.size(); i++) {
                Object param = this.params[i];
                if (param instanceOf String) {
                    String input = (String)param;
                    if (input.startsWith('$')) {
                        ATKCommon.XrefParam xrefParam = new ATKCommon.XrefParam();
                        xrefParam.index = i;
                        xrefParam.level = ATKCommon.converter.toInteger(input.substring(1, 2));
                        xrefParam.fieldName = input.substring(3).toUpperCase();

                        xrefParams.add(xrefParam);
                        newParams.add(null);
                    } else {
                        newParams.add(param);
                    }
                } else {
                    newParams.add(param);
                }
            }

            ATKCommon.XrefMethod method = new ATKCommon.XrefMethod(xrefParams);
            method.helperName = this.helperName;
            method.name = this.methodName;
            method.params = newParams;
            method.paramEvaluator = PARAM_EVALUATOR;
            entityField.method = method;
        }
    }
}
