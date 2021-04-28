/**
* This Apex Class is test class for Contract Pricing which covers APTS_AdjustmentLineItemCallback.
* Created By - Ankit Shah
* Created Date - 31st Jan, 2018
*/

@isTest
public with sharing class APTS_ContractPricingTest {
    
    @testSetup
    private static void testDataSetup() {
        
        User testuser = APTS_TestUtils.createUser();
        
        System.runAs(testuser) {
            
            Apttus_Config2__ConfigCustomClasses__c configCustomClasses = APTS_TestUtils.getCustomClassSettings();
            insert configCustomClasses;

            Apttus_Config2__ConfigCustomClasses__c configCustomClassesProperty = new Apttus_Config2__ConfigCustomClasses__c();
            configCustomClassesProperty.Name = 'Config Custom Classes';
            configCustomClassesProperty.Apttus_Config2__AdjustmentLineItemCallbackClass__c = 'APTS_AdjustmentLineItemCallback';
            insert configCustomClassesProperty;

            Apttus_Config2__ConfigLineItemCustomFields__c oConfigLineItemCustomFields = new Apttus_Config2__ConfigLineItemCustomFields__c();
            oConfigLineItemCustomFields.Name = 'System Properties';
            oConfigLineItemCustomFields.Apttus_Config2__CustomFieldNames__c = 'APTS_ATP_Check_Status__c,Apttus_Config2__HasIncentives__c,Apttus_Config2__AttributeValueId__r.APTS_Type_of_contract__c,Apttus_Config2__PriceListItemId__r.APTS_Default_Selling_Uom__c,Apttus_Config2__SellingUom__c,APTS_Requested_Delivery_Date__c';
            oConfigLineItemCustomFields.Apttus_Config2__CustomFieldNames2__c = 'Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__ParentOptionGroupId__r.Apttus_Config2__Label__c, Apttus_Config2__OptionId__r.Name,Apttus_Config2__ConfigurationId__c';
            oConfigLineItemCustomFields.Apttus_Config2__CustomFieldNames3__c = 'Apttus_Config2__PriceListItemId__r.APTS_Call_Out_Coverage__c, Apttus_Config2__PriceListItemId__r.APTS_Labour_Coverage__c, Apttus_Config2__PriceListItemId__r.APTS_Spare_Parts_Coverage__c';
            oConfigLineItemCustomFields.Apttus_Config2__CustomFieldNames4__c = 'Apttus_Config2__AttributeValueId__r.APTS_Call_Out_Coverage_chk__c, Apttus_Config2__AttributeValueId__r.APTS_Labour_Coverage_chk__c, Apttus_Config2__AttributeValueId__r.APTS_Spare_Parts_Coverage_chk__c';
            insert oConfigLineItemCustomFields;

            Apttus_Config2__ConfigLineItemCustomFields__c oConfigLineItemCustomFields1 = new Apttus_Config2__ConfigLineItemCustomFields__c();
            oConfigLineItemCustomFields1.Name = 'System Properties 1';
            oConfigLineItemCustomFields1.Apttus_Config2__CustomFieldNames__c = 'Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.APTS_Is_Amended_for_Indexation__c,Apttus_Config2__ConfigurationId__r.APTS_Max_Requested_Delivery_Date__c';
            oConfigLineItemCustomFields1.Apttus_Config2__CustomFieldNames2__c = '';
            oConfigLineItemCustomFields1.Apttus_Config2__CustomFieldNames3__c = '';
            oConfigLineItemCustomFields1.Apttus_Config2__CustomFieldNames4__c = '';
            insert oConfigLineItemCustomFields1; 
            
            Contact con= APTS_TestUtils.createContact();
            insert con;
            
            Account grandParentAccount = APTS_TestUtils.createGrandParentAccount();
            insert grandParentAccount;
            
            Account parentAccount = APTS_TestUtils.createParentAccount(grandParentAccount);
            insert parentAccount;
            
            Account childAccount = APTS_TestUtils.createChildAccount(parentAccount);
            insert childAccount;
            
            Opportunity opp = APTS_TestUtils.createOpportunity(childAccount.id);
            insert opp;
            
            Product2 product =APTS_TestUtils.createProduct('Piazza DOro Estremo Bonen 1000 Gram','26940998','Espresso');
            insert product;
            
            Apttus_Config2__ClassificationName__c category = APTS_TestUtils.createCategory();
            insert category;
            
            Apttus_Config2__ClassificationHierarchy__c categoryHierarchy = APTS_TestUtils.createCategoryHierarchy(category.Id);
            insert categoryHierarchy;
            
            Apttus_Config2__ClassificationHierarchy__c subCategoryHierarchy = APTS_TestUtils.createSubCategory(category.Id, categoryHierarchy.Id);
            insert subCategoryHierarchy;
            
            Apttus_Config2__ClassificationHierarchy__c subSubCategoryHierarchy = APTS_TestUtils.createSubSubCategory(category.Id,categoryHierarchy.Id ,subCategoryHierarchy.Id);
            insert subSubCategoryHierarchy;
            
            Apttus_Config2__ProductClassification__c productClassification = APTS_TestUtils.createProductClassification(subCategoryHierarchy.Id, product.id);
            insert productClassification;
            
            Apttus_Config2__ProductClassification__c productClassification1 = APTS_TestUtils.createProductClassification(subCategoryHierarchy.Id, product.id);
            insert productClassification1;
            
            Apttus_Config2__PriceList__c priceList = APTS_TestUtils.createPriceList();
            insert priceList;
            
            Apttus_Config2__PriceListItem__c priceListItem = APTS_TestUtils.createPriceListItem(priceList.id,product.id);
            insert priceListItem;
            
            Apttus_Config2__ProductAttributeGroup__c productAttributeGroup = APTS_TestUtils.createProductAttributeGroup('Apttus_Config2__ProductAttributeValue__c');
            insert productAttributeGroup;
            
            Apttus_Config2__ProductAttribute__c productAttribute = APTS_TestUtils.createProductAttribute('Warranty__c', productAttributeGroup.Id);
            insert productAttribute;
            
            List<Apttus_Config2__PriceDimension__c> listPriceDimensions = APTS_TestUtils.createPriceDimension('priceDimension1', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'Warranty__c', productAttribute.Id);
            insert listPriceDimensions; 
            
            Apttus_Config2__PriceMatrix__c priceMatrix = APTS_TestUtils.createPriceMatrix(priceListItem.Id, listPriceDimensions[0].Id);
            insert priceMatrix;
            
            List<Apttus_Config2__PriceMatrixEntry__c> pmeList = APTS_TestUtils.createPriceMatrixEntry(priceMatrix.Id);
            insert pmeList;
            
            Apttus_Proposal__Proposal__c quote = APTS_TestUtils.getQuoteProposal(childAccount.id,opp.Id,'Proposal','Test',priceList.id);
            insert quote;
            
            Apttus_Config2__ProductConfiguration__c config = new Apttus_Config2__ProductConfiguration__c(Name='Sample',Apttus_QPConfig__Proposald__c=quote.id,Apttus_Config2__PriceListId__c=priceList.id);
            insert config;
            
            Apttus_Config2__LineItem__c lineItem = APTS_TestUtils.getConfigLineItem(config.id, null, 1, true, 2, '', product.id, false, null,product.id, null, '', 2.3, false, '', 1, priceList.id, priceListItem.Id, '', '', 'Sales Price', '',false, false, 22.00, 24.00, '', 34.00, 23.00, 33.50, '');
            insert lineItem;
            
            Apttus_Proposal__Proposal_Line_Item__c propLineItem = APTS_TestUtils.getProposalLineItem(quote.Id,lineItem.Id,priceListItem.Id,product.Id,product.Id);
            insert propLineItem;
            
            Apttus__APTS_Agreement__c agreement = APTS_TestUtils.createAgreement(con.Id,quote.Id, priceList.Id, childAccount.Id);
            insert agreement;
            
            Apttus_Config2__ProductConfiguration__c agreementCart = new Apttus_Config2__ProductConfiguration__c(Name='Sample',Apttus_CMConfig__AgreementId__c=agreement.id,Apttus_Config2__PriceListId__c=priceList.id);
            agreementCart.Apttus_Config2__BusinessObjectType__c = 'Agreement';
            insert agreementCart;
                                                
            Apttus_Config2.CPQWebService.finalizeConfiguration(agreementCart.Id);
            
            List<Apttus__AgreementLineItem__c> agreementLineItems = APTS_TestUtils.createAgreementLineItem(product.Id, agreement.Id, childAccount.Id, lineItem, priceListItem.Id,subCategoryHierarchy.Id);
            insert agreementLineItems;
            
            List<APTS_Adjustments__c> adjustmentLineItems = APTS_TestUtils.getAdjustmentLineItems(agreement.Id, categoryHierarchy.Id, subCategoryHierarchy.Id,subSubCategoryHierarchy.Id , childAccount.id, priceListItem.Id);
            insert adjustmentLineItems;
            
            Apttus_Config2__AdjustmentLineItem__c adjline = APTS_TestUtils.createadjustmentlineitems(lineItem.id);
            insert adjline;
            
            Apttus_CMConfig__AgreementAdjustmentLineItem__c  agradjline= APTS_TestUtils.createagrementadjustmentlineitem(agreementLineItems[0].id);
            insert agradjline;
            
            APTS_Contract_Entitlement_Repository__c cerrec = APTS_TestUtils.createCerrecords(agradjline.id,agreementLineItems[0].id,product.id); 
            insert cerrec;
            
            /*Apttus_Config2__Order__c orderObj =  APTS_TestUtils.createOrder(null, priceList.id , childAccount.id, null);
            insert orderObj;
            
            Apttus_Config2__ProductConfiguration__c orderCart = new Apttus_Config2__ProductConfiguration__c(Name='Sample',Apttus_Config2__OrderId__c=orderObj.id,Apttus_Config2__PriceListId__c=priceList.id);
            orderCart.Apttus_Config2__BusinessObjectType__c = 'Order';
            insert orderCart;
            
            Apttus_Config2__LineItem__c lineItem1 = APTS_TestUtils.getConfigLineItem(orderCart.id, null, 1, true, 2, '', product.id, false, null,product.id, null, '', 2.3, false, '', 1, priceList.id, priceListItem.Id, '', '', 'Sales Price', '',false, false, 22.00, 24.00, '', 34.00, 23.00, 33.50, '');
            String catString = String.valueOf(categoryHierarchy.Id);
            String subCatString = String.valueOf(subCategoryHierarchy.Id);
            String subSubCatString = String.valueOf(subSubCategoryHierarchy.Id);
            lineItem1.Apttus_Config2__ClassificationHierarchyInfo__c = 'Coffee:Id='+ catString + ' | Coffee:IncludeInTotalsView__c=true | Filter Coffee:Id='+subCatString+ '| Filter Coffee:IncludeInTotalsView__c=true | Sub Filter Coffee:Id='+subSubCatString+ '| sub Filter Coffee:IncludeInTotalsView__c=true';
            insert lineItem1;*/
            
            
            
            
        }
        
    }
        
    
    private static testMethod void testForAdjustmentLineItemCallback() {
        
        Test.startTest();
        
        Apttus__APTS_Agreement__c agreement = APTS_TestUtils.getAgreements();
        System.assertNotEquals(null, agreement.Id);
        
        agreement.Apttus__Status_Category__c = 'In Effect';
        agreement.Apttus__Status__c = 'Activated';
        agreement.Apttus__Contract_End_Date__c = Date.Today()+10;
        update agreement;        
        
        Apttus_Config2__PriceList__c priceList = APTS_TestUtils.getpricelist();
        
        Apttus_Config2__PriceListItem__c priceListItem = APTS_TestUtils.getpli(priceList.id);
        
        Account childAccount = APTS_TestUtils.getchildaccount();
        
        Product2 product = APTS_TestUtils.getProduct();
        
        Apttus_Config2__ClassificationHierarchy__c categoryHierarchy = APTS_TestUtils.getcategory();
        
        Apttus_Config2__ClassificationHierarchy__c subCategoryHierarchy = APTS_TestUtils.getsubcategory();
        
        Apttus_Config2__ClassificationHierarchy__c subSubCategoryHierarchy = APTS_TestUtils.getsubsubcategory();
        
        Apttus_Config2__Order__c orderObj =  APTS_TestUtils.createOrder(null, priceList.id , childAccount.id, null);
            insert orderObj;
            
            Apttus_Config2__ProductConfiguration__c orderCart = new Apttus_Config2__ProductConfiguration__c(Name='Sample',Apttus_Config2__OrderId__c=orderObj.id,Apttus_Config2__PriceListId__c=priceList.id);
            orderCart.Apttus_Config2__BusinessObjectType__c = 'Order';
            insert orderCart;
            
            Apttus_Config2__LineItem__c lineItem1 = APTS_TestUtils.getConfigLineItem(orderCart.id, null, 1, true, 2, '', product.id, false, null,product.id, null, '', 2.3, false, '', 1, priceList.id, priceListItem.Id, '', '', 'Sales Price', '',false, false, 22.00, 24.00, '', 34.00, 23.00, 33.50, '');
            String catString = String.valueOf(categoryHierarchy.Id);
            String subCatString = String.valueOf(subCategoryHierarchy.Id);
            String subSubCatString = String.valueOf(subSubCategoryHierarchy.Id);
            lineItem1.Apttus_Config2__ClassificationHierarchyInfo__c = 'Coffee:Id='+ catString + ' | Coffee:IncludeInTotalsView__c=true | Filter Coffee:Id='+subCatString+ '| Filter Coffee:IncludeInTotalsView__c=true | Sub Filter Coffee:Id='+subSubCatString+ '| sub Filter Coffee:IncludeInTotalsView__c=true';
            insert lineItem1;                
        
        List<Apttus_Config2__Order__c> listOrder = [SELECT Id,Apttus_CMConfig__AgreementId__c FROM Apttus_Config2__Order__c ];
        System.assertNotEquals(0, listOrder.size());
        
        List<Apttus_Config2__ProductConfiguration__c> productConfigs = [ SELECT Id FROM Apttus_Config2__ProductConfiguration__c WHERE Apttus_Config2__BusinessObjectType__c='Order' ];
        System.assertNotEquals(0, productConfigs.size());
        
        List<Apttus_Config2__LineItem__c> lineItems = APTS_TestUtils.getLineItemsFromOrderCart(productConfigs[0].Id);
        System.assertNotEquals(0, lineItems.size());
        
        Apttus_Config2.CustomClass.IAdjustmentLineItemCallback adjustmentLineItemCallback = new APTS_AdjustmentLineItemCallback();            
        Apttus_Config2.CallbackTester.testAdjustmentLineItemCallback(productConfigs[0].Id, lineItems[0], adjustmentLineItemCallback);
        
        Test.stopTest();
        
    }
    
    private static testMethod void testMethod1ForAdjustmentPage() {
        
        test.startTest();
        
        Apttus__APTS_Agreement__c agreement = APTS_TestUtils.getAgreements();
        System.assertNotEquals(null, agreement.Id);
        
        /*PageReference pageRef = Page.APTS_Adjustments;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('Mode', 'Cart');
        ApexPages.currentPage().getParameters().put('agreementId', agreement.Id);
        ApexPages.currentPage().getParameters().put('index', '0');*/
        
        /*APTS_AdjustmentsController oAdjustmentsController = new APTS_AdjustmentsController();
        
        oAdjustmentsController.addNewCategoryAdjustmentLine();
        oAdjustmentsController.addNewSubCategoryAdjustmentLine();
        oAdjustmentsController.addNewSubSubCategoryAdjustmentLine();
        oAdjustmentsController.addNewProductAdjustmentLine();
        
        oAdjustmentsController.removeCategoryAdjustmentLine();
        oAdjustmentsController.removeSubCategoryAdjustmentLine();
        oAdjustmentsController.removeSubSubCategoryAdjustmentLine();
        oAdjustmentsController.removeProductAdjustmentLine();
        
        oAdjustmentsController.addNewCategoryAdjustmentLine();
        oAdjustmentsController.addNewSubCategoryAdjustmentLine();
        oAdjustmentsController.addNewSubSubCategoryAdjustmentLine();
        oAdjustmentsController.addNewProductAdjustmentLine();
        
        oAdjustmentsController.getCategoryPicklist();
        oAdjustmentsController.getDiscountTypes();
        oAdjustmentsController.getSubTypes();
        oAdjustmentsController.getUomTypes();
        
        oAdjustmentsController.populateExistingAdjustmentLines();
        
        oAdjustmentsController.changeSubCatForLine();
        oAdjustmentsController.changeSSCSubCatForLine();
        oAdjustmentsController.changeSSCSubSubCatForLine();
        
        ApexPages.currentPage().getParameters().put('firstParam', 'Piazz');
        oAdjustmentsController.searchProducts();
        ApexPages.currentPage().getParameters().put('secondParam', '3');
        oAdjustmentsController.doSelectProduct();*/
        
        test.stopTest();
        
    }
    
    private static testMethod void testMethod2ForAdjustmentPage() {
        
        test.startTest();
        
        Apttus__APTS_Agreement__c agreement = APTS_TestUtils.getAgreements();
        System.assertNotEquals(null, agreement.Id);
        
        List<Apttus_Config2__ProductConfiguration__c> productConfigs = [    SELECT 
                                                                        Id,Apttus_CMConfig__AgreementId__c 
                                                                        FROM Apttus_Config2__ProductConfiguration__c 
                                                                        WHERE Apttus_Config2__BusinessObjectType__c='Agreement' 
                                                                        AND Apttus_CMConfig__AgreementId__c=:agreement.Id];
        
        System.assertNotEquals(0, productConfigs.size());
        
        /*PageReference pageRef = Page.APTS_Adjustments;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('Mode', 'Cart');
        ApexPages.currentPage().getParameters().put('Id', productConfigs[0].Id);
        ApexPages.currentPage().getParameters().put('index', '0');*/
        
        /*APTS_AdjustmentsController oAdjustmentsController = new APTS_AdjustmentsController();
        oAdjustmentsController.addNewCategoryAdjustmentLine();
        oAdjustmentsController.addNewSubCategoryAdjustmentLine();
        oAdjustmentsController.addNewSubSubCategoryAdjustmentLine();
        oAdjustmentsController.addNewProductAdjustmentLine();*/
        
        test.stopTest();
        
    }
    
    private static testMethod void testMethod3ForAdjustmentPage() {
        
        test.startTest();
        
        Apttus__APTS_Agreement__c agreement = APTS_TestUtils.getAgreements();
        System.assertNotEquals(null, agreement.Id);
        List<Apttus_Config2__ProductConfiguration__c> productConfigs = [    SELECT 
                                                                        Id,Apttus_CMConfig__AgreementId__c 
                                                                        FROM Apttus_Config2__ProductConfiguration__c 
                                                                        WHERE Apttus_Config2__BusinessObjectType__c='Agreement' 
                                                                        AND Apttus_CMConfig__AgreementId__c=:agreement.Id];
        
        System.assertNotEquals(0, productConfigs.size());
        
        /*PageReference pageRef = Page.APTS_Adjustments;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('Mode', 'Cart');
        ApexPages.currentPage().getParameters().put('agreementId', agreement.Id);
        ApexPages.currentPage().getParameters().put('index', '0');
        ApexPages.currentPage().getParameters().put('Id', productConfigs[0].Id);*/
        
        
        /*APTS_AdjustmentsController oAdjustmentsController = new APTS_AdjustmentsController();
        
        oAdjustmentsController.populateExistingAdjustmentLines();
        PageReference newProposalPage = oAdjustmentsController.save();
        PageReference returnToProposalPage = oAdjustmentsController.cancel();*/
        
        test.stopTest();
        
    }
    
    private static testMethod void testMethod4ForAdjustmentPage() {
        
        test.startTest();
        
        Apttus__APTS_Agreement__c agreement = APTS_TestUtils.getAgreements();
        System.assertNotEquals(null, agreement.Id);
        List<Apttus_Config2__ProductConfiguration__c> productConfigs = [    SELECT 
                                                                        Id,Apttus_CMConfig__AgreementId__c 
                                                                        FROM Apttus_Config2__ProductConfiguration__c 
                                                                        WHERE Apttus_Config2__BusinessObjectType__c='Agreement' 
                                                                        AND Apttus_CMConfig__AgreementId__c=:agreement.Id];
        
        System.assertNotEquals(0, productConfigs.size());
        
        List<APTS_Adjustments__c> adjustmentLineItems = [SELECT Id,APTS_Start_Date__c,APTS_End_Date__c FROM APTS_Adjustments__c];
        
        /*PageReference pageRef = Page.APTS_Adjustments;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('Mode', 'Cart');
        ApexPages.currentPage().getParameters().put('agreementId', agreement.Id);
        ApexPages.currentPage().getParameters().put('index', '0');
        ApexPages.currentPage().getParameters().put('Id', productConfigs[0].Id);*/
        
        
        /*APTS_AdjustmentsController oAdjustmentsController = new APTS_AdjustmentsController();
        
        oAdjustmentsController.populateExistingAdjustmentLines();
        
        PageReference newProposalPage = oAdjustmentsController.save();
        
        adjustmentLineItems[0].APTS_Start_Date__c = Date.today();
        update adjustmentLineItems[0];            
        PageReference newProposalPage1 = oAdjustmentsController.save();
        
        adjustmentLineItems[0].APTS_End_Date__c = Date.today() + 1;
        update adjustmentLineItems[0];
        PageReference newProposalPage2 = oAdjustmentsController.save();*/
        
        test.stopTest();
        
    }
    
    private static testMethod void testMethod5ForAdjustmentPage() {
        
        test.startTest();
        
        Apttus__APTS_Agreement__c agreement = APTS_TestUtils.getAgreements();
        System.assertNotEquals(null, agreement.Id);
        
       /*PageReference pageRef = Page.APTS_Adjustments;
        Test.setCurrentPage(pageRef);*/
        
        ApexPages.currentPage().getParameters().put('Mode', 'Cart');
        ApexPages.currentPage().getParameters().put('businessObjectId', agreement.Id);
        
        
        /*TS_AdjustmentsController oAdjustmentsController = new APTS_AdjustmentsController();*/
        
        test.stopTest();
        
    }

    @isTest static void testDigitalOrder(){
        Apttus__APTS_Agreement__c agreement = APTS_TestUtils.getAgreements();
        agreement.Apttus__Status_Category__c = 'In Effect';
        agreement.Apttus__Status__c = 'Activated';
        agreement.Apttus__Contract_End_Date__c = Date.Today()+10;
        update agreement;        
        
        Apttus_Config2__PriceList__c priceList = APTS_TestUtils.getpricelist();
        Apttus_Config2__PriceListItem__c priceListItem = APTS_TestUtils.getpli(priceList.id);
        Account childAccount = APTS_TestUtils.getchildaccount();
        Product2 product = APTS_TestUtils.getProduct();
        Apttus_Config2__ClassificationHierarchy__c categoryHierarchy = APTS_TestUtils.getcategory();
        Apttus_Config2__ClassificationHierarchy__c subCategoryHierarchy = APTS_TestUtils.getsubcategory();
        Apttus_Config2__ClassificationHierarchy__c subSubCategoryHierarchy = APTS_TestUtils.getsubsubcategory();

        APTS_DOEPIReqWrapper oDOEPIReqWrapper = new APTS_DOEPIReqWrapper();
        oDOEPIReqWrapper.SourceOrderNumber = 'sn12345';
        oDOEPIReqWrapper.SalesforceAccountID = childAccount.Id;
        oDOEPIReqWrapper.SalesforcePriceListID = priceListItem.Id;
        oDOEPIReqWrapper.SalesOrganization = 'SAP_0111';
        oDOEPIReqWrapper.Source = 'Digital';
        oDOEPIReqWrapper.OneTimeCustomer = 'false';
        oDOEPIReqWrapper.OrderLineItems = new List<APTS_DOEPIReqWrapper.EPIOrderLI>();
        APTS_DOEPIReqWrapper.EPIOrderLI orderLineItem = new APTS_DOEPIReqWrapper.EPIOrderLI();
        orderLineItem.ProductCode = product.productcode;
        orderLineItem.Quantity = 1;
        orderLineItem.ConfigurationType = 'Standalone';
        orderLineItem.SourceLineNumber = '1';
        orderLineItem.SellingUnitofMeasure = 'SAP_PCE';

        orderLineItem.Adjustments = new List<APTS_DOEPIReqWrapper.EPIAdjustmentLI>();
        APTS_DOEPIReqWrapper.EPIAdjustmentLI oAdjust = new APTS_DOEPIReqWrapper.EPIAdjustmentLI();
        oAdjust.IncentiveAmount = 10;
        oAdjust.SubType = 'ZP08';
        orderLineItem.Adjustments.add(oAdjust);
        oDOEPIReqWrapper.OrderLineItems.add(orderLineItem);
        
        Apttus_Config2__Order__c orderObj =  APTS_TestUtils.createOrder(null, priceList.id , childAccount.id, null);
        orderObj.APTS_Order_Type__c = ' Standard Order';
        orderObj.APTS_Order_Sub_Type__c = 'Digital Order';
        orderObj.APTS_Source_Order_Number__c = 'sn12345';
        insert orderObj;
            
        Apttus_Config2__ProductConfiguration__c orderCart = new Apttus_Config2__ProductConfiguration__c(Name='Sample',Apttus_Config2__OrderId__c=orderObj.id,Apttus_Config2__PriceListId__c=priceList.id);
        orderCart.Apttus_Config2__BusinessObjectType__c = 'Order';
        insert orderCart;
        
        Apttus_Config2__LineItem__c lineItem1 = APTS_TestUtils.getConfigLineItem(orderCart.id, null, 1, true, 2, '', product.id, false, null,product.id, null, '', 2.3, false, '', 1, priceList.id, priceListItem.Id, '', '', 'Sales Price', '',false, false, 22.00, 24.00, '', 34.00, 23.00, 33.50, '');
        String catString = String.valueOf(categoryHierarchy.Id);
        String subCatString = String.valueOf(subCategoryHierarchy.Id);
        String subSubCatString = String.valueOf(subSubCategoryHierarchy.Id);
        lineItem1.Apttus_Config2__ClassificationHierarchyInfo__c = 'Coffee:Id='+ catString + ' | Coffee:IncludeInTotalsView__c=true | Filter Coffee:Id='+subCatString+ '| Filter Coffee:IncludeInTotalsView__c=true | Sub Filter Coffee:Id='+subSubCatString+ '| sub Filter Coffee:IncludeInTotalsView__c=true';
        lineItem1.APTS_Source_Line_Number__c = '1';
        insert lineItem1;        
       
        Test.startTest();
        Apttus_Config2.CustomClass.IAdjustmentLineItemCallback adjustmentLineItemCallback = new APTS_AdjustmentLineItemCallback();
        Apttus_Config2.CallbackTester.testAdjustmentLineItemCallback(orderCart.Id, lineItem1, adjustmentLineItemCallback);
        Test.stopTest();
    }
}