/*************************************************************
@Name: APTS_AssetRenewalBatch_Phase2
@Author: Karan Khatri
@CreateDate: 15-07-2019
@Description: Batch class to process assets that are to be auto-renewed= new
*****************************************************************/
global class APTS_AssetRenewalBatch_Phase2 implements Database.Batchable<sObject>{
    String query;
    private static String BATCHNAME = 'APTS_AutoRenewalBatch_Phase2';
    private static String STREAM = 'CLM';
    private static String TYPE = 'Batch';
    String thread_number;
    global APTS_AssetRenewalBatch_Phase2(String threadNumber){
        this.thread_number = threadNumber;
    }
    

   global Database.QueryLocator start(Database.BatchableContext BC){
        try{
            for(APTS_Batch_Queries__mdt batchQuery : [SELECT Id,
                                                          APTS_Query_String__c
                                                          FROM APTS_Batch_Queries__mdt
                                                          WHERE APTS_Batch_Name__c =: BATCHNAME]){
               
                  query = batchQuery.APTS_Query_String__c;
                if(String.isNotBlank(thread_number) && thread_number != '0'){
                    query = query  + ' and APTS_thread_sequence__c = \''+thread_number+'\'';
                }           
                  
                //system.debug('query ++++ '  + query);
            }
            
            return Database.getQueryLocator(query);
        }catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), TYPE, String.valueOf(ex) ,BATCHNAME, null, STREAM, false, false, null, true); return null;}
    }

    global void execute(Database.BatchableContext BC, List<sObject> autoRenewStagingList) {
        Set<Id> agreementIdSet = new Set<Id>();
        Map<Id, Apttus__APTS_Agreement__c> agreementMap = new Map<Id, Apttus__APTS_Agreement__c>();
        Map<Id, Account> accountMap = new Map<Id, Account>();
        List<Apttus_Config2__Order__c> orderList = new List<Apttus_Config2__Order__c>();
        Map<Id, List<Id>> assetIdMap = new Map<Id, List<Id>>();
        Set<Id> assetIdSet = new Set<Id>();
        List<APTS_Auto_renewal_staging__c> transUpdateList = new List<APTS_Auto_renewal_staging__c>();
        Set<Id> assetIdSet2 = new Set<Id>();
        Map<Id,Id> autoRenewalOrderMap = new Map<Id,Id>();
        Map<Id,Id> orderRenewalStagingMap = new Map<Id,Id>();
        Map<Id,APTS_Auto_renewal_staging__c> autoRenewalErrorMap = new Map<Id,APTS_Auto_renewal_staging__c>();
        try{   
            System.debug('******autoRenewStagingList=====>'+autoRenewStagingList);
            //System.debug('******assetIdMap=====>'+assetIdMap);
            //System.debug('******agreementMap=====>'+agreementMap);
            //System.debug('******accountMap=====>'+accountMap);
            //System.debug('******assetIdSet2=====>'+assetIdSet2);
            for(APTS_Auto_renewal_staging__c autoRenewStaging : (List<APTS_Auto_renewal_staging__c>) autoRenewStagingList){
                Apttus_Config2__Order__c oOrder = APTS_CLMUtil.createAdminOrder(autoRenewStaging.APTS_Affected_Asset_Line_Item__r.APTS_relatedlist_agreement__r,autoRenewStaging.APTS_Affected_Asset_Line_Item__r.Apttus_Config2__AccountId__r,'Renewal');
                oOrder.APTS_Auto_renewal_staging_source_id__c =autoRenewStaging.id;
                oOrder.CurrencyIsoCode=autoRenewStaging.APTS_Affected_Asset_Line_Item__r.CurrencyIsoCode;
                oOrder.Apttus_Config2__OrderStartDate__c=autoRenewStaging.APTS_Affected_Asset_Line_Item__r.Apttus_Config2__EndDate__c.addDays(1);
                oOrder.Apttus_Config2__OrderEndDate__c=oOrder.Apttus_Config2__OrderStartDate__c.addMonths(12).addDays(-1);
                orderList.add(oOrder);
                if(assetIdMap.get(autoRenewStaging.APTS_Affected_Asset_Line_Item__r.APTS_relatedlist_agreement__c)==null){
                   assetIdMap.put(autoRenewStaging.APTS_Affected_Asset_Line_Item__r.APTS_relatedlist_agreement__c, new List<Id>{autoRenewStaging.APTS_Affected_Asset_Line_Item__c});
                }else{
                    assetIdMap.get(autoRenewStaging.APTS_Affected_Asset_Line_Item__r.APTS_relatedlist_agreement__c).add(autoRenewStaging.APTS_Affected_Asset_Line_Item__c);
                }
            }
            //System.debug('****assetIdMap=====>'+assetIdMap);
            if(orderList.size() > 0){
                Database.insert(orderList, false);
            }
            
            for(Apttus_Config2__Order__c oOrder : orderList){
                if(orderRenewalStagingMap.get(oOrder.id)==null){
                    orderRenewalStagingMap.put(oOrder.id,oOrder.APTS_Auto_renewal_staging_source_id__c);
                }
            }
            //System.debug('******orderList=====>'+orderList);
            for(Apttus_Config2__Order__c oOrder : orderList){
                if(oOrder != null && oOrder.Id != null){
                    Id cartId = APTS_OrderUtils.createCart(oOrder.Id);
                    if(assetIdMap.containsKey(oOrder.Apttus_CMConfig__AgreementId__c) && assetIdMap.get(oOrder.Apttus_CMConfig__AgreementId__c) != null){
                        autoRenewalErrorMap = activateOrder(cartId, assetIdMap.get(oOrder.Apttus_CMConfig__AgreementId__c), oOrder.Id,orderRenewalStagingMap);
                        transUpdateList.addAll(autoRenewalErrorMap.values());
                    }
                }
                if(autoRenewalOrderMap.get(oOrder.APTS_Auto_renewal_staging_source_id__c)==null){
                    autoRenewalOrderMap.put(oOrder.APTS_Auto_renewal_staging_source_id__c,oOrder.id);
                }
            }
            
            for(APTS_Auto_renewal_staging__c autoRenewStaging : (List<APTS_Auto_renewal_staging__c>) autoRenewStagingList){
                if(autoRenewalErrorMap.isEmpty() || (!autoRenewalErrorMap.isEmpty() && autoRenewalErrorMap.get(autoRenewStaging.id)==null)){
                    autoRenewStaging.APTS_Process_status__c = 'Processed';
                    autoRenewStaging.APTS_Comments__c = 'Processed with no errors';
                    if(!autoRenewalOrderMap.isEmpty() && autoRenewalOrderMap.get(autoRenewStaging.id)!=null){
                        autoRenewStaging.APTS_Associated_order__c=autoRenewalOrderMap.get(autoRenewStaging.id);
                    }
                    transUpdateList.add(autoRenewStaging);
                }
            }
            //System.debug('******transUpdateList=====>'+transUpdateList);
            if(!transUpdateList.isEmpty()){
                Database.update(transUpdateList, false);
            }
            
        }catch(Exception ex){
            System.debug('******failure=====>'+ex.getMessage() + ex.getLineNumber());
            List<APTS_Auto_renewal_staging__c> autoRenStagErrorList = new List<APTS_Auto_renewal_staging__c>();
            for(APTS_Auto_renewal_staging__c autoRenewStaging : (List<APTS_Auto_renewal_staging__c>) autoRenewStagingList){
                    autoRenewStaging.APTS_Process_status__c = 'Processed with errors'; 
                    autoRenewStaging.APTS_Comments__c = String.valueOf(ex) + '\n\n' + ex.getStackTraceString();
                    //autoRenewStaging.APTS_Error_details__c = ex.getMessage();
                    autoRenStagErrorList.add(autoRenewStaging);
            }
            if(!autoRenStagErrorList.isEmpty()){
                Database.update(autoRenStagErrorList, false);
            }
            System.debug('******autoRenStagErrorList- failure=====>'+autoRenStagErrorList);
        }
    }
    public Map<Id,APTS_Auto_renewal_staging__c> activateOrder(Id cartId, List<Id> assetLIIdList, Id orderId,Map<Id,Id> orderRenewalStagingMap) {
        System.debug('*****cartId=====>'+cartId);
        System.debug('*****assetLIIdList=====>'+assetLIIdList);
        System.debug('*****orderId=====>'+orderId);
        System.debug('*****cartId=====>'+cartId);
        Map<Id,APTS_Auto_renewal_staging__c> autoRenewalErrorMap = new Map<Id,APTS_Auto_renewal_staging__c>();
        Apttus_Config2.CPQStruct.ChangeAssetsRequestDO request = new Apttus_Config2.CPQStruct.ChangeAssetsRequestDO();
        request.AssetIds = assetLIIdList;
        request.CartId = cartId;
        Apttus_Config2.CPQStruct.ChangeAssetsResponseDO response = Apttus_Config2.AssetService.changeAssets(request);
        
        System.debug('******response===============>'+response);
        if((response.LineItemMap==null || (response.LineItemMap!=null && response.LineItemMap.isEmpty())) && !orderRenewalStagingMap.isEmpty() && orderRenewalStagingMap.get(orderId)!=null){
            Id autoRenewalAssetId = orderRenewalStagingMap.get(orderId);
            APTS_Auto_renewal_staging__c autoRenewStaging = new APTS_Auto_renewal_staging__c(id=autoRenewalAssetId);
            autoRenewStaging.APTS_Process_status__c = 'Processed with errors'; 
            autoRenewStaging.APTS_Comments__c = 'Error while doing change asset - No line items were pulled!';
            if(autoRenewalErrorMap.get(autoRenewStaging.id)==null){
                autoRenewalErrorMap.put(autoRenewStaging.id,autoRenewStaging);
            }
        }else{
            APTS_OrderUtils.repriceCart(cartId);
            if(!Test.isRunningTest()){
                if(cartId != null && orderId != null) {
                    APTS_OrderUtils.repriceCart(cartId);
                    APTS_OrderUtils.repriceCart(cartId);
                    APTS_OrderUtils.finalizeCart(cartId);
                    APTS_OrderUtils.syncCart(cartId);
                    APTS_OrderUtils.acceptOrder(orderId);
                }
            }
        }
        return autoRenewalErrorMap;
    }
    global void finish(Database.BatchableContext BC) {
        Set<String> pendingJobStatus = new Set<String>{'Preparing','Processing','Queued','Holding'};
        List<AsyncApexJob> pendingJobs = [select Status from AsyncApexJob where ApexClass.name like '%AssetRenewalBatch%' and Status IN : pendingJobStatus and ParentJobId =null];
        //System.debug('*****pendingJobs=====>'+pendingJobs);
        if(pendingJobs.isEmpty()){
            if(TriggerSettings__c.getValues(UserInfo.getUserId())!=null){
                TriggerSettings__c triggerSettings = TriggerSettings__c.getValues(UserInfo.getUserId());
                Database.delete(triggerSettings,false);
            }
            if(ProcessBuilderSettings__c.getValues(UserInfo.getUserId())!=null){            
                ProcessBuilderSettings__c PBSettings = ProcessBuilderSettings__c.getValues(UserInfo.getUserId());
                Database.delete(PBSettings,false);
            }
        }
    }
}