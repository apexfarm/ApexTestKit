public with sharing class ATKReflect {
    private static final String METHOD_PATTERN = 
        '\\{![\\s]*([a-zA-Z_]*)\\.([a-zA-Z_]*)(\\(.*?\\))?[\\s]*\\}' +
        '|' +
        '\\{\\{[\\s]*((.*?))[\\s]*\\}\\}';

    public static final IMethodParser METHOD_PARSER = new MethodParser();
    public static final IMethodBuilder METHOD_BUILDER = new MethodBuilder();

    public interface IMethodBuilder {
        IMethodEval buildEval(String helperName, String methodName, List<Object> params);
        IMethodXref buildXref(String helperName, String methodName, List<Object> params);
    }
    
    public interface IMethodParser {
        IMethodEval parse(String expression);
    }

    public interface IMethodEval {
        Object evaluate(Map<String, IValueProvider> helpers);
    }

    public interface IMethodXref extends IMethodEval {
        Integer level();
        List<XrefParam> xrefParams();
        void loadParams(IParamEvaluator paramEvaluator);
    }

    public interface IParamEvaluator {
        Object evaluateParam(String fieldName, Integer level);
    }

    public interface IValueProvider {
        Object call(String method, List<Object> params);
    }

    @TestVisible
    private class MethodBuilder implements IMethodBuilder {
        public IMethodEval buildEval(String helperName, String methodName, List<Object> params) {
            Method method = new Method();
            method.helperName = helperName;
            method.name = methodName;
            method.params = params;
            return method;
        }

        public IMethodXref buildXref(String helperName, String methodName, List<Object> params) {
            List<XrefParam> xrefParams = new List<XrefParam>();
            List<Object> newParams = new List<Object>();
            for (Integer i = 0; i < params.size(); i++) {
                Object param = params[i];
                if (param instanceOf String) {
                    String input = (String)param;
                    if (input.startsWith('$')) {
                        String fieldName = input.substring(3).toUpperCase();
                        Integer level = ATKCommon.CONVERTER.toInteger(input.substring(1, 2));
                        XrefParam xrefParam = new XrefParam(fieldName, i, level);

                        xrefParams.add(xrefParam);
                        newParams.add(null);
                    } else {
                        newParams.add(param);
                    }
                } else {
                    newParams.add(param);
                }
            }

            XrefMethod method = new XrefMethod(xrefParams);
            method.helperName = helperName;
            method.name = methodName;
            method.params = newParams;
            return method;
        }
    }

    @TestVisible
    private class MethodParser implements IMethodParser {
        private Map<String, IMethodEval> methodCache = new Map<String, IMethodEval>();
        private Pattern methodPattern = Pattern.compile(METHOD_PATTERN);

        public IMethodEval parse(String expression) {
            IMethodEval methodGroup;
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

    @TestVisible
    private class MethodGroup implements IMethodEval {
        String expression { get; set; }
        public Boolean hasMethod { get; private set; }
        public List<IMethodEval> methodList { get; private set; }
        @TestVisible
        List<String> splits { get; set; }
        Boolean isPure { get; set; } // a single pure expression without blank characters

        MethodGroup(String expression, System.Matcher matcher) {
            this.expression = expression;
            this.hasMethod = false;
            this.splits = new List<String>();
            this.methodList = new List<IMethodEval>();

            Integer prevEnd = 0;
            while(matcher.find()) {
                this.splits.add(expression.substring(prevEnd, matcher.start()));
                this.methodList.add(buildMethod(matcher));
                this.hasMethod = true;
                prevEnd = matcher.end();
            }
            if (this.hasMethod) {
                this.splits.add(expression.substring(prevEnd));
            }
            this.isPure = this.splits.size() == 2
                && String.isBlank(this.splits[0])
                && String.isBlank(this.splits[1]);
        }

        IMethodEval buildMethod(System.Matcher matcher) {
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

        public Object evaluate(Map<String, IValueProvider> helpers) {
            if (!this.hasMethod) {
                return this.expression;
            }

            List<Object> evals = new List<Object>();
            for (IMethodEval method : this.methodList) {
                evals.add(method.evaluate(helpers));
            }

            if (this.isPure) {
                return evals.get(0);
            }

            List<String> splits = this.splits;
            if (splits.size() == evals.size() + 1) {
                ATKCommon.StringBuilder builder = new ATKCommon.StringBuilder();
                builder.append(splits[0]);
                for (Integer i = 0; i < evals.size(); i++) {
                    String eval = ATKCommon.CONVERTER.toString(evals[i]);
                    builder.append(eval == null ? '' : eval);
                    builder.append(splits[i+1]);
                }
                return builder.toString();
            }
            return null;
        }
    }

    @TestVisible
    private virtual class Method implements IMethodEval {
        public String helperName { get; set; }
        public String name { get; set; }
        public List<Object> params { get; set; }

        public virtual Object evaluate(Map<String, IValueProvider> helpers) {
            IValueProvider helper = helpers.get(helperName);
            if (helper != null) {
                return helper.call(name, params);
            }
            return null;
        }
    }

    @TestVisible
    private class SymbolMethod extends Method {
        SymbolMethod(String format) {
            helperName = 'helper';
            name = 'replaceSymbols';
            this.params = new List<Object> { format };
        }
    }

    @TestVisible
    private class XrefMethod extends Method implements IMethodXref {
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

        public Integer level() {
            return this.level;
        }

        public List<XrefParam> xrefParams() {
            return this.xrefParams;
        }

        public void loadParams(IParamEvaluator paramEvaluator) {
            if (xrefParams != null && paramEvaluator != null) {
                for (XrefParam param : xrefParams) {
                    params.set(param.index, paramEvaluator.evaluateParam(param.fieldName, param.level));
                }
            }
        }
    }

    @TestVisible
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
}
