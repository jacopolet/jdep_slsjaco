/**
* @author        Karen Hung
* @date          28.3.2020
* @description   Test class for TS_MCOperating_Scheduler
* @revision(s)   
*/
@isTest
public class TS_MCOperating_Scheduler_Test {
 
	private static testMethod void TriggerSchedule() {
		Test.startTest();

		User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(usr) {
           
           Datetime currentDate = System.now();
           Datetime computedDate = currentDate.addMinutes(1);
           
           String day = string.valueOf(computedDate.day());
           String month = string.valueOf(computedDate.month());
           String hour = string.valueOf(computedDate.hour());
           String minute = string.valueOf(computedDate.minute()); 
           String second = string.valueOf(computedDate.second());
           String year = string.valueOf(computedDate.year());
           String strSchedule = second + ' ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ?' + ' ' + year;
           
           Date mdate = date.today().toStartofWeek().addDays(1);

           TS_MCOperating_Scheduler mcTaskSChed = new TS_MCOperating_Scheduler(null);
           
           String jobID = System.schedule('Machine Clean Operating Scheduler Test Class:', strSchedule, mcTaskSChed);
           
            CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
            // Verify the job has not run
            System.assertEquals(0, ct.TimesTriggered);

        }
		Test.stopTest();
    }
    
    private static testMethod void TriggerScheduleEx() {
		Test.startTest();

		User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(usr) {
           
           Datetime currentDate = System.now();
           Datetime computedDate = currentDate.addMinutes(1);
           
           String day = string.valueOf(computedDate.day());
           String month = string.valueOf(computedDate.month());
           String hour = string.valueOf(computedDate.hour());
           String minute = string.valueOf(computedDate.minute()); 
           String second = string.valueOf(computedDate.second());
           String year = string.valueOf(computedDate.year());
           String strSchedule = second + ' ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ?' + ' ' + year;
           
           Date mdate = date.today().toStartofWeek().addDays(1);

           TS_MCOperating_Scheduler mcTaskSChed = new TS_MCOperating_Scheduler(null);
           TS_MCOperating_Scheduler.hasException = true;
           
           String jobID = System.schedule('Machine Clean Operating Scheduler Test Class:', strSchedule, mcTaskSChed);
           
            CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
            // Verify the job has not run
            System.assertEquals(0, ct.TimesTriggered);
        }
		Test.stopTest();	
	}
    
}