/**
 * Apex Test Kit
 */
public with sharing class ATKWizard {

    private static final ATKWand.IWizardEntity entityWizard = new ATKWizardEntity();
    private static final ATKWand.IWizardEndableField fieldWizard = new ATKWizardField();
    private static final ATKWand.IWizardFieldEval evalWizard = new WizardFieldEval();
    private static final ATKWand.IWizardFieldXref xrefWizard = new WizardFieldXref();

    @TestVisible
    private static ATKWand.ATKSpellBook spellBook { get; set; }

    public static ATKWand.IWizardEntity I() {
        return entityWizard;
    }

    class ATKWizardEntity implements ATKWand.IWizardEntity {
        // keywords to end with
        public ATKWand.IBag generate() {
            (new ATKWand()).generate(spellBook, false);
            ATKWand.IBag bag = spellBook.toBag();
            spellBook = null;
            return bag;
        }

        public ATKWand.IBag generate(Boolean inMemory) {
            (new ATKWand()).generate(spellBook, inMemory);

            ATKWand.IBag bag = spellBook.toBag();
            spellBook = null;
            return bag;
        }

        public void register() {
            (new ATKWand()).register(spellBook);
        }

        // keywords to start new context
        public ATKWand.IWizardEntity wantTemp(SObjectType objectType, String templateName) {
            spellBook = new ATKWand.ATKSpellBook();
            spellBook.attach(new ATKWand.EntityNode(objectType, ATKWand.EntityNodeType.Template));
            return entityWizard;
        }

        public ATKWand.IWizardEntity wantMany(SObjectType objectType) {
            spellBook = new ATKWand.ATKSpellBook();
            spellBook.attach(new ATKWand.EntityNode(objectType, ATKWand.EntityNodeType.WantMany));
            return entityWizard;
        }

        public ATKWand.IWizardEntity belongTo(SObjectType objectType) {
            spellBook.attach(new ATKWand.EntityNode(objectType, ATKWand.EntityNodeType.BelongTo));
            return entityWizard;
        }

        public ATKWand.IWizardEntity haveMany(SObjectType objectType) {
            spellBook.attach(new ATKWand.EntityNode(objectType, ATKWand.EntityNodeType.HaveMany));
            return entityWizard;
        }

        // keywords to build graph
        public ATKWand.IWizardEntity referenceBy(Schema.SObjectField relationField) {
            spellBook.apply(new ATKWand.ReferenceByAttribute(relationField));
            return entityWizard;
        }

        public ATKWand.IWizardEntity also(Integer depth) {
            spellBook.pop(depth);
            return entityWizard;
        }

        public ATKWand.IWizardEntity also() {
            return also(1);
        }

        // keywords to control data
        public ATKWand.IWizardEntity useCSV(String fileName) {
            // spellBook.apply(new ATKWand.UseListAttribute(repository));
            return entityWizard;
        }

        public ATKWand.IWizardEntity useList(List<SObject> repository) {
            spellBook.apply(new ATKWand.UseListAttribute(repository));
            return entityWizard;
        }

        public ATKWand.IWizardEntity useTemp() {
            spellBook.apply(new ATKWand.UseTempAttribute(null));
            return entityWizard;
        }

        public ATKWand.IWizardEntity useTemp(String templateName) {
            spellBook.apply(new ATKWand.UseTempAttribute(templateName));
            return entityWizard;
        }

        public ATKWand.IWizardEntity total(Integer count) {
            spellBook.apply(new ATKWand.TotalAttribute(count));
            return entityWizard;
        }

        public ATKWand.IWizardField fields() {
            return fieldWizard;
        }
    }

    class ATKWizardField implements ATKWand.IWizardEndableField {
        ATKWand.EvalAttribute evalAttribute = new ATKWand.EvalAttribute();
        ATKWand.XrefAttribute xrefAttribute = new ATKWand.XrefAttribute();

        public ATKWand.IWizardEntity end() {
            return entityWizard;
        }

        public ATKWand.IWizardEndableField guard() {
            spellBook.apply(new ATKWand.GuardAttribute(true));
            return fieldWizard;
        }

        public ATKWand.IWizardEndableField guard(Boolean enable) {
            spellBook.apply(new ATKWand.GuardAttribute(enable));
            return fieldWizard;
        }

        public ATKWand.IWizardFieldEval eval(Schema.SObjectField field) {
            evalAttribute.field = field;
            spellBook.apply(this.evalAttribute);
            return evalWizard;
        }

        public ATKWand.IWizardFieldXref xref(Schema.SObjectField field) {
            xrefAttribute.field = field;
            spellBook.apply(this.xrefAttribute);
            return xrefWizard;
        }
    }

    public class WizardFieldEval implements ATKWand.IWizardFieldEval {
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

        public ATKWand.IWizardEndableField userName() {
            spellBook.apply(this.userNameAttribute);
            return fieldWizard;
        }

        public ATKWand.IWizardEndableField email() {
            spellBook.apply(this.emailAttribute);
            return fieldWizard;
        }

        public ATKWand.IWizardEndableField url() {
            spellBook.apply(this.urlAttribute);
            return fieldWizard;
        }

        public ATKWand.IWizardEndableField phone() {
            spellBook.apply(this.phoneAttribute);
            return fieldWizard;
        }

        public ATKWand.IWizardEndableField number(Integer precision, Integer scale) {
            this.numberAttribute.params = new List<Object> { precision, scale };
            spellBook.apply(this.numberAttribute);
            return fieldWizard;
        }

        public ATKWand.IWizardEndableField past()  {
            spellBook.apply(this.pastAttribute);
            return fieldWizard;
        }

        public ATKWand.IWizardEndableField future() {
            spellBook.apply(this.futureAttribute);
            return fieldWizard;
        }

        public ATKWand.IWizardEndableField between(String fo, String to) {
            this.betweenAttribute.params = new List<Object> { fo, to };
            spellBook.apply(this.betweenAttribute);
            return fieldWizard;
        }

        public ATKWand.IWizardEndableField firstName() {
            spellBook.apply(this.firstNameAttribute);
            return fieldWizard;
        }

        public ATKWand.IWizardEndableField lastName() {
            spellBook.apply(this.lastNameAttribute);
            return fieldWizard;
        }

        public ATKWand.IWizardEndableField word() {
            spellBook.apply(this.wordAttribute);
            return fieldWizard;
        }

        public ATKWand.IWizardEndableField words() {
            spellBook.apply(this.wordsAttribute);
            return fieldWizard;
        }

        public ATKWand.IWizardEndableField sentence() {
            spellBook.apply(this.sentenceAttribute);
            return fieldWizard;
        }

        public ATKWand.IWizardEndableField sentences() {
            spellBook.apply(this.sentencesAttribute);
            return fieldWizard;
        }

        public ATKWand.IWizardEndableField paragraph() {
            spellBook.apply(this.paragraphAttribute);
            return fieldWizard;
        }

        public ATKWand.IWizardEndableField paragraphs() {
            spellBook.apply(this.paragraphAttribute);
            return fieldWizard;
        }

        public ATKWand.IWizardEndableField guess() {
            spellBook.apply(new ATKWand.EvalGuessAttribute());
            return fieldWizard;
        }

        public ATKWand.IWizardEndableField index(String format) {
            spellBook.apply(new ATKWand.EvalIndexAttribute(format));
            return fieldWizard;
        }

        public ATKWand.IWizardEndableField fake(String rule) {
            spellBook.apply(new ATKWand.EvalFakerAttribute(rule));
            return fieldWizard;
        }

        public ATKWand.IWizardEndableField value(Object value) {
            spellBook.apply(new ATKWand.EvalValueAttribute(value));
            return fieldWizard;
        }

        public ATKWand.IWizardEndableField repeat(List<Object> values) {
            spellBook.apply(new ATKWand.EvalRepeatAttribute(values));
            return fieldWizard;
        }

        public ATKWand.IWizardEndableField repeat(Object value1, Object value2) {
            spellBook.apply(new ATKWand.EvalRepeatAttribute(new List<Object> { value1, value2 }));
            return fieldWizard;
        }

        public ATKWand.IWizardEndableField repeat(Object value1, Object value2, Object value3) {
            spellBook.apply(new ATKWand.EvalRepeatAttribute(new List<Object> { value1, value2, value3 }));
            return fieldWizard;
        }
    }

    public class WizardFieldXref implements ATKWand.IWizardFieldXref {
        ATKWand.XrefMethodAttribute xrefMethodAttribute = new ATKWand.XrefMethodAttribute();

        public ATKWand.IWizardEndableField value(String field) {
            this.xrefMethodAttribute.helperName = 'value';
            this.xrefMethodAttribute.methodName = 'get';
            this.xrefMethodAttribute.params = new List<Object> { field };
            spellBook.apply(this.xrefMethodAttribute);
            return fieldWizard;
        }

        public ATKWand.IWizardEndableField add(String field, Object value) {
            this.xrefMethodAttribute.helperName = 'numbers';
            this.xrefMethodAttribute.methodName = 'add';
            this.xrefMethodAttribute.params = new List<Object> { field, value };
            spellBook.apply(this.xrefMethodAttribute);
            return fieldWizard;
        }

        public ATKWand.IWizardEndableField substract(String field, Object value) {
            this.xrefMethodAttribute.helperName = 'numbers';
            this.xrefMethodAttribute.methodName = 'substract';
            this.xrefMethodAttribute.params = new List<Object> { field, value };
            spellBook.apply(this.xrefMethodAttribute);
            return fieldWizard;
        }

        public ATKWand.IWizardEndableField divide(String field, Object value) {
            this.xrefMethodAttribute.helperName = 'numbers';
            this.xrefMethodAttribute.methodName = 'divide';
            this.xrefMethodAttribute.params = new List<Object> { field, value };
            spellBook.apply(this.xrefMethodAttribute);
            return fieldWizard;
        }

        public ATKWand.IWizardEndableField multiply(String field, Object value) {
            this.xrefMethodAttribute.helperName = 'numbers';
            this.xrefMethodAttribute.methodName = 'multiply';
            this.xrefMethodAttribute.params = new List<Object> { field, value };
            spellBook.apply(this.xrefMethodAttribute);
            return fieldWizard;
        }

        public ATKWand.IWizardEndableField addYears(String field, Integer value) {
            this.xrefMethodAttribute.helperName = 'dates';
            this.xrefMethodAttribute.methodName = 'add';
            this.xrefMethodAttribute.params = new List<Object> { field, value };
            spellBook.apply(this.xrefMethodAttribute);
            return fieldWizard;
        }

        public ATKWand.IWizardEndableField addMonths(String field, Integer value) {
            this.xrefMethodAttribute.helperName = 'dates';
            this.xrefMethodAttribute.methodName = 'add';
            this.xrefMethodAttribute.params = new List<Object> { field, value };
            spellBook.apply(this.xrefMethodAttribute);
            return fieldWizard;
        }

        public ATKWand.IWizardEndableField addDays(String field, Integer value) {
            this.xrefMethodAttribute.helperName = 'dates';
            this.xrefMethodAttribute.methodName = 'addDays';
            this.xrefMethodAttribute.params = new List<Object> { field, value };
            spellBook.apply(this.xrefMethodAttribute);
            return fieldWizard;
        }

        public ATKWand.IWizardEndableField addHours(String field, Integer value) {
            this.xrefMethodAttribute.helperName = 'dates';
            this.xrefMethodAttribute.methodName = 'addHours';
            this.xrefMethodAttribute.params = new List<Object> { field, value };
            spellBook.apply(this.xrefMethodAttribute);
            return fieldWizard;
        }

        public ATKWand.IWizardEndableField addMinutes(String field, Integer value) {
            this.xrefMethodAttribute.helperName = 'dates';
            this.xrefMethodAttribute.methodName = 'addMinutes';
            this.xrefMethodAttribute.params = new List<Object> { field, value };
            spellBook.apply(this.xrefMethodAttribute);
            return fieldWizard;
        }

        public ATKWand.IWizardEndableField addSeconds(String field, Integer value) {
            this.xrefMethodAttribute.helperName = 'dates';
            this.xrefMethodAttribute.methodName = 'addSeconds';
            this.xrefMethodAttribute.params = new List<Object> { field, value };
            spellBook.apply(this.xrefMethodAttribute);
            return fieldWizard;
        }
    }
}
