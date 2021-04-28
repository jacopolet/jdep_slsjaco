/*
@Author : Ariel Quesada 
@Description : Calculation Engine to administer calculations related with Volume assumptions, obligations and rebates
*/
public with sharing class APTS_VolumeCalculationEngine {

    private static String CONSUMPTION = system.label.APTS_Consumption;
    private static String VOLUME = system.label.APTS_Volume;
    private static String HIGHRATETIER = system.label.APTS_HighRate;
    private static String BENEFIT = system.label.APTS_Benefit;
    private static String BENEFITPERUNIT='Benefit Per Unit';
    private static String RATEPERTIER = system.label.APTS_RatePerEach;
    private static String BENEFITAMT= system.label.APTS_BenefitAmt;
    private static String LISTPRICE = system.label.APTS_ListPrice;
    private static String NETPRICE = system.label.APTS_NetPrice;
    private static String REVENUE = system.label.APTS_Revenue;
    private static String NONE = '--None--';

    // Constant to retrieve family level
    public static Integer CATEGORY_LEVEL = 1;
    public static Integer SUBCATEGORY_LEVEL = 2;
    public static Integer SUBSUBCATEGORY_LEVEL = 3;
    public static Integer PRODUCT_LEVEL = 4;

    public class VolumeAssumptionRequest
    {
        public String fromUOM{get;set;} // From UOM
        public decimal unitfromUOM{get;set;} // unit in the from UOM
        public Id agreementId{get;set;} // Id of the agreement
        public string toUOM{get;set;} // From UOM

        public String category{get;set;}
        public String subcategory{get;set;}
        public String subsubcategory{get;set;}
        public Integer familyLevel{get;set;}
        public Id productId{get;set;}
    }
    public class VolumeRebateRequest
    {
        public Id agreementId{get;set;} // Id of the agreement
        public decimal volAssumption{get;set;} // Volume Assumption
        public Id category{get;set;} // Id of the Category
        public decimal grossSale{get;set;} // gross Sale
        public decimal netSale{get;set;} // Net Sale
    }
    public class DrinksRequest
    {
        public Id agreementId{get;set;} // Id of the agreement
        public decimal volumeAssumption{get;set;} // Volume Assumption
        public string originalUOM{get;set;} // final UOM

        public String category{get;set;}
        public String subcategory{get;set;}
        public String subsubcategory{get;set;}
        public Integer familyLevel{get;set;}
        public Id productId{get;set;}
    }

    public class GrossAndNetSalesRequest
    {
        public String category{get;set;}
        public String subcategory{get;set;}
        public String subsubcategory{get;set;}
        public Integer familyLevel{get;set;}
        public String UOM{get;set;}
        public String PreferredWayOfIngredientDelivery{get;set;}
        public String salesOrganization{get;set;}
    }

    public class GrossAndNetSalesResponse
    {
        public decimal grossSales;
        public decimal netSales;
    }
    public static decimal getAssumption(VolumeAssumptionRequest request)
    {
        System.debug('Parameter: GetAssumption: request: ' + request);
        // Calculation of assumption
        decimal assumption = 0.0;
        try{
        Apttus__APTS_Agreement__c agreement =[SELECT id,RecordType.name FROM Apttus__APTS_Agreement__c WHERE id =:request.agreementId];     

        if (agreement.RecordType.name == CONSUMPTION)
        {
            assumption = request.unitfromUOM;
        }
        else if (request.fromUOM == request.toUOM)
        {
            assumption = request.unitfromUOM;
        }
        else if (request.subcategory == NONE)
        {
            assumption = 0.0;
        }
        else
        {
            String familyName;
            if (request.subsubcategory != null)
            {
                if (request.subsubcategory.contains('|'))
                {
                    System.debug('Subsubcategory to be simplified');
                    familyName = request.category + '|' +
                                    request.subsubcategory;
                }
                else
                {
                    familyName = request.category + '|' + request.subcategory + '|' + 
                                    request.subsubcategory;
                }
            }
            else 
            {
                familyName = request.category + '|' + request.subcategory;
            }
            
            System.debug('Request.category: ' + request.category);
            System.debug('Request.subcategory: ' + request.subcategory);
            System.debug('Request.subsubcategory: ' + request.subsubcategory);
            System.debug('FamilyName:' + familyName);
            if (request.category != null && request.subcategory != null && request.unitfromUOM != null && request.fromUOM != null && request.toUOM != null && 
                request.familyLevel >= CATEGORY_LEVEL && request.familyLevel <= PRODUCT_LEVEL)
            {
                // Before everything the query of picklist
                Map<String,String> mapPicklist = new Map<String,String>();
                Schema.DescribeFieldResult field = Apttus_Config2__FrequencyConversionRate__c.Apttus_Config2__ProductFamily__c.getDescribe();
                for (Schema.PicklistEntry f : field.getPicklistValues())
                {
                    mapPicklist.put(f.getLabel(), f.getValue());
                }


                list<Apttus_Config2__FrequencyConversionRate__c> lstFreqUOM = new list<Apttus_Config2__FrequencyConversionRate__c>();
                
                if (request.familyLevel == CATEGORY_LEVEL)
                {
                    System.debug('GetAssumption at Category Level');
                    lstFreqUOM = [select Id,Apttus_Config2__ConversionFactor__c,Apttus_Config2__ToUom__c, Apttus_Config2__FromUom__c 
                                   from Apttus_Config2__FrequencyConversionRate__c
                                   where toLabel(Apttus_Config2__ProductFamily__c) =: request.category
                                   AND Apttus_Config2__FromUom__c =:request.fromUOM 
                                   AND Apttus_Config2__ToUom__c =: request.toUOM limit 1];
                }
                else if (request.familyLevel == SUBCATEGORY_LEVEL)
                {
                    System.debug('GetAssumption at Subcategory Level');
                    lstFreqUOM = [select Id,Apttus_Config2__ConversionFactor__c,Apttus_Config2__ToUom__c, Apttus_Config2__FromUom__c 
                                   from Apttus_Config2__FrequencyConversionRate__c
                                   where toLabel(APTS_Product_Family2__c) =: request.subcategory
                                   AND Apttus_Config2__FromUom__c =:request.fromUOM 
                                   AND Apttus_Config2__ToUom__c =: request.toUOM limit 1];                      
                    // If there are no records at subcategory, the next step is to query at category level
                    if (lstFreqUOM.isEmpty())
                    {
                        System.debug('If there are no records at subcategory, the next step is to query at category level');
                        lstFreqUOM = [select Id,Apttus_Config2__ConversionFactor__c,Apttus_Config2__ToUom__c, Apttus_Config2__FromUom__c 
                               from Apttus_Config2__FrequencyConversionRate__c
                               where toLabel(Apttus_Config2__ProductFamily__c) =: request.category
                               AND Apttus_Config2__FromUom__c =:request.fromUOM 
                               AND Apttus_Config2__ToUom__c =: request.toUOM limit 1];          
                    }
                }
                else if (request.familyLevel == SUBSUBCATEGORY_LEVEL)
                {
                    System.debug('GetAssumption at Subsubcategory Level');
                    lstFreqUOM = [select Id,Apttus_Config2__ConversionFactor__c,Apttus_Config2__ToUom__c, Apttus_Config2__FromUom__c 
                                   from Apttus_Config2__FrequencyConversionRate__c
                                   where toLabel(APTS_Product_Family3__c) =: familyName 
                                   AND Apttus_Config2__FromUom__c =:request.fromUOM 
                                   AND Apttus_Config2__ToUom__c =: request.toUOM limit 1];
                    // If there are no records at subsubcategory level the next step is to query at subcategory level
                    if (lstFreqUOM.IsEmpty())
                    {
                        System.debug('If there are no records at subsubcategory level the next step is to query at subcategory level');
                        lstFreqUOM = [select Id,Apttus_Config2__ConversionFactor__c,Apttus_Config2__ToUom__c, Apttus_Config2__FromUom__c 
                                   from Apttus_Config2__FrequencyConversionRate__c
                                   where toLabel(APTS_Product_Family2__c) =: request.subcategory
                                   AND Apttus_Config2__FromUom__c =:request.fromUOM 
                                   AND Apttus_Config2__ToUom__c =: request.toUOM limit 1];   
                        // If there are no records at subcategory, the next step is to query at category level
                        if (lstFreqUOM.isEmpty())
                        {
                            System.debug('If there are no records at subcategory, the next step is to query at category level');
                            lstFreqUOM = [select Id,Apttus_Config2__ConversionFactor__c,Apttus_Config2__ToUom__c, Apttus_Config2__FromUom__c 
                                   from Apttus_Config2__FrequencyConversionRate__c
                                   where toLabel(Apttus_Config2__ProductFamily__c) =: request.category
                                   AND Apttus_Config2__FromUom__c =:request.fromUOM 
                                   AND Apttus_Config2__ToUom__c =: request.toUOM limit 1];          
                        }                       

                    }
                }
                else if (request.familyLevel == PRODUCT_LEVEL)
                {                   
                    if (request.productId != NULL)
                    {
                        System.debug('GetAssumption at Product level');
                        lstFreqUOM = [select Id,Apttus_Config2__ConversionFactor__c,Apttus_Config2__ToUom__c, Apttus_Config2__FromUom__c 
                                   from Apttus_Config2__FrequencyConversionRate__c
                                   where Apttus_Config2__ProductId__c =: request.productId
                                   AND Apttus_Config2__FromUom__c =:request.fromUOM 
                                   AND Apttus_Config2__ToUom__c =: request.toUOM limit 1];
                        if (lstFreqUOM.isEmpty())
                        {
                            // If there are no records at subsubcategory level the next step is to query at subsubcategory level
                            System.debug('If there are no records at subsubcategory level the next step is to query at subsubcategory level');
                            lstFreqUOM = [select Id,Apttus_Config2__ConversionFactor__c,Apttus_Config2__ToUom__c, Apttus_Config2__FromUom__c 
                                           from Apttus_Config2__FrequencyConversionRate__c
                                           where toLabel(APTS_Product_Family3__c) =: familyName 
                                           AND Apttus_Config2__FromUom__c =:request.fromUOM 
                                           AND Apttus_Config2__ToUom__c =: request.toUOM limit 1];
                            
                            if (lstFreqUOM.IsEmpty())
                            {
                                // If there are no records at subcategory, the next step is to query at subcategory level
                                System.debug('If there are no records at subsubcategory, the next step is to query at subcategory level');
                                lstFreqUOM = [select Id,Apttus_Config2__ConversionFactor__c,Apttus_Config2__ToUom__c, Apttus_Config2__FromUom__c 
                                           from Apttus_Config2__FrequencyConversionRate__c
                                           where toLabel(APTS_Product_Family2__c) =: request.subcategory
                                           AND Apttus_Config2__FromUom__c =:request.fromUOM 
                                           AND Apttus_Config2__ToUom__c =: request.toUOM limit 1];   
                                
                                if (lstFreqUOM.isEmpty())
                                {
                                    // If there are no records at subcategory, the next step is to query at subcategory level
                                    System.debug('If there are no records at subcategory, the next step is to query at category level');
                                    lstFreqUOM = [select Id,Apttus_Config2__ConversionFactor__c,Apttus_Config2__ToUom__c, Apttus_Config2__FromUom__c 
                                           from Apttus_Config2__FrequencyConversionRate__c
                                           where toLabel(Apttus_Config2__ProductFamily__c) =: request.category
                                           AND Apttus_Config2__FromUom__c =:request.fromUOM 
                                           AND Apttus_Config2__ToUom__c =: request.toUOM limit 1];          
                                }                       
                            }
                        }
                    }
                    else
                    {
                        assumption = 0.0;
                    }
                }
                if(!lstFreqUOM.isEmpty())
                {
                    assumption = lstFreqUOM[0].Apttus_Config2__ConversionFactor__c * request.unitfromUOM;  
                }
                else
                {
                    assumption = 0.0; // Conversion not found
                }
            }
            else
            {
                assumption = 0.0;
            }
        }
        }catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString(), 'Agreement', null, 'OM', false, false, null, true);}
        return assumption;
    }
    public static decimal getDrinks(DrinksRequest request)
    {
        System.debug('APTS_VolumeCalculationEngine: getDrinks with parameter: ' + request);
        // Calculation of assumption
        decimal drinks = 0.0;
        try{
        Apttus__APTS_Agreement__c agreement =[SELECT id,RecordType.name FROM Apttus__APTS_Agreement__c WHERE id =:request.agreementId];     

        if (agreement.RecordType.name == CONSUMPTION)
        {
            System.debug('APTS_VolumeCalculationEngine: Agreement is consumption model. No conversion needed (only drinks).');
            drinks = request.volumeAssumption;
        }
        else if (request.originalUOM == 'SAP_DRKS')
        {
            System.debug('APTS_VolumeCalculationEngine: Drinks to Drinks. No conversion needed');
            drinks = request.volumeAssumption;  
        }
        else
        {
            String familyName;
            if (request.subsubcategory != null)
            {
                if (request.subsubcategory.contains('|'))
                {
                    System.debug('Subsubcategory to be simplified');
                    familyName = request.category + '|' +
                                    request.subsubcategory;
                }
                else
                {
                    familyName = request.category + '|' + request.subcategory + '|' + 
                                    request.subsubcategory;
                }
            }
            else 
            {
                familyName = request.category + '|' + request.subcategory;
            }
            
            System.debug('Request.category: ' + request.category);
            System.debug('Request.subcategory: ' + request.subcategory);
            System.debug('Request.subsubcategory: ' + request.subsubcategory);
            System.debug('FamilyName:' + familyName);
            System.debug('APTS_VolumeCalculationEngine: Agreement is not consumption model. Conversion needed. Request: ' + request);
            if (request.category != null && request.subcategory != null && request.volumeAssumption != null && request.originalUOM != null && 
                request.familyLevel >= CATEGORY_LEVEL && request.familyLevel <= PRODUCT_LEVEL)
            {
                // Before everything the query of picklist
                Map<String,String> mapPicklist = new Map<String,String>();
                Schema.DescribeFieldResult field = Apttus_Config2__FrequencyConversionRate__c.Apttus_Config2__ProductFamily__c.getDescribe();
                for (Schema.PicklistEntry f : field.getPicklistValues())
                {
                    mapPicklist.put(f.getLabel(), f.getValue());
                }


                list<Apttus_Config2__FrequencyConversionRate__c> lstFreqUOM = new list<Apttus_Config2__FrequencyConversionRate__c>();
                
                String DrinksUOM = 'SAP_DRKS';
                if (request.familyLevel == CATEGORY_LEVEL)
                {
                    System.debug('APTS_VolumeCalculationEngine: Conversion at category level.');
                    lstFreqUOM = [select Id,Apttus_Config2__ConversionFactor__c,Apttus_Config2__ToUom__c, Apttus_Config2__FromUom__c 
                                   from Apttus_Config2__FrequencyConversionRate__c
                                   where toLabel(Apttus_Config2__ProductFamily__c) =: request.category
                                   AND Apttus_Config2__FromUom__c =: DrinksUOM
                                   AND Apttus_Config2__ToUom__c =: request.originalUOM limit 1];
                }
                else if (request.familyLevel == SUBCATEGORY_LEVEL)
                {
                    System.debug('APTS_VolumeCalculationEngine: Conversion at subcategory level.');
                    lstFreqUOM = [select Id,Apttus_Config2__ConversionFactor__c,Apttus_Config2__ToUom__c, Apttus_Config2__FromUom__c 
                                   from Apttus_Config2__FrequencyConversionRate__c
                                   where toLabel(APTS_Product_Family2__c) =: request.subcategory
                                   AND Apttus_Config2__FromUom__c =: DrinksUOM
                                   AND Apttus_Config2__ToUom__c =: request.originalUOM limit 1];   // If there are no records at subcategory, the next step is to query at category level
                    if (lstFreqUOM.isEmpty())
                    {
                        System.debug('APTS_VolumeCalculationEngine: Conversion at category level.');
                        lstFreqUOM = [select Id,Apttus_Config2__ConversionFactor__c,Apttus_Config2__ToUom__c, Apttus_Config2__FromUom__c 
                               from Apttus_Config2__FrequencyConversionRate__c
                               where toLabel(Apttus_Config2__ProductFamily__c) =: request.category
                                    AND Apttus_Config2__FromUom__c =: DrinksUOM
                                   AND Apttus_Config2__ToUom__c =: request.originalUOM limit 1];
                    }
                }
                else if (request.familyLevel == SUBSUBCATEGORY_LEVEL)
                {
                    System.debug('APTS_VolumeCalculationEngine: Conversion at subsubcategory level.');
                    lstFreqUOM = [select Id,Apttus_Config2__ConversionFactor__c,Apttus_Config2__ToUom__c, Apttus_Config2__FromUom__c 
                                   from Apttus_Config2__FrequencyConversionRate__c
                                   where toLabel(APTS_Product_Family3__c) =: familyName 
                                    AND Apttus_Config2__FromUom__c =: DrinksUOM
                                   AND Apttus_Config2__ToUom__c =: request.originalUOM limit 1];
                    // If there are no records at subsubcategory level the next step is to query at subcategory level
                    if (lstFreqUOM.IsEmpty())
                    {
                        System.debug('APTS_VolumeCalculationEngine: Subsubcategory record not found. Try at subcategory level');
                        lstFreqUOM = [select Id,Apttus_Config2__ConversionFactor__c,Apttus_Config2__ToUom__c, Apttus_Config2__FromUom__c 
                                   from Apttus_Config2__FrequencyConversionRate__c
                                   where toLabel(APTS_Product_Family2__c) =: request.subcategory
                                   AND Apttus_Config2__FromUom__c =: DrinksUOM
                                   AND Apttus_Config2__ToUom__c =: request.originalUOM limit 1];
                        // If there are no records at subcategory, the next step is to query at category level
                        if (lstFreqUOM.isEmpty())
                        {
                            System.debug('APTS_VolumeCalculationEngine: Conversion at category level.');
                            lstFreqUOM = [select Id,Apttus_Config2__ConversionFactor__c,Apttus_Config2__ToUom__c, Apttus_Config2__FromUom__c 
                                   from Apttus_Config2__FrequencyConversionRate__c
                                   where toLabel(Apttus_Config2__ProductFamily__c) =: request.category
                                   AND Apttus_Config2__FromUom__c =: DrinksUOM
                                   AND Apttus_Config2__ToUom__c =: request.originalUOM limit 1];
                        }                       
                    }
                }
                else if (request.familyLevel == PRODUCT_LEVEL)
                {
                    // Product scenario
                    if (request.productId != NULL)
                    {
                        System.debug('APTS_VolumeCalculationEngine: Conversion at product level.');
                        lstFreqUOM = [select Id,Apttus_Config2__ConversionFactor__c,Apttus_Config2__ToUom__c, Apttus_Config2__FromUom__c 
                                   from Apttus_Config2__FrequencyConversionRate__c
                                   where Apttus_Config2__ProductId__c =: request.productId
                                    AND Apttus_Config2__FromUom__c =: DrinksUOM
                                   AND Apttus_Config2__ToUom__c =: request.originalUOM limit 1];
                        if (lstFreqUOM.isEmpty())
                        {
                            System.debug('APTS_VolumeCalculationEngine: Conversion at subsubcategory level.');
                            lstFreqUOM = [select Id,Apttus_Config2__ConversionFactor__c,Apttus_Config2__ToUom__c, Apttus_Config2__FromUom__c 
                                           from Apttus_Config2__FrequencyConversionRate__c
                                           where toLabel(APTS_Product_Family3__c) =: familyName 
                                           AND Apttus_Config2__FromUom__c =: DrinksUOM
                                           AND Apttus_Config2__ToUom__c =: request.originalUOM limit 1];
                            // If there are no records at subsubcategory level the next step is to query at subcategory level
                            if (lstFreqUOM.IsEmpty())
                            {
                                System.debug('APTS_VolumeCalculationEngine: Subsubcategory record not found. Try at subcategory level');
                                lstFreqUOM = [select Id,Apttus_Config2__ConversionFactor__c,Apttus_Config2__ToUom__c, Apttus_Config2__FromUom__c 
                                           from Apttus_Config2__FrequencyConversionRate__c
                                           where toLabel(APTS_Product_Family2__c) =: request.subcategory
                                           AND Apttus_Config2__FromUom__c =: DrinksUOM
                                           AND Apttus_Config2__ToUom__c =: request.originalUOM limit 1];
                                // If there are no records at subcategory, the next step is to query at category level
                                if (lstFreqUOM.isEmpty())
                                {
                                    System.debug('APTS_VolumeCalculationEngine: Conversion at category level.');
                                    lstFreqUOM = [select Id,Apttus_Config2__ConversionFactor__c,Apttus_Config2__ToUom__c, Apttus_Config2__FromUom__c 
                                           from Apttus_Config2__FrequencyConversionRate__c
                                           where toLabel(Apttus_Config2__ProductFamily__c) =: request.category
                                           AND Apttus_Config2__FromUom__c =: DrinksUOM
                                           AND Apttus_Config2__ToUom__c =: request.originalUOM limit 1];
                                }                       
                            }
                        }
                    }
                    else
                    {
                        drinks = 0.0;
                    }
                }

                System.debug('APTS_VolumeCalculationEngine: lstFreqUOM (root Level): ' + lstFreqUOM);
                if(!lstFreqUOM.isEmpty())
                {
                    if (lstFreqUOM[0].Apttus_Config2__ConversionFactor__c != null)
                    {
                        drinks = request.volumeAssumption / lstFreqUOM[0].Apttus_Config2__ConversionFactor__c;
                    }
                    else
                    {
                        drinks = 0.0;
                    }
                }
                else
                {
                    drinks = 0.0; //Conversion not found
                }
            }
            else
            {
                System.debug('APTS_VolumeCalculationEngine: Parameter incomplete on VolumeAssumptionRequest: ' + request);
                drinks = 0.0;
            }
        }
        }catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString(), 'Agreement', null, 'OM', false, false, null, true);}
        return drinks;
    }
    public static decimal getRebate(VolumeRebateRequest request)
    {
        System.debug('APTS_VolumeCalculationEngine: Start of getRebate Calculation');
        Decimal inputTier;
        Decimal rebatePay = 0;
        Decimal temprebatePay = 0;
        Decimal finalRebate = 0;
        Decimal DimensionPreValue = 0;
        Boolean checkZero = FALSE;
        Decimal temp = 0;
        Integer listSize = 1;
        Boolean Pass = TRUE;
        Id prevValue = NULL;
        Id prevInc = NULL;
        try{
        List<Apttus_Config2__PriceRuleEntry__c> lstPrRuleEntry =[SELECT
                     Id, Apttus_Config2__Dimension4Value__c, Apttus_Config2__AdjustmentAmount__c,Apttus_Config2__AdjustmentType__c, 
                     Apttus_Config2__PriceRuleId__r.Apttus_Config2__RulesetId__r.Apttus_Config2__Criteria__c,
                     Apttus_Config2__PriceRuleId__r.Apttus_Config2__RulesetId__r.Apttus_Config2__IncentiveId__c,
                     Apttus_Config2__PriceRuleId__r.Apttus_Config2__RulesetId__r.Apttus_Config2__IncentiveId__r.Apttus_Config2__Active__c,
                     Apttus_Config2__PriceRuleId__r.Apttus_Config2__RulesetId__r.Apttus_Config2__IncentiveId__r.Apttus_CMConfig__AgreementId__r.RecordType.name,
                     Apttus_Config2__PriceRuleId__r.Apttus_Config2__TierMetricType__c,Apttus_Config2__PriceRuleId__r.Apttus_Config2__MetricValueSource__c,
                     Apttus_Config2__PriceRuleId__r.Apttus_Config2__Dimension4ValueType__c
                FROM Apttus_Config2__PriceRuleEntry__c 
                WHERE Apttus_Config2__PriceRuleId__r.Apttus_Config2__RulesetId__r.Apttus_Config2__IncentiveId__r.Apttus_CMConfig__AgreementId__c =:request.agreementId 
                AND Apttus_Config2__PriceRuleId__r.Apttus_Config2__RulesetId__r.Apttus_Config2__IncentiveId__r.Apttus_Config2__Active__c=TRUE];

        System.debug('APTS_VolumeCalculationEngine: Number of price rule entries that affect the agreement for rebate calculation: ' + lstPrRuleEntry.Size());
        for(Apttus_Config2__PriceRuleEntry__c priceEntry:lstPrRuleEntry )
        {
            System.debug('APTS_VolumeCalculationEngine: Start of Price Entry iteration with finalRebate: ' + finalRebate);
            if(priceEntry.Apttus_Config2__PriceRuleId__c!=prevValue && 
                prevValue!=NULL && 
                priceEntry.Apttus_Config2__PriceRuleId__r.Apttus_Config2__RulesetId__r.Apttus_Config2__IncentiveId__c !=prevInc && 
                prevInc !=Null)//previous rule value not equal to now then add rebate
            {
                temprebatePay=temprebatePay+rebatePay;
                prevValue=priceEntry.Apttus_Config2__PriceRuleId__c;
                finalRebate=temprebatePay;
                Pass =TRUE;
                temp=0;
                DimensionPreValue =0;
                rebatePay=0;
            }
            if(priceEntry.Apttus_Config2__PriceRuleId__r.Apttus_Config2__TierMetricType__c==VOLUME)
            {
                System.debug('APTS_VolumeCalculationEngine: Type of Rule Entry = VOLUME');
                inputTier=request.volAssumption;
                System.debug('APTS_VolumeCalculationEngine: Verification of criteria for VOLUME.');
                if(!string.isBlank(priceEntry.Apttus_Config2__PriceRuleId__r.Apttus_Config2__RulesetId__r.Apttus_Config2__Criteria__c))
                {
                    System.debug('APTS_VolumeCalculationEngine: Criteria found for the Price Rule');                    
                    APTS_CategoryCriteriaParse criteria=
                        APTS_CategoryCriteriaParse.parse(priceEntry.Apttus_Config2__PriceRuleId__r.Apttus_Config2__RulesetId__r.Apttus_Config2__Criteria__c);
                    System.debug('APTS_VolumeCalculationEngine: criteria (as an object): ' + criteria);
                    String criteria1=String.ValueOf(criteria);
                    System.debug('APTS_VolumeCalculationEngine: criteria (as an string): ' + criteria);
                    if(request.category!=Null && criteria1.contains(request.category))
                    {
                        System.debug('APTS_VolumeCalculationEngine: Category in criteria.');
                        if(priceEntry.Apttus_Config2__PriceRuleId__r.Apttus_Config2__Dimension4ValueType__c==HIGHRATETIER )
                        {
                            System.debug('APTS_VolumeCalculationEngine: Type of Dimension: HIGHRATETIER');
                            if(inputTier<=Decimal.valueOf(priceEntry.Apttus_Config2__Dimension4Value__c))
                            {
                                if(Decimal.valueOf(priceEntry.Apttus_Config2__Dimension4Value__c)<DimensionPreValue ||DimensionPreValue ==0 )
                                {
                                    if(priceEntry.Apttus_Config2__AdjustmentType__c== BENEFITAMT)
                                    {                                       
                                        rebatePay = priceEntry.Apttus_Config2__AdjustmentAmount__c;
                                        DimensionPreValue = Decimal.valueOf(priceEntry.Apttus_Config2__Dimension4Value__c);
                                        System.debug('APTS_VolumeCalculationEngine: Calculation of rebatePay for Benefit Amount: ' + rebatePay);   
                                    }
                                    else if(priceEntry.Apttus_Config2__AdjustmentType__c== BENEFITPERUNIT)
                                    {
                                        rebatePay=inputTier*priceEntry.Apttus_Config2__AdjustmentAmount__c;
                                        DimensionPreValue = Decimal.valueOf(priceEntry.Apttus_Config2__Dimension4Value__c);
                                        System.debug('APTS_VolumeCalculationEngine: Calculation of rebatePay for Benefit per Unit: ' + rebatePay);
                                    }
                                }
                            }
                        }
                        else if(priceEntry.Apttus_Config2__PriceRuleId__r.Apttus_Config2__Dimension4ValueType__c==RATEPERTIER)
                        { 
                            if (temp >0 || checkZero)
                            {
                                inputTier = temp;
                            }
                            if(priceEntry.Apttus_Config2__AdjustmentType__c== BENEFITAMT)
                            {
                                if(inputTier>=Decimal.valueOf(priceEntry.Apttus_Config2__Dimension4Value__c))
                                {
                                    rebatePay= rebatePay+priceEntry.Apttus_Config2__AdjustmentAmount__c;
                                    temp= inputTier-Decimal.valueOf(priceEntry.Apttus_Config2__Dimension4Value__c);
                                    System.debug('Temp calculation (BENEFITAMT): ' + temp);
                                    if(temp==0)
                                    {
                                        checkZero=TRUE;
                                    }
                                }
                                else if(Pass && (inputTier>0 && inputTier!= Null))
                                {
                                    rebatePay=rebatePay+priceEntry.Apttus_Config2__AdjustmentAmount__c;
                                    Pass=FALSE;
                                }
                            }
                            else if(priceEntry.Apttus_Config2__AdjustmentType__c== BENEFITPERUNIT)
                            {
                                if(inputTier>=Decimal.valueOf(priceEntry.Apttus_Config2__Dimension4Value__c))
                                {
                                    rebatePay = rebatePay+(Decimal.valueOf(priceEntry.Apttus_Config2__Dimension4Value__c)*priceEntry.Apttus_Config2__AdjustmentAmount__c);
                                    temp = inputTier-Decimal.valueOf(priceEntry.Apttus_Config2__Dimension4Value__c);
                                    System.debug('Temp calculation (BENEFITPERUNIT): ' + temp);
                                    if(temp==0)
                                    {
                                        checkZero=TRUE;
                                    }
                                }
                                else if(Pass && (inputTier>0 && inputTier!= Null))
                                {
                                    rebatePay=rebatePay+(inputTier*priceEntry.Apttus_Config2__AdjustmentAmount__c);
                                    Pass=FALSE;
                                }
                            }
                        }    
                    } 
                    else 
                    {
                        rebatePay=0;
                    }
                }
                else
                { 
                    rebatePay=0;
                }
            }           
            else if(priceEntry.Apttus_Config2__PriceRuleId__r.Apttus_Config2__TierMetricType__c== REVENUE && 
                priceEntry.Apttus_Config2__PriceRuleId__r.Apttus_Config2__RulesetId__r.Apttus_Config2__IncentiveId__r.Apttus_CMConfig__AgreementId__r.RecordType.name
                    != CONSUMPTION)
            {
                System.debug('APTS_VolumeCalculationEngine: Type of Rule Entry = REVENUE and not Consumption / prevValue: ' + prevValue);
                APTS_CategoryCriteriaParse criteria=
                    APTS_CategoryCriteriaParse.parse(priceEntry.Apttus_Config2__PriceRuleId__r.Apttus_Config2__RulesetId__r.Apttus_Config2__Criteria__c);
                String criteria1=String.ValueOf(criteria);
                if (request.category!=Null && criteria1.contains(request.category))
                { 
                    System.debug('APTS_VolumeCalculationEngine: Category found for REVENUE Type of Rule Entry');
                    if(priceEntry.Apttus_Config2__PriceRuleId__r.Apttus_Config2__MetricValueSource__c==LISTPRICE)
                    {
                        System.debug('APTS_VolumeCalculationEngine: REVENUE TYPE/LISTPRICE');
                        inputTier = request.grossSale;
                    }
                    else if(priceEntry.Apttus_Config2__PriceRuleId__r.Apttus_Config2__MetricValueSource__c==NETPRICE )
                    {  
                        System.debug('APTS_VolumeCalculationEngine: REVENUE TYPE/NETPRICE');
                        inputTier = request.netSale;
                    }  
                    if(priceEntry.Apttus_Config2__PriceRuleId__r.Apttus_Config2__Dimension4ValueType__c==HIGHRATETIER )
                    {  
                        System.debug('APTS_VolumeCalculationEngine: REVENUE TYPE/NETPRICE/HIGHRATETIER with inputTier: ' + inputTier);
                        if(inputTier !=null &&  inputTier >0)
                        {             
                            System.debug('APTS_VolumeCalculationEngine: REVENUE TYPE/NETPRICE/HIGHRATETIER with Dimension4value: ' + priceEntry.Apttus_Config2__Dimension4Value__c);
                            System.debug('APTS_VolumeCalculationEngine: REVENUE TYPE/NETPRICE/HIGHRATETIER with DimensionPreValue: ' + DimensionPreValue);
                            if(inputTier<=Decimal.valueOf(priceEntry.Apttus_Config2__Dimension4Value__c))
                            {
                                if(Decimal.valueOf(priceEntry.Apttus_Config2__Dimension4Value__c)<DimensionPreValue || DimensionPreValue ==0 )
                                {
                                    System.debug('APTS_VolumeCalculationEngine: Ready to analyze adjustment type: ' + priceEntry.Apttus_Config2__AdjustmentType__c);
                                    if(priceEntry.Apttus_Config2__AdjustmentType__c == BENEFIT)
                                    {                                       
                                        rebatePay=inputTier*(priceEntry.Apttus_Config2__AdjustmentAmount__c/100);
                                        DimensionPreValue = Decimal.valueOf(priceEntry.Apttus_Config2__Dimension4Value__c);
                                        System.debug('APTS_VolumeCalculationEngine: REVENUE TYPE/NETPRICE/HIGHRATETIER/BENEFIT with rebatePay:' + rebatePay);
                                    }
                                    else if(priceEntry.Apttus_Config2__AdjustmentType__c== BENEFITAMT)
                                    {
                                        rebatePay=priceEntry.Apttus_Config2__AdjustmentAmount__c;
                                        DimensionPreValue = Decimal.valueOf(priceEntry.Apttus_Config2__Dimension4Value__c);
                                        System.debug('APTS_VolumeCalculationEngine: REVENUE TYPE/NETPRICE/HIGHRATETIER/BENEFITAMT with rebatePay:' + rebatePay);
                                    }
                                }
                            }
                        }
                        finalRebate=rebatePay;
                    }
                    else if(priceEntry.Apttus_Config2__PriceRuleId__r.Apttus_Config2__Dimension4ValueType__c==RATEPERTIER )
                    {  
                        if(inputTier !=null &&  inputTier >0)
                        {         
                            if(temp>0 || checkZero)
                            {
                                inputTier=temp;
                            }
                            if(priceEntry.Apttus_Config2__AdjustmentType__c == BENEFITAMT)
                            {
                                if(inputTier>=Decimal.valueOf(priceEntry.Apttus_Config2__Dimension4Value__c))
                                {
                                    rebatePay= rebatePay+(Decimal.valueOf(priceEntry.Apttus_Config2__Dimension4Value__c)*priceEntry.Apttus_Config2__AdjustmentAmount__c);
                                    temp= inputTier-Decimal.valueOf(priceEntry.Apttus_Config2__Dimension4Value__c);
                                    if(temp==0)
                                    {
                                        checkZero=TRUE;
                                    }
                                }
                                else if(Pass)
                                {
                                    rebatePay=rebatePay+(inputTier*priceEntry.Apttus_Config2__AdjustmentAmount__c);
                                    Pass=FALSE;
                                }
                            }
                            else if(priceEntry.Apttus_Config2__AdjustmentType__c== BENEFIT)
                            {
                                if(inputTier>=Decimal.valueOf(priceEntry.Apttus_Config2__Dimension4Value__c))
                                {
                                    rebatePay = rebatePay + (Decimal.valueOf(priceEntry.Apttus_Config2__Dimension4Value__c)*(priceEntry.Apttus_Config2__AdjustmentAmount__c/100));
                                    temp = inputTier-Decimal.valueOf(priceEntry.Apttus_Config2__Dimension4Value__c);
                                    if(temp==0)
                                    {
                                        checkZero=TRUE;
                                    }
                                }
                                else if(Pass)
                                {
                                    rebatePay=rebatePay+(inputTier*(priceEntry.Apttus_Config2__AdjustmentAmount__c/100));
                                    Pass=FALSE;
                                }  
                            }//finalRebate=rebatePay;
                        }
                    }
                    else
                    {
                        rebatePay=0;
                    }               
                }
            }
            System.debug('APTS_VolumeCalculationEngine: After iteration the value of prevValue is: ' + prevValue);
            if(prevValue==NULL)
            {
                finalRebate=rebatePay;
                prevValue=priceEntry.Apttus_Config2__PriceRuleId__c;
                temprebatePay=rebatePay;
                rebatePay=0;
                System.debug('APTS_VolumeCalculationEngine: PrevValue is null: finalRebate  = : ' + finalRebate);
            }
            else
            {
                prevValue=priceEntry.Apttus_Config2__PriceRuleId__c;
                //temprebatePay=rebatePay;
            }

            if(lstPrRuleEntry.size() == listSize)
            {
                system.debug('rebate()'+rebatePay);
                finalRebate = finalRebate + rebatePay;
                System.debug('APTS_VolumeCalculationEngine: listSize is correct: finalRebate  = : ' + finalRebate);   
            }
            listSize=listSize + 1;
            prevInc=priceEntry.Apttus_Config2__PriceRuleId__r.Apttus_Config2__RulesetId__r.Apttus_Config2__IncentiveId__c;
        }
        System.debug('APTS_VolumeCalculationEngine: End of method: finalRebate to be returned : ' + finalRebate);   
        }catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString(), 'Agreement', null, 'OM', false, false, null, true);}
        return finalRebate;
    }

    public static GrossAndNetSalesResponse getGrossAndNetValues(GrossAndNetSalesRequest request)
    {
        GrossAndNetSalesResponse response = new GrossAndNetSalesResponse();
        // The Average List and cost price object must be queried according with the parameters entered     
        List<APTS_AverageListPriceCostPrice__c> averageObjects = null;
        // The first step is to review the family Level so that the query can be determined
        try{
        if (request.familyLevel == 1)
        {
            System.debug('Family Level 1: Info to be considered: Category');
            averageObjects = [SELECT Id, APTS_ALPCP_GIP__c, APTS_ALPCP_VAP__c, APTS_ALPCP_Routesales__c, APTS_ALPCP_IngCost__c
                              FROM APTS_AverageListPriceCostPrice__c
                              WHERE APTS_ALPCP_SalesOrg__c =: request.salesorganization // Sales Organization
                              AND APTS_ALPCP_UnitOfMeasure__c =: request.UOM // Unit of measure
                              AND APTS_ALPCP_Category__c =: request.category // Category
                              LIMIT 1];
        }
        else if (request.familyLevel == 2 )
        {           
            string family2 = request.category + '|' + request.subcategory;
            System.debug('Family Level 2: Info to be considered: Category, Subcategory. ');
            averageObjects = [SELECT Id, APTS_ALPCP_GIP__c, APTS_ALPCP_VAP__c, APTS_ALPCP_Routesales__c, APTS_ALPCP_IngCost__c
                              FROM APTS_AverageListPriceCostPrice__c
                              WHERE APTS_ALPCP_SalesOrg__c =: request.salesorganization // Sales Organization
                              AND APTS_ALPCP_UnitOfMeasure__c =: request.UOM // Unit of measure
                              AND toLabel(APTS_ALPCP_Category__c) =: request.category // Category
                              AND toLabel(APTS_ALPCP_Subcategory__c) =: family2 // Subcategory
                              AND APTS_ALPCP_Subsubcat__c = null 
                              LIMIT 1];
        }
        else if (request.familyLevel == 3)
        {
            string family2 = request.category + '|' + request.subcategory;
            string family3 = request.category + '|' + request.subcategory + '|' + request.subsubcategory;

            System.debug('Family Level 3: Info to be considered: Category, Subcategory, subsubcategory');
            averageObjects = [SELECT Id, APTS_ALPCP_GIP__c, APTS_ALPCP_VAP__c, APTS_ALPCP_Routesales__c, APTS_ALPCP_IngCost__c
                              FROM APTS_AverageListPriceCostPrice__c
                              WHERE APTS_ALPCP_SalesOrg__c =: request.salesorganization // Sales Organization
                              AND APTS_ALPCP_UnitOfMeasure__c =: request.UOM // Unit of measure
                              AND toLabel(APTS_ALPCP_Category__c) =: request.category // Category
                              AND toLabel(APTS_ALPCP_Subcategory__c) =: family2 // Subcategory
                              AND toLabel(APTS_ALPCP_Subsubcat__c) =: family3 // Subsubcategory
                              LIMIT 1];
        }
        System.debug('AverageObjects queried: ' + averageObjects);
        if (averageObjects != null && !averageObjects.IsEmpty())
        {           
            if (request.PreferredWayOfIngredientDelivery == 'LSP')
            {
                response.grossSales = averageObjects[0].APTS_ALPCP_VAP__c;
            }
            if (request.PreferredWayOfIngredientDelivery == 'Indirect Channel')
            {
                response.grossSales = averageObjects[0].APTS_ALPCP_GIP__c;
            }
            if (request.PreferredWayOfIngredientDelivery == 'RouteSales')
            {
                response.grossSales = averageObjects[0].APTS_ALPCP_Routesales__c;
            }
            response.netSales = 0.0;
            System.debug('Gross sales:' + response.grossSales);
            System.debug('Net sales:' + response.netSales);
        }
        else
        {
            response.grossSales = 0.0;
            response.netSales = 0.0;
        }
        }catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString(), 'Agreement', null, 'OM', false, false, null, true);}
        return response;
    }
}