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
    public static final Answer DEFAULT_ANSWERS = new DefaultAnswer();
    public static final Answer NULL_ANSWERS = new NullAnswer();
    public static final Answer SELF_ANSWERS = new SelfAnswer();
    public static final Answer MOCK_ANSWERS = new MockAnswer();

    public static final MockingProgress progress = new MockingProgress();
    private static final InvocationFinder INVOCATION_FINDER = new InvocationFinder();
    private static final Reporter REPORTER = new Reporter();
    private static Map<String, SObjectType> globalDescribe { get; set; }

    private static Boolean isSObjectType(Type type) {
        if (globalDescribe == null) {
            globalDescribe = Schema.getGlobalDescribe();
        }

        return globalDescribe.containsKey(type.getName());
    }

    private static object validateNotNull(Object arg) {
        if (arg == null) {
            REPORTER.reportMisuse_NullArguments();
        }
        return arg;
    }

    public class MockHandler implements System.StubProvider {
        public Object handleMethodCall(Object mock, String methodName, Type returnType, List<Type> paramTypes, List<String> paramNames, List<Object> arguments) {
            Invocation invocation = new Invocation(progress.getMockSettings(mock), mock, methodName, returnType, paramTypes, paramNames, arguments);

            if (progress.isStubbing) {
                progress.setMatchableInvocation(invocation, arguments);

                if (progress.isWillStubbing) {
                    progress.finishStubbing();
                }
                return progress.container.defaultAnswer(invocation);
            }

            if (progress.isVerifying) {
                progress.setMatchableInvocation(invocation, arguments);

                try {
                    progress.currentModeWrapper.verify(progress.container, (VerifiableInvocation) progress.currentMatchable);
                } catch (ATK.MockException exp) {
                    throw new ATK.MockException(exp.getMessage());
                } finally {
                    progress.finishVerifiying();
                }

                return progress.container.defaultAnswer(invocation);
            }

            progress.container.addInvocation(invocation);
            return progress.container.answer(invocation, progress.context);
        }
    }

    // =================
    // #region Stubber

    public class MockingProgress {
        public final GlobalSettings settings { get; set; }
        private final MockHandler mockHandler { get; set; }
        private final InvocationContainer container { get; set; }
        private final VerificationContext context { get; set; }

        // temporary states
        public final MatcherRecorder matcherRecorder { get; set; }
        private MatchableInvocation currentMatchable { get; set; }
        private VerificationModeWrapper currentModeWrapper { get; set; }
        private Boolean isStubbing = false;
        private Boolean isWillStubbing = false;

        // TODO: report unfinished stubbing;

        public MockingProgress() {
            this.settings = new GlobalSettings();
            this.mockHandler = new MockHandler();
            this.container = new InvocationContainer();
            this.context = new VerificationContext(new Set<Object>(), null);
            this.matcherRecorder = new MatcherRecorder();
        }

        public void startStubbing() {
            this.isStubbing = true;
        }

        public void stopStubbing() {
            this.isStubbing = false;
        }

        public Boolean isVerifying {
            get {
                return this.currentModeWrapper != null;
            }
        }

        private void finishStubbing() {
            this.container.addStubbedInvocation((StubbedInvocation) this.currentMatchable);
            this.currentMatchable = null;
            this.isWillStubbing = false;
        }

        private void finishVerifiying() {
            this.currentMatchable = null;
            this.currentModeWrapper = null;
            this.isWillStubbing = false;
        }

        public void setMatchableInvocation(Invocation invocation, List<Object> arguments) {
            // GivenStubber starts here
            if (this.currentMatchable == null) {
                this.currentMatchable = new StubbedInvocation();
            }

            if (!this.matcherRecorder.hasMatchers()) {
                for (Object arg : arguments) {
                    this.matcherRecorder.eq(arg);
                }
            } else {
                // TODO: seems not easy to verify matchers against argument types
            }

            this.currentMatchable.populate(invocation, this.matcherRecorder.matchers);
            this.matcherRecorder.reset();
        }

        private MockSettings getMockSettings(Object mock) {
            return this.container.mockSettings.get(mock);
        }

        private void putMockSettings(Object mock, MockSettings settings) {
            this.container.mockSettings.put(mock, settings);
        }

        public Object createMock(Type mockType) {
            return this.createMock(mockType, null, null, null, null, null, null);
        }

        public Object createMock(Type mockType, ATK.Answer defaultAnswer) {
            return this.createMock(mockType, null, defaultAnswer, null, null, null, null);
        }

        public Object createMock(Type mockType, ATK.MockSettings settings) {
            MockSettings mockSettings = (MockSettings) settings;
            return this.createMock(mockType, mockSettings.mockName, mockSettings.defaultAnswer, mockSettings.lenient, mockSettings.lenientVoid, mockSettings.stubOnly, mockSettings.verbose);
        }

        private Object createMock(Type mockType, String mockName, ATK.Answer defaultAnswer, Boolean lenient, Boolean lenientVoid, Boolean stubOnly, Boolean verbose) {
            Object mock = Test.createStub(mockType, mockHandler);

            MockSettings settings = new MockSettings();
            settings.mock = mock;
            settings.mockType = mockType;
            settings.mockName = String.isBlank(mockName) ? '[' + mockType.getName() + ']' : mockName;
            settings.defaultAnswer = defaultAnswer == null ? this.settings.defaultAnswer : defaultAnswer;
            settings.lenient = lenient == null ? this.settings.lenient : lenient;
            settings.lenientVoid = lenientVoid == null ? this.settings.lenientVoid : lenientVoid;
            settings.stubOnly = stubOnly == null ? this.settings.stubOnly : stubOnly;
            settings.verbose = verbose == null ? this.settings.verbose : verbose;

            this.putMockSettings(mock, settings);
            return mock;
        }

        public LenientStubber createLenientStubber() {
            if (!this.isStubbing) {
                REPORTER.reportMisuse_StubbingNotStarted();
            }
            return new LenientStubber(this);
        }

        public GivenStubber createGivenStubber() {
            if (!this.isStubbing) {
                this.currentMatchable = null;
                REPORTER.reportMisuse_StubbingNotStarted();
            }
            GivenStubber givenStub = new GivenStubber((StubbedInvocation) this.currentMatchable);
            this.finishStubbing();
            return givenStub;
        }

        public WillStubber createWillStubber() {
            if (!this.isStubbing) {
                REPORTER.reportMisuse_StubbingNotStarted();
            }
            this.currentMatchable = new StubbedInvocation();
            WillStubber willStub = new WillStubber((StubbedInvocation) this.currentMatchable);
            this.isWillStubbing = true;
            return willStub;
        }

        public ThenStubber createThenStubber(Object mock) {
            this.currentMatchable = new VerifiableInvocation();
            ThenStubber thenStub = new ThenStubber(mock, this);
            return thenStub;
        }

        public ATK.InOrder createInOrder(List<Object> mocks) {
            return new VerificationContext(new Set<Object>(mocks), this.context);
        }

        private void haveNoInteractions(Object mock) {
            try {
                this.currentMatchable.mock = mock;
                this.currentMatchable.mockSetting = this.getMockSettings(mock);
                this.currentModeWrapper.verify(
                    INVOCATION_FINDER.findMatchingChuckByMock(this.container.invocations, this.currentModeWrapper.context, mock),
                    (VerifiableInvocation) this.currentMatchable,
                    this.currentModeWrapper.context
                );
            } catch (ATK.MockException exp) {
                throw exp;
            } finally {
                this.finishVerifiying();
            }
        }

        private void haveNoMoreInteractions(Object mock) {
            try {
                this.currentMatchable.mock = mock;
                this.currentMatchable.mockSetting = this.getMockSettings(mock);
                this.currentModeWrapper.verify(
                    INVOCATION_FINDER.findUnverifiedByMock(this.container.invocations, this.currentModeWrapper.context, mock),
                    (VerifiableInvocation) this.currentMatchable,
                    this.currentModeWrapper.context
                );
            } catch (ATK.MockException exp) {
                throw new ATK.MockException(exp.getMessage());
            } finally {
                this.finishVerifiying();
            }
        }

        public void haveNoUnusedStubs(Object mock) {
            try {
                this.currentMatchable.mock = mock;
                this.currentMatchable.mockSetting = this.getMockSettings(mock);
                this.currentModeWrapper.verify(
                    INVOCATION_FINDER.findUnusedStubs(this.container.stubbedInvocations, this.currentModeWrapper.context, mock),
                    (VerifiableInvocation) this.currentMatchable,
                    this.currentModeWrapper.context
                );
            } catch (ATK.MockException exp) {
                throw exp;
            } finally {
                this.finishVerifiying();
            }
        }
    }

    public class LenientStubber implements ATK.Lenient {
        private MockingProgress progress { get; set; }

        LenientStubber(MockingProgress progress) {
            this.progress = progress;
        }

        public ATK.Given given(Object mock) {
            return this.progress.createGivenStubber().lenient();
        }

        public ATK.Will willReturn(Object value) {
            return this.progress.createWillStubber().lenient().willReturn(value);
        }

        public ATK.Will willAnswer(ATK.Answer answer) {
            return this.progress.createWillStubber().lenient().willAnswer(answer);
        }

        public ATK.Will willThrow(Exception exp) {
            return this.progress.createWillStubber().lenient().willThrow(exp);
        }

        public ATK.Will willDoNothing() {
            return this.progress.createWillStubber().lenient().willDoNothing();
        }
    }

    public class ThenStubber implements ATK.ThenOf, ATK.Should, ATK.InOrderShould {
        private Object mock { get; set; }
        private MockingProgress progress { get; set; }
        private VerificationModeWrapper mode { get; set; }

        ThenStubber(Object mock, MockingProgress progress) {
            this.mock = mock;
            this.progress = progress;
        }

        public ATK.Should should() {
            this.mode = new NoOrderVerificationMode(this.progress.context);
            this.progress.currentModeWrapper = this.mode;
            return this;
        }

        public ATK.InOrderShould should(ATK.InOrder inOrder) {
            this.mode = new InOrderVerificationMode((VerificationContext) inOrder);
            this.progress.currentModeWrapper = this.mode;
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

        public void haveNoUnusedStubs() {
            this.mode.wrap(new NoUnusedStubVerificationMode());
            this.progress.haveNoUnusedStubs(this.mock);
        }

        // none-greedy
        public Object calls(Integer n) {
            this.mode.wrap(new CallsVerificationMode(n));
            return this.mock;
        }
    }

    public class GivenStubber implements ATK.Given {
        StubbedInvocation stubbedInvocation { get; set; }

        GivenStubber(StubbedInvocation stubbedInvocation) {
            this.stubbedInvocation = stubbedInvocation;
        }

        public ATK.Given lenient() {
            this.stubbedInvocation.lenient = true;
            return this;
        }

        public ATK.Given willReturn(Object value) {
            this.stubbedInvocation.addAnswer(new ValueAnswer(value));
            return this;
        }

        public ATK.Given willAnswer(ATK.Answer answer) {
            this.stubbedInvocation.addAnswer(answer);
            return this;
        }

        public ATK.Given willThrow(Exception exp) {
            this.stubbedInvocation.addAnswer(new ExceptionAnswer(exp));
            return this;
        }
    }

    public class WillStubber implements ATK.Will {
        StubbedInvocation stubbedInvocation { get; set; }

        WillStubber(StubbedInvocation stubbedInvocation) {
            this.stubbedInvocation = stubbedInvocation;
        }

        public ATK.Will lenient() {
            this.stubbedInvocation.lenient = true;
            return this;
        }

        public ATK.Will willReturn(Object value) {
            this.stubbedInvocation.addAnswer(new ValueAnswer(value));
            return this;
        }

        public ATK.Will willAnswer(ATK.Answer answer) {
            this.stubbedInvocation.addAnswer(answer);
            return this;
        }

        public ATK.Will willThrow(Exception exp) {
            this.stubbedInvocation.addAnswer(new ExceptionAnswer(exp));
            return this;
        }

        public ATK.Will willDoNothing() {
            this.stubbedInvocation.addAnswer(NULL_ANSWERS);
            return this;
        }

        public Object given(Object mock) {
            return mock;
        }
    }

    // #endregion
    // =================

    // ===================
    // #region Invocations

    // Strict Mode: https://github.com/mockito/mockito/issues/1097
    // - unstubbed, non-void method fails immediately with "I am unstubbed!" exception
    // - such method is implicitly marked as verified for the verifyNoMoreInteractions() calls
    // - unused stubs are detected at the end of test and trigger failure

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
            if (invocation != null && !this.stubOnly(invocation)) {
                this.invocations.add(invocation);
                REPORTER.reportInfo_MockInvocation(invocation, this.invocations.size());
            }
        }

        private void addStubbedInvocation(StubbedInvocation invocation) {
            if (invocation != null) {
                this.stubbedInvocations.add(invocation);
                REPORTER.reportInfo_StubInvocation(invocation, this.stubbedInvocations.size());
            }
        }

        public Object answer(Invocation invocation, VerificationContext context) {
            for (Integer i = this.stubbedInvocations.size(); i > 0; i--) {
                StubbedInvocation stub = this.stubbedInvocations[i - 1];
                if (stub.matches(invocation)) {
                    if (!stub.lenient()) {
                        context.markUsedStub(stub);
                        context.markVerified(invocation);
                    }
                    return stub.answer(invocation);
                }
            }

            if (invocation.lenientVoid) {
                return null;
            }

            if (!invocation.lenient()) {
                REPORTER.reportMisuse_potentialStubbingProblem(invocation);
            }
            return this.defaultAnswer(invocation);
        }

        public Object defaultAnswer(Invocation invocation) {
            return this.mockSettings.get(invocation.mock).defaultAnswer.answer(invocation);
        }

        private Boolean stubOnly(Invocation invocation) {
            return this.mockSettings.get(invocation.mock).stubOnly;
        }
    }

    public class GlobalSettings extends MockSettings implements ATK.GlobalSettings {
        private GlobalSettings() {
            this.defaultAnswer = DEFAULT_ANSWERS;
            this.lenient = false;
            this.lenientVoid = false;
            this.stubOnly = false;
            this.verbose = false;
        }

        public MockSettings withSettings() {
            return this;
        }
    }

    public virtual class MockSettings implements ATK.MockSettings {
        private Object mock { get; set; }
        private Type mockType { get; set; }
        private String mockName { get; set; }
        private ATK.Answer defaultAnswer { get; set; }
        private Boolean lenient { get; set; }
        private Boolean lenientVoid { get; set; }
        private Boolean stubOnly { get; set; }
        private Boolean verbose { get; set; }

        public MockSettings name(String name) {
            this.mockName = name;
            return this;
        }

        public MockSettings defaultAnswer(ATK.Answer answer) {
            this.defaultAnswer = answer;
            return this;
        }

        public MockSettings stubOnly() {
            this.stubOnly = true;
            return this;
        }

        public MockSettings lenient() {
            this.lenient = true;
            return this;
        }

        public MockSettings lenientVoid() {
            this.lenientVoid = true;
            return this;
        }

        public MockSettings verbose() {
            this.verbose = true;
            return this;
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

        protected virtual Boolean lenient() {
            if (this.mockSetting != null) {
                return this.mockSetting.lenient;
            }
            return false;
        }

        private Boolean lenientVoid {
            get {
                if (this.mockSetting != null && this.method != null) {
                    return this.mockSetting.lenientVoid && this.method.returnType == void.class;
                }
                return false;
            }
        }

        private Boolean verbose {
            get {
                if (this.mockSetting != null) {
                    return this.mockSetting.verbose;
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
                if (arg instanceof String) {
                    args.add('\'' + arg + '\'');
                } else {
                    args.add(String.valueOf(arg));
                }
            }

            return this.mockName + '.' + this.method.name + '(' + String.join(args, ', ') + ')';
        }
    }

    private abstract class MatchableInvocation extends Invocation {
        protected List<Matcher> matchers = new List<Matcher>();

        private void populate(Invocation invocation, List<Matcher> matchers) {
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
            if (method == null) {
                return this.mockName;
            }

            List<String> matcherNames = new List<String>();

            for (Matcher matcher : matchers) {
                matcherNames.add(String.valueOf(matcher));
            }

            return this.mockName + '.' + this.method.name + '(' + String.join(matcherNames, ', ') + ')';
        }
    }

    private class VerifiableInvocation extends MatchableInvocation {
    }

    private class StubbedInvocation extends MatchableInvocation implements Answer {
        private Boolean lenient { get; set; }
        protected List<ATK.Answer> answers { get; set; }
        private Boolean isConsecutive { get; set; }
        private Boolean hasNextAnswer {
            get {
                return this.answers.size() > 0;
            }
        }

        private StubbedInvocation() {
            this.lenient = false;
            this.answers = new List<ATK.Answer>();
            this.isConsecutive = false;
        }

        protected override Boolean lenient() {
            return this.lenient || super.lenient();
        }

        private ATK.Answer poll() {
            return this.answers.remove(this.answers.size() - 1);
        }

        private ATK.Answer peek() {
            return this.answers.get(this.answers.size() - 1);
        }

        public Object answer(ATK.Invocation invocation) {
            if (this.hasNextAnswer) {
                if (this.isConsecutive) {
                    return this.poll().answer(invocation);
                } else {
                    return this.peek().answer(invocation);
                }
            }
            return null;
        }

        private void addAnswer(ATK.Answer answer) {
            if (this.answers.size() == 0) {
                this.answers.add(answer);
            } else {
                this.isConsecutive = true;
                this.answers.add(0, answer);
            }
        }
    }

    // #endregion
    // ===================

    // ===============
    // #region Answers

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
        public Object answer(ATK.Invocation invocation) {
            Object defaultAnswer = DEFAULT_ANSWERS.answer(invocation);
            if (defaultAnswer != null) {
                return defaultAnswer;
            }

            try {
                if (progress.isStubbing || progress.isVerifying) {
                    return null;
                }
                return progress.createMock(invocation.method.returnType, progress.getMockSettings(invocation.mock));
            } catch (Exception ex) {
            }
            return null;
        }
    }

    // #endregion
    // ===============

    // ====================
    // #region Verificatoin
    //=====================

    public interface VerificationMode {
        void verify(List<Invocation> occurrences, VerifiableInvocation matchable, VerificationContext context);
    }

    public class CallsVerificationMode implements VerificationMode {
        Integer times { get; set; }

        CallsVerificationMode(Integer times) {
            this.times = (Integer) validateNotNull(times);
        }

        public void verify(List<Invocation> occurrences, VerifiableInvocation matchable, VerificationContext context) {
            if (occurrences.size() < this.times) {
                REPORTER.reportVerify_CallTimesMisMatch(matchable, times, occurrences);
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

        public void verify(List<Invocation> occurrences, VerifiableInvocation matchable, VerificationContext context) {
            if (occurrences.size() != this.times) {
                REPORTER.reportVerify_CallTimesMisMatch(matchable, times, occurrences);
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

        public void verify(List<Invocation> occurrences, VerifiableInvocation matchable, VerificationContext context) {
            if (occurrences.size() < this.times) {
                REPORTER.reportVerify_TooManyCalls(matchable, times, occurrences);
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

        public void verify(List<Invocation> occurrences, VerifiableInvocation matchable, VerificationContext context) {
            if (occurrences.size() > this.times) {
                REPORTER.reportVerify_TooFewCalls(matchable, times, occurrences);
            } else {
                for (Invocation occurrence : occurrences) {
                    context.markVerified(occurrence);
                }
            }
        }
    }

    public class NoInteractionVerificationMode implements VerificationMode {
        public void verify(List<Invocation> occurrences, VerifiableInvocation invocation, VerificationContext context) {
            if (occurrences.size() != 0) {
                REPORTER.reportVerify_shouldHaveNoInvocations(invocation.mockName, occurrences);
            }
        }
    }

    public class NoMoreInteractionVerificationMode implements VerificationMode {
        public void verify(List<Invocation> occurrences, VerifiableInvocation invocation, VerificationContext context) {
            if (occurrences.size() != 0) {
                REPORTER.reportVerify_shouldHaveNoMoreInvocations(invocation.mockName, occurrences);
            }
        }
    }

    public class NoUnusedStubVerificationMode implements VerificationMode {
        public void verify(List<Invocation> occurrences, VerifiableInvocation invocation, VerificationContext context) {
            if (occurrences.size() != 0) {
                REPORTER.reportMisuse_UnnecessaryStubbingException(occurrences);
            }
        }
    }

    public abstract class VerificationModeWrapper implements VerificationMode {
        VerificationMode wrappedMode { get; set; }
        VerificationContext context { get; set; }

        public void wrap(verificationMode mode) {
            this.wrappedMode = mode;
        }

        public virtual void verify(List<Invocation> occurrences, VerifiableInvocation verifiable, VerificationContext context) {
            if (this.wrappedMode != null) {
                REPORTER.reportInfo_Verification(this.wrappedMode, verifiable, occurrences);
                this.wrappedMode.verify(occurrences, verifiable, context);
            }
        }

        protected abstract void verify(InvocationContainer container, VerifiableInvocation verifiable);
    }

    public class NoOrderVerificationMode extends VerificationModeWrapper {
        NoOrderVerificationMode(VerificationContext context) {
            this.context = context;
        }

        public override void verify(InvocationContainer container, VerifiableInvocation verifiable) {
            List<Invocation> occurrences = INVOCATION_FINDER.findMatchingChuck(container.invocations, verifiable);
            this.verify(occurrences, verifiable, this.context);
        }
    }

    public class InOrderVerificationMode extends VerificationModeWrapper {
        InOrderVerificationMode(VerificationContext context) {
            this.context = context;
        }

        public override void verify(InvocationContainer container, VerifiableInvocation verifiable) {
            List<Invocation> invocations = INVOCATION_FINDER.findUnverified(container.invocations, this.context);
            List<Invocation> occurrences = INVOCATION_FINDER.findFirstMatchingChuck(invocations, verifiable);
            this.verify(occurrences, verifiable, this.context);
        }
    }

    public class InvocationFinder {
        private List<Invocation> findMatchingChuck(List<Invocation> candidates, VerifiableInvocation verifiable) {
            List<Invocation> occurrences = new List<Invocation>();
            for (Invocation candidate : candidates) {
                if (verifiable.matches(candidate)) {
                    occurrences.add(candidate);
                }
            }
            return occurrences;
        }

        private List<Invocation> findFirstMatchingChuck(List<Invocation> candidates, VerifiableInvocation verifiable) {
            List<Invocation> occurrences = new List<Invocation>();
            for (Invocation candidate : candidates) {
                if (verifiable.matches(candidate)) {
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

        private List<Invocation> findUnusedStubs(List<StubbedInvocation> stubs, VerificationContext context, Object mock) {
            List<Invocation> occurrences = new List<Invocation>();
            for (StubbedInvocation stub : stubs) {
                if (stub.mock == mock && !context.isStubUsed(stub) && !stub.lenient()) {
                    occurrences.add(stub);
                }
            }
            return occurrences;
        }
    }

    public class VerificationContext implements ATK.InOrder {
        VerificationContext parent { get; set; }
        Set<Object> mocks { get; set; }
        Set<Invocation> invocations { get; set; }
        Set<StubbedInvocation> stubbedInvocations { get; set; }

        VerificationContext(Set<Object> mocks, VerificationContext parent) {
            this.mocks = mocks;
            this.parent = parent;
            this.invocations = new Set<Invocation>();
            this.stubbedInvocations = new Set<StubbedInvocation>();
        }

        public Boolean containsMock(Object mock) {
            return this.mocks.contains(mock);
        }

        public void markVerified(Invocation invocation) {
            this.invocations.add(invocation);
            if (this.parent != null) {
                this.parent.markVerified(invocation);
            }
        }

        public Boolean isVerified(Invocation invocation) {
            return this.invocations.contains(invocation);
        }

        public void markUsedStub(StubbedInvocation invocation) {
            this.stubbedInvocations.add(invocation);
        }

        public Boolean isStubUsed(StubbedInvocation invocation) {
            return this.stubbedInvocations.contains(invocation);
        }
    }

    // #endregion
    // ====================

    // =======================
    // #region Comobo Matchers

    public interface Matcher extends ATK.Matcher {
    }

    public abstract class ArgumentMatcher {
    }

    public abstract class ComboMatcher extends ArgumentMatcher {
        protected List<Matcher> matchers { get; set; }

        ComboMatcher() {
            matchers = new List<Matcher>();
        }

        public void addMatcher(Matcher matcher) {
            this.matchers.add(matcher);
        }

        protected List<String> matcherNames() {
            List<String> matcherNames = new List<String>();

            for (Matcher matcher : this.matchers) {
                matcherNames.add(String.valueOf(matcher));
            }

            return matcherNames;
        }
    }

    public class AllOfMatcher extends ComboMatcher implements Matcher {
        public Boolean matches(Type type, Object arg) {
            for (Matcher matcher : this.matchers) {
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

    public class AnyOfMatcher extends ComboMatcher implements Matcher {
        public Boolean matches(Type type, Object arg) {
            Boolean hasMatched = false;
            for (Matcher matcher : this.matchers) {
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

    public class NoneOfMatcher extends ComboMatcher implements Matcher {
        public Boolean matches(Type type, Object arg) {
            Boolean hasMatched = false;
            for (Matcher matcher : this.matchers) {
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
    // =======================

    // =====================
    // #region Type Matchers

    public class AnyMatcher extends ArgumentMatcher implements Matcher {
        public Boolean matches(Type type, Object arg) {
            return true;
        }

        public override String toString() {
            return 'ATK.any()';
        }
    }

    public class AnyTypeMatcher extends ArgumentMatcher implements Matcher {
        private Type type { get; set; }

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

            return this.type == type || this.type.isAssignableFrom(type);
        }

        public override String toString() {
            return 'ATK.any(' + this.type.getName() + '.class)';
        }
    }

    public class NullableTypeMatcher extends ArgumentMatcher implements Matcher {
        private Type type { get; set; }

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

    public class ListTypeMatcher extends ArgumentMatcher implements Matcher {
        public Boolean matches(Type type, Object arg) {
            return arg != null && arg instanceof List<Object>;
        }

        public override String toString() {
            return 'ATK.anyList()';
        }
    }

    public class SetTypeMatcher extends ArgumentMatcher implements Matcher {
        public Boolean matches(Type type, Object arg) {
            return arg != null && type.getName().startsWith('Set<');
        }

        public override String toString() {
            return 'ATK.anySet()';
        }
    }

    public class MapTypeMatcher extends ArgumentMatcher implements Matcher {
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

    public class NullMatcher extends ArgumentMatcher implements Matcher {
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

    public class SameMatcher extends ArgumentMatcher implements Matcher {
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

    public class NeMatcher extends ArgumentMatcher implements Matcher {
        Object value { get; set; }

        NeMatcher(Object value) {
            this.value = value;
        }

        public Boolean matches(Type type, Object arg) {
            return arg != value;
        }

        public override String toString() {
            if (value instanceof String) {
                return 'ATK.ne(\'' + this.value + '\')';
            }
            return 'ATK.ne(' + String.valueOf(this.value) + ')';
        }
    }

    public class EqMatcher extends ArgumentMatcher implements Matcher {
        Object value { get; set; }

        EqMatcher(Object value) {
            this.value = value;
        }

        public Boolean matches(Type type, Object arg) {
            return arg == value;
        }

        public override String toString() {
            if (value instanceof String) {
                return 'ATK.eq(\'' + this.value + '\')';
            }
            return 'ATK.eq(' + String.valueOf(this.value) + ')';
        }
    }

    public class GtMatcher extends ArgumentMatcher implements Matcher {
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
            if (value instanceof String) {
                return 'ATK.gt(\'' + this.value + '\')';
            }
            return 'ATK.gt(' + String.valueOf(this.value) + ')';
        }
    }

    public class GteMatcher extends ArgumentMatcher implements Matcher {
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
            if (value instanceof String) {
                return 'ATK.gte(\'' + this.value + '\')';
            }
            return 'ATK.gte(' + String.valueOf(this.value) + ')';
        }
    }

    public class LtMatcher extends ArgumentMatcher implements Matcher {
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
            if (value instanceof String) {
                return 'ATK.lt(\'' + this.value + '\')';
            }
            return 'ATK.lt(' + String.valueOf(this.value) + ')';
        }
    }

    public class LteMatcher extends ArgumentMatcher implements Matcher {
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
            if (value instanceof String) {
                return 'ATK.lte(\'' + this.value + '\')';
            }
            return 'ATK.lte(' + String.valueOf(this.value) + ')';
        }
    }

    public class BetweenMatcher extends ArgumentMatcher implements Matcher {
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
            if (minValue instanceof String && maxValue instanceof String) {
                return 'ATK.between(\'' + this.minValue + '\', \'' + this.maxValue + '\')';
            }
            return 'ATK.between(' + String.valueOf(this.minValue) + ', ' + String.valueOf(this.maxValue) + ')';
        }
    }

    public class IsBlankMatcher extends ArgumentMatcher implements Matcher {
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

    public class ContainsMatcher extends ArgumentMatcher implements Matcher {
        String value { get; set; }

        ContainsMatcher(String value) {
            this.value = (String) validateNotNull(value);
        }

        public Boolean matches(Type type, Object arg) {
            return arg != null && ((String) arg).contains(this.value);
        }

        public override String toString() {
            return 'ATK.contains(\'' + this.value + '\')';
        }
    }

    public class StartsWithMatcher extends ArgumentMatcher implements Matcher {
        String value { get; set; }

        StartsWithMatcher(String value) {
            this.value = (String) validateNotNull(value);
        }

        public Boolean matches(Type type, Object arg) {
            return arg != null && ((String) arg).startsWith(this.value);
        }

        public override String toString() {
            return 'ATK.startsWith(\'' + this.value + '\')';
        }
    }

    public class EndsWithMatcher extends ArgumentMatcher implements Matcher {
        String value { get; set; }

        EndsWithMatcher(String value) {
            this.value = (String) validateNotNull(value);
        }

        public Boolean matches(Type type, Object arg) {
            return arg != null && ((String) arg).endsWith(this.value);
        }

        public override String toString() {
            return 'ATK.endsWith(\'' + this.value + '\')';
        }
    }

    public class RegExpMatcher extends ArgumentMatcher implements Matcher {
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

    public class SObjectFieldMatcher extends ArgumentMatcher implements Matcher {
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

    public class SObjectMatcher extends ArgumentMatcher implements Matcher {
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

    public class SObjectListMatcher extends ArgumentMatcher implements Matcher {
        List<Matcher> matchers { get; set; }

        SObjectListMatcher(SObjectField field, Object value) {
            this.matchers = new List<Matcher>();
            this.matchers.add(new SObjectFieldMatcher(field, value));
        }

        SObjectListMatcher(Map<SObjectField, Object> matchRules) {
            validateNotNull(matchRules);
            this.matchers = new List<Matcher>();
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
                for (Matcher matcher : this.matchers) {
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

    public class MultiSObjectListMatcher extends ArgumentMatcher implements Matcher {
        List<Matcher> matchers { get; set; }
        Boolean isInOrder { get; set; }

        MultiSObjectListMatcher(List<Map<SObjectField, Object>> matchRulesList, Boolean isInOrder) {
            validateNotNull(matchRulesList);
            this.matchers = new List<Matcher>();
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
                    Matcher matcher = this.matchers[i];
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
                    Matcher matcher = this.matchers[j];
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

    public class MatcherRecorder implements ATK.MatcherRecorder {
        List<Matcher> matchers { get; set; }

        public MatcherRecorder() {
            this.matchers = new List<Matcher>();
        }

        private void addMatcher(Matcher matcher) {
            this.matchers.add(matcher);
        }

        private void reset() {
            this.matchers = new List<Matcher>();
        }

        private Boolean hasMatchers() {
            return this.matchers.size() > 0;
        }

        private void moveMatchers(ComboMatcher combo, Integer size) {
            for (Integer i = size; i > 0; i--) {
                Matcher matcher = this.matchers.remove(this.matchers.size() - i);
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
            this.addMatcher((Matcher) combo);
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
            this.addMatcher((Matcher) combo);
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
            this.addMatcher((Matcher) combo);
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

        public Time neTime(Time value) {
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

        public Time eqTime(Time value) {
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

    // ======================
    // #region Error Handling

    public class Reporter {
        private String join(List<String> strs) {
            return String.join(strs, '\n');
        }

        private void reportInfo_MockInvocation(Invocation invocation, Integer order) {
            if (invocation.verbose) {
                System.debug(LoggingLevel.INFO, String.format('[VERBOSE] BDD STEP: Given, Invoked Invocation #{1}: {0}', new List<Object>{ invocation, order }));
            }
        }

        private void reportInfo_StubInvocation(StubbedInvocation invocation, Integer order) {
            if (invocation.verbose) {
                System.debug(LoggingLevel.INFO, String.format('[VERBOSE] BDD STEP: When, Stubbed Invocation #{1}: {0}', new List<Object>{ invocation, order }));
            }
        }

        private void reportInfo_Verification(VerificationMode mode, VerifiableInvocation invocation, List<Invocation> occurrences) {
            if (invocation.verbose) {
                if (mode instanceof NoInteractionVerificationMode || mode instanceof NoMoreInteractionVerificationMode || mode instanceof NoUnusedStubVerificationMode) {
                } else {
                    System.debug(LoggingLevel.INFO, String.format('[VERBOSE] BDD STEP: Then, Verify Invocation: {0}, Matched Invocations: {1}', new List<Object>{ invocation, occurrences }));
                }
            }
        }

        private void reportMisuse_NullArguments() {
            throw new ATK.MockException('Argument cannot be null.');
        }

        private void reportMisuse_StubbingNotStarted() {
            throw new ATK.MockException('Given statements are not wrapped between ATK.startStubbing() and ATK.stopStubbing().');
        }

        private void reportMisuse_UnnecessaryStubbingException(List<Invocation> occurrences) {
            throw new ATK.MockException(String.format('{0} stubbed invocations are not used.', new List<Object>{ occurrences.size() }));
        }

        private void reportMisuse_potentialStubbingProblem(Invocation invocatoin) {
            throw new ATK.MockException(String.format('Invocation "{0}" has not been stubbed', new List<Object>{ (Invocation) invocatoin }));
        }

        private void reportVerify_CallTimesMisMatch(VerifiableInvocation verifiable, Integer times, List<Invocation> occurrences) {
            throw new ATK.MockException(String.format('Expected "{0}" to be called {1} time(s). But has been called {2} time(s).', new List<Object>{ verifiable, times, occurrences.size() }));
        }

        private void reportVerify_TooManyCalls(VerifiableInvocation verifiable, Integer times, List<Invocation> occurrences) {
            throw new ATK.MockException(String.format('Expected "{0}" to be called at least {1} time(s). But has been called {2} time(s).', new List<Object>{ verifiable, times, occurrences.size() }));
        }

        private void reportVerify_TooFewCalls(VerifiableInvocation verifiable, Integer times, List<Invocation> occurrences) {
            throw new ATK.MockException(String.format('Expected "{0}" to be called at most {1} time(s). But has been called {2} time(s).', new List<Object>{ verifiable, times, occurrences.size() }));
        }

        private void reportVerify_shouldHaveNoInvocations(String mockName, List<Invocation> occurrences) {
            throw new ATK.MockException(String.format('Expected "{0}" to have no invocations. But has {1} invocation(s).', new List<Object>{ mockName, occurrences.size() }));
        }

        private void reportVerify_shouldHaveNoMoreInvocations(String mockName, List<Invocation> occurrences) {
            throw new ATK.MockException(String.format('Expected "{0}" to have no more unverified invocations. But still has {1} invocation(s).', new List<Object>{ mockName, occurrences.size() }));
        }
    }

    // #endregion
    // ======================
}
