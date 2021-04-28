@isTest 
private class APTS_NetPriceExtractionBatchTest  {
 @testSetup
    public static void testDataSetup() {
	APTS_CERUtilityTest.testDataSetup();
	 
	}
	 static testMethod void test_insertNetPrice() {
        Test.startTest();
        Database.executeBatch(new APTS_NetPriceExtractionBatch('Select Id from Account limit 1'), 5);
         
        Test.stopTest();
    }
}