@isTest
private with sharing class APTS_AmendCancelOrderControllerTest {

    public static boolean isOrderUpdatedRequired = true;

    @testSetup static void setupTestData() {
        User oTestUser = APTS_TestFacade.createTestUser();
        APTS_TestFacade.createMandatoryRecords(oTestUser);
        APTS_TestFacade.createAndConfigureAgreement(oTestUser);
        APTS_TestFacade.createAndConfigureOrder(oTestUser);

    }

    @isTest static void test_AmendOrder() {
        User oTestUser = APTS_TestFacade.getTestUser();
        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder();
        oOrder.Apttus_Config2__Status__c = 'Pending';
        oOrder.APTS_Order_Header_SAP_ID__c = '3232132';
        update oOrder;

        test.startTest();

        //System.runAs(oTestUser) {
        ApexPages.currentPage().getParameters().put('Id', oOrder.Id);
        ApexPages.currentPage().getParameters().put('action', 'Amend');
        ApexPages.currentPage().getParameters().put('flow', 'NGStandard');

        APTS_AmendCancelOrderController oController = new APTS_AmendCancelOrderController();

        PageReference pageRef = oController.submitOrder();
        pageRef = oController.redirectAmendCancelOrder();
        oController.isDeInstallationDateVisible = true;
        oController.dtDeinstallDate = System.today();
        oOrder.APTS_Requested_Installation_Date__c = System.today().addMonths(1).toStartOfWeek().addDays(7);
        pageRef = oController.submitOrder();
        //}

        test.stopTest();
    }


    @isTest static void test_CancelOrder() {
        User oTestUser = APTS_TestFacade.getTestUser();
        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder();
        oOrder.APTS_Order_Type__c = 'Machine Order';
        oOrder.APTS_Order_Sub_Type__c = 'Installation';
        oOrder.Apttus_Config2__Status__c = 'Pending';
        update oOrder;

        test.startTest();

        //System.runAs(oTestUser) {
        ApexPages.currentPage().getParameters().put('Id', oOrder.Id);
        ApexPages.currentPage().getParameters().put('action', 'Cancel');
        ApexPages.currentPage().getParameters().put('flow', 'NGStandard');

        APTS_AmendCancelOrderController oController = new APTS_AmendCancelOrderController();
        PageReference pageRef = oController.submitOrder();
        //}

        test.stopTest();
    }

    @isTest static void test_CancelOrder2() {
        User oTestUser = APTS_TestFacade.getTestUser();
        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder();
        test.startTest();

        //System.runAs(oTestUser) {
        ApexPages.currentPage().getParameters().put('Id', oOrder.Id);
        ApexPages.currentPage().getParameters().put('action', 'Cancel');
        ApexPages.currentPage().getParameters().put('flow', 'NGStandard');

        APTS_AmendCancelOrderController oController = new APTS_AmendCancelOrderController();
        PageReference pageRef = oController.submitOrder();
        //}

        test.stopTest();
    }

    @isTest static void test_CancelOrder3() {
        User oTestUser = APTS_TestFacade.getTestUser();
        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder();
        oOrder.Apttus_Config2__Status__c = APTS_OrderConstants.DRAFT;
        oOrder.APTS_Status__c = APTS_OrderConstants.DRAFT;
        database.update(oOrder, false);
        test.startTest();

        //System.runAs(oTestUser) {
        ApexPages.currentPage().getParameters().put('Id', oOrder.Id);
        ApexPages.currentPage().getParameters().put('action', 'Cancel');
        ApexPages.currentPage().getParameters().put('flow', 'NGStandard');

        APTS_AmendCancelOrderController oController = new APTS_AmendCancelOrderController();
        PageReference pageRef = oController.submitOrder();
        pageRef = oController.redirectAmendCancelOrder();
        //}

        test.stopTest();
    }

    @isTest static void test_AmendOrderDate() {
        User oTestUser = APTS_TestFacade.getTestUser();
        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder();
        oOrder.APTS_Order_Type__c = 'Machine Order';
        oOrder.APTS_Order_Sub_Type__c = 'Installation';
        oOrder.Apttus_Config2__Status__c = 'Pending';
        oOrder.APTS_Order_Header_SAP_ID__c = '3232132';
        update oOrder;

        test.startTest();

        //System.runAs(oTestUser) {
        ApexPages.currentPage().getParameters().put('Id', oOrder.Id);
        ApexPages.currentPage().getParameters().put('action', 'Amend');
        ApexPages.currentPage().getParameters().put('flow', 'NGStandard');
        ApexPages.currentPage().getParameters().put('isAmendDate', 'true');

        APTS_AmendCancelOrderController oController = new APTS_AmendCancelOrderController();
        oController.isDeInstallationDateVisible = true;
        oController.oOrder.APTS_Requested_De_Installation_Date__c = System.today().addMonths(1).toStartOfWeek().addDays(7);

        oController.isInstallationDateVisible = true;
        oController.oOrder.APTS_Requested_Installation_Date__c = System.today().addMonths(1).toStartOfWeek().addDays(7);
        oController.calcReqDeliveryDate();

        PageReference pageRef = oController.submitOrder();


        //}

        test.stopTest();
    }

    @isTest static void test_SubmitOrder() {
        User oTestUser = APTS_TestFacade.getTestUser();

        //Date dtDeinstallDate = System.today().addMonths(1).toStartOfWeek().addDays(1);
        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder();
        oOrder.Apttus_Config2__Description__c = 'Machine Order';
        oOrder.APTS_Order_Type__c = 'Machine Order';
        oOrder.APTS_Order_Sub_Type__c = 'Standard Order';
        oOrder.Apttus_Config2__Status__c = 'Pending';
        oOrder.APTS_Requested_Delivery_Date__c = System.today().addDays(7);
        oOrder.APTS_Order_Header_SAP_ID__c = '3232132';
        oOrder.APTS_Requested_De_Installation_Date__c = System.today().addMonths(1).toStartOfWeek().addDays(7);
        oOrder.APTS_Requested_Installation_Date__c = System.today().addMonths(1).toStartOfWeek().addDays(7);
        update oOrder;

        test.startTest();

        //System.runAs(oTestUser) {
        ApexPages.currentPage().getParameters().put('Id', oOrder.Id);
        ApexPages.currentPage().getParameters().put('action', 'Amend');
        ApexPages.currentPage().getParameters().put('flow', 'NGStandard');
        ApexPages.currentPage().getParameters().put('isAmendDate', 'true');
        //ApexPages.currentPage().getParameters().put(isDeInstallationDateVisible, true);
        //ApexPages.currentPage().getParameters().put(dtDeinstallDate, System.today().addMonths(1).toStartOfWeek().addDays(1));


        APTS_AmendCancelOrderController oController = new APTS_AmendCancelOrderController();
        //oController.isDeInstallationDateVisible = true;
        //oController.submitOrder.isOrderUpdatedRequired= true;
        //oController.oOrder.APTS_Requested_De_Installation_Date__c = System.today().addMonths(1).toStartOfWeek().addDays(7);
        //oController.dtDeinstallDate  = System.today().addMonths(1).toStartOfWeek().addDays(7);

        oController.isInstallationDateVisible = true;
        oController.oOrder.APTS_Requested_Installation_Date__c = System.today().addMonths(1).toStartOfWeek().addDays(7);
        oController.calcReqDeliveryDate();
        oController.submitOrder();

        //oOrder.APTS_Requested_Installation_Date__c = null;
        //update oOrder;
        //oController.calcReqDeliveryDate();
        //PageReference pageRef = oController.submitOrder();


        //}

        test.stopTest();
    }

    @isTest static void testBack() {
        User oTestUser = APTS_TestFacade.getTestUser();

        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder();
        oOrder.Apttus_Config2__Description__c = 'Machine Order';
        oOrder.APTS_Order_Type__c = 'Machine Order';
        oOrder.APTS_Order_Sub_Type__c = 'Standard Order';
        oOrder.Apttus_Config2__Status__c = 'Pending';
        oOrder.APTS_Requested_Delivery_Date__c = System.today().addDays(7);
        oOrder.APTS_Order_Header_SAP_ID__c = '3232132';
        oOrder.APTS_Requested_De_Installation_Date__c = System.today().addMonths(1).toStartOfWeek().addDays(7);
        oOrder.APTS_Requested_Installation_Date__c = System.today().addMonths(1).toStartOfWeek().addDays(7);
        update oOrder;

        Case cse = new Case();
        cse.Subject = 'caseSubj';
        cse.Status = 'New';
        cse.ApptusOrder__c  = oOrder.Id;
        insert cse;

        test.startTest();

        //System.runAs(oTestUser) {
        ApexPages.currentPage().getParameters().put('Id', oOrder.Id);
        ApexPages.currentPage().getParameters().put('action', 'Cancel');
        ApexPages.currentPage().getParameters().put('flow', 'NGMachine');

        APTS_AmendCancelOrderController oController = new APTS_AmendCancelOrderController();
        oController.back();

        //}

        test.stopTest();
    }

}