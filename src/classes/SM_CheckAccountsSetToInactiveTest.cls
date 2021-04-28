@isTest
private class SM_CheckAccountsSetToInactiveTest {

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
        acc.SAP_Customer_ID__c = '76509';
        acc.Phone = '+31302979111';      
        acc.Sales_Organization__c = 'SAP_0333';
        acc.Duplicate_Reason__c='Office building';
        acc.Being_Converted__c = true;
        acc.IsActive__c = true;
        acc.Last_Relevant_Activity_Date__c = Date.newInstance(1960, 2, 17);
        insert acc;
        
        SM_CheckAccountsSetToInactive.hasException = true;
        SM_CheckAccountsSetToInactive batchrun = new SM_CheckAccountsSetToInactive();
        ID result = Database.executeBatch(batchrun);
        System.assert(result != null);
        
        Test.stopTest();
	}
    
}