@isTest
private with sharing class APTS_CreateReOrderControllerTest {

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

    }


    @isTest static void test_ReOrder() {

        User oTestUser = APTS_TestFacade.getTestUser();
        Account oAccount = APTS_TestFacade.getAccount();

        Apttus_Config2__AccountLocation__c loc = new Apttus_Config2__AccountLocation__c();
        loc.Apttus_Config2__AccountId__c = oAccount.Id;
        loc.Account_Location_Status__c  = 'Valid';
        loc.SAP_Customer_ID__c = '123';
        loc.Delivery_Block_Reason__c = null;
        insert loc;

        List<Product2> oProductAll = new List<Product2>();
        Product2 oProduct1 = new Product2();
        oProduct1.ProductCode = 'CT4016359';
        oProduct1.Name = 'PICKW TEA TRAY EMPTY 1PC X1';
        oProduct1.Family = 'SAP_01';
        oProduct1.APTS_Associated_Sales_Org__c = 'SAP_0111';
        oProductAll.add(oProduct1);

        Product2 oProduct2 = new Product2();
        oProduct2.ProductCode = '4019328';
        oProduct2.Name = 'DE SMOOTH ROAST CERT LIQ AMB 2LX2 I NT';
        oProduct2.Family = 'SAP_01';
        oProduct2.APTS_Associated_Sales_Org__c = 'SAP_0111';
        oProductAll.add(oProduct2);

        Product2 oProduct3 = new Product2();
        oProduct3.ProductCode = '4021941';
        oProduct3.Name = 'DE PRESTIGE TQL 2LX2 ARDEENFRNLNORUSV';
        oProduct3.Family = 'SAP_01';
        oProduct3.APTS_Associated_Sales_Org__c = 'SAP_0111';
        oProductAll.add(oProduct3);

        Product2 oProduct4 = new Product2();
        oProduct4.ProductCode = '4021926';
        oProduct4.Name = 'DE MEDIUM RST TQL2LX2 - Draft';
        oProduct4.Family = 'SAP_01';
        oProduct4.APTS_Associated_Sales_Org__c = 'SAP_0111';
        oProductAll.add(oProduct4);

        Product2 oProduct5 = new Product2();
        oProduct5.ProductCode = '4045960';
        oProduct5.Name = 'DE ESP D.RST100%ARAB UTZ BN1000GX6INT';
        oProduct5.Family = 'SAP_01';
        oProduct5.APTS_Associated_Sales_Org__c = 'SAP_0111';
        oProductAll.add(oProduct5);

        Product2 oProduct6 = new Product2();
        oProduct6.ProductCode = '4041004';
        oProduct6.Name = 'DE CAF DARK ROAST TQL 2LX2';
        oProduct6.Family = 'SAP_01';
        oProduct6.APTS_Associated_Sales_Org__c = 'SAP_0111';
        oProductAll.add(oProduct6);

        Product2 oProduct7 = new Product2();
        oProduct7.ProductCode = '4016613';
        oProduct7.Name = 'PICKW TMS MINT ISE 25X1.5GX3 INT';
        oProduct7.Family = 'SAP_01';
        oProduct7.APTS_Associated_Sales_Org__c = 'SAP_0111';
        oProductAll.add(oProduct7);

        Product2 oProduct8 = new Product2();
        oProduct8.ProductCode = 'CT4016617';
        oProduct8.Name = 'PICKW TMS GT LEMON ISE 25X1.5GX3 INT';
        oProduct8.Family = 'SAP_01';
        oProduct8.APTS_Associated_Sales_Org__c = 'SAP_0111';
        oProductAll.add(oProduct8);

        Product2 oProduct9 = new Product2();
        oProduct9.ProductCode = '4016617';
        oProduct9.Name = 'PICKW TMS GT LEMON ISE 25X1.5GX3 INT';
        oProduct9.Family = 'SAP_01';
        oProduct9.APTS_Associated_Sales_Org__c = 'SAP_0111';
        oProductAll.add(oProduct9);

        insert oProductAll;

        List<Apttus_Config2__AssetLineItem__c> filterAssetLineItemToProductCode = new List<Apttus_Config2__AssetLineItem__c>();

        Apttus_Config2__AssetLineItem__c oAssetLineItem1 = new Apttus_Config2__AssetLineItem__c();
        oAssetLineItem1.Apttus_Config2__AccountId__c = oAccount.Id;
        oAssetLineItem1.Apttus_Config2__AssetStatus__c = 'Activated';
        oAssetLineItem1.Apttus_Config2__BasePrice__c = 1;
        oAssetLineItem1.Apttus_Config2__ProductId__c = oProductAll[0].Id;
        filterAssetLineItemToProductCode.add(oAssetLineItem1);

        Apttus_Config2__AssetLineItem__c oAssetLineItem2 = new Apttus_Config2__AssetLineItem__c();
        oAssetLineItem2.Apttus_Config2__AccountId__c = oAccount.Id;
        oAssetLineItem2.Apttus_Config2__AssetStatus__c = 'Activated';
        oAssetLineItem2.Apttus_Config2__BasePrice__c = 1;
        oAssetLineItem2.Apttus_Config2__ProductId__c = oProductAll[1].Id;
        filterAssetLineItemToProductCode.add(oAssetLineItem2);

        Apttus_Config2__AssetLineItem__c oAssetLineItem3 = new Apttus_Config2__AssetLineItem__c();
        oAssetLineItem3.Apttus_Config2__AccountId__c = oAccount.Id;
        oAssetLineItem3.Apttus_Config2__AssetStatus__c = 'Activated';
        oAssetLineItem3.Apttus_Config2__BasePrice__c = 1;
        oAssetLineItem3.Apttus_Config2__ProductId__c = oProductAll[2].Id;
        filterAssetLineItemToProductCode.add(oAssetLineItem3);


        Apttus_Config2__AssetLineItem__c oAssetLineItem4 = new Apttus_Config2__AssetLineItem__c();
        oAssetLineItem4.Apttus_Config2__AccountId__c = oAccount.Id;
        oAssetLineItem4.Apttus_Config2__AssetStatus__c = 'Activated';
        oAssetLineItem4.Apttus_Config2__BasePrice__c = 1;
        oAssetLineItem4.Apttus_Config2__ProductId__c = oProductAll[3].Id;
        filterAssetLineItemToProductCode.add(oAssetLineItem4);

        Apttus_Config2__AssetLineItem__c oAssetLineItem5 = new Apttus_Config2__AssetLineItem__c();
        oAssetLineItem5.Apttus_Config2__AccountId__c = oAccount.Id;
        oAssetLineItem5.Apttus_Config2__AssetStatus__c = 'Activated';
        oAssetLineItem5.Apttus_Config2__BasePrice__c = 1;
        oAssetLineItem5.Apttus_Config2__ProductId__c = oProductAll[4].Id;
        filterAssetLineItemToProductCode.add(oAssetLineItem5);

        Apttus_Config2__AssetLineItem__c oAssetLineItem6 = new Apttus_Config2__AssetLineItem__c();
        oAssetLineItem6.Apttus_Config2__AccountId__c = oAccount.Id;
        oAssetLineItem6.Apttus_Config2__AssetStatus__c = 'Activated';
        oAssetLineItem6.Apttus_Config2__BasePrice__c = 1;
        oAssetLineItem6.Apttus_Config2__ProductId__c = oProductAll[5].Id;
        filterAssetLineItemToProductCode.add(oAssetLineItem6);

        Apttus_Config2__AssetLineItem__c oAssetLineItem7 = new Apttus_Config2__AssetLineItem__c();
        oAssetLineItem7.Apttus_Config2__AccountId__c = oAccount.Id;
        oAssetLineItem7.Apttus_Config2__AssetStatus__c = 'Activated';
        oAssetLineItem7.Apttus_Config2__BasePrice__c = 1;
        oAssetLineItem7.Apttus_Config2__ProductId__c = oProductAll[6].Id;
        filterAssetLineItemToProductCode.add(oAssetLineItem7);

        Apttus_Config2__AssetLineItem__c oAssetLineItem8 = new Apttus_Config2__AssetLineItem__c();
        oAssetLineItem8.Apttus_Config2__AccountId__c = oAccount.Id;
        oAssetLineItem8.Apttus_Config2__AssetStatus__c = 'Activated';
        oAssetLineItem8.Apttus_Config2__BasePrice__c = 1;
        oAssetLineItem8.Apttus_Config2__ProductId__c = oProductAll[7].Id;
        filterAssetLineItemToProductCode.add(oAssetLineItem8);

        Apttus_Config2__AssetLineItem__c oAssetLineItem9 = new Apttus_Config2__AssetLineItem__c();
        oAssetLineItem9.Apttus_Config2__AccountId__c = oAccount.Id;
        oAssetLineItem9.Apttus_Config2__AssetStatus__c = 'Activated';
        oAssetLineItem9.Apttus_Config2__BasePrice__c = 1;
        oAssetLineItem9.Apttus_Config2__ProductId__c = oProductAll[8].Id;
        filterAssetLineItemToProductCode.add(oAssetLineItem9);
        insert filterAssetLineItemToProductCode;

        test.startTest();

        System.runAs(oTestUser) {

            ApexPages.currentPage().getParameters().put(APTS_OrderConstants.ID, oAccount.Id);


            APTS_CreateReOrderController oCreateReOrderController = new APTS_CreateReOrderController();
            APTS_CreateReOrderController.ProductWrapper oProdWrap = new APTS_CreateReOrderController.ProductWrapper();

            //APTS_CreateReOrderController.AgreementWrapper oAgreeWrap = new APTS_CreateReOrderController.AgreementWrapper();
            oCreateReOrderController.sProductCode = '55115867';
            oCreateReOrderController.bErrorOccurred  = false;
            oCreateReOrderController.oOrder = null;
            oCreateReOrderController.sAllProductsByName = null;
            oCreateReOrderController.sAllProductsByCode = null;
            oCreateReOrderController.dtOrderStartDate = null;
            oCreateReOrderController.sAllProducts  = null;
            oCreateReOrderController.sAllOrderNumbers  = null;
            oCreateReOrderController.iRemainProduct = 1;
            oCreateReOrderController.iLoadLess = 1;

            oCreateReOrderController.doSOQLS();

            oCreateReOrderController.loadAgreements();
            oCreateReOrderController.loadProducts();
            ApexPages.currentPage().getParameters().put(APTS_OrderConstants.FIRST_PARAM, '4016617');
            oCreateReOrderController.sProductCode = '4016617';
            oCreateReOrderController.searchProductsByCode();
            oCreateReOrderController.addProductsOnSearch();
            ApexPages.currentPage().getParameters().put(APTS_OrderConstants.FIRST_PARAM, 'DE CAF DARK ROAST TQL 2LX2');
            oCreateReOrderController.sProductName = 'DE CAF DARK ROAST TQL 2LX2';
            oCreateReOrderController.searchProductsByName();
            oCreateReOrderController.addProductsOnSearchByName();

            //oCreateReOrderController.callTwoMethods();
            //oCreateReOrderController.addProductsOnSearch();
            //oCreateReOrderController.addProductsOnSearchByName();
            oCreateReOrderController.createOrder();
            //oCreateReOrderController.searchProductsByName();
            //oCreateReOrderController.searchProductsByCode();
            oCreateReOrderController.errorMessageForNoProducts('Test');
            oCreateReOrderController.loadMore();
            //oCreateReOrderController.raiseError();
            //oCreateReOrderController.loadMore();
            //oCreateReOrderController.loadLess();
            ApexPages.currentPage().getParameters().put(APTS_OrderConstants.FIRST_PARAM, 'NoResultsFound');
            oCreateReOrderController.sProductCode = 'NoResultsFound';
            oCreateReOrderController.searchProductsByCode();
            oCreateReOrderController.addProductsOnSearch();
            ApexPages.currentPage().getParameters().put(APTS_OrderConstants.FIRST_PARAM, 'NoResultsFound');
            oCreateReOrderController.sProductName = 'NoResultsFound';
            oCreateReOrderController.searchProductsByName();
            oCreateReOrderController.addProductsOnSearchByName();
            ApexPages.currentPage().getParameters().put(APTS_OrderConstants.FIRST_PARAM, 'DE SMOOTH ROAST CERT LIQ AMB 2LX2 I NT');
            oCreateReOrderController.sProductName = 'DE SMOOTH ROAST CERT LIQ AMB 2LX2 I NT';
            oCreateReOrderController.searchProductsByName();
            oCreateReOrderController.addProductsOnSearchByName();


        }
    }

    @isTest static void test_ReOrder2() {

        User oTestUser = APTS_TestFacade.getTestUser();
        Account oAccount = APTS_TestFacade.getAccount();

        Apttus_Config2__AccountLocation__c loc = new Apttus_Config2__AccountLocation__c();
        loc.Apttus_Config2__AccountId__c = oAccount.Id;
        loc.Account_Location_Status__c  = 'Valid';
        loc.SAP_Customer_ID__c = '123';
        loc.Delivery_Block_Reason__c = null;
        insert loc;

        List<Product2> oProductAll = new List<Product2>();
        Product2 oProduct1 = new Product2();
        oProduct1.ProductCode = 'CT4016359';
        oProduct1.Name = 'PICKW TEA TRAY EMPTY 1PC X1';
        oProduct1.Family = 'SAP_01';
        oProduct1.APTS_Associated_Sales_Org__c = 'SAP_0111';
        oProductAll.add(oProduct1);

        Product2 oProduct2 = new Product2();
        oProduct2.ProductCode = '4019328';
        oProduct2.Name = 'DE SMOOTH ROAST CERT LIQ AMB 2LX2 I NT';
        oProduct2.Family = 'SAP_01';
        oProduct2.APTS_Associated_Sales_Org__c = 'SAP_0111';
        oProductAll.add(oProduct2);

        Product2 oProduct3 = new Product2();
        oProduct3.ProductCode = '4021941';
        oProduct3.Name = 'DE PRESTIGE TQL 2LX2 ARDEENFRNLNORUSV';
        oProduct3.Family = 'SAP_01';
        oProduct3.APTS_Associated_Sales_Org__c = 'SAP_0111';
        oProductAll.add(oProduct3);

        insert oProductAll;

        List<Apttus_Config2__AssetLineItem__c> filterAssetLineItemToProductCode = new List<Apttus_Config2__AssetLineItem__c>();

        Apttus_Config2__AssetLineItem__c oAssetLineItem1 = new Apttus_Config2__AssetLineItem__c();
        oAssetLineItem1.Apttus_Config2__AccountId__c = oAccount.Id;
        oAssetLineItem1.Apttus_Config2__AssetStatus__c = 'Activated';
        oAssetLineItem1.Apttus_Config2__BasePrice__c = 1;
        oAssetLineItem1.Apttus_Config2__ProductId__c = oProductAll[0].Id;
        filterAssetLineItemToProductCode.add(oAssetLineItem1);

        Apttus_Config2__AssetLineItem__c oAssetLineItem2 = new Apttus_Config2__AssetLineItem__c();
        oAssetLineItem2.Apttus_Config2__AccountId__c = oAccount.Id;
        oAssetLineItem2.Apttus_Config2__AssetStatus__c = 'Activated';
        oAssetLineItem2.Apttus_Config2__BasePrice__c = 1;
        oAssetLineItem2.Apttus_Config2__ProductId__c = oProductAll[1].Id;
        filterAssetLineItemToProductCode.add(oAssetLineItem2);

        Apttus_Config2__AssetLineItem__c oAssetLineItem3 = new Apttus_Config2__AssetLineItem__c();
        oAssetLineItem3.Apttus_Config2__AccountId__c = oAccount.Id;
        oAssetLineItem3.Apttus_Config2__AssetStatus__c = 'Activated';
        oAssetLineItem3.Apttus_Config2__BasePrice__c = 1;
        oAssetLineItem3.Apttus_Config2__ProductId__c = oProductAll[2].Id;
        filterAssetLineItemToProductCode.add(oAssetLineItem3);



        insert filterAssetLineItemToProductCode;

        test.startTest();

        System.runAs(oTestUser) {

            ApexPages.currentPage().getParameters().put(APTS_OrderConstants.ID, oAccount.Id);


            APTS_CreateReOrderController oCreateReOrderController = new APTS_CreateReOrderController();
            APTS_CreateReOrderController.ProductWrapper oProdWrap = new APTS_CreateReOrderController.ProductWrapper();

            //APTS_CreateReOrderController.AgreementWrapper oAgreeWrap = new APTS_CreateReOrderController.AgreementWrapper();
            oCreateReOrderController.sProductCode = '55115867';
            oCreateReOrderController.bErrorOccurred  = false;
            //oCreateReOrderController.oOrder = null;
            oCreateReOrderController.sAllProductsByName = null;
            oCreateReOrderController.sAllProductsByCode = null;
            oCreateReOrderController.dtOrderStartDate = null;
            oCreateReOrderController.sAllProducts  = null;
            oCreateReOrderController.sAllOrderNumbers  = null;
            oCreateReOrderController.iRemainProduct = 1;
            oCreateReOrderController.iLoadLess = 1;

            oCreateReOrderController.doSOQLS();

            oCreateReOrderController.loadAgreements();
            oCreateReOrderController.loadProducts();
            ApexPages.currentPage().getParameters().put(APTS_OrderConstants.FIRST_PARAM, '4019328');
            oCreateReOrderController.sProductCode = '4019328';
            oCreateReOrderController.searchProductsByCode();
            oCreateReOrderController.addProductsOnSearch();
            ApexPages.currentPage().getParameters().put(APTS_OrderConstants.FIRST_PARAM, 'PICKW TEA TRAY EMPTY 1PC X1');
            oCreateReOrderController.sProductName = 'PICKW TEA TRAY EMPTY 1PC X1';
            oCreateReOrderController.searchProductsByName();
            oCreateReOrderController.addProductsOnSearchByName();
            ApexPages.currentPage().getParameters().put(APTS_OrderConstants.FIRST_PARAM, 'DE PRESTIGE TQL 2LX2 ARDEENFRNLNORUSV');
            oCreateReOrderController.sProductName = 'DE PRESTIGE TQL 2LX2 ARDEENFRNLNORUSV';
            oCreateReOrderController.searchProductsByName();
            oCreateReOrderController.addProductsOnSearchByName();

            oCreateReOrderController.callTwoMethods();
            //oCreateReOrderController.addProductsOnSearch();
            //oCreateReOrderController.addProductsOnSearchByName();
            oCreateReOrderController.createOrder();
            //oCreateReOrderController.searchProductsByName();
            //oCreateReOrderController.searchProductsByCode();
            oCreateReOrderController.errorMessageForNoProducts('Test');
            oCreateReOrderController.loadMore();
            //oCreateReOrderController.loadMore();
            oCreateReOrderController.loadLess();
            oCreateReOrderController.goToOrder();
            oCreateReOrderController.back();


        }
    }



    @isTest static void test_ReOrder_ResetOrderSearch() {

        User oTestUser = APTS_TestFacade.getTestUser();
        Account oAccount = APTS_TestFacade.getAccount();
        test.startTest();

        System.runAs(oTestUser) {

            ApexPages.currentPage().getParameters().put(APTS_OrderConstants.ID, oAccount.Id);
            APTS_CreateReOrderController oCreateReOrderController = new APTS_CreateReOrderController();
            oCreateReOrderController.sProductCode = '4016617';
            oCreateReOrderController.sProductName = 'PICKW TMS GT LEMON ISE 25X1.5GX3 INT';
            oCreateReOrderController.resetOrderSearch();

        }
        test.stopTest();
    }



    @isTest static void test_ReOrder3() {

        User oTestUser = APTS_TestFacade.getTestUser();
        Account oAccount = APTS_TestFacade.getAccount();

        Apttus_Config2__AccountLocation__c loc = new Apttus_Config2__AccountLocation__c();
        loc.Apttus_Config2__AccountId__c = oAccount.Id;
        loc.Account_Location_Status__c  = 'Valid';
        loc.SAP_Customer_ID__c = '123';
        loc.Delivery_Block_Reason__c = null;
        insert loc;

        List<Product2> oProductAll = new List<Product2>();
        Product2 oProduct1 = new Product2();
        oProduct1.ProductCode = 'CT4016359';
        oProduct1.Name = 'PICKW TEA TRAY EMPTY 1PC X1';
        oProduct1.Family = 'SAP_01';
        oProduct1.APTS_Associated_Sales_Org__c = 'SAP_0111';
        oProductAll.add(oProduct1);

        insert oProductAll;

        List<Apttus_Config2__AssetLineItem__c> filterAssetLineItemToProductCode = new List<Apttus_Config2__AssetLineItem__c>();

        Apttus_Config2__AssetLineItem__c oAssetLineItem1 = new Apttus_Config2__AssetLineItem__c();
        oAssetLineItem1.Apttus_Config2__AccountId__c = oAccount.Id;
        oAssetLineItem1.Apttus_Config2__AssetStatus__c = 'Activated';
        oAssetLineItem1.Apttus_Config2__BasePrice__c = 1;
        oAssetLineItem1.Apttus_Config2__ProductId__c = oProductAll[0].Id;
        filterAssetLineItemToProductCode.add(oAssetLineItem1);

        insert filterAssetLineItemToProductCode;

        test.startTest();

        System.runAs(oTestUser) {

            ApexPages.currentPage().getParameters().put(APTS_OrderConstants.ID, oAccount.Id);


            APTS_CreateReOrderController oCreateReOrderController = new APTS_CreateReOrderController();
            APTS_CreateReOrderController.ProductWrapper oProdWrap = new APTS_CreateReOrderController.ProductWrapper();

            oCreateReOrderController.sProductCode = '55115867';
            oCreateReOrderController.bErrorOccurred  = false;
            oCreateReOrderController.sAllProductsByName = null;
            oCreateReOrderController.sAllProductsByCode = null;
            oCreateReOrderController.dtOrderStartDate = null;
            oCreateReOrderController.sAllProducts  = null;
            oCreateReOrderController.sAllOrderNumbers  = null;
            oCreateReOrderController.iRemainProduct = 1;
            oCreateReOrderController.iLoadLess = 1;
            oCreateReOrderController.doSOQLS();
            oCreateReOrderController.loadAgreements();
            oCreateReOrderController.loadProducts();
            ApexPages.currentPage().getParameters().put(APTS_OrderConstants.FIRST_PARAM, '4019328');
            oCreateReOrderController.sProductCode = '4019328';
            oCreateReOrderController.searchProductsByCode();
            oCreateReOrderController.addProductsOnSearch();
            ApexPages.currentPage().getParameters().put(APTS_OrderConstants.FIRST_PARAM, 'PICKW TEA TRAY EMPTY 1PC X1');
            oCreateReOrderController.sProductName = 'PICKW TEA TRAY EMPTY 1PC X1';
            oCreateReOrderController.searchProductsByName();
            oCreateReOrderController.addProductsOnSearchByName();
            ApexPages.currentPage().getParameters().put(APTS_OrderConstants.FIRST_PARAM, 'DE PRESTIGE TQL 2LX2 ARDEENFRNLNORUSV');
            oCreateReOrderController.sProductName = 'DE PRESTIGE TQL 2LX2 ARDEENFRNLNORUSV';
            oCreateReOrderController.searchProductsByName();
            oCreateReOrderController.addProductsOnSearchByName();
            oCreateReOrderController.callTwoMethods();
            oCreateReOrderController.createOrder();
            oCreateReOrderController.errorMessageForNoProducts('Test');
            oCreateReOrderController.loadMore();
            oCreateReOrderController.loadLess();
            oCreateReOrderController.goToOrder();
            oCreateReOrderController.back();


        }
    }


}