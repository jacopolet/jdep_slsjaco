@isTest
private class SM_FlaggedforDeletionBatchTest {

	private static testMethod void testPositive() {
	    Test.startTest();
	    
        Account acc = new Account();
        acc.Name = 'accName1';
        acc.BillingStreet = 'mainstreet1';
        acc.Main_House_Number__c = '121';
        acc.Main_Street_Only__c = 'streetOnly1';
        acc.BillingCity = 'mainCity1';
        acc.BillingState = 'state1';
        acc.BillingPostalCode = 'pCode1';
        acc.BillingCountry = 'country1';
        acc.Main_Country_ISO__c = 'countryISO1';
        //acc.Main_Postal_Box__c = 'pBox1';
        acc.Language__c = 'SAP_SR';
        acc.Bill_Block_Reason__c = 'SAP_00';
        acc.Transactional_Block_Reason__c = 'SAP_00';
        acc.Delivery_Block_Reason__c = 'SAP_D3';
        acc.Phone = '+31302979111';      
        acc.Sales_Organization__c = '	SAP_6712';
        acc.Duplicate_Reason__c='Office building';
        acc.Duplicate_Validation__c = 'Duplicate Identified';
        acc.Flagged_for_Deletion__c = true;
        acc.RecordTypeId = SM_Constants.recordTypeIdProspectValid;
        insert acc;
        
        // SM_processonCallListDayAccount.hasException = true;
        SM_FlaggedforDeletionBatch batchrun = new SM_FlaggedforDeletionBatch();
        ID result = Database.executeBatch(batchrun);
        System.assert(result != null);
        
        Test.stopTest();
	}
	
	private static testMethod void testNegative() {
        Test.startTest();
        Account acc = new Account();
        acc.Name = 'accName1';
        acc.BillingStreet = 'mainstreet1';
        acc.Main_House_Number__c = '121';
        acc.Main_Street_Only__c = 'streetOnly1';
        acc.BillingCity = 'mainCity1';
        acc.BillingState = 'state1';
        acc.BillingPostalCode = 'pCode1';
        acc.BillingCountry = 'country1';
        acc.Main_Country_ISO__c = 'countryISO1';
        //acc.Main_Postal_Box__c = 'pBox1';
        acc.Language__c = 'SAP_SR';
        acc.Bill_Block_Reason__c = 'SAP_00';
        acc.Transactional_Block_Reason__c = 'SAP_00';
        acc.Delivery_Block_Reason__c = 'SAP_D3';
        acc.Phone = '+31302979111';      
        acc.Sales_Organization__c = '	SAP_6712';
        acc.Duplicate_Reason__c='Office building';
        acc.Duplicate_Validation__c = 'Duplicate Identified';
        acc.Flagged_for_Deletion__c = true;
        acc.RecordTypeId = SM_Constants.recordTypeIdProspectValid;
        insert acc;
        
        SM_FlaggedforDeletionBatch.hasException = true;
        SM_FlaggedforDeletionBatch batchrun = new SM_FlaggedforDeletionBatch();
        ID result = Database.executeBatch(batchrun);
        System.assert(result != null);
        
        Test.stopTest();
    }
}