/*************************************************************
@Name: APTS_FinalizeSwapOrderControllerTest
@Author: Neev Shah
@CreateDate: 12-05-2018
******************************************************************/

@isTest
private class APTS_FinalizeSwapOrderControllerTest {
	private static final String ID = System.Label.APTS_Id;

	@testSetup static void setupTestData() {
        User oTestUser = APTS_TestFacade.createTestUser();
        APTS_TestFacade.createMandatoryRecords(oTestUser);
        APTS_TestFacade.createAndConfigureOrder(oTestUser);

        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder();
        oOrder.APTS_Order_Sub_Type__c = 'Technical Swap';
        oOrder.APTS_Order_Type__c = 'Machine Order';
        oOrder.APTS_SAP_OrderType__c = 'XA13';
        update oOrder;

        Apttus_Config2__Order__c childOrder = oOrder.clone(false,false,false,false);
        childOrder.APTS_Order_Sub_Type__c = 'Technical Swap';
        childOrder.APTS_Order_Type__c = 'Machine Order';
        childOrder.APTS_SAP_OrderType__c = 'XB13';
        childOrder.Apttus_Config2__ParentOrderId__c = oOrder.Id;
        insert childOrder;

        Apttus_Config2__ProductConfiguration__c childConfig = APTS_TestDataFactory.createProductConfig(childOrder);
        insert childConfig;
    }

	@isTest static void test_redirectToContractedPage() {
		User oTestUser = APTS_TestFacade.getTestUser();
		Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder();
		Apttus_Config2__ProductConfiguration__c oCart = APTS_TestFacade.getProductConfiguration();

		test.startTest();
		System.runAs(oTestUser) {
			ApexPages.currentPage().getParameters().put('businessObjectId', oOrder.Id);
			ApexPages.currentPage().getParameters().put(ID, oCart.Id);
	        APTS_FinalizeSwapOrderController oController = new APTS_FinalizeSwapOrderController();
	        PageReference pageRef = oController.redirectToContractedPage();
	        System.assertNotEquals(NULL, pageRef);
    	}
        test.stopTest();
	}
	
	@isTest static void test_Exception() {
		User oTestUser = APTS_TestFacade.getTestUser();
		
		test.startTest();
		System.runAs(oTestUser) {
			ApexPages.currentPage().getParameters().put('businessObjectId', '1232');
			ApexPages.currentPage().getParameters().put(ID, '13242');
	        APTS_FinalizeSwapOrderController oController = new APTS_FinalizeSwapOrderController();
	        PageReference pageRef = oController.redirectToContractedPage();
	        System.assertEquals(NULL, pageRef);
    	}
        test.stopTest();
	}
	
}