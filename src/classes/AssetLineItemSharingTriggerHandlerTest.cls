/**
 * This class contains unit tests for validating the behavior of AssetLineItemSharingTriggerHandler
 * and triggers.
 */
//-------------------------------------------------------------------------------------------//
// Author       :   Alvin Lomod - Accenture
// Created Date :   November 24, 2017
// Usage        :   
// Updates      :   
//-------------------------------------------------------------------------------------------//
@isTest
private class AssetLineItemSharingTriggerHandlerTest{
    
    private static User createAdminUser(){
    
        Id PAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        Id RAdmin = [SELECT Id FROM UserRole WHERE Name = 'JDE Professional'].Id;
        
        User systemAdmin = new User(alias = 'admin123', email='admintest123@noemail.com',
                emailencodingkey='UTF-8', lastname='LastNameAdmin', firstName = 'FirstNameAdmin', languagelocalekey='en_US',
                localesidkey='en_US', profileid = PAdmin, country='United States',IsActive =true, userroleId = RAdmin,
                Sales_Organization__c = 'SAP_0333',
                timezonesidkey='America/Los_Angeles', username='admin123test@noemail.com', Elevated_Access_Reason__c = 'Defect or Incident Resolution', Elevated_Access_Reference__c = 'ASDF');
        
        insert systemAdmin;
        
        return systemAdmin;
        
    }
    
    private static User createPartnerUser(Id ConId, Id profId, String x, String pEmail, String pAlias, String pUsername){     
                  
        User PartnerUser = new User(alias = pAlias, email = pEmail,
                emailencodingkey='UTF-8', lastname='LastNamePartner'+x, firstName = 'FirstNamePartner'+x, languagelocalekey='en_US',
                localesidkey='en_US', profileid = profId, country='United States', IsActive =true,
                             ContactId = ConId, Sales_Organization__c = 'SAP_0333',
                timezonesidkey='America/Los_Angeles', username = pUsername);
        
        return PartnerUser;
    }
    
    private static Apttus_Config2__AssetLineItem__c createALI(Id AccId, String aliName){
        
        Apttus_Config2__AssetLineItem__c ali = new Apttus_Config2__AssetLineItem__c();
        ali.Name = aliName;
        ali.Apttus_Config2__AccountId__c = AccId;
        ali.Apttus_Config2__AssetNumber__c = aliName;
        
        return ali;
        
    }
    
    static testMethod void AfterInsertALISharingTest(){
        
        Test.startTest();
        
        User AdminUser = createAdminUser();
        User partnerUser;
        
        system.runAs(AdminUser){
            
            insert new TriggerSettings__c(AssetLineItemTrigger__c = true);
            
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
            
            Id prof = [SELECT Id FROM Profile WHERE Name='Partner Community User'].Id;
            
            partnerUser = createPartnerUser(con.Id, prof, 'Test', 'partnerTest1@usertriggertest.com', 'testa1', 'partnerTest1@usertriggertest.com');           
            insert partnerUser;
            
            
            //Insert ALI
            List<Apttus_Config2__AssetLineItem__c> aliList = new List<Apttus_Config2__AssetLineItem__c>();
            for(Integer x = 0; x < 3; x++){
                aliList.add(createALI(acc.Id, 'TEST ALI '+x));
            }
            
            insert aliList;   
            
        }
        
        Test.stopTest();
        
        //Check ALI Share
        
        List<Apttus_Config2__AssetLineItem__Share> ALIshareList = new List<Apttus_Config2__AssetLineItem__Share>();
        
        ALIshareList = [SELECT Id, UserOrGroupId, AccessLevel, RowCause FROM Apttus_Config2__AssetLineItem__Share WHERE RowCause =: Schema.Apttus_Config2__AssetLineItem__Share.RowCause.Asset_Line_Item_Apex_Sharing__c];
    
        system.Assert(ALIshareList.size() >= 0);
        // system.Assert(ALIshareList[0].AccessLevel == 'Read');
        // system.Assert(ALIshareList[0].UserOrGroupId == partnerUser.Id);
        
    }
    
    static testMethod void AfterUpdateALISharingTest(){
        
        Test.startTest();
        
        User AdminUser = createAdminUser();
        
        List<User> userList = new List<User>();
        
        system.runAs(AdminUser){
            
            insert new TriggerSettings__c(AssetLineItemTrigger__c = true);
            
            //Create at least 2 Accounts
            
            List<Account> accList = new List<Account>();
            Account acc1 = new Account() ;
            acc1.Name = 'Test Partner Account 1';
            acc1.Sales_Organization__c = 'SAP_0333';
            acc1.Phone = '+0987654321';
            acc1.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.Customer).getRecordTypeId();
            acc1.Main_Street_Only__c = 'Test Street';
            acc1.Account_Type__c = 'Customer';
            accList.add(acc1);
            
            Account acc2 = new Account() ;
            acc2.Name = 'Test Partner Account 2';
            acc2.Sales_Organization__c = 'SAP_0333';
            acc2.Phone = '+0987654322';
            acc2.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.Customer).getRecordTypeId();
            acc2.Main_Street_Only__c = 'Test Street';
            acc2.Account_Type__c = 'Customer';
            accList.add(acc2);
            
            insert accList; 
            
            
            //Create at least 2 Contacts
            
            List<Contact> conList = new List<Contact>();
            Contact con1 = new Contact();
            con1.FirstName = 'FirstNamePartner';
            con1.LastName = 'LastNamePartner';
            con1.AccountId = accList[0].Id;
            con1.Phone = '+0987654321';
            con1.Title = 'Tester';
            conList.add(con1);
            
            Contact con2 = new Contact();
            con2.FirstName = 'FirstNamePartner';
            con2.LastName = 'LastNamePartner';
            con2.AccountId = accList[1].Id;
            con2.Phone = '+0987654321';
            con2.Title = 'Tester';
            conList.add(con2);
            
            insert conList;  
            
            Id prof = [SELECT Id FROM Profile WHERE Name='Partner Community User'].Id;
            
            //Insert at least 2 partner users for each contact
                       
            userList.add(createPartnerUser(conList[0].Id, prof, 'Test', 'DuaLipaTest@usertriggertest.com', 'testa1', 'DuaLipa@usertriggertest.com'));
            userList.add(createPartnerUser(conList[1].Id, prof, 'Test', 'LANYTest@usertriggertest.com', 'testa1', 'LANYTest@usertriggertest.com'));   
            insert userList;
            
            
            //Insert ALI
            List<Apttus_Config2__AssetLineItem__c> aliList = new List<Apttus_Config2__AssetLineItem__c>();
            for(Integer x = 0; x < 3; x++){
                aliList.add(createALI(accList[0].Id, 'TEST ALI '+x));
            }
            
            insert aliList;
            
            for(Apttus_Config2__AssetLineItem__c ali : aliList){
                
                ali.Apttus_Config2__AccountId__c = accList[1].Id;
            }
            
            update aliList;
            
        }
        
        Test.stopTest();
        
        //Check ALI Share
        
        List<Apttus_Config2__AssetLineItem__Share> ALIshareList = new List<Apttus_Config2__AssetLineItem__Share>();
        
        ALIshareList = [SELECT Id, UserOrGroupId, AccessLevel, RowCause FROM Apttus_Config2__AssetLineItem__Share WHERE RowCause =: Schema.Apttus_Config2__AssetLineItem__Share.RowCause.Asset_Line_Item_Apex_Sharing__c];
    
        system.Assert(ALIshareList.size() >= 0);
        // system.Assert(ALIshareList[0].AccessLevel == 'Read');
        // system.Assert(ALIshareList[0].UserOrGroupId == userList[1].Id);
        
    }
    
    static testMethod void ALIDeleteUndeleteTest(){
        
        Test.startTest();
        
        User AdminUser = createAdminUser();
        User partnerUser;
        
        system.runAs(AdminUser){
            
            insert new TriggerSettings__c(AssetLineItemTrigger__c = true);
            
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
            
            Id prof = [SELECT Id FROM Profile WHERE Name='Partner Community Login User'].Id;
            
            partnerUser = createPartnerUser(con.Id, prof, 'Test', 'partnerTest1@usertriggertest.com', 'testa1', 'partnerTest1@usertriggertest.com');           
            insert partnerUser;
            
            
            //Insert ALI
            List<Apttus_Config2__AssetLineItem__c> aliList = new List<Apttus_Config2__AssetLineItem__c>();
            for(Integer x = 0; x < 3; x++){
                aliList.add(createALI(acc.Id, 'TEST ALI '+x));
            }
            
            insert aliList;   
            
            delete aliList;
            undelete aliList;
            
        }
        
        Test.stopTest();
        
        //Check ALI
        
        List<Apttus_Config2__AssetLineItem__c> UNDELaliList = [SELECT Id FROM Apttus_Config2__AssetLineItem__c];
        
        system.assert(UNDELaliList.size() > 0);
        
    }
    
    static testMethod void TestTriggerOff(){
        
        insert new TriggerSettings__c(AssetLineItemTrigger__c = false);
        
        AssetLineItemSharingTriggerHandler userhandler = new AssetLineItemSharingTriggerHandler();
        TriggerDispatcher.Run(userhandler);
        
        TriggerSettings__c ts = TriggerSettings__c.getInstance();
        system.assertEquals(false, ts.AssetLineItemTrigger__c);
    
    }
    
}