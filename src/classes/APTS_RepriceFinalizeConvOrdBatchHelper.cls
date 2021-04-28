/******************************************************
Name: APTS_RepriceFinalizeConvOrdBatchHelper
Date: 25th Aug 2020
Desciption: Used for  Converion Order reprice and Finalization for bulk Data 
Author: Sai Sagar
Change Verison History: 
********************************************************/
global with sharing class APTS_RepriceFinalizeConvOrdBatchHelper implements APTS_CommonBatchHandler{

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
                Id cartId = APTS_OrderUtils.createCart(ord.Id);
                Id bundleId = ord.APTS_L1_Asset_Line_Item__r.Apttus_Config2__BundleAssetId__c!=null?ord.APTS_L1_Asset_Line_Item__r.Apttus_Config2__BundleAssetId__c:ord.APTS_L1_Asset_Line_Item__c;
                if(cartId!=null){
                    List<ID> assetIdList=new List<ID>();
                    Map<ID,Apttus_Config2__LineItem__c> lineItemMap=new Map<ID,Apttus_Config2__LineItem__c>();
                    assetIdList.add(bundleId);
                    Apttus_Config2.CPQStruct.ChangeAssetsRequestDO request = new Apttus_Config2.CPQStruct.ChangeAssetsRequestDO();
                    request.AssetIds = assetIdList;
                    request.CartId = cartId;
                    Apttus_Config2.CPQStruct.ChangeAssetsResponseDO response = Apttus_Config2.AssetService.changeAssets(request);
                    if((response.LineItemMap==null || (response.LineItemMap!=null && response.LineItemMap.isEmpty())) ){
                        results.totalRecordsFailed = results.totalRecordsFailed+1;                               
                        String errorMessage = 'Add line items to Cart.Apttus_Config2.changeAssets';
                        lstErrorLogs.add(APTS_CommonBatch_Helper.createBatchErrorObject( currentBatch[0].Id, errorMessage, ord.Id, 'Order', 'Error Occured inBatch Processing:  Change Asset API returned NULL', 'APTS_RepriceFinalizeConvOrdBatchHelper'));	                        
                    }
                    else{
                        lineItemMap=response.LineItemMap;
                    }
                    Apttus_CPQApi.CPQWebService.associateConstraintRules(cartId,null);
                    Apttus_CPQApi.CPQWebService.applyConstraintRules(cartId, false);
                    APTS_OrderUtils.repriceCart(cartId);
                    APTS_OrderUtils.repriceCart(cartId);
                    APTS_OrderUtils.repriceCart(cartId);
                    APTS_OrderUtils.finalizeCart(cartId); 
                    APTS_OrderUtils.syncCart(cartId);                   
                }
            }            
        }catch(Exception e){
            results.totalRecordsFailed = results.totalRecordsFailed+scopeList.size();                  
            lstErrorLogs.add(APTS_CommonBatch_Helper.createBatchErrorObject( currentBatch[0].Id, e.getMessage() + '<>' +  e.getStackTraceString(), '', 'Order', 'Error Occured in Batch Processing:  Reprice and Finalize Order Config', 'APTS_RepriceFinalizeConvOrdBatchHelper'));	                        
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