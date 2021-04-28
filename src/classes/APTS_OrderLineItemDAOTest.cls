/*************************************************************
@Name: APTS_OrderLineItemDAOTest
@Author: Galin Georgiev
@CreateDate: 12-10-2018
@Description: Order Line Item DAO Test
@UsedBy: APTS_OrderLineItemDAO
******************************************************************/
//v100 12-10-2018 Georgiev: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes

@isTest
private with sharing class APTS_OrderLineItemDAOTest {

    @testSetup static void setupTestData() {

        User oTestUser = APTS_TestFacade.createTestUser();
        APTS_TestFacade.createMandatoryRecords(oTestUser);
    }

    @isTest static void test_OrderLineItemDAO() {

        User oTestUser = APTS_TestFacade.getTestUser();

        Test.startTest();

        System.runAs(oTestUser) {

            APTS_OrderLineItemDAO.getOrderLineItems(null);
            APTS_OrderLineItemDAO.getAllOrderLineItems(null);
            APTS_OrderLineItemDAO.getOrder(null);
            APTS_OrderLineItemDAO.getAssetLineItems(null);
            //APTS_OrderLineItemDAO.getAgreementLineItems(null);
            APTS_OrderLineItemDAO.getItemCategoryDetermination();
            APTS_OrderLineItemDAO.getItemRelevancyDetermination();
            APTS_OrderLineItemDAO.getWorkOrderTrigger(null);
            APTS_OrderLineItemDAO.getWorkOrderLineItem(null);
            APTS_OrderLineItemDAO.getAgreementPODetails(null);
            APTS_OrderLineItemDAO.getPhysicalAsset(null);
            APTS_OrderLineItemDAO.getOrderLineItemByParentOLI(null);
            APTS_OrderLineItemDAO.getAdjustmentLineItems(null);
            APTS_OrderLineItemDAO.getOrderAdjustmentLineItems(null);
            APTS_OrderLineItemDAO.getAssetAdjustmentLineItems(null);
            APTS_OrderLineItemDAO.getAccountLocation(null);
            APTS_OrderLineItemDAO.getOrderLineItemstoOrder(null);
        }

        Test.stopTest();
    }
}