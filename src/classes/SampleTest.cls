/**
 * Apex Test Kit
 */
@isTest
private with sharing class SampleTest {
    @isTest
    static void testDataFactory() {
        Integer accountTotal = 5;
        Integer contactTotal = 10;
        SampleTestDataFactory.createAccountWithContact(accountTotal, contactTotal);

        List<Account> accountList = [SELECT Id, Name, NumberOfEmployees, Fax, Industry FROM Account];
        System.assertEquals(accountTotal, accountList.size());
        for (Account account : accountList) {
            System.assert(account.Fax != null);
            System.assert(account.Fax.startsWith('555'));
            System.assert(account.Name != null);
            System.assert(account.Industry != null);
            System.assert(account.NumberOfEmployees != null);
        }
        List<Contact> contactList = [SELECT Id, LastName FROM Contact];
        System.assertEquals(contactTotal, contactList.size());
        for (Contact contact : contactList) {
            System.assert(contact.LastName != null);
        }
    }

    @isTest
    static void testFieldGuessValue() {
        Integer accountTotal = 5;
        Integer contactTotal = 10;
        ATKWizard.I().wantMany(Account.SObjectType)
            .total(accountTotal)
            .fields()
                .eval(Account.NumberOfEmployees).guess()
                .eval(Account.Fax).guess()
                .eval(Account.Industry).guess()
            .end()
            .haveMany(Contact.SObjectType)
                .total(contactTotal)
            .generate();

        List<Account> accountList = [SELECT Id, Name, NumberOfEmployees, Fax, Industry FROM Account];
        System.assertEquals(accountTotal, accountList.size());
        for (Account account : accountList) {
            System.assert(account.Fax != null);
            System.assert(account.Name != null);
            System.assert(account.Industry != null);
            System.assert(account.NumberOfEmployees != null);
        }
        List<Contact> contactList = [SELECT Id, LastName FROM Contact];
        System.assertEquals(contactTotal, contactList.size());
        for (Contact contact : contactList) {
            System.assert(contact.LastName != null);
        }
    }

    // /*
    //  * FIELD KEYWORD TESTS
    //  */

    @isTest
    static void testFieldWithRuleList() {
        ATKWizard.I().wantMany(Account.SObjectType)
            .total(6)
            .fields()
                .eval(Account.Name).fake('Microsoft-{{###}}')
                .eval(Account.Fax).fake('{{1##-###-####}}')
            .end()
            .generate();

        List<Account> accountList = [SELECT Id, Name, Fax FROM Account];
        System.assertEquals(6, accountList.size());
        for (Account account : accountList) {
            System.debug(String.format('account: Id({0}), Name({1}), Fax({2})', new List<String> {
                account.Id, account.Name, account.Fax
            }));
            System.assert(account.Name.startsWith('Microsoft'));
        }
    }

    @isTest
    static void testFieldPostUpdate() {
        ATKWizard.Bag bag = ATKWizard.I().wantMany(Account.SObjectType)
            .total(10)
            .fields()
                .eval(Account.Name).index('Microsoft-{0}')
            .end()
            .generate();

        List<Account> accountList = [SELECT Id, Name FROM Account];
        System.assertEquals(10, accountList.size());
        for (Account account : accountList) {
            System.assert(account.Name.startsWith('Microsoft-'));
        }

        ATKWizard.I().wantMany(Account.SObjectType)
            .useList(bag.get(Account.SObjectType))
            .fields()
                .eval(Account.Name).index('Google-{0}')
            .end()
            .generate();

        accountList = [SELECT Id, Name FROM Account];
        System.assertEquals(10, accountList.size());
        for (Account account : accountList) {
            System.assert(account.Name.startsWith('Google-'));
        }
    }

    @isTest
    static void testFieldPostUpdateWithSecondUseList() {
        ATKWizard.Bag bag = ATKWizard.I().wantMany(Account.SObjectType)
            .total(10)
            .fields()
                .eval(Account.Name).fake('Microsoft-{{###}}')
            .end()
            .generate();

        List<Account> accountList = [SELECT Id, Name FROM Account];
        System.assertEquals(10, accountList.size());
        for (Account account : accountList) {
            System.assert(account.Name.startsWith('Microsoft-'));
        }

        ATKWizard.I().wantMany(Account.SObjectType)
            .useList(bag.get(Account.SObjectType))
            .useList(new List<Account> {
                new Account(), new Account(), new Account(), new Account(), new Account()
            })
            .fields()
                .eval(Account.Name).fake('Google-{{###}}')
            .end()
            .generate();

        accountList = [SELECT Id, Name FROM Account];
        System.assertEquals(15, accountList.size());
        for (Account account : accountList) {
            System.assert(account.Name.startsWith('Google-'));
        }
    }

    // /*
    //  * CREATION KEYWORD TESTS
    //  */

    @isTest
    static void testRelationshipHaveMany() {
        Long startTime = System.currentTimeMillis();

        Integer accountTotal = 500;
        Integer contactTotal = 1000;
        ATKWizard.Bag bag = ATKWizard.I().wantMany(Account.SObjectType)
            .total(accountTotal)
            .fields()
                .eval(Account.Name).index('Name-{0}')           // Name-0, Name-1, Name-2 ...
                .eval(Account.AccountNumber).fake('{{?*****}}') // alpha + 6 * alphanumeric
                .eval(Account.NumberOfEmployees).number(8, 0)   // a integer of 8 digits
                .eval(Account.Fax).phone()                      // a standard US phone format
                .eval(Account.Description).paragraphs()         // multiple line text
                .eval(Account.Industry).guess()                 // pick any from the picklist
                .eval(Account.Website).guess()                  // pick any valid url
            .end()
            .haveMany(Contact.SObjectType)
                .referenceBy(Contact.AccountId)
                .total(contactTotal)
                .fields()
                    .eval(Contact.FirstName).firstName()        // English first name
                    .eval(Contact.LastName).lastName()          // English last name
                    .eval(Contact.Birthdate).past()             // a date in past 3 years
                    .eval(Contact.Email).email()                // a valid email address
                    .eval(Contact.DoNotCall).value(false)       // fixed value
                    .eval(Contact.Title).repeat('Mr.', 'Ms.')   // repeat 'Mr.', 'Ms.'
                .end()
            .generate();

        Long endTime = System.currentTimeMillis();
        System.debug('ATK generate takes ' + ((endTime - startTime)/1000) + ' seconds.');
        System.debug('CPU Limit: ' + Limits.getCpuTime() + '/' + Limits.getLimitCpuTime());

        Test.startTest();
        List<Account> accountList = [SELECT Id, (SELECT Id FROM Contacts) FROM Account];
        List<Contact> contactList = [SELECT Id FROM Contact];

        System.assertEquals(accountTotal, accountList.size());
        System.assertEquals(contactTotal, contactList.size());
        for (Account account : accountList) {
            System.assertEquals(2, account.Contacts.size());
        }
        System.debug('CPU Limit: ' + Limits.getCpuTime() + '/' + Limits.getLimitCpuTime());
        Test.stopTest();
    }

    @isTest
    static void testRelationshipHaveManyWithLessChild() {
        ATKWizard.I().wantMany(Account.SObjectType)
            .fields()
                .eval(Account.Name).fake('Google-{{###}}')
            .end()
            .total(10)
            .haveMany(Contact.SObjectType)
                .referenceBy(Contact.AccountId)
                .fields()
                    .eval(Contact.LastName).lastName()
                .end()
                .total(4)
            .generate();

        List<Account> accountList = [SELECT Id, (SELECT Id FROM Contacts) FROM Account];
        List<Contact> contactList = [SELECT Id FROM Contact];

        System.assertEquals(10, accountList.size());
        System.assertEquals(4, contactList.size());
        for (Integer i = 0; i < accountList.size(); i++) {
            if (i < 4) {
                System.assertEquals(1, accountList[i].Contacts.size());
            } else {
                System.assertEquals(0, accountList[i].Contacts.size());
            }
        }
    }

    @isTest
    static void testRelationshipHaveManyList() {
        List<Account> accountList = new List<Account>();
        List<Contact> contactList = new List<Contact>();
        for (Integer i = 0; i < 10; i++) {
            accountList.add(new Account(
                Name = ATKFaker.helper.replaceSymbols('Apple-###')
            ));
        }
        for (Integer i = 0; i < 40; i++) {
            contactList.add(new Contact(
                FirstName = ATKFaker.name.FirstName(),
                LastName = ATKFaker.name.LastName()
            ));
        }
        insert accountList;
        // no need to insert contactList, ATKWizard will handle it

        ATKWizard.I().wantMany(Account.SObjectType)
            .useList(accountList)
            .haveMany(Contact.SObjectType)
                .useList(contactList)
                .referenceBy(Contact.AccountId)
            .generate();

        accountList = [SELECT Id, (SELECT Id FROM Contacts) FROM Account];
        System.assertEquals(10, accountList.size());
        for (Account account : accountList) {
            System.assertEquals(4, account.Contacts.size());
        }
    }

    @isTest
    static void testRelationshipBelongTo() {
        ATKWizard.I().wantMany(Contact.SObjectType)
            .total(40)
            .fields()
                .eval(Contact.LastName).lastName()
            .end()
            .belongTo(Account.SObjectType)
                .referenceBy(Contact.AccountId)
                .total(10)
                .fields()
                    .eval(Account.Name).fake('Google-{{###}}')
                .end()
            .generate();

        List<Account> accountList = [SELECT Id, (SELECT Id FROM Contacts) FROM Account];
        List<Contact> contactList = [SELECT Id FROM Contact];

        System.assertEquals(10, accountList.size());
        System.assertEquals(40, contactList.size());
    }

    @isTest
    static void testRelationshipBelongToWithLessChild() {
        ATKWizard.I().wantMany(Contact.SObjectType)
            .total(4)
            .fields()
                .eval(Contact.LastName).lastName()
            .end()
            .belongTo(Account.SObjectType)
                .referenceBy(Contact.AccountId)
                .total(10)
                .fields()
                    .eval(Account.Name).fake('Google-{{###}}')
                .end()
            .generate();

        List<Account> accountList = [SELECT Id, (SELECT Id FROM Contacts) FROM Account];
        List<Contact> contactList = [SELECT Id FROM Contact];

        System.assertEquals(10, accountList.size());
        System.assertEquals(4, contactList.size());
        for (Integer i = 0; i < accountList.size(); i++) {
            if (i < 4) {
                System.assertEquals(1, accountList[i].Contacts.size());
            } else {
                System.assertEquals(0, accountList[i].Contacts.size());
            }
        }
    }

    @isTest
    static void testRelationshipHaveManyBelongTo() {
        Id pricebook2Id = Test.getStandardPricebookId();

        ATKWizard.Bag bag = ATKWizard.I().wantMany(Product2.SObjectType)
            .total(5)
            .haveMany(PricebookEntry.SObjectType)
                .referenceBy(PricebookEntry.Product2Id)
                .total(5)
                .fields()
                    .eval(PricebookEntry.Pricebook2Id).value(pricebook2Id)
                    .eval(PricebookEntry.UseStandardPrice).value(false)
                    .eval(PricebookEntry.IsActive).value(true)
                .end()
            .generate();

        ATKWizard.I().wantMany(Pricebook2.SObjectType)
            .total(5)
            .haveMany(PricebookEntry.SObjectType)
                .referenceBy(PricebookEntry.Pricebook2Id)
                .total(25)
                .fields()
                    .eval(PricebookEntry.UseStandardPrice).value(false)
                    .eval(PricebookEntry.IsActive).value(true)
                .end()
                .belongTo(Product2.SObjectType)
                    .referenceBy(PricebookEntry.Product2Id)
                    .useList(bag.get(Product2.SObjectType))
            .generate();

        List<AggregateResult> results = [
            SELECT count(Id)
            FROM PricebookEntry
            WHERE Pricebook2Id != :pricebook2Id
            GROUP BY Product2Id
        ];

        for (AggregateResult result : results) {
            System.assertEquals(5, result.get('expr0'));
        }
    }

    @isTest
    static void testRelationshipAlsoTraverse() {
        ATKWizard.I().wantMany(Account.SObjectType)
            .total(3)
            .haveMany(Contact.SObjectType)
                .referenceBy(Contact.AccountId)
                .total(6)
            .also()
            .haveMany(Contract.SObjectType)
                .referenceBy(Contract.AccountId)
                .total(6)
                .fields()
                    .eval(Contract.StartDate).between('2018-7-1', '2018-7-31')
                    .eval(Contract.ContractTerm).value(12)
                    .eval(Contract.Status).value('Draft')
                .end()
                .haveMany(Order.SObjectType)
                    .referenceBy(Order.ContractId)
                    .total(12)
                    .fields()
                        .eval(Order.EffectiveDate).between('2018-8-1', '2018-8-31')
                        .eval(Order.EndDate).between('2019-6-1', '2019-6-30')
                        .eval(Order.IsReductionOrder).value(false)
                        .eval(Order.Status).value('Draft')
                    .end()
            .also(2)
            .haveMany(Opportunity.SObjectType)
                .referenceBy(Opportunity.AccountId)
                .total(6)
            .generate();

        List<Account> accountList = [
            SELECT
                (SELECT Id
                FROM Contacts),
                (SELECT Id
                FROM Contracts),
                (SELECT Id
                FROM Opportunities)
            FROM Account
        ];

        System.assertEquals(3, accountList.size());
        for (Account account : accountList) {
            System.assertEquals(2, account.Contacts.size());
            System.assertEquals(2, account.Contracts.size());
            System.assertEquals(2, account.Opportunities.size());

            for (Contract contract : account.Contracts) {
                List<Order> orderList = [SELECT Id FROM Order WHERE ContractId = :contract.Id];
                System.assertEquals(2, orderList.size());
            }
        }
    }

    @isTest
    static void testRelationshipAccountOpportunity() {
        ATKWizard.Bag bag = ATKWizard.I().wantMany(Account.SObjectType)
            .total(3)
            .haveMany(Contact.SObjectType)
                .referenceBy(Contact.AccountId)
                .total(6)
            .generate();

        ATKWizard.I().wantMany(Account.SObjectType)
            .useList(bag.get(Account.SObjectType))
            .haveMany(Opportunity.SObjectType)
                .referenceBy(Opportunity.AccountId)
                .total(6)
                .fields()
                    .eval(Opportunity.CloseDate).between('2018-7-1', '2018-8-1')
                .end()
                .haveMany(OpportunityContactRole.SObjectType)
                    .referenceBy(OpportunityContactRole.OpportunityId)
                    .total(36)
                    .belongTo(Contact.SObjectType)
                        .referenceBy(OpportunityContactRole.ContactId)
                        .useList(bag.get(Contact.SObjectType))
            .generate();

        List<OpportunityContactRole> ocrList = [SELECT Id FROM OpportunityContactRole];
        System.assertEquals(36, ocrList.size());
    }

    @isTest
    static void testRelationshipOptionalReferenceBy() {
        ATKWizard.I().wantMany(Account.SObjectType)
            .total(10)
            .haveMany(Contact.SObjectType)
                .total(20)
                .haveMany(OpportunityContactRole.SObjectType)
                    .total(20)
                    .belongTo(Opportunity.SObjectType)
                        .fields()
                            .eval(Opportunity.CloseDate).between('2018-7-1', '2018-8-1')
                        .end()
                        .total(20)
            .generate();

        List<Account> accountList = [SELECT Id, (SELECT Id FROM Contacts) FROM Account];
        List<Contact> contactList = [SELECT Id FROM Contact];
        List<Opportunity> oppoList = [SELECT Id FROM Opportunity];
        List<OpportunityContactRole> roleList = [SELECT Id FROM OpportunityContactRole];

        System.assertEquals(10, accountList.size());
        System.assertEquals(20, contactList.size());
        System.assertEquals(20, oppoList.size());
        System.assertEquals(20, roleList.size());
        for (Account account : accountList) {
            System.assertEquals(2, account.Contacts.size());
        }
    }

    /*
     * CROSS RECORD REFERENCE
     */

    @isTest
    static void testCrossFieldReference() {
        Date current = Date.today();
        ATKWizard.Bag bag = ATKWizard.I().wantMany(Contact.SObjectType)
            .total(10)
            .fields()
                .eval(Contact.Birthdate).value(current.addDays(100))
                .eval(Contact.Birthdate).value(current)
                .xref(Contact.Birthdate).addDays('$1.Birthdate', -1)
            .end()
            .generate();

        List<SObject> contacts = bag.get(Contact.SObjectType);
        for (Integer i = 0; i < contacts.size(); i++) {
            System.debug(current.addDays(-i) + ' == ' + contacts[i].get('Birthdate'));
            System.assertEquals(current.addDays(-i), contacts[i].get('Birthdate'));
        }
    }

    @isTest
    static void testCrossFieldReference2() {
        Date current = Date.today();
        ATKWizard.Bag bag = ATKWizard.I().wantMany(Contact.SObjectType)
            .total(10)
            .fields()
                .eval(Contact.Birthdate).value(current.addDays(100))
                .xref(Contact.Birthdate).addDays('$1.Birthdate', -1)
                .eval(Contact.Birthdate).value(current)
            .end()
            .generate();

        List<SObject> contacts = bag.get(Contact.SObjectType);
        for (Integer i = 0; i < contacts.size(); i++) {
            System.debug(contacts[i].get('Birthdate'));
            System.assertEquals(current.addDays(-i), contacts[i].get('Birthdate'));
        }
    }

    @isTest
    static void testCrossFieldReference3() {
        Date current = Date.today();
        ATKWizard.Bag bag = ATKWizard.I().wantMany(Contact.SObjectType)
            .total(10)
            .fields()
                .xref(Contact.Birthdate).addDays('$1.Birthdate', -2)
                .xref(Contact.Birthdate).addDays('$1.Birthdate', -1)
                .eval(Contact.Birthdate).value(current.addDays(100))
                .eval(Contact.Birthdate).value(current)
            .end()
            .generate();

        List<SObject> contacts = bag.get(Contact.SObjectType);
        for (Integer i = 0; i < contacts.size(); i++) {
            System.debug(contacts[i].get('Birthdate'));
            System.assertEquals(current.addDays(-i), contacts[i].get('Birthdate'));
        }
    }

    @isTest
    static void testCrossFieldReferenceForPostUpdate() {
        Date current = Date.today();
        ATKWizard.I().wantMany(Contact.SObjectType)
            .total(10)
            .fields()
                .eval(Contact.Birthdate).value(current)
            .end()
            .generate();

        List<Contact> contacts = [SELECT Id, Birthdate FROM Contact];
        System.assertEquals(10, contacts.size());
        for (Contact contact : contacts) {
            System.assertEquals(current, contact.Birthdate);
        }

        ATKWizard.Bag bag = ATKWizard.I().wantMany(Contact.SObjectType)
            .total(10)
            .fields()
                .eval(Contact.Birthdate).value(current)
                .xref(Contact.Birthdate).addDays('$1.Birthdate', -1)
            .end()
            .generate();

        contacts = (List<Contact>)bag.get(Contact.SObjectType);
        System.assertEquals(10, contacts.size());
        for (Integer i = 0; i < contacts.size(); i++) {
            System.debug(contacts[i].Birthdate);
            System.assertEquals(current.addDays(-i), contacts[i].Birthdate);
        }
    }

    @isTest
    static void testCrossFieldReferenceOnLevelZero() {
        Long startTime = System.currentTimeMillis();
        Date current = Date.today();
        ATKWizard.Bag bag = ATKWizard.I().wantMany(Contact.SObjectType)
            .total(1500)
            .fields()
                .eval(Contact.Email).guess()
                .eval(Contact.FirstName).firstName()
                .xref(Contact.LastName).value('$0.FirstName')
                .eval(Contact.Birthdate).value(current)
                .xref(Contact.Birthdate).addDays('$1.Birthdate', -1)
            .end()
            .generate();


        Long endTime = System.currentTimeMillis();
        System.debug('ATK generate takes ' + ((endTime - startTime)/1000) + ' seconds.');
        System.debug('CPU Limit: ' + Limits.getCpuTime() + '/' + Limits.getLimitCpuTime());

        Test.startTest();
        List<Contact> contacts = (List<Contact>)bag.get(Contact.SObjectType);
        for (Integer i = 0; i < contacts.size(); i++) {
            System.assertEquals(current.addDays(-i), contacts[i].Birthdate);
            System.assertEquals(contacts[i].LastName, contacts[i].FirstName);
        }
        Test.stopTest();
    }

    @isTest
    static void testCrossFieldReferenceValidateException() {
        Boolean hasException = false;
        try {
            ATKWizard.Bag bag = ATKWizard.I().wantMany(Contact.SObjectType)
                .total(10)
                .fields()
                    .eval(Contact.FirstName).firstName()
                    .xref(Contact.Birthdate).addDays('$1.Birthdate', -1)
                .end()
                .generate();
        } catch (ATKCommon.NotFoundException ex) {
            hasException = true;
        }
        System.assert(hasException);
    }

    @isTest
    static void testCrossFieldReferenceValidateException2() {
        Boolean hasException = false;
        try {
            ATKWizard.Bag bag = ATKWizard.I().wantMany(Contact.SObjectType)
                .total(10)
                .fields()
                    .eval(Contact.FirstName).firstName()
                    .xref(Contact.LastName).value('$0.FirstName')
                .end()
                .generate();
        } catch (ATKCommon.NotFoundException ex) {
            hasException = true;
        }
        System.assert(!hasException);
    }

    @isTest
    static void testCrossFieldReferenceDependencySort() {
        Datetime currentDatetime = Datetime.now();
        ATKWizard.I().wantMany(Event.SObjectType)
            .total(10)
            .fields()
                .guard(false)
                .eval(Event.StartDateTime).value(currentDatetime)
                .xref(Event.StartDateTime).addDays('$1.EndDateTime', 1)
                .xref(Event.EndDateTime).addDays('$0.StartDateTime', 1)
                .xref(Event.ActivityDateTime).value('$0.StartDateTime')
                .eval(Event.DurationInMinutes).value(24 * 60)
                .eval(Event.Type).guess()
            .end()
            .generate();

        List<Event> events = [SELECT Id, StartDateTime, EndDateTime, ActivityDateTime, Type FROM Event];
        System.debug(events);
        System.assertEquals(10, events.size());
        Datetime eventDatetime = currentDatetime;
        for (Event event : events) {
            System.assertNotEquals(null, event.Type);
            System.assertEquals(eventDatetime, event.StartDateTime);
            System.assertEquals(eventDatetime, event.ActivityDateTime);
            eventDatetime = eventDatetime.addDays(1);
            System.assertEquals(eventDatetime, event.EndDateTime);
            eventDatetime = eventDatetime.addDays(1);
        }
    }

    @isTest
    static void testCrossFieldReferenceDependencySort2() {
        Datetime currentDatetime = Datetime.now();
        ATKWizard.I().wantMany(Event.SObjectType)
            .total(10)
            .fields()
                .guard(false)
                .eval(Event.StartDateTime).repeat(currentDatetime, currentDatetime.addDays(2))
                .xref(Event.StartDateTime).addDays('$2.EndDateTime', 3)
                .xref(Event.EndDateTime).addDays('$0.StartDateTime', 1)
                .xref(Event.ActivityDateTime).value('$0.StartDateTime')
                .eval(Event.DurationInMinutes).value(24 * 60)
            .end()
            .generate();

        List<Event> events = [SELECT Id, StartDateTime, EndDateTime, ActivityDateTime FROM Event];
        System.debug(events);
        System.assertEquals(10, events.size());
        Datetime eventDatetime = currentDatetime;
        for (Event event : events) {
            System.assertEquals(eventDatetime, event.StartDateTime);
            System.assertEquals(eventDatetime, event.ActivityDateTime);
            eventDatetime = eventDatetime.addDays(1);
            System.assertEquals(eventDatetime, event.EndDateTime);
            eventDatetime = eventDatetime.addDays(1);
        }
    }
}
