@isTest
public with sharing class SampleTestDataFactory {
    public static final String ACCOUNT_WITH_FAX = 'SampleTestDataFactory/ACCOUNT_WITH_FAX';
    public static final String CONTACT_WITH_EMAIL = 'SampleTestDataFactory/CONTACT_WITH_EMAIL';

    public static String registerAccountWithFax() {
        ATKWizard.I().wantTemp(Account.SObjectType, ACCOUNT_WITH_FAX)
            .guard()
            .fields()
                .eval(Account.Name, 'Microsoft-{{###}}')
                .eval(Account.Fax, '{{1##-###-####}}')
                .eval(Account.NumberOfEmployees, '{!random.number(8, 0)}')
                .eval(Account.Industry)
                .eval(Account.Industry)
            .end()
            .register();
        return ACCOUNT_WITH_FAX;
    }

    public static String registerContactWithEmail() {
        ATKWizard.I().wantTemp(Contact.SObjectType, CONTACT_WITH_EMAIL)
            .guard()
            .fields()
                .eval(Contact.FirstName, '{!name.firstName(female)}')
                .eval(Contact.LastName, '{!name.lastName}')
                .eval(Contact.Birthdate, '{!dates.past}')
                .eval(Contact.Email, '{!internet.email}')
            .end()
            .register();
        return CONTACT_WITH_EMAIL;
    }

    public static void generateAccountsWithContacts(Integer accountTotal, Integer contactTotal) {
        registerAccountWithFax();
        registerContactWithEmail();

        ATKWizard.I().wantMany(Account.SObjectType)
            .useTemp(ACCOUNT_WITH_FAX)
            .total(accountTotal)
            .haveMany(Contact.SObjectType)
                .referenceBy(Contact.AccountId)
                .useTemp(CONTACT_WITH_EMAIL)
                .total(contactTotal)
            .generate();
    }
}
