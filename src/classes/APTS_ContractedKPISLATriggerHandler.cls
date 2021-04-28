/*******************************************************************************************
Name            : APTS_ContractedKPISLATriggerHandler
Created By      : Santosh Kumar
Created Date    : 9 May 2018
Description     : Handler class of Contract KPI/SLA trigger 'APTS_ContractedKPISLATrigger'.
Test Class      : APTS_ContractedKPISLATriggerHandlerTest
*********************************************************************************************/


public with sharing class APTS_ContractedKPISLATriggerHandler  implements ITriggerHandler
{
    private static boolean triggerDisabled = false;

    public Boolean isDisabled() {

        return triggerDisabled;
    }

    public void beforeInsert(List<SObject> newItems) {
    
            Set<Id> agreeSet = new Set<Id>();
            List<Contracted_kpi_sla__c> lstNewContractedKPI = (List<Contracted_kpi_sla__c>)newItems;
            
            Set<String> KpiTypeset = new Set<String>();
            for(Contracted_kpi_sla__c  contractKpiSla : (List<Contracted_kpi_sla__c>) newItems){
            agreeSet.add(contractKpiSla.kpi_contract__c);
            KpiTypeset.add(contractKpiSla.KPI_type__c);
            }
            for(Contracted_kpi_sla__c KpiSla : [SELECT Id, kpi_contract__c, KPI_type__c 
                                                FROM Contracted_kpi_sla__c 
                                                WHERE kpi_contract__c IN: agreeSet AND KPI_type__c IN: KpiTypeset]){
            lstNewContractedKPI[0].adderror('Only one Contracted KPI/SLA record for a KPI Type is allowed for an Agreement');
            }
            
            //Changes for Language Translation
            List<String> lstLang = new List<String>();
            for(Contracted_kpi_sla__c tmp : (List<Contracted_kpi_sla__c>) newItems){
                if(tmp.APTS_Agreement_Language__c != NULL){
                    lstLang.add(tmp.APTS_Agreement_Language__c);
                }
            }
            if(lstLang.size() > 0){
                APTS_LanguageTranslator.translateLanguage(newItems, 'Contracted_kpi_sla__c', lstLang);
            }
    }

    public void afterInsert(List<SObject> newList, Map<Id, SObject> newItems) {

        Set<Id> conkpislaIdset = new Set<Id>();
        Map<Id, Apttus__APTS_Agreement__c> aggMaptUpdate = new Map<Id, Apttus__APTS_Agreement__c>();
        APTS_CLMUtil.validateLock(newList, 'Contracted_kpi_sla__c');
        try{
            for(Contracted_kpi_sla__c oContKSla : (List<Contracted_kpi_sla__c>)newList) {
                conkpislaIdset.add(oContKSla.kpi_contract__c);
            }

            system.debug('conkpislaIdset=='+conkpislaIdset);
            if(!conkpislaIdset.isEmpty()) {
                for(Apttus__APTS_Agreement__c oAgg : [select id,APTS_KPISLA_RelatedList_Details__c from Apttus__APTS_Agreement__c where id IN: conkpislaIdset]) {
                    aggMaptUpdate.put(oAgg.Id, oAgg);
                }
            }  

            if(!aggMaptUpdate.isEmpty()) {
                aggMaptUpdate = prepareAggMap(newList, aggMaptUpdate);
            }
            
            system.debug('aggMaptUpdate=='+aggMaptUpdate);
            if(!aggMaptUpdate.isEmpty()) {
                update aggMaptUpdate.values();
            }
            updateAgreementField(newList);
        }Catch(Exception e) {
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'ContractedKPI/SLA',newList[0].Id ,'CLM',false,true, 'sankumar@apttus.com', true);
        }

    }

    public void beforeUpdate(List<SObject> newList, Map<Id, SObject> newItems,List<SObject> oldList, Map<Id, SObject> oldItems) {
        //Changes for Language Translation
        List<String> lstLang = new List<String>();
        for(Contracted_kpi_sla__c tmp : (List<Contracted_kpi_sla__c>) newList){
            if(tmp.APTS_Agreement_Language__c != NULL){
                lstLang.add(tmp.APTS_Agreement_Language__c);
            }
        }
        if(lstLang.size() > 0){
            APTS_LanguageTranslator.translateLanguage(newList, 'Contracted_kpi_sla__c', lstLang);
        }
    }   

    public void afterUpdate(List<SObject> newList, Map<Id, SObject> newItems,List<SObject> oldList, Map<Id, SObject> oldItems) {
    
        APTS_CLMUtil.validateLock(newList, 'Contracted_kpi_sla__c');    
        updateaggfield(newList);
        updateAgreementField(newList);
    }


    public void beforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems) {}

    public void afterDelete(List<SObject> oldList, Map<Id, SObject> oldItems) {

        updateaggfield(oldList);
        updateAgreementField(oldList);

    }

    public void afterUndelete(List<SObject> newList, Map<Id, SObject> newItems) {}

    public static void updateaggfield(List<SObject> objList) {

        Set<Id> conkpislaIdset = new Set<Id>();
        Map<Id, Apttus__APTS_Agreement__c> aggMaptUpdate = new Map<Id, Apttus__APTS_Agreement__c>();
        List<Contracted_kpi_sla__c> newConlist = new List<Contracted_kpi_sla__c>(); 
        try{
            for(Contracted_kpi_sla__c oContKSla : (List<Contracted_kpi_sla__c>)objList) {
                conkpislaIdset.add(oContKSla.kpi_contract__c);
            }

            system.debug('conkpislaIdset update=='+conkpislaIdset);
            if(!conkpislaIdset.isEmpty()) {
                for(Apttus__APTS_Agreement__c oAgg : [select id,APTS_KPISLA_RelatedList_Details__c from Apttus__APTS_Agreement__c where id IN: conkpislaIdset]) {
                    oAgg.APTS_KPISLA_RelatedList_Details__c = '';
                    aggMaptUpdate.put(oAgg.Id, oAgg);
                }

                newConlist = [select id,kpi_contract__c,kpi_frequency__c,KPI_Penalty__c,KPI_type__c,kpi_type_value__c from Contracted_kpi_sla__c where kpi_contract__c IN: conkpislaIdset];
            }

            if(!aggMaptUpdate.isEmpty()) {
                aggMaptUpdate = prepareAggMap(newConlist, aggMaptUpdate);
            }
            
            system.debug('aggMaptUpdate update=='+aggMaptUpdate);
            if(!aggMaptUpdate.isEmpty()) {
                update aggMaptUpdate.values();
            }
        }Catch(Exception e) {
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'ContractedKPISLA',objList[0].Id ,'CLM',false,true, 'sankumar@apttus.com', true);
        }

    }

    public static Map<Id, Apttus__APTS_Agreement__c> prepareAggMap(List<SObject> newList, Map<Id, Apttus__APTS_Agreement__c> aggMap) {
        for(Contracted_kpi_sla__c oContKSla : (List<Contracted_kpi_sla__c>)newList) { 
            if(oContKSla.KPI_type__c == 'Availability % per machine' && oContKSla.kpi_frequency__c == 'Monthly') {
                aggMap = getAggMap(aggMap, oContKSla.kpi_contract__c, 'MachineMonthly|');        
            }
            if(oContKSla.KPI_type__c == 'Availability % per machine' && oContKSla.kpi_frequency__c == 'Quarterly') {
                aggMap = getAggMap(aggMap, oContKSla.kpi_contract__c, 'MachineQuarterly|');
            }
            if(oContKSla.KPI_type__c == 'Availability % per machine' && oContKSla.kpi_frequency__c == 'Half-Yearly') {
                aggMap = getAggMap(aggMap, oContKSla.kpi_contract__c, 'MachineHalfyearly|');
            }
            if(oContKSla.KPI_type__c == 'Availability % per machine' && oContKSla.kpi_frequency__c == 'Yearly') {
                aggMap = getAggMap(aggMap, oContKSla.kpi_contract__c, 'MachineYearly|');
            }
            if(oContKSla.KPI_type__c == 'Availability % total' && oContKSla.kpi_frequency__c == 'Monthly') {
                aggMap = getAggMap(aggMap, oContKSla.kpi_contract__c, 'TotalMonthly|');
            }
            if(oContKSla.KPI_type__c == 'Availability % total' && oContKSla.kpi_frequency__c == 'Quarterly') {
                aggMap = getAggMap(aggMap, oContKSla.kpi_contract__c, 'TotalQuarterly|');
            }
            if(oContKSla.KPI_type__c == 'Availability % total' && oContKSla.kpi_frequency__c == 'Half-Yearly') {
                aggMap = getAggMap(aggMap, oContKSla.kpi_contract__c, 'TotalHalfyearly|');
            }
            if(oContKSla.KPI_type__c == 'Availability % total' && oContKSla.kpi_frequency__c == 'Yearly') {
                aggMap = getAggMap(aggMap, oContKSla.kpi_contract__c, 'TotalYearly|');
            }
            if(oContKSla.KPI_type__c == 'Availability % total' || oContKSla.KPI_type__c == 'Availability % per machine') {
                aggMap = getAggMap(aggMap, oContKSla.kpi_contract__c, 'TotalorMachine|');
            }
            if((oContKSla.KPI_type__c == 'Availability % total' || oContKSla.KPI_type__c == 'Availability % per machine') && oContKSla.KPI_Penalty__c == null && oContKSla.kpi_frequency__c == 'Monthly') {
                aggMap = getAggMap(aggMap, oContKSla.kpi_contract__c, 'TotalorMachineNullMonthly|');
            }
            if((oContKSla.KPI_type__c == 'Availability % total' || oContKSla.KPI_type__c == 'Availability % per machine') && oContKSla.KPI_Penalty__c == null && oContKSla.kpi_frequency__c == 'Quarterly') {
                aggMap = getAggMap(aggMap, oContKSla.kpi_contract__c, 'TotalorMachineNullQuarterly|');
            }
            if((oContKSla.KPI_type__c == 'Availability % total' || oContKSla.KPI_type__c == 'Availability % per machine') && oContKSla.KPI_Penalty__c == null && oContKSla.kpi_frequency__c == 'Half-Yearly') {
                aggMap = getAggMap(aggMap, oContKSla.kpi_contract__c, 'TotalorMachineNullHalfYearly|');
            }
            if((oContKSla.KPI_type__c == 'Availability % total' || oContKSla.KPI_type__c == 'Availability % per machine') && oContKSla.KPI_Penalty__c == null && oContKSla.kpi_frequency__c == 'Yearly') {
                aggMap = getAggMap(aggMap, oContKSla.kpi_contract__c, 'TotalorMachineNullYearly|');
            }
            if((oContKSla.KPI_type__c == 'Availability % total' || oContKSla.KPI_type__c == 'Availability % per machine') && oContKSla.KPI_Penalty__c != null && oContKSla.kpi_frequency__c == 'Quarterly') {
                aggMap = getAggMap(aggMap, oContKSla.kpi_contract__c, 'TotalorMachineAnyQuarterly|');
            }
            if((oContKSla.KPI_type__c == 'Availability % total' || oContKSla.KPI_type__c == 'Availability % per machine') && oContKSla.KPI_Penalty__c != null && oContKSla.kpi_frequency__c == 'Monthly') {
                aggMap = getAggMap(aggMap, oContKSla.kpi_contract__c, 'TotalorMachineAnyMonthly|');
            }
            if((oContKSla.KPI_type__c == 'Availability % total' || oContKSla.KPI_type__c == 'Availability % per machine') && oContKSla.KPI_Penalty__c != null && oContKSla.kpi_frequency__c == 'Half-Yearly') {
                aggMap = getAggMap(aggMap, oContKSla.kpi_contract__c, 'TotalorMachineAnyHalfYearly|');
            }
            if(oContKSla.KPI_type__c == 'Down time %' && oContKSla.kpi_frequency__c == 'Quarterly') {
                aggMap = getAggMap(aggMap, oContKSla.kpi_contract__c, 'DowntimeQuarterly|');
            }
            if(oContKSla.KPI_type__c == 'Down time %' && oContKSla.kpi_frequency__c == 'Monthly') {
                aggMap = getAggMap(aggMap, oContKSla.kpi_contract__c, 'DowntimeMonthly|');
            }
            if(oContKSla.KPI_type__c == 'Down time %' && oContKSla.kpi_frequency__c == 'Half-Yearly') {
                aggMap = getAggMap(aggMap, oContKSla.kpi_contract__c, 'DowntimeHalfyearly|');
            }
            if(oContKSla.KPI_type__c == 'Down time %' && oContKSla.kpi_frequency__c == 'Yearly') {
                aggMap = getAggMap(aggMap, oContKSla.kpi_contract__c, 'DowntimeYearly|');
            }
            if(oContKSla.KPI_type__c == 'Down time %' && oContKSla.kpi_frequency__c == 'Quarterly' && oContKSla.KPI_Penalty__c != null) {
                aggMap = getAggMap(aggMap, oContKSla.kpi_contract__c, 'DowntimeAnyQuarterly|');
            }
            if(oContKSla.KPI_type__c == 'Down time %' && oContKSla.kpi_frequency__c == 'Monthly' && oContKSla.KPI_Penalty__c != null) {
                aggMap = getAggMap(aggMap, oContKSla.kpi_contract__c, 'DowntimeAnyMonthly|');
            }
            if(oContKSla.KPI_type__c == 'Down time %' && oContKSla.kpi_frequency__c == 'Half-Yearly' && oContKSla.KPI_Penalty__c != null) {
                aggMap = getAggMap(aggMap, oContKSla.kpi_contract__c, 'DowntimeAnyHalfyearly|');
            }
            if(oContKSla.KPI_type__c == 'Down time %' && oContKSla.kpi_frequency__c == 'Yearly' && oContKSla.KPI_Penalty__c != null) {
                aggMap = getAggMap(aggMap, oContKSla.kpi_contract__c, 'DowntimeAnyYearly|');
            }
            if(oContKSla.KPI_type__c == 'Invoicing' && oContKSla.kpi_frequency__c == 'Quarterly') {
                aggMap = getAggMap(aggMap, oContKSla.kpi_contract__c, 'InvoiceQuarterly|');
            }
            if(oContKSla.KPI_type__c == 'Invoicing' && oContKSla.kpi_frequency__c == 'Monthly') {
                aggMap = getAggMap(aggMap, oContKSla.kpi_contract__c, 'InvoiceMonthly|');
            }
            if(oContKSla.KPI_type__c == 'Invoicing' && oContKSla.kpi_frequency__c == 'Half-Yearly') {
                aggMap = getAggMap(aggMap, oContKSla.kpi_contract__c, 'InvoiceHalfyearly|');
            }
            if(oContKSla.KPI_type__c == 'Invoicing' && oContKSla.kpi_frequency__c == 'Yearly') {
                aggMap = getAggMap(aggMap, oContKSla.kpi_contract__c, 'InvoiceYearly|');
            }
            if(oContKSla.KPI_type__c == 'Invoicing' && oContKSla.kpi_frequency__c == 'Quarterly' && oContKSla.KPI_Penalty__c != null) {
                aggMap = getAggMap(aggMap, oContKSla.kpi_contract__c, 'InvoiceAnyQuarterly|');
            }
            if(oContKSla.KPI_type__c == 'Invoicing' && oContKSla.kpi_frequency__c == 'Monthly' && oContKSla.KPI_Penalty__c != null) {
                aggMap = getAggMap(aggMap, oContKSla.kpi_contract__c, 'InvoiceAnyMonthly|');
            }
            if(oContKSla.KPI_type__c == 'Invoicing' && oContKSla.kpi_frequency__c == 'Yearly' && oContKSla.KPI_Penalty__c != null) {
                aggMap = getAggMap(aggMap, oContKSla.kpi_contract__c, 'InvoiceAnyYearly|');
            }

        }
        return aggMap;

    }

    public static Map<Id, Apttus__APTS_Agreement__c> getAggMap(Map<Id, Apttus__APTS_Agreement__c> newAggMap, Id aggid, String rellistdata) {
        Apttus__APTS_Agreement__c aggmt = newAggMap.get(aggid);
        if(aggmt.APTS_KPISLA_RelatedList_Details__c == null || aggmt.APTS_KPISLA_RelatedList_Details__c == '') {
            aggmt.APTS_KPISLA_RelatedList_Details__c = rellistdata;
        }else if(!aggmt.APTS_KPISLA_RelatedList_Details__c.containsIgnoreCase(rellistdata)) {
            aggmt.APTS_KPISLA_RelatedList_Details__c += rellistdata;
        }
        newAggMap.put(aggmt.Id, aggmt);
        return newAggMap;
    }
    
    /*@methodName - updateAgreementField
    * @description - update Non – Standard Deal (KPI/SLA) value per agreement
    * @author - Juhi Rawal
    * @param - List<SObject>
    * @return - void
    */   
    public void updateAgreementField(List<SObject>  listSObject){
        try{
            Set<Id> setAgreementIds = new Set<Id>();
            List<Contracted_kpi_sla__c> listContracted = (List<Contracted_kpi_sla__c>) listSObject;
            for(Contracted_kpi_sla__c oContracted: listContracted ){
                setAgreementIds.add(oContracted.kpi_contract__c );
            }
            
            Map<Id,Apttus__APTS_Agreement__c> mapAgreementUpdate = new Map<Id,Apttus__APTS_Agreement__c>();
            for(AggregateResult oResult : [select count(id)numRec,kpi_contract__c  from Contracted_kpi_sla__c where kpi_contract__c IN: setAgreementIds group by kpi_contract__c ]){
                Apttus__APTS_Agreement__c oAgr = new Apttus__APTS_Agreement__c(Id=String.valueOf(oResult.get('kpi_contract__c')));
                if(Integer.valueOf(oResult.get('numRec')) > 0){
                    oAgr.APTS_Non_Standard_Deal_KPI_SLA__c = true;
                    mapAgreementUpdate.put(oAgr.Id,oAgr);
                }   
            }        
            for(Id oId : setAgreementIds){
                if(!mapAgreementUpdate.containsKey(oId)){
                    Apttus__APTS_Agreement__c oAgr = new Apttus__APTS_Agreement__c(Id=oId);
                    oAgr.APTS_Non_Standard_Deal_KPI_SLA__c = false;
                    mapAgreementUpdate.put(oAgr.Id,oAgr);
                }
            }
            if(!mapAgreementUpdate.isEmpty()){
                update mapAgreementUpdate.values();
            } 
        } catch(Exception e){
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Contracted KPI/SLA','','CPQ',false,true,'cpqerror@accenture.com',true);             
        }  
    }
}