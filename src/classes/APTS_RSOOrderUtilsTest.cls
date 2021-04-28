@isTest
public class APTS_RSOOrderUtilsTest {
    @testSetup static void setupTestData() {
        User oTestUser = APTS_TestFacade.createTestUser();

        Group queue = new Group();
        queue.name = System.Label.APTS_CS_Queue;
        queue.Type = 'Queue';
        insert queue;

        Account acc = APTS_TestDataFactory.createAccount('RSO Order Test');
        insert acc;

        Account accContractProc = APTS_TestDataFactory.createAccount('RSO Order Test2');
        accContractProc.ParentId = acc.Id;
        insert accContractProc;

        Apttus_Config2__AccountLocation__c loc = new Apttus_Config2__AccountLocation__c();
        loc.Apttus_Config2__AccountId__c = acc.Id;
        insert loc;

        Apttus_Config2__AccountLocation__c loc1 = new Apttus_Config2__AccountLocation__c();
        loc1.Apttus_Config2__AccountId__c = accContractProc.Id;
        insert loc1;

        Contact con = APTS_TestDataFactory.createContact(acc, '+31-3000000000');
        con.Preferred_Language__c = 'SAP_EN';
        Insert con;

        Case cse = TS_TestDataFactory.createFieldServiceCase();
        cse.ContactId = con.Id;
        insert cse;

        Apttus_Config2__PriceList__c plist = APTS_TestDataFactory.createPriceList('Netherlands Standard');
        insert plist;

        Product2 prod = APTS_TestDataFactory.createProduct('test rso ', '08111', 'Ingrident', 'Standalone', FALSE, FALSE);
        prod.APTS_Associated_Sales_Org__c = 'SAP_0111';
        insert prod;

        Apttus_Config2__PriceListItem__c plistItem = APTS_TestDataFactory.createPriceListItem(plist.Id, prod.Id);
        insert plistItem;

        // Create a product
        Product2 catProduct = APTS_TestDataFactory.createProduct('Category Product', '26940900', 'Ingrident', 'Standalone', FALSE, FALSE);
        catProduct.IsActive = true;
        catProduct.APTS_Category_Adjustments_Product__c = true;
        insert CatProduct;

        Apttus_Config2__PriceListItem__c priceListItem1 = APTS_TestDataFactory.createPriceListItem(plist.id, CatProduct.id);
        insert priceListItem1;

        Apttus_Config2__ClassificationName__c category = APTS_TestDataFactory.createCategory();
        insert category;

        Apttus_Config2__ClassificationName__c subcategory = APTS_TestDataFactory.createCategory();
        subcategory.Name = 'Beans';
        subcategory.Apttus_Config2__HierarchyLabel__c = 'Beans';
        subcategory.Apttus_Config2__Type__c = 'Both';
        insert subcategory;

        Apttus_Config2__ClassificationName__c ssubcategory = APTS_TestDataFactory.createCategory();
        ssubcategory.Name = 'Coffee Beans';
        ssubcategory.Apttus_Config2__HierarchyLabel__c = 'Coffee Beans';
        ssubcategory.Apttus_Config2__Type__c = 'Both';
        insert ssubcategory;

        // Create category hierarchy
        Apttus_Config2__ClassificationHierarchy__c categoryHierarchy =  APTS_TestDataFactory.createCategoryHierarchy(category.Id, 'Coffee');
        insert categoryHierarchy;

        // Create subcategory
        Apttus_Config2__ClassificationHierarchy__c subCategoryHierarchy = APTS_TestDataFactory.createSubCategory(subcategory.Id, categoryHierarchy.Id);
        insert subCategoryHierarchy;

        // Create subsubcategory
        Apttus_Config2__ClassificationHierarchy__c subSubCategoryHierarchy = new Apttus_Config2__ClassificationHierarchy__c();
        subSubCategoryHierarchy.Name = 'Sub Sub Category Beans';
        subSubCategoryHierarchy.CurrencyIsoCode = 'EUR';
        subSubCategoryHierarchy.Apttus_Config2__DefaultSearchCategory__c = false;
        subSubCategoryHierarchy.Apttus_Config2__ExpandedByDefault__c = false;
        subSubCategoryHierarchy.Apttus_Config2__HideAllSearchFilters__c = false;
        subSubCategoryHierarchy.Apttus_Config2__IncludeInTotalsView__c = true;
        subSubCategoryHierarchy.Apttus_Config2__IsHidden__c = false;
        subSubCategoryHierarchy.Apttus_Config2__IsPicklist__c = false;
        subSubCategoryHierarchy.Apttus_Config2__Label__c = 'Espresso Beans';
        subSubCategoryHierarchy.Apttus_Config2__Left__c = 2;
        subSubCategoryHierarchy.Apttus_Config2__Level__c = 1;
        subSubCategoryHierarchy.Apttus_Config2__MaxOptions__c = 1.00000;
        subSubCategoryHierarchy.Apttus_Config2__MinOptions__c = 1.00000;
        subSubCategoryHierarchy.Apttus_Config2__Right__c = 3;
        subSubCategoryHierarchy.Apttus_Config2__Modifiable__c = true;
        subSubCategoryHierarchy.Apttus_Config2__HierarchyId__c = ssubcategory.Id;
        subSubCategoryHierarchy.Apttus_Config2__AncestorId__c = subCategoryHierarchy.Id;
        subSubCategoryHierarchy.Apttus_Config2__PrimordialId__c = categoryHierarchy.Id;
        insert subSubCategoryHierarchy;

        APTS_RSO_Product_Catalog__c oRSOProd = new APTS_RSO_Product_Catalog__c();
        oRSOProd.APTS_Product__c = prod.Id;
        oRSOProd.APTS_Type__c = 'Routesales';
        oRSOProd.APTS_Region__c  = 'SAP_0111';
        oRSOProd.APTS_Category_Text__c  = category.name;
        oRSOProd.APTS_Sub_Category_Text__c  = subcategory.name;
        oRSOProd.APTS_Sub_Sub_Category_Text__c  = ssubcategory.name;
        insert oRSOProd;

        Apttus__APTS_Agreement__c agr = APTS_TestDataFactory.createAgreement(con.Id, plist.Id, acc.Id, 'Standard Deal');
        agr.Apttus_CMConfig__LocationId__c = loc.Id;
        agr.Apttus__Status__c = 'Activated';
        agr.APTS_Sold_To__c = acc.Id;
        agr.APTS_Routesales__c = true;
        insert agr;

        Apttus__APTS_Agreement__c agrWithProds = APTS_TestDataFactory.createAgreement(con.Id, plist.Id, accContractProc.Id, 'Standard Deal');
        agrWithProds.Apttus_CMConfig__LocationId__c = loc1.Id;
        agrWithProds.Apttus__Status__c = 'Activated';
        agrWithProds.APTS_Sold_To__c = accContractProc.Id;
        agrWithProds.APTS_Routesales__c = true;
        insert agrWithProds;

        Apttus__AgreementLineItem__c agLine = APTS_TestDataFactory.createAgreementLineItem(prod.Id, agr.Id, acc.Id, plistItem.Id);
        insert agLine;

        APTS_Agreement_PO_Details__c oPODetails = new APTS_Agreement_PO_Details__c();
        oPODetails.APTS_Agreement__c = agr.Id;
        oPODetails.APTS_PO_Number__c = '';
        oPODetails.APTS_PO_Number_Required__c = 'Yes';
        oPODetails.APTS_PO_Number_Type__c = 'Variable';
        oPODetails.APTS_PO_Category__c = 'Ingredients';
        insert oPODetails;

        APTS_Contract_Entitlement_Repository__c oCERRecord = new APTS_Contract_Entitlement_Repository__c();
        oCERRecord.APTS_Sold_to_Party__c = acc.Id;
        oCERRecord.APTS_Product__c = prod.Id;
        oCERRecord.APTS_Contributing_Agreement__c = agr.Id;
        oCERRecord.APTS_Agreement_Line_Item__c = agLine.Id;
        oCERRecord.APTS_Contributing_Agreement_Level__c = 'Child';
        oCERRecord.APTS_Agreement_Type__c = 'Standard Deal';
        insert oCERRecord;


        Apttus__AgreementLineItem__c catagLine = APTS_TestDataFactory.createAgreementLineItem(CatProduct.Id, agr.Id, acc.Id, priceListItem1.Id);
        insert catagLine;

        APTS_Contract_Entitlement_Repository__c oCERRecord1 = new APTS_Contract_Entitlement_Repository__c();
        oCERRecord1.APTS_Sold_to_Party__c = acc.Id;
        oCERRecord1.APTS_Product__c = CatProduct.Id;
        oCERRecord1.APTS_Contributing_Agreement__c = agr.Id;
        oCERRecord1.APTS_Agreement_Line_Item__c = catagLine.Id;
        oCERRecord1.APTS_Contributing_Agreement_Level__c = 'Child';
        oCERRecord1.APTS_Category_Level__c = 'Sub Sub Category';
        oCERRecord1.APTS_Agreement_Type__c = 'Standard Deal';
        oCERRecord1.APTS_CategoryCER__c = categoryHierarchy.Id;
        oCERRecord1.APTS_Sub_Category__c = subCategoryHierarchy.Id;
        oCERRecord1.APTS_Sub_Sub_Category__c = subSubCategoryHierarchy.Id;
        insert oCERRecord1;


    }

    @isTest static void testGetInterfaceLog() {
        User oTestUser = APTS_TestFacade.getTestUser();

        test.startTest();

        System.runAs(oTestUser) {
            APTS_Order_Interface_Log__c oLog =  APTS_RSOOrderUtils.getInterfaceLog(null, 0, 5, '123', '12345', null, 'MobileApp');
            System.assertNotEquals(NULL, oLog);
        }

        test.stopTest();
    }

    @isTest static void getRSOContractedProdWrapper() {
        User oTestUser = APTS_TestFacade.getTestUser();

        test.startTest();

        System.runAs(oTestUser) {
            APTS_RSOProductCatalogWrapper.ContractedProducts obj =  APTS_RSOOrderUtils.getRSOContractedProdWrapper(new APTS_RSOProductCatalogWrapper.ContractedProducts());
            System.assertNotEquals(NULL, obj);
        }

        test.stopTest();
    }

    @isTest static void testGetQueue() {
        User oTestUser = APTS_TestFacade.getTestUser();

        test.startTest();
        try {
            System.runAs(oTestUser) {
                Group oGrp =  APTS_DigitalOrderBatchHelper.getCSQueue();
                System.assertNotEquals(NULL, oGrp);

                APTS_Order_Error_Log__c oErrLog = APTS_RSOOrderUtils.createErrorLog('sErrMsg', 'sSourceOrder', null, null, null, oGrp);
                System.assertNotEquals(NULL, oErrLog);

                APTS_RSOOrderUtils.setHTTPResponseData(501, 'errorCode', 'message');
            }

            test.stopTest();
        } catch (Exception ex) {
            throw ex;
        }
    }

    @isTest static void testGetRequestBodyJSON() {
        User oTestUser = APTS_TestFacade.getTestUser();
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeStringField('EmpEmail', 'testRSO@JDECoffee.com');
        gen.writeEndObject();
        String jSONClass = gen.getAsString();

        test.startTest();

        System.runAs(oTestUser) {
            RestRequest request = new RestRequest();
            RestResponse res = new RestResponse();
            request.requestUri = '/services/apexrest/RSOOrder/refreshProducts/';
            request.httpMethod = 'POST';
            request.requestBody = Blob.valueof(jSONClass);

            Map<String, Object>  mapStr = APTS_RSOOrderUtils.getRequestBodyJSON(request);
            System.assertNotEquals(NULL, mapStr);
        }

        test.stopTest();
    }

    @isTest static void testGetAgreements() {
        User oTestUser = APTS_TestFacade.getTestUser();
        Map<Id, Account> mapAccounts = new Map<Id, Account>([SELECT Id FROM Account LIMIT 1]);

        test.startTest();

        System.runAs(oTestUser) {
            Map<Id, Account> accMap = APTS_RSOOrderUtils.getAccounts(mapAccounts.keySet());
            System.assertNotEquals(null, accMap);
            System.assertNotEquals(true, accMap.isEmpty());
            Set<ID> setAcc = new Set<ID>();
            setAcc = mapAccounts.keySet();
            List<ID> ListAcc= new List<ID>();
            ListAcc.addAll(setAcc);
             Map<Id, List<Apttus__APTS_Agreement__c>> mapAg;

            APTS_RSOOrderUtils.RSOWrapper rsoWrapper= APTS_RSOOrderUtils.getRSOAgreements('Route Sales Order', ListAcc);
             mapAg = rsoWrapper.mapAccAgr;
            System.assertNotEquals(NULL, mapAg);
            System.assertNotEquals(NULL, mapAg.isEmpty());
        }

        test.stopTest();
    }

    @isTest static void testGetInterfaceLogExtOrder() {
        User oTestUser = APTS_TestFacade.getTestUser();
        Map<Id, Account> mapAccounts = new Map<Id, Account>([SELECT Id FROM Account LIMIT 1]);

        test.startTest();

        System.runAs(oTestUser) {
            APTS_RSOOrderUtils.OrderInterfaceWrapper wrapper = APTS_RSOOrderUtils.getInterfaceLogExtOrder('Route Sales Order 12332323232323232323232', 'RSOApp', 'sn123');
            System.assertNotEquals(NULL, wrapper);
        }

        test.stopTest();
    }

    @isTest static void testGetCatalogProducts() {
        APTS_Sync_Data_Log__c oSynLog = new APTS_Sync_Data_Log__c();
        oSynLog.APTS_Date_of_Last_Sync__c = System.today() - 5;
        insert oSynLog;

        User oTestUser = APTS_TestFacade.getTestUser();

        test.startTest();

        System.runAs(oTestUser) {
            APTS_RSOProductCatalogWrapper wrapperobj = APTS_RSOOrderUtils.getRSOCatalogProducts('Routesales', 'SAP_0111', FALSE, oSynLog, false);
            System.assertNotEquals(NULL, wrapperobj);
            wrapperobj = APTS_RSOOrderUtils.getRSOCatalogProducts('Routesales', 'SAP_0111', true, oSynLog, true);
            System.assertNotEquals(NULL, wrapperobj);
        }

        test.stopTest();
    }

    @isTest static void testGetContractedProducts() {
        APTS_Sync_Data_Log__c oSynLog = new APTS_Sync_Data_Log__c();
        oSynLog.APTS_Date_of_Last_Sync__c = System.today() - 5;
        insert oSynLog;

        User oTestUser = APTS_TestFacade.getTestUser();

        Map<Id, Account> mapAcc = new Map<Id, Account> ([SELECT Id from Account]);

        test.startTest();

        System.runAs(oTestUser) {
            APTS_RSOProductCatalogWrapper wrapperobj = APTS_RSOOrderUtils.getRSOCatalogProducts('Routesales', 'SAP_0111', FALSE, oSynLog, false);
            System.assertNotEquals(NULL, wrapperobj);
            APTS_RSOProductCatalogWrapper wrapperobj1 = APTS_RSOOrderUtils.getRSOCatalogProducts('Routesales', 'SAP_0111', FALSE, oSynLog);
            System.assertNotEquals(NULL, wrapperobj1);

            Map<Id, Apttus__APTS_Agreement__c> mapContributingAg = APTS_RSOOrderUtils.getRSOAgreement('Route Sales Order', mapAcc.keySet());
            System.assertNotEquals(NULL, mapContributingAg);

            Map<Id, List<APTS_RSOProductCatalogWrapper.ContractedProducts>> mapContractedProds = APTS_RSOOrderUtils.getContractedProducts('Routesales', mapAcc.keySet(), mapContributingAg, wrapperobj.mapAllRSOProducts, wrapperobj.mapCategoryProductsId);
            System.assertNotEquals(NULL, mapContractedProds);
            System.assertNotEquals(true, mapContractedProds.isEmpty());
            
            Apttus_Config2__PriceList__c plist = APTS_TestDataFactory.createPriceList('Netherlands Standard');
        insert plist;

        Product2 prod = APTS_TestDataFactory.createProduct('test rso ', '08111', 'Ingrident', 'Standalone', FALSE, FALSE);
        prod.APTS_Associated_Sales_Org__c = 'SAP_6712';
        insert prod;

        Apttus_Config2__PriceListItem__c plistItem = APTS_TestDataFactory.createPriceListItem(plist.Id, prod.Id);
        insert plistItem;

        // Create a product
        Product2 catProduct = APTS_TestDataFactory.createProduct('Category Product', '26940900', 'Ingrident', 'Standalone', FALSE, FALSE);
        catProduct.IsActive = true;
        catProduct.APTS_Category_Adjustments_Product__c = true;
        insert CatProduct;

        Apttus_Config2__PriceListItem__c priceListItem1 = APTS_TestDataFactory.createPriceListItem(plist.id, CatProduct.id);
        insert priceListItem1;

        Apttus_Config2__ClassificationName__c category = APTS_TestDataFactory.createCategory();
        insert category;

        Apttus_Config2__ClassificationName__c subcategory = APTS_TestDataFactory.createCategory();
        subcategory.Name = 'Beans';
        subcategory.Apttus_Config2__HierarchyLabel__c = 'Beans';
        subcategory.Apttus_Config2__Type__c = 'Both';
        insert subcategory;

        Apttus_Config2__ClassificationName__c ssubcategory = APTS_TestDataFactory.createCategory();
        ssubcategory.Name = 'Coffee Beans';
        ssubcategory.Apttus_Config2__HierarchyLabel__c = 'Coffee Beans';
        ssubcategory.Apttus_Config2__Type__c = 'Both';
        insert ssubcategory;

        // Create category hierarchy
        Apttus_Config2__ClassificationHierarchy__c categoryHierarchy =  APTS_TestDataFactory.createCategoryHierarchy(category.Id, 'Coffee');
        insert categoryHierarchy;

        // Create subcategory
        Apttus_Config2__ClassificationHierarchy__c subCategoryHierarchy = APTS_TestDataFactory.createSubCategory(subcategory.Id, categoryHierarchy.Id);
        insert subCategoryHierarchy;

        APTS_RSO_Product_Catalog__c oRSOProd = new APTS_RSO_Product_Catalog__c();
        oRSOProd.APTS_Product__c = prod.Id;
        oRSOProd.APTS_Type__c = 'Routesales';
        oRSOProd.APTS_Region__c  = 'SAP_0111';
        oRSOProd.APTS_Category_Text__c  = category.name;
        oRSOProd.APTS_Sub_Category_Text__c  = subcategory.name;
        oRSOProd.APTS_Sub_Sub_Category_Text__c  = ssubcategory.name;
        insert oRSOProd;            
            
            APTS_RSOProductCatalogWrapper.BlockedProducts mapBlockedProducts = APTS_RSOOrderUtils.getBlockedProductWrapper(oRSOProd);
            
        }

        test.stopTest();
    }

    @isTest static void testGetWorkOrderLineItems() {

        User oTestUser = APTS_TestFacade.getTestUser();

        test.startTest();

        System.runAs(oTestUser) {
            List<WorkOrderLineItem> lstWOLI = APTS_RSOOrderUtils.getWorkOrderLineItem('TestEngineer@test.com', FALSE, 'Dispatched');

        }

        test.stopTest();
    }

    @isTest static void testGetSAPOrderType() {

        User oTestUser = APTS_TestFacade.getTestUser();
        Apttus_Config2__Order__c oRSOOrder = new Apttus_Config2__Order__c();

        test.startTest();

        System.runAs(oTestUser) {
            oRSOOrder.APTS_Order_Type__c = 'Route Sales Order';
            oRSOOrder.APTS_Order_Sub_Type__c = 'Standard Order';
            oRSOOrder.APTS_Fulfill_From_To_Van__c = true;
            String saptype = APTS_RSOOrderUtils.getSAPOrderType(oRSOOrder);
            System.assertEquals(saptype.equalsIgnoreCase('XA02'), true);

            oRSOOrder.APTS_Fulfill_From_To_Van__c = FALSE;
            saptype = APTS_RSOOrderUtils.getSAPOrderType(oRSOOrder);
            System.assertEquals(saptype.equalsIgnoreCase('XA01'), true);

            oRSOOrder.APTS_Order_Sub_Type__c = 'Unplanned Return';
            saptype = APTS_RSOOrderUtils.getSAPOrderType(oRSOOrder);
            System.assertEquals(saptype.equalsIgnoreCase('XB02'), true);

            oRSOOrder.APTS_Fulfill_From_To_Van__c = true;
            saptype = APTS_RSOOrderUtils.getSAPOrderType(oRSOOrder);
            System.assertEquals(saptype.equalsIgnoreCase('XB05'), true);

            oRSOOrder.APTS_Order_Type__c = 'Operating Order';
            oRSOOrder.APTS_Order_Sub_Type__c = 'Standard Order';
            saptype = APTS_RSOOrderUtils.getSAPOrderType(oRSOOrder);
            System.assertEquals(saptype.equalsIgnoreCase('XA02'), true);

            oRSOOrder.APTS_Fulfill_From_To_Van__c = FALSE;
            saptype = APTS_RSOOrderUtils.getSAPOrderType(oRSOOrder);
            System.assertEquals(saptype.equalsIgnoreCase('XA01'), true);

            oRSOOrder.APTS_Order_Sub_Type__c = 'Unplanned Return';
            saptype = APTS_RSOOrderUtils.getSAPOrderType(oRSOOrder);
            System.assertEquals(saptype.equalsIgnoreCase('XB02'), true);

            oRSOOrder.APTS_Fulfill_From_To_Van__c = true;
            saptype = APTS_RSOOrderUtils.getSAPOrderType(oRSOOrder);
            System.assertEquals(saptype.equalsIgnoreCase('XB03'), true);

            oRSOOrder.APTS_Order_Sub_Type__c = 'Stock Count';
            saptype = APTS_RSOOrderUtils.getSAPOrderType(oRSOOrder);
            System.assertEquals(saptype.equalsIgnoreCase('XA04'), true);

        }

        test.stopTest();
    }

    @isTest static void testValidateRSOData() {
        User oTestUser = APTS_TestFacade.getTestUser();

        Account acc = APTS_TestDataFactory.createAccount('RSO Order Test');
        insert acc;

        Apttus_Config2__AccountLocation__c loc = new Apttus_Config2__AccountLocation__c();
        loc.Apttus_Config2__AccountId__c = acc.Id;
        insert loc;

        APTS_DOEPIReqWrapper oDOEPIReqWrapper = new APTS_DOEPIReqWrapper();

        test.startTest();
        System.runAs(oTestUser) {

            String errorMsg = APTS_RSOOrderUtils.validateRSOData(oDOEPIReqWrapper);
            System.assertNotEquals(NULL, errorMsg);

            oDOEPIReqWrapper.SourceOrderNumber = 'sn1232';
            errorMsg = APTS_RSOOrderUtils.validateRSOData(oDOEPIReqWrapper);
            System.assertNotEquals(NULL, errorMsg);

            oDOEPIReqWrapper.SourceOrderNumber = 'sn1232';
            oDOEPIReqWrapper.SalesforceAccountID = acc.Id;
            errorMsg = APTS_RSOOrderUtils.validateRSOData(oDOEPIReqWrapper);
            System.assertNotEquals(NULL, errorMsg);

            oDOEPIReqWrapper.SourceOrderNumber = 'sn1232';
            oDOEPIReqWrapper.SalesforceAccountID = acc.Id;
            oDOEPIReqWrapper.SalesforceAccountLocationID = loc.Id;
            oDOEPIReqWrapper.RSOEmployeeEmail = 'testmail@gmail.com';
            errorMsg = APTS_RSOOrderUtils.validateRSOData(oDOEPIReqWrapper);
            System.assertNotEquals(NULL, errorMsg);

            oDOEPIReqWrapper.SourceOrderNumber = 'sn1232';
            oDOEPIReqWrapper.SalesforceAccountID = acc.Id;
            oDOEPIReqWrapper.SalesforceAccountLocationID = loc.Id;
            oDOEPIReqWrapper.RSOEmployeeEmail = 'testmail@gmail.com';
            oDOEPIReqWrapper.OrderType = 'Route Sales Order';
            errorMsg = APTS_RSOOrderUtils.validateRSOData(oDOEPIReqWrapper);
            System.assertNotEquals(NULL, errorMsg);

            oDOEPIReqWrapper.SourceOrderNumber = 'sn1232';
            oDOEPIReqWrapper.SalesforceAccountID = acc.Id;
            oDOEPIReqWrapper.SalesforceAccountLocationID = loc.Id;
            oDOEPIReqWrapper.RSOEmployeeEmail = 'testmail@gmail.com';
            oDOEPIReqWrapper.OrderType = 'Route Sales Order';
            oDOEPIReqWrapper.OrderSubType = 'Stock Count';
            errorMsg = APTS_RSOOrderUtils.validateRSOData(oDOEPIReqWrapper);
            System.assertNotEquals(NULL, errorMsg);

            oDOEPIReqWrapper.SourceOrderNumber = 'sn1232';
            oDOEPIReqWrapper.SalesforceAccountID = acc.Id;
            oDOEPIReqWrapper.SalesforceAccountLocationID = loc.Id;
            oDOEPIReqWrapper.RSOEmployeeEmail = 'testmail@gmail.com';
            oDOEPIReqWrapper.OrderType = 'Route Sales Order';
            oDOEPIReqWrapper.OrderSubType = 'Stock Count';
            oDOEPIReqWrapper.FulfilledFromVan = True;
            errorMsg = APTS_RSOOrderUtils.validateRSOData(oDOEPIReqWrapper);
            System.assertNotEquals(NULL, errorMsg);
        }

        test.stopTest();

    }

    @isTest static void testGetSAPNumber() {

        User oTestUser = APTS_TestFacade.getTestUser();
        oTestUser.Email = 'testmail@gmail.com';
        oTestUser.EmployeeNumber = 'TEST11233';
        Database.update(oTestUser, false);
        Account acc = APTS_TestDataFactory.createAccount('RSO Order Test');
        insert acc;

        APTS_DOEPIReqWrapper oDOEPIReqWrapper = new APTS_DOEPIReqWrapper();

        Set<String> em = new Set<String>();

        test.startTest();
        System.runAs(oTestUser) {

            oDOEPIReqWrapper.SourceOrderNumber = 'sn1232';
            oDOEPIReqWrapper.SalesforceAccountID = acc.Id;
            oDOEPIReqWrapper.RSOEmployeeEmail = 'testmail@gmail.com';
            em.add(oDOEPIReqWrapper.RSOEmployeeEmail);
            Map<String, String> sapno = APTS_RSOOrderUtils.getSAPNumber(em);
            System.assertNotEquals(NULL, sapno);
        }

        test.stopTest();
    }

    @isTest static void testGetAgreementsother() {

        User oTestUser = APTS_TestFacade.getTestUser();
        
        Account acc = APTS_TestDataFactory.createAccount('RSO Order Test');
        insert acc;

        Set<Id> accIdSet = new Set<Id>();

        test.startTest();
        System.runAs(oTestUser) {
            accIdSet.add(acc.Id);

            Map<Id, Apttus__APTS_Agreement__c> aggrmp = APTS_RSOOrderUtils.getRSOAgreement('Route Sales Order', accIdSet);
            System.assertNotEquals(NULL, aggrmp);
        }

        test.stopTest();
    }


    @isTest static void testGetPODetails() {
        User oTestUser = APTS_TestFacade.getTestUser();

        Account acc = APTS_TestDataFactory.createAccount('RSO Order Test');
        insert acc;

        Contact con = new Contact();
        con.AccountId = acc.Id;
        con.MobilePhone = '98607134761';
        con.LastName = acc.Name;
        con.Email = 'test1234@qp1.org';
        insert con;

        Apttus_Config2__PriceList__c plist = APTS_TestFacade.getPriceList();

        Apttus__APTS_Agreement__c agrr = APTS_TestDataFactory.createAgreement(con.Id, plist.Id, acc.Id, 'Standard Deal', 'Agreement');
        insert agrr;

        Set<Id> agrSet = new Set<Id>();

        test.startTest();
        System.runAs(oTestUser) {
            agrSet.add(agrr.Id);
            Map<Id, List<APTS_Agreement_PO_Details__c>> aggrmp = APTS_RSOOrderUtils.getPODetails(agrSet);
            System.assertNotEquals(NULL, aggrmp);
        }

        test.stopTest();
    }

    @isTest static void testCreateOrderHeader() {
        User oTestUser = APTS_TestFacade.getTestUser();

        Account acc = APTS_TestDataFactory.createAccount('RSO Order Test');
        insert acc;

        Contact con = new Contact();
        con.AccountId = acc.Id;
        con.MobilePhone = '98607134961';
        con.LastName = acc.Name;
        con.Email = 'test1278@qp1.org';
        insert con;

        Apttus_Config2__PriceList__c plist = APTS_TestDataFactory.createPriceList('Netherlands Standard');
        insert plist;

        Apttus__APTS_Agreement__c agrr = APTS_TestDataFactory.createAgreement(con.Id, plist.Id, acc.Id, 'Standard Deal', 'Agreement');
        insert agrr;

        APTS_DOEPIReqWrapper oDOEPIReqWrapper = new APTS_DOEPIReqWrapper();
        oDOEPIReqWrapper.SourceOrderNumber = 'sn1232';
        oDOEPIReqWrapper.SalesforceAccountID = acc.Id;
        oDOEPIReqWrapper.RSOEmployeeEmail = 'testmail@gmail.com';
        oDOEPIReqWrapper.OrderType = 'Route Sales Order';
        oDOEPIReqWrapper.OrderSubType = 'Stock Count';
        oDOEPIReqWrapper.FulfilledFromVan = True;

        Id routeSalesRecordTypeId = Schema.SObjectType.Apttus_Config2__Order__c.getRecordTypeInfosByName().get('Route Sales Order').getRecordTypeId();
        Id operatingRecordTypeId = Schema.SObjectType.Apttus_Config2__Order__c.getRecordTypeInfosByName().get('Operating Order').getRecordTypeId();

        test.startTest();
        System.runAs(oTestUser) {
            List<Apttus__APTS_Agreement__c> listAg = new List<Apttus__APTS_Agreement__c>();
            listAg.add(agrr);

            Set<Id> agrSet = new Set<Id>();
            agrSet.add(agrr.Id);
            Map<Id, List<APTS_Agreement_PO_Details__c>> aggrmp = APTS_RSOOrderUtils.getPODetails(agrSet);

            Apttus_Config2__Order__c oOrder = APTS_RSOOrderUtils.createOrderHeader(routeSalesRecordTypeId, operatingRecordTypeId, oDOEPIReqWrapper, acc, listAg, aggrmp);
            System.assertNotEquals(NULL, oOrder);
        }

        test.stopTest();
    }

    @isTest static void testContributingAgreements() {
        User oTestUser = APTS_TestFacade.getTestUser();
        Map<Id, Account> mapAccounts = new Map<Id, Account>([SELECT Id FROM Account LIMIT 1]);

        APTS_Sync_Data_Log__c oSynLog = new APTS_Sync_Data_Log__c();
        oSynLog.APTS_Date_of_Last_Sync__c = System.today() - 5;
        insert oSynLog;

        test.startTest();

        System.runAs(oTestUser) {
            Account accChild = APTS_TestDataFactory.createAccount('RSO Order Test');

            for (Id accId : mapAccounts.keySet()) {
                accChild.ParentId = accId;
                break;
            }

            insert accChild;

            Set<Id> setAccID = new Set<Id> ();
            setAccID.add(accChild.Id);
            
           /* Contact con = APTS_TestDataFactory.createContact(accChild, '+31-3000000000');
            con.Preferred_Language__c = 'SAP_EN';
            Insert con; */

            APTS_RSOOrderUtils.AccountHierarchyWrapper wrapHierarchy = APTS_RSOOrderUtils.getAccountHierarchyId(setAccID);
            System.assertNotEquals(NULL, wrapHierarchy);

            Map<Id, Apttus__APTS_Agreement__c> mapAg1 = APTS_RSOOrderUtils.getContributingAgreements('Route Sales Order', wrapHierarchy);
            System.assertNotEquals(NULL, mapAg1);
            System.assertNotEquals(NULL, mapAg1.isEmpty());

            Map<Id, List<Apttus__APTS_Agreement__c>> mapAg2 = APTS_RSOOrderUtils.getRSOAgreements(wrapHierarchy);
            System.assertNotEquals(NULL, mapAg1);
            System.assertNotEquals(NULL, mapAg1.isEmpty());

            Set<Id> setAgId = new Set<Id> ();

            for (Apttus__APTS_Agreement__c oAg : mapAg1.values()) {
                setAgId.add(oAg.Id);
            }

            APTS_RSOOrderUtils.getQueue('CS Queue');
            APTS_RSOOrderUtils.getQueue(null);
           
        }

        test.stopTest();
    }
    @isTest static void testCreateOrderHeader2() {
        User oTestUser = APTS_TestFacade.getTestUser();

        Account acc = APTS_TestDataFactory.createAccount('RSO Order Test');
        insert acc;

        Contact con = new Contact();
        con.AccountId = acc.Id;
        con.MobilePhone = '98607134961';
        con.LastName = acc.Name;
        con.Email = 'test1278@qp1.org';
        insert con;
        
        Apttus_Config2__PriceList__c plist = APTS_TestDataFactory.createPriceList('Netherlands Standard');
        insert plist;

        Apttus__APTS_Agreement__c agrr = APTS_TestDataFactory.createAgreement(con.Id, plist.Id, acc.Id, 'Standard Deal', 'Agreement');
        insert agrr;
        
        Id consumptionRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Consumption Model').getRecordTypeId();
        agrr.RecordTypeId = consumptionRecordTypeId;
        database.update(agrr, false);

        APTS_DOEPIReqWrapper oDOEPIReqWrapper = new APTS_DOEPIReqWrapper();
        oDOEPIReqWrapper.SourceOrderNumber = 'sn1232';
        oDOEPIReqWrapper.SalesforceAccountID = acc.Id;
        oDOEPIReqWrapper.RSOEmployeeEmail = 'testmail@gmail.com';
        oDOEPIReqWrapper.OrderType = 'Route Sales Order';
        oDOEPIReqWrapper.OrderSubType = 'Stock Count';
        oDOEPIReqWrapper.FulfilledFromVan = True;

        Id routeSalesRecordTypeId = Schema.SObjectType.Apttus_Config2__Order__c.getRecordTypeInfosByName().get('Route Sales Order').getRecordTypeId();
        Id operatingRecordTypeId = Schema.SObjectType.Apttus_Config2__Order__c.getRecordTypeInfosByName().get('Operating Order').getRecordTypeId();

        test.startTest();
        System.runAs(oTestUser) {
            List<Apttus__APTS_Agreement__c> listAg = new List<Apttus__APTS_Agreement__c>();
            listAg.add(agrr);

            Set<Id> agrSet = new Set<Id>();
            agrSet.add(agrr.Id);
            Map<Id, List<APTS_Agreement_PO_Details__c>> aggrmp = APTS_RSOOrderUtils.getPODetails(agrSet);

            Apttus_Config2__Order__c oOrder = APTS_RSOOrderUtils.createOrderHeader(routeSalesRecordTypeId, operatingRecordTypeId, oDOEPIReqWrapper, acc, listAg, aggrmp);
            System.assertNotEquals(NULL, oOrder);
            Set<id> setAccID = new set<id>();
            setAccID.add(acc.id);
            APTS_RSOOrderUtils.getContacts(setAccID);
        }

        test.stopTest();
    }
}