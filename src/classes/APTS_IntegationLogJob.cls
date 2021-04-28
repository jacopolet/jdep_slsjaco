/*************************************************************
@Name: APTS_IntegationLogJob
@Author: Pranjal Mittal
@CreateDate: 23-01-2018
@Description: 
@UsedBy: 
******************************************************************/
//v101 09-Sept-2019 Mahesh Chilaka : DFT2C-856 - Added ExecuteExt method for ad-hoc request.

global class APTS_IntegationLogJob implements Database.Batchable<sObject>, Database.Stateful {
    
    String query;
    public Map<Id, RTR_LAE_Staging_Data__c> mapStageData = new Map<Id, RTR_LAE_Staging_Data__c>();
    static final String TRANS_A005 = 'A005';
    static final String TRANS_B005 = 'B005';
    Map<Id, Integration_Log__c> mapAssetLogId = new Map<Id, Integration_Log__c>();
    Date effectiveDate;
    Set<ID> assetIdSet = new Set<ID>();

    global APTS_IntegationLogJob(){}

    global APTS_IntegationLogJob(Map<Id, RTR_LAE_Staging_Data__c> mapStageData, Date effectiveDate) {
        try
        {
            this.mapStageData = mapStageData;
            this.effectiveDate = effectiveDate;
            for(RTR_LAE_Staging_Data__c stagingSO : [Select ID, APTS_Asset_Line_Item__c, APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__c from RTR_LAE_Staging_Data__c where ID IN: mapStageData.values()])
            {
                if(stagingSO.APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__c != null)
                {
                    assetIdSet.add(stagingSO.APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__c);
                }
                else
                {
                    assetIdSet.add(stagingSO.APTS_Asset_Line_Item__c);
                }
            }
            query = 'Select ID from Apttus_Config2__AssetLineItem__c where ID IN :assetIdSet';
        }
        catch(Exception ex)
        {
            APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'APEX', ex.getStackTraceString()+' Message:'+ex.getMessage() ,'APTS_IntegationLogJob Constructor', null,'CLM',false,false, null, true);
        }
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Apttus_Config2__AssetLineItem__c> scope) {
        List<Apttus_Config2__AssetLineItem__c> assetLineItemWithStaging = [SELECT ID, (SELECT Id, APTS_Asset_Line_Item__c,  APTS_Serial_Number__c, APTS_Contract_Number__c, APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__c, 
                                                                                        APTS_Business_Transaction_Type__c FROM Apttus_Integration_Logs__r 
                                                                                        WHERE APTS_Contract_Effective_Date__c =: effectiveDate 
                                                                                             ORDER BY CreatedDate DESC LIMIT 1 ) 
                                                                           FROM Apttus_Config2__AssetLineItem__c 
                                                                           WHERE (ID IN :scope OR APTS_Is_Primary_L1_Asset__c IN :scope)];

        executeExt(assetLineItemWithStaging, false);
    }
    
    global void finish(Database.BatchableContext BC){
        try
        {
            update mapStageData.values();
            for(Integration_Log__c tmpLog : mapAssetLogId.values()){
                tmpLog.Object_Id__c = tmpLog.Id;
                tmpLog.Integration_Status__c = 'Initial';
            }
            upsert mapAssetLogId.values();
        }
        catch(Exception ex)
        {
            APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'APEX', ex.getStackTraceString()+' Message:'+ex.getMessage() ,'APTS_IntegationLogJob finish', null,'CLM',false,false, null, true);
        }
    }

    //v101 09-Sept-2019 Mahesh Chilaka : DFT2C-856 - START.
    @TestVisible
    public void executeExt(List<Apttus_Config2__AssetLineItem__c> assetLineItemWithStaging, Boolean adhocRequest){
        try
        {
            Map<Id, Integration_Log__c> mapTempAssetLogId = new Map<Id, Integration_Log__c>();            
            Map<Id, Set<Id>> mapParentChildAsset = new Map<Id, Set<Id>>();
            Map<Id, Id> mapAssetStageId = new Map<Id, Id>();
            Map<String, Id> mapSerialAssetId = new Map<String, Id>();

            //if(mapStageData.isEmpty()){ adhocRequest = true; }

            for(Apttus_Config2__AssetLineItem__c assetLineItemSO : assetLineItemWithStaging)
            {
                for(RTR_LAE_Staging_Data__c tmpStageData : assetLineItemSO.Apttus_Integration_Logs__r){
                    
                    
                    if((adhocRequest || !mapStageData.containsKey(tmpStageData.Id)) && !tmpStageData.APTS_Business_Transaction_Type__c.equalsIgnoreCase(TRANS_A005) ){
                        mapStageData.put(tmpStageData.Id, tmpStageData);
                        mapAssetStageId.put(tmpStageData.APTS_Asset_Line_Item__c, tmpStageData.Id);
                    }
    
                    if(tmpStageData.APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__c == NULL
                         && !mapParentChildAsset.containsKey(tmpStageData.APTS_Asset_Line_Item__c)){
                        
                            mapParentChildAsset.put(tmpStageData.APTS_Asset_Line_Item__c, new Set<Id>{tmpStageData.APTS_Asset_Line_Item__c});
                    }
                    else if(tmpStageData.APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__c != NULL){
                        if(mapParentChildAsset.containsKey(tmpStageData.APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__c)){
                            mapParentChildAsset.get(tmpStageData.APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__c).add(tmpStageData.APTS_Asset_Line_Item__c);
                        }
                        else{
                            Set<Id> setChildId = new Set<Id>();
                            setChildId.add(tmpStageData.APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__c);
                            setChildId.add(tmpStageData.APTS_Asset_Line_Item__c);
                            mapParentChildAsset.put(tmpStageData.APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__c, setChildId);
                        }
                    }
    
                    if(tmpStageData.APTS_Business_Transaction_Type__c.equalsIgnoreCase(TRANS_B005) && tmpStageData.APTS_Serial_Number__c != NULL){
                        mapSerialAssetId.put(tmpStageData.APTS_Serial_Number__c, tmpStageData.APTS_Asset_Line_Item__c);
                    }
                }
            }
            system.debug('$$$$$$ mapParentChildAsset '+mapParentChildAsset);
            system.debug('$$$$$$ mapStageData : '+mapStageData);
            Boolean toUpsert = false;
    
            for(Id tmpId : mapParentChildAsset.keySet()){
                if(!mapTempAssetLogId.containsKey(tmpId)){
                    system.debug('mapStageData :'+mapAssetStageId.get(tmpId)+' '+mapStageData.containsKey(mapAssetStageId.get(tmpId)));
                    if(mapAssetStageId.containsKey(tmpId) && mapStageData.containsKey(mapAssetStageId.get(tmpId)) && !mapStageData.get(mapAssetStageId.get(tmpId)).APTS_Business_Transaction_Type__c.equalsIgnoreCase(TRANS_A005)){
                        Integration_Log__c newLog = new Integration_Log__c();
                        newLog.Object__c = 'RTR_LAE_Staging_Data__c';
                        newLog.Integration_Status__c = 'Paused';
                        newLog.Object_Id__c = 'dummyId';
                        //mapAssetLogId.put(tmpId, newLog);
                        mapTempAssetLogId.put(tmpId, newLog);
                        toUpsert = true;
                    }else if(!mapAssetStageId.containsKey(tmpId)){
                        Set<Id> noL1Staging = mapParentChildAsset.get(tmpId);
                        for(Id processId: noL1Staging){
                            if(processId != tmpId){
                                Integration_Log__c newLog = new Integration_Log__c();
                                newLog.Object__c = 'RTR_LAE_Staging_Data__c';
                                newLog.Integration_Status__c = 'Paused';
                                newLog.Object_Id__c = 'dummyId';
                                //mapAssetLogId.put(tmpId, newLog);
                                mapTempAssetLogId.put(tmpId, newLog);
                                toUpsert = true;
                            }
                        }
                    }
                }
            }
            
            if(toUpsert){
                upsert mapTempAssetLogId.values();
                mapAssetLogId.putAll(mapTempAssetLogId);
            }
    
            for(Id bundleId : mapParentChildAsset.keySet()){
                if(mapAssetStageId.containsKey(bundleId) && mapStageData.containsKey(mapAssetStageId.get(bundleId)) && mapAssetLogId.containsKey(bundleId) && mapAssetLogId.get(bundleId).Id != null)
                {
                    mapStageData.get(mapAssetStageId.get(bundleId)).APTS_Integration_Log_Id__c = mapAssetLogId.get(bundleId).Id;
                }
                for(Id childId : mapParentChildAsset.get(bundleId)){
                    if(mapStageData.containsKey(mapAssetStageId.get(childId)) && mapAssetStageId.containsKey(childId) && mapAssetLogId.containsKey(bundleId) && mapAssetLogId.get(bundleId).Id != null){
                        mapStageData.get(mapAssetStageId.get(childId)).APTS_Integration_Log_Id__c = mapAssetLogId.get(bundleId).Id;
                    }
                }
            }
    
            List<RTR_LAE_Staging_Data__c> lstOfOldStagingData = [SELECT Id, APTS_Integration_Log_Id__c, APTS_Serial_Number__c, APTS_Business_Transaction_Type__c, APTS_Asset_Line_Item__r.APTS_Physical_Asset__r.ParentPhysicalAsset__r.InitialActivationDate__c, APTS_Asset_Line_Item__r.APTS_Physical_Asset__r.InitialActivationDate__c, APTS_Remaining_Useful_Life__c, APTS_Contract_Effective_Date__c, APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__c, APTS_AssetProcessed__c FROM RTR_LAE_Staging_Data__c WHERE APTS_Serial_Number__c IN: mapSerialAssetId.keySet() AND APTS_Business_Transaction_Type__c = 'A005' AND APTS_AssetProcessed__c =: false];
            Boolean oldUpdateRequired = false;
            system.debug('$$$$ lstOfOldStagingData '+lstOfOldStagingData);
            if(lstOfOldStagingData != NULL && lstOfOldStagingData.size() > 0){
                oldUpdateRequired = true;
                for(RTR_LAE_Staging_Data__c tmpOld : lstOfOldStagingData){
                    Id parentBundleId;
                    for(Id bundleId : mapParentChildAsset.keySet()){
                        for(Id childId : mapParentChildAsset.get(bundleId)){
                            if(mapSerialAssetId.containsKey(tmpOld.APTS_Serial_Number__c) && childId == mapSerialAssetId.get(tmpOld.APTS_Serial_Number__c)){
                                parentBundleId = bundleId;
                                break;
                            }
                        }
                    }
                    if(mapAssetLogId.containsKey(parentBundleId) && mapAssetLogId.get(parentBundleId).Id != null)
                    {
                        tmpOld.APTS_Integration_Log_Id__c = (mapAssetLogId.get(parentBundleId)).Id;
                        tmpOld.APTS_AssetProcessed__c = true;
                    }
                }
            }
    
            if(oldUpdateRequired){
                update lstOfOldStagingData;
            }

            if(adhocRequest){

                 update mapStageData.values();
                for(Integration_Log__c tmpLog : mapAssetLogId.values()){
                    tmpLog.Object_Id__c = tmpLog.Id;
                    tmpLog.Integration_Status__c = 'Initial';
                }
                upsert mapAssetLogId.values();
            }
        }
        catch(Exception ex)
        {
            APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'APEX', ex.getStackTraceString()+' Message:'+ex.getMessage() ,'APTS_IntegationLogJob execute', null,'CLM',false,false, null, true);
        }
    }
    //v101 09-Sept-2019 Mahesh Chilaka : DFT2C-856 - END.
    

}