/**
 * 1. Install https://github.com/apexfarm/ApexTestKit
 *
 * 2. Targeted Relationships:
 *    Account(2) <= Retail Store(4) <= In-store Location(8) <= Store Product(16) => Product2(4)
 * 
 * 2. Expected Distributions:
 *    |---------------------------------------------------|---------------------------------------------------|
 *    |                     Account 1                     |                     Account 2                     |
 *    |                       Contact 1                   |                       Contact 3                   |
 *    |                       Contact 2                   |                       Contact 4                   |
 *    |-------------------------|-------------------------|-------------------------|-------------------------|
 *    | Store Group 1           | Store Group 1           | Store Group 2           | Store Group 2           |
 *    |   Retail Store 1        |   Retail Store 2        |   Retail Store 3        |   Retail Store 4        |
 *    |     In-store Location 1 |     In-store Location 3 |     In-store Location 5 |     In-store Location 7 |
 *    |       Product 1         |       Product 1         |       Product 1         |       Product 1         |
 *    |       Product 2         |       Product 2         |       Product 2         |       Product 2         |
 *    |     In-store Location 2 |     In-store Location 4 |     In-store Location 6 |     In-store Location 8 |
 *    |       Product 3         |       Product 3         |       Product 3         |       Product 3         |
 *    |       Product 4         |       Product 4         |       Product 4         |       Product 4         |
 *    |-------------------------|-------------------------|-------------------------|-------------------------|
 */

Savepoint sp = Database.setSavepoint();
Datetime startTime = Datetime.now();

List<PriceBook2> priceBooks = new List<PriceBook2>{ 
    [SELECT Id, Name FROM PriceBook2 WHERE IsStandard = TRUE][0], 
    new PriceBook2(Name = 'Local Price Book', IsActive = true) 
};

ATK.SaveResult result = ATK.prepare(Account.SObjectType, 2)
    .field(Account.Name).index('Account {000}')
    .withChildren(Contact.SObjectType, Contact.AccountId, 4)
        .field(Contact.LastName).index('Contact {000}')
    .also()
    // =============Retail Stores=============
    .withChildren(RetailStore.SObjectType, RetailStore.AccountId, 4)
        .field(RetailStore.Name).index('Retail Store {000}')
        .withChildren(InstoreLocation.SObjectType, InstoreLocation.RetailStoreId, 8)
            .field(InstoreLocation.Name).index('In-store Location {000}')
            .field(InstoreLocation.InStoreLocationType).repeat('Shelf', 'Backroom')
            .field(InstoreLocation.Category).repeat('Aisle', 'Backroom Storage')
            .withChildren(StoreProduct.SObjectType, StoreProduct.InstoreLocationId, 16)
                .junctionOf(StoreProduct.InstoreLocationId, StoreProduct.ProductId)
                .field(StoreProduct.StartDate).repeat(Date.newInstance(2020, 1, 1))
                .field(StoreProduct.DefaultOrderQuantity).repeat(50)
                .field(StoreProduct.IsFavorite).repeat(true, false)
                .field(StoreProduct.DisplayOrder).repeat(1, 2)
                // =============Products=============
                .withParents(Product2.SObjectType, StoreProduct.ProductId, 4)
                    .field(Product2.Name).index('Product {000}')
                    .field(Product2.IsActive).repeat(true)
                    .withChildren(PricebookEntry.SObjectType, PricebookEntry.Product2Id, 8)
                        .junctionOf(PricebookEntry.Product2Id, PricebookEntry.Pricebook2Id)
                        .field(PricebookEntry.IsActive).repeat(true)
                        .field(PricebookEntry.UnitPrice).repeat(9.99)
                        .withParents(Pricebook2.SObjectType, PricebookEntry.Pricebook2Id, priceBooks)
        .also(5)
        .withParents(RetailLocationGroup.SObjectType, RetailStore.RetailLocationGroupId, 2)
            .field(RetailLocationGroup.Name).index('Store Group {000}')
            // =============Store KPIs=============
            // 2 Groups * 2 Indicators * 4 Products
            .withChildren(RetailStoreKpi.SObjectType, RetailStoreKpi.RetailStoreGroupId, 16)
                .junctionOf(RetailStoreKpi.RetailStoreGroupId, RetailStoreKpi.AssessmentIndDefinitionId, RetailStoreKpi.ProductId)
                .field(RetailStoreKpi.InStoreLocationCategory).repeatX('Aisle', 4, 'Backroom Storage', 4)
                .field(RetailStoreKpi.KpiType).repeat('Inventory')
                .field(RetailStoreKpi.StartDate).repeat(Date.newInstance(2020, 1, 1))
                .field(RetailStoreKpi.TargetIntegerValue).repeat(10, null)
                .field(RetailStoreKpi.TargetDecimalValue).repeat(null, 9.9)
                .withParents(AssessmentIndicatorDefinition.SObjectType, RetailStoreKpi.AssessmentIndDefinitionId, 2)
                    .field(AssessmentIndicatorDefinition.Name).repeat('Inventory Check | Inventory Count', 'Inventory Check | Display Price')
                    .field(AssessmentIndicatorDefinition.DataType).repeat('Number', 'Decimal')
                    .withChildren(AssessmentTaskIndDefinition.SObjectType, AssessmentTaskIndDefinition.AssessmentIndDefinitionId, 2)
                        .junctionOf(AssessmentTaskIndDefinition.AssessmentIndDefinitionId, AssessmentTaskIndDefinition.AssessmentTaskDefinitionId)
                        .withParents(AssessmentTaskDefinition.SObjectType, AssessmentTaskIndDefinition.AssessmentTaskDefinitionId, 1)
                            .field(AssessmentTaskDefinition.Name).repeat('Inventory Check')
                            .field(AssessmentTaskDefinition.TaskType).repeat('InventoryCheck')
                .also(3)
                .withParents(Product2.SObjectType, RetailStoreKpi.ProductId)
    .mock();

List<RetailStoreKpi> kpis = result.get(RetailStoreKpi.SobjectType);
for (RetailStoreKpi kpi : kpis) {
    System.debug(kpi);
}

Datetime endTime = Datetime.now();
System.debug(endTime.getTime() - startTime.getTime());
Database.rollback(sp);