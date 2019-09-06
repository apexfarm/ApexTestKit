/**
 * Apex Test Kit
 */
public with sharing class ATKCommand implements IEntityKeywords, IEndedFieldKeywords, IEvalKeywords, IXrefKeywords {

    ATKEntityCollection.EvalAttribute evalAttribute { get; set; }
    ATKEntityCollection.XrefAttribute xrefAttribute { get; set; }
    ATKEntityCollection.EvalMethodAttribute userNameAttribute { get; set; }
    ATKEntityCollection.EvalMethodAttribute emailAttribute { get; set; }
    ATKEntityCollection.EvalMethodAttribute urlAttribute { get; set; }
    ATKEntityCollection.EvalMethodAttribute phoneAttribute { get; set; }
    ATKEntityCollection.EvalMethodAttribute numberAttribute { get; set; }
    ATKEntityCollection.EvalMethodAttribute pastAttribute { get; set; }
    ATKEntityCollection.EvalMethodAttribute futureAttribute { get; set; }
    ATKEntityCollection.EvalMethodAttribute betweenAttribute { get; set; }
    ATKEntityCollection.EvalMethodAttribute firstNameAttribute { get; set; }
    ATKEntityCollection.EvalMethodAttribute lastNameAttribute { get; set; }
    ATKEntityCollection.EvalMethodAttribute wordAttribute { get; set; }
    ATKEntityCollection.EvalMethodAttribute wordsAttribute { get; set; }
    ATKEntityCollection.EvalMethodAttribute sentenceAttribute { get; set; }
    ATKEntityCollection.EvalMethodAttribute sentencesAttribute { get; set; }
    ATKEntityCollection.EvalMethodAttribute paragraphAttribute { get; set; }
    ATKEntityCollection.EvalMethodAttribute paragraphsAttribute { get; set; }
    ATKEntityCollection.XrefMethodAttribute xrefMethodAttribute { get; set; }

    ATKCommand() {
        evalAttribute = new ATKEntityCollection.EvalAttribute();
        xrefAttribute = new ATKEntityCollection.XrefAttribute();
        userNameAttribute = new ATKEntityCollection.EvalMethodAttribute('internet', 'userName');
        emailAttribute = new ATKEntityCollection.EvalMethodAttribute('internet', 'email');
        urlAttribute = new ATKEntityCollection.EvalMethodAttribute('internet', 'url');
        phoneAttribute = new ATKEntityCollection.EvalMethodAttribute('phone', 'phoneNumber');
        numberAttribute = new ATKEntityCollection.EvalMethodAttribute('random', 'number');
        pastAttribute = new ATKEntityCollection.EvalMethodAttribute('dates', 'past');
        futureAttribute = new ATKEntityCollection.EvalMethodAttribute('dates', 'future');
        betweenAttribute = new ATKEntityCollection.EvalMethodAttribute('dates', 'between');
        firstNameAttribute = new ATKEntityCollection.EvalMethodAttribute('name', 'firstName');
        lastNameAttribute = new ATKEntityCollection.EvalMethodAttribute('name', 'lastName');
        wordAttribute = new ATKEntityCollection.EvalMethodAttribute('lorem', 'word');
        wordsAttribute = new ATKEntityCollection.EvalMethodAttribute('lorem', 'words');
        sentenceAttribute = new ATKEntityCollection.EvalMethodAttribute('lorem', 'sentence');
        sentencesAttribute = new ATKEntityCollection.EvalMethodAttribute('lorem', 'sentences');
        paragraphAttribute = new ATKEntityCollection.EvalMethodAttribute('lorem', 'paragraph');
        paragraphsAttribute = new ATKEntityCollection.EvalMethodAttribute('lorem', 'paragraphs');
        xrefMethodAttribute = new ATKEntityCollection.XrefMethodAttribute();
    }

    /*
     * Keyword Interfaces
     */

    public interface IEntityKeywords {
        // keywords to end with
        ResultMap generate();
        ResultMap generate(Boolean inMemory);

        // keywords to start new context
        IEntityKeywords belongTo(SObjectType entityType);
        IEntityKeywords haveMany(SObjectType entityType);

        // keywords to build graph
        IEntityKeywords referenceBy(Schema.SObjectField relationField);
        IEntityKeywords also();
        IEntityKeywords also(Integer depth);
        IEntityKeywords total(Integer count);

        // keywords to build data
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

    public class ResultMap {
        Map<Schema.SObjectType, List<SObject>> repositoryByType { get; set; }

        ResultMap(ATKEntityCollection entityCollection) {
            repositoryByType = new Map<Schema.SObjectType, List<SObject>>();
            Iterator<ATKEntityCollection.EntityNode> iterator = entityCollection.iterator();
            while(iterator.hasNext()) {
                ATKEntityCollection.EntityNode entityNode = iterator.next();
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

    private static ATKCommand sharedCommand { get; set; }
    ATKEntityCollection entityCollection { get; set; }

    public static IEntityKeywords prepare(SObjectType objectType) {
        if (sharedCommand == null) {
            sharedCommand = new ATKCommand();
        }
        sharedCommand.entityCollection = new ATKEntityCollection();
        sharedCommand.entityCollection.attach(new ATKEntityCollection.EntityNode(objectType, ATKEntityCollection.EntityNodeType.Prepare));
        return sharedCommand;
    }

    // keywords to end with
    public ResultMap generate() {
        (new ATKEntityGenerator()).generate(entityCollection, false);
        ResultMap results = new ResultMap(entityCollection);
        entityCollection = null;
        return results;
    }

    public ResultMap generate(Boolean inMemory) {
        (new ATKEntityGenerator()).generate(entityCollection, inMemory);
        ResultMap results = new ResultMap(entityCollection);
        entityCollection = null;
        return results;
    }

    // keywords to start new context
    public IEntityKeywords belongTo(SObjectType objectType) {
        entityCollection.attach(new ATKEntityCollection.EntityNode(objectType, ATKEntityCollection.EntityNodeType.BelongTo));
        return sharedCommand;
    }

    public IEntityKeywords haveMany(SObjectType objectType) {
        entityCollection.attach(new ATKEntityCollection.EntityNode(objectType, ATKEntityCollection.EntityNodeType.HaveMany));
        return sharedCommand;
    }

    // keywords to build graph
    public IEntityKeywords referenceBy(Schema.SObjectField relationField) {
        entityCollection.apply(new ATKEntityCollection.ReferenceByAttribute(relationField));
        return sharedCommand;
    }

    public IEntityKeywords also(Integer depth) {
        entityCollection.pop(depth);
        return sharedCommand;
    }

    public IEntityKeywords also() {
        return also(1);
    }

    public IEntityKeywords useList(List<SObject> repository) {
        entityCollection.apply(new ATKEntityCollection.UseListAttribute(repository));
        return sharedCommand;
    }

    public IEntityKeywords total(Integer count) {
        entityCollection.apply(new ATKEntityCollection.TotalAttribute(count));
        return sharedCommand;
    }

    public IFieldKeywords fields() {
        return sharedCommand;
    }

    public IEntityKeywords end() {
        return sharedCommand;
    }

    public IEndedFieldKeywords guard() {
        entityCollection.apply(new ATKEntityCollection.GuardAttribute(true));
        return sharedCommand;
    }

    public IEndedFieldKeywords guard(Boolean enable) {
        entityCollection.apply(new ATKEntityCollection.GuardAttribute(enable));
        return sharedCommand;
    }

    public IEvalKeywords eval(Schema.SObjectField field) {
        evalAttribute.field = field;
        entityCollection.apply(this.evalAttribute);
        return sharedCommand;
    }

    public IXrefKeywords xref(Schema.SObjectField field) {
        xrefAttribute.field = field;
        entityCollection.apply(this.xrefAttribute);
        return sharedCommand;
    }

    /*
     * Eval Keywords
     */
    public IEndedFieldKeywords userName() {
        entityCollection.apply(this.userNameAttribute);
        return sharedCommand;
    }

    public IEndedFieldKeywords email() {
        entityCollection.apply(this.emailAttribute);
        return sharedCommand;
    }

    public IEndedFieldKeywords url() {
        entityCollection.apply(this.urlAttribute);
        return sharedCommand;
    }

    public IEndedFieldKeywords phone() {
        entityCollection.apply(this.phoneAttribute);
        return sharedCommand;
    }

    public IEndedFieldKeywords number(Integer precision, Integer scale) {
        this.numberAttribute.params = new List<Object> { precision, scale };
        entityCollection.apply(this.numberAttribute);
        return sharedCommand;
    }

    public IEndedFieldKeywords past()  {
        entityCollection.apply(this.pastAttribute);
        return sharedCommand;
    }

    public IEndedFieldKeywords future() {
        entityCollection.apply(this.futureAttribute);
        return sharedCommand;
    }

    public IEndedFieldKeywords between(String fo, String to) {
        this.betweenAttribute.params = new List<Object> { fo, to };
        entityCollection.apply(this.betweenAttribute);
        return sharedCommand;
    }

    public IEndedFieldKeywords firstName() {
        entityCollection.apply(this.firstNameAttribute);
        return sharedCommand;
    }

    public IEndedFieldKeywords lastName() {
        entityCollection.apply(this.lastNameAttribute);
        return sharedCommand;
    }

    public IEndedFieldKeywords word() {
        entityCollection.apply(this.wordAttribute);
        return sharedCommand;
    }

    public IEndedFieldKeywords words() {
        entityCollection.apply(this.wordsAttribute);
        return sharedCommand;
    }

    public IEndedFieldKeywords sentence() {
        entityCollection.apply(this.sentenceAttribute);
        return sharedCommand;
    }

    public IEndedFieldKeywords sentences() {
        entityCollection.apply(this.sentencesAttribute);
        return sharedCommand;
    }

    public IEndedFieldKeywords paragraph() {
        entityCollection.apply(this.paragraphAttribute);
        return sharedCommand;
    }

    public IEndedFieldKeywords paragraphs() {
        entityCollection.apply(this.paragraphAttribute);
        return sharedCommand;
    }

    public IEndedFieldKeywords guess() {
        entityCollection.apply(new ATKEntityCollection.EvalGuessAttribute());
        return sharedCommand;
    }

    public IEndedFieldKeywords index(String format) {
        entityCollection.apply(new ATKEntityCollection.EvalIndexAttribute(format));
        return sharedCommand;
    }

    public IEndedFieldKeywords fake(String rule) {
        entityCollection.apply(new ATKEntityCollection.EvalFakerAttribute(rule));
        return sharedCommand;
    }

    public IEndedFieldKeywords value(Object value) {
        entityCollection.apply(new ATKEntityCollection.EvalValueAttribute(value));
        return sharedCommand;
    }

    public IEndedFieldKeywords repeat(List<Object> values) {
        entityCollection.apply(new ATKEntityCollection.EvalRepeatAttribute(values));
        return sharedCommand;
    }

    public IEndedFieldKeywords repeat(Object value1, Object value2) {
        entityCollection.apply(new ATKEntityCollection.EvalRepeatAttribute(new List<Object> { value1, value2 }));
        return sharedCommand;
    }

    public IEndedFieldKeywords repeat(Object value1, Object value2, Object value3) {
        entityCollection.apply(new ATKEntityCollection.EvalRepeatAttribute(new List<Object> { value1, value2, value3 }));
        return sharedCommand;
    }

    /*
     * Eval Keywords
     */
    public IEndedFieldKeywords value(String field) {
        this.xrefMethodAttribute.helperName = 'value';
        this.xrefMethodAttribute.methodName = 'get';
        this.xrefMethodAttribute.params = new List<Object> { field };
        entityCollection.apply(this.xrefMethodAttribute);
        return sharedCommand;
    }

    public IEndedFieldKeywords add(String field, Object value) {
        this.xrefMethodAttribute.helperName = 'numbers';
        this.xrefMethodAttribute.methodName = 'add';
        this.xrefMethodAttribute.params = new List<Object> { field, value };
        entityCollection.apply(this.xrefMethodAttribute);
        return sharedCommand;
    }

    public IEndedFieldKeywords substract(String field, Object value) {
        this.xrefMethodAttribute.helperName = 'numbers';
        this.xrefMethodAttribute.methodName = 'substract';
        this.xrefMethodAttribute.params = new List<Object> { field, value };
        entityCollection.apply(this.xrefMethodAttribute);
        return sharedCommand;
    }

    public IEndedFieldKeywords divide(String field, Object value) {
        this.xrefMethodAttribute.helperName = 'numbers';
        this.xrefMethodAttribute.methodName = 'divide';
        this.xrefMethodAttribute.params = new List<Object> { field, value };
        entityCollection.apply(this.xrefMethodAttribute);
        return sharedCommand;
    }

    public IEndedFieldKeywords multiply(String field, Object value) {
        this.xrefMethodAttribute.helperName = 'numbers';
        this.xrefMethodAttribute.methodName = 'multiply';
        this.xrefMethodAttribute.params = new List<Object> { field, value };
        entityCollection.apply(this.xrefMethodAttribute);
        return sharedCommand;
    }

    public IEndedFieldKeywords addYears(String field, Integer value) {
        this.xrefMethodAttribute.helperName = 'dates';
        this.xrefMethodAttribute.methodName = 'add';
        this.xrefMethodAttribute.params = new List<Object> { field, value };
        entityCollection.apply(this.xrefMethodAttribute);
        return sharedCommand;
    }

    public IEndedFieldKeywords addMonths(String field, Integer value) {
        this.xrefMethodAttribute.helperName = 'dates';
        this.xrefMethodAttribute.methodName = 'add';
        this.xrefMethodAttribute.params = new List<Object> { field, value };
        entityCollection.apply(this.xrefMethodAttribute);
        return sharedCommand;
    }

    public IEndedFieldKeywords addDays(String field, Integer value) {
        this.xrefMethodAttribute.helperName = 'dates';
        this.xrefMethodAttribute.methodName = 'addDays';
        this.xrefMethodAttribute.params = new List<Object> { field, value };
        entityCollection.apply(this.xrefMethodAttribute);
        return sharedCommand;
    }

    public IEndedFieldKeywords addHours(String field, Integer value) {
        this.xrefMethodAttribute.helperName = 'dates';
        this.xrefMethodAttribute.methodName = 'addHours';
        this.xrefMethodAttribute.params = new List<Object> { field, value };
        entityCollection.apply(this.xrefMethodAttribute);
        return sharedCommand;
    }

    public IEndedFieldKeywords addMinutes(String field, Integer value) {
        this.xrefMethodAttribute.helperName = 'dates';
        this.xrefMethodAttribute.methodName = 'addMinutes';
        this.xrefMethodAttribute.params = new List<Object> { field, value };
        entityCollection.apply(this.xrefMethodAttribute);
        return sharedCommand;
    }

    public IEndedFieldKeywords addSeconds(String field, Integer value) {
        this.xrefMethodAttribute.helperName = 'dates';
        this.xrefMethodAttribute.methodName = 'addSeconds';
        this.xrefMethodAttribute.params = new List<Object> { field, value };
        entityCollection.apply(this.xrefMethodAttribute);
        return sharedCommand;
    }
}
