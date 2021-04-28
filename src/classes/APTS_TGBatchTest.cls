/*******************************************************************************************
Name            : APTS_TGBatchTest
Created By      : Ariel Quesada
Created Date    : 06/19/2018
Description     : This class is the test class for APTS_TGBatch
Version history : 
*********************************************************************************************/
@isTest
private class APTS_TGBatchTest {

	static Integer NUMBER_TEST_RECORDS = 6;

    // 8 accounts for different test scenarios
    static Account nullAccount;
    static Account nonTGAccount;
    static Account childAccount;
    static Account parentAccount;
    static Account grandParentAccount;
    static Account nonContractedProductsAccountLooped;
    static Account nonContractedProductsAccountNonLooped;
    static Account contractedProductsAccountNonLooped;
    static Account contractedProductsAccountLooped;


    @isTest static void testBatch() 
    {
        Test.startTest();   

        CreateTestDataforTG();
        APTS_TGBatch batch = new APTS_TGBatch();
        Id batchJobId = Database.executeBatch(batch);

        Test.stopTest();
    }

    @isTest static void isTGApplicableTest()
    {
        Test.startTest();

        List<Account> accounts = new List<Account>();
        Account yesTGAccount;
        yesTGAccount = new Account();
        yesTGAccount.Name = 'Yes TG Account';
        yesTGAccount.Phone='+11111111111';
        yesTGAccount.Main_Street_Only__c = 'Test Street';
        yesTGAccount.Main_House_Number__c = 'Test no.';
        yesTGAccount.Sales_Organization__c = 'SAP_0111';
        yesTGAccount.APTS_Partner_Pricing_Portal_Applicable__c = true;
        accounts.add(yesTGAccount);

        Account nonTGAccount;
        nonTGAccount = new Account();
        nonTGAccount.Name = 'Non TG Account';
        nonTGAccount.Phone='+11111111111';
        nonTGAccount.Main_Street_Only__c = 'Test Street';
        nonTGAccount.Main_House_Number__c = 'Test no.';
        nonTGAccount.Sales_Organization__c = 'SAP_0111';
        nonTGAccount.APTS_Partner_Pricing_Portal_Applicable__c = false;
        accounts.add(nonTGAccount);
        
        insert accounts;

        System.assert(APTS_TGBatch.isTGApplicable(yesTGAccount) == true);
        System.assert(APTS_TGBatch.isTGApplicable(nonTGAccount) == false);
        Test.stopTest();
    }


    @isTest static void isTGLoopedTest()
    {
        Test.startTest();

        List<Account> accounts = new List<Account>();
        Account yesTGLoopedAccount;
        yesTGLoopedAccount = new Account();
        yesTGLoopedAccount.Name = 'TG Looped Account';
        yesTGLoopedAccount.Phone='+11111111111';
        yesTGLoopedAccount.Main_Street_Only__c = 'Test Street';
        yesTGLoopedAccount.Main_House_Number__c = 'Test no.';
        yesTGLoopedAccount.Sales_Organization__c = 'SAP_0111';
        yesTGLoopedAccount.APTS_Partner_Pricing_Portal_Looped_in__c = true;
        accounts.add(yesTGLoopedAccount);

        Account nonTGLoopedAccount;
        nonTGLoopedAccount = new Account();
        nonTGLoopedAccount.Name = 'TG Non Looped Account';
        nonTGLoopedAccount.Phone='+11111111111';
        nonTGLoopedAccount.Main_Street_Only__c = 'Test Street';
        nonTGLoopedAccount.Main_House_Number__c = 'Test no.';
        nonTGLoopedAccount.Sales_Organization__c = 'SAP_0111';
        nonTGLoopedAccount.APTS_Partner_Pricing_Portal_Looped_in__c = false;
        accounts.add(nonTGLoopedAccount);

        insert accounts;

        System.assert(APTS_TGBatch.isTGLoopedIn(yesTGLoopedAccount) == true);
        System.assert(APTS_TGBatch.isTGLoopedIn(nonTGLoopedAccount) == false);

        APTS_TGBatch.setTGLoopedIn(yesTGLoopedAccount, false);
        APTS_TGBatch.setTGLoopedIn(nonTGLoopedAccount, true);

        System.assert(APTS_TGBatch.isTGLoopedIn(yesTGLoopedAccount) == false);
        System.assert(APTS_TGBatch.isTGLoopedIn(nonTGLoopedAccount) == true);

        Test.stopTest();
    }


 
    @isTest static void unionTest()
    {
        Test.startTest();

        List<Product2> list1 = new List<Product2>();
        List<Product2> list2 = new List<Product2>();

        Product2 product1 = new Product2();
        product1.Name = 'A';
        product1.ProductCode = 'A';
        product1.Family = 'Tea';
        product1.IsActive = true;

        Product2 product2 = new Product2();
        product2.Name = 'B';
        product2.ProductCode = 'B';
        product2.Family = 'Tea';
        product2.IsActive = true;

        Product2 product3 = new Product2();
        product3.Name = 'C';
        product3.ProductCode = 'C';
        product3.Family = 'Tea';
        product3.IsActive = true;

        Product2 product4 = new Product2();
        product4.Name = 'D';
        product4.ProductCode = 'D';
        product4.Family = 'Tea';
        product4.IsActive = true;

        Product2 product5 = new Product2();
        product5.Name = 'E';
        product5.ProductCode = 'E';
        product5.Family = 'Tea';
        product5.IsActive = true;

        list1.add(product1);
        list1.add(product2);
        list1.add(product3);

        list2.add(product3);
        list2.add(product4);
        list2.add(product5);

        // Test#1
        List<Product2> union1 = APTS_TGBatch.unionOfListProducts(list1,list2);
        System.assertEquals(5, union1.size());

        // Test#2
        List<Product2> union2 = APTS_TGBatch.unionOfListProducts(list1, null);
        System.assertEquals(3, union2.size());        

        Test.stopTest();

    }

    @isTest static void intersectTest()
    {
        Test.startTest();

        List<Product2> list1 = new List<Product2>();
        List<Product2> list2 = new List<Product2>();

        Product2 product1 = new Product2();
        product1.Name = 'A';
        product1.ProductCode = 'A';
        product1.Family = 'Tea';
        product1.IsActive = true;

        Product2 product2 = new Product2();
        product2.Name = 'B';
        product2.ProductCode = 'B';
        product2.Family = 'Tea';
        product2.IsActive = true;

        Product2 product3 = new Product2();
        product3.Name = 'C';
        product3.ProductCode = 'C';
        product3.Family = 'Tea';
        product3.IsActive = true;

        Product2 product4 = new Product2();
        product4.Name = 'D';
        product4.ProductCode = 'D';
        product4.Family = 'Tea';
        product4.IsActive = true;

        Product2 product5 = new Product2();
        product5.Name = 'E';
        product5.ProductCode = 'E';
        product5.Family = 'Tea';
        product5.IsActive = true;

        list1.add(product1);
        list1.add(product2);
        list1.add(product3);

        list2.add(product3);
        list2.add(product4);
        list2.add(product5);

        // Test #1
        List<Product2> intersect1 = APTS_TGBatch.intersectionOfListProducts(list1,list2);
        System.assertEquals(1, intersect1.size());

        // Test #2
        List<Product2> intersect2 = APTS_TGBatch.intersectionofListProducts(list1, null);
        System.assertEquals(0, intersect2.size());
        Test.stopTest();
    }

    static void CreateTestDataforTG()
    {   
        // Section 1: Creation of the contact
        Contact primaryContact = new Contact();
        primaryContact.FirstName = 'Test';
        primaryContact.LastName = ' Primary Contact';
        primaryContact.Email = 'xyz@abc.com';
        primaryContact.Phone = '+11111111111';
        insert primaryContact;

        // Section 2: Creation of accounts
        Account nullAccount = null; // Dummy account to cover null scenarios

        grandParentAccount = new Account ();
        grandParentAccount.Name = 'AccountGrandParent';
        grandParentAccount.Phone='+11111111111';
        grandParentAccount.Main_Street_Only__c = 'Test Street';
        grandParentAccount.Main_House_Number__c = 'Test no.';
        grandParentAccount.Sales_Organization__c = 'SAP_0111';
        grandParentAccount.APTS_Partner_Pricing_Portal_Applicable__c = true;
        grandParentAccount.SAP_Customer_ID__c = '101';
        insert grandParentAccount;

        parentAccount = new Account();
        parentAccount.Name = 'AccountParent';
        parentAccount.Phone='+11111111111';
        parentAccount.Main_Street_Only__c = 'Test Street';
        parentAccount.Main_House_Number__c = 'Test no.';
        parentAccount.ParentId = grandParentAccount.Id;
        parentAccount.Sales_Organization__c = 'SAP_0111';
        parentAccount.APTS_Partner_Pricing_Portal_Applicable__c = true;
        ParentAccount.SAP_Customer_ID__c = '102';
        insert parentAccount;


        List<Account> accounts = new List<Account>();

        childAccount = new Account();
        childAccount.Name = 'AccountChild';
        childAccount.Phone='+11111111111';
        childAccount.Main_Street_Only__c = 'Test Street';
        childAccount.Main_House_Number__c = 'Test no.';
        childAccount.ParentId = parentAccount.Id;
        childAccount.Sales_Organization__c = 'SAP_0111';
        childAccount.APTS_Partner_Pricing_Portal_Applicable__c = true;
        childAccount.SAP_Customer_ID__c = '103';        
        accounts.add(childAccount);

        nonTGAccount = new Account();
        nonTGAccount.Name = 'Non TG Account';
        nonTGAccount.Phone='+11111111111';
        nonTGAccount.Main_Street_Only__c = 'Test Street';
        nonTGAccount.Main_House_Number__c = 'Test no.';
        nonTGAccount.Sales_Organization__c = 'SAP_0111';
        nonTGAccount.SAP_Customer_ID__c = '104';
        nonTGAccount.APTS_Partner_Pricing_Portal_Applicable__c = false;
        accounts.add(nonTGAccount);

        nonContractedProductsAccountLooped = new Account();
        nonContractedProductsAccountLooped.Name = 'Non Contracted products Account Looped';
        nonContractedProductsAccountLooped.Phone='+11111111111';
        nonContractedProductsAccountLooped.Main_Street_Only__c = 'Test Street';
        nonContractedProductsAccountLooped.Main_House_Number__c = 'Test no.';
        nonContractedProductsAccountLooped.Sales_Organization__c = 'SAP_0111';
        nonContractedProductsAccountLooped.APTS_Partner_Pricing_Portal_Applicable__c = true;
        nonContractedProductsAccountLooped.SAP_Customer_ID__c = '105';
        nonContractedProductsAccountLooped.APTS_Partner_Pricing_Portal_Looped_in__c = true;
        accounts.add(nonContractedProductsAccountLooped);

        nonContractedProductsAccountNonLooped = new Account();
        nonContractedProductsAccountNonLooped.Name = 'Non Contracted products Account Non Looped';
        nonContractedProductsAccountNonLooped.Phone='+11111111111';
        nonContractedProductsAccountNonLooped.Main_Street_Only__c = 'Test Street';
        nonContractedProductsAccountNonLooped.Main_House_Number__c = 'Test no.';
        nonContractedProductsAccountNonLooped.Sales_Organization__c = 'SAP_0111';
        nonContractedProductsAccountNonLooped.APTS_Partner_Pricing_Portal_Applicable__c = true;
        nonContractedProductsAccountNonLooped.SAP_Customer_ID__c = '106';
        nonContractedProductsAccountNonLooped.APTS_Partner_Pricing_Portal_Looped_in__c = false;
        accounts.add(nonContractedProductsAccountNonLooped);

        contractedProductsAccountNonLooped = new Account();
        contractedProductsAccountNonLooped.Name = 'Contracted products Account Non Looped';
        contractedProductsAccountNonLooped.Phone='+11111111111';
        contractedProductsAccountNonLooped.Main_Street_Only__c = 'Test Street';
        contractedProductsAccountNonLooped.Main_House_Number__c = 'Test no.';
        contractedProductsAccountNonLooped.Sales_Organization__c = 'SAP_0111';
        contractedProductsAccountNonLooped.APTS_Partner_Pricing_Portal_Applicable__c = true;
        contractedProductsAccountNonLooped.SAP_Customer_ID__c = '107';
        contractedProductsAccountNonLooped.APTS_Partner_Pricing_Portal_Looped_in__c = false;
        accounts.add(contractedProductsAccountNonLooped);

        contractedProductsAccountLooped = new Account();
        contractedProductsAccountLooped.Name = 'Contracted products Account Looped';
        contractedProductsAccountLooped.Phone='+11111111111';
        contractedProductsAccountLooped.Main_Street_Only__c = 'Test Street';
        contractedProductsAccountLooped.Main_House_Number__c = 'Test no.';
        contractedProductsAccountLooped.Sales_Organization__c = 'SAP_0111';
        contractedProductsAccountLooped.APTS_Partner_Pricing_Portal_Applicable__c = true;
        contractedProductsAccountLooped.SAP_Customer_ID__c = '108';
        contractedProductsAccountLooped.APTS_Partner_Pricing_Portal_Looped_in__c = true;
        accounts.add(contractedProductsAccountLooped);

        insert accounts;

        System.debug('APTS_TGBatchTest: Accounts created');        

        // Section 3: Creation of Opportunities
        List<Opportunity> opportunities = new List<Opportunity>();
        Opportunity grandParentOpportunity = new Opportunity();
        grandParentOpportunity.Name = 'Grand Parent Opportunity';
        grandParentOpportunity.AccountId = grandParentAccount.Id;
        grandParentOpportunity.Go_To_Market__c = 'Direct';
        grandParentOpportunity.StageName = 'Proposal';
        grandParentOpportunity.CloseDate = date.Today().addDays(365);
        grandParentOpportunity.Probability = 10;
        opportunities.add(grandParentOpportunity);

        Opportunity parentOpportunity = new Opportunity();
        parentOpportunity.Name = 'Parent Opportunity';
        parentOpportunity.AccountId = parentAccount.Id;
        parentOpportunity.Go_To_Market__c = 'Direct';
        parentOpportunity.StageName = 'Proposal';
        parentOpportunity.CloseDate = date.Today().addDays(365);
        parentOpportunity.Probability = 10;
        opportunities.add(parentOpportunity);

        Opportunity childOpportunity = new Opportunity();
        childOpportunity.Name = 'Child Opportunity';
        childOpportunity.AccountId = childAccount.Id;
        childOpportunity.Go_To_Market__c = 'Direct';
        childOpportunity.StageName = 'Proposal';
        childOpportunity.CloseDate = date.Today().addDays(365);
        childOpportunity.Probability = 10;
        opportunities.add(childOpportunity);
        insert opportunities;

        System.debug('APTS_TGBatchTest: Opportunities created.');

        // Section 4: Creation of products
        List<Product2> products = new List<Product2>();
        Product2 childProduct1 = new Product2();
        childProduct1.Name = 'Child Product1';
        childProduct1.ProductCode = 'CP1';
        childProduct1.Family = 'Tea';
        childProduct1.IsActive = true;
        childProduct1.Apttus_Config2__ConfigurationType__c = 'Standalone';
        childProduct1.Apttus_Config2__Uom__c = 'Each';
        products.add(childProduct1);

        Product2 childProduct2 = new Product2();
        childProduct2.Name = 'Child Product2';
        childProduct2.ProductCode = 'CP2';
        childProduct2.Family = 'Coffee';
        childProduct2.IsActive = true;
        childProduct2.Apttus_Config2__ConfigurationType__c = 'Standalone';
        childProduct2.Apttus_Config2__Uom__c = 'Each';
        products.add(childProduct2);

        Product2 parentProduct1 = new Product2();
        parentProduct1.Name = 'Parent Product1';
        parentProduct1.ProductCode = 'PP1';
        parentProduct1.Family = 'Tea';
        parentProduct1.IsActive = true;
        parentProduct1.Apttus_Config2__ConfigurationType__c = 'Standalone';
        parentProduct1.Apttus_Config2__Uom__c = 'Each';
        products.add(parentProduct1);

        Product2 parentProduct2 = new Product2();
        parentProduct2.Name = 'Parent Product2';
        parentProduct2.ProductCode = 'PP2';
        parentProduct2.Family = 'Coffee';
        parentProduct2.IsActive = true;
        parentProduct2.Apttus_Config2__ConfigurationType__c = 'Standalone';
        parentProduct2.Apttus_Config2__Uom__c = 'Each';
        products.add(parentProduct2);

        Product2 grandParentProduct1 = new Product2();
        grandParentProduct1.Name = 'Grand Parent Product1';
        grandParentProduct1.ProductCode = 'GPP1';
        grandParentProduct1.Family = 'Tea';
        grandParentProduct1.IsActive = true;
        grandParentProduct1.Apttus_Config2__ConfigurationType__c = 'Standalone';
        grandParentProduct1.Apttus_Config2__Uom__c = 'Each';
        products.add(grandParentProduct1);

        Product2 grandParentProduct2 = new Product2();
        grandParentProduct2.Name = 'Grand Parent Product2';
        grandParentProduct2.ProductCode = 'GPP2';
        grandParentProduct2.Family = 'Coffee';
        grandParentProduct2.IsActive = true;
        grandParentProduct2.Apttus_Config2__ConfigurationType__c = 'Standalone';
        grandParentProduct2.Apttus_Config2__Uom__c = 'Each';
        products.add(grandParentProduct2);
        insert products;

        System.debug('APTS_TGBatchTest: Products created.');

        List<Product2> productsCreated = [SELECT Id, Name FROM Product2];

        // Creation of category
        Apttus_Config2__ClassificationName__c category = new Apttus_Config2__ClassificationName__c();
        category.Name = 'Machines';
        category.Apttus_Config2__Active__c = true;
        category.Apttus_Config2__HierarchyLabel__c = 'Machines';
        category.Apttus_Config2__Type__c = 'Offering';
        category.APTS_Allow_Adjustments__c = true;
        insert category;

        // Creation of category hierarchy
        Apttus_Config2__ClassificationHierarchy__c categoryHierarchy = new Apttus_Config2__ClassificationHierarchy__c();
        categoryHierarchy.Name = 'Machines';
        categoryHierarchy.Apttus_Config2__HierarchyId__c = category.Id;
        categoryHierarchy.Apttus_Config2__AncestorId__c = null;
        categoryHierarchy.Apttus_Config2__DefaultSearchCategory__c = false;
        categoryHierarchy.Apttus_Config2__ExpandedByDefault__c = false;
        categoryHierarchy.Apttus_Config2__HideAllSearchFilters__c = false;
        categoryHierarchy.Apttus_Config2__IncludeInTotalsView__c = true;
        categoryHierarchy.Apttus_Config2__IsHidden__c = false;
        categoryHierarchy.Apttus_Config2__IsPicklist__c = false;
        categoryHierarchy.Apttus_Config2__Label__c = 'Machines';
        categoryHierarchy.Apttus_Config2__LargeImageSize__c = '20x20';
        categoryHierarchy.Apttus_Config2__Left__c = 1;
        categoryHierarchy.Apttus_Config2__Level__c = 0;
        categoryHierarchy.Apttus_Config2__MaxOptions__c = 1.00000;
        categoryHierarchy.Apttus_Config2__MinOptions__c = 1.00000;
        categoryHierarchy.Apttus_Config2__Modifiable__c = true;
        categoryHierarchy.Apttus_Config2__PrimordialId__c = null;
        categoryHierarchy.Apttus_Config2__ProductAttributeGroupId__c = null;
        categoryHierarchy.Apttus_Config2__Right__c = 20;
        insert categoryHierarchy;

        // Creation of subcategory hierarchy
        Apttus_Config2__ClassificationHierarchy__c subCategoryHierarchy = new Apttus_Config2__ClassificationHierarchy__c();
        subCategoryHierarchy.Name = 'Cafitesse';
        subCategoryHierarchy.CurrencyIsoCode = 'EUR';
        subCategoryHierarchy.Apttus_Config2__HierarchyId__c = category.Id;
        subCategoryHierarchy.Apttus_Config2__AncestorId__c = categoryHierarchy.Id;
        subCategoryHierarchy.Apttus_Config2__DefaultSearchCategory__c = false;
        subCategoryHierarchy.Apttus_Config2__ExpandedByDefault__c = false;
        subCategoryHierarchy.Apttus_Config2__HideAllSearchFilters__c = false;
        subCategoryHierarchy.Apttus_Config2__IncludeInTotalsView__c = true;
        subCategoryHierarchy.Apttus_Config2__IsHidden__c = false;
        subCategoryHierarchy.Apttus_Config2__IsPicklist__c = false;
        subCategoryHierarchy.Apttus_Config2__Label__c = 'Cafitesse';
        subCategoryHierarchy.Apttus_Config2__Left__c = 2;
        subCategoryHierarchy.Apttus_Config2__Level__c = 1;
        subCategoryHierarchy.Apttus_Config2__MaxOptions__c = 1.00000;
        subCategoryHierarchy.Apttus_Config2__MinOptions__c = 1.00000;
        subCategoryHierarchy.Apttus_Config2__Modifiable__c = true;
        subCategoryHierarchy.Apttus_Config2__PrimordialId__c = categoryHierarchy.Id;
        subCategoryHierarchy.Apttus_Config2__ProductAttributeGroupId__c = null;
        subCategoryHierarchy.Apttus_Config2__Right__c = 3;
        insert subCategoryHierarchy;

        // Creation of subsubcategory hierarchy
        Apttus_Config2__ClassificationHierarchy__c subSubCategoryHierarchy = new Apttus_Config2__ClassificationHierarchy__c();
        subSubCategoryHierarchy.Name = 'Sub Sub Category Beans';
        subSubCategoryHierarchy.CurrencyIsoCode = 'EUR';
        subSubCategoryHierarchy.Apttus_Config2__HierarchyId__c = category.Id;
        subSubCategoryHierarchy.Apttus_Config2__AncestorId__c = subCategoryHierarchy.Id;
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
        subSubCategoryHierarchy.Apttus_Config2__Modifiable__c = true;
        subSubCategoryHierarchy.Apttus_Config2__PrimordialId__c = categoryHierarchy.Id;
        subSubCategoryHierarchy.Apttus_Config2__ProductAttributeGroupId__c = null;
        subSubCategoryHierarchy.Apttus_Config2__Right__c = 3;
        insert subSubCategoryHierarchy;

        // Product Classification
        List<Apttus_Config2__ProductClassification__c> productClassifications = new List<Apttus_Config2__ProductClassification__c>();

        Apttus_Config2__ProductClassification__c childproductClassification1 = new Apttus_Config2__ProductClassification__c();
        childproductClassification1.Apttus_Config2__ClassificationId__c = subCategoryHierarchy.Id;
        childproductClassification1.Apttus_Config2__DefaultQuantity__c = 1.00000;
        childproductClassification1.Apttus_Config2__MaxQuantity__c =  1.00000;
        childproductClassification1.Apttus_Config2__MinQuantity__c = 0.00000;
        childproductClassification1.Apttus_Config2__MinQuantity__c = 0.00000;
        childproductClassification1.Apttus_Config2__Modifiable__c = true;
        childproductClassification1.Apttus_Config2__ProductId__c = childProduct1.Id;
        productClassifications.add(childproductClassification1);

        Apttus_Config2__ProductClassification__c childproductClassification2 = new Apttus_Config2__ProductClassification__c();
        childproductClassification2.Apttus_Config2__ClassificationId__c = subCategoryHierarchy.Id;
        childproductClassification2.Apttus_Config2__DefaultQuantity__c = 1.00000;
        childproductClassification2.Apttus_Config2__MaxQuantity__c =  1.00000;
        childproductClassification2.Apttus_Config2__MinQuantity__c = 0.00000;
        childproductClassification2.Apttus_Config2__MinQuantity__c = 0.00000;
        childproductClassification2.Apttus_Config2__Modifiable__c = true;
        childproductClassification2.Apttus_Config2__ProductId__c = childProduct2.Id;
        productClassifications.add(childproductClassification2);

        Apttus_Config2__ProductClassification__c parentproductClassification1 = new Apttus_Config2__ProductClassification__c();
        parentproductClassification1.Apttus_Config2__ClassificationId__c = subCategoryHierarchy.Id;
        parentproductClassification1.Apttus_Config2__DefaultQuantity__c = 1.00000;
        parentproductClassification1.Apttus_Config2__MaxQuantity__c =  1.00000;
        parentproductClassification1.Apttus_Config2__MinQuantity__c = 0.00000;
        parentproductClassification1.Apttus_Config2__MinQuantity__c = 0.00000;
        parentproductClassification1.Apttus_Config2__Modifiable__c = true;
        parentproductClassification1.Apttus_Config2__ProductId__c = parentProduct1.Id;
        productClassifications.add(parentproductClassification1);

        Apttus_Config2__ProductClassification__c parentproductClassification2 = new Apttus_Config2__ProductClassification__c();
        parentproductClassification2.Apttus_Config2__ClassificationId__c = subCategoryHierarchy.Id;
        parentproductClassification2.Apttus_Config2__DefaultQuantity__c = 1.00000;
        parentproductClassification2.Apttus_Config2__MaxQuantity__c =  1.00000;
        parentproductClassification2.Apttus_Config2__MinQuantity__c = 0.00000;
        parentproductClassification2.Apttus_Config2__MinQuantity__c = 0.00000;
        parentproductClassification2.Apttus_Config2__Modifiable__c = true;
        parentproductClassification2.Apttus_Config2__ProductId__c = parentProduct2.Id;
        productClassifications.add(parentproductClassification2);

        Apttus_Config2__ProductClassification__c grandParentproductClassification1 = new Apttus_Config2__ProductClassification__c();
        grandParentproductClassification1.Apttus_Config2__ClassificationId__c = subCategoryHierarchy.Id;
        grandParentproductClassification1.Apttus_Config2__DefaultQuantity__c = 1.00000;
        grandParentproductClassification1.Apttus_Config2__MaxQuantity__c =  1.00000;
        grandParentproductClassification1.Apttus_Config2__MinQuantity__c = 0.00000;
        grandParentproductClassification1.Apttus_Config2__MinQuantity__c = 0.00000;
        grandParentproductClassification1.Apttus_Config2__Modifiable__c = true;
        grandParentproductClassification1.Apttus_Config2__ProductId__c = grandParentProduct1.Id;
        productClassifications.add(grandParentproductClassification1);

        Apttus_Config2__ProductClassification__c grandParentproductClassification2 = new Apttus_Config2__ProductClassification__c();
        grandParentproductClassification2.Apttus_Config2__ClassificationId__c = subCategoryHierarchy.Id;
        grandParentproductClassification2.Apttus_Config2__DefaultQuantity__c = 1.00000;
        grandParentproductClassification2.Apttus_Config2__MaxQuantity__c =  1.00000;
        grandParentproductClassification2.Apttus_Config2__MinQuantity__c = 0.00000;
        grandParentproductClassification2.Apttus_Config2__MinQuantity__c = 0.00000;
        grandParentproductClassification2.Apttus_Config2__Modifiable__c = true;
        grandParentproductClassification2.Apttus_Config2__ProductId__c = grandParentProduct2.Id;
        productClassifications.add(grandParentproductClassification2);

        insert productClassifications;

        System.debug('APTS_TGBatchTest: Category and classification created.');

        // Price List
        Apttus_Config2__PriceList__c priceList = new Apttus_Config2__PriceList__c();
        priceList.Name = 'Germany General Pricelist - EUR';
        priceList.Apttus_Config2__Active__c = true;
        priceList.APTS_SalesOrg__c = 'SalesOrg';
        insert priceList;

        // Price List Items
        List<Apttus_Config2__PriceListItem__c> PLIs = new List<Apttus_Config2__PriceListItem__c>();

        Apttus_Config2__PriceListItem__c childPLI1 = new Apttus_Config2__PriceListItem__c();
        childPLI1.Apttus_Config2__PriceListId__c = priceList.Id;
        childPLI1.Apttus_Config2__ProductId__c = childProduct1.Id;
        childPLI1.Apttus_Config2__ListPrice__c = 10;
        childPLI1.Apttus_Config2__ChargeType__c = 'Sales Price';
        childPLI1.Apttus_Config2__PriceType__c = 'One Time';
        childPLI1.Apttus_Config2__PriceMethod__c = 'Per Unit';
        childPLI1.Apttus_Config2__Active__c = true;
        childPLI1.Apttus_Config2__BillingFrequency__c = 'One Time';
        childPLI1.Apttus_Config2__BillingRule__c = 'Bill In Advance';
        childPLI1.APTS_Status__c = 'New';
        childPLI1.Apttus_Config2__PriceUom__c = 'SAP_BX';
        PLIs.add(childPLI1);

        Apttus_Config2__PriceListItem__c childPLI2 = new Apttus_Config2__PriceListItem__c();
        childPLI2.Apttus_Config2__PriceListId__c = priceList.Id;
        childPLI2.Apttus_Config2__ProductId__c = childProduct2.Id;
        childPLI2.Apttus_Config2__ListPrice__c = 20;
        childPLI2.Apttus_Config2__ChargeType__c = 'Sales Price';
        childPLI2.Apttus_Config2__PriceType__c = 'One Time';
        childPLI2.Apttus_Config2__PriceMethod__c = 'Per Unit';
        childPLI2.Apttus_Config2__Active__c = true;
        childPLI2.Apttus_Config2__BillingFrequency__c = 'One Time';
        childPLI2.Apttus_Config2__BillingRule__c = 'Bill In Advance';
        childPLI2.APTS_Status__c = 'New';
        childPLI2.Apttus_Config2__PriceUom__c = 'SAP_PCE';
        PLIs.add(childPLI2);

        Apttus_Config2__PriceListItem__c parentPLI1 = new Apttus_Config2__PriceListItem__c();
        parentPLI1.Apttus_Config2__PriceListId__c = priceList.Id;
        parentPLI1.Apttus_Config2__ProductId__c = parentProduct1.Id;
        parentPLI1.Apttus_Config2__ListPrice__c = 30;
        parentPLI1.Apttus_Config2__ChargeType__c = 'Sales Price';
        parentPLI1.Apttus_Config2__PriceType__c = 'One Time';
        parentPLI1.Apttus_Config2__PriceMethod__c = 'Per Unit';
        parentPLI1.Apttus_Config2__Active__c = true;
        parentPLI1.Apttus_Config2__BillingFrequency__c = 'One Time';
        parentPLI1.Apttus_Config2__BillingRule__c = 'Bill In Advance';
        parentPLI1.APTS_Status__c = 'Adjusted';
        parentPLI1.Apttus_Config2__PriceUom__c = 'SAP_PCE';
        PLIs.add(parentPLI1);
        
        Apttus_Config2__PriceListItem__c parentPLI2 = new Apttus_Config2__PriceListItem__c();
        parentPLI2.Apttus_Config2__PriceListId__c = priceList.Id;
        parentPLI2.Apttus_Config2__ProductId__c = parentProduct2.Id;
        parentPLI2.Apttus_Config2__ListPrice__c = 40;
        parentPLI2.Apttus_Config2__ChargeType__c = 'Sales Price';
        parentPLI2.Apttus_Config2__PriceType__c = 'One Time';
        parentPLI2.Apttus_Config2__PriceMethod__c = 'Per Unit';
        parentPLI2.Apttus_Config2__Active__c = true;
        parentPLI2.Apttus_Config2__BillingFrequency__c = 'One Time';
        parentPLI2.Apttus_Config2__BillingRule__c = 'Bill In Advance';
        parentPLI2.APTS_Status__c = 'Adjusted';
        parentPLI2.Apttus_Config2__PriceUom__c = 'SAP_PCE';
        PLIs.add(parentPLI2);

        Apttus_Config2__PriceListItem__c grandParentPLI1 = new Apttus_Config2__PriceListItem__c();
        grandParentPLI1.Apttus_Config2__PriceListId__c = priceList.Id;
        grandParentPLI1.Apttus_Config2__ProductId__c = grandParentProduct1.Id;
        grandParentPLI1.Apttus_Config2__ListPrice__c = 50;
        grandParentPLI1.Apttus_Config2__ChargeType__c = 'Sales Price';
        grandParentPLI1.Apttus_Config2__PriceType__c = 'One Time';
        grandParentPLI1.Apttus_Config2__PriceMethod__c = 'Per Unit';
        grandParentPLI1.Apttus_Config2__Active__c = true;
        grandParentPLI1.Apttus_Config2__BillingFrequency__c = 'One Time';
        grandParentPLI1.Apttus_Config2__BillingRule__c = 'Bill In Advance';
        grandParentPLI1.APTS_Status__c = 'New';
        grandParentPLI1.Apttus_Config2__PriceUom__c = 'SAP_PCE';
        PLIs.add(grandParentPLI1);
        
        Apttus_Config2__PriceListItem__c grandParentPLI2 = new Apttus_Config2__PriceListItem__c();
        grandParentPLI2.Apttus_Config2__PriceListId__c = priceList.Id;
        grandParentPLI2.Apttus_Config2__ProductId__c = grandParentProduct2.Id;
        grandParentPLI2.Apttus_Config2__ListPrice__c = 60;
        grandParentPLI2.Apttus_Config2__ChargeType__c = 'Sales Price';
        grandParentPLI2.Apttus_Config2__PriceType__c = 'One Time';
        grandParentPLI2.Apttus_Config2__PriceMethod__c = 'Per Unit';
        grandParentPLI2.Apttus_Config2__Active__c = true;
        grandParentPLI2.Apttus_Config2__BillingFrequency__c = 'One Time';
        grandParentPLI2.Apttus_Config2__BillingRule__c = 'Bill In Advance';
        grandParentPLI2.Apttus_Config2__PriceUom__c = 'SAP_PCE';
        PLIs.add(grandParentPLI2);
        insert PLIs;

        System.debug('APTS_TGBatchTest: Price List and Price List Items inserted.');

        // Creation of Product Attribute Group
        Apttus_Config2__ProductAttributeGroup__c productAttributeGroup = new Apttus_Config2__ProductAttributeGroup__c();
        productAttributeGroup.Name = 'Test Product Attribute Group';
        productAttributeGroup.Apttus_Config2__BusinessObject__c = 'Apttus_Config2__ProductAttributeValue__c';
        productAttributeGroup.Apttus_Config2__Description__c = 'Test Product Attribute Group';
        productAttributeGroup.Apttus_Config2__TwoColumnAttributeDisplay__c = true;
        insert productAttributeGroup;

        Apttus_Config2__ProductAttribute__c productAttribute = new Apttus_Config2__ProductAttribute__c();
        productAttribute.Apttus_Config2__Sequence__c = 1;
        productAttribute.Apttus_Config2__Field__c = 'Warranty__c';
        productAttribute.Apttus_Config2__AttributeGroupId__c = productAttributeGroup.Id;
        insert productAttribute;

        // Creation of Price Dimension
        List<Apttus_Config2__PriceDimension__c> listPriceDimension = new List<Apttus_Config2__PriceDimension__c>();
        Apttus_Config2__PriceDimension__c priceDimension = new Apttus_Config2__PriceDimension__c();
        priceDimension.Name = 'priceDimension1';
        priceDimension.Apttus_Config2__ContextType__c = 'Product Attribute';
        priceDimension.Apttus_Config2__BusinessObject__c = 'Apttus_Config2__ProductAttributeValue__c';
        priceDimension.Apttus_Config2__Datasource__c = 'Warranty__c';
        priceDimension.Apttus_Config2__AttributeId__c = productAttribute.Id;
        listPriceDimension.add(priceDimension);
        insert listPriceDimension;

        System.debug('APTS_TGBatchTest: Price configuration inserted.');

        // Price Matrix
        List<Apttus_Config2__PriceMatrix__c> priceMatrixes = new List<Apttus_Config2__PriceMatrix__c>();

        Apttus_Config2__PriceMatrix__c childPM1 = new Apttus_Config2__PriceMatrix__c();
        childPM1.Apttus_Config2__Sequence__c = 1;
        childPM1.Apttus_Config2__PriceListItemId__c = childPLI1.Id;
        childPM1.Apttus_Config2__Dimension1Id__c = listPriceDimension.get(0).Id;
        childPM1.Apttus_Config2__Dimension1ValueType__c = 'Discrete';
        priceMatrixes.add(childPM1);

        Apttus_Config2__PriceMatrix__c childPM2 = new Apttus_Config2__PriceMatrix__c();
        childPM2.Apttus_Config2__Sequence__c = 1;
        childPM2.Apttus_Config2__PriceListItemId__c = childPLI2.Id;
        childPM2.Apttus_Config2__Dimension1Id__c = listPriceDimension.get(0).Id;
        childPM2.Apttus_Config2__Dimension1ValueType__c = 'Discrete';
        priceMatrixes.add(childPM2);

        Apttus_Config2__PriceMatrix__c parentPM1 = new Apttus_Config2__PriceMatrix__c();
        parentPM1.Apttus_Config2__Sequence__c = 1;
        parentPM1.Apttus_Config2__PriceListItemId__c = parentPLI1.Id;
        parentPM1.Apttus_Config2__Dimension1Id__c = listPriceDimension.get(0).Id;
        parentPM1.Apttus_Config2__Dimension1ValueType__c = 'Discrete';
        priceMatrixes.add(parentPM1);

        Apttus_Config2__PriceMatrix__c parentPM2 = new Apttus_Config2__PriceMatrix__c();
        parentPM2.Apttus_Config2__Sequence__c = 1;
        parentPM2.Apttus_Config2__PriceListItemId__c = parentPLI2.Id;
        parentPM2.Apttus_Config2__Dimension1Id__c = listPriceDimension.get(0).Id;
        parentPM2.Apttus_Config2__Dimension1ValueType__c = 'Discrete';
        priceMatrixes.add(parentPM2);

        Apttus_Config2__PriceMatrix__c grandParentPM1 = new Apttus_Config2__PriceMatrix__c();
        grandParentPM1.Apttus_Config2__Sequence__c = 1;
        grandParentPM1.Apttus_Config2__PriceListItemId__c = grandParentPLI1.Id;
        grandParentPM1.Apttus_Config2__Dimension1Id__c = listPriceDimension.get(0).Id;
        grandParentPM1.Apttus_Config2__Dimension1ValueType__c = 'Discrete';
        priceMatrixes.add(grandParentPM1);

        Apttus_Config2__PriceMatrix__c grandParentPM2 = new Apttus_Config2__PriceMatrix__c();
        grandParentPM2.Apttus_Config2__Sequence__c = 1;
        grandParentPM2.Apttus_Config2__PriceListItemId__c = grandParentPLI2.Id;
        grandParentPM2.Apttus_Config2__Dimension1Id__c = listPriceDimension.get(0).Id;
        grandParentPM2.Apttus_Config2__Dimension1ValueType__c = 'Discrete';
        priceMatrixes.add(grandParentPM2);

        insert priceMatrixes;
        System.debug('APTS_TGBatchTest: Pricematrix inserted.');

        // Entries for the Price Matrix
        List<Apttus_Config2__PriceMatrixEntry__c> listPME = new List<Apttus_Config2__PriceMatrixEntry__c>();

        // Child
        Apttus_Config2__PriceMatrixEntry__c child12MonthsPM1 = new Apttus_Config2__PriceMatrixEntry__c();
        child12MonthsPM1.Apttus_Config2__Dimension1Value__c = '12 Months';
        child12MonthsPM1.Apttus_Config2__PriceMatrixId__c = childPM1.Id;
        child12MonthsPM1.Apttus_Config2__Sequence__c = 1;
        child12MonthsPM1.Apttus_Config2__UsageRate__c = 1;
        child12MonthsPM1.Apttus_Config2__AdjustmentAmount__c = 1;
        child12MonthsPM1.Apttus_Config2__PriceOverride__c = 1;
        listPME.add(child12MonthsPM1);

        Apttus_Config2__PriceMatrixEntry__c child6MonthsPM1 = new Apttus_Config2__PriceMatrixEntry__c();
        child6MonthsPM1.Apttus_Config2__Dimension1Value__c = '6 Months';
        child6MonthsPM1.Apttus_Config2__PriceMatrixId__c = childPM1.Id;
        child6MonthsPM1.Apttus_Config2__Sequence__c = 1;
        child6MonthsPM1.Apttus_Config2__UsageRate__c = 1;
        child6MonthsPM1.Apttus_Config2__AdjustmentAmount__c = 1;
        child6MonthsPM1.Apttus_Config2__PriceOverride__c = 1;
        listPME.add(child6MonthsPM1);

        Apttus_Config2__PriceMatrixEntry__c child12MonthsPM2 = new Apttus_Config2__PriceMatrixEntry__c();
        child12MonthsPM2.Apttus_Config2__Dimension1Value__c = '12 Months';
        child12MonthsPM2.Apttus_Config2__PriceMatrixId__c = childPM2.Id;
        child12MonthsPM2.Apttus_Config2__Sequence__c = 1;
        child12MonthsPM2.Apttus_Config2__UsageRate__c = 1;
        child12MonthsPM2.Apttus_Config2__AdjustmentAmount__c = 1;
        child12MonthsPM2.Apttus_Config2__PriceOverride__c = 1;
        listPME.add(child12MonthsPM2);

        Apttus_Config2__PriceMatrixEntry__c child6MonthsPM2 = new Apttus_Config2__PriceMatrixEntry__c();
        child6MonthsPM2.Apttus_Config2__Dimension1Value__c = '6 Months';
        child6MonthsPM2.Apttus_Config2__PriceMatrixId__c = childPM2.Id;
        child6MonthsPM2.Apttus_Config2__Sequence__c = 1;
        child6MonthsPM2.Apttus_Config2__UsageRate__c = 1;
        child6MonthsPM2.Apttus_Config2__AdjustmentAmount__c = 1;
        child6MonthsPM2.Apttus_Config2__PriceOverride__c = 1;
        listPME.add(child6MonthsPM2);

        // Parent
        Apttus_Config2__PriceMatrixEntry__c parent12MonthsPM1 = new Apttus_Config2__PriceMatrixEntry__c();
        parent12MonthsPM1.Apttus_Config2__Dimension1Value__c = '12 Months';
        parent12MonthsPM1.Apttus_Config2__PriceMatrixId__c = parentPM1.Id;
        parent12MonthsPM1.Apttus_Config2__Sequence__c = 1;
        parent12MonthsPM1.Apttus_Config2__UsageRate__c = 1;
        parent12MonthsPM1.Apttus_Config2__AdjustmentAmount__c = 1;
        parent12MonthsPM1.Apttus_Config2__PriceOverride__c = 1;
        listPME.add(parent12MonthsPM1);

        Apttus_Config2__PriceMatrixEntry__c parent6MonthsPM1 = new Apttus_Config2__PriceMatrixEntry__c();
        parent6MonthsPM1.Apttus_Config2__Dimension1Value__c = '6 Months';
        parent6MonthsPM1.Apttus_Config2__PriceMatrixId__c = parentPM1.Id;
        parent6MonthsPM1.Apttus_Config2__Sequence__c = 1;
        parent6MonthsPM1.Apttus_Config2__UsageRate__c = 1;
        parent6MonthsPM1.Apttus_Config2__AdjustmentAmount__c = 1;
        parent6MonthsPM1.Apttus_Config2__PriceOverride__c = 1;
        listPME.add(parent6MonthsPM1);

        Apttus_Config2__PriceMatrixEntry__c parent12MonthsPM2 = new Apttus_Config2__PriceMatrixEntry__c();
        parent12MonthsPM2.Apttus_Config2__Dimension1Value__c = '12 Months';
        parent12MonthsPM2.Apttus_Config2__PriceMatrixId__c = parentPM2.Id;
        parent12MonthsPM2.Apttus_Config2__Sequence__c = 1;
        parent12MonthsPM2.Apttus_Config2__UsageRate__c = 1;
        parent12MonthsPM2.Apttus_Config2__AdjustmentAmount__c = 1;
        parent12MonthsPM2.Apttus_Config2__PriceOverride__c = 1;
        listPME.add(parent12MonthsPM2);

        Apttus_Config2__PriceMatrixEntry__c parent6MonthsPM2 = new Apttus_Config2__PriceMatrixEntry__c();
        parent6MonthsPM2.Apttus_Config2__Dimension1Value__c = '6 Months';
        parent6MonthsPM2.Apttus_Config2__PriceMatrixId__c = parentPM2.Id;
        parent6MonthsPM2.Apttus_Config2__Sequence__c = 1;
        parent6MonthsPM2.Apttus_Config2__UsageRate__c = 1;
        parent6MonthsPM2.Apttus_Config2__AdjustmentAmount__c = 1;
        parent6MonthsPM2.Apttus_Config2__PriceOverride__c = 1;
        listPME.add(parent6MonthsPM2);

        // GrandParent
        Apttus_Config2__PriceMatrixEntry__c grandParent12MonthsPM1 = new Apttus_Config2__PriceMatrixEntry__c();
        grandParent12MonthsPM1.Apttus_Config2__Dimension1Value__c = '12 Months';
        grandParent12MonthsPM1.Apttus_Config2__PriceMatrixId__c = grandParentPM1.Id;
        grandParent12MonthsPM1.Apttus_Config2__Sequence__c = 1;
        grandParent12MonthsPM1.Apttus_Config2__UsageRate__c = 1;
        grandParent12MonthsPM1.Apttus_Config2__AdjustmentAmount__c = 1;
        grandParent12MonthsPM1.Apttus_Config2__PriceOverride__c = 1;
        listPME.add(grandParent12MonthsPM1);

        Apttus_Config2__PriceMatrixEntry__c grandParent6MonthsPM1 = new Apttus_Config2__PriceMatrixEntry__c();
        grandParent6MonthsPM1.Apttus_Config2__Dimension1Value__c = '6 Months';
        grandParent6MonthsPM1.Apttus_Config2__PriceMatrixId__c = grandParentPM1.Id;
        grandParent6MonthsPM1.Apttus_Config2__Sequence__c = 1;
        grandParent6MonthsPM1.Apttus_Config2__UsageRate__c = 1;
        grandParent6MonthsPM1.Apttus_Config2__AdjustmentAmount__c = 1;
        grandParent6MonthsPM1.Apttus_Config2__PriceOverride__c = 1;
        listPME.add(grandParent6MonthsPM1);

        Apttus_Config2__PriceMatrixEntry__c grandParent12MonthsPM2 = new Apttus_Config2__PriceMatrixEntry__c();
        grandParent12MonthsPM2.Apttus_Config2__Dimension1Value__c = '12 Months';
        grandParent12MonthsPM2.Apttus_Config2__PriceMatrixId__c = grandParentPM2.Id;
        grandParent12MonthsPM2.Apttus_Config2__Sequence__c = 1;
        grandParent12MonthsPM2.Apttus_Config2__UsageRate__c = 1;
        grandParent12MonthsPM2.Apttus_Config2__AdjustmentAmount__c = 1;
        grandParent12MonthsPM2.Apttus_Config2__PriceOverride__c = 1;
        listPME.add(grandParent12MonthsPM2);

        Apttus_Config2__PriceMatrixEntry__c grandParent6MonthsPM2 = new Apttus_Config2__PriceMatrixEntry__c();
        grandParent6MonthsPM2.Apttus_Config2__PriceMatrixId__c = grandParentPM2.Id;
        grandParent6MonthsPM2.Apttus_Config2__Dimension1Value__c = '6 Months';
        grandParent6MonthsPM2.Apttus_Config2__Sequence__c = 1;
        grandParent6MonthsPM2.Apttus_Config2__UsageRate__c = 1;
        grandParent6MonthsPM2.Apttus_Config2__AdjustmentAmount__c = 1;
        grandParent6MonthsPM2.Apttus_Config2__PriceOverride__c = 1;
        listPME.add(grandParent6MonthsPM2);

        insert listPME;
        System.debug('APTS_TGBatchTest: Price structure created.');

        // Creation of the quote
        List<Apttus_Proposal__Proposal__c> quotes = new List<Apttus_Proposal__Proposal__c>();

        Apttus_Proposal__Proposal__c childQuote = new Apttus_Proposal__Proposal__c();
        childQuote.Apttus_Proposal__Proposal_Name__c = 'Child Proposal';
        childQuote.Apttus_Proposal__Opportunity__c = childOpportunity.Id;
        childQuote.Apttus_Proposal__Account__c = childAccount.Id;
        childQuote.Apttus_QPConfig__PriceListId__c = priceList.Id;
        quotes.add(childQuote);

        Apttus_Proposal__Proposal__c parentQuote = new Apttus_Proposal__Proposal__c();
        parentQuote.Apttus_Proposal__Proposal_Name__c = 'Parent Proposal';
        parentQuote.Apttus_Proposal__Opportunity__c = parentOpportunity.Id;
        parentQuote.Apttus_Proposal__Account__c = parentAccount.Id;
        parentQuote.Apttus_QPConfig__PriceListId__c = priceList.Id;
        quotes.add(parentQuote);

        Apttus_Proposal__Proposal__c grandParentQuote = new Apttus_Proposal__Proposal__c();
        grandParentQuote.Apttus_Proposal__Proposal_Name__c = 'GrandParent Proposal';
        grandParentQuote.Apttus_Proposal__Opportunity__c = grandParentOpportunity.id;
        grandParentQuote.Apttus_Proposal__Account__c = grandParentAccount.Id;
        grandParentQuote.Apttus_QPConfig__PriceListId__c = priceList.Id;
        quotes.add(grandParentQuote);

        insert quotes;

        System.debug('APTS_TGBatchTest: Quotes created.');

        // Creation of the agreements
        List<Apttus__APTS_Agreement__c> agreements = new List<Apttus__APTS_Agreement__c>();

        Apttus__APTS_Agreement__c childAgreement = new Apttus__APTS_Agreement__c();
        childAgreement.recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
        childAgreement.Name = 'Agreement';
        childAgreement.Apttus__Primary_Contact__c = primaryContact.Id;
        childAgreement.Apttus__Agreement_Category__c = 'Standard';
        childAgreement.Apttus_CMConfig__PriceListId__c = priceList.Id;
        childAgreement.Apttus_CMConfig__PricingDate__c = System.Today();
        childAgreement.Apttus__Account__c = childaccount.Id;
        childAgreement.APTS_Order_Non_Contracted_Products__c = true;
        agreements.add(childAgreement);

        Apttus__APTS_Agreement__c parentAgreement = new Apttus__APTS_Agreement__c();
        parentAgreement.recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
        parentAgreement.Name = 'Agreement';
        parentAgreement.Apttus__Primary_Contact__c = primaryContact.Id;
        parentAgreement.Apttus__Agreement_Category__c = 'Standard';
        parentAgreement.Apttus_CMConfig__PriceListId__c = priceList.Id;
        parentAgreement.Apttus_CMConfig__PricingDate__c = System.Today();
        parentAgreement.Apttus__Account__c = parentAccount.Id;
        parentAgreement.APTS_Order_Non_Contracted_Products__c = true;
        agreements.add(parentAgreement);

        Apttus__APTS_Agreement__c grandParentAgreement = new Apttus__APTS_Agreement__c();
        grandParentAgreement.recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
        grandParentAgreement.Name = 'Agreement';
        grandParentAgreement.Apttus__Primary_Contact__c = primaryContact.Id;
        grandParentAgreement.Apttus__Agreement_Category__c = 'Standard';
        grandParentAgreement.Apttus_CMConfig__PriceListId__c = priceList.Id;
        grandParentAgreement.Apttus_CMConfig__PricingDate__c = System.Today();
        grandParentAgreement.Apttus__Account__c = grandParentAccount.Id;
        grandParentAgreement.APTS_Order_Non_Contracted_Products__c = true;
        agreements.add(grandParentAgreement);

        Apttus__APTS_Agreement__c contractedProductsAgreementNonLooped = new Apttus__APTS_Agreement__c();
        contractedProductsAgreementNonLooped.recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
        contractedProductsAgreementNonLooped.Name = 'Agreement';
        contractedProductsAgreementNonLooped.Apttus__Primary_Contact__c = primaryContact.Id;
        contractedProductsAgreementNonLooped.Apttus__Agreement_Category__c = 'Standard';
        contractedProductsAgreementNonLooped.Apttus_CMConfig__PriceListId__c = priceList.Id;
        contractedProductsAgreementNonLooped.Apttus_CMConfig__PricingDate__c = System.Today();
        contractedProductsAgreementNonLooped.Apttus__Account__c = contractedProductsAccountNonLooped.Id;
        contractedProductsAgreementNonLooped.APTS_Order_Non_Contracted_Products__c = true;
        agreements.add(contractedProductsAgreementNonLooped);

        Apttus__APTS_Agreement__c contractedProductsAgreementLooped = new Apttus__APTS_Agreement__c();
        contractedProductsAgreementLooped.recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
        contractedProductsAgreementLooped.Name = 'Agreement';
        contractedProductsAgreementLooped.Apttus__Primary_Contact__c = primaryContact.Id;
        contractedProductsAgreementLooped.Apttus__Agreement_Category__c = 'Standard';
        contractedProductsAgreementLooped.Apttus_CMConfig__PriceListId__c = priceList.Id;
        contractedProductsAgreementLooped.Apttus_CMConfig__PricingDate__c = System.Today();
        contractedProductsAgreementLooped.Apttus__Account__c = contractedProductsAccountLooped.Id;
        contractedProductsAgreementLooped.APTS_Order_Non_Contracted_Products__c = true;
        agreements.add(contractedProductsAgreementLooped);

        Apttus__APTS_Agreement__c nonContractedProductsAgreementLooped = new Apttus__APTS_Agreement__c();
        nonContractedProductsAgreementLooped.recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
        nonContractedProductsAgreementLooped.Name = 'Agreement';
        nonContractedProductsAgreementLooped.Apttus__Primary_Contact__c = primaryContact.Id;
        nonContractedProductsAgreementLooped.Apttus__Agreement_Category__c = 'Standard';
        nonContractedProductsAgreementLooped.Apttus_CMConfig__PriceListId__c = priceList.Id;
        nonContractedProductsAgreementLooped.Apttus_CMConfig__PricingDate__c = System.Today();
        nonContractedProductsAgreementLooped.Apttus__Account__c = nonContractedProductsAccountLooped.Id;
        nonContractedProductsAgreementLooped.APTS_Order_Non_Contracted_Products__c = false;
        agreements.add(nonContractedProductsAgreementLooped);

        Apttus__APTS_Agreement__c nonContractedProductsAgreementNonLooped = new Apttus__APTS_Agreement__c();
        nonContractedProductsAgreementNonLooped.recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
        nonContractedProductsAgreementNonLooped.Name = 'Agreement';
        nonContractedProductsAgreementNonLooped.Apttus__Primary_Contact__c = primaryContact.Id;
        nonContractedProductsAgreementNonLooped.Apttus__Agreement_Category__c = 'Standard';
        nonContractedProductsAgreementNonLooped.Apttus_CMConfig__PriceListId__c = priceList.Id;
        nonContractedProductsAgreementNonLooped.Apttus_CMConfig__PricingDate__c = System.Today();
        nonContractedProductsAgreementNonLooped.Apttus__Account__c = nonContractedProductsAccountNonLooped.Id;
        nonContractedProductsAgreementNonLooped.APTS_Order_Non_Contracted_Products__c = false;
        agreements.add(nonContractedProductsAgreementNonLooped);

        insert agreements;

        System.debug('APTS_TGBatchTest: Agreements created.');

        // Product Configuration
        List<Apttus_Config2__ProductConfiguration__c> prodConfigurations = new List<Apttus_Config2__ProductConfiguration__c>();
        Apttus_Config2__ProductConfiguration__c childConfiguration = new Apttus_Config2__ProductConfiguration__c();
        childConfiguration.Name='Sample';
        childConfiguration.Apttus_CMConfig__AgreementId__c=childAgreement.Id;
        childConfiguration.Apttus_QPConfig__Proposald__c=childQuote.Id;
        childConfiguration.Apttus_Config2__PriceListId__c=pricelist.Id;
        prodConfigurations.add(childConfiguration);

        Apttus_Config2__ProductConfiguration__c parentConfiguration = new Apttus_Config2__ProductConfiguration__c();
        parentConfiguration.Name='Sample';
        parentConfiguration.Apttus_CMConfig__AgreementId__c=parentAgreement.Id;
        parentConfiguration.Apttus_QPConfig__Proposald__c=parentQuote.Id;
        parentConfiguration.Apttus_Config2__PriceListId__c=pricelist.Id;
		prodConfigurations.add(parentConfiguration);

        Apttus_Config2__ProductConfiguration__c grandParentConfiguration = new Apttus_Config2__ProductConfiguration__c();
        grandParentConfiguration.Name='Sample';
        grandParentConfiguration.Apttus_CMConfig__AgreementId__c= grandParentAgreement.Id;
        grandParentConfiguration.Apttus_QPConfig__Proposald__c=grandParentQuote.Id;
        grandParentConfiguration.Apttus_Config2__PriceListId__c=pricelist.Id;
        prodConfigurations.add(grandParentConfiguration);

        Apttus_Config2__ProductConfiguration__c nonContractedLoopedConfiguration = new Apttus_Config2__ProductConfiguration__c();
        nonContractedLoopedConfiguration.Name = 'Sample';
        nonContractedLoopedConfiguration.Apttus_CMConfig__AgreementId__c = nonContractedProductsAgreementLooped.Id;
        nonContractedLoopedConfiguration.Apttus_QPConfig__Proposald__c = childQuote.Id;
        nonContractedLoopedConfiguration.Apttus_Config2__PriceListId__c = pricelist.Id;
        prodConfigurations.add(nonContractedLoopedConfiguration);

        Apttus_Config2__ProductConfiguration__c nonContractedNonLoopedConfiguration = new Apttus_Config2__ProductConfiguration__c();
        nonContractedNonLoopedConfiguration.Name = 'Sample';
        nonContractedNonLoopedConfiguration.Apttus_CMConfig__AgreementId__c = nonContractedProductsAgreementNonLooped.Id;
        nonContractedNonLoopedConfiguration.Apttus_QPConfig__Proposald__c = childQuote.Id;
        nonContractedNonLoopedConfiguration.Apttus_Config2__PriceListId__c = pricelist.Id;
        prodConfigurations.add(nonContractedNonLoopedConfiguration);

        Apttus_Config2__ProductConfiguration__c contractedLoopedConfiguration = new Apttus_Config2__ProductConfiguration__c();
        contractedLoopedConfiguration.Name = 'Sample';
        contractedLoopedConfiguration.Apttus_CMConfig__AgreementId__c = contractedProductsAgreementLooped.Id;
        contractedLoopedConfiguration.Apttus_QPConfig__Proposald__c = childQuote.Id;
        contractedLoopedConfiguration.Apttus_Config2__PriceListId__c = pricelist.Id;
        prodConfigurations.add(contractedLoopedConfiguration);

        Apttus_Config2__ProductConfiguration__c contractedNonLoopedConfiguration = new Apttus_Config2__ProductConfiguration__c();
        contractedNonLoopedConfiguration.Name = 'Sample';
        contractedNonLoopedConfiguration.Apttus_CMConfig__AgreementId__c = contractedProductsAgreementNonLooped.Id;
        contractedNonLoopedConfiguration.Apttus_QPConfig__Proposald__c = childQuote.Id;
        contractedNonLoopedConfiguration.Apttus_Config2__PriceListId__c = pricelist.Id;
        prodConfigurations.add(contractedNonLoopedConfiguration);

        insert prodConfigurations;
        System.debug('APTS_TGBatchTest: Product Configurations created.');

        // Line Item for Child items
        List<Apttus_Config2__LineItem__c> lineItems = new List<Apttus_Config2__LineItem__c>();
        Apttus_Config2__LineItem__c childLineItem1 = new Apttus_Config2__LineItem__c();
        childLineItem1.Apttus_Config2__ConfigurationId__c = childConfiguration.Id;
        childLineItem1.Apttus_Config2__LineNumber__c = 1;
        childLineItem1.Apttus_Config2__IsPrimaryLine__c = true;
        childLineItem1.Apttus_Config2__PrimaryLineNumber__c = 1;
        childLineItem1.Apttus_Config2__ItemSequence__c = 2;
        childLineItem1.Apttus_Config2__SummaryGroupId__c = null;
        childLineItem1.Apttus_Config2__LineType__c = '';
        childLineItem1.Apttus_Config2__ProductId__c = childProduct1.Id;
        childLineItem1.Apttus_Config2__Customizable__c = false;
        childLineItem1.Apttus_Config2__ProductOptionId__c = null;
        childLineItem1.Apttus_Config2__OptionId__c = childProduct1.Id;
        childLineItem1.Apttus_Config2__ClassificationId__c = null;
        childLineItem1.Apttus_Config2__ClassificationHierarchy__c = '';
        childLineItem1.Apttus_Config2__Quantity__c = 2.3;
        childLineItem1.Apttus_Config2__IsQuantityModifiable__c = false;
        childLineItem1.Apttus_Config2__Uom__c = '';
        childLineItem1.Apttus_Config2__Term__c = 1;
        childLineItem1.Apttus_Config2__PriceListId__c = pricelist.Id;
        childLineItem1.Apttus_Config2__PriceListItemId__c = childPLI1.Id;
        childLineItem1.Apttus_Config2__PriceType__c = '';
        childLineItem1.Apttus_Config2__PriceMethod__c = '';
        childLineItem1.Apttus_Config2__ChargeType__c = 'Sales Price';
        childLineItem1.Apttus_Config2__Frequency__c = '';
        childLineItem1.Apttus_Config2__AllowManualAdjustment__c = false;
        childLineItem1.Apttus_Config2__AllocateGroupAdjustment__c = false;
        childLineItem1.Apttus_Config2__ListPrice__c = 22.00;
        childLineItem1.Apttus_Config2__NetPrice__c = 10.00;
        childLineItem1.Apttus_Config2__BasePrice__c = 24.00;
        childLineItem1.Apttus_Config2__BasePriceMethod__c = '';
        childLineItem1.Apttus_Config2__BaseExtendedPrice__c = 34.00;
        childLineItem1.Apttus_Config2__OptionPrice__c = 23.00;
        childLineItem1.Apttus_Config2__ExtendedPrice__c = 33.50;
        childLineItem1.Apttus_Config2__Description__c = '';
        childLineItem1.Apttus_Config2__AdjustedPrice__c = 0;
        childLineitem1.Apttus_Config2__PriceUom__c = childProduct1.Apttus_Config2__Uom__c;
        lineItems.add(childLineItem1);

        Apttus_Config2__LineItem__c childLineItem2 = new Apttus_Config2__LineItem__c();
        childLineItem2.Apttus_Config2__ConfigurationId__c = childConfiguration.Id;
        childLineItem2.Apttus_Config2__LineNumber__c = 1;
        childLineItem2.Apttus_Config2__IsPrimaryLine__c = true;
        childLineItem2.Apttus_Config2__PrimaryLineNumber__c = 1;
        childLineItem2.Apttus_Config2__ItemSequence__c = 2;
        childLineItem2.Apttus_Config2__SummaryGroupId__c = null;
        childLineItem2.Apttus_Config2__LineType__c = '';
        childLineItem2.Apttus_Config2__ProductId__c = childProduct2.Id;
        childLineItem2.Apttus_Config2__Customizable__c = false;
        childLineItem2.Apttus_Config2__ProductOptionId__c = null;
        childLineItem2.Apttus_Config2__OptionId__c = childProduct2.Id;
        childLineItem2.Apttus_Config2__ClassificationId__c = null;
        childLineItem2.Apttus_Config2__ClassificationHierarchy__c = '';
        childLineItem2.Apttus_Config2__Quantity__c = 2.3;
        childLineItem2.Apttus_Config2__IsQuantityModifiable__c = false;
        childLineItem2.Apttus_Config2__Uom__c = '';
        childLineItem2.Apttus_Config2__Term__c = 1;
        childLineItem2.Apttus_Config2__PriceListId__c = pricelist.Id;
        childLineItem2.Apttus_Config2__PriceListItemId__c = childPLI2.Id;
        childLineItem2.Apttus_Config2__PriceType__c = '';
        childLineItem2.Apttus_Config2__PriceMethod__c = '';
        childLineItem2.Apttus_Config2__ChargeType__c = 'Sales Price';
        childLineItem2.Apttus_Config2__Frequency__c = '';
        childLineItem2.Apttus_Config2__AllowManualAdjustment__c = false;
        childLineItem2.Apttus_Config2__AllocateGroupAdjustment__c = false;
        childLineItem2.Apttus_Config2__ListPrice__c = 22.00;
        childLineItem2.Apttus_Config2__NetPrice__c = 20.00;
        childLineItem2.Apttus_Config2__BasePrice__c = 24.00;
        childLineItem2.Apttus_Config2__BasePriceMethod__c = '';
        childLineItem2.Apttus_Config2__BaseExtendedPrice__c = 34.00;
        childLineItem2.Apttus_Config2__OptionPrice__c = 23.00;
        childLineItem2.Apttus_Config2__ExtendedPrice__c = 33.50;
        childLineItem2.Apttus_Config2__Description__c = '';
        childLineItem2.Apttus_Config2__AdjustedPrice__c = 0;
        childLineitem2.Apttus_Config2__PriceUom__c = childProduct2.Apttus_Config2__Uom__c;
        lineItems.add(childLineItem2);

        // Line Item for Parent items
        Apttus_Config2__LineItem__c parentLineItem1 = new Apttus_Config2__LineItem__c();
        parentLineItem1.Apttus_Config2__ConfigurationId__c = parentConfiguration.Id;
        parentLineItem1.Apttus_Config2__LineNumber__c = 1;
        parentLineItem1.Apttus_Config2__IsPrimaryLine__c = true;
        parentLineItem1.Apttus_Config2__PrimaryLineNumber__c = 1;
        parentLineItem1.Apttus_Config2__ItemSequence__c = 2;
        parentLineItem1.Apttus_Config2__SummaryGroupId__c = null;
        parentLineItem1.Apttus_Config2__LineType__c = '';
        parentLineItem1.Apttus_Config2__ProductId__c = parentProduct1.Id;
        parentLineItem1.Apttus_Config2__Customizable__c = false;
        parentLineItem1.Apttus_Config2__ProductOptionId__c = null;
        parentLineItem1.Apttus_Config2__OptionId__c = parentProduct1.Id;
        parentLineItem1.Apttus_Config2__ClassificationId__c = null;
        parentLineItem1.Apttus_Config2__ClassificationHierarchy__c = '';
        parentLineItem1.Apttus_Config2__Quantity__c = 2.3;
        parentLineItem1.Apttus_Config2__IsQuantityModifiable__c = false;
        parentLineItem1.Apttus_Config2__Uom__c = '';
        parentLineItem1.Apttus_Config2__Term__c = 1;
        parentLineItem1.Apttus_Config2__PriceListId__c = pricelist.Id;
        parentLineItem1.Apttus_Config2__PriceListItemId__c = parentPLI1.Id;
        parentLineItem1.Apttus_Config2__PriceType__c = '';
        parentLineItem1.Apttus_Config2__PriceMethod__c = '';
        parentLineItem1.Apttus_Config2__ChargeType__c = 'Sales Price';
        parentLineItem1.Apttus_Config2__Frequency__c = '';
        parentLineItem1.Apttus_Config2__AllowManualAdjustment__c = false;
        parentLineItem1.Apttus_Config2__AllocateGroupAdjustment__c = false;
        parentLineItem1.Apttus_Config2__ListPrice__c = 22.00;
        parentLineItem1.Apttus_Config2__NetPrice__c = 30.00;
        parentLineItem1.Apttus_Config2__BasePrice__c = 24.00;
        parentLineItem1.Apttus_Config2__BasePriceMethod__c = '';
        parentLineItem1.Apttus_Config2__BaseExtendedPrice__c = 34.00;
        parentLineItem1.Apttus_Config2__OptionPrice__c = 23.00;
        parentLineItem1.Apttus_Config2__ExtendedPrice__c = 33.50;
        parentLineItem1.Apttus_Config2__Description__c = '';
        parentLineItem1.Apttus_Config2__AdjustedPrice__c = 0;
        parentLineitem1.Apttus_Config2__PriceUom__c = parentProduct1.Apttus_Config2__Uom__c;
        lineitems.add(parentLineItem1);

        Apttus_Config2__LineItem__c parentLineItem2 = new Apttus_Config2__LineItem__c();
        parentLineItem2.Apttus_Config2__ConfigurationId__c = parentConfiguration.Id;
        parentLineItem2.Apttus_Config2__LineNumber__c = 1;
        parentLineItem2.Apttus_Config2__IsPrimaryLine__c = true;
        parentLineItem2.Apttus_Config2__PrimaryLineNumber__c = 1;
        parentLineItem2.Apttus_Config2__ItemSequence__c = 2;
        parentLineItem2.Apttus_Config2__SummaryGroupId__c = null;
        parentLineItem2.Apttus_Config2__LineType__c = '';
        parentLineItem2.Apttus_Config2__ProductId__c = parentProduct2.Id;
        parentLineItem2.Apttus_Config2__Customizable__c = false;
        parentLineItem2.Apttus_Config2__ProductOptionId__c = null;
        parentLineItem2.Apttus_Config2__OptionId__c = parentProduct2.Id;
        parentLineItem2.Apttus_Config2__ClassificationId__c = null;
        parentLineItem2.Apttus_Config2__ClassificationHierarchy__c = '';
        parentLineItem2.Apttus_Config2__Quantity__c = 2.3;
        parentLineItem2.Apttus_Config2__IsQuantityModifiable__c = false;
        parentLineItem2.Apttus_Config2__Uom__c = '';
        parentLineItem2.Apttus_Config2__Term__c = 1;
        parentLineItem2.Apttus_Config2__PriceListId__c = pricelist.Id;
        parentLineItem2.Apttus_Config2__PriceListItemId__c = parentPLI2.Id;
        parentLineItem2.Apttus_Config2__PriceType__c = '';
        parentLineItem2.Apttus_Config2__PriceMethod__c = '';
        parentLineItem2.Apttus_Config2__ChargeType__c = 'Sales Price';
        parentLineItem2.Apttus_Config2__Frequency__c = '';
        parentLineItem2.Apttus_Config2__AllowManualAdjustment__c = false;
        parentLineItem2.Apttus_Config2__AllocateGroupAdjustment__c = false;
        parentLineItem2.Apttus_Config2__ListPrice__c = 22.00;
        parentLineItem2.Apttus_Config2__NetPrice__c = 40.00;
        parentLineItem2.Apttus_Config2__BasePrice__c = 24.00;
        parentLineItem2.Apttus_Config2__BasePriceMethod__c = '';
        parentLineItem2.Apttus_Config2__BaseExtendedPrice__c = 34.00;
        parentLineItem2.Apttus_Config2__OptionPrice__c = 23.00;
        parentLineItem2.Apttus_Config2__ExtendedPrice__c = 33.50;
        parentLineItem2.Apttus_Config2__Description__c = '';
        parentLineItem2.Apttus_Config2__AdjustedPrice__c = 0;
        parentLineitem2.Apttus_Config2__PriceUom__c = parentProduct2.Apttus_Config2__Uom__c;
        lineitems.add(parentLineItem2);

        // Line Item for Grand Parent items
        Apttus_Config2__LineItem__c grandParentLineItem1 = new Apttus_Config2__LineItem__c();
        grandParentLineItem1.Apttus_Config2__ConfigurationId__c = grandParentConfiguration.Id;
        grandParentLineItem1.Apttus_Config2__LineNumber__c = 1;
        grandParentLineItem1.Apttus_Config2__IsPrimaryLine__c = true;
        grandParentLineItem1.Apttus_Config2__PrimaryLineNumber__c = 1;
        grandParentLineItem1.Apttus_Config2__ItemSequence__c = 2;
        grandParentLineItem1.Apttus_Config2__SummaryGroupId__c = null;
        grandParentLineItem1.Apttus_Config2__LineType__c = '';
        grandParentLineItem1.Apttus_Config2__ProductId__c = grandParentProduct1.Id;
        grandParentLineItem1.Apttus_Config2__Customizable__c = false;
        grandParentLineItem1.Apttus_Config2__ProductOptionId__c = null;
        grandParentLineItem1.Apttus_Config2__OptionId__c = grandParentProduct1.Id;
        grandParentLineItem1.Apttus_Config2__ClassificationId__c = null;
        grandParentLineItem1.Apttus_Config2__ClassificationHierarchy__c = '';
        grandParentLineItem1.Apttus_Config2__Quantity__c = 2.3;
        grandParentLineItem1.Apttus_Config2__IsQuantityModifiable__c = false;
        grandParentLineItem1.Apttus_Config2__Uom__c = '';
        grandParentLineItem1.Apttus_Config2__Term__c = 1;
        grandParentLineItem1.Apttus_Config2__PriceListId__c = pricelist.Id;
        grandParentLineItem1.Apttus_Config2__PriceListItemId__c = grandParentPLI1.Id;
        grandParentLineItem1.Apttus_Config2__PriceType__c = '';
        grandParentLineItem1.Apttus_Config2__PriceMethod__c = '';
        grandParentLineItem1.Apttus_Config2__ChargeType__c = 'Sales Price';
        grandParentLineItem1.Apttus_Config2__Frequency__c = '';
        grandParentLineItem1.Apttus_Config2__AllowManualAdjustment__c = false;
        grandParentLineItem1.Apttus_Config2__AllocateGroupAdjustment__c = false;
        grandParentLineItem1.Apttus_Config2__ListPrice__c = 22.00;
        grandParentLineItem1.Apttus_Config2__NetPrice__c = 50.00;
        grandParentLineItem1.Apttus_Config2__BasePrice__c = 24.00;
        grandParentLineItem1.Apttus_Config2__BasePriceMethod__c = '';
        grandParentLineItem1.Apttus_Config2__BaseExtendedPrice__c = 34.00;
        grandParentLineItem1.Apttus_Config2__OptionPrice__c = 23.00;
        grandParentLineItem1.Apttus_Config2__ExtendedPrice__c = 33.50;
        grandParentLineItem1.Apttus_Config2__Description__c = '';
        grandParentLineItem1.Apttus_Config2__AdjustedPrice__c = 0;
        grandParentLineitem1.Apttus_Config2__PriceUom__c = grandParentProduct1.Apttus_Config2__Uom__c;
        lineitems.add(grandParentLineitem1);

        Apttus_Config2__LineItem__c grandParentLineItem2 = new Apttus_Config2__LineItem__c();
        grandParentLineItem2.Apttus_Config2__ConfigurationId__c = grandParentConfiguration.Id;
        grandParentLineItem2.Apttus_Config2__LineNumber__c = 1;
        grandParentLineItem2.Apttus_Config2__IsPrimaryLine__c = true;
        grandParentLineItem2.Apttus_Config2__PrimaryLineNumber__c = 1;
        grandParentLineItem2.Apttus_Config2__ItemSequence__c = 2;
        grandParentLineItem2.Apttus_Config2__SummaryGroupId__c = null;
        grandParentLineItem2.Apttus_Config2__LineType__c = '';
        grandParentLineItem2.Apttus_Config2__ProductId__c = grandParentProduct2.Id;
        grandParentLineItem2.Apttus_Config2__Customizable__c = false;
        grandParentLineItem2.Apttus_Config2__ProductOptionId__c = null;
        grandParentLineItem2.Apttus_Config2__OptionId__c = grandParentProduct2.Id;
        grandParentLineItem2.Apttus_Config2__ClassificationId__c = null;
        grandParentLineItem2.Apttus_Config2__ClassificationHierarchy__c = '';
        grandParentLineItem2.Apttus_Config2__Quantity__c = 2.3;
        grandParentLineItem2.Apttus_Config2__IsQuantityModifiable__c = false;
        grandParentLineItem2.Apttus_Config2__Uom__c = '';
        grandParentLineItem2.Apttus_Config2__Term__c = 1;
        grandParentLineItem2.Apttus_Config2__PriceListId__c = pricelist.Id;
        grandParentLineItem2.Apttus_Config2__PriceListItemId__c = grandParentPLI2.Id;
        grandParentLineItem2.Apttus_Config2__PriceType__c = '';
        grandParentLineItem2.Apttus_Config2__PriceMethod__c = '';
        grandParentLineItem2.Apttus_Config2__ChargeType__c = 'Sales Price';
        grandParentLineItem2.Apttus_Config2__Frequency__c = '';
        grandParentLineItem2.Apttus_Config2__AllowManualAdjustment__c = false;
        grandParentLineItem2.Apttus_Config2__AllocateGroupAdjustment__c = false;
        grandParentLineItem2.Apttus_Config2__ListPrice__c = 22.00;
        grandParentLineItem2.Apttus_Config2__NetPrice__c = 30.00;
        grandParentLineItem2.Apttus_Config2__BasePrice__c = 24.00;
        grandParentLineItem2.Apttus_Config2__BasePriceMethod__c = '';
        grandParentLineItem2.Apttus_Config2__BaseExtendedPrice__c = 34.00;
        grandParentLineItem2.Apttus_Config2__OptionPrice__c = 23.00;
        grandParentLineItem2.Apttus_Config2__ExtendedPrice__c = 33.50;
        grandParentLineItem2.Apttus_Config2__Description__c = '';
        grandParentLineItem2.Apttus_Config2__AdjustedPrice__c = 0;
        grandParentLineitem2.Apttus_Config2__PriceUom__c = grandParentProduct2.Apttus_Config2__Uom__c;
        lineitems.add(grandParentLineItem2);

        Apttus_Config2__LineItem__c nonContractedLoopedLineItem = new Apttus_Config2__LineItem__c();
        nonContractedLoopedLineItem.Apttus_Config2__ConfigurationId__c = nonContractedLoopedConfiguration.Id;
        nonContractedLoopedLineItem.Apttus_Config2__LineNumber__c = 1;
        nonContractedLoopedLineItem.Apttus_Config2__IsPrimaryLine__c = true;
        nonContractedLoopedLineItem.Apttus_Config2__PrimaryLineNumber__c = 1;
        nonContractedLoopedLineItem.Apttus_Config2__ItemSequence__c = 2;
        nonContractedLoopedLineItem.Apttus_Config2__SummaryGroupId__c = null;
        nonContractedLoopedLineItem.Apttus_Config2__LineType__c = '';
        nonContractedLoopedLineItem.Apttus_Config2__ProductId__c = childProduct1.Id;
        nonContractedLoopedLineItem.Apttus_Config2__Customizable__c = false;
        nonContractedLoopedLineItem.Apttus_Config2__ProductOptionId__c = null;
        nonContractedLoopedLineItem.Apttus_Config2__OptionId__c = childProduct1.Id;
        nonContractedLoopedLineItem.Apttus_Config2__ClassificationId__c = null;
        nonContractedLoopedLineItem.Apttus_Config2__ClassificationHierarchy__c = '';
        nonContractedLoopedLineItem.Apttus_Config2__Quantity__c = 2.3;
        nonContractedLoopedLineItem.Apttus_Config2__IsQuantityModifiable__c = false;
        nonContractedLoopedLineItem.Apttus_Config2__Uom__c = '';
        nonContractedLoopedLineItem.Apttus_Config2__Term__c = 1;
        nonContractedLoopedLineItem.Apttus_Config2__PriceListId__c = pricelist.Id;
        nonContractedLoopedLineItem.Apttus_Config2__PriceListItemId__c = childPLI1.Id;
        nonContractedLoopedLineItem.Apttus_Config2__PriceType__c = '';
        nonContractedLoopedLineItem.Apttus_Config2__PriceMethod__c = '';
        nonContractedLoopedLineItem.Apttus_Config2__ChargeType__c = 'Sales Price';
        nonContractedLoopedLineItem.Apttus_Config2__Frequency__c = '';
        nonContractedLoopedLineItem.Apttus_Config2__AllowManualAdjustment__c = false;
        nonContractedLoopedLineItem.Apttus_Config2__AllocateGroupAdjustment__c = false;
        nonContractedLoopedLineItem.Apttus_Config2__ListPrice__c = 22.00;
        nonContractedLoopedLineItem.Apttus_Config2__NetPrice__c = 30.00;
        nonContractedLoopedLineItem.Apttus_Config2__BasePrice__c = 24.00;
        nonContractedLoopedLineItem.Apttus_Config2__BasePriceMethod__c = '';
        nonContractedLoopedLineItem.Apttus_Config2__BaseExtendedPrice__c = 34.00;
        nonContractedLoopedLineItem.Apttus_Config2__OptionPrice__c = 23.00;
        nonContractedLoopedLineItem.Apttus_Config2__ExtendedPrice__c = 33.50;
        nonContractedLoopedLineItem.Apttus_Config2__Description__c = '';
        nonContractedLoopedLineItem.Apttus_Config2__AdjustedPrice__c = 0;
        nonContractedLoopedLineItem.Apttus_Config2__PriceUom__c = childProduct1.Apttus_Config2__Uom__c;
        lineitems.add(nonContractedLoopedLineItem);

        Apttus_Config2__LineItem__c nonContractedNonLoopedLineItem = new Apttus_Config2__LineItem__c();
        nonContractedNonLoopedLineItem.Apttus_Config2__ConfigurationId__c = nonContractedNonLoopedConfiguration.Id;
        nonContractedNonLoopedLineItem.Apttus_Config2__LineNumber__c = 1;
        nonContractedNonLoopedLineItem.Apttus_Config2__IsPrimaryLine__c = true;
        nonContractedNonLoopedLineItem.Apttus_Config2__PrimaryLineNumber__c = 1;
        nonContractedNonLoopedLineItem.Apttus_Config2__ItemSequence__c = 2;
        nonContractedNonLoopedLineItem.Apttus_Config2__SummaryGroupId__c = null;
        nonContractedNonLoopedLineItem.Apttus_Config2__LineType__c = '';
        nonContractedNonLoopedLineItem.Apttus_Config2__ProductId__c = childProduct1.Id;
        nonContractedNonLoopedLineItem.Apttus_Config2__Customizable__c = false;
        nonContractedNonLoopedLineItem.Apttus_Config2__ProductOptionId__c = null;
        nonContractedNonLoopedLineItem.Apttus_Config2__OptionId__c = childProduct1.Id;
        nonContractedNonLoopedLineItem.Apttus_Config2__ClassificationId__c = null;
        nonContractedNonLoopedLineItem.Apttus_Config2__ClassificationHierarchy__c = '';
        nonContractedNonLoopedLineItem.Apttus_Config2__Quantity__c = 2.3;
        nonContractedNonLoopedLineItem.Apttus_Config2__IsQuantityModifiable__c = false;
        nonContractedNonLoopedLineItem.Apttus_Config2__Uom__c = '';
        nonContractedNonLoopedLineItem.Apttus_Config2__Term__c = 1;
        nonContractedNonLoopedLineItem.Apttus_Config2__PriceListId__c = pricelist.Id;
        nonContractedNonLoopedLineItem.Apttus_Config2__PriceListItemId__c = childPLI1.Id;
        nonContractedNonLoopedLineItem.Apttus_Config2__PriceType__c = '';
        nonContractedNonLoopedLineItem.Apttus_Config2__PriceMethod__c = '';
        nonContractedNonLoopedLineItem.Apttus_Config2__ChargeType__c = 'Sales Price';
        nonContractedNonLoopedLineItem.Apttus_Config2__Frequency__c = '';
        nonContractedNonLoopedLineItem.Apttus_Config2__AllowManualAdjustment__c = false;
        nonContractedNonLoopedLineItem.Apttus_Config2__AllocateGroupAdjustment__c = false;
        nonContractedNonLoopedLineItem.Apttus_Config2__ListPrice__c = 22.00;
        nonContractedNonLoopedLineItem.Apttus_Config2__NetPrice__c = 30.00;
        nonContractedNonLoopedLineItem.Apttus_Config2__BasePrice__c = 24.00;
        nonContractedNonLoopedLineItem.Apttus_Config2__BasePriceMethod__c = '';
        nonContractedNonLoopedLineItem.Apttus_Config2__BaseExtendedPrice__c = 34.00;
        nonContractedNonLoopedLineItem.Apttus_Config2__OptionPrice__c = 23.00;
        nonContractedNonLoopedLineItem.Apttus_Config2__ExtendedPrice__c = 33.50;
        nonContractedNonLoopedLineItem.Apttus_Config2__Description__c = '';
        nonContractedNonLoopedLineItem.Apttus_Config2__AdjustedPrice__c = 0;
        nonContractedNonLoopedLineItem.Apttus_Config2__PriceUom__c = childProduct1.Apttus_Config2__Uom__c;
        lineitems.add(nonContractedNonLoopedLineItem);

        Apttus_Config2__LineItem__c contractedNonLoopedLineItem = new Apttus_Config2__LineItem__c();
        contractedNonLoopedLineItem.Apttus_Config2__ConfigurationId__c = contractedNonLoopedConfiguration.Id;
        contractedNonLoopedLineItem.Apttus_Config2__LineNumber__c = 1;
        contractedNonLoopedLineItem.Apttus_Config2__IsPrimaryLine__c = true;
        contractedNonLoopedLineItem.Apttus_Config2__PrimaryLineNumber__c = 1;
        contractedNonLoopedLineItem.Apttus_Config2__ItemSequence__c = 2;
        contractedNonLoopedLineItem.Apttus_Config2__SummaryGroupId__c = null;
        contractedNonLoopedLineItem.Apttus_Config2__LineType__c = '';
        contractedNonLoopedLineItem.Apttus_Config2__ProductId__c = childProduct1.Id;
        contractedNonLoopedLineItem.Apttus_Config2__Customizable__c = false;
        contractedNonLoopedLineItem.Apttus_Config2__ProductOptionId__c = null;
        contractedNonLoopedLineItem.Apttus_Config2__OptionId__c = childProduct1.Id;
        contractedNonLoopedLineItem.Apttus_Config2__ClassificationId__c = null;
        contractedNonLoopedLineItem.Apttus_Config2__ClassificationHierarchy__c = '';
        contractedNonLoopedLineItem.Apttus_Config2__Quantity__c = 2.3;
        contractedNonLoopedLineItem.Apttus_Config2__IsQuantityModifiable__c = false;
        contractedNonLoopedLineItem.Apttus_Config2__Uom__c = '';
        contractedNonLoopedLineItem.Apttus_Config2__Term__c = 1;
        contractedNonLoopedLineItem.Apttus_Config2__PriceListId__c = pricelist.Id;
        contractedNonLoopedLineItem.Apttus_Config2__PriceListItemId__c = childPLI1.Id;
        contractedNonLoopedLineItem.Apttus_Config2__PriceType__c = '';
        contractedNonLoopedLineItem.Apttus_Config2__PriceMethod__c = '';
        contractedNonLoopedLineItem.Apttus_Config2__ChargeType__c = 'Sales Price';
        contractedNonLoopedLineItem.Apttus_Config2__Frequency__c = '';
        contractedNonLoopedLineItem.Apttus_Config2__AllowManualAdjustment__c = false;
        contractedNonLoopedLineItem.Apttus_Config2__AllocateGroupAdjustment__c = false;
        contractedNonLoopedLineItem.Apttus_Config2__ListPrice__c = 22.00;
        contractedNonLoopedLineItem.Apttus_Config2__NetPrice__c = 30.00;
        contractedNonLoopedLineItem.Apttus_Config2__BasePrice__c = 24.00;
        contractedNonLoopedLineItem.Apttus_Config2__BasePriceMethod__c = '';
        contractedNonLoopedLineItem.Apttus_Config2__BaseExtendedPrice__c = 34.00;
        contractedNonLoopedLineItem.Apttus_Config2__OptionPrice__c = 23.00;
        contractedNonLoopedLineItem.Apttus_Config2__ExtendedPrice__c = 33.50;
        contractedNonLoopedLineItem.Apttus_Config2__Description__c = '';
        contractedNonLoopedLineItem.Apttus_Config2__AdjustedPrice__c = 0;
        contractedNonLoopedLineItem.Apttus_Config2__PriceUom__c = childProduct1.Apttus_Config2__Uom__c;
        lineitems.add(contractedNonLoopedLineItem);

        Apttus_Config2__LineItem__c contractedLoopedLineItem = new Apttus_Config2__LineItem__c();
        contractedLoopedLineItem.Apttus_Config2__ConfigurationId__c = contractedLoopedConfiguration.Id;
        contractedLoopedLineItem.Apttus_Config2__LineNumber__c = 1;
        contractedLoopedLineItem.Apttus_Config2__IsPrimaryLine__c = true;
        contractedLoopedLineItem.Apttus_Config2__PrimaryLineNumber__c = 1;
        contractedLoopedLineItem.Apttus_Config2__ItemSequence__c = 2;
        contractedLoopedLineItem.Apttus_Config2__SummaryGroupId__c = null;
        contractedLoopedLineItem.Apttus_Config2__LineType__c = '';
        contractedLoopedLineItem.Apttus_Config2__ProductId__c = childProduct1.Id;
        contractedLoopedLineItem.Apttus_Config2__Customizable__c = false;
        contractedLoopedLineItem.Apttus_Config2__ProductOptionId__c = null;
        contractedLoopedLineItem.Apttus_Config2__OptionId__c = childProduct1.Id;
        contractedLoopedLineItem.Apttus_Config2__ClassificationId__c = null;
        contractedLoopedLineItem.Apttus_Config2__ClassificationHierarchy__c = '';
        contractedLoopedLineItem.Apttus_Config2__Quantity__c = 2.3;
        contractedLoopedLineItem.Apttus_Config2__IsQuantityModifiable__c = false;
        contractedLoopedLineItem.Apttus_Config2__Uom__c = '';
        contractedLoopedLineItem.Apttus_Config2__Term__c = 1;
        contractedLoopedLineItem.Apttus_Config2__PriceListId__c = pricelist.Id;
        contractedLoopedLineItem.Apttus_Config2__PriceListItemId__c = childPLI1.Id;
        contractedLoopedLineItem.Apttus_Config2__PriceType__c = '';
        contractedLoopedLineItem.Apttus_Config2__PriceMethod__c = '';
        contractedLoopedLineItem.Apttus_Config2__ChargeType__c = 'Sales Price';
        contractedLoopedLineItem.Apttus_Config2__Frequency__c = '';
        contractedLoopedLineItem.Apttus_Config2__AllowManualAdjustment__c = false;
        contractedLoopedLineItem.Apttus_Config2__AllocateGroupAdjustment__c = false;
        contractedLoopedLineItem.Apttus_Config2__ListPrice__c = 22.00;
        contractedLoopedLineItem.Apttus_Config2__NetPrice__c = 30.00;
        contractedLoopedLineItem.Apttus_Config2__BasePrice__c = 24.00;
        contractedLoopedLineItem.Apttus_Config2__BasePriceMethod__c = '';
        contractedLoopedLineItem.Apttus_Config2__BaseExtendedPrice__c = 34.00;
        contractedLoopedLineItem.Apttus_Config2__OptionPrice__c = 23.00;
        contractedLoopedLineItem.Apttus_Config2__ExtendedPrice__c = 33.50;
        contractedLoopedLineItem.Apttus_Config2__Description__c = '';
        contractedLoopedLineItem.Apttus_Config2__AdjustedPrice__c = 0;
        contractedLoopedLineItem.Apttus_Config2__PriceUom__c = childProduct1.Apttus_Config2__Uom__c;
        lineitems.add(contractedLoopedLineItem);

        insert lineitems;
        System.debug('APTS_TGBatchTest: Line items created.');

        // Proposal line items for Child
        List<Apttus_Proposal__Proposal_Line_Item__c> proposalLineItems = new List<Apttus_Proposal__Proposal_Line_Item__c>();
        Apttus_Proposal__Proposal_Line_Item__c childProposalLineItem1 = new Apttus_Proposal__Proposal_Line_Item__c();
        childProposalLineItem1.Apttus_Proposal__Proposal__c = childQuote.Id;
        childProposalLineItem1.Apttus_QPConfig__DerivedFromId__c = childLineItem1.Id;
        childProposalLineItem1.Apttus_QPConfig__PriceListItemId__c = childPLI1.Id;
        childProposalLineItem1.Apttus_QPConfig__OptionId__c = childProduct1.Id;
        childProposalLineItem1.Apttus_Proposal__Product__c = childProduct1.Id;
        proposalLineItems.add(childProposalLineItem1);

        Apttus_Proposal__Proposal_Line_Item__c childProposalLineItem2 = new Apttus_Proposal__Proposal_Line_Item__c();
        childProposalLineItem2.Apttus_Proposal__Proposal__c = childQuote.Id;
        childProposalLineItem2.Apttus_QPConfig__DerivedFromId__c = childLineItem2.Id;
        childProposalLineItem2.Apttus_QPConfig__PriceListItemId__c = childPLI2.Id;
        childProposalLineItem2.Apttus_QPConfig__OptionId__c = childProduct2.Id;
        childProposalLineItem2.Apttus_Proposal__Product__c = childProduct2.Id;
        proposalLineItems.add(childProposalLineItem2);

        // Proposal line items for Parent
        Apttus_Proposal__Proposal_Line_Item__c parentProposalLineItem1 = new Apttus_Proposal__Proposal_Line_Item__c();
        parentProposalLineItem1.Apttus_Proposal__Proposal__c = parentQuote.Id;
        parentProposalLineItem1.Apttus_QPConfig__DerivedFromId__c = parentLineItem1.Id;
        parentProposalLineItem1.Apttus_QPConfig__PriceListItemId__c = parentPLI1.Id;
        parentProposalLineItem1.Apttus_QPConfig__OptionId__c = parentProduct1.Id;
        parentProposalLineItem1.Apttus_Proposal__Product__c = parentProduct1.Id;
        proposalLineItems.add(parentProposalLineItem1);

        Apttus_Proposal__Proposal_Line_Item__c parentProposalLineItem2 = new Apttus_Proposal__Proposal_Line_Item__c();
        parentProposalLineItem2.Apttus_Proposal__Proposal__c = parentQuote.Id;
        parentProposalLineItem2.Apttus_QPConfig__DerivedFromId__c = parentLineItem2.Id;
        parentProposalLineItem2.Apttus_QPConfig__PriceListItemId__c = parentPLI2.Id;
        parentProposalLineItem2.Apttus_QPConfig__OptionId__c = parentProduct2.Id;
        parentProposalLineItem2.Apttus_Proposal__Product__c = parentProduct2.Id;
        proposalLineItems.add(parentProposalLineItem2);

        // Proposal line items for Grand Parent
        Apttus_Proposal__Proposal_Line_Item__c grandParentProposalLineItem1 = new Apttus_Proposal__Proposal_Line_Item__c();
        grandParentProposalLineItem1.Apttus_Proposal__Proposal__c = grandParentQuote.Id;
        grandParentProposalLineItem1.Apttus_QPConfig__DerivedFromId__c = grandParentLineItem1.Id;
        grandParentProposalLineItem1.Apttus_QPConfig__PriceListItemId__c = grandParentPLI1.Id;
        grandParentProposalLineItem1.Apttus_QPConfig__OptionId__c = grandParentProduct1.Id;
        grandParentProposalLineItem1.Apttus_Proposal__Product__c = grandParentProduct1.Id;
        proposalLineItems.add(grandParentProposalLineItem1);

        Apttus_Proposal__Proposal_Line_Item__c grandParentProposalLineItem2 = new Apttus_Proposal__Proposal_Line_Item__c();
        grandParentProposalLineItem2.Apttus_Proposal__Proposal__c = grandParentQuote.Id;
        grandParentProposalLineItem2.Apttus_QPConfig__DerivedFromId__c = grandParentLineItem2.Id;
        grandParentProposalLineItem2.Apttus_QPConfig__PriceListItemId__c = grandParentPLI2.Id;
        grandParentProposalLineItem2.Apttus_QPConfig__OptionId__c = grandParentProduct2.Id;
        grandParentProposalLineItem2.Apttus_Proposal__Product__c = grandParentProduct2.Id;
        proposalLineItems.add(grandParentProposalLineItem2);

        insert proposalLineItems;
        System.debug('APTS_TGBatchTest: Proposal Line Items created.');

        // Agreement Line Items for Child
        List<Apttus__AgreementLineItem__c> AGLIs = new List<Apttus__AgreementLineItem__c>();
        Apttus__AgreementLineItem__c childAgreementLineItem1 = new Apttus__AgreementLineItem__c();
        childAgreementLineItem1.Apttus__ProductId__c = childProduct1.Id;
        childAgreementLineItem1.Apttus_CMConfig__LineNumber__c = 1;
        childAgreementLineItem1.Apttus_CMConfig__ItemSequence__c = 1;
        childAgreementLineItem1.Apttus__AgreementId__c = childAgreement.Id;
        childAgreementLineItem1.Apttus_CMConfig__BaseProductId__c = childProduct1.Id;
        childAgreementLineItem1.Apttus_CMConfig__BillToAccountId__c = childAccount.Id;
        childAgreementLineItem1.Apttus_CMConfig__DerivedFromId__c = childLineItem1.Id;
        childAgreementLineItem1.Apttus_CMConfig__PriceListItemId__c = childPLI1.Id;
        childAgreementLineItem1.Apttus__NetPrice__c = childLineItem1.Apttus_Config2__NetPrice__c;
        childAgreementLineItem1.Apttus__Quantity__c = 1;
        childAgreementLineItem1.Apttus_CMConfig__LineType__c = 'Product/Service';
        childAgreementLineItem1.Apttus_CMConfig__ChargeType__c = childLineItem1.Apttus_Config2__ChargeType__c;
        childAgreementLineItem1.Apttus_CMConfig__SellingTerm__c = 1;
        childAgreementLineItem1.Apttus_CMConfig__SellingFrequency__c = 'One Time';
        childAgreementLineItem1.Apttus_CMConfig__ClassificationHierarchy__c = 'Coffee | Espresso Beans';
        childAgreementLineItem1.Apttus_CMConfig__ClassificationId__c = subCategoryHierarchy.Id;
        childAgreementLineItem1.Apttus_CMConfig__StartDate__c = System.Today();
        childAgreementLineItem1.Apttus_CMConfig__EndDate__c = System.Today();
        childAgreementLineItem1.Apttus_CMConfig__Term__c = childLineItem1.Apttus_Config2__Term__c;
        childAgreementLineItem1.Apttus_CMConfig__PriceUom__c = childLineItem1.Apttus_Config2__PriceUom__c;
        AGLIs.add(childAgreementLineItem1);

        Apttus__AgreementLineItem__c childAgreementLineItem2 = new Apttus__AgreementLineItem__c();
        childAgreementLineItem2.Apttus__ProductId__c = childProduct2.Id;
        childAgreementLineItem2.Apttus_CMConfig__LineNumber__c = 1;
        childAgreementLineItem2.Apttus_CMConfig__ItemSequence__c = 1;
        childAgreementLineItem2.Apttus__AgreementId__c = childAgreement.Id;
        childAgreementLineItem2.Apttus_CMConfig__BaseProductId__c = childProduct2.Id;
        childAgreementLineItem2.Apttus_CMConfig__BillToAccountId__c = childAccount.Id;
        childAgreementLineItem2.Apttus_CMConfig__DerivedFromId__c = childLineItem2.Id;
        childAgreementLineItem2.Apttus_CMConfig__PriceListItemId__c = childPLI2.Id;
        childAgreementLineItem2.Apttus__NetPrice__c = childLineItem2.Apttus_Config2__NetPrice__c;
        childAgreementLineItem2.Apttus__Quantity__c = 1;
        childAgreementLineItem2.Apttus_CMConfig__LineType__c = 'Product/Service';
        childAgreementLineItem2.Apttus_CMConfig__ChargeType__c = childLineItem2.Apttus_Config2__ChargeType__c;
        childAgreementLineItem2.Apttus_CMConfig__SellingTerm__c = 1;
        childAgreementLineItem2.Apttus_CMConfig__SellingFrequency__c = 'One Time';
        childAgreementLineItem2.Apttus_CMConfig__ClassificationHierarchy__c = 'Coffee | Espresso Beans';
        childAgreementLineItem2.Apttus_CMConfig__ClassificationId__c = subCategoryHierarchy.Id;
        childAgreementLineItem2.Apttus_CMConfig__StartDate__c = System.Today();
        childAgreementLineItem2.Apttus_CMConfig__EndDate__c = System.Today();
        childAgreementLineItem2.Apttus_CMConfig__Term__c = childLineItem2.Apttus_Config2__Term__c;
        childAgreementLineItem2.Apttus_CMConfig__PriceUom__c = childLineItem2.Apttus_Config2__PriceUom__c;
        AGLIs.add(childAgreementLineItem2);

        // Agreement Line Items for Parent
        Apttus__AgreementLineItem__c parentAgreementLineItem1 = new Apttus__AgreementLineItem__c();
        parentAgreementLineItem1.Apttus__ProductId__c = parentProduct1.Id;
        parentAgreementLineItem1.Apttus_CMConfig__LineNumber__c = 1;
        parentAgreementLineItem1.Apttus_CMConfig__ItemSequence__c = 1;
        parentAgreementLineItem1.Apttus__AgreementId__c = parentAgreement.Id;
        parentAgreementLineItem1.Apttus_CMConfig__BaseProductId__c = parentProduct1.Id;
        parentAgreementLineItem1.Apttus_CMConfig__BillToAccountId__c = parentAccount.Id;
        parentAgreementLineItem1.Apttus_CMConfig__DerivedFromId__c = parentLineItem1.Id;
        parentAgreementLineItem1.Apttus_CMConfig__PriceListItemId__c = parentPLI1.Id;
        parentAgreementLineItem1.Apttus__NetPrice__c = parentLineItem1.Apttus_Config2__NetPrice__c;
        parentAgreementLineItem1.Apttus__Quantity__c = 1;
        parentAgreementLineItem1.Apttus_CMConfig__LineType__c = 'Product/Service';
        parentAgreementLineItem1.Apttus_CMConfig__ChargeType__c = parentLineItem1.Apttus_Config2__ChargeType__c;
        parentAgreementLineItem1.Apttus_CMConfig__SellingTerm__c = 1;
        parentAgreementLineItem1.Apttus_CMConfig__SellingFrequency__c = 'One Time';
        parentAgreementLineItem1.Apttus_CMConfig__ClassificationHierarchy__c = 'Coffee | Espresso Beans';
        parentAgreementLineItem1.Apttus_CMConfig__ClassificationId__c = subCategoryHierarchy.Id;
        parentAgreementLineItem1.Apttus_CMConfig__StartDate__c = System.Today();
        parentAgreementLineItem1.Apttus_CMConfig__EndDate__c = System.Today();
        parentAgreementLineItem1.Apttus_CMConfig__Term__c = parentLineItem1.Apttus_Config2__Term__c;
        parentAgreementLineItem1.Apttus_CMConfig__PriceUom__c = parentLineItem1.Apttus_Config2__PriceUom__c;
        AGLIs.add(parentAgreementLineItem1);

        Apttus__AgreementLineItem__c parentAgreementLineItem2 = new Apttus__AgreementLineItem__c();
        parentAgreementLineItem2.Apttus__ProductId__c = parentProduct2.Id;
        parentAgreementLineItem2.Apttus_CMConfig__LineNumber__c = 1;
        parentAgreementLineItem2.Apttus_CMConfig__ItemSequence__c = 1;
        parentAgreementLineItem2.Apttus__AgreementId__c = parentAgreement.Id;
        parentAgreementLineItem2.Apttus_CMConfig__BaseProductId__c = parentProduct2.Id;
        parentAgreementLineItem2.Apttus_CMConfig__BillToAccountId__c = parentAccount.Id;
        parentAgreementLineItem2.Apttus_CMConfig__DerivedFromId__c = parentLineItem2.Id;
        parentAgreementLineItem2.Apttus_CMConfig__PriceListItemId__c = parentPLI2.Id;
        parentAgreementLineItem2.Apttus__NetPrice__c = parentLineItem2.Apttus_Config2__NetPrice__c;
        parentAgreementLineItem2.Apttus__Quantity__c = 1;
        parentAgreementLineItem2.Apttus_CMConfig__LineType__c = 'Product/Service';
        parentAgreementLineItem2.Apttus_CMConfig__ChargeType__c = parentLineItem2.Apttus_Config2__ChargeType__c;
        parentAgreementLineItem2.Apttus_CMConfig__SellingTerm__c = 1;
        parentAgreementLineItem2.Apttus_CMConfig__SellingFrequency__c = 'One Time';
        parentAgreementLineItem2.Apttus_CMConfig__ClassificationHierarchy__c = 'Coffee | Espresso Beans';
        parentAgreementLineItem2.Apttus_CMConfig__ClassificationId__c = subCategoryHierarchy.Id;
        parentAgreementLineItem2.Apttus_CMConfig__StartDate__c = System.Today();
        parentAgreementLineItem2.Apttus_CMConfig__EndDate__c = System.Today();
        parentAgreementLineItem2.Apttus_CMConfig__Term__c = parentLineItem2.Apttus_Config2__Term__c;
        parentAgreementLineItem2.Apttus_CMConfig__PriceUom__c = parentLineItem2.Apttus_Config2__PriceUom__c;
        AGLIs.add(parentAgreementLineItem2);

        // Agreement Line Items for Grand Parent
        Apttus__AgreementLineItem__c grandParentAgreementLineItem1 = new Apttus__AgreementLineItem__c();
        grandParentAgreementLineItem1.Apttus__ProductId__c = grandParentProduct1.Id;
        grandParentAgreementLineItem1.Apttus_CMConfig__LineNumber__c = 1;
        grandParentAgreementLineItem1.Apttus_CMConfig__ItemSequence__c = 1;
        grandParentAgreementLineItem1.Apttus__AgreementId__c = grandParentAgreement.Id;
        grandParentAgreementLineItem1.Apttus_CMConfig__BaseProductId__c = grandParentProduct1.Id;
        grandParentAgreementLineItem1.Apttus_CMConfig__BillToAccountId__c = grandParentAccount.Id;
        grandParentAgreementLineItem1.Apttus_CMConfig__DerivedFromId__c = grandParentLineItem1.Id;
        grandParentAgreementLineItem1.Apttus_CMConfig__PriceListItemId__c = grandParentPLI1.Id;
        grandParentAgreementLineItem1.Apttus__NetPrice__c = grandParentLineItem1.Apttus_Config2__NetPrice__c;
        grandParentAgreementLineItem1.Apttus__Quantity__c = 1;
        grandParentAgreementLineItem1.Apttus_CMConfig__LineType__c = 'Product/Service';
        grandParentAgreementLineItem1.Apttus_CMConfig__ChargeType__c = grandParentLineItem1.Apttus_Config2__ChargeType__c;
        grandParentAgreementLineItem1.Apttus_CMConfig__SellingTerm__c = 1;
        grandParentAgreementLineItem1.Apttus_CMConfig__SellingFrequency__c = 'One Time';
        grandParentAgreementLineItem1.Apttus_CMConfig__ClassificationHierarchy__c = 'Coffee | Espresso Beans';
        grandParentAgreementLineItem1.Apttus_CMConfig__ClassificationId__c = subCategoryHierarchy.Id;
        grandParentAgreementLineItem1.Apttus_CMConfig__StartDate__c = System.Today();
        grandParentAgreementLineItem1.Apttus_CMConfig__EndDate__c = System.Today();
        grandParentAgreementLineItem1.Apttus_CMConfig__Term__c = grandParentLineItem1.Apttus_Config2__Term__c;
        grandParentAgreementLineItem1.Apttus_CMConfig__PriceUom__c = grandParentLineItem1.Apttus_Config2__PriceUom__c;
        AGLIs.add(grandParentAgreementLineItem1);

        Apttus__AgreementLineItem__c grandParentAgreementLineItem2 = new Apttus__AgreementLineItem__c();
        grandParentAgreementLineItem2.Apttus__ProductId__c = grandParentProduct2.Id;
        grandParentAgreementLineItem2.Apttus_CMConfig__LineNumber__c = 1;
        grandParentAgreementLineItem2.Apttus_CMConfig__ItemSequence__c = 1;
        grandParentAgreementLineItem2.Apttus__AgreementId__c = grandParentAgreement.Id;
        grandParentAgreementLineItem2.Apttus_CMConfig__BaseProductId__c = grandParentProduct2.Id;
        grandParentAgreementLineItem2.Apttus_CMConfig__BillToAccountId__c = grandParentAccount.Id;
        grandParentAgreementLineItem2.Apttus_CMConfig__DerivedFromId__c = grandParentLineItem2.Id;
        grandParentAgreementLineItem2.Apttus_CMConfig__PriceListItemId__c = grandParentPLI2.Id;
        grandParentAgreementLineItem2.Apttus__NetPrice__c = grandParentLineItem2.Apttus_Config2__NetPrice__c;
        grandParentAgreementLineItem2.Apttus__Quantity__c = 1;
        grandParentAgreementLineItem2.Apttus_CMConfig__LineType__c = 'Product/Service';
        grandParentAgreementLineItem2.Apttus_CMConfig__ChargeType__c = grandParentLineItem2.Apttus_Config2__ChargeType__c;
        grandParentAgreementLineItem2.Apttus_CMConfig__SellingTerm__c = 1;
        grandParentAgreementLineItem2.Apttus_CMConfig__SellingFrequency__c = 'One Time';
        grandParentAgreementLineItem2.Apttus_CMConfig__ClassificationHierarchy__c = 'Coffee | Espresso Beans';
        grandParentAgreementLineItem2.Apttus_CMConfig__ClassificationId__c = subCategoryHierarchy.Id;
        grandParentAgreementLineItem2.Apttus_CMConfig__StartDate__c = System.Today();
        grandParentAgreementLineItem2.Apttus_CMConfig__EndDate__c = System.Today();
        grandParentAgreementLineItem2.Apttus_CMConfig__Term__c = grandParentLineItem2.Apttus_Config2__Term__c;
        grandParentAgreementLineItem2.Apttus_CMConfig__PriceUom__c = grandParentLineItem2.Apttus_Config2__PriceUom__c;
        AGLIs.add(grandParentAgreementLineItem2);

        Apttus__AgreementLineItem__c nonContractedLoopedAgreementLineItem = new Apttus__AgreementLineItem__c();
        nonContractedLoopedAgreementLineItem.Apttus__ProductId__c = childProduct1.Id;
        nonContractedLoopedAgreementLineItem.Apttus_CMConfig__LineNumber__c = 1;
        nonContractedLoopedAgreementLineItem.Apttus_CMConfig__ItemSequence__c = 1;
        nonContractedLoopedAgreementLineItem.Apttus__AgreementId__c = nonContractedProductsAgreementLooped.Id;
        nonContractedLoopedAgreementLineItem.Apttus_CMConfig__BaseProductId__c = childProduct1.Id;
        nonContractedLoopedAgreementLineItem.Apttus_CMConfig__BillToAccountId__c = nonContractedProductsAccountLooped.Id;
        nonContractedLoopedAgreementLineItem.Apttus_CMConfig__DerivedFromId__c = nonContractedLoopedLineItem.Id;
        nonContractedLoopedAgreementLineItem.Apttus_CMConfig__PriceListItemId__c = childPLI1.Id;
        nonContractedLoopedAgreementLineItem.Apttus__NetPrice__c = nonContractedLoopedLineItem.Apttus_Config2__NetPrice__c;
        nonContractedLoopedAgreementLineItem.Apttus__Quantity__c = 1;
        nonContractedLoopedAgreementLineItem.Apttus_CMConfig__LineType__c = 'Product/Service';
        nonContractedLoopedAgreementLineItem.Apttus_CMConfig__ChargeType__c = nonContractedLoopedLineItem.Apttus_Config2__ChargeType__c;
        nonContractedLoopedAgreementLineItem.Apttus_CMConfig__SellingTerm__c = 1;
        nonContractedLoopedAgreementLineItem.Apttus_CMConfig__SellingFrequency__c = 'One Time';
        nonContractedLoopedAgreementLineItem.Apttus_CMConfig__ClassificationHierarchy__c = 'Coffee | Espresso Beans';
        nonContractedLoopedAgreementLineItem.Apttus_CMConfig__ClassificationId__c = subCategoryHierarchy.Id;
        nonContractedLoopedAgreementLineItem.Apttus_CMConfig__StartDate__c = System.Today();
        nonContractedLoopedAgreementLineItem.Apttus_CMConfig__EndDate__c = System.Today();
        nonContractedLoopedAgreementLineItem.Apttus_CMConfig__Term__c = nonContractedLoopedLineItem.Apttus_Config2__Term__c;
        nonContractedLoopedAgreementLineItem.Apttus_CMConfig__PriceUom__c = nonContractedLoopedLineItem.Apttus_Config2__PriceUom__c;
        AGLIs.add(nonContractedLoopedAgreementLineItem);

        Apttus__AgreementLineItem__c nonContractedNonLoopedAgreementLineItem = new Apttus__AgreementLineItem__c();
        nonContractedNonLoopedAgreementLineItem.Apttus__ProductId__c = childProduct1.Id;
        nonContractedNonLoopedAgreementLineItem.Apttus_CMConfig__LineNumber__c = 1;
        nonContractedNonLoopedAgreementLineItem.Apttus_CMConfig__ItemSequence__c = 1;
        nonContractedNonLoopedAgreementLineItem.Apttus__AgreementId__c = nonContractedProductsAgreementNonLooped.Id;
        nonContractedNonLoopedAgreementLineItem.Apttus_CMConfig__BaseProductId__c = childProduct1.Id;
        nonContractedNonLoopedAgreementLineItem.Apttus_CMConfig__BillToAccountId__c = nonContractedProductsAccountNonLooped.Id;
        nonContractedNonLoopedAgreementLineItem.Apttus_CMConfig__DerivedFromId__c = nonContractedNonLoopedLineItem.Id;
        nonContractedNonLoopedAgreementLineItem.Apttus_CMConfig__PriceListItemId__c = childPLI1.Id;
        nonContractedNonLoopedAgreementLineItem.Apttus__NetPrice__c = nonContractedNonLoopedLineItem.Apttus_Config2__NetPrice__c;
        nonContractedNonLoopedAgreementLineItem.Apttus__Quantity__c = 1;
        nonContractedNonLoopedAgreementLineItem.Apttus_CMConfig__LineType__c = 'Product/Service';
        nonContractedNonLoopedAgreementLineItem.Apttus_CMConfig__ChargeType__c = nonContractedNonLoopedLineItem.Apttus_Config2__ChargeType__c;
        nonContractedNonLoopedAgreementLineItem.Apttus_CMConfig__SellingTerm__c = 1;
        nonContractedNonLoopedAgreementLineItem.Apttus_CMConfig__SellingFrequency__c = 'One Time';
        nonContractedNonLoopedAgreementLineItem.Apttus_CMConfig__ClassificationHierarchy__c = 'Coffee | Espresso Beans';
        nonContractedNonLoopedAgreementLineItem.Apttus_CMConfig__ClassificationId__c = subCategoryHierarchy.Id;
        nonContractedNonLoopedAgreementLineItem.Apttus_CMConfig__StartDate__c = System.Today();
        nonContractedNonLoopedAgreementLineItem.Apttus_CMConfig__EndDate__c = System.Today();
        nonContractedNonLoopedAgreementLineItem.Apttus_CMConfig__Term__c = nonContractedNonLoopedLineItem.Apttus_Config2__Term__c;
        nonContractedNonLoopedAgreementLineItem.Apttus_CMConfig__PriceUom__c = nonContractedNonLoopedLineItem.Apttus_Config2__PriceUom__c;
        AGLIs.add(nonContractedNonLoopedAgreementLineItem);

        Apttus__AgreementLineItem__c contractedNonLoopedAgreementLineItem = new Apttus__AgreementLineItem__c();
        contractedNonLoopedAgreementLineItem.Apttus__ProductId__c = childProduct1.Id;
        contractedNonLoopedAgreementLineItem.Apttus_CMConfig__LineNumber__c = 1;
        contractedNonLoopedAgreementLineItem.Apttus_CMConfig__ItemSequence__c = 1;
        contractedNonLoopedAgreementLineItem.Apttus__AgreementId__c = contractedProductsAgreementNonLooped.Id;
        contractedNonLoopedAgreementLineItem.Apttus_CMConfig__BaseProductId__c = childProduct1.Id;
        contractedNonLoopedAgreementLineItem.Apttus_CMConfig__BillToAccountId__c = contractedProductsAccountNonLooped.Id;
        contractedNonLoopedAgreementLineItem.Apttus_CMConfig__DerivedFromId__c = contractedNonLoopedLineItem.Id;
        contractedNonLoopedAgreementLineItem.Apttus_CMConfig__PriceListItemId__c = childPLI1.Id;
        contractedNonLoopedAgreementLineItem.Apttus__NetPrice__c = contractedNonLoopedLineItem.Apttus_Config2__NetPrice__c;
        contractedNonLoopedAgreementLineItem.Apttus__Quantity__c = 1;
        contractedNonLoopedAgreementLineItem.Apttus_CMConfig__LineType__c = 'Product/Service';
        contractedNonLoopedAgreementLineItem.Apttus_CMConfig__ChargeType__c = contractedNonLoopedLineItem.Apttus_Config2__ChargeType__c;
        contractedNonLoopedAgreementLineItem.Apttus_CMConfig__SellingTerm__c = 1;
        contractedNonLoopedAgreementLineItem.Apttus_CMConfig__SellingFrequency__c = 'One Time';
        contractedNonLoopedAgreementLineItem.Apttus_CMConfig__ClassificationHierarchy__c = 'Coffee | Espresso Beans';
        contractedNonLoopedAgreementLineItem.Apttus_CMConfig__ClassificationId__c = subCategoryHierarchy.Id;
        contractedNonLoopedAgreementLineItem.Apttus_CMConfig__StartDate__c = System.Today();
        contractedNonLoopedAgreementLineItem.Apttus_CMConfig__EndDate__c = System.Today();
        contractedNonLoopedAgreementLineItem.Apttus_CMConfig__Term__c = contractedNonLoopedLineItem.Apttus_Config2__Term__c;
        contractedNonLoopedAgreementLineItem.Apttus_CMConfig__PriceUom__c = contractedNonLoopedLineItem.Apttus_Config2__PriceUom__c;
        AGLIs.add(contractedNonLoopedAgreementLineItem);

        Apttus__AgreementLineItem__c contractedLoopedAgreementLineItem = new Apttus__AgreementLineItem__c();
        contractedLoopedAgreementLineItem.Apttus__ProductId__c = childProduct1.Id;
        contractedLoopedAgreementLineItem.Apttus_CMConfig__LineNumber__c = 1;
        contractedLoopedAgreementLineItem.Apttus_CMConfig__ItemSequence__c = 1;
        contractedLoopedAgreementLineItem.Apttus__AgreementId__c = contractedProductsAgreementLooped.Id;
        contractedLoopedAgreementLineItem.Apttus_CMConfig__BaseProductId__c = childProduct1.Id;
        contractedLoopedAgreementLineItem.Apttus_CMConfig__BillToAccountId__c = contractedProductsAccountLooped.Id;
        contractedLoopedAgreementLineItem.Apttus_CMConfig__DerivedFromId__c = contractedLoopedLineItem.Id;
        contractedLoopedAgreementLineItem.Apttus_CMConfig__PriceListItemId__c = childPLI1.Id;
        contractedLoopedAgreementLineItem.Apttus__NetPrice__c = contractedLoopedLineItem.Apttus_Config2__NetPrice__c;
        contractedLoopedAgreementLineItem.Apttus__Quantity__c = 1;
        contractedLoopedAgreementLineItem.Apttus_CMConfig__LineType__c = 'Product/Service';
        contractedLoopedAgreementLineItem.Apttus_CMConfig__ChargeType__c = contractedLoopedLineItem.Apttus_Config2__ChargeType__c;
        contractedLoopedAgreementLineItem.Apttus_CMConfig__SellingTerm__c = 1;
        contractedLoopedAgreementLineItem.Apttus_CMConfig__SellingFrequency__c = 'One Time';
        contractedLoopedAgreementLineItem.Apttus_CMConfig__ClassificationHierarchy__c = 'Coffee | Espresso Beans';
        contractedLoopedAgreementLineItem.Apttus_CMConfig__ClassificationId__c = subCategoryHierarchy.Id;
        contractedLoopedAgreementLineItem.Apttus_CMConfig__StartDate__c = System.Today();
        contractedLoopedAgreementLineItem.Apttus_CMConfig__EndDate__c = System.Today();
        contractedLoopedAgreementLineItem.Apttus_CMConfig__Term__c = contractedLoopedLineItem.Apttus_Config2__Term__c;
        contractedLoopedAgreementLineItem.Apttus_CMConfig__PriceUom__c = contractedLoopedLineItem.Apttus_Config2__PriceUom__c;
        AGLIs.add(contractedLoopedAgreementLineItem);

        insert AGLIs;
        System.debug('APTS_TGBatchTest: Agreement Line Items created.');

        // Activation of agreements
        List<Apttus__APTS_Agreement__c> agreementsToActivate = new List<Apttus__APTS_Agreement__c>();
        childAgreement.Apttus__Status__c = 'Activated';
        childAgreement.Apttus__Status_Category__c = 'In Effect';
        childAgreement.Apttus__Contract_End_Date__c = System.Today().addDays(365);
        agreementsToActivate.add(childAgreement);

        parentAgreement.Apttus__Status__c = 'Activated';
        parentAgreement.Apttus__Status_Category__c = 'In Effect';
        parentAgreement.Apttus__Contract_End_Date__c = System.Today().addDays(365);
        agreementsToActivate.add(parentAgreement);

        grandParentAgreement.Apttus__Status__c = 'Activated';
        grandParentAgreement.Apttus__Status_Category__c = 'In Effect';
        grandParentAgreement.Apttus__Contract_End_Date__c = System.Today().addDays(365);
        agreementsToActivate.add(grandParentAgreement);

        contractedProductsAgreementLooped.Apttus__Status__c = 'Activated';
        contractedProductsAgreementLooped.Apttus__Status_Category__c = 'In Effect';
        contractedProductsAgreementLooped.Apttus__Contract_End_Date__c = System.Today().addDays(365);
        agreementsToActivate.add(contractedProductsAgreementLooped);

        contractedProductsAgreementNonLooped.Apttus__Status__c = 'Activated';
        contractedProductsAgreementNonLooped.Apttus__Status_Category__c = 'In Effect';
        contractedProductsAgreementNonLooped.Apttus__Contract_End_Date__c = System.Today().addDays(365);
        agreementsToActivate.add(contractedProductsAgreementNonLooped);

        nonContractedProductsAgreementLooped.Apttus__Status__c = 'Activated';
        nonContractedProductsAgreementLooped.Apttus__Status_Category__c = 'In Effect';
        nonContractedProductsAgreementLooped.Apttus__Contract_End_Date__c = System.Today().addDays(365);
        agreementsToActivate.add(nonContractedProductsAgreementLooped);

        nonContractedProductsAgreementNonLooped.Apttus__Status__c = 'Activated';
        nonContractedProductsAgreementNonLooped.Apttus__Status_Category__c = 'In Effect';
        nonContractedProductsAgreementNonLooped.Apttus__Contract_End_Date__c = System.Today().addDays(365);
        agreementsToActivate.add(nonContractedProductsAgreementNonLooped);

        update agreementsToActivate;
        System.debug('APTS_TGBatchTest: Agreements activated.');

        List <Apttus__APTS_Agreement__c> agreementsToUpdate = new List <Apttus__APTS_Agreement__c> ();           
        
        agreementsToUpdate.clear();           
        agreementsToUpdate.add(grandParentAgreement);            
        APTS_ManageCER.manageCERRecords(agreementsToUpdate,'Agreement','Insert');
        
        agreementsToUpdate.clear();
        agreementsToUpdate.add(parentAgreement);
        APTS_ManageCER.manageCERRecords(agreementsToUpdate,'Agreement','Insert');

        agreementsToUpdate.clear();           
        agreementsToUpdate.add(childAgreement);            
        APTS_ManageCER.manageCERRecords(agreementsToUpdate,'Agreement','Insert');

        agreementsToUpdate.clear();           
        agreementsToUpdate.add(nonContractedProductsAgreementLooped);            
        APTS_ManageCER.manageCERRecords(agreementsToUpdate,'Agreement','Insert');

        agreementsToUpdate.clear();           
        agreementsToUpdate.add(nonContractedProductsAgreementNonLooped);            
        APTS_ManageCER.manageCERRecords(agreementsToUpdate,'Agreement','Insert');

        agreementsToUpdate.clear();           
        agreementsToUpdate.add(contractedProductsAgreementLooped);            
        APTS_ManageCER.manageCERRecords(agreementsToUpdate,'Agreement','Insert');

        agreementsToUpdate.clear();           
        agreementsToUpdate.add(contractedProductsAgreementNonLooped);            
        APTS_ManageCER.manageCERRecords(agreementsToUpdate,'Agreement','Insert');
    }

    @isTest static void getAgreementListAllTest()
    {
        Test.startTest();

        CreateTestDataforTG();
        // Test
        List<Account> accounts = new List<Account>();
        accounts.add(childAccount);
        accounts.add(parentAccount);
        accounts.add(grandParentAccount);
        Map<Id,List<Product2>> productsAgreementListAllMap = APTS_TGBatch.getAgreementListAll(accounts);
        System.assertEquals(6,productsAgreementListAllMap.get(childAccount.Id).size(), 'The right number of records are not being obtained in AGR_LIST_FULL getter for child account');
        System.assertEquals(4,productsAgreementListAllMap.get(parentAccount.Id).size(), 'The right number of records are not being obtained in AGR_LIST_FULL getter for parent account');
        System.assertEquals(2,productsAgreementListAllMap.get(grandParentAccount.Id).size(), 'The right number of records are not being obtained in AGR_LIST_FULL getter for grand Parent account');

        Test.stopTest();
    }

    @isTest static void getAgreementListDeltaTest()
    {
        Test.startTest();

        CreateTestDataforTG();

        List<Account> accounts = new List<Account>();
        accounts.add(childAccount);
        accounts.add(parentAccount);
        accounts.add(grandParentAccount);

        Map<Id,List<Product2>> productsAgreementListDeltaMap = APTS_TGBatch.getAgreementListDelta(accounts);

        System.assertEquals(6,productsAgreementListDeltaMap.get(childAccount.Id).size(), 'The right number of records are not being obtained in AGR_LIST_FULL getter for child account');
        System.assertEquals(4,productsAgreementListDeltaMap.get(parentAccount.Id).size(), 'The right number of records are not being obtained in AGR_LIST_FULL getter for parent account');
        System.assertEquals(2,productsAgreementListDeltaMap.get(grandParentAccount.Id).size(), 'The right number of records are not being obtained in AGR_LIST_FULL getter for grand Parent account');
        Test.stopTest();
    }


   @isTest static void getPLIListDeltaTestData()
    {
        Test.startTest();

        CreateTestDataforTG();
        // Test
        List<Apttus_Config2__PriceList__c> priceLists = [SELECT Id FROM Apttus_Config2__PriceList__c  WHERE Name = 'Germany General Pricelist - EUR'];
        List<Product2> productsPLIListDelta = APTS_TGBatch.getPLIListDelta(priceLists);
        System.assertNotEquals(0, productsPLIListDelta.size());

        Test.stopTest();
    }

    @isTest static void getPLIListDeltaTestEmpty()
    {
        Test.startTest();

        CreateTestDataforTG();
        // Test
        List<Apttus_Config2__PriceList__c> priceLists = [SELECT Id FROM Apttus_Config2__PriceList__c WHERE Name <> 'Germany General Pricelist - EUR'];
        List<Product2> productsPLIListDelta = APTS_TGBatch.getPLIListDelta(priceLists);
        System.assertEquals(0, productsPLIListDelta.size());

        Test.stopTest();
    }

    @isTest static void getPLIListFullTestData()
    {
        Test.startTest();

        CreateTestDataforTG();
        // Test
        List<Apttus_Config2__PriceList__c> priceLists = [SELECT Id FROM Apttus_Config2__PriceList__c WHERE Name = 'Germany General Pricelist - EUR'];
        List<Product2> productsPLIListFull = APTS_TGBatch.getPLIListFull(priceLists);
        System.assertNotEquals(0, productsPLIListFull.size());

        Test.stopTest();
    }

    @isTest static void getPLIListFullTestEmpty()
    {
        Test.startTest();

        CreateTestDataforTG();
        // Test
        List<Apttus_Config2__PriceList__c> priceLists = [SELECT Id FROM Apttus_Config2__PriceList__c WHERE Name <> 'Germany General Pricelist - EUR'];
        List<Product2> productsPLIListFull = APTS_TGBatch.getPLIListFull(priceLists);
        System.assertEquals(0, productsPLIListFull.size());

        Test.stopTest();
    }

      @isTest static void canOrderNonContractedProductsTest()
    {        
        CreateTestDataforTG();

        Test.startTest();

        List<Account> accounts = new List<Account>();

        accounts.add(nullAccount); 
        accounts.add(nonTGAccount); 
        accounts.add(nonContractedProductsAccountNonLooped); 
        accounts.add(nonContractedProductsAccountLooped); 
        accounts.add(contractedProductsAccountNonLooped); 
        accounts.add(contractedProductsAccountLooped); 

        Map<Id, Boolean> canOrderNonContractedProductsMap = APTS_TGBatch.canOrderNonContractedProducts(accounts);

        System.assertNotEquals(null, canOrderNonContractedProductsMap);
        System.assertEquals(false, canOrderNonContractedProductsMap.get(nonTGAccount.Id));
        System.assertEquals(false, canOrderNonContractedProductsMap.get(nonContractedProductsAccountNonLooped.Id));
        System.assertEquals(false, canOrderNonContractedProductsMap.get(nonContractedProductsAccountLooped.Id));
        System.assertEquals(true, canOrderNonContractedProductsMap.get(contractedProductsAccountNonLooped.Id));
        System.assertEquals(true, canOrderNonContractedProductsMap.get(contractedProductsAccountLooped.Id));

        Test.stopTest();
    }

    @isTest static void processTGTest()
    {
        Test.startTest();

        CreateTestDataforTG();

        List<Account> accounts = new List<Account>();

        accounts.add(childAccount); 
        accounts.add(parentAccount);
        accounts.add(grandParentAccount);
        accounts.add(nullAccount); // Scenario #1a
        accounts.add(nonTGAccount); // Scenario #1b
        accounts.add(nonContractedProductsAccountNonLooped); // Scenario #2
        accounts.add(nonContractedProductsAccountLooped); // Scenario #3
        accounts.add(contractedProductsAccountNonLooped); // Scenario #4
        accounts.add(contractedProductsAccountLooped); // Scenario #5

        APTS_TGBatch batch = new APTS_TGBatch();        
        List<APTS_TGBatch.TGRecord> records = batch.processTG(accounts);

        Test.stopTest();
    }
}