/*************************************************************
@Name: APTS_AssetAutoRenewalBatch_Phase1
@Author: Karan Khatri
@CreateDate: 15-07-2019
@Description: Batch class to process assets that are to be auto-renewed= new
*****************************************************************/
global class APTS_AssetRenewalBatch_Phase1 implements Database.Batchable<sObject>{

    String query;
    private static String ARBATCHNAME = 'APTS_AutoRenewalBatch_Phase1';
    private static String STREAM = 'CLM';
    private static String TYPE = 'Batch';
    String allowableTriggers;

    Map<String, String> agmtIdToIndexNumberMap = new Map<String, String>();

    global Database.QueryLocator start(Database.BatchableContext BC){
        try{
            //Logic to bypass trigger logic for Auto-renewals | Avoids exceptions and improves performanace
            //bypassCurrentUserfromTriggersandFlows();
        
            List<APTS_Batch_Queries__mdt> batchQuery = [SELECT Id,    
                                                          APTS_Query_String__c
                                                          FROM APTS_Batch_Queries__mdt
                                                          WHERE APTS_Batch_Name__c =: ARBATCHNAME limit 1];
                query = batchQuery[0].APTS_Query_String__c;   
                System.debug('*******query=========>'+query);
                return Database.getQueryLocator(query);
        }catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), TYPE, String.valueOf(ex) ,ARBATCHNAME, null, STREAM, false, false, null, true); return null;}
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        Map<Id,APTS_Auto_renewal_staging__c> autoRenewalAssetMap = new Map<Id,APTS_Auto_renewal_staging__c>();
        Map<Id,Apttus_Config2__AssetLineItem__c> bundleAssetRenewalMap = new Map<Id,Apttus_Config2__AssetLineItem__c>();
        Integer icount = 1;
        boolean skip = false;
        //Map<Id,Apttus_Config2__BundleAssetId__c> assetBundleIdERAMap = new Map<Id,Apttus_Config2__BundleAssetId__c>();
        Set<Id> bundleAssetIdSet = new Set<Id>();
        Map<Id,Boolean> inProgressDeInstallBundleMap = new Map<Id,Boolean>();
         for(Apttus_Config2__AssetLineItem__c astLine1 : (List<Apttus_Config2__AssetLineItem__c>) scope){
            //assetMap.put(astLine.Id, astLine);
            if(String.IsNotBlank(astLine1.Apttus_Config2__BundleAssetId__c)){
                bundleAssetIdSet.add(astLine1.Apttus_Config2__BundleAssetId__c);
            }
        }
        inProgressDeInstallBundleMap = APTS_ValidationCallBack.validateIfDeinstallationOrder(bundleAssetIdSet);
        for(Apttus_Config2__AssetLineItem__c astLine : (List<Apttus_Config2__AssetLineItem__c>) scope){
            //Mark Bundle as auto renewed
            /*Apttus_Config2__AssetLineItem__c bundleAsset = new Apttus_Config2__AssetLineItem__c(id=astLine.Apttus_Config2__BundleAssetId__c);
            bundleAsset.APTS_is_Auto_renewed__c = true;
            if(bundleAssetRenewalMap.get(astLine.Apttus_Config2__BundleAssetId__c)==null){
                bundleAssetRenewalMap.put(astLine.Apttus_Config2__BundleAssetId__c,bundleAsset);
            }*/
            //Creates a Auto renewal staging record
            APTS_Auto_renewal_staging__c autoRenewalStaging = new APTS_Auto_renewal_staging__c();
            autoRenewalStaging.APTS_Affected_Asset_Line_Item__c = astLine.Apttus_Config2__BundleAssetId__c;
            autoRenewalStaging.APTS_Assets_Old_start_date__c = astLine.Apttus_Config2__BundleAssetId__r.Apttus_Config2__StartDate__c;
            autoRenewalStaging.APTS_Assets_old_end_date__c = astLine.Apttus_Config2__BundleAssetId__r.Apttus_Config2__EndDate__c;
            autoRenewalStaging.APTS_Process_status__c = 'Unprocessed';
            autoRenewalStaging.APTS_Auto_renewal_staging_Ext_id__c=astLine.Apttus_Config2__BundleAssetId__c + '|' +String.valueOf(astLine.Apttus_Config2__BundleAssetId__r.Apttus_Config2__EndDate__c.year());
            autoRenewalStaging.APTS_Phase_1_date_and_time_for_Rollback__c=System.now();
           
            if(astLine.Apttus_Config2__BundleAssetId__c!=null && !inProgressDeInstallBundleMap.isEmpty() && inProgressDeInstallBundleMap.KeySet().contains(astLine.Apttus_Config2__BundleAssetId__c)){
                autoRenewalStaging.APTS_Process_status__c = 'Ignored';
                autoRenewalStaging.APTS_Comments__c = 'Open de-installation against the order thus no renewal can be done';
            }
            if(autoRenewalAssetMap.get(astLine.Apttus_Config2__BundleAssetId__c)==null){
                skip=false; 
                autoRenewalStaging.APTS_thread_sequence__c = String.valueOf(icount); 
                autoRenewalAssetMap.put(astLine.Apttus_Config2__BundleAssetId__c,autoRenewalStaging);
                System.debug('old count====>'+icount);
                if(icount == Integer.valueOf(System.Label.APTS_AutoRenewalBatch2Size)){ 
                    icount = 1;
                    skip = true;
                }
                System.debug('old count====>'+icount);
                if(!skip){
                    icount++;
                }
                System.debug('new count====>'+icount);
            }
            
        }
        /*if(!bundleAssetRenewalMap.isEmpty()){
            Database.update(bundleAssetRenewalMap.values(),false);
            System.debug('bundleAssetRenewalMap=====ADDED======>'+bundleAssetRenewalMap);
        }*/

        System.debug('autoRenewalAssetMap===========>'+autoRenewalAssetMap);
        if(!autoRenewalAssetMap.isEmpty()){
            Database.upsert(autoRenewalAssetMap.values(),APTS_Auto_renewal_staging__c.fields.APTS_Auto_renewal_staging_Ext_id__c,false);
            System.debug('autoRenewalAssetMap=====ADDED======>'+autoRenewalAssetMap);
        }
    }

    global void finish(Database.BatchableContext BC) {
        Integer autoRenewalBatch2Size = Integer.valueOf(System.Label.APTS_AutoRenewalBatch2Size);
        //Not greater than 3 threads are allowed | Risk on ORG BATCH DEADLOCK
        if(autoRenewalBatch2Size<=3){
            /*For(Integer i=1;i<=autoRenewalBatch2Size;i++){
                Database.executeBatch(new APTS_AssetRenewalBatch_Phase2(String.valueOf(i)),1);
            }*/
			if(autoRenewalBatch2Size==3){
				Database.executeBatch(new APTS_AssetRenewalBatch_Phase2(String.valueOf('1')),1);
				Database.executeBatch(new APTS_AssetRenewalBatch_Phase2(String.valueOf('2')),1);
				Database.executeBatch(new APTS_AssetRenewalBatch_Phase2(String.valueOf('3')),1);
			}
			if(autoRenewalBatch2Size==2){
				Database.executeBatch(new APTS_AssetRenewalBatch_Phase2(String.valueOf('1')),1);
				Database.executeBatch(new APTS_AssetRenewalBatch_Phase2(String.valueOf('2')),1);
			}
			if(autoRenewalBatch2Size==1){
				Database.executeBatch(new APTS_AssetRenewalBatch_Phase2(String.valueOf('1')),1);
			}
        }
    }
}