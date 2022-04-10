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

## 1. Strictness

ATK begins with the most strict settings by default, and developers can use setting methods to gradually relax them. Each of the following setting methods can only work within its corresponding strictness.

| Strictness   | `stubbedVoids()` | `defaultAnswer()` | `stubOnly()`                                                 |
| ------------ | ---------------- | ----------------- | ------------------------------------------------------------ |
| Strict Mode  | ✓                |                   | ✓                                                            |
| Lenient Mode |                  | ✓                 | ✓                                                            |
|              |                  |                   | **When** step cannot track stub-only invocations<br />**Then** step cannot verify stub-only invocations |

### 1. 1 Strict Mode

Strict mode is the default strictness enforced for all mocking activities. It helps write clean mocking codes and increase productivity. In strict mode, ATK will:

1. Fail unstubbed method invocation immediately.
2. Mark stubbed method invocation as verified implicitly for the `haveNoMoreInteractions()` calls.
3. Detect unused stubs at the end of test with `haveNoUnusedStubs()` calls.

In strict mode, void methods can be treated as stubbed methods and automatically verified:

```java
// 1. global level
ATK.mock().withSettings().stubbedVoids();
// 2. mock level
ATK.mock(YourClass.class, ATK.withSettings().stubbedVoids());
```

### 1.2 Lenient Mode

In lenient mode, unstubbed methods will return default values, and they have to be explicitly verified for the `haveNoMoreInteractions()` calls. Use `lenient()` to enable lenient mode:

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
| Custom Answers         | Custom default answers can also be supplied to the `defaultAnswer()` method, please check [Answer Customization](#answer-customization) for detail. |

## 2. Mock Settings

As you have already seen, settings can be applied at three levels from high to low. Lower level settings will override the higher level settings:

```
+------------------------------+
|        +------------------+  |
|        |      +--------+  |  |
| global | mock |  stub  |  |  |
|        |      +--------|  |  |
|        +------------------+  |
+------------------------------+
```
| Mock API Name                                               | Example                                                    |
| ----------------------------------------------------------- | ---------------------------------------------------------- |
| `ATK.GlobalSettings ATK.mock()`                             | `ATK.mock().withSettings().lenient();`                     |
| `Object ATK.mock(Type mockType)`                            | `ATK.mock(YourClass.class);`                               |
| `Object ATK.mock(Type mockType, ATK.Answer defaultAnswer)`  | `ATK.mock(YourClass.class, ATK.RETURNS_DEFAULTS);`         |
| `Object ATK.mock(Type mockType, ATK.MockSettings settings)` | `ATK.mock(YourClass.class, ATK.withSettings().lenient());` |

### 2.1 Global  Level  Settings

Global settings are defined with `ATK.mock().withSettings()`.

```java
ATK.mock().withSettings()
    .stubbedVoids()                      // In strict mode, void methods are treated as stubbed methods and automatically verified.
    .lenient()                           // Enable lenient mode.
    .defaultAnswer(ATK.RETURNS_DEFAULTS) // Specify default answers for lenient mode.
    .stubOnly()                          // In either strict or lenient mode, any interactions can neither be tracked nor verified.
    .verbose();                          // For development/debug purpose to print verbose messages.
```

### 2.2 Mock Level Settings

```java
YourClass mock = (YourClass) ATK.mock(YourClass.class, ATK.withSettings()
    .name('mock')                        // This name is used in exception message, otherwise "[YourClass]" is used as instance name.
    .stubbedVoids()                      // In strict mode, void methods are treated as stubbed methods and automatically verified.
    .lenient()                           // Enable lenient mode.
    .defaultAnswer(ATK.RETURNS_DEFAULTS) // Specify default answers for lenient mode.
    .stubOnly()                          // In either strict or lenient mode, any interactions can neither be tracked nor verified.
    .verbose());                         // For development/debug purpose to print verbose messages.
```


### 2.3 Stub Level Settings

`ATK.lenient()` is the only stub level setting used to bypass the strict mode.

```java
ATK.lenient().given(mock.doWithInteger(1)).willReturn('one');
((YourClass) ATK.lenient().willReturn('one').given(mock)).doWithInteger(1);
```

## 3. Given Steps

### 3.1 Five Rules

Please consider the following five rules carefully before define stubs in the given steps.

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

### 3.2 Answers

Here are the APIs to define answers for the stubs in the give steps.

| API Name                        | Description                                                  |
| ------------------------------- | ------------------------------------------------------------ |
| `willReturn(Object value)`      | Return any value that compatible with the target method return type. |
| `willAnswer(ATK.Answer answer)` | Return a customized answer dynamically according to conditions such as arguments and return type. |
| `willThrow(Exception exp)`      | Throw the exception when target method is called.            |
| `willDoNothing()`               | Return `null`. Supposed to be called with void methods only. |

#### Answer Chaining

Answers can be chained for a particular stub, and their values will be returned one by one in the defining order for each interaction. If the answers are exhausted, `null` will be returned instead. Here is an example:

```java
YourClass mock = (YourClass) ATK.mock(YourClass.class);
ATK.startStubbing();
ATK.given(mock.doWithInteger(1)).willReturn('one').willReturn('another one');
ATK.stopStubbing();

System.assertEquals('one', mock.doWithInteger(1));
System.assertEquals('another one', mock.doWithInteger(1));
System.assertEquals(null, mock.doWithInteger(1));
```

#### Answer Customization

Customized answers can be supplied to both `defaultAnswer()` and `willAnswer()` methods.

```java
public class YourCustomAnswer implements ATK.Answer {
    public Object answer(ATK.Invocation invocation) {
        // ...
    }
}

ATK.mock(YourClass.class, ATK.withSettings().defaultAnswer(new YourCustomAnswer()));
ATK.given(mock.doWithInteger(1)).willAnswer(new YourCustomAnswer()); // mock is created elsewhere
```

| `ATK.Invocation` Properties | Description                                                  |
| --------------------------- | ------------------------------------------------------------ |
| `Object mock`               | The mock object.                                             |
| `Type mockType`             | The mock type.                                               |
| `ATK.Method method`         | The method metadata, also reference to `ATK.method` properties below. |
| `List<Object> arguments`    | The `Arguments` passed into the invocation.                  |

| `ATK.Method` Properties   | Description                 |
| ------------------------- | --------------------------- |
| `String name`             | The method name.            |
| `Type returnType`         | The method return type.     |
| `List<String> paramNames` | The method parameter names. |
| `List<Type> paramTypes`   | The method parameter types. |

## 4. Then Steps

This is the only flavor to declare then statements. And as the same as given statements, argument matchers can be used as well.

```java
((YourClass) ATK.then(mock).should().once()).doWithInteger(1);
((YourClass) ATK.then(mock).should().once()).doWithInteger(ATK.anyInteger());
```

### 4.1 Verification Mode

| API Name             | Alias To     | Description                                      |
| -------------------- | ------------ | ------------------------------------------------ |
| `never()`            | `times(0)`   | Verifies that interaction did not happen.        |
| `once()`             | `times(1)`   | Verifies that interaction happened exactly once. |
| `times(Integer n)`   |              | Allows verifying exact number of invocations.    |
| `atLeastOnce()`      | `atLeast(1)` | Allows at-least-once verification.               |
| `atLeast(Integer n)` |              | Allows at-least-n verification.                  |
| `atMostOnce()`       | `atMost(1)`  | Allows at-most-once verification.                |
| `atMost(Integer n)`  |              | Allows at-most-n verification.                   |

| API Name                   | Description                                                  | Example                                            |
| -------------------------- | ------------------------------------------------------------ | -------------------------------------------------- |
| `haveNoInteractions()`     | Fail if there are any interactions with the mock in when steps. | `ATK.then(mock).should().haveNoInteractions()`     |
| `haveNoMoreInteractions()` | Fail if there are any interactions unverified with the mock. | `ATK.then(mock).should().haveNoMoreInteractions()` |
| `haveNoUnusedStubs()`      | Fail if there are any unused/unmatched stubs in when steps.  | `ATK.then(mock).should().haveNoUnusedStubs()`      |

### 4.2 In-Order  Verification

```java
YourClass mock = (YourClass) ATK.mock(YourClass.class, ATK.withSettings().lenient());

mock.doWithInteger(1);
mock.doWithInteger(1);
mock.doWithInteger(2);
mock.doWithInteger(1);

ATK.InOrder inOrder = ATK.InOrder(mock);

((YourClass) ATK.then(mock).should(inOrder).times(2)).doWithInteger(1);
((YourClass) ATK.then(mock).should(inOrder).times(1)).doWithInteger(2);
((YourClass) ATK.then(mock).should(inOrder).times(1)).doWithInteger(1);

ATK.then(mock).should(inOrder).haveNoMoreInteractions();
```

Not all verification modes are supported by in-order verifications. Please stick to the following verification modes with `should(ATK.InOrder inOrder)`:

| API Name                   | Descriptions                                                 |
| -------------------------- | ------------------------------------------------------------ |
| `never()`                  | Verifies that interaction did not happen.                    |
| `once()`                   | Verifies that interaction happened exactly once.             |
| `times(Integer n)`         | Allows verifying exact number of invocations.                |
| `calls(Integer n)`         | Non-greedy verifications. Check Mockito wiki [Greedy Algorithm of Verification InOrder](https://github.com/mockito/mockito/wiki/Greedy-algorithm-of-verification-InOrder) for detail. |
| `haveNoMoreInteractions()` | In-order verifications are tracked in a different context, so even in strict mode, all interactions should be exhausted with verifications explicitly. |

### 4.3 Assert Messages

Here are sample assertion messages. The generated method signature could be different than the one defined in the test classes, such as all exact values will be replaced by `ATK.eq()` matchers. In future this is an area I will continuously improve, to help developers better understand the message contexts.

```
Expected "[ATKMockTest].doWithIntegers(ATK.eq(1))" to be called 1 time(s). But has been called 0 time(s).
Expected "[ATKMockTest].doWithIntegers(ATK.eq(1))" to be called at least 3 time(s). But has been called 0 time(s).
Expected "[ATKMockTest].doWithIntegers(ATK.eq(1))" to be called at most 3 time(s). But has been called 0 time(s).
```

## 5. Matchers

Please don't mix exact values and matchers in one given statement, either use exact values or matchers for all arguments.

```java
// Correct
ATK.given(mock.doWithIntegers(1, 2, 3)).willReturn('1, 2, 3');
ATK.given(mock.doWithIntegers(ATK.eqInteger(1), ATK.eqInteger(2), ATK.eqInteger(3)).willReturn('1, 2, 3');

// Wrong
ATK.given(mock.doWithIntegers(1, 2, ATK.eqInteger(3)).willReturn('1, 2, 3');
```

### 5.1 Type Matchers

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

### 5.2 Value Matchers

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

| API Name | Alias To | Description |
| ---- | ---- | ---- |
|`Object ne(Object value)`| | Object argument that is not equal to the given value. |
|`Integer neInteger(Integer value)`| `(Integer) ATK.ne(123)` | `Integer` argument that is not equal to the given value. |
|`Long neLong(Long value)`| `(Long) ATK.ne(123L)` | `Long` argument that is not equal to the given value. |
|`Double neDouble(Double value)`| `(Double) ATK.ne(123.0D)` | `Double` argument that is not equal to the given value. |
|`Decimal neDecimal(Decimal value)`| `(Decimal) ATK.ne(123.0)` | `Decimal` argument that is not equal to the given value. |
|`Date neDate(Date value)`| `(Date) ATK.ne(Date.today())` | `Date` argument that is not equal to the given value. |
|`Datetime neDatetime(Datetime value)`| `(Datetime) ATK.ne(Datetime.now())` | `Datetime` argument that is not equal to the given value. |
|`Time neTime(Datetime value)`| `(Time) ATK.ne(Time.newInstance(0, 0, 0, 0))` | `Time` argument that is not equal to the given value. |
|`Id neId(Id value)`| `(Id) ATK.ne(accountId)` | `Id` argument that is not equal to the given value. |
|`String neString(String value)`| `(String) ATK.ne('In Progress')` | `String` argument that is not equal to the given value. |
|`Boolean neBoolean(Boolean value)`| `(Boolean) ATK.ne(true)` | `Boolean` argument that is not equal to the given value. |

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
| `LIst<SObject> sObjectListWith(List<Map<SObjectField, Object>> value, Boolean inOrder)` | `ATK.sObjectListWith(new List<Map<SObjectField, Object>>{})` |

### 5.3 Logical Matchers

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

------

## Happy Hacking!
