/************************************************************
Apex Class: APTS_InActivateAssetLineItemsBatchHelper
@Author: Sai Sagar
@CreateDate: 26-09-2018
Description: Common Batch helper for InActivateAssetLineItems
*************************************************************/
global class APTS_InActivateAssetLineItemsBatchHelper implements APTS_CommonBatchHandler {
    
   
  global void processBatchRecords(Database.BatchableContext context, List<Apttus_Config2__OrderLineItem__c> lstOrderLineItems,boolean control){
    System.debug('control_____________________----'+control);    
    // Get Current Batch Execution State
    List<APTS_Batch_Job_Execution__c> currentBatch = [Select id,APTS_Total_Records__c,APTS_Total_Records_Failed__c from APTS_Batch_Job_Execution__c where APTS_Job_ID__c =: context.getJobId()];
    integer processedRecords = lstOrderLineItems.size();
    processedRecords = currentBatch[currentBatch.size() - 1].APTS_Total_Records__c == null? processedRecords: Integer.valueOf(currentBatch[currentBatch.size() - 1].APTS_Total_Records__c+processedRecords);
    integer totalRecordsFailed =  currentBatch[currentBatch.size() - 1].APTS_Total_Records_Failed__c == null? 0: Integer.valueOf(currentBatch[currentBatch.size() - 1].APTS_Total_Records_Failed__c);
    //Variables declaration
    List<APTS_Batch_Error__c> lstErrorLogs = new List<APTS_Batch_Error__c>();
    Boolean pricingResult;
    //For each Order line item reprice
    if(lstOrderLineItems.size() > 0 && currentBatch.size() > 0){
    List<Apttus_Config2__AssetLineItem__c> assetLineItemMigratedUpdateLst =new List <Apttus_Config2__AssetLineItem__c>(); 
        List<Database.SaveResult> srList = new List<Database.SaveResult>();
         List<Database.DeleteResult> srDeleteList = new List<Database.DeleteResult>();   
      for(Apttus_Config2__OrderLineItem__c currentOLI : lstOrderLineItems){ 
          system.debug(Logginglevel.ERROR,'currentOLI::::::' + currentOLI.Id);  
           if(currentOLI.APTS_Migrated_Asset_Line_Item__c != null && currentOLI.Apttus_Config2__AssetLineItemId__c != null){
            Apttus_Config2__AssetLineItem__c asset = new Apttus_Config2__AssetLineItem__c(); 
            asset.Id = currentOLI.APTS_Migrated_Asset_Line_Item__c;
            asset.Apttus_Config2__IsInactive__c = true;
            asset.APTS_Batch_Billing_Schedules__c = true;
            assetLineItemMigratedUpdateLst.add(asset);
          } 
      } 
      
      if(assetLineItemMigratedUpdateLst.size()>0){ 
                if(Test.isRunningTest()) {
                    Apttus_Config2__AssetLineItem__c assettest = new Apttus_Config2__AssetLineItem__c(); 
                    assetLineItemMigratedUpdateLst.add(assettest); 
                }
        if(!control){
          srList = Database.update(assetLineItemMigratedUpdateLst, false);
        }else{
          srDeleteList = Database.delete(assetLineItemMigratedUpdateLst, false);
        }
      }
          // Iterate through each returned result
        for (Database.SaveResult sr : srList) {
          if (sr.isSuccess()) {
            // Operation was successful, so get the ID of the record that was processed
            System.debug('Successfully Updated' + sr.getId());
          }
          else {
            // Operation failed, so get all errors                
            for(Database.Error e : sr.getErrors()) { 
              System.debug('The following error has occurred.');                    
              System.debug(e.getStatusCode() + ': ' + e.getMessage()); 
              totalRecordsFailed = totalRecordsFailed+1; 
              String errorMessage = e.getMessage();          
              lstErrorLogs.add(APTS_CommonBatch_Helper.createBatchErrorObject(
                                      currentBatch[0].Id,
                                      errorMessage, 
                                      sr.getId(), 
                                      'Apttus_Config2__AssetLineItem__c',
                                      'Error Occured During Parallel Batch Processing',
                                      'APTS_InActivateAssetLineItemsBatchHelper'));
            }
          }
        }
              // Iterate through each returned result
        for (Database.DeleteResult  sr : srDeleteList) {
          if (sr.isSuccess()) { 
            System.debug('Successfully Deleted' + sr.getId());
          }
          else {
            // Operation failed, so get all errors                
            for(Database.Error e : sr.getErrors()) { 
              System.debug('The following error has occurred.');                    
              System.debug(e.getStatusCode() + ': ' + e.getMessage()); 
              totalRecordsFailed = totalRecordsFailed+1; 
              String errorMessage = e.getMessage();          
              lstErrorLogs.add(APTS_CommonBatch_Helper.createBatchErrorObject(
                                      currentBatch[0].Id,
                                      errorMessage, 
                                      sr.getId(), 
                                      'Apttus_Config2__AssetLineItem__c',
                                      'Error Occured During Parallel Batch Processing',
                                      'APTS_InActivateAssetLineItemsBatchHelper'));
            }
          }
        }
      }  
        //Log errors
        if(lstErrorLogs.size() > 0){
            APTS_CommonBatch_Helper.createBatchErrorLogs(lstErrorLogs);        
        }  
    if(currentBatch.size() > 0){                  
      APTS_CommonBatch_Helper.updateExecutionLog(context.getJobId(),'In Progress',processedRecords,totalRecordsFailed );
    }    
  } 
}