/************************************************************
Apex Class: APTS_LineItemsPricingBatchHelper
@Author: Sai Sagar
@CreateDate: 24-05-2018
Description: Common Batch helper for Pricing API
*************************************************************/
global with sharing class APTS_LineItemsPricingBatchHelper implements APTS_CommonBatchHandler {
    
    // 10 Records
    global void processBatchRecords(Database.BatchableContext context, List<Apttus_Config2__LineItem__c> lstLineItems,boolean control){
        System.debug('control_____________________----'+control);       
        // Get Current Batch Execution State
        List<APTS_Batch_Job_Execution__c> currentBatch = [Select id,APTS_Total_Records__c,APTS_Total_Records_Failed__c from APTS_Batch_Job_Execution__c where APTS_Job_ID__c =: context.getJobId()];
        integer processedRecords = lstLineItems.size();
        processedRecords = currentBatch[currentBatch.size() - 1].APTS_Total_Records__c == null? processedRecords: Integer.valueOf(currentBatch[currentBatch.size() - 1].APTS_Total_Records__c+processedRecords);
        integer totalRecordsFailed =  currentBatch[currentBatch.size() - 1].APTS_Total_Records_Failed__c == null? 0: Integer.valueOf(currentBatch[currentBatch.size() - 1].APTS_Total_Records_Failed__c);
        //Variables declaration
        List<APTS_Batch_Error__c> lstErrorLogs = new List<APTS_Batch_Error__c>();
        Boolean pricingResult;
        System.debug('Logger Enabled - ----'+control);
        String LoggerMessage = '';
        //For each line item reprice
        if(lstLineItems.size() > 0 && currentBatch.size() > 0){
            for(Apttus_Config2__LineItem__c currentLI : lstLineItems){
                if(currentLI.Apttus_Config2__LineNumber__c != null){
                    try{
                        LoggerMessage = 'Before Pricing Call: '+ System.now() + '\r\n';         
                        Integer lineNumber = Integer.ValueOf(currentLI.Apttus_Config2__LineNumber__c);
                        pricingResult = Apttus_Config2.PricingWebService.computeBasePriceForItemColl(currentLI.Apttus_Config2__ConfigurationId__c, lineNumber);                 
                        if(control){ 
                            LoggerMessage = LoggerMessage + 'currentLI::::::' + currentLI.Id + '\r\n';
                            LoggerMessage = LoggerMessage + 'After Pricing Call: '+ System.now() + '\r\n';
                            List<Apttus_Config2__LineItem__c> liList = APTS_LineItemsPricingBatchHelper.getLineItem(new Set<Id> {currentLI.Apttus_Config2__ConfigurationId__c}, new Set<Integer>{lineNumber} );                     
                            LoggerMessage = LoggerMessage + ''+liList;
                            LoggerMessage = LoggerMessage + 'Pricing Response::::::' + pricingResult + '\r\n';
                            // Creating for Debugging the issue on Pricing
                            lstErrorLogs.add(APTS_CommonBatch_Helper.createBatchErrorObject(currentBatch[0].Id, LoggerMessage , currentLI.Id, 'Apttus_Config2__LineItem__c', 'NOT a Error : Record for Logging Pricing Request and Response', 'APTS_LineItemsPricingBatchHelper'));
                        }                   
                        system.debug(Logginglevel.ERROR,'Pricing result::::::' + pricingResult);                                                                
                    }Catch(Exception e){                    
                        totalRecordsFailed = totalRecordsFailed+1;
                        system.debug(Logginglevel.ERROR,'Exception repriceLineItems:::::' + e.getMessage() + '<>' +  e.getStackTraceString());              
                        lstErrorLogs.add(APTS_CommonBatch_Helper.createBatchErrorObject(currentBatch[0].Id, e.getMessage() + '<>' +  e.getStackTraceString(), currentLI.Id, 'Apttus_Config2__LineItem__c', 'Error Occured During Parallel Batch Processing', 'APTS_LineItemsPricingBatchHelper'));
                    }
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


    global static List<Apttus_Config2__LineItem__c> getLineItem(Set<Id> lineItemIds, Set<Integer> lineNumbers){
        
        return  [select id,Apttus_Config2__ListPrice__c,Apttus_Config2__NetPrice__c, APTS_Net_Adjustment_Amount__c, Apttus_Config2__AdjustmentAmount__c, Apttus_Config2__AdjustedPrice__c  from Apttus_Config2__LineItem__c where Apttus_Config2__ConfigurationId__c =: lineItemIds AND Apttus_Config2__LineNumber__c =: lineNumbers];
    }
}