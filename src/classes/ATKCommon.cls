/**
 * Apex Test Kit
 */
global with sharing class ATKCommon {
    public static final Integer METHOD_GROUP_MAX_LEVEL  = 100;
    public static final Converter converter = new Converter();
    public static final MethodParser parser = new MethodParser();

    /*
     * Custom Exceptions
     */
	global class DeepRecursionException extends Exception {

    }
    
    global class NotFoundException extends Exception {

    }

    global class InsufficientAttributeException extends Exception {

    }

    global class IncorrectTypeException extends Exception {

    }

    /*
     * Interpolation Method Parser
     */
    public interface MethodEvaluator {
        Object evaluate(ATKCommon.Method method);
    }

    public interface ParamEvaluator {
        Object evaluate(ATKCommon.Param param);
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
                    methodGroup.addMethod(method);
                    methodGroup.addSplit(input.substring(prevEnd, matcher.start()));
                    prevEnd = matcher.end();
                    remaining = input.substring(prevEnd);
                }
                methodGroup.addSplit(remaining);
            }
            return methodGroup;
        }

        private Method buildMethod(System.Matcher matcher) {
            Method method = new Method();
            method.format = matcher.group(4);
            method.helperName = matcher.group(1);
            method.name = matcher.group(2);
            
            String paramText = matcher.group(3);
            if (paramText != null) {
                paramText = paramText.replaceAll('[\\(\\)\\s]', '');
                if (String.isNotEmpty(paramText)) {
                    List<String> params = paramText.split(',');
                    for (Integer i = 0; i < params.size(); i++) {
                        String param = params[i];
                        method.addParam(param, i);
                    }
                }
            }

            System.debug('format: ' + method.format);
            System.debug('helperName: ' + method.helperName);
            System.debug('methodName: ' + method.name);
            System.debug('params: ' + method.params);
            System.debug('xrefParams: ' + method.xrefParams);
            return method;
        }
    }

    public class MethodGroup {
        public Integer level { get; set; }
        public List<Method> methodList { get; set; }
        List<String> splits { get; set; }
        String input { get; set; }

        private Boolean hasMethod {
            get {
                return methodList.size() > 0;
            }
        }

        MethodGroup() {
            methodList = new List<Method>();
            splits = new List<String>();
        }

        void addSplit(String split) {
            this.splits.add(split);
        }

        void addMethod(Method method) {
            this.methodList.add(method);
            if (method.level < level) {
                level = method.level;
            }
        }

        public Object evaluate(MethodEvaluator methodEvaluator) {
            if (!this.hasMethod) {
                return this.input;
            }

            List<Object> evals = new List<Object>();
            for (Method method : this.methodList) {
                evals.add(methodEvaluator.evaluate(method));
            }

            List<String> splits = this.splits;
            if (splits.size() == 2 && String.isBlank(splits[0]) && String.isBlank(splits[1])) {
                return evals.get(0);
            }

            if (splits.size() == evals.size() + 1) {
                String output = splits[0];
                for (Integer i = 0; i < evals.size(); i++) {
                    String eval = converter.toString(evals[i]);
                    output += (eval == null ? '' : eval);
                    output += splits[i+1];
                }
                return output;
            }
            return this.input;
        }
    }

    public class Method {
        public Integer level { get; set; }
        public String format { get; set; }
        public String helperName { get; set; }
        public String name { get; set; }
        public List<Object> params { get; set; }

        public List<Param> xrefParams { get; set; }
        public Boolean isXref {
            get {
                return xrefParams.size() > 0;
            }
        }

        public Method() {
            this.params = new List<Object>();
            this.xrefParams = new List<Param>();
            level = METHOD_GROUP_MAX_LEVEL;
        }

        public void loadParams(ParamEvaluator paramEvaluator) {
            if (isXref && paramEvaluator != null) {
                for (Param param : xrefParams) {
                    params.set(param.index, paramEvaluator.evaluate(param));
                }
            }
        }

        void addParam(String input, Integer at) {
            if (input.startsWith('$')) {
                Param param = new Param();
                param.index = at;
                param.xrefLevel = converter.toInteger(input.substring(1, 2));
                param.xrefField = input.substring(3).toUpperCase();
                xrefParams.add(param);
                params.add(null);
                if (param.xrefLevel < level) {
                    level = param.xrefLevel;
                }
            } else {
                params.add(input);
            }
        }
    }

    public class Param {
        Object value { get; set; }
        Integer index { get; set; }
        public Integer xrefLevel { get; set; }
        public String xrefField { get; set; }
    }

    /**
     * Converter
     */
    public class Converter {
        public Integer toInteger(Object input) {
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

        public Decimal toDecimal(Object input) {
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

        public String toString(Object input) {
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

        public Date toDate(Object input) {
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

        public Datetime toDatetime(Object input) {
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

        public Time toTime(Object input) {
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
}
