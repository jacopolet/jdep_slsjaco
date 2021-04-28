/**
* Class Name : APTS_DeleteFireAndForget_Scheduler_Test
* Description : Apex Class to test APTS_DeleteFireAndForget_Scheduler Class
* Author : V. Shankaranarayanan (v.shankaranarayanan@accenture.com)
* Date Created : 09-05-2018
**/
@isTest
private class APTS_DeleteFireAndForget_Scheduler_Test{
    
    private static String status = 'Outbound Message Triggered';
    static String schedule = '0 0 0 1 1 ? 2050';
    
    /**Method Name : testData
    * Description : Method used to create test data
    **/
    @testSetup
    static void testData(){
        IntegrationUserAndProfile__c custSetting = APTS_TestDataFactory.createIntegrationUserAndProfile();
        Database.insert(custSetting, false);
        
        List<APTS_IntegrationLogFireForgetInterfaces__c> interfaceSetting = APTS_TestDataFactory.createFandFInterfaces();
        Database.insert(interfaceSetting, false);
        
        List<Integration_Log__c> logList = APTS_TestDataFactory.createIntegrationLog(200, status);
        Database.insert(logList, false);
        
        List<Integration_Log__c> logUpdateList = new List<Integration_Log__c>();
        for(Integration_Log__c log : [SELECT Id, Object__c FROM Integration_Log__c WHERE Integration_Status__c =: status LIMIT 50000]){
            log.Object__c = 'RelatedInvoice__c';
            logUpdateList.add(log);
        }
        Database.update(logUpdateList, false);
    }
    
    /**Method Name : testScheduler
    * Description : Method to test APTS_DeleteFireAndForgetBatch_Scheduler scheduler
    **/
    @isTest
    static void testScheduler(){
        APTS_DeleteFireAndForget_Scheduler schedulerClass = new APTS_DeleteFireAndForget_Scheduler();

        test.startTest();
        String jobId = System.Schedule(status, schedule, schedulerClass);
        test.stopTest();
        
        CronTrigger cronTgr = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id =: jobId];
        System.assertEquals(schedule, cronTgr.CronExpression);
        System.assertEquals(0, cronTgr.TimesTriggered);
        System.assertEquals('2050-01-01 00:00:00', String.valueOf(cronTgr.NextFireTime));
    }
    
}