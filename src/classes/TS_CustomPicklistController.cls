/**
* @author        Rey Austral
* @date          9.28.2017           
* @description   Controller for  TS_CustomPicklist (Lightning Component)
* @revision(s)
*/
public with sharing class TS_CustomPicklistController {
	@AuraEnabled
    public static List < PickListWrapper > fetchPicklistValues(String objectName, String fieldAPI) {
    	List<PickListWrapper> result = new List<PickListWrapper>();
    	Schema.DescribeSObjectResult sobjectType = Schema.getGlobalDescribe().get(objectName).getDescribe();
    	Schema.DescribeFieldResult sObjectResult = sobjectType.fields.getMap().get( fieldAPI ).getDescribe();
    	List<Schema.PicklistEntry> pick_list_values = sObjectResult.getPickListValues();
    	for (Schema.PicklistEntry a : pick_list_values) { //for all values in the picklist list
            PickListWrapper pick = new PickListWrapper();
            pick.value = a.getValue();
            pick.label = a.getLabel();
            pick.selected = false;//ref.fieldValue.contains(a.getValue()) ? true : false;                        
            result.add(pick);//add the value  to our final list
        }   
    	return result;
    }

    public class PickListWrapper {
    	@AuraEnabled 
    	public String value { get; set; }
        @AuraEnabled 
        public String label { get; set; }
    	@AuraEnabled
    	public Boolean selected { get; set; }
    }

}