/*************************************************************
@Name: APTS_PreviewOrderControllerTest
@Author: Galin Georgiev
@CreateDate: 19-02-2018
@Description: Preview Order Test
@UsedBy: APTS_PreviewOrderController
******************************************************************/
//v100 19-02-2018 Galin Georgiev: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes

@isTest
private with sharing class APTS_PreviewOrderControllerTest {

    private static final String ID = System.Label.APTS_Id;
    private static final String RETID = 'retId';
    private static final String FLOW = System.Label.APTS_Flow;
    private static final String NGSTANDARD_ORDER = System.Label.APTS_NGStandardOrder;
    private static final String NGMACHINE_ORDER = System.Label.APTS_NGMachineOrder;    

    @testSetup static void setupTestData() {

        User oTestUser = APTS_TestFacade.createTestUser();
        APTS_TestFacade.createMandatoryRecords(oTestUser);
        APTS_TestFacade.createAndConfigureOrder(oTestUser);    

    }

    @isTest static void test_PreviewOrderControllerStandard() {

        User oTestUser = APTS_TestFacade.getTestUser();
        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder();
        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestFacade.getProductConfiguration();
        Apttus_Config2__Order__c oOrder1 = APTS_TestFacade.getMachineOrder();
        List<Apttus_Config2__OrderLineItem__c> orderLineItemList = APTS_TestFacade.getOrderLineItemList(oOrder.Id);
        List<Apttus_Config2__LineItem__c> lineItemList = APTS_TestFacade.getLineItemList();
        
        test.startTest();
        try{
        System.runAs(oTestUser) {

            ApexPages.currentPage().getParameters().put(ID, oProductConfiguration.Id);
            ApexPages.currentPage().getParameters().put(RETID, oOrder.Id);
            ApexPages.currentPage().getParameters().put(FLOW, NGSTANDARD_ORDER);

            APTS_PreviewOrderController oPreviewOrderController = new APTS_PreviewOrderController();
            Test.setMock(WebServiceMock.class, new APTS_ATPCheckHTTPCalloutMockImpl());

            PageReference pageRef = oPreviewOrderController.previewOrder();
            oPreviewOrderController.doAsyncATPCheck(); 
            oPreviewOrderController.processResponse();
            
        }
         }
        catch (Exception e) {
    System.debug('Exception ' + e);
        }

        test.stopTest();
    }  

    @isTest static void test_PreviewOrderControllerMachine() {

        User oTestUser = APTS_TestFacade.getTestUser();
        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder();
        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestFacade.getProductConfiguration();
        Apttus_Config2__Order__c oOrder1 = APTS_TestFacade.getMachineOrder();
        List<Apttus_Config2__OrderLineItem__c> orderLineItemList = APTS_TestFacade.getOrderLineItemList(oOrder.Id);
        List<Apttus_Config2__LineItem__c> lineItemList = APTS_TestFacade.getLineItemList();

        test.startTest();
        try{
        System.runAs(oTestUser) {

            ApexPages.currentPage().getParameters().put(ID, oProductConfiguration.Id);
            ApexPages.currentPage().getParameters().put(RETID, oOrder.Id);
            ApexPages.currentPage().getParameters().put(FLOW, NGMACHINE_ORDER);
            
            APTS_PreviewOrderController oPreviewOrderController = new APTS_PreviewOrderController();
            Test.setMock(WebServiceMock.class, new APTS_ATPCheckHTTPCalloutMockImpl());
            APTS_SAPWSStructure.BAPI_SALESORDER_SIMULATE_Response_element oBAPI_SALESORDER_SIMULATE_Response_element = new APTS_SAPWSStructure.BAPI_SALESORDER_SIMULATE_Response_element();
            PageReference pageRef = oPreviewOrderController.previewOrder();
            oPreviewOrderController.processResponse();
            oPreviewOrderController.doAsyncATPCheck(); 
        }
            }
        catch (Exception e) {
    System.debug('Exception ' + e);
        }

        test.stopTest();
    }   
}