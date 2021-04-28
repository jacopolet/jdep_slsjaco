/*************************************************************
@Name: APTS_UpdateFinancialStartDateQueueable
@Author: Mahesh Chilaka
@CreateDate: 09-09-2020
@Description: DQ-369 - This queueable job is used to updated the FinancialStartDate on Assets when an Asset Movement successfully moved to RAR/LAE (SAP).
@UsedBy: APTS_UpdateFinancialStartDateQueueable
******************************************************************/
/*
@Version History : v1.0 - created
                  
*/
public with sharing class APTS_UpdateFinancialStartDateQueueable Implements Queueable {
    
    public void execute(QueueableContext context) {

        //Set<String> classNames = new Set<String>{'APTS_UpdateFinancialStartDateQueueable'};
        Map<Id, Date> mapAssetswithStagingDate = new Map<Id, Date>();
        List<Apttus_Config2__AssetLineItem__c> listAssetLineItem = new List<Apttus_Config2__AssetLineItem__c>();
        List<RTR_LAE_Staging_Data__c> listStagingData = new List<RTR_LAE_Staging_Data__c>();
        Date todayDate = System.Today();
        
        for(RTR_LAE_Staging_Data__c stagingData : getStagingData005(todayDate)){
            if(stagingData.APTS_Start_Date__c != null){
                mapAssetswithStagingDate.put(stagingData.APTS_Asset_Line_Item__c, stagingData.APTS_Start_Date__c);
            }
            stagingData.APTS_isFinancialStartDateUpdated__c = true; 
            listStagingData.add(stagingData);
         }

         for(Apttus_Config2__AssetLineItem__c asset : [SELECT Id, APTS_Financial_Start_Date__c
                                                        FROM Apttus_Config2__AssetLineItem__c 
                                                        WHERE Id IN: mapAssetswithStagingDate.keyset()]){

            asset.APTS_Financial_Start_Date__c = mapAssetswithStagingDate.get(asset.Id);
            listAssetLineItem.add(asset);       
         }
    

        if(!listAssetLineItem.isEmpty()){
            try{
                APTS_CheckRecursive.processedSet.add('APTS_AssetLineItemTriggerHandlerBeforeUpdate');
                APTS_CheckRecursive.processedSet.add('APTS_AssetLineItemTriggerHandlerAfterUpdate');
                Database.update(listAssetLineItem);
                Database.update(listStagingData);
            }catch(Exception ex){
                APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString()+'/n/n'+ex.getMessage() , 'APTS_UpdateFinancialStartDateQueueable', null, 'CLM', false, false, null, true); 
            }
        
        }

        if(!getStagingData005(todayDate).isEmpty()){
            system.enqueueJob(new APTS_UpdateFinancialStartDateQueueable());
        }

    }

     public static List<RTR_LAE_Staging_Data__c> getStagingData005(Date todayDate){
        Integer batchSize = 25; 

        for(LAE_RAR_StagingStaticData__mdt stgBatch : [SELECT MasterLabel,qualifiedApiName,DeveloperName, BatchSize__c FROM LAE_RAR_StagingStaticData__mdt WHERE qualifiedApiName='FinancialStartDateBatchSize']){
            batchSize = Integer.valueOf(stgBatch.BatchSize__c);
        }

        return [SELECT Id, APTS_Asset_Line_Item__c, APTS_Start_Date__c 
                FROM RTR_LAE_Staging_Data__c
                WHERE APTS_Integration_Log_Id__c != null 
                    AND APTS_Asset_Line_Item__c != null
                    AND APTS_Business_Transaction_Type__c = 'B005'
                    AND APTS_isFinancialStartDateUpdated__c = false
                    AND CreatedDate >=: todayDate LIMIT: batchSize];
     }
}