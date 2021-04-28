/**
 * This class contains unit tests for validating the behavior of PreBidApprovalTriggerHandler
 *
 */
//-------------------------------------------------------------------------------------------//
// Author       :   Alvin Lomod - Accenture
// Created Date :   December 04, 2017
// Usage        :   
// Updates      :   
//-------------------------------------------------------------------------------------------//
@isTest
private class PreBidApprovalTriggerHandlerTest{
    
        
    private static List<User> createPRFSalesUsers(){ 
        
        Id PAdmin = [SELECT Id FROM Profile WHERE Name = 'JDE - End User - Basic Internal'].Id;
        
        User PRFSalesUser = new User(alias = 'testmgr', email='testPRF12345@noemail.com',
                emailencodingkey='UTF-8', lastname='LastNamePRF', firstName = 'FirstNamePRF', languagelocalekey='en_US',
                localesidkey='en_US', profileid = PAdmin, country='United States',IsActive =true, //userroleId = RAdmin,
                Sales_Organization__c = 'SAP_0333',
                timezonesidkey='America/Los_Angeles', username='testPRF12345@noemail.com');
        
        User PRFSalesMGR = new User(alias = 'testPRF', email='testPRFMgr67890@noemail.com',
                emailencodingkey='UTF-8', lastname='LastNameMGR', firstName = 'FirstNameMGR', languagelocalekey='en_US',
                localesidkey='en_US', profileid = PAdmin, country='United States',IsActive =true, //userroleId = RAdmin,
                Sales_Organization__c = 'SAP_0333',
                timezonesidkey='America/Los_Angeles', username='testPRFMgr67890@noemail.com');
        insert PRFSalesMgr;
        
        PRFSalesUser.ManagerId = PRFSalesMgr.Id;
        
        insert PRFSalesUser;
        
        List<User> UserToCreate = new List<User>();
        UserToCreate.add(PRFSalesMgr);
        UsertoCreate.add(PRFSalesUser);
        
        //insert UserToCreate;
        system.debug(UserToCreate);
        return UserToCreate;
        
    }
    
    
    static testMethod void PreBidApprovalTest(){
        
        List<User> userList = createPRFSalesUsers();
        insert new TriggerSettings__c(PreBidApprovalTrigger__c = true);
                
        Account acc = new Account() ;
        acc.Name = 'Test Partner Account';
        acc.Sales_Organization__c = 'SAP_0333';
        acc.Phone = '+0987654321';
        acc.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.Customer).getRecordTypeId();
        acc.Main_Street_Only__c = 'Test Street';
        acc.Account_Type__c = 'Customer';
        insert acc; 
        
        Contact con = new Contact();
        con.FirstName = 'FirstNamePartner';
        con.LastName = 'LastNamePartner';
        con.AccountId = acc.Id;
        con.Phone = '+0987654321';
        con.Title = 'Tester';
        insert con;  
        
        Opportunity opp = new Opportunity();
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(SM_Constants.OpptRecTypeTender).getRecordTypeId();
        opp.AccountId = acc.Id;
        opp.Type = 'Public';
        opp.CloseDate = Date.Today().addDays(10);
        opp.StageName = 'Open';
        opp.Name = 'Test Tender Opportunity';
        insert Opp;       
        
        Pre_Bid_Approval__c pba = new Pre_Bid_Approval__c();
        pba.User__c = userList[1].Id;
        pba.Name = 'TEST PBA';
        pba.Opportunity__c = opp.Id;
        pba.Department__c = 'BPO';
        insert pba;
        
        Test.startTest();
        
        // Create an approval request for the account
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(pba.id);
        
        // Submit on behalf of a specific submitter
        req1.setSubmitterId(UserInfo.getUserId()); 
        
        // Submit the record to specific process and skip the criteria evaluation
        req1.setProcessDefinitionNameOrId('Pre_Bids_Approvals');
        req1.setSkipEntryCriteria(false);
        
        // Submit the approval request for the account
        Approval.ProcessResult result = Approval.process(req1);
        
        Pre_Bid_Approval__c checkPBA = [SELECT Id, Approval_Status__c FROM Pre_Bid_Approval__c WHERE Id =: pba.Id LIMIT 1];
        system.assert(checkPBA.Approval_Status__c == 'Pending Approval');
        
        
        checkPBA.Approval_Status__c = 'Reject To Transfer';
        update checkPBA;

        Test.stopTest();
        
        List<ProcessInstanceWorkItem> ApprovalRequestList = [SELECT Id, ActorId, OriginalActorId, ProcessInstanceId FROM ProcessInstanceWorkitem piwi WHERE piwi.ProcessInstanceId in (SELECT Id FROM ProcessInstance WHERE TargetObjectId =: checkPBA.Id)];
        system.assertEquals(ApprovalRequestList[0].ActorId, userList[0].Id);
        
    }
    
    static testMethod void UpdateDelUndelTest(){
        
        Test.startTest();
        
        insert new TriggerSettings__c(PreBidApprovalTrigger__c = true);
                
        Account acc = new Account() ;
        acc.Name = 'Test Partner Account';
        acc.Sales_Organization__c = 'SAP_0333';
        acc.Phone = '+0987654321';
        acc.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.Customer).getRecordTypeId();
        acc.Main_Street_Only__c = 'Test Street';
        acc.Account_Type__c = 'Customer';
        insert acc; 
        
        Contact con = new Contact();
        con.FirstName = 'FirstNamePartner';
        con.LastName = 'LastNamePartner';
        con.AccountId = acc.Id;
        con.Phone = '+0987654321';
        con.Title = 'Tester';
        insert con;  
        
        Opportunity opp = new Opportunity();
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(SM_Constants.OpptRecTypeTender).getRecordTypeId();
        opp.AccountId = acc.Id;
        opp.Type = 'Public';
        opp.CloseDate = Date.Today().addDays(10);
        opp.StageName = 'Open';
        opp.Name = 'Test Tender Opportunity';
        insert Opp;        
        
        Pre_Bid_Approval__c pba = new Pre_Bid_Approval__c();
        pba.User__c = UserInfo.getUserId();
        pba.Name = 'TEST PBA';
        pba.Opportunity__c = opp.Id;
        pba.Department__c = 'BPO';
        insert pba;
        
        pba.Name = 'TEST PBA 2';
        
        update pba;
        delete pba;
        undelete pba;       
        
        List<Pre_Bid_Approval__c> undelPBA = [SELECT Id FROM Pre_Bid_Approval__c];
        system.assert(undelPBA.size() > 0);

        Test.stopTest();
        
        
    }
    
    static testMethod void TestTriggerOff(){
        
        insert new TriggerSettings__c(PreBidApprovalTrigger__c = false);
        
        PreBidApprovalTriggerHandler userhandler = new PreBidApprovalTriggerHandler();
        TriggerDispatcher.Run(userhandler);
        
        TriggerSettings__c ts = TriggerSettings__c.getInstance();
        system.assertEquals(false, ts.PreBidApprovalTrigger__c);
    
    }
    
    
    
}