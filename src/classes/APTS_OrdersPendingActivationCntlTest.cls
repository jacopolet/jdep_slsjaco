@isTest
private class APTS_OrdersPendingActivationCntlTest {
	
	@testSetup static void setupTestData() {
		User oTestUser = APTS_TestFacade.createTestUser();
		APTS_TestFacade.createMandatoryRecords(oTestUser);
		List<Account> listAcc = new List<Account>();
	    for (Account acc : [select Id, Account_Status__c from Account]) {
	      acc.Account_Status__c = 'Valid';
	      listAcc.add(acc);
	    }

	    if (!listAcc.isEmpty()) {
	      update listAcc;
	    }

	    //configure order
		APTS_TestFacade.createAndConfigureOrder(oTestUser);

		List<Apttus_Config2__OrderLineItem__c> listOLITmp = new List<Apttus_Config2__OrderLineItem__c>();
		for(Apttus_Config2__OrderLineItem__c oliTmp :[select id from Apttus_Config2__OrderLineItem__c where  Apttus_Config2__IsPrimaryLine__c = true]){
			oliTmp.APTS_Treated_By_Activation_Batch__c = true;
			listOLITmp.add(oliTmp);
		}
    
		if(!listOLITmp.isEmpty() ){
			update listOLITmp;
		}
	}
	
	@isTest static void test_Controller() {
		User oTestUser = APTS_TestFacade.getTestUser();

		test.startTest();

		System.runAs(oTestUser) {
			APTS_OrdersPendingActivationCntl oTmpCntl = new APTS_OrdersPendingActivationCntl();
			oTmpCntl.prepareData();
			System.assertNotEquals(TRUE, oTmpCntl.listOLI.isEmpty()); 

			oTmpCntl.loadMore();
			System.assertNotEquals(TRUE, oTmpCntl.listOLI.isEmpty()); 
			oTmpCntl.loadLess();
			System.assertNotEquals(TRUE, oTmpCntl.listOLI.isEmpty());

			oTmpCntl.selectedOLIId  = oTmpCntl.listOLI[0].Id;
			oTmpCntl.activateOrderLineItem();
		}
	}
}