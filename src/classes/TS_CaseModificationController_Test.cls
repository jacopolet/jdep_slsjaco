/**
* @author        Harold Marilag
* @date          8.23.2017           
* @description   Test class for TS_CaseModificationController
* @revision(s)
*/
@isTest
private class TS_CaseModificationController_Test {

    
    /**
	* @author        Harold Marilag
	* @date          8.23.2017           
	* @description   Test method for TS_CaseModificationController
	* @revision(s)
	*/
    private static testMethod void testCreateMassCaseRecords() {
        Account acc = new Account(Name='Account', Phone='+31302979111');
        insert acc;
        
        Apttus_Config2__AccountLocation__c al = TS_TestDataFactory.createAccountLocation(acc.Id); 
        insert al;
        
        Product2 p2 = TS_TestDataFactory.createProduct('P', 'MA');
        insert p2;
        
        Case cse = TS_TestDataFactory.createFieldServiceCase();
        cse.AccountId = acc.Id;
        cse.AccountLocation__c = al.Id;
        cse.ProductId = p2.Id;
        cse.Status = 'Open';
        cse.GenerateOrder__c = true;
        insert cse;
        
        
        TS_CaseModificationController.runBatchJob(cse);
        
        //force throw exception
        TS_CaseModificationController.hasException = true;
        TS_CaseModificationController.runBatchJob(cse);
        TS_CaseModificationController.createOrderClass(cse.Id);
        System.assert(cse != null);
    }  
}