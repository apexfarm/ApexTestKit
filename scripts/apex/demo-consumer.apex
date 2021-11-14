/*
1. Object relationship and number of records
    Account(2) 
        <= Retail Store(2) 
            <= In-store Location(4) 
                <= Store Product(8) 
                    => Product2(4)

2. Expected Record Distribution:
    |-----------------------------|-----------------------------|
    | Account 1                   | Account 2                   |
    |     Retail Store 1          |     Retail Store 2          |
    |         In-store Location 1 |         In-store Location 3 |
    |             Store Product 1 |             Store Product 5 |
    |                 Product 1   |                 Product 1   |
    |                 Product 2   |                 Product 2   |
    |             Store Product 2 |             Store Product 6 |
    |                 Product 3   |                 Product 3   |
    |                 Product 4   |                 Product 4   |
    |         In-store Location 2 |         In-store Location 4 |
    |             Store Product 3 |             Store Product 7 |
    |                 Product 1   |                 Product 1   |
    |                 Product 2   |                 Product 2   |
    |             Store Product 4 |             Store Product 8 |
    |                 Product 3   |                 Product 3   |
    |                 Product 4   |                 Product 4   |
    |-----------------------------|---------------------------- |
*/

PriceBook2 standardPricebook = [SELECT Id, Name FROM PriceBook2 WHERE IsStandard = TRUE];

List<PriceBook2> priceBooks = new List<PriceBook2>{ standardPricebook, new PriceBook2(Name = 'Promotion Price Book') };

ATK.SaveResult result = ATK.prepare(Account.SObjectType, 2)
    .field(Account.Name)
    .index('Account Name {0}')
    .withChildren(RetailStore.SObjectType, RetailStore.AccountId, 2)
        .field(RetailStore.Name)
        .index('Store Name {0}')
        .withChildren(InstoreLocation.SObjectType, InstoreLocation.RetailStoreId, 4)
        // .field(InstoreLocation.InStoreLocationType).repeat('Shelf', 'Backroom')
        // .field(InstoreLocation.Category).repeat('Aisle', 'Backroom Storage')
            .withJunction(StoreProduct.SObjectType, StoreProduct.InstoreLocationId, 8)
            // .field(StoreProduct.StartDate).repeat(Date.newInstance(2020, 1, 1))
            .withParents(Product2.SObjectType, StoreProduct.ProductId, 2)
                .withJunction(PricebookEntry.SObjectType, PricebookEntry.Product2Id, 4)
                    .withParents(Pricebook2.SObjectType, PricebookEntry.Pricebook2Id, priceBooks)
    .mock();
