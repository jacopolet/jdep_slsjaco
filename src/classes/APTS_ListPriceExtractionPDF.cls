/*
 * This class is used to display List price extraction + CSP page.
 * Created By - Karan Khatri
 * Created Date - 17th May, 2018
 * Modified History
 * // v100 - Defect 21155 - Updated the query filter
 * // v101 - Defect 22913 - Logic added to extract Prices For ZOPT Machines and Concepts
 * // v102 - Defect 4283 - 1. Code fix for not to display irrevalent Materials. 
                           2. Code fix to clear all previous search results.
*/

public without sharing class APTS_ListPriceExtractionPDF {

   
    public boolean groupByCategory { get; set; }
    public boolean includeVat { get; set; } 
    public boolean includeTax { get; set; }
    //<< v102 - Start
    public boolean displayBundleProduct { get; set; }
    //>> v102 - End
    public String userDefinedUOM { get; set; }    
    transient public String groupByCategoryPdf { get; set; }
    transient public String includeVatPdf{ get; set; }
    transient public String includeTaxPdf{ get; set; }
    transient public String isExportAsXls{ get; set; }     
    public List<compareListPriceExtractionWrapper> comparepriceList{get;set;}
    public List<ListPriceExtractionWrapper> productpriceList{get;set;}  
    public Apttus_Config2__PriceList__c priceListDetails{get;set;}
    public String region {get;set;}
    public ID pricelistID;
    public ID acctID;  
    
    public APTS_ListPriceExtractionPDF(){
        productpriceList = new List<ListPriceExtractionWrapper>();
        comparepriceList = new List<compareListPriceExtractionWrapper>();
        groupByCategory = true;
    } 

    /* Method name : loadProductsList
       Description : Method used to Load products on List Price extraction wizard page and PDF page*/
   public void loadProductsList(){
       
       //initialize
     String selectedCatgsXLS = '';
     String userUOMPdf = '';
     String selectedCatgs;
     //<< v101 - Start
     Set<String> prefixCodeMachineConcept = new Set<String> {'04', '07'};
     //>> v101 - End
     Set<String> displayCategoryFormat = new  Set<String>();
     Set<String> salesCatalogIDSet = new Set<String>();
     Set<String> productCodeSet = new Set<String>();
     //<< v102 - Start
     Set<String> categoryMachineConcept = new Set<String> {'Machines', 'Concepts'};     
     displayBundleProduct = false; 
     //>> v102 - End
     Set<ID> pliIds = new Set<Id>();
     //<< v101 - Start
     Set<ID> optGroupIndiProductIds = new Set<ID>();
     Set<ID> pliUniqueIds = new Set<ID>();
     //>> v101 - End

     
     productpriceList = new List<ListPriceExtractionWrapper>();
     comparepriceList = new List<compareListPriceExtractionWrapper>();
     List<string> catselected = new List<string>();
     //<< v102 - Start
     List<string> productFamilyCode = new List<string>();
     //>> v102 - End
     List<Apttus_Config2__PriceMatrix__c> pricematList = new List<Apttus_Config2__PriceMatrix__c>();
     List<APTS_Contract_Entitlement_Repository__c>cerList = new List<APTS_Contract_Entitlement_Repository__c>();
     List<Apttus_Config2__PriceListItem__c> customerpricelistItemList = new List<Apttus_Config2__PriceListItem__c>();
     List<Apttus_Config2__PriceListItem__c> pricelistItemList = new List<Apttus_Config2__PriceListItem__c>();
     
     //<< v101 - Start
     Map<Id, String> componentParentProductMap = new Map<Id, String>();
     Map<Id, Id> priceListwithComponentProductMap = new Map<Id, Id>();
     //>> v101 - End
     //<< v102 - Start
     Map<Id, String> optionGroupBundleProductCodeMap = new Map<Id, String>();
     Map<Id, String> optionGroupBundleProductNameMap = new Map<Id, String>();
     //>> v102 - End
     Map<Id,String> plidiscMap = new Map<Id,String>();
     Map<Id,decimal> plinetpriceMap = new Map<Id,decimal>();
     Map<Id,decimal> plinetpricetaxMap = new Map<Id,decimal>();          
     Map<String,String> regionMap = new  Map<String,String>();
     Map<String,String> UOMMap = new  Map<String,String>();
     
     Map<Id,List<Apttus_Config2__PriceMatrix__c>> plimatrixMap = new Map<Id,List<Apttus_Config2__PriceMatrix__c>>();
     Map<String,String> productCategoryMap = new  Map<String,String>();
     Map<ID,Apttus_Config2__FrequencyConversionRate__c> uomConversionMap= new Map<ID,Apttus_Config2__FrequencyConversionRate__c>();
     Map<Id,List<APTS_Contract_Entitlement_Repository__c>> pliCERmap = new Map<Id,List<APTS_Contract_Entitlement_Repository__c>>();
     Map<Id,String> plimatrixentryMap = new Map<Id,String>();
     Map<String,Decimal> uomConversionValueMap = new Map<String,Decimal>();
       
       try{
            //Fetching params from query string
            groupByCategoryPdf = ApexPages.currentPage().getParameters().get('GroupByCategory');
            includeTaxPdf = ApexPages.currentPage().getParameters().get('includeTax');
            includeVatPdf = ApexPages.currentPage().getParameters().get('includeVat');
            userUOMPdf = ApexPages.currentPage().getParameters().get('userUOM');
            isExportAsXls = ApexPages.currentPage().getParameters().get('isExportAsXls'); 
            //<< v102 - Start
            if(ApexPages.currentPage().getParameters().get('selectedCatgsXLS')!=null){
                selectedCatgsXLS = EncodingUtil.urlDecode(ApexPages.currentPage().getParameters().get('selectedCatgsXLS'),'UTF-8');
            }
            getQueryStringParams();
            
            if(selectedCatgsXLS != null){
                catselected = selectedCatgsXLS.split(',');
            }  
                   

            for(string categories : catselected){
                productFamilyCode.add(APTS_ListPriceExtractionCtrl.productFamilyMap.get(categories));
                if(categoryMachineConcept.contains(categories) && isExportAsXls == 'true'){ displayBundleProduct = true; }
            }
            //>> v102 - End  

            for( Schema.PicklistEntry v : Apttus_Config2__FrequencyConversionRate__c.Apttus_Config2__ToUom__c.getDescribe().getPicklistValues()) {
                UOMMap.put(v.getValue(),v.getLabel());
            }
            
              
            //Map for Product Family API and Values
            for( Schema.PicklistEntry v : Apttus_Config2__PriceList__c.APTS_Region__c.getDescribe().getPicklistValues()) {
                regionMap.put(v.getValue(),v.getLabel());
            }

            if(pricelistID != null){
                priceListDetails = [select id,name,CreatedDate,APTS_Region__c,Apttus_Config2__AccountId__c from Apttus_Config2__PriceList__c where Id =: pricelistID limit 1];
                if(priceListDetails != null && priceListDetails.APTS_Region__c != null && !regionMap.isEmpty() && regionMap.get(priceListDetails.APTS_Region__c)!=null){
                    region = regionMap.get(priceListDetails.APTS_Region__c);
                }
        // v100, v102 - Start
                //List of price list items - used for display list of products with details
                pricelistItemList = [SELECT Id,Apttus_Config2__ProductCode__c,APTS_Default_Selling_Uom__c,APTS_VAT_percentage__c,Apttus_Config2__ChargeType__c,Apttus_Config2__ProductId__r.APTS_Sales_Catalog__c,
                      Apttus_Config2__ProductId__r.IsActive,Apttus_Config2__Active__c,Apttus_Config2__ProductId__r.name,Apttus_Config2__ProductId__c,Apttus_Config2__PriceUom__c,APTS_Tax_per_UOM__c,
                      Apttus_Config2__Description__c,Apttus_Config2__ListPrice__c,Apttus_Config2__PriceListId__r.Apttus_Config2__AccountId__c , CurrencyIsoCode,
                      Apttus_Config2__ProductId__r.APTS_Material_Type__c, Apttus_Config2__ProductId__r.APTS_Option_Group_Indicator__c, toLabel(Apttus_Config2__ProductId__r.APTS_Option_Family__c)
                   FROM Apttus_Config2__PriceListItem__c 
                   WHERE Apttus_Config2__PriceListId__c =: priceListDetails.Id AND
                       Apttus_Config2__PriceListId__r.Apttus_Config2__Active__c = true AND 
                       Apttus_Config2__Active__c = true AND 
                       Apttus_Config2__ProductId__r.Family IN : productFamilyCode AND
                       Apttus_Config2__ProductId__r.IsActive = true 
                     ORDER BY Apttus_Config2__ProductId__c LIMIT 1800];
        // v100 - End
        system.debug('PLI '+pricelistItemList.size());
        //<< v101 - Start
              for(Apttus_Config2__PriceListItem__c pli : pricelistItemList) {
                          if(pli.Apttus_Config2__ProductId__c != null && String.isNotBlank(pli.Apttus_Config2__ProductId__r.APTS_Sales_Catalog__c)){
                              if(prefixCodeMachineConcept.contains(String.valueOf(pli.Apttus_Config2__ProductId__r.APTS_Sales_Catalog__c).subString(0,2))){
                                  optGroupIndiProductIds.add(pli.Apttus_Config2__ProductId__c);
                          }
                         system.debug(pli.Apttus_Config2__ProductId__r.APTS_Sales_Catalog__c);
                  }
                  pliUniqueIds.add(pli.Id);
                }

                if(!optGroupIndiProductIds.isEmpty()){
                    for(Apttus_Config2__ProductOptionComponent__c poc :[Select id, Apttus_Config2__ParentProductId__r.ProductCode, 
                                                                                Apttus_Config2__ComponentProductId__c,
                                                                                Apttus_Config2__ComponentProductId__r.ProductCode,
                                                                                Apttus_Config2__ComponentProductId__r.Name,
                                                                                Apttus_Config2__ParentProductId__r.APTS_Sales_Catalog__c 
                                                                        from Apttus_Config2__ProductOptionComponent__c 
                                                                        where Apttus_Config2__ParentProductId__c IN: optGroupIndiProductIds and 
                                                                             Apttus_Config2__ComponentProductId__r.APTS_Option_Group_Indicator__c != '' and 
                                                                             Apttus_Config2__ComponentProductId__r.APTS_Option_Group_Indicator__c != '00' and
                                                                             Apttus_Config2__ComponentProductId__r.APTS_Material_Type__c = 'ZOPT']){
                        componentParentProductMap.put(poc.Apttus_Config2__ComponentProductId__c, poc.Apttus_Config2__ParentProductId__r.ProductCode);
                        //<< v102 - Start
                        optionGroupBundleProductCodeMap.put(poc.Apttus_Config2__ComponentProductId__c, poc.Apttus_Config2__ParentProductId__r.APTS_Sales_Catalog__c);
                        optionGroupBundleProductNameMap.put(poc.Apttus_Config2__ComponentProductId__c, poc.Apttus_Config2__ComponentProductId__r.Name);
                        //>> v102 - End
                    
                    }

                    for(Apttus_Config2__PriceListItem__c prLiIT : [SELECT Id,Apttus_Config2__ProductCode__c,APTS_Default_Selling_Uom__c,APTS_VAT_percentage__c,Apttus_Config2__ChargeType__c,
                                                                            Apttus_Config2__ProductId__r.APTS_Sales_Catalog__c,Apttus_Config2__ProductId__r.IsActive,Apttus_Config2__Active__c,
                                                                            Apttus_Config2__ProductId__r.name, Apttus_Config2__ProductId__c,Apttus_Config2__PriceUom__c,APTS_Tax_per_UOM__c,
                                                                            Apttus_Config2__Description__c,Apttus_Config2__ListPrice__c,Apttus_Config2__PriceListId__r.Apttus_Config2__AccountId__c, 
                                                                            CurrencyIsoCode, Apttus_Config2__ProductId__r.APTS_Material_Type__c, Apttus_Config2__ProductId__r.APTS_Option_Group_Indicator__c,
                                                                            toLabel(Apttus_Config2__ProductId__r.APTS_Option_Family__c)
                                                                     FROM Apttus_Config2__PriceListItem__c 
                                                                     WHERE Apttus_Config2__ProductId__c IN: componentParentProductMap.keyset() AND 
                                                                           Apttus_Config2__PriceListId__c =: pricelistID AND
                                                                           Apttus_Config2__PriceListId__r.Apttus_Config2__Active__c = true AND 
                                                                           Apttus_Config2__Active__c = true AND 
                                                                           Apttus_Config2__ProductId__r.APTS_Option_Family__c != '' AND
                                                                           Apttus_Config2__ProductId__r.IsActive = true]){
                        if(!pliUniqueIds.contains(prLiIT.Id)) {
                          pricelistItemList.add(prLiIT);
                          pliUniqueIds.add(prLiIT.id);
                        }
                        priceListwithComponentProductMap.put(prLIIT.Id, prLIIT.Apttus_Config2__ProductId__c);

                    }
                }
                //>> v101, v102 - End
                system.debug('PLI '+pricelistItemList.size());
                for(Apttus_Config2__PriceListItem__c pli : pricelistItemList) {
                  if(pli.Apttus_Config2__ChargeType__c.contains('Rental')){
                        pliids.add(pli.id);    
                    }               
                }
              
              for(Apttus_Config2__PriceMatrix__c primat : [Select Id,Name,Apttus_Config2__PriceListItemId__c,Apttus_Config2__Dimension1Id__c,Apttus_Config2__Dimension2Id__c,
                                        Apttus_Config2__Dimension3Id__c,Apttus_Config2__Dimension4Id__c,Apttus_Config2__Dimension5Id__c,
                                        (SELECT Id,Name,Apttus_Config2__Dimension1Value__c,Apttus_Config2__AdjustmentAmount__c FROM Apttus_Config2__MatrixEntries__r),
                                        Apttus_Config2__Dimension6Id__c 
                                    FROM Apttus_Config2__PriceMatrix__c 
                                    WHERE (Apttus_Config2__PriceListItemId__c IN: pliids) AND 
                                        (Apttus_Config2__Dimension1Id__r.Name = 'Selling Term' OR 
                                         Apttus_Config2__Dimension2Id__r.Name = 'Selling Term' OR 
                                         Apttus_Config2__Dimension3Id__r.Name = 'Selling Term' OR  
                                         Apttus_Config2__Dimension4Id__r.Name = 'Selling Term' OR 
                                         Apttus_Config2__Dimension5Id__r.Name = 'Selling Term' OR  
                                         Apttus_Config2__Dimension6Id__r.Name = 'Selling Term')]){
                    if(plimatrixMap.containskey(primat.Apttus_Config2__PriceListItemId__c)) {
                      List<Apttus_Config2__PriceMatrix__c> primatList = plimatrixMap.get(primat.Apttus_Config2__PriceListItemId__c);
                      primatList.add(primat);
                      plimatrixMap.put(primat.Apttus_Config2__PriceListItemId__c,primatList);
                    }
                    else{
                      plimatrixMap.put(primat.Apttus_Config2__PriceListItemId__c,new List<Apttus_Config2__PriceMatrix__c>{primat});
                    }
                    List<Apttus_Config2__PriceMatrixEntry__c> plmatent = primat.Apttus_Config2__MatrixEntries__r;
                    Apttus_Config2__PriceMatrixEntry__c plmatentry = plmatent[0];
                    //Added by Abhishek K to fetch the Minimum Price Dimension Values
                    for(Apttus_Config2__PriceMatrixEntry__c plm : plmatent)
                    {
                    if(plm.Apttus_Config2__Dimension1Value__c < plmatentry.Apttus_Config2__Dimension1Value__c){ plmatentry = plm;}
                    }
                     
                    plimatrixentryMap.put(primat.Apttus_Config2__PriceListItemId__c,plmatentry.Apttus_Config2__Dimension1Value__c);                
              }
              
            }

           if(acctID != null){
                cerList = APTS_CERUtility.getContractedProductsWithDiscounts(acctId);
                cerList.sort();
            }
            
            
            if(!cerList.isEmpty()){
                for(APTS_Contract_Entitlement_Repository__c cer : cerList){
                     if(pliCERmap.containskey(cer.APTS_Agreement_Adjustment_Line_Item__r.Apttus_CMConfig__LineItemId__r.Apttus_CMConfig__PriceListItemId__c)){
                             List<APTS_Contract_Entitlement_Repository__c> cerListtemp = new List<APTS_Contract_Entitlement_Repository__c>();
                             cerListtemp.add(cer);
                             pliCERmap.put(cer.APTS_Agreement_Adjustment_Line_Item__r.Apttus_CMConfig__LineItemId__r.Apttus_CMConfig__PriceListItemId__c,cerListtemp);
                            
                         }
                         else{
                             pliCERmap.put(cer.APTS_Agreement_Adjustment_Line_Item__r.Apttus_CMConfig__LineItemId__r.Apttus_CMConfig__PriceListItemId__c,new List<APTS_Contract_Entitlement_Repository__c>{cer});
                             
                         }
             
                     if(plinetpriceMap.get(cer.APTS_Agreement_Adjustment_Line_Item__r.Apttus_CMConfig__LineItemId__r.Apttus_CMConfig__PriceListItemId__c) == null){                
                         plinetpriceMap.put(cer.APTS_Agreement_Adjustment_Line_Item__r.Apttus_CMConfig__LineItemId__r.Apttus_CMConfig__PriceListItemId__c,cer.APTS_Agreement_Line_Item__r.Apttus__NetPrice__c);
                         
                     }else{
                         
                     }
                     if(plinetpricetaxMap.get(cer.APTS_Agreement_Adjustment_Line_Item__r.Apttus_CMConfig__LineItemId__r.Apttus_CMConfig__PriceListItemId__c) == null){
                         plinetpricetaxMap.put(cer.APTS_Agreement_Adjustment_Line_Item__r.Apttus_CMConfig__LineItemId__r.Apttus_CMConfig__PriceListItemId__c,cer.APTS_Agreement_Line_Item__r.APTS_Net_Price_Inc_taxes__c);
                         
                     }
                     else{
                         
                     }

                     
                    if(plidiscMap.get(cer.APTS_Agreement_Adjustment_Line_Item__r.Apttus_CMConfig__LineItemId__r.Apttus_CMConfig__PriceListItemId__c) == null){
                        string typevalue = cer.APTS_Type__c+'  '+cer.APTS_Adjustment_Value__c ;
                        plidiscMap.put(cer.APTS_Agreement_Adjustment_Line_Item__r.Apttus_CMConfig__LineItemId__r.Apttus_CMConfig__PriceListItemId__c,typevalue);
                        
                    }else {
                        string typevalue2 = cer.APTS_Type__c+'  '+cer.APTS_Adjustment_Value__c ;
                        String disctype = plidiscMap.get(cer.APTS_Agreement_Adjustment_Line_Item__r.Apttus_CMConfig__LineItemId__r.Apttus_CMConfig__PriceListItemId__c);
                        
                        disctype += ' '+typevalue2;
                        
                        plidiscMap.clear(); 
                        plidiscMap.put(cer.APTS_Agreement_Adjustment_Line_Item__r.Apttus_CMConfig__LineItemId__r.Apttus_CMConfig__PriceListItemId__c,disctype);
                        
                    }
                } 
            }       
            
            if(!pricelistItemList.isEmpty()){
                for(Apttus_Config2__PriceListItem__c pricelistItem : pricelistItemList){            
                    if(pricelistItem.Apttus_Config2__ProductId__r.APTS_Sales_Catalog__c!=null){                                    
                        salesCatalogIDSet.add(pricelistItem.Apttus_Config2__ProductId__r.APTS_Sales_Catalog__c);
                        productCodeSet.add(pricelistItem.Apttus_Config2__ProductCode__c);
                        pliIds.add(pricelistItem.Id);
                        if(!pliCERmap.isEmpty() && pliCERmap.containskey(pricelistItem.Id) && 
                        pricelistItem.Apttus_Config2__PriceListId__r.Apttus_Config2__AccountId__c != null && 
                         acctID != null && 
                         pricelistItem.Apttus_Config2__PriceListId__r.Apttus_Config2__AccountId__c == acctID){
                             customerpricelistItemList.add(pricelistItem);
                             
                         }
                    }
                }
            }
            //get all UOM conversion rates
            if(!productCodeSet.isEmpty() /*&& userDefinedUOM!=null */){
            
        for( Apttus_Config2__FrequencyConversionRate__c freqConversion : [SELECT id,Apttus_Config2__FromUom__c,Apttus_Config2__ToUom__c,Apttus_Config2__ProductFamily__c,
                                             Apttus_Config2__ConversionFactor__c,Apttus_Config2__ProductId__c,APTS_ProductCode__c 
                                          FROM Apttus_Config2__FrequencyConversionRate__c 
                                          WHERE Apttus_Config2__ToUom__c =: userUOMPdf AND 
                                            Apttus_Config2__FromUom__c =: APTS_CPQConstants.PIECE_UOM_API AND 
                                            APTS_ProductCode__c IN: productCodeSet LIMIT 25000]) {
          if(uomConversionMap.containskey(freqConversion.id)) {         
                        if(uomConversionMap.get(freqConversion.id)==null){
                            uomConversionMap.put(freqConversion.id,freqConversion);
                        }
                   }else {  uomConversionMap.put(freqConversion.id,freqConversion); } 

                  if(freqConversion.Apttus_Config2__ConversionFactor__c != null){
                    uomConversionValueMap.put(freqConversion.APTS_ProductCode__c, freqConversion.Apttus_Config2__ConversionFactor__c);
                  }
          }
        }
           system.debug('salesCatalogIDSet '+salesCatalogIDSet.size()+' catselected '+catselected);
           if(salesCatalogIDSet != null){ 
                productCategoryMap = getCategoriesforProducts(salesCatalogIDSet,catselected);
            }
            System.debug('**productCategoryMap'+productCategoryMap.size());
            System.debug('**productCategoryMap'+productCategoryMap);
            comparepriceList.clear();
            if(!customerpricelistItemList.isEmpty() || !pricelistItemList.isEmpty()){
               for(Apttus_Config2__PriceListItem__c pricelistItem : (!customerpricelistItemList.isEmpty())?customerpricelistItemList : pricelistItemList){
                    String category='';
                    String discount='';
                    decimal netprice=0;
                    decimal netpricewithTax=0;
                    decimal uomListPrice=0;
                    String userSelectedUOM='';
                    decimal formattedListPrice=0;
                    String defaultsellinguom='';
                    //<< v103 - Start
                    String bundleProductName;
                    String bundleProductCode;
                    String optionGroupName;
                    String optionGroupCode;
                    String productName;
                    //>> v103 - End
                    //Added by Hari Selling Term for Rental PLI
                    string sellingterm;

                     if(pricelistItem.Apttus_Config2__ProductId__r.APTS_Material_Type__c != 'ZCMA' && 
                                  priceListItem.Apttus_Config2__ProductId__r.APTS_Option_Group_Indicator__c != '00') {
                        //Used to get categories for list of price list items                   
                        if(pricelistItem.Apttus_Config2__ProductId__c!=null && pricelistItem.Apttus_Config2__ProductId__r.IsActive==true && pricelistItem.Apttus_Config2__Active__c==true){
                            if(!productCategoryMap.isEmpty() &&  productCategoryMap.get(pricelistItem.Apttus_Config2__ProductId__r.APTS_Sales_Catalog__c)!=null ){                            
                                    category = productCategoryMap.get(pricelistItem.Apttus_Config2__ProductId__r.APTS_Sales_Catalog__c); 
                                    //<< v103 - Start   
                                   optionGroupCode = pricelistItem.Apttus_Config2__ProductCode__c;   
                                   productName = pricelistItem.Apttus_Config2__ProductId__r.Name;    
                                   //>> v103 - Start                              
                            }
                            //<< v101 - Start
                            else if(priceListwithComponentProductMap.containsKey(priceListItem.Id)){
                                   category = productCategoryMap.get(optionGroupBundleProductCodeMap.get(priceListwithComponentProductMap.get(priceListItem.Id)));
                                   //<< v103 - Start
                                   bundleProductName = optionGroupBundleProductNameMap.get(priceListwithComponentProductMap.get(priceListItem.Id));
                                   bundleProductCode = componentParentProductMap.get(priceListwithComponentProductMap.get(priceListItem.Id));
                                   optionGroupCode = pricelistItem.Apttus_Config2__ProductCode__c;
                                   optionGroupName = pricelistItem.Apttus_Config2__ProductId__r.APTS_Option_Family__c;
                                   productName = pricelistItem.Apttus_Config2__ProductId__r.Name;
                                   //>> v103 - Start 
                                   System.debug('**category'+category+'**bundleProductName'+bundleProductName);
                                   System.debug('**category code'+componentParentProductMap.get(priceListwithComponentProductMap.get(priceListItem.Id)));
                            }
                            //>> v101 - End
                            if(category==null){
                                category = APTS_CPQConstants.NO_CATEGORY;
                            }
                            if(!plidiscMap.isEmpty()){
                                discount = plidiscMap.get(pricelistItem.Id);
                            }
                            if(!plinetpriceMap.isEmpty()){
                                netprice = plinetpriceMap.get(pricelistItem.Id);
                            }
                            if(!plinetpricetaxMap.isEmpty()){
                                netpricewithTax = plinetpricetaxMap.get(pricelistItem.Id);
                            }
                            // Added by Hari
                            if(plimatrixentryMap.get(pricelistItem.Id) != null){
                                sellingterm = 0+' - '+plimatrixentryMap.get(pricelistItem.Id);
                            }
                            if(pricelistItem.APTS_Default_Selling_Uom__c==null||pricelistItem.APTS_Default_Selling_Uom__c==''){defaultsellinguom=APTS_CPQConstants.LABEL_PIECE;}
                            if(pricelistItem.APTS_Default_Selling_Uom__c!=null && !UOMMap.isEmpty() && UOMMap.get(pricelistItem.APTS_Default_Selling_Uom__c)!=null){defaultsellinguom=UOMMap.get(pricelistItem.APTS_Default_Selling_Uom__c);}
                            if(pricelistItem.Apttus_Config2__ListPrice__c==null){formattedlistprice=0;}else{formattedlistprice=pricelistItem.Apttus_Config2__ListPrice__c;}

                            // v100 - Start
                          //if(APTS_CalculateTaxesCtrl.getConversionRate(uomConversionMap,APTS_CPQConstants.PIECE_UOM_API,userUOMPdf,pricelistItem.Apttus_Config2__ProductCode__c)!=null && APTS_CalculateTaxesCtrl.getConversionRate(uomConversionMap,APTS_CPQConstants.PIECE_UOM_API,userUOMPdf,pricelistItem.Apttus_Config2__ProductCode__c)!=0){
                               //  uomListPrice = (formattedlistprice * APTS_CalculateTaxesCtrl.getConversionRate(uomConversionMap,APTS_CPQConstants.PIECE_UOM_API,userUOMPdf,pricelistItem.Apttus_Config2__ProductCode__c)).setScale(2);
                           if(!uomConversionValueMap.isEmpty() && uomConversionValueMap.containsKey(pricelistItem.Apttus_Config2__ProductCode__c)) {
                                    uomListPrice = (formattedlistprice * uomConversionValueMap.get(pricelistItem.Apttus_Config2__ProductCode__c)).setScale(2);
                             }
                        //   }
                        // v100 - End
                 
                                //get UOM picklist label from picklist API
                                String uomPDF=userUOMPdf; 
                                userSelectedUOM = UOMMap.get(uomPDF);
                            
                            //for no conversions available simply copy list price to UOM based list price.
                            system.debug('before assignment --> ' + uomListPrice);
                            IF(uomListPrice==null || uomListPrice==0){
                                system.debug('Value to be assigned --> ' + formattedlistprice.setScale(2));
                                uomListPrice = formattedlistprice.setScale(2);
                            }
                            System.debug('Category====>'+category+' Sales Catalog==>'+pricelistItem.Apttus_Config2__ProductId__r.APTS_Sales_Catalog__c);
                            if(acctID == null){
                                //Add to the display list | This list is the one which we see on UI 
                                if(String.isNotBlank(category)) {
                                    productpriceList.add(new ListPriceExtractionWrapper(category,pricelistItem,userSelectedUOM,uomListPrice,sellingterm,defaultsellinguom,formattedlistprice, bundleProductCode, bundleProductName, optionGroupCode, optionGroupName, productName));
                                }
                            }

                            if(acctId != null){
                                comparepriceList.add(new compareListPriceExtractionWrapper(category,pricelistItem,discount,netprice,netpricewithTax, bundleProductCode, bundleProductName, optionGroupCode, optionGroupName, productName));
                            }
                        }    
                    }
                }
            }
            system.debug('ProductpriceList ' + productpriceList.size());
            //Sort Wrapper data to improvise user experience.
            productpriceList.sort();
            comparepriceList.sort();
            //Enhance user experience | Align one category with multiple price list items
            for(ListPriceExtractionWrapper formatedListWrapper : productpriceList){
                if(!displayCategoryFormat.contains(formatedListWrapper.category)){
                    displayCategoryFormat.add(formatedListWrapper.category);
                }else{
                    formatedListWrapper.category='';
                }
            }

             //CSP | Enhance user experience | Align one category with multiple price list items
            if(acctId != null){
                for(compareListPriceExtractionWrapper formatedListWrapper : comparepriceList){
                    if(!displayCategoryFormat.contains(formatedListWrapper.category)){
                        displayCategoryFormat.add(formatedListWrapper.category);
                    }else{
                        formatedListWrapper.category='';
                    }
                }
            }
            
        }catch(Exception e){
             //APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'APTS_ListPriceExtractionCtrl', ApexPages.currentPage().getParameters().get('businessObjectId'),'CPQ',false,true,'cpqerror@accenture.com',true);
            //system.debug('Error Message'+e);
            //system.debug('Message'+e.getStackTraceString());
        }
        
    }
    public class ListPriceExtractionWrapper implements Comparable{
        public String category {get;set;}
        public String defaultsellinguom {get;set;}
        public Decimal formattedlistprice {get;set;}
        public String convertedUOM {get;set;}
        public decimal uomBasedListPrice {get;set;}
        public Apttus_Config2__PriceListItem__c pricelistItem {get;set;}
        public string rentsellingterm{get;set;}
        //<< v103 - Start
        public string bundleProductName {get;set;}
        public string bundleProductCode {get;set;}
        public string optionGroupName {get;set;}
        public string optionGroupCode {get;set;}
        public string productName {get;set;}
        //>> v103 - End

        //constructor
        public ListPriceExtractionWrapper(String categoryName,Apttus_Config2__PriceListItem__c pli,String convUOM,Decimal uomBasedLP,string sellingterm,String defaultselling,Decimal formattedlist, String bundleProdCode, String bundleProdName, String optionGrpCode, String optionGrpName, String prodName){
            category = categoryName;
            pricelistItem = pli;
            convertedUOM = convUOM;
            uomBasedListPrice = uomBasedLP;
            rentsellingterm = sellingterm;
            defaultsellinguom = defaultselling;
            formattedlistprice = formattedlist;
            //<< v103 - Start
            bundleProductCode = bundleProdCode;
            bundleProductName = bundleProdName;
            optionGroupCode = optionGrpCode;
            optionGroupName = optionGrpName;
            productName = prodName;
            //<< v103 - Start            
        }
        //method interface 
        public Integer compareTo(Object objToCompare) {
            //Sort by category decending order
            return ((ListPriceExtractionWrapper)objToCompare).category.compareTo(category);
        }
    }
    public class compareListPriceExtractionWrapper implements Comparable{  
        public String category {get;set;}
        public Apttus_Config2__PriceListItem__c pricelistItem {get;set;}
        public string discount {get;set;}
        public decimal contnetprice {get;set;}
        public decimal netpriwithtaxvat {get;set;}
        //<< v103 - Start
        public string bundleProductName {get;set;}
        public string bundleProductCode {get;set;}
        public string optionGroupName {get;set;}
        public string optionGroupCode {get;set;}
        public string productName {get;set;}
        //>> v103 - End

        public compareListPriceExtractionWrapper(String categoryName,Apttus_Config2__PriceListItem__c pli,string disc,decimal contpri,decimal netpritaxvat, String bundleProdCode, String bundleProdName, String optionGrpCode, String optionGrpName, String prodName){
            category = categoryName;
            pricelistItem = pli;
            discount = disc;
            contnetprice = contpri;
            netpriwithtaxvat = netpritaxvat;
             //<< v103 - Start
            bundleProductCode = bundleProdCode;
            bundleProductName = bundleProdName;
            optionGroupCode = optionGrpCode;
            optionGroupName = optionGrpName;
            productName = prodName;
            //<< v103 - Start
        }

        public Integer compareTo(Object objToCompare) {
            //Sort by BookName Alphabetically
            return ((compareListPriceExtractionWrapper)objToCompare).category.compareTo(category);
        }
    }
    public void getQueryStringParams(){
        pricelistID = ApexPages.currentPage().getParameters().get('pliid');        
        acctID = ApexPages.currentPage().getParameters().get('id');
    }
    /* Method name : getCategoriesforProducts
       Description : Method used to get category hierarchy based on offering external IDs on Products*/
    public Map<String,String> getCategoriesforProducts(Set<String> OfferingExternalIds,List<String> catselected){
        Map<String,String> productCategoryMap = new Map<String,String>();
        
        For(Apttus_Config2__ClassificationHierarchy__c category : [select id,APTS_CategoryHierarchyOfferingExtId__c,name,Apttus_Config2__HierarchyId__r.name from Apttus_Config2__ClassificationHierarchy__c where APTS_CategoryHierarchyOfferingExtId__c IN: OfferingExternalIds and Apttus_Config2__HierarchyId__r.Apttus_Config2__Active__c=true limit 5000]){
            if(catselected!=null && catselected.contains(category.Apttus_Config2__HierarchyId__r.name)){
                if(category.APTS_CategoryHierarchyOfferingExtId__c != null){
                if(productCategoryMap.get(category.APTS_CategoryHierarchyOfferingExtId__c)==null){
                    //Map of Product Offering ID and category hierarchy
                    String formattedString='';
                    for(String subCategory : category.name.split('\\|')){
                        formattedString += subCategory + APTS_CPQConstants.PIPE_SIGN;
                    }
                    formattedString = formattedString.removeEnd(APTS_CPQConstants.PIPE_SIGN); 
                    productCategoryMap.put(category.APTS_CategoryHierarchyOfferingExtId__c,category.Apttus_Config2__HierarchyId__r.name+APTS_CPQConstants.PIPE_SIGN+formattedString);
                }
            }
            if(catselected==null && acctID!=null){
                if(productCategoryMap.get(category.APTS_CategoryHierarchyOfferingExtId__c)==null){
                    //Map of Product Offering ID and category hierarchy
                    String formattedString='';
                    for(String subCategory : category.name.split('\\|')){
                        formattedString += subCategory + APTS_CPQConstants.PIPE_SIGN;
                    }
                    formattedString = formattedString.removeEnd(APTS_CPQConstants.PIPE_SIGN); 
                    productCategoryMap.put(category.APTS_CategoryHierarchyOfferingExtId__c,category.Apttus_Config2__HierarchyId__r.name+APTS_CPQConstants.PIPE_SIGN+formattedString);
                }
            }
        }
    }
        
        return productCategoryMap;
    }
}