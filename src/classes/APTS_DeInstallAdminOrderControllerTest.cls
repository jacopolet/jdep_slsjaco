/*************************************************************
@Name: APTS_DeInstallAdminOrderControllerTest
@Author: Shanmuga Prasarh
@CreateDate: 08-06-2018
@Description: Test class for APTS_DeInstallAdminOrderController
@UsedBy: 
******************************************************************/

@isTest
private with sharing class APTS_DeInstallAdminOrderControllerTest{
    
    private static final String PAGE_PARAM_ID = System.Label.APTS_Id;
    
     @testSetup static void setupTestData() {

        User oTestUser = APTS_TestFacade.createTestUser();
        APTS_TestFacade.createMandatoryRecords(oTestUser);
        APTS_TestFacade.createAndConfigureAgreement(oTestUser);
        APTS_TestFacade.createAndConfigureOrder(oTestUser);
    }
    
       @isTest static void test_DeInstallAdminOrderController() {
        
        PageReference pageRef = Page.APTS_DeInstallAdminOrder;
        Test.setCurrentPage(pageRef); 

        Id RecId = Schema.SObjectType.Apttus_Config2__Order__c.getRecordTypeInfosByName().get('Admin Order').getRecordTypeId();
        User oTestUser = APTS_TestFacade.getTestUser();
        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getMachineOrder();
        oOrder.APTS_Order_Type__c = 'Admin Order';
        oOrder.RecordTypeId = RecId;
        oOrder.APTS_Order_Sub_Type__c = 'Installation';
        Database.Update(oOrder, false);
        
        List<Apttus_Config2__OrderLineItem__c> orderLineItemList = APTS_TestFacade.getOrderLineItemList(oOrder.Id);
        Apttus__APTS_Agreement__c oAgreement = APTS_TestFacade.getAgreement('Cancelled Agreement');
        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestFacade.getMachineProductConfiguration();
        List<Apttus__AgreementLineItem__c> agreementLineItemList = APTS_TestFacade.getAgreementLineItem(oAgreement.Id);
        List<Apttus_Config2__AssetLineItem__c> assetLineItemList = APTS_TestFacade.getAssetLineItem();        
        assetLineItemList[0].APTS_Sub_Status__c = 'Temporary Deactivated';
        update assetLineItemList;
        
        for(Apttus_Config2__OrderLineItem__c ordLineItem : orderLineItemList){
            ordLineItem.Apttus_Config2__AssetLineItemId__c = assetLineItemList.get(0).Id;   
        }
        Database.update(orderLineItemList);
        oOrder.Apttus_CMConfig__AgreementId__c = oAgreement.Id;
        Database.update(oOrder);
        
        Test.startTest();

        System.runAs(oTestUser) {

            ApexPages.currentPage().getParameters().put(PAGE_PARAM_ID, oOrder.Id);

            APTS_DeInstallAdminOrderController oDeInstallAdminOrderController = new APTS_DeInstallAdminOrderController();

            oDeInstallAdminOrderController.getAssets();
            oDeInstallAdminOrderController.assetLineItemWrapperList[0].selected = true;
            oDeInstallAdminOrderController.deinstallAssets();
            oDeInstallAdminOrderController.back();
        }

        Test.stopTest();
        
    }
      @isTest static void test_RAdminOrderController() {
      
        PageReference pageRef = Page.APTS_DeInstallAdminOrder;
        Test.setCurrentPage(PageRef); 

        Id RecId = Schema.SObjectType.Apttus_Config2__Order__c.getRecordTypeInfosByName().get('Admin Order').getRecordTypeId();
        User oTestUser = APTS_TestFacade.getTestUser();
        
        Apttus_Config2__Order__c oOrderRenewal = APTS_TestFacade.getMachineOrder();
        oOrderRenewal.APTS_Order_Type__c = 'Admin Order';
        oOrderRenewal.RecordTypeId = RecId;
        oOrderRenewal.APTS_Order_Sub_Type__c = 'Renewal';
        Database.Update(oOrderRenewal, false);
        
        List<Apttus__AgreementLineItem__c> aLIList = APTS_TestFacade.getProductAgLineItem('Bundle');
        
        List<Apttus_Config2__OrderLineItem__c> orderLineItemList = APTS_TestFacade.getOrderLineItemList(oOrderRenewal.Id);
        Apttus__APTS_Agreement__c oAgreement = APTS_TestFacade.getAgreement('Cancelled Agreement');
        oAgreement.Apttus__Status__c = 'In Effect';
        oAgreement.Apttus__Status_Category__c = 'Activated';
        Database.Update(oAgreement, false);
        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestFacade.getMachineProductConfiguration();
        List<Apttus__AgreementLineItem__c> agreementLineItemList = APTS_TestFacade.getAgreementLineItem(oAgreement.Id);
        List<Apttus_Config2__AssetLineItem__c> assetLineItemList = APTS_TestFacade.getAssetLineItem();        

        
        for(Apttus_Config2__OrderLineItem__c ordLineItem : orderLineItemList){
            ordLineItem.Apttus_Config2__AssetLineItemId__c = assetLineItemList.get(0).Id;   
        }
        Database.update(orderLineItemList);
        
        for(Apttus__AgreementLineItem__c aLI : aLIList){
            aLI.Apttus_CMConfig__AssetLineItemId__c = assetLineItemList.get(0).Id; 
            //aLI.Apttus__AgreementId__c = oAgreement.Id;
            aLI.Apttus_CMConfig__LineStatus__c = 'Renewed';
        }
        Database.update(aLIList);
        
        oOrderRenewal.Apttus_CMConfig__AgreementId__c = oAgreement.Id;
        Database.update(oOrderRenewal);
        
        Test.startTest();

        System.runAs(oTestUser) {

            ApexPages.currentPage().getParameters().put(PAGE_PARAM_ID, oOrderRenewal.Id);
            APTS_DeInstallAdminOrderController oDeInstallAdminOrderController = new APTS_DeInstallAdminOrderController();
            oDeInstallAdminOrderController.getAssets();
            oDeInstallAdminOrderController.assetLineItemWrapperList.get(0).selected = true;
            oDeInstallAdminOrderController.deinstallAssets();
            oDeInstallAdminOrderController.back();
        }

        Test.stopTest();
    }
    @isTest static void test_installOrderController() {
    
        PageReference pageRef = Page.APTS_DeInstallAdminOrder;
        Test.setCurrentPage(pageRef);
           
        Id RecId = Schema.SObjectType.Apttus_Config2__Order__c.getRecordTypeInfosByName().get('Admin Order').getRecordTypeId();
        User oTestUser = APTS_TestFacade.getTestUser();
        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getMachineOrder();
        oOrder.APTS_Order_Type__c = 'Admin Order';
        oOrder.RecordTypeId = RecId;
        oOrder.APTS_Order_Sub_Type__c = 'De-installation';
        Database.Update(oOrder, false);
        
        List<Apttus_Config2__OrderLineItem__c> orderLineItemList = APTS_TestFacade.getOrderLineItemList(oOrder.Id);
        Apttus__APTS_Agreement__c oAgreement = APTS_TestFacade.getAgreement('Cancelled Agreement');
        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestFacade.getMachineProductConfiguration();
        List<Apttus__AgreementLineItem__c> agreementLineItemList = APTS_TestFacade.getAgreementLineItem(oAgreement.Id);
        List<Apttus_Config2__AssetLineItem__c> assetLineItemList = APTS_TestFacade.getAssetLineItem();        

        
        for(Apttus_Config2__OrderLineItem__c ordLineItem : orderLineItemList){
            ordLineItem.Apttus_Config2__AssetLineItemId__c = assetLineItemList.get(0).Id;   
        }
        Database.update(orderLineItemList);
        oOrder.Apttus_CMConfig__AgreementId__c = oAgreement.Id;
        Database.update(oOrder);
        
        Test.startTest();

        System.runAs(oTestUser) {

            ApexPages.currentPage().getParameters().put(PAGE_PARAM_ID, oOrder.Id);
            APTS_DeInstallAdminOrderController oDeInstallAdminOrderController = new APTS_DeInstallAdminOrderController();
            oDeInstallAdminOrderController.getAssets();
            oDeInstallAdminOrderController.assetLineItemWrapperList[0].selected = true;
            oDeInstallAdminOrderController.deinstallAssets();
            oDeInstallAdminOrderController.back();
        }

        Test.stopTest();
        
    }
}