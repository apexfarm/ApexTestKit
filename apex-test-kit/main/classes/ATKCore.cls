/**
 * Copyright 2018 Jeff Jin
 * https://github.com/apexfarm/ApexTestKit
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

public with sharing class ATKCore {
    public static final Profiles PROFILES = new Profiles();
    public static final RecordTypes RECORD_TYPES = new RecordTypes();
    public static final Converter CONVERTER = new Converter();
    public static final Generator GENERATOR = new Generator();
    private static final Distributor DISTRIBUTOR = new Distributor();

    // ************************
    // #region Graph Definition
    // ************************
    public class EntityNodeMatrix implements Iterator<EntityNode> {
        public Integer rowIndex { get; set; }
        public Integer colIndex { get; set; }
        List<List<EntityNode>> entityNodeMatrix { get; set; }
        public List<EntityNode> entityNodeCache { get; set; }
        List<EntityNode> entityNodeStack { get; set; }
        public EntityNode currEntityNode { get; set; }

        public EntityNodeMatrix() {
            entityNodeMatrix = new List<List<EntityNode>>();
            entityNodeStack = new List<EntityNode>();
            entityNodeCache = new List<EntityNode>();
            this.reset();
        }

        public void reset() {
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

        public void pop(Integer depth) {
            while (depth > 0) {
                depth--;
                Integer size = this.entityNodeStack.size();
                if (size > 1) {
                    this.entityNodeStack.remove(size - 1);
                    this.currEntityNode = this.entityNodeStack[size - 2];
                }
            }
            this.reset();
            while (this.hasNext()) {
                EntityNode entityNode = this.next();
                if (entityNode == this.currEntityNode) {
                    break;
                }
            }
        }

        public void add(EntityNodeType nodeType, Schema.SObjectType objectType, Schema.SObjectField referenceField) {
            Integer currRowIndex = rowIndex;
            Integer currColIndex = colIndex;
            EntityNode nextEntityNode;
            this.reset();
            while (this.hasNext()) {
                nextEntityNode = this.next();
                if (nextEntityNode.objectType == objectType) {
                    break;
                }
            }

            if (nextEntityNode != null) {
                switch on nodeType {
                    when MANY_TO_ONE {
                        moveParentAboveChild(
                            nextEntityNode, rowIndex, colIndex,
                            currEntityNode, currRowIndex, currColIndex);
                        rowIndex = rowIndex;
                        colIndex = 0;
                    }
                    when ONE_TO_MANY {
                        moveParentAboveChild(
                            currEntityNode, currRowIndex, currColIndex,
                            nextEntityNode, rowIndex, colIndex);
                        rowIndex = rowIndex + 1;
                        colIndex = colIndex;
                    }
                }

                attach(nodeType, nextEntityNode, referenceField);
            }
        }

        public void moveParentAboveChild(
            EntityNode parentNode, Integer parentRow, Integer parentCol,
            EntityNode childNode, Integer childRow, Integer childCol) {

            // Open comment for debug purpose
            // System.debug(String.format('{0}({1}, {2})', new List<Object>{ parentNode.objectType, parentRow, parentCol }));
            // System.debug(String.format('{0}({1}, {2})', new List<Object>{ childNode.objectType, childRow, childCol }));

            if (childRow == parentRow && childCol < parentCol) {
                entityNodeMatrix.get(parentRow).remove(parentCol);
                entityNodeMatrix.add(parentRow, new List<EntityNode> { parentNode });
            }
        }

        public void add(EntityNodeType nodeType, EntityNode nextEntityNode, Schema.SObjectField referenceField) {
            switch on nodeType {
                when PREPARE {
                    rowIndex = 0;
                    colIndex = 0;
                    entityNodeMatrix.add(new List<EntityNode>());
                    entityNodeMatrix.get(rowIndex).add(nextEntityNode);
                }
                when MANY_TO_ONE {
                    if (rowIndex > 0) {
                        rowIndex -= 1;
                        entityNodeMatrix.get(rowIndex).add(nextEntityNode);
                        colIndex = entityNodeMatrix.get(rowIndex).size() - 1;
                    } else {
                        rowIndex = 0;
                        colIndex = 0;
                        entityNodeMatrix.add(rowIndex, new List<EntityNode>());
                        entityNodeMatrix.get(rowIndex).add(nextEntityNode);
                    }
                }
                when ONE_TO_MANY {
                    rowIndex += 1;
                    if (rowIndex == entityNodeMatrix.size()) {
                        colIndex = 0;
                        entityNodeMatrix.add(new List<EntityNode>());
                        entityNodeMatrix.get(rowIndex).add(nextEntityNode);
                    } else {
                        colIndex = entityNodeMatrix.get(rowIndex).size();
                        entityNodeMatrix.get(rowIndex).add(nextEntityNode);
                    }
                }
            }

            attach(nodeType, nextEntityNode, referenceField);
        }

        void attach(EntityNodeType nodeType, EntityNode nextEntityNode, Schema.SObjectField referenceField) {
            entityNodeStack.add(nextEntityNode);
            entityNodeCache.add(nextEntityNode);

            switch on nodeType {
                when MANY_TO_ONE {
                    currEntityNode.referenceToMap.put(referenceField, nextEntityNode);
                    currEntityNode.referenceFields.add(referenceField);
                }
                when ONE_TO_MANY {
                    nextEntityNode.referenceToMap.put(referenceField, currEntityNode);
                    nextEntityNode.referenceFields.add(referenceField);
                }
            }
            this.currEntityNode = nextEntityNode;
        }
    }

    public enum EntityNodeType {
        PREPARE,
        MANY_TO_ONE,
        ONE_TO_MANY
    }

    public class EntityNode {
        public Schema.SObjectType objectType { get; set; }
        public Schema.DescribeSObjectResult dsr { get; set; }
        public Integer size { get; set; }
        public Map<Schema.SObjectField, EntityNode> referenceToMap { get; set; }
        public List<Schema.SObjectField> referenceFields { get; set; }
        public List<SObject> objects { get; set; }


        public Map<Schema.SObjectField, EntityField> fieldMap { get; set; }
        public List<EntityField> fieldCache { get; set; }
        public EntityField currEntityField { get; set; }

        public EntityNode(Schema.SObjectType objectType) {
            this.objectType = objectType;
            this.dsr = objectType.getDescribe();

            this.referenceToMap = new Map<Schema.SObjectField, EntityNode>();
            this.referenceFields = new List<Schema.SObjectField>();
            this.fieldMap = new Map<Schema.SObjectField, EntityField>();
            this.fieldCache = new List<EntityField>();
        }

        public EntityNode(Schema.SObjectType objectType, Integer size) {
            this(objectType);
            this.size = size;
            this.objects = new List<SObject>();
        }

        public EntityNode(Schema.SObjectType objectType, List<SObject> objects) {
            this(objectType);
            this.size = objects.size();
            this.objects = objects;
        }

        public void addField(SObjectField field) {
            EntityField entityField;
            if (this.fieldMap.containsKey(field)) {
                entityField = this.fieldMap.get(field);
            } else {
                entityField = new EntityField(field);
                this.fieldMap.put(field, entityField);
                this.fieldCache.add(entityField);
            }
            this.currEntityField = entityField;
        }
    }

    public enum EntityFieldArithmetic {
        ADD,
        SUBSTRACT,
        DIVIDE,
        MULTIPLY,

        ADD_YEARS,
        ADD_MONTHS,
        ADD_DAYS,
        ADD_HOURS,
        ADD_MINUTES,
        ADD_SECONDS
    }

    static Pattern methodPattern = Pattern.compile('\\{(0+)\\}');

    public class EntityField  {
        public Schema.SObjectField field { get; set; }
        public Schema.DescribeFieldResult dfr { get; set; }

        // Fixed Value
        public Object fixedValue { get; set; }
        public Integer indexLength { get; set; }
        public Boolean uniqueIndex { get; set; }
        public String indexFormat { get;
            set {
                indexFormat = value;
                this.indexLength = 0;
                System.Matcher matcher = methodPattern.matcher(value);
                while(matcher.find()) {
                    this.indexLength = matcher.group(1).length();
                }
            }
        }
        public List<Object> repeatValues { get; set; }

        // Arithmetic
        public EntityFieldArithmetic arithmetic { get; set; }
        public Object initValue { get; set; }
        public Object stepValue { get; set; }

        public EntityField(Schema.SObjectField field) {
            this.field = field;
            this.dfr = this.field.getDescribe();
            this.uniqueIndex = true;
        }

        Boolean isIndexed {
            get {
                return indexFormat != null;
            }
        }

        Boolean isRepeated {
            get {
                return repeatValues != null && repeatValues.size() > 0;
            }
        }

        @TestVisible
        Boolean isArithmetic {
            get {
                return arithmetic != null;
            }
        }

        public Object getValue(Integer rowIndex) {
            if (isIndexed) {
                return String.format(this.indexFormat, new List<Object> {
                    String.valueOf(rowIndex + 1).leftPad(indexLength, '0')
                });
            } else if (isRepeated) {
                return this.repeatValues[Math.mod(rowIndex, this.repeatValues.size())];
            } else {
                return this.fixedValue;
            }
        }

        public Object getValue(Datetime init, Integer step, Integer rowIndex) {
            switch on this.arithmetic {
                when ADD_YEARS {
                    return init.addYears(step * rowIndex);
                }
                when ADD_MONTHS {
                    return init.addMonths(step * rowIndex);
                }
                when ADD_DAYS {
                    return init.addDays(step * rowIndex);
                }
                when ADD_HOURS{
                    return init.addHours(step * rowIndex);
                }
                when ADD_MINUTES{
                    return init.addMinutes(step * rowIndex);
                }
                when ADD_SECONDS {
                    return init.addSeconds(step * rowIndex);
                }
                when else {
                    return init;
                }
            }
        }

        public Object getValue(Date init, Integer step, Integer rowIndex) {
            switch on this.arithmetic {
                when ADD_YEARS {
                    return init.addYears(step * rowIndex);
                }
                when ADD_MONTHS {
                    return init.addMonths(step * rowIndex);
                }
                when ADD_DAYS {
                    return init.addDays(step * rowIndex);
                }
                when else {
                    return init;
                }
            }
        }

        public Object getValue(Time init, Integer step, Integer rowIndex) {
            switch on this.arithmetic {
                when ADD_HOURS{
                    return init.addHours(step * rowIndex);
                }
                when ADD_MINUTES{
                    return init.addMinutes(step * rowIndex);
                }
                when ADD_SECONDS {
                    return init.addSeconds(step * rowIndex);
                }
                when else {
                    return init;
                }
            }
        }

        public Object getValue(Decimal init, Decimal step, Integer rowIndex) {
            switch on this.arithmetic {
                when ADD {
                    return init + step * rowIndex;
                }
                when SUBSTRACT {
                    return init - step * rowIndex;
                }
                when DIVIDE {
                    return init / step.pow(rowIndex);
                }
                when MULTIPLY {
                    return init * step.pow(rowIndex);
                }
                when else {
                    return init;
                }
            }
        }
    }

    // #endregion
    // ************************

    // ************************
    // #region SObject Creation
    // ************************

    public class Generator {
        public Map<Schema.SObjectType, Map<Schema.SObjectField, Integer>> indexes { get; set; }

        {
            indexes = new Map<Schema.SObjectType, Map<Schema.SObjectField, Integer>>();
        }

        public void generate(EntityNodeMatrix iterator, Boolean doInsert) {
            iterator.reset();
            while (iterator.hasNext()) {
                EntityNode entityNode = iterator.next();
                Boolean needUpsert = true;
                if (entityNode.objects.size() == 0) {
                    needUpsert = false;
                    Schema.SObjectType objectType = entityNode.objectType;
                    for (Integer i = 0; i < entityNode.size; ++i) {
                        SObject obj = objectType.newSObject();
                        entityNode.objects.add(obj);
                    }
                }

                if (entityNode.size > 0) {
                    assignFields(entityNode);
                    assignReference(entityNode, doInsert);
                }

                if (!doInsert) {
                    continue;
                }

                if (needUpsert) {
                    // upsert doesn't work on list of generic sObject types
                    List<SObject> updateList = new List<SObject>();
                    List<SObject> insertList = new List<SObject>();
                    for (SObject obj : entityNode.objects) {
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
                } else {
                    Database.insert(entityNode.objects);
                }
            }
        }

        public void assignFields(EntityNode entityNode) {
            List<SObject> objects = entityNode.objects;
            Integer size = objects.size();

            for (EntityField entityField : entityNode.fieldCache) {
                if (entityField.isArithmetic) {
                    switch on entityField.dfr.getType() {
                        when DATE {
                            Date init = Converter.toDate(entityField.initValue);
                            Integer step = Converter.toInteger(entityField.stepVAlue);
                            for (Integer i = 0; i < size; ++i) {
                                objects[i].put(entityField.field, entityField.getValue(init, step, i));
                            }
                        }
                        when DATETIME {
                            Datetime init = Converter.toDatetime(entityField.initValue);
                            Integer step = Converter.toInteger(entityField.stepVAlue);
                            for (Integer i = 0; i < size; ++i) {
                                objects[i].put(entityField.field, entityField.getValue(init, step, i));
                            }
                        }
                        when TIME {
                            Time init = Converter.toTime(entityField.initValue);
                            Integer step = Converter.toInteger(entityField.stepVAlue);
                            for (Integer i = 0; i < size; ++i) {
                                objects[i].put(entityField.field, entityField.getValue(init, step, i));
                            }
                        }
                        when DOUBLE, INTEGER, PERCENT, CURRENCY {
                            Decimal init = Converter.toDecimal(entityField.initValue);
                            Decimal step = Converter.toDecimal(entityField.stepVAlue);
                            for (Integer i = 0; i < size; ++i) {
                                objects[i].put(entityField.field, entityField.getValue(init, step, i));
                            }
                        }
                    }
                } else {
                    Integer index = 0;
                    if (entityField.uniqueIndex) {
                        if(!indexes.containsKey(entityNode.objectType)) {
                            indexes.put(entityNode.objectType, new Map<Schema.SObjectField, Integer> {
                                entityField.field => 0
                            });
                        } else if (!indexes.get(entityNode.objectType).containsKey(entityField.field)) {
                            indexes.get(entityNode.objectType).put(entityField.field, 0);
                        }
                        index = indexes.get(entityNode.objectType).get(entityField.field);
                        indexes.get(entityNode.objectType).put(entityField.field, index + size);
                    }

                    for (Integer i = 0; i < size; ++i) {
                        Object value = entityField.getValue(i + index);
                        objects[i].put(entityField.field, value);
                    }
                }
            }
        }

        @TestVisible
        void assignReference(EntityNode entityNode, Boolean doInsert) {
            if (entityNode.referenceToMap != null
                && entityNode.referenceToMap.size() > 0
                && entityNode.objects != null) {

                List<SObject> childObjectList = entityNode.objects;

                for (Schema.SObjectField referenceField : entityNode.referenceFields) {
                    String relationshipName = referenceField.getDescribe().getRelationshipName();
                    List<SObject> parentObjectList = entityNode.referenceToMap.get(referenceField).objects;

                    // Open comment for debug purpose
                    // System.debug(String.format('{0} -> {1}', new List<Object> { entityNode.objectType, relationshipName }));
                    // System.debug(String.format('{0} -> {1}', new List<Object> { childObjectList.size(), parentObjectList.size() }));

                    for (List<SObject> pair : DISTRIBUTOR.distribute(childObjectList, parentObjectList)) {
                        // pair[0] = child
                        // pair[1] = parent
                        pair[0].put(referenceField, pair[1].Id);
                        pair[0].putSObject(relationshipName, pair[1]);
                    }
                }
            }
        }
    }

    public class Distributor {

        public List<List<SObject>> distribute(List<SObject> leftGroup, List<SObject> rightGroup) {
            List<List<SObject>> groups = new List<List<SObject>>();

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
            for (Integer i = 0, j = 0; i < l; ++i) {
                if (j < remainder) {
                    j = i / (s + 1);
                } else {
                    j = (i - remainder) / s;
                }
                groups.add(new List<SObject>{
                    leftGroup[i], rightGroup[j]
                });
            }
            return groups;
        }
    }

    // #endregion
    // ************************

    // ***********************
    // #region Utility Classes
    // ***********************

    public class StringBuilder {
        List<String> values { get; set; }

        public StringBuilder() {
            values = new List<String>();
        }

        public void addIndex(Integer index, String value) {
            values.add(index, value);
        }

        public void setIndex(Integer index, String value) {
            values.set(index, value);
        }

        public String getIndex(Integer index) {
            return values.get(index);
        }

        public void append(Decimal value) {
            values.add(CONVERTER.toString(value));
        }

        public void append(String value) {
            values.add(value);
        }

        public void append(List<String> values) {
            this.values.addAll(values);
        }

        public void append(StringBuilder builder) {
            values.addAll(builder.values);
        }

        public override String toString() {
            return String.join(values, '');
        }

        public String toString(String separator) {
            return String.join(values, separator);
        }
    }

    public class Converter {
        @TestVisible
        private Converter() {
        }

        public Boolean toBoolean(Object input) {
            if (input == null) {
                return null;
            } else if (input instanceof Boolean) {
                return (Boolean)input;
            } else {
                try {
                    return Boolean.valueOf(input);
                } catch (Exception e) {
                    return null;
                }
            }
        }

        public Integer toInteger(Object input) {
            if (input == null) {
                return null;
            } else if (input instanceof Integer) {
                return (Integer)input;
            } else {
                try {
                    return Integer.valueOf(input);
                } catch (Exception e) {
                    return null;
                }
            }
        }

        public Long toLong(Object input) {
            if (input == null) {
                return null;
            } else if (input instanceof Long) {
                return (Long)input;
            } else {
                try {
                    return Long.valueOf(toString(input));
                } catch (Exception e) {
                    return null;
                }
            }
        }

        public Double toDouble(Object input) {
            if (input == null) {
                return null;
            } else if (input instanceof Double) {
                return (Double)input;
            } else {
                try {
                    return Double.valueOf(input);
                } catch (Exception e) {
                    return null;
                }
            }
        }

        public Decimal toDecimal(Object input) {
            if (input == null) {
                return null;
            } else if (input instanceof Decimal) {
                return (Decimal)input;
            } else {
                try {
                    String inputString;
                    if (input instanceOf String) {
                        inputString = (String)input;
                    } else {
                        inputString = String.valueOf(input);
                    }
                    return Decimal.valueOf(inputString);
                } catch (Exception e) {
                    return null;
                }
            }
        }

        public String toString(Object input) {
            if (input == null) {
                return null;
            } else if (input instanceof String) {
                return (String)input;
            } else {
                return String.valueOf(input);
            }
        }

        public Date toDate(Object input) {
            if (input instanceof Date) {
                return (Date)input;
            } else if (input instanceof Datetime){
                return ((Datetime)input).date();
            } else if (input instanceof String) {
                try {
                    return (Date)JSON.deserialize(
                        String.format('"{0}"', new List<String> { (String)input }),
                        Date.class);
                } catch (Exception e) {
                    return null;
                }
            }
            return null;
        }

        public Datetime toDatetime(Object input) {
            if (input instanceof Datetime) {
                return (Datetime)input;
            } else if (input instanceof String) {
                try {
                    return (Datetime)JSON.deserialize(
                        String.format('"{0}"', new List<String> { (String)input }),
                        Datetime.class);
                } catch (Exception e) {
                    return null;
                }
            }
            return null;
        }

        public Time toTime(Object input) {
            if (input == null) {
                return null;
            } else if (input instanceof Time) {
                return (Time)input;
            } else if (input instanceof Datetime){
                return ((Datetime)input).time();
            }
            return null;
        }
    }

    public class Profiles {
        @TestVisible
        Map<String, Id> profileIdByName {
            get {
                if (profileIdByName == null) {
                    profileIdByName = new Map<String, Id>();
                    for (Profile profile : [SELECT Id, Name FROM Profile]) {
                        profileIdByName.put(profile.Name.toUpperCase(), profile.Id);
                    }
                }
                return profileIdByName;
            }
            set;
        }

        public Id getId(String name) {
            return profileIdByName.get(name.toUpperCase());
        }
    }

    public class RecordTypes {
        @TestVisible
        Map<String, Map<String, Id>> recordTypeIdByName {
            get {
                if (recordTypeIdByName == null) {
                    recordTypeIdByName = new Map<String, Map<String, Id>>();
                    for (RecordType recordType : [SELECT
                            Id,
                            DeveloperName,
                            NamespacePrefix,
                            Name,
                            SObjectType
                        FROM RecordType]) {
                        if (!recordTypeIdByName.containsKey(recordType.SObjectType)) {
                            recordTypeIdByName.put(recordType.SObjectType.toUpperCase(), new Map<String, Id> {
                                recordType.DeveloperName.toUpperCase() => recordType.Id,
                                recordType.Name.toUpperCase() => recordType.Id
                            });
                        } else {
                            recordTypeIdByName.get(recordType.SObjectType.toUpperCase())
                                .put(recordType.DeveloperName.toUpperCase(), recordType.Id);
                            recordTypeIdByName.get(recordType.SObjectType.toUpperCase())
                                .put(recordType.Name.toUpperCase(), recordType.Id);
                        }
                    }
                }
                return recordTypeIdByName;
            }
            set;
        }

        public Id getId(SObjectType objectType, String name) {
            Map<String, Id> recordTypeIds = recordTypeIdByName.get(String.valueOf(objectType).toUpperCase());
            if (recordTypeIds != null) {
                return recordTypeIds.get(name.toUpperCase());
            } else {
                return null;
            }
        }
    }

    // #endregion
    // ***********************
}
