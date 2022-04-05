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

public with sharing class ATKMock {
    public static final MockingProgress progress = new MockingProgress();
    public static final InvocationFinder INVOCATION_FINDER = new InvocationFinder();
    public static final Answer DEFAULT_ANSWERS = new DefaultAnswer();
    public static final Answer NULL_ANSWERS = new NullAnswer();
    public static final Answer SELF_ANSWERS = new SelfAnswer();
    public static final Answer MOCK_ANSWERS = new MockAnswer(progress);
    private static Map<String, SObjectType> globalDescribe { get; set; }

    private static Boolean isSObjectType(Type type) {
        if (globalDescribe == null) {
            globalDescribe = Schema.getGlobalDescribe();
        }

        return globalDescribe.containsKey(type.getName());
    }

    private static object validateNotNull(Object arg) {
        if (arg == null) {
            throw new NonArgumentException();
        }
        return arg;
    }

    public class MockHandler implements System.StubProvider {
        public Object handleMethodCall(Object mock, String methodName, Type returnType, List<Type> paramTypes, List<String> paramNames, List<Object> arguments) {
            Invocation invocation = new Invocation(progress.getMockSettings(mock), mock, methodName, returnType, paramTypes, paramNames, arguments);

            if (progress.isStubbing || progress.isVerifying) {
                progress.currentInvocation = invocation;
                if (!progress.matcherRecorder.hasMatchers()) {
                    for (Object arg : arguments) {
                        progress.matcherRecorder.eq(arg);
                    }
                }

                progress.currentMatchers = progress.matcherRecorder.matchers;
                progress.matcherRecorder.reset();

                // WillStub ends here
                if (progress.isStubbing && progress.currentMatchable != null) {
                    progress.attach();
                    progress.reset();
                }

                // ThenStub ends here
                if (progress.isVerifying && progress.currentMatchable != null) {
                    try {
                        progress.attach();
                        progress.currentVerificationMode.verify(progress.container, progress.currentMatchable);
                    } catch (ATK.VerificationException exp) {
                        throw exp;
                    } finally {
                        progress.reset();
                    }
                }

                return progress.container.defaultAnswer(invocation);
            }

            progress.container.addInvocation(invocation);
            return progress.container.answer(invocation, progress.context);
        }
    }

    public class MockingProgress {
        private final MockHandler mockHandler { get; set; }
        private final InvocationContainer container { get; set; }
        private final VerificationContext context { get; set; }

        // temporary states
        public final MatcherRecorder matcherRecorder { get; set; }
        private MatchableInvocation currentMatchable { get; set; }
        private List<ArgumentMatcher> currentMatchers { get; set; }
        private Invocation currentInvocation { get; set; }
        private VerificationModeWrapper currentVerificationMode { get; set; }
        private Boolean isStubbing = false;
        private Boolean isVerifying = false;

        public MockingProgress() {
            this.mockHandler = new MockHandler();
            this.container = new InvocationContainer();
            this.context = new VerificationContext(new Set<Object>());
            this.matcherRecorder = new MatcherRecorder();
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

        private void attach() {
            this.currentMatchable.populate(this.currentInvocation, this.currentMatchers);
            if (this.isStubbing) {
                this.container.addInvocation(this.currentMatchable);
            }
        }

        private void reset() {
            this.matcherRecorder.reset();
            this.currentMatchers = null;
            this.currentInvocation = null;
            this.currentMatchable = null;
            this.currentVerificationMode = null;
            this.stopVerifying();
        }

        private MockSettings getMockSettings(Object mock) {
            return this.container.mockSettings.get(mock);
        }

        private void putMockSettings(Object mock, MockSettings settings) {
            this.container.mockSettings.put(mock, settings);
        }

        public Object createMock(Type mockType) {
            return this.createMock(mockType, mockType.getName(), DEFAULT_ANSWERS, false, false);
        }

        public Object createMock(Type mockType, ATK.Answer defaultAnswer) {
            return this.createMock(mockType, mockType.getName(), defaultAnswer, false, false);
        }

        public Object createMock(Type mockType, ATK.MockSettings settings) {
            return this.createMock(mockType, ((MockSettings) settings).mockName, ((MockSettings) settings).defaultAnswer, ((MockSettings) settings).lenient, ((MockSettings) settings).isStubOnly);
        }

        private Object createMock(Type mockType, String name, ATK.Answer defaultAnswer, Boolean lenient, Boolean isStubOnly) {
            Object mock = Test.createStub(mockType, mockHandler);
            MockSettings settings = new MockSettings(mock, mockType, name, defaultAnswer, lenient, isStubOnly);
            this.putMockSettings(mock, settings);
            return mock;
        }

        public GivenStubbing createGivenStub() {
            GivenStubbing givenStub = new GivenStubbing();
            this.currentMatchable = givenStub.matchable;
            this.attach();
            this.reset();
            return givenStub;
        }

        public WillStubbing createWillStub() {
            WillStubbing willStub = new WillStubbing();
            this.currentMatchable = willStub.matchable;
            return willStub;
        }

        public ThenStubbing createThenStub(Object mock) {
            this.startVerifying();
            ThenStubbing thenStub = new ThenStubbing(mock, this);
            this.currentMatchable = thenStub.matchable;
            return thenStub;
        }

        public ATK.InOrder createInOrder(List<Object> mocks) {
            return new VerificationContext(new Set<Object>(mocks));
        }

        private void haveNoInteractions(Object mock) {
            try {
                this.currentMatchable.mock = mock;
                this.currentMatchable.mockSetting = this.getMockSettings(mock);
                this.currentVerificationMode.verify(
                    INVOCATION_FINDER.findMatchingChuckByMock(this.container.invocations, this.currentVerificationMode.context, mock),
                    this.currentMatchable,
                    this.currentVerificationMode.context
                );
            } catch (ATK.VerificationException exp) {
                throw exp;
            } finally {
                this.reset();
            }
        }

        private void haveNoMoreInteractions(Object mock) {
            try {
                this.currentMatchable.mock = mock;
                this.currentMatchable.mockSetting = this.getMockSettings(mock);
                this.currentVerificationMode.verify(
                    INVOCATION_FINDER.findUnverifiedByMock(this.container.invocations, this.currentVerificationMode.context, mock),
                    this.currentMatchable,
                    this.currentVerificationMode.context
                );
            } catch (ATK.VerificationException exp) {
                throw exp;
            } finally {
                this.reset();
            }
        }
    }

    public class GivenStubbing implements ATK.Given {
        StubbedInvocation matchable = new StubbedInvocation();

        public ATK.Given willReturn(Object value) {
            this.matchable.addAnswer(new ValueAnswer(value));
            return this;
        }

        public ATK.Given willAnswer(ATK.Answer answer) {
            this.matchable.addAnswer(answer);
            return this;
        }

        public ATK.Given willThrow(Exception exp) {
            this.matchable.addAnswer(new ExceptionAnswer(exp));
            return this;
        }

        public ATK.Given willDoNothing() {
            this.matchable.addAnswer(NULL_ANSWERS);
            return this;
        }
    }

    public class WillStubbing implements ATK.Will {
        StubbedInvocation matchable = new StubbedInvocation();

        public ATK.Will willReturn(Object value) {
            this.matchable.addAnswer(new ValueAnswer(value));
            return this;
        }

        public ATK.Will willAnswer(ATK.Answer answer) {
            this.matchable.addAnswer(answer);
            return this;
        }

        public ATK.Will willThrow(Exception exp) {
            this.matchable.addAnswer(new ExceptionAnswer(exp));
            return this;
        }

        public ATK.Will willDoNothing() {
            this.matchable.addAnswer(NULL_ANSWERS);
            return this;
        }

        public Object given(Object mock) {
            return mock;
        }
    }

    public class ThenStubbing implements ATK.ThenOf, ATK.Should, ATK.InOrderShould {
        private Object mock { get; set; }
        private MockingProgress progress { get; set; }
        private MatchableInvocation matchable { get; set; }
        private VerificationModeWrapper mode { get; set; }

        ThenStubbing(Object mock, MockingProgress progress) {
            this.mock = mock;
            this.progress = progress;
            this.matchable = new MatchableInvocation();
        }

        public ATK.Should should() {
            this.mode = new NoOrderVerificationMode(this.progress.context);
            this.progress.currentVerificationMode = this.mode;
            return this;
        }

        public ATK.InOrderShould should(ATK.InOrder inOrder) {
            this.mode = new InOrderVerificationMode((VerificationContext) inOrder);
            this.progress.currentVerificationMode = this.mode;
            return this;
        }

        public Object never() {
            this.mode.wrap(new TimesVerificationMode(0));
            return this.mock;
        }

        public Object once() {
            this.mode.wrap(new TimesVerificationMode(1));
            return this.mock;
        }

        public Object times(Integer times) {
            this.mode.wrap(new TimesVerificationMode(times));
            return this.mock;
        }

        public Object atLeast(Integer times) {
            this.mode.wrap(new AtLeastVerificationMode(times));
            return this.mock;
        }

        public Object atLeastOnce() {
            this.mode.wrap(new AtLeastVerificationMode(1));
            return this.mock;
        }

        public Object atMost(Integer times) {
            this.mode.wrap(new AtMostVerificationMode(times));
            return this.mock;
        }

        public Object atMostOnce() {
            this.mode.wrap(new AtMostVerificationMode(1));
            return this.mock;
        }

        public void haveNoInteractions() {
            this.mode.wrap(new NoInteractionVerificationMode());
            this.progress.haveNoInteractions(this.mock);
        }

        public void haveNoMoreInteractions() {
            this.mode.wrap(new NoMoreInteractionVerificationMode());
            this.progress.haveNoMoreInteractions(this.mock);
        }

        // none-greedy
        public Object calls(Integer n) {
            this.mode.wrap(new CallsVerificationMode(n));
            return this.mock;
        }
    }

    // ===================
    // #region Invocations
    // ===================

    public class MockSettings implements ATK.MockSettings {
        private Object mock { get; set; }
        private Type mockType { get; set; }
        private String mockName { get; set; }
        private ATK.Answer defaultAnswer { get; set; }
        private Boolean lenient { get; set; }
        private Boolean isStubOnly { get; set; }

        public MockSettings() {
            this.defaultAnswer = DEFAULT_ANSWERS;
            this.lenient = false;
            this.isStubOnly = false;
        }

        private MockSettings(Object mock, Type mockType, string mockName, ATK.Answer defaultAnswer, Boolean lenient, Boolean isStubOnly) {
            this.mock = mock;
            this.mockType = mockType;
            this.mockName = String.isBlank(mockName) ? mockType.getName() : mockName;
            this.defaultAnswer = defaultAnswer == null ? DEFAULT_ANSWERS : defaultAnswer;
            this.lenient = lenient == null ? false : lenient;
            this.isStubOnly = isStubOnly == null ? false : isStubOnly;
        }

        public MockSettings name(String name) {
            this.mockName = name;
            return this;
        }

        public MockSettings defaultAnswer(ATK.Answer answer) {
            this.defaultAnswer = answer;
            return this;
        }

        public MockSettings stubOnly() {
            this.isStubOnly = true;
            return this;
        }

        public MockSettings lenient() {
            this.lenient = true;
            return this;
        }
    }

    private class InvocationContainer {
        private List<Invocation> invocations { get; set; }
        private List<StubbedInvocation> stubbedInvocations { get; set; }
        private Map<Object, MockSettings> mockSettings { get; set; }

        private InvocationContainer() {
            this.invocations = new List<Invocation>();
            this.stubbedInvocations = new List<StubbedInvocation>();
            this.mockSettings = new Map<Object, MockSettings>();
        }

        private void addInvocation(Invocation invocation) {
            if (invocation instanceof StubbedInvocation) {
                this.stubbedInvocations.add((StubbedInvocation) invocation);
            } else {
                if (!this.isStubOnly(invocation)) {
                    this.invocations.add(invocation);
                }
            }
        }

        public Object answer(Invocation candidate, VerificationContext context) {
            for (Integer i = this.stubbedInvocations.size(); i > 0; i--) {
                StubbedInvocation stub = this.stubbedInvocations[i - 1];
                if (stub.matches(candidate)) {
                    // TODO: track used stubs
                    if (!candidate.lenient) {
                        context.markVerified(candidate);
                    }
                    return stub.answer(candidate);
                }
            }

            if (!candidate.lenient) {
                throw new ATK.VerificationException(String.format('"{0}" has not been stubbed', new List<Object>{ (Invocation) candidate }));
            }
            return this.defaultAnswer((Invocation) candidate);
        }

        public Object defaultAnswer(Invocation candidate) {
            return this.mockSettings.get(candidate.mock).defaultAnswer.answer(candidate);
        }

        private Boolean isStubOnly(Invocation invocation) {
            return this.mockSettings.get(invocation.mock).isStubOnly;
        }
    }

    private virtual class MatchableInvocation extends Invocation {
        protected List<ArgumentMatcher> matchers = new List<ArgumentMatcher>();

        private void populate(Invocation invocation, List<ArgumentMatcher> matchers) {
            this.mock = invocation.mock;
            this.method = invocation.method;
            this.arguments = invocation.arguments;
            this.mockSetting = invocation.mockSetting;
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

        public override virtual String toString() {
            List<String> matcherNames = new List<String>();

            for (ArgumentMatcher matcher : matchers) {
                matcherNames.add(String.valueOf(matcher));
            }

            return this.mockName + '.' + this.method.name + '(' + String.join(matcherNames, ', ') + ')';
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
                if (this.isConsecutive) {
                    return this.answers[this.answeredIndex++].answer(invocation);
                } else {
                    return this.answers[this.answeredIndex].answer(invocation);
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
        private MockSettings mockSetting { get; set; }

        private String mockName {
            get {
                if (this.mockSetting != null) {
                    return this.mockSetting.mockName;
                }
                return '';
            }
        }

        private Type mockType {
            get {
                if (this.mockSetting != null) {
                    return this.mockSetting.mockType;
                }
                return null;
            }
        }

        private Boolean lenient {
            get {
                if (this.mockSetting != null) {
                    return this.mockSetting.lenient;
                }
                return false;
            }
        }

        private Invocation() {
        }

        private Invocation(MockSettings mockSetting, Object mock, String methodName, Type returnType, List<Type> paramTypes, List<String> paramNames, List<Object> arguments) {
            this.mockSetting = mockSetting;
            this.mock = mock;
            this.method = new Method(methodName, returnType, paramTypes, paramNames);
            this.arguments = arguments;
        }

        public override virtual String toString() {
            List<String> args = new List<String>();

            for (Object arg : this.arguments) {
                args.add(String.valueOf(arg));
            }

            return this.mockName + '.' + this.method.name + '(' + String.join(args, ', ') + ')';
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

        public override Integer hashCode() {
            return (31 * this.name.hashCode()) ^ this.paramTypes.hashCode();
        }
    }

    // #endregion
    // ===================

    // ===============
    // #region Answers
    // ===============

    public interface Answer extends ATK.Answer {
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

    private class ExceptionAnswer implements Answer {
        private Exception exp { get; set; }

        ExceptionAnswer(Exception exp) {
            this.exp = exp;
        }

        public Object answer(ATK.Invocation invocation) {
            throw exp;
        }
    }

    private class NullAnswer implements Answer {
        public Object answer(ATK.Invocation invocation) {
            return null;
        }
    }

    public class DefaultAnswer implements Answer {
        private Map<Type, Object> primitiveDefaultValues { get; set; }

        private DefaultAnswer() {
            this.primitiveDefaultValues = new Map<Type, Object>{
                void.class => null,
                Integer.class => 0,
                Long.class => 0L,
                Double.class => 0.0d,
                Decimal.class => 0,
                String.class => '',
                Boolean.class => false
            };
        }

        public Object answer(ATK.Invocation invocation) {
            Type returnType = invocation.method.returnType;

            if (this.primitiveDefaultValues.containsKey(returnType)) {
                return this.primitiveDefaultValues.get(returnType);
            }

            if (returnType == void.class) {
                return null;
            } else if (returnType.getName().startsWith('List<')) {
                return returnType.newInstance();
            } else if (returnType.getName().startsWith('Set<')) {
                return returnType.newInstance();
            } else if (returnType.getName().startsWith('Map<')) {
                return returnType.newInstance();
            } else if (isSObjectType(returnType)) {
                return returnType.newInstance();
            }

            return null;
        }
    }

    private class SelfAnswer implements Answer {
        public Object answer(ATK.Invocation invocation) {
            Object defaultAnswer = DEFAULT_ANSWERS.answer(invocation);
            if (defaultAnswer != null) {
                return defaultAnswer;
            }

            try {
                if (invocation.method.returnType.isAssignableFrom(((Invocation) invocation).mockType)) {
                    return invocation.mock;
                }
            } catch (Exception ex) {
            }
            return null;
        }
    }

    private class MockAnswer implements Answer {
        private MockingProgress progress { get; set; }

        private MockAnswer(MockingProgress progress) {
            this.progress = progress;
        }

        public Object answer(ATK.Invocation invocation) {
            Object defaultAnswer = DEFAULT_ANSWERS.answer(invocation);
            if (defaultAnswer != null) {
                return defaultAnswer;
            }

            try {
                if (this.progress.isStubbing || this.progress.isVerifying) {
                    return null;
                }
                return this.progress.createMock(invocation.method.returnType, this.progress.getMockSettings(invocation.mock));
            } catch (Exception ex) {
            }
            return null;
        }
    }

    // TODO: support RETURNS_DEEP_STUBS

    // #endregion
    // ===============

    // ====================
    // #region Verificatoin
    //=====================

    public interface VerificationMode {
        void verify(List<Invocation> occurrences, MatchableInvocation matchable, VerificationContext context);
    }

    public class CallsVerificationMode implements VerificationMode {
        Integer times { get; set; }

        CallsVerificationMode(Integer times) {
            this.times = (Integer) validateNotNull(times);
        }

        public void verify(List<Invocation> occurrences, MatchableInvocation matchable, VerificationContext context) {
            if (occurrences.size() < this.times) {
                throw new ATK.VerificationException(String.format('Expected "{0}" to be called {1} time(s). But has been called {2} time(s).', new List<Object>{ matchable, this.times, occurrences }));
            } else {
                for (Integer i = 0; i < this.times; i++) {
                    context.markVerified(occurrences[i]);
                }
            }
        }
    }

    public class TimesVerificationMode implements VerificationMode {
        Integer times { get; set; }

        TimesVerificationMode(Integer times) {
            this.times = (Integer) validateNotNull(times);
        }

        public void verify(List<Invocation> occurrences, MatchableInvocation matchable, VerificationContext context) {
            if (occurrences.size() != this.times) {
                throw new ATK.VerificationException(
                    String.format('Expected "{0}" to be called {1} time(s). But has been called {2} time(s).', new List<Object>{ matchable, this.times, occurrences.size() })
                );
            } else {
                for (Invocation occurrence : occurrences) {
                    context.markVerified(occurrence);
                }
            }
        }
    }

    public class AtLeastVerificationMode implements VerificationMode {
        Integer times { get; set; }

        AtLeastVerificationMode(Integer times) {
            this.times = (Integer) validateNotNull(times);
        }

        public void verify(List<Invocation> occurrences, MatchableInvocation matchable, VerificationContext context) {
            if (occurrences.size() < this.times) {
                throw new ATK.VerificationException(
                    String.format('Expected "{0}" to be called at least {1} time(s). But has been called {2} time(s).', new List<Object>{ matchable, this.times, occurrences.size() })
                );
            } else {
                for (Invocation occurrence : occurrences) {
                    context.markVerified(occurrence);
                }
            }
        }
    }

    public class AtMostVerificationMode implements VerificationMode {
        Integer times { get; set; }

        AtMostVerificationMode(Integer times) {
            this.times = (Integer) validateNotNull(times);
        }

        public void verify(List<Invocation> occurrences, MatchableInvocation matchable, VerificationContext context) {
            if (occurrences.size() > this.times) {
                throw new ATK.VerificationException(
                    String.format('Expected "{0}" to be called at most {1} time(s). But has been called {2} time(s).', new List<Object>{ matchable, this.times, occurrences.size() })
                );
            } else {
                for (Invocation occurrence : occurrences) {
                    context.markVerified(occurrence);
                }
            }
        }
    }

    public class NoInteractionVerificationMode implements VerificationMode {
        public void verify(List<Invocation> occurrences, MatchableInvocation invocation, VerificationContext context) {
            if (occurrences.size() != 0) {
                throw new ATK.VerificationException(String.format('Expected "{0}" to have no invocations. But has {1} invocation(s).', new List<Object>{ invocation.mockName, occurrences.size() }));
            }
        }
    }

    public class NoMoreInteractionVerificationMode implements VerificationMode {
        public void verify(List<Invocation> occurrences, MatchableInvocation invocation, VerificationContext context) {
            if (occurrences.size() != 0) {
                throw new ATK.VerificationException(
                    String.format('Expected "{0}" to have no more invocations left. But still has {1} invocation(s) left.', new List<Object>{ invocation.mockName, occurrences.size() })
                );
            }
        }
    }

    public abstract class VerificationModeWrapper implements VerificationMode {
        VerificationMode wrappedMode { get; set; }
        VerificationContext context { get; set; }

        public void wrap(verificationMode mode) {
            this.wrappedMode = mode;
        }

        public virtual void verify(List<Invocation> occurrences, MatchableInvocation invocation, VerificationContext context) {
            if (this.wrappedMode != null) {
                this.wrappedMode.verify(occurrences, invocation, context);
            }
        }

        protected abstract void verify(InvocationContainer container, MatchableInvocation invocation);
    }

    public class NoOrderVerificationMode extends VerificationModeWrapper {
        NoOrderVerificationMode(VerificationContext context) {
            this.context = context;
        }

        public override void verify(InvocationContainer container, MatchableInvocation invocation) {
            List<Invocation> occurrences = INVOCATION_FINDER.findMatchingChuck(container.invocations, invocation);
            this.verify(occurrences, invocation, this.context);
        }
    }

    public class InOrderVerificationMode extends VerificationModeWrapper {
        InOrderVerificationMode(VerificationContext context) {
            this.context = context;
        }

        public override void verify(InvocationContainer container, MatchableInvocation matchable) {
            List<Invocation> invocations = INVOCATION_FINDER.findUnverified(container.invocations, this.context);
            List<Invocation> occurrences = INVOCATION_FINDER.findFirstMatchingChuck(invocations, matchable);
            this.verify(occurrences, matchable, this.context);
        }
    }

    // TODO: need full tests
    public class InvocationFinder {
        private List<Invocation> findMatchingChuck(List<Invocation> candidates, MatchableInvocation matchable) {
            List<Invocation> occurrences = new List<Invocation>();
            for (Invocation candidate : candidates) {
                if (matchable.matches(candidate)) {
                    occurrences.add(candidate);
                }
            }
            return occurrences;
        }

        private List<Invocation> findFirstMatchingChuck(List<Invocation> candidates, MatchableInvocation matchable) {
            List<Invocation> occurrences = new List<Invocation>();
            for (Invocation candidate : candidates) {
                if (matchable.matches(candidate)) {
                    occurrences.add(candidate);
                } else {
                    break;
                }
            }
            return occurrences;
        }

        private List<Invocation> findUnverified(List<Invocation> candidates, VerificationContext context) {
            List<Invocation> occurrences = new List<Invocation>();
            for (Invocation candidate : candidates) {
                if (context.containsMock(candidate.mock)) {
                    if (context.isVerified(candidate)) {
                        occurrences.clear();
                    } else {
                        occurrences.add(candidate);
                    }
                }
            }
            return occurrences;
        }

        private List<Invocation> findMatchingChuckByMock(List<Invocation> candidates, VerificationContext context, Object mock) {
            List<Invocation> occurrences = new List<Invocation>();
            for (Invocation candidate : candidates) {
                if (candidate.mock == mock) {
                    occurrences.add(candidate);
                }
            }
            return occurrences;
        }

        private List<Invocation> findUnverifiedByMock(List<Invocation> candidates, VerificationContext context, Object mock) {
            List<Invocation> occurrences = new List<Invocation>();
            for (Invocation candidate : candidates) {
                if (candidate.mock == mock) {
                    if (context.isVerified(candidate)) {
                        occurrences.clear();
                    } else {
                        occurrences.add(candidate);
                    }
                }
            }
            return occurrences;
        }
    }

    public class VerificationContext implements ATK.InOrder {
        Set<Invocation> invocations { get; set; }
        Set<Object> mocks { get; set; }

        VerificationContext(Set<Object> mocks) {
            this.invocations = new Set<Invocation>();
            this.mocks = mocks;
        }

        public Boolean isVerified(Invocation invocation) {
            return this.invocations.contains(invocation);
        }

        public void markVerified(Invocation invocation) {
            this.invocations.add(invocation);
        }

        public Boolean containsMock(Object mock) {
            return this.mocks.contains(mock);
        }
    }

    // #endregion
    // ====================

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

            // ! Seems no longer necessary
            // if (this.type == SObject.class) {
            //     return arg instanceof SObject;
            // }

            // if (this.type == List<SObject>.class) {
            //     return arg instanceof List<SObject>;
            // }

            // TODO: Add tests for isAssignable
            return this.type == type || this.type.isAssignableFrom(type);
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
            return this.type == type || this.type.isAssignableFrom(type);
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

    public class NullMatcher implements ArgumentMatcher {
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

    public class NeMatcher implements ArgumentMatcher {
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

    public class EqMatcher implements ArgumentMatcher {
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

    public class GtMatcher implements ArgumentMatcher {
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

    public class GteMatcher implements ArgumentMatcher {
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

    public class LtMatcher implements ArgumentMatcher {
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

    public class LteMatcher implements ArgumentMatcher {
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

    public class BetweenMatcher implements ArgumentMatcher {
        Object minValue { get; set; }
        Object maxValue { get; set; }
        Boolean minInclusive { get; set; }
        Boolean maxInclusive { get; set; }

        BetweenMatcher(Object minValue, Boolean minInclusive, Object maxValue, Boolean maxInclusive) {
            this.minValue = minValue;
            this.maxValue = maxValue;
            this.minInclusive = minInclusive;
            this.maxInclusive = maxInclusive;
        }

        public Boolean matches(Type type, Object arg) {
            if (arg == null) {
                return false;
            }

            if (!this.minInclusive && !this.maxInclusive) {
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

            if (this.minInclusive && !this.maxInclusive) {
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

            if (!this.minInclusive && this.maxInclusive) {
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

            if (this.minInclusive && this.maxInclusive) {
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
        Boolean isInOrder { get; set; }

        MultiSObjectListMatcher(List<Map<SObjectField, Object>> matchRulesList, Boolean isInOrder) {
            validateNotNull(matchRulesList);
            this.matchers = new List<ArgumentMatcher>();
            this.isInOrder = isInOrder;

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

            if (this.isInOrder) {
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

    public class MatcherRecorder implements ATK.MatcherRecorder {
        List<ArgumentMatcher> matchers { get; set; }

        public MatcherRecorder() {
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
            this.addMatcher(new NeMatcher(value));
            return null;
        }

        public Long neLong(Long value) {
            this.addMatcher(new NeMatcher(value));
            return null;
        }

        public Double neDouble(Double value) {
            this.addMatcher(new NeMatcher(value));
            return null;
        }

        public Decimal neDecimal(Decimal value) {
            this.addMatcher(new NeMatcher(value));
            return null;
        }

        public Date neDate(Date value) {
            this.addMatcher(new NeMatcher(value));
            return null;
        }

        public Datetime neDatetime(Datetime value) {
            this.addMatcher(new NeMatcher(value));
            return null;
        }

        public Id neId(Id value) {
            this.addMatcher(new NeMatcher(value));
            return null;
        }

        public String neString(String value) {
            this.addMatcher(new NeMatcher(value));
            return null;
        }

        public Boolean neBoolean(Boolean value) {
            this.addMatcher(new NeMatcher(value));
            return null;
        }

        public Object eq(Object value) {
            this.addMatcher(new EqMatcher(value));
            return null;
        }

        public Integer eqInteger(Integer value) {
            this.addMatcher(new EqMatcher(value));
            return null;
        }

        public Long eqLong(Long value) {
            this.addMatcher(new EqMatcher(value));
            return null;
        }

        public Double eqDouble(Double value) {
            this.addMatcher(new EqMatcher(value));
            return null;
        }

        public Decimal eqDecimal(Decimal value) {
            this.addMatcher(new EqMatcher(value));
            return null;
        }

        public Date eqDate(Date value) {
            this.addMatcher(new EqMatcher(value));
            return null;
        }

        public Datetime eqDatetime(Datetime value) {
            this.addMatcher(new EqMatcher(value));
            return null;
        }

        public Id eqId(Id value) {
            this.addMatcher(new EqMatcher(value));
            return null;
        }

        public String eqString(String value) {
            this.addMatcher(new EqMatcher(value));
            return null;
        }

        public Boolean eqBoolean(Boolean value) {
            this.addMatcher(new EqMatcher(value));
            return null;
        }

        public Integer gt(Integer value) {
            this.addMatcher(new GtMatcher(value));
            return null;
        }

        public Long gt(Long value) {
            this.addMatcher(new GtMatcher(value));
            return null;
        }

        public Double gt(Double value) {
            this.addMatcher(new GtMatcher(value));
            return null;
        }

        public Decimal gt(Decimal value) {
            this.addMatcher(new GtMatcher(value));
            return null;
        }

        public Date gt(Date value) {
            this.addMatcher(new GtMatcher(value));
            return null;
        }

        public Datetime gt(Datetime value) {
            this.addMatcher(new GtMatcher(value));
            return null;
        }

        public Time gt(Time value) {
            this.addMatcher(new GtMatcher(value));
            return null;
        }

        public Id gt(Id value) {
            this.addMatcher(new GtMatcher(value));
            return null;
        }

        public String gt(String value) {
            this.addMatcher(new GtMatcher(value));
            return null;
        }

        public Integer gte(Integer value) {
            this.addMatcher(new GteMatcher(value));
            return null;
        }

        public Long gte(Long value) {
            this.addMatcher(new GteMatcher(value));
            return null;
        }

        public Double gte(Double value) {
            this.addMatcher(new GteMatcher(value));
            return null;
        }

        public Decimal gte(Decimal value) {
            this.addMatcher(new GteMatcher(value));
            return null;
        }

        public Date gte(Date value) {
            this.addMatcher(new GteMatcher(value));
            return null;
        }

        public Datetime gte(Datetime value) {
            this.addMatcher(new GteMatcher(value));
            return null;
        }

        public Time gte(Time value) {
            this.addMatcher(new GteMatcher(value));
            return null;
        }

        public Id gte(Id value) {
            this.addMatcher(new GteMatcher(value));
            return null;
        }

        public String gte(String value) {
            this.addMatcher(new GteMatcher(value));
            return null;
        }

        public Integer lt(Integer value) {
            this.addMatcher(new LtMatcher(value));
            return null;
        }

        public Long lt(Long value) {
            this.addMatcher(new LtMatcher(value));
            return null;
        }

        public Double lt(Double value) {
            this.addMatcher(new LtMatcher(value));
            return null;
        }

        public Decimal lt(Decimal value) {
            this.addMatcher(new LtMatcher(value));
            return null;
        }

        public Date lt(Date value) {
            this.addMatcher(new LtMatcher(value));
            return null;
        }

        public Datetime lt(Datetime value) {
            this.addMatcher(new LtMatcher(value));
            return null;
        }

        public Time lt(Time value) {
            this.addMatcher(new LtMatcher(value));
            return null;
        }

        public Id lt(Id value) {
            this.addMatcher(new LtMatcher(value));
            return null;
        }

        public String lt(String value) {
            this.addMatcher(new LtMatcher(value));
            return null;
        }

        public Integer lte(Integer value) {
            this.addMatcher(new LteMatcher(value));
            return null;
        }

        public Long lte(Long value) {
            this.addMatcher(new LteMatcher(value));
            return null;
        }

        public Double lte(Double value) {
            this.addMatcher(new LteMatcher(value));
            return null;
        }

        public Decimal lte(Decimal value) {
            this.addMatcher(new LteMatcher(value));
            return null;
        }

        public Date lte(Date value) {
            this.addMatcher(new LteMatcher(value));
            return null;
        }

        public Datetime lte(Datetime value) {
            this.addMatcher(new LteMatcher(value));
            return null;
        }

        public Time lte(Time value) {
            this.addMatcher(new LteMatcher(value));
            return null;
        }

        public Id lte(Id value) {
            this.addMatcher(new LteMatcher(value));
            return null;
        }

        public String lte(String value) {
            this.addMatcher(new LteMatcher(value));
            return null;
        }

        public Integer between(Integer minValue, Boolean minInclusive, Integer maxValue, Boolean maxInclusive) {
            this.addMatcher(new BetweenMatcher(minValue, minInclusive, maxValue, maxInclusive));
            return null;
        }

        public Long between(Long minValue, Boolean minInclusive, Long maxValue, Boolean maxInclusive) {
            this.addMatcher(new BetweenMatcher(minValue, minInclusive, maxValue, maxInclusive));
            return null;
        }

        public Double between(Double minValue, Boolean minInclusive, Double maxValue, Boolean maxInclusive) {
            this.addMatcher(new BetweenMatcher(minValue, minInclusive, maxValue, maxInclusive));
            return null;
        }

        public Decimal between(Decimal minValue, Boolean minInclusive, Decimal maxValue, Boolean maxInclusive) {
            this.addMatcher(new BetweenMatcher(minValue, minInclusive, maxValue, maxInclusive));
            return null;
        }

        public Date between(Date minValue, Boolean minInclusive, Date maxValue, Boolean maxInclusive) {
            this.addMatcher(new BetweenMatcher(minValue, minInclusive, maxValue, maxInclusive));
            return null;
        }

        public Datetime between(Datetime minValue, Boolean minInclusive, Datetime maxValue, Boolean maxInclusive) {
            this.addMatcher(new BetweenMatcher(minValue, minInclusive, maxValue, maxInclusive));
            return null;
        }

        public Time between(Time minValue, Boolean minInclusive, Time maxValue, Boolean maxInclusive) {
            this.addMatcher(new BetweenMatcher(minValue, minInclusive, maxValue, maxInclusive));
            return null;
        }

        public Id between(Id minValue, Boolean minInclusive, Id maxValue, Boolean maxInclusive) {
            this.addMatcher(new BetweenMatcher(minValue, minInclusive, maxValue, maxInclusive));
            return null;
        }

        public String between(String minValue, Boolean minInclusive, String maxValue, Boolean maxInclusive) {
            this.addMatcher(new BetweenMatcher(minValue, minInclusive, maxValue, maxInclusive));
            return null;
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

        public LIst<SObject> sObjectListWith(List<Map<SObjectField, Object>> value, Boolean isInOrder) {
            this.addMatcher(new MultiSObjectListMatcher(value, isInOrder));
            return null;
        }
        // #endregion
    }

    public interface ArgumentMatcher extends ATK.Matcher {
    }

    // ======================
    // #region Error Handling
    // ======================

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

    // #endregion
    // ======================
}
