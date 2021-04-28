/*************************************************************
@Name: APTS_AcceptOrder
@Author: Mahesh Chilaka
@CreateDate: 23-08-2019
@Description: Invoked from Transaction Data detail page for re-initiating. DFT2C-858
@Test Class : Covered by APTS_StagingDataJobTest
@UsedBy: Re-interface the transaction data record.
******************************************************************/
public with sharing class APTS_LAE_RAR_Reinterface {

    public PageReference reInterface(){
        PageReference pageRef = null;
        Id transId = ApexPages.currentPage().getParameters().get('ID');             
        Set<String> classNames = new Set<String>{'APTS_StagingDataJob'};
        Set<String> setChargeType = new Set<String>{'Service Fee', 'Rental Fee', 'Sales Price'};
        String lineType = 'Product/Service';
        Set<Id> setAssetId = new Set<Id>();
        Set<Id> setTransDataIds = new Set<Id>();
        Set<String> setSchBusinesstype = new Set<String>();
                
        List<RTR_LAE_Transaction_Data__c> lstTransData = [SELECT Id, APTS_Asset_Line_Item__c, APTS_Asset_Processed__c, APTS_Business_Transaction_Type__c,
                                                                Error_in_Processing__c 
                                                        FROM RTR_LAE_Transaction_Data__c  WHERE Id =: transId AND 
                                                            APTS_Asset_Line_Item__r.Apttus_Config2__ChargeType__c IN : setChargeType];

        for(RTR_LAE_Transaction_Data__c transData : lstTransData){
            transData.APTS_Asset_Processed__c = false;
            transData.Error_in_Processing__c = false;
            transData.Error_Description__c = null;
            
            //setSchBusinesstype.add(transData.APTS_Business_Transaction_Type__c);
            //setAssetId.add(transData.APTS_Asset_Line_Item__c);
            //setTransDataIds.add(transData.Id);
        }
        if(!lstTransData.isEmpty()) { update lstTransData; }
             
        
      /*  if(!isJobRunning(classNames) && !setAssetId.isEmpty()){ 
             List<Apttus_Config2__AssetLineItem__c> lstAssetLineItem = fetchAssetLineItem(setChargeType, lineType, setAssetId);

             APTS_StagingDataJob stagingJob = new APTS_StagingDataJob(false);
             stagingJob.setTransDataIds = setTransDataIds;
             stagingJob.executeExt(lstAssetLineItem, true,setSchBusinesstype);           
        }*/

        pageRef = new PageReference('/'+transId);
        pageRef.setRedirect(true);
        return pageRef;
   }

   /* This method will return true if there no jobs running */
    public static boolean isJobRunning(Set<String> setClassNames){

        Set<String> status = new Set<String>{'Completed','Failed','Aborted'};  
        List<AsyncApexJob> jobsInQueue = [Select id, apexclass.name, JobType, Status from AsyncApexJob where apexclass.name IN: setClassNames and Status Not IN: status];
            
        if(!jobsInQueue.isEmpty()){ 
            return true;
        }

        return false;
    }


    /* This method will return true if there no jobs running */
    public static List<Apttus_Config2__AssetLineItem__c> fetchAssetLineItem(Set<String> setChargeType, String lineType, Set<Id> setAssetId){

        return [SELECT Id, APTS_Is_Primary_L1_Asset__c,
                            Apttus_Config2__ChargeType__c,
                            APTS_Contract_Type__c,
                            APTS_Type_Of_Contract__c,
                            APTS_Asset_Validaton_Error__c,
                            APTS_Calculated_Base_Extended_Price__c,
                            APTS_MigrationDate__c,
                            Apttus_Config2__OriginalStartDate__c,
                            Apttus_Config2__Quantity__c,
                            Apttus_Config2__BasePrice__c,
                            Apttus_Config2__EndDate__c,
                            Apttus_Config2__BillingStartDate__c,
                            Apttus_Config2__StartDate__c,
                            Apttus_CMConfig__AgreementId__r.Apttus__Agreement_Number__c,  
                            Apttus_Config2__AccountId__r.SAP_Customer_ID__c,
                            Apttus_Config2__AccountId__r.Mini_Company_Code__c,
                            APTS_Physical_Asset__r.InitialActivationDate__c,
                            APTS_Physical_Asset__c,
                            APTS_Is_Primary_L1_Line__c,
                            APTS_Is_Primary_L1_Asset__r.APTS_Physical_Asset__r.InitialActivationDate__c                                                                     
                    FROM Apttus_Config2__AssetLineItem__c
                    WHERE Apttus_Config2__ChargeType__c IN : setChargeType AND 
                            Apttus_Config2__LineType__c =: lineType AND 
                            Id IN: setAssetId];
    }
}