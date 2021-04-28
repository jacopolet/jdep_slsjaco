/**
* @author        Anna Gonzales
* @date          6.30.2017           
* @description   Test class for WaterFilterChangeConTriggerScheduler
* @revision(s)
*/
@isTest
private class WaterFilterChangeConTriggerSchedulerTest {
    
    static testMethod void testWaterFilterChangeConTriggerScheduler(){  
        Test.startTest();
           String jobId = System.schedule('testWaterFilterChangeConTriggerScheduler', '0 0 4 * * ?', new WaterFilterChangeConTriggerScheduler());
        Test.stopTest();
        
        List<CronTrigger> cronJob = [select Id, cronExpression, TimesTriggered, NextFireTime from CronTrigger where (Id = :jobId)];
        
        if(!cronJob.isEmpty()){
            CronTrigger schedJob = cronJob.get(0);
            system.assert(schedJob.CronExpression.equals('0 0 4 * * ?'));
            system.assert(schedJob.TimesTriggered == 0);
            system.assert(schedJob.NextFireTime.hour() == 4);
        }
    }
    
    static testMethod void testErrorWaterFilterChangeConTriggerScheduler(){
      WaterFilterChangeConTriggerScheduler.hasException = true;
      System.schedule('testWaterFilterChangeConTriggerScheduler', '0 0 4 * * ?', new WaterFilterChangeConTriggerScheduler());  
      System.assert(WaterFilterChangeConTriggerScheduler.hasException = true);
    }   
    
}