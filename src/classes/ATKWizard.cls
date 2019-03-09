/**
 * Apex Test Kit
 */
public with sharing class ATKWizard {
    private static final ATKCommon.IWizardI iWizard = new WizardI();
    private static final ATKCommon.IWizardEntity entityWizard = new ATKWizardEntity();
    private static final ATKCommon.IWizardEndableField fieldWizard = new ATKWizardField();
    private static final ATKCommon.IWizardFieldEval evalWizard = new WizardFieldEval();
    private static final ATKCommon.IWizardFieldXref xrefWizard = new WizardFieldXref();

    @TestVisible
    private static ATKWand.ATKSpellBook spellBook { get; set; }

    public static ATKCommon.IWizardI I() {
        return iWizard;
    }

    class WizardI implements ATKCommon.IWizardI {
        public ATKCommon.IWizardEntity wantMany(SObjectType objectType) {
            spellBook = new ATKWand.ATKSpellBook();
            spellBook.attach(new ATKWand.EntityNode(objectType, ATKWand.EntityNodeType.WantMany));
            return entityWizard;
        }
    }

    class ATKWizardEntity implements ATKCommon.IWizardEntity {
        // keywords to end with
        public ATKCommon.IBag generate() {
            (new ATKWand()).generate(spellBook, false);
            ATKCommon.IBag bag = spellBook.toBag();
            spellBook = null;
            return bag;
        }

        public ATKCommon.IBag generate(Boolean inMemory) {
            (new ATKWand()).generate(spellBook, inMemory);
            ATKCommon.IBag bag = spellBook.toBag();
            spellBook = null;
            return bag;
        }

        // keywords to start new context
        public ATKCommon.IWizardEntity belongTo(SObjectType objectType) {
            spellBook.attach(new ATKWand.EntityNode(objectType, ATKWand.EntityNodeType.BelongTo));
            return entityWizard;
        }

        public ATKCommon.IWizardEntity haveMany(SObjectType objectType) {
            spellBook.attach(new ATKWand.EntityNode(objectType, ATKWand.EntityNodeType.HaveMany));
            return entityWizard;
        }

        // keywords to build graph
        public ATKCommon.IWizardEntity referenceBy(Schema.SObjectField relationField) {
            spellBook.apply(new ATKWand.ReferenceByAttribute(relationField));
            return entityWizard;
        }

        public ATKCommon.IWizardEntity also(Integer depth) {
            spellBook.pop(depth);
            return entityWizard;
        }

        public ATKCommon.IWizardEntity also() {
            return also(1);
        }

        // keywords to control data
        public ATKCommon.IWizardEntity useCSV(String fileName) {
            // spellBook.apply(new ATKWand.UseListAttribute(repository));
            return entityWizard;
        }

        public ATKCommon.IWizardEntity useList(List<SObject> repository) {
            spellBook.apply(new ATKWand.UseListAttribute(repository));
            return entityWizard;
        }

        public ATKCommon.IWizardEntity useTemp(Type templateClass, String templateName) {
            if (templateClass != null) {
                Object instance = templateClass.newInstance();
                if (instance instanceOf ATKCommon.IWizardTemplate) {
                    ATKCommon.IWizardTemplate template = (ATKCommon.IWizardTemplate)instance;
                    template.apply(entityWizard, templateName);
                }
            }
            return entityWizard;
        }

        public ATKCommon.IWizardEntity total(Integer count) {
            spellBook.apply(new ATKWand.TotalAttribute(count));
            return entityWizard;
        }

        public ATKCommon.IWizardField fields() {
            return fieldWizard;
        }
    }

    class ATKWizardField implements ATKCommon.IWizardEndableField {
        ATKWand.EvalAttribute evalAttribute = new ATKWand.EvalAttribute();
        ATKWand.XrefAttribute xrefAttribute = new ATKWand.XrefAttribute();

        public ATKCommon.IWizardEntity end() {
            return entityWizard;
        }

        public ATKCommon.IWizardEndableField guard() {
            spellBook.apply(new ATKWand.GuardAttribute(true));
            return fieldWizard;
        }

        public ATKCommon.IWizardEndableField guard(Boolean enable) {
            spellBook.apply(new ATKWand.GuardAttribute(enable));
            return fieldWizard;
        }

        public ATKCommon.IWizardFieldEval eval(Schema.SObjectField field) {
            evalAttribute.field = field;
            spellBook.apply(this.evalAttribute);
            return evalWizard;
        }

        public ATKCommon.IWizardFieldXref xref(Schema.SObjectField field) {
            xrefAttribute.field = field;
            spellBook.apply(this.xrefAttribute);
            return xrefWizard;
        }
    }

    class WizardFieldEval implements ATKCommon.IWizardFieldEval {
        ATKWand.EvalMethodAttribute userNameAttribute = new ATKWand.EvalMethodAttribute('internet', 'userName');
        ATKWand.EvalMethodAttribute emailAttribute = new ATKWand.EvalMethodAttribute('internet', 'email');
        ATKWand.EvalMethodAttribute urlAttribute = new ATKWand.EvalMethodAttribute('internet', 'url');
        ATKWand.EvalMethodAttribute phoneAttribute = new ATKWand.EvalMethodAttribute('phone', 'phoneNumber');
        ATKWand.EvalMethodAttribute numberAttribute = new ATKWand.EvalMethodAttribute('random', 'number');
        ATKWand.EvalMethodAttribute pastAttribute = new ATKWand.EvalMethodAttribute('dates', 'past');
        ATKWand.EvalMethodAttribute futureAttribute = new ATKWand.EvalMethodAttribute('dates', 'future');
        ATKWand.EvalMethodAttribute betweenAttribute = new ATKWand.EvalMethodAttribute('dates', 'between');
        ATKWand.EvalMethodAttribute firstNameAttribute = new ATKWand.EvalMethodAttribute('name', 'firstName');
        ATKWand.EvalMethodAttribute lastNameAttribute = new ATKWand.EvalMethodAttribute('name', 'lastName');
        ATKWand.EvalMethodAttribute wordAttribute = new ATKWand.EvalMethodAttribute('lorem', 'word');
        ATKWand.EvalMethodAttribute wordsAttribute = new ATKWand.EvalMethodAttribute('lorem', 'words');
        ATKWand.EvalMethodAttribute sentenceAttribute = new ATKWand.EvalMethodAttribute('lorem', 'sentence');
        ATKWand.EvalMethodAttribute sentencesAttribute = new ATKWand.EvalMethodAttribute('lorem', 'sentences');
        ATKWand.EvalMethodAttribute paragraphAttribute = new ATKWand.EvalMethodAttribute('lorem', 'paragraph');
        ATKWand.EvalMethodAttribute paragraphsAttribute = new ATKWand.EvalMethodAttribute('lorem', 'paragraphs');

        public ATKCommon.IWizardEndableField userName() {
            spellBook.apply(this.userNameAttribute);
            return fieldWizard;
        }

        public ATKCommon.IWizardEndableField email() {
            spellBook.apply(this.emailAttribute);
            return fieldWizard;
        }

        public ATKCommon.IWizardEndableField url() {
            spellBook.apply(this.urlAttribute);
            return fieldWizard;
        }

        public ATKCommon.IWizardEndableField phone() {
            spellBook.apply(this.phoneAttribute);
            return fieldWizard;
        }

        public ATKCommon.IWizardEndableField number(Integer precision, Integer scale) {
            this.numberAttribute.params = new List<Object> { precision, scale };
            spellBook.apply(this.numberAttribute);
            return fieldWizard;
        }

        public ATKCommon.IWizardEndableField past()  {
            spellBook.apply(this.pastAttribute);
            return fieldWizard;
        }

        public ATKCommon.IWizardEndableField future() {
            spellBook.apply(this.futureAttribute);
            return fieldWizard;
        }

        public ATKCommon.IWizardEndableField between(String fo, String to) {
            this.betweenAttribute.params = new List<Object> { fo, to };
            spellBook.apply(this.betweenAttribute);
            return fieldWizard;
        }

        public ATKCommon.IWizardEndableField firstName() {
            spellBook.apply(this.firstNameAttribute);
            return fieldWizard;
        }

        public ATKCommon.IWizardEndableField lastName() {
            spellBook.apply(this.lastNameAttribute);
            return fieldWizard;
        }

        public ATKCommon.IWizardEndableField word() {
            spellBook.apply(this.wordAttribute);
            return fieldWizard;
        }

        public ATKCommon.IWizardEndableField words() {
            spellBook.apply(this.wordsAttribute);
            return fieldWizard;
        }

        public ATKCommon.IWizardEndableField sentence() {
            spellBook.apply(this.sentenceAttribute);
            return fieldWizard;
        }

        public ATKCommon.IWizardEndableField sentences() {
            spellBook.apply(this.sentencesAttribute);
            return fieldWizard;
        }

        public ATKCommon.IWizardEndableField paragraph() {
            spellBook.apply(this.paragraphAttribute);
            return fieldWizard;
        }

        public ATKCommon.IWizardEndableField paragraphs() {
            spellBook.apply(this.paragraphAttribute);
            return fieldWizard;
        }

        public ATKCommon.IWizardEndableField guess() {
            spellBook.apply(new ATKWand.EvalGuessAttribute());
            return fieldWizard;
        }

        public ATKCommon.IWizardEndableField index(String format) {
            spellBook.apply(new ATKWand.EvalIndexAttribute(format));
            return fieldWizard;
        }

        public ATKCommon.IWizardEndableField fake(String rule) {
            spellBook.apply(new ATKWand.EvalFakerAttribute(rule));
            return fieldWizard;
        }

        public ATKCommon.IWizardEndableField value(Object value) {
            spellBook.apply(new ATKWand.EvalValueAttribute(value));
            return fieldWizard;
        }

        public ATKCommon.IWizardEndableField repeat(List<Object> values) {
            spellBook.apply(new ATKWand.EvalRepeatAttribute(values));
            return fieldWizard;
        }

        public ATKCommon.IWizardEndableField repeat(Object value1, Object value2) {
            spellBook.apply(new ATKWand.EvalRepeatAttribute(new List<Object> { value1, value2 }));
            return fieldWizard;
        }

        public ATKCommon.IWizardEndableField repeat(Object value1, Object value2, Object value3) {
            spellBook.apply(new ATKWand.EvalRepeatAttribute(new List<Object> { value1, value2, value3 }));
            return fieldWizard;
        }
    }

    class WizardFieldXref implements ATKCommon.IWizardFieldXref {
        ATKWand.XrefMethodAttribute xrefMethodAttribute = new ATKWand.XrefMethodAttribute();

        public ATKCommon.IWizardEndableField value(String field) {
            this.xrefMethodAttribute.helperName = 'value';
            this.xrefMethodAttribute.methodName = 'get';
            this.xrefMethodAttribute.params = new List<Object> { field };
            spellBook.apply(this.xrefMethodAttribute);
            return fieldWizard;
        }

        public ATKCommon.IWizardEndableField add(String field, Object value) {
            this.xrefMethodAttribute.helperName = 'numbers';
            this.xrefMethodAttribute.methodName = 'add';
            this.xrefMethodAttribute.params = new List<Object> { field, value };
            spellBook.apply(this.xrefMethodAttribute);
            return fieldWizard;
        }

        public ATKCommon.IWizardEndableField substract(String field, Object value) {
            this.xrefMethodAttribute.helperName = 'numbers';
            this.xrefMethodAttribute.methodName = 'substract';
            this.xrefMethodAttribute.params = new List<Object> { field, value };
            spellBook.apply(this.xrefMethodAttribute);
            return fieldWizard;
        }

        public ATKCommon.IWizardEndableField divide(String field, Object value) {
            this.xrefMethodAttribute.helperName = 'numbers';
            this.xrefMethodAttribute.methodName = 'divide';
            this.xrefMethodAttribute.params = new List<Object> { field, value };
            spellBook.apply(this.xrefMethodAttribute);
            return fieldWizard;
        }

        public ATKCommon.IWizardEndableField multiply(String field, Object value) {
            this.xrefMethodAttribute.helperName = 'numbers';
            this.xrefMethodAttribute.methodName = 'multiply';
            this.xrefMethodAttribute.params = new List<Object> { field, value };
            spellBook.apply(this.xrefMethodAttribute);
            return fieldWizard;
        }

        public ATKCommon.IWizardEndableField addYears(String field, Integer value) {
            this.xrefMethodAttribute.helperName = 'dates';
            this.xrefMethodAttribute.methodName = 'add';
            this.xrefMethodAttribute.params = new List<Object> { field, value };
            spellBook.apply(this.xrefMethodAttribute);
            return fieldWizard;
        }

        public ATKCommon.IWizardEndableField addMonths(String field, Integer value) {
            this.xrefMethodAttribute.helperName = 'dates';
            this.xrefMethodAttribute.methodName = 'add';
            this.xrefMethodAttribute.params = new List<Object> { field, value };
            spellBook.apply(this.xrefMethodAttribute);
            return fieldWizard;
        }

        public ATKCommon.IWizardEndableField addDays(String field, Integer value) {
            this.xrefMethodAttribute.helperName = 'dates';
            this.xrefMethodAttribute.methodName = 'addDays';
            this.xrefMethodAttribute.params = new List<Object> { field, value };
            spellBook.apply(this.xrefMethodAttribute);
            return fieldWizard;
        }

        public ATKCommon.IWizardEndableField addHours(String field, Integer value) {
            this.xrefMethodAttribute.helperName = 'dates';
            this.xrefMethodAttribute.methodName = 'addHours';
            this.xrefMethodAttribute.params = new List<Object> { field, value };
            spellBook.apply(this.xrefMethodAttribute);
            return fieldWizard;
        }

        public ATKCommon.IWizardEndableField addMinutes(String field, Integer value) {
            this.xrefMethodAttribute.helperName = 'dates';
            this.xrefMethodAttribute.methodName = 'addMinutes';
            this.xrefMethodAttribute.params = new List<Object> { field, value };
            spellBook.apply(this.xrefMethodAttribute);
            return fieldWizard;
        }

        public ATKCommon.IWizardEndableField addSeconds(String field, Integer value) {
            this.xrefMethodAttribute.helperName = 'dates';
            this.xrefMethodAttribute.methodName = 'addSeconds';
            this.xrefMethodAttribute.params = new List<Object> { field, value };
            spellBook.apply(this.xrefMethodAttribute);
            return fieldWizard;
        }
    }
}
