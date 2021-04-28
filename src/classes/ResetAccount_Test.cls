@isTest
public class ResetAccount_Test {
	private static testMethod void integrationlogErrorPromotion() {
        Id recordTypeIdProspectValid =  Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.ProspectValid).getRecordTypeId();
        Id recordTypeIdPromotionReq =  Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.PromotionRequested).getRecordTypeId();
        Account acctRec = new Account(Name = 'Test Account', Phone = '+31302979111', RecordTypeId = recordTypeIdPromotionReq);
        insert acctRec;
        
        Integration_Log__c integ = new Integration_Log__c();
        integ.Integration_Status__c = 'Target System Error';
        integ.Account__c = acctRec.id;
        integ.Object_Id__c = acctRec.Id;
        integ.Object__c = 'Account';
        insert integ;
        
    	ResetAccount.resetAccountRelatedToIntegrationLog(integ.Id);
        
        Integration_Log__c integrationlog = [Select Id, Integration_Status__c, Object_Id__c FROM Integration_Log__c WHERE ID = :integ.Id];
        Account accRec = [Select Id, RecordTypeId FROM Account WHERE Id = :integrationlog.Object_Id__c];
        
        System.assertEquals(accRec.RecordTypeId, recordTypeIdProspectValid);
        
    }
    
    private static testMethod void integrationlogErrorCustomer() {
        Id recordTypeIdCustomerValidation =  Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.EndCustomerValidation).getRecordTypeId();
        Id recordTypeIdCustomer =  Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.Customer).getRecordTypeId();
        Account acctRec = new Account(Name = 'Test Account', Phone = '+31302979111', RecordTypeId = recordTypeIdCustomerValidation);
        insert acctRec;
        
        Integration_Log__c integ = new Integration_Log__c();
        integ.Integration_Status__c = 'Target System Error';
        integ.Account__c = acctRec.id;
        integ.Object_Id__c = acctRec.Id;
        integ.Object__c = 'Account';
        insert integ;
        
    	ResetAccount.resetAccountRelatedToIntegrationLog(integ.Id);
        
        Integration_Log__c integrationlog = [Select Id, Integration_Status__c, Object_Id__c FROM Integration_Log__c WHERE ID = :integ.Id];
        Account accRec = [Select Id, RecordTypeId FROM Account WHERE Id = :integrationlog.Object_Id__c];
        
        System.assertEquals(accRec.RecordTypeId, recordTypeIdCustomer);
        
    }
    
    private static testMethod void integrationlogNoError() {
        Id recordTypeIdCustomerValidation =  Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.EndCustomerValidation).getRecordTypeId();
        Account acctRec = new Account(Name = 'Test Account', Phone = '+31302979111', RecordTypeId = recordTypeIdCustomerValidation);
        insert acctRec;
        
        Integration_Log__c integ = new Integration_Log__c();
        integ.Integration_Status__c = 'Initial';
        integ.Account__c = acctRec.id;
        integ.Object_Id__c = acctRec.Id;
        integ.Object__c = 'Account';
        insert integ;
        
    	ResetAccount.resetAccountRelatedToIntegrationLog(integ.Id);
        
        Integration_Log__c integrationlog = [Select Id, Integration_Status__c, Object_Id__c FROM Integration_Log__c WHERE ID = :integ.Id];
        Account accRec = [Select Id, RecordTypeId FROM Account WHERE Id = :integrationlog.Object_Id__c];
        
        System.assertEquals(accRec.RecordTypeId, recordTypeIdCustomerValidation);
        
    }
}