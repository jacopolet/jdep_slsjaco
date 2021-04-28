/**
* Class Name : APTS_SalesOrgDataTriggerHandler
* Description :  Sales Org Data Trigger Handler which implements ITriggerHandler interface
* Author : V. Shankaranarayanan / Nagavi
* Date Created : 15-03-2018
**/
public with sharing class APTS_SalesOrgDataTriggerHandler implements ITriggerHandler{
    
    public class ApplicationException extends Exception {}
    
    public void BeforeInsert(List<SObject> newItems){
        try{
            updateSalesOrgFields((List<APTS_Sales_Org_Data__c>)newItems);
        }catch(Exception e) {/*throw new ApplicationException(ex);*/ APTS_CustomLogging.createErrorLog(e.getTypeName(), APTS_CPQConstants.APEX_NAME, e.getStackTraceString() , APTS_CPQConstants.SALE_TGR_HDLR, APTS_CPQConstants.EXCEPTION_ID, APTS_CPQConstants.CPQ,false,true,APTS_CPQConstants.CPQ_ERROR_EMAIL,true);}
    }
 
    public void BeforeUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldItems){}
 
    public void BeforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems){}
 
    public void AfterInsert(List<SObject> newList, Map<Id, SObject> newItems){}
 
    public void AfterUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldItems){
    updatePLIS(newList);
    updateAssoicatedSalesOrgOnProd(newList,oldItems);
}
 
    public void AfterDelete(List<SObject> oldList, Map<Id, SObject> oldItems){}
 
    public void AfterUndelete(List<SObject> newList, Map<Id, SObject> newItems){}
 
    /**Method Name : IsDisabled
    * Description : Method to check whether Sales Org Data Trigger is disabled or enabled based on 'SalesOrgDataTrigger__c'
    *               field of 'TriggerSettings__c' Custom Setting, If true, Trigger is enabled, else disabled.
    **/
    public Boolean IsDisabled(){
        try{
            return (TriggerSettings__c.getInstance().SalesOrgDataTrigger__c == true ? false : true);
        }catch(Exception e) {throw new ApplicationException(e);/*APTS_CustomLogging.createErrorLog(e.getTypeName(), APTS_CPQConstants.APEX_NAME, e.getStackTraceString() , APTS_CPQConstants.SALE_TGR_HDLR, APTS_CPQConstants.EXCEPTION_ID, APTS_CPQConstants.CPQ,false,true,APTS_CPQConstants.CPQ_ERROR_EMAIL,true);*/}
    }
    
    /**Method Name : updateSalesOrgFields
    * Description : Method to populate 'APTS_Product_Code__c', 'APTS_Product__c' and 'APTS_Price_List__c' fields of 
    *               Sales Org Data object based on 'APTS_Sales_Org_Data_Ext_ID__c' and 'APTS_Sales_Org_Data_Name__c' field values
    **/
    public void updateSalesOrgFields(List<APTS_Sales_Org_Data__c> newItems){
        Set<String> salesOrgDataProdCodeSet = new Set<String>();
        Set<String> salesOrgDataSalesOrgSet = new Set<String>();
        Map<String,Product2> productCodeMap = new Map<String, Product2>();
        Map<String, Id> priceListOrgIdMap = new Map<String, Id>();
        List<APTS_Sales_Org_Data__c> pliBasedOnSalesOrg=new List<APTS_Sales_Org_Data__c>();
        Map<Id,Product2> prodsForPliMap=new Map<Id,Product2>();
        Map<Id,Product2> zcBBForPliMap=new Map<Id,Product2>();
        List<APTS_Sales_Org_Data__c> activeSalesOrgList = new List<APTS_Sales_Org_Data__c>();
        try{
            for(APTS_Sales_Org_Data__c salesOrgData : newItems){
                if(salesOrgData.APTS_Sales_Org_Data_Ext_ID__c != null){
                    salesOrgData.APTS_Product_Code__c = salesOrgData.APTS_Sales_Org_Data_Ext_ID__c.substringBefore(Label.APTS_Pipe_Symbol);
                    salesOrgDataProdCodeSet.add(salesOrgData.APTS_Product_Code__c);
                    if(String.IsNotBlank(salesOrgData.APTS_Sales_Org_Data_Name__c)){
                        salesOrgDataSalesOrgSet.add(salesOrgData.APTS_Sales_Org_Data_Name__c);
                    }
                }
            }
            
            for(Product2 prod : [SELECT Id, ProductCode, Apttus_Config2__ConfigurationType__c, APTS_Material_Type__c, APTS_Sales_Catalog__c, APTS_Option_Group_Indicator__c FROM Product2 WHERE ProductCode IN: salesOrgDataProdCodeSet]){
                productCodeMap.put(prod.ProductCode, prod);
            }
            for(Apttus_Config2__PriceList__c priceList : [SELECT Id, APTS_SalesOrg__c FROM Apttus_Config2__PriceList__c WHERE APTS_SalesOrg__c IN: salesOrgDataSalesOrgSet AND APTS_PriceList_Type__c='Direct']){
                priceListOrgIdMap.put(priceList.APTS_SalesOrg__c, priceList.Id);
            }
           for(APTS_Sales_Org_Data__c salesOrgData : (List<APTS_Sales_Org_Data__c>) newItems){
                if(String.IsNotBlank(salesOrgData.APTS_Product_Code__c)){
                    salesOrgData.APTS_Product__c = productCodeMap.containsKey(salesOrgData.APTS_Product_Code__c) ? productCodeMap.get(salesOrgData.APTS_Product_Code__c).Id : null;
                    // To gather prod data for dummy pli insertion
                    if(salesOrgData.APTS_Product__c!=null && Trigger.isInsert){
                        if(productCodeMap.get(salesOrgData.APTS_Product_Code__c).APTS_Material_Type__c == Label.APTS_ZCMA){
                            prodsForPliMap.put(salesOrgData.APTS_Product__c,productCodeMap.get(salesOrgData.APTS_Product_Code__c));  
                        }
                        if(productCodeMap.get(salesOrgData.APTS_Product_Code__c).APTS_Material_Type__c == Label.APTS_ZCBB){
                            zcBBForPliMap.put(salesOrgData.APTS_Product__c,productCodeMap.get(salesOrgData.APTS_Product_Code__c));  
                        }    
                    }         
                }
                if(String.IsNotBlank(salesOrgData.APTS_Sales_Org_Data_Name__c)){
                    salesOrgData.APTS_Price_List__c = priceListOrgIdMap.containsKey(salesOrgData.APTS_Sales_Org_Data_Name__c) ? priceListOrgIdMap.get(salesOrgData.APTS_Sales_Org_Data_Name__c) : null;
                    // To gather price list data for dummy pli insertion
                    if(salesOrgData.APTS_Price_List__c!=null && Trigger.isInsert){
                        pliBasedOnSalesOrg.add(salesOrgData);
                    }
                    if(String.IsNotBlank(salesOrgData.APTS_Distribution_chain_specific_materia__c)){
                        activeSalesOrgList.add(salesOrgData); 
                    }
                }
            }
            //To initiate the dummy pli insertion. This runs when the sales org is inserted after product insertion
            if(((!pliBasedOnSalesOrg.IsEmpty() && !prodsForPliMap.IsEmpty())|| (!zcBBForPliMap.IsEmpty() && !activeSalesOrgList.IsEmpty())) && Trigger.isInsert){      
                APTS_ProductTriggerHandler.createDummyPLIs(prodsForPliMap, pliBasedOnSalesOrg, zcBBForPliMap, activeSalesOrgList);
            }
        }catch(Exception e) {
            /*throw new ApplicationException(e);*/ 
            APTS_CustomLogging.createErrorLog(e.getTypeName(), APTS_CPQConstants.APEX_NAME, e.getStackTraceString() , APTS_CPQConstants.SALE_TGR_HDLR, APTS_CPQConstants.EXCEPTION_ID, APTS_CPQConstants.CPQ,false,true,APTS_CPQConstants.CPQ_ERROR_EMAIL,true);}
    }
    
    
    public void updatePLIS(List<SObject> newItems){
        Map<Id,String> priceListUOMMap = new Map<Id,String>();
        Set<Id> ProdPLSet = new Set<Id>();
        List<APTS_Transactional_UOM__c> transUOMS = APTS_Transactional_UOM__c.getall().values();
        Set<String> transactionalUOMS = new Set<String>();
        Set<Id> priceListIds= new Set<Id>();
        
        for(APTS_Transactional_UOM__c tom : transUOMS ){
            transactionalUOMS.add(tom.name);
        }
        
        for(SObject s : newItems){
            APTS_Sales_Org_Data__c so = (APTS_Sales_Org_Data__c )s;
            System.debug('** In After Update TUOMS'+so.APTS_Selling_Unit__c);
            if(so.APTS_Price_List__c!=null && String.isNOTBlank(so.APTS_Selling_Unit__c) && transactionalUOMS.contains(so.APTS_Selling_Unit__c)) 
            {
                System.debug('** In After Update TUOMS Nontransaction'+transactionalUOMS+so.APTS_Selling_Unit__c);
                priceListIds.add(so.APTS_Price_List__c);
                priceListUOMMap.put(so.APTS_Price_List__c,so.APTS_Selling_Unit__c);
                ProdPLSet.add(so.APTS_Product__c);
            }
            if(so.APTS_Price_List__c!=null && String.isNOTBlank(so.APTS_Selling_Unit__c) && !transactionalUOMS.contains(so.APTS_Selling_Unit__c)) 
            {
                System.debug('** In After Update TUOMS'+transactionalUOMS+so.APTS_Selling_Unit__c);
                priceListIds.add(so.APTS_Price_List__c);
                priceListUOMMap.put(so.APTS_Price_List__c,APTS_CPQConstants.SPACE_SIGN);
                ProdPLSet.add(so.APTS_Product__c);
            }
        }
        System.debug('** In After Update PLMAP'+priceListUOMMap+priceListIds);
        List<Apttus_Config2__PriceListItem__c> plisToUpdate = new List<Apttus_Config2__PriceListItem__c>();
        
        for(Apttus_Config2__PriceListItem__c pli : [select id,APTS_Default_Selling_Uom__c,Apttus_Config2__PriceListId__c from Apttus_Config2__PriceListItem__c where Apttus_Config2__PriceListId__c IN :priceListIds and Apttus_Config2__ProductId__c in:ProdPLSet])
        {
            pli.APTS_Default_Selling_Uom__c = priceListUOMMap.get(pli.Apttus_Config2__PriceListId__c);
            plisToUpdate.add(pli);
        }
        System.debug('** In After Update PLIS Size'+plisToUpdate.size());
        
        String PRICELISTITEM = 'Apttus_Config2__PriceListItem__c';
        DescribeSObjectResult objResultPLI = APTS_OTCUtil.getsObjectAccess(PRICELISTITEM);
        if(objResultPLI != null && objResultPLI.isUpdateable() )
        {
        update plisToUpdate;
        }
    }
   public void updateAssoicatedSalesOrgOnProd(List<SObject> newItems,Map<Id, SObject> oldMap){
        Map<String,APTS_MARA_MVKE_Status_Mapping__c> maraStatusMap = APTS_ProductRedistributionBatchHandler.getMARAMVKEStatusMapping();
        System.debug('maraStatusMap=============>'+maraStatusMap);
        Set<ID> salesOrgIdSet = new Set<ID>();
        Map<Id,Product2> productUpdateMap = new Map<Id,Product2>();
        Product2 prod;
        List<APTS_Sales_Org_Data__c> getMaraSalesOrgsList = new  List<APTS_Sales_Org_Data__c>();
        for(APTS_Sales_Org_Data__c salesOrg : (List<APTS_Sales_Org_Data__c>)newItems){
            System.debug('old map value=====>'+((APTS_Sales_Org_Data__c)oldMap.get(salesOrg.id)).APTS_Distribution_chain_specific_materia__c);
            System.debug('new map value=====>'+salesOrg.APTS_Distribution_chain_specific_materia__c);
            if(((APTS_Sales_Org_Data__c)oldMap.get(salesOrg.id)).APTS_Distribution_chain_specific_materia__c != salesOrg.APTS_Distribution_chain_specific_materia__c){
                salesOrgIdSet.add(salesOrg.id);
            }
        }
        System.debug('salesOrgIdSet==============>'+salesOrgIdSet);
        System.debug('maraStatusMap==============>'+maraStatusMap);
        if(!salesOrgIdSet.isEmpty() && !maraStatusMap.isEmpty()){
            for(APTS_Sales_Org_Data__c salesOrg : [select id,APTS_Sales_Org_Data_Name__c,APTS_Distribution_chain_specific_materia__c,APTS_Product__c,APTS_Product__r.APTS_Cross_plant_material_status__c,APTS_Product__r.APTS_Associated_Sales_Org__c,APTS_Product__r.name from APTS_Sales_Org_Data__c where id IN : salesOrgIdSet]){
                List<String> assSalesOrgList = new List<String>();
                //Initialize the product you want to update
                if(salesOrg.APTS_Product__c!=null){
                    prod = new Product2(id=salesOrg.APTS_Product__c);
                }   
                System.debug('prod==============>'+prod);
                System.debug('prod name==============>'+salesOrg.APTS_Product__r.name);
                System.debug('CPMS==============>'+salesOrg.APTS_Product__r.APTS_Cross_plant_material_status__c);
                System.debug('DCSM==============>'+salesOrg.APTS_Distribution_chain_specific_materia__c);
                System.debug('Sales org name==============>'+salesOrg.APTS_Sales_Org_Data_Name__c);
                System.debug('EXISTING SALES ORG==============>'+salesOrg.APTS_Product__r.APTS_Associated_Sales_Org__c);
                if(prod!=null && salesOrg.APTS_Sales_Org_Data_Name__c!=null && salesOrg.APTS_Product__c!=null){
                    if( prod.APTS_Associated_Sales_Org__c==null){
                        prod.APTS_Associated_Sales_Org__c='';
                    }
                    //create list of sales org data 1) as per the data base [for first time] 2) as per the trigger transaction[Uncommited data but updated]
                    if(salesOrg.APTS_Product__r.APTS_Associated_Sales_Org__c!=null && productUpdateMap.get(salesOrg.APTS_Product__c)==null){
                        assSalesOrgList = salesOrg.APTS_Product__r.APTS_Associated_Sales_Org__c.split(';');
                    }
                    if(productUpdateMap.get(salesOrg.APTS_Product__c)!=null && productUpdateMap.get(salesOrg.APTS_Product__c).APTS_Associated_Sales_Org__c!=null){
                        assSalesOrgList = productUpdateMap.get(salesOrg.APTS_Product__c).APTS_Associated_Sales_Org__c.split(';');
                    }
                    System.debug('assSalesOrgList=================>'+assSalesOrgList);
                    //check if custom setting -> Visible on catalog matches - If matches add values to the "associated sales org" field
                    if(salesOrg.APTS_Product__r.APTS_Cross_plant_material_status__c!=null && 
                        salesOrg.APTS_Distribution_chain_specific_materia__c!=null && 
                        maraStatusMap.get(salesOrg.APTS_Product__r.APTS_Cross_plant_material_status__c+system.label.APTS_Pipe_Symbol+salesOrg.APTS_Distribution_chain_specific_materia__c)!=null && 
                        maraStatusMap.get(salesOrg.APTS_Product__r.APTS_Cross_plant_material_status__c+system.label.APTS_Pipe_Symbol+salesOrg.APTS_Distribution_chain_specific_materia__c).APTS_Visible_in_Catalogue__c){
                        //Avoiding null getting added at first
                        if(salesOrg.APTS_Product__r.APTS_Associated_Sales_Org__c==null){
                            salesOrg.APTS_Product__r.APTS_Associated_Sales_Org__c = '';
                        }
                        //Populating sales org based on first time and se
                        if(salesOrg.APTS_Product__r.APTS_Associated_Sales_Org__c!=null && productUpdateMap.get(salesOrg.APTS_Product__c)==null){
                            prod.APTS_Associated_Sales_Org__c = salesOrg.APTS_Product__r.APTS_Associated_Sales_Org__c; 
                            if(!salesOrg.APTS_Product__r.APTS_Associated_Sales_Org__c.contains(system.label.APTS_SAP + salesOrg.APTS_Sales_Org_Data_Name__c)){
                                prod.APTS_Associated_Sales_Org__c += ';' +system.label.APTS_SAP + salesOrg.APTS_Sales_Org_Data_Name__c;
                            }    
                        }
                        if(salesOrg.APTS_Product__c!=null && !productUpdateMap.isEmpty() && productUpdateMap.get(salesOrg.APTS_Product__c)!=null && productUpdateMap.get(salesOrg.APTS_Product__c).APTS_Associated_Sales_Org__c!=null){
                            prod.APTS_Associated_Sales_Org__c = productUpdateMap.get(salesOrg.APTS_Product__c).APTS_Associated_Sales_Org__c; 
                            if(!productUpdateMap.get(salesOrg.APTS_Product__c).APTS_Associated_Sales_Org__c.contains(system.label.APTS_SAP + salesOrg.APTS_Sales_Org_Data_Name__c)){
                                prod.APTS_Associated_Sales_Org__c += ';' +system.label.APTS_SAP + salesOrg.APTS_Sales_Org_Data_Name__c;
                            }
                        }
                        //Created map to avoid duplicate ids issue while inserting and always storing the latest/updated value in map
                        if(productUpdateMap.get(prod.id)==null){
                            productUpdateMap.put(prod.id,prod);
                        }else{
                            productUpdateMap.remove(prod.id);
                             productUpdateMap.put(prod.id,prod);
                        }
                        System.debug('INSIDE FIRST IF==========>'+productUpdateMap);
                    //check if custom setting -> Visible on catalog deosnt matches - If not matches then remove the entries from "associated sales org" field
                    }else{
                        //Updated comma seperated associated sales org, iterate and removing the desired entry
                        if(!assSalesOrgList.isEmpty()){
                            for(String str : assSalesOrgList){
                                if(!str.equalsIgnoreCase(system.label.APTS_SAP + salesOrg.APTS_Sales_Org_Data_Name__c)){
                                    prod.APTS_Associated_Sales_Org__c += str + ';';
                                }
                            }
                            //Created map to avoid duplicate ids issue while inserting and always storing the latest/updated value in map
                            if(productUpdateMap.get(prod.id)==null){
                                productUpdateMap.put(prod.id,prod);
                            }else{
                                productUpdateMap.remove(prod.id);
                                 productUpdateMap.put(prod.id,prod);
                            }
                        }
                        System.debug('INSIDE SECOND IF==========>'+productUpdateMap);
                    }
                }
            }
        }
        System.debug('productUpdateMap==============>'+productUpdateMap);
        if(!productUpdateMap.isEmpty()){
            update productUpdateMap.values();
        }
    }
}