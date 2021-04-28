/*************************************************************
@Name: APTS_OrderAdjustmentTriggerHandlerTest
@Author: Neev Shah
@CreateDate: 30-07-2018
@Description: Trigger on Order Adjustment Line Item
******************************************************************/
//v100 30-07-2018 Neev Shah: Initial version.

@isTest
public class APTS_OrderAdjustmentTriggerHandlerTest {
    @testSetup static void setupTestData() {
        User oTestUser = APTS_TestFacade.createTestUser();
        APTS_TestFacade.createMandatoryRecords(oTestUser);
        APTS_TestFacade.createAndConfigureAgreement(oTestUser);
        APTS_TestFacade.createAndConfigureOrder(oTestUser);
    }

    @isTest static void test_StandardReturnAdjustment() {
        User oTestUser = APTS_TestFacade.getTestUser();

        System.runAs(oTestUser) {
            Account oAccount = APTS_TestFacade.getAccount();
            Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder();
            List<Apttus_Config2__OrderLineItem__c> listOrderLineItems = APTS_TestFacade.getOrderLineItemList(oOrder.Id);
            List<Apttus_Config2__AssetLineItem__c> listAssets = APTS_TestFacade.getAssetLineItem();
            system.debug('listOrderLineItems = ' + listOrderLineItems);
            system.debug('listAssets = ' + listAssets);

            test.startTest();

            listOrderLineItems[0].Apttus_Config2__AssetLineItemId__c = listAssets[0].Id;
            listOrderLineItems[0].APTS_Returned_Quantity__c = 1;
            update listOrderLineItems[0];

            List<Apttus_Config2__OrderAdjustmentLineItem__c> listAdj = new List<Apttus_Config2__OrderAdjustmentLineItem__c>();
            Apttus_Config2__OrderAdjustmentLineItem__c oAdj = new Apttus_Config2__OrderAdjustmentLineItem__c();
            oAdj.Apttus_Config2__LineItemId__c = listOrderLineItems[0].Id;
            oAdj.Apttus_Config2__LineNumber__c = 1;
            oAdj.Apttus_Config2__IsModifiable__c = true;
            oAdj.Apttus_Config2__AdjustmentType__c = '% Discount';
            oAdj.Apttus_Config2__AdjustmentAmount__c = 10;
            oAdj.Apttus_Config2__Bucket__c = 'Bucket 1';
            oAdj.Apttus_Config2__AdjustmentAppliesTo__c = 'Starting Price';
            listAdj.add(oAdj);

            oAdj = new Apttus_Config2__OrderAdjustmentLineItem__c();
            oAdj.Apttus_Config2__LineItemId__c = listOrderLineItems[0].Id;
            oAdj.Apttus_Config2__LineNumber__c = 1;
            oAdj.Apttus_Config2__IsModifiable__c = true;
            oAdj.Apttus_Config2__AdjustmentType__c = 'Discount Amount';
            oAdj.Apttus_Config2__AdjustmentAmount__c = 10;
            oAdj.Apttus_Config2__Bucket__c = 'Bucket 1';
            oAdj.Apttus_Config2__AdjustmentAppliesTo__c = 'Starting Price';
            listAdj.add(oAdj);


            oAdj = new Apttus_Config2__OrderAdjustmentLineItem__c();
            oAdj.Apttus_Config2__LineItemId__c = listOrderLineItems[0].Id;
            oAdj.Apttus_Config2__LineNumber__c = 1;
            oAdj.Apttus_Config2__IsModifiable__c = true;
            oAdj.Apttus_Config2__AdjustmentType__c = '% Markup';
            oAdj.Apttus_Config2__AdjustmentAmount__c = 10;
            oAdj.Apttus_Config2__Bucket__c = 'Bucket 1';
            oAdj.Apttus_Config2__AdjustmentAppliesTo__c = 'Starting Price';
            listAdj.add(oAdj);


            oAdj = new Apttus_Config2__OrderAdjustmentLineItem__c();
            oAdj.Apttus_Config2__LineItemId__c = listOrderLineItems[0].Id;
            oAdj.Apttus_Config2__LineNumber__c = 1;
            oAdj.Apttus_Config2__IsModifiable__c = true;
            oAdj.Apttus_Config2__AdjustmentType__c = 'Markup Amount';
            oAdj.Apttus_Config2__AdjustmentAmount__c = 10;
            oAdj.Apttus_Config2__Bucket__c = 'Bucket 1';
            oAdj.Apttus_Config2__AdjustmentAppliesTo__c = 'Starting Price';
            listAdj.add(oAdj);

            oAdj = new Apttus_Config2__OrderAdjustmentLineItem__c();
            oAdj.Apttus_Config2__LineItemId__c = listOrderLineItems[0].Id;
            oAdj.Apttus_Config2__LineNumber__c = 1;
            oAdj.Apttus_Config2__IsModifiable__c = true;
            oAdj.Apttus_Config2__AdjustmentType__c = 'Price Override';
            oAdj.Apttus_Config2__AdjustmentAmount__c = 10;
            oAdj.Apttus_Config2__Bucket__c = 'Bucket 1';
            oAdj.Apttus_Config2__AdjustmentAppliesTo__c = 'Starting Price';
            listAdj.add(oAdj);
            insert listAdj;

            List<Apttus_Config2__OrderAdjustmentLineItem__c> listAdjUpdated = [SELECT ID FROM Apttus_Config2__OrderAdjustmentLineItem__c WHERE APTS_Return_Adjustment_Price__c <> NULL];
            system.assertNotEquals(NULL, listAdjUpdated);
            system.assertNotEquals(TRUE, listAdjUpdated.isEmpty());
            test.stopTest();

        }
    }
}