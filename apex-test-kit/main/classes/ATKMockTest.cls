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
    static void testMock() {
        MockException exp = new MockException();

        ATKMockTest mock = (ATKMockTest) ATK.mock(ATKMockTest.class);
        {
            // GIVEN
            ATK.startStubbing();
            ATK.given(mock.doWithInteger(0)).willReturn(0);
            ATK.given(mock.doWithInteger(ATK.anyInteger())).willReturn(1).willReturn(2);
            ATK.given(mock.doWithInteger(2)).willAnswer(new IntegerAnswer());
            ATK.given(mock.doWithInteger(3)).willThrow(exp);

            ((ATKMockTest) ATK.willReturn(4).willReturn(5).given(mock)).doWithInteger(4);
            ((ATKMockTest) ATK.willThrow(exp).given(mock)).doException(); // void method
            ((ATKMockTest) ATK.willDoNothing().given(mock)).doNothing(); // void method
            ATK.stopStubbing();
        }

        {
            // WHEN
            System.assertEquals(0, mock.doWithInteger(0));
            System.assertEquals(1, mock.doWithInteger(99));
            System.assertEquals(2, mock.doWithInteger(99));
            System.assertEquals(null, mock.doWithInteger(99));
            System.assertEquals(2, mock.doWithInteger(2));

            MockException exp2;
            try {
                exp2 = null;
                mock.doWithInteger(3);
            } catch (MockException ex) {
                exp2 = ex;
            }
            System.assertEquals(exp, exp2);

            System.assertEquals(4, mock.doWithInteger(4));
            System.assertEquals(5, mock.doWithInteger(4));

            try {
                exp2 = null;
                mock.doException();
            } catch (MockException ex) {
                exp2 = ex;
            }
            System.assertEquals(exp, exp2);

            mock.doNothing();
        }

        {
            // THEN
            ((ATKMockTest) ATK.then(mock).should().times(1)).doWithInteger(0);
            ((ATKMockTest) ATK.then(mock).should().times(1)).doException();
            ((ATKMockTest) ATK.then(mock).should().times(1)).doNothing();

            ((ATKMockTest) ATK.then(mock).should().times(8)).doWithInteger(ATK.anyInteger());

            ((ATKMockTest) ATK.then(mock).should().times(2)).doWithInteger(4);
            ((ATKMockTest) ATK.then(mock).should().atLeast(2)).doWithInteger(4);
            ((ATKMockTest) ATK.then(mock).should().atMost(2)).doWithInteger(4);

            ((ATKMockTest) ATK.then(mock).should().never()).doWithInteger(5);

            // ATK.InOrder inOrder = ATK.inOrder(mock);
            // ((ATKMockTest)ATK.then(mock).should(inOrder).times(1)).doWithInteger(0);
            // ((ATKMockTest)ATK.then(mock).should(inOrder).atLeast(1)).doWithInteger(ATK.anyInteger());
            // ((ATKMockTest)ATK.then(mock).should(inOrder).times(1)).doWithInteger(2);
            // ((ATKMockTest)ATK.then(mock).should(inOrder).times(1)).doWithInteger(3);
        }
    }

    // ******************
    // #region Test Impls

    public class MockException extends Exception {
    }

    public class IntegerAnswer implements ATK.Answer {
        public Object answer(ATK.Invocation invocation) {
            return 2;
        }
    }

    public void doNothing() {
    }

    public void doException() {
    }

    public Integer doWithInteger(Integer i) {
        return null;
    }

    // #endregion
    // ******************
}
