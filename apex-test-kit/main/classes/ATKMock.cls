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

public with sharing class ATKMock implements System.StubProvider {
    public static ArgumentManager argumentManager { get; set; }
    private static Invocation currentInvocation { get; set; }
    private static MatchableInvocation currentMatchable { get; set; }
    private static VerificationMode verificationMode { get; set; }

    private InvocationContainer container { get; set; }
    private Boolean isStubbing = false;
    private Boolean isVerifying = false;

    public class NonArgumentException extends Exception {
        String msg = 'Argument cannot be null.';

        {
            this.setMessage(msg);
        }
    }

    public class NotStartStubbingException extends Exception {
        String msg = 'startStubbing() is not called';

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
        container = new InvocationContainer();
    }

    public void startStubbing() {
        this.isStubbing = true;
    }

    public void stopStubbing() {
        if (!this.isStubbing) {
            throw new NotStartStubbingException();
        }
        this.isStubbing = false;
    }

    private void startVerifying() {
        this.isVerifying = true;
    }

    private void stopVerifying() {
        this.isVerifying = false;
    }

    public Object createMock(Type mockType) {
        return Test.createStub(mockType, this);
    }

    public Object handleMethodCall(Object mock, String methodName, Type returnType, List<Type> paramTypes, List<String> paramNames, List<Object> arguments) {
        Invocation invocation = new Invocation(mock, methodName, returnType, paramTypes, paramNames, arguments);

        System.debug(mock);
        System.debug(returnType);

        if (this.isStubbing || this.isVerifying) {
            this.currentInvocation = invocation;
            if (!this.argumentManager.hasMatchers()) {
                for (Object arg : arguments) {
                    this.argumentManager.eq(arg);
                }
            }

            // WillStub ends here
            if (this.isStubbing && this.currentMatchable != null) {
                this.attach();
                this.reset();
            }

            // ThenStub ends here
            if (this.isVerifying && this.currentMatchable != null) {
                try {
                    this.attach();
                    this.verificationMode.verify(this.container, this.currentMatchable);
                } catch (ATK.VerificationException exp) {
                    throw exp;
                } finally {
                    this.stopVerifying();
                    this.reset();
                }
            }

            if (invocation.mockClassName == returnType.getName()) {
                return mock;
            } else {
                return null;
            }
        }

        this.container.addInvocation(invocation);
        return this.container.invoke(invocation);
    }

    private void attach() {
        this.currentMatchable.populate(this.currentInvocation);
        this.currentMatchable.populate(this.argumentManager.matchers);
        if (this.isStubbing) {
            this.container.addInvocation(this.currentMatchable);
        }
    }

    private void reset() {
        this.argumentManager.reset();
        this.currentInvocation = null;
        this.currentMatchable = null;
        this.verificationMode = null;
    }

    public GivenStubbing createGivenStub() {
        GivenStubbing givenStub = new GivenStubbing();
        this.currentMatchable = givenStub.invocation;
        this.attach();
        this.reset();
        return givenStub;
    }

    public WillStubbing createWillStub() {
        WillStubbing willStub = new WillStubbing();
        this.currentMatchable = willStub.invocation;
        return willStub;
    }

    public ThenStubbing createThenStub(Object mock) {
        this.startVerifying();
        ThenStubbing thenStub = new ThenStubbing(mock);
        this.currentMatchable = thenStub.invocation;
        this.verificationMode = thenStub.mode;
        return thenStub;
    }

    public InOrder createInOrder(List<Object> mocks) {
        return new InOrder(mocks);
    }

    public class GivenStubbing implements ATK.Given {
        StubbedInvocation invocation = new StubbedInvocation();

        public ATK.Given willReturn(Object value) {
            this.invocation.addAnswer(new ValueAnswer(value));
            return this;
        }

        public ATK.Given willAnswer(ATK.Answer answer) {
            this.invocation.addAnswer(answer);
            return this;
        }

        public ATK.Given willThrow(Exception exp) {
            this.invocation.addAnswer(new ExceptionAnswer(exp));
            return this;
        }

        public ATK.Given willDoNothing() {
            this.invocation.addAnswer(new VoidAnswer());
            return this;
        }
    }

    public class WillStubbing implements ATK.Will {
        StubbedInvocation invocation = new StubbedInvocation();

        public ATK.Will willReturn(Object value) {
            this.invocation.addAnswer(new ValueAnswer(value));
            return this;
        }

        public ATK.Will willAnswer(ATK.Answer answer) {
            this.invocation.addAnswer(answer);
            return this;
        }

        public ATK.Will willThrow(Exception exp) {
            this.invocation.addAnswer(new ExceptionAnswer(exp));
            return this;
        }

        public ATK.Will willDoNothing() {
            this.invocation.addAnswer(new VoidAnswer());
            return this;
        }

        public Object given(Object mock) {
            return mock;
        }
    }

    public class ThenStubbing implements ATK.ThenOf, ATK.GreedyShould, ATK.InOrderShould {
        MatchableInvocation invocation { get; set; }
        Object mock { get; set; }
        VerificationMode mode { get; set; }

        ThenStubbing(Object mock) {
            this.mock = mock;
            this.invocation = new MatchableInvocation();
            this.mode = new verificationMode();
        }

        public ATK.GreedyShould should() {
            this.mode.addMode(new AnyOrderVerificationMode());
            return this;
        }

        public ATK.InOrderShould should(ATK.InOrder inOrder) {
            this.mode.addMode(new InOrderVerificationMode((InOrder) inOrder));
            return this;
        }

        public Object never() {
            this.mode.addMode(new TimesVerificationMode(0));
            return this.mock;
        }

        public Object once() {
            this.mode.addMode(new TimesVerificationMode(1));
            return this.mock;
        }

        public Object times(Integer times) {
            this.mode.addMode(new TimesVerificationMode(times));
            return this.mock;
        }

        public Object atLeast(Integer times) {
            this.mode.addMode(new AtLeastVerificationMode(times));
            return this.mock;
        }

        public Object atLeastOnce() {
            this.mode.addMode(new AtLeastVerificationMode(1));
            return this.mock;
        }

        public Object atMost(Integer times) {
            this.mode.addMode(new AtMostVerificationMode(times));
            return this.mock;
        }

        public Object atMostOnce() {
            this.mode.addMode(new AtMostVerificationMode(1));
            return this.mock;
        }

        public void haveNoInteractions() {
        }

        public void haveNoMoreInteractions() {
        }

        // none-greedy
        public Object calls(Integer n) {
            return this.mock;
        }
    }

    private interface InOrderContext {
        Boolean isVerified(Invocation invocation);
        void markVerified(Invocation invocation);
    }

    public virtual class NoOrder implements ATK.InOrder, InOrderContext {
        Set<Invocation> invocations { get; set; }

        NoOrder() {
            this.invocations = new Set<Invocation>();
        }

        public Boolean isVerified(Invocation invocation) {
            return this.invocations.contains(invocation);
        }

        public void markVerified(Invocation invocation) {
            this.invocations.add(invocation);
        }
    }

    public class InOrder extends NoOrder implements ATK.InOrder, InOrderContext {
        List<Object> mocks { get; set; }

        InOrder(List<Object> mocks) {
            super();
            this.mocks = mocks;
        }
    }

    // ====================
    // #region Verificatoin
    //=====================
    public virtual class VerificationMode {
        VerificationMode innerMode { get; set; }

        public void addMode(verificationMode mode) {
            if (this.innerMode == null) {
                this.innerMode = mode;
            } else {
                this.innerMode.addMode(mode);
            }
        }

        public virtual void verify(InvocationContainer container, MatchableInvocation invocation) {
            List<Invocation> occurrences = this.findMatchingChuck(container, invocation);
            this.verify(occurrences.size(), invocation);
        }

        public virtual void verify(Integer occurrences, MatchableInvocation invocation) {
            if (this.innerMode != null) {
                this.innerMode.verify(occurrences, invocation);
            }
        }

        protected virtual List<Invocation> findMatchingChuck(InvocationContainer container, MatchableInvocation invocation) {
            if (this.innerMode != null) {
                return this.innerMode.findMatchingChuck(container, invocation);
            }
            return new List<Invocation>();
        }
    }

    public class AnyOrderVerificationMode extends VerificationMode {
        protected override List<Invocation> findMatchingChuck(InvocationContainer container, MatchableInvocation invocation) {
            List<Invocation> occurrences = new List<Invocation>();
            for (Invocation candidate : container.invocations) {
                if (invocation.matches(candidate)) {
                    occurrences.add(invocation);
                }
            }
            return occurrences;
        }
    }

    public class InOrderVerificationMode extends VerificationMode {
        InOrder inOrder { get; set; }

        InOrderVerificationMode(InOrder inOrder) {
            this.inOrder = inOrder;
        }

        public override void verify(InvocationContainer container, MatchableInvocation invocation) {
            // List<Invocation> unverifiedInvocations = this.removeVerified(container.invocations, this.inOrder);
            // List<List<Invocation>> invocations = this.findMatchingChuck(unverifiedInvocations, invocation);
            // this.verifyInOrder();
        }
    }

    public class TimesVerificationMode extends VerificationMode {
        Integer times { get; set; }

        TimesVerificationMode(Integer times) {
            this.times = (Integer) validateNotNull(times);
        }

        public override void verify(Integer occurrences, MatchableInvocation invocation) {
            if (occurrences != this.times) {
                throw new ATK.VerificationException(
                    String.format('Expected "[{0}].{1}" to be called {2} time(s). But has been called {3} time(s).', new List<Object>{ invocation.mockClassName, invocation, this.times, occurrences })
                );
            }
        }
    }

    public class AtLeastVerificationMode extends VerificationMode {
        Integer times { get; set; }

        AtLeastVerificationMode(Integer times) {
            this.times = (Integer) validateNotNull(times);
        }

        public override void verify(Integer occurrences, MatchableInvocation invocation) {
            if (occurrences < this.times) {
                throw new ATK.VerificationException(
                    String.format(
                        'Expected "[{0}].{1}" to be called at least {2} time(s). But has been called {3} time(s).',
                        new List<Object>{ invocation.mockClassName, invocation, this.times, occurrences }
                    )
                );
            }
        }
    }

    public class AtMostVerificationMode extends VerificationMode {
        Integer times { get; set; }

        AtMostVerificationMode(Integer times) {
            this.times = (Integer) validateNotNull(times);
        }

        public override void verify(Integer occurrences, MatchableInvocation invocation) {
            if (occurrences > this.times) {
                throw new ATK.VerificationException(
                    String.format(
                        'Expected "[{0}].{1}" to be called at most {2} time(s). But has been called {3} time(s).',
                        new List<Object>{ invocation.mockClassName, invocation, this.times, occurrences }
                    )
                );
            }
        }
    }

    // #endregion
    // ====================

    // ===================
    // #region Invocations
    // ===================

    private class InvocationContainer {
        List<Invocation> invocations { get; set; }
        List<StubbedInvocation> stubbedInvocations { get; set; }

        InvocationContainer() {
            this.invocations = new List<Invocation>();
            this.stubbedInvocations = new List<StubbedInvocation>();
        }

        private void addInvocation(Invocation invocation) {
            if (invocation instanceof StubbedInvocation) {
                this.stubbedInvocations.add((StubbedInvocation) invocation);
            } else {
                this.invocations.add(invocation);
            }
        }

        private Object invoke(Invocation candidate) {
            for (Integer i = this.stubbedInvocations.size(); i > 0; i--) {
                StubbedInvocation stub = this.stubbedInvocations[i - 1];
                if (stub.matches(candidate)) {
                    return stub.answer(candidate);
                }
            }
            return (new VoidAnswer()).answer(candidate);
        }
    }

    private virtual class MatchableInvocation extends Invocation {
        protected List<ArgumentMatcher> matchers = new List<ArgumentMatcher>();

        private void populate(Invocation invocation) {
            this.mock = invocation.mock;
            this.method = invocation.method;
            this.arguments = invocation.arguments;
        }

        private void populate(List<ArgumentMatcher> matchers) {
            this.matchers = matchers;
        }

        public Boolean matches(Invocation candidate) {
            if (this.mock != candidate.mock || this.method != candidate.method) {
                return false;
            }

            for (Integer i = 0; i < this.matchers.size(); i++) {
                Type type = candidate.method.paramTypes[i];
                Object arg = candidate.arguments[i];

                if (!this.matchers[i].matches(type, arg)) {
                    return false;
                }
            }

            return true;
        }

        public override String toString() {
            List<String> matcherNames = new List<String>();

            for (ArgumentMatcher matcher : matchers) {
                matcherNames.add(String.valueOf(matcher));
            }

            return this.method.name + '(' + String.join(matcherNames, ', ') + ')';
        }
    }

    private class StubbedInvocation extends MatchableInvocation implements Answer {
        protected List<ATK.Answer> answers = new List<ATK.Answer>();
        protected Integer answeredIndex = 0;

        private Boolean isConsecutive {
            get {
                return answers.size() > 1;
            }
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

    private virtual class Invocation extends ATK.Invocation {
        public String mockClassName {
            get {
                return String.valueOf(this.mock).split('__sfdc_ApexStub:')[0];
            }
        }

        Invocation() {
        }

        Invocation(Invocation invocation) {
            this.mock = invocation.mock;
            this.method = invocation.method;
            this.arguments = invocation.arguments;
        }

        Invocation(Object mock, String methodName, Type returnType, List<Type> paramTypes, List<String> paramNames, List<Object> arguments) {
            this.mock = mock;
            this.method = new Method(methodName, returnType, paramTypes, paramNames);
            this.arguments = arguments;
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
            System.debug('number of parameters passed into the mocked call: ' + this.arguments.size());
            System.debug('parameter(s) sent into the mocked call: ' + this.arguments);
        }
    }

    public class Method extends ATK.Method {
        Method(String methodName, Type returnType, List<Type> paramTypes, List<String> paramNames) {
            this.name = methodName;
            this.returnType = returnType;
            this.paramTypes = paramTypes;
            this.paramNames = paramNames;
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

    // #endregion
    // ===================

    // =====================
    // #region Type Matchers
    // =====================

    public class AnyMatcher implements ArgumentMatcher {
        public Boolean matches(Type type, Object arg) {
            return true;
        }

        public override String toString() {
            return 'ATK.any()';
        }
    }

    public class AnyTypeMatcher implements ArgumentMatcher {
        Type type { get; set; }

        AnyTypeMatcher(Type type) {
            this.type = (Type) validateNotNull(type);
        }

        public Boolean matches(Type type, Object arg) {
            if (arg == null) {
                return false;
            }

            if (this.type == SObject.class) {
                return arg instanceof SObject;
            }

            if (this.type == List<SObject>.class) {
                return arg instanceof List<SObject>;
            }

            return this.type == type;
        }

        public override String toString() {
            return 'ATK.any(' + this.type.getName() + '.class)';
        }
    }

    public class NullableTypeMatcher implements ArgumentMatcher {
        Type type { get; set; }

        NullableTypeMatcher(Type type) {
            this.type = (Type) validateNotNull(type);
        }

        public Boolean matches(Type type, Object arg) {
            return this.type == type;
        }

        public override String toString() {
            return 'ATK.nullable(' + this.type.getName() + '.class)';
        }
    }

    public class ListTypeMatcher implements ArgumentMatcher {
        public Boolean matches(Type type, Object arg) {
            return arg != null && arg instanceof List<Object>;
        }

        public override String toString() {
            return 'ATK.anyList()';
        }
    }

    public class SetTypeMatcher implements ArgumentMatcher {
        public Boolean matches(Type type, Object arg) {
            return arg != null && type.getName().startsWith('Set<');
        }

        public override String toString() {
            return 'ATK.anySet()';
        }
    }

    public class MapTypeMatcher implements ArgumentMatcher {
        public Boolean matches(Type type, Object arg) {
            return arg != null && type.getName().startsWith('Map<');
        }

        public override String toString() {
            return 'ATK.anyMap()';
        }
    }

    // #endregion
    // =====================

    // ======================
    // #region Value Matchers
    // ======================

    public class NullMatcher extends ArgumentCaster implements ArgumentMatcher {
        Boolean isNull { get; set; }

        NullMatcher(Boolean isNull) {
            this.isNull = isNull;
        }

        public Boolean matches(Type type, Object arg) {
            if (this.isNull) {
                return arg == null;
            }
            return arg != null;
        }

        public override String toString() {
            return 'ATK.' + (this.isNull ? 'isNull()' : 'isNotNull()');
        }
    }

    public class SameMatcher implements ArgumentMatcher {
        Object value { get; set; }

        SameMatcher(Object value) {
            this.value = value;
        }

        public Boolean matches(Type type, Object arg) {
            return arg === value;
        }

        public override String toString() {
            return 'ATK.same(' + String.valueOf(this.value) + ')';
        }
    }

    public class NeMatcher extends ArgumentCaster implements ArgumentMatcher {
        Object value { get; set; }

        NeMatcher(Object value) {
            this.value = value;
        }

        public Boolean matches(Type type, Object arg) {
            return arg != value;
        }

        public override String toString() {
            return 'ATK.ne(' + String.valueOf(this.value) + ')';
        }
    }

    public class EqMatcher extends ArgumentCaster implements ArgumentMatcher {
        Object value { get; set; }

        EqMatcher(Object value) {
            this.value = value;
        }

        public Boolean matches(Type type, Object arg) {
            return arg == value;
        }

        public override String toString() {
            return 'ATK.eq(' + String.valueOf(this.value) + ')';
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
            } else if (type == Time.class) {
                return (Time) arg > (Time) this.value;
            } else if (type == String.class) {
                return (String) arg > (String) this.value;
            } else if (type == Id.class) {
                return (Id) arg > (Id) this.value;
            }
            return false;
        }

        public override String toString() {
            return 'ATK.gt(' + String.valueOf(this.value) + ')';
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
            } else if (type == DateTime.class) {
                return (DateTime) arg >= (DateTime) this.value;
            } else if (type == Time.class) {
                return (Time) arg >= (Time) this.value;
            } else if (type == String.class) {
                return (String) arg >= (String) this.value;
            } else if (type == Id.class) {
                return (Id) arg >= (Id) this.value;
            }
            return false;
        }

        public override String toString() {
            return 'ATK.gte(' + String.valueOf(this.value) + ')';
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
            } else if (type == Time.class) {
                return (Time) arg < (Time) this.value;
            } else if (type == String.class) {
                return (String) arg < (String) this.value;
            } else if (type == Id.class) {
                return (Id) arg < (Id) this.value;
            }
            return false;
        }

        public override String toString() {
            return 'ATK.lt(' + String.valueOf(this.value) + ')';
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
            } else if (type == Time.class) {
                return (Time) arg <= (Time) this.value;
            } else if (type == String.class) {
                return (String) arg <= (String) this.value;
            } else if (type == Id.class) {
                return (Id) arg <= (Id) this.value;
            }
            return false;
        }

        public override String toString() {
            return 'ATK.lte(' + String.valueOf(this.value) + ')';
        }
    }

    public class BetweenMatcher extends ArgumentCaster implements ArgumentMatcher {
        Object minValue { get; set; }
        Object maxValue { get; set; }
        Boolean inclusive { get; set; }
        Boolean minInclusive { get; set; }
        Boolean maxInclusive { get; set; }

        BetweenMatcher(Object minValue, Object maxValue) {
            this(minValue, maxValue, true);
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
                } else if (type == Time.class) {
                    return (Time) arg > (Time) this.minValue && (Time) arg < (Time) this.maxValue;
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
                } else if (type == Time.class) {
                    return (Time) arg >= (Time) this.minValue && (Time) arg < (Time) this.maxValue;
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
                } else if (type == Time.class) {
                    return (Time) arg > (Time) this.minValue && (Time) arg <= (Time) this.maxValue;
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
                } else if (type == Time.class) {
                    return (Time) arg >= (Time) this.minValue && (Time) arg <= (Time) this.maxValue;
                } else if (type == String.class) {
                    return (String) arg >= (String) this.minValue && (String) arg <= (String) this.maxValue;
                } else if (type == Id.class) {
                    return (Id) arg >= (Id) this.minValue && (Id) arg <= (Id) this.maxValue;
                }
            }

            return false;
        }

        public override String toString() {
            return 'ATK.between(' + String.valueOf(this.minValue) + ', ' + String.valueOf(this.maxValue) + ')';
        }
    }

    public class IsBlankMatcher implements ArgumentMatcher {
        Boolean isBlank { get; set; }

        IsBlankMatcher(Boolean isBlank) {
            this.isBlank = isBlank;
        }

        public Boolean matches(Type type, Object arg) {
            if (this.isBlank) {
                return String.isBlank((String) arg);
            }
            return String.isNotBlank((String) arg);
        }

        public override String toString() {
            return 'ATK.' + (this.isBlank ? 'isBlank()' : 'isNotBlank()');
        }
    }

    public class ContainsMatcher implements ArgumentMatcher {
        String value { get; set; }

        ContainsMatcher(String value) {
            this.value = (String) validateNotNull(value);
        }

        public Boolean matches(Type type, Object arg) {
            return arg != null && ((String) arg).contains(this.value);
        }

        public override String toString() {
            return 'ATK.contains(\'' + String.valueOf(this.value) + '\')';
        }
    }

    public class StartsWithMatcher implements ArgumentMatcher {
        String value { get; set; }

        StartsWithMatcher(String value) {
            this.value = (String) validateNotNull(value);
        }

        public Boolean matches(Type type, Object arg) {
            return arg != null && ((String) arg).startsWith(this.value);
        }

        public override String toString() {
            return 'ATK.startsWith(\'' + String.valueOf(this.value) + '\')';
        }
    }

    public class EndsWithMatcher implements ArgumentMatcher {
        String value { get; set; }

        EndsWithMatcher(String value) {
            this.value = (String) validateNotNull(value);
        }

        public Boolean matches(Type type, Object arg) {
            return arg != null && ((String) arg).endsWith(this.value);
        }

        public override String toString() {
            return 'ATK.endsWith(\'' + String.valueOf(this.value) + '\')';
        }
    }

    public class RegExpMatcher implements ArgumentMatcher {
        String regexp { get; set; }
        Pattern regExpPattern { get; set; }

        RegExpMatcher(String regexp) {
            this.regexp = (String) validateNotNull(regexp);
            this.regExpPattern = Pattern.compile(regexp);
        }

        public Boolean matches(Type type, Object arg) {
            if (arg == null) {
                return false;
            }

            System.Matcher matcher = this.regExpPattern.matcher((String) arg);
            return matcher.matches();
        }

        public override String toString() {
            return 'ATK.matches(\'' + this.regexp + '\')';
        }
    }

    public class SObjectFieldMatcher implements ArgumentMatcher {
        String fieldName { get; set; }
        Object value { get; set; }

        SObjectFieldMatcher(String fieldName, Object value) {
            validateNotNull(fieldName);
            this.fieldName = fieldName;
            this.value = value;
        }

        SObjectFieldMatcher(SObjectField field, Object value) {
            validateNotNull(field);
            DescribeFieldResult dfr = field.getDescribe();
            this.fieldName = dfr.getName();
            this.value = value;
        }

        public Boolean matches(Type type, Object arg) {
            if (arg == null || !(arg instanceof SObject)) {
                return false;
            }
            SObject sobj = (SOBject) arg;
            return sobj.get(this.fieldName) == value;
        }

        public override String toString() {
            return 'ATK.sObjectWith(' + this.fieldName + ', ' + String.valueOf(this.value) + ')';
        }
    }

    public class SObjectMatcher implements ArgumentMatcher {
        List<SObjectFieldMatcher> matchers { get; set; }

        SObjectMatcher(Map<SObjectField, Object> matchRules) {
            validateNotNull(matchRules);
            this.matchers = new List<SObjectFieldMatcher>();
            for (SObjectField field : matchRules.keySet()) {
                this.matchers.add(new SObjectFieldMatcher(field, matchRules.get(field)));
            }
        }

        public Boolean matches(Type type, Object arg) {
            for (SObjectFieldMatcher matcher : matchers) {
                if (!matcher.matches(type, arg)) {
                    return false;
                }
            }

            return true;
        }

        public override String toString() {
            return 'ATK.sObjectWith()';
        }
    }

    public class SObjectListMatcher implements ArgumentMatcher {
        List<ArgumentMatcher> matchers { get; set; }

        SObjectListMatcher(SObjectField field, Object value) {
            this.matchers = new List<ArgumentMatcher>();
            this.matchers.add(new SObjectFieldMatcher(field, value));
        }

        SObjectListMatcher(Map<SObjectField, Object> matchRules) {
            validateNotNull(matchRules);
            this.matchers = new List<ArgumentMatcher>();
            for (SObjectField field : matchRules.keySet()) {
                this.matchers.add(new SObjectFieldMatcher(field, matchRules.get(field)));
            }
        }

        public Boolean matches(Type type, Object arg) {
            if (arg == null || !(arg instanceof List<SObject>)) {
                return false;
            }
            List<SObject> sobjs = (List<SOBject>) arg;

            for (SObject sobj : sobjs) {
                for (ArgumentMatcher matcher : this.matchers) {
                    if (!matcher.matches(SObjectType.class, sobj)) {
                        return false;
                    }
                }
            }

            return true;
        }

        public override String toString() {
            return 'ATK.sObjectListWith()';
        }
    }

    public class MultiSObjectListMatcher implements ArgumentMatcher {
        List<ArgumentMatcher> matchers { get; set; }
        Boolean inOrder { get; set; }

        MultiSObjectListMatcher(List<Map<SObjectField, Object>> matchRulesList, Boolean inOrder) {
            validateNotNull(matchRulesList);
            this.matchers = new List<ArgumentMatcher>();
            this.inOrder = inOrder;

            for (Map<SObjectField, Object> matchRules : matchRulesList) {
                this.matchers.add(new SObjectMatcher(matchRules));
            }
        }

        public Boolean matches(Type type, Object arg) {
            if (arg == null || !(arg instanceof List<SObject>)) {
                return false;
            }
            List<SObject> sobjs = (List<SOBject>) arg;

            if (this.matchers.size() != sobjs.size()) {
                return false;
            }

            if (this.inOrder) {
                for (Integer i = 0; i < sobjs.size(); i++) {
                    SObject sobj = sobjs[i];
                    ArgumentMatcher matcher = this.matchers[i];
                    if (!matcher.matches(SObjectType.class, sobj)) {
                        return false;
                    }
                }
                return true;
            }

            List<Integer> matchedIndexes = new List<Integer>();
            for (Integer i = 0; i < sobjs.size(); i++) {
                SObject sobj = sobjs[i];
                for (Integer j = 0; j < matchers.size(); j++) {
                    if (matchedIndexes.contains(j)) {
                        continue;
                    }
                    ArgumentMatcher matcher = this.matchers[j];
                    if (matcher.matches(SObjectType.class, sobj)) {
                        matchedIndexes.add(j);
                        break;
                    }
                }
            }

            return matchedIndexes.size() == sobjs.size();
        }

        public override String toString() {
            return 'ATK.sObjectListWith()';
        }
    }

    // #endregion
    // ======================

    // =======================
    // #region Comobo Matchers
    // ======================

    public abstract class ComboMatcher {
        protected List<ArgumentMatcher> matchers { get; set; }

        ComboMatcher() {
            matchers = new List<ArgumentMatcher>();
        }

        public void addMatcher(ArgumentMatcher matcher) {
            this.matchers.add(matcher);
        }

        protected List<String> matcherNames() {
            List<String> matcherNames = new List<String>();

            for (ArgumentMatcher matcher : this.matchers) {
                matcherNames.add(String.valueOf(matcher));
            }

            return matcherNames;
        }
    }

    public class AllOfMatcher extends ComboMatcher implements ArgumentMatcher {
        public Boolean matches(Type type, Object arg) {
            for (ArgumentMatcher matcher : this.matchers) {
                if (!matcher.matches(type, arg)) {
                    return false;
                }
            }

            return true;
        }

        public override String toString() {
            return 'ATK.allOf(' + String.join(this.matcherNames(), ', ') + ')';
        }
    }

    public class AnyOfMatcher extends ComboMatcher implements ArgumentMatcher {
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

        public override String toString() {
            return 'ATK.anyOf(' + String.join(this.matcherNames(), ', ') + ')';
        }
    }

    public class NoneOfMatcher extends ComboMatcher implements ArgumentMatcher {
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

        public override String toString() {
            return 'ATK.noneOf(' + String.join(this.matcherNames(), ', ') + ')';
        }
    }

    // #endregion
    // ======================

    public class ArgumentManager implements ATK.ArgumentManager {
        List<ArgumentMatcher> matchers { get; set; }

        private ArgumentManager() {
            this.matchers = new List<ArgumentMatcher>();
        }

        private void addMatcher(ArgumentMatcher matcher) {
            this.matchers.add(matcher);
        }

        private void reset() {
            this.matchers = new List<ArgumentMatcher>();
        }

        private Boolean hasMatchers() {
            return this.matchers.size() > 0;
        }

        private void moveMatchers(ComboMatcher combo, Integer size) {
            for (Integer i = size; i > 0; i--) {
                ArgumentMatcher matcher = this.matchers.remove(this.matchers.size() - i);
                combo.addMatcher(matcher);
            }
        }

        private void removeMatchers(Integer size) {
            for (Integer i = 0; i < size; i++) {
                this.matchers.remove(this.matchers.size() - 1);
            }
        }

        // #region Combo Matchers
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
            ComboMatcher combo = new AllOfMatcher();
            this.moveMatchers(combo, os.size());
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
            ComboMatcher combo = new AnyOfMatcher();
            this.moveMatchers(combo, os.size());
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
            ComboMatcher combo = new NoneOfMatcher();
            this.moveMatchers(combo, os.size());
            this.addMatcher((ArgumentMatcher) combo);
            return null;
        }

        // #endregion

        // #region Type Matchers
        public Integer anyInteger() {
            this.addMatcher(new AnyTypeMatcher(Integer.class));
            return null;
        }

        public Long anyLong() {
            this.addMatcher(new AnyTypeMatcher(Long.class));
            return null;
        }

        public Double anyDouble() {
            this.addMatcher(new AnyTypeMatcher(Double.class));
            return null;
        }

        public Decimal anyDecimal() {
            this.addMatcher(new AnyTypeMatcher(Decimal.class));
            return null;
        }

        public Date anyDate() {
            this.addMatcher(new AnyTypeMatcher(Date.class));
            return null;
        }

        public Datetime anyDatetime() {
            this.addMatcher(new AnyTypeMatcher(Datetime.class));
            return null;
        }

        public Time anyTime() {
            this.addMatcher(new AnyTypeMatcher(Time.class));
            return null;
        }

        public Id anyId() {
            this.addMatcher(new AnyTypeMatcher(Id.class));
            return null;
        }

        public String anyString() {
            this.addMatcher(new AnyTypeMatcher(String.class));
            return null;
        }

        public Boolean anyBoolean() {
            this.addMatcher(new AnyTypeMatcher(Boolean.class));
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

        public Object any() {
            this.addMatcher(new AnyMatcher());
            return null;
        }

        public Object any(Type type) {
            this.addMatcher(new AnyTypeMatcher(type));
            return null;
        }

        public Object nullable(Type type) {
            this.addMatcher(new NullableTypeMatcher(type));
            return null;
        }

        public SObject anySObject() {
            this.addMatcher(new AnyTypeMatcher(SObject.class));
            return null;
        }

        public List<SObject> anySObjectList() {
            this.addMatcher(new AnyTypeMatcher(List<SObject>.class));
            return null;
        }

        // #endregion

        // #region Value Matchers
        public Object isNull() {
            this.addMatcher(new NullMatcher(true));
            return null;
        }

        public Object isNotNull() {
            this.addMatcher(new NullMatcher(false));
            return null;
        }

        public Object same(Object value) {
            this.addMatcher(new SameMatcher(value));
            return null;
        }

        public Object ne(Object value) {
            this.addMatcher(new NeMatcher(value));
            return null;
        }

        public Integer neInteger(Integer value) {
            ArgumentCaster caster = new NeMatcher(value);
            this.addMatcher((ArgumentMatcher) caster);
            return caster.asInteger();
        }

        public Long neLong(Long value) {
            ArgumentCaster caster = new NeMatcher(value);
            this.addMatcher((ArgumentMatcher) caster);
            return caster.asLong();
        }

        public Double neDouble(Double value) {
            ArgumentCaster caster = new NeMatcher(value);
            this.addMatcher((ArgumentMatcher) caster);
            return caster.asDouble();
        }

        public Decimal neDecimal(Decimal value) {
            ArgumentCaster caster = new NeMatcher(value);
            this.addMatcher((ArgumentMatcher) caster);
            return caster.asDecimal();
        }

        public Date neDate(Date value) {
            ArgumentCaster caster = new NeMatcher(value);
            this.addMatcher((ArgumentMatcher) caster);
            return caster.asDate();
        }

        public Datetime neDatetime(Datetime value) {
            ArgumentCaster caster = new NeMatcher(value);
            this.addMatcher((ArgumentMatcher) caster);
            return caster.asDatetime();
        }

        public Id neId(Id value) {
            ArgumentCaster caster = new NeMatcher(value);
            this.addMatcher((ArgumentMatcher) caster);
            return caster.asId();
        }

        public String neString(String value) {
            ArgumentCaster caster = new NeMatcher(value);
            this.addMatcher((ArgumentMatcher) caster);
            return caster.asString();
        }

        public Boolean neBoolean(Boolean value) {
            ArgumentCaster caster = new NeMatcher(value);
            this.addMatcher((ArgumentMatcher) caster);
            return caster.asBoolean();
        }

        public Object eq(Object value) {
            this.addMatcher(new EqMatcher(value));
            return null;
        }

        public Integer eqInteger(Integer value) {
            ArgumentCaster caster = new EqMatcher(value);
            this.addMatcher((ArgumentMatcher) caster);
            return caster.asInteger();
        }

        public Long eqLong(Long value) {
            ArgumentCaster caster = new EqMatcher(value);
            this.addMatcher((ArgumentMatcher) caster);
            return caster.asLong();
        }

        public Double eqDouble(Double value) {
            ArgumentCaster caster = new EqMatcher(value);
            this.addMatcher((ArgumentMatcher) caster);
            return caster.asDouble();
        }

        public Decimal eqDecimal(Decimal value) {
            ArgumentCaster caster = new EqMatcher(value);
            this.addMatcher((ArgumentMatcher) caster);
            return caster.asDecimal();
        }

        public Date eqDate(Date value) {
            ArgumentCaster caster = new EqMatcher(value);
            this.addMatcher((ArgumentMatcher) caster);
            return caster.asDate();
        }

        public Datetime eqDatetime(Datetime value) {
            ArgumentCaster caster = new EqMatcher(value);
            this.addMatcher((ArgumentMatcher) caster);
            return caster.asDatetime();
        }

        public Id eqId(Id value) {
            ArgumentCaster caster = new EqMatcher(value);
            this.addMatcher((ArgumentMatcher) caster);
            return caster.asId();
        }

        public String eqString(String value) {
            ArgumentCaster caster = new EqMatcher(value);
            this.addMatcher((ArgumentMatcher) caster);
            return caster.asString();
        }

        public Boolean eqBoolean(Boolean value) {
            ArgumentCaster caster = new EqMatcher(value);
            this.addMatcher((ArgumentMatcher) caster);
            return caster.asBoolean();
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

        public String isBlank() {
            this.addMatcher(new IsBlankMatcher(true));
            return null;
        }

        public String isNotBlank() {
            this.addMatcher(new IsBlankMatcher(false));
            return null;
        }

        public String contains(String value) {
            this.addMatcher(new ContainsMatcher(value));
            return null;
        }

        public String startsWith(String value) {
            this.addMatcher(new StartsWithMatcher(value));
            return null;
        }

        public String endsWith(String value) {
            this.addMatcher(new EndsWithMatcher(value));
            return null;
        }

        public String matches(String regexp) {
            this.addMatcher(new RegExpMatcher(regexp));
            return null;
        }

        public SObject sObjectWithId(Id value) {
            this.addMatcher(new SObjectFieldMatcher('Id', value));
            return null;
        }

        public SObject sObjectWithName(String value) {
            this.addMatcher(new SObjectFieldMatcher('Name', value));
            return null;
        }

        public SObject sObjectWith(SObjectField field, Object value) {
            this.addMatcher(new SObjectFieldMatcher(field, value));
            return null;
        }

        public SObject sObjectWith(Map<SObjectField, Object> value) {
            this.addMatcher(new SObjectMatcher(value));
            return null;
        }

        public LIst<SObject> sObjectListWith(SObjectField field, Object value) {
            this.addMatcher(new SObjectListMatcher(field, value));
            return null;
        }

        public LIst<SObject> sObjectListWith(Map<SObjectField, Object> value) {
            this.addMatcher(new SObjectListMatcher(value));
            return null;
        }

        public LIst<SObject> sObjectListWith(List<Map<SObjectField, Object>> value, Boolean inOrder) {
            this.addMatcher(new MultiSObjectListMatcher(value, inOrder));
            return null;
        }
        // #endregion
    }

    public interface ArgumentMatcher extends ATK.Matcher {
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
}
