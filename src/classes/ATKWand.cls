/**
 * Apex Test Kit
 */
public with sharing class ATKWand {
    private static final ATKCommon.MethodParser METHOD_PARSER = ATKCommon.METHOD_PARSER;
    private static final MethodEvaluator METHOD_EVALUATOR = new MethodEvaluator();

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

    public interface IWizardBag {
        List<SObject> get(Schema.SObjectType objectType);
    }

    public interface IWizardEntity {
        // keywords to start with
        IWizardEntity wantTemp(SObjectType entityType, String templateName);
        IWizardEntity wantMany(SObjectType entityType);
        IWizardEntity belongTo(SObjectType entityType);
        IWizardEntity haveMany(SObjectType entityType);

        // keywords to build graph
        IWizardEntity referenceBy(Schema.SObjectField relationField);
        IWizardEntity total(Integer count);
        IWizardEntity also();
        IWizardEntity also(Integer depth);

        // keywords to build values
        IWizardEntity useCSV(String fileName);
        IWizardEntity useList(List<SObject> repository);
        IWizardEntity useTemp();
        IWizardEntity useTemp(String templateName);
        IWizardField fields();

        // keywords to end with
        IWizardBag generate();
        IWizardBag generate(Boolean inMemory);
        void register();
    }

    public interface IWizardField {
        IWizardField guard();
        IWizardField guard(Boolean enable);
        IWizardField useEval(Schema.SObjectField field);
        IWizardField useEval(Schema.SObjectField field, Object rule);
        IWizardField useXref(Schema.SObjectField field, String rule);
        IWizardField useXref(Schema.SObjectField field, String rule, Object origin);
        IWizardEntity end();
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
        void resetRuleIndexCache();
        Object evaluate(
            Integer recordIndex,
            EntityNode entityNode,
            RuleEntityField field,
            Integer depth);
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
                    && !entityNode.ruleFieldMap.containsKey(field)
                    && !entityNode.xrefFieldMap.containsKey(field)) {
                    entityNode.ruleFieldCache.add(new RuleEntityField(dfr, fieldName, false, null));
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
                validateXrefFieldOrigin(entityNode, field);
            }
        }

        @TestVisible
        void validateXrefFieldOrigin(EntityNode entityNode, XrefEntityField field) {
            ATKCommon.MethodGroup methodGroup = METHOD_PARSER.parse((String)field.rule);
            if (methodGroup.hasXrefMethod) {
                for (ATKCommon.Method method : methodGroup.methodList) {
                    if (method instanceof ATKCommon.XrefMethod) {
                        ATKCommon.XrefMethod xrefMethod = (ATKCommon.XrefMethod)method;
                        if (0 < xrefMethod.level) {
                            for (ATKCommon.XrefParam param : xrefMethod.xrefParams) {
                                if (0 < param.level && field.origin == null) {
                                    throw new ATKCommon.NotFoundException(
                                        String.format('The cross reference field {0}.{1} must have an origin.',
                                        new List<String> { entityNode.Name, field.name })
                                    );
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    class NodeGenerator implements IGenerator {
        public void generate(ATKSpellBook spellBook) {
            EVALUATOR.resetRuleIndexCache();
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
            for (RuleEntityField field : entityNode.ruleFieldCache) {
                for (Integer i = 0; i < total; i++) {
                    Object value = EVALUATOR.evaluate(i, entityNode, field, 10);
                    if (value != null) {
                        SObject record = repository[i];
                        record.put(field.name, value);
                    }
                }
            }

            for (Integer i = 0; i < total; i++) {
               for (RuleEntityField field : entityNode.xrefFieldCache) {
                    Object value = EVALUATOR.evaluate(i, entityNode, field, 10);
                    if (value != null) {
                        SObject record = repository[i];
                        record.put(field.name, value);
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
        private Map<String, Integer> ruleIndexCache { get; set; }
        private Map<String, Set<Object>> uniqueValueCache { get; set; }
        private List<String> UNIQUE_VALUE_FORMATS { get; set; }

        @TestVisible
        FieldEvaluator() {
            picklistCache = new Map<String, List<String>>();
            uniqueValueCache = new Map<String, Set<Object>>();
            ruleIndexCache = new Map<String, Integer>();
            UNIQUE_VALUE_FORMATS = new List<String> {
                '{{?}}',
                '{{?*}}',
                '{{?**}}',
                '{{?***}}',
                '{{?****}}',
                '{{?*****}}'
            };
        }

        public void resetRuleIndexCache() {
            ruleIndexCache = new Map<String, Integer>();
        }

        public Object evaluate(
            Integer recordIndex,
            EntityNode entityNode,
            RuleEntityField field,
            Integer depth) {

            DescribeSObjectResult dsr = entityNode.dsr;
            Schema.DescribeFieldResult dfr = field.dfr;
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
                    value = getValue(recordIndex, entityNode, field, key);
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
                value = getValue(recordIndex, entityNode, field, key);
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

        public Object getValue(Integer recordIndex, EntityNode entityNode, RuleEntityField field, String key) {
            DescribeSObjectResult dsr = entityNode.dsr;
            Schema.DescribeFieldResult dfr = field.dfr;
            Object rule = field.rule;
            FieldRuleType ruleType = field.ruleType;

            Object value;
            switch on ruleType {
                when StringRule {
                    value = fake(recordIndex, entityNode, field, (String)rule);
                }
                when StringList {
                    value = fake(recordIndex, entityNode, field, (String)getIndexedRule(key, (List<String>)rule));
                }
                when StringSet {
                    value = fake(recordIndex, entityNode, field, (String)ATKFaker.random.arrayElement(new List<String>((Set<String>)rule)));
                }
                when ObjectList {
                    value = getIndexedRule(key, (List<Object>)rule);
                }
                when ObjecSet {
                    value = ATKFaker.random.arrayElement(new List<Object>((Set<Object>)rule));
                }
                when FeelLuck {
                    value = guessValue(dsr, dfr);
                }
                when else {
                    value = rule;
                }
            }
            return value;
        }

        Object fake(Integer recordIndex, EntityNode entityNode, RuleEntityField field, String rule) {
            METHOD_EVALUATOR.currentRecordIndex = recordIndex;
            METHOD_EVALUATOR.currentEntity = entityNode;
            METHOD_EVALUATOR.currentField = field;
            return METHOD_PARSER.parse(rule).evaluate(METHOD_EVALUATOR);
        }

        Object getIndexedRule(String key, List<Object> ruleList) {
            if (ruleIndexCache.get(key) == null) {
                ruleIndexCache.put(key, -1);
            }
            Integer index = ruleIndexCache.get(key);
            index++;
            if (index == ruleList.size()) {
                index = 0;
            }
            ruleIndexCache.put(key, index);
            return ruleList.get(index);
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

    public class MethodEvaluator implements ATKCommon.IMethodEvaluator, ATKCommon.IParamEvaluator {
        Integer currentRecordIndex { get; set; }
        EntityNode currentEntity { get; set; }
        RuleEntityField currentField { get; set; }

        public Object evaluateMethod(ATKCommon.Method method) {
            Object value;
            ATKFaker.IProvider helper = ATKFaker.helperMap.get(method.helperName);
            if (helper != null) {
                if (method instanceof ATKCommon.XrefMethod) {
                    ATKCommon.XrefMethod xrefMethod = (ATKCommon.XrefMethod)method;
                    if (this.currentRecordIndex < xrefMethod.level && xrefMethod.level < ATKCommon.METHOD_GROUP_MAX_LEVEL) {
                        Object origin = ((XrefEntityField)currentField).origin;
                        if (origin instanceof List<Object>) {
                            List<Object> originList = (List<Object>)origin;
                            return originList[this.currentRecordIndex];
                        } else {
                            return origin;
                        }
                    }
                    xrefMethod.loadParams(this);
                }
                value = helper.call(method.name, method.params);
            }
            return value;
        }

        public Object evaluateParam(Integer level, String fieldName) {
            if (currentEntity == null) {
                return null;
            }

            Integer size = currentEntity.repository.size();
            if (level <= this.currentRecordIndex) {
                SObject record = currentEntity.repository[this.currentRecordIndex - level];
                return record.get(fieldName);
            }
            return null;
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

    public class ATKSpellBook implements Iterable<EntityNode> {
        private Map<Schema.SObjectType, List<EntityNode>> entityNodeMap { get; set; }
        @TestVisible
        private EntityNodeMatrix matrix { get; private set; }

        {
            entityNodeMap = new Map<Schema.SObjectType, List<EntityNode>>();
            matrix = new EntityNodeMatrix();
        }

        public Iterator<EntityNode> iterator() {
            this.matrix.reset();
            return matrix;
        }

        public void attach(EntityNode entityNode) {
            this.matrix.add(entityNode);
            addToEntityNodeMap(entityNode);
        }

        public void apply(IEntityAttribute attribute) {
            this.matrix.currentEntityNode.apply(attribute);
        }

        public void pop(Integer depth) {
            this.matrix.pop(depth);
        }

        private void addToEntityNodeMap(EntityNode entityNode) {
            Schema.SObjectType objectType = entityNode.objectType;
            if (entityNodeMap.get(objectType) == null) {
                entityNodeMap.put(objectType, new List<EntityNode>());
            }
            entityNodeMap.get(objectType).add(entityNode);
        }

        public List<SObject> query(Schema.SObjectType objectType) {
            List<EntityNode> entityNodeList = entityNodeMap.get(objectType);
            List<SObject> repository = new List<SObject>();
            if (entityNodeList != null) {
                for (EntityNode entityNode : entityNodeList) {
                    repository.addAll(entityNode.repository);
                }
            }
            return repository;
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

    enum FieldRuleType {
        StringRule,
        StringList,
        StringSet,
        ObjectList,
        ObjecSet,
        ValueRule,
        FeelLuck
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
        public String templateName { get; set; }

        public Boolean guardEnabled { get; set; }
        public Map<Schema.SObjectField, RuleEntityField> ruleFieldMap { get; set; }
        public Map<Schema.SObjectField, XrefEntityField> xrefFieldMap { get; set; }
        List<RuleEntityField> ruleFieldCache { get; set; }
        List<XrefEntityField> xrefFieldCache { get; set; }

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
            this.ruleFieldMap = new Map<Schema.SObjectField, RuleEntityField>();
            this.xrefFieldMap = new Map<Schema.SObjectField, XrefEntityField>();
            this.ruleFieldCache = new List<RuleEntityField>();
            this.xrefFieldCache = new List<XrefEntityField>();
        }

        public void apply(IEntityAttribute attribute) {
            attribute.apply(this);
        }
    }

    public static EntityNode createTemplate(Schema.SObjectType objectType, String templateName) {
        EntityNode template = new EntityNode();
        template.objectType = objectType;
        template.nodeType = EntityNodeType.Template;
        template.templateName = templateName;
        return template;
    }

    public virtual class RuleEntityField  {
        Schema.DescribeFieldResult dfr { get; set; }
        String name { get; set; }
        Boolean hasRule { get; set; }
        Object rule { get; set; }
        FieldRuleType ruleType { get; set; }

        RuleEntityField(Schema.DescribeFieldResult dfr, String name, Boolean hasRule, Object rule) {
            this.name = name;
            this.rule = rule;
            this.hasRule = hasRule;

            if (this.hasRule) {
                if (rule == null) {
                    this.ruleType = FieldRuleType.ValueRule;
                } if (rule instanceOf String) {
                    this.ruleType = FieldRuleType.StringRule;
                } else if (rule instanceOf List<String>) {
                    this.ruleType = FieldRuleType.StringList;
                } else if (rule instanceOf Set<String>) {
                    this.ruleType = FieldRuleType.StringSet;
                } else if (rule instanceOf List<Object>) {
                    this.ruleType = FieldRuleType.ObjectList;
                } else if (rule instanceOf Set<Object>) {
                    this.ruleType = FieldRuleType.ObjecSet;
                } else {
                    this.ruleType = FieldRuleType.ValueRule;
                }
            } else {
                this.ruleType = FieldRuleType.FeelLuck;
            }
            this.dfr = dfr;
        }
    }

    public class XrefEntityField extends RuleEntityField implements Comparable {
        Object origin { get; set; }

        XrefEntityField(Schema.DescribeFieldResult dfr, String name, Boolean hasRule, Object rule, Object origin) {
            super(dfr, name, hasRule, rule);
            this.origin = origin;
        }

        public Integer compareTo(Object toObj) {
            RuleEntityField field = this;
            RuleEntityField toField = (RuleEntityField)toObj;
            ATKCommon.MethodGroup methodGroup = METHOD_PARSER.parse((String)field.rule);
            ATKCommon.MethodGroup toMethodGroup = METHOD_PARSER.parse((String)toField.rule);

            Integer returnValue = 0; // The return value of 0 indicates that both elements are equal.
            if (methodGroup.level < toMethodGroup.level) {
                returnValue = 1;
            } else if (methodGroup.level > toMethodGroup.level) {
                returnValue = -1;
            }
            return returnValue;
        }
    }

    /*
    * ENTITY ATTRIBUTE
    */
    public Interface IEntityAttribute {
        void apply(EntityNode entityNode);
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

    public class UseTempAttribute implements IEntityAttribute {
        private String templateName { get; set; }

        public UseTempAttribute(String templateName) {
            this.templateName = templateName;
        }

        public void apply(EntityNode entityNode) {
            entityNode.templateName = templateName;
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
        protected Schema.SObjectField field { get; set; }
        protected Object rule { get; set; }
        protected Boolean hasRule { get; set; }

        public EvalAttribute(Schema.SObjectField field) {
            this.field = field;
            this.hasRule = false;
        }

        public EvalAttribute(Schema.SObjectField field, Object rule) {
            this.field = field;
            this.rule = rule;
            this.hasRule = true;
        }

        public virtual void apply(EntityNode entityNode) {
            Schema.DescribeFieldResult dfr = this.field.getDescribe();
            String fieldName = dfr.getName();
            RuleEntityField ruleEntityField = new RuleEntityField(dfr, fieldName, hasRule, rule);
            entityNode.ruleFieldMap.put(this.field, ruleEntityField);
            entityNode.ruleFieldCache.add(ruleEntityField);
        }
    }

    public class XrefAttribute extends EvalAttribute {
        private Object origin { get; set; }

        public xrefAttribute(Schema.SObjectField field, String rule) {
            super(field, rule);
        }

        public xrefAttribute(Schema.SObjectField field, String rule, Object origin) {
            super(field, rule);
            this.origin = origin;
        }

        public override void apply(EntityNode entityNode) {
            Schema.DescribeFieldResult dfr = this.field.getDescribe();
            String fieldName = dfr.getName();
            XrefEntityField xrefEntityField = new XrefEntityField(dfr, fieldName, hasRule, rule, origin);
            entityNode.xrefFieldMap.put(this.field, xrefEntityField);
            entityNode.xrefFieldCache.add(xrefEntityField);
        }
    }
}
