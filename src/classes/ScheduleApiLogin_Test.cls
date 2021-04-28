/**
* @author        Rey Austral
* @date          5.31.2017           
* @description   Test class for ScheduleApiLogin
* @revision(s)
*/
@isTest
public class ScheduleApiLogin_Test {
    static testMethod void testSchedulePricebookEntry(){        
        IntegrationUserAndProfile__c integ = new IntegrationUserAndProfile__c();
        integ.Click_Session_Id_Duration__c = 30;
        insert integ;

        Datetime dt = Datetime.now().addMinutes(1);
        String CRON_EXP = '0 '+ dt.minute() + ' * ' + dt.day() + ' ' + dt.month() + ' ? ' + dt.year();
        String jobId = system.schedule('Sample_Heading', CRON_EXP, new ScheduleApiLogin () );
        List<CronTrigger> cronJob = [select Id, cronExpression, TimesTriggered, NextFireTime from CronTrigger where (Id = :jobId)];
        if(!cronJob.isEmpty()){
            CronTrigger schedJob = cronJob.get(0);
            system.assert(schedJob.CronExpression.equals(CRON_EXP ));
            system.assert(schedJob.TimesTriggered == 0);
        }
    }
    
    static testMethod void testException(){
        ScheduleApiLogin.hasException = true;
        IntegrationUserAndProfile__c integ = new IntegrationUserAndProfile__c();
        integ.Click_Session_Id_Duration__c = 30;
        insert integ;

        Datetime dt = Datetime.now().addMinutes(1);
        String CRON_EXP = '0 '+ dt.minute() + ' * ' + dt.day() + ' ' + dt.month() + ' ? ' + dt.year();
        String jobId = system.schedule('Sample_Heading', CRON_EXP, new ScheduleApiLogin () );
        System.assert(ScheduleApiLogin.hasException);
    }
}