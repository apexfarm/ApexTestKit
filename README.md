# Apex Test Kit

![](https://img.shields.io/badge/build-passing-brightgreen.svg) ![](https://img.shields.io/badge/coverage-%3E95%25-brightgreen.svg) 

Apex Test Kit (Salesforce) is a library to help generate testing data for Apex test classes automatically. It has the following features:

1. Generate good-looking names for username, email, phone number etc.
2. Automatically populate required fields and deal with unique values.
3. Establish arbitrary level many to many relationships.

```java
@isTest
static void testAccountCreation() {
    // create 10 accounts, each has 2 contacts
    ATKWizard.I().wantMany('Account')
        .total(10)
        .hasMany('Contact')
            .total(20)
        .generate();

    List<Account> accountList = [SELECT Id FROM Account];
    System.assertEquals(10, accountList.size());
}
```

Underneath, the data are automatically populated with appropriate values according to field types, including: BOOLEAN, DATE, TIME, DATETIME, DOUBLE, INTEGER, PERCENT, CURRENCY, PICKLIST, MULTIPICKLIST, STRING, TEXTAREA, EMAIL, URL, PHONE, ADDRESS.

### Caveat

1. Depends on number of required fields and generation expression rules, the size of debug log could exceed the 5MB limit. In such case, please toggle the debug level to hide unnecessary information.
2. Sometime ramdom values could bring uncertainty to test results. In such case, please specify the genereation expression rule explicitly or to a fixed value.

## Usage of ATKWizard 

All examples below can be successfully run from `src/classes/SampleTest.cls` in a clean Salesforce CRM organization. If validation rules were added to CRM standard sObjects, `fields()` keyword should be used to tailor the record generation to bypass them.

### 1. Setup Relationship

When `referenceBy()` is omitted, the relationship field will be looked up implicitly according to the sObject type.

#### 1.1 One to Many

```java
ATKWizard.I().wantMany('Account')
    .total(10)
    .hasMany('Contact')
        .referenceBy('AccountId') // can be omitted
        .total(40)
    .generate();
```

#### 1.2 Many to One

```java
ATKWizard.I().wantMany('Contact')
    .total(40)
    .belongsTo('Account')
        .referenceBy('AccountId') // can be omitted
        .total(10)
    .generate();
```

#### 1.3 Many to Many

```java
Id pricebook2Id = Test.getStandardPricebookId();

ATKWizard.Bag bag = ATKWizard.I()
    .wantMany('Product2')
        .total(5)
        .hasMany('PricebookEntry')
            .referenceBy('Product2Id') // can be omitted
            .fields(new Map<String, Object> {
                'Pricebook2Id' => pricebook2Id,
                'UseStandardPrice' => false,
                'IsActive' => true
            })
            .total(5)
        .generate();

ATKWizard.I().wantMany('Pricebook2')
    .total(5)
    .hasMany('PricebookEntry')
        .referenceBy('Pricebook2Id') // can be omitted
        .fields(new Map<String, Object> {
            'UseStandardPrice' => false,
            'IsActive' => true
        })
        .total(25)
        .belongsTo('Product2')
            .referenceBy('Product2Id') // can be omitted
            .fromList(bag.get('Product2'))
    .generate();
```

### 2. Keyword Overview

#### 2.1 Entity Creation Keywords

There are three entity creation keywords, each of them will start a new sObject context. And it is advised to use the following indentation format for clarity.

```java
ATKWizard.I().wantMany('A')
    .hasMany('B')
        .belongsTo('C')
            .hasMany('D')
    .generate();
```

| Keyword     | Param  | Description                                                  |
| ----------- | ------ | ------------------------------------------------------------ |
| wantMany()  | String | Always start chain with wantMany keyword. It is the root sObject to start relationship with. Accept a valid sObejct API name as its parameter. |
| hasMany()   | String | Establish one to many relationship between the previous working on sObject and the current sObject. Accept a valid sObejct API name as its parameter. |
| belongsTo() | String | Establish many to one relationship between the previous working on sObject and the current sObject. Accept a valid sObejct API name as its parameter. |

#### 2.2 Entity Decoration Keywords

Here is an example to demo the use of all entity decoration keywords.

```java
List<A> aList = [SELECT Id FROM A Limit 1];
ATKWizard.I().wantMany('A')
    .fromList(aList);
    .hasMany('B')
        .referenceBy('lookup_field_on_B_to_A')
        .total(2)
        .origin(new Map<String, Object>{
            'counter' => 1
        })
        .fields(new Map<String, Object>{
            'counter' => '{!numbers.add($1.counter, 1)}', // must work with origin()
            'firstName' => '{!name.firstName(male)}',
            'phoneNumber' => '{{###-###-####}}',
            'price' => 12.34
        })
    .generate();
```

| Keyword       | Param                 | Description                                                  |
| ------------- | --------------------- | ------------------------------------------------------------ |
| total()       | Integer               | **Required***, only if `fromList()` is not used. It defines number of records to create for the attached sObject context. |
| fromList()    | List\<sObject\>       | **Required***, only if `total()` is not used. This tells the wizard to use the predefined sObject list, rather than to create the records from scratch. |
| fields()      | Map\<String, Object\> | **Optional**. Use this keyword to tailor the field values, either to bypass validation rules, or to fulfill assertion logics. The key of the map is the field API name of the sObject. The value of the map can be either `ATKFaker` interpolation expressions, or primitive values. Multiple `fields()` can be chained. |
| referenceBy() | String                | **Optional**. Only use this keyword if there are multiple fields on the entity referencing the same sObject. It accepts relationship API name to reference parent from child. |
| origin()      | Map\<String, Object\> | **Optional**. Use this keyword if cross record arithmetic expressions are used in `fields()`, like `'{!dates.addDay($1.startDate__c, 1)}'`. Here `$1` is used to reference a previous record. Hence you can use `$0` to reference values on the current record. |

#### 2.3 Entity Traversal Keywords

| Keyword | Param   | Description                                                  |
| ------- | ------- | ------------------------------------------------------------ |
| also    | Integer | Currently this is the only entity traversal keyword. It can be used to switch back to any previous sObject context. |

```java
ATKWizard.I().wantMany('A')
    .hasMany('B')
    .also() // go back 1 sObject (B) to sObject (A)
    .hasMany('C')
        .belongsTo('D')
    .also(2) // go back 2 sObject (C, D) to sObject (A)
    .hasMany('E')
    .generate();
```

### 3. Advanced Usage

#### 3.1 Rule List vs Rule Set

With rule `List<>`, `fields()` can sequentially assign values to records created. Use `List<Object>` instead of `List<String>` whenever there is no need of ATKFaker interpolation, because it will consume less CPU limit.

```java
ATKWizard.I().wantMany('SomeObject__c')
    .total(3)
    .fields(new Map<String, Object> {
        'Name' => new List<String> { // ATK will always try to parse String as expressions
            'AP-{{###}}', 'GG-{{###}}', 'MS-{{###}}'
        },
        'Alias' => new List<Object> { // ATK will never try to parse Object as expressions
            'AP-123', 'GG-456', 'MS-789'
        },
        'Price' => new List<Object> {
            12.39, 28.76, 22.00
        }
    })
    .generate();
```

With rule `Set<>`, `fields()` can randomly assign values to records created. Please avoid using Set, because ramdon will introduce uncertainty, unless it is intended. 

```java
ATKWizard.I().wantMany('SomeObject__c')
    .total(3)
    .fields(new Map<String, Object> {
        'Name' => new Set<String> { // ATK will always try to parse String as expressions
            'AP-{{###}}', 'GG-{{###}}', 'MS-{{###}}'
        },
        'Alias' => new Set<Object> { // ATK will never try to parse Object as expressions
            'AP-123', 'GG-456', 'MS-789'
        },
        'Price' => new Set<Object> {
            12.39, 28.76, 22.00
        }
    })
    .generate();
```

#### 3.2 Cross Record Reference

Combining with `origin()`, `fields()` can also perform arithmetic calculations according to fields on previously created records.

```java
Date currentDate = Date.today();
ATKWizard.I().wantMany('Contact')
    .total(10) // create 10 contact
    .origin(new Map<String, Object> {
        'Birthdate' => currentDate // assign the first contact Birthday to today
    })
    .fields(new Map<String, Object> {
        'Birthdate' => '{!dates.addDays($1.Birthdate, -1)}' // one day less than the Birthday of previous record
    })
    .generate();
```

- $0 represents current record: `'EndDate__c' => '{!dates.addDays($0.StartDate__c, 1)}'`
- $1 represents previous record: `'StartDate__c' => '{!dates.addDays($1.EndDate__c, 1)}'`

Here is a list of supported arithmetic expressions:

```java
'{!numbers.add($1.Price__c, 10)}'
'{!numbers.substract($1.Price__c, 10)}'
'{!numbers.divide($1.Price__c, 10)}'
'{!numbers.multiply($1.Price__c, 10)}'
 
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

Copyright (c) 2018 Jianfeng Jin

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
