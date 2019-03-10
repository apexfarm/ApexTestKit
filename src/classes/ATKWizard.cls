/**
 * Apex Test Kit
 */
public with sharing class ATKWizard implements IWantKeywords,
    IEntityKeywords, IEndedFieldKeywords, IEvalKeywords, IXrefKeywords {

    ATKWand.ATKSpellbook spellbook { get; set; }
    ATKWand.EvalAttribute evalAttribute { get; set; }
    ATKWand.XrefAttribute xrefAttribute { get; set; }
    ATKWand.EvalMethodAttribute userNameAttribute { get; set; }
    ATKWand.EvalMethodAttribute emailAttribute { get; set; }
    ATKWand.EvalMethodAttribute urlAttribute { get; set; }
    ATKWand.EvalMethodAttribute phoneAttribute { get; set; }
    ATKWand.EvalMethodAttribute numberAttribute { get; set; }
    ATKWand.EvalMethodAttribute pastAttribute { get; set; }
    ATKWand.EvalMethodAttribute futureAttribute { get; set; }
    ATKWand.EvalMethodAttribute betweenAttribute { get; set; }
    ATKWand.EvalMethodAttribute firstNameAttribute { get; set; }
    ATKWand.EvalMethodAttribute lastNameAttribute { get; set; }
    ATKWand.EvalMethodAttribute wordAttribute { get; set; }
    ATKWand.EvalMethodAttribute wordsAttribute { get; set; }
    ATKWand.EvalMethodAttribute sentenceAttribute { get; set; }
    ATKWand.EvalMethodAttribute sentencesAttribute { get; set; }
    ATKWand.EvalMethodAttribute paragraphAttribute { get; set; }
    ATKWand.EvalMethodAttribute paragraphsAttribute { get; set; }
    ATKWand.XrefMethodAttribute xrefMethodAttribute { get; set; }

    private static ATKWizard sharedWizard { get; set; }

    public static IWantKeywords I() {
        if (sharedWizard == null) {
            sharedWizard = new ATKWizard();
        }
        return sharedWizard;
    }

    ATKWizard() {
        evalAttribute = new ATKWand.EvalAttribute();
        xrefAttribute = new ATKWand.XrefAttribute();
        userNameAttribute = new ATKWand.EvalMethodAttribute('internet', 'userName');
        emailAttribute = new ATKWand.EvalMethodAttribute('internet', 'email');
        urlAttribute = new ATKWand.EvalMethodAttribute('internet', 'url');
        phoneAttribute = new ATKWand.EvalMethodAttribute('phone', 'phoneNumber');
        numberAttribute = new ATKWand.EvalMethodAttribute('random', 'number');
        pastAttribute = new ATKWand.EvalMethodAttribute('dates', 'past');
        futureAttribute = new ATKWand.EvalMethodAttribute('dates', 'future');
        betweenAttribute = new ATKWand.EvalMethodAttribute('dates', 'between');
        firstNameAttribute = new ATKWand.EvalMethodAttribute('name', 'firstName');
        lastNameAttribute = new ATKWand.EvalMethodAttribute('name', 'lastName');
        wordAttribute = new ATKWand.EvalMethodAttribute('lorem', 'word');
        wordsAttribute = new ATKWand.EvalMethodAttribute('lorem', 'words');
        sentenceAttribute = new ATKWand.EvalMethodAttribute('lorem', 'sentence');
        sentencesAttribute = new ATKWand.EvalMethodAttribute('lorem', 'sentences');
        paragraphAttribute = new ATKWand.EvalMethodAttribute('lorem', 'paragraph');
        paragraphsAttribute = new ATKWand.EvalMethodAttribute('lorem', 'paragraphs');
        xrefMethodAttribute = new ATKWand.XrefMethodAttribute();
    }

    /*
     * Template Interfaces
     */
    public interface WizardTemplateInterface {
        void apply(IEntityKeywords entity, String templateName);
    }

    public interface IWizardTemplate extends WizardTemplateInterface {

    }

    /*
     * Keyword Interfaces
     */

    public interface IWantKeywords {
        IEntityKeywords wantMany(SObjectType entityType);
    }

    public interface IEntityKeywords {
        // keywords to end with
        Bag generate();
        Bag generate(Boolean inMemory);

        // keywords to start new context
        IEntityKeywords belongTo(SObjectType entityType);
        IEntityKeywords haveMany(SObjectType entityType);

        // keywords to build graph
        IEntityKeywords referenceBy(Schema.SObjectField relationField);
        IEntityKeywords also();
        IEntityKeywords also(Integer depth);
        IEntityKeywords total(Integer count);

        // keywords to build data
        IEntityKeywords useTemp(Type templateClass, String templateName);
        IEntityKeywords useCSV(String fileName);
        IEntityKeywords useList(List<SObject> repository);
        IFieldKeywords fields();
    }

    public interface IFieldKeywords {
        IEndedFieldKeywords guard();
        IEndedFieldKeywords guard(Boolean enable);
        IEvalKeywords eval(Schema.SObjectField field);
        IXrefKeywords xref(Schema.SObjectField field);
    }

    public interface IEndedFieldKeywords extends IFieldKeywords {
        IEntityKeywords end();
    }

    public interface IEvalKeywords {
        // try best to make uniqueness
        IEndedFieldKeywords guess();
        IEndedFieldKeywords userName();
        IEndedFieldKeywords email();
        IEndedFieldKeywords url();
        IEndedFieldKeywords phone();
        IEndedFieldKeywords number(Integer precision, Integer scale);
        IEndedFieldKeywords past() ;
        IEndedFieldKeywords future();
        IEndedFieldKeywords between(String fo, String to);

        // non-uniquable, use fake() to make unique values
        IEndedFieldKeywords firstName();
        IEndedFieldKeywords lastName();
        IEndedFieldKeywords word();
        IEndedFieldKeywords words();
        IEndedFieldKeywords sentence();
        IEndedFieldKeywords sentences();
        IEndedFieldKeywords paragraph();
        IEndedFieldKeywords paragraphs();

        // user control
        IEndedFieldKeywords fake(String rule);
        IEndedFieldKeywords index(String format);
        // fixed values
        IEndedFieldKeywords value(Object value);
        IEndedFieldKeywords repeat(List<Object> values);
        IEndedFieldKeywords repeat(Object value1, Object value2);
        IEndedFieldKeywords repeat(Object value1, Object value2, Object value3);
    }

    public interface IXrefKeywords {
        IEndedFieldKeywords value(String field);
        IEndedFieldKeywords add(String field, Object value);
        IEndedFieldKeywords substract(String field, Object value);
        IEndedFieldKeywords divide(String field, Object value);
        IEndedFieldKeywords multiply(String field, Object value);
        IEndedFieldKeywords addYears(String field, Integer value);
        IEndedFieldKeywords addMonths(String field, Integer value);
        IEndedFieldKeywords addDays(String field, Integer value);
        IEndedFieldKeywords addHours(String field, Integer value);
        IEndedFieldKeywords addMinutes(String field, Integer value);
        IEndedFieldKeywords addSeconds(String field, Integer value);
    }

    public class Bag {
        Map<Schema.SObjectType, List<SObject>> repositoryByType { get; set; }

        Bag(ATKWand.ATKSpellbook spellbook) {
            repositoryByType = new Map<Schema.SObjectType, List<SObject>>();
            Iterator<ATKWand.EntityNode> iterator = spellbook.iterator();
            while(iterator.hasNext()) {
                ATKWand.EntityNode entityNode = iterator.next();
                if (!this.repositoryByType.containsKey(entityNode.objectType)) {
                    this.repositoryByType.put(entityNode.objectType, entityNode.repository);
                } else {
                    this.repositoryByType.get(entityNode.objectType).addAll(entityNode.repository);
                }
            }
        }

        public List<SObject> get(Schema.SObjectType objectType) {
            return repositoryByType.get(objectType);
        }
    }

    public IEntityKeywords wantMany(SObjectType objectType) {
        spellbook = new ATKWand.ATKSpellbook();
        spellbook.attach(new ATKWand.EntityNode(objectType, ATKWand.EntityNodeType.WantMany));
        return sharedWizard;
    }

    // keywords to end with
    public Bag generate() {
        (new ATKWand()).generate(spellbook, false);
        BAg bag = new Bag(spellbook);
        spellbook = null;
        return bag;
    }

    public Bag generate(Boolean inMemory) {
        (new ATKWand()).generate(spellbook, inMemory);
        Bag bag = new Bag(spellbook);
        spellbook = null;
        return bag;
    }

    // keywords to start new context
    public IEntityKeywords belongTo(SObjectType objectType) {
        spellbook.attach(new ATKWand.EntityNode(objectType, ATKWand.EntityNodeType.BelongTo));
        return sharedWizard;
    }

    public IEntityKeywords haveMany(SObjectType objectType) {
        spellbook.attach(new ATKWand.EntityNode(objectType, ATKWand.EntityNodeType.HaveMany));
        return sharedWizard;
    }

    // keywords to build graph
    public IEntityKeywords referenceBy(Schema.SObjectField relationField) {
        spellbook.apply(new ATKWand.ReferenceByAttribute(relationField));
        return sharedWizard;
    }

    public IEntityKeywords also(Integer depth) {
        spellbook.pop(depth);
        return sharedWizard;
    }

    public IEntityKeywords also() {
        return also(1);
    }

    // keywords to control data
    public IEntityKeywords useCSV(String fileName) {
        // spellbook.apply(new ATKWand.UseListAttribute(repository));
        return sharedWizard;
    }

    public IEntityKeywords useList(List<SObject> repository) {
        spellbook.apply(new ATKWand.UseListAttribute(repository));
        return sharedWizard;
    }

    public IEntityKeywords useTemp(Type templateClass, String templateName) {
        if (templateClass != null) {
            Object instance = templateClass.newInstance();
            if (instance instanceOf IWizardTemplate) {
                IWizardTemplate template = (IWizardTemplate)instance;
                template.apply(sharedWizard, templateName);
            }
        }
        return sharedWizard;
    }

    public IEntityKeywords total(Integer count) {
        spellbook.apply(new ATKWand.TotalAttribute(count));
        return sharedWizard;
    }

    public IFieldKeywords fields() {
        return sharedWizard;
    }

    public IEntityKeywords end() {
        return sharedWizard;
    }

    public IEndedFieldKeywords guard() {
        spellbook.apply(new ATKWand.GuardAttribute(true));
        return sharedWizard;
    }

    public IEndedFieldKeywords guard(Boolean enable) {
        spellbook.apply(new ATKWand.GuardAttribute(enable));
        return sharedWizard;
    }

    public IEvalKeywords eval(Schema.SObjectField field) {
        evalAttribute.field = field;
        spellbook.apply(this.evalAttribute);
        return sharedWizard;
    }

    public IXrefKeywords xref(Schema.SObjectField field) {
        xrefAttribute.field = field;
        spellbook.apply(this.xrefAttribute);
        return sharedWizard;
    }

    /*
     * Eval Keywords
     */
    public IEndedFieldKeywords userName() {
        spellbook.apply(this.userNameAttribute);
        return sharedWizard;
    }

    public IEndedFieldKeywords email() {
        spellbook.apply(this.emailAttribute);
        return sharedWizard;
    }

    public IEndedFieldKeywords url() {
        spellbook.apply(this.urlAttribute);
        return sharedWizard;
    }

    public IEndedFieldKeywords phone() {
        spellbook.apply(this.phoneAttribute);
        return sharedWizard;
    }

    public IEndedFieldKeywords number(Integer precision, Integer scale) {
        this.numberAttribute.params = new List<Object> { precision, scale };
        spellbook.apply(this.numberAttribute);
        return sharedWizard;
    }

    public IEndedFieldKeywords past()  {
        spellbook.apply(this.pastAttribute);
        return sharedWizard;
    }

    public IEndedFieldKeywords future() {
        spellbook.apply(this.futureAttribute);
        return sharedWizard;
    }

    public IEndedFieldKeywords between(String fo, String to) {
        this.betweenAttribute.params = new List<Object> { fo, to };
        spellbook.apply(this.betweenAttribute);
        return sharedWizard;
    }

    public IEndedFieldKeywords firstName() {
        spellbook.apply(this.firstNameAttribute);
        return sharedWizard;
    }

    public IEndedFieldKeywords lastName() {
        spellbook.apply(this.lastNameAttribute);
        return sharedWizard;
    }

    public IEndedFieldKeywords word() {
        spellbook.apply(this.wordAttribute);
        return sharedWizard;
    }

    public IEndedFieldKeywords words() {
        spellbook.apply(this.wordsAttribute);
        return sharedWizard;
    }

    public IEndedFieldKeywords sentence() {
        spellbook.apply(this.sentenceAttribute);
        return sharedWizard;
    }

    public IEndedFieldKeywords sentences() {
        spellbook.apply(this.sentencesAttribute);
        return sharedWizard;
    }

    public IEndedFieldKeywords paragraph() {
        spellbook.apply(this.paragraphAttribute);
        return sharedWizard;
    }

    public IEndedFieldKeywords paragraphs() {
        spellbook.apply(this.paragraphAttribute);
        return sharedWizard;
    }

    public IEndedFieldKeywords guess() {
        spellbook.apply(new ATKWand.EvalGuessAttribute());
        return sharedWizard;
    }

    public IEndedFieldKeywords index(String format) {
        spellbook.apply(new ATKWand.EvalIndexAttribute(format));
        return sharedWizard;
    }

    public IEndedFieldKeywords fake(String rule) {
        spellbook.apply(new ATKWand.EvalFakerAttribute(rule));
        return sharedWizard;
    }

    public IEndedFieldKeywords value(Object value) {
        spellbook.apply(new ATKWand.EvalValueAttribute(value));
        return sharedWizard;
    }

    public IEndedFieldKeywords repeat(List<Object> values) {
        spellbook.apply(new ATKWand.EvalRepeatAttribute(values));
        return sharedWizard;
    }

    public IEndedFieldKeywords repeat(Object value1, Object value2) {
        spellbook.apply(new ATKWand.EvalRepeatAttribute(new List<Object> { value1, value2 }));
        return sharedWizard;
    }

    public IEndedFieldKeywords repeat(Object value1, Object value2, Object value3) {
        spellbook.apply(new ATKWand.EvalRepeatAttribute(new List<Object> { value1, value2, value3 }));
        return sharedWizard;
    }

    /*
     * Eval Keywords
     */
    public IEndedFieldKeywords value(String field) {
        this.xrefMethodAttribute.helperName = 'value';
        this.xrefMethodAttribute.methodName = 'get';
        this.xrefMethodAttribute.params = new List<Object> { field };
        spellbook.apply(this.xrefMethodAttribute);
        return sharedWizard;
    }

    public IEndedFieldKeywords add(String field, Object value) {
        this.xrefMethodAttribute.helperName = 'numbers';
        this.xrefMethodAttribute.methodName = 'add';
        this.xrefMethodAttribute.params = new List<Object> { field, value };
        spellbook.apply(this.xrefMethodAttribute);
        return sharedWizard;
    }

    public IEndedFieldKeywords substract(String field, Object value) {
        this.xrefMethodAttribute.helperName = 'numbers';
        this.xrefMethodAttribute.methodName = 'substract';
        this.xrefMethodAttribute.params = new List<Object> { field, value };
        spellbook.apply(this.xrefMethodAttribute);
        return sharedWizard;
    }

    public IEndedFieldKeywords divide(String field, Object value) {
        this.xrefMethodAttribute.helperName = 'numbers';
        this.xrefMethodAttribute.methodName = 'divide';
        this.xrefMethodAttribute.params = new List<Object> { field, value };
        spellbook.apply(this.xrefMethodAttribute);
        return sharedWizard;
    }

    public IEndedFieldKeywords multiply(String field, Object value) {
        this.xrefMethodAttribute.helperName = 'numbers';
        this.xrefMethodAttribute.methodName = 'multiply';
        this.xrefMethodAttribute.params = new List<Object> { field, value };
        spellbook.apply(this.xrefMethodAttribute);
        return sharedWizard;
    }

    public IEndedFieldKeywords addYears(String field, Integer value) {
        this.xrefMethodAttribute.helperName = 'dates';
        this.xrefMethodAttribute.methodName = 'add';
        this.xrefMethodAttribute.params = new List<Object> { field, value };
        spellbook.apply(this.xrefMethodAttribute);
        return sharedWizard;
    }

    public IEndedFieldKeywords addMonths(String field, Integer value) {
        this.xrefMethodAttribute.helperName = 'dates';
        this.xrefMethodAttribute.methodName = 'add';
        this.xrefMethodAttribute.params = new List<Object> { field, value };
        spellbook.apply(this.xrefMethodAttribute);
        return sharedWizard;
    }

    public IEndedFieldKeywords addDays(String field, Integer value) {
        this.xrefMethodAttribute.helperName = 'dates';
        this.xrefMethodAttribute.methodName = 'addDays';
        this.xrefMethodAttribute.params = new List<Object> { field, value };
        spellbook.apply(this.xrefMethodAttribute);
        return sharedWizard;
    }

    public IEndedFieldKeywords addHours(String field, Integer value) {
        this.xrefMethodAttribute.helperName = 'dates';
        this.xrefMethodAttribute.methodName = 'addHours';
        this.xrefMethodAttribute.params = new List<Object> { field, value };
        spellbook.apply(this.xrefMethodAttribute);
        return sharedWizard;
    }

    public IEndedFieldKeywords addMinutes(String field, Integer value) {
        this.xrefMethodAttribute.helperName = 'dates';
        this.xrefMethodAttribute.methodName = 'addMinutes';
        this.xrefMethodAttribute.params = new List<Object> { field, value };
        spellbook.apply(this.xrefMethodAttribute);
        return sharedWizard;
    }

    public IEndedFieldKeywords addSeconds(String field, Integer value) {
        this.xrefMethodAttribute.helperName = 'dates';
        this.xrefMethodAttribute.methodName = 'addSeconds';
        this.xrefMethodAttribute.params = new List<Object> { field, value };
        spellbook.apply(this.xrefMethodAttribute);
        return sharedWizard;
    }
}
