@isTest
Public class APTS_ProcessUsageInputSchedulerTest{
    public static testMethod void testUsageInputschedule() {
        
        APTS_ProcessUsageInputScheduler sh1 = new APTS_ProcessUsageInputScheduler();
        Test.startTest();
            Datetime dt = Datetime.now().addMinutes(1);
            String CRON_EXP = '0 '+ dt.minute() + ' * ' + dt.day() + ' ' + dt.month() + ' ? ' + dt.year(); 
            system.schedule('Usage Input', CRON_EXP, sh1); 
        Test.stopTest(); 
        }
    
}