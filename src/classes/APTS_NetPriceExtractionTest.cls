@isTest 
private class APTS_NetPriceExtractionTest {

     @testSetup
    public static void testDataSetup() {
    APTS_CERUtilityTest.testDataSetup();
     
    }
     static testMethod void test_insertNetPrice() {
        Test.startTest();
        Account childAccount = APTS_TestUtils.getchildaccount();
        id soldToAccountId = childAccount.id;
       APTS_NetPriceExtraction.insertNetPrice(soldToAccountId);
       Set<Id> accSet=new Set<Id>();
       accSet.add(soldToAccountId);
         APTS_NetPriceExtraction.updateNetPriceExtraction(accSet);
        Test.stopTest();
    }
}