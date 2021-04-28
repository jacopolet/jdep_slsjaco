/**
* Class Name : APTS_CustomLogging_Test
* Description : Test Class to test APTS_CustomLogging Apex class
* Author : Abhishek Kolipey
* Date Created : 08-05-2018
**/
@isTest
private class APTS_CustomLogging_Test{

    /**Method Name : testLogging
    * Description : Method to test Custom Logging logic
    **/
    @isTest
    static void testLogging(){
        APTS_CustomLogging.createErrorLog('Error Name', 'Apex', 'Stack Trace String' ,'Product2', '03202340', 'CPQ', false, true, 'test@test.com', true);
        List<APTS_Error_Object__c> errorObjList = [SELECT Id FROM APTS_Error_Object__c LIMIT 50000];
        system.assertEquals(1, errorObjList.size());
    }

}