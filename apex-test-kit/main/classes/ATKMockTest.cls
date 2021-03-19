@IsTest
public with sharing class ATKMockTest {

    public class MockException extends Exception {

    }

    public class IntegerAnswer {

    }

    public void doNothing() {

    }

    public void doException() {

    }

    public Object doWithInteger(Integer i) {
        return null;
    }

    @IsTest
    static void testMock() {
        MockException exp = new MockException();

        ATKMockTest mock = (ATKMockTest)ATK.mock(ATKMockTest.class);
        {// GIVEN
            ATK.given(mock.doWithInteger(0)).willReturn(0);
            ATK.given(mock.doWithInteger(ATK.anyInteger())).willReturn(ATK.anyInteger());
            ATK.given(mock.doWithInteger(2)).willReturn(new IntegerAnswer());
            ATK.given(mock.doWithInteger(3)).willThrow(exp);

            ((ATKMockTest)ATK.willReturn(4).given(mock)).doWithInteger(4);
            ((ATKMockTest)ATK.willThrow(exp).given(mock)).doException(); // void method
            ((ATKMockTest)ATK.willDoNothing().given(mock)).doNothing();  // void method
        }

        {// WHEN
            mock.doWithInteger(0);
            mock.doWithInteger(1);
            mock.doWithInteger(2);
            try {
                mock.doWithInteger(3);
            } catch (MockException ex) {
            }
            mock.doWithInteger(4);

            try {
                mock.doException();
            } catch (MockException ex) {
            }
            mock.doNothing();
        }

        {// THEN
            ((ATKMockTest)ATK.then(mock).should().times(1)).doWithInteger(0);
            ((ATKMockTest)ATK.then(mock).should().atLeast(1)).doWithInteger(1);
            ((ATKMockTest)ATK.then(mock).should().atMost(1)).doWithInteger(2);
            ((ATKMockTest)ATK.then(mock).should().never()).doWithInteger(5);

            ATK.InOrder inOrder;
            ((ATKMockTest)ATK.then(mock).should(inOrder).times(1)).doWithInteger(0);
            ((ATKMockTest)ATK.then(mock).should(inOrder).times(1)).doWithInteger(1);
            ((ATKMockTest)ATK.then(mock).should(inOrder).times(1)).doWithInteger(2);
            ((ATKMockTest)ATK.then(mock).should(inOrder).times(1)).doWithInteger(3);
        }
    }
}
