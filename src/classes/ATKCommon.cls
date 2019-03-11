/**
 * Apex Test Kit
 */
public with sharing class ATKCommon {
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
     * Provider Interfaces
     */
    public interface IProvider {
        Object call(String method, List<Object> params);
    }

    public interface IDataProvider extends IProvider {

    }

    public interface IArithmeticProvider extends IProvider {

    }

    /*
     * Interpolation Method Parser
     */
    public interface IMethodEvaluator {
        Object evaluate(Map<String, IProvider> helpers);
    }

    public interface IParamEvaluator {
        Object evaluateParam(String fieldName, Integer recordIndex, Integer level);
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

    public class MethodGroup implements IMethodEvaluator {
        String expression { get; set; }
        public Boolean hasMethod { get; private set; }
        public List<Method> methodList { get; private set; }
        @TestVisible
        List<String> splits { get; set; }
        Boolean isPure { get; set; } // a single pure expression without blank characters

        MethodGroup(String expression, System.Matcher matcher) {
            this.expression = expression;
            this.hasMethod = false;
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
        }

        Method buildMethod(System.Matcher matcher) {
            Method method;
            if (matcher.group(4) != null) {
                method = new SymbolMethod(matcher.group(4));
                return method;
            }

            List<Object> params;
            String paramText = matcher.group(3);
            if (paramText != null) {
                paramText = paramText.replaceAll('[\\(\\)\\s]', '');
                if (String.isNotEmpty(paramText)) {
                    params = paramText.split(',');
                }
            }

            method = new Method();
            method.helperName = matcher.group(1);
            method.name = matcher.group(2);
            method.params = params;

            // System.debug('helperName: ' + method.helperName);
            // System.debug('methodName: ' + method.name);
            // System.debug('params: ' + method.params);
            return method;
        }

        public Object evaluate(Map<String, IProvider> helpers) {
            if (!this.hasMethod) {
                return this.expression;
            }

            List<Object> evals = new List<Object>();
            for (Method method : this.methodList) {
                evals.add(method.evaluate(helpers));
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
            return null;
        }
    }

    public virtual class Method implements IMethodEvaluator {
        public String helperName { get; set; }
        public String name { get; set; }
        public List<Object> params { get; set; }

        public virtual Object evaluate(Map<String, IProvider> helpers) {
            IProvider helper = helpers.get(helperName);
            if (helper != null) {
                return helper.call(name, params);
            } else {
                return null;
            }
        }
    }

    public class SymbolMethod extends Method {
        SymbolMethod(String format) {
            helperName = 'helper';
            name = 'replaceSymbols';
            this.params = new List<Object> { format };
        }
    }

    public class XrefMethod extends Method {
        public IParamEvaluator paramEvaluator { get; set; }
        public List<XrefParam> xrefParams { get; private set; }
        public Integer level {
            get;
            set {
                if (level == null || value < level) {
                    level = value;
                }
            }
        }

        public XrefMethod(List<XrefParam> xrefParams) {
            this.xrefParams = xrefParams;
            for (XrefParam param : xrefParams) {
               this.level = param.level;
            }
        }

        public void loadParams(Integer recordIndex) {
            if (xrefParams != null && paramEvaluator != null) {
                for (XrefParam param : xrefParams) {
                    params.set(param.index, paramEvaluator.evaluateParam(param.fieldName, recordIndex, param.level));
                }
            }
        }

        public Object evaluate(Map<String, IProvider> helpers, Integer recordIndex) {
            IProvider helper = helpers.get(helperName);
            if (helper == null) {
                return null;
            }
            loadParams(recordIndex);
            return helper.call(name, params);
        }
    }

    public class XrefParam {
        public Integer index { get; set; }
        public Integer level {
            get;
            set {
                if (level == null || value < level) {
                    level = value;
                }
            }
        }
        public String fieldName { get; set; }

        public XrefParam(String fieldName, Integer index, Integer level) {
            this.fieldName = fieldName;
            this.index = index;
            this.level = level;
        }
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
                return ((Datetime)input).dateGMT();
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
