/**
* @author        Marvin Gatchalian
* @date          5.mar.2018
* @description   Apex class used to execute Pricebook Entry SyncToClick batch by creating Integration Log 
* @revision(s)
*/
public with sharing class TS_PricebookEntry_SyncToClick_Execute {
	
	public Map <pricebookentry, Integration_Log__c> createIntegrationLogPerPriceBookEntry (List<pricebookentry> priceBookEntries) {
        CustomLogging.push('createIntegrationLogPerPriceBookEntry', 'TS_PricebookEntry_SyncToClick_Execute');
		Map <pricebookentry, Integration_Log__c> priceBookEntryIntegrationLogMap  = new
		Map <pricebookentry, Integration_Log__c>();
		
        try {
            
            for(PricebookEntry eachPriceBookEntry :priceBookEntries) {
                if (!eachPriceBookEntry.TS_Click_Synchronized__c) {
                	
                	Integration_Log__c integLog = new Integration_Log__c();
                	
                    integLog.Object_Id__c = eachPriceBookEntry.Id;
                    integLog.Object__c = INT_Constants.CLICK_SYNCMASTERPRODUCT;
                    integLog.Integration_Status__c = INT_Constants.INITIAL;
                    integLog.Triggered_Timestamp__c = Datetime.now();
                    
                    eachPriceBookEntry.TS_Click_Synchronized__c = true;
                    
                    priceBookEntryIntegrationLogMap.put(eachPriceBookEntry, integLog);
                }
            }

        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        
        CustomLogging.pop();
		return priceBookEntryIntegrationLogMap;
	}
    
}