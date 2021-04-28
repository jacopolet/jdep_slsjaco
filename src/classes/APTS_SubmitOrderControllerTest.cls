@isTest
private with sharing class APTS_SubmitOrderControllerTest {
    private static final String ID = System.Label.APTS_Id;
    private static final String ACCOUNT_NAME = 'JDETestAccount';
    private static final String CONTACT_NUMBER = '1010101011';
    private static final String PRICELIST_NAME = 'JDETest Price List';
    private static final String PROD_FAMILY_MACHINE = 'MA';
    private static final String PROD_CONFIG_BUNDLE = 'Bundle';
    private static final String PENDING = System.Label.APTS_Pending;

    @isTest static void test_SubmitOrderController() {
        User oTestUser = APTS_TestDataFactory.createUser();

        Account oAcc = APTS_TestDataFactory.createAccount('Account_Spain');

        oAcc.SAP_Customer_ID__c = '9876543234';
        insert oAcc;

        Contact oCon = APTS_TestDataFactory.createContact(oAcc , '87654345678');
        insert oCon;

        Apttus_Config2__PriceList__c oPricelist = APTS_TestDataFactory.createPriceList('myPriceList');
        insert oPriceList;

        Apttus__APTS_Agreement__c oAgree = APTS_TestDataFactory.createAgreement(oCon.id, oPricelist.id, oAcc.id, 'Consumption Model');
        oAgree.RecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Consumption Model').getRecordTypeId();
        insert oAgree;


        Apttus_Config2__Order__c oOrder = APTS_TestDataFactory.createOrder(oAcc.id, oPricelist.Id, oCon.Id);
        oOrder.Apttus_CMConfig__AgreementId__c = oAgree.id;
        oOrder.Apttus_Config2__SoldToAccountId__c = oAcc.id;
        oOrder.Apttus_Config2__BillToAccountId__c = oAcc.Id;
        oOrder.Apttus_Config2__ShipToAccountId__c = oAcc.id;
        oOrder.APTS_Payer__c = oAcc.id;
        oOrder.APTS_SAP_OrderType__c = 'XA13';
        oOrder.APTS_Order_Sub_Type__c = 'Commercial Swap';
        oOrder.Apttus_Config2__Status__c = 'Draft';
        oOrder.APTS_Status__c  = 'Draft';
        oOrder.APTS_Requested_Installation_Date__c = APTS_OrderUtils.getTheNextMonday();
        insert oOrder;


        Apttus_Config2__Order__c oOrder1 = APTS_TestDataFactory.createOrder(oAcc.id, oPricelist.Id, oCon.Id);
        oOrder1.Apttus_Config2__SoldToAccountId__c = oAcc.id;
        oOrder1.Apttus_Config2__BillToAccountId__c = oAcc.id;
        oOrder1.Apttus_Config2__ShipToAccountId__c = oAcc.id;
        oOrder1.APTS_Payer__c = oAcc.id;
        oOrder1.APTS_SAP_OrderType__c = 'XA13';
        oOrder1.APTS_Order_Sub_Type__c = 'Commercial Swap';
        oOrder1.Apttus_Config2__PreviousVersion__c = oOrder.Id;
        oOrder1.Apttus_Config2__Status__c = 'Draft';
        oOrder1.APTS_Status__c  = 'Draft';
        oOrder1.APTS_Requested_Installation_Date__c = APTS_OrderUtils.getTheNextMonday();
        insert oOrder1;


        Product2 prod1 = APTS_TestDataFactory.createProduct(oAcc.Name, oAcc.Name, null, null, FALSE, FALSE);
        Database.insert(prod1, FALSE);

        //Create Price List Items
        Apttus_Config2__PriceListItem__c pli1 = APTS_TestDataFactory.createPriceListItem(oPricelist.Id, prod1.Id);
        Database.insert(pli1, FALSE);


        Apttus__APTS_Agreement__c oAgr1 = [Select id, RecordType.Id, RecordType.Name from Apttus__APTS_Agreement__c where Id = :oAgree.Id LIMIT 1];

        //Agreement Line Item
        Apttus__AgreementLineItem__c oAgrLineItem = APTS_TestDataFactory.createAgreementLineItem(prod1.Id, oAgree.Id, oAcc.Id, pli1.Id);
        oAgrLineItem.Apttus_CMConfig__ChargeType__c = 'Usage Fee';
        Database.insert(oAgrLineItem, FALSE);

        Apttus_Config2__OrderLineItem__c oOLI = new Apttus_Config2__OrderLineItem__c();
        oOLI.Apttus_Config2__ChargeType__c = 'Usage Fee';
        oOLI.Apttus_CMConfig__AgreementLineItemId__c = oAgrLineItem.id;
        oOLI.Apttus_Config2__OrderId__c = oOrder.id;
        insert oOLI;




        Apttus_Config2__OrderUsagePriceTier__c oOrderUsagePriceTier = new Apttus_Config2__OrderUsagePriceTier__c();
        oOrderUsagePriceTier.Apttus_Config2__OrderLineItemId__c = oOLI.Id;
        oOrderUsagePriceTier.Apttus_Config2__AdjustmentAmount__c = 5;
        oOrderUsagePriceTier.Apttus_Config2__Dimension1Value__c = 'Paid';
        oOrderUsagePriceTier.Apttus_Config2__Sequence__c = 1;
        Database.insert(oOrderUsagePriceTier, FALSE);

        test.startTest();

        System.runAs(oTestUser) {

            ApexPages.currentPage().getParameters().put(ID, oOrder.Id);
            APTS_SubmitOrderController.submitOrder(oOrder.Id, true);

            ApexPages.currentPage().getParameters().put(ID, oOrder1.Id);
            APTS_SubmitOrderController.submitOrder(oOrder1.Id, true);

            APTS_SubmitOrderController oSubmitOrderController = new APTS_SubmitOrderController();
            oSubmitOrderController.submitOrder();
            PageReference pg =  oSubmitOrderController.back();


            List<Apttus_Config2__Order__c> listOrders = [SELECT Id, APTS_Status__c FROM Apttus_Config2__Order__c ];

            System.assertNotEquals(TRUE, listOrders.isEmpty());
        }

        test.stopTest();
    }

    @isTest static void test_SubmitAmendOrder1() {

        User oTestUser = APTS_TestFacade.createTestUser();
        APTS_TestFacade.createMandatoryRecords(oTestUser);
        APTS_TestFacade.createAndConfigureOrder(oTestUser);

        //User oTestUser = APTS_TestFacade.getTestUser();
        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder();

        Apttus_Config2__Order__c oOrder2 = APTS_TestFacade.getOrder();
        //oOrder2.Apttus_Config2__PreviousVersion__c = oOrder.Id;
        oOrder2.APTS_SAP_OrderType__c = 'XA13';
        oOrder2.APTS_Order_Sub_Type__c = 'Digital Order';
        oOrder2.Apttus_Config2__PONumber__c = 'PO has expired';
        oOrder2.Apttus_Config2__Status__c = 'Draft';
        oOrder2.APTS_Status__c  = 'Draft';
        update oOrder2;

        test.startTest();
        System.runAs(oTestUser) {


            ApexPages.currentPage().getParameters().put(ID, oOrder2.Id);
            APTS_SubmitOrderController.submitOrder(oOrder2.Id, true);
            APTS_SubmitOrderController oSubmitOrderController1 = new APTS_SubmitOrderController();

            oSubmitOrderController1.submitOrder();



            ApexPages.currentPage().getParameters().put(ID, null);
            APTS_SubmitOrderController oSubmitOrderController2 = new APTS_SubmitOrderController();

            //oSubmitOrderController2.submitOrder();

            //APTS_SubmitOrderController.submitOrder(null, true);
            List<Apttus_Config2__Order__c> listOrders1 = [SELECT Id, APTS_Status__c FROM Apttus_Config2__Order__c ];
            System.assertNotEquals(TRUE, listOrders1.isEmpty());

            PageReference pg2 =  oSubmitOrderController2.back();


        }

        test.stopTest();
    }

    @isTest static void test_MachineCancellation() {

        User oTestUser = APTS_TestFacade.createTestUser();
        APTS_TestFacade.createMandatoryRecords(oTestUser);
        APTS_TestFacade.createAndConfigureOrder(oTestUser);

        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder();

        Apttus_Config2__Order__c oOrder2 = oOrder.clone(false, false, false, false);
        oOrder2.Apttus_Config2__PreviousVersion__c = oOrder.Id;
        oOrder2.APTS_SAP_OrderType__c = 'XA13';
        oOrder2.APTS_Order_Type__c = APTS_OrderConstants.MACHINE_ORDER;
        oOrder2.Apttus_Config2__Status__c = APTS_OrderConstants.STATUS_PENDING_CANCEL;
        oOrder2.APTS_Status__c  = APTS_OrderConstants.STATUS_PENDING_CANCEL;
        insert oOrder2;

        Case cse = new Case();
        cse.Subject = 'caseSubj';
        cse.Status = 'New';
        cse.ApptusOrder__c  = oOrder2.Id;
        insert cse;

        test.startTest();
        System.runAs(oTestUser) {

            APTS_SubmitOrderController.submitOrder(oOrder2.Id, true);

            ApexPages.currentPage().getParameters().put(ID, oOrder2.Id);
            APTS_SubmitOrderController oSubmitOrderController1 = new APTS_SubmitOrderController();
            oSubmitOrderController1.submitOrder();
            PageReference pg2 =  oSubmitOrderController1.back();

            List<Apttus_Config2__Order__c> listOrders1 = [SELECT Id, APTS_Status__c FROM Apttus_Config2__Order__c ];
            System.assertNotEquals(TRUE, listOrders1.isEmpty());
        }


        test.stopTest();
    }

    @isTest static void test_SubmitReturnOrder() {

        User oTestUser = APTS_TestFacade.createTestUser();

        Account oAcc = APTS_TestDataFactory.createAccount('Account_Spain');

        oAcc.SAP_Customer_ID__c = '9876500234';
        insert oAcc;

        Contact oCon = APTS_TestDataFactory.createContact(oAcc , '80054345678');
        insert oCon;

        Apttus_Config2__PriceList__c oPricelist = APTS_TestDataFactory.createPriceList('myPriceList');
        insert oPriceList;

        Apttus__APTS_Agreement__c oAgree = APTS_TestDataFactory.createAgreement(oCon.id, oPricelist.id, oAcc.id, 'Consumption Model');
        oAgree.RecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Consumption Model').getRecordTypeId();
        insert oAgree;

        Apttus_Config2__BillingPreference__c billpre = APTS_TestUtils.createBillingPrefrence();
        Database.insert(billpre, false);

        Apttus_Billing__Invoice__c oInvoice = new Apttus_Billing__Invoice__c();
        oInvoice.APTS_External_Invoice_Number__c = '1255666';
        oInvoice.Apttus_Billing__BillToAccountId__c = oAcc.Id;
            oInvoice.Apttus_Billing__LocationId__c = null;
            oInvoice.Apttus_Billing__Status__c = 'Draft';
            oInvoice.Apttus_Billing__TotalInvoiceAmount__c = 100;
          Database.Insert(oInvoice, false);
        

        Apttus_Config2__Order__c oOrder = APTS_TestDataFactory.createOrder(oAcc.id, oPricelist.Id, oCon.Id);
        oOrder.Apttus_CMConfig__AgreementId__c = oAgree.id;
        oOrder.Apttus_Config2__SoldToAccountId__c = oAcc.id;
        oOrder.Apttus_Config2__BillToAccountId__c = oAcc.Id;
        oOrder.Apttus_Config2__ShipToAccountId__c = oAcc.id;
        oOrder.APTS_Payer__c = oAcc.id;
        oOrder.APTS_SAP_OrderType__c = 'XA13';
        oOrder.APTS_Order_Sub_Type__c = 'Commercial Swap';
        oOrder.Apttus_Config2__Status__c = 'Draft';
        oOrder.APTS_Status__c  = 'Draft';
        oOrder.APTS_Requested_Installation_Date__c = APTS_OrderUtils.getTheNextMonday();
        oOrder.APTS_Invoice__c = oInvoice.id;
        insert oOrder;

        Product2 prod1 = APTS_TestDataFactory.createProduct(oAcc.Name, oAcc.Name, null, null, FALSE, FALSE);
        Database.insert(prod1, FALSE);

        //Create Price List Items
        Apttus_Config2__PriceListItem__c pli1 = APTS_TestDataFactory.createPriceListItem(oPricelist.Id, prod1.Id);
        Database.insert(pli1, FALSE);


        Apttus__APTS_Agreement__c oAgr1 = [Select id, RecordType.Id, RecordType.Name from Apttus__APTS_Agreement__c where Id = :oAgree.Id LIMIT 1];

        //Agreement Line Item
        Apttus__AgreementLineItem__c oAgrLineItem = APTS_TestDataFactory.createAgreementLineItem(prod1.Id, oAgree.Id, oAcc.Id, pli1.Id);
        oAgrLineItem.Apttus_CMConfig__ChargeType__c = 'Usage Fee';
        Database.insert(oAgrLineItem, FALSE);

        Apttus_Config2__AssetLineItem__c ali = APTS_TestUtils.createAssetLineItem(oAcc.Id, prod1.Id, oPricelist.Id, pli1.Id , billpre.Id , oOrder.Id);
        ali.Apttus_CMConfig__AgreementId__c = oAgr1.Id;
        ali.Apttus_Config2__AssetStatus__c = 'Terminated';
        insert ali;

        Apttus_Config2__OrderLineItem__c oOLI = new Apttus_Config2__OrderLineItem__c();
        oOLI.Apttus_Config2__ChargeType__c = 'Usage Fee';
        oOLI.Apttus_CMConfig__AgreementLineItemId__c = oAgrLineItem.id;
        oOLI.Apttus_Config2__OrderId__c = oOrder.id;
        oOLI.Apttus_Config2__AssetLineItemId__c = ali.id;
        insert oOLI;

        Apttus_Config2__AccountLocation__c oAccLoc = new Apttus_Config2__AccountLocation__c();
        oAccLoc.Apttus_Config2__AccountId__c = oAcc.id;
        oAccLoc.SAP_Customer_ID__c = '9876543234';
        insert oAccLoc;

        Apttus_Config2__OrderUsagePriceTier__c oOrderUsagePriceTier = new Apttus_Config2__OrderUsagePriceTier__c();
        oOrderUsagePriceTier.Apttus_Config2__OrderLineItemId__c = oOLI.Id;
        oOrderUsagePriceTier.Apttus_Config2__AdjustmentAmount__c = 5;
        oOrderUsagePriceTier.Apttus_Config2__Dimension1Value__c = 'Paid';
        oOrderUsagePriceTier.Apttus_Config2__Sequence__c = 1;
        Database.insert(oOrderUsagePriceTier, FALSE);

        List<Apttus_Config2__OrderLineItem__c> orderLineItemList = APTS_TestFacade.getOrderLineItemList(oOrder.Id);
        List<Apttus_Config2__AssetLineItem__c> assetLineItemList = APTS_TestFacade.getAssetLineItem();

        test.startTest();

        System.runAs(oTestUser) {

            ApexPages.currentPage().getParameters().put(ID, oOrder.Id);
            APTS_SubmitOrderController.submitOrder(oOrder.Id, true);

            APTS_SubmitOrderController.setInvoiceLineItemOnOLI(oOrder);
            APTS_SubmitOrderController s = new APTS_SubmitOrderController();
            s.back();

        }

        test.stopTest();
    }
}