/**
* Class Name : APTS_NetPriceExtractionSchedulerTest
* Description : Apex Class to test APTS_NetPriceExtractionScheduler Class
* Author : Venky Muppalaneni
* Date Created : 07/05/2020
**/
@isTest
public class APTS_NetPriceExtractionSchedulerTest  {
 static String schedule = '0 0 0 1 1 ? 2050';
    
    /**Method Name : testData
    * Description : Method used to create test data
    **/
      @testSetup
    static void testData(){
    
        
         List<Apttus__APTS_Agreement__c> agreementList=new list <Apttus__APTS_Agreement__c>();
        
        Account acc = APTS_TestUtils.createaccount();
        Database.insert(acc,false);
        
        Contact cont = APTS_TestUtils.createContact();
        Database.insert(cont,false);
        
        Apttus_Config2__PriceList__c plist = APTS_TestUtils.createPriceList();
        Database.insert(plist,false);
       
        Apttus__APTS_Agreement__c aggr = APTS_TestUtils.createAgreement(cont.Id,null,plist.Id,acc.Id);
        aggr.Apttus__Contract_End_Date__c = System.today()-1;
        aggr.Apttus__Status_Category__c = 'In Effect';
        aggr.Apttus__Status__c = 'Activated';
        aggr.Apttus__Contract_Start_Date__c = System.today()-50;
        aggr.Apttus__Auto_Renewal__c = true;
        agreementList.add(aggr);
                
        Database.insert(agreementList, false);
        
    }
/**Method Name : testScheduler
 * Description : Method to test the scheduler
 **/  
   static testMethod void testScheduler(){
     APTS_NetPriceExtractionScheduler sch = new APTS_NetPriceExtractionScheduler();      
     test.startTest();
     String schitem = System.Schedule('APTS_NetPriceExtractionScheduler', schedule, sch);
     Test.stopTest();
     
        CronTrigger cronTgr = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id =: schitem];
        System.assertEquals(schedule, cronTgr.CronExpression);
        System.assertEquals(0, cronTgr.TimesTriggered);
        System.assertEquals('2050-01-01 00:00:00', String.valueOf(cronTgr.NextFireTime));
     
    }
}