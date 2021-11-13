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

public with sharing virtual class ATKMock implements System.StubProvider {
    private Map<Object, MockingDetail> detailByMock { get; set; }
    private Boolean isStubbing = false;

    private MockingDetail currentMockingDetail { get; set; }
    private Stubbing currentStubbing { get; set; }
    private Invocation currentInvocation { get; set; }

    {
        detailByMock = new Map<Object, MockingDetail>();
    }

    public void startStubbing() {
        this.isStubbing = true;
    }

    public void stopStubbing() {
        this.isStubbing = false;
    }

    public Object createMock(Type mockType) {
        MockingDetail mockingDetail = new MockingDetail(Test.createStub(mockType, this));
        this.detailByMock.put(mockingDetail.mock, mockingDetail);
        return mockingDetail.mock;
    }

    private MockingDetail getMockingDetail(Object mock) {
        MockingDetail mockingDetail = detailByMock.get(mock);
        return mockingDetail;
    }

    public GivenStubbing setGivenStubbing() {
        this.currentStubbing = new ATKMock.GivenStubbing();
        this.attachStubbing();
        return (ATKMock.GivenStubbing)this.currentStubbing;
    }

    public WillStubbing setWillStubbing() {
        this.currentStubbing = new ATKMock.WillStubbing();
        return (ATKMock.WillStubbing)this.currentStubbing;
    }

    // Method depends on state and creating side effects
    private void attachStubbing() {
        this.currentStubbing.invocation = this.currentInvocation;
        this.currentMockingDetail.stubbings.add(this.currentStubbing);
    }

    public Object handleMethodCall(Object mock, String methodName,
        Type returnType, List<Type> paramTypes, List<String> paramNames,
        List<Object> listOfArgs) {

        Invocation invocation = new Invocation( mock,  methodName,
         returnType,  paramTypes, paramNames, listOfArgs);
        invocation.debug();

        if (this.isStubbing) {
            this.currentMockingDetail = this.getMockingDetail(mock);
            this.currentInvocation = invocation;
            // End of Will Stubbing
            if (this.currentStubbing != null && this.currentStubbing instanceof WillStubbing) {
                this.attachStubbing();
            }
            return null;
        }

        return this.getMockingDetail(mock).invoke(invocation);
    }

    public ATK.ThenOf then(Object mock) {
        return this.getMockingDetail(mock);
    }

    public class MockingDetail implements ATK.ThenOf, ATK.Should {
        Object mock { get; set; }
        List<Stubbing> stubbings { get; set; }

        private MockingDetail(Object mock) {
            this.mock = mock;
            this.stubbings = new List<Stubbing>();
        }

        private Object invoke(Invocation invocation) {
            for (Stubbing stubbing : stubbings) {
                if (stubbing.invocation.method == invocation.method) {

                }
            }
            return null;
        }

        public ATK.Should should() {
            return this;
        }

        public ATK.Should should(ATK.InOrder inOrder) {
            return this;
        }

        public Object never() {
            return null;
        }

        public Object times(Integer times) {
            return null;
        }

        public Object atLeast(Integer times) {
            return null;
        }

        public Object atMost(Integer times) {
            return null;
        }

    }

    private abstract class Stubbing {
        protected Invocation invocation { get; set; }
        protected List<ATK.Answer> answers = new List<ATK.Answer>();
    }

    public class GivenStubbing extends Stubbing implements ATK.Given {
        public ATK.Given willReturn(Object value) {
            this.answers.add(new ValueAnswer(value));
            return this;
        }

        public ATK.Given willAnswer(ATK.Answer answer) {
            this.answers.add(answer);
            return this;
        }

        public ATK.Given willThrow(Exception exp) {
            this.answers.add(new ExceptionAnswer(exp));
            return this;
        }
    }

    public class WillStubbing extends Stubbing implements ATK.Will {
        public ATK.Will willReturn(Object value) {
            this.answers.add(new ValueAnswer(value));
            return this;
        }

        public ATK.Will willAnswer(ATK.Answer answer) {
            this.answers.add(answer);
            return this;
        }

        public ATK.Will willThrow(Exception exp) {
            this.answers.add(new ExceptionAnswer(exp));
            return this;
        }

        public ATK.Will willDoNothing() {
            this.answers.add(new VoidAnswer());
            return this;
        }

        public Object given(Object mock) {
            return mock;
        }
    }

    private interface Answer extends ATK.Answer {

    }

    private class ValueAnswer implements Answer {
        private Object value { get; set; }

        ValueAnswer(Object value) {
            this.value = value;
        }

        public Object answer(ATK.Invocation invocation) {
            return value;
        }
    }

    private class VoidAnswer implements Answer {
        public Object answer(ATK.Invocation invocation) {
            return null;
        }
    }

    private class ExceptionAnswer implements Answer {
        private Exception exp { get; set; }

        ExceptionAnswer(Exception exp) {
            this.exp = exp;
        }

        public Object answer(ATK.Invocation invocation) {
            throw exp;
        }
    }

    private class ArgumentMatcher {

    }

    private class MockHandler {
        private Object handle(Invocation invocation) {
            return null;
        }

        private InvocationContainer getInvocationContainer() {
            return null;
        }
    }

    private class InvocationContainer {

    }

    private class Method {
        String methodName { get; set; }
        List<Type> paramTypes { get; set; }
        List<String> paramNames { get; set; }
        Type returnType { get; set; }
    }

    private class Invocation implements ATK.Invocation {
        Method method { get; set; }
        List<Object> listOfArgs { get; set; }


        private Invocation(Object mock, String methodName,
            Type returnType, List<Type> paramTypes, List<String> paramNames,
            List<Object> listOfArgs) {
            this.method = new Method();
            this.method.methodName = methodName;
            this.method.returnType = returnType;
            this.method.paramTypes = paramTypes;
            this.method.paramNames = paramNames;
            this.listOfArgs = listOfArgs;
        }

        private void debug() {
            // The following debug statements show an example of logging
            // the invocation of a mocked method.

            // You can use the method name and return type to determine which method was called.
            System.debug('Name of stubbed method: ' + this.method.methodName);
            System.debug('Return type of stubbed method: ' + this.method.returnType.getName());

            // You can also use the parameter names and types to determine which method
            // was called.
            for (integer i =0; i < this.method.paramNames.size(); i++) {
                System.debug('parameter name: ' + this.method.paramNames.get(i));
                System.debug('  parameter type: ' + this.method.paramTypes.get(i).getName());
            }

            // This shows the actual parameter values passed into the stubbed method at runtime.
            System.debug('number of parameters passed into the mocked call: ' +
                this.listOfArgs.size());
            System.debug('parameter(s) sent into the mocked call: ' + this.listOfArgs);
        }
    }
}