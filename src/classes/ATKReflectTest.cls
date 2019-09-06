@IsTest
private with sharing class ATKReflectTest {

    class TestProvider implements ATKReflect.IValueProvider {
        public Object call(String method, List<Object> params) {
            String value = '';
            for (Object param : params) {
                value += (String)param;
            }
            return value;
        }
    }

    @isTest
    static void testMethodEvaluation() {
        ATKReflect.MethodParser parser = new ATKReflect.MethodParser();
        Map<String, ATKReflect.IValueProvider> helpers = new Map<String, ATKReflect.IValueProvider> {
            'helper' => new TestProvider()
        };

        // expression with help interpolation
        ATKReflect.MethodGroup methodGroup = (ATKReflect.MethodGroup)parser.parse('xxx{!helper.name(param0, param1)}xxx');
        System.assertEquals(2, methodGroup.splits.size());
        System.assertEquals('xxx', methodGroup.splits[0]);
        System.assertEquals('xxx', methodGroup.splits[1]);
        System.assertEquals(1, methodGroup.methodList.size());
        ATKReflect.Method method = (ATKReflect.Method)methodGroup.methodList[0];
        System.assertEquals('helper', method.helperName);
        System.assertEquals('name', method.name);
        System.assertEquals(2, method.params.size());
        System.assertEquals('param0', method.params[0]);
        System.assertEquals('param1', method.params[1]);
        System.assertEquals('xxxparam0param1xxx', methodGroup.evaluate(helpers));

        // expression with symbol interpolation
        methodGroup = (ATKReflect.MethodGroup)parser.parse('xxx{{###-###-####}}xxx');
        System.assertEquals(2, methodGroup.splits.size());
        System.assertEquals('xxx', methodGroup.splits[0]);
        System.assertEquals('xxx', methodGroup.splits[1]);
        System.assertEquals(1, methodGroup.methodList.size());
        method = (ATKReflect.Method)methodGroup.methodList[0];
        System.assert(method instanceof ATKReflect.SymbolMethod);
        System.assertEquals('helper', method.helperName);
        System.assertEquals('replaceSymbols', method.name);
        System.assertEquals(1, method.params.size());
        System.assertEquals('###-###-####', method.params[0]);
        System.assertEquals('xxx###-###-####xxx', methodGroup.evaluate(helpers));

        // expression without interpolation
        methodGroup = (ATKReflect.MethodGroup)parser.parse('xxx---xxx');
        System.assertEquals(0, methodGroup.splits.size());
        System.assertEquals(0, methodGroup.methodList.size());
        System.assertEquals('xxx---xxx', methodGroup.evaluate(helpers));

        // expression is pure method
        methodGroup = (ATKReflect.MethodGroup)parser.parse('{!helper.name(param0, param1)}');
        System.assertEquals(2, methodGroup.splits.size());
        System.assertEquals(1, methodGroup.methodList.size());
        System.assertEquals('param0param1', methodGroup.evaluate(helpers));

        // expression is cached
        methodGroup = (ATKReflect.MethodGroup)parser.parse('{!helper.name(param0, param1)}');
        System.assertEquals(2, methodGroup.splits.size());
        System.assertEquals(1, methodGroup.methodList.size());
        System.assertEquals('param0param1', methodGroup.evaluate(helpers));
    }

    class TestParamEvaluator implements ATKReflect.IParamEvaluator {
        public Object evaluateParam(String fieldName, Integer level ) {
            Object value;
            if (fieldName == 'param0') value = 'A';
            if (fieldName == 'param1') value = 'B';
            return value;
        }
    }

    @isTest
    static void testXrefParamEvaluation() {
        TestParamEvaluator paramEvaluator = new TestParamEvaluator();
        Map<String, ATKReflect.IValueProvider> helpers = new Map<String, ATKReflect.IValueProvider> {
            'helper' => new TestProvider()
        };

        List<ATKReflect.XrefParam> xrefParams = new List<ATKReflect.XrefParam> {
            new ATKReflect.XrefParam('param0', 0, 1),
            new ATKReflect.XrefParam('param1', 1, 2)
        };
        List<Object> params = new List<Object> { null, null };

        ATKReflect.XrefMethod method = new ATKReflect.XrefMethod(xrefParams);
        method.helperName = 'helper';
        method.name = 'name';
        method.params = params;

        method.loadParams(paramEvaluator);
        System.assertEquals('AB', method.evaluate(helpers));
        System.assertEquals('A', method.params[0]);
        System.assertEquals('B', method.params[1]);
    }
}
