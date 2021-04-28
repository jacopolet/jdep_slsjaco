/*******************************************************************************************
Name            : APTS_AgreementPODetailsTriggerHandler
Created By      : Shanmuga Prasath
Created Date    : 08/06/2018
Description     : Handler class of Agreement_PO_Details trigger 'APTS_AgreementPODetailsTrigger'.
Version history : 
*********************************************************************************************/
public with sharing class APTS_AgreementPODetailsTriggerHandler implements ITriggerHandler{
    
    /* Check custom setting for agreement trigger activation. */
    public Boolean isDisabled(){
        try{
            return TriggerSettings__c.getInstance().APTS_AgreementPODetails__c == true ? false : true;
        }catch(exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString() , 'Agreement PO Details', null, 'CLM', false, false, null, true);return true;}
    }
    
    /* After agreement is updated. */
    public void afterUpdate(List<SObject> newList, Map<Id, SObject> mapPOAgreements, List<SObject> oldList, Map<Id, SObject> mapOldPOAgreements){
        /*try{
            Map<Id, Apttus_Config2__AssetLineItem__c> phyAssetIdToALIMap = new Map<Id, Apttus_Config2__AssetLineItem__c>();
            Map<Id, APTS_Agreement_PO_Details__c> agrIdToPODetailsMap = new Map<Id, APTS_Agreement_PO_Details__c>();
            List<PhysicalAsset__c> physicalAssetUpdateList = new List<PhysicalAsset__c>();
            Map<Id, APTS_Agreement_PO_Details__c> oldRecMap = (Map<Id, APTS_Agreement_PO_Details__c>) mapOldPOAgreements;
            Map<Id, PhysicalAsset__c> physicalAssetMap = new Map<Id, PhysicalAsset__c>();
            
            for(APTS_Agreement_PO_Details__c agreementPODetails : (List<APTS_Agreement_PO_Details__c>)newList){
                if(agreementPODetails.APTS_PO_Number_Required__c != oldRecMap.get(agreementPODetails.Id).APTS_PO_Number_Required__c || agreementPODetails.APTS_PO_Number_Type__c != oldRecMap.get(agreementPODetails.Id).APTS_PO_Number_Type__c || agreementPODetails.APTS_PO_Number__c != oldRecMap.get(agreementPODetails.Id).APTS_PO_Number__c){
                    agrIdToPODetailsMap.put(agreementPODetails.APTS_Agreement__c, agreementPODetails);
                }
            }
            
            if(agrIdToPODetailsMap.size() > 0){
                // PI fix # 190262 
                for(Apttus_Config2__AssetLineItem__c aLI : [SELECT Id, Name, APTS_Physical_Asset__c, Apttus_CMConfig__AgreementId__c FROM Apttus_Config2__AssetLineItem__c WHERE Apttus_CMConfig__AgreementId__c IN: agrIdToPODetailsMap.keySet() AND APTS_Physical_Asset__c != null]){
                    phyAssetIdToALIMap.put(aLI.APTS_Physical_Asset__c, aLI);
                }
                // PI fix # 190262 
                for(PhysicalAsset__c physicalAsset : [SELECT Id, RecordTypeId, PONumberMachines__c, PONumberRequiredMachines__c, PONumberTypeMachines__c, PONumberServices__c, PONumberRequiredServices__c, PONumberTypeServices__c FROM PhysicalAsset__c WHERE Id IN: phyAssetIdToALIMap.keySet()]){
                    APTS_Agreement_PO_Details__c poDetails = agrIdToPODetailsMap.get(phyAssetIdToALIMap.get(physicalAsset.Id).Apttus_CMConfig__AgreementId__c);
                   if(poDetails == null)
                   {
                     podetails = agrIdToPODetailsMap.get(phyAssetIdToALIMap.get(physicalAsset.Id).APTS_relatedlist_agreement__c);
                   }
                    if(physicalAsset.RecordTypeId != null && physicalAsset.RecordTypeId == Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get('Machine').getRecordTypeId()){
                        if(poDetails.APTS_PO_Number__c != null){
                            physicalAsset.PONumberMachines__c = poDetails.APTS_PO_Number__c;
                        }
                        if(poDetails.APTS_PO_Number_Required__c != null){
                            physicalAsset.PONumberRequiredMachines__c = poDetails.APTS_PO_Number_Required__c;
                        }
                        if( poDetails.APTS_PO_Number_Type__c != null){
                            physicalAsset.PONumberTypeMachines__c = poDetails.APTS_PO_Number_Type__c;
                        }
                        physicalAssetUpdateList.add(physicalAsset);
                    }else if(physicalAsset.RecordTypeId != null && physicalAsset.RecordTypeId == Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get('Option').getRecordTypeId()){
                        if(poDetails.APTS_PO_Number__c != null){
                            physicalAsset.PONumberServices__c = poDetails.APTS_PO_Number__c;
                        }
                        if(poDetails.APTS_PO_Number_Required__c != null){
                            physicalAsset.PONumberRequiredServices__c = poDetails.APTS_PO_Number_Required__c;
                        }
                        if( poDetails.APTS_PO_Number_Type__c != null){
                            physicalAsset.PONumberTypeServices__c = poDetails.APTS_PO_Number_Type__c;
                        }
                        physicalAssetUpdateList.add(physicalAsset);
                    }
                }
                
                Database.Update(physicalAssetUpdateList, false);
            }
        }
        catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'APEX', ex.getStackTraceString() ,'Agreement PO Details', null,'CLM',false,false, null, true);} */
        
        //try
        {
            Map<ID, Apttus__APTS_Agreement__c> agreementsToUpdateMap = new Map<ID, Apttus__APTS_Agreement__c>();
            for(APTS_Agreement_PO_Details__c agreementPODetailsSO : (List<APTS_Agreement_PO_Details__c>)newList)
            {
                if(agreementPODetailsSO.APTS_Agreement__c != null)
                {
                    agreementsToUpdateMap.put(agreementPODetailsSO.APTS_Agreement__c, new Apttus__APTS_Agreement__c(ID = agreementPODetailsSO.APTS_Agreement__c, APTS_PO_Details_Changed__c = true));
                }    
            }
            if(agreementsToUpdateMap.size() > 0)
            {
                update agreementsToUpdateMap.values();
            }
        }
        //catch(Exception ex)
        {
        //    APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'APEX', ex.getStackTraceString()+' Message:'+ex.getMessage() ,'Agreement PO Details', null,'CLM',false,false, null, true);
        }
    }

    /* Before inserting agreement. */
    public void beforeInsert(List<SObject> newItems){}

    /* Before record updation. */
    public void beforeUpdate(List<SObject> newList, Map<Id, SObject> newItems,
    List<SObject> oldList, Map<Id, SObject> oldItems){}

    /* Before deleting agreement records. */
    public void beforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems){}

    /* After inserting agreement records. */
    public void afterInsert(List<SObject> newList, Map<Id, SObject> newItems){}

    /* After deleting agreement records. */
    public void afterDelete(List<SObject> oldList, Map<Id, SObject> oldItems){}

     /* After undeleting agreement records. */
    public void afterUndelete(List<SObject> newList, Map<Id, SObject> newItems){}
}