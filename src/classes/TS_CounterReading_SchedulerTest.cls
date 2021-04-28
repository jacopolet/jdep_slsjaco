/*
* @author        Archi Delphinanto
* @date          14 March 2018          
* @description   Test class for TS_CounterReading_Batch
* @revision(s)
*/
@isTest
public with sharing class  TS_CounterReading_SchedulerTest {
	
	private static testMethod void testScheduler() {
		Test.startTest();

			Datetime dt = Datetime.now().addMinutes(5);
			String timeForScheduler = dt.format('s m H d M \'?\' yyyy');

			Id schedId = System.Schedule('<<First Counter Reading Task Batch>>', timeForScheduler,new TS_CounterReading_Scheduler());

	        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
   					          FROM CronTrigger WHERE id = :schedId ];
   			// Verify the job has not run
   			System.assertEquals(0, ct.TimesTriggered);
		
		Test.stopTest();
		
	}
    
    private static testMethod void testifCurrentbusy() {
		Test.startTest();
			Datetime dt = Datetime.now().addMinutes(5);
			String timeForScheduler = dt.format('s m H d M \'?\' yyyy');
        	TS_CounterReading_Scheduler.hasException = true;
			TS_CounterReading_Scheduler tsc = new TS_CounterReading_Scheduler();
			//tsc.runningJobCount = 5; // to simulate 5 batch jobs
			Id schedId = System.Schedule('<<First Counter Reading Task Batch>>', timeForScheduler, tsc);

	        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
   					          FROM CronTrigger WHERE id = :schedId ];
   			// Verify the job has not run
   			System.assertEquals(0, ct.TimesTriggered);
		
		Test.stopTest();
		
	}

  
}