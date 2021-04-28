global without sharing class ResetIntegrationLog {
   
    webservice static String resetObjectIntegrationLog(Id integID) {
        String retString = 'Success';
        
        Integration_Log__c integrationlog = [Select Id, Integration_Status__c, Object_Id__c, Bank_Detail__c, Object__c FROM Integration_Log__c WHERE ID = :integID];
        
        if (integrationlog.Integration_Status__c != 'Target System Error'){
            retString = 'No Error';
        } else {
            if (integrationlog.Bank_Detail__c != null){
                 Bank_Details__c bankdetailrec = [Select Id, Updated_Bank_Account__c, Updated_Bank_Country__c, Updated_Bank_Key__c, Updated_Collection_Authorization__c, Updated_Control_Key__c, Updated_IBAN__c from Bank_Details__c Where Id = :integrationlog.Bank_Detail__c];
                 if (bankdetailrec != null){
                     bankdetailrec.Updated_Bank_Account__c = null;
                     bankdetailrec.Updated_Bank_Country__c = null;  
                     bankdetailrec.Updated_Bank_Key__c = null;
                     bankdetailrec.Updated_Collection_Authorization__c = false;
                     bankdetailrec.Updated_Control_Key__c = null;
                     bankdetailrec.Updated_IBAN__c = null;
                     update bankdetailrec;
                     retString = 'Bank Detail';
                 }
            } else {
                if (integrationlog.Object__c == 'Account'){
                    Id recordTypeIdCustomer = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.Customer).getRecordTypeId();
                    Id recordTypeIdProspectValid =  Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.ProspectValid).getRecordTypeId();
                    Id recordTypeIdPromotionReq =  Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.PromotionRequested).getRecordTypeId();
                    Id recordTypeIdCustomerValidation =  Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.EndCustomerValidation).getRecordTypeId();
                    
                    Account accRec = [Select Id, RecordTypeId FROM Account WHERE Id = :integrationlog.Object_Id__c];
                    if (accRec.RecordTypeId == recordTypeIdPromotionReq) {
                        accRec.RecordTypeId = recordTypeIdProspectValid;
                        accRec.Prospect_promotion_status__c = 'Prospect promotion denied';
                    } else if (accRec.RecordTypeId == recordTypeIdCustomerValidation) {
                        accRec.RecordTypeId = recordTypeIdCustomer;
                        accRec.Previous_Record_Type__c = String.valueOf(recordTypeIdCustomerValidation).substring(0, 15);
                    }
                    update accRec;
                }
            }
        }
        return retString;
    }
}