{
    // 1. Setup > Digital Experiences > Settings 
    // 2. Select Allow using standard external profiles for self-registration, user creation, and login.
    // 3. Portal Account Owener must have a role
    Savepoint sp = Database.setSavepoint();

    ATK.SaveResult result = ATK.prepare(Account.SObjectType, 1)
        .field(Account.Name).index('Name-{000}')
        .withChildren(Contact.SObjectType, Contact.AccountId, 3)
            .field(Contact.LastName).index('Name-{000}')
            .withChildren(User.SObjectType, User.ContactId, 3)
                .profile('Customer Community User')
                .field(User.FirstName).repeat('FirstName')
                .field(User.LastName).repeat('LastName')
                .field(User.Email).index('test.user+{0000}@email.com')
                .field(User.UserName).index('test.user+{0000}@email.com')
                .field(User.Alias).index('test{0000}')
                .field(User.EmailEncodingKey).repeat('UTF-8')
                .field(User.LanguageLocaleKey).repeat('en_US')
                .field(User.LocaleSidKey).repeat('en_US')
                .field(User.TimeZoneSidKey).repeat('Pacific/Auckland')
        .mock();

    for (Integer i = 0; i < 3; i++ ) {
        User user = (User)result.get(User.SObjectType)[i];
        Contact contact = (Contact)result.get(Contact.SObjectType)[i];

        System.assertEquals(contact, user.Contact);
    }

    Database.rollback(sp);
}

{
    Savepoint sp = Database.setSavepoint();

    ATK.SaveResult result = ATK.prepare(User.SObjectType, 10)
        .permissionSet('Survey Creator')
        .profile('Chatter Free User')
        .field(User.FirstName).repeat('FirstName')
        .field(User.LastName).repeat('LastName')
        .field(User.Email).index('test.user+{0000}@email.com')
        .field(User.UserName).index('test.user+{0000}@email.com')
        .field(User.Alias).index('test{0000}')
        .field(User.EmailEncodingKey).repeat('UTF-8')
        .field(User.LanguageLocaleKey).repeat('en_US')
        .field(User.LocaleSidKey).repeat('en_US')
        .field(User.TimeZoneSidKey).repeat('Pacific/Auckland')
        .mock();

    Database.rollback(sp);
}
