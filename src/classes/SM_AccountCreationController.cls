public without sharing class SM_AccountCreationController {
    @AuraEnabled
    public static Boolean checkRecordType(String recordTypeId){
    	Boolean isProspect = false;
        if(recordTypeId == Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.Prospect).getRecordTypeId()){
            isProspect = true;
        }    
        return isProspect;
    }
}