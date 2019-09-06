/**
 * Apex Test Kit
 */
public with sharing class ATKEntityGenerator {
    static final ISchemator SCHEMATOR = new FieldSchemator(); // have state
    static final IEvaluator EVALUATOR = new FieldEvaluator(); // have state
    static final IValidator VALIDATOR = new NodeValidator();  // pure func
    static final IGenerator GENERATOR = new NodeGenerator();  // pure func
    static final Distributor DISTRIBUTOR = new Distributor(); // pure func

    Boolean inMemory { get; set; }

    public void generate(ATKEntityCollection entityCollection, Boolean inMemory) {
        this.inMemory = inMemory;
        SCHEMATOR.build(entityCollection);
        VALIDATOR.validate(entityCollection);
        GENERATOR.generate(entityCollection);
    }

    interface ISchemator {
        void build(ATKEntityCollection entityCollection);
        String getReferenceFieldName(String objectName, String referenceTypeName);
        String getReferenceFieldType(String objectName, String referenceFieldName);
        Boolean isGeolocationField(Schema.DescribeSObjectResult dsr, Schema.DescribeFieldResult dfr);
        Boolean isAddressField(Schema.DescribeSObjectResult dsr, Schema.DescribeFieldResult dfr);
    }

    interface IValidator {
        void validate(ATKEntityCollection entityCollection);
    }

    interface IGenerator {
        void generate(ATKEntityCollection entityCollection);
    }

    interface IEvaluator {
        Object evaluate(
            Integer recordIndex,
            ATKEntityCollection.EntityNode entityNode,
            ATKEntityCollection.EntityField entityField,
            Integer depth);
    }

    class FieldSchemator implements ISchemator {
        Map<String, Set<String>> addressFieldCache { get; set; }
        Map<String, Set<String>> geolocationFieldCache { get; set; }
        Map<String, Map<String, String>> referenceFieldNameByTypeCache { get; set; }
        Map<String, Map<String, String>> referenceFieldTypeByNameCache { get; set; }

        @TestVisible
        FieldSchemator() {
            addressFieldCache = new Map<String, Set<String>>();
            geolocationFieldCache = new Map<String, Set<String>>();
            referenceFieldNameByTypeCache = new Map<String, Map<String, String>>();
            referenceFieldTypeByNameCache = new Map<String, Map<String, String>>();
        }

        public void build(ATKEntityCollection entityCollection) {
            Iterator<ATKEntityCollection.EntityNode> iterator = entityCollection.iterator();
            while (iterator.hasNext()) {
                ATKEntityCollection.EntityNode entityNode = iterator.next();
                entityNode.xrefFieldCache.sort();
                buildFieldCaches(entityNode);
            }
        }

        void buildFieldCaches(ATKEntityCollection.EntityNode entityNode) {
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
                    entityNode.evalFieldCache.add(new ATKEntityCollection.EvalEntityField(field, true));
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
        public void validate(ATKEntityCollection entityCollection) {
            Iterator<ATKEntityCollection.EntityNode> iterator = entityCollection.iterator();
            while (iterator.hasNext()) {
                ATKEntityCollection.EntityNode entityNode = iterator.next();
                validateTotalAndList(entityNode);
                validateRelationship(entityNode);
                validateXrefFields(entityNode);
            }
        }

        @TestVisible
        void validateTotalAndList(ATKEntityCollection.EntityNode entityNode) {
            if ((entityNode.total == null || entityNode.total == 0) &&
                (entityNode.repository == null || entityNode.repository.size() == 0)
            ) {
                throw new ATKCommon.InsufficientAttributeException(
                    String.format('Please set either total() or fromList() for sObject type {0}.',
                    new List<String> { entityNode.name }));
            }
        }

        @TestVisible
        void validateRelationship(ATKEntityCollection.EntityNode entityNode) {
            if (entityNode.referenceToMap != null && entityNode.referenceToMap.size() > 0) {
                for (String fieldName : entityNode.referenceToMap.keySet()) {
                    ATKEntityCollection.EntityNode referenceTo = entityNode.referenceToMap.get(fieldName);
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

        void autoDetectReferenceFieldName(ATKEntityCollection.EntityNode entityNode, ATKEntityCollection.EntityNode referenceTo) {
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
        void validateXrefFields(ATKEntityCollection.EntityNode entityNode) {
            for (ATKEntityCollection.XrefEntityField field : entityNode.xrefFieldCache) {
                if (0 < field.method.level()) {
                    for (ATKReflect.XrefParam param : field.method.xrefParams()) {
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
        public void generate(ATKEntityCollection entityCollection) {
            Iterator<ATKEntityCollection.EntityNode> iterator = entityCollection.iterator();
            while (iterator.hasNext()) {
                ATKEntityCollection.EntityNode entityNode = iterator.next();
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

        void updateObjects(ATKEntityCollection.EntityNode entityNode) {
            Schema.SObjectType objectType = entityNode.objectType;
            Schema.DescribeSObjectResult dsr = entityNode.dsr;

            List<SObject> repository = entityNode.repository;
            Integer total = repository.size();
            for (ATKEntityCollection.EntityField entityField : entityNode.evalFieldCache) {
                for (Integer i = 0; i < total; i++) {
                    Object value = EVALUATOR.evaluate(i, entityNode, entityField, 10);
                    if (value != null) {
                        SObject record = repository[i];
                        record.put(entityField.name, value);
                    }
                }
            }

            for (Integer i = 0; i < total; i++) {
               for (ATKEntityCollection.EntityField entityField : entityNode.xrefFieldCache) {
                    Object value = EVALUATOR.evaluate(i, entityNode, entityField, 10);
                    if (value != null) {
                        SObject record = repository[i];
                        record.put(entityField.name, value);
                    }
                }
            }
        }

        void assignReferences(ATKEntityCollection.EntityNode entityNode) {
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
        Map<String, List<String>> picklistCache { get; set; }
        Map<String, Set<Object>> uniqueValueCache { get; set; }
        List<String> UNIQUE_VALUE_FORMATS { get; set; }

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

        public Object evaluate(Integer recordIndex, ATKEntityCollection.EntityNode entityNode, ATKEntityCollection.EntityField entityField, Integer depth) {
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
                    value = ATKCommon.CONVERTER.toDate(value);
                }
                when TIME {
                    value = ATKCommon.CONVERTER.toTime(value);
                }
                when INTEGER {
                    value = ATKCommon.CONVERTER.toInteger(value);
                }
            }
            return value;
        }

        Object getValue(Integer recordIndex, ATKEntityCollection.EntityNode entityNode, ATKEntityCollection.EntityField entityField) {
            DescribeSObjectResult dsr = entityNode.dsr;
            Schema.DescribeFieldResult dfr = entityField.dfr;
            Object value;
            if (entityField.needGuess) {
                value = guessValue(dsr, dfr);
            } else {
                value = entityField.getValue(entityNode, recordIndex);
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
}
