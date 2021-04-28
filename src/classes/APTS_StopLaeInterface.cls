/*************************************************************
@Name: APTS_StopLaeInterface
@Author: Shahul Hameed
@CreateDate: 17-12-2021
@Description: Invoked from Transaction Data detail page to stop interface 
@UsedBy: Button to stop the transaction data record to interface with lae.
******************************************************************/
public with sharing class APTS_StopLaeInterface{

public PageReference StopLaeInterface(){
        PageReference pageRef = null;
        Id transId = ApexPages.currentPage().getParameters().get('ID');             
        Set<String> classNames = new Set<String>{'APTS_StagingDataJob'};
        Set<String> setChargeType = new Set<String>{'Service Fee', 'Rental Fee', 'Sales Price'};
        String lineType = 'Product/Service';
        Set<Id> setAssetId = new Set<Id>();
        Set<Id> setTransDataIds = new Set<Id>();
        Set<String> setSchBusinesstype = new Set<String>();
        list<Apttus_Config2__AssetLineItem__c> finalassetlist= new list<Apttus_Config2__AssetLineItem__c>();
                
        List<RTR_LAE_Transaction_Data__c> lstTransData = [SELECT Id, APTS_Asset_Line_Item__c, APTS_Asset_Processed__c, APTS_Business_Transaction_Type__c,
                                                                Error_in_Processing__c 
                                                        FROM RTR_LAE_Transaction_Data__c  WHERE Id =: transId AND 
                                                            APTS_Asset_Line_Item__r.Apttus_Config2__ChargeType__c IN : setChargeType];

        for(RTR_LAE_Transaction_Data__c transData : lstTransData){
            transData.APTS_Asset_Processed__c = true;
            transData.Error_in_Processing__c = false;
            setAssetId.add(transData.APTS_Asset_Line_Item__c);
        }
        if(!lstTransData.isEmpty()) { update lstTransData; }
        
        for(Apttus_Config2__AssetLineItem__c ali:[select id,APTS_Stop_RtR_Transactions_from__c from Apttus_Config2__AssetLineItem__c where id=:setAssetId]){
        
        ali.APTS_Stop_RtR_Transactions_from__c=system.today()-1;
        finalassetlist.add(ali);
        }
        if(!finalassetlist.isEmpty()) {
         APTS_AssetLineItemTriggerHandler.isSkipAssetlineitemTrigger = true;
         update finalassetlist;
         APTS_AssetLineItemTriggerHandler.isSkipAssetlineitemTrigger = false;
         }    
        pageRef = new PageReference('/'+transId);
        pageRef.setRedirect(true);
        return pageRef;
   }


}