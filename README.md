# Apex Test Kit

![](https://img.shields.io/badge/version-4.0.1-brightgreen.svg) ![](https://img.shields.io/badge/build-passing-brightgreen.svg) ![](https://img.shields.io/badge/coverage-95%25-brightgreen.svg)

Apex Test Kit can help generate massive data for Apex test classes, including mock sObjects with read-only fields. It solves two pain points during data creation:

1. Establish arbitrary levels of many-to-one, one-to-many relationships.
2. Generate field values based on simple rules automatically.

It can also help generate method stubs with the help of Apex `StubProvider` interface underneath. Thanks to both [Mockito](https://github.com/mockito/mockito) and [fflib-apex-mocks](https://github.com/apex-enterprise-patterns/fflib-apex-mocks) libraries.

1. Stubs are defined and verified with BDD given-when-then styles.
2. [Strict mode](https://github.com/apexfarm/ApexTestKit/wiki/Apex-Test-Kit-with-BDD#1-1-strict-mode) is enforced by default to help developers write clean mocking codes and increase productivity.

| Environment           | Installation Link                                                                                                                                         | Version   |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- |
| Production, Developer | <a target="_blank" href="https://login.salesforce.com/packaging/installPackage.apexp?p0=04t2v000007GULbAAO"><img src="docs/images/deploy-button.png"></a> | ver 4.0.1 |
| Sandbox               | <a target="_blank" href="https://test.salesforce.com/packaging/installPackage.apexp?p0=04t2v000007GULbAAO"><img src="docs/images/deploy-button.png"></a>  | ver 4.0.1 |

---

### **v4.0 Release Notes**

#### Major Changes

-   Ported Mockito BDD Features

#### Next Steps

-   Performance tuning for the BDD features.
-   Enhance the BDD features.
-   Support `HttpCalloutMock` in BDD style.

---

## &#128293; Apex Test Kit with BDD

Please check the developer guide at this [wiki page](https://github.com/apexfarm/ApexTestKit/wiki/Apex-Test-Kit-with-BDD).

```java
YourClass mock = (YourClass) ATK.mock(YourClass.class);
// Given
ATK.startStubbing();
ATK.given(mock.doSomething()).willReturn('Sth.');
ATK.stopStubbing();

// When
String returnValue = mock.doSomething();

// Then
System.assertEquals('Sth.', returnValue);
((ATKMockTest) ATK.then(mock).should().once()).doSomething();
```

## Table of Contents

-   [Introduction](#introduction)
    -   [Performance](#performance)
    -   [Demos](#demos)
-   [Relationship](#relationship)
    -   [One to Many](#one-to-many)
    -   [Many to One](#many-to-one)
    -   [Many to Many](#many-to-many)
    -   [Many to Many with Junction](#many-to-many-with-junction)
-   [&#128229;Save](#save)
    -   [Command API](#command-api)
    -   [Save Result API](#save-result-api)
-   [&#9749;Mock](#-mock)
    -   [Mock with Children](#mock-with-children)
    -   [Mock with Predefined List](#mock-with-predefined-list)
    -   [Fake Id](#fake-id)
-   [Entity Keywords](#entity-keywords)
    -   [Entity Creation Keywords](#entity-creation-keywords)
    -   [Entity Updating Keywords](#entity-updating-keywords)
    -   [Entity Reference Keywords](#entity-reference-keywords)
-   [Field Keywords](#field-keywords)
    -   [Basic Field Keywords](#basic-field-keywords)
    -   [Arithmetic Field Keywords](#arithmetic-field-keywords)
    -   [Lookup Field Keywords](#lookup-field-keywords)
-   [Entity Builder Factory](#entity-builder-factory)
-   [License](#license)

## Introduction

<p align="center">
<img src="docs/images/sales-objects.png#2020-5-31" width="400" alt="Sales Object Graph">
</p>

Imagine the complexity to generate all sObjects and relationships in the above diagram. With ATK we can create them within just one Apex statement. Here, we are generating:

1. _200_ accounts with names: `Name-0001, Name-0002, Name-0003...`
2. Each of the accounts has _2_ contacts.
3. Each of the contacts has _1_ opportunity via the OpportunityContactRole.
4. Also each of the accounts has _2_ orders.
5. Also each of the orders belongs to _1_ opportunity from the same account.

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
2. Debug level is set to DEBUG.

| 1000 \* Account | Database.insert | ATK Save | ATK Mock | ATK Mock Perf. |
| --------------- | --------------- | -------- | -------- | -------------- |
| CPU Time        | 0               | 0        | 487      | N/A            |
| Real Time (ms)  | 6300            | 6631     | 656      | ~10x faster    |

### Demos

Here are demos under the `scripts/apex` folder, they have been successfully run in fresh Salesforce organization with appropriate feature enabled. If not, please try to fix them with FLS, validation rules or duplicate rules etc.

| Subject              | File Path                         | Description                                                                                                                      |
| -------------------- | --------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| Campaign             | `scripts/apex/demo-campaign.apex` | How to genereate campaigns with hierarchy relationships. `ATK.EntityBuilder` is implemented to reuse the field population logic. |
| Consumer Goods Cloud | `scripts/apex/demo-consumer.apex` | Create meaningful sObject relationship distributions in one ATK statement.                                                       |
| Sales                | `scripts/apex/demo-sales.apex`    | You've already seen it in the above paragraph.                                                                                   |
| Products             | `scripts/apex/demo-products.apex` | How to generate PriceBook2, PriceBookEntry, Product2, ProductCategory, Catalog.                                                  |
| Cases                | `scripts/apex/demo-cases.apex`    | How to generate Accounts, Contacts and Cases.                                                                                    |
| Users                | `scripts/apex/demo-users.apex`    | How to generate community users in one goal.                                                                                     |

## Relationship

The object relationships described in a single ATK statement must be a Directed Acyclic Graph ([DAG](https://en.wikipedia.org/wiki/Directed_acyclic_graph)) , thus no cyclic relationships. If the validation fails, an exception will be thrown.

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

The result of the following statement is identical to the one above.

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

The above ATK statement will give the following distribution patterns, which seems not intuitive, if not intentional. It only makes scenes when the same contact play two different roles in the same opportunity.

| Opportunity Name | Contact Name | Contact Role   |
| ---------------- | ------------ | -------------- |
| Opportunity 0001 | Contact 0001 | Business User  |
| Opportunity 0001 | Contact 0001 | Decision Maker |
| Opportunity 0002 | Contact 0002 | Business User  |
| Opportunity 0002 | Contact 0002 | Decision Maker |
| ...              | ...          | ....           |

### Many to Many with Junction

`junctionOf()` can annotate an sObject as the junction of a many-to-many relationship. Its main purpose is to distribute parents of the junction object from one branch to another in a specific order. Note:

-   `junctionOf()` must be used directly after [Entity Keywords](#entity-keywords).
-   All parent relationships of the junction sObject used in the statement must be listed in the `junctionOf()` keyword.
-   Different defining order of the junction relationships will result in different distributions.

```java
ATK.prepare(Opportunity.SObjectType, 10)
    .field(Opportunity.Name).index('Opportunity {0000}')
    .withChildren(OpportunityContactRole.SObjectType, OpportunityContactRole.OpportunityId, 20)
        .junctionOf(OpportunityContactRole.OpportunityId, OpportunityContactRole.ContactId)
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

| Junction Keyword API                                                                                                                          | Description                                                          |
| :-------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------- |
| junctionOf(SObjectField _parentId1_, SObjectField _parentId2_);                                                                               | Annotate an entity is a junction of the listed parent relationships. |
| junctionOf(SObjectField _parentId1_, SObjectField _parentId2_, SObjectField _parentId3_);                                                     | Annotate an entity is a junction of the listed parent relationships. |
| junctionOf(SObjectField _parentId1_, SObjectField _parentId2_, SObjectField _parentId3_, SObjectField _parentId4_);                           | Annotate an entity is a junction of the listed parent relationships. |
| junctionOf(SObjectField _parentId1_, SObjectField _parentId2_, SObjectField _parentId3_, SObjectField _parentId4_, SObjectField _parentId5_); | Annotate an entity is a junction of the listed parent relationships. |
| junctionOf(List\<SObjectField\> _parentIds_);                                                                                                 | Annotate an entity is a junction of the listed parent relationships. |

## &#128229;Save

### Command API

There are three commands to create the sObjects, in database, in memory, or in mock istate.

| Method API                              | Description                                                                                                                                                                             |
| --------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| ATK.SaveResult save()                   | Actual DMLs will be performed to insert/update sObjects into Salesforce.                                                                                                                |
| ATK.SaveResult save(Boolean _doInsert_) | If `doInsert` is `false`, no actual DMLs will be performed, just in-memory generated SObjects will be returned. Only writable fields can be populated.                                  |
| ATK.SaveResult mock()                   | No actual DMLs will be performed, but sObjects will be returned in SaveResult as if they are newly retrieved by SOQL with fake Ids. Both writable and read-only fields can be populated |

### Save Result API

Use `ATK.SaveResult` to retrieve sObjects generated from the ATK statement.

| Method                                                      | Description                                                                                                       |
| ----------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| List<SObject> get(SObjectType _objectType_)                 | Get the sObjects generated from the first `SObjectType` defined in ATK statement.                                 |
| List<SObject> get(SObjectType _objectType_, Integer _nth_); | Get the sObjects generated from the nth `SObjectType` defined in ATK statement, such as in the Account Hierarchy. |
| List<SObject> getAll(SObjectType _objectType_)              | Get all sObjects generated from `SObjectType` defined in ATK statement.                                           |

## &#9749; Mock

The followings are supported, when generate sObjects with `mock()` command:

1. Assign extremely large fake IDs to the generated sObjects.
2. Assign values to read-only fields, such as _formula fields_, _rollup summary fields_, and _system fields_.
3. Assign one level children relationship and multiple level parent relationships.

### Mock with Children

<p>
  <img src="./docs/images/mock-relationship.png#2021-3-9" align="right" width="250" alt="Mock Relationship">
  To establish a relationship graph as the picture on the right, we can start from any node. <b>However only the sObjects created in the prepare statement can have child relationships referencing their direct children.</b><br><br>
  <b>Note</b>: As the diagram illustrated the direct children D and E of B can not reference back to B. The decision is made to prevent a <a href="https://trailblazer.salesforce.com/issues_view?id=a1p3A000001Gv4KQAS">Known Salesforce Issue</a> reported since winter 19. Here we are trying to avoid forming circular references. But D and E can still have other parent relationships, such as D to C. <br><br>
  All the nodes in green are reachable from node B. The diagram can be interpreted as the following SOQL statement:
</p>

```SQL
SELECT Id, A__r.Id, (SELECT Id FROM E__r), (SELECT Id, C__r.Id FROM D__r) FROM B__c
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

| Keyword API                                                 | Description                                                                                                                                                                                              |
| ----------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Id fakeId(Schema.SObjectType _objectType_)                  | Return self incrementing fake IDs. They will start over from each transaction, which means they are unique within each transaction. By default Ids will start from `ATK.fakeId(Account.SObjectType, 1)`. |
| Id fakeId(Schema.SObjectType _objectType_, Integer _index_) | Return the fake ID specified an index explicitly.                                                                                                                                                        |

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

All the following APIs have an `Integer size` parameter at the end, which indicate how many records will be created on the fly.

```java
ATK.prepare(A__c.SObjectType, 10)
    .withChildren(B__c.SObjectType, B__c.A_ID__c, 10)
        .withParents(C__c.SObjectType, B__c.C_ID__c, 10)
    .save();
```

| Keyword API                                                                           | Description                                                                                         |
| ------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| prepare(SObjectType _objectType_, Integer _size_)                                     | Always start chain with `prepare()` keyword. It is the root sObject to start relationship with.     |
| withParents(SObjectType _objectType_, SObjectField _referenceField_, Integer _size_)  | Establish many to one relationship between the previous working on sObject and the current sObject. |
| withChildren(SObjectType _objectType_, SObjectField _referenceField_, Integer _size_) | Establish one to many relationship between the previous working on sObject and the current sObject. |

### Entity Updating Keywords

All the following APIs have a `List<SObject> objects` parameter at the end, which indicates the sObjects are selected/created elsewhere, and ATK will help to `upsert` them.

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

| Keyword API                                                                                      | Description                                                                                         |
| ------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------- |
| prepare(SObjectType _objectType_, List\<SObject\> _objects_)                                     | Always start chain with `prepare()` keyword. It is the root sObject to start relationship with.     |
| withParents(SObjectType _objectType_, SObjectField _referenceField_, List\<SObject\> _objects_)  | Establish many to one relationship between the previous working on sObject and the current sObject. |
| withChildren(SObjectType _objectType_, SObjectField _referenceField_, List\<SObject\> _objects_) | Establish one to many relationship between the previous working on sObject and the current sObject. |

### Entity Reference Keywords

All the following APIs don't have a third parameter of size or list at the end, which means the relationship will look back to reference the previously created sObjects.

| Keyword API                                                           | Description                                                                                         |
| --------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| withParents(SObjectType _objectType_, SObjectField _referenceField_)  | Establish many to one relationship between the previous working on sObject and the current sObject. |
| withChildren(SObjectType _objectType_, SObjectField _referenceField_) | Establish one to many relationship between the previous working on sObject and the current sObject. |

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

| Keyword API                                                                                                                                                                       | Description                                                                                                                       |
| --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| index(String _format_)                                                                                                                                                            | Formatted string with `{0000}`, can recognize left padding. i.e. `Name-{0000}` will generate Name-0001, Name-0002, Name-0003 etc. |
| **Repeat Family**                                                                                                                                                                 |                                                                                                                                   |
| repeat(Object _value_)                                                                                                                                                            | Repeat with a single fixed value.                                                                                                 |
| repeat(Object _value1_, Object _value2_)                                                                                                                                          | Repeat with the provided values alternatively.                                                                                    |
| repeat(Object _value1_, Object _value2_, Object _value3_)                                                                                                                         | Repeat with the provided values alternatively.                                                                                    |
| repeat(Object _value1_, Object _value2_, Object _value3_, Object _value4_)                                                                                                        | Repeat with the provided values alternatively.                                                                                    |
| repeat(Object _value1_, Object _value2_, Object _value3_, Object _value4_, Object _value5_)                                                                                       | Repeat with the provided values alternatively.                                                                                    |
| repeat(List\<Object\> _values_)                                                                                                                                                   | Repeat with the provided values alternatively.\*\*                                                                                |
| **RepeatX Family**                                                                                                                                                                |                                                                                                                                   |
| repeatX(Object _value1_, Integer _size1_, Object _value2_, Integer _size2_)                                                                                                       | repeat each value by x, y... times in sequence.                                                                                   |
| repeatX(Object _value1_, Integer _size1_, Object _value2_, Integer _size2_, Object _value3_, Integer _size3_)                                                                     | repeat each value by x, y... times in sequence.                                                                                   |
| repeatX(Object _value1_, Integer _size1_, Object _value2_, Integer _size2_, Object _value3_, Integer _size3_, Object _value4_, Integer _size4_)                                   | repeat each value by x, y... times in sequence.                                                                                   |
| repeatX(Object _value1_, Integer _size1_, Object _value2_, Integer _size2_, Object _value3_, Integer _size3_, Object _value4_, Integer _size4_, Object _value5_, Integer _size5_) | repeat each value by x, y... times in sequence.                                                                                   |
| repeatX(List\<Object\> _values_, List\<Integer\> _sizes_)                                                                                                                         | repeat each value by x, y... times in sequence.                                                                                   |

### Arithmetic Field Keywords

These keywords will increase/decrease the `init` values by the provided steps.

#### Number Arithmetic

| Keyword API                                | Description                             |
| ------------------------------------------ | --------------------------------------- |
| add(Decimal _init_, Decimal _step_)        | Must be applied to a number type field. |
| substract(Decimal _init_, Decimal _step_)  | Must be applied to a number type field. |
| divide(Decimal _init_, Decimal _factor_)   | Must be applied to a number type field. |
| multiply(Decimal _init_, Decimal _factor_) | Must be applied to a number type field. |

#### Date/Time Arithmetic

| Keyword API                               | Description                                    |
| ----------------------------------------- | ---------------------------------------------- |
| addYears(Object _init_, Integer _step_)   | Must be applied to a Datetime/Date type field. |
| addMonths(Object _init_, Integer _step_)  | Must be applied to a Datetime/Date type field. |
| addDays(Object _init_, Integer _step_)    | Must be applied to a Datetime/Date type field. |
| addHours(Object _init_, Integer _step_)   | Must be applied to a Datetime/Time type field. |
| addMinutes(Object _init_, Integer _step_) | Must be applied to a Datetime/Time type field. |
| addSeconds(Object _init_, Integer _step_) | Must be applied to a Datetime/Time type field. |

### Lookup Field Keywords

These are field keywords in nature, but without the need to be chained after `.field()`. ATK will help to look up the IDs and assign them to the correct relationship fields automatically.

```java
ATK.prepare(Account.SObjectType, 10)
    .recordType('Business_Account');   // case sensitive

ATK.prepare(User.SObjectType, 10)
    .profile('Chatter Free User')      // must be applied to User SObject
    .permissionSet('Survey_Creator');  // must be applied to User SObject
```

| Keyword API                                                   | Description                                                                                                            |
| ------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| recordType(String _name_)                                     | Assign record type ID by developer name, the name is case sensitive due the `getRecordTypeInfosByDeveloperName()` API. |
| profile(String _name_)                                        | Assign profile ID by profile name.                                                                                     |
| permissionSet(String _name_)                                  | Assign the permission set to users by developer name.                                                                  |
| permissionSet(String name1, String _name2_)                   | Assign all the permission sets to users by developer names.                                                            |
| permissionSet(String _name1_, String _name2_, String _name3_) | Assign all the permission sets to users by developer names.                                                            |
| permissionSet(List\<String\> _names_)                         | Assign all the permission sets to users by developer names.                                                            |

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
