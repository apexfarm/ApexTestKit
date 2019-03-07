/**
 * Apex Test Kit
 */
@isTest
private with sharing class SampleTest {
    // @isTest
    // static void testDataFactory() {
    //     Integer accountTotal = 5;
    //     Integer contactTotal = 10;
    //     SampleTestDataFactory.generateAccountsWithContacts(accountTotal, contactTotal);

    //     List<Account> accountList = [SELECT Id, Name, NumberOfEmployees, Fax, Industry FROM Account];
    //     System.assertEquals(accountTotal, accountList.size());
    //     for (Account account : accountList) {
    //         System.assert(account.Fax != null);
    //         System.assert(account.Name != null);
    //         System.assert(account.Industry != null);
    //         System.assert(account.NumberOfEmployees != null);
    //     }
    //     List<Contact> contactList = [SELECT Id, LastName FROM Contact];
    //     System.assertEquals(contactTotal, contactList.size());
    //     for (Contact contact : contactList) {
    //         System.assert(contact.LastName != null);
    //     }
    // }

    @isTest
    static void testFieldGuessValue() {
        Integer accountTotal = 5;
        Integer contactTotal = 10;
        ATKWizard.I().wantMany(Account.SObjectType)
            .total(accountTotal)
            .fields()
                .guard()
                .useEval(Account.NumberOfEmployees)
                .useEval(Account.Fax)
                .useEval(Account.Industry)
            .end()
            .haveMany(Contact.SObjectType)
                .total(contactTotal)
                .fields().guard().end()
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

    /*
     * FIELD KEYWORD TESTS
     */

    @isTest
    static void testFieldWithRuleList() {
        ATKWizard.I().wantMany(Account.SObjectType)
            .total(6)
            .fields()
                .guard()
                .useEval(Account.Name, new List<String> {
                    'Microsoft-{{###}}',
                    'Google-{{###}}',
                    'Apple-{{###}}'
                })
            .end()
            .generate();

        List<Account> accountList = [SELECT Id, Name, Fax FROM Account];
        for (Account account : accountList) {
            System.debug(String.format('account: Id({0}), Name({1}), Fax({2})', new List<String> {
                account.Id, account.Name, account.Fax
            }));
        }

        System.assertEquals(6, accountList.size());
        System.assert(accountList[0].Name.startsWith('Microsoft'));
        System.assert(accountList[1].Name.startsWith('Google'));
        System.assert(accountList[2].Name.startsWith('Apple'));
        System.assert(accountList[3].Name.startsWith('Microsoft'));
        System.assert(accountList[4].Name.startsWith('Google'));
        System.assert(accountList[5].Name.startsWith('Apple'));
    }

    @isTest
    static void testFieldWithRuleSet() {
        ATKWizard.I().wantMany(Account.SObjectType)
            .total(6)
            .fields()
                .guard()
                .useEval(Account.Name, new Set<String> {
                    'Microsoft-{{###}}',
                    'Google-{{###}}',
                    'Apple-{{###}}'
                })
            .end()
            .generate();

        List<Account> accountList = [SELECT Id, Name, Fax FROM Account];
        for (Account account : accountList) {
            System.debug(String.format('account: Id({0}), Name({1}), Fax({2})', new List<String> {
                account.Id, account.Name, account.Fax
            }));
        }

        System.assertEquals(6, accountList.size());
    }

    @isTest
    static void testFieldWithRules() {
        ATKWizard.I().wantMany(Account.SObjectType)
            .total(10)
            .fields()
                .guard()
                .useEval(Account.Name, new List<String> {
                    'Microsoft-{{###}}',
                    'Google-{{###}}',
                    'Apple-{{###}}'
                })
                .useEval(Account.Fax, '{{1##-###-####}}')
            .end()
            .generate();

        List<Account> accountList = [SELECT Id, Name, Fax FROM Account];
        System.assertEquals(10, accountList.size());
    }

    @isTest
    static void testFieldPostUpdate() {
        ATKWand.IWizardBag bag = ATKWizard.I().wantMany(Account.SObjectType)
            .total(10)
            .fields()
                .guard()
                .useEval(Account.Name, new List<String> {
                    'Microsoft-{{###}}'
                })
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
                .guard()
                .useEval(Account.Name, new List<String> {
                    'Google-{{###}}'
                })
            .end()
            .generate();

        accountList = [SELECT Id, Name FROM Account];
        System.assertEquals(10, accountList.size());
        for (Account account : accountList) {
            System.assert(account.Name.startsWith('Google-'));
        }
    }

    @isTest
    static void testFieldPostUpdateWithSeconduseList() {
        ATKWand.IWizardBag bag = ATKWizard.I().wantMany(Account.SObjectType)
            .total(10)
            .fields()
                .guard()
                .useEval(Account.Name, new List<String> {
                    'Microsoft-{{###}}'
                })
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
                .guard()
                .useEval(Account.Name, new List<String> {
                    'Google-{{###}}'
                })
            .end()
            .generate();

        accountList = [SELECT Id, Name FROM Account];
        System.assertEquals(15, accountList.size());
        for (Account account : accountList) {
            System.assert(account.Name.startsWith('Google-'));
        }
    }

    /*
     * CREATION KEYWORD TESTS
     */

    @isTest
    static void testRelationshipHaveMany() {
        Integer accountTotal = 500;
        Integer contactTotal = 1000;
        Long startTime = System.currentTimeMillis();
        ATKWand.IWizardBag bag = ATKWizard.I().wantMany(Account.SObjectType)
            .total(accountTotal)
            .fields()
                .guard()
                .useEval(Account.Industry)
                .useEval(Account.Name, 'Microsoft-{{###}}')
                .useEval(Account.Fax, '{{1##-###-####}}')
                .useEval(Account.NumberOfEmployees, '{!random.number(8, 0)}')
            .end()
            .haveMany(Contact.SObjectType)
                .referenceBy(Contact.AccountId)
                .total(contactTotal)
                .fields()
                    .guard()
                    .useEval(Contact.FirstName, '{!name.firstName(female)}')
                    .useEval(Contact.LastName, '{!name.lastName}')
                    .useEval(Contact.Birthdate, '{!dates.past}')
                    .useEval(Contact.Email, '{!internet.email}')
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
                .guard()
                .useEval(Account.Name, 'Google-{{###}}')
            .end()
            .total(10)
            .haveMany(Contact.SObjectType)
                .referenceBy(Contact.AccountId)
                .fields()
                    .guard()
                    .useEval(Contact.LastName, '{!name.lastName}')
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
                .guard()
                .useEval(Contact.LastName, '{!name.lastName}')
            .end()
            .belongTo(Account.SObjectType)
                .referenceBy(Contact.AccountId)
                .total(10)
                .fields()
                    .guard()
                    .useEval(Account.Name, 'Google-{{###}}')
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
                .guard()
                .useEval(Contact.LastName, '{!name.lastName}')
            .end()
            .belongTo(Account.SObjectType)
                .referenceBy(Contact.AccountId)
                .total(10)
                .fields()
                    .guard()
                    .useEval(Account.Name, 'Google-{{###}}')
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

        ATKWand.IWizardBag bag = ATKWizard.I().wantMany(Product2.SObjectType)
            .total(5)
            .fields().guard().end()
            .haveMany(PricebookEntry.SObjectType)
                .referenceBy(PricebookEntry.Product2Id)
                .total(5)
                .fields()
                    .guard()
                    .useEval(PricebookEntry.Pricebook2Id, pricebook2Id)
                    .useEval(PricebookEntry.UseStandardPrice, false)
                    .useEval(PricebookEntry.IsActive, true)
                .end()
            .generate();

        ATKWizard.I().wantMany(Pricebook2.SObjectType)
            .total(5)
            .fields().guard().end()
            .haveMany(PricebookEntry.SObjectType)
                .referenceBy(PricebookEntry.Pricebook2Id)
                .total(25)
                .fields()
                    .guard()
                    .useEval(PricebookEntry.UseStandardPrice, false)
                    .useEval(PricebookEntry.IsActive, true)
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
            .fields().guard().end()
            .total(3)
            .haveMany(Contact.SObjectType)
                .referenceBy(Contact.AccountId)
                .total(6)
                .fields().guard().end()
            .also()
            .haveMany(Contract.SObjectType)
                .referenceBy(Contract.AccountId)
                .total(6)
                .fields()
                    .guard()
                    .useEval(Contract.StartDate, '{!dates.between(2018-7-1, 2018-7-31)}')
                    .useEval(Contract.ContractTerm, 12)
                    .useEval(Contract.Status, 'Draft')
                .end()
                .haveMany(Order.SObjectType)
                    .referenceBy(Order.ContractId)
                    .total(12)
                    .fields()
                        .guard()
                        .useEval(Order.EffectiveDate, '{!dates.between(2018-8-1, 2018-8-31)}')
                        .useEval(Order.EndDate, '{!dates.between(2019-6-1, 2019-6-30)}')
                        .useEval(Order.IsReductionOrder, false)
                        .useEval(Order.Status, 'Draft')
                    .end()
            .also(2)
            .haveMany(Opportunity.SObjectType)
                .referenceBy(Opportunity.AccountId)
                .total(6)
                .fields().guard().end()
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
        ATKWand.IWizardBag bag = ATKWizard.I().wantMany(Account.SObjectType)
            .total(3)
            .fields().guard().end()
            .haveMany(Contact.SObjectType)
                .referenceBy(Contact.AccountId)
                .total(6)
                .fields().guard().end()
            .generate();

        ATKWizard.I().wantMany(Account.SObjectType)
            .useList(bag.get(Account.SObjectType))
            .haveMany(Opportunity.SObjectType)
                .referenceBy(Opportunity.AccountId)
                .total(6)
                .fields()
                    .guard()
                    .useEval(Opportunity.CloseDate, '{!dates.between(2018-7-1, 2018-8-1)}')
                .end()
                .haveMany(OpportunityContactRole.SObjectType)
                    .referenceBy(OpportunityContactRole.OpportunityId)
                    .total(36)
                    .fields().guard().end()
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
            .fields().guard().end()
            .haveMany(Contact.SObjectType)
                .fields().guard().end()
                .total(20)
                .haveMany(OpportunityContactRole.SObjectType)
                    .fields().guard().end()
                    .total(20)
                    .belongTo(Opportunity.SObjectType)
                        .fields()
                            .guard()
                            .useEval(Opportunity.CloseDate, '{!dates.between(2018-7-1, 2018-8-1)}')
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

    @isTest
    static void testCrossFieldReference() {
        Date current = Date.today();
        ATKWand.IWizardBag bag = ATKWizard.I().wantMany(Contact.SObjectType)
            .total(10)
            .fields()
                .guard()
                .useXref(Contact.Birthdate, '{!dates.addDays($1.Birthdate, -1)}', current)
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
                .guard()
                .useEval(Contact.Birthdate, current)
            .end()
            .generate();

        List<Contact> contacts = [SELECT Id, Birthdate FROM Contact];
        System.assertEquals(10, contacts.size());
        for (Contact contact : contacts) {
            System.assertEquals(current, contact.Birthdate);
        }

        ATKWand.IWizardBag bag = ATKWizard.I().wantMany(Contact.SObjectType)
            .total(10)
            .fields()
                .guard()
                .useXref(Contact.Birthdate, '{!dates.addDays($1.Birthdate, -1)}', current)
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
        ATKWand.IWizardBag bag = ATKWizard.I().wantMany(Contact.SObjectType)
            .total(1500)
            .fields()
                .guard()
                .useEval(Contact.Email)
                .useEval(Contact.FirstName, '{!name.firstName}')
                .useXref(Contact.LastName, 'A {!value.get($0.FirstName)}')
                .useXref(Contact.Birthdate, '{!dates.addDays($1.Birthdate, -1)}', current)
            .end()
            .generate();


        Long endTime = System.currentTimeMillis();
        System.debug('ATK generate takes ' + ((endTime - startTime)/1000) + ' seconds.');
        System.debug('CPU Limit: ' + Limits.getCpuTime() + '/' + Limits.getLimitCpuTime());

        Test.startTest();
        List<Contact> contacts = (List<Contact>)bag.get(Contact.SObjectType);
        for (Integer i = 0; i < contacts.size(); i++) {
            System.assertEquals(current.addDays(-i), contacts[i].Birthdate);
            System.assertEquals(contacts[i].LastName, 'A ' + contacts[i].FirstName);
        }
        Test.stopTest();
    }

    @isTest
    static void testCrossFieldReferenceValidateException() {
        Boolean hasException = false;
        try {
            ATKWand.IWizardBag bag = ATKWizard.I().wantMany(Contact.SObjectType)
                .total(10)
                .fields()
                    .guard()
                    .useEval(Contact.FirstName, '{!name.firstName}')
                    .useXref(Contact.Birthdate, '{!dates.addDays($1.Birthdate, -1)}')
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
            ATKWand.IWizardBag bag = ATKWizard.I().wantMany(Contact.SObjectType)
                .total(10)
                .fields()
                    .guard()
                    .useEval(Contact.FirstName, '{!name.firstName}')
                    .useXref(Contact.LastName, 'A {!value.get($0.FirstName)}')
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
                .useXref(Event.StartDateTime, '{!dates.addDays($1.EndDateTime, 1)}', currentDatetime)
                .useXref(Event.EndDateTime, '{!dates.addDays($0.StartDateTime, 1)}')
                .useXref(Event.ActivityDateTime, '{!value.get($0.StartDateTime)}')
                .useEval(Event.DurationInMinutes, 24 * 60)
                .useEval(Event.Type)
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
                .useXref(Event.StartDateTime, '{!dates.addDays($2.EndDateTime, 3)}', new List<Object>{
                    currentDatetime,
                    currentDatetime.addDays(2)
                })
                .useXref(Event.EndDateTime, '{!dates.addDays($0.StartDateTime, 1)}')
                .useXref(Event.ActivityDateTime, '{!value.get($0.StartDateTime)}')
                .useEval(Event.DurationInMinutes, 24 * 60)
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
