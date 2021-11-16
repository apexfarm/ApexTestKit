// 1. Enable FLS of OpportunityId of Order

Savepoint sp = Database.setSavepoint();

ATK.SaveResult result = ATK.prepare(Account.SObjectType, 200)
    .field(Account.Name).index('Name-{0000}')
    .withChildren(Contact.SObjectType, Contact.AccountId, 400)
        .field(Contact.LastName).index('Name-{0000}')
        .field(Contact.Email).index('test.user+{0000}@email.com')
        .field(Contact.MobilePhone).index('+86 186 7777 {0000}')
        .withChildren(OpportunityContactRole.SObjectType, OpportunityContactRole.ContactId, 800)
            .field(OpportunityContactRole.Role).repeat('Business User', 'Decision Maker')
            .withParents(Opportunity.SObjectType, OpportunityContactRole.OpportunityId, 400)
                .field(Opportunity.Name).index('Name-{0000}')
                .field(Opportunity.CloseDate).addDays(Date.newInstance(2020, 1, 1), 1)
                .field(Opportunity.ForecastCategoryName).repeat('Pipeline')
                .field(Opportunity.Probability).repeat(0.9, 0.8, 0.7)
                .field(Opportunity.StageName).repeat('Prospecting')
                .field(Opportunity.TotalOpportunityQuantity).add(1000, 10)
                .withParents(Account.SObjectType, Opportunity.AccountId)
    .also(4)
    .withChildren(Order.SObjectType, Order.AccountId, 400)
        .field(Order.Name).index('Name-{0000}')
        .field(Order.EffectiveDate).addDays(Date.newInstance(2020, 1, 1), 1)
        .field(Order.Status).repeat('Draft')
        .withParents(Contact.SObjectType, Order.BillToContactId)
        .also()
        .withParents(Opportunity.SObjectType, Order.OpportunityId)
    .save(true);

System.assertEquals(200, result.get(Account.SObjectType).size());
System.assertEquals(400, result.get(Contact.SObjectType).size());
System.assertEquals(800, result.get(OpportunityContactRole.SObjectType).size());
System.assertEquals(400, result.get(Opportunity.SObjectType).size());
System.assertEquals(400, result.get(Order.SObjectType).size());

for (Integer i = 0; i < 200; i++) {
    Account acc = (Account)result.get(Account.SObjectType)[i];
    Contact contact1 = (Contact)result.get(Contact.SObjectType)[i * 2];
    Contact contact2 = (Contact)result.get(Contact.SObjectType)[i * 2 + 1];
    Order order1 = (Order)result.get(Order.SObjectType)[i * 2];
    Order order2 = (Order)result.get(Order.SObjectType)[i * 2 + 1];
    Opportunity opp1 = (Opportunity)result.get(Opportunity.SObjectType)[i * 2];
    Opportunity opp2 = (Opportunity)result.get(Opportunity.SObjectType)[i * 2 + 1];
    OpportunityContactRole opc1 = (OpportunityContactRole)result.get(OpportunityContactRole.SObjectType)[i * 4];
    OpportunityContactRole opc2 = (OpportunityContactRole)result.get(OpportunityContactRole.SObjectType)[i * 4 + 1];
    OpportunityContactRole opc3 = (OpportunityContactRole)result.get(OpportunityContactRole.SObjectType)[i * 4 + 2];
    OpportunityContactRole opc4 = (OpportunityContactRole)result.get(OpportunityContactRole.SObjectType)[i * 4 + 3];

    System.assertEquals(acc, contact1.Account);
    System.assertEquals(acc, contact2.Account);
    System.assertEquals(acc, opp1.Account);
    System.assertEquals(acc, opp2.Account);

    System.assertEquals(acc, order1.Account);
    System.assertEquals(acc, order2.Account);
    System.assertEquals(contact1, order1.BillToContact);
    System.assertEquals(contact2, order2.BillToContact);
    System.assertEquals(opp1, order1.Opportunity);
    System.assertEquals(opp2, order2.Opportunity);
    
    System.assertEquals(opp1, opc1.Opportunity);
    System.assertEquals(opp1, opc2.Opportunity);
    System.assertEquals(opp2, opc3.Opportunity);
    System.assertEquals(opp2, opc4.Opportunity);
    System.assertEquals(contact1, opc1.Contact);
    System.assertEquals(contact1, opc2.Contact);
    System.assertEquals(contact2, opc3.Contact);
    System.assertEquals(contact2, opc4.Contact);
}

Database.rollback(sp);