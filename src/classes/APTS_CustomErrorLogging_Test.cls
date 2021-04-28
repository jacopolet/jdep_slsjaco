/**
* Class Name : APTS_CustomErrorLogging_Test
* Description : Test Class to test APTS_CustomErrorLogging Apex class
* Author : Venky Muppalaneni
* Date Created : 22-06-2020
**/
@isTest
private class APTS_CustomErrorLogging_Test{

    /**Method Name : testLogging
    * Description : Method to test Custom Logging logic
    **/
    @isTest
    static void testLogging(){
        APTS_CustomErrorLogging.assignTransactionId(null);
        APTS_CustomErrorLogging.createErrorLog('Error Name', 'Apex', 'Stack Trace String' ,'Product2', '03202340', 'CPQ', false, true, 'test@test.com', true,null,null,'Error Message');
        APTS_CustomErrorLogging.saveErrorLog();
        List<APTS_Error_Object__c> errorObjList = [SELECT Id FROM APTS_Error_Object__c LIMIT 50000];
        system.assertEquals(1, errorObjList.size());
    }

}