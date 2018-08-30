/**
 * Apex Test Kit
 */
global with sharing class ATKFaker {
    public static Map<String, IProvider> helperMap { get; set; }
    global static Internet internet { get; set; }
    global static Phone phone { get; set; }
    global static Name name { get; set; }
    global static Lorem lorem { get; set; }
    global static DateHelper dates { get; set; }
    global static Finance finance { get; set; }
    global static Random random { get; set; }
    global static Helper helper { get; set; }
    @TestVisible
    private static NumberArithmeticHelper numbers { get; set; }

    @TestVisible
    private static ATKFakerDefinition definition = new ATKFakerDefinition();
    public static final ATKCommon.MethodParser parser = ATKCommon.parser;
    private static final MethodEvaluator methodEvaluator = new MethodEvaluator();

    static {
        internet = new Internet();
        phone = new Phone();
        random = new Random();
        finance = new Finance();
        lorem = new Lorem();
        dates = new DateHelper();
        name = new Name();
        helper = new Helper();
        numbers = new NumberArithmeticHelper();

        helperMap = new Map<String, IProvider>();
        helperMap.put('internet', internet);
        helperMap.put('phone', phone);
        helperMap.put('random', random);
        helperMap.put('finance', finance);
        helperMap.put('lorem', lorem);
        helperMap.put('dates', dates);
        helperMap.put('name', name);
        helperMap.put('helper', helper);
        helperMap.put('numbers', numbers);
    }

    global static Object fake(String input) {
        ATKCommon.MethodGroup methodGroup = parser.parse(input);
        return methodGroup.evaluate(methodEvaluator);
    }

    public class MethodEvaluator implements ATKCommon.MethodEvaluator {
        public Object evaluateMethod(ATKCommon.Method method) {
            Object value;
            IProvider helper = helperMap.get(method.helperName);
            if (helper != null) {
                value = helper.call(method.name, method.params);
            }
            return value;
        }
    }

    /**
     * PROVIDERS
     */
    public interface IProvider {
        Object call(String method, List<Object> params);
    }

    public interface IDataProvider extends IProvider {

    }

    @TestVisible
    global class Helper implements IDataProvider {
        public Object call(String method, List<Object> params) {
            Object param0;
            Object param1;
            if (params != null) {
                if (params.size() > 0) {
                    param0 = params.get(0);
                }
                if (params.size() > 1) {
                    param1 = params.get(1);
                }              
            }
            Object output;
            switch on method {
                when 'replaceSymbols' {
                    output = replaceSymbols(ATKCommon.converter.toString(param0));
                }
                when else {
                    
                }
            }
            return output;
        }

        global Object randomize(List<Object> elements) {
            elements = elements == null ? new List<Object> { 'a', 'b', 'c' } : elements;
            return random.arrayElement(elements);
        }

        global String slugify(String input) {
            if (input == null) {
                input = '';
            }
            return input.replaceAll(' ', '-')
                .replaceAll('[^\\w\\.\\-]+', '')
                .replaceAll('--+', '-');
        }

        global String replaceSymbolsWithNumber(String input) {
            return replaceSymbolsWithNumber(input, null);
        }

        global String replaceSymbolsWithNumber(String input, String symbol) {
            input = input == null ? '' : input;
            symbol = symbol == null ? '#' : symbol;
            Integer numberSignChar = symbol.charAt(0);
            Integer exclamationChar = '!'.charAt(0);
            Integer[] chars = input.getChars();

            String output = '';
            for (Integer i = 0; i < chars.size(); i++) {
                if (chars[i] == numberSignChar) {
                    output += String.valueOf(random.number(0, 9, 0));
                } else if (chars[i] == exclamationChar) {
                    output += String.valueOf(random.number(2, 9, 0));
                } else {
                    output += String.fromCharArray(new Integer[]{chars[i]});
                }
            }
            return output;
        }

        global String replaceSymbols(String input) {
            input = input == null ? '' : input;
            Integer numberSignChar = '#'.charAt(0);
            Integer questionMarkChar = '?'.charAt(0);
            Integer asteriskChar = '*'.charAt(0);
            
            Integer[] chars = input.getChars();
            String output = '';
            List<String> alphaList = definition.get(ATKFakerDefinition.FAKER_SYMBOL_ALPHA);
            for (Integer i = 0; i < chars.size(); i++) {
                if (chars[i] == numberSignChar) {
                    output += random.number(0, 9, 0);
                } else if (chars[i] == questionMarkChar) {
                    output += (String)random.arrayElement(alphaList);
                } else if (chars[i] == asteriskChar) {
                    output += random.boolean() ? 
                        (String)random.arrayElement(alphaList) : 
                        String.valueOf(random.number(0, 9, 0));
                } else {
                    output += String.fromCharArray(new Integer[]{chars[i]});
                }
            }
            return output;
        }
    }

    global class Random implements IDataProvider {
        private Integer RANDOM_NUMBER_CACHE_SIZE = 569;
        private List<Double> randomNumberCache = new List<Double>();
        private Integer randomNumberIndex = 0;

        public Object call(String method, List<Object> params) {
            Object param0;
            Object param1;
            Object param2;
            if (params != null) {
                if (params.size() > 0) {
                    param0 = params.get(0);
                }
                if (params.size() > 1) {
                    param1 = params.get(1);
                }
                if (params.size() > 2) {
                    param2 = params.get(2);
                }
            }

            Object output;
            switch on method {
                when 'boolean' {
                    output = boolean();
                }
                when 'number' {
                    if (params != null) {
                        if (params.size() == 1) {
                            Decimal max = ATKCommon.converter.toDecimal(param0);
                            output = number(max);
                        } else if (params.size() == 2) {
                            Integer precision = ATKCommon.converter.toInteger(param0);
                            Integer scale = ATKCommon.converter.toInteger(param1);
                            output = number(precision, scale);
                        } else {
                            Decimal min = ATKCommon.converter.toDecimal(param0);
                            Decimal max = ATKCommon.converter.toDecimal(param1);
                            Integer scale = ATKCommon.converter.toInteger(param2);
                            output = number(min, max, scale);
                        }
                    }
                    else {
                        output = number(null, null, null);
                    }
                }
                when 'arrayElement' {
                    output = arrayElement(params);
                }
                when 'arrayElements' {
                    output = arrayElements(params, null);
                }
                when else {

                }
            }
            return output;
        }

        private Double random() {
            Double randomNumber;
            if (randomNumberCache.size() == RANDOM_NUMBER_CACHE_SIZE) {
                if (randomNumberIndex == RANDOM_NUMBER_CACHE_SIZE) {
                    randomNumberIndex = 0;
                }
                randomNumber = randomNumberCache[randomNumberIndex];
                ++randomNumberIndex;
            } else {
                randomNumber = Math.random();
                randomNumberCache.add(randomNumber);
            }
            return randomNumber;
        }

        global Boolean boolean() {
            return random() > 0.5;
        }

        global Decimal number() {
            return number(null, null, null);
        }

        global Decimal number(Decimal max) {
            return number(null, max, null);
        }

        global Decimal number(Integer precision, Integer scale) {
            scale = scale == null ? 0 : scale;
            precision = precision == null ? 3 + scale : precision;

            if (precision < scale || precision == 0) {
                return 0;
            }

            Double random = random();
            Integer integralPart = (Integer)Decimal.valueOf((random * (precision - scale))).round();
            Integer decimalPart = (scale == 0) ? 0 : (Integer)Decimal.valueOf(random() * scale).round();
            Integer newPrecision = integralPart + decimalPart;

            if (newPrecision < decimalPart || newPrecision == 0) {
                return 0;
            }

            Decimal value = Decimal.valueOf(
                ((Math.pow(10, newPrecision) -1) * random()).round()
            ).divide(Math.pow(10, decimalPart), decimalPart);

            // System.debug('precision(' + precision
            //     + '), scale(' + scale
            //     + '), random(' + random
            //     + '), integralPart(' + integralPart
            //     + '), decimalPart(' + decimalPart
            //     + '), Value(' + value
            //     + ')');
            return value;
        }

        global Decimal number(Decimal min, Decimal max, Integer scale) {
            min = min == null ? 0 : min;
            max = max == null ? 999 : max;
            scale = scale == null ? max.scale() : scale;

            Decimal delta = Decimal.valueOf(
                ((max - min) * random() * Math.pow(10, scale)).round(System.RoundingMode.DOWN)
            ).divide(Math.pow(10, scale), scale);
            return min + delta;
        }

        global Object arrayElement(List<Object> elements) {
            if (elements == null || elements.size() == 0) {
                return null;
            }

            Integer index = Integer.valueOf(number(0, elements.size() - 1, 0));
            return elements.get(index);
        }

        global List<Object> arrayElements(List<Object> elements) {
            return arrayElements(elements, null);
        }

        global List<Object> arrayElements(List<Object> elements, Integer count) {
            if (elements == null || elements.size() == 0) {
                return new List<Object>();
            }

            if (count == null) {
                count = Integer.valueOf(random.number(1, elements.size(), 0));
            } else if (count > elements.size()) {
                count = elements.size();
            } else if (count < 0) {
                count = 0;
            }

            List<Object> cloneElements = elements.clone();
            Integer countToRemove = cloneElements.size() - count;
            for (Integer i = 0; i < countToRemove; i++) {
                Integer indexToRemove = Integer.valueOf(random.number(cloneElements.size() - 1));
                cloneElements.remove(indexToRemove);
            }
            return cloneElements;
        }
    }

    global class DateHelper extends DateArithmeticHelper implements IDataProvider {
        public override Object call(String method, List<Object> params) {
            Object param0;
            Object param1;
            if (params != null) {
                if (params.size() > 0) {
                    param0 = params.get(0);
                }
                if (params.size() > 1) {
                    param1 = params.get(1);
                }
            }

            Object output;
            switch on method {
                when 'past' {
                    Integer years = ATKCommon.converter.toInteger(param0);
                    String dt = ATKCommon.converter.toString(param1);
                    output = past(years, dt);
                }
                when 'future' {
                    Integer years = ATKCommon.converter.toInteger(param0);
                    String dt = ATKCommon.converter.toString(param1);
                    output = future(years, dt);
                }
                when 'between' {
                    String dt1 = ATKCommon.converter.toString(param0);
                    String dt2 = ATKCommon.converter.toString(param1);
                    output = between(dt1, dt2);
                }
                when else {
                    output = super.call(method, params);
                }
            }
            return output;
        }

        global Datetime past() {
            return past(null, null);
        }

        global Datetime past(Integer years, String refDate) {
            Datetime d = ATKCommon.converter.toDatetime(refDate);
            d = d == null ? Datetime.now() : d;
            years = years == null ? 1 : years;
            return d.addSeconds(-Integer.valueOf(random.number(1, years * 365 * 24 * 3600, 0)));
        }

        global Datetime future() {
            return future(null, null);
        }

        global Datetime future(Integer years, String refDate) {
            Datetime d = ATKCommon.converter.toDatetime(refDate);
            d = d == null ? Datetime.now() : d;
            years = years == null ? 1 : years;
            return d.addSeconds(Integer.valueOf(random.number(1, years * 365 * 24 * 3600, 0)));
        }

        global Datetime between(String fo, String to) {
            Datetime fromDatetime = ATKCommon.converter.toDatetime(fo);
            Datetime toDatetime = ATKCommon.converter.toDatetime(to);
            Integer dateOffset = Integer.valueOf(random.number(toDatetime.getTime() - fromDatetime.getTime())/1000);
            return fromDatetime.addSeconds(dateOffset);
        }
    }

    global class Internet implements IDataProvider {
        public Object call(String method, List<Object> params) {
            Object param0;
            Object param1;
            Object param2;
            if (params != null) {
                if (params.size() > 0) {
                    param0 = params.get(0);
                }
                if (params.size() > 1) {
                    param1 = params.get(1);
                }
                if (params.size() > 2) {
                    param2 = params.get(2);
                }                
            }

            Object output;
            switch on method {
                when 'userName' {
                    output = userName(
                        ATKCommon.converter.toString(param0),
                        ATKCommon.converter.toString(param1)
                    );
                }
                when 'email' {
                    output = email(
                        ATKCommon.converter.toString(param0),
                        ATKCommon.converter.toString(param1),
                        ATKCommon.converter.toString(param2)
                    );
                }
                when 'url' {
                    output = url();
                }
                when 'avatar' {
                    output = avatar();
                }
                when else {
                    
                }
            }
            return output;
        }

        global String userName() {
            return userName(null, null);
        }

        global String userName(String firstName, String lastName) {
            String result;
            firstName = firstName == null ? name.firstName(null) : firstName;
            lastName = lastName == null ? name.lastName() : lastName;

            switch on Integer.valueOf(random.number(0, 2, 0)) {
                when 0 {
                    result = firstName + random.number(99, 999, 0);
                }
                when 1 {
                    result = firstName 
                        + (String)random.arrayElement(definition.get(ATKFakerDefinition.FAKER_INTERNET_USERNAME_PUNCTUATION))
                        + lastName;
                }
                when 2 {
                    result = firstName 
                        + (String)random.arrayElement(definition.get(ATKFakerDefinition.FAKER_INTERNET_USERNAME_PUNCTUATION))
                        + lastName
                        + random.number(99, 999, 0);
                }
            }
            result = result.replaceAll('\'', '');
            result = result.replaceAll(' ', '');
            return result;
        }

        global String email() {
            return email(null, null, null);
        }

        global String email(String firstName, String lastName, String provider) {
            List<String> providerList = definition.get(ATKFakerDefinition.FAKER_INTERNET_FREEEMAIL);
            provider = provider == null ? (String)random.arrayElement(providerList) : provider;
        	return helper.slugify(internet.userName(firstName, lastName)) + '@' + provider;
        }

        global String url() {
        	return protocol() + '://' + domainName();
        }

        global String avatar() {
            return (String)random.arrayElement(definition.get(ATKFakerDefinition.FAKER_INTERNET_AVATARURI));
        }

        private String protocol() {
            List<String> protocolList = new List<String> { 'http', 'https' };
            return (String)random.arrayElement(protocolList);
        }

        private String domainName() {
            return domainWord() + '.' + domainSuffix();
        }

        private String domainWord() {
            return name.firstName().replaceAll('[\\~#&*{}/:<>?|\\\"\']', '').toLowerCase();
        }

        private String domainSuffix() {
            List<String> domainSuffixList = definition.get(ATKFakerDefinition.FAKER_INTERNET_DOMAINSUFFIX);
            return (String)random.arrayElement(domainSuffixList);
        }
    }

    global class Phone implements IDataProvider {
        public Object call(String method, List<Object> params) {
            Object param0;
            if (params != null) {
                if (params.size() > 0) {
                    param0 = params.get(0);
                }
            }

            Object output;
            switch on method {
                when 'phoneNumber' {
                    output = phoneNumber(
                        ATKCommon.converter.toString(param0)
                    );
                }
                when else {
                    
                }
            }
            return output;
        }

        global String phoneNumber() {
            return phoneNumber(null);
        }

        global String phoneNumber(String format) {
            format = format == null ? phoneFormat() : format;
        	return helper.replaceSymbolsWithNumber(format);
        }

        private String phoneFormat() {
            List<String> formats = definition.get(ATKFakerDefinition.FAKER_PHONE_FORMATS);
            return (String)random.arrayElement(formats);
        }
    }

    global class Name implements IDataProvider {
        public Object call(String method, List<Object> params) {
            Object param0;
            if (params != null) {
                if (params.size() > 0) {
                    param0 = params.get(0);
                }
            }

            Object output;
            switch on method {
                when 'firstName' {
                    output = firstName(
                        ATKCommon.converter.toString(param0)
                    );
                }
                when 'lastName' {
                    output = lastName();
                }
                when else {
                    
                }
            }
            return output;
        }

        global String firstName() {
            return firstName(null);
        }

        global String firstName(String gender) {
            list<String> nameList;
            if (gender == 'female' || gender == 'Female' || gender == 'FEMALE') {
                nameList = definition.get(ATKFakerDefinition.FAKER_NAME_FEMALEFIRSTNAME);
            } else if (gender == 'male' || gender == 'Male' || gender == 'MALE') {
                nameList = definition.get(ATKFakerDefinition.FAKER_NAME_MALEFIRSTNAME);
            }
            
            if (nameList == null) {
                nameList = definition.get(ATKFakerDefinition.FAKER_NAME_FIRSTNAME);
            }
            return (String)random.arrayElement(nameList);
        }

        global String lastName() {
            return (String)random.arrayElement(definition.get(ATKFakerDefinition.FAKER_NAME_LASTNAME));
        }
    }

    global class Finance implements IDataProvider {
        public Object call(String method, List<Object> params) {
            Object param0;
            Object param1;
            if (params != null) {
                if (params.size() > 0) {
                    param0 = params.get(0);
                }
                if (params.size() > 1) {
                    param1 = params.get(1);
                }
            }

            Object output;
            switch on method {
                when 'amount' {
                    Integer precision = ATKCommon.converter.toInteger(param0);
                    Integer scale = ATKCommon.converter.toInteger(param1);
                    output = amount(precision, scale);
                }
                when else {
                    
                }
            }
            return output;
        }

        global Decimal amount() {
            return amount(null, null);
        }

        global Decimal amount(Integer precision, Integer scale) {
        	return random.number(precision, scale);
        }
    }

    global class Lorem implements IDataProvider {
        public Object call(String method, List<Object> params) {
            Object param0;
            Object param1;
            if (params != null) {
                if (params.size() > 0) {
                    param0 = params.get(0);
                }
                if (params.size() > 1) {
                    param1 = params.get(1);
                }
            }

            Object output;
            Integer count = ATKCommon.converter.toInteger(param0);
            String separator = ATKCommon.converter.toString(param1);
            switch on method {
                when 'word' {
                    output = word();
                }
                when 'words' {
                    output = words(count);
                }
                when 'sentence' {
                    output = sentence(count);
                }
                when 'sentences' {
                    output = sentences(count, separator);
                }
                when 'paragraph' {
                    output = paragraph(count);
                }
                when 'paragraphs' {
                    output = paragraphs(count, separator);
                }
                when 'lines' {
                    output = words(count);
                }
                when 'text' {
                    output = words(count);
                }
                when else {
                    
                }
            }
            return output;
        }

        global String word() {
            List<String> words = definition.get(ATKFakerDefinition.FAKER_LOREM_WORDS);
        	return (String)random.arrayElement(words);
        }

        global String words() {
            return words(null);
        }

        global String words(Integer count) {
            count = count == null ? 3 : count;
            String output = '';
            for (Integer i = 0; i < count; ) {
                output += word();
                i++;
                if (i != count) {
                    output += ' ';
                }
            }
        	return output;
        }

        global String sentence() {
            return sentence(null);
        }

        global String sentence(Integer count) {
            count = count == null ? Integer.valueOf(random.number(3, 10, 0)) : count;
            String sentence = words(count);
            return String.format('{0}{1}.', new List<String>{
                sentence.substring(0, 1).toUpperCase(),
                sentence.substring(1)
            });
        }

        global String sentences() {
            return sentences(null, null);
        }

        global String sentences(Integer count) {
            return sentences(count, null);
        }

        global String sentences(Integer count, String separator) {
            count = count == null ? Integer.valueOf(random.number(2, 6, 0)) : count;
            separator = separator == null ? ' ' : separator;

            String output = '';
            for (Integer i = 0; i < count;) {
                output += sentence();
                i++;
                if (i != count) {
                    output += separator;
                }
            }
            return output;
        }

        global String paragraph() {
            return paragraph(null);
        }

        global String paragraph(Integer count) {
            count = count == null? 3 : count;
            return sentences(count + Integer.valueOf(random.number(0, 3, 2)), null);
        }

        global String paragraphs() {
            return paragraphs(null, null);
        }

        global String paragraphs(Integer count, String separator) {
            separator = separator == null ? '\n \r' : separator;
            count = count == null ? 3 : count;

            String output = '';
            for (Integer i = 0; i < count;) {
                output += paragraph();
                i++;
                if (i != count) {
                    output += separator;
                }
            }
            return output;
        }

        global String lines() {
            return lines(null);
        }

        global String lines(Integer count) {
            count = count == null ? Integer.valueOf(random.number(1, 5, 0)) : count;
            return sentences(count, '\n');
        }

        global String text() {
            List<String> methodList = new List<String> {
                'word', 'words', 
                'sentence', 'sentences',
                'paragraph', 'paragraphs', 
                'lines'};
            String method = (String)random.arrayElement(methodList);
            return (String)call(method, null);
        }
    }

    global class Address implements IDataProvider {
        public Object call(String method, List<Object> params) {
            Object output;
            switch on method {
                when 'city' {
                }
                when else {
                    
                }
            }
            return output;
        }
    }

    /*
     * Arithmetic Provider
     */
    public interface IArithmeticProvider extends IProvider {

    }

    @TestVisible
    private virtual class NumberArithmeticHelper implements IArithmeticProvider {
        public virtual Object call(String method, List<Object> params) {
            Object param0;
            Object param1;
            if (params != null) {
                if (params.size() > 0) {
                    param0 = params.get(0);
                }
                if (params.size() > 1) {
                    param1 = params.get(1);
                }
            }

            Object output;
            Decimal a = ATKCommon.converter.toDecimal(param0);
            Decimal b = ATKCommon.converter.toDecimal(param1);
            switch on method {
                when 'add' {
                    output = add(a, b);
                }
                when 'subtract' {
                    output = subtract(a, b);
                }
                when 'divide' {
                    output = divide(a, b);
                }
                when 'multiply' {
                    output = multiply(a, b);
                }
                when else {

                }
            }
            return output;
        }

        @TestVisible
        private Decimal add(Decimal a, Decimal b) {
            if (a == null || b == null) {
                return null;
            }
            return a + b;
        }

        @TestVisible
        private Decimal subtract(Decimal a, Decimal b) {
            if (a == null || b == null) {
                return null;
            }
            return a - b;
        }

        @TestVisible
        private Decimal divide(Decimal a, Decimal b) {
            if (a == null || b == null) {
                return null;
            }
            return a / b;
        }

        @TestVisible
        private Decimal multiply(Decimal a, Decimal b) {
            if (a == null || b == null) {
                return null;
            }
            return a * b;
        }
    }

    private virtual class DateArithmeticHelper implements IArithmeticProvider {
        public virtual Object call(String method, List<Object> params) {
            Object param0;
            Object param1;
            if (params != null) {
                if (params.size() > 0) {
                    param0 = params.get(0);
                }
                if (params.size() > 1) {
                    param1 = params.get(1);
                }
            }

            Object output;
            Datetime dt = ATKCommon.converter.toDatetime(param0);
            Integer add = ATKCommon.converter.toInteger(param1);
            switch on method {
                when 'addDays' {
                    output = addDays(dt, add);
                }
                when 'addHours' {
                    output = addHours(dt, add);
                }
                when 'addMinutes' {
                    output = addMinutes(dt, add);
                }
                when 'addMonths' {
                    output = addMonths(dt, add);
                }
                when 'addSeconds' {
                    output = addSeconds(dt, add);
                }
                when 'addYears' {
                    output = addYears(dt, add);
                }
                when else {

                }
            }
            return output;
        }

        @TestVisible
        private Datetime addDays(Datetime dt, Integer additionalDays) {
            if (dt == null) {
                return null;
            }
            return dt.addDays(additionalDays);
        }

        @TestVisible
        private Datetime addHours(Datetime dt, Integer additionalHours) {
            if (dt == null) {
                return null;
            }
            return dt.addHours(additionalHours);
        }

        @TestVisible
        private Datetime addMinutes(Datetime dt, Integer additionalMinutes) {
            if (dt == null) {
                return null;
            }
            return dt.addMinutes(additionalMinutes);
        }

        @TestVisible
        private Datetime addMonths(Datetime dt, Integer additionalMonths) {
            if (dt == null) {
                return null;
            }
            return dt.addMonths(additionalMonths);
        }

        @TestVisible
        private Datetime addSeconds(Datetime dt, Integer additionalSeconds) {
            if (dt == null) {
                return null;
            }
            return dt.addSeconds(additionalSeconds);
        }

        @TestVisible
        private Datetime addYears(Datetime dt, Integer additionalYears) {
            if (dt == null) {
                return null;
            }
            return dt.addYears(additionalYears);
        }
    }
}
