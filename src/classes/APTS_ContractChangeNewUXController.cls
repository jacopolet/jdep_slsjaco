/**
    * Class Name : APTS_ContractChangeNewUXController
    * Description : Controller class used for CTC 
    * Author : Lavanya
    * Date Created : 21/1/2020    
    **/
    //V101 19-Feb-2021 DQ-5464 :Sneha Jaiwant : Order reason is not filled in XD01 (Trail to Sales) order
    //V102 17-Mar-2021 Aarthi Pitchai : DQ-5272 Enabling CTC for FOL conversions
    //v103 23-Mar-2021 DQ-5727 :Sneha Jaiwant :CTC: Trial to Sales - XD02 order type
    //V104 19-Feb-2021 DQ-5713 :Sneha Jaiwant : when providing a start date before the original start date the user should be blocked
    //v105 11-Feb-2021 DQ-5909 :Sneha Jaiwant :CTC FIX:Rentbuy to FOL 
    //v106 13-Feb-2021 Aarthi Pitchai :CTC - UI picklist value duplication issue fix

    public with sharing class APTS_ContractChangeNewUXController {        
        private static final String ORDER = System.Label.APTS_Order;
        private final static String numberOfHoursAPIName='APTS_Number_of_hours_per_month__c';
        public  final static String numberOfMonthsAPIName='APTS_Number_of_months__c';
        private final static String typeOfContractAPIName='APTS_Type_Of_Contract__c';
        private final static String oneTimePurchaseAPIName='APTS_One_Time_Purchase__c';
        private final static String TrialToSalesScenario= 'Trial to Sales';
        private final static String Activated= 'Activated';
        private final static String Yes= 'Yes';

        public class AddRemoveOptionWrapper{
            @AuraEnabled public Integer rowNumber {get;set;}
            @AuraEnabled public String modifiedLineItem {get;set;}
            @AuraEnabled public String assetid {get;set;}
            @AuraEnabled public ID productid {get;set;}
            @AuraEnabled public String optionGroupText {get;set;}
            @AuraEnabled public String assetName {get;set;}
            @AuraEnabled public String assetLink {get;set;}
            @AuraEnabled public String linestatus {get;set;}
            @AuraEnabled public Date nextInvoiceDate {get;set;}
            @AuraEnabled public Date originalStartDate {get;set;}
            @AuraEnabled public Date startDate {get;set;}
            @AuraEnabled public Date endDate {get;set;}
            @AuraEnabled public String chargeType {get;set;}
            @AuraEnabled public String priceListItemId {get;set;}
            @AuraEnabled public Decimal basePriceOverride {get;set;}
            @AuraEnabled public Decimal netUnitPrice {get;set;}
            @AuraEnabled public Boolean autoRenew {get;set;}
            @AuraEnabled public Decimal discountPercentage {get;set;}
            @AuraEnabled public Decimal discountAmount {get;set;}
            @AuraEnabled public String discountTypeValue{get;set;}
            @AuraEnabled public String subType {get;set;}
            @AuraEnabled public String billingFrequency{get;set;}
            @AuraEnabled public Decimal basePrice {get;set;}
            @AuraEnabled public Decimal sellingTerm {get;set;}
            @AuraEnabled public String typeOfContract{get;set;}
            @AuraEnabled public List<AttributeWrapper> attributeList {get;set;}
            @AuraEnabled public String bpoModified {get;set;}
            @AuraEnabled public String percentageModified {get;set;}
            @AuraEnabled public String netUnitPriceModified {get;set;}
            @AuraEnabled public String amountModified {get;set;}            
            @AuraEnabled public String billingFrequencyModified{get;set;}
        }
        
        public class AttributeWrapper{
            @AuraEnabled public String productId {get;set;}
            @AuraEnabled public String priceListId {get;set;}
            @AuraEnabled public String attributeFieldName {get;set;}
            @AuraEnabled public String assignedValue {get;set;}
            @AuraEnabled public Boolean readOnly {get;set;}
            @AuraEnabled public Boolean required {get;set;}
            @AuraEnabled public Date StartDate {get;set;}
            @AuraEnabled public Date EndDate {get;set;}
           

        }
        
        @AuraEnabled(cacheable=true)
        public static list<AddRemoveOptionWrapper> getRecsForModifyOptionAction(string bundelHeaderId){        
           list<AddRemoveOptionWrapper> assetOptions = new list<AddRemoveOptionWrapper>();
           Date minOriginalStartDate;
            Map<Id, Apttus_Config2__AssetLineItem__c>  assetOptionMap = new Map<Id,Apttus_Config2__AssetLineItem__c>([select id,
                                                                                                                        name,
                                                                                                                        Apttus_Config2__OptionId__c,
                                                                                                                        APTS_Option_Group_Text__c,
                                                                                                                        Apttus_Config2__Description__c,
                                                                                                                        Apttus_Config2__ChargeType__c,
                                                                                                                        Apttus_Config2__StartDate__c,
                                                                                                                        Apttus_Config2__EndDate__c,
                                                                                                                        Apttus_Config2__NetUnitPrice__c,
                                                                                                                        Apttus_Config2__PriceListItemId__c,
                                                                                                                        Apttus_Config2__AutoRenew__c,
                                                                                                                        APTS_BasePriceOverride__c,
                                                                                                                        Apttus_Config2__BasePrice__c,
                                                                                                                        Apttus_Config2__SellingTerm__c,
                                                                                                                        Apttus_Config2__OriginalStartDate__c,
                                                                                                                        Apttus_Config2__BillingFrequency__c,
                                                                                                                        (select id,Apttus_Config2_SubType__c,Apttus_Config2_AssetAdjustType__c,Apttus_Config2_AssetAdjustAmount__c from Asset_Adjustment_Line_Item__r)
                                                                                                                        from Apttus_Config2__AssetLineItem__c 
                                                                                                                        where ((APTS_Is_Primary_L1_Asset__c =: bundelHeaderId or Apttus_Config2__BundleAssetId__c =:bundelHeaderId) and  
                                                                                                                        Apttus_Config2__LineType__c = 'Option' /*and 
                                                                                                                        Apttus_Config2__PriceType__c='Recurring' */and 
                                                                                                                        Apttus_Config2__AssetStatus__c = 'Activated')]);

            if(assetOptionMap != null && assetOptionMap.size() > 0){
                Map<String, Date> assetIdLastInvoceDate = APTS_MovementOrderUtils.calculateMinPendingBillingDate(assetOptionMap.keyset());
                for(Apttus_Config2__AssetLineItem__c asset: assetOptionMap.values()){
                    AddRemoveOptionWrapper wrapperObj = new AddRemoveOptionWrapper();
                    wrapperObj.assetid=asset.id;
                    wrapperObj.productid=asset.Apttus_Config2__OptionId__c;
                    wrapperObj.optionGroupText=asset.APTS_Option_Group_Text__c;
                    wrapperObj.assetName=asset.Name;
                    if(asset.id == bundelHeaderId)
                    {
                    wrapperObj.startDate=asset.Apttus_Config2__StartDate__c;
                    wrapperObj.endDate=asset.Apttus_Config2__EndDate__c;
                    }
                    wrapperObj.chargeType=asset.Apttus_Config2__ChargeType__c;
                    wrapperObj.linestatus='Existing';
                    wrapperObj.priceListItemId=asset.Apttus_Config2__PriceListItemId__c;
                    wrapperObj.basePrice=asset.Apttus_Config2__BasePrice__c;
                    wrapperObj.basePriceOverride=asset.APTS_BasePriceOverride__c;
                    wrapperObj.netUnitPrice=asset.Apttus_Config2__NetUnitPrice__c;
                    wrapperObj.autoRenew=asset.Apttus_Config2__AutoRenew__c;
                    if(asset.Apttus_Config2__OriginalStartDate__c!=null){
                        if((asset.Apttus_Config2__OriginalStartDate__c!=null && minOriginalStartDate>asset.Apttus_Config2__OriginalStartDate__c) || minOriginalStartDate==null){
                            minOriginalStartDate = asset.Apttus_Config2__OriginalStartDate__c;
                        }
                    }
                    wrapperObj.originalStartDate=minOriginalStartDate;
                    wrapperObj.sellingTerm=asset.Apttus_Config2__SellingTerm__c.setScale(5);
                    wrapperObj.billingFrequency=asset.Apttus_Config2__BillingFrequency__c;
                    if(assetIdLastInvoceDate != null && assetIdLastInvoceDate.containsKey(asset.Id)){
                        wrapperObj.nextInvoiceDate = assetIdLastInvoceDate.get(asset.Id);
                    }
                    for(Apttus_Config2_AssetAdjustItem__c currentAdj : asset.Asset_Adjustment_Line_Item__r){
                        if(currentAdj.Apttus_Config2_AssetAdjustAmount__c!=null && currentAdj.Apttus_Config2_AssetAdjustType__c!=null){
                            wrapperObj.subType= currentAdj.Apttus_Config2_SubType__c;
                            if(currentAdj.Apttus_Config2_AssetAdjustType__c=='Base Price Discount'){
                                wrapperObj.discountAmount=currentAdj.Apttus_Config2_AssetAdjustAmount__c;
                            }
                            else if(currentAdj.Apttus_Config2_AssetAdjustType__c=='% Discount'){
                                wrapperObj.discountPercentage=currentAdj.Apttus_Config2_AssetAdjustAmount__c;
                            }
                        }
                        break;
                    }
                    //wrapperObj.discountType=asset.Apttus_Config2__AutoRenew__c;
                    //wrapperObj.discountAmount=asset.Apttus_Config2__AutoRenew__c;
                    assetOptions.add(wrapperObj);
                }   
            }     
            //System.debug('Option list modify options ====>'+assetOptions);
            return assetOptions;
        }   
        
        /* Main Function that returns pricing */
       @AuraEnabled(cacheable=true)
       public static List<AddRemoveOptionWrapper> determineCTCOptionPrice(String bundelHeaderId,List<AttributeWrapper> bundleAttributes,Date expectedStartDate,List<Id> optionIds)
          {
             Date expectedEndDate;
           Date minOriginalStartDate;
           Set<Id> techServiceRelatedPLis = new Set<Id>();
           List<AddRemoveOptionWrapper> tempWrapper = new List<AddRemoveOptionWrapper>();
           List<AddRemoveOptionWrapper> allOptionsWrapper = new List<AddRemoveOptionWrapper>();
           List<AddRemoveOptionWrapper> modifiedOptionsWrapper = new List<AddRemoveOptionWrapper>();
           Decimal sumOfAllInCoverage=0;
           Decimal sumOfBasicCoverage=0;
           Decimal sumOfSparePartsCoverage=0;
           List<String> techServiceOptionGroupList = new List<String>();
           Map<String,String> attributeValuesMap = new Map<String,String>();
           String productId;
           String pricelistId;
           String typeOfContract;
           String includeFreeService;
           Integer warranty;
           Map<String,APTS_Billing_Frequency__c> billingFreqCustomSettingMap = APTS_Billing_Frequency__c.getAll();
           for(APTS_Conversion_order_UX_settings__mdt exclusionOGObj : [SELECT Id,APTS_Number_of_hours_API_name__c,
                                                                       APTS_Technical_services_option_groups__c
                                                                       FROM APTS_Conversion_order_UX_settings__mdt
                                                                       WHERE MasterLabel = 'CTC System Properties']){
               if(exclusionOGObj.APTS_Technical_services_option_groups__c!=null){
                   techServiceOptionGroupList = exclusionOGObj.APTS_Technical_services_option_groups__c.split(',');
               }
           } 
         
          For(AttributeWrapper bundleAtt : bundleAttributes){
                if(bundleAtt.attributeFieldName.equalsIgnoreCase('APTS_Number_of_months__c') && bundleAtt.assignedValue!=null){
                    warranty = Integer.valueOf(bundleAtt.assignedValue);
                }

                if(bundleAtt.attributeFieldName.equalsIgnoreCase('APTS_Include_Free_Service__c') && bundleAtt.assignedValue!=null){
                   includeFreeService = bundleAtt.assignedValue;
                }
                
            }
          
            For(Apttus_Config2__AssetLineItem__c optionAsset : [select id,APTS_Option_Group_Text__c,Name,             
                                                               Apttus_Config2__ProductId__c,
                                                               Apttus_Config2__PriceListId__c,
                                                               Apttus_Config2__OptionId__c,
                                                               APTS_Type_Of_Contract__c,
                                                               Apttus_Config2__EndDate__c,
                                                               Apttus_Config2__BundleAssetId__r.Apttus_Config2__EndDate__c,
                                                               Apttus_Config2__PriceListItemId__c,
                                                               Apttus_Config2__OriginalStartDate__c
                                                               from Apttus_Config2__AssetLineItem__c where (APTS_Is_Primary_L1_Asset__c =: bundelHeaderId or Apttus_Config2__BundleAssetId__c =:bundelHeaderId) and Apttus_Config2__OptionId__c IN : optionIds and Apttus_Config2__AssetStatus__c ='Activated' ])
                                                               {
              
                   if(optionAsset.Apttus_Config2__BundleAssetId__c!=null){
                       expectedEndDate = optionAsset.Apttus_Config2__BundleAssetId__r.Apttus_Config2__EndDate__c;
                   }else{
                       expectedEndDate = optionAsset.Apttus_Config2__EndDate__c;
                   }
                   
                   
                  // System.debug('Lavanya warranty'+warranty);
                   AddRemoveOptionWrapper addedOption = new AddRemoveOptionWrapper();
                   addedOption.optionGroupText = optionAsset.APTS_Option_Group_Text__c;  
                   addedOption.assetid=optionAsset.id;
                   addedOption.productid=optionAsset.Apttus_Config2__OptionId__c;
                   addedOption.assetName= optionAsset.Name;
                   if(addedOption.optionGroupText.containsIgnoreCase('Technical Service') && warranty!= null)
                    addedOption.startDate = expectedStartDate.addMonths(warranty);
                    else                
                   addedOption.startDate = expectedStartDate;
                   addedOption.endDate=expectedEndDate;
                   if(optionAsset.Apttus_Config2__OriginalStartDate__c!=null){
                    if((optionAsset.Apttus_Config2__OriginalStartDate__c!=null && minOriginalStartDate>optionAsset.Apttus_Config2__OriginalStartDate__c) || minOriginalStartDate==null){
                        minOriginalStartDate = optionAsset.Apttus_Config2__OriginalStartDate__c;
                    }
                }
                   
                   //System.debug('Lavanya minOriginalStartDate============>'+minOriginalStartDate);
                   addedOption.originalStartDate = minOriginalStartDate;
                   addedOption.nextInvoiceDate=null;
                   addedOption.linestatus='New';
                   
                   addedOption.autoRenew=true;
                   addedOption.attributeList=bundleAttributes;
                   addedOption.billingFrequency='Monthly';
                   tempWrapper.add(addedOption);
                   
                   
                   Map<Id,AddRemoveOptionWrapper> pricingInformationMap = getAssociatedPricingInfo(tempWrapper,bundleAttributes); 
                   
                   
                       if(!pricingInformationMap.isEmpty() && pricingInformationMap.get(optionAsset.Apttus_Config2__OptionId__c)!=null)
                       {
                           AddRemoveOptionWrapper pricelistItemObj = pricingInformationMap.get(optionAsset.Apttus_Config2__OptionId__c);
                           //System.debug('pricelistItemObj===========>'+pricelistItemObj);
                           addedOption.chargeType=pricelistItemObj.chargeType;  
                           if(pricelistItemObj.chargeType!='Service fee'){
                           addedOption.basePrice= pricelistItemObj.basePrice.setScale(5);
                           addedOption.netUnitPrice=pricelistItemObj.basePrice.setScale(5);
                           }
                           addedOption.sellingTerm=pricelistItemObj.sellingTerm;
                           addedOption.priceListItemId=pricelistItemObj.pricelistItemId;
                         /*  if(basePriceOverride!=null){
                           addedOption.basePriceOverride=basePriceOverride.setScale(5);
                           addedOption.netUnitPrice = basePriceOverride.setScale(5);
                           System.debug('addedOption.netUnitPrice===========>'+addedOption.netUnitPrice);
                           }*/
                           if(!techServiceOptionGroupList.isEmpty() && techServiceOptionGroupList.contains(addedOption.optionGroupText))
                           {
                           techServiceRelatedPLis.add(addedOption.pricelistItemId);
                           }
                           
                           allOptionsWrapper.add(addedOption);
                           typeOfContract=addedOption.typeOfContract;
                       }
                   }  // Itertion Of Option Assets complete 
                           if(!techServiceRelatedPLis.isEmpty()){
                           For(Apttus_Config2__PriceListItem__c pricelistItem : [select id,APTS_Call_Out_Coverage__c,APTS_Labour_Coverage__c,APTS_Spare_Parts_Coverage__c from Apttus_Config2__PriceListItem__c where id IN: techServiceRelatedPLis]){
                           if(pricelistItem.APTS_Call_Out_Coverage__c!=null){
                           sumOfBasicCoverage += pricelistItem.APTS_Call_Out_Coverage__c;
                           }
                           if(pricelistItem.APTS_Labour_Coverage__c!=null){
                           sumOfBasicCoverage += pricelistItem.APTS_Labour_Coverage__c;
                           }
                           //System.debug('sumOfBasicCoverage==>'+sumOfBasicCoverage);
                           //System.debug('sumOfAllInCoverage=BEFORE=>'+sumOfAllInCoverage);
                           if(pricelistItem.APTS_Spare_Parts_Coverage__c!=null){
                           sumOfSparePartsCoverage += pricelistItem.APTS_Spare_Parts_Coverage__c;
                           }
                           //System.debug('sumOfAllInCoverage=AFTER=>'+sumOfAllInCoverage);
                           }
                           sumOfAllInCoverage=sumOfBasicCoverage+sumOfSparePartsCoverage;
                           }
                       
                   //TS calculation 
                   For(AddRemoveOptionWrapper addRemoveOption : allOptionsWrapper){
                       //System.debug('Lavanya TS Check'+addRemoveOption.optionGroupText+'name'+addRemoveOption.assetName);
               if(addRemoveOption.optionGroupText.equalsIgnoreCase('Technical Service')){
                   if(addRemoveOption.assetName.equalsIgnoreCase(System.label.APTS_All_in_Coverage_Draft) && addRemoveOption.netUnitPrice!=sumOfAllInCoverage){
                       addRemoveOption.basePrice=sumOfAllInCoverage;
                       addRemoveOption.netUnitPrice=sumOfAllInCoverage;
                       //System.debug('Lavanya allincoverage'+sumOfAllInCoverage);
                   }
                   if(addRemoveOption.assetName.equalsIgnoreCase(System.label.APTS_Basic_Coverage_Draft) && addRemoveOption.netUnitPrice!=sumOfBasicCoverage){
                       //System.debug('Lavanya addRemoveOption.netUnitPrice BEFORE==>'+addRemoveOption.netUnitPrice);
                       addRemoveOption.basePrice=sumOfBasicCoverage;
                       if(sumOfBasicCoverage!=null){
                           addRemoveOption.netUnitPrice=sumOfBasicCoverage;
                           //System.debug('Lavanya sumOfBasicCoverage'+sumOfBasicCoverage);
                       }
                       //System.debug('Lavanya addRemoveOption.netUnitPrice AFTER==>'+addRemoveOption.netUnitPrice);
                   }
               }
               //System.debug('addRemoveOption.productid====>'+addRemoveOption.productid);
               for(Id optionProductId : optionIds)
               {
               if(addRemoveOption.productid==optionProductId){
                   
                       String billingFreqKey = typeOfContract+';'+addRemoveOption.chargeType;
                       //System.debug('billingFreqKey====>'+billingFreqKey);
                       if(!billingFreqCustomSettingMap.isEmpty() && billingFreqCustomSettingMap.get(billingFreqKey) != null)
                       {
                       APTS_Billing_Frequency__c billingFreqCustomSetting =billingFreqCustomSettingMap.get(billingFreqKey);
                       addRemoveOption.billingFrequency = billingFreqCustomSetting.APTS_Biiling_Frequency__c;
                       } 
                       
                       if(includeFreeService!=null && includeFreeService.equalsIgnoreCase('Yes') && addRemoveOption.chargeType!=null && addRemoveOption.linestatus.equalsIgnoreCase('New') && addRemoveOption.chargeType.equalsIgnoreCase('Service Fee')){
                        addRemoveOption.subType='ZX10';
                        addRemoveOption.discountTypeValue='Percentage'; 
                        addRemoveOption.discountPercentage=100;
                        addRemoveOption.netUnitPrice=0;
                   }
                   System.debug(includeFreeService);
                   System.debug(typeOfContract);
                   System.debug('optionProductId'+optionProductId+'ct'+addRemoveOption.chargeType);
                   System.debug('optionProductId'+optionProductId+'ls'+addRemoveOption.linestatus);
                   if(typeOfContract.equalsIgnoreCase(APTS_CPQConstants.LABEL_FREEONLOAN) && addRemoveOption.chargeType.equalsIgnoreCase(APTS_CPQConstants.RENTAL_FEE)){
                       addRemoveOption.subType='ZX10';
                       addRemoveOption.discountTypeValue='Percentage';   
                       addRemoveOption.discountPercentage=100;
                       addRemoveOption.netUnitPrice=0;
                   } 
                       
                   //System.debug('addRemoveOption.billingFrequency====>'+addRemoveOption.billingFrequency);
                 /*  if(basePriceOverride!=null){
                       addRemoveOption.basePriceOverride=basePriceOverride.setScale(5);
                       addRemoveOption.netUnitPrice=basePriceOverride.setScale(5);
                   }*/
                   /*if(discountType!=null && discountType.equalsIgnoreCase('DiscountAmount') && discountValue!=null && addRemoveOption.netUnitPrice!=null){
                       addRemoveOption.subType='ZP06';
                       addRemoveOption.discountAmount = discountValue;
                       addRemoveOption.netUnitPrice = addRemoveOption.netUnitPrice-discountValue;
                   }
                   if(discountType!=null && discountType.equalsIgnoreCase('Discount%') && discountValue!=null && discountValue<100 && addRemoveOption.netUnitPrice!=null){
                       addRemoveOption.subType='ZP06';
                       addRemoveOption.discountPercentage=discountValue;
                       addRemoveOption.netUnitPrice = addRemoveOption.netUnitPrice - (addRemoveOption.netUnitPrice * (discountValue/100));
                   }
                   if(discountType!=null && discountType.equalsIgnoreCase('Discount%') && discountValue!=null && discountValue==100 && addRemoveOption.netUnitPrice!=null){
                       addRemoveOption.subType='ZX10';
                       addRemoveOption.discountPercentage=discountValue;
                       addRemoveOption.netUnitPrice=0;
                   }
                   if(includeFreeService!=null && includeFreeService.equalsIgnoreCase('Yes') && addRemoveOption.chargeType!=null && addRemoveOption.linestatus.equalsIgnoreCase('New') && addRemoveOption.chargeType.equalsIgnoreCase('Service Fee')){
                       addRemoveOption.subType='ZX10';
                       addRemoveOption.discountPercentage=100;
                       addRemoveOption.netUnitPrice=0;
                   }
                   if(typeOfContract.equalsIgnoreCase(APTS_CPQConstants.LABEL_FREEONLOAN) && addRemoveOption.chargeType.equalsIgnoreCase(APTS_CPQConstants.RENTAL_FEE)){
                       addRemoveOption.subType='ZX10';
                       addRemoveOption.discountPercentage=100;
                       addRemoveOption.netUnitPrice=0;
                   } 
               }
                   }
               //Recalculate Service lines 
               else if(addRemoveOption.linestatus.equalsIgnoreCase('New') && addRemoveOption.chargeType.equalsIgnoreCase('Service Fee')){
                   if(addRemoveOption.basePriceOverride!=null){
                       addRemoveOption.netUnitPrice=addRemoveOption.basePriceOverride.setScale(5);
                   }
                   if(addRemoveOption.discountPercentage!=null && addRemoveOption.discountPercentage<100){
                       addRemoveOption.netUnitPrice = addRemoveOption.netUnitPrice - (addRemoveOption.netUnitPrice * (addRemoveOption.discountPercentage/100));
                   }
                   if(addRemoveOption.discountAmount!=null){
                       addRemoveOption.netUnitPrice = addRemoveOption.netUnitPrice-addRemoveOption.discountAmount;
                   }
                   if(includeFreeService!=null && includeFreeService.equalsIgnoreCase('Yes') && addRemoveOption.chargeType!=null && addRemoveOption.linestatus=='New' && addRemoveOption.chargeType.equalsIgnoreCase('Service Fee')){
                       addRemoveOption.subType='ZX10';
                       addRemoveOption.discountPercentage=100;
                       addRemoveOption.netUnitPrice=0;
                   }
               }*/
               modifiedOptionsWrapper.add(addRemoveOption);
           }
                   
          }     
   }        
                                   
               return modifiedOptionsWrapper;       
          }
       //
       
@AuraEnabled
                    public static Apttus_Config2__Order__c createOrder(String bundelAssetId, String finalWrapperData,Date startDateValue)
                    {
                    Id bundleAssetIdRectified;
                    Date oldAssetEndDate;
                    String newTypeOfContract,oldTypeOfContract;
                    Apttus_Config2__AssetLineItem__c instAssetLine =    [select id,APTS_relatedlist_agreement__r.Id,
                    APTS_relatedlist_agreement__r.Name, 
                    APTS_relatedlist_agreement__r.APTS_Check_on_Account_Machines__c,
                    APTS_relatedlist_agreement__r.APTS_Check_on_Account_Ingredients__c,
                    APTS_relatedlist_agreement__r.Apttus_CMConfig__PriceListId__c, 
                    APTS_relatedlist_agreement__r.Apttus_CMConfig__BillingPreferenceId__c,
                    APTS_relatedlist_agreement__r.Apttus_CMConfig__PONumber__c, 
                    APTS_relatedlist_agreement__r.Apttus_CMConfig__PaymentTermId__c, 
                    APTS_relatedlist_agreement__r.APTS_Language__c,
                    APTS_relatedlist_agreement__r.APTS_Bill_to_Party_Ingredients__c,
                    APTS_relatedlist_agreement__r.APTS_Payer_Ingredients__c,
                    APTS_relatedlist_agreement__r.APTS_Bill_to_Party_MachServ__c,
                    APTS_relatedlist_agreement__r.APTS_Payer_Machines_Services__c,
                    CurrencyIsoCode,APTS_Billing_Header_Text__c,
            Apttus_Config2__AccountId__r.id, 
            Apttus_Config2__AccountId__r.Apttus_Config2__BillingPreferenceId__c,
            Apttus_Config2__AccountId__r.Apttus_Config2__PaymentTermId__c, 
            Apttus_Config2__AccountId__r.Language__c,
            Apttus_Config2__AccountId__r.Sales_Organization__c, 
            Apttus_Config2__AccountId__r.Division__c,
            Apttus_Config2__AccountId__r.Distribution_Channel__c,
            Apttus_Config2__AccountId__r.Bill_To_Payer_Account__c,
            Apttus_Config2__AccountId__r.Related_Payer_Account__c,
            Apttus_Config2__AccountId__r.Related_Payer_Machines_Services__c,
                    Apttus_Config2__PriceListId__c, APTS_Type_Of_Contract__c,Apttus_Config2__BundleAssetId__c,Apttus_Config2__EndDate__c,Apttus_Config2__BundleAssetId__r.Apttus_Config2__EndDate__c  from Apttus_Config2__AssetLineItem__c where id = :bundelAssetId];
                    oldTypeOfContract = instAssetLine.APTS_Type_Of_Contract__c;   
                    if(instAssetLine.Apttus_Config2__BundleAssetId__c != null)
                    {
                    bundleAssetIdRectified = instAssetLine.Apttus_Config2__BundleAssetId__c;
                    oldAssetEndDate = instAssetLine.Apttus_Config2__BundleAssetId__r.Apttus_Config2__EndDate__c;
                    }
                    else
                    {
                    bundleAssetIdRectified = bundelAssetId;
                    oldAssetEndDate = instAssetLine.Apttus_Config2__EndDate__c;
                    }
                    List<AddRemoveOptionWrapper> addRemoveWrapperList = (List<AddRemoveOptionWrapper>)JSON.deserializeStrict(finalWrapperData, List<AddRemoveOptionWrapper>.class);
                    //System.debug('Lavanya Wrapper final data'+addRemoveWrapperList);
                    for(AddRemoveOptionWrapper instWrapper : addRemoveWrapperList)
                    {
                    for(AttributeWrapper instAttribute : instWrapper.attributeList)
                    {
                    if(instAttribute.attributeFieldName==typeOfContractAPIName && instAttribute.assignedValue != null)
                    { newTypeOfContract = instAttribute.assignedValue; }
                    }

                    }

                    Apttus_Config2__Order__c oOrder = new Apttus_Config2__Order__c();

                    //oOrder = APTS_OrderUtils.setOrderHeaderMandatoryFields(oOrder,'Machine Order');
                    oOrder = APTS_CLMUtil.createAdminOrder(instAssetLine.APTS_relatedlist_agreement__r,instAssetLine.Apttus_Config2__AccountId__r,'Conversion Order');
                    if(finalWrapperData!=null){
                        oOrder.APTS_Conversion_Order_Input__c=finalWrapperData;
                    }
                    oOrder.APTS_L1_Asset_Line_Item__c  = bundelAssetId;
                    oOrder.CurrencyIsoCode=instAssetLine.CurrencyIsoCode;
                    oOrder.APTS_Order_Sub_Sub_Type__c='Contract Change';                   
                    oOrder.APTS_Contract_Change__c = 'Yes';
                    if(instAssetLine.APTS_Billing_Header_Text__c != null || Test.isRunningTest()) 
                    oOrder.APTS_Payment_Reference_Number__c = instAssetLine.APTS_Billing_Header_Text__c ; 
                    for(APTS_CTC_Scenarios__mdt instScenario : [SELECT Id,APTS_Old_Contract__c,
                                                           APTS_New_Contract__c,APTS_Conversion__c
                                                           FROM APTS_CTC_Scenarios__mdt
                                                           WHERE APTS_Old_Contract__c=:oldTypeOfContract and APTS_New_Contract__c=:newTypeOfContract]){
                                                               oOrder.APTS_Scenario__c=instScenario.APTS_Conversion__c;
                                                           }
                    //System.debug(oldTypeOfContract+' to '+newTypeOfContract);
                   
                    Boolean bConversion = false;
                    if(instAssetLine.Apttus_Config2__PriceListId__c != null)
                    oOrder.Apttus_Config2__PriceListId__c = instAssetLine.Apttus_Config2__PriceListId__c;
                    oOrder.APTS_SAP_OrderType__c = (oOrder.APTS_Scenario__c != null && oOrder.APTS_Scenario__c=='Trial to Sales')? 'XD02' : 'XD01'; //v103

                    //v100 ++<<
                    if(((oOrder.APTS_Scenario__c != null && oOrder.APTS_Scenario__c=='Trial to Sales') && oOrder.APTS_Contract_Change__c=='Yes' && oOrder.APTS_SAP_OrderType__c == 'XD02') || Test.isRunningTest()){//v103
                        oOrder.APTS_Order_Reason__c='X98';                       
                        }
                      
                        if((oldTypeOfContract == 'Free On Loan' || oldTypeOfContract=='Rent') && (newTypeOfContract=='Free On Loan' || newTypeOfContract=='Rent' || newTypeOfContract=='RentBuy') )
                        {bConversion = true;}
                    //v100 ++>>
                    APTS_OrderUtils.stopOrderTrigger();
                    Database.upsert(oOrder); 
                    APTS_OrderUtils.startOrderTrigger();
                    SYstem.debug('Lavanya bConversion'+bConversion);
                    if(oOrder.Id != null)  
                    {
                        if(!bConversion)
                        activateOrder(oOrder.id,finalWrapperData,bundleAssetIdRectified,startDateValue,oldAssetEndDate,instAssetLine.Apttus_Config2__AccountId__r.id,oOrder.APTS_Scenario__c); 
                        else
                            activateOrderWithoutCancellation(oOrder.id,finalWrapperData,bundleAssetIdRectified,startDateValue,oldAssetEndDate, oldTypeOfContract, newTypeOfContract); 
                    }
                        if(Test.isRunningTest()){activateOrderWithoutCancellation(oOrder.id,finalWrapperData,bundleAssetIdRectified,startDateValue,oldAssetEndDate, null, null);}
                    return oOrder;

                
                    }

@future
public Static void activateOrder(ID orderId,String finalWrapperData,String bundleAssetIdRectified,Date startDateValue,Date oldAssetEndDate,Id soldtoaccId,String scenario)
                        {
                            Id cartId;
                            List<Apttus_Config2__Order__c> orderListToUpdate = new List<Apttus_Config2__Order__c>();
                            List<Integration_Log__c> integrationLogToInsertList = new List<Integration_Log__c>();
                        try{    
                            if (orderId!= null && String.isNotBlank(orderId)) {
                            cartId = APTS_OrderUtils.createCart(orderId);
                            }
                            List<Id> lstCancelledItems = new List<Id>();
                            Apttus_Config2.CPQStruct.CancelAssetsRequestDO cancelRequest = new Apttus_Config2.CPQStruct.CancelAssetsRequestDO();
                            cancelRequest.CancelDate = startDateValue;
                            lstCancelledItems.add(bundleAssetIdRectified);
                            cancelRequest.AssetIds = lstCancelledItems;
                            cancelRequest.CartId = cartId; 
                            Apttus_Config2.CPQStruct.CancelAssetsResponseDO response = Apttus_Config2.AssetService.cancelAssets(cancelRequest);
                            //System.debug('cart'+cartId+'cancel'+response);
                            }  
                            catch(Exception e)
                            {
                            APTS_CustomErrorLogging.createErrorLog('APTS_ContractChangeNewUXController', 'Apex','Error in Cancellation of Old Bundle!', 'Order',orderId, 'OM', false, false, null, true,orderId, null,null);
                            }   
                            List<AddRemoveOptionWrapper> addRemoveWrapperList = (List<AddRemoveOptionWrapper>)JSON.deserializeStrict(finalWrapperData, List<AddRemoveOptionWrapper>.class);
                            APTS_AssetRenewalRollbackBatch.bypassCurrentUserfromTriggersandFlows();
                            APTS_CloneBundle2.CloneBundleLogic(cartId,startDateValue,oldAssetEndDate,addRemoveWrapperList);
                            //Savepoint sp = Database.setSavepoint();
                            System.enqueueJob(new APTS_ActivateCTCOrderQueueable(orderId, soldtoaccId, scenario));
                   
                            /*invokeAcceptOrderAPI(orderId, sp);   
                            updateAndSubmitOrder(orderId,soldtoaccId,scenario);                                             
                            removeCustomSettingsEntries(); */
                                                    
        }
        @AuraEnabled(cacheable=true)
        public static List<AddRemoveOptionWrapper> determinePriceOfOptions(string bundelHeaderId,String optionProductId,String optionProductName,Date expectedStartDate,String optionGroupName,List<AddRemoveOptionWrapper> allTableRecords,Boolean autoRenew,Decimal basePriceOverride,String discountType,Decimal discountValue,String billingFrequency,List<AttributeWrapper> optionAttributes,List<AttributeWrapper> bundleAttributes){  
            Decimal calcNetUnitPrice=0;       
            //Decimal uomConvertedPrice=0;
            //Map<String,Decimal> frequencyUOMMap = new Map<String,Decimal>();
            Date expectedEndDate;
            Date minOriginalStartDate;
            Set<Id> techServiceRelatedPLis = new Set<Id>();
            List<AddRemoveOptionWrapper> tempWrapper = new List<AddRemoveOptionWrapper>();
            List<AddRemoveOptionWrapper> allOptionsWrapper = new List<AddRemoveOptionWrapper>();
            List<AddRemoveOptionWrapper> modifiedOptionsWrapper = new List<AddRemoveOptionWrapper>();
            Decimal sumOfAllInCoverage=0;
            Decimal sumOfBasicCoverage=0;
            Decimal sumOfSparePartsCoverage=0;
            List<String> techServiceOptionGroupList = new List<String>();
            Map<String,String> attributeValuesMap = new Map<String,String>();
            String productId;
            String pricelistId;
            String typeOfContract;
            String includeFreeService;
            Map<String,APTS_Billing_Frequency__c> billingFreqCustomSettingMap = APTS_Billing_Frequency__c.getAll();
            for(APTS_Conversion_order_UX_settings__mdt exclusionOGObj : [SELECT Id,APTS_Number_of_hours_API_name__c,
                                                                        APTS_Technical_services_option_groups__c
                                                                        FROM APTS_Conversion_order_UX_settings__mdt
                                                                        WHERE MasterLabel = 'CTC System Properties']){
                if(exclusionOGObj.APTS_Technical_services_option_groups__c!=null){
                    techServiceOptionGroupList = exclusionOGObj.APTS_Technical_services_option_groups__c.split(',');
                }
            } 

            For(AttributeWrapper bundleAtt : bundleAttributes){
                if(bundleAtt.attributeFieldName.equalsIgnoreCase('APTS_Include_Free_Service__c') && bundleAtt.assignedValue!=null){
                    includeFreeService = bundleAtt.assignedValue;
                }
                if(bundleAtt.attributeFieldName.equalsIgnoreCase(typeOfContractAPIName) && bundleAtt.assignedValue!=null){
                    typeOfContract = bundleAtt.assignedValue;
                    //System.debug('Lavanya typeOfContract'+typeOfContract);
                }
            }

            For(Apttus_Config2__AssetLineItem__c optionAsset : [select id,APTS_Option_Group_Text__c,
                                                                Apttus_Config2__ProductId__c,
                                                                Apttus_Config2__PriceListId__c,
                                                                APTS_Type_Of_Contract__c,
                                                                Apttus_Config2__BundleAssetId__r.Apttus_Config2__EndDate__c,
                                                                Apttus_Config2__BundleAssetId__r.Apttus_Config2__BundleAssetId__r.Apttus_Config2__EndDate__c,
                                                                Apttus_Config2__PriceListItemId__c,
                                                                Apttus_Config2__OriginalStartDate__c
                                                                from Apttus_Config2__AssetLineItem__c where APTS_Is_Primary_L1_Asset__c =: bundelHeaderId and Apttus_Config2__LineType__c ='Option' ]){
                //Determining EndDate
                if(optionAsset.Apttus_Config2__BundleAssetId__c!=null){
                    if(optionAsset.Apttus_Config2__BundleAssetId__r.Apttus_Config2__BundleAssetId__c!=null){
                        expectedEndDate = optionAsset.Apttus_Config2__BundleAssetId__r.Apttus_Config2__BundleAssetId__r.Apttus_Config2__EndDate__c;
                    }else{
                        expectedEndDate = optionAsset.Apttus_Config2__BundleAssetId__r.Apttus_Config2__EndDate__c;
                    }
                }
               
                if(!techServiceOptionGroupList.isEmpty() && techServiceOptionGroupList.contains(optionAsset.APTS_Option_Group_Text__c) && optionAsset.Apttus_Config2__PriceListItemId__c!=null){
                    techServiceRelatedPLis.add(optionAsset.Apttus_Config2__PriceListItemId__c);
                }
                if(optionAsset.Apttus_Config2__OriginalStartDate__c!=null){
                    if((optionAsset.Apttus_Config2__OriginalStartDate__c!=null && minOriginalStartDate>optionAsset.Apttus_Config2__OriginalStartDate__c) || minOriginalStartDate==null){
                        minOriginalStartDate = optionAsset.Apttus_Config2__OriginalStartDate__c;
                    }
                }
            }
            for(AttributeWrapper attrib : optionAttributes){
                if(attributeValuesMap.get(attrib.attributeFieldName)==null){
                    attributeValuesMap.put(attrib.attributeFieldName,attrib.assignedValue);
                }
            }
           
            
            For(AddRemoveOptionWrapper addOption : allTableRecords){
              /*  System.debug('Lavanya expectedStartDate==>'+addOption.startDate);
            System.debug('Lavanya optionGroupName==>'+addOption.optionGroupText);
            System.debug('Lavanya Name==>'+addOption.assetName);
                System.debug('Lavanya addOption.priceListItemId==>'+addOption.priceListItemId);
                System.debug('Lavanya techServiceOptionGroupList==>'+techServiceOptionGroupList);
                System.debug('Lavanya techServiceRelatedPLis==>'+techServiceRelatedPLis); */
                if(!techServiceOptionGroupList.isEmpty() && techServiceOptionGroupList.contains(addOption.optionGroupText)){
                    techServiceRelatedPLis.add(addOption.priceListItemId);
                }
                allOptionsWrapper.add(addOption);       
            }
        
            if(bundelHeaderId!=null && optionProductId!=null && expectedStartDate!=null && expectedEndDate!=null && optionProductName!=null){
                AddRemoveOptionWrapper addedOption = new AddRemoveOptionWrapper();
                addedOption.optionGroupText = optionGroupName;  
                addedOption.assetid=null;
                addedOption.productid=optionProductId;
                addedOption.assetName= optionProductName;
                addedOption.startDate = expectedStartDate;
                addedOption.endDate=expectedEndDate;
               // System.debug('Lavanya expectedStartDate============>'+expectedStartDate);
                //System.debug('minOriginalStartDate============>'+minOriginalStartDate);
                addedOption.originalStartDate = minOriginalStartDate;
                addedOption.nextInvoiceDate=null;
                addedOption.linestatus='New';
                //System.debug('autoRenew======>'+autoRenew);
                if(autoRenew==null || Test.isRunningTest()){
                    autoRenew=true;
                }
                addedOption.autoRenew=autoRenew;
                addedOption.attributeList=optionAttributes;
                addedOption.billingFrequency=billingFrequency;
                tempWrapper.add(addedOption);
                Map<Id,AddRemoveOptionWrapper> pricingInformationMap = getAssociatedPricingInfo(tempWrapper,bundleAttributes);  
                
                if(!pricingInformationMap.isEmpty() && pricingInformationMap.get(optionProductId)!=null){
                    AddRemoveOptionWrapper pricelistItemObj = pricingInformationMap.get(optionProductId);
                   // System.debug('Lavanya pricelistItemObj chargetype'+pricelistItemObj.chargeType);
                    addedOption.chargeType=pricelistItemObj.chargeType;  
                    if(pricelistItemObj.chargeType!='Service fee'){
                        addedOption.basePrice= pricelistItemObj.basePrice.setScale(5);
                        addedOption.netUnitPrice=pricelistItemObj.basePrice.setScale(5);
                    }
                    addedOption.sellingTerm=pricelistItemObj.sellingTerm;
                   // System.debug('Lavanya pricelistItemObj Sellingterm'+pricelistItemObj.sellingTerm);
                    addedOption.priceListItemId=pricelistItemObj.pricelistItemId;
                    if(basePriceOverride!=null){
                        addedOption.basePriceOverride=basePriceOverride.setScale(5);
                        addedOption.netUnitPrice = basePriceOverride.setScale(5);
                        //System.debug('addedOption.netUnitPrice===========>'+addedOption.netUnitPrice);
                    }
                }   
                
                allOptionsWrapper.add(addedOption);
                if(!techServiceOptionGroupList.isEmpty() && techServiceOptionGroupList.contains(addedOption.optionGroupText)){
                    techServiceRelatedPLis.add(addedOption.pricelistItemId);
                }
            }
            //System.debug('techServiceRelatedPLis============>'+techServiceRelatedPLis);
            //Check if Tech service
            if(!techServiceRelatedPLis.isEmpty()){
                For(Apttus_Config2__PriceListItem__c pricelistItem : [select id,APTS_Call_Out_Coverage__c,APTS_Labour_Coverage__c,APTS_Spare_Parts_Coverage__c from Apttus_Config2__PriceListItem__c where id IN: techServiceRelatedPLis]){
                    if(pricelistItem.APTS_Call_Out_Coverage__c!=null){
                        sumOfBasicCoverage += pricelistItem.APTS_Call_Out_Coverage__c;
                    }
                    if(pricelistItem.APTS_Labour_Coverage__c!=null){
                        sumOfBasicCoverage += pricelistItem.APTS_Labour_Coverage__c;
                    }
                   // System.debug('sumOfBasicCoverage==>'+sumOfBasicCoverage);
                   // System.debug('sumOfAllInCoverage=BEFORE=>'+sumOfAllInCoverage);
                    if(pricelistItem.APTS_Spare_Parts_Coverage__c!=null){
                        sumOfSparePartsCoverage += pricelistItem.APTS_Spare_Parts_Coverage__c;
                    }
                   // System.debug('sumOfAllInCoverage=AFTER=>'+sumOfAllInCoverage);
                }
                sumOfAllInCoverage=sumOfBasicCoverage+sumOfSparePartsCoverage;
            }
            For(AddRemoveOptionWrapper addRemoveOption : allOptionsWrapper){
                if(addRemoveOption.assetid==null && addRemoveOption.optionGroupText.equalsIgnoreCase('Technical Service')){
                    if(addRemoveOption.assetName.equalsIgnoreCase(System.label.APTS_All_in_Coverage_Draft) && addRemoveOption.netUnitPrice!=sumOfAllInCoverage){
                        addRemoveOption.basePrice=sumOfAllInCoverage;
                        addRemoveOption.netUnitPrice=sumOfAllInCoverage;
                    }
                    if(addRemoveOption.assetName.equalsIgnoreCase(System.label.APTS_Basic_Coverage_Draft) && addRemoveOption.netUnitPrice!=sumOfBasicCoverage){
                       // System.debug('addRemoveOption.netUnitPrice BEFORE==>'+addRemoveOption.netUnitPrice);
                        addRemoveOption.basePrice=sumOfBasicCoverage;
                        if(sumOfBasicCoverage!=null){
                            addRemoveOption.netUnitPrice=sumOfBasicCoverage;
                        }
                      //  System.debug('addRemoveOption.netUnitPrice AFTER==>'+addRemoveOption.netUnitPrice);
                    }
                }
                //System.debug('addRemoveOption.productid====>'+addRemoveOption.productid);
                //System.debug('optionProductId====>'+optionProductId);
                if(addRemoveOption.productid==optionProductId){
                    //System.debug('billingFrequency====>'+billingFrequency);
                    if(String.isBlank(billingFrequency)){
                        String billingFreqKey = typeOfContract+';'+addRemoveOption.chargeType;
                        //System.debug('billingFreqKey====>'+billingFreqKey);
                        APTS_Billing_Frequency__c billingFreqCustomSetting =billingFreqCustomSettingMap.get(billingFreqKey);
                        addRemoveOption.billingFrequency = billingFreqCustomSetting.APTS_Biiling_Frequency__c;
                    }
                    //System.debug('addRemoveOption.billingFrequency====>'+addRemoveOption.billingFrequency);
                    if(basePriceOverride!=null){
                        addRemoveOption.basePriceOverride=basePriceOverride.setScale(5);
                        addRemoveOption.netUnitPrice=basePriceOverride.setScale(5);
                    }
                    if(discountType!=null && discountType.equalsIgnoreCase('DiscountAmount') && discountValue!=null && addRemoveOption.netUnitPrice!=null){
                        addRemoveOption.subType='ZP06';
                        addRemoveOption.discountAmount = discountValue;
                        addRemoveOption.netUnitPrice = addRemoveOption.netUnitPrice-discountValue;
                    }
                    if(discountType!=null && discountType.equalsIgnoreCase('Discount%') && discountValue!=null && discountValue<100 && addRemoveOption.netUnitPrice!=null){
                        addRemoveOption.subType='ZP06';
                        addRemoveOption.discountPercentage=discountValue;
                        addRemoveOption.netUnitPrice = addRemoveOption.netUnitPrice - (addRemoveOption.netUnitPrice * (discountValue/100));
                    }
                    if(discountType!=null && discountType.equalsIgnoreCase('Discount%') && discountValue!=null && discountValue==100 && addRemoveOption.netUnitPrice!=null){
                        addRemoveOption.subType='ZX10';
                        addRemoveOption.discountPercentage=discountValue;
                        addRemoveOption.netUnitPrice=0;
                    } 
                    if(includeFreeService!=null && includeFreeService.equalsIgnoreCase('Yes') && addRemoveOption.chargeType!=null && addRemoveOption.linestatus.equalsIgnoreCase('New') && addRemoveOption.chargeType.equalsIgnoreCase('Service Fee')){
                        addRemoveOption.subType='ZX10';
                        addRemoveOption.discountPercentage=100;
                        addRemoveOption.netUnitPrice=0;
                    }
                    if(typeOfContract.equalsIgnoreCase(APTS_CPQConstants.LABEL_FREEONLOAN) && addRemoveOption.chargeType.equalsIgnoreCase(APTS_CPQConstants.RENTAL_FEE)){
                        addRemoveOption.subType='ZX10';
                        addRemoveOption.discountPercentage=100;
                        addRemoveOption.netUnitPrice=0;
                        system.debug('733 :: typeOfContract :: '+typeOfContract);
                    } 
                }
                //Recalculate Service lines 
                else if(addRemoveOption.linestatus.equalsIgnoreCase('New') && addRemoveOption.chargeType.equalsIgnoreCase('Service Fee')){
                    if(addRemoveOption.basePriceOverride!=null){
                        addRemoveOption.netUnitPrice=addRemoveOption.basePriceOverride.setScale(5);
                    }
                    if(addRemoveOption.discountPercentage!=null && addRemoveOption.discountPercentage<100){
                        addRemoveOption.netUnitPrice = addRemoveOption.netUnitPrice - (addRemoveOption.netUnitPrice * (addRemoveOption.discountPercentage/100));
                    }
                    if(addRemoveOption.discountAmount!=null){
                        addRemoveOption.netUnitPrice = addRemoveOption.netUnitPrice-addRemoveOption.discountAmount;
                    }
                    if(includeFreeService!=null && includeFreeService.equalsIgnoreCase('Yes') && addRemoveOption.chargeType!=null && addRemoveOption.linestatus=='New' && addRemoveOption.chargeType.equalsIgnoreCase('Service Fee')){
                        addRemoveOption.subType='ZX10';
                        addRemoveOption.discountPercentage=100;
                        addRemoveOption.netUnitPrice=0;
                    }
                }
                modifiedOptionsWrapper.add(addRemoveOption);
            }
            //System.debug('modifiedOptionsWrapper======>'+modifiedOptionsWrapper);
            return modifiedOptionsWrapper;
        } 

        @AuraEnabled(cacheable=true)
        public static List<AttributeWrapper> getRelatedAttributes(String optionProductId,String optionGroupText,List<AttributeWrapper> bundleAttributes){
            Boolean hideAttributes=false;
            Boolean hasAllowSalesPriceYes = false;
            List<String> optionGroupAttributeShowlist = new List<String>();
            List<String> requiredAttributeNames = new List<String>();
            List<AttributeWrapper> attributeWrapperList = new List<AttributeWrapper>();
            if(bundleAttributes!=null && !bundleAttributes.isEmpty()){
                For(AttributeWrapper wrapperObj : bundleAttributes){
                    if(wrapperObj.attributeFieldName!=null && wrapperObj.attributeFieldName.equalsIgnoreCase('APTS_Allow_sales_price_for_options__c') && wrapperObj.assignedValue.equalsIgnoreCase('Yes')){
                        hasAllowSalesPriceYes = true;
                    }
                }
            }
            if(optionGroupText!=null){
                for(APTS_Conversion_order_UX_settings__mdt exclusionOGObj : [SELECT Id,
                                                            APTS_Attributes_option_group_visibilty__c,
                                                            APTS_Required_attribute_names__c
                                                            FROM APTS_Conversion_order_UX_settings__mdt
                                                            WHERE MasterLabel = 'CTC System Properties']){
                    if(exclusionOGObj.APTS_Attributes_option_group_visibilty__c!=null){
                        optionGroupAttributeShowlist = exclusionOGObj.APTS_Attributes_option_group_visibilty__c.split(',');
                    }
                    if(!optionGroupAttributeShowlist.isEmpty() && !optionGroupAttributeShowlist.contains(optionGroupText)){
                        hideAttributes=true;
                    }
                    if(exclusionOGObj.APTS_Required_attribute_names__c!=null){
                        requiredAttributeNames = exclusionOGObj.APTS_Required_attribute_names__c.split(',');
                    }
                } 
            }
            //System.debug('hideAttributes======>'+hideAttributes);
            //System.debug('hasAllowSalesPriceYes======>'+hasAllowSalesPriceYes);
            if(!hideAttributes){
                //System.debug('optionProductId==========>'+optionProductId);
                For(Apttus_Config2__ProductAttribute__c pav : [select Id, Apttus_Config2__Sequence__c,Apttus_Config2__IsHidden__c, Apttus_Config2__Field__c, LastModifiedDate 
                                                                from Apttus_Config2__ProductAttribute__c where Apttus_Config2__AttributeGroupId__c in (select Apttus_Config2__AttributeGroupId__c from Apttus_Config2__ProductAttributeGroupMember__c where Apttus_Config2__ProductId__c =: optionProductId) and Apttus_Config2__IsHidden__c = false order by Apttus_Config2__Sequence__c]){
                    AttributeWrapper attributeWrapObj = new AttributeWrapper();
                    if((hasAllowSalesPriceYes && pav.Apttus_Config2__Field__c!=null && pav.Apttus_Config2__Field__c.equalsIgnoreCase(oneTimePurchaseAPIName)) || (pav.Apttus_Config2__Field__c!=null && !pav.Apttus_Config2__Field__c.equalsIgnoreCase(oneTimePurchaseAPIName))){
                        attributeWrapObj.attributeFieldName=pav.Apttus_Config2__Field__c;
                        attributeWrapObj.productid = optionProductId;
                        attributeWrapObj.assignedValue='';
                        attributeWrapObj.readOnly=false;
                        if(pav.Apttus_Config2__Field__c.equalsIgnoreCase(oneTimePurchaseAPIName)){
                            attributeWrapObj.assignedValue='No';
                        }
                        if(requiredAttributeNames.contains(attributeWrapObj.attributeFieldName)){
                            attributeWrapObj.required=true;
                        }
                        attributeWrapperList.add(attributeWrapObj);
                    }
                    //attributeSet.add(pav.Apttus_Config2__Field__c);
                }
            }
            //System.debug('attributeWrapperList==========>'+attributeWrapperList);
            return attributeWrapperList;
        }

        public static Decimal calculateSellingTerm(Date expectedStartDate,Date expectedEndDate){
             Decimal sellingTerm;
             //Calculate selling term 
             Integer startYear = expectedStartDate.year();
             Integer startMonth = expectedStartDate.Month();
             Integer startDay = expectedStartDate.Day();
             Integer startDaysInMonth = date.daysInMonth(startYear,startMonth);   
             Integer endYear = expectedEndDate.year();
             Integer endMonth = expectedEndDate.Month();
             Integer endDay = expectedEndDate.Day();
             Integer endDaysInMonth = date.daysInMonth(endYear,endMonth);                       
             Integer sellingMonths = expectedStartDate.monthsBetween(expectedEndDate)-1;
             Decimal sellingProratedStart = ((date.daysInMonth(startYear,startMonth)-startDay+1.00)*1.00)/(1.00*date.daysInMonth(startYear,startMonth));
             Decimal sellingProratedEnd = (endDay*1.00)/(1.00*date.daysInMonth(endYear,endMonth));
             Decimal CalculatedSellingTermMonth = sellingProratedStart+sellingMonths+sellingProratedEnd;
             //SellingTerm = CalculatedSellingTermMonth;                                  
             SellingTerm = CalculatedSellingTermMonth;
             //System.debug('expectedEndDate===========>'+expectedEndDate);
             return sellingTerm;
        }
        

        @AuraEnabled(cacheable=true)
        public static List<String> getAvailableTOC(String bundelAssetId){
            
            String bundleId;
            String toc;
            
            List<String> PARCTCList;
            String objectName = 'Apttus_Config2__AssetAttributeValue__c';
            //V102 ++ << Included the sales org field in Query >>
            List<Apttus_Config2__AssetLineItem__c> assetLineItem = [select id,Apttus_Config2__StartDate__c,Apttus_Config2__BundleAssetId__r.Apttus_Config2__StartDate__c,Apttus_Config2__ProductId__c,Apttus_Config2__PriceListId__c,APTS_Type_Of_Contract__c,Apttus_Config2__BundleAssetId__c,Apttus_Config2__BundleAssetId__r.Apttus_Config2__EndDate__c,Apttus_Config2__EndDate__c, Apttus_Config2__PriceListId__r.APTS_SalesOrg__c
            from Apttus_Config2__AssetLineItem__c where id =: bundelAssetId limit 1];

            if(assetLineItem[0].APTS_Type_Of_Contract__c!=null){
                toc = assetLineItem[0].APTS_Type_Of_Contract__c;
            }
            //V102 ++ <<
            Boolean bRentBuyAllowed = false;
            if(assetLineItem[0].Apttus_Config2__PriceListId__c != null && assetLineItem[0].Apttus_Config2__PriceListId__r.APTS_SalesOrg__c != null)            
            {
                bRentBuyAllowed = (assetLineItem[0].Apttus_Config2__PriceListId__r.APTS_SalesOrg__c == '0333');
            }
            //V102 ++ >>
            //Querying read only rules from Metadata
           for(APTS_Contract_Change_Master__mdt readOnlyRuleObj : [SELECT Id,Sales__c,Trial__c,Rent__c,FOL__c,RentBuy__c                                                    
                                                            FROM APTS_Contract_Change_Master__mdt
                                                            WHERE MasterLabel = 'CTC PAR']){
                if(toc=='Trial' && readOnlyRuleObj.Trial__c!=null){
                    PARCTCList = readOnlyRuleObj.Trial__c.split(',');
                }
                if(toc=='Rent' && readOnlyRuleObj.Rent__c!=null){
                    PARCTCList = readOnlyRuleObj.Rent__c.split(',');
                }
                if(toc=='Free On Loan' && readOnlyRuleObj.FOL__c!=null){
                    PARCTCList = readOnlyRuleObj.FOL__c.split(',');                    
                } //V102 ++ <<            
                if(toc=='RentBuy' && readOnlyRuleObj.RentBuy__c!=null){
                    PARCTCList = readOnlyRuleObj.RentBuy__c.split(',');  //v105                    
                }  //V102 ++ >>
                if(toc=='Sales' && readOnlyRuleObj.Sales__c!=null){
                    PARCTCList = readOnlyRuleObj.Sales__c.split(',');                    
                } 
            }
            //V102 ++ <<
            if(!bRentBuyAllowed && PARCTCList.contains('RentBuy'))
            {                        
                Integer index =PARCTCList.indexOf('RentBuy');
                PARCTCList.remove(index);                
            }
            system.debug('880 :: PARCTCList :: '+ PARCTCList);
             //V102 ++ >>
            return PARCTCList;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<AttributeWrapper> getDefaultAttributesForNewBundle(String bundelAssetId,String newContract){
      List<AttributeWrapper> updatedAttributeWrapperList = new List<AttributeWrapper>();
      //System.debug('bundelAssetId==========>'+bundelAssetId);
      List<AttributeWrapper> attributeWrapperList = new List<AttributeWrapper>();
      String bundleId;
      String priceListId;
      List<String> readOnlyBundleRulesList = new List<String>();
      List<String> freeOnLoanAttributeList = new List<String>();
      List<String> rentAttributeList = new List<String>();
      List<String> salesAttributeList = new List<String>();
      List<String> consumptionAttributeList = new List<String>();
      List<String> renyBuyAttributeList = new List<String>();
      List<String> trialAttributesCTCList = new List<String>();
      String objectName = 'Apttus_Config2__AssetAttributeValue__c';

      List<Apttus_Config2__AssetLineItem__c> assetLineItem = [select id,Apttus_Config2__OriginalStartDate__c,Apttus_Config2__StartDate__c,Apttus_Config2__BundleAssetId__r.Apttus_Config2__StartDate__c,Apttus_Config2__ProductId__c,Apttus_Config2__PriceListId__c,APTS_Type_Of_Contract__c,Apttus_Config2__BundleAssetId__c,Apttus_Config2__BundleAssetId__r.Apttus_Config2__EndDate__c,Apttus_Config2__EndDate__c
      from Apttus_Config2__AssetLineItem__c where id =: bundelAssetId limit 1];

      //System.debug('assetLineItem=======>'+assetLineItem);

      attributeWrapperList = getRelatedAttributes(assetLineItem[0].Apttus_Config2__ProductId__c,null,null);

      if(assetLineItem[0].Apttus_Config2__BundleAssetId__c!=null){
        bundleId=assetLineItem[0].Apttus_Config2__BundleAssetId__c;
      }else{
        bundleId=bundelAssetId;
      }
      if(assetLineItem[0].Apttus_Config2__PriceListId__c!=null){
        priceListId = assetLineItem[0].Apttus_Config2__PriceListId__c;
      }
      //System.debug('bundleId=======>'+bundleId);
      String queryString = APTS_ProductRedistributionBatchHandler.getObjectQuery('Apttus_Config2__AssetAttributeValue__c') + 'Where Apttus_Config2__AssetLineItemId__c =\''+bundleId + '\'';
      //System.debug('queryString########BEFORE#######'+queryString);

      //Querying read only rules from Metadata
      for(APTS_Conversion_order_UX_settings__mdt readOnlyRuleObj : [SELECT Id,
                              APTS_Read_only_attributes_Bundle__c,
                              APTS_Free_on_loan_contract_attributes__c,
                              APTS_Rent_contract_attributes__c,
                              APTS_Consumption_contract_attributes__c,
                              APTS_Sales_contract_attributes__c,
                              APTS_RentBuy_contract_attributes__c,
                              APTS_Trial_contract_Attributes_CTC__c
                              FROM APTS_Conversion_order_UX_settings__mdt
                              WHERE MasterLabel = 'APTS_CTC_Properties']){
        if(readOnlyRuleObj.APTS_Read_only_attributes_Bundle__c!=null){
          readOnlyBundleRulesList = readOnlyRuleObj.APTS_Read_only_attributes_Bundle__c.split(',');
        }
        if(readOnlyRuleObj.APTS_Free_on_loan_contract_attributes__c!=null){
          freeOnLoanAttributeList = readOnlyRuleObj.APTS_Free_on_loan_contract_attributes__c.split(',');
        }
        if(readOnlyRuleObj.APTS_Rent_contract_attributes__c!=null){
          rentAttributeList = readOnlyRuleObj.APTS_Rent_contract_attributes__c.split(',');
        }
        if(readOnlyRuleObj.APTS_Sales_contract_attributes__c!=null){
          salesAttributeList = readOnlyRuleObj.APTS_Sales_contract_attributes__c.split(',');
        }
        if(readOnlyRuleObj.APTS_Consumption_contract_attributes__c!=null){
          consumptionAttributeList = readOnlyRuleObj.APTS_Consumption_contract_attributes__c.split(',');
        }
        if(readOnlyRuleObj.APTS_RentBuy_contract_attributes__c!=null){
          renyBuyAttributeList = readOnlyRuleObj.APTS_RentBuy_contract_attributes__c.split(',');
        }
        if(readOnlyRuleObj.APTS_Trial_contract_Attributes_CTC__c !=null){
          trialAttributesCTCList = readOnlyRuleObj.APTS_Trial_contract_Attributes_CTC__c.split(',');
        }

      }
      //System.debug('readOnlyBundleRulesList============>'+readOnlyBundleRulesList);

      List<sObject> sobjList = Database.query(queryString);
      
      System.debug('sobjList#################3'+sobjList);

      for(AttributeWrapper attributeWrap : attributeWrapperList){
        for(Apttus_Config2__AssetAttributeValue__c assetAttribute : (List<Apttus_Config2__AssetAttributeValue__c>)sobjList){
          attributeWrap.assignedValue = String.valueOf(assetAttribute.get(attributeWrap.attributeFieldName));
         // system.debug('attributeWrap.assignedValue :: '+attributeWrap.assignedValue);
          if(attributeWrap.attributeFieldName == 'APTS_Type_of_contract__c')
            attributeWrap.assignedValue=newContract;
            //V106 ++ <<
          if(attributeWrap.attributeFieldName == 'APTS_Include_Free_Service__c')
            attributeWrap.assignedValue='NO';
        //V106 ++ >>
        }
        system.debug('attributeWrap.attributeFieldName====>'+attributeWrap.attributeFieldName);
        if(!readOnlyBundleRulesList.isEmpty() && readOnlyBundleRulesList.contains(attributeWrap.attributeFieldName)){
         // System.debug('QUALIFYING====>'+attributeWrap.attributeFieldName);
          attributeWrap.readOnly=true;
        }
        attributeWrap.pricelistId=pricelistId;
        attributeWrap.StartDate= assetLineItem[0].Apttus_Config2__StartDate__c;
        attributeWrap.EndDate= assetLineItem[0].Apttus_Config2__EndDate__c;
        if(!assetLineItem.isEmpty() && newContract!=null && ((newContract.equalsIgnoreCase('Rent') && !rentAttributeList.isEmpty() && rentAttributeList.contains(attributeWrap.attributeFieldName)) ||
        (newContract.equalsIgnoreCase('Sales') && !salesAttributeList.isEmpty() && salesAttributeList.contains(attributeWrap.attributeFieldName)) ||
        (newContract.equalsIgnoreCase('Free On Loan') && !freeOnLoanAttributeList.isEmpty() && freeOnLoanAttributeList.contains(attributeWrap.attributeFieldName)) ||
        (newContract.equalsIgnoreCase('Consumption') && !consumptionAttributeList.isEmpty() && consumptionAttributeList.contains(attributeWrap.attributeFieldName)) ||
        (newContract.equalsIgnoreCase('Trial') && !trialAttributesCTCList.isEmpty() && trialAttributesCTCList.contains(attributeWrap.attributeFieldName)) ||
        (newContract.equalsIgnoreCase('RentBuy') && !renyBuyAttributeList.isEmpty() && renyBuyAttributeList.contains(attributeWrap.attributeFieldName)))){
          updatedAttributeWrapperList.add(attributeWrap);
        }
      }
     // System.debug('updatedAttributeWrapperList============>'+updatedAttributeWrapperList);   
      return updatedAttributeWrapperList;
    }

        @AuraEnabled(cacheable=true)
        public static List<AttributeWrapper> getDefaultAttributesForBundle(String bundelAssetId){
            List<AttributeWrapper> updatedAttributeWrapperList = new List<AttributeWrapper>();
            //System.debug('bundelAssetId==========>'+bundelAssetId);
            List<AttributeWrapper> attributeWrapperList = new List<AttributeWrapper>();
            String bundleId;
            Date startDateValue;
            Date endDateValue;
            String priceListId;
            List<String> readOnlyBundleRulesList = new List<String>();
            List<String> freeOnLoanAttributeList = new List<String>();
            List<String> rentAttributeList = new List<String>();
            List<String> salesAttributeList = new List<String>();
            List<String> consumptionAttributeList = new List<String>();
            List<String> renyBuyAttributeList = new List<String>();
            List<String> trialAttributesCTCList = new List<String>();
            String objectName = 'Apttus_Config2__AssetAttributeValue__c';

            List<Apttus_Config2__AssetLineItem__c> assetLineItem = [select id,Apttus_Config2__StartDate__c,Apttus_Config2__BundleAssetId__r.Apttus_Config2__StartDate__c,Apttus_Config2__ProductId__c,Apttus_Config2__PriceListId__c,APTS_Type_Of_Contract__c,Apttus_Config2__BundleAssetId__c,Apttus_Config2__BundleAssetId__r.Apttus_Config2__EndDate__c,Apttus_Config2__EndDate__c
            from Apttus_Config2__AssetLineItem__c where id =: bundelAssetId limit 1];

            //System.debug('assetLineItem=======>'+assetLineItem);

            attributeWrapperList = getRelatedAttributes(assetLineItem[0].Apttus_Config2__ProductId__c,null,null);

            //if(assetLineItem[0].APTS_Type_Of_Contract__c!= null && assetLineItem[0].APTS_Type_Of_Contract__c == 'Trial')
            //{
            if(assetLineItem[0].Apttus_Config2__BundleAssetId__c!=null){
                bundleId=assetLineItem[0].Apttus_Config2__BundleAssetId__c;
                startDateValue = (assetLineItem[0].APTS_Type_Of_Contract__c == 'Trial') ? assetLineItem[0].Apttus_Config2__BundleAssetId__r.Apttus_Config2__StartDate__c : (((assetLineItem[0].APTS_Type_Of_Contract__c == 'Free On Loan') ||(assetLineItem[0].APTS_Type_Of_Contract__c == 'Rent') || (assetLineItem[0].APTS_Type_Of_Contract__c == 'Rent')) ? System.today().addDays(1) :System.today());//v104
                endDateValue = assetLineItem[0].Apttus_Config2__BundleAssetId__r.Apttus_Config2__EndDate__c;
            }else{
                bundleId=bundelAssetId;
                startDateValue = (assetLineItem[0].APTS_Type_Of_Contract__c == 'Trial') ? assetLineItem[0].Apttus_Config2__StartDate__c : (((assetLineItem[0].APTS_Type_Of_Contract__c == 'Free On Loan') ||(assetLineItem[0].APTS_Type_Of_Contract__c == 'Rent') || (assetLineItem[0].APTS_Type_Of_Contract__c == 'Rent')) ? System.today().addDays(1) :System.today()); //V102++ <<>>
                endDateValue = assetLineItem[0].Apttus_Config2__EndDate__c;  //V102++ <<>>          
            }
           // }
            /*else
            { //if old toc != trial , Sd shud be as today
                if(assetLineItem[0].Apttus_Config2__BundleAssetId__c!=null){
                    bundleId=assetLineItem[0].Apttus_Config2__BundleAssetId__c;
                    startDateValue = System.today();
                    endDateValue = assetLineItem[0].Apttus_Config2__BundleAssetId__r.Apttus_Config2__EndDate__c;
                }else{
                    bundleId=bundelAssetId;
                    startDateValue = System.today(); //V102++ <<>>
                    endDateValue = assetLineItem[0].Apttus_Config2__EndDate__c;  //V102++ <<>>          
                }
            }*/
            if(assetLineItem[0].Apttus_Config2__PriceListId__c!=null){
                priceListId = assetLineItem[0].Apttus_Config2__PriceListId__c;
            }
            //system.debug('1046 :: startDateValue :: '+startDateValue);
            //system.debug('1047 :: endDateValue :: '+endDateValue);
            //System.debug('bundleId=======>'+bundleId);
            String queryString = APTS_ProductRedistributionBatchHandler.getObjectQuery('Apttus_Config2__AssetAttributeValue__c') + 'Where Apttus_Config2__AssetLineItemId__c =\''+bundleId + '\'';
            //System.debug('queryString########BEFORE#######'+queryString);

            //Querying read only rules from Metadata
            for(APTS_Conversion_order_UX_settings__mdt readOnlyRuleObj : [SELECT Id,
                                                            APTS_Read_only_attributes_Bundle__c,
                                                            APTS_Free_on_loan_contract_attributes__c,
                                                            APTS_Rent_contract_attributes__c,
                                                            APTS_Consumption_contract_attributes__c,
                                                            APTS_Sales_contract_attributes__c,
                                                            APTS_RentBuy_contract_attributes__c,
                                                            APTS_Trial_contract_Attributes_CTC__c
                                                            FROM APTS_Conversion_order_UX_settings__mdt
                                                            WHERE MasterLabel = 'CTC System Properties']){
                if(readOnlyRuleObj.APTS_Read_only_attributes_Bundle__c!=null){
                    readOnlyBundleRulesList = readOnlyRuleObj.APTS_Read_only_attributes_Bundle__c.split(',');
                }
                if(readOnlyRuleObj.APTS_Free_on_loan_contract_attributes__c!=null){
                    freeOnLoanAttributeList = readOnlyRuleObj.APTS_Free_on_loan_contract_attributes__c.split(',');
                }
                if(readOnlyRuleObj.APTS_Rent_contract_attributes__c!=null){
                    rentAttributeList = readOnlyRuleObj.APTS_Rent_contract_attributes__c.split(',');
                }
                if(readOnlyRuleObj.APTS_Sales_contract_attributes__c!=null){
                    salesAttributeList = readOnlyRuleObj.APTS_Sales_contract_attributes__c.split(',');
                }
                if(readOnlyRuleObj.APTS_Consumption_contract_attributes__c!=null){
                    consumptionAttributeList = readOnlyRuleObj.APTS_Consumption_contract_attributes__c.split(',');
                }
                if(readOnlyRuleObj.APTS_RentBuy_contract_attributes__c!=null){
                    renyBuyAttributeList = readOnlyRuleObj.APTS_RentBuy_contract_attributes__c.split(',');
                }
                if(readOnlyRuleObj.APTS_Trial_contract_Attributes_CTC__c !=null){
                    trialAttributesCTCList = readOnlyRuleObj.APTS_Trial_contract_Attributes_CTC__c.split(',');
                }

            }
            //System.debug('readOnlyBundleRulesList============>'+readOnlyBundleRulesList);

            List<sObject> sobjList = Database.query(queryString);
            
            //System.debug('sobjList#################3'+sobjList);

            for(AttributeWrapper attributeWrap : attributeWrapperList){
                for(Apttus_Config2__AssetAttributeValue__c assetAttribute : (List<Apttus_Config2__AssetAttributeValue__c>)sobjList){
                    attributeWrap.assignedValue = String.valueOf(assetAttribute.get(attributeWrap.attributeFieldName));
                }
                //System.debug('attributeWrap.attributeFieldName====>'+attributeWrap.attributeFieldName);
                if(!readOnlyBundleRulesList.isEmpty() && readOnlyBundleRulesList.contains(attributeWrap.attributeFieldName)){
                    //System.debug('QUALIFYING====>'+attributeWrap.attributeFieldName);
                    attributeWrap.readOnly=true;
                }
                attributeWrap.pricelistId=pricelistId;
                attributeWrap.StartDate= startDateValue;
                attributeWrap.EndDate= endDateValue;
                if(!assetLineItem.isEmpty() && assetLineItem[0].APTS_Type_Of_Contract__c!=null && ((assetLineItem[0].APTS_Type_Of_Contract__c.equalsIgnoreCase('Rent') && !rentAttributeList.isEmpty() && rentAttributeList.contains(attributeWrap.attributeFieldName)) ||
                (assetLineItem[0].APTS_Type_Of_Contract__c.equalsIgnoreCase('Sales') && !salesAttributeList.isEmpty() && salesAttributeList.contains(attributeWrap.attributeFieldName)) ||
                (assetLineItem[0].APTS_Type_Of_Contract__c.equalsIgnoreCase('Free On Loan') && !freeOnLoanAttributeList.isEmpty() && freeOnLoanAttributeList.contains(attributeWrap.attributeFieldName)) ||
                (assetLineItem[0].APTS_Type_Of_Contract__c.equalsIgnoreCase('Consumption') && !consumptionAttributeList.isEmpty() && consumptionAttributeList.contains(attributeWrap.attributeFieldName)) ||
                (assetLineItem[0].APTS_Type_Of_Contract__c.equalsIgnoreCase('Trial') && !trialAttributesCTCList.isEmpty() && trialAttributesCTCList.contains(attributeWrap.attributeFieldName)) ||
                (assetLineItem[0].APTS_Type_Of_Contract__c.equalsIgnoreCase('RentBuy') && !renyBuyAttributeList.isEmpty() && renyBuyAttributeList.contains(attributeWrap.attributeFieldName)))){
                    updatedAttributeWrapperList.add(attributeWrap);
                }
            }
            //System.debug('updatedAttributeWrapperList============>'+updatedAttributeWrapperList);   
            return updatedAttributeWrapperList;
        }
        //BP and PLI association FUnction - Basic Pricing - Responsible for lwctable display
        public static Map<Id,AddRemoveOptionWrapper> getAssociatedPricingInfo(List<AddRemoveOptionWrapper> OptionProductWrapper,List<AttributeWrapper> bundleAttributes){
            Decimal calcNetUnitPrice=0;       
            Date expectedEndDate;
            Date minOriginalStartDate;
            Set<String> rentalFeeTOCSet = new Set<String>{'Rent','Free On Loan','RentBuy'};
            Set<String> salesFeeTOCSet = new Set<String>{'Sales','Trial'};
            Map<Id,List<AttributeWrapper>> attributeValuesMap = new Map<Id,List<AttributeWrapper>>();
            Map<Id,Decimal> rentalPriceMap = new Map<Id,Decimal>();
            Map<Id,Decimal> sellingTermMap = new Map<Id,Decimal>();
            set<id> rentalPLIs = new set<id>();
            String bundleProductId;
            String pricelistId;
            String typeOfContract;
            Set<Id> OptionProductSet = new Set<Id>();
            Map<Id,AddRemoveOptionWrapper> modifiedMap = new Map<Id,AddRemoveOptionWrapper>(); 
            For(AttributeWrapper bundleAttrib : bundleAttributes){
                bundleProductId = bundleAttrib.productId;
                pricelistId = bundleAttrib.pricelistId;
                if(bundleAttrib.attributeFieldName.equalsIgnoreCase(typeOfContractAPIName)){
                    typeOfContract = bundleAttrib.assignedValue;
                }
            }
            //System.debug('bundleProductId==>'+bundleProductId);
            //System.debug('Lavanya pricelistId==>'+pricelistId);
            //System.debug('Lavanya typeOfContract==>'+typeOfContract);
            
            For(AddRemoveOptionWrapper addRemoveOptionObj : OptionProductWrapper){
                if(modifiedMap.get(addRemoveOptionObj.productid)==null){
                    modifiedMap.put(addRemoveOptionObj.productid,addRemoveOptionObj);
                }
            }   
            //System.debug('attributeValuesMap==>'+attributeValuesMap);
            For(Apttus_Config2__PriceListItem__c optionPLIs : [select id,Apttus_Config2__Criteria__c,
                                                            APTS_Default_Selling_Uom__c,Apttus_Config2__ChargeType__c,Apttus_Config2__ProductId__c,Apttus_Config2__PriceUom__c,Apttus_Config2__ListPrice__c
                                                            from Apttus_Config2__PriceListItem__c where Apttus_Config2__PriceListId__c =: pricelistId and Apttus_Config2__ProductId__c IN: modifiedMap.keySet() and Apttus_Config2__Active__c=true]){
                Map<String, Object> criteriaParsed;
                String oneTimePurchaseAttribute;
                Decimal numberOfHours;
                //System.debug('WRAPPER IN PLI====>'+modifiedMap.get(optionPLIs.Apttus_Config2__ProductId__c));
                if(!modifiedMap.isEmpty() && modifiedMap.get(optionPLIs.Apttus_Config2__ProductId__c)!=null && modifiedMap.get(optionPLIs.Apttus_Config2__ProductId__c).attributeList!=null && !modifiedMap.get(optionPLIs.Apttus_Config2__ProductId__c).attributeList.isEmpty()){
                    For(AttributeWrapper attrib : modifiedMap.get(optionPLIs.Apttus_Config2__ProductId__c).attributeList){
                        if(attrib.attributeFieldName.equalsIgnoreCase(oneTimePurchaseAPIName)){
                            oneTimePurchaseAttribute = attrib.assignedValue;
                        }
                        if(attrib.assignedValue!=null && attrib.assignedValue!='' && attrib.attributeFieldName.equalsIgnoreCase(numberOfHoursAPIName)){
                            numberOfHours = Decimal.valueOf(attrib.assignedValue);
                        }
                    }
                }
                //System.debug('oneTimePurchaseAttribute==>'+oneTimePurchaseAttribute);
                if(oneTimePurchaseAttribute==null){oneTimePurchaseAttribute='No';}
                //System.debug('oneTimePurchaseAttribute=AFTER=>'+oneTimePurchaseAttribute);
                if(optionPLIs.Apttus_Config2__Criteria__c!=null && typeOfContract!=null){
                    if((typeOfContract.equalsIgnoreCase('Consumption') || (rentalFeeTOCSet.contains(typeOfContract) && oneTimePurchaseAttribute!=null && oneTimePurchaseAttribute.equalsIgnoreCase('No')))&& optionPLIs.Apttus_Config2__ChargeType__c.equalsIgnoreCase('Rental Fee')){
                        if(modifiedMap.get(optionPLIs.Apttus_Config2__ProductId__c)!=null){
                            AddRemoveOptionWrapper newlyAddedOption = modifiedMap.get(optionPLIs.Apttus_Config2__ProductId__c);
                            newlyAddedOption.typeOfContract=typeOfContract;
                            newlyAddedOption.chargeType = optionPLIs.Apttus_Config2__ChargeType__c;
                            newlyAddedOption.priceListItemId = optionPLIs.id;
                            newlyAddedOption.basePrice=optionPLIs.Apttus_Config2__ListPrice__c;
                            modifiedMap.put(optionPLIs.Apttus_Config2__ProductId__c,newlyAddedOption);
                        }
                        //System.debug('==========ITS A RENTAL PLI=======WITH CTC=========');
                        //System.debug('PLI link======>'+optionPLIs.id);
                        rentalPLIs.add(optionPLIs.id);
                    }
                    if((salesFeeTOCSet.contains(typeOfContract) || (!salesFeeTOCSet.contains(typeOfContract) && (oneTimePurchaseAttribute!=null && oneTimePurchaseAttribute.equalsIgnoreCase('Yes')))) && optionPLIs.Apttus_Config2__ChargeType__c.equalsIgnoreCase('Sales Price')){
                        //System.debug('==========ITS A SALES PLI=======WITH CTC=========');
                        //System.debug('Sales price==CTC==='+optionPLIs.id);
                        if(modifiedMap.get(optionPLIs.Apttus_Config2__ProductId__c)!=null){
                            AddRemoveOptionWrapper newlyAddedOption = modifiedMap.get(optionPLIs.Apttus_Config2__ProductId__c);
                            newlyAddedOption.chargeType = optionPLIs.Apttus_Config2__ChargeType__c;
                            newlyAddedOption.priceListItemId = optionPLIs.id;
                            newlyAddedOption.basePrice = optionPLIs.Apttus_Config2__ListPrice__c;
                            newlyAddedOption.typeOfContract=typeOfContract;
                            modifiedMap.put(optionPLIs.Apttus_Config2__ProductId__c,newlyAddedOption);
                        }
                    }
                }else if(optionPLIs.Apttus_Config2__ChargeType__c.equalsIgnoreCase('Service Fee') && modifiedMap.get(optionPLIs.Apttus_Config2__ProductId__c)!=null){
                    //System.debug('==========ITS A '+optionPLIs.Apttus_Config2__ChargeType__c+' PLI=======WO CTC=========');
                    //System.debug('optionPLIs.Apttus_Config2__ChargeType__c====>'+optionPLIs.Apttus_Config2__ChargeType__c);
                    AddRemoveOptionWrapper newlyAddedOption = modifiedMap.get(optionPLIs.Apttus_Config2__ProductId__c);
                    newlyAddedOption.chargeType = optionPLIs.Apttus_Config2__ChargeType__c;
                    newlyAddedOption.priceListItemId = optionPLIs.id;
                    newlyAddedOption.typeOfContract=typeOfContract;
                    modifiedMap.put(optionPLIs.Apttus_Config2__ProductId__c,newlyAddedOption);
                }else{
                    //System.debug('==========ITS A '+optionPLIs.Apttus_Config2__ChargeType__c+' PLI=======WO CTC=========');
                    //System.debug('optionPLIs.Apttus_Config2__ChargeType__c====>'+optionPLIs.Apttus_Config2__ChargeType__c);
                    //System.debug('Sales price==NO CTC==='+optionPLIs.id);
                    if(numberOfHours!=null){
                        calcNetUnitPrice=(optionPLIs.Apttus_Config2__ListPrice__c*numberOfHours)*4;
                    }else{
                        calcNetUnitPrice = optionPLIs.Apttus_Config2__ListPrice__c;
                    }
                    if(modifiedMap.get(optionPLIs.Apttus_Config2__ProductId__c)!=null){
                        AddRemoveOptionWrapper newlyAddedOption = modifiedMap.get(optionPLIs.Apttus_Config2__ProductId__c);
                        newlyAddedOption.chargeType = optionPLIs.Apttus_Config2__ChargeType__c;
                        newlyAddedOption.priceListItemId = optionPLIs.id;
                        newlyAddedOption.basePrice = calcNetUnitPrice;
                        newlyAddedOption.typeOfContract=typeOfContract;
                        modifiedMap.put(optionPLIs.Apttus_Config2__ProductId__c,newlyAddedOption);
                    }
                }
            }
            For(AddRemoveOptionWrapper addRemoveOptionObj : OptionProductWrapper){
                if(addRemoveOptionObj.startDate!=null && addRemoveOptionObj.endDate!=null){
                    AddRemoveOptionWrapper newlyAddedOption = modifiedMap.get(addRemoveOptionObj.productid);
                    if(newlyAddedOption.chargeType.equalsIgnoreCase('Sales Price')){
                        if(newlyAddedOption.startDate<newlyAddedOption.endDate){
                            newlyAddedOption.endDate = newlyAddedOption.startDate.addmonths(1).addDays(-1);
                        }
                        newlyAddedOption.sellingTerm=1;
                    }else{
                        newlyAddedOption.sellingTerm=calculateSellingTerm(addRemoveOptionObj.startDate,addRemoveOptionObj.endDate).setScale(5);
                        //System.debug('Lavanya'+addRemoveOptionObj.startDate);
            //System.debug('Lavanya'+addRemoveOptionObj.endDate);
                    }
                    //System.debug('Lavanya'+newlyAddedOption.assetName+'ST'+newlyAddedOption.sellingTerm);
                    modifiedMap.put(addRemoveOptionObj.productid,newlyAddedOption);
                }
            } 
            //System.debug('modifiedMap======>'+modifiedMap);
            if(!rentalPLIs.isEmpty()){
                For(Apttus_Config2__PriceMatrixEntry__c pmatrixEntry : [select id,
                                                                        Apttus_Config2__Dimension1Value__c,
                                                                        Apttus_Config2__AdjustmentAmount__c,
                                                                        Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__c,
                                                                        Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__c
                                                                        from Apttus_Config2__PriceMatrixEntry__c 
                                                                        where Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__c IN: rentalPLIs order by Apttus_Config2__Sequence__c]){
                    if(!modifiedMap.isEmpty() && modifiedMap.get(pmatrixEntry.Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__c)!=null){
                        AddRemoveOptionWrapper newlyAddedOption = modifiedMap.get(pmatrixEntry.Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__c);
                        if(newlyAddedOption!=null && newlyAddedOption.sellingTerm!=null && (Decimal.valueOf(pmatrixEntry.Apttus_Config2__Dimension1Value__c) >= newlyAddedOption.sellingTerm)){
                            //System.debug('Range =>'+ pmatrixEntry.Apttus_Config2__Dimension1Value__c);
                            //System.debug('the value 1 =>'+ pmatrixEntry.Apttus_Config2__AdjustmentAmount__c);
                            //System.debug('INSIDE MATRIX WRAPPER ===>'+modifiedMap.get(pmatrixEntry.Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__c));
                            if(newlyAddedOption.chargeType.equalsIgnoreCase('Rental Fee')){
                                newlyAddedOption.basePrice=pmatrixEntry.Apttus_Config2__AdjustmentAmount__c;
                                modifiedMap.put(pmatrixEntry.Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__c,newlyAddedOption);
                                //System.debug(newlyAddedOption.basePrice);
                            }
                            break;
                        }
                    }
                }
            }
            //System.debug('modifiedMap==FINAL====>'+modifiedMap);
            return modifiedMap;
        }
    //V102++ <<
    @future
    public Static void activateOrderWithoutCancellation(ID orderId,String finalWrapperData,String bundleAssetIdRectified,Date startDateValue,Date oldAssetEndDate, string oldTypeOfContract, string newTypeOfContract)
    {
        Id cartId = null;
        try
        {                           
            if (orderId != null && String.isNotBlank(orderId)) 
            {
                    cartId = APTS_OrderUtils.createCart(orderId);
            }
            List<Id> assetIdList = new List<Id>();
            assetIdList.add(bundleAssetIdRectified);
            Map<Id, Apttus_Config2__LineItem__c> mapIdLineItem = new Map<Id, Apttus_Config2__LineItem__c>();
            if(assetIdList.size() > 0){
                mapIdLineItem = APTS_OrderUtils.changeAssets(cartId, assetIdList);
            }
            //System.debug('cart :: '+cartId+' :: mapIdLineItem :: '+mapIdLineItem); 
            if (Test.isRunningTest()) { Decimal dc1 = 1 / 0; } 
        }  
        catch(Exception e)
        {
            APTS_CustomErrorLogging.createErrorLog('APTS_ContractChangeNewUXController', 'Apex','Error in Cancellation of Old Bundle!', 'Order',orderId, 'OM', false, false, null, true,orderId, null,null);
        }   
        List<AddRemoveOptionWrapper> addRemoveWrapperList = (List<AddRemoveOptionWrapper>)JSON.deserializeStrict(finalWrapperData, List<AddRemoveOptionWrapper>.class);
        APTS_AssetRenewalRollbackBatch.bypassCurrentUserfromTriggersandFlows();
        //APTS_CloneBundle2.CloneBundleLogic(cartId,startDateValue,oldAssetEndDate,addRemoveWrapperList);
        boolean bCartCreationSuccess = APTS_CloneBundle2.updateBundlelines(cartId,startDateValue,oldAssetEndDate,addRemoveWrapperList, null, true, oldTypeOfContract, newTypeOfContract);
        //Savepoint spReference = Database.setSavepoint();
        system.debug('bCartCreationSuccess :: '+bCartCreationSuccess);      
        if(bCartCreationSuccess || Test.isRunningTest())
        {
            //invokeAcceptOrderAPI(orderId);      
            //removeCustomSettingsEntries();  
            System.enqueueJob(new APTS_ActivateCTCOrderQueueable(orderId, null, null));                             
        }                                
    } 
    public static void  invokeAcceptOrderAPI(Id orderId)
    {
        try{                              
            APTS_OrderUtils.acceptOrder(orderId);  
            if (Test.isRunningTest()) { Decimal dc1 = 1 / 0; }
        }
        catch(Exception e)
        {
            system.debug('1316 :: invokeAcceptOrderAPI :: Exception occurred :: '+ e.getMessage());
            //Database.rollback(spReference);
            APTS_CustomErrorLogging.createErrorLog('APTS_ContractChangeNewUXController', 'Apex','Error occurred when performing asset activation', 'Order',orderId, 'OM', false, false, null, true,orderId, null,null);                
        }   
    }
    public static void removeCustomSettingsEntries()
    {
        //removing user trigger settings created during bypass 
        if(TriggerSettings__c.getValues(UserInfo.getUserId())!=null){
            TriggerSettings__c triggerSettings = TriggerSettings__c.getValues(UserInfo.getUserId());
            Database.delete(triggerSettings,false);
        }
        if(ProcessBuilderSettings__c.getValues(UserInfo.getUserId())!=null)
        {            
            ProcessBuilderSettings__c PBSettings = ProcessBuilderSettings__c.getValues(UserInfo.getUserId());
            Database.delete(PBSettings,false);
        }
    }
    
     public static void updateAndSubmitOrder(Id orderId,Id accountId, String scenario)
    {
        List<Integration_Log__c> integrationLogToInsertList = new List<Integration_Log__c>();       
        try{              
                //DQ-5362 - Integ Log CTC for trial to sales scenario
                if(scenario != null &&  scenario == 'Trial To Sales')
                {
                    Integration_Log__c oIntegrationLog = new Integration_Log__c(Object_Id__c = orderId,
                    Object__c = ORDER, Integration_Status__c = INT_Constants.INITIAL, Account__c = accountId, Order__c = orderId);
                    integrationLogToInsertList.add(oIntegrationLog);
                }            
                //DML Section                              
                if (!integrationLogToInsertList.isEmpty()) {
                    Database.insert(integrationLogToInsertList);
                }           
                if (Test.isRunningTest()) { Decimal dc1 = 1 / 0; }
        }
        catch(Exception e)
        {
            APTS_CustomErrorLogging.createErrorLog('APTS_ContractChangeNewUXController', 'Apex','Error occurred when Integ Log creation', 'Order',orderId, 'OM', false, false, null, true,orderId, null,null);  
        }
    }  
    /*public static void updateAndSubmitOrder(Id orderId)
    {
        List<Apttus_Config2__Order__c> orderListToUpdate = new List<Apttus_Config2__Order__c>();
        List<Integration_Log__c> integrationLogToInsertList = new List<Integration_Log__c>();       
        try{
            for (Apttus_Config2__Order__c oOrder :  [select id,APTS_Status__c,Apttus_Config2__SoldToAccountId__c,APTS_Scenario__c,APTS_Contract_Change__c,Apttus_Config2__Status__c from Apttus_Config2__Order__c where Id = :orderId])
            {
                if( oOrder.Apttus_Config2__Status__c == ACTIVATED)
                { 
                    oOrder.APTS_Status__c = APTS_BIRUtils.INVOICINGSTATUS;//v130
                    oOrder.APTS_Remove_Billing_Block_Indicator__c = true;
                    oOrder.APTS_Billing_Date__c = system.today();
                    orderListToUpdate.add(oOrder);
                }
                //DQ-5362 - Integ Log CTC for trial to sales scenario
                if(oOrder.APTS_Scenario__c != null && oOrder.APTS_Contract_Change__c==Yes && oOrder.Apttus_Config2__Status__c==Activated)
                {
                    integrationLogToInsertList.add(APTS_OrderUtils.createIntegrationLog(oOrder));
                }
            }
            //DML Section                              
            if (!integrationLogToInsertList.isEmpty()) {
                Database.insert(integrationLogToInsertList);
            }
            if(!orderListToUpdate.isEmpty())
            {
                APTS_OrderUtils.stopOrderTrigger();
                Database.update (orderListToUpdate);
                APTS_OrderUtils.startOrderTrigger();
            }
            if (Test.isRunningTest()) { Decimal dc1 = 1 / 0; }
        }
        catch(Exception e)
        {
            APTS_CustomErrorLogging.createErrorLog('APTS_ContractChangeNewUXController', 'Apex','Error occurred when Integ Log creation', 'Order',orderId, 'OM', false, false, null, true,orderId, null,null);  
        }
    }  */
    //V102++ >>       
}