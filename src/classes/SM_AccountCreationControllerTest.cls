@isTest
private class SM_AccountCreationControllerTest {
    private static testMethod void prospectRecordType() {
        Profile p = [SELECT Id FROM Profile WHERE Name =: SM_Constants.JDEEndUser]; 
        User u = new User(Alias = 'standt', Email='ample@testUser.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',  
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sample@ksdjflskje.com', Sales_Organization__c = 'SAP_0111');
        
        System.runAs(u) {
            //Selection of record type
            String accountProspectRecordType = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.Prospect).getRecordTypeId(); 
    
            Boolean isProspect = SM_AccountCreationController.checkRecordType(accountProspectRecordType);
            
            //Assert the name field and saved expense
            System.assertEquals(true, isProspect);
        }
    }
    
    private static testMethod void nonprospectRecordType() {
        Profile p = [SELECT Id FROM Profile WHERE Name =: SM_Constants.JDEEndUser]; 
        User u = new User(Alias = 'standt', Email='ample@testUser.com', 
        EmailEncodingKey='UTF-8', LastName='Testing2', LanguageLocaleKey='en_US',  
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sample@ksdjflskje2.com', Sales_Organization__c = 'SAP_0111');
        
        System.runAs(u) {
            //Selection of record type
            String adminstrativeAddressRecordType = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.AdministrativeAddress).getRecordTypeId(); 
    
            Boolean isProspect = SM_AccountCreationController.checkRecordType(adminstrativeAddressRecordType);
            
            //Assert the name field and saved expense
            System.assertEquals(false, isProspect);
        }
    }
}