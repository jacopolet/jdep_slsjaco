/******************************************************
Name: APTS_ActivateConversionOrderBatchHelper
Date: 25th Aug 2020
Desciption: Used for Converion Order Activation for bulk Data 
Author: Sai Sagar
Change Verison History: 
********************************************************/
global with sharing class APTS_ActivateConversionOrderBatchHelper implements APTS_CommonBatchHandler{

    global void processBatchRecords(Database.BatchableContext context, List<Apttus_Config2__Order__c> scopeList, boolean control){
        APTS_CommonBatch.BatchResults results = new APTS_CommonBatch.BatchResults(); 
        List<APTS_Batch_Job_Execution__c> currentBatch = [Select id,APTS_Total_Records__c,Second_Query__c , APTS_Total_Records_Failed__c from APTS_Batch_Job_Execution__c where APTS_Job_ID__c =: context.getJobId()];
        integer processedRecords = scopeList.size();        
        List<APTS_Batch_Error__c> lstErrorLogs = new List<APTS_Batch_Error__c>();

        if(currentBatch.size() > 0){
            results.processedRecords = currentBatch[currentBatch.size() - 1].APTS_Total_Records__c == null? processedRecords: Integer.valueOf(currentBatch[currentBatch.size() - 1].APTS_Total_Records__c+processedRecords);
            results.totalRecordsFailed =  currentBatch[currentBatch.size() - 1].APTS_Total_Records_Failed__c == null? 0: Integer.valueOf(currentBatch[currentBatch.size() - 1].APTS_Total_Records_Failed__c);                   
        }   

        try{
            for(Apttus_Config2__Order__c ord: scopeList){
                Boolean isSuccess = APTS_OrderUtils.acceptOrder(ord.Id);
                if(!isSuccess || Test.isRunningTest()){
                    results.totalRecordsFailed = results.totalRecordsFailed+1;                               
                    String errorMessage = 'Failed in Accept Order';
                    lstErrorLogs.add(APTS_CommonBatch_Helper.createBatchErrorObject( currentBatch[0].Id, errorMessage, ord.Id, 'Order', 'Error Occured in Batch Processing:  Accept Order has Failed', 'APTS_ActivateConversionOrderBatchHelper'));	                                
                }
            }
        }catch(Exception e){
            results.totalRecordsFailed = results.totalRecordsFailed+scopeList.size();       
            lstErrorLogs.add(APTS_CommonBatch_Helper.createBatchErrorObject(currentBatch[0].Id, e.getMessage() + '<>' +  e.getStackTraceString(), '', 'Asset', 'Exception Occured During Parallel Batch Processing:  Order Activation for CAD', 'APTS_ActivateConversionOrderBatchHelper'));
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