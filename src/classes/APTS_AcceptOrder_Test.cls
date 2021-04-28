/*************************************************************
@Name: APTS_AcceptOrder_Test
@Author: Shanmuga Prasath
@CreateDate: 29-04-2019
@Description: Apex Class to test APTS_AcceptOrder Class 
******************************************************************/
@isTest
private with sharing class APTS_AcceptOrder_Test{
    
    private static final String PAGE_PARAM_ID = System.Label.APTS_Id;
    
    @testSetup static void setupTestData(){
        User oTestUser = APTS_TestFacade.createTestUser();
        APTS_TestFacade.createMandatoryRecords(oTestUser);
        APTS_TestFacade.createAndConfigureAgreement(oTestUser);
        APTS_TestFacade.createAndConfigureOrder(oTestUser);
    }
    
    @isTest static void test_createAdminOrderController(){
        
        PageReference pageRef = Page.APTS_AcceptOrder;
        Test.setCurrentPage(pageRef);
        
        Account oAccount = [SELECT Id FROM Account LIMIT 1];
        Apttus_Config2__Order__c  oOrder = [SELECT Id FROM Apttus_Config2__Order__c LIMIT 1];
        Apttus__APTS_Agreement__c  agreemnt = [SELECT Id FROM Apttus__APTS_Agreement__c  LIMIT 1];
        
        oOrder.APTS_SAP_OrderType__c = 'XA13';
        oOrder.Apttus_CMConfig__AgreementId__c = agreemnt.Id; 
        oOrder.APTS_Contract_Change__c = 'Yes';
        update oOrder;
        
        PhysicalAsset__c physical1 = new PhysicalAsset__c();
        physical1.SerialNumber__c = '211789';
        physical1.AssetStatus__c = 'Pending Activation';
        physical1.SoldTo__c = oAccount.Id; 
        insert physical1;
        
        Apttus_Config2__OrderLineItem__c oOLI = new Apttus_Config2__OrderLineItem__c();
        oOLI.Apttus_Config2__LineType__c = 'Product/Service';
        oOLI.Apttus_Config2__Status__c = 'Draft';
        oOLI.APTS_Status__c= 'Draft';
        oOLI.Apttus_Config2__LineStatus__c='Cancelled';
        oOLI.APTS_Serial_Number__c = '211789';
        oOLI.Apttus_Config2__LineNumber__c = 1; 
        oOLI.Apttus_CMConfig__AgreementId__c = agreemnt.Id;
        oOLI.APTS_Physical_Asset__c = physical1.id;
        oOLI.APTS_Type_of_Contract__c = 'Sales';
        oOLI.Apttus_Config2__ChargeType__c = 'Sales Price';
        oOLI.Apttus_Config2__OrderId__c = oOrder.id;
        oOLI.Apttus_Config2__SellingFrequency__c = 'Hourly';
        oOLI.APTS_Item_Relevant_for_SAP__c = true;
        Insert oOLI;
        
        APTS_Billing_Settings__c billingsetting = new APTS_Billing_Settings__c();
        billingsetting.APTS_Agreement_ID__c = agreemnt.id;
        billingsetting.APTS_Agreement_Billing_Type__c  = 'Machine';
        insert billingsetting;
        
        ApexPages.currentPage().getParameters().put(PAGE_PARAM_ID, oOrder.Id);
        ApexPages.currentPage().getParameters().put('type', System.Label.APTS_AdminOrder);
        
        User oTestUser = APTS_TestFacade.getTestUser();
        APTS_AcceptOrderQueue.doChainJob = false;
        Test.startTest();
        System.runAs(oTestUser){
             APTS_AcceptOrder controller = new APTS_AcceptOrder();
            controller.submitOrder();
        }
        Test.stopTest();
        
    }
    @isTest static void test_submitSAPDebit(){
        
        PageReference pageRef = Page.APTS_AcceptOrder;
        Test.setCurrentPage(pageRef);
        
        Account oAccount = [SELECT Id FROM Account LIMIT 1];
        Apttus_Config2__Order__c  oOrder = [SELECT Id FROM Apttus_Config2__Order__c LIMIT 1];
        Apttus__APTS_Agreement__c  agreemnt = [SELECT Id FROM Apttus__APTS_Agreement__c  LIMIT 1];
        
        oOrder.APTS_SAP_OrderType__c = 'XD01';
        oOrder.Apttus_CMConfig__AgreementId__c = agreemnt.Id; 
        update oOrder;
        ApexPages.currentPage().getParameters().put(PAGE_PARAM_ID, oOrder.Id);
        ApexPages.currentPage().getParameters().put('type', System.Label.APTS_AdminOrder);
        
        APTS_AcceptOrder controller = new APTS_AcceptOrder();
        controller.submitOrder();
    }
}