/**
* Class Name : APTS_PricingDistributionBatch
* Description : Batch Apex Class to process Pricing Staging records and creates PLI, PM and PME records
* Author : Nagavi Babu/Lavanya Ravindran/Karan Khatri
* Date Created : 03/06/2018
**/
global with sharing class APTS_PricingDistributionBatch implements Database.Batchable<sObject>,Database.Stateful{

    private Static String EMPTY_STRING = ' ';
    public String query = APTS_PricingDistributionBatchHandler.getObjectQuery(Label.APTS_PricingStagingObject) + EMPTY_STRING + Label.APTS_PricingQuery;

    /** Method Name : start
    * Description : start method of Batch class
    **/
    global Database.QueryLocator start(Database.BatchableContext batchContext){
        System.debug('Query===> ' + query);
        System.debug('Query Result===> ' + Database.getQueryLocator(query));
        return Database.getQueryLocator(query);
    }

    /** Method Name : execute
    * Description : execute method of Batch class
    **/
    global void execute(Database.BatchableContext batchContext, List<APTS_Pricing_Staging__c> records){
        try{
        //Map<Id,String> pricingErrorMap2 = new Map<Id,String>();
        Map<string,String> pricingErrorMap = new Map<String,String>();
        Map<String,Product2> activeProductMap = new Map<String,Product2>();
        Map<String,APTS_Sales_Org_Data__c> activeSalesOrgPLMap = new Map<String,APTS_Sales_Org_Data__c>();
        Map<String,APTS_Sales_Org_Data__c> activeSalesOrgMap = new Map<String,APTS_Sales_Org_Data__c>();
        List<APTS_Sales_Org_Data__c> inactiveSalesOrgs = new List<APTS_Sales_Org_Data__c>();
        Map<String,Apttus_Config2__PriceListItem__c> prodToPLIMap = new Map<String,Apttus_Config2__PriceListItem__c>();
        Map<String,Apttus_Config2__PriceListItem__c> prodToPLIInactiveMap= new Map<String,Apttus_Config2__PriceListItem__c>();
        Map<String, List<Integer>> mapOfContractPeriods = new Map<String, List<Integer>>();
        Map<String, Map<String, Decimal>> mapOfListPrice = new Map<String, Map<String, Decimal>>();
        Map<Id,APTS_Pricing_Staging__c> processedPSMap = new Map<Id,APTS_Pricing_Staging__c>();
        Map<Id,Apttus_Config2__PriceListItem__c> InactivePLItoBeActivatedMap = new Map<Id,Apttus_Config2__PriceListItem__c>();
        Map<String, Apttus_Config2__PriceListItem__c> pliToBoUpsertedMap = new Map<String, Apttus_Config2__PriceListItem__c>();
        Map<Id, Apttus_Config2__PriceMatrix__c> existingPLIPMMap = new Map<Id, Apttus_Config2__PriceMatrix__c>();
        Map<Id, Apttus_Config2__PriceMatrix__c> existingPLPMMap = new Map<Id, Apttus_Config2__PriceMatrix__c>();  // Change of Lavanya
        Map<Apttus_Config2__PriceMatrix__c, Map<String, Apttus_Config2__PriceMatrixEntry__c>> existingPMPMEMap = new Map<Apttus_Config2__PriceMatrix__c, Map<String, Apttus_Config2__PriceMatrixEntry__c>>();
        Map<ID, Map<String, Apttus_Config2__PriceMatrixEntry__c>> newPMIdPMEMap = new Map<ID, Map<String, Apttus_Config2__PriceMatrixEntry__c>>();
        List<APTS_Pricing_Staging__c> serviceFeeStagingList = new List<APTS_Pricing_Staging__c>();
        map<Id,Apttus_Config2__PriceListItem__c> pliToBeDeactivated = new Map<id,Apttus_Config2__PriceListItem__c>();
        List<Apttus_Config2__PriceListItem__c> rentalPLIsToBeInserted = new List<Apttus_Config2__PriceListItem__c>();
        List<Apttus_Config2__PriceMatrixEntry__c> pMEToBeUpsertedList = new List<Apttus_Config2__PriceMatrixEntry__c>();
        List<Apttus_Config2__PriceMatrixEntry__c> PMISToBeDeleted = new List<Apttus_Config2__PriceMatrixEntry__c>();
        List<Apttus_Config2__PriceMatrixEntry__c> PMEList  = new List<Apttus_Config2__PriceMatrixEntry__c>();
        Set<String> relatedProductCodes = new Set<String>();
        Set<String> salesOrgCodes = new Set<String>();
        Set<String> processedPricing = new Set<String>();
        Set<Id> updatedPLISet=new Set<Id>();
        Set<String> transactionalUOMSSet = new Set<String>();
         List<Apttus_Config2__PriceMatrixEntry__c> priceMatrixEntryList = new List<Apttus_Config2__PriceMatrixEntry__c>();
        //Added for tax fields map update
        Map<string,APTS_Product_Replacement_Codes__c> relatedReplacementMap=new Map<string,APTS_Product_Replacement_Codes__c>();
        Map<ID,String> productProductCodeMap = new Map<ID,String>();
        Map<String, APTS_Tax_Pricing_Mapping__c> taxFieldMapCS = APTS_Tax_Pricing_Mapping__c.getAll();
        System.debug('********records============>'+records);
        for(APTS_Pricing_Staging__c staging : records){
            relatedProductCodes.add(staging.APTS_Product_Code__c);   
            salesOrgCodes.add(staging.APTS_Sales_Organization__c);
        }
        
        
        
        //Get the available products
        if(!relatedProductCodes.IsEmpty()){
            activeProductMap = APTS_PricingDistributionBatchHandler.mapOfProducts(relatedProductCodes);   
        }
        
        
        //Get the active and inactive Sales Orgs
        if(!salesOrgCodes.IsEmpty() && !activeProductMap.IsEmpty()){
            Set<String> prodIdSet = new Set<String>();
            prodIdSet.addAll(activeProductMap.keySet());

            String query = APTS_PricingDistributionBatchHandler.getObjectQuery(Label.APTS_SalesOrgDataObject)+Label.APTS_SalesOrgDataQuery;
            System.debug('SALES ORG query===>'+query);
            for(APTS_Sales_Org_Data__c sOrg : Database.query(query)){
                if(String.IsNotBlank(sOrg.APTS_Distribution_chain_specific_materia__c)){
                    activeSalesOrgPLMap.put(sOrg.APTS_Sales_Org_Data_Name__c, sOrg);  
                    activeSalesOrgMap.put(sOrg.APTS_Product_Code__c+sOrg.APTS_Sales_Org_Data_Name__c,sOrg);
                }else{
                    inactiveSalesOrgs.add(sOrg);
                }
            }
        }
        
        system.debug('############ activeSalesOrgMap '+activeSalesOrgMap);
        system.debug('############ activeSalesOrgPLMap '+activeSalesOrgPLMap);
        system.debug('############ inactiveSalesOrgs '+inactiveSalesOrgs);
        
        //Get available replacement product codes
        relatedReplacementMap=APTS_PricingDistributionBatchHandler.getReplacedRecords(activeProductMap,activeSalesOrgPLMap);
        
        //Added by Abhishek K to pull it out from For loop to Avoid too Many SOQL Errors
        prodToPLIInactiveMap = APTS_PricingDistributionBatchHandler.getExistingInactivePriceListItems(activeProductMap,activeSalesOrgPLMap);
        
        
        //Get the existing PLI -- Key is productcode+salesorg+chargetype
        prodToPLIMap = APTS_PricingDistributionBatchHandler.getExistingPriceListItems(activeProductMap,activeSalesOrgPLMap);
        system.debug('############ prodToPLIMap '+prodToPLIMap);
        
        existingPMPMEMap = APTS_PricingDistributionBatchHandler.getExistingPMsPMEs(prodToPLIMap.values());
        pliToBeDeactivated = APTS_PricingDistributionBatchHandler.processInactiveSalesOrg(inactiveSalesOrgs);
        existingPLPMMap = APTS_PricingDistributionBatchHandler.getExistingPLPM(prodToPLIMap.values()); // change of Lavanya 
                
        for(Apttus_Config2__PriceMatrix__c pM : existingPMPMEMap.keySet()){
            existingPLIPMMap.put(pM.Apttus_Config2__PriceListItemId__c, pM);
            if(newPMIdPMEMap.get(pm.id)==null){
                newPMIdPMEMap.put(pm.id,existingPMPMEMap.get(pm));
            }
        }
        
        //Update Tax related fields on price list items | Karan Khatri 
        Map<String,List<Apttus_Config2__PriceListItem__c>> prodCodePriceListItemsMap = APTS_PricingDistributionBatchHandler.createProductPriceListItemsMap(relatedProductCodes,salesOrgCodes);
         
        System.debug('activeProductMap=========>'+activeProductMap); 
        // Get the related records based on condition types
        for(APTS_Pricing_Staging__c pricing:records){
            
            String relatedPli = pricing.APTS_Product_Code__c+pricing.APTS_Sales_Organization__c+APTS_PricingDistributionBatchHandler.getChargeType(pricing.APTS_Condition_Type__c,pricing.APTS_Product_Code__c);
           
            String tempCode='';

            if(pricing.APTS_Price_Uom__c!=null){
                transactionalUOMSSet = APTS_PricingDistributionBatchHandler.getTransactableUOMs();
            }
            System.debug('transactionalUOMSSet==========>'+transactionalUOMSSet);
            if(!transactionalUOMSSet.isEmpty() && !transactionalUOMSSet.contains(pricing.APTS_Price_Uom__c)){
                processedPSMap.put(pricing.Id,pricing);
                pricingErrorMap.put(pricing.APTS_PLI_Unique_Identifier__c,'We cannot process Pricing Staging records where the Price UOM is a non transactable uom, and this value of ' + pricing.APTS_Price_Uom__c + ' cannot be processed, please re submit the Price to Apttus with a Transactable Price UOM value');
            }
            else{
            
            if(activeProductMap.containsKey(pricing.APTS_Product_Code__c)){
                tempCode=activeProductMap.get(pricing.APTS_Product_Code__c).ProductCode+pricing.APTS_Sales_Organization__c;
            }
            //check if there is matched product and the sales org is active
            System.debug('product code ===>'+pricing.APTS_Product_Code__c);
            System.debug('Active product code ===>'+activeProductMap.containsKey(pricing.APTS_Product_Code__c));
            System.debug('tempCode ===>'+tempCode);
            System.debug('activeSalesOrgMap.containsKey(tempCode)===>'+activeSalesOrgMap.containsKey(tempCode));
            if(activeProductMap.containsKey(pricing.APTS_Product_Code__c) && tempCode!='' && activeSalesOrgMap.containsKey(tempCode)){
                //processedPricing.add(relatedPli); //To check duplicates
                
                if(relatedReplacementMap.containsKey(pricing.APTS_Product_Code__c+pricing.APTS_Sales_Organization__c)){ 
                    String oldProductCode=relatedReplacementMap.get(pricing.APTS_Product_Code__c+pricing.APTS_Sales_Organization__c).APTS_Product_Code__c;
                    string oldRelatedPli=oldProductCode+pricing.APTS_Sales_Organization__c+APTS_PricingDistributionBatchHandler.getChargeType(pricing.APTS_Condition_Type__c);
                      
                    if(prodToPLIMap.containsKey(oldRelatedPli)){
                        Apttus_Config2__PriceListItem__c oldPli=prodToPLIMap.get(oldRelatedPli);
                        if(pliToBeDeactivated.get(oldPli.id)==null){
                            pliToBeDeactivated.put(oldPli.id,oldPli);
                        }
                    }
                }
          System.debug('**relpli'+relatedPli);
          System.debug('**relpli'+prodToPLIMap.keyset());
                if((pricing.APTS_Condition_Type__c == Label.APTS_YSF1 || pricing.APTS_Condition_Type__c == Label.APTS_Z000)&& !pricing.APTS_SAP_Deletion_Indicator__c){
                    
                    /*System.debug('IN ZOOO');
                    if(prodToPLIMap.containsKey(relatedPli)){
                       System.debug('EXISTING ZOOO');
                        Apttus_Config2__PriceListItem__c existingPLI = prodToPLIMap.get(relatedPli);
                        existingPLI = APTS_PricingDistributionBatchHandler.mapPLIFields(pricing, existingPLI, activeSalesOrgMap.get(tempCode), activeProductMap);
                        System.debug('List Price'+pricing.APTS_List_Price__c+existingPLI.Apttus_Config2__ListPrice__c);
                        
                        if(pricing.APTS_SAP_Deletion_Indicator__c == true || (pricing.APTS_Effective_Date__c== NULL && pricing.APTS_Expiration_Date__c== NULL)){                        
                         existingPLI .Apttus_Config2__Active__c = false;
                        existingPLI .Apttus_Config2__ExpirationDate__c = System.Now(); 
                        }
                        pliToBoUpsertedMap.put(existingPLI.APTS_Product_Code__c+existingPLI.APTS_Sales_Organization__c+existingPLI.Apttus_Config2__ChargeType__c, existingPLI);
                        processedPSMap.put(pricing.Id,pricing);
                    }else{
                        System.debug('NEW ZOOO');
                        Apttus_Config2__PriceListItem__c newPLI = new Apttus_Config2__PriceListItem__c();
                        newPLI = APTS_PricingDistributionBatchHandler.mapPLIFields(pricing, newPLI, activeSalesOrgMap.get(tempCode), activeProductMap);
                        System.debug('NEW PLI=====>'+newPLI);
                        if(pricing.APTS_SAP_Deletion_Indicator__c == true || (pricing.APTS_Effective_Date__c== NULL && pricing.APTS_Expiration_Date__c== NULL)){
                      
                         newPLI.Apttus_Config2__Active__c = false;
                        newPLI.Apttus_Config2__ExpirationDate__c = System.Now();
                       
        
                                }
                                
                            pliToBoUpsertedMap.put(relatedPli,newPLI);
                            System.debug('pliToBoUpsertedMap=====>'+pliToBoUpsertedMap);
                            processedPSMap.put(pricing.Id,pricing);
                        }    
                       
                    }*/
                     if(prodToPLIMap.containsKey(relatedPli)){
                        Apttus_Config2__PriceListItem__c existingPLI = prodToPLIMap.get(relatedPli);
                        existingPLI = APTS_PricingDistributionBatchHandler.mapPLIFields(pricing, existingPLI, activeSalesOrgMap.get(tempCode), activeProductMap);
                       pliToBoUpsertedMap.put(existingPLI.APTS_Product_Code__c+existingPLI.APTS_Sales_Organization__c+existingPLI.Apttus_Config2__ChargeType__c, existingPLI);
                        processedPSMap.put(pricing.Id,pricing);
                    }else{
                        Apttus_Config2__PriceListItem__c newPLI = new Apttus_Config2__PriceListItem__c();
                        newPLI = APTS_PricingDistributionBatchHandler.mapPLIFields(pricing, newPLI, activeSalesOrgMap.get(tempCode), activeProductMap);
                        pliToBoUpsertedMap.put(relatedPli,newPLI);
                        processedPSMap.put(pricing.Id,pricing);
                    }
                }else if((pricing.APTS_Condition_Type__c == Label.APTS_YSFL || pricing.APTS_Condition_Type__c == Label.APTS_YSFC || pricing.APTS_Condition_Type__c == Label.APTS_YSFS || taxFieldMapCS.keyset().contains(pricing.APTS_Condition_Type__c))&& !pricing.APTS_SAP_Deletion_Indicator__c){
                    //filter only valid pricing staging
                    APTS_Tax_Pricing_Mapping__c taxMapping;
                    if(!taxFieldMapCS.isEmpty() && taxFieldMapCS.get(pricing.APTS_Condition_Type__c)!=null){
                        taxMapping = taxFieldMapCS.get(pricing.APTS_Condition_Type__c);
                    }
                    /*System.debug('pricing.APTS_Condition_Type__c=====>'+pricing.APTS_Condition_Type__c);
                    System.debug('pricing.APTS_Price_Uom__c=====>'+pricing.APTS_Price_Uom__c);
                    System.debug('taxMapping.APTS_UOM_Supported__c=====>'+taxMapping.APTS_UOM_Supported__c);*/
                    if(taxMapping!=null && pricing.APTS_Condition_Type__c!=null && taxFieldMapCS.keyset().contains(pricing.APTS_Condition_Type__c) && pricing.APTS_Price_Uom__c!=null && taxMapping.APTS_UOM_Supported__c!=null && !taxMapping.APTS_UOM_Supported__c.equalsIgnoreCase(pricing.APTS_Price_Uom__c)){
                        if(pricingErrorMap.get(pricing.id)==null){
                            processedPSMap.put(pricing.Id,pricing);
                            pricingErrorMap.put(pricing.APTS_PLI_Unique_Identifier__c,'Pricing UOM doesnt match with expected UOM \n Record Pricing UOM : '+pricing.APTS_Price_Uom__c+'\n Expected Pricing UOM : '+taxMapping.APTS_UOM_Supported__c);
                        }
                    }else{
                        serviceFeeStagingList.add(pricing);
                    }
                    System.debug('pricing.APTS_Condition_Type__c=====>'+pricing.APTS_Condition_Type__c);
                    System.debug('pricingErrorMap=====>'+pricingErrorMap);
                    //processedPSMap.put(pricing.Id,pricing);
                }else if(pricing.APTS_Condition_Type__c == Label.APTS_YRF0 && !pricing.APTS_SAP_Deletion_Indicator__c){
                
                    String strContPeriod = pricing.APTS_Contract_Period__c;
                    System.debug('strContPeriod===> ' + strContPeriod);
                    if(String.isNotBlank(strContPeriod) && pricing.APTS_List_Price__c!=null && pricing.APTS_SAP_ListPriceUnits__c!=null){
                        Integer intCpNum = Integer.valueOf(strContPeriod.substring(5));

                        if(mapOfContractPeriods.containsKey(relatedPli)){
                            mapOfContractPeriods.get(relatedPli).add(intCpNum);
                        }else{
                            mapOfContractPeriods.put(relatedPli, new List<Integer> {intCpNum});
                        }

                        if(mapOfListPrice.containsKey(relatedPli) && mapOfListPrice.get(relatedPli)!=null) {
                            mapOfListPrice.get(relatedPli).put(pricing.APTS_Contract_Period__c, pricing.APTS_List_Price__c/pricing.APTS_SAP_ListPriceUnits__c);
                        }else{
                            mapOfListPrice.put(relatedPli, new Map<String, Decimal> {pricing.APTS_Contract_Period__c => pricing.APTS_List_Price__c/pricing.APTS_SAP_ListPriceUnits__c});
                        }
                        processedPSMap.put(pricing.Id,pricing);
                    }
                    
                                        
                    if(prodToPLIMap.containsKey(relatedPli)){ //Check if there is existing pli
                        Apttus_Config2__PriceListItem__c existingPLI = prodToPLIMap.get(relatedPli);
                        //updatedPLISet.add(existingPLI.Id);
                        if(!pliToBoUpsertedMap.containsKey(relatedPli)){ 
                            existingPLI = APTS_PricingDistributionBatchHandler.mapPLIFields(pricing, existingPLI, activeSalesOrgMap.get(tempCode), activeProductMap);
                            pliToBoUpsertedMap.put(relatedPli,existingPLI);
                            //updatedPLISet.add(existingPLI.Id);
                            processedPSMap.put(pricing.Id,pricing);
                        }
                        
                        /*if(existingPLPMMap.containsKey(existingPLI.Id)){ // Assuming rental PLi will always have PM linkeed to it
                       
                            Apttus_Config2__PriceMatrix__c tempPM = new Apttus_Config2__PriceMatrix__c();
                            Apttus_Config2__PriceMatrixEntry__c tempPME = new Apttus_Config2__PriceMatrixEntry__c();     
                            tempPM = existingPLPMMap.get(existingPLI.Id);
                            System.debug('Lavanya TempPM:-'+tempPM.id); 
                            System.debug('Lavanya Contract Period Data:-'+pricing.APTS_Contract_Period__c);  
                            System.debug('KARAN newPMIdPMEMap:-'+newPMIdPMEMap.containsKey(tempPM.id));
                            System.debug('KARAN newPMIdPMEMap:-'+newPMIdPMEMap.get(tempPM.id));
                            if(newPMIdPMEMap!= NULL && newPMIdPMEMap.containsKey(tempPM.id)){
                                if(newPMIdPMEMap.get(tempPM.id).containsKey(pricing.APTS_Contract_Period__c)){
                                                                     
                                    tempPME = APTS_PricingDistributionBatchHandler.mapPMEFields(pricing,existingPLI,newPMIdPMEMap.get(tempPM.id).get(pricing.APTS_Contract_Period__c),tempPM);
                                    System.debug('INSIDE CONTAINS'+tempPME);
                                    if(pricing.APTS_SAP_Deletion_Indicator__c == true || (pricing.APTS_Effective_Date__c== NULL && pricing.APTS_Expiration_Date__c== NULL)){      
                                        PMISToBeDeleted.add(tempPME);                                     
                                    }
                                    else{
                                    pMEToBeUpsertedList.add(tempPME);                                    
                                    processedPSMap.put(pricing.Id,pricing);}
                                }else{
                                
                                    tempPME = APTS_PricingDistributionBatchHandler.mapPMEFields(pricing,existingPLI,tempPME,tempPM);
                                    System.debug('INSIDE NOT CONTAINS'+tempPME);
                                    if(pricing.APTS_SAP_Deletion_Indicator__c == true || (pricing.APTS_Effective_Date__c== NULL && pricing.APTS_Expiration_Date__c== NULL)){      
                                    PMISToBeDeleted.add(tempPME);                                                                              
                                    }else{
                                    pMEToBeUpsertedList.add(tempPME);
                                   
                                    processedPSMap.put(pricing.Id,pricing);}
                                }
                            }
                        }*/
                        if(existingPLIPMMap.containsKey(existingPLI.Id)){ // Assuming rental PLi will always have PM linkeed to it
                            updatedPLISet.add(existingPLI.Id);
                            Apttus_Config2__PriceMatrix__c tempPM = new Apttus_Config2__PriceMatrix__c();
                            Apttus_Config2__PriceMatrixEntry__c tempPME = new Apttus_Config2__PriceMatrixEntry__c();
                                
                            tempPM = existingPLIPMMap.get(existingPLI.Id);
                                
                            if(existingPMPMEMap.get(tempPM).containsKey(pricing.APTS_Contract_Period__c)){
                                tempPME = existingPMPMEMap.get(tempPM).get(pricing.APTS_Contract_Period__c);
                                tempPME = APTS_PricingDistributionBatchHandler.mapPMEFields(pricing,existingPLI,tempPME,tempPM);
                                pMEToBeUpsertedList.add(tempPME);
                                processedPSMap.put(pricing.Id,pricing);
                            }else{
                                tempPME = APTS_PricingDistributionBatchHandler.mapPMEFields(pricing,existingPLI,tempPME,tempPM);
                                pMEToBeUpsertedList.add(tempPME);
                                processedPSMap.put(pricing.Id,pricing);
                            }
                        }
   
                    }else if(!pliToBoUpsertedMap.containsKey(relatedPli)){
                       
                        Apttus_Config2__PriceListItem__c newPLI = new Apttus_Config2__PriceListItem__c();
                        newPLI = APTS_PricingDistributionBatchHandler.mapPLIFields(pricing, newPLI, activeSalesOrgMap.get(tempCode), activeProductMap);
                        pliToBoUpsertedMap.put(relatedPli,newPLI);
                         
                        processedPSMap.put(pricing.Id,pricing);
                    }           
                }
                        
            }
            //checks if pricing staging contains any of the tax condition types | Filter criteria | Karan Khatri - END    
            
            // Commented by Abhishek K to put it outside For Loop
            //prodToPLIInactiveMap = APTS_PricingDistributionBatchHandler.getExistingInactivePriceListItems(activeProductMap,activeSalesOrgPLMap);
            /*if(pricing.APTS_SAP_Deletion_Indicator__c == false && (pricing.APTS_Effective_Date__c<= System.today() && pricing.APTS_Expiration_Date__c > System.today()))           {
                
                if(pricing.APTS_Condition_Type__c == Label.APTS_YRF0)
                {

                    System.debug('Batch Rental Reverse');
                    List<Apttus_Config2__PriceMatrix__c> pmList = new List<Apttus_Config2__PriceMatrix__c>();
                    List<Apttus_Config2__PriceListItem__c> pliList =  new List<Apttus_Config2__PriceListItem__c>();
                    List<Integer> conPeriodList = new List<Integer>();
                    Map<String, List<Integer>> mapOfContract= new Map<String, List<Integer>>();
                    Map<String, Map<String, Decimal>>  mapOfLP= new Map<String, Map<String, Decimal>>();
                    Map<String, Decimal> listPriceMap = new Map<String, Decimal>();

                    //for rental create Price Matrices 
                    Apttus_Config2__PriceListItem__c instpli = prodToPLIMap.get(relatedPli);
                    if(!existingPLPMMap.isEmpty())
                    {
                       pmList.add(existingPLPMMap.get(instpli.Id));
                       pliList.add(instpli);                
                       conPeriodList = mapOfContractPeriods.get(relatedPli);
                       listPriceMap = mapOfListPrice.get(relatedPli);
                       mapOfContract.put(relatedPli,conPeriodList);
                       mapOfLP.put(relatedPli,listPriceMap);
                       System.debug('Batch Rental Dta'+pmList+'pli'+pliList+'mapOfContract'+mapOfContract+'mapOfLP'+mapOfLP);
                       PMEList = APTS_PricingDistributionBatchHandler.createPriceMatrixEntry(pmList,pliList,mapOfContract,mapOfLP);
                       System.debug('Batch Final Insertion Dta'+PMEList);
                    }

                }
                if(pricing.APTS_Condition_Type__c == Label.APTS_YSF1 || pricing.APTS_Condition_Type__c == Label.APTS_Z000){   
                    for(Apttus_Config2__PriceListItem__c instpli : prodToPLIInactiveMap.values()){ 
                        System.debug('Batch Sales/Service  Reverse');
                        instpli.Apttus_Config2__Active__c= true;
                        InactivePLItoBeActivatedMap.put(instpli.id,instpli);
                    }   
                }
            }*/
            if(pricing.APTS_SAP_Deletion_Indicator__c || (pricing.APTS_Effective_Date__c== NULL && pricing.APTS_Expiration_Date__c== NULL) || (pricing.APTS_Expiration_Date__c <= System.today())){
                System.debug('prodToPLIMap=======>'+prodToPLIMap);
                System.debug('existingPLPMMap=======>'+existingPLPMMap);
                System.debug('newPMIdPMEMap=======>'+newPMIdPMEMap);
                System.debug('relatedPli====>'+relatedPli);
                if(pricing.APTS_Condition_Type__c == Label.APTS_YRF0 && !prodToPLIMap.isEmpty() && !existingPLPMMap.isEmpty() && !newPMIdPMEMap.isEmpty()){
                    //Apttus_Config2__PriceListItem__c instpli = pliToBoUpsertedMap.get(relatedPli);
                    Apttus_Config2__PriceMatrix__c tempPM = new Apttus_Config2__PriceMatrix__c();
                    Apttus_Config2__PriceListItem__c existingPLI;
                    if(prodToPLIMap.get(relatedPli)!=null){   
                        existingPLI = prodToPLIMap.get(relatedPli); 
                        if(existingPLI!=null && existingPLPMMap.get(existingPLI.Id)!=null){
                            tempPM = existingPLPMMap.get(existingPLI.Id);
                        }
                    }
                    System.debug('instpli SDI##YRFO:-'+tempPM);
                    System.debug('existingPLI  SDI##YRFO:-'+existingPLI);
                    System.debug('Lavanya TempPM SDI##YRFO:-'+tempPM.id); 
                    System.debug('Lavanya Contract Period Data SDI##YRFO:-'+pricing.APTS_Contract_Period__c);  
                    System.debug('KARAN newPMIdPMEMap SDI##YRFO:-'+newPMIdPMEMap.containsKey(tempPM.id));
                    System.debug('KARAN newPMIdPMEMap SDI##YRFO:-'+newPMIdPMEMap.get(tempPM.id));
                    if(tempPM!=null && !newPMIdPMEMap.isEmpty() && newPMIdPMEMap.get(tempPM.id)!=null && pricing.APTS_Contract_Period__c!=null && newPMIdPMEMap.get(tempPM.id).get(pricing.APTS_Contract_Period__c)!=null){                              
                        System.debug('EXISTING PMs===SDI##YRFO===>'+newPMIdPMEMap.get(tempPM.id).get(pricing.APTS_Contract_Period__c));   
                        PMISToBeDeleted.add(newPMIdPMEMap.get(tempPM.id).get(pricing.APTS_Contract_Period__c));                         
                        processedPSMap.put(pricing.Id,pricing);
                    }   
                }
                if((pricing.APTS_Condition_Type__c == Label.APTS_YSF1 || pricing.APTS_Condition_Type__c == Label.APTS_Z000) && !prodToPLIMap.isEmpty()){   
                    System.debug('Batch Sales/Service  Reverse');
                    System.debug('pliToBoUpsertedMap.get(relatedPli)==SDI##ZOOO/YSF1===>'+pliToBoUpsertedMap.get(relatedPli));
                    if(prodToPLIMap.get(relatedPli)!=null){
                        //Apttus_Config2__PriceListItem__c instpli = pliToBoUpsertedMap.get(relatedPli);
                        Apttus_Config2__PriceListItem__c instpli = prodToPLIMap.get(relatedPli);
                        if(pliToBeDeactivated.get(instpli.id)==null){
                            pliToBeDeactivated.put(instpli.id,instpli);
                        }
                    }
                    System.debug('pliToBeDeactivated===>'+pliToBeDeactivated);
                    processedPSMap.put(pricing.Id,pricing);
                }   
            }
        }
        System.debug('Batch InactivePLItoBeActivatedMap =========>'+InactivePLItoBeActivatedMap);
           
        }
        System.debug('pliToBoUpsertedMap======FIRST===========>'+pliToBoUpsertedMap);
        System.debug('prodToPLIMap======FIRST===========>'+prodToPLIMap);
        //Update the list price on rental PLI with the lowest contract period price
        pliToBoUpsertedMap=APTS_PricingDistributionBatchHandler.updateLowestContractPeriodPrice(prodToPLIMap,pliToBoUpsertedMap,mapOfContractPeriods,mapOfListPrice);
        System.debug('pliToBoUpsertedMap======SECOND===========>'+pliToBoUpsertedMap);
        System.debug('prodToPLIMap======SECOND===========>'+prodToPLIMap);
        System.debug('serviceFeeStagingList===========>'+serviceFeeStagingList);
        // process the pricing staging for YSFL/YSFC/YSFS condition types
        if(!serviceFeeStagingList.IsEmpty()){
            pliToBoUpsertedMap=APTS_PricingDistributionBatchHandler.processServicePS(serviceFeeStagingList, pliToBoUpsertedMap, prodToPLIMap,activeSalesOrgMap,activeProductMap);
        }
        System.debug('pliToBoUpsertedMap======THIRD===========>'+pliToBoUpsertedMap);
        System.debug('prodToPLIMap======THIRD===========>'+prodToPLIMap);
       //Add coverage field changes for Sales and Rental PLIs if any of them already exists | Karan Khatri | 22/6
        for(Apttus_Config2__PriceListItem__c pricelistItem : prodToPLIMap.values()){
            if(pricelistItem.id!=null && pricelistItem.Apttus_Config2__ProductId__c!=null && pricelistItem.Apttus_Config2__ProductCode__c!=null && productProductCodeMap.get( pricelistItem.Apttus_Config2__ProductId__c)==null){
                productProductCodeMap.put(pricelistItem.Apttus_Config2__ProductId__c,pricelistItem.Apttus_Config2__ProductCode__c);
            }
        }
        Map<ID,Apttus_Config2__FrequencyConversionRate__c> uomConversionMap= new Map<ID,Apttus_Config2__FrequencyConversionRate__c>();
        for( Apttus_Config2__FrequencyConversionRate__c freqConversion : [select id,Apttus_Config2__FromUom__c,Apttus_Config2__ToUom__c,Apttus_Config2__ProductFamily__c,Apttus_Config2__ConversionFactor__c,Apttus_Config2__ProductId__c,APTS_ProductCode__c from Apttus_Config2__FrequencyConversionRate__c where APTS_ProductCode__c IN: productProductCodeMap.values() limit 50000]){
            if(uomConversionMap.get(freqConversion.id)==null){
                uomConversionMap.put(freqConversion.id,freqConversion);
            }
        }

        System.debug('NEEDED pliToBoUpsertedMap'+pliToBoUpsertedMap);
        System.debug('# # #productProductCodeMap===============>'+productProductCodeMap);
        for(Apttus_Config2__PriceListItem__c cPricelistItem : pliToBoUpsertedMap.values()){
            System.debug('cPricelistItem===>'+cPricelistItem);
            System.debug('prodToPLIMap============>'+prodToPLIMap);
            System.debug('cPricelistItem==CT=>'+cPricelistItem.Apttus_Config2__ChargeType__c);
            if(cPricelistItem.Apttus_Config2__ChargeType__c==Label.APTS_Rental_Price || cPricelistItem.Apttus_Config2__ChargeType__c==Label.APTS_Sales_Price){
                System.debug('cPricelistItem.APTS_Sales_Organization__c===>'+cPricelistItem.APTS_Sales_Organization__c);
                System.debug('cPricelistItem.Apttus_Config2__ProductId__c===>'+cPricelistItem.Apttus_Config2__ProductId__c);
                if(!prodToPLIMap.isEmpty() && !productProductCodeMap.isEmpty() && cPricelistItem.APTS_Sales_Organization__c!=null && productProductCodeMap.get(cPricelistItem.Apttus_Config2__ProductId__c)!=null){
                    Apttus_Config2__PriceListItem__c priceListItem;
                    String productCode = productProductCodeMap.get(cPricelistItem.Apttus_Config2__ProductId__c);
                    System.debug('productCode===>'+productCode);
                    IF(cPricelistItem.Apttus_Config2__ChargeType__c==Label.APTS_Rental_Price){
                        priceListItem = prodToPLIMap.get(productCode+cPricelistItem.APTS_Sales_Organization__c+Label.APTS_Sales_Price);
                    }else{
                        priceListItem = prodToPLIMap.get(productCode+cPricelistItem.APTS_Sales_Organization__c+Label.APTS_Rental_Price);
                    }
                    System.debug('priceListItem==SP==>'+priceListItem);
                    if(priceListItem!=null){
                        //if New Service PLI then pick coverage fields frome existing Sales PLI
                        cPricelistItem.APTS_Call_Out_Coverage__c=priceListItem.APTS_Call_Out_Coverage__c;
                        cPricelistItem.APTS_Labour_Coverage__c=priceListItem.APTS_Labour_Coverage__c;
                        cPricelistItem.APTS_Spare_Parts_Coverage__c=priceListItem.APTS_Spare_Parts_Coverage__c;
                        cPricelistItem.APTS_TAX_all_countries_UOM__c=0;
                        cPricelistItem.APTS_TAX_DK_specific_UOM__c=0;
                        cPricelistItem.APTS_Tax_per_UOM__c=0;
                        cPricelistItem.APTS_TXP_Cappuccino_Tax_Mixed__c=0;
                        cPricelistItem.APTS_TXP_Chocolate_Tax__c=0;
                        cPricelistItem.APTS_TXP_Coffee_Tax__c=0;
                        cPricelistItem.APTS_TXP_Disposable_Tableware__c=0;
                        cPricelistItem.APTS_TXP_Disposal_Fee__c=0;
                        cPricelistItem.APTS_TXP_Instant_Coffee_Tax__c=0;
                        cPricelistItem.APTS_TXP_Liquid_Coffee_Tax__c=0;
                        cPricelistItem.APTS_TXP_Recycle_Con_Pack_Tax__c=0;
                        cPricelistItem.APTS_TXP_Tea_Tax__c=0;
                        cPricelistItem.APTS_TXP_Belgian_GSV__c=0;
                        //Copying tax fields as well
                        for(APTS_Tax_Pricing_Mapping__c taxfield : taxFieldMapCS.values()){
                            cPricelistItem.put(taxfield.APTS_Tax_field_on_price_list_item__c,priceListItem.get(taxfield.APTS_Tax_field_on_price_list_item__c));
                        }

                        if(cPricelistItem.Apttus_Config2__ChargeType__c==APTS_CPQConstants.RENTAL_FEE){
                            cPricelistItem.APTS_TXP_Disposal_Fee__c=0;
                        }
                        System.debug('cPricelistItem====>'+cPricelistItem);
                        System.debug('cPricelistItem.APTS_TXP_Recycle_Con_Pack_Tax__c====>'+cPricelistItem.APTS_TXP_Recycle_Con_Pack_Tax__c);
                        System.debug('cPricelistItem.APTS_TXP_Disposal_Fee__c====>'+cPricelistItem.APTS_TXP_Disposal_Fee__c);
                        System.debug('conversion====>'+APTS_CalculateTaxesCtrl.getConversionRate(uomConversionMap,APTS_CPQConstants.PIECE_UOM_API,cPricelistItem.Apttus_Config2__PriceUom__c,productCode));
                        //Additional tax fields to copy
                        if(APTS_CalculateTaxesCtrl.getConversionRate(uomConversionMap,APTS_CPQConstants.PIECE_UOM_API,cPricelistItem.Apttus_Config2__PriceUom__c,productCode)!=null){
                            cPricelistItem.APTS_TAX_all_countries_UOM__c = (cPricelistItem.APTS_TXP_Recycle_Con_Pack_Tax__c + cPricelistItem.APTS_TXP_Disposal_Fee__c + cPricelistItem.APTS_TXP_Belgian_GSV__c) * APTS_CalculateTaxesCtrl.getConversionRate(uomConversionMap,APTS_CPQConstants.PIECE_UOM_API,cPricelistItem.Apttus_Config2__PriceUom__c,productCode);
                        }
                        System.debug('coffee tax====>'+cPricelistItem.APTS_TXP_Coffee_tax__c);
                        System.debug('productCode====>'+productCode);
                        System.debug('cPricelistItem.Apttus_Config2__PriceUom__c====>'+cPricelistItem.Apttus_Config2__PriceUom__c);
                        System.debug('conversion====>'+APTS_CalculateTaxesCtrl.getConversionRate(uomConversionMap,cPricelistItem.Apttus_Config2__PriceUom__c,APTS_CPQConstants.KG_UOM_API,productCode));
                        if(APTS_CalculateTaxesCtrl.getConversionRate(uomConversionMap,cPricelistItem.Apttus_Config2__PriceUom__c,APTS_CPQConstants.KG_UOM_API,productCode)!=null && APTS_CalculateTaxesCtrl.getConversionRate(uomConversionMap,cPricelistItem.Apttus_Config2__PriceUom__c,APTS_CPQConstants.KG_UOM_API,productCode)!=0){
                            cPricelistItem.APTS_TAX_DK_specific_UOM__c = (cPricelistItem.APTS_TXP_Coffee_tax__c + cPricelistItem.APTS_TXP_Instant_coffee_tax__c + cPricelistItem.APTS_TXP_Liquid_coffee_tax__c + cPricelistItem.APTS_TXP_Tea_tax__c + cPricelistItem.APTS_TXP_Chocolate_tax__c + cPricelistItem.APTS_TXP_Disposable_tableware__c + cPricelistItem.APTS_TXP_Cappuccino_tax_mixed__c) / APTS_CalculateTaxesCtrl.getConversionRate(uomConversionMap,cPricelistItem.Apttus_Config2__PriceUom__c,APTS_CPQConstants.KG_UOM_API,productCode);
                        }
                        cPricelistItem.APTS_Tax_per_UOM__c = cPricelistItem.APTS_TAX_all_countries_UOM__c + cPricelistItem.APTS_TAX_DK_specific_UOM__c;
                    }
                }
            }
        }
        //Process price list item of inactive sales Org
        if(!pliToBeDeactivated.IsEmpty()){
            List<Apttus_Config2__PriceListItem__c> deactivatedPLIsList = APTS_PricingDistributionBatchHandler.deactivatePLIs(pliToBeDeactivated.values());
            List<Database.UpsertResult> upsertResultList = Database.upsert(deactivatedPLIsList,Apttus_Config2__PriceListItem__c.fields.APTS_PriceListItemExtId__c,false);
            pricingErrorMap = APTS_PricingDistributionBatchHandler.processPLIUpsertResult(upsertResultList,pricingErrorMap,deactivatedPLIsList); 
        }
        System.debug('PMISToBeDeleted=============>'+PMISToBeDeleted);
        //Delete PriceMatrices which has SAPDeletionFlag enabled 
        if(!PMISToBeDeleted.IsEmpty()){
             Database.DeleteResult[] deleteList = Database.delete(PMISToBeDeleted,false);
             /**for(Database.DeleteResult dr : deleteList) {
                 if(!dr.IsSuccess())
                 {
                     System.debug('Error in Deletion'+dr);
                 }
                 
             }**/
        }


        if(!PMEList.isEmpty()){
            Database.UpsertResult[] updateList = Database.upsert(PMEList,false);
             /**for(Database.UpsertResult instupdate : updateList) {
                 if(!instupdate.IsSuccess())
                 {
                     System.debug('Error in Updation'+instupdate);
                 }
                 
             }**/
        }
        //System.debug('pli1'+pliToBoUpsertedMap.values().get(0));
        //Updating the Charge Type Criteria value of Option Products
        pliToBoUpsertedMap = APTS_PricingDistributionBatchHandler.updateCTC(activeProductMap, pliToBoUpsertedMap, prodToPLIMap);
        
        pliToBoUpsertedMap = APTS_PricingDistributionBatchHandler.updateActiveFlagOnPLI(pliToBoUpsertedMap,pliToBeDeactivated);
        System.debug('*********pliToBoUpsertedMap===========>'+pliToBoUpsertedMap);
        //Perform the DML and capture error logs
        if(!pliToBoUpsertedMap.IsEmpty()){
        System.debug('pli12'+pliToBoUpsertedMap.values().get(0));
        
            List<Database.UpsertResult> upsertResultList = Database.upsert(pliToBoUpsertedMap.values(),Apttus_Config2__PriceListItem__c.fields.APTS_PriceListItemExtId__c, false);
            pricingErrorMap = APTS_PricingDistributionBatchHandler.processPLIUpsertResult(upsertResultList,pricingErrorMap,pliToBoUpsertedMap.values());
           // upsert pliToBoUpsertedMap.values();
        }

        if(!InactivePLItoBeActivatedMap.isEmpty()){
            Database.UpsertResult[] updateList = Database.upsert(InactivePLItoBeActivatedMap.values(),false);
             /**for(Database.UpsertResult instupdate : updateList) {
                 if(!instupdate.IsSuccess()){
                     System.debug('Error in Updation'+instupdate);
                 }
             }**/

        }
        
        for(Apttus_Config2__PriceListItem__c pLI : pliToBoUpsertedMap.values()){
            if(pLI.Apttus_Config2__ChargeType__c == Label.APTS_Rental_Price && !updatedPLISet.contains(pLI.Id)){
                rentalPLIsToBeInserted.add(pLI);
            }
        }

        //For Rental PLIs, create Price Matrix records
        if(!rentalPLIsToBeInserted.isEmpty()){
            List<Apttus_Config2__PriceMatrix__c> priceMatrixList = APTS_PricingDistributionBatchHandler.createPriceMatrix(rentalPLIsToBeInserted);
            System.debug('****priceMatrixList===>'+priceMatrixList);
            if(!priceMatrixList.IsEmpty()){
                List<Database.UpsertResult> upsertResultList = Database.upsert(priceMatrixList, Apttus_Config2__PriceMatrix__c.Fields.APTS_PriceMatrixExtId__c, false);
                pricingErrorMap = APTS_PricingDistributionBatchHandler.processPMUpsertResult(upsertResultList,pricingErrorMap,priceMatrixList);
            }
            System.debug('****mapOfContractPeriods===>'+mapOfContractPeriods);
            System.debug('****mapOfListPrice===>'+mapOfListPrice);
            //For Rental PLIs, create Price Matrix Entry records
            priceMatrixEntryList = APTS_PricingDistributionBatchHandler.createPriceMatrixEntry(priceMatrixList, rentalPLIsToBeInserted, mapOfContractPeriods, mapOfListPrice);
        }
        if(!pMEToBeUpsertedList.isEmpty()){
            priceMatrixEntryList.addAll(pMEToBeUpsertedList);
        }
        System.debug('****priceMatrixEntryList===>'+priceMatrixEntryList);
        if(!priceMatrixEntryList.IsEmpty()){
            List<Database.UpsertResult> upsertResultList = Database.upsert(priceMatrixEntryList, false);
            pricingErrorMap = APTS_PricingDistributionBatchHandler.processPMEUpsertResult(upsertResultList,pricingErrorMap,priceMatrixEntryList);
        }
        
        
        
        List<APTS_Pricing_Staging__c> stagingUpdateList = new List<APTS_Pricing_Staging__c>();
        for(APTS_Pricing_Staging__c staging : processedPSMap.values()){
            staging.APTS_Process_Status__c = (pricingErrorMap.containsKey(staging.APTS_PLI_Unique_Identifier__c)) ? Label.APTS_Processed_with_Error : Label.APTS_Processed;
            stagingUpdateList.add(staging);
        }

        if(!stagingUpdateList.isEmpty()){
            //try{
                Database.update(stagingUpdateList, false);
            //}catch(Exception ex){}
        }
        
        //List<APTS_Batch_Error__c> errorsToInsert = APTS_PricingDistributionBatchHandler.insertBatchErrors(pricingErrorMap);
        
        //if(!errorsToInsert.IsEmpty()){
            //try{
                System.debug('pricingErrorMap===FINAL===>'+pricingErrorMap);
                Database.insert(APTS_PricingDistributionBatchHandler.insertBatchErrors(pricingErrorMap), false);
            //}catch(Exception ex){}
        //}
        
        }catch(Exception e)
        {
       APTS_CustomLogging.createErrorLog(e.getTypeName(), APTS_CPQConstants.APEX_NAME, e.getStackTraceString() ,'APTS_PricingDistributionBatchHandler', APTS_CPQConstants.EXCEPTION_ID, APTS_CPQConstants.CPQ,false,true,APTS_CPQConstants.CPQ_ERROR_EMAIL,true);        
        }
    }

    /** Method Name : finish
    * Description : finish method of Batch class
    **/
    global void finish(Database.BatchableContext batchContext){
    try{
        //Run Apttus Maintenance Batches
        APTS_PricingDistributionBatchHandler.runMaintenanceBatches();
        
        //Send email to the admin in case of failures in the DML operation
        AsyncApexJob asyncJob = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems FROM AsyncApexJob WHERE Id =: batchContext.getJobId()];
        if(asyncJob != null && asyncJob.NumberOfErrors > 0){
            APTS_PricingDistributionBatchHandler.sendEmail(asyncJob);
        }
         }catch(Exception e)
        {
       APTS_CustomLogging.createErrorLog(e.getTypeName(), APTS_CPQConstants.APEX_NAME, e.getStackTraceString() ,'APTS_PricingDistributionBatchHandler', APTS_CPQConstants.EXCEPTION_ID, APTS_CPQConstants.CPQ,false,true,APTS_CPQConstants.CPQ_ERROR_EMAIL,true);        
        }
    }

}