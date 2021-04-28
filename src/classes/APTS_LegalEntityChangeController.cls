/*************************************************************
@Name: APTS_LegalEntityChangeController
@Author: Pranjal Mittal
@CreateDate: 29-05-2018
@Description: 
@UsedBy: APTS_LegalEntityChange.page
******************************************************************/

public with sharing class APTS_LegalEntityChangeController {

    public class CustomException extends Exception {}

    //Clones the selected agreement.
    @AuraEnabled
    public static String getClonedAgreement(String recordId, String selectedAccountId){
        
        Id aggrId = Id.valueOf(recordId);
        Id newAccountId = Id.valueOf(selectedAccountId);

        Map<Id, Id> mapOldNewAggr = new Map<Id, Id>();
        Boolean flag = false;

        try{
            //Performance issue fixes by Ajith
            if(Apttus__APTS_Agreement__c.sObjectType.getDescribe().isCreateable()){
            if(aggrId != NULL){
                Apttus__APTS_Agreement__c oAggr = [SELECT Id, Name, Apttus__Account__c, Apttus__Status__c,
                    Apttus__FF_Agreement_Number__c, RecordType.Name
                    FROM Apttus__APTS_Agreement__c
                    WHERE Id = :aggrId];
            
                if(selectedAccountId == NULL) throw new CustomException('Please select an account.');

                if(oAggr.Apttus__Status__c != Label.Apttus.Activated) throw new CustomException('Only Activated agreement can be cloned.');

                if(oAggr.Apttus__Account__c == newAccountId) throw new CustomException('Old and new account cannot same.');
                
                Apttus__APTS_Agreement__c newAggr = Apttus.ComplyWebService.cloneAgreement(aggrId);
                newAggr.Apttus__Account__c = newAccountId;
                insert newAggr;

                Apttus.ComplyWebService.afterAgreementClone(aggrId, newAggr.Id);
                flag = true;
                mapOldNewAggr.put(aggrId, newAggr.Id);
            }

            if(flag){
                Database.executeBatch(new APTS_LegalEntityChangeBatch(mapOldNewAggr));
            }}
        }catch(Exception e){
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Legal Entity', recordId,'CLM',false,false, null, true);
            throw new AuraHandledException(e.getMessage());
        }
        
        if(mapOldNewAggr.values() != NULL){
            return mapOldNewAggr.values()[0];
        }

        return null;
    }

}