/**
* Class Name : APTS_DeleteOpenOrdersBatchScheduler_Test
* Description : Apex Class to test APTS_DeleteOpenOrdersBatch_Scheduler Class
* Author : Hariharan
* Date Created : 04/04/2018
**/
@isTest
private class APTS_DeleteOpenOrdersBatchScheduler_Test{
    
    static String schedule = '0 0 0 1 1 ? 2050';
    
    /**Method Name : testData
    * Description : Method used to create test data
    **/
      @testSetup
    static void testData(){
        string acctName = 'Test'+ string.valueOf(Math.random());
        Account testAccount = APTS_TestDataFactory.createAccount(acctName);
        Database.insert(testAccount, false); 
        
        Apttus_Config2__PriceList__c  testPriceList = APTS_TestDataFactory.createPriceList('Test JDE PriceList');
        Database.insert(testPriceList, false);  
        
        Contact testContact = APTS_TestDataFactory.createContact(testAccount ,'9999912345');
        Database.insert(testContact, false);
        
        Apttus_Config2__Order__c  testOrder = APTS_TestDataFactory.createOrder(testAccount.Id, testPriceList.Id, testContact.Id);
        Database.insert(testOrder); 
    }
/**Method Name : testScheduler
 * Description : Method to test the scheduler
 **/  
   static testMethod void testScheduler(){
     APTS_DeleteOpenOrdersBatch_Scheduler sch = new APTS_DeleteOpenOrdersBatch_Scheduler();      
     test.startTest();
     String schitem = System.Schedule('APTS_DeleteOpenOrdersBatch_Scheduler', schedule, sch);
     Test.stopTest();
    }
   }