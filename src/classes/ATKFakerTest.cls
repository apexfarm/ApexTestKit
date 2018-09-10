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

    /*
     * HELPER TESTS
     */
    @isTest
    static void testHelper() {
        for (Integer i = 0; i < 10; i++) {
            String output = (String)ATKFaker.fake('{!helper.replaceSymbols(###-???-***)}');
            System.assert(output.containsNone('#?*'));
            System.assert(output.contains('-'));
        }

        List<Integer> numberList = new List<Integer> { 1, 2, 3, 4, 5, 6, 7, 8, 9 };
        for (Integer i = 0; i < 10; i++) {
            Integer output = (Integer)ATKFaker.helper.randomize(numberList);
            System.assert(numberList.contains(output));
        }

        {
            String output;
            output = ATKFaker.helper.slugify(null);
            System.assertEquals('', output);
            output = ATKFaker.helper.slugify('Jeff-Jin');
            System.assertEquals('Jeff-Jin', output);
            output = ATKFaker.helper.slugify('Jeff Jin');
            System.assertEquals('Jeff-Jin', output);
            output = ATKFaker.helper.slugify('Jeff!@#$%^&  -  Jin');
            System.assertEquals('Jeff-Jin', output);
            output = ATKFaker.helper.slugify('Jeff!@#$%^& -  -  Jin');
            System.assertEquals('Jeff-Jin', output);
            output = ATKFaker.helper.slugify('Jeff!@#$%^& - @#$%@#$^ -  Jin');
            System.assertEquals('Jeff-Jin', output);
        }

        for (Integer i = 0; i < 10; i++) {
            String output = ATKFaker.helper.replaceSymbolsWithNumber('!!!###');
            System.assert(output.containsNone('!#'), 'replaceSymbolsWithNumber(!!!###)');
        }

        for (Integer i = 0; i < 10; i++) {
            String output = ATKFaker.helper.replaceSymbolsWithNumber('!!!&&&###', '&');
            System.assert(output.containsNone('!&'), 'replaceSymbolsWithNumber(!!!&&&###, &)');
            System.assert(output.endsWith('###'), 'replaceSymbolsWithNumber(!!!&&&###, &)');
        }

        for (Integer i = 0; i < 10; i++) {
            String output = ATKFaker.helper.replaceSymbols('###-???-***');
            System.assert(output.containsNone('#?*'));
            System.assert(output.contains('-'));
        }
    }

    /*
     * RANDOM HELPER TESTS
     */
    @isTest
    static void testRandomHelper() {
        for (Integer i = 0; i < 10; i++) {
            Object value = ATKFaker.fake(' {! random.boolean } ');
            System.assert(value instanceOf Boolean);
        }

        for (Integer i = 0; i < 10; i++) {
            String value = (String)ATKFaker.fake('{!random.number(9)}{!random.number(0, 9)}{!random.number(0, 9, 0)}');
            System.assertNotEquals(null, value);
            System.assertEquals(3, value.length());
        }

        {
            List<Object> letters = new List<Object> {'a', 'b', 'c', 'd', 'e', 'f'};
            for (Integer i = 0; i < 10; i++) {
                Object value = ATKFaker.fake('{!random.arrayElement(a, b, c, d, e, f)}');
                System.assert(letters.contains(value));
            }
        }

        {
            List<Object> letters = new List<Object> {'a', 'b', 'c', 'd', 'e', 'f'};
            for (Integer i = 0; i < 10; i++) {
                List<Object> value = (List<Object>)ATKFaker.fake('{!random.arrayElements(a, b, c, d, e, f)}');
                for (Object letter : value) {
                    System.assert(letters.contains(letter));
                }
            }
        }

    }

    @isTest
    static void testRandomHelperMinMax() {
        {
            Decimal value = ATKFaker.random.number(0, 0, 0);
            System.assertEquals(0, value);
            System.assertEquals(0, value.scale());
            System.assertEquals(1, value.precision());
        }

        {
            Decimal value = ATKFaker.random.number(0, 0, 2);
            System.assertEquals(0, value);
            System.assert(2 >= value.scale());
            System.assertEquals(1, value.precision());
        }

        for (Integer i = 0; i < 100; i++) {
            Decimal value = ATKFaker.random.number(0, 9, 0);
            System.assertEquals(0, value.scale());
            System.assert(0 <= value && value <= 9, 'number(0, 9, 0)');
        }

        for (Integer i = 0; i < 100; i++) {
            Decimal value = ATKFaker.random.number(-9, 0, 0);
            System.assertEquals(0, value.scale());
            System.assert(-9 <= value && value <= 0, 'number(-9, 0, 0)');
        }

        for (Integer i = 0; i < 100; i++) {
            Decimal value = ATKFaker.random.number(-9, 9, 0);
            System.assertEquals(0, value.scale());
            System.assert(-9 <= value && value <= 9, 'number(-9, 9, 0)');
        }


        for (Integer i = 0; i < 100; i++) {
            Decimal value = ATKFaker.random.number(0, 9, 2);
            System.assert(2 >= value.scale(), 'number(0, 9, 2)');
            System.assert(0 <= value && value <= 9, 'number(0, 9, 2)');
        }


        for (Integer i = 0; i < 100; i++) {
            Decimal value = ATKFaker.random.number(0, 8.4999, 2);
            System.assert(2 >= value.scale());
            System.assert(0 <= value && value <= 8.4999, 'number(0, 8.4999, 2)');
        }
    }

    @isTest
    static void testRandomHelperMax() {
        for (Integer i = 0; i < 100; i++) {
            Decimal value = ATKFaker.random.number();
            System.assertEquals(0, value.scale());
            System.assert(0 <= value && value <= 999, 'number()');
        }

        for (Integer i = 0; i < 100; i++) {
            Decimal value = ATKFaker.random.number(9);
            System.assertEquals(0, value.scale());
            System.assert(0 <= value && value <= 9, 'number(9)');
        }

        for (Integer i = 0; i < 100; i++) {
            Decimal value = ATKFaker.random.number(9.99);
            System.assert(2 >= value.scale());
            System.assert(0 <= value && value <= 9.99, 'number(9.99)');
        }

        for (Integer i = 0; i < 100; i++) {
            Decimal value = ATKFaker.random.number(9.11);
            System.assert(2 >= value.scale());
            System.assert(0 <= value && value <= 9.11, 'number(9.11)');
        }
    }

	@isTest
    static void testRandomHelperPrecision() {
        {
            Decimal value = ATKFaker.random.number(0, 0);
            System.assertEquals(0, value);
            System.assertEquals(0, value.scale());
            System.assertEquals(1, value.precision());
        }

        for (Integer i = 0; i < 100; i++) {
            Decimal value = ATKFaker.random.number(1, 0);
            System.assertEquals(0, value.scale());
            System.assert(0 <= value.precision() && value.precision() <= 1, 'number(1, 0)');
        }

        for (Integer i = 0; i < 100; i++) {
            Decimal value = ATKFaker.random.number(2, 0);
            System.assertEquals(0, value.scale());
            System.assert(0 <= value.precision() && value.precision() <= 2, 'number(2, 0)');
        }

        for (Integer i = 0; i < 100; i++) {
            Decimal value = ATKFaker.random.number(1, 1);
            System.assert(1 >= value.scale(), 'number(1, 1)');
            System.assert(0 <= value.precision() && value.precision() <= 1, 'number(1, 1)');
        }

        for (Integer i = 0; i < 100; i++) {
            Decimal value = ATKFaker.random.number(2, 1);
            System.assert(1 >= value.scale(), 'number(2, 1)');
            System.assert(0 <= value.precision() && value.precision() <= 2, 'number(2, 1)');
        }

        for (Integer i = 0; i < 100; i++) {
            Decimal value = ATKFaker.random.number(18, 3);
            System.assert(3 >= value.scale(), 'number(18, 3)');
            System.assert(18 >= value.precision(), 'number(18, 3)');
            System.assert(value.precision() - value.scale() <= 15, 'exceed integral part');
        }

        for (Integer i = 0; i < 100; i++) {
            Decimal value = (Decimal)ATKFaker.fake('{!random.number(18, 3)}');
            System.assert(3 >= value.scale(), 'number(18, 3)');
            System.assert(18 >= value.precision(), 'number(18, 3)');
            System.assert(value.precision() - value.scale() <= 15, 'exceed integral part');
        }
    }

    @isTest
    static void testRandomHelperArrayElement() {
        List<String> stringList = new List<String> {
            'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i'
        };

        {
            Object value = ATKFaker.random.arrayElement(null);
            System.assertEquals(null, value);
        }

        for (Integer i = 0; i < 100; i++) {
            String stringValue = (String)ATKFaker.random.arrayElement(stringList);
            System.assert(stringList.contains(stringValue), 'arrayElement(stringList)');
        }

        {
            List<Object> value = ATKFaker.random.arrayElements(null);
            System.assertEquals(0, value.size());
        }

        {
            List<Object> value = ATKFaker.random.arrayElements(stringList, 10);
            System.assertEquals(9, value.size());
        }

        {
            List<Object> value = ATKFaker.random.arrayElements(stringList, 0);
            System.assertEquals(0, value.size());
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
    static void testDatesHelperArithmetic() {
        Datetime now = Datetime.now();
        String nowIso = now.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');

        {
            DateTime d = (DateTime) ATKFaker.fake('{!dates.addDays(' + nowIso + ', 1)}');
            System.assertEquals(now.addDays(1), d);
            d = (DateTime) ATKFaker.dates.addDays(null, 1);
            System.assertEquals(null, d);
        }

        {
            DateTime d = (DateTime) ATKFaker.fake('{!dates.addHours(' + nowIso + ', 1)}');
            System.assertEquals(now.addHours(1), d);
            d = (DateTime) ATKFaker.dates.addHours(null, 1);
            System.assertEquals(null, d);
        }

        {
            DateTime d = (DateTime) ATKFaker.fake('{!dates.addMinutes(' + nowIso + ', 1)}');
            System.assertEquals(now.addMinutes(1), d);
            d = (DateTime) ATKFaker.dates.addMinutes(null, 1);
            System.assertEquals(null, d);
        }

        {
            DateTime d = (DateTime) ATKFaker.fake('{!dates.addMonths(' + nowIso + ', 1)}');
            System.assertEquals(now.addMonths(1), d);
            d = (DateTime) ATKFaker.dates.addMonths(null, 1);
            System.assertEquals(null, d);
        }

        {
            DateTime d = (DateTime) ATKFaker.fake('{!dates.addSeconds(' + nowIso + ', 1)}');
            System.assertEquals(now.addSeconds(1), d);
            d = (DateTime) ATKFaker.dates.addSeconds(null, 1);
            System.assertEquals(null, d);
        }

        {
            DateTime d = (DateTime) ATKFaker.fake('{!dates.addYears(' + nowIso + ', 1)}');
            System.assertEquals(now.addYears(1), d);
            d = (DateTime) ATKFaker.dates.addYears(null, 1);
            System.assertEquals(null, d);
        }
    }

    @isTest
    static void testDatesHelper() {
        Datetime now = Datetime.now();
        String nowIso = now.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
        Datetime past = ATKFaker.dates.past(1, nowIso);
        String pastIso = past.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
        Datetime future = ATKFaker.dates.future(1, nowIso);
        String futureIso = future.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');

        for (Integer i = 0; i < 100; i++) {
            DateTime d = (DateTime)ATKFaker.fake('{!dates.past}');
            System.assert(d < now);
        }

        for (Integer i = 0; i < 100; i++) {
            DateTime d = (DateTime)ATKFaker.fake('{!dates.future}');
            System.assert(d > now);
        }

        for (Integer i = 0; i < 100; i++) {
            DateTime d = (DateTime)ATKFaker.fake('{!dates.between(' + pastIso + ', ' + futureIso + ')}');
            System.assert(d >= past, 'dates.between: d >= past');
            System.assert(d <= future, 'dates.between: d <= future');
        }

        for (Integer i = 0; i < 100; i++) {
            Datetime d = ATKFaker.dates.past();
            System.assert(d <= now.addMinutes(5), 'dates.past');
        }

        for (Integer i = 0; i < 100; i++) {
            Datetime d = ATKFaker.dates.past(1, nowIso);
            System.assert(d <= now, 'dates.past');
        }

        for (Integer i = 0; i < 100; i++) {
            Datetime d = ATKFaker.dates.future();
            System.assert(d >= now, 'dates.future');
        }

        for (Integer i = 0; i < 100; i++) {
            Datetime d = ATKFaker.dates.future(1, nowIso);
            System.assert(d >= now, 'dates.future');
        }

        for (Integer i = 0; i < 100; i++) {
            Datetime d = ATKFaker.dates.between(pastIso, futureIso);
            System.assert(d >= past, 'dates.between: d >= past');
            System.assert(d <= future, 'dates.between: d <= future');
        }
    }

    /*
     * INTERNET HELPER TESTS
     */
    @isTest
    static void testInternetHelper() {
        for (Integer i = 0; i < 10; i++) {
            String output = (String)ATKFaker.fake('{!internet.userName(Jeff, Jin)}');
            System.assert(output.startsWith('Jeff'));
        }

        {
            String output = (String)ATKFaker.internet.userName();
            System.assertNotEquals(null, output);
        }

        for (Integer i = 0; i < 10; i++) {
            String output = (String)ATKFaker.fake('{!internet.userName(Je\' ff, Jin)}');
            System.assert(output.startsWith('Jeff'));
        }

        {
            String output = (String)ATKFaker.internet.email();
            System.assertNotEquals(null, output);
        }

        for (Integer i = 0; i < 10; i++) {
            String output = (String)ATKFaker.fake('{!internet.email(Je\' ff, Jin, sample.com)}');
            System.assert(output.startsWith('Jeff'));
            System.assert(output.endsWith('@sample.com'));
        }

        for (Integer i = 0; i < 10; i++) {
            String output = (String)ATKFaker.fake('{!internet.url}');
            System.assert(output.startsWith('http'));
        }

        for (Integer i = 0; i < 10; i++) {
            String output = (String)ATKFaker.fake('{!internet.avatar}');
            System.assert(output.startsWith('http'));
        }
    }

    /*
     * PHONE HELPER TESTS
     */
    @isTest
    static void testPhoneHelper() {
        {
            Object output = ATKFaker.phone.phoneNumber();
            System.assertNotEquals(null, output);
        }

        for (Integer i = 0; i < 10; i++) {
            Object output = ATKFaker.fake('{!phone.phoneNumber}');
            System.assertNotEquals(null, output);
        }

        for (Integer i = 0; i < 10; i++) {
            String output = (String)ATKFaker.fake('{!phone.phoneNumber(###-###-####)}');
            System.assertEquals(12, output.length());
            System.assertEquals(3, output.split('-').size());
        }
    }

    /*
     * NAME HELPER TESTS
     */
    @isTest
    static void testNameHelper() {
        List<String> femaleFirstNameList = ATKFaker.definition.get(ATKFakerDefinition.FAKER_NAME_FEMALEFIRSTNAME);
        List<String> maleFirstNameList = ATKFaker.definition.get(ATKFakerDefinition.FAKER_NAME_MALEFIRSTNAME);
        List<String> firstNameList = ATKFaker.definition.get(ATKFakerDefinition.FAKER_NAME_FIRSTNAME);
        List<String> lastNameList = ATKFaker.definition.get(ATKFakerDefinition.FAKER_NAME_LASTNAME);

        for (Integer i = 0; i < 100; i++) {
            String firstName = (String)ATKFaker.fake('{!name.firstName(female)}');
            System.assert(femaleFirstNameList.contains(firstName), 'firstName(female)');
        }

        for (Integer i = 0; i < 100; i++) {
            String firstName = ATKFaker.name.firstName('female');
            System.assert(femaleFirstNameList.contains(firstName), 'firstName(female)');
        }

        for (Integer i = 0; i < 100; i++) {
            String firstName = (String)ATKFaker.fake('{!name.firstName(male)}');
            System.assert(maleFirstNameList.contains(firstName), 'firstName(male)');
        }

        for (Integer i = 0; i < 100; i++) {
            String firstName = ATKFaker.name.firstName('male');
            System.assert(maleFirstNameList.contains(firstName), 'firstName(male)');
        }


        for (Integer i = 0; i < 100; i++) {
            String firstName = (String)ATKFaker.fake('{!name.firstName()}');
            System.assert(firstNameList.contains(firstName), 'firstName()');
        }

        for (Integer i = 0; i < 100; i++) {
            String firstName = ATKFaker.name.firstName(null);
            System.assert(firstNameList.contains(firstName), 'firstName()');
        }

        for (Integer i = 0; i < 100; i++) {
            String lastName = (String)ATKFaker.fake('{!name.lastName()}');
            System.assert(lastNameList.contains(lastName), 'lastName()');
        }

        for (Integer i = 0; i < 100; i++) {
            String lastName = ATKFaker.name.lastName();
            System.assert(lastNameList.contains(lastName), 'lastName()');
        }
    }

    /*
     * LOREM HELPER TESTS
     */
    @isTest
    static void testLorem() {
        List<String> loremWordList = ATKFaker.definition.get(ATKFakerDefinition.FAKER_LOREM_WORDS);

        for (Integer i = 0; i < 10; i++) {
            Object output = ATKFaker.fake('{!lorem.word} {!lorem.words} {!lorem.sentence} {!lorem.sentences} '
                + '{!lorem.paragraph} {!lorem.paragraphs} {!lorem.lines} {!lorem.text}');
            System.assertNotEquals(null, output);
        }

        for (Integer i = 0; i < 10; i++) {
            Object output = ATKFaker.fake('{!lorem.words(3)} {!lorem.sentence(3)} {!lorem.sentences(3, ;)} '
                + '{!lorem.paragraph(3)} {!lorem.paragraphs(3, ;)} {!lorem.lines(3)} {!lorem.text(3)}');
            System.assertNotEquals(null, output);
        }

        for (Integer i = 0; i < 10; i++) {
            String word = ATKFaker.lorem.word();
            System.assert(loremWordList.contains(word), 'word()');
        }

        for (Integer i = 0; i < 10; i++) {
            String words = ATKFaker.lorem.words();
            System.assertEquals(3, words.split(' ').size());
        }

        for (Integer i = 0; i < 10; i++) {
            String words = ATKFaker.lorem.words(3);
            System.assertEquals(3, words.split(' ').size());
        }

        String sentence = ATKFaker.lorem.sentence();
        System.assert(sentence.endsWith('.'));

        {
            String sentences = ATKFaker.lorem.sentences();
            System.assert(2 <= sentences.split('\\. ').size());
        }

        {
            String sentences = ATKFaker.lorem.sentences(3);
            System.assertEquals(3, sentences.split('\\. ').size());
        }

        {
            String sentences = ATKFaker.lorem.sentences(3, ' ');
            System.assertEquals(3, sentences.split('\\. ').size());
        }

        String paragraph = ATKFaker.lorem.paragraph();
        System.assert(3 <= paragraph.split('\\. ').size());

        {
            String paragraphs = ATKFaker.lorem.paragraphs();
            System.assertEquals(3, paragraphs.split('\n \r').size());
        }

        {
            String paragraphs = ATKFaker.lorem.paragraphs(3, '\n \r');
            System.assertEquals(3, paragraphs.split('\n \r').size());
        }

        {
            String lines = ATKFaker.lorem.lines(3);
            System.assertEquals(3, lines.split('\n').size());
        }

        {
            String lines = ATKFaker.lorem.lines();
            System.assert(1 <= lines.split('\n').size());
        }

        String text = ATKFaker.lorem.text();
        System.assertNotEquals(null, text);
    }

    /*
     * NUMBER HELPER TESTS
     */
    @isTest
    static void testNumberHelper() {
        System.assertEquals(2, ATKFaker.fake('{!numbers.add(1, 1)}'));
        System.assertEquals(2, ATKFaker.numbers.add(1, 1));
        System.assertEquals(2.1, ATKFaker.numbers.add(1.1, 1));
        System.assertEquals(null, ATKFaker.numbers.add(null, 1));
        System.assertEquals(1, ATKFaker.fake('{!numbers.subtract(2, 1)}'));
        System.assertEquals(1, ATKFaker.numbers.subtract(2, 1));
        System.assertEquals(0.1, ATKFaker.numbers.subtract(1.1, 1));
        System.assertEquals(null, ATKFaker.numbers.subtract(null, 1));
        System.assertEquals(2, ATKFaker.fake('{!numbers.divide(2, 1)}'));
        System.assertEquals(2, ATKFaker.numbers.divide(2, 1));
        System.assertEquals(1.1, ATKFaker.numbers.divide(11, 10));
        System.assertEquals(null, ATKFaker.numbers.divide(null, 10));
        System.assertEquals(2, ATKFaker.fake('{!numbers.multiply(2, 1)}'));
        System.assertEquals(2, ATKFaker.numbers.multiply(2, 1));
        System.assertEquals(11, ATKFaker.numbers.multiply(1.1, 10));
        System.assertEquals(null, ATKFaker.numbers.multiply(null, 10));
    }

    /*
     * FINANCE HELPER TESTS
     */
    @isTest
    static void testFinance() {
        for (Integer i = 0; i < 10; i++) {
            Object output = ATKFaker.fake('{!finance.amount}');
            System.assertNotEquals(null, output);
        }

        for (Integer i = 0; i < 10; i++) {
            Object output = ATKFaker.finance.amount();
            System.assertNotEquals(null, output);
        }

        for (Integer i = 0; i < 10; i++) {
            Decimal output = (Decimal)ATKFaker.fake('{!finance.amount(2, 0)}');
            System.assert(0 <= output && output < 100);
        }
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
     * ATKCommon String Builder
     */
    @isTest
    static void testATKCommon_StringBuilder() {
        {
            ATKCommon.StringBuilder builder = new ATKCommon.StringBuilder();
            for (Integer i = 0; i < 100; i++) {
                builder.append('a');
            }
            String s = builder.toString();
            System.assertEquals(100, s.length());
        }

        {
            ATKCommon.StringBuilder builder = new ATKCommon.StringBuilder();
            for (Integer i = 0; i < 100; i++) {
                ATKCommon.StringBuilder builder2 = new ATKCommon.StringBuilder();
                builder2.append(new List<String> {'a', 'b'});
                builder.append(builder2);
            }
            String s = builder.toString();
            System.assertEquals(200, s.length());
        }

        {
            ATKCommon.StringBuilder builder = new ATKCommon.StringBuilder();
            builder.append('abc');
            builder.append('def');
            String first = builder.getIndex(0);
            builder.setIndex(0, first.substring(1));
            builder.addIndex(0, 'A');
            builder.append('.');
            System.assertEquals('Abcdef.', builder.toString());
        }
    }

    /*
     * ATKCommon Test Methods
     */
    class TestMethodEvaluator implements ATKCommon.MethodEvaluator, ATKCommon.ParamEvaluator {
        public Object evaluateMethod(ATKCommon.Method method) {
            if (method instanceof ATKCommon.XrefMethod) {
                ATKCommon.XrefMethod xrefMethod = (ATKCommon.XrefMethod)method;
                xrefMethod.loadParams(this);
            }
            List<String> stringParams = new List<String>();
            for (Object param : method.params) {
                stringParams.add(String.valueOf(param));
            }
            return String.format('+{0}+{1}+', stringParams);
        }

        public Object evaluateParam(Integer prevIndex, String fieldName) {
            return fieldName;
        }
    }

    @isTest
    static void testATKCommon_MethodParser() {
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
        System.assertEquals('xxx+param0+param1+xxx', methodGroup.evaluate(methodEvaluator));

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
        System.assertEquals('xxx+A+B+xxx', methodGroup.evaluate(methodEvaluator));

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

        methodGroup = parser.parse('   {!helper.name($1.a, $2.b)}   ');
        methodGroup = parser.parse('   {!helper.name($1.a, $2.b)}   ');
        System.assertEquals(2, methodGroup.splits.size());
        System.assertEquals(1, methodGroup.methodList.size());
        System.assertEquals('+A+B+', methodGroup.evaluate(methodEvaluator));
    }

    @isTest
    static void testATKCommon_Converter() {
        ATKCommon.Converter converter = new ATKCommon.Converter();
        System.assertEquals(null, converter.toInteger(null));
        System.assertEquals(null, converter.toInteger('abc'));
        System.assertEquals(123, converter.toInteger(123));
        System.assertEquals(123, converter.toInteger(123.00));
        System.assertEquals(123, converter.toInteger('123'));
        System.assertEquals(123, converter.toInteger('123.00'));

        System.assertEquals(null, converter.toDecimal(Datetime.now()));
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
