/*************************************************************
@Name: APTS_ConfigurationTriggerHandlerTest
@Author: Galin Georgiev
@CreateDate: 19-02-2018
@Description: Configuration Trigger Handler Test
@UsedBy: APTS_ConfigurationTriggerHandler
******************************************************************/
//v100 19-02-2018 Galin Georgiev: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes

@isTest
private with sharing class APTS_ConfigurationTriggerHandlerTest {

    private static final String STANDARD_ORDER = System.Label.APTS_Standard_Order;
    private static final String MACHINE_ORDER = System.Label.APTS_Machine_Order;

    @testSetup static void setupTestData() {

        User oTestUser = APTS_TestFacade.createTestUser();
        APTS_TestFacade.createMandatoryRecords(oTestUser);
        System.assert(oTestUser != Null);
    }

    @isTest static void test_ConfigurationTriggerHandler() {

        User oTestUser = APTS_TestFacade.getTestUser();

        //TriggerSettings__c oTriggerSettings = new TriggerSettings__c(APTS_Configuration_Trigger__c = true);
        //Database.insert(oTriggerSettings);

        TriggerSettings__c oTriggerSettings = [SELECT APTS_Order_Trigger__c, APTS_OrderLineItemTrigger__c, APTS_Configuration_Trigger__c, AssetLineItemTrigger__c, PhysicalAssetTrigger__c FROM TriggerSettings__c];
        oTriggerSettings.APTS_Configuration_Trigger__c = true;
        Database.update(oTriggerSettings);
        System.assert(oTriggerSettings != Null);
        
        Test.startTest();
        
        System.assert(oTestUser != Null);
        System.runAs(oTestUser) {

            APTS_ConfigurationTriggerHandler oConfigurationTriggerHandler = new APTS_ConfigurationTriggerHandler();
            oConfigurationTriggerHandler.isDisabled();

            APTS_TestFacade.createAndConfigureOrder(oTestUser);
            Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder();
            oOrder.APTS_Order_Type__c = STANDARD_ORDER;
            oOrder.APTS_Requested_Delivery_Date__c = Date.today();
            Database.update(oOrder);
            System.assert(oOrder != Null);

            Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestFacade.getProductConfiguration();

            List<Apttus_Config2__LineItem__c> lineItemList = APTS_TestFacade.getLineItemList();
            lineItemList[0].APTS_Requested_Delivery_Date__c = Date.today().addDays(10);
            Database.update(lineItemList);
            Database.update(oProductConfiguration);
            /*
                        oTriggerSettings.APTS_Order_Trigger__c = false;
                        Database.update(oTriggerSettings);
                        lineItemList[0].APTS_Requested_Delivery_Date__c = Date.today().addDays(15);
                        Database.update(lineItemList);
                        Database.update(oProductConfiguration);
            */
            Database.delete(oProductConfiguration);

            oOrder.APTS_Order_Type__c = MACHINE_ORDER;
            Database.update(oOrder);
            Apttus_Config2__ProductConfiguration__c oProductConfiguration1 = APTS_TestDataFactory.createProductConfig(oOrder);
            Database.insert(oProductConfiguration1);
        }

        Test.stopTest();
    }

    @isTest static void test_Delete() {

        User oTestUser = APTS_TestFacade.getTestUser();

        Test.startTest();
        System.assert(oTestUser != Null);
        System.runAs(oTestUser) {

            APTS_ConfigurationTriggerHandler oConfigurationTriggerHandler = new APTS_ConfigurationTriggerHandler();
            //oConfigurationTriggerHandler.afterDelete(null,null);
            oConfigurationTriggerHandler.afterUndelete(null, null);
        }

        Test.stopTest();
    }
}