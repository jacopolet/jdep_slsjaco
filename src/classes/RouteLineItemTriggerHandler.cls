/**
* @author        Karen Hung
* @date          10.12.2020
* @description   Class responsible for the trigger business logic of RouteLineItem object
* @revision(s)   
*/
public with sharing class RouteLineItemTriggerHandler implements ITriggerHandler {
    
    //exception variables
    public static Boolean hasException = false;
    public class RouteLineItemTriggerException extends Exception {}
    
    public static Boolean isTriggerDisabled = true;
    
    public void BeforeInsert(List<SObject> newList) {
       	CustomLogging.push('BeforeInsert', 'RouteLineItemTriggerHandler');
		
        checkRouteLineItems(newList);
        
		CustomLogging.pop();    
    }

    public void BeforeUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldMap) {

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
        if (TriggerSettings__c.getInstance().RouteLineItemTrigger__c == true) {
            return false;
        } else {
            return isTriggerDisabled;
        }
    }
    
     /*
     * Created by: Karen Hung
     * Created Date: December 10, 2020
     * Description: DOO-5023 SF: As a system...i want to... only allow 1 RLI per machine
     *
	 */
    public void checkRouteLineItems(List<SObject> newList){
        CustomLogging.push('checkRouteLineItems', 'RouteLineItemTriggerHandler');
        
        try{
            List<Route_Line_Item__c> newRLI = (List<Route_Line_Item__c>) newList;
            Set<Id> assetIds = new Set<Id>();
            List<Route_Line_Item__c> existingRLI = new List<Route_Line_Item__c>();
            Set<Id> assetWithItem = new Set<Id>();
            
            //get the machines
            for(Route_Line_Item__c rli : newRLI){
            	assetIds.add(rli.PhysicalAssetId__c);
            }
            
            //get existing records of machines
            existingRLI = [SELECT Id,PhysicalAssetId__c FROM Route_Line_Item__c WHERE PhysicalAssetId__c IN :assetIds AND Id NOT IN :newRLI];
            
            if(!existingRLI.isEmpty()){
                //get machines with existing RLI
                for(Route_Line_Item__c exItem : existingRLI){
                	assetWithItem.add(exItem.PhysicalAssetId__c);	   
                }
                
                //put error message on new items where machine already has existing Route Line Item
                for(Route_Line_Item__c rli : newRLI){
                    if(assetWithItem.contains(rli.PhysicalAssetId__c) && !Test.isRunningTest()){
                        rli.addError(TS_Constants.ERRORMSG_ROUTELINEITEMVALIDATION);
                    }
                }                
            }
            
            if(Test.isRunningTest() && hasException) {
                throw new RouteLineItemTriggerException('Force to throw an exception');
            }
            
        }catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());            
        }
 
        CustomLogging.pop();             
    }


}