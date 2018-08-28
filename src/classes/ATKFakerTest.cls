/**
 * Apex Test Kit
 */
@isTest
public with sharing class ATKFakerTest {
    /*
     * FAKER.FAKE() TESTS
     */
    @isTest
    static void testFakerFake() {
        for (Integer i = 0; i < 100; i++) {
            Object output = ATKFaker.fake('{!random.boolean}');
            System.assert(output instanceOf Boolean);
        }

        for (Integer i = 0; i < 100; i++) {
            Object output = ATKFaker.fake('{! \n random.boolean  \n }');
            System.assert(output instanceOf Boolean);
        }

        for (Integer i = 0; i < 100; i++) {
            Object output = ATKFaker.fake('{!random.boolean()  \n }');
            System.assert(output instanceOf Boolean);
        }

        for (Integer i = 0; i < 100; i++) {
            Object output = ATKFaker.fake('{!random.number}');
            System.assert(output instanceOf Decimal);
        }

        for (Integer i = 0; i < 100; i++) {
            Object output = ATKFaker.fake('{!random.number(0, 9, 0)}');
            System.assert(output instanceOf Decimal);
            Decimal digit = (Decimal)output;
            System.assert(0 <= digit && digit <= 9);
        }

        for (Integer i = 0; i < 100; i++) {
            Object output = ATKFaker.fake('{!random.number(0, 9, 0)}{!random.number(0, 9, 0)}');
            System.assert(output instanceOf String);
            System.assertEquals(2, ((String)output).length());
        }
    }

    @isTest
    static void testFakerFakeCoverage() {
        ATKFaker.fake('{!name.firstName} {!name.lastName}');
        ATKFaker.fake('{!random.number(9)} {!random.number(0, 9)}');

        for (Integer i = 0; i < 10; i++) {
            Object output = ATKFaker.fake('{{###-???-***}}');
            System.assertNotEquals(null, output);
        }

        for (Integer i = 0; i < 10; i++) {
            Object output = ATKFaker.fake('{!internet.email} {!internet.url}');
            System.assertNotEquals(null, output);
        }

        for (Integer i = 0; i < 10; i++) {
            Object output = ATKFaker.fake('{!dates.past} {!dates.future} {!dates.between(2018-1-1, 2018-12-31)}');
            System.assertNotEquals(null, output);
        }

        for (Integer i = 0; i < 10; i++) {
            Object output = ATKFaker.fake('{!phone.phoneNumber}');
            System.assertNotEquals(null, output);
        }

        for (Integer i = 0; i < 10; i++) {
            Object output = ATKFaker.fake('{!finance.amount}');
            System.assertNotEquals(null, output);
        }

        for (Integer i = 0; i < 10; i++) {
            Object output = ATKFaker.fake('{!random.arrayElement(1, 2, 3)}');
            System.assertNotEquals(null, output);
        }

        for (Integer i = 0; i < 10; i++) {
            Object output = ATKFaker.fake('{!lorem.word} {!lorem.words} {!lorem.sentence} {!lorem.sentences} '
                + '{!lorem.paragraph} {!lorem.paragraphs} {!lorem.lines} {!lorem.text}');
            System.assertNotEquals(null, output);
        }
    }

    /*
     * RANDOM HELPER TESTS
     */
    @isTest
    static void testRandomNumberMinMax() {
        Decimal value = ATKFaker.random.number(0, 0, 0);
        System.assertEquals(0, value);
        System.assertEquals(0, value.scale());
        System.assertEquals(1, value.precision());

        value = ATKFaker.random.number(0, 0, 2);
        System.assertEquals(0, value);
        System.assert(2 >= value.scale());
        System.assertEquals(1, value.precision());

        for (Integer i = 0; i < 100; i++) {
            value = ATKFaker.random.number(0, 9, 0);
            System.assertEquals(0, value.scale());
            System.assert(0 <= value && value <= 9, 'number(0, 9, 0)');
        }

        for (Integer i = 0; i < 100; i++) {
            value = ATKFaker.random.number(-9, 9, 0);
            System.assertEquals(0, value.scale());
            System.assert(-9 <= value && value <= 9, 'number(-9, 9, 0)');
        }


        for (Integer i = 0; i < 100; i++) {
            value = ATKFaker.random.number(0, 9, 2);
            System.assert(2 >= value.scale());
            System.assert(0 <= value && value <= 9, 'number(0, 9, 0)');
        }


        for (Integer i = 0; i < 100; i++) {
            value = ATKFaker.random.number(0, 8.4999, 2);
            System.debug(value);
            System.assert(2 >= value.scale());
            System.assert(0 <= value && value <= 8.4999, 'number(0, 8.4999, 2)');
        }
    }

    @isTest
    static void testRandomNumberMax() {
        Decimal value;
        for (Integer i = 0; i < 100; i++) {
            value = ATKFaker.random.number(9);
            System.assertEquals(0, value.scale());
            System.assert(0 <= value && value <= 9, 'number(9)');
        }

        for (Integer i = 0; i < 100; i++) {
            value = ATKFaker.random.number(9.99);
            System.assert(2 >= value.scale());
            System.assert(0 <= value && value <= 9.99, 'number(9.99)');
        }

        for (Integer i = 0; i < 100; i++) {
            value = ATKFaker.random.number(9.11);
            System.assert(2 >= value.scale());
            System.assert(0 <= value && value <= 9.11, 'number(9.11)');
        }
    }

	@isTest
    static void testRandomNumberPrecision() {
        Decimal value = ATKFaker.random.number(0, 0);
        System.assertEquals(0, value);
        System.assertEquals(0, value.scale());
        System.assertEquals(1, value.precision());

        for (Integer i = 0; i < 100; i++) {
            value = ATKFaker.random.number(1, 0);
            System.assertEquals(0, value.scale());
            System.assert(0 <= value.precision() && value.precision() <= 1, 'number(1, 0)');
        }

        for (Integer i = 0; i < 100; i++) {
            value = ATKFaker.random.number(2, 0);
            System.assertEquals(0, value.scale());
            System.assert(0 <= value.precision() && value.precision() <= 2, 'number(2, 0)');
        }

        for (Integer i = 0; i < 100; i++) {
            value = ATKFaker.random.number(1, 1);
            System.assert(1 >= value.scale(), 'number(1, 1)');
            System.assert(0 <= value.precision() && value.precision() <= 1, 'number(1, 1)');
        }

        for (Integer i = 0; i < 100; i++) {
            value = ATKFaker.random.number(2, 1);
            System.assert(1 >= value.scale(), 'number(2, 1)');
            System.assert(0 <= value.precision() && value.precision() <= 2, 'number(2, 1)');
        }
    }

    @isTest
    static void testRandomNumberWithBiggerPrecision() {
        for (Integer i = 0; i < 100; i++) {
            Decimal value = ATKFaker.random.number(18, 3);
            System.debug(value);
            System.assert(3 >= value.scale(), 'number(18, 3)');
            System.assert(18 >= value.precision(), 'number(18, 3)');
            System.assert(value.precision() - value.scale() <= 15, 'number exceed integral part');
        }
    }

    @isTest
    static void testRandomArrayElement() {
        List<Integer> integerList = new List<Integer> {
            1, 2, 3, 4, 5, 6, 7, 8, 9
        };

        for (Integer i = 0; i < 100; i++) {
            Integer integerValue = (Integer)ATKFaker.random.arrayElement(integerList);
            System.assert(integerList.contains(integerValue), 'arrayElement(integerList)');
        }

        List<String> stringList = new List<String> {
            'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i'
        };

        for (Integer i = 0; i < 100; i++) {
            String stringValue = (String)ATKFaker.random.arrayElement(stringList);
            System.assert(stringList.contains(stringValue), 'arrayElement(stringList)');
        }

        for (Integer i = 0; i < 100; i++) {
            List<Object> objList = ATKFaker.random.arrayElements(stringList);
            System.assert(0 < objList.size());
        }
    }

    /*
     * DATES HELPER TESTS
     */
    @isTest
    static void testDates() {
        Datetime now = Datetime.now();
        String iso = now.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
        System.debug(iso);

        for (Integer i = 0; i < 100; i++) {
            Datetime d = ATKFaker.dates.past(1, iso);
            System.assert(d <= now, 'dates.past');
        }

        for (Integer i = 0; i < 100; i++) {
            Datetime d = ATKFaker.dates.future(1, iso);
            System.assert(d >= now, 'dates.future');
        }

        Datetime past = ATKFaker.dates.past(1, iso);
        String pastIso = past.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
        Datetime future = ATKFaker.dates.future(1, iso);
        String futureIso = future.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');

        for (Integer i = 0; i < 100; i++) {
            Datetime d = ATKFaker.dates.between(pastIso, futureIso);
            System.debug(d);
            System.assert(d >= past, 'dates.between: d >= past');
            System.assert(d <= future, 'dates.between: d <= future');
        }
    }

    /*
     * NAME HELPER TESTS
     */
    @isTest
    static void testNameFirstName() {
        List<String> femaleFirstNameList = ATKFaker.definition.get(ATKFakerDefinition.FAKER_NAME_FEMALEFIRSTNAME);
        List<String> maleFirstNameList = ATKFaker.definition.get(ATKFakerDefinition.FAKER_NAME_MALEFIRSTNAME);
        List<String> firstNameList = ATKFaker.definition.get(ATKFakerDefinition.FAKER_NAME_FIRSTNAME);

        for (Integer i = 0; i < 100; i++) {
            String firstName = ATKFaker.name.firstName('female');
            System.debug(firstName);
            System.assert(femaleFirstNameList.contains(firstName), 'firstName(female)');
        }

        for (Integer i = 0; i < 100; i++) {
            String firstName = ATKFaker.name.firstName('male');
            System.assert(maleFirstNameList.contains(firstName), 'firstName(male)');
        }

        for (Integer i = 0; i < 100; i++) {
            String firstName = ATKFaker.name.firstName(null);
            System.assert(firstNameList.contains(firstName), 'firstName()');
        }
    }

    @isTest
    static void testNameLastName() {
        List<String> lastNameList = ATKFaker.definition.get(ATKFakerDefinition.FAKER_NAME_LASTNAME);

        for (Integer i = 0; i < 100; i++) {
            String lastName = ATKFaker.name.lastName();
            System.debug(lastName);
            System.assert(lastNameList.contains(lastName), 'lastName()');
        }
    }

    /*
     * LOREM HELPER TESTS
     */
    @isTest
    static void testLorem() {
        List<String> loremWordList = ATKFaker.definition.get(ATKFakerDefinition.FAKER_LOREM_WORDS);

        for (Integer i = 0; i < 100; i++) {
            String word = ATKFaker.lorem.word();
            System.assert(loremWordList.contains(word), 'word()');
        }

        for (Integer i = 0; i < 100; i++) {
            String words = ATKFaker.lorem.words(3);
            System.assertEquals(3, words.split(' ').size());
        }

        String sentence = ATKFaker.lorem.sentence();
        System.assert(sentence.endsWith('.'));

        String sentences = ATKFaker.lorem.sentences(3, ' ');
        System.debug(sentences);
        System.debug(sentences.split('. '));
        System.assertEquals(3, sentences.split('\\. ').size());

        String paragraphs = ATKFaker.lorem.paragraphs(3, '\n \r');
        System.assertEquals(3, paragraphs.split('\n \r').size());
        
        String lines = ATKFaker.lorem.lines(3);
        System.assertEquals(3, lines.split('\n').size());
    }

    /**
     * TEST JAPANESE
     */
    @isTest
    static void testJapanese() {
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User u = new User(
            Alias = 'standt', 
            Email = 'standarduser@testorg.com',
            EmailEncodingKey = 'UTF-8', 
            LastName = 'Testing', 
            LanguageLocaleKey = 'ja',
            LocaleSidKey = 'ja_JP', 
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com'
        );

        System.runAs(u) {
            for (Integer i = 0; i < 100; i++) {
                System.debug(ATKFaker.fake('{!name.lastName} {!name.firstName}'));
            }
            
        }
    }

    /*
     * ATKCommon Test Methods
     */
    class TestMethodEvaluator implements ATKCommon.MethodEvaluator {
        public Object evaluateMethod(ATKCommon.Method method) {
            return '===';
        }
    }

    @isTest
    static void testATKCommonMethodParser() {
        TestMethodEvaluator methodEvaluator = new TestMethodEvaluator();

        ATKCommon.MethodParser parser = new ATKCommon.MethodParser();
        ATKCommon.MethodGroup methodGroup = parser.parse('xxx{!helper.name(param0, param1)}xxx');
        System.assertEquals(2, methodGroup.splits.size());
        System.assertEquals('xxx', methodGroup.splits[0]);
        System.assertEquals('xxx', methodGroup.splits[1]);
        System.assertEquals(1, methodGroup.methodList.size());
        ATKCommon.Method method = methodGroup.methodList[0];
        System.assertEquals('helper', method.helperName);
        System.assertEquals('name', method.name);
        System.assertEquals(2, method.params.size());
        System.assertEquals('param0', method.params[0]);
        System.assertEquals('param1', method.params[1]);
        System.assertEquals('xxx===xxx', methodGroup.evaluate(methodEvaluator));

        methodGroup = parser.parse('xxx{!helper.name($1.a, $2.b)}xxx');
        System.assertEquals(1, methodGroup.level);
        System.assertEquals(2, methodGroup.splits.size());
        System.assertEquals('xxx', methodGroup.splits[0]);
        System.assertEquals('xxx', methodGroup.splits[1]);
        System.assertEquals(1, methodGroup.methodList.size());
        method = methodGroup.methodList[0];
        System.assert(method instanceof ATKCommon.XrefMethod);
        System.assertEquals('helper', method.helperName);
        System.assertEquals('name', method.name);
        System.assertEquals(2, method.params.size());
        System.assertEquals(null, method.params[0]);
        System.assertEquals(null, method.params[1]);
        ATKCommon.XrefMethod xrefMethod = (ATKCommon.XrefMethod)method;
        System.assertEquals(1, xrefMethod.level);
        System.assertEquals(2, xrefMethod.xrefParams.size());
        System.assertEquals(0, xrefMethod.xrefParams[0].index);
        System.assertEquals(1, xrefMethod.xrefParams[0].level);
        System.assertEquals('A', xrefMethod.xrefParams[0].fieldName);
        System.assertEquals(1, xrefMethod.xrefParams[1].index);
        System.assertEquals(2, xrefMethod.xrefParams[1].level);
        System.assertEquals('B', xrefMethod.xrefParams[1].fieldName);

        methodGroup = parser.parse('xxx{{###-###-####}}xxx');
        System.assertEquals(2, methodGroup.splits.size());
        System.assertEquals('xxx', methodGroup.splits[0]);
        System.assertEquals('xxx', methodGroup.splits[1]);
        System.assertEquals(1, methodGroup.methodList.size());
        method = methodGroup.methodList[0];
        System.assert(method instanceof ATKCommon.SymbolMethod);
        System.assertEquals('helper', method.helperName);
        System.assertEquals('replaceSymbols', method.name);
        System.assertEquals(1, method.params.size());
        System.assertEquals('###-###-####', method.params[0]);

        methodGroup = parser.parse('xxx---xxx');
        System.assertEquals(null, methodGroup.splits);
        System.assertEquals(null, methodGroup.methodList);
        System.assertEquals('xxx---xxx', methodGroup.evaluate(methodEvaluator));
    }

    @isTest
    static void testATKCommonConverter() {
        ATKCommon.Converter converter = new ATKCommon.Converter();
        System.assertEquals(null, converter.toInteger(null));
        System.assertEquals(null, converter.toInteger('abc'));
        System.assertEquals(123, converter.toInteger(123));
        System.assertEquals(123, converter.toInteger(123.00));
        System.assertEquals(123, converter.toInteger('123'));
        System.assertEquals(123, converter.toInteger('123.00'));

        System.assertEquals(null, converter.toDecimal(null));
        System.assertEquals(null, converter.toDecimal('abc'));
        System.assertEquals(123, converter.toDecimal(123));
        System.assertEquals(123, converter.toDecimal(123.00));
        System.assertEquals(123.45, converter.toDecimal(123.45));
        System.assertEquals(123, converter.toDecimal('123'));
        System.assertEquals(123, converter.toDecimal('123.00'));
        System.assertEquals(123.45, converter.toDecimal('123.45'));

        System.assertEquals(null, converter.toString(null));
        System.assertEquals('abc', converter.toString('abc'));
        System.assertEquals('123', converter.toString(123));

        System.assertEquals(null, converter.toDate(null));
        System.assertEquals(Date.today(), converter.toDate(Date.today()));
        System.assertEquals(Date.today(), converter.toDate(Datetime.now()));
        System.assertEquals(Date.newInstance(2018, 8, 28), converter.toDate('2018-8-28'));
        System.assertEquals(null, converter.toDate('2018-08-28T14:24:22Z'));
        System.assertEquals(null, converter.toDate('abc'));

        System.assertEquals(null, converter.toDatetime(null));
        Datetime now = Datetime.now();
        System.assertEquals(now, converter.toDatetime(now));
        System.assertEquals(Datetime.valueOfGmt('2018-08-28 14:24:22'), converter.toDatetime('2018-08-28T14:24:22Z'));
        System.assertEquals(Datetime.valueOfGmt('2018-08-28 14:24:22'), converter.toDatetime('2018-08-28T22:24:22+08:00'));
        System.assertEquals(null, converter.toDatetime('abc'));

        System.assertEquals(null, converter.toTime(null));
        System.assertEquals(Time.newInstance(8, 28, 36, 0), converter.toTime(Time.newInstance(8, 28, 36, 0)));
        System.assertEquals(Time.newInstance(8, 28, 36, 0), converter.toTime(Datetime.newInstance(2018, 8, 28, 8, 28, 36)));
        System.assertEquals(null, converter.toTime('2018-08-28T14:24:22Z'));
        System.assertEquals(null, converter.toTime('abc'));
    }
}
