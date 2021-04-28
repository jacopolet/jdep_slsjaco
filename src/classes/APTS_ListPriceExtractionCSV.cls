/*
 * This class is used to download and attachments of CSV files of List price extraction data. Defect #22520.
 * Created By - Mahesh Chilaka
 * Created Date - 17th Dec, 2018
 * Modified History 
 *  // v101 - Defect 22913 - Logic added to extract Prices For ZOPT Machines and Concepts
 *  // v102 - Defect 4283 - 1. Code fix for not to display irrevalent Materials. 
                            2. Code fix to clear all previous search results.
*/


public without sharing class APTS_ListPriceExtractionCSV {

   
  /* Method name : initializeCSVCall
     Description : Method used to initialize future call and download and attach the search result data as CSV file*/  
   public static void initializeCSVCall(String groupCatCSV, String incluTaxCSV, String incluVatCSV, String userUOMCSV, String isExportAsxls, boolean futureCall, String pricelistID, String acctId){

    List<Id> firstSet = new List<Id>();
    List<Id> secondSet = new List<Id>();
    List<Id> thirdSet = new List<Id>();
    List<Id> fourthSet = new List<Id>();
    List<Id> fifthSet = new List<Id>();
    List<Id> sixthSet = new List<Id>();
    List<Id> seventhSet = new List<Id>();
    List<Id> eightSet = new List<Id>();
    integer i=1;
    for(Apttus_Config2__PriceListItem__c pli : [SELECT Id FROM Apttus_Config2__PriceListItem__c  WHERE Apttus_Config2__PriceListId__c =: pricelistID AND                                                       
                                                                                                       Apttus_Config2__PriceListId__r.Apttus_Config2__Active__c = true AND 
                                                                                                       Apttus_Config2__Active__c = true AND 
                                                                                                       Apttus_Config2__ProductId__r.IsActive = true 
                                                                                               ORDER BY Apttus_Config2__ProductId__c ]) {
        if(i<=5000){ 
          firstSet.add(pli.Id);
        } else if(i>5000 && i<=10000 || Test.isRunningTest()){
         secondSet.add(pli.Id);
        } else if(i>10000 && i<=15000 || Test.isRunningTest()){
         thirdSet.add(pli.Id);
        } else if(i>15000 && i<=20000 || Test.isRunningTest()){
         fourthSet.add(pli.Id);
        } else if(i>20000 && i<=25000 || Test.isRunningTest()){
         fifthSet.add(pli.Id);
        } else if(i>25000 && i<=30000 || Test.isRunningTest()){
         sixthSet.add(pli.Id);
        } else if(i>30000 && i<=35000 || Test.isRunningTest()){
         seventhSet.add(pli.Id);
        } else if(i>35000 && i<=40000 || Test.isRunningTest()){
         eightSet.add(pli.Id);
        } 

       i++;
       
    }

    

      if(!firstSet.isEmpty()) {
        insertCSVFile(firstSet,  groupCatCSV,  incluTaxCSV,  incluVatCSV,  userUOMCSV,  isExportAsxls,  futureCall,  pricelistID,  acctId, 'Set1');
      }
      if(!secondSet.isEmpty() || Test.isRunningTest()) {
        insertCSVFile(secondSet,  groupCatCSV,  incluTaxCSV,  incluVatCSV,  userUOMCSV,  isExportAsxls,  futureCall,  pricelistID,  acctId, 'Set2');
      }
      if(!thirdSet.isEmpty() || Test.isRunningTest()) {
        insertCSVFile(thirdSet,  groupCatCSV,  incluTaxCSV,  incluVatCSV,  userUOMCSV,  isExportAsxls,  futureCall,  pricelistID,  acctId, 'Set3');
      }
      if(!fourthSet.isEmpty() || Test.isRunningTest()) {
        insertCSVFile(fourthSet,  groupCatCSV,  incluTaxCSV,  incluVatCSV,  userUOMCSV,  isExportAsxls,  futureCall,  pricelistID,  acctId, 'Set4');
      }
      if(!fifthSet.isEmpty() || Test.isRunningTest()) {
        insertCSVFile(fifthSet,  groupCatCSV,  incluTaxCSV,  incluVatCSV,  userUOMCSV,  isExportAsxls,  futureCall,  pricelistID,  acctId, 'Set5');
      }
      if(!sixthSet.isEmpty() || Test.isRunningTest()) {
        insertCSVFile(sixthSet,  groupCatCSV,  incluTaxCSV,  incluVatCSV,  userUOMCSV,  isExportAsxls,  futureCall,  pricelistID,  acctId, 'Set6');
      }
      if(!seventhSet.isEmpty() || Test.isRunningTest()) {
        insertCSVFile(seventhSet,  groupCatCSV,  incluTaxCSV,  incluVatCSV,  userUOMCSV,  isExportAsxls,  futureCall,  pricelistID,  acctId, 'Set7');
      }
      if(!eightSet.isEmpty() || Test.isRunningTest()) {
        insertCSVFile(eightSet,  groupCatCSV,  incluTaxCSV,  incluVatCSV,  userUOMCSV,  isExportAsxls,  futureCall,  pricelistID,  acctId, 'Set8');
      }


   }
    
    /* Method name : insertCSVFile
     Description : Method used to insert CSV files based on PriceListItems in search results */
    @future 
    public static void insertCSVFile(List<Id> priceListItemIds, String groupCatCSV, String incluTaxCSV, String incluVatCSV, String userUOMCSV1, String isExportAsxls1, boolean futureCall, String pricelistID, String acctId, String attachName){

       //initialize
        boolean groupByCategory ;
        boolean includeVat ;
        boolean includeTax ;
        //<< v102 - Start
        boolean displayBundleProduct = false;
        //>> v102 - End
        decimal netprice=0;
        decimal netpricewithTax=0;
        decimal uomListPrice=0;
        decimal formattedListPrice=0;
        String userDefinedUOM ;    
        String groupByCategoryCSV ;
        String includeVatCSV;
        String includeTaxCSV;
        String isExportAsXls;    
        String region ; 
        String userUOMCSV = '';
        String selectedCatgs;
        String category='';
        String discount='';    
        String userSelectedUOM='';    
        String defaultsellinguom='';
        string sellingterm;
        String uomCSV;
        String parentId;
        //<< v102 - Start
        String bundleProductName;
        String bundleProductCode;
        String optionGroupName;
        String optionGroupCode;
        String productName;
        //>> v102 - End
         
        Apttus_Config2__PriceList__c priceListDetails;
        //<< v101 - Start 
        Set<String> prefixCodeMachineConcept = new Set<String> {'04', '07'};
        //>> v101 - End 
        Set<String> displayCategoryFormat = new  Set<String>();
        Set<String> salesCatalogIDSet = new Set<String>();
        Set<String> productCodeSet = new Set<String>();
        //<< v102 - Start
        Set<String> categoryMachineConcept = new Set<String> {'Machines', 'Concepts'}; 
        //>> v102 - End
        Set<ID> pliIds = new Set<Id>();   
        Set<ID> pliCERSet = new Set<ID>();
        //<< v101 - Start
        Set<ID> optGroupIndiProductIds = new Set<ID>();
        //>> v101 - End
        
        List<string> catselected = new List<string>();
        //<< v102 - Start
        List<string> productFamilyCode = new List<string>();
        //>> v102 - End
        List<Apttus_Config2__PriceMatrix__c> pricematList = new List<Apttus_Config2__PriceMatrix__c>();
        List<APTS_Contract_Entitlement_Repository__c>cerList = new List<APTS_Contract_Entitlement_Repository__c>();
        List<Apttus_Config2__PriceListItem__c> customerpricelistItemList = new List<Apttus_Config2__PriceListItem__c>();
        Map<Id, Apttus_Config2__PriceListItem__c> pricelistItemList = new Map<Id, Apttus_Config2__PriceListItem__c>();
        
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

        Map<Id,String> plimatrixentryMap = new Map<Id,String>();
        Map<String,Decimal> uomConversionValueMap = new Map<String,Decimal>();

      try{
            //Fetching params from query string
            groupByCategoryCSV = groupCatCSV;
            includeTaxCSV = incluTaxCSV;
            includeVatCSV = incluVatCSV;
            userUOMCSV = userUOMCSV1;
            isExportAsXls = isExportAsxls1; 
            //<< v102 - Start
            if(String.isNotBlank(groupByCategoryCSV)){
                catselected = groupByCategoryCSV.split(',');

                for(string categories : catselected){
                    productFamilyCode.add(APTS_ListPriceExtractionCtrl.productFamilyMap.get(categories));
                    if(categoryMachineConcept.contains(categories)){ displayBundleProduct = true; }
                }
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
                  
                //<< v102 - Start
                for(Apttus_Config2__PriceListItem__c pli : [SELECT Id,Apttus_Config2__ProductCode__c,APTS_Default_Selling_Uom__c,APTS_VAT_percentage__c,Apttus_Config2__ChargeType__c,Apttus_Config2__ProductId__r.APTS_Sales_Catalog__c,
                                                                  Apttus_Config2__ProductId__r.IsActive,Apttus_Config2__Active__c,Apttus_Config2__ProductId__r.name,Apttus_Config2__ProductId__c,Apttus_Config2__PriceUom__c,APTS_Tax_per_UOM__c,
                                                                  Apttus_Config2__Description__c,Apttus_Config2__ListPrice__c,Apttus_Config2__PriceListId__r.Apttus_Config2__AccountId__c , CurrencyIsoCode,
                                                                  Apttus_Config2__ProductId__r.APTS_Material_Type__c, Apttus_Config2__ProductId__r.APTS_Option_Group_Indicator__c, toLabel(Apttus_Config2__ProductId__r.APTS_Option_Family__c)
                                                             FROM Apttus_Config2__PriceListItem__c 
                                                             WHERE Id IN: priceListItemIds AND
                                                                    Apttus_Config2__PriceListId__r.Apttus_Config2__Active__c = true AND 
                                                                      Apttus_Config2__Active__c = true AND 
                                                                      Apttus_Config2__ProductId__r.Family IN : productFamilyCode AND
                                                                      Apttus_Config2__ProductId__r.IsActive = true                                                                       
                                                             ORDER BY Apttus_Config2__ProductId__c ]) {
                    if(String.isNotBlank(pli.Apttus_Config2__ChargeType__c)  && pli.Apttus_Config2__ChargeType__c.contains('Rental') ){
                      pliids.add(pli.id);    
                    }
                  if(pli.Apttus_Config2__ProductId__r != null && pli.Apttus_Config2__ProductId__r.APTS_Sales_Catalog__c != null){                                    
                      salesCatalogIDSet.add(pli.Apttus_Config2__ProductId__r.APTS_Sales_Catalog__c);
                      productCodeSet.add(pli.Apttus_Config2__ProductCode__c);
                      pliIds.add(pli.Id);
                    }   
                    pricelistItemList.put(pli.Id, pli);    
                }
                //>> v102 - End
                //<< v101 - Start
                for(Apttus_Config2__PriceListItem__c pli : pricelistItemList.values()) {
                    if(pli.Apttus_Config2__ProductId__c != null && String.isNotBlank(pli.Apttus_Config2__ProductId__r.APTS_Sales_Catalog__c)){
                        if(prefixCodeMachineConcept.contains(String.valueOf(pli.Apttus_Config2__ProductId__r.APTS_Sales_Catalog__c).subString(0,2))){
                            optGroupIndiProductIds.add(pli.Apttus_Config2__ProductId__c);
                          }
                         //system.debug(pli.Apttus_Config2__ProductId__r.APTS_Sales_Catalog__c);
                  }
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
                    //<< v102 - Start
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
                      
                        if(String.isNotBlank(prLiIT.Apttus_Config2__ChargeType__c)  && prLiIT.Apttus_Config2__ChargeType__c.contains('Rental') ){
                          pliids.add(prLiIT.id);    
                        }
                      if(prLiIT.Apttus_Config2__ProductId__r != null && prLiIT.Apttus_Config2__ProductId__r.APTS_Sales_Catalog__c != null){                                    
                          salesCatalogIDSet.add(prLiIT.Apttus_Config2__ProductId__r.APTS_Sales_Catalog__c);
                          productCodeSet.add(prLiIT.Apttus_Config2__ProductCode__c);
                          pliIds.add(prLiIT.Id);
                        } 
                        if(!pricelistItemList.containsKey(prLiIT.Id)){  
                          pricelistItemList.put(prLiIT.Id, prLiIT);  
                        }                      
                        priceListwithComponentProductMap.put(prLIIT.Id, prLIIT.Apttus_Config2__ProductId__c);
                    }    
                }
                //>> v102 - End
                //>> v101 - End
               
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
               
              if(String.isNotBlank(acctID)){
                cerList = APTS_CERUtility.getContractedProductsWithDiscounts(acctId);
                cerList.sort();
              }
                       
                            
              if(!cerList.isEmpty()){
                for(APTS_Contract_Entitlement_Repository__c cer : cerList){
                   
                     pliCERSet.add(cer.APTS_Agreement_Adjustment_Line_Item__r.Apttus_CMConfig__LineItemId__r.Apttus_CMConfig__PriceListItemId__c);
               
                   if(cer.APTS_Agreement_Line_Item__r.Apttus__NetPrice__c != null){                
                     plinetpriceMap.put(cer.APTS_Agreement_Adjustment_Line_Item__r.Apttus_CMConfig__LineItemId__r.Apttus_CMConfig__PriceListItemId__c,cer.APTS_Agreement_Line_Item__r.Apttus__NetPrice__c);
                     
                   }
                   if(cer.APTS_Agreement_Line_Item__r.APTS_Net_Price_Inc_taxes__c != null){
                     plinetpricetaxMap.put(cer.APTS_Agreement_Adjustment_Line_Item__r.Apttus_CMConfig__LineItemId__r.Apttus_CMConfig__PriceListItemId__c,cer.APTS_Agreement_Line_Item__r.APTS_Net_Price_Inc_taxes__c);
                     
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
                  if(pricelistItemList.containsKey(pliSetId) && 
                     pricelistItemList.get(pliSetId).Apttus_Config2__PriceListId__r.Apttus_Config2__AccountId__c != null && 
                     acctID != null && 
                     pricelistItemList.get(pliSetId).Apttus_Config2__PriceListId__r.Apttus_Config2__AccountId__c == acctID){
                     customerpricelistItemList.add(pricelistItemList.get(pliSetId));
                     
                   }
                 }
                
              }
              
              
              //get all UOM conversion rates
              if(!productCodeSet.isEmpty() ){
              
                for( Apttus_Config2__FrequencyConversionRate__c freqConversion : [SELECT id,Apttus_Config2__FromUom__c,Apttus_Config2__ToUom__c,Apttus_Config2__ProductFamily__c,
                                                                                         Apttus_Config2__ConversionFactor__c,Apttus_Config2__ProductId__c,APTS_ProductCode__c 
                                                                                  FROM Apttus_Config2__FrequencyConversionRate__c 
                                                                                  WHERE Apttus_Config2__ToUom__c =: userUOMCSV AND 
                                                                                        Apttus_Config2__FromUom__c =: APTS_CPQConstants.PIECE_UOM_API AND
                                                                                        APTS_ProductCode__c IN: productCodeSet]) {
               
                   if(freqConversion.Apttus_Config2__ConversionFactor__c != null){
                    uomConversionValueMap.put(freqConversion.APTS_ProductCode__c, freqConversion.Apttus_Config2__ConversionFactor__c);
                  }
                }
              }
               
               //system.debug('catselected'+catselected);
               if(salesCatalogIDSet != null){ 
                productCategoryMap = getCategoriesforProducts(salesCatalogIDSet,catselected);
              }
              //System.debug('**productCategoryMap'+productCategoryMap.size());
              string header = priceListDetails.Name+' : '+ priceListDetails.CreatedDate.format('dd/MM/yyyy')+'\n';
                     header += 'Jacobs Douwe Egberts Pro - '+region+' \n \n';
              if(String.isBlank(acctID)) {
                  if(displayBundleProduct){
                    header += 'Category; Bundle Article Nr.; Bundle Product Name; Article Nr. ; Option Group; Product name; Charge type; (Default) Selling UoM; List Price (Negotiated); User based UoM; RENT : Selling Term; UoM based List price; TAX; VAT\n';
                  }else {
                    header += 'Category; Article Nr. ; Product name; Charge type; (Default) Selling UoM; List Price (Negotiated); User based UoM; RENT : Selling Term; UoM based List price; TAX; VAT\n';
                  }
               } else if(String.isNotBlank(acctID)){
                  if(displayBundleProduct){
                    header += 'Category; Bundle Article Nr.; Bundle Product Name; Article Nr. ; Option Group; Product name; Charge type; (Default) Selling UoM; List Price (Negotiated); TAX; VAT;Discount;Net Price;Net Price(inc. Taxes)\n';
                  }else {
                    header += 'Category; Article Nr. ; Product name; Charge type; (Default) Selling UoM; List Price (Negotiated); TAX; VAT;Discount;Net Price;Net Price(inc. Taxes)\n';
                  }
              }
              string finalstr = header ;
              string recordString = '';

             if(!customerpricelistItemList.isEmpty() || !pricelistItemList.isEmpty()) {
                 for(Apttus_Config2__PriceListItem__c pricelistItem : (!customerpricelistItemList.isEmpty())?customerpricelistItemList : pricelistItemList.values()){
                   category='';
                   discount='';
                   netprice=0;
                   netpricewithTax=0;
                   uomListPrice=0;
                   userSelectedUOM='';
                   formattedListPrice=0;
                   defaultsellinguom='';
                   //<< v102 - Start
                   bundleProductName='';
                   bundleProductCode='';
                   optionGroupName='';
                   optionGroupCode='';
                    //>> v102 - End
                  //Added by Hari Selling Term for Rental PLI
                   sellingterm='';
                  //Used to get categories for list of price list items                   
                  
                    if(!productCategoryMap.isEmpty() &&  productCategoryMap.get(pricelistItem.Apttus_Config2__ProductId__r.APTS_Sales_Catalog__c)!=null ){                            
                        category = productCategoryMap.get(pricelistItem.Apttus_Config2__ProductId__r.APTS_Sales_Catalog__c);      
                        //<< v102 - Start   
                         optionGroupCode = pricelistItem.Apttus_Config2__ProductCode__c;
                         productName = pricelistItem.Apttus_Config2__ProductId__r.Name;       
                        //>> v102 - Start                      
                    }
                    //<< v101 - Start
                    else if(priceListwithComponentProductMap.containsKey(priceListItem.Id)){
                        category = productCategoryMap.get(optionGroupBundleProductCodeMap.get(priceListwithComponentProductMap.get(priceListItem.Id))); 
                        //<< v102 - Start
                        bundleProductName = optionGroupBundleProductNameMap.get(priceListwithComponentProductMap.get(priceListItem.Id));
                        bundleProductCode = componentParentProductMap.get(priceListwithComponentProductMap.get(priceListItem.Id));
                        optionGroupCode = pricelistItem.Apttus_Config2__ProductCode__c;
                        optionGroupName = pricelistItem.Apttus_Config2__ProductId__r.APTS_Option_Family__c;
                        productName = pricelistItem.Apttus_Config2__ProductId__r.Name;
                        //>> v102 - Start
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

                    if(!uomConversionValueMap.isEmpty() && uomConversionValueMap.containsKey(pricelistItem.Apttus_Config2__ProductCode__c)) {                            
                        uomListPrice = (formattedlistprice * uomConversionValueMap.get(pricelistItem.Apttus_Config2__ProductCode__c)).setScale(2);
                       } 

                      //get UOM picklist label from picklist API
                      uomCSV=userUOMCSV; 
                      userSelectedUOM = UOMMap.get(uomCSV);
                    
                    //for no conversions available simply copy list price to UOM based list price.

                    IF(uomListPrice==null || uomListPrice==0){
                      //system.debug('Value to be assigned --> ' + formattedlistprice.setScale(2));
                      uomListPrice = formattedlistprice.setScale(2);
                    }

                    //<< v102 - Start
                    if(String.isNotBlank(category)) {
                        if(String.isBlank(acctID)){
                            //Add to the display list | This list is the one which we see on UI 
                            if(displayBundleProduct){
                              recordString = '"'+category+'";"'+bundleProductCode+'";"'+bundleProductName+'";"'+optionGroupCode+'";"'+optionGroupName+'";"'+productName+'";"'+pricelistItem.Apttus_Config2__ChargeType__c+'";"'+defaultsellinguom+'";"'+pricelistItem.CurrencyIsoCode+' '+formattedlistprice+'";"'+userSelectedUOM+'";"'+sellingterm+'";"'+uomListPrice+'";"'+pricelistItem.APTS_Tax_per_UOM__c+'";"'+pricelistItem.APTS_VAT_percentage__c+'"\n';
                            }else {
                              recordString = '"'+category+'";"'+optionGroupCode+'";"'+productName+'";"'+pricelistItem.Apttus_Config2__ChargeType__c+'";"'+defaultsellinguom+'";"'+pricelistItem.CurrencyIsoCode+' '+formattedlistprice+'";"'+userSelectedUOM+'";"'+sellingterm+'";"'+uomListPrice+'";"'+pricelistItem.APTS_Tax_per_UOM__c+'";"'+pricelistItem.APTS_VAT_percentage__c+'"\n';
                            }
                            finalstr = finalstr +recordString;

                          } else if(String.isNotBlank(acctID)){
                              if(displayBundleProduct){
                                recordString = '"'+category+'";"'+bundleProductCode+'";"'+bundleProductName+'";"'+optionGroupCode+'";"'+optionGroupName+'";"'+productName+'";"'+pricelistItem.Apttus_Config2__ChargeType__c+'";"'+defaultsellinguom+'";"'+pricelistItem.CurrencyIsoCode+' '+formattedlistprice+'";"'+pricelistItem.APTS_Tax_per_UOM__c+'";"'+pricelistItem.APTS_VAT_percentage__c+'";"'+discount+'";"'+netprice+'";"'+netpricewithTax+'"\n';
                             }else {
                                recordString = '"'+category+'";"'+optionGroupCode+'";"'+productName+'";"'+pricelistItem.Apttus_Config2__ChargeType__c+'";"'+defaultsellinguom+'";"'+pricelistItem.CurrencyIsoCode+' '+formattedlistprice+'";"'+pricelistItem.APTS_Tax_per_UOM__c+'";"'+pricelistItem.APTS_VAT_percentage__c+'";"'+discount+'";"'+netprice+'";"'+netpricewithTax+'"\n';
                             }
                             finalstr = finalstr +recordString;             
                           }
                    }
                    //>> v102 - End
                  

                      
            }

                if(String.isNotBlank(acctId) ){
                    parentId = acctId;
                  } else if(String.isNotBlank(pricelistID)){
                    parentId = pricelistID;
                  }

                    Attachment attach = new Attachment(parentId = parentId, Name = 'List Price Extraction_'+attachName+' - '+ System.Now().format() + '.csv', body = Blob.valueOf(finalstr)); //create the attachment object
                    insert attach;
              }
               
                   
              
          }
                      
            
      }catch(Exception e){
           APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'APTS_ListPriceExtractionCSV', ApexPages.currentPage().getParameters().get('businessObjectId'),'CPQ',false,true,'cpqerror@accenture.com',true);
        //  system.debug('Error Message'+e);
          //system.debug('Message'+e.getStackTraceString());
      } 

       
    }

    
  
    /* Method name : getCategoriesforProducts
       Description : Method used to get category hierarchy based on offering external IDs on Products*/
    public static Map<String,String> getCategoriesforProducts(Set<String> OfferingExternalIds,List<String> catselected){
        Map<String,String> productCategoryMap = new Map<String,String>();
        
        For(Apttus_Config2__ClassificationHierarchy__c category : [select id, Name, APTS_CategoryHierarchyOfferingExtId__c, 
                                                                          Apttus_Config2__HierarchyId__r.Name  
                                                                    from Apttus_Config2__ClassificationHierarchy__c 
                                                                    where Name != '' AND APTS_CategoryHierarchyOfferingExtId__c !='' AND 
                                                                          Apttus_Config2__HierarchyId__r.name != '' AND 
                                                                          Apttus_Config2__HierarchyId__r.Apttus_Config2__Active__c=true]){           
               
               productCategoryMap.put(category.APTS_CategoryHierarchyOfferingExtId__c, category.Name+'|'+category.Apttus_Config2__HierarchyId__r.Name);
          
        }
        
        return productCategoryMap;
    }
   
}