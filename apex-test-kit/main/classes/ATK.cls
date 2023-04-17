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
    public virtual class MockException extends Exception {
    }

    // ==============
    // #region Entity

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
        List<SObject> get(SObjectType objectType);
        List<SObject> get(SObjectType objectType, Integer index);
        List<SObject> getAll(SObjectType objectType);
        List<Id> getIds(SObjectType objectType);
        List<Id> getIds(SObjectType objectType, Integer index);
        List<Id> getAllIds(SObjectType objectType);
    }

    // #endregion
    // ==============

    // =======================
    // #region Mock Interfaces

    private static Mock MOCK {
        get {
            if (MOCK == null) {
                Type mockType = Type.forName('ATKMock');
                if (mockType != null) {
                    MOCK = (Mock) mockType.newInstance();
                } else {
                    throw new MockException('Please install/add ATKMock class.');
                }
            }
            return MOCK;
        }
        set;
    }
    public static final Answer RETURNS_DEFAULTS = MOCK.getReturnsDefaults();
    public static final Answer RETURNS_SELF = MOCK.getReturnsSelf();
    public static final Answer RETURNS_MOCKS = MOCK.getReturnsMocks();
    private static final MockingProgress PROGRESS = MOCK.getProgress();
    private static final MatcherRecorder MATCHER_RECORDER = MOCK.getMatcherRecorder();

    public static void startStubbing() {
        PROGRESS.startStubbing();
    }

    public static void stopStubbing() {
        PROGRESS.stopStubbing();
    }

    public static MockSettings withSettings() {
        return PROGRESS.newCustomSettings();
    }

    public static GlobalSettings mock() {
        return PROGRESS.getGlobalSettings();
    }

    public static Object mock(Type mockType) {
        return PROGRESS.createMock(mockType);
    }

    public static Object mock(Type mockType, Answer defaultAnswer) {
        return PROGRESS.createMock(mockType, defaultAnswer);
    }

    public static Object mock(Type mockType, MockSettings settings) {
        return PROGRESS.createMock(mockType, settings);
    }

    public static Lenient lenient() {
        return PROGRESS.createLenientStubber();
    }

    public static Given given(Object value) {
        return PROGRESS.createGivenStubber();
    }

    public static Will willReturn(Object value) {
        return PROGRESS.createWillStubber().willReturn(value);
    }

    public static Will willAnswer(Answer answer) {
        return PROGRESS.createWillStubber().willAnswer(answer);
    }

    public static Will willThrow(Exception exp) {
        return PROGRESS.createWillStubber().willThrow(exp);
    }

    public static Will willDoNothing() {
        return PROGRESS.createWillStubber().willDoNothing();
    }

    public static ThenOf then(Object mock) {
        return PROGRESS.createThenStubber(mock);
    }

    public static InOrder inOrder(List<Object> mocks) {
        return PROGRESS.createInOrder(mocks);
    }

    public static InOrder inOrder(Object mock1) {
        return inOrder(new List<Object>{ mock1 });
    }

    public static InOrder inOrder(Object mock1, Object mock2) {
        return inOrder(new List<Object>{ mock1, mock2 });
    }

    public static InOrder inOrder(Object mock1, Object mock2, Object mock3) {
        return inOrder(new List<Object>{ mock1, mock2, mock3 });
    }

    public static InOrder inOrder(Object mock1, Object mock2, Object mock3, Object mock4) {
        return inOrder(new List<Object>{ mock1, mock2, mock3, mock4 });
    }

    public static InOrder inOrder(Object mock1, Object mock2, Object mock3, Object mock4, Object mock5) {
        return inOrder(new List<Object>{ mock1, mock2, mock3, mock4, mock5 });
    }

    public interface Mock {
        ATK.Answer getReturnsDefaults();
        ATK.Answer getReturnsSelf();
        ATK.Answer getReturnsMocks();
        ATK.MockingProgress getProgress();
        ATK.MatcherRecorder getMatcherRecorder();
    }

    public interface MockingProgress {
        void startStubbing();
        void stopStubbing();
        MockSettings newCustomSettings();
        GlobalSettings getGlobalSettings();
        Object createMock(Type mockType);
        Object createMock(Type mockType, ATK.Answer defaultAnswer);
        Object createMock(Type mockType, ATK.MockSettings settings);
        Lenient createLenientStubber();
        Given createGivenStubber();
        Will createWillStubber();
        ThenOf createThenStubber(Object mock);
        InOrder createInOrder(List<Object> mocks);
    }

    public interface MockSettings {
        MockSettings name(String name);
        MockSettings defaultAnswer(Answer answer);
        MockSettings stubOnly();
        MockSettings lenient();
        MockSettings stubbedVoids();
        MockSettings verbose();
    }

    public interface GlobalSettings {
        MockSettings withSettings();
    }

    public interface Lenient {
        Given given(Object mock);
        Will willReturn(Object value);
        Will willAnswer(Answer answer);
        Will willThrow(Exception exp);
        Will willDoNothing();
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

    public virtual class Method {
        public String name { get; protected set; }
        public List<Type> paramTypes { get; protected set; }
        public List<String> paramNames { get; protected set; }
        public Type returnType { get; protected set; }
    }

    public virtual class Invocation {
        public Method method { get; protected set; }
        public Object mock { get; protected set; }
        public Type mockType { get; protected set; }
        public List<Object> arguments { get; protected set; }
    }

    public interface ThenOf {
        Should should();
        InOrderShould should(InOrder inOrder);
    }

    public interface InOrder {
    }

    public interface Should {
        void haveNoInteractions();
        void haveNoMoreInteractions();
        void haveNoUnusedStubs();

        Object never();
        Object once();
        Object times(Integer n);
        Object atLeast(Integer n);
        Object atLeastOnce();
        Object atMost(Integer n);
        Object atMostOnce();
    }

    public interface InOrderShould {
        void haveNoMoreInteractions();

        Object never();
        Object once();
        Object times(Integer n);
        Object calls(Integer n);
    }

    public interface GlobalShould {
        void haveNoInteractions();
        void haveNoInteractions(Object mock1);
        void haveNoInteractions(Object mock1, Object mock2);
        void haveNoInteractions(Object mock1, Object mock2, Object mock3);
        void haveNoInteractions(Object mock1, Object mock2, Object mock3, Object mock4);
        void haveNoInteractions(Object mock1, Object mock2, Object mock3, Object mock4, Object mock5);
        void haveNoInteractions(List<Object> mocks);
        void haveNoMoreInteractions();
        void haveNoMoreInteractions(Object mock1);
        void haveNoMoreInteractions(Object mock1, Object mock2);
        void haveNoMoreInteractions(Object mock1, Object mock2, Object mock3);
        void haveNoMoreInteractions(Object mock1, Object mock2, Object mock3, Object mock4);
        void haveNoMoreInteractions(Object mock1, Object mock2, Object mock3, Object mock4, Object mock5);
        void haveNoMoreInteractions(List<Object> mocks);
        void haveNoUnusedStubs();
        void haveNoUnusedStubs(Object mock1);
        void haveNoUnusedStubs(Object mock1, Object mock2);
        void haveNoUnusedStubs(Object mock1, Object mock2, Object mock3);
        void haveNoUnusedStubs(Object mock1, Object mock2, Object mock3, Object mock4);
        void haveNoUnusedStubs(Object mock1, Object mock2, Object mock3, Object mock4, Object mock5);
        void haveNoUnusedStubs(List<Object> mocks);
    }

    public interface Matcher {
        Boolean matches(Type type, Object arg);
    }

    public interface MatcherRecorder {
        // Type Matchers
        Integer anyInteger();
        Long anyLong();
        Double anyDouble();
        Decimal anyDecimal();
        Date anyDate();
        Datetime anyDatetime();
        Time anyTime();
        Id anyId();
        String anyString();
        Boolean anyBoolean();

        List<Object> anyList();
        Object anySet();
        Object anyMap();

        Object any();
        Object any(Type type);
        Object nullable(Type type);

        SObject anySObject();
        List<SObject> anySObjectList();

        // Value Matchers
        Object isNull();
        Object isNotNull();
        Object same(Object value);

        Object ne(Object value);
        Integer neInteger(Integer value);
        Long neLong(Long value);
        Double neDouble(Double value);
        Decimal neDecimal(Decimal value);
        Date neDate(Date value);
        Datetime neDatetime(Datetime value);
        Time neTime(Time value);
        Id neId(Id value);
        String neString(String value);
        Boolean neBoolean(Boolean value);

        Object eq(Object value);
        Integer eqInteger(Integer value);
        Long eqLong(Long value);
        Double eqDouble(Double value);
        Decimal eqDecimal(Decimal value);
        Date eqDate(Date value);
        Datetime eqDatetime(Datetime value);
        Time eqTime(Time value);
        Id eqId(Id value);
        String eqString(String value);
        Boolean eqBoolean(Boolean value);

        Integer gt(Integer value);
        Long gt(Long value);
        Double gt(Double value);
        Decimal gt(Decimal value);
        Date gt(Date value);
        Datetime gt(Datetime value);
        Time gt(Time value);
        Id gt(Id value);
        String gt(String value);

        Integer gte(Integer value);
        Long gte(Long value);
        Double gte(Double value);
        Decimal gte(Decimal value);
        Date gte(Date value);
        Datetime gte(Datetime value);
        Time gte(Time value);
        Id gte(Id value);
        String gte(String value);

        Integer lt(Integer value);
        Long lt(Long value);
        Double lt(Double value);
        Decimal lt(Decimal value);
        Date lt(Date value);
        Datetime lt(Datetime value);
        Time lt(Time value);
        Id lt(Id value);
        String lt(String value);

        Integer lte(Integer value);
        Long lte(Long value);
        Double lte(Double value);
        Decimal lte(Decimal value);
        Date lte(Date value);
        Datetime lte(Datetime value);
        Time lte(Time value);
        Id lte(Id value);
        String lte(String value);

        Integer between(Integer min, Boolean minInclusive, Integer max, Boolean maxInclusive);
        Long between(Long min, Boolean minInclusive, Long max, Boolean maxInclusive);
        Double between(Double min, Boolean minInclusive, Double max, Boolean maxInclusive);
        Decimal between(Decimal min, Boolean minInclusive, Decimal max, Boolean maxInclusive);
        Date between(Date min, Boolean minInclusive, Date max, Boolean maxInclusive);
        Datetime between(Datetime min, Boolean minInclusive, Datetime max, Boolean maxInclusive);
        Time between(Time min, Boolean minInclusive, Time max, Boolean maxInclusive);
        Id between(Id min, Boolean minInclusive, Id max, Boolean maxInclusive);
        String between(String min, Boolean minInclusive, String max, Boolean maxInclusive);

        String isBlank();
        String isNotBlank();
        String startsWith(String value);
        String endsWith(String value);
        String matches(String regexp);
        String contains(String value);

        // TODO: implement list matchers
        // Object listContains(Object value);
        // Object listIsEmpty();

        SObject sObjectWithId(Id value);
        SObject sObjectWithName(String value);
        SObject sObjectWith(SObjectField field, Object value);
        SObject sObjectWith(Map<SObjectField, Object> value);
        SObject sObjectWith(Map<SObjectField, Matcher> value);
        LIst<SObject> sObjectListWith(SObjectField field, Object value);
        LIst<SObject> sObjectListWith(Map<SObjectField, Object> value);
        LIst<SObject> sObjectListWith(List<Map<SObjectField, Object>> value, Boolean inOrder);

        // Combo Matchers
        Object allOf(Object arg1, Object arg2);
        Object allOf(Object arg1, Object arg2, Object arg3);
        Object allOf(Object arg1, Object arg2, Object arg3, Object arg4);
        Object allOf(Object arg1, Object arg2, Object arg3, Object arg4, Object arg5);
        Object allOf(List<Object> args);
        Object anyOf(Object arg1, Object arg2);
        Object anyOf(Object arg1, Object arg2, Object arg3);
        Object anyOf(Object arg1, Object arg2, Object arg3, Object arg4);
        Object anyOf(Object arg1, Object arg2, Object arg3, Object arg4, Object arg5);
        Object anyOf(List<Object> args);
        Object isNot(Object arg1);
        Object noneOf(Object arg1, Object arg2);
        Object noneOf(Object arg1, Object arg2, Object arg3);
        Object noneOf(Object arg1, Object arg2, Object arg3, Object arg4);
        Object noneOf(Object arg1, Object arg2, Object arg3, Object arg4, Object arg5);
        Object noneOf(List<Object> args);
    }

    // #endregion
    // =======================

    // =========================
    // #region Argument Matchers

    // #region - Type Matchers
    public static Integer anyInteger() {
        return MATCHER_RECORDER.anyInteger();
    }

    public static Long anyLong() {
        return MATCHER_RECORDER.anyLong();
    }

    public static Double anyDouble() {
        return MATCHER_RECORDER.anyDouble();
    }

    public static Decimal anyDecimal() {
        return MATCHER_RECORDER.anyDecimal();
    }

    public static Date anyDate() {
        return MATCHER_RECORDER.anyDate();
    }

    public static Datetime anyDatetime() {
        return MATCHER_RECORDER.anyDatetime();
    }

    public static Time anyTime() {
        return MATCHER_RECORDER.anyTime();
    }

    public static Id anyId() {
        return MATCHER_RECORDER.anyId();
    }

    public static String anyString() {
        return MATCHER_RECORDER.anyString();
    }

    public static Boolean anyBoolean() {
        return MATCHER_RECORDER.anyBoolean();
    }

    public static List<Object> anyList() {
        return MATCHER_RECORDER.anyList();
    }

    public static Object anySet() {
        return MATCHER_RECORDER.anySet();
    }

    public static Object anyMap() {
        return MATCHER_RECORDER.anyMap();
    }

    public static Object any() {
        return MATCHER_RECORDER.any();
    }

    public static Object any(Type type) {
        return MATCHER_RECORDER.any(type);
    }

    public static Object nullable(Type type) {
        return MATCHER_RECORDER.nullable(type);
    }

    public static SObject anySObject() {
        return MATCHER_RECORDER.anySObject();
    }

    public static List<SObject> anySObjectList() {
        return MATCHER_RECORDER.anySObjectList();
    }
    // #endregion

    // #region - Value Matchers
    public static Object isNull() {
        return MATCHER_RECORDER.isNull();
    }

    public static Object isNotNull() {
        return MATCHER_RECORDER.isNotNull();
    }

    public static Object same(Object value) {
        return MATCHER_RECORDER.same(value);
    }

    public static Object ne(Object value) {
        return MATCHER_RECORDER.ne(value);
    }

    public static Integer neInteger(Integer value) {
        return MATCHER_RECORDER.neInteger(value);
    }

    public static Long neLong(Long value) {
        return MATCHER_RECORDER.neLong(value);
    }

    public static Double neDouble(Double value) {
        return MATCHER_RECORDER.neDouble(value);
    }

    public static Decimal neDecimal(Decimal value) {
        return MATCHER_RECORDER.neDecimal(value);
    }

    public static Date neDate(Date value) {
        return MATCHER_RECORDER.neDate(value);
    }

    public static Datetime neDatetime(Datetime value) {
        return MATCHER_RECORDER.neDatetime(value);
    }

    public static Time neTime(Time value) {
        return MATCHER_RECORDER.neTime(value);
    }

    public static Id neId(Id value) {
        return MATCHER_RECORDER.neId(value);
    }

    public static String neString(String value) {
        return MATCHER_RECORDER.neString(value);
    }

    public static Boolean neBoolean(Boolean value) {
        return MATCHER_RECORDER.neBoolean(value);
    }

    public static Object eq(Object value) {
        return MATCHER_RECORDER.eq(value);
    }

    public static Integer eqInteger(Integer value) {
        return MATCHER_RECORDER.eqInteger(value);
    }

    public static Long eqLong(Long value) {
        return MATCHER_RECORDER.eqLong(value);
    }

    public static Double eqDouble(Double value) {
        return MATCHER_RECORDER.eqDouble(value);
    }

    public static Decimal eqDecimal(Decimal value) {
        return MATCHER_RECORDER.eqDecimal(value);
    }

    public static Date eqDate(Date value) {
        return MATCHER_RECORDER.eqDate(value);
    }

    public static Datetime eqDatetime(Datetime value) {
        return MATCHER_RECORDER.eqDatetime(value);
    }

    public static Time eqTime(Time value) {
        return MATCHER_RECORDER.eqTime(value);
    }

    public static Id eqId(Id value) {
        return MATCHER_RECORDER.eqId(value);
    }

    public static String eqString(String value) {
        return MATCHER_RECORDER.eqString(value);
    }

    public static Boolean eqBoolean(Boolean value) {
        return MATCHER_RECORDER.eqBoolean(value);
    }

    public static Integer gt(Integer value) {
        return MATCHER_RECORDER.gt(value);
    }

    public static Long gt(Long value) {
        return MATCHER_RECORDER.gt(value);
    }

    public static Double gt(Double value) {
        return MATCHER_RECORDER.gt(value);
    }

    public static Decimal gt(Decimal value) {
        return MATCHER_RECORDER.gt(value);
    }

    public static Date gt(Date value) {
        return MATCHER_RECORDER.gt(value);
    }

    public static Datetime gt(Datetime value) {
        return MATCHER_RECORDER.gt(value);
    }

    public static Time gt(Time value) {
        return MATCHER_RECORDER.gt(value);
    }

    public static Id gt(Id value) {
        return MATCHER_RECORDER.gt(value);
    }

    public static String gt(String value) {
        return MATCHER_RECORDER.gt(value);
    }

    public static Integer gte(Integer value) {
        return MATCHER_RECORDER.gte(value);
    }

    public static Long gte(Long value) {
        return MATCHER_RECORDER.gte(value);
    }

    public static Double gte(Double value) {
        return MATCHER_RECORDER.gte(value);
    }

    public static Decimal gte(Decimal value) {
        return MATCHER_RECORDER.gte(value);
    }

    public static Date gte(Date value) {
        return MATCHER_RECORDER.gte(value);
    }

    public static Datetime gte(Datetime value) {
        return MATCHER_RECORDER.gte(value);
    }

    public static Time gte(Time value) {
        return MATCHER_RECORDER.gte(value);
    }

    public static Id gte(Id value) {
        return MATCHER_RECORDER.gte(value);
    }

    public static String gte(String value) {
        return MATCHER_RECORDER.gte(value);
    }

    public static Integer lt(Integer value) {
        return MATCHER_RECORDER.lt(value);
    }

    public static Long lt(Long value) {
        return MATCHER_RECORDER.lt(value);
    }

    public static Double lt(Double value) {
        return MATCHER_RECORDER.lt(value);
    }

    public static Decimal lt(Decimal value) {
        return MATCHER_RECORDER.lt(value);
    }

    public static Date lt(Date value) {
        return MATCHER_RECORDER.lt(value);
    }

    public static Datetime lt(Datetime value) {
        return MATCHER_RECORDER.lt(value);
    }

    public static Time lt(Time value) {
        return MATCHER_RECORDER.lt(value);
    }

    public static Id lt(Id value) {
        return MATCHER_RECORDER.lt(value);
    }

    public static String lt(String value) {
        return MATCHER_RECORDER.lt(value);
    }

    public static Integer lte(Integer value) {
        return MATCHER_RECORDER.lte(value);
    }

    public static Long lte(Long value) {
        return MATCHER_RECORDER.lte(value);
    }

    public static Double lte(Double value) {
        return MATCHER_RECORDER.lte(value);
    }

    public static Decimal lte(Decimal value) {
        return MATCHER_RECORDER.lte(value);
    }

    public static Date lte(Date value) {
        return MATCHER_RECORDER.lte(value);
    }

    public static Datetime lte(Datetime value) {
        return MATCHER_RECORDER.lte(value);
    }

    public static Time lte(Time value) {
        return MATCHER_RECORDER.lte(value);
    }

    public static Id lte(Id value) {
        return MATCHER_RECORDER.lte(value);
    }

    public static String lte(String value) {
        return MATCHER_RECORDER.lte(value);
    }

    public static Integer between(Integer min, Integer max) {
        return MATCHER_RECORDER.between(min, true, max, true);
    }

    public static Integer between(Integer min, Integer max, Boolean inclusive) {
        return MATCHER_RECORDER.between(min, inclusive, max, inclusive);
    }

    public static Integer between(Integer min, Boolean minInclusive, Integer max, Boolean maxInclusive) {
        return MATCHER_RECORDER.between(min, minInclusive, max, maxInclusive);
    }

    public static Long between(Long min, Long max) {
        return MATCHER_RECORDER.between(min, true, max, true);
    }

    public static Long between(Long min, Long max, Boolean inclusive) {
        return MATCHER_RECORDER.between(min, inclusive, max, inclusive);
    }

    public static Long between(Long min, Boolean minInclusive, Long max, Boolean maxInclusive) {
        return MATCHER_RECORDER.between(min, minInclusive, max, maxInclusive);
    }

    public static Double between(Double min, Double max) {
        return MATCHER_RECORDER.between(min, true, max, true);
    }

    public static Double between(Double min, Double max, Boolean inclusive) {
        return MATCHER_RECORDER.between(min, inclusive, max, inclusive);
    }

    public static Double between(Double min, Boolean minInclusive, Double max, Boolean maxInclusive) {
        return MATCHER_RECORDER.between(min, minInclusive, max, maxInclusive);
    }

    public static Decimal between(Decimal min, Decimal max) {
        return MATCHER_RECORDER.between(min, true, max, true);
    }

    public static Decimal between(Decimal min, Decimal max, Boolean inclusive) {
        return MATCHER_RECORDER.between(min, inclusive, max, inclusive);
    }

    public static Decimal between(Decimal min, Boolean minInclusive, Decimal max, Boolean maxInclusive) {
        return MATCHER_RECORDER.between(min, minInclusive, max, maxInclusive);
    }

    public static Date between(Date min, Date max) {
        return MATCHER_RECORDER.between(min, true, max, true);
    }

    public static Date between(Date min, Date max, Boolean inclusive) {
        return MATCHER_RECORDER.between(min, inclusive, max, inclusive);
    }

    public static Date between(Date min, Boolean minInclusive, Date max, Boolean maxInclusive) {
        return MATCHER_RECORDER.between(min, minInclusive, max, maxInclusive);
    }

    public static Datetime between(Datetime min, Datetime max) {
        return MATCHER_RECORDER.between(min, true, max, true);
    }

    public static Datetime between(Datetime min, Datetime max, Boolean inclusive) {
        return MATCHER_RECORDER.between(min, inclusive, max, inclusive);
    }

    public static Datetime between(Datetime min, Boolean minInclusive, Datetime max, Boolean maxInclusive) {
        return MATCHER_RECORDER.between(min, minInclusive, max, maxInclusive);
    }

    public static Time between(Time min, Time max) {
        return MATCHER_RECORDER.between(min, true, max, true);
    }

    public static Time between(Time min, Time max, Boolean inclusive) {
        return MATCHER_RECORDER.between(min, inclusive, max, inclusive);
    }

    public static Time between(Time min, Boolean minInclusive, Time max, Boolean maxInclusive) {
        return MATCHER_RECORDER.between(min, minInclusive, max, maxInclusive);
    }

    public static Id between(Id min, Id max) {
        return MATCHER_RECORDER.between(min, true, max, true);
    }

    public static Id between(Id min, Id max, Boolean inclusive) {
        return MATCHER_RECORDER.between(min, inclusive, max, inclusive);
    }

    public static Id between(Id min, Boolean minInclusive, Id max, Boolean maxInclusive) {
        return MATCHER_RECORDER.between(min, minInclusive, max, maxInclusive);
    }

    public static String between(String min, String max) {
        return MATCHER_RECORDER.between(min, true, max, true);
    }

    public static String between(String min, String max, Boolean inclusive) {
        return MATCHER_RECORDER.between(min, inclusive, max, inclusive);
    }

    public static String between(String min, Boolean minInclusive, String max, Boolean maxInclusive) {
        return MATCHER_RECORDER.between(min, minInclusive, max, maxInclusive);
    }

    public static String isBlank() {
        return MATCHER_RECORDER.isBlank();
    }

    public static String isNotBlank() {
        return MATCHER_RECORDER.isNotBlank();
    }

    public static String contains(String value) {
        return MATCHER_RECORDER.contains(value);
    }

    public static String startsWith(String value) {
        return MATCHER_RECORDER.startsWith(value);
    }

    public static String endsWith(String value) {
        return MATCHER_RECORDER.endsWith(value);
    }

    public static String matches(String regexp) {
        return MATCHER_RECORDER.matches(regexp);
    }

    public static SObject sObjectWithId(Id value) {
        return MATCHER_RECORDER.sObjectWithId(value);
    }

    public static SObject sObjectWithName(String value) {
        return MATCHER_RECORDER.sObjectWithName(value);
    }

    public static SObject sObjectWith(SObjectField field, Object value) {
        return MATCHER_RECORDER.sObjectWith(field, value);
    }

    public static SObject sObjectWith(Map<SObjectField, Object> value) {
        return MATCHER_RECORDER.sObjectWith(value);
    }

    public static LIst<SObject> sObjectListWith(SObjectField field, Object value) {
        return MATCHER_RECORDER.sObjectListWith(field, value);
    }

    public static LIst<SObject> sObjectListWith(Map<SObjectField, Object> value) {
        return MATCHER_RECORDER.sObjectListWith(value);
    }

    public static LIst<SObject> sObjectListWith(List<Map<SObjectField, Object>> value) {
        return MATCHER_RECORDER.sObjectListWith(value, false);
    }

    public static LIst<SObject> sObjectListWith(List<Map<SObjectField, Object>> value, Boolean inOrder) {
        return MATCHER_RECORDER.sObjectListWith(value, inOrder);
    }
    // #endregion

    // #region - Combo Matchers
    public static Object allOf(Object arg1, Object arg2) {
        return MATCHER_RECORDER.allOf(arg1, arg2);
    }

    public static Object allOf(Object arg1, Object arg2, Object arg3) {
        return MATCHER_RECORDER.allOf(arg1, arg2, arg3);
    }

    public static Object allOf(Object arg1, Object arg2, Object arg3, Object arg4) {
        return MATCHER_RECORDER.allOf(arg1, arg2, arg3, arg4);
    }

    public static Object allOf(Object arg1, Object arg2, Object arg3, Object arg4, Object arg5) {
        return MATCHER_RECORDER.allOf(arg1, arg2, arg3, arg4, arg5);
    }

    public static Object allOf(List<Object> args) {
        return MATCHER_RECORDER.allOf(args);
    }

    public static Object anyOf(Object arg1, Object arg2) {
        return MATCHER_RECORDER.anyOf(arg1, arg2);
    }

    public static Object anyOf(Object arg1, Object arg2, Object arg3) {
        return MATCHER_RECORDER.anyOf(arg1, arg2, arg3);
    }

    public static Object anyOf(Object arg1, Object arg2, Object arg3, Object arg4) {
        return MATCHER_RECORDER.anyOf(arg1, arg2, arg3, arg4);
    }

    public static Object anyOf(Object arg1, Object arg2, Object arg3, Object arg4, Object arg5) {
        return MATCHER_RECORDER.anyOf(arg1, arg2, arg3, arg4, arg5);
    }

    public static Object anyOf(List<Object> args) {
        return MATCHER_RECORDER.anyOf(args);
    }

    public static Object isNot(Object arg1) {
        return MATCHER_RECORDER.isNot(arg1);
    }

    public static Object noneOf(Object arg1, Object arg2) {
        return MATCHER_RECORDER.noneOf(arg1, arg2);
    }

    public static Object noneOf(Object arg1, Object arg2, Object arg3) {
        return MATCHER_RECORDER.noneOf(arg1, arg2, arg3);
    }

    public static Object noneOf(Object arg1, Object arg2, Object arg3, Object arg4) {
        return MATCHER_RECORDER.noneOf(arg1, arg2, arg3, arg4);
    }

    public static Object noneOf(Object arg1, Object arg2, Object arg3, Object arg4, Object arg5) {
        return MATCHER_RECORDER.noneOf(arg1, arg2, arg3, arg4, arg5);
    }

    public static Object noneOf(List<Object> args) {
        return MATCHER_RECORDER.noneOf(args);
    }
    // #endregion

    // #endregion
    // =========================

}
