//v 1.1 DQ-2134 - Lavanya - Changes made for Contract Output - For UOM_Translated Population


public with sharing class APTS_VolumeObligationTriggerHandler implements ITriggerHandler 
{
    private static boolean triggerDisabled = false;
    public static final String SUBSUBCATEGORY = APTS_CPQConstants.SUBSUBCATEGORY;
    public static final String SUBCATEGORY = APTS_CPQConstants.SUBCATEGORY;
    public static final String PRODUCT = APTS_CPQConstants.PRODUCT;
    public static final String SAP_PCE = Label.APTS_UoM_Piece;
    public static final String ROUTESALES = APTS_CPQConstants.ROUTESALES;
    public static final String LSP = APTS_CPQConstants.LSP;
    public static final String apiObject= 'APTS_AgreementTotalVolumeObligation__c';
    public static final String INDIRECT_CHANNEL = APTS_CPQConstants.INDIRECT_CHANNEL;
    public Map<Id,Apttus__APTS_Agreement__c> agreementMap = new Map<Id,Apttus__APTS_Agreement__c>();

    public Boolean isDisabled() {

        return triggerDisabled;
    }

    public void beforeInsert(List<SObject> newItems) {
        try{
        //DQ-2134
        Map<String, String> mapFields= new Map<String, String>();
        Map<String, String> mapNew= new Map<String, String>();
        mapFields.put('APTS_Unit_of_Measure__c', 'APTS_Unit_of_Measure_Translated__c');
        mapNew= APTS_LanguageTranslator.getAPItoLabel(apiObject,mapFields);
        //DQ-2134
            getAverageListPriceCostPrice(newItems);
            //Changes for Language Translation added by Shanmuga Prasath
            List<String> lstLang = new List<String>();
            for(APTS_AgreementTotalVolumeObligation__c tmp : (List<APTS_AgreementTotalVolumeObligation__c>) newItems){
                tmp.CurrencyIsoCode = agreementMap.get(tmp.APTS_Agreement__c).Apttus_CMConfig__PriceListId__r.CurrencyIsoCode;
                if(tmp.APTS_Agreement_Language__c != NULL){
                    lstLang.add(tmp.APTS_Agreement_Language__c);
                }
                //DQ-2134
                if(!mapNew.isEmpty() && mapNew.containsKey(tmp.APTS_Unit_of_Measure__c) && mapNew.get(tmp.APTS_Unit_of_Measure__c)!= null)
                tmp.APTS_Unit_of_Measure_Translated__c = mapNew.get(tmp.APTS_Unit_of_Measure__c);
               //DQ-2134
            }
            if(lstLang.size() > 0){
                APTS_LanguageTranslator.translateLanguage(newItems, 'APTS_AgreementTotalVolumeObligation__c', lstLang);
            }
        }Catch(Exception e) {
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'VolumeObligation',newItems[0].Id ,'CLM',false,false,'', false);
        }
    }

    public void afterInsert(List<SObject> newList, Map<Id, SObject> newItems) {
       Set<Id> aggIdset = new Set<Id>();
        Map<Id, Apttus__APTS_Agreement__c> aggMaptUpdate = new Map<Id, Apttus__APTS_Agreement__c>();
        try{
            for(APTS_AgreementTotalVolumeObligation__c oVolobj : (List<APTS_AgreementTotalVolumeObligation__c>)newList) {
                aggIdset.add(oVolobj.APTS_Agreement__c);
            }

            if(!aggIdset.isEmpty()) {
                for(Apttus__APTS_Agreement__c oAgg : [select id,APTS_VolumeObligationRelatedDetails__c from Apttus__APTS_Agreement__c where id IN: aggIdset]) {
                        aggMaptUpdate.put(oAgg.Id, oAgg);
                }
            }

            aggMaptUpdate = prepareAggMap(newList, aggMaptUpdate); 

            system.debug('aggMaptUpdate=='+aggMaptUpdate);
            if(!aggMaptUpdate.isEmpty()) {
                APTS_CheckRecursive.skipTriggerLogic=true;
                update aggMaptUpdate.values();
            }
        }Catch(Exception e) {
           APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'VolumeObligation','','CLM',false,false,'', false);
        }
    }
    

    public void beforeUpdate(List<SObject> newList, Map<Id, SObject> newItems,List<SObject> oldList, Map<Id, SObject> oldItems) {
        try{
         //DQ-2134
        Map<String, String> mapFields= new Map<String, String>();
        Map<String, String> mapNew= new Map<String, String>();
        mapFields.put('APTS_Unit_of_Measure__c', 'APTS_Unit_of_Measure_Translated__c');
        mapNew= APTS_LanguageTranslator.getAPItoLabel(apiObject,mapFields);
        //DQ-2134
            getAverageListPriceCostPrice(newList);
            system.debug('##### TP0 beforeUpdate entered');
            //Changes for Language Translation added by Shanmuga Prasath
            List<String> lstLang = new List<String>();
            for(APTS_AgreementTotalVolumeObligation__c tmp : (List<APTS_AgreementTotalVolumeObligation__c>) newList){
                if(tmp.APTS_Agreement_Language__c != NULL){
                    lstLang.add(tmp.APTS_Agreement_Language__c);
                }
                 //DQ-2134
                if(!mapNew.isEmpty() && mapNew.containsKey(tmp.APTS_Unit_of_Measure__c) && mapNew.get(tmp.APTS_Unit_of_Measure__c)!= null)
                tmp.APTS_Unit_of_Measure_Translated__c = mapNew.get(tmp.APTS_Unit_of_Measure__c);
               //DQ-2134
            }
            if(lstLang.size() > 0){
                APTS_LanguageTranslator.translateLanguage(newList, 'APTS_AgreementTotalVolumeObligation__c', lstLang);
            }
        }Catch(Exception e) {
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'VolumeObligation',newList[0].Id ,'CLM',false,false, '', false);
        }
    }   

    public void afterUpdate(List<SObject> newList, Map<Id, SObject> newItems,List<SObject> oldList, Map<Id, SObject> oldItems) {
        //List<APTS_AgreementTotalVolumeObligation__c> newVolobjlist = new List<APTS_AgreementTotalVolumeObligation__c>();
        Map<Id, APTS_AgreementTotalVolumeObligation__c> newMap = (Map<Id, APTS_AgreementTotalVolumeObligation__c>)oldItems;
        Set<Id> aggIdset = new Set<Id>();
        
        for(APTS_AgreementTotalVolumeObligation__c newVolobj : (List<APTS_AgreementTotalVolumeObligation__c>)newList){
            if(newVolobj.APTS_Action__c != (newMap.get(newVolobj.id)).APTS_Action__c || newVolobj.APTS_IncludeSelloutData__c != (newMap.get(newVolobj.id)).APTS_IncludeSelloutData__c || newVolobj.APTS_VolumeAssumption__c != (newMap.get(newVolobj.id)).APTS_VolumeAssumption__c){
               aggIdset.add(newVolobj.APTS_Agreement__c);
            }
        }
        if(aggIdset.size() > 0){
            updateaggfield(aggIdset);
        }
        
    }


    public void beforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems) {}

    public void afterDelete(List<SObject> oldList, Map<Id, SObject> oldItems) {
        //updateaggfield(oldList);
        Set<Id> aggIdset = new Set<Id>();
        
        for(APTS_AgreementTotalVolumeObligation__c newVolobj : (List<APTS_AgreementTotalVolumeObligation__c>)oldList){
               aggIdset.add(newVolobj.APTS_Agreement__c);
        }
        if(aggIdset.size() > 0){
            updateaggfield(aggIdset);
        }
    }

    public void afterUndelete(List<SObject> newList, Map<Id, SObject> newItems) {}

    public static void updateaggfield(Set<Id> aggIdset) {

        //Set<Id> aggIdset = new Set<Id>();
        Map<Id, Apttus__APTS_Agreement__c> aggMaptUpdate = new Map<Id, Apttus__APTS_Agreement__c>();
        List<APTS_AgreementTotalVolumeObligation__c> newVolobjlist = new List<APTS_AgreementTotalVolumeObligation__c>(); 
        try{
            /*for(APTS_AgreementTotalVolumeObligation__c oVol : (List<APTS_AgreementTotalVolumeObligation__c>)objList) {
                aggIdset.add(oVol.APTS_Agreement__c);
            }*/

            if(!aggIdset.isEmpty()) {
                for(Apttus__APTS_Agreement__c oAgg : [select id,APTS_VolumeObligationRelatedDetails__c from Apttus__APTS_Agreement__c where id IN: aggIdset]) {
                    oAgg.APTS_VolumeObligationRelatedDetails__c = '';
                    aggMaptUpdate.put(oAgg.Id, oAgg);
                }

                newVolobjlist = [select id,name,APTS_Agreement__c,APTS_Action__c,APTS_IncludeSelloutData__c,APTS_VolumeAssumption__c from APTS_AgreementTotalVolumeObligation__c where APTS_Agreement__c IN: aggIdset];
            }


            aggMaptUpdate = prepareAggMap(newVolobjlist, aggMaptUpdate);
            
            system.debug('aggMaptUpdate update=='+aggMaptUpdate);
            if(!aggMaptUpdate.isEmpty()) {
                 APTS_CheckRecursive.skipTriggerLogic=true;
                update aggMaptUpdate.values();
            }
        }Catch(Exception e) {
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'VolumeObligation',newVolobjlist[0].Id ,'CLM',false,false, '', false);
        }

    }    

    public static Map<Id, Apttus__APTS_Agreement__c> prepareAggMap(List<SObject> newList, Map<Id, Apttus__APTS_Agreement__c> aggMap) {

        for(APTS_AgreementTotalVolumeObligation__c ovolobg : (List<APTS_AgreementTotalVolumeObligation__c>)newList) {
            if(ovolobg.APTS_Action__c == 'Invoice Customer') {
                aggMap = getAggMap(aggMap, ovolobg.APTS_Agreement__c, 'Invoice Customer|');        
            }
            if(ovolobg.APTS_Action__c == 'Paid Service Fee') {
                aggMap = getAggMap(aggMap, ovolobg.APTS_Agreement__c, 'Paid Service Fee|');        
            }
            if(ovolobg.APTS_Action__c == 'Renegotiate Contract') {
                aggMap = getAggMap(aggMap, ovolobg.APTS_Agreement__c, 'Renegotiate Contract|');        
            }
            if(ovolobg.APTS_IncludeSelloutData__c == true) {
                aggMap = getAggMap(aggMap, ovolobg.APTS_Agreement__c, 'Selloutdatatrue|');        
            }
            if(ovolobg.APTS_VolumeAssumption__c > 0) {
                aggMap = getAggMap(aggMap, ovolobg.APTS_Agreement__c, 'Volume Assumption|');        
            }

                        
        }
        return aggMap;        
    }

    public static Map<Id, Apttus__APTS_Agreement__c> getAggMap(Map<Id, Apttus__APTS_Agreement__c> newAggMap, Id aggid, String rellistdata) {
        Apttus__APTS_Agreement__c aggmt = newAggMap.get(aggid);
        if(aggmt.APTS_VolumeObligationRelatedDetails__c == null || aggmt.APTS_VolumeObligationRelatedDetails__c == '') {
            aggmt.APTS_VolumeObligationRelatedDetails__c = rellistdata;
        }else if(!aggmt.APTS_VolumeObligationRelatedDetails__c.containsIgnoreCase(rellistdata)) {
            aggmt.APTS_VolumeObligationRelatedDetails__c += rellistdata;
        }
        newAggMap.put(aggmt.Id, aggmt);
        return newAggMap;
    }         
    /*@methodName - getAverageListPriceCostPrice
    * @description - Fetches ALCP Record based on Sales Org, Pricing Date, UOM, Subcategory and Subsubcategory
    * @param - List<SObject> newItems
    * @return - 
    * @history: 9/18/18 jason.e.mactal     removed logic for fetching ALCP for Product Based Assumption and added UOM on logic ALM: 19160
    */
    public void getAverageListPriceCostPrice(List<SObject> newItems){
        Set<String> subSubCategorySet = new Set<String>();
        Set<String> productSet = new Set<String>();
        Set<String> salesOrgSet = new Set<String>();
        Set<Id> aggSet = new Set<Id>();
        Set<Id> catHierarchyIdSet = new Set<Id>();
        
        Map<String,List<Map<String,List<APTS_AverageListPriceCostPrice__c>>>> oALCPPerRegionUOMMap = new Map<String,List<Map<String,List<APTS_AverageListPriceCostPrice__c>>>>();
        
        try{
        for(APTS_AgreementTotalVolumeObligation__c oVAO : (List<APTS_AgreementTotalVolumeObligation__c>)newItems){
            salesOrgSet.add(oVAO.APTS_Sales_Org__c);
            aggSet.add(oVAO.APTS_Agreement__c);

            if(!PRODUCT.equalsIgnoreCase(oVAO.APTS_Type__c) && oVAO.APTS_Value__c != NULL){
                catHierarchyIdSet.add(Id.valueOf(oVAO.APTS_Value__c));
            }
        }
        
        //Fetch Agreements
        agreementMap = getAgreements(aggSet);
        
        //Fetch Category Hierarchies
        Map<Id,Apttus_Config2__ClassificationHierarchy__c> categoryHierarchyMap = new Map<Id,Apttus_Config2__ClassificationHierarchy__c>([SELECT Id, APTS_CategoryHierarchyOfferingExtId__c FROM Apttus_Config2__ClassificationHierarchy__c WHERE Id IN:catHierarchyIdSet]);
                      
        //Fetch Agreement Line Items
        /*Map<Id,Apttus__AgreementLineItem__c> agreementLineItemMap = new Map<Id,Apttus__AgreementLineItem__c>();
        for(Apttus__AgreementLineItem__c oALI: [SELECT Id, Apttus_CMConfig__PriceListItemId__r.Apttus_Config2__Cost__c, Apttus_CMConfig__PriceListItemId__r.Apttus_Config2__ListPrice__c, Apttus__ProductId__c, Apttus_CMConfig__PriceListItemId__r.Apttus_Config2__PriceUom__c,
                                              APTS_Net_Adjustment_Amount_2_decimals__c
                                              FROM Apttus__AgreementLineItem__c
                                              WHERE Apttus__AgreementId__c =: aggSet AND APTS_Ingredient_Standalone__c = TRUE]){
                                                  
            if(!agreementLineItemMap.containsKey(oALI.Apttus__ProductId__c)) {
                agreementLineItemMap.put(oALI.Apttus__ProductId__c, oALI);
            }
            
        }*/
        
        for(APTS_AverageListPriceCostPrice__c oALCP: [SELECT ID, APTS_ALPCP_SalesOrg__c, APTS_ALPCP_UnitOfMeasure__c, APTS_ALPCP_Category__c, APTS_ALPCP_Subcategory__c, APTS_ALPCP_Subsubcat__c, APTS_Start_Date__c, APTS_End_Date__c, APTS_ALPCP_IngCost__c, APTS_ALPCP_GIP__c, APTS_ALPCP_VAP__c, APTS_ALPCP_Routesales__c FROM APTS_AverageListPriceCostPrice__c WHERE APTS_ALPCP_SalesOrg__c IN: salesOrgSet]){
            Map<String,List<APTS_AverageListPriceCostPrice__c>> oALCPMap = new Map<String,List<APTS_AverageListPriceCostPrice__c>>();
            //Gather all Average List Price Cost Price for Product
            /*if(oALCP.APTS_ALPCP_Product__c != NULL){
                if (oALCPMap.containsKey(PRODUCT)) {
                    oALCPMap.get(PRODUCT).add(oALCP);
                } else {
                    oALCPMap.put(PRODUCT, new List<APTS_AverageListPriceCostPrice__c> {oALCP});
                  }
            }*/
            
            //Gather all Average List Price Cost Price for Sub-Category
            if(oALCP.APTS_ALPCP_Category__c != NULL && oALCP.APTS_ALPCP_Subcategory__c != NULL && oALCP.APTS_ALPCP_Subsubcat__c == NULL){
                if (oALCPMap.containsKey(SUBCATEGORY)) {
                    oALCPMap.get(SUBCATEGORY).add(oALCP);
                } else {
                    oALCPMap.put(SUBCATEGORY, new List<APTS_AverageListPriceCostPrice__c> {oALCP});
                }
            }
            //Gather all Average List Price Cost Price for Sub-Sub-Category
            if(oALCP.APTS_ALPCP_Category__c != NULL && oALCP.APTS_ALPCP_Subcategory__c != NULL && oALCP.APTS_ALPCP_Subsubcat__c != NULL){
                if (oALCPMap.containsKey(SUBSUBCATEGORY)) {
                    oALCPMap.get(SUBSUBCATEGORY).add(oALCP);
                } else {
                    oALCPMap.put(SUBSUBCATEGORY, new List<APTS_AverageListPriceCostPrice__c> {oALCP});
                }
            }
            //Add it to mapping by region+uom
            if(oALCP.APTS_ALPCP_SalesOrg__c!=NULL && oALCP.APTS_ALPCP_UnitOfMeasure__c!=NULL){
                string regionUOMstr = string.valueOf(oALCP.APTS_ALPCP_SalesOrg__c) + string.valueOf(oALCP.APTS_ALPCP_UnitOfMeasure__c);
                if(oALCPPerRegionUOMMap.containsKey(regionUOMstr)){
                    oALCPPerRegionUOMMap.get(regionUOMstr).add(oALCPMap);
                } else {
                    oALCPPerRegionUOMMap.put(regionUOMstr,new List<Map<String,List<APTS_AverageListPriceCostPrice__c>>>{oALCPMap});
                }
            }
        }
        
        for(APTS_AgreementTotalVolumeObligation__c oVAO : (List<APTS_AgreementTotalVolumeObligation__c>)newItems){
            string regionUOMstr = string.valueOf(oVAO.APTS_Sales_Org__c) + string.valueOf(oVAO.APTS_Unit_of_Measure__c);
            APTS_AverageListPriceCostPrice__c oAverageListPriceCostPrice = new APTS_AverageListPriceCostPrice__c();
            //Get ALCP per Sales Org
            if(oVAO.APTS_Sales_Org__c!=NULL && oVAO.APTS_Unit_of_Measure__c!=NULL && oALCPPerRegionUOMMap.containsKey(regionUOMstr)){
                for(Map<String,List<APTS_AverageListPriceCostPrice__c>> oALCPPerType: oALCPPerRegionUOMMap.get(regionUOMstr)){
                    //Get ALCP Per Type
                    if(oVAO.APTS_Type__c!=NULL && oALCPPerType.containsKey(oVAO.APTS_Type__c)){
                        for(APTS_AverageListPriceCostPrice__c oALCP: oALCPPerType.get(oVAO.APTS_Type__c)){
                            //Check if ALCP Record Matches with the Category, Subcategory and SubSubcategory && Check the Pricing Date
                            if(SUBSUBCATEGORY.equalsIgnoreCase(oVAO.APTS_Type__c) && 
                            !string.isEmpty(oVAO.APTS_Value__c) &&
                            oALCP.APTS_ALPCP_Subsubcat__c.substring(4).equalsIgnoreCase(categoryHierarchyMap.get(oVAO.APTS_Value__c).APTS_CategoryHierarchyOfferingExtId__c) &&
                            oVAO.APTS_Pricing_Date__c >= oALCP.APTS_Start_Date__c && oVAO.APTS_Pricing_Date__c <= oALCP.APTS_End_Date__c){
                                oVAO.APTS_AverageListPriceCostPrice__c = oALCP.id;
                                oAverageListPriceCostPrice = oALCP;
                            }
                            //Check if ALCP Record Matches with the Category, Subcategory && Check the Pricing Date
                            if(SUBCATEGORY.equalsIgnoreCase(oVAO.APTS_Type__c) && 
                            !string.isEmpty(oVAO.APTS_Value__c) &&
                            oALCP.APTS_ALPCP_Subcategory__c.substring(4).equalsIgnoreCase(categoryHierarchyMap.get(oVAO.APTS_Value__c).APTS_CategoryHierarchyOfferingExtId__c) &&
                            oVAO.APTS_Pricing_Date__c >= oALCP.APTS_Start_Date__c && oVAO.APTS_Pricing_Date__c <= oALCP.APTS_End_Date__c){
                                oVAO.APTS_AverageListPriceCostPrice__c = oALCP.id;
                                oAverageListPriceCostPrice = oALCP;
                            }
                            //removing as per defect ALM: 19160
                            //Check if Product Name matches with ALCP Product
                            //if(PRODUCT.equals(oVAO.APTS_Type__c) && 
                            //!string.isEmpty(oVAO.APTS_Value_Name__c) && oALCP.APTS_ALPCP_Product__c.equalsIgnoreCase(oVAO.APTS_Value_Name__c) && oVAO.APTS_Pricing_Date__c >= oALCP.APTS_Start_Date__c && oVAO.APTS_Pricing_Date__c <= oALCP.APTS_End_Date__c){
                            //    oVAO.APTS_AverageListPriceCostPrice__c = oALCP.id;
                            //}
                            
                        }
                    }
                }
            }
            oVAO.APTS_Total_Estimated_Contract_Value__c = calculateEstimatedContractValue(oVAO.APTS_Type__c, oVAO, oAverageListPriceCostPrice);
            if(SUBSUBCATEGORY.equalsIgnoreCase(oVAO.APTS_Type__c) || SUBCATEGORY.equalsIgnoreCase(oVAO.APTS_Type__c)){
                oVAO.APTS_Total_Expected_Cost_Amount__c = calculateEstimatedCostAmount(oVAO.APTS_Type__c, oVAO, oAverageListPriceCostPrice);
            }
            //oVAO.APTS_Total_Expected_Discount_Amount__c = calculateExpectedDiscount(oVAO.APTS_Type__c, oVAO, agreementLineItemMap.get(oVAO.APTS_Value__c));

            
        }
        }Catch(Exception e) {
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'VolumeObligationDM',null ,'CPQ',false,false, '', false);
        }
    }
    
    /*@methodName - calculateEstimatedContractValue
    * @description - calculate the Total Estimated Contract Value
    * @param - string sVAOType, APTS_AgreementTotalVolumeObligation__c oVAO
    * @return - decimal
    * @ALM: 19724
    * @history: 11.14.2018 - changed formula for calculating TECV for Product based VA, removed ALI input parameter
    */
    public decimal calculateEstimatedContractValue(string sVAOType, APTS_AgreementTotalVolumeObligation__c oVAO, APTS_AverageListPriceCostPrice__c oALCP){
        decimal contractValue = 0;
        decimal averagePrice = 0;
        
        if(oVAO.APTS_AverageListPriceCostPrice__c != NULL){
            if(ROUTESALES.equalsIgnoreCase(agreementMap.get(oVAO.APTS_Agreement__c).APTS_Preferred_way_of_ingredient_deliver__c)){
                averagePrice = oALCP.APTS_ALPCP_Routesales__c;
            }
            if(LSP.equalsIgnoreCase(agreementMap.get(oVAO.APTS_Agreement__c).APTS_Preferred_way_of_ingredient_deliver__c)){
                averagePrice = oALCP.APTS_ALPCP_VAP__c;
            }
            if(INDIRECT_CHANNEL.equalsIgnoreCase(agreementMap.get(oVAO.APTS_Agreement__c).APTS_Preferred_way_of_ingredient_deliver__c)){
                averagePrice = oALCP.APTS_ALPCP_GIP__c;
            }
        }
    
        if((SUBSUBCATEGORY.equalsIgnoreCase(sVAOType) || SUBCATEGORY.equalsIgnoreCase(sVAOType)) && oVAO.APTS_AverageListPriceCostPrice__c != NULL && agreementMap.get(oVAO.APTS_Agreement__c).APTS_Agreement_Duration_Months__c!=null){
             contractValue = (oVAO.APTS_VolumeAssumption__c * averagePrice / 12) * agreementMap.get(oVAO.APTS_Agreement__c).APTS_Agreement_Duration_Months__c;
        }
        
        else if(PRODUCT.equalsIgnoreCase(sVAOType) && oVAO.APTS_GrossSale__c != NULL && agreementMap.get(oVAO.APTS_Agreement__c).APTS_Agreement_Duration_Months__c!=null){
            contractValue = (oVAO.APTS_GrossSale__c/ 12) * agreementMap.get(oVAO.APTS_Agreement__c).APTS_Agreement_Duration_Months__c;
        }else{
            contractValue = 0;
        }
    
    return contractValue;
    }
    /*@methodName - calculateEstimatedCostAmount
    * @description - calculate the Total Estimated Contract Value
    * @param - string sVAOType, APTS_AgreementTotalVolumeObligation__c oVAO
    * @return - decimal
    * @ALM: 19727
    * @history: 11.14.2018 - removed logic for calculating Total Estimated Cost Amount for Product Based VA,removed ALI input parameter 
    */
    public decimal calculateEstimatedCostAmount(string sVAOType, APTS_AgreementTotalVolumeObligation__c oVAO, APTS_AverageListPriceCostPrice__c oALCP){
        decimal costAmount;
    
        if((SUBSUBCATEGORY.equalsIgnoreCase(sVAOType) || SUBCATEGORY.equalsIgnoreCase(sVAOType)) && oVAO.APTS_AverageListPriceCostPrice__c != NULL && oVAO.APTS_VolumeAssumption__c != NULL && agreementMap.get(oVAO.APTS_Agreement__c).APTS_Agreement_Duration_Months__c!=null){
             costAmount = (oVAO.APTS_VolumeAssumption__c * oALCP.APTS_ALPCP_IngCost__c / 12) *  agreementMap.get(oVAO.APTS_Agreement__c).APTS_Agreement_Duration_Months__c;
        }
        //else if(PRODUCT.equalsIgnoreCase(sVAOType) && SAP_PCE.equalsIgnoreCase(oALI.Apttus_CMConfig__PriceListItemId__r.Apttus_Config2__PriceUom__c) && SAP_PCE.equalsIgnoreCase(oVAO.APTS_Unit_of_Measure__c) && oVAO.APTS_VolumeAssumption__c != NULL && agreementMap.get(oVAO.APTS_Agreement__c).APTS_Agreement_Duration_Months__c !=null){
        //    costAmount = (oVAO.APTS_VolumeAssumption__c * oALI.Apttus_CMConfig__PriceListItemId__r.Apttus_Config2__Cost__c / 12) * agreementMap.get(oVAO.APTS_Agreement__c).APTS_Agreement_Duration_Months__c;
        //}
        //else{
        //    costAmount = 0;
        //}
    
    return costAmount;
    }
    
    /*@methodName - getAgreements
    * @description - fetch Agreement
    * @param - Set<id>
    * @return - Map<Id,Apttus__APTS_Agreement__c>
    */
    public Map<Id,Apttus__APTS_Agreement__c> getAgreements(Set<id> aggIdSet){
        Map<Id,Apttus__APTS_Agreement__c> agrMap = new Map<Id,Apttus__APTS_Agreement__c>([SELECT Id, APTS_Agreement_Duration_Months__c, APTS_Preferred_way_of_ingredient_deliver__c, Apttus_CMConfig__PriceListId__r.CurrencyIsoCode FROM Apttus__APTS_Agreement__c WHERE Id IN:aggIdSet]);
        return agrMap;
    }
    /*@methodName - calculateExpectedDiscount
    * @description - calculate the Total Estimated Contract Value - not currently used
    * @param - string sVAOType, APTS_AgreementTotalVolumeObligation__c oVAO, Apttus__AgreementLineItem__c oALI
    * @return - decimal
    * @ALM: 19727
    *
    public decimal calculateExpectedDiscount(string sVAOType, APTS_AgreementTotalVolumeObligation__c oVAO, Apttus__AgreementLineItem__c oALI){
        decimal discountAmount = 0;
    
        if(PRODUCT.equalsIgnoreCase(sVAOType) && oVAO.APTS_VolumeAssumption__c != NULL && agreementMap.get(oVAO.APTS_Agreement__c).APTS_Agreement_Duration_Months__c!=null){
             discountAmount = (oVAO.APTS_VolumeAssumption__c * oALI.APTS_Net_Adjustment_Amount_2_decimals__c / 12) *  agreementMap.get(oVAO.APTS_Agreement__c).APTS_Agreement_Duration_Months__c;
        }else{
            discountAmount = 0;
        }
    
    return discountAmount;
    }*/
    
        
}