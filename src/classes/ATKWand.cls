/**
 * Apex Test Kit
 */
public with sharing class ATKWand {
    private static Map<String, Schema.SObjectType> gd { get; set; }
    private static final ItemsDistributor itemsDistributor = new ItemsDistributor();
    private static final FieldEvaluator fieldEvaluator = new FieldEvaluator();
    private static final NodesValidator nodesValidator = new NodesValidator();
    public static final ATKCommon.MethodParser parser = ATKCommon.parser;
    private static final MethodEvaluator methodEvaluator = new MethodEvaluator();

    static {
        gd = Schema.getGlobalDescribe();
    }

    public static void validate(ATKSpellBook spellBook) {
        nodesValidator.validate(spellBook);
    }

    public static void generate(ATKSpellBook spellBook) {
        fieldEvaluator.resetRuleIndexCache();
        Iterator<ATKSpellBook.EntityNode> iterator = spellBook.iterator();
        while (iterator.hasNext()) {
            ATKSpellBook.EntityNode entityNode = iterator.next();
            if (entityNode.repository == null || entityNode.repository.size() == 0) {
                List<SObject> repository = createObjects(entityNode);
                assignReferences(entityNode);
                Database.insert(repository);
            } else {
                List<SObject> repository = updateObjects(entityNode);
                assignReferences(entityNode);
                Database.update(repository);
            }
        }
    }

    private static Object fake(String input, String fieldName) {
        ATKCommon.MethodGroup methodGroup = parser.parse(input);
        Integer size = methodEvaluator.workingEntity.repository.size();
        if (size < methodGroup.level && methodGroup.level < ATKCommon.METHOD_GROUP_MAX_LEVEL) {
            Object initValue = methodEvaluator.workingEntity.fieldInitMap.get(fieldName.toUpperCase());
            if (initValue instanceof List<Object>) {
                List<Object> initValueList = (List<Object>)initValue;
                return initValueList[size];
            } else {
                return initValue;
            }
        }
        return methodGroup.evaluate(methodEvaluator);
    }

    public class MethodEvaluator implements ATKCommon.MethodEvaluator, ATKCommon.ParamEvaluator {
        ATKSpellBook.EntityNode workingEntity { get; set; }

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

    class NodesValidator {
        public void validate(ATKSpellBook spellBook) {
            Iterator<ATKSpellBook.EntityNode> iterator = spellBook.iterator();
            while (iterator.hasNext()) {
                ATKSpellBook.EntityNode entityNode = iterator.next();
                validateTotalAndList(entityNode);
                validateRelationship(entityNode);
                validateXrefFields(entityNode);
            }
        }

        void validateTotalAndList(ATKSpellBook.EntityNode entityNode) {
            if ((entityNode.total == null || entityNode.total == 0) &&
                (entityNode.repository == null || entityNode.repository.size() == 0)
            ) {
                throw new ATKCommon.InsufficientAttributeException(
                    String.format('Please set either a total() or fromList() to entity {0}.',
                        new List<String> { entityNode.name }));
            }
        }

        void validateRelationship(ATKSpellBook.EntityNode entityNode) {
            if (entityNode.referenceToMap != null && entityNode.referenceToMap.size() > 0) {
                Schema.SObjectType objectType = gd.get(entityNode.name);
                Schema.DescribeSObjectResult dsr = objectType.getDescribe();
                Map<String, SObjectField> fieldMap = dsr.fields.getMap();
                for (String fieldName : entityNode.referenceToMap.keySet()) {
                    SObjectField field = fieldMap.get(fieldName);
                    if (field == null) {
                        throw new ATKCommon.NotFoundException(
                            String.format('The relationship field ({0}.{1}) can not be found.',
                                new List<String> { entityNode.name, fieldName }));
                    }
                    Schema.DescribeFieldResult dfr = field.getDescribe();
                    List<Schema.SObjectType> referenceToTypeList = dfr.getReferenceTo();
                    Boolean incorrectType = true;
                    ATKSpellBook.EntityNode referenceTo = entityNode.referenceToMap.get(fieldName);
                    for (Schema.SObjectType referenceToType : referenceToTypeList) {
                        Schema.DescribeSObjectResult refDsr = referenceToType.getDescribe();
                        if (refDsr.getName().toUpperCase() == referenceTo.Name) {
                            incorrectType = false;
                        }
                    }
                    if (incorrectType) {
                        throw new ATKCommon.IncorrectTypeException(
                            String.format('The relationship field ({0}.{1}) is not referenced to entity ({2}).',
                                new List<String> { entityNode.name, fieldName, referenceTo.name }));
                    }
                }
            }
        }

        void validateXrefFields(ATKSpellBook.EntityNode entityNode) {
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
                            String.format('The field ({0}.{1}) is used in cross reference fields, and must be initialized with fieldsInit().',
                                new List<String> { entityNode.name, fieldName }));
                    }
                }
            }
        }

        Boolean validateXrefFieldsInit(String input, Map<String, Object> fieldInitMap) {
            ATKCommon.MethodGroup methodGroup = ATKFaker.parser.parse(input);
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

    private static List<SObject> createObjects(ATKSpellBook.EntityNode entityNode) {
        methodEvaluator.workingEntity = entityNode;
        Schema.SObjectType objectType = gd.get(entityNode.name);
        Schema.DescribeSObjectResult dsr = objectType.getDescribe();
        Set<String> fieldNameSet = entityNode.fieldRuleMap.keySet();
        Set<String> xrefsNameSet = entityNode.fieldInitMap.keySet();

        List<SObject> repository = entityNode.repository;
        for (Integer i = 0; i < entityNode.total; i++) {
            SObject obj = objectType.newSObject();
            for (SObjectField field : dsr.fields.getMap().values()) {
                Schema.DescribeFieldResult dfr = field.getDescribe();
                String fieldName = dfr.getName().toUpperCase();
                if (xrefsNameSet.contains(fieldName)) {
                    break;
                }
                Boolean hasRule = fieldNameSet.contains(fieldName);
                Object rule = entityNode.fieldRuleMap.get(fieldName);
                Object value = fieldEvaluator.randomFieldValue(dsr, dfr, rule, hasRule, 10);
                if (value != null) {
                    obj.put(fieldName, value);
                }
            }

            for (String fieldName : xrefsNameSet) {
                SObjectField field = dsr.fields.getMap().get(fieldName);
                Schema.DescribeFieldResult dfr = field.getDescribe();
                Object rule = entityNode.fieldRuleMap.get(fieldName);
                Object value = fieldEvaluator.randomFieldValue(dsr, dfr, rule, true, 10);
                if (value != null) {
                    obj.put(fieldName, value);
                }
            }

            repository.add(obj);
        }
        return repository;
    }

    private static List<SObject> updateObjects(ATKSpellBook.EntityNode entityNode) {
        methodEvaluator.workingEntity = entityNode;
        Schema.SObjectType objectType = gd.get(entityNode.name);
        Schema.DescribeSObjectResult dsr = objectType.getDescribe();
        Set<String> fieldNameSet = entityNode.fieldRuleMap.keySet();

        List<SObject> repository = entityNode.repository;
        entityNode.repository = new List<SObject> ();
        for (Integer i = 0; i < repository.size(); i++) {
            SObject obj = repository[i];
            for (String fieldName : fieldNameSet) {
                SObjectField field = dsr.fields.getMap().get(fieldName);
                Schema.DescribeFieldResult dfr = field.getDescribe();
                Object rule = entityNode.fieldRuleMap.get(fieldName);
                Object value = fieldEvaluator.randomFieldValue(dsr, dfr, rule, true, 10);
                if (value != null) {
                    obj.put(fieldName, value);
                }
            }
            entityNode.repository.add(obj);
        }
        return repository;
    }

    private static void assignReferences(ATKSpellBook.EntityNode entityNode) {
        if (entityNode.referenceToMap != null
            && entityNode.referenceToMap.size() > 0
            && entityNode.repository != null) {

            List<String> fieldNames = new List<String>(entityNode.referenceToMap.keySet());
            List<SObject> childObjectList = entityNode.repository;

            if (fieldNames.size() >= 2) {
                List<SObject> leftGroup = entityNode.referenceToMap.get(fieldNames[0]).repository;
                List<SObject> rightGroup = entityNode.referenceToMap.get(fieldNames[1]).repository;
                List<List<Object>> pairs = itemsDistributor.product2(leftGroup, rightGroup, entityNode.total);
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
                for (List<Object> pair : itemsDistributor.distribute(childObjectList, parentObjectList)) {
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

    @TestVisible
    class ItemsDistributor {
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

    class FieldEvaluator {
        private Map<String, List<String>> picklistCache { get; set; }
        private Map<String, Set<String>> addressFieldCache { get; set; }
        private Map<String, Set<String>> geolocationFieldCache { get; set; }
        private Map<String, Set<Object>> uniqueValueCache { get; set; }
        private Map<String, Integer> ruleIndexCache { get; set; }

        FieldEvaluator() {
            picklistCache = new Map<String, List<String>>();
            addressFieldCache = new Map<String, Set<String>>();
            geolocationFieldCache = new Map<String, Set<String>>();
            uniqueValueCache = new Map<String, Set<Object>>();
            ruleIndexCache = new Map<String, Integer>();
        }

        void resetRuleIndexCache() {
            ruleIndexCache = new Map<String, Integer>();
        }

        Object randomFieldValue(
            Schema.DescribeSObjectResult dsr,
            Schema.DescribeFieldResult dfr,
            Object rule,
            Boolean hasRule,
            Integer depth) {

            if (depth == 0) {
                throw new ATKCommon.DeepRecursionException(String.format(
                    'Please adjust field ({0}) generation rule to allow uniqueness more likely to happen',
                    new List<String>{
                        dfr.getName()
                    }));
            }

            String key = dsr.getName() + '.' + dfr.getName();
            Object value;
            if (isGeolocationField(dsr, dfr)) {
                return value;
            }

            if (!hasRule) {
                value = defaultRandomFieldValue(dsr, dfr);
            } else if (rule instanceOf String) {
                value = fake((String) rule, dfr.getName());
            } else if (rule instanceOf List<String>) {
                value = fake((String) getIndexedRule(key, (List<String>) rule), dfr.getName());
            } else if (rule instanceOf Set<String>) {
                value = fake((String) ATKFaker.random.arrayElement(new List<String>((Set<String>) rule)), dfr.getName());
            } else if (rule instanceOf List<Object>) {
                value = getIndexedRule(key, (List<Object>) rule);
            } else if (rule instanceOf Set<Object>) {
                value = ATKFaker.random.arrayElement(new List<Object>((Set<Object>) rule));
            } else {
                value = rule;
            }

            if (dfr.isUnique()) {
                if (uniqueValueCache.get(key) == null) {
                    uniqueValueCache.put(key, new Set<Object>());
                }

                if (uniqueValueCache.get(key).contains(value)) {
                    value = randomFieldValue(dsr, dfr, rule, hasRule, --depth);
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

        Object defaultRandomFieldValue(Schema.DescribeSObjectResult dsr, Schema.DescribeFieldResult dfr) {
            Object value;
            if (isNotEditableField(dfr) || isAddressField(dsr, dfr)) {
                return value;
            }
            // System.debug(dfr.getName() + ': ' + dfr.getType());
            switch on dfr.getType() {
                when BOOLEAN {
                    value = ATKFaker.random.boolean();
                }
                when DATE {
                    value = ATKCommon.converter.toDate(ATKFaker.dates.past());
                }
                when DATETIME {
                    value = ATKFaker.dates.past();
                }
                when TIME {
                    value = ATKCommon.converter.toTime(ATKFaker.dates.past());
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
                    System.debug('Double - ' + fieldName + ': ' + value);
                }
                when INTEGER {
                    value = Integer.valueOf(ATKFaker.random.number(dfr.getPrecision(), dfr.getScale()));
                }
                when PERCENT {
                    value = ATKFaker.random.number(0, 1, 2);
                }
                when CURRENCY {
                    value = ATKFaker.random.number(dfr.getPrecision(), dfr.getScale());
                }
                when PICKLIST {
                    List<String> picklistValues = getPicklistValues(dsr, dfr);
                    value = (String) ATKFaker.random.arrayElement(picklistValues);
                }
                when MULTIPICKLIST {
                    List<String> picklistValues = (List<String>) getPicklistValues(dsr, dfr);
                    List<String> values = (List<String>) ATKFaker.random.arrayElements(picklistValues);
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
                    Integer count;
                    if (dfr.isUnique()) {
                        count = length / 5;
                    }
                    String output = ATKFaker.lorem.words(count);
                    if (String.isNotEmpty(output) && output.length() > length) {
                        output = output.left(length);
                    }
                    value = output;
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

        Boolean isNotEditableField(Schema.DescribeFieldResult dfr) {
            String fieldName = dfr.getName().toUpperCase();
            return dfr.isCalculated()
                || dfr.isAutoNumber()
                || !dfr.isCreateable()
                || dfr.getType() == Schema.DisplayType.REFERENCE
                || fieldName == 'CLEANSTATUS' // Used by Database.com
                || fieldName == 'JIGSAW';     // Used by Database.com
        }

        Boolean isGeolocationField(Schema.DescribeSObjectResult dsr, Schema.DescribeFieldResult dfr) {
            Set<String> geolocationFieldSet = getGeolocationFields(dsr);
            return geolocationFieldSet.contains(dfr.getName().toUpperCase());
        }

        Set<String> getGeolocationFields(Schema.DescribeSObjectResult dsr) {
            String objectName = dsr.getName();
            if (geolocationFieldCache.get(objectName) == null) {
                Set<String> geolocationFieldSet = new Set<String>();
                Map<String, SObjectField> fieldMemeberMap = dsr.fields.getMap();
                for (SObjectField field : fieldMemeberMap.values()) {
                    Schema.DescribeFieldResult dfr = field.getDescribe();
                    String fieldName = dfr.getName().toUpperCase();
                    if (fieldName.endsWith('__LATITUDE__S')) {
                        geolocationFieldSet.add(fieldName.replace('__LATITUDE__S', '__C'));
                    } else if (fieldName.endsWith('__LONGITUDE__S')) {
                        geolocationFieldSet.add(fieldName.replace('__LONGITUDE__S', '__C'));
                    }
                }
                geolocationFieldSet.add('LONGITUDE');
                geolocationFieldSet.add('LATITUDE');
                System.debug('geolocation of ' + objectName + ': ' + geolocationFieldSet);
                geolocationFieldCache.put(objectName, geolocationFieldSet);
            }
            return geolocationFieldCache.get(objectName);
        }

        Boolean isAddressField(Schema.DescribeSObjectResult dsr, Schema.DescribeFieldResult dfr) {
            Set<String> addressFieldSet = getAddressFields(dsr);
            return addressFieldSet.contains(dfr.getName().toUpperCase());
        }

        Set<String> getAddressFields(Schema.DescribeSObjectResult dsr) {
            String objectName = dsr.getName();
            if (addressFieldCache.get(objectName) == null) {
                Set<String> addressFieldSet = new Set<String>();
                Map<String, SObjectField> fieldMemeberMap = dsr.fields.getMap();
                for (SObjectField field : fieldMemeberMap.values()) {
                    Schema.DescribeFieldResult dfr = field.getDescribe();
                    if (dfr.getType() == Schema.DisplayType.ADDRESS) {
                        String addressPrefix = dfr.getName().toUpperCase().replace('ADDRESS', '');
                        addressFieldSet.add(addressPrefix + 'STREET');
                        addressFieldSet.add(addressPrefix + 'CITY');
                        addressFieldSet.add(addressPrefix + 'STATE');
                        addressFieldSet.add(addressPrefix + 'POSTALCODE');
                        addressFieldSet.add(addressPrefix + 'COUNTRY');
                        addressFieldSet.add(addressPrefix + 'LATITUDE');
                        addressFieldSet.add(addressPrefix + 'LONGITUDE');
                        addressFieldSet.add(addressPrefix + 'GEOCODEACCURACY');
                    }
                }
                addressFieldCache.put(objectName, addressFieldSet);
            }
            return addressFieldCache.get(objectName);
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
}
