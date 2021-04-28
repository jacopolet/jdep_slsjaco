/**
* @author        Marvin Gatchalian
* @date          6.mar.2018
* @description   Apex class used to send the callout to Click this must be limited to 100 records as the batch class
                 has been executed with 100 records per batch.
* @revision(s)
*/
public without sharing class TS_PriceBookEntrySyncToClick {
    
    public static Boolean hasException = false;
    public class TS_PriceBookEntrySyncToClickException extends Exception {}
	
	public void executeSendPartType(List<Integration_Log__c> currentILogList) {
        CustomLogging.push('SyncMasterProduct', 'TS_PriceBookEntrySyncToClick');
        
        List<Integration_Log__c> updatedIlogList = [Select Id, Integration_Status__c, Work_Order_Line_Item__c ,
        												   Object__c, Object_Id__c
                                                    From Integration_Log__c Where Id IN: currentILogList];
                                                    
        List<Integration_Log__c> updatableIlogList = new List<Integration_Log__c>();
        
        Set<Id> psId = new Set<Id>();
        
        Map<Id,Integration_Log__c> iLogMap = new Map<Id,Integration_Log__c>();
        for (Integration_Log__c ilog : updatedIlogList) {
            psId.add(ilog.Object_Id__c);      
            iLogMap.put(ilog.Object_Id__c, ilog);      
        }

        List<PricebookEntry> priceBookEntries = [SELECT Id, PriceBook2.Name, Country_ISO__c, Product2.Id, Product2.Name, 
                                        				Product2.Description, OldStandardPrice__c, Name, Product2.IsActive, 
                                                        Product2.APTS_Material_Type__c, //Is_Service_Material__c, replaced  15 may 18  
                                        				UnitPrice,
                                                        Product2.ProductCode, //KTS-1882 6.26.2018 Added by Paul Aguiling
                                                        Sales_Organization__c, //DOO-4641 XEN REYES July 6, 2020
                                                 		CurrencyIsoCode //Karen Hung 16.12.2020 DOO-5111
                                                 FROM PricebookEntry WHERE Id IN: psId];

        //GET SALES ORG DATA - DOO-4641 XEN REYES July 6, 2020
        //SAP_01 -> Available; SAP_04 -> New Product; SAP_07 -> To sell old stocks
        Map<Id, Map<String, APTS_Sales_Org_Data__c>> pbe_salesOrg_orderable_Map = new Map<Id, Map<String, APTS_Sales_Org_Data__c>>();
        List<String> distributionChainSpecificMaterialOrderable_list = new List<String>();

        if(Test.isRunningTest()){
            distributionChainSpecificMaterialOrderable_list = new List<String>{'SAP_01', 'SAP_04', 'SAP_07'};
        } else {
            distributionChainSpecificMaterialOrderable_list = System.Label.TS_OrderableProducts.split(',');
        }

        if(!priceBookEntries.isEmpty()){
            Set<String> countrySet = new Set<String>();
            Set<String> productIdSet = new Set<String>();
            for(PricebookEntry eachPB : priceBookEntries) {
                if(eachPB.Sales_Organization__c != null){
                    String pb_var = eachPB.Sales_Organization__c.right(4);
                    countrySet.add(pb_var);
                }

                if(eachPB.Product2.Id != null){
                    productIdSet.add(eachPB.Product2.Id);
                }
            }

            if(!countrySet.isEmpty() || !productIdSet.isEmpty()){
                List<APTS_Sales_Org_Data__c> salesOrg_list = [SELECT Id, APTS_Sales_Org_Data_Name__c, APTS_Product__c FROM APTS_Sales_Org_Data__c 
                                                                WHERE APTS_Sales_Org_Data_Name__c IN: countrySet 
                                                                AND APTS_Product__c IN: productIdSet 
                                                                AND APTS_Distribution_chain_specific_materia__c IN: distributionChainSpecificMaterialOrderable_list];

                if(!salesOrg_list.isEmpty()){
                    for(APTS_Sales_Org_Data__c salesOrg_var : salesOrg_list){
                        if(pbe_salesOrg_orderable_Map.containsKey(salesOrg_var.APTS_Product__c)){
                            pbe_salesOrg_orderable_Map.get(salesOrg_var.APTS_Product__c).put(salesOrg_var.APTS_Sales_Org_Data_Name__c,salesOrg_var);
                        } else {
                            pbe_salesOrg_orderable_Map.put(salesOrg_var.APTS_Product__c, new Map<String, APTS_Sales_Org_Data__c>{salesOrg_var.APTS_Sales_Org_Data_Name__c => salesOrg_var});
                        }
                    }
                }
            }
        }
                                        		  
        JDEServicesCallout.JDEServiceOptimizationPort port = new JDEServicesCallout.JDEServiceOptimizationPort();
        JDEServicesCallout.PartTypes[] elem = new List<JDEServicesCallout.PartTypes>();

        for(PricebookEntry eachPriceBookEntry : priceBookEntries) {
            JDEServicesCallout.PartTypes partType = new JDEServicesCallout.PartTypes();
            partType.Name = eachPriceBookEntry.Product2.ProductCode; //KTS-1882 6.26.2018 Updated by Paul Aguiling
            partType.Country = eachPriceBookEntry.Country_ISO__c;    //Should be two letter
            partType.Description = eachPriceBookEntry.Product2.Description;             
            //partType.Cost = Integer.valueOf(eachPriceBookEntry.UnitPrice);
            partType.Cost = eachPriceBookEntry.UnitPrice;
            partType.Active = eachPriceBookEntry.Product2.IsActive;

            //DOO-4641 XEN REYES July 6, 2020
            if(eachPriceBookEntry.Product2.IsActive){
                if(pbe_salesOrg_orderable_Map.containsKey(eachPriceBookEntry.Product2.Id)){
                    if(eachPriceBookEntry.Sales_Organization__c != null){
                        String salesOrgStr = eachPriceBookEntry.Sales_Organization__c.right(4);
                        if(!pbe_salesOrg_orderable_Map.get(eachPriceBookEntry.Product2.Id).containsKey(salesOrgStr)){
                            partType.Active = false;
                        }
                    } else {
                        partType.Active = false;
                    }
                } else {
                    partType.Active = false;
                }
            }

            partType.PartID = eachPriceBookEntry.Id;
            partType.MaterialType = eachPriceBookEntry.Product2.APTS_Material_Type__c;
            //partType.IsServiceMaterial =  eachPriceBookEntry.Is_Service_Material__c ? 1 : 0;
            partType.CostCurrency = eachPriceBookEntry.CurrencyIsoCode; //Karen Hung 16.12.2020 DOO-5111
            elem.add(partType);           
            updatableIlogList.add( iLogMap.get(eachPriceBookEntry.Id) );
        }

        try {
            if (!elem.isEmpty()) {
                ExecuteQueueableCallOut eqc = new ExecuteQueueableCallOut();
                eqc.iLogList = updatableIlogList;
                eqc.elem = elem;            
                System.enqueueJob(eqc);
            }
            
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_PriceBookEntrySyncToClickException('Force to throw an exception');
            }
            
        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
    
        CustomLogging.pop();       
    }
    
	
	
    
}