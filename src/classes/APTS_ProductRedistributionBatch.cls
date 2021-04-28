/**
* Class Name : APTS_ProductRedistributionBatch
* Description :  Batch Apex Class to process multiple Objects related to Product2 whenever the product2 records 
                 are upserted in Product2 object from SAP
                    
* Author : V. Shankaranarayanan/Nagavi Babu
* Date Created : 02/23/2018
**/
global class APTS_ProductRedistributionBatch implements Database.Batchable<sObject>,Database.Stateful{// with sharing

    private Static String EMPTY_STRING = ' ';
    public Map<Id, String> prodErrorMap = new Map<Id,String>();
    public List<Id> productIdList = new List<Id>();
    
    public String query = APTS_ProductRedistributionBatchHandler.getObjectQuery(Label.Apttus_CPQAdmin.Product2) +EMPTY_STRING +label.APTS_Sub_Query_For_Product;
    
    /** Method Name : start
    * Description : start method of Batch class
    **/
    global Database.QueryLocator start(Database.BatchableContext batchContext){
        return Database.getQueryLocator(query);
    }

    /** Method Name : execute
    * Description : execute method of Batch class
    **/
    global void execute(Database.BatchableContext batchContext, List<Product2> records){
        try
        {
        Set<Id> prodsToDelinkSet = new Set<Id>();
        Map<Id,Product2> activeProductMap = new Map<Id,Product2>();
        Map<Id,Product2> allProductMap = new Map<Id,Product2>();
        Set<String> offeringCodesSet = new set<String>();
        Set<String> optionCodesSet = new set<String>();
        List<Apttus_Config2__ProductClassification__c> prodClassUpdateList = new List<Apttus_Config2__ProductClassification__c>();
        Map<Id,List<APTS_Batch_Error__c>> batchErrorsMap=new Map<Id,List<APTS_Batch_Error__c>>();
        List<APTS_Batch_Error__c> batchErrorsList=new List<APTS_Batch_Error__c>();
        Map<String, Product2> productCodeProductMap = new Map<String, Product2>();
        List<Product2> prodToBeUpdated=new List<Product2>();
        
        for(Product2 prod : records){
            //Boolean isEligible=true;
            if(allProductMap.get(prod.id)==null){
                allProductMap.put(prod.Id, prod);
            }
            if(prod.APTS_Cross_plant_material_status__c!=null){
                if(productCodeProductMap.get(prod.ProductCode)==null){
                    productCodeProductMap.put(prod.ProductCode, prod);
                }
            }
            prod.Apttus_Config2__BundleInvoiceLevel__c='';
             
            if(prod.APTS_Cross_plant_material_status__c!=system.label.APTS_HI){ 
            //if(prod.APTS_Cross_plant_material_status__c!=null){    
                prod.isActive=true;
                Boolean isEligible=True;
                // Added by Hari to Fix defect 
                if(prod.APTS_Sales_Catalog__c == '00' && prod.APTS_Option_Group_Indicator__c != '00'){
                    prod.Apttus_Config2__HasAttributes__c = True;
                }
                
                if(prod.APTS_Sales_Catalog__c != '00' && prod.APTS_Option_Group_Indicator__c == '00'){
                    prod.Apttus_Config2__HasAttributes__c = False;
                }
                //if(prod.APTS_Option_Group_Indicator__c!=null && prod.APTS_Option_Group_Indicator__c != '00'){
                //    prod.Apttus_Config2__BundleInvoiceLevel__c='Detail';
                //}
                //Set the product attribute values for active products
                if(prod.APTS_Material_Type__c == Label.APTS_ZCMA){
                    prod.Apttus_Config2__HasAttributes__c = true;
                    prod.Apttus_Config2__HasOptions__c = true;
                    prod.Apttus_Config2__Customizable__c=true;
                    prod.Apttus_Config2__BundleInvoiceLevel__c='Detail';
                    prod.Apttus_Config2__ConfigurationType__c=Label.Apttus_Config2.Bundle;
                    
                }
                else if(prod.APTS_Material_Type__c==Label.APTS_ZOPT || prod.APTS_Material_Type__c==Label.APTS_ZCBB){
                    prod.Apttus_Config2__HasAttributes__c = true;
                    //prod.Apttus_Config2__BundleInvoiceLevel__c=Label.Apttus_Config2.Bundle;
                    prod.Apttus_Config2__ConfigurationType__c=Label.Apttus_Config2.Option;
                }
                else if(prod.APTS_Material_Type__c==Label.APTS_ZFIN || prod.APTS_Material_Type__c==Label.APTS_ZSER || prod.APTS_Material_Type__c==Label.APTS_ZSPR || prod.APTS_Material_Type__c==Label.APTS_ZSRV ){
                    prod.Apttus_Config2__ConfigurationType__c=Label.APTS_Standalone;
                }
                
                else{ //If the material type is not valid , insert batch error and stop the processing of the product
                    isEligible=False;
                    batchErrorsMap=APTS_ProductRedistributionBatchHandler.insertBatchErrors(batchErrorsMap,prod.Id,Label.APTS_Material_Type_Error,Label.APTS_Error_In_Material_Type);
                    prod.APTS_Upserted_from_SAP__c=False;
                    prod.APTS_BatchProcess_Status__c=Label.APTS_Processed_with_Error;
                    prodToBeUpdated.add(prod); 
                }
                
                if(isEligible){
                    if(prod.APTS_Sales_Catalog__c != null){
                            
                        if(prod.APTS_Sales_Catalog__c.startsWith(system.label.APTS_04_Value)&&prod.APTS_Material_Type__c!='ZFIN'&&prod.APTS_Sales_Catalog__c!='0406'){
                                prod.Apttus_Config2__Customizable__c=true;
                        }
                        offeringCodesSet.add(prod.APTS_Sales_Catalog__c);
                    }
                    if(prod.APTS_Option_Group_Indicator__c != null){
                        optionCodesSet.add(prod.APTS_Option_Group_Indicator__c);
                     
                    }
                    if(prod.APTS_Conversion_Option_Indicator__c!= null){
                    
                        optionCodesSet.add(prod.APTS_Conversion_Option_Indicator__c);
                    //Added by Abhishek K 
                    }
                    activeProductMap.put(prod.Id, prod);//To be updated in the end
                }
               
            }
            else{ // If the cross plant material status is not valid, keep the product inactive
                prod.isActive=false;
                prod.APTS_Upserted_from_SAP__c=False;
                prod.APTS_BatchProcess_Status__c=system.label.APTS_Processed;
                prodToBeUpdated.add(prod);
            }
            
        }
        
        //Set the associated active/valid sales org for the active products
        activeProductMap = APTS_ProductRedistributionBatchHandler.processSalesOrgData(activeProductMap);
                     
        //Process Category Hierarchy related records and get the records to be upserted
        batchErrorsMap=APTS_ProductRedistributionBatchHandler.processCategoryHierarchy(batchErrorsMap,offeringCodesSet,optionCodesSet,activeProductMap);
        
        //Process Product Group and get the records to be upserted
        batchErrorsMap=APTS_ProductRedistributionBatchHandler.processProductGroup(batchErrorsMap,activeProductMap);
        
        //Process product attribute group and get the records to be upserted
        batchErrorsMap=APTS_ProductRedistributionBatchHandler.processProductAttributeGroups(batchErrorsMap,activeProductMap);
        
        //Process Frequency/UOM Conversion Rate and get the records to be updated
        batchErrorsMap = APTS_ProductRedistributionBatchHandler.updateFreqConversionRate(batchErrorsMap,allProductMap,productCodeProductMap);
        
        //Process Product Translations and get the records to be updated
        batchErrorsMap = APTS_ProductRedistributionBatchHandler.UpdateProdTranslationWithProdId(batchErrorsMap,allProductMap,productCodeProductMap);
                        
        //Update the product object after checking for errors and processing the products
        activeProductMap=APTS_ProductRedistributionBatchHandler.updateProducts(batchErrorsMap,activeProductMap);
        prodToBeUpdated.addAll(activeProductMap.Values());
        
       
        // Update the products
        Database.SaveResult[] srList = Database.update(prodToBeUpdated,false);
        batchErrorsMap=APTS_ProductRedistributionBatchHandler.getErrorDetailsForProduct(srList,batchErrorsMap,label.APTS_Product_Error,prodToBeUpdated);
        
        // insert the batch errors
        if(batchErrorsMap.size()>0){
            for(Id prodId : batchErrorsMap.KeySet()){
                batchErrorsList.addAll(batchErrorsMap.get(prodId));   
                
            }
            Database.insert(batchErrorsList);
        }
        
        Set<Id> idSet = new Set<Id>();
        idSet.addAll(activeProductMap.keySet());
        productIdList.addAll(idSet);
               }catch(Exception e){
        APTS_CustomLogging.createErrorLog(e.getTypeName(), APTS_CPQConstants.APEX_NAME, e.getStackTraceString() ,'ProductRedistributionBatch', APTS_CPQConstants.EXCEPTION_ID, APTS_CPQConstants.CPQ,false,false,APTS_CPQConstants.CPQ_ERROR_EMAIL,true);
        }
    }    

    /** Method Name : finish
    * Description : finish method of Batch class
    **/
    global void finish(Database.BatchableContext batchContext){
        try{
    // Run the maintainance batch based on the DML operation
    
    if(!Test.isRunningTest()/* && !System.IsBatch()*/){
       APTS_ProductRedistributionBatchHandler.runMaintenanceBatches(productIdList);
    }   

        APTS_ProductReplacementCodeMapping instProdCodeMap = new APTS_ProductReplacementCodeMapping();
        
        Database.executeBatch(instProdCodeMap,Integer.valueOf(System.Label.APTS_ProductReplacementBatchSize));
       

    //Send email to the admin in case of failures in the DML operation
    AsyncApexJob asyncJob = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems FROM AsyncApexJob WHERE Id =: batchContext.getJobId()];
    if(asyncJob != null && asyncJob.NumberOfErrors > 0){
        APTS_ProductRedistributionBatchHandler.sendEmail(asyncJob);
        }
               }catch(Exception e){
        APTS_CustomLogging.createErrorLog(e.getTypeName(), APTS_CPQConstants.APEX_NAME, e.getStackTraceString() ,'ProductRedistributionBatch', APTS_CPQConstants.EXCEPTION_ID, APTS_CPQConstants.CPQ,false,false,APTS_CPQConstants.CPQ_ERROR_EMAIL,true);
        }
    }    

}