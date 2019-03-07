@isTest
public with sharing class SampleTestDataFactory {
    public static final String ACCOUNT_WITH_FAX = 'SampleTestDataFactory/ACCOUNT_WITH_FAX';
    public static final String CONTACT_WITH_EMAIL = 'SampleTestDataFactory/CONTACT_WITH_EMAIL';

    public static String registerAccountWithFax() {
        ATKWizard.I().wantTemp(Account.SObjectType, ACCOUNT_WITH_FAX)
            .fields()
                .guard()
                .useEval(Account.Fax, '{{1##-###-####}}')
                .useEval(Account.NumberOfEmployees, '{!random.number(8, 0)}')
                .useEval(Account.Industry)
                .useEval(Account.Industry)
            .end()
            .register();
        return ACCOUNT_WITH_FAX;
    }

    public static String registerContactWithEmail() {
        ATKWizard.I().wantTemp(Contact.SObjectType, CONTACT_WITH_EMAIL)
            .fields()
                .guard()
                .useEval(Contact.FirstName, '{!name.firstName(female)}')
                .useEval(Contact.LastName, '{!name.lastName}')
                .useEval(Contact.Birthdate, '{!dates.past}')
                .useEval(Contact.Email, '{!internet.email}')
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
