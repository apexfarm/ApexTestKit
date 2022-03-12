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
    private Map<Object, Mock> mockByStub { get; set; }
    private Boolean isStubbing = false;

    private Mock currentMock { get; set; }
    private Stub currentStub { get; set; }
    private Invocation currentInvocation { get; set; }

    {
        mockByStub = new Map<Object, Mock>();
    }

    public void startStubbing() {
        this.isStubbing = true;
    }

    public void stopStubbing() {
        this.isStubbing = false;
    }

    public Mock createMock(Type mockType) {
        Mock mock = new Mock(Test.createStub(mockType, this));
        this.mockByStub.put(mock.stub, mock);
        return mock;
    }

    private Mock getMock(Object stub) {
        Mock mock = this.mockByStub.get(stub);
        return mock;
    }

    public Object handleMethodCall(Object stub, String methodName, Type returnType, List<Type> paramTypes, List<String> paramNames, List<Object> listOfArgs) {
        Invocation invocation = new Invocation(stub, methodName, returnType, paramTypes, paramNames, listOfArgs);
        invocation.debug();

        if (this.isStubbing) {
            this.currentMock = this.getMock(stub);
            this.currentInvocation = invocation;
            // End of Will Stub
            if (this.currentStub != null && this.currentStub instanceof WillStub) {
                this.attachStub();
            }
            return null;
        }

        return this.getMock(stub).invoke(invocation);
    }

    public GivenStub setGivenStub() {
        this.currentStub = new ATKMock.GivenStub();
        this.attachStub();
        return (ATKMock.GivenStub) this.currentStub;
    }

    public WillStub setWillStub() {
        this.currentStub = new ATKMock.WillStub();
        return (ATKMock.WillStub) this.currentStub;
    }

    // Method depends on state and creating side effects
    private void attachStub() {
        this.currentStub.invocation = this.currentInvocation;
        this.currentMock.stubs.add(this.currentStub);
    }

    public ATK.ThenOf then(Object mock) {
        return this.getMock(mock);
    }

    public class Mock implements ATK.ThenOf, ATK.Should {
        public Object stub { get; set; }
        List<Stub> stubs { get; set; }

        private Mock(Object stub) {
            this.stub = stub;
            this.stubs = new List<Stub>();
        }

        private Object invoke(Invocation invocation) {
            for (Stub stub : stubs) {
                if (stub.invocation.method == invocation.method) {
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

    private abstract class Stub {
        protected Invocation invocation { get; set; }
        protected List<ATK.Answer> answers = new List<ATK.Answer>();
    }

    public class GivenStub extends Stub implements ATK.Given {
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

    public class WillStub extends Stub implements ATK.Will {
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

        private Invocation(Object mock, String methodName, Type returnType, List<Type> paramTypes, List<String> paramNames, List<Object> listOfArgs) {
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
            for (integer i = 0; i < this.method.paramNames.size(); i++) {
                System.debug('parameter name: ' + this.method.paramNames.get(i));
                System.debug('  parameter type: ' + this.method.paramTypes.get(i).getName());
            }

            // This shows the actual parameter values passed into the stubbed method at runtime.
            System.debug('number of parameters passed into the mocked call: ' + this.listOfArgs.size());
            System.debug('parameter(s) sent into the mocked call: ' + this.listOfArgs);
        }
    }
}
