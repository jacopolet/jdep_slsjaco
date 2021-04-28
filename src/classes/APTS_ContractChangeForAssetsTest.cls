/*************************************************************
@Name: APTS_ContractChangeForAssets
@Author: Lavanya
@CreateDate: jan 1 2020
@Description: Test class for APTS_ContractChangeForAssets Class
@UsedBy: 
******************************************************************/
@isTest
private with sharing class APTS_ContractChangeForAssetsTest{
    
    private static final String PAGE_PARAM_ID = System.Label.APTS_Id;
    
    @testSetup static void setupTestData(){
        User oTestUser = APTS_TestFacade.createTestUser();
        APTS_TestFacade.createMandatoryRecords(oTestUser);
        APTS_TestFacade.createAndConfigureAgreement(oTestUser);
    }
    
    @isTest static void test_createContractChangeforAssets(){
        
        PageReference pageRef = Page.APTS_ContractChangeForAssets;
        Test.setCurrentPage(pageRef);
        
        Account oAccount = [SELECT Id FROM Account LIMIT 1];
        ApexPages.currentPage().getParameters().put(PAGE_PARAM_ID, oAccount.Id);
        ApexPages.currentPage().getParameters().put('type', System.Label.APTS_AdminOrder);
        
        User oTestUser = APTS_TestFacade.getTestUser();
        Test.startTest();
        System.runAs(oTestUser){
            APTS_ContractChangeForAssets createConversionOrderController = new APTS_ContractChangeForAssets();
            //createConversionOrderController.getOrderSubTypePicklist();
            createConversionOrderController.createOrder();
            createConversionOrderController.setOrderSubType();
            createConversionOrderController.agreementWrapperList.get(0).selected = true;
            createConversionOrderController.back();
            createConversionOrderController.proceedNext();
        }

        Test.stopTest();
        
    }
}