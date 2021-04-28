/*************************************************************
@Name: APTS_ExternalMovementOrderWCCCntrTest
@Author: Galin Georgiev
@CreateDate: 15-06-2018
@Description:
@UsedBy: APTS_ExternalMovementOrderWCCCntr
******************************************************************/
//v100 15-06-2018 Galin Georgiev: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes

@isTest
private with sharing class APTS_ExternalMovementOrderWCCCntrTest {

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
		APTS_TestFacade.createAndConfigureAgreementOnSecondAccount(oTestUser);
		APTS_TestFacade.createAndConfigureOrder(oTestUser);

		Apttus_Config2__Order__c oOrder = APTS_TestFacade.getMachineOrder();

		Apttus__APTS_Agreement__c oDeInstallAgreementAmended = APTS_TestFacade.getAgreement('Cancelled Agreement');
		List<Apttus__AgreementLineItem__c> agreementDeInstallLineItemList = APTS_TestFacade.getAgreementLineItem(oDeInstallAgreementAmended.Id);
		List<Apttus_Config2__AssetLineItem__c> assetLineItemList = APTS_TestFacade.getAssetLineItem();
		for (Apttus__AgreementLineItem__c oAgreementLineItem : agreementDeInstallLineItemList) {
			oAgreementLineItem.APTS_Serial_Number2__c = '12345';
			oAgreementLineItem.Apttus_CMConfig__AssetLineItemId__c = assetLineItemList.get(0).Id;
		}
		Database.update(agreementDeInstallLineItemList);

		Apttus__APTS_Agreement__c oInstallAgreement = APTS_TestFacade.getAgreement('Agreement second account');
		List<Apttus__AgreementLineItem__c> agreementLineItemList = APTS_TestFacade.getAgreementLineItem(oInstallAgreement.Id);
		for (Apttus__AgreementLineItem__c oAgreementLineItem : agreementLineItemList) {
			oAgreementLineItem.APTS_Serial_Number2__c = '12345';
		}
		Database.update(agreementLineItemList);

		oOrder.Apttus_CMConfig__AgreementId__c = oDeInstallAgreementAmended.Id;
		Database.update(oOrder);
	}

	@isTest static void test_ExternalMovementOrderWCCControllerDeInstall() {

		User oTestUser = APTS_TestFacade.getTestUser();
		Account oAccount = APTS_TestFacade.getAccount();
		Apttus_Config2__Order__c oOrder = APTS_TestFacade.getMachineOrder();
		Apttus__APTS_Agreement__c oInstallAgreement = APTS_TestFacade.getAgreement('Agreement second account');

		Test.startTest();

		System.runAs(oTestUser) {

			ApexPages.currentPage().getParameters().put(ID, oOrder.Id);
			ApexPages.currentPage().getParameters().put(AID, oAccount.Id);

			APTS_ExternalMovementOrderWCCController oExternalMovementOrderWCCController = new APTS_ExternalMovementOrderWCCController();

			oExternalMovementOrderWCCController.installAgreementId = oInstallAgreement.Id;

			oExternalMovementOrderWCCController.assetWrapperDisplayList[0].selected = true;
			oExternalMovementOrderWCCController.assetWrapperDisplayList[0].sMovementToBuilding = 'MovementToBuilding';
			oExternalMovementOrderWCCController.setSelectedAssetWrapper();

			oExternalMovementOrderWCCController.dtInstallDate = Date.newInstance(2018, 06, 18);
			oExternalMovementOrderWCCController.dtDeInstallDate = Date.newInstance(2018, 06, 18);

			oExternalMovementOrderWCCController.createMovementOrder();
			oExternalMovementOrderWCCController.createDeInstallCart();
			oExternalMovementOrderWCCController.cancelAssets();
			oExternalMovementOrderWCCController.repriceDeInstallCart();
			oExternalMovementOrderWCCController.saveDeInstallCart();
			oExternalMovementOrderWCCController.finalizeDeInstallCart();
			oExternalMovementOrderWCCController.synchronizeDeInstallCart();
		}

		Test.stopTest();
	}

	@isTest static void test_ExternalMovementOrderWCCControllerInstall() {

		User oTestUser = APTS_TestFacade.getTestUser();
		Account oAccount = APTS_TestFacade.getAccount();
		Apttus_Config2__Order__c oOrder = APTS_TestFacade.getMachineOrder();

		Test.startTest();

		System.runAs(oTestUser) {

			ApexPages.currentPage().getParameters().put(ID, oOrder.Id);
			ApexPages.currentPage().getParameters().put(AID, oAccount.Id);

			APTS_ExternalMovementOrderWCCController oExternalMovementOrderWCCController = new APTS_ExternalMovementOrderWCCController();

			oExternalMovementOrderWCCController.assetWrapperDisplayList[0].selected = true;
			oExternalMovementOrderWCCController.assetWrapperDisplayList[0].sMovementToBuilding = 'MovementToBuilding';
			oExternalMovementOrderWCCController.setSelectedAssetWrapper();

			oExternalMovementOrderWCCController.dtInstallDate = Date.newInstance(2018, 06, 18);
			oExternalMovementOrderWCCController.dtDeInstallDate = Date.newInstance(2018, 06, 18);

			oExternalMovementOrderWCCController.validate();
			oExternalMovementOrderWCCController.createInstallOrder();
			oExternalMovementOrderWCCController.createInstallCart();
			oExternalMovementOrderWCCController.addProductsToInstallCart();
			oExternalMovementOrderWCCController.updateProductAttributeValues();
			oExternalMovementOrderWCCController.repriceInstallCart();
			oExternalMovementOrderWCCController.fixNonPrimaryLines();
			oExternalMovementOrderWCCController.cloneLSPDetails();
			oExternalMovementOrderWCCController.saveInstallCart();
			oExternalMovementOrderWCCController.finalizeInstallCart();
			oExternalMovementOrderWCCController.synchronizeInstallCart();
			oExternalMovementOrderWCCController.createInstallPhysicalAsset();			

			oExternalMovementOrderWCCController.goToOrder();
			oExternalMovementOrderWCCController.backToAgreement();
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

			APTS_ExternalMovementOrderWCCController oExternalMovementOrderWCCController = new APTS_ExternalMovementOrderWCCController();

			ApexPages.currentPage().getParameters().put(FIRSTPARAM, '12');
			oExternalMovementOrderWCCController.searchSerialNumbers();

			oExternalMovementOrderWCCController.doAssetSearch();

			oExternalMovementOrderWCCController.resetAssetSearch();
			oExternalMovementOrderWCCController.doAssetSearch();
			
			oExternalMovementOrderWCCController.back();
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

			APTS_ExternalMovementOrderWCCController oExternalMovementOrderWCCController = new APTS_ExternalMovementOrderWCCController();

			oExternalMovementOrderWCCController.loadMore();
			oExternalMovementOrderWCCController.loadLess();            
		}

		test.stopTest();
	}
    @isTest static void test_Exceptions() {

		User oTestUser = APTS_TestFacade.getTestUser();
		Account oAccount = APTS_TestFacade.getAccount();
		Apttus_Config2__Order__c oOrder = APTS_TestFacade.getMachineOrder();

		test.startTest();

		System.runAs(oTestUser) {

			ApexPages.currentPage().getParameters().put(ID, oOrder.Id);
			ApexPages.currentPage().getParameters().put(AID, oAccount.Id);
			Apttus_Config2__ProductConfiguration__c  pc = APTS_TestFacade.getProductConfiguration();
            id cartId = pc.id;
          
			APTS_ExternalMovementOrderWCCController oExternalMovementOrderWCCController = new APTS_ExternalMovementOrderWCCController();

			oExternalMovementOrderWCCController.accountHierarchyId = null;
            oExternalMovementOrderWCCController.sAllServiceContactFrom = 'From Contact';
            oExternalMovementOrderWCCController.sServiceContactTo = 'To Contact';
            oExternalMovementOrderWCCController.sAllServiceContactTo = 'All service contacts';
            oExternalMovementOrderWCCController.bErrorOccurred = false;
			oExternalMovementOrderWCCController.deInstallCartId = oOrder.id;
            oExternalMovementOrderWCCController.installCartId = oOrder.id;
            oExternalMovementOrderWCCController.createMovementOrder();
            oExternalMovementOrderWCCController.bErrorOccurred = false;
            oExternalMovementOrderWCCController.createDeInstallCart();
            oExternalMovementOrderWCCController.cancelAssets();       
            oExternalMovementOrderWCCController.bErrorOccurred = false;
            oExternalMovementOrderWCCController.repriceDeInstallCart();
            oExternalMovementOrderWCCController.bErrorOccurred = false;
            oExternalMovementOrderWCCController.saveDeInstallCart();
            oExternalMovementOrderWCCController.finalizeDeInstallCart();
            oExternalMovementOrderWCCController.bErrorOccurred = false;
            oExternalMovementOrderWCCController.synchronizeDeInstallCart();
            oExternalMovementOrderWCCController.deInstallCartId = cartId;
            oExternalMovementOrderWCCController.installCartId = cartId;
            oExternalMovementOrderWCCController.createInstallOrder();           
            oExternalMovementOrderWCCController.addProductsToInstallCart();
            oExternalMovementOrderWCCController.updateProductAttributeValues();
            oExternalMovementOrderWCCController.repriceInstallCart();            
            oExternalMovementOrderWCCController.fixNonPrimaryLines();
            oExternalMovementOrderWCCController.cloneLSPDetails();             
            oExternalMovementOrderWCCController.createInstallPhysicalAsset();
            Contact oContact = APTS_TestFacade.getContact();
            ApexPages.currentPage().getParameters().put(FIRSTPARAM, oContact.Id);			
            oExternalMovementOrderWCCController.setServiceContactTo();
            oExternalMovementOrderWCCController.setServiceContactFrom();
            oExternalMovementOrderWCCController.searchServiceContactTo();
            oExternalMovementOrderWCCController.searchServiceContactFrom();            
            try { oExternalMovementOrderWCCController.back(); } catch(Exception ex){} 
            try { oExternalMovementOrderWCCController.backToAgreement(); } catch(Exception ex){} 
			oExternalMovementOrderWCCController.deInstallCartId = oOrder.id;
            oExternalMovementOrderWCCController.installCartId =  oOrder.id;
            oExternalMovementOrderWCCController.bErrorOccurred = false;
            oExternalMovementOrderWCCController.saveInstallCart();
            oExternalMovementOrderWCCController.bErrorOccurred = false;
            oExternalMovementOrderWCCController.createInstallCart();
            oExternalMovementOrderWCCController.bErrorOccurred = false;
            oExternalMovementOrderWCCController.createDeInstallCart();                     
		}
		test.stopTest();
	}
}