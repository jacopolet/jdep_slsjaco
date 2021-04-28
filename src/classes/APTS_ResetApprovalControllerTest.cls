/*************************************************************
@Name: APTS_ResetApprovalController
@Author: Sneha Jaiwant
@CreateDate: 28-9-2020
@Description: Test Class for APTS_ResetApprovalController
******************************************************************/
@istest(SeeAllData = False)
public class APTS_ResetApprovalControllerTest{

@testSetup
static void testSetup() {
    
    User testUser = APTS_TestDataFactory.createUser();
    insert testUser;
    
    Account oAcc = APTS_TestDataFactory.createAccount('Test Acc');
    insert oAcc;
    
        Apttus_Config2__Order__c order= new Apttus_Config2__Order__c ();
        order.Apttus_Config2__Status__c = 'Draft';
        order.Approval_Status__c= 'Approval Pending';
        order.Apttus_Config2__OrderStartDate__c = Date.today();
        order.Apttus_Config2__OrderEndDate__c = Date.today() + 365;
        order.Apttus_Config2__BillToAccountId__c = oAcc.Id;
        order.Apttus_Config2__ShipToAccountId__c = oAcc.Id;
        order.Apttus_Config2__SoldToAccountId__c = oAcc.Id;
        order.APTS_Lock_Order__c = true;
        insert order;
        }

static testMethod void  methodTest(){
user testUser = [SELECT Id FROM User WHERE Username = 'testuser123@jdecoffee.com'];
  
  Apttus_Config2__Order__c oOrder = [SELECT ID FROM Apttus_Config2__Order__c where APTS_Lock_Order__c =:true AND Approval_Status__c =: 'Approval Pending' LIMIT 1];
  
   List<Apttus_Approval__Approval_Request__c> oAppReqList = new List<Apttus_Approval__Approval_Request__c>();
  
  Apttus_Approval__Approval_Request__c oAppReqOrder = new Apttus_Approval__Approval_Request__c();
  oAppReqOrder.Apttus_Approval__Object_Id__c = oOrder.Id;
  oAppReqOrder.Apttus_Approval__Object_Type__c = 'Apttus_Config2__Order__c';
  oAppReqOrder.Apttus_Approval__Approval_Status__c= 'Not Submitted';
  oAppReqOrder.APTS_Related_Order__c= oOrder.id;
 insert oAppReqOrder ;




    Test.StartTest();
    PageReference pageRef = Page.APTS_ResetApproval; 
    Apexpages.currentPage().getParameters().put('id',oAppReqOrder.APTS_Related_Order__c);
    APTS_ResetApprovalController cac = new APTS_ResetApprovalController ();
    cac.redirectURL();
   
      
    Test.StopTest();
}

}