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
    public ArgumentManager argumentManager { get; set; }
    private Map<Object, Mock> mockByStub { get; set; }
    private Boolean isStubbing = false;

    private Mock currentMock { get; set; }
    private Stub currentStub { get; set; }
    private Invocation currentInvocation { get; set; }

    public class NonArgumentException extends Exception {
        String msg = 'Argument cannot be null.';

        {
            this.setMessage(msg);
        }
    }

    private static object validateNotNull(Object arg) {
        if (arg == null) {
            throw new NonArgumentException();
        }
        return arg;
    }

    {
        argumentManager = new ArgumentManager();
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
        this.mockByStub.put(mock.mock, mock);
        return mock;
    }

    private Mock getMock(Object mock) {
        return this.mockByStub.get(mock);
    }

    public Object handleMethodCall(Object mock, String methodName, Type returnType, List<Type> paramTypes, List<String> paramNames, List<Object> listOfArgs) {
        Invocation invocation = new Invocation();
        invocation.populate(mock, methodName, returnType, paramTypes, paramNames, listOfArgs);
        invocation.debug();

        if (this.isStubbing) {
            this.currentMock = this.getMock(mock);
            this.currentInvocation = invocation;

            if (!this.argumentManager.hasMatchers()) {
                for (Integer i = 0; i < paramTypes.size(); i++) {
                    Type type = paramTypes[i];
                    Object arg = listOfArgs[i];
                    this.argumentManager.eq(arg);
                }
            }

            // End of Will Stub
            if (this.currentStub != null && this.currentStub instanceof WillStub) {
                this.finalzieStub();
            }

            return null;
        }

        return this.getMock(mock).invoke(invocation);
    }

    public GivenStub setGivenStub() {
        ATKMock.GivenStub stub = new ATKMock.GivenStub();
        this.currentStub = stub;
        this.finalzieStub();
        return stub;
    }

    public WillStub setWillStub() {
        this.currentStub = new ATKMock.WillStub();
        return (ATKMock.WillStub) this.currentStub;
    }

    // Method depends on state and creating side effects
    private void finalzieStub() {
        this.currentStub.populate(this.currentInvocation);
        this.currentStub.matchers.addAll(this.argumentManager.matchers);
        this.currentMock.addStub(this.currentStub);

        this.argumentManager.reset();
        this.currentStub = null;
        this.currentMock = null;
    }

    public ATK.ThenOf then(Object mock) {
        return this.getMock(mock);
    }

    public class Mock implements ATK.ThenOf, ATK.Should {
        public Object mock { get; set; }
        Map<Method, List<Stub>> stubByMethod { get; set; }

        private Mock(Object mock) {
            this.mock = mock;
            this.stubByMethod = new Map<Method, List<Stub>>();
        }

        private void addStub(Stub stub) {
            if (!this.stubByMethod.containsKey(stub.method)) {
                this.stubByMethod.put(stub.method, new List<Stub>());
            }
            this.stubByMethod.get(stub.method).add(stub);
        }

        private Object invoke(Invocation invocation) {
            List<Stub> stubs = stubByMethod.get(invocation.method);
            for (Integer i = stubs.size(); i > 0; i--) {
                Stub stub = stubs[i - 1];
                if (stub.matches(invocation)) {
                    return stub.answer(invocation);
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

    private class Method {
        String name { get; set; }
        List<Type> paramTypes { get; set; }
        List<String> paramNames { get; set; }
        Type returnType { get; set; }
        String paramTypesName {
            get {
                List<String> typeNames = new List<String>();
                for (Type t : this.paramTypes) {
                    typeNames.add(t.getName());
                }
                return String.join(typeNames, '_');
            }
        }

        public Boolean equals(Object obj) {
            if (this === obj) {
                return true;
            }

            Method method = (Method) obj;
            return method != null && this.name == method.name && this.paramTypes == method.paramTypes;
        }

        public Integer hashCode() {
            return (31 * this.name.hashCode()) ^ this.paramTypes.hashCode();
        }
    }

    private virtual class Invocation implements ATK.Invocation {
        Method method { get; set; }
        List<Object> listOfArgs { get; set; }

        private void populate(Object mock, String methodName, Type returnType, List<Type> paramTypes, List<String> paramNames, List<Object> listOfArgs) {
            this.method = new Method();
            this.method.name = methodName;
            this.method.returnType = returnType;
            this.method.paramTypes = paramTypes;
            this.method.paramNames = paramNames;
            this.listOfArgs = listOfArgs;
        }

        private void debug() {
            // The following debug statements show an example of logging
            // the invocation of a mocked method.

            // You can use the method name and return type to determine which method was called.
            System.debug('Name of stubbed method: ' + this.method.name);
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

    private abstract class Stub extends Invocation implements Answer {
        protected List<ArgumentMatcher> matchers = new List<ArgumentMatcher>();
        protected List<ATK.Answer> answers = new List<ATK.Answer>();
        protected Integer answeredIndex = 0;

        private Boolean isConsecutive {
            get {
                return answers.size() > 1;
            }
        }

        private void populate(Invocation invocation) {
            this.method = invocation.method;
            this.listOfArgs = invocation.listOfArgs;
        }

        public Boolean matches(Invocation candidate) {
            if (this.method != candidate.method) {
                return false;
            }

            for (Integer i = 0; i < this.matchers.size(); i++) {
                Type type = candidate.method.paramTypes[i];
                Object arg = candidate.listOfArgs[i];

                if (!this.matchers[i].matches(type, arg)) {
                    return false;
                }
            }

            return true;
        }

        public Object answer(ATK.Invocation invocation) {
            if (this.hasNextAnswer()) {
                if (!this.isConsecutive) {
                    return this.answers[0].answer(invocation);
                } else {
                    return this.answers[this.answeredIndex++].answer(invocation);
                }
            }
            return null;
        }

        private Boolean hasNextAnswer() {
            return this.answers.size() > this.answeredIndex;
        }

        private void addAnswer(ATK.Answer answer) {
            this.answers.add(answer);
        }
    }

    public class GivenStub extends Stub implements ATK.Given {
        public ATK.Given willReturn(Object value) {
            this.addAnswer(new ValueAnswer(value));
            return this;
        }

        public ATK.Given willAnswer(ATK.Answer answer) {
            this.addAnswer(answer);
            return this;
        }

        public ATK.Given willThrow(Exception exp) {
            this.addAnswer(new ExceptionAnswer(exp));
            return this;
        }
    }

    public class WillStub extends Stub implements ATK.Will {
        public ATK.Will willReturn(Object value) {
            this.addAnswer(new ValueAnswer(value));
            return this;
        }

        public ATK.Will willAnswer(ATK.Answer answer) {
            this.addAnswer(answer);
            return this;
        }

        public ATK.Will willThrow(Exception exp) {
            this.addAnswer(new ExceptionAnswer(exp));
            return this;
        }

        public ATK.Will willDoNothing() {
            this.addAnswer(new VoidAnswer());
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

    // #region Argument Matchers
    public interface ArgumentMatcher extends ATK.ArgumentMatcher {
    }

    interface ArgumentMatcherCombo {
        void addMatcher(ArgumentMatcher matcher);
    }

    public virtual class ArgumentCaster implements ATK.ArgumentCaster {
        public Integer asInteger() {
            return null;
        }

        public Long asLong() {
            return null;
        }

        public Double asDouble() {
            return null;
        }

        public Decimal asDecimal() {
            return null;
        }

        public Date asDate() {
            return null;
        }

        public Datetime asDatetime() {
            return null;
        }

        public Boolean asBoolean() {
            return null;
        }

        public Id asId() {
            return null;
        }

        public String asString() {
            return null;
        }

        public Object asObject() {
            return null;
        }
    }

    // Type Matchers
    public class TypeMatcher implements ArgumentMatcher {
        Type type { get; set; }

        TypeMatcher(Type type) {
            this.type = type;
        }

        public Boolean matches(Type type, Object arg) {
            return this.type == type && arg != null;
        }
    }

    public class AnyTypeMatcher implements ArgumentMatcher {
        public Boolean matches(Type type, Object arg) {
            return true && arg != null;
        }
    }

    public class ListTypeMatcher implements ArgumentMatcher {
        public Boolean matches(Type type, Object arg) {
            return type.getName().startsWith('List<') && arg != null;
        }
    }

    public class SetTypeMatcher implements ArgumentMatcher {
        public Boolean matches(Type type, Object arg) {
            return type.getName().startsWith('Set<') && arg != null;
        }
    }

    public class MapTypeMatcher implements ArgumentMatcher {
        public Boolean matches(Type type, Object arg) {
            return type.getName().startsWith('Map<') && arg != null;
        }
    }

    // Value Matchers
    public virtual class NullMatcher extends ArgumentCaster implements ArgumentMatcher {
        public virtual Boolean matches(Type type, Object arg) {
            return arg == null;
        }
    }

    public class EqMatcher extends NullMatcher implements ArgumentMatcher {
        Object value { get; set; }

        EqMatcher(Object value) {
            this.value = value;
        }

        public override Boolean matches(Type type, Object arg) {
            return arg == value;
        }
    }

    public class GtMatcher extends ArgumentCaster implements ArgumentMatcher {
        Object value { get; set; }

        GtMatcher(Object value) {
            this.value = validateNotNull(value);
        }

        public Boolean matches(Type type, Object arg) {
            if (arg == null) {
                return false;
            }

            if (type == Integer.class) {
                return (Integer) arg > (Integer) this.value;
            } else if (type == Long.class) {
                return (Long) arg > (Long) this.value;
            } else if (type == Double.class) {
                return (Double) arg > (Double) this.value;
            } else if (type == Decimal.class) {
                return (Decimal) arg > (Decimal) this.value;
            } else if (type == Date.class) {
                return (Date) arg > (Date) this.value;
            } else if (type == Datetime.class) {
                return (Datetime) arg > (Datetime) this.value;
            } else if (type == String.class) {
                return (String) arg > (String) this.value;
            } else if (type == Id.class) {
                return (Id) arg > (Id) this.value;
            }
            return false;
        }
    }

    public class GteMatcher extends ArgumentCaster implements ArgumentMatcher {
        Object value { get; set; }

        GteMatcher(Object value) {
            this.value = validateNotNull(value);
        }

        public Boolean matches(Type type, Object arg) {
            if (arg == null) {
                return false;
            }

            if (type == Integer.class) {
                return (Integer) arg >= (Integer) this.value;
            } else if (type == Long.class) {
                return (Long) arg >= (Long) this.value;
            } else if (type == Double.class) {
                return (Double) arg >= (Double) this.value;
            } else if (type == Decimal.class) {
                return (Decimal) arg >= (Decimal) this.value;
            } else if (type == Date.class) {
                return (Date) arg >= (Date) this.value;
            } else if (type == Datetime.class) {
                return (Datetime) arg >= (Datetime) this.value;
            } else if (type == String.class) {
                return (String) arg >= (String) this.value;
            } else if (type == Id.class) {
                return (Id) arg >= (Id) this.value;
            }
            return false;
        }
    }

    public class LtMatcher extends ArgumentCaster implements ArgumentMatcher {
        Object value { get; set; }

        LtMatcher(Object value) {
            this.value = validateNotNull(value);
        }

        public Boolean matches(Type type, Object arg) {
            if (arg == null) {
                return false;
            }

            if (type == Integer.class) {
                return (Integer) arg < (Integer) this.value;
            } else if (type == Long.class) {
                return (Long) arg < (Long) this.value;
            } else if (type == Double.class) {
                return (Double) arg < (Double) this.value;
            } else if (type == Decimal.class) {
                return (Decimal) arg < (Decimal) this.value;
            } else if (type == Date.class) {
                return (Date) arg < (Date) this.value;
            } else if (type == Datetime.class) {
                return (Datetime) arg < (Datetime) this.value;
            } else if (type == String.class) {
                return (String) arg < (String) this.value;
            } else if (type == Id.class) {
                return (Id) arg < (Id) this.value;
            }
            return false;
        }
    }

    public class LteMatcher extends ArgumentCaster implements ArgumentMatcher {
        Object value { get; set; }

        LteMatcher(Object value) {
            this.value = validateNotNull(value);
        }

        public Boolean matches(Type type, Object arg) {
            if (arg == null) {
                return false;
            }

            if (type == Integer.class) {
                return (Integer) arg <= (Integer) this.value;
            } else if (type == Long.class) {
                return (Long) arg <= (Long) this.value;
            } else if (type == Double.class) {
                return (Double) arg <= (Double) this.value;
            } else if (type == Decimal.class) {
                return (Decimal) arg <= (Decimal) this.value;
            } else if (type == Date.class) {
                return (Date) arg <= (Date) this.value;
            } else if (type == Datetime.class) {
                return (Datetime) arg <= (Datetime) this.value;
            } else if (type == String.class) {
                return (String) arg <= (String) this.value;
            } else if (type == Id.class) {
                return (Id) arg <= (Id) this.value;
            }
            return false;
        }
    }

    public class BetweenMatcher extends ArgumentCaster implements ArgumentMatcher {
        Object minValue { get; set; }
        Object maxValue { get; set; }
        Boolean inclusive { get; set; }
        Boolean minInclusive { get; set; }
        Boolean maxInclusive { get; set; }

        BetweenMatcher(Object minValue, Object maxValue) {
            this(minValue, maxValue, false);
        }

        BetweenMatcher(Object minValue, Object maxValue, Boolean inclusive) {
            this.minValue = validateNotNull(minValue);
            this.maxValue = validateNotNull(maxValue);
            this.inclusive = inclusive;
            this.minInclusive = false;
            this.maxInclusive = false;
        }

        BetweenMatcher(Object minValue, Boolean minInclusive, Object maxValue, Boolean maxInclusive) {
            this(minValue, maxValue, minInclusive || maxInclusive);
            this.minInclusive = minInclusive;
            this.maxInclusive = maxInclusive;
        }

        public Boolean matches(Type type, Object arg) {
            if (arg == null) {
                return false;
            }

            if (!this.inclusive) {
                if (type == Integer.class) {
                    return (Integer) arg > (Integer) this.minValue && (Integer) arg < (Integer) this.maxValue;
                } else if (type == Long.class) {
                    return (Long) arg > (Long) this.minValue && (Long) arg < (Long) this.maxValue;
                } else if (type == Double.class) {
                    return (Double) arg > (Double) this.minValue && (Double) arg < (Double) this.maxValue;
                } else if (type == Decimal.class) {
                    return (Decimal) arg > (Decimal) this.minValue && (Decimal) arg < (Decimal) this.maxValue;
                } else if (type == Date.class) {
                    return (Date) arg > (Date) this.minValue && (Date) arg < (Date) this.maxValue;
                } else if (type == Datetime.class) {
                    return (Datetime) arg > (Datetime) this.minValue && (Datetime) arg < (Datetime) this.maxValue;
                } else if (type == String.class) {
                    return (String) arg > (String) this.minValue && (String) arg < (String) this.maxValue;
                } else if (type == Id.class) {
                    return (Id) arg > (Id) this.minValue && (Id) arg < (Id) this.maxValue;
                }
            }

            if (this.minInclusive) {
                if (type == Integer.class) {
                    return (Integer) arg >= (Integer) this.minValue && (Integer) arg < (Integer) this.maxValue;
                } else if (type == Long.class) {
                    return (Long) arg >= (Long) this.minValue && (Long) arg < (Long) this.maxValue;
                } else if (type == Double.class) {
                    return (Double) arg >= (Double) this.minValue && (Double) arg < (Double) this.maxValue;
                } else if (type == Decimal.class) {
                    return (Decimal) arg >= (Decimal) this.minValue && (Decimal) arg < (Decimal) this.maxValue;
                } else if (type == Date.class) {
                    return (Date) arg >= (Date) this.minValue && (Date) arg < (Date) this.maxValue;
                } else if (type == Datetime.class) {
                    return (Datetime) arg >= (Datetime) this.minValue && (Datetime) arg < (Datetime) this.maxValue;
                } else if (type == String.class) {
                    return (String) arg >= (String) this.minValue && (String) arg < (String) this.maxValue;
                } else if (type == Id.class) {
                    return (Id) arg >= (Id) this.minValue && (Id) arg < (Id) this.maxValue;
                }
            }

            if (this.maxInclusive) {
                if (type == Integer.class) {
                    return (Integer) arg > (Integer) this.minValue && (Integer) arg <= (Integer) this.maxValue;
                } else if (type == Long.class) {
                    return (Long) arg > (Long) this.minValue && (Long) arg <= (Long) this.maxValue;
                } else if (type == Double.class) {
                    return (Double) arg > (Double) this.minValue && (Double) arg <= (Double) this.maxValue;
                } else if (type == Decimal.class) {
                    return (Decimal) arg > (Decimal) this.minValue && (Decimal) arg <= (Decimal) this.maxValue;
                } else if (type == Date.class) {
                    return (Date) arg > (Date) this.minValue && (Date) arg <= (Date) this.maxValue;
                } else if (type == Datetime.class) {
                    return (Datetime) arg > (Datetime) this.minValue && (Datetime) arg <= (Datetime) this.maxValue;
                } else if (type == String.class) {
                    return (String) arg > (String) this.minValue && (String) arg <= (String) this.maxValue;
                } else if (type == Id.class) {
                    return (Id) arg > (Id) this.minValue && (Id) arg <= (Id) this.maxValue;
                }
            }

            if (this.inclusive) {
                if (type == Integer.class) {
                    return (Integer) arg >= (Integer) this.minValue && (Integer) arg <= (Integer) this.maxValue;
                } else if (type == Long.class) {
                    return (Long) arg >= (Long) this.minValue && (Long) arg <= (Long) this.maxValue;
                } else if (type == Double.class) {
                    return (Double) arg >= (Double) this.minValue && (Double) arg <= (Double) this.maxValue;
                } else if (type == Decimal.class) {
                    return (Decimal) arg >= (Decimal) this.minValue && (Decimal) arg <= (Decimal) this.maxValue;
                } else if (type == Date.class) {
                    return (Date) arg >= (Date) this.minValue && (Date) arg <= (Date) this.maxValue;
                } else if (type == Datetime.class) {
                    return (Datetime) arg >= (Datetime) this.minValue && (Datetime) arg <= (Datetime) this.maxValue;
                } else if (type == String.class) {
                    return (String) arg >= (String) this.minValue && (String) arg <= (String) this.maxValue;
                } else if (type == Id.class) {
                    return (Id) arg >= (Id) this.minValue && (Id) arg <= (Id) this.maxValue;
                }
            }

            return false;
        }
    }

    // Comobo Matchers
    public class AllMatcher implements ArgumentMatcher, ArgumentMatcherCombo {
        List<ArgumentMatcher> matchers { get; set; }

        AllMatcher() {
            matchers = new List<ArgumentMatcher>();
        }

        public void addMatcher(ArgumentMatcher matcher) {
            this.matchers.add(matcher);
        }

        public Boolean matches(Type type, Object arg) {
            Boolean hasMatched = true;
            for (ArgumentMatcher matcher : this.matchers) {
                if (!matcher.matches(type, arg)) {
                    hasMatched = false;
                    break;
                }
            }

            return hasMatched;
        }
    }

    public class AnyMatcher implements ArgumentMatcher, ArgumentMatcherCombo {
        List<ArgumentMatcher> matchers { get; set; }

        AnyMatcher() {
            matchers = new List<ArgumentMatcher>();
        }

        public void addMatcher(ArgumentMatcher matcher) {
            this.matchers.add(matcher);
        }

        public Boolean matches(Type type, Object arg) {
            Boolean hasMatched = false;
            for (ArgumentMatcher matcher : this.matchers) {
                if (matcher.matches(type, arg)) {
                    hasMatched = true;
                    break;
                }
            }

            return hasMatched;
        }
    }

    public class NoneMatcher implements ArgumentMatcher, ArgumentMatcherCombo {
        List<ArgumentMatcher> matchers { get; set; }

        NoneMatcher() {
            matchers = new List<ArgumentMatcher>();
        }

        public void addMatcher(ArgumentMatcher matcher) {
            this.matchers.add(matcher);
        }

        public Boolean matches(Type type, Object arg) {
            Boolean hasMatched = false;
            for (ArgumentMatcher matcher : this.matchers) {
                if (matcher.matches(type, arg)) {
                    hasMatched = true;
                    break;
                }
            }

            return !hasMatched;
        }
    }

    public class ArgumentManager implements ATK.ArgumentManager {
        Integer sequence { get; set; }
        Integer matchIndex { get; set; }
        List<ArgumentMatcher> matchers { get; set; }

        private ArgumentManager() {
            this.sequence = -2147483647;
            this.matchIndex = 0;
            this.matchers = new List<ArgumentMatcher>();
        }

        private void addMatcher(ArgumentMatcher matcher) {
            this.matchers.add(matcher);
        }

        private void reset() {
            this.sequence = -2147483647;
            this.matchIndex = 0;
            this.matchers.clear();
        }

        private Boolean hasMatchers() {
            return this.matchers.size() > 0;
        }

        private void moveMatcher(ArgumentMatcherCombo combo, Integer count) {
            for (Integer i = 0; i < count; i++) {
                ArgumentMatcher lastMatcher = this.matchers.remove(this.matchers.size() - 1);
                combo.addMatcher(lastMatcher);
            }
        }

        // Combo Matchers
        public Object allOf(Object o1, Object o2) {
            return this.allOf(new List<Object>{ o1, o2 });
        }

        public Object allOf(Object o1, Object o2, Object o3) {
            return this.allOf(new List<Object>{ o1, o2, o3 });
        }

        public Object allOf(Object o1, Object o2, Object o3, Object o4) {
            return this.allOf(new List<Object>{ o1, o2, o3, o4 });
        }

        public Object allOf(Object o1, Object o2, Object o3, Object o4, Object o5) {
            return this.allOf(new List<Object>{ o1, o2, o3, o4, o5 });
        }

        public Object allOf(List<Object> os) {
            ArgumentMatcherCombo combo = new AllMatcher();
            this.moveMatcher(combo, os.size());
            this.addMatcher((ArgumentMatcher) combo);
            return null;
        }

        public Object anyOf(Object o1, Object o2) {
            return this.anyOf(new List<Object>{ o1, o2 });
        }

        public Object anyOf(Object o1, Object o2, Object o3) {
            return this.anyOf(new List<Object>{ o1, o2, o3 });
        }

        public Object anyOf(Object o1, Object o2, Object o3, Object o4) {
            return this.anyOf(new List<Object>{ o1, o2, o3, o4 });
        }

        public Object anyOf(Object o1, Object o2, Object o3, Object o4, Object o5) {
            return this.anyOf(new List<Object>{ o1, o2, o3, o4, o5 });
        }

        public Object anyOf(List<Object> os) {
            ArgumentMatcherCombo combo = new AnyMatcher();
            this.moveMatcher(combo, os.size());
            this.addMatcher((ArgumentMatcher) combo);
            return null;
        }

        public Object isNot(Object o1) {
            return this.noneOf(new List<Object>{ o1 });
        }

        public Object noneOf(Object o1, Object o2) {
            return this.noneOf(new List<Object>{ o1, o2 });
        }

        public Object noneOf(Object o1, Object o2, Object o3) {
            return this.noneOf(new List<Object>{ o1, o2, o3 });
        }

        public Object noneOf(Object o1, Object o2, Object o3, Object o4) {
            return this.noneOf(new List<Object>{ o1, o2, o3, o4 });
        }

        public Object noneOf(Object o1, Object o2, Object o3, Object o4, Object o5) {
            return this.noneOf(new List<Object>{ o1, o2, o3, o4, o5 });
        }

        public Object noneOf(List<Object> os) {
            ArgumentMatcherCombo combo = new NoneMatcher();
            this.moveMatcher(combo, os.size());
            this.addMatcher((ArgumentMatcher) combo);
            return null;
        }

        // Type Matchers
        public Integer anyInteger() {
            this.addMatcher(new TypeMatcher(Integer.class));
            return null;
        }

        public Long anyLong() {
            this.addMatcher(new TypeMatcher(Long.class));
            return null;
        }

        public Double anyDouble() {
            this.addMatcher(new TypeMatcher(Double.class));
            return null;
        }

        public Decimal anyDecimal() {
            this.addMatcher(new TypeMatcher(Decimal.class));
            return null;
        }

        public Date anyDate() {
            this.addMatcher(new TypeMatcher(Date.class));
            return null;
        }

        public Datetime anyDatetime() {
            this.addMatcher(new TypeMatcher(Datetime.class));
            return null;
        }

        public Id anyId() {
            this.addMatcher(new TypeMatcher(Id.class));
            return null;
        }

        public String anyString() {
            this.addMatcher(new TypeMatcher(String.class));
            return null;
        }

        public Boolean anyBoolean() {
            this.addMatcher(new TypeMatcher(Boolean.class));
            return null;
        }

        public Object anyObject() {
            this.addMatcher(new AnyTypeMatcher());
            return null;
        }

        public List<Object> anyList() {
            this.addMatcher(new ListTypeMatcher());
            return null;
        }

        public Object anySet() {
            this.addMatcher(new SetTypeMatcher());
            return null;
        }

        public Object anyMap() {
            this.addMatcher(new MapTypeMatcher());
            return null;
        }

        // Value Matchers
        public ArgumentCaster isNull() {
            ArgumentCaster caster = new NullMatcher();
            this.addMatcher((ArgumentMatcher) caster);
            return caster;
        }

        public ArgumentCaster eq(Object value) {
            ArgumentCaster caster = new EqMatcher(value);
            this.addMatcher((ArgumentMatcher) caster);
            return caster;
        }

        public ArgumentCaster gt(Object value) {
            ArgumentCaster caster = new GtMatcher(value);
            this.addMatcher((ArgumentMatcher) caster);
            return caster;
        }

        public ArgumentCaster gte(Object value) {
            ArgumentCaster caster = new GteMatcher(value);
            this.addMatcher((ArgumentMatcher) caster);
            return caster;
        }

        public ArgumentCaster lt(Object value) {
            ArgumentCaster caster = new LtMatcher(value);
            this.addMatcher((ArgumentMatcher) caster);
            return caster;
        }

        public ArgumentCaster lte(Object value) {
            ArgumentCaster caster = new LteMatcher(value);
            this.addMatcher((ArgumentMatcher) caster);
            return caster;
        }

        public ArgumentCaster between(Object minValue, Object maxValue) {
            ArgumentCaster caster = new BetweenMatcher(minValue, maxValue);
            this.addMatcher((ArgumentMatcher) caster);
            return caster;
        }

        public ArgumentCaster between(Object minValue, Object maxValue, Boolean inclusive) {
            ArgumentCaster caster = new BetweenMatcher(minValue, maxValue, inclusive);
            this.addMatcher((ArgumentMatcher) caster);
            return caster;
        }

        public ArgumentCaster between(Object minValue, Boolean minInclusive, Object maxValue, Boolean maxInclusive) {
            ArgumentCaster caster = new BetweenMatcher(minValue, minInclusive, maxValue, maxInclusive);
            this.addMatcher((ArgumentMatcher) caster);
            return caster;
        }
    }

    // #endregion
}
