//-------------------------------------------------------------------------------------------
// Author       :   Catherine Aragon - Accenture
// Created Date :   March 14, 2017
// Usage        :   Test Class for BankDetailsTriggerHandler
//-------------------------------------------------------------------------------------------
@isTest
private class BankDetailsTriggerHandler_Test {
    
    //Description: This is for test setup of the test class
    static void testSetupDB(){
        
        //insert custom settings
        TriggerSettings__c ts = new TriggerSettings__c();
        ts.BankDetailsTrigger__c = true;
        insert ts;
        
        List<Bank_Details__c> bDetailList = new List<Bank_Details__c>();
        
        Bank_key__c bankKey = new Bank_key__c();
        bankKey.Conversion_ID__c = '123456709';
        insert bankKey;
        
        for(Bank_Details__c bDetail : TestDataFactory.createBankDetail(1)){
            bDetail.Bank_country__c = 'BE';
            bDetail.Bank_key__c = bankKey.id;
            bDetailList.add(bDetail);
        }
        
        insert bDetailList;
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
    
    private static testMethod void testPositive() {
        Profile p = [SELECT Id FROM Profile WHERE Name= 'System Administrator']; 
        User u = new User(Alias = 'standt',
                          Email='ample@testUser.com', 
                          EmailEncodingKey='UTF-8', 
                          LastName='Testing', 
                          LanguageLocaleKey='en_US',  
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', 
                          UserName='sample@testUser1111.com', 
                          Sales_Organization__c = 'SAP_0111', 
                          Elevated_Access_Reason__c = 'Defect or Incident Resolution', 
                          Elevated_Access_Reference__c = 'ASDF');
        insert u;
                
        System.runAs(u) {
            insert new TriggerSettings__c(BankDetailsTrigger__c = true);
            
            List<User> userList = createPRFSalesUsers();
            
            Bank_key__c bankKey = new Bank_key__c();
            bankKey.Conversion_ID__c = '234343434';
            insert bankKey;
            
            Account acc = new Account();
            acc.Name = 'accName';
            acc.Second_Account_Name__c = 'sAccName';
            acc.Sales_Organization__c = 'SAP_0111';
            //acc.Sales_Office__c = 'SAP_F020';
            acc.Phone = '+09238409384';
            insert acc;
    
            Bank_Details__c bank = new Bank_Details__c();
            bank.Bank_account__c = 'Bank acc';
            bank.Bank_country__c = 'SE';
            bank.Bank_key__c = bankKey.Id;
            bank.Collection_authorization__c = false;
            bank.Control_key__c = '21';
            bank.IBAN__c = 'IBAN';
            bank.Account__c = acc.Id;
            bank.Finance_Controller_BD_Validation__c = userList[0].id;
            insert bank;
            
            Bank_Details__c updateBankD = new Bank_Details__c();
            updateBankD = [SELECT Name, Bank_account__c, Bank_country__c,  Collection_authorization__c, Control_key__c, IBAN__c 
                                      FROM Bank_Details__c WHERE Id = :bank.Id];
                                      
            Bank_key__c bankKey1 = new Bank_key__c();
            bankKey1.Conversion_ID__c = '234343434';
            insert bankKey1;
    
            updateBankD.Approval_Bank_account__c = 'Update Bank acc1';
            updateBankD.Approval_Bank_country__c = 'DK';
            updateBankD.Approval_Collection_authorization__c = true;
            updateBankD.Approval_Bank_key__c = bankKey1.Id;
            updateBankD.Approval_Control_key__c = '80';
            updateBankD.Approval_IBAN__c = 'IBAN1';
            updateBankD.Updated_Request_Validation__c = 'Approval Validated';
           
            
            test.startTest();
            SM_CheckRecursive.run = true;
            update updateBankD;
            test.stopTest();
            //Bank_key__c,
            Bank_Details__c bDetails = [SELECT Name, Updated_Bank_account__c, Bank_account__c, Bank_country__c,  Collection_authorization__c, Control_key__c, IBAN__c 
                                        FROM Bank_Details__c WHERE Id = :updateBankD.Id];
    
            System.assertNotEquals(bDetails.Updated_Bank_account__c, Null);
         
        }
        
        BankDetailsTriggerHandler bankDetail = new BankDetailsTriggerHandler();
        
        List<SObject> newItems;
        List<SObject> oldList;
        Map<Id, SObject> oldItems;
        List<SObject> newList;
        Map<Id, SObject> newItemsMap;
        
        bankDetail.BeforeInsert(newItems); 
        bankDetail.BeforeDelete(oldList, oldItems);
        //bankDetail.AfterUpdate(newList, newItemsMap, oldList, oldItems);
        bankDetail.AfterDelete(oldList, oldItems);
        bankDetail.AfterUndelete(newList, newItemsMap);
    }
    
    private static testMethod void testPositiveSysad() {
        Profile p = [SELECT Id FROM Profile WHERE Name=: SM_Constants.JDEEndUser]; 
        User u = new User(Alias = 'standt',
                          Email='ample@testUser.com', 
                          EmailEncodingKey='UTF-8', 
                          LastName='Testing', 
                          LanguageLocaleKey='en_US',  
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', 
                          UserName='sample@testUser1111.com', 
                          Sales_Organization__c = 'SAP_0111', 
                          Elevated_Access_Reason__c = 'Defect or Incident Resolution', 
                          Elevated_Access_Reference__c = 'ASDF');
        insert u;
                
        System.runAs(u) {
            SM_CheckRecursive.run = true;
            insert new TriggerSettings__c(BankDetailsTrigger__c = true);
            
            Bank_key__c bankKey = new Bank_key__c();
            bankKey.Conversion_ID__c = '234343434';
            insert bankKey;
            
            Account acc = new Account();
            acc.Name = 'accName';
            acc.Second_Account_Name__c = 'sAccName';
            acc.Sales_Organization__c = 'SAP_0111';
            //acc.Sales_Office__c = 'SAP_F020';
            acc.Phone = '+09238409384';
            insert acc;
    
            Bank_Details__c bank = new Bank_Details__c();
            bank.Account__c = acc.Id;
            insert bank;
            
            Bank_Details__c updateBankD = new Bank_Details__c();
            updateBankD = [SELECT Name, Bank_account__c, Bank_country__c,  Collection_authorization__c, Control_key__c, IBAN__c 
                                      FROM Bank_Details__c WHERE Id = :bank.Id];
                                      
            Bank_key__c bankKey1 = new Bank_key__c();
            bankKey1.Conversion_ID__c = '234343434';
            insert bankKey1;
    
            updateBankD.Bank_account__c = 'Update Bank acc1';
            updateBankD.Bank_country__c = 'DK';
            updateBankD.Collection_authorization__c = true;
            updateBankD.Bank_key__c = bankKey1.Id;
            updateBankD.Control_key__c = '80';
            updateBankD.IBAN__c = 'IBAN1';
           
            
            test.startTest();
            SM_CheckRecursive.run = true;
            update updateBankD;
            test.stopTest();
            //Bank_key__c,
            Bank_Details__c bDetails = [SELECT Name, Updated_Bank_account__c, Bank_account__c, Bank_country__c,  Collection_authorization__c, Control_key__c, IBAN__c 
                                        FROM Bank_Details__c WHERE Id = :updateBankD.Id];
    
            System.assertNotEquals(bDetails.Bank_account__c, bDetails.Updated_Bank_account__c);
         
        }
        
        BankDetailsTriggerHandler bankDetail = new BankDetailsTriggerHandler();
        
        List<SObject> newItems;
        List<SObject> oldList;
        Map<Id, SObject> oldItems;
        List<SObject> newList;
        Map<Id, SObject> newItemsMap;
        
        bankDetail.BeforeInsert(newItems); 
        bankDetail.BeforeDelete(oldList, oldItems);
        //bankDetail.AfterUpdate(newList, newItemsMap, oldList, oldItems);
        bankDetail.AfterDelete(oldList, oldItems);
        bankDetail.AfterUndelete(newList, newItemsMap);
    }
    private static testMethod void testPositivenotSysad() {
        Profile p = [SELECT Id FROM Profile WHERE Name= 'System Administrator']; 
        User u = new User(Alias = 'standt',
                          Email='ample@testUser.com', 
                          EmailEncodingKey='UTF-8', 
                          LastName='Testing', 
                          LanguageLocaleKey='en_US',  
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', 
                          UserName='sample@testUser1111.com', 
                          Sales_Organization__c = 'SAP_0111', 
                          Elevated_Access_Reason__c = 'Defect or Incident Resolution', 
                          Elevated_Access_Reference__c = 'ASDF');
        insert u;
                
        System.runAs(u) {
            insert new TriggerSettings__c(BankDetailsTrigger__c = true);
            
            Bank_key__c bankKey = new Bank_key__c();
            bankKey.Conversion_ID__c = '234343434';
            insert bankKey;
            
            Account acc = new Account();
            acc.Name = 'accName';
            acc.Second_Account_Name__c = 'sAccName';
            acc.Sales_Organization__c = 'SAP_0111';
            //acc.Sales_Office__c = 'SAP_F020';
            acc.Phone = '+09238409384';
            insert acc;
    
            Bank_Details__c bank = new Bank_Details__c();
            bank.Account__c = acc.Id;
            insert bank;
            
            Bank_Details__c updateBankD = new Bank_Details__c();
            updateBankD = [SELECT Name, Bank_account__c, Bank_country__c,  Collection_authorization__c, Control_key__c, IBAN__c 
                                      FROM Bank_Details__c WHERE Id = :bank.Id];
                                      
            Bank_key__c bankKey1 = new Bank_key__c();
            bankKey1.Conversion_ID__c = '234343434';
            insert bankKey1;
    
            updateBankD.Approval_Bank_account__c = 'Update Bank acc1';
            updateBankD.Approval_Bank_country__c = 'DK';
            updateBankD.Approval_Collection_authorization__c = true;
            updateBankD.Approval_Bank_key__c = bankKey1.Id;
            updateBankD.Approval_Control_key__c = '80';
            updateBankD.Approval_IBAN__c = 'IBAN1';
           
            
            test.startTest();
            SM_CheckRecursive.run = true;
            update updateBankD;
            test.stopTest();
            //Bank_key__c,
            Bank_Details__c bDetails = [SELECT Name, Updated_Request_Validation__c 
                                        FROM Bank_Details__c WHERE Id = :updateBankD.Id];
    
            System.assertNotEquals(bDetails.Updated_Request_Validation__c, 'Approval Pending');
         
        }
        
        BankDetailsTriggerHandler bankDetail = new BankDetailsTriggerHandler();
        
        List<SObject> newItems;
        List<SObject> oldList;
        Map<Id, SObject> oldItems;
        List<SObject> newList;
        Map<Id, SObject> newItemsMap;
        
        bankDetail.BeforeInsert(newItems); 
        bankDetail.BeforeDelete(oldList, oldItems);
        //bankDetail.AfterUpdate(newList, newItemsMap, oldList, oldItems);
        bankDetail.AfterDelete(oldList, oldItems);
        bankDetail.AfterUndelete(newList, newItemsMap);
    }
    
    private static testMethod void testiLog() {
        insert new TriggerSettings__c(BankDetailsTrigger__c = true);
        
        List<User> userList = createPRFSalesUsers();
        
        Bank_key__c bankKey = new Bank_key__c();
        bankKey.Conversion_ID__c = '234343434';
        insert bankKey;
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.SAP_Customer_ID__c = 'QW12321';
        acc.Sales_Organization__c = 'SAP_0111';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+09238409384';
        insert acc;

        Bank_Details__c bank = new Bank_Details__c();
        bank.Bank_account__c = 'Update Bank acc';
        bank.Bank_country__c = 'SE';
        bank.Bank_key__c = bankKey.Id;
        bank.Collection_authorization__c = true;
        bank.Control_key__c = '21';
        bank.IBAN__c = 'IBAN';
        bank.Account__c = acc.Id;
        bank.Finance_Controller_BD_Validation__c = userList[0].id;
        insert bank;
        
        test.startTest();
        /*Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(bank.id);
        
        // Submit on behalf of a specific submitter
        req1.setSubmitterId(UserInfo.getUserId()); 
        
        // Submit the record to specific process and skip the criteria evaluation
        req1.setProcessDefinitionNameOrId('BD_Update_Request_Validation');
        req1.setSkipEntryCriteria(false);
        
        // Submit the approval request for the account
        Approval.ProcessResult result = Approval.process(req1);*/
        
        Bank_Details__c checkStatus = [SELECT Id, Reject_to_Transfer__c FROM Bank_Details__c WHERE Id = :bank.Id];
        
        checkStatus.Updated_Request_Validation__c = SM_Constants.ApprovalApproved;
        update checkStatus;
        system.assert(checkStatus.Updated_Request_Validation__c == SM_Constants.ApprovalApproved);

        Test.stopTest();
    }
    
    private static testMethod void testApproval() {
        insert new TriggerSettings__c(BankDetailsTrigger__c = true);
        
        List<User> userList = createPRFSalesUsers();
        
        Bank_key__c bankKey = new Bank_key__c();
        bankKey.Conversion_ID__c = '234343434';
        insert bankKey;
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0111';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+09238409384';
        insert acc;

        Bank_Details__c bank = new Bank_Details__c();
        bank.Bank_account__c = 'Update Bank acc';
        bank.Bank_country__c = 'SE';
        bank.Bank_key__c = bankKey.Id;
        bank.Collection_authorization__c = true;
        bank.Control_key__c = '21';
        bank.IBAN__c = 'IBAN';
        bank.Account__c = acc.Id;
        bank.Finance_Controller_BD_Validation__c = userList[0].id;
        insert bank;
        
        test.startTest();
        /*Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(bank.id);
        
        // Submit on behalf of a specific submitter
        req1.setSubmitterId(UserInfo.getUserId()); 
        
        // Submit the record to specific process and skip the criteria evaluation
        req1.setProcessDefinitionNameOrId('BD_Update_Request_Validation');
        req1.setSkipEntryCriteria(false);
        
        // Submit the approval request for the account
        Approval.ProcessResult result = Approval.process(req1);*/
        
        Bank_Details__c checkStatus = [SELECT Id, Reject_to_Transfer__c FROM Bank_Details__c WHERE Id = :bank.Id];
        system.assert(checkStatus.Reject_to_Transfer__c == false);
        
        checkStatus.Reject_to_Transfer__c = true;
        update checkStatus;
        system.assert(checkStatus.Reject_to_Transfer__c == true);

        Test.stopTest();
        
        List<ProcessInstanceWorkItem> ApprovalRequestList = [SELECT Id, ActorId, OriginalActorId, ProcessInstanceId FROM ProcessInstanceWorkitem piwi WHERE piwi.ProcessInstanceId in (SELECT Id FROM ProcessInstance WHERE TargetObjectId =: checkStatus.Id)];
        //system.assertEquals(ApprovalRequestList[0].ActorId, userList[0].Id);
    }
    
}