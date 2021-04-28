/*************************************************************
@Name: APTS_ConversionOrderControllerTest
@Author: Galin Georgiev
@CreateDate: 19-02-2018
@Description: Order Utils Test
@UsedBy: APTS_ConversionOrderController
******************************************************************/
//v100 19-02-2018 Galin Georgiev: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes

@isTest
private with sharing class APTS_ConversionOrderControllerTest {

	private static final String ID = System.Label.APTS_Id;

	@testSetup static void setupTestData() {

		User oTestUser = APTS_TestFacade.createTestUser();
		APTS_TestFacade.createMandatoryRecords(oTestUser);
		APTS_TestFacade.createAndConfigureAgreement(oTestUser);
		APTS_TestFacade.createAndConfigureOrder(oTestUser);
	}

	@isTest static void test_ConversionOrderController() {

		User oTestUser = APTS_TestFacade.getTestUser();
		Apttus_Config2__Order__c oOrder = APTS_TestFacade.getMachineOrder();
		List<Apttus_Config2__OrderLineItem__c> orderLineItemList = APTS_TestFacade.getOrderLineItemList(oOrder.Id);
		Apttus__APTS_Agreement__c oAgreement = APTS_TestFacade.getAgreement('Agreement Amended');
		Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestFacade.getMachineProductConfiguration();

		oOrder.Apttus_CMConfig__AgreementId__c = oAgreement.Id;
		Database.update(oOrder);

		Test.startTest();

		System.runAs(oTestUser) {

			ApexPages.currentPage().getParameters().put(ID, oProductConfiguration.Id);

			APTS_ConversionOrderController oConversionOrderController = new APTS_ConversionOrderController();

			oConversionOrderController.agreementWrapperList[0].agreementLineItemWrapperList[0].selected = true;
			oConversionOrderController.addSelectedToCart();
			oConversionOrderController.updateProductAttributeValues();
			oConversionOrderController.fixNonPrimaryLines();

			oConversionOrderController.backToCatalog();
			oConversionOrderController.goToPricing();
		}

		Test.stopTest();
	}
}