# Apex Test Kit

![](https://img.shields.io/badge/version-3.5.2-brightgreen.svg) ![](https://img.shields.io/badge/build-passing-brightgreen.svg) ![](https://img.shields.io/badge/coverage-97%25-brightgreen.svg)

Apex Test Kit can help generate massive records for Apex test classes. It solves two pain points during record creation:

1. Establish arbitrary levels of many-to-one, one-to-many relationships.
2. Generate field values based on simple rules automatically.
2. Support mock sObjects generation that would be returned from any SOQL.

| Environment           | Installation Link                                            | Version   |
| --------------------- | ------------------------------------------------------------ | --------- |
| Production, Developer | <a target="_blank" href="https://login.salesforce.com/packaging/installPackage.apexp?p0=04t2v000007GTRTAA4"><img src="docs/images/deploy-button.png"></a> | ver 3.5.2 |
| Sandbox               | <a target="_blank" href="https://test.salesforce.com/packaging/installPackage.apexp?p0=04t2v000007GTRTAA4"><img src="docs/images/deploy-button.png"></a> | ver 3.5.2 |

------
### **v3.5 Release Notes**

#### Minor Changes
- Increase api versions to 53.0
- Increase number of accepted parameters of `repeat()` from 3 to 5.
- **v3.5.2 [RepeatX](#basic-field-keywords)**: Introduce new field keyword family `repeatX('A', 3, 'B', 2)`, thus repeat A three times and B two times.
- **v3.5.1 Fixes**: `Illegal assignment from Decimal to Integer`, when use arithmetic keywords against integer field types such as `Number(8, 0)`.

#### Major Changes (Non-breaking)
- [**Many to Many with Junction**](#many-to-many-with-junction): Introduce entity keyword `withJunction()`, it can be used as `withChildren()` to establish one-to-many relationship, but with a different distribution logic to distribute some parents of the junction object among the others.
  - **Pros**: Verified `withJunction()` in **Consumer Goods Cloud Demo** (`scripts/apex/demo-consumer.apex`), and it works well with the combination of other entity keywords to fulfill wider business scenarios. 
  - **Cons**: `withJunction()` will result in meaningless distribution logic if two parents share a common ancestor. In such case, please keep use `withChildren()`. Plan to bring a solution for this during next release, won't be soon and won't be long. **Caution**: `withJunction()` API or behavior is subject to change in minor chances.


* **v3.5.2 [Junction Order](#junction-order)**: Introduce keyword `order()` to alter the default relationship orders established by `withJunction()` keyword. It brings flexibility, so ATK sObject graph don't need to follow a rigid definition order to make `withJunction()` working as expected.
* Account, Contact, Case, User are the only sObjects used in test classes.

#### Next Release

- Bring solution for the `withJunction()` cons mentioned above.
- Bring a demo to generate nearly full graph of B2B Commerce Cloud to further verify the robustness and stability of `withJunction()` keyword.
------


## Table of Contents

- [Introduction](#introduction)
  - [Performance](#performance)
  - [Demos](#demos)
    - &#128293;Consumer Goods Cloud
- [Relationship](#relationship)
  - [One to Many](#one-to-many)
  - [Many to One](#many-to-one)
  - [Many to Many](#many-to-many)
  - [Many to Many with Junction](#many-to-many-with-junction)
  - [Junction Order](#junction-order)
- [&#128229;Save](#save)
  - [Command API](#command-api)
  - [Save Result API](#save-result-api)

- [&#9749;Mock](#-mock)
  - [Mock with Children](#mock-with-children)
  - [Mock with Predefined List](#mock-with-predefined-list)
  - [Fake Id](#fake-id)

- [Entity Keywords](#entity-keywords)
  - [Entity Creation Keywords](#entity-creation-keywords)
  - [Entity Updating Keywords](#entity-updating-keywords)
  - [Entity Reference Keywords](#entity-reference-keywords)
- [Field Keywords](#field-keywords)
  - [Basic Field Keywords](#basic-field-keywords)
  - [Arithmetic Field Keywords](#arithmetic-field-keywords)
  - [Lookup Field Keywords](#lookup-field-keywords)
- [Entity Builder Factory](#entity-builder-factory)
- [License](#license)

## Introduction

<p align="center">
<img src="docs/images/sales-objects.png#2020-5-31" width="400" alt="Sales Object Graph">
</p>

Imagine the complexity to generate all sObjects and relationships in the above diagram. With ATK we can create them within just one Apex statement. Here, we are generating:

1. *200* accounts with names: `Name-0001, Name-0002, Name-0003...`
2. Each of the accounts has *2* contacts.
3. Each of the contacts has *1* opportunity via the OpportunityContactRole.
4. Also each of the accounts has *2* orders.
5. Also each of the orders belongs to *1* opportunity from the same account.

```java
ATK.SaveResult result = ATK.prepare(Account.SObjectType, 200)
    .field(Account.Name).index('Name-{0000}')
    .withChildren(Contact.SObjectType, Contact.AccountId, 400)
        .field(Contact.LastName).index('Name-{0000}')
        .field(Contact.Email).index('test.user+{0000}@email.com')
        .field(Contact.MobilePhone).index('+86 186 7777 {0000}')
        .withChildren(OpportunityContactRole.SObjectType, OpportunityContactRole.ContactId, 400)
            .field(OpportunityContactRole.Role).repeat('Business User', 'Decision Maker')
            .withParents(Opportunity.SObjectType, OpportunityContactRole.OpportunityId, 400)
                .field(Opportunity.Name).index('Name-{0000}')
                .field(Opportunity.ForecastCategoryName).repeat('Pipeline')
                .field(Opportunity.Probability).repeat(0.9, 0.8)
                .field(Opportunity.StageName).repeat('Prospecting')
                .field(Opportunity.CloseDate).addDays(Date.newInstance(2020, 1, 1), 1)
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
    .save();
```

**Note**: `withChildren()` and `withParents()` without a third size parameter indicate they will back reference the sObjects created previously in the statement.

### Performance

The scripts used to perform benchmark testing are documented under `scripts/apex/benchmark.apex`. All tests will insert 1000 accounts under the following conditions:

1. No duplicate rules, process builders, and triggers etc.
2. ApexCode debug level is set to DEBUG.

| 1000 * Account | Database.insert | ATK Save | ATK Mock | ATK Mock Perf. |
| -------------- | --------------- | -------- | -------- | -------------- |
| CPU Time       | 0               | 0        | 487      | N/A            |
| Real Time (ms) | 6300            | 6631     | 656      | ~10x faster    |

### Demos

There are five demos under the `scripts/apex` folder, they can be successfully run in a clean Salesforce CRM organization. If not, please try to fix them with FLS, validation rules or duplicate rules etc.

| Subject        | File Path                         | Description                                                  |
| -------------- | --------------------------------- | ------------------------------------------------------------ |
| Campaign       | `scripts/apex/demo-campaign.apex` | How to genereate campaigns with hierarchy relationships. `ATK.EntityBuilder` is implemented to reuse the field population logic. |
| &#128293;Consumer Goods Cloud | `scripts/apex/demo-consumer.apex` | Create all the following sObjects in one ATK statement with meaningful relationship distributions: `Account`, `Contact`, `RetailLocationGroup`, `RetailStore`, `InstoreLocation`, `StoreProduct`, `Product2`, `PricebookEntry`, `Pricebook2`, `RetailStoreKpi`, `AssessmentIndicatorDefinition`, `AssessmentTaskDefinition`. |
| Sales          | `scripts/apex/demo-sales.apex`    | You've already seen it in the above paragraph.               |
| Products       | `scripts/apex/demo-products.apex` | How to generate Products for standard Price Book.            |
| Cases          | `scripts/apex/demo-cases.apex`    | How to generate Accounts, Contacts and Cases.                |
| Users          | `scripts/apex/demo-users.apex`    | How to generate community users in one goal.                 |

## Relationship

The object relationships described in a single ATK statement must be a Directed Acyclic Graph ([DAG](https://en.wikipedia.org/wiki/Directed_acyclic_graph)) , thus no cyclic relationships. If the validation is failed, an exception will be thrown.

### One to Many

```java
ATK.prepare(Account.SObjectType, 10)
    .field(Account.Name).index('Name-{0000}')
    .withChildren(Contact.SObjectType, Contact.AccountId, 20)
        .field(Contact.LastName).index('Name-{0000}')
    .save();
```

| Account Name | Contact Name |
| ------------ | ------------ |
| Name-0001    | Name-0001    |
| Name-0001    | Name-0002    |
| Name-0002    | Name-0003    |
| Name-0002    | Name-0004    |
| ...          | ...          |

### Many to One

The result of the following statement is identical to the one in the above one-to-many relationship.

```java
ATK.prepare(Contact.SObjectType, 20)
    .field(Contact.LastName).index('Name-{0000}')
    .withParents(Account.SObjectType, Contact.AccountId, 10)
        .field(Account.Name).index('Name-{0000}')
    .save();
```

### Many to Many

```java
ATK.prepare(Opportunity.SObjectType, 10)
    .field(Opportunity.Name).index('Opportunity {0000}')
    .withChildren(OpportunityContactRole.SObjectType, OpportunityContactRole.OpportunityId, 20)
        .field(OpportunityContactRole.Role).repeat('Business User', 'Decision Maker')
        .withParents(Contact.SObjectType, OpportunityContactRole.ContactId, 10)
            .field(Contact.LastName).index('Contact {0000}')
    .mock();
```

The result of above ATK statement will give the following distribution pattern, which seems not intuitive, if not intentional. But it makes scenes when the same contact play two different roles in the same opportunity.

| Opportunity Name | Contact Name | Contact Role   |
| ---------------- | ------------ | -------------- |
| Opportunity 0001 | Contact 0001 | Business User  |
| Opportunity 0001 | Contact 0001 | Decision Maker |
| Opportunity 0002 | Contact 0002 | Business User  |
| Opportunity 0002 | Contact 0002 | Decision Maker |
| ...              | ...          | ....           |

### Many to Many with Junction

`withJunction()` can be used as `withChildren()` to establish one-to-many relationship, but with a different logic to distribute parents of the junction object among the others.

```java
ATK.prepare(Opportunity.SObjectType, 10)
    .field(Opportunity.Name).index('Opportunity {0000}')
    .withJunction(OpportunityContactRole.SObjectType, OpportunityContactRole.OpportunityId, 20)
        .field(OpportunityContactRole.Role).repeat('Business User', 'Decision Maker')
        .withParents(Contact.SObjectType, OpportunityContactRole.ContactId, 10)
            .field(Contact.LastName).index('Contact {0000}')
    .mock();
```
| Opportunity Name | Contact Name | Contact Role   |
| ---------------- | ------------ | -------------- |
| Opportunity 0001 | Contact 0001 | Business User  |
| Opportunity 0001 | Contact 0002 | Decision Maker |
| Opportunity 0002 | Contact 0003 | Business User  |
| Opportunity 0002 | Contact 0004 | Decision Maker |
| ...              | ...          | ....           |
| Opportunity 0006 | Contact 0001 | Business User  |
| Opportunity 0006 | Contact 0002 | Decision Maker |
| Opportunity 0007 | Contact 0003 | Business User  |
| Opportunity 0007 | Contact 0004 | Decision Maker |
| ...              | ...          | ....           |

### Junction Order

**Note**: Different order of the junction relationships will result different distribution patterns. Here is an example if the above ATK statement define Contact first before Opportunity.

```java
ATK.prepare(Contact.SObjectType, 10)
    .field(Contact.LastName).index('Contact {0000}')
    .withJunction(OpportunityContactRole.SObjectType, OpportunityContactRole.ContactId, 20)
        // ! Uncomment the following line will give the same result as the above ATK statement
        // .order(OpportunityContactRole.OpportunityId, OpportunityContactRole.ContactId)
        .field(OpportunityContactRole.Role).repeat('Business User', 'Decision Maker')
        .withParents(Opportunity.SObjectType, OpportunityContactRole.OpportunityId, 10)
            .field(Opportunity.Name).index('Opportunity {0000}')
    .mock();
```

| Contact Name | Opportunity Name | Contact Role   |
| ------------ | ---------------- | -------------- |
| Contact 0001 | Opportunity 0001 | Business User  |
| Contact 0001 | Opportunity 0002 | Decision Maker |
| Contact 0002 | Opportunity 0003 | Business User  |
| Contact 0002 | Opportunity 0004 | Decision Maker |
| ...          | ...              | ....           |
| Contact 0006 | Opportunity 0001 | Business User  |
| Contact 0006 | Opportunity 0002 | Decision Maker |
| Contact 0007 | Opportunity 0003 | Business User  |
| Contact 0007 | Opportunity 0004 | Decision Maker |
| ...          | ...              | ....           |

Here we have `order()` keyword to alter the default relationship orders for the junction sObject. It brings flexibility, so ATK sObject graph don't need to follow a rigid definition order to make `withJunction()` working as expected. **Note**: 

- `order()` must be used directly after `withJunction()` keyword.
- All parent relationships used by the junction sObject must be listed in the `order()` keyword.

| Keyword API                                                   |
| ------------------------------------------------------------ |
| order(SObjectField *parentId1*, SObjectField *parentId2*);   |
| order(SObjectField *parentId1*, SObjectField *parentId2*, SObjectField *parentId3*); |
| order(SObjectField *parentId1*, SObjectField *parentId2*, SObjectField *parentId3*, SObjectField *parentId4*); |
| order(SObjectField *parentId1*, SObjectField *parentId2*, SObjectField *parentId3*, SObjectField *parentId4*, SObjectField *parentId5*); |
| order(List\<SObjectField\> *parentIds*);                     |

## &#128229;Save

### Command API

There are three commands to create the sObjects, in database, in memory, or in mock.

| Method API                              | Description                                                  |
| --------------------------------------- | ------------------------------------------------------------ |
| ATK.SaveResult save()                   | Actual DMLs will be performed to insert/update sObjects into Salesforce. |
| ATK.SaveResult save(Boolean *doInsert*) | If `doInsert` is `false`, no actual DMLs will be performed, just in-memory generated SObjects will be returned. Only writable fields can be populated. |
| ATK.SaveResult mock()                   | &#9749;No actual DMLs will be performed, but sObjects will be returned in SaveResult as if they are newly retrieved by SOQL with fake Ids. Both writable and read-only fields can be populated |

### Save Result API

Use `ATK.SaveResult` to retrieve sObjects generated from the ATK statement.

| Method                                                      | Description                                                  |
| ----------------------------------------------------------- | ------------------------------------------------------------ |
| List<SObject> get(SObjectType *objectType*)                 | Get the sObjects generated from the first `SObjectType` defined in ATK statement. |
| List<SObject> get(SObjectType *objectType*, Integer *nth*); | Get the sObjects generated from the nth `SObjectType` defined in ATK statement, such as in the Account Hierarchy. |
| List<SObject> getAll(SObjectType *objectType*)              | Get all sObjects generated from `SObjectType` defined in ATK statement. |

## &#9749; Mock

The followings are suppored, when generate sObjects with `mock()` API:

1. Assign extremely large fake IDs to the generated sObjects
2. Assign values to read-only fields, such as *formula fields*, *rollup summary fields*, and *system fields*.
3. Assign one level children relationship and multiple level parent relationships.

### Mock with Children

<p>
  <img src="docs/images/mock-relationship.png#2021-3-9" align="right" width="250" alt="Mock Relationship">
  To establish a relationship graph as the picture on the right, we can start from any node. <b>However only the sObjects created in the prepare statement can have child relationships referencing their direct children.</b><br><br>
  <b>Note</b>: As the diagram illustrated the direct children D and E of B can no longer reference back to B. The decision is made to prevent a <a href="https://trailblazer.salesforce.com/issues_view?id=a1p3A000001Gv4KQAS">Known Salesforce Issue</a> reported since winter 19. Here we are trying to avoid forming circular references. But D and E can still have parent relationship referencing other sObject during mock, such as D to C. <br><br>
  All the nodes in green are reachable from node B. The diagram can be interpreted as the following SOQL statement:
</p>


```SQL
SELECT Id, A__r.Id, (SELECT Id FROM E__r), (SELECT Id, C__r.Id FROM D__r)
FROM B__c
```

And we can generate them with the following ATK statement:

```java
ATK.SaveResult result = ATK.prepare(B__c.SObjectType, 10)
    .withParents(A__c.SObjectType, B__c.A_ID__c, 10)
    .also()
    .withChildren(D__c.SObjectType, D__c.B_ID__c, 10)
        .withParents(C__c.SObjectType, D__c.C_ID__c, 10)
        .also()
        .withChildren(F__c.SObjectType, F__c.D_ID__c, 10)
    .also(2)
    .withChildren(E__c.SObjectType, E__c.B_ID__c, 10)
    .mock();

List<B__c> listOfB = (List<B__c>)result.get(B__c.SObjectType);
for (B__c itemB : listOfB) {
    System.assertEquals(1, itemB.D__r.size());
    System.assertEquals(1, itemB.E__r.size());
}
```

### Mock with Predefined List

Mock also supports predefined list or SOQL query results. But if there are any parent or child relationships in the predefined list, they are going to be trimmed in the generated mock sObjects.

```java
List<B__c> listOfB = [SELECT X__r.Id, (SELECT Id FROM Y__r) FROM B__c LIMIT 3];

ATK.SaveResult result = ATK.prepare(B__c.SObjectType, listOfB)
    .withParents(A__c.SObjectType, B__c.A_ID__c, 1)
    .also()
    .withChildren(D__c.SObjectType, D__c.B_ID__c, 6)
    .mock()

List<B__c> mockOfB = (List<B__c>)result.get(B__c.SObjectType);
// The B__c in mockOfB cannot reference X__r and Y__r any more.
// The B__c in listOfB can still reference X__r and Y__r.
```

### Fake Id

These methods are exposed in case we need manually control the ID assignments such as:

```java
Id fakeUserId = ATK.fakeId(User.SObjectType, 1);
ATK.SaveResult result = ATK.prepare(Account.SObjectType, 9)
    .field(Account.OwnerId).repeat(fakeUserId)
    .mock()
```

| Keyword API                                                 | Description                                                  |
| ----------------------------------------------------------- | ------------------------------------------------------------ |
| Id fakeId(Schema.SObjectType *objectType*)                  | Return self incrementing fake IDs. They will start over from each transaction, which means they are unique within each transaction. By default Ids will start from `ATK.fakeId(Account.SObjectType, 1)`. |
| Id fakeId(Schema.SObjectType *objectType*, Integer *index*) | Return the fake ID specified an index explicitly.            |

## Entity Keywords

These keywords are used to establish arbitrary levels of many-to-one, one-to-many relationships. Here is a dummy example to demo the use of Entity keywords. Each of them will start a new sObject context. And it is advised to use the following indentation for clarity.

```java
ATK.prepare(A__c.SObjectType, 10)
    .withChildren(B__c.SObjectType, B__c.A_ID__c, 10)
        .withParents(C__c.SObjectType, B__c.C_ID__c, 10)
            .withChildren(D__c.SObjectType, D__c.C_ID__c, 10)
            .also() // Go back 1 depth to C__c
            .withChildren(E__c.SObjectType, E__c.C_ID__c, 10)
        .also(2)    // Go back 2 depth to B__c
        .withChildren(F__c.SObjectType, F__c.B_ID__c, 10)
    .save();
```

### Entity Creation Keywords

All the following APIs have an `Integer size` parameter at the end, which indicate how many instances of the sObject type will be created on the fly.

```java
ATK.prepare(A__c.SObjectType, 10)
    .withChildren(B__c.SObjectType, B__c.A_ID__c, 10)
        .withParents(C__c.SObjectType, B__c.C_ID__c, 10)
    .save();
```

| Keyword API                                                  | Description                                                  |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| prepare(SObjectType *objectType*, Integer *size*)            | Always start chain with `prepare()` keyword. It is the root sObject to start relationship with. |
| withParents(SObjectType *objectType*, SObjectField *referenceField*, Integer *size*) | Establish many to one relationship between the previous working on sObject and the current sObject. |
| withChildren(SObjectType *objectType*, SObjectField *referenceField*, Integer *size*) | Establish one to many relationship between the previous working on sObject and the current sObject. |
| withJunction(SObjectType *objectType*, SObjectField *referenceField*, Integer *size*) | Establish one to many relationship between the previous working on sObject and the current sObject. |

### Entity Updating Keywords

All the following APIs have a `List<SObject> objects` parameter at the end, which indicate the sObjects are selected/created elsewhere, and ATK will upsert them.

```java
ATK.prepare(A__c.SObjectType, [SELECT Id FROM A__c]) // Select existing sObjects
    .field(A__c.Name).index('Name-{0000}')           // Update existing sObjects
    .field(A__c.Price).repeat(100)
    .withChildren(B__c.SObjectType, B__c.A_ID__c, new List<SObject> {
        new B__c(Name = 'Name-A'),                   // Manually assign field values
        new B__c(Name = 'Name-B'),
        new B__c(Name = 'Name-C')})
        .field(B__c.Counter__c).add(1, 1)            // Automatically assign field values
        .field(B__c.Weekday__c).repeat('Mon', 'Tue') // Automatically assign field values
        .withParents(C__c.SObjectType, B__c.C_ID__c, new List<SObject> {
            new C__c(Name = 'Name-A'),
            new C__c(Name = 'Name-B'),
            new C__c(Name = 'Name-C')})
    .save();
```

| Keyword API                                                  | Description                                                  |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| prepare(SObjectType *objectType*, List\<SObject\> *objects*) | Always start chain with `prepare()` keyword. It is the root sObject to start relationship with. |
| withParents(SObjectType *objectType*, SObjectField *referenceField*, List\<SObject\> *objects*) | Establish many to one relationship between the previous working on sObject and the current sObject. |
| withChildren(SObjectType *objectType*, SObjectField *referenceField*, List\<SObject\> *objects*) | Establish one to many relationship between the previous working on sObject and the current sObject. |
| withJunction(SObjectType *objectType*, SObjectField *referenceField*, List\<SObject\> *objects*) | Establish one to many relationship between the previous working on sObject and the current sObject. |

### Entity Reference Keywords

All the following APIs don't have a third parameter of size or list at the end, which means the relationship will look back to reference the previously created sObjects.

| Keyword API                                                  | Description                                                  |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| withParents(SObjectType *objectType*, SObjectField *referenceField*) | Establish many to one relationship between the previous working on sObject and the current sObject. |
| withChildren(SObjectType *objectType*, SObjectField *referenceField*) | Establish one to many relationship between the previous working on sObject and the current sObject. |


**Note**: Once these APIs are used, please make sure there are sObjects with the same type created previously, and only created once.

## Field Keywords

These keywords are used to generate field values based on simple rules automatically.

```java
ATK.prepare(A__c.SObjectType, 10)
    .withChildren(B__c.SObjectType, B__c.A_ID__c, 10)
        .field(B__C.Name__c).index('Name-{0000}')
        .field(B__C.PhoneNumber__c).index('+86 186 7777 {0000}')
        .field(B__C.Price__c).repeat(12.34)
        .field(B__C.CampanyName__c).repeat('Google', 'Apple', 'Microsoft')
        .field(B__C.Counter__c).add(1, 1)
        .field(B__C.StartDate__c).addDays(Date.newInstance(2020, 1, 1), 1)
    .save();
```

### Basic Field Keywords
| Keyword API                                                  | Description                                                  |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| index(String *format*)                                       | Formatted string with `{0000}`, can recognize left padding. i.e. `Name-{0000}` will generate Name-0001, Name-0002, Name-0003 etc. |
| **Repeat Family**                                            |                                                              |
| repeat(Object *value*)                                       | Repeat with a single fixed value.                            |
| repeat(Object *value1*, Object *value2*)                     | Repeat with the provided values alternatively.               |
| repeat(Object *value1*, Object *value2*, Object *value3*)    | Repeat with the provided values alternatively.               |
| repeat(Object *value1*, Object *value2*, Object *value3*, Object *value4*) | Repeat with the provided values alternatively.               |
| repeat(Object *value1*, Object *value2*, Object *value3*, Object *value4*, Object *value5*) | Repeat with the provided values alternatively.               |
| repeat(List\<Object\> *values*)                              | Repeat with the provided values alternatively.**             |
| **RepeatX Family**                                           |                                                              |
| repeatX(Object *value1*, Integer *size1*, Object *value2*, Integer *size2*) | repeat each value by x times in sequence.                    |
| repeatX(Object *value1*, Integer *size1*, Object *value2*, Integer *size2*, Object *value3*, Integer *size3*) | repeat each value by x times in sequence.                    |
| repeatX(Object *value1*, Integer *size1*, Object *value2*, Integer *size2*, Object *value3*, Integer *size3*, Object *value4*, Integer *size4*) | repeat each value by x times in sequence.                    |
| repeatX(Object *value1*, Integer *size1*, Object *value2*, Integer *size2*, Object *value3*, Integer *size3*, Object *value4*, Integer *size4*, Object *value5*, Integer *size5*) | repeat each value by x times in sequence.                    |
| repeatX(List\<Object\> *values*, List\<Integer\> *sizes*)      | repeat each value by x times in sequence.                    |

### Arithmetic Field Keywords

These keywords will increase/decrease the `init` values by the provided steps.

#### Number Arithmetic

| Keyword API                                | Description                                    |
| ------------------------------------------ | ---------------------------------------------- |
| add(Decimal *init*, Decimal *step*)        | Must be applied to a number type field.        |
| substract(Decimal *init*, Decimal *step*)  | Must be applied to a number type field.        |
| divide(Decimal *init*, Decimal *factor*)   | Must be applied to a number type field.        |
| multiply(Decimal *init*, Decimal *factor*) | Must be applied to a number type field.        |

#### Date/Time Arithmetic

| Keyword API                                | Description                                    |
| ------------------------------------------ | ---------------------------------------------- |
| addYears(Object *init*, Integer *step*)    | Must be applied to a Datetime/Date type field. |
| addMonths(Object *init*, Integer *step*)   | Must be applied to a Datetime/Date type field. |
| addDays(Object *init*, Integer *step*)     | Must be applied to a Datetime/Date type field. |
| addHours(Object *init*, Integer *step*)    | Must be applied to a Datetime/Time type field. |
| addMinutes(Object *init*, Integer *step*)  | Must be applied to a Datetime/Time type field. |
| addSeconds(Object *init*, Integer *step*)  | Must be applied to a Datetime/Time type field. |

### Lookup Field Keywords

These are field keywords in nature, but without the need to be chained after `.field(Schema.SObjectField)`. ATK will help to look up the IDs and assign them to the correct fields automatically.

```java
ATK.prepare(User.SObjectType, 10)
    .profile('Chatter Free User')      // must be applied to User SObject
    .permissionSet('Survey_Creator');  // must be applied to User SObject

ATK.prepare(Account.SObjectType, 10)
    .recordType('Business_Account');
```

| Keyword API                                                  | Description                                                  |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| recordType(String *name*)                                    | Assign record type ID by developer name, the name is case sensitive due the `getRecordTypeInfosByDeveloperName()` API. |
| profile(String *name*)                                       | Assign profile ID by profile name.                           |
| permissionSet(String *name*)                                 | Assign the permission set to users by developer name.        |
| permissionSet(String name1, String *name2*)                  | Assign all the permission sets to users by developer names.  |
| permissionSet(String *name1*, String *name2*, String *name3*) | Assign all the permission sets to users by developer names.  |
| permissionSet(List\<String\> *names*)                        | Assign all the permission sets to users by developer names.  |

## Entity Builder Factory

In order to increase the reusability of ATK, we can abstract the field keywords into an Entity Builder.

```java
@IsTest
public with sharing class CampaignServiceTest {
    @TestSetup
    static void setup() {
        ATK.SaveResult result = ATK.prepare(Campaign.SObjectType, 4)
            .build(EntityBuilderFactory.campaignBuilder)     // Reference to Entity Builder
            .withChildren(CampaignMember.SObjectType, CampaignMember.CampaignId, 8)
                .withParents(Lead.SObjectType, CampaignMember.LeadId, 8)
                    .build(EntityBuilderFactory.leadBuilder) // Reference to Entity Builder
            .save();
    }
}
```

```java
@IsTest
public with sharing class EntityBuilderFactory {
    public static CampaignEntityBuilder campaignBuilder = new CampaignEntityBuilder();
    public static LeadEntityBuilder leadBuilder = new LeadEntityBuilder();

    // Inner class implements ATK.EntityBuilder
    public class CampaignEntityBuilder implements ATK.EntityBuilder {
        public void build(ATK.Entity campaignEntity, Integer size) {
            campaignEntity
                .field(Campaign.Type).repeat('Partners')
                .field(Campaign.Name).index('Name-{0000}')
                .field(Campaign.StartDate).repeat(Date.newInstance(2020, 1, 1))
                .field(Campaign.EndDate).repeat(Date.newInstance(2020, 1, 1));
        }
    }

    // Inner class implements ATK.EntityBuilder
    public class LeadEntityBuilder implements ATK.EntityBuilder {
        public void build(ATK.Entity leadEntity, Integer size) {
            leadEntity
                .field(Lead.Company).index('Name-{0000}')
                .field(Lead.LastName).index('Name-{0000}')
                .field(Lead.Email).index('test.user+{0000}@email.com')
                .field(Lead.MobilePhone).index('+86 186 7777 {0000}');
        }
    }
}
```

## License

Apache 2.0
