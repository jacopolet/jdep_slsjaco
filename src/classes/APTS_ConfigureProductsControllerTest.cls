/*************************************************************
@Name: APTS_ConfigureProductsControllerTest
@Author: Galin Georgiev
@CreateDate: 16-10-2018
@Description: Redirect to contracted products when user click on Configure Products
@UsedBy: APTS_ConfigureProducts page
******************************************************************/
//v100 16-10-2018 Galin Georgiev: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes

@isTest
private with sharing class APTS_ConfigureProductsControllerTest {

	private static final String ID = System.Label.APTS_Id;
	private static final String FLOW = System.Label.APTS_Flow;

	@testSetup static void setupTestData() {

		User oTestUser = APTS_TestFacade.createTestUser();

		APTS_TestFacade.createMandatoryRecords(oTestUser);
		APTS_TestFacade.createAndConfigureOrder(oTestUser);
		APTS_TestFacade.createMachineAmendOrder(oTestUser);

		System.assert(oTestUser != null);
	}

	@isTest static void test_configureProductsController() {

		User oTestUser = APTS_TestFacade.getTestUser();

		Apttus_Config2__Order__c oOrder = APTS_TestFacade.getMachineOrder();

		test.startTest();

		System.runAs(oTestUser) {

			ApexPages.currentPage().getParameters().put(ID, oOrder.Id);
			ApexPages.currentPage().getParameters().put(FLOW, 'NGMachineOrder');

			APTS_ConfigureProductsController oConfigureProductsController = new APTS_ConfigureProductsController();

			oConfigureProductsController.goToContractedProducts();

			System.assert(oTestUser != null);
		}

		test.stopTest();
	}

	@isTest static void test_configureProductsController1() {

		User oTestUser = APTS_TestFacade.getTestUser();
		
		Apttus_Config2__Order__c oOrder = APTS_TestFacade.getMachineOrder();

		Apttus_Config2__ProductConfiguration__c oConfiguration = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c WHERE Apttus_Config2__OrderId__c = :oOrder.Id];
		Database.delete(oConfiguration);

		test.startTest();

		System.runAs(oTestUser) {

			ApexPages.currentPage().getParameters().put(ID, oOrder.Id);
			ApexPages.currentPage().getParameters().put(FLOW, 'NGMachineOrder');

			APTS_ConfigureProductsController oConfigureProductsController = new APTS_ConfigureProductsController();

			oConfigureProductsController.goToContractedProducts();

			System.assert(oTestUser != null);
		}

		test.stopTest();
	}
}