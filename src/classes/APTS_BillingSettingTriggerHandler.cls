/**
* Class Name : APTS_BillingSettingTriggerHandler 
* Description :  Handler for APTS_BillingSettingTrigger 
* Author : Juhi Rawal (Apttus)
* Date Created : 29th May,2018
**/
public without sharing class APTS_BillingSettingTriggerHandler implements ITriggerHandler{

    public void beforeInsert(List<SObject> newList){
        //Changes for Language Translation
        List<String> lstLang = new List<String>();
        for(APTS_Billing_Settings__c tmp : (List<APTS_Billing_Settings__c>) newList){
            if(tmp.APTS_Agreement_Language__c != NULL){
                lstLang.add(tmp.APTS_Agreement_Language__c);
            }
        }
        if(lstLang.size() > 0){
            APTS_LanguageTranslator.translateLanguage(newList, 'APTS_Billing_Settings__c', lstLang);
        }
    }

    public void beforeUpdate(List<SObject> newList, Map<Id, SObject> newItems,List<SObject> oldList, Map<Id, SObject> oldItems){
        //Changes for Language Translation
        List<String> lstLang = new List<String>();
        for(APTS_Billing_Settings__c tmp : (List<APTS_Billing_Settings__c>) newList){
            if(tmp.APTS_Agreement_Language__c != NULL){
                lstLang.add(tmp.APTS_Agreement_Language__c);
            }
        }
        if(lstLang.size() > 0){
            APTS_LanguageTranslator.translateLanguage(newList, 'APTS_Billing_Settings__c', lstLang);
        }
    }

    public void BeforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems){}

    public void AfterInsert(List<SObject> newList, Map<Id, SObject> newItems){
        APTS_CLMUtil.validateLock(newList, 'APTS_Billing_Settings__c');
        updateBillingSetting(newList);
        updateAgreementFields(newList,'insert'); 
    }

    public void AfterUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldItems){
        APTS_CLMUtil.validateLock(newList, 'APTS_Billing_Settings__c');
        updateBillingSetting(newList);
        updateAgreementFields(newList,'update');
    }

    public void AfterDelete(List<SObject> oldList, Map<Id, SObject> oldItems){
        updateAgreementFields(oldList,'delete'); 
    }
    
    public void AfterUndelete(List<SObject> newList, Map<Id, SObject> newItems){}
    
    public Boolean IsDisabled(){
        return (TriggerSettings__c.getInstance().APTS_BillingSettingTrigger__c == true ? false : true);
    }
    
    /*@methodName - updateAgreementFields
    * @description - update All Agreement fields
    * @author - Juhi Rawal
    * @param - List<SObject>
    * @return - void
    */  
    public void updateAgreementFields(List<SObject> listSObject, String operation){
        try{
            Map<Id,Apttus__APTS_Agreement__c> mapAgreementUpdate = new Map<Id,Apttus__APTS_Agreement__c>();
            for(Apttus__APTS_Agreement__c oAgr: updateAgrBillingArr(listSObject).values()){ 
                Apttus__APTS_Agreement__c oAgreement = new Apttus__APTS_Agreement__c(Id=oAgr.Id);
                oAgreement.APTS_Non_Standard_Deal_Billing_Arrears__c = oAgr.APTS_Non_Standard_Deal_Billing_Arrears__c;
                mapAgreementUpdate.put(oAgr.Id,oAgreement);
            }
            for(Apttus__APTS_Agreement__c oAgree: updateAgrPaymentMethod(listSObject).values()){
                if(mapAgreementUpdate.containsKey(oAgree.Id)){
                    Apttus__APTS_Agreement__c oAgreement = mapAgreementUpdate.get(oAgree.Id);
                    oAgreement.APTS_Non_Standard_Deal_Payment_Method__c = oAgree.APTS_Non_Standard_Deal_Payment_Method__c;
                    mapAgreementUpdate.put(oAgree.Id,oAgreement); 
                }
            } 
            for(Apttus__APTS_Agreement__c oAgree: updateAgrPaymentValue(listSObject).values()){
                if(mapAgreementUpdate.containsKey(oAgree.Id)){
                    Apttus__APTS_Agreement__c oAgreement = mapAgreementUpdate.get(oAgree.Id);
                    oAgreement.APTS_Payment_Term_Value_1__c = oAgree.APTS_Payment_Term_Value_1__c;
                    oAgreement.APTS_Payment_Term_Value_2__c = oAgree.APTS_Payment_Term_Value_2__c;
                    oAgreement.APTS_Non_Standard_Deal_Payment_Terms__c = oAgree.APTS_Non_Standard_Deal_Payment_Terms__c;
                    mapAgreementUpdate.put(oAgree.Id,oAgreement); 
                }
            }
            //Added by Santosh to update BillingPreferenceRelatedDetails long text area field in Agreement for purpose of Output Templates
            for(Apttus__APTS_Agreement__c oAgg : updateaggfield(listSObject,operation).values()) {
                if(mapAgreementUpdate.containsKey(oAgg.Id)) {
                    Apttus__APTS_Agreement__c oAgreement = mapAgreementUpdate.get(oAgg.Id);
                    oAgreement.APTS_BillingPreferenceRelatedDetails__c = oAgg.APTS_BillingPreferenceRelatedDetails__c;
                    mapAgreementUpdate.put(oAgg.Id,oAgreement);
                } else {
                    mapAgreementUpdate.put(oAgg.Id,oAgg);
                }
            }
            //End of Santosh code
            
            if(!mapAgreementUpdate.isEmpty()) update mapAgreementUpdate.values();
        } catch(Exception e){
        /*** PI fix # 190321 & 190381****/
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Billing Setting','','CPQ',false,false,null,true);             
        }     
    }
    
    /*@methodName - updateAgrBillingArr
    * @description - update Non-standard Deal (Billing Arrears) per agreement
    * @author - Juhi Rawal
    * @param - List<SObject>
    * @return - Map<Id,Apttus__APTS_Agreement__c>
    */  
    public Map<Id,Apttus__APTS_Agreement__c> updateAgrBillingArr(List<SObject>  listSObject){
        Map<Id,Apttus__APTS_Agreement__c> mapAgreementUpdate = new Map<Id,Apttus__APTS_Agreement__c>();
        try{
            Set<Id> setAgrIDs = new Set<Id>();
            for(APTS_Billing_Settings__c oBill : (List<APTS_Billing_Settings__c>) listSObject){
                setAgrIDs.add(oBill.APTS_Agreement_ID__c);
            }      
            
            for(APTS_Billing_Settings__c oBillingSetting : [select APTS_Agreement_ID__c from APTS_Billing_Settings__c where APTS_Agreement_ID__c IN: setAgrIDs AND APTS_Billing_Rule_Contract__c = 'Bill in Arrears']){
                Apttus__APTS_Agreement__c oAgr = new Apttus__APTS_Agreement__c(Id=oBillingSetting.APTS_Agreement_ID__c);
                oAgr.APTS_Non_Standard_Deal_Billing_Arrears__c = true;
                mapAgreementUpdate.put(oBillingSetting.APTS_Agreement_ID__c,oAgr);
            }           
            for(Id oId: setAgrIDs){
                if(!mapAgreementUpdate.containsKey(oId)){
                    Apttus__APTS_Agreement__c oAgr = new Apttus__APTS_Agreement__c(Id=oId);
                    oAgr.APTS_Non_Standard_Deal_Billing_Arrears__c = false;
                    mapAgreementUpdate.put(oId,oAgr);
                }
            }
        } catch(Exception e){
        /*** PI fix # 190321 & 190381****/
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Billing Setting','','CPQ',false,false,null,true);             
        }  
        return mapAgreementUpdate;
        
        
    }
    
    /*@methodName - updateAgrPaymentMethod
    * @description - update Non-standard Deal (Payment Method) per agreement
    * @author - Juhi Rawal
    * @param - List<SObject>
    * @return - Map<Id,Apttus__APTS_Agreement__c>
    */  
    public Map<Id,Apttus__APTS_Agreement__c> updateAgrPaymentMethod(List<SObject> listSObject){ 
        Map<Id,Apttus__APTS_Agreement__c> mapAgrPaymentMetod = new Map<Id,Apttus__APTS_Agreement__c>();
        try{
            Set<Id> setAgrIDs = new Set<Id>();
            Set<String> setSAPIds = new Set<String> {'SAP_02024','SAP_0202D','SAP_0202I','SAP_0067D','SAP_01546','SAP_0154J','SAP_0154Q','SAP_6706Q','SAP_6750D','SAP_00794','SAP_0079D','SAP_0079E','SAP_0079H','SAP_0079I','SAP_0160D'};
            for(APTS_Billing_Settings__c oBill : (List<APTS_Billing_Settings__c>) listSObject){
                setAgrIDs.add(oBill.APTS_Agreement_ID__c);
            }
            for(APTS_Billing_Settings__c oBillingSetting : [select APTS_Agreement_ID__c,APTS_Payment_Term_Setting__r.APTS_Ext_ID__c from APTS_Billing_Settings__c where APTS_Agreement_ID__c IN: setAgrIDs AND APTS_Payment_Method__r.APTS_Ext_ID__c IN: setSAPIds]){
                Apttus__APTS_Agreement__c oAgr = new Apttus__APTS_Agreement__c(Id=oBillingSetting.APTS_Agreement_ID__c);
                oAgr.APTS_Non_Standard_Deal_Payment_Method__c = true;
                mapAgrPaymentMetod.put(oBillingSetting.APTS_Agreement_ID__c,oAgr);
            }            
            for(Id oId : setAgrIDs){
                if(!mapAgrPaymentMetod.containsKey(oId)){
                    Apttus__APTS_Agreement__c oAgr = new Apttus__APTS_Agreement__c(Id=oId);
                    oAgr.APTS_Non_Standard_Deal_Payment_Method__c = false;
                    mapAgrPaymentMetod.put(oId,oAgr);
                }
            }
        } catch(Exception e){
        /*** PI fix # 190321 & 190381****/
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Billing Setting','','CPQ',false,false,null,true);             
        }  
        return mapAgrPaymentMetod;    
       
    }
    
    /*@methodName - updateAgrPaymentValue
    * @description - update Payment Values & Non-Standard Deal(Payment term) fields per agreement
    * @author - Juhi Rawal
    * @param - List<SObject>
    * @return - Map<Id,Apttus__APTS_Agreement__c>
    */   
    public Map<Id,Apttus__APTS_Agreement__c>  updateAgrPaymentValue(List<SObject> listSObject){
        Map<Id,Apttus__APTS_Agreement__c> mapAgreementUpdate = new Map<Id,Apttus__APTS_Agreement__c>();
        try{
            Set<Id> setAgrIDs = new Set<Id>();
            //Map<Id,List<Decimal>> mapAgreIdDecimal = new Map<Id,List<Decimal>>();
            Map<Id,AgreementDetailsWrapper> mapAgreIdString = new Map<Id,AgreementDetailsWrapper>();
            for(APTS_Billing_Settings__c oBill : (List<APTS_Billing_Settings__c>) listSObject){
                setAgrIDs.add(oBill.APTS_Agreement_ID__c);
            }
            for(APTS_Billing_Settings__c  oBillSetting : [select APTS_Payment_Term_Setting__r.Apttus_Config2__Value__c,APTS_Agreement_ID__r.APTS_Bill_to_Party_Ingredients__r.Creditworthiness_Flag__c,  APTS_Agreement_ID__r.APTS_Bill_to_Party_MachServ__r.Creditworthiness_Flag__c, APTS_Agreement_ID__c from APTS_Billing_Settings__c where APTS_Agreement_ID__c IN: setAgrIDs]){
            
                if(mapAgreIdString.containsKey(oBillSetting.APTS_Agreement_ID__c)){
                    AgreementDetailsWrapper oAgrWrap = mapAgreIdString.get(oBillSetting.APTS_Agreement_ID__c);
                    oAgrWrap.listPaymentTermDays.add(oBillSetting.APTS_Payment_Term_Setting__r.Apttus_Config2__Value__c);
                    mapAgreIdString.put(oBillSetting.APTS_Agreement_ID__c,oAgrWrap);
                } else{
                    AgreementDetailsWrapper oAgrWrapp = new AgreementDetailsWrapper();
                    oAgrWrapp.strMachineFlag = oBillSetting.APTS_Agreement_ID__r.APTS_Bill_to_Party_MachServ__r.Creditworthiness_Flag__c;
                    oAgrWrapp.strIngredientsFlag = oBillSetting.APTS_Agreement_ID__r.APTS_Bill_to_Party_Ingredients__r.Creditworthiness_Flag__c;
                    oAgrWrapp.listPaymentTermDays = new List<Decimal>{oBillSetting.APTS_Payment_Term_Setting__r.Apttus_Config2__Value__c};
                    
                    mapAgreIdString.put(oBillSetting.APTS_Agreement_ID__c,oAgrWrapp);
                }
            }
            System.debug('mapAgreIdString====> ' + mapAgreIdString);
            for(Id oId: setAgrIDs){
                Apttus__APTS_Agreement__c oAgr = new Apttus__APTS_Agreement__c(Id=oId);
                if(mapAgreIdString.containsKey(oId)){
                    AgreementDetailsWrapper oAgrWrapper = mapAgreIdString.get(oId);
                    List<Decimal> liststring = oAgrWrapper.listPaymentTermDays;
                    if(liststring.size()==0){
                       oAgr.APTS_Payment_Term_Value_1__c = null;
                       oAgr.APTS_Payment_Term_Value_2__c = null;
                     
                    }
                    if(liststring.size()==1){
                        oAgr.APTS_Payment_Term_Value_1__c = liststring[0];
                        
                        if(((String.isBlank(oAgrWrapper.strIngredientsFlag) || oAgrWrapper.strIngredientsFlag == 'Red' || oAgrWrapper.strMachineFlag == 'Red' || String.isBlank(oAgrWrapper.strMachineFlag)) && liststring[0]>0 ) || ((oAgrWrapper.strIngredientsFlag == 'Orange' || oAgrWrapper.strMachineFlag == 'Orange') && liststring[0]>14) || ((oAgrWrapper.strIngredientsFlag == 'Green' || oAgrWrapper.strMachineFlag == 'Green') && liststring[0]>29)){
                              oAgr.APTS_Non_Standard_Deal_Payment_Terms__c = true;
                        } else {
                              oAgr.APTS_Non_Standard_Deal_Payment_Terms__c = false;
                        }
                    } else if(liststring.size()>1){
                        oAgr.APTS_Payment_Term_Value_1__c = liststring[0];
                        oAgr.APTS_Payment_Term_Value_2__c = liststring[1];
                        if(((String.isBlank(oAgrWrapper.strIngredientsFlag) || oAgrWrapper.strIngredientsFlag == 'Red' || oAgrWrapper.strMachineFlag == 'Red' || String.isBlank(oAgrWrapper.strMachineFlag)) && (liststring[0]>0 || liststring[1] > 0)) || ((oAgrWrapper.strIngredientsFlag == 'Orange' || oAgrWrapper.strMachineFlag == 'Orange') && (liststring[0]>14 || liststring[1]>14)) || ((oAgrWrapper.strIngredientsFlag == 'Green' || oAgrWrapper.strMachineFlag == 'Green') && (liststring[0]>29 || liststring[1]>29))){
                              oAgr.APTS_Non_Standard_Deal_Payment_Terms__c = true;
                        } else {
                              oAgr.APTS_Non_Standard_Deal_Payment_Terms__c = false;
                        }
                    } 
                } else {
                    oAgr.APTS_Payment_Term_Value_1__c = null;
                    oAgr.APTS_Payment_Term_Value_2__c = null;
                    oAgr.APTS_Non_Standard_Deal_Payment_Terms__c = false;
                }
                    
                mapAgreementUpdate.put(oId,oAgr);
            }
        } catch(Exception e){
        /*** PI fix # 190321 & 190381****/
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Billing Setting','','CPQ',false,false,null,true);             
        }              
        return mapAgreementUpdate;
    }

    ////Added by Santosh to prepare Agreement data based on billing setting data and return map of Agreement 
    public static Map<Id, Apttus__APTS_Agreement__c> updateaggfield(List<SObject> objList, String operation) {

        Set<Id> aggIdset = new Set<Id>();
        Map<Id, Apttus__APTS_Agreement__c> aggMaptUpdate = new Map<Id, Apttus__APTS_Agreement__c>();
        List<APTS_Billing_Settings__c> newbillsetlist = new List<APTS_Billing_Settings__c>(); 
        try{
            for(APTS_Billing_Settings__c obillset : (List<APTS_Billing_Settings__c>)objList) {
                aggIdset.add(obillset.APTS_Agreement_ID__c);
            }

            if(!aggIdset.isEmpty()) {
                for(Apttus__APTS_Agreement__c oAgg : [select id,APTS_BillingPreferenceRelatedDetails__c from Apttus__APTS_Agreement__c where id IN: aggIdset]) {
                    if(operation != 'insert') {
                        oAgg.APTS_BillingPreferenceRelatedDetails__c = '';
                    }
                    aggMaptUpdate.put(oAgg.Id, oAgg);
                }
                if(operation == 'insert') {
                    newbillsetlist = (List<APTS_Billing_Settings__c>)objList;
                } else {
                /*** PI fix # 190410****/
                    newbillsetlist = [select id,name,APTS_Agreement_ID__c,APTS_Ingredient_Billing_Cycle_Start__c,APTS_Billing_Cycle_Start__c,APTS_Ingredient_Billing_Interval__c,APTS_Billing_Rule_Contract__c,APTS_Agreement_Billing_Type__c ,APTS_Billing_Interval__c from APTS_Billing_Settings__c where APTS_Agreement_ID__c IN: aggIdset];
                    }
            }

            if(!newbillsetlist.isEmpty() && !aggMaptUpdate.isEmpty()) {
                aggMaptUpdate = prepareAggMap(newbillsetlist, aggMaptUpdate);
            }
            
        }Catch(Exception e) {
        /*** PI fix # 190321 & 190381****/
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Billing Setting',objList[0].Id ,'CLM',false,false,null, true);
        }
        return aggMaptUpdate;
    }

    //Added by Santosh to prepare Agreement data
    public static Map<Id, Apttus__APTS_Agreement__c> prepareAggMap(List<SObject> newList, Map<Id, Apttus__APTS_Agreement__c> aggMap) {

        for(APTS_Billing_Settings__c obillset : (List<APTS_Billing_Settings__c>)newList) {
            
            if(obillset.APTS_Agreement_Billing_Type__c.containsIgnoreCase('Machine') && obillset.APTS_Agreement_Billing_Type__c != null && obillset.APTS_Agreement_Billing_Type__c != ''){
            aggMap = getAggMap(aggMap, obillset.APTS_Agreement_ID__c, 'Machine|');  
                if(obillset.APTS_Billing_Cycle_Start__c != null && (obillset.APTS_Billing_Cycle_Start__c == 'Billing Day of Month' || obillset.APTS_Billing_Cycle_Start__c == 'Ready for Billing Date' || obillset.APTS_Billing_Cycle_Start__c == 'Period Start Date')){
            aggMap = getAggMap(aggMap, obillset.APTS_Agreement_ID__c, 'Machine:'+obillset.APTS_Ingredient_Billing_Cycle_Start__c+'|');    
                }
                if(obillset.APTS_Billing_Interval__c != null){
            aggMap = getAggMap(aggMap, obillset.APTS_Agreement_ID__c, obillset.APTS_Billing_Interval__c+'Machine:Billing Interval|');
                }else{
            aggMap = getAggMap(aggMap, obillset.APTS_Agreement_ID__c, 'Machine:Billing Interval= null|');       
                }
            aggMap = getAggMap(aggMap, obillset.APTS_Agreement_ID__c, obillset.APTS_Billing_Rule_Contract__c+'|'+'Machine|');
            }
            if(obillset.APTS_Agreement_Billing_Type__c.containsIgnoreCase('Ingredients') && obillset.APTS_Agreement_Billing_Type__c != null && obillset.APTS_Agreement_Billing_Type__c != ''){
            aggMap = getAggMap(aggMap, obillset.APTS_Agreement_ID__c, 'Ingredients|');
                if(obillset.APTS_Ingredient_Billing_Cycle_Start__c != null && (obillset.APTS_Ingredient_Billing_Cycle_Start__c == 'Billing Day of Month' || obillset.APTS_Ingredient_Billing_Cycle_Start__c == 'Ready for Billing Date' || obillset.APTS_Ingredient_Billing_Cycle_Start__c == 'Period Start Date')){
            aggMap = getAggMap(aggMap, obillset.APTS_Agreement_ID__c, 'Ingredients:'+obillset.APTS_Ingredient_Billing_Cycle_Start__c+'|');    
                }  
                if(obillset.APTS_Ingredient_Billing_Interval__c!= null){
            aggMap = getAggMap(aggMap, obillset.APTS_Agreement_ID__c, obillset.APTS_Ingredient_Billing_Interval__c+'Ingredients:Billing Interval|');
                }else{
            aggMap = getAggMap(aggMap, obillset.APTS_Agreement_ID__c, 'Ingredients:Billing Interval= null|');       
                }
            aggMap = getAggMap(aggMap, obillset.APTS_Agreement_ID__c, obillset.APTS_Billing_Rule_Contract__c+'|'+'Ingredients|');
            }
        }
        return aggMap;
    }
    //Added by Shanmuga Prasath to update the Agreement fields from Billing Setting for Output FD
    public static void updateBillingSetting(List<sObject> newList){
        Map<APTS_Billing_Settings__c, Id> billingSettingMap = new Map<APTS_Billing_Settings__c, Id>();
        Map<Id, Apttus__APTS_Agreement__c> agreementMap = new Map<Id, Apttus__APTS_Agreement__c>();
        for(APTS_Billing_Settings__c billSet : (List<APTS_Billing_Settings__c>)newList){
            if(billSet.APTS_Agreement_ID__c != null){
                billingSettingMap.put(billSet, billSet.APTS_Agreement_ID__c);
            }
        }

        for(APTS_Billing_Settings__c billingSetting : billingSettingMap.keySet()){
            if(billingSettingMap.get(billingSetting) != null){
                Apttus__APTS_Agreement__c agreement;
                if(agreementMap.containsKey(billingSetting.APTS_Agreement_ID__c)){
                    agreement = agreementMap.get(billingSetting.APTS_Agreement_ID__c);
                }else{
                    agreement = new Apttus__APTS_Agreement__c(Id=billingSettingMap.get(billingSetting));
                }
                
                if(billingSetting.APTS_Billing_Interval_Translated__c != null){
                    agreement.APTS_Machine_Billing_Interval_Translated__c = billingSetting.APTS_Billing_Interval_Translated__c;
                }
                if(billingSetting.APTS_Billing_Day_Of_Month_Translated__c != null){
                    agreement.APTS_Machine_Bill_Day_Of_Month_Trans__c = billingSetting.APTS_Billing_Day_Of_Month_Translated__c;
                }
                if(billingSetting.APTS_Billing_Cycle_Start_Translated__c != null){
                    agreement.APTS_Machine_Billing_Cycle_Start_Trans__c = billingSetting.APTS_Billing_Cycle_Start_Translated__c;
                }
                if(billingSetting.APTS_Ingredient_Bill_Interval_Translated__c != null){
                    agreement.APTS_Ingredient_Bill_Interval_Translated__c = billingSetting.APTS_Ingredient_Bill_Interval_Translated__c;
                }
                if(billingSetting.APTS_Ingredient_Bill_Day_Of_Month_Trans__c != null){
                    agreement.APTS_Ingredient_Bill_Day_Of_Month_Trans__c = billingSetting.APTS_Ingredient_Bill_Day_Of_Month_Trans__c;
                }
                if(billingSetting.APTS_Ingredient_Bill_Cycle_Start_Trans__c != null){
                    agreement.APTS_Ingredient_Bill_Cycle_Start_Trans__c = billingSetting.APTS_Ingredient_Bill_Cycle_Start_Trans__c;
                }
                agreementMap.put(agreement.Id, agreement);
            }
        }
        Database.update(agreementMap.values(), false);
    }


    //Added by Santosh to assign data to Agreement field
    public static Map<Id, Apttus__APTS_Agreement__c> getAggMap(Map<Id, Apttus__APTS_Agreement__c> newAggMap, Id aggid, String rellistdata) {
        Apttus__APTS_Agreement__c aggmt = newAggMap.get(aggid);
        if(aggmt.APTS_BillingPreferenceRelatedDetails__c == null || aggmt.APTS_BillingPreferenceRelatedDetails__c == '') {
            aggmt.APTS_BillingPreferenceRelatedDetails__c = rellistdata;
        }else if(!aggmt.APTS_BillingPreferenceRelatedDetails__c.containsIgnoreCase(rellistdata)) {
            aggmt.APTS_BillingPreferenceRelatedDetails__c += rellistdata;
        }
        newAggMap.put(aggmt.Id, aggmt);
        return newAggMap;
    }
    
    public class AgreementDetailsWrapper{
        List<Decimal> listPaymentTermDays;
        String strMachineFlag;
        String strIngredientsFlag; 
    }
}