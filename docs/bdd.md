[Mockito](https://site.mockito.org/) BDD flavor has been brought into Apex Test Kit with some twists.

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

## Strictness

ATK begins with the most strict settings by default, and developers can use setting methods to gradually relax them. Each of the following setting methods can only work within its corresponding strictness.

| Strictness   | `stubVoid()` | `defaultAnswer()` | `stubOnly()`                                                 |
| ------------ | ------------ | ----------------- | ------------------------------------------------------------ |
| Strict Mode  | ✓            |                   | ✓                                                            |
| Lenient Mode |              | ✓                 | ✓                                                            |
|              |              |                   | **When** step cannot track stub-only invocations<br />**Then** step cannot verify stub-only invocations |

Settings can be applied at three levels from high to low. Lower level settings will override the high level settings:

```
+------------------------------+
|        +------------------+  |
|        |      +--------+  |  |
| global | mock |  stub  |  |  |
|        |      +--------|  |  |
|        +------------------+  |
+------------------------------+
```

### Strict Mode

Strict mode is the default strictness enforced for all mocking activities. It helps write clean mocking codes and increase productivity. In strict mode, ATK will:

1. Fail unstubbed method invocation immediately.
2. Mark stubbed method invocation as verified implicitly for the `haveNoMoreInteractions()` calls.
3. Detect unused stubs at the end of test with `haveNoUnusedStubs()` calls.

In strict mode, void methods can be treated as stubbed methods automatically at the following two levels:

```java
// 1. global level
ATK.mock().withSettings().stubVoid();
// 2. mock level
ATK.mock(YourClass.class, ATK.withSettings().stubVoid());
```

### Lenient Mode

In lenient mode, unstubbed methods will return default values, but they have to be explicitly verified for the `haveNoMoreInteractions()` calls. Use `lenient()` at three levels to enable lenient mode:

```java
// 1. global level
ATK.mock().withSettings().lenient();
// 2. mock level
ATK.mock(YourClass.class, ATK.withSettings().lenient());
// 3. stub level
ATK.lenient().given(mock.doSomething()).willReturn('Sth.');
```

In lenient mode, default answers can be specified differently at two levels:

```java
// 1. global level
ATK.mock().withSettings().lenient().defaultAnswer(ATK.RETURNS_DEFAULTS);
// 2. mock level
ATK.mock(YourClass.class, ATK.RETURNS_DEFAULTS);
ATK.mock(YourClass.class, ATK.withSettings().lenient().defaultAnswer(ATK.RETURNS_DEFAULTS));
```

| Default Answers        | Description                                                  |
| ---------------------- | ------------------------------------------------------------ |
| `ATK.RETURNS_DEFAULTS` | Return zeros, false, empty strings, empty collections (list, set, map), and then nulls. This is also the default behavior in lenient mode. |
| `ATK.RETURNS_SELF`     | Return itself whenever a method is invoked that returns a Type equal to the class or a superclass. |
| `ATK.RETURNS_MOCKS`    | Return ordinary values (zeros, false, empty string, empty collections) first, then it tries to return mocks. If the return type cannot be mocked (e.g. is final) then plain `null` is returned. |

Custom default answers can also be supplied here, just implement the `ATK.Answer` interface:

```java
public class YourDefaultAnswer implements ATK.Answer {
    public Object answer(ATK.Invocation invocation) {
        // ...
    }
}
```

## Given Statements

```java
YourClass mock = (YourClass) ATK.mock(YourClass.class);

// 1. Given Statements must defined between ATK.startStubbing() and ATK.stopStubbing().
ATK.startStubbing();

// 2. The following two flavors define the same behavior. 
ATK.given(mock.doWithInteger(1)).willReturn('one');               // 2-1. Flavor 1
((YourClass) ATK.willReturn('one').given(mock)).doWithInteger(1); // 2-2. Flavor 2

// 3. Only the second flavor can be used for void methods.
((YourClass) ATK.willDoNothing().given(mock)).doVoidReturn();

// 4. Matchers can be used to define the stubs with arbitrary arguments.
ATK.given(mock.doWithInteger(ATK.anyInteger())).willReturn('any');
ATK.given(mock.doWithInteger(ATK.gte(1)).willReturn('>=1');

// 5. Latter Stub with same arguments can override the former one.
ATK.given(mock.doWithInteger(1).willReturn('one');           // 5-1. Cannot be matched
ATK.given(mock.doWithInteger(ATK.gte(1)).willReturn('>=1');  // 5-2. Will be matched

ATK.stopStubbing();
```

### Answers

| API Name                        | Description                                                  |
| ------------------------------- | ------------------------------------------------------------ |
| `willReturn(Object value)`      | Return any value that compatible with the target method return type. |
| `willAnswer(ATK.Answer answer)` | Return a customized answer dynamically according to conditions such as arguments and return type. |
| `willThrow(Exception exp)`      | Throw the exception when target method is called.            |
| `willDoNothing()`               | Return `null`. Supposed to be called with void methods only. |

Answers can be chained for a particular stub, and they will be returned in their defining order for each invocation. If the answers are exhausted, `null` will returned instead. Here is an example:

```java
YourClass mock = (YourClass) ATK.mock(YourClass.class);
ATK.startStubbing();
ATK.given(mock.doWithInteger(1)).willReturn('one').willReturn('another one');
ATK.stopStubbing();

System.assertEquals('one', mock.doWithInteger(1));
System.assertEquals('another one', mock.doWithInteger(1));
System.assertEquals(null, mock.doWithInteger(1));
```

Custom answers can be supplied to `willAnswer(ATK.Answer answer)` method.

```java
public class YourCustomAnswer implements ATK.Answer {
    public Object answer(ATK.Invocation invocation) {
        // ...
    }
}
```

| `ATK.Invocation` Properties | Description |
| --------------------------- | ----------- |
| `Object mock`               |             |
| `ATK.Method method`         |             |
| `List<Object> arguments`    |             |

| `ATK.Method` Properties   | Description |
| ------------------------- | ----------- |
| `String name`             |             |
| `Type returnType`         |             |
| `List<Type> paramTypes`   |             |
| `List<String> paramNames` |             |



## Then Statements

This is the only flavor to declare then statements. And same as given statements, argument matchers can be used as well.

```java
((ATKMockTest) ATK.then(mock).should().once()).doWithInteger(1);
((ATKMockTest) ATK.then(mock).should().once()).doWithInteger(ATK.anyInteger());
```

### Verification Modes

| API Name             | Alias To     | Description                                      |
| -------------------- | ------------ | ------------------------------------------------ |
| `never()`            | `times(0)`   | Verifies that interaction did not happen.        |
| `once()`             | `times(1)`   | Verifies that interaction happened exactly once. |
| `times(Integer n)`   |              | Allows verifying exact number of invocations.    |
| `atLeastOnce()`      | `atLeast(1)` | Allows at-least-once verification.               |
| `atLeast(Integer n)` |              | Allows at-least-n verification.                  |
| `atMostOnce()`       | `atMost(1)`  | Allows at-most-once verification.                |
| `atMost(Integer n)`  |              | Allows at-most-n verification.                   |

### Assertion Messages

Here are sample assertion messages. The generated method signature could be different than the one defined in the test classes, such as all exact values will be replaced by `ATK.eq()` matchers.

```
Expected "[ATKMockTest].doWithIntegers(ATK.eq(1))" to be called 1 time(s). But has been called 0 time(s).
Expected "[ATKMockTest].doWithIntegers(ATK.eq(1))" to be called at least 3 time(s). But has been called 0 time(s).
Expected "[ATKMockTest].doWithIntegers(ATK.eq(1))" to be called at most 3 time(s). But has been called 0 time(s).
```

## Argument Matchers

Please don't mix exact values and matchers in one given statement, either use exact values or matchers for all arguments.

```java
// Correct
ATK.given(mock.doWithIntegers(1, 2, 3)).willReturn('1, 2, 3');
ATK.given(mock.doWithIntegers(ATK.eqInteger(1), ATK.eqInteger(2), ATK.eqInteger(3)).willReturn('1, 2, 3');

// Wrong
ATK.given(mock.doWithIntegers(1, 2, ATK.eqInteger(3)).willReturn('1, 2, 3');
```

### Type Matchers

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
| `Time anyTime()` | `ATK.any(Time.class)` | Only allow valued `Time`, excluding nulls. |
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

### Value Matchers

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
|`Time eqTime(Time value)`| `(Time) ATK.eq(Time.newInstance(0, 0, 0, 0))` | `Time` argument that is equal to the given value. |
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
|`Time neTime(Datetime value)`| `Time` argument that is not equal to the given value. |
|`Id neId(Id value)`| `Id` argument that is not equal to the given value. |
|`String neString(String value)`| `String` argument that is not equal to the given value. |
|`Boolean neBoolean(Boolean value)`| `Boolean` argument that is not equal to the given value. |

#### Comparisons

Comparison matchers are overloaded with the following primitive types: `Integer`, `Long`, `Double`, `Decimal`, `Date`, `Datetime`, `Time`, `Id`, `String`.

| API Name | Description | Example |
| ---- | ---- | ---- |
| `gt(Object value)` | Greater than the given value. | `ATK.gt(10L)` |
| `gte(Object value)` | Greater than or equal to the given value. | `ATK.gte(10.0D)` |
| `lt(Object value)` | Less than the given value. | `ATK.lt(10.0)` |
| `lte(Object value)` | Less than or equal to the given value. | `ATK.lte(Date.today())` |
| `between(Object min, Object max)` | Between the given values. `min` and `max` values are inclusive, same behavior as the `BETWEEN` keyword used in SQL. | `ATK.between(1, 10)` |
| `between(Object min, Object max, Boolean inclusive)` | Use `inclusive = false` to exclude boundary values. | `ATK.between(1, 10, true)` |
| `between(Object min, Boolean minInclusive, Object max, Boolean maxInclusive)` | Finer control to the `min` and `max` inclusive behaviors. | `ATK.between(1, false, 10, true)` |

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
| `SObject sObjectWith(SObjectField field, Object value)` | `ATK.sObjectWith(Account.Name, 'Salesforce')` |
| `SObject sObjectWith(Map<SObjectField, Object> value)` | `ATK.sObjectWith(new Map<SObjectField, Object> {})` |
| `LIst<SObject> sObjectListWith(SObjectField field, Object value)` | `ATK.sObjectListWith(Opportunity.StageName, 'Open')` |
| `LIst<SObject> sObjectListWith(Map<SObjectField, Object> value)` | `ATK.sObjectListWith(new Map<SObjectField, Object> {})` |
| `LIst<SObject> sObjectListWith(List<Map<SObjectField, Object>> value, Boolean inOrder)` | `ATK.sObjectListWith(new List<Map<SObjectField, Object>>{}` |

### Logical Matchers

```java
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

