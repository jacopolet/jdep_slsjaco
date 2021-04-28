/*************************************************************
@Name: APTS_ConversionOrderFromAccountTest
@Author: Shanmuga Prasath/Jagan
@CreateDate: 29-04-2019
@Description: Test class for APTS_CreateConversionOrderFromAccount Class
@UsedBy: 
******************************************************************/
@isTest
private with sharing class APTS_ConversionOrderFromAccountTest{
    
    private static final String PAGE_PARAM_ID = System.Label.APTS_Id;
    
    @testSetup static void setupTestData(){
        User oTestUser = APTS_TestFacade.createTestUser();
        APTS_TestFacade.createMandatoryRecords(oTestUser);
        APTS_TestFacade.createAndConfigureAgreement(oTestUser);
    }
    
    @isTest static void test_createAdminOrderController(){
        
        PageReference pageRef = Page.APTS_ConversionOrderFromAccount;
        Test.setCurrentPage(pageRef);
        
        Account oAccount = [SELECT Id FROM Account LIMIT 1];
        ApexPages.currentPage().getParameters().put(PAGE_PARAM_ID, oAccount.Id);
        ApexPages.currentPage().getParameters().put('type', System.Label.APTS_AdminOrder);
        
        User oTestUser = APTS_TestFacade.getTestUser();
        Test.startTest();
        System.runAs(oTestUser){
            APTS_ConversionOrderFromAccount createConversionOrderController = new APTS_ConversionOrderFromAccount();
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