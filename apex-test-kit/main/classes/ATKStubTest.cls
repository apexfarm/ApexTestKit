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
public with sharing class ATKStubTest {
    @IsTest
    static void testMock() {
        MockException exp = new MockException();

        ATKStubTest mock = (ATKStubTest)ATK.mock(ATKStubTest.class);
        {// GIVEN
            ATK.given(mock.doWithInteger(0)).willReturn(0);
            ATK.given(mock.doWithInteger(ATK.anyInteger()))
                .willReturn(1)
                .willReturn(2);
            ATK.given(mock.doWithInteger(2)).willAnswer(new IntegerAnswer());
            ATK.given(mock.doWithInteger(3)).willThrow(exp);

            ((ATKStubTest)ATK.willReturn(4).willReturn(5).given(mock)).doWithInteger(4);
            ((ATKStubTest)ATK.willThrow(exp).given(mock)).doException(); // void method
            ((ATKStubTest)ATK.willDoNothing().given(mock)).doNothing();  // void method
        }

        {// WHEN
            mock.doWithInteger(0);
            mock.doWithInteger(1);
            mock.doWithInteger(2);
            try {
                mock.doWithInteger(3);
            } catch (MockException ex) {
            }
            mock.doWithInteger(4);

            try {
                mock.doException();
            } catch (MockException ex) {
            }
            mock.doNothing();
        }

        {// THEN
            ((ATKStubTest)ATK.then(mock).should().times(1)).doWithInteger(0);
            ((ATKStubTest)ATK.then(mock).should().atLeast(1)).doWithInteger(ATK.anyInteger());
            ((ATKStubTest)ATK.then(mock).should().atMost(1)).doWithInteger(2);
            ((ATKStubTest)ATK.then(mock).should().never()).doWithInteger(5);

            ATK.InOrder inOrder = ATK.inOrder(mock);
            ((ATKStubTest)ATK.then(mock).should(inOrder).times(1)).doWithInteger(0);
            ((ATKStubTest)ATK.then(mock).should(inOrder).atLeast(1)).doWithInteger(ATK.anyInteger());
            ((ATKStubTest)ATK.then(mock).should(inOrder).times(1)).doWithInteger(2);
            ((ATKStubTest)ATK.then(mock).should(inOrder).times(1)).doWithInteger(3);
        }
    }

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

    public Object doWithInteger(Integer i) {
        return i;
    }
}
