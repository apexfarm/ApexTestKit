@IsTest
private with sharing class ATKCommonTest {
    @isTest
    static void testStringBuilder() {
        {
            ATKCommon.StringBuilder builder = new ATKCommon.StringBuilder();
            for (Integer i = 0; i < 10; i++) {
                if (Math.mod(i, 2) == 0) {
                    builder.append('a');
                } else {
                    builder.append(1);
                }
            }
            String s = builder.toString();
            System.assertEquals(10, s.length());
            System.assertEquals('a1a1a1a1a1', s);
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

    @isTest
    static void testConverter() {
        ATKCommon.Converter CONVERTER = new ATKCommon.Converter();
        System.assertEquals(null, CONVERTER.toInteger(null));
        System.assertEquals(null, CONVERTER.toInteger('abc'));
        System.assertEquals(123, CONVERTER.toInteger(123));
        System.assertEquals(123, CONVERTER.toInteger(123.00));
        System.assertEquals(123, CONVERTER.toInteger('123'));
        System.assertEquals(123, CONVERTER.toInteger('123.00'));

        System.assertEquals(null, CONVERTER.toDecimal(Datetime.now()));
        System.assertEquals(null, CONVERTER.toDecimal(null));
        System.assertEquals(null, CONVERTER.toDecimal('abc'));
        System.assertEquals(123, CONVERTER.toDecimal(123));
        System.assertEquals(123, CONVERTER.toDecimal(123.00));
        System.assertEquals(123.45, CONVERTER.toDecimal(123.45));
        System.assertEquals(123, CONVERTER.toDecimal('123'));
        System.assertEquals(123, CONVERTER.toDecimal('123.00'));
        System.assertEquals(123.45, CONVERTER.toDecimal('123.45'));

        System.assertEquals(null, CONVERTER.toString(null));
        System.assertEquals('abc', CONVERTER.toString('abc'));
        System.assertEquals('123', CONVERTER.toString(123));

        System.assertEquals(null, CONVERTER.toDate(null));
        System.assertEquals(Date.today(), CONVERTER.toDate(Date.today()));
        System.assertEquals(Date.today(), CONVERTER.toDate(Datetime.now()));
        System.assertEquals(Date.newInstance(2018, 8, 28), CONVERTER.toDate('2018-8-28'));
        System.assertEquals(null, CONVERTER.toDate('2018-08-28T14:24:22Z'));
        System.assertEquals(null, CONVERTER.toDate('abc'));

        System.assertEquals(null, CONVERTER.toDatetime(null));
        Datetime now = Datetime.now();
        System.assertEquals(now, CONVERTER.toDatetime(now));
        System.assertEquals(Datetime.valueOfGmt('2018-08-28 14:24:22'), CONVERTER.toDatetime('2018-08-28T14:24:22Z'));
        System.assertEquals(Datetime.valueOfGmt('2018-08-28 14:24:22'), CONVERTER.toDatetime('2018-08-28T22:24:22+08:00'));
        System.assertEquals(null, CONVERTER.toDatetime('abc'));

        System.assertEquals(null, CONVERTER.toTime(null));
        System.assertEquals(Time.newInstance(8, 28, 36, 0), CONVERTER.toTime(Time.newInstance(8, 28, 36, 0)));
        System.assertEquals(Time.newInstance(8, 28, 36, 0), CONVERTER.toTime(Datetime.newInstance(2018, 8, 28, 8, 28, 36)));
        System.assertEquals(null, CONVERTER.toTime('2018-08-28T14:24:22Z'));
        System.assertEquals(null, CONVERTER.toTime('abc'));
    }
}
