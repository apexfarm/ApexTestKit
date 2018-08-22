/**
 * Apex Test Kit
 */
global with sharing class ATKWizard {
    private static final BOOLEAN IS_INIT = true;
    private ATKSpellBook spellBook { get; set; }

    /*
     * Entity Creation
     */
    global ATKWizard wantMany(String entityName) {
        this.spellBook = new ATKSpellBook();
        this.spellBook.attach(new ATKSpellBook.EntityNode(entityName, 
            ATKSpellBook.EntityNodeType.WantMany));
        return this;
    }

    global ATKWizard belongsTo(String entityName) {
        this.spellBook.attach(new ATKSpellBook.EntityNode(entityName,
            ATKSpellBook.EntityNodeType.BelongsTo));
        return this;
    }

    global ATKWizard hasMany(String entityName) {
        this.spellBook.attach(new ATKSpellBook.EntityNode(entityName,
            ATKSpellBook.EntityNodeType.HasMany));
        return this;
    }

    /*
     * Entity Decoration
     */
    global ATKWizard fromList(List<SObject> repository) {
        this.spellBook.apply(new ATKSpellBook.FromListAttribute(repository));
        return this;
    }

    global ATKWizard total(Integer count) {
        this.spellBook.apply(new ATKSpellBook.TotalAttribute(count));
        return this;
    }

    global ATKWizard fieldsInit(Map<String, Object> fieldRuleMap) {
        this.spellBook.apply(new ATKSpellBook.FieldAttribute(fieldRuleMap, IS_INIT));
        return this;
    }

    global ATKWizard fields(Map<String, Object> fieldRuleMap) {
        this.spellBook.apply(new ATKSpellBook.FieldAttribute(fieldRuleMap));
        return this;
    }

    global ATKWizard referenceBy(String relationName) {
        this.spellBook.apply(new ATKSpellBook.ReferenceByAttribute(relationName));
        return this;
    }

    /*
     * Entity Traverse
     */
    global ATKWizard also() {
        return also(1);
    }

    global ATKWizard also(Integer depth) {
        this.spellBook.pop(depth);
        return this;
    }

    /*
     * Entity Generation
     */
    global Bag generate() {
        ATKWand.validate(this.spellBook);
        ATKWand.generate(this.spellBook);

        Bag bag = new Bag(this.spellBook);
        this.spellBook = null;
        return bag;
    }

    /**
     * [Bag of Holding](https://en.wikipedia.org/wiki/Bag_of_holding)
     */
    global class Bag {
        private ATKSpellBook spellBook { get; set; }

        private Bag(ATKSpellBook spellBook) {
            this.spellBook = spellBook;
        }

        global List<SObject> query(String entityName) {
            return this.spellBook.query(entityName);
        }
    }
}
