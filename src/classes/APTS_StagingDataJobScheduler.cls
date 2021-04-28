/*************************************************************
@Name: APTS_StagingDataJobScheduler
@Author: Shahul
@CreateDate: 17-11-2020
@Description: 
@UsedBy: 
******************************************************************/

global without sharing class APTS_StagingDataJobScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
    
    Set<String> setChargeType = new Set<String>{'Service Fee', 'Rental Fee', 'Sales Price'};
    String lineType = 'Product/Service';
    List<RTR_LAE_Transaction_Data__c> earliestdate= new List<RTR_LAE_Transaction_Data__c>();
    List<RTR_LAE_Transaction_Data__c> latestdate= new List<RTR_LAE_Transaction_Data__c>();
    
    earliestdate=[SELECT Id,APTS_Contract_Effective_Date__c
    FROM RTR_LAE_Transaction_Data__c
    WHERE APTS_Asset_Processed__c = false AND isDeleted = false
    AND Error_in_Processing__c = false AND APTS_Asset_Line_Item__c != null
    AND APTS_Asset_Line_Item__r.Apttus_Config2__ChargeType__c IN : setChargeType
    AND APTS_Asset_Line_Item__r.Apttus_Config2__LineType__c =: lineType and APTS_Contract_Effective_Date__c!=null order by APTS_Contract_Effective_Date__c ASC LIMIT 1];

    latestdate=[SELECT Id,APTS_Contract_Effective_Date__c
    FROM RTR_LAE_Transaction_Data__c
    WHERE APTS_Asset_Processed__c = false AND isDeleted = false
    AND Error_in_Processing__c = false AND APTS_Asset_Line_Item__c != null
    AND APTS_Asset_Line_Item__r.Apttus_Config2__ChargeType__c IN : setChargeType
    AND APTS_Asset_Line_Item__r.Apttus_Config2__LineType__c =: lineType and APTS_Contract_Effective_Date__c!=null order by APTS_Contract_Effective_Date__c DESC LIMIT 1];
    
    if((earliestdate!=null &&!earliestdate.isempty())&&(latestdate!=null&&!latestdate.isempty())){
    APTS_RTR_Scheduler_Query__c schQuery = new APTS_RTR_Scheduler_Query__c(); 
    schQuery.APTS_Contract_Effective_Start_Date__c = earliestdate[0].APTS_Contract_Effective_Date__c;schQuery.APTS_Contract_Effective_End_Date__c = System.today()-1;  
    schQuery.isBatchableRequest__c = true;insert schQuery;
    }
    
    Integer batchSize = APTS_RtRSchedulerComponentController.getStagingBatchSize();
    APTS_ValidateAssetsBfrProcessStagingJob validateJob = new APTS_ValidateAssetsBfrProcessStagingJob();
    Database.executeBatch(validateJob,batchSize);
    //APTS_ProcessStaging stagingJobExt = new APTS_ProcessStaging();
    //database.executebatch(stagingJobExt, batchSize);
    }
}