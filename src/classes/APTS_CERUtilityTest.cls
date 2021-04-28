/*******************************************************************************************
Name            : APTS_CERUtilityTest
Created By      : Venky Muppalaneni
Created Date    : 03/15/2018
Description     :This Apex Class is test class for CER which covers APTS_CERUtility.
Version history :
05/31/2018: 1) Changes made by Ariel Quesada to increase code coverage and to delete dependencies from other classes
06/04/2018: 1) Additional updates to increase code coverage
Test Class      :
*********************************************************************************************/
@isTest
public class APTS_CERUtilityTest {
    APTS_CERUtility APTS_CERUtility = new APTS_CERUtility();


    /* Creation of data for test methods*/
    @testSetup
    public static void testDataSetup() {
        User testuser = APTS_TestUtils.createUser();
        System.runAs(testuser) {
            // Get Custom Class Settings
            Apttus_Config2__ConfigCustomClasses__c configCustomClasses = APTS_TestUtils.getCustomClassSettings();
            insert configCustomClasses;

            // Create a contact
            Contact con = APTS_TestUtils.createContact();
            insert con;

            // Create purchasing organization
            Account organisation = APTS_TestUtils.createBuyingGroup();
            insert organisation;

            // Create three accounts
            Account grandParentAccount = APTS_TestUtils.createGrandParentAccount();
            grandParentAccount.Purchasing_Organization__c = organisation.Id;
            grandParentAccount.Sales_Organization__c = 'SAP_0111';
            insert grandParentAccount;

            Account parentAccount = APTS_TestUtils.createParentAccount(grandParentAccount);
            parentAccount.Purchasing_Organization__c = organisation.Id;
            parentAccount.Sales_Organization__c = 'SAP_0111';
            insert parentAccount;

            Account childAccount = APTS_TestUtils.createChildAccount(parentAccount);
            childAccount.Purchasing_Organization__c = organisation.Id;
            childAccount.Sales_Organization__c = 'SAP_0111';
            childAccount.Segment__c = 'SAP_A';
            insert childAccount;

            // Create an opportunity for the child Account
            Opportunity opp = APTS_TestUtils.createOpportunity(childAccount.id);
            insert opp;

            // Create a product
            Product2 product = APTS_TestUtils.createProduct('Piazza DOro Estremo Bonen 1000 Gram', '26940998', 'Espresso');
            product.IsActive = true;
            product.APTS_Associated_Sales_Org__c ='SAP_0111';
            insert product;

            //create RSO Catalog Product
            APTS_RSO_Product_Catalog__c oRSOProduct = new APTS_RSO_Product_Catalog__c();
            oRSOProduct.APTS_Product__c = product.Id;
            oRSOProduct.APTS_Category_Text__c = 'Catagory';
            oRSOProduct.APTS_Sub_Category_Text__c = 'Sub Catagory';
            oRSOProduct.APTS_Sub_Sub_Category_Text__c = 'Sub Sub Catagory';
            insert oRSOProduct;

            // Create a product
            Product2 CatProduct = APTS_TestUtils.createProduct('Category Product', '26940900', 'Espresso');
            CatProduct.IsActive = true;
            CatProduct.APTS_Category_Adjustments_Product__c = true;
            CatProduct.APTS_Associated_Sales_Org__c ='SAP_0111';
            insert CatProduct;

            // Create category
            Apttus_Config2__ClassificationName__c category = APTS_TestUtils.createCategory();
            insert category;

            // Create category hierarchy
            Apttus_Config2__ClassificationHierarchy__c categoryHierarchy = APTS_TestUtils.createCategoryHierarchy(category.Id);
            insert categoryHierarchy;

            // Create subcategory
            Apttus_Config2__ClassificationHierarchy__c subCategoryHierarchy = APTS_TestUtils.createSubCategory(category.Id, categoryHierarchy.Id);
            insert subCategoryHierarchy;

            // Create subsubcategory
            Apttus_Config2__ClassificationHierarchy__c subSubCategoryHierarchy = APTS_TestUtils.createSubSubCategory(category.Id, categoryHierarchy.Id , subCategoryHierarchy.Id);
            insert subSubCategoryHierarchy;

            // Create product classification
            Apttus_Config2__ProductClassification__c productClassification1 = APTS_TestUtils.createProductClassification(categoryHierarchy.Id, product.id);
            insert productClassification1;
            // Create product classification
            Apttus_Config2__ProductClassification__c productClassification = APTS_TestUtils.createProductClassification(categoryHierarchy.Id, CatProduct.id);
            insert productClassification;


            // Create Price List
            Apttus_Config2__PriceList__c priceList = APTS_TestUtils.createPriceList();
            insert priceList;

            Apttus_Config2__PriceList__c CSPPriceList = APTS_TestUtils.createPriceList();
            CSPPriceList.APTS_PriceList_Type__c = 'CSP';
            CSPPriceList.Apttus_Config2__BasedOnPriceListId__c = priceList.id;
            CSPPriceList.Name= 'CSP PriceList';
            insert CSPPriceList;

            // Create price list item
            Apttus_Config2__PriceListItem__c priceListItem = APTS_TestUtils.createPriceListItem(PriceList.id, product.id);
            priceListItem.Apttus_Config2__PriceUom__c='SAP_PCE';
            priceListItem.APTS_Tax_per_UOM__c=1;
            priceListItem.APTS_Default_selling_UOM__c='SAP_PCE';
            insert priceListItem;
            Apttus_Config2__PriceListItem__c priceListItem1 = APTS_TestUtils.createPriceListItem(PriceList.id, CatProduct.id);
            priceListItem1.Apttus_Config2__PriceUom__c='SAP_PCE';
            priceListItem1.APTS_Tax_per_UOM__c=1;
            priceListItem1.APTS_Default_selling_UOM__c='SAP_PCE';
            insert priceListItem1;
            Apttus_Config2__PriceListItem__c priceListItem2 = APTS_TestUtils.createPriceListItem(CSPPriceList.id, product.id);
            priceListItem2.Apttus_Config2__PriceUom__c='SAP_PCE';
            priceListItem2.APTS_Tax_per_UOM__c=1;
            priceListItem2.APTS_Default_selling_UOM__c='SAP_PCE';
            insert priceListItem2;
            Apttus_Config2__PriceListItem__c priceListItem3 = APTS_TestUtils.createPriceListItem(CSPPriceList.id, CatProduct.id);
            priceListItem3.Apttus_Config2__PriceUom__c='SAP_PCE';
            priceListItem3.APTS_Tax_per_UOM__c=1;
            priceListItem3.APTS_Default_selling_UOM__c='SAP_PCE';
            insert priceListItem3;
            APTS_Sales_Org_Data__c   sod = new APTS_Sales_Org_Data__c (APTS_Product__c = product.id, APTS_Price_List__c = priceList.id);
            insert sod;
            APTS_Sales_Org_Data__c   sod1 = new APTS_Sales_Org_Data__c (APTS_Product__c = CatProduct.id, APTS_Price_List__c = priceList.id);
            insert sod1;

            // Create product attribute group
            Apttus_Config2__ProductAttributeGroup__c productAttributeGroup = APTS_TestUtils.createProductAttributeGroup('Apttus_Config2__ProductAttributeValue__c');
            insert productAttributeGroup;

            // Create product attribute
            Apttus_Config2__ProductAttribute__c productAttribute = APTS_TestUtils.createProductAttribute('Warranty__c', productAttributeGroup.Id);
            insert productAttribute;

            // Create Price dimensions
            List<Apttus_Config2__PriceDimension__c> listPriceDimensions = APTS_TestUtils.createPriceDimension('priceDimension1', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'Warranty__c', productAttribute.Id);
            insert listPriceDimensions;

            // Create price matrix
            Apttus_Config2__PriceMatrix__c priceMatrix = APTS_TestUtils.createPriceMatrix(priceListItem.Id, listPriceDimensions[0].Id);
            insert priceMatrix;

            // Create entry for the price matrix
            List<Apttus_Config2__PriceMatrixEntry__c> pmeList = APTS_TestUtils.createPriceMatrixEntry(priceMatrix.Id);
            insert pmeList;

            // Create the quote (for the child account)
            Apttus_Proposal__Proposal__c quoteChild = APTS_TestUtils.getQuoteProposal(childAccount.id, opp.Id, 'Proposal', 'Test', priceList.id);
            insert quoteChild;

            // Create the quote (for the child account)
            Apttus_Proposal__Proposal__c quoteParent = APTS_TestUtils.getQuoteProposal(parentAccount.id, opp.Id, 'Proposal', 'Test', priceList.id);
            insert quoteParent;

            // Create the quote (for the child account)
            Apttus_Proposal__Proposal__c quoteGrandParent = APTS_TestUtils.getQuoteProposal(GrandParentAccount.id, opp.Id, 'Proposal', 'Test', priceList.id);
            insert quoteGrandParent;

            // Create the quote (for the Purchasing Group account)
            Apttus_Proposal__Proposal__c quotePurchasing = APTS_TestUtils.getQuoteProposal(organisation.id, opp.Id, 'Proposal', 'Test', priceList.id);
            insert quotePurchasing;

            // Create and activate the agreement (for the child account)
            Apttus__APTS_Agreement__c agreementChild = APTS_TestUtils.createAgreement(con.Id, quoteChild.Id, CSPPriceList.Id, childAccount.Id);
            agreementChild.Apttus__Status__c = 'Activated';
            agreementChild.Apttus__Status_Category__c = 'In Effect';
            agreementChild.Apttus__Contract_End_Date__c = Date.newInstance(2020, 12, 12);
            agreementChild.APTS_Routesales__c = TRUE;
            insert agreementChild;
            /* agreementChild.Apttus__Status__c = 'Activated';
             update agreementChild;
             */

            
            id soldToAccountId = childAccount.id;
            APTS_GetProductsRest.GetProductReturnObject cspProd = APTS_CERUtility.getProduct(soldToAccountId);
            APTS_GetPriceRest.GetPriceReturnObject cspPrce = APTS_CERUtility.getPrice(soldToAccountId);

            agreementChild.Apttus_CMConfig__PriceListId__c =  CSPPriceList.Id;
            update agreementChild;

            APTS_GetProductsRest.GetProductReturnObject generalProd = APTS_CERUtility.getProduct(soldToAccountId);
            APTS_GetPriceRest.GetPriceReturnObject generalPrice = APTS_CERUtility.getPrice(soldToAccountId);

            // Create and activate the agreement (for the parent account)
            Apttus__APTS_Agreement__c agreementParent = APTS_TestUtils.createAgreement(con.Id, quoteParent.Id, priceList.Id, parentAccount.Id);
            agreementParent.Apttus__Status__c = 'Activated';
            agreementParent.Apttus__Status_Category__c = 'In Effect';
            agreementParent.Apttus__Contract_End_Date__c = Date.newInstance(2020, 12, 12);
            agreementParent.APTS_Routesales__c = TRUE;
            insert agreementParent;

            // Create and activate the agreement (for the grand parent account)
            Apttus__APTS_Agreement__c agreementGrandParent = APTS_TestUtils.createAgreement(con.Id, quoteGrandParent.Id, priceList.Id, grandParentAccount.Id);
            agreementGrandParent.Apttus__Status__c = 'Activated';
            agreementGrandParent.Apttus__Status_Category__c = 'In Effect';
            agreementGrandParent.Apttus__Contract_End_Date__c = Date.newInstance(2020, 12, 12);
            agreementGrandParent.APTS_Routesales__c = TRUE;
            insert agreementGrandParent;

            //Create and activate the agreement (for the Purchasing Group)
            Apttus__APTS_Agreement__c agreementPurchasing = APTS_TestUtils.createAgreement(con.Id, quotePurchasing.Id, priceList.Id, organisation.Id);
            agreementPurchasing.Apttus__Status__c = 'Activated';
            agreementPurchasing.Apttus__Status_Category__c = 'In Effect';
            agreementPurchasing.Apttus__Contract_End_Date__c = Date.newInstance(2020, 12, 12);
            insert agreementPurchasing;



            // Create the product configuration (for the child account)
            Apttus_Config2__ProductConfiguration__c configChild = new Apttus_Config2__ProductConfiguration__c(Name = 'Sample', Apttus_CMConfig__AgreementId__c = agreementChild.Id,
            Apttus_Config2__AccountId__c=childAccount.Id,
             Apttus_QPConfig__Proposald__c = quoteChild.id, Apttus_Config2__PriceListId__c = priceList.id);
            insert configChild;

            // Create the product configuration (for the parent account)
            Apttus_Config2__ProductConfiguration__c configParent = new Apttus_Config2__ProductConfiguration__c(Name = 'Sample', Apttus_CMConfig__AgreementId__c = agreementParent.Id, Apttus_QPConfig__Proposald__c = quoteParent.id, Apttus_Config2__PriceListId__c = priceList.id);
            insert configParent;

            // Create the product configuration (for the grand parent account)
            Apttus_Config2__ProductConfiguration__c configGrandParent = new Apttus_Config2__ProductConfiguration__c(Name = 'Sample', Apttus_CMConfig__AgreementId__c = agreementGrandParent.Id, Apttus_QPConfig__Proposald__c = quoteGrandParent.id, Apttus_Config2__PriceListId__c = priceList.id);
            insert configGrandParent;

            // Create the product configuration (for the purchasing group)
            Apttus_Config2__ProductConfiguration__c configPurchasing = new Apttus_Config2__ProductConfiguration__c(Name = 'Sample', Apttus_CMConfig__AgreementId__c = agreementPurchasing.Id, Apttus_QPConfig__Proposald__c = quotePurchasing.id, Apttus_Config2__PriceListId__c = priceList.id);
            insert configPurchasing;

            // Create the line item (for the child account)
            Apttus_Config2__LineItem__c lineItemChild = APTS_TestUtils.getConfigLineItem(configChild.id, null, 1,
                    true, 2, '', product.id, false, null, product.id, null, '', 2.3, false, '', 1, priceList.id, priceListItem.Id,
                    '', '', 'Sales Price', '', false, false, 22.00, 24.00, '', 34.00, 23.00, 33.50, '');
            insert lineItemChild;

            Apttus_Config2__LineItem__c lineItemChild1 = APTS_TestUtils.getConfigLineItem(configChild.id, null, 2,
                    true, 3, '', CatProduct.id, false, null, CatProduct.id, null, '', 2.3, false, '', 1, priceList.id, priceListItem.Id,
                    '', '', 'Sales Price', '', false, false, 22.00, 24.00, '', 34.00, 23.00, 33.50, '');
            insert lineItemChild1;

            Apttus_Config2__LineItem__c lineItemChild2 = APTS_TestUtils.getConfigLineItem(configChild.id, null, 3,
                    true, 4, '', product.id, false, null, product.id, null, '', 2.3, false, '', 1, priceList.id, priceListItem.Id,
                    '', '', 'Sales Price', '', false, false, 20.00, 25.00, '', 33.00, 24.00, 33.50, '');
            insert lineItemChild2;

            // Create the line item (for the parent account)
            Apttus_Config2__LineItem__c lineItemParent = APTS_TestUtils.getConfigLineItem(configParent.id, null, 1,
                    true, 2, '', product.id, false, null, product.id, null, '', 2.3, false, '', 1, priceList.id, priceListItem.Id,
                    '', '', 'Sales Price', '', false, false, 22.00, 24.00, '', 34.00, 23.00, 33.50, '');
            insert lineItemParent;

            // Create the line item (for the grand parent account)
            Apttus_Config2__LineItem__c lineItemGrandParent = APTS_TestUtils.getConfigLineItem(configGrandParent.id, null, 1,
                    true, 2, '', product.id, false, null, product.id, null, '', 2.3, false, '', 1, priceList.id, priceListItem.Id,
                    '', '', 'Sales Price', '', false, false, 22.00, 24.00, '', 34.00, 23.00, 33.50, '');
            insert lineItemGrandParent;

            // Create the proposal line item
            Apttus_Proposal__Proposal_Line_Item__c propLineItemChild = APTS_TestUtils.getProposalLineItem(quoteChild.Id, lineItemChild.Id, priceListItem.Id, product.Id, product.Id);
            insert propLineItemChild;

            propLineItemChild = APTS_TestUtils.getProposalLineItem(quoteChild.Id, lineItemChild.Id, priceListItem.Id, CatProduct.Id, CatProduct.Id);
            insert propLineItemChild;

            // Create the proposal line item
            Apttus_Proposal__Proposal_Line_Item__c propLineItemParent = APTS_TestUtils.getProposalLineItem(quoteParent.Id, lineItemParent.Id, priceListItem.Id, product.Id, product.Id);
            insert propLineItemParent;

            Apttus_Proposal__Proposal_Line_Item__c propLineItemGrandParent = APTS_TestUtils.getProposalLineItem(quoteGrandParent.Id, lineItemGrandParent.Id, priceListItem.Id, product.Id, product.Id);
            insert propLineItemGrandParent;



            Apttus_Config2__ProductConfiguration__c agreementCartChild = new Apttus_Config2__ProductConfiguration__c(Name = 'Sample', Apttus_CMConfig__AgreementId__c = agreementChild.id, Apttus_Config2__PriceListId__c = priceList.id);
            agreementCartChild.Apttus_Config2__BusinessObjectType__c = 'Agreement';
            insert agreementCartChild;

            Apttus_Config2__ProductConfiguration__c agreementCartParent = new Apttus_Config2__ProductConfiguration__c(Name = 'Sample', Apttus_CMConfig__AgreementId__c = agreementparent.id, Apttus_Config2__PriceListId__c = priceList.id);
            agreementCartParent.Apttus_Config2__BusinessObjectType__c = 'Agreement';
            insert agreementCartParent;

            Apttus_Config2__ProductConfiguration__c agreementCartGrandParent = new Apttus_Config2__ProductConfiguration__c(Name = 'Sample', Apttus_CMConfig__AgreementId__c = agreementGrandParent.id, Apttus_Config2__PriceListId__c = priceList.id);
            agreementCartGrandParent.Apttus_Config2__BusinessObjectType__c = 'Agreement';
            insert agreementCartGrandParent;

            List<Apttus__AgreementLineItem__c> agreementLineItemsChild = APTS_TestUtils.createAgreementLineItem(product.Id, agreementChild.Id, childAccount.Id, lineItemChild, priceListItem.Id, subCategoryHierarchy.Id);
            agreementLineItemsChild[0].Apttus_CMConfig__BasePriceOverride__c = 100;
            insert agreementLineItemsChild;

            agreementLineItemsChild = APTS_TestUtils.createAgreementLineItem(CatProduct.Id, agreementChild.Id, childAccount.Id, lineItemChild, priceListItem.Id, categoryHierarchy.Id);
            agreementLineItemsChild[0].Apttus_CMConfig__BasePriceOverride__c = 80;
            insert agreementLineItemsChild;

            agreementLineItemsChild = APTS_TestUtils.createAgreementLineItem(product.Id, agreementChild.Id, childAccount.Id, lineItemChild, priceListItem.Id, categoryHierarchy.Id);
            agreementLineItemsChild[0].Apttus_CMConfig__BasePriceOverride__c = 70;
            insert agreementLineItemsChild;

            List<Apttus__AgreementLineItem__c> agreementLineItemsParent = APTS_TestUtils.createAgreementLineItem(product.Id, agreementParent.Id, parentAccount.Id, lineItemParent, priceListItem.Id, subCategoryHierarchy.Id);
            agreementLineItemsParent[0].Apttus_CMConfig__BasePriceOverride__c = 100;
            insert agreementLineItemsParent;


            List<Apttus__AgreementLineItem__c> agreementLineItemsGrandParent = APTS_TestUtils.createAgreementLineItem(product.Id, agreementGrandParent.Id, grandParentAccount.Id, lineItemChild, priceListItem.Id, subCategoryHierarchy.Id);
            agreementLineItemsGrandParent[0].Apttus_CMConfig__BasePriceOverride__c = 100;
            insert agreementLineItemsGrandParent;
            List<Apttus__AgreementLineItem__c> agreementLineItemsPurchasing = APTS_TestUtils.createAgreementLineItem(product.Id, agreementPurchasing.Id, organisation.Id, lineItemChild, priceListItem.Id, subCategoryHierarchy.Id);
            insert agreementLineItemsPurchasing;

            Apttus_Config2__ProductHierarchyView__c phv = new Apttus_Config2__ProductHierarchyView__c(Apttus_Config2__PriceListId__c = priceList.id, Apttus_Config2__ProductClassificationId__c = productClassification.Id);
            phv.Apttus_Config2__ParentLevel__c = 1;
            phv.Apttus_Config2__ChildLevel__c = 2;
            phv.Apttus_Config2__HierarchyId__c = category.Id;
            insert phv;
            /*  List<APTS_Adjustments__c> adjustmentLineItems = APTS_TestUtils.getAdjustmentLineItems(agreementChild.Id, categoryHierarchy.Id, subCategoryHierarchy.Id,subSubCategoryHierarchy.Id , childAccount.id, priceListItem.Id);
             insert adjustmentLineItems;
             List<APTS_Adjustments__c> adjustmentLineItems1 = APTS_TestUtils.getAdjustmentLineItems(agreementParent.Id, categoryHierarchy.Id, subCategoryHierarchy.Id,subSubCategoryHierarchy.Id , parentAccount.id, priceListItem.Id);
             insert adjustmentLineItems1;
             List<APTS_Adjustments__c> adjustmentLineItems2 = APTS_TestUtils.getAdjustmentLineItems(agreementGrandParent.Id, categoryHierarchy.Id, subCategoryHierarchy.Id,subSubCategoryHierarchy.Id , grandParentAccount.id, priceListItem.Id);
             insert adjustmentLineItems2;
             List<APTS_Adjustments__c> adjustmentLineItems3 = APTS_TestUtils.getAdjustmentLineItems(agreementPurchasing.Id, categoryHierarchy.Id, subCategoryHierarchy.Id,subSubCategoryHierarchy.Id , organisation.id, priceListItem.Id);
             insert adjustmentLineItems3;       */

            Test.startTest();
            List<Apttus_CMConfig__AgreementAdjustmentLineItem__c> adjustmentLineItemPurchasingList = new List<Apttus_CMConfig__AgreementAdjustmentLineItem__c>();
            for (Apttus__AgreementLineItem__c lineitem : agreementLineItemsPurchasing) {
                adjustmentLineItemPurchasingList.add(APTS_TestUtils.createagrementadjustmentlineitemCER(lineitem.id));
            }
            insert adjustmentLineItemPurchasingList;

            List<Apttus_CMConfig__AgreementAdjustmentLineItem__c> adjustmentLineItemGrandParentList = new List<Apttus_CMConfig__AgreementAdjustmentLineItem__c>();
            for (Apttus__AgreementLineItem__c lineitem : agreementLineItemsGrandParent) {
                adjustmentLineItemGrandParentList.add(APTS_TestUtils.createagrementadjustmentlineitemCER(lineitem.id));
            }
            insert adjustmentLineItemGrandParentList;


            List<Apttus_CMConfig__AgreementAdjustmentLineItem__c> adjustmentLineItemParentList = new List<Apttus_CMConfig__AgreementAdjustmentLineItem__c>();
            for (Apttus__AgreementLineItem__c lineitem : agreementLineItemsParent) {
                adjustmentLineItemParentList.add(APTS_TestUtils.createagrementadjustmentlineitemCER(lineitem.id));
            }
            insert adjustmentLineItemParentList;


            List<Apttus_CMConfig__AgreementAdjustmentLineItem__c> adjustmentLineItemChildList = new List<Apttus_CMConfig__AgreementAdjustmentLineItem__c>();
            for (Apttus__AgreementLineItem__c lineitem : agreementLineItemsChild) {
                adjustmentLineItemChildList.add(APTS_TestUtils.createagrementadjustmentlineitemCER(lineitem.id));
                Apttus_CMConfig__AgreementAdjustmentLineItem__c temp = APTS_TestUtils.createagrementadjustmentlineitemCER(lineitem.id);
                temp.Apttus_CMConfig__AdjustmentType__c = 'Discount Amount';
                adjustmentLineItemChildList.add(temp);
                temp = APTS_TestUtils.createagrementadjustmentlineitemCER(lineitem.id);
                temp.Apttus_CMConfig__AdjustmentType__c = '% Markup';
                adjustmentLineItemChildList.add(temp);
                temp = APTS_TestUtils.createagrementadjustmentlineitemCER(lineitem.id);
                temp.Apttus_CMConfig__AdjustmentType__c = 'Markup Amount';
                adjustmentLineItemChildList.add(temp);
                temp = APTS_TestUtils.createagrementadjustmentlineitemCER(lineitem.id);
                temp.Apttus_CMConfig__AdjustmentType__c = 'Price Override';
                adjustmentLineItemChildList.add(temp);
            }
            insert adjustmentLineItemChildList;
            List <Apttus__APTS_Agreement__c> newstatuslist = new List <Apttus__APTS_Agreement__c> ();

            newstatuslist.clear();
            newstatuslist.add(agreementPurchasing);
            APTS_ManageCER.manageCERRecords(newstatuslist, 'Agreement', 'Update');

            newstatuslist.clear();
            newstatuslist.add(agreementGrandParent);
            APTS_ManageCER.manageCERRecords(newstatuslist, 'Agreement', 'Update');

            newstatuslist.clear();
            newstatuslist.add(agreementParent);
            APTS_ManageCER.manageCERRecords(newstatuslist, 'Agreement', 'Update');

            newstatuslist.clear();
            newstatuslist.add(agreementChild);
            APTS_ManageCER.manageCERRecords(newstatuslist, 'Agreement', 'Update');

            Test.stopTest();
        }

    }

    /**
     * This is a test method for getRecordTypeNameById
     */
    private static testMethod void test_getRecordTypeNameById() {
        Test.startTest();
        String objectName = 'Apttus__APTS_Agreement__c';
        Id strRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
        String resultGetRecordTypeNameById = APTS_CERUtility.getRecordTypeNameById(objectName, strRecordTypeId);
        System.assertNotEquals(resultGetRecordTypeNameById, null);
        String resultGetRecordTypeNameByIdEmpty = APTS_CERUtility.getRecordTypeNameById(null, null);
        System.assertEquals(resultGetRecordTypeNameByIdEmpty, '');
        Test.stopTest();
    }

    /**
     * This is a test method for getAccountHierarchy
     */
    private static testMethod void test_getAccountHierarchy() {
        Test.startTest();
        Set<Id> accounts = new Set<Id>();
        for (Account a : APTS_TestUtils.getAccounts()) {
            accounts.add(a.id);
        }
        Map<Id, APTS_CERUtility.AccountHierarchy> resultGetAccountHierarchy = APTS_CERUtility.getAccountHierarchy(accounts);
        Test.stopTest();
    }

    /**
     * This is a test method for getAccountAgreementHierarchyBottomToTop
     */
    private static testMethod void test_getAccountAgreementHierarchyBottomToTop() {
        Test.startTest();
        Set<Id> accounts = new Set<Id>();
        for (Account a : APTS_TestUtils.getAccounts()) {
            accounts.add(a.id);
        }
        APTS_CERUtility.AccountAgreementHierarchyBottomToTop aah =
            new APTS_CERUtility.AccountAgreementHierarchyBottomToTop();
        Map<Id, APTS_CERUtility.AccountAgreementHierarchyBottomToTop> resultGetAccountAgreementHierarchyBottomToTop =
            APTS_CERUtility.getAccountAgreementHierarchyBottomToTop(accounts,accounts);

        resultGetAccountAgreementHierarchyBottomToTop =
            APTS_CERUtility.getAccountAgreementHierarchyBottomToTop(null,accounts);

        Test.stopTest();
    }

    /**
     * This is a test method for getAccountAgreementHierarchyTopToBottom
     */
    private static testMethod void test_getAccountAgreementHierarchyTopToBottom() {
        Test.startTest();
        Set<Id> accountId = new Set<Id>();
        for (Account a : APTS_TestUtils.getAccounts()) {
            accountId.add(a.id);
        }
        List<APTS_CER_Transaction__c> resultGetAccountAgreementHierarchyTopToBottom = APTS_CERUtility.getAccountAgreementHierarchyTopToBottom(accountId);
        resultGetAccountAgreementHierarchyTopToBottom = APTS_CERUtility.getAccountAgreementHierarchyTopToBottom(null);
        Test.stopTest();
    }
    private static testMethod void test_getgetAccountAgreementHierarchy() {
        Test.startTest();
        Set<Id> accountId = new Set<Id>();
        for (Account a : APTS_TestUtils.getAccounts()) {
            accountId.add(a.id);
        }
        List<Apttus__APTS_Agreement__c> resultGetAccountAgreementHierarchyTopToBottom = APTS_CERUtility.getAccountAgreementHierarchy(accountId);
        resultGetAccountAgreementHierarchyTopToBottom = APTS_CERUtility.getAccountAgreementHierarchy(null);
        Test.stopTest();
    }

    /**
     * This is a test method for getContractedProductsForAgreement
     */
    private static testMethod void test_getContractedProductsForAgreement() {
        Test.startTest();
        Set<Id> agreements = new Set<Id>();
        Apttus__APTS_Agreement__c agreement = APTS_TestUtils.getAgreements();
        agreements.add(agreement.Id);
        Map<Id, Map<Id, List<APTS_CERUtility.AgreementLineItemChargeType>>> resultGetContractedProductsForAgreement = APTS_CERUtility.getContractedProductsForAgreement(agreements);
        Test.stopTest();
    }
    /**
     * This is a test method for getCerRecordAccountForRelatedAccount
     */
    static testMethod void test_getCerRecordAccountForRelatedAccount() {
        Test.startTest();

        Account a = APTS_TestUtils.getchildaccount();
        id soldToAccountId = a.id;
        boolean isPending = False;
        Id resultGetCerRecordAccountForRelatedAccount1 = APTS_CERUtility.getCerRecordAccountForRelatedAccount(soldToAccountId, isPending);
        // Id resultGetCerRecordAccountForRelatedAccount2 = APTS_CERUtility.getCerRecordAccountForRelatedAccount(soldToAccountId);
        soldToAccountId = a.ParentId;
        resultGetCerRecordAccountForRelatedAccount1 = APTS_CERUtility.getCerRecordAccountForRelatedAccount(soldToAccountId, isPending);
        //resultGetCerRecordAccountForRelatedAccount2 = APTS_CERUtility.getCerRecordAccountForRelatedAccount(soldToAccountId);
        /* soldToAccountId=a.ParentId.ParentId;
        resultGetCerRecordAccountForRelatedAccount1 = APTS_CERUtility.getCerRecordAccountForRelatedAccount(soldToAccountId,isPending);
        resultGetCerRecordAccountForRelatedAccount2 = APTS_CERUtility.getCerRecordAccountForRelatedAccount(soldToAccountId); */
        Test.stopTest();


    }
    static testMethod void test_getCategoryCerRecordAccountForRelatedAccount() {
        Test.startTest();

        Account a = APTS_TestUtils.getchildaccount();
        id soldToAccountId = a.id;
        boolean isPending = False;
        Id resultGetCerRecordAccountForRelatedAccount1 = APTS_CERUtility.getCategoryCerRecordAccountForRelatedAccount(soldToAccountId, isPending);
        // Id resultGetCerRecordAccountForRelatedAccount2 = APTS_CERUtility.getCerRecordAccountForRelatedAccount(soldToAccountId);
        soldToAccountId = a.ParentId;
        resultGetCerRecordAccountForRelatedAccount1 = APTS_CERUtility.getCategoryCerRecordAccountForRelatedAccount(soldToAccountId, isPending);
        //resultGetCerRecordAccountForRelatedAccount2 = APTS_CERUtility.getCerRecordAccountForRelatedAccount(soldToAccountId);
        /* soldToAccountId=a.ParentId.ParentId;
        resultGetCerRecordAccountForRelatedAccount1 = APTS_CERUtility.getCerRecordAccountForRelatedAccount(soldToAccountId,isPending);
        resultGetCerRecordAccountForRelatedAccount2 = APTS_CERUtility.getCerRecordAccountForRelatedAccount(soldToAccountId); */
        Test.stopTest();


    }
    /**
     * This is a test method for getContractedProductsForDigital
     */
    /*static testMethod void test_getContractedProductsRSO() {
        Test.startTest();
        Account account = APTS_TestUtils.getchildaccount();
        LIST<Id> soldToAccountId = new LIST<Id>();
        soldtoAccountId.add(account.id);
        Map<Id, List<APTS_CERUtility.ContractedProductsRSO>> resultGetContractedProductsRSO = APTS_CERUtility.getContractedProductsRSO(soldToAccountId, 'S20');
        account = APTS_TestUtils.getParentAccount();
        soldtoAccountId.add(account.id);
        resultGetContractedProductsRSO = APTS_CERUtility.getContractedProductsRSO(soldToAccountId, 'S25');
        account = APTS_TestUtils.getGrandParentAccount();
        soldtoAccountId.add(account.id);
        //resultGetContractedProductsForDigital = APTS_CERUtility.getContractedProductsForDigital(soldToAccountId,'S20');
        //      soldToAccountId = new LIST<Id>();
        //      for(Account a:APTS_TestUtils.getAccounts())
        //      {
        //          soldToAccountId.add(a.id);
        //      }
        //resultGetContractedProductsForDigital = APTS_CERUtility.getContractedProductsForDigital(soldToAccountId);
        Test.stopTest();
    }*/
    /**
     * This is a test method for getCategoryProductsWithDiscounts
     */
    static testMethod void test_getCategoryProductsWithDiscounts() {
        Test.startTest();

        // Test for the child account
        Account childAccount = APTS_TestUtils.getchildaccount();
        id soldToAccountIdChild = childAccount.id;
        Apttus__APTS_Agreement__c agreementChild = [ SELECT Id, Apttus__Account__c FROM Apttus__APTS_Agreement__c WHERE Apttus__Account__c = : childAccount.Id LIMIT 1];
        Apttus_Config2__ProductConfiguration__c cartChild = [SELECT Id, Apttus_CMConfig__AgreementId__c FROM Apttus_Config2__ProductConfiguration__c  WHERE Apttus_CMConfig__AgreementId__c = : agreementChild.Id LIMIT 1];
        Id cartIdChild = cartChild.Id;
        Map<Id, List<APTS_Contract_Entitlement_Repository__c>> resultGetContractedProductsWithDiscountsChild = APTS_CERUtility.getCategoryProductsWithDiscounts(soldToAccountIdChild, cartIdChild, true);
        APTS_CERUtility.applyBPO(cartIdChild,true);
        // Test for the parent account
        Account parentAccount = APTS_TestUtils.getParentAccount();
        id soldToAccountIdParent = parentAccount.id;
        Apttus__APTS_Agreement__c agreementParent = [ SELECT Id, Apttus__Account__c FROM Apttus__APTS_Agreement__c WHERE Apttus__Account__c = : parentAccount.Id LIMIT 1];
        Apttus_Config2__ProductConfiguration__c cartParent = [SELECT Id, Apttus_CMConfig__AgreementId__c FROM Apttus_Config2__ProductConfiguration__c  WHERE Apttus_CMConfig__AgreementId__c = : agreementParent.Id LIMIT 1];
        Id cartIdParent = cartParent.Id;
        Map<Id, List<APTS_Contract_Entitlement_Repository__c>> resultGetContractedProductsWithDiscountsParent = APTS_CERUtility.getCategoryProductsWithDiscounts(soldToAccountIdParent, cartIdParent, true);
        // Test for grand parent account
        Test.stopTest();
    }

    /**
     * This is a test method for getContractedProductsWithDiscounts
     */
    static testMethod void test_getContractedProductsWithDiscounts() {
        Test.startTest();

        // Test for the child account
        Account childAccount = APTS_TestUtils.getchildaccount();
        id soldToAccountIdChild = childAccount.id;
        Apttus__APTS_Agreement__c agreementChild = [ SELECT Id, Apttus__Account__c FROM Apttus__APTS_Agreement__c WHERE Apttus__Account__c = : childAccount.Id LIMIT 1];
        Apttus_Config2__ProductConfiguration__c cartChild = [SELECT Id, Apttus_CMConfig__AgreementId__c FROM Apttus_Config2__ProductConfiguration__c  WHERE Apttus_CMConfig__AgreementId__c = : agreementChild.Id LIMIT 1];
        Id cartIdChild = cartChild.Id;
        Map<Id, List<APTS_Contract_Entitlement_Repository__c>> resultGetContractedProductsWithDiscountsChild = APTS_CERUtility.getContractedProductsWithDiscounts(soldToAccountIdChild, cartIdChild, true);

        // Test for the parent account
        Account parentAccount = APTS_TestUtils.getParentAccount();
        id soldToAccountIdParent = parentAccount.id;
        Apttus__APTS_Agreement__c agreementParent = [ SELECT Id, Apttus__Account__c FROM Apttus__APTS_Agreement__c WHERE Apttus__Account__c = : parentAccount.Id LIMIT 1];
        Apttus_Config2__ProductConfiguration__c cartParent = [SELECT Id, Apttus_CMConfig__AgreementId__c FROM Apttus_Config2__ProductConfiguration__c  WHERE Apttus_CMConfig__AgreementId__c = : agreementParent.Id LIMIT 1];
        Id cartIdParent = cartParent.Id;
        Map<Id, List<APTS_Contract_Entitlement_Repository__c>> resultGetContractedProductsWithDiscountsParent = APTS_CERUtility.getContractedProductsWithDiscounts(soldToAccountIdParent, cartIdParent, true);
        // Test for grand parent account
        Test.stopTest();
    }
    /**
     * This is a test method for getPrice
     */
    static testMethod void test_getPrice() {
        Test.startTest();
        Account childAccount = APTS_TestUtils.getchildaccount();
        id soldToAccountId = childAccount.id;
        APTS_GetPriceRest.GetPriceReturnObject gpo = APTS_CERUtility.getPrice(soldToAccountId);
        /*  Account parentAccount =APTS_TestUtils.getParentAccount();
          soldToAccountId=parentAccount.id;
        gpo=APTS_CERUtility.getPrice(soldToAccountId);*/
        Test.stopTest();
    }
     /**
     * This is a test method for getProduct
     */
    
      static testMethod void test_getProduct() {
        Test.startTest();
           
        Account childAccount = APTS_TestUtils.getchildaccount();
        id soldToAccountId = childAccount.id;
        APTS_GetProductsRest.GetProductReturnObject gpo = APTS_CERUtility.getProduct(soldToAccountId);
           Test.stopTest();
    }
    
    static testMethod void test_getPaymentDetail() {
        Test.startTest();           
        Account childAccount = APTS_TestUtils.getchildaccount();
        id soldToAccountId = childAccount.id;
        APTS_GetPaymentdetailRest.GetPaymentdetailReturnObject gpo = APTS_CERUtility.getPaymentdetail(soldToAccountId);
           Test.stopTest();
    }
    
    static testMethod void test_getInvoiceDetail() {
        Test.startTest();           
        Account childAccount = APTS_TestUtils.getchildaccount();
        Account parentAccount = APTS_TestUtils.getParentAccount();
        childAccount.Bill_To_Payer_Account__c=parentAccount.Id;
        Update childAccount;
        id soldToAccountId = childAccount.id;
        APTS_GetInvoicedetailRest.GetInvoicedetailReturnObject gpo = APTS_CERUtility.getInvoicedetail(soldToAccountId);
        Account childAccountnew = APTS_TestUtils.getchildaccount();
        childAccountnew.Bill_To_Payer_Account__c=null;
        Update childAccountnew;
        id soldToAccountIdnew = childAccountnew.id;
        APTS_GetInvoicedetailRest.GetInvoicedetailReturnObject gponew = APTS_CERUtility.getInvoicedetail(soldToAccountIdnew);
        id soldToAccountIdnewexcpetion;
        APTS_GetInvoicedetailRest.GetInvoicedetailReturnObject gponew1 = APTS_CERUtility.getInvoicedetail(soldToAccountIdnewexcpetion);
        Test.stopTest();
    }
    
    static testMethod void test_getContractedProducts() {
        Test.startTest();
        Account childAccount = APTS_TestUtils.getchildaccount();
        id soldToAccountIdChild = childAccount.id;
        String orderType = APTS_CERUtility.STANDARD_ORDER;
        APTS_CERUtility.ContractedProducts resultGetContractedProducts = APTS_CERUtility.getContractedProducts(soldToAccountIdChild, orderType, 'Standard Deal');
        resultGetContractedProducts = APTS_CERUtility.getContractedProducts(soldToAccountIdChild, '', 'Standard Deal');
        Test.stopTest();

        // Check
        // System.assert(ApexPages.hasMessages());
        // for(ApexPages.Message msg : ApexPages.getMessages()) {
        //     System.assertEquals('Upload file is NULL', msg.getSummary());
        //     System.assertEquals(ApexPages.Severity.ERROR, msg.getSeverity());
        // }
    }

    /**
     * This is a test method for getCategoryProducts
     */
    static testMethod void test_getCategoryProducts() {
        Test.startTest();
        Id soldToAccountId = null;
        Id productId = null;
        String categoryLevel = 'Ol8EgtC';
        Id category = null;
        Id subCategory = null;
        Id subSubCategory = null;
        List<APTS_Contract_Entitlement_Repository__c> resultGetCategoryProducts = APTS_CERUtility.getCategoryProducts(soldToAccountId, productId, categoryLevel, category, subCategory, subSubCategory);
        Apttus_Config2__ClassificationHierarchy__c categoryRecord = [Select Id FROM Apttus_Config2__ClassificationHierarchy__c WHERE    Apttus_Config2__Level__c = 1 LIMIT 1];
        Id categoryDummy = categoryRecord.Id;
        List<APTS_Contract_Entitlement_Repository__c> resultGetCategoryProductsDummy1 = APTS_CERUtility.getCategoryProducts(soldToAccountId, productId, categoryLevel, categoryDummy, null, null);
        List<APTS_Contract_Entitlement_Repository__c> resultGetCategoryProductsDummy2 = APTS_CERUtility.getCategoryProducts(soldToAccountId, productId, categoryLevel, null, categoryDummy, null);
        List<APTS_Contract_Entitlement_Repository__c> resultGetCategoryProductsDummy3 = APTS_CERUtility.getCategoryProducts(soldToAccountId, productId, categoryLevel, null, null, categoryDummy);

        Test.stopTest();

    }


    /**
     * This is a test method for getAllCategoryProducts
     */
    static testMethod void test_getAllCategoryProducts() {

        Test.startTest();
        Id soldToAccountId = null;
        Id productId = null;
        List<APTS_Contract_Entitlement_Repository__c> resultGetAllCategoryProducts = APTS_CERUtility.getAllCategoryProducts(soldToAccountId, productId);
        Test.stopTest();
    }


    /**
     * This is a test method for getPrice
     */
    /* private static testMethod void test_getPrice()
        {
            Test.startTest();
            Id soldToPartyId = null;
            APTS_CERUtility.getPrice(soldToPartyId);
            Test.stopTest();
        } */

    /**
     * This is a test method for all
     */
    private static testMethod void test_all() {
        Test.startTest();
        String objectName = 'kpqh5ZC';
        //  test getingredientsList
        APTS_CERUtility.ContractedProducts tcp = new APTS_CERUtility.ContractedProducts();
        tcp.getingredientsList();
        tcp.getmachinesList();

        List<APTS_CERUtility.Ingredient> resultGetingredientsList = new  List<APTS_CERUtility.Ingredient>();
        APTS_CERUtility.Ingredient tl = new APTS_CERUtility.Ingredient();
        tl.categoryID = null;
        tl.categoryName   = '';

        List<APTS_CERUtility.Machine> resultMachineList = new  List<APTS_CERUtility.Machine>();
        APTS_CERUtility.Machine tm = new APTS_CERUtility.Machine();
        tm.productID = null;
        tm.getoptions();
        tm.getparentBundle();
        APTS_CERUtility.ParentBundle tpb = new APTS_CERUtility.ParentBundle();
        tpb.productID = null;
        tpb.productName = '';
        tpb.chargeType = '';
        tpb.attributeId = null;
        tpb.agreementLineItem = null;
        tpb.isNonSalesOrg =true;
        APTS_CERUtility.Options to = new APTS_CERUtility.Options();
        to.optionID = null;
        to.optionName = '';
        to.optionComponentId = null;
        to.chargeType = '';
        to.attributeId = null;
        to.agreementLineItem = null;
        to.isNonSalesOrg =true;
        //  test getsubCategories
        List<APTS_CERUtility.SubCategory> resultGetsubCategories = new  List<APTS_CERUtility.SubCategory>();
        APTS_CERUtility.SubCategory tsc = new APTS_CERUtility.SubCategory();
        tsc.subCategoryID = null;
        tsc.subCategoryName  = '';
        //  test getsubSubCategories
        List<APTS_CERUtility.SubSubCategory> resultGetsubSubCategories = new  List<APTS_CERUtility.SubSubCategory>();
        APTS_CERUtility.SubSubCategory tssc = new APTS_CERUtility.SubSubCategory();
        tssc.subSubCategoryID = null;
        tssc.subSubCategoryName = '';

        //  test getproducts
        List<APTS_CERUtility.Product> resultGetproducts = new  List<APTS_CERUtility.Product>();
        APTS_CERUtility.Product tp = new APTS_CERUtility.Product();
        tp.productId = null;
        tp.productName  = '';
        tp.sellingUOM  = '';
        tp.selected  = false;
        tp.productInCart  = false;
        tp.agreementLineItem   = null;
        tp.isNonSalesOrg =true;
        resultGetproducts.add(tp);
        tssc.products.add(tp);
        tssc.getproducts();
        tsc.subSubCategories.add(tssc);
        tsc.products.add(tp);
        tsc.getproducts();
        tsc.getsubSubCategories();
        tl.subCategories .add(tsc);
        tl.products.add(tp);
        tl.getsubCategories();

        Id strRecordTypeId = null;
        //  test getRecordTypeNameById
        String resultGetRecordTypeNameById = APTS_CERUtility.getRecordTypeNameById(objectName, strRecordTypeId);
        Set<Id> accounts =  null;
        //  test getAccountHierarchy
        Map<Id, APTS_CERUtility.AccountHierarchy> resultGetAccountHierarchy = APTS_CERUtility.getAccountHierarchy(accounts);
        //  test getAccountAgreementHierarchyBottomToTop
        Map<Id, APTS_CERUtility.AccountAgreementHierarchyBottomToTop> resultGetAccountAgreementHierarchyBottomToTop = APTS_CERUtility.getAccountAgreementHierarchyBottomToTop(accounts,accounts);
        Set<Id> accountId = null;
        //  test getAccountAgreementHierarchyTopToBottom
        List<APTS_CER_Transaction__c> resultGetAccountAgreementHierarchyTopToBottom = APTS_CERUtility.getAccountAgreementHierarchyTopToBottom(accountId);
        Set<Id> agreements = null;
        //  test getContractedProductsForAgreement
        Map<Id, Map<Id, List<APTS_CERUtility.AgreementLineItemChargeType>>> resultGetContractedProductsForAgreement = APTS_CERUtility.getContractedProductsForAgreement(agreements);
        //Id soldToPartyId = null;
        //  test getPrice
        //APTS_CERUtility.getPrice(soldToPartyId);
        Id soldToAccountId = null;
        //  test getContractedProductsWithDiscounts

        List<APTS_Contract_Entitlement_Repository__c> resultGetContractedProductsWithDiscounts = APTS_CERUtility.getContractedProductsWithDiscounts(soldToAccountId);
        Test.stopTest();

    }

}