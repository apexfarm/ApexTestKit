/**
 * Apex Test Kit
 */
public with sharing class ATKWand {
    private static Map<String, Schema.SObjectType> gd { get; set; }
    private static final ATKCommon.MethodParser METHOD_PARSER = ATKCommon.METHOD_PARSER;
    private static final MethodEvaluator METHOD_EVALUATOR = new MethodEvaluator();

    private static final ISchemator SCHEMATOR = new FieldSchemator();
    private static final IValidator VALIDATOR = new NodeValidator();
    private static final IGenerator GENERATOR = new NodeGenerator();
    private static final IEvaluator EVALUATOR = new FieldEvaluator();

    static {
        gd = Schema.getGlobalDescribe();
    }

    public static void generate(ATKSpellBook spellBook) {
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
        void resetRuleIndexCache();
        Object evaluate(
            Integer recordIndex,
            DescribeSObjectResult dsr,
            EntityField field,
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


            Boolean hasRule = true;
            for (SObjectField field : dsr.fields.getMap().values()) {
                Schema.DescribeFieldResult dfr = field.getDescribe();
                String fieldName = dfr.getName().toUpperCase();

                // System.debug(objectName + '.' + fieldName
                //     + ' : isNillable(' + dfr.isNillable()
                //     + '), precision(' + dfr.getPrecision()
                //     + '), scale(' + dfr.getScale()
                //     + '), type(' + dfr.getType()
                //     + ')');

                // rebuild dynamic caches
                if (entityNode.fieldRuleMap.containsKey(fieldName)) {
                    Object rule = entityNode.fieldRuleMap.get(fieldName);
                    if (rule != null) {
                        if (detectedXrefMethod(rule)) {
                            entityNode.fieldXrefMap.put(fieldName, rule);
                            entityNode.tmpXrefFieldCache.add(new XrefEntityField(fieldName, hasRule, rule, dfr));
                            continue;
                        }
                    }
                    entityNode.tmpRuleFieldCache.add(new EntityField(fieldName, hasRule, rule, dfr));
                } else if (entityNode.guessFieldNames.contains(fieldName)) {
                    entityNode.tmpRuleFieldCache.add(new EntityField(fieldName, !hasRule, null, dfr));
                } else if (entityNode.guessEnabled && (!dfr.isNillable() && isEditableField(dfr))) {
                    entityNode.tmpRuleFieldCache.add(new EntityField(fieldName, !hasRule, null, dfr));
                }

                // no need to rebuild static caches
                if (addressFieldSet != null) {
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
            entityNode.tmpXrefFieldCache.sort();
        }

        public Boolean detectedXrefMethod(Object rule) {
            Boolean hasXrefMethod = false;
            List<ATKCommon.MethodGroup> methodGroups = new List<ATKCommon.MethodGroup>();
            if (rule instanceOf String) {
                ATKCommon.MethodGroup methodGroup = METHOD_PARSER.parse((String)rule);
                methodGroups.add(methodGroup);
                hasXrefMethod = methodGroup.hasXrefMethod;
            }
            // else if (rule instanceOf List<String>) {
            //     List<String> ruleList = (List<String>)rule;
            //     for (String input : ruleList) {
            //         ATKCommon.MethodGroup methodGroup = METHOD_PARSER.parse((String)input);
            //         methodGroups.add(methodGroup);
            //         if (methodGroup.hasXrefMethod) {
            //             hasXrefMethod = methodGroup.hasXrefMethod;
            //         }
            //     }
            // } else if (rule instanceOf Set<String>) {
            //     Set<String> ruleList = (Set<String>)rule;
            //     for (String input : ruleList) {
            //         ATKCommon.MethodGroup methodGroup = METHOD_PARSER.parse((String)input);
            //         methodGroups.add(methodGroup);
            //         if (methodGroup.hasXrefMethod) {
            //             hasXrefMethod = methodGroup.hasXrefMethod;
            //         }
            //     }
            // }
            return hasXrefMethod;
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
                    String.format('Cannot find sObject type {0}.', new List<String> {
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
                    String.format('Please set either total() or fromList() for sObject type {0}.',
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
            if (entityNode.fieldXrefMap != null) {
                for (String fieldName : entityNode.fieldXrefMap.keySet()) {
                    Object rule = entityNode.fieldXrefMap.get(fieldName);
                    if (rule instanceOf String) {
                        validateXrefFieldOrigin(fieldName, (String)rule, entityNode);
                    }
                }
            }

            if (entityNode.fieldRuleMap != null) {
                for (String fieldName : entityNode.fieldRuleMap.keySet()) {
                    Object rule = entityNode.fieldRuleMap.get(fieldName);
                    if (rule instanceOf List<String>) {
                        List<String> ruleList = (List<String>)rule;
                        for (String input : ruleList) {
                            validateXrefFieldNotInList(fieldName, input, entityNode);
                        }
                    } else if (rule instanceOf Set<String>) {
                        Set<String> ruleList = (Set<String>)rule;
                        for (String input : ruleList) {
                            validateXrefFieldNotInList(fieldName, input, entityNode);
                        }
                    }
                }
            }
        }

        @TestVisible
        void validateXrefFieldOrigin(String fieldName, String input, EntityNode entityNode) {
            ATKCommon.MethodGroup methodGroup = METHOD_PARSER.parse(input);
            if (methodGroup.hasXrefMethod) {
                for (ATKCommon.Method method : methodGroup.methodList) {
                    if (method instanceof ATKCommon.XrefMethod) {
                        ATKCommon.XrefMethod xrefMethod = (ATKCommon.XrefMethod)method;
                        if (0 < xrefMethod.level) {
                            for (ATKCommon.XrefParam param : xrefMethod.xrefParams) {
                                if (0 < param.level && !entityNode.fieldInitMap.containsKey(fieldName)) {
                                    throw new ATKCommon.NotFoundException(
                                        String.format('The cross reference field {0}.{1} must be initialized with origin() keyword.',
                                        new List<String> { entityNode.Name, fieldName })
                                    );
                                }
                            }
                        }
                    }
                }
            }
        }

        @TestVisible
        void validateXrefFieldNotInList(String fieldName, String input, EntityNode entityNode) {
            ATKCommon.MethodGroup methodGroup = METHOD_PARSER.parse(input);
            if (methodGroup.hasXrefMethod) {
                for (ATKCommon.Method method : methodGroup.methodList) {
                    if (method instanceof ATKCommon.XrefMethod) {
                        throw new ATKCommon.NotFoundException(
                            String.format('The cross reference field {0}.{1} connot be used in rule list or rule set.',
                            new List<String> { entityNode.Name, fieldName })
                        );
                    }
                }
            }
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
                if (entityNode.repository.size() == 0) {
                    Schema.SObjectType objectType = gd.get(entityNode.name);
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
            METHOD_EVALUATOR.currentEntity = entityNode;
            Schema.SObjectType objectType = gd.get(entityNode.name);
            Schema.DescribeSObjectResult dsr = objectType.getDescribe();

            List<SObject> repository = entityNode.repository;
            Integer total = repository.size();
            for (EntityField field : entityNode.tmpRuleFieldCache) {
                for (Integer i = 0; i < total; i++) {
                    Object value = EVALUATOR.evaluate(i, dsr, field, 10);
                    if (value != null) {
                        SObject record = repository[i];
                        record.put(field.name, value);
                    }
                }
            }

            for (Integer i = 0; i < total; i++) {
               for (EntityField field : entityNode.tmpXrefFieldCache) {
                    Object value = EVALUATOR.evaluate(i, dsr, field, 10);
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

        public Object evaluate(
            Integer recordIndex,
            DescribeSObjectResult dsr,
            EntityField field,
            Integer depth) {

            Schema.DescribeFieldResult dfr = field.dfr;
            Boolean isUnique = dfr.isUnique();
            Schema.DisplayType fieldType = dfr.getType();
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
                    value = getValue(recordIndex, dsr, field, key);
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
                value = getValue(recordIndex, dsr, field, key);
            }

            switch on fieldType {
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

        public Object getValue(Integer recordIndex, DescribeSObjectResult dsr, EntityField field, String key) {
            Schema.DescribeFieldResult dfr = field.dfr;
            Object rule = field.rule;
            FieldRuleType ruleType = field.ruleType;

            Object value;
            switch on ruleType {
                when StringRule {
                    value = fake(recordIndex, dfr.getName(), (String)rule);
                }
                when StringList {
                    value = fake(recordIndex, dfr.getName(), (String)getIndexedRule(key, (List<String>)rule));
                }
                when StringSet {
                    value = fake(recordIndex, dfr.getName(), (String)ATKFaker.random.arrayElement(new List<String>((Set<String>)rule)));
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

        private Object fake(Integer recordIndex, String fieldName, String input) {
            METHOD_EVALUATOR.currentRecordIndex = recordIndex;
            METHOD_EVALUATOR.currentFieldName = fieldName.toUpperCase();
            ATKCommon.MethodGroup methodGroup = METHOD_PARSER.parse(input);
            return methodGroup.evaluate(METHOD_EVALUATOR);
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
        EntityNode currentEntity { get; set; }
        Integer currentRecordIndex { get; set; }
        String currentFieldName { get; set; }

        public Object evaluateMethod(ATKCommon.Method method) {
            Object value;
            ATKFaker.IProvider helper = ATKFaker.helperMap.get(method.helperName);
            if (helper != null) {
                if (method instanceof ATKCommon.XrefMethod) {
                    ATKCommon.XrefMethod xrefMethod = (ATKCommon.XrefMethod)method;
                    if (this.currentRecordIndex < xrefMethod.level && xrefMethod.level < ATKCommon.METHOD_GROUP_MAX_LEVEL) {
                        Object initValue = currentEntity.fieldInitMap.get(currentFieldName);
                        if (initValue instanceof List<Object>) {
                            List<Object> initValueList = (List<Object>)initValue;
                            return initValueList[this.currentRecordIndex];
                        } else {
                            return initValue;
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

    enum FieldRuleType {
        StringRule,
        StringList,
        StringSet,
        ObjectList,
        ObjecSet,
        ValueRule,
        FeelLuck
    }

    public class XrefEntityField extends EntityField implements Comparable {
        XrefEntityField(String name, Boolean hasRule, Object rule, Schema.DescribeFieldResult dfr) {
            super(name, hasRule, rule, dfr);
        }

        public Integer compareTo(Object toObj) {
            EntityField field = this;
            EntityField toField = (EntityField)toObj;
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

    public virtual class EntityField  {
        String name { get; set; }
        Object rule { get; set; }
        FieldRuleType ruleType { get; set; }
        Boolean hasRule { get; set; }
        Schema.DescribeFieldResult dfr { get; set; }

        EntityField(String name, Boolean hasRule, Object rule, Schema.DescribeFieldResult dfr) {
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

    public class EntityNode {
        // Graph Properties
        Integer rowIndex { get; set; }
        Integer colIndex { get; set; }
        EntityNodeType type { get; set; }
        EntityNode parentEntityNode {
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

        // Entity Attributes
        public String name { get; set; }
        public Integer total { get; set; }
        public Map<String, EntityNode> referenceToMap { get; set; }
        public Map<String, Object> fieldInitMap { get; set; }
        public Map<String, Object> fieldRuleMap { get; set; }
        public Map<String, Object> fieldXrefMap { get; set; }
        public Boolean guessEnabled { get; set; }
        public List<String> guessFieldNames { get; set; }

        public List<SObject> repository { get; set; }
        List<EntityField> tmpRuleFieldCache { get; set; }
        List<XrefEntityField> tmpXrefFieldCache { get; set; }

        public EntityNode(String name, EntityNodeType type) {
            this.name = name.trim().toUpperCase();
            this.type = type;
            this.referenceToMap = new Map<String, EntityNode>();
            this.fieldInitMap = new Map<String, Object>();
            this.fieldRuleMap = new Map<String, Object>();
            this.fieldXrefMap = new Map<String, Object>();
            this.tmpRuleFieldCache = new List<EntityField>();
            this.tmpXrefFieldCache = new List<XrefEntityField>();
            this.repository = new List<SObject>();
            this.guessEnabled = true;
            this.guessFieldNames = new List<String>();
        }

        void apply(IEntityAttribute attribute) {
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
            if (entityNode.repository.size() == 0) {
                entityNode.total = total;
            } else {
                entityNode.total = entityNode.repository.size();
            }
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

    public class GuessAttribute implements IEntityAttribute, IRelatedEntityAttribute {
        private Boolean guessEnabled { get; set; }
        private List<String> guessFieldNames { get; set; }

        public GuessAttribute(Boolean guessEnabled, List<String> guessFieldNames) {
            this.guessEnabled = guessEnabled;
            this.guessFieldNames = new List<String>();
            for(String fieldName : guessFieldNames) {
                this.guessFieldNames.add(fieldName.toUpperCase());
            }
        }

        public GuessAttribute(List<String> guessFieldNames) {
            this(true, guessFieldNames);
        }

        public GuessAttribute(Boolean guessEnabled) {
            this(guessEnabled, new List<String>());
        }

        public void apply(EntityNode entityNode) {
            entityNode.guessEnabled = this.guessEnabled;
            entityNode.guessFieldNames = this.guessFieldNames;
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
