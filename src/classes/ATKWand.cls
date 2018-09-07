/**
 * Apex Test Kit
 */
public with sharing class ATKWand {
    private static Map<String, Schema.SObjectType> gd { get; set; }
    public static final ATKCommon.MethodParser parser = ATKCommon.parser;
    private static final MethodEvaluator methodEvaluator = new MethodEvaluator();

    private static final IValidator nodeValidator = new NodeValidator();
    private static final IGenerator nodeGenerator = new NodeGenerator();

    static {
        gd = Schema.getGlobalDescribe();
    }

    public static void validate(ATKSpellBook spellBook) {
        nodeValidator.validate(spellBook);
    }

    public static void generate(ATKSpellBook spellBook) {
        nodeGenerator.generate(spellBook);
    }

    interface IValidator {
        void validate(ATKSpellBook spellBook);
    }

    interface IGenerator {
        void generate(ATKSpellBook spellBook);
    }
    
    interface IFieldEvaluator {
        void resetRuleIndexCache();
        Object getValue(
            Schema.DescribeSObjectResult dsr,
            Schema.DescribeFieldResult dfr,
            Object rule, Boolean hasRule, Integer depth);
    }

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

        void validateTotalAndList(EntityNode entityNode) {
            if ((entityNode.total == null || entityNode.total == 0) &&
                (entityNode.repository == null || entityNode.repository.size() == 0)
            ) {
                throw new ATKCommon.InsufficientAttributeException(
                    String.format('Please set either a total() or fromList() to entity {0}.',
                    new List<String> { entityNode.name }));
            }
        }

        void validateRelationship(EntityNode entityNode) {
            if (entityNode.referenceToMap != null && entityNode.referenceToMap.size() > 0) {
                Schema.SObjectType objectType = gd.get(entityNode.name);
                Schema.DescribeSObjectResult dsr = objectType.getDescribe();
                Map<String, SObjectField> fieldMap = dsr.fields.getMap();
                
                Map<String, String> fieldNameMap = new Map<String, String>();
                for (SObjectField field : fieldMap.values()) {
                    Schema.DescribeFieldResult dfr = field.getDescribe();
                    if (dfr.getType() == Schema.DisplayType.REFERENCE) {
                        for (Schema.SObjectType rst : dfr.getReferenceTo()) {
                            fieldNameMap.put(
                                rst.getDescribe().getName().toUpperCase(), 
                                dfr.getName().toUpperCase());
                        }
                    }
                }

                for (String fieldName : entityNode.referenceToMap.keySet()) {
                    EntityNode referenceTo = entityNode.referenceToMap.get(fieldName);
                    if (fieldName == referenceTo.Name) {
                        String referenceFieldName = fieldNameMap.get(referenceTo.Name);
                        if (referenceFieldName == null) {
                            throw new ATKCommon.IncorrectTypeException(
                                String.format('The relationship field ({0}.{1}) to entity ({2}) doesn\'t exist.',
                                new List<String> { entityNode.name, fieldName, referenceTo.name }));
                        } else if (referenceFieldName != fieldName) {
                            if (entityNode.referenceToMap.get(referenceFieldName) != null) {
                                throw new ATKCommon.IncorrectTypeException(
                                    String.format('The relationship field ({0}.{1}) to entity ({2}) should not be used multiple times.',
                                    new List<String> { entityNode.name, fieldName, referenceTo.name }));
                            }
                            entityNode.referenceToMap.remove(fieldName);
                            entityNode.referenceToMap.put(referenceFieldName, referenceTo);
                        }
                    } else {
                        SObjectField field = fieldMap.get(fieldName);
                        if (field == null) {
                            throw new ATKCommon.NotFoundException(
                                String.format('The relationship field ({0}.{1}) to entity ({2}) doesn\'t exist.',
                                new List<String> { entityNode.name, fieldName, referenceTo.name }));
                        }

                        Boolean incorrectType = true;
                        Schema.DescribeFieldResult dfr = field.getDescribe();
                        for (Schema.SObjectType referenceToType : dfr.getReferenceTo()) {
                            Schema.DescribeSObjectResult refDsr = referenceToType.getDescribe();
                            if (refDsr.getName().toUpperCase() == referenceTo.Name) {
                                incorrectType = false;
                            }
                        }
                        if (incorrectType) {
                            throw new ATKCommon.IncorrectTypeException(
                                String.format('The relationship field ({0}.{1}) doesn\'t reference to entity ({2}).',
                                new List<String> { entityNode.name, fieldName, referenceTo.name }));
                        }
                    }
                }
            }
        }

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
                            String.format('The cross reference field ({0}.{1}) must be initialized with origin() keyword.',
                                new List<String> { entityNode.name, fieldName }));
                    }
                }
            }
        }

        Boolean validateXrefFieldsInit(String input, Map<String, Object> fieldInitMap) {
            ATKCommon.MethodGroup methodGroup = parser.parse(input);
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
        IFieldEvaluator fieldEvaluator { get; set; }
        Distributor distributor { get; set; }

        NodeGenerator() {
            fieldEvaluator = new FieldEvaluator();
            distributor = new Distributor();
        }

        public void generate(ATKSpellBook spellBook) {
            fieldEvaluator.resetRuleIndexCache();
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
                    Database.update(repository);
                }
            }
        }

        List<SObject> createObjects(EntityNode entityNode) {
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
                    Object value = fieldEvaluator.getValue(dsr, dfr, rule, hasRule, 10);
                    if (value != null) {
                        obj.put(fieldName, value);
                    }
                }

                for (String fieldName : xrefsNameSet) {
                    SObjectField field = dsr.fields.getMap().get(fieldName);
                    Schema.DescribeFieldResult dfr = field.getDescribe();
                    Object rule = entityNode.fieldRuleMap.get(fieldName);
                    Object value = fieldEvaluator.getValue(dsr, dfr, rule, true, 10);
                    if (value != null) {
                        obj.put(fieldName, value);
                    }
                }

                repository.add(obj);
            }
            return repository;
        }

        List<SObject> updateObjects(EntityNode entityNode) {
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
                    Object value = fieldEvaluator.getValue(dsr, dfr, rule, true, 10);
                    if (value != null) {
                        obj.put(fieldName, value);
                    }
                }
                entityNode.repository.add(obj);
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

    class FieldEvaluator implements IFieldEvaluator {
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
                    'Please adjust field ({0}) generation rule to allow uniqueness more likely to happen',
                    new List<String>{
                        dfr.getName()
                    }));
            }

            if (dfr.isNillable() && !hasRule) {
               return null;
            }

            if (isGeolocationField(dsr, dfr)) {
                return null;
            }

            String key = dsr.getName() + '.' + dfr.getName();
            Object value;
            if (!hasRule) {
                value = guessValue(dsr, dfr);
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

        Object guessValue(Schema.DescribeSObjectResult dsr, Schema.DescribeFieldResult dfr) {
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
                    // System.debug('Double - ' + fieldName + ': ' + value);
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
                Map<String, SObjectField> fieldMap = dsr.fields.getMap();
                for (SObjectField field : fieldMap.values()) {
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
                // System.debug('geolocation of ' + objectName + ': ' + geolocationFieldSet);
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
                Map<String, SObjectField> fieldMap = dsr.fields.getMap();
                for (SObjectField field : fieldMap.values()) {
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

        private Object fake(String input, String fieldName) {
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

    public class ATKSpellBook implements Iterable<EntityNode> {
        private Map<String, List<EntityNode>> entityNodeMap { get; set; }
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

    private class EntityNodeMatrix implements Iterator<EntityNode> {
        private Integer rowIndex { get; set; }
        private Integer colIndex { get; set; }
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

        public String name { get; set; }
        public Integer total { get; set; }
        public Map<String, Object> fieldInitMap { get; set; }
        public Map<String, Object> fieldRuleMap { get; set; }
        public Map<String, EntityNode> referenceToMap { get; set; }
        public List<SObject> repository { get; set; }

        public EntityNode(String name, EntityNodeType type) {
            this.name = name.trim().toUpperCase();
            this.type = type;
            fieldRuleMap = new Map<String, Object>();
            fieldInitMap = new Map<String, Object>();
            referenceToMap = new Map<String, EntityNode>();
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
