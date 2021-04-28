/*************************************************************
@Name: APTS_CreateMachineOrderControllerTest
@Author: Galin Georgiev
@CreateDate: 19-02-2018
@Description: Create Order from Account Test
@UsedBy: APTS_CreateMachineOrderController
******************************************************************/
//v100 19-02-2018 Galin Georgiev: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes

/* Create Order from Account Test */
@isTest
private with sharing class APTS_CreateMachineOrderControllerTest {

    /* Data Setup for Create Machine Order */
    @testSetup static void setupTestData() {

        User oTestUser = APTS_TestFacade.createTestUser();
        APTS_TestFacade.createMandatoryRecords(oTestUser);
        APTS_TestFacade.createAndConfigureAgreement(oTestUser);
        APTS_TestFacade.createAndConfigureOrder(oTestUser);
        System.assert(oTestUser != Null);
    }

     /* Install Machine Order */
    @isTest static void test_InstallOrder() {

        User oTestUser = APTS_TestFacade.getTestUser();
        Account oAccount = APTS_TestFacade.getAccount();

        test.startTest();

        System.runAs(oTestUser) {

            ApexPages.currentPage().getParameters().put(APTS_OrderConstants.ID, oAccount.Id);

            APTS_CreateMachineOrderController oCreateMachineOrderController = new APTS_CreateMachineOrderController();
            oCreateMachineOrderController.doSOQLS();
            oCreateMachineOrderController.getOrderSubTypePicklist();            
            oCreateMachineOrderController.createOrder();
            oCreateMachineOrderController.back();
        }

        test.stopTest();
        
        System.assert(oAccount.Id != Null, 'AccoundId is require in order to  Place Machine Order');
    }

     /* Swap Machine Order */
    @isTest static void test_SwapOrder() {

        User oTestUser = APTS_TestFacade.getTestUser();
        Account oAccount = APTS_TestFacade.getAccount();

        test.startTest();

        System.runAs(oTestUser) {

            ApexPages.currentPage().getParameters().put(APTS_OrderConstants.ID, oAccount.Id);

            APTS_CreateMachineOrderController oCreateMachineOrderController = new APTS_CreateMachineOrderController();
            oCreateMachineOrderController.doSOQLS();
            oCreateMachineOrderController.oOrder.APTS_Order_Sub_Type__c = APTS_OrderConstants.TECHNICAL_SWAP;
            //oCreateMachineOrderController.agreementWrapperList[0].selected = true;
            oCreateMachineOrderController.createOrder();
        
        test.stopTest();
        
        System.assertEquals('Technical Swap',oCreateMachineOrderController.oOrder.APTS_Order_Sub_Type__c);
         }
    }
    
     /* DeInstall Machine Order */
    @isTest static void test_DeInstallOrder() {

        User oTestUser = APTS_TestFacade.getTestUser();
        Account oAccount = APTS_TestFacade.getAccount();

        test.startTest();

        System.runAs(oTestUser) {

            ApexPages.currentPage().getParameters().put(APTS_OrderConstants.ID, oAccount.Id);

            APTS_CreateMachineOrderController oCreateMachineOrderController = new APTS_CreateMachineOrderController();
            oCreateMachineOrderController.doSOQLS();
            oCreateMachineOrderController.oOrder.APTS_Order_Sub_Type__c = APTS_OrderConstants.DE_INSTALLATION;
            //oCreateMachineOrderController.agreementWrapperList[0].selected = true;
            
            oCreateMachineOrderController.createOrder();    

         test.stopTest();
        
        System.assertEquals('De-Installation',oCreateMachineOrderController.oOrder.APTS_Order_Sub_Type__c); 
        }   
    }

     /* Internal Machine Move */
    @isTest static void test_InternalMovementOrder() {

        User oTestUser = APTS_TestFacade.getTestUser();
        Account oAccount = APTS_TestFacade.getAccount();

        test.startTest();

        System.runAs(oTestUser) {

            ApexPages.currentPage().getParameters().put(APTS_OrderConstants.ID, oAccount.Id);

            APTS_CreateMachineOrderController oCreateMachineOrderController = new APTS_CreateMachineOrderController();
            oCreateMachineOrderController.doSOQLS();
            oCreateMachineOrderController.oOrder.APTS_Order_Sub_Type__c = APTS_OrderConstants.INTERNAL_MOVEMENT;
            //oCreateMachineOrderController.agreementWrapperList[0].selected = true;
        
            oCreateMachineOrderController.createOrder();    
        
            test.stopTest();
        
            System.assertEquals('Internal Movement',oCreateMachineOrderController.oOrder.APTS_Order_Sub_Type__c);
           }
    }

     /* Extral Machine Move Order type */
    @isTest static void test_ExternalMovementOrder() {

        User oTestUser = APTS_TestFacade.getTestUser();
        Account oAccount = APTS_TestFacade.getAccount();

        test.startTest();

        System.runAs(oTestUser) {

            ApexPages.currentPage().getParameters().put(APTS_OrderConstants.ID, oAccount.Id);

            APTS_CreateMachineOrderController oCreateMachineOrderController = new APTS_CreateMachineOrderController();
            oCreateMachineOrderController.doSOQLS();
            oCreateMachineOrderController.oOrder.APTS_Order_Sub_Type__c = APTS_OrderConstants.EXTERNAL_MOVEMENT_WITH_CONTRACT_CHANGE;
            //oCreateMachineOrderController.agreementWrapperList[0].selected = true;
            
            oCreateMachineOrderController.createOrder();
    
        test.stopTest();
        
        System.assertEquals('External Movement With Contract Change',oCreateMachineOrderController.oOrder.APTS_Order_Sub_Type__c);
        }
    } 
    
     /* Convert or upgrate Machine Order */
    @isTest static void test_ConversionOrder() {

        User oTestUser = APTS_TestFacade.getTestUser();
        Account oAccount = APTS_TestFacade.getAccount();

        test.startTest();

        System.runAs(oTestUser) {

            ApexPages.currentPage().getParameters().put(APTS_OrderConstants.ID, oAccount.Id);

            APTS_CreateMachineOrderController oCreateMachineOrderController = new APTS_CreateMachineOrderController();
            oCreateMachineOrderController.doSOQLS();
            oCreateMachineOrderController.oOrder.APTS_Order_Sub_Type__c = APTS_OrderConstants.CONVERSION;
            //oCreateMachineOrderController.agreementWrapperList[0].selected = true;

            oCreateMachineOrderController.createOrder();        

        test.stopTest();
        
        System.assertEquals(APTS_OrderConstants.CONVERSION, oCreateMachineOrderController.oOrder.APTS_Order_Sub_Type__c);   
        }
    }
}