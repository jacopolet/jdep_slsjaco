/*******************************************************************************************
Name            : APTS_RebateDefinitionTriggerHandler
Created By      : Santosh Kumar
Created Date    : 22 May 2018
Description     : Handler class of APTS_RebateDefinitionTrigger.
Test Class      : APTS_RebateDefinitionTriggerHandlerTest
*********************************************************************************************/

public with sharing class APTS_RebateDefinitionTriggerHandler implements ITriggerHandler 
{
    private static boolean triggerDisabled = false;
    private static String AGREEMENTOBJ = 'Apttus__APTS_Agreement__c';
    public Boolean isDisabled() {

        return triggerDisabled;
    }

    public void beforeInsert(List<SObject> newItems) {
        List<String> lstLang = new List<String>();
        for(APTS_RebateDefiniation__c tmp : (List<APTS_RebateDefiniation__c>) newItems){
            if(tmp.APTS_Agreement_Language__c != NULL){
                lstLang.add(tmp.APTS_Agreement_Language__c);
            }
        }
        if(lstLang.size() > 0){
            APTS_LanguageTranslator.translateLanguage(newItems, 'APTS_RebateDefiniation__c', lstLang);
        }
    }

    public void afterInsert(List<SObject> newList, Map<Id, SObject> newItems) {
        Set<Id> aggIdset = new Set<Id>();
        Map<Id, Apttus__APTS_Agreement__c> aggMaptUpdate = new Map<Id, Apttus__APTS_Agreement__c>();
        try{
            for(APTS_RebateDefiniation__c oRebdef : (List<APTS_RebateDefiniation__c>)newList) {
                aggIdset.add(oRebdef.APTS_Agreement__c);
            }

            if(!aggIdset.isEmpty()) {
                for(Apttus__APTS_Agreement__c oAgg : [select id,APTS_IncentivesRelatedDetails__c from Apttus__APTS_Agreement__c where id IN: aggIdset]) {
                    aggMaptUpdate.put(oAgg.Id, oAgg);
                }
            }
            if(!aggMaptUpdate.isEmpty()) {
                aggMaptUpdate = prepareAggMap(newList, aggMaptUpdate); 
            }
            system.debug('aggMaptUpdate=='+aggMaptUpdate);
            if(!aggMaptUpdate.isEmpty()) {
             DescribeSObjectResult objResult = APTS_OTCUtil.getsObjectAccess(AGREEMENTOBJ);
             if(objResult != null && objResult.isUpdateable())
               {
                update aggMaptUpdate.values();
                }
            }
        }Catch(Exception e) {
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'RebateDefinition',newList[0].Id ,'CLM',false,false,null, true);
        }
    }

    public void beforeUpdate(List<SObject> newList, Map<Id, SObject> newItems,List<SObject> oldList, Map<Id, SObject> oldItems) {
        /*List<String> lstLang = new List<String>();
        for(APTS_RebateDefiniation__c tmp : (List<APTS_RebateDefiniation__c>) newList){
            if(tmp.APTS_Agreement_Language__c != NULL){
                lstLang.add(tmp.APTS_Agreement_Language__c);
            }
        }
        if(lstLang.size() > 0){
            APTS_LanguageTranslator.translateLanguage(newList, 'APTS_RebateDefiniation__c', lstLang);
        }*/
    }   

    public void afterUpdate(List<SObject> newList, Map<Id, SObject> newItems,List<SObject> oldList, Map<Id, SObject> oldItems) {
        updateaggfield(newList);
     
    }

    public void beforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems) {}

    public void afterDelete(List<SObject> oldList, Map<Id, SObject> oldItems) {

       updateaggfield(oldList);
    }

    public void afterUndelete(List<SObject> newList, Map<Id, SObject> newItems) {}

    public static void updateaggfield(List<SObject> objList) {

        Set<Id> aggIdset = new Set<Id>();
        Map<Id, Apttus__APTS_Agreement__c> aggMaptUpdate = new Map<Id, Apttus__APTS_Agreement__c>();
        List<APTS_RebateDefiniation__c> newVolobjlist = new List<APTS_RebateDefiniation__c>(); 
        try{
            for(APTS_RebateDefiniation__c oRebdef : (List<APTS_RebateDefiniation__c>)objList) {
                aggIdset.add(oRebdef.APTS_Agreement__c);
            }

            if(!aggIdset.isEmpty()) {
                for(Apttus__APTS_Agreement__c oAgg : [select id,APTS_IncentivesRelatedDetails__c from Apttus__APTS_Agreement__c where id IN: aggIdset]) {
                    oAgg.APTS_IncentivesRelatedDetails__c = '';
                    aggMaptUpdate.put(oAgg.Id, oAgg);
                }

                newVolobjlist = [select id,name,APTS_Agreement__c,APTS_Description__c,APTS_RebateTableTierType__c,APTS_TierMetricType__c,APTS_Volumepermachine__c from APTS_RebateDefiniation__c where APTS_Agreement__c IN: aggIdset];
            }

            if(!newVolobjlist.isEmpty() && !aggMaptUpdate.isEmpty()) {
                aggMaptUpdate = prepareAggMap(newVolobjlist, aggMaptUpdate);
            }

            system.debug('aggMaptUpdate update=='+aggMaptUpdate);
            if(!aggMaptUpdate.isEmpty()) {
            DescribeSObjectResult objResult = APTS_OTCUtil.getsObjectAccess(AGREEMENTOBJ);
             if(objResult != null && objResult.isUpdateable())
               {
                update aggMaptUpdate.values();
                }
            }
        }Catch(Exception e) {
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'RebateDefinition',objList[0].Id ,'CLM',false,false,null, true);
        }

    }    

    public static Map<Id, Apttus__APTS_Agreement__c> prepareAggMap(List<SObject> newList, Map<Id, Apttus__APTS_Agreement__c> aggMap) {

        for(APTS_RebateDefiniation__c oRebdef : (List<APTS_RebateDefiniation__c>)newList) {
           aggMap = getAggMap(aggMap, oRebdef.APTS_Agreement__c, oRebdef.Name+'|');
           if(oRebdef.APTS_RebateTableTierType__c != null) {
                aggMap = getAggMap(aggMap, oRebdef.APTS_Agreement__c, oRebdef.APTS_RebateTableTierType__c+'|');
           }
           if(oRebdef.APTS_TierMetricType__c != null) {
                aggMap = getAggMap(aggMap, oRebdef.APTS_Agreement__c, oRebdef.APTS_TierMetricType__c+'|');
           }
           if(oRebdef.APTS_Description__c != null) {
                aggMap = getAggMap(aggMap, oRebdef.APTS_Agreement__c, 'Description|');
           }system.debug('Outside oRebdef.APTS_Volumepermachine__c'+ oRebdef.APTS_Volumepermachine__c);
           if(oRebdef.APTS_Volumepermachine__c) {system.debug('inside oRebdef.APTS_Volumepermachine__c'+ oRebdef.APTS_Volumepermachine__c);
                aggMap = getAggMap(aggMap, oRebdef.APTS_Agreement__c, 'Machine|');
           }
           if(!oRebdef.APTS_Volumepermachine__c) {
                aggMap = getAggMap(aggMap, oRebdef.APTS_Agreement__c, 'Total|');
           }            
        }
        return aggMap;        
    }

    public static Map<Id, Apttus__APTS_Agreement__c> getAggMap(Map<Id, Apttus__APTS_Agreement__c> newAggMap, Id aggid, String rellistdata) {
        Apttus__APTS_Agreement__c aggmt = newAggMap.get(aggid);
        if(aggmt.APTS_IncentivesRelatedDetails__c == null || aggmt.APTS_IncentivesRelatedDetails__c == '') {
            aggmt.APTS_IncentivesRelatedDetails__c = rellistdata;
        }else if(!aggmt.APTS_IncentivesRelatedDetails__c.containsIgnoreCase(rellistdata)) {
            aggmt.APTS_IncentivesRelatedDetails__c += rellistdata;
        }
        newAggMap.put(aggmt.Id, aggmt);
        return newAggMap;
    }         
}