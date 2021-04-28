/*************************************************************
@Name: APTS_ValidateAssetsBfrProcessStagingJob
@Author: Mahesh Chilaka
@CreateDate: 25-08-2020
@Description: DQ-2484 - This batch apex will validate the Assets Data prior to APTS_ProcessStaging Job.
@UsedBy: 
******************************************************************/
/*
@Version History : v1.0 - created
                   v1.1 - 11/09/2020 - DQ-369 -  Added condition to validate the FinancialStartDate is not null.
                   v1.2 - 22/09/2020 - DQ-3783 - Added new fields to execute the user submitted request in chronological order.
e                   V1.3 - 14/01/2021 - DQ-4869 - Unblock the Asset Validation

*/
public class APTS_ValidateAssetsBfrProcessStagingJob implements Database.Batchable<sObject>{
    
 
    public Database.QueryLocator start(Database.BatchableContext BC){
    
         List < APTS_RTR_Scheduler_Query__c > lstSchQuery = new List < APTS_RTR_Scheduler_Query__c > ();
         Map < Id, RTR_LAE_Transaction_Data__c > mapTransData = new Map < Id, RTR_LAE_Transaction_Data__c > ();
         Set<String> setChargeType = new Set<String>{'Service Fee', 'Rental Fee', 'Sales Price'};
         Set < String > setAgreementNumber = New Set < String > ();
         Set < String > setFinanceId = New Set < String > ();
         Set < String > setALINumber = New Set < String > ();
         Set < String > setCompanyCode = New Set < String > ();
         Set < String > setBusinessType = New Set < String > ();
         Set < String > setTypeofContract = New Set < String > ();
         Set < String > setTransID = New Set < String > ();
         Set < Id > finalsetTransID = New Set < Id > ();
         Set < Id > setAssetId = new Set < Id > ();
         Set < Id > setTransDataID = new Set < Id > ();
         Date contEffStartDate, contEffEndDate;
         Boolean contInterFlag;
         String whereClause = '';
         String processStaging = System.Label.APTS_LAE_Job_Status_Process_Staging;
         String queryString = 'SELECT Id, APTS_Business_Transaction_Type__c, APTS_Asset_Line_Item__r.Apttus_Config2__EndDate__c,' 
                             +'APTS_Contract_Effective_Date__c, APTS_Asset_Line_Item__r.APTS_Type_Of_Contract__c, APTS_Asset_Line_Item__c,'
                             +'CreatedDate, APTS_Asset_Line_Item__r.Apttus_Config2__OriginalStartDate__c, APTS_Asset_Processed__c,'
                             +'Error_in_Processing__c, Error_Description__c , APTS_Asset_Line_Item__r.APTS_Financial_Start_Date__c '
                             +'FROM RTR_LAE_Transaction_Data__c WHERE Id != null ';
                                
          for (APTS_RTR_Scheduler_Query__c schQuery: [SELECT APTS_Agreement_Number__c, Asset_Line_Item_Number__c, APTS_Business_Transaction_Type__c, APTS_Company_Code__c,
                                                             APTS_Contract_Effective_End_Date__c, APTS_Contract_Effective_Start_Date__c, APTS_Controlled_Interface_Flag__c,
                                                             APTS_Finance_ID__c, APTS_LAE_RAR_Transaction_ID__c, APTS_Type_of_Contract__c, isProcessed__c, isDataValidated__c,
                                                             APTS_Current_Job_Work_In_Progress__c
                                                      FROM APTS_RTR_Scheduler_Query__c
                                                      WHERE isBatchableRequest__c = true AND isProcessed__c = false AND isDataValidated__c = false 
                                                      ORDER BY Createddate desc LIMIT 1
                                                      ]) {
         
             IF(!string.isBlank(schQuery.APTS_Agreement_Number__c)) setAgreementNumber.addAll(schQuery.APTS_Agreement_Number__c.split(','));
             IF(!string.isBlank(schQuery.APTS_Finance_ID__c)) setFinanceId.addAll(schQuery.APTS_Finance_ID__c.split(','));
             IF(!string.isBlank(schQuery.Asset_Line_Item_Number__c)) setALINumber.addAll(schQuery.Asset_Line_Item_Number__c.split(','));
             IF(!string.isBlank(schQuery.APTS_Company_Code__c)) setCompanyCode.addAll(schQuery.APTS_Company_Code__c.split(','));
             IF(!string.isBlank(schQuery.APTS_Business_Transaction_Type__c)) setBusinessType.addAll(schQuery.APTS_Business_Transaction_Type__c.split(','));
             IF(!string.isBlank(schQuery.APTS_Type_of_Contract__c)) setTypeofContract.addAll(schQuery.APTS_Type_of_Contract__c.split(','));
             IF(!string.isBlank(schQuery.APTS_LAE_RAR_Transaction_ID__c)) setTransID.addAll(schQuery.APTS_LAE_RAR_Transaction_ID__c.split(','));
             contInterFlag = schQuery.APTS_Controlled_Interface_Flag__c;
             contEffStartDate = schQuery.APTS_Contract_Effective_Start_Date__c;
             contEffEndDate = schQuery.APTS_Contract_Effective_End_Date__c;
             schQuery.isDataValidated__c = true;
             //v1.2 - START
             schQuery.APTS_Current_Job_Work_In_Progress__c = processStaging;
             //v1.2 - END
             lstSchQuery.add(schQuery);
         }
         if (!lstSchQuery.isEmpty()) {
             update lstSchQuery;
         }
         
         if(contEffStartDate != null && contEffEndDate != null){
             whereClause += ' AND (APTS_Contract_Effective_Date__c >= :contEffStartDate AND APTS_Contract_Effective_Date__c <= :contEffEndDate) ';
         }
         if (!setCompanyCode.isEmpty()) {
             whereClause += ' AND APTS_Asset_Line_Item__r.APttus_Config2__AccountId__r.Mini_Company_Code__c IN: setCompanyCode ';
         }
         if (!setBusinessType.isEmpty()) {
             whereClause += ' AND APTS_Business_Transaction_Type__c IN: setBusinessType ';
         }
         if (!setTypeofContract.isEmpty()) {
             whereClause += ' AND APTS_Asset_Line_Item__r.APTS_Type_Of_Contract__c IN: setTypeofContract ';
         }
         if (!setAgreementNumber.isEmpty()) {
             whereClause += ' AND APTS_Asset_Line_Item__r.Apttus_CMConfig__AgreementId__r.Apttus__Agreement_Number__c IN: setAgreementNumber ';
         }
         if (!setFinanceId.isEmpty()) {
             whereClause += ' AND APTS_Asset_Line_Item__r.APTS_FinanceId__c IN: setFinanceId ';
         }
         if (!setALINumber.isEmpty()) {
             whereClause += ' AND APTS_Asset_Line_Item__r.APTS_Asset_Line_Item_Number__c IN: setALINumber ';
         }
         if (!setTransID.isEmpty()) {
             whereClause += ' AND Id IN: setTransID ';
         }
         if (!String.isBlank(whereClause)) {
              whereClause += ' AND APTS_Controlled_Interface_Flag__c =: contInterFlag'
                          + ' AND APTS_Asset_Line_Item__r.Apttus_Config2__ChargeType__c IN: setChargeType AND APTS_Asset_Processed__c = false'
                          + ' ORDER BY APTS_Contract_Effective_Date__c ASC'; 
             system.debug(' ==> '+ queryString + whereClause);
             queryString = queryString+whereClause;
             return Database.getQueryLocator(queryString);
         }
             return Database.getQueryLocator(queryString + ' LIMIT 0');
         
         
    }
  
    public void execute(Database.BatchableContext BC, List < RTR_LAE_Transaction_Data__c > listTransData){
         List < RTR_LAE_Transaction_Data__c > listUpdateTransData = new List < RTR_LAE_Transaction_Data__c > ();
         Map < Id, RTR_LAE_Transaction_Data__c > mapUpdateTransData = new Map < Id, RTR_LAE_Transaction_Data__c > ();
         Set < Id > setAssetId_002 = new Set < Id > ();
         Set < Id > setAssetIdLaterCreated_003 = new Set < Id > ();
         Set < DateTime > setTransCreatedDate_002 = new Set < DateTime > ();
         String errMsgEffectiveDate = System.Label.APTS_LAE_Tx_Err_Effective_Date;
         String errMsgEffectiveDateAfterRenewal = System.Label.APTS_LAE_Tx_Err_Effective_Date_Renewal;
         String errMsgOriginalDate = System.Label.APTS_LAE_Tx_Err_Asset_Original_Start_Date;
         
         for (RTR_LAE_Transaction_Data__c transData: listTransData) {
         
             if (transData.APTS_Business_Transaction_Type__c.contains('0002') &&
                 transData.APTS_Asset_Line_Item__r.Apttus_Config2__EndDate__c != transData.APTS_Contract_Effective_Date__c &&
                 !transData.APTS_Asset_Line_Item__r.APTS_Type_Of_Contract__c.contains('Sales')) {
                 setAssetId_002.add(transData.APTS_Asset_Line_Item__c);
                 setTransCreatedDate_002.add(transData.CreatedDate);
             }
             //V1.3 - START
             //v1.1 - START
            /* if (transData.APTS_Asset_Line_Item__r.Apttus_Config2__EndDate__c <= transData.APTS_Asset_Line_Item__r.APTS_Financial_Start_Date__c) {
                 transData.APTS_Asset_Processed__c = True;
                 transData.Error_in_Processing__c = True;
                 transData.Error_Description__c = transData.Error_Description__c != null ? transData.Error_Description__c + ';' + errMsgOriginalDate : errMsgOriginalDate;
                 mapUpdateTransData.put(transData.Id, transData);
             }*/
             //v1.1 - END
             //V1.3 -END
         }
         
         if (!setAssetId_002.isEmpty()) {
             for (RTR_LAE_Transaction_Data__c transData: [SELECT Id, APTS_Asset_Line_Item__c
                                                             FROM RTR_LAE_Transaction_Data__c
                                                             WHERE APTS_Asset_Line_Item__c IN: setAssetId_002
                                                                 AND APTS_Business_Transaction_Type__c = '0003'
                                                                 AND APTS_Asset_Processed__c = False
                                                                 AND Error_in_Processing__c = False
                                                                 AND CreatedDate >: setTransCreatedDate_002 LIMIT 5000
                                                             ]) {
             
                 setAssetIdLaterCreated_003.add(transData.APTS_Asset_Line_Item__c);
             
             }
         }
         
        
         for (RTR_LAE_Transaction_Data__c transData: listTransData) {
         
             if (transData.APTS_Business_Transaction_Type__c.contains('0002') && setAssetIdLaterCreated_003.contains(transData.APTS_Asset_Line_Item__c)) {
                 transData.APTS_Asset_Processed__c = True;
                 transData.Error_in_Processing__c = False;
                 transData.Error_Description__c = transData.Error_Description__c != null ? transData.Error_Description__c + ';' + errMsgEffectiveDateAfterRenewal : errMsgEffectiveDateAfterRenewal;
                 mapUpdateTransData.put(transData.Id, transData);
             } else if (transData.APTS_Business_Transaction_Type__c.contains('0002') && !setAssetIdLaterCreated_003.contains(transData.APTS_Asset_Line_Item__c) && setAssetId_002.contains(transData.APTS_Asset_Line_Item__c)) {
                 transData.APTS_Asset_Processed__c = True;
                 transData.Error_in_Processing__c = True;
                 transData.Error_Description__c = transData.Error_Description__c != null ? transData.Error_Description__c + ';' + errMsgEffectiveDate : errMsgEffectiveDate;
                 mapUpdateTransData.put(transData.Id, transData);
             }
         
         }
         
         
         if (!mapUpdateTransData.isEmpty()) {
             try {
                 update mapUpdateTransData.values();
             }catch(Exception ex){
                 APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString()+'/n/n'+ex.getMessage() , 'APTS_ValidateAssetsBfrProcessStagingJob', null, 'CLM', false, false, null, true); 
             }
     
         }
    }
  
    public void finish(Database.BatchableContext BC){
       Set < String > classNames = new Set < String > {'APTS_ProcessStaging'};
       Integer batchSize = APTS_RtRSchedulerComponentController.getStagingBatchSize();
       
       Id profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].ID;
       List < APTS_RTR_Scheduler_Query__c > lstSchQuery = [SELECT Id FROM APTS_RTR_Scheduler_Query__c WHERE isBatchableRequest__c =: true AND isProcessed__c =: false AND isDataValidated__c =: false ORDER BY Createddate desc LIMIT 1];
       // && userInfo.getProfileId() != profileId
       if (!lstSchQuery.isEmpty() && !Test.isRunningTest()) {
           APTS_ValidateAssetsBfrProcessStagingJob validateJob = new APTS_ValidateAssetsBfrProcessStagingJob();
           Database.executeBatch(validateJob);
       } else if (lstSchQuery.isEmpty() && !Test.isRunningTest() && !APTS_LAE_RAR_Reinterface.isJobRunning(classNames)) {
           APTS_ProcessStaging stagingJobExt = new APTS_ProcessStaging();
           Database.executeBatch(stagingJobExt, batchSize);
       }
    }
 }