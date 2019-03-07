# Apex Test Kit 2.0

![](https://img.shields.io/badge/version-2.0.0-brightgreen.svg) ![](https://img.shields.io/badge/build-passing-brightgreen.svg) ![](https://img.shields.io/badge/coverage-%3E95%25-brightgreen.svg)

Apex Test Kit is a Salesforce library to help generate testing data for Apex test classes. It has the following features:

1. Generate good-looking names for username, email, phone number etc.
2. Automatically guess values for required fields and deal with uniqueness.
3. Establish arbitrary level many to many relationships.

```java
@isTest
static void testAccountCreation() {
    // create 10 accounts, each has 2 contacts
    ATKWizard.I().wantMany(Account.SObjectType)
        .total(10)
        .fields().guard().end()
        .haveMany(Contact.SObjectType)
            .total(20)
        	.fields().guard().end()
        .generate();

    List<Account> accountList = [SELECT Id FROM Account];
    System.assertEquals(10, accountList.size());
}
```

Underneath, the data are automatically guessed with appropriate values according to field types, including: BOOLEAN, DATE, TIME, DATETIME, DOUBLE, INTEGER, PERCENT, CURRENCY, PICKLIST, MULTIPICKLIST, STRING, TEXTAREA, EMAIL, URL, PHONE, ADDRESS.

### Caveat

1. Depends on number of fields generated, the size of debug log could exceed the 5MB limit. In such case, please set the ApexCode debug level to `DEBUG`.
2. Sometime ramdom values could bring uncertainty to test results. In such case, please specify the genereation expression rule explicitly or to a fixed value.
3. The current field generation capacity is around 6000 in 10 seconds. If there are 20 generated fields (not fixed values) per record, the max record generation capacity is around 300. If more are created, it is likely to reach the CPU limit. So It is also better to use `Test.startTest()` and `Test.stopTest()` to wrap your testing logic.
4. If record type is activated and there are picklist values depending on them, please try to declare the picklist values in the `fields()` explicitly for that record type.

## Usage of ATKWizard

All examples below can be successfully run from `src/classes/SampleTest.cls` in a clean Salesforce CRM organization. If validation rules were added to CRM standard sObjects, `fields().useEval().end()` keywords could be used to tailor the record generation to bypass them.

### 1. Setup Relationship

#### 1.1 One to Many

**Note**: the following `referenceBy()` keyword can be omitted, because there is only one Contact->Account relationship field on Contact sObject.

```java
ATKWizard.I().wantMany(Account.SObjectType)
    .total(10)
    .fields().guard().end()
    .haveMany(Contact.SObjectType)
        .referenceBy(Contact.AccountId) // can be omitted
        .total(40)
        .fields().guard().end()
    .generate();
```

#### 1.2 Many to One

```java
ATKWizard.I().wantMany(Contact.SObjectType)
    .total(40)
    .fields().guard().end()
    .belongTo(Account.SObjectType)
        .referenceBy(Contact.AccountId) // can be omitted
        .total(10)
        .fields().guard().end()
    .generate();
```

#### 1.3 Many to Many

```java
Id pricebook2Id = Test.getStandardPricebookId();

ATKWand.IWizardBag bag = ATKWizard.I().wantMany(Product2.SObjectType)
    .total(5)
    .fields().guard().end()
    .haveMany(PricebookEntry.SObjectType)
        .referenceBy(PricebookEntry.Product2Id) // can be omitted
        .total(5)
        .fields()
            .guard()
            .useEval(PricebookEntry.Pricebook2Id, pricebook2Id)
            .useEval(PricebookEntry.UseStandardPrice, false)
            .useEval(PricebookEntry.IsActive, true)
        .end()
    .generate();

ATKWizard.I().wantMany(Pricebook2.SObjectType)
    .total(5)
    .fields().guard().end()
    .haveMany(PricebookEntry.SObjectType)
        .referenceBy(PricebookEntry.Pricebook2Id) // can be omitted
        .total(25)
        .fields()
            .guard()
            .useEval(PricebookEntry.UseStandardPrice, false)
            .useEval(PricebookEntry.IsActive, true)
        .end()
        .belongTo(Product2.SObjectType)
            .referenceBy(PricebookEntry.Product2Id) // can be omitted
            .useList(bag.get(Product2.SObjectType))
    .generate();
```

### 2. Keyword Overview

#### 2.1 Entity Creation Keywords

There are three entity creation keywords, each of them will start a new sObject context. And it is advised to use the following indentation format for clarity.

```java
ATKWizard.I().wantMany(A__c.SObjectType)
    .haveMany(B__c.SObjectType)
        .belongTo(C__c.SObjectType)
            .haveMany(D__c.SObjectType)
    .generate();
```

| Keyword     | Param  | Description                                                  |
| ----------- | ------ | ------------------------------------------------------------ |
| wantMany()  | SObjectType | Always start chain with wantMany keyword. It is the root sObject to start relationship with. |
| haveMany()   | SObjectType | Establish one to many relationship between the previous working on sObject and the current sObject. |
| belongTo() | SObjectType | Establish many to one relationship between the previous working on sObject and the current sObject. |

#### 2.2 Entity Decoration Keywords

Here is an example to demo the use of all entity decoration keywords. Although sounds many, for basic usage only `total()` and `fields()` will be used frequently and with occasional use of `referenceBy()`.

```java
// create 10 A, each has 2 B.
List<A__c> aList = [SELECT Id FROM A__c Limit 10];
ATKWizard.I().wantMany(A__c.SObjectType)
    .fromList(aList);
    .haveMany(B__c.SObjectType)
        .referenceBy(B__C.A_ID__c)
        .total(20)
        .fields()
           .guard()
           .useEval(B__C.AnyField__c)
           .useEval(B__C.Price__c, 12.34)
           .useEval(B__C.PhoneNumber__c, '{{###-###-####}}')
           .useEval(B__C.FirstName__c, '{!name.firstName(male)}')
           .useXref(B__C.Counter__c, '{!numbers.add($1.Counter__c, 1)}', 1)
        .end()
    .generate();
```

##### 2.2.1 Entity Graph Decoration Keywords

| Keyword       | Param           | Description                                                  |
| ------------- | --------------- | ------------------------------------------------------------ |
| total()       | Integer         | **Required***, only if `fromList()` is not used. It defines number of records to create for the attached sObject context. |
| fromList()    | List\<sObject\> | **Required***, only if `total()` is not used. This tells the wizard to use the previously created sObject list, rather than to create the records from scratch. |
| referenceBy() | SObjectField    | **Optional**. Only use this keyword if there are multiple fields on the entity referencing the same sObject. |

##### 2.2.2 Entity Field Decoration Keywords

Only use `guard()`, `useEval()`, `useXref()`, between `fields()` and `end()` keywords. And every `fields()` must follow an `end()` at the bottom. 

| Keyword   | Param                          | Description                                                  |
| --------- | ------------------------------ | ------------------------------------------------------------ |
| fields()  | N/A                            | **Optional**. Start of declaring field generation logic.     |
| end()     | N/A                            | **Optional**. End of declaring field generation logic.       |
| guard()   | [Boolean]                      | **Optional**. Turn on guard for `REQUIRED_FIELD_MISSING` exceptions by implicitly guessing values for fields not defined in `useEval()` and `useXref()`. 80% of the time, implicit guessing is useful, but you would not like to use it for sObjects with many required fields such as User and Event etc. |
| useEval() | SObjectField, [Object]         | **Optional**. Use this keyword to tailor the field values, either to bypass validation rules, or to fulfill assertion logics. The second parameter could be either `ATKFaker` interpolation expressions, or primitive values. |
| useXref() | SObjectField, String, [Object] | **Optional**. Use this keyword if cross record arithmetic expressions are used, like `'{!dates.addDay($1.startDate__c, 1)}'`. Here `$1` is used to reference a previous record. Hence you can use `$0` to reference values on the current record. |

#### 2.3 Entity Traversal Keywords

| Keyword | Param   | Description                                                  |
| ------- | ------- | ------------------------------------------------------------ |
| also    | Integer | It can be used to switch back to any previous sObject context. |

```java
ATKWizard.I().wantMany(A__c.SObjectType)
    .haveMany(B__c.SObjectType)
    .also() // go back 1 sObject (B) to sObject (A)
    .haveMany(C__c.SObjectType)
        .belongTo(D__c.SObjectType)
    .also(2) // go back 2 sObject (C, D) to sObject (A)
    .haveMany(E__c.SObjectType)
    .generate();
```

### 3. Advanced Usage

#### 3.1 Rule List

With rule `List<>`, `useEval()` can sequentially assign values to records created. Use `List<Object>` instead of `List<String>` whenever there is no need of ATKFaker interpolation, due to less CPU limit consumed.

```java
ATKWizard.I().wantMany(SomeObject__c.SObjectType)
    .total(3)
    .fields()
    	// ATK will always try to parse String as expressions
        .useEval(SomeObject__c.Name__c, new List<String> {
            'AP-{{###}}', 'GG-{{###}}', 'MS-{{###}}'
        })
    	// ATK will never try to parse Object as expressions
        .useEval(SomeObject__c.Alias__c, new List<Object> { 
            'AP-123', 'GG-456', 'MS-789'
        })
    	.useEval(SomeObject__c.Price__c, new List<Object> {
            12.39, 28.76, 22.00
        })
    .end()
    .generate();
```

#### 3.2 Cross Record Reference

With `useXref()`, we can perform arithmetic calculations according to fields on previously created records. For example, we can create records with consecutive start dates and end dates as below:

```java
Datetime currentDatetime = Datetime.now();
ATKWizard.I().wantMany(Event.SObjectType)
    .total(10)
    .fields()
        .useXref(Event.StartDateTime, '{!dates.addDays($1.EndDateTime, 1)}', currentDatetime)
        .useXref(Event.EndDateTime, '{!dates.addDays($0.StartDateTime, 1)}')
        .useXref(Event.ActivityDateTime, '{!value.get($0.StartDateTime)}')
        .useEval(Event.DurationInMinutes, 24 * 60)
    .end()
    .generate();
```

`$0` represents current record, `$1` represents previous one record, and so on. **Caution**: Cross record reference field cannot be declared as rule list.

Here is a list of supported arithmetic expressions, negative values could also be used:

```java
// directly get value from a record field
'{!value.get($0.StartDateTime)}'

// numeric arithmetic
'{!numbers.add($1.Price__c, 10)}'
'{!numbers.substract($1.Price__c, 10)}'
'{!numbers.divide($1.Price__c, 10)}'
'{!numbers.multiply($1.Price__c, 10)}'

// date/datetime arithmetic
'{!dates.addDays($0.StartDate__c, 1)}'
'{!dates.addHours($0.StartDate__c, 1)}'
'{!dates.addMinutes($0.StartDate__c, 1)}'
'{!dates.addMonths($0.StartDate__c, 1)}'
'{!dates.addSeconds($0.StartDate__c, 1)}'
'{!dates.addYears($0.StartDate__c, 1)}'
```

## Usage of ATKFaker

ATKWizard is built on top of the ATKFaker, which can also be used standalone. It is ported from [faker.js](https://github.com/marak/Faker.js/).

### 1 Interpolation

All of the following helper APIs also support Interpolation from string expressions.

#### 1.1 Helper Interpolation

Use `{!   }` Visualforce expression notation to interpolate helper methods. Empty parenthesis can be omitted.

```java
ATKFaker.fake('Hello {!name.firstName(male)} {!name.lastName}!'); // => 'Hello Jeff Jin!'
```

#### 1.2 Symbol Interpolation

Use `{{   }}` Handlebars expression notation to interpolate symbol formats.

```java
ATKFaker.fake('{{###-###-####}}');
```

Format can use the following symbols:

* \# - number
* ? - alpha
* \* - alphanumeric

### 2 Helper APIs

All APIs can be used in `ATKFaker.fake()` as a string expression. Just remove the `ATKFaker` class, and the single quote for string parameter, the empty parentheses can also be optionally removed.

#### 2.1 Name

```java
ATKFaker.name.firstName();
ATKFaker.name.firstName('male');
ATKFaker.name.firstName('female');
ATKFaker.name.lastName();
```

#### 2.2 Internet

```java
ATKFaker.internet.userName();
ATKFaker.internet.email();
ATKFaker.internet.url();
ATKFaker.internet.avatar();
```

#### 2.3 Phone

```java
ATKFaker.phone.phoneNumber();
ATKFaker.phone.phoneNumber('1xx-xxx-xxxx');
```

#### 2.4 Random

```java
ATKFaker.random.boolean();
ATKFaker.random.number(); // => 0-999
ATKFaker.random.number(99); // number(max) => 0-99
ATKFaker.random.number(5, 2); // number(precesion, scale) => 123.45
ATKFaker.random.number(0, 99, 2); // number(min, max, scale) => 75.23
ATKFaker.random.arrayElements(new List<Integer> { 1, 2, 3, 4, 5 });
ATKFaker.random.arrayElements(new List<Integer> { 1, 2, 3, 4, 5 }, 3); // => {2, 4, 5}
```

#### 2.5 Lorem

```java
ATKFaker.lorem.word();
ATKFaker.lorem.words();
ATKFaker.lorem.sentence();
ATKFaker.lorem.sentences();
ATKFaker.lorem.paragraph();
ATKFaker.lorem.paragraphs();
ATKFaker.lorem.lines();
ATKFaker.lorem.text(); // word(s), sentence(s), paragraph(s), lines
```

#### 2.6 Dates

```java
ATKFaker.dates.past();
ATKFaker.dates.past(3, '2018-08-13'); // date in 3 years before 2018-08-13
ATKFaker.dates.future()
ATKFaker.dates.future(3, '2018-08-13'); // date in 3 years after 2018-08-13
ATKFaker.dates.between('2017-08-13', '2018-08-13');
```

## License

MIT License
