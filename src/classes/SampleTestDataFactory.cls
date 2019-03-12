@isTest
public with sharing class SampleTestDataFactory {
    public static ATKCommand.ResultMap createAccountWithContact(Integer accountTotal, Integer contactTotal) {
        return ATKCommand.prepare(Account.SObjectType)
            .useTemp(SampleTestTempFactory.class, SampleTestTempFactory.ACCOUNT_WITH_FAX)
            .total(accountTotal)
            .fields()
                .eval(Account.Fax).fake('{{555-###-####}}') // override field declared in template
            .end()
            .haveMany(Contact.SObjectType)
                .useTemp(SampleTestTempFactory.class, SampleTestTempFactory.CONTACT_WITH_EMAIL)
                .total(contactTotal)
            .generate();
    }
}
