/*************************************************************
@Name: APTS_AssetRenewalRollbackBatch
@Author: Karan Khatri
@CreateDate: 15-07-2019
@Description: Batch class to rollback records created by Phase1 and Phase2 batch of auto renewals
@Reference JIRA : DFT2C-58
*****************************************************************/
global class APTS_AssetRenewalRollbackBatch implements Database.Batchable<sObject>{

    String query;
    private static String ARBATCHNAME = 'APTS_AutoRenewalRollbackBatch';
    private static String STREAM = 'CLM';
    private static String TYPE = 'Batch';
    Map<String, String> agmtIdToIndexNumberMap = new Map<String, String>();
    
    //Constructor
    global APTS_AssetRenewalRollbackBatch(){}

    //start method to get AUTO RENEWAL STAGING records which are "Processed"
    global Database.QueryLocator start(Database.BatchableContext BC){
        try{
          //Logic to bypass trigger logic for Auto-renewals | Avoids exceptions and improves performanace
            bypassCurrentUserfromTriggersandFlows();
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
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
         
        List<Id> tempAutoRenewalIds = new List<Id>();
        List<Id> autoRenewalStagingIds = new List<Id>();
        List<String> orderStatusToConsider = System.Label.APTS_OrderStatusForRollback.split(',');
        List<Apttus_Config2__Order__c> ordersToCancelList = new  List<Apttus_Config2__Order__c>();
        List<Apttus_Config2__ProductConfiguration__c> prodConfigList = new  List<Apttus_Config2__ProductConfiguration__c>();
        List<Apttus_Config2__TempObject__c> tempObjectList = new  List<Apttus_Config2__TempObject__c>();
        For(APTS_Auto_renewal_staging__c autoRenewStaging : (List<APTS_Auto_renewal_staging__c>)scope){
           tempAutoRenewalIds.add(autoRenewStaging.id);
        }
        System.debug('******tempAutoRenewalIds=====>'+tempAutoRenewalIds);
        //Re check in case of sequencing issue
        if(!tempAutoRenewalIds.isEmpty()){
            For(APTS_Auto_renewal_staging__c finalAutoRenewStaging : [select id from APTS_Auto_renewal_staging__c where id IN: tempAutoRenewalIds]){
                 autoRenewalStagingIds.add(finalAutoRenewStaging.id);
            }
        }
        System.debug('******autoRenewalStagingIds=====>'+autoRenewalStagingIds);
        if(!autoRenewalStagingIds.isEmpty()){
            
            //Get all qualifying orders 
            for(Apttus_Config2__Order__c ord : [Select id From Apttus_Config2__Order__c Where Apttus_Config2__Status__c IN: orderStatusToConsider and APTS_Auto_renewal_staging_source_id__c IN: autoRenewalStagingIds limit 50000]){
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

    global void finish(Database.BatchableContext BC) {
       //Once rollback is done | Continue Auto-Renewal flow
       Database.executeBatch(new APTS_AssetRenewalBatch_Phase1(),Integer.valueOf(System.Label.APTS_AutoAssetRenewalBatchSize));
    }
    
    public static void bypassCurrentUserfromTriggersandFlows(){
    
        //Disable all Triggers and Process Builders for current user
        //If value exists update all flags to false
        List<String> allowableTriggers = System.label.APTS_Allowable_Triggers_Auto_Renewals.split(',');
        if(TriggerSettings__c.getValues(UserInfo.getUserId())!=null){
            Map<String, Schema.SObjectField> m = Schema.SObjectType.TriggerSettings__c.fields.getMap();
            TriggerSettings__c triggerSettings = TriggerSettings__c.getValues(UserInfo.getUserId());    
            for(Schema.SObjectField field : m.values()){
                System.debug('***FIELD==1===>'+String.valueOf(field.getDescribe().getType()));
                if(String.valueOf(field.getDescribe().getType())=='BOOLEAN' && (!String.valueOf(field).equalsIgnoreCase('IsDeleted'))){
                    if(field!=null && allowableTriggers.contains(String.valueOf(field))){
                        triggerSettings.put(field,true);
                    }else{
                        triggerSettings.put(field,false);
                    }
                }

            }
            update triggerSettings;
        }
        //If value doesnt exist create and try and set all flag to false   
        if(TriggerSettings__c.getValues(UserInfo.getUserId())==null){
            Map<String, Schema.SObjectField> m = Schema.SObjectType.TriggerSettings__c.fields.getMap();
            TriggerSettings__c triggerSettings = new TriggerSettings__c();
            triggerSettings.SetupOwnerId = UserInfo.getUserId();
            for(Schema.SObjectField field : m.values()){
                System.debug('***FIELD===2==>'+String.valueOf(field.getDescribe().getType()));
                if(String.valueOf(field.getDescribe().getType())=='BOOLEAN' && (!String.valueOf(field).equalsIgnoreCase('IsDeleted'))){
                   if(field!=null && allowableTriggers.contains(String.valueOf(field))){
                        triggerSettings.put(field,true);
                    }else{
                        triggerSettings.put(field,false);
                    }
                }
            }
            insert triggerSettings;
        }
        //Disabling All Process builders 
        //If value exists update all flags to false
         if(ProcessBuilderSettings__c.getValues(UserInfo.getUserId())!=null){
            Map<String, Schema.SObjectField> m = Schema.SObjectType.ProcessBuilderSettings__c.fields.getMap();
            ProcessBuilderSettings__c PBSettings = ProcessBuilderSettings__c.getValues(UserInfo.getUserId());
            for(Schema.SObjectField field : m.values()){
                System.debug('***FIELD==3===>'+String.valueOf(field.getDescribe().getType()));
                if(String.valueOf(field.getDescribe().getType())=='BOOLEAN' && (!String.valueOf(field).equalsIgnoreCase('IsDeleted'))){
                   PBSettings.put(field,false);
                }
            }
            update PBSettings;
        }
        //If value doesnt exist create and try and set all flag to false
        if(ProcessBuilderSettings__c.getValues(UserInfo.getUserId())==null){
            Map<String, Schema.SObjectField> m = Schema.SObjectType.ProcessBuilderSettings__c.fields.getMap();
            ProcessBuilderSettings__c PBSettings = new ProcessBuilderSettings__c();
            PBSettings.SetupOwnerId = UserInfo.getUserId();
            for(Schema.SObjectField field : m.values()){
                System.debug('***FIELD==4===>'+String.valueOf(field.getDescribe().getType()));
                if(String.valueOf(field.getDescribe().getType())=='BOOLEAN' && (!String.valueOf(field).equalsIgnoreCase('IsDeleted'))){
                   PBSettings.put(field,false);
                }
            }
            insert PBSettings;
        }     
    
    }
}