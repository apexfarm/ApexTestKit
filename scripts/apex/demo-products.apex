Savepoint sp = Database.setSavepoint();
Datetime startTime = Datetime.now();

ATK.SaveResult result = ATK.prepare(PriceBook2.SObjectType, new List<PriceBook2>{ 
        [SELECT Id, Name FROM PriceBook2 WHERE IsStandard = TRUE][0], 
        new PriceBook2(Name = 'Local Price Book', IsActive = true) 
    })
    .withJunction(PricebookEntry.SObjectType, PricebookEntry.Pricebook2Id, 400)
        .field(PricebookEntry.IsActive).repeat(true)
        .field(PricebookEntry.UnitPrice).repeat(9.99)
        .withParents(Product2.SObjectType, PricebookEntry.Product2Id, 200)
            .field(Product2.IsActive).repeat(true)
            .field(Product2.Name).index('Product {0000}')
    .save();

Datetime endTime = Datetime.now();
System.debug(endTime.getTime() - startTime.getTime());
Database.rollback(sp);