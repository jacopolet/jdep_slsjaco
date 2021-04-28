/*************************************************************
@Name: APTS_CreateStandardOrderControllerTest
@Author: Galin Georgiev
@CreateDate: 19-02-2018
@Description: Create Order from Account Test
@UsedBy: APTS_CreateStandardOrderController
******************************************************************/
//v100 19-02-2018 Galin Georgiev: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes
//v103 06-08-2018 Neev Shah : Standard Return CR - copy Adjustments from Assets
//v104 18-10-2018 Rajesh patel : Coverage improvement
//v105 By Nikita
/* Create Standard Order Controller test class */
@isTest
private with sharing class APTS_CreateStandardOrderControllerTest {

    /* Setup Test Data */
    @testSetup static void setupTestData() {

        User oTestUser = APTS_TestFacade.createTestUser();
        APTS_TestFacade.createMandatoryRecords(oTestUser);
        APTS_TestFacade.createAndConfigureAgreement(oTestUser);
        APTS_TestFacade.createAndConfigureOrder(oTestUser);



        List<Apttus_Config2__AssetLineItem__c> listAsset = APTS_TestFacade.getAssetLineItem();

        for (Apttus_Config2__AssetLineItem__c oAsset : listAsset) {
            oAsset.Apttus_Config2__Quantity__c = 0; //v105
        }
        update listAsset;

        List<Apttus_Config2_AssetAdjustItem__c> assetAdjList = new List<Apttus_Config2_AssetAdjustItem__c>();

        if (listAsset != null) {
            for (Apttus_Config2__AssetLineItem__c oAsset : listAsset) {
                Apttus_Config2_AssetAdjustItem__c oAssetAdj = new Apttus_Config2_AssetAdjustItem__c();
                oAssetAdj.Apttus_Config2_AssetLineItemId__c = oAsset.Id;
                oAssetAdj.Apttus_Config2_AssetAdjustAmount__c = 10;
                oAssetAdj.Apttus_Config2_AssetAdjustType__c = APTS_OrderConstants.DISCOUNT;
                assetAdjList.add(oAssetAdj);
            }
        }

        Database.insert(assetAdjList);

        System.assert(oTestUser != null);
    }

    /* Sandard Order */
    @isTest static void test_standardOrder() {

        User oTestUser = APTS_TestFacade.getTestUser();
        Account oAccount = APTS_TestFacade.getAccount();

        Apttus_Config2__AccountLocation__c loc = new Apttus_Config2__AccountLocation__c();
        loc.Apttus_Config2__AccountId__c = oAccount.Id;
        loc.Account_Location_Status__c  = 'Valid';
        loc.SAP_Customer_ID__c = '123';
        loc.Delivery_Block_Reason__c = null;
        insert loc;


        test.startTest();

        System.runAs(oTestUser) {

            ApexPages.currentPage().getParameters().put(APTS_OrderConstants.ID, oAccount.Id);

            APTS_CreateStandardOrderController oCreateStandardOrderController = new APTS_CreateStandardOrderController();

            oCreateStandardOrderController.doSOQLS();

            Map<Id, Account> idToAccountMapTmp = new Map<Id, Account>([SELECT Id, APTS_Account_Level__c FROM Account WHERE APTS_Ultimate_Parent_Id__c = :oAccount.Id]);
            oCreateStandardOrderController.filterAccounts(oAccount, idToAccountMapTmp);
            oCreateStandardOrderController.loadAgreements();

            oCreateStandardOrderController.agreementWrapperList[0].selected = true;
            oCreateStandardOrderController.getOrderSubTypePicklist();
            //oCreateStandardOrderController.createOrder();


            test.stopTest();

            //System.assertEquals(true, oCreateStandardOrderController.agreementWrapperList[0].selected);
        }
    }


    //v105 Sandard Order Nikita */
    @isTest static void test_standardReturnOrder() {

        User oTestUser = APTS_TestFacade.getTestUser();
        Account oAccount = APTS_TestFacade.getAccount();

        Apttus_Config2__AccountLocation__c loc = new Apttus_Config2__AccountLocation__c();
        loc.Apttus_Config2__AccountId__c = oAccount.Id;
        loc.Account_Location_Status__c  = 'Valid';
        loc.SAP_Customer_ID__c = '123';
        loc.Delivery_Block_Reason__c = null;
        insert loc;


        test.startTest();

        System.runAs(oTestUser) {

            ApexPages.currentPage().getParameters().put(APTS_OrderConstants.ID, oAccount.Id);

            APTS_CreateStandardOrderController oCreateStandardOrderController = new APTS_CreateStandardOrderController();

            oCreateStandardOrderController.doSOQLS();

            oCreateStandardOrderController.loadOrders();
            Map<Id, Account> idToAccountMapTmp = new Map<Id, Account>([SELECT Id, APTS_Account_Level__c FROM Account WHERE APTS_Ultimate_Parent_Id__c = :oAccount.Id]);
            oCreateStandardOrderController.filterAccounts(oAccount, idToAccountMapTmp);
            oCreateStandardOrderController.loadAgreements();

            oCreateStandardOrderController.oOrder.APTS_Order_Sub_Type__c = APTS_OrderConstants.STANDARD_RETURN;
            oCreateStandardOrderController.bShowAgreements = false;

            oCreateStandardOrderController.agreementWrapperList[0].selected = true;
            oCreateStandardOrderController.getOrderSubTypePicklist();

            oCreateStandardOrderController.orderWrapperList[0].orderLineItemWrapperList[0].selected = true;
            oCreateStandardOrderController.createOrder();
            oCreateStandardOrderController.checkHidden();
            oCreateStandardOrderController.createCart();

            Set<Id> setAssetIds = new Set<Id> ();
            setAssetIds.add(oCreateStandardOrderController.orderWrapperList[0].orderLineItemWrapperList[0].oOrderLineItem.Apttus_Config2__AssetLineItemId__c);
            Map<Id, Apttus_Config2__LineItem__c> mapLines = new Map<Id, Apttus_Config2__LineItem__c>([SELECT id, Apttus_Config2__AssetLineItemId__c, Apttus_Config2__IsAssetPricing__c, Apttus_Config2__BasePriceOverride__c FROM Apttus_Config2__LineItem__c]);
            oCreateStandardOrderController.setAssetPricing(false, setAssetIds,  mapLines);

            oCreateStandardOrderController.repriceCart();
            oCreateStandardOrderController.saveCart();
            oCreateStandardOrderController.finalizeCart();
            oCreateStandardOrderController.synchronizeCart();
            oCreateStandardOrderController.goToOrder();



            PageReference pageRef = oCreateStandardOrderController.back();


            test.stopTest();

            //System.assertEquals(true, oCreateStandardOrderController.agreementWrapperList[0].selected);
        }
    }

    /* Standard Return Order Create */
    @isTest static void test_standardReturnOrderCreate() {

        User oTestUser = APTS_TestFacade.getTestUser();
        Account oAccount = APTS_TestFacade.getAccount();

        Apttus_Config2__AccountLocation__c loc = new Apttus_Config2__AccountLocation__c();
        loc.Apttus_Config2__AccountId__c = oAccount.Id;
        loc.Account_Location_Status__c  = 'Valid';
        loc.SAP_Customer_ID__c = '123';
        loc.Delivery_Block_Reason__c = null;
        insert loc;

        /*List<Apttus__APTS_Agreement__c> AgrList = [select id from Apttus__APTS_Agreement__c where Apttus_Config2__AccountId__c = : oAccount.id];
        AgrList[0].APTS_Location__c =loc.id;
        update AgrList;*/

        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder();

        test.startTest();

        System.runAs(oTestUser) {

            ApexPages.currentPage().getParameters().put(APTS_OrderConstants.ID, oAccount.Id);

            APTS_CreateStandardOrderController oCreateStandardOrderController = new APTS_CreateStandardOrderController();

            oCreateStandardOrderController.doSOQLS();
            oCreateStandardOrderController.loadOrders();

            oCreateStandardOrderController.oOrder.APTS_Order_Sub_Type__c = APTS_OrderConstants.STANDARD_RETURN;
            oCreateStandardOrderController.bShowOrders = true;
            oCreateStandardOrderController.bShowAgreements = false;

            oCreateStandardOrderController.orderWrapperList[0].orderLineItemWrapperList[0].selected = true;
            oCreateStandardOrderController.orderWrapperList[0].orderLineItemWrapperList[0].returnedQuantity = 0;

            oCreateStandardOrderController.createOrder();
            oCreateStandardOrderController.createCart();
            oCreateStandardOrderController.changeAssets();
            oCreateStandardOrderController.cancelAssets();
            oCreateStandardOrderController.updateQuantity();
            oCreateStandardOrderController.repriceCart();
            oCreateStandardOrderController.saveCart();
            oCreateStandardOrderController.finalizeCart();
            oCreateStandardOrderController.synchronizeCart();
            oCreateStandardOrderController.goToOrder();

            test.stopTest();

            System.assertEquals('Standard Return', oCreateStandardOrderController.oOrder.APTS_Order_Sub_Type__c);
            System.assertNotEquals(false, oCreateStandardOrderController.bShowOrders);
            System.assertEquals(false, oCreateStandardOrderController.bShowAgreements);
        }

    }

    /* Search Order */
    @isTest static void test_searchOrder() {

        User oTestUser = APTS_TestFacade.getTestUser();
        Account oAccount = APTS_TestFacade.getAccount();

        test.startTest();

        System.runAs(oTestUser) {

            ApexPages.currentPage().getParameters().put(APTS_OrderConstants.ID, oAccount.Id);

            APTS_CreateStandardOrderController oCreateStandardOrderController = new APTS_CreateStandardOrderController();

            oCreateStandardOrderController.doSOQLS();
            oCreateStandardOrderController.loadOrders();

            oCreateStandardOrderController.oOrder.APTS_Order_Sub_Type__c = APTS_OrderConstants.STANDARD_RETURN;
            oCreateStandardOrderController.checkHidden();

            ApexPages.currentPage().getParameters().put(APTS_OrderConstants.FIRST_PARAM, 'Bundle');
            oCreateStandardOrderController.searchProducts();

            ApexPages.currentPage().getParameters().put(APTS_OrderConstants.FIRST_PARAM, 'O');
            oCreateStandardOrderController.searchOrderNumbers();

            oCreateStandardOrderController.doOrderSearch();

            oCreateStandardOrderController.resetOrderSearch();
            oCreateStandardOrderController.doOrderSearch();

            oCreateStandardOrderController.selectAll();
            // v104 ++<<
            oCreateStandardOrderController.cancelAssets();// Change done by rajesh
            //v104 ++>>

            test.stopTest();

            System.assertEquals('Standard Return', oCreateStandardOrderController.oOrder.APTS_Order_Sub_Type__c);
        }

    }

    /* Load More Less */
    @isTest static void test_LoadMoreLess() {

        User oTestUser = APTS_TestFacade.getTestUser();
        Account oAccount = APTS_TestFacade.getAccount();

        test.startTest();

        System.runAs(oTestUser) {

            ApexPages.currentPage().getParameters().put(APTS_OrderConstants.ID, oAccount.Id);

            APTS_CreateStandardOrderController oCreateStandardOrderController = new APTS_CreateStandardOrderController();

            oCreateStandardOrderController.doSOQLS();
            oCreateStandardOrderController.loadOrders();

            oCreateStandardOrderController.oOrder.APTS_Order_Sub_Type__c = APTS_OrderConstants.STANDARD_RETURN;

            oCreateStandardOrderController.loadMore();
            oCreateStandardOrderController.loadLess();
            oCreateStandardOrderController.createCart(); //v105
            oCreateStandardOrderController.selectAll();

            test.stopTest();

            System.assertEquals('Standard Return', oCreateStandardOrderController.oOrder.APTS_Order_Sub_Type__c);
        }
    }

    /* Standard Return Order Validate */
    @isTest static void test_standardReturnOrderValidate() {

        User oTestUser = APTS_TestFacade.getTestUser();
        Account oAccount = APTS_TestFacade.getAccount();


        test.startTest();

        System.runAs(oTestUser) {

            ApexPages.currentPage().getParameters().put(APTS_OrderConstants.ID, oAccount.Id);

            APTS_CreateStandardOrderController oCreateStandardOrderController = new APTS_CreateStandardOrderController();

            oCreateStandardOrderController.doSOQLS();
            oCreateStandardOrderController.loadOrders();

            oCreateStandardOrderController.oOrder.APTS_Order_Sub_Type__c = APTS_OrderConstants.STANDARD_RETURN;
            oCreateStandardOrderController.bShowOrders = true;
            oCreateStandardOrderController.bShowAgreements = false;


            oCreateStandardOrderController.orderWrapperList[0].selected = true;
            oCreateStandardOrderController.orderWrapperList[0].orderLineItemWrapperList[0].selected = true;
            oCreateStandardOrderController.orderWrapperList[0].orderLineItemWrapperList[0].returnedQuantity = 2;

            oCreateStandardOrderController.createOrder();

            oCreateStandardOrderController.orderWrapperList[0].orderLineItemWrapperList[0].returnedQuantity = Integer.valueOf(oCreateStandardOrderController.orderWrapperList[0].orderLineItemWrapperList[0].oOrderLineItem.Apttus_Config2__Quantity__c);

            oCreateStandardOrderController.createOrder();

            //OrderWrapper abc= new OrderWrapper();
            //Integer test1=oCreateStandardOrderController.compareTo(OrderWrapper abc);
            //APTS_OrderLineItemWrapper wrap = new APTS_OrderLineItemWrapper();
            test.stopTest();

            System.assertEquals('Standard Return', oCreateStandardOrderController.oOrder.APTS_Order_Sub_Type__c);
        }
    }

    /* StandardOrder Test */
    @isTest static void test_standardOrderTest() {

        User oTestUser = APTS_TestFacade.getTestUser();
        Account oAccount = APTS_TestFacade.getAccount();
        Set<Id> setAssetIds = new Set<Id>();
        Map<Id, Apttus_Config2__LineItem__c> mapLines = new Map<Id, Apttus_Config2__LineItem__c>();
        Map<Id, Id> mapAssetID = new Map<Id, Id>();
        Map<Id, Id> mapAssetIDs = new Map<Id, Id>();
        List<Apttus_Config2__AssetLineItem__c> assetLineItemList = APTS_TestFacade.getAssetLineItem();
        List<Apttus_Config2__LineItem__c> lineItem = APTS_TestFacade.getLineItemList();
        mapAssetIDs.put(assetLineItemList[0].Id, lineItem[0].Id);
        
        Boolean Status_value = false;
        List<APTS_CreateStandardOrderController.APTS_OrderLineItemWrapper> oLIWrapper = new List<APTS_CreateStandardOrderController.APTS_OrderLineItemWrapper>();
        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder();

        test.startTest();

        System.runAs(oTestUser) {

            APTS_CreateStandardOrderController oCreateStandardOrderController = new APTS_CreateStandardOrderController();
            APTS_CreateStandardOrderController.APTS_OrderLineItemWrapper wrap = new APTS_CreateStandardOrderController.APTS_OrderLineItemWrapper();
            // oCreateStandardOrderController.setAssetPricing(Status_value,setAssetIds,mapLines);
            oCreateStandardOrderController.addAssetAdjustments(mapAssetID);
            //oCreateStandardOrderController.addAssetAdjustments(mapAssetIDs);
            //oCreateStandardOrderController.APTS_OrderLineItemWrapper();
            oCreateStandardOrderController.updateQuantity();
            oCreateStandardOrderController.cancelAssets();
            oCreateStandardOrderController.changeAssets();
            oCreateStandardOrderController.createCart();
            oCreateStandardOrderController.checkHidden();
            //oCreateStandardOrderController.createOrder();

            // oLIWrapper.add(wrap);
            //APTS_CreateStandardOrderController.OrderWrapper abc= new APTS_CreateStandardOrderController.OrderWrapper(true, oOrder, oLIWrapper);
            //abc.compareTo(abc);





            test.stopTest();
        }
    }
    @isTest static void test_UnplannedReturnOrder() {

        User oTestUser = APTS_TestFacade.getTestUser();
        Account oAccount = APTS_TestFacade.getAccount();

        test.startTest();

        System.runAs(oTestUser) {

            ApexPages.currentPage().getParameters().put(APTS_OrderConstants.ID, oAccount.Id);

            APTS_CreateStandardOrderController oCreateStandardOrderController = new APTS_CreateStandardOrderController();

            oCreateStandardOrderController.doSOQLS();

            oCreateStandardOrderController.loadOrders();
            Map<Id, Account> idToAccountMapTmp = new Map<Id, Account>([SELECT Id, APTS_Account_Level__c FROM Account WHERE APTS_Ultimate_Parent_Id__c = :oAccount.Id]);
            oCreateStandardOrderController.filterAccounts(oAccount, idToAccountMapTmp);
            oCreateStandardOrderController.loadAgreements();

            oCreateStandardOrderController.oOrder.APTS_Order_Sub_Type__c = APTS_OrderConstants.UNPLANNED_RETURN;
            oCreateStandardOrderController.bShowAgreements = true;

            oCreateStandardOrderController.oOrder.APTS_Order_Sub_Type__c = APTS_OrderConstants.CONSIGNMENT_ISSUE;

            oCreateStandardOrderController.oOrder.APTS_Order_Sub_Type__c = APTS_OrderConstants.CONSIGNMENT_FILLUP;
            oCreateStandardOrderController.bShowAgreements = true;

            oCreateStandardOrderController.agreementWrapperList[0].selected = true;
            oCreateStandardOrderController.getOrderSubTypePicklist();

            oCreateStandardOrderController.orderWrapperList[0].orderLineItemWrapperList[0].selected = false;
            oCreateStandardOrderController.createOrder();
            oCreateStandardOrderController.checkHidden();
            oCreateStandardOrderController.createCart();

            Set<Id> setAssetIds = new Set<Id> ();
            setAssetIds.add(oCreateStandardOrderController.orderWrapperList[0].orderLineItemWrapperList[0].oOrderLineItem.Apttus_Config2__AssetLineItemId__c);
            Map<Id, Apttus_Config2__LineItem__c> mapLines = new Map<Id, Apttus_Config2__LineItem__c>([SELECT id, Apttus_Config2__AssetLineItemId__c, Apttus_Config2__IsAssetPricing__c, Apttus_Config2__BasePriceOverride__c FROM Apttus_Config2__LineItem__c]);
            oCreateStandardOrderController.setAssetPricing(false, setAssetIds,  mapLines);

            oCreateStandardOrderController.repriceCart();
            oCreateStandardOrderController.saveCart();
            oCreateStandardOrderController.finalizeCart();
            oCreateStandardOrderController.synchronizeCart();
            oCreateStandardOrderController.goToOrder();



            PageReference pageRef = oCreateStandardOrderController.back();


            test.stopTest();

            //System.assertEquals(true, oCreateStandardOrderController.agreementWrapperList[0].selected);
        }
    }
}