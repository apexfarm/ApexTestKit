Savepoint sp = Database.setSavepoint();

ATK.SaveResult result = ATK.prepare(PriceBook2.SObjectType, [
        SELECT Id
        FROM PriceBook2
        WHERE IsStandard = true
    ])
    .field(PriceBook2.IsActive).repeat(true)
    .withChildren(PricebookEntry.SObjectType, PricebookEntry.Pricebook2Id, 200)
        .field(PricebookEntry.UnitPrice).repeat(100)
        .field(PricebookEntry.IsActive).repeat(true)
        .withParents(Product2.SObjectType, PricebookEntry.Product2Id, 200)
            .field(Product2.Name).index('Product Name-{0000}')
            .field(Product2.ProductCode).index('Product Code-{0000}')
    .save();

Database.rollback(sp);