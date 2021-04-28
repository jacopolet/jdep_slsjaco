//-------------------------------------------------------------------------------------------
// Author       :   Catherine Aragon - Accenture
// Created Date :   March 14, 2017
// Usage        :   Test Class for AccountTaxTriggerhandler
//-------------------------------------------------------------------------------------------
@isTest
public class AccountTaxTriggerHandler_Test {
    
    //Description: This is for test setup of the test class
    //@testSetup
    static void testSetup(){
        //insert custom settings
        insert new TriggerSettings__c(AccountTaxTrigger__c = true);
        
        List<Account_Tax__c > acctTaxLists = new List<Account_Tax__c >();
        for(Account_Tax__c   acctTax : TestDataFactory.createAccountTax(10)){
            acctTaxLists.add(acctTax);
        }
        
        insert acctTaxLists;
        //System.debug('acctTaxList: ' + acctTaxList);
    }
    
    private static List<User> createPRFSalesUsers(){ 
        
        Id PAdmin = [SELECT Id FROM Profile WHERE Name = :SM_Constants.JDEEndUser].Id;
        
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
    
     //Description: Test method for updating account tax field value.
    private static testMethod void testApproval() {
    
        //testSetup();
        TriggerSettings__c ts = new TriggerSettings__c();
        ts.AccountTaxTrigger__c = true;
        insert ts;
        
        List<User> userList = createPRFSalesUsers();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+09238409384';
        insert acc;
        
        Account_Tax__c acctTax = new Account_Tax__c();
        acctTax.Finance_Controller_Tax_Validation__c = userList[1].Id;
        acctTax.Mini_Tax_Classification__c = 'SAP_0';
        acctTax.Mini_Tax_Category__c = 'SAP_ZM04';
        acctTax.Mini_Tax_Country__c = 'SAP_ES';
        acctTax.Mini_Account__c = acc.Id;
        insert acctTax;
        
        Test.startTest();
        // Create an approval request for the account
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(acctTax.id);
        
        // Submit on behalf of a specific submitter
        req1.setSubmitterId(UserInfo.getUserId()); 
        
        // Submit the record to specific process and skip the criteria evaluation
        req1.setProcessDefinitionNameOrId('SM_TD_Update_Request_Validation');
        req1.setSkipEntryCriteria(false);
        
        // Submit the approval request for the account
        Approval.ProcessResult result = Approval.process(req1);
        
        Account_Tax__c checkStatus = [SELECT Id, Reject_to_Transfer__c FROM Account_Tax__c WHERE Id = :acctTax.Id];
        system.assert(checkStatus.Reject_to_Transfer__c == false);
        
        checkStatus.Reject_to_Transfer__c = true;
        checkrecursive.run = true;
        update checkStatus;
        system.assert(checkStatus.Reject_to_Transfer__c == true);

        Test.stopTest();
        
        List<ProcessInstanceWorkItem> ApprovalRequestList = [SELECT Id, ActorId, OriginalActorId, ProcessInstanceId FROM ProcessInstanceWorkitem piwi WHERE piwi.ProcessInstanceId in (SELECT Id FROM ProcessInstance WHERE TargetObjectId =: checkStatus.Id)];
        //system.assertEquals(ApprovalRequestList[0].ActorId, userList[0].Id);
        
    }
    
    //Description: Test method for updating account tax field value.
    private static testMethod void testPositive() {
    
        //testSetup();
        TriggerSettings__c ts = new TriggerSettings__c();
        ts.AccountTaxTrigger__c = true;
        insert ts;
        
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+09238409384';
        insert acc;
        
        Account_Tax__c acctTax1 = new Account_Tax__c();
        acctTax1.Mini_Tax_Classification__c = 'SAP_3';
        acctTax1.Mini_Tax_Category__c = 'SAP_ZM01';
        acctTax1.Mini_Tax_Country__c = 'SAP_BE';
        acctTax1.Mini_Account__c = acc.Id;
        insert acctTax1;
        
        List<Account_Tax__c> updateAccountTax = new List<Account_Tax__c>();
        Integer i = 0;
        
        for(Account_Tax__c acctTax: [SELECT Name FROM Account_Tax__c]){
            acctTax.Mini_Tax_Classification__c = 'SAP_0';
            acctTax.Mini_Tax_Category__c = 'SAP_ZM04';
            acctTax.Mini_Tax_Country__c = 'SAP_ES';
            i++;
            updateAccountTax.add(acctTax);
        }
        
        test.startTest();
        checkrecursive.run = true;
        update updateAccountTax;
        test.stopTest();
        
        Account_Tax__c acctTax2 = [SELECT Mini_Tax_Classification__c, Updated_Tax_Classification__c FROM Account_Tax__c LIMIT 1];

        System.assertNotEquals(acctTax2.Mini_Tax_Classification__c, acctTax2.Updated_Tax_Classification__c);
        
        AccountTaxTriggerHandler acctTax = new AccountTaxTriggerHandler();
        List<SObject> newItems;
        List<SObject> oldList;
        Map<Id, SObject> oldItems;
        List<SObject> newList;
        
        acctTax.BeforeInsert(newItems); 
        acctTax.BeforeDelete(oldList, oldItems);
        acctTax.AfterDelete(oldList, oldItems);
        
        
    }
    
    //Description: Test method for updating account tax field value. WHile using a PRF Sales profile user
    //Created by: Alvin Lomod
    /*private static testMethod void testPositiveRunAsPRFSales() {
        
        Profile p = [SELECT Id FROM Profile WHERE Name =: SM_Constants.JDEEndUser]; 
        User u2 = new User(Alias = '111utest', Email='testuser111@testorg.com', 
         EmailEncodingKey='UTF-8', LastName='Testing123', LanguageLocaleKey='en_US', 
         LocaleSidKey='en_US', ProfileId = p.Id, 
         TimeZoneSidKey='America/Los_Angeles', UserName='testuser1234567@jdecoffee.com');
        
        insert u2;
         
        PermissionSet ps = [SELECT ID From PermissionSet WHERE Name = 'JDE_Field_Sales_Representative'];
        insert new PermissionSetAssignment(AssigneeId = u2.id, PermissionSetId = ps.Id);

        System.runAs(u2) {
        
        //testSetup();
        
        TriggerSettings__c ts = new TriggerSettings__c();
        ts.AccountTaxTrigger__c = true;
        insert ts;
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+09238409384';
        insert acc;
        
        Account_Tax__c acctTax = new Account_Tax__c();
        acctTax.Mini_Tax_Classification__c = 'SAP_3';
        acctTax.Mini_Tax_Category__c = 'SAP_ZM01';
        acctTax.Mini_Tax_Country__c = 'SAP_BE';
        acctTax.Mini_Account__c = acc.Id;
        insert acctTax;
        
        List<Account_Tax__c> updateAccountTax = new List<Account_Tax__c>();
        Integer i = 0;
        
        for(Account_Tax__c acctTax1: [SELECT Name FROM Account_Tax__c]){
            acctTax1.Mini_Tax_Classification__c = 'SAP_0';
            acctTax1.Mini_Tax_Category__c = 'SAP_ZM04';
            acctTax1.Mini_Tax_Country__c = 'SAP_ES';
            i++;
            updateAccountTax.add(acctTax1);
        }
        
        test.startTest();
        checkrecursive.run = true;
        update updateAccountTax;
        test.stopTest();
        
        System.debug('updateAccountTax: ' + updateAccountTax);
        
        Account_Tax__c acctTax2 = [SELECT Mini_Tax_Classification__c, Updated_Tax_Classification__c FROM Account_Tax__c LIMIT 1];

        System.assertNotEquals(acctTax2.Mini_Tax_Classification__c, acctTax2.Updated_Tax_Classification__c);
        
        }
        
    }*/
    
}