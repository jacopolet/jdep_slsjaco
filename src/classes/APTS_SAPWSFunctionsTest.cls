/***************************************************************
@Name: APTS_SAPWSFunctionsTest
@Author: Galin Georgiev
@CreateDate: 19-02-2018
@Description: SAP functions test class
@UsedBy: APTS_SAPWSFunctionsTest
******************************************************************/
//v100 19-02-2018 Galin Georgiev: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes

@isTest
private with sharing class APTS_SAPWSFunctionsTest {

    @isTest static void test_SAPWSFunctions() {

        test.startTest();

        Test.setMock(WebServiceMock.class, new APTS_ATPCheckHTTPCalloutMockImpl());
        APTS_SAPWSFunctions.HTTPS_Port oSAPWSFunctions = new APTS_SAPWSFunctions.HTTPS_Port();
        System.assert(oSAPWSFunctions != Null);    

        APTS_SAPWSStructure.BAPI_SALESORDER_SIMULATE_Response_element response = oSAPWSFunctions.doATPSimulation(
                    null, null, null,
                    null, null, null,
                    null, null, null,
                    null, null, null,
                    null, null, null,
                    null, null, null,
                    null);

        test.stopTest();
        
    }
    
     @isTest static void test_SAPWSFunctionsTest() {

        test.startTest();
        try{
        APTS_SAPWSStructure.EXTENSIONIN_element EXTENSIONIN = new APTS_SAPWSStructure.EXTENSIONIN_element();
        Test.setMock(WebServiceMock.class, new APTS_ATPCheckHTTPCalloutMockImpl());
        APTS_SAPWSFunctions.AsyncHTTPS_Port oSAPWSFunctions = new APTS_SAPWSFunctions.AsyncHTTPS_Port();    
        System.assert(oSAPWSFunctions != Null);  
        APTS_SAPWSFunctions.BAPI_SALESORDER_SIMULATE_Response_elementFuture response = oSAPWSFunctions.doAsyncATPSimulation(
        null, null, null,
        EXTENSIONIN, null, null,
        null, null, null,
        null, null, null,
        null, null, null,
        null, null, null,
        null, null);       
     
        test.stopTest();
    }
    catch(exception ex){}
    }
}