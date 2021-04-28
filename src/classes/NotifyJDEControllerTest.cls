/**
 * This class contains unit tests for validating the behavior of NotifyJDEController
 * and triggers.
 */
//-------------------------------------------------------------------------------------------//
// Author       :   Alvin Lomod - Accenture
// Created Date :   November 23, 2017
// Usage        :   
// Updates      :   
//-------------------------------------------------------------------------------------------//
@isTest
private class NotifyJDEControllerTest{
    
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
    
    private static User createPartnerUser(){

        Id p = [SELECT Id FROM Profile WHERE Name='Partner Community Login User'].id;
        
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
                  
        User PartnerUser = new User(alias = 'test123', email='test123@noemail.com',
                emailencodingkey='UTF-8', lastname='LastNamePartner', firstName = 'FirstNamePartner', languagelocalekey='en_US',
                localesidkey='en_US', profileid = p, country='United States',IsActive =true,
                             ContactId = con.Id, Sales_Organization__c = 'SAP_0333',
                timezonesidkey='America/Los_Angeles', username='tester@notemail.com');
       
        insert PartnerUser;
        
        return PartnerUser;
    }
    
    static testMethod void NotifyJDEPartnerUserTest(){
        
        Test.startTest();
        
        User AdminUser = createAdminUser();
        
        system.runAs(AdminUser){
            
            insert new TriggerSettings__c(LeadTrigger__c = true);
            insert new WorkflowSettings__c(LeadWorkflows__c = true);
        
            User partnerUser = createPartnerUser();
            
            system.runAs(partnerUser) {
                
                //Create new Lead to transfer to a queue
                
                List<Lead> ldList = new List<Lead>();
                
                Lead ld1 = new Lead();
                ld1.Status = 'Open';
                ld1.LastName = 'TestLead';
                ld1.FirstName = 'TestLead';
                ld1.Title = 'TestLead';
                ld1.Phone = '+1234567890';
                ld1.Touchpoint_Type__c = 'REFERRAL PARTNER';
                ld1.Company = 'TestCompany';
                ld1.Assign__c = false;
                ld1.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get(SM_Constants.LeadRecTypePRFPartner).getRecordTypeId();
                ldList.add(ld1);
                
                Lead ld2 = new Lead();
                ld2.Status = 'Open';
                ld2.LastName = 'TestLead2';
                ld2.FirstName = 'TestLead2';
                ld2.Title = 'TestLead2';
                ld2.Phone = '+1234567897';
                ld2.Touchpoint_Type__c = 'REFERRAL EMPLOYEE';
                ld2.Company = 'TestCompany2';
                ld2.Assign__c = false;
                ld2.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get(SM_Constants.LeadRecTypePRFPartner).getRecordTypeId();
                ldList.add(ld2);
                
                insert ldList;
                
                PageReference pageRef1 = Page.NotifyJDE;
                pageRef1.getParameters().put('Id', String.valueOf(ldList[0].Id));
                Test.setCurrentPage(pageRef1);  
                
                ApexPages.StandardController sc1 = new ApexPages.StandardController(ldList[0]);
                NotifyJDEController ctrl1 = new NotifyJDEController(sc1);
                
                ctrl1.NotifyJDE();
                
                PageReference pageRef2 = Page.NotifyJDE;
                pageRef2.getParameters().put('Id', String.valueOf(ldList[1].Id));
                Test.setCurrentPage(pageRef2); 
                
                ApexPages.StandardController sc2 = new ApexPages.StandardController(ldList[1]);
                NotifyJDEController ctrl2 = new NotifyJDEController(sc2);
                
                ctrl2.NotifyJDE();
                ctrl2.returnToLead();
                
            }
            
        }
        
        Test.stopTest();
        
        //Check Lead
        
        List<Lead> LeadInserted = [SELECT Id, Assign__c FROM Lead WHERE Touchpoint_Type__c =: 'REFERRAL PARTNER'];
        
        system.assertEquals(LeadInserted.size(), 1);
        system.assertEquals(LeadInserted[0].Assign__c, true);
    }
    
    static testMethod void NotifyJDENonPartnerUserTest(){
        
        Test.startTest();
        
        User AdminUser = createAdminUser();
        
        system.runAs(AdminUser){
            
            insert new TriggerSettings__c(LeadTrigger__c = true);
            insert new WorkflowSettings__c(LeadWorkflows__c = true);
                
            //Create new Lead to transfer to a queue
            
            List<Lead> ldList = new List<Lead>();
            
            Lead ld1 = new Lead();
            ld1.Status = 'Open';
            ld1.LastName = 'TestLead';
            ld1.FirstName = 'TestLead';
            ld1.Title = 'TestLead';
            ld1.Phone = '+1234567890';
            ld1.Touchpoint_Type__c = 'REFERRAL PARTNER';
            ld1.Company = 'TestCompany';
            ld1.Assign__c = false;
            ld1.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get(SM_Constants.LeadRecTypePRFPartner).getRecordTypeId();
            
            insert ld1;
            
            PageReference pageRef = Page.NotifyJDE;
            pageRef.getParameters().put('Id', String.valueOf(ld1.Id));
            Test.setCurrentPage(pageRef);  
            
            ApexPages.StandardController sc = new ApexPages.StandardController(ld1);
            NotifyJDEController ctrl = new NotifyJDEController(sc);
            
            ctrl.NotifyJDE();
            
        }
        
        Test.stopTest();
        
        //Check Lead
        
        List<Lead> LeadInserted = [SELECT Id, Assign__c FROM Lead WHERE Touchpoint_Type__c =: 'REFERRAL PARTNER'];
        
        system.assertEquals(LeadInserted.size(), 1);
        system.assertEquals(LeadInserted[0].Assign__c, true);
    }
    
}