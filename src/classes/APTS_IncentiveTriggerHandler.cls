/**
* Class Name : APTS_IncentiveTriggerHandler 
* Description :  Handler for APTS_IncentiveTrigger
* Author : Juhi Rawal (Apttus)
* Date Created : 29th May,2018
**/
//v101 16-JAN-2018 Renuka : Defect-23024 Setting Payout Frequency in Agreement from Incentive
public with sharing class APTS_IncentiveTriggerHandler implements ITriggerHandler{
    
     
     public static final String PAYOUT_FREQUENCY= 'Apttus_CMConfig__PayoutFrequency__c';
     
     public void beforeInsert(List<SObject> newList){}

     public void beforeUpdate(List<SObject> newList, Map<Id, SObject> newItems,List<SObject> oldList, Map<Id, SObject> oldItems){}

     public void beforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems){}

    public void AfterInsert(List<SObject> newList, Map<Id, SObject> newItems){
        updateAgreementField(newList);
    }


    public void AfterUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldItems){
        updateAgreementField(newList);
    }

    public void AfterDelete(List<SObject> oldList, Map<Id, SObject> oldItems){
        updateAgreementField(oldList);
    }
    
    public void AfterUndelete(List<SObject> newList, Map<Id, SObject> newItems){}
    
    public Boolean IsDisabled(){
        return (TriggerSettings__c.getInstance().APTS_IncentiveTrigger__c == true ? false : true);
    }
    
    /*@methodName - updateAgreementField
    * @description - update Non – Standard Deal (Rebate) value per agreement
    * @author - Juhi Rawal
    * @param - List<SObject>
    * @return - void
    */   
    public void updateAgreementField(List<SObject>  listSObject){
        try{
            Set<Id> setAgreementIds = new Set<Id>();
            System.debug('setAgreementIds =====> ' + setAgreementIds );
            List<Apttus_Config2__Incentive__c> listIncentives = (List<Apttus_Config2__Incentive__c>) listSObject;
            for(Apttus_Config2__Incentive__c oIncentive: listIncentives ){
                if(String.isNotBlank(oIncentive.Apttus_CMConfig__AgreementId__c)){
                    setAgreementIds.add(oIncentive.Apttus_CMConfig__AgreementId__c);
                }
                
            }       
            
            if(setAgreementIds != null && !setAgreementIds.isEmpty()){
                Map<Id,Apttus__APTS_Agreement__c> mapAgreementUpdate = new Map<Id,Apttus__APTS_Agreement__c>();
                for(AggregateResult oResult : [select count(id)numRec,Apttus_CMConfig__AgreementId__c,Apttus_CMConfig__PayoutFrequency__c from Apttus_Config2__Incentive__c where Apttus_CMConfig__AgreementId__c IN: setAgreementIds group by Apttus_CMConfig__AgreementId__c,Apttus_CMConfig__PayoutFrequency__c ]){
                    Apttus__APTS_Agreement__c oAgr = new Apttus__APTS_Agreement__c(Id=String.valueOf(oResult.get(APTS_CPQConstants.AGREEMENT_ID)));
                    if(Integer.valueOf(oResult.get(APTS_CPQConstants.NUM_REC)) > 0){
                        oAgr.APTS_Non_Standard_Deal_Rebate__c = true;
                        System.debug('oResult==>' + oResult);
                        //v101 Starts here- Defect-23024 Setting Payout Frequency in Agreement from Incentive
                        If(String.valueOf(oResult.get(PAYOUT_FREQUENCY))!=null ){
                            oAgr.Apttus_CMConfig__PayoutFrequency__c= String.valueOf(oResult.get(PAYOUT_FREQUENCY));
                        }
                        //v101 Ends here 
                        if(String.isNotBlank(oAgr.Id)){
                            mapAgreementUpdate.put(oAgr.Id,oAgr);
                        }
                    }  
                    
                }
                
                for(Id oId : setAgreementIds){
                    if(!mapAgreementUpdate.containsKey(oId)){
                        Apttus__APTS_Agreement__c oAgr = new Apttus__APTS_Agreement__c(Id=oId);
                        oAgr.APTS_Non_Standard_Deal_Rebate__c = false;
                        if(String.isNotBlank(oAgr.Id)){
                            mapAgreementUpdate.put(oAgr.Id,oAgr);
                        }
                    }
                }
                if(!mapAgreementUpdate.isEmpty()){
                    APTS_CheckRecursive.processedSet.add('APTS_AgreementTriggerHandlerBeforeUpdate');
                    APTS_CheckRecursive.processedSet.add('APTS_AgreementTriggerHandlerAfterUpdate');
                    update mapAgreementUpdate.values();
                    APTS_CheckRecursive.processedSet.remove('APTS_AgreementTriggerHandlerBeforeUpdate');
                    APTS_CheckRecursive.processedSet.remove('APTS_AgreementTriggerHandlerAfterUpdate');
                }
            }
            
        } catch(Exception e){
            APTS_CustomLogging.createErrorLog(e.getTypeName(), APTS_CPQConstants.APEX_NAME, e.getStackTraceString() , APTS_CPQConstants.INCENTIVE, APTS_CPQConstants.EXCEPTION_ID, APTS_CPQConstants.CPQ,false,true,APTS_CPQConstants.CPQ_ERROR_EMAIL,true);             
        }  
    }
}