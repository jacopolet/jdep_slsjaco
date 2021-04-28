/*************************************************************
@Name: APTS_RtRSchedulerComponentController
@Author: Mahesh Chilaka
@CreateDate: 18-09-2019
@Description: Controller class for APTS_RtRSchedulerComponent
lightning component
@UsedBy: APTS_RtRSchedulerComponent
******************************************************************/
/*
@Version History : v1.0 - created
                   v1.1 - 19/11/2019 - DFT2C-1990 - Restrict system admin to access scheduler page.
                   v1.2 - 25/08/2020 - DQ-2484 - Added logic will execute Batch Job to validate Asset's DeInstallation and Original Start Date.
                   v1.3 - 22/09/2020 - DQ-3783 - Added new fields to execute the user submitted request in chronological order.
*/
public without sharing class APTS_RtRSchedulerComponentController {

   
    /****************************************************************** 
    @Description: This aura method is defined to check the user input should be process for creating staging job.
    @Params : String, String, String, String, String, String, String, String, String
    @return : Boolean
    ******************************************************************/
    @AuraEnabled
    public static Boolean scheduleRtRBatch(String batchStartDate, String batchEndDate, String companyCode, String businessType, String typeofContract, String agreementNumber, String financeId, String aliNumber, String transId, String controlledFlag){
        
        Map<Id, RTR_LAE_Transaction_Data__c> mapTransData = new Map<Id, RTR_LAE_Transaction_Data__c>();
        Set<Id> setAssetId = new Set<Id>();
        Set<Id> setTransDataIds = New Set<Id>();
        Set<String> setAgreementNumber = New Set<String>();
        Set<String> setFinanceId = New Set<String>();
        Set<String> setALINumber = New Set<String>();
        Set<String> setCompanyCode = New Set<String>();
        Set<String> setBusinessType = New Set<String>();
        Set<String> setTypeofContract = New Set<String>();
        Set<String> setTransID = New Set<String>();
        Set<Id> finalsetadhocTransID = New Set<Id>();
        Set<String> setSchBusinesstype = new Set<String>();
        Set<String> classNames = new Set<String>{'APTS_StagingDataJob'};
        Set<String> classValidate = new Set<String>{'APTS_ValidateAssetsBeforeProcessStagingJob'};
        Set<String> setChargeType = new Set<String>{'Service Fee', 'Rental Fee', 'Sales Price'};
        String lineType = 'Product/Service';
        String ACTIVATED = 'Activated';
        String queryString = ' SELECT Id, APTS_Asset_Processed__c, APTS_Asset_Line_Item__c, Error_in_Processing__c, APTS_Business_Transaction_Type__c FROM RTR_LAE_Transaction_Data__c WHERE Id != null ';
        String whereClause = '';
        Date contEffStartDate, contEffEndDate, pickEffectiveDate;
        Boolean contInterFlag;
        Boolean contInterFlagadhoc;
        Integer batchSize = getStagingBatchSize();
    
        try{
            contInterFlag = controlledFlag == 'True' ? true : false;

            APTS_RTR_Scheduler_Query__c schQuery = new APTS_RTR_Scheduler_Query__c(); 
            schQuery.APTS_Contract_Effective_Start_Date__c = Date.valueOf(batchStartDate); 
            schQuery.APTS_Contract_Effective_End_Date__c = Date.valueOf(batchEndDate);  
            //v1.3 - START
            schQuery.APTS_Current_Job_Carry_Out_CED__c =  Date.valueOf(batchStartDate);   
            //v1.3 - END         
            schQuery.APTS_Company_Code__c = companyCode;
            schQuery.APTS_Business_Transaction_Type__c = businessType;
            schQuery.APTS_Type_of_Contract__c = typeofContract;
            schQuery.APTS_Agreement_Number__c = agreementNumber;
            schQuery.APTS_Finance_ID__c = financeId;
            schQuery.Asset_Line_Item_Number__c = aliNumber;
            schQuery.APTS_LAE_RAR_Transaction_ID__c = transId;
            schQuery.APTS_Controlled_Interface_Flag__c = contInterFlag;


            setCompanyCode.addAll(typeCastStringtoSet(companyCode));
            setBusinessType.addAll(typeCastStringtoSet(businessType));
            setTypeofContract.addAll(typeCastStringtoSet(typeofContract));
            setAgreementNumber.addAll(typeCastStringtoSet(agreementNumber));
            setFinanceId.addAll(typeCastStringtoSet(financeId));
            setALINumber.addAll(typeCastStringtoSet(aliNumber));
            setTransID.addAll(typeCastStringtoSet(transId));
              
           if(!String.isBlank(batchStartDate) && !String.isBlank(batchEndDate)){    
               contEffStartDate = Date.valueOf(batchStartDate);
               contEffEndDate = Date.valueOf(batchEndDate);
               whereClause += ' AND (APTS_Contract_Effective_Date__c >=: contEffStartDate AND APTS_Contract_Effective_Date__c <=: contEffEndDate) ';
            }
            if(!setCompanyCode.isEmpty()){
                whereClause += ' AND APTS_Asset_Line_Item__r.Apttus_Config2__AccountId__r.Mini_Company_Code__c IN: setCompanyCode ';
            }
            if(!setBusinessType.isEmpty()){
                whereClause += ' AND APTS_Business_Transaction_Type__c IN: setBusinessType ';
            }
            if(!setTypeofContract.isEmpty()){
                whereClause += ' AND APTS_Asset_Line_Item__r.APTS_Type_Of_Contract__c IN: setTypeofContract ';
            }
            if(!setAgreementNumber.isEmpty()){
                whereClause += ' AND APTS_Asset_Line_Item__r.Apttus_CMConfig__AgreementId__r.Apttus__Agreement_Number__c IN: setAgreementNumber ';
            }
            if(!setFinanceId.isEmpty()){
                whereClause += ' AND APTS_Asset_Line_Item__r.APTS_FinanceId__c IN: setFinanceId ';
            }
            if(!setALINumber.isEmpty()){
                whereClause += ' AND APTS_Asset_Line_Item__r.APTS_Asset_Line_Item_Number__c IN: setALINumber ';
            }
            if(!setTransID.isEmpty()){
                whereClause += ' AND Id IN: setTransID ';
            }
             
            system.debug('WhereClause :'+ whereClause);
            
            if(!String.isBlank(whereClause) ){

                whereClause += ' AND APTS_Controlled_Interface_Flag__c =: contInterFlag ';
                whereClause += ' AND APTS_Asset_Line_Item__r.Apttus_Config2__ChargeType__c IN: setChargeType AND APTS_Asset_Processed__c = false ';
                whereClause += ' ORDER BY  APTS_Contract_Effective_Date__c ASC LIMIT 5000';
               
                mapTransData = new Map<Id, RTR_LAE_Transaction_Data__c>((List<RTR_LAE_Transaction_Data__c>) Database.Query(queryString+whereClause));
                
                /*  // DQ-2484 As per new requirement, This code is no longer used  -- START
                for(RTR_LAE_Transaction_Data__c transDataExt : mapTransData.values()){
                finalsetadhocTransID.add(transDataExt.Id);
                    if(transDataExt.APTS_Business_Transaction_Type__c.contains('005')){
                        setAssetId.add(transDataExt.APTS_Asset_Line_Item__c);
                    }
                    
                }
                
                for(RTR_LAE_Transaction_Data__c transDataExt : [SELECT  Id, APTS_Asset_Processed__c, APTS_Asset_Line_Item__c, Error_in_Processing__c, APTS_Business_Transaction_Type__c
                                                                FROM RTR_LAE_Transaction_Data__c 
                                                                WHERE APTS_Asset_Line_Item__c IN: setAssetId AND 
                                                                     APTS_Business_Transaction_Type__c LIKE '%005' AND
                                                                     APTS_Asset_Line_Item__r.Apttus_Config2__ChargeType__c IN: setChargeType AND 
                                                                     APTS_Asset_Processed__c =: false]){
                    if(!mapTransData.containsKey(transDataExt.Id)){
                    finalsetadhocTransID.add(transDataExt.Id);
                        mapTransData.put(transDataExt.Id, transDataExt);
                    }

                }

                setAssetId.clear();
                List<RTR_LAE_Transaction_Data__c> lstTransDataadhoc = new List<RTR_LAE_Transaction_Data__c>();
                lstTransDataadhoc=[SELECT Id,APTS_Asset_Line_Item__r.APTS_Asset_Line_Item_Number__c,APTS_Asset_Line_Item__r.Apttus_Config2__AccountId__r.Mini_Company_Code__c,APTS_Asset_Line_Item__r.Apttus_Config2__ProductId__r.Name,APTS_Contract_Effective_Date__c,APTS_Contractual_Purchase__c,APTS_Asset_Line_Item__r.Apttus_Config2__EndDate__c,APTS_Asset_Line_Item__r.Apttus_CMConfig__AgreementId__r.Apttus__Agreement_Number__c,APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__r.APTS_Physical_Asset__r.InitialActivationDate__c,APTS_Asset_Line_Item__r.APTS_Physical_Asset__r.InitialActivationDate__c,APTS_Asset_Line_Item__r.APTS_MigrationDate__c,APTS_Asset_Line_Item__r.Apttus_Config2__BillingStartDate__c,APTS_Asset_Line_Item__r.Apttus_Config2__StartDate__c,APTS_Asset_Line_Item__r.Apttus_Config2__PriceListId__r.CurrencyIsoCode,APTS_Asset_Line_Item__r.Apttus_Config2__AccountId__r.SAP_Customer_ID__c,APTS_Asset_Line_Item__r.Apttus_Config2__AccountId__r.Distribution_Channel__c,APTS_Asset_Line_Item__r.Apttus_Config2__ProductId__r.ProductCode,APTS_Asset_Line_Item__r.Apttus_Config2__ChargeType__c,APTS_Asset_Line_Item__r.APTS_Type_Of_Contract__c,APTS_Asset_Line_Item__r.APTS_Installation_Sales_Order_Item__c,APTS_Asset_Line_Item__r.Apttus_Config2__AccountId__r.Sales_Organization__c,APTS_Asset_Line_Item__r.APTS_Physical_Asset__r.APTS_FinanceId__c,APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__r.APTS_Physical_Asset__r.APTS_FinanceId__c,APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__r.APTS_Physical_Asset__r.ActiveWarranty__c,APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__r.APTS_Physical_Asset__r.WarrantyStartDate__c,APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__r.APTS_Physical_Asset__r.Warranty__c,APTS_Asset_Line_Item__r.APTS_Physical_Asset__r.ActiveWarranty__c,APTS_Asset_Line_Item__r.APTS_Physical_Asset__r.WarrantyStartDate__c,APTS_Asset_Line_Item__r.APTS_Physical_Asset__r.Warranty__c,APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__c,APTS_Asset_Line_Item__r.APTS_Physical_Asset__c,APTS_Asset_Line_Item__r.Apttus_Config2__OriginalStartDate__c,Service_Installation_Override__c,Error_Description__c,APTS_Asset_Line_Item__r.APTS_Contract_Change__c,APTS_Asset_Line_Item__r.APTS_Terminated_PHA_serial_number__c,APTS_Asset_Line_Item__r.APTS_Terminated_Physical_Asset__c,APTS_Asset_Line_Item__r.APTS_Term_PHA_Initial_Activation_Date__c,APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__r.APTS_Terminated_PHA_serial_number__c,APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__r.APTS_Terminated_Physical_Asset__c,APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__r.APTS_Term_PHA_Initial_Activation_Date__c,APTS_Asset_Processed__c,APTS_Business_Transaction_Type__c,APTS_Asset_Line_Item__c, Error_in_Processing__c FROM RTR_LAE_Transaction_Data__c WHERE Id != null AND ID IN : finalsetadhocTransID];

                for(RTR_LAE_Transaction_Data__c transData : mapTransData.values()){                                  
                    transData.Error_in_Processing__c = false;
                    transData.Error_Description__c  = null;
                    setAssetId.add(transData.APTS_Asset_Line_Item__c);
                    setSchBusinesstype.add(transData.APTS_Business_Transaction_Type__c);
                    setTransDataIds.add(transData.Id);
                }    
                
                if(!setAssetId.isEmpty() && setAssetId.size() > batchSize){
                    schQuery.isBatchableRequest__c = true;
                }
                insert schQuery;*/ // DQ-2484 As per new requirement, This code is no longer used  -- END
                
               // v1.2 - START
                if(!mapTransData.isEmpty()){
                    schQuery.isBatchableRequest__c = true;

                    for(RTR_LAE_Transaction_Data__c transData : mapTransData.values()){                                  
                        transData.Error_in_Processing__c = false;
                        transData.Error_Description__c  = null;
                    }

                    update mapTransData.values();  
                }
                insert schQuery;
                // v1.2 - END

                if(!mapTransData.isEmpty()&&label.SwitchStagingJob=='TRUE'){

                   // v1.2 - START
                    if(!APTS_LAE_RAR_Reinterface.isJobRunning(classValidate) && !Test.isRunningTest()){
                        APTS_ValidateAssetsBfrProcessStagingJob validateJob = new APTS_ValidateAssetsBfrProcessStagingJob();
                        Database.executeBatch(validateJob);
                    }
                    // v1.2 - END
                    
                     // DQ-2484 As per new requirement, This code is no longer used  -- START
                  /*  // call the stagingDataJob executeExt method directly.
                    //List<Apttus_Config2__AssetLineItem__c> lstAssetLineItem = APTS_LAE_RAR_Reinterface.fetchAssetLineItem(setChargeType, lineType, setAssetId);

                    APTS_ProcessStaging stagingJob = new APTS_ProcessStaging();
                    //stagingJob.setTransDataIds = setTransDataIds;
                    //stagingJob.contInterFlag= contInterFlag;

                    if(mapTransData.values().size() <= batchSize){
                        System.debug(' Less then ' + batchSize);
                      stagingJob.executeExt(lstTransDataadhoc, True);
                    }else if(!APTS_LAE_RAR_Reinterface.isJobRunning(classNames) && !Test.isRunningTest()){
                        System.debug(' Greater then '+ batchSize);
                        APTS_ProcessStaging stagingJobExt = new APTS_ProcessStaging();
                        Database.executeBatch(stagingJobExt, batchSize);
                    }
                    // DQ-2484 As per new requirement, This code is no longer used  -- END
                    */

                }
                
                if(!mapTransData.isEmpty()&&label.SwitchStagingJob=='FALSE'){
                   
                   
                   /*  // DQ-2484 As per new requirement, This code is no longer used  -- START
                    update mapTransData.values();  
                  
                  // call the stagingDataJob executeExt method directly.
                    List<Apttus_Config2__AssetLineItem__c> lstAssetLineItem = APTS_LAE_RAR_Reinterface.fetchAssetLineItem(setChargeType, lineType, setAssetId);

                    APTS_StagingDataJob stagingJob = new APTS_StagingDataJob(false);
                    stagingJob.setTransDataIds = setTransDataIds;
                    //stagingJob.contInterFlag= contInterFlag;

                    if(setAssetId.size() <= batchSize){
                        System.debug(' Less then ' + batchSize);
                      stagingJob.executeExt(lstAssetLineItem, true,setSchBusinesstype);
                    }else 
                    */ // DQ-2484 As per new requirement, This code is no longer used  -- END

                        if(!APTS_LAE_RAR_Reinterface.isJobRunning(classNames) && !Test.isRunningTest()){
                            System.debug(' Greater then '+ batchSize);
                            APTS_StagingDataJob stagingJobExt = new APTS_StagingDataJob();
                            Database.executeBatch(stagingJobExt, batchSize);
                        }
                    }
                    
               return true;
            }            
        }catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString() , 'APTS_RtRSchedulerComponentController', null, 'CLM', false, false, null, true); }
           
        return false;
    }
    
    /****************************************************************** 
    @Description: This method is defined to split the user input string into Set collection.
    @Params : String
    @return : Set<String>
    ******************************************************************/
    public static Set<String> typeCastStringtoSet(String inputValue){

        Set<String> setSplitString = new Set<String>();

        IF(!string.isBlank(inputValue)){ setSplitString.addAll(inputValue.split(',')); } 

        return setSplitString;
    }

    /****************************************************************** 
    @Description: This method will return profile details of current user.
    @Params : 
    @return : profile
    ******************************************************************/
    //v1.1 - START
    @AuraEnabled
    public static Profile getProfileInfo(){   
        String profileId = UserInfo.getProfileId();
        Profile profile = [SELECT Id, Name FROM Profile WHERE Id =:profileId];
        return profile;   
    }
    //v1.1 - END

    /****************************************************************** 
    @Description: This method will return batch size from custom metadatatype.
    @Params : 
    @return : Integer
    ******************************************************************/
    //v1.1 - START    
    public static Integer getStagingBatchSize(){ 
       Integer batchSize = 25;  
       for(LAE_RAR_StagingStaticData__mdt stgBatch : [SELECT MasterLabel,qualifiedApiName,DeveloperName, BatchSize__c FROM LAE_RAR_StagingStaticData__mdt WHERE qualifiedApiName='StagingDataBatchSize']){
            batchSize = Integer.valueOf(stgBatch.BatchSize__c);
        }
        return batchSize;   
    }
    //v1.1 - END
}