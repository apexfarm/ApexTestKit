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

    // =======================
    // #region Mock Interfaces

    public static final Answer RETURNS_DEFAULTS = ATKMock.DEFAULT_ANSWERS;
    public static final Answer RETURNS_SELF = ATKMock.SELF_ANSWERS;
    public static final Answer RETURNS_MOCKS = ATKMock.MOCK_ANSWERS;

    public static void startStubbing() {
        ATKMock.progress.startStubbing();
    }

    public static void stopStubbing() {
        ATKMock.progress.stopStubbing();
    }

    public static GlobalSettings mock() {
        return ATKMock.progress.settings;
    }

    public static Object mock(Type mockType) {
        return ATKMock.progress.createMock(mockType);
    }

    public static Object mock(Type mockType, Answer defaultAnswer) {
        return ATKMock.progress.createMock(mockType, defaultAnswer);
    }

    public static Object mock(Type mockType, MockSettings settings) {
        return ATKMock.progress.createMock(mockType, settings);
    }

    public static MockSettings withSettings() {
        return new ATKMock.MockSettings();
    }

    public static Lenient lenient() {
        return ATKMock.progress.createLenientStub();
    }

    public static Given given(Object value) {
        return ATKMock.progress.createGivenStub();
    }

    public static Will willReturn(Object value) {
        return ATKMock.progress.createWillStub().willReturn(value);
    }

    public static Will willAnswer(Answer answer) {
        return ATKMock.progress.createWillStub().willAnswer(answer);
    }

    public static Will willThrow(Exception exp) {
        return ATKMock.progress.createWillStub().willThrow(exp);
    }

    public static Will willDoNothing() {
        return ATKMock.progress.createWillStub().willDoNothing();
    }

    public static ThenOf then(Object mock) {
        return ATKMock.progress.createThenStub(mock);
    }

    public static InOrder inOrder(List<Object> mocks) {
        return ATKMock.progress.createInOrder(mocks);
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

    public interface MockSettings {
        MockSettings name(String name);
        MockSettings defaultAnswer(Answer answer);
        MockSettings stubOnly();
        MockSettings lenient();
        MockSettings lenientVoid();
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
        public Object mock { get; set; }
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

    // #endregion
    // =======================

    // =========================
    // #region Argument Matchers

    // #region - Type Matchers
    public static Integer anyInteger() {
        return ATKMock.progress.matcherRecorder.anyInteger();
    }

    public static Long anyLong() {
        return ATKMock.progress.matcherRecorder.anyLong();
    }

    public static Double anyDouble() {
        return ATKMock.progress.matcherRecorder.anyDouble();
    }

    public static Decimal anyDecimal() {
        return ATKMock.progress.matcherRecorder.anyDecimal();
    }

    public static Date anyDate() {
        return ATKMock.progress.matcherRecorder.anyDate();
    }

    public static Datetime anyDatetime() {
        return ATKMock.progress.matcherRecorder.anyDatetime();
    }

    public static Time anyTime() {
        return ATKMock.progress.matcherRecorder.anyTime();
    }

    public static Id anyId() {
        return ATKMock.progress.matcherRecorder.anyId();
    }

    public static String anyString() {
        return ATKMock.progress.matcherRecorder.anyString();
    }

    public static Boolean anyBoolean() {
        return ATKMock.progress.matcherRecorder.anyBoolean();
    }

    public static List<Object> anyList() {
        return ATKMock.progress.matcherRecorder.anyList();
    }

    public static Object anySet() {
        return ATKMock.progress.matcherRecorder.anySet();
    }

    public static Object anyMap() {
        return ATKMock.progress.matcherRecorder.anyMap();
    }

    public static Object any() {
        return ATKMock.progress.matcherRecorder.any();
    }

    public static Object any(Type type) {
        return ATKMock.progress.matcherRecorder.any(type);
    }

    public static Object nullable(Type type) {
        return ATKMock.progress.matcherRecorder.nullable(type);
    }

    public static SObject anySObject() {
        return ATKMock.progress.matcherRecorder.anySObject();
    }

    public static List<SObject> anySObjectList() {
        return ATKMock.progress.matcherRecorder.anySObjectList();
    }
    // #endregion

    // #region - Value Matchers
    public static Object isNull() {
        return ATKMock.progress.matcherRecorder.isNull();
    }

    public static Object isNotNull() {
        return ATKMock.progress.matcherRecorder.isNotNull();
    }

    public static Object same(Object value) {
        return ATKMock.progress.matcherRecorder.same(value);
    }

    public static Object ne(Object value) {
        return ATKMock.progress.matcherRecorder.ne(value);
    }

    public static Integer neInteger(Integer value) {
        return ATKMock.progress.matcherRecorder.neInteger(value);
    }

    public static Long neLong(Long value) {
        return ATKMock.progress.matcherRecorder.neLong(value);
    }

    public static Double neDouble(Double value) {
        return ATKMock.progress.matcherRecorder.neDouble(value);
    }

    public static Decimal neDecimal(Decimal value) {
        return ATKMock.progress.matcherRecorder.neDecimal(value);
    }

    public static Date neDate(Date value) {
        return ATKMock.progress.matcherRecorder.neDate(value);
    }

    public static Datetime neDatetime(Datetime value) {
        return ATKMock.progress.matcherRecorder.neDatetime(value);
    }

    public static Time neTime(Time value) {
        return ATKMock.progress.matcherRecorder.neTime(value);
    }

    public static Id neId(Id value) {
        return ATKMock.progress.matcherRecorder.neId(value);
    }

    public static String neString(String value) {
        return ATKMock.progress.matcherRecorder.neString(value);
    }

    public static Boolean neBoolean(Boolean value) {
        return ATKMock.progress.matcherRecorder.neBoolean(value);
    }

    public static Object eq(Object value) {
        return ATKMock.progress.matcherRecorder.eq(value);
    }

    public static Integer eqInteger(Integer value) {
        return ATKMock.progress.matcherRecorder.eqInteger(value);
    }

    public static Long eqLong(Long value) {
        return ATKMock.progress.matcherRecorder.eqLong(value);
    }

    public static Double eqDouble(Double value) {
        return ATKMock.progress.matcherRecorder.eqDouble(value);
    }

    public static Decimal eqDecimal(Decimal value) {
        return ATKMock.progress.matcherRecorder.eqDecimal(value);
    }

    public static Date eqDate(Date value) {
        return ATKMock.progress.matcherRecorder.eqDate(value);
    }

    public static Datetime eqDatetime(Datetime value) {
        return ATKMock.progress.matcherRecorder.eqDatetime(value);
    }

    public static Time eqTime(Time value) {
        return ATKMock.progress.matcherRecorder.eqTime(value);
    }

    public static Id eqId(Id value) {
        return ATKMock.progress.matcherRecorder.eqId(value);
    }

    public static String eqString(String value) {
        return ATKMock.progress.matcherRecorder.eqString(value);
    }

    public static Boolean eqBoolean(Boolean value) {
        return ATKMock.progress.matcherRecorder.eqBoolean(value);
    }

    public static Integer gt(Integer value) {
        return ATKMock.progress.matcherRecorder.gt(value);
    }

    public static Long gt(Long value) {
        return ATKMock.progress.matcherRecorder.gt(value);
    }

    public static Double gt(Double value) {
        return ATKMock.progress.matcherRecorder.gt(value);
    }

    public static Decimal gt(Decimal value) {
        return ATKMock.progress.matcherRecorder.gt(value);
    }

    public static Date gt(Date value) {
        return ATKMock.progress.matcherRecorder.gt(value);
    }

    public static Datetime gt(Datetime value) {
        return ATKMock.progress.matcherRecorder.gt(value);
    }

    public static Time gt(Time value) {
        return ATKMock.progress.matcherRecorder.gt(value);
    }

    public static Id gt(Id value) {
        return ATKMock.progress.matcherRecorder.gt(value);
    }

    public static String gt(String value) {
        return ATKMock.progress.matcherRecorder.gt(value);
    }

    public static Integer gte(Integer value) {
        return ATKMock.progress.matcherRecorder.gte(value);
    }

    public static Long gte(Long value) {
        return ATKMock.progress.matcherRecorder.gte(value);
    }

    public static Double gte(Double value) {
        return ATKMock.progress.matcherRecorder.gte(value);
    }

    public static Decimal gte(Decimal value) {
        return ATKMock.progress.matcherRecorder.gte(value);
    }

    public static Date gte(Date value) {
        return ATKMock.progress.matcherRecorder.gte(value);
    }

    public static Datetime gte(Datetime value) {
        return ATKMock.progress.matcherRecorder.gte(value);
    }

    public static Time gte(Time value) {
        return ATKMock.progress.matcherRecorder.gte(value);
    }

    public static Id gte(Id value) {
        return ATKMock.progress.matcherRecorder.gte(value);
    }

    public static String gte(String value) {
        return ATKMock.progress.matcherRecorder.gte(value);
    }

    public static Integer lt(Integer value) {
        return ATKMock.progress.matcherRecorder.lt(value);
    }

    public static Long lt(Long value) {
        return ATKMock.progress.matcherRecorder.lt(value);
    }

    public static Double lt(Double value) {
        return ATKMock.progress.matcherRecorder.lt(value);
    }

    public static Decimal lt(Decimal value) {
        return ATKMock.progress.matcherRecorder.lt(value);
    }

    public static Date lt(Date value) {
        return ATKMock.progress.matcherRecorder.lt(value);
    }

    public static Datetime lt(Datetime value) {
        return ATKMock.progress.matcherRecorder.lt(value);
    }

    public static Time lt(Time value) {
        return ATKMock.progress.matcherRecorder.lt(value);
    }

    public static Id lt(Id value) {
        return ATKMock.progress.matcherRecorder.lt(value);
    }

    public static String lt(String value) {
        return ATKMock.progress.matcherRecorder.lt(value);
    }

    public static Integer lte(Integer value) {
        return ATKMock.progress.matcherRecorder.lte(value);
    }

    public static Long lte(Long value) {
        return ATKMock.progress.matcherRecorder.lte(value);
    }

    public static Double lte(Double value) {
        return ATKMock.progress.matcherRecorder.lte(value);
    }

    public static Decimal lte(Decimal value) {
        return ATKMock.progress.matcherRecorder.lte(value);
    }

    public static Date lte(Date value) {
        return ATKMock.progress.matcherRecorder.lte(value);
    }

    public static Datetime lte(Datetime value) {
        return ATKMock.progress.matcherRecorder.lte(value);
    }

    public static Time lte(Time value) {
        return ATKMock.progress.matcherRecorder.lte(value);
    }

    public static Id lte(Id value) {
        return ATKMock.progress.matcherRecorder.lte(value);
    }

    public static String lte(String value) {
        return ATKMock.progress.matcherRecorder.lte(value);
    }

    public static Integer between(Integer min, Integer max) {
        return ATKMock.progress.matcherRecorder.between(min, true, max, true);
    }

    public static Integer between(Integer min, Integer max, Boolean inclusive) {
        return ATKMock.progress.matcherRecorder.between(min, inclusive, max, inclusive);
    }

    public static Integer between(Integer min, Boolean minInclusive, Integer max, Boolean maxInclusive) {
        return ATKMock.progress.matcherRecorder.between(min, minInclusive, max, maxInclusive);
    }

    public static Long between(Long min, Long max) {
        return ATKMock.progress.matcherRecorder.between(min, true, max, true);
    }

    public static Long between(Long min, Long max, Boolean inclusive) {
        return ATKMock.progress.matcherRecorder.between(min, inclusive, max, inclusive);
    }

    public static Long between(Long min, Boolean minInclusive, Long max, Boolean maxInclusive) {
        return ATKMock.progress.matcherRecorder.between(min, minInclusive, max, maxInclusive);
    }

    public static Double between(Double min, Double max) {
        return ATKMock.progress.matcherRecorder.between(min, true, max, true);
    }

    public static Double between(Double min, Double max, Boolean inclusive) {
        return ATKMock.progress.matcherRecorder.between(min, inclusive, max, inclusive);
    }

    public static Double between(Double min, Boolean minInclusive, Double max, Boolean maxInclusive) {
        return ATKMock.progress.matcherRecorder.between(min, minInclusive, max, maxInclusive);
    }

    public static Decimal between(Decimal min, Decimal max) {
        return ATKMock.progress.matcherRecorder.between(min, true, max, true);
    }

    public static Decimal between(Decimal min, Decimal max, Boolean inclusive) {
        return ATKMock.progress.matcherRecorder.between(min, inclusive, max, inclusive);
    }

    public static Decimal between(Decimal min, Boolean minInclusive, Decimal max, Boolean maxInclusive) {
        return ATKMock.progress.matcherRecorder.between(min, minInclusive, max, maxInclusive);
    }

    public static Date between(Date min, Date max) {
        return ATKMock.progress.matcherRecorder.between(min, true, max, true);
    }

    public static Date between(Date min, Date max, Boolean inclusive) {
        return ATKMock.progress.matcherRecorder.between(min, inclusive, max, inclusive);
    }

    public static Date between(Date min, Boolean minInclusive, Date max, Boolean maxInclusive) {
        return ATKMock.progress.matcherRecorder.between(min, minInclusive, max, maxInclusive);
    }

    public static Datetime between(Datetime min, Datetime max) {
        return ATKMock.progress.matcherRecorder.between(min, true, max, true);
    }

    public static Datetime between(Datetime min, Datetime max, Boolean inclusive) {
        return ATKMock.progress.matcherRecorder.between(min, inclusive, max, inclusive);
    }

    public static Datetime between(Datetime min, Boolean minInclusive, Datetime max, Boolean maxInclusive) {
        return ATKMock.progress.matcherRecorder.between(min, minInclusive, max, maxInclusive);
    }

    public static Time between(Time min, Time max) {
        return ATKMock.progress.matcherRecorder.between(min, true, max, true);
    }

    public static Time between(Time min, Time max, Boolean inclusive) {
        return ATKMock.progress.matcherRecorder.between(min, inclusive, max, inclusive);
    }

    public static Time between(Time min, Boolean minInclusive, Time max, Boolean maxInclusive) {
        return ATKMock.progress.matcherRecorder.between(min, minInclusive, max, maxInclusive);
    }

    public static Id between(Id min, Id max) {
        return ATKMock.progress.matcherRecorder.between(min, true, max, true);
    }

    public static Id between(Id min, Id max, Boolean inclusive) {
        return ATKMock.progress.matcherRecorder.between(min, inclusive, max, inclusive);
    }

    public static Id between(Id min, Boolean minInclusive, Id max, Boolean maxInclusive) {
        return ATKMock.progress.matcherRecorder.between(min, minInclusive, max, maxInclusive);
    }

    public static String between(String min, String max) {
        return ATKMock.progress.matcherRecorder.between(min, true, max, true);
    }

    public static String between(String min, String max, Boolean inclusive) {
        return ATKMock.progress.matcherRecorder.between(min, inclusive, max, inclusive);
    }

    public static String between(String min, Boolean minInclusive, String max, Boolean maxInclusive) {
        return ATKMock.progress.matcherRecorder.between(min, minInclusive, max, maxInclusive);
    }

    public static String isBlank() {
        return ATKMock.progress.matcherRecorder.isBlank();
    }

    public static String isNotBlank() {
        return ATKMock.progress.matcherRecorder.isNotBlank();
    }

    public static String contains(String value) {
        return ATKMock.progress.matcherRecorder.contains(value);
    }

    public static String startsWith(String value) {
        return ATKMock.progress.matcherRecorder.startsWith(value);
    }

    public static String endsWith(String value) {
        return ATKMock.progress.matcherRecorder.endsWith(value);
    }

    public static String matches(String regexp) {
        return ATKMock.progress.matcherRecorder.matches(regexp);
    }

    public static SObject sObjectWithId(Id value) {
        return ATKMock.progress.matcherRecorder.sObjectWithId(value);
    }

    public static SObject sObjectWithName(String value) {
        return ATKMock.progress.matcherRecorder.sObjectWithName(value);
    }

    public static SObject sObjectWith(SObjectField field, Object value) {
        return ATKMock.progress.matcherRecorder.sObjectWith(field, value);
    }

    public static SObject sObjectWith(Map<SObjectField, Object> value) {
        return ATKMock.progress.matcherRecorder.sObjectWith(value);
    }

    public static LIst<SObject> sObjectListWith(SObjectField field, Object value) {
        return ATKMock.progress.matcherRecorder.sObjectListWith(field, value);
    }

    public static LIst<SObject> sObjectListWith(Map<SObjectField, Object> value) {
        return ATKMock.progress.matcherRecorder.sObjectListWith(value);
    }

    public static LIst<SObject> sObjectListWith(List<Map<SObjectField, Object>> value) {
        return ATKMock.progress.matcherRecorder.sObjectListWith(value, false);
    }

    public static LIst<SObject> sObjectListWith(List<Map<SObjectField, Object>> value, Boolean inOrder) {
        return ATKMock.progress.matcherRecorder.sObjectListWith(value, inOrder);
    }
    // #endregion

    // #region - Combo Matchers
    public static Object allOf(Object arg1, Object arg2) {
        return ATKMock.progress.matcherRecorder.allOf(arg1, arg2);
    }

    public static Object allOf(Object arg1, Object arg2, Object arg3) {
        return ATKMock.progress.matcherRecorder.allOf(arg1, arg2, arg3);
    }

    public static Object allOf(Object arg1, Object arg2, Object arg3, Object arg4) {
        return ATKMock.progress.matcherRecorder.allOf(arg1, arg2, arg3, arg4);
    }

    public static Object allOf(Object arg1, Object arg2, Object arg3, Object arg4, Object arg5) {
        return ATKMock.progress.matcherRecorder.allOf(arg1, arg2, arg3, arg4, arg5);
    }

    public static Object allOf(List<Object> args) {
        return ATKMock.progress.matcherRecorder.allOf(args);
    }

    public static Object anyOf(Object arg1, Object arg2) {
        return ATKMock.progress.matcherRecorder.anyOf(arg1, arg2);
    }

    public static Object anyOf(Object arg1, Object arg2, Object arg3) {
        return ATKMock.progress.matcherRecorder.anyOf(arg1, arg2, arg3);
    }

    public static Object anyOf(Object arg1, Object arg2, Object arg3, Object arg4) {
        return ATKMock.progress.matcherRecorder.anyOf(arg1, arg2, arg3, arg4);
    }

    public static Object anyOf(Object arg1, Object arg2, Object arg3, Object arg4, Object arg5) {
        return ATKMock.progress.matcherRecorder.anyOf(arg1, arg2, arg3, arg4, arg5);
    }

    public static Object anyOf(List<Object> args) {
        return ATKMock.progress.matcherRecorder.anyOf(args);
    }

    public static Object isNot(Object arg1) {
        return ATKMock.progress.matcherRecorder.isNot(arg1);
    }

    public static Object noneOf(Object arg1, Object arg2) {
        return ATKMock.progress.matcherRecorder.noneOf(arg1, arg2);
    }

    public static Object noneOf(Object arg1, Object arg2, Object arg3) {
        return ATKMock.progress.matcherRecorder.noneOf(arg1, arg2, arg3);
    }

    public static Object noneOf(Object arg1, Object arg2, Object arg3, Object arg4) {
        return ATKMock.progress.matcherRecorder.noneOf(arg1, arg2, arg3, arg4);
    }

    public static Object noneOf(Object arg1, Object arg2, Object arg3, Object arg4, Object arg5) {
        return ATKMock.progress.matcherRecorder.noneOf(arg1, arg2, arg3, arg4, arg5);
    }

    public static Object noneOf(List<Object> args) {
        return ATKMock.progress.matcherRecorder.noneOf(args);
    }
    // #endregion

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
    // =========================

    // =========================
    // #region Entity Interfaces

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
    // =========================
}
