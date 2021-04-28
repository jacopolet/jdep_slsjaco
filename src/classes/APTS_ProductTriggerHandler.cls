/**********************
Purpose: 
Revision History:
#No     Name        Date        Purpose
1.0     Nagavi      15/01/2017  Created the class to handle logics related to snding updates to SAP PO
************************/
public without sharing class APTS_ProductTriggerHandler implements ITriggerHandler {

    public class ApplicationException extends Exception {}
    private Static String EMPTY_STRING = ' '; 
    public static Map<Id,Product2> dummyPLIProdMap;
    public static Map<Id,Product2> dummyPLIProdMapFixedTerm;
    //Added by Saranya Rajagopal Date: 20th sep 2018
    public static Map<String,Price_List_Item_Information__mdt> dummyProductname=new Map<String,Price_List_Item_Information__mdt>();
    public static Map<String,Price_List_Item_Information__mdt> dummyProductcode=new Map<String,Price_List_Item_Information__mdt>();
    public static  List<Price_List_Item_Information__mdt> CustomMetaData=[SELECT id,Product_Name__c,Product_Code__c,Price_Type__c,Frequency__c,Charge_Type__c,Billing_Rule__c,Billing_Frequency__c FROM Price_List_Item_Information__mdt];
    /*@methodName- IsDisabled
    *@description- method is used to prevent recursion
    *@param- empty
    *@return- boolean
    */
    public Boolean isDisabled(){
        try{
            return (TriggerSettings__c.getInstance().ProductTrigger__c == true ? false : true);
        }catch(Exception ex){throw new ApplicationException(ex);}
    }
    
    /*@methodName- beforeInsert
    *@description- method is used to call logic related to the beforeInsert event
    *@param- List<SObject> newProductsList
    *@return- void
    */
    public void beforeInsert(List<SObject> newProductsList){
        try{ 
            processProductsInsertBasedOnMARA(newProductsList);
        }catch(Exception e){
            APTS_CustomLogging.createErrorLog(e.getTypeName(),'Apex', e.getStackTraceString() ,'APTS_ProductTriggerHandler',null,'CPQ',false,false,null,true);
        }
    } 
 
    /*@methodName- beforeUpdate
    *@description- method is used to call logic related to the beforeUpdate event
    *@param- List<SObject> newProductsList, Map<Id, SObject> newProductsMap, List<SObject> oldProductsList, Map<Id, SObject> oldProductsMap
    *@return- void
    */
    public void beforeUpdate(List<SObject> newProductsList, Map<Id, SObject> newProductsMap, List<SObject> oldProductsList, Map<Id, SObject> oldProductsMap){
        try{
            processProductUpdateBasedOnMARA(newProductsList);   
        }catch(Exception e){
            APTS_CustomLogging.createErrorLog(e.getTypeName(),'Apex', e.getStackTraceString() ,'APTS_ProductTriggerHandler',null,'CPQ',false,false,null,true);    
        }
    }
    
    /*@methodName- beforeDelete
    *@description- method is used to call logic related to the beforeDelete event
    *@param- List<SObject> oldProductsList, Map<Id, SObject> oldProductsMap 
    *@return- void
    */
    public void beforeDelete(List<SObject> oldProductsList, Map<Id, SObject> oldProductsMap){}
 
    /*@methodName- afterInsert
    *@description- method is used to call logic related to the afterInsert event
    *@param- List<SObject> newProductsList, Map<Id, SObject> newProductsMap
    *@return- void
    */
    public void afterInsert(List<SObject> newProductsList, Map<Id, SObject> newProductsMap){
        try{
            //Logic to check if the product is active and it is newly inserted.If so will trigger digital pricing
            System.debug('newProductsList=========>'+newProductsList);
            onAfterInsertProduct2((List<Product2>)newProductsList);
        }catch(Exception e) {
            System.debug('--ERROR--');
            APTS_CustomLogging.createErrorLog(e.getTypeName(),'Batch Apex', e.getStackTraceString() ,'APTS_ProductTriggerHandler',null,'CPQ',false,false,null,true);
        }
    }
    
    /*@methodName- afterUpdate
    *@description- method is used to call logic related to the afterUpdate event
    *@param- List<SObject> newProductsList , Map<Id, SObject> newProductsMap, List<SObject> oldProductsList, Map<Id, SObject> oldProductsMap
    *@return- void
    */
    public void afterUpdate(List<SObject> newProductsList , Map<Id, SObject> newProductsMap, List<SObject> oldProductsList, Map<Id, SObject> oldProductsMap){
        try{
            //Logic to check if the product's isactive field has changed.If so will trigger digital pricing
            onAfterUpdateProduct2((Map<Id, Product2>)newProductsMap,(Map<Id, Product2>)oldProductsMap);
            ProductPLIActivation((Map<Id, Product2>)newProductsMap,(Map<Id, Product2>)oldProductsMap);

            //XEN REYES Sept. 25, 2019 - DOO-1814 (Part Sync to Click from SF Product page)
            SYNC_TO_CLICK(newProductsList, oldProductsMap);

        }catch(Exception e) {
            APTS_CustomLogging.createErrorLog(e.getTypeName(),'Batch Apex', e.getStackTraceString() ,'APTS_ProductTriggerHandler',null,'CPQ',false,false,null,true);
        }
    }
    
    /*@methodName- afterDelete
    *@description- method is used to call logic related to the afterDelete event
    *@param- List<SObject> oldProductsList, Map<Id, SObject> oldProductsMap 
    *@return- void
    */
    public void afterDelete(List<SObject> oldProductsList, Map<Id, SObject> oldProductsMap){}
    
    /*@methodName- afterUndelete
    *@description- method is used to call logic related to the afterUndelete event
    *@param- List<SObject> newProductsList, Map<Id, SObject> newProductsMap
    *@return- void
    */
    public void afterUndelete(List<SObject> newProductsList, Map<Id, SObject> newProductsMap){}
    
    /*************** Business Logic Methods ***********************/
    /*@methodName- onAfterInsertProduct2
    *@description- method is used to call logic related to the afterInsert event
    *@param- Pass only the records to be processed as a list
    *@return- void
    */
     public static void onAfterInsertProduct2(List<Product2> newProductsList){
         try{
            Set<Id> productIdsToBeSentToSAPPO = new Set<Id>();
            dummyPLIProdMap = new Map<Id,Product2>();
            dummyPLIProdMapFixedTerm = new Map<Id,Product2>();
            Map<Id,Product2> zcbbProductMap = new Map<Id,Product2>();
            Map<String, Id> prodCodeProdIdMap = new Map<String, Id>();
            List<APTS_Sales_Org_Data__c> allSalesOrgList = new List<APTS_Sales_Org_Data__c>();
            List<APTS_Sales_Org_Data__c> activeSalesOrgList = new List<APTS_Sales_Org_Data__c>();
            Set<String> prodIdSet = new Set<String>();
             
            for(Price_List_Item_Information__mdt dummyValues:CustomMetaData)
            {
                dummyProductname.put(dummyValues.Product_Name__c,dummyValues);
                dummyProductcode.put(dummyValues.Product_Code__c,dummyValues);
            }
            for(Product2 prod : newProductsList){
                if(prod.IsActive && APTS_IntegrationLogHandlerUtility.checkIfWebshopIsValid(prod.APTS_Product_Enabled_for_web_shop_s__c)){
                    productIdsToBeSentToSAPPO.add(prod.Id);   
                }
                if(prod.APTS_Material_Type__c == Label.APTS_ZCMA){
                    dummyPLIProdMap.put(prod.Id,prod);
                }
                Boolean isCheck=isProductAvailable(prod.name,CustomMetaData);
                if(ischeck || dummyProductcode.keyset().contains(prod.ProductCode))
                {
                System.debug('** Abhishek Inside Dummy PLI Trigger'+prod.name);
                System.debug('** Abhishek Inside Dummy PLI Trigger'+prod.ProductCode);
                    dummyPLIProdMap.put(prod.Id,prod);
                    dummyPLIProdMapFixedTerm.put(prod.Id,prod);
                }
                
                if(prod.APTS_Material_Type__c == Label.APTS_ZCBB && prod.isActive){
                    zcbbProductMap.put(prod.Id,prod);
                    prodIdSet.add(prod.ProductCode);
                }
                if(String.IsNotBlank(prod.ProductCode)){
                    prodCodeProdIdMap.put(prod.ProductCode, prod.Id);
                }
            }
             
            
            if(!productIdsToBeSentToSAPPO.isEmpty()){
               APTS_IntegrationLogHandlerUtility.createIntegrationLogs(productIdsToBeSentToSAPPO);
            }
            
            //Logic to link Orphan Sales Org Data records to Product
            if(!prodCodeProdIdMap.IsEmpty()){
                //Call to link sales org and product
                allSalesOrgList = linkSalesOrgData(prodCodeProdIdMap);
                
            }
            //get All Active sales org
            String query = APTS_PricingDistributionBatchHandler.getObjectQuery(Label.APTS_SalesOrgDataObject)+'WHERE APTS_Product_Code__c IN: prodIdSet';
            for(APTS_Sales_Org_Data__c sOrg : Database.query(query)){
                if(String.IsNotBlank(sOrg.APTS_Distribution_chain_specific_materia__c)){
                    activeSalesOrgList.add(sOrg); 
                }
            }
            //Logic to create dummy PLIs for Bundle Products
            System.debug('**Abhishek Dummy PLIS'+allSalesOrgList);
            System.debug('**Abhishek Dummy PLIS'+activeSalesOrgList);
            if((!dummyPLIProdMap.IsEmpty() || !zcbbProductMap.isEmpty()) && (!allSalesOrgList.IsEmpty() || !activeSalesOrgList.isEmpty())){
                createDummyPLIs(dummyPLIProdMap, allSalesOrgList,zcbbProductMap, activeSalesOrgList);
            }
         }catch(Exception e){
             APTS_CustomLogging.createErrorLog(e.getTypeName(),'Batch', e.getStackTraceString() ,'APTS_ProductTriggerHandler',null,'CPQ',false,false,null,true);
         }
    }
             //Added by Saranya Rajagopal Date: 20th sep 2018
    private static Boolean isProductAvailable(String prodName, List<Price_List_Item_Information__mdt> CustomMetaData){
        for(Price_List_Item_Information__mdt metaData :CustomMetaData){
            if(prodName.containsignorecase(metaData.Product_Name__c)){
                System.debug('** Saranya Inside Dummy PLI Trigger'+prodName);
                return True;
                
            }
        }
       return false;
    }

    public static void ProductPLIActivation(Map<Id, Product2> newProductsMap, Map<Id, Product2> oldProductsMap){
         System.debug('ProductPLIActivation');
        Set<Id> setPrdIds = new Set<Id>();
        List<Apttus_Config2__PriceListItem__c> lstPriceListItemToUpdate = new List<Apttus_Config2__PriceListItem__c>();
        for(Id prodId:newProductsMap.keySet()){
             if(oldProductsMap.get(prodId).IsActive != newProductsMap.get(prodId).IsActive && newProductsMap.get(prodId).IsActive == true)    setPrdIds.add(prodId);
        }
        List<Apttus_Config2__PriceListItem__c> lstPriceListItem = new List<Apttus_Config2__PriceListItem__c>([select id from Apttus_Config2__PriceListItem__c where Apttus_Config2__ProductId__c IN :setPrdIds]);
        for(Apttus_Config2__PriceListItem__c instPLI : lstPriceListItem)
        {
           instPLI.Apttus_Config2__Active__c = true; 
           lstPriceListItemToUpdate.add(instPLI);
        }
        Database.update(lstPriceListItemToUpdate,true);
        } 
    /*@methodName- onAfterUpdateProduct2
    *@description- method is used to call logic related to the afterUpdate event
    *@param- Pass the map of new and old records
    *@return- no returntype
    */
    public static void onAfterUpdateProduct2(Map<Id, Product2> newProductsMap, Map<Id, Product2> oldProductsMap){
        try{ 
            Set<Id> productIdsToBeSentToSAPPO = new Set<Id>();
            List<Schema.FieldSetMember> relatedFieldSet=new List<Schema.FieldSetMember>();
            List<Product2> maraChangedProducts = new List<Product2>();
            relatedFieldSet=APTS_IntegrationLogHandlerUtility.readFieldSet('APTS_FieldsForDigitalIntegration', Label.Apttus_CPQAdmin.Product2);    
            for(Id prodId:newProductsMap.keySet()){
                if(APTS_IntegrationLogHandlerUtility.checkIfWebshopIsValid(newProductsMap.get(prodId).APTS_Product_Enabled_for_web_shop_s__c) && ((newProductsMap.get(prodId).IsActive != oldProductsMap.get(prodId).IsActive) ||
                    (newProductsMap.get(prodId).IsActive == true && 
                    APTS_IntegrationLogHandlerUtility.checkIfValidToSend(newProductsMap.get(prodId),oldProductsMap.get(prodId),relatedFieldSet)))){
                    productIdsToBeSentToSAPPO.add(prodId);
                }
            }
             
            if(!productIdsToBeSentToSAPPO.isEmpty()){
                APTS_IntegrationLogHandlerUtility.checkAndCreateIntegrationLogs(productIdsToBeSentToSAPPO);     
            }
        }catch(Exception e){
            APTS_CustomLogging.createErrorLog(e.getTypeName(),'Batch', e.getStackTraceString() ,'APTS_ProductTriggerHandler',null,'CPQ',false,false,null,true);
        }
    }
     
    public static void processProductsInsertBasedOnMARA(List<SObject> newProductsList){
        try{
            System.debug('processProductsInsertBasedOnMARA');
            APTS_ProductPricingBatchSettings__c custSetting = APTS_ProductPricingBatchSettings__c.getInstance();
            Set<String> initialLoadAllowedStatuses = custSetting != null ? changeStringToSetValue(custSetting.APTS_AllowedPlantStatusDuringInitialLoad__c) : null;
            Set<String> allowedStatusesDuringUpdate = custSetting != null ? changeStringToSetValue(custSetting.APTS_AllowedPlantStatusDuringUpdate__c) : null;
            
            Boolean initialLoad = custSetting != null ? custSetting.APTS_BatchProductPricingInitialDataLoad__c : false;
            List<APTS_Batch_Log_Event__e> batchEventList = new List<APTS_Batch_Log_Event__e>();
            for(Product2 prod : (List<Product2>) newProductsList){
                prod.Apttus_Config2__BundleInvoiceLevel__c='';
                if((initialLoad && !initialLoadAllowedStatuses.contains(prod.APTS_Cross_plant_material_status__c)) 
                    || (!initialLoad && !allowedStatusesDuringUpdate.contains(prod.APTS_Cross_plant_material_status__c))){
                    batchEventList.add(createBatchEvent(prod.ProductCode));
                    prod.addError(Label.APTS_MARAStatusErrorMsg);
                }
                //Populate BundleInvoiceLevel Defect - 15322 -- START | Karan
                if(prod.APTS_Material_Type__c==Label.APTS_ZCMA || (prod.APTS_Option_Group_Indicator__c!=null && prod.APTS_Option_Group_Indicator__c != '00')){
                    prod.Apttus_Config2__BundleInvoiceLevel__c='Detail';
                }else{
                     prod.Apttus_Config2__BundleInvoiceLevel__c='';
                }
                //Populate BundleInvoiceLevel Defect - 15322 -- END | Karan
            }
            EventBus.publish(batchEventList);
        }catch(Exception e){
            APTS_CustomLogging.createErrorLog(e.getTypeName(),'Batch', e.getStackTraceString() ,'APTS_ProductTriggerHandler',null,'CPQ',false,false,null,true);
        }
    }
    
    public static Set<String> changeStringToSetValue(String value){
         Set<String> tempSet = new Set<String>();
         tempSet.addAll(value.split(Label.APTS_CommaSeparator));
         return tempSet;
     }
    
    public static void processProductUpdateBasedOnMARA(List<SObject> newProductsList){
          try{
            APTS_ProductPricingBatchSettings__c custSetting = APTS_ProductPricingBatchSettings__c.getInstance();
            Set<String> blockedStatuses = custSetting != null ? changeStringToSetValue(custSetting.APTS_BlockedPlantStatusDuringUpdate__c) : null;
            List<APTS_Batch_Log_Event__e> batchEventList = new List<APTS_Batch_Log_Event__e>();
            for(Product2 prod : (List<Product2>) newProductsList){
                if(blockedStatuses.contains(prod.APTS_Cross_plant_material_status__c)){
                    batchEventList.add(createBatchEvent(prod.ProductCode));
                    prod.addError(Label.APTS_MARAStatusErrorMsg);
                }
            }
            EventBus.publish(batchEventList);
        }catch(Exception e){
            APTS_CustomLogging.createErrorLog(e.getTypeName(),'Batch', e.getStackTraceString() ,'APTS_ProductTriggerHandler',null,'CPQ',false,false,null,true);
        }
    }
    
    public static APTS_Batch_Log_Event__e createBatchEvent(String errorProductCode){
        APTS_Batch_Log_Event__e batchLogEvent = new APTS_Batch_Log_Event__e(
            APTS_Error_Name__c = Label.APTS_ProductInsertFailedMsg + errorProductCode,
            APTS_Error_Level__c = Label.APTS_Error,
            APTS_Object_Id__c = errorProductCode,
            APTS_Error_Description__c = Label.APTS_MARAStatusErrorMsg,
            APTS_Object_Name__c = Label.Apttus_CPQAdmin.Product2,
            APTS_Error_Date_Time__c = System.Now()
        );
        return batchLogEvent;
    }
    
    public static List<APTS_Sales_Org_Data__c> linkSalesOrgData(Map<String, Id> prodCodeProdIdMap){
        
        List<APTS_Sales_Org_Data__c> salesOrgList = new List<APTS_Sales_Org_Data__c>();
        List<APTS_Sales_Org_Data__c> allSalesOrgList = new List<APTS_Sales_Org_Data__c>();
        
        for(APTS_Sales_Org_Data__c salesOrg : [SELECT Id, APTS_Product__c, APTS_Product_Code__c, APTS_Price_List__c FROM APTS_Sales_Org_Data__c WHERE APTS_Product_Code__c IN: prodCodeProdIdMap.keySet() ]){
            if(String.IsBlank(salesOrg.APTS_Product__c)){
                salesOrg.APTS_Product__c = prodCodeProdIdMap.get(salesOrg.APTS_Product_Code__c);
                salesOrgList.add(salesOrg);
            }
            allSalesOrgList.add(salesOrg);
        }
        
        if(!salesOrgList.IsEmpty()){
            try{
                Database.update(salesOrgList, false);
            }catch(Exception ex){throw new ApplicationException(ex);}
        }
        
        return allSalesOrgList;
    }
    
    
    /** Method Name : createDummyPLIs
    * Description : Method to insert PLI for Bundle products
    **/
    public static void createDummyPLIs(Map<Id,Product2> dummyPLIProdMap, List<APTS_Sales_Org_Data__c> allSalesOrgList,Map<Id,Product2> zcbbDummyPLIs, List<APTS_Sales_Org_Data__c> activeSalesOrgList){
         
        List<Apttus_Config2__PriceListItem__c> pliToBeInserted = new List<Apttus_Config2__PriceListItem__c>(); 
        Set<String> chargeTypeSet = new Set<String>{Label.APTS_Sales_Price, Label.APTS_Rental_Price, Label.APTS_Service_Fee};
        Map<String, String> dummyPLICTCMap = getPLIChargeTypeCriteriaMapping();
        System.debug('******dummyPLICTCMap============>'+dummyPLICTCMap);
       if(dummyPLIProdMapFixedTerm==null) dummyPLIProdMapFixedTerm = new Map<Id,Product2>();
       
         
       if(!allSalesOrgList.isEmpty() && !dummyPLIProdMap.isEmpty()){
       System.debug('** Abhishek Inside Dummy PLI1'+allSalesOrgList.isEmpty());
         System.debug('** Abhishek Inside Dummy PLI2'+dummyPLIProdMap.isEmpty());
            for(APTS_Sales_Org_Data__c salesOrg : allSalesOrgList){
            System.debug('** Abhishek Inside Dummy PLI0');
               for(Product2 prodDummy : dummyPLIProdMapFixedTerm.values())
               {
                    System.debug('** Abhishek Creating Dummy PLI');
                    //Added by Saranya Rajagopal Date: 20th sep 2018
                    Price_List_Item_Information__mdt customPLI=dummyProductname.get(prodDummy.Name);
                    Price_List_Item_Information__mdt customPLICode=dummyProductcode.get(prodDummy.ProductCode);
                    Apttus_Config2__PriceListItem__c pLI = new Apttus_Config2__PriceListItem__c();
                    pLI.Apttus_Config2__ProductId__c = prodDummy.id;
                    pLI.APTS_Related_sales_org_data__c=salesOrg.id;
                    pLI.Apttus_Config2__PriceListId__c = salesOrg.APTS_Price_List__c;
                    pLI.Apttus_Config2__PriceUom__c = APTS_CPQConstants.PIECE_UOM_API;
                    if(customPLI!=null)
                    {
                      System.debug('******@@@customPLI============>'+customPLI);
                        pLI.Apttus_Config2__ChargeType__c =customPLI.Charge_Type__c;
                        pLI.Apttus_Config2__PriceType__c=customPLI.Price_Type__c;
                        pLI.Apttus_Config2__Frequency__c=customPLI.Frequency__c;
                        pLI.Apttus_Config2__BillingFrequency__c=customPLI.Billing_Frequency__c;
                        pLI.Apttus_Config2__BillingRule__c=customPLI.Billing_Rule__c;
                        pli.Apttus_Config2__PriceUom__c = APTS_CPQConstants.PIECE_UOM_API;
                       
                    }
                    else if(customPLICode!=null)
                    {
                   
                      System.debug('@@@ Salesorg pricelist'+salesOrg.APTS_Price_List__c);
                        pLI.Apttus_Config2__ChargeType__c =customPLICode.Charge_Type__c;
                        pLI.Apttus_Config2__PriceType__c=customPLICode.Price_Type__c;
                        pLI.Apttus_Config2__Frequency__c=customPLICode.Frequency__c;
                        pLI.Apttus_Config2__BillingFrequency__c=customPLICode.Billing_Frequency__c;
                        pLI.Apttus_Config2__BillingRule__c=customPLICode.Billing_Rule__c;
                        
                    }
                    pliToBeInserted.add(pLI);
                }
                if(dummyPLIProdMap.containsKey(salesOrg.APTS_Product__c)){
                 System.debug('@@@ Salesorg product'+salesOrg.APTS_Product__c);
                
                    if(!String.IsBlank(dummyPLIProdMap.get(salesOrg.APTS_Product__c).APTS_Option_Group_Indicator__c) && (dummyPLIProdMap.get(salesOrg.APTS_Product__c).APTS_Option_Group_Indicator__c).startsWith(system.label.APTS_04_Value)){
                        //Menu Option Grp
                        Apttus_Config2__PriceListItem__c pLI = new Apttus_Config2__PriceListItem__c();
                        pLI.Apttus_Config2__ProductId__c = salesOrg.APTS_Product__c;
                        pLI.Apttus_Config2__PriceListId__c = salesOrg.APTS_Price_List__c;
                        pLI.Apttus_Config2__ChargeType__c = Label.APTS_Usage_Fee;
                        pLI.Apttus_Config2__PriceType__c=APTS_CPQConstants.USAGE_LABEL;
                        pLI.Apttus_Config2__PriceMethod__c  =APTS_CPQConstants.PER_UNIT;
                        pLI.Apttus_Config2__Frequency__c=Label.APTS_Monthly;
                        pLI.Apttus_Config2__BillingFrequency__c=Label.APTS_Monthly;
                        pLI.Apttus_Config2__BillingRule__c=APTS_CPQConstants.LABEL_BILL_IN_ARREARS;
                        pli.Apttus_Config2__PriceUom__c = APTS_CPQConstants.PIECE_UOM_API;
                        pLI.APTS_Related_sales_org_data__c=salesOrg.id;
                        pliToBeInserted.add(pLI);
                    }else if(!String.IsBlank(dummyPLIProdMap.get(salesOrg.APTS_Product__c).APTS_Sales_Catalog__c) && (dummyPLIProdMap.get(salesOrg.APTS_Product__c).APTS_Sales_Catalog__c).startsWith('0702')){
                     //Ingredeint Bundle
                        //Defect no : 15247 | If Material Type = ZCMA && Sales Catalog = 0702, Create PLI charge type = Sales Fee; No other Charge type PLIs should be created. | Karan Khatri START
                        Apttus_Config2__PriceListItem__c pLI = new Apttus_Config2__PriceListItem__c();
                        pLI.Apttus_Config2__ProductId__c = salesOrg.APTS_Product__c;
                        pLI.Apttus_Config2__PriceListId__c = salesOrg.APTS_Price_List__c;
                        pLI.Apttus_Config2__ChargeType__c = Label.APTS_Sales_Price;
                        pLI.Apttus_Config2__PriceType__c=Label.APTS_OneTime;
                        pLI.Apttus_Config2__Frequency__c=Label.APTS_OneTime;
                        pLI.Apttus_Config2__BillingFrequency__c=Label.APTS_OneTime;
                        pLI.Apttus_Config2__BillingRule__c=APTS_CPQConstants.LABEL_BILL_IN_ADVANCE;
                        pli.Apttus_Config2__PriceUom__c = APTS_CPQConstants.PIECE_UOM_API;
                        pLI.APTS_Related_sales_org_data__c=salesOrg.id;
                        //Defect no 23632 Added by Saranya Rajagopal 
                        PLI.Apttus_Config2__IsQuantityReadOnly__c=True;
                        pliToBeInserted.add(pLI);
                        //Defect no : 15247 | If Material Type = ZCMA && Sales Catalog = 0702, Create PLI charge type = Sales Fee; No other Charge type PLIs should be created. | Karan Khatri END
                    }else{
                         System.debug('*****@@@@Saranya=====>');
                        for(String chargeType : chargeTypeSet){
                            Apttus_Config2__PriceListItem__c pLI = new Apttus_Config2__PriceListItem__c();
                            pLI.Apttus_Config2__ProductId__c = salesOrg.APTS_Product__c;
                            pLI.Apttus_Config2__PriceListId__c = salesOrg.APTS_Price_List__c;
                            pLI.Apttus_Config2__ChargeType__c = chargeType;
                            pli.Apttus_Config2__PriceUom__c = APTS_CPQConstants.PIECE_UOM_API;
                            pLI.APTS_Related_sales_org_data__c=salesOrg.id;
                            //Set the price type and frequency for rental and service fee pli
                            if(chargeType != Label.APTS_Sales_Price){
                            System.debug('@@@chargeType '+chargeType);
                                pLI.Apttus_Config2__PriceType__c=Label.Apttus_CPQAdmin.Recurring;
                                pLI.Apttus_Config2__Frequency__c=Label.APTS_Monthly;
                                //pLI.Apttus_Config2__BillingFrequency__c=Label.APTS_Monthly;
                                if(chargeType == Label.APTS_Usage_Fee){
                                System.debug('@@@c@hargeType '+chargeType);
                                    pLI.Apttus_Config2__BillingRule__c=APTS_CPQConstants.LABEL_BILL_IN_ARREARS;
                                    pLI.Apttus_Config2__PriceType__c=APTS_CPQConstants.USAGE_LABEL;
                                    pLI.Apttus_Config2__PriceMethod__c  =APTS_CPQConstants.PER_UNIT;
                                }else{
                                     pLI.Apttus_Config2__BillingRule__c=APTS_CPQConstants.LABEL_BILL_IN_ADVANCE;
                                }
                            }else{
                                pLI.Apttus_Config2__Frequency__c=Label.APTS_OneTime;
                                //pLI.Apttus_Config2__BillingFrequency__c=Label.APTS_OneTime;
                                pLI.Apttus_Config2__PriceType__c=Label.APTS_OneTime;
                                pLI.Apttus_Config2__BillingRule__c=APTS_CPQConstants.LABEL_BILL_IN_ADVANCE;
                            }
                            System.debug('*****chargeType=====>'+chargeType);
                            if(dummyPLICTCMap.containsKey(Label.Apttus_Config2.Bundle +EMPTY_STRING+ chargeType) && dummyPLICTCMap.get(Label.Apttus_Config2.Bundle +EMPTY_STRING+ chargeType) !=null){
                                System.debug('KEY========>'+Label.Apttus_Config2.Bundle +EMPTY_STRING+ chargeType);
                                pLI.Apttus_Config2__Criteria__c = dummyPLICTCMap.get(Label.Apttus_Config2.Bundle +EMPTY_STRING+ chargeType);
                            }
                            pliToBeInserted.add(pLI);
                        }
                    }
                }
            }
        }
        //Usage Fee PLI must be populated for the ZCBB materials | Karan Khatri == START 
        if(!zcbbDummyPLIs.isEmpty() && !activeSalesOrgList.isEmpty()){ //Consumption Categories
        System.debug('@@@activeSalesOrgList '+activeSalesOrgList);
            for(APTS_Sales_Org_Data__c salesOrg : activeSalesOrgList){
                if(zcbbDummyPLIs.containsKey(salesOrg.APTS_Product__c)){
                    Apttus_Config2__PriceListItem__c pLI = new Apttus_Config2__PriceListItem__c();
                    pLI.Apttus_Config2__ProductId__c = salesOrg.APTS_Product__c;
                    pLI.Apttus_Config2__PriceListId__c = salesOrg.APTS_Price_List__c;
                    pLI.Apttus_Config2__ChargeType__c = Label.APTS_Usage_Fee;
                    pLI.Apttus_Config2__PriceType__c=APTS_CPQConstants.USAGE_LABEL;
                    pLI.Apttus_Config2__PriceMethod__c  =APTS_CPQConstants.PER_UNIT;
                    pLI.Apttus_Config2__Frequency__c=Label.APTS_Monthly;
                    //pLI.Apttus_Config2__BillingFrequency__c=Label.APTS_Monthly;
                    pLI.Apttus_Config2__BillingRule__c=APTS_CPQConstants.LABEL_BILL_IN_ARREARS;
                    pli.Apttus_Config2__PriceUom__c = APTS_CPQConstants.PIECE_UOM_API;
                    pLI.APTS_Related_sales_org_data__c=salesOrg.id;
                    pliToBeInserted.add(pLI);
                }
            }
        }
        //Usage Fee PLI must be populated for the ZCBB materials | Karan Khatri == END      
        if(!pliToBeInserted.IsEmpty()){
            try{
                Database.insert(pliToBeInserted);
            }catch(Exception e){
                APTS_CustomLogging.createErrorLog(e.getTypeName(),'Batch', e.getStackTraceString() ,'APTS_ProductTriggerHandler',null,'CPQ',false,false,null,true);
            }
        }
    }
    
    /** Method Name : getPLIChargeTypeCriteriaMapping
    * Description : Method to build and return PLI Charge Type Criteria mapping
    **/
    public static Map<String, String> getPLIChargeTypeCriteriaMapping(){
        Map<String, String> pLIChargeTypeCriteriaMap = new Map<String, String>();
        
        for(APTS_PLI_Charge_Type_Criteria_Mapping__mdt meta : [SELECT Id, MasterLabel, APTS_Charge_Type_Criteria__c FROM APTS_PLI_Charge_Type_Criteria_Mapping__mdt ]){
            pLIChargeTypeCriteriaMap.put(meta.MasterLabel, meta.APTS_Charge_Type_Criteria__c);
        }
        return pLIChargeTypeCriteriaMap;
    }
    

    /*
    * @author        Abram Vixen Reyes
    * @date          September 25, 2019
    * @description   Method to sync the pricebookentry to Click
    * @revision(s)
    */

    public void SYNC_TO_CLICK (List<SObject> newList, Map<Id, SObject> oldMap) {
        CustomLogging.push('SYNC_TO_CLICK', 'APTS_ProductTriggerHandler');
        
        Set<Id> prodToProcessSet = new Set<Id>();
        for(Product2 PROD_VAR : (List<Product2>) newList){
            Product2 OLD_VAR = (Product2) oldMap.get(PROD_VAR.Id);
            if(PROD_VAR.TS_SyncToClick__c != OLD_VAR.TS_SyncToClick__c){
                prodToProcessSet.add(PROD_VAR.Id);
            }
        }

        if(!prodToProcessSet.isEmpty()){
            Map<Id, PricebookEntry> PBENTRY_MAP = new Map<Id, PricebookEntry>([SELECT Id, TS_Load_Id__c, Sales_Organization__c, Country_ISO__c, Pricebook2.IsStandard, IsActive, Product2.Name, Product2.ProductCode FROM PricebookEntry 
                                                                                WHERE Product2Id IN: prodToProcessSet 
                                                                                AND Product2.APTS_Material_Type__c IN ('ZSPR', 'ZSER')
                                                                                AND TS_Load_Id__c != null
                                                                                AND Pricebook2.IsStandard = false
                                                                                AND IsActive = true
                                                                                AND TS_Click__c = true
                                                                                ]);
            
            if(!PBENTRY_MAP.isEmpty()){
                List<Integration_Log__c> LOG_LIST = new List<Integration_Log__c>();
                for(PricebookEntry PBE_VAR : PBENTRY_MAP.values()){
                    LOG_LIST.add(new Integration_Log__c(Object_Id__c = PBE_VAR.Id,
                                                        Object__c = INT_Constants.CLICK_SYNCMASTERPRODUCT,
                                                        Integration_Status__c = INT_Constants.INITIAL,
                                                        Triggered_Timestamp__c = Datetime.now(),
                                                        Useful_Container__c = String.valueOf(PBE_VAR.Product2.Name + ' - ' + PBE_VAR.Product2.ProductCode + ' - ' + PBE_VAR.Country_ISO__c + ' - ' + 'Manual Sync')
                                                        ));
                }

                if(!LOG_LIST.isEmpty()){
                    try{
                        insert LOG_LIST;
                    } catch (Exception e){
                        CustomLogging.debugException(e);
                        CustomLogging.pop();
                    }
                }
            }                                                                                
        }

        CustomLogging.pop();
    }
}