/**
* Class Name : APTS_MeterReadingDataDelete_Test
* Description : Test Class to test the Batch class APTS_MeterReadingDataDelete and the APTS_MeterRdngDtDeltSchedule class                    
* Classes Covered : APTS_MeterReadingDataDelete(92% Code Coverage)
                    APTS_MeterRdngDtDeltSchedule(100% Code Coverage)
* Author : Kiruthika Pachaimaal
* Date Created : 15/05/2018
**/
@isTest
private class APTS_MeterReadingDataDelete_Test {
    
    /**
    * Method Name : static void setupData()
    * Description : Test Setup Data Method to create test data                    
    * Author : Kiruthika Pachaimaal
    * Date Created : 15/05/2018
    **/
    @testSetup
    static void setupData(){
        
        APTS_Meter_Reading_Data__c mtrRdDt = new APTS_Meter_Reading_Data__c();
        //mtrRdDt.APTS_Status__c = 'Completed';
        Database.insert(mtrRdDt);
        APTS_Meter_Reading_Data__c mtrRdDt0 = new APTS_Meter_Reading_Data__c();
        mtrRdDt0.APTS_Status__c = 'Completed';
        Database.insert(mtrRdDt0);
        
       // mtrRdDt0.Id = 'a9J4E0000008T1q123';
    }
    
    /**
    * Method Name : static void testMeterReadingData()
    * Description : Test Method to test APTS_MeterRdngDtDeltSchedule and APTS_MeterReadingDataDelete batch                
    * Author : Kiruthika Pachaimaal
    * Date Created : 15/05/2018
    **/
   // @isTest
    static testMethod void testMeterReadingData(){
        
        User usr = [Select id from User where Id = :UserInfo.getUserId() limit 1];
        System.RunAs(usr){
            Test.startTest();
            APTS_MeterRdngDtDeltSchedule testsche = new APTS_MeterRdngDtDeltSchedule();
            String sch = '0 0 23 * * ?';
            system.schedule('Test status Check', sch, testsche );
            List<APTS_Meter_Reading_Data__c >Mlist = [Select id,APTS_Status__c from APTS_Meter_Reading_Data__c WHERE APTS_Status__c ='Completed'];
            System.assert(Mlist.size() > 0);
            Test.stopTest();
        }
    }
}