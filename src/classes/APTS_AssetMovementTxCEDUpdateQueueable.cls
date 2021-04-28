/*************************************************************
@Name: APTS_AssetMovementTxCEDUpdateQueueable
@Author: Mahesh Chilaka
@CreateDate: 20-01-2020
@Description: Queueable class for updating Contract Effective Date on Transaction records for A005 and B005. DQ - 368.
@UsedBy: 
******************************************************************/
/*
@Version History : v1.0 - created
                   v1.1 - DQ-3607 - Added new method retrieving data and updated the logic queueable chain job.

*/
public with sharing class APTS_AssetMovementTxCEDUpdateQueueable implements Queueable {
    

    public void execute(QueueableContext context) {
       
        Set<String> setBusinessType = new Set<String>{'A005','B005'};
        Set<Id> setAssetPrimaryL1Id = new Set<Id>();
        Set<String> setCurrentAgreeNumber = new Set<String>();
        Map<Id, RTR_LAE_Transaction_Data__c> mapTransData = new Map<Id, RTR_LAE_Transaction_Data__c>();
        Map<String, Date> mapAssetCurrentAgreementStartDate = new Map<String, Date>(); 
        Map<String, Date> mapAssetPreviousAgreementEndDate = new Map<String, Date>();        
        Id primaryL1Id ;
        String formulaChargeType = '', agreementNumber = '';
        Integer batchSize = APTS_RtRSchedulerComponentController.getStagingBatchSize();
        Datetime dtCurrentTime = Test.IsRunningTest() ? System.Now().addMinutes(5) : System.Now().addMinutes(-5);

        try {
           // v1.1 - START
            for(RTR_LAE_Transaction_Data__c transData : getTransactions(setBusinessType, dtCurrentTime, batchSize)){
                if(transData.APTS_Asset_Line_Item__c != null){
                    primaryL1Id = transData.APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__c != null ? transData.APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__c : transData.APTS_Asset_Line_Item__c;                                                    
                    agreementNumber = transData.APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__c != null ? transData.APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__r.Apttus_CMConfig__AgreementId__r.Apttus__Agreement_Number__c : transData.APTS_Asset_Line_Item__r.Apttus_CMConfig__AgreementId__r.Apttus__Agreement_Number__c;
                    setAssetPrimaryL1Id.add(primaryL1Id);
                    mapTransData.put(transData.Id, transData);
                    setCurrentAgreeNumber.add(agreementNumber);    
                }       

            }
            // v1.1 - END

           // APTS_StagingDataJob sdj = new APTS_StagingDataJob(false);
              APTS_ProcessStaging sdj = new APTS_ProcessStaging();
            
            if(setAssetPrimaryL1Id != null){
                sdj.setALIAgreeNumber.addALL(setCurrentAgreeNumber);
                sdj.fetchAssetPreviousAgreement(setAssetPrimaryL1Id, false);
                sdj.fetchAssetPreviousContractStartEndDates(setAssetPrimaryL1Id); 
            }

            if(sdj.mapAssetCurrentAgreementStartDate != null) {           
                mapAssetCurrentAgreementStartDate.putAll(sdj.mapAssetCurrentAgreementStartDate);
            }
            if(sdj.mapAssetPreviousAgreementEndDate != null) {  
                mapAssetPreviousAgreementEndDate.putAll(sdj.mapAssetPreviousAgreementEndDate);
            }

            system.debug(' mapAssetCurrentAgreementStartDate '+ mapAssetCurrentAgreementStartDate);
            system.debug(' mapAssetPreviousAgreementEndDate '+ mapAssetPreviousAgreementEndDate);
        
            for(RTR_LAE_Transaction_Data__c transData : mapTransData.Values() ){

                primaryL1Id = transData.APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__c != null ? transData.APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__c : transData.APTS_Asset_Line_Item__c; 
                formulaChargeType = primaryL1ID + ';' + transData.APTS_Asset_Line_Item__r.Apttus_Config2__ChargeType__c;

                if(transData.APTS_Business_Transaction_Type__c == 'A005'){
                    transData.APTS_Contract_Effective_Date__c = mapAssetPreviousAgreementEndDate.containsKey(formulaChargeType) ? mapAssetPreviousAgreementEndDate.get(formulaChargeType) : System.Today();            
                } else if(transData.APTS_Business_Transaction_Type__c == 'B005'){
                    transData.APTS_Contract_Effective_Date__c = mapAssetCurrentAgreementStartDate.containsKey(formulaChargeType) ? mapAssetCurrentAgreementStartDate.get(formulaChargeType) : System.Today().addDays(1);
                }
            }

            if(!mapTransData.isEmpty()){
                
                update mapTransData.values(); 
            }
        
            // v1.1 - START
            if(!getTransactions(setBusinessType, dtCurrentTime, batchSize).isEmpty() && !Test.IsRunningTest()){
                System.enqueueJob(new APTS_AssetMovementTxCEDUpdateQueueable());
            }
            // v1.1 - END
        }
        catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString() , 'APTS_AssetMovementTxCEDUpdateQueueable', null, 'CLM', false, false, null, true); }
    
    }

    /*************************************************************
    @Descriptio: This method will return list of 005 transaction records
    @parameters: Set<String>, DateTime, Integer
    @returns: List<Transaction>
    **************************************************************/
    public List<RTR_LAE_Transaction_Data__c> getTransactions(Set<String> setBusinessType, Datetime dtCurrentTime, Integer batchSize){
      return [SELECT Id, APTS_Asset_Line_Item__c, APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__c, 
                                                                APTS_Contract_Effective_Date__c, APTS_Asset_Line_Item__r.Apttus_Config2__ChargeType__c,
                                                                APTS_Business_Transaction_Type__c , APTS_Asset_Line_Item__r.Apttus_CMConfig__AgreementId__r.Apttus__Agreement_Number__c,
                                                                APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__r.Apttus_CMConfig__AgreementId__r.Apttus__Agreement_Number__c
                                                        FROM RTR_LAE_Transaction_Data__c 
                                                        WHERE APTS_Contract_Effective_Date__c = null AND
                                                                APTS_Business_Transaction_Type__c IN: setBusinessType AND
                                                                Createddate < : dtCurrentTime ORDER BY Createddate LIMIT: batchSize];
    }

}