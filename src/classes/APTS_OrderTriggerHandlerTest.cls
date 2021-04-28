/*************************************************************
@Name: APTS_OrderTriggerHandlerTest
@Author: Galin Georgiev
@CreateDate: 19-02-2018
@Description: Order Trigger Handler Test
@UsedBy: APTS_OrderTriggerHandler
******************************************************************/
//v100 19-02-2018 Galin Georgiev: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes

@isTest
private with sharing class APTS_OrderTriggerHandlerTest {

    private static final String STANDARD_ORDER = System.Label.APTS_Standard_Order;
    private static final String SUBMITTED = System.Label.APTS_Submitted;
    private static final String INSTALLATION = System.Label.APTS_Installation;
    private static final String DE_INSTALLATION = System.Label.APTS_De_installation;
    private static final String MACHINE_ORDER = System.Label.APTS_Machine_Order;
    private static final String PASS = System.Label.APTS_Pass;
    private static final String PENDING = System.Label.APTS_Pending;
    private static final String Z6 = System.Label.APTS_Z6;
    private static final String ACTIVATED = System.Label.APTS_Activated;
    private static final String ADMINORDER = 'Admin Order';
    private static final String STANDARD_RETURN = 'Standard Return';
    private static final String TECHNICAL_SWAP = System.Label.APTS_Technical_Swap;
    private static final String INTERNAL_MOVEMENT = System.Label.APTS_Internal_Movement;

    @testSetup static void setupTestData() {

        User oTestUser = APTS_TestFacade.createTestUser();
        APTS_TestFacade.createMandatoryRecords(oTestUser);
        APTS_TestFacade.createAndConfigureAgreement(oTestUser);
        APTS_TestFacade.createAndConfigureOrder(oTestUser);
        APTS_OrderUtils.stopOrderLineItemTrigger();                
        APTS_TestFacade.createMachineAmendOrder(oTestUser);
        APTS_OrderUtils.startOrderLineItemTrigger();

        Apttus__APTS_Agreement__c oAgreement = APTS_TestFacade.getAgreement('Agreement');
        oAgreement.APTS_Fixed_Term_Type__c = 'Fixed Cost';
        Database.update(oAgreement);
        System.assertEquals('Fixed Cost',oAgreement.APTS_Fixed_Term_Type__c);
        System.assert(oTestUser != Null);
        
        
    }

    @isTest static void test_BeforeInsert() {

        User oTestUser = APTS_TestFacade.getTestUser();
        Account oAccount = APTS_TestFacade.getAccount();

        Test.startTest();

       // System.runAs(oTestUser) {

            APTS_OrderTriggerHandler oOrderTriggerHandler = new APTS_OrderTriggerHandler();
            APTS_OrderTriggerHandler.isDisabled();

            Apttus_Config2__Order__c oOrderDO = new Apttus_Config2__Order__c();
            oOrderDO.APTS_Order_Type__c = 'Digital Order';
            System.assertEquals('Digital Order',oOrderDO.APTS_Order_Type__c);
            Database.insert(oOrderDO);

            Apttus_Config2__Order__c oOrderRS = new Apttus_Config2__Order__c();
            oOrderRS.APTS_Order_Type__c = 'Route Sales Order';
            System.assertEquals('Route Sales Order',oOrderRS.APTS_Order_Type__c);
            Database.insert(oOrderRS);

            Apttus_Config2__Order__c oOrderOO = new Apttus_Config2__Order__c();
            oOrderOO.APTS_Order_Type__c = 'Operating Order';
            Database.insert(oOrderOO);

            Apttus__APTS_Agreement__c oAgreement = APTS_TestFacade.getAgreement('Agreement');
            oAgreement.APTS_Check_on_Account_Machines__c = false;
            oAgreement.APTS_Check_on_Account_Ingredients__c = false;
            Database.update(oAgreement);

            Apttus_Config2__Order__c oMachineOrderAgr = new Apttus_Config2__Order__c();
            oMachineOrderAgr.APTS_Order_Type__c = MACHINE_ORDER;
            oMachineOrderAgr.Apttus_CMConfig__AgreementId__c = oAgreement.Id;
            Database.insert(oMachineOrderAgr);

            Apttus_Config2__Order__c oStandardOrderAgr = new Apttus_Config2__Order__c();
            oStandardOrderAgr.APTS_Order_Type__c = STANDARD_ORDER;
            oStandardOrderAgr.Apttus_CMConfig__AgreementId__c = oAgreement.Id;
            Database.insert(oStandardOrderAgr);

            Apttus_Config2__Order__c oAdminOrderAgr = new Apttus_Config2__Order__c();
            oAdminOrderAgr.APTS_Order_Type__c = ADMINORDER;
            oAdminOrderAgr.Apttus_CMConfig__AgreementId__c = oAgreement.Id;
            Database.insert(oAdminOrderAgr);

            Apttus_Config2__Order__c oStandardReturnOrder = new Apttus_Config2__Order__c();
            oStandardReturnOrder.APTS_Order_Type__c = STANDARD_ORDER;
            oStandardReturnOrder.APTS_Order_Sub_Type__c = STANDARD_RETURN;
            oMachineOrderAgr.Apttus_CMConfig__AgreementId__c = oAgreement.Id;
            Database.insert(oStandardReturnOrder);

            oAgreement.APTS_Check_on_Account_Machines__c = true;
            oAgreement.APTS_Check_on_Account_Ingredients__c = true;
            Database.update(oAgreement);

            Apttus_Config2__Order__c oMachineOrderAgr1 = new Apttus_Config2__Order__c();
            oMachineOrderAgr1.APTS_Order_Type__c = MACHINE_ORDER;
            oMachineOrderAgr1.Apttus_CMConfig__AgreementId__c = oAgreement.Id;
            oMachineOrderAgr1.Apttus_Config2__SoldToAccountId__c = oAccount.Id;
            Database.insert(oMachineOrderAgr1);

            Apttus_Config2__Order__c oStandardReturnOrder1 = new Apttus_Config2__Order__c();
            oStandardReturnOrder1.APTS_Order_Type__c = STANDARD_ORDER;
            oStandardReturnOrder1.APTS_Order_Sub_Type__c = STANDARD_RETURN;
            oStandardReturnOrder1.Apttus_CMConfig__AgreementId__c = oAgreement.Id;
            oStandardReturnOrder1.Apttus_Config2__SoldToAccountId__c = oAccount.Id;
            Database.insert(oStandardReturnOrder1);
            
            
            
       // }

        Test.stopTest();
    }

    @isTest static void test_OrderTriggerHandler() {

        User oTestUser = APTS_TestFacade.getTestUser();

        

        Test.startTest();

        //System.runAs(oTestUser) {

            Apttus__APTS_Agreement__c oAgreement = APTS_TestFacade.getAgreement('Agreement');
    
            Apttus_Config2__Order__c oOrder = APTS_TestFacade.getMachineOrder();
            oOrder.Apttus_Config2__Status__c = 'Draft';
            oOrder.Apttus_CMConfig__AgreementId__c = oAgreement.Id;
            System.assert(oAgreement.Id != Null);
            Database.update(oOrder);

            APTS_OrderUtils.submitOrder(oOrder.Id);
            Database.update(oOrder);

            oOrder.APTS_Order_Header_SAP_ID__c = '123';
            Database.update(oOrder);

            oOrder.APTS_Requested_Installation_Date__c = Date.newInstance(2018, 07, 23);
            Database.update(oOrder);

            oOrder.APTS_Requested_Delivery_Date__c = Date.today() + 1;
            Database.update(oOrder);

            oOrder.APTS_Delivery_Date_Authorized__c = Date.today() + 7;
            oOrder.APTS_Pick_Up_Date_Authorized__c = Date.today() + 8;
            oOrder.APTS_Movement_Date_Authorized__c = Date.today() + 9;
            Database.update(oOrder);

            oOrder.Apttus_Config2__Status__c = ACTIVATED;
            Database.update(oOrder);


        Test.stopTest();
    }

        @isTest static void test_OrderTriggerHandler1() {

        User oTestUser = APTS_TestFacade.getTestUser();

        

        Test.startTest();

        //System.runAs(oTestUser) {
            Apttus__APTS_Agreement__c oAgreement = APTS_TestFacade.getAgreement('Agreement');
            Account oAccount = APTS_TestFacade.getAccount();
            
            Apttus_Config2__Order__c odebitOrder1= new Apttus_Config2__Order__c();
            odebitOrder1.APTS_Order_Type__c = 'Debit Memo';
            odebitOrder1.Apttus_CMConfig__AgreementId__c = oAgreement.Id;
            odebitOrder1.Apttus_Config2__SoldToAccountId__c = oAccount.Id;
            Database.insert(odebitOrder1);
            
            Apttus_Config2__Order__c ocreditOrder1= new Apttus_Config2__Order__c();
            ocreditOrder1.APTS_Order_Type__c = 'Credit Memo';
            ocreditOrder1.Apttus_CMConfig__AgreementId__c = oAgreement.Id;
            ocreditOrder1.Apttus_Config2__SoldToAccountId__c = oAccount.Id;
            Database.insert(ocreditOrder1);
            
            Apttus_Config2__Order__c oSimpleOrder = APTS_TestFacade.getOrder('MachineAmendOrder');
            oSimpleOrder.APTS_Order_Type__c = MACHINE_ORDER;
            oSimpleOrder.APTS_Order_Sub_Type__c = INSTALLATION;
            oSimpleOrder.APTS_Requested_Installation_Date__c = Date.newInstance(2018, 07, 23);
            oSimpleOrder.APTS_ATP_Check_Status__c = PASS;
            oSimpleOrder.APTS_Work_Order_Created__c = false;
            Database.update(oSimpleOrder);

            oSimpleOrder.APTS_Order_Sub_Type__c = DE_INSTALLATION;
            oSimpleOrder.APTS_ATP_Check_Status__c = PASS;
            oSimpleOrder.APTS_Work_Order_Created__c = false;
            oSimpleOrder.APTS_Requested_De_Installation_Date__c = Date.newInstance(2018, 07, 23);
            Database.update(oSimpleOrder);

            oSimpleOrder.APTS_Order_Sub_Type__c = 'Conversion';
            oSimpleOrder.APTS_ATP_Check_Status__c = PASS;
            oSimpleOrder.APTS_Work_Order_Created__c = false;
            Database.update(oSimpleOrder);

            oSimpleOrder.APTS_Order_Sub_Type__c = INTERNAL_MOVEMENT;
            oSimpleOrder.APTS_ATP_Check_Status__c = PASS;
            oSimpleOrder.APTS_Work_Order_Created__c = false;
            Database.update(oSimpleOrder);

            oSimpleOrder.APTS_Order_Sub_Type__c = TECHNICAL_SWAP;
            oSimpleOrder.APTS_ATP_Check_Status__c = PASS;
            oSimpleOrder.APTS_Work_Order_Created__c = false;
            Database.update(oSimpleOrder);
            
            Apttus_Config2__Order__c debit = [Select Id,APTS_Credit_Debit_For__c,Apttus_Config2__Source__c From Apttus_Config2__Order__c Where APTS_Order_Type__c ='Debit Memo'];
            debit.Apttus_Config2__Source__c='Account';
            debit.APTS_Credit_Debit_For__c = 'Ingredients (Standard Deal)';
            debit.APTS_SAP_OrderType__c='XD01';
            update debit;
            
            Apttus_Config2__Order__c credit= [Select Id,APTS_Credit_Debit_For__c,Apttus_Config2__Source__c From Apttus_Config2__Order__c Where APTS_Order_Type__c ='Credit Memo'];
            credit.Apttus_Config2__Source__c='Account';
            credit.APTS_Credit_Debit_For__c = 'Ingredients (Standard Deal)';
            credit.APTS_SAP_OrderType__c ='XC01';
            update credit;
       // }

        Test.stopTest();
    }

    @isTest static void test_Delete() {

        User oTestUser = APTS_TestFacade.getTestUser();
        System.assert(oTestUser != Null);
        Test.startTest();

        //System.runAs(oTestUser) {

            APTS_OrderTriggerHandler oOrderTriggerHandler = new APTS_OrderTriggerHandler();
            oOrderTriggerHandler.beforeDelete(null, null);
            oOrderTriggerHandler.afterDelete(null, null);
            oOrderTriggerHandler.afterUndelete(null, null);
        //}

        Test.stopTest();
    }
    
    @isTest static void test_OrderTriggerHandler_Digital() {

        User oTestUser = APTS_TestFacade.getTestUser();

        Test.startTest();

        //System.runAs(oTestUser) {

            Apttus__APTS_Agreement__c oAgreement = APTS_TestFacade.getAgreement('Agreement');
            
            Apttus_Config2__Order__c oOrder = new Apttus_Config2__Order__c();
            oOrder.APTS_Order_Type__c = 'Standard Order';
            oOrder.APTS_Order_Sub_Type__c = 'Digital Order';
            System.assertEquals('Digital Order',oOrder.APTS_Order_Sub_Type__c);
            Database.insert(oOrder);

            oOrder.Apttus_Config2__Status__c = 'Draft';
            oOrder.Apttus_CMConfig__AgreementId__c = oAgreement.Id;
            System.assert(oAgreement.Id != Null);
            Database.update(oOrder);

            APTS_OrderUtils.submitOrder(oOrder.Id);
            Database.update(oOrder);

            oOrder.APTS_Order_Header_SAP_ID__c = '123';
            Database.update(oOrder);

            oOrder.APTS_Requested_Delivery_Date__c = Date.today() + 1;
            Database.update(oOrder);

            oOrder.APTS_Delivery_Date_Authorized__c = Date.today() + 7;
            Database.update(oOrder);

            oOrder.Apttus_Config2__Status__c = ACTIVATED;
            Database.update(oOrder);

       // }

        Test.stopTest();
    }
    
    @isTest static void test_OrderTriggerHandler_rso() {

        User oTestUser = APTS_TestFacade.getTestUser();

        Test.startTest();

        //System.runAs(oTestUser) {

            Apttus__APTS_Agreement__c oAgreement = APTS_TestFacade.getAgreement('Agreement');
            
            Apttus_Config2__Order__c oOrder = new Apttus_Config2__Order__c();
            oOrder.APTS_Order_Type__c = 'Route Sales Order';
            System.assertEquals('Route Sales Order',oOrder.APTS_Order_Type__c);
            Database.insert(oOrder);

            oOrder.Apttus_Config2__Status__c = 'Draft';
            oOrder.Apttus_CMConfig__AgreementId__c = oAgreement.Id;
            System.assert(oAgreement.Id != Null);
            Database.update(oOrder);

            APTS_OrderUtils.submitOrder(oOrder.Id);
            Database.update(oOrder);

            oOrder.APTS_Order_Header_SAP_ID__c = '123';
            Database.update(oOrder);

            oOrder.APTS_Requested_Installation_Date__c = Date.newInstance(2018, 07, 23);
            Database.update(oOrder);

            oOrder.APTS_Requested_Delivery_Date__c = Date.today() + 1;
            Database.update(oOrder);

            oOrder.APTS_Delivery_Date_Authorized__c = Date.today() + 7;
            oOrder.APTS_Pick_Up_Date_Authorized__c = Date.today() + 8;
            oOrder.APTS_Movement_Date_Authorized__c = Date.today() + 9;
            Database.update(oOrder);

            oOrder.Apttus_Config2__Status__c = ACTIVATED;
            Database.update(oOrder);

       // }

        Test.stopTest();
    }

}