@isTest
private class EmailBatchMonitoringTest {

    static testMethod void EmailBatchMonitoringTest () {        
         test.starttest();
         EmailBatchMonitoring myClass = new EmailBatchMonitoring ();   
         String chron = '0 0 23 * * ?';        
         system.schedule('Test Sched', chron, myClass);
         test.stopTest();
        
         List<AsyncApexJob> jobsScheduled = [select Id, ApexClassID, ApexClass.Name, Status, JobType from AsyncApexJob where JobType = 'ScheduledApex'];
         System.assertEquals(1, jobsScheduled.size(), 'expecting one scheduled job');
    }
}