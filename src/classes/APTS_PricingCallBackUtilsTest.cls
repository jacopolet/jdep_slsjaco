/*************************************************************
@Name: APTS_PricingCallBackUtilsTest
@Author: Galin Georgiev
@CreateDate: 20-03-2018
@Description: PricingCallBack Test
@UsedBy: APTS_PricingCallBackUtils
******************************************************************/
//v100 20-03-2018 Galin Georgiev: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes

@isTest
private with sharing class APTS_PricingCallBackUtilsTest {

    private static final String NGSTANDARD_ORDER = System.Label.APTS_NGStandardOrder;
    private static final String NGMACHINE_ORDER = System.Label.APTS_NGMachineOrder;

    @testSetup static void setupTestData() {

        User oTestUser = APTS_TestFacade.createTestUser();
        APTS_TestFacade.createMandatoryRecords(oTestUser);
        APTS_TestFacade.createAndConfigureOrder(oTestUser);
    }

    @isTest static void test_PricingCallBackUtil() {

        User oTestUser = APTS_TestFacade.getTestUser();
        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder();
        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestFacade.getProductConfiguration();
        List<Apttus_Config2__LineItem__c> lineItemList = APTS_TestFacade.getLineItemList(oProductConfiguration.Id);
        Apttus_Config2__LineItem__c oLineItem = lineItemList.get(0);
        Id locationId = oOrder.Apttus_Config2__LocationId__c;
        System.assertEquals(locationId,oOrder.Apttus_Config2__LocationId__c);

        Test.startTest();

        System.runAs(oTestUser) {

            String sFlow = NGSTANDARD_ORDER;

            Date dtBiggestRequestedDelivaryDate = APTS_PricingCallBackUtils.getBiggestRequestedDeliveryDate(oProductConfiguration.Id, Date.today());

            APTS_PricingCallBackUtils.setRequestedDeliveryDate(oLineItem, sFlow, dtBiggestRequestedDelivaryDate);
            APTS_PricingCallBackUtils.setRequestedInstallationDate(oLineItem, sFlow, dtBiggestRequestedDelivaryDate);
            APTS_PricingCallBackUtils.setLocation(oLineItem, sFlow, locationId);
        }

        Test.stopTest();
    }
}