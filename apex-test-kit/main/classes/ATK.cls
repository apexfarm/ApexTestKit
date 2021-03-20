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

public with sharing class ATK  {
    // ***********************
    // #region Mock Interfaces
    // ***********************

    public static Object mock(Type mockType) {
        return ATKStub.getInstance(mockType);
    }

    public static Given given(Object obj) {
        return new ATKStub.GivenStubbing();
    }

    public static Will willReturn(Object obj) {
        return new ATKStub.WillStubbing().willReturn(obj);
    }

    public static Will willAnswer(Answer answer) {
        return new ATKStub.WillStubbing().willAnswer(answer);
    }

    public static Will willThrow(Exception exp) {
        return new ATKStub.WillStubbing().willThrow(exp);
    }

    public static Will willDoNothing() {
        return new ATKStub.WillStubbing();
    }

    public static ThenOf then(Object mock) {
        return null;
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
        Given willReturn(Object obj);
        Given willAnswer(Answer obj);
        Given willThrow(Exception exp);
    }

    public interface Will {
        Will willReturn(Object obj);
        Will willAnswer(Answer answer);
        Will willThrow(Exception exp);
        Will willDoNothing();
        Object given(Object instance);
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
    // #region Argument Matcher
    // *************************

    public static Integer anyInteger() {
        return null;
    }

    public static Decimal anyDecimal() {
        return null;
    }

    public static Boolean anyBoolean() {
        return null;
    }

    public static String anyString() {
        return null;
    }

    public static List<Object> anyList() {
        return null;
    }

    public static Set<Object> anySet() {
        return null;
    }

    public static Map<Object, Object> anyMap() {
        return null;
    }

    // #endregion
    // *************************

    // *************************
    // #region Entity Interfaces
    // *************************

    public static Entity prepare(Schema.SObjectType objectType, Integer size) {
        ATKCore.EntityCommand sharedCommand  = new ATKCore.EntityCommand();
        sharedCommand.matrix.add(ATKCore.EntityNodeType.PREPARE, new ATKCore.EntityNode(objectType, size), null);
        return sharedCommand;
    }

    public static Entity prepare(Schema.SObjectType objectType, List<SObject> objects) {
        ATKCore.EntityCommand sharedCommand  = new ATKCore.EntityCommand();
        sharedCommand.matrix.add(ATKCore.EntityNodeType.PREPARE, new ATKCore.EntityNode(objectType, objects), null);
        return sharedCommand;
    }

    public static Id fakeId(Schema.SObjectType objectType) {
        return ATKCore.FAKEID.get(objectType);
    }

    public static Id fakeId(Schema.SObjectType objectType, Integer index) {
        return ATKCore.FAKEID.get(objectType, index);
    }

    public interface Entity {
        // keywords to start new context
        Entity withParents(Schema.SObjectType objectType, Schema.SObjectField parentIdField);
        Entity withParents(Schema.SObjectType objectType, Schema.SObjectField parentIdField, Integer size);
        Entity withParents(Schema.SObjectType objectType, Schema.SObjectField parentIdField, List<SObject> objects);
        Entity withChildren(Schema.SObjectType objectType, Schema.SObjectField parentIdField);
        Entity withChildren(Schema.SObjectType objectType, Schema.SObjectField parentIdField, Integer size);
        Entity withChildren(Schema.SObjectType objectType, Schema.SObjectField parentIdField, List<SObject> objects);

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

    public interface SaveResult {
        List<SObject> get(SObjectType objectType);
        List<SObject> get(SObjectType objectType, Integer index);
        List<SObject> getAll(SObjectType objectType);
    }

    // #endregion
    // *************************
}