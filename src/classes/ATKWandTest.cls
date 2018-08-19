/**
 * Apex Test Kit
 */

@IsTest
private class ATKWandTest {
    @IsTest
    static void testSetProduction() {
        List<Object> leftList = new List<Object> { 'A', 'B', 'C' };
        List<Object> rightList = new List<Object> { '1', '2' };
        List<List<Object>> pairs = ATKWand.product(leftList, rightList, 6);
        for (Integer i = 0; i < pairs.size(); i++) {
            System.debug(String.valueOf(pairs[i][0]) + String.valueOf(pairs[i][1]));
        }
        System.assertEquals(6, pairs.size());
        System.assertEquals('A1', String.valueOf(pairs[0][0]) + String.valueOf(pairs[0][1]));
        System.assertEquals('A2', String.valueOf(pairs[1][0]) + String.valueOf(pairs[1][1]));
        System.assertEquals('B1', String.valueOf(pairs[2][0]) + String.valueOf(pairs[2][1]));
        System.assertEquals('B2', String.valueOf(pairs[3][0]) + String.valueOf(pairs[3][1]));
        System.assertEquals('C1', String.valueOf(pairs[4][0]) + String.valueOf(pairs[4][1]));
        System.assertEquals('C2', String.valueOf(pairs[5][0]) + String.valueOf(pairs[5][1]));
    }

    @IsTest
    static void testSetProduction2() {
        List<Object> leftList = new List<Object> { 'A', 'B', 'C' };
        List<Object> rightList = new List<Object> { '1', '2' };
        List<List<Object>> pairs = ATKWand.product2(leftList, rightList, 5);
        for (Integer i = 0; i < pairs.size(); i++) {
            System.debug(String.valueOf(pairs[i][0]) + String.valueOf(pairs[i][1]));
        }
        System.assertEquals(5, pairs.size());
        System.assertEquals('A1', String.valueOf(pairs[0][0]) + String.valueOf(pairs[0][1]));
        System.assertEquals('B2', String.valueOf(pairs[1][0]) + String.valueOf(pairs[1][1]));
        System.assertEquals('C1', String.valueOf(pairs[2][0]) + String.valueOf(pairs[2][1]));
        System.assertEquals('A2', String.valueOf(pairs[3][0]) + String.valueOf(pairs[3][1]));
        System.assertEquals('B1', String.valueOf(pairs[4][0]) + String.valueOf(pairs[4][1]));
    }

    @IsTest
    static void testSetDistribution() {
        List<Object> leftList = new List<Object> { 'i0', 'i1', 'i2', 'i3', 'i4' };
        List<Object> rightList = new List<Object> { 'j0', 'j1' };
        List<List<Object>> pairs = ATKWand.distribute(leftList, rightList);
        for (Integer i = 0; i < pairs.size(); i++) {
            System.debug(String.valueOf(pairs[i][0]) + String.valueOf(pairs[i][1]));
        }
        System.assertEquals(5, pairs.size());
        System.assertEquals('i0j0', String.valueOf(pairs[0][0]) + String.valueOf(pairs[0][1]));
        System.assertEquals('i1j0', String.valueOf(pairs[1][0]) + String.valueOf(pairs[1][1]));
        System.assertEquals('i2j0', String.valueOf(pairs[2][0]) + String.valueOf(pairs[2][1]));
        System.assertEquals('i3j1', String.valueOf(pairs[3][0]) + String.valueOf(pairs[3][1]));
        System.assertEquals('i4j1', String.valueOf(pairs[4][0]) + String.valueOf(pairs[4][1]));
    }
}
