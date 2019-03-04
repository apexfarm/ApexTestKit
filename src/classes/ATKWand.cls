/**
 * Apex Test Kit
 */
public with sharing class ATKWand {
    public static final ATKCommon.MethodParser METHOD_PARSER = ATKCommon.METHOD_PARSER;
    private static Map<String, Schema.SObjectType> gd { get; set; }
    private static final MethodEvaluator METHOD_EVALUATOR = new MethodEvaluator();

    private static final ISchemator SCHEMATOR = new FieldSchemator();
    private static final IValidator VALIDATOR = new NodeValidator();
    private static final IGenerator GENERATOR = new NodeGenerator();
    private static final IEvaluator EVALUATOR = new FieldEvaluator();

    static {
        gd = Schema.getGlobalDescribe();
    }

    public static void analysis(ATKSpellBook spellBook) {
        SCHEMATOR.build(spellBook);
        VALIDATOR.validate(spellBook);
    }

    public static void generate(ATKSpellBook spellBook) {
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
        void resetRuleIndexCache();
        Object getValue(
            Schema.DescribeSObjectResult dsr,
            Schema.DescribeFieldResult dfr,
            Object rule,
            Boolean hasRule,
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
                buildFieldCaches(entityNode);
            }
        }

        void buildFieldCaches(EntityNode entityNode) {
            Schema.SObjectType objectType = gd.get(entityNode.name);
            Schema.DescribeSObjectResult dsr = objectType.getDescribe();
            String objectName = dsr.getName();

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
                referenceFieldNameByTypeCache.put(objectName.toUpperCase(), referenceFieldNameMap);

                referenceFieldTypeMap = new Map<String, String>();
                referenceFieldTypeByNameCache.put(objectName.toUpperCase(), referenceFieldTypeMap);
            }

            Set<String> xrefsNameSet = entityNode.fieldInitMap.keySet();
            Set<String> fieldNameSet = entityNode.fieldRuleMap.keySet();

            for (SObjectField field : dsr.fields.getMap().values()) {
                Schema.DescribeFieldResult dfr = field.getDescribe();
                String fieldName = dfr.getName().toUpperCase();

                Object rule = entityNode.fieldRuleMap.get(fieldName);
                if (xrefsNameSet.contains(fieldName)) {
                    entityNode.tmpXrefFieldCache.add(new EntityField(fieldName, rule, true, dfr));
                } else if (fieldNameSet.contains(fieldName)) {
                    entityNode.tmpRuleFieldCache.add(new EntityField(fieldName, rule, true, dfr));
                } else if (!dfr.isNillable() && isEditableField(dfr)) {
                    entityNode.tmpRuleFieldCache.add(new EntityField(fieldName, rule, false, dfr));
                }

                // no need to rebuild static caches
                if (addressFieldSet == null) {
                    continue;
                }

                Schema.DisplayType fieldType = dfr.getType();
                if (fieldType == Schema.DisplayType.ADDRESS) {
                    String addressPrefix = dfr.getName().toUpperCase().replace('ADDRESS', '');
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
                        String toRefType = rst.getDescribe().getName().toUpperCase();
                        String fromRefField = dfr.getName().toUpperCase();
                        referenceFieldNameMap.put(toRefType, fromRefField);
                        referenceFieldTypeMap.put(fromRefField, toRefType);
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
                || fieldName == 'CLEANSTATUS' // Used by Database.com
                || fieldName == 'JIGSAW');     // Used by Database.com
        }
    }

    @TestVisible
    class NodeValidator implements IValidator {

        public void validate(ATKSpellBook spellBook) {
            Iterator<EntityNode> iterator = spellBook.iterator();
            while (iterator.hasNext()) {
                EntityNode entityNode = iterator.next();
                validateEntityName(entityNode);
                validateTotalAndList(entityNode);
                validateRelationship(entityNode);
                validateXrefFields(entityNode);
            }
        }

        @TestVisible
        void validateEntityName(EntityNode entityNode) {
            Schema.SObjectType objectType = gd.get(entityNode.name);
            if (objectType == null) {
                throw new ATKCommon.IncorrectTypeException(
                    String.format('Cannot find entity {0}.', new List<String> {
                        entityNode.name
                    }));
            }
        }

        @TestVisible
        void validateTotalAndList(EntityNode entityNode) {
            if ((entityNode.total == null || entityNode.total == 0) &&
                (entityNode.repository == null || entityNode.repository.size() == 0)
            ) {
                throw new ATKCommon.InsufficientAttributeException(
                    String.format('Please set either a total() or fromList() to entity {0}.',
                    new List<String> { entityNode.name }));
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

        @TestVisible
        void validateXrefFields(EntityNode entityNode) {
            if (entityNode.fieldRuleMap != null && entityNode.fieldRuleMap.size() > 0) {
                Boolean isValid = true;
                for (String fieldName : entityNode.fieldRuleMap.keySet()) {
                    Object rule = entityNode.fieldRuleMap.get(fieldName);
                    if (rule instanceOf String) {
                        isValid = validateXrefFieldsInit((String)rule, entityNode.fieldInitMap);
                    } else if (rule instanceOf List<String>) {
                        List<String> ruleList = (List<String>)rule;
                        for (String input : ruleList) {
                            isValid = validateXrefFieldsInit(input, entityNode.fieldInitMap);
                            if (!isValid) {
                                break;
                            }
                        }
                    } else if (rule instanceOf Set<String>) {
                        Set<String> ruleList = (Set<String>)rule;
                        for (String input : ruleList) {
                            isValid = validateXrefFieldsInit(input, entityNode.fieldInitMap);
                            if (!isValid) {
                                break;
                            }
                        }
                    }

                    if (!isValid) {
                        throw new ATKCommon.NotFoundException(
                            String.format('The cross reference field {0}.{1} must be initialized with origin() keyword.',
                                new List<String> { entityNode.name, fieldName }));
                    }
                }
            }
        }

        @TestVisible
        Boolean validateXrefFieldsInit(String input, Map<String, Object> fieldInitMap) {
            ATKCommon.MethodGroup methodGroup = METHOD_PARSER.parse(input);
            if (methodGroup.level < ATKCommon.METHOD_GROUP_MAX_LEVEL) {
                for (ATKCommon.Method method : methodGroup.methodList) {
                    if (method instanceof ATKCommon.XrefMethod) {
                        ATKCommon.XrefMethod xrefMethod = (ATKCommon.XrefMethod)method;
                        if (0 < xrefMethod.level && xrefMethod.level < ATKCommon.METHOD_GROUP_MAX_LEVEL) {
                            for (ATKCommon.XrefParam param : xrefMethod.xrefParams) {
                                if (!fieldInitMap.containsKey(param.fieldName)) {
                                    return false;
                                }
                            }
                        }
                    }
                }
            }
            return true;
        }
    }

    class NodeGenerator implements IGenerator {
        Distributor distributor { get; set; }

        NodeGenerator() {
            distributor = new Distributor();
        }

        public void generate(ATKSpellBook spellBook) {
            EVALUATOR.resetRuleIndexCache();
            Iterator<EntityNode> iterator = spellBook.iterator();
            while (iterator.hasNext()) {
                EntityNode entityNode = iterator.next();
                if (entityNode.repository == null || entityNode.repository.size() == 0) {
                    List<SObject> repository = createObjects(entityNode);
                    assignReferences(entityNode);
                    Database.insert(repository);
                } else {
                    List<SObject> repository = updateObjects(entityNode);
                    assignReferences(entityNode);

                    List<SObject> updateList = new List<SObject>();
                    List<SObject> insertList = new List<SObject>();
                    for (SObject obj: repository) {
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

        List<SObject> createObjects(EntityNode entityNode) {
            METHOD_EVALUATOR.workingEntity = entityNode;
            Schema.SObjectType objectType = gd.get(entityNode.name);
            Schema.DescribeSObjectResult dsr = objectType.getDescribe();

            List<SObject> repository = entityNode.repository;
            // for (EntityField field : entityNode.tmpRuleFieldCache) {
            //     List<Object> values = EVALUATOR.getValues(dsr, field.dfr, field.rule, field.hasRule, entityNode.total, 10);
            //     for (Object value : values) {
            //         if (value != null) {
            //             obj.put(field.name, value);
            //         }
            //     }
            // }

            // for (EntityField field : entityNode.tmpXrefFieldCache) {
            //     List<Object> values = EVALUATOR.getValues(dsr, field.dfr, field.rule, field.hasRule, entityNode.total, 10);
            //     for (Object value : values) {
            //         if (value != null) {
            //             obj.put(field.name, value);
            //         }
            //     }
            // }

            for (Integer i = 0; i < entityNode.total; i++) {
                SObject obj = objectType.newSObject();
                repository.add(obj);
                for (EntityField field : entityNode.tmpRuleFieldCache) {
                    Object value = EVALUATOR.getValue(dsr, field.dfr, field.rule, field.hasRule, 10);
                    if (value != null) {
                        obj.put(field.name, value);
                    }
                }

                for (EntityField field : entityNode.tmpXrefFieldCache) {
                    Object value = EVALUATOR.getValue(dsr, field.dfr, field.rule, field.hasRule, 10);
                    if (value != null) {
                        obj.put(field.name, value);
                    }
                }
            }
            return repository;
        }

        List<SObject> updateObjects(EntityNode entityNode) {
            METHOD_EVALUATOR.workingEntity = entityNode;
            Schema.SObjectType objectType = gd.get(entityNode.name);
            Schema.DescribeSObjectResult dsr = objectType.getDescribe();

            List<SObject> repository = entityNode.repository;
            for (Integer i = 0; i < repository.size(); i++) {
                SObject obj = repository[i];
                for (EntityField field : entityNode.tmpRuleFieldCache) {
                    Object value = EVALUATOR.getValue(dsr, field.dfr, field.rule, field.hasRule, 10);
                    if (value != null) {
                        obj.put(field.name, value);
                    }
                }

                for (EntityField field : entityNode.tmpXrefFieldCache) {
                    Object value = EVALUATOR.getValue(dsr, field.dfr, field.rule, field.hasRule, 10);
                    if (value != null) {
                        obj.put(field.name, value);
                    }
                }
            }
            return repository;
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
                    List<List<Object>> pairs = distributor.product2(leftGroup, rightGroup, entityNode.total);
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
                    for (List<Object> pair : distributor.distribute(childObjectList, parentObjectList)) {
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

        Boolean isNotEditableField(Schema.DescribeFieldResult dfr) {
            String fieldName = dfr.getName().toUpperCase();
            return !dfr.isCreateable()
                || dfr.isCalculated()
                || dfr.isAutoNumber()
                || dfr.getType() == Schema.DisplayType.REFERENCE
                || fieldName == 'CLEANSTATUS' // Used by Database.com
                || fieldName == 'JIGSAW';     // Used by Database.com
        }
    }

    @TestVisible
    class FieldEvaluator implements IEvaluator {
        private Map<String, List<String>> picklistCache { get; set; }
        private Map<String, Integer> ruleIndexCache { get; set; }
        private Map<String, Set<Object>> uniqueValueCache { get; set; }
        private Map<String, Object> nonUniqueFieldCache {get; set; }
        private List<String> UNIQUE_VALUE_FORMATS { get; set; }

        @TestVisible
        FieldEvaluator() {
            picklistCache = new Map<String, List<String>>();
            uniqueValueCache = new Map<String, Set<Object>>();
            nonUniqueFieldCache = new Map<String, Object>();
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

        public Object getValue(
            Schema.DescribeSObjectResult dsr,
            Schema.DescribeFieldResult dfr,
            Object rule,
            Boolean hasRule,
            Integer depth) {

            if (depth == 0) {
                throw new ATKCommon.DeepRecursionException(String.format(
                    'Please assign ATKFaker interpolation expression for field {0}.{1} to enforce uniqueness, i.e. {{******}}',
                    new List<String> { dsr.getName(), dfr.getName() }
                ));
            }

            // if (isGeolocationField(dsr, dfr)) {
            //     return null;
            // }

            String key = dsr.getName() + '.' + dfr.getName();
            Object value;

            // System.debug(key + ': ' + dfr.getType());

            if (!hasRule) {
                value = nonUniqueFieldCache.get(key);
                if (dfr.isUnique() || value == null) {
                    value = guessValue(dsr, dfr);
                    if (value != null && !dfr.isUnique()) {
                        nonUniqueFieldCache.put(key, value);
                    }
                }
            } else if (rule instanceOf String) {
                value = fake((String)rule, dfr.getName());
            } else if (rule instanceOf List<String>) {
                value = fake((String)getIndexedRule(key, (List<String>)rule), dfr.getName());
            } else if (rule instanceOf Set<String>) {
                value = fake((String)ATKFaker.random.arrayElement(new List<String>((Set<String>)rule)), dfr.getName());
            } else if (rule instanceOf List<Object>) {
                value = getIndexedRule(key, (List<Object>)rule);
            } else if (rule instanceOf Set<Object>) {
                value = ATKFaker.random.arrayElement(new List<Object>((Set<Object>)rule));
            } else {
                value = rule;
            }

            if (dfr.isUnique() && value != null) {
                if (uniqueValueCache.get(key) == null) {
                    uniqueValueCache.put(key, new Set<Object>());
                }

                if (uniqueValueCache.get(key).contains(value)) {
                    value = getValue(dsr, dfr, rule, hasRule, --depth);
                }
                uniqueValueCache.get(key).add(value);
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

        private Object fake(String input, String fieldName) {
            ATKCommon.MethodGroup methodGroup = METHOD_PARSER.parse(input);
            Integer size = METHOD_EVALUATOR.workingEntity.repository.size();
            if (size < methodGroup.level && methodGroup.level < ATKCommon.METHOD_GROUP_MAX_LEVEL) {
                Object initValue = METHOD_EVALUATOR.workingEntity.fieldInitMap.get(fieldName.toUpperCase());
                if (initValue instanceof List<Object>) {
                    List<Object> initValueList = (List<Object>)initValue;
                    return initValueList[size];
                } else {
                    return initValue;
                }
            }
            return methodGroup.evaluate(METHOD_EVALUATOR);
        }

        Object guessValue(Schema.DescribeSObjectResult dsr, Schema.DescribeFieldResult dfr) {
            // if (isAddressField(dsr, dfr)) {
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
                    value = ATKFaker.random.number(dfr.getPrecision(), dfr.getScale());
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
                when ADDRESS {

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

    public class MethodEvaluator implements ATKCommon.MethodEvaluator, ATKCommon.ParamEvaluator {
        EntityNode workingEntity { get; set; }

        public Object evaluateMethod(ATKCommon.Method method) {
            Object value;
            ATKFaker.IProvider helper = ATKFaker.helperMap.get(method.helperName);
            if (helper != null) {
                if (method instanceof ATKCommon.XrefMethod) {
                    ATKCommon.XrefMethod xrefMethod = (ATKCommon.XrefMethod)method;
                    xrefMethod.loadParams(this);
                }
                value = helper.call(method.name, method.params);
            }
            return value;
        }

        public Object evaluateParam(Integer prevIndex, String fieldName) {
            if (workingEntity == null) {
                return null;
            }

            Integer size = workingEntity.repository.size();
            if (prevIndex <= size) {
                SObject record = workingEntity.repository[size - prevIndex];
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
        private Map<String, List<EntityNode>> entityNodeMap { get; set; }
        @TestVisible
        private EntityNodeMatrix matrix { get; private set; }

        {
            entityNodeMap = new Map<String, List<EntityNode>>();
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
            this.matrix.currentEntitNode.apply(attribute);
        }

        public void pop(Integer depth) {
            this.matrix.pop(depth);
        }

        public List<SObject> query(String entityName) {
            entityName = entityName.toUpperCase();
            List<EntityNode> entityNodeList = entityNodeMap.get(entityName);
            List<SObject> repository = new List<SObject>();
            if (entityNodeList != null) {
                for (EntityNode entityNode : entityNodeList) {
                    repository.addAll(entityNode.repository);
                }
            }
            return repository;
        }

        private void addToEntityNodeMap(EntityNode entityNode) {
            String entityName = entityNode.name;
            if (entityNodeMap.get(entityName) == null) {
                entityNodeMap.put(entityName, new List<EntityNode>());
            }
            entityNodeMap.get(entityName).add(entityNode);
        }
    }

    @TestVisible
    private class EntityNodeMatrix implements Iterator<EntityNode> {
        private Integer rowIndex { get; set; }
        private Integer colIndex { get; set; }
        @TestVisible
        private List<List<EntityNode>> entityNodeMatrix { get; set; }
        private List<EntityNode> entityNodeStack { get; set; }
        private EntityNode currentEntitNode { get; set; }

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
                    this.currentEntitNode = this.entityNodeStack[size - 2];
                }
            }
            rowIndex = this.currentEntitNode.rowIndex;
            colIndex = this.currentEntitNode.colIndex;
        }

        private void add(EntityNode entityNode) {
            switch on entityNode.type {
                when WantMany {
                    rowIndex = 0;
                    colIndex = 0;
                    entityNodeMatrix.add(new List<EntityNode>());
                    entityNodeMatrix.get(rowIndex).add(entityNode);
                }
                when BelongsTo {
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
                when HasMany {
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
            entityNode.parentEntityNode = this.currentEntitNode;
            this.currentEntitNode = entityNode;
        }
    }

    /*
    * ENTITY NODE
    */
    public enum EntityNodeType {
        WantMany,
        BelongsTo,
        HasMany
    }

    class EntityField {
        String name { get; set; }
        Object rule { get; set; }
        Boolean hasRule { get; set; }
        Schema.DescribeFieldResult dfr { get; set; }

        EntityField(String name, Object rule, Boolean hasRule, Schema.DescribeFieldResult dfr) {
            this.name = name;
            if (rule instanceOf String && '{!any.value}'.equals(((String)rule))) {
                this.rule = null;
                this.hasRule = false;
            } else {
                this.rule = rule;
                this.hasRule = hasRule;
            }
            this.dfr = dfr;
        }
    }

    public class EntityNode {
        private Integer rowIndex { get; set; }
        private Integer colIndex { get; set; }
        private EntityNodeType type { get; set; }
        private EntityNode parentEntityNode {
            get;
            set {
                parentEntityNode = value;
                switch on type {
                    when BelongsTo {
                        parentEntityNode.referenceToMap.put(this.name, this);
                    }
                    when HasMany {
                        referenceToMap.put(parentEntityNode.name, parentEntityNode);
                    }
                }
            }
        }
        private List<EntityField> tmpRuleFieldCache { get; set; }
        private List<EntityField> tmpXrefFieldCache { get; set; }

        public String name { get; set; }
        public Integer total { get; set; }
        public Map<String, EntityNode> referenceToMap { get; set; }
        public Map<String, Object> fieldInitMap { get; set; }
        public Map<String, Object> fieldRuleMap { get; set; }
        public List<SObject> repository { get; set; }

        public EntityNode(String name, EntityNodeType type) {
            this.name = name.trim().toUpperCase();
            this.type = type;
            referenceToMap = new Map<String, EntityNode>();
            fieldRuleMap = new Map<String, Object>();
            fieldInitMap = new Map<String, Object>();
            tmpRuleFieldCache = new List<EntityField>();
            tmpXrefFieldCache = new List<EntityField>();
            repository = new List<SObject>();
        }

        private virtual void apply(IEntityAttribute attribute) {
            attribute.apply(this);
        }
    }

    /*
    * ENTITY ATTRIBUTE
    */
    public Interface IEntityAttribute {
        void apply(EntityNode entityNode);
    }

    public Interface IRelatedEntityAttribute extends IEntityAttribute {

    }

    public class TotalAttribute implements IEntityAttribute, IRelatedEntityAttribute {
        private Integer total { get; set; }
        public TotalAttribute(Integer total) {
            this.total = total;
        }

        public void apply(EntityNode entityNode) {
            entityNode.total = total;
        }
    }

    public class FromListAttribute implements IEntityAttribute, IRelatedEntityAttribute {
        private List<SObject> repository { get; set; }

        public FromListAttribute(List<SObject> repository) {
            this.repository = repository;
        }

        public void apply(EntityNode entityNode) {
            entityNode.repository.addAll(repository);
            IEntityAttribute totalAttribute = new TotalAttribute(repository.size());
            totalAttribute.apply(entityNode);
        }
    }

    public virtual class FieldAttribute implements IEntityAttribute, IRelatedEntityAttribute {
        protected Map<String, Object> fieldRuleMap { get; set; }

        public FieldAttribute(Map<String, Object> fieldRuleMap) {
            this.fieldRuleMap = new Map<String, Object>();
            for (String key : fieldRuleMap.keySet()) {
                this.fieldRuleMap.put(key.trim().toUpperCase(), fieldRuleMap.get(key));
            }
        }

        public virtual void apply(EntityNode entityNode) {
            entityNode.fieldRuleMap.putAll(fieldRuleMap);
        }
    }

    public class OriginFieldAttribute extends FieldAttribute {
        public OriginFieldAttribute(Map<String, Object> fieldRuleMap) {
            super(fieldRuleMap);
        }

        public override void apply(EntityNode entityNode) {
            entityNode.fieldInitMap.putAll(fieldRuleMap);
        }
    }

    public class ReferenceByAttribute implements IRelatedEntityAttribute {
        private String referenceBy { get; set; }
        public ReferenceByAttribute(String referenceBy) {
            this.referenceBy = referenceBy.trim().toUpperCase();
        }

        public void apply(EntityNode entityNode) {
            switch on entityNode.type {
                when BelongsTo {
                    entityNode.parentEntityNode.referenceToMap.remove(entityNode.name);
                    entityNode.parentEntityNode.referenceToMap.put(referenceBy, entityNode);
                }
                when HasMany {
                    entityNode.referenceToMap.remove(entityNode.parentEntityNode.name);
                    entityNode.referenceToMap.put(referenceBy, entityNode.parentEntityNode);
                }
            }
        }
    }
}
