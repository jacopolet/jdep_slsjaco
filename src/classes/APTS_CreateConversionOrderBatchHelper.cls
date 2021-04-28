/******************************************************
Name: APTS_CreateCoversionOrderBatchHelper
Date: 25th Aug 2020
Desciption: Used for Creating Converion Order for bulk Data 
Author: Sai Sagar
Change Verison History: 
********************************************************/
global with sharing class APTS_CreateConversionOrderBatchHelper implements APTS_CommonBatchHandler {
    // ScopeList - L1 Asset Id's
    global void processBatchRecords(Database.BatchableContext context, List<Apttus_Config2__AssetLineItem__c> scopeList, boolean control){
        APTS_CommonBatch.BatchResults results = new APTS_CommonBatch.BatchResults(); 
        List<APTS_Batch_Job_Execution__c> currentBatch = [Select id,APTS_Total_Records__c,Second_Query__c , APTS_Total_Records_Failed__c from APTS_Batch_Job_Execution__c where APTS_Job_ID__c =: context.getJobId()];
        integer processedRecords = scopeList.size();        
        List<APTS_Batch_Error__c> lstErrorLogs = new List<APTS_Batch_Error__c>();
        string assetLineQuery = '';
        if(currentBatch.size() > 0){
            results.processedRecords = currentBatch[currentBatch.size() - 1].APTS_Total_Records__c == null? processedRecords: Integer.valueOf(currentBatch[currentBatch.size() - 1].APTS_Total_Records__c+processedRecords);
            results.totalRecordsFailed =  currentBatch[currentBatch.size() - 1].APTS_Total_Records_Failed__c == null? 0: Integer.valueOf(currentBatch[currentBatch.size() - 1].APTS_Total_Records_Failed__c);                   
        }   
        
        try{
            if(scopeList != null && scopeList.size() > 0 ){                                     
                List<Apttus_Config2__Order__c> orderList = new List<Apttus_Config2__Order__c>();
                orderList  = APTS_CreateConversionOrderBatchHelper.createConversionOrder(scopeList,'','');
                if(orderList.size() > 0){
                    APTS_OrderUtils.stopOrderTrigger();
                    Database.SaveResult[] srList = Database.insert(orderList, false);
                    // Iterate through each returned result
                    for (Database.SaveResult sr : srList) {
                        if (sr.isSuccess()) {}
                        else {
                            // Operation failed, so get all errors                
                            for(Database.Error err : sr.getErrors()) {
                                System.debug('The following error has occurred.');                    
                                String errorMessage = err.getStatusCode() + ': ' + err.getMessage();
                                lstErrorLogs.add(APTS_CommonBatch_Helper.createBatchErrorObject( currentBatch[0].Id, errorMessage, '', 'Order', 'Error Occured During Parallel Batch Processing:  Order Creation for CAD', 'APTS_CreateCoversionOrderBatchHelper'));	                                                        
                            }
                        }
                    }                    
                    APTS_OrderUtils.startOrderTrigger();
                }
            }
        }catch(Exception e){
            results.totalRecordsFailed = results.totalRecordsFailed+scopeList.size();       
            lstErrorLogs.add(APTS_CommonBatch_Helper.createBatchErrorObject(currentBatch[0].Id, e.getMessage() + '<>' +  e.getStackTraceString(), '', 'Order', 'Error Occured During Parallel Batch Processing:  Order Creation for CAD', 'APTS_CreateCoversionOrderBatchHelper'));
        }

        //Log errors
        if(lstErrorLogs.size() > 0){
            APTS_CommonBatch_Helper.createBatchErrorLogs(lstErrorLogs);
        }

        if(currentBatch.size() > 0){                                    
            APTS_CommonBatch_Helper.updateExecutionLog(context.getJobId(),'In Progress',results.processedRecords,results.totalRecordsFailed );
        }        
    }

    global static List<Apttus_Config2__Order__c> createConversionOrder(list<Apttus_Config2__AssetLineItem__c> primaryL1Assets,String subSubType,String orderInput){
        List<Apttus_Config2__Order__c> orderList = new List<Apttus_Config2__Order__c>();               
        for(Apttus_Config2__AssetLineItem__c l1AssetId: primaryL1Assets){
                    Apttus_Config2__Order__c oOrder = APTS_CLMUtil.createAdminOrder(l1AssetId.APTS_relatedlist_agreement__r,l1AssetId.Apttus_Config2__AccountId__r,'Conversion Order');
                oOrder.APTS_Order_Sub_Sub_Type__c=subSubType;
                if(orderInput!=null){
                    oOrder.APTS_Conversion_Order_Input__c=orderInput;
                }
                oOrder.APTS_L1_Asset_Line_Item__c  = l1AssetId.Id;
                oOrder.CurrencyIsoCode=l1AssetId.CurrencyIsoCode;
                orderList.add(oOrder);
        }
        return orderList;
    }
}