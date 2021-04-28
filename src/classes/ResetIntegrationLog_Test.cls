@isTest
public class ResetIntegrationLog_Test {
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
        
    	ResetIntegrationLog.resetObjectIntegrationLog(integ.Id);
        
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
        
    	ResetIntegrationLog.resetObjectIntegrationLog(integ.Id);
        
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
        
    	ResetIntegrationLog.resetObjectIntegrationLog(integ.Id);
        
        Integration_Log__c integrationlog = [Select Id, Integration_Status__c, Object_Id__c FROM Integration_Log__c WHERE ID = :integ.Id];
        Account accRec = [Select Id, RecordTypeId FROM Account WHERE Id = :integrationlog.Object_Id__c];
        
        System.assertEquals(accRec.RecordTypeId, recordTypeIdCustomerValidation);
        
    }
    
    private static testMethod void integrationlogBankDetail() {
        Bank_key__c bankKey = new Bank_key__c();
        bankKey.Conversion_ID__c = '234343434';
        insert bankKey;
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Account_Status__c = 'Valid';
        acc.Main_City__c = 'Netherlands';
        acc.Main_Postal_Code__c = '1500';
        acc.Main_State__c = 'Amsterdam';
        acc.Archiving_Flag__c = False;
        acc.Main_Country__c = 'Netherlands';
        acc.Sales_Organization__c = 'SAP_0111';
        acc.Duplicate_Reason__c = '';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+09238409384';
        insert acc;

        Bank_Details__c bank = new Bank_Details__c();
        bank.Updated_Bank_Account__c = 'Update Bank acc';
        bank.Updated_Bank_Country__c = 'SE';
        bank.Updated_Bank_Key__c = bankKey.Id;
        bank.Updated_Collection_Authorization__c = false;
        bank.Updated_Control_Key__c = '21';
        bank.Updated_IBAN__c = 'IBAN';
        bank.Account__c = acc.Id;
        //bank.Finance_Controller_BD_Validation__c = userList[1].Id;
        insert bank;
        
        Integration_Log__c integ = new Integration_Log__c();
        integ.Integration_Status__c = 'Target System Error';
        integ.Account__c = acc.id;
        integ.Object_Id__c = acc.Id;
        integ.Object__c = 'Account';
        integ.Bank_Detail__c = bank.Id;
        insert integ;
        
        ResetIntegrationLog.resetObjectIntegrationLog(integ.Id);
        Integration_Log__c integrationlog = [Select Id, Integration_Status__c, Bank_Detail__c FROM Integration_Log__c WHERE ID = :integ.Id];
        Bank_Details__c bankdetailrec = [Select Id, Updated_Bank_Account__c, Updated_Bank_Country__c, Updated_Bank_Key__c, Updated_Collection_Authorization__c, Updated_Control_Key__c, Updated_IBAN__c from Bank_Details__c Where Id = :integrationlog.Bank_Detail__c];
        
        System.assertEquals(bankdetailrec.Updated_Bank_Account__c, null);
        
    }
}