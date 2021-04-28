/*
 * This class is used to display List price extraction + CSP page.
 * Created By - Karan Khatri
 * Created Date - 17th May, 2018
 * Modified History
 *  // v100 - Defect 21155 - Updated the query filter
 *  // v101 - Defect  22520 - Handling high volume data
 *  // v102 - Defect 22913 - Logic added to extract Prices For ZOPT Machines and Concepts
 *  // v103 - Defect 4283 - 1. Code fix for not to display irrevalent Materials. 
                            2. Code fix to clear all previous search results.
 *                           
*/

public without sharing class APTS_ListPriceExtractionCtrl {
   
    public String selectedCatgs {get;set;}
    //<< v103 - Start
    public boolean displayBundleProduct { get; set; }
    //>> v103 - End
    public boolean groupByCategory { get; set; }
    public boolean errorMessage { get; set; }
    public boolean includeVat { get; set; }
    public boolean includeTax { get; set; }
    public String userDefinedUOM { get; set; }
    public boolean highVolumeData { get; set; }
    public List<compareListPriceExtractionWrapper> comparepriceList;
    public List<compareListPriceExtractionWrapper> requestedAccountpriceListItems{get;set;}
    public List<ListPriceExtractionWrapper> productpriceList;
    public List<ListPriceExtractionWrapper> requestedPriceListItems{get;set;}
    public ID pricelistID;
    public ID acctID;
    public Map<String,String> UOMMap = new  Map<String,String>();
    public integer startIndex;
    public final integer LIMIT_SIZE=Integer.valueof(System.label.APTS_List_Price_Extraction_Page_Size);

    public List<string> selectedCatgsValues{get;set;}
    //<< v103 - Start
    public static Map<String, String> productFamilyMap = new Map<String, String>{'Coffee' => 'SAP_01', 
                                                                                'Tea' => 'SAP_02',     
                                                                                '&More' => 'SAP_03',       
                                                                                'Machines' => 'SAP_04',        
                                                                                'Services' => 'SAP_05',        
                                                                                'Spare Parts' => 'SAP_06',     
                                                                                'Concepts' =>  'SAP_07',       
                                                                                'Consumption Categories' => 'SAP_08'};
    //>> v103 - End
  
    //constructor - data initilialization
    public APTS_ListPriceExtractionCtrl(){
        productpriceList = new List<ListPriceExtractionWrapper>();
        comparepriceList = new List<compareListPriceExtractionWrapper>();
        requestedAccountpriceListItems = new List<compareListPriceExtractionWrapper>();
        requestedPriceListItems = new List<ListPriceExtractionWrapper>();
        groupByCategory = true;
      //Added by saranya PI ISSUE 190431	
        errorMessage=false;	
       // pricelistID = ApexPages.currentPage().getParameters().get('pliid');   	
        if(ApexPages.currentPage().getParameters().get('pliid')==null || ApexPages.currentPage().getParameters().get('pliid')=='')	
     {	
     errorMessage=True;	

            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Account does not have Customer specific price list  !');	
            ApexPages.addMessage(myMsg);	
        }
    } 

    /* Method name : loadProductsList
       Description : Method used to Load products on List Price extraction wizard page and PDF page*/
    public void loadProductsList(){
       
        //initialize
        startIndex=0;   
        displayBundleProduct = false;     
        //<< v102 - Start
        Set<String> prefixCodeMachineConcept = new Set<String> {'04', '07'};
        //>> v102 - End

        //<< v103 - Start
        Set<String> categoryMachineConcept = new Set<String> {'Machines', 'Concepts'};
        //>> v103 - End

        Apttus_Config2__PriceList__c priceListDetails = new Apttus_Config2__PriceList__c();
        
        Set<String> displayCategoryFormat = new  Set<String>();
        Set<String> salesCatalogIDSet = new Set<String>();
        Set<String> productCodeSet = new Set<String>();  
        Set<ID> pliIds = new Set<ID>();
        Set<ID> pliCERSet = new Set<ID>();        
        //<< v102 - Start
        Set<ID> optGroupIndiProductIds = new Set<ID>();       
        //>> v102 - End
        List<string> catselected = new List<string>();
        //<< v103 - Start
        List<string> productFamilyCode = new List<string>();
        //>> v103 - End
        productpriceList = new List<ListPriceExtractionWrapper>();
        comparepriceList = new List<compareListPriceExtractionWrapper>();
        List<APTS_Contract_Entitlement_Repository__c>cerList = new List<APTS_Contract_Entitlement_Repository__c>();              
        List<Apttus_Config2__PriceListItem__c> pricelistItemList = new List<Apttus_Config2__PriceListItem__c>();
        List<Apttus_Config2__PriceMatrix__c> pricematList = new List<Apttus_Config2__PriceMatrix__c>();
        List<Apttus_Config2__PriceListItem__c> customerpricelistItemList = new List<Apttus_Config2__PriceListItem__c>();
       //customerpricelistItemList = new List<Apttus_Config2__PriceListItem__c>();
        
        //<< v102 - Start
        Map<Id, String> componentParentProductMap = new Map<Id, String>();
        Map<Id, Id> priceListwithComponentProductMap = new Map<Id, Id>();
        //>> v102 - End
        //<< v103 - Start
        Map<Id, String> optionGroupBundleProductCodeMap = new Map<Id, String>();
        Map<Id, String> optionGroupBundleProductNameMap = new Map<Id, String>();
        //>> v103 - End
        Map<Id,String> plimatrixentryMap = new Map<Id,String>();
        Map<Id,String> plidiscMap = new Map<Id,String>();
        Map<Id,decimal> plinetpriceMap = new Map<Id,decimal>();
        Map<Id,decimal> plinetpricetaxMap = new Map<Id,decimal>();         
        Map<Id,List<Apttus_Config2__PriceMatrix__c>> plimatrixMap = new Map<Id,List<Apttus_Config2__PriceMatrix__c>>();
        Map<String,String> productCategoryMap = new  Map<String,String>();
        Map<ID,Apttus_Config2__FrequencyConversionRate__c> uomConversionMap= new Map<ID,Apttus_Config2__FrequencyConversionRate__c>();
        Map<Id,List<APTS_Contract_Entitlement_Repository__c>> pliCERmap = new Map<Id,List<APTS_Contract_Entitlement_Repository__c>>();
        Map<String,Decimal> uomConversionValueMap = new Map<String,Decimal>();
        Map<Id,Apttus_Config2__PriceListItem__c> pricelistItemMap = new Map<Id,Apttus_Config2__PriceListItem__c>();

        
        try{
            
            getQueryStringParams();
            //<< v103 - Start
            requestedAccountpriceListItems.clear();
            requestedPriceListItems.clear();
            comparepriceList.clear();
            productpriceList.clear();

            if(selectedCatgs != null){
                catselected = selectedCatgs.split(',');

                for(string categories : catselected){
                    productFamilyCode.add(productFamilyMap.get(categories));
                    if(categoryMachineConcept.contains(categories)){ displayBundleProduct = true; }
                }
            }
            //>> v103 - Start

            if(pricelistID != null){

                //<< v100, v103 - Start
                //List of price list items - used for display list of products with details
                pricelistItemList = [SELECT Id,Apttus_Config2__ProductCode__c,APTS_Default_Selling_Uom__c,APTS_VAT_percentage__c,Apttus_Config2__ChargeType__c,
                                            Apttus_Config2__ProductId__r.APTS_Sales_Catalog__c,Apttus_Config2__ProductId__r.IsActive,Apttus_Config2__Active__c,
                                            Apttus_Config2__ProductId__r.name, Apttus_Config2__ProductId__c,Apttus_Config2__PriceUom__c,APTS_Tax_per_UOM__c,
                                            Apttus_Config2__Description__c,Apttus_Config2__ListPrice__c,Apttus_Config2__PriceListId__r.Apttus_Config2__AccountId__c, 
                                            CurrencyIsoCode, Apttus_Config2__ProductId__r.APTS_Material_Type__c, Apttus_Config2__ProductId__r.APTS_Option_Group_Indicator__c,
                                            toLabel(Apttus_Config2__ProductId__r.APTS_Option_Family__c)
                                     FROM Apttus_Config2__PriceListItem__c 
                                     WHERE Apttus_Config2__PriceListId__c =: pricelistID AND 
                                           Apttus_Config2__PriceListId__r.Apttus_Config2__Active__c = true AND 
                                           Apttus_Config2__Active__c = true AND 
                                           Apttus_Config2__ProductId__r.Family IN : productFamilyCode AND
                                           Apttus_Config2__ProductId__r.IsActive = true  
                                     ORDER BY Apttus_Config2__ProductId__c LIMIT 1800];
                //<< v102 - Start                     
                for(Apttus_Config2__PriceListItem__c pli : pricelistItemList) {
                    if(pli.Apttus_Config2__ProductId__c != null && String.isNotBlank(pli.Apttus_Config2__ProductId__r.APTS_Sales_Catalog__c)){
                        if(prefixCodeMachineConcept.contains(String.valueOf(pli.Apttus_Config2__ProductId__r.APTS_Sales_Catalog__c).subString(0,2))){
                            optGroupIndiProductIds.add(pli.Apttus_Config2__ProductId__c);
                          }
                         system.debug(pli.Apttus_Config2__ProductId__r.APTS_Sales_Catalog__c);
                  }
                }

                if(!optGroupIndiProductIds.isEmpty()){                    
                    for(Apttus_Config2__ProductOptionComponent__c poc :[Select id, Apttus_Config2__ParentProductId__r.ProductCode, 
                                                                                Apttus_Config2__ComponentProductId__c,
                                                                                Apttus_Config2__ComponentProductId__r.ProductCode,
                                                                                Apttus_Config2__ParentProductId__r.Name,
                                                                                Apttus_Config2__ParentProductId__r.APTS_Sales_Catalog__c
                                                                        from Apttus_Config2__ProductOptionComponent__c 
                                                                        where Apttus_Config2__ParentProductId__c IN: optGroupIndiProductIds and 
                                                                             Apttus_Config2__ComponentProductId__r.APTS_Option_Group_Indicator__c != '' and 
                                                                             Apttus_Config2__ComponentProductId__r.APTS_Option_Group_Indicator__c != '00' and
                                                                             Apttus_Config2__ComponentProductId__r.APTS_Material_Type__c = 'ZOPT']){
                        componentParentProductMap.put(poc.Apttus_Config2__ComponentProductId__c, poc.Apttus_Config2__ParentProductId__r.ProductCode);
                        //<< v102 - Start 
                        optionGroupBundleProductCodeMap.put(poc.Apttus_Config2__ComponentProductId__c, poc.Apttus_Config2__ParentProductId__r.APTS_Sales_Catalog__c);
                        optionGroupBundleProductNameMap.put(poc.Apttus_Config2__ComponentProductId__c, poc.Apttus_Config2__ParentProductId__r.Name);
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
                                                                           Apttus_Config2__ProductId__r.IsActive = true ]){
                        pricelistItemList.add(prLiIT);
                        priceListwithComponentProductMap.put(prLIIT.Id, prLIIT.Apttus_Config2__ProductId__c);

                        if(highVolumeData && pricelistItemList.size() > 1800){
                            highVolumeData = false;
                            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,'Search result returns high volume data. On screen user can view 1800 records at Max . Please click on "Export as CSV" button to extract complete result as an attachments');
                            ApexPages.addMessage(myMsg);
                        }
                    }
                }
                
                // >> v102 -End
                // >> v100, v103 -End
                for(Apttus_Config2__PriceListItem__c pli : pricelistItemList) {
                   if(String.isNotBlank(pli.Apttus_Config2__ChargeType__c)  && pli.Apttus_Config2__ChargeType__c.contains('Rental') ){
                      pliids.add(pli.id);    
                    }
                  if(pli.Apttus_Config2__ProductId__r != null && pli.Apttus_Config2__ProductId__r.APTS_Sales_Catalog__c != null){                                    
                      salesCatalogIDSet.add(pli.Apttus_Config2__ProductId__r.APTS_Sales_Catalog__c);
                      productCodeSet.add(pli.Apttus_Config2__ProductCode__c);
                      pliIds.add(pli.Id);
                    }
                    pricelistItemMap.put(pli.Id, pli);
                    
                }
             
                
             
                for(Apttus_Config2__PriceMatrix__c primat : [Select Id,Name,Apttus_Config2__PriceListItemId__c,Apttus_Config2__Dimension1Id__c,Apttus_Config2__Dimension2Id__c,
                                                                    Apttus_Config2__Dimension3Id__c,Apttus_Config2__Dimension4Id__c,Apttus_Config2__Dimension5Id__c,
                                                                    (SELECT Id,Name,Apttus_Config2__Dimension1Value__c,Apttus_Config2__AdjustmentAmount__c FROM Apttus_Config2__MatrixEntries__r order by Apttus_Config2__Dimension1Value__c asc),
                                                                    Apttus_Config2__Dimension6Id__c 
                                                              FROM Apttus_Config2__PriceMatrix__c 
                                                              WHERE (Apttus_Config2__PriceListItemId__c IN: pliids) AND 
                                                                    (Apttus_Config2__Dimension1Id__r.Name = 'Selling Term' OR 
                                                                     Apttus_Config2__Dimension2Id__r.Name = 'Selling Term' OR 
                                                                     Apttus_Config2__Dimension3Id__r.Name = 'Selling Term' OR  
                                                                     Apttus_Config2__Dimension4Id__r.Name = 'Selling Term' OR 
                                                                     Apttus_Config2__Dimension5Id__r.Name = 'Selling Term' OR  
                                                                     Apttus_Config2__Dimension6Id__r.Name = 'Selling Term')]){
                     
                      List<Apttus_Config2__PriceMatrixEntry__c> plmatent = primat.Apttus_Config2__MatrixEntries__r;
                      Apttus_Config2__PriceMatrixEntry__c plmatentry = plmatent[0];                   
                       
                      plimatrixentryMap.put(primat.Apttus_Config2__PriceListItemId__c,plmatentry.Apttus_Config2__Dimension1Value__c);                
                  }
               
            }
           if(acctID != null){
                cerList = APTS_CERUtility.getContractedProductsWithDiscounts(acctId);
                cerList.sort();
            }
        
            
            if(!cerList.isEmpty()){
                for(APTS_Contract_Entitlement_Repository__c cer : cerList){
                     pliCERSet.add(cer.APTS_Agreement_Adjustment_Line_Item__r.Apttus_CMConfig__LineItemId__r.Apttus_CMConfig__PriceListItemId__c);
       
                     if(cer.APTS_Agreement_Line_Item__r.Apttus__NetPrice__c != null){                
                      plinetpriceMap.put(cer.APTS_Agreement_Adjustment_Line_Item__r.Apttus_CMConfig__LineItemId__r.Apttus_CMConfig__PriceListItemId__c, cer.APTS_Agreement_Line_Item__r.Apttus__NetPrice__c);
                 
                     }
                     if(cer.APTS_Agreement_Line_Item__r.APTS_Net_Price_Inc_taxes__c != null){
                      plinetpricetaxMap.put(cer.APTS_Agreement_Adjustment_Line_Item__r.Apttus_CMConfig__LineItemId__r.Apttus_CMConfig__PriceListItemId__c, cer.APTS_Agreement_Line_Item__r.APTS_Net_Price_Inc_taxes__c);
                 
                     }    

                    if(cer.APTS_Type__c != null && cer.APTS_Adjustment_Value__c != null){                        
                       String typevalue = cer.APTS_Type__c+'  '+cer.APTS_Adjustment_Value__c ;
                        if(plidiscMap.containsKey(cer.APTS_Agreement_Adjustment_Line_Item__r.Apttus_CMConfig__LineItemId__r.Apttus_CMConfig__PriceListItemId__c)) {                       
                          String disctype = plidiscMap.get(cer.APTS_Agreement_Adjustment_Line_Item__r.Apttus_CMConfig__LineItemId__r.Apttus_CMConfig__PriceListItemId__c);                        
                          disctype += ' '+typevalue;
                          plidiscMap.put(cer.APTS_Agreement_Adjustment_Line_Item__r.Apttus_CMConfig__LineItemId__r.Apttus_CMConfig__PriceListItemId__c,disctype); 

                        } else { plidiscMap.put(cer.APTS_Agreement_Adjustment_Line_Item__r.Apttus_CMConfig__LineItemId__r.Apttus_CMConfig__PriceListItemId__c,typevalue); }
                    } 
                   
                } 
            }       
          
            if(!pliCERSet.isEmpty()){
                for(Id pliSetId : pliCERSet){
                  if(pricelistItemMap.containsKey(pliSetId) && 
                      pricelistItemMap.get(pliSetId).Apttus_Config2__PriceListId__r.Apttus_Config2__AccountId__c != null && 
                      acctID != null && 
                      pricelistItemMap.get(pliSetId).Apttus_Config2__PriceListId__r.Apttus_Config2__AccountId__c == acctID){
                      customerpricelistItemList.add(pricelistItemMap.get(pliSetId));
                   
                   }
                }
            }
            //get all UOM conversion rates
            if(!productCodeSet.isEmpty() && userDefinedUOM!=null){
                for( Apttus_Config2__FrequencyConversionRate__c freqConversion : [SELECT id,Apttus_Config2__FromUom__c,Apttus_Config2__ToUom__c,
                                                                                         Apttus_Config2__ProductFamily__c,Apttus_Config2__ConversionFactor__c,
                                                                                         Apttus_Config2__ProductId__c,APTS_ProductCode__c 
                                                                                  FROM Apttus_Config2__FrequencyConversionRate__c 
                                                                                  WHERE Apttus_Config2__ToUom__c =: userDefinedUOM AND 
                                                                                        Apttus_Config2__FromUom__c =: APTS_CPQConstants.PIECE_UOM_API AND 
                                                                                        APTS_ProductCode__c IN: productCodeSet LIMIT 25000]){
                   

                  if(freqConversion.Apttus_Config2__ConversionFactor__c != null){
                    uomConversionValueMap.put(freqConversion.APTS_ProductCode__c, freqConversion.Apttus_Config2__ConversionFactor__c);
                  }
                }
            }
                     
           if(salesCatalogIDSet != null){ 
                productCategoryMap = getCategoriesforProducts(salesCatalogIDSet,catselected);
            }
            
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
                    String productCode;
                    //>> v103 - End
                    //Added by Hari Selling Term for Rental PLI
                    string sellingterm;
                    //Used to get categories for list of price list items                   
                    if(pricelistItem.Apttus_Config2__ProductId__c!=null && pricelistItem.Apttus_Config2__ProductId__r.IsActive==true && pricelistItem.Apttus_Config2__Active__c==true){
                        if(pricelistItem.Apttus_Config2__ProductId__r.APTS_Material_Type__c != 'ZCMA' && 
                                  priceListItem.Apttus_Config2__ProductId__r.APTS_Option_Group_Indicator__c != '00') {
                            if(!productCategoryMap.isEmpty() &&  productCategoryMap.get(pricelistItem.Apttus_Config2__ProductId__r.APTS_Sales_Catalog__c)!=null ){                            
                                   category = productCategoryMap.get(pricelistItem.Apttus_Config2__ProductId__r.APTS_Sales_Catalog__c);
                                   //<< v103 - Start                                   
                                    optionGroupCode = pricelistItem.Apttus_Config2__ProductCode__c;  
                                    productName = pricelistItem.Apttus_Config2__ProductId__r.Name;                                                            
                                   //>> v103 - Start                  
                            }
                            //<< v102 - Start
                            else if(priceListwithComponentProductMap.containsKey(priceListItem.Id)){
                                   category = productCategoryMap.get(optionGroupBundleProductCodeMap.get(priceListwithComponentProductMap.get(priceListItem.Id))); 
                                   //<< v103 - Start                                
                                   bundleProductName = optionGroupBundleProductNameMap.get(priceListwithComponentProductMap.get(priceListItem.Id));
                                   bundleProductCode = componentParentProductMap.get(priceListwithComponentProductMap.get(priceListItem.Id));
                                   optionGroupCode = pricelistItem.Apttus_Config2__ProductCode__c;
                                   optionGroupName = pricelistItem.Apttus_Config2__ProductId__r.APTS_Option_Family__c;
                                   productName = pricelistItem.Apttus_Config2__ProductId__r.Name;
                                   //>> v103 - Start
                            }
                            //>> v102 - End
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
                            
                            // << v100 -Start
                            //get UOM conversion first and then get updated list price = original list price  X  conversion rate
                            //if(APTS_CalculateTaxesCtrl.getConversionRate(uomConversionMap,APTS_CPQConstants.PIECE_UOM_API,userDefinedUOM,pricelistItem.Apttus_Config2__ProductCode__c)!=null && APTS_CalculateTaxesCtrl.getConversionRate(uomConversionMap,APTS_CPQConstants.PIECE_UOM_API,userDefinedUOM,pricelistItem.Apttus_Config2__ProductCode__c)!=0){
                                //uomListPrice = (formattedlistprice * APTS_CalculateTaxesCtrl.getConversionRate(uomConversionMap,APTS_CPQConstants.PIECE_UOM_API,userDefinedUOM,pricelistItem.Apttus_Config2__ProductCode__c)).setScale(2);
                                if(!uomConversionValueMap.isEmpty() && uomConversionValueMap.containsKey(pricelistItem.Apttus_Config2__ProductCode__c)) {
                                    uomListPrice = (formattedlistprice * uomConversionValueMap.get(pricelistItem.Apttus_Config2__ProductCode__c)).setScale(2);
                                }
                              // system.debug('uomListPrice ==>'+uomConversionValueMap.size());
                            //}
                            // >> v100 -End
                            
                            //get UOM picklist label from picklist API 
                            userSelectedUOM = UOMMap.get(userDefinedUOM);

                            //for no conversions available simply copy list price to UOM based list price.
                            IF(uomListPrice==null || uomListPrice==0){
                                uomListPrice = formattedlistprice.setScale(2);
                            }
                            if(acctID == null){
                                //System.debug('Category====>'+category+' Sales Catalog==>'+pricelistItem.Apttus_Config2__ProductId__r.APTS_Sales_Catalog__c);
                                //Add to the display list | This list is the one which we see on UI 
                                if(String.isNotBlank(Category)) {
                                    productpriceList.add(new ListPriceExtractionWrapper(category,pricelistItem,userSelectedUOM,uomListPrice,sellingterm,defaultsellinguom,formattedlistprice, bundleProductCode, bundleProductName, optionGroupCode, optionGroupName, productName));
                                }
                            }

                            if(acctId != null){
                                comparepriceList.add(new compareListPriceExtractionWrapper(category,pricelistItem,discount,netprice,netpricewithTax,defaultsellinguom,formattedlistprice, bundleProductCode, bundleProductName, optionGroupCode, optionGroupName, productName));
                            }
                        }
                    }
                }
            }
            
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
           
            if(!productpriceList.isEmpty()){
                For(integer i=startIndex; i<LIMIT_SIZE ; i++){
                    if((productpriceList.size() - 1) >= i){
                        requestedPriceListItems.add(productpriceList[i]);
                    }
                }
            }
            if(!comparepriceList.isEmpty()){
                 For(integer i=startIndex; i<LIMIT_SIZE ; i++){
                    if((comparepriceList.size() - 1) >= i){
                        requestedAccountpriceListItems.add(comparepriceList[i]);
                    }
                }
            }
          
        }catch(Exception e){
             APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'APTS_ListPriceExtractionCtrl', ApexPages.currentPage().getParameters().get('businessObjectId'),'CPQ',false,true,'cpqerror@accenture.com',true);
            //system.debug('Error Message'+e);
            //system.debug('Message'+e.getMessage());
        }
        
    }
  
  //Added by saranya PI ISSUE 190431	
 public PageReference backtoAccount() {	
        PageReference cancelPage;	
       String acccID = ApexPages.currentPage().getParameters().get('id');	


             cancelPage =  new PageReference('/'+acccId);	
            cancelPage.setRedirect(true);	

         return cancelPage;       	
    }	
    
    public void holdsSelectedCategory(List<String> selectedVal){
        
        selectedCatgsValues = selectedVal.isEmpty()?new list<String>():selectedVal;
        
    }
    /* Method name : viewListOfPriceListItems
       Description : Method used to traverse to view list of products on VF page*/
    public PageReference viewListOfPriceListItems() {
       
        if(String.isNotBlank(selectedCatgs)){
            string redirectpage;
            getQueryStringParams();
         
            if(acctID != null){
                return Page.APTS_CustomerListPriceExtraction;
            }
            if(acctID == null){
               return Page.APTS_ListPriceExtractionProductsPage;
            } 
        }else{
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Please select atleast one category to proceed !');
            ApexPages.addMessage(myMsg);
        }    
        return null;   
    }

    /* Method name : previousActionPage
       Description : Method used to traverse back to Option selection page*/
    public PageReference previousActionPage() { 
        return Page.APTS_ListPriceExtractionSelectPage;
    }

    public PageReference cancelPage() {
    // Modified by Hari to move List Price button to Account
        //PageReference cancelPage =  new PageReference('/'+pricelistID);
        PageReference cancelPage;
        getQueryStringParams();
        if(acctId!=null){
            cancelPage =  new PageReference('/'+acctId);
            cancelPage.setRedirect(true);
        }else{
            cancelPage =  new PageReference('/'+pricelistID);
            cancelPage.setRedirect(true);
        }
        return cancelPage;       
    }

    /* Method name : downloadAsPDF
       Description : Method used to traverse to PDF page*/
    public void downloadAsPDF() {
        //PageReference pageRef;
        try{
            PageReference pdfPage;
            String parentId, pageMsg;            
            String selectedCategories = EncodingUtil.urlEncode(selectedCatgs, 'UTF-8');
            
            
            if(acctId != null){
              pdfPage = Page.APTS_CustomerListPriceExtractionPDF;
              pdfPage.getParameters().put('Id',acctId);
              parentId = acctId;
              pageMsg = 'PDF has been downloaded and added as an Attachment on your requested account ,<b><a href="/'+acctId+'">Click here to go to Account</a></b>';
            } else {
              pdfPage = Page.APTS_ListPriceExtractionPDFPage;
              parentId = pricelistID;
              pageMsg = 'PDF has been downloaded and added as an Attachment on your requested Pricelist ,<b><a href="/'+pricelistID+'">Click here to go to pricelist</a></b>';
            }
            pdfPage.getParameters().put('pliid',pricelistID);
            pdfPage.getParameters().put('groupByCategory',String.valueOf(GroupByCategory));
            pdfPage.getParameters().put('includeVat',String.valueOf(includeVat));
            pdfPage.getParameters().put('includeTax',String.valueOf(includeTax));
            pdfPage.getParameters().put('userUOM',userDefinedUOM);
            pdfPage.getParameters().put('selectedCatgsXLS',selectedCategories);
            pdfPage.getParameters().put('isExportAsXls','fasle');
            

            Blob pdfBlob;
            if(Test.isRunningTest()) { 
              pdfBlob = blob.valueOf('Unit.Test');
            } else {
              pdfBlob = pdfPage.getContentAsPDF();
            }
            Attachment attach = new Attachment(parentId = parentId, Name ='List Price Extraction - '+ System.Now().format() + '.pdf', body = pdfBlob); //create the attachment object
            insert attach; 
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM, pageMsg);
            ApexPages.addMessage(myMsg);
            
         }catch(Exception e){
             APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'APTS_ListPriceExtractionCtrl', ApexPages.currentPage().getParameters().get('businessObjectId'),'CPQ',false,true,'cpqerror@accenture.com',true);
             //system.debug('Error Message'+e);
            //system.debug('Message'+e.getMessage());
        }
        
    }

    public void exportAsExcel() {
        
        try{
            PageReference xlsPage;
            String parentId, pageMsg;            
            String selectedCategories = EncodingUtil.urlEncode(selectedCatgs, 'UTF-8');
                         
            if(acctId != null){
              xlsPage = Page.APTS_CustomerListPriceExtractionExcel;
              xlsPage.getParameters().put('Id',acctId);
              parentId = acctId;
              pageMsg = 'Excel Sheet has been downloaded and added as an Attachment on your requested account ,<b><a href="/'+acctId+'">Click here to go to Account</a></b>';
            } else {
              xlsPage = Page.APTS_ListPriceExtractionExcelPage;
              parentId = pricelistID;
              pageMsg = 'Excel Sheet has been downloaded and added as an Attachment on your requested Pricelist ,<b><a href="/'+pricelistID+'">Click here to go to pricelist</a></b>';
            }
            xlsPage.getParameters().put('pliid',pricelistID);
            xlsPage.getParameters().put('groupByCategory',String.valueOf(GroupByCategory));
            xlsPage.getParameters().put('includeVat',String.valueOf(includeVat));
            xlsPage.getParameters().put('includeTax',String.valueOf(includeTax));
            xlsPage.getParameters().put('userUOM',userDefinedUOM);
            xlsPage.getParameters().put('selectedCatgsXLS',selectedCategories);
            xlsPage.getParameters().put('isExportAsXls','true');
            
            
            Blob xlsBlob ;
            if(Test.isRunningTest()) { 
              xlsBlob = blob.valueOf('Unit.Test');
            } else {
              xlsBlob = xlsPage.getContent();
            }
            Attachment attach = new Attachment(parentId = parentId, Name = 'List Price Extraction - '+ System.Now().format() + '.xls', body = xlsBlob); //create the attachment object
            insert attach; 

            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM, pageMsg);
            ApexPages.addMessage(myMsg);

            
        }catch(Exception e){
             APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'APTS_ListPriceExtractionCtrl', ApexPages.currentPage().getParameters().get('businessObjectId'),'CPQ',false,true,'cpqerror@accenture.com',true);
             //system.debug('Error Message'+e);
            //system.debug('Message'+e.getMessage());
        }
    }

    //<< v101 - Start
    /* Method name : exportAsCSV
       Description : Method used to download and attach the search result data as CSV file*/
     public void exportAsCSV() {
        PageReference pageRef;
        try{
            
                String  pageMsg;
                String selectedCategories = EncodingUtil.urlEncode(selectedCatgs, 'UTF-8');
                
                APTS_ListPriceExtractionCSV.initializeCSVCall(selectedCategories, String.valueOf(includeVat), String.valueOf(includeTax), userDefinedUOM, 'false', true, pricelistID, acctId);
       
                
                if(String.isNotBlank(acctId) ){
                  pageMsg = 'CSV Sheets has been downloaded and added as an Attachments on your requested account ,<b><a href="/'+acctId+'">Click here to go to Account</a></b>';
            
                } else if(String.isNotBlank(pricelistID)){
                  pageMsg = 'CSV Sheets has been downloaded and added as an Attachments on your requested Pricelist ,<b><a href="/'+pricelistID+'">Click here to go to pricelist</a></b>';
                }
            
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM, pageMsg);
                ApexPages.addMessage(myMsg);
            
        }catch(Exception e){
             APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'APTS_ListPriceExtractionCtrl', ApexPages.currentPage().getParameters().get('businessObjectId'),'CPQ',false,true,'cpqerror@accenture.com',true);
            //system.debug('Error Message'+e);
            //system.debug('Message'+e.getMessage());
        }
    }
     //>> v101 - End

    /* Method name : previousActionPage
       Description : Method used to traverse back to Option selection page*/

    public List<SelectOption> getuomValues() {
        List<SelectOption> options = new List<SelectOption>();
        for( Schema.PicklistEntry v : Apttus_Config2__FrequencyConversionRate__c.Apttus_Config2__ToUom__c.getDescribe().getPicklistValues()) {
            UOMMap.put(v.getValue(),v.getLabel());
            options.add(new SelectOption(v.getValue(),v.getLabel()));
        }
        return options;
    }
    //Added by Hari for CR on categories selection
    public static String getAllPicklistValues(){
        List<String> productPickListValue = new List<String>();
        for(Apttus_Config2__ClassificationName__c cat : [Select Name From Apttus_Config2__ClassificationName__c where Apttus_Config2__Type__c IN ('Offering','Both')]){
              productPickListValue.add(cat.Name);
        }
        return JSON.serialize(productPickListValue);
    }
    
    public Map<Id,APTS_Contract_Entitlement_Repository__c> getcerforplis(Set<Id> pliids){
        Map<Id,APTS_Contract_Entitlement_Repository__c> pliCERmap = new Map<Id,APTS_Contract_Entitlement_Repository__c>();
        for(APTS_Contract_Entitlement_Repository__c cer: [Select id,APTS_Adjustment_Value__c,APTS_Agreement_Adjustment_Line_Item__c,APTS_Agreement_Adjustment_Line_Item__r.Apttus_CMConfig__LineItemId__r.Apttus_CMConfig__PriceListItemId__c,APTS_Adjustment_Type__c From APTS_Contract_Entitlement_Repository__c where APTS_Agreement_Adjustment_Line_Item__r.Apttus_CMConfig__LineItemId__r.Apttus_CMConfig__PriceListItemId__c IN: pliIds limit 50000]){
            if(pliCERmap.get(cer.APTS_Agreement_Adjustment_Line_Item__r.Apttus_CMConfig__LineItemId__r.Apttus_CMConfig__PriceListItemId__c) == null){
                pliCERmap.put(cer.APTS_Agreement_Adjustment_Line_Item__r.Apttus_CMConfig__LineItemId__r.Apttus_CMConfig__PriceListItemId__c,cer);
            }
        }
        return pliCERmap;
    }
    public void getQueryStringParams(){

        if(String.isNotBlank(ApexPages.currentPage().getParameters().get('pliid'))) {
            pricelistID = ApexPages.currentPage().getParameters().get('pliid');   
        } 
        if(String.isNotBlank(ApexPages.currentPage().getParameters().get('id'))) {    
            acctID = ApexPages.currentPage().getParameters().get('id');
        }

        AggregateResult[] groupedResults  = [SELECT count(Id)recordCount 
                                     FROM Apttus_Config2__PriceListItem__c 
                                     WHERE   Apttus_Config2__PriceListId__c =: pricelistID AND 
                                             Apttus_Config2__PriceListId__r.Apttus_Config2__Active__c = true AND 
                                             Apttus_Config2__Active__c = true AND 
                                             Apttus_Config2__ProductId__r.IsActive = true ];
        highVolumeData = true;
      if(Integer.valueOf(groupedResults[0].get('recordCount')) > 1800){
        highVolumeData = false;
        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,'Search result returns high volume data. On screen user can view 1800 records at Max . Please click on "Export as CSV" button to extract complete result as an attachments');
        ApexPages.addMessage(myMsg);
      }
    }

    public void validateQueryParams(){
        
        if(String.isBlank(ApexPages.currentPage().getParameters().get('pliid'))) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,'There is no PriceList associated with the Account, Please include before proceeding..');
            ApexPages.addMessage(myMsg);
        }
    }

    /* Method name : getCategoriesforProducts
       Description : Method used to get category hierarchy based on offering external IDs on Products*/
    public Map<String,String> getCategoriesforProducts(Set<String> offeringExternalIds,List<String> catselected){
        Map<String,String> productCategoryMap = new Map<String,String>();
        
        For(Apttus_Config2__ClassificationHierarchy__c category : [select id,APTS_CategoryHierarchyOfferingExtId__c,name,Apttus_Config2__HierarchyId__r.name from Apttus_Config2__ClassificationHierarchy__c where APTS_CategoryHierarchyOfferingExtId__c IN: offeringExternalIds and Apttus_Config2__HierarchyId__r.Apttus_Config2__Active__c=true limit 5000]){
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
    /* Wrapper class name : ListPriceExtractionWrapper
       Description : Class that helps to bind Category and Price list item data*/
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
        public ListPriceExtractionWrapper(String categoryName,Apttus_Config2__PriceListItem__c pli,String convUOM,Decimal uomBasedLP,string sellingterm,String defaultselling,Decimal formattedlist,String bundleProdCode, String bundleProdName, String optionGrpCode, String optionGrpName, String prodName){
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
        public String defaultsellinguom {get;set;}
        public Decimal formattedlistprice {get;set;}
        //<< v103 - Start
        public string bundleProductName {get;set;}
        public string bundleProductCode {get;set;}
        public string optionGroupName {get;set;}
        public string optionGroupCode {get;set;}
        public string productName {get;set;}        
        //>> v103 - End


        public compareListPriceExtractionWrapper(String categoryName,Apttus_Config2__PriceListItem__c pli,string disc,decimal contpri,decimal netpritaxvat,String defaultselling,Decimal formattedlist,String bundleProdCode, String bundleProdName, String optionGrpCode, String optionGrpName, String prodName){
            category = categoryName;
            pricelistItem = pli;
            discount = disc;
            contnetprice = contpri;
            netpriwithtaxvat = netpritaxvat;
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

        public Integer compareTo(Object objToCompare) {
            //Sort by BookName Alphabetically
            return ((compareListPriceExtractionWrapper)objToCompare).category.compareTo(category);
        }
    }
    public void previous()  
    {
        if(acctId==null){
            requestedPriceListItems.clear();
            if(startIndex>=LIMIT_SIZE){
                startIndex-=LIMIT_SIZE;
            }
            For(integer i=startIndex; i< startIndex + LIMIT_SIZE; i++){
                if((productpriceList.size() - 1) >= i){
                    requestedPriceListItems.add(productpriceList[i]);
                }
            }
        }else{
            requestedAccountpriceListItems.clear();
            if(startIndex>=LIMIT_SIZE){
                startIndex-=LIMIT_SIZE;
            }
            For(integer i=startIndex; i< startIndex + LIMIT_SIZE; i++){
                if((comparepriceList.size() - 1) >= i){
                    requestedAccountpriceListItems.add(comparepriceList[i]);
                }
            }
        }
    }  
    public void next(){  
        if(acctId==null){
            requestedPriceListItems.clear();
            startIndex+=LIMIT_SIZE;
            For(integer i=startIndex; i< startIndex + LIMIT_SIZE; i++){
                if((productpriceList.size() - 1) >= i){
                    requestedPriceListItems.add(productpriceList[i]);
                }
            }
        }else{
            requestedAccountpriceListItems.clear();
            startIndex+=LIMIT_SIZE;
            For(integer i=startIndex; i< startIndex + LIMIT_SIZE; i++){
                if((comparepriceList.size() - 1) >= i){
                    requestedAccountpriceListItems.add(comparepriceList[i]);
                }
            }
        }
    }  
    public void first()  
    {  
        if(acctId==null){
            requestedPriceListItems.clear();
            startIndex=0;
            For(integer i=0; i< LIMIT_SIZE; i++){
                if((productpriceList.size() - 1) >= i){
                    requestedPriceListItems.add(productpriceList[i]);
                }
            }
        }else{
            requestedAccountpriceListItems.clear();
            startIndex=0;
            For(integer i=0; i< LIMIT_SIZE; i++){
                if((comparepriceList.size() - 1) >= i){
                    requestedAccountpriceListItems.add(comparepriceList[i]);
                }
            }
        }
    }  
    public void last(){ 
        if(acctId==null){
            requestedPriceListItems.clear();
            startIndex=productpriceList.size()-LIMIT_SIZE;
            if(productpriceList.size()>LIMIT_SIZE){
                For(integer i=productpriceList.size()-LIMIT_SIZE; i<productpriceList.size(); i++){
                    if((productpriceList.size() - 1) >= i){
                        requestedPriceListItems.add(productpriceList[i]);
                    }
                }
            }
        }else{
            requestedAccountpriceListItems.clear();
            startIndex=comparepriceList.size()-LIMIT_SIZE;
            if(comparepriceList.size()>LIMIT_SIZE){
                For(integer i=comparepriceList.size()-LIMIT_SIZE; i<comparepriceList.size(); i++){
                    if((comparepriceList.size() - 1) >= i){
                        requestedAccountpriceListItems.add(comparepriceList[i]);
                    }
                }
            }
        }
    }  
   public Boolean hasNext {
        get{
            if(acctId==null){
                if(productpriceList.size() > startIndex+LIMIT_SIZE){
                    return true;
                }else{
                    return false;
                }
            }else{
                if(comparepriceList.size() > startIndex+LIMIT_SIZE){
                    return true;
                }else{
                    return false;
                }
            }
        }set;
    }

    public Integer pageNumber {
        get{
            Decimal pageNumber = (startIndex/LIMIT_SIZE) + 1;
            return (Integer)pageNumber.round(System.RoundingMode.CEILING);
        }
        set;
    }

    public Integer totalPages {
        get{
            if(acctId==null){
                Decimal totalSize = productpriceList.size()/LIMIT_SIZE;
                return (Integer)totalSize.round(System.RoundingMode.CEILING);
            }else{
                Decimal totalSize = comparepriceList.size()/LIMIT_SIZE;
                return (Integer)totalSize.round(System.RoundingMode.CEILING);
            }
        }
        set;
    }
 
     /** indicates whether there are more records before the current page set.*/
     public Boolean hasPrevious {
         get{
            if(startIndex>0){
                return true;
            }else{
                return false;
            }
        }set;
     }
}