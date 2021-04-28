/**
* @author        Karen Hung
* @date          12.11.2019
* @description   Class responsible for the trigger business logic of Part Request Line Item , part of DOO-2196
* @revision(s)   
*/

public without sharing class PartRequestLineItemTriggerHandler implements ITriggerHandler {
	public static Boolean isTriggerDisabled = true;
       
    public class PartRequestLineItemTriggerHandlerException extends Exception {}
    
    public static boolean hasException = false;
    
    public void BeforeInsert(List<SObject> newList) {
        try{
            if (Test.isRunningTest() && hasException) {
                throw new PartRequestLineItemTriggerHandlerException(TS_Constants.FORCE_EXCEPTION);
            }
            validateItem(newList);
        }catch(Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());          
        } 	
    }

    public void BeforeUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldMap) {
        try{
            if (Test.isRunningTest() && hasException) {
                throw new PartRequestLineItemTriggerHandlerException(TS_Constants.FORCE_EXCEPTION);
            }
            validateItem(newList);
        }catch(Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());          
        } 
    }

    public void BeforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems) {

    }

    public void AfterInsert(List<SObject> newList, Map<Id, SObject> newItems) {

    }

    public void AfterUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldMap) {

    }

    public void AfterDelete(List<SObject> oldList, Map <Id, SObject> oldItems) {

    }

    public void AfterUndelete(List<SObject> newList, Map <Id, SObject> newItems) {

    }

    public Boolean IsDisabled() {
        if (TriggerSettings__c.getInstance().PartRequestLineItemTrigger__c == true) {
            return false;
        } else {
            return isTriggerDisabled;
        }
    }
    
    
    /****Method for custom validation***/
    public void validateItem(List<Part_Request_Line_Item__c> newList){
        CustomLogging.push('validateItem', 'PartRequestLineItemTriggerHandler');
        //throw error if there's no matching pricebookentry for product and sales organization
        try{
            
            if (Test.isRunningTest() && hasException) {
                throw new PartRequestLineItemTriggerHandlerException(TS_Constants.FORCE_EXCEPTION);
            }
            
            List<String> productList = new List<String>();
            Map<String,String> itemProductMap = new Map<String,String>();
            for(Part_Request_Line_Item__c prli : newList){
                productList.add(prli.Product__c);
            }           
            
            //Get Pricebook entries
            Map<String, PriceBookEntry> pbeMap = new Map<String, PriceBookEntry>();
            for(PriceBookEntry pbEntry : [SELECT Id,Sales_Organization__c, Product2Id FROM PriceBookEntry 
                                          WHERE Sales_Organization__c != null 
                                          AND Product2Id != null 
                                          AND IsActive = true
                                          AND Product2Id IN :productList]){
                pbeMap.put(pbEntry.Sales_Organization__c + pbEntry.Product2Id, pbEntry);    
            }

            //XEN REYES DOO-5265 Jan. 27, 2021
            List<String> distributionChainSpecificMaterialOrderable_list = new List<String>();
            if(Test.isRunningTest()){
                distributionChainSpecificMaterialOrderable_list = new List<String>{'SAP_01', 'SAP_04', 'SAP_07', 'SAP_03'};
            } else {
                distributionChainSpecificMaterialOrderable_list = System.Label.TS_OrderableProducts.split(',');
            }

            //Karen Hung  20.05.2020 DOO-4440 check sales org data if part is relevant
            Set<String> orgProductSet = new Set<String>();
            if(!productList.isEmpty()){
                for(APTS_Sales_Org_Data__c orgData : [SELECT Id, APTS_Product__c, APTS_Distribution_chain_specific_materia__c, APTS_Sales_Org_Data_Name__c FROM APTS_Sales_Org_Data__c
                                                      WHERE APTS_Product__c IN :productList AND APTS_Distribution_chain_specific_materia__c IN: distributionChainSpecificMaterialOrderable_list]){

                   orgProductSet.add('SAP_'+ orgData.APTS_Sales_Org_Data_Name__c + orgData.APTS_Product__c);                   
                }
            }

            for(Part_Request_Line_Item__c prlItem : newList){
                if(pbeMap.get(prlItem.Sales_Organization__c + prlItem.Product__c) == null){
                    prlItem.addError(TS_Constants.ERRORMESSAGE_NOPBENTRY);  //This product is not in your country’s price list. Please contact your administrator.
                }

                //Karen Hung  20.05.2020 DOO-4440 put error if part is not relevant for the country
                if(!orgProductSet.contains(prlItem.Sales_Organization__c + prlItem.Product__c)){
                    prlItem.addError(TS_Constants.ERRORMESSAGE_NOTRELEVANT);  //You are not allowed to order part that is not relevant in your country.  
                }
            }
            
        }catch(Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());       
        }
        
        CustomLogging.pop();        
    }    
}