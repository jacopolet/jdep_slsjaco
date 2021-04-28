/**
* @author           Abram Vixen Reyes
* @date				Jan. 24, 2019
* @description      Test Class for TS_ClickSessionId_Scheduler
* @revision(s)   
*                
*/
@isTest
public class TS_ClickSessionId_SchedulerTest {
	
    private static testMethod void TriggerSchedule() {
        Test.startTest();
        
        Datetime currentDate = System.now();
        Datetime computedDate = currentDate.addMinutes(1);
        
        String day = string.valueOf(computedDate.day());
        String month = string.valueOf(computedDate.month());
        String hour = string.valueOf(computedDate.hour());
        String minute = string.valueOf(computedDate.minute()); 
        String second = string.valueOf(computedDate.second());
        String year = string.valueOf(computedDate.year());
        String strSchedule = second + ' ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ?' + ' ' + year;
        
        TS_ClickSessionId_Scheduler clickSched = new TS_ClickSessionId_Scheduler();
        String jobID = System.schedule('Click Session Id Test Class:', strSchedule, clickSched);
        
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
                          FROM CronTrigger WHERE id = :jobId];
        
        //Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);
        
        Test.stopTest();
    }
    
     private static testMethod void testifCurrentbusy() {
		Test.startTest();
			Datetime dt = Datetime.now().addMinutes(5);
			String timeForScheduler = dt.format('s m H d M \'?\' yyyy');
        	TS_ClickSessionId_Scheduler.hasException = true;
			TS_ClickSessionId_Scheduler tsc = new TS_ClickSessionId_Scheduler();		
         	String jobID = System.schedule('Click Session Id Test Class Has Exception:', timeForScheduler, tsc);
		Test.stopTest();
		
	}
}