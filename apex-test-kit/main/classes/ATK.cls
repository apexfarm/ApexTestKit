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

public with sharing class ATK implements Entity, Field {
    private static ATK sharedCommand { get; set; }
    private ATKCore.EntityNodeMatrix matrix { get; set; }

    {
        matrix = new ATKCore.EntityNodeMatrix();
    }

    public static Entity prepare(Schema.SObjectType objectType, Integer size) {
        if (sharedCommand == null) {
            sharedCommand = new ATK();
        }

        sharedCommand.matrix.add(ATKCore.EntityNodeType.PREPARE, new ATKCore.EntityNode(objectType, size), null);
        return sharedCommand;
    }

    public static Entity prepare(Schema.SObjectType objectType, List<SObject> objects) {
        if (sharedCommand == null) {
            sharedCommand = new ATK();
        }

        sharedCommand.matrix.add(ATKCore.EntityNodeType.PREPARE, new ATKCore.EntityNode(objectType, objects), null);
        return sharedCommand;
    }

    // ***************************************
    // #region Entity Interface Implementation
    // ***************************************
    public class SaveResult {
        Map<SObjectType, List<List<SObject>>> result = new Map<SObjectType, List<List<SObject>>>();

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
    }

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
        SaveResult result = new SaveResult();
        for (ATKCore.EntityNode node : matrix.entityNodeCache) {
            if (!result.result.containsKey(node.objectType)) {
                result.result.put(node.objectType, new List<List<SObject>> { node.objects });
            } else {
                result.result.get(node.objectType).add(node.objects);
            }
        }
        sharedCommand = null;
        return result;
    }

    public Entity withParents(Schema.SObjectType objectType, Schema.SObjectField parentRelationship) {
        this.matrix.add(ATKCore.EntityNodeType.MANY_TO_ONE, objectType, parentRelationship);
        return sharedCommand;
    }

    public Entity withParents(Schema.SObjectType objectType, Schema.SObjectField parentRelationship, Integer size) {
        this.matrix.add(ATKCore.EntityNodeType.MANY_TO_ONE, new ATKCore.EntityNode(objectType, size), parentRelationship);
        return sharedCommand;
    }

    public Entity withParents(Schema.SObjectType objectType, Schema.SObjectField parentRelationship, List<SObject> objects) {
        this.matrix.add(ATKCore.EntityNodeType.MANY_TO_ONE, new ATKCore.EntityNode(objectType, objects), parentRelationship);
        return sharedCommand;
    }

    public Entity withChildren(Schema.SObjectType objectType, Schema.SObjectField parentRelationship) {
        this.matrix.add(ATKCore.EntityNodeType.ONE_TO_MANY, objectType, parentRelationship);
        return sharedCommand;
    }

    public Entity withChildren(Schema.SObjectType objectType, Schema.SObjectField parentRelationship, Integer size) {
        this.matrix.add(ATKCore.EntityNodeType.ONE_TO_MANY, new ATKCore.EntityNode(objectType, size), parentRelationship);
        return sharedCommand;
    }

    public Entity withChildren(Schema.SObjectType objectType, Schema.SObjectField parentRelationship, List<SObject> objects) {
        this.matrix.add(ATKCore.EntityNodeType.ONE_TO_MANY, new ATKCore.EntityNode(objectType, objects), parentRelationship);
        return sharedCommand;
    }

    public Entity also() {
        this.matrix.pop(1);
        return sharedCommand;
    }

    public Entity also(Integer depth) {
        this.matrix.pop(depth);
        return sharedCommand;
    }

    public Field field(SObjectField field) {
        this.matrix.currEntityNode.addField(field);
        return sharedCommand;
    }

    public Entity build(ATK.EntityBuilder builder) {
        builder.build(sharedCommand, sharedCommand.matrix.currEntityNode.size);
        return sharedCommand;
    }

    // #endregion
    // ***************************************

    // **************************************
    // #region Field Interface Implementation
    // **************************************

    public Entity recordType(String name) {
        Schema.SObjectField recordTypeIdField = this.matrix.currEntityNode.dsr
            .fields.getMap().get('RecordTypeId');
        if (recordTypeIdField != null) {
            sharedCommand.field(recordTypeIdField).repeat(ATKCore.RECORD_TYPES
                .getId(this.matrix.currEntityNode.dsr, name));
        }
        return sharedCommand;
    }

    public Entity profile(String name) {
        if (User.SObjectType == sharedCommand.matrix.currEntityNode.objectType) {
            sharedCommand.field(User.ProfileId).repeat(ATKCore.PROFILES.getId(name));
        }
        return sharedCommand;
    }

    public Entity permissionSet(String name) {
        this.permissionSet(new List<String> { name });
        return sharedCommand;
    }

    public Entity permissionSet(String name1, String name2) {
        this.permissionSet(new List<String> { name1, name2 });
        return sharedCommand;
    }

    public Entity permissionSet(String name1, String name2, String name3) {
        this.permissionSet(new List<String> { name1, name2, name3 });
        return sharedCommand;
    }

    public Entity permissionSet(List<String> names) {
        if (User.SObjectType == sharedCommand.matrix.currEntityNode.objectType) {
            List<Id> permissionSetIds = ATKCore.PERMISSION_SETS.getIds(names);
            if (permissionSetIds.size() > 0) {
                sharedCommand.withChildren(
                    PermissionSetAssignment.SObjectType,
                    PermissionSetAssignment.AssigneeId,
                    sharedCommand.matrix.currEntityNode.size * permissionSetIds.size())
                    .field(PermissionSetAssignment.PermissionSetId).repeat(permissionSetIds)
                    .also();
            }
        }
        return sharedCommand;
    }

    public Entity index(String format) {
        this.matrix.currEntityNode.currEntityField.indexFormat = format;
        return sharedCommand;
    }

    public Entity repeat(Object value) {
        this.matrix.currEntityNode.currEntityField.fixedValue = value;
        return sharedCommand;
    }

    public Entity repeat(Object value1, Object value2) {
        this.matrix.currEntityNode.currEntityField.repeatValues = new List<Object> { value1, value2 };
        return sharedCommand;
    }

    public Entity repeat(Object value1, Object value2, Object value3) {
        this.matrix.currEntityNode.currEntityField.repeatValues = new List<Object> { value1, value2, value3 };
        return sharedCommand;
    }

    public Entity repeat(List<Object> values) {
        this.matrix.currEntityNode.currEntityField.repeatValues = values;
        return sharedCommand;
    }

    // public Entity lookup(String field) {

    //     return sharedCommand;
    // }

    public Entity add(Decimal init, Decimal step) {
        this.matrix.currEntityNode.currEntityField.arithmetic = ATKCore.EntityFieldArithmetic.ADD;
        this.matrix.currEntityNode.currEntityField.initValue = init;
        this.matrix.currEntityNode.currEntityField.stepValue = step;
        return sharedCommand;
    }

    public Entity substract(Decimal init, Decimal step) {
        this.matrix.currEntityNode.currEntityField.arithmetic = ATKCore.EntityFieldArithmetic.SUBSTRACT;
        this.matrix.currEntityNode.currEntityField.initValue = init;
        this.matrix.currEntityNode.currEntityField.stepValue = step;
        return sharedCommand;
    }

    public Entity divide(Decimal init, Decimal factor) {
        this.matrix.currEntityNode.currEntityField.arithmetic = ATKCore.EntityFieldArithmetic.DIVIDE;
        this.matrix.currEntityNode.currEntityField.initValue = init;
        this.matrix.currEntityNode.currEntityField.stepValue = factor;
        return sharedCommand;
    }

    public Entity multiply(Decimal init, Decimal factor) {
        this.matrix.currEntityNode.currEntityField.arithmetic = ATKCore.EntityFieldArithmetic.MULTIPLY;
        this.matrix.currEntityNode.currEntityField.initValue = init;
        this.matrix.currEntityNode.currEntityField.stepValue = factor;
        return sharedCommand;
    }

    public Entity addYears(Object init, Integer step) {
        this.matrix.currEntityNode.currEntityField.arithmetic = ATKCore.EntityFieldArithmetic.ADD_YEARS;
        this.matrix.currEntityNode.currEntityField.initValue = init;
        this.matrix.currEntityNode.currEntityField.stepValue = step;
        return sharedCommand;
    }

    public Entity addMonths(Object init, Integer step) {
        this.matrix.currEntityNode.currEntityField.arithmetic = ATKCore.EntityFieldArithmetic.ADD_MONTHS;
        this.matrix.currEntityNode.currEntityField.initValue = init;
        this.matrix.currEntityNode.currEntityField.stepValue = step;
        return sharedCommand;
    }

    public Entity addDays(Object init, Integer step) {
        this.matrix.currEntityNode.currEntityField.arithmetic = ATKCore.EntityFieldArithmetic.ADD_DAYS;
        this.matrix.currEntityNode.currEntityField.initValue = init;
        this.matrix.currEntityNode.currEntityField.stepValue = step;
        return sharedCommand;
    }

    public Entity addHours(Object init, Integer step) {
        this.matrix.currEntityNode.currEntityField.arithmetic = ATKCore.EntityFieldArithmetic.ADD_HOURS;
        this.matrix.currEntityNode.currEntityField.initValue = init;
        this.matrix.currEntityNode.currEntityField.stepValue = step;
        return sharedCommand;
    }

    public Entity addMinutes(Object init, Integer step) {
        this.matrix.currEntityNode.currEntityField.arithmetic = ATKCore.EntityFieldArithmetic.ADD_MINUTES;
        this.matrix.currEntityNode.currEntityField.initValue = init;
        this.matrix.currEntityNode.currEntityField.stepValue = step;
        return sharedCommand;
    }

    public Entity addSeconds(Object init, Integer step) {
        this.matrix.currEntityNode.currEntityField.arithmetic = ATKCore.EntityFieldArithmetic.ADD_SECONDS;
        this.matrix.currEntityNode.currEntityField.initValue = init;
        this.matrix.currEntityNode.currEntityField.stepValue = step;
        return sharedCommand;
    }

    // #endregion
    // **************************************

    // ******************
    // #region Interfaces
    // ******************
    public interface Entity {
        // keywords to start new context
        Entity withParents(Schema.SObjectType objectType, Schema.SObjectField parentRelationship);
        Entity withParents(Schema.SObjectType objectType, Schema.SObjectField parentRelationship, Integer size);
        Entity withParents(Schema.SObjectType objectType, Schema.SObjectField parentRelationship, List<SObject> objects);
        Entity withChildren(Schema.SObjectType objectType, Schema.SObjectField parentRelationship);
        Entity withChildren(Schema.SObjectType objectType, Schema.SObjectField parentRelationship, Integer size);
        Entity withChildren(Schema.SObjectType objectType, Schema.SObjectField parentRelationship, List<SObject> objects);

        // keywords to build graph
        Entity also();
        Entity also(Integer depth);
        Entity build(ATK.EntityBuilder builder);
        Field field(SObjectField field);

        // keywords to end with
        SaveResult save();
        SaveResult save(Boolean doInsert);
        SaveResult mock();

        // keywords to lookup relation
        Entity recordType(String name);
        Entity profile(String name);
        Entity permissionSet(String name);
        Entity permissionSet(String name1, String name2);
        Entity permissionSet(String name1, String name2, String name3);
        Entity permissionSet(List<String> names);
    }

    public interface Field {
        // deprecating on 3.2.0
        Entity recordType(String name);
        Entity profile(String name);
        Entity permissionSet(String name);
        Entity permissionSet(String name1, String name2);
        Entity permissionSet(String name1, String name2, String name3);
        Entity permissionSet(List<String> names);

        // Fixed Values
        Entity index(String format);
        Entity repeat(Object value);
        Entity repeat(Object value1, Object value2);
        Entity repeat(Object value1, Object value2, Object value3);
        Entity repeat(List<Object> values);
        // Entity lookup(String field);

        // Arithmetic
        Entity add(Decimal init, Decimal step);
        Entity substract(Decimal init, Decimal step);
        Entity divide(Decimal init, Decimal factor);
        Entity multiply(Decimal init, Decimal factor);

        Entity addYears(Object init, Integer step);
        Entity addMonths(Object init, Integer step);
        Entity addDays(Object init, Integer step);
        Entity addHours(Object init, Integer step);
        Entity addMinutes(Object init, Integer step);
        Entity addSeconds(Object init, Integer step);
    }

    public interface EntityBuilder {
        void build(Entity entity, Integer size);
    }
    // #endregion
    // ******************
}