global without sharing class ResetAccount {
    webservice static String resetAccountRelatedToIntegrationLog(Id integID) {
        String retString = 'Success';
        Id recordTypeIdCustomer = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.Customer).getRecordTypeId();
        Id recordTypeIdProspectValid =  Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.ProspectValid).getRecordTypeId();
        Id recordTypeIdPromotionReq =  Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.PromotionRequested).getRecordTypeId();
        Id recordTypeIdCustomerValidation =  Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.EndCustomerValidation).getRecordTypeId();
        Integration_Log__c integrationlog = [Select Id, Integration_Status__c, Object_Id__c FROM Integration_Log__c WHERE ID = :integID];
        Account accRec = [Select Id, RecordTypeId FROM Account WHERE Id = :integrationlog.Object_Id__c];
        if (integrationlog.Integration_Status__c != 'Target System Error') {
            retString = 'No Error';
        } else {
            if (accRec.RecordTypeId == recordTypeIdPromotionReq) {
                accRec.RecordTypeId = recordTypeIdProspectValid;
                accRec.Prospect_promotion_status__c = 'Prospect promotion denied';
            } else if (accRec.RecordTypeId == recordTypeIdCustomerValidation) {
                accRec.RecordTypeId = recordTypeIdCustomer;
				accRec.Previous_Record_Type__c = String.valueOf(recordTypeIdCustomerValidation).substring(0, 15);
            } 
            update accRec;
        }
        return retString;
    }
}