/**
 * Apex Test Kit
 */
public with sharing class ATKWizard implements ATKWand.IWizardEntity, ATKWand.IWizardField {
    private static ATKWizard instance { get; set; }
    public static ATKWizard I() {
        if (instance == null) {
            instance = new ATKWizard();
        }
        return instance;
    }

    @TestVisible
    private ATKWand.ATKSpellBook spellBook { get; set; }

    /*
     * Entity Creation
     */
    public ATKWand.IWizardEntity wantTemp(SObjectType objectType, String templateName) {
        this.spellBook = new ATKWand.ATKSpellBook();
        this.spellBook.attach(ATKWand.createTemplate(objectType, templateName));
        return this;
    }

    public ATKWand.IWizardEntity wantMany(SObjectType objectType) {
        this.spellBook = new ATKWand.ATKSpellBook();
        this.spellBook.attach(new ATKWand.EntityNode(objectType, ATKWand.EntityNodeType.WantMany));
        return this;
    }

    public ATKWand.IWizardEntity belongTo(SObjectType objectType) {
        this.spellBook.attach(new ATKWand.EntityNode(objectType, ATKWand.EntityNodeType.BelongTo));
        return this;
    }

    public ATKWand.IWizardEntity haveMany(SObjectType objectType) {
        this.spellBook.attach(new ATKWand.EntityNode(objectType, ATKWand.EntityNodeType.HaveMany));
        return this;
    }

    /*
     * Entity Relationship
     */

    public ATKWand.IWizardEntity referenceBy(Schema.SObjectField relationField) {
        this.spellBook.apply(new ATKWand.ReferenceByAttribute(relationField));
        return this;
    }

    public ATKWand.IWizardEntity total(Integer count) {
        this.spellBook.apply(new ATKWand.TotalAttribute(count));
        return this;
    }

    public ATKWand.IWizardEntity also() {
        return also(1);
    }

    public ATKWand.IWizardEntity also(Integer depth) {
        this.spellBook.pop(depth);
        return this;
    }

    /*
     * Entity Field Source
     */
    public ATKWand.IWizardEntity useCSV(String fileName) {
        // this.spellBook.apply(new ATKWand.UseListAttribute(repository));
        return this;
    }

    public ATKWand.IWizardEntity useList(List<SObject> repository) {
        this.spellBook.apply(new ATKWand.UseListAttribute(repository));
        return this;
    }

    public ATKWand.IWizardEntity useTemp() {
        this.spellBook.apply(new ATKWand.UseTempAttribute(null));
        return this;
    }

    public ATKWand.IWizardEntity useTemp(String templateName) {
        this.spellBook.apply(new ATKWand.UseTempAttribute(templateName));
        return this;
    }

    /*
     * Field Decoration
     */

    public ATKWand.IWizardEntity guard() {
        this.spellBook.apply(new ATKWand.GuardAttribute(true));
        return this;
    }

    public ATKWand.IWizardEntity guard(Boolean enable) {
        this.spellBook.apply(new ATKWand.GuardAttribute(enable));
        return this;
    }

    public ATKWand.IWizardField fields() {
        return this;
    }

    public ATKWand.IWizardField eval(Schema.SObjectField field) {
        this.spellBook.apply(new ATKWand.EvalAttribute(field));
        return this;
    }

    public ATKWand.IWizardField eval(Schema.SObjectField field, Object rule) {
        this.spellBook.apply(new ATKWand.EvalAttribute(field, rule));
        return this;
    }

    public ATKWand.IWizardField xref(Schema.SObjectField field, String rule) {
        this.spellBook.apply(new ATKWand.XrefAttribute(field, rule));
        return this;
    }

    public ATKWand.IWizardField xref(Schema.SObjectField field, String rule, Object origin) {
        this.spellBook.apply(new ATKWand.XrefAttribute(field, rule, origin));
        return this;
    }

    public ATKWand.IWizardEntity end() {
        return this;
    }

    /*
     * Entity Generation
     */
    public void register() {
        (new ATKWand()).register(this.spellBook);
    }

    public ATKWand.IWizardBag generate() {
        (new ATKWand()).generate(this.spellBook, false);

        Bag bag = new Bag(this.spellBook);
        this.spellBook = null;
        return bag;
    }

    public ATKWand.IWizardBag generate(Boolean inMemory) {
        (new ATKWand()).generate(this.spellBook, inMemory);

        Bag bag = new Bag(this.spellBook);
        this.spellBook = null;
        return bag;
    }

    @TestVisible
    private class Bag implements ATKWand.IWizardBag {
        private ATKWand.ATKSpellBook spellBook { get; set; }

        @TestVisible
        private Bag(ATKWand.ATKSpellBook spellBook) {
            this.spellBook = spellBook;
        }

        public List<SObject> get(Schema.SObjectType objectType) {
            return this.spellBook.query(objectType);
        }
    }
}
