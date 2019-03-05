/**
 * Apex Test Kit
 */
global with sharing class ATKWizard {
    private static ATKWizard instance { get; set; }
    global static ATKWizard I() {
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
    global ATKWizard wantMany(String entityName) {
        this.spellBook = new ATKWand.ATKSpellBook();
        this.spellBook.attach(new ATKWand.EntityNode(entityName,
            ATKWand.EntityNodeType.WantMany));
        return this;
    }

    global ATKWizard belongsTo(String entityName) {
        this.spellBook.attach(new ATKWand.EntityNode(entityName,
            ATKWand.EntityNodeType.BelongsTo));
        return this;
    }

    global ATKWizard hasMany(String entityName) {
        this.spellBook.attach(new ATKWand.EntityNode(entityName,
            ATKWand.EntityNodeType.HasMany));
        return this;
    }

    /*
     * Entity Decoration
     */
    global ATKWizard fromList(List<SObject> repository) {
        this.spellBook.apply(new ATKWand.FromListAttribute(repository));
        return this;
    }

    global ATKWizard total(Integer count) {
        this.spellBook.apply(new ATKWand.TotalAttribute(count));
        return this;
    }

    global ATKWizard origin(Map<String, Object> fieldRuleMap) {
        this.spellBook.apply(new ATKWand.OriginFieldAttribute(fieldRuleMap));
        return this;
    }

    global ATKWizard fields(Map<String, Object> fieldRuleMap) {
        this.spellBook.apply(new ATKWand.FieldAttribute(fieldRuleMap));
        return this;
    }

    global ATKWizard referenceBy(String relationName) {
        this.spellBook.apply(new ATKWand.ReferenceByAttribute(relationName));
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
        ATKWand.generate(this.spellBook);

        Bag bag = new Bag(this.spellBook);
        this.spellBook = null;
        return bag;
    }

    /**
     * [Bag of Holding](https://en.wikipedia.org/wiki/Bag_of_holding)
     */
    global class Bag {
        private ATKWand.ATKSpellBook spellBook { get; set; }

        @TestVisible
        private Bag(ATKWand.ATKSpellBook spellBook) {
            this.spellBook = spellBook;
        }

        global List<SObject> get(String entityName) {
            return this.spellBook.query(entityName);
        }
    }
}
