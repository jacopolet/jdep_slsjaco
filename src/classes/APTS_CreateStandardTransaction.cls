/*************************************************************
@Name: APTS_CreateStandardTransaction
@Author: Aftab
@CreateDate: 31-05-2019
@Description: Batch class to apply standard indexation
@Covered by: APTS_CreateStandardTransaction_Test
*****************************************************************/
global class APTS_CreateStandardTransaction implements Database.Batchable<sObject>{

    String region;
    String query; 
    String techService; 
    String machineCare;
    private static String BATCHNAME = 'APTS_StandardIndexBatch';
    private static String STREAM = 'CLM';
    private static String TYPE = 'Batch';

    global APTS_CreateStandardTransaction(String region, String techService, String machineCare){
        if(region != null){
            this.region= region;
            this.techService = techService;
            this.machineCare = machineCare;
        }
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
        try{
            for(APTS_Batch_Queries__mdt batchQuery : [SELECT Id,
                                                          APTS_Query_String__c
                                                          FROM APTS_Batch_Queries__mdt
                                                          WHERE APTS_Batch_Name__c =: BATCHNAME]){
                query = batchQuery.APTS_Query_String__c;
            }
            return Database.getQueryLocator(query);
        }catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), TYPE, String.valueOf(ex) ,BATCHNAME, null, STREAM, false, false, null, true); return null;}
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<APTS_Index_Contract__c> lstContract = (List<APTS_Index_Contract__c>)scope;
        for(APTS_Index_Contract__c contract : lstContract){
                if(String.isNotBlank(techService) && contract.APTS_Indexation_Category__c == 'Technical Services'){
                    contract.APTS_Indexation_Number__c = String.valueOf(techService);
                }/*else if(String.isNotBlank(machineCare) && contract.APTS_Indexation_Category__c == 'Machine Care Service'){
                    contract.APTS_Indexation_Number__c = String.valueOf(machineCare);
                }*/
            }
        APTS_AgreementTriggerHandler.triggerDisabled = TRUE;
        if(lstContract.size() > 0)update lstContract;
    }

    global void finish(Database.BatchableContext BC) {
         //Do nothing
    }
}