/**
 * Apex Test Kit
 */
public with sharing class ATKCommon {
    public static final Integer METHOD_GROUP_MAX_LEVEL = 100;
    public static final Converter converter = new Converter();
    public static final MethodParser METHOD_PARSER = new MethodParser();

    /*
     * Custom Exceptions
     */
	public class DeepRecursionException extends Exception {

    }

    public class NotFoundException extends Exception {

    }

    public class InsufficientAttributeException extends Exception {

    }

    public class IncorrectTypeException extends Exception {

    }

    /*
     * Interpolation Method Parser
     */
    public interface IMethodEvaluator {
        Object evaluateMethod(ATKCommon.Method method);
    }

    public interface IParamEvaluator {
        Object evaluateParam(Integer level, String fieldName);
    }

    public class MethodParser {
        private Map<String, MethodGroup> methodCache = new Map<String, MethodGroup>();
        private Pattern methodPattern = Pattern.compile(
            '\\{![\\s]*([a-zA-Z_]*)\\.([a-zA-Z_]*)(\\(.*?\\))?[\\s]*\\}' +
            '|' +
            '\\{\\{[\\s]*((.*?))[\\s]*\\}\\}'
        );

        public MethodGroup parse(String expression) {
            MethodGroup methodGroup;
            if (methodCache.get(expression) != null) {
                methodGroup = methodCache.get(expression);
            } else {
                System.Matcher matcher = methodPattern.matcher(expression);
                methodGroup = new MethodGroup(expression, matcher);
                methodCache.put(expression, methodGroup);
            }
            return methodGroup;
        }
    }

    public class MethodGroup {
        public Integer level { get; private set; }
        public List<Method> methodList { get; private set; }
        public Boolean hasMethod { get; private set; }
        public Boolean hasXrefMethod { get; private set; }

        String expression { get; set; }
        @TestVisible
        List<String> splits { get; set; }
        Boolean isPure { get; set; } // a single pure expression without blank characters

        MethodGroup(String expression, System.Matcher matcher) {
            this.level = METHOD_GROUP_MAX_LEVEL;
            this.expression = expression;
            this.hasMethod = false;
            this.hasXrefMethod = false;
            this.splits = new List<String>();
            this.methodList = new List<Method>();

            Integer prevEnd = 0;
            while(matcher.find()) {
                addSplit(expression.substring(prevEnd, matcher.start()));
                addMethod(buildMethod(matcher));
                prevEnd = matcher.end();
            }
            if (this.hasMethod) {
                addSplit(expression.substring(prevEnd));
            }
            this.isPure = this.splits.size() == 2
                && String.isBlank(this.splits[0])
                && String.isBlank(this.splits[1]);
        }

        void addSplit(String split) {
            this.splits.add(split);
        }

        void addMethod(Method method) {
            this.methodList.add(method);
            this.hasMethod = true;

            if (method instanceof XrefMethod) {
                XrefMethod xrefMethod = (XrefMethod)method;
                this.hasXrefMethod = true;
                if (xrefMethod.level < this.level) {
                    this.level = xrefMethod.level;
                }
            }
        }

        public Object evaluate(IMethodEvaluator methodEvaluator) {
            if (!this.hasMethod) {
                return this.expression;
            }

            List<Object> evals = new List<Object>();
            for (Method method : this.methodList) {
                evals.add(methodEvaluator.evaluateMethod(method));
            }

            List<String> splits = this.splits;
            if (this.isPure) {
                return evals.get(0);
            }

            if (splits.size() == evals.size() + 1) {
                StringBuilder builder = new StringBuilder();
                builder.append(splits[0]);
                for (Integer i = 0; i < evals.size(); i++) {
                    String eval = converter.toString(evals[i]);
                    builder.append(eval == null ? '' : eval);
                    builder.append(splits[i+1]);
                }
                return builder.toString();
            }
            return this.expression;
        }
    }

    static Method buildMethod(System.Matcher matcher) {
        Method method;
        if (matcher.group(4) != null) {
            method = new SymbolMethod(matcher.group(4));
            return method;
        }

        List<XrefParam> xrefParams;
        List<Object> params;
        String paramText = matcher.group(3);
        if (paramText != null) {
            paramText = paramText.replaceAll('[\\(\\)\\s]', '');
            if (String.isNotEmpty(paramText)) {
                params = new List<Object>();
                List<String> paramSplits = paramText.split(',');
                for (Integer i = 0; i < paramSplits.size(); i++) {
                    String input = paramSplits[i];
                    if (input.startsWith('$')) {
                        if (xrefParams == null) {
                            xrefParams = new List<XrefParam>();
                        }
                        XrefParam param = new XrefParam();
                        param.index = i;
                        param.level = converter.toInteger(input.substring(1, 2));
                        param.fieldName = input.substring(3).toUpperCase();
                        xrefParams.add(param);
                        params.add(null);
                    } else {
                        params.add(input);
                    }
                }
            }
        }

        if (xrefParams != null) {
            method = new XrefMethod(xrefParams);
        } else {
            method = new Method();
        }

        method.helperName = matcher.group(1);
        method.name = matcher.group(2);
        method.params = params;

        // System.debug('helperName: ' + method.helperName);
        // System.debug('methodName: ' + method.name);
        // System.debug('params: ' + method.params);
        return method;
    }

    public virtual class Method {
        public String helperName { get; set; }
        public String name { get; set; }
        public List<Object> params { get; set; }
    }

    public class SymbolMethod extends Method {
        private SymbolMethod(String format) {
            helperName = 'helper';
            name = 'replaceSymbols';
            this.params = new List<Object> { format };
        }
    }

    public class XrefMethod extends Method {
        public List<XrefParam> xrefParams { get; set; }
        public Integer level {
            get;
            set {
                if (level == null || value < level) {
                    level = value;
                }
            }
        }

        XrefMethod(List<XrefParam> xrefParams) {
            this.xrefParams = xrefParams;
            for (XrefParam param : xrefParams) {
               this.level = param.level;
            }
        }

        public void loadParams(IParamEvaluator paramEvaluator) {
            if (xrefParams != null && paramEvaluator != null) {
                for (XrefParam param : xrefParams) {
                    params.set(param.index, paramEvaluator.evaluateParam(param.level, param.fieldName));
                }
            }
        }
    }

    public class XrefParam {
        @TestVisible
        Integer index { get; set; }
        @TestVisible
        public Integer level {
            get;
            private set {
                if (level == null || value < level) {
                    level = value;
                }
            }
        }
        public String fieldName { get; private set; }
    }

    /**
     * String Builder
     */
    public class StringBuilder {
        List<String> values { get; set; }

        public StringBuilder() {
            values = new List<String>();
        }

        public void addIndex(Integer index, String value) {
            values.add(index, value);
        }

        public void setIndex(Integer index, String value) {
            values.set(index, value);
        }

        public String getIndex(Integer index) {
            return values.get(index);
        }

        public void append(Decimal value) {
            values.add(converter.toString(value));
        }

        public void append(String value) {
            values.add(value);
        }

        public void append(List<String> values) {
            this.values.addAll(values);
        }

        public void append(StringBuilder builder) {
            values.addAll(builder.values);
        }

        public override String toString() {
            return String.join(values, '');
        }
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
