/**********************************************************************************
 * @Author: Keerthana
 * @Company: Accenture
 * @Description: Handles the Contents/file creation for Bizisland CER
 * @Created Date: Jan 8, 2019
 * @History:
 *      <Name>              <Date>          <Description>
 *      Keerthana           08.01.2019       Created
 **********************************************************************************/
 //v100 12/03/2019 Venky Muppalaneni : Added Based on price list item list price 
 //v101 27/03/2019 Mahesh Chilaka : Code fix for wrong list price.
 //v102 09/04/2019 Mahesh Chilaka : Defect-6630, Code fix for wrong Bonsai Id Level.
global class APTS_CERBizIsland implements Database.Batchable<sObject>{
    
    global String csvColumnHeader;
    global List<String> csvRowValues = new List<String>();    
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        /* && Apttus__AgreementId__r.isBonsai__c=true  &&   AND (Apttus_CMConfig__LineType__c =\'Product/Service\' OR Apttus_CMConfig__HasOptions__c = false)*/
        Bonsai__c customSetting = Bonsai__c.getAll().values();
        String query;
       /* if(customSetting.Delta_Load__c){
            APTS_BizIsland__mdt bizmdt = [Select APTS_Query__c from APTS_BizIsland__mdt where DeveloperName= :'CERDelta'][0];
            query = bizmdt.APTS_Query__c; 
        }*/
        system.debug('csfull'+customSetting.Full_Load__c);
        if(customSetting.Full_Load__c){
            APTS_BizIsland__mdt bizmdt = [Select APTS_Query__c from APTS_BizIsland__mdt where DeveloperName= :'CERFull'][0];
            query = bizmdt.APTS_Query__c;
            system.debug('query string' +query);
            
        }

            system.debug('query' +query);
           return Database.getQueryLocator(query);
           //system.debug('query' +query);
    }

    global void execute(Database.BatchableContext BC, List<APTS_Contract_Entitlement_Repository__c> scope) {
        system.debug('@@' +scope);
        String ProductNumber;
        String IDField;
        String Status;
        String productIdSoldtoPartyId = '';
        String salesorg ='';
        String disChan='';
        string uom='';
        string netpriceincl ='0.00';
        string indirecttaxamt ='0.00';
        decimal myindirecttaxamt;
        decimal mynetpriceincl;
          //V100 Start  
        decimal listPrice = 0;
          //V100 End  
        decimal discountcus;
        string discountcustomcurrency='0.00';
        set<id> prodid = new set<id>();
        set <Id> cerprodid = new set<id>();
        Map<Id,Product2> prodmap; 
        Map<Id, Product2> pricemap;
        Map<Id, Product2> cerprodfreqmap;
        Set<Id> soldToAccount = new Set<Id>();
        List<CER_Bizisland__c> listCERBiz = new List<CER_Bizisland__c>();
        Map<String, Integer> cerProductSoldtoPartyMap = new Map<String, Integer>();
        Set<Id> cerProductIdSet = new Set<Id>();
        Set<Id> cerSoldtoPartySet = new Set<Id>();


        try
        {
       
        for(APTS_Contract_Entitlement_Repository__c instcer : scope){
            if(instcer.APTS_Agreement_Line_Item__r.Apttus__ProductId__c != null){
                prodid.add(instcer.APTS_Agreement_Line_Item__r.Apttus__ProductId__c);
            }
            if(instcer.APTS_Product__c!= null){
                    cerprodid.add(instcer.APTS_Product__c);
            }
            if(instcer.APTS_Sold_to_Party__c != null){
                soldToAccount.add(instcer.APTS_Sold_to_Party__c);
            }

            

            if(instcer.APTS_Contributing_Agreement_Level__c != 'Child') {                
                cerProductIdSet.add(instcer.APTS_Product__c);
                cerSoldtoPartySet.add(instcer.APTS_Sold_to_Party__c);                
            }
        }

        for(APTS_Contract_Entitlement_Repository__c cerRec : [SELECT Id, APTS_Product__c, APTS_Sold_to_Party__c 
                                                              FROM APTS_Contract_Entitlement_Repository__c
                                                              WHERE APTS_Product__c IN: cerProductIdSet AND
                                                                    APTS_Sold_to_Party__c IN: cerSoldtoPartySet AND
                                                                    APTS_Contributing_Agreement_Level__c = 'Child' ]){

            productIdSoldtoPartyId = cerRec.APTS_Product__c+';'+cerRec.APTS_Sold_to_Party__c;

            if(!cerProductSoldtoPartyMap.isEmpty() && cerProductSoldtoPartyMap.containsKey(productIdSoldtoPartyId)){
                    cerProductSoldtoPartyMap.put(productIdSoldtoPartyId,cerProductSoldtoPartyMap.get(productIdSoldtoPartyId)+1);
            }            
            else {
                   cerProductSoldtoPartyMap.put(productIdSoldtoPartyId, 1);
            }
        }

        // Agreement Account Map
        List<Apttus__APTS_Agreement__c> tempListPo;// = new List<Apttus__APTS_Agreement__c>();
        Map<Id, List<Apttus__APTS_Agreement__c>> accountAgreementMap = new Map<Id, List<Apttus__APTS_Agreement__c>>();
        if(!soldToAccount.isEmpty()){
            for (Apttus__APTS_Agreement__c oAgreement : [SELECT Id,
                                                        Apttus__Account__c,
                                                        Apttus__FF_Agreement_Number__c,
                                                        RecordTypeId
                                                    FROM Apttus__APTS_Agreement__c
                                                    WHERE Apttus__Account__c IN: soldToAccount]){
                tempListPo = new List<Apttus__APTS_Agreement__c>();
                if(accountAgreementMap.containsKey(oAgreement.Apttus__Account__c)){
                    tempListPo = accountAgreementMap.get(oAgreement.Apttus__Account__c);
                    if (!tempListPo.contains(oAgreement)){
                        tempListPo.add(oAgreement);
                        accountAgreementMap.put(oAgreement.Apttus__Account__c,tempListPo);
                    }
                }else{
                    tempListPo.add(oAgreement);
                    accountAgreementMap.put(oAgreement.Apttus__Account__c, new List<Apttus__APTS_Agreement__c>(tempListPo));
                }
            }
        }
        system.debug('accountAgreementMap==>'+accountAgreementMap);
        if(prodid.size()>0){
                prodmap = new map<id,product2>([select id,
                    (select id,
                    Apttus_Config2__FromUom__c,
                    Apttus_Config2__ToUom__c,
                    Apttus_Config2__ConversionFactor__c 
                    from Apttus_Config2__FrequencyUOMConversionRates__r ) from Product2 where id in :prodid]); 
        }
        system.debug('prodmap' +prodmap);

        if(cerprodid.size()>0){
                pricemap = new map<id,Product2>([select id,
                    (select id,
                    Apttus_Config2__ProductId__c,
                    Apttus_Config2__PriceUom__c,
                    Apttus_Config2__ListPrice__c,
                    APTS_Sales_Org__c,
                    Apttus_Config2__PriceListId__r.APTS_PriceList_Type__c,
                    Apttus_Config2__PriceListId__r.Apttus_Config2__Active__c from Apttus_Config2__PriceLists__r where 
                    Apttus_Config2__PriceListId__r.APTS_PriceList_Type__c='Direct' AND 
                    Apttus_Config2__PriceListId__r.Apttus_Config2__Active__c = true AND 
                    APTS_Sales_Org__c = 'SAP_0975')from Product2 where id in:cerprodid]);
        }
        system.debug('pricemap' +pricemap);
        if(cerprodid.size()>0){
            cerprodfreqmap = new map<id,product2>([select id,(select id,Apttus_Config2__FromUom__c,Apttus_Config2__ToUom__c,Apttus_Config2__ConversionFactor__c from Apttus_Config2__FrequencyUOMConversionRates__r ) from Product2 where id in :cerprodid]);   
        }
        system.debug('cerprodfreqmap' +cerprodfreqmap);
        
        Pattern p = Pattern.compile('[^0-9]');
        for(APTS_Contract_Entitlement_Repository__c instceragrLI : scope){

           // if(instceragrLI.APTS_Sold_to_Party__r.APTS_Bonsai_ID_Level__c == 'AGR'){
                    // Build Product Code 
                    IF(instceragrLI.APTS_Agreement_Line_Item__r.Apttus_CMConfig__OptionId__c != NULL)
                        ProductNumber = instceragrLI.APTS_Agreement_Line_Item__r.Apttus_CMConfig__OptionId__r.ProductCode;
                    else
                        ProductNumber = instceragrLI.APTS_Agreement_Line_Item__r.Apttus__ProductId__r.ProductCode;
                  /*  IF(instceragrLI.APTS_Agreement_Line_Item__r.Apttus_CMConfig__BasePriceOverride__c != NULL)
                        IDField='CUST' ;
                    else */
                    
                    productIdSoldtoPartyId = instceragrLI.APTS_Product__c+';'+instceragrLI.APTS_Sold_to_Party__c;

                     if(cerProductSoldtoPartyMap.containsKey(productIdSoldtoPartyId) &&
                        cerProductSoldtoPartyMap.get(productIdSoldtoPartyId) > 0) {   

                        IDField = instceragrLI.APTS_Agreement_Line_Item__r.Apttus__AgreementId__r.Apttus__Account__r.APTS_Bonsai_ID_Level__c;
                    } //v102 -Start
                    else if (instceragrLI.APTS_Sold_to_Party__r.APTS_Has_Child_Accounts__c) {
                         IDField = 'AGR';
                    } //v102 - End.
                    else {
                        IDField = instceragrLI.APTS_Sold_to_Party__r.APTS_Bonsai_ID_Level__c;
                     }

                    if(instceragrLI.CreatedDate.date()==System.Today())
                    Status = 'New';
                    else if(instceragrLI.LastModifiedDate.date() ==System.Today())
                    Status='Modified';
                    else 
                    Status='Not Modified';
                    if((Status == 'Modified' || Status == 'New') && instceragrLI.isDeleted == true)
                    Status = 'Deleted';
                    
                    if(prodmap != null 
                    && prodmap.containskey(instceragrLI.APTS_Agreement_Line_Item__r.Apttus__ProductId__c) 
                    && prodmap.get(instceragrLI.APTS_Agreement_Line_Item__r.Apttus__ProductId__c).Apttus_Config2__FrequencyUOMConversionRates__r.size()>0){
                    
                        for(integer i=0; i<prodmap.get(instceragrLI.APTS_Agreement_Line_Item__r.Apttus__ProductId__c).Apttus_Config2__FrequencyUOMConversionRates__r.size();i++){

                            if(instceragrLI.APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingUom__c == instceragrLI.APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.Apttus_Config2__PriceUom__c ){
                             
                                netpriceincl = string.valueof(instceragrLI.APTS_Agreement_Line_Item__r.Apttus__NetPrice__c + (instceragrLI.APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.APTS_Tax_per_UOM__c *instceragrLI.APTS_Agreement_Line_Item__r.Apttus__Quantity__c));
                                indirecttaxamt = string.valueof(instceragrLI.APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.APTS_Tax_per_UOM__c *instceragrLI.APTS_Agreement_Line_Item__r.Apttus__Quantity__c);


                            }
                            else if(instceragrLI.APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingUom__c == 'SAP_PCE'  && 
                                    instceragrLI.APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.Apttus_Config2__PriceUom__c =='SAP_BX' && 
                                    prodmap.get(instceragrLI.APTS_Agreement_Line_Item__r.Apttus__ProductId__c).Apttus_Config2__FrequencyUOMConversionRates__r[i].Apttus_Config2__FromUom__c == 'SAP_PCE' &&
                                    prodmap.get(instceragrLI.APTS_Agreement_Line_Item__r.Apttus__ProductId__c).Apttus_Config2__FrequencyUOMConversionRates__r[i].Apttus_Config2__ToUom__c == 'SAP_BX'){
                                
                                    netpriceincl = string.valueof(instceragrLI.APTS_Agreement_Line_Item__r.Apttus__NetPrice__c + (instceragrLI.APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.APTS_Tax_per_UOM__c *(1/prodmap.get(instceragrLI.APTS_Agreement_Line_Item__r.Apttus__ProductId__c).Apttus_Config2__FrequencyUOMConversionRates__r[i].Apttus_Config2__ConversionFactor__c) *instceragrLI.APTS_Agreement_Line_Item__r.Apttus__Quantity__c));
                                    indirecttaxamt = string.valueof(instceragrLI.APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.APTS_Tax_per_UOM__c *(1/prodmap.get(instceragrLI.APTS_Agreement_Line_Item__r.Apttus__ProductId__c).Apttus_Config2__FrequencyUOMConversionRates__r[i].Apttus_Config2__ConversionFactor__c) *instceragrLI.APTS_Agreement_Line_Item__r.Apttus__Quantity__c);
                           
                            }            
                            else if(instceragrLI.APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingUom__c == prodmap.get(instceragrLI.APTS_Agreement_Line_Item__r.Apttus__ProductId__c).Apttus_Config2__FrequencyUOMConversionRates__r[i].Apttus_Config2__ToUom__c &&
                                    prodmap.get(instceragrLI.APTS_Agreement_Line_Item__r.Apttus__ProductId__c).Apttus_Config2__FrequencyUOMConversionRates__r[i].Apttus_Config2__FromUom__c == 'SAP_PCE' && 
                                    instceragrLI.APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.Apttus_Config2__PriceUom__c =='SAP_PCE'){
                    
                      
                                    netpriceincl = string.valueof(instceragrLI.APTS_Agreement_Line_Item__r.Apttus__NetPrice__c + (instceragrLI.APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.APTS_Tax_per_UOM__c *prodmap.get(instceragrLI.APTS_Agreement_Line_Item__r.Apttus__ProductId__c).Apttus_Config2__FrequencyUOMConversionRates__r[i].Apttus_Config2__ConversionFactor__c *instceragrLI.APTS_Agreement_Line_Item__r.Apttus__Quantity__c));
                                    indirecttaxamt = string.valueof(instceragrLI.APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.APTS_Tax_per_UOM__c *prodmap.get(instceragrLI.APTS_Agreement_Line_Item__r.Apttus__ProductId__c).Apttus_Config2__FrequencyUOMConversionRates__r[i].Apttus_Config2__ConversionFactor__c *instceragrLI.APTS_Agreement_Line_Item__r.Apttus__Quantity__c);
                            } 
                           else if(instceragrLI.APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingUom__c == prodmap.get(instceragrLI.APTS_Agreement_Line_Item__r.Apttus__ProductId__c).Apttus_Config2__FrequencyUOMConversionRates__r[i].Apttus_Config2__ToUom__c  && 
                                    prodmap.get(instceragrLI.APTS_Agreement_Line_Item__r.Apttus__ProductId__c).Apttus_Config2__FrequencyUOMConversionRates__r[i].Apttus_Config2__FromUom__c == 'SAP_BX' && 
                                    instceragrLI.APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.Apttus_Config2__PriceUom__c =='SAP_BX'){
                    
                      
                                    netpriceincl = string.valueof(instceragrLI.APTS_Agreement_Line_Item__r.Apttus__NetPrice__c +(instceragrLI.APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.APTS_Tax_per_UOM__c*instceragrLI.APTS_Agreement_Line_Item__r.Apttus__Quantity__c));
                                    indirecttaxamt = string.valueof(instceragrLI.APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.APTS_Tax_per_UOM__c);
                           
                            
                           }
                                          }
                           system.debug('netpriceincl' +netpriceincl);
                           system.debug('indirecttaxamt' +indirecttaxamt);
         
                                      
                                          
            
                        myindirecttaxamt = Decimal.valueOf(indirecttaxamt);
                        if(myindirecttaxamt != 0)
                        {
                        myindirecttaxamt = myindirecttaxamt.setScale(5);
                        }
                        else {
                        myindirecttaxamt = 0;
                        }
                        mynetpriceincl = Decimal.valueOf(netpriceincl); 
                        if(mynetpriceincl != 0)
                        {
                        mynetpriceincl = mynetpriceincl.setScale(5);
                        }
                        else {
                        mynetpriceincl = 0;
                        }
            
                    }
            
                    if(pricemap != null 
                        && pricemap.containskey(instceragrLI.APTS_Product__c) 
                        && pricemap.get(instceragrLI.APTS_Product__c).Apttus_Config2__PriceLists__r.size()>0){
                        
                        for(integer i=0; i<pricemap.get(instceragrLI.APTS_Product__c).Apttus_Config2__PriceLists__r.size();i++){
                            for(integer j=0; j<cerprodfreqmap.get(instceragrLI.APTS_Product__c).Apttus_Config2__FrequencyUOMConversionRates__r.size();j++){
                                if(instceragrLI.APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingUom__c != null 
                                   && pricemap.get(instceragrLI.APTS_Product__c).Apttus_Config2__PriceLists__r[i].Apttus_Config2__PriceUom__c!= null 
                                   && instceragrLI.APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingUom__c == pricemap.get(instceragrLI.APTS_Product__c).Apttus_Config2__PriceLists__r[i].Apttus_Config2__PriceUom__c
                                   && instceragrLI.APTS_Agreement_Line_Item__r.Apttus__NetPrice__c != null
                                   && instceragrLI.APTS_Agreement_Line_Item__r.Apttus__Quantity__c != null){
                                   
                                    discountcustomcurrency = string.valueof(pricemap.get(instceragrLI.APTS_Product__c).Apttus_Config2__PriceLists__r[i].Apttus_Config2__ListPrice__c - (instceragrLI.APTS_Agreement_Line_Item__r.Apttus__NetPrice__c/instceragrLI.APTS_Agreement_Line_Item__r.Apttus__Quantity__c));
                                }
                                    //system.debug('keer listprice' +pricemap.get(instceragrLI.APTS_Product__c).Apttus_Config2__PriceLists__r[i].Apttus_Config2__ListPrice__c );
                                    //system.debug('keer freprice' +cerprodfreqmap.get(instceragrLI.APTS_Product__c).Apttus_Config2__FrequencyUOMConversionRates__r[j].Apttus_Config2__ConversionFactor__c);
                                    //system.debug('keer netprice' +instceragrLI.APTS_Agreement_Line_Item__r.Apttus_CMConfig__NetUnitPrice__c);
                                    
                                else if (instceragrLI.APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingUom__c != null 
                                          && pricemap.get(instceragrLI.APTS_Product__c).Apttus_Config2__PriceLists__r[i].Apttus_Config2__PriceUom__c != null 
                                          && cerprodfreqmap.get(instceragrLI.APTS_Product__c).Apttus_Config2__FrequencyUOMConversionRates__r[j].Apttus_Config2__FromUom__c != null
                                          && cerprodfreqmap.get(instceragrLI.APTS_Product__c).Apttus_Config2__FrequencyUOMConversionRates__r[j].Apttus_Config2__ToUom__c != null
                                          && instceragrLI.APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingUom__c != pricemap.get(instceragrLI.APTS_Product__c).Apttus_Config2__PriceLists__r[i].Apttus_Config2__PriceUom__c && pricemap.get(instceragrLI.APTS_Product__c).Apttus_Config2__PriceLists__r[i].Apttus_Config2__PriceUom__c == cerprodfreqmap.get(instceragrLI.APTS_Product__c).Apttus_Config2__FrequencyUOMConversionRates__r[j].Apttus_Config2__FromUom__c && instceragrLI.APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingUom__c == cerprodfreqmap.get(instceragrLI.APTS_Product__c).Apttus_Config2__FrequencyUOMConversionRates__r[j].Apttus_Config2__ToUom__c
                                          && instceragrLI.APTS_Agreement_Line_Item__r.Apttus__NetPrice__c !=null
                                          && instceragrLI.APTS_Agreement_Line_Item__r.Apttus__Quantity__c != null){
                                    discountcustomcurrency = string.valueof((pricemap.get(instceragrLI.APTS_Product__c).Apttus_Config2__PriceLists__r[i].Apttus_Config2__ListPrice__c * cerprodfreqmap.get(instceragrLI.APTS_Product__c).Apttus_Config2__FrequencyUOMConversionRates__r[j].Apttus_Config2__ConversionFactor__c)- (instceragrLI.APTS_Agreement_Line_Item__r.Apttus__NetPrice__c/instceragrLI.APTS_Agreement_Line_Item__r.Apttus__Quantity__c));
                                }
                            system.debug('==discountcustomcurrency==>'+discountcustomcurrency); 
                                //if(discountcustomcurrency != null){
                                discountcus = Decimal.valueOf(discountcustomcurrency);
                                //}    
                                if(discountcus != 0){
                                    discountcus = discountcus.setScale(5);
                                }else {
                                    discountcus = 0;
                                }
                            }
                        }
                    }
                
                    if(instceragrLI.APTS_Agreement_Line_Item__r.APTS_Sales_Org__c != NULL 
                    && instceragrLI.APTS_Agreement_Line_Item__r.APTS_Sales_Org__c.contains('SAP_')){
                        salesorg = instceragrLI.APTS_Agreement_Line_Item__r.APTS_Sales_Org__c.replace('SAP_','');
                    }else if(instceragrLI.APTS_Agreement_Line_Item__r.APTS_Sales_Org__c != NULL){
                        salesorg = instceragrLI.APTS_Agreement_Line_Item__r.APTS_Sales_Org__c;
                    }
                    if(instceragrLI.APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.APTS_Related_sales_org_data__r.APTS_Distribution_channel__c != NULL && instceragrLI.APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.APTS_Related_sales_org_data__r.APTS_Distribution_channel__c.contains('SAP_')){
                        disChan = instceragrLI.APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.APTS_Related_sales_org_data__r.APTS_Distribution_channel__c.replace('SAP_','');
                    }
                    else if (instceragrLI.APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.APTS_Related_sales_org_data__r.APTS_Distribution_channel__c != NULL){
                        disChan = instceragrLI.APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.APTS_Related_sales_org_data__r.APTS_Distribution_channel__c;
                        }
                   
                     if(instceragrLI.APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingUom__c!= NULL 
                     && instceragrLI.APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingUom__c.contains('SAP_')){
                        uom = instceragrLI.APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingUom__c.replace('SAP_','');
                    }else if (instceragrLI.APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingUom__c!= NULL){
                        uom = instceragrLI.APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingUom__c;
                    }
                       
                       
                     //V100 Start  
                    //v101 Start
                    if(instceragrLI.APTS_Agreement_Line_Item__r != null && instceragrLI.APTS_Agreement_Line_Item__r.Apttus__ListPrice__c != null) {
                        listPrice=instceragrLI.APTS_Agreement_Line_Item__r.Apttus__ListPrice__c;     
                    }
                    //v101 END             
                    //V100 End
                    // Changes for Agreement Number mapping Starts
                    String agreementnumber = '';
                    if(instceragrLI.APTS_Contributing_Agreement__r.RecordTypeId != null){
                        if(!accountAgreementMap.isEmpty()
                            && accountAgreementMap.containsKey(instceragrLI.APTS_Sold_to_Party__c)
                            && accountAgreementMap.get(instceragrLI.APTS_Sold_to_Party__c) != null){
                            List<Apttus__APTS_Agreement__c> agreementList = accountAgreementMap.get(instceragrLI.APTS_Sold_to_Party__c);
                            for(Apttus__APTS_Agreement__c oAgreement : agreementList){
                                if(instceragrLI.APTS_Contributing_Agreement__r.RecordTypeId == oAgreement.RecordTypeId){
                                    agreementnumber = oAgreement.Apttus__FF_Agreement_Number__c;
                                }
                            } 
                        }
                    }else{
                        agreementnumber = instceragrLI.APTS_Contributing_Agreement__r.Apttus__FF_Agreement_Number__c;
                    }
                    // Changes for Agreement Number mapping ENDS      
                    String rowStr = salesorg+','+disChan+','+IDField+','+agreementnumber+','+instceragrLI.APTS_Sold_to_Party__r.SAP_Customer_ID__c+','+ProductNumber+','+listPrice+','+mynetpriceincl+','+instceragrLI.APTS_Agreement_Line_Item__r.CurrencyIsoCode+','+uom+','+discountcus+','+myindirecttaxamt+','+Status;
                    system.debug('SOFI Heap size is ' + limits.getHeapSize() + ' enforced is ' + limits.getLimitHeapSize());
                    system.debug('keer rowstr' +rowstr);
                    csvRowValues.clear();   
                    system.debug('keer rowstr' +csvRowValues.size());
                    system.debug('SOFI Heap size is ' + limits.getHeapSize() + ' enforced is ' + limits.getLimitHeapSize());
                    //Integer i=1;
                    /*  Integer i=1;
                    if(limits.getHeapSize() >= limits.getLimitHeapSize()) // ==11MB
                    {               
                        List<String> myString = new List<String>();
                        myString.addAll(rowStr);
                        i=i+1;
                    }
                    else*/
                    
                         //csvRowValues.add(rowStr);

                    CER_Bizisland__c cerBiz = new CER_Bizisland__c();
                    cerBiz.Sales_Organization__c = salesorg;
                    cerBiz.Distribution_Channel__c = disChan;
                    cerBiz.ID_Level__c = IDField;
                    cerBiz.Agreement_number__c = agreementnumber;
                    cerBiz.Customer_Number__c = instceragrLI.APTS_Sold_to_Party__r.SAP_Customer_ID__c;
                    cerBiz.Product_number__c = ProductNumber;
                    cerBiz.List_Price__c = String.valueOf(listPrice);
                    cerBiz.Net_Price_Incl_Indirect_Tax__c = String.valueOf(mynetpriceincl);
                    cerBiz.Customer_Currency__c = instceragrLI.APTS_Agreement_Line_Item__r.CurrencyIsoCode;
                    cerBiz.Base_unit_of_measure__c = uom;
                    cerBiz.Discount_in_customer_currency__c = String.valueOf(discountcus);
                    cerBiz.Indirect_tax_amount_in_customer_currency__c = String.valueOf(myindirecttaxamt);
                    cerBiz.Status__c = Status;
                    cerBiz.Load_Type__c = 'Full';

                    listCERBiz.add(cerBiz);
                    
                    system.debug('SOFI :'+limits.getHeapSize());
                    salesorg = '';
                    disChan = '';
                    uom='';
            //netpriceincl='';
            //indirecttaxamt='';
           // }
        }
            if(!listCERBiz.isEmpty()){
                insert listCERBiz;
            }
            
        }catch(Exception e){
                system.debug('exception occurred in **** ===> '+e);
                system.debug('e===> '+e.getLineNumber());
                APTS_CustomLogging.createErrorLog(e.getTypeName(),'Batch', e.getStackTraceString()+'::Line Number:'+e.getLineNumber() ,'APTS_Contract_Entitlement_Repository__c', '' ,'CPQ', False, False,'', true);
        }  
    
    }
    
    global void finish(Database.BatchableContext BC) {
            APTS_CERBizIslandExt prcAgain = new APTS_CERBizIslandExt();
            Database.executeBatch(prcAgain,200); 
            
            APTS_PurgeCERBizIslandBufferData deleteCERBiz = new APTS_PurgeCERBizIslandBufferData();
            Database.executeBatch(deleteCERBiz, 200);           
    }   
        
        
        
    }