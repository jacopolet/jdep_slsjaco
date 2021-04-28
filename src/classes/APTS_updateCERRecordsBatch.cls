/*************************************************************
@Name: APTS_updateCERRecordsBatch 
@Author: Aftab Mohammed
@Description: Batch class to process CER Transaction records to update Agreements
*****************************************************************/
global class APTS_updateCERRecordsBatch implements Database.Batchable<sObject>{

    String query;
    private static String BATCHNAME = 'APTS_updateCERRecordsBatch';
    private static String STREAM = 'CLM';
    private static String TYPE = 'CER Transaction Batch';
    List<APTS_CER_Transaction__c> cerTransList = new List<APTS_CER_Transaction__c>();
    
    public APTS_updateCERRecordsBatch(List<APTS_CER_Transaction__c> cerTransList){
        this.cerTransList = cerTransList;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        try{
            query = 'SELECT Id, APTS_Agreement_Id__c FROM APTS_CER_Transaction__c WHERE APTS_Process_Status__c = \'Created\'';
            return Database.getQueryLocator(query);
        }catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), TYPE, String.valueOf(ex) ,BATCHNAME, null, STREAM, false, false, null, true); return null;}
    }

    global void execute(Database.BatchableContext BC, List<APTS_CER_Transaction__c> scope) {
        
        Set<String> agreementIdSet = new Set<String>();
        
        APTS_CER_Transaction__c cerTrans = scope[0];
        cerTrans.APTS_Process_Status__c = 'Processing';
        update cerTrans;
        agreementIdSet.add(cerTrans.APTS_Agreement_Id__c);
        
        List<Apttus__APTS_Agreement__c> agreementList = [SELECT Id, RecordTypeId, Apttus__Account__c,APTS_CER_Batch_Executed__c FROM Apttus__APTS_Agreement__c WHERE Id IN: agreementIdSet];
        
        if(agreementList.size() > 0){
            try{
                APTS_ManageCER.manageCERRecords(agreementList,APTS_ManageCER.BATCH,APTS_ManageCER.DMLUPDATE); 
            }catch(Exception ex){
                cerTrans.APTS_Process_Status__c = 'Failed';
                cerTrans.APTS_Error__c = String.valueOf(ex); update cerTrans;
            }
        }
        
        if(cerTrans.APTS_Process_Status__c != 'Failed'){
            cerTrans.APTS_Process_Status__c = 'Processed';
            update cerTrans;
        }
        
    }
    
    global void finish(Database.BatchableContext BC) {}
    
}