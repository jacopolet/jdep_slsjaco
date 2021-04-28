/**************************************************************
 * @Author: Santosh Kumar
 * @Company: Accenture
 * @Description: Handler class for APTS_IndexContractTrigger
 * @Created Date: May 3, 2018
 * @Revisions:
 *      <Name>              <Date>          <Description>
 *      jason.e.mactal      5/29/2018       Added logic for populating Non – Standard Deal (Indexation) on Agreement
 * 
 *************************************************************/
public with sharing class APTS_IndexContractTriggerHandler implements ITriggerHandler 
{
    public static final String STANDARD_INDEXATION = 'Standard Indexation';
    
    private static boolean triggerDisabled = false;
    
    private static final Set<String> assetIndexationCategories = new Set<String>{'Technical Services'};

    public Boolean isDisabled() {

        return triggerDisabled;
    }

    public void beforeInsert(List<SObject> newItems) {
        List<String> lstLang = new List<String>();
        for(APTS_Index_Contract__c tmp : (List<APTS_Index_Contract__c>) newItems){
            if(tmp.APTS_Agreement_Language__c != NULL){
                lstLang.add(tmp.APTS_Agreement_Language__c);
            }
        }
        if(lstLang.size() > 0){
            APTS_LanguageTranslator.translateLanguage(newItems, 'APTS_Index_Contract__c', lstLang);
        }
    }

    public void afterInsert(List<SObject> newList, Map<Id, SObject> newItems) {
        APTS_CLMUtil.validateLock(newList, 'APTS_Index_Contract__c');
        APTS_AgreementTriggerHandler.triggerDisabled = TRUE;
        updateNonStandardIndexation(setNonStandardIndexation(newItems),newItems,'afterInsert',null);
    }

    public void beforeUpdate(List<SObject> newList, Map<Id, SObject> newItems,List<SObject> oldList, Map<Id, SObject> oldItems) {
        List<String> lstLang = new List<String>();
        for(APTS_Index_Contract__c tmp : (List<APTS_Index_Contract__c>) newList){
            if(tmp.APTS_Agreement_Language__c != NULL){
                lstLang.add(tmp.APTS_Agreement_Language__c);
            }
        }
        if(lstLang.size() > 0){
            APTS_LanguageTranslator.translateLanguage(newList, 'APTS_Index_Contract__c', lstLang);
        }
    }   

    public void afterUpdate(List<SObject> newList, Map<Id, SObject> newItems,List<SObject> oldList, Map<Id, SObject> oldItems) {
        APTS_CLMUtil.validateLock(newList, 'APTS_Index_Contract__c');
        updateaggfield(newList, oldItems);
        updateNonStandardIndexation(setNonStandardIndexation(newItems),newItems,'afterUpdate',null);
    }


    public void beforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems) {}

    public void afterDelete(List<SObject> oldList, Map<Id, SObject> oldItems) {
        System.debug('OLD LIST========>'+(List<APTS_Index_Contract__c>) oldItems.values());
        System.debug('assetIndexationCategories========>'+assetIndexationCategories);
        Set<id> aggIdSet = getAgreementIds(oldItems);
        Map<Id,Integer> nonStandardIndexCountMap = new Map<Id,Integer>();
        System.debug('aggIdSet=========>'+aggIdSet);
        for(APTS_Index_Contract__c indexCon : [SELECT Id, APTS_Index_Type__c, APTS_Contract__c FROM APTS_Index_Contract__c WHERE APTS_Contract__c IN: aggIdSet and APTS_Indexation_Category__c IN: assetIndexationCategories and APTS_Index_Type__c='Non-Standard Indexation']){
            System.debug('indexCon=========>'+indexCon);
            if(nonStandardIndexCountMap.get(indexCon.APTS_Contract__c)==null){
                nonStandardIndexCountMap.put(indexCon.APTS_Contract__c,1);
            }else{
                nonStandardIndexCountMap.put(indexCon.APTS_Contract__c,nonStandardIndexCountMap.get(indexCon.APTS_Contract__c)+1);
            }
        }
        updateNonStandardIndexation(setNonStandardIndexation(oldItems),oldItems,'afterDelete',nonStandardIndexCountMap);
    }

    public void afterUndelete(List<SObject> newList, Map<Id, SObject> newItems) {}

    public static void updateaggfield(List<SObject> objList, Map<Id, SObject> oldItems) {

        Set<Id> aggIdset = new Set<Id>();
        Map<Id, Apttus__APTS_Agreement__c> aggMaptUpdate = new Map<Id, Apttus__APTS_Agreement__c>();
        List<APTS_Index_Contract__c> newindexconlist = new List<APTS_Index_Contract__c>(); 
        for(APTS_Index_Contract__c oindexcon : (List<APTS_Index_Contract__c>)objList) {
            if(oindexcon.APTS_Index_Type__c != ((APTS_Index_Contract__c)oldItems.get(oindexcon.Id)).APTS_Index_Type__c) {
                aggIdset.add(oindexcon.APTS_Contract__c);
            }
            
        }

        if(!aggIdset.isEmpty()) {
            for(Apttus__APTS_Agreement__c oAgg : [select id,APTS_IndexationRelatedListDetails__c from Apttus__APTS_Agreement__c where id IN: aggIdset]) {
                oAgg.APTS_IndexationRelatedListDetails__c = '';
                aggMaptUpdate.put(oAgg.Id, oAgg);
            }

            newindexconlist = [select id,APTS_Index_Type__c,APTS_Contract__c from APTS_Index_Contract__c where APTS_Contract__c IN: aggIdset];
        }


        aggMaptUpdate = prepareAggMap(newindexconlist, aggMaptUpdate);
        
        system.debug('aggMaptUpdate update=='+aggMaptUpdate);
        if(!aggMaptUpdate.isEmpty()) {
            APTS_AgreementTriggerHandler.triggerDisabled = TRUE;
            APTS_DefaultAgreementDates.triggerDisabled = TRUE;
            update aggMaptUpdate.values();
        }

    }

    public static Map<Id, Apttus__APTS_Agreement__c> prepareAggMap(List<SObject> newList, Map<Id, Apttus__APTS_Agreement__c> aggMap) {

        for(APTS_Index_Contract__c oindexcon : (List<APTS_Index_Contract__c>)newList) {
            if(oindexcon.APTS_Index_Type__c == 'Standard Indexation') {
                aggMap = getAggMap(aggMap, oindexcon.APTS_Contract__c, 'StandardIndexation|');        
            }
            if(oindexcon.APTS_Index_Type__c == 'Non-Standard Indexation') {
                aggMap = getAggMap(aggMap, oindexcon.APTS_Contract__c, 'NonStandardIndexation|');        
            }
            if(oindexcon.APTS_Index_Type__c == 'No Indexation') {
                aggMap = getAggMap(aggMap, oindexcon.APTS_Contract__c, 'NoIndexation|');        
            }                        
        }
        return aggMap;        
    }

    public static Map<Id, Apttus__APTS_Agreement__c> getAggMap(Map<Id, Apttus__APTS_Agreement__c> newAggMap, Id aggid, String rellistdata) {
        Apttus__APTS_Agreement__c aggmt = newAggMap.get(aggid);
        if(aggmt.APTS_IndexationRelatedListDetails__c == null || aggmt.APTS_IndexationRelatedListDetails__c == '') {
            aggmt.APTS_IndexationRelatedListDetails__c = rellistdata;
        }else if(!aggmt.APTS_IndexationRelatedListDetails__c.containsIgnoreCase(rellistdata)) {
            aggmt.APTS_IndexationRelatedListDetails__c += rellistdata;
        }
        newAggMap.put(aggmt.Id, aggmt);
        return newAggMap;
    }
    
    /*@methodName - setNonStandardIndexation
    * @description - set Non – Standard Deal (Indexation) value per agreement
    * @author - jason.e.mactal
    * @param - Map<Id, SObject>
    * @return - Map<id,boolean>
    */
    public Map<id,boolean> setNonStandardIndexation(Map<Id, SObject> items){
        Map<id,boolean> aggNonStandardIndexationMap = new Map<id,boolean>();
        Set<id> aggIdSet = getAgreementIds(items);
        
        for(APTS_Index_Contract__c oIndexCon : [SELECT Id, APTS_Index_Type__c, APTS_Contract__c FROM APTS_Index_Contract__c WHERE APTS_Contract__c IN: aggIdSet]){
            if(!STANDARD_INDEXATION.equals(oIndexCon.APTS_Index_Type__c)){
                aggNonStandardIndexationMap.put(oIndexCon.APTS_Contract__c,true);
            }
            else if(aggNonStandardIndexationMap.get(oIndexCon.APTS_Contract__c)!=true){
                aggNonStandardIndexationMap.put(oIndexCon.APTS_Contract__c,false);
            }
        }
        return aggNonStandardIndexationMap;
    }

    /*@methodName - updateNonStandardIndexation
    * @description - update Non – Standard Deal (Indexation) value per agreement
    * @author - jason.e.mactal
    * @param - Map<Id, SObject>
    * @return - Map<id,boolean>
    */    
    public void updateNonStandardIndexation(Map<id,boolean> aggNonStandardIndexationMap,Map<id,sObject> indexContractRecs,String triggerEvent,Map<Id,Integer> nonIndexTotalCountMap){
        try{
            List<Apttus__APTS_Agreement__c> agreementList = [SELECT Id, APTS_Non_Standard_Deal_Indexation__c,APTS_Non_Standard_Index_Execution_Date__c FROM Apttus__APTS_Agreement__c WHERE ID IN: aggNonStandardIndexationMap.keySet()];
            Map<Id,Apttus__APTS_Agreement__c> agreementListUpdateMap = new Map<Id,Apttus__APTS_Agreement__c>();
            Map<Id,Date> nonStandardIndexExecutionDateMap = new Map<Id,Date>();
            Map<Id,Integer> nonStandardIndexCountMap = new Map<Id,Integer>();
            for(APTS_Index_Contract__c indexcon : (List<APTS_Index_Contract__c>)indexContractRecs.values()) {
                if(indexcon.APTS_Index_Type__c!=null &&
                    indexcon.APTS_Index_Type__c.equalsIgnoreCase('Non-Standard Indexation') &&
                    indexcon.APTS_Start_Date__c!=null && assetIndexationCategories.contains(indexcon.APTS_Indexation_Category__c)){ 
                    if(nonStandardIndexExecutionDateMap.get(indexcon.APTS_Contract__c)==null){
                        nonStandardIndexExecutionDateMap.put(indexcon.APTS_Contract__c,indexcon.APTS_Start_Date__c);
                    }
                    /*if(triggerEvent!=null && triggerEvent.equalsIgnoreCase('afterDelete')){
                        if(nonStandardIndexCountMap.get(indexcon.APTS_Contract__c)==null){
                            nonStandardIndexCountMap.put(indexcon.APTS_Contract__c,1);
                        }else{
                            nonStandardIndexCountMap.put(indexcon.APTS_Contract__c,nonStandardIndexCountMap.get(indexcon.APTS_Contract__c)+1);
                        }
                    }*/
                }
            }
            for(APTS_Index_Contract__c indexcon : (List<APTS_Index_Contract__c>)indexContractRecs.values()) {
                if(triggerEvent!=null && 
                    triggerEvent.equalsIgnoreCase('afterDelete') && 
                    nonIndexTotalCountMap!=null && 
                    (nonIndexTotalCountMap.isEmpty() || (!nonIndexTotalCountMap.isEmpty() && nonIndexTotalCountMap.get(indexcon.APTS_Contract__c)==null))){
                    if(nonStandardIndexExecutionDateMap.keySet().contains(indexcon.APTS_Contract__c)){
                        if(agreementListUpdateMap.get(indexcon.APTS_Contract__c)==null){
                            Apttus__APTS_Agreement__c oAgg = new Apttus__APTS_Agreement__c(id=indexcon.APTS_Contract__c);
                            oAgg.APTS_Non_Standard_Index_Execution_Date__c=null;
                            agreementListUpdateMap.put(oAgg.id,oAgg);
                        }else{
                            Apttus__APTS_Agreement__c oAgg = agreementListUpdateMap.get(indexcon.APTS_Contract__c);
                            oAgg.APTS_Non_Standard_Index_Execution_Date__c=null;
                            agreementListUpdateMap.put(oAgg.id,oAgg);
                        }
                        System.debug('agreementListUpdateMap===INSIDE======>'+agreementListUpdateMap);
                    }
                }
            }
            System.debug('nonIndexTotalCountMap==========>'+nonIndexTotalCountMap);
            System.debug('nonStandardIndexExecutionDateMap==========>'+nonStandardIndexExecutionDateMap);
            System.debug('triggerEvent=========>'+triggerEvent);
            if(nonIndexTotalCountMap!=null){
                System.debug('IS EMPTY==========>'+nonIndexTotalCountMap.isEmpty());
            }
            for(Apttus__APTS_Agreement__c oAgg: agreementList){
                //check if values in agreement is different
                if(oAgg.APTS_Non_Standard_Deal_Indexation__c != aggNonStandardIndexationMap.get(oAgg.id)){
                    if(agreementListUpdateMap.get(oAgg.id)==null){
                        oAgg.APTS_Non_Standard_Deal_Indexation__c = aggNonStandardIndexationMap.get(oAgg.id);
                        agreementListUpdateMap.put(oAgg.id,oAgg);
                    }else{
                        Apttus__APTS_Agreement__c oAgg1 = agreementListUpdateMap.get(oAgg.id);
                        oAgg1.APTS_Non_Standard_Deal_Indexation__c = aggNonStandardIndexationMap.get(oAgg.id);
                        agreementListUpdateMap.put(oAgg1.id,oAgg1);
                    }
                }
                if(triggerEvent!=null && (triggerEvent.equalsIgnoreCase('afterUpdate')||triggerEvent.equalsIgnoreCase('afterInsert'))){
                    if(nonStandardIndexExecutionDateMap.get(oAgg.id)!=null){
                        if(agreementListUpdateMap.get(oAgg.id)==null){
                            oAgg.APTS_Non_Standard_Index_Execution_Date__c = nonStandardIndexExecutionDateMap.get(oAgg.id);
                            agreementListUpdateMap.put(oAgg.id,oAgg);
                        }else{
                            Apttus__APTS_Agreement__c oAgg1 = agreementListUpdateMap.get(oAgg.id);
                            oAgg1.APTS_Non_Standard_Index_Execution_Date__c = nonStandardIndexExecutionDateMap.get(oAgg.id);
                            agreementListUpdateMap.put(oAgg1.id,oAgg1);
                        }
                    }
                }
            }
            System.debug('agreementListUpdateMap==========>'+agreementListUpdateMap);
            if(!agreementListUpdateMap.isEmpty()){
                APTS_AgreementTriggerHandler.triggerDisabled = TRUE;
                APTS_DefaultAgreementDates.triggerDisabled = TRUE;
                database.update(agreementListUpdateMap.values());
            }
        } catch(Exception e){
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Index Contract','','CPQ',false,true,'cpqerror@accenture.com',true);             
        }  
        
        
    }
    /*@methodName - getAgreementIds
    * @description - get agreement ids from Index contracts
    * @author - jason.e.mactal
    * @param - Map<Id, SObject>
    * @return - Set<id>
    */
    public Set<id> getAgreementIds (Map<Id, SObject> items){
        Set<id> aggIdSet = new Set<id>();
        for(APTS_Index_Contract__c oIndexCon : (List<APTS_Index_Contract__c>)items.values()){
            aggIdSet.add(oIndexCon.APTS_Contract__c);
        }
        return aggIdSet;
    }
    
}