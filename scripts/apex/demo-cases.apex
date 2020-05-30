Savepoint sp = Database.setSavepoint();

ATK.SaveResult result = ATK.prepare(Account.SObjectType, 200)
    .field(Account.Name).index('Name-{0000}')
    .withChildren(Contact.SObjectType, Contact.AccountId, 400)
        .field(Contact.LastName).index('Name-{0000}')
        .field(Contact.Email).index('test.user+{0000}@email.com')
        .field(Contact.MobilePhone).index('+86 186 7777 {0000}')
        .field(Contact.Birthdate).addDays(Date.newInstance(2020, 1, 1), 1)
        .withChildren(Case.SObjectType, Case.ContactId, 800) // Parent Cases
            .withParents(Account.SObjectType, Case.AccountId)
            .also()
            .withParents(Case.SObjectType, Case.ParentId, 800) // Child Cases
                .withParents(Account.SObjectType, Case.AccountId)
                .also()
                .withParents(Contact.SObjectType, Case.ContactId)
    .save(true);

List<SObject> accounts = result.get(Account.SObjectType);
List<SObject> contacts = result.get(Contact.SObjectType);
List<SObject> cases = result.get(Case.SObjectType);

for (Integer i = 0; i< 200; ++i) {
    System.assertEquals(accounts[i].Id, contacts[i*2].get('AccountId'));
    System.assertEquals(accounts[i].Id, contacts[i*2+1].get('AccountId'));

    System.assertEquals(accounts[i].Id, cases[i*4].get('AccountId'));
    System.assertEquals(accounts[i].Id, cases[i*4+1].get('AccountId'));
    System.assertEquals(accounts[i].Id, cases[i*4+2].get('AccountId'));
    System.assertEquals(accounts[i].Id, cases[i*4+3].get('AccountId'));

    System.assertEquals(contacts[i*2].Id, cases[i*4].get('ContactId'));
    System.assertEquals(contacts[i*2].Id, cases[i*4+1].get('ContactId'));
    System.assertEquals(contacts[i*2+1].Id, cases[i*4+2].get('ContactId'));
    System.assertEquals(contacts[i*2+1].Id, cases[i*4+3].get('ContactId'));
}

Database.rollback(sp);
