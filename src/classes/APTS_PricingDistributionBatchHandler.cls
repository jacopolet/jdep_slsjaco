/**
* Class Name : APTS_PricingDistributionBatchHandler
* Description :  Handler class for 'APTS_PricingDistributionBatch' Apex Class
* Author : V. Shankaranarayanan/Nagavi Babu/Lavanya ravindran
* Date Created : 03/06/2018
**/
public with sharing class APTS_PricingDistributionBatchHandler{
    
    private Static String EMPTY_STRING = ' ';
    
    /** Method Name : getObjectQuery
    * Description : Method to build and return a dynamic query for a specified sObject 
    **/
    public static String getObjectQuery(String objectName){
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
        String thisQuery = Label.APTS_SelectLabel + EMPTY_STRING;
        for(Schema.SObjectField field : fieldMap.values()){
            thisQuery += field.getDescribe().getName() + Label.APTS_CommaSeparator;
        }
        thisQuery = thisQuery.subString(0, thisQuery.length()-1);
        thisQuery += EMPTY_STRING + Label.APTS_FromLabel + EMPTY_STRING + objectName + EMPTY_STRING;
        return thisQuery;
    }
    
    /** Method Name : getPricingStagingToPLIFieldsMapping
    * Description : Method to build and return Pricing Staging and PLI Objects' field mapping
    **/
    public static Map<String, String> getPricingStagingToPLIFieldsMapping(){
        Map<String, String> pricingStagingToPLIFieldsMap = new Map<String, String>();
        
        for(APTS_Pricing_Staging_PLI_Field_Mapping__mdt meta : [SELECT Id, APTS_Price_List_Item_Field_Name__c, APTS_Pricing_Staging_Field_Name__c FROM APTS_Pricing_Staging_PLI_Field_Mapping__mdt]){
            pricingStagingToPLIFieldsMap.put(meta.APTS_Pricing_Staging_Field_Name__c, meta.APTS_Price_List_Item_Field_Name__c);
        }
        return pricingStagingToPLIFieldsMap;
    }
    
    /** Method Name : getPricingStagingContractMapping
    * Description : Method to build and return Pricing Staging Contract Period mapping
    **/
    public static Map<String, APTS_Pricing_Staging_Contract_Mapping__mdt> getPricingStagingContractMapping(){
        
        Map<String, APTS_Pricing_Staging_Contract_Mapping__mdt> pricingStagingContractMap = new Map<String, APTS_Pricing_Staging_Contract_Mapping__mdt>();
        for(APTS_Pricing_Staging_Contract_Mapping__mdt meta : [SELECT Id, MasterLabel, APTS_Dimension__c, APTS_Sequence__c FROM APTS_Pricing_Staging_Contract_Mapping__mdt]){
            pricingStagingContractMap.put(meta.MasterLabel, meta);
        }
        return pricingStagingContractMap;
    }
    
    /** Method Name : getPLIChargeTypeCriteriaMapping
    * Description : Method to build and return PLI Charge Type Criteria mapping
    **/
    public static Map<String, String> getPLIChargeTypeCriteriaMapping(){
        
        Map<String, String> pLIChargeTypeCriteriaMap = new Map<String, String>();
        for(APTS_PLI_Charge_Type_Criteria_Mapping__mdt meta : [Select Id, MasterLabel, APTS_Charge_Type_Criteria__c from APTS_PLI_Charge_Type_Criteria_Mapping__mdt]){
            pLIChargeTypeCriteriaMap.put(meta.MasterLabel, meta.APTS_Charge_Type_Criteria__c);
        }
        return pLIChargeTypeCriteriaMap;
    }
     
    /** Method Name : getTaxAmendmentValues
    * Description : Method to build and return Tax Amendment Custom Setting values
    **/ 
    public static Map<String,Integer> getTaxAmendmentValues(){
        Map<String, Integer> custSettingMap = new Map<String, Integer>();
        for(APTS_Tax_Amendment_Settings__c custSetting : APTS_Tax_Amendment_Settings__c.getAll().values()){
            custSettingMap.put(custSetting.APTS_SalesOrgClassificationCombination__c, Integer.valueOf(custSetting.APTS_Percentage__c));
        }
        return custSettingMap;
    }
     
    /** Method Name : deactivatePLIs
    * Description : Method to make the PLIs inactive
    **/
    public static List<Apttus_Config2__PriceListItem__c> deactivatePLIs(List<Apttus_Config2__PriceListItem__c> pLISet){
        List<Apttus_Config2__PriceListItem__c> pLIUpdateList = new List<Apttus_Config2__PriceListItem__c>();
        for(Apttus_Config2__PriceListItem__c pLI : pLISet){
            pLI.Apttus_Config2__Active__c = false;
            pLI.Apttus_Config2__ExpirationDate__c = System.Now();
            pLIUpdateList.add(pLI);
        }
        return pLIUpdateList;
    }
    
    /** Method Name : processServicePS
    * Description : Method to update the appropriate fields of 'Service Fee' related Pricing Staging records
    **/
    public static Map<String, Apttus_Config2__PriceListItem__c> processServicePS(List<APTS_Pricing_Staging__c> pricingStagingList, Map<String, Apttus_Config2__PriceListItem__c> pliToBoUpsertedMap, Map<String,Apttus_Config2__PriceListItem__c> prodToPLIMap,Map<String,APTS_Sales_Org_Data__c> activeSalesOrgMap,Map<String,Product2> activeProductMap){
        List<APTS_Batch_Error__c> batchErrorList = new List<APTS_Batch_Error__c>();
        Map<Id,APTS_Pricing_Staging__c> psToBeUpdated=new Map<Id,APTS_Pricing_Staging__c>();
        List<APTS_Pricing_Staging__c> psToBeUpdatedList=new List<APTS_Pricing_Staging__c>();
        Set<String> requiredChargeTypeSet = new Set<String>{Label.APTS_Sales_Price, Label.APTS_Rental_Price};
        Map<String, APTS_Tax_Pricing_Mapping__c> taxFieldMapCS = APTS_Tax_Pricing_Mapping__c.getAll();
        Map<ID,Apttus_Config2__FrequencyConversionRate__c> uomConversionMap= new Map<ID,Apttus_Config2__FrequencyConversionRate__c>();
        Map<ID,String> productcodeProductIDMap = new Map<ID,String>();
        System.debug('pricingStagingList=============>'+pricingStagingList);
        for(APTS_Pricing_Staging__c stage : pricingStagingList){
            for(String chargeType : requiredChargeTypeSet){
                Apttus_Config2__PriceListItem__c toBeUpdatedPLI = new Apttus_Config2__PriceListItem__c ();
                String pLIKey = stage.APTS_Product_Code__c + stage.APTS_Sales_Organization__c + chargeType;
                APTS_Tax_Pricing_Mapping__c taxMapping = taxFieldMapCS.get(stage.APTS_Condition_Type__c);
                if(pliToBoUpsertedMap.containsKey(pLIKey)){
                    toBeUpdatedPLI= pliToBoUpsertedMap.get(pLIKey);
                    
                }else if(prodToPLIMap.containsKey(pLIKey)){
                    toBeUpdatedPLI = prodToPLIMap.get(pLIKey);
                    
                }
                System.debug('pLIKey=============>'+pLIKey);
                System.debug('pliToBoUpsertedMap=============>'+pliToBoUpsertedMap);
                System.debug('prodToPLIMap=============>'+prodToPLIMap);
                System.debug('toBeUpdatedPLI=============>'+toBeUpdatedPLI);
                if((pliToBoUpsertedMap.containsKey(pLIKey) || prodToPLIMap.containsKey(pLIKey)) && stage.APTS_SAP_ListPriceUnits__c!=null && stage.APTS_SAP_ListPriceUnits__c!=0){    
                    if(stage.APTS_Condition_Type__c == Label.APTS_YSFL){
                        toBeUpdatedPLI.APTS_Labour_Coverage__c = stage.APTS_List_Price__c / stage.APTS_SAP_ListPriceUnits__c;
                    }else if(stage.APTS_Condition_Type__c == Label.APTS_YSFC){
                        toBeUpdatedPLI.APTS_Call_Out_Coverage__c = stage.APTS_List_Price__c / stage.APTS_SAP_ListPriceUnits__c;
                    }else if(stage.APTS_Condition_Type__c == Label.APTS_YSFS){
                        toBeUpdatedPLI.APTS_Spare_Parts_Coverage__c = stage.APTS_List_Price__c / stage.APTS_SAP_ListPriceUnits__c;
                    }else if(taxFieldMapCS.keyset().contains(stage.APTS_Condition_Type__c)){
                        //Update tax fields for new PLIs |  Karan
                        if(stage.APTS_Condition_Type__c==APTS_CPQConstants.TAX_DISP_CODE){
                            if(toBeUpdatedPLI.Apttus_Config2__ChargeType__c==APTS_CPQConstants.SALES_PRICE){
                                toBeUpdatedPLI.put(taxMapping.APTS_Tax_field_on_price_list_item__c,(stage.APTS_List_Price__c / stage.APTS_SAP_ListPriceUnits__c));
                            }else{
                                toBeUpdatedPLI.put(taxMapping.APTS_Tax_field_on_price_list_item__c,0);
                            }
                        }else{
                            //for price list item update tax fields based on custom setting
                            toBeUpdatedPLI.put(taxMapping.APTS_Tax_field_on_price_list_item__c,(stage.APTS_List_Price__c / stage.APTS_SAP_ListPriceUnits__c));
                        }
                    }
                    stage.APTS_Process_Status__c=Label.APTS_Processed;
                    psToBeUpdated.put(stage.Id,stage);
                    pliToBoUpsertedMap.put(pLIKey,toBeUpdatedPLI);
                    //Add product code set
                    System.debug('*****stage.APTS_Product_Code__c=====>');
                    if(productcodeProductIDMap.get(toBeUpdatedPLI.Apttus_Config2__ProductId__c)==null){
                        productcodeProductIDMap.put(toBeUpdatedPLI.Apttus_Config2__ProductId__c,stage.APTS_Product_Code__c);
                    }
                }  
            }                          
        }
        //getting all UOM conversion values
        
        for( Apttus_Config2__FrequencyConversionRate__c freqConversion : [select id,Apttus_Config2__FromUom__c,Apttus_Config2__ToUom__c,Apttus_Config2__ProductFamily__c,Apttus_Config2__ConversionFactor__c,Apttus_Config2__ProductId__c,APTS_ProductCode__c from Apttus_Config2__FrequencyConversionRate__c where APTS_ProductCode__c IN: productcodeProductIDMap.values()]){
            if(uomConversionMap.get(freqConversion.id)==null){
                uomConversionMap.put(freqConversion.id,freqConversion);
            }
        }
        System.debug('uomConversionMap======>'+uomConversionMap);
        System.debug('productcodeProductIDMap======>'+productcodeProductIDMap);
        //Calculating tax per uom field = TAX_all_countries + TAX_DK_specific
        for(Apttus_Config2__PriceListItem__c taxSum : pliToBoUpsertedMap.Values()){
            System.debug('taxSum.Apttus_Config2__PriceUom__c====>'+taxSum.Apttus_Config2__PriceUom__c);
            System.debug('productcodeProductIDMap.get(taxSum.Apttus_Config2__ProductId__c)======>'+productcodeProductIDMap.get(taxSum.Apttus_Config2__ProductId__c));
            System.debug('UOM Piece======>'+APTS_CalculateTaxesCtrl.getConversionRate(uomConversionMap,APTS_CPQConstants.PIECE_UOM_API,taxSum.Apttus_Config2__PriceUom__c,productcodeProductIDMap.get(taxSum.Apttus_Config2__ProductId__c)));
            System.debug('UOM KG======>'+APTS_CalculateTaxesCtrl.getConversionRate(uomConversionMap,taxSum.Apttus_Config2__PriceUom__c,APTS_CPQConstants.KG_UOM_API,productcodeProductIDMap.get(taxSum.Apttus_Config2__ProductId__c)));
            //Initialize null value to 0
            for(APTS_Tax_Pricing_Mapping__c taxfields : taxFieldMapCS.values()){
                if(taxSum.get(taxfields.APTS_Tax_field_on_price_list_item__c)==null){
                    taxSum.put(taxfields.APTS_Tax_field_on_price_list_item__c,0);
                }
            }
            taxSum.APTS_TAX_all_countries_UOM__c=0;
            taxSum.APTS_TAX_DK_specific_UOM__c=0;
            taxSum.APTS_Tax_per_UOM__c=0;
            if(taxSum.Apttus_Config2__PriceUom__c!=null && !productcodeProductIDMap.isEmpty() && productcodeProductIDMap.get(taxSum.Apttus_Config2__ProductId__c)!=null && !uomConversionMap.isEmpty() && APTS_CalculateTaxesCtrl.getConversionRate(uomConversionMap,APTS_CPQConstants.PIECE_UOM_API,taxSum.Apttus_Config2__PriceUom__c,productcodeProductIDMap.get(taxSum.Apttus_Config2__ProductId__c))!=null && APTS_CalculateTaxesCtrl.getConversionRate(uomConversionMap,taxSum.Apttus_Config2__PriceUom__c,APTS_CPQConstants.KG_UOM_API,productcodeProductIDMap.get(taxSum.Apttus_Config2__ProductId__c))!=null){
                //calculate tax
                if(taxSum.APTS_TXP_Recycle_Con_Pack_Tax__c != NULL && taxSum.APTS_TXP_Disposal_Fee__c != NULL && taxSum.APTS_TXP_Belgian_GSV__c != NULL && taxSum.Apttus_Config2__PriceUom__c != NULL && taxSum.Apttus_Config2__ProductId__c != NULL)
                taxSum.APTS_TAX_all_countries_UOM__c = (taxSum.APTS_TXP_Recycle_Con_Pack_Tax__c + taxSum.APTS_TXP_Disposal_Fee__c + taxSum.APTS_TXP_Belgian_GSV__c) * APTS_CalculateTaxesCtrl.getConversionRate(uomConversionMap,APTS_CPQConstants.PIECE_UOM_API,taxSum.Apttus_Config2__PriceUom__c,productcodeProductIDMap.get(taxSum.Apttus_Config2__ProductId__c));

                if(APTS_CalculateTaxesCtrl.getConversionRate(uomConversionMap,taxSum.Apttus_Config2__PriceUom__c,APTS_CPQConstants.KG_UOM_API,productcodeProductIDMap.get(taxSum.Apttus_Config2__ProductId__c))!=0){
                    taxSum.APTS_TAX_DK_specific_UOM__c = (taxSum.APTS_TXP_Coffee_tax__c + taxSum.APTS_TXP_Instant_coffee_tax__c + taxSum.APTS_TXP_Liquid_coffee_tax__c + taxSum.APTS_TXP_Tea_tax__c + taxSum.APTS_TXP_Chocolate_tax__c + taxSum.APTS_TXP_Disposable_tableware__c + taxSum.APTS_TXP_Cappuccino_tax_mixed__c) / APTS_CalculateTaxesCtrl.getConversionRate(uomConversionMap,taxSum.Apttus_Config2__PriceUom__c,APTS_CPQConstants.KG_UOM_API,productcodeProductIDMap.get(taxSum.Apttus_Config2__ProductId__c));
                } 
                taxSum.APTS_Tax_per_UOM__c = taxSum.APTS_TAX_all_countries_UOM__c + taxSum.APTS_TAX_DK_specific_UOM__c;
            }
        }     
                
        psToBeUpdatedList=psToBeUpdated.Values();
        if(!psToBeUpdatedList.IsEmpty()){
            Database.upsert(psToBeUpdatedList,false);
        }
                
        return pliToBoUpsertedMap;
    }
    

    /** Method Name : mapPLIFields
    * Description : Method to map PLI fields with Pricing Staging, Product2 and Sales Org Data field values
    **/
    public static Apttus_Config2__PriceListItem__c mapPLIFields(APTS_Pricing_Staging__c thisPricingStaging, Apttus_Config2__PriceListItem__c thisPriceListItem,APTS_Sales_Org_Data__c thisSalesOrg, Map<String, Product2> productMap){
        Map<String, String> pricingStagingToPLIFieldsMap = getPricingStagingToPLIFieldsMapping();
        Map<String, Integer> taxAmendmentMap = getTaxAmendmentValues();
        System.debug('thisSalesOrg======>'+thisSalesOrg);
        //Associate salesorg with pricelistitems
        thisPriceListItem.APTS_Related_sales_org_data__c=thisSalesOrg.id;
        for(String pricingStagingField : pricingStagingToPLIFieldsMap.keySet()){
            String priceListItemField = pricingStagingToPLIFieldsMap.get(pricingStagingField);
            if(thisPricingStaging.get(pricingStagingField) != null){
                try{
               
                    thisPriceListItem.put(priceListItemField, thisPricingStaging.get(pricingStagingField));
                }catch(Exception ex){}
            }
        }
                System.debug('List Price Map'+thisPricingStaging.APTS_List_Price__c+thisPricingStaging.APTS_SAP_ListPriceUnits__c+thisPriceListItem.Apttus_Config2__ListPrice__c);

        if(thisPricingStaging.APTS_SAP_ListPriceUnits__c!=null && thisPricingStaging.APTS_SAP_ListPriceUnits__c!=0){
            thisPriceListItem.Apttus_Config2__ListPrice__c = thisPricingStaging.APTS_List_Price__c / thisPricingStaging.APTS_SAP_ListPriceUnits__c;
        }
        try{
            List<APTS_Transactional_UOM__c> transUOMS = APTS_Transactional_UOM__c.getall().values();
            Set<String> transactionalUOMS = new Set<String>();      
            for(APTS_Transactional_UOM__c tom : transUOMS )
            {
                transactionalUOMS.add(tom.name);
            }
            String chargeType = getChargeType(thisPricingStaging.APTS_Condition_Type__c,thisPricingStaging.APTS_Product_Code__c);
            String priceType = getPriceType(thisPricingStaging.APTS_Condition_Type__c, thisPricingStaging.APTS_Calculation_Type__c);
            String taxKey = thisPricingStaging.APTS_Sales_Organization__c+ Label.APTS_Pipe_Symbol+ Integer.valueOf(thisSalesOrg.APTS_VAT_Indicator__c);
             // External id OF PLI Changes 
            String PricingStagingPLIUnique = thisPricingStaging.APTS_PLI_Unique_Identifier__c;
            if(PricingStagingPLIUnique.contains('ZCONT'))
            {
            String plisubstring = PricingStagingPLIUnique.substringAfter('ZCONT');
            String pliAfter = plisubstring.right(plisubstring.length()-1);
            String pliData= PricingStagingPLIUnique.substringBefore('ZCONT');
            String pliExtidFinal= pliData+pliAfter;            
            thisPriceListItem.APTS_PriceListItemExtId__c = pliExtidFinal;
            }
            else
            {
                 System.debug('Sales Service External ID ');
                thisPriceListItem.APTS_PriceListItemExtId__c= thisPricingStaging.APTS_PLI_Unique_Identifier__c;
            }
            /*Below lines are commented as part of Defect - 15418 
            Updated summary 20/06 Desmond-  Remove logic to populate these fields 
            1) Price List Item   - Auto Renew 
            2) Price List Item  - Auto Renewal Term 
            //thisPriceListItem.Apttus_Config2__AutoRenew__c = priceType == Label.Apttus_CPQAdmin.Recurring;
            //thisPriceListItem.Apttus_Config2__AutoRenewalTerm__c = getAutoRenewalTerm(thisPriceListItem.Apttus_Config2__Frequency__c);
            */
            thisPriceListItem.Apttus_Config2__Frequency__c = getFrequency(thisPricingStaging.APTS_Calculation_Type__c);
            //thisPriceListItem.Apttus_Config2__AutoCascadeSellingTerm__c = (chargeType == Label.APTS_Service_Fee || chargeType == Label.APTS_Rental_Price || chargetype == Label.APTS_Additional_Service_Fees) && priceType == Label.Apttus_CPQAdmin.Recurring; //Lavanya ASF change
            /* Commented as part of CR - Billing Frequency and Billing rules to be driven based on condition type suggested by Desmond */
            //thisPriceListItem.Apttus_Config2__BillingFrequency__c = getBillingFrequency(priceType, thisPriceListItem.Apttus_Config2__Frequency__c);
            //thisPriceListItem.Apttus_Config2__BillingRule__c = getBillingRule(priceType, thisPriceListItem.Apttus_Config2__Frequency__c);
            thisPriceListItem.Apttus_Config2__Sequence__c = getSequence(chargeType);
            System.debug('**here0');
            if(String.IsNotBlank(thisSalesOrg.APTS_Cost_Price__c) && String.IsNotBlank(thisSalesOrg.APTS_Cost_Price_Unit__c)){
                thisPriceListItem.Apttus_Config2__Cost__c = Decimal.valueOf(thisSalesOrg.APTS_Cost_Price__c) / Decimal.valueOf(thisSalesOrg.APTS_Cost_Price_Unit__c);
                System.debug('@@@');
                System.debug(thisPriceListItem.Apttus_Config2__Cost__c);
            }
            //thisPriceListItem.APTS_Cost__c = cost price from default plant;
            if(productMap.containsKey(thisPricingStaging.APTS_Product_Code__c)){
                //thisPriceListItem.APTS_Material_Pricing_Group__c = productMap.get(thisPricingStaging.APTS_Product_Code__c).APTS_Material_Pricing_Group__c ;
            }
            thisPriceListItem.Apttus_Config2__PriceMethod__c = Label.Apttus_CPQAdmin.PerUnit;
            thisPriceListItem.Apttus_Config2__PriceType__c = priceType;
            thisPriceListItem.Apttus_Config2__ProductId__c = productMap.containsKey(thisPricingStaging.APTS_Product_Code__c) ? productMap.get(thisPricingStaging.APTS_Product_Code__c).Id : EMPTY_STRING;
            if(thisPriceListItem.Apttus_Config2__PriceListId__c==null) thisPriceListItem.Apttus_Config2__PriceListId__c = thisSalesOrg.APTS_Price_List__c;
            System.debug('**here1');
                if(transactionalUOMS.contains(thisSalesOrg.APTS_Selling_Unit__c)) 
                thisPriceListItem.APTS_Default_Selling_Uom__c = thisSalesOrg.APTS_Selling_Unit__c;
                else
                thisPriceListItem.APTS_Default_Selling_Uom__c = '';
            System.debug('**here2');
            thisPriceListItem.Apttus_Config2__PriceUom__c = thisPricingStaging.APTS_Price_Uom__c;
            thisPriceListItem.Apttus_Config2__ChargeType__c = chargeType;
            System.debug(thisPricingStaging.APTS_Condition_Type__c+'**listmap1'+thisPricingStaging.APTS_List_Price__c+thisPricingStaging.APTS_SAP_ListPriceUnits__c+thisPriceListItem.Apttus_Config2__ListPrice__c+(thisPricingStaging.APTS_List_Price__c/thisPricingStaging.APTS_SAP_ListPriceUnits__c).setScale(5));
            if(thisPricingStaging.APTS_SAP_ListPriceUnits__c!=null && thisPricingStaging.APTS_SAP_ListPriceUnits__c!=0){
                thisPriceListItem.Apttus_Config2__ListPrice__c=(thisPricingStaging.APTS_List_Price__c/thisPricingStaging.APTS_SAP_ListPriceUnits__c).setScale(5);
            
            }
            if(!taxAmendmentMap.IsEmpty() && taxAmendmentMap.containsKey(taxKey)){
                thisPriceListItem.APTS_VAT_percentage__c =  taxAmendmentMap.get(taxKey);
            }
            //Billing Frequency and Billing rule changes based on contract type suggested by Desmond 
            
            thisPriceListItem.Apttus_Config2__BillingRule__c = APTS_CPQConstants.LABEL_BILL_IN_ADVANCE;
            List<String> TempBillingSet = new List<String>();
            TempBillingSet = System.Label.APTS_BillingFrequencyRestriction.split(',');
            if(thisPricingStaging.APTS_Condition_Type__c==Label.APTS_Z000) {
             if(!TempBillingSet.contains(productMap.get(thisPricingStaging.APTS_Product_Code__c).APTS_Option_Group_Indicator__c) && productMap.get(thisPricingStaging.APTS_Product_Code__c).Name != Label.APTS_FREIGHT_CHARGES_PRODUCT_NAME && productMap.get(thisPricingStaging.APTS_Product_Code__c).Name != Label.APTS_Internal_Movement && productMap.get(thisPricingStaging.APTS_Product_Code__c).Name != Label.APTS_External_Movement)
                thisPriceListItem.Apttus_Config2__BillingFrequency__c = APTS_CPQConstants.LABEL_ONE_TIME;               
            }else{
                if(thisPricingStaging.APTS_Condition_Type__c == Label.APTS_YRF0){
                    thisPriceListItem.APTS_Lowest_Contract_Period__c=thisPricingStaging.APTS_Contract_Period__c;
                    thisPriceListItem.APTS_Lowest_List_Price__c=thisPricingStaging.APTS_List_Price__c/thisPricingStaging.APTS_SAP_ListPriceUnits__c;
                    thisPriceListItem.Apttus_Config2__ListPrice__c=thisPriceListItem.APTS_Lowest_List_Price__c;
                    System.debug('**listmap2'+thisPriceListItem.APTS_Lowest_List_Price__c);
                }
                if(!TempBillingSet.contains(productMap.get(thisPricingStaging.APTS_Product_Code__c).APTS_Option_Group_Indicator__c)   && productMap.get(thisPricingStaging.APTS_Product_Code__c).Name != Label.APTS_FREIGHT_CHARGES_PRODUCT_NAME && productMap.get(thisPricingStaging.APTS_Product_Code__c).Name != Label.APTS_Internal_Movement && productMap.get(thisPricingStaging.APTS_Product_Code__c).Name != Label.APTS_External_Movement)
                thisPriceListItem.Apttus_Config2__BillingFrequency__c=APTS_CPQConstants.LABEL_MONTHLY; 
            }
            //Added change to populate VAT indicator from Sales org to Price list item
            System.debug('thisSalesOrg.APTS_VAT_Indicator__c=====>'+thisSalesOrg.APTS_VAT_Indicator__c);
            if(thisSalesOrg!=null && thisSalesOrg.APTS_VAT_Indicator__c!=null){
                thisPriceListItem.APTS_VAT_indicator__c = Integer.valueOf(thisSalesOrg.APTS_VAT_Indicator__c);
            }
        }catch(Exception ex){System.debug('**exception'+ex.getStackTraceString()+ex.getMessage());}
        return thisPriceListItem;
    }
    
    /** Method Name : updateLowestContractPeriodPrice
    * Description : Method to Update the list price on rental PLI with the lowest contract period price
    **/

    public static Map<String, Apttus_Config2__PriceListItem__c> updateLowestContractPeriodPrice(Map<String,Apttus_Config2__PriceListItem__c> prodToPLIMap,Map<String, Apttus_Config2__PriceListItem__c> pliToBoUpsertedMap,Map<String, List<Integer>> mapOfContractPeriods,Map<String, Map<String, Decimal>> mapOfListPrice) {        
        
        for(string contPeriod:mapOfContractPeriods.keySet()){
            Apttus_Config2__PriceListItem__c existingPLI=new Apttus_Config2__PriceListItem__c ();
            Integer lowestContPeriodNum =12;
            Integer currentContract =12;
            List<Integer> listOfContNums = mapOfContractPeriods.get(contPeriod);
            listOfContNums.sort();
            //get the lowest contract period
            lowestContPeriodNum = getLowestContractPeriodNumber(listOfContNums);
            if(pliToBoUpsertedMap.containsKey(contPeriod)){
                existingPLI = pliToBoUpsertedMap.get(contPeriod);
            }
            else if(prodToPLIMap.containsKey(contPeriod)){
                existingPLI = prodToPLIMap.get(contPeriod);
            }
            if(existingPLI.APTS_Lowest_Contract_Period__c!=null){
                currentContract = Integer.valueOf(existingPLI.APTS_Lowest_Contract_Period__c.substring(5));
            }
            if(currentContract > lowestContPeriodNum){
                existingPLI.APTS_Lowest_Contract_Period__c=Label.APTS_ZCONT+lowestContPeriodNum;
                existingPLI.APTS_Lowest_List_Price__c=mapOfListPrice.get(contPeriod).get(Label.APTS_ZCONT+lowestContPeriodNum);
                existingPLI.Apttus_Config2__ListPrice__c=(mapOfListPrice.get(contPeriod).get(Label.APTS_ZCONT+lowestContPeriodNum));
                pliToBoUpsertedMap.put(contPeriod,existingPLI);
            }
            else{
                existingPLI.Apttus_Config2__ListPrice__c=existingPLI.APTS_Lowest_List_Price__c;
                pliToBoUpsertedMap.put(contPeriod,existingPLI);
            }
        }
        return pliToBoUpsertedMap;
    }       

    /** Method Name : getLowestContractPeriodNumber
    * Description : Method to get the lowest contract period for a pli
    **/
    
     public static Integer getLowestContractPeriodNumber(List<Integer> listOfContractPeriodNum) {
        Integer smallest = 12;
        for(Integer i : listOfContractPeriodNum) {
            if(smallest > i) {
                smallest = i;
            }
        }
        return smallest;
     }
    
    /** Method Name : getPriceType
    * Description : Method to get Price Type value based on Condition Type and Calculation Type field values
    **/
    public static String getPriceType(String conditionType, String calculationType){
        String priceType = EMPTY_STRING;
        if(String.IsNotBlank(conditionType)){
            if(conditionType == Label.APTS_Z000){
                priceType = Label.Apttus_CPQAdmin.OneTime;
            }else if((conditionType == Label.APTS_YRF0 || conditionType == Label.APTS_YSF1) && String.IsNotBlank(calculationType) && 
                    (calculationType == Label.APTS_CalcType_M || calculationType == Label.APTS_CalcType_N || calculationType == Label.APTS_CalcType_O || calculationType == Label.APTS_CalcType_P)){
                priceType = Label.Apttus_CPQAdmin.Recurring;
            }else{
                priceType = Label.Apttus_CPQAdmin.OneTime;
            }
        }
        return priceType;
    }
    
     /** Method Name : getChargeType
    * Description : Method to get Charge Type value based on Condition Type field value
    **/
    public static String getChargeType(String conditionType){
    String chargeType = EMPTY_STRING;
        if(String.IsNotBlank(conditionType)){
            if(conditionType == Label.APTS_Z000){
                chargeType = Label.APTS_Sales_Price;
            }else if(conditionType == Label.APTS_YRF0){
                chargeType = Label.APTS_Rental_Price;
            }else if(conditionType == Label.APTS_YSF1 || conditionType == Label.APTS_YSFL || conditionType == Label.APTS_YSFC || conditionType == Label.APTS_YSFS){
                chargeType = Label.APTS_Additional_Service_Fees;
            }
        }
        return chargeType;
    }
   
      /** Method Name : getChargeType
    * Description : Method to get Charge Type value based on Condition Type field value
    **/
    public static String getChargeType(String conditionType,String productCode){
    String chargeType = EMPTY_STRING;
    List<String> tempIng = new List<String>();
    tempIng = System.Label.APTS_Additional_service_OG_indicators.split(',');
    Set<String> SetProductCodes = new Set<String>();
    SetProductCodes.add(productCode);
        if(String.IsNotBlank(conditionType)){
            if(conditionType == Label.APTS_Z000){
                chargeType = Label.APTS_Sales_Price;
            }else if(conditionType == Label.APTS_YRF0){
                chargeType = Label.APTS_Rental_Price;
            }else if(conditionType == Label.APTS_YSF1)
            {
                Map<String,Product2> mapPro = new Map<String,Product2>();
                mapPro = mapOfProducts(productCode);  
                if(productCode!=null && !mapPro.isEmpty() && mapPro.get(productCode)!=null && mapPro.get(productCode).APTS_Option_Group_Indicator__c != null && tempIng!=null && tempIng.contains(mapPro.get(productCode).APTS_Option_Group_Indicator__c)){
                    chargeType = Label.APTS_Additional_Service_Fees;
                }
            }
            else if(conditionType == Label.APTS_YSFL || conditionType == Label.APTS_YSFC || conditionType == Label.APTS_YSFS)
                chargeType = Label.APTS_Additional_Service_Fees;
            }
        return chargeType;
    }
    /** Method Name : getFrequency
    * Description : Method to get Frequency value based on Calculation Type field value
    **/
    public static String getFrequency(String calculationType){
        String freqValue = EMPTY_STRING;
        if(String.IsNotBlank(calculationType)){
            if(calculationType == Label.APTS_CalcType_M){
                freqValue = Label.APTS_Monthly;
            }else if(calculationType == Label.APTS_CalcType_N){
                freqValue = Label.APTS_Yearly;
            }else if(calculationType == Label.APTS_CalcType_O){
                freqValue = Label.APTS_Daily;
            }else if(calculationType == Label.APTS_CalcType_P){
                freqValue = Label.APTS_Weekly;
            }else if(calculationType == Label.APTS_CalcType_C){
                freqValue = Label.APTS_OneTime;
            }
        }
        return freqValue;
    }

    // Commented because of code coverage and not being used anymore   - START
    
    /** Method Name : getBillingFrequency
    * Description : Method to get Billing Frequency value based on Price Type and Frequency values
    **/
    /*
    public static String getBillingFrequency(String conditionType,String productCode){
        String billingFreq = EMPTY_STRING;
        if(String.IsNotBlank(priceType)){
            if(priceType == Label.Apttus_CPQAdmin.OneTime){
                billingFreq = Label.Apttus_CPQAdmin.OneTime;
            }else if(priceType == Label.Apttus_CPQAdmin.Recurring && frequency == Label.APTS_Monthly){
                billingFreq = Label.APTS_Monthly;
            }
        }
        return billingFreq;
    }*/
    
    /** Method Name : getBillingRule
    * Description : Method to get Billing Rule value based on Price Type and Frequency values
    **/
    /*
    public static String getBillingRule(String priceType, String frequency){
        String billingRule = EMPTY_STRING;
        if(String.IsNotBlank(priceType) && (priceType == Label.Apttus_CPQAdmin.OneTime || (priceType == Label.Apttus_CPQAdmin.Recurring && frequency == Label.APTS_Monthly))){
            billingRule = Label.APTS_Bill_In_Advance;
        }
        return billingRule;
    }*/
    
    /** Method Name : getAutoRenewalTerm
    * Description : Method to get Auto Renewal Term value based on Frequency value
    **/
    /*
    public static Integer getAutoRenewalTerm(String frequency){
        Integer renewalTerm;
        if(String.IsNotBlank(frequency)){
            if(frequency == Label.APTS_Monthly){
                renewalTerm = 12;
            }else if(frequency == Label.APTS_Yearly){
                renewalTerm = 1;
            }else if(frequency == Label.APTS_Daily){
                renewalTerm = 365;
            }else if(frequency == Label.APTS_Weekly){
                renewalTerm = 52;
            }else if(frequency == Label.APTS_OneTime){
                renewalTerm = 0;
            }
        }
        return renewalTerm;
    }*/
    // Commented because of code coverage and not being used anymore   - END

    /** Method Name : getSequence
    * Description : Method to get Sequence value based on Charge Type value
    **/
    public static Integer getSequence(String chargeType){
        Integer sequence;
        if(String.IsNotBlank(chargeType)){
            if(chargeType == Label.APTS_Sales_Price){
                sequence = 1;
            }else if(chargeType == Label.APTS_Rental_Price){
                sequence = 2;
            }else if(chargeType == Label.APTS_Additional_Service_Fees){ //Lavanya ASF change
                sequence = 3;
            }
        }
        return sequence;
    }
    
    /** Method Name : getSellingTermPDId
    * Description : Method to get 'Selling Term' record ID of 'Price Dimension' object
    **/
    public static String getSellingTermPDId(){
        String sellingTermPDId = EMPTY_STRING;
        APTS_ProductPricingBatchSettings__c custSetting = APTS_ProductPricingBatchSettings__c.getInstance();
        sellingTermPDId = custSetting != null ? custSetting.APTS_Selling_Term_Price_Dimension_Rec_ID__c : EMPTY_STRING;
        
        return sellingTermPDId;
    }
    
    /** Method Name : createPriceMatrix
    * Description : Method to create Price Matrix record for a list of PLI records
    **/
    public static List<Apttus_Config2__PriceMatrix__c> createPriceMatrix(List<Apttus_Config2__PriceListItem__c> pliList){
        String priceDimensionId = getSellingTermPDId();
        List<Apttus_Config2__PriceMatrix__c> priceMatrixList = new List<Apttus_Config2__PriceMatrix__c>();
        for(Apttus_Config2__PriceListItem__c pLI : pliList){
            if(pLI != null && String.IsNotBlank(pLI.Id)){
                Apttus_Config2__PriceMatrix__c priceMatrix = new Apttus_Config2__PriceMatrix__c();
                if(String.IsNotBlank(pLI.APTS_PriceListItemExtId__c)){
                   // String pLIExtIdAfter = pLI.APTS_PriceListItemExtId__c.substringAfter('ZCONT');
                   // String pMExtId = (pLI.APTS_PriceListItemExtId__c.substringBefore('ZCONT')+pLIExtIdAfter.replace(pLIExtIdAfter.left(1),'')).deleteWhitespace();
                     priceMatrix.APTS_PriceMatrixExtId__c = pLI.APTS_PriceListItemExtId__c + Label.APTS_Pipe_Symbol + Label.APTS_Matrix;
                   // priceMatrix.APTS_PriceMatrixExtId__c = pMExtId + Label.APTS_Pipe_Symbol + Label.APTS_Matrix;
                }
                priceMatrix.Apttus_Config2__Description__c = pLI.Apttus_Config2__Description__c;
                priceMatrix.Apttus_Config2__Dimension1Id__c = priceDimensionId;
                priceMatrix.Apttus_Config2__Dimension1ValueType__c = Label.APTS_Range;
                priceMatrix.Apttus_Config2__MatrixType__c = pLI.APTS_PriceListItemExtId__c.contains(Label.APTS_YRF0) ? Label.Apttus_CPQAdmin.Dimension : EMPTY_STRING;
                priceMatrix.Apttus_Config2__PriceListItemId__c = pLI.Id;
                priceMatrix.Apttus_Config2__Sequence__c = 1;
                priceMatrix.Apttus_Config2__StopProcessingMoreMatrices__c = false;
                priceMatrixList.add(priceMatrix);
            }
        }
        return priceMatrixList;
    }
    
    /** Method Name : createPriceMatrixEntry
    * Description : Method to create Price Matrix record for a list of PLI and list of PM records
    **/
    public static List<Apttus_Config2__PriceMatrixEntry__c> createPriceMatrixEntry(List<Apttus_Config2__PriceMatrix__c> pmList, List<Apttus_Config2__PriceListItem__c> pliList, Map<String, List<Integer>> conPeriodMap, Map<String, Map<String, Decimal>> listPriceMap){
        Map<String, String> pmMap = new Map<String, String>();
        Map<String, APTS_Pricing_Staging_Contract_Mapping__mdt> pricingStagingContractMap = getPricingStagingContractMapping();
        for(Apttus_Config2__PriceMatrix__c pm : pmList){
            pmMap.put(pm.Apttus_Config2__PriceListItemId__c, pm.Id);            
        }
        List<Apttus_Config2__PriceMatrixEntry__c> pmeList = new List<Apttus_Config2__PriceMatrixEntry__c> ();
        for(Apttus_Config2__PriceListItem__c pli : pliList){
            if(pli != null && String.IsNotBlank(pli.Id) && conPeriodMap != null && listPriceMap != null){
                String key = pli.APTS_Product_Code__c+pli.APTS_Sales_Organization__c+getChargeType(pli.APTS_ConditionType__c);
                if(conPeriodMap.containsKey(key)){
                    for(Integer i : conPeriodMap.get(key)){
                        Apttus_Config2__PriceMatrixEntry__c pme = new Apttus_Config2__PriceMatrixEntry__c();
                        pme.Apttus_Config2__AdjustmentAmount__c = listPriceMap.get(key).get(Label.APTS_ZCONT+i);
                        pme.Apttus_Config2__AdjustmentType__c = Label.APTS_List_Price_Override;
                        pme.APTS_PriceMatrixEntryExtId__c = pli.APTS_PriceListItemExtId__c + Label.APTS_Pipe_Symbol + Label.APTS_ZCONT +i;
                        pme.Apttus_Config2__Dimension1Value__c = String.valueOf(pricingStagingContractMap.get(Label.APTS_ZCONT+i).APTS_Dimension__c);
                        pme.Apttus_Config2__Sequence__c = pricingStagingContractMap.get(Label.APTS_ZCONT+i).APTS_Sequence__c;
                        pme.Apttus_Config2__PriceMatrixId__c = pmMap.containsKey(pli.Id) ? pmMap.get(pli.Id) : EMPTY_STRING;
                        pmeList.add(pme);
                    }
                }
            }
        }
        return pmeList;
    }
    
    /** Method Name : updateCTC
    * Description : Method to update the Charge Type Criteria field of Option Products associated to 'Machine Tab' Category
    **/
    
    public static Map<String,Apttus_Config2__PriceListItem__c> updateCTC(Map<String,Product2> activeProductMap, Map<String,Apttus_Config2__PriceListItem__c> pliToBoUpsertedMap, Map<String,Apttus_Config2__PriceListItem__c> prodToPLIMap){
        
        Map<Id, Product2> optionProdIdMap = new Map<Id, Product2>();
        Map<String, String> pliCTCMap = getPLIChargeTypeCriteriaMapping();
        Set<String> updatedPLI=new Set<String>();
        
        for(Product2 prod : activeProductMap.values()){
            if(prod.Apttus_Config2__ConfigurationType__c == Label.APTS_Option && prod.APTS_Material_Type__c == Label.APTS_ZOPT && String.IsNotBlank(prod.APTS_Option_Group_Indicator__c)){
                if(prod.APTS_Option_Group_Indicator__c.startsWith('01')){
                    optionProdIdMap.put(prod.Id, prod);
                }
            }
        }

        for(String str : pliToBoUpsertedMap.keySet()){
            if(String.IsNotBlank(str) && (!str.contains(Label.APTS_Service_Fee) || !str.contains(Label.APTS_Additional_Service_Fees)) &&  optionProdIdMap.containsKey(pliToBoUpsertedMap.get(str).Apttus_Config2__ProductId__c) && !updatedPLI.contains(str)){
                String tempStr='';
                String tempChargeType='';
                String chargeType='';
                if(str.contains(Label.APTS_Sales_Price)){
                    tempStr=str.replace(Label.APTS_Sales_Price,Label.APTS_Rental_Price);
                    chargeType=Label.APTS_Sales_Price;
                    tempChargeType=Label.APTS_Rental_Price;
                }
                else if(str.contains(Label.APTS_Rental_Price)){
                    tempStr=str.replace(Label.APTS_Rental_Price,Label.APTS_Sales_Price);
                    chargeType=Label.APTS_Rental_Price;
                    tempChargeType=Label.APTS_Sales_Price;
                }
                
                //Check if the sales and rental pli are available for the product and then apply CTC
                if(pliToBoUpsertedMap.containsKey(tempStr) || prodToPLIMap.containsKey(tempStr)){
                    Apttus_Config2__PriceListItem__c pli=pliToBoUpsertedMap.get(str);
                    
                    if(pliCTCMap.containsKey(chargeType) && pliCTCMap.get(chargeType) !=null && pliCTCMap.get(chargeType) !=''){
                        pli.Apttus_Config2__Criteria__c = pliCTCMap.get(chargeType);
                        pliToBoUpsertedMap.put(pli.APTS_Product_Code__c+pli.APTS_Sales_Organization__c+pli.Apttus_Config2__ChargeType__c, pli);
                    }
                    
                    //To update the other pli
                    Apttus_Config2__PriceListItem__c tempPli=new Apttus_Config2__PriceListItem__c();
                    if(pliToBoUpsertedMap.containsKey(tempStr)){ 
                        tempPli = pliToBoUpsertedMap.get(tempStr);
                    }
                    else{
                        tempPli = prodToPLIMap.get(tempStr);
                    }
                    if(pliCTCMap.containsKey(tempChargeType) && pliCTCMap.get(tempChargeType) !=null && pliCTCMap.get(tempChargeType) !=''){
                        tempPli.Apttus_Config2__Criteria__c = pliCTCMap.get(tempChargeType);
                        updatedPLI.add(tempStr); //add the other pli to a set to prevent it from being updated again
                        pliToBoUpsertedMap.put(tempPli.APTS_Product_Code__c+tempPli.APTS_Sales_Organization__c+tempPli.Apttus_Config2__ChargeType__c, tempPli);
                    }
                }
                        
            }
        }
        return pliToBoUpsertedMap;
    }
    
     /** Method Name : mapOfProducts
    * Description : Method to get the map of products for a set of Product Codes
    **/
    public static Map<String, Product2> mapOfProducts(String productCode) {        
        
        Map<String, Product2> prodCodeMap = new Map<String, Product2>();
        String query = getObjectQuery('Product2');
        query += Label.APTS_Product2_Query;
        for(Product2 prod : Database.query(query)){
           prodCodeMap.put(prod.ProductCode,prod) ;
        } System.debug('ASF'+prodCodeMap);
        return prodCodeMap;
    }


    /** Method Name : mapOfProducts
    * Description : Method to get the map of products for a set of Product Codes
    **/
    public static Map<String, Product2> mapOfProducts(Set<String> relatedProductCodes) { 
        
        Set<string> processedCodes=new Set<string>();
        for(String str:relatedProductCodes){
            str='%'+str+'%';
            processedCodes.add(str);
        }
        Map<String, Product2> prodMap = new Map<String, Product2>();
        String query = getObjectQuery(Label.Apttus_CPQAdmin.Product2);
        query += Label.APTS_Product2Query;
        for(Product2 prod : Database.query(query)){
            prodMap.put(prod.ProductCode, prod);
            if(prod.APTS_Replaced_by__c != null && prod.APTS_Replaced_by__c!= ''){
                List<string> tempList=new List<String>();
                tempList=prod.APTS_Replaced_by__c.split(system.label.APTS_CommaSeparator);
                for(String str:tempList){
                    prodMap.put(str,prod);
                }
            }
        }
        return prodMap;
    }
    /** Method Name : mapOfProducts
    * Description : Method to get the map of products for a set of Product Codes
    **/
    public static Map<string,APTS_Product_Replacement_Codes__c> getReplacedRecords(Map<String,Product2> activeProductMap,Map<String,APTS_Sales_Org_Data__c> activeSalesOrgPLMap) { 
        
        Map<string,APTS_Product_Replacement_Codes__c> relatedReplacementMap=new Map<string,APTS_Product_Replacement_Codes__c>();
        Set<Id> prodIdSet = new Set<Id>();
        for(Product2 prod:activeProductMap.Values()){
            prodIdSet.add(prod.Id);
        }
        
        Set<String> salesOrgList=new Set<String>(activeSalesOrgPLMap.KeySet());
        String query = getObjectQuery('APTS_Product_Replacement_Codes__c');
        query += 'WHERE APTS_Product__c IN : prodIdSet AND APTS_Sales_Org__c IN : salesOrgList';
        
        for(APTS_Product_Replacement_Codes__c replProd : Database.query(query)){
            relatedReplacementMap.put(replProd.APTS_Replacement_Product_Code__c+replProd.APTS_Sales_Org__c, replProd);
        }
        return relatedReplacementMap;
    }
    
    /** Method Name : getExistingPriceListItems
    * Description : Method to get existing PLI records for list of Products and Pricelists
    **/
    public static Map<String,Apttus_Config2__PriceListItem__c> getExistingPriceListItems(Map<String,Product2> activeProductMap,Map<String,APTS_Sales_Org_Data__c> allSalesOrgPLMap){
        
        Map<String,Apttus_Config2__PriceListItem__c> prodToPLIMap=new Map<String,Apttus_Config2__PriceListItem__c>();
        Set<Id> prodIdSet = new Set<Id>();
        for(Product2 prod:activeProductMap.Values()){
            prodIdSet.add(prod.Id);
        }
        
        Set<Id> plIds = new Set<Id>();
        for(APTS_Sales_Org_Data__c org:allSalesOrgPLMap.values()){
            plIds.add(org.APTS_Price_List__c);
        }
        
        String query = getObjectQuery(Label.APTS_PLIObject);
        query += Label.APTS_PLIQuery;
        
        for(Apttus_Config2__PriceListItem__c pli:Database.query(query)){
            prodToPLIMap.put(pli.APTS_Product_Code__c+pli.APTS_Sales_Organization__c+pli.Apttus_Config2__ChargeType__c,pli);
        }
        return prodToPLIMap;
    }
    
    
    /** Method Name : getExistingInactivePriceListItems
    * Description : Method to get existing Inactive PLI records for list of Products and Pricelists
    **/
    public static Map<String,Apttus_Config2__PriceListItem__c> getExistingInactivePriceListItems(Map<String,Product2> activeProductMap,Map<String,APTS_Sales_Org_Data__c> allSalesOrgPLMap){
        
        Map<String,Apttus_Config2__PriceListItem__c> prodToPLIInactiveMap=new Map<String,Apttus_Config2__PriceListItem__c>();
        Set<Id> prodIdSet = new Set<Id>();
        for(Product2 prod:activeProductMap.Values()){
            prodIdSet.add(prod.Id);
        }
        
        Set<Id> plIds = new Set<Id>();
        for(APTS_Sales_Org_Data__c org:allSalesOrgPLMap.values()){
            plIds.add(org.APTS_Price_List__c);
        }
        
        String query = getObjectQuery(Label.APTS_PLIObject);
        query+= Label.APTS_PLIInactiveQuery;
        
        for(Apttus_Config2__PriceListItem__c pli:Database.query(query)){
            prodToPLIInactiveMap.put(pli.APTS_Product_Code__c+pli.APTS_Sales_Organization__c+pli.Apttus_Config2__ChargeType__c,pli);
        }
        return prodToPLIInactiveMap;
    }
    
    /** Method Name : getExistingPLPM
    * Description : Method to get existing Price Matrix from List<PLI>
    **/
    public static Map<Id,Apttus_Config2__PriceMatrix__c> getExistingPLPM(List<Apttus_Config2__PriceListItem__c> pLIList){
        Map<Id,Apttus_Config2__PriceMatrix__c> existingPLPMMap = new Map<Id,Apttus_Config2__PriceMatrix__c>();
        Set<Id> pLIIdSet = new Set<Id>(new Map<Id,Apttus_Config2__PriceListItem__c>(pLIList).keySet());
       
        String priceDimensionId = getSellingTermPDId();
        
        for(Apttus_Config2__PriceMatrix__c pM : [SELECT Id, Apttus_Config2__PriceListItemId__c, Apttus_Config2__Dimension1Id__c, (SELECT Id, Apttus_Config2__PriceMatrixId__c, APTS_PriceMatrixEntryExtId__c,Apttus_Config2__Sequence__c, Apttus_Config2__AdjustmentAmount__c FROM Apttus_Config2__MatrixEntries__r) FROM Apttus_Config2__PriceMatrix__c WHERE Apttus_Config2__PriceListItemId__c IN: pLIIdSet AND Apttus_Config2__Dimension1Id__c =: priceDimensionId ]){
                        
       
           
              
                if(existingPLPMMap.containsKey(pM.Apttus_Config2__PriceListItemId__c)){
                
                Apttus_Config2__PriceMatrix__c tempPM = new Apttus_Config2__PriceMatrix__c();
                    tempPM = existingPLPMMap.get(pM.Apttus_Config2__PriceListItemId__c);                    
                    existingPLPMMap.put(pM.Apttus_Config2__PriceListItemId__c,tempPM);
                }else{
                
                  existingPLPMMap.put(pM.Apttus_Config2__PriceListItemId__c,pM);
                }
            
        }   System.debug('PricingDistributionBatchHandler PLPMMap'+existingPLPMMap);
        return existingPLPMMap;
    }
    
    /** Method Name : getExistingPMsPMEs
    * Description : Method to get existing Price Matrix and Price Matrix Entry records for a list of PLI
    **/
 public static Map<Apttus_Config2__PriceMatrix__c, Map<String, Apttus_Config2__PriceMatrixEntry__c>> getExistingPMsPMEs(List<Apttus_Config2__PriceListItem__c> pLIList){
        Map<Apttus_Config2__PriceMatrix__c, Map<String, Apttus_Config2__PriceMatrixEntry__c>> existingPMPMEMap = new Map<Apttus_Config2__PriceMatrix__c, Map<String, Apttus_Config2__PriceMatrixEntry__c>>();
        Set<Id> pLIIdSet = new Set<Id>(new Map<Id,Apttus_Config2__PriceListItem__c>(pLIList).keySet());
        
        String priceDimensionId = getSellingTermPDId();
        
        for(Apttus_Config2__PriceMatrix__c pM : [SELECT Id, Apttus_Config2__PriceListItemId__c, Apttus_Config2__Dimension1Id__c, (SELECT Id, Apttus_Config2__PriceMatrixId__c, APTS_PriceMatrixEntryExtId__c,Apttus_Config2__Sequence__c, Apttus_Config2__AdjustmentAmount__c FROM Apttus_Config2__MatrixEntries__r) FROM Apttus_Config2__PriceMatrix__c WHERE Apttus_Config2__PriceListItemId__c IN: pLIIdSet AND Apttus_Config2__Dimension1Id__c =: priceDimensionId]){
        System.debug('Lavanya Inside first for');
            for(Apttus_Config2__PriceMatrixEntry__c pME : pM.Apttus_Config2__MatrixEntries__r){
            System.debug('Lavnya Inside 2nd for');
                Map<String, Apttus_Config2__PriceMatrixEntry__c> pMEMap = new Map<String, Apttus_Config2__PriceMatrixEntry__c>();
                  System.debug('Lavanya Contains PM 1'+PM);
                if(existingPMPMEMap.containsKey(pM)){
                    System.debug('Lavanya Contains PM 2'+PM);
              
                    pMEMap = existingPMPMEMap.get(pM);
                    pMEMap.put(Label.APTS_ZCONT+pME.Apttus_Config2__Sequence__c, pME);
                    System.debug('Lavanya Contains PMMap 1'+pMEMap);
                    existingPMPMEMap.put(pM, pMEMap);
                }else{
                   
                    pMEMap.put(Label.APTS_ZCONT+pME.Apttus_Config2__Sequence__c, pME);
                    existingPMPMEMap.put(pM, pMEMap);
                      System.debug('Lavanya Contains PMMap 2'+pMEMap);
                }
            }
        }  
        return existingPMPMEMap;
    }

    /** Method Name : mapPMEFields
    * Description : Method to map PME fields with Pricing Staging, PLI and PM field values
    **/
    public static Apttus_Config2__PriceMatrixEntry__c mapPMEFields(APTS_Pricing_Staging__c staging, Apttus_Config2__PriceListItem__c existingPLI, Apttus_Config2__PriceMatrixEntry__c tempPME, Apttus_Config2__PriceMatrix__c tempPM){
        
        Map<String, APTS_Pricing_Staging_Contract_Mapping__mdt> pricingStagingContractMap = getPricingStagingContractMapping();

        tempPME.Apttus_Config2__AdjustmentAmount__c = staging.APTS_List_Price__c/staging.APTS_SAP_ListPriceUnits__c;
        tempPME.Apttus_Config2__AdjustmentType__c = Label.APTS_List_Price_Override;
        tempPME.APTS_PriceMatrixEntryExtId__c = existingPLI.APTS_PriceListItemExtId__c + Label.APTS_Pipe_Symbol + staging.APTS_Contract_Period__c;
        tempPME.Apttus_Config2__Dimension1Value__c = String.valueOf(pricingStagingContractMap.get(staging.APTS_Contract_Period__c).APTS_Dimension__c);
        tempPME.Apttus_Config2__Sequence__c = pricingStagingContractMap.get(staging.APTS_Contract_Period__c).APTS_Sequence__c;
        if(String.IsBlank(tempPME.Apttus_Config2__PriceMatrixId__c)){   
            tempPME.Apttus_Config2__PriceMatrixId__c = tempPM.Id;
        }
        
        return tempPME;
    }
    
    /** Method Name : processInactiveSalesOrg
    * Description : Method to query and return the list of PLIs to be deactivated, for inactive Sales Org (APTS_Distribution_chain_specific_materia__c is blank)
    **/
    public static Map<Id,Apttus_Config2__PriceListItem__c> processInactiveSalesOrg(List<APTS_Sales_Org_Data__c> inactiveSalesOrgs){
        Set<Id> prodIdSet = new Set<Id>();
        Set<Id> pLIdSet = new Set<Id>();
       
        for(APTS_Sales_Org_Data__c sOrg : inactiveSalesOrgs){
            prodIdSet.add(sOrg.APTS_Product__c);
            pLIdSet.add(sOrg.APTS_Price_List__c);
        }

        return new Map<Id,Apttus_Config2__PriceListItem__c>([SELECT Id, Apttus_Config2__Active__c, Apttus_Config2__ExpirationDate__c FROM Apttus_Config2__PriceListItem__c WHERE Apttus_Config2__ProductId__c IN: prodIdSet AND Apttus_Config2__PriceListId__c IN: pLIdSet ]);
    }
    
    /** Method Name : sendEmail
    * Description : Method to send email when Pricing Batch execution is completed with errors
    **/
    public static void sendEmail(AsyncApexJob asyncJob){
        APTS_ProductPricingBatchSettings__c custSetting = APTS_ProductPricingBatchSettings__c.getInstance();
        String emailId = custSetting != null ? custSetting.APTS_Pricing_Batch_Notification_Email_ID__c : EMPTY_STRING;
        if(String.IsNotBlank(emailId)){
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.toAddresses = new String[]{emailId};
            message.Subject = Label.APTS_PricingBatchRedistribution + EMPTY_STRING + asyncJob.Status;
            message.plainTextBody = 'The Pricing Redistribution Batch processed '+ asyncJob.TotalJobItems +' batches with '+ asyncJob.NumberOfErrors + ' failures.';
            Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>{message};
            try{
                Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
            }catch(Exception ex){}
        }
    }
   
    
    /** Method Name : processPLIUpsertResult
    * Description : Method to process SaveResult and UpsertResult and updates the PricingErrorMap
    **/
    public static Map<string,String> processPLIUpsertResult(List<Database.UpsertResult> upsertResultList, Map<String,String> pricingErrorMap,List<Apttus_Config2__PriceListItem__c> pliList){
        //Map<string,String> updatedErrorMap = new Map<string, String>();
        
        for (Integer i = 0; i < pliList.size(); i++) {
            Database.UpsertResult s = upsertResultList[i];
            Apttus_Config2__PriceListItem__c origRecord = pliList[i];
            if (!s.isSuccess()) {
                
                for(Database.Error err : s.getErrors()) {
                    
                    if(!pricingErrorMap.isEmpty() && pricingErrorMap.containsKey(origRecord.APTS_PriceListItemExtId__c)){
                        pricingErrorMap.put(origRecord.APTS_PriceListItemExtId__c,pricingErrorMap.containsKey(origRecord.APTS_PriceListItemExtId__c)+ EMPTY_STRING +err.getMessage());
                    }else{
                        pricingErrorMap.put(origRecord.APTS_PriceListItemExtId__c,err.getMessage());
                    }
                }
            } 
                    
        }
        
        return pricingErrorMap;
    }
    
    /** Method Name : processPMUpsertResult
    * Description : Method to process UpsertResult and updates the PricingErrorMap
    **/
    public static Map<string,String> processPMUpsertResult(List<Database.UpsertResult> upsertResultList, Map<String,String> pricingErrorMap,List<Apttus_Config2__PriceMatrix__c> priceMatrixList){
        for (Integer i = 0; i < priceMatrixList.size(); i++) {
            Database.UpsertResult upsertResult = upsertResultList[i];
            Apttus_Config2__PriceMatrix__c origRecord = priceMatrixList[i];
            if (!upsertResult.isSuccess()) {
                //string temp = priceMatrixList[i].APTS_PriceMatrixExtId__c.substringBefore(Label.APTS_Pipe_Symbol);
                string temp = priceMatrixList[i] != null && priceMatrixList[i].APTS_PriceMatrixExtId__c != null ? priceMatrixList[i].APTS_PriceMatrixExtId__c.substringBefore(Label.APTS_Pipe_Symbol) : null;
                for(Database.Error err : upsertResult.getErrors()) {
                    if(!pricingErrorMap.isEmpty() && pricingErrorMap.containsKey(temp)){
                        pricingErrorMap.put(temp,pricingErrorMap.containsKey(temp)+ EMPTY_STRING +err.getMessage());
                    }else{
                        pricingErrorMap.put(temp,err.getMessage());
                    }
                }
            }
        }
        return pricingErrorMap;
    }
    
    /** Method Name : processPMEUpsertResult
    * Description : Method to process  UpsertResult and updates the PricingErrorMap
    **/
    public static Map<string,String> processPMEUpsertResult(List<Database.UpsertResult> upsertResultList, Map<String,String> pricingErrorMap,List<Apttus_Config2__PriceMatrixEntry__c> priceMatrixEntryList ){
        for (Integer i = 0; i < priceMatrixEntryList .size(); i++) {
            Database.UpsertResult upsertResult = upsertResultList[i];
            Apttus_Config2__PriceMatrixEntry__c origRecord = priceMatrixEntryList[i];
            if (!upsertResult.isSuccess()) {
                //string temp = priceMatrixEntryList[i].APTS_PriceMatrixEntryExtId__c.substringBefore(Label.APTS_Pipe_Symbol);
                string temp = priceMatrixEntryList[i] != null && priceMatrixEntryList[i].APTS_PriceMatrixEntryExtId__c != null ? priceMatrixEntryList[i].APTS_PriceMatrixEntryExtId__c.substringBefore(Label.APTS_Pipe_Symbol) : null;
                for(Database.Error err : upsertResult.getErrors()) {
                    if(!pricingErrorMap.isEmpty() && pricingErrorMap.containsKey(temp)){
                        pricingErrorMap.put(temp,pricingErrorMap.containsKey(temp)+ EMPTY_STRING +err.getMessage());
                    }else{
                        pricingErrorMap.put(temp,err.getMessage());
                    }
                }
            } 
        }
        return pricingErrorMap;
    }
    
    /** Method Name : insertBatchErrors
    * Description : Method to create and return a list of Batch Error records 
    **/
    public static List<APTS_Batch_Error__c> insertBatchErrors(Map<String, String> pricingErrorMap){
        List<APTS_Batch_Error__c> batchErrorList = new List<APTS_Batch_Error__c>();
        for(string id : pricingErrorMap.keySet()){
            APTS_Batch_Error__c batchError = new APTS_Batch_Error__c();
            batchError.APTS_Error_Name__c = Label.APTS_PricingBatchDMLFailed;
            batchError.APTS_Error_Level__c = Label.APTS_Error;
            batchError.APTS_Error_Description__c = pricingErrorMap.get(id);
            batchError.APTS_Parent_ID__c = id;
            batchError.APTS_Parent_Object_Name__c = Label.APTS_PricingStaging;
            batchError.Error_Date_Time__c = System.Now();
            batchErrorList.add(batchError);
        }
        return batchErrorList;
    }
    
    /** Method Name : runMaintenanceBatches
    * Description : Method to run Apttus Maintenance Batches related to Pricing Batch
    **/
    public static void runMaintenanceBatches(){
        /*Apttus_Config2.PriceListItemSequenceUpdateJob pLIUpdateJob = new Apttus_Config2.PriceListItemSequenceUpdateJob();
        Database.executeBatch(pLIUpdateJob);*/

        //Commented above code as part of Defect ID : 19803 | need to simply update criteria maintainence (Runs pricing criteria fields)
        /*Apttus_Config2.CriteriaUpdateJob criteriaUpdateJob = new Apttus_Config2.CriteriaUpdateJob(new List<String>{Label.APTS_All_Value});
        Database.executeBatch(criteriaUpdateJob);*/
        Apttus_CPQApi.BatchUpdateService.updatePricingCriteria();
    }
    
    /** Method Name : createProductPriceListItemsMap
    * Description : Method to generate map product code Vs its price list items(one to many)
      uses : set of product codes and set or sales org data
    **/
    public static Map<String,List<Apttus_Config2__PriceListItem__c>> createProductPriceListItemsMap(Set<String> productCodeSet,Set<String> salesOrgCodesSet){
        Map<String,List<Apttus_Config2__PriceListItem__c>> prodCodePriceListItemsMap = new Map<String,List<Apttus_Config2__PriceListItem__c>>();
        
        //Created Map of productcode and its price list items associated to it based on product codes and sales org code list - helps to filter down and process relevant data + avoids unncessary updates
        for(Apttus_Config2__PriceListItem__c productPricelistItem : [select id,Apttus_Config2__PriceListId__c,APTS_Sales_Organization__c,Apttus_Config2__ChargeType__c,APTS_TXP_Coffee_tax__c,APTS_TXP_Instant_coffee_tax__c,APTS_TXP_Liquid_coffee_tax__c,APTS_TXP_Tea_tax__c,APTS_TXP_Chocolate_tax__c,APTS_TXP_Disposable_tableware__c,APTS_TXP_Cappuccino_tax_mixed__c,APTS_TXP_Recycle_Con_Pack_Tax__c,APTS_TXP_Disposal_Fee__c,Apttus_Config2__ProductCode__c from Apttus_Config2__PriceListItem__c where Apttus_Config2__ProductCode__c IN: productCodeSet and APTS_Sales_Organization__c IN: salesOrgCodesSet ]){
            if(prodCodePriceListItemsMap.get(productPricelistItem.Apttus_Config2__ProductCode__c)==null){
                prodCodePriceListItemsMap.put(productPricelistItem.Apttus_Config2__ProductCode__c,new List<Apttus_Config2__PriceListItem__c>{productPricelistItem});
            }else{                      
                prodCodePriceListItemsMap.get(productPricelistItem.Apttus_Config2__ProductCode__c).add(productPricelistItem);
            }
        }
        return prodCodePriceListItemsMap;
    }
    /** Method Name : getTransactableUOMs
    * Description : Method to get transactable UOMs list
    **/
    public static Set<String> getTransactableUOMs(){
        List<APTS_Transactional_UOM__c> transUOMS = APTS_Transactional_UOM__c.getall().values();
        Set<String> transactionalUOMS = new Set<String>();      
        for(APTS_Transactional_UOM__c tom : transUOMS ){
            transactionalUOMS.add(tom.name);
        }
        return transactionalUOMS;
    }
     /** Method Name : deactivatePLIs
    * Description : Method to make the PLIs inactive
    **/
    public static Map<String,Apttus_Config2__PriceListItem__c> updateActiveFlagOnPLI(Map<String,Apttus_Config2__PriceListItem__c> mapOfActivePLIs,Map<Id,Apttus_Config2__PriceListItem__c> deactivatedPliMap){
        Map<String,Apttus_Config2__PriceListItem__c> activePLIsMap = new Map<String,Apttus_Config2__PriceListItem__c>();
        For(String keyVal : mapOfActivePLIs.keyset()){
            Apttus_Config2__PriceListItem__c pli = mapOfActivePLIs.get(keyVal);
            if(!deactivatedPliMap.keyset().contains(pli.id)){
                pli.Apttus_Config2__Active__c=true;
            }
            if(activePLIsMap.get(keyVal)==null){
                activePLIsMap.put(keyval,pli);
            }
        }
        return activePLIsMap;
    }
}