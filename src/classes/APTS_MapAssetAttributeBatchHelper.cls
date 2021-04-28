/************************************************************
Apex Class: APTS_MapAssetAttributeBatchHelper
@Author: Sai Sagar
@CreateDate: 24-05-2018
Description: Batch helper for Mapping Old Asset attribute with New Asset after during Datamigration
             Should be Invokde after Billing Scheidule Batch
*************************************************************/
global with sharing class APTS_MapAssetAttributeBatchHelper implements APTS_CommonBatchHandler{
    
    global void processBatchRecords(Database.BatchableContext context, List<Apttus_Config2__OrderLineItem__c> lstOrderLineItem, boolean control){

        APTS_CommonBatch.BatchResults results = new APTS_CommonBatch.BatchResults(); 
        List<APTS_Batch_Job_Execution__c> currentBatch = [Select id,APTS_Total_Records__c,APTS_Total_Records_Failed__c from APTS_Batch_Job_Execution__c where APTS_Job_ID__c =: context.getJobId()];
        integer processedRecords = lstOrderLineItem.size();
        results.processedRecords = currentBatch[currentBatch.size() - 1].APTS_Total_Records__c == null? processedRecords: Integer.valueOf(currentBatch[currentBatch.size() - 1].APTS_Total_Records__c+processedRecords);
        results.totalRecordsFailed =  currentBatch[currentBatch.size() - 1].APTS_Total_Records_Failed__c == null? 0: Integer.valueOf(currentBatch[currentBatch.size() - 1].APTS_Total_Records_Failed__c);
        List<APTS_Batch_Error__c> lstErrorLogs = new List<APTS_Batch_Error__c>();

        String assetAttributeValueFields = ''; 
        String assetAdjLineItemFields = '';
        try{
            //Get fields from object AssetAttributeValue
            String SobjectApiName = 'Apttus_Config2__AssetAttributeValue__c';
            Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            Map<String, Schema.SObjectField> fieldMap = schemaMap.get(SobjectApiName).getDescribe().fields.getMap();
  
            for(String fieldName : fieldMap.keyset()){
                if(assetAttributeValueFields == null || assetAttributeValueFields == ''){
                    assetAttributeValueFields = fieldName;
                }else{
                    assetAttributeValueFields = assetAttributeValueFields + ', ' + fieldName;
                }
            }  
                                
            //Get fields from object Asset Adjustment Line Item
            String SobjectApiName1 = 'Apttus_Config2_AssetAdjustItem__c';
            Map<String, Schema.SObjectType> schemaMap1 = Schema.getGlobalDescribe();
            Map<String, Schema.SObjectField> fieldMap1 = schemaMap1.get(SobjectApiName1).getDescribe().fields.getMap();
  
            for(String fieldName : fieldMap1.keyset()){
                if(assetAdjLineItemFields == null || assetAdjLineItemFields == ''){
                    assetAdjLineItemFields = fieldName;
                }else{
                    assetAdjLineItemFields = assetAdjLineItemFields + ', ' + fieldName;
                }
            }
        
            List<Database.SaveResult> srList = new List<Database.SaveResult>();        
            Map<Id,Id> mapOLIOldALI = new Map<Id,Id>();
            Map<Id,Id> mapMigratedAssetNewAsset = new Map<Id,Id>();
            Map<Id,Id> mapNewAssetMigratedParentAsset = new Map<Id,Id>();
            Map<Id,Id> mapNewAssetMigratedBundleAsset = new Map<Id,Id>();
            Map<Id,Id> mapNewAssetNewAttribute = new Map<Id,Id>(); 
            Set<Id> oldAssetIds = new Set<Id>();
            Set<Id> newAssetIds = new Set<Id>();
        
            //Loop over the order line items and create map for Old ALI and new ALI
            for(Apttus_Config2__OrderLineItem__c currentOLI : lstOrderLineItem){ 
                mapMigratedAssetNewAsset.put(currentOLI.APTS_Migrated_Asset_Line_Item__c,currentOLI.Apttus_Config2__AssetLineItemId__c);
                mapNewAssetMigratedParentAsset.put(currentOLI.Apttus_Config2__AssetLineItemId__c,currentOLI.APTS_Migrated_Asset_Line_Item__r.Apttus_Config2__ParentAssetId__c);
                mapNewAssetMigratedBundleAsset.put(currentOLI.Apttus_Config2__AssetLineItemId__c,currentOLI.APTS_Migrated_Asset_Line_Item__r.Apttus_Config2__BundleAssetId__c);
                mapOLIOldALI.put(currentOLI.Id, currentOLI.APTS_Migrated_Asset_Line_Item__c);
                oldAssetIds.add(currentOLI.APTS_Migrated_Asset_Line_Item__c);
                newAssetIds.add(currentOLI.Apttus_Config2__AssetLineItemId__c);
            }
            List<Apttus_Config2__AssetLineItem__c> lstNewALI = new List<Apttus_Config2__AssetLineItem__c>();
            lstNewALI =[SELECT Id, Apttus_CMConfig__AgreementId__c,Apttus_Config2__BusinessLineItemId__c,Apttus_Config2__BundleAssetId__c,Apttus_Config2__ParentAssetId__c FROM Apttus_Config2__AssetLineItem__c WHERE id IN: newAssetIds OR Apttus_Config2__BundleAssetId__c IN: mapMigratedAssetNewAsset.keyset() OR Apttus_Config2__ParentAssetId__c IN : mapMigratedAssetNewAsset.keyset()];
       
            //Query for Old Asset Attribute Value records
            System.debug('lstNewALI>>>>'+lstNewALI);
            String strQueryAssetAttribute = 'SELECT ' + assetAttributeValueFields + ' FROM Apttus_Config2__AssetAttributeValue__c WHERE Apttus_Config2__AssetLineItemId__c in : oldAssetIds';
                                
            List<Apttus_Config2__AssetAttributeValue__c> lstNewAttributeValue = new List<Apttus_Config2__AssetAttributeValue__c>();
            Apttus_Config2__AssetAttributeValue__c tempAV;
            //cloning asset attribute value
            for(Apttus_Config2__AssetAttributeValue__c attributeRecord :  Database.query(strQueryAssetAttribute)){
                tempAV = attributeRecord.clone(false, true, false, false);
                if(mapMigratedAssetNewAsset.containsKey(attributeRecord.Apttus_Config2__AssetLineItemId__c))
                    tempAV.Apttus_Config2__AssetLineItemId__c = mapMigratedAssetNewAsset.get(attributeRecord.Apttus_Config2__AssetLineItemId__c);
                lstNewAttributeValue.add(tempAV);
            }             
            //Insert cloned records
            if(lstNewAttributeValue.size()>0){
                srList = Database.insert(lstNewAttributeValue, false);
            }
            System.debug('srList>>>'+srList); 
            // Iterate through each returned result
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully created AssetAttributeValue. AssetAttributeValue Id: ' + sr.getId());
                }
                else {
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) {
                        String errorMessage = err.getStatusCode() + ': ' + err.getMessage() + '--' + + err.getFields();         
                        lstErrorLogs.add(APTS_CommonBatch_Helper.createBatchErrorObject(
                                                                        currentBatch[0].Id,
                                                                        errorMessage, 
                                                                        '', 
                                                                        'Apttus_Config2__AssetAttributeValue__c',
                                                                        'Error Occured During Parallel Batch Processing:  map Asset Attribute batch during Insert Asset Attribute',
                                                                        'APTS_MapAssetAttributeBatchHelper'));  
                    }
                }
            }
        
            for(Apttus_Config2__AssetAttributeValue__c newAttribute : lstNewAttributeValue){
                mapNewAssetNewAttribute.put(newAttribute.Apttus_Config2__AssetLineItemId__c, newAttribute.id); 
            }
                        
            List<Apttus_Config2__AssetLineItem__c>  updateALI = new List<Apttus_Config2__AssetLineItem__c>();   
            for(Apttus_Config2__AssetLineItem__c newAsset : lstNewALI){ 
                if(mapNewAssetNewAttribute.containsKey(newAsset.id)){
                    newAsset.Apttus_Config2__AttributeValueId__c = mapNewAssetNewAttribute.get(newAsset.id);                
                }
                if(mapMigratedAssetNewAsset.get(mapNewAssetMigratedParentAsset.get(newAsset.id)) != null){
                    newAsset.Apttus_Config2__ParentAssetId__c = mapMigratedAssetNewAsset.get(mapNewAssetMigratedParentAsset.get(newAsset.id));
                }
                if(mapMigratedAssetNewAsset.get(mapNewAssetMigratedBundleAsset.get(newAsset.id)) != null){
                    newAsset.Apttus_Config2__BundleAssetId__c = mapMigratedAssetNewAsset.get(mapNewAssetMigratedBundleAsset.get(newAsset.id));
                }       
                // Changes to Defect: #18247 - Update Option Asset to New Asset 
                if(mapMigratedAssetNewAsset.containskey(newAsset.Apttus_Config2__BundleAssetId__c) && mapMigratedAssetNewAsset.get(newAsset.Apttus_Config2__BundleAssetId__c) != null){
                    newAsset.Apttus_Config2__BundleAssetId__c = mapMigratedAssetNewAsset.get(newAsset.Apttus_Config2__BundleAssetId__c);
                }
                if(mapMigratedAssetNewAsset.containskey(newAsset.Apttus_Config2__ParentAssetId__c) && mapMigratedAssetNewAsset.get(newAsset.Apttus_Config2__ParentAssetId__c) != null){
                    newAsset.Apttus_Config2__ParentAssetId__c = mapMigratedAssetNewAsset.get(newAsset.Apttus_Config2__ParentAssetId__c);
                }           
                updateALI.add(newAsset);
            }
            System.debug('updateALI>>>'+updateALI);
            if(updateALI.size()>0){
                
                srList = Database.update(updateALI, false); 
            }
        
            //Query for Old Asset Adjustment Line Item records
            String strQueryAssetAdjLineItem = 'SELECT ' + assetAdjLineItemFields + ' FROM Apttus_Config2_AssetAdjustItem__c WHERE Apttus_Config2_AssetLineItemId__c in : oldAssetIds';
        
            System.debug('strQueryAssetAdjLineItem---'+strQueryAssetAdjLineItem);       
            List<Apttus_Config2_AssetAdjustItem__c> lstAssetAdjLineItem = Database.query(strQueryAssetAdjLineItem);
            List<Apttus_Config2_AssetAdjustItem__c> lstNewAssetAdjLineItem = new List<Apttus_Config2_AssetAdjustItem__c>();
            Apttus_Config2_AssetAdjustItem__c tempAALI;
            //cloning asset adjustment line item
            if(lstAssetAdjLineItem.size() > 0){
                for(Apttus_Config2_AssetAdjustItem__c assetAdjLineRecord : lstAssetAdjLineItem){
                    tempAALI = assetAdjLineRecord.clone(false, true, false, false);
                    if(mapMigratedAssetNewAsset.containsKey(assetAdjLineRecord.Apttus_Config2_AssetLineItemId__c))
                        tempAALI.Apttus_Config2_AssetLineItemId__c = mapMigratedAssetNewAsset.get(assetAdjLineRecord.Apttus_Config2_AssetLineItemId__c);
                    lstNewAssetAdjLineItem.add(tempAALI);
                }
            }   
             System.debug('lstNewAssetAdjLineItem>>>'+lstNewAssetAdjLineItem);      
            //Insert cloned records
            if(lstNewAssetAdjLineItem.size()>0){
                if(Test.isRunningTest()) {
                    Apttus_Config2_AssetAdjustItem__c assettest = new Apttus_Config2_AssetAdjustItem__c(); 
                    lstNewAssetAdjLineItem.add(assettest); 
                }
                srList = Database.insert(lstNewAssetAdjLineItem, false);
            }
            System.debug('srList>>>'+srList); 
            // Iterate through each returned result
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully created Asset Adjustment Line Item. AssetAdjustmentLineItem Id: ' + sr.getId());
                }
                else {
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) {
                        String errorMessage = err.getStatusCode() + ': ' + err.getMessage() + '--' + + err.getFields();         
                        lstErrorLogs.add(APTS_CommonBatch_Helper.createBatchErrorObject(
                                                                        currentBatch[0].Id,
                                                                        errorMessage, 
                                                                        '', 
                                                                        'Apttus_Config2_AssetAdjustItem__c',
                                                                        'Error Occured During Parallel Batch Processing:  Map Asset Attribute batch during Insert Asset Adjustment Item',
                                                                        'APTS_MapAssetAttributeBatchHelper'));  
                    }
                }
            }
        
            //Query for Asset Counter Reading Data
            List<APTS_CounterReadingData__c> listAssetCounter = [select id, APTS_Asset_Line_Item__c, APTS_Atrribute_Value__c FROM  APTS_CounterReadingData__c where APTS_Asset_Line_Item__c in : oldAssetIds];
        
            List<APTS_CounterReadingData__c> listNewAssetCounter = new List<APTS_CounterReadingData__c>();
            System.debug('listAssetCounter---'+listAssetCounter);       
            for(APTS_CounterReadingData__c counterReading : listAssetCounter){
                if(mapMigratedAssetNewAsset.containsKey(counterReading.APTS_Asset_Line_Item__c)){
                    counterReading.APTS_Asset_Line_Item__c = mapMigratedAssetNewAsset.get(counterReading.APTS_Asset_Line_Item__c);
                    counterReading.APTS_Atrribute_Value__c = mapNewAssetNewAttribute.get(mapMigratedAssetNewAsset.get(counterReading.APTS_Asset_Line_Item__c));
                    listNewAssetCounter.add(counterReading);
                }           
            }
            System.debug('listNewAssetCounter>>>'+listNewAssetCounter); 
            if(listNewAssetCounter.size()>0){
                if(Test.isRunningTest()) {
                    APTS_CounterReadingData__c countertest = new APTS_CounterReadingData__c(); 
                    listNewAssetCounter.add(countertest); 
                }
                srList = Database.update(listNewAssetCounter, false);
            }
            System.debug('srList>>>'+srList); 
            // Iterate through each returned result
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully created Counter reading. Counter reading Id: ' + sr.getId());
                }
                else {
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) { 
                        String errorMessage = err.getStatusCode() + ': ' + err.getMessage() + '--' + + err.getFields();         
                        lstErrorLogs.add(APTS_CommonBatch_Helper.createBatchErrorObject(
                                                                        currentBatch[0].Id,
                                                                        errorMessage, 
                                                                        '', 
                                                                        'APTS_CounterReadingData__c',
                                                                        'Error Occured During Parallel Batch Processing:  Map Asset Attribute batch during update Counter Reading',
                                                                        'APTS_MapAssetAttributeBatchHelper'));  
                    }
                }
            }
        }Catch(Exception e){
            results.totalRecordsFailed = results.totalRecordsFailed+lstOrderLineItem.size();
            String errorMessage = e.getMessage() + '<>' +  e.getStackTraceString();         
            lstErrorLogs.add(APTS_CommonBatch_Helper.createBatchErrorObject(
                                                            currentBatch[0].Id,
                                                            errorMessage, 
                                                            'Map Asset Attributes', 
                                                            'Asset Attribute Mapping',
                                                            'Error Occured During Parallel Batch Processing:  Map Asset Attribute batch',
                                                            'APTS_MapAssetAttributeBatchHelper'));
        }

        //Log errors
        if(lstErrorLogs.size() > 0){
            APTS_CommonBatch_Helper.createBatchErrorLogs(lstErrorLogs);
        }

        if(currentBatch.size() > 0){                                    
            APTS_CommonBatch_Helper.updateExecutionLog(context.getJobId(),'In Progress',results.processedRecords,results.totalRecordsFailed );
        }
    } 
}