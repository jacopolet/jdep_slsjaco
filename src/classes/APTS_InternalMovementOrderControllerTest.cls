/*************************************************************
@Name: APTS_InternalMovementOrderControllerTest
@Author: Galin Georgiev
@CreateDate: 29-05-2018
@Description:
@UsedBy: APTS_InternalMovementOrderController
******************************************************************/
//v100 29-05-2018 Galin Georgiev: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes

@isTest
private with sharing class APTS_InternalMovementOrderControllerTest {

	private static final String ID = System.Label.APTS_Id;
	private static final String AID = System.Label.APTS_aId;
	private static final String FIRSTPARAM = System.Label.APTS_firstParam;

	@testSetup static void setupTestData() {		
        
        User oTestUser = APTS_TestFacade.createTestUser();
		APTS_TestFacade.createMandatoryRecords(oTestUser);

		TriggerSettings__c oTriggerSettings = [SELECT APTS_Order_Trigger__c, APTS_OrderLineItemTrigger__c, APTS_Configuration_Trigger__c, AssetLineItemTrigger__c, PhysicalAssetTrigger__c FROM TriggerSettings__c];
		oTriggerSettings.APTS_Order_Trigger__c = false;
		oTriggerSettings.APTS_OrderLineItemTrigger__c = false;
		oTriggerSettings.APTS_Configuration_Trigger__c = false;
		oTriggerSettings.AssetLineItemTrigger__c = false;
		oTriggerSettings.PhysicalAssetTrigger__c = false;
		Database.update(oTriggerSettings);

		APTS_TestFacade.createAndConfigureAgreement(oTestUser);
		APTS_TestFacade.createAndConfigureOrder(oTestUser);
	}

	@isTest static void test_InternalMovementOrderController() {

		User oTestUser = APTS_TestFacade.getTestUser();
		Account oAccount = APTS_TestFacade.getAccount();
		Contact oContact = APTS_TestFacade.getContact();
		Apttus_Config2__Order__c oOrder = APTS_TestFacade.getMachineOrder();
		Apttus__APTS_Agreement__c oAgreement = APTS_TestFacade.getAgreement('Cancelled Agreement');		

		Test.startTest();

		System.runAs(oTestUser) {

			ApexPages.currentPage().getParameters().put(ID, oOrder.Id);
			ApexPages.currentPage().getParameters().put(AID, oAccount.Id);

			APTS_InternalMovementOrderController oInternalMovementOrderController = new APTS_InternalMovementOrderController();

			oInternalMovementOrderController.assetWrapperDisplayList[0].selected = true;
			oInternalMovementOrderController.assetWrapperDisplayList[0].sMovementToBuilding = 'MovementToBuilding';
			oInternalMovementOrderController.setSelectedAssetWrapper();

			oInternalMovementOrderController.dtInstallDate = Date.newInstance(2018, 06, 18);
			oInternalMovementOrderController.dtDeInstallDate = Date.newInstance(2018, 06, 18);
			oInternalMovementOrderController.serviceContactFromId = oContact.Id;
			oInternalMovementOrderController.serviceContactToId = oContact.Id;

			oInternalMovementOrderController.createMovementOrder();
			oInternalMovementOrderController.createCart();
			oInternalMovementOrderController.changeAssets();
			oInternalMovementOrderController.saveCart();
			oInternalMovementOrderController.updatePhysicalAsset();
			oInternalMovementOrderController.updateLSP();
			oInternalMovementOrderController.goToPricing();
			oInternalMovementOrderController.backToAgreement();			
		}

		Test.stopTest();
	}

	@isTest static void test_doSearch() {

		User oTestUser = APTS_TestFacade.getTestUser();
		Account oAccount = APTS_TestFacade.getAccount();
		Apttus_Config2__Order__c oOrder = APTS_TestFacade.getMachineOrder();

		test.startTest();

		System.runAs(oTestUser) {

			ApexPages.currentPage().getParameters().put(ID, oOrder.Id);
			ApexPages.currentPage().getParameters().put(AID, oAccount.Id);

			APTS_InternalMovementOrderController oInternalMovementOrderController = new APTS_InternalMovementOrderController();
			
			ApexPages.currentPage().getParameters().put(FIRSTPARAM, '12');
			oInternalMovementOrderController.searchSerialNumbers();

			oInternalMovementOrderController.doAssetSearch();

			oInternalMovementOrderController.resetAssetSearch();
			oInternalMovementOrderController.doAssetSearch();

			ApexPages.currentPage().getParameters().put('serviceContactFrom', 'JDE');
			ApexPages.currentPage().getParameters().put('serviceContactTo', 'JDE');
			oInternalMovementOrderController.searchServiceContactFrom();
			oInternalMovementOrderController.searchServiceContactTo();			

			oInternalMovementOrderController.setServiceContactFrom();
			oInternalMovementOrderController.setServiceContactTo();				

			oInternalMovementOrderController.back();				
		}

		test.stopTest();
	}	

	@isTest static void test_LoadMoreLess() {

		User oTestUser = APTS_TestFacade.getTestUser();
		Account oAccount = APTS_TestFacade.getAccount();
		Apttus_Config2__Order__c oOrder = APTS_TestFacade.getMachineOrder();

		test.startTest();

		System.runAs(oTestUser) {

			ApexPages.currentPage().getParameters().put(ID, oOrder.Id);
			ApexPages.currentPage().getParameters().put(AID, oAccount.Id);

			APTS_InternalMovementOrderController oInternalMovementOrderController = new APTS_InternalMovementOrderController();

			oInternalMovementOrderController.loadMore();
			oInternalMovementOrderController.loadLess();
		}

		test.stopTest();
	}
}