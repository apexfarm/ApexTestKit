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
    public static final PermissionSets PERMISSION_SETS = new PermissionSets();
    public static final FakeId FAKEID = new FakeId();

    public static final Generator SAVE_GENERATOR = new SaveGenerator();
    public static final Generator MOCK_GENERATOR = new MockGenerator();
    @TestVisible
    private static final Converter CONVERTER = new Converter();
    @TestVisible
    private static final Distributor DISTRIBUTOR = new Distributor();
    @TestVisible
    private static Integer batchSize = 200;

    // *************************
    // #region SObject Generator
    // *************************

    public abstract class Generator {
        public Map<Schema.SObjectType, Map<Schema.SObjectField, Integer>> indexes { get; set; }

        {
            indexes = new Map<Schema.SObjectType, Map<Schema.SObjectField, Integer>>();
        }

        public abstract void generate(EntityNodeMatrix matrix, Boolean doInsert);
        abstract void createObjects(EntityNode entityNode);
        abstract void assignFields(EntityNode entityNode);
        abstract void assignReferences(EntityNode entityNode);

        public Integer reserveIndex(SObjectType objectType, SObjectField field, Integer size) {
            if(!indexes.containsKey(objectType)) {
                indexes.put(objectType, new Map<Schema.SObjectField, Integer> {
                    field => 0
                });
            } else if (!indexes.get(objectType).containsKey(field)) {
                indexes.get(objectType).put(field, 0);
            }
            Integer index = indexes.get(objectType).get(field);
            indexes.get(objectType).put(field, index + size);
            return index;
        }
    }

    public class MockGenerator extends Generator {
        public override void generate(EntityNodeMatrix matrix, Boolean doInsert) {
            matrix.generateDAG();
            matrix.reset();
            while (matrix.hasNext()) {
                EntityNode entityNode = matrix.next();
                createObjects(entityNode);

                if (entityNode.size > 0) {
                    assignFields(entityNode);
                    assignReferences(entityNode);
                }
            }

            convertMockObjects(matrix);

            matrix.reset();
            while (matrix.hasNext()) {
                EntityNode entityNode = matrix.next();

                if (entityNode.size > 0) {
                    SAVE_GENERATOR.assignFields(entityNode);
                    SAVE_GENERATOR.assignReferences(entityNode);
                }

                // Ids should be assigned after reference assignments, because once Ids are
                // assigned some relationships are no longer updatable.
                List<SObject> objects = entityNode.objects;
                List<Id> ids = FAKEID.generate(entityNode.objectType, objects.size());
                for (Integer i = 0; i < objects.size(); i++) {
                    if (objects.get(i).Id == null) {
                        objects.get(i).Id = ids[i];
                    }
                }
            }
        }

        public void convertMockObjects(EntityNodeMatrix matrix) {
            matrix.reset();
            if (matrix.hasNext()) {
                EntityNode entityNode = matrix.next();
                entityNode.objects = entityNode.mockObjects.convert();
            }

            while (matrix.hasNext()) {
                EntityNode entityNode = matrix.next();
                if (entityNode.belongsToRoot) {
                    for (EntityNodeRelationship relationship : entityNode.relatinoships) {
                        EntityNode parentNode = relationship.parent;
                        for (SObject obj : parentNode.objects) {
                            System.debug(obj);
                            for (SObject childObj : obj.getSObjects(relationship.childRelationship)) {
                                System.debug(childObj);
                                entityNode.objects.add(childObj);
                            }
                        }
                        break; // only need to collect children from a single relationship
                    }
                } else if (entityNode.objects.isEmpty()) {
                    entityNode.objects.addAll(entityNode.mockObjects.convert());
                }
            }
        }

        public override void createObjects(EntityNode entityNode) {
            // if (!entityNode.belongsToRoot && entityNode.readonlyFields.isEmpty()) {
            //     Schema.SObjectType objectType = entityNode.objectType;
            //     for (Integer i = 0; i < entityNode.size; ++i) {
            //         entityNode.objects.add(objectType.newSObject());
            //     }
            // } else
            if (entityNode.mockObjects.isEmpty()) {
                String objectName = entityNode.dsr.getName();
                for (Integer i = 0; i < entityNode.size; ++i) {
                    entityNode.mockObjects.add(new MockSObject(objectName));
                }
            }
        }

        public override void assignFields(EntityNode entityNode) {
            MockSObjectList mockObjects = entityNode.mockObjects;
            Integer size = mockObjects.size();
            for (EntityField entityField : entityNode.readonlyFields) {
                if (entityField.isArithmetic) {
                    switch on entityField.dfr.getType() {
                        when DATE {
                            Date init = Converter.toDate(entityField.initValue);
                            Integer step = Converter.toInteger(entityField.stepVAlue);
                            for (Integer i = 0; i < size; ++i) {
                                mockObjects.get(i).put(entityField.dfr.getName(), CONVERTER.toString(entityField.getValue(init, step, i)));
                            }
                        }
                        when DATETIME {
                            Datetime init = Converter.toDatetime(entityField.initValue);
                            Integer step = Converter.toInteger(entityField.stepVAlue);
                            for (Integer i = 0; i < size; ++i) {
                                mockObjects.get(i).put(entityField.dfr.getName(), CONVERTER.toString(entityField.getValue(init, step, i)));
                            }
                        }
                        when TIME {
                            Time init = Converter.toTime(entityField.initValue);
                            Integer step = Converter.toInteger(entityField.stepVAlue);
                            for (Integer i = 0; i < size; ++i) {
                                mockObjects.get(i).put(entityField.dfr.getName(), String.valueOf(entityField.getValue(init, step, i)));
                            }
                        }
                        when DOUBLE, INTEGER, PERCENT, CURRENCY {
                            Decimal init = Converter.toDecimal(entityField.initValue);
                            Decimal step = Converter.toDecimal(entityField.stepVAlue);
                            for (Integer i = 0; i < size; ++i) {
                                mockObjects.get(i).put(entityField.dfr.getName(), String.valueOf(entityField.getValue(init, step, i)));
                            }
                        }
                    }
                } else {
                    Integer start = reserveIndex(entityNode.objectType, entityField.field, size);
                    for (Integer i = 0; i < size; ++i) {
                        Object value = entityField.getValue(i + start);
                        mockObjects.get(i).put(entityField.dfr.getName(), CONVERTER.toString(value));
                    }
                }
            }
        }

        @TestVisible
        override void assignReferences(EntityNode entityNode) {
            if (!entityNode.belongsToRoot) {
                return;
            }

            if (entityNode.relatinoships != null
                && !entityNode.relatinoships.isEmpty()
                && entityNode.mockObjects != null) {

                MockSObjectList childObjectList = entityNode.mockObjects;

                for (EntityNodeRelationship relationship : entityNode.relatinoships) {
                    // String parentRelationshipId = relationship.parentRelationship.getDescribe().getName();
                    String parentRelationshipName = relationship.parentRelationship.getDescribe().getRelationshipName();
                    MockSObjectList parentObjectList = relationship.parent.mockObjects;

                    // Open comment for debug purpose
                    // System.debug(String.format('{0} -> {1}', new List<Object> { entityNode.objectType, parentRelationshipName }));
                    // System.debug(String.format('{0} -> {1}', new List<Object> { childObjectList.size(), parentObjectList.size() }));

                    for (List<MockSObject> pair : DISTRIBUTOR.distribute(childObjectList, parentObjectList)) {
                        // pair[0] = child
                        // pair[1] = parent
                        // pair[0].put(parentRelationshipId, pair[1].Id);
                        if (relationship.parent.belongsToRoot || !relationship.child.belongsToRoot) {
                            pair[1].putChild(relationship.childRelationship, pair[0]);
                        } else {
                            pair[0].putParent(parentRelationshipName, pair[1]);
                        }
                    }
                }
            }
        }
    }

    public class SaveGenerator extends Generator {
        public override void generate(EntityNodeMatrix matrix, Boolean doInsert) {
            matrix.generateDAG();
            matrix.reset();
            while (matrix.hasNext()) {
                EntityNode entityNode = matrix.next();
                createObjects(entityNode);

                if (entityNode.size > 0) {
                    assignFields(entityNode);
                    assignReferences(entityNode);
                }

                if (!doInsert) {
                    continue;
                }

                List<SObject> updateList = new List<SObject>();
                List<SObject> insertList = new List<SObject>();
                for (SObject obj : entityNode.objects) {
                    if (obj.Id == null) {
                        insertList.add(obj);
                    } else {
                        updateList.add(obj);
                    }
                }
                if (!updateList.isEmpty()) {
                    Database.update(updateList);
                }
                if (!insertList.isEmpty()) {
                    Database.insert(insertList);
                }
            }
        }

        public override void createObjects(EntityNode entityNode) {
            if (entityNode.objects.isEmpty()) {
                Schema.SObjectType objectType = entityNode.objectType;
                for (Integer i = 0; i < entityNode.size; ++i) {
                    entityNode.objects.add(objectType.newSObject());
                }
            }
        }

        public override void assignFields(EntityNode entityNode) {
            List<SObject> objects = entityNode.objects;
            Integer size = objects.size();

            for (EntityField entityField : entityNode.writableFields) {
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
                    Integer index = reserveIndex(entityNode.objectType, entityField.field, size);
                    for (Integer i = 0; i < size; ++i) {
                        Object value = entityField.getValue(i + index);
                        objects[i].put(entityField.field, value);
                    }
                }
            }
        }

        @TestVisible
        override void assignReferences(EntityNode entityNode) {
            if (entityNode.relatinoships != null
                && entityNode.relatinoships.size() > 0
                && entityNode.objects != null) {

                for (EntityNodeRelationship relationship : entityNode.relatinoships) {
                    String relationshipName = relationship.parentRelationship.getDescribe().getRelationshipName();
                    List<SObject> parentObjectList = relationship.parent.objects;
                    List<SObject> childObjectList = relationship.child.objects;

                    // Open comment for debug purpose
                    // System.debug(String.format('{0} -> {1}', new List<Object> { entityNode.objectType, relationshipName }));
                    // System.debug(String.format('{0} -> {1}', new List<Object> { childObjectList.size(), parentObjectList.size() }));

                    for (List<SObject> pair : DISTRIBUTOR.distribute(childObjectList, parentObjectList)) {
                        // pair[0] = child
                        // pair[1] = parent
                        pair[0].put(relationship.parentRelationship, pair[1].Id);
                        pair[0].putSObject(relationshipName, pair[1]);
                    }
                }
            }
        }
    }

    public class Distributor {
        public List<List<MockSObject>> distribute(MockSObjectList leftGroup, MockSObjectList rightGroup) {
            List<List<MockSObject>> groups = new List<List<MockSObject>>();

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
                groups.add(new List<MockSObject>{
                    leftGroup.get(i), rightGroup.get(j)
                });
            }
            return groups;
        }

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

    // *************************************
    // #region [Model] => JSON Representable
    // *************************************

    private class MockSObjectList {
        private List<MockSObject> mockObjects { get; set; }

        MockSObjectList() {
            mockObjects = new List<MockSObject>();
        }

        void add(MockSObject objectMock) {
            mockObjects.add(objectMock);
        }

        void addAll(List<MockSObject> mockObjects) {
            this.mockObjects.addAll(mockObjects);
        }

        MockSObject get(Integer i) {
            return mockObjects[i];
        }

        Boolean isEmpty() {
            return mockObjects.isEmpty();
        }

        Integer size() {
            return mockObjects.size();
        }

        public override String toString() {
            StringBuilder builder = new StringBuilder();
            for (MockSObject objectMock : mockObjects) {
                builder.append(String.valueOf(objectMock));
            }
            return '[' + builder.toString(',') + ']';
        }

        public List<SObject> convert() {
            String jsonStr = String.valueOf(this);
            System.debug(jsonStr);
            return (List<SObject>)JSON.deserialize(jsonStr, List<SObject>.class);
        }
    }

    private class MockSObject {
        private String objectName { get; set; }
        private Map<String, Object> fieldMap { get; set; }

        Id id {
            get {
                return id;
            }
            set {
                fieldMap.put('id', '"' + value + '"');
                id = value;
            }
        }

        MockSObject(String objectName) {
            this.objectName = objectName;
            this.fieldMap = new Map<String, Object>();
        }

        void put(String name, Object value) {
            fieldMap.put(name, '"' + value + '"');
        }

        void putParent(String name, MockSObject value) {
            fieldMap.put(name, value);
        }

        void putChild(String name, MockSObject value) {
            if (!fieldMap.containsKey(name)) {
                fieldMap.put(name, new MockSObjectChildren());
            }
            MockSObjectChildren children = (MockSObjectChildren)fieldMap.get(name);
            ((MockSObjectChildren)children).add(value);
        }

        public override String toString() {
            StringBuilder builder = new StringBuilder();
            builder.append('{"attributes":{"type":"' + this.objectName + '"}');
            for(String fieldName: fieldMap.keySet()) {
                builder.append(',"' + fieldName + '":' + String.valueOf(fieldMap.get(fieldName)));
            }
            builder.append('}');
            return builder.toString();
        }
    }

    private class MockSObjectChildren {
        private List<MockSObject> mockObjects { get; set; }

        MockSObjectChildren() {
            this.mockObjects = new List<MockSObject>();
        }

        void add(MockSObject objectMock) {
            mockObjects.add(objectMock);
        }

        public override String toString() {
            StringBuilder builder = new StringBuilder();
            for (MockSObject objectMock : mockObjects) {
                builder.append(String.valueOf(objectMock));
            }
            return '{"totalSize":' + mockObjects.size() + ',"records":[' + builder.toString(',') + ']}';
        }
    }

    // #endregion
    // *************************************

    // ************************************
    // #region [Model] => Entity and Fields
    // ************************************

    public class EntityNodeMatrix implements Iterator<EntityNode> {
        public EntityNode currEntityNode { get; private set; }
        public List<EntityNodeRelationship> entityNodeRelationships { get; private set; }
        public List<EntityNode> entityNodeCache { get; private set; }
        private List<EntityNode> entityNodeStack { get; set; }

        private SymbolDigraph graph { get; set; }
        private Topological top { get; set; }
        private Integer currentIndex { get; set; }

        public EntityNodeMatrix() {
            entityNodeStack = new List<EntityNode>();
            entityNodeCache = new List<EntityNode>();
            entityNodeRelationships = new List<EntityNodeRelationship>();
        }

        public void generateDAG() {
            this.graph = new SymbolDigraph(this.entityNodeCache);
            for (EntityNodeRelationship relation : this.entityNodeRelationships) {
                this.graph.addEdge(relation.parent, relation.child);
            }

            this.top = new Topological(graph.G());

            if (this.top.isDAG() && this.top.order().size() > 0) {
                List<Integer> queue = new List<Integer>();
                Integer rootVertex = this.top.order()[0];
                queue.add(rootVertex);
                while(!queue.isEmpty()) {
                    Integer vertex = queue.remove(0);
                    EntityNode entityNode = (EntityNode)this.graph.keyAt(vertex);
                    entityNode.belongsToRoot = true;
                    for (Integer childVertex : this.graph.G().adj(vertex)) {
                        queue.add(childVertex);
                    }
                }
            }
        }

        public void reset() {
            if (this.top.isDAG()) {
                currentIndex = -1;
            } else {
                // throw Exception
            }
        }

        public Boolean hasNext() {
            return currentIndex < this.top.order().size() - 1;
        }

        public EntityNode next() {
            if (this.hasNext()) {
                currentIndex++;
                return (EntityNode)this.graph.keyAt(this.top.order()[currentIndex]);
            } else {
                return null;
            }
        }

        public void add(EntityNodeType nodeType, EntityNode nextEntityNode, Schema.SObjectField parentRelationship) {
            addEntityNode(nodeType, nextEntityNode, parentRelationship);
            entityNodeCache.add(nextEntityNode);
        }

        public void add(EntityNodeType nodeType, Schema.SObjectType objectType, Schema.SObjectField parentRelationship) {
            EntityNode nextEntityNode;
            for (EntityNode entityNode : this.entityNodeCache) {
                if (entityNode.objectType == objectType) {
                    nextEntityNode = entityNode;
                    break;
                }
            }
            if (nextEntityNode != null) {
                addEntityNode(nodeType, nextEntityNode, parentRelationship);
            }
        }

        private void addEntityNode(EntityNodeType nodeType, EntityNode nextEntityNode, Schema.SObjectField parentRelationship) {
            // currEntityNode: child
            // nextEntityNode: parent
            switch on nodeType {
                when MANY_TO_ONE {
                    EntityNodeRelationship relationship = new EntityNodeRelationship(nextEntityNode, this.currEntityNode, parentRelationship);
                    entityNodeRelationships.add(relationship);
                    currEntityNode.relatinoships.add(relationship);
                }
                when ONE_TO_MANY {
                    EntityNodeRelationship relationship = new EntityNodeRelationship(this.currEntityNode, nextEntityNode, parentRelationship);
                    entityNodeRelationships.add(relationship);
                    nextEntityNode.relatinoships.add(relationship);
                }
            }

            entityNodeStack.add(nextEntityNode);
            this.currEntityNode = nextEntityNode;
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
        }
    }

    public enum EntityNodeType {
        PREPARE,
        MANY_TO_ONE,
        ONE_TO_MANY
    }

    class EntityNodeRelationship {
        EntityNode parent { get; set; }
        EntityNode child { get; set; }
        Schema.SObjectField parentRelationship { get; set; }
        String childRelationship { get; set; }

        EntityNodeRelationship(EntityNode parent, EntityNode child, Schema.SObjectField parentRelationship) {
            this.parent = parent;
            this.child = child;
            this.parentRelationship = parentRelationship;

            for (Schema.ChildRelationship cr: parent.dsr.getChildRelationships()) {
                if (cr.getChildSObject() == child.objectType && cr.getField() == parentRelationship) {
                    this.childRelationship = cr.getRelationshipName();
                    break;
                }
            }
        }
    }

    public class EntityNode {
        public Schema.SObjectType objectType { get; set; }
        public Schema.DescribeSObjectResult dsr { get; set; }
        public Integer size { get; set; }

        public List<EntityNodeRelationship> relatinoships { get; set; }
        public List<SObject> objects { get; set; }
        public MockSObjectList mockObjects { get; set; }

        public EntityField currEntityField { get; set; }
        @TestVisible
        private Map<Schema.SObjectField, EntityField> fieldMap { get; set; }
        private List<EntityField> writableFields { get; set; }
        private List<EntityField> readonlyFields { get; set; }
        private Boolean belongsToRoot { get; set; }

        public EntityNode(Schema.SObjectType objectType) {
            this.objectType = objectType;
            this.dsr = objectType.getDescribe();

            this.relatinoships = new List<EntityNodeRelationship>();
            this.fieldMap = new Map<Schema.SObjectField, EntityField>();
            this.writableFields = new List<EntityField>();
            this.readonlyFields = new List<EntityField>();
            this.belongsToRoot = false;
        }

        public EntityNode(Schema.SObjectType objectType, Integer size) {
            this(objectType);
            this.size = size;
            this.objects = new List<SObject>();
            this.mockObjects = new MockSObjectList();
        }

        public EntityNode(Schema.SObjectType objectType, List<SObject> objects) {
            this(objectType);
            this.size = objects.size();
            this.objects = objects;
            this.mockObjects = new MockSObjectList();
        }

        public void addField(SObjectField field) {
            EntityField entityField;
            if (this.fieldMap.containsKey(field)) {
                entityField = this.fieldMap.get(field);
            } else {
                entityField = new EntityField(field);
                this.fieldMap.put(field, entityField);
                if (!entityField.dfr.isCreateable()) {
                    this.readonlyFields.add(entityField);
                } else {
                    this.writableFields.add(entityField);
                }
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
    // *************************************

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
            } else if (input instanceof Date) {
                return ((Datetime)input).format('yyyy-MM-dd');
            } else if (input instanceof Datetime) {
                return ((Datetime)input).formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
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

    public class PermissionSets {
        @TestVisible
        Map<String, Id> permissionSetIdByName {
            get {
                if (permissionSetIdByName == null) {
                    permissionSetIdByName = new Map<String, Id>();
                    for (PermissionSet permissionSet : [
                        SELECT Id, Label, Name
                        FROM PermissionSet
                        WHERE ProfileId = null]) {
                        permissionSetIdByName.put(permissionSet.Name.toUpperCase(), permissionSet.Id);
                        permissionSetIdByName.put(permissionSet.Label.toUpperCase(), permissionSet.Id);
                    }
                }
                return permissionSetIdByName;
            }
            set;
        }

        public Id getId(String name) {
            return permissionSetIdByName.get(name.toUpperCase());
        }

        public List<Id> getIds(List<String> names) {
            List<Id> ids = new List<Id>();
            for (String name : names) {
                Id id = this.getId(name);
                if (id != null) {
                    ids.add(id);
                }
            }
            return ids;
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
        public Id getId(DescribeSObjectResult dsr, String developerName) {
            RecordTypeInfo recordTypeInfo = dsr.getRecordTypeInfosByDeveloperName().get(developerName);
            if (recordTypeInfo != null) {
                return recordTypeInfo.getRecordTypeId();
            }
            return null;
        }
    }

    class Indexer {
        Integer i = 0;
    }

    public class FakeId {
        Map<Schema.SObjectType, Indexer> objectIdIndexes { get; set; }

        {
            objectIdIndexes = new Map<Schema.SObjectType, Indexer>();
        }

        public String get(Schema.SObjectType objectType, Integer i) {
            return objectType.getDescribe().getKeyPrefix()
                + '000zzzz'
                + String.valueOf(i).leftPad(5, '0');
        }

        public List<Id> generate(Schema.SObjectType objectType, Integer size) {
            List<Id> ids = new List<Id>();
            if (!objectIdIndexes.containsKey(objectType)) {
                objectIdIndexes.put(objectType, new Indexer());
            }

            Indexer idx = objectIdIndexes.get(objectType);
            String prefix = objectType.getDescribe().getKeyPrefix() + '000zzzz';
            for (Integer i = 0; i < size; i++) {
                ids.add(prefix + String.valueOf(++idx.i).leftPad(5, '0'));
            }
            return ids;
        }
    }

    // #endregion
    // ***********************

    // ************************
    // #region Graph Definition
    // ************************
    public class Digraph {
        public final Integer V { get; private set; }
        public Integer E { get; private set; }
        private List<List<Integer>> adj { get; set; }

        public Digraph(Integer V) {
            this.V = V;
            this.E = 0;
            this.adj = new List<List<Integer>>();
            for (Integer i = 0; i < V; i ++) {
                this.adj.add(new List<Integer>());
            }
        }

        public void addEdge(Integer v, Integer w) {
            adj[v].add(w);
            E++;
        }

        public List<Integer> adj(Integer v) {
            return adj[v];
        }
    }

    public class DirectedCycle {
        List<Boolean> marked { get; set; }
        List<Integer> edgeTo { get; set; }
        List<Boolean> onStack { get; set; }
        List<Integer> cycle { get; set; }

        public DirectedCycle(Digraph G) {
            this.onStack = new List<Boolean>();
            this.edgeTo = new List<Integer>();
            this.marked = new List<Boolean>();

            for (Integer v = 0; v < G.V; v++) {
                this.onStack.add(false);
                this.edgeTo.add(null);
                this.marked.add(false);
            }

            for (Integer v = 0; v < G.V; v++) {
                if (!this.marked[v]) {
                    dfs(G, v);
                }
            }
        }

        private void dfs(Digraph G, Integer v) {
            this.onStack[v] = true;
            this.marked[v] = true;
            for (Integer w : G.adj(v)) {
                if (this.hasCycle()) {
                    return;
                } else if (!this.marked[w]) {
                    this.edgeTo[w] = v;
                    dfs(G, w);
                } else if (this.onStack[w]) {
                    cycle = new List<Integer>();
                    for (Integer x = v; x != w; x = this.edgeTo[x]) {
                        cycle.add(x);
                    }
                    cycle.add(w);
                    cycle.add(v);
                }
            }
            this.onStack[v] = false;
        }

        public Boolean hasCycle() {
            return cycle != null;
        }

        // public List<Integer> cycle() {
        //     return cycle;
        // }
    }

    public class DepthFirstOrder {
        private List<Boolean> marked;
        private List<Integer> pre; // Queue
        private List<Integer> post; // Queue

        public DepthFirstOrder(Digraph G) {
            pre = new List<Integer>();
            post = new List<Integer>();
            marked = new List<Boolean>();

            for (Integer v = 0; v < G.V; v++) {
                marked.add(false);
            }

            for (Integer v = 0; v < G.V; v++) {
                if (!marked[v]) {
                    dfs(G, v);
                }
            }
        }

        private void dfs(Digraph G, Integer v) {
            pre.add(v);
            marked[v] = true;
            for (Integer w : G.adj(v)) {
                if (!marked[w]) {
                    dfs(G, w);
                }
            }

            post.add(v);
        }

        // public List<Integer> pre() {
        //     return pre;
        // }

        // public List<Integer> post() {
        //     return post;
        // }

        public List<Integer> reversePost(){
            List<Integer> reversePost = new List<Integer>();
            for (Integer i = post.size(); i > 0; i--) {
                reversePost.add(post[i - 1]);
            }
            return reversePost;
        }
    }

    public class Topological {
        private List<Integer> order;
        public Topological(Digraph G) {
            DirectedCycle cyclefinder = new DirectedCycle(G);
            if (!cyclefinder.hasCycle()) {
                DepthFirstOrder dfs = new DepthFirstOrder(G);
                order = dfs.reversePost();
            }
        }

        public List<Integer> order(){
            return order;
        }

        public Boolean isDAG() {
            return order != null;
        }
    }

    public class SymbolDigraph {
        private Map<Object, Integer> indexMap;
        private List<Object> keys;
        private Digraph G;

        public SymbolDigraph(List<Object> objects) {
            indexMap = new Map<Object, Integer>();
            keys = new List<Object>();

            for (Object obj : objects) {
                if (!this.indexMap.containsKey(obj)) {
                    this.indexMap.put(obj, indexMap.size());
                    this.keys.add(obj);
                }
            }
            G = new Digraph(objects.size());
        }

        public void addEdge(Object a, Object b) {
            G.addEdge(indexMap.get(a), indexMap.get(b));
        }

        // public Boolean contains(Object s) {
        //     return indexMap.containsKey(s);
        // }

        // public Integer index(Object s) {
        //     return indexMap.get(s);
        // }

        public Object keyAt(Integer i) {
            return keys[i];
        }

        public Digraph G() {
            return G;
        }
    }

    // #endregion
    // ************************
}
