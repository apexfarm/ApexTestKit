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
    static void tests_for_not_asserted() {
        ATKMockTest mock = (ATKMockTest) ATK.mock(ATKMockTest.class);

        ATK.startStubbing();
        ((ATKMockTest) ATK.lenient().willReturn('one').given(mock)).doWithInteger(1);
        ((ATKMockTest) ATK.lenient().willThrow(new MockTestException()).given(mock)).doWithInteger(1);
        ((ATKMockTest) ATK.lenient().willAnswer(new CustomAnswer('one')).given(mock)).doWithInteger(1);
        ((ATKMockTest) ATK.lenient().willDoNothing().given(mock)).doReturnVoid();
        ATK.stopStubbing();

        try {
            ATK.lenient();
        } catch (Exception ex) {
        }

        try {
            ATK.given(mock.doWithInteger(1));
        } catch (Exception ex) {
        }

        try {
            ATK.willAnswer(new CustomAnswer('one'));
        } catch (Exception ex) {
        }

        ATK.inOrder(mock, mock, mock);
        ATK.inOrder(mock, mock, mock, mock);
        ATK.inOrder(mock, mock, mock, mock, mock);

        Time time1 = Time.newInstance(0, 0, 0, 0);
        ATK.anyTime();
        ATK.eqTime(time1);
        ATK.neTime(time1);
        ATK.gt(time1);
        ATK.gte(time1);
        ATK.lt(time1);
        ATK.lte(time1);
        ATK.between(time1, time1);
        ATK.between(time1, time1, false);
        ATK.between(time1, false, time1, false);
    }

    @IsTest
    static void tests_for_performance_tuning() {
        ATKMockTest mock = (ATKMockTest) ATK.mock(ATKMockTest.class);

        ATK.startStubbing();
        ((ATKMockTest) ATK.willReturn('one').given(mock)).doWithInteger(1);
        ATK.stopStubbing();

        for (Integer i = 0; i < 10; i++) {
            mock.doWithInteger(1);
        }

        ((ATKMockTest) ATK.then(mock).should().times(10)).doWithInteger(1);
        System.debug(Limits.getCpuTime());
    }

    // ===============
    // #region Answers

    @IsTest
    static void test_answers_for_strict() {
        ATKMockTest mock = (ATKMockTest) ATK.mock(ATKMockTest.class);
        ATK.startStubbing();
        ATK.given(mock.doWithInteger(1)).willReturn('one');
        ATK.given(mock.doWithInteger(2)).willReturn('two');
        ATK.lenient().given(mock.doWithInteger(4)).willReturn('four');
        ATK.stopStubbing();

        ATK.then(mock).should().haveNoInteractions();

        mock.doWithInteger(1);

        ATK.MockException exp;
        try {
            mock.doWithInteger(3);
        } catch (ATK.MockException ex) {
            exp = ex;
        }
        System.assert(exp != null);
        System.debug(exp);

        exp = null;
        try {
            ATK.then(mock).should().haveNoMoreInteractions();
        } catch (ATK.MockException ex) {
            exp = ex;
        }
        System.assert(exp != null);
        System.debug(exp);

        exp = null;
        try {
            ATK.then(mock).should().haveNoUnusedStubs();
        } catch (ATK.MockException ex) {
            exp = ex;
        }
        System.assert(exp != null);
        System.debug(exp);

        mock.doWithInteger(2);

        ATK.then(mock).should().haveNoMoreInteractions();
        ATK.then(mock).should().haveNoUnusedStubs();
    }

    @IsTest
    static void test_answers_for_strict_inorder() {
        ATK.mock().withSettings().verbose();
        ATKMockTest mock1 = (ATKMockTest) ATK.mock(ATKMockTest.class, ATK.withSettings().name('mock1'));
        ATKMockTest mock2 = (ATKMockTest) ATK.mock(ATKMockTest.class, ATK.withSettings().name('mock2'));
        ATK.startStubbing();
        ATK.given(mock1.doWithInteger(1)).willReturn('one');
        ATK.given(mock2.doWithInteger(2)).willReturn('two');
        ATK.stopStubbing();

        ATK.InOrder inOrder = ATK.inOrder(mock1, mock2);
        ATK.then(mock1).should().haveNoInteractions();
        ATK.then(mock2).should().haveNoInteractions();

        mock1.doWithInteger(1);
        mock2.doWithInteger(2);

        ((ATKMockTest) ATK.then(mock1).should(inOrder).once()).doWithInteger(1);
        ((ATKMockTest) ATK.then(mock2).should(inOrder).once()).doWithInteger(2);

        ATK.then(mock1).should().haveNoMoreInteractions();
        ATK.then(mock2).should().haveNoMoreInteractions();
        ATK.then(mock1).should(inOrder).haveNoMoreInteractions();
        ATK.then(mock2).should(inOrder).haveNoMoreInteractions();
        ATK.then(mock1).should().haveNoUnusedStubs();
        ATK.then(mock2).should().haveNoUnusedStubs();
    }

    @IsTest
    static void test_answers_for_strict_stubbedVoids() {
        ATK.mock().withSettings().stubbedVoids();

        ATKMockTest mock = (ATKMockTest) ATK.mock(ATKMockTest.class);
        ATK.startStubbing();
        ATK.given(mock.doWithInteger(1)).willReturn('one');
        ATK.stopStubbing();

        System.assertEquals('one', mock.doWithInteger(1));
        mock.doReturnVoid();

        ATK.then(mock).should().haveNoMoreInteractions();
        ATK.then(mock).should().haveNoUnusedStubs();
    }

    @IsTest
    static void test_answers_for_given() {
        ATKMockTest mock = (ATKMockTest) ATK.mock(ATKMockTest.class);
        ATK.startStubbing();
        ATK.given(mock.doWithInteger(ATK.anyInteger())).willReturn('1').willReturn('2').willAnswer(new CustomAnswer('Three')).willThrow(new MockTestException());
        ATK.stopStubbing();

        System.assertEquals('1', mock.doWithInteger(1));
        System.assertEquals('2', mock.doWithInteger(2));
        System.assertEquals('Three', mock.doWithInteger(3));
        MockTestException thrownExp;
        try {
            mock.doWithInteger(4);
        } catch (MockTestException ex) {
            thrownExp = ex;
        }
        System.assertNotEquals(null, thrownExp);
        System.assertEquals(null, mock.doWithInteger(5));
    }

    @IsTest
    static void test_answers_for_will() {
        ATKMockTest mock = (ATKMockTest) ATK.mock(ATKMockTest.class);

        {
            ATK.startStubbing();
            ((ATKMockTest) ATK.willReturn('1').willReturn('2').willAnswer(new CustomAnswer('Three')).willThrow(new MockTestException()).given(mock)).doWithInteger(ATK.anyInteger());
            ATK.stopStubbing();

            System.assertEquals('1', mock.doWithInteger(1));
            System.assertEquals('2', mock.doWithInteger(2));
            System.assertEquals('Three', mock.doWithInteger(3));
            MockTestException thrownExp;
            try {
                mock.doWithInteger(4);
            } catch (MockTestException ex) {
                thrownExp = ex;
            }
            System.assertNotEquals(null, thrownExp);
            System.assertEquals(null, mock.doWithInteger(5));
            ((ATKMockTest) ATK.then(mock).should().times(5)).doWithInteger(ATK.anyInteger());
        }

        {
            ATK.startStubbing();
            ((ATKMockTest) ATK.willAnswer(new CustomAnswer('Three')).given(mock)).doWithInteger(3);
            ((ATKMockTest) ATK.willThrow(new MockTestException()).given(mock)).doWithInteger(4);
            ATK.stopStubbing();

            System.assertEquals('Three', mock.doWithInteger(3));
            MockTestException thrownExp;
            try {
                mock.doWithInteger(4);
            } catch (MockTestException ex) {
                thrownExp = ex;
            }
            System.assertNotEquals(null, thrownExp);
        }

        {
            ATK.startStubbing();
            ((ATKMockTest) ATK.willDoNothing().willReturn('2').willAnswer(new CustomAnswer('Three')).willThrow(new MockTestException()).given(mock)).doReturnVoid();
            ATK.stopStubbing();

            mock.doReturnVoid();
            mock.doReturnVoid();
            mock.doReturnVoid();
            MockTestException thrownExp;
            try {
                mock.doReturnVoid();
            } catch (MockTestException ex) {
                thrownExp = ex;
            }
            System.assertNotEquals(null, thrownExp);
            mock.doReturnVoid();

            ((ATKMockTest) ATK.then(mock).should().times(5)).doReturnVoid();
        }
    }

    @IsTest
    static void test_answers_for_returns_defaults() {
        ATKMockTest mock = (ATKMockTest) ATK.mock(ATKMockTest.class, ATK.withSettings().lenient());

        System.assertEquals(0, mock.doReturnInteger());
        System.assertEquals(0L, mock.doReturnLong());
        System.assertEquals(0.0d, mock.doReturnDouble());
        System.assertEquals(0, mock.doReturnDecimal());
        System.assertEquals('', mock.doReturnString());
        System.assertEquals(false, mock.doReturnBoolean());
        System.assert(null != mock.doReturnAccountList());
        System.assert(null != mock.doReturnAccountSet());
        System.assert(null != mock.doReturnAccountMap());
        System.assert(null != mock.doReturnAccount());
        System.assertEquals(null, mock.doReturnSObject());
        System.assertEquals(null, mock.doReturnMock(null));
    }

    @IsTest
    static void test_answers_for_returns_self() {
        ATKMockTest mock = (ATKMockTest) ATK.mock(ATKMockTest.class, ATK.withSettings().lenient().defaultAnswer(ATK.RETURNS_SELF).verbose());

        ATK.startStubbing();
        // prettier-ignore
        ATK.given(mock
            .doReturnSelf(ATK.any())
            .doReturnSelf(1)
            .doWithInteger(ATK.anyInteger()))
                .willReturn('return 1');
        ATK.stopStubbing();

        System.assertEquals('return 1', mock.doReturnSelf('1').doReturnSelf(1).doWithInteger(1));
    }

    @IsTest
    static void test_answers_for_returns_mocks() {
        {
            // stubbed
            ATKMockTest mock = (ATKMockTest) ATK.mock(ATKMockTest.class, ATK.withSettings().lenient().defaultAnswer(ATK.RETURNS_MOCKS));
            ATKMockTest instance = new ATKMockTest();

            ATK.startStubbing();
            ATK.given(mock.doReturnMock(null)).willReturn(null).willReturn(instance);
            ATK.stopStubbing();

            System.assertEquals(null, mock.doReturnMock(null));
            System.assertEquals(instance, mock.doReturnMock(null));
            System.assertEquals(null, mock.doReturnMock(null));
        }

        {
            // unstubbed
            ATKMockTest mock = (ATKMockTest) ATK.mock(ATKMockTest.class, ATK.withSettings().lenient().defaultAnswer(ATK.RETURNS_MOCKS));

            ATKMockTest anotherMock = mock.doReturnMock(null);
            anotherMock.doWithInteger(1);

            ((ATKMockTest) ATK.then(anotherMock).should().once()).doWithInteger(1);
        }
    }

    @IsTest
    static void test_answers_for_returns_defaults_and_self() {
        ATK.mock().withSettings().defaultAnswer(ATK.RETURNS_MOCKS).lenient();
        ATKMockTest mock1 = (ATKMockTest) ATK.mock(ATKMockTest.class, ATK.RETURNS_DEFAULTS);
        ATKMockTest mock2 = (ATKMockTest) ATK.mock(ATKMockTest.class, ATK.RETURNS_SELF);

        System.assertEquals(0, mock1.doReturnInteger());
        System.assertEquals(0L, mock1.doReturnLong());
        System.assertEquals(0.0d, mock1.doReturnDouble());
        System.assertEquals(0, mock1.doReturnDecimal());
        System.assertEquals('', mock1.doReturnString());
        System.assertEquals(false, mock1.doReturnBoolean());
        System.assert(null != mock1.doReturnAccountList());
        System.assert(null != mock1.doReturnAccountSet());
        System.assert(null != mock1.doReturnAccountMap());
        System.assert(null != mock1.doReturnAccount());
        System.assertEquals(null, mock1.doReturnSObject());
        System.assertEquals(null, mock1.doReturnMock(null));

        ATK.startStubbing();
        // prettier-ignore
        ATK.given(mock2
            .doReturnSelf(ATK.any())
            .doReturnSelf(1)
            .doWithInteger(ATK.anyInteger()))
                .willReturn('one');
        ATK.stopStubbing();

        System.assertEquals('one', mock2.doReturnSelf('1').doReturnSelf(1).doWithInteger(1));
    }

    @IsTest
    static void test_answers_for_custom_answers() {
        ATK.mock().withSettings().lenient();
        ATKMockTest mock1 = (ATKMockTest) ATK.mock(ATKMockTest.class, new CustomAnswer('Custom Answer 1'));
        System.assertEquals('Custom Answer 1', mock1.doWithInteger(1));

        ATK.mock().withSettings().defaultAnswer(new CustomAnswer('Custom Answer 2'));

        ATKMockTest mock2 = (ATKMockTest) ATK.mock(ATKMockTest.class);
        System.assertEquals('Custom Answer 2', mock2.doWithInteger(2));

        ATKMockTest mock3 = (ATKMockTest) ATK.mock(ATKMockTest.class, new CustomAnswer('Custom Answer 3'));
        System.assertEquals('Custom Answer 3', mock3.doWithInteger(3));
    }

    // #endregion
    // ===============

    // ================
    // #region Matchers

    @IsTest
    static void test_matchers_for_types() {
        ATK.mock().withSettings().verbose();
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
        // ATK.given(mock.doWithTime(ATK.anyTime())).willReturn('0');
        // ATK.given(mock.doWithTimes(ATK.anyTime(), ATK.anyTime(), ATK.anyTime())).willReturn('0');
        ATK.given(mock.doWithId(ATK.anyId())).willReturn('0');
        ATK.given(mock.doWithIds(ATK.anyId(), ATK.anyId(), ATK.anyId())).willReturn('0');
        ATK.given(mock.doWithString(ATK.anyString())).willReturn('0');
        ATK.given(mock.doWithStrings(ATK.anyString(), ATK.anyString(), ATK.anyString())).willReturn('0');
        ATK.given(mock.doWithBoolean(ATK.anyBoolean())).willReturn('0');
        ATK.given(mock.doWithBooleans(ATK.anyBoolean(), ATK.anyBoolean(), ATK.anyBoolean())).willReturn('0');
        ATK.given(mock.doWithObject(ATK.nullable(Object.class))).willReturn('nullable');
        ATK.given(mock.doWithObject(ATK.any(Object.class))).willReturn('0');
        ATK.given(mock.doWithObjects((ATKMockTest) ATK.any(ATKMockTest.class), ATK.any(), ATK.any())).willReturn('0');
        ATK.given(mock.doWithList(ATK.anyList())).willReturn('0');
        ATK.given(mock.doWithLists((List<ATKMockTest>) ATK.anyList(), ATK.anyList(), ATK.anyList())).willReturn('0');
        ATK.given(mock.doWithSet((Set<ATKMockTest>) ATK.anySet())).willReturn('0');
        ATK.given(mock.doWithSets((Set<ATKMockTest>) ATK.anySet(), (Set<Object>) ATK.anySet(), (Set<Object>) ATK.anySet())).willReturn('0');
        ATK.given(mock.doWithMap((Map<String, ATKMockTest>) ATK.anyMap())).willReturn('0');
        ATK.given(mock.doWithMaps((Map<String, ATKMockTest>) ATK.anyMap(), (Map<Object, Object>) ATK.anyMap(), (Map<Object, Object>) ATK.anyMap())).willReturn('0');
        ATK.given(mock.doWithSObject(ATK.anySObject())).willReturn('0');
        ATK.given(mock.doWithSObjects(ATK.anySObjectList())).willReturn('0');
        ATK.stopStubbing();

        System.assertEquals('0', mock.doWithInteger(1));
        System.assertEquals('0', mock.doWithIntegers(1, 2, 3));
        System.assertEquals('0', mock.doWithLong(1L));
        System.assertEquals('0', mock.doWithLongs(1L, 2L, 3L));
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
        System.assertEquals('nullable', mock.doWithObject(null));
        System.assertEquals('0', mock.doWithObject(new ATKMockTest()));
        System.assertEquals('0', mock.doWithObjects(new ATKMockTest(), 2, '3'));
        System.assertEquals('0', mock.doWithList(new List<ATKMockTest>()));
        System.assertEquals('0', mock.doWithLists(new List<ATKMockTest>(), new List<Object>(), new List<Object>()));
        System.assertEquals('0', mock.doWithSet(new Set<ATKMockTest>()));
        System.assertEquals('0', mock.doWithSets(new Set<ATKMockTest>(), new Set<Object>(), new Set<Object>()));
        System.assertEquals('0', mock.doWithMap(new Map<String, ATKMockTest>()));
        System.assertEquals('0', mock.doWithMaps(new Map<String, ATKMockTest>(), new Map<Object, Object>(), new Map<Object, Object>()));
        System.assertEquals('0', mock.doWithSObject(new Account()));
        System.assertEquals('0', mock.doWithSObjects(new List<Account>()));
    }

    @IsTest
    static void test_matchers_for_integers() {
        ATK.mock().withSettings().verbose();
        ATKMockTest mock = (ATKMockTest) ATK.mock(ATKMockTest.class);
        ATK.startStubbing();
        ATK.given(mock.doWithInteger(ATK.lt(3))).willReturn('<3');
        ATK.given(mock.doWithInteger(ATK.lte(1))).willReturn('<=1');
        ATK.given(mock.doWithInteger(ATK.eqInteger(3))).willReturn('=3');
        ATK.given(mock.doWithInteger(ATK.gt(3))).willReturn('>3');
        ATK.given(mock.doWithInteger(ATK.gte(5))).willReturn('>=5');
        ATK.given(mock.doWithInteger(ATK.between(7, true, 11, false))).willReturn('7-10');
        ATK.given(mock.doWithInteger(ATK.between(7, false, 11, true))).willReturn('8-11');
        ATK.given(mock.doWithInteger(ATK.between(8, 10))).willReturn('8-10');
        ATK.given(mock.doWithInteger(ATK.between(8, 10, false))).willReturn('9');
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
    static void test_matchers_for_long() {
        ATK.mock().withSettings().verbose();
        ATKMockTest mock = (ATKMockTest) ATK.mock(ATKMockTest.class);
        ATK.startStubbing();
        ATK.given(mock.doWithLong(ATK.lt(3L))).willReturn('<3');
        ATK.given(mock.doWithLong(ATK.lte(1L))).willReturn('<=1');
        ATK.given(mock.doWithLong(ATK.eqLong(3L))).willReturn('=3');
        ATK.given(mock.doWithLong(ATK.gt(3L))).willReturn('>3');
        ATK.given(mock.doWithLong(ATK.gte(5L))).willReturn('>=5');
        ATK.given(mock.doWithLong(ATK.between(7L, true, 11L, false))).willReturn('7-10');
        ATK.given(mock.doWithLong(ATK.between(7L, false, 11L, true))).willReturn('8-11');
        ATK.given(mock.doWithLong(ATK.between(8L, 10L))).willReturn('8-10');
        ATK.given(mock.doWithLong(ATK.between(8L, 10L, false))).willReturn('9');
        ATK.stopStubbing();

        System.assertEquals('<=1', mock.doWithLong(0L));
        System.assertEquals('<=1', mock.doWithLong(1L));
        System.assertEquals('<3', mock.doWithLong(2L));
        System.assertEquals('=3', mock.doWithLong(3L));
        System.assertEquals('>3', mock.doWithLong(4L));
        System.assertEquals('>=5', mock.doWithLong(5L));
        System.assertEquals('>=5', mock.doWithLong(6L));
        System.assertEquals('7-10', mock.doWithLong(7L));
        System.assertEquals('8-10', mock.doWithLong(8L));
        System.assertEquals('9', mock.doWithLong(9L));
        System.assertEquals('8-10', mock.doWithLong(10L));
        System.assertEquals('8-11', mock.doWithLong(11L));
    }

    @IsTest
    static void test_matchers_for_double() {
        ATK.mock().withSettings().verbose();
        ATKMockTest mock = (ATKMockTest) ATK.mock(ATKMockTest.class);
        ATK.startStubbing();
        ATK.given(mock.doWithDouble(ATK.lt(3.0d))).willReturn('<3');
        ATK.given(mock.doWithDouble(ATK.lte(1.0d))).willReturn('<=1');
        ATK.given(mock.doWithDouble(ATK.eqDouble(3.0d))).willReturn('=3');
        ATK.given(mock.doWithDouble(ATK.gt(3.0d))).willReturn('>3');
        ATK.given(mock.doWithDouble(ATK.gte(5.0d))).willReturn('>=5');
        ATK.given(mock.doWithDouble(ATK.between(7.0d, true, 11.0d, false))).willReturn('7-10');
        ATK.given(mock.doWithDouble(ATK.between(7.0d, false, 11.0d, true))).willReturn('8-11');
        ATK.given(mock.doWithDouble(ATK.between(8.0d, 10.0d))).willReturn('8-10');
        ATK.given(mock.doWithDouble(ATK.between(8.0d, 10.0d, false))).willReturn('9');
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
    static void test_matchers_for_decimal() {
        ATK.mock().withSettings().verbose();
        ATKMockTest mock = (ATKMockTest) ATK.mock(ATKMockTest.class);
        ATK.startStubbing();
        ATK.given(mock.doWithDecimal(ATK.lt(3.0))).willReturn('<3');
        ATK.given(mock.doWithDecimal(ATK.lte(1.0))).willReturn('<=1');
        ATK.given(mock.doWithDecimal(ATK.eqDecimal(3.0))).willReturn('=3');
        ATK.given(mock.doWithDecimal(ATK.gt(3.0))).willReturn('>3');
        ATK.given(mock.doWithDecimal(ATK.gte(5.0))).willReturn('>=5');
        ATK.given(mock.doWithDecimal(ATK.between(7.0, true, 11.0, false))).willReturn('7-10');
        ATK.given(mock.doWithDecimal(ATK.between(7.0, false, 11.0, true))).willReturn('8-11');
        ATK.given(mock.doWithDecimal(ATK.between(8.0, 10.0))).willReturn('8-10');
        ATK.given(mock.doWithDecimal(ATK.between(8.0, 10.0, false))).willReturn('9');
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
    static void test_matchers_for_date() {
        ATK.mock().withSettings().verbose();
        ATKMockTest mock = (ATKMockTest) ATK.mock(ATKMockTest.class);
        ATK.startStubbing();
        ATK.given(mock.doWithDate(ATK.lt(Date.newInstance(2022, 1, 3)))).willReturn('<3');
        ATK.given(mock.doWithDate(ATK.lte(Date.newInstance(2022, 1, 1)))).willReturn('<=1');
        ATK.given(mock.doWithDate(ATK.eqDate(Date.newInstance(2022, 1, 3)))).willReturn('=3');
        ATK.given(mock.doWithDate(ATK.gt(Date.newInstance(2022, 1, 3)))).willReturn('>3');
        ATK.given(mock.doWithDate(ATK.gte(Date.newInstance(2022, 1, 5)))).willReturn('>=5');
        ATK.given(mock.doWithDate(ATK.between(Date.newInstance(2022, 1, 7), true, Date.newInstance(2022, 1, 11), false))).willReturn('7-10');
        ATK.given(mock.doWithDate(ATK.between(Date.newInstance(2022, 1, 7), false, Date.newInstance(2022, 1, 11), true))).willReturn('8-11');
        ATK.given(mock.doWithDate(ATK.between(Date.newInstance(2022, 1, 8), Date.newInstance(2022, 1, 10)))).willReturn('8-10');
        ATK.given(mock.doWithDate(ATK.between(Date.newInstance(2022, 1, 8), Date.newInstance(2022, 1, 10), false))).willReturn('9');
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
    static void test_matchers_for_datetime() {
        ATK.mock().withSettings().verbose();
        ATKMockTest mock = (ATKMockTest) ATK.mock(ATKMockTest.class);
        ATK.startStubbing();
        ATK.given(mock.doWithDatetime(ATK.lt(Datetime.newInstance(2022, 1, 3)))).willReturn('<3');
        ATK.given(mock.doWithDatetime(ATK.lte(Datetime.newInstance(2022, 1, 1)))).willReturn('<=1');
        ATK.given(mock.doWithDatetime(ATK.eqDatetime(Datetime.newInstance(2022, 1, 3)))).willReturn('=3');
        ATK.given(mock.doWithDatetime(ATK.gt(Datetime.newInstance(2022, 1, 3)))).willReturn('>3');
        ATK.given(mock.doWithDatetime(ATK.gte(Datetime.newInstance(2022, 1, 5)))).willReturn('>=5');
        ATK.given(mock.doWithDatetime(ATK.between(Datetime.newInstance(2022, 1, 7), true, Datetime.newInstance(2022, 1, 11), false))).willReturn('7-10');
        ATK.given(mock.doWithDatetime(ATK.between(Datetime.newInstance(2022, 1, 7), false, Datetime.newInstance(2022, 1, 11), true))).willReturn('8-11');
        ATK.given(mock.doWithDatetime(ATK.between(Datetime.newInstance(2022, 1, 8), Datetime.newInstance(2022, 1, 10)))).willReturn('8-10');
        ATK.given(mock.doWithDatetime(ATK.between(Datetime.newInstance(2022, 1, 8), Datetime.newInstance(2022, 1, 10), false))).willReturn('9');
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
    static void test_matchers_for_id() {
        ATK.mock().withSettings().verbose();
        ATKMockTest mock = (ATKMockTest) ATK.mock(ATKMockTest.class);
        ATK.startStubbing();
        ATK.given(mock.doWithId(ATK.lt(ATK.fakeId(Account.SObjectType, 3)))).willReturn('<3');
        ATK.given(mock.doWithId(ATK.lte(ATK.fakeId(Account.SObjectType, 1)))).willReturn('<=1');
        ATK.given(mock.doWithId(ATK.eqId(ATK.fakeId(Account.SObjectType, 3)))).willReturn('=3');
        ATK.given(mock.doWithId(ATK.gt(ATK.fakeId(Account.SObjectType, 3)))).willReturn('>3');
        ATK.given(mock.doWithId(ATK.gte(ATK.fakeId(Account.SObjectType, 5)))).willReturn('>=5');
        ATK.given(mock.doWithId(ATK.between(ATK.fakeId(Account.SObjectType, 7), true, ATK.fakeId(Account.SObjectType, 11), false))).willReturn('7-10');
        ATK.given(mock.doWithId(ATK.between(ATK.fakeId(Account.SObjectType, 7), false, ATK.fakeId(Account.SObjectType, 11), true))).willReturn('8-11');
        ATK.given(mock.doWithId(ATK.between(ATK.fakeId(Account.SObjectType, 8), ATK.fakeId(Account.SObjectType, 10)))).willReturn('8-10');
        ATK.given(mock.doWithId(ATK.between(ATK.fakeId(Account.SObjectType, 8), ATK.fakeId(Account.SObjectType, 10), false))).willReturn('9');
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
    static void test_matchers_for_string() {
        ATK.mock().withSettings().verbose();
        ATKMockTest mock = (ATKMockTest) ATK.mock(ATKMockTest.class);
        ATK.startStubbing();
        ATK.given(mock.doWithString(ATK.lt('03'))).willReturn('<03');
        ATK.given(mock.doWithString(ATK.lte('01'))).willReturn('<=01');
        ATK.given(mock.doWithString(ATK.eqString('03'))).willReturn('=03');
        ATK.given(mock.doWithString(ATK.gt('03'))).willReturn('>03');
        ATK.given(mock.doWithString(ATK.gte('05'))).willReturn('>=05');
        ATK.given(mock.doWithString(ATK.between('07', true, '11', false))).willReturn('07-10');
        ATK.given(mock.doWithString(ATK.between('07', false, '11', true))).willReturn('08-11');
        ATK.given(mock.doWithString(ATK.between('08', '10'))).willReturn('08-10');
        ATK.given(mock.doWithString(ATK.between('08', '10', false))).willReturn('09');
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
    static void test_matchers_for_string_methods() {
        ATK.mock().withSettings().verbose();
        ATKMockTest mock = (ATKMockTest) ATK.mock(ATKMockTest.class);
        ATK.startStubbing();
        ATK.given(mock.doWithString(ATK.isBlank())).willReturn('blank');
        ATK.given(mock.doWithString(ATK.isNotBlank())).willReturn('not blank');
        ATK.given(mock.doWithString(ATK.contains('a'))).willReturn('a');
        ATK.given(mock.doWithString(ATK.startsWith('b'))).willReturn('b');
        ATK.given(mock.doWithString(ATK.endsWith('c'))).willReturn('c');
        ATK.given(mock.doWithString(ATK.matches('x{3}dx{3}'))).willReturn('d');
        ATK.stopStubbing();

        System.assertEquals('a', mock.doWithString('xxxaxxx'));
        System.assertEquals('b', mock.doWithString('bxxxxxx'));
        System.assertEquals('c', mock.doWithString('xxxxxxc'));
        System.assertEquals('d', mock.doWithString('xxxdxxx'));
        System.assertEquals('not blank', mock.doWithString('xxxxxxx'));
        System.assertEquals('blank', mock.doWithString(' \r\n'));
    }

    @IsTest
    static void test_matchers_for_boolean() {
        ATK.mock().withSettings().verbose();
        ATKMockTest mock = (ATKMockTest) ATK.mock(ATKMockTest.class);
        ATK.startStubbing();
        ATK.given(mock.doWithBoolean(ATK.eqBoolean(true))).willReturn('true');
        ATK.given(mock.doWithBoolean(ATK.eqBoolean(false))).willReturn('false');
        ATK.stopStubbing();

        System.assertEquals('true', mock.doWithBoolean(true));
        System.assertEquals('false', mock.doWithBoolean(false));
    }

    @IsTest
    static void test_matchers_for_object() {
        ATK.mock().withSettings().verbose();
        ATKMockTest mock = (ATKMockTest) ATK.mock(ATKMockTest.class);
        ATKMockTest theObject = new ATKMockTest();
        ATK.startStubbing();
        ATK.given(mock.doWithObject(ATK.isNull())).willReturn('null');
        ATK.given(mock.doWithObject(ATK.isNotNull())).willReturn('not null');
        ATK.given(mock.doWithObject(ATK.eq(theObject))).willReturn('eq Object');
        ATK.stopStubbing();

        System.assertEquals('eq Object', mock.doWithObject(theObject));
        System.assertEquals('not null', mock.doWithObject(new ATKMockTest()));
        System.assertEquals('null', mock.doWithObject(null));
    }

    @IsTest
    static void test_matchers_for_list() {
        ATK.mock().withSettings().verbose();
        ATKMockTest mock = (ATKMockTest) ATK.mock(ATKMockTest.class);
        List<Integer> theList = new List<Integer>{ 1, 2, 3 };
        ATK.startStubbing();
        ATK.given(mock.doWithList((List<Integer>) ATK.eq(theList))).willReturn('eq List');
        ATK.given(mock.doWithList((List<Integer>) ATK.same(theList))).willReturn('same List');
        ATK.given(mock.doWithList((List<ATKMockTest>) ATK.eq(new List<ATKMockTest>()))).willReturn('eq List');
        ATK.stopStubbing();

        System.assertEquals('eq List', mock.doWithList(new List<ATKMockTest>()));
        System.assertEquals('eq List', mock.doWithList(new List<Integer>{ 1, 2, 3 }));
        System.assertEquals('same List', mock.doWithList(theList));
    }

    @IsTest
    static void test_matchers_for_sobject() {
        ATK.mock().withSettings().verbose();
        ATKMockTest mock = (ATKMockTest) ATK.mock(ATKMockTest.class);
        ATK.startStubbing();
        ATK.given(mock.doWithSObject(ATK.sObjectWithId(ATK.fakeId(Account.SObjectType, 0)))).willReturn('0');
        ATK.given(mock.doWithSObject(ATK.sObjectWithName('Account 1'))).willReturn('1');
        ATK.given(mock.doWithSObject(ATK.sObjectWith(Account.Name, 'Account 2'))).willReturn('2');
        ATK.given(mock.doWithSObject(ATK.sObjectWith(new Map<SObjectField, Object>{ Account.Id => ATK.fakeId(Account.SObjectType, 3), Account.Name => 'Account 3' }))).willReturn('3');
        ATK.stopStubbing();

        System.assertEquals('0', mock.doWithSObject(new Account(Id = ATK.fakeId(Account.SObjectType, 0), Name = 'Account 0')));
        System.assertEquals('1', mock.doWithSObject(new Account(Id = ATK.fakeId(Account.SObjectType, 1), Name = 'Account 1')));
        System.assertEquals('2', mock.doWithSObject(new Account(Id = ATK.fakeId(Account.SObjectType, 2), Name = 'Account 2')));
        System.assertEquals('3', mock.doWithSObject(new Account(Id = ATK.fakeId(Account.SObjectType, 3), Name = 'Account 3')));
    }

    @IsTest
    static void test_matchers_for_sobject_list() {
        ATK.mock().withSettings().verbose();
        ATKMockTest mock = (ATKMockTest) ATK.mock(ATKMockTest.class);
        ATK.startStubbing();
        ATK.given(mock.doWithSObjects(ATK.sObjectListWith(Account.Description, 'Same Account'))).willReturn('1');
        ATK.given(mock.doWithSObjects(ATK.sObjectListWith(new Map<SObjectField, Object>{ Account.Name => 'Account 2', Account.Description => 'Description 2' }))).willReturn('2');
        ATK.given(
                mock.doWithSObjects(
                    ATK.sObjectListWith(
                        new List<Map<SObjectField, Object>>{
                            new Map<SObjectField, Object>{ Account.Name => 'Account 3', Account.Description => 'Description 3' },
                            new Map<SObjectField, Object>{ Account.Name => 'Account 4', Account.Description => 'Description 4' },
                            new Map<SObjectField, Object>{ Account.Name => 'Account 5', Account.Description => 'Description 5' }
                        }
                    )
                )
            )
            .willReturn('3');
        ATK.given(
                mock.doWithSObjects(
                    ATK.sObjectListWith(
                        new List<Map<SObjectField, Object>>{
                            new Map<SObjectField, Object>{ Account.Name => 'Account 3', Account.Description => 'Description 3' },
                            new Map<SObjectField, Object>{ Account.Name => 'Account 4', Account.Description => 'Description 4' },
                            new Map<SObjectField, Object>{ Account.Name => 'Account 5', Account.Description => 'Description 5' }
                        },
                        true
                    )
                )
            )
            .willReturn('4');
        ATK.stopStubbing();

        System.assertEquals(
            '1',
            mock.doWithSObjects(
                new List<Account>{
                    new Account(Name = 'Account 1', Description = 'Same Account'),
                    new Account(Name = 'Account 2', Description = 'Same Account'),
                    new Account(Name = 'Account 3', Description = 'Same Account')
                }
            )
        );

        System.assertEquals(
            '2',
            mock.doWithSObjects(
                new List<Account>{
                    new Account(Name = 'Account 2', Description = 'Description 2'),
                    new Account(Name = 'Account 2', Description = 'Description 2'),
                    new Account(Name = 'Account 2', Description = 'Description 2')
                }
            )
        );

        System.assertEquals(
            '3',
            mock.doWithSObjects(
                new List<Account>{
                    new Account(Name = 'Account 4', Description = 'Description 4'),
                    new Account(Name = 'Account 3', Description = 'Description 3'),
                    new Account(Name = 'Account 5', Description = 'Description 5')
                }
            )
        );

        System.assertEquals(
            '4',
            mock.doWithSObjects(
                new List<Account>{
                    new Account(Name = 'Account 3', Description = 'Description 3'),
                    new Account(Name = 'Account 4', Description = 'Description 4'),
                    new Account(Name = 'Account 5', Description = 'Description 5')
                }
            )
        );
    }

    @IsTest
    static void test_matchers_for_combos() {
        ATK.mock().withSettings().verbose();
        ATKMockTest mock = (ATKMockTest) ATK.mock(ATKMockTest.class);
        ATK.startStubbing();
        ATK.given(mock.doWithSObject((SObject) ATK.isNot(ATK.sObjectWith(Account.Name, 'Company 1')))).willReturn('isNot 1');
        ATK.given(mock.doWithSObject((SObject) ATK.noneOf(ATK.sObjectWith(Account.Name, 'Company 1'), ATK.sObjectWith(Account.Name, 'Company 2')))).willReturn('noneOf 2');
        ATK.given(mock.doWithSObject((SObject) ATK.noneOf(ATK.sObjectWith(Account.Name, 'Company 1'), ATK.sObjectWith(Account.Name, 'Company 2'), ATK.sObjectWith(Account.Name, 'Company 3'))))
            .willReturn('noneOf 3');
        ATK.given(
                mock.doWithSObject(
                    (SObject) ATK.noneOf(
                        ATK.sObjectWith(Account.Name, 'Company 1'),
                        ATK.sObjectWith(Account.Name, 'Company 2'),
                        ATK.sObjectWith(Account.Name, 'Company 3'),
                        ATK.sObjectWith(Account.Name, 'Company 4')
                    )
                )
            )
            .willReturn('noneOf 4');
        ATK.given(
                mock.doWithSObject(
                    (SObject) ATK.noneOf(
                        ATK.sObjectWith(Account.Name, 'Company 1'),
                        ATK.sObjectWith(Account.Name, 'Company 2'),
                        ATK.sObjectWith(Account.Name, 'Company 3'),
                        ATK.sObjectWith(Account.Name, 'Company 4'),
                        ATK.sObjectWith(Account.Name, 'Company 5')
                    )
                )
            )
            .willReturn('noneOf 5');
        ATK.given(
                mock.doWithSObject(
                    (SObject) ATK.noneOf(
                        new List<Object>{
                            ATK.sObjectWith(Account.Name, 'Company 1'),
                            ATK.sObjectWith(Account.Name, 'Company 2'),
                            ATK.sObjectWith(Account.Name, 'Company 3'),
                            ATK.sObjectWith(Account.Name, 'Company 4'),
                            ATK.sObjectWith(Account.Name, 'Company 5'),
                            ATK.sObjectWith(Account.Name, 'Company 6')
                        }
                    )
                )
            )
            .willReturn('noneOf 6');

        ATK.given(mock.doWithSObject((SObject) ATK.anyOf(ATK.isNull(), ATK.sObjectWith(Account.Name, 'Business 2')))).willReturn('anyOf 2');
        ATK.given(mock.doWithSObject((SObject) ATK.anyOf(ATK.isNull(), ATK.sObjectWithId(ATK.fakeId(Account.SObjectType, 3)), ATK.sObjectWith(Account.Name, 'Business 3')))).willReturn('anyOf 3');
        ATK.given(mock.doWithSObject((SObject) ATK.anyOf(ATK.isNull(), ATK.anyBoolean(), ATK.sObjectWithId(ATK.fakeId(Account.SObjectType, 4)), ATK.sObjectWith(Account.Name, 'Business 4'))))
            .willReturn('anyOf 4');
        ATK.given(
                mock.doWithSObject(
                    (SObject) ATK.anyOf(
                        ATK.isNull(),
                        ATK.anyBoolean(),
                        ATK.sObjectWithId(ATK.fakeId(Account.SObjectType, 5)),
                        ATK.sObjectWith(Account.Name, 'Business 5'),
                        ATK.sObjectWith(Account.Description, 'Description 5')
                    )
                )
            )
            .willReturn('anyOf 5');
        ATK.given(mock.doWithSObject((SObject) ATK.anyOf(new List<Object>{ ATK.isNull(), ATK.sObjectWith(Account.Name, 'Business 6') }))).willReturn('anyOf 6');

        ATK.given(mock.doWithSObject((SObject) ATK.allOf(ATK.anySObject(), ATK.sObjectWith(Account.Name, 'Account 2')))).willReturn('allOf 2');
        ATK.given(mock.doWithSObject((SObject) ATK.allOf(ATK.anySObject(), ATK.sObjectWithId(ATK.fakeId(Account.SObjectType, 3)), ATK.sObjectWith(Account.Name, 'Account 3')))).willReturn('allOf 3');
        ATK.given(mock.doWithSObject((SObject) ATK.allOf(ATK.anySObject(), ATK.isNotNull(), ATK.sObjectWithId(ATK.fakeId(Account.SObjectType, 4)), ATK.sObjectWith(Account.Name, 'Account 4'))))
            .willReturn('allOf 4');
        ATK.given(
                mock.doWithSObject(
                    (SObject) ATK.allOf(
                        ATK.anySObject(),
                        ATK.isNotNull(),
                        ATK.sObjectWithId(ATK.fakeId(Account.SObjectType, 5)),
                        ATK.sObjectWith(Account.Name, 'Account 5'),
                        ATK.sObjectWith(Account.Description, 'Description 5')
                    )
                )
            )
            .willReturn('allOf 5');
        ATK.given(mock.doWithSObject((SObject) ATK.allOf(new List<Object>{ ATK.anySObject(), ATK.sObjectWith(Account.Name, 'Account 6') }))).willReturn('allOf 6');
        ATK.stopStubbing();

        System.assertEquals('allOf 2', mock.doWithSObject(new Account(Id = ATK.fakeId(Account.SObjectType, 2), Name = 'Account 2')));
        System.assertEquals('allOf 3', mock.doWithSObject(new Account(Id = ATK.fakeId(Account.SObjectType, 3), Name = 'Account 3')));
        System.assertEquals('allOf 4', mock.doWithSObject(new Account(Id = ATK.fakeId(Account.SObjectType, 4), Name = 'Account 4')));
        System.assertEquals('allOf 5', mock.doWithSObject(new Account(Id = ATK.fakeId(Account.SObjectType, 5), Name = 'Account 5', Description = 'Description 5')));
        System.assertEquals('allOf 6', mock.doWithSObject(new Account(Id = ATK.fakeId(Account.SObjectType, 6), Name = 'Account 6')));

        System.assertEquals('anyOf 2', mock.doWithSObject(new Account(Id = ATK.fakeId(Account.SObjectType, 2), Name = 'Business 2')));
        System.assertEquals('anyOf 3', mock.doWithSObject(new Account(Id = ATK.fakeId(Account.SObjectType, 3), Name = 'Business 3')));
        System.assertEquals('anyOf 4', mock.doWithSObject(new Account(Id = ATK.fakeId(Account.SObjectType, 4), Name = 'Business 4')));
        System.assertEquals('anyOf 5', mock.doWithSObject(new Account(Id = ATK.fakeId(Account.SObjectType, 5), Name = 'Business 5', Description = 'Description 5')));
        System.assertEquals('anyOf 6', mock.doWithSObject(new Account(Id = ATK.fakeId(Account.SObjectType, 6), Name = 'Business 6')));

        System.assertEquals('isNot 1', mock.doWithSObject(new Account(Name = 'Company 2')));
        System.assertEquals('noneOf 2', mock.doWithSObject(new Account(Name = 'Company 3')));
        System.assertEquals('noneOf 3', mock.doWithSObject(new Account(Name = 'Company 4')));
        System.assertEquals('noneOf 4', mock.doWithSObject(new Account(Name = 'Company 5')));
        System.assertEquals('noneOf 5', mock.doWithSObject(new Account(Name = 'Company 6')));
        System.assertEquals('noneOf 6', mock.doWithSObject(new Account(Name = 'Company 7')));
    }

    @IsTest
    static void test_matchers_for_ne_series() {
        ATK.mock().withSettings().verbose();
        ATKMockTest mock = (ATKMockTest) ATK.mock(ATKMockTest.class, ATK.withSettings().lenient());
        ATK.startStubbing();
        ATK.given(mock.doWithObject(ATK.ne(1))).willReturn('1');
        ATK.given(mock.doWithInteger(ATK.neInteger(2))).willReturn('2');
        ATK.given(mock.doWithLong(ATK.neLong(3))).willReturn('3');
        ATK.given(mock.doWithDouble(ATK.neDouble(4.0d))).willReturn('4');
        ATK.given(mock.doWithDecimal(ATK.neDecimal(5.0))).willReturn('5');
        ATK.given(mock.doWithDate(ATK.neDate(Date.newInstance(2022, 1, 6)))).willReturn('6');
        ATK.given(mock.doWithDatetime(ATK.neDatetime(Datetime.newInstance(2022, 1, 7)))).willReturn('7');
        ATK.given(mock.doWithId(ATK.neId(ATK.fakeId(Account.SObjectType, 9)))).willReturn('9');
        ATK.given(mock.doWithString(ATK.neString('10'))).willReturn('10');
        ATK.given(mock.doWithBoolean(ATK.neBoolean(true))).willReturn('11');
        ATK.stopStubbing();

        System.assertEquals('', mock.doWithObject(1));
        System.assertEquals('', mock.doWithInteger(2));
        System.assertEquals('', mock.doWithLong(3L));
        System.assertEquals('', mock.doWithDouble(4.0d));
        System.assertEquals('', mock.doWithDecimal(5.0));
        System.assertEquals('', mock.doWithDate(Date.newInstance(2022, 1, 6)));
        System.assertEquals('', mock.doWithDatetime(Datetime.newInstance(2022, 1, 7)));
        System.assertEquals('', mock.doWithId(ATK.fakeId(Account.SObjectType, 9)));
        System.assertEquals('', mock.doWithString('10'));
        System.assertEquals('', mock.doWithBoolean(true));

        System.assertEquals('1', mock.doWithObject(2));
        System.assertEquals('2', mock.doWithInteger(3));
        System.assertEquals('3', mock.doWithLong(4L));
        System.assertEquals('4', mock.doWithDouble(5.0d));
        System.assertEquals('5', mock.doWithDecimal(6.0));
        System.assertEquals('6', mock.doWithDate(Date.newInstance(2022, 1, 7)));
        System.assertEquals('7', mock.doWithDatetime(Datetime.newInstance(2022, 1, 8)));
        System.assertEquals('9', mock.doWithId(ATK.fakeId(Account.SObjectType, 10)));
        System.assertEquals('10', mock.doWithString('11'));
        System.assertEquals('11', mock.doWithBoolean(false));
    }

    // #endregion
    // ================

    // ====================
    // #region Verification

    @IsTest
    static void test_then_for_verification_positive() {
        ATKMockTest mock = (ATKMockTest) ATK.mock(ATKMockTest.class, ATK.withSettings().lenient());

        mock.doWithInteger(1);
        mock.doWithInteger(2);
        mock.doWithInteger(2);
        mock.doWithIntegers(3, 4, 5);
        mock.doWithIntegers(3, 4, 5);
        mock.doWithIntegers(3, 4, 5);

        ((ATKMockTest) ATK.then(mock).should().never()).doWithInteger(0);
        ((ATKMockTest) ATK.then(mock).should().atMostOnce()).doWithInteger(0);

        ((ATKMockTest) ATK.then(mock).should().once()).doWithInteger(1);
        ((ATKMockTest) ATK.then(mock).should().atMostOnce()).doWithInteger(1);
        ((ATKMockTest) ATK.then(mock).should().atLeastOnce()).doWithInteger(1);

        ((ATKMockTest) ATK.then(mock).should().times(2)).doWithInteger(2);
        ((ATKMockTest) ATK.then(mock).should().atLeastOnce()).doWithInteger(2);
        ((ATKMockTest) ATK.then(mock).should().atLeast(2)).doWithInteger(2);
        ((ATKMockTest) ATK.then(mock).should().atMost(2)).doWithInteger(2);
        ((ATKMockTest) ATK.then(mock).should().atMost(3)).doWithInteger(2);

        ((ATKMockTest) ATK.then(mock).should().times(3)).doWithIntegers(3, 4, 5);
        ((ATKMockTest) ATK.then(mock).should().atLeast(2)).doWithIntegers(3, 4, 5);
        ((ATKMockTest) ATK.then(mock).should().atLeast(3)).doWithIntegers(3, 4, 5);
        ((ATKMockTest) ATK.then(mock).should().atMost(3)).doWithIntegers(3, 4, 5);
        ((ATKMockTest) ATK.then(mock).should().atMost(4)).doWithIntegers(3, 4, 5);
    }

    @IsTest
    static void test_then_for_verification_negative() {
        ATKMockTest mock = (ATKMockTest) ATK.mock(ATKMockTest.class, ATK.withSettings().lenient());

        mock.doWithInteger(0);
        mock.doWithInteger(0);

        ATK.MockException exp;
        try {
            ((ATKMockTest) ATK.then(mock).should().never()).doWithInteger(0);
        } catch (ATK.MockException ex) {
            exp = ex;
        }
        System.assert(exp != null);
        System.debug(exp.getMessage());
        exp = null;

        try {
            ((ATKMockTest) ATK.then(mock).should().once()).doWithIntegers(1, 2, 3);
        } catch (ATK.MockException ex) {
            exp = ex;
        }
        System.assert(exp != null);
        System.debug(exp.getMessage());
        exp = null;

        try {
            ((ATKMockTest) ATK.then(mock).should().times(3)).doWithIntegers(1, 2, 3);
        } catch (ATK.MockException ex) {
            exp = ex;
        }
        System.assert(exp != null);
        System.debug(exp.getMessage());
        exp = null;

        try {
            ((ATKMockTest) ATK.then(mock).should().atLeast(3)).doWithIntegers(1, 2, 3);
        } catch (ATK.MockException ex) {
            exp = ex;
        }
        System.assert(exp != null);
        System.debug(exp.getMessage());
        exp = null;

        try {
            ((ATKMockTest) ATK.then(mock).should().atLeastOnce()).doWithIntegers(1, 2, 3);
        } catch (ATK.MockException ex) {
            exp = ex;
        }
        System.assert(exp != null);
        System.debug(exp.getMessage());
        exp = null;

        try {
            ((ATKMockTest) ATK.then(mock).should().atMost(1)).doWithInteger(0);
        } catch (ATK.MockException ex) {
            exp = ex;
        }
        System.assert(exp != null);
        System.debug(exp.getMessage());
        exp = null;

        try {
            ((ATKMockTest) ATK.then(mock).should().atMostOnce()).doWithInteger(0);
        } catch (ATK.MockException ex) {
            exp = ex;
        }
        System.assert(exp != null);
        System.debug(exp.getMessage());
        exp = null;

        try {
            ATK.then(mock).should().haveNoInteractions();
        } catch (ATK.MockException ex) {
            exp = ex;
        }
        System.assert(exp != null);
        System.debug(exp.getMessage());
        exp = null;

        try {
            ATK.then(mock).should().haveNoMoreInteractions();
        } catch (ATK.MockException ex) {
            exp = ex;
        }
        System.assert(exp != null);
        System.debug(exp.getMessage());
        exp = null;
    }

    @IsTest
    static void test_then_for_verification_noorder() {
        ATKMockTest mock = (ATKMockTest) ATK.mock(ATKMockTest.class, ATK.withSettings().lenient());
        ATK.then(mock).should().haveNoInteractions();

        mock.doWithInteger(1);
        mock.doWithInteger(1);

        ((ATKMockTest) ATK.then(mock).should().times(2)).doWithInteger(1);
        ATK.then(mock).should().haveNoMoreInteractions();
    }

    @IsTest
    static void test_then_for_verification_inorder() {
        ATK.mock().withSettings().lenient().verbose();
        ATKMockTest mock = (ATKMockTest) ATK.mock(ATKMockTest.class);
        ATK.InOrder inOrder = ATK.inOrder(mock);
        ATK.then(mock).should().haveNoInteractions();

        mock.doWithInteger(1);

        {
            ATK.MockException exp;
            try {
                ATK.then(mock).should().haveNoInteractions();
            } catch (ATK.MockException ex) {
                exp = ex;
            }
            System.assertNotEquals(null, exp);
            System.debug(exp.getMessage());
        }

        mock.doWithInteger(1);
        mock.doWithInteger(1);
        mock.doWithInteger(2);
        mock.doWithInteger(1);

        {
            ATK.MockException exp;
            try {
                ((ATKMockTest) ATK.then(mock).should(inOrder).calls(4)).doWithInteger(1);
            } catch (ATK.MockException ex) {
                exp = ex;
            }
            System.assertNotEquals(null, exp);
            System.debug(exp.getMessage());
        }

        ((ATKMockTest) ATK.then(mock).should(inOrder).calls(1)).doWithInteger(1);
        ((ATKMockTest) ATK.then(mock).should(inOrder).times(2)).doWithInteger(1);
        ((ATKMockTest) ATK.then(mock).should(inOrder).once()).doWithInteger(2);

        {
            ATK.MockException exp;
            try {
                ATK.then(mock).should().haveNoMoreInteractions();
            } catch (ATK.MockException ex) {
                exp = ex;
            }
            System.assertNotEquals(null, exp);
            System.debug(exp.getMessage());
        }

        ((ATKMockTest) ATK.then(mock).should(inOrder).once()).doWithInteger(1);
        ATK.then(mock).should().haveNoMoreInteractions();
        ATK.then(mock).should(inOrder).haveNoMoreInteractions();
    }

    @IsTest
    static void test_then_for_verification_inorder_x2() {
        ATK.mock().withSettings().lenient();
        ATKMockTest mock1 = (ATKMockTest) ATK.mock(ATKMockTest.class, ATK.withSettings().name('mock1'));
        ATKMockTest mock2 = (ATKMockTest) ATK.mock(ATKMockTest.class, ATK.withSettings().name('mock2'));
        ATK.InOrder inOrder = ATK.inOrder(mock1, mock2);
        ATK.then(mock1).should().haveNoInteractions();
        ATK.then(mock2).should().haveNoInteractions();

        mock1.doWithInteger(1);

        {
            ATK.MockException exp;
            try {
                ATK.then(mock1).should().haveNoInteractions();
            } catch (ATK.MockException ex) {
                exp = ex;
            }
            System.assertNotEquals(null, exp);
            System.debug(exp.getMessage());
        }
        ATK.then(mock2).should().haveNoInteractions();

        mock1.doWithInteger(1);
        mock1.doWithInteger(1);
        mock2.doWithInteger(2);
        mock1.doWithInteger(1);

        ((ATKMockTest) ATK.then(mock1).should(inOrder).calls(1)).doWithInteger(1);
        ((ATKMockTest) ATK.then(mock1).should(inOrder).times(2)).doWithInteger(1);
        ((ATKMockTest) ATK.then(mock2).should(inOrder).once()).doWithInteger(2);

        {
            ATK.MockException exp;
            try {
                ATK.then(mock1).should().haveNoMoreInteractions();
            } catch (ATK.MockException ex) {
                exp = ex;
            }
            System.assertNotEquals(null, exp);
            System.debug(exp.getMessage());
        }

        ((ATKMockTest) ATK.then(mock1).should(inOrder).once()).doWithInteger(1);
        ATK.then(mock1).should().haveNoMoreInteractions();
        ATK.then(mock2).should().haveNoMoreInteractions();
        ATK.then(mock1).should(inOrder).haveNoMoreInteractions();
        ATK.then(mock2).should(inOrder).haveNoMoreInteractions();
        ATK.then(mock1).should().haveNoUnusedStubs();
        ATK.then(mock2).should().haveNoUnusedStubs();
    }

    // #endregion
    // ====================

    // ******************
    // #region Test Impls

    public class MockTestException extends Exception {
    }

    public class CustomAnswer implements ATK.Answer {
        String returnValue { get; set; }

        CustomAnswer(String returnValue) {
            this.returnValue = returnValue;
        }

        public Object answer(ATK.Invocation invocation) {
            return this.returnValue;
        }
    }
    public ATKMockTest doReturnSelf(Object param) {
        return null;
    }

    public ATKMockTest doReturnMock(Object param) {
        return null;
    }

    public void doReturnVoid() {
    }

    public Integer doReturnInteger() {
        return null;
    }

    public Long doReturnLong() {
        return null;
    }

    public Double doReturnDouble() {
        return null;
    }

    public Decimal doReturnDecimal() {
        return null;
    }

    public String doReturnString() {
        return null;
    }

    public Boolean doReturnBoolean() {
        return null;
    }

    public List<Account> doReturnAccountList() {
        return null;
    }

    public Set<Account> doReturnAccountSet() {
        return null;
    }

    public Map<Id, Account> doReturnAccountMap() {
        return null;
    }

    public Account doReturnAccount() {
        return null;
    }

    public SObject doReturnSObject() {
        return null;
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

    public String doWithObjects(ATKMockTest i1, Object i2, Object i3) {
        return null;
    }

    public String doWithList(List<Object> i) {
        return null;
    }

    public String doWithLists(List<ATKMockTest> i1, List<Object> i2, List<Object> i3) {
        return null;
    }

    public String doWithSet(Set<ATKMockTest> i) {
        return null;
    }

    public String doWithSets(Set<ATKMockTest> i1, Set<Object> i2, Set<Object> i3) {
        return null;
    }

    public String doWithMap(Map<String, ATKMockTest> i) {
        return null;
    }

    public String doWithMaps(Map<String, ATKMockTest> i1, Map<Object, Object> i2, Map<Object, Object> i3) {
        return null;
    }

    public String doWithSObject(SObject i) {
        return null;
    }

    public String doWithSObjects(List<SObject> i1) {
        return null;
    }

    // #endregion
    // ******************
}
