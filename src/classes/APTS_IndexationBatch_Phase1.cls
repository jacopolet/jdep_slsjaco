/**
 * @description       : APTS_IndexationBatch_Phase1
 * @author            : Karan Khatri
 * @group             : 
 * @last modified on  : 02-02-2021
 * @last modified by  : Karan Khatri
 * Modifications Log 
 * Ver   Date         Author         Modification
 * 1.0   02-02-2021   Karan Khatri   Initial Version
**/
global class APTS_IndexationBatch_Phase1 implements Database.Batchable<sObject>,Database.Stateful{

    String region;
    String query;
    String batchType;
    Date batchDate;
    private static String SBATCHNAME = 'APTS_StandardIndexBatch';
    private static String BATCHNAME = 'APTS_IndexationBatch_Phase1';
    private static String NSBATCHNAME = 'APTS_NonStandardIndexBatch';
    private static String STANDARD = 'Standard';
    private static String NONSTANDARD = 'NonStandard';
    private static String STREAM = 'CLM';
    private static String TYPE = 'Batch';
    private static final String HYPHEN = '-';
    Set<ID> AgreementIDSet = new Set<ID>();
    Map<String, String> agmtIdToIndexNumberMap = new Map<String, String>();

    global APTS_IndexationBatch_Phase1(String region){
        if(region != null){
            this.region= region;
        }
        batchType=STANDARD;
    }
    
    global APTS_IndexationBatch_Phase1(Date batchDate){
        if(batchDate != null){
            this.batchDate= batchDate;
        }
         batchType=NONSTANDARD;
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
        try{
        
            APTS_AssetRenewalRollbackBatch.bypassCurrentUserfromTriggersandFlows();
        
            if(batchType==STANDARD){
                for(APTS_Batch_Queries__mdt batchQuery : [SELECT Id,
                                                              APTS_Query_String__c
                                                              FROM APTS_Batch_Queries__mdt
                                                              WHERE APTS_Batch_Name__c =: SBATCHNAME]){
                    query = batchQuery.APTS_Query_String__c;
                }
            }
            if(batchType==NONSTANDARD){
                for(APTS_Batch_Queries__mdt batchQuery : [SELECT Id,
                                                              APTS_Query_String__c
                                                              FROM APTS_Batch_Queries__mdt
                                                              WHERE APTS_Batch_Name__c =: NSBATCHNAME]){
                    query = batchQuery.APTS_Query_String__c;
                }
            }
            return Database.getQueryLocator(query);
        }catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), TYPE, String.valueOf(ex) ,BATCHNAME, null, STREAM, false, false, null, true); return null;}
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        for(APTS_Index_Contract__c indexContract : (List<APTS_Index_Contract__c>)scope){
            agreementIdSet.add(indexContract.APTS_Contract__c);
            if(String.IsNotBlank(indexContract.APTS_Indexation_Number__c)){
                String formattedNumber =indexContract.APTS_Indexation_Number__c.replace(',','.');
                agmtIdToIndexNumberMap.put(indexContract.APTS_Contract__c+ HYPHEN +indexContract.APTS_Indexation_Category__c, formattedNumber);
            }
         }
    }

    global void finish(Database.BatchableContext BC) {
        boolean isStdIndex = batchType == STANDARD ? true : false;
        Id batchInstanceId = Database.executeBatch(new APTS_IndexationBatch_Phase2(AgreementIDSet,agmtIdToIndexNumberMap, isStdIndex),200);
    }
}