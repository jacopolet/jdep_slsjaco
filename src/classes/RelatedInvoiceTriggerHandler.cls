/**
* @author        Karen Hung
* @date          24.11.2020
* @description   Class responsible for the trigger business logic of Related Invoice object
* @revision(s)   
*/
public with sharing class RelatedInvoiceTriggerHandler implements ITriggerHandler {
    public static Boolean isTriggerDisabled = true;
    
    public void BeforeInsert(List<SObject> newList) {
      
    }

    public void BeforeUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldMap) {
   		unlinkToCase(newList, oldMap);    
    }

    public void BeforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems) {
		preventDeletion(oldList);	
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
        if (TriggerSettings__c.getInstance().RelatedInvoiceTrigger__c == true) {
            return false;
        } else {
            return isTriggerDisabled;
        }
    }
    
    /*
     * Created by: Karen Hung
     * Created Date: November 24, 2020
     * Description: DOO-4734 prevent related deletion if dunning block = true
     *
	 */
    public void preventDeletion(List<SObject> oldList){
        CustomLogging.push('preventDeletion', 'RelatedInvoiceTriggerHandler');
        List<Related_Invoice__c> oldRI = (List<Related_Invoice__c>) oldList;
        for(Related_Invoice__c item : oldRI){
            if(item.Dunning_Block__c){
            	item.addError(TS_Constants.ERRORMSG_RELATEDINVOICEVALIDATION);    
            }
        }
        CustomLogging.pop();        
    }
    
    /*
     * Created by: Karen Hung
     * Created Date: November 24, 2020
     * Description: DOO-4734 remove case field value if Remove Link to Invoice is executed in lightning action
     *
	 */
    public void unlinkToCase(List<SObject> newList, Map<Id, SObject> oldMap){
   		CustomLogging.push('unlinkToCase', 'RelatedInvoiceTriggerHandler');
        Map<Id, Related_Invoice__c> oldRec = (Map<Id, Related_Invoice__c>) oldMap;
        
        for(Related_Invoice__c item : (List<Related_Invoice__c>) newList){
        	
            if(item.Case__c != null && 
               !item.Dunning_Block__c &&
               item.Remove_Link__c != oldRec.get(item.Id).Remove_Link__c){
            	
                   item.Case__c = null;
            }
            
        }
        CustomLogging.pop();
    }
    
    
    

}