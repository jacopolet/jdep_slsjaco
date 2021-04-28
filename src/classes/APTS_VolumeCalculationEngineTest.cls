@isTest
private class APTS_VolumeCalculationEngineTest {

	private static String VOLUME = system.label.APTS_Volume;
	private static String HIGHRATETIER = system.label.APTS_HighRate;
	private static String BENEFIT = system.label.APTS_Benefit;
	private static String BENEFITAMT= system.label.APTS_BenefitAmt;
	private static String BENEFITPERUNIT='Benefit Per Unit';
	private static String RATEPERTIER = system.label.APTS_RatePerEach;
	private static String REVENUE = system.label.APTS_Revenue;
	private static String LISTPRICE = system.label.APTS_ListPrice;
	private static String NETPRICE = system.label.APTS_NetPrice;

	@testSetup static void setupTestData()
	{
		// Creation of category
        /*Apttus_Config2__ClassificationName__c category = new Apttus_Config2__ClassificationName__c();
        category.Name = 'Coffee';
        category.Apttus_Config2__Active__c = true;
        category.Apttus_Config2__HierarchyLabel__c = 'Coffee';
        category.Apttus_Config2__Type__c = 'Offering';
        category.APTS_Allow_Adjustments__c = true;*/
        Apttus_Config2__ClassificationName__c category = APTS_TestDataFactory.createCategory();
        Database.insert(category);

        // Creation of category hierarchy
        /*Apttus_Config2__ClassificationHierarchy__c categoryHierarchy = new Apttus_Config2__ClassificationHierarchy__c();
        categoryHierarchy.Name = 'Coffee';
        categoryHierarchy.Apttus_Config2__HierarchyId__c = category.Id;
        categoryHierarchy.Apttus_Config2__AncestorId__c = null;
        categoryHierarchy.Apttus_Config2__DefaultSearchCategory__c = false;
        categoryHierarchy.Apttus_Config2__ExpandedByDefault__c = false;
        categoryHierarchy.Apttus_Config2__HideAllSearchFilters__c = false;
        categoryHierarchy.Apttus_Config2__IncludeInTotalsView__c = true;
        categoryHierarchy.Apttus_Config2__IsHidden__c = false;
        categoryHierarchy.Apttus_Config2__IsPicklist__c = false;
        categoryHierarchy.Apttus_Config2__Label__c = 'Coffee';
        categoryHierarchy.Apttus_Config2__LargeImageSize__c = '20x20';
        categoryHierarchy.Apttus_Config2__Left__c = 1;
        categoryHierarchy.Apttus_Config2__Level__c = 0;
        categoryHierarchy.Apttus_Config2__MaxOptions__c = 1.00000;
        categoryHierarchy.Apttus_Config2__MinOptions__c = 1.00000;
        categoryHierarchy.Apttus_Config2__Modifiable__c = true;
        categoryHierarchy.Apttus_Config2__PrimordialId__c = null;
        categoryHierarchy.Apttus_Config2__ProductAttributeGroupId__c = null;
        categoryHierarchy.Apttus_Config2__Right__c = 20;*/
        Apttus_Config2__ClassificationHierarchy__c categoryHierarchy = APTS_TestDataFactory.createCategoryHierarchy(category.Id, 'Coffee');
        Database.insert(categoryHierarchy);


        // Creation of category hierarchy
        /*Apttus_Config2__ClassificationHierarchy__c subCategoryHierarchy = new Apttus_Config2__ClassificationHierarchy__c();
        subCategoryHierarchy.Name = 'Instant';
        subCategoryHierarchy.Apttus_Config2__HierarchyId__c = category.Id;
        subCategoryHierarchy.Apttus_Config2__AncestorId__c = categoryHierarchy.Id;
        subCategoryHierarchy.Apttus_Config2__DefaultSearchCategory__c = false;
        subCategoryHierarchy.Apttus_Config2__ExpandedByDefault__c = false;
        subCategoryHierarchy.Apttus_Config2__HideAllSearchFilters__c = false;
        subCategoryHierarchy.Apttus_Config2__IncludeInTotalsView__c = true;
        subCategoryHierarchy.Apttus_Config2__IsHidden__c = false;
        subCategoryHierarchy.Apttus_Config2__IsPicklist__c = false;
        subCategoryHierarchy.Apttus_Config2__Label__c = 'Instant';
        subCategoryHierarchy.Apttus_Config2__LargeImageSize__c = '20x20';
        subCategoryHierarchy.Apttus_Config2__Left__c = 1;
        subCategoryHierarchy.Apttus_Config2__Level__c = 0;
        subCategoryHierarchy.Apttus_Config2__MaxOptions__c = 1.00000;
        subCategoryHierarchy.Apttus_Config2__MinOptions__c = 1.00000;
        subCategoryHierarchy.Apttus_Config2__Modifiable__c = true;
        subCategoryHierarchy.Apttus_Config2__PrimordialId__c = null;
        subCategoryHierarchy.Apttus_Config2__ProductAttributeGroupId__c = null;
        subCategoryHierarchy.Apttus_Config2__Right__c = 20;*/
        Apttus_Config2__ClassificationHierarchy__c subCategoryHierarchy = APTS_TestDataFactory.createSubCategory(category.Id, categoryHierarchy.Id);
        Database.insert(subCategoryHierarchy);
        subCategoryHierarchy.Name='Instant';
        subCategoryHierarchy.Apttus_Config2__Label__c = 'Instant';
        subCategoryHierarchy.Apttus_Config2__Left__c = 1;
        subCategoryHierarchy.Apttus_Config2__Level__c = 0;
        subCategoryHierarchy.Apttus_Config2__PrimordialId__c = categoryHierarchy.Id;
        subCategoryHierarchy.Apttus_Config2__Right__c = 20;
        Database.update(subCategoryHierarchy);

		// Creation of pricelist
        /*Apttus_Config2__PriceList__c priceList = new Apttus_Config2__PriceList__c();
        priceList.Name = 'JDE Price List';
        priceList.Apttus_Config2__Active__c = true;
        priceList.APTS_SalesOrg__c = 'SalesOrg';*/
        Apttus_Config2__PriceList__c priceList = APTS_TestDataFactory.createPriceList('JDE Price List');
        Database.insert(priceList);
        priceList.APTS_SalesOrg__c = 'SalesOrg';
        Database.update(priceList);

		// Creation of conversion Record
		List<Apttus_Config2__FrequencyConversionRate__c> conversions = new List<Apttus_Config2__FrequencyConversionRate__c>();
		/*Apttus_Config2__FrequencyConversionRate__c conversionRateDrinksToKGM = new Apttus_Config2__FrequencyConversionRate__c();
		conversionRateDrinksToKGM.Apttus_Config2__FromUom__c = 'SAP_DRKS';
		conversionRateDrinksToKGM.Apttus_Config2__ToUom__c = 'SAP_KGM';
		conversionRateDrinksToKGM.Apttus_Config2__ConversionFactor__c = 6;	
		conversionRateDrinksToKGM.Apttus_Config2__ProductFamily__c = 'SAP_01';
        conversionRateDrinksToKGM.Apttus_Config2__FromFrequency__c = 'Daily';*/
        Apttus_Config2__FrequencyConversionRate__c conversionRateDrinksToKGM = APTS_TestDataFactory.createConversionRate('SAP_DRKS','SAP_KGM');
        conversionRateDrinksToKGM.Apttus_Config2__ConversionFactor__c = 6;	
		conversionRateDrinksToKGM.Apttus_Config2__ProductFamily__c = 'SAP_01';
		conversions.add(conversionRateDrinksToKGM);

		/*Apttus_Config2__FrequencyConversionRate__c conversionRateDrinksToLTR = new Apttus_Config2__FrequencyConversionRate__c();
		conversionRateDrinksToLTR.Apttus_Config2__FromUom__c = 'SAP_DRKS';
		conversionRateDrinksToLTR.Apttus_Config2__ToUom__c = 'SAP_LTR';
		conversionRateDrinksToLTR.Apttus_Config2__ConversionFactor__c = 20;	
		conversionRateDrinksToLTR.Apttus_Config2__ProductFamily__c = 'SAP_01';
        conversionRateDrinksToLTR.Apttus_Config2__FromFrequency__c = 'Daily';*/
        Apttus_Config2__FrequencyConversionRate__c conversionRateDrinksToLTR = APTS_TestDataFactory.createConversionRate('SAP_DRKS','SAP_LTR');
        conversionRateDrinksToLTR.Apttus_Config2__ConversionFactor__c = 20;	
		conversionRateDrinksToLTR.Apttus_Config2__ProductFamily__c = 'SAP_01';
		conversions.add(conversionRateDrinksToLTR);

        /*Apttus_Config2__FrequencyConversionRate__c conversionRateDrinkszero = new Apttus_Config2__FrequencyConversionRate__c();
        conversionRateDrinkszero.Apttus_Config2__FromUom__c = 'SAP_DRKS';
        conversionRateDrinkszero.Apttus_Config2__ToUom__c = 'SAP_PF';
        conversionRateDrinkszero.Apttus_Config2__ConversionFactor__c = 0.0; 
        conversionRateDrinkszero.Apttus_Config2__ProductFamily__c = 'SAP_01';
        conversionRateDrinkszero.Apttus_Config2__FromFrequency__c = 'Daily';*/   
        Apttus_Config2__FrequencyConversionRate__c conversionRateDrinkszero = APTS_TestDataFactory.createConversionRate('SAP_DRKS','SAP_PF');
        conversionRateDrinkszero.Apttus_Config2__ConversionFactor__c = 0.0;	
		conversionRateDrinkszero.Apttus_Config2__ProductFamily__c = 'SAP_01';
        conversions.add(conversionRateDrinkszero);

		insert conversions;

		// Creation of the contact
        /*Contact primaryContact = new Contact();
        primaryContact.FirstName = 'Test';
        primaryContact.LastName = ' Primary Contact';
        primaryContact.Email = 'xyz@abc.com';
        primaryContact.Phone = '+11111111111';*/
        Contact primaryContact = APTS_TestUtils.createContact();
        Database.insert(primaryContact);
        primaryContact.LastName = ' Primary Contact';
        primaryContact.Phone = '+11111111111';
        Database.update(primaryContact);

        // Creation of the account
        /*List<Account> accounts = new List<Account>();
        Account childAccount;
        childAccount = new Account();
        childAccount.Name = 'AccountChild';
        childAccount.Phone='+11111111111';
        childAccount.Main_Street_Only__c = 'Test Street';
        childAccount.Main_House_Number__c = 'Test no.';
        childAccount.Sales_Organization__c = 'SAP_0111';
        childAccount.APTS_Partner_Pricing_Portal_Applicable__c = true;
        childAccount.SAP_Customer_ID__c = '103';
        accounts.add(childAccount);*/
        Account acc = APTS_TestDataFactory.createAccount('AccountChild');
        acc.Main_Street_Only__c = 'Test Street';
        acc.Main_House_Number__c = 'Test no.';
        acc.APTS_Partner_Pricing_Portal_Applicable__c = true;
        acc.SAP_Customer_ID__c = '103';
        Database.insert(acc);
        acc.Phone='+11111111111';
        Database.update(acc);

		// Creation of agreements
		List<Apttus__APTS_Agreement__c> agreements = new List<Apttus__APTS_Agreement__c>();
		
		/*Apttus__APTS_Agreement__c benefitAmountStandardAgreement = new Apttus__APTS_Agreement__c();
        benefitAmountStandardAgreement.recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
        benefitAmountStandardAgreement.Name = 'Standard Agreement (Benefit Amount)';
        benefitAmountStandardAgreement.Apttus__Primary_Contact__c = primaryContact.Id;
        benefitAmountStandardAgreement.Apttus__Agreement_Category__c = 'Standard';
        benefitAmountStandardAgreement.Apttus_CMConfig__PriceListId__c = priceList.Id;
        benefitAmountStandardAgreement.Apttus_CMConfig__PricingDate__c = System.Today();
        benefitAmountStandardAgreement.Apttus__Account__c = acc.Id;
        benefitAmountStandardAgreement.APTS_Order_Non_Contracted_Products__c = true;
        benefitAmountStandardAgreement.APTS_Preferred_way_of_ingredient_deliver__c = 'Routesales';
        benefitAmountStandardAgreement.APTS_Language__c = 'SAP_SV';*/
        Apttus__APTS_Agreement__c benefitAmountStandardAgreement = APTS_TestDataFactory.createAgreement(primaryContact.Id, priceList.Id, acc.Id, 'Standard Deal', 'Standard Agreement (Benefit Amount)');
        benefitAmountStandardAgreement.APTS_Order_Non_Contracted_Products__c = true;
        benefitAmountStandardAgreement.APTS_Preferred_way_of_ingredient_deliver__c = 'Routesales';
        benefitAmountStandardAgreement.APTS_Language__c = 'SAP_SV';
        agreements.add(benefitAmountStandardAgreement);

        /*Apttus__APTS_Agreement__c benefitperUnitStandardAgreement = new Apttus__APTS_Agreement__c();
        benefitperUnitStandardAgreement.recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
        benefitperUnitStandardAgreement.Name = 'Standard Agreement (Benefit per Unit)';
        benefitperUnitStandardAgreement.Apttus__Primary_Contact__c = primaryContact.Id;
        benefitperUnitStandardAgreement.Apttus__Agreement_Category__c = 'Standard';
        benefitperUnitStandardAgreement.Apttus_CMConfig__PriceListId__c = priceList.Id;
        benefitperUnitStandardAgreement.Apttus_CMConfig__PricingDate__c = System.Today();
        benefitperUnitStandardAgreement.Apttus__Account__c = acc.Id;
        benefitperUnitStandardAgreement.APTS_Order_Non_Contracted_Products__c = true;
        benefitperUnitStandardAgreement.APTS_Language__c = 'SAP_NO';*/
        Apttus__APTS_Agreement__c benefitperUnitStandardAgreement = APTS_TestDataFactory.createAgreement(primaryContact.Id, priceList.Id, acc.Id, 'Standard Deal', 'Standard Agreement (Benefit per Unit)');
        benefitperUnitStandardAgreement.APTS_Order_Non_Contracted_Products__c = true;
        benefitperUnitStandardAgreement.APTS_Language__c = 'SAP_NO';
        agreements.add(benefitperUnitStandardAgreement);

        /*Apttus__APTS_Agreement__c benefitAmountRatePerTierStandardAgreement = new Apttus__APTS_Agreement__c();
        benefitAmountRatePerTierStandardAgreement.recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
        benefitAmountRatePerTierStandardAgreement.Name = 'Standard Agreement (Benefit Amount) - Rate Per Tier';
        benefitAmountRatePerTierStandardAgreement.Apttus__Primary_Contact__c = primaryContact.Id;
        benefitAmountRatePerTierStandardAgreement.Apttus__Agreement_Category__c = 'Standard';
        benefitAmountRatePerTierStandardAgreement.Apttus_CMConfig__PriceListId__c = priceList.Id;
        benefitAmountRatePerTierStandardAgreement.Apttus_CMConfig__PricingDate__c = System.Today();
        benefitAmountRatePerTierStandardAgreement.Apttus__Account__c = acc.Id;
        benefitAmountRatePerTierStandardAgreement.APTS_Order_Non_Contracted_Products__c = true;
        benefitAmountRatePerTierStandardAgreement.APTS_Language__c = 'SAP_SV';*/
        Apttus__APTS_Agreement__c benefitAmountRatePerTierStandardAgreement = APTS_TestDataFactory.createAgreement(primaryContact.Id, priceList.Id, acc.Id, 'Standard Deal', 'Standard Agreement (Benefit Amount) - Rate Per Tier');
        benefitAmountRatePerTierStandardAgreement.APTS_Order_Non_Contracted_Products__c = true;
        benefitAmountRatePerTierStandardAgreement.APTS_Language__c = 'SAP_SV';
        agreements.add(benefitAmountRatePerTierStandardAgreement);

        /*Apttus__APTS_Agreement__c benefitperUnirRatePerTierStandardAgreement = new Apttus__APTS_Agreement__c();
        benefitperUnirRatePerTierStandardAgreement.recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
        benefitperUnirRatePerTierStandardAgreement.Name = 'Standard Agreement (Benefit per Unit) - Rate Per Tier';
        benefitperUnirRatePerTierStandardAgreement.Apttus__Primary_Contact__c = primaryContact.Id;
        benefitperUnirRatePerTierStandardAgreement.Apttus__Agreement_Category__c = 'Standard';
        benefitperUnirRatePerTierStandardAgreement.Apttus_CMConfig__PriceListId__c = priceList.Id;
        benefitperUnirRatePerTierStandardAgreement.Apttus_CMConfig__PricingDate__c = System.Today();
        benefitperUnirRatePerTierStandardAgreement.Apttus__Account__c = acc.Id;
        benefitperUnirRatePerTierStandardAgreement.APTS_Order_Non_Contracted_Products__c = true;
        benefitperUnirRatePerTierStandardAgreement.APTS_Language__c = 'SAP_DK';*/
        Apttus__APTS_Agreement__c benefitperUnirRatePerTierStandardAgreement = APTS_TestDataFactory.createAgreement(primaryContact.Id, priceList.Id, acc.Id, 'Standard Deal', 'Standard Agreement (Benefit per Unit) - Rate Per Tier');
        benefitperUnirRatePerTierStandardAgreement.APTS_Order_Non_Contracted_Products__c = true;
        benefitperUnirRatePerTierStandardAgreement.APTS_Language__c = 'SAP_DK';
        agreements.add(benefitperUnirRatePerTierStandardAgreement);

        /*Apttus__APTS_Agreement__c revenueStandardAgreement = new Apttus__APTS_Agreement__c();
        revenueStandardAgreement.recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
        revenueStandardAgreement.Name = 'Standard Agreement (Revenue)';
        revenueStandardAgreement.Apttus__Primary_Contact__c = primaryContact.Id;
        revenueStandardAgreement.Apttus__Agreement_Category__c = 'Standard';
        revenueStandardAgreement.Apttus_CMConfig__PriceListId__c = priceList.Id;
        revenueStandardAgreement.Apttus_CMConfig__PricingDate__c = System.Today();
        revenueStandardAgreement.Apttus__Account__c = acc.Id;
        revenueStandardAgreement.APTS_Order_Non_Contracted_Products__c = true;
        revenueStandardAgreement.APTS_Language__c = 'SAP_FR';*/
        Apttus__APTS_Agreement__c revenueStandardAgreement = APTS_TestDataFactory.createAgreement(primaryContact.Id, priceList.Id, acc.Id, 'Standard Deal', 'Standard Agreement (Revenue)');
        revenueStandardAgreement.APTS_Order_Non_Contracted_Products__c = true;
        revenueStandardAgreement.APTS_Language__c = 'SAP_FR';
        agreements.add(revenueStandardAgreement);

        /*Apttus__APTS_Agreement__c revenueStandardNetPriceAgreement = new Apttus__APTS_Agreement__c();
        revenueStandardNetPriceAgreement.recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
        revenueStandardNetPriceAgreement.Name = 'Standard Agreement (Revenue) - Net Price';
        revenueStandardNetPriceAgreement.Apttus__Primary_Contact__c = primaryContact.Id;
        revenueStandardNetPriceAgreement.Apttus__Agreement_Category__c = 'Standard';
        revenueStandardNetPriceAgreement.Apttus_CMConfig__PriceListId__c = priceList.Id;
        revenueStandardNetPriceAgreement.Apttus_CMConfig__PricingDate__c = System.Today();
        revenueStandardNetPriceAgreement.Apttus__Account__c = acc.Id;
        revenueStandardNetPriceAgreement.APTS_Order_Non_Contracted_Products__c = true;*/
        Apttus__APTS_Agreement__c revenueStandardNetPriceAgreement = APTS_TestDataFactory.createAgreement(primaryContact.Id, priceList.Id, acc.Id, 'Standard Deal', 'Standard Agreement (Revenue) - Net Price');
        revenueStandardNetPriceAgreement.APTS_Order_Non_Contracted_Products__c = true;
        agreements.add(revenueStandardNetPriceAgreement);

        /*Apttus__APTS_Agreement__c revenueRatePerTierStandardAgreement = new Apttus__APTS_Agreement__c();
        revenueRatePerTierStandardAgreement.recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
        revenueRatePerTierStandardAgreement.Name = 'Standard Agreement (Revenue) - Rate Per Tier';
        revenueRatePerTierStandardAgreement.Apttus__Primary_Contact__c = primaryContact.Id;
        revenueRatePerTierStandardAgreement.Apttus__Agreement_Category__c = 'Standard';
        revenueRatePerTierStandardAgreement.Apttus_CMConfig__PriceListId__c = priceList.Id;
        revenueRatePerTierStandardAgreement.Apttus_CMConfig__PricingDate__c = System.Today();
        revenueRatePerTierStandardAgreement.Apttus__Account__c = acc.Id;
        revenueRatePerTierStandardAgreement.APTS_Order_Non_Contracted_Products__c = true;*/
        Apttus__APTS_Agreement__c revenueRatePerTierStandardAgreement = APTS_TestDataFactory.createAgreement(primaryContact.Id, priceList.Id, acc.Id, 'Standard Deal', 'Standard Agreement (Revenue) - Rate Per Tier');
        revenueRatePerTierStandardAgreement.APTS_Order_Non_Contracted_Products__c = true;
        agreements.add(revenueRatePerTierStandardAgreement);

        /*Apttus__APTS_Agreement__c revenuePerTierStandardNetPriceAgreement = new Apttus__APTS_Agreement__c();
        revenuePerTierStandardNetPriceAgreement.recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
        revenuePerTierStandardNetPriceAgreement.Name = 'Standard Agreement (Revenue) - Net Price - Rate Per Tier';
        revenuePerTierStandardNetPriceAgreement.Apttus__Primary_Contact__c = primaryContact.Id;
        revenuePerTierStandardNetPriceAgreement.Apttus__Agreement_Category__c = 'Standard';
        revenuePerTierStandardNetPriceAgreement.Apttus_CMConfig__PriceListId__c = priceList.Id;
        revenuePerTierStandardNetPriceAgreement.Apttus_CMConfig__PricingDate__c = System.Today();
        revenuePerTierStandardNetPriceAgreement.Apttus__Account__c = acc.Id;
        revenuePerTierStandardNetPriceAgreement.APTS_Order_Non_Contracted_Products__c = true;*/
        Apttus__APTS_Agreement__c revenuePerTierStandardNetPriceAgreement = APTS_TestDataFactory.createAgreement(primaryContact.Id, priceList.Id, acc.Id, 'Standard Deal', 'Standard Agreement (Revenue) - Net Price - Rate Per Tier');
        revenuePerTierStandardNetPriceAgreement.APTS_Order_Non_Contracted_Products__c = true;
        agreements.add(revenuePerTierStandardNetPriceAgreement);

        /*Apttus__APTS_Agreement__c multipleIncentivesAgreement = new Apttus__APTS_Agreement__c();
        multipleIncentivesAgreement.recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
        multipleIncentivesAgreement.Name = 'Standard Agreement (Revenue) - Multiple Incentives';
        multipleIncentivesAgreement.Apttus__Primary_Contact__c = primaryContact.Id;
        multipleIncentivesAgreement.Apttus__Agreement_Category__c = 'Standard';
        multipleIncentivesAgreement.Apttus_CMConfig__PriceListId__c = priceList.Id;
        multipleIncentivesAgreement.Apttus_CMConfig__PricingDate__c = System.Today();
        multipleIncentivesAgreement.Apttus__Account__c = acc.Id;
        multipleIncentivesAgreement.APTS_Order_Non_Contracted_Products__c = true;*/
        Apttus__APTS_Agreement__c multipleIncentivesAgreement = APTS_TestDataFactory.createAgreement(primaryContact.Id, priceList.Id, acc.Id, 'Standard Deal', 'Standard Agreement (Revenue) - Multiple Incentives');
        multipleIncentivesAgreement.APTS_Order_Non_Contracted_Products__c = true;
        agreements.add(multipleIncentivesAgreement);

   		/*Apttus__APTS_Agreement__c comsumptionAgreement = new Apttus__APTS_Agreement__c();
        comsumptionAgreement.recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Consumption Model').getRecordTypeId();
        comsumptionAgreement.Name = 'Agreement';
        comsumptionAgreement.Apttus__Primary_Contact__c = primaryContact.Id;
        comsumptionAgreement.Apttus__Agreement_Category__c = 'Standard';
        comsumptionAgreement.Apttus_CMConfig__PriceListId__c = priceList.Id;
        comsumptionAgreement.Apttus_CMConfig__PricingDate__c = System.Today();
        comsumptionAgreement.Apttus__Account__c = acc.Id;
        comsumptionAgreement.APTS_Order_Non_Contracted_Products__c = true;*/
        Apttus__APTS_Agreement__c comsumptionAgreement = APTS_TestDataFactory.createAgreement(primaryContact.Id, priceList.Id, acc.Id, 'Consumption Model', 'Agreement');
        comsumptionAgreement.APTS_Order_Non_Contracted_Products__c = true;
        agreements.add(comsumptionAgreement);

        insert agreements;

        // Creation of incentives
        List<Apttus_Config2__Incentive__c> incentives = new List<Apttus_Config2__Incentive__c>();

        /*Apttus_Config2__Incentive__c benefitAmountStandardIncentive = new Apttus_Config2__Incentive__c();
        benefitAmountStandardIncentive.Apttus_CMConfig__AgreementId__c = benefitAmountStandardAgreement.Id;
        benefitAmountStandardIncentive.Apttus_Config2__Active__c = true;
        benefitAmountStandardIncentive.Apttus_Config2__Sequence__c = 1;
        incentives.add(benefitAmountStandardIncentive);*/
        
        Apttus_Config2__Incentive__c benefitAmountStandardIncentive = APTS_TestDataFactory.createIncentive(benefitAmountStandardAgreement);
        incentives.add(benefitAmountStandardIncentive);

        /*Apttus_Config2__Incentive__c benefitperUnitStandardIncentive = new Apttus_Config2__Incentive__c();
        benefitperUnitStandardIncentive.Apttus_CMConfig__AgreementId__c = benefitperUnitStandardAgreement.Id;
        benefitperUnitStandardIncentive.Apttus_Config2__Active__c = true;
        benefitperUnitStandardIncentive.Apttus_Config2__Sequence__c = 1;*/
        Apttus_Config2__Incentive__c benefitperUnitStandardIncentive = APTS_TestDataFactory.createIncentive(benefitperUnitStandardAgreement);
        incentives.add(benefitperUnitStandardIncentive);

        /*Apttus_Config2__Incentive__c benefitAmountRatePerTierStandardIncentive = new Apttus_Config2__Incentive__c();
        benefitAmountRatePerTierStandardIncentive.Apttus_CMConfig__AgreementId__c = benefitAmountRatePerTierStandardAgreement.Id;
        benefitAmountRatePerTierStandardIncentive.Apttus_Config2__Active__c = true;
        benefitAmountRatePerTierStandardIncentive.Apttus_Config2__Sequence__c = 1;*/
        Apttus_Config2__Incentive__c benefitAmountRatePerTierStandardIncentive = APTS_TestDataFactory.createIncentive(benefitAmountRatePerTierStandardAgreement);
        incentives.add(benefitAmountRatePerTierStandardIncentive);

        /*Apttus_Config2__Incentive__c benefitperUnitRatePerTierStandardIncentive = new Apttus_Config2__Incentive__c();
        benefitperUnitRatePerTierStandardIncentive.Apttus_CMConfig__AgreementId__c = benefitperUnirRatePerTierStandardAgreement.Id;
        benefitperUnitRatePerTierStandardIncentive.Apttus_Config2__Active__c = true;
        benefitperUnitRatePerTierStandardIncentive.Apttus_Config2__Sequence__c = 1;*/
        Apttus_Config2__Incentive__c benefitperUnitRatePerTierStandardIncentive = APTS_TestDataFactory.createIncentive(benefitperUnirRatePerTierStandardAgreement);
        incentives.add(benefitperUnitRatePerTierStandardIncentive);

        /*Apttus_Config2__Incentive__c revenueStandardIncentive = new Apttus_Config2__Incentive__c();
        revenueStandardIncentive.Apttus_CMConfig__AgreementId__c = revenueStandardAgreement.Id;
        revenueStandardIncentive.Apttus_Config2__Active__c = true;
        revenueStandardIncentive.Apttus_Config2__Sequence__c = 1;*/
        Apttus_Config2__Incentive__c revenueStandardIncentive = APTS_TestDataFactory.createIncentive(revenueStandardAgreement);
        incentives.add(revenueStandardIncentive);

        /*Apttus_Config2__Incentive__c revenueStandardNetPriceIncentive = new Apttus_Config2__Incentive__c();
        revenueStandardNetPriceIncentive.Apttus_CMConfig__AgreementId__c = revenueStandardNetPriceAgreement.Id;
        revenueStandardNetPriceIncentive.Apttus_Config2__Active__c = true;
        revenueStandardNetPriceIncentive.Apttus_Config2__Sequence__c = 1;*/
        Apttus_Config2__Incentive__c revenueStandardNetPriceIncentive = APTS_TestDataFactory.createIncentive(revenueStandardNetPriceAgreement);
        incentives.add(revenueStandardNetPriceIncentive);

        /*Apttus_Config2__Incentive__c revenueRatePerTierStandardIncentive = new Apttus_Config2__Incentive__c();
        revenueRatePerTierStandardIncentive.Apttus_CMConfig__AgreementId__c = revenueRatePerTierStandardAgreement.Id;
        revenueRatePerTierStandardIncentive.Apttus_Config2__Active__c = true;
        revenueRatePerTierStandardIncentive.Apttus_Config2__Sequence__c = 1;*/
        Apttus_Config2__Incentive__c revenueRatePerTierStandardIncentive = APTS_TestDataFactory.createIncentive(revenueRatePerTierStandardAgreement);
        incentives.add(revenueRatePerTierStandardIncentive);

        /*Apttus_Config2__Incentive__c revenueRatePerTierStandardNetPriceIncentive = new Apttus_Config2__Incentive__c();
        revenueRatePerTierStandardNetPriceIncentive.Apttus_CMConfig__AgreementId__c = revenuePerTierStandardNetPriceAgreement.Id;
        revenueRatePerTierStandardNetPriceIncentive.Apttus_Config2__Active__c = true;
        revenueRatePerTierStandardNetPriceIncentive.Apttus_Config2__Sequence__c = 1;*/
        Apttus_Config2__Incentive__c revenueRatePerTierStandardNetPriceIncentive = APTS_TestDataFactory.createIncentive(revenuePerTierStandardNetPriceAgreement);
        incentives.add(revenueRatePerTierStandardNetPriceIncentive);


        /*Apttus_Config2__Incentive__c multipleIncentivesIncentive1 = new Apttus_Config2__Incentive__c();
        multipleIncentivesIncentive1.Apttus_CMConfig__AgreementId__c = multipleIncentivesAgreement.Id;
        multipleIncentivesIncentive1.Apttus_Config2__Active__c = true;
        multipleIncentivesIncentive1.Apttus_Config2__Sequence__c = 1;*/
        Apttus_Config2__Incentive__c multipleIncentivesIncentive1 = APTS_TestDataFactory.createIncentive(multipleIncentivesAgreement);
        incentives.add(multipleIncentivesIncentive1);

        /*Apttus_Config2__Incentive__c multipleIncentivesIncentive2 = new Apttus_Config2__Incentive__c();
        multipleIncentivesIncentive2.Apttus_CMConfig__AgreementId__c = multipleIncentivesAgreement.Id;
        multipleIncentivesIncentive2.Apttus_Config2__Active__c = true;
        multipleIncentivesIncentive2.Apttus_Config2__Sequence__c = 1;*/
        Apttus_Config2__Incentive__c multipleIncentivesIncentive2 = APTS_TestDataFactory.createIncentive(multipleIncentivesAgreement);
        incentives.add(multipleIncentivesIncentive2);

        insert incentives;

        // Creation of rulesets
        List<Apttus_Config2__PriceRuleset__c> rulesets = new List<Apttus_Config2__PriceRuleset__c>();

        //Apttus_Config2__PriceRuleset__c benefitAmountStandardRuleSet = new Apttus_Config2__PriceRuleset__c();
        //benefitAmountStandardRuleSet.Apttus_Config2__IncentiveId__c = benefitAmountStandardIncentive.Id;
        //benefitAmountStandardRuleSet.Apttus_Config2__Sequence__c = 1;
        //benefitAmountStandardRuleSet.Apttus_Config2__Criteria__c = '{"sObjectName" : "Apttus_Config2__OrderLineItem__c","sObjectLabel" : "Apttus_Config2__OrderLineItem__c",	"searchText" : null, "filter" : {"predicates" : [ {	"RowNum" : 1,"RHSSObjectName" : null,"RHSFieldType" : null,"RHSFieldName" : " ","RHSFieldLabel" : null,	"RHSChildFilterName" : "","RefFieldName" : null,"OffsetValue" : null,"LHSSObjectName" : "Apttus_Config2__OrderLineItem__c","LHSChildFilterName" : null,	"FieldValue" : " +' + categoryHierarchy.Id + '","FieldType" : "REFERENCE","FieldName" : "Apttus_Config2__ClassificationId__c","FieldLabel" : "Category","CompOper" : "equal to","BoolOper" : null} ],"hasRHSFields" : false,	"condExpr" : "1 ",	"childFilter" : null},	"fields" : [ "Apttus_Config2__ClassificationId__c" ],	"exprStr" : "(Category = ' + categoryHierarchy.Id + ') "}';
        Apttus_Config2__PriceRuleset__c benefitAmountStandardRuleSet = APTS_TestDataFactory.createPriceRuleSet(benefitAmountStandardIncentive);
        benefitAmountStandardRuleSet.Apttus_Config2__Criteria__c = '{"sObjectName" : "Apttus_Config2__OrderLineItem__c","sObjectLabel" : "Apttus_Config2__OrderLineItem__c",	"searchText" : null, "filter" : {"predicates" : [ {	"RowNum" : 1,"RHSSObjectName" : null,"RHSFieldType" : null,"RHSFieldName" : " ","RHSFieldLabel" : null,	"RHSChildFilterName" : "","RefFieldName" : null,"OffsetValue" : null,"LHSSObjectName" : "Apttus_Config2__OrderLineItem__c","LHSChildFilterName" : null,	"FieldValue" : " +' + categoryHierarchy.Id + '","FieldType" : "REFERENCE","FieldName" : "Apttus_Config2__ClassificationId__c","FieldLabel" : "Category","CompOper" : "equal to","BoolOper" : null} ],"hasRHSFields" : false,	"condExpr" : "1 ",	"childFilter" : null},	"fields" : [ "Apttus_Config2__ClassificationId__c" ],	"exprStr" : "(Category = ' + categoryHierarchy.Id + ') "}';
        rulesets.add(benefitAmountStandardRuleSet);

        /*Apttus_Config2__PriceRuleset__c benefitperUnitStandardRuleSet = new Apttus_Config2__PriceRuleset__c();
        benefitperUnitStandardRuleSet.Apttus_Config2__IncentiveId__c = benefitperUnitStandardIncentive.Id;
        benefitperUnitStandardRuleSet.Apttus_Config2__Sequence__c = 1;
        benefitperUnitStandardRuleSet.Apttus_Config2__Criteria__c = '{"sObjectName" : "Apttus_Config2__OrderLineItem__c","sObjectLabel" : "Apttus_Config2__OrderLineItem__c",	"searchText" : null, "filter" : {"predicates" : [ {	"RowNum" : 1,"RHSSObjectName" : null,"RHSFieldType" : null,"RHSFieldName" : " ","RHSFieldLabel" : null,	"RHSChildFilterName" : "","RefFieldName" : null,"OffsetValue" : null,"LHSSObjectName" : "Apttus_Config2__OrderLineItem__c","LHSChildFilterName" : null,	"FieldValue" : " +' + categoryHierarchy.Id + '","FieldType" : "REFERENCE","FieldName" : "Apttus_Config2__ClassificationId__c","FieldLabel" : "Category","CompOper" : "equal to","BoolOper" : null} ],"hasRHSFields" : false,	"condExpr" : "1 ",	"childFilter" : null},	"fields" : [ "Apttus_Config2__ClassificationId__c" ],	"exprStr" : "(Category = ' + categoryHierarchy.Id + ') "}';
        rulesets.add(benefitperUnitStandardRuleSet);*/
        Apttus_Config2__PriceRuleset__c benefitperUnitStandardRuleSet = APTS_TestDataFactory.createPriceRuleSet(benefitperUnitStandardIncentive);
        benefitperUnitStandardRuleSet.Apttus_Config2__Criteria__c = '{"sObjectName" : "Apttus_Config2__OrderLineItem__c","sObjectLabel" : "Apttus_Config2__OrderLineItem__c",	"searchText" : null, "filter" : {"predicates" : [ {	"RowNum" : 1,"RHSSObjectName" : null,"RHSFieldType" : null,"RHSFieldName" : " ","RHSFieldLabel" : null,	"RHSChildFilterName" : "","RefFieldName" : null,"OffsetValue" : null,"LHSSObjectName" : "Apttus_Config2__OrderLineItem__c","LHSChildFilterName" : null,	"FieldValue" : " +' + categoryHierarchy.Id + '","FieldType" : "REFERENCE","FieldName" : "Apttus_Config2__ClassificationId__c","FieldLabel" : "Category","CompOper" : "equal to","BoolOper" : null} ],"hasRHSFields" : false,	"condExpr" : "1 ",	"childFilter" : null},	"fields" : [ "Apttus_Config2__ClassificationId__c" ],	"exprStr" : "(Category = ' + categoryHierarchy.Id + ') "}';
        rulesets.add(benefitperUnitStandardRuleSet);

        /*Apttus_Config2__PriceRuleset__c benefitAmountRatePerTierStandardRuleSet = new Apttus_Config2__PriceRuleset__c();
        benefitAmountRatePerTierStandardRuleSet.Apttus_Config2__IncentiveId__c = benefitAmountRatePerTierStandardIncentive.Id;
        benefitAmountRatePerTierStandardRuleSet.Apttus_Config2__Sequence__c = 1;
        benefitAmountRatePerTierStandardRuleSet.Apttus_Config2__Criteria__c = '{"sObjectName" : "Apttus_Config2__OrderLineItem__c","sObjectLabel" : "Apttus_Config2__OrderLineItem__c",	"searchText" : null, "filter" : {"predicates" : [ {	"RowNum" : 1,"RHSSObjectName" : null,"RHSFieldType" : null,"RHSFieldName" : " ","RHSFieldLabel" : null,	"RHSChildFilterName" : "","RefFieldName" : null,"OffsetValue" : null,"LHSSObjectName" : "Apttus_Config2__OrderLineItem__c","LHSChildFilterName" : null,	"FieldValue" : " +' + categoryHierarchy.Id + '","FieldType" : "REFERENCE","FieldName" : "Apttus_Config2__ClassificationId__c","FieldLabel" : "Category","CompOper" : "equal to","BoolOper" : null} ],"hasRHSFields" : false,	"condExpr" : "1 ",	"childFilter" : null},	"fields" : [ "Apttus_Config2__ClassificationId__c" ],	"exprStr" : "(Category = ' + categoryHierarchy.Id + ') "}';
        rulesets.add(benefitAmountRatePerTierStandardRuleSet);*/
        Apttus_Config2__PriceRuleset__c benefitAmountRatePerTierStandardRuleSet = APTS_TestDataFactory.createPriceRuleSet(benefitAmountRatePerTierStandardIncentive);
        benefitAmountRatePerTierStandardRuleSet.Apttus_Config2__Criteria__c = '{"sObjectName" : "Apttus_Config2__OrderLineItem__c","sObjectLabel" : "Apttus_Config2__OrderLineItem__c",	"searchText" : null, "filter" : {"predicates" : [ {	"RowNum" : 1,"RHSSObjectName" : null,"RHSFieldType" : null,"RHSFieldName" : " ","RHSFieldLabel" : null,	"RHSChildFilterName" : "","RefFieldName" : null,"OffsetValue" : null,"LHSSObjectName" : "Apttus_Config2__OrderLineItem__c","LHSChildFilterName" : null,	"FieldValue" : " +' + categoryHierarchy.Id + '","FieldType" : "REFERENCE","FieldName" : "Apttus_Config2__ClassificationId__c","FieldLabel" : "Category","CompOper" : "equal to","BoolOper" : null} ],"hasRHSFields" : false,	"condExpr" : "1 ",	"childFilter" : null},	"fields" : [ "Apttus_Config2__ClassificationId__c" ],	"exprStr" : "(Category = ' + categoryHierarchy.Id + ') "}';
        rulesets.add(benefitAmountRatePerTierStandardRuleSet);

        /*Apttus_Config2__PriceRuleset__c benefitperUnitRatePerTierStandardRuleSet = new Apttus_Config2__PriceRuleset__c();
        benefitperUnitRatePerTierStandardRuleSet.Apttus_Config2__IncentiveId__c = benefitperUnitRatePerTierStandardIncentive.Id;
        benefitperUnitRatePerTierStandardRuleSet.Apttus_Config2__Sequence__c = 1;
        benefitperUnitRatePerTierStandardRuleSet.Apttus_Config2__Criteria__c = '{"sObjectName" : "Apttus_Config2__OrderLineItem__c","sObjectLabel" : "Apttus_Config2__OrderLineItem__c",	"searchText" : null, "filter" : {"predicates" : [ {	"RowNum" : 1,"RHSSObjectName" : null,"RHSFieldType" : null,"RHSFieldName" : " ","RHSFieldLabel" : null,	"RHSChildFilterName" : "","RefFieldName" : null,"OffsetValue" : null,"LHSSObjectName" : "Apttus_Config2__OrderLineItem__c","LHSChildFilterName" : null,	"FieldValue" : " +' + categoryHierarchy.Id + '","FieldType" : "REFERENCE","FieldName" : "Apttus_Config2__ClassificationId__c","FieldLabel" : "Category","CompOper" : "equal to","BoolOper" : null} ],"hasRHSFields" : false,	"condExpr" : "1 ",	"childFilter" : null},	"fields" : [ "Apttus_Config2__ClassificationId__c" ],	"exprStr" : "(Category = ' + categoryHierarchy.Id + ') "}';
        rulesets.add(benefitperUnitRatePerTierStandardRuleSet);*/
        Apttus_Config2__PriceRuleset__c benefitperUnitRatePerTierStandardRuleSet = APTS_TestDataFactory.createPriceRuleSet(benefitperUnitRatePerTierStandardIncentive);
        benefitperUnitRatePerTierStandardRuleSet.Apttus_Config2__Criteria__c = '{"sObjectName" : "Apttus_Config2__OrderLineItem__c","sObjectLabel" : "Apttus_Config2__OrderLineItem__c",	"searchText" : null, "filter" : {"predicates" : [ {	"RowNum" : 1,"RHSSObjectName" : null,"RHSFieldType" : null,"RHSFieldName" : " ","RHSFieldLabel" : null,	"RHSChildFilterName" : "","RefFieldName" : null,"OffsetValue" : null,"LHSSObjectName" : "Apttus_Config2__OrderLineItem__c","LHSChildFilterName" : null,	"FieldValue" : " +' + categoryHierarchy.Id + '","FieldType" : "REFERENCE","FieldName" : "Apttus_Config2__ClassificationId__c","FieldLabel" : "Category","CompOper" : "equal to","BoolOper" : null} ],"hasRHSFields" : false,	"condExpr" : "1 ",	"childFilter" : null},	"fields" : [ "Apttus_Config2__ClassificationId__c" ],	"exprStr" : "(Category = ' + categoryHierarchy.Id + ') "}';
        rulesets.add(benefitperUnitRatePerTierStandardRuleSet);


        /*Apttus_Config2__PriceRuleset__c revenueStandardRuleSet = new Apttus_Config2__PriceRuleset__c();
        revenueStandardRuleSet.Apttus_Config2__IncentiveId__c = revenueStandardIncentive.Id;
        revenueStandardRuleSet.Apttus_Config2__Sequence__c = 1;
        revenueStandardRuleSet.Apttus_Config2__Criteria__c = '{"sObjectName" : "Apttus_Config2__OrderLineItem__c","sObjectLabel" : "Apttus_Config2__OrderLineItem__c",	"searchText" : null, "filter" : {"predicates" : [ {	"RowNum" : 1,"RHSSObjectName" : null,"RHSFieldType" : null,"RHSFieldName" : " ","RHSFieldLabel" : null,	"RHSChildFilterName" : "","RefFieldName" : null,"OffsetValue" : null,"LHSSObjectName" : "Apttus_Config2__OrderLineItem__c","LHSChildFilterName" : null,	"FieldValue" : " +' + categoryHierarchy.Id + '","FieldType" : "REFERENCE","FieldName" : "Apttus_Config2__ClassificationId__c","FieldLabel" : "Category","CompOper" : "equal to","BoolOper" : null} ],"hasRHSFields" : false,	"condExpr" : "1 ",	"childFilter" : null},	"fields" : [ "Apttus_Config2__ClassificationId__c" ],	"exprStr" : "(Category = ' + categoryHierarchy.Id + ') "}';
        rulesets.add(revenueStandardRuleSet);*/
		Apttus_Config2__PriceRuleset__c revenueStandardRuleSet = APTS_TestDataFactory.createPriceRuleSet(revenueStandardIncentive);
        revenueStandardRuleSet.Apttus_Config2__Criteria__c = '{"sObjectName" : "Apttus_Config2__OrderLineItem__c","sObjectLabel" : "Apttus_Config2__OrderLineItem__c",	"searchText" : null, "filter" : {"predicates" : [ {	"RowNum" : 1,"RHSSObjectName" : null,"RHSFieldType" : null,"RHSFieldName" : " ","RHSFieldLabel" : null,	"RHSChildFilterName" : "","RefFieldName" : null,"OffsetValue" : null,"LHSSObjectName" : "Apttus_Config2__OrderLineItem__c","LHSChildFilterName" : null,	"FieldValue" : " +' + categoryHierarchy.Id + '","FieldType" : "REFERENCE","FieldName" : "Apttus_Config2__ClassificationId__c","FieldLabel" : "Category","CompOper" : "equal to","BoolOper" : null} ],"hasRHSFields" : false,	"condExpr" : "1 ",	"childFilter" : null},	"fields" : [ "Apttus_Config2__ClassificationId__c" ],	"exprStr" : "(Category = ' + categoryHierarchy.Id + ') "}';
        rulesets.add(revenueStandardRuleSet);
        
        /*Apttus_Config2__PriceRuleset__c revenueStandardNetPriceRuleSet = new Apttus_Config2__PriceRuleset__c();
        revenueStandardNetPriceRuleSet.Apttus_Config2__IncentiveId__c = revenueStandardNetPriceIncentive.Id;
        revenueStandardNetPriceRuleSet.Apttus_Config2__Sequence__c = 1;
        revenueStandardNetPriceRuleSet.Apttus_Config2__Criteria__c = '{"sObjectName" : "Apttus_Config2__OrderLineItem__c","sObjectLabel" : "Apttus_Config2__OrderLineItem__c",	"searchText" : null, "filter" : {"predicates" : [ {	"RowNum" : 1,"RHSSObjectName" : null,"RHSFieldType" : null,"RHSFieldName" : " ","RHSFieldLabel" : null,	"RHSChildFilterName" : "","RefFieldName" : null,"OffsetValue" : null,"LHSSObjectName" : "Apttus_Config2__OrderLineItem__c","LHSChildFilterName" : null,	"FieldValue" : " +' + categoryHierarchy.Id + '","FieldType" : "REFERENCE","FieldName" : "Apttus_Config2__ClassificationId__c","FieldLabel" : "Category","CompOper" : "equal to","BoolOper" : null} ],"hasRHSFields" : false,	"condExpr" : "1 ",	"childFilter" : null},	"fields" : [ "Apttus_Config2__ClassificationId__c" ],	"exprStr" : "(Category = ' + categoryHierarchy.Id + ') "}';
        rulesets.add(revenueStandardNetPriceRuleSet);*/
        Apttus_Config2__PriceRuleset__c revenueStandardNetPriceRuleSet = APTS_TestDataFactory.createPriceRuleSet(revenueStandardNetPriceIncentive);
        revenueStandardNetPriceRuleSet.Apttus_Config2__Criteria__c = '{"sObjectName" : "Apttus_Config2__OrderLineItem__c","sObjectLabel" : "Apttus_Config2__OrderLineItem__c",	"searchText" : null, "filter" : {"predicates" : [ {	"RowNum" : 1,"RHSSObjectName" : null,"RHSFieldType" : null,"RHSFieldName" : " ","RHSFieldLabel" : null,	"RHSChildFilterName" : "","RefFieldName" : null,"OffsetValue" : null,"LHSSObjectName" : "Apttus_Config2__OrderLineItem__c","LHSChildFilterName" : null,	"FieldValue" : " +' + categoryHierarchy.Id + '","FieldType" : "REFERENCE","FieldName" : "Apttus_Config2__ClassificationId__c","FieldLabel" : "Category","CompOper" : "equal to","BoolOper" : null} ],"hasRHSFields" : false,	"condExpr" : "1 ",	"childFilter" : null},	"fields" : [ "Apttus_Config2__ClassificationId__c" ],	"exprStr" : "(Category = ' + categoryHierarchy.Id + ') "}';
        rulesets.add(revenueStandardNetPriceRuleSet);

        /*Apttus_Config2__PriceRuleset__c revenueRatePerTierStandardRuleSet = new Apttus_Config2__PriceRuleset__c();
        revenueRatePerTierStandardRuleSet.Apttus_Config2__IncentiveId__c = revenueRatePerTierStandardIncentive.Id;
        revenueRatePerTierStandardRuleSet.Apttus_Config2__Sequence__c = 1;
        revenueRatePerTierStandardRuleSet.Apttus_Config2__Criteria__c = '{"sObjectName" : "Apttus_Config2__OrderLineItem__c","sObjectLabel" : "Apttus_Config2__OrderLineItem__c",	"searchText" : null, "filter" : {"predicates" : [ {	"RowNum" : 1,"RHSSObjectName" : null,"RHSFieldType" : null,"RHSFieldName" : " ","RHSFieldLabel" : null,	"RHSChildFilterName" : "","RefFieldName" : null,"OffsetValue" : null,"LHSSObjectName" : "Apttus_Config2__OrderLineItem__c","LHSChildFilterName" : null,	"FieldValue" : " +' + categoryHierarchy.Id + '","FieldType" : "REFERENCE","FieldName" : "Apttus_Config2__ClassificationId__c","FieldLabel" : "Category","CompOper" : "equal to","BoolOper" : null} ],"hasRHSFields" : false,	"condExpr" : "1 ",	"childFilter" : null},	"fields" : [ "Apttus_Config2__ClassificationId__c" ],	"exprStr" : "(Category = ' + categoryHierarchy.Id + ') "}';
        rulesets.add(revenueRatePerTierStandardRuleSet);*/
        Apttus_Config2__PriceRuleset__c revenueRatePerTierStandardRuleSet = APTS_TestDataFactory.createPriceRuleSet(revenueRatePerTierStandardIncentive);
        revenueRatePerTierStandardRuleSet.Apttus_Config2__Criteria__c = '{"sObjectName" : "Apttus_Config2__OrderLineItem__c","sObjectLabel" : "Apttus_Config2__OrderLineItem__c",	"searchText" : null, "filter" : {"predicates" : [ {	"RowNum" : 1,"RHSSObjectName" : null,"RHSFieldType" : null,"RHSFieldName" : " ","RHSFieldLabel" : null,	"RHSChildFilterName" : "","RefFieldName" : null,"OffsetValue" : null,"LHSSObjectName" : "Apttus_Config2__OrderLineItem__c","LHSChildFilterName" : null,	"FieldValue" : " +' + categoryHierarchy.Id + '","FieldType" : "REFERENCE","FieldName" : "Apttus_Config2__ClassificationId__c","FieldLabel" : "Category","CompOper" : "equal to","BoolOper" : null} ],"hasRHSFields" : false,	"condExpr" : "1 ",	"childFilter" : null},	"fields" : [ "Apttus_Config2__ClassificationId__c" ],	"exprStr" : "(Category = ' + categoryHierarchy.Id + ') "}';
        rulesets.add(revenueRatePerTierStandardRuleSet);

        /*Apttus_Config2__PriceRuleset__c revenueRatePerTierStandardNetPriceRuleSet = new Apttus_Config2__PriceRuleset__c();
        revenueRatePerTierStandardNetPriceRuleSet.Apttus_Config2__IncentiveId__c = revenueRatePerTierStandardNetPriceIncentive.Id;
        revenueRatePerTierStandardNetPriceRuleSet.Apttus_Config2__Sequence__c = 1;
        revenueRatePerTierStandardNetPriceRuleSet.Apttus_Config2__Criteria__c = '{"sObjectName" : "Apttus_Config2__OrderLineItem__c","sObjectLabel" : "Apttus_Config2__OrderLineItem__c",	"searchText" : null, "filter" : {"predicates" : [ {	"RowNum" : 1,"RHSSObjectName" : null,"RHSFieldType" : null,"RHSFieldName" : " ","RHSFieldLabel" : null,	"RHSChildFilterName" : "","RefFieldName" : null,"OffsetValue" : null,"LHSSObjectName" : "Apttus_Config2__OrderLineItem__c","LHSChildFilterName" : null,	"FieldValue" : " +' + categoryHierarchy.Id + '","FieldType" : "REFERENCE","FieldName" : "Apttus_Config2__ClassificationId__c","FieldLabel" : "Category","CompOper" : "equal to","BoolOper" : null} ],"hasRHSFields" : false,	"condExpr" : "1 ",	"childFilter" : null},	"fields" : [ "Apttus_Config2__ClassificationId__c" ],	"exprStr" : "(Category = ' + categoryHierarchy.Id + ') "}';
        rulesets.add(revenueRatePerTierStandardNetPriceRuleSet);*/
        Apttus_Config2__PriceRuleset__c revenueRatePerTierStandardNetPriceRuleSet = APTS_TestDataFactory.createPriceRuleSet(revenueRatePerTierStandardNetPriceIncentive);
        revenueRatePerTierStandardNetPriceRuleSet.Apttus_Config2__Criteria__c = '{"sObjectName" : "Apttus_Config2__OrderLineItem__c","sObjectLabel" : "Apttus_Config2__OrderLineItem__c",	"searchText" : null, "filter" : {"predicates" : [ {	"RowNum" : 1,"RHSSObjectName" : null,"RHSFieldType" : null,"RHSFieldName" : " ","RHSFieldLabel" : null,	"RHSChildFilterName" : "","RefFieldName" : null,"OffsetValue" : null,"LHSSObjectName" : "Apttus_Config2__OrderLineItem__c","LHSChildFilterName" : null,	"FieldValue" : " +' + categoryHierarchy.Id + '","FieldType" : "REFERENCE","FieldName" : "Apttus_Config2__ClassificationId__c","FieldLabel" : "Category","CompOper" : "equal to","BoolOper" : null} ],"hasRHSFields" : false,	"condExpr" : "1 ",	"childFilter" : null},	"fields" : [ "Apttus_Config2__ClassificationId__c" ],	"exprStr" : "(Category = ' + categoryHierarchy.Id + ') "}';
        rulesets.add(revenueRatePerTierStandardNetPriceRuleSet);

        /*Apttus_Config2__PriceRuleset__c multipleIncentivesPriceRuleSet1 = new Apttus_Config2__PriceRuleset__c();
        multipleIncentivesPriceRuleSet1.Apttus_Config2__IncentiveId__c = multipleIncentivesIncentive1.Id;
        multipleIncentivesPriceRuleSet1.Apttus_Config2__Sequence__c = 1;
        multipleIncentivesPriceRuleSet1.Apttus_Config2__Criteria__c = '{"sObjectName" : "Apttus_Config2__OrderLineItem__c","sObjectLabel" : "Apttus_Config2__OrderLineItem__c",   "searchText" : null, "filter" : {"predicates" : [ { "RowNum" : 1,"RHSSObjectName" : null,"RHSFieldType" : null,"RHSFieldName" : " ","RHSFieldLabel" : null, "RHSChildFilterName" : "","RefFieldName" : null,"OffsetValue" : null,"LHSSObjectName" : "Apttus_Config2__OrderLineItem__c","LHSChildFilterName" : null, "FieldValue" : " +' + categoryHierarchy.Id + '","FieldType" : "REFERENCE","FieldName" : "Apttus_Config2__ClassificationId__c","FieldLabel" : "Category","CompOper" : "equal to","BoolOper" : null} ],"hasRHSFields" : false,    "condExpr" : "1 ",  "childFilter" : null},  "fields" : [ "Apttus_Config2__ClassificationId__c" ],   "exprStr" : "(Category = ' + categoryHierarchy.Id + ') "}';
        rulesets.add(multipleIncentivesPriceRuleSet1);*/
        Apttus_Config2__PriceRuleset__c multipleIncentivesPriceRuleSet1 = APTS_TestDataFactory.createPriceRuleSet(multipleIncentivesIncentive1);
        multipleIncentivesPriceRuleSet1.Apttus_Config2__Criteria__c = '{"sObjectName" : "Apttus_Config2__OrderLineItem__c","sObjectLabel" : "Apttus_Config2__OrderLineItem__c",	"searchText" : null, "filter" : {"predicates" : [ {	"RowNum" : 1,"RHSSObjectName" : null,"RHSFieldType" : null,"RHSFieldName" : " ","RHSFieldLabel" : null,	"RHSChildFilterName" : "","RefFieldName" : null,"OffsetValue" : null,"LHSSObjectName" : "Apttus_Config2__OrderLineItem__c","LHSChildFilterName" : null,	"FieldValue" : " +' + categoryHierarchy.Id + '","FieldType" : "REFERENCE","FieldName" : "Apttus_Config2__ClassificationId__c","FieldLabel" : "Category","CompOper" : "equal to","BoolOper" : null} ],"hasRHSFields" : false,	"condExpr" : "1 ",	"childFilter" : null},	"fields" : [ "Apttus_Config2__ClassificationId__c" ],	"exprStr" : "(Category = ' + categoryHierarchy.Id + ') "}';
        rulesets.add(multipleIncentivesPriceRuleSet1);

        /*Apttus_Config2__PriceRuleset__c multipleIncentivesPriceRuleSet2 = new Apttus_Config2__PriceRuleset__c();
        multipleIncentivesPriceRuleSet2.Apttus_Config2__IncentiveId__c = multipleIncentivesIncentive2.Id;
        multipleIncentivesPriceRuleSet2.Apttus_Config2__Sequence__c = 1;
        multipleIncentivesPriceRuleSet2.Apttus_Config2__Criteria__c = '{"sObjectName" : "Apttus_Config2__OrderLineItem__c","sObjectLabel" : "Apttus_Config2__OrderLineItem__c",   "searchText" : null, "filter" : {"predicates" : [ { "RowNum" : 1,"RHSSObjectName" : null,"RHSFieldType" : null,"RHSFieldName" : " ","RHSFieldLabel" : null, "RHSChildFilterName" : "","RefFieldName" : null,"OffsetValue" : null,"LHSSObjectName" : "Apttus_Config2__OrderLineItem__c","LHSChildFilterName" : null, "FieldValue" : " +' + categoryHierarchy.Id + '","FieldType" : "REFERENCE","FieldName" : "Apttus_Config2__ClassificationId__c","FieldLabel" : "Category","CompOper" : "equal to","BoolOper" : null} ],"hasRHSFields" : false,    "condExpr" : "1 ",  "childFilter" : null},  "fields" : [ "Apttus_Config2__ClassificationId__c" ],   "exprStr" : "(Category = ' + categoryHierarchy.Id + ') "}';
        rulesets.add(multipleIncentivesPriceRuleSet2);*/
        Apttus_Config2__PriceRuleset__c multipleIncentivesPriceRuleSet2 = APTS_TestDataFactory.createPriceRuleSet(multipleIncentivesIncentive2);
        multipleIncentivesPriceRuleSet2.Apttus_Config2__Criteria__c = '{"sObjectName" : "Apttus_Config2__OrderLineItem__c","sObjectLabel" : "Apttus_Config2__OrderLineItem__c",	"searchText" : null, "filter" : {"predicates" : [ {	"RowNum" : 1,"RHSSObjectName" : null,"RHSFieldType" : null,"RHSFieldName" : " ","RHSFieldLabel" : null,	"RHSChildFilterName" : "","RefFieldName" : null,"OffsetValue" : null,"LHSSObjectName" : "Apttus_Config2__OrderLineItem__c","LHSChildFilterName" : null,	"FieldValue" : " +' + categoryHierarchy.Id + '","FieldType" : "REFERENCE","FieldName" : "Apttus_Config2__ClassificationId__c","FieldLabel" : "Category","CompOper" : "equal to","BoolOper" : null} ],"hasRHSFields" : false,	"condExpr" : "1 ",	"childFilter" : null},	"fields" : [ "Apttus_Config2__ClassificationId__c" ],	"exprStr" : "(Category = ' + categoryHierarchy.Id + ') "}';
        rulesets.add(multipleIncentivesPriceRuleSet2);
        
        insert rulesets;

        // Creation of Price Rules
        List<Apttus_Config2__PriceRule__c> priceRules = new List<Apttus_Config2__PriceRule__c>();

        /*Apttus_Config2__PriceRule__c benefitAmountStandardPriceRule = new Apttus_Config2__PriceRule__c();
        benefitAmountStandardPriceRule.Apttus_Config2__RulesetId__c = benefitAmountStandardRuleSet.Id;
        benefitAmountStandardPriceRule.Apttus_Config2__Sequence__c = 1;
        benefitAmountStandardPriceRule.Apttus_Config2__TierMetricType__c = VOLUME;
        benefitAmountStandardPriceRule.Apttus_Config2__Dimension4ValueType__c=HIGHRATETIER;*/
        Apttus_Config2__PriceRule__c benefitAmountStandardPriceRule = APTS_TestDataFactory.createPriceRule(benefitAmountStandardRuleSet);
        benefitAmountStandardPriceRule.Apttus_Config2__TierMetricType__c = VOLUME;
        benefitAmountStandardPriceRule.Apttus_Config2__Dimension4ValueType__c=HIGHRATETIER;
        priceRules.add(benefitAmountStandardPriceRule);

        /*Apttus_Config2__PriceRule__c benefitperUnitStandardPriceRule = new Apttus_Config2__PriceRule__c();
        benefitperUnitStandardPriceRule.Apttus_Config2__RulesetId__c = benefitperUnitStandardRuleSet.Id;
        benefitperUnitStandardPriceRule.Apttus_Config2__Sequence__c = 1;
        benefitperUnitStandardPriceRule.Apttus_Config2__TierMetricType__c = VOLUME;
        benefitperUnitStandardPriceRule.Apttus_Config2__Dimension4ValueType__c=HIGHRATETIER;*/
        Apttus_Config2__PriceRule__c benefitperUnitStandardPriceRule = APTS_TestDataFactory.createPriceRule(benefitperUnitStandardRuleSet);
        benefitperUnitStandardPriceRule.Apttus_Config2__TierMetricType__c = VOLUME;
        benefitperUnitStandardPriceRule.Apttus_Config2__Dimension4ValueType__c=HIGHRATETIER;
        priceRules.add(benefitperUnitStandardPriceRule);

        /*Apttus_Config2__PriceRule__c benefitAmountRatePerTierStandardPriceRule = new Apttus_Config2__PriceRule__c();
        benefitAmountRatePerTierStandardPriceRule.Apttus_Config2__RulesetId__c = benefitAmountRatePerTierStandardRuleSet.Id;
        benefitAmountRatePerTierStandardPriceRule.Apttus_Config2__Sequence__c = 1;
        benefitAmountRatePerTierStandardPriceRule.Apttus_Config2__TierMetricType__c = VOLUME;
        benefitAmountRatePerTierStandardPriceRule.Apttus_Config2__Dimension4ValueType__c=RATEPERTIER;*/
        Apttus_Config2__PriceRule__c benefitAmountRatePerTierStandardPriceRule = APTS_TestDataFactory.createPriceRule(benefitAmountRatePerTierStandardRuleSet);
        benefitAmountRatePerTierStandardPriceRule.Apttus_Config2__TierMetricType__c = VOLUME;
        benefitAmountRatePerTierStandardPriceRule.Apttus_Config2__Dimension4ValueType__c=RATEPERTIER;
        priceRules.add(benefitAmountRatePerTierStandardPriceRule);

        /*Apttus_Config2__PriceRule__c benefitperUnitRatePerTierStandardPriceRule = new Apttus_Config2__PriceRule__c();
        benefitperUnitRatePerTierStandardPriceRule.Apttus_Config2__RulesetId__c = benefitperUnitRatePerTierStandardRuleSet.Id;
        benefitperUnitRatePerTierStandardPriceRule.Apttus_Config2__Sequence__c = 1;
        benefitperUnitRatePerTierStandardPriceRule.Apttus_Config2__TierMetricType__c = VOLUME;
        benefitperUnitRatePerTierStandardPriceRule.Apttus_Config2__Dimension4ValueType__c=RATEPERTIER;*/
        Apttus_Config2__PriceRule__c benefitperUnitRatePerTierStandardPriceRule = APTS_TestDataFactory.createPriceRule(benefitperUnitRatePerTierStandardRuleSet);
        benefitperUnitRatePerTierStandardPriceRule.Apttus_Config2__TierMetricType__c = VOLUME;
        benefitperUnitRatePerTierStandardPriceRule.Apttus_Config2__Dimension4ValueType__c=RATEPERTIER;
        priceRules.add(benefitperUnitRatePerTierStandardPriceRule);

        /*Apttus_Config2__PriceRule__c revenueStandardPriceRule = new Apttus_Config2__PriceRule__c();
        revenueStandardPriceRule.Apttus_Config2__RulesetId__c = revenueStandardRuleSet.Id;
        revenueStandardPriceRule.Apttus_Config2__Sequence__c = 1;
        revenueStandardPriceRule.Apttus_Config2__TierMetricType__c = REVENUE;
        revenueStandardPriceRule.Apttus_Config2__Dimension4ValueType__c=HIGHRATETIER;
        revenueStandardPriceRule.Apttus_Config2__MetricValueSource__c = LISTPRICE;*/
        Apttus_Config2__PriceRule__c revenueStandardPriceRule = APTS_TestDataFactory.createPriceRule(revenueStandardRuleSet);
        revenueStandardPriceRule.Apttus_Config2__TierMetricType__c = REVENUE;
        revenueStandardPriceRule.Apttus_Config2__Dimension4ValueType__c=HIGHRATETIER;
        revenueStandardPriceRule.Apttus_Config2__MetricValueSource__c = LISTPRICE;
        priceRules.add(revenueStandardPriceRule);

        /*Apttus_Config2__PriceRule__c revenueStandardNetPricePriceRule = new Apttus_Config2__PriceRule__c();
        revenueStandardNetPricePriceRule.Apttus_Config2__RulesetId__c = revenueStandardNetPriceRuleSet.Id;
        revenueStandardNetPricePriceRule.Apttus_Config2__Sequence__c = 1;
        revenueStandardNetPricePriceRule.Apttus_Config2__TierMetricType__c = REVENUE;
        revenueStandardNetPricePriceRule.Apttus_Config2__Dimension4ValueType__c=HIGHRATETIER;
        revenueStandardNetPricePriceRule.Apttus_Config2__MetricValueSource__c = NETPRICE;*/
        Apttus_Config2__PriceRule__c revenueStandardNetPricePriceRule = APTS_TestDataFactory.createPriceRule(revenueStandardNetPriceRuleSet);
        revenueStandardNetPricePriceRule.Apttus_Config2__TierMetricType__c = REVENUE;
        revenueStandardNetPricePriceRule.Apttus_Config2__Dimension4ValueType__c=HIGHRATETIER;
        revenueStandardNetPricePriceRule.Apttus_Config2__MetricValueSource__c = NETPRICE;
        priceRules.add(revenueStandardNetPricePriceRule);

        /*Apttus_Config2__PriceRule__c revenueRatePerTierStandardPriceRule = new Apttus_Config2__PriceRule__c();
        revenueRatePerTierStandardPriceRule.Apttus_Config2__RulesetId__c = revenueRatePerTierStandardRuleSet.Id;
        revenueRatePerTierStandardPriceRule.Apttus_Config2__Sequence__c = 1;
        revenueRatePerTierStandardPriceRule.Apttus_Config2__TierMetricType__c = REVENUE;
        revenueRatePerTierStandardPriceRule.Apttus_Config2__Dimension4ValueType__c=RATEPERTIER;
        revenueRatePerTierStandardPriceRule.Apttus_Config2__MetricValueSource__c = LISTPRICE;*/
        Apttus_Config2__PriceRule__c revenueRatePerTierStandardPriceRule = APTS_TestDataFactory.createPriceRule(revenueRatePerTierStandardRuleSet);
        revenueRatePerTierStandardPriceRule.Apttus_Config2__TierMetricType__c = REVENUE;
        revenueRatePerTierStandardPriceRule.Apttus_Config2__Dimension4ValueType__c=RATEPERTIER;
        revenueRatePerTierStandardPriceRule.Apttus_Config2__MetricValueSource__c = LISTPRICE;
        priceRules.add(revenueRatePerTierStandardPriceRule);

        /*Apttus_Config2__PriceRule__c revenueRatePerTierStandardNetPricePriceRule = new Apttus_Config2__PriceRule__c();
        revenueRatePerTierStandardNetPricePriceRule.Apttus_Config2__RulesetId__c = revenueRatePerTierStandardNetPriceRuleSet.Id;
        revenueRatePerTierStandardNetPricePriceRule.Apttus_Config2__Sequence__c = 1;
        revenueRatePerTierStandardNetPricePriceRule.Apttus_Config2__TierMetricType__c = REVENUE;
        revenueRatePerTierStandardNetPricePriceRule.Apttus_Config2__Dimension4ValueType__c=RATEPERTIER;
        revenueRatePerTierStandardNetPricePriceRule.Apttus_Config2__MetricValueSource__c = NETPRICE;*/
        Apttus_Config2__PriceRule__c revenueRatePerTierStandardNetPricePriceRule = APTS_TestDataFactory.createPriceRule(revenueRatePerTierStandardNetPriceRuleSet);
        revenueRatePerTierStandardNetPricePriceRule.Apttus_Config2__TierMetricType__c = REVENUE;
        revenueRatePerTierStandardNetPricePriceRule.Apttus_Config2__Dimension4ValueType__c=RATEPERTIER;
        revenueRatePerTierStandardNetPricePriceRule.Apttus_Config2__MetricValueSource__c = NETPRICE;
        priceRules.add(revenueRatePerTierStandardNetPricePriceRule);

        /*Apttus_Config2__PriceRule__c multipleIncentivesPricePriceRule1 = new Apttus_Config2__PriceRule__c();
        multipleIncentivesPricePriceRule1.Apttus_Config2__RulesetId__c = multipleIncentivesPriceRuleSet1.Id;
        multipleIncentivesPricePriceRule1.Apttus_Config2__Sequence__c = 1;
        multipleIncentivesPricePriceRule1.Apttus_Config2__TierMetricType__c = REVENUE;
        multipleIncentivesPricePriceRule1.Apttus_Config2__Dimension4ValueType__c=RATEPERTIER;
        multipleIncentivesPricePriceRule1.Apttus_Config2__MetricValueSource__c = NETPRICE;*/
        Apttus_Config2__PriceRule__c multipleIncentivesPricePriceRule1 = APTS_TestDataFactory.createPriceRule(multipleIncentivesPriceRuleSet1);
        multipleIncentivesPricePriceRule1.Apttus_Config2__TierMetricType__c = REVENUE;
        multipleIncentivesPricePriceRule1.Apttus_Config2__Dimension4ValueType__c=RATEPERTIER;
        multipleIncentivesPricePriceRule1.Apttus_Config2__MetricValueSource__c = NETPRICE;
        priceRules.add(multipleIncentivesPricePriceRule1);

        /*Apttus_Config2__PriceRule__c multipleIncentivesPricePriceRule2 = new Apttus_Config2__PriceRule__c();
        multipleIncentivesPricePriceRule2.Apttus_Config2__RulesetId__c = multipleIncentivesPriceRuleSet2.Id;
        multipleIncentivesPricePriceRule2.Apttus_Config2__Sequence__c = 1;
        multipleIncentivesPricePriceRule2.Apttus_Config2__TierMetricType__c = REVENUE;
        multipleIncentivesPricePriceRule2.Apttus_Config2__Dimension4ValueType__c=RATEPERTIER;
        multipleIncentivesPricePriceRule2.Apttus_Config2__MetricValueSource__c = NETPRICE;*/
        Apttus_Config2__PriceRule__c multipleIncentivesPricePriceRule2 = APTS_TestDataFactory.createPriceRule(multipleIncentivesPriceRuleSet2);
        multipleIncentivesPricePriceRule2.Apttus_Config2__TierMetricType__c = REVENUE;
        multipleIncentivesPricePriceRule2.Apttus_Config2__Dimension4ValueType__c=RATEPERTIER;
        multipleIncentivesPricePriceRule2.Apttus_Config2__MetricValueSource__c = NETPRICE;
        priceRules.add(multipleIncentivesPricePriceRule2);


        insert pricerules; 

        // Creation rule entries
        List<Apttus_Config2__PriceRuleEntry__c> ruleEntries = new List<Apttus_Config2__PriceRuleEntry__c>();

        /*Apttus_Config2__PriceRuleEntry__c benefitAmountStandardRuleEntry = new Apttus_Config2__PriceRuleEntry__c();
        benefitAmountStandardRuleEntry.Apttus_Config2__PriceRuleId__c = benefitAmountStandardPriceRule.Id;
        benefitAmountStandardRuleEntry.Apttus_Config2__Sequence__c = 1;
        benefitAmountStandardRuleEntry.Apttus_Config2__Dimension4Value__c = '500';
        benefitAmountStandardRuleEntry.Apttus_Config2__AdjustmentType__c = BENEFITAMT;
        benefitAmountStandardRuleEntry.Apttus_Config2__AdjustmentAmount__c = 100;*/
        Apttus_Config2__PriceRuleEntry__c benefitAmountStandardRuleEntry = APTS_TestDataFactory.createPriceRuleEntry(benefitAmountStandardPriceRule);
        benefitAmountStandardRuleEntry.Apttus_Config2__Dimension4Value__c = '500';
        benefitAmountStandardRuleEntry.Apttus_Config2__AdjustmentType__c = BENEFITAMT;
        benefitAmountStandardRuleEntry.Apttus_Config2__AdjustmentAmount__c = 100;
        ruleEntries.add(benefitAmountStandardRuleEntry);

        /*Apttus_Config2__PriceRuleEntry__c benefitperUnitStandardRuleEntry = new Apttus_Config2__PriceRuleEntry__c();
        benefitperUnitStandardRuleEntry.Apttus_Config2__PriceRuleId__c = benefitperUnitStandardPriceRule.Id;
        benefitperUnitStandardRuleEntry.Apttus_Config2__Sequence__c = 1;
        benefitperUnitStandardRuleEntry.Apttus_Config2__Dimension4Value__c = '500';
        benefitperUnitStandardRuleEntry.Apttus_Config2__AdjustmentType__c = BENEFITPERUNIT;
        benefitperUnitStandardRuleEntry.Apttus_Config2__AdjustmentAmount__c = 100;*/
        Apttus_Config2__PriceRuleEntry__c benefitperUnitStandardRuleEntry = APTS_TestDataFactory.createPriceRuleEntry(benefitperUnitStandardPriceRule);
        benefitperUnitStandardRuleEntry.Apttus_Config2__Dimension4Value__c = '500';
        benefitperUnitStandardRuleEntry.Apttus_Config2__AdjustmentType__c = BENEFITPERUNIT;
        benefitperUnitStandardRuleEntry.Apttus_Config2__AdjustmentAmount__c = 100;
        ruleEntries.add(benefitperUnitStandardRuleEntry);

        /*Apttus_Config2__PriceRuleEntry__c benefitAmountRatePerTierStandardRuleEntry1 = new Apttus_Config2__PriceRuleEntry__c();
        benefitAmountRatePerTierStandardRuleEntry1.Apttus_Config2__PriceRuleId__c = benefitAmountRatePerTierStandardPriceRule.Id;
        benefitAmountRatePerTierStandardRuleEntry1.Apttus_Config2__Sequence__c = 1;
        benefitAmountRatePerTierStandardRuleEntry1.Apttus_Config2__Dimension4Value__c = '500';
        benefitAmountRatePerTierStandardRuleEntry1.Apttus_Config2__AdjustmentType__c = BENEFITAMT;
        benefitAmountRatePerTierStandardRuleEntry1.Apttus_Config2__AdjustmentAmount__c = 100;*/
        Apttus_Config2__PriceRuleEntry__c benefitAmountRatePerTierStandardRuleEntry1 = APTS_TestDataFactory.createPriceRuleEntry(benefitAmountRatePerTierStandardPriceRule);
        benefitAmountRatePerTierStandardRuleEntry1.Apttus_Config2__Dimension4Value__c = '500';
        benefitAmountRatePerTierStandardRuleEntry1.Apttus_Config2__AdjustmentType__c = BENEFITAMT;
        benefitAmountRatePerTierStandardRuleEntry1.Apttus_Config2__AdjustmentAmount__c = 100;
        ruleEntries.add(benefitAmountRatePerTierStandardRuleEntry1);

        /*Apttus_Config2__PriceRuleEntry__c benefitAmountRatePerTierStandardRuleEntry2 = new Apttus_Config2__PriceRuleEntry__c();
        benefitAmountRatePerTierStandardRuleEntry2.Apttus_Config2__PriceRuleId__c = benefitAmountRatePerTierStandardPriceRule.Id;
        benefitAmountRatePerTierStandardRuleEntry2.Apttus_Config2__Sequence__c = 1;
        benefitAmountRatePerTierStandardRuleEntry2.Apttus_Config2__Dimension4Value__c = '1';
        benefitAmountRatePerTierStandardRuleEntry2.Apttus_Config2__AdjustmentType__c = BENEFITAMT;
        benefitAmountRatePerTierStandardRuleEntry2.Apttus_Config2__AdjustmentAmount__c = 100;*/
        Apttus_Config2__PriceRuleEntry__c benefitAmountRatePerTierStandardRuleEntry2 = APTS_TestDataFactory.createPriceRuleEntry(benefitAmountRatePerTierStandardPriceRule);
        benefitAmountRatePerTierStandardRuleEntry2.Apttus_Config2__Dimension4Value__c = '1';
        benefitAmountRatePerTierStandardRuleEntry2.Apttus_Config2__AdjustmentType__c = BENEFITAMT;
        benefitAmountRatePerTierStandardRuleEntry2.Apttus_Config2__AdjustmentAmount__c = 100;
        ruleEntries.add(benefitAmountRatePerTierStandardRuleEntry2);

        /*Apttus_Config2__PriceRuleEntry__c benefitperUnitRatePerTierStandardRuleEntry = new Apttus_Config2__PriceRuleEntry__c();
        benefitperUnitRatePerTierStandardRuleEntry.Apttus_Config2__PriceRuleId__c = benefitperUnitRatePerTierStandardPriceRule.Id;
        benefitperUnitRatePerTierStandardRuleEntry.Apttus_Config2__Sequence__c = 1;
        benefitperUnitRatePerTierStandardRuleEntry.Apttus_Config2__Dimension4Value__c = '1';
        benefitperUnitRatePerTierStandardRuleEntry.Apttus_Config2__AdjustmentType__c = BENEFITPERUNIT;
        benefitperUnitRatePerTierStandardRuleEntry.Apttus_Config2__AdjustmentAmount__c = 100;*/
        Apttus_Config2__PriceRuleEntry__c benefitperUnitRatePerTierStandardRuleEntry = APTS_TestDataFactory.createPriceRuleEntry(benefitperUnitRatePerTierStandardPriceRule);
        benefitperUnitRatePerTierStandardRuleEntry.Apttus_Config2__Dimension4Value__c = '1';
        benefitperUnitRatePerTierStandardRuleEntry.Apttus_Config2__AdjustmentType__c = BENEFITPERUNIT;
        benefitperUnitRatePerTierStandardRuleEntry.Apttus_Config2__AdjustmentAmount__c = 100;
        ruleEntries.add(benefitperUnitRatePerTierStandardRuleEntry);

        /*Apttus_Config2__PriceRuleEntry__c revenueStandardRuleEntry = new Apttus_Config2__PriceRuleEntry__c();
        revenueStandardRuleEntry.Apttus_Config2__PriceRuleId__c = revenueStandardPriceRule.Id;
        revenueStandardRuleEntry.Apttus_Config2__Sequence__c = 1;
        revenueStandardRuleEntry.Apttus_Config2__Dimension4Value__c = '500';
        revenueStandardRuleEntry.Apttus_Config2__AdjustmentType__c = BENEFIT;
        revenueStandardRuleEntry.Apttus_Config2__AdjustmentAmount__c = 100;*/
        Apttus_Config2__PriceRuleEntry__c revenueStandardRuleEntry = APTS_TestDataFactory.createPriceRuleEntry(revenueStandardPriceRule);
        revenueStandardRuleEntry.Apttus_Config2__Dimension4Value__c = '500';
        revenueStandardRuleEntry.Apttus_Config2__AdjustmentType__c = BENEFIT;
        revenueStandardRuleEntry.Apttus_Config2__AdjustmentAmount__c = 100;
        ruleEntries.add(revenueStandardRuleEntry);

        /*Apttus_Config2__PriceRuleEntry__c revenueStandardNetPriceRuleEntry = new Apttus_Config2__PriceRuleEntry__c();
        revenueStandardNetPriceRuleEntry.Apttus_Config2__PriceRuleId__c = revenueStandardNetPricePriceRule.Id;
        revenueStandardNetPriceRuleEntry.Apttus_Config2__Sequence__c = 1;
        revenueStandardNetPriceRuleEntry.Apttus_Config2__Dimension4Value__c = '5000';
        revenueStandardNetPriceRuleEntry.Apttus_Config2__AdjustmentType__c = BENEFITAMT;
        revenueStandardNetPriceRuleEntry.Apttus_Config2__AdjustmentAmount__c = 100;*/
        Apttus_Config2__PriceRuleEntry__c revenueStandardNetPriceRuleEntry = APTS_TestDataFactory.createPriceRuleEntry(revenueStandardNetPricePriceRule);
        revenueStandardNetPriceRuleEntry.Apttus_Config2__Dimension4Value__c = '5000';
        revenueStandardNetPriceRuleEntry.Apttus_Config2__AdjustmentType__c = BENEFITAMT;
        revenueStandardNetPriceRuleEntry.Apttus_Config2__AdjustmentAmount__c = 100;
        ruleEntries.add(revenueStandardNetPriceRuleEntry);

        /*Apttus_Config2__PriceRuleEntry__c revenueRatePerTierStandardRuleEntry = new Apttus_Config2__PriceRuleEntry__c();
        revenueRatePerTierStandardRuleEntry.Apttus_Config2__PriceRuleId__c = revenueRatePerTierStandardPriceRule.Id;
        revenueRatePerTierStandardRuleEntry.Apttus_Config2__Sequence__c = 1;
        revenueRatePerTierStandardRuleEntry.Apttus_Config2__Dimension4Value__c = '500';
        revenueRatePerTierStandardRuleEntry.Apttus_Config2__AdjustmentType__c = BENEFIT;
        revenueRatePerTierStandardRuleEntry.Apttus_Config2__AdjustmentAmount__c = 20;*/
        Apttus_Config2__PriceRuleEntry__c revenueRatePerTierStandardRuleEntry = APTS_TestDataFactory.createPriceRuleEntry(revenueRatePerTierStandardPriceRule);
        revenueRatePerTierStandardRuleEntry.Apttus_Config2__Dimension4Value__c = '500';
        revenueRatePerTierStandardRuleEntry.Apttus_Config2__AdjustmentType__c = BENEFIT;
        revenueRatePerTierStandardRuleEntry.Apttus_Config2__AdjustmentAmount__c = 20;
        ruleEntries.add(revenueRatePerTierStandardRuleEntry);

        /*Apttus_Config2__PriceRuleEntry__c revenueRatePerTierStandardNetPriceRuleEntry = new Apttus_Config2__PriceRuleEntry__c();
        revenueRatePerTierStandardNetPriceRuleEntry.Apttus_Config2__PriceRuleId__c = revenueRatePerTierStandardNetPricePriceRule.Id;
        revenueRatePerTierStandardNetPriceRuleEntry.Apttus_Config2__Sequence__c = 1;
        revenueRatePerTierStandardNetPriceRuleEntry.Apttus_Config2__Dimension4Value__c = '5000';
        revenueRatePerTierStandardNetPriceRuleEntry.Apttus_Config2__AdjustmentType__c = BENEFITAMT;
        revenueRatePerTierStandardNetPriceRuleEntry.Apttus_Config2__AdjustmentAmount__c = 20;*/
        Apttus_Config2__PriceRuleEntry__c revenueRatePerTierStandardNetPriceRuleEntry = APTS_TestDataFactory.createPriceRuleEntry(revenueRatePerTierStandardNetPricePriceRule);
        revenueRatePerTierStandardNetPriceRuleEntry.Apttus_Config2__Dimension4Value__c = '5000';
        revenueRatePerTierStandardNetPriceRuleEntry.Apttus_Config2__AdjustmentType__c = BENEFITAMT;
        revenueRatePerTierStandardNetPriceRuleEntry.Apttus_Config2__AdjustmentAmount__c = 20;
        ruleEntries.add(revenueRatePerTierStandardNetPriceRuleEntry);

        /*Apttus_Config2__PriceRuleEntry__c multipleIncentivesPriceRuleEntry1 = new Apttus_Config2__PriceRuleEntry__c();
        multipleIncentivesPriceRuleEntry1.Apttus_Config2__PriceRuleId__c = multipleIncentivesPricePriceRule1.Id;
        multipleIncentivesPriceRuleEntry1.Apttus_Config2__Sequence__c = 1;
        multipleIncentivesPriceRuleEntry1.Apttus_Config2__Dimension4Value__c = '5000';
        multipleIncentivesPriceRuleEntry1.Apttus_Config2__AdjustmentType__c = BENEFITAMT;
        multipleIncentivesPriceRuleEntry1.Apttus_Config2__AdjustmentAmount__c = 20;*/
        Apttus_Config2__PriceRuleEntry__c multipleIncentivesPriceRuleEntry1 = APTS_TestDataFactory.createPriceRuleEntry(multipleIncentivesPricePriceRule1);
        multipleIncentivesPriceRuleEntry1.Apttus_Config2__Dimension4Value__c = '5000';
        multipleIncentivesPriceRuleEntry1.Apttus_Config2__AdjustmentType__c = BENEFITAMT;
        multipleIncentivesPriceRuleEntry1.Apttus_Config2__AdjustmentAmount__c = 20;
        ruleEntries.add(multipleIncentivesPriceRuleEntry1);

        /*Apttus_Config2__PriceRuleEntry__c multipleIncentivesPriceRuleEntry2 = new Apttus_Config2__PriceRuleEntry__c();
        multipleIncentivesPriceRuleEntry2.Apttus_Config2__PriceRuleId__c = multipleIncentivesPricePriceRule2.Id;
        multipleIncentivesPriceRuleEntry2.Apttus_Config2__Sequence__c = 1;
        multipleIncentivesPriceRuleEntry2.Apttus_Config2__Dimension4Value__c = '5000';
        multipleIncentivesPriceRuleEntry2.Apttus_Config2__AdjustmentType__c = BENEFITAMT;
        multipleIncentivesPriceRuleEntry2.Apttus_Config2__AdjustmentAmount__c = 20;*/
        Apttus_Config2__PriceRuleEntry__c multipleIncentivesPriceRuleEntry2 = APTS_TestDataFactory.createPriceRuleEntry(multipleIncentivesPricePriceRule2);
        multipleIncentivesPriceRuleEntry2.Apttus_Config2__Dimension4Value__c = '5000';
        multipleIncentivesPriceRuleEntry2.Apttus_Config2__AdjustmentType__c = BENEFITAMT;
        multipleIncentivesPriceRuleEntry2.Apttus_Config2__AdjustmentAmount__c = 20;
        ruleEntries.add(multipleIncentivesPriceRuleEntry2);

        insert ruleEntries;

        // Creation of Product
        List<Product2> products = new List<Product2>();
        /*Product2 childProduct1 = new Product2();
        childProduct1.Name = 'Child Product1';
        childProduct1.ProductCode = 'CP1';
        childProduct1.Family = 'Tea';
        childProduct1.IsActive = true;
        childProduct1.Apttus_Config2__ConfigurationType__c = 'Standalone';
        childProduct1.Apttus_Config2__Uom__c = 'Each';*/
        Product2 childProduct1 = APTS_TestDataFactory.createProduct('Child Product1', 'CP1', 'Tea', 'Standalone', false, false);
        products.add(childProduct1);
        insert products;
	}
	@isTest static void getAssumptionStandardTestDrinksToKgmCategory()
	{
		// Query of test data stored in the system
		Test.startTest();
		Id standardRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
		List<Apttus__APTS_Agreement__c> agreements = [SELECT Id 
													  FROM Apttus__APTS_Agreement__c
													  WHERE recordtypeid =: standardRecordTypeId];

		// Calculate Assumption
		APTS_VolumeCalculationEngine.VolumeAssumptionRequest request = new APTS_VolumeCalculationEngine.VolumeAssumptionRequest();
		request.agreementId = agreements.get(0).Id;
		request.unitfromUOM = 10;
		request.fromUOM = 'SAP_DRKS';
		request.toUOM = 'SAP_KGM';
		request.category = 'Coffee';
        request.subCategory = 'Instant';
        request.familyLevel = APTS_VolumeCalculationEngine.SUBCATEGORY_LEVEL;

		decimal assumption = APTS_VolumeCalculationEngine.getAssumption(request);
		System.assertEquals(60.0, assumption);

		// Reverse calculation: From Volume Assumption to Drinks
		APTS_VolumeCalculationEngine.DrinksRequest reverseRequest = new APTS_VolumeCalculationEngine.DrinksRequest();
		reverseRequest.agreementId = agreements.get(0).Id;
		reverseRequest.volumeAssumption = assumption;
        reverseRequest.originalUOM = 'SAP_KGM';
		reverseRequest.category = 'Coffee';
        reverseRequest.subCategory = 'Instant';
        reverseRequest.familyLevel = APTS_VolumeCalculationEngine.SUBCATEGORY_LEVEL;

		decimal drinks = APTS_VolumeCalculationEngine.getDrinks(reverseRequest);
		System.assertEquals(request.unitfromUOM, drinks);
	
		Test.stopTest();
	}



	@isTest static void getAssumptionStandardTestDrinksToLtrCategory()
	{
		Test.startTest();
		// Query of test data stored in the system
		Id standardRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
		List<Apttus__APTS_Agreement__c> agreements = [SELECT Id 
													  FROM Apttus__APTS_Agreement__c
													  WHERE recordtypeid =: standardRecordTypeId];

		APTS_VolumeCalculationEngine.VolumeAssumptionRequest request = new APTS_VolumeCalculationEngine.VolumeAssumptionRequest();
		request.agreementId = agreements.get(0).Id;
		request.unitfromUOM = 10;
		request.fromUOM = 'SAP_DRKS';
		request.toUOM = 'SAP_LTR';
		request.category = 'Coffee';
        request.subCategory = 'Instant';
        request.familyLevel = APTS_VolumeCalculationEngine.SUBCATEGORY_LEVEL;

		decimal assumption = APTS_VolumeCalculationEngine.getAssumption(request);
		System.assertEquals(200.0, assumption);

		// Reverse calculation: From Volume Assumption to Drinks
		APTS_VolumeCalculationEngine.DrinksRequest reverseRequest = new APTS_VolumeCalculationEngine.DrinksRequest();
		reverseRequest.agreementId = agreements.get(0).Id;
		reverseRequest.volumeAssumption = assumption;
        reverseRequest.category = 'Coffee';
		reverseRequest.subcategory = 'Instant';
		reverseRequest.originalUOM = 'SAP_LTR';
        reverseRequest.familyLevel = APTS_VolumeCalculationEngine.SUBCATEGORY_LEVEL;

		decimal drinks = APTS_VolumeCalculationEngine.getDrinks(reverseRequest);
		System.assertEquals(request.unitfromUOM, drinks);
		Test.stopTest();
	}

	@isTest static void getAssumptionStandardTestDrinksToDrinksCategory()
	{
		Test.startTest();
		// Query of test data stored in the system
		Id standardRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
		List<Apttus__APTS_Agreement__c> agreements = [SELECT Id 
													  FROM Apttus__APTS_Agreement__c
													  WHERE recordtypeid =: standardRecordTypeId];

		APTS_VolumeCalculationEngine.VolumeAssumptionRequest request = new APTS_VolumeCalculationEngine.VolumeAssumptionRequest();
		request.agreementId = agreements.get(0).Id;
		request.unitfromUOM = 50;
		request.fromUOM = 'SAP_DRKS';
		request.toUOM = 'SAP_DRKS';
		request.category = 'Coffee';
        request.subCategory = 'Instant';
        request.familyLevel = APTS_VolumeCalculationEngine.SUBCATEGORY_LEVEL;

		decimal assumption = APTS_VolumeCalculationEngine.getAssumption(request);
		System.assertEquals(50.0, assumption);

		// Reverse calculation: From Volume Assumption to Drinks
		APTS_VolumeCalculationEngine.DrinksRequest reverseRequest = new APTS_VolumeCalculationEngine.DrinksRequest();
		reverseRequest.agreementId = agreements.get(0).Id;
		reverseRequest.volumeAssumption = assumption;
		reverseRequest.category = 'Coffee';
        reverseRequest.subcategory = 'Instant';
		reverseRequest.originalUOM = 'SAP_DRKS';
        reverseRequest.familyLevel = APTS_VolumeCalculationEngine.SUBCATEGORY_LEVEL;

		decimal drinks = APTS_VolumeCalculationEngine.getDrinks(reverseRequest);
		System.assertEquals(request.unitfromUOM, drinks);

		Test.stopTest();
	}

	@isTest static void getAssumptionStandardTestDrinksToCasesCategory()
	{
		Test.startTest();
		// Query of test data stored in the system
		Id standardRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
		List<Apttus__APTS_Agreement__c> agreements = [SELECT Id 
													  FROM Apttus__APTS_Agreement__c
													  WHERE recordtypeid =: standardRecordTypeId];

		APTS_VolumeCalculationEngine.VolumeAssumptionRequest request = new APTS_VolumeCalculationEngine.VolumeAssumptionRequest();
		request.agreementId = agreements.get(0).Id;
		request.unitfromUOM = 50;
		request.fromUOM = 'SAP_DRKS';
		request.toUOM = 'SAP_CS';
		request.category = 'Coffee';
        request.subcategory = 'Instant';
        request.familyLevel = APTS_VolumeCalculationEngine.SUBCATEGORY_LEVEL;

		decimal assumption = APTS_VolumeCalculationEngine.getAssumption(request);
		System.assertEquals(0.0, assumption);

		// Reverse calculation: From Volume Assumption to Drinks
		APTS_VolumeCalculationEngine.DrinksRequest reverseRequest = new APTS_VolumeCalculationEngine.DrinksRequest();
		reverseRequest.agreementId = agreements.get(0).Id;
		reverseRequest.volumeAssumption = assumption;
		reverseRequest.category = 'Coffee';
        reverseRequest.subcategory = 'Instant';
		reverseRequest.originalUOM = 'SAP_CS';
        reverseRequest.familyLevel = APTS_VolumeCalculationEngine.SUBCATEGORY_LEVEL;


		decimal drinks = APTS_VolumeCalculationEngine.getDrinks(reverseRequest);
		System.assertEquals(0.0, drinks);

		Test.stopTest();
	}

	@isTest static void getAssumptionStandardTestIncompleteRequestCategory()
	{
		Test.startTest();
		// Query of test data stored in the system
		Id standardRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
		List<Apttus__APTS_Agreement__c> agreements = [SELECT Id 
													  FROM Apttus__APTS_Agreement__c
													  WHERE recordtypeid =: standardRecordTypeId];

		APTS_VolumeCalculationEngine.VolumeAssumptionRequest request = new APTS_VolumeCalculationEngine.VolumeAssumptionRequest();
		request.agreementId = agreements.get(0).Id;
		request.fromUOM = 'SAP_DRKS';
		decimal assumption = APTS_VolumeCalculationEngine.getAssumption(request);
		System.assertEquals(assumption, 0.0);
		Test.stopTest();
	}

	@isTest static void getAssumptionConsumptionTestCategory()
	{
		Test.startTest();
		Id consumptionRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Consumption Model').getRecordTypeId();
		List<Apttus__APTS_Agreement__c> agreements = [SELECT Id 
													  FROM Apttus__APTS_Agreement__c
													  WHERE recordtypeid =: consumptionRecordTypeId];

		APTS_VolumeCalculationEngine.VolumeAssumptionRequest request = new APTS_VolumeCalculationEngine.VolumeAssumptionRequest();
		request.agreementId = agreements.get(0).Id;
		request.unitfromUOM = 20;
		request.fromUOM = 'SAP_DRKS';
		request.toUOM = 'SAP_KGM'; // The destination unit is irrelevant because the the agreement is consumption model
        request.category = 'Coffee';
        request.subcategory = 'Instant';
        request.familyLevel = APTS_VolumeCalculationEngine.SUBCATEGORY_LEVEL;
		decimal assumption = APTS_VolumeCalculationEngine.getAssumption(request);
		System.assertEquals(20.0, assumption);

		// Reverse calculation: From Volume Assumption to Drinks
		APTS_VolumeCalculationEngine.DrinksRequest reverseRequest = new APTS_VolumeCalculationEngine.DrinksRequest();
		reverseRequest.agreementId = agreements.get(0).Id;
		reverseRequest.volumeAssumption = assumption;
		reverseRequest.originalUOM = 'SAP_KGM';
        reverseRequest.category = 'Coffee';
        reverseRequest.subcategory = 'Instant';
        reverseRequest.familyLevel = APTS_VolumeCalculationEngine.SUBCATEGORY_LEVEL;

		decimal drinks = APTS_VolumeCalculationEngine.getDrinks(reverseRequest);
		System.assertEquals(20.0, drinks);

		Test.stopTest();
	}

    @isTest static void getDrinksConversionZeroTest()
    {
        Test.startTest();
        Id recordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
        List<Apttus__APTS_Agreement__c> agreements = [SELECT Id 
                                                      FROM Apttus__APTS_Agreement__c
                                                      WHERE recordtypeid =: recordTypeId];

        // Reverse calculation: From Volume Assumption to Drinks
        APTS_VolumeCalculationEngine.DrinksRequest reverseRequest = new APTS_VolumeCalculationEngine.DrinksRequest();
        reverseRequest.agreementId = agreements.get(0).Id;
        reverseRequest.volumeAssumption = 200.0;
        reverseRequest.originalUOM = 'SAP_PF';
        reverseRequest.familyLevel = APTS_VolumeCalculationEngine.CATEGORY_LEVEL;

        decimal drinks = APTS_VolumeCalculationEngine.getDrinks(reverseRequest);
        System.assertEquals(0.0, drinks);

        Test.stopTest();
    }

	@isTest static void getRebateStandardTestBenefitAmount1Category()
	{
		// Query of test data stored in the system
		Test.startTest();
		Id standardRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
		List<Apttus__APTS_Agreement__c> agreements = [SELECT Id 
													  FROM Apttus__APTS_Agreement__c
													  WHERE recordtypeid =: standardRecordTypeId
													  AND Name='Standard Agreement (Benefit Amount)'];

		// Calculate of VolumeAssumption
		APTS_VolumeCalculationEngine.VolumeAssumptionRequest assumptionRequest = new APTS_VolumeCalculationEngine.VolumeAssumptionRequest();
		assumptionRequest.agreementId = agreements.get(0).Id;
		assumptionRequest.unitfromUOM = 10;
		assumptionRequest.fromUOM = 'SAP_DRKS';
		assumptionRequest.toUOM = 'SAP_KGM';
		assumptionRequest.category = 'Coffee';
        assumptionRequest.subcategory = 'Instant';
        assumptionRequest.familyLevel = APTS_VolumeCalculationEngine.SUBCATEGORY_LEVEL;


		decimal assumption = APTS_VolumeCalculationEngine.getAssumption(assumptionRequest);
		System.assertEquals(60.0, assumption);

		// Calculate of getRebate
        List<Apttus_Config2__ClassificationHierarchy__c> classificationHierarchies = [select Id, Name from Apttus_Config2__ClassificationHierarchy__c];
        System.debug('list of hierarchies before run the test: ' + classificationHierarchies);                                                                          

		APTS_VolumeCalculationEngine.VolumeRebateRequest rebateRequest = new APTS_VolumeCalculationEngine.VolumeRebateRequest();
		rebateRequest.agreementId = agreements.get(0).Id;
		rebateRequest.volAssumption = assumption;
		rebateRequest.category = classificationHierarchies.get(0).Id;
		rebateRequest.grossSale = 20;
		rebateRequest.netSale = 50;

		decimal rebate = APTS_VolumeCalculationEngine.getRebate(rebateRequest);
		System.assertEquals(100.0, rebate);
		Test.stopTest();
	}

    @isTest static void getRebateStandardTestBenefitAmount2()
    {
        // Query of test data stored in the system
        Test.startTest();
        Id standardRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
        List<Apttus__APTS_Agreement__c> agreements = [SELECT Id 
                                                      FROM Apttus__APTS_Agreement__c
                                                      WHERE recordtypeid =: standardRecordTypeId
                                                      AND Name='Standard Agreement (Benefit Amount)'];

        // Calculate of VolumeAssumption
        APTS_VolumeCalculationEngine.VolumeAssumptionRequest assumptionRequest = new APTS_VolumeCalculationEngine.VolumeAssumptionRequest();
        assumptionRequest.agreementId = agreements.get(0).Id;
        assumptionRequest.unitfromUOM = 500;
        assumptionRequest.fromUOM = 'SAP_DRKS';
        assumptionRequest.toUOM = 'SAP_KGM';
        assumptionRequest.category = 'Coffee';
        assumptionRequest.subcategory = 'Instant';
        assumptionRequest.familyLevel = APTS_VolumeCalculationEngine.SUBCATEGORY_LEVEL;


        decimal assumption = APTS_VolumeCalculationEngine.getAssumption(assumptionRequest);
        System.assertEquals(3000.0, assumption);

        // Calculate of getRebate
        List<Apttus_Config2__ClassificationHierarchy__c> classificationHierarchies = [select Id, Name from Apttus_Config2__ClassificationHierarchy__c];
        System.debug('list of hierarchies before run the test: ' + classificationHierarchies);                                                                          
        APTS_VolumeCalculationEngine.VolumeRebateRequest rebateRequest = new APTS_VolumeCalculationEngine.VolumeRebateRequest();
        rebateRequest.agreementId = agreements.get(0).Id;
        rebateRequest.volAssumption = assumption;
        rebateRequest.category = classificationHierarchies.get(0).Id;
        rebateRequest.grossSale = 20;
        rebateRequest.netSale = 50;

        decimal rebate = APTS_VolumeCalculationEngine.getRebate(rebateRequest);
        System.assertEquals(0.0, rebate);
        Test.stopTest();
    }

	@isTest static void getRebateStandardTestBenefitPerUnit()
	{
		// Query of test data stored in the system
		Test.startTest();
		Id standardRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
		List<Apttus__APTS_Agreement__c> agreements = [SELECT Id 
													  FROM Apttus__APTS_Agreement__c
													  WHERE recordtypeid =: standardRecordTypeId
													  AND Name='Standard Agreement (Benefit per Unit)'];

		// Calculate of VolumeAssumption
		APTS_VolumeCalculationEngine.VolumeAssumptionRequest assumptionRequest = new APTS_VolumeCalculationEngine.VolumeAssumptionRequest();
		assumptionRequest.agreementId = agreements.get(0).Id;
		assumptionRequest.unitfromUOM = 10;
		assumptionRequest.fromUOM = 'SAP_DRKS';
		assumptionRequest.toUOM = 'SAP_KGM';
		assumptionRequest.category = 'Coffee';
        assumptionRequest.subcategory = 'Instant';
        assumptionRequest.familyLevel = APTS_VolumeCalculationEngine.SUBCATEGORY_LEVEL;


		decimal assumption = APTS_VolumeCalculationEngine.getAssumption(assumptionRequest);
		System.assertEquals(60.0, assumption);

		// Calculate of getRebate
        List<Apttus_Config2__ClassificationHierarchy__c> classificationHierarchies = [select Id, Name from Apttus_Config2__ClassificationHierarchy__c];
        System.debug('list of hierarchies before run the test: ' + classificationHierarchies);                                                                          
		APTS_VolumeCalculationEngine.VolumeRebateRequest rebateRequest = new APTS_VolumeCalculationEngine.VolumeRebateRequest();
		rebateRequest.agreementId = agreements.get(0).Id;
		rebateRequest.volAssumption = assumption;
		rebateRequest.category = classificationHierarchies.get(0).Id;
		rebateRequest.grossSale = 20;
		rebateRequest.netSale = 50;

		decimal rebate = APTS_VolumeCalculationEngine.getRebate(rebateRequest);
		System.debug('Rebate to be tested: ' + rebate);
		System.assertEquals(6000, rebate);
		Test.stopTest();
	}

	@isTest static void getRebateStandardTestBenefitAmountRatePerTier()
	{
		// Query of test data stored in the system
		Test.startTest();
		Id standardRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
		List<Apttus__APTS_Agreement__c> agreements = [SELECT Id 
													  FROM Apttus__APTS_Agreement__c
													  WHERE recordtypeid =: standardRecordTypeId
													  AND Name='Standard Agreement (Benefit Amount) - Rate Per Tier'];

		// Calculate of VolumeAssumption
		APTS_VolumeCalculationEngine.VolumeAssumptionRequest assumptionRequest = new APTS_VolumeCalculationEngine.VolumeAssumptionRequest();
		assumptionRequest.agreementId = agreements.get(0).Id;
		assumptionRequest.unitfromUOM = 10;
		assumptionRequest.fromUOM = 'SAP_DRKS';
		assumptionRequest.toUOM = 'SAP_KGM';
		assumptionRequest.category = 'Coffee';
        assumptionRequest.subcategory = 'Instant';
        assumptionRequest.familyLevel = APTS_VolumeCalculationEngine.SUBCATEGORY_LEVEL;


		decimal assumption = APTS_VolumeCalculationEngine.getAssumption(assumptionRequest);
		System.assertEquals(60.0, assumption);

		// Calculate of getRebate
		List<Apttus_Config2__ClassificationHierarchy__c> classificationHierarchies = [select Id, Name from Apttus_Config2__ClassificationHierarchy__c];
        System.debug('list of hierarchies before run the test: ' + classificationHierarchies);                                                                          
        APTS_VolumeCalculationEngine.VolumeRebateRequest rebateRequest = new APTS_VolumeCalculationEngine.VolumeRebateRequest();
		rebateRequest.agreementId = agreements.get(0).Id;
		rebateRequest.volAssumption = assumption;
		rebateRequest.category = classificationHierarchies.get(0).Id;
		rebateRequest.grossSale = 20;
		rebateRequest.netSale = 50;

		decimal rebate = APTS_VolumeCalculationEngine.getRebate(rebateRequest);
		System.assertEquals(200.0, rebate);
		Test.stopTest();
	}

	@isTest static void getRebateStandardTestBenefitPerUnitRatePerTier1()
	{
		// Query of test data stored in the system
		Test.startTest();
		Id standardRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
		List<Apttus__APTS_Agreement__c> agreements = [SELECT Id 
													  FROM Apttus__APTS_Agreement__c
													  WHERE recordtypeid =: standardRecordTypeId
													  AND Name='Standard Agreement (Benefit per Unit) - Rate Per Tier'];

		// Calculate of VolumeAssumption
		APTS_VolumeCalculationEngine.VolumeAssumptionRequest assumptionRequest = new APTS_VolumeCalculationEngine.VolumeAssumptionRequest();
		assumptionRequest.agreementId = agreements.get(0).Id;
		assumptionRequest.unitfromUOM = 10;
		assumptionRequest.fromUOM = 'SAP_DRKS';
		assumptionRequest.toUOM = 'SAP_KGM';
        assumptionRequest.category = 'Coffee';
        assumptionRequest.subcategory = 'Instant';
        assumptionRequest.familyLevel = APTS_VolumeCalculationEngine.SUBCATEGORY_LEVEL;

		decimal assumption = APTS_VolumeCalculationEngine.getAssumption(assumptionRequest);
		System.assertEquals(60.0, assumption);

		// Calculate of getRebate
        List<Apttus_Config2__ClassificationHierarchy__c> classificationHierarchies = [select Id, Name from Apttus_Config2__ClassificationHierarchy__c];
        System.debug('list of hierarchies before run the test: ' + classificationHierarchies);                                                                          
		APTS_VolumeCalculationEngine.VolumeRebateRequest rebateRequest = new APTS_VolumeCalculationEngine.VolumeRebateRequest();
		rebateRequest.agreementId = agreements.get(0).Id;
		rebateRequest.volAssumption = assumption;
		rebateRequest.category = classificationHierarchies.get(0).Id;
		rebateRequest.grossSale = 20;
		rebateRequest.netSale = 50;

		decimal rebate = APTS_VolumeCalculationEngine.getRebate(rebateRequest);
		System.debug('Rebate to be tested: ' + rebate);
		System.assertEquals(100, rebate);
		Test.stopTest();
	}

    @isTest static void getRebateStandardTestBenefitPerUnitRatePerTier2()
    {
        // Query of test data stored in the system
        Test.startTest();
        Id standardRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
        List<Apttus__APTS_Agreement__c> agreements = [SELECT Id 
                                                      FROM Apttus__APTS_Agreement__c
                                                      WHERE recordtypeid =: standardRecordTypeId
                                                      AND Name='Standard Agreement (Benefit per Unit) - Rate Per Tier'];

        // Calculate of VolumeAssumption
        APTS_VolumeCalculationEngine.VolumeAssumptionRequest assumptionRequest = new APTS_VolumeCalculationEngine.VolumeAssumptionRequest();
        assumptionRequest.agreementId = agreements.get(0).Id;
        assumptionRequest.unitfromUOM = 500;
        assumptionRequest.fromUOM = 'SAP_DRKS';
        assumptionRequest.toUOM = 'SAP_KGM';
        assumptionRequest.category = 'Coffee';
        assumptionRequest.subcategory = 'Instant';
        assumptionRequest.familyLevel = APTS_VolumeCalculationEngine.SUBCATEGORY_LEVEL;

        decimal assumption = APTS_VolumeCalculationEngine.getAssumption(assumptionRequest);
        System.assertEquals(3000.0, assumption);

        // Calculate of getRebate
        List<Apttus_Config2__ClassificationHierarchy__c> classificationHierarchies = [select Id, Name from Apttus_Config2__ClassificationHierarchy__c];
        System.debug('list of hierarchies before run the test: ' + classificationHierarchies);                                                                          
        APTS_VolumeCalculationEngine.VolumeRebateRequest rebateRequest = new APTS_VolumeCalculationEngine.VolumeRebateRequest();
        rebateRequest.agreementId = agreements.get(0).Id;
        rebateRequest.volAssumption = assumption;
        rebateRequest.category = classificationHierarchies.get(0).Id;
        rebateRequest.grossSale = 20;
        rebateRequest.netSale = 50;

        decimal rebate = APTS_VolumeCalculationEngine.getRebate(rebateRequest);
        System.debug('Rebate to be tested: ' + rebate);
        System.assertEquals(100, rebate);
        Test.stopTest();
    }

	@isTest static void getRebateStandardTestRevenue()
    {
		// Query of test data stored in the system
		Test.startTest();
		Id standardRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
		List<Apttus__APTS_Agreement__c> agreements = [SELECT Id 
													  FROM Apttus__APTS_Agreement__c
													  WHERE recordtypeid =: standardRecordTypeId
													  AND Name='Standard Agreement (Revenue)'];

		// Calculate of VolumeAssumption
		APTS_VolumeCalculationEngine.VolumeAssumptionRequest assumptionRequest = new APTS_VolumeCalculationEngine.VolumeAssumptionRequest();
		assumptionRequest.agreementId = agreements.get(0).Id;
		assumptionRequest.unitfromUOM = 10;
		assumptionRequest.fromUOM = 'SAP_DRKS';
		assumptionRequest.toUOM = 'SAP_KGM';
        assumptionRequest.category = 'Coffee';
        assumptionRequest.subcategory = 'Instant';
        assumptionRequest.familyLevel = APTS_VolumeCalculationEngine.SUBCATEGORY_LEVEL;


		decimal assumption = APTS_VolumeCalculationEngine.getAssumption(assumptionRequest);
		System.assertEquals(60.0, assumption);

		// Calculate of getRebate
        List<Apttus_Config2__ClassificationHierarchy__c> classificationHierarchies = [select Id, Name from Apttus_Config2__ClassificationHierarchy__c];
        System.debug('list of hierarchies before run the test: ' + classificationHierarchies);                                                                          
		APTS_VolumeCalculationEngine.VolumeRebateRequest rebateRequest = new APTS_VolumeCalculationEngine.VolumeRebateRequest();
		rebateRequest.agreementId = agreements.get(0).Id;
		rebateRequest.volAssumption = assumption;
		rebateRequest.category = classificationHierarchies.get(0).Id;
		rebateRequest.grossSale = 20;
		rebateRequest.netSale = 50;

		decimal rebate = APTS_VolumeCalculationEngine.getRebate(rebateRequest);
		System.debug('Rebate to be tested: ' + rebate);
		System.assertEquals(20, rebate);
		Test.stopTest();
	}

	@isTest static void getRebateStandardTestRevenueNetPrice()
	{
		// Query of test data stored in the system
		Test.startTest();
		Id standardRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
		List<Apttus__APTS_Agreement__c> agreements = [SELECT Id 
													  FROM Apttus__APTS_Agreement__c
													  WHERE recordtypeid =: standardRecordTypeId
													  AND Name='Standard Agreement (Revenue) - Net Price'];

		// Calculate of VolumeAssumption
		APTS_VolumeCalculationEngine.VolumeAssumptionRequest assumptionRequest = new APTS_VolumeCalculationEngine.VolumeAssumptionRequest();
		assumptionRequest.agreementId = agreements.get(0).Id;
		assumptionRequest.unitfromUOM = 10;
		assumptionRequest.fromUOM = 'SAP_DRKS';
		assumptionRequest.toUOM = 'SAP_KGM';
        assumptionRequest.category = 'Coffee';
        assumptionRequest.subcategory = 'Instant';
        assumptionRequest.familyLevel = APTS_VolumeCalculationEngine.SUBCATEGORY_LEVEL;


		decimal assumption = APTS_VolumeCalculationEngine.getAssumption(assumptionRequest);
		System.assertEquals(60.0, assumption);

		// Calculate of getRebate
        List<Apttus_Config2__ClassificationHierarchy__c> classificationHierarchies = [select Id, Name from Apttus_Config2__ClassificationHierarchy__c];
        System.debug('list of hierarchies before run the test: ' + classificationHierarchies);                                                                          
		APTS_VolumeCalculationEngine.VolumeRebateRequest rebateRequest = new APTS_VolumeCalculationEngine.VolumeRebateRequest();
		rebateRequest.agreementId = agreements.get(0).Id;
		rebateRequest.volAssumption = assumption;
		rebateRequest.category = classificationHierarchies.get(0).Id;
		rebateRequest.grossSale = 20;
		rebateRequest.netSale = 50;

		decimal rebate = APTS_VolumeCalculationEngine.getRebate(rebateRequest);
		System.debug('Rebate to be tested: ' + rebate);
		System.assertEquals(100, rebate);
		Test.stopTest();
	}

	@isTest static void getRebateRatePerTierStandardTestRevenue()
	{
		// Query of test data stored in the system
		Test.startTest();
		Id standardRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
		List<Apttus__APTS_Agreement__c> agreements = [SELECT Id 
													  FROM Apttus__APTS_Agreement__c
													  WHERE recordtypeid =: standardRecordTypeId
													  AND Name='Standard Agreement (Revenue) - Rate Per Tier'];


		// Calculate of VolumeAssumption
		APTS_VolumeCalculationEngine.VolumeAssumptionRequest assumptionRequest = new APTS_VolumeCalculationEngine.VolumeAssumptionRequest();
		assumptionRequest.agreementId = agreements.get(0).Id;
		assumptionRequest.unitfromUOM = 10;
		assumptionRequest.fromUOM = 'SAP_DRKS';
		assumptionRequest.toUOM = 'SAP_KGM';
		assumptionRequest.category = 'Coffee';
        assumptionRequest.subcategory = 'Instant';
        assumptionRequest.familyLevel = APTS_VolumeCalculationEngine.SUBCATEGORY_LEVEL;


		decimal assumption = APTS_VolumeCalculationEngine.getAssumption(assumptionRequest);
		System.assertEquals(60.0, assumption);

		// Calculate of getRebate
        List<Apttus_Config2__ClassificationHierarchy__c> classificationHierarchies = [select Id, Name from Apttus_Config2__ClassificationHierarchy__c];
        System.debug('list of hierarchies before run the test: ' + classificationHierarchies);                                                                          
        APTS_VolumeCalculationEngine.VolumeRebateRequest rebateRequest = new APTS_VolumeCalculationEngine.VolumeRebateRequest();
		rebateRequest.agreementId = agreements.get(0).Id;
		rebateRequest.volAssumption = assumption;
		rebateRequest.category = classificationHierarchies.get(0).Id;
		rebateRequest.grossSale = 20;
		rebateRequest.netSale = 50;

		decimal rebate = APTS_VolumeCalculationEngine.getRebate(rebateRequest);
		System.debug('Rebate to be tested: ' + rebate);
		System.assertEquals(4, rebate);
		Test.stopTest();
	}

	@isTest static void getRebateRatePerTierStandardTestRevenueNetPrice()
	{
		// Query of test data stored in the system
		Test.startTest();
		Id standardRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
		List<Apttus__APTS_Agreement__c> agreements = [SELECT Id 
													  FROM Apttus__APTS_Agreement__c
													  WHERE recordtypeid =: standardRecordTypeId
													  AND Name='Standard Agreement (Revenue) - Net Price - Rate Per Tier'];



		// Calculate of VolumeAssumption
		APTS_VolumeCalculationEngine.VolumeAssumptionRequest assumptionRequest = new APTS_VolumeCalculationEngine.VolumeAssumptionRequest();
		assumptionRequest.agreementId = agreements.get(0).Id;
		assumptionRequest.unitfromUOM = 10;
		assumptionRequest.fromUOM = 'SAP_DRKS';
		assumptionRequest.toUOM = 'SAP_KGM';
		assumptionRequest.category = 'Coffee';
        assumptionRequest.subcategory = 'Instant';
        assumptionRequest.familyLevel = APTS_VolumeCalculationEngine.SUBCATEGORY_LEVEL;


		decimal assumption = APTS_VolumeCalculationEngine.getAssumption(assumptionRequest);
		System.assertEquals(60.0, assumption);

		// Calculate of getRebate
        List<Apttus_Config2__ClassificationHierarchy__c> classificationHierarchies = [select Id, Name from Apttus_Config2__ClassificationHierarchy__c];
        System.debug('list of hierarchies before run the test: ' + classificationHierarchies);                                                                          	
        APTS_VolumeCalculationEngine.VolumeRebateRequest rebateRequest = new APTS_VolumeCalculationEngine.VolumeRebateRequest();
		rebateRequest.agreementId = agreements.get(0).Id;
		rebateRequest.volAssumption = assumption;
		rebateRequest.category = classificationHierarchies.get(0).Id;
		rebateRequest.grossSale = 20;
		rebateRequest.netSale = 50;

		decimal rebate = APTS_VolumeCalculationEngine.getRebate(rebateRequest);
		System.debug('Rebate to be tested: ' + rebate);
		System.assertEquals(1000, rebate);
		Test.stopTest();
	}

    @isTest static void getMultipleIncentivesTest()
    {
        // Query of test data stored in the system
        Test.startTest();
        Id standardRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
        List<Apttus__APTS_Agreement__c> agreements = [SELECT Id 
                                                      FROM Apttus__APTS_Agreement__c
                                                      WHERE recordtypeid =: standardRecordTypeId
                                                      AND Name='Standard Agreement (Revenue) - Multiple Incentives'];

        // Calculate of VolumeAssumption
        APTS_VolumeCalculationEngine.VolumeAssumptionRequest assumptionRequest = new APTS_VolumeCalculationEngine.VolumeAssumptionRequest();
        assumptionRequest.agreementId = agreements.get(0).Id;
        assumptionRequest.unitfromUOM = 10;
        assumptionRequest.fromUOM = 'SAP_DRKS';
        assumptionRequest.toUOM = 'SAP_KGM';
        assumptionRequest.category = 'Coffee';
        assumptionRequest.subcategory = 'Instant';
        assumptionRequest.familyLevel = APTS_VolumeCalculationEngine.SUBCATEGORY_LEVEL;


        decimal assumption = APTS_VolumeCalculationEngine.getAssumption(assumptionRequest);
        System.assertEquals(60.0, assumption);

        // Calculate of getRebate
        List<Apttus_Config2__ClassificationHierarchy__c> classificationHierarchies = [select Id, Name from Apttus_Config2__ClassificationHierarchy__c];
        System.debug('list of hierarchies before run the test: ' + classificationHierarchies);                                                                          
        APTS_VolumeCalculationEngine.VolumeRebateRequest rebateRequest = new APTS_VolumeCalculationEngine.VolumeRebateRequest();
        rebateRequest.agreementId = agreements.get(0).Id;
        rebateRequest.volAssumption = assumption;
        rebateRequest.category = classificationHierarchies.get(0).Id;
        rebateRequest.grossSale = 20;
        rebateRequest.netSale = 50;

        decimal rebate = APTS_VolumeCalculationEngine.getRebate(rebateRequest);
        System.debug('Rebate to be tested: ' + rebate);
        System.assertEquals(2000, rebate);

        Test.stopTest();
    }  

    @isTest static void getProductAssumptionTest()
    {
        // Query of test data stored in the system
        Test.startTest();
        Id standardRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
        List<Apttus__APTS_Agreement__c> agreements = [SELECT Id 
                                                      FROM Apttus__APTS_Agreement__c
                                                      WHERE recordtypeid =: standardRecordTypeId
                                                      AND Name='Standard Agreement (Revenue) - Multiple Incentives'];

        List<Product2> prd = [Select Id from Product2 LIMIT 1];

        // Calculate of VolumeAssumption
        APTS_VolumeCalculationEngine.VolumeAssumptionRequest assumptionRequest = new APTS_VolumeCalculationEngine.VolumeAssumptionRequest();
        assumptionRequest.agreementId = agreements.get(0).Id;
        assumptionRequest.unitfromUOM = 10;
        assumptionRequest.fromUOM = 'SAP_DRKS';
        assumptionRequest.toUOM = 'SAP_KGM';
        assumptionRequest.category = 'Coffee';
        assumptionRequest.subcategory = 'Instant';
        assumptionRequest.familyLevel = APTS_VolumeCalculationEngine.PRODUCT_LEVEL;
        assumptionRequest.productId = prd.get(0).Id;


        decimal assumption = APTS_VolumeCalculationEngine.getAssumption(assumptionRequest);
        System.assertEquals(60.0, assumption);    
        Test.stopTest();       

        // Reverse calculation: From Volume Assumption to Drinks
        APTS_VolumeCalculationEngine.DrinksRequest reverseRequest = new APTS_VolumeCalculationEngine.DrinksRequest();
        reverseRequest.agreementId = agreements.get(0).Id;
        reverseRequest.volumeAssumption = assumption;
        reverseRequest.originalUOM = 'SAP_KGM';
        reverseRequest.category = 'Coffee';
        reverseRequest.subcategory = 'Instant';
        reverseRequest.productId = prd.get(0).Id;
        reverseRequest.familyLevel = APTS_VolumeCalculationEngine.PRODUCT_LEVEL;

        decimal drinks = APTS_VolumeCalculationEngine.getDrinks(reverseRequest);
        System.assertEquals(10.0, drinks);
    }

    @isTest static void getGrossSalesAndNetSalesTestCategoryLevel()
    {
        Test.startTest();
        APTS_VolumeCalculationEngine.GrossAndNetSalesRequest gsnsRequest = new APTS_VolumeCalculationEngine.GrossAndNetSalesRequest();
        gsnsRequest.familyLevel = 1;
        APTS_VolumeCalculationEngine.GrossAndNetSalesResponse gsnsResponse = APTS_VolumeCalculationEngine.getGrossAndNetValues(gsnsRequest);
        Test.stopTest();
    }

    @isTest static void getGrossSalesAndNetSalesTestSubCategoryLevel()
    {
        Test.startTest();
        APTS_VolumeCalculationEngine.GrossAndNetSalesRequest gsnsRequest = new APTS_VolumeCalculationEngine.GrossAndNetSalesRequest();
        gsnsRequest.familyLevel = 2;
        APTS_VolumeCalculationEngine.GrossAndNetSalesResponse gsnsResponse = APTS_VolumeCalculationEngine.getGrossAndNetValues(gsnsRequest);
        Test.stopTest();
    }

    @isTest static void getGrossSalesAndNetSalesTestSubSubCategoryLevel()
    {
        Test.startTest();
        APTS_VolumeCalculationEngine.GrossAndNetSalesRequest gsnsRequest = new APTS_VolumeCalculationEngine.GrossAndNetSalesRequest();
        gsnsRequest.familyLevel = 3;
        APTS_VolumeCalculationEngine.GrossAndNetSalesResponse gsnsResponse = APTS_VolumeCalculationEngine.getGrossAndNetValues(gsnsRequest);
        Test.stopTest();
    }

    @isTest static void getGrossSalesAndNetSalesTestProductLevel()
    {
        Test.startTest();
        APTS_VolumeCalculationEngine.GrossAndNetSalesRequest gsnsRequest = new APTS_VolumeCalculationEngine.GrossAndNetSalesRequest();
        gsnsRequest.familyLevel = 4;
        APTS_VolumeCalculationEngine.GrossAndNetSalesResponse gsnsResponse = APTS_VolumeCalculationEngine.getGrossAndNetValues(gsnsRequest);
        Test.stopTest();
    }
}