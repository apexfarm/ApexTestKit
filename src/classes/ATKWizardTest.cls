/**
 * Apex Test Kit
 */
@isTest
private with sharing class ATKWizardTest {
    @isTest
    static void TestTotal() {
        ATKWizard.I().wantMany('Account').total(100).generate();
        List<Account> accountList = [SELECT Id FROM Account];
        System.assertEquals(100, accountList.size());
    }

    /*
     * FIELD KEYWORD TESTS
     */

    @isTest
    static void TestFieldWithRuleList() {
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
    static void TestFieldWithRuleSet() {
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
    static void TestFieldWithRules() {
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
    static void TestFieldPostUpdate() {
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

    /*
     * CREATION KEYWORD TESTS
     */

    @isTest
    static void TestRelationshipHasMany() {
        ATKWizard.Bag bag = ATKWizard.I().wantMany('Account')
            .total(10)
            .fields(new Map<String, Object> {
                'Name' => new List<String> {
                    'Microsoft-{{###}}',
                    'Google-{{###}}',
                    'Apple-{{###}}'
                },
                'Fax' => '{{1##-###-####}}'
            })
            .hasMany('Contact')
                .referenceBy('AccountId')
                .total(20)
                .fields(new Map<String, Object> {
                    'FirstName' => '{!name.firstName(female)}',
                    'LastName' => '{!name.lastName}'
                })
            .generate();

        System.debug(bag.get('Account'));
        System.debug(bag.get('Contact'));

        List<Account> accountList = [SELECT Id, (SELECT Id FROM Contacts) FROM Account];
        List<Contact> contactList = [SELECT Id FROM Contact];

        System.assertEquals(10, accountList.size());
        System.assertEquals(20, contactList.size());
        for (Account account : accountList) {
            System.assertEquals(2, account.Contacts.size());
        }
    }

    @isTest
    static void TestRelationshipHasManyWithLessChild() {
        ATKWizard.I().wantMany('Account')
            .total(10)
            .hasMany('Contact')
                .referenceBy('AccountId')
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
    static void TestRelationshipHasManyList() {
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
        insert contactList;

        ATKWizard.I().wantMany('Account')
            .fromList(accountList)
            .hasMany('Contact')
                .fromList(contactList)
                .referenceBy('AccountId')
            .generate();

        accountList = [SELECT Id, (SELECT Id FROM Contacts) FROM Account];
        for (Account account : accountList) {
            System.assertEquals(4, account.Contacts.size());
        }
    }

    @isTest
    static void TestRelationshipBelongsTo() {
        ATKWizard.I().wantMany('Contact')
            .total(40)
            .belongsTo('Account')
                .referenceBy('AccountId')
                .total(10)
            .generate();

        List<Account> accountList = [SELECT Id, (SELECT Id FROM Contacts) FROM Account];
        List<Contact> contactList = [SELECT Id FROM Contact];

        System.assertEquals(10, accountList.size());
        System.assertEquals(40, contactList.size());
    }

    @isTest
    static void TestRelationshipBelongsToWithLessChild() {
        ATKWizard.I().wantMany('Contact')
            .total(4)
            .belongsTo('Account')
                .referenceBy('AccountId')
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
    static void TestRelationshipOptionalReferenceBy() {
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
}
