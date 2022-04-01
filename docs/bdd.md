![](https://img.shields.io/badge/version-4.0.0%20preview-orange.svg) ![](https://img.shields.io/badge/build-passing-brightgreen.svg) ![](https://img.shields.io/badge/coverage-93%25-brightgreen.svg)

[Mockito](https://site.mockito.org/) BDD flavor has been brought into Apex Test Kit with some twists. Some developments are still needed before its final release, such as:

1. Implement "in order" verification. (This is the only major feature currently missing.)
2. Add more exceptions and guards to help developers understand how to use the BDD API correctly.
3. Add more unit tests to cover wide variety scenarios.


| Environment           | Installation Link                                            | Version           |
| --------------------- | ------------------------------------------------------------ | ----------------- |
| Production, Developer | <a target="_blank" href="https://login.salesforce.com/packaging/installPackage.apexp?p0=04t2v000007GUCxAAO"><img src="https://github.com/apexfarm/ApexTestKit/raw/master/docs/images/deploy-button.png"></a> | ver 4.0.0 preview |
| Sandbox               | <a target="_blank" href="https://test.salesforce.com/packaging/installPackage.apexp?p0=04t2v000007GUCxAAO"><img src="https://github.com/apexfarm/ApexTestKit/raw/master/docs/images/deploy-button.png"></a> | ver 4.0.0 preview |

Please give your feedback in GitHub issue <a href="https://github.com/apexfarm/ApexTestKit/issues/34" target="_blank">v4.0 with BDD</a>, any missing features or API suggestions are welcomed. Also please help give a star if you like the BDD feature, it might help accelerate the release :).

## Table of Contents

- [Overview](#overview)
- [1. Given Statements](#1-given-statements)
  - [1.1 Three Rules](#11-three-rules)
  - [1.2 Answers](#12-answers)
- [2. Then Statements](#2-then-statements)
  - [2.1 Verification Modes](#21-verification-modes)
  - [2.2-Assertion Messages](#22-assertion-messages)
- [3. Argument Matchers](#3-argument-matchers)
  - [3.1 Type Matchers](#31-type-matchers)
    - [Any Types](#any-types)
    - [Primitives](#primitives)
    - [Collections](#collections)
  - [3.2 Value Matchers](#32-value-matchers)
    - [References](#references)
    - [Equals](#equals)
    - [Non Equals](#non-equals)
    - [Comparisons](#comparisons)
    - [Strings](#strings)
    - [sObjects](#sobjects)
  - [3.3 Logical Matchers](#33-logical-matchers)
    - [AND](#and)
    - [OR](#or)
    - [NOR](#nor) 

## Overview

```java
ATKMockTest mock = (ATKMockTest) ATK.mock(ATKMockTest.class);
// Given
ATK.startStubbing();
ATK.given(mock.doWithInteger(1)).willReturn('return 1');
ATK.stopStubbing();

// When
System.assertEquals('return 1', mock.doWithInteger(1));

// Then
((ATKMockTest) ATK.then(mock).should().once()).doWithInteger(1);
```

## 1. Given Statements

### 1.1 Three Rules

**Rule 1**: Given statements must be wrapped between `ATK.startStubbing()` and `ATK.stopStubbing()` statements.

```java
ATKMockTest mock = (ATKMockTest) ATK.mock(ATKMockTest.class);
ATK.startStubbing();
// Given Statements Here!
ATK.stopStubbing();
```

**Rule 2**: There are two flavors to declare given statements.  The following two will define the same behavior.

```java
// Flavor 1
ATK.given(mock.doWithInteger(1)).willReturn('return 1');

// Flavor 2
((ATKMockTest) ATK.willReturn('return 1').given(mock)).doWithInteger(1);
```

However only the latter flavor can be used for methods that return void.

```java
((ATKMockTest) ATK.willDoNothing().given(mock)).doVoidReturn(1);
```

**Rule 3**: Argument matchers can be used to match arbitrary arguments.

```java
ATK.given(mock.doWithInteger(ATK.eqInteger(1)).willReturn('return 1');
ATK.given(mock.doWithInteger(ATK.anyInteger())).willReturn('return any integer');
```

### 1.2 Answers

| API Name                        | Description                                                  |
| ------------------------------- | ------------------------------------------------------------ |
| `willReturn(Object value)`      | Return any value that compatible with the target method return type. |
| `willAnswer(ATK.Answer answer)` | Return a customized answer dynamically according to conditions such as arguments. |
| `willThrow(Exception exp)`      | Throw the exception when target method is called.            |
| `willDoNothing()`               | Return `null`.                                               |

## 2. Then Statements

This is the only flavor to declare then statements. And same as given statements, argument matchers can be used as well.

```java
((ATKMockTest) ATK.then(mock).should().once()).doWithInteger(1);
((ATKMockTest) ATK.then(mock).should().once()).doWithInteger(ATK.anyInteger());
```

### 2.1 Verification Modes

| API Name             | Alias To     | Description                                      |
| -------------------- | ------------ | ------------------------------------------------ |
| `never()`            | `times(0)`   | Verifies that interaction did not happen.        |
| `once()`             | `times(1)`   | Verifies that interaction happened exactly once. |
| `times(Integer n)`   |              | Allows verifying exact number of invocations.    |
| `atLeastOnce()`      | `atLeast(1)` | Allows at-least-once verification.               |
| `atLeast(Integer n)` |              | Allows at-least-n verification.                  |
| `atMostOnce()`       | `atMost(1)`  | Allows at-most-once verification.                |
| `atMost(Integer n)`  |              | Allows at-most-n verification.                   |

### 2.2 Assertion Messages

Here are sample assertion messages. The generated method signature could be different than the one defined in the test classes, such as all exact values will be replaced by `ATK.eq()` matchers.

```
Expected "[ATKMockTest].doWithIntegers(ATK.eq(1))" to be called 1 time(s). But has been called 0 time(s).
Expected "[ATKMockTest].doWithIntegers(ATK.eq(1))" to be called at least 3 time(s). But has been called 0 time(s).
Expected "[ATKMockTest].doWithIntegers(ATK.eq(1))" to be called at most 3 time(s). But has been called 0 time(s).
```

## 3. Argument Matchers

Please don't mix exact values and matchers in one given statement, either use exact values or matchers for all arguments.

```java
// Correct
ATK.given(mock.doWithIntegers(1, 2, 3)).willReturn('1, 2, 3');
ATK.given(mock.doWithIntegers(ATK.eqInteger(1), ATK.eqInteger(2), ATK.eqInteger(3)).willReturn('1, 2, 3');

// Wrong
ATK.given(mock.doWithIntegers(1, 2, ATK.eqInteger(3)).willReturn('1, 2, 3');
```

### 3.1 Type Matchers

#### Any Types

Please supply exactly the same type used by the matched argument, neither ancestor nor descendent types are allowed.

| API Name                     | Description                                          | Example                      |
| ---------------------------- | ---------------------------------------------------- | ---------------------------- |
| `Object any()`               | Matches **anything**, including nulls.               | `ATK.any()`                  |
| `Object any(Type type)`      | Matches any object of given type, excluding nulls.   | `ATK.any(String.class)`      |
| `Object nullable(Type type)` | Argument that is either `null` or of the given type. | `ATK.nullable(String.class)` |

#### Primitives

| API Name                 | Alias To                 | Description                                                  |
| ------------------------ | ------------------------ | ------------------------------------------------------------ |
| `Integer anyInteger()`   | `ATK.any(Integer.class)` | Only allow valued `Integer`, excluding nulls.                |
| `Long anyLong()`         | `ATK.any(Long.class)`        | Only allow valued `Long`, excluding nulls. |
| `Double anyDouble()`     | `ATK.any(Double.class)`      | Only allow valued `Double`, excluding nulls.                 |
| `Decimal anyDecimal()`   | `ATK.any(Decimal.class)`     | Only allow valued `Decimal`, excluding nulls.                |
| `Date anyDate()`         | `ATK.any(Date.class)`        | Only allow valued `Date`, excluding nulls.                   |
| `Datetime anyDatetime()` | `ATK.any(Datetime.class)`    | Only allow valued `Datetime`, excluding nulls.               |
| `Id anyId()`             | `ATK.any(Id.class)`          | Only allow valued `Id`, excluding nulls.                     |
| `String anyString()`     | `ATK.any(String.class)`      | Only allow valued `String`, excluding nulls.                 |
| `Boolean anyBoolean()`   | `ATK.any(Boolean.class)`     | Only allow valued `Boolean`, excluding nulls.                |

#### Collections

| API Name | Description | Example |
| ---- | ---- | ---- |
| `List<Object> anyList()`     | Only allow non-null `List`. | `ATK.anyList()` |
| `Object anySet()`     | Only allow non-null `Set`. | `ATK.anySet()` |
| `Object anyMap()`     | Only allow non-null `Map`. | `ATK.anyMap()` |
| `SObject anySObject()`     | Only allow non-null `SObject`. | `ATK.anySObject()` |
| `List<SObject> anySObjectList()`     | Only allow non-null `List<SObject>`, such as `List<Account>` etc. | `ATK.anySObjectList()` |

### 3.2 Value Matchers

#### References
| API Name | Description |
| ---- | ---- |
|`Object isNull()`| `null` argument. |
|`Object isNotNull()`| Not `null` argument. |
|`Object same(Object value)`| Object argument that is the same as the given value. |

#### Equals

| API Name | Alias To | Description |
| ---- | ---- | ---- |
|`Object eq(Object value)`| | Object argument that is equal to the given value. |
|`Integer eqInteger(Integer value)`| `(Integer) ATK.eq(123)` | `Integer` argument that is equal to the given value. |
|`Long eqLong(Long value)`| `(Long) ATK.eq(123L)` | `Long` argument that is equal to the given value. |
|`Double eqDouble(Double value)`| `(Double) ATK.eq(123.0D)` | `Double` argument that is equal to the given value. |
|`Decimal eqDecimal(Decimal value)`| `(Decimal) ATK.eq(123.0)` | `Decimal` argument that is equal to the given value. |
|`Date eqDate(Date value)`| `(Date) ATK.eq(Date.today())` | `Date` argument that is equal to the given value. |
|`Datetime eqDatetime(Datetime value)`| `(Datetime) ATK.eq(Datetime.now())` | `Datetime` argument that is equal to the given value. |
|`Id eqId(Id value)`| `(Id) ATK.eq(accountId)` | `Id` argument that is equal to the given value. |
|`String eqString(String value)`| `(String) ATK.eq('In Progress')` | `String` argument that is equal to the given value. |
|`Boolean eqBoolean(Boolean value)`| `(Boolean) ATK.eq(true)` | `Boolean` argument that is equal to the given value. |

#### Non Equals

| API Name | Description |
| ---- | ---- |
|`Object ne(Object value)`| Object argument that is not equal to the given value. |
|`Integer neInteger(Integer value)`| `Integer` argument that is not equal to the given value. |
|`Long neLong(Long value)`| `Long` argument that is not equal to the given value. |
|`Double neDouble(Double value)`| `Double` argument that is not equal to the given value. |
|`Decimal neDecimal(Decimal value)`| `Decimal` argument that is not equal to the given value. |
|`Date neDate(Date value)`| `Date` argument that is not equal to the given value. |
|`Datetime neDatetime(Datetime value)`| `Datetime` argument that is not equal to the given value. |
|`Id neId(Id value)`| `Id` argument that is not equal to the given value. |
|`String neString(String value)`| `String` argument that is not equal to the given value. |
|`Boolean neBoolean(Boolean value)`| `Boolean` argument that is not equal to the given value. |

#### Comparisons

Comparison matchers need to be casted to their targeting argument types with the following syntax:

```java
// Correct
ATK.given(mock.doWithInteger(ATK.gt(10).asInteger())).willReturn('> 10');
    
// Wrong - Error will be thrown
ATK.given(mock.doWithInteger((Integer) ATK.gt(10))).willReturn('> 10');
```

| API Name | Description | Example |
| ---- | ---- | ---- |
| `gt(Object value)` | Greater than the given value. | `ATK.gt(10L).asLong()` |
| `gte(Object value)` | Greater than or equal to the given value. | `ATK.gte(10.0D).asDouble()` |
| `lt(Object value)` | Less than the given value. | `ATK.lt(10.0).asDecimal()` |
| `lte(Object value)` | Less than or equal to the given value. | `ATK.lte(Date.today()).asDate()` |
| `between(Object min, Object max)` | Between the given values. `min` and `max` values are included, same behavior as the `BETWEEN` keyword used in SQL. | `ATK.between(1, 10).Integer()` |
| `between(Object min, Object max, Boolean inclusive)` | `inclusive = false` to exclude boundary values. | `ATK.between(1, 10, true).Integer()` |
| `between(Object min, Boolean minInclusive, Object max, Boolean maxInclusive)` | Finer control to the `min` and `max` inclusive behaviors. | `ATK.between(1, false, 10, true).Integer()` |

#### Strings

| API Name | Example |
| ---- | ---- |
| `String isBlank()` | `ATK.isBlank()` |
| `String isNotBlank()` | `ATK.isNotBlank()` |
| `String contains(String value)` | `ATK.contains('abc')` |
| `String startsWith(String value)` | `ATK.startsWith('abc')` |
| `String endsWith(String value)` | `ATK.endsWith('abc')` |
| `String matches(String regexp)` | `ATK.matches('^[2-9]\\d\'{\'2\'}\'-\\d\'{\'3\'}\'-\\d\'{\'4\'}\'$')` |


#### sObjects
| API Name | Example |
| ---- | ---- |
| `SObject sObjectWithId(Id value)` | `ATK.sObjectWithId(accountId)` |
| `SObject sObjectWithName(String value)` | `ATK.sObjectWithName('Salesforce')` |
| `SObject sObjectWith(SObjectField field, Object value)` | `ATK.sObjectWithId(Account.Name, 'Salesforce')` |
| `SObject sObjectWith(Map<SObjectField, Object> value)` | `ATK.sObjectWith(new Map<SObjectField, Object> {})` |
| `LIst<SObject> sObjectListWith(SObjectField field, Object value)` | `ATK.sObjectListWith(Opportunity.StageName, 'Open')` |
| `LIst<SObject> sObjectListWith(Map<SObjectField, Object> value)` | `ATK.sObjectListWith(new Map<SObjectField, Object> {})` |
| `LIst<SObject> sObjectListWith(List<Map<SObjectField, Object>> value, Boolean inOrder)` | `ATK.sObjectListWith(new List<Map<SObjectField, Object>>{}` |

### 3.3 Logical Matchers

Only matchers are allowed to be used as arguments for logical matchers, for example:

```java
// Type casting is no longer need for ATK.gt and ATK.lt, since they are wrapped within the logical matcher.
ATK.given(mock.doWithInteger((Integer) ATK.allOf(ATK.gt(1), ATK.lt(10)))).willReturn('arg > 1 AND arg < 10');
```

#### AND

| API Name                                                     | Description           |
| ---- | ---- |
| `Object allOf(Object arg1, Object arg2)`                     | Logical AND operator. |
| `Object allOf(Object arg1, Object arg2, Object arg3)`        | Logical AND operator. |
| `Object allOf(Object arg1, Object arg2, Object arg3, Object arg4)` | Logical AND operator. |
| `Object allOf(Object arg1, Object arg2, Object arg3, Object arg4, Object arg5)` | Logical AND operator. |
| `Object allOf(List<Object> args)`                            | Logical AND operator. |

#### OR

| API Name                                                     | Description          |
| ------------------------------------------------------------ | -------------------- |
| `Object anyOf(Object arg1, Object arg2)`                     | Logical OR operator. |
| `Object anyOf(Object arg1, Object arg2, Object arg3)`        | Logical OR operator. |
| `Object anyOf(Object arg1, Object arg2, Object arg3, Object arg4)` | Logical OR operator. |
| `Object anyOf(Object arg1, Object arg2, Object arg3, Object arg4, Object arg5)` | Logical OR operator. |
| `Object anyOf(List<Object> args)`                            | Logical OR operator. |

#### NOR

| API Name                                                     | Description           |
| ------------------------------------------------------------ | --------------------- |
| `Object isNot(Object arg1)`                                  | Logical NOT operator. |
| `Object noneOf(Object arg1, Object arg2)`                    | Logical NOR operator. |
| `Object noneOf(Object arg1, Object arg2, Object arg3)`       | Logical NOR operator. |
| `Object noneOf(Object arg1, Object arg2, Object arg3, Object arg4)` | Logical NOR operator. |
| `Object noneOf(Object arg1, Object arg2, Object arg3, Object arg4, Object arg5)` | Logical NOR operator. |
| `Object noneOf(List<Object> args)`                           | Logical NOR operator. |

