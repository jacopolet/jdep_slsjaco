@isTest
public class APTS_CreateRSOOrderControllerTest {

    @testSetup static void setupTestData() {

        User oTestUser = APTS_TestFacade.createTestUser();

        System.runAs(oTestUser) {

            Group queue = new Group();
            queue.name = System.Label.APTS_CS_Queue;
            queue.Type = 'Queue';
            insert queue;

            Account acc = APTS_TestDataFactory.createAccount('RSO Order Test');
            insert acc;

            Apttus_Config2__AccountLocation__c loc = new Apttus_Config2__AccountLocation__c();
            loc.Apttus_Config2__AccountId__c = acc.Id;
            loc.Account_Location_Status__c  = 'Valid';
            insert loc;

            Contact con = APTS_TestDataFactory.createContact(acc, '+31-3000000000');
            con.Preferred_Language__c = 'SAP_EN';
            Insert con;

            Case cse = TS_TestDataFactory.createFieldServiceCase();
            cse.ContactId = con.Id;
            insert cse;

            Apttus_Config2__PriceList__c plist = APTS_TestDataFactory.createPriceList('Netherlands Standard');
            insert plist;

            Product2 prod = APTS_TestDataFactory.createProduct('test rso ', '08111', 'Ingrident', 'Standalone', FALSE, FALSE);
            prod.APTS_Option_Group_Indicator__c = 'Full Operating';
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

            APTS_RSO_Product_Catalog__c oRSOCatalog = new APTS_RSO_Product_Catalog__c();
            oRSOCatalog.APTS_Product__c = prod.Id;
            oRSOCatalog.APTS_Type__c = 'Operating';
            oRSOCatalog.APTS_Region__c  = 'SAP_0111';
            oRSOCatalog.APTS_Category_Text__c  = category.name;
            oRSOCatalog.APTS_Sub_Category_Text__c  = subcategory.name;
            oRSOCatalog.APTS_Sub_Sub_Category_Text__c  = ssubcategory.name;
            insert oRSOCatalog;


            Apttus__APTS_Agreement__c agr = APTS_TestDataFactory.createAgreement(con.Id, plist.Id, acc.Id, 'Consumption Model');
            agr.Apttus_CMConfig__LocationId__c = loc.Id;
            agr.APTS_Location__c  = loc.Id;
            agr.Apttus__Status_Category__c = 'In Effect';
            agr.Apttus__Status__c = 'Activated';
            agr.APTS_Sold_To__c = acc.Id;
            agr.Apttus__Contract_End_Date__c = System.today().addYears(1);
            insert agr;

            Apttus_Config2__ProductConfiguration__c oConfig = APTS_TestDataFactory.createProductConfig(agr);
            oConfig.Apttus_Config2__Status__c = 'Finalized';
            Database.insert(oConfig);

            Apttus_Config2__LineItem__c oLineItem = APTS_TestDataFactory.createLineItem(oConfig, plistItem.Id, NULL, prod.Id, NULL, NULL, 1, 1, 2, 'Product/Service', NULL, 'Monthly', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 100, 2);
            oLineItem.Apttus_Config2__PricingStatus__c = 'Completed';
            oLineItem.Apttus_Config2__ClassificationHierarchy__c = 'Coffee';
            Database.insert(oLineItem);

            Apttus_Config2__AdjustmentLineItem__c adjustlineItem = new Apttus_Config2__AdjustmentLineItem__c ();
            adjustlineItem.Apttus_Config2__LineNumber__c = 12345;
            adjustlineItem.Apttus_Config2__LineItemId__c = oLineItem.id;
            adjustlineItem.Apttus_Config2__Type__c = 'YOCI';
            adjustlineItem.Apttus_Config2__SubType__c = 'YOCI';
            adjustlineItem.Apttus_Config2__AdjustmentAmount__c = 100;
            Database.insert(adjustlineItem);

            Apttus__AgreementLineItem__c agLine = APTS_TestDataFactory.createAgreementLineItem(prod.Id, agr.Id, acc.Id, plistItem.Id);
            agLine.Apttus_CMConfig__DerivedFromId__c = oLineItem.Id;
            agLine.Apttus_CMConfig__HasOptions__c  = false;
            agLine.Apttus_CMConfig__IsPrimaryLine__c  = true;
            insert agLine;

            Apttus__AgreementLineItem__c catagLine = APTS_TestDataFactory.createAgreementLineItem(CatProduct.Id, agr.Id, acc.Id, priceListItem1.Id);
            catagLine.Apttus_CMConfig__HasOptions__c  = false;
            catagLine.Apttus_CMConfig__IsPrimaryLine__c  = true;
            insert catagLine;

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
            oCERRecord.APTS_Agreement_Type__c = 'Consumption Model';
            oCERRecord.APTS_Is_Pending__c = FALSE;
            insert oCERRecord;


            APTS_Contract_Entitlement_Repository__c oCERRecord1 = new APTS_Contract_Entitlement_Repository__c();
            oCERRecord1.APTS_Sold_to_Party__c = acc.Id;
            oCERRecord1.APTS_Product__c = CatProduct.Id;
            oCERRecord1.APTS_Contributing_Agreement__c = agr.Id;
            oCERRecord1.APTS_Agreement_Line_Item__c = catagLine.Id;
            oCERRecord1.APTS_Contributing_Agreement_Level__c = 'Child';
            oCERRecord1.APTS_Agreement_Type__c = 'Consumption Model';
            oCERRecord1.APTS_Is_Pending__c = FALSE;
            oCERRecord1.APTS_Type__c = 'Consignment';
            oCERRecord1.APTS_Sub_Type__c = 'Consignment Ingredients';
            oCERRecord1.APTS_Adjustment_Type__c = '% Discount';
            oCERRecord1.APTS_Adjustment_Value__c = 100;
            insert oCERRecord1;

            Resource__c testResource = TS_TestDataFactory.createResourceSingle('TestRSONumber');
            testResource.EmailAddress__c = 'testRSO@JDECoffee.com';
            insert testResource;

            WorkOrder parentWO = TS_TestDataFactory.createWorkOrder();
            parentWO.ContactId = con.Id;
            parentWO.CaseId = cse.Id;
            parentWO.WorkOrderType__c = Label.TS_Case_SubType_CorrectMaint;
            insert parentWO;

            WorkOrderLineItem woliParent = TS_TestDataFactory.createWorkOrderLineItem(parentWO.Id);
            woliParent.ExecutingEngineer__c = testResource.Id;
            woliParent.Status = 'Dispatched';
            woliParent.InternalOrderSAP__c = '123';
            woliParent.WorkOrderLineItemType__c = Label.TS_Type_Task;
            woliParent.Case__c = cse.Id;
            woliParent.WorkOrderId = parentWO.Id;
            woliParent.StartDate__c = system.today();
            woliParent.WorkOrderType__c = 'S25';
            woliParent.AccountLocation__c = loc.Id;
            insert woliParent;

            PhysicalAsset__c oPhyAss = new PhysicalAsset__c();
            oPhyAss.name = 'testPhyAss';
            oPhyAss.SerialNumber__c = 'testPhyAss';
            oPhyAss.Product__c = prod.Id;
            oPhyAss.AccountLocation__c = loc.Id;
            insert oPhyAss;
        }
    }

    @isTest static void testBack() {

        User oTestUser = APTS_TestFacade.getTestUser();

        System.runAs(oTestUser) {

            Account oAcc = [SELECT ID FROM Account LIMIT 1];

            test.startTest();

            //  System.runAs(oTestUser) {
            ApexPages.currentPage().getParameters().put('id', oAcc.Id);
            APTS_CreateRSOOrderController oController = new APTS_CreateRSOOrderController();
            oController.prepareData();
            oController.back();
            APTS_CreateRSOOrderController.ConsignmentProductsWrapper cpw = new APTS_CreateRSOOrderController.ConsignmentProductsWrapper();
            oController.selectAgreement();
            try{
                APTS_CreateRSOOrderController.getSellingUOM('dummy');
                oController.getLineItem(null);
            }catch(exception ex){
            }
                test.stopTest();
        }
    }

    @isTest static void testCreateOrderRSO() {

        User oTestUser = APTS_TestFacade.getTestUser();

        System.runAs(oTestUser) {

            Account oAcc = [SELECT ID FROM Account LIMIT 1];

            test.startTest();

            // System.runAs(oTestUser) {
            PageReference pageRef = Page.APTS_CreateRSOOrder;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('id', oAcc.Id);
            ApexPages.currentPage().getParameters().put('type', 'Route');
            APTS_CreateRSOOrderController oController = new APTS_CreateRSOOrderController();
            oController.prepareData();
            oController.oRSOOrder.APTS_Order_Sub_Type__c = 'Standard Order';
            oController.createOrder();
            // }

            test.stopTest();
        }
    }


    @isTest static void testCreateOrderOperating() {

        User oTestUser = APTS_TestFacade.getTestUser();

        System.runAs(oTestUser) {

            Apttus_Config2__AccountLocation__c oAccLoc = [SELECT ID FROM Apttus_Config2__AccountLocation__c LIMIT 1];
            Account oAcc = [SELECT ID FROM Account LIMIT 1];
            system.debug('oAcc = ' + oAcc);
            test.startTest();

            //  System.runAs(oTestUser) {
            PageReference pageRef = Page.APTS_CreateRSOOrder;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('id', oAcc.Id);
            ApexPages.currentPage().getParameters().put('locId', oAccLoc.Id);
            ApexPages.currentPage().getParameters().put('type', 'Operating');
            APTS_CreateRSOOrderController oController = new APTS_CreateRSOOrderController();
            oController.prepareData();
            if (oController != NULL) {
                oController.sProductName = 'test';
                oController.filterProducts();
                oController.resetSearch();


                oController.oRSOOrder.APTS_Order_Sub_Type__c = 'Stock Count';
                oController.setOrderSubType();
                if (oController.listConsignmentProds != null && !oController.listConsignmentProds.isEmpty()) {
                    oController.listConsignmentProds[0].isSelected = true;
                    oController.listConsignmentProds[0].quantity = 1;
                }
                oController.createOrder();

                oController.oRSOOrder.APTS_Order_Sub_Type__c = 'Standard Order';
                oController.setOrderSubType();
            }
            //  }

            test.stopTest();
        }
    }
    @isTest static void testCreateOrderAccountHierarchy() {

        User oTestUser = APTS_TestFacade.getTestUser();

        System.runAs(oTestUser) {

            Account oAcc = [SELECT ID,parentID,parent.parentID FROM Account  LIMIT 1];
            
            Account acc2 = APTS_TestDataFactory.createAccount('RSO Order GP');
            insert acc2;
            
            Account acc1 = APTS_TestDataFactory.createAccount('RSO Order Parent');
            acc1.parentID = acc2.id;
            insert acc1;
            
            oacc.parentID = acc1.id;
            update oacc;

            test.startTest();

            // System.runAs(oTestUser) {
            PageReference pageRef = Page.APTS_CreateRSOOrder;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('id', oAcc.Id);
            ApexPages.currentPage().getParameters().put('type', 'Route');
            APTS_CreateRSOOrderController oController = new APTS_CreateRSOOrderController();
            oController.prepareData();
            oController.oRSOOrder.APTS_Order_Sub_Type__c = 'Standard Order';
            oController.createOrder();
            Account oAccount = APTS_TestFacade.getAccount('RSO Order Test');
            Apttus__APTS_Agreement__c oAgreement = APTS_TestFacade.getAgreement('Agreement');
            Apttus_Config2__Order__c oRSOOrder = new Apttus_Config2__Order__c();
            oRSOOrder.APTS_Order_Type__c = 'Route Sales Order';
            oRSOOrder.APTS_Order_Sub_Type__c = 'Standard Order';
            oController.setOrderHeaderFields(oAccount,oAgreement,oRSOOrder);

            // }

            test.stopTest();
        }
    }
     @isTest static void testCoverException() {

        User oTestUser = APTS_TestFacade.getTestUser();

        System.runAs(oTestUser) {

            test.startTest();
            PageReference pageRef = Page.APTS_CreateRSOOrder;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('id', '123');
            APTS_CreateRSOOrderController oController = new APTS_CreateRSOOrderController();
            oController.selectAgreement();
            oController.setOrderSubType();
            test.stopTest();
            
        }
    }
}