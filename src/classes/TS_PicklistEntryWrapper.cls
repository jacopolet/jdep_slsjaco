/**
* @author        Rey Austral
* @date          9.28.2017           
* @description   Wrapper Class that is used for the dependent picklist
* @revision(s)
*/
public with sharing class TS_PicklistEntryWrapper {		
	@AuraEnabled public String label { get; set; }
	@AuraEnabled public String value { get; set; }	
	@AuraEnabled public List<TS_PicklistEntryWrapper> dependentPickList { get; set; }
}