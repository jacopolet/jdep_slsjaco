/*************************************************************
@Name: APTS_OrderWSUtilsTest
@Author: Galin Georgiev
@CreateDate: 19-03-2018
@Description: Order Web Service Utils Test
@UsedBy: APTS_OrderWSUtilsTest
******************************************************************/
//v100 19-03-2018 Galin Georgiev: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes

@isTest
/* Test class to check the code coverage for class APTS_OrderWSUtils*/
private with sharing class APTS_OrderWSUtilsTest {
    /* Test Method to set the test data*/
    @testSetup static void setupTestData() {

        User oTestUser = APTS_TestFacade.createTestUser();
        APTS_TestFacade.createMandatoryRecords(oTestUser);        
        APTS_TestFacade.createAndConfigureOrder(oTestUser);
        System.assert(oTestUser != Null);
    }

    /* Test Method to run doATPCheck and prepareXMLRequest method*/
    @isTest static void test_doATPCheck() {

        User oTestUser = APTS_TestFacade.getTestUser();
        //Account oAccount = APTS_TestFacade.getAccount();
        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder();  
        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestFacade.getProductConfiguration();
        
        //System.assert(oTestUser != Null);           

        Test.startTest();

        System.runAs(oTestUser) {

        	Test.setMock(WebServiceMock.class, new APTS_ATPCheckHTTPCalloutMockImpl());
            
            APTS_OrderWSUtils.doATPCheck(oOrder.Id, oProductConfiguration.Id);

            APTS_OrderWSUtils.prepareXMLRequest(oOrder.Id, oProductConfiguration.Id);
            /*
            //APTS_OrderWSUtils.getFreightData(idToLineItemMap,null);

            APTS_SAPWSStructure.ORDER_CONDITION_EX_element responseTLI = new APTS_SAPWSStructure.ORDER_CONDITION_EX_element();
            Map<Integer, Apttus_Config2__LineItem__c> itemNumberToOrderLineItemMap = new Map<Integer, Apttus_Config2__LineItem__c>();
            //APTS_OrderWSUtils.setAsyncATPCheckResults(responseTLI,itemNumberToOrderLineItemMap);
           // APTS_OrderWSUtils.getFreightData(itemNumberToOrderLineItemMap,null);*/
        }


        Test.stopTest();
    }
}