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

public with sharing virtual class ATKStub implements System.StubProvider {
    private static StubMap stubMap { get; set; }
    private static Stubbing stubbing { get; set; }
    private static Invocation invocation { get; set; }

    static {
        stubMap = new StubMap();
    }

    public static Object getInstance(Type mockType) {
        return stubMap.getInstance(mockType);
    }

    public static GivenStubbing setStubbing(GivenStubbing stubbing) {
        ATKStub.stubbing = stubbing;
        stubbing.invocation = invocation;
        return stubbing;
    }

    public static WillStubbing setStubbing(WillStubbing stubbing) {
        ATKStub.stubbing = stubbing;
        return stubbing;
    }

    public class StubMap {
        private Object getInstance(Type mockType) {
            ATKStub stub = new ATKStub();
            Object mock = Test.createStub(mockType, stub);
            return mock;
        }
    }

    private class MockHandler {

    }

    private class InvocationContainer {

    }

    private abstract class Stubbing {
        protected Invocation invocation { get; set; }
        protected List<Object> answers = new List<Object>();
    }

    public class GivenStubbing extends Stubbing implements ATK.Given {
        public GivenStubbing willReturn(Object obj) {
            answers.add(obj);
            return this;
        }

        public GivenStubbing willAnswer(ATK.Answer answer) {
            answers.add(answer);
            return this;
        }

        public GivenStubbing willThrow(Exception exp) {
            answers.add(exp);
            return this;
        }
    }

    public class WillStubbing extends Stubbing implements ATK.Will {
        public WillStubbing willReturn(Object obj) {
            answers.add(obj);
            return this;
        }

        public WillStubbing willAnswer(ATK.Answer answer) {
            answers.add(answer);
            return this;
        }

        public WillStubbing willThrow(Exception exp) {
            answers.add(exp);
            return this;
        }

        public WillStubbing willDoNothing() {
            answers.add(null);
            return this;
        }

        public Object given(Object mock) {
            return mock;
        }
    }

    public interface Answer extends ATK.Answer {

    }

    private class Invocation {
        Object mock { get; set; }
        String methodName { get; set; }
        Type returnType { get; set; }
        List<Type> paramTypes { get; set; }
        List<String> paramNames { get; set; }
        List<Object> listOfArgs { get; set; }
    }

    private class ArgumentMatcher {

    }

    public Object handleMethodCall(Object mock, String methodName,
        Type returnType, List<Type> paramTypes, List<String> paramNames,
        List<Object> listOfArgs) {

        Invocation invocation = new Invocation();
        invocation.mock = mock;
        invocation.methodName = methodName;
        invocation.returnType = returnType;
        invocation.paramTypes = paramTypes;
        invocation.paramNames = paramNames;
        invocation.listOfArgs = listOfArgs;
        ATKStub.invocation = invocation;

        if (ATKStub.stubbing != null && ATKStub.stubbing.invocation == null) {
            ATKStub.stubbing.invocation = invocation;
        }

        // The following debug statements show an example of logging
        // the invocation of a mocked method.

        // You can use the method name and return type to determine which method was called.
        System.debug('Name of stubbed method: ' + methodName);
        System.debug('Return type of stubbed method: ' + returnType.getName());

        // You can also use the parameter names and types to determine which method
        // was called.
        for (integer i =0; i < paramNames.size(); i++) {
            System.debug('parameter name: ' + paramNames.get(i));
            System.debug('  parameter type: ' + paramTypes.get(i).getName());
        }

        // This shows the actual parameter values passed into the stubbed method at runtime.
        System.debug('number of parameters passed into the mocked call: ' +
            listOfArgs.size());
        System.debug('parameter(s) sent into the mocked call: ' + listOfArgs);

        // This is a very simple mock provider that answers a hard-coded value
        // based on the return type of the invoked.
        if (returnType.getName() == 'String')
            return '8/8/2016';
        else
            return null;
    }
}
