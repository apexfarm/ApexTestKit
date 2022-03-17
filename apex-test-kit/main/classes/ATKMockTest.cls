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

@IsTest
public with sharing class ATKMockTest {
    @IsTest
    static void test_matchers_for_types() {
        ATKMockTest mock = (ATKMockTest) ATK.mock(ATKMockTest.class);
        ATK.startStubbing();
        ATK.given(mock.doWithInteger(ATK.anyInteger())).willReturn('0');
        ATK.given(mock.doWithIntegers(ATK.anyInteger(), ATK.anyInteger(), ATK.anyInteger())).willReturn('0');
        ATK.given(mock.doWithLong(ATK.anyLong())).willReturn('0');
        ATK.given(mock.doWithLongs(ATK.anyLong(), ATK.anyLong(), ATK.anyLong())).willReturn('0');
        ATK.given(mock.doWithDouble(ATK.anyDouble())).willReturn('0');
        ATK.given(mock.doWithDoubles(ATK.anyDouble(), ATK.anyDouble(), ATK.anyDouble())).willReturn('0');
        ATK.given(mock.doWithDecimal(ATK.anyDecimal())).willReturn('0');
        ATK.given(mock.doWithDecimals(ATK.anyDecimal(), ATK.anyDecimal(), ATK.anyDecimal())).willReturn('0');
        ATK.given(mock.doWithDate(ATK.anyDate())).willReturn('0');
        ATK.given(mock.doWithDates(ATK.anyDate(), ATK.anyDate(), ATK.anyDate())).willReturn('0');
        ATK.given(mock.doWithDatetime(ATK.anyDatetime())).willReturn('0');
        ATK.given(mock.doWithDatetimes(ATK.anyDatetime(), ATK.anyDatetime(), ATK.anyDatetime())).willReturn('0');
        ATK.given(mock.doWithId(ATK.anyId())).willReturn('0');
        ATK.given(mock.doWithIds(ATK.anyId(), ATK.anyId(), ATK.anyId())).willReturn('0');
        ATK.given(mock.doWithString(ATK.anyString())).willReturn('0');
        ATK.given(mock.doWithStrings(ATK.anyString(), ATK.anyString(), ATK.anyString())).willReturn('0');
        ATK.given(mock.doWithBoolean(ATK.anyBoolean())).willReturn('0');
        ATK.given(mock.doWithBooleans(ATK.anyBoolean(), ATK.anyBoolean(), ATK.anyBoolean())).willReturn('0');
        ATK.given(mock.doWithObject(ATK.anyObject())).willReturn('0');
        ATK.given(mock.doWithObjects(ATK.anyObject(), ATK.anyObject(), ATK.anyObject())).willReturn('0');
        ATK.given(mock.doWithList((List<String>) ATK.anyList())).willReturn('0');
        ATK.given(mock.doWithLists((List<String>) ATK.anyList(), (List<Integer>) ATK.anyList(), ATK.anyList())).willReturn('0');
        ATK.given(mock.doWithSet((Set<String>) ATK.anySet())).willReturn('0');
        ATK.given(mock.doWithSets((Set<String>) ATK.anySet(), (Set<Object>) ATK.anySet(), (Set<Object>) ATK.anySet())).willReturn('0');
        ATK.given(mock.doWithMap((Map<String, Object>) ATK.anyMap())).willReturn('0');
        ATK.given(mock.doWithMaps((Map<String, Object>) ATK.anyMap(), (Map<Object, Object>) ATK.anyMap(), (Map<Object, Object>) ATK.anyMap())).willReturn('0');
        ATK.stopStubbing();

        System.assertEquals('0', mock.doWithInteger(1));
        System.assertEquals('0', mock.doWithIntegers(1, 2, 3));
        System.assertEquals('0', mock.doWithLong(1));
        System.assertEquals('0', mock.doWithLongs(1, 2, 3));
        System.assertEquals('0', mock.doWithDouble(1.1d));
        System.assertEquals('0', mock.doWithDoubles(1.1d, 2.2d, 3.3d));
        System.assertEquals('0', mock.doWithDecimal(1.1));
        System.assertEquals('0', mock.doWithDecimals(1.1, 2.2, 3.3));
        System.assertEquals('0', mock.doWithDate(Date.newInstance(2022, 1, 1)));
        System.assertEquals('0', mock.doWithDates(Date.newInstance(2022, 1, 1), Date.newInstance(2022, 1, 2), Date.newInstance(2022, 1, 3)));
        System.assertEquals('0', mock.doWithDatetime(Datetime.newInstance(2022, 1, 1)));
        System.assertEquals('0', mock.doWithDatetimes(Datetime.newInstance(2022, 1, 1), Datetime.newInstance(2022, 1, 2), Datetime.newInstance(2022, 1, 3)));
        System.assertEquals('0', mock.doWithId(ATK.fakeId(Account.SObjectType)));
        System.assertEquals('0', mock.doWithIds(ATK.fakeId(Account.SObjectType), ATK.fakeId(Account.SObjectType), ATK.fakeId(Account.SObjectType)));
        System.assertEquals('0', mock.doWithString('1'));
        System.assertEquals('0', mock.doWithStrings('1', '2', '3'));
        System.assertEquals('0', mock.doWithBoolean(true));
        System.assertEquals('0', mock.doWithBooleans(false, true, false));
        System.assertEquals('0', mock.doWithObject(1));
        System.assertEquals('0', mock.doWithObjects(1, 2, 3));
        System.assertEquals('0', mock.doWithList(new List<String>()));
        System.assertEquals('0', mock.doWithLists(new List<String>(), new List<Integer>(), new List<Object>()));
        System.assertEquals('0', mock.doWithSet(new Set<String>()));
        System.assertEquals('0', mock.doWithSets(new Set<String>(), new Set<Object>(), new Set<Object>()));
        System.assertEquals('0', mock.doWithMap(new Map<String, Object>()));
        System.assertEquals('0', mock.doWithMaps(new Map<String, Object>(), new Map<Object, Object>(), new Map<Object, Object>()));
    }

    @IsTest
    static void test_matchers_for_value_of_integer() {
        ATKMockTest mock = (ATKMockTest) ATK.mock(ATKMockTest.class);
        ATK.startStubbing();
        ATK.given(mock.doWithInteger(ATK.lt(3).asInteger())).willReturn('<3');
        ATK.given(mock.doWithInteger(ATK.lte(1).asInteger())).willReturn('<=1');
        ATK.given(mock.doWithInteger(ATK.eq(3).asInteger())).willReturn('=3');
        ATK.given(mock.doWithInteger(ATK.gt(3).asInteger())).willReturn('>3');
        ATK.given(mock.doWithInteger(ATK.gte(5).asInteger())).willReturn('>=5');
        ATK.given(mock.doWithInteger(ATK.between(7, true, 11, false).asInteger())).willReturn('7-10');
        ATK.given(mock.doWithInteger(ATK.between(7, false, 11, true).asInteger())).willReturn('8-11');
        ATK.given(mock.doWithInteger(ATK.between(8, 10, true).asInteger())).willReturn('8-10');
        ATK.given(mock.doWithInteger(ATK.between(8, 10).asInteger())).willReturn('9');
        ATK.stopStubbing();

        System.assertEquals('<=1', mock.doWithInteger(0));
        System.assertEquals('<=1', mock.doWithInteger(1));
        System.assertEquals('<3', mock.doWithInteger(2));
        System.assertEquals('=3', mock.doWithInteger(3));
        System.assertEquals('>3', mock.doWithInteger(4));
        System.assertEquals('>=5', mock.doWithInteger(5));
        System.assertEquals('>=5', mock.doWithInteger(6));
        System.assertEquals('7-10', mock.doWithInteger(7));
        System.assertEquals('8-10', mock.doWithInteger(8));
        System.assertEquals('9', mock.doWithInteger(9));
        System.assertEquals('8-10', mock.doWithInteger(10));
        System.assertEquals('8-11', mock.doWithInteger(11));
    }

    @IsTest
    static void test_matchers_for_value_of_long() {
        ATKMockTest mock = (ATKMockTest) ATK.mock(ATKMockTest.class);
        ATK.startStubbing();
        ATK.given(mock.doWithLong(ATK.lt(3).asLong())).willReturn('<3');
        ATK.given(mock.doWithLong(ATK.lte(1).asLong())).willReturn('<=1');
        ATK.given(mock.doWithLong(ATK.eq(3).asLong())).willReturn('=3');
        ATK.given(mock.doWithLong(ATK.gt(3).asLong())).willReturn('>3');
        ATK.given(mock.doWithLong(ATK.gte(5).asLong())).willReturn('>=5');
        ATK.given(mock.doWithLong(ATK.between(7, true, 11, false).asLong())).willReturn('7-10');
        ATK.given(mock.doWithLong(ATK.between(7, false, 11, true).asLong())).willReturn('8-11');
        ATK.given(mock.doWithLong(ATK.between(8, 10, true).asLong())).willReturn('8-10');
        ATK.given(mock.doWithLong(ATK.between(8, 10).asLong())).willReturn('9');
        ATK.stopStubbing();

        System.assertEquals('<=1', mock.doWithLong(0));
        System.assertEquals('<=1', mock.doWithLong(1));
        System.assertEquals('<3', mock.doWithLong(2));
        System.assertEquals('=3', mock.doWithLong(3));
        System.assertEquals('>3', mock.doWithLong(4));
        System.assertEquals('>=5', mock.doWithLong(5));
        System.assertEquals('>=5', mock.doWithLong(6));
        System.assertEquals('7-10', mock.doWithLong(7));
        System.assertEquals('8-10', mock.doWithLong(8));
        System.assertEquals('9', mock.doWithLong(9));
        System.assertEquals('8-10', mock.doWithLong(10));
        System.assertEquals('8-11', mock.doWithLong(11));
    }

    @IsTest
    static void test_matchers_for_value_of_double() {
        ATKMockTest mock = (ATKMockTest) ATK.mock(ATKMockTest.class);
        ATK.startStubbing();
        ATK.given(mock.doWithDouble(ATK.lt(3.0d).asDouble())).willReturn('<3');
        ATK.given(mock.doWithDouble(ATK.lte(1.0d).asDouble())).willReturn('<=1');
        ATK.given(mock.doWithDouble(ATK.eq(3.0d).asDouble())).willReturn('=3');
        ATK.given(mock.doWithDouble(ATK.gt(3.0d).asDouble())).willReturn('>3');
        ATK.given(mock.doWithDouble(ATK.gte(5.0d).asDouble())).willReturn('>=5');
        ATK.given(mock.doWithDouble(ATK.between(7.0d, true, 11.0d, false).asDouble())).willReturn('7-10');
        ATK.given(mock.doWithDouble(ATK.between(7.0d, false, 11.0d, true).asDouble())).willReturn('8-11');
        ATK.given(mock.doWithDouble(ATK.between(8.0d, 10.0d, true).asDouble())).willReturn('8-10');
        ATK.given(mock.doWithDouble(ATK.between(8.0d, 10.0d).asDouble())).willReturn('9');
        ATK.stopStubbing();

        System.assertEquals('<=1', mock.doWithDouble(0.0d));
        System.assertEquals('<=1', mock.doWithDouble(1.0d));
        System.assertEquals('<3', mock.doWithDouble(2.0d));
        System.assertEquals('=3', mock.doWithDouble(3.0d));
        System.assertEquals('>3', mock.doWithDouble(4.0d));
        System.assertEquals('>=5', mock.doWithDouble(5.0d));
        System.assertEquals('>=5', mock.doWithDouble(6.0d));
        System.assertEquals('7-10', mock.doWithDouble(7.0d));
        System.assertEquals('8-10', mock.doWithDouble(8.0d));
        System.assertEquals('9', mock.doWithDouble(9.0d));
        System.assertEquals('8-10', mock.doWithDouble(10.0d));
        System.assertEquals('8-11', mock.doWithDouble(11.0d));
    }

    @IsTest
    static void test_matchers_for_value_of_decimal() {
        ATKMockTest mock = (ATKMockTest) ATK.mock(ATKMockTest.class);
        ATK.startStubbing();
        ATK.given(mock.doWithDecimal(ATK.lt(3.0).asDecimal())).willReturn('<3');
        ATK.given(mock.doWithDecimal(ATK.lte(1.0).asDecimal())).willReturn('<=1');
        ATK.given(mock.doWithDecimal(ATK.eq(3.0).asDecimal())).willReturn('=3');
        ATK.given(mock.doWithDecimal(ATK.gt(3.0).asDecimal())).willReturn('>3');
        ATK.given(mock.doWithDecimal(ATK.gte(5.0).asDecimal())).willReturn('>=5');
        ATK.given(mock.doWithDecimal(ATK.between(7.0, true, 11.0, false).asDecimal())).willReturn('7-10');
        ATK.given(mock.doWithDecimal(ATK.between(7.0, false, 11.0, true).asDecimal())).willReturn('8-11');
        ATK.given(mock.doWithDecimal(ATK.between(8.0, 10.0, true).asDecimal())).willReturn('8-10');
        ATK.given(mock.doWithDecimal(ATK.between(8.0, 10.0).asDecimal())).willReturn('9');
        ATK.stopStubbing();

        System.assertEquals('<=1', mock.doWithDecimal(0.0));
        System.assertEquals('<=1', mock.doWithDecimal(1.0));
        System.assertEquals('<3', mock.doWithDecimal(2.0));
        System.assertEquals('=3', mock.doWithDecimal(3.0));
        System.assertEquals('>3', mock.doWithDecimal(4.0));
        System.assertEquals('>=5', mock.doWithDecimal(5.0));
        System.assertEquals('>=5', mock.doWithDecimal(6.0));
        System.assertEquals('7-10', mock.doWithDecimal(7.0));
        System.assertEquals('8-10', mock.doWithDecimal(8.0));
        System.assertEquals('9', mock.doWithDecimal(9.0));
        System.assertEquals('8-10', mock.doWithDecimal(10.0));
        System.assertEquals('8-11', mock.doWithDecimal(11.0));
    }

    @IsTest
    static void test_matchers_for_value_of_date() {
        ATKMockTest mock = (ATKMockTest) ATK.mock(ATKMockTest.class);
        ATK.startStubbing();
        ATK.given(mock.doWithDate(ATK.lt(Date.newInstance(2022, 1, 3)).asDate())).willReturn('<3');
        ATK.given(mock.doWithDate(ATK.lte(Date.newInstance(2022, 1, 1)).asDate())).willReturn('<=1');
        ATK.given(mock.doWithDate(ATK.eq(Date.newInstance(2022, 1, 3)).asDate())).willReturn('=3');
        ATK.given(mock.doWithDate(ATK.gt(Date.newInstance(2022, 1, 3)).asDate())).willReturn('>3');
        ATK.given(mock.doWithDate(ATK.gte(Date.newInstance(2022, 1, 5)).asDate())).willReturn('>=5');
        ATK.given(mock.doWithDate(ATK.between(Date.newInstance(2022, 1, 7), true, Date.newInstance(2022, 1, 11), false).asDate())).willReturn('7-10');
        ATK.given(mock.doWithDate(ATK.between(Date.newInstance(2022, 1, 7), false, Date.newInstance(2022, 1, 11), true).asDate())).willReturn('8-11');
        ATK.given(mock.doWithDate(ATK.between(Date.newInstance(2022, 1, 8), Date.newInstance(2022, 1, 10), true).asDate())).willReturn('8-10');
        ATK.given(mock.doWithDate(ATK.between(Date.newInstance(2022, 1, 8), Date.newInstance(2022, 1, 10)).asDate())).willReturn('9');
        ATK.stopStubbing();

        System.assertEquals('<=1', mock.doWithDate(Date.newInstance(2021, 12, 31)));
        System.assertEquals('<=1', mock.doWithDate(Date.newInstance(2022, 1, 1)));
        System.assertEquals('<3', mock.doWithDate(Date.newInstance(2022, 1, 2)));
        System.assertEquals('=3', mock.doWithDate(Date.newInstance(2022, 1, 3)));
        System.assertEquals('>3', mock.doWithDate(Date.newInstance(2022, 1, 4)));
        System.assertEquals('>=5', mock.doWithDate(Date.newInstance(2022, 1, 5)));
        System.assertEquals('>=5', mock.doWithDate(Date.newInstance(2022, 1, 6)));
        System.assertEquals('7-10', mock.doWithDate(Date.newInstance(2022, 1, 7)));
        System.assertEquals('8-10', mock.doWithDate(Date.newInstance(2022, 1, 8)));
        System.assertEquals('9', mock.doWithDate(Date.newInstance(2022, 1, 9)));
        System.assertEquals('8-10', mock.doWithDate(Date.newInstance(2022, 1, 10)));
        System.assertEquals('8-11', mock.doWithDate(Date.newInstance(2022, 1, 11)));
    }

    @IsTest
    static void test_matchers_for_value_of_datetime() {
        ATKMockTest mock = (ATKMockTest) ATK.mock(ATKMockTest.class);
        ATK.startStubbing();
        ATK.given(mock.doWithDatetime(ATK.lt(Datetime.newInstance(2022, 1, 3)).asDatetime())).willReturn('<3');
        ATK.given(mock.doWithDatetime(ATK.lte(Datetime.newInstance(2022, 1, 1)).asDatetime())).willReturn('<=1');
        ATK.given(mock.doWithDatetime(ATK.eq(Datetime.newInstance(2022, 1, 3)).asDatetime())).willReturn('=3');
        ATK.given(mock.doWithDatetime(ATK.gt(Datetime.newInstance(2022, 1, 3)).asDatetime())).willReturn('>3');
        ATK.given(mock.doWithDatetime(ATK.gte(Datetime.newInstance(2022, 1, 5)).asDatetime())).willReturn('>=5');
        ATK.given(mock.doWithDatetime(ATK.between(Datetime.newInstance(2022, 1, 7), true, Datetime.newInstance(2022, 1, 11), false).asDatetime())).willReturn('7-10');
        ATK.given(mock.doWithDatetime(ATK.between(Datetime.newInstance(2022, 1, 7), false, Datetime.newInstance(2022, 1, 11), true).asDatetime())).willReturn('8-11');
        ATK.given(mock.doWithDatetime(ATK.between(Datetime.newInstance(2022, 1, 8), Datetime.newInstance(2022, 1, 10), true).asDatetime())).willReturn('8-10');
        ATK.given(mock.doWithDatetime(ATK.between(Datetime.newInstance(2022, 1, 8), Datetime.newInstance(2022, 1, 10)).asDatetime())).willReturn('9');
        ATK.stopStubbing();

        System.assertEquals('<=1', mock.doWithDatetime(Datetime.newInstance(2021, 12, 31)));
        System.assertEquals('<=1', mock.doWithDatetime(Datetime.newInstance(2022, 1, 1)));
        System.assertEquals('<3', mock.doWithDatetime(Datetime.newInstance(2022, 1, 2)));
        System.assertEquals('=3', mock.doWithDatetime(Datetime.newInstance(2022, 1, 3)));
        System.assertEquals('>3', mock.doWithDatetime(Datetime.newInstance(2022, 1, 4)));
        System.assertEquals('>=5', mock.doWithDatetime(Datetime.newInstance(2022, 1, 5)));
        System.assertEquals('>=5', mock.doWithDatetime(Datetime.newInstance(2022, 1, 6)));
        System.assertEquals('7-10', mock.doWithDatetime(Datetime.newInstance(2022, 1, 7)));
        System.assertEquals('8-10', mock.doWithDatetime(Datetime.newInstance(2022, 1, 8)));
        System.assertEquals('9', mock.doWithDatetime(Datetime.newInstance(2022, 1, 9)));
        System.assertEquals('8-10', mock.doWithDatetime(Datetime.newInstance(2022, 1, 10)));
        System.assertEquals('8-11', mock.doWithDatetime(Datetime.newInstance(2022, 1, 11)));
    }

    @IsTest
    static void test_matchers_for_value_of_id() {
        ATKMockTest mock = (ATKMockTest) ATK.mock(ATKMockTest.class);
        ATK.startStubbing();
        ATK.given(mock.doWithId(ATK.lt(ATK.fakeId(Account.SObjectType, 3)).asId())).willReturn('<3');
        ATK.given(mock.doWithId(ATK.lte(ATK.fakeId(Account.SObjectType, 1)).asId())).willReturn('<=1');
        ATK.given(mock.doWithId(ATK.eq(ATK.fakeId(Account.SObjectType, 3)).asId())).willReturn('=3');
        ATK.given(mock.doWithId(ATK.gt(ATK.fakeId(Account.SObjectType, 3)).asId())).willReturn('>3');
        ATK.given(mock.doWithId(ATK.gte(ATK.fakeId(Account.SObjectType, 5)).asId())).willReturn('>=5');
        ATK.given(mock.doWithId(ATK.between(ATK.fakeId(Account.SObjectType, 7), true, ATK.fakeId(Account.SObjectType, 11), false).asId())).willReturn('7-10');
        ATK.given(mock.doWithId(ATK.between(ATK.fakeId(Account.SObjectType, 7), false, ATK.fakeId(Account.SObjectType, 11), true).asId())).willReturn('8-11');
        ATK.given(mock.doWithId(ATK.between(ATK.fakeId(Account.SObjectType, 8), ATK.fakeId(Account.SObjectType, 10), true).asId())).willReturn('8-10');
        ATK.given(mock.doWithId(ATK.between(ATK.fakeId(Account.SObjectType, 8), ATK.fakeId(Account.SObjectType, 10)).asId())).willReturn('9');
        ATK.stopStubbing();

        System.assertEquals('<=1', mock.doWithId(ATK.fakeId(Account.SObjectType, 0)));
        System.assertEquals('<=1', mock.doWithId(ATK.fakeId(Account.SObjectType, 1)));
        System.assertEquals('<3', mock.doWithId(ATK.fakeId(Account.SObjectType, 2)));
        System.assertEquals('=3', mock.doWithId(ATK.fakeId(Account.SObjectType, 3)));
        System.assertEquals('>3', mock.doWithId(ATK.fakeId(Account.SObjectType, 4)));
        System.assertEquals('>=5', mock.doWithId(ATK.fakeId(Account.SObjectType, 5)));
        System.assertEquals('>=5', mock.doWithId(ATK.fakeId(Account.SObjectType, 6)));
        System.assertEquals('7-10', mock.doWithId(ATK.fakeId(Account.SObjectType, 7)));
        System.assertEquals('8-10', mock.doWithId(ATK.fakeId(Account.SObjectType, 8)));
        System.assertEquals('9', mock.doWithId(ATK.fakeId(Account.SObjectType, 9)));
        System.assertEquals('8-10', mock.doWithId(ATK.fakeId(Account.SObjectType, 10)));
        System.assertEquals('8-11', mock.doWithId(ATK.fakeId(Account.SObjectType, 11)));
    }

    @IsTest
    static void test_matchers_for_value_of_string() {
        ATKMockTest mock = (ATKMockTest) ATK.mock(ATKMockTest.class);
        ATK.startStubbing();
        ATK.given(mock.doWithString(ATK.lt('03').asString())).willReturn('<03');
        ATK.given(mock.doWithString(ATK.lte('01').asString())).willReturn('<=01');
        ATK.given(mock.doWithString(ATK.eq('03').asString())).willReturn('=03');
        ATK.given(mock.doWithString(ATK.gt('03').asString())).willReturn('>03');
        ATK.given(mock.doWithString(ATK.gte('05').asString())).willReturn('>=05');
        ATK.given(mock.doWithString(ATK.between('07', true, '11', false).asString())).willReturn('07-10');
        ATK.given(mock.doWithString(ATK.between('07', false, '11', true).asString())).willReturn('08-11');
        ATK.given(mock.doWithString(ATK.between('08', '10', true).asString())).willReturn('08-10');
        ATK.given(mock.doWithString(ATK.between('08', '10').asString())).willReturn('09');
        ATK.stopStubbing();

        System.assertEquals('<=01', mock.doWithString('00'));
        System.assertEquals('<=01', mock.doWithString('01'));
        System.assertEquals('<03', mock.doWithString('02'));
        System.assertEquals('=03', mock.doWithString('03'));
        System.assertEquals('>03', mock.doWithString('04'));
        System.assertEquals('>=05', mock.doWithString('05'));
        System.assertEquals('>=05', mock.doWithString('06'));
        System.assertEquals('07-10', mock.doWithString('07'));
        System.assertEquals('08-10', mock.doWithString('08'));
        System.assertEquals('09', mock.doWithString('09'));
        System.assertEquals('08-10', mock.doWithString('10'));
        System.assertEquals('08-11', mock.doWithString('11'));
    }

    @IsTest
    static void testMock() {
        // MockException exp = new MockException();

        // ATKMockTest mock = (ATKMockTest) ATK.mock(ATKMockTest.class);
        // {
        //     // GIVEN
        //     ATK.startStubbing();
        //     ATK.given(mock.doWithInteger(0)).willReturn(0);
        //     ATK.given(mock.doWithInteger(ATK.anyInteger())).willReturn(1).willReturn(2);
        //     ATK.given(mock.doWithInteger(ATK.gt(100).asInteger()));
        //     ATK.given(mock.doWithInteger(2)).willAnswer(new StringAnswer());
        //     ATK.given(mock.doWithInteger(3)).willThrow(exp);

        //     ((ATKMockTest) ATK.willReturn(4).willReturn(5).given(mock)).doWithInteger(4);
        //     ((ATKMockTest) ATK.willThrow(exp).given(mock)).doException(); // void method
        //     ((ATKMockTest) ATK.willDoNothing().given(mock)).doNothing(); // void method
        //     ATK.stopStubbing();
        // }

        // {
        //     // WHEN
        //     System.assertEquals('0', mock.doWithInteger(0));
        //     System.assertEquals('1', mock.doWithInteger(99));
        //     System.assertEquals('2', mock.doWithInteger(99));
        //     System.assertEquals(null, mock.doWithInteger(99));
        //     System.assertEquals('2', mock.doWithInteger(2));

        //     MockException exp2;
        //     try {
        //         exp2 = null;
        //         mock.doWithInteger(3);
        //     } catch (MockException ex) {
        //         exp2 = ex;
        //     }
        //     System.assertEquals(exp, exp2);

        //     System.assertEquals('4', mock.doWithInteger(4));
        //     System.assertEquals('5', mock.doWithInteger(4));

        //     try {
        //         exp2 = null;
        //         mock.doException();
        //     } catch (MockException ex) {
        //         exp2 = ex;
        //     }
        //     System.assertEquals(exp, exp2);

        //     mock.doNothing();
        // }

        // {
        //     // THEN

        //     ((ATKMockTest) ATK.then(mock).should().times(1)).doWithInteger(0);
        //     ((ATKMockTest) ATK.then(mock).should().times(1)).doException();
        //     ((ATKMockTest) ATK.then(mock).should().times(1)).doNothing();

        //     ((ATKMockTest) ATK.then(mock).should().times(8)).doWithInteger(ATK.anyInteger());

        //     ((ATKMockTest) ATK.then(mock).should().times(2)).doWithInteger(4);
        //     ((ATKMockTest) ATK.then(mock).should().atLeast(2)).doWithInteger(4);
        //     ((ATKMockTest) ATK.then(mock).should().atMost(2)).doWithInteger(4);

        //     ((ATKMockTest) ATK.then(mock).should().never()).doWithInteger(5);

        //     // ATK.InOrder inOrder = ATK.inOrder(mock);
        //     // ((ATKMockTest)ATK.then(mock).should(inOrder).times(1)).doWithInteger(0);
        //     // ((ATKMockTest)ATK.then(mock).should(inOrder).atLeast(1)).doWithInteger(ATK.anyInteger());
        //     // ((ATKMockTest)ATK.then(mock).should(inOrder).times(1)).doWithInteger(2);
        //     // ((ATKMockTest)ATK.then(mock).should(inOrder).times(1)).doWithInteger(3);
        // }
    }

    // ******************
    // #region Test Impls

    public class MockException extends Exception {
    }

    public class StringAnswer implements ATK.Answer {
        public Object answer(ATK.Invocation invocation) {
            return '2';
        }
    }

    public void doNothing() {
    }

    public void doException() {
    }

    public String doWithInteger(Integer i) {
        return null;
    }

    public String doWithIntegers(Integer i1, Integer i2, Integer i3) {
        return null;
    }

    public String doWithLong(Long i) {
        return null;
    }

    public String doWithLongs(Long i1, Long i2, Long i3) {
        return null;
    }

    public String doWithDouble(Double i) {
        return null;
    }

    public String doWithDoubles(Double i1, Double i2, Double i3) {
        return null;
    }

    public String doWithDecimal(Decimal i) {
        return null;
    }

    public String doWithDecimals(Decimal i1, Decimal i2, Decimal i3) {
        return null;
    }

    public String doWithDate(Date i) {
        return null;
    }

    public String doWithDates(Date i1, Date i2, Date i3) {
        return null;
    }

    public String doWithDatetime(Datetime i) {
        return null;
    }

    public String doWithDatetimes(Datetime i1, Datetime i2, Datetime i3) {
        return null;
    }

    public String doWithId(Id i) {
        return null;
    }

    public String doWithIds(Id i1, Id i2, Id i3) {
        return null;
    }

    public String doWithString(String i) {
        return null;
    }

    public String doWithStrings(String i1, String i2, String i3) {
        return null;
    }

    public String doWithBoolean(Boolean i) {
        return null;
    }

    public String doWithBooleans(Boolean i1, Boolean i2, Boolean i3) {
        return null;
    }

    public String doWithObject(Object i) {
        return null;
    }

    public String doWithObjects(Object i1, Object i2, Object i3) {
        return null;
    }

    public String doWithList(List<String> i) {
        return null;
    }

    public String doWithLists(List<String> i1, List<Integer> i2, List<Object> i3) {
        return null;
    }

    public String doWithSet(Set<String> i) {
        return null;
    }

    public String doWithSets(Set<String> i1, Set<Object> i2, Set<Object> i3) {
        return null;
    }

    public String doWithMap(Map<String, Object> i) {
        return null;
    }

    public String doWithMaps(Map<String, Object> i1, Map<Object, Object> i2, Map<Object, Object> i3) {
        return null;
    }

    // #endregion
    // ******************
}
