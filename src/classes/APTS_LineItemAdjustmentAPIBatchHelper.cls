/************************************************************
Apex Class: APTS_LineItemAdjustmentAPIBatchHelper
@Author: Sai Sagar
@CreateDate: 01-10-2018
Description: Common Batch helper for Pricing API
*************************************************************/   
global with sharing class APTS_LineItemAdjustmentAPIBatchHelper implements APTS_CommonBatchHandler {
    
  // 10 Records
  global void processBatchRecords(Database.BatchableContext context, List<Apttus_Config2__ProductConfiguration__c> configurationList,boolean control){
    
    Map<Id,Map<Apttus_Config2__LineItem__c,List<Apttus_Config2__AdjustmentLineItem__c>>> lineItemMigrationMap = new Map<Id,Map<Apttus_Config2__LineItem__c,List<Apttus_Config2__AdjustmentLineItem__c>>>(); 
    Map<Id,List<Apttus_Config2__AdjustmentLineItem__c>> adjustmentlineItemMap = new Map<Id,List<Apttus_Config2__AdjustmentLineItem__c>>();
    Map<id,Apttus_Config2__LineItem__c> lineItemMap = new Map<id,Apttus_Config2__LineItem__c>();
     
    String lineitemFields=''; 
    String assetAdjLineItemFields=''; 
     //Get fields from object Asset Adjustment Line Item
    String SobjectApiName = 'Apttus_Config2__AdjustmentLineItem__c';
    Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
    Map<String, Schema.SObjectField> fieldMap = schemaMap.get(SobjectApiName).getDescribe().fields.getMap();
    for(String fieldName : fieldMap.keyset()){
        if(assetAdjLineItemFields == null || assetAdjLineItemFields == ''){
            assetAdjLineItemFields = fieldName;
        }else{
            assetAdjLineItemFields = assetAdjLineItemFields + ', ' + fieldName;
        }
    }
    // Get Current Batch Execution State
    List<APTS_Batch_Job_Execution__c> currentBatch = [Select id,APTS_Total_Records__c,APTS_Total_Records_Failed__c,Second_Query__c from APTS_Batch_Job_Execution__c where APTS_Job_ID__c =: context.getJobId()];
    integer processedRecords = configurationList.size();
    processedRecords = currentBatch[currentBatch.size() - 1].APTS_Total_Records__c == null? processedRecords: Integer.valueOf(currentBatch[currentBatch.size() - 1].APTS_Total_Records__c+processedRecords);
    integer totalRecordsFailed =  currentBatch[currentBatch.size() - 1].APTS_Total_Records_Failed__c == null? 0: Integer.valueOf(currentBatch[currentBatch.size() - 1].APTS_Total_Records_Failed__c);
    //Variables declaration
    List<APTS_Batch_Error__c> lstErrorLogs = new List<APTS_Batch_Error__c>(); 
    //For each line item reprice
    if(configurationList.size() > 0 && currentBatch.size() > 0){
    Set<Id> configurationId = new Set<Id>();
    for(Apttus_Config2__ProductConfiguration__c configID:configurationList){
      configurationId.add(configID.id);
    } 
    
    if(currentBatch[0].Second_Query__c != null){
      lineitemFields = currentBatch[0].Second_Query__c;
    }
    String strQuery = 'SELECT ' + lineitemFields + ' FROM Apttus_Config2__LineItem__c WHERE Apttus_Config2__ConfigurationId__c  in : configurationId';
    
    Set<Id> lineItemId = new Set<Id>(); 
    for(Apttus_Config2__LineItem__c obj: Database.query(strQuery)){
        lineItemId.add(obj.Id); 
        lineItemmap.put(obj.Id,obj);
    }  
    String strQueryAssetAdjLineItem = 'SELECT ' + assetAdjLineItemFields + ' FROM Apttus_Config2__AdjustmentLineItem__c WHERE Apttus_Config2__LineItemId__c in : lineItemId'; 
    
    for(Apttus_Config2__AdjustmentLineItem__c obj: Database.query(strQueryAssetAdjLineItem)){  
        if(adjustmentLineItemMap.containsKey(obj.Apttus_Config2__LineItemId__c)){
            List<Apttus_Config2__AdjustmentLineItem__c> adjLineItem = adjustmentLineItemMap.get(obj.Apttus_Config2__LineItemId__c);
            adjLineItem.add(obj);
            adjustmentLineItemMap.put(obj.Apttus_Config2__LineItemId__c, adjLineItem);
        }else{
            List<Apttus_Config2__AdjustmentLineItem__c> adjLineItems = new List<Apttus_Config2__AdjustmentLineItem__c>();
            adjLineItems.add(obj);
            adjustmentLineItemMap.put(obj.Apttus_Config2__LineItemId__c,adjLineItems);
        } 
    }
    
    
    for(id liId :lineItemmap.keyset()){
        List<Apttus_Config2__AdjustmentLineItem__c> adjustmentlist = new List<Apttus_Config2__AdjustmentLineItem__c>();
        if(adjustmentLineItemMap.containsKey(liId)){
            adjustmentlist = adjustmentLineItemMap.get(liId);
        }       
        if(lineItemMigrationMap.containsKey(lineItemmap.get(liId).Apttus_Config2__ConfigurationId__c)){  
            lineItemMigrationMap.get(lineItemmap.get(liId).Apttus_Config2__ConfigurationId__c).put(lineItemmap.get(liId),adjustmentlist); 
        }else{ 
            Map<Apttus_Config2__LineItem__c,List<Apttus_Config2__AdjustmentLineItem__c>> mapAdjustmentLineItem = new Map<Apttus_Config2__LineItem__c,List<Apttus_Config2__AdjustmentLineItem__c>>();
            mapAdjustmentLineItem.put(lineItemmap.get(liId),adjustmentlist);
            lineItemMigrationMap.put(lineItemmap.get(liId).Apttus_Config2__ConfigurationId__c,mapAdjustmentLineItem);
          }
    } 
    
    for(Id cartid:lineItemMigrationMap.keyset()){
        try{
            system.debug(Logginglevel.ERROR,'cartid::::::' + cartid);   
            if(lineItemMigrationMap.containsKey(cartid)){
                APTS_MigrationZX10 instMigration = new APTS_MigrationZX10(cartid,lineItemMigrationMap.get(cartid)); 
            }
        }Catch(Exception e){          
          totalRecordsFailed = totalRecordsFailed+1;
          system.debug(Logginglevel.ERROR,'Exception on Adjust API Batch:::::' + e.getMessage() + '<>' +  e.getStackTraceString());        
          lstErrorLogs.add(APTS_CommonBatch_Helper.createBatchErrorObject(currentBatch[0].Id, e.getMessage() + '<>' +  e.getStackTraceString(), cartid, 'Apttus_Config2__ProductConfiguration__c', 'Error Occured During Parallel Batch Processing', 'APTS_LineItemAdjustmentAPIBatchHelper'));
        }
      }
      //Log errors
      if(lstErrorLogs.size() > 0){
        APTS_CommonBatch_Helper.createBatchErrorLogs(lstErrorLogs);        
      }      
    }
    
    if(currentBatch.size() > 0){                  
      APTS_CommonBatch_Helper.updateExecutionLog(context.getJobId(),'In Progress',processedRecords,totalRecordsFailed );
    }    
  }

}