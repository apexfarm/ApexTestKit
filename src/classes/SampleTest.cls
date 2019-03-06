/**
 * Apex Test Kit
 */
@isTest
private with sharing class SampleTest {
    @isTest
    static void testFieldGuessValue() {
        Integer accountTotal = 5;
        Integer contactTotal = 10;
        ATKWizard.I().wantMany('Account')
            .guess(new List<String> { 'NumberOfEmployees', 'Fax', 'Industry' })
            .total(accountTotal)
            .hasMany('Contact')
                .total(contactTotal)
            .generate();
        List<Account> accountList = [SELECT Id, Name, NumberOfEmployees, Fax, Industry FROM Account];
        System.debug(accountList);
        System.assertEquals(accountTotal, accountList.size());
        for (Account account : accountList) {
            System.assert(account.Fax != null);
            System.assert(account.Name != null);
            System.assert(account.Industry != null);
            System.assert(account.NumberOfEmployees != null);
        }
        List<Contact> contactList = [SELECT Id, LastName FROM Contact];
        for (Contact contact : contactList) {
            System.assert(contact.LastName != null);
        }
        System.assertEquals(contactTotal, contactList.size());
    }

    /*
     * FIELD KEYWORD TESTS
     */

    @isTest
    static void testFieldWithRuleList() {
        ATKWizard.I().wantMany('Account')
            .total(6)
            .fields(new Map<String, Object> {
                'Name' => new List<String> {
                    'Microsoft-{{###}}',
                    'Google-{{###}}',
                    'Apple-{{###}}'
                }
            })
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
        ATKWizard.I().wantMany('Account')
            .total(6)
            .fields(new Map<String, Object> {
                'Name' => new Set<String> {
                    'Microsoft-{{###}}',
                    'Google-{{###}}',
                    'Apple-{{###}}'
                }
            })
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
        ATKWizard.I().wantMany('Account')
            .total(100)
            .fields(new Map<String, Object> {
                'Name' => new List<String> {
                    'Microsoft-{{###}}',
                    'Google-{{###}}',
                    'Apple-{{###}}'
                },
                'Fax' => '{{1##-###-####}}'
            })
            .generate();

        List<Account> accountList = [SELECT Id, Name, Fax FROM Account];
        System.debug(accountList.size());
        for (Account account : accountList) {
            System.debug(String.format('account: Id({0}), Name({1}), Fax({2})', new List<String> {
                account.Id, account.Name, account.Fax
            }));
        }

        System.assertEquals(100, accountList.size());
    }

    @isTest
    static void testFieldPostUpdate() {
        ATKWizard.Bag bag = ATKWizard.I().wantMany('Account')
            .total(10)
            .fields(new Map<String, Object> {
                'Name' => new List<String> {
                    'Microsoft-{{###}}'
                }
            })
            .generate();

        List<Account> accountList = [SELECT Id, Name FROM Account];
        System.assertEquals(10, accountList.size());
        for (Account account : accountList) {
            System.assert(account.Name.startsWith('Microsoft-'));
        }

        ATKWizard.I().wantMany('Account')
            .fromList(bag.get('Account'))
            .fields(new Map<String, Object> {
                'Name' => new List<String> {
                    'Google-{{###}}'
                }
            })
            .generate();

        accountList = [SELECT Id, Name FROM Account];
        System.assertEquals(10, accountList.size());
        for (Account account : accountList) {
            System.assert(account.Name.startsWith('Google-'));
        }
    }

    @isTest
    static void testFieldPostUpdateWithSecondFromList() {
        ATKWizard.Bag bag = ATKWizard.I().wantMany('Account')
            .total(10)
            .fields(new Map<String, Object> {
                'Name' => new List<String> {
                    'Microsoft-{{###}}'
                }
            })
            .generate();

        List<Account> accountList = [SELECT Id, Name FROM Account];
        System.assertEquals(10, accountList.size());
        for (Account account : accountList) {
            System.assert(account.Name.startsWith('Microsoft-'));
        }

        ATKWizard.I().wantMany('Account')
            .fromList(bag.get('Account'))
            .fromList(new List<Account> {
                new Account(), new Account(), new Account(), new Account(), new Account()
            })
            .fields(new Map<String, Object> {
                'Name' => new List<String> {
                    'Google-{{###}}'
                }
            })
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
    static void testRelationshipHasMany() {
        Integer accountTotal = 500;
        Integer contactTotal = 1000;
        Long startTime = System.currentTimeMillis();
        ATKWizard.Bag bag = ATKWizard.I().wantMany('Account')
            .total(accountTotal)
            .fields(new Map<String, Object> {
                'Name' => new List<String> {
                    'Microsoft-{{###}}',
                    'Google-{{###}}',
                    'Apple-{{###}}'
                },
                'Fax' => '{{1##-###-####}}',
                'NumberOfEmployees' => '{!random.number(8, 0)}'
            })
            .guess(new List<String> {'Industry'})
            .hasMany('Contact')
                .referenceBy('AccountId')
                .total(contactTotal)
                .fields(new Map<String, Object> {
                    'FirstName' => '{!name.firstName(female)}',
                    'LastName' => '{!name.lastName}',
                    'Birthdate' => '{!dates.past}',
                    'Email' => '{!internet.email}'
                })
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
    static void testRelationshipHasManyWithLessChild() {
        ATKWizard.I().wantMany('Account')
            .fields(new Map<String, Object> {
                'Name' => 'Google-{{###}}'
            })
            .total(10)
            .hasMany('Contact')
                .referenceBy('AccountId')
                .fields(new Map<String, Object> {
                    'LastName' => '{!name.lastName}'
                })
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
    static void testRelationshipHasManyList() {
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

        ATKWizard.I().wantMany('Account')
            .fromList(accountList)
            .hasMany('Contact')
                .fromList(contactList)
                .referenceBy('AccountId')
            .generate();

        accountList = [SELECT Id, (SELECT Id FROM Contacts) FROM Account];
        System.assertEquals(10, accountList.size());
        for (Account account : accountList) {
            System.assertEquals(4, account.Contacts.size());
        }
    }

    @isTest
    static void testRelationshipBelongsTo() {
        ATKWizard.I().wantMany('Contact')
            .fields(new Map<String, Object> {
                    'LastName' => '{!name.lastName}'
                })
            .total(40)
            .belongsTo('Account')
                .referenceBy('AccountId')
                .fields(new Map<String, Object> {
                    'Name' => 'Google-{{###}}'
                })
                .total(10)
            .generate();

        List<Account> accountList = [SELECT Id, (SELECT Id FROM Contacts) FROM Account];
        List<Contact> contactList = [SELECT Id FROM Contact];

        System.assertEquals(10, accountList.size());
        System.assertEquals(40, contactList.size());
    }

    @isTest
    static void testRelationshipBelongsToWithLessChild() {
        ATKWizard.I().wantMany('Contact')
            .fields(new Map<String, Object> {
                    'LastName' => '{!name.lastName}'
                })
            .total(4)
            .belongsTo('Account')
                .referenceBy('AccountId')
                .fields(new Map<String, Object> {
                    'Name' => 'Google-{{###}}'
                })
                .total(10)
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
    static void testRelationshipHasManyBelongsTo() {
        Id pricebook2Id = Test.getStandardPricebookId();

        ATKWizard.Bag bag = ATKWizard.I().wantMany('Product2')
            .total(5)
            .hasMany('PricebookEntry')
                .referenceBy('Product2Id')
                .fields(new Map<String, Object> {
                    'Pricebook2Id' => pricebook2Id,
                    'UseStandardPrice' => false,
                    'IsActive' => true
                })
                .total(5)
            .generate();

        ATKWizard.I().wantMany('Pricebook2')
            .total(5)
            .hasMany('PricebookEntry')
                .referenceBy('Pricebook2Id')
                .fields(new Map<String, Object> {
                    'UseStandardPrice' => false,
                    'IsActive' => true
                })
                .total(25)
                .belongsTo('Product2')
                    .referenceBy('Product2Id')
                    .fromList(bag.get('Product2'))
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
        ATKWizard.I().wantMany('Account')
            .total(3)
            .hasMany('Contact')
                .referenceBy('AccountId')
                .total(6)
            .also()
            .hasMany('Contract')
                .referenceBy('AccountId')
                .fields(new Map<String, Object> {
                    'StartDate' => '{!dates.between(2018-7-1, 2018-7-31)}',
                    'ContractTerm' => 12,
                    'Status' => 'Draft'
                })
                .total(6)
                .hasMany('Order')
                    .referenceBy('ContractId')
                    .fields(new Map<String, Object> {
                        'EffectiveDate' => '{!dates.between(2018-8-1, 2018-8-31)}',
                        'EndDate' => '{!dates.between(2019-6-1, 2019-6-30)}',
                        'IsReductionOrder' => false,
                        'Status' => 'Draft'
                    })
                    .total(12)
            .also(2)
            .hasMany('Opportunity')
                .referenceBy('AccountId')
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
        ATKWizard.Bag bag = ATKWizard.I().wantMany('Account')
            .total(3)
            .hasMany('Contact')
                .referenceBy('AccountId')
                .total(6)
            .generate();

        ATKWizard.I().wantMany('Account')
            .fromList(bag.get('Account'))
            .hasMany('Opportunity')
                .fields(new Map<String, Object> {
                    'CloseDate' => '{!dates.between(2018-7-1, 2018-8-1)}'
                })
                .referenceBy('AccountId')
                .total(6)
                .hasMany('OpportunityContactRole')
                    .referenceBy('OpportunityId')
                    .total(36)
                    .belongsTo('Contact')
                        .referenceBy('ContactId')
                        .fromList(bag.get('Contact'))
            .generate();

        List<OpportunityContactRole> ocrList = [SELECT Id FROM OpportunityContactRole];
        System.assertEquals(36, ocrList.size());
    }

    @isTest
    static void testRelationshipOptionalReferenceBy() {
        ATKWizard.I().wantMany('Account')
            .total(10)
            .hasMany('Contact')
                .total(20)
                .hasMany('OpportunityContactRole')
                    .total(20)
                    .belongsTo('Opportunity')
                        .total(20)
                        .fields(new Map<String, Object> {
                            'CloseDate' => '{!dates.between(2018-7-1, 2018-8-1)}'
                        })
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
        ATKWizard.Bag bag = ATKWizard.I().wantMany('Contact')
            .total(10)
            .origin(new Map<String, Object> {
                'Birthdate' => current
            })
            .fields(new Map<String, Object> {
                'Birthdate' => '{!dates.addDays($1.Birthdate, -1)}'
            })
            .generate();

        List<SObject> contacts = bag.get('Contact');
        for (Integer i = 0; i < contacts.size(); i++) {
            System.debug(contacts[i].get('Birthdate'));
            System.assertEquals(current.addDays(-i), contacts[i].get('Birthdate'));
        }
    }

    @isTest
    static void testCrossFieldReferenceForPostUpdate() {
        Date current = Date.today();
        ATKWizard.I().wantMany('Contact')
            .fields(new Map<String, Object> {
                'Birthdate' => current
            })
            .total(10)
            .generate();

        List<Contact> contacts = [SELECT Id, Birthdate FROM Contact];
        System.assertEquals(10, contacts.size());
        for (Contact contact : contacts) {
            System.assertEquals(current, contact.Birthdate);
        }

        ATKWizard.Bag bag = ATKWizard.I().wantMany('Contact')
            .total(10)
            .origin(new Map<String, Object> {
                'Birthdate' => current
            })
            .fields(new Map<String, Object> {
                'Birthdate' => '{!dates.addDays($1.Birthdate, -1)}'
            })
            .generate();

        contacts = (List<Contact>)bag.get('Contact');
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
        ATKWizard.Bag bag = ATKWizard.I().wantMany('Contact')
            .total(1500)
            .origin(new Map<String, Object> {
                'Birthdate' => current
            })
            .fields(new Map<String, Object> {
                'FirstName' => '{!name.firstName}',
                'LastName' => 'A {!value.get($0.FirstName)}',
                'Birthdate' => '{!dates.addDays($1.Birthdate, -1)}'
            })
            .guess(new List<String> {'Email'})
            .generate();


        Long endTime = System.currentTimeMillis();
        System.debug('ATK generate takes ' + ((endTime - startTime)/1000) + ' seconds.');
        System.debug('CPU Limit: ' + Limits.getCpuTime() + '/' + Limits.getLimitCpuTime());

        Test.startTest();
        List<Contact> contacts = (List<Contact>)bag.get('Contact');
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
            ATKWizard.Bag bag = ATKWizard.I().wantMany('Contact')
            .total(10)
            .fields(new Map<String, Object> {
                'FirstName' => '{!name.firstName}',
                'Birthdate' => '{!dates.addDays($1.Birthdate, -1)}'
            })
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
            ATKWizard.Bag bag = ATKWizard.I().wantMany('Contact')
            .total(10)
            .fields(new Map<String, Object> {
                'FirstName' => '{!name.firstName}',
                'LastName' => 'A {!value.get($0.FirstName)}'
            })
            .generate();
        } catch (ATKCommon.NotFoundException ex) {
            hasException = true;
        }
        System.assert(!hasException);
    }

    @isTest
    static void testCrossFieldReferenceValidateException3() {
        Boolean hasException = false;
        try {
            ATKWizard.Bag bag = ATKWizard.I().wantMany('Contact')
            .total(10)
            .fields(new Map<String, Object> {
                'FirstName' => '{!name.firstName}',
                'LastName' => new List<String> {
                    'A {!value.get($0.FirstName)}',
                    'B {!value.get($0.FirstName)}',
                    'C {!value.get($0.FirstName)}'
                }
            })
            .generate();
        } catch (ATKCommon.NotFoundException ex) {
            hasException = true;
        }
        System.assert(hasException);
    }

    @isTest
    static void testCrossFieldReferenceDependencySort() {
        Datetime currentDatetime = Datetime.now();
        ATKWizard.I().wantMany('Event')
            .origin(new Map<String, Object> {
                'StartDateTime' => currentDatetime
            })
            .guess(false, new List<String> { 'Type' })
            .fields(new Map<String, Object> {
                'StartDateTime' => '{!dates.addDays($1.EndDateTime, 1)}',
                'EndDateTime' => '{!dates.addDays($0.StartDateTime, 1)}',
                'ActivityDateTime' => '{!value.get($0.StartDateTime)}',
                'DurationInMinutes' => 24 * 60
            })
            .total(10)
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
        ATKWizard.I().wantMany('Event')
            .origin(new Map<String, Object> {
                'StartDateTime' => new List<Object>{ currentDatetime, currentDatetime.addDays(2) }
            })
            .guess(false)
            .fields(new Map<String, Object> {
                'StartDateTime' => '{!dates.addDays($2.EndDateTime, 3)}',
                'EndDateTime' => '{!dates.addDays($0.StartDateTime, 1)}',
                'ActivityDateTime' => '{!value.get($0.StartDateTime)}',
                'DurationInMinutes' => 24 * 60
            })
            .total(10)
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
