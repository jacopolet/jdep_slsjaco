/*************************************************************
@Name: APTS_PreviewOrderControllerTest
@Author: Galin Georgiev
@CreateDate: 19-02-2018
@Description: Preview Order Test
@UsedBy: APTS_PreviewOrderController
******************************************************************/
//v100 19-02-2018 Galin Georgiev: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes
//v101 Added code to test exception handling

@isTest
private with sharing class APTS_ResetOrderControllerTest {

	@testSetup static void setupTestData() {
		User oTestUser = APTS_TestFacade.createTestUser();
		APTS_TestFacade.createMandatoryRecords(oTestUser);
		APTS_TestFacade.createAndConfigureOrder(oTestUser);
	}

	@isTest static void test_ResetOrderController() {

		User oTestUser = APTS_TestFacade.getTestUser();
		Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder();

		test.startTest();

		System.runAs(oTestUser) {

			ApexPages.currentPage().getParameters().put(APTS_OrderConstants.ID, oOrder.Id);
			APTS_ResetOrderController oResetOrderController = new APTS_ResetOrderController();
			PageReference pageRef = oResetOrderController.resetOrder();
		}

		test.stopTest();
	}
}