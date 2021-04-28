/**
 * Class Name: PromoteToSAPRemoteTest
 * @author: Alvin Lomod
 * Date: 14-Mar-2018
 * Requirement: KASM-1376
 * @description: Test class of PromoteToSAPRemoteTest
 *
 */
 
 @isTest
 private class PromoteToSAPRemoteTest {
     
     private static testMethod void promoteToSAPAccount(){
         
        Profile p = [SELECT Id FROM Profile WHERE Name =: SM_Constants.SystemAdmin]; 
        User u = new User(Alias = 'standt', Email='sample@testUser1.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sample@testUser1.com', Sales_Organization__c = 'SAP_0333',
        Elevated_Access_Reason__c = 'Defect or Incident Resolution', Elevated_Access_Reference__c = 'ASDF');
        
        System.runAs(u) {
        List<Account> accList = new List<Account>();
        for(Account acc : TestDataFactory.createAccounts(5,'29604')){
            acc.Creditworthiness_Flag__c = 'Green';
            acc.Main_Address_Validation_Pending__c = false;
            acc.Sales_Office__c = null;
            acc.Prospect_promotion_status__c = 'Prospect';
            acc.RecordTypeId = SM_Constants.recordTypeIdProspectValid;
            accList.add(acc);
        }
        
        accList[0].Commercial_Register_Number__c = '12334790AAAA';
        accList[0].VAT_Registration_Number__c = '12345678900987';
        accList[0].Account_Status__c = 'Valid';
            
        accList[1].Account_Status__c = 'Valid';
        accList[1].Main_Postal_Box__c = 'asdf';
            
        accList[2].Account_Status__c = 'Valid';
        accList[2].Main_Postal_Box_Postal_Code__c = 'asdf';
        
        accList[3].Account_Status__c = 'Valid';
        accList[3].Main_Postal_Box_City__c = 'asdf';
            
        accList[4].Account_Status__c = 'Not Valid';
        
        checkRecursive.run = true;
        test.startTest();
        insert accList;
        
        PromoteToSAPRemote.PromoteToSAP(accList[0].Id);
        PromoteToSAPRemote.PromoteToSAP(accList[1].Id);
        PromoteToSAPRemote.PromoteToSAP(accList[2].Id);
        PromoteToSAPRemote.PromoteToSAP(accList[3].Id);
        PromoteToSAPRemote.PromoteToSAP(accList[4].Id);
        
        test.stopTest();
        
        List<Integration_Log__c> iLogList = [SELECT Object_Id__c, Object__c, Account__c FROM Integration_Log__c WHERE Account__c =: accList[0].Id];
        List<Account> UpdatedAccList = [SELECT Id, RecordTypeId FROM Account WHERE Id =: accList[0].Id];
        
        system.assertEquals(iLogList[0].Object_Id__c, accList[0].Id);
        system.assertEquals(UpdatedAccList[0].RecordTypeId, Label.AccountRecordTypeId_PromotionRequested);
        
        }
     }
     
      private static testMethod void promoteToSAPAccount2(){
         
        Profile p = [SELECT Id FROM Profile WHERE Name =: SM_Constants.SystemAdmin]; 
        User u = new User(Alias = 'standt', Email='sample@testUser1.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sample@testUser1.com', Sales_Organization__c = 'SAP_0333',
        Elevated_Access_Reason__c = 'Defect or Incident Resolution', Elevated_Access_Reference__c = 'ASDF');
        
        System.runAs(u) {
        List<Account> accList = new List<Account>();
        for(Account acc : TestDataFactory.createAccounts(1,'29604')){
            acc.Creditworthiness_Flag__c = 'Green';
            acc.Main_Address_Validation_Pending__c = false;
            acc.Sales_Office__c = null;
            acc.Prospect_promotion_status__c = 'Submitted for promotion';
            accList.add(acc);
        }
        
        accList[0].Commercial_Register_Number__c = '12334790AAAA';
        accList[0].VAT_Registration_Number__c = '12345678900987';
        accList[0].Account_Status__c = 'Valid';
        
        test.startTest();
        insert accList;
        
        checkRecursive.run = true;
        PromoteToSAPRemote.PromoteToSAP(accList[0].Id);
        PromoteToSAPRemote.PromoteToSAP(accList[1].Id);
        
        test.stopTest();
        
        system.assertEquals(accList[0].Prospect_promotion_status__c, 'Submitted for promotion');
        
        }
     }
     
     private static testMethod void promoteToSAPAccountLocation(){
        Profile p = [SELECT Id FROM Profile WHERE Name =: SM_Constants.SystemAdmin]; 
        User u = new User(Alias = 'standt', Email='sample@testUser1.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sample@testUser1.com', Sales_Organization__c = 'SAP_0333',
        Elevated_Access_Reason__c = 'Defect or Incident Resolution', Elevated_Access_Reference__c = 'ASDF');
        
        System.runAs(u) {        
        List<Account> accList = new List<Account>();
        for(Account acc : TestDataFactory.createAccounts(1,'29604')){
            acc.Creditworthiness_Flag__c = 'Green';
            acc.Main_Address_Validation_Pending__c = false;
            acc.Sales_Office__c = null;
            accList.add(acc);
        }
        
        
        insert accList;
            
        List<Apttus_Config2__AccountLocation__c> accLocList = new List<Apttus_Config2__AccountLocation__c>();
        for(integer x = 0; x<=1; x++){
            Apttus_Config2__AccountLocation__c accLoc = new Apttus_Config2__AccountLocation__c();
            accLoc.Apttus_Config2__AccountId__c = accList[0].Id;
            accLoc.Shipping_Address_Validation_Code__c = 'testa1321';
            accLoc.Address_Validation__c = 'Valid';
            accLoc.Copy_of_Parent_Account__c = false;
            accLoc.Promotion_Status__c = 'Prospect';
            accLoc.RecordTypeId = Schema.SObjectType.Apttus_Config2__AccountLocation__c.getRecordTypeInfosByName().get('Account Location Valid').getRecordTypeId();
            accLoc.Name = 'SAMP';
            accLoc.Customer_calendar_key__c = 'SAP_32';
            accLoc.Mini_Language__c = 'SAP_FR';
            accLoc.Saturday_Afternoon_From_Receiving__c = '14:30';
            accLoc.Saturday_Afternoon_To_Receiving__c = '15:00';
            accLoc.Saturday_Morning_From_Receiving__c = '02:45';
            accLoc.Saturday_Morning_To_Receiving__c = '02:15';
            accLoc.Sunday_Afternoon_From_Receiving__c = '15:15';
            accLoc.Sunday_Afternoon_To_Receiving__c = '15:30';
            accLoc.Sunday_Morning_From_Receiving__c = '03:30';
            accLoc.Sunday_Morning_To_Receiving__c = '   01:00';
            accLocList.add(accLoc);
        }
        
        accLocList[1].Copy_of_Parent_Account__c = true; //Invalid
        accLocList[0].Account_Location_Status__c = 'Valid';
        
        insert accLocList;
        
        test.startTest();
        PromoteToSAPRemote.PromoteToSAPAccountLocation(accLocList[0].Id);
        PromoteToSAPRemote.PromoteToSAPAccountLocation(accLocList[1].Id);
        
        test.stopTest();
        
        List<Integration_Log__c> iLogList = [SELECT Object_Id__c, Object__c, Account__c, AccountLocation__c FROM Integration_Log__c WHERE AccountLocation__c =: accLocList[0].Id];
        List<Apttus_Config2__AccountLocation__c> UpdatedAccLocList = [SELECT Id, RecordTypeId FROM Apttus_Config2__AccountLocation__c WHERE Id =: accLocList[0].Id];
        
        system.assertEquals(iLogList[0].Object_Id__c, accLocList[0].Id);
        system.assertEquals(UpdatedAccLocList[0].RecordTypeId, Label.AccountLocationRecordTypeId_PromotionRequested);
        
        }
         
     }
     
     private static testMethod void promoteToSAPAccountLocationSubmitted(){
        Profile p = [SELECT Id FROM Profile WHERE Name =: SM_Constants.SystemAdmin]; 
        User u = new User(Alias = 'standt', Email='sample@testUser1.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sample@testUser1.com', Sales_Organization__c = 'SAP_0333',
        Elevated_Access_Reason__c = 'Defect or Incident Resolution', Elevated_Access_Reference__c = 'ASDF');
        
        System.runAs(u) {        
        List<Account> accList = new List<Account>();
        for(Account acc : TestDataFactory.createAccounts(1,'29604')){
            acc.Creditworthiness_Flag__c = 'Green';
            acc.Main_Address_Validation_Pending__c = false;
            acc.Sales_Office__c = null;
            accList.add(acc);
        }
        
        
        insert accList;
            
        List<Apttus_Config2__AccountLocation__c> accLocList = new List<Apttus_Config2__AccountLocation__c>();
        for(integer x = 0; x<=1; x++){
            Apttus_Config2__AccountLocation__c accLoc = new Apttus_Config2__AccountLocation__c();
            accLoc.Apttus_Config2__AccountId__c = accList[0].Id;
            accLoc.Shipping_Address_Validation_Code__c = 'testa1321';
            accLoc.Address_Validation__c = 'Valid';
            accLoc.Copy_of_Parent_Account__c = false;
            accLoc.Promotion_Status__c = 'Submitted for promotion';
            accLoc.RecordTypeId = Schema.SObjectType.Apttus_Config2__AccountLocation__c.getRecordTypeInfosByName().get('Account Location Valid').getRecordTypeId();
            accLoc.Name = 'SAMP';
            accLoc.Customer_calendar_key__c = 'SAP_32';
            accLoc.Mini_Language__c = 'SAP_FR';
            accLoc.Saturday_Afternoon_From_Receiving__c = '14:30';
            accLoc.Saturday_Afternoon_To_Receiving__c = '15:00';
            accLoc.Saturday_Morning_From_Receiving__c = '02:45';
            accLoc.Saturday_Morning_To_Receiving__c = '02:15';
            accLoc.Sunday_Afternoon_From_Receiving__c = '15:15';
            accLoc.Sunday_Afternoon_To_Receiving__c = '15:30';
            accLoc.Sunday_Morning_From_Receiving__c = '03:30';
            accLoc.Sunday_Morning_To_Receiving__c = '   01:00';
            accLocList.add(accLoc);
        }
        
        accLocList[1].Copy_of_Parent_Account__c = true; //Invalid
        accLocList[0].Account_Location_Status__c = 'Valid';
        
        insert accLocList;
        
        test.startTest();
        PromoteToSAPRemote.PromoteToSAPAccountLocation(accLocList[0].Id);
        PromoteToSAPRemote.PromoteToSAPAccountLocation(accLocList[1].Id);
        
        test.stopTest();
        
        List<Apttus_Config2__AccountLocation__c> UpdatedAccLocList = [SELECT Id, RecordTypeId,Promotion_Status__c FROM Apttus_Config2__AccountLocation__c WHERE Id =: accLocList[0].Id];
   
        system.assertEquals(UpdatedAccLocList[0].Promotion_Status__c, 'Submitted for promotion');
        
        }
         
     }
 }