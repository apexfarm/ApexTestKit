public with sharing class ATKMock implements System.StubProvider {


    public static Object getInstance(Type mockType) {
        return Test.createStub(mockType, new ATKMock());
    }

    public Object handleMethodCall(Object target, String stubbedMethodName,
        Type returnType, List<Type> paramTypes, List<String> paramNames,
        List<Object> listOfArgs) {

        // The following debug statements show an example of logging
        // the invocation of a mocked method.

        // You can use the method name and return type to determine which method was called.
        System.debug('Name of stubbed method: ' + stubbedMethodName);
        System.debug('Return type of stubbed method: ' + returnType.getName());

        // You can also use the parameter names and types to determine which method
        // was called.
        for (integer i =0; i < paramNames.size(); i++) {
            System.debug('parameter name: ' + paramNames.get(i));
            System.debug('  parameter type: ' + paramTypes.get(i).getName());
        }

        // This shows the actual parameter values passed into the stubbed method at runtime.
        System.debug('number of parameters passed into the mocked call: ' +
            listOfArgs.size());
        System.debug('parameter(s) sent into the mocked call: ' + listOfArgs);

        // This is a very simple mock provider that returns a hard-coded value
        // based on the return type of the invoked.
        if (returnType.getName() == 'String')
            return '8/8/2016';
        else
            return null;
    }

    private class Invocation {
        Object target { get; set; }
        String methodName { get; set; }
        Type returnType { get; set; }
        List<Type> paramTypes { get; set; }
        List<String> paramNames { get; set; }
        List<Object> listOfArgs { get; set; }
    }

    private class ArgumentMatcher {

    }
}
