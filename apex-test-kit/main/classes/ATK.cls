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

public with sharing class ATK {
    // ***********************
    // #region Mock Interfaces
    // ***********************

    private static final ATKMock mockInstance = new ATKMock();

    public static Object mock(Type mockType) {
        return mockInstance.createMock(mockType).mock;
    }

    public static void startStubbing() {
        mockInstance.startStubbing();
    }

    public static void stopStubbing() {
        mockInstance.stopStubbing();
    }

    public static Given given(Object value) {
        return mockInstance.setGivenStub();
    }

    public static Will willReturn(Object value) {
        return mockInstance.setWillStub().willReturn(value);
    }

    public static Will willAnswer(Answer answer) {
        return mockInstance.setWillStub().willAnswer(answer);
    }

    public static Will willThrow(Exception exp) {
        return mockInstance.setWillStub().willThrow(exp);
    }

    public static Will willDoNothing() {
        return mockInstance.setWillStub().willDoNothing();
    }

    public static ThenOf then(Object mock) {
        return mockInstance.then(mock);
    }

    public static InOrder inOrder(Object mock1) {
        return null;
    }

    public static InOrder inOrder(Object mock1, Object mock2) {
        return null;
    }

    public static InOrder inOrder(Object mock, Object mock2, Object mock3) {
        return null;
    }

    public interface Given {
        Given willReturn(Object value);
        Given willAnswer(Answer answer);
        Given willThrow(Exception exp);
    }

    public interface Will {
        Will willReturn(Object value);
        Will willAnswer(Answer answer);
        Will willThrow(Exception exp);
        Will willDoNothing();
        Object given(Object mock);
    }

    public interface Answer {
        Object answer(Invocation invocation);
    }

    public interface Invocation {
    }

    public interface ThenOf {
        Should should();
        Should should(InOrder inOrder);
    }

    public interface InOrder {
    }

    public interface Should {
        Object never();
        Object times(Integer times);
        Object atLeast(Integer times);
        Object atMost(Integer times);
    }

    // #endregion
    // *************************

    // *************************
    // #region Argument Matchers
    // *************************
    // Type Matchers
    public static Integer anyInteger() {
        return mockInstance.argumentManager.anyInteger();
    }

    public static Long anyLong() {
        return mockInstance.argumentManager.anyLong();
    }

    public static Double anyDouble() {
        return mockInstance.argumentManager.anyDouble();
    }

    public static Decimal anyDecimal() {
        return mockInstance.argumentManager.anyDecimal();
    }

    public static Date anyDate() {
        return mockInstance.argumentManager.anyDate();
    }

    public static Datetime anyDatetime() {
        return mockInstance.argumentManager.anyDatetime();
    }

    public static Id anyId() {
        return mockInstance.argumentManager.anyId();
    }

    public static String anyString() {
        return mockInstance.argumentManager.anyString();
    }

    public static Boolean anyBoolean() {
        return mockInstance.argumentManager.anyBoolean();
    }

    public static Object anyObject() {
        return mockInstance.argumentManager.anyObject();
    }

    public static List<Object> anyList() {
        return mockInstance.argumentManager.anyList();
    }

    public static Object anySet() {
        return mockInstance.argumentManager.anySet();
    }

    public static Object anyMap() {
        return mockInstance.argumentManager.anyMap();
    }

    // Value Matchers
    public static ArgumentCaster eq(Object value) {
        return mockInstance.argumentManager.eq(value);
    }

    public static ComparableArgumentCaster gt(Object value) {
        return mockInstance.argumentManager.gt(value);
    }

    public static ComparableArgumentCaster gte(Object value) {
        return mockInstance.argumentManager.gte(value);
    }

    public static ComparableArgumentCaster lt(Object value) {
        return mockInstance.argumentManager.lt(value);
    }

    public static ComparableArgumentCaster lte(Object value) {
        return mockInstance.argumentManager.lte(value);
    }

    public static ComparableArgumentCaster between(Object minValue, Object maxValue) {
        return mockInstance.argumentManager.between(minValue, maxValue);
    }

    public static ComparableArgumentCaster between(Object minValue, Object maxValue, Boolean inclusive) {
        return mockInstance.argumentManager.between(minValue, maxValue, inclusive);
    }

    public static ComparableArgumentCaster between(Object minValue, Boolean minInclusive, Object maxValue, Boolean maxInclusive) {
        return mockInstance.argumentManager.between(minValue, minInclusive, maxValue, maxInclusive);
    }

    // Combo Matchers
    public static Object allOf(Object o1, Object o2) {
        return mockInstance.argumentManager.allOf(o1, o2);
    }

    public static Object allOf(Object o1, Object o2, Object o3) {
        return mockInstance.argumentManager.allOf(o1, o2, o3);
    }

    public static Object allOf(Object o1, Object o2, Object o3, Object o4) {
        return mockInstance.argumentManager.allOf(o1, o2, o3, o4);
    }

    public static Object allOf(Object o1, Object o2, Object o3, Object o4, Object o5) {
        return mockInstance.argumentManager.allOf(o1, o2, o3, o4, o5);
    }

    public static Object allOf(List<Object> os) {
        return mockInstance.argumentManager.allOf(os);
    }

    public static Object anyOf(Object o1, Object o2) {
        return mockInstance.argumentManager.anyOf(o1, o2);
    }

    public static Object anyOf(Object o1, Object o2, Object o3) {
        return mockInstance.argumentManager.anyOf(o1, o2, o3);
    }

    public static Object anyOf(Object o1, Object o2, Object o3, Object o4) {
        return mockInstance.argumentManager.anyOf(o1, o2, o3, o4);
    }

    public static Object anyOf(Object o1, Object o2, Object o3, Object o4, Object o5) {
        return mockInstance.argumentManager.anyOf(o1, o2, o3, o4, o5);
    }

    public static Object anyOf(List<Object> os) {
        return mockInstance.argumentManager.anyOf(os);
    }

    public static Object isNot(Object o1) {
        return mockInstance.argumentManager.isNot(o1);
    }

    public static Object noneOf(Object o1, Object o2) {
        return mockInstance.argumentManager.noneOf(o1, o2);
    }

    public static Object noneOf(Object o1, Object o2, Object o3) {
        return mockInstance.argumentManager.noneOf(o1, o2, o3);
    }

    public static Object noneOf(Object o1, Object o2, Object o3, Object o4) {
        return mockInstance.argumentManager.noneOf(o1, o2, o3, o4);
    }

    public static Object noneOf(Object o1, Object o2, Object o3, Object o4, Object o5) {
        return mockInstance.argumentManager.noneOf(o1, o2, o3, o4, o5);
    }

    public static Object noneOf(List<Object> os) {
        return mockInstance.argumentManager.noneOf(os);
    }

    public interface ArgumentMatcher {
        Boolean matches(Type type, Object arg);
    }

    public interface ArgumentManager {
        // Type Matchers
        Integer anyInteger();
        Long anyLong();
        Double anyDouble();
        Decimal anyDecimal();
        Date anyDate();
        Datetime anyDatetime();
        Id anyId();
        String anyString();
        Boolean anyBoolean();
        Object anyObject();
        List<Object> anyList();
        Object anySet();
        Object anyMap();

        // Value Matchers
        ArgumentCaster isNull();
        ArgumentCaster eq(Object value);
        ComparableArgumentCaster gt(Object value);
        ComparableArgumentCaster gte(Object value);
        ComparableArgumentCaster lt(Object value);
        ComparableArgumentCaster lte(Object value);
        ComparableArgumentCaster between(Object minValue, Object maxValue);
        ComparableArgumentCaster between(Object minValue, Object maxValue, Boolean inclusive);
        ComparableArgumentCaster between(Object minValue, Boolean minInclusive, Object maxValue, Boolean maxInclusive);

        // Combo Matchers
        Object allOf(Object o1, Object o2);
        Object allOf(Object o1, Object o2, Object o3);
        Object allOf(Object o1, Object o2, Object o3, Object o4);
        Object allOf(Object o1, Object o2, Object o3, Object o4, Object o5);
        Object allOf(List<Object> os);
        Object anyOf(Object o1, Object o2);
        Object anyOf(Object o1, Object o2, Object o3);
        Object anyOf(Object o1, Object o2, Object o3, Object o4);
        Object anyOf(Object o1, Object o2, Object o3, Object o4, Object o5);
        Object anyOf(List<Object> os);
        Object isNot(Object o1);
        Object noneOf(Object o1, Object o2);
        Object noneOf(Object o1, Object o2, Object o3);
        Object noneOf(Object o1, Object o2, Object o3, Object o4);
        Object noneOf(Object o1, Object o2, Object o3, Object o4, Object o5);
        Object noneOf(List<Object> os);
    }

    public interface ComparableArgumentCaster {
        Integer asInteger();
        Long asLong();
        Double asDouble();
        Decimal asDecimal();
        Date asDate();
        Datetime asDatetime();
        Id asId();
        String asString();
    }

    public interface ArgumentCaster extends ComparableArgumentCaster {
        Boolean asBoolean();
        Object asObject();
    }

    // #endregion
    // *************************

    // *************************
    // #region Entity Interfaces
    // *************************

    public static JunctionEntity prepare(Schema.SObjectType objectType, Integer size) {
        ATKCore.EntityCommand sharedCommand = new ATKCore.EntityCommand();
        sharedCommand.prepare(objectType, size);
        return sharedCommand;
    }

    public static Entity prepare(Schema.SObjectType objectType, List<SObject> objects) {
        ATKCore.EntityCommand sharedCommand = new ATKCore.EntityCommand();
        sharedCommand.prepare(objectType, objects);
        return sharedCommand;
    }

    public static Id fakeId(Schema.SObjectType objectType) {
        return ATKCore.FAKEID.get(objectType);
    }

    public static Id fakeId(Schema.SObjectType objectType, Integer index) {
        return ATKCore.FAKEID.get(objectType, index);
    }

    public interface JunctionEntity extends Entity {
        Entity junctionOf(Schema.SObjectField parentIdField1, Schema.SObjectField parentIdField2);
        Entity junctionOf(Schema.SObjectField parentIdField1, Schema.SObjectField parentIdField2, Schema.SObjectField parentIdField3);
        Entity junctionOf(Schema.SObjectField parentIdField1, Schema.SObjectField parentIdField2, Schema.SObjectField parentIdField3, Schema.SObjectField parentIdField4);
        Entity junctionOf(
            Schema.SObjectField parentIdField1,
            Schema.SObjectField parentIdField2,
            Schema.SObjectField parentIdField3,
            Schema.SObjectField parentIdField4,
            Schema.SObjectField parentIdField5
        );
        Entity junctionOf(List<Schema.SObjectField> parentIdFields);
    }

    public interface Entity {
        // keywords to start new context
        JunctionEntity withParents(Schema.SObjectType objectType, Schema.SObjectField parentIdField);
        JunctionEntity withParents(Schema.SObjectType objectType, Schema.SObjectField parentIdField, Integer size);
        JunctionEntity withParents(Schema.SObjectType objectType, Schema.SObjectField parentIdField, List<SObject> objects);
        JunctionEntity withChildren(Schema.SObjectType objectType, Schema.SObjectField parentIdField);
        JunctionEntity withChildren(Schema.SObjectType objectType, Schema.SObjectField parentIdField, Integer size);
        JunctionEntity withChildren(Schema.SObjectType objectType, Schema.SObjectField parentIdField, List<SObject> objects);

        // keywords to build graph
        Entity also();
        Entity also(Integer depth);
        Entity build(ATK.EntityBuilder builder);
        Field field(SObjectField field);

        // keywords to lookup relation
        Entity recordType(String name);
        Entity profile(String name);
        Entity permissionSet(String name);
        Entity permissionSet(String name1, String name2);
        Entity permissionSet(String name1, String name2, String name3);
        Entity permissionSet(List<String> names);

        // keywords to end with
        SaveResult save();
        SaveResult save(Boolean doInsert);
        SaveResult mock();
    }

    public interface Field {
        // deprecated on 3.2.0
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
        Entity repeat(Object value1, Object value2, Object value3, Object value4);
        Entity repeat(Object value1, Object value2, Object value3, Object value4, Object value5);
        Entity repeat(List<Object> values);
        Entity repeatX(Object value1, Integer size1, Object value2, Integer size2);
        Entity repeatX(Object value1, Integer size1, Object value2, Integer size2, Object value3, Integer size3);
        Entity repeatX(Object value1, Integer size1, Object value2, Integer size2, Object value3, Integer size3, Object value4, Integer size4);
        Entity repeatX(Object value1, Integer size1, Object value2, Integer size2, Object value3, Integer size3, Object value4, Integer size4, Object value5, Integer size5);
        Entity repeatX(List<Object> values, List<Integer> sizes);

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

    public interface SaveResult {
        List<SObject> get(SObjectType objectType); // return the first matching lists
        List<SObject> get(SObjectType objectType, Integer index);
        List<SObject> getAll(SObjectType objectType);
    }

    // #endregion
    // *************************
}
