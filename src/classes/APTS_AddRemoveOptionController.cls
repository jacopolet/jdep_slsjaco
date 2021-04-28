/**
  * Class Name : APTS_AddRemoveOptionController
  * Description : Controller class used for New UX - Add/Remove options
  * Author : Karan Khatri
  * Date Created : 09-09-2020
  **/

  public with sharing class APTS_AddRemoveOptionController {
    private final static String numberOfHoursAPIName='APTS_Number_of_hours_per_month__c';
    private final static String typeOfContractAPIName='APTS_Type_Of_Contract__c';
    private final static String oneTimePurchaseAPIName='APTS_One_Time_Purchase__c';
    private final static String typeofPaymentSystemAPIName ='APTS_Type_of_Payment_System__c';
    private final static String merchantAPIName='APTS_Merchant__c';
    private final static String firstLineResponseTime='APTS_First_Line_Response_Time__c';

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
      @AuraEnabled public String subType {get;set;}
      @AuraEnabled public String billingFrequency{get;set;}
      @AuraEnabled public Decimal basePrice {get;set;}
      @AuraEnabled public Decimal sellingTerm {get;set;}
      @AuraEnabled public List<AttributeWrapper> attributeList {get;set;}
       // @AuraEnabled public Decimal discountAmount {get;set;}
       // @AuraEnabled public Decimal discountPercentage {get;set;}
       // @AuraEnabled public String subType {get;set;}
    }
    
    public class AttributeWrapper{
      @AuraEnabled public String productId {get;set;}
      @AuraEnabled public String priceListId {get;set;}
      @AuraEnabled public String attributeFieldName {get;set;}
      @AuraEnabled public String assignedValue {get;set;}
      @AuraEnabled public Boolean readOnly {get;set;}
      @AuraEnabled public Boolean required {get;set;}
    }
    
    @AuraEnabled(cacheable=true)
    public static list<AddRemoveOptionWrapper> getRecsForModifyOptionAction(string bundelHeaderId){        
       list<AddRemoveOptionWrapper> assetOptions = new list<AddRemoveOptionWrapper>();
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
                                                            where APTS_Is_Primary_L1_Asset__c =: bundelHeaderId and  
                                                            Apttus_Config2__LineType__c = 'Option' and 
                                                            Apttus_Config2__PriceType__c='Recurring' and 
                                                            Apttus_Config2__AssetStatus__c = 'Activated']);

      if(assetOptionMap != null && assetOptionMap.size() > 0){
        Map<String, Date> assetIdLastInvoceDate = APTS_MovementOrderUtils.calculateMinPendingBillingDate(assetOptionMap.keyset());
        for(Apttus_Config2__AssetLineItem__c asset: assetOptionMap.values()){
          AddRemoveOptionWrapper wrapperObj = new AddRemoveOptionWrapper();
          wrapperObj.assetid=asset.id;
          wrapperObj.productid=asset.Apttus_Config2__OptionId__c;
          wrapperObj.optionGroupText=asset.APTS_Option_Group_Text__c;
          wrapperObj.assetName=asset.Name;
          wrapperObj.startDate=asset.Apttus_Config2__StartDate__c;
          wrapperObj.endDate=asset.Apttus_Config2__EndDate__c;
          wrapperObj.chargeType=asset.Apttus_Config2__ChargeType__c;
          wrapperObj.linestatus='Existing';
          wrapperObj.priceListItemId=asset.Apttus_Config2__PriceListItemId__c;
          wrapperObj.basePrice=asset.Apttus_Config2__BasePrice__c;
          wrapperObj.basePriceOverride=asset.APTS_BasePriceOverride__c;
          wrapperObj.netUnitPrice=asset.Apttus_Config2__NetUnitPrice__c;
          wrapperObj.autoRenew=asset.Apttus_Config2__AutoRenew__c;
          wrapperObj.originalStartDate=asset.Apttus_Config2__OriginalStartDate__c;
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
      System.debug('Option list modify options ====>'+assetOptions);
      return assetOptions;
    }   
    
    @AuraEnabled(cacheable=true)
    public static List<Apttus_Config2__ProductOptionComponent__c> getOptionGroupRecs(string bundelHeaderId,List<AddRemoveOptionWrapper> allTableRecords,List<AttributeWrapper> bundleAttributes){ 
      List<String> exclusionOptionGroup = new List<String>();
      Set<String> optionGroupText = new Set<String>();
      Set<String> additonalFilterOGSet = new Set<String>();
      Map<String,Decimal> productOptionCompCountMap = new Map<String,Decimal>();
      Map<Id,Apttus_Config2__ProductOptionComponent__c> optionGroupMap = new Map<Id,Apttus_Config2__ProductOptionComponent__c>(); 
      Map<String,Decimal> assetCartOptionGroupMemberMap = new Map<String,Decimal>(); 
      Set<Id> OptionGroupTextIds = new Set<Id>();
      Id productId;
      For(Apttus_Config2__AssetLineItem__c optionAsset : [select id,
                                Apttus_Config2__ProductId__c,
                                APTS_Option_Group_Text__c,
                                Apttus_Config2__PriceType__c,
                                Apttus_Config2__AssetStatus__c 
                                from Apttus_Config2__AssetLineItem__c 
                                where APTS_Is_Primary_L1_Asset__c =: bundelHeaderId and Apttus_Config2__LineType__c ='Option' and Apttus_Config2__AssetStatus__c='Activated']){
        if(optionAsset.Apttus_Config2__ProductId__c!=null){
          productId = optionAsset.Apttus_Config2__ProductId__c;
        }
        if(optionAsset.APTS_Option_Group_Text__c!=null && !optionAsset.Apttus_Config2__PriceType__c.equalsIgnoreCase('Recurring')){
          optionGroupText.add(optionAsset.APTS_Option_Group_Text__c);
        }
        if(optionAsset.APTS_Option_Group_Text__c!=null){
          if(assetCartOptionGroupMemberMap.get(optionAsset.APTS_Option_Group_Text__c)==null){
            assetCartOptionGroupMemberMap.put(optionAsset.APTS_Option_Group_Text__c,1);
          }else{
            assetCartOptionGroupMemberMap.put(optionAsset.APTS_Option_Group_Text__c,assetCartOptionGroupMemberMap.get(optionAsset.APTS_Option_Group_Text__c)+1);
          }
        }
      }

      for(APTS_Conversion_order_UX_settings__mdt exclusionOGObj : [SELECT Id,
                              APTS_Exclusion_Option_Groups__c
                              FROM APTS_Conversion_order_UX_settings__mdt
                              WHERE MasterLabel = 'System Properties']){
        if(exclusionOGObj.APTS_Exclusion_Option_Groups__c!=null){                                                
          exclusionOptionGroup = exclusionOGObj.APTS_Exclusion_Option_Groups__c.split(',');
        }
      }
      List<AddRemoveOptionWrapper> optionsWrapperList = new List<AddRemoveOptionWrapper>();
      List<Apttus_Config2__ProductOptionComponent__c> prodOpionCompList = [select id,
                                        Apttus_Config2__ComponentProductId__c,Apttus_Config2__ComponentProductId__r.name,
                                        Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__c,
                                        Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.name,
                                        Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__MaxOptions__c
                                        from Apttus_Config2__ProductOptionComponent__c 
                                        where Apttus_Config2__ParentProductId__c =: productId];
      For(Apttus_Config2__ProductOptionComponent__c prodOptionComp : prodOpionCompList){
        AddRemoveOptionWrapper addRemoveWrapper = new AddRemoveOptionWrapper();
        addRemoveWrapper.productId = prodOptionComp.Apttus_Config2__ComponentProductId__c;
        optionsWrapperList.add(addRemoveWrapper);
      }
      System.debug('bundleAttributes====OGS===>'+bundleAttributes);
      System.debug('optionsWrapperList======OGS=======>'+optionsWrapperList);
      Map<Id,AddRemoveOptionWrapper> pricingInformationMap = getAssociatedPricingInfo(optionsWrapperList,bundleAttributes);
      System.debug('pricingInformationMap=====OGS========>'+pricingInformationMap);
      For(Apttus_Config2__ProductOptionComponent__c prodOptionComp : prodOpionCompList){
        System.debug('COMPONENT NAME======>'+prodOptionComp.Apttus_Config2__ComponentProductId__r.name);
        System.debug('GROUP ID======>'+prodOptionComp.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__c);
        if(exclusionOptionGroup.isEmpty() || (!exclusionOptionGroup.isEmpty() && !exclusionOptionGroup.contains(prodOptionComp.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.name))){
          if(productOptionCompCountMap.get(prodOptionComp.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.name)==null){
            System.debug('I AM HERE'+productOptionCompCountMap.get(prodOptionComp.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.name));
            productOptionCompCountMap.put(prodOptionComp.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.name,1);
          }else{
            System.debug('I AM HERE 2'+productOptionCompCountMap.get(prodOptionComp.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.name));
            productOptionCompCountMap.put(prodOptionComp.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.name,productOptionCompCountMap.get(prodOptionComp.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.name)+1);
          }
        }
        if(!pricingInformationMap.isEmpty() && pricingInformationMap.get(prodOptionComp.Apttus_Config2__ComponentProductId__c)!=null){
          AddRemoveOptionWrapper addRemoveWrapper = pricingInformationMap.get(prodOptionComp.Apttus_Config2__ComponentProductId__c);
          if(addRemoveWrapper.priceListItemId!=null){
            OptionGroupTextIds.add(prodOptionComp.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__c);
          }
        }
       }
       System.debug('OptionGroupTextIds========>'+OptionGroupTextIds); 
      For(AddRemoveOptionWrapper addRemoveObj: allTableRecords){
        if(addRemoveObj.linestatus!='Cancelled'){
          optionGroupText.add(addRemoveObj.optionGroupText);
        }
        if(productOptionCompCountMap.get(addRemoveObj.optionGroupText)==1){
          additonalFilterOGSet.add(addRemoveObj.optionGroupText);
        }
        if(addRemoveObj.linestatus.equalsIgnoreCase('New') && addRemoveObj.optionGroupText!=null){
          if(assetCartOptionGroupMemberMap.get(addRemoveObj.optionGroupText)==null){
            assetCartOptionGroupMemberMap.put(addRemoveObj.optionGroupText,1);
          }else{
            assetCartOptionGroupMemberMap.put(addRemoveObj.optionGroupText,assetCartOptionGroupMemberMap.get(addRemoveObj.optionGroupText)+1);
          }
        }
      } 
      System.debug('additonalFilterOGSet====>'+additonalFilterOGSet); 
      System.debug('assetCartOptionGroupMemberMap=============>'+assetCartOptionGroupMemberMap);     
      For(Apttus_Config2__ProductOptionComponent__c prodOpComp : prodOpionCompList){
        System.debug('prodOpComp.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.name====>'+prodOpComp.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.name);
        System.debug('ALREADY ADDED OPTIONS====>'+assetCartOptionGroupMemberMap.get(prodOpComp.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.name));
        System.debug('MASTER DATA OPTIONS====>'+productOptionCompCountMap.get(prodOpComp.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.name));
        if((prodOpComp.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__c!=null && 
         prodOpComp.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.name!=null && 
         optionGroupMap.get(prodOpComp.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__c)==null) &&
         
         (!exclusionOptionGroup.isEmpty() && 
         !exclusionOptionGroup.contains(prodOpComp.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.Name)) &&
         
         !(prodOpComp.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__MaxOptions__c == 1 && 
         optionGroupText.contains(prodOpComp.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.name))&&

         !additonalFilterOGSet.contains(prodOpComp.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.name) && 

         (assetCartOptionGroupMemberMap.get(prodOpComp.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.name)==null || 
         (assetCartOptionGroupMemberMap.get(prodOpComp.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.name)!=null &&
         productOptionCompCountMap.get(prodOpComp.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.name)!=null &&
         assetCartOptionGroupMemberMap.get(prodOpComp.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.name)!=productOptionCompCountMap.get(prodOpComp.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.name))) && 
         
         OptionGroupTextIds.contains(prodOpComp.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__c)){
          optionGroupMap.put(prodOpComp.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__c,prodOpComp);
         }
       } 
       System.debug('optionGroupMap====>'+optionGroupMap);
       return optionGroupMap.values();
    } 

    @AuraEnabled(cacheable=true)
    public static List<Apttus_Config2__ProductOptionComponent__c> getOptions(string bundelHeaderId,String optionGroupId,List<AddRemoveOptionWrapper> allTableRecords,List<AttributeWrapper> bundleAttributes){  
      System.debug('bundelHeaderId==OPTION==>'+bundelHeaderId);
      System.debug('optionGroupId==OPTION==>'+optionGroupId); 
      List<String> exclusionOptions = new List<String>();
      Set<String> selectedProductKeySet = new Set<String>();
      Map<Id,Apttus_Config2__ProductOptionComponent__c> optionGroupCompMap = new Map<Id,Apttus_Config2__ProductOptionComponent__c>();
      List<Apttus_Config2__ProductOptionComponent__c> optionGroupComList = new List<Apttus_Config2__ProductOptionComponent__c>();
      Id productId;
      for(APTS_Conversion_order_UX_settings__mdt exclusionOGObj : [SELECT Id,
            APTS_Exclusion_Options__c
            FROM APTS_Conversion_order_UX_settings__mdt
            WHERE MasterLabel = 'System Properties']){
        if(exclusionOGObj.APTS_Exclusion_Options__c!=null){
          exclusionOptions = exclusionOGObj.APTS_Exclusion_Options__c.split(',');
        }
      }
      For(AddRemoveOptionWrapper addRemoveObj: allTableRecords){
        if(addRemoveObj.productid!=null){
          selectedProductKeySet.add(addRemoveObj.productid+addRemoveObj.optionGroupText);
        }
      }
      For(Apttus_Config2__AssetLineItem__c optionAsset : [select id,Apttus_Config2__ProductId__c,Apttus_Config2__OptionId__c,APTS_Option_Group_Text__c from Apttus_Config2__AssetLineItem__c where APTS_Is_Primary_L1_Asset__c =: bundelHeaderId and Apttus_Config2__LineType__c ='Option' and Apttus_Config2__AssetStatus__c='Activated']){
        if(optionAsset.Apttus_Config2__ProductId__c!=null){
          productId = optionAsset.Apttus_Config2__ProductId__c;
        }
        if(optionAsset.Apttus_Config2__OptionId__c!=null){
          selectedProductKeySet.add(optionAsset.Apttus_Config2__OptionId__c+optionAsset.APTS_Option_Group_Text__c);
        }
      }
      List<Apttus_Config2__ProductOptionComponent__c> prodOpionCompList = [select id,
                                        Apttus_Config2__ComponentProductId__c,
                                        Apttus_Config2__ComponentProductId__r.name,
                                        Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__c,
                                        Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.name
                                        from Apttus_Config2__ProductOptionComponent__c 
                                        where Apttus_Config2__ParentProductId__c=: productId and Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__c =: optionGroupId];

       System.debug('prodOpionCompList============>'+prodOpionCompList);
       System.debug('selectedProductKeySet============>'+selectedProductKeySet);
       For(Apttus_Config2__ProductOptionComponent__c prodOptionComp : prodOpionCompList){
        System.debug('exclusionOptions==============>'+exclusionOptions);                                                                
        if((exclusionOptions.isEmpty() || 
        (!exclusionOptions.isEmpty() && !exclusionOptions.contains(prodOptionComp.Apttus_Config2__ComponentProductId__c))) &&
        !selectedProductKeySet.contains(prodOptionComp.Apttus_Config2__ComponentProductId__c+prodOptionComp.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.name) &&
        optionGroupCompMap.get(prodOptionComp.Apttus_Config2__ComponentProductId__c)==null){
          optionGroupCompMap.put(prodOptionComp.Apttus_Config2__ComponentProductId__c,prodOptionComp);
        }
      }
      List<AddRemoveOptionWrapper> optionsWrapperList = new List<AddRemoveOptionWrapper>();
        For(Id prodCompId : optionGroupCompMap.keySet()){
         AddRemoveOptionWrapper addRemoveWrapper = new AddRemoveOptionWrapper();
         addRemoveWrapper.productId = prodCompId;
         optionsWrapperList.add(addRemoveWrapper);
      }
        Map<Id,AddRemoveOptionWrapper> pricingInformationMap = getAssociatedPricingInfo(optionsWrapperList,bundleAttributes);  
        if(!pricingInformationMap.isEmpty()){
        For(Id prodCompId : pricingInformationMap.keySet()){
          if(pricingInformationMap.get(prodCompId)!=null && optionGroupCompMap.get(prodCompId)!=null){
            AddRemoveOptionWrapper addRemoveWrapper = pricingInformationMap.get(prodCompId);
            Apttus_Config2__ProductOptionComponent__c optionComponent = optionGroupCompMap.get(prodCompId);
            if(addRemoveWrapper.priceListItemId!=null){
              optionGroupComList.add(optionComponent);
            }
          }
        }  
      }
       System.debug('ÓPTIONS WITH PLI=============>'+pricingInformationMap);  
       System.debug('optionGroupComList===========>'+optionGroupComList);
       return optionGroupComList;
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
                                    WHERE MasterLabel = 'System Properties']){
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
      System.debug('bundelHeaderId==>'+bundelHeaderId);
      System.debug('optionProductId==>'+optionProductId);
      System.debug('expectedStartDate==>'+expectedStartDate);
      System.debug('optionGroupMame==>'+optionGroupName);
      For(AddRemoveOptionWrapper addOption : allTableRecords){
        System.debug('addOption.optionGroupText==>'+addOption.optionGroupText);
        System.debug('addOption.priceListItemId==>'+addOption.priceListItemId);
        System.debug('techServiceOptionGroupList==>'+techServiceOptionGroupList);
        System.debug('techServiceRelatedPLis==>'+techServiceRelatedPLis);
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
        System.debug('minOriginalStartDate============>'+minOriginalStartDate);
        addedOption.originalStartDate = minOriginalStartDate;
        addedOption.nextInvoiceDate=null;
        addedOption.linestatus='New';
        System.debug('autoRenew======>'+autoRenew);
        if(autoRenew==null){
          autoRenew=true;
        }
        addedOption.autoRenew=autoRenew;
        addedOption.attributeList=optionAttributes;
        addedOption.billingFrequency=billingFrequency;
        tempWrapper.add(addedOption);
        Map<Id,AddRemoveOptionWrapper> pricingInformationMap = getAssociatedPricingInfo(tempWrapper,bundleAttributes);  
        
        if(!pricingInformationMap.isEmpty() && pricingInformationMap.get(optionProductId)!=null){
          AddRemoveOptionWrapper pricelistItemObj = pricingInformationMap.get(optionProductId);
          System.debug('pricelistItemObj===========>'+pricelistItemObj);
          addedOption.chargeType=pricelistItemObj.chargeType;  
          if(pricelistItemObj.chargeType!='Service fee'){
            addedOption.basePrice= pricelistItemObj.basePrice.setScale(5);
            addedOption.netUnitPrice=pricelistItemObj.basePrice.setScale(5);
          }
          addedOption.sellingTerm=pricelistItemObj.sellingTerm;
          addedOption.priceListItemId=pricelistItemObj.pricelistItemId;
          if(basePriceOverride!=null){
            addedOption.basePriceOverride=basePriceOverride.setScale(5);
            addedOption.netUnitPrice = basePriceOverride.setScale(5);
            System.debug('addedOption.netUnitPrice===========>'+addedOption.netUnitPrice);
          }
        }  
        
        allOptionsWrapper.add(addedOption);
        if(!techServiceOptionGroupList.isEmpty() && techServiceOptionGroupList.contains(addedOption.optionGroupText)){
          techServiceRelatedPLis.add(addedOption.pricelistItemId);
        }
      }
      System.debug('techServiceRelatedPLis============>'+techServiceRelatedPLis);
      //Check if Tech service
      if(!techServiceRelatedPLis.isEmpty()){
        For(Apttus_Config2__PriceListItem__c pricelistItem : [select id,APTS_Call_Out_Coverage__c,APTS_Labour_Coverage__c,APTS_Spare_Parts_Coverage__c from Apttus_Config2__PriceListItem__c where id IN: techServiceRelatedPLis]){
          if(pricelistItem.APTS_Call_Out_Coverage__c!=null){
            sumOfBasicCoverage += pricelistItem.APTS_Call_Out_Coverage__c;
          }
          if(pricelistItem.APTS_Labour_Coverage__c!=null){
            sumOfBasicCoverage += pricelistItem.APTS_Labour_Coverage__c;
          }
          System.debug('sumOfBasicCoverage==>'+sumOfBasicCoverage);
          System.debug('sumOfAllInCoverage=BEFORE=>'+sumOfAllInCoverage);
          if(pricelistItem.APTS_Spare_Parts_Coverage__c!=null){
            sumOfSparePartsCoverage += pricelistItem.APTS_Spare_Parts_Coverage__c;
          }
          System.debug('sumOfAllInCoverage=AFTER=>'+sumOfAllInCoverage);
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
            System.debug('addRemoveOption.netUnitPrice BEFORE==>'+addRemoveOption.netUnitPrice);
            addRemoveOption.basePrice=sumOfBasicCoverage;
            if(sumOfBasicCoverage!=null){
              addRemoveOption.netUnitPrice=sumOfBasicCoverage;
            }
            System.debug('addRemoveOption.netUnitPrice AFTER==>'+addRemoveOption.netUnitPrice);
          }
        }
        System.debug('addRemoveOption.productid====>'+addRemoveOption.productid);
        System.debug('optionProductId====>'+optionProductId);
        if(addRemoveOption.productid==optionProductId){
          System.debug('billingFrequency====>'+billingFrequency);
          if(String.isBlank(billingFrequency)){
            String billingFreqKey = typeOfContract+';'+addRemoveOption.chargeType;
            System.debug('billingFreqKey====>'+billingFreqKey);
            APTS_Billing_Frequency__c billingFreqCustomSetting =billingFreqCustomSettingMap.get(billingFreqKey);
            addRemoveOption.billingFrequency = billingFreqCustomSetting.APTS_Biiling_Frequency__c;
          }
          System.debug('addRemoveOption.billingFrequency====>'+addRemoveOption.billingFrequency);
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
          }
          /*if(typeOfContract.equalsIgnoreCase(APTS_CPQConstants.CONSUMPTION)){
            addRemoveOption.subType='YOCI';
            addRemoveOption.discountPercentage=100;
            addRemoveOption.netUnitPrice=0;
          }*/
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
      System.debug('modifiedOptionsWrapper======>'+modifiedOptionsWrapper);
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
                              WHERE MasterLabel = 'System Properties']){
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
      System.debug('hideAttributes======>'+hideAttributes);
      System.debug('hasAllowSalesPriceYes======>'+hasAllowSalesPriceYes);
      if(!hideAttributes){
        System.debug('optionProductId==========>'+optionProductId);
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
            if(pav.Apttus_Config2__Field__c.equalsIgnoreCase(typeofPaymentSystemAPIName)){
              attributeWrapObj.assignedValue='Open system (bankcard)';
            }
            if(pav.Apttus_Config2__Field__c.equalsIgnoreCase(merchantAPIName)){
              attributeWrapObj.assignedValue='JDE';
            }
            if(pav.Apttus_Config2__Field__c.equalsIgnoreCase(firstLineResponseTime)){
              attributeWrapObj.assignedValue='0';
            }
            attributeWrapperList.add(attributeWrapObj);
          }
          //attributeSet.add(pav.Apttus_Config2__Field__c);
        }
      }
      System.debug('attributeWrapperList==========>'+attributeWrapperList);
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
       System.debug('expectedEndDate===========>'+expectedEndDate);
       return sellingTerm;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<AttributeWrapper> getDefaultAttributesForBundle(String bundelAssetId){
      List<AttributeWrapper> updatedAttributeWrapperList = new List<AttributeWrapper>();
      System.debug('bundelAssetId==========>'+bundelAssetId);
      List<AttributeWrapper> attributeWrapperList = new List<AttributeWrapper>();
      String bundleId;
      String priceListId;
      List<String> readOnlyBundleRulesList = new List<String>();
      List<String> freeOnLoanAttributeList = new List<String>();
      List<String> rentAttributeList = new List<String>();
      List<String> salesAttributeList = new List<String>();
      List<String> consumptionAttributeList = new List<String>();
      List<String> renyBuyAttributeList = new List<String>();
      String objectName = 'Apttus_Config2__AssetAttributeValue__c';

      List<Apttus_Config2__AssetLineItem__c> assetLineItem = [select id,Apttus_Config2__ProductId__c,Apttus_Config2__PriceListId__c,APTS_Type_Of_Contract__c,Apttus_Config2__BundleAssetId__c,Apttus_Config2__BundleAssetId__r.Apttus_Config2__EndDate__c,Apttus_Config2__EndDate__c
      from Apttus_Config2__AssetLineItem__c where id =: bundelAssetId limit 1];

      System.debug('assetLineItem=======>'+assetLineItem);

      attributeWrapperList = getRelatedAttributes(assetLineItem[0].Apttus_Config2__ProductId__c,null,null);

      if(assetLineItem[0].Apttus_Config2__BundleAssetId__c!=null){
        bundleId=assetLineItem[0].Apttus_Config2__BundleAssetId__c;
      }else{
        bundleId=bundelAssetId;
      }
      if(assetLineItem[0].Apttus_Config2__PriceListId__c!=null){
        priceListId = assetLineItem[0].Apttus_Config2__PriceListId__c;
      }
      System.debug('bundleId=======>'+bundleId);
      String queryString = APTS_ProductRedistributionBatchHandler.getObjectQuery('Apttus_Config2__AssetAttributeValue__c') + 'Where Apttus_Config2__AssetLineItemId__c =\''+bundleId + '\'';
      System.debug('queryString########BEFORE#######'+queryString);

      //Querying read only rules from Metadata
      for(APTS_Conversion_order_UX_settings__mdt readOnlyRuleObj : [SELECT Id,
                              APTS_Read_only_attributes_Bundle__c,
                              APTS_Free_on_loan_contract_attributes__c,
                              APTS_Rent_contract_attributes__c,
                              APTS_Consumption_contract_attributes__c,
                              APTS_Sales_contract_attributes__c,
                              APTS_RentBuy_contract_attributes__c
                              FROM APTS_Conversion_order_UX_settings__mdt
                              WHERE MasterLabel = 'System Properties']){
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
      }
      System.debug('readOnlyBundleRulesList============>'+readOnlyBundleRulesList);

      List<sObject> sobjList = Database.query(queryString);
      
      System.debug('sobjList#################3'+sobjList);

      for(AttributeWrapper attributeWrap : attributeWrapperList){
        for(Apttus_Config2__AssetAttributeValue__c assetAttribute : (List<Apttus_Config2__AssetAttributeValue__c>)sobjList){
          attributeWrap.assignedValue = String.valueOf(assetAttribute.get(attributeWrap.attributeFieldName));
        }
        System.debug('attributeWrap.attributeFieldName====>'+attributeWrap.attributeFieldName);
        if(!readOnlyBundleRulesList.isEmpty() && readOnlyBundleRulesList.contains(attributeWrap.attributeFieldName)){
          System.debug('QUALIFYING====>'+attributeWrap.attributeFieldName);
          attributeWrap.readOnly=true;
        }
        attributeWrap.pricelistId=pricelistId;
        if(!assetLineItem.isEmpty() && assetLineItem[0].APTS_Type_Of_Contract__c!=null && ((assetLineItem[0].APTS_Type_Of_Contract__c.equalsIgnoreCase('Rent') && !rentAttributeList.isEmpty() && rentAttributeList.contains(attributeWrap.attributeFieldName)) ||
        (assetLineItem[0].APTS_Type_Of_Contract__c.equalsIgnoreCase('Sales') && !salesAttributeList.isEmpty() && salesAttributeList.contains(attributeWrap.attributeFieldName)) ||
        (assetLineItem[0].APTS_Type_Of_Contract__c.equalsIgnoreCase('Free On Loan') && !freeOnLoanAttributeList.isEmpty() && freeOnLoanAttributeList.contains(attributeWrap.attributeFieldName)) ||
        (assetLineItem[0].APTS_Type_Of_Contract__c.equalsIgnoreCase('Consumption') && !consumptionAttributeList.isEmpty() && consumptionAttributeList.contains(attributeWrap.attributeFieldName)) ||
        (assetLineItem[0].APTS_Type_Of_Contract__c.equalsIgnoreCase('RentBuy') && !renyBuyAttributeList.isEmpty() && renyBuyAttributeList.contains(attributeWrap.attributeFieldName)))){
          updatedAttributeWrapperList.add(attributeWrap);
        }
      }
      System.debug('updatedAttributeWrapperList============>'+updatedAttributeWrapperList);   
      return updatedAttributeWrapperList;
    }
    public static void processAddRemoveOptions(Map<ID,Apttus_Config2__LineItem__c> lineItemMap,String orderInput,Id cartId,String bundleLevelAttributes){
      List<AddRemoveOptionWrapper> addRemoveWrapperList = (List<AddRemoveOptionWrapper>)JSON.deserializeStrict(orderInput, List<AddRemoveOptionWrapper>.class);
      List<AttributeWrapper> bundleAttributes = (List<AttributeWrapper>)JSON.deserializeStrict(bundleLevelAttributes, List<AttributeWrapper>.class);
      System.debug('bundleAttributes=====ATTRIBUTES==FROM LWC===>'+bundleAttributes);
      Map<Id,AddRemoveOptionWrapper> addingOptionMap = new Map<Id,AddRemoveOptionWrapper>();
      Map<Id,AddRemoveOptionWrapper> removeOptionMap = new Map<Id,AddRemoveOptionWrapper>();
      Map<Id,Apttus_Config2__LineItem__c> cancelledLinesMap = new Map<Id,Apttus_Config2__LineItem__c>();
      List<Apttus_Config2__LineItem__c> addLinesList = new List<Apttus_Config2__LineItem__c>();
      Map<String,String> updatedBundleAttributeMap = new Map<String,String>();
      Map<id,Apttus_Config2__ProductAttributeValue__c> attributeUpdateMap = new Map<id,Apttus_Config2__ProductAttributeValue__c>();
      Integer lineNumber;
      String pricelistId;
      String productId;
      Boolean isRepriced=false;
      for(AddRemoveOptionWrapper addRemoveObj : addRemoveWrapperList){
        if(addRemoveObj.linestatus.equalsIgnoreCase('New')){
          if(addingOptionMap.get(addRemoveObj.productid)==null){
            addingOptionMap.put(addRemoveObj.productid,addRemoveObj);
          }
        }
        if(addRemoveObj.linestatus.equalsIgnoreCase('Cancelled')){
          if(removeOptionMap.get(addRemoveObj.assetid)==null){
            removeOptionMap.put(addRemoveObj.assetid,addRemoveObj);
          }
        }
      }
      For(AttributeWrapper updatedBundleattribute : bundleAttributes){
        if(updatedBundleAttributeMap.get(updatedBundleattribute.attributeFieldName)==null){
          updatedBundleAttributeMap.put(updatedBundleattribute.attributeFieldName,updatedBundleattribute.assignedValue);
        }
      }
      For(Apttus_Config2__LineItem__c lineItem : lineItemMap.values()){
        if(!lineItem.Apttus_Config2__IsOptionRollupLine__c && lineItem.Apttus_Config2__HasOptions__c && lineItem.Apttus_Config2__LineType__c.equalsIgnoreCase('Product/Service')){
          lineNumber = Integer.valueOf(lineItem.Apttus_Config2__LineNumber__c);
          pricelistId = lineItem.Apttus_Config2__PriceListId__c;
          productId = lineItem.Apttus_Config2__ProductId__c;
        }
        if(!removeOptionMap.isEmpty() && removeOptionMap.keyset().contains(lineItem.Apttus_Config2__AssetLineItemId__c)){
          lineItem.Apttus_Config2__LineStatus__c='Cancelled';
          lineItem.Apttus_Config2__EndDate__c = removeOptionMap.get(lineItem.Apttus_Config2__AssetLineItemId__c).endDate;
          lineitem.Apttus_Config2__SellingTerm__c=null;
          if(cancelledLinesMap.get(lineitem.id)==null){
            cancelledLinesMap.put(lineitem.id,lineitem);
          }
        } 
        if(lineItem.Apttus_Config2__AttributeValueId__c!=null){
          Apttus_Config2__ProductAttributeValue__c productAttribute = new Apttus_Config2__ProductAttributeValue__c(id=lineItem.Apttus_Config2__AttributeValueId__c);
          DescribeSObjectResult d = ((SObject)(Type.forName('Schema.Apttus_Config2__ProductAttributeValue__c').newInstance())).getSObjectType().getDescribe();
          System.debug('DescribeSObjectResult==========>'+d);
          For(AttributeWrapper updatedBundleattribute : bundleAttributes){
            Schema.DisplayType fielddataType = d.fields.getMap().get(updatedBundleattribute.attributeFieldName).getDescribe().getType();
            System.debug('updatedBundleattribute.attributeFieldName==========>'+updatedBundleattribute.attributeFieldName);
            System.debug('fielddataType==========>'+fielddataType);
            if(updatedBundleattribute.attributeFieldName!=null && updatedBundleattribute.assignedValue!=null){
              if(fielddataType == Schema.DisplayType.String) {
                productAttribute.put(updatedBundleattribute.attributeFieldName,String.valueOf(updatedBundleattribute.assignedValue));
              }
              if(fielddataType == Schema.DisplayType.Picklist) {
                productAttribute.put(updatedBundleattribute.attributeFieldName,String.valueOf(updatedBundleattribute.assignedValue));
              }
              else if(fielddataType == Schema.DisplayType.Integer) {
                productAttribute.put(updatedBundleattribute.attributeFieldName,Integer.valueOf(updatedBundleattribute.assignedValue));
              }
              else if(fielddataType == Schema.DisplayType.Double) {
                productAttribute.put(updatedBundleattribute.attributeFieldName,Decimal.valueOf(updatedBundleattribute.assignedValue));
              }
              else if(fielddataType == Schema.DisplayType.Currency) {
                productAttribute.put(updatedBundleattribute.attributeFieldName,Decimal.valueOf(updatedBundleattribute.assignedValue));
              }
              else if(fielddataType == Schema.DisplayType.Percent) {
                productAttribute.put(updatedBundleattribute.attributeFieldName,Decimal.valueOf(updatedBundleattribute.assignedValue));
              }
            }
          }
          if(attributeUpdateMap.get(productAttribute.id)==null){
            attributeUpdateMap.put(productAttribute.id,productAttribute);
          }
        }
      }

      if(!cancelledLinesMap.isEmpty()){
        update cancelledLinesMap.values();
      }
      System.debug('lineNumber=========>'+lineNumber);
      System.debug('pricelistId=========>'+pricelistId);
      System.debug('productid=========>'+productId);
      System.debug('productid=========>'+productId);
      System.debug('addingOptionMap========> '+ addingOptionMap);
      System.debug('removeOptionMap========> '+ removeOptionMap);
      if(!addingOptionMap.isEmpty()){
        List<Apttus_CPQApi.CPQ.SelectedOptionDO> selectedOptDOList = new List<Apttus_CPQApi.CPQ.SelectedOptionDO>();
        Apttus_CPQApi.CPQ.ProductOptionGroupSearchResultDO result = Apttus_CPQApi.CPQWebService.getOptionGroupsForPriceListProduct(priceListId,productId);
        System.debug('result========>'+result);
        System.debug('result====.HasOptionGroups=====>'+result.HasOptionGroups);
        if(result.HasOptionGroups){
          List<Apttus_CPQApi.CPQ.ProductOptionGroupDO> prodOptGrpDOList = result.OptionGroups;
          System.debug('prodOptGrpDOList=====>'+prodOptGrpDOList);
          for(Apttus_CPQApi.CPQ.ProductOptionGroupDO prodOptGrpDO : prodOptGrpDOList){
            System.debug('prodOptGrpDO.Label=====>'+prodOptGrpDO.Label);
            System.debug('prodOptGrpDO.HasComponents=====>'+prodOptGrpDO.HasOptionComponents);
            System.debug('prodOptGrpDO.HasChildOptionGroups=====>'+prodOptGrpDO.HasChildOptionGroups);
            if(prodOptGrpDO.HasOptionComponents){
              List<Apttus_CPQApi.CPQ.ProductOptionComponentDO> prodOptCompDOList = new List<Apttus_CPQApi.CPQ.ProductOptionComponentDO>();
              prodOptCompDOList = prodOptGrpDO.OptionComponents;
              System.debug('prodOptCompDOList=====>'+prodOptCompDOList);
              for(Apttus_CPQApi.CPQ.ProductOptionComponentDO prodOptCompDO :prodOptCompDOList){
                if(addingOptionMap.keySet().contains(prodOptCompDO.ComponentProductId)){
                  AddRemoveOptionWrapper addOption = addingOptionMap.get(prodOptCompDO.ComponentProductId);
                  if(addOption.optionGroupText == prodOptGrpDO.Label){
                    Apttus_CPQApi.CPQ.SelectedOptionDO selectedOptDO = new Apttus_CPQApi.CPQ.SelectedOptionDO();
                    selectedOptDO.ComponentId = prodOptCompDO.ComponentId;
                    selectedOptDO.ComponentProductId = prodOptCompDO.ComponentProductId;
                    System.debug('selectedOptDO==1===>'+selectedOptDO);
                    selectedOptDOList.add(selectedOptDO);
                  }
                }
              }  
            }
            if(prodOptGrpDO.HasChildOptionGroups){
              List<Apttus_CPQApi.CPQ.ProductOptionGroupDO> prodOptGroupList = new List<Apttus_CPQApi.CPQ.ProductOptionGroupDO>();
              prodOptGroupList = prodOptGrpDO.ChildOptionGroups;
              for(Apttus_CPQApi.CPQ.ProductOptionGroupDO prodOptGrpChild : prodOptGroupList){
                List<Apttus_CPQApi.CPQ.ProductOptionComponentDO> prodOptCompDOList = new List<Apttus_CPQApi.CPQ.ProductOptionComponentDO>();
                prodOptCompDOList = prodOptGrpChild.OptionComponents;
                for(Apttus_CPQApi.CPQ.ProductOptionComponentDO prodOptCompDO :prodOptCompDOList){
                  if(addingOptionMap.keySet().contains(prodOptCompDO.ComponentProductId)){
                    AddRemoveOptionWrapper addOption = addingOptionMap.get(prodOptCompDO.ComponentProductId);
                    if(addOption.optionGroupText == prodOptGrpChild.Label){
                      Apttus_CPQApi.CPQ.SelectedOptionDO selectedOptDO = new Apttus_CPQApi.CPQ.SelectedOptionDO();
                      selectedOptDO.ComponentId = prodOptCompDO.ComponentId;
                      selectedOptDO.ComponentProductId = prodOptCompDO.ComponentProductId;
                      System.debug('addOption=======>'+addOption);
                      System.debug('selectedOptDO=====>'+selectedOptDO);
                      selectedOptDOList.add(selectedOptDO);
                    }
                  }
                }
              }  
            }
          }
        }
        //System.debug('removeOptionMap=========>'+removeOptionMap);
        System.debug('cartId=========>'+cartId);
        System.debug('selectedOptDOList=========>'+selectedOptDOList);
        Apttus_CPQApi.CPQ.AddOptionsResponseDO addOptRespDO = Apttus_CPQApi.CPQWebService.addOptions(cartId, lineNumber, selectedOptDOList);    
        System.debug('addOptRespDO=========>'+addOptRespDO);
        if(addOptRespDO!=null && !addOptRespDO.addedOptionLineItems.isEmpty()){
          processAttributes(addOptRespDO.addedOptionLineItems,addingOptionMap,attributeUpdateMap,bundleAttributes);
        }
        if(!attributeUpdateMap.isEmpty()){
          update attributeUpdateMap.values();
        }
        //APTS_OrderUtils.repriceCart(cartId);
        //isRepriced=true;
        if(addOptRespDO!=null && !addOptRespDO.addedOptionLineItems.isEmpty()){
           processNewlyAddedOptions(cartId,addOptRespDO.addedOptionLineItems,addingOptionMap,addLinesList,bundleAttributes);
        }
      }
      
      /*if(!removeOptionMap.isEmpty()){
        if(!isRepriced){
          APTS_OrderUtils.repriceCart(cartId);
        }
      }*/
      System.debug('addLinesList=====>'+addLinesList);
      if(!addLinesList.isEmpty()){
        update addLinesList;
      }

    } 
    /*public static void setCancellatonFields(Apttus_Config2__LineItem__c lineitem){
      lineitem.Apttus_Config2__AllocateGroupAdjustment__c = false;
      lineitem.Apttus_Config2__AllowRemoval__c = true;
      lineitem.Apttus_Config2__AllowableAction__c = 'No Adjustments';
      lineitem.Apttus_Config2__IsCustomPricing__c = false;
      lineitem.Apttus_Config2__IsQuantityModifiable__c = false;
      lineitem.Apttus_Config2__StatusDetails__c = '{"MUST_CONFIG":0,"DF_PND":0,"RQ_OPT":0,"RQ_ATTR":0,"MINMAX_VAL":0,"CONST_PND":0,"REVAL_PND":0}';
      lineitem.Apttus_Config2__ShipToAccountId__c=null;
      lineitem.Apttus_Config2__PriceAdjustment__c=lineitem.Apttus_Config2__AdjustedPrice__c;
      lineitem.Apttus_Config2__NetAdjustmentPercent__c=0;
      lineitem.Apttus_Config2__ContractNumbers__c=String.valueOf(lineitem.Apttus_Config2__EndDate__c);
      lineitem.Apttus_Config2__ConfigStatus__c='Complete';
      lineitem.Apttus_Config2__AllowManualAdjustment__c=false;
      lineitem.Apttus_Config2__ExtendedQuantity__c=1;
    }*/
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
      System.debug('bundleProductId==>'+bundleProductId);
      System.debug('pricelistId==>'+pricelistId);
      System.debug('typeOfContract==>'+typeOfContract);
      
      For(AddRemoveOptionWrapper addRemoveOptionObj : OptionProductWrapper){
        if(modifiedMap.get(addRemoveOptionObj.productid)==null){
          modifiedMap.put(addRemoveOptionObj.productid,addRemoveOptionObj);
        }
      }   
      System.debug('attributeValuesMap==>'+attributeValuesMap);
      For(Apttus_Config2__PriceListItem__c optionPLIs : [select id,Apttus_Config2__Criteria__c,
                              APTS_Default_Selling_Uom__c,Apttus_Config2__ChargeType__c,Apttus_Config2__ProductId__c,Apttus_Config2__PriceUom__c,Apttus_Config2__ListPrice__c
                              from Apttus_Config2__PriceListItem__c where Apttus_Config2__PriceListId__c =: pricelistId and Apttus_Config2__ProductId__c IN: modifiedMap.keySet() and Apttus_Config2__Active__c=true]){
        Map<String, Object> criteriaParsed;
        String oneTimePurchaseAttribute;
        Decimal numberOfHours;
        System.debug('WRAPPER IN PLI====>'+modifiedMap.get(optionPLIs.Apttus_Config2__ProductId__c));
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
        System.debug('oneTimePurchaseAttribute==>'+oneTimePurchaseAttribute);
        if(oneTimePurchaseAttribute==null){oneTimePurchaseAttribute='No';}
        System.debug('oneTimePurchaseAttribute=AFTER=>'+oneTimePurchaseAttribute);
        if(optionPLIs.Apttus_Config2__Criteria__c!=null && typeOfContract!=null){
          if((typeOfContract.equalsIgnoreCase('Consumption') || (rentalFeeTOCSet.contains(typeOfContract) && oneTimePurchaseAttribute!=null && oneTimePurchaseAttribute.equalsIgnoreCase('No')))&& optionPLIs.Apttus_Config2__ChargeType__c.equalsIgnoreCase('Rental Fee')){
            if(modifiedMap.get(optionPLIs.Apttus_Config2__ProductId__c)!=null){
              AddRemoveOptionWrapper newlyAddedOption = modifiedMap.get(optionPLIs.Apttus_Config2__ProductId__c);
              newlyAddedOption.chargeType = optionPLIs.Apttus_Config2__ChargeType__c;
              newlyAddedOption.priceListItemId = optionPLIs.id;
              newlyAddedOption.basePrice=optionPLIs.Apttus_Config2__ListPrice__c;
              modifiedMap.put(optionPLIs.Apttus_Config2__ProductId__c,newlyAddedOption);
            }
            System.debug('==========ITS A RENTAL PLI=======WITH CTC=========');
            System.debug('PLI link======>'+optionPLIs.id);
            rentalPLIs.add(optionPLIs.id);
          }
          if((salesFeeTOCSet.contains(typeOfContract) || (!salesFeeTOCSet.contains(typeOfContract) && (oneTimePurchaseAttribute!=null && oneTimePurchaseAttribute.equalsIgnoreCase('Yes')))) && optionPLIs.Apttus_Config2__ChargeType__c.equalsIgnoreCase('Sales Price')){
            System.debug('==========ITS A SALES PLI=======WITH CTC=========');
            System.debug('Sales price==CTC==='+optionPLIs.id);
            if(modifiedMap.get(optionPLIs.Apttus_Config2__ProductId__c)!=null){
              AddRemoveOptionWrapper newlyAddedOption = modifiedMap.get(optionPLIs.Apttus_Config2__ProductId__c);
              newlyAddedOption.chargeType = optionPLIs.Apttus_Config2__ChargeType__c;
              newlyAddedOption.priceListItemId = optionPLIs.id;
              newlyAddedOption.basePrice = optionPLIs.Apttus_Config2__ListPrice__c;
              modifiedMap.put(optionPLIs.Apttus_Config2__ProductId__c,newlyAddedOption);
            }
          }
        }else if(optionPLIs.Apttus_Config2__ChargeType__c.equalsIgnoreCase('Service Fee') && modifiedMap.get(optionPLIs.Apttus_Config2__ProductId__c)!=null){
          System.debug('==========ITS A '+optionPLIs.Apttus_Config2__ChargeType__c+' PLI=======WO CTC=========');
          System.debug('optionPLIs.Apttus_Config2__ChargeType__c====>'+optionPLIs.Apttus_Config2__ChargeType__c);
          AddRemoveOptionWrapper newlyAddedOption = modifiedMap.get(optionPLIs.Apttus_Config2__ProductId__c);
          newlyAddedOption.chargeType = optionPLIs.Apttus_Config2__ChargeType__c;
          newlyAddedOption.priceListItemId = optionPLIs.id;
          modifiedMap.put(optionPLIs.Apttus_Config2__ProductId__c,newlyAddedOption);
        }else{
          System.debug('==========ITS A '+optionPLIs.Apttus_Config2__ChargeType__c+' PLI=======WO CTC=========');
          System.debug('optionPLIs.Apttus_Config2__ChargeType__c====>'+optionPLIs.Apttus_Config2__ChargeType__c);
          System.debug('Sales price==NO CTC==='+optionPLIs.id);
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
          }
          modifiedMap.put(addRemoveOptionObj.productid,newlyAddedOption);
        }
      } 
      System.debug('modifiedMap======>'+modifiedMap);
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
              System.debug('Range =>'+ pmatrixEntry.Apttus_Config2__Dimension1Value__c);
              System.debug('the value 1 =>'+ pmatrixEntry.Apttus_Config2__AdjustmentAmount__c);
              System.debug('INSIDE MATRIX WRAPPER ===>'+modifiedMap.get(pmatrixEntry.Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__c));
              if(newlyAddedOption.chargeType.equalsIgnoreCase('Rental Fee')){
                newlyAddedOption.basePrice=pmatrixEntry.Apttus_Config2__AdjustmentAmount__c;
                modifiedMap.put(pmatrixEntry.Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__c,newlyAddedOption);
              }
              break;
            }
          }
        }
      }
      System.debug('modifiedMap==FINAL====>'+modifiedMap);
      return modifiedMap;
    }
    public static void processNewlyAddedOptions(Id cartId, List<Apttus_Config2__LineItem__c> lineItemsList,Map<Id,AddRemoveOptionWrapper> addingOptionMap, List<Apttus_Config2__LineItem__c> addLinesList,List<AttributeWrapper> bundleAttributes){
       Apttus_CPQApi.CPQ.UpdateManualAdjustmentsRequestDO adjRequest = new  Apttus_CPQApi.CPQ.UpdateManualAdjustmentsRequestDO();
          List<Apttus_CPQApi.CPQ.AdjustmentItemCollDO> lineItemAdjustments = new List<Apttus_CPQApi.CPQ.AdjustmentItemCollDO>();
          List<Apttus_Config2__AdjustmentLineItem__c> adjustmentList;
          adjRequest.CartId = cartId; 
          for(Apttus_Config2__LineItem__c lineitem : lineItemsList){
            adjustmentList=new List<Apttus_Config2__AdjustmentLineItem__c>();
            System.debug('addingOptionMap=========>'+addingOptionMap);
            System.debug('lineItem.old TOC=========>'+lineItem.APTS_old_toc__c);
            System.debug('lineItem.APTS_Type_Of_Contract__c=========>'+lineItem.APTS_Type_Of_Contract__c);
            System.debug('lineItem.Apttus_Config2__OptionId__c=========>'+lineItem.Apttus_Config2__OptionId__c);
            Apttus_CPQApi.CPQ.AdjustmentItemCollDO adjItemColl = new Apttus_CPQApi.CPQ.AdjustmentItemCollDO(); 
            adjItemColl.LineItemId = lineitem.Id;
            Apttus_Config2__AdjustmentLineItem__c newAdjustment =new Apttus_Config2__AdjustmentLineItem__c();
            AddRemoveOptionWrapper addOption = addingOptionMap.get(lineItem.Apttus_Config2__OptionId__c);
            System.debug('added OPTION NEW=========>'+addOption);
            lineItem.APTS_Start_Date_New_UX__c=addOption.startDate;
            lineItem.APTS_List_Price_New_UX__c=addOption.basePrice;
            lineitem.APTS_Is_DateDefaulted_AmendSD__c=true;
            lineitem.APTS_End_Date_New_UX__c=addOption.endDate;
            lineitem.APTS_Is_DateDefaulted_AmendED__c=true;
            lineitem.APTS_Is_DateDefaulted_NewLI__c=true;
            lineitem.APTS_Auto_renew_New_UX__c=addOption.autoRenew;
            lineitem.Apttus_Config2__BasePriceOverride__c=addOption.basePriceOverride;
            System.debug('***addOption.assetName=========>'+addOption.assetName);
            System.debug('***addOption.billingFrequency=========>'+addOption.billingFrequency);
            lineitem.APTS_Billing_frequency_New_UX__c=addOption.billingFrequency;
            lineitem.APTS_Default_Billing_Frequency__c=true;
            System.debug('productAttList====>'+addOption.attributeList);
            if(!bundleAttributes.isEmpty()){
              For(AttributeWrapper updatedBundleattribute : bundleAttributes){
                if(updatedBundleattribute.attributeFieldName.equalsIgnoreCase(typeOfContractAPIName)){
                  lineitem.APTS_old_toc__c=updatedBundleattribute.assignedValue;
                }
              }
            }
            if(addOption.subType!=null && addOption.discountPercentage!=null){
              newAdjustment.Apttus_Config2__SubType__c=addOption.subType;
              newAdjustment.Apttus_Config2__AdjustmentType__c='% Discount';
              newAdjustment.Apttus_Config2__AdjustmentAmount__c=addOption.discountPercentage;
              adjustmentList.add(newAdjustment);
            }
            if(addOption.subType!=null && addOption.discountAmount!=null){
              newAdjustment.Apttus_Config2__SubType__c=addOption.subType;
              newAdjustment.Apttus_Config2__AdjustmentType__c='Base Price Discount';
              newAdjustment.Apttus_Config2__AdjustmentAmount__c=addOption.discountAmount;
              adjustmentList.add(newAdjustment);
            } 
            adjItemColl.AdjustmentItems =APTS_DiscountBucketizing.processAdjustmentLineItemfields(adjustmentList); 
            lineItemAdjustments.add(adjItemColl);
            addLinesList.add(lineItem);
          }
          adjRequest.AdjustmentItemColls = lineItemAdjustments;
          Apttus_CPQApi.CPQ.UpdateManualAdjustmentsResponseDO adjustmentsResult =  Apttus_CPQApi.CPQWebService.updateManualAdjustmentsForCart(adjRequest);
    }
    public static void processAttributes(List<Apttus_Config2__LineItem__c> lineItemsList,Map<Id,AddRemoveOptionWrapper> addingOptionMap,Map<id,Apttus_Config2__ProductAttributeValue__c> attributeUpdateMap,List<AttributeWrapper> bundleAttributes){
      List<AttributeWrapper> technicalServicesAttributes = new List<AttributeWrapper>();
      for(Apttus_Config2__LineItem__c lineitem : lineItemsList){
        AddRemoveOptionWrapper addOption = addingOptionMap.get(lineItem.Apttus_Config2__OptionId__c);
        System.debug('added OPTION NEW=========>'+addOption);
        if(!addOption.assetName.equalsIgnoreCase('NO COVERAGE') && addOption!=null && addOption.optionGroupText.equalsIgnoreCase('Technical Service') && addOption.attributeList.isEmpty()){
          AttributeWrapper techAttributeCOC = new AttributeWrapper();
          techAttributeCOC.attributeFieldName='APTS_Call_Out_Coverage_chk__c';
          techAttributeCOC.assignedValue='Yes';
          technicalServicesAttributes.add(techAttributeCOC);
    
          AttributeWrapper techAttributeCOCPerc = new AttributeWrapper();
          techAttributeCOCPerc.attributeFieldName='APTS_Call_Out_Coverage_Percent__c';
          techAttributeCOCPerc.assignedValue='100';
          technicalServicesAttributes.add(techAttributeCOCPerc);
    
          AttributeWrapper techAttributeLC = new AttributeWrapper();
          techAttributeLC.attributeFieldName='APTS_Labour_Coverage_chk__c';
          techAttributeLC.assignedValue='Yes';
          technicalServicesAttributes.add(techAttributeLC);
    
          AttributeWrapper techAttributeLCPerc = new AttributeWrapper();
          techAttributeLCPerc.attributeFieldName='APTS_Labour_Coverage_Percent__c';
          techAttributeLCPerc.assignedValue='100';
          technicalServicesAttributes.add(techAttributeLCPerc);
    
          if(addOption.assetName.equalsIgnoreCase('ALL-IN COVERAGE')){
            AttributeWrapper techAttributeSPC = new AttributeWrapper();
            techAttributeSPC.attributeFieldName='APTS_Spare_Parts_Coverage_chk__c';
            techAttributeSPC.assignedValue='Yes';
            technicalServicesAttributes.add(techAttributeSPC);
    
            AttributeWrapper techAttributeSPCPerc = new AttributeWrapper();
            techAttributeSPCPerc.attributeFieldName='APTS_Spare_Parts_Coverage_Percent__c';
            techAttributeSPCPerc.assignedValue='100';
            technicalServicesAttributes.add(techAttributeSPCPerc);
          }
    
        }
        if(!addOption.attributeList.isEmpty() || !technicalServicesAttributes.isEmpty() || !bundleAttributes.isEmpty()){
          Apttus_Config2__ProductAttributeValue__c attributeValue = new Apttus_Config2__ProductAttributeValue__c(id=lineitem.Apttus_Config2__AttributeValueId__c);
          if(!addOption.attributeList.isEmpty()){
            for(AttributeWrapper attributeObj : addOption.attributeList){
              System.debug('attributeObj.attributeFieldName====>'+attributeObj.attributeFieldName);
              System.debug('attributeObj.assignedValue====>'+attributeObj.assignedValue);
              if(attributeObj.attributeFieldName!=null && attributeObj.assignedValue!=null){
                if(attributeObj.attributeFieldName.equalsIgnoreCase(numberOfHoursAPIName) || attributeObj.attributeFieldName.equalsIgnoreCase(firstLineResponseTime)){
                  if(String.isBlank(attributeObj.assignedValue)){ 
                      attributeObj.assignedValue='0';
                  }
                  attributeValue.put(attributeObj.attributeFieldName,Decimal.valueOf(attributeObj.assignedValue));
                }else{
                  attributeValue.put(attributeObj.attributeFieldName,attributeObj.assignedValue);
                }
              }
            }
          }
          if(!bundleAttributes.isEmpty()){
            DescribeSObjectResult d = ((SObject)(Type.forName('Schema.Apttus_Config2__ProductAttributeValue__c').newInstance())).getSObjectType().getDescribe();
            For(AttributeWrapper updatedBundleattribute : bundleAttributes){
              Schema.DisplayType fielddataType = d.fields.getMap().get(updatedBundleattribute.attributeFieldName).getDescribe().getType();
              if(updatedBundleattribute.attributeFieldName!=null && updatedBundleattribute.assignedValue!=null){
                if(fielddataType == Schema.DisplayType.String) {
                  attributeValue.put(updatedBundleattribute.attributeFieldName,String.valueOf(updatedBundleattribute.assignedValue));
                }
                if(fielddataType == Schema.DisplayType.Picklist) {
                  attributeValue.put(updatedBundleattribute.attributeFieldName,String.valueOf(updatedBundleattribute.assignedValue));
                }
                else if(fielddataType == Schema.DisplayType.Integer) {
                  attributeValue.put(updatedBundleattribute.attributeFieldName,Integer.valueOf(updatedBundleattribute.assignedValue));
                }
                else if(fielddataType == Schema.DisplayType.Double) {
                  attributeValue.put(updatedBundleattribute.attributeFieldName,Decimal.valueOf(updatedBundleattribute.assignedValue));
                }
                else if(fielddataType == Schema.DisplayType.Currency) {
                  attributeValue.put(updatedBundleattribute.attributeFieldName,Decimal.valueOf(updatedBundleattribute.assignedValue));
                }
                else if(fielddataType == Schema.DisplayType.Percent) {
                  attributeValue.put(updatedBundleattribute.attributeFieldName,Decimal.valueOf(updatedBundleattribute.assignedValue));
                }
              }
            }
          }
          if(!technicalServicesAttributes.isEmpty()){
            Decimal value;
            For(AttributeWrapper technicalService : technicalServicesAttributes){
              value=0;
              if(technicalService.attributeFieldName!=null && technicalService.assignedValue!=null){
                if(technicalService.attributeFieldName.contains('Percent__c')){
                  value = Decimal.valueOf(technicalService.assignedValue);
                }
                if(value!=0){
                  attributeValue.put(technicalService.attributeFieldName,value);    
                }else{
                  attributeValue.put(technicalService.attributeFieldName,technicalService.assignedValue);
                }
              }
            }
          }
    
          if(attributeUpdateMap.get(attributeValue.id)==null){
            attributeUpdateMap.put(attributeValue.id,attributeValue);
          }
        }
      }
    }    
  }