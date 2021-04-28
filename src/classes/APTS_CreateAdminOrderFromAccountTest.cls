/*************************************************************
@Name: APTS_CreateAdminOrderFromAccountTest
@Author: Shanmuga Prasath
@CreateDate: 08-06-2018
@Description: Test class for APTS_CreateAdminOrderFromAccount Class
@UsedBy: 
******************************************************************/
@isTest
private with sharing class APTS_CreateAdminOrderFromAccountTest{
    
    private static final String PAGE_PARAM_ID = System.Label.APTS_Id;
    
    @testSetup static void setupTestData(){
        User oTestUser = APTS_TestFacade.createTestUser();
        APTS_TestFacade.createMandatoryRecords(oTestUser);
        APTS_TestFacade.createAndConfigureAgreement(oTestUser);
    }
    
    @isTest static void test_createAdminOrderController(){
        
        PageReference pageRef = Page.APTS_CreateAdminOrderFromAccount;
        Test.setCurrentPage(pageRef);
        
        Account oAccount = [SELECT Id FROM Account LIMIT 1];
        ApexPages.currentPage().getParameters().put(PAGE_PARAM_ID, oAccount.Id);
        ApexPages.currentPage().getParameters().put('type', System.Label.APTS_AdminOrder);
        
        User oTestUser = APTS_TestFacade.getTestUser();
        Test.startTest();
        System.runAs(oTestUser){
            APTS_CreateAdminOrderFromAccount createAdminOrderController = new APTS_CreateAdminOrderFromAccount();
            createAdminOrderController.getOrderSubTypePicklist();
            createAdminOrderController.createOrder();
            createAdminOrderController.setOrderSubType();
            createAdminOrderController.agreementWrapperList.get(0).selected = true;
            createAdminOrderController.back();
            createAdminOrderController.proceedNext();
        }

        Test.stopTest();
        
    }
}