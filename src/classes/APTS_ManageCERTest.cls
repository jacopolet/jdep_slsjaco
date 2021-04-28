/*******************************************************************************************
  Name            : APTS_ManageCERTest
  Created By      : Venky Muppalaneni
  Created Date    : 03/15/2018
  Description     :This Apex Class is test class for CER which covers APTS_ManageCER.
  06/04/2018: Updates from Ariel Quesada to increase code coverage
  Version history : 
  Test Class      : 
  *********************************************************************************************/
@isTest
private class APTS_ManageCERTest {

	@testSetup
	private static void testDataSetup()
	{
		User testuser = APTS_TestUtils.createUser();
		System.runAs(testuser)
		{
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
			insert grandParentAccount;

			Account parentAccount = APTS_TestUtils.createParentAccount(grandParentAccount);
			parentAccount.Purchasing_Organization__c = organisation.Id;
			insert parentAccount;

			Account childAccount = APTS_TestUtils.createChildAccount(parentAccount);
			childAccount.Purchasing_Organization__c = organisation.Id;
			insert childAccount;

			// Create an opportunity for the child Account
			Opportunity opp = APTS_TestUtils.createOpportunity(childAccount.id);
			insert opp;

			// Create products for the different combination
			// Product 1 (for the child agreement)
			Product2 productChild = APTS_TestUtils.createProduct('Child product', '1', 'Espresso');
			insert productChild;

			// Product 2 (for the parent agreement)
			Product2 productParent = APTS_TestUtils.createProduct('Parent product', '2', 'Coffee');
			insert productParent;

			// Product 3 (for the grand parent agreement)
			Product2 productGrandParent = APTS_TestUtils.createProduct('Grand Parent product', '3', 'Espresso');
			insert productGrandParent;

			// Product 4 (for the purchasing agreement)
			Product2 productPurchasing = APTS_TestUtils.createProduct('Purchasing product', '4', 'Coffee');
			insert productPurchasing;

			// Product 5 (for child and parent)
			Product2 productChildParent = APTS_TestUtils.createProduct('Child and Parent product', '5', 'Espresso');
			insert productChildParent;

			Product2 productChildGrandParent = APTS_TestUtils.createProduct('Child and Grand Parent product', '5', 'Espresso');
			insert productChildGrandParent;

			// Create category
			Apttus_Config2__ClassificationName__c category = APTS_TestUtils.createCategory();
			insert category;

			// Create category hierarchy
			Apttus_Config2__ClassificationHierarchy__c categoryHierarchy =
			APTS_TestUtils.createCategoryHierarchy(category.Id);
			insert categoryHierarchy;

			// Create subcategory
			Apttus_Config2__ClassificationHierarchy__c subCategoryHierarchy =
			APTS_TestUtils.createSubCategory(category.Id, categoryHierarchy.Id);
			insert subCategoryHierarchy;

			// Create subsubcategory
			Apttus_Config2__ClassificationHierarchy__c subSubCategoryHierarchy =
			APTS_TestUtils.createSubSubCategory(category.Id, categoryHierarchy.Id, subCategoryHierarchy.Id);
			insert subSubCategoryHierarchy;

			// Create product classification
			Apttus_Config2__ProductClassification__c productClassification =
			APTS_TestUtils.createProductClassification(subCategoryHierarchy.Id, productChild.id);
			insert productClassification;

			// Create Price List                        
			Apttus_Config2__PriceList__c priceList = APTS_TestUtils.createPriceList();
			insert priceList;

			// Create price list item
			Apttus_Config2__PriceListItem__c priceListItem;
			priceListItem = APTS_TestUtils.createPriceListItem(priceList.id, productChild.id);
			insert priceListItem;
			priceListItem = APTS_TestUtils.createPriceListItem(priceList.id, productParent.id);
			insert priceListItem;
			priceListItem = APTS_TestUtils.createPriceListItem(priceList.id, productGrandParent.id);
			insert priceListItem;
			priceListItem = APTS_TestUtils.createPriceListItem(priceList.id, productPurchasing.id);
			insert priceListItem;
			priceListItem = APTS_TestUtils.createPriceListItem(priceList.id, productChildParent.id);
			insert priceListItem;
			priceListItem = APTS_TestUtils.createPriceListItem(priceList.id, productChildGrandParent.id);
			insert priceListItem;
			
			// Create product attribute group
			Apttus_Config2__ProductAttributeGroup__c productAttributeGroup =
			APTS_TestUtils.createProductAttributeGroup('Apttus_Config2__ProductAttributeValue__c');
			insert productAttributeGroup;

			// Create product attribute
			Apttus_Config2__ProductAttribute__c productAttribute =
			APTS_TestUtils.createProductAttribute('Warranty__c', productAttributeGroup.Id);
			insert productAttribute;

			// Create Price dimensions
			List<Apttus_Config2__PriceDimension__c> listPriceDimensions =
			APTS_TestUtils.createPriceDimension('priceDimension1', 'Product Attribute',
			                                    'Apttus_Config2__ProductAttributeValue__c', 'Warranty__c', productAttribute.Id);
			insert listPriceDimensions;

			// Create price matrix
			Apttus_Config2__PriceMatrix__c priceMatrix =
			APTS_TestUtils.createPriceMatrix(priceListItem.Id, listPriceDimensions[0].Id);
			insert priceMatrix;

			// Create entry for the price matrix
			List<Apttus_Config2__PriceMatrixEntry__c> pmeList =
			APTS_TestUtils.createPriceMatrixEntry(priceMatrix.Id);
			insert pmeList;

			// Create the quote (for the child account)
			Apttus_Proposal__Proposal__c quoteChild =
			APTS_TestUtils.getQuoteProposal(childAccount.id, opp.Id, 'Proposal', 'Test', priceList.id);
			insert quoteChild;

			// Create the quote (for the parent account)
			Apttus_Proposal__Proposal__c quoteParent =
			APTS_TestUtils.getQuoteProposal(parentAccount.id, opp.Id, 'Proposal', 'Test', priceList.id);
			insert quoteParent;

			// Create the quote (for the grand parent account)
			Apttus_Proposal__Proposal__c quoteGrandParent =
			APTS_TestUtils.getQuoteProposal(GrandParentAccount.id, opp.Id, 'Proposal', 'Test', priceList.id);
			insert quoteGrandParent;

			// Create the quote (for the Purchasing Group account)
			Apttus_Proposal__Proposal__c quotePurchasing =
			APTS_TestUtils.getQuoteProposal(organisation.id, opp.Id, 'Proposal', 'Test', priceList.id);
			insert quotePurchasing;

			// Create the product configuration (for the child account)
			Apttus_Config2__ProductConfiguration__c configChild =
			new Apttus_Config2__ProductConfiguration__c(Name = 'Sample',
			                                            Apttus_QPConfig__Proposald__c = quoteChild.id, Apttus_Config2__PriceListId__c = priceList.id);
			insert configChild;

			// Create the product configuration (for the parent account)
			Apttus_Config2__ProductConfiguration__c configParent =
			new Apttus_Config2__ProductConfiguration__c(Name = 'Sample',
			                                            Apttus_QPConfig__Proposald__c = quoteParent.id, Apttus_Config2__PriceListId__c = priceList.id);
			insert configParent;

			// Create the product configuration (for the grand parent account)
			Apttus_Config2__ProductConfiguration__c configGrandParent =
			new Apttus_Config2__ProductConfiguration__c(Name = 'Sample',
			                                            Apttus_QPConfig__Proposald__c = quoteGrandParent.id, Apttus_Config2__PriceListId__c = priceList.id);
			insert configGrandParent;

			// Create the product configuration (for the purchasing group)
			Apttus_Config2__ProductConfiguration__c configPurchasing =
			new Apttus_Config2__ProductConfiguration__c(Name = 'Sample',
			                                            Apttus_QPConfig__Proposald__c = quotePurchasing.id, Apttus_Config2__PriceListId__c = priceList.id);
			insert configPurchasing;

			// Create the line item (for the child account)
			Apttus_Config2__LineItem__c lineItemChild = APTS_TestUtils.getConfigLineItem(configChild.id, null, 1,
			                                                                             true, 2, '', productChild.id, false, null, productChild.id, null, '', 2.3, false, '', 1,
			                                                                             priceList.id, priceListItem.Id, '', '', 'Sales Price', '', false, false, 22.00, 24.00, '', 34.00, 23.00, 33.50, '');
			insert lineItemChild;
			Apttus_Config2__LineItem__c lineItemChildParentInChild = APTS_TestUtils.getConfigLineItem(configChild.id, null, 1,
			                                                                                          true, 2, '', productChildParent.id, false, null, productChildParent.id, null, '', 2.3, false, '', 1,
			                                                                                          priceList.id, priceListItem.Id, '', '', 'Sales Price', '', false, false, 22.00, 24.00, '', 34.00, 23.00, 33.50, '');
			insert lineItemChildParentInChild;

			// Create the line item (for the parent account)
			Apttus_Config2__LineItem__c lineItemParent = APTS_TestUtils.getConfigLineItem(configParent.id, null, 1,
			                                                                              true, 2, '', productParent.id, false, null, productParent.id, null, '', 2.3, false, '', 1,
			                                                                              priceList.id, priceListItem.Id, '', '', 'Sales Price', '', false, false, 22.00, 24.00, '', 34.00, 23.00, 33.50, '');
			insert lineItemParent;
			Apttus_Config2__LineItem__c lineItemChildParentInParent = APTS_TestUtils.getConfigLineItem(configParent.id, null, 1,
			                                                                                           true, 2, '', productChildParent.id, false, null, productChildParent.id, null, '', 2.3, false, '', 1,
			                                                                                           priceList.id, priceListItem.Id, '', '', 'Sales Price', '', false, false, 22.00, 24.00, '', 34.00, 23.00, 33.50, '');
			insert lineItemChildParentInParent;

			// Create the line item (for the grand parent account)
			Apttus_Config2__LineItem__c lineItemGrandParent = APTS_TestUtils.getConfigLineItem(configGrandParent.id, null, 1,
			                                                                                   true, 2, '', productGrandParent.id, false, null, productGrandParent.id, null, '', 2.3, false, '', 1,
			                                                                                   priceList.id, priceListItem.Id, '', '', 'Sales Price', '', false, false, 22.00, 24.00, '', 34.00, 23.00, 33.50, '');
			insert lineItemGrandParent;

			// Create the line item (for the grand parent account)
			Apttus_Config2__LineItem__c lineItemPurchasing = APTS_TestUtils.getConfigLineItem(configPurchasing.id, null, 1,
			                                                                                  true, 2, '', productPurchasing.id, false, null, productPurchasing.id, null, '', 2.3, false, '', 1,
			                                                                                  priceList.id, priceListItem.Id, '', '', 'Sales Price', '', false, false, 22.00, 24.00, '', 34.00, 23.00, 33.50, '');
			insert lineItemPurchasing;

			// Create the proposal line item
			Apttus_Proposal__Proposal_Line_Item__c propLineItemChild =
			APTS_TestUtils.getProposalLineItem(quoteChild.Id, lineItemChild.Id, priceListItem.Id, productChild.Id, productChild.Id);
			insert propLineItemChild;
			Apttus_Proposal__Proposal_Line_Item__c propLineItemChildParentInChild =
			APTS_TestUtils.getProposalLineItem(quoteChild.Id, lineItemChildParentInChild.Id, priceListItem.Id, productChild.Id, productChild.Id);
			insert propLineItemChildParentInChild;

			// Create the proposal line item
			Apttus_Proposal__Proposal_Line_Item__c propLineItemParent =
			APTS_TestUtils.getProposalLineItem(quoteParent.Id, lineItemParent.Id, priceListItem.Id,
			                                   productChild.Id, productChild.Id);
			insert propLineItemParent;
			Apttus_Proposal__Proposal_Line_Item__c propLineItemChildParentInParent =
			APTS_TestUtils.getProposalLineItem(quoteParent.Id, lineItemChildParentInParent.Id, priceListItem.Id,
			                                   productChildParent.Id, productChildParent.Id);
			insert propLineItemChildParentInParent;

			Apttus_Proposal__Proposal_Line_Item__c propLineItemGrandParent = APTS_TestUtils.getProposalLineItem(quoteGrandParent.Id, lineItemGrandParent.Id, priceListItem.Id, productChild.Id, productChild.Id);
			insert propLineItemGrandParent;


			// Create and activate the agreement (for the child account)
			Apttus__APTS_Agreement__c agreementChild = APTS_TestUtils.createAgreement(con.Id, quoteChild.Id, priceList.Id, childAccount.Id);
			agreementChild.Apttus__Status__c = 'Activated';
			agreementChild.Apttus__Status_Category__c = 'In Effect';
			agreementChild.Apttus__Contract_End_Date__c = Date.newInstance(2020, 12, 12);
			insert agreementChild;
			APTS_Agreement_Account_Exclusion__c aae = new APTS_Agreement_Account_Exclusion__c();
			aae.APTS_Agreement__c = agreementChild.Id;
			aae.APTS_Account__c = childAccount.Id;
			insert aae;
			// Create and activate the agreement (for the parent account)
			Apttus__APTS_Agreement__c agreementParent = APTS_TestUtils.createAgreement(con.Id, quoteParent.Id, priceList.Id, parentAccount.Id);
			agreementParent.Apttus__Status__c = 'Activated';
			agreementParent.Apttus__Status_Category__c = 'In Effect';
			agreementParent.Apttus__Contract_End_Date__c = Date.newInstance(2020, 12, 12);
			insert agreementParent;

			// Create and activate the agreement (for the grand parent account)
			Apttus__APTS_Agreement__c agreementGrandParent = APTS_TestUtils.createAgreement(con.Id, quoteGrandParent.Id, priceList.Id, grandParentAccount.Id);
			agreementGrandParent.Apttus__Status__c = 'Activated';
			agreementGrandParent.Apttus__Status_Category__c = 'In Effect';
			agreementGrandParent.Apttus__Contract_End_Date__c = Date.newInstance(2020, 12, 12);
			insert agreementGrandParent;

			Apttus__APTS_Agreement__c agreementPurchasing = APTS_TestUtils.createAgreement(con.Id, quotePurchasing.Id, priceList.Id, organisation.Id);
			agreementPurchasing.Apttus__Status__c = 'Activated';
			agreementPurchasing.Apttus__Status_Category__c = 'In Effect';
			agreementPurchasing.Apttus__Contract_End_Date__c = Date.newInstance(2020, 12, 12);
			insert agreementPurchasing;

			// Create and activate the agreement (for the Purchasing Group)

			Apttus_Config2__ProductConfiguration__c agreementCartChild = new Apttus_Config2__ProductConfiguration__c(Name = 'Sample', Apttus_CMConfig__AgreementId__c = agreementChild.id, Apttus_Config2__PriceListId__c = priceList.id);
			agreementCartChild.Apttus_Config2__BusinessObjectType__c = 'Agreement';
			insert agreementCartChild;

			Apttus_Config2__ProductConfiguration__c agreementCartParent = new Apttus_Config2__ProductConfiguration__c(Name = 'Sample', Apttus_CMConfig__AgreementId__c = agreementparent.id, Apttus_Config2__PriceListId__c = priceList.id);
			agreementCartParent.Apttus_Config2__BusinessObjectType__c = 'Agreement';
			insert agreementCartParent;

			Apttus_Config2__ProductConfiguration__c agreementCartGrandParent = new Apttus_Config2__ProductConfiguration__c(Name = 'Sample', Apttus_CMConfig__AgreementId__c = agreementGrandParent.id, Apttus_Config2__PriceListId__c = priceList.id);
			agreementCartGrandParent.Apttus_Config2__BusinessObjectType__c = 'Agreement';
			insert agreementCartGrandParent;



			// Creation of agreement Line Items
			List<Apttus__AgreementLineItem__c> agreementLineItemsChild =
			APTS_TestUtils.createAgreementLineItem(productChild.Id, agreementChild.Id,
			                                       childAccount.Id, lineItemChild, priceListItem.Id, subCategoryHierarchy.Id);
			insert agreementLineItemsChild;

			APTS_Agreement_Line_Account_Exclusion__c alae = new APTS_Agreement_Line_Account_Exclusion__c();
			alae.APTS_Account__c = childAccount.Id;
			alae.APTS_Agreement_Line_Item__c = agreementLineItemsChild[0].id;
			insert alae;
			List<Apttus__AgreementLineItem__c> agreementLineItemsChildParentInChild =
			APTS_TestUtils.createAgreementLineItem(productChildParent.Id, agreementChild.Id,
			                                       childAccount.Id, lineItemChildParentInChild, priceListItem.Id, subCategoryHierarchy.Id);
			insert agreementLineItemsChildParentInChild;

			List<Apttus__AgreementLineItem__c> agreementLineItemsChildGrandParentInChild =	APTS_TestUtils.createAgreementLineItem(productChildGrandParent.Id, agreementChild.Id,
			                                       childAccount.Id, lineItemChildParentInChild, priceListItem.Id, subCategoryHierarchy.Id);
			insert agreementLineItemsChildGrandParentInChild;

			


			List<Apttus__AgreementLineItem__c> agreementLineItemsParent =
			APTS_TestUtils.createAgreementLineItem(productChild.Id, agreementParent.Id,
			                                       parentAccount.Id, lineItemParent, priceListItem.Id, subCategoryHierarchy.Id);
			insert agreementLineItemsParent;
			List<Apttus__AgreementLineItem__c> agreementLineItemsChildParentInParent =
			APTS_TestUtils.createAgreementLineItem(productChildParent.Id, agreementParent.Id,
			                                       parentAccount.Id, lineItemChildParentInParent, priceListItem.Id, subCategoryHierarchy.Id);
			insert agreementLineItemsChildParentInParent;
			agreementLineItemsChildParentInParent =
			APTS_TestUtils.createAgreementLineItem(productChild.Id, agreementParent.Id,
			                                       parentAccount.Id, lineItemChildParentInParent, priceListItem.Id, subCategoryHierarchy.Id);
			insert agreementLineItemsChildParentInParent;

			List<Apttus__AgreementLineItem__c> agreementLineItemsGrandParent =
			APTS_TestUtils.createAgreementLineItem(productChild.Id, agreementGrandParent.Id,
			                                       grandParentAccount.Id, lineItemGrandParent, priceListItem.Id, subCategoryHierarchy.Id);
			insert agreementLineItemsGrandParent;
			agreementLineItemsGrandParent = APTS_TestUtils.createAgreementLineItem(productChildParent.Id, agreementGrandParent.Id,
			                                                                       grandParentAccount.Id, lineItemGrandParent, priceListItem.Id, subCategoryHierarchy.Id);
			insert agreementLineItemsGrandParent;


			List<Apttus__AgreementLineItem__c> agreementLineItemsPurchasing =
			APTS_TestUtils.createAgreementLineItem(productChild.Id, agreementPurchasing.Id,
			                                       organisation.Id, lineItemPurchasing, priceListItem.Id, subCategoryHierarchy.Id);
			insert agreementLineItemsPurchasing;


			Test.startTest();

			List<Apttus_CMConfig__AgreementAdjustmentLineItem__c> adjustmentLineItemPurchasingList =
			new List<Apttus_CMConfig__AgreementAdjustmentLineItem__c> ();
			for (Apttus__AgreementLineItem__c lineitem : agreementLineItemsPurchasing) {
				adjustmentLineItemPurchasingList.add(APTS_TestUtils.createagrementadjustmentlineitemCER(lineitem.Id));
			}
			insert adjustmentLineItemPurchasingList;

			List<Apttus_CMConfig__AgreementAdjustmentLineItem__c> adjustmentLineItemGrandParentList =
			new List<Apttus_CMConfig__AgreementAdjustmentLineItem__c> ();
			for (Apttus__AgreementLineItem__c lineitem : agreementLineItemsGrandParent) {
				adjustmentLineItemGrandParentList.add(APTS_TestUtils.createagrementadjustmentlineitemCER(lineitem.id));
			}
			insert adjustmentLineItemGrandParentList;


			List<Apttus_CMConfig__AgreementAdjustmentLineItem__c> adjustmentLineItemParentList =
			new List<Apttus_CMConfig__AgreementAdjustmentLineItem__c> ();
			for (Apttus__AgreementLineItem__c lineitem : agreementLineItemsParent) {
				adjustmentLineItemParentList.add(APTS_TestUtils.createagrementadjustmentlineitemCER(lineitem.id));
			}
			for (Apttus__AgreementLineItem__c lineitem : agreementLineItemsChildParentInParent) {
				adjustmentLineItemParentList.add(APTS_TestUtils.createagrementadjustmentlineitemCER(lineitem.id));
			}
			insert adjustmentLineItemParentList;


			List<Apttus_CMConfig__AgreementAdjustmentLineItem__c> adjustmentLineItemChildList = new List<Apttus_CMConfig__AgreementAdjustmentLineItem__c> ();
			for (Apttus__AgreementLineItem__c lineitem : agreementLineItemsChild) {
				adjustmentLineItemChildList.add(APTS_TestUtils.createagrementadjustmentlineitemCER(lineitem.id));
			}
			for (Apttus__AgreementLineItem__c lineitem : agreementLineItemsChildParentInChild) {
				adjustmentLineItemChildList.add(APTS_TestUtils.createagrementadjustmentlineitemCER(lineitem.id));
			}
			insert adjustmentLineItemChildList;
			APTS_Adjustment_Line_Account_Exclusion__c ajlae = new APTS_Adjustment_Line_Account_Exclusion__c();
			ajlae.APTS_Account__c = childAccount.Id;
			ajlae.APTS_Agreement_Adjustment_Line_Item__c = adjustmentLineItemChildList[0].id;
			insert ajlae;

			List<Apttus__APTS_Agreement__c> newstatuslist = new List<Apttus__APTS_Agreement__c> ();
			newstatuslist.add(agreementPurchasing);
			APTS_ManageCER.manageCERRecords(newstatuslist, 'Agreement', 'Update');

			newstatuslist.clear();
			newstatuslist.add(agreementGrandParent);
			APTS_ManageCER.manageCERRecords(newstatuslist, 'Agreement', 'Update');

			newstatuslist.clear();
			newstatuslist.add(agreementParent);
			APTS_ManageCER.manageCERRecords(newstatuslist, 'Agreement', 'Update');

			newstatuslist.clear();
			newstatuslist.add(agreementGrandParent);
			APTS_ManageCER.manageCERRecords(newstatuslist, 'Agreement', 'Delete');
			newstatuslist.clear();
			newstatuslist.add(agreementParent);
			APTS_ManageCER.manageCERRecords(newstatuslist, 'Agreement', 'Delete');

			newstatuslist.clear();
			newstatuslist.add(agreementChild);
			APTS_ManageCER.manageCERRecords(newstatuslist, 'Agreement', 'Update');

			Test.stopTest();


		}
	}
	/**
	 * This is a test method for updateCERForAgreementExpiration
	 */
	private static testMethod void test_updateCERForAgreementExpiration()
	{
		Test.startTest();
		List<Id> agreementIdList = new List<Id> ();
		Apttus__APTS_Agreement__c agreement = APTS_TestUtils.getAgreements();
		agreementIdList.add(agreement.Id);
		APTS_ManageCER.updateCERForAgreementExpiration(agreementIdList);
		Test.stopTest();
	}


	/**
	 * This is a test method for updateCERForAdjustmentExpiration
	 */
	private static testMethod void test_updateCERForAdjustmentExpiration()
	{
		Test.startTest();
		Apttus__APTS_Agreement__c agreement = APTS_TestUtils.getAgreements();
		Apttus__AgreementLineItem__c lineItems = APTS_TestUtils.getAgreementLineItems(agreement.id);
		List<Apttus_Config2__AdjustmentLineItem__c> adjustmentLineList = APTS_TestUtils.getAdjustmentLineItems(lineitems.Id);
		List<Id> adjustmentLineIdList = new List<Id> ();
		for (Apttus_Config2__AdjustmentLineItem__c adjustment : adjustmentLineList) {
			adjustmentLineIdList.add(adjustment.Id);
		}
		APTS_ManageCER.updateCERForAdjustmentExpiration(adjustmentLineIdList);
		Test.stopTest();
	}


	///** commented by venky
	//* This is a test method for excludeAccountFromAgreement
	//*/
	//private static testMethod void test_excludeAccountFromAgreement() 
	//{
	//Test.startTest();
	//Id agreementId = null;
	//List<Id> accountIdList = new List<Id>();
	//Apttus__APTS_Agreement__c agreement = APTS_TestUtils.getAgreements();
	//agreementId=agreement.Id;
	//for(Account a:APTS_TestUtils.getAccounts())
	//{
	//accountIdList.add(a.id);
	//}
	//APTS_ManageCER.excludeAccountFromAgreement(agreementId,accountIdList);
	//Test.stopTest();
	//}


	/** Commented By Venky
	 * This is a test method for excludeAccountFromAgreementLineItem
	 */
	//private static testMethod void test_excludeAccountFromAgreementLineItem() 
	//{
	//Test.startTest();
	//Id agreementId = null;
	//Id agreementLineItemId = null;
	//List<Id> accountIdList = new List<Id>();
	//Apttus__APTS_Agreement__c agreement = APTS_TestUtils.getAgreements();
	//agreementId=agreement.Id;
	//Apttus__AgreementLineItem__c agreementLineItem =APTS_TestUtils.getAgreementLineItems(agreementId);
	//agreementLineItemId=agreementLineItem.Id;
	//for(Account a:APTS_TestUtils.getAccounts())
	//{
	//accountIdList.add(a.id);
	//}
	//APTS_ManageCER.excludeAccountFromAgreementLineItem(agreementId,agreementLineItemId,accountIdList);
	//Test.stopTest();
	//}


	/**
	 * This is a test method for excludeExceptionForAccountFromAgreementLineItem
	 */
	private static testMethod void test_excludeExceptionForAccountFromAgreementLineItem()
	{
		Test.startTest();
		Id agreementId = null;
		Id agreementLineItemId = null;
		List<Id> accountIdList = new List<Id> ();
		Apttus__APTS_Agreement__c agreement = APTS_TestUtils.getAgreements();
		agreementId = agreement.Id;
		Apttus__AgreementLineItem__c agreementLineItem = APTS_TestUtils.getAgreementLineItems(agreementId);
		agreementLineItemId = agreementLineItem.Id;
		for (Account a : APTS_TestUtils.getAccounts())
		{
			accountIdList.add(a.id);
		}
		APTS_ManageCER.excludeExceptionForAccountFromAgreementLineItem(agreementId, agreementLineItemId, accountIdList);
		Test.stopTest();
	}


	/**
	 * This is a test method for excludeAccountFromAdjustments
	 */
	private static testMethod void test_excludeAccountFromAdjustments() {

		// PageReference pageRef = Page.APTS_ManageCER;
		// Test.setCurrentPage(pageRef);
		// pageRef.getParameters().put('param1', 'param1');

		Test.startTest();

		// Variables

		// Obtain all the agreements
		List<Apttus__APTS_Agreement__c> agreements = APTS_TestUtils.getAllAgreements();
		for (Apttus__APTS_Agreement__c agreement : agreements)
		{


			Id agreementId = agreement.Id;
			List<Apttus__AgreementLineItem__c> agreementLineItems = APTS_TestUtils.getAllAgreementLineItems(agreementId);
			for (Apttus__AgreementLineItem__c agreementLineItem : agreementLineItems)
			{
				List<Id> agreementAdjustmentLineItemIds = new List<Id> ();

				Id agreementLineItemId = agreementLineItem.Id;
				Apttus_CMConfig__AgreementAdjustmentLineItem__c agreementAdjustmentLineItem =
				APTS_TestUtils.createagrementadjustmentlineitem(agreementLineItemId);

				agreementAdjustmentLineItemIds.add(agreementAdjustmentLineItem.Id);

				List<Id> accountIdList = new List<Id> ();
				for (Account a : APTS_TestUtils.getAccounts())
				{
					accountIdList.add(a.id);
				}

				APTS_ManageCER.excludeAccountFromAdjustments(agreementId, agreementLineItemId, agreementAdjustmentLineItemIds, accountIdList);
			}

		}



		Test.stopTest();
	}


	/**
	 * This is a test method for getCERDataForAccount
	 */
	private static testMethod void test_getCERDataForAccount()
	{
		Test.startTest();

		Account buyingGroupAccount = APTS_TestUtils.getBuyingGroup();
		Account childAccount = APTS_TestUtils.getChildAccount();
		Account parentAccount = APTS_TestUtils.getParentAccount();
		Account grandParentAccount = APTS_TestUtils.getGrandParentAccount();

		List<APTS_Contract_Entitlement_Repository__c> resultGetCERDataForAccount = null;
		resultGetCERDataForAccount = APTS_ManageCER.getCERDataForAccount(childAccount.Id);
		resultGetCERDataForAccount = APTS_ManageCER.getCERDataForAccount(parentAccount.Id);
		resultGetCERDataForAccount = APTS_ManageCER.getCERDataForAccount(grandParentAccount.Id);
		resultGetCERDataForAccount = APTS_ManageCER.getCERDataForAccount(buyingGroupAccount.Id);
		Test.stopTest();
	}


	/**
	 * This is a test method for getCERDataForAgreement
	 */
	//private static testMethod void test_getCERDataForAgreement() 
	//{
	//Test.startTest();
	//List<Apttus__APTS_Agreement__c> agreements = APTS_TestUtils.getAllAgreements();
	//for(Apttus__APTS_Agreement__c agreement: agreements){
	//List<APTS_Contract_Entitlement_Repository__c> resultGetCERDataForAgreement = APTS_ManageCER.getCERDataForAgreement(agreement.Id);    
	//}            
	//Test.stopTest();
	//}


	///** Commented By Venky
	//* This is a test method for deleteAccountFromBuyingGroup
	//*/
	//private static testMethod void test_deleteAccountFromBuyingGroup() {

	//// PageReference pageRef = Page.APTS_ManageCER;
	//// Test.setCurrentPage(pageRef);
	//// pageRef.getParameters().put('param1', 'param1');

	//Test.startTest();

	//Account buyingGroupAccount = APTS_TestUtils.getBuyingGroup();
	//Account childAccount = APTS_TestUtils.getChildAccount();
	//Account parentAccount = APTS_TestUtils.getParentAccount();
	//Account grandParentAccount = APTS_TestUtils.getGrandParentAccount();

	//APTS_ManageCER.deleteAccountFromBuyingGroup(buyingGroupAccount.Id,buyingGroupAccount.Id);     
	//APTS_ManageCER.deleteAccountFromBuyingGroup(grandParentAccount.Id,buyingGroupAccount.Id);
	//APTS_ManageCER.deleteAccountFromBuyingGroup(parentAccount.Id,buyingGroupAccount.Id);
	//APTS_ManageCER.deleteAccountFromBuyingGroup(childAccount.Id,buyingGroupAccount.Id);

	//Test.stopTest();        
	//}


	/**
	 * This is a test method for addAccountToBuyingGroup
	 */
	//private static testMethod void test_addAccountToBuyingGroup() {

	//// PageReference pageRef = Page.APTS_ManageCER;
	//// Test.setCurrentPage(pageRef);
	//// pageRef.getParameters().put('param1', 'param1');

	//Test.startTest();

	//Account buyingGroupAccount = APTS_TestUtils.getBuyingGroup();
	//Account childAccount = APTS_TestUtils.getChildAccount();
	//Account parentAccount = APTS_TestUtils.getParentAccount();
	//Account grandParentAccount = APTS_TestUtils.getGrandParentAccount();
	//APTS_ManageCER.addAccountToBuyingGroup(parentAccount.Id,buyingGroupAccount.Id);
	//APTS_ManageCER.addAccountToBuyingGroup(grandParentAccount.Id,buyingGroupAccount.Id);

	//Test.stopTest();

	//// Check
	//// System.assert(ApexPages.hasMessages());
	//// for(ApexPages.Message msg : ApexPages.getMessages()) {
	////     System.assertEquals('Upload file is NULL', msg.getSummary());
	////     System.assertEquals(ApexPages.Severity.ERROR, msg.getSeverity());
	//// }
	//}


	/**
	 * This is a test method for deleteCERDataForAccount
	 */
	private static testMethod void test_deleteCERDataForAccount()
	{
		Test.startTest();
		Id accountId = null;
		for (Account a : APTS_TestUtils.getAccounts())
		{
			accountId = a.id;
			break;
		}
		APTS_ManageCER.deleteCERDataForAccount(accountId);
		Test.stopTest();
	}


	/**
	 * This is a test method for getHierarchyAccountIdList
	 */
	private static testMethod void test_getHierarchyAccountIdList()
	{
		Test.startTest();

		Id accountId = null;
		Account buyingGroupAccount = APTS_TestUtils.getBuyingGroup();
		Account childAccount = APTS_TestUtils.getChildAccount();
		Account parentAccount = APTS_TestUtils.getParentAccount();
		Account grandParentAccount = APTS_TestUtils.getGrandParentAccount();

		List<Id> resultGetHierarchyAccountIdList = null;
		// Normal get for the different accounts
		resultGetHierarchyAccountIdList = APTS_ManageCER.getHierarchyAccountIdList(buyingGroupAccount.Id, 'Grand Parent Account');
		resultGetHierarchyAccountIdList = APTS_ManageCER.getHierarchyAccountIdList(childAccount.Id, 'Grand Parent Account');
		resultGetHierarchyAccountIdList = APTS_ManageCER.getHierarchyAccountIdList(parentAccount.Id, 'Grand Parent Account');
		resultGetHierarchyAccountIdList = APTS_ManageCER.getHierarchyAccountIdList(grandParentAccount.Id, 'Grand Parent Account');
		// Get for a parent account thas has no children (in this case childAccount)
		resultGetHierarchyAccountIdList = APTS_ManageCER.getHierarchyAccountIdList(parentAccount.Id, 'NonExisting Account');
		resultGetHierarchyAccountIdList = APTS_ManageCER.getHierarchyAccountIdList(parentAccount.Id, 'Parent Account');
		Test.stopTest();
	}


	/**
	 * This is a test method for isBuyingGroup
	 */
	private static testMethod void test_isBuyingGroup() {

		// PageReference pageRef = Page.APTS_ManageCER;
		// Test.setCurrentPage(pageRef);
		// pageRef.getParameters().put('param1', 'param1');

		Test.startTest();

		Account buyingGroupAccount = APTS_TestUtils.getBuyingGroup();
		Account childAccount = APTS_TestUtils.getChildAccount();
		Account parentAccount = APTS_TestUtils.getParentAccount();
		Account grandParentAccount = APTS_TestUtils.getGrandParentAccount();

		boolean resultIsBuyingGroup = false;
		resultIsBuyingGroup = APTS_ManageCER.isBuyingGroup(buyingGroupAccount.Id);
		resultIsBuyingGroup = APTS_ManageCER.isBuyingGroup(childAccount.Id);
		resultIsBuyingGroup = APTS_ManageCER.isBuyingGroup(parentAccount.Id);
		resultIsBuyingGroup = APTS_ManageCER.isBuyingGroup(grandParentAccount.Id);


		Test.stopTest();
	}


	/**
	 * This is a test method for getRelatedBuyingGroupAccounts
	 */
	private static testMethod void test_getRelatedBuyingGroupAccounts() {

		// PageReference pageRef = Page.APTS_ManageCER;
		// Test.setCurrentPage(pageRef);
		// pageRef.getParameters().put('param1', 'param1');

		Test.startTest();

		Id buyingGroupAccountId = null;
		List<Account> resultGetRelatedBuyingGroupAccounts = APTS_ManageCER.getRelatedBuyingGroupAccounts(buyingGroupAccountId);


		Test.stopTest();

		// Check
		// System.assert(ApexPages.hasMessages());
		// for(ApexPages.Message msg : ApexPages.getMessages()) {
		//     System.assertEquals('Upload file is NULL', msg.getSummary());
		//     System.assertEquals(ApexPages.Severity.ERROR, msg.getSeverity());
		// }
	}


	/**
	 * This is a test method for manageCERRecords
	 */
	private static testMethod void test_manageCERRecords()
	{
		Test.startTest();
		List<Apttus__APTS_Agreement__c> agreements = APTS_TestUtils.getAllAgreements();
		string triggerPoint = 'Agreement';
		string dmlOperation = 'Insert';
		APTS_ManageCER.manageCERRecords(agreements, triggerPoint, dmlOperation);
		triggerPoint = 'Agreement';
		dmlOperation = 'Update';
		APTS_ManageCER.manageCERRecords(agreements, triggerPoint, dmlOperation);
		triggerPoint = 'Agreement';
		dmlOperation = 'Delete';
		APTS_ManageCER.manageCERRecords(agreements, triggerPoint, dmlOperation);
		Test.stopTest();
	}


	/**
	 * This is a test method for excludedItemsFromTwoAgreements
	 */
	private static testMethod void test_excludedItemsFromTwoAgreements() {

		// PageReference pageRef = Page.APTS_ManageCER;
		// Test.setCurrentPage(pageRef);
		// pageRef.getParameters().put('param1', 'param1');

		Test.startTest();
		List<APTS_CERUtility.Agreement> childAgreements = new List<APTS_CERUtility.Agreement>();
		List<APTS_CERUtility.Agreement> parentAgreements = new List<APTS_CERUtility.Agreement>();
		List<Apttus__APTS_Agreement__c> agreementList = APTS_TestUtils.getAllAgreements();
		APTS_CERUtility.Agreement cerAgr = new APTS_CERUtility.Agreement();
		Set<Id> tempAgreementSet=new Set<Id>();
		For (Apttus__APTS_Agreement__c agr : agreementList)
		{
			cerAgr = new APTS_CERUtility.Agreement();
			cerAgr.agreementId = agr.id;
			childAgreements.add(cerAgr);
			parentAgreements.add(cerAgr);
			tempAgreementSet.add(agr.id);
		}


		Map<Id, Map<Id, List<APTS_CERUtility.AgreementLineItemChargeType>>> contractedProducts = APTS_CERUtility.getContractedProductsForAgreement(tempAgreementSet);
		Map<Id, List<Id>> resultExcludedItemsFromTwoAgreements = APTS_ManageCER.excludedItemsFromTwoAgreements(childAgreements, parentAgreements, contractedProducts);


		Test.stopTest();

		// Check
		// System.assert(ApexPages.hasMessages());
		// for(ApexPages.Message msg : ApexPages.getMessages()) {
		//     System.assertEquals('Upload file is NULL', msg.getSummary());
		//     System.assertEquals(ApexPages.Severity.ERROR, msg.getSeverity());
		// }
	}


	/**
	 * This is a test method for excludedItemsFromThreeAgreements
	 */
	private static testMethod void test_excludedItemsFromThreeAgreements()
	{
		Test.startTest();

		List<APTS_CERUtility.Agreement> childAgreements = new List<APTS_CERUtility.Agreement> ();
		List<APTS_CERUtility.Agreement> parentAgreements = new List<APTS_CERUtility.Agreement> ();
		List<APTS_CERUtility.Agreement> grandParentAgreements = new List<APTS_CERUtility.Agreement> ();

		Account buyingGroupAccount = APTS_TestUtils.getBuyingGroup();
		Account childAccount = APTS_TestUtils.getChildAccount();
		Account parentAccount = APTS_TestUtils.getParentAccount();
		Account grandParentAccount = APTS_TestUtils.getGrandParentAccount();


		List<Apttus__APTS_Agreement__c> agreements = APTS_TestUtils.getAllAgreements();
		Set<Id> agreementsSet = new Set<Id> ();

		for (Apttus__APTS_Agreement__c agreement : agreements)
		{
			agreementsSet.add(agreement.Id);
			APTS_CERUtility.Agreement newAgreement = new APTS_CERUtility.Agreement();
			newAgreement.AgreementType = 'Standard Deal';
			newAgreement.AgreementId = agreement.Id;
			if (agreement.Apttus__Account__c == childAccount.Id)
			{
				childAgreements.add(newAgreement);
			}
			else if (agreement.Apttus__Account__c == parentAccount.Id)
			{
				parentAgreements.add(newAgreement);
			}
			else if (agreement.Apttus__Account__c == grandParentAccount.Id)
			{
				grandParentAgreements.add(newAgreement);
			}

		}

		Map<Id, Map<Id, List<APTS_CERUtility.AgreementLineItemChargeType>>> contractedProducts =
		APTS_CERUtility.getContractedProductsForAgreement(agreementsSet);


		Map<Id, List<Id>> resultExcludedItemsFromThreeAgreements =
		APTS_ManageCER.excludedItemsFromThreeAgreements(childAgreements, parentAgreements, grandParentAgreements, contractedProducts);
		Test.stopTest();
	}


	/**
	 * This is a test method for excludedItemsFromFourAgreements
	 */
	private static testMethod void test_excludedItemsFromFourAgreements() {

		// PageReference pageRef = Page.APTS_ManageCER;
		// Test.setCurrentPage(pageRef);
		// pageRef.getParameters().put('param1', 'param1');

		Test.startTest();

		List<APTS_CERUtility.Agreement> childAgreements = new List<APTS_CERUtility.Agreement> ();
		List<APTS_CERUtility.Agreement> parentAgreements = new List<APTS_CERUtility.Agreement> ();
		List<APTS_CERUtility.Agreement> grandParentAgreements = new List<APTS_CERUtility.Agreement> ();
		List<APTS_CERUtility.Agreement> buyingGroupAgreements = new List<APTS_CERUtility.Agreement> ();

		Account buyingGroupAccount = APTS_TestUtils.getBuyingGroup();
		Account childAccount = APTS_TestUtils.getChildAccount();
		Account parentAccount = APTS_TestUtils.getParentAccount();
		Account grandParentAccount = APTS_TestUtils.getGrandParentAccount();


		List<Apttus__APTS_Agreement__c> agreements = APTS_TestUtils.getAllAgreements();
		Set<Id> agreementsSet = new Set<Id> ();

		for (Apttus__APTS_Agreement__c agreement : agreements)
		{
			agreementsSet.add(agreement.Id);
			APTS_CERUtility.Agreement newAgreement = new APTS_CERUtility.Agreement();
			newAgreement.AgreementType = 'Standard Deal';
			newAgreement.AgreementId = agreement.Id;
			if (agreement.Apttus__Account__c == childAccount.Id)
			{
				childAgreements.add(newAgreement);
			}
			else if (agreement.Apttus__Account__c == parentAccount.Id)
			{
				parentAgreements.add(newAgreement);
			}
			else if (agreement.Apttus__Account__c == grandParentAccount.Id)
			{
				grandParentAgreements.add(newAgreement);
			}
			else
			buyingGroupAgreements.add(newAgreement);

		}

		Map<Id, Map<Id, List<APTS_CERUtility.AgreementLineItemChargeType>>> contractedProducts =
		APTS_CERUtility.getContractedProductsForAgreement(agreementsSet);
		Map<Id, List<Id>> resultExcludedItemsFromFourAgreements = APTS_ManageCER.excludedItemsFromFourAgreements(childAgreements, parentAgreements, grandParentAgreements, buyingGroupAgreements, contractedProducts);


		Test.stopTest();

		// Check
		// System.assert(ApexPages.hasMessages());
		// for(ApexPages.Message msg : ApexPages.getMessages()) {
		//     System.assertEquals('Upload file is NULL', msg.getSummary());
		//     System.assertEquals(ApexPages.Severity.ERROR, msg.getSeverity());
		// }
	}

	/**
	 * This is a test method for excludedItemsFromAgreements
	 */
	private static testMethod void test_excludedItemsFromAgreements()
	{
		Test.startTest();
		Map<Id, Map<Id, List<Id>>> toBeExcluded = new Map<Id, Map<Id, List<Id>>> ();
		Map<Id, Set<Id>> resultExcludedItemsFromAgreements = APTS_ManageCER.excludedItemsFromAgreements(toBeExcluded);
		Test.stopTest();
	}


	/**
	 * This is a test method for all
	 */
	private static testMethod void test_all() {

		// PageReference pageRef = Page.APTS_ManageCER;
		// Test.setCurrentPage(pageRef);
		// pageRef.getParameters().put('param1', 'param1');

		Test.startTest();

		List<Id> agreementIdList = null;
		//  test updateCERForAgreementExpiration
		APTS_ManageCER.updateCERForAgreementExpiration(agreementIdList);

		List<Id> adjustmentLineIdList = null;
		//  test updateCERForAdjustmentExpiration
		APTS_ManageCER.updateCERForAdjustmentExpiration(adjustmentLineIdList);

		Id agreementId = null;
		List<Id> accountIdList = null;
		//  test excludeAccountFromAgreement
		// APTS_ManageCER.excludeAccountFromAgreement(agreementId,accountIdList);

		Id agreementLineItemId = null;
		//  test excludeAccountFromAgreementLineItem
		// APTS_ManageCER.excludeAccountFromAgreementLineItem(agreementId,agreementLineItemId,accountIdList);

		//  test excludeExceptionForAccountFromAgreementLineItem
		APTS_ManageCER.excludeExceptionForAccountFromAgreementLineItem(agreementId, agreementLineItemId, accountIdList);

		List<Id> agreementAdjustmentLineItemId = null;
		//  test excludeAccountFromAdjustments
		APTS_ManageCER.excludeAccountFromAdjustments(agreementId, agreementLineItemId, agreementAdjustmentLineItemId, accountIdList);

		Id accountId = null;
		//  test getCERDataForAccount
		// List<APTS_Contract_Entitlement_Repository__c> resultGetCERDataForAccount = APTS_ManageCER.getCERDataForAccount(accountId);

		//  test getCERDataForAgreement
		//  List<APTS_Contract_Entitlement_Repository__c> resultGetCERDataForAgreement = APTS_ManageCER.getCERDataForAgreement(agreementId);

		Id buyingGroupAccountId = null;
		//  test deleteAccountFromBuyingGroup
		//        APTS_ManageCER.deleteAccountFromBuyingGroup(accountId,buyingGroupAccountId);

		//  test addAccountToBuyingGroup
		// APTS_ManageCER.addAccountToBuyingGroup(accountId,buyingGroupAccountId);

		//  test deleteCERDataForAccount
		APTS_ManageCER.deleteCERDataForAccount(accountId);

		//  test getHierarchyAccountIdList
		List<Id> resultGetHierarchyAccountIdList = APTS_ManageCER.getHierarchyAccountIdList(accountId, '');
		//  test isBuyingGroup
		boolean resultIsBuyingGroup = APTS_ManageCER.isBuyingGroup(accountId);

		//  test getRelatedBuyingGroupAccounts
		List<Account> resultGetRelatedBuyingGroupAccounts = APTS_ManageCER.getRelatedBuyingGroupAccounts(buyingGroupAccountId);

		List<Apttus__APTS_Agreement__c> agreements = null;
		string triggerPoint = 'mFUCo9c';
		string dmlOperation = 'Oq42yAl';
		//  test manageCERRecords
		APTS_ManageCER.manageCERRecords(agreements, triggerPoint, dmlOperation);

		List<APTS_CERUtility.Agreement> childAgreements = null;
		List<APTS_CERUtility.Agreement> parentAgreements = null;
		List<APTS_CERUtility.Agreement> grandParentAgreements = null;
		List<APTS_CERUtility.Agreement> buyingGroupAgreements = null;
		Map<Id, Map<Id, List<APTS_CERUtility.AgreementLineItemChargeType>>> contractedProducts = null;
		//  test excludedItemsFromTwoAgreements
		Map<Id, List<Id>> resultExcludedItemsFromTwoAgreements = APTS_ManageCER.excludedItemsFromTwoAgreements(childAgreements, parentAgreements, contractedProducts);


		//  test excludedItemsFromThreeAgreements
		Map<Id, List<Id>> resultExcludedItemsFromThreeAgreements = APTS_ManageCER.excludedItemsFromThreeAgreements(childAgreements, parentAgreements, grandParentAgreements, contractedProducts);




		//  test excludedItemsFromFourAgreements
		Map<Id, List<Id>> resultExcludedItemsFromFourAgreements = APTS_ManageCER.excludedItemsFromFourAgreements(childAgreements, parentAgreements, grandParentAgreements, buyingGroupAgreements, contractedProducts);

		Map<Id, Map<Id, List<Id>>> toBeExcluded = null;
		//  test excludedItemsFromAgreements
		//Map<Id,Set<Id>> resultExcludedItemsFromAgreements = APTS_ManageCER.excludedItemsFromAgreements(toBeExcluded);


		Test.stopTest();

		// Check
		// System.assert(ApexPages.hasMessages());
		// for(ApexPages.Message msg : ApexPages.getMessages()) {
		//     System.assertEquals('Upload file is NULL', msg.getSummary());
		//     System.assertEquals(ApexPages.Severity.ERROR, msg.getSeverity());
		// }
	}


}