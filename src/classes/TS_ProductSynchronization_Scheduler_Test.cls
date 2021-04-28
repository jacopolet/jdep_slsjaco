/*
* @author        Marvin Gatchalian
* @date          8.mar.2018          
* @description   Test class for TS_ProductSynchronization_Scheduler
* @revision(s)
*/


@isTest
public with sharing class TS_ProductSynchronization_Scheduler_Test {
	private static testMethod void TS_ProductSynchronization_Scheduler() {
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
			
			TS_ProductSynchronization_Scheduler productSyncSched = new TS_ProductSynchronization_Scheduler(computedDate);
			String jobID = System.schedule('Product Synchronization Scheduler Test Class:', strSchedule, productSyncSched);
			
			CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
   					          FROM CronTrigger WHERE id = :jobId];
   			// Verify the job has not run
   			System.assertEquals(0, ct.TimesTriggered);
   			System.assertEquals(computedDate, ct.NextFireTime);
			
		Test.stopTest();
		
	}
    
    /*12.5.18 method with exception*/
    private static testMethod void TS_ProductSynchronization_SchedulerEx() {
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
			
       		TS_ProductSynchronization_Scheduler.hasException = true;
			TS_ProductSynchronization_Scheduler productSyncSched = new TS_ProductSynchronization_Scheduler(computedDate);
			String jobID = System.schedule('Product Synchronization Scheduler Test Class:', strSchedule, productSyncSched);
			
			CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
   					          FROM CronTrigger WHERE id = :jobId];
   			// Verify the job has not run
   			System.assertEquals(0, ct.TimesTriggered);
   			System.assertEquals(computedDate, ct.NextFireTime);
			
		Test.stopTest();
		
	}
    
	
}