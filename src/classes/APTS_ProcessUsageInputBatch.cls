/*
 * Author: Amit
 * Version: V1
 * Class : Batch class to rate usage input 
 */
global class APTS_ProcessUsageInputBatch implements Database.Batchable<sObject>{
	global Database.QueryLocator start(Database.BatchableContext BC){
 		string query = 'Select Id from Apttus_Billing__UsageInput__c where Apttus_Billing__Status__c = \'Loaded\'';
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<Apttus_Billing__UsageInput__c> scope){
        Set<ID> usageInputIDs = new Set<ID>(); 
        for(Apttus_Billing__UsageInput__c usgInp : scope){
            usageInputIDs.add(usgInp.Id);
        }
        system.debug('usageInputIDs ==> '+usageInputIDs);
        Apttus_Billing.BillingService.processPendingUsageInput(usageInputIDs,true); 
    }
    global void finish(Database.BatchableContext BC){
    }
}