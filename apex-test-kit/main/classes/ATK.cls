/**
 * Copyright 2018 Jeff Jin
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

    public SaveResult save(Boolean doInsert) {
        ATKCore.GENERATOR.generate(this.matrix, doInsert);
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

    public Entity withParents(Schema.SObjectType objectType, Schema.SObjectField referenceField) {
        this.matrix.add(ATKCore.EntityNodeType.MANY_TO_ONE, objectType, referenceField);
        return sharedCommand;
    }

    public Entity withParents(Schema.SObjectType objectType, Schema.SObjectField referenceField, Integer size) {
        this.matrix.add(ATKCore.EntityNodeType.MANY_TO_ONE, new ATKCore.EntityNode(objectType, size), referenceField);
        return sharedCommand;
    }

    public Entity withParents(Schema.SObjectType objectType, Schema.SObjectField referenceField, List<SObject> objects) {
        this.matrix.add(ATKCore.EntityNodeType.MANY_TO_ONE, new ATKCore.EntityNode(objectType, objects), referenceField);
        return sharedCommand;
    }

    public Entity withChildren(Schema.SObjectType objectType, Schema.SObjectField referenceField) {
        this.matrix.add(ATKCore.EntityNodeType.ONE_TO_MANY, objectType, referenceField);
        return sharedCommand;
    }

    public Entity withChildren(Schema.SObjectType objectType, Schema.SObjectField referenceField, Integer size) {
        this.matrix.add(ATKCore.EntityNodeType.ONE_TO_MANY, new ATKCore.EntityNode(objectType, size), referenceField);
        return sharedCommand;
    }

    public Entity withChildren(Schema.SObjectType objectType, Schema.SObjectField referenceField, List<SObject> objects) {
        this.matrix.add(ATKCore.EntityNodeType.ONE_TO_MANY, new ATKCore.EntityNode(objectType, objects), referenceField);
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

    public Entity field(ATK.FieldBuilder builder) {
        builder.build(sharedCommand, sharedCommand.matrix.currEntityNode.size);
        return sharedCommand;
    }

    // #endregion
    // ***************************************

    // **************************************
    // #region Field Interface Implementation
    // **************************************

    static Map<String, Id> recordTypeIdByName {
        get {
            if (recordTypeIdByName == null) {
                recordTypeIdByName = new Map<String, Id>();
                for (RecordType recordType : [SELECT Id, DeveloperName, Name FROM RecordType]) {
                    recordTypeIdByName.put(recordType.DeveloperName.toUpperCase(), recordType.Id);
                    recordTypeIdByName.put(recordType.Name.toUpperCase(), recordType.Id);
                }
            }
            return recordTypeIdByName;
        }
        set;
    }

    public Entity recordType(String name) {
        this.matrix.currEntityNode.currEntityField.fixedValue = recordTypeIdByName.get(name.toUpperCase());
        return sharedCommand;
    }

    static Map<String, Id> profileIdByName {
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

    public Entity profile(String name) {
        this.matrix.currEntityNode.currEntityField.fixedValue = profileIdByName.get(name.toUpperCase());
        return sharedCommand;
    }

    // public Entity permissionSet(String name) {

    //     return sharedCommand;
    // }

    // public Entity permissionSet(String name1, String name2) {

    //     return sharedCommand;
    // }

    // public Entity permissionSet(String name1, String name2, String name3) {

    //     return sharedCommand;
    // }

    // public Entity permissionSet(List<String> names) {

    //     return sharedCommand;
    // }

    public Entity index(String format) {
        this.matrix.currEntityNode.currEntityField.indexFormat = format;
        this.matrix.currEntityNode.currEntityField.uniqueIndex = true;
        return sharedCommand;
    }

    public Entity index(String format, Boolean unique) {
        this.matrix.currEntityNode.currEntityField.indexFormat = format;
        this.matrix.currEntityNode.currEntityField.uniqueIndex = unique;
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

    public Entity add(Object init, Object step) {
        this.matrix.currEntityNode.currEntityField.arithmetic = ATKCore.EntityFieldArithmetic.ADD;
        this.matrix.currEntityNode.currEntityField.initValue = init;
        this.matrix.currEntityNode.currEntityField.stepValue = step;
        return sharedCommand;
    }

    public Entity substract(Object init, Object step) {
        this.matrix.currEntityNode.currEntityField.arithmetic = ATKCore.EntityFieldArithmetic.SUBSTRACT;
        this.matrix.currEntityNode.currEntityField.initValue = init;
        this.matrix.currEntityNode.currEntityField.stepValue = step;
        return sharedCommand;
    }

    public Entity divide(Object init, Object factor) {
        this.matrix.currEntityNode.currEntityField.arithmetic = ATKCore.EntityFieldArithmetic.DIVIDE;
        this.matrix.currEntityNode.currEntityField.initValue = init;
        this.matrix.currEntityNode.currEntityField.stepValue = factor;
        return sharedCommand;
    }

    public Entity multiply(Object init, Object factor) {
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
        Entity withParents(Schema.SObjectType objectType, Schema.SObjectField referenceField);
        Entity withParents(Schema.SObjectType objectType, Schema.SObjectField referenceField, Integer size);
        Entity withParents(Schema.SObjectType objectType, Schema.SObjectField referenceField, List<SObject> objects);
        Entity withChildren(Schema.SObjectType objectType, Schema.SObjectField referenceField);
        Entity withChildren(Schema.SObjectType objectType, Schema.SObjectField referenceField, Integer size);
        Entity withChildren(Schema.SObjectType objectType, Schema.SObjectField referenceField, List<SObject> objects);

        // keywords to build graph
        Entity also();
        Entity also(Integer depth);
        Entity field(ATK.FieldBuilder builder);
        Field field(SObjectField field);

        // Entity permissionSet(String name);
        // Entity permissionSet(String name1, String name2);
        // Entity permissionSet(String name1, String name2, String name3);
        // Entity permissionSet(List<String> names);

        // keywords to end with
        SaveResult save(Boolean doInsert);
    }

    public interface Field {
        Entity recordType(String name);
        Entity profile(String name);

        // Fixed Values
        Entity index(String format);
        Entity index(String format, Boolean unique);
        Entity repeat(Object value);
        Entity repeat(Object value1, Object value2);
        Entity repeat(Object value1, Object value2, Object value3);
        Entity repeat(List<Object> values);
        // Entity lookup(String field);

        // Arithmetic
        Entity add(Object init, Object step);
        Entity substract(Object init, Object step);
        Entity divide(Object init, Object factor);
        Entity multiply(Object init, Object factor);

        Entity addYears(Object init, Integer step);
        Entity addMonths(Object init, Integer step);
        Entity addDays(Object init, Integer step);
        Entity addHours(Object init, Integer step);
        Entity addMinutes(Object init, Integer step);
        Entity addSeconds(Object init, Integer step);
    }

    public interface FieldBuilder {
        void build(Entity entity, Integer size);
    }
    // #endregion
    // ******************
}