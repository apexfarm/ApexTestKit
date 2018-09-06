# Apex Test Kit (beta)

Notes when use beta version:

> * ATKFaker is not yet fully ported from [faker.js](https://github.com/marak/Faker.js/), still needs some minor works.
> * Global APIs are fairly stable, but are also subject to change during beta period.

Apex Test Kit (Salesforce) is a library to help generate testing data for Apex test classes automatically. It is trying to solve the following frustrations when creating testing data:

1. Time wasted to think of good username, email, phone number etc.
2. Time wasted to resolve data insertion errors due to missing required fields.
3. Time wasted to create many to many relationships, 100 x 100 records for example. 

```java
@isTest
static void testAccountCreation() {
    ATKWizard me = new ATKWizard();
    // create 100 accounts, each has 2 contacts
    me.wantMany('Account')
        .total(100)
        .hasMany('Contact')
            .referenceBy('AccountId') // can be omitted
            .total(200)
        .generate();

    List<Account> accountList = [SELECT Id FROM Account];
    System.assertEquals(100, accountList.size());
}
```

Underneath, the data are automatically populated with appropriate values according to field types, including: BOOLEAN, DATE, TIME, DATETIME, DOUBLE, INTEGER, PERCENT, CURRENCY, PICKLIST, MULTIPICKLIST, STRING, TEXTAREA, EMAIL, URL, PHONE, ADDRESS.

## Usage

### 1. ATKWizard Class

All examples below can be successfully run from test class ATKWizardTest in a clean Salesforce CRM organization. If validation rules are added to certain sObjects, the test class has to be twisted.

#### 1.1 One to Many

```java
ATKWizard me = new ATKWizard();
me.wantMany('Account')
    .total(10)
    .hasMany('Contact')
        .referenceBy('AccountId') // can be omitted
        .total(40)
    .generate();
```

#### 1.2 Many to One

```java
ATKWizard me = new ATKWizard();
me.wantMany('Contact')
    .total(40)
    .belongsTo('Account')
        .referenceBy('AccountId') // can be omitted
        .total(10)
    .generate();
```

#### 1.3 Many to Many

```java
Id pricebook2Id = Test.getStandardPricebookId();

ATKWizard me = new ATKWizard();
ATKWizard.Bag bag = me
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

me.wantMany('Pricebook2')
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
ATKWizard me = new ATKWizard();
me.wantMany('A')
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

| Keyword       | Param                 | Description                                                  |
| ------------- | --------------------- | ------------------------------------------------------------ |
| total()       | Integer               | **Required***, only if `fromList()` is not used. It defines number of records to create for the attached sObject context. |
| fromList()    | List\<sObject\>       | **Required***, only if `total()` is not used. This tells the wizard to use the predefined sObject list, rather than to create the records from scratch. |
| fields()      | Map\<String, Object\> | **Optional**. Use this keyword to tailor the field values, either to bypass validation rules, or to fulfill assertion logics. The key of the map is the field API name of the sObject. And the value of the map can be value generation expressions, or the exact values to use. |
| referenceBy() | String                | **Optional**. Use this keyword if there are multiple fields on the entity referencing the same sObject. It accepts relationship API name to reference parent from child. |
| origin()      | Map\<String, Object\> | **Optional**. Use this keyword if cross record arithmetic expressions are used in `fields()`, like `'{!dates.addDay($1.startDate__c, 1)}'`. Here `$1` is used to reference a previous record. Hence you can use `$0` to reference values on the current record. |

For `fields()`, there are two ways to assign rule collections:

1. Use List to assign values sequentially.
```java
fields(new Map<String, Object> {
    'Name' => new List<String> { // always try to parse String as expressions
        'AP-{{###}}', 'GG-{{###}}', 'MS-{{###}}'
    },
    'Alias' => new List<Object> { // object will not be treated as expressions
        'AP-{{###}}', 'GG-{{###}}', 'MS-{{###}}'
    },
    'Price' => new List<Object> {
        12.39, 28.76, 22.00
    }
});
```

2. Use Set to assign values randomly. 
```java
fields(new Map<String, Object> {
    'Name' => new Set<String> { // always try to parse String as expressions
        'AP-{{###}}', 'GG-{{###}}', 'MS-{{###}}'
    },
    'Alias' => new Set<Object> { // object will not be treated as expressions
        'AP-{{###}}', 'GG-{{###}}', 'MS-{{###}}'
    },
    'Price' => new Set<Object> {
        12.39, 28.76, 22.00
    }
});
```

For `fields()`, it can perform arithmetic calculations according to other field values:

```java
Date current = Date.today();
ATKWizard me = new ATKWizard();
me.wantMany('Contact')
    .total(10)
    .origin(new Map<String, Object> {
        'Birthdate' => current // give a default value for $1.Birthdate
    })
    .fields(new Map<String, Object> {
        'Birthdate' => '{!dates.addDays($1.Birthdate, -1)}'
    })
    .generate();
```

* $0 represents current record: `'EndDate__c' => '{!dates.addDays($0.StartDate__c, 1)}'`
* $1 represents previous record: `'StartDate__c' => '{!dates.addDays($1.EndDate__c, 1)}'`

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

#### 2.3 Entity Traversal Keywords

| Keyword | Param   | Description                                                  |
| ------- | ------- | ------------------------------------------------------------ |
| also    | Integer | Currently this is the only entity traversal keyword. It can be used to switch back to any previous sObject context. |

```java
ATKWizard me = new ATKWizard();
me.wantMany('A')
    .hasMany('B')
    .also() // go back 1 sObject (B) to sObject (A)
    .hasMany('C')
        .belongsTo('D')
    .also(2) // go back 2 sObject (C, D) to sObject (A)
    .hasMany('E')
    .generate();
```

### 3. ATKFaker Class

ATKWizard is built on top of the ATKFaker, which can also be used standalone. It is ported from [faker.js](https://github.com/marak/Faker.js/).

#### 3.1 Interpolation

All of the following helper APIs also support Interpolation from string expressions.

##### Helper Interpolation

Use `{!   }` Visualforce expression notation to interpolate helper methods. Empty parenthesis can be omitted. 

```java
ATKFaker.fake('Hello {!name.firstName(female)} {!name.lastName}!'); // => 'Hello Jeff Jin!'
```

##### Symbol Interpolation

Use `{{   }}` Handlebars expression notation to interpolate symbol formats.

```java
ATKFaker.fake('{{###-###-####}}');
```

Format can use the following symbols:

* \# - number
* ? - alpha
* \* - alphanumeric

#### 3.2 Internet 

```java
ATKFaker.internet.userName();
ATKFaker.internet.email();
ATKFaker.internet.url();
ATKFaker.internet.avatar();
```

#### 3.3 Phone

```java
ATKFaker.phone.phoneNumber();
ATKFaker.phone.phoneNumber('1xx-xxx-xxxx');
```

#### 3.4 Name 

```java
ATKFaker.name.firstName();
ATKFaker.name.firstName('male');
ATKFaker.name.firstName('female');
ATKFaker.name.lastName();
```

#### 3.5 Random 

```java
ATKFaker.random.boolean();
ATKFaker.random.number(); // => 0-999
ATKFaker.random.number(99); // number(max) => 0-99
ATKFaker.random.number(5, 2); // number(precesion, scale) => 123.45
ATKFaker.random.number(0, 99, 2); // number(min, max, scale) => 75.23
ATKFaker.random.arrayElements(new List<Integer> { 1, 2, 3, 4, 5 });
ATKFaker.random.arrayElements(new List<Integer> { 1, 2, 3, 4, 5 }, 3); // => {2, 4, 5}
```

#### 3.6 Lorem

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

#### 3.7 Dates

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
