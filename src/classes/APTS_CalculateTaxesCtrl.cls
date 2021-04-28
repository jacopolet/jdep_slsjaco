/*
 * This class is used to calculate VAT and Additional tax on cart.
 * Created By - Karan Khatri
 * Created Date - 21st March, 2018
 * 
 * v100 - Aftab - Adding action method
*/

public without sharing class APTS_CalculateTaxesCtrl{
    private String flow;
    private String configRequestId;
    private String configId;
    private boolean excludeTAX;
    private boolean excludeVAT;
    public APTS_CalculateTaxesCtrl(Id configId){
        this.configId = configId;
        flow = null;
        configRequestId = null;
        excludeTAX=false;
        excludeVAT=false;
        Apttus_Config2__ProductConfiguration__c productConfig = new Apttus_Config2__ProductConfiguration__c();
        if(configId!=null)
        {
        productConfig = [select Apttus_CMConfig__AgreementId__r.APTS_Exclude_TAX__c,Apttus_CMConfig__AgreementId__r.APTS_Exclude_VAT__c,Apttus_CMConfig__AgreementId__c from Apttus_Config2__ProductConfiguration__c where id =: configId];
        if(productConfig.Apttus_CMConfig__AgreementId__c!=null){
            excludeTAX = productConfig.Apttus_CMConfig__AgreementId__r.APTS_Exclude_TAX__c;
            excludeVAT = productConfig.Apttus_CMConfig__AgreementId__r.APTS_Exclude_VAT__c;
        }
        }
    }
    public APTS_CalculateTaxesCtrl(ApexPages.StandardController stdController){
        this(ApexPages.currentPage().getParameters().get(APTS_CPQConstants.TAX_ID));
        flow = ApexPages.currentPage().getParameters().get(APTS_CPQConstants.FLOW);
        configRequestId = ApexPages.currentPage().getParameters().get(APTS_CPQConstants.CONFIG_REQUEST_ID);
    }
    
    public void calculateVATandAddTaxAction(){
        calculateVATandAddTax();
    }
    
    public PageReference calculateVATandAddTax(){
        List<Apttus_Config2__LineItem__c> lineItemsToUpdate = new List<Apttus_Config2__LineItem__c>();
        Map<ID,Apttus_Config2__FrequencyConversionRate__c> uomConversionMap= new Map<ID,Apttus_Config2__FrequencyConversionRate__c>();
        Set<String> toUOMSet = new Set<String>();
        Set<String> prodCodeSet = new Set<String>();
        Set<String> uomAPIParamSet = new Set<String>();
        try{
            //get exclude tax and exclude vat field from agreement in order to bypass logic
            if(configId!=null){
                //creating set for Pricing UOM and selling UOM
                for(Apttus_Config2__LineItem__c lineitem : [select id, Apttus_Config2__PriceUom__c,Apttus_Config2__OptionId__c,Apttus_Config2__OptionId__r.productcode,Apttus_Config2__SellingUom__c,Apttus_Config2__ProductId__r.productcode from Apttus_Config2__LineItem__c where Apttus_Config2__ConfigurationId__c=:configId]){
                    if(lineitem.Apttus_Config2__PriceUom__c!=null && lineitem.Apttus_Config2__SellingUom__c!=null){
                        if(lineitem.Apttus_Config2__OptionId__c!=null){

                            uomAPIParamSet.add(lineitem.Apttus_Config2__OptionId__r.productcode+';'+lineitem.Apttus_Config2__PriceUom__c+';'+lineitem.Apttus_Config2__SellingUom__c);

                            uomAPIParamSet.add(lineitem.Apttus_Config2__OptionId__r.productcode+';'+APTS_CPQConstants.PIECE_UOM_API+';'+lineitem.Apttus_Config2__PriceUom__c);
                        }else{

                            uomAPIParamSet.add(lineitem.Apttus_Config2__ProductId__r.productcode+';'+lineitem.Apttus_Config2__PriceUom__c+';'+lineitem.Apttus_Config2__SellingUom__c);
                            
                            uomAPIParamSet.add(lineitem.Apttus_Config2__ProductId__r.productcode+';'+APTS_CPQConstants.PIECE_UOM_API+';'+lineitem.Apttus_Config2__PriceUom__c);
                        }
                    }
                }
                //Created map for UOM table | gets all UOM table records matching with line item pricing UOM and selling UOM
                Map<String,Decimal> uomAPIResponseMap = APTS_UOMConversionUtils.getUOMConversions(uomAPIParamSet);
                //Iterate over line items and calculate additional taxes,weight and VAT
                for(Apttus_Config2__LineItem__c lineitem : [select id,Apttus_Config2__PriceListItemId__r.APTS_TXP_Disposal_Fee__c,Apttus_Config2__AttributeValueId__r.APTS_Refurbished__c,Apttus_Config2__AdjustmentType__c,Apttus_Config2__AdjustmentAmount__c,APTS_is_Tax_and_VAT_calculated__c,Apttus_Config2__ConfigurationId__c,Apttus_Config2__OptionId__c,Apttus_Config2__OptionId__r.productcode, Apttus_Config2__ProductId__c,Apttus_Config2__ProductId__r.productcode, Apttus_Config2__PriceUom__c,Apttus_Config2__SellingUom__c,APTS_Net_Price_Inc_taxes__c,Apttus_Config2__Quantity__c,Apttus_Config2__PriceListItemId__c,Apttus_Config2__PriceListItemId__r.APTS_Tax_per_UOM__c,Apttus_Config2__PriceListItemId__r.APTS_VAT_indicator__c,Apttus_Config2__PriceListItemId__r.APTS_VAT_percentage__c,Apttus_Config2__PricingStatus__c,APTS_Tax__c,APTS_VAT__c,Apttus_Config2__NetPrice__c from Apttus_Config2__LineItem__c where Apttus_Config2__ConfigurationId__c=:configId limit 50000]){
                    //imitialize all computing values to 0 | helps to see updated data
                    Decimal sellingUomConversionRate=0;
                    Decimal pricingUomConversionRate=0;
                    lineitem.APTS_Tax__c=0;
                    lineitem.APTS_VAT__c=0;
                    lineitem.APTS_Net_Price_Inc_taxes__c = 0;
                    // Added checks for Tax CR | If 100% discount then tax should be zero
                    if(lineitem.Apttus_Config2__PriceListItemId__c!=null && lineitem.Apttus_Config2__Quantity__c!=null && lineitem.Apttus_Config2__Quantity__c!=0 && lineitem.Apttus_Config2__NetPrice__c!=0) {
                         if(!uomAPIResponseMap.isEmpty() && lineitem.Apttus_Config2__PriceUom__c!=null && lineitem.Apttus_Config2__SellingUom__c!=null){
                            //get UOM converted value for line item based on Pricing UOM and Selling UOM
                            if(lineitem.Apttus_Config2__OptionId__c!=null && uomAPIResponseMap.get(lineitem.Apttus_Config2__OptionId__r.productcode+';'+APTS_CPQConstants.PIECE_UOM_API+';'+lineitem.Apttus_Config2__SellingUom__c)!=null){
                                sellingUomConversionRate = uomAPIResponseMap.get(lineitem.Apttus_Config2__OptionId__r.productcode+';'+APTS_CPQConstants.PIECE_UOM_API+';'+lineitem.Apttus_Config2__SellingUom__c);
                                pricingUomConversionRate = uomAPIResponseMap.get(lineitem.Apttus_Config2__OptionId__r.productcode+';'+APTS_CPQConstants.PIECE_UOM_API+';'+lineitem.Apttus_Config2__PriceUom__c);
                            }else if(uomAPIResponseMap.get(lineitem.Apttus_Config2__ProductId__r.productcode+';'+APTS_CPQConstants.PIECE_UOM_API+';'+lineitem.Apttus_Config2__SellingUom__c)!=null)     {                   
                                sellingUomConversionRate = uomAPIResponseMap.get(lineitem.Apttus_Config2__ProductId__r.productcode+';'+APTS_CPQConstants.PIECE_UOM_API+';'+lineitem.Apttus_Config2__SellingUom__c);
                                pricingUomConversionRate = uomAPIResponseMap.get(lineitem.Apttus_Config2__ProductId__r.productcode+';'+APTS_CPQConstants.PIECE_UOM_API+';'+lineitem.Apttus_Config2__PriceUom__c);
                            }
                        }
                        //calculate tax for line item 
                        if(sellingUomConversionRate!=null && pricingUomConversionRate!=null && sellingUomConversionRate!=0 && pricingUomConversionRate!=0 && !excludeTAX && lineitem.Apttus_Config2__PriceListItemId__r.APTS_Tax_per_UOM__c!=null){
                            // Added checks for Tax CR | If second hand machine is being bought , then tax should not be charged else normal flow
                            if(lineitem.Apttus_Config2__AttributeValueId__c!=null && lineitem.Apttus_Config2__AttributeValueId__r.APTS_Refurbished__c==APTS_CPQConstants.LABEL_YES && lineitem.Apttus_Config2__PriceListItemId__r.APTS_TXP_Disposal_Fee__c!=null && lineitem.Apttus_Config2__PriceListItemId__r.APTS_TXP_Disposal_Fee__c!=0){
                                lineitem.APTS_Tax__c = (lineitem.Apttus_Config2__Quantity__c * sellingUomConversionRate) * ((lineitem.Apttus_Config2__PriceListItemId__r.APTS_Tax_per_UOM__c - lineitem.Apttus_Config2__PriceListItemId__r.APTS_TXP_Disposal_Fee__c) / pricingUomConversionRate);
                            }else{
                                lineitem.APTS_Tax__c = (lineitem.Apttus_Config2__Quantity__c * sellingUomConversionRate) * (lineitem.Apttus_Config2__PriceListItemId__r.APTS_Tax_per_UOM__c / pricingUomConversionRate);
                            }       
                        }
                        //calculate Net Price Inclusive of taxes
                        if(lineitem.Apttus_Config2__NetPrice__c!=0){
                            if(lineitem.APTS_Tax__c!=0){
                                lineitem.APTS_Net_Price_Inc_taxes__c = lineitem.Apttus_Config2__NetPrice__c + lineitem.APTS_Tax__c;
                            }else{
                                 lineitem.APTS_Net_Price_Inc_taxes__c = lineitem.Apttus_Config2__NetPrice__c;
                            }
                        }
                        //calculate VAT for line item
                        if(lineitem.Apttus_Config2__PriceListItemId__r.APTS_VAT_percentage__c!=null &&  lineitem.Apttus_Config2__PriceListItemId__r.APTS_VAT_percentage__c!=0 && lineitem.Apttus_Config2__NetPrice__c!=null && lineitem.Apttus_Config2__NetPrice__c!=0 && !excludeVAT){
                           lineitem.APTS_VAT__c = lineitem.APTS_Net_Price_Inc_taxes__c * (lineitem.Apttus_Config2__PriceListItemId__r.APTS_VAT_percentage__c/100);
                        }
                    }
                     //update flag on line item to restrict user if he hasnt calculated tax and VAT
                    lineitem.APTS_is_Tax_and_VAT_calculated__c = true;

                    //lineitem.Apttus_Config2__PricingStatus__c= APTS_CPQConstants.LABEL_PRICING_COMPLETE;

                    //Add line items in List for updating
                    lineItemsToUpdate.add(lineitem);
                }
                //update line item list
                if(!lineItemsToUpdate.isEmpty()){
                    update lineItemsToUpdate;
                }
            }
            //Once everything is done redirect back to the cart.
            return GoBacktoCart();
        }catch(Exception e){
            APTS_CustomLogging.createErrorLog(e.getTypeName(), APTS_CPQConstants.APEX_NAME, e.getMessage()+'\n\n'+e.getStackTraceString() , APTS_CPQConstants.LINE_ITEM, ApexPages.currentPage().getParameters().get(APTS_CPQConstants.BSN_OBJ_ID),APTS_CPQConstants.CPQ,false,true,APTS_CPQConstants.KK_EAMIL,true);
            return null;
        }
    }
    //Method used to redirect back to the cart 
    public PageReference GoBacktoCart(){  
         PageReference pg;
         pg = Page.Apttus_Config2__Cart;
         pg.getParameters().put(APTS_CPQConstants.TAX_ID, configId);
         pg.getParameters().put(APTS_CPQConstants.FLOW,flow);       
         pg.getParameters().put(APTS_CPQConstants.CONFIG_REQUEST_ID, configRequestId);  
         pg.getParameters().put(APTS_CPQConstants.LAUNCH_STATE, APTS_CPQConstants.CART);     
         return pg; 
    }
    //gets converted rate for Pricing UOM and Selling UOM
    public static decimal getConversionRate(Map<ID,Apttus_Config2__FrequencyConversionRate__c> uomConversionMap,String fromUom,String toUom,String productCode){
        String prodID,prodFamily;
        Decimal conversionRate=0;
        if(toUom!=null && productCode!=null && fromUom!=null && !uomConversionMap.isEmpty()){
            //check if UOM conversion data exists for Product
            for(Apttus_Config2__FrequencyConversionRate__c uomConversion : uomConversionMap.values()){
                if(uomConversion.APTS_ProductCode__c == productCode && uomConversion.Apttus_Config2__FromUom__c == fromUom && uomConversion.Apttus_Config2__ToUom__c == toUom && uomConversion.Apttus_Config2__ConversionFactor__c!=null){
                    conversionRate = uomConversion.Apttus_Config2__ConversionFactor__c;
                    return conversionRate;
                }
            }
            /* COMMENTED because below scenerios wont exist --- only filtering with product code
             //check if UOM conversion data exists for Product Family
            if(conversionRate==0){
                for(Apttus_Config2__FrequencyConversionRate__c uomConversion : uomConversionMap.values()){
                    if(productFamily!=null && uomConversion.Apttus_Config2__ProductId__c==null && uomConversion.Apttus_Config2__ProductFamily__c == productFamily && uomConversion.Apttus_Config2__FromUom__c == fromUom && uomConversion.Apttus_Config2__ToUom__c == toUom && uomConversion.Apttus_Config2__ConversionFactor__c!=null){
                        conversionRate = uomConversion.Apttus_Config2__ConversionFactor__c;
                    }
                }
            }
            //If both of the above data doesnt exist choose generic data.
            if(conversionRate==0){
                for(Apttus_Config2__FrequencyConversionRate__c uomConversion : uomConversionMap.values()){
                    if(uomConversion.Apttus_Config2__FromUom__c == fromUom && uomConversion.Apttus_Config2__ToUom__c == toUom && uomConversion.Apttus_Config2__ConversionFactor__c!=null && uomConversion.Apttus_Config2__ProductFamily__c == null && uomConversion.Apttus_Config2__ProductId__c==null){
                        conversionRate = uomConversion.Apttus_Config2__ConversionFactor__c;
                    }
                }
            }*/
        }
        return 0;
    } 
}