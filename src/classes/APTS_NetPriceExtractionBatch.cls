global class APTS_NetPriceExtractionBatch implements Database.Batchable<sObject>, Database.Stateful {
	
	String query;
	String countryCode;
	String segment;
	//private List<Id> lstExpiredAgreementsId = new List<Id>();

	global APTS_NetPriceExtractionBatch(String queryInput) {
	query=queryInput;
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		//query = 'select id from Account where Sales_Organization__c =:countryCode and Segment__c=:segment';
		
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<sObject> scope) {	
		List<Account> lstAccount = (List<Account>) scope;
		for(Account tmpAcc : lstAccount){
			APTS_NetPriceExtraction.insertNetPrice(tmpAcc.Id);
		}
	}
	
	global void finish(Database.BatchableContext BC) {

	}
	
}