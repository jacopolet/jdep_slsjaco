/**
* Class Name : APTS_NetPriceExtractionScheduler
* Description :Scheduler class for APTS_NetPriceExtractionBatch
* Author : Venky Muppalaneni 
* Date Created : 07/05/2020
**/
//v1 
global without sharing class APTS_NetPriceExtractionScheduler implements Schedulable {
	global void execute(SchedulableContext sc) {
		Set<ID> accountSet = new Set<ID> ();
		//List<string> exclusionAccountList = System.Label.APTS_NetPriceExtractionAccountExclusionList.split(',');
		Set<string> exclusionAccountList = new Set<String>();
		For(APTS_NetPriceExtAccountExclusionTable__mdt exlcAcc : [select id,label from APTS_NetPriceExtAccountExclusionTable__mdt where APTS_isActive__c = true]){
			exclusionAccountList.add(exlcAcc.Label);
		}
		For (Account a :[select id,SAP_Customer_ID__c,parent.SAP_Customer_ID__c,parent.parent.SAP_Customer_ID__c,parent.parent.parent.SAP_Customer_ID__c,parent.parent.parent.parent.SAP_Customer_ID__c from Account where id in(Select APTS_Sold_to_Party__c from APTS_Contract_Entitlement_Repository__c where APTS_Contributing_Agreement_Level__c =: APTS_CERUtility.CHILD and APTS_Agreement_Type__c =: APTS_CERUtility.STANDARD_DEAL and(APTS_Start_Date__c = TODAY OR APTS_End_Date__c = YESTERDAY ) and(APTS_Agreement_Line_Item__r.APTS_Bundle_Option__c = true or APTS_Agreement_Line_Item__r.APTS_Ingredient_Standalone__c = true or APTS_Agreement_Line_Item__r.APTS_More_Standalone__c = true) and APTS_Is_Pending__c = false)])
		{
			if(!exclusionAccountList.contains(a.SAP_Customer_ID__c) && !exclusionAccountList.contains(a.parent.SAP_Customer_ID__c) && !exclusionAccountList.contains(a.parent.parent.SAP_Customer_ID__c) && !exclusionAccountList.contains(a.parent.parent.parent.SAP_Customer_ID__c) && !exclusionAccountList.contains(a.parent.parent.parent.parent.SAP_Customer_ID__c)){
				accountSet.add(a.id);
			}
		}
		if(accountSet.size()>0 || Test.isRunningTest())
		{
		String inClause = String.format('(\'\'{0}\'\')',
		                                new List<String> { String.join(new List<Id> (accountSet), '\',\'') });
		String query = 'SELECT Id FROM Account WHERE(Purchasing_Organization__c IN ' + inClause + '  OR Parent.Parent.Id IN ' + inClause + ' OR Parent.Id IN ' + inClause + ' OR ID IN ' + inClause + ' ) limit 50000';
		database.executeBatch(new APTS_NetPriceExtractionBatch(query), 1);
		}

	}
}