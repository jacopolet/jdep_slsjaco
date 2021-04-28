/*
* @author        Marvin Gatchalian
* @date          8.mar.2018          
* @description   Test class for TS_PricebookEntry_SyncToClick_Scheduler
* @revision(s)
*/


@isTest
public with sharing class TS_PricebookEntry_SyncToClick_Sched_Test {
	private static testMethod void TS_PricebookEntry_SyncToClick_Scheduler() {
		
		IntegrationUserAndProfile__c customSettings = new IntegrationUserAndProfile__c();
		customSettings.ClickPriceBookEntryScheduleDuration__c = 10800;
		customSettings.Click_Product_Batch_Limit__c = 50; 
		insert customSettings;
		
		Test.startTest();
			
			Datetime currentDate = System.now();
			Datetime computedDate = currentDate.addDays(7);
			
			String day = string.valueOf(computedDate .day());
			String month = string.valueOf(computedDate .month());
			String hour = string.valueOf(computedDate .hour());
			String minute = string.valueOf(computedDate .minute()); 
			String second = string.valueOf(computedDate .second());
			String year = string.valueOf(computedDate .year());
			String strSchedule = second + ' ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ?' + ' ' + year;
			
			TS_PricebookEntry_SyncToClick_Scheduler productSyncSched = new TS_PricebookEntry_SyncToClick_Scheduler(computedDate);
			String jobID = System.schedule('Pricebook Entry Sync Scheduler Test Class:', strSchedule, productSyncSched);
			
			CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
   					          FROM CronTrigger WHERE id = :jobId];
   			// Verify the job has not run
   			System.assertEquals(0, ct.TimesTriggered);
   			System.assertEquals(computedDate, ct.NextFireTime);
			
		Test.stopTest();
		
	}
	
}