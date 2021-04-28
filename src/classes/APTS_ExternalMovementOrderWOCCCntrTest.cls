/*************************************************************
@Name: APTS_ExternalMovementOrderWOCCCntrTest
@Author: Galin Georgiev
@CreateDate: 24-06-2018
@Description:
@UsedBy: APTS_ExternalMovementOrderWOCCCntr
******************************************************************/
//v100 24-06-2018 Galin Georgiev: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes

@isTest
private with sharing class APTS_ExternalMovementOrderWOCCCntrTest {

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

	@isTest static void test_ExternalMovementOrderWOCCController() {

		User oTestUser = APTS_TestFacade.getTestUser();
		Account oAccount = APTS_TestFacade.getAccount();
		Contact oContact = APTS_TestFacade.getContact();
		Apttus_Config2__Order__c oOrder = APTS_TestFacade.getMachineOrder();
		Apttus__APTS_Agreement__c oAgreement = APTS_TestFacade.getAgreement('Cancelled Agreement');

		Test.startTest();

		System.runAs(oTestUser) {

			ApexPages.currentPage().getParameters().put(ID, oOrder.Id);
			ApexPages.currentPage().getParameters().put(AID, oAccount.Id);

			APTS_ExternalMovementOrderWOCCController oExternalMovementOrderWOCCController = new APTS_ExternalMovementOrderWOCCController();

			oExternalMovementOrderWOCCController.assetWrapperDisplayList[0].selected = true;
			oExternalMovementOrderWOCCController.assetWrapperDisplayList[0].sMovementToBuilding = 'MovementToBuilding';
			oExternalMovementOrderWOCCController.setSelectedAssetWrapper();
			oExternalMovementOrderWOCCController.getAccountHierarchyList();

			oExternalMovementOrderWOCCController.dtInstallDate = Date.newInstance(2018, 06, 18);
			oExternalMovementOrderWOCCController.dtDeInstallDate = Date.newInstance(2018, 06, 18);
			oExternalMovementOrderWOCCController.serviceContactFromId = oContact.Id;
			oExternalMovementOrderWOCCController.serviceContactToId = oContact.Id;

			oExternalMovementOrderWOCCController.createMovementOrder();
			oExternalMovementOrderWOCCController.createCart();
			oExternalMovementOrderWOCCController.changeAssets();
			oExternalMovementOrderWOCCController.saveCart();
			oExternalMovementOrderWOCCController.updatePhysicalAsset();
			oExternalMovementOrderWOCCController.updateLSP();
			oExternalMovementOrderWOCCController.goToPricing();
			oExternalMovementOrderWOCCController.backToAgreement();
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

			APTS_ExternalMovementOrderWOCCController oExternalMovementOrderWOCCController = new APTS_ExternalMovementOrderWOCCController();

			ApexPages.currentPage().getParameters().put(FIRSTPARAM, '12');
			oExternalMovementOrderWOCCController.searchSerialNumbers();

			oExternalMovementOrderWOCCController.doAssetSearch();

			oExternalMovementOrderWOCCController.resetAssetSearch();
			oExternalMovementOrderWOCCController.doAssetSearch();

			oExternalMovementOrderWOCCController.searchToShipToLocations();
			oExternalMovementOrderWOCCController.doSelectAccountLocation();

			ApexPages.currentPage().getParameters().put(FIRSTPARAM, 'JDE');
			oExternalMovementOrderWOCCController.searchServiceContactFrom();
			oExternalMovementOrderWOCCController.searchServiceContactTo();

			oExternalMovementOrderWOCCController.setServiceContactFrom();
			oExternalMovementOrderWOCCController.setServiceContactTo();

			oExternalMovementOrderWOCCController.back();
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

			APTS_ExternalMovementOrderWOCCController oExternalMovementOrderWOCCController = new APTS_ExternalMovementOrderWOCCController();

			oExternalMovementOrderWOCCController.loadMore();
			oExternalMovementOrderWOCCController.loadLess();
		}

		test.stopTest();
	}
}