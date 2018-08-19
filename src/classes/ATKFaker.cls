/**
 * Apex Test Kit
 */
global with sharing class ATKFaker {
    global static Map<String, IProvider> helperMap { get; set; }
    global static Internet internet { get; set; }
    global static Phone phone { get; set; }
    global static Name name { get; set; }
    global static Lorem lorem { get; set; }
    global static DateHelper dates { get; set; }
    global static Finance finance { get; set; }
    global static Random random { get; set; }
    global static Helper helper { get; set; }

    private static MethodParser parser = new MethodParser();
    @TestVisible
    private static ATKFakerDefinition definition = new ATKFakerDefinition();

    static {
        internet = new Internet();
        phone = new Phone();
        random = new Random();
        finance = new Finance();
        lorem = new Lorem();
        dates = new DateHelper();
        name = new Name();
        helper = new Helper();

        helperMap = new Map<String, IProvider>();
        helperMap.put('internet', internet);
        helperMap.put('phone', phone);
        helperMap.put('random', random);
        helperMap.put('finance', finance);
        helperMap.put('lorem', lorem);
        helperMap.put('dates', dates);
        helperMap.put('name', name);
        helperMap.put('helper', helper);
    }

    public static Object fake(MethodGroup methodGroup) {
        List<Object> evals = new List<Object>();
        for (Method method : methodGroup.methodList) {
            evals.add(evaluate(method));
        }

        List<String> splits = methodGroup.splits;
        if (splits.size() == 2 && String.isBlank(splits[0]) && String.isBlank(splits[1])) {
            return evals.get(0);
        }

        if (splits.size() == evals.size() + 1) {
            String output = splits[0];
            for (Integer i = 0; i < evals.size(); i++) {
                String eval = helper.toString(evals[i]);                                       
                output += (eval == null ? '' : eval);
                output += splits[i+1];
            }
            return output;
        }

        return methodGroup.input;
    }

    global static Object fake(String input) {
        MethodGroup methodGroup = parser.parse(input);
        return fake(methodGroup);
    }

    private static Object evaluate(Method method) {
        Object value;
        if (method.format != null) {
            value = helper.replaceSymbols(method.format);
        } else {
            IProvider helper = helperMap.get(method.helperName);
            if (helper != null) {
                value = helper.call(method.name, method.params);
            }
        }
        return value;
    }

    /**
     * Interpolation Method Parser
     */
    public class MethodGroup {
        public List<Method> methodList { get; set; }
        List<String> splits { get; set; }
        String input { get; set; }

        MethodGroup() {
            methodList = new List<Method>();
            splits = new List<String>();
        }
    }

    public class Method {
        String format { get; set; }
        String helperName { get; set; }
        String name { get; set; }
        List<String> params { get; set; }
    }

    public class MethodParser {
        private Map<String, MethodGroup> methodCache = new Map<String, MethodGroup>();
        private Pattern methodPattern = Pattern.compile(
            '\\{![\\s]*([a-zA-Z_]*)\\.([a-zA-Z_]*)(\\(.*?\\))?[\\s]*\\}' +
            '|' +
            '\\{\\{[\\s]*((.*?))[\\s]*\\}\\}'
        );

        public MethodGroup parse(String input) {
            MethodGroup methodGroup;
            if (methodCache.get(input) != null) {
                methodGroup = methodCache.get(input);
            } else {
                methodGroup = new MethodGroup();
                methodGroup.input = input;
                methodCache.put(input, methodGroup);
                
                System.Matcher matcher = methodPattern.matcher(input);
                String remaining = input;
                Integer prevEnd = 0;
                while(matcher.find()) {
                    Method method = buildMethod(matcher);
                    methodGroup.splits.add(input.substring(prevEnd, matcher.start()));
                    prevEnd = matcher.end();
                    remaining = input.substring(prevEnd);
                    methodGroup.methodList.add(method);
                }
                methodGroup.splits.add(remaining);
            }
            return methodGroup;
        }

        private Method buildMethod(System.Matcher matcher) {
            String format = matcher.group(4);
            String helperName = matcher.group(1);
            String methodName = matcher.group(2);
            
            List<String> params;
            String paramText = matcher.group(3);
            if (paramText != null) {
                paramText = paramText.replaceAll('[\\(\\)\\s]', '');
                params = paramText.split(',');
            }

            Method method = new Method();
            method.format = format;
            method.helperName = helperName;
            method.name = methodName;
            method.params = params;
            // System.debug('format: ' +format);
            // System.debug('helperName: ' + helperName);
            // System.debug('methodName: ' + methodName);
            // System.debug('params: ' + params);
            return method;
        }
    }

    private interface IProvider {
        Object call(String method, List<String> params);
    }

    /*
     * HELPER PROVIDER
     */
    global class Helper implements IProvider {
        global Object call(String method, List<String> params) {
            String param0;
            String param1;
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
                    output = replaceSymbols(param0);
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
                .replaceAll('----', '-')
                .replaceAll('---', '-')
                .replaceAll('--', '-');
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

        global Integer toInteger(Object input) {
            if (input == null) {
                return null;
            } else if (input instanceof Integer) {
                return (Integer)input;
            } else {
                try {
                    return Integer.valueOf(input);
                } catch (Exception e) {}
                return null;
            }
        }

        global Decimal toDecimal(Object input) {
            if (input == null) {
                return null;
            } else if (input instanceof Decimal) {
                return (Decimal)input;
            } else {
                try {
                    String inputString;
                    if (input instanceOf String) {
                        inputString = (String)input;
                    } else {
                        inputString = String.valueOf(input);
                    }
                    return Decimal.valueOf(inputString);
                } catch (Exception e) {}
                return null;
            }
        }

        global String toString(Object input) {
            if (input == null) {
                return null;
            } else if (input instanceof String) {
                return (String)input;
            } else {
                try {
                    return String.valueOf(input);
                } catch (Exception e) {}
                return null;
            }
        }

        global Date toDate(Object input) {
            if (input == null) {
                return null;
            } else if (input instanceof Date) {
                return (Date)input;
            } else if (input instanceof Datetime){
                return ((Datetime)input).date();
            } else if (input instanceof String) {
                try {
                    return (Date)JSON.deserialize(
                        String.format('"{0}"', new List<String> { (String)input }),
                        Date.class);
                } catch (Exception e) {}
            }
            return null;
        }

        global Datetime toDatetime(Object input) {
            if (input == null) {
                return null;
            } else if (input instanceof Datetime) {
                return (Datetime)input;
            } else if (input instanceof String) {
                try {
                    return (Datetime)JSON.deserialize(
                        String.format('"{0}"', new List<String> { (String)input }),
                        Datetime.class);
                } catch (Exception e) {}
            }
            return null;
        }

        global Time toTime(Object input) {
            if (input == null) {
                return null;
            } else if (input instanceof Time) {
                return (Time)input;
            } else if (input instanceof Datetime){
                return ((Datetime)input).time();
            }
            return null;
        }
    }

    /*
     * RANDOM PROVIDER
     */
    global class Random implements IProvider {
        private Integer RANDOM_NUMBER_CACHE_SIZE = 569;
        private List<Double> randomNumberCache = new List<Double>();
        private Integer randomNumberIndex = 0;

        global Object call(String method, List<String> params) {
            String param0;
            String param1;
            String param2;
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
                            Decimal max = helper.toDecimal(param0);
                            output = number(max);
                        } else if (params.size() == 2) {
                            Integer precision = helper.toInteger(param0);
                            Integer scale = helper.toInteger(param1);
                            output = number(precision, scale);
                        } else {
                            Decimal min = helper.toDecimal(param0);
                            Decimal max = helper.toDecimal(param1);
                            Integer scale = helper.toInteger(param2);
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

    /*
     * INTERNET PROVIDER
     */
    global class Internet implements IProvider {
        global Object call(String method, List<String> params) {
            String param0;
            String param1;
            String param2;
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
                    output = userName(param0, param1);
                }
                when 'email' {
                    output = email(param0, param1, param2);
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

    /*
     * PHONE NUMBER
     */
    global class Phone implements IProvider {
        global Object call(String method, List<String> params) {
            String param0;
            if (params != null) {
                if (params.size() > 0) {
                    param0 = params.get(0);
                }
            }

            Object output;
            switch on method {
                when 'phoneNumber' {
                    output = phoneNumber(param0);
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

    /*
     * NAME PROVIDER
     */
    global class Name implements IProvider {
        global Object call(String method, List<String> params) {
            String param0;
            if (params != null) {
                if (params.size() > 0) {
                    param0 = params.get(0);
                }
            }

            Object output;
            switch on method {
                when 'firstName' {
                    output = firstName(param0);
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

    global class Finance implements IProvider {
        global Object call(String method, List<String> params) {
            String param0;
            String param1;
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
                    Integer precision = helper.toInteger(param0);
                    Integer scale = helper.toInteger(param1);
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

    /*
     * LOREM PROVIDER
     */
    global class Lorem implements IProvider {
        global Object call(String method, List<String> params) {
            String param0;
            String param1;
            String param2;
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
                when 'word' {
                    output = word();
                }
                when 'words' {
                    Integer count = helper.toInteger(param0);
                    output = words(count);
                }
                when 'sentence' {
                    Integer count = helper.toInteger(param0);
                    output = sentence(count);
                }
                when 'sentences' {
                    Integer count = helper.toInteger(param0);
                    output = sentences(count, param1);
                }
                when 'paragraph' {
                    Integer count = helper.toInteger(param0);
                    output = paragraph(count);
                }
                when 'paragraphs' {
                    Integer count = helper.toInteger(param0);
                    output = paragraphs(count, param1);
                }
                when 'lines' {
                    Integer count = helper.toInteger(param0);
                    output = words(count);
                }
                when 'text' {
                    Integer count = helper.toInteger(param0);
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

        global String sentences(Integer count, String seperator) {
            count = count == null ? Integer.valueOf(random.number(2, 6, 0)) : count;
            seperator = seperator == null ? ' ' : seperator;

            String output = '';
            for (Integer i = 0; i < count;) {
                output += sentence();
                i++;
                if (i != count) {
                    output += seperator;
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

        global String paragraphs(Integer count, String seperator) {
            seperator = seperator == null ? '\n \r' : seperator;
            count = count == null ? 3 : count;

            String output = '';
            for (Integer i = 0; i < count;) {
                output += paragraph();
                i++;
                if (i != count) {
                    output += seperator;
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

    /*
     * DATEHELPER
     */
    global class DateHelper implements IProvider {
        global Object call(String method, List<String> params) {
            String param0;
            String param1;
            String param2;
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
                    Integer years = helper.toInteger(param0);
                    output = past(years, param1);
                }
                when 'future' {
                    Integer years = helper.toInteger(param0);
                    output = future(years, param1);
                }
                when 'between' {
                    output = between(param0, param1);
                }
                when 'addDays' {
                    Datetime dt = helper.toDatetime(param0);
                    Integer days = helper.toInteger(param1);
                    output = addDays(dt, days);
                }
                when 'addHours' {
                    Datetime dt = helper.toDatetime(param0);
                    Integer hours = helper.toInteger(param1);
                    output = addHours(dt, hours);
                }
                when 'addMinutes' {
                    Datetime dt = helper.toDatetime(param0);
                    Integer minutes = helper.toInteger(param1);
                    output = addMinutes(dt, minutes);
                }
                when 'addMonths' {
                    Datetime dt = helper.toDatetime(param0);
                    Integer months = helper.toInteger(param1);
                    output = addMonths(dt, months);
                }
                when 'addSeconds' {
                    Datetime dt = helper.toDatetime(param0);
                    Integer seconds = helper.toInteger(param1);
                    output = addSeconds(dt, seconds);
                }
                when 'addYears' {
                    Datetime dt = helper.toDatetime(param0);
                    Integer years = helper.toInteger(param1);
                    output = addYears(dt, years);
                }
                when else {
                    
                }
            }
            return output;
        }

        private Datetime addDays(Datetime dt, Integer additionalDays) {
            return dt.addDays(additionalDays);
        }

        private Datetime addHours(Datetime dt, Integer additionalHours) {
            return dt.addHours(additionalHours);
        }

        private Datetime addMinutes(Datetime dt, Integer additionalMinutes) {
            return dt.addMinutes(additionalMinutes);
        }

        private Datetime addMonths(Datetime dt, Integer additionalMonths) {
            return dt.addMonths(additionalMonths);
        }

        private Datetime addSeconds(Datetime dt, Integer additionalSeconds) {
            return dt.addSeconds(additionalSeconds);
        }

        private Datetime addYears(Datetime dt, Integer additionalYears) {
            return dt.addYears(additionalYears);
        }

        global Datetime past() {
            return past(null, null);
        }

        global Datetime past(Integer years, String refDate) {
            Datetime d = helper.toDatetime(refDate);
            d = d == null ? Datetime.now() : d;
            years = years == null ? 1 : years;
            return d.addSeconds(-Integer.valueOf(random.number(1, years * 365 * 24 * 3600, 0)));
        }

        global Datetime future() {
            return future(null, null);
        }

        global Datetime future(Integer years, String refDate) {
            Datetime d = helper.toDatetime(refDate);
            d = d == null ? Datetime.now() : d;
            years = years == null ? 1 : years;
            return d.addSeconds(Integer.valueOf(random.number(1, years * 365 * 24 * 3600, 0)));
        }

        global Datetime between(String fo, String to) {
            Datetime fromDatetime = helper.toDatetime(fo);
            Datetime toDatetime = helper.toDatetime(to);
            Integer dateOffset = Integer.valueOf(random.number(toDatetime.getTime() - fromDatetime.getTime())/1000);
            return fromDatetime.addSeconds(dateOffset);
        }
    }

    /*
     * ADDRESS PROVIDER
     */
    global class Address implements IProvider {
        global Object call(String method, List<String> params) {
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
}
