/*************************************************************
@Name: APTS_DeInstallOrderControllerTest
@Author: Galin Georgiev
@CreateDate: 29-05-2018
@Description:
@UsedBy: APTS_DeInstallOrderController
******************************************************************/
//v100 19-02-2018 Galin Georgiev: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes

@isTest
private with sharing class APTS_DeInstallOrderControllerTest {

    private static final String PAGE_PARAM_ID = System.Label.APTS_Id;
    private static final String PAGE_MSG_SELECT_MIN_ONE_MACHINE = 'Please select at least one Machine';
    private static final String FIRSTPARAM = System.Label.APTS_firstParam;

    @testSetup static void setupTestData() {

        User oTestUser = APTS_TestFacade.createTestUser();
        APTS_TestFacade.createMandatoryRecords(oTestUser);
        APTS_TestFacade.createAndConfigureAgreement(oTestUser);
        APTS_TestFacade.createAndConfigureOrder(oTestUser);
        System.assert(oTestUser != Null);
    }

    @isTest static void test_DeInstallOrderController() {

        User oTestUser = APTS_TestFacade.getTestUser();
        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getMachineOrder();
        List<Apttus_Config2__OrderLineItem__c> orderLineItemList = APTS_TestFacade.getOrderLineItemList(oOrder.Id);
        Apttus__APTS_Agreement__c oAgreement = APTS_TestFacade.getAgreement('Cancelled Agreement');
        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestFacade.getMachineProductConfiguration();
        List<Apttus__AgreementLineItem__c> agreementLineItemList = APTS_TestFacade.getAgreementLineItem(oAgreement.Id);
        List<Apttus_Config2__AssetLineItem__c> assetLineItemList = APTS_TestFacade.getAssetLineItem();

        for (Apttus__AgreementLineItem__c oAgreementLineItem : agreementLineItemList) {
            oAgreementLineItem.Apttus_CMConfig__AssetLineItemId__c = assetLineItemList.get(0).Id;
        }
        Database.update(agreementLineItemList);

        oOrder.Apttus_CMConfig__AgreementId__c = oAgreement.Id;
        Database.update(oOrder);

        Test.startTest();

        System.runAs(oTestUser) {

            ApexPages.currentPage().getParameters().put(PAGE_PARAM_ID, oOrder.Id);

            APTS_DeInstallOrderController oDeInstallOrderController = new APTS_DeInstallOrderController();

            oDeInstallOrderController.agreementLineItemWrapperList[0].selected = true;
            oDeInstallOrderController.deInstallDate = Date.today().addDays(7).toStartOfWeek();

            oDeInstallOrderController.loadMore();
            oDeInstallOrderController.loadLess();

            oDeInstallOrderController.deInstallOrder();
            oDeInstallOrderController.createCart();
            oDeInstallOrderController.cancelAssets();
            oDeInstallOrderController.saveCart();
            oDeInstallOrderController.goToPricing();
            System.assertEquals(true,oDeInstallOrderController.agreementLineItemWrapperList[0].selected);
        }

        Test.stopTest();
    }

    @isTest static void test_ComercialSwap() {

        User oTestUser = APTS_TestFacade.getTestUser();
        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getMachineOrder();
        List<Apttus_Config2__OrderLineItem__c> orderLineItemList = APTS_TestFacade.getOrderLineItemList(oOrder.Id);
        Apttus__APTS_Agreement__c oAgreement = APTS_TestFacade.getAgreement('Cancelled Agreement');
        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestFacade.getMachineProductConfiguration();
        List<Apttus__AgreementLineItem__c> agreementLineItemList = APTS_TestFacade.getAgreementLineItem(oAgreement.Id);
        List<Apttus_Config2__AssetLineItem__c> assetLineItemList = APTS_TestFacade.getAssetLineItem();

        for (Apttus__AgreementLineItem__c oAgreementLineItem : agreementLineItemList) {
            oAgreementLineItem.Apttus_CMConfig__AssetLineItemId__c = assetLineItemList.get(0).Id;
        }
        Database.update(agreementLineItemList);

        oOrder.Apttus_CMConfig__AgreementId__c = oAgreement.Id;
        oOrder.APTS_Order_Sub_Type__c = 'Commercial Swap';
        Database.update(oOrder);

        Test.startTest();

        System.runAs(oTestUser) {

            ApexPages.currentPage().getParameters().put(PAGE_PARAM_ID, oOrder.Id);

            APTS_DeInstallOrderController oDeInstallOrderController = new APTS_DeInstallOrderController();

            oDeInstallOrderController.agreementLineItemWrapperList[0].selected = true;
            oDeInstallOrderController.deInstallDate = Date.today().addDays(7).toStartOfWeek();

            oDeInstallOrderController.loadMore();
            oDeInstallOrderController.loadLess();

            oDeInstallOrderController.deInstallOrder();
            oDeInstallOrderController.createCart();
            oDeInstallOrderController.cancelAssets();
            oDeInstallOrderController.saveCart();
            oDeInstallOrderController.goToPricing();
            System.assertEquals('Commercial Swap',oOrder.APTS_Order_Sub_Type__c);
        }

        Test.stopTest();
    }

    @isTest static void test_doSearch() {

        User oTestUser = APTS_TestFacade.getTestUser();
        Account oAccount = APTS_TestFacade.getAccount();
        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getMachineOrder();
        System.assert(oAccount != Null);

        test.startTest();

        System.runAs(oTestUser) {

            ApexPages.currentPage().getParameters().put(PAGE_PARAM_ID, oOrder.Id);

            APTS_DeInstallOrderController oDeInstallOrderController = new APTS_DeInstallOrderController();

            ApexPages.currentPage().getParameters().put(FIRSTPARAM, '12');
            oDeInstallOrderController.searchSerialNumbers();

            oDeInstallOrderController.doAssetSearch();

            oDeInstallOrderController.resetAssetSearch();
            oDeInstallOrderController.doAssetSearch();

            APTS_DeInstallOrderController.APTS_AgreementLineItemWrapper oALIW = new APTS_DeInstallOrderController.APTS_AgreementLineItemWrapper();

            oDeInstallOrderController.backToAgreement();
           
        }

        test.stopTest();
    }
}