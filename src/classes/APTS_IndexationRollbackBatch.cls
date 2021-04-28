/**
 * @description       : APTS_IndexationRollbackBatch
 * @author            : Karan Khatri
 * @group             : 
 * @last modified on  : 02-02-2021
 * @last modified by  : Karan Khatri
 * Modifications Log 
 * Ver   Date         Author         Modification
 * 1.0   02-02-2021   Karan Khatri   Initial Version
**/
public without sharing class APTS_IndexationRollbackBatch implements Database.Batchable<sObject> {

    String query;
    private static String ARBATCHNAME = 'APTS_AssetIndexationRollbackBatch';
    private static String STREAM = 'CLM';
    private static String TYPE = 'Batch';
    Map<String, String> agmtIdToIndexNumberMap = new Map<String, String>();
    
    //Constructor
    public APTS_IndexationRollbackBatch(){}

    //start method to get AUTO RENEWAL STAGING records which are "Processed"
    public Database.QueryLocator start(Database.BatchableContext BC){
        try{
          for(APTS_Batch_Queries__mdt batchQuery : [SELECT Id,
                                                          APTS_Query_String__c
                                                          FROM APTS_Batch_Queries__mdt
                                                          WHERE APTS_Batch_Name__c =: ARBATCHNAME]){
                query = batchQuery.APTS_Query_String__c;
            }
            System.debug('***query===>'+query);
            return Database.getQueryLocator(query);
        }catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), TYPE, String.valueOf(ex) ,ARBATCHNAME, null, STREAM, false, false, null, true); return null;}
    }

    //Execute method to process all qualified AUTO RENEWAL RECORDS and do the following
    //1) Process only Draft and Pending orders 
    //2) Delete the orders
    //3) Delete orphan Product configuration 
    //4) Delete Temp Object (CPQ)
    public void execute(Database.BatchableContext BC, List<sObject> scope) {
         
        List<Id> tempIndexationStagingIds = new List<Id>();
        List<Id> indexationStagingIds = new List<Id>();
        List<String> orderStatusToConsider = System.Label.APTS_OrderStatusForRollback.split(',');
        List<Apttus_Config2__Order__c> ordersToCancelList = new  List<Apttus_Config2__Order__c>();
        List<Apttus_Config2__ProductConfiguration__c> prodConfigList = new  List<Apttus_Config2__ProductConfiguration__c>();
        List<Apttus_Config2__TempObject__c> tempObjectList = new  List<Apttus_Config2__TempObject__c>();
        For(APTS_Index_Transaction__c autoRenewStaging : (List<APTS_Index_Transaction__c>)scope){
           tempIndexationStagingIds.add(autoRenewStaging.id);
        }
        System.debug('******tempIndexationStagingIds=====>'+tempIndexationStagingIds);
        //Re check in case of sequencing issue
        if(!tempIndexationStagingIds.isEmpty()){
            For(APTS_Index_Transaction__c finalAutoRenewStaging : [select id from APTS_Index_Transaction__c where id IN: tempIndexationStagingIds]){
                 indexationStagingIds.add(finalAutoRenewStaging.id);
            }
        }
        System.debug('******indexationStagingIds=====>'+indexationStagingIds);
        if(!indexationStagingIds.isEmpty()){
            
            //Get all qualifying orders 
            for(Apttus_Config2__Order__c ord : [Select id From Apttus_Config2__Order__c Where Apttus_Config2__Status__c IN: orderStatusToConsider and APTS_Indexation_source_id__c IN: indexationStagingIds limit 50000]){
                ordersToCancelList.add(ord);
            }
            System.debug('******ordersToCancelList=====>'+ordersToCancelList);
            //Get all orphan Product Configs
            for(Apttus_Config2__ProductConfiguration__c config : [Select id From Apttus_Config2__ProductConfiguration__c Where Apttus_Config2__OrderId__c IN: ordersToCancelList limit 50000]){
                prodConfigList.add(config);
            }
            System.debug('******prodConfigList=====>'+prodConfigList);
            //Get all orphan TempObject records
             for(Apttus_Config2__TempObject__c temp : [Select id From Apttus_Config2__TempObject__c Where Apttus_Config2__ConfigurationId__c IN: prodConfigList limit 50000]){
                tempObjectList.add(temp);
            }
            System.debug('******tempObjectList=====>'+tempObjectList);
        
        }
        
        //Delete orphan Product config
        if(!prodConfigList.isEmpty()){
            Database.delete(prodConfigList,false);
        }
        
        //Delete orphan temp object CPQ
        if(!tempObjectList.isEmpty()){
            Database.delete(tempObjectList,false);
        }
        
        //Delete qualifying orders
        if(!ordersToCancelList.isEmpty()){
            Database.delete(ordersToCancelList,false);
        }
        
        //Delete AutoRenewal staging records
        if(!scope.isEmpty()){
            Database.delete(scope,false);
        }
        
    }

    public void finish(Database.BatchableContext BC) {
       
    }
}