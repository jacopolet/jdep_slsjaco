/**************************************************************
 * @Author: jason.e.mactal
 * @Company: Accenture
 * @Description: Test class for APTS_ApprovalRequestTriggerHandler
 * @Created Date: May 3, 2018
 * @Revisions:
 *      <Name>              <Date>          <Description>
 *      jason.e.mactal      June 20, 2018   Initial Version
 * 
 *************************************************************/
@isTest
private class APTS_ApprovalRequestTriggerHandlerTest {

    @testSetup
    static void testSetup() {
        
        User testUser = APTS_TestDataFactory.createUser();
        insert testUser;
        
        Account oAcc = APTS_TestDataFactory.createAccount('Test Acc');
        insert oAcc;
        
        Apttus_Config2__Order__c oOrder = APTS_TestDataFactory.createOrder(oAcc.Id, null, null);
        insert oOrder;
        
        Apttus_Billing__Invoice__c oInv = new Apttus_Billing__Invoice__c();
        oInv.Apttus_Billing__BillToAccountId__c = oAcc.id;
        oInv.Apttus_Billing__TotalInvoiceAmount__c = 100;
        insert oInv;
        
        Apttus_Billing__CreditMemo__c oCreditMemo = new Apttus_Billing__CreditMemo__c();
        oCreditMemo.Apttus_Billing__BillToAccountId__c = oAcc.Id;
        oCreditMemo.Apttus_Billing__CreditAmount__c = 100;
        oCreditMemo.Apttus_Billing__Description__c = 'Test Credit Memo';
        oCreditMemo.Apttus_Billing__InvoiceID__c = oInv.Id;
        insert oCreditMemo;
        
        Apttus_Config2__Incentive__c oIncentive = new Apttus_Config2__Incentive__c();
        oIncentive.Apttus_Config2__Sequence__c = 1;
        oIncentive.Apttus_Config2__Status__c = 'Draft';
        insert oIncentive;
        
        Apttus_Rebate__IncentivePayoutSchedule__c incentPS = new Apttus_Rebate__IncentivePayoutSchedule__c();
        incentPS.Apttus_Rebate__IncentiveId__c = oIncentive.id;
        insert incentPS;
        
        
        insert new TriggerSettings__c(APTS_ApprovalRequestTrigger__c = true);
        

    }

	private static testMethod void updateLookupFieldsTest() {
	    user testUser = [SELECT Id FROM User WHERE Username = 'testuser123@jdecoffee.com'];
	    
	    Apttus_Config2__Order__c oOrder = [SELECT ID FROM Apttus_Config2__Order__c LIMIT 1];
	    Apttus_Billing__CreditMemo__c oCreditMemo = [SELECT ID FROM Apttus_Billing__CreditMemo__c LIMIT 1];
	    Apttus_Rebate__IncentivePayoutSchedule__c oIPS = [SELECT ID FROM Apttus_Rebate__IncentivePayoutSchedule__c LIMIT 1];
	    
	    List<Apttus_Approval__Approval_Request__c> oAppReqList = new List<Apttus_Approval__Approval_Request__c>();
	    
	    Apttus_Approval__Approval_Request__c oAppReqOrder = new Apttus_Approval__Approval_Request__c();
	    oAppReqOrder.Apttus_Approval__Object_Id__c = oOrder.Id;
	    oAppReqOrder.Apttus_Approval__Object_Type__c = 'Apttus_Config2__Order__c';
	    oAppReqList.add(oAppReqOrder);
	    
	    Apttus_Approval__Approval_Request__c oAppReqCM = new Apttus_Approval__Approval_Request__c();
	    oAppReqCM.Apttus_Approval__Object_Id__c = oCreditMemo.Id;
	    oAppReqCM.Apttus_Approval__Object_Type__c = 'Apttus_Billing__CreditMemo__c';
	    oAppReqList.add(oAppReqCM);

	    Apttus_Approval__Approval_Request__c oAppReqIPS = new Apttus_Approval__Approval_Request__c();
	    oAppReqIPS.Apttus_Approval__Object_Id__c = oIPS.Id;
	    oAppReqIPS.Apttus_Approval__Object_Type__c = 'Apttus_Rebate__IncentivePayoutSchedule__c';
	    oAppReqList.add(oAppReqIPS);
	    
        system.runAs(testUser) {
            test.startTest();
            insert oAppReqList;
            update oAppReqList;
            delete oAppReqList;
            undelete oAppReqList;
            test.stopTest();
        }
        Apttus_Approval__Approval_Request__c oAppReqOrderCheck = [SELECT ID, APTS_Related_Order__c FROM Apttus_Approval__Approval_Request__c WHERE APTS_Related_Order__c != null LIMIT 1];
        Apttus_Approval__Approval_Request__c oAppReqOrderCMCheck = [SELECT ID, APTS_Related_Credit_Memo__c FROM Apttus_Approval__Approval_Request__c WHERE APTS_Related_Credit_Memo__c != null LIMIT 1];
        Apttus_Approval__Approval_Request__c oAppReqOrderIPSCheck = [SELECT ID, APTS_Related_IncentivePayoutSchedule__c FROM Apttus_Approval__Approval_Request__c WHERE APTS_Related_IncentivePayoutSchedule__c != null LIMIT 1];
        
        system.assertEquals(oAppReqOrderCheck.APTS_Related_Order__c,oOrder.id);
        system.assertEquals(oAppReqOrderCMCheck.APTS_Related_Credit_Memo__c,oCreditMemo.id);
        system.assertEquals(oAppReqOrderIPSCheck.APTS_Related_IncentivePayoutSchedule__c,oIPS.id);
        
	}

}