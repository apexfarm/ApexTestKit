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
    public static final FakeId FAKEID = new FakeId();

    @TestVisible
    private static final Generator SAVE_GENERATOR = new SaveGenerator();
    @TestVisible
    private static final Generator MOCK_GENERATOR = new MockGenerator();
    @TestVisible
    private static final Converter CONVERTER = new Converter();
    @TestVisible
    private static final Distributor DISTRIBUTOR = new Distributor();

    @TestVisible
    private static final Profiles PROFILES = new Profiles();
    @TestVisible
    private static final RecordTypes RECORD_TYPES = new RecordTypes();
    @TestVisible
    private static final PermissionSets PERMISSION_SETS = new PermissionSets();

    public class NoneDAGException extends Exception {
        String msg = 'In each ATK statement, The object relationships must be '
        + 'a Directed Acyclic Graph, thus no cyclic relationships. '
        + 'https://github.com/apexfarm/ApexTestKit/tree/develop#relationship';

        {
            this.setMessage(msg);
        }
    }

    // ***********************
    // #region SObject Command

    public class SaveResult implements ATK.SaveResult {
        Map<SObjectType, List<List<SObject>>> result = new Map<SObjectType, List<List<SObject>>>();
        EntityNodeMatrix matrix { get; set; }
    
        SaveResult(EntityNodeMatrix matrix) {
            this.matrix = matrix;
            for (EntityNode node : matrix.entityNodeCache) {
                if (!result.containsKey(node.objectType)) {
                    result.put(node.objectType, new List<List<SObject>> { node.objects });
                } else {
                    result.get(node.objectType).add(node.objects);
                }
            }

            // Open comment for debug purpose
            this.debug();
        }

        void debug() {
            Iterator<Schema.SObjectType> keys = this.keys();
            String message = 'Topology Order:';
            while (keys.hasNext()) {
                message += ' ' + keys.next();
            }
            System.debug(message);

            Iterator<List<SObject>> values = this.values();
            while(values.hasNext()) {
                System.debug(values.next());
            }
        }
    
        public List<SObject> get(SObjectType objectType) {
            return result.get(objectType)[0];
        }
    
        public List<SObject> get(SObjectType objectType, Integer index) {
            return result.get(objectType)[index];
        }
    
        public List<SObject> getAll(SObjectType objectType) {
            List<SObject> allObjects;
            if (result.get(objectType).size() == 1) {
                allObjects = result.get(objectType)[0];
            } else {
                allObjects = new List<SObject>();
                for (List<SObject> objects : result.get(objectType)) {
                    allObjects.addAll(objects);
                }
            }
            return allObjects;
        }
    
        Iterator<Schema.SObjectType> keys() {
            return new ObjectTypeIterator(this.matrix);
        }
    
        Iterator<List<SObject>> values() {
            return new ObjectListIterator(this.matrix);
        }
    }
    
    public class ObjectTypeIterator implements Iterator<Schema.SObjectType> {
        EntityNodeMatrix matrix { get; set; }
    
        ObjectTypeIterator(EntityNodeMatrix matrix) {
            this.matrix = matrix;
            this.matrix.reset();
        }
    
        public Boolean hasNext() {
            return this.matrix.hasNext();
        }
    
        public Schema.SObjectType next() {
            if (this.hasNext()) {
                return this.matrix.next().objectType;
            } else {
                return null;
            }
        }
    }
    
    public class ObjectListIterator implements Iterator<List<SObject>> {
        EntityNodeMatrix matrix { get; set; }
    
        ObjectListIterator(EntityNodeMatrix matrix) {
            this.matrix = matrix;
            this.matrix.reset();
        }
    
        public Boolean hasNext() {
            return this.matrix.hasNext();
        }
    
        public List<SObject> next() {
            if (this.hasNext()) {
                return this.matrix.next().objects;
            } else {
                return null;
            }
        }
    }

    public class EntityCommand implements ATK.Entity, ATK.Field {
        public EntityNodeMatrix matrix { get; set; }

        {
            matrix = new EntityNodeMatrix();
        }

        // *******************************************
        // #region ATK.Entity Interface Implementation
        // ***************************************

        public SaveResult save() {
            return this.save(true);
        }

        public SaveResult save(Boolean doInsert) {
            ATKCore.SAVE_GENERATOR.generate(this.matrix, doInsert);
            return generateResult();
        }

        public SaveResult mock() {
            ATKCore.MOCK_GENERATOR.generate(this.matrix, false);
            return generateResult();
        }

        private SaveResult generateResult() {
            SaveResult result = new SaveResult(this.matrix);
            return result;
        }

        public ATK.Entity prepare(Schema.SObjectType objectType, Integer size) {
            this.matrix.add(EntityNodeType.PREPARE, new EntityNode(objectType, size), null);
            return this;
        }
    
        public ATK.Entity prepare(Schema.SObjectType objectType, List<SObject> objects) {
            this.matrix.add(EntityNodeType.PREPARE, new EntityNode(objectType, objects), null);
            return this;
        }

        public ATK.Entity withParents(Schema.SObjectType objectType, Schema.SObjectField parentIdField) {
            this.matrix.add(EntityNodeType.MANY_TO_ONE, objectType, parentIdField);
            return this;
        }

        public ATK.Entity withParents(Schema.SObjectType objectType, Schema.SObjectField parentIdField, Integer size) {
            this.matrix.add(EntityNodeType.MANY_TO_ONE, new EntityNode(objectType, size), parentIdField);
            return this;
        }

        public ATK.Entity withParents(Schema.SObjectType objectType, Schema.SObjectField parentIdField, List<SObject> objects) {
            this.matrix.add(EntityNodeType.MANY_TO_ONE, new EntityNode(objectType, objects), parentIdField);
            return this;
        }

        public ATK.Entity withChildren(Schema.SObjectType objectType, Schema.SObjectField parentIdField) {
            this.matrix.add(EntityNodeType.ONE_TO_MANY, objectType, parentIdField);
            return this;
        }

        public ATK.Entity withChildren(Schema.SObjectType objectType, Schema.SObjectField parentIdField, Integer size) {
            this.matrix.add(EntityNodeType.ONE_TO_MANY, new EntityNode(objectType, size), parentIdField);
            return this;
        }

        public ATK.Entity withChildren(Schema.SObjectType objectType, Schema.SObjectField parentIdField, List<SObject> objects) {
            this.matrix.add(EntityNodeType.ONE_TO_MANY, new EntityNode(objectType, objects), parentIdField);
            return this;
        }

        public ATK.Entity withJunction(Schema.SObjectType objectType, Schema.SObjectField parentIdField) {
            EntityNode entityNode = this.matrix.add(EntityNodeType.ONE_TO_MANY, objectType, parentIdField);
            entityNode.isJunction = true;
            return this;
        }

        public ATK.Entity withJunction(Schema.SObjectType objectType, Schema.SObjectField parentIdField, Integer size) {
            EntityNode entityNode = this.matrix.add(EntityNodeType.ONE_TO_MANY, new EntityNode(objectType, size), parentIdField);
            entityNode.isJunction = true;
            return this;
        }

        public ATK.Entity withJunction(Schema.SObjectType objectType, Schema.SObjectField parentIdField, List<SObject> objects) {
            EntityNode entityNode = this.matrix.add(EntityNodeType.ONE_TO_MANY, new EntityNode(objectType, objects), parentIdField);
            entityNode.isJunction = true;
            return this;
        }

        public ATK.Entity also() {
            this.matrix.pop(1);
            return this;
        }

        public ATK.Entity also(Integer depth) {
            this.matrix.pop(depth);
            return this;
        }

        public ATK.Field field(SObjectField field) {
            this.matrix.currEntityNode.addField(field);
            return this;
        }

        public ATK.Entity build(ATK.EntityBuilder builder) {
            builder.build(this, this.matrix.currEntityNode.size);
            return this;
        }

        // #endregion
        // *******************************************

        // **************************************
        // #region Field Interface Implementation
        // **************************************

        public ATK.Entity recordType(String name) {
            Schema.SObjectField recordTypeIdField = this.matrix.currEntityNode.dsr
                .fields.getMap().get('RecordTypeId');
            if (recordTypeIdField != null) {
                this.field(recordTypeIdField).repeat(ATKCore.RECORD_TYPES
                    .getId(this.matrix.currEntityNode.dsr, name));
            }
            return this;
        }

        public ATK.Entity profile(String name) {
            if (User.SObjectType == this.matrix.currEntityNode.objectType) {
                this.field(User.ProfileId).repeat(ATKCore.PROFILES.getId(name));
            }
            return this;
        }

        public ATK.Entity permissionSet(String name) {
            this.permissionSet(new List<String> { name });
            return this;
        }

        public ATK.Entity permissionSet(String name1, String name2) {
            this.permissionSet(new List<String> { name1, name2 });
            return this;
        }

        public ATK.Entity permissionSet(String name1, String name2, String name3) {
            this.permissionSet(new List<String> { name1, name2, name3 });
            return this;
        }

        public ATK.Entity permissionSet(List<String> names) {
            if (User.SObjectType == this.matrix.currEntityNode.objectType) {
                List<Id> permissionSetIds = ATKCore.PERMISSION_SETS.getIds(names);
                if (permissionSetIds.size() > 0) {
                    this.withChildren(
                        PermissionSetAssignment.SObjectType,
                        PermissionSetAssignment.AssigneeId,
                        this.matrix.currEntityNode.size * permissionSetIds.size())
                        .field(PermissionSetAssignment.PermissionSetId).repeat(permissionSetIds)
                        .also();
                }
            }
            return this;
        }

        public ATK.Entity index(String format) {
            this.matrix.currEntityNode.currEntityField.indexFormat = format;
            return this;
        }

        public ATK.Entity repeat(Object value) {
            this.matrix.currEntityNode.currEntityField.fixedValue = value;
            return this;
        }

        public ATK.Entity repeat(Object value1, Object value2) {
            this.matrix.currEntityNode.currEntityField.repeatValues = new List<Object> { value1, value2 };
            return this;
        }

        public ATK.Entity repeat(Object value1, Object value2, Object value3) {
            this.matrix.currEntityNode.currEntityField.repeatValues = new List<Object> { value1, value2, value3 };
            return this;
        }

        public ATK.Entity repeat(Object value1, Object value2, Object value3, Object value4) {
            this.matrix.currEntityNode.currEntityField.repeatValues = new List<Object> { value1, value2, value3, value4 };
            return this;
        }

        public ATK.Entity repeat(Object value1, Object value2, Object value3, Object value4, Object value5) {
            this.matrix.currEntityNode.currEntityField.repeatValues = new List<Object> { value1, value2, value3, value4, value5 };
            return this;
        }

        public ATK.Entity repeat(List<Object> values) {
            this.matrix.currEntityNode.currEntityField.repeatValues = values;
            return this;
        }

        // public ATK.Entity lookup(String field) {
        //     return this;
        // }

        public ATK.Entity add(Decimal init, Decimal step) {
            this.matrix.currEntityNode.currEntityField.arithmetic = ATKCore.EntityFieldArithmetic.ADD;
            this.matrix.currEntityNode.currEntityField.initValue = init;
            this.matrix.currEntityNode.currEntityField.stepValue = step;
            return this;
        }

        public ATK.Entity substract(Decimal init, Decimal step) {
            this.matrix.currEntityNode.currEntityField.arithmetic = ATKCore.EntityFieldArithmetic.SUBSTRACT;
            this.matrix.currEntityNode.currEntityField.initValue = init;
            this.matrix.currEntityNode.currEntityField.stepValue = step;
            return this;
        }

        public ATK.Entity divide(Decimal init, Decimal factor) {
            this.matrix.currEntityNode.currEntityField.arithmetic = ATKCore.EntityFieldArithmetic.DIVIDE;
            this.matrix.currEntityNode.currEntityField.initValue = init;
            this.matrix.currEntityNode.currEntityField.stepValue = factor;
            return this;
        }

        public ATK.Entity multiply(Decimal init, Decimal factor) {
            this.matrix.currEntityNode.currEntityField.arithmetic = ATKCore.EntityFieldArithmetic.MULTIPLY;
            this.matrix.currEntityNode.currEntityField.initValue = init;
            this.matrix.currEntityNode.currEntityField.stepValue = factor;
            return this;
        }

        public ATK.Entity addYears(Object init, Integer step) {
            this.matrix.currEntityNode.currEntityField.arithmetic = ATKCore.EntityFieldArithmetic.ADD_YEARS;
            this.matrix.currEntityNode.currEntityField.initValue = init;
            this.matrix.currEntityNode.currEntityField.stepValue = step;
            return this;
        }

        public ATK.Entity addMonths(Object init, Integer step) {
            this.matrix.currEntityNode.currEntityField.arithmetic = ATKCore.EntityFieldArithmetic.ADD_MONTHS;
            this.matrix.currEntityNode.currEntityField.initValue = init;
            this.matrix.currEntityNode.currEntityField.stepValue = step;
            return this;
        }

        public ATK.Entity addDays(Object init, Integer step) {
            this.matrix.currEntityNode.currEntityField.arithmetic = ATKCore.EntityFieldArithmetic.ADD_DAYS;
            this.matrix.currEntityNode.currEntityField.initValue = init;
            this.matrix.currEntityNode.currEntityField.stepValue = step;
            return this;
        }

        public ATK.Entity addHours(Object init, Integer step) {
            this.matrix.currEntityNode.currEntityField.arithmetic = ATKCore.EntityFieldArithmetic.ADD_HOURS;
            this.matrix.currEntityNode.currEntityField.initValue = init;
            this.matrix.currEntityNode.currEntityField.stepValue = step;
            return this;
        }

        public ATK.Entity addMinutes(Object init, Integer step) {
            this.matrix.currEntityNode.currEntityField.arithmetic = ATKCore.EntityFieldArithmetic.ADD_MINUTES;
            this.matrix.currEntityNode.currEntityField.initValue = init;
            this.matrix.currEntityNode.currEntityField.stepValue = step;
            return this;
        }

        public ATK.Entity addSeconds(Object init, Integer step) {
            this.matrix.currEntityNode.currEntityField.arithmetic = ATKCore.EntityFieldArithmetic.ADD_SECONDS;
            this.matrix.currEntityNode.currEntityField.initValue = init;
            this.matrix.currEntityNode.currEntityField.stepValue = step;
            return this;
        }

        // #endregion
        // **************************************
    }

    // #endregion
    // ***********************

    // *************************
    // #region SObject Generator

    public abstract class Generator {
        private Map<Schema.SObjectType, Map<Schema.SObjectField, Integer>> indexes { get; set; }

        {
            indexes = new Map<Schema.SObjectType, Map<Schema.SObjectField, Integer>>();
        }

        private Integer reserveIndex(SObjectType objectType, SObjectField field, Integer size) {
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

        abstract void generate(EntityNodeMatrix matrix, Boolean doInsert);

        protected void createObjects(EntityNode entityNode) {
            if (entityNode.objects.isEmpty()) {
                Schema.SObjectType objectType = entityNode.objectType;
                for (Integer i = 0; i < entityNode.size; ++i) {
                    entityNode.objects.add(objectType.newSObject());
                }
            }
        }

        @TestVisible
        protected void assignFields(EntityNode entityNode) {
            if (entityNode.size <= 0) {
                return;
            }

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

        /**
         * @param skipRootChild Avoid children back reference to root parents during JSON deserialization.
         */
        @TestVisible
        protected void assignReferences(EntityNode entityNode, Boolean skipRootChild) {
            if (entityNode.relatinoships != null
                && entityNode.relatinoships.size() > 0
                && entityNode.objects != null
                && entityNode.size > 0) {

                for (EntityNodeRelationship relationship : entityNode.relatinoships) {
                    if (skipRootChild && relationship.parent.isRoot && relationship.child.isRootChild) {
                        continue;
                    }

                    String relationshipName = relationship.parentIdField.getDescribe().getRelationshipName();
                    List<SObject> parentObjectList = relationship.parent.objects;
                    List<SObject> childObjectList = relationship.child.objects;

                    // Open comment for debug purpose
                    // System.debug(String.format('{0} -> {1}', new List<Object> { entityNode.objectType, relationshipName }));
                    // System.debug(String.format('{0} -> {1}', new List<Object> { childObjectList.size(), parentObjectList.size() }));

                    if (parentObjectList.size() == 0) {
                        continue;
                    }

                    for (List<Object> pair : DISTRIBUTOR.distribute(childObjectList, parentObjectList)) {
                        // * pair[0] is child, pair[1] is parent
                        ((SObject)pair[0]).put(relationship.parentIdField, ((SObject)pair[1]).Id);
                        ((SObject)pair[0]).putSObject(relationshipName, ((SObject)pair[1]));
                    }
                }
            }
        }
    }

    public class MockGenerator extends Generator {
        public override void generate(EntityNodeMatrix matrix, Boolean doInsert) {
            matrix.generateDAG();

            // step 1
            matrix.reset();
            while (matrix.hasNext()) {
                EntityNode entityNode = matrix.next();
                if (entityNode.isRoot || entityNode.isRootChild) {
                    createMockObjects(entityNode);
                    assignMockObjectFields(entityNode);
                    assignMockObjectReferences(entityNode);
                }
            }

            // step 2
            matrix.reset();
            while (matrix.hasNext()) {
                EntityNode entityNode = matrix.next();
                if (entityNode.isRoot) {
                    entityNode.convertToSObjects();
                } else if (entityNode.isRootChild) {
                    entityNode.convertToSObjectsFromParent();
                } else {
                    createMockObjects(entityNode);
                    assignMockObjectFields(entityNode);
                    entityNode.convertToSObjects();
                }
                entityNode.stashObjectIds();
                assignFields(entityNode);
                assignReferences(entityNode, true);
                entityNode.applyObjectIds();
            }
        }

        @TestVisible
        private void createMockObjects(EntityNode entityNode) {
            if (entityNode.mockObjects.isEmpty()) {
                String objectName = entityNode.dsr.getName();
                List<Id> ids = FAKEID.generate(entityNode.objectType, entityNode.size);
                entityNode.mockIds.addAll(ids);

                if (!entityNode.objects.isEmpty()) {
                    // convert objects to mock objects
                    for (Integer i = 0; i < entityNode.size; ++i) {
                        entityNode.mockObjects.add(new MockSObject(objectName, ids[i], entityNode.objects[i]));
                    }
                    entityNode.objects.clear();
                } else {
                    for (Integer i = 0; i < entityNode.size; ++i) {
                        entityNode.mockObjects.add(new MockSObject(objectName, ids[i]));
                    }
                }
            }
        }

        @TestVisible
        private void assignMockObjectFields(EntityNode entityNode) {
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

                    // fix: https://github.com/apexfarm/ApexTestKit/issues/31
                    if (entityField.dfr.getName() == 'Id') {
                        entityNode.mockIds.clear();
                        for (Integer i = 0; i < size; ++i) {
                            Object value = entityField.getValue(i + start);
                            mockObjects.get(i).Id = CONVERTER.toString(value);
                            entityNode.mockIds.add(mockObjects.get(i).Id);
                        }
                    } else {
                        for (Integer i = 0; i < size; ++i) {
                            Object value = entityField.getValue(i + start);
                            mockObjects.get(i).put(entityField.dfr.getName(), CONVERTER.toString(value));
                        }
                    }
                }
            }
        }

        @TestVisible
        public void assignMockObjectReferences(EntityNode entityNode) {
            if (entityNode.isRootChild
                && entityNode.relatinoships != null
                && entityNode.mockObjects != null) {


                for (EntityNodeRelationship relationship : entityNode.relatinoships) {
                    if (!relationship.parent.isRoot) {
                        continue;
                    }

                    MockSObjectList parentObjectList = relationship.parent.mockObjects;
                    MockSObjectList childObjectList = relationship.child.mockObjects;

                    // Open comment for debug purpose
                    // System.debug(String.format('{0} -> {1}', new List<Object> { entityNode.objectType, relationship.parentRelationshipName }));
                    // System.debug(String.format('{0} -> {1}', new List<Object> { childObjectList.size(), parentObjectList.size() }));

                    if (parentObjectList.size() == 0) {
                        continue;
                    }

                    for (List<Object> pair : DISTRIBUTOR.distribute(childObjectList.mockObjects, parentObjectList.mockObjects)) {
                        // * pair[0] is child, pair[1] is parent
                        ((MockSObject)pair[0]).put(relationship.parentRelationshipId, ((MockSObject)pair[1]).Id);
                        // pair[0].putParent(relationship.parentRelationshipName, pair[1]);
                        ((MockSObject)pair[1]).putChild(relationship.childRelationshipName, ((MockSObject)pair[0]));
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
                assignFields(entityNode);
                assignReferences(entityNode, false);

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
    }

    public class Distributor {
        public List<List<Object>> distribute(List<Object> leftGroup, List<Object> rightGroup) {
            List<List<Object>> groups = new List<List<Object>>();

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
                groups.add(new List<Object>{
                    leftGroup[i], rightGroup[j]
                });
            }
            return groups;
        }
    }

    // #endregion
    // *************************

    // ************************************
    // #region [Model] => JSON Represention

    private class MockSObjectList {
        private List<MockSObject> mockObjects { get; set; }

        MockSObjectList() {
            mockObjects = new List<MockSObject>();
        }

        void add(MockSObject objectMock) {
            mockObjects.add(objectMock);
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

        void clear() {
            mockObjects.clear();
        }

        public override String toString() {
            StringBuilder builder = new StringBuilder();
            for (MockSObject objectMock : mockObjects) {
                builder.append(String.valueOf(objectMock));
            }
            return '[' + builder.toString(',') + ']';
        }
    }

    private class MockSObject {
        private String objectName { get; set; }
        private Map<String, Object> fieldMap { get; set; }

        MockSObject(String objectName, Id objectId) {
            this.objectName = objectName;
            this.fieldMap = new Map<String, Object>();
            this.id = objectId;
        }

        MockSObject(String objectName, Id objectId, SObject obj) {
            this.objectName = objectName;
            this.fieldMap = new Map<String, Object>();
            this.id = objectId;
            Map<String, Object> fieldMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(obj));
            for (String fieldName : fieldMap.keySet()) {
                if (fieldName == 'attributes'
                    || fieldMap.get(fieldName) instanceof Map<String, Object>) {
                    // TODO: tests to cover these conditions
                    continue;
                } else {
                    this.put(fieldName, fieldMap.get(fieldName));
                }
            }
        }

        Id id {
            get;
            set {
                fieldMap.put('Id', value);
                id = value;
            }
        }

        void put(String name, Object value) {
            fieldMap.put(name, value);
        }

        // void putParent(String name, MockSObject value) {
        //     fieldMap.put(name, value);
        // }

        void putChild(String name, MockSObject value) {
            if (String.isBlank(name)) {
                return;
            }
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
                if (fieldMap.get(fieldName) instanceof MockSObjectChildren) {
                    builder.append(',"' + fieldName + '":' + String.valueOf(fieldMap.get(fieldName)));
                } else {
                    builder.append(',"' + fieldName + '":"' + String.valueOf(fieldMap.get(fieldName)) + '"');
                }
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
            return '{"totalSize":' + mockObjects.size() + ',"done":true,"records":[' + builder.toString(',') + ']}';
        }
    }

    // #endregion
    // ************************************

    // ************************************
    // #region [Model] => Entity and Fields

    @TestVisible
    private enum EntityNodeType {
        PREPARE,
        MANY_TO_ONE,
        ONE_TO_MANY
    }

    @TestVisible
    private class EntityNodeMatrix implements Iterator<EntityNode> {
        public EntityNode currEntityNode { get; private set; }
        public List<EntityNodeRelationship> entityNodeRelationships { get; private set; }
        public List<EntityNode> entityNodeCache { get; private set; }
        private List<EntityNode> entityNodeStack { get; set; }

        private SymbolDigraph graph { get; set; }
        private Topological top { get; set; }
        private Integer nextIndex { get; set; }

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
                    for (Integer childVertex : this.graph.G().adj(vertex)) {
                        queue.add(childVertex);
                    }
                }
            }
        }

        public void reset() {
            if (this.top.isDAG()) {
                nextIndex = 0;
            } else {
                throw new NoneDAGException();
            }
        }

        public Boolean hasNext() {
            return nextIndex < this.top.order().size();
        }

        public EntityNode next() {
            if (this.hasNext()) {
                return (EntityNode)this.graph.keyAt(this.top.order()[nextIndex++]);
            } else {
                return null;
            }
        }

        public EntityNode add(EntityNodeType nodeType, EntityNode nextEntityNode, Schema.SObjectField parentIdField) {
            addEntityNode(nodeType, nextEntityNode, parentIdField);
            entityNodeCache.add(nextEntityNode);
            return nextEntityNode;
        }

        public EntityNode add(EntityNodeType nodeType, Schema.SObjectType objectType, Schema.SObjectField parentIdField) {
            EntityNode nextEntityNode;
            for (EntityNode entityNode : this.entityNodeCache) {
                if (entityNode.objectType == objectType) {
                    nextEntityNode = entityNode;
                    break;
                }
            }
            if (nextEntityNode != null) {
                addEntityNode(nodeType, nextEntityNode, parentIdField);
            }
            return nextEntityNode;
        }

        private void addEntityNode(EntityNodeType nodeType, EntityNode nextEntityNode, Schema.SObjectField parentIdField) {
            EntityNodeRelationship relationship;
            switch on nodeType {
                when PREPARE {
                    nextEntityNode.isRoot = true;
                }
                when MANY_TO_ONE {
                    relationship = new EntityNodeRelationship(nextEntityNode, this.currEntityNode, parentIdField);
                }
                when ONE_TO_MANY {
                    relationship = new EntityNodeRelationship(this.currEntityNode, nextEntityNode, parentIdField);
                }
            }

            if (relationship != null) {
                entityNodeRelationships.add(relationship);
                relationship.child.relatinoships.add(relationship);
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

    private class EntityNodeRelationship {
        EntityNode parent { get; set; }
        EntityNode child { get; set; }
        Schema.SObjectField parentIdField { get; set; }
        String childRelationshipName { get; set; }
        String parentRelationshipName { get; set; }
        String parentRelationshipId { get; set; }

        EntityNodeRelationship(EntityNode parent, EntityNode child, Schema.SObjectField parentIdField) {
            this.parent = parent;
            this.child = child;
            this.parentIdField = parentIdField;

            this.parentRelationshipId = parentIdField.getDescribe().getName();
            this.parentRelationshipName = parentIdField.getDescribe().getRelationshipName();
            for (Schema.ChildRelationship cr: parent.dsr.getChildRelationships()) {
                if (cr.getChildSObject() == child.objectType && cr.getField() == parentIdField) {
                    this.childRelationshipName = cr.getRelationshipName();
                    break;
                }
            }

            if (this.parent.isRoot && String.isNotEmpty(this.childRelationshipName)) {
                this.child.isRootChild = true;
            }
        }
    }

    @TestVisible
    private class EntityNode {
        public Schema.SObjectType objectType { get; set; }
        public Schema.DescribeSObjectResult dsr { get; set; }
        public Integer size { get; set; }
        public Boolean isJunction { get; set; }

        public List<EntityNodeRelationship> relatinoships { get; set; }
        public List<SObject> objects { get; set; }

        // Used for fields generation
        public EntityField currEntityField { get; set; }
        public Map<Schema.SObjectField, EntityField> fieldMap { get; set; }
        public List<EntityField> writableFields { get; set; }
        public List<EntityField> readonlyFields { get; set; }

        // Used for mock objects generation
        public MockSObjectList mockObjects { get; set; }
        public List<Id> mockIds { get; set; }
        public Boolean isRoot { get; set; }
        public Boolean isRootChild { get; set; }

        private EntityNode(Schema.SObjectType objectType) {
            this.objectType = objectType;
            this.dsr = objectType.getDescribe();
            this.isJunction = false;

            this.relatinoships = new List<EntityNodeRelationship>();

            this.fieldMap = new Map<Schema.SObjectField, EntityField>();
            this.writableFields = new List<EntityField>();
            this.readonlyFields = new List<EntityField>();

            this.mockObjects = new MockSObjectList();
            this.mockIds = new List<Id>();
            this.isRoot = false;
            this.isRootChild = false;
        }

        public EntityNode(Schema.SObjectType objectType, Integer size) {
            this(objectType);
            this.size = size;
            this.objects = new List<SObject>();
        }

        public EntityNode(Schema.SObjectType objectType, List<SObject> objects) {
            this(objectType);
            this.objects = new List<SObject> ();
            this.objects.addAll(objects);
            this.size = this.objects.size();
        }

        public void addField(SObjectField field) {
            EntityField entityField;
            if (this.fieldMap.containsKey(field)) {
                entityField = this.fieldMap.get(field);
            } else {
                entityField = new EntityField(field);
                this.fieldMap.put(field, entityField);
                if (!entityField.dfr.isCreateable() || entityField.dfr.getName() == 'Id') {
                    this.readonlyFields.add(entityField);
                } else {
                    this.writableFields.add(entityField);
                }
            }
            this.currEntityField = entityField;
        }

        // Used for mock objects generation
        private void stashObjectIds() {
            for (SObject obj : this.objects) {
                obj.Id = null;
            }
        }

        // Used for mock objects generation
        private void applyObjectIds() {
            Integer index = 0;
            for (Id mockId : this.mockIds) {
                this.objects[index].Id = mockId;
                index++;
            }
        }

        // Used for mock objects generation
        private void convertToSObjects() {
            String jsonStr = String.valueOf(mockObjects);
            this.objects = (List<SObject>)JSON.deserialize(jsonStr, List<SObject>.class);
            this.mockObjects.clear();
        }

        // Used for mock objects generation
        private void convertToSObjectsFromParent() {
            for (EntityNodeRelationship relationship : this.relatinoships) {
                EntityNode parentNode = relationship.parent;
                if (parentNode.isRoot && parentNode.objects.size() > 0) {
                    Map<Id, SObject> objectMap = new Map<Id, SObject>();
                    for (SObject parentObj : parentNode.objects) {
                        if (String.isBlank(relationship.childRelationshipName)) {
                            continue;
                        }

                        for (SObject childObj : parentObj.getSObjects(relationship.childRelationshipName)) {
                            if (this.mockIds.contains(childObj.Id)) {
                                Id tempId = childObj.id;
                                childObj.id = null;
                                // Commented out due to issues/30, will bring it back once Salesforce fixes it.
                                // childObj.putSObject(relationship.parentRelationshipName, parentObj);
                                childObj.id = tempId;
                                objectMap.put(childObj.Id, childObj);
                            }
                        }
                    }

                    for (Id id : this.mockIds) {
                        this.objects.add(objectMap.get(id));
                    }
                }
            }
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
                this.indexLength = 0;
                System.Matcher matcher = methodPattern.matcher(value);
                while(matcher.find()) {
                    this.indexLength = matcher.group(1).length();
                }
                indexFormat = matcher.replaceFirst('{0}');
                System.debug(indexFormat);
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
                    String.valueOf(rowIndex + 1).leftPad(this.indexLength, '0')
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
    // ************************************

    // ***********************
    // #region Utility Classes

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

        public Id get(Schema.SObjectType objectType) {
            return generate(objectType, 1)[0];
        }

        public Id get(Schema.SObjectType objectType, Integer i) {
            return objectType.getDescribe().getKeyPrefix() + '000zzzz'
                + String.valueOf(i).leftPad(5, '0');
        }

        private List<Id> generate(Schema.SObjectType objectType, Integer size) {
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

        // TODO: Reserve for future uses
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

        // TODO: Reserve for future uses
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