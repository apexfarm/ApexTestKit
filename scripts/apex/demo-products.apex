Savepoint sp = Database.setSavepoint();
Datetime startTime = Datetime.now();

ATK.SaveResult result = ATK.prepare(PriceBook2.SObjectType, new List<PriceBook2>{ 
        [SELECT Id, Name FROM PriceBook2 WHERE IsStandard = TRUE][0], 
        new PriceBook2(Name = 'Promotion Price Book', IsActive = true),
        new PriceBook2(Name = 'Partner Price Book', IsActive = true) 
    })
    .withChildren(PricebookEntry.SObjectType, PricebookEntry.Pricebook2Id, 60)
        .junctionOf(PricebookEntry.Pricebook2Id, PricebookEntry.Product2Id)
        .field(PricebookEntry.IsActive).repeat(true)
        .field(PricebookEntry.UnitPrice).repeat(9.99)
        .withParents(Product2.SObjectType, PricebookEntry.Product2Id, 20)
            .field(Product2.IsActive).repeat(true)
            .field(Product2.Name).index('Product {0}')
    .save();

Datetime endTime = Datetime.now();
System.debug(endTime.getTime() - startTime.getTime());
Database.rollback(sp);