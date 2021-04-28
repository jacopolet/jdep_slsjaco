/*************************************************************
@Name: APTS_StagingDataJob
@Author: Mahesh Chilaka
@CreateDate: 13-08-2019
@Description: Redesign of Staging Data creation from Transation Data. - DFT2C-856,857,858 .
@UsedBy: 
******************************************************************/
/*
@Version History : v1.0 - created
                   v1.1 - 14/11/2019 - DFT2C-1967 - Assign Service Transaction Start/End Date on Staging data creation.
                   v1.2 - 15/11/2019 - DFT2C-1962, DFT2C-1985 - The whole bundle should not be sent, When transaction has an error.
                   v1.3 - 21/11/2019 - DFT2C-2012, DFT2C-2018, DFT2C-2021 - Updated serial number validation and removed active assets query criteria.
                   v1.4 - 22/11/2019 - DFT2C-2034 - Added logic for warranty start date for sales machine and service option. 
                   v1.5 - 23/12/2019 - DFT2C-2011, DQ - 1397 - Scheduler interface based selection should ignore any other RtR Transaction records on same effective date.
                   v1.6 - 21/01/2020 - DQ - 368 - Exposed few avariables by changing access modifiers and methods to APTS_AssetMovementTxCEDUpdateQueueable.
                   v1.7 - 25/03/2020 - DQ-1829 - Added 0002 transaction type changes for Contract type change
                   v1.8 - 31/03/2020 - DQ-1385 - Added to default Selling term for sales Option
                   v1.9 - 09/04/2020 - DQ-513 - RTR Scheduler to process all the Records based on the business Transaction selection(Signature changed for execute method/getalltransactions methods
*/

global class APTS_StagingDataJob implements Database.Batchable<sObject> {
    
    String query;
   
    Date effectiveDate;
    Boolean adhocRequest = false;    
    Integer count = 0;    
    private Map<Id, List<Apttus_Billing__BillingSchedule__c>> mapAllPrimaryAssetBillingSch = new Map<Id, List<Apttus_Billing__BillingSchedule__c>>();
    private Map<Id, List<Apttus_Billing__BillingSchedule__c>> mapAllAssetAgreeBillingSch = new Map<Id, List<Apttus_Billing__BillingSchedule__c>>();
    private Map<Id, String> mapAccountSAPID = new Map<Id, String>();
    private Map<String, Id> mapAssetPL1Option = new Map<String, Id>();
    private Map<Id, Integer> mapRemainingUsefulLife = new Map<Id, Integer>();
    private Map<Id, Id> mapAssetPreviousAgreement = new Map<Id, Id>();
    private Map<Id, Id> mapAssetPreviousAccount = new Map<Id, Id>();
    private Map<Id, String> mapAssetPreviousAgreementNumber = new Map<Id, String>();
    private Map<Id, Set<Id>> mapPL1AssetWithOptions = new Map<Id, Set<Id>>();
    private Map<Id, Set<Id>> mapPL1AssetAgreeWithOptions = new Map<Id, Set<Id>>();
    private List<Apttus_Config2__AssetLineItem__c> lstAssetLineItemOptions = new List<Apttus_Config2__AssetLineItem__c>();
    private List<Apttus_Config2__AssetLineItem__c> lstAssetAgreeLineItemOptions = new List<Apttus_Config2__AssetLineItem__c>();
    private Map<String, Date> mapAssetPreviousAgreementStartDate = new Map<String, Date>();
    //v1.6 - START 
    public Map<String, Date> mapAssetPreviousAgreementEndDate = new Map<String, Date>();
    public Map<String, Date> mapAssetCurrentAgreementStartDate = new Map<String, Date>();
    public Map<String, Date> mapAssetCurrentAgreementEndDate = new Map<String, Date>();
    //v1.6 - END 
    private Map<String, Date> mapServiceAssetStartDate = new Map<String, Date>();
    private Map<String, Date> mapServiceAssetEndDate = new Map<String, Date>();
    public Map<Id, Boolean> mapServiceWarranty = new Map<Id, Boolean>();
    public Map<Id, Boolean> mapServiceActiveWarranty = new Map<Id, Boolean>();
    public Map<Id, Date> mapServiceActiveWarrantyDate = new Map<Id, Date>();
    private Map<Id, Date> mapServiceWarrantyDate = new Map<Id, Date>();
    private Map<Id, Decimal> mapPL1NetPrice = new Map<Id, Decimal>();
    private Map<Id, Decimal> mapPL1GrossPrice = new Map<Id, Decimal>();    

    private Map<Id, Decimal> mapPL1NetPriceService = new Map<Id, Decimal>();
    private Map<Id, Decimal> mapPL1GrossPriceService = new Map<Id, Decimal>();
    private Map<Id, Decimal> mapPL1NetPriceSales = new Map<Id, Decimal>();
    private Map<Id, Decimal> mapPL1GrossPriceSales = new Map<Id, Decimal>();
    private Map<Id, Decimal> mapPL1NetPriceRent = new Map<Id, Decimal>();
    private Map<Id, Decimal> mapPL1GrossPriceRent = new Map<Id, Decimal>();

    private Map<Id, Decimal> mapPL1AgreeNetPriceService = new Map<Id, Decimal>();
    private Map<Id, Decimal> mapPL1AgreeGrossPriceService = new Map<Id, Decimal>();
    private Map<Id, Decimal> mapPL1AgreeNetPriceSales = new Map<Id, Decimal>();
    private Map<Id, Decimal> mapPL1AgreeGrossPriceSales = new Map<Id, Decimal>();
    private Map<Id, Decimal> mapPL1AgreeNetPriceRent = new Map<Id, Decimal>();
    private Map<Id, Decimal> mapPL1AgreeGrossPriceRent = new Map<Id, Decimal>();


    private Map<Id, Decimal> mapOptGrossPriceService = new Map<Id, Decimal>();
    private Map<Id, Decimal> mapOptGrossPriceSales = new Map<Id, Decimal>();
    private Map<Id, Decimal> mapOptGrossPriceRent = new Map<Id, Decimal>();
    private Map<Id, Decimal> mapOptNetPriceService = new Map<Id, Decimal>();
    private Map<Id, Decimal> mapOptNetPriceSales = new Map<Id, Decimal>();
    private Map<Id, Decimal> mapOptNetPriceRent = new Map<Id, Decimal>();

    private Map<Id, Decimal> mapAgreeOptGrossPriceService = new Map<Id, Decimal>();
    private Map<Id, Decimal> mapAgreeOptGrossPriceSales = new Map<Id, Decimal>();
    private Map<Id, Decimal> mapAgreeOptGrossPriceRent = new Map<Id, Decimal>();
    private Map<Id, Decimal> mapAgreeOptNetPriceService = new Map<Id, Decimal>();
    private Map<Id, Decimal> mapAgreeOptNetPriceSales = new Map<Id, Decimal>();
    private Map<Id, Decimal> mapAgreeOptNetPriceRent = new Map<Id, Decimal>();
   
    private Set<Id> setAssetsProcessedWithoutBillSch = new Set<Id>();
    private Set<Id> setAssetsProcessed = new Set<Id>();
    private Set<Id> setErrorTransData = new Set<Id>();
    private static final String TRANS_0001 = '0001';
    private static final String TRANS_0002 = '0002';
    private static final String TRANS_0003 = '0003';
    private static final String TRANS_0004 = '0004';
    private static final String TRANS_0005 = '0005';
    private static final String TRANS_A005 = 'A005';
    private static final String TRANS_B005 = 'B005';
    private static final String CONSUMPTION = 'Consumption Model';
    private static final String ACTIVATED = 'Activated';
    public String strInvoiced = 'Invoiced';
    public String lineType = 'Product/Service';
    public Boolean isNewAgreementGrossPriceCal = false;
    public Set<Id> setTransDataIds = new Set<Id>();
    public Set<Id> setSchAssetId = new Set<Id>();
    public Set<String> setSchBusinesstype = new Set<String>();
    Set<String> setBillingStatus = new Set<String>{'Invoiced', 'Pending Invoiced', 'Pending Billing'};
    Set<String> setBillingStatusNetPrice = new Set<String>{'Pending Invoiced', 'Pending Billing'};
    Set<String> setBillingStatusGrossPrice = new Set<String>{'Invoiced', 'Pending Invoiced', 'Pending Billing', 'Invoiced Cancelled'};
    Set<String> setExcludeOptions = new Set<String>{'0107','0108'};
    Set<String> setChargeType = new Set<String>{'Service Fee', 'Rental Fee', 'Sales Price'};
    //v1.6 - START    
    public Set<String> setALIAgreeNumber = new Set<String>();
    public Set<String> setPrevAgreeNumber= new Set<String>();
    //v1.6 - END 
    

    global APTS_StagingDataJob(Date effectiveDate) {
        if(effectiveDate != null ){
            this.effectiveDate = effectiveDate;
        }
    }

    global APTS_StagingDataJob(){

        Set<String> setAgreementNumber = New Set<String>();
        Set<String> setFinanceId = New Set<String>();
        Set<String> setALINumber = New Set<String>();
        Set<String> setCompanyCode = New Set<String>();
        Set<String> setBusinessType = New Set<String>();
        Set<String> setTypeofContract = New Set<String>();
        Set<String> setTransID = New Set<String>();
        Date contEffStartDate, contEffEndDate;
        Boolean contInterFlag;
        String queryString = ' SELECT Id, APTS_Asset_Processed__c,APTS_Business_Transaction_Type__c,APTS_Asset_Line_Item__c, Error_in_Processing__c FROM RTR_LAE_Transaction_Data__c WHERE Id != null ';
        String whereClause = '';
        List<APTS_RTR_Scheduler_Query__c> lstSchQuery = new List<APTS_RTR_Scheduler_Query__c>();

        for(APTS_RTR_Scheduler_Query__c schQuery : [SELECT APTS_Agreement_Number__c, Asset_Line_Item_Number__c, APTS_Business_Transaction_Type__c, APTS_Company_Code__c,
                                                            APTS_Contract_Effective_End_Date__c, APTS_Contract_Effective_Start_Date__c, APTS_Controlled_Interface_Flag__c, APTS_Finance_ID__c, APTS_LAE_RAR_Transaction_ID__c, APTS_Type_of_Contract__c, isProcessed__c
                                                    FROM APTS_RTR_Scheduler_Query__c 
                                                    WHERE isBatchableRequest__c = true AND isProcessed__c = false ORDER BY Createddate desc LIMIT 1]){

                                                    
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
        schQuery.isProcessed__c = true;
        lstSchQuery.add(schQuery);
        }

        if(!lstSchQuery.isEmpty()){ update lstSchQuery; }

        if(contEffStartDate != null && contEffEndDate != null){   
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

        if(!String.isBlank(whereClause) ){
            whereClause += ' AND APTS_Controlled_Interface_Flag__c =: contInterFlag ';
            whereClause += ' AND APTS_Asset_Line_Item__r.Apttus_Config2__ChargeType__c IN: setChargeType AND APTS_Asset_Processed__c = false ';
            whereClause += ' ORDER BY  APTS_Contract_Effective_Date__c ASC LIMIT 5000';
            
            for(RTR_LAE_Transaction_Data__c transData :  Database.Query(queryString+whereClause)){ 
                setSchAssetId.add(transData.APTS_Asset_Line_Item__c);
                setSchBusinesstype.add(transData.APTS_Business_Transaction_Type__c);                
            }
        }
    }

    global APTS_StagingDataJob(Boolean adhocRequest) {
        if(adhocRequest){
            this.adhocRequest = true;
            for(RTR_LAE_Transaction_Data__c transData : [SELECT Id, APTS_Contract_Effective_Date__c 
                                                     FROM RTR_LAE_Transaction_Data__c 
                                                     WHERE APTS_Asset_Processed__c = false AND 
                                                            isDeleted = false AND 
                                                            Error_in_Processing__c = false AND
                                                            APTS_Asset_Line_Item__c != null AND 
                                                            APTS_Contract_Effective_Date__c != null AND
                                                            APTS_Asset_Line_Item__r.Apttus_Config2__ChargeType__c IN : setChargeType AND 
                                                            APTS_Asset_Line_Item__r.Apttus_Config2__LineType__c =: lineType
                                                    ORDER BY APTS_Contract_Effective_Date__c ASC LIMIT 1]){
                this.effectiveDate = transData.APTS_Contract_Effective_Date__c;
            }
            if(this.effectiveDate == null) { adhocRequest = false; }
        }
    }
    
     global Database.QueryLocator start(Database.BatchableContext BC) {          
       
        String queryString = '';
        //Set<Id> setAssetId = new Set<Id>();

        if(setSchAssetId.isEmpty()){
            //v1.3 - START
            for(RTR_LAE_Transaction_Data__c transData : [SELECT Id, APTS_Asset_Line_Item__c,APTS_Business_Transaction_Type__c 
                                                        FROM RTR_LAE_Transaction_Data__c 
                                                        WHERE APTS_Asset_Processed__c = false AND 
                                                                isDeleted = false AND 
                                                                Error_in_Processing__c = false AND
                                                                APTS_Asset_Line_Item__c != null AND
                                                                APTS_Asset_Line_Item__r.Apttus_Config2__ChargeType__c IN : setChargeType AND 
                                                                APTS_Asset_Line_Item__r.Apttus_Config2__LineType__c =: lineType AND
                                                                APTS_Contract_Effective_Date__c =: effectiveDate LIMIT 40000]){
                setSchAssetId.add(transData.APTS_Asset_Line_Item__c);
                setSchBusinesstype.add(transData.APTS_Business_Transaction_Type__c);
            }
            //v1.3 - END
        }
       // system.debug(' Query setAssetId :'+setAssetId);
        
        

             queryString = ' SELECT Id, APTS_Is_Primary_L1_Asset__c,'
                                    + ' Apttus_Config2__ChargeType__c,'
                                    + ' APTS_Contract_Type__c,'
                                    + ' APTS_Type_Of_Contract__c,'                                    
                                    + ' APTS_Asset_Validaton_Error__c,'
                                    + ' APTS_Calculated_Base_Extended_Price__c,'
                                    + ' APTS_MigrationDate__c,'
                                    + ' Apttus_Config2__OriginalStartDate__c,'
                                    + ' Apttus_Config2__Quantity__c,'
                                    + ' Apttus_Config2__BasePrice__c,'
                                    + ' Apttus_Config2__EndDate__c,'
                                    + ' Apttus_Config2__BillingStartDate__c,'
                                    + ' Apttus_Config2__StartDate__c,'
                                    + ' Apttus_CMConfig__AgreementId__r.Apttus__Agreement_Number__c, ' 
                                    + ' Apttus_Config2__AccountId__r.SAP_Customer_ID__c,'
                                    + ' Apttus_Config2__AccountId__r.Mini_Company_Code__c,'
                                    + ' APTS_Physical_Asset__r.InitialActivationDate__c,'
                                    + ' APTS_Physical_Asset__c,'
                                    + ' APTS_Is_Primary_L1_Line__c,'
                                    + ' APTS_Is_Primary_L1_Asset__r.APTS_Physical_Asset__r.InitialActivationDate__c,'
                                    + ' APTS_Contract_Change__c,'
                                    + ' APTS_Terminated_Physical_Asset__c,'
                                    + ' APTS_Terminated_PHA_serial_number__c'       
                             + ' FROM Apttus_Config2__AssetLineItem__c'
                             + ' WHERE Apttus_Config2__ChargeType__c IN : setChargeType AND '
                                    + ' Apttus_Config2__LineType__c =: lineType AND '
                                    + ' Id IN: setSchAssetId ';

       if(setSchAssetId.isEmpty()) { queryString = 'SELECT Id FROM Apttus_Config2__AssetLineItem__c LIMIT 0'; }

        return Database.getQueryLocator(queryString);
   }
   
   global void execute(Database.BatchableContext BC, List<sObject> scope) { 
       executeExt((List<Apttus_Config2__AssetLineItem__c>) scope, false,setSchBusinesstype);  
   }
   
   
   global void finish(Database.BatchableContext BC) {

       // Check if we have any ad-hoc or recent data request pending.
       // if exist then reinvoke the batch once again.
        Set<String> classNames = new Set<String>{'APTS_StagingDataJob'};
        Date pickEffectiveDate;
        Integer batchSize = APTS_RtRSchedulerComponentController.getStagingBatchSize();

        Id profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].ID;

        List<APTS_RTR_Scheduler_Query__c> lstSchQuery = [SELECT Id FROM APTS_RTR_Scheduler_Query__c WHERE isBatchableRequest__c =: true AND isProcessed__c =: false ORDER BY Createddate desc LIMIT 1];
         
        //v1.3 - START
        

        for(RTR_LAE_Transaction_Data__c transData : [SELECT Id, APTS_Contract_Effective_Date__c 
                                                     FROM RTR_LAE_Transaction_Data__c 
                                                     WHERE APTS_Asset_Processed__c = false AND 
                                                            isDeleted = false AND 
                                                            Error_in_Processing__c = false AND
                                                            APTS_Asset_Line_Item__c != null AND 
                                                            APTS_Contract_Effective_Date__c != null AND
                                                            APTS_Asset_Line_Item__r.Apttus_Config2__ChargeType__c IN : setChargeType AND 
                                                            APTS_Asset_Line_Item__r.Apttus_Config2__LineType__c =: lineType                                                  
                                                    ORDER BY APTS_Contract_Effective_Date__c ASC LIMIT 1]){
                pickEffectiveDate = transData.APTS_Contract_Effective_Date__c;
        }
        //v1.3 - END
        
        if(!APTS_LAE_RAR_Reinterface.isJobRunning(classNames) && !lstSchQuery.isEmpty() && !Test.isRunningTest() && userInfo.getProfileId() != profileId ){
            System.debug(' Batch loop 1');
            APTS_StagingDataJob stagingjob = new APTS_StagingDataJob();
            Database.executeBatch(stagingjob, batchSize);

        }else if(!APTS_LAE_RAR_Reinterface.isJobRunning(classNames) && pickEffectiveDate != null && !Test.isRunningTest() && userInfo.getProfileId() == profileId){ 
             System.debug(' Batch loop 2');
             APTS_StagingDataJob stagingjob = new APTS_StagingDataJob(pickEffectiveDate);
             Database.executeBatch(stagingjob, batchSize);
        } 
        
   }


 /****************************************************************** 
  @Description: This method is defined the extension of Execute method and also used for Ad-hoc request.
  @Params : List<Apttus_Config2__AssetLineItem__c>
  @return : List<RTR_LAE_Staging_Data__c>
  ******************************************************************/
  public void executeExt(List<Apttus_Config2__AssetLineItem__c> lstAssetLineItem, Boolean isExecuteIntegrationLog,Set<String> setBusinessTransactiontype){
      try{            
       
       Set<Id> setUniqueAsset = new Set<Id>();  
       Set<Id> setPrimaryL1Asset = new Set<Id>();     
       Map<String, String> mapAssetWithBusinessTypeFinal = new Map<String, String>();
       Map<String, String> mapAssetWithBusinessType = new Map<String, String>();
       Map<Id, Decimal> mapFinalAssetGrossPrice = new Map<Id, Decimal>();
       Map<Id, Decimal> mapFinalAssetNetPrice = new Map<Id, Decimal>();
       Set<String> set005 = new Set<String>{'A005', 'B005'};
       Set<Id> set005AssetId = new Set<Id>();
       Id parentId;

      
       Map<Id, Apttus_Config2__AssetLineItem__c> mapAssetLineItem = new Map<Id, Apttus_Config2__AssetLineItem__c>();
       List<RTR_LAE_Staging_Data__c> lstStagingData = new List<RTR_LAE_Staging_Data__c>();


        for(Apttus_Config2__AssetLineItem__c ali : lstAssetLineItem) {
            mapAssetLineItem.put(ali.Id, ali);
            //System.debug('AssetId :'+ali.Id);

        }

        List<RTR_LAE_Transaction_Data__c> lstProcessedTransData = getAllTransactionData(mapAssetLineItem.keySet(),setBusinessTransactiontype);
        System.debug('lstProcessedTransData :'+lstProcessedTransData);

        for(RTR_LAE_Transaction_Data__c transData : lstProcessedTransData){
            if(set005.contains(transData.APTS_Business_Transaction_Type__c)){
                if(transData.APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__c != null) {                     
                        set005AssetId.add(transData.APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__c);
                        set005AssetId.add(transData.APTS_Asset_Line_Item__c);
                    }else if(transData.APTS_Asset_Line_Item__c != null){
                        set005AssetId.add(transData.APTS_Asset_Line_Item__c);
                    }                 
            }            
            setALIAgreeNumber.add(transData.APTS_Asset_Line_Item__r.Apttus_CMConfig__AgreementId__r.Apttus__Agreement_Number__c);
        }
        
        //v1.5 - START
        if(setTransDataIds.isEmpty()){
            for(RTR_LAE_Transaction_Data__c transData : lstProcessedTransData){            
               
                setTransDataIds.add(transData.Id);
                
            }
        }
        //v1.5 - END
        
       System.debug('Flow set005AssetId :'+set005AssetId);

        for(Apttus_Config2__AssetLineItem__c ali : lstAssetLineItem) {

            if(!setUniqueAsset.contains(ali.Id) && !setUniqueAsset.contains(ali.APTS_Is_Primary_L1_Asset__c)){
                
                    if(ali.APTS_Is_Primary_L1_Asset__c != null) {                     
                        setUniqueAsset.add(ali.APTS_Is_Primary_L1_Asset__c);
                        setPrimaryL1Asset.add(ali.APTS_Is_Primary_L1_Asset__c);
                       // System.debug(' Service AssetId :'+ali.APTS_Is_Primary_L1_Asset__c);
                        setUniqueAsset.add(ali.Id);
                    }else if(ali.APTS_Is_Primary_L1_Line__c){
                        setUniqueAsset.add(ali.Id);
                        setPrimaryL1Asset.add(ali.Id);
                    }                
            }
            System.debug('FLow setUniqueAsset :'+setUniqueAsset);        
        }

        remainingUsefulLife(lstProcessedTransData);
       System.debug('Flow mapRemainingUsefulLife :'+mapRemainingUsefulLife.size());
        
        if(!set005AssetId.isEmpty()){
    //v1.6 - START
            fetchAssetPreviousAgreement(set005AssetId, true);
    //v1.6 - END
           // System.debug('mapAssetPreviousAgreement :'+mapAssetPreviousAgreement.size());
            fetchAssetPreviousSoldTo(set005AssetId);
        }

         System.debug('Lavanya'+setUniqueAsset);
        if(!setUniqueAsset.isEmpty()){
       System.debug('Lavanya'+mapAllPrimaryAssetBillingSch);
            mapAllPrimaryAssetBillingSch = getBillingSchRelatedtoAsset(setUniqueAsset, mapAllPrimaryAssetBillingSch, false);
             System.debug('Lavanya'+mapAllPrimaryAssetBillingSch);
        }

     //  System.debug('ALL mapAllPrimaryAssetBillingSch :'+mapAllPrimaryAssetBillingSch);
     //  System.debug('lstAssetLineItemOptions :'+lstAssetLineItemOptions);

              
        if(!mapAllPrimaryAssetBillingSch.isEmpty()){

            mapAssetWithBusinessType = getFinalAssetWithBusinessType(mapAssetLineItem.keySet());
           
           
            if(!mapAssetWithBusinessType.isEmpty()){
              mapAssetWithBusinessTypeFinal.putAll(mapAssetWithBusinessType);
            }
                
            
            mapFinalAssetNetPrice = calculateNetPrice(mapAllPrimaryAssetBillingSch, false); 
            mapAllPrimaryAssetBillingSch.clear(); 
            isNewAgreementGrossPriceCal = true;        
            mapAllPrimaryAssetBillingSch = getBillingSchRelatedtoAsset(setUniqueAsset, mapAllPrimaryAssetBillingSch, false);

           // System.debug('ALL mapAllPrimaryAssetBillingSch :'+mapAllPrimaryAssetBillingSch);
           // System.debug('lstAssetLineItemOptions :'+lstAssetLineItemOptions);

            mapFinalAssetGrossPrice = calculateGrossPrice(mapAllPrimaryAssetBillingSch, false);
            

            calculateNetGrossPriceFinal(mapFinalAssetNetPrice, mapFinalAssetGrossPrice, false);
            
            fetchAssetPreviousContractStartEndDates(set005AssetId);
            //v1.1 START
            fetchServiceFeeAssetContractStartEndDates(setPrimaryL1Asset);
            //v1.1 END

            //v1.4 START
            fetchServiceHeaderWarranty(setPrimaryL1Asset);
            //v1.4 END

          lstStagingData = createStagingData(mapAssetLineItem, mapFinalAssetNetPrice, mapFinalAssetGrossPrice, mapAssetWithBusinessTypeFinal);

        }

        lstProcessedTransData = getAllTransactionData(mapAssetLineItem.keySet(),setSchBusinesstype);
        for(RTR_LAE_Transaction_Data__c transData : lstProcessedTransData){
            
            if(transData.APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__c != null)  {
                parentId = transData.APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__c;
            }else {
                parentId = transData.APTS_Asset_Line_Item__c;
            }

            if(!setErrorTransData.contains(transData.Id)){
                transData.Error_Description__c  = null;    
                transData.Error_in_Processing__c = false;
            }
            //v1.2 - START
            System.debug('Lavanya'+setAssetsProcessedWithoutBillSch);System.debug('Lavanya mapAllPrimaryAssetBillingSch'+mapAllPrimaryAssetBillingSch);
            if(setAssetsProcessedWithoutBillSch.contains(parentId) || mapAllPrimaryAssetBillingSch.isEmpty()){
                transData.Error_Description__c  = 'No Valid Billing Schedules found;';    
                transData.Error_in_Processing__c = true;
            } 
            //v1.2 - END                  
            transData.APTS_Asset_Processed__c = true;            
        }
      
      if(!lstProcessedTransData.isEmpty()){   update lstProcessedTransData; }

       

        if(lstStagingData != null ){
            APTS_IntegationLogJob integrJob = new APTS_IntegationLogJob();                
           // system.debug('integrJob.mapStageData '+integrJob.mapStageData);
            List<Apttus_Config2__AssetLineItem__c> assetLineItemWithStaging = [SELECT ID, (SELECT Id, APTS_AssetProcessed__c, APTS_Asset_Line_Item__c,  APTS_Serial_Number__c, APTS_Contract_Number__c, APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__c, 
                                                                                    APTS_Business_Transaction_Type__c FROM Apttus_Integration_Logs__r 
                                                                                    WHERE Id IN: lstStagingData 
                                                                                        ORDER BY CreatedDate DESC) 
                                                                                FROM Apttus_Config2__AssetLineItem__c 
                                                                                WHERE (ID IN :mapAssetLineItem.keySet())];
          //  system.debug('assetLineItemWithStaging '+assetLineItemWithStaging);
            integrJob.executeExt(assetLineItemWithStaging, true);

        }

        

    }catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString()+'/n/n'+ex.getMessage() , 'Staging Data Job', null, 'CLM', false, false, null, true); }
    
  }





  /****************************************************************** 
  @Description: This method is used to calculate the Gross Price of asset related billingschedule.
  @Params : Map<Id, List<Apttus_Billing__BillingSchedule__c>, List<Apttus_Config2__AssetLineItem__c>
  @return : Map<Id, Decimal>
  ******************************************************************/
   public Map<Id, Decimal> calculateGrossPrice(Map<Id, List<Apttus_Billing__BillingSchedule__c>> mapAllPrimaryAssetBillingSchGen, Boolean isPreviousAgreement){
       Map<Id, Date> mapAssetBillSchEarliestDate = new Map<Id, Date>();
       Map<Id, Date> mapAssetBillSchLatestDate = new Map<Id, Date>();
       Set<Id> setUnique = new Set<Id>();
       

        Map<Id, Decimal> mapFinalAssetGrossPrice = new Map<Id, Decimal>();
        Decimal grossPrice = 0.0, grossPriceSales, grossPriceService, grossPriceRent,  daysBetween = 0.0, monthsBetween = 0.0;
        Decimal totGrossPrice = 0.0;
        Date bilSchEarliestDate , bilSchLatestDate, bilSchInvoicedCancelledDate ;
        Date startDate, endDate, extDate;
        Integer numberDays, startDateNumberDays, endDateNumberDays, startDateDaysBetween = 0;
        System.debug('flow mapAllPrimaryAssetBillingSchGen'+mapAllPrimaryAssetBillingSchGen.size());    
        for(Id assetId : mapAllPrimaryAssetBillingSchGen.keySet()){        
            bilSchEarliestDate = null;
            bilSchLatestDate = null;
            bilSchInvoicedCancelledDate = null;
             if(mapAllPrimaryAssetBillingSchGen.containsKey(assetId) && mapAllPrimaryAssetBillingSchGen.get(assetId) != null){
            
                for(Apttus_Billing__BillingSchedule__c billSch : mapAllPrimaryAssetBillingSchGen.get(assetId)) {
                                
                    //Earliest Logic Pick the Oldest Start Date
                    if(bilSchEarliestDate == null || billSch.Apttus_Billing__PeriodStartDate__c <= bilSchEarliestDate){
                        bilSchEarliestDate = billSch.Apttus_Billing__PeriodStartDate__c;
                    }
                    //Latest Logic Pick the Later End Date
                    if(bilSchLatestDate == bilSchLatestDate || billSch.Apttus_Billing__PeriodEndDate__c >= bilSchLatestDate){
                        bilSchLatestDate = billSch.Apttus_Billing__PeriodEndDate__c;
                    }
                    if(billSch.Apttus_Billing__Status__c == 'Invoiced Cancelled'){
                        bilSchInvoicedCancelledDate = billSch.Apttus_Billing__PeriodStartDate__c;
                    }
                }
                mapAssetBillSchEarliestDate.put(assetId, bilSchEarliestDate);

                if(bilSchInvoicedCancelledDate != null){
                   mapAssetBillSchLatestDate.put(assetId, bilSchInvoicedCancelledDate);
                }else {
                   mapAssetBillSchLatestDate.put(assetId, bilSchLatestDate);
                }

             }
        }
          System.debug('flow mapAssetBillSchEarliestDate :'+mapAssetBillSchEarliestDate);
         System.debug('flow mapFinalAssetGrossPrice :'+mapAssetBillSchLatestDate); 
          System.debug('flow isPreviousAgreement :'+isPreviousAgreement); 
          
        for(Apttus_Config2__AssetLineItem__c asset : isPreviousAgreement ? lstAssetAgreeLineItemOptions : lstAssetLineItemOptions){
        
                totGrossPrice = 0.0;
                grossPriceSales = 0.0; 
                grossPriceService = 0.0;
                grossPriceRent = 0.0;
                  System.debug('flow asset.id OUT:'+asset.id); 
                 if(mapAllPrimaryAssetBillingSchGen.containsKey(asset.id) && mapAllPrimaryAssetBillingSchGen.get(asset.id) != null){
                          System.debug('flow asset.id IN:'+asset.id); 
                    for(Apttus_Billing__BillingSchedule__c billSch : mapAllPrimaryAssetBillingSchGen.get(asset.Id)) {
                        grossPrice = 0.0;
                        if(mapAssetBillSchEarliestDate.containsKey(asset.id) && mapAssetBillSchLatestDate.containsKey(asset.id) ){
                            startDate = mapAssetBillSchEarliestDate.get(asset.id);
                            endDate = mapAssetBillSchLatestDate.get(asset.id);
                            
                            extDate = Date.newInstance(endDate.Year(),endDate.Month(),startDate.Day()); 
                            

                            numberDays = date.daysInMonth(startDate.year(), startDate.month());
                            startDateNumberDays = date.daysInMonth(startDate.year(), startDate.month());
                            endDateNumberDays = date.daysInMonth(endDate.year(), endDate.month());
                           
                           if(!startDate.isSameDay(endDate) && startDate.monthsBetween(endDate) > 0){       
                                startDateDaysBetween = (numberDays - startDate.day());
                            } else {
                                startDateDaysBetween = (endDate.day() - startDate.day());
                            }
                        
                            if(startDate.monthsBetween(endDate) > 0){
                                daysBetween = (startDateDaysBetween + endDate.day());
                            }else {
                                daysBetween = startDateDaysBetween;
                            }
                           
                            if(startDate.monthsBetween(endDate) > 0){
                                monthsBetween = (startDate.monthsBetween(endDate) - 1)+ (daysBetween.divide(30,5));
                            }else if(daysBetween > 0) {
                                monthsBetween = (daysBetween.divide(30,5));
                            }
                            
                             //v1.8--Start
                        if(!setUnique.contains(asset.id)){
                            System.debug('MASTER FLOW DEBUG Apttus_Config2__Quantity__c :'+ daysBetween+ ' '+monthsBetween+' '+asset.Apttus_Config2__BasePrice__c+' '+asset.Apttus_Config2__Quantity__c);
                            if(asset.Apttus_Config2__BasePrice__c > 0 && asset.Apttus_Config2__Quantity__c > 0&& asset.Apttus_Config2__ChargeType__c=='Sales Price'){
                                grossPrice = (1* asset.Apttus_Config2__BasePrice__c * asset.Apttus_Config2__Quantity__c).setScale(2);
                                if(grossPrice > 0){
                                
                                    totGrossPrice += grossPrice;
                                    System.debug('FLow grossPrice :'+ totGrossPrice+ '   '+grossPrice);
                                    
                                    if(billSch.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ChargeType__c.Contains('Sales')){
                                        grossPriceSales += grossPrice; System.debug('flow grossPriceSales->'+grossPriceSales)   ;
                                    }
                                
                                }
                            } else if(asset.Apttus_Config2__BasePrice__c > 0 && asset.Apttus_Config2__Quantity__c > 0&& asset.Apttus_Config2__ChargeType__c!='Sales Price'){
                                grossPrice = (monthsBetween* asset.Apttus_Config2__BasePrice__c * asset.Apttus_Config2__Quantity__c).setScale(2);
                                if(grossPrice > 0){
                                
                                    totGrossPrice += grossPrice;
                                    System.debug('FLow grossPrice :'+ totGrossPrice+ '   '+grossPrice);
                                    
                                    if(billSch.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ChargeType__c.Contains('Service')) {
                                        grossPriceService += grossPrice;System.debug('flow grossPriceService->'+grossPriceService)  ;
                                    }else if(billSch.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ChargeType__c.Contains('Rental')){
                                        grossPriceRent += grossPrice;System.debug('flow grossPriceRent->'+grossPriceRent)   ;   
                                    }
                                
                                }
                            }//v1.8 End
                            setUnique.add(asset.Id);

                            mapFinalAssetGrossPrice.put(asset.id, grossPrice);
                            System.debug('flow mapFinalAssetGrossPrice->'+mapFinalAssetGrossPrice)  ;   

                            if(isPreviousAgreement){
                                mapAgreeOptGrossPriceService.put(asset.id, grossPriceService);
                                mapAgreeOptGrossPriceSales.put(asset.id, grossPriceSales);
                                mapAgreeOptGrossPriceRent.put(asset.id, grossPriceRent);  
                        System.debug('flow mapFinalAssetGrossPrice->'+mapAgreeOptGrossPriceRent)    ;   
                            } else {
                                mapOptGrossPriceService.put(asset.id, grossPriceService);
                                mapOptGrossPriceSales.put(asset.id, grossPriceSales);
                                mapOptGrossPriceRent.put(asset.id, grossPriceRent);
                            }
                          }
                        }
                    }
                 }
                  
        }
            

        return mapFinalAssetGrossPrice;
   }

   /****************************************************************** 
   @Description: This method is used to calculate the Net Price of asset related billingschedule.
   @Params : Map<Id, List<Apttus_Billing__BillingSchedule__c>
   @return : Map<Id, Decimal>
   ******************************************************************/
   public Map<Id, Decimal> calculateNetPrice(Map<Id, List<Apttus_Billing__BillingSchedule__c>> mapAllPriryAssetBillingSchGen, Boolean isPreviousAgreement){

        Map<Id, Decimal> mapFinalAssetNetPrice = new Map<Id, Decimal>();
        Map<String, Map<Id, Decimal>> mapFinalOnContractType = new Map<String, Map<Id, Decimal>>();
        //Set<String> setExcludeOptions = new Set<String>{'0107','0108'};
        Decimal netPrice = 0.0, netPriceSales, netPriceService, netPriceRent;

       // system.debug('CalculateNetPrice :'+ mapAllPriryAssetBillingSchGen.size());

      for(Apttus_Config2__AssetLineItem__c asset : isPreviousAgreement ? lstAssetAgreeLineItemOptions : lstAssetLineItemOptions){
         
                netPrice = 0.0;
                netPriceSales = 0.0;
                netPriceService = 0.0;
                netPriceRent = 0.0;

                if(mapAllPriryAssetBillingSchGen.containsKey(asset.id) && mapAllPriryAssetBillingSchGen.get(asset.id) != null){

                   //  system.debug(' mapAllPriryAssetBillingSchGen.get(asset.id) :'+mapAllPriryAssetBillingSchGen.get(asset.id).size());

                    for(Apttus_Billing__BillingSchedule__c billSch : mapAllPriryAssetBillingSchGen.get(asset.id)) {

                           // system.debug(' netPrice :'+netPrice+' + '+billSch.Apttus_Billing__FeeAmount__c);
                            netPrice += (billSch.Apttus_Billing__FeeAmount__c).setScale(2);
                            if(billSch.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ChargeType__c.Contains('Service')) {
                                netPriceService += (billSch.Apttus_Billing__FeeAmount__c).setScale(2);
                            }else if(billSch.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ChargeType__c.Contains('Rental')){
                                netPriceRent += (billSch.Apttus_Billing__FeeAmount__c).setScale(2);
                            }else if(billSch.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ChargeType__c.Contains('Sales')){
                                netPriceSales += (billSch.Apttus_Billing__FeeAmount__c).setScale(2);
                            }
                       
                    }

                    mapFinalAssetNetPrice.put(asset.id, netPrice);
                    if(isPreviousAgreement){
                        mapAgreeOptNetPriceService.put(asset.id, netPriceService);
                        mapAgreeOptNetPriceSales.put(asset.id, netPriceSales);
                        mapAgreeOptNetPriceRent.put(asset.id, netPriceRent);
                    } else {
                        mapOptNetPriceService.put(asset.id, netPriceService);
                        mapOptNetPriceSales.put(asset.id, netPriceSales);
                        mapOptNetPriceRent.put(asset.id, netPriceRent);
                    }

                    
                }
          
       }
        
        return mapFinalAssetNetPrice;
   }

   /****************************************************************** 
   @Description: This method is used to calculate the Net Price of asset related billingschedule.
   @Params : Map<Id, List<Apttus_Billing__BillingSchedule__c>
   @return : Map<Id, Decimal>
   ******************************************************************/
   public void calculateNetGrossPriceFinal(Map<Id, Decimal> mapFinalAssetNetPrice, Map<Id, Decimal> mapFinalAssetGrossPrice, Boolean isPreviousAgreement){        
        Decimal finalNetPrice = 0.0;
        Decimal finalGrossPrice = 0.0;
        Decimal finalNetPriceSales, finalNetPriceService, finalNetPriceRent;
        Decimal finalGrossPriceSales, finalGrossPriceService, finalGrossPriceRent;


      for(Id assetPLI : isPreviousAgreement ? mapPL1AssetAgreeWithOptions.keyset() : mapPL1AssetWithOptions.keyset()){
           finalNetPrice = 0.0;
           finalGrossPrice = 0.0;

           finalNetPriceSales = 0.0;
           finalNetPriceService = 0.0; 
           finalNetPriceRent= 0.0;
           finalGrossPriceSales = 0.0;
           finalGrossPriceService = 0.0;
           finalGrossPriceRent = 0.0;

         for(Id aliId : isPreviousAgreement ? mapPL1AssetAgreeWithOptions.get(assetPLI) : mapPL1AssetWithOptions.get(assetPLI)){
             if(mapFinalAssetNetPrice.containsKey(aliId) && mapFinalAssetNetPrice.get(aliId) != null){
                finalNetPrice += mapFinalAssetNetPrice.get(aliId);
             }
             if(mapFinalAssetGrossPrice.containsKey(aliId) && mapFinalAssetGrossPrice.get(aliId) != null){
                finalGrossPrice += mapFinalAssetGrossPrice.get(aliId);
                System.debug('finalGrossPrice flow '+ finalGrossPrice);
             }

             if(isPreviousAgreement){

                if(mapAgreeOptNetPriceService.containsKey(aliId) && mapAgreeOptNetPriceService.get(aliId) != null){
                    finalNetPriceService += mapAgreeOptNetPriceService.get(aliId);
                }
                if(mapAgreeOptNetPriceSales.containsKey(aliId) && mapAgreeOptNetPriceSales.get(aliId) != null){
                    finalNetPriceSales += mapAgreeOptNetPriceSales.get(aliId);
                }
                if(mapAgreeOptNetPriceRent.containsKey(aliId) &&  mapAgreeOptNetPriceRent.get(aliId) != null){
                    finalNetPriceRent += mapAgreeOptNetPriceRent.get(aliId);
                    System.debug('finalNetPriceRent flow '+ finalNetPriceRent);
                }
                
                if(mapAgreeOptGrossPriceService.containsKey(aliId) && mapAgreeOptGrossPriceService.get(aliId) != null){
                    finalGrossPriceService += mapAgreeOptGrossPriceService.get(aliId);System.debug('mapAgreeOptGrossPriceService flow '+ mapAgreeOptGrossPriceService);
                }
                if(mapAgreeOptGrossPriceSales.containsKey(aliId) && mapAgreeOptGrossPriceSales.get(aliId) != null){
                    finalGrossPriceSales += mapAgreeOptGrossPriceSales.get(aliId);
                }
                if(mapAgreeOptGrossPriceRent.containsKey(aliId) && mapAgreeOptGrossPriceRent.get(aliId) != null){
                    finalGrossPriceRent += mapAgreeOptGrossPriceRent.get(aliId);
                    System.debug('mapAgreeOptGrossPriceRent flow '+ mapAgreeOptGrossPriceRent);
                }

             }else{

                if(mapOptNetPriceService.containsKey(aliId) && mapOptNetPriceService.get(aliId) != null){
                    finalNetPriceService += mapOptNetPriceService.get(aliId);
                    System.debug('mapOptNetPriceService flow '+ mapOptNetPriceService);
                }
                if(mapOptNetPriceSales.containsKey(aliId) && mapOptNetPriceSales.get(aliId) != null){
                    finalNetPriceSales += mapOptNetPriceSales.get(aliId);
                }
                if(mapOptNetPriceRent.containsKey(aliId) &&  mapOptNetPriceRent.get(aliId) != null){
                    finalNetPriceRent += mapOptNetPriceRent.get(aliId);
                        System.debug('mapOptNetPriceRent flow '+ mapOptNetPriceRent);
                }
                
                if(mapOptGrossPriceService.containsKey(aliId) && mapOptGrossPriceService.get(aliId) != null){
                    finalGrossPriceService += mapOptGrossPriceService.get(aliId);System.debug('mapOptGrossPriceService flow '+ mapOptGrossPriceService);
                }
                if(mapOptGrossPriceSales.containsKey(aliId) && mapOptGrossPriceSales.get(aliId) != null){
                    finalGrossPriceSales += mapOptGrossPriceSales.get(aliId);
                }
                if(mapOptGrossPriceRent.containsKey(aliId) && mapOptGrossPriceRent.get(aliId) != null){
                    finalGrossPriceRent += mapOptGrossPriceRent.get(aliId); System.debug('mapOptGrossPriceRent flow '+ mapOptGrossPriceRent);
                }
             }
         }
         mapPL1NetPrice.put(assetPLI, finalNetPrice);
         mapPL1GrossPrice.put(assetPLI, finalGrossPrice);

         if(isPreviousAgreement){

            mapPL1AgreeNetPriceService.put(assetPLI, finalNetPriceService);
            mapPL1AgreeNetPriceSales.put(assetPLI, finalNetPriceSales);
            mapPL1AgreeNetPriceRent.put(assetPLI, finalNetPriceRent);

            mapPL1AgreeGrossPriceService.put(assetPLI, finalGrossPriceService);
            mapPL1AgreeGrossPriceSales.put(assetPLI, finalGrossPriceSales);
            mapPL1AgreeGrossPriceRent.put(assetPLI, finalGrossPriceRent);
            System.debug('mapPL1AgreeGrossPriceRent flow '+ mapPL1AgreeGrossPriceRent);
            System.debug('mapPL1AgreeNetPriceRent flow '+ mapPL1AgreeNetPriceRent);
            System.debug('mapPL1AgreeGrossPriceService flow '+ mapPL1AgreeGrossPriceService);

         }else{
System.debug('here');
            mapPL1NetPriceService.put(assetPLI, finalNetPriceService);
            mapPL1NetPriceSales.put(assetPLI, finalNetPriceSales);
            mapPL1NetPriceRent.put(assetPLI, finalNetPriceRent);

            mapPL1GrossPriceService.put(assetPLI, finalGrossPriceService);
            mapPL1GrossPriceSales.put(assetPLI, finalGrossPriceSales);
            mapPL1GrossPriceRent.put(assetPLI, finalGrossPriceRent);
         }
       }

        
   }

   /****************************************************************** 
   @Description: This method is used to identify all asset related BusinessTypes.
   @Params : Set<Id> 
   @return : Map<String, String>
   ******************************************************************/
   public Map<String, String> getFinalAssetWithBusinessType(Set<Id> setAssetId ){
       
       Map<String, Integer> mapBusiTypeSort = new Map<String, Integer>{'0002' => 1, '0001' => 2, 'A005' => 3, 'B005' => 3, '0003' => 4, '0004' => 5};
       Map<Integer, String> mapCodeBusiTypeSort = new Map<Integer, String>{1 => '0002',  2 => '0001',  4 => '0003' , 5 => '0004'};
       Map<Id, Integer> mapAssetBusiTypeSort = new Map<Id, Integer>();
       Map<String, String> mapAssetWithBusinessTypeFinal = new Map<String, String>();
       Integer businessTypeSort ;
       String formulaBusinessType ;

        for(RTR_LAE_Transaction_Data__c transData : getAllTransactionData(setAssetId,setSchBusinesstype)) {   
      
            businessTypeSort = mapBusiTypeSort.get(transData.APTS_Business_Transaction_Type__c);

            if(mapAssetBusiTypeSort.containsKey(transData.APTS_Asset_Line_Item__c) && mapAssetBusiTypeSort.get(transData.APTS_Asset_Line_Item__c) > 0 ){
                    integer sortDegree =  mapAssetBusiTypeSort.get(transData.APTS_Asset_Line_Item__c);
                    if(sortDegree > businessTypeSort ){
                        mapAssetBusiTypeSort.put(transData.APTS_Asset_Line_Item__c, businessTypeSort);
                    }
            }else {
                mapAssetBusiTypeSort.put(transData.APTS_Asset_Line_Item__c, businessTypeSort);
            }
            
        }
        
         
          for(Id idd : mapAssetBusiTypeSort.keyset()){
           //   System.debug(' setAssetType0002 '+ idd+'  '+mapAssetBusiTypeSort.get(idd));
              if(mapAssetBusiTypeSort.get(idd) == 3){
                    mapAssetWithBusinessTypeFinal.put(idd+';'+'A005', 'A005');               
                    mapAssetWithBusinessTypeFinal.put(idd+';'+'B005', 'B005');
                }else {
                    formulaBusinessType = idd+';'+mapCodeBusiTypeSort.get(mapAssetBusiTypeSort.get(idd));
                    mapAssetWithBusinessTypeFinal.put(formulaBusinessType, mapCodeBusiTypeSort.get(mapAssetBusiTypeSort.get(idd)));
                }
          }

      

        return mapAssetWithBusinessTypeFinal;
   }
 
   
   /****************************************************************** 
   @Description: This method is used to identify all asset related billingschedule.
   @Params : Set<String>,  Set<Id>
   @return : Map<Id, List<Apttus_Billing__BillingSchedule__c>>
   ******************************************************************/
   public Map<Id, List<Apttus_Billing__BillingSchedule__c>> getBillingSchRelatedtoAsset( Set<Id> setAssetId, Map<Id, List<Apttus_Billing__BillingSchedule__c>> mapAllPriyAssetBillingSchGen, Boolean isGrossPriceCall){

       // Set<String> setBillingStatus = new Set<String>{'Invoiced', 'Pending Invoiced', 'Pending Billing'};
        Map<Id, List<Apttus_Config2__AssetLineItem__c>> mapAllPL1OptionAsset = new Map<Id, List<Apttus_Config2__AssetLineItem__c>>();
        Map<Id, Id> mapPL1withOptions = new Map<Id, Id>();
        Set<Id> setUnique = new Set<Id>();
        //Set<String> setExcludeOptions = new Set<String>{'0107','0108'};
        Set<String> setExcludeSalesOptions = new Set<String>{'0107;Sales Price','0108;Sales Price'};
        String formulaExcludeSalesOptions;

       for(Apttus_Config2__AssetLineItem__c aliopt : [SELECT Id, Apttus_Config2__ChargeType__c, APTS_Is_Primary_L1_Asset__c,
                                                             Apttus_Config2__BasePrice__c, Apttus_Config2__Quantity__c ,
                                                             Apttus_Config2__OptionId__r.APTS_Option_Group_Indicator__c
                                               FROM Apttus_Config2__AssetLineItem__c 
                                               WHERE Apttus_Config2__LineType__c =: 'Option' AND                                                    
                                                   APTS_Is_Primary_L1_Asset__c IN: setAssetId]) {
                                                   

                    formulaExcludeSalesOptions = aliopt.Apttus_Config2__OptionId__r.APTS_Option_Group_Indicator__c+';'+aliopt.Apttus_Config2__ChargeType__c;
                   if(!setExcludeSalesOptions.contains(formulaExcludeSalesOptions)){
                        
                        //if(!isGrossPriceCall && lstAssetLineItemOptions.isEmpty()){
                                                 lstAssetLineItemOptions.add(aliopt);
                               System.debug('Lavanya'+lstAssetLineItemOptions)  ;
                       // }               

                        mapPL1withOptions.put(aliopt.Id, aliopt.APTS_Is_Primary_L1_Asset__c);
                        if(mapPL1AssetWithOptions.containskey(aliopt.APTS_Is_Primary_L1_Asset__c) && mapPL1AssetWithOptions.get(aliopt.APTS_Is_Primary_L1_Asset__c) != null){
                                Set<Id> setOptions = mapPL1AssetWithOptions.get(aliopt.APTS_Is_Primary_L1_Asset__c) ;
                                setOptions.add(aliopt.Id);
                                mapPL1AssetWithOptions.put(aliopt.APTS_Is_Primary_L1_Asset__c, setOptions);
                        }else{
                                mapPL1AssetWithOptions.put(aliopt.APTS_Is_Primary_L1_Asset__c, new set<Id> { aliopt.Id });
                        } System.debug('Lavanya'+mapPL1AssetWithOptions+'mapPL1withOptions'+mapPL1withOptions.size())  ;
                 }
                                                
        }
          
        //  system.debug('setAssetId :'+ setAssetId);
        //   system.debug('mapPL1withOptions :'+ mapPL1withOptions);

        if(!mapPL1withOptions.isEmpty()) {
            Id parentId ;
            Set<Id> setALIIds = mapPL1withOptions.keySet();
            System.debug('Lavanya setAliids'+setALIIds);
            String billSchQuery = ' SELECT Id, name, Apttus_Billing__FeeAmount__c, Apttus_Billing__PeriodStartDate__c, '
                                   +'  Apttus_Billing__PeriodEndDate__c, Apttus_Billing__AssetLineItemId__c, '
                                   +'  Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ChargeType__c, '
                                   +'  Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BasePrice__c, '
                                   +'  Apttus_Billing__AssetLineItemId__r.Apttus_Config2__Quantity__c, Apttus_Billing__Status__c '
                                   +' FROM Apttus_Billing__BillingSchedule__c '
                                   +' WHERE Apttus_Billing__AssetLineItemId__c IN: setALIIds  ' ;

            if(isGrossPriceCall){
                     billSchQuery += ' AND Apttus_Billing__Status__c IN: setBillingStatusGrossPrice  ';
                     billSchQuery += ' AND APTS_Agreement__r.Apttus__Agreement_Number__c IN: setPrevAgreeNumber';  
                     System.debug('Lavanya 1'+setPrevAgreeNumber+'billing'+setBillingStatusGrossPrice);
             } else {
                 if(isNewAgreementGrossPriceCal){
                     billSchQuery += ' AND Apttus_Billing__Status__c IN: setBillingStatusGrossPrice ';   
                     isNewAgreementGrossPriceCal = false;   
                      System.debug('Lavanya 2'+setBillingStatusGrossPrice);              
                 }
                 else {
                      billSchQuery += ' AND ((Apttus_Billing__Status__c IN: setBillingStatusNetPrice AND Apttus_Billing__IsSuperseded__c = false)  OR Apttus_Billing__Status__c =: strInvoiced) ';                     
                                           
                 }
                  billSchQuery += ' AND APTS_Agreement__r.Apttus__Agreement_Number__c IN: setALIAgreeNumber';
                  System.debug('Lavanya 3'+setALIAgreeNumber);      
            }
                                                
            for(Apttus_Billing__BillingSchedule__c billsch : Database.Query(billSchQuery)) {      
            System.debug('Am cmin inside finally');  
                    
                    parentId = billsch.Apttus_Billing__AssetLineItemId__c;
                    
                   
                       if(!setUnique.contains(billsch.Id)){
                        if(mapAllPriyAssetBillingSchGen.containsKey(parentId) && mapAllPriyAssetBillingSchGen.get(parentId) != null){
                            List<Apttus_Billing__BillingSchedule__c> lstBillsch =  mapAllPriyAssetBillingSchGen.get(parentId);
                            lstBillsch.add(billsch);
                            mapAllPriyAssetBillingSchGen.put(parentId, lstBillsch);
                            
                           
                        }
                        else {
                             mapAllPriyAssetBillingSchGen.put(parentId, new List<Apttus_Billing__BillingSchedule__c> { billsch });
                             
                        }
                         setUnique.add(billsch.Id);
                     }
                    
                 //    system.debug(' setUnique :' + setUnique.size()+ '  '+mapAllPriyAssetBillingSchGen.values().size());
                  
              }
        }

        return mapAllPriyAssetBillingSchGen;
        
   }

   /****************************************************************** 
   @Description: This method is used to create staging data.
   @Params : Map<Id, Apttus_Config2__AssetLineItem__c>,  Map<Id, Decimal>, Map<Id, Decimal>, Map<String, String>
   @return : void
   ******************************************************************/
   public List<RTR_LAE_Staging_Data__c> createStagingData(Map<Id, Apttus_Config2__AssetLineItem__c> mapAssetLineItem,   Map<Id, Decimal> mapFinalAssetNetPrice,  Map<Id, Decimal> mapFinalAssetGrossPrice, Map<String, String> mapAssetWithBusinessTypeFinal){
    
       List<RTR_LAE_Staging_Data__c> lstStagingData = new List<RTR_LAE_Staging_Data__c>();
       //List<RTR_LAE_Transaction_Data__c> lstTransData = new List<RTR_LAE_Transaction_Data__c>();
       List<RTR_LAE_Transaction_Data__c> lstFinalDataonValidation = new List<RTR_LAE_Transaction_Data__c>();
       String formulaBusinessType, formulaChargeType ;
       Date physicalAssetActivateWarrentyDate  ;
       Integer remainingValue = 0;
       Id parentId;

        if(Test.isRunningTest()){
           lstFinalDataonValidation.addAll(getAllTransactionData(mapAssetLineItem.keySet(),setSchBusinesstype));
        }else { 
          lstFinalDataonValidation.addAll(validateTransData(mapAssetLineItem.keySet(), mapFinalAssetNetPrice, mapFinalAssetGrossPrice));
        }


       system.debug('lstFinalDataonValidation: '+lstFinalDataonValidation.size());
       //system.debug('getAllTransactionData(setFinalDataonValidation) : '+getAllTransactionData(setFinalDataonValidation).size());
        

       for(RTR_LAE_Transaction_Data__c transData : lstFinalDataonValidation){
           
           formulaBusinessType = transData.APTS_Asset_Line_Item__c +';'+ transData.APTS_Business_Transaction_Type__c;
           remainingValue = 0;
            if(transData.APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__c != null)  {
                parentId = transData.APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__c;
            }else {
                parentId = transData.APTS_Asset_Line_Item__c;
            } 

            formulaChargeType = parentId +';'+ transData.APTS_Asset_Line_Item__r.Apttus_Config2__ChargeType__c;

           system.debug('transData.APTS_Asset_Line_Item__c : '+transData.APTS_Asset_Line_Item__c);
           system.debug('mapFinalAssetNetPrice.containsKey : '+mapPL1NetPrice.containsKey(parentId));
           system.debug('mapFinalAssetGrossPrice.containsKey : '+mapPL1GrossPrice.containsKey(parentId));
           system.debug('mapAssetWithBusinessTypeFinal.containsKey : '+mapAssetWithBusinessTypeFinal.containsKey(formulaBusinessType));

         if( mapPL1NetPrice.containsKey(parentId) && 
             mapPL1GrossPrice.containsKey(parentId) &&
             mapAssetWithBusinessTypeFinal.containsKey(formulaBusinessType)){
                
                Apttus_Config2__AssetLineItem__c assetLI = mapAssetLineItem.get(transData.APTS_Asset_Line_Item__c);

                RTR_LAE_Staging_Data__c newStageData = new RTR_LAE_Staging_Data__c();
                newStageData.APTS_Asset_Line_Item__c = transData.APTS_Asset_Line_Item__c;
                newStageData.APTS_Business_Transaction_Type__c = mapAssetWithBusinessTypeFinal.get(formulaBusinessType);
                if(assetLI.APTS_Type_Of_Contract__c != null && assetLI.APTS_Type_Of_Contract__c.equalsIgnoreCase('Sales')){
                    newStageData.APTS_Contractual_Purchase__c = 'S';
                }
                
                newStageData.APTS_Contract_Effective_Date__c = transData.APTS_Contract_Effective_Date__c;

                if(newStageData.APTS_Business_Transaction_Type__c == 'A005' && mapAssetPreviousAgreementStartDate.containsKey(formulaChargeType) && 
                    mapAssetPreviousAgreementEndDate.containsKey(formulaChargeType)){

                    newStageData.APTS_Contract_Start_Date__c = mapAssetPreviousAgreementStartDate.get(formulaChargeType);
                    newStageData.APTS_Due_Date__c = mapAssetPreviousAgreementStartDate.get(formulaChargeType);
                    newStageData.APTS_Start_Date__c = mapAssetPreviousAgreementStartDate.get(formulaChargeType);
                    newStageData.APTS_Contract_End_Date__c = mapAssetPreviousAgreementEndDate.get(formulaChargeType);
                    newStageData.APTS_End_Date__c = mapAssetPreviousAgreementEndDate.get(formulaChargeType);

                }else if(newStageData.APTS_Business_Transaction_Type__c == 'B005' && mapAssetCurrentAgreementStartDate.containsKey(formulaChargeType) &&
                         mapAssetCurrentAgreementEndDate.containsKey(formulaChargeType)){

                    newStageData.APTS_Contract_Start_Date__c = mapAssetCurrentAgreementStartDate.get(formulaChargeType);
                    newStageData.APTS_Due_Date__c = mapAssetCurrentAgreementStartDate.get(formulaChargeType);
                    newStageData.APTS_Start_Date__c = mapAssetCurrentAgreementStartDate.get(formulaChargeType);
                    newStageData.APTS_Contract_End_Date__c = mapAssetCurrentAgreementEndDate.get(formulaChargeType);
                    newStageData.APTS_End_Date__c = mapAssetCurrentAgreementEndDate.get(formulaChargeType);

                }else if(mapAssetLineItem.get(assetLI.Id).APTS_MigrationDate__c != null){
                    newStageData.APTS_Contract_Start_Date__c = assetLI.Apttus_Config2__StartDate__c;
                    newStageData.APTS_Due_Date__c = assetLI.Apttus_Config2__StartDate__c;
                }
                else {
                    newStageData.APTS_Contract_Start_Date__c = assetLI.Apttus_Config2__BillingStartDate__c;
                    newStageData.APTS_Due_Date__c = assetLI.Apttus_Config2__BillingStartDate__c;
                }

                if(transData.APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__c == null && transData.APTS_Asset_Line_Item__r.APTS_Physical_Asset__c != null){
                    newStageData.APTS_Physical_Asset__c = transData.APTS_Asset_Line_Item__r.APTS_Physical_Asset__c;

                }else if(transData.APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__c != null){
                    newStageData.APTS_Physical_Asset__c = transData.APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__r.APTS_Physical_Asset__c;
                }
                //v1.7 | Added by Karan | DQ-1829 START
                System.debug('******tranData.APTS_Asset_Line_Item__r.APTS_Contract_Change__c=====>'+transData.APTS_Asset_Line_Item__r.APTS_Contract_Change__c);
                System.debug('******tranData.APTS_Business_Transaction_Type__c=====>'+transData.APTS_Business_Transaction_Type__c);
                System.debug('******tranData.APTS_Asset_Line_Item__r.APTS_Terminated_PHA_serial_number__c=====>'+transData.APTS_Asset_Line_Item__r.APTS_Terminated_PHA_serial_number__c);
                System.debug('******tranData.APTS_Asset_Line_Item__r.APTS_Terminated_Physical_Asset__c=====>'+transData.APTS_Asset_Line_Item__r.APTS_Terminated_Physical_Asset__c);
                if(transData.APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__c == null && transData.APTS_Business_Transaction_Type__c.equalsIgnoreCase('0002') && transData.APTS_Asset_Line_Item__r.APTS_Contract_Change__c && transData.APTS_Asset_Line_Item__r.APTS_Terminated_Physical_Asset__c!=null){
                    newStageData.APTS_Physical_Asset__c = transData.APTS_Asset_Line_Item__r.APTS_Terminated_Physical_Asset__c;
                }
                if( transData.APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__c != null && transData.APTS_Business_Transaction_Type__c.equalsIgnoreCase('0002') && transData.APTS_Asset_Line_Item__r.APTS_Contract_Change__c && transData.APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__r.APTS_Terminated_Physical_Asset__c!=null){
                    newStageData.APTS_Physical_Asset__c = transData.APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__r.APTS_Terminated_Physical_Asset__c;
                }
                //v1.7 | Added by Karan | DQ-1829 END
                if(!newStageData.APTS_Business_Transaction_Type__c.contains('005') && (assetLI.Apttus_Config2__ChargeType__c == 'Sales Price' || assetLI.Apttus_Config2__ChargeType__c == 'Rental Fee') ){
                    newStageData.APTS_Start_Date__c = assetLI.Apttus_Config2__OriginalStartDate__c;
                    newStageData.APTS_Contract_End_Date__c = assetLI.Apttus_Config2__EndDate__c;  
                    newStageData.APTS_End_Date__c = assetLI.Apttus_Config2__EndDate__c;
                } 
                // v1.1 - START
                if(!newStageData.APTS_Business_Transaction_Type__c.contains('005') && assetLI.Apttus_Config2__ChargeType__c == 'Service Fee' 
                    && mapServiceAssetStartDate.containsKey(parentId) && mapServiceAssetEndDate.containsKey(parentId)){
                    newStageData.APTS_Contract_Start_Date__c = mapServiceAssetStartDate.get(parentId);                    
                    newStageData.APTS_Start_Date__c = mapServiceAssetStartDate.get(parentId);
                    newStageData.APTS_Contract_End_Date__c = mapServiceAssetEndDate.get(parentId);
                    newStageData.APTS_End_Date__c = mapServiceAssetEndDate.get(parentId);
                }
                // v1.1 - END
                // v1.4 - START
                //PRIMARY LOGIC TO VALIDATE THE RECORD HAS PASSED INITIAL CRITERIA
                if(assetLI.Apttus_Config2__ChargeType__c == 'Service Fee' && assetLI.APTS_Type_Of_Contract__c == 'Sales' && 
                    newStageData.APTS_Business_Transaction_Type__c != 'B005' && 
                    mapServiceActiveWarranty.containsKey(parentId) && mapServiceActiveWarranty.get(parentId)  &&
                   //INSERT LOGIC THAT DETERMINES IF LEVEL 1 CD = OVERWRITE DATE
                     ((transData.Service_Installation_Override__c != null && mapServiceWarrantyDate.containsKey(parentId) && 
                     mapServiceWarrantyDate.get(parentId) == transData.Service_Installation_Override__c)
                    ||                    
                    //INSERT LOGIC THAT DETERMINES IF LEVEL 1 CD = OPTION CD
                    (transData.Service_Installation_Override__c == null && mapServiceWarranty.containsKey(parentId) && mapServiceWarranty.get(parentId) ))){
                    
                    newStageData.APTS_Contract_Start_Date__c = mapServiceActiveWarrantyDate.get(parentId);                  
                    newStageData.APTS_Start_Date__c = mapServiceActiveWarrantyDate.get(parentId);
                }
                // v1.4 - END                

                if(newStageData.APTS_Business_Transaction_Type__c == 'A005'){

                    if(assetLI.Apttus_Config2__ChargeType__c == 'Service Fee'){
                        newStageData.APTS_NetPrice_Amount__c = mapPL1AgreeNetPriceService.get(parentId);
                        newStageData.APTS_Gross_Amount__c =  mapPL1AgreeGrossPriceService.get(parentId);
                    }else if(assetLI.Apttus_Config2__ChargeType__c == 'Sales Price'){
                        newStageData.APTS_NetPrice_Amount__c = mapPL1AgreeNetPriceSales.get(parentId);
                        newStageData.APTS_Gross_Amount__c =  mapPL1AgreeGrossPriceSales.get(parentId);
                    }else if(assetLI.Apttus_Config2__ChargeType__c == 'Rental Fee'){
                        newStageData.APTS_NetPrice_Amount__c = mapPL1AgreeNetPriceRent.get(parentId);
                        newStageData.APTS_Gross_Amount__c =  mapPL1AgreeGrossPriceRent.get(parentId);
                    }

                }else {
                    if(assetLI.Apttus_Config2__ChargeType__c == 'Service Fee'){
                        newStageData.APTS_NetPrice_Amount__c = mapPL1NetPriceService.get(parentId);
                        newStageData.APTS_Gross_Amount__c =  mapPL1GrossPriceService.get(parentId);
                    }else if(assetLI.Apttus_Config2__ChargeType__c == 'Sales Price'){
                        newStageData.APTS_NetPrice_Amount__c = mapPL1NetPriceSales.get(parentId);
                        newStageData.APTS_Gross_Amount__c =  mapPL1GrossPriceSales.get(parentId);
                    }else if(assetLI.Apttus_Config2__ChargeType__c == 'Rental Fee'){
                        newStageData.APTS_NetPrice_Amount__c = mapPL1NetPriceRent.get(parentId);
                        newStageData.APTS_Gross_Amount__c =  mapPL1GrossPriceRent.get(parentId);
                    }
                }


                
               if(newStageData.APTS_Business_Transaction_Type__c == 'A005' && mapAssetPreviousAgreementNumber.containsKey(assetLI.Id)){
                   newStageData.APTS_Contract_Number__c = mapAssetPreviousAgreementNumber.get(assetLI.Id);
               } else {
                   newStageData.APTS_Contract_Number__c = assetLI.Apttus_CMConfig__AgreementId__r.Apttus__Agreement_Number__c;
               }
            
              if(newStageData.APTS_Business_Transaction_Type__c == 'A005' && mapAssetPreviousAccount.containsKey(assetLI.Id)){
                   newStageData.APTS_Customer__c = mapAccountSAPID.get(mapAssetPreviousAccount.get(assetLI.Id));
              }else{
                   newStageData.APTS_Customer__c = assetLI.Apttus_Config2__AccountId__r.SAP_Customer_ID__c;
              }
               
                newStageData.APTS_Company_Code__c = assetLI.Apttus_Config2__AccountId__r.Mini_Company_Code__c;
               
                if(mapRemainingUsefulLife.containsKey(transData.Id)){
                    newStageData.APTS_Remaining_Useful_Life__c = mapRemainingUsefulLife.get(transData.Id);
                }else{
                    newStageData.APTS_Remaining_Useful_Life__c = 0;
                }

                lstStagingData.add(newStageData);                     

            }
      }

       if(!lstStagingData.isEmpty()){ 
           insert lstStagingData;

           return lstStagingData;
       }
       
       return null;
   }

   /****************************************************************** 
   @Description: This method is used to validate the transaction data.
   @Params : Map<Id, Apttus_Config2__AssetLineItem__c>,  Map<Id, Decimal>, Map<Id, Decimal>, Map<String, String>
   @return : void
   ******************************************************************/
   public List<RTR_LAE_Transaction_Data__c> validateTransData(Set<Id> setAssetId,  Map<Id, Decimal> mapFinalAssetNetPrice,  Map<Id, Decimal> mapFinalAssetGrossPrice){
       
       List<RTR_LAE_Transaction_Data__c> lstErrorTransData = new List<RTR_LAE_Transaction_Data__c>();
       List<RTR_LAE_Transaction_Data__c> lstValidTransData = new List<RTR_LAE_Transaction_Data__c>();
       List<RTR_LAE_Transaction_Data__c> lstValidTempTransData = new List<RTR_LAE_Transaction_Data__c>();
       Map<Id, String> mapBundleTransError = new Map<Id, String>();
       String errorDesc = '';
       Id parentId;
    //   system.debug('mapFinalAssetGrossPriceTest '+mapFinalAssetGrossPrice);
     //  system.debug('mapFinalAssetGrossPrice.containsKey : '+mapPL1GrossPrice);
      system.debug('mapPL1NetPrice.containsKey : '+mapPL1NetPrice);

      system.debug('mapPL1AgreeNetPriceService : '+mapPL1AgreeNetPriceService);
      system.debug('mapPL1AgreeGrossPriceService : '+mapPL1AgreeGrossPriceService);

      system.debug('mapPL1AgreeNetPriceSales : '+mapPL1AgreeNetPriceSales);
      system.debug('mapPL1AgreeGrossPriceSales : '+mapPL1AgreeGrossPriceSales);

      system.debug('mapPL1AgreeNetPriceRent : '+mapPL1AgreeNetPriceRent);
      system.debug('mapPL1AgreeGrossPriceRent : '+mapPL1AgreeGrossPriceRent);

      system.debug('mapPL1NetPriceService : '+mapPL1NetPriceService);
      system.debug('mapPL1GrossPriceService : '+mapPL1GrossPriceService);
      
      system.debug('mapPL1NetPriceSales : '+mapPL1NetPriceSales);
      system.debug('mapPL1GrossPriceSales : '+mapPL1GrossPriceSales);

      system.debug('mapPL1NetPriceRent : '+mapPL1NetPriceRent);
      system.debug('mapPL1GrossPriceRent : '+mapPL1GrossPriceRent);

       for(RTR_LAE_Transaction_Data__c tranData : getAllTransactionData(setAssetId,setSchBusinesstype)) {
          //  system.debug('tranData : '+tranData);
            
            errorDesc = '';
            
            if(tranData.APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__c != null)  {
                parentId = tranData.APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__c;
            }else {
                parentId = tranData.APTS_Asset_Line_Item__c;
            } 
            
           if(tranData.APTS_Asset_Line_Item__r.APTS_Asset_Line_Item_Number__c == null){
               errorDesc += 'Asset Line Item Number is Null;';
           }
           if(tranData.APTS_Business_Transaction_Type__c == null){
               errorDesc += 'Business Transaction Type is Null;';
           }
           if(tranData.APTS_Asset_Line_Item__r.Apttus_Config2__AccountId__r.Mini_Company_Code__c == null){
               errorDesc += 'Company Code is Null;';
           }
           if(tranData.APTS_Asset_Line_Item__r.Apttus_Config2__ProductId__r.Name == null){
               errorDesc += 'Contract Description is Null;';
           }
           if(tranData.APTS_Contract_Effective_Date__c == null){
               errorDesc += 'Contract Effective Date is Null;';
           }
           if(tranData.APTS_Asset_Line_Item__r.Apttus_Config2__EndDate__c == null){
               errorDesc += 'Contract End Date is Null;';
           }
           if(tranData.APTS_Asset_Line_Item__r.Apttus_CMConfig__AgreementId__r.Apttus__Agreement_Number__c == null){
               errorDesc += 'Contract Number is Null;';
           }
           if((tranData.APTS_Asset_Line_Item__r.APTS_MigrationDate__c == null && 
               tranData.APTS_Asset_Line_Item__r.Apttus_Config2__BillingStartDate__c == null) || 
               tranData.APTS_Asset_Line_Item__r.APTS_MigrationDate__c != null && 
               tranData.APTS_Asset_Line_Item__r.Apttus_Config2__StartDate__c == null){
               errorDesc += 'Contract Start Date is Null;'; 
               errorDesc += 'Due Date is Null;';
           }
           if(tranData.APTS_Asset_Line_Item__r.Apttus_Config2__PriceListId__r.CurrencyIsoCode == null){
               errorDesc += 'Currency Code is Null;';
           }
           if(tranData.APTS_Asset_Line_Item__r.Apttus_Config2__AccountId__r.SAP_Customer_ID__c == null){
               errorDesc += 'Customer is Null;';
           }
           if(tranData.APTS_Asset_Line_Item__r.Apttus_Config2__AccountId__r.Distribution_Channel__c == null){
               errorDesc += 'Distribution Channel is Null;';
           }
           if(tranData.APTS_Asset_Line_Item__r.Apttus_Config2__EndDate__c == null){
               errorDesc += 'End Date is Null;';
           }
           if((tranData.APTS_Business_Transaction_Type__c == 'A005' && 
              (tranData.APTS_Asset_Line_Item__r.Apttus_Config2__ChargeType__c == 'Service Fee' && mapPL1AgreeNetPriceService.containsKey(parentId) && mapPL1AgreeNetPriceService.get(parentId) < 0) ||
              (tranData.APTS_Asset_Line_Item__r.Apttus_Config2__ChargeType__c == 'Sales Price' && mapPL1AgreeNetPriceSales.containsKey(parentId) && mapPL1AgreeNetPriceSales.get(parentId) < 0) ||
              (tranData.APTS_Asset_Line_Item__r.Apttus_Config2__ChargeType__c == 'Rental Fee' && mapPL1AgreeNetPriceRent.containsKey(parentId) && mapPL1AgreeNetPriceRent.get(parentId) < 0)) ||
              (tranData.APTS_Business_Transaction_Type__c == 'B005' && 
              (tranData.APTS_Asset_Line_Item__r.Apttus_Config2__ChargeType__c == 'Service Fee' && mapPL1NetPriceService.containsKey(parentId) && mapPL1NetPriceService.get(parentId) < 0) ||
              (tranData.APTS_Asset_Line_Item__r.Apttus_Config2__ChargeType__c == 'Sales Price' && mapPL1NetPriceSales.containsKey(parentId) && mapPL1NetPriceSales.get(parentId) < 0) ||
              (tranData.APTS_Asset_Line_Item__r.Apttus_Config2__ChargeType__c == 'Rental Fee' && mapPL1NetPriceRent.containsKey(parentId) && mapPL1NetPriceRent.get(parentId) < 0)) ||

              ((tranData.APTS_Asset_Line_Item__r.Apttus_Config2__ChargeType__c == 'Service Fee' && mapPL1NetPriceService.containsKey(parentId) && mapPL1NetPriceService.get(parentId) < 0) ||
              (tranData.APTS_Asset_Line_Item__r.Apttus_Config2__ChargeType__c == 'Sales Price' && mapPL1NetPriceSales.containsKey(parentId) && mapPL1NetPriceSales.get(parentId) < 0) ||
              (tranData.APTS_Asset_Line_Item__r.Apttus_Config2__ChargeType__c == 'Rental Fee' && mapPL1NetPriceRent.containsKey(parentId) && mapPL1NetPriceRent.get(parentId) < 0))){
               errorDesc += 'Net Price is lower than Zero;';
           }
           
           SYstem.debug('flow tranData.APTS_Business_Transaction_Type__c'+tranData.APTS_Business_Transaction_Type__c);
           SYstem.debug('flow tranData.parentId'+parentId+'Mapvalue'+mapPL1AgreeGrossPriceRent);
            SYstem.debug('flow tranData.parentId'+parentId+'Mapvalue'+mapPL1GrossPriceRent);
           
           if((tranData.APTS_Business_Transaction_Type__c == 'A005' && 
              (tranData.APTS_Asset_Line_Item__r.Apttus_Config2__ChargeType__c == 'Service Fee' && mapPL1AgreeGrossPriceService.containsKey(parentId) && mapPL1AgreeGrossPriceService.get(parentId) == 0) ||
              (tranData.APTS_Asset_Line_Item__r.Apttus_Config2__ChargeType__c == 'Sales Price' && mapPL1AgreeGrossPriceSales.containsKey(parentId) && mapPL1AgreeGrossPriceSales.get(parentId) == 0) ||
              (tranData.APTS_Asset_Line_Item__r.Apttus_Config2__ChargeType__c == 'Rental Fee' && mapPL1AgreeGrossPriceRent.containsKey(parentId) && mapPL1AgreeGrossPriceRent.get(parentId) == 0)) ||
              (tranData.APTS_Business_Transaction_Type__c == 'B005' && 
              (tranData.APTS_Asset_Line_Item__r.Apttus_Config2__ChargeType__c == 'Service Fee' && mapPL1GrossPriceService.containsKey(parentId) && mapPL1GrossPriceService.get(parentId) == 0) ||
              (tranData.APTS_Asset_Line_Item__r.Apttus_Config2__ChargeType__c == 'Sales Price' && mapPL1GrossPriceSales.containsKey(parentId) && mapPL1GrossPriceSales.get(parentId) == 0) ||
              (tranData.APTS_Asset_Line_Item__r.Apttus_Config2__ChargeType__c == 'Rental Fee' && mapPL1GrossPriceRent.containsKey(parentId) && mapPL1GrossPriceRent.get(parentId) == 0))||

              ((tranData.APTS_Asset_Line_Item__r.Apttus_Config2__ChargeType__c == 'Service Fee' && mapPL1GrossPriceService.containsKey(parentId) && mapPL1GrossPriceService.get(parentId) == 0) ||
              (tranData.APTS_Asset_Line_Item__r.Apttus_Config2__ChargeType__c == 'Sales Price' && mapPL1GrossPriceSales.containsKey(parentId) && mapPL1GrossPriceSales.get(parentId) == 0) ||
              (tranData.APTS_Asset_Line_Item__r.Apttus_Config2__ChargeType__c == 'Rental Fee' && mapPL1GrossPriceRent.containsKey(parentId) && mapPL1GrossPriceRent.get(parentId) == 0))){
               errorDesc += 'Gross Price must be higher than Zero;';
           }
           if(tranData.APTS_Asset_Line_Item__r.Apttus_Config2__ProductId__r.ProductCode == null){
               errorDesc += 'Product Code is Null;';
           }
           if(tranData.APTS_Asset_Line_Item__r.Apttus_Config2__ChargeType__c == null){
               errorDesc += 'Product Family is Null;';
           }
           if(mapRemainingUsefulLife.containsKey(tranData.Id) && (mapRemainingUsefulLife.get(tranData.Id) < 0 || mapRemainingUsefulLife.get(tranData.Id) > 84)){
               errorDesc += 'Remaining Useful Life should be in between 0 and 84;';
           }
           if(tranData.APTS_Business_Transaction_Type__c == TRANS_0001 &&
              tranData.APTS_Asset_Line_Item__r.APTS_MigrationDate__c == null && 
              tranData.APTS_Asset_Line_Item__r.Apttus_Config2__ChargeType__c == 'Rental fee' && 
              tranData.APTS_Asset_Line_Item__r.APTS_Type_Of_Contract__c != 'Sales' && 
              tranData.APTS_Asset_Line_Item__r.APTS_Installation_Sales_Order_Item__c == null) {
               errorDesc += 'Sales Order Item is Null;';
           }
           if(tranData.APTS_Asset_Line_Item__r.Apttus_Config2__AccountId__r.Sales_Organization__c == null){
               errorDesc += 'Sales Org is Null;';
           }
           //v1.3 - START
           if(((tranData.APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__c != null && tranData.APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__r.APTS_Physical_Asset__r.APTS_FinanceId__c == null && 
                tranData.APTS_Asset_Line_Item__r.Apttus_Config2__ChargeType__c == 'Service Fee')
                || 
                (tranData.APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__c == null && tranData.APTS_Asset_Line_Item__r.APTS_Physical_Asset__r.APTS_FinanceId__c == null && 
                tranData.APTS_Asset_Line_Item__r.Apttus_Config2__ChargeType__c != 'Service Fee')) && !(tranData.APTS_Asset_Line_Item__r.APTS_Contract_Change__c && tranData.APTS_Business_Transaction_Type__c.equalsIgnoreCase('0002'))){
               System.debug('Inside first if');
               errorDesc += 'Serial Number is Null;';
           }
           System.debug('******tranData.APTS_Asset_Line_Item__r.APTS_Contract_Change__c=====>'+tranData.APTS_Asset_Line_Item__r.APTS_Contract_Change__c);
           System.debug('******tranData.APTS_Business_Transaction_Type__c=====>'+tranData.APTS_Business_Transaction_Type__c);
           System.debug('******tranData.APTS_Asset_Line_Item__r.APTS_Terminated_PHA_serial_number__c=====>'+tranData.APTS_Asset_Line_Item__r.APTS_Terminated_PHA_serial_number__c);
           if(((tranData.APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__c != null && tranData.APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__r.APTS_Terminated_PHA_serial_number__c == null && 
                tranData.APTS_Asset_Line_Item__r.Apttus_Config2__ChargeType__c == 'Service Fee')
                || 
                (tranData.APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__c == null && tranData.APTS_Asset_Line_Item__r.APTS_Terminated_PHA_serial_number__c == null && 
                tranData.APTS_Asset_Line_Item__r.Apttus_Config2__ChargeType__c != 'Service Fee')) && (tranData.APTS_Asset_Line_Item__r.APTS_Contract_Change__c && tranData.APTS_Business_Transaction_Type__c.equalsIgnoreCase('0002'))){
               System.debug('Inside second if');
               errorDesc += 'Serial Number is Null;';
               //checkifExist;
           }
           
           //v1.3 - END
           if(tranData.APTS_Asset_Line_Item__r.Apttus_Config2__OriginalStartDate__c == null){
               errorDesc += 'Start Data is Null;';
           }
           //v1.2 - START
           if(mapBundleTransError.containsKey(parentId) && String.isBlank(errorDesc)){
               errorDesc = mapBundleTransError.get(parentId);
           } 
           //v1.2 - END
           
           if(String.isBlank(errorDesc)){
               lstValidTempTransData.add(tranData);
           }
           else {
               //v1.2 - START
               if(!mapBundleTransError.containsKey(parentId)) {
                   mapBundleTransError.put(parentId, 'Twin Transaction has error;');
               }
               //v1.2 - END
               tranData.Error_Description__c  = errorDesc;    
               tranData.Error_in_Processing__c = true;
               tranData.APTS_Asset_Processed__c = true;
               setErrorTransData.add(tranData.Id);
               lstErrorTransData.add(tranData);                
           }        
            

       }

       //v1.2 - START
       for(RTR_LAE_Transaction_Data__c tranData : lstValidTempTransData){
           if(tranData.APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__c != null)  {
                parentId = tranData.APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__c;
            }else {
                parentId = tranData.APTS_Asset_Line_Item__c;
            } 

            if(mapBundleTransError.containsKey(parentId)){
               tranData.Error_Description__c  = mapBundleTransError.get(parentId);    
               tranData.Error_in_Processing__c = true;
               tranData.APTS_Asset_Processed__c = true;
               setErrorTransData.add(tranData.Id);
               lstErrorTransData.add(tranData);                         
            }
            else {
                lstValidTransData.add(tranData);
            }
       }
       //v1.2 - END
         system.debug('lstErrorTransData : '+lstErrorTransData);
         system.debug('setValidTransData : '+lstValidTransData);

       if(!lstErrorTransData.isEmpty()){ update lstErrorTransData; }

       return lstValidTransData;
       
   }

   /****************************************************************** 
   @Description: This method is used to verify the asset life is in between 0 to 84.
   @Params : List<RTR_LAE_Transaction_Data__c>
   @return : void
   ******************************************************************/
    public void remainingUsefulLife(List<RTR_LAE_Transaction_Data__c> listTransData){       
       
       Integer remainingValue = 0;
        for(RTR_LAE_Transaction_Data__c tranData : listTransData){
            remainingValue = 0;
            if(tranData.APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__c == null && 
                tranData.APTS_Contract_Effective_Date__c != null && 
                tranData.APTS_Asset_Line_Item__r.APTS_Physical_Asset__r.InitialActivationDate__c != null) {

                remainingValue = tranData.APTS_Asset_Line_Item__r.APTS_Physical_Asset__r.InitialActivationDate__c.monthsBetween(tranData.APTS_Contract_Effective_Date__c);
                
            }else if(tranData.APTS_Contract_Effective_Date__c != null && tranData.APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__r.APTS_Physical_Asset__r.InitialActivationDate__c != null ){                 
                remainingValue = tranData.APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__r.APTS_Physical_Asset__r.InitialActivationDate__c.monthsBetween(tranData.APTS_Contract_Effective_Date__c);
            //v1.7 | Added by Karan | DQ-1829 START
            }else if(tranData.APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__c == null && tranData.APTS_Business_Transaction_Type__c.equalsIgnoreCase('0002') && tranData.APTS_Asset_Line_Item__r.APTS_Contract_Change__c && tranData.APTS_Asset_Line_Item__r.APTS_Term_PHA_Initial_Activation_Date__c!=null){
                remainingValue = tranData.APTS_Asset_Line_Item__r.APTS_Term_PHA_Initial_Activation_Date__c.monthsBetween(tranData.APTS_Contract_Effective_Date__c);
            }else if(tranData.APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__c != null && tranData.APTS_Business_Transaction_Type__c.equalsIgnoreCase('0002') && tranData.APTS_Asset_Line_Item__r.APTS_Contract_Change__c && tranData.APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__r.APTS_Term_PHA_Initial_Activation_Date__c!=null){
                remainingValue = tranData.APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__r.APTS_Term_PHA_Initial_Activation_Date__c.monthsBetween(tranData.APTS_Contract_Effective_Date__c);
            }
             //v1.7 | Added by Karan | DQ-1829 END
            if(remainingValue < 0){
                remainingValue = remainingValue * -1;
            }
            remainingValue = Integer.valueOf(84 - remainingValue);
            
            if(remainingValue > 0){
                mapRemainingUsefulLife.put(tranData.Id, remainingValue);
            }else{
                mapRemainingUsefulLife.put(tranData.Id, 0);
            }
            
        }

   }

   /****************************************************************** 
   @Description: This method will return list of transaction data record.
   @Params : Set<Id>
   @return : List<RTR_LAE_Transaction_Data__c>
   ******************************************************************/
   public List<RTR_LAE_Transaction_Data__c> getAllTransactionData(Set<Id> setAssetId,Set<String>setBusinesstype){

       String strQuery = 'SELECT Id, APTS_Business_Transaction_Type__c, APTS_Asset_Line_Item__c, '
                          + '  APTS_Asset_Line_Item__r.APTS_Asset_Line_Item_Number__c,'
                          + '  APTS_Asset_Line_Item__r.Apttus_Config2__AccountId__r.Mini_Company_Code__c,'
                          + '  APTS_Asset_Line_Item__r.Apttus_Config2__ProductId__r.Name,'
                          + '  APTS_Contract_Effective_Date__c,'
                          + '  APTS_Contractual_Purchase__c,'
                          + '  APTS_Asset_Line_Item__r.Apttus_Config2__EndDate__c,'
                          + '  APTS_Asset_Line_Item__r.Apttus_CMConfig__AgreementId__r.Apttus__Agreement_Number__c,'
                          + '  APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__r.APTS_Physical_Asset__r.InitialActivationDate__c,'
                          + '  APTS_Asset_Line_Item__r.APTS_Physical_Asset__r.InitialActivationDate__c,'
                          + '  APTS_Asset_Line_Item__r.APTS_MigrationDate__c,'
                          + '  APTS_Asset_Line_Item__r.Apttus_Config2__BillingStartDate__c,'
                          + '  APTS_Asset_Line_Item__r.Apttus_Config2__StartDate__c,'
                          + '  APTS_Asset_Line_Item__r.Apttus_Config2__PriceListId__r.CurrencyIsoCode,'
                          + '  APTS_Asset_Line_Item__r.Apttus_Config2__AccountId__r.SAP_Customer_ID__c,'
                          + '  APTS_Asset_Line_Item__r.Apttus_Config2__AccountId__r.Distribution_Channel__c,'
                          + '  APTS_Asset_Line_Item__r.Apttus_Config2__ProductId__r.ProductCode,'
                          + '  APTS_Asset_Line_Item__r.Apttus_Config2__ChargeType__c,'
                          + '  APTS_Asset_Line_Item__r.APTS_Type_Of_Contract__c,'
                          + '  APTS_Asset_Line_Item__r.APTS_Installation_Sales_Order_Item__c,'
                          + '  APTS_Asset_Line_Item__r.Apttus_Config2__AccountId__r.Sales_Organization__c,'
                          + '  APTS_Asset_Line_Item__r.APTS_Physical_Asset__r.APTS_FinanceId__c,'
                          + '  APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__r.APTS_Physical_Asset__r.APTS_FinanceId__c,'
                          + '  APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__r.APTS_Physical_Asset__r.ActiveWarranty__c,'
                          + '  APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__r.APTS_Physical_Asset__r.WarrantyStartDate__c,'
                          + '  APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__r.APTS_Physical_Asset__r.Warranty__c,'
                          + '  APTS_Asset_Line_Item__r.APTS_Physical_Asset__r.ActiveWarranty__c,'
                          + '  APTS_Asset_Line_Item__r.APTS_Physical_Asset__r.WarrantyStartDate__c,'
                          + '  APTS_Asset_Line_Item__r.APTS_Physical_Asset__r.Warranty__c,'
                          + '  APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__c,'
                          + '  APTS_Asset_Line_Item__r.APTS_Physical_Asset__c,'
                          + '  APTS_Asset_Line_Item__r.Apttus_Config2__OriginalStartDate__c,'
                          + '  Service_Installation_Override__c,'
                          + '  Error_Description__c,'
                          + '  Error_in_Processing__c,'
                          + '  APTS_Asset_Line_Item__r.APTS_Contract_Change__c,'
                          + '  APTS_Asset_Line_Item__r.APTS_Terminated_PHA_serial_number__c,'
                          + '  APTS_Asset_Line_Item__r.APTS_Terminated_Physical_Asset__c,'
                          + '  APTS_Asset_Line_Item__r.APTS_Term_PHA_Initial_Activation_Date__c,'
                          + '  APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__r.APTS_Terminated_PHA_serial_number__c,'
                          + '  APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__r.APTS_Terminated_Physical_Asset__c,'
                          + '  APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__r.APTS_Term_PHA_Initial_Activation_Date__c'
                          + '  FROM RTR_LAE_Transaction_Data__c '
                          + '  WHERE APTS_Asset_Processed__c = false AND '
                          + '      isDeleted = false AND '
                          + '      Error_in_Processing__c = false ';
                        if(!setTransDataIds.isEmpty()){
                          strQuery += ' AND ID IN: setTransDataIds ';                                
                        }else {
                          strQuery += ' AND APTS_Asset_Line_Item__c IN : setAssetId ';
                        }if(!setBusinesstype.isEmpty()){
                           strQuery += ' AND APTS_Business_Transaction_Type__c IN : setBusinesstype ';
                        }
        return Database.query(strQuery);

      
   }
   
   // v1.6 - START
   /****************************************************************** 
   @Description: This method will retrieve asset previous agreement.
   @Params : Set<Id>
   @return : void
   ******************************************************************/
   public void fetchAssetPreviousAgreement(Set<Id> setAssetId, Boolean innerCall){
       //List<Apttus_Config2__AssetLineItem__c> lstAssetAgreeLineItemOptions = new List<Apttus_Config2__AssetLineItem__c>();
       //Map<Id, List<Apttus_Billing__BillingSchedule__c>> mapAllAssetAgreeBillingSch = new Map<Id, List<Apttus_Billing__BillingSchedule__c>>();
       //Map<Id, Set<Id>> mapPL1AssetAgreeWithOptions = new Map<Id, Set<Id>>();
       Map<Id, Decimal> mapAgreeOptGrossPriceService = new Map<Id, Decimal>();
       Map<Id, Decimal> mapAgreeOptGrossPriceSales = new Map<Id, Decimal>();
       Map<Id, Decimal> mapAgreeOptGrossPriceRent = new Map<Id, Decimal>();
       Map<Id, Decimal> mapAgreeOptNetPriceService = new Map<Id, Decimal>();
       Map<Id, Decimal> mapAgreeOptNetPriceSales = new Map<Id, Decimal>();
       Map<Id, Decimal> mapAgreeOptNetPriceRent = new Map<Id, Decimal>();

       Map<Id, Id> mapAgreementAsset = new Map<Id, Id>();       
       Map<String, Id> mapAgreementNumberAssetID = new Map<String, Id>();
       Map<Id, String> mapAgreementNumberID = new Map<Id, String>();
       Map<Id, Date> mapAssetBillSchEarliestDate = new Map<Id, Date>();
       Map<Id, Date> mapAssetBillSchLatestDate = new Map<Id, Date>();
       Map<Id, Decimal> mapFinalAssetGrossPrice = new Map<Id, Decimal>();
       Map<Id, Decimal> mapFinalAssetNetPrice = new Map<Id, Decimal>();
       //Set<String> setExcludeOptions = new Set<String>{'0107','0108'};
       //Set<String> setBillingStatus = new Set<String>{'Invoiced', 'Pending Invoiced', 'Pending Billing'};
       Set<String> setExcludeSalesOptions = new Set<String>{'0107;Sales Price','0108;Sales Price'};
       
       Set<Id> setUnique = new Set<Id>();
       Date bilSchEarliestDate , bilSchLatestDate ;
       Date startDate, endDate;
       Decimal netPrice, netPriceSales, netPriceService, netPriceRent;
       Decimal grossPrice, grossPriceSales, grossPriceService, grossPriceRent;
       Decimal finalNetPrice = 0.0;
       Decimal finalGrossPrice = 0.0;
       Decimal finalNetPriceSales, finalNetPriceService, finalNetPriceRent;
       Decimal finalGrossPriceSales, finalGrossPriceService, finalGrossPriceRent;

       String agreementPrefix = Apttus__APTS_Agreement__c.sobjecttype.getDescribe().getKeyPrefix();
       String agreeOldValue = '';
       String formulaExcludeSalesOptions, formulaAgreeIDNumber;
        System.debug('flow fetchAssetPreviousAgreement');
      
        for(Apttus_Config2__AssetLineItem__c ali : [ SELECT Id, Apttus_Config2__ChargeType__c, APTS_Is_Primary_L1_Asset__c,
                                                             Apttus_Config2__BasePrice__c, Apttus_Config2__Quantity__c ,
                                                             Apttus_Config2__OptionId__r.APTS_Option_Group_Indicator__c,
                                                            (SELECT Id, OldValue, NewValue 
                                                             FROM histories WHERE field ='Apttus_CMConfig__AgreementId__c'   
                                                             ORDER BY Createddate desc) 
                                                     FROM Apttus_Config2__AssetLineItem__c 
                                                     WHERE Apttus_Config2__LineType__c =: 'Option' AND                                                  
                                                          APTS_Is_Primary_L1_Asset__c IN : setAssetId ORDER BY createddate desc ]){

            formulaExcludeSalesOptions = ali.Apttus_Config2__OptionId__r.APTS_Option_Group_Indicator__c+';'+ali.Apttus_Config2__ChargeType__c;

           if(!setExcludeSalesOptions.contains(formulaExcludeSalesOptions)){ 
                for(Apttus_Config2__AssetLineItem__History aliHis : ali.histories){
                    agreeOldValue = String.valueOf(aliHis.OldValue);
                    if(String.isNotBlank(agreeOldValue) && agreeOldValue.startsWith(agreementPrefix) && !mapAssetPreviousAgreement.containsKey(ali.Id)){                
                            mapAssetPreviousAgreement.put(ali.Id, agreeOldValue);   
                            mapAgreementAsset.put(Id.valueOf(agreeOldValue), ali.Id);            
                    }
                }

                lstAssetAgreeLineItemOptions.add(ali);
                system.debug('AssetOptionId -->'+ali.Id);

            if(mapPL1AssetAgreeWithOptions.containskey(ali.APTS_Is_Primary_L1_Asset__c) && mapPL1AssetAgreeWithOptions.get(ali.APTS_Is_Primary_L1_Asset__c) != null){
                    Set<Id> setOptions = mapPL1AssetAgreeWithOptions.get(ali.APTS_Is_Primary_L1_Asset__c) ;
                    setOptions.add(ali.Id);
                    mapPL1AssetAgreeWithOptions.put(ali.APTS_Is_Primary_L1_Asset__c, setOptions);
                }else{
                    mapPL1AssetAgreeWithOptions.put(ali.APTS_Is_Primary_L1_Asset__c, new set<Id> { ali.Id });
                } 
              //  system.debug('mapPL1AssetAgreeWithOptions -->'+mapPL1AssetAgreeWithOptions);
           }


        }

       system.debug('flow mapAgreementAsset -->'+mapAgreementAsset);
      system.debug('flow lstAssetAgreeLineItemOptions -->'+lstAssetAgreeLineItemOptions.size());
        for(Apttus__APTS_Agreement__c agreeLI : [SELECT Id, Apttus__Agreement_Number__c FROM Apttus__APTS_Agreement__c WHERE ID IN: mapAgreementAsset.keyset()]){
            mapAgreementNumberID.put(agreeLI.Id, agreeLI.Apttus__Agreement_Number__c);
            setPrevAgreeNumber.add(agreeLI.Apttus__Agreement_Number__c);
            mapAgreementNumberAssetID.put(agreeLI.Apttus__Agreement_Number__c, mapAgreementAsset.get(agreeLI.Id));
        }

        if(innerCall){
         
            for(Apttus__APTS_Agreement__c agreeLI : [SELECT Id, Apttus__Agreement_Number__c,
                                                                (SELECT Id, name, Apttus_Billing__FeeAmount__c, Apttus_Billing__PeriodStartDate__c, 
                                                                        Apttus_Billing__PeriodEndDate__c, Apttus_Billing__AssetLineItemId__c,
                                                                        Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ChargeType__c,
                                                                        Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BasePrice__c,
                                                                        Apttus_Billing__AssetLineItemId__r.Apttus_Config2__Quantity__c,
                                                                        Apttus_Billing__Status__c 
                                                                FROM Billing_Schedules__r WHERE ((Apttus_Billing__Status__c IN: setBillingStatusNetPrice AND Apttus_Billing__IsSuperseded__c =: false)  OR Apttus_Billing__Status__c =: strInvoiced) AND Apttus_Billing__AssetLineItemId__c IN: lstAssetAgreeLineItemOptions) 
                                                        FROM Apttus__APTS_Agreement__c 
                                                        WHERE Apttus__Agreement_Number__c IN: mapAgreementNumberID.values()]){

                                List<Apttus_Billing__BillingSchedule__c> lstBillsch = new List<Apttus_Billing__BillingSchedule__c>();
                            for( Apttus_Billing__BillingSchedule__c billsch : agreeLI.Billing_Schedules__r){
                                if(!setUnique.contains(billsch.Id)){
                                    lstBillsch.add(billsch);
                                }
                                setUnique.add(billsch.Id);
                            }

                            if(mapAllAssetAgreeBillingSch.containskey(mapAgreementNumberAssetID.get(agreeLI.Apttus__Agreement_Number__c)) && mapAllAssetAgreeBillingSch.get(mapAgreementNumberAssetID.get(agreeLI.Apttus__Agreement_Number__c)) != null){
                                    List<Apttus_Billing__BillingSchedule__c> listOptions = mapAllAssetAgreeBillingSch.get(mapAgreementNumberAssetID.get(agreeLI.Apttus__Agreement_Number__c)) ;
                                    listOptions.addAll(lstBillsch);
                                    mapAllAssetAgreeBillingSch.put(mapAgreementNumberAssetID.get(agreeLI.Apttus__Agreement_Number__c), listOptions);
                                }else{
                                    mapAllAssetAgreeBillingSch.put(mapAgreementNumberAssetID.get(agreeLI.Apttus__Agreement_Number__c), lstBillsch);
                                }

                            System.debug('flow mapAllAssetAgreeBillingSch'+mapAllAssetAgreeBillingSch);

            }

        

            mapFinalAssetNetPrice = calculateNetPrice(mapAllAssetAgreeBillingSch, true);
          system.debug('flow mapFinalAssetNetPrice -->'+mapFinalAssetNetPrice);
            mapAllAssetAgreeBillingSch.clear();
            
            mapAllAssetAgreeBillingSch = getBillingSchRelatedtoAsset(setAssetId, mapAllAssetAgreeBillingSch, true);
                System.debug('flow mapAllAssetAgreeBillingSch'+mapAllAssetAgreeBillingSch);
                
            mapFinalAssetGrossPrice = calculateGrossPrice(mapAllAssetAgreeBillingSch, true);
         system.debug('flow mapFinalAssetGrossPrice -->'+mapFinalAssetGrossPrice);

            calculateNetGrossPriceFinal(mapFinalAssetNetPrice, mapFinalAssetGrossPrice, true);

        } 

   }
   // v1.6 - END

   /****************************************************************** 
   @Description: This method will retrieve asset previous AccountSAPID.
   @Params : Set<Id>
   @return : void
   ******************************************************************/
   public void fetchAssetPreviousSoldTo(Set<Id> setAssetId){

       String accountPrefix = Account.sobjecttype.getDescribe().getKeyPrefix();
       String agreementPrefix = Apttus__APTS_Agreement__c.sobjecttype.getDescribe().getKeyPrefix();
       Map<Id, Id> mapAssetPreAgreement = new Map<Id, Id>();
       Map<Id, Id> mapAssetAgreeID = new Map<Id, Id>();
       Map<Id, String> mapAgreementNumber = new Map<Id, String>();
       String assetOldVal;


         for(Apttus_Config2__AssetLineItem__c ali : [ SELECT Id,
                                                            (SELECT Id, OldValue, NewValue, parentId 
                                                             FROM histories WHERE field = 'Apttus_Config2__AccountId__c' OR field = 'Apttus_CMConfig__AgreementId__c'  
                                                             ORDER BY Createddate desc) 
                                                     FROM Apttus_Config2__AssetLineItem__c 
                                                     WHERE  (APTS_Is_Primary_L1_Asset__c IN : setAssetId  OR ID IN:setAssetId) ORDER BY createddate desc ]){
                    
                    for(Apttus_Config2__AssetLineItem__History aliHis : ali.histories){     
                        assetOldVal = String.valueOf(aliHis.OldValue);                  
                        if(string.isNotBlank(assetOldVal) && assetOldVal.startsWith(accountPrefix) && !mapAssetPreviousAccount.containsKey(ali.Id)){
                            mapAssetPreviousAccount.put(ali.Id, Id.valueOf(assetOldVal));
                        }else if(string.isNotBlank(assetOldVal) && assetOldVal.startsWith(agreementPrefix) && !mapAssetPreAgreement.containsKey(aliHis.parentId)){
                            mapAssetPreAgreement.put(aliHis.parentId, Id.valueOf(assetOldVal));
                            mapAssetAgreeID.put(Id.valueOf(assetOldVal), (aliHis.parentId));
                        }
                       // system.debug(' histories '+ aliHis);
                    }
                    
          }
        
          for(Account acc : [SELECT Id, SAP_Customer_ID__c FROM Account WHERE Id IN: mapAssetPreviousAccount.values()]){
              mapAccountSAPID.put(acc.Id, acc.SAP_Customer_ID__c);
          }          
          for(Apttus__APTS_Agreement__c agreeLI : [SELECT Id, Apttus__Agreement_Number__c FROM Apttus__APTS_Agreement__c WHERE ID IN: mapAssetPreAgreement.values()]){
            //mapAssetPreviousAgreementNumber.put(mapAssetAgreeID.get(agreeLI.Id), agreeLI.Apttus__Agreement_Number__c);
            mapAgreementNumber.put(agreeLI.Id, agreeLI.Apttus__Agreement_Number__c);
          }
          for(Id agrId : mapAssetPreAgreement.keyset()){
              mapAssetPreviousAgreementNumber.put(agrId, mapAgreementNumber.get(mapAssetPreAgreement.get(agrId)));
          }
        
   } 

   /****************************************************************** 
   @Description: This method will arrange earlier and latest dates of AssetLineItem.
   @Params : 
   @return : void
   ******************************************************************/
   public void fetchAssetPreviousContractStartEndDates(Set<Id> setAssetId){     
        
        String formulaChargeType ='', chargetype='';
        Date dt;


        String billSchQuery = ' SELECT Id, name, Apttus_Billing__FeeAmount__c, Apttus_Billing__PeriodStartDate__c, '
                               +'  Apttus_Billing__PeriodEndDate__c, Apttus_Billing__AssetLineItemId__c, '
                               +'  Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Asset__c, '
                               +'  Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ChargeType__c, '
                               +'  Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BasePrice__c, '
                               +'  APTS_Agreement__r.Apttus__Agreement_Number__c, '
                               +'  Apttus_Billing__AssetLineItemId__r.Apttus_Config2__Quantity__c, Apttus_Billing__Status__c '
                               +' FROM Apttus_Billing__BillingSchedule__c '
                               +' WHERE Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Asset__c IN: setAssetId '
                               +' AND Apttus_Billing__AssetLineItemId__r.Apttus_Config2__LineType__c = \'Option\' ' 
                               +' AND Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ChargeType__c != \'Usage Fee\' '
                               +' AND Apttus_Billing__Status__c IN: setBillingStatusGrossPrice ';

        if(setPrevAgreeNumber != null){      
                 billSchQuery += ' AND (APTS_Agreement__r.Apttus__Agreement_Number__c IN: setPrevAgreeNumber';  
        }
        if(setALIAgreeNumber != null){         
                 billSchQuery += ' OR APTS_Agreement__r.Apttus__Agreement_Number__c IN: setALIAgreeNumber ';
        } 

        billSchQuery += ' ) ';
               
        
        for(Apttus_Billing__BillingSchedule__c abbs : Database.Query(billSchQuery)){

            chargetype = abbs.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ChargeType__c == 'Additional Service Fee' ? 'Service Fee' : abbs.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ChargeType__c;
            formulaChargeType = abbs.Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Asset__c +';' +chargetype;
             dt = null;
             //v1.2 - START
             setAssetId.remove(abbs.Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Asset__c);
             //v1.2 - END
            if(setALIAgreeNumber.contains(abbs.APTS_Agreement__r.Apttus__Agreement_Number__c)){
                if(!mapAssetCurrentAgreementStartDate.containsKey(formulaChargeType)){
                    mapAssetCurrentAgreementStartDate.put(formulaChargeType, abbs.Apttus_Billing__PeriodStartDate__c);
                }else if(mapAssetCurrentAgreementStartDate.containsKey(formulaChargeType)){
                     dt = mapAssetCurrentAgreementStartDate.get(formulaChargeType);
                    if(abbs.Apttus_Billing__PeriodStartDate__c < dt){
                        mapAssetCurrentAgreementStartDate.put(formulaChargeType, abbs.Apttus_Billing__PeriodStartDate__c);
                    }
                }

                if(!mapAssetCurrentAgreementEndDate.containsKey(formulaChargeType) ){
                    mapAssetCurrentAgreementEndDate.put(formulaChargeType, abbs.Apttus_Billing__PeriodEndDate__c);
                }else if(mapAssetCurrentAgreementEndDate.containsKey(formulaChargeType)){
                     dt = mapAssetCurrentAgreementEndDate.get(formulaChargeType);
                    if(abbs.Apttus_Billing__PeriodEndDate__c > dt){
                        mapAssetCurrentAgreementEndDate.put(formulaChargeType, abbs.Apttus_Billing__PeriodEndDate__c);
                    }
                }
            }
            
            if(setPrevAgreeNumber.contains(abbs.APTS_Agreement__r.Apttus__Agreement_Number__c)){

                 if(!mapAssetPreviousAgreementStartDate.containsKey(formulaChargeType) ){
                    mapAssetPreviousAgreementStartDate.put(formulaChargeType, abbs.Apttus_Billing__PeriodStartDate__c);
                }else if(mapAssetPreviousAgreementStartDate.containsKey(formulaChargeType) ){
                     dt = mapAssetPreviousAgreementStartDate.get(formulaChargeType);
                    if(abbs.Apttus_Billing__PeriodStartDate__c < dt){
                        mapAssetPreviousAgreementStartDate.put(formulaChargeType, abbs.Apttus_Billing__PeriodStartDate__c);
                    }
                }
               

                if(!mapAssetPreviousAgreementEndDate.containsKey(formulaChargeType) ){                    
                    mapAssetPreviousAgreementEndDate.put(formulaChargeType, abbs.Apttus_Billing__PeriodEndDate__c);
                }else if(mapAssetPreviousAgreementEndDate.containsKey(formulaChargeType) ){                    
                     dt = mapAssetPreviousAgreementEndDate.get(formulaChargeType);                    
                    if(abbs.Apttus_Billing__PeriodEndDate__c > dt){
                        mapAssetPreviousAgreementEndDate.put(formulaChargeType, abbs.Apttus_Billing__PeriodEndDate__c);
                    }
                }
            }
                
            
        }
        //v1.2 - START
        setAssetsProcessedWithoutBillSch.addAll(setAssetId);
        //v1.2 - END
   }

   // v1.1 - START
   /******************************************************************************************************************
   @Description: This method will setup service fee and additional service fee earlier and latest dates of AssetLineItem.
   @Params : 
   @return : void
   *******************************************************************************************************************/
   public void fetchServiceFeeAssetContractStartEndDates(Set<Id> setAssetId){    

       Set<String> setChargeTypeAddService = new Set<String>{'Service Fee', 'Additional Service Fee'};
       Date dt;
        
        for(Apttus_Config2__AssetLineItem__c abbs : [SELECT Id, APTS_Is_Primary_L1_Asset__c, Apttus_Config2__EndDate__c, Apttus_Config2__OriginalStartDate__c                                                                                                 
                                                     FROM Apttus_Config2__AssetLineItem__c
                                                     WHERE Apttus_Config2__ChargeType__c IN : setChargeTypeAddService AND 
                                                            Apttus_Config2__LineType__c =: lineType AND 
                                                            APTS_Is_Primary_L1_Asset__c IN: setAssetId ]){           
             dt = null;
            
            if(!mapServiceAssetStartDate.containsKey(abbs.APTS_Is_Primary_L1_Asset__c)){
                mapServiceAssetStartDate.put(abbs.APTS_Is_Primary_L1_Asset__c, abbs.Apttus_Config2__OriginalStartDate__c);
            }else if(mapServiceAssetStartDate.containsKey(abbs.APTS_Is_Primary_L1_Asset__c)){
                    dt = mapServiceAssetStartDate.get(abbs.APTS_Is_Primary_L1_Asset__c);
                if(abbs.Apttus_Config2__OriginalStartDate__c < dt){
                    mapServiceAssetStartDate.put(abbs.APTS_Is_Primary_L1_Asset__c, abbs.Apttus_Config2__OriginalStartDate__c);
                }
            }

            if(!mapServiceAssetEndDate.containsKey(abbs.APTS_Is_Primary_L1_Asset__c) ){
                mapServiceAssetEndDate.put(abbs.APTS_Is_Primary_L1_Asset__c, abbs.Apttus_Config2__EndDate__c);
            }else if(mapServiceAssetEndDate.containsKey(abbs.APTS_Is_Primary_L1_Asset__c)){
                    dt = mapServiceAssetEndDate.get(abbs.APTS_Is_Primary_L1_Asset__c);
                if(abbs.Apttus_Config2__EndDate__c > dt){
                    mapServiceAssetEndDate.put(abbs.APTS_Is_Primary_L1_Asset__c, abbs.Apttus_Config2__EndDate__c);
                }
            }
            
        }
   }
   // v1.1 - END


   // v1.4- START
   /******************************************************************************************************************
   @Description: This method will check the service header and service option created on same day.
   @Params : 
   @return : void
   *******************************************************************************************************************/
   public void fetchServiceHeaderWarranty(Set<Id> setAssetId){    

       Set<String> setChargeTypeService = new Set<String>{'Service Fee'};
       Set<String> setLineTypeOption = new Set<String>{'Option'};
       Boolean activeWarranty = false;
        for(Apttus_Config2__AssetLineItem__c ali : [SELECT Id, APTS_Is_Primary_L1_Asset__c, Createddate, APTS_Is_Primary_L1_Asset__r.Createddate,
                                                        Apttus_Config2__AttributeValueId__r.APTS_Number_of_months__c,
                                                        APTS_Is_Primary_L1_Asset__r.Apttus_Config2__OriginalStartDate__c
                                                     FROM Apttus_Config2__AssetLineItem__c
                                                     WHERE Apttus_Config2__ChargeType__c IN : setChargeTypeService AND 
                                                            Apttus_Config2__LineType__c IN : setLineTypeOption AND 
                                                            APTS_Is_Primary_L1_Asset__c IN: setAssetId ]){    

            if(!mapServiceWarranty.containsKey(ali.APTS_Is_Primary_L1_Asset__c) ){    
                mapServiceWarranty.put(ali.APTS_Is_Primary_L1_Asset__c, ali.Createddate.isSameDay(ali.APTS_Is_Primary_L1_Asset__r.Createddate));
                mapServiceWarrantyDate.put(ali.APTS_Is_Primary_L1_Asset__c, Date.valueOf(ali.APTS_Is_Primary_L1_Asset__r.Createddate));
                activeWarranty = (ali.Apttus_Config2__AttributeValueId__r.APTS_Number_of_months__c != null && ali.Apttus_Config2__AttributeValueId__r.APTS_Number_of_months__c != '0') ? true : false;
                mapServiceActiveWarranty.put(ali.APTS_Is_Primary_L1_Asset__c, activeWarranty);
                mapServiceActiveWarrantyDate.put(ali.APTS_Is_Primary_L1_Asset__c, Date.valueOf(ali.APTS_Is_Primary_L1_Asset__r.Apttus_Config2__OriginalStartDate__c));
            }
        }
        
   }
   // v1.4 - END

   
   @TestVisible
   private RTR_LAE_Staging_Data__c createStagingRecord(RTR_LAE_Transaction_Data__c transData){
        RTR_LAE_Staging_Data__c newStageData = new RTR_LAE_Staging_Data__c();
        newStageData.APTS_Asset_Line_Item__c = transData.APTS_Asset_Line_Item__c;
        newStageData.APTS_Business_Transaction_Type__c = transData.APTS_Business_Transaction_Type__c;
        newStageData.APTS_Contractual_Purchase__c = transData.APTS_Contractual_Purchase__c;
        return newStageData;
    }
    
}