/*************************************************************
@Name: APTS_TestFacade
@Author: Galin Georgiev
@CreateDate: 02-01-2018
@Description: Test facade class
@UsedBy: Test classes
******************************************************************/
//v100 19-02-2018 Galin Georgiev: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes
//v101 28/06/2018 Raul Orozco : Change in name of products all in coverage, basic coverage to improve
//                              code coverage as the value of labels validated in PCB changed

@isTest
public class APTS_TestFacade {

    private static final String ACTIVATED = System.Label.APTS_Activated;
    private static final String IN_EFFECT = System.Label.APTS_In_Effect;
    private static final String STANDARD_DEAL = System.Label.APTS_Standard_Deal;
    private static final String STANDARD_ORDER = System.Label.APTS_Standard_Order;
    private static final String MACHINE_ORDER = System.Label.APTS_Machine_Order;
    private static final String NGSTANDARD_ORDER = System.Label.APTS_NGStandardOrder;
    private static final String NGMACHINE_ORDER = System.Label.APTS_NGMachineOrder;
    private static final String BEINGAMENDED = System.Label.APTS_Being_Amended;
    private static final String INSTALLATION = System.Label.APTS_Installation;
    private static final String OPTION = System.Label.APTS_Option;

    //Create test user
    @TestVisible private static User createTestUser() {

        User testuser = APTS_TestDataFactory.createUser();
        Database.insert(testuser);

        System.runAs(testuser) {

            Group oGroup = new Group(Name = 'Apttus Users');
            Database.insert(oGroup);

            GroupMember oGroupMember = new GroupMember();
            oGroupMember.UserOrGroupId = testuser.Id;
            oGroupMember.GroupId = oGroup.Id;
            Database.insert(oGroupMember);
        }

        return testuser;
    }

    //create mandatory records
    @TestVisible private static void createMandatoryRecords(User testuser) {

        System.runAs(testuser) {

            TriggerSettings__c oTriggerSettings = new TriggerSettings__c(AccountTrigger__c = false, Agreement__c = false, APTS_Order_Trigger__c = true,
                    APTS_OrderLineItemTrigger__c = true, APTS_OrderFulfillmentLineItemTrigger__c = true, APTS_Order_Adjustment_Trigger__c = true/*, SetupOwnerId = testuser.ProfileId*/);
            Database.insert(oTriggerSettings);

            APTS_DaysByCalendarMonthAVG__c daysByCalenderSettings = new APTS_DaysByCalendarMonthAVG__c(Name='Decimal2',DivideBy__c=30.41);
            Database.insert(daysByCalenderSettings);
            
            APTS_SAP_Connection_Settings__c oSAPConnectionSettings = new APTS_SAP_Connection_Settings__c(Name = 'ATP Check', APTS_Endpoint__c = 'Endpoint', APTS_UseFakeEndpoint__c = false, APTS_FakeEndpoint__c = 'FE', APTS_Timeout__c = 60);
            Database.insert(oSAPConnectionSettings);

            Apttus_Config2__BillingPreference__c oBillingPreference = APTS_TestDataFactory.createBillingPrefrence('JDETestPrefrence');
            Database.insert(oBillingPreference);

            APTS_Payment_Method__c paymentMethod = APTS_TestUtils.paymentMethod();
            insert paymentMethod;

            Apttus_Config2__PaymentTerm__c paymentTerm = APTS_TestUtils.paymentTerm();
            paymentTerm.Apttus_Config2__Sequence__c = 5;
            insert paymentTerm;            

            // create account
            Account oAccount = APTS_TestDataFactory.createAccount('JDETestAccount');
            oAccount.Sales_Organization__c = 'SAP_0111';
            oAccount.Distribution_Channel__c = 'SAP_10';
            oAccount.Division__c = 'SAP_20';
            oAccount.SAP_Customer_ID__c = '123';
            oAccount.Apttus_Config2__BillingPreferenceId__c = oBillingPreference.Id;
            oAccount.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
            oAccount.APTS_Payment_Method__c = paymentMethod.Id;
            Database.insert(oAccount);

            // create second account
            Account oSecondAccount = APTS_TestDataFactory.createAccount('JDESecondTestAccount');
            oSecondAccount.Sales_Organization__c = 'SAP_0111';
            oSecondAccount.Distribution_Channel__c = 'SAP_10';
            oSecondAccount.Division__c = 'SAP_20';
            oSecondAccount.SAP_Customer_ID__c = '1253';
            oSecondAccount.Apttus_Config2__BillingPreferenceId__c = oBillingPreference.Id;
            oSecondAccount.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
            oSecondAccount.APTS_Payment_Method__c = paymentMethod.Id;            
            Database.insert(oSecondAccount);

            // create contact
            List<Contact> contactList = new List<Contact>();
            Contact oContact = APTS_TestDataFactory.createContact(oAccount, '1010101011');
            oContact.Function__c = 'Buyer Ingredients';
            oContact.Main_Service_Person__c = true;
            contactList.add(oContact);
            Contact oContact1 = APTS_TestDataFactory.createContact(oAccount, '1010101012');
            oContact1.Function__c = 'Buyer Ingredients';
            contactList.add(oContact1);
            Contact oContact2 = APTS_TestDataFactory.createContact(oAccount, '1010101013');
            oContact2.Function__c = 'Buyer All';
            contactList.add(oContact2);
            Contact oContact3 = APTS_TestDataFactory.createContact(oAccount, '1010101014');
            oContact3.Function__c = 'Buyer All';
            contactList.add(oContact3);
            Contact oContact4 = APTS_TestDataFactory.createContact(oAccount, '1010101015');
            oContact4.Function__c = 'Buyer All';
            oContact4.Main_Commercial_Person__c = true;
            contactList.add(oContact4);
            Contact oContact5 = APTS_TestDataFactory.createContact(oAccount, '1010101016');
            oContact5.Function__c = 'Buyer All';
            oContact5.Main_Commercial_Person__c = true;            
            contactList.add(oContact5);

            Database.insert(contactList);

            //create opportunity
            Opportunity oOpportunity = APTS_TestDataFactory.createOpportunity('JDETestOpportunity', oAccount.Id);
            Database.insert(oOpportunity);

            //create price list
            Apttus_Config2__PriceList__c pricelist = APTS_TestDataFactory.createPriceList('JDETest Price List');
            Database.insert(pricelist);

            //Create Products
            List<Product2> prodList = new List<Product2>();
            Product2 oStandaloneProduct = APTS_TestDataFactory.createProduct('Standalone', '104', 'MA', 'Standalone', FALSE, FALSE);
            Product2 oBundleProduct = APTS_TestDataFactory.createProduct('Bundle', '101', 'MA', 'Bundle', FALSE, TRUE);
            oBundleProduct.APTS_Material_Type__c = 'ZCMA';
            Product2 oOptionProduct = APTS_TestDataFactory.createProduct('Option', '102', 'MA', 'Option', FALSE, FALSE);
            oOptionProduct.APTS_Plug_and_Play_Indicator__c = true;
            //v101++<<
            Product2 oAllInCvrgProduct = APTS_TestDataFactory.createProduct('ALL-IN COVERAGE', '102', 'MA', 'Option', FALSE, FALSE);
            Product2 oBasicCvrgProduct = APTS_TestDataFactory.createProduct('BASIC COVERAGE', '102', 'MA', 'Option', FALSE, FALSE);
            Product2 oZCMAProduct = APTS_TestDataFactory.createProduct('BASIC COVERAGE', '102', 'MA', 'Bundle', FALSE, FALSE);
            Product2 oZOPTProduct = APTS_TestDataFactory.createProduct('BASIC COVERAGE', '102', 'MA', 'Option', FALSE, FALSE);
            //v100++>>
            oZCMAProduct.APTS_Material_Type__c = 'ZCMA';
            oZOPTProduct.APTS_Material_Type__c = 'ZOPT';

            prodList.add(oStandaloneProduct);
            prodList.add(oBundleProduct);
            prodList.add(oOptionProduct);
            prodList.add(oAllInCvrgProduct);
            prodList.add(oBasicCvrgProduct);
            prodList.add(oZCMAProduct);
            prodList.add(oZOPTProduct);

            Database.insert(prodList);

            //Create Price List Items
            List<Apttus_Config2__PriceListItem__c> priceListItemList = new List<Apttus_Config2__PriceListItem__c>();
            Apttus_Config2__PriceListItem__c oPriceListItemStandalone = APTS_TestDataFactory.createPriceListItem(priceList.Id, oStandaloneProduct.Id);
            priceListItemList.add(oPriceListItemStandalone);
            Apttus_Config2__PriceListItem__c oPriceListItemBundle = APTS_TestDataFactory.createPriceListItem(priceList.Id, oBundleProduct.Id);
            oPriceListItemBundle.APTS_Call_Out_Coverage__c = 10;
            oPriceListItemBundle.APTS_Labour_Coverage__c = 10;
            oPriceListItemBundle.APTS_Spare_Parts_Coverage__c = 10;
            priceListItemList.add(oPriceListItemBundle);
            Apttus_Config2__PriceListItem__c oPriceListItemOption = APTS_TestDataFactory.createPriceListItem(priceList.Id, oOptionProduct.Id);
            priceListItemList.add(oPriceListItemOption);
            Apttus_Config2__PriceListItem__c oPriceListItemAllInCvrg = APTS_TestDataFactory.createPriceListItem(priceList.Id, oAllInCvrgProduct.Id);
            priceListItemList.add(oPriceListItemAllInCvrg);
            Apttus_Config2__PriceListItem__c oPriceListItemBasicCvrg = APTS_TestDataFactory.createPriceListItem(priceList.Id, oBasicCvrgProduct.Id);
            priceListItemList.add(oPriceListItemBasicCvrg);
            Database.insert(priceListItemList);

            Apttus_Config2__ClassificationName__c category = APTS_TestDataFactory.createCategory();
            Database.insert(category);
            Apttus_Config2__ClassificationName__c categoryMachines = APTS_TestDataFactory.createCategory();
            categoryMachines.Name = 'Machines';
            Database.insert(categoryMachines);

            List<Apttus_Config2__ClassificationHierarchy__c> categoryHierarchyList = new List<Apttus_Config2__ClassificationHierarchy__c>();
            Apttus_Config2__ClassificationHierarchy__c categoryHierarchyMachine = APTS_TestDataFactory.createCategoryHierarchy(categoryMachines.Id, 'Machine');
            Apttus_Config2__ClassificationHierarchy__c categoryHierarchyService = APTS_TestDataFactory.createCategoryHierarchy(category.Id, 'Service');
            Apttus_Config2__ClassificationHierarchy__c categoryHierarchyCoffee = APTS_TestDataFactory.createCategoryHierarchy(category.Id, 'Coffee');
            categoryHierarchyList.add(categoryHierarchyMachine);
            categoryHierarchyList.add(categoryHierarchyService);
            categoryHierarchyList.add(categoryHierarchyCoffee);
            Database.insert(categoryHierarchyList);

            Apttus_Config2__ClassificationHierarchy__c subCategoryHierarchy = APTS_TestDataFactory.createSubCategory(category.Id, categoryHierarchyMachine.Id);
            Database.insert(subCategoryHierarchy);

            Apttus_Config2__ClassificationHierarchy__c subSubCategoryHierarchy = APTS_TestDataFactory.createSubCategory(category.Id, categoryHierarchyMachine.Id);
            subSubCategoryHierarchy.Name = 'Sub sub category';
            subSubCategoryHierarchy.Apttus_Config2__AncestorId__c = subCategoryHierarchy.Id;
            Database.insert(subSubCategoryHierarchy);

            Apttus_Config2__ProductClassification__c productClassification = APTS_TestDataFactory.createProductClassification(categoryHierarchyMachine.Id, oBundleProduct.Id);
            Database.insert(productClassification);

            List<Apttus_Config2__ProductOptionGroup__c> productOptionGroupList = new List<Apttus_Config2__ProductOptionGroup__c>();
            Apttus_Config2__ProductOptionGroup__c oProductOptionGroupMachine = APTS_TestDataFactory.createProductOptionGroup(categoryHierarchyMachine.Id, subCategoryHierarchy.Id);
            productOptionGroupList.add(oProductOptionGroupMachine);
            Apttus_Config2__ProductOptionGroup__c oProductOptionGroupService = APTS_TestDataFactory.createProductOptionGroup(categoryHierarchyService.Id, subCategoryHierarchy.Id);
            productOptionGroupList.add(oProductOptionGroupService);
            Database.insert(productOptionGroupList);

            List<Apttus_Config2__ProductOptionComponent__c> productOptionComponentList = new List<Apttus_Config2__ProductOptionComponent__c>();
            Apttus_Config2__ProductOptionComponent__c oProductOptionComponentMachine = APTS_TestDataFactory.createProductOptionComponent(oProductOptionGroupMachine.Id);
            oProductOptionComponentMachine.Apttus_Config2__ComponentProductId__c = oBundleProduct.Id;
            oProductOptionComponentMachine.Apttus_Config2__ParentProductId__c = oOptionProduct.Id;
            oProductOptionComponentMachine.Apttus_Config2__RelationshipType__c = 'Option';
            productOptionComponentList.add(oProductOptionComponentMachine);

            Apttus_Config2__ProductOptionComponent__c oProductOptionComponentService = APTS_TestDataFactory.createProductOptionComponent(oProductOptionGroupService.Id);
            productOptionComponentList.add(oProductOptionComponentService);
            Database.insert(productOptionComponentList);
        }
    }

    //Create Agreement and Agreement Line Items
    @TestVisible private static void createAndConfigureAgreement(User testuser) {

        Contact oContact = getContact();
        Account oAccount = getAccount();

        Product2 oStandaloneProduct = getStandaloneProduct();
        Product2 oBundleProduct = getBundleProduct();
        Product2 oOptionProduct = getOptionProduct();
        Apttus_Config2__BillingPreference__c oBillingPreference = getBillingPreference();

        Apttus_Config2__PriceList__c oPriceList = getPriceList();

        Apttus_Config2__PriceListItem__c oPriceListItemStandalone = getPriceListItem(oStandaloneProduct.Id);
        Apttus_Config2__PriceListItem__c oPriceListItemBundle = getPriceListItem(oBundleProduct.Id);
        Apttus_Config2__PriceListItem__c oPriceListItemOption = getPriceListItem(oOptionProduct.Id);

        Apttus_Config2__ProductOptionComponent__c oProductOptionComponentMachine = getProductOptionComponent('Machine');

        System.runAs(testuser) {           
           
            Apttus__APTS_Agreement__c oAgreement = APTS_TestDataFactory.createAgreement(oContact.Id, oPriceList.Id, oAccount.Id, STANDARD_DEAL, 'Agreement');
            oAgreement.Apttus__Status_Category__c = IN_EFFECT;
            oAgreement.Apttus__Status__c = ACTIVATED;
            oAgreement.Apttus__Contract_End_Date__c = Date.Today().addDays(365);             
            oAgreement.APTS_Is_Amended_for_Indexation__c = true; //to increase line coverage - akhilesh 
            Database.insert(oAgreement);
            system.debug('241:: oAgreement :: '+oAgreement);

            Apttus__APTS_Agreement__c oAgreementCM = APTS_TestDataFactory.createAgreement(oContact.Id, oPriceList.Id, oAccount.Id, 'Consumption Model', 'AgreementCM');
            oAgreementCM.Apttus__Status_Category__c = IN_EFFECT;
            oAgreementCM.Apttus__Status__c = ACTIVATED;
            oAgreementCM.Apttus__Contract_End_Date__c = Date.Today().addDays(365);
            Database.insert(oAgreementCM);
            system.debug('248:: oAgreement :: '+oAgreementCM);
            Apttus__APTS_Agreement__c oAmendedAgreement = APTS_TestDataFactory.createAgreement(oContact.Id, oPriceList.Id, oAccount.Id, 'Consumption Model', 'Agreement Amended');
            oAmendedAgreement.Apttus__Status_Category__c = IN_EFFECT;
            oAmendedAgreement.Apttus__Status__c = ACTIVATED;
            oAmendedAgreement.Apttus__Contract_End_Date__c = Date.Today().addDays(365);
            Database.insert(oAmendedAgreement);
            system.debug('254:: oAgreement :: '+oAmendedAgreement);
            Apttus__APTS_Agreement__c oCancelledAgreement = APTS_TestDataFactory.createAgreement(oContact.Id, oPriceList.Id, oAccount.Id, STANDARD_DEAL, 'Cancelled Agreement');
            oCancelledAgreement.Apttus__Status_Category__c = IN_EFFECT;
            oCancelledAgreement.Apttus__Status__c = ACTIVATED;
            oCancelledAgreement.Apttus__Contract_End_Date__c = Date.Today().addDays(365);
            oCancelledAgreement.Apttus__Version_Number__c = 1;
            Database.insert(oCancelledAgreement);

            Apttus_Config2__ProductConfiguration__c oMachineProductConfiguration = APTS_TestDataFactory.createProductConfig(oAgreementCM);
            oMachineProductConfiguration.Apttus_Config2__Status__c = 'Finalized';
            Database.insert(oMachineProductConfiguration);

            Apttus_Config2__ProductConfiguration__c oAmendedProductConfiguration = APTS_TestDataFactory.createProductConfig(oAmendedAgreement);
            oAmendedProductConfiguration.Apttus_Config2__Status__c = 'Finalized';
            Database.insert(oAmendedProductConfiguration);

            Apttus_Config2__ProductConfiguration__c oCancelledProductConfiguration = APTS_TestDataFactory.createProductConfig(oCancelledAgreement);
            oCancelledProductConfiguration.Apttus_Config2__Status__c = 'Finalized';
            Database.insert(oCancelledProductConfiguration);

            List<Apttus_Config2__LineItem__c> lineItemList = new List<Apttus_Config2__LineItem__c>();
            Apttus_Config2__LineItem__c oMachineLineItemBundle = APTS_TestDataFactory.createLineItem(oMachineProductConfiguration, oPriceListItemBundle.Id, NULL, oBundleProduct.Id, NULL, NULL, 1, 1, 2, 'Product/Service', oBillingPreference.Id, 'Monthly', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 100, 2);
            oMachineLineItemBundle.Apttus_Config2__PricingStatus__c = 'Completed';
            lineItemList.add(oMachineLineItemBundle);

            Apttus_Config2__LineItem__c oMachineLineItemOption = APTS_TestDataFactory.createLineItem(oMachineProductConfiguration, oPriceListItemOption.Id, NULL, oOptionProduct.Id, NULL, NULL, 1, 1, 2, 'Option', oBillingPreference.Id, 'Monthly', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 100, 2);
            oMachineLineItemOption.Apttus_Config2__PricingStatus__c = 'Completed';
            lineItemList.add(oMachineLineItemOption);

            Apttus_Config2__LineItem__c oAmendedLineItemBundle = APTS_TestDataFactory.createLineItem(oAmendedProductConfiguration, oPriceListItemBundle.Id, NULL, oBundleProduct.Id, NULL, NULL, 1, 1, 2, 'Product/Service', oBillingPreference.Id, 'Monthly', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 100, 2);
            oAmendedLineItemBundle.Apttus_Config2__PricingStatus__c = 'Completed';
            oAmendedLineItemBundle.Apttus_Config2__LineStatus__c = 'Amended';
            lineItemList.add(oAmendedLineItemBundle);

            Apttus_Config2__LineItem__c oAmendedLineItemOption = APTS_TestDataFactory.createLineItem(oAmendedProductConfiguration, oPriceListItemOption.Id, NULL, oBundleProduct.Id, oOptionProduct.Id, NULL, 1, 1, 2, 'Option', oBillingPreference.Id, 'Monthly', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 100, 2);
            oAmendedLineItemOption.Apttus_Config2__PricingStatus__c = 'Completed';
            oAmendedLineItemOption.Apttus_Config2__LineStatus__c = 'New';
            oAmendedLineItemOption.Apttus_Config2__LineType__c = OPTION;
            oAmendedLineItemOption.Apttus_Config2__ProductOptionId__c = oProductOptionComponentMachine.Id;
            lineItemList.add(oAmendedLineItemOption);

            Apttus_Config2__LineItem__c oCancelledLineItemBundle = APTS_TestDataFactory.createLineItem(oCancelledProductConfiguration, oPriceListItemBundle.Id, NULL, oBundleProduct.Id, NULL, NULL, 1, 1, 2, 'Product/Service', oBillingPreference.Id, 'Monthly', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 100, 2);
            oCancelledLineItemBundle.Apttus_Config2__PricingStatus__c = 'Completed';
            oCancelledLineItemBundle.Apttus_Config2__LineStatus__c = 'Amended';
            lineItemList.add(oCancelledLineItemBundle);

            Apttus_Config2__LineItem__c oCancelledLineItemOption = APTS_TestDataFactory.createLineItem(oCancelledProductConfiguration, oPriceListItemOption.Id, NULL, oBundleProduct.Id, oOptionProduct.Id, NULL, 1, 1, 2, 'Option', oBillingPreference.Id, 'Monthly', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 100, 2);
            oCancelledLineItemOption.Apttus_Config2__PricingStatus__c = 'Completed';
            oCancelledLineItemOption.Apttus_Config2__LineStatus__c = 'New';
            oCancelledLineItemOption.Apttus_Config2__LineType__c = OPTION;
            oCancelledLineItemOption.Apttus_Config2__ProductOptionId__c = oProductOptionComponentMachine.Id;
            lineItemList.add(oCancelledLineItemOption);
            Database.insert(lineItemList);


            List<Apttus__AgreementLineItem__c> agreementLineItemList = new List<Apttus__AgreementLineItem__c>();
            Apttus__AgreementLineItem__c oAgreementLineItem = APTS_TestDataFactory.createAgreementLineItem(oStandaloneProduct.Id, oAgreement.Id, oAccount.Id, oPriceListItemStandalone.Id);
            agreementLineItemList.add(oAgreementLineItem);
            Apttus__AgreementLineItem__c oAgreementLineItemBundle = APTS_TestDataFactory.createAgreementLineItem(oBundleProduct.Id, oAgreementCM.Id, oAccount.Id, oPriceListItemBundle.Id);
            agreementLineItemList.add(oAgreementLineItemBundle);

            Apttus__AgreementLineItem__c oAgreementLineItemOption = APTS_TestDataFactory.createAgreementLineItem(oBundleProduct.Id, oAgreementCM.Id, oAccount.Id, oPriceListItemOption.Id);
            oAgreementLineItemOption.Apttus_CMConfig__OptionId__c = oOptionProduct.Id;
            oAgreementLineItemOption.Apttus_CMConfig__IsPrimaryLine__c = true;
            oAgreementLineItemOption.Apttus_CMConfig__LineType__c = 'Option';
            oAgreementLineItemOption.Apttus_CMConfig__ProductOptionId__c = oProductOptionComponentMachine.Id;
            agreementLineItemList.add(oAgreementLineItemOption);

            Apttus__AgreementLineItem__c oAmendedAgreementLineItemBundle = APTS_TestDataFactory.createAgreementLineItem(oBundleProduct.Id, oAmendedAgreement.Id, oAccount.Id, oPriceListItemBundle.Id);
            oAmendedAgreementLineItemBundle.Apttus_CMConfig__LineStatus__c = 'Amended';
            oAmendedAgreementLineItemBundle.Apttus_CMConfig__HasOptions__c = true;
            oAmendedAgreementLineItemBundle.Apttus_CMConfig__DerivedFromId__c = oAmendedLineItemBundle.Id;
            agreementLineItemList.add(oAmendedAgreementLineItemBundle);

            Apttus__AgreementLineItem__c oAmendedAgreementLineItemOption = APTS_TestDataFactory.createAgreementLineItem(oBundleProduct.Id, oAmendedAgreement.Id, oAccount.Id, oPriceListItemOption.Id);
            oAmendedAgreementLineItemOption.Apttus_CMConfig__OptionId__c = oOptionProduct.Id;
            oAmendedAgreementLineItemOption.Apttus_CMConfig__IsPrimaryLine__c = true;
            oAmendedAgreementLineItemOption.Apttus_CMConfig__LineType__c = 'Option';
            oAmendedAgreementLineItemOption.Apttus_CMConfig__LineStatus__c = 'New';
            oAmendedAgreementLineItemOption.Apttus_CMConfig__DerivedFromId__c = oAmendedLineItemOption.Id;
            oAmendedAgreementLineItemOption.Apttus_CMConfig__ProductOptionId__c = oProductOptionComponentMachine.Id;
            agreementLineItemList.add(oAmendedAgreementLineItemOption);

            Apttus__AgreementLineItem__c oCancelledAgreementLineItemBundle = APTS_TestDataFactory.createAgreementLineItem(oBundleProduct.Id, oCancelledAgreement.Id, oAccount.Id, oPriceListItemBundle.Id);
            oCancelledAgreementLineItemBundle.Apttus_CMConfig__LineStatus__c = 'Cancelled';
            oCancelledAgreementLineItemBundle.Apttus_CMConfig__HasOptions__c = true;
            oCancelledAgreementLineItemBundle.Apttus_CMConfig__DerivedFromId__c = oCancelledLineItemBundle.Id;
            agreementLineItemList.add(oCancelledAgreementLineItemBundle);

            Apttus__AgreementLineItem__c oCancelledAgreementLineItemOption = APTS_TestDataFactory.createAgreementLineItem(oBundleProduct.Id, oCancelledAgreement.Id, oAccount.Id, oPriceListItemOption.Id);
            oCancelledAgreementLineItemOption.Apttus_CMConfig__OptionId__c = oOptionProduct.Id;
            oCancelledAgreementLineItemOption.Apttus_CMConfig__IsPrimaryLine__c = true;
            oCancelledAgreementLineItemOption.Apttus_CMConfig__LineType__c = 'Option';
            oCancelledAgreementLineItemOption.Apttus_CMConfig__LineStatus__c = 'Cancelled';
            oCancelledAgreementLineItemOption.Apttus_CMConfig__DerivedFromId__c = oCancelledLineItemOption.Id;
            oCancelledAgreementLineItemOption.Apttus_CMConfig__ProductOptionId__c = oProductOptionComponentMachine.Id;
            agreementLineItemList.add(oCancelledAgreementLineItemOption);

            Apttus__AgreementLineItem__c oAgreementLineItemCM = APTS_TestDataFactory.createAgreementLineItem(oStandaloneProduct.Id, oAgreementCM.Id, oAccount.Id, oPriceListItemStandalone.Id);
            agreementLineItemList.add(oAgreementLineItemCM);
            Database.insert(agreementLineItemList);
            //START : changed by Balasahnthi for Defect # 22391 - Too many soql  error during more than line items in the cart
            List<APTS_Billing_Settings__c> bsList = new List<APTS_Billing_Settings__c>();
            APTS_Billing_Settings__c oBillingSettingsMachine = APTS_TestDataFactory.createBillingSettings(oAgreement.Id,oAccount.Id,oAccount.Apttus_Config2__BillingPreferenceId__c,oAccount.APTS_Payment_Method__c,oAccount.Apttus_Config2__PaymentTermId__c,'Machine');
            bsList.add(oBillingSettingsMachine);
            APTS_Billing_Settings__c oBillingSettingsIngredient = APTS_TestDataFactory.createBillingSettings(oAgreement.Id,oAccount.Id,oAccount.Apttus_Config2__BillingPreferenceId__c,oAccount.APTS_Payment_Method__c,oAccount.Apttus_Config2__PaymentTermId__c,'Ingredients');
            bsList.add(oBillingSettingsIngredient);
            Database.insert(bsList);
            // END: changed by Balasahnthi for Defect # 22391 - Too many soql  error during more than line items in the cart

            List<APTS_Agreement_PO_Details__c> poDetailsList = new List<APTS_Agreement_PO_Details__c>();
            APTS_Agreement_PO_Details__c machinePODetail = APTS_TestDataFactory.createAgreementPOdetails(oAgreement.Id);
            poDetailsList.add(machinePODetail);

            APTS_Agreement_PO_Details__c servicePODetail = APTS_TestDataFactory.createAgreementPOdetails(oAgreement.Id);
            servicePODetail.APTS_PO_Category__c = 'Services';
            poDetailsList.add(servicePODetail);
            Database.insert(poDetailsList);

        }
    }

    //Create Agreement and Agreement Line Items
    @TestVisible private static void createAndConfigureAgreementOnSecondAccount(User testuser) {

        Contact oContact = getContact();
        Account oAccount = getAccount('JDESecondTestAccount');

        Product2 oStandaloneProduct = getStandaloneProduct();
        Product2 oBundleProduct = getBundleProduct();
        Product2 oOptionProduct = getOptionProduct();
        Apttus_Config2__BillingPreference__c oBillingPreference = getBillingPreference();

        Apttus_Config2__PriceList__c oPriceList = getPriceList();

        Apttus_Config2__PriceListItem__c oPriceListItemStandalone = getPriceListItem(oStandaloneProduct.Id);
        Apttus_Config2__PriceListItem__c oPriceListItemBundle = getPriceListItem(oBundleProduct.Id);
        Apttus_Config2__PriceListItem__c oPriceListItemOption = getPriceListItem(oOptionProduct.Id);

        Apttus_Config2__ProductOptionComponent__c oProductOptionComponentMachine = getProductOptionComponent('Machine');

        System.runAs(testuser) {
            Apttus__APTS_Agreement__c oAgreement = APTS_TestDataFactory.createAgreement(oContact.Id, oPriceList.Id, oAccount.Id, STANDARD_DEAL, 'Agreement second account');
            oAgreement.Apttus__Status_Category__c = IN_EFFECT;
            oAgreement.Apttus__Status__c = ACTIVATED;
            oAgreement.Apttus__Contract_End_Date__c = Date.Today().addDays(365);
            Database.insert(oAgreement);

            Apttus_Config2__ProductConfiguration__c oMachineProductConfiguration = APTS_TestDataFactory.createProductConfig(oAgreement);
            oMachineProductConfiguration.Apttus_Config2__Status__c = 'Finalized';
            Database.insert(oMachineProductConfiguration);

            List<Apttus_Config2__LineItem__c> lineItemList = new List<Apttus_Config2__LineItem__c>();
            Apttus_Config2__LineItem__c oMachineLineItemBundle = APTS_TestDataFactory.createLineItem(oMachineProductConfiguration, oPriceListItemBundle.Id, NULL, oBundleProduct.Id, NULL, NULL, 1, 1, 2, 'Product/Service', oBillingPreference.Id, 'Monthly', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 100, 2);
            oMachineLineItemBundle.Apttus_Config2__PricingStatus__c = 'Completed';
            lineItemList.add(oMachineLineItemBundle);

            Apttus_Config2__LineItem__c oMachineLineItemOption = APTS_TestDataFactory.createLineItem(oMachineProductConfiguration, oPriceListItemOption.Id, NULL, oOptionProduct.Id, NULL, NULL, 1, 1, 2, 'Option', oBillingPreference.Id, 'Monthly', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 100, 2);
            oMachineLineItemOption.Apttus_Config2__PricingStatus__c = 'Completed';
            lineItemList.add(oMachineLineItemOption);
            Database.insert(lineItemList);

            List<Apttus__AgreementLineItem__c> agreementLineItemList = new List<Apttus__AgreementLineItem__c>();
            Apttus__AgreementLineItem__c oAgreementLineItemBundle = APTS_TestDataFactory.createAgreementLineItem(oBundleProduct.Id, oAgreement.Id, oAccount.Id, oPriceListItemBundle.Id);
            agreementLineItemList.add(oAgreementLineItemBundle);

            Apttus__AgreementLineItem__c oAgreementLineItemOption = APTS_TestDataFactory.createAgreementLineItem(oBundleProduct.Id, oAgreement.Id, oAccount.Id, oPriceListItemOption.Id);
            oAgreementLineItemOption.Apttus_CMConfig__OptionId__c = oOptionProduct.Id;
            oAgreementLineItemOption.Apttus_CMConfig__IsPrimaryLine__c = true;
            oAgreementLineItemOption.Apttus_CMConfig__LineType__c = 'Option';
            oAgreementLineItemOption.Apttus_CMConfig__ProductOptionId__c = oProductOptionComponentMachine.Id;
            agreementLineItemList.add(oAgreementLineItemOption);
            Database.insert(agreementLineItemList);

            APTS_Billing_Settings__c oBillingSettings = APTS_TestDataFactory.createBillingSettings(oAgreement.Id);
            Database.insert(oBillingSettings);

            List<APTS_Agreement_PO_Details__c> poDetailsList = new List<APTS_Agreement_PO_Details__c>();
            APTS_Agreement_PO_Details__c machinePODetail = APTS_TestDataFactory.createAgreementPOdetails(oAgreement.Id);
            poDetailsList.add(machinePODetail);

            APTS_Agreement_PO_Details__c servicePODetail = APTS_TestDataFactory.createAgreementPOdetails(oAgreement.Id);
            servicePODetail.APTS_PO_Category__c = 'Services';
            poDetailsList.add(servicePODetail);
            Database.insert(poDetailsList);

        }
    }

    //Create Order and Order Line Items
    @TestVisible private static void createAndConfigureOrder(User testuser) {

        Contact oContact = getContact();
        Account oAccount = getAccount();
        Opportunity oOpportunity = getOpportunity();

        Product2 oStandaloneProduct = getStandaloneProduct();
        Product2 oBundleProduct = getBundleProduct();
        Product2 oOptionProduct = getOptionProduct();
        //v101++<<
        Product2 oAllInCvrgProduct = getProductByName('ALL-IN COVERAGE');
        Product2 oBasicCvrgProduct = getProductByName('BASIC COVERAGE');
        //v100++>>
        Apttus_Config2__BillingPreference__c oBillingPreference = getBillingPreference();

        Apttus_Config2__PriceList__c oPriceList = getPriceList();
        Apttus_Config2__PriceListItem__c oPriceListItemStandalone = getPriceListItem(oStandaloneProduct.Id);
        Apttus_Config2__PriceListItem__c oPriceListItemBundle = getPriceListItem(oBundleProduct.Id);
        Apttus_Config2__PriceListItem__c oPriceListItemOption = getPriceListItem(oOptionProduct.Id);
        Apttus_Config2__ProductOptionComponent__c oProductOptionComponentMachine = getProductOptionComponent('Machine');
        Apttus_Config2__ProductOptionComponent__c oProductOptionComponentService = getProductOptionComponent('Service');
        
        System.runAs(testuser) {
            
            Apttus__APTS_Agreement__c oAgreement = APTS_TestDataFactory.createAgreement(oContact.Id, oPriceList.Id, oAccount.Id, STANDARD_DEAL, 'Agreement');
            oAgreement.Apttus__Status_Category__c = IN_EFFECT;
            oAgreement.Apttus__Status__c = ACTIVATED;
            oAgreement.Apttus__Contract_End_Date__c = Date.Today().addDays(365);
            oAgreement.APTS_Bill_to_Party_Ingredients__c = oAgreement.Apttus__Account__c;
            oAgreement.APTS_Bill_to_Party_MachServ__c = oAgreement.Apttus__Account__c;
            oAgreement.APTS_Payer_Ingredients__c = oAgreement.Apttus__Account__c;
            oAgreement.APTS_Payer_Machines_Services__c = oAgreement.Apttus__Account__c;
            oAgreement.Apttus__Auto_Renewal__c = true;
            Database.insert(oAgreement);

            Apttus_Config2__OrderSystemProperties__c oOrderSystemProperties = APTS_TestDataFactory.getOrderSystemProperties();
            Database.insert(oOrderSystemProperties);

            List<Apttus_Config2__Order__c> orderList = new List<Apttus_Config2__Order__c>();
            Apttus_Config2__Order__c oStandardOrder = APTS_TestDataFactory.createOrder(oAccount.Id, oPriceList.Id, oContact.Id);
            oStandardOrder.Apttus_Config2__Status__c = ACTIVATED;
            oStandardOrder.Apttus_Config2__Description__c = 'StandardOrder';
            oStandardOrder.Apttus_Config2__PONumber__c = '1234';
            oStandardOrder.APTS_Order_Sub_Type__c = STANDARD_ORDER;
            oStandardOrder.RecordTypeId = Schema.SObjectType.Apttus_Config2__Order__c.getRecordTypeInfosByName().get(STANDARD_ORDER).getRecordTypeId();
            orderList.add(oStandardOrder);

            Apttus_Config2__Order__c oStandardOrder1 = APTS_TestDataFactory.createOrder(oAccount.Id, oPriceList.Id, oContact.Id);
            oStandardOrder1.Apttus_Config2__Status__c = ACTIVATED;
            oStandardOrder1.Apttus_Config2__Description__c = 'StandardOrder1';
            oStandardOrder.APTS_Order_Sub_Type__c = STANDARD_ORDER;
            oStandardOrder1.Apttus_Config2__OrderStartDate__c = Date.today().addDays(1);
            oStandardOrder1.RecordTypeId = Schema.SObjectType.Apttus_Config2__Order__c.getRecordTypeInfosByName().get(STANDARD_ORDER).getRecordTypeId();
            orderList.add(oStandardOrder1);
            /*
                        Apttus_Config2__Order__c oStandardOrder2 = APTS_TestDataFactory.createOrder(oAccount.Id, oPriceList.Id, oContact.Id);
                        oStandardOrder.Apttus_Config2__Status__c = ACTIVATED;
                        oStandardOrder.Apttus_Config2__Description__c = 'StandardOrder2';
                        oStandardOrder.Apttus_Config2__PONumber__c = '5555';
                        database.insert(oStandardOrder2);
            */
            Apttus_Config2__Order__c oStandardOrderBeingAmended = APTS_TestDataFactory.createOrder(oAccount.Id, oPriceList.Id, oContact.Id);
            oStandardOrderBeingAmended.Apttus_Config2__Status__c = BEINGAMENDED;
            oStandardOrderBeingAmended.Apttus_Config2__Description__c = 'StandardOrderBeingAmended';
            oStandardOrderBeingAmended.RecordTypeId = Schema.SObjectType.Apttus_Config2__Order__c.getRecordTypeInfosByName().get(STANDARD_ORDER).getRecordTypeId();
            orderList.add(oStandardOrderBeingAmended);

            Apttus_Config2__Order__c oMachineOrder = APTS_TestDataFactory.createOrder(oAccount.Id, oPriceList.Id, oContact.Id);
            oMachineOrder.Apttus_Config2__Status__c = ACTIVATED;
            oMachineOrder.Apttus_Config2__Description__c = 'MachineOrder';
            oMachineOrder.APTS_Order_Sub_Type__c = INSTALLATION;
            oMachineOrder.APTS_SAP_OrderType__c = 'XA13';
            oMachineOrder.Apttus_Config2__PONumber__c = '123456789';
            oMachineOrder.RecordTypeId = Schema.SObjectType.Apttus_Config2__Order__c.getRecordTypeInfosByName().get(MACHINE_ORDER).getRecordTypeId();
            orderList.add(oMachineOrder);
            Database.insert(orderList);

            system.debug('TestFacade :: OrderList :: ' + orderList);

            //Creating physical Asset Object
            List<PhysicalAsset__c> physicalAssetList = new List<PhysicalAsset__c>();
            PhysicalAsset__c oPhysicalAsset = APTS_TestDataFactory.createPhysicalAsset();
            physicalAssetList.add(oPhysicalAsset);
            PhysicalAsset__c oPhysicalAsset1 = APTS_TestDataFactory.createPhysicalAsset();
            physicalAssetList.add(oPhysicalAsset1);
            PhysicalAsset__c oPhysicalAsset2 = APTS_TestDataFactory.createPhysicalAsset();
            physicalAssetList.add(oPhysicalAsset2);
            PhysicalAsset__c oPhysicalAsset3 = APTS_TestDataFactory.createPhysicalAsset();
            physicalAssetList.add(oPhysicalAsset3);
            PhysicalAsset__c oPhysicalAsset4 = APTS_TestDataFactory.createPhysicalAsset();
            physicalAssetList.add(oPhysicalAsset4);
            PhysicalAsset__c oPhysicalAsset5 = APTS_TestDataFactory.createPhysicalAsset();
            physicalAssetList.add(oPhysicalAsset5);
            Database.insert(physicalAssetList);
            //creating agreementPODetails

            List<Apttus_Config2__ProductConfiguration__c> productConfigurationList = new List<Apttus_Config2__ProductConfiguration__c>();
            Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestDataFactory.createProductConfig(oStandardOrder);
            oProductConfiguration.APTS_Flow__c = NGSTANDARD_ORDER;
            oProductConfiguration.Apttus_Config2__Status__c = 'Finalized';
            productConfigurationList.add(oProductConfiguration);

            Apttus_Config2__ProductConfiguration__c oMachineProductConfiguration = APTS_TestDataFactory.createProductConfig(oMachineOrder);
            oMachineProductConfiguration.APTS_Flow__c = NGMACHINE_ORDER;
            oMachineProductConfiguration.Apttus_Config2__Status__c = 'Finalized';
            productConfigurationList.add(oMachineProductConfiguration);
            Database.insert(productConfigurationList);

            /*Apttus_Config2__TempObject__c oTempObject = new Apttus_Config2__TempObject__c();
            oTempObject.Apttus_Config2__ConfigurationId__c = oProductConfiguration.Id;
            Database.insert(oTempObject);*/

            List<Apttus_Config2__LineItem__c> lineItemList = new List<Apttus_Config2__LineItem__c>();
            Apttus_Config2__LineItem__c oLineItemStandalone = APTS_TestDataFactory.createLineItem(oProductConfiguration, oPriceListItemStandalone.Id, NULL, oStandaloneProduct.Id, NULL, NULL, 1, 1, 1, 'Product/Service', oBillingPreference.Id, 'Monthly', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 100, 2);
            oLineItemStandalone.Apttus_Config2__PricingStatus__c = 'Completed';
            oLineItemStandalone.APTS_Requested_Delivery_Date__c = System.today();
            lineItemList.add(oLineItemStandalone);

            Apttus_Config2__LineItem__c oLineItemBundle = APTS_TestDataFactory.createLineItem(oProductConfiguration, oPriceListItemBundle.Id, NULL, oBundleProduct.Id, NULL, NULL, 1, 1, 1, 'Product/Service', oBillingPreference.Id, 'Monthly', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 100, 2);
            oLineItemBundle.Apttus_Config2__PricingStatus__c = 'Completed';
            lineItemList.add(oLineItemBundle);
            //createLineItem(Apttus_Config2__ProductConfiguration__c ProdConfig, Id PriceListItemId, Id LocationId, Id ProductId, Id OptionId, Id AssetLineItemId, Decimal dPrimaryLineNo, Decimal dLineNumber, Decimal dItemSequence, String sLineType, Id BillPreferenceId, String sBillFrequency, String sBillingRule, String sPriceType, String sPriceMethod, String sPriceUOM, Decimal dBasePrice, Decimal quantity)
            Apttus_Config2__LineItem__c oLineItemOption = APTS_TestDataFactory.createLineItem(oProductConfiguration, oPriceListItemOption.Id, NULL, oBundleProduct.Id, oOptionProduct.Id, NULL, 1, 1, 1, 'Option', oBillingPreference.Id, 'Monthly', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 100, 2);
            oLineItemOption.Apttus_Config2__PricingStatus__c = 'Completed';
            lineItemList.add(oLineItemOption);
           /*  List<Apttus__AgreementLineItem__c> lstAgreementLI = getAgreementLineItem(oAgreement.id);
            lstAgreementLI[0].Apttus_CMConfig__SellingTerm__c = 12;
            Database.update(lstAgreementLI[0], false); */
            Apttus_Config2__LineItem__c oLineItemAllInCvrg = APTS_TestDataFactory.createLineItem(oProductConfiguration, oPriceListItemBundle.Id, NULL, oBundleProduct.Id, NULL, NULL, 1, 1, 1, 'Product/Service', oBillingPreference.Id, 'Monthly', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 100, 2);
            oLineItemAllInCvrg.Apttus_Config2__PricingStatus__c = 'Completed';
            oLineItemAllInCvrg.Apttus_Config2__ProductOptionId__c = oProductOptionComponentService.Id;
            oLineItemAllInCvrg.Apttus_Config2__OptionId__c = oAllInCvrgProduct.Id;
            oLineItemAllInCvrg.Apttus_Config2__ChargeType__c = system.label.APTS_Service_Fee;
           // oLineItemAllInCvrg.APTS_Agreement_Line_Item__c = lstAgreementLI[0].Id;            
            lineItemList.add(oLineItemAllInCvrg);

            Apttus_Config2__LineItem__c oLineItemBasicCvrg = APTS_TestDataFactory.createLineItem(oProductConfiguration, oPriceListItemBundle.Id, NULL, oBundleProduct.Id, NULL, NULL, 1, 1, 1, 'Product/Service', oBillingPreference.Id, 'Monthly', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 100, 2);
            oLineItemBasicCvrg.Apttus_Config2__PricingStatus__c = 'Completed';
            oLineItemBasicCvrg.Apttus_Config2__ProductOptionId__c = oProductOptionComponentService.Id;
            oLineItemBasicCvrg.Apttus_Config2__OptionId__c = oBasicCvrgProduct.Id;
            lineItemList.add(oLineItemBasicCvrg);

            Apttus_Config2__LineItem__c oMachineLineItemBundle = APTS_TestDataFactory.createLineItem(oMachineProductConfiguration, oPriceListItemBundle.Id, NULL, oBundleProduct.Id, NULL, NULL, 1, 1, 1, 'Product/Service', oBillingPreference.Id, 'Monthly', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 100, 2);
            oMachineLineItemBundle.Apttus_Config2__PricingStatus__c = 'Completed';
            //oMachineLineItemBundle.Apttus_Config2__ProductOptionId__c = oProductOptionComponentMachine.Id;
            lineItemList.add(oMachineLineItemBundle);

            Apttus_Config2__LineItem__c oMachineLineItemOption = APTS_TestDataFactory.createLineItem(oMachineProductConfiguration, oPriceListItemOption.Id, NULL, oBundleProduct.Id, oOptionProduct.Id, NULL, 1, 1, 1, 'Option', oBillingPreference.Id, 'Monthly', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 100, 2);
            oMachineLineItemOption.Apttus_Config2__PricingStatus__c = 'Completed';
            oMachineLineItemOption.Apttus_Config2__LineType__c = OPTION;
            oMachineLineItemOption.Apttus_Config2__ProductOptionId__c = oProductOptionComponentMachine.Id;
            lineItemList.add(oMachineLineItemOption);
            Database.insert(lineItemList);

            List<Apttus_Config2__ProductAttributeValue__c> productAttributeValueList = new List<Apttus_Config2__ProductAttributeValue__c>();
            Apttus_Config2__ProductAttributeValue__c oProductAttributeValueCOCchk = new Apttus_Config2__ProductAttributeValue__c(Apttus_Config2__LineItemId__c = oLineItemBasicCvrg.Id);
            oProductAttributeValueCOCchk.APTS_Call_Out_Coverage_chk__c = 'Yes';
            oProductAttributeValueCOCchk.APTS_Type_of_Consumption__c = 'Both';
            productAttributeValueList.add(oProductAttributeValueCOCchk);
            Apttus_Config2__ProductAttributeValue__c oProductAttributeValueLCchk = new Apttus_Config2__ProductAttributeValue__c(Apttus_Config2__LineItemId__c = oLineItemAllInCvrg.Id);
            oProductAttributeValueLCchk.APTS_Labour_Coverage_chk__c = 'Yes';
            oProductAttributeValueLCchk.APTS_Type_of_Consumption__c = 'Both';
            productAttributeValueList.add(oProductAttributeValueLCchk);
            Apttus_Config2__ProductAttributeValue__c oProductAttributeValueSPCchk = new Apttus_Config2__ProductAttributeValue__c(Apttus_Config2__LineItemId__c = oLineItemAllInCvrg.Id);
            oProductAttributeValueSPCchk.APTS_Spare_Parts_Coverage_chk__c  = 'Yes';
            oProductAttributeValueSPCchk.APTS_Type_of_Consumption__c = 'Both';
            oProductAttributeValueSPCchk.APTS_Refurbished__c = 'Yes';
            productAttributeValueList.add(oProductAttributeValueSPCchk);
            Database.insert(productAttributeValueList);

            APTS_Order_LSP_Details__c oLSPDetails = APTS_TestDataFactory.createLSPDetails();
            Database.insert(oLSPDetails);

            //Adding Machine Assets
            List<Apttus_Config2__AssetLineItem__c> assetLineItemList = new List<Apttus_Config2__AssetLineItem__c>();
            Apttus_Config2__AssetLineItem__c oAssetLineItemStandalone = APTS_TestDataFactory.createAssetLineItem(oStandardOrder, oPriceListItemStandalone.Id, null, oStandaloneProduct.Id, null, 1, 1, 'Product/Service', oBillingPreference.Id, 'Monthly', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 100.0, 10.0);
            oAssetLineItemStandalone.APTS_Physical_Asset__c = oPhysicalAsset.Id;
            oAssetLineItemStandalone.APTS_Order_LSP_Detail__c = oLSPDetails.Id;
            oAssetLineItemStandalone.Apttus_Config2__AssetStatus__c = ACTIVATED;
            assetLineItemList.add(oAssetLineItemStandalone);

            Apttus_Config2__AssetLineItem__c oAssetLineItemStandalone1 = APTS_TestDataFactory.createAssetLineItem(oStandardOrder1, oPriceListItemStandalone.Id, null, oStandaloneProduct.Id, null, 1, 1, 'Product/Service', oBillingPreference.Id, 'Monthly', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 100.0, 10.0);
            oAssetLineItemStandalone1.APTS_Physical_Asset__c = oPhysicalAsset1.Id;
            oAssetLineItemStandalone1.APTS_Order_LSP_Detail__c = oLSPDetails.Id;
            oAssetLineItemStandalone1.Apttus_Config2__AssetStatus__c = ACTIVATED;
            assetLineItemList.add(oAssetLineItemStandalone1);

            Apttus_Config2__AssetLineItem__c oAssetLineItemBundle = APTS_TestDataFactory.createAssetLineItem(oStandardOrder, oPriceListItemBundle.Id, null, oBundleProduct.Id, null, 1, 1, 'Product/Service', oBillingPreference.Id, 'Monthly', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 100.0, 10.0);
            oAssetLineItemBundle.APTS_Physical_Asset__c = oPhysicalAsset2.Id;
            oAssetLineItemBundle.APTS_Order_LSP_Detail__c = oLSPDetails.Id;
            oAssetLineItemBundle.Apttus_Config2__AssetStatus__c = ACTIVATED;
            assetLineItemList.add(oAssetLineItemBundle);

            Apttus_Config2__AssetLineItem__c oAssetLineItemOption = APTS_TestDataFactory.createAssetLineItem(oStandardOrder, oPriceListItemOption.Id, null, oOptionProduct.Id, null, 1, 1, 'Option', oBillingPreference.Id, 'Monthly', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 100.0, 10.0);
            oAssetLineItemOption.APTS_Physical_Asset__c = oPhysicalAsset3.Id;
            oAssetLineItemOption.APTS_Order_LSP_Detail__c = oLSPDetails.Id;
            oAssetLineItemOption.Apttus_Config2__AssetStatus__c = ACTIVATED;
            assetLineItemList.add(oAssetLineItemOption);

            Apttus_Config2__AssetLineItem__c oMachineAssetLineItemBundle = APTS_TestDataFactory.createAssetLineItem(oMachineOrder, oPriceListItemBundle.Id, null, oBundleProduct.Id, null, 1, 1, 'Product/Service', oBillingPreference.Id, 'Monthly', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 100.0, 10.0);
            oMachineAssetLineItemBundle.APTS_Physical_Asset__c = oPhysicalAsset4.Id;
            oMachineAssetLineItemBundle.APTS_Order_LSP_Detail__c = oLSPDetails.Id;
            oMachineAssetLineItemBundle.Apttus_Config2__AssetStatus__c = ACTIVATED;
            assetLineItemList.add(oMachineAssetLineItemBundle);

            Apttus_Config2__AssetLineItem__c oMachineAssetLineItemOption = APTS_TestDataFactory.createAssetLineItem(oMachineOrder, oPriceListItemOption.Id, null, oOptionProduct.Id, null, 1, 1, 'Option', oBillingPreference.Id, 'Monthly', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 100.0, 10.0);
            oMachineAssetLineItemOption.APTS_Physical_Asset__c = oPhysicalAsset5.Id;
            oMachineAssetLineItemOption.APTS_Order_LSP_Detail__c = oLSPDetails.Id;
            oMachineAssetLineItemOption.Apttus_Config2__AssetStatus__c = ACTIVATED;
            oMachineAssetLineItemOption.APTS_SourceSystem__c = 'BEC';
            assetLineItemList.add(oMachineAssetLineItemOption);
            Database.insert(assetLineItemList);

            Apttus_Config2__ProductAttributeValue__c prdAttValue = new Apttus_Config2__ProductAttributeValue__c();
            prdAttValue.APTS_Type_of_Consumption__c = 'Both';
            prdAttValue.APTS_Number_of_months__c = '9';
            prdAttValue.APTS_WTS_Changed_By__c = 'Customer';
            prdAttValue.APTS_Refurbished__c = 'Yes';
            Database.insert(prdAttValue, false);

            List<Apttus_Config2__OrderLineItem__c> orderLineItemList = new List<Apttus_Config2__OrderLineItem__c>();
            Apttus_Config2__OrderLineItem__c oOrderLineItemStandalone = APTS_TestDataFactory.createOrderLineItem(oStandardOrder, oPriceListItemStandalone.Id, null, oStandaloneProduct.Id, null, oAssetLineItemStandalone.Id, null, 1, 1, 1, 'Product/Service', oBillingPreference.Id, 'One Time', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 100.0, 10.0);
            oOrderLineItemStandalone.Apttus_Config2__FulfilledQuantity__c = 10;
            oOrderLineItemStandalone.Apttus_Config2__IsPrimaryLine__c = true;
            oOrderLineItemStandalone.APTS_Item_Relevant_for_SAP__c = true;
            orderLineItemList.add(oOrderLineItemStandalone);

            Apttus_Config2__OrderLineItem__c oOrderLineItemBundle = APTS_TestDataFactory.createOrderLineItem(oStandardOrder, oPriceListItemBundle.Id, null, oBundleProduct.Id, null, oAssetLineItemBundle.Id, null, 1, 1, 1, 'Product/Service', oBillingPreference.Id, 'One Time', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 200.0, 20.0);
            oOrderLineItemBundle.Apttus_Config2__FulfilledQuantity__c = 20;
            oOrderLineItemBundle.Apttus_Config2__IsPrimaryLine__c = true;
            oOrderLineItemBundle.APTS_Item_Relevant_for_SAP__c = true;
            oOrderLineItemBundle.Apttus_Config2__AttributeValueId__c = prdAttValue.Id;
            oOrderLineItemBundle.APTS_Order_LSP_Detail__c = oLSPDetails.Id;
            oOrderLineItemBundle.APTS_Material_Availability_Date__c = Date.today();
            oOrderLineItemBundle.Apttus_Config2__LineType__c = 'Product/Service';
            oOrderLineItemBundle.APTS_Type_of_Contract__c = 'Sales';
            oOrderLineItemBundle.Apttus_Config2__ChargeType__c = 'Sales Price';
            oOrderLineItemBundle.Apttus_CMConfig__AgreementId__c = oAgreement.Id;
            orderLineItemList.add(oOrderLineItemBundle);

            Apttus_Config2__OrderLineItem__c oOrderLineItemOption = APTS_TestDataFactory.createOrderLineItem(oStandardOrder, oPriceListItemOption.Id, null, oOptionProduct.Id, null, oAssetLineItemOption.Id, null, 1, 1, 1, 'Option', oBillingPreference.Id, 'One Time', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 200.0, 20.0);
            oOrderLineItemOption.Apttus_Config2__FulfilledQuantity__c = 20;
            oOrderLineItemOption.Apttus_Config2__IsPrimaryLine__c = true;
            oOrderLineItemOption.APTS_Item_Relevant_for_SAP__c = true;
            oOrderLineItemOption.Apttus_CMConfig__AgreementId__c = oAgreement.Id;
            orderLineItemList.add(oOrderLineItemOption);

            Apttus_Config2__OrderLineItem__c oOrder1LineItemStandalone = APTS_TestDataFactory.createOrderLineItem(oStandardOrder1, oPriceListItemStandalone.Id, null, oStandaloneProduct.Id, null, oAssetLineItemStandalone.Id, null, 1, 1, 1, 'Product/Service', oBillingPreference.Id, 'One Time', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 100.0, 10.0);
            oOrder1LineItemStandalone.Apttus_Config2__FulfilledQuantity__c = 10;
            oOrder1LineItemStandalone.Apttus_Config2__IsPrimaryLine__c = true;
            oOrder1LineItemStandalone.APTS_Item_Relevant_for_SAP__c = true;
            orderLineItemList.add(oOrder1LineItemStandalone);

            Apttus_Config2__OrderLineItem__c oMachineOrderLineItemBundle = APTS_TestDataFactory.createOrderLineItem(oMachineOrder, oPriceListItemBundle.Id, null, oBundleProduct.Id, null, oMachineAssetLineItemBundle.Id, null, 1, 1, 1, 'Product/Service', oBillingPreference.Id, 'One Time', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 200.0, 20.0);
            oMachineOrderLineItemBundle.Apttus_Config2__FulfilledQuantity__c = 20;
            oMachineOrderLineItemBundle.Apttus_Config2__IsPrimaryLine__c = true;
            oMachineOrderLineItemBundle.APTS_Item_Relevant_for_SAP__c = true;
            oMachineOrderLineItemBundle.Apttus_Config2__HasOptions__c = true;
            oMachineOrderLineItemBundle.APTS_Order_LSP_Detail__c = oLSPDetails.Id;
            oMachineOrderLineItemBundle.APTS_Material_Availability_Date__c = Date.today();
            oMachineOrderLineItemBundle.Apttus_Config2__DerivedFromId__c = oMachineLineItemBundle.Id;
            oMachineOrderLineItemBundle.Apttus_Config2__LineType__c = 'Product/Service';
            oMachineOrderLineItemBundle.APTS_Type_of_Contract__c = 'Sales';
            oMachineOrderLineItemBundle.Apttus_Config2__ChargeType__c = 'Sales Price';
            oMachineOrderLineItemBundle.Apttus_CMConfig__AgreementId__c = oAgreement.Id;
            orderLineItemList.add(oMachineOrderLineItemBundle);

            Apttus_Config2__OrderLineItem__c oMachineOrderLineItemBundleNP = APTS_TestDataFactory.createOrderLineItem(oMachineOrder, oPriceListItemBundle.Id, null, oBundleProduct.Id, null, oMachineAssetLineItemBundle.Id, null, 1, 1, 1, 'Product/Service', oBillingPreference.Id, 'One Time', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 200.0, 20.0);
            oMachineOrderLineItemBundleNP.Apttus_Config2__FulfilledQuantity__c = 20;
            oMachineOrderLineItemBundleNP.Apttus_Config2__IsPrimaryLine__c = false;
            oMachineOrderLineItemBundleNP.APTS_Item_Relevant_for_SAP__c = true;
            oMachineOrderLineItemBundleNP.Apttus_Config2__HasOptions__c = true;
            oMachineOrderLineItemBundleNP.APTS_Order_LSP_Detail__c = oLSPDetails.Id;
            oMachineOrderLineItemBundleNP.APTS_Material_Availability_Date__c = Date.today();
            oMachineOrderLineItemBundleNP.Apttus_Config2__DerivedFromId__c = oMachineLineItemBundle.Id;
            oMachineOrderLineItemBundleNP.Apttus_CMConfig__AgreementId__c = oAgreement.Id;
            orderLineItemList.add(oMachineOrderLineItemBundleNP);

            Apttus_Config2__OrderLineItem__c oMachineOrderLineItemOption = APTS_TestDataFactory.createOrderLineItem(oMachineOrder, oPriceListItemOption.Id, null, oBundleProduct.Id, oOptionProduct.Id, oMachineAssetLineItemOption.Id, null, 1, 1, 1, 'Option', oBillingPreference.Id, 'One Time', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 200.0, 20.0);
            oMachineOrderLineItemOption.Apttus_Config2__FulfilledQuantity__c = 20;
            oMachineOrderLineItemOption.Apttus_Config2__IsPrimaryLine__c = true;
            oMachineOrderLineItemOption.APTS_Item_Relevant_for_SAP__c = true;
            oMachineOrderLineItemOption.Apttus_Config2__DerivedFromId__c = oMachineLineItemOption.Id;
            oMachineOrderLineItemOption.Apttus_CMConfig__AgreementId__c = oAgreement.Id;
            orderLineItemList.add(oMachineOrderLineItemOption);
            Database.insert(orderLineItemList);
        }
    }

    //Create Order
    @TestVisible private static void createMachineAmendOrder(User testuser) {

        System.runAs(testuser) {

            Apttus_Config2__Order__c oOrder = new Apttus_Config2__Order__c();
            oOrder.APTS_SAP_OrderType__c = 'XA13';
            oOrder.Apttus_Config2__Description__c = 'MachineAmendOrder';
            Database.insert(oOrder);

            APTS_Order_LSP_Details__c oLSPDetails = APTS_TestDataFactory.createLSPDetails();
            Database.insert(oLSPDetails);

            List<Apttus_Config2__OrderLineItem__c> orderLineItemTIList = new List<Apttus_Config2__OrderLineItem__c>();
            Apttus_Config2__OrderLineItem__c oOrderLineItem = new Apttus_Config2__OrderLineItem__c();
            oOrderLineItem.Apttus_Config2__OrderId__c = oOrder.Id;
            oOrderLineItem.APTS_Order_LSP_Detail__c = oLSPDetails.Id;
            oOrderLineItem.Apttus_Config2__LineType__c = 'Product/Service';
            oOrderLineItem.APTS_Type_of_Contract__c = 'Sales';
            oOrderLineItem.Apttus_Config2__ChargeType__c = 'Sales Price';
            oOrderLineItem.Apttus_Config2__LineStatus__c = 'Amended';
            orderLineItemTIList.add(oOrderLineItem);

            Apttus_Config2__OrderLineItem__c oOrderLineItemOption = new Apttus_Config2__OrderLineItem__c();
            oOrderLineItemOption.Apttus_Config2__OrderId__c = oOrder.Id;
            oOrderLineItemOption.Apttus_Config2__LineType__c = OPTION;
            oOrderLineItemOption.APTS_Item_Relevant_for_SAP__c = true;
            oOrderLineItemOption.Apttus_Config2__LineStatus__c = 'New';
            orderLineItemTIList.add(oOrderLineItemOption);

            Database.insert(orderLineItemTIList);
        }
    }

    //Create Order
    @TestVisible private static void createSimpleOrderWithAgreement(User testuser, Id agreementId) {

        System.runAs(testuser) {

            Apttus_Config2__Order__c oOrder = new Apttus_Config2__Order__c();
            oOrder.APTS_SAP_OrderType__c = 'XA13';
            oOrder.Apttus_Config2__Description__c = 'MachineAmendOrder';
            oOrder.Apttus_CMConfig__AgreementId__c = agreementId;
            Database.insert(oOrder);

            APTS_Order_LSP_Details__c oLSPDetails = APTS_TestDataFactory.createLSPDetails();
            Database.insert(oLSPDetails);

            List<Apttus_Config2__OrderLineItem__c> orderLineItemTIList = new List<Apttus_Config2__OrderLineItem__c>();
            Apttus_Config2__OrderLineItem__c oOrderLineItem = new Apttus_Config2__OrderLineItem__c();
            oOrderLineItem.Apttus_Config2__OrderId__c = oOrder.Id;
            oOrderLineItem.Apttus_CMConfig__AgreementId__c = agreementId;
            oOrderLineItem.APTS_Order_LSP_Detail__c = oLSPDetails.Id;
            oOrderLineItem.Apttus_Config2__LineType__c = 'Product/Service';
            oOrderLineItem.APTS_Type_of_Contract__c = 'Sales';
            oOrderLineItem.Apttus_Config2__ChargeType__c = 'Sales Price';
            oOrderLineItem.Apttus_Config2__LineStatus__c = 'Amended';
            orderLineItemTIList.add(oOrderLineItem);

            Apttus_Config2__OrderLineItem__c oOrderLineItemOption = new Apttus_Config2__OrderLineItem__c();
            oOrderLineItemOption.Apttus_Config2__OrderId__c = oOrder.Id;
            oOrderLineItemOption.Apttus_CMConfig__AgreementId__c = agreementId;
            oOrderLineItemOption.Apttus_Config2__LineType__c = OPTION;
            oOrderLineItemOption.APTS_Item_Relevant_for_SAP__c = true;
            oOrderLineItemOption.Apttus_Config2__LineStatus__c = 'New';
            orderLineItemTIList.add(oOrderLineItemOption);

            Database.insert(orderLineItemTIList);
        }
    }

    @TestVisible private static User getTestUser() {

        User testuser = [SELECT Id FROM USER WHERE LastName = 'testUserForTestClasses' LIMIT 1];

        return testuser;
    }

    @TestVisible private static Account getAccount() {

        Account oAccount = [
                               SELECT Id, Name, Apttus_Config2__BillingPreferenceId__c, Apttus_Config2__PaymentTermId__c, APTS_Payment_Method__c,Language__c,
                               Sales_Organization__c, Division__c, Distribution_Channel__c, Bill_To_Payer_Account__c,
                               Related_Payer_Account__c, /*Related_Bill_to_Machines_Services__c,*/ Related_Payer_Machines_Services__c,
                               APTS_Account_Level__c
                               FROM Account
                               WHERE Name = 'JDETestAccount' LIMIT 1];

        return oAccount;
    }

    @TestVisible private static Account getAccount(String sName) {

        Account oAccount = [
                               SELECT Id, Apttus_Config2__BillingPreferenceId__c, Apttus_Config2__PaymentTermId__c, APTS_Payment_Method__c,Language__c,
                               Sales_Organization__c, Division__c, Distribution_Channel__c, Bill_To_Payer_Account__c,
                               Related_Payer_Account__c, Related_Payer_Machines_Services__c,
                               APTS_Account_Level__c
                               FROM Account
                               WHERE Name = :sName LIMIT 1];

        return oAccount;
    }

    @TestVisible private static Contact getContact() {

        Contact oContact = [SELECT Id FROM Contact WHERE MobilePhone = '1010101011' LIMIT 1];

        return oContact;
    }

    @TestVisible private static Map<Id, Contact> getContacts(Id accountId) {
        
        Map<Id, Contact> idToContactMap = new Map<Id, Contact>([SELECT Id, Name, Function__c, Main_Commercial_Person__c, Main_Service_Person__c FROM Contact WHERE AccountId = :accountId ]);

        return idToContactMap;
    }

    @TestVisible private static Opportunity getOpportunity() {

        Opportunity oOpportunity = [SELECT Id FROM Opportunity LIMIT 1];

        return oOpportunity;
    }

    @TestVisible private static List<Product2> getProductList() {
        
        List<Product2> productList = [SELECT Id FROM Product2 ];

        return productList;
    }

    @TestVisible private static Product2 getStandaloneProduct() {

        Product2 oStandaloneProduct = [SELECT Id FROM Product2 WHERE Name = 'Standalone' LIMIT 1];

        return oStandaloneProduct;
    }

    @TestVisible private static Product2 getBundleProduct() {

        Product2 oBundleProduct = [SELECT Id FROM Product2 WHERE Name = 'Bundle' LIMIT 1];

        return oBundleProduct;
    }

    @TestVisible private static Product2 getOptionProduct() {

        Product2 oOptionProduct = [SELECT Id FROM Product2 WHERE Name = 'Option' LIMIT 1];

        return oOptionProduct;
    }

    @TestVisible private static Product2 getProductByName(String sName) {

        Product2 oProduct = [SELECT Id FROM Product2 WHERE Name = :sName LIMIT 1];

        return oProduct;
    }

    @TestVisible private static Apttus_Config2__PriceList__c getPriceList() {

        Apttus_Config2__PriceList__c oPriceList = [SELECT Id FROM Apttus_Config2__PriceList__c LIMIT 1];

        return oPriceList;
    }

    @TestVisible private static Apttus_Config2__PriceListItem__c getPriceListItem(Id productId) {

        Apttus_Config2__PriceListItem__c oPriceListItem = [SELECT Id FROM Apttus_Config2__PriceListItem__c WHERE Apttus_Config2__ProductId__c = :productId LIMIT 1];

        return oPriceListItem;
    }

    @TestVisible private static Apttus__APTS_Agreement__c getAgreement(String sName) {

        Apttus__APTS_Agreement__c oAgreement = [
                SELECT Id, Name, RecordTypeId, Apttus_CMConfig__PriceListId__c, Apttus_CMConfig__PONumber__c,
                Apttus_CMConfig__BillingPreferenceId__c, Apttus_CMConfig__PaymentTermId__c, Apttus__Status_Category__c,
                Apttus__Status__c, Apttus__Contract_Start_Date__c, Apttus__Contract_End_Date__c,
                Apttus__Account__r.APTS_Account_Level__c, Apttus__Account__r.Name, Apttus__Primary_Contact__c,
                APTS_Language__c, APTS_Bill_to_Party_Ingredients__c, APTS_Payer_Ingredients__c, APTS_Bill_to_Party_MachServ__c,
                APTS_Payer_Machines_Services__c, Apttus__Account__c,APTS_Agreement_Request__c
                FROM Apttus__APTS_Agreement__c
                WHERE Name = :sName LIMIT 1];

        return oAgreement;
    }

    @TestVisible private static APTS_Billing_Settings__c getBillingSettings() {

        APTS_Billing_Settings__c oBillingSetting = [SELECT Id FROM APTS_Billing_Settings__c LIMIT 1];

        return oBillingSetting;
    }

    @TestVisible private static Apttus_Config2__BillingPreference__c getBillingPreference() {

        Apttus_Config2__BillingPreference__c oBillingPreference = [SELECT Id FROM Apttus_Config2__BillingPreference__c LIMIT 1];

        return oBillingPreference;
    }

    @TestVisible private static Apttus_Config2__Order__c getOrder() {

        Apttus_Config2__Order__c oOrder = [
                                              SELECT Id, Name, APTS_Name__c, Apttus_Config2__Status__c, RecordTypeId,
                                              Apttus_Config2__OrderStartDate__c, Apttus_Config2__OrderEndDate__c,
                                              Apttus_CMConfig__AgreementId__c, Apttus_Config2__BillingPreferenceId__c,
                                              Apttus_Config2__BillToAccountId__c, Apttus_Config2__PriceListId__c, Apttus_Config2__ShipToAccountId__c,
                                              Apttus_Config2__SoldToAccountId__c, Apttus_Config2__Source__c, APTS_Status__c, Apttus_Config2__PrimaryContactId__c,
                                              APTS_Subject__c, APTS_LSP_Description__c, APTS_ServiceContact__c, APTS_ProjectNumber__c, APTS_IsProject__c,
                                              APTS_ScheduleDate__c, APTS_ScheduleExceptions__c, Apttus_Config2__ParentOrderId__c, APTS_Requested_Delivery_Date__c, APTS_Order_Header_SAP_ID__c,
                                              APTS_Order_Sub_Type__c, APTS_Requested_Installation_Date__c, Apttus_Config2__PONumber__c,
                                              APTS_Sales_Organization__c, APTS_Order_Type__c, Apttus_Config2__LocationId__c,
                                              Apttus_CMConfig__AgreementId__r.Apttus__Version_Number__c
                                              FROM Apttus_Config2__Order__c
                                              WHERE Apttus_Config2__Description__c = 'StandardOrder' LIMIT 1];

        return oOrder;
    }

    @TestVisible private static Apttus_Config2__Order__c getOrder(String sDescription) {

        Apttus_Config2__Order__c oOrder = [
                                              SELECT Id, Name, APTS_Name__c, Apttus_Config2__Status__c, RecordTypeId,
                                              Apttus_Config2__OrderStartDate__c, Apttus_Config2__OrderEndDate__c,
                                              Apttus_CMConfig__AgreementId__c, Apttus_Config2__BillingPreferenceId__c,
                                              Apttus_Config2__BillToAccountId__c, Apttus_Config2__PriceListId__c, Apttus_Config2__ShipToAccountId__c,
                                              Apttus_Config2__SoldToAccountId__c, Apttus_Config2__Source__c, APTS_Status__c, Apttus_Config2__PrimaryContactId__c,
                                              APTS_Subject__c, APTS_LSP_Description__c, APTS_ServiceContact__c, APTS_ProjectNumber__c, APTS_IsProject__c,
                                              APTS_ScheduleDate__c, APTS_ScheduleExceptions__c, Apttus_Config2__ParentOrderId__c, APTS_Requested_Delivery_Date__c,
                                              APTS_Order_Sub_Type__c, APTS_Requested_Installation_Date__c, Apttus_Config2__PONumber__c,
                                              APTS_Sales_Organization__c, APTS_Order_Type__c, Apttus_Config2__LocationId__c,
                                              APTS_SAP_OrderType__c
                                              FROM Apttus_Config2__Order__c
                                              WHERE Apttus_Config2__Description__c = :sDescription LIMIT 1];

        return oOrder;
    }

    @TestVisible private static Apttus_Config2__Order__c getMachineOrder() {

        Apttus_Config2__Order__c oOrder = [
                                              SELECT Id, Name, APTS_Name__c, Apttus_Config2__Status__c, RecordTypeId,
                                              Apttus_Config2__OrderStartDate__c, Apttus_Config2__OrderEndDate__c,APTS_ATP_Check_Status__c,
                                              Apttus_CMConfig__AgreementId__c, Apttus_Config2__BillingPreferenceId__c,APTS_Remove_Billing_Block_Indicator__c,
                                              Apttus_Config2__BillToAccountId__c, Apttus_Config2__PriceListId__c, Apttus_Config2__ShipToAccountId__c,
                                              Apttus_Config2__SoldToAccountId__c, Apttus_Config2__Source__c, APTS_Status__c, Apttus_Config2__PrimaryContactId__c,
                                              APTS_Subject__c, APTS_LSP_Description__c, APTS_ServiceContact__c, APTS_ProjectNumber__c, APTS_IsProject__c,
                                              APTS_ScheduleDate__c, APTS_ScheduleExceptions__c, Apttus_Config2__ParentOrderId__c, APTS_Requested_Delivery_Date__c,
                                              APTS_Order_Sub_Type__c, APTS_Requested_Installation_Date__c, Apttus_Config2__PONumber__c,
                                              APTS_Sales_Organization__c, APTS_Order_Type__c, Apttus_Config2__LocationId__c,
                                              APTS_SAP_OrderType__c,APTS_Billing_Date__c
                                              FROM Apttus_Config2__Order__c
                                              WHERE Apttus_Config2__Description__c = 'MachineOrder' LIMIT 1];

        return oOrder;
    }

    @TestVisible private static Apttus_Config2__Order__c getBeingAmendedOrderOrder() {

        Apttus_Config2__Order__c oOrder = [
                                              SELECT Id, Name, APTS_Name__c, Apttus_Config2__Status__c, RecordTypeId,
                                              Apttus_Config2__OrderStartDate__c, Apttus_Config2__OrderEndDate__c,
                                              Apttus_CMConfig__AgreementId__c, Apttus_Config2__BillingPreferenceId__c,
                                              Apttus_Config2__BillToAccountId__c, Apttus_Config2__PriceListId__c, Apttus_Config2__ShipToAccountId__c,
                                              Apttus_Config2__SoldToAccountId__c, Apttus_Config2__Source__c, APTS_Status__c, Apttus_Config2__PrimaryContactId__c,
                                              APTS_Subject__c, APTS_LSP_Description__c, APTS_ServiceContact__c, APTS_ProjectNumber__c, APTS_IsProject__c,
                                              APTS_ScheduleDate__c, APTS_ScheduleExceptions__c, Apttus_Config2__ParentOrderId__c, APTS_Requested_Delivery_Date__c,
                                              APTS_Order_Sub_Type__c, APTS_Requested_Installation_Date__c, Apttus_Config2__PONumber__c,
                                              APTS_Sales_Organization__c, APTS_Order_Type__c, Apttus_Config2__LocationId__c,
                                              APTS_SAP_OrderType__c
                                              FROM Apttus_Config2__Order__c
                                              WHERE Apttus_Config2__Description__c = 'StandardOrderBeingAmended' LIMIT 1];

        return oOrder;
    }

    @TestVisible private static Apttus_Config2__ProductConfiguration__c getProductConfiguration() {

        Apttus_Config2__ProductConfiguration__c oProductConfiguration = [
                    SELECT Id, APTS_Flow__c, Apttus_Config2__OrderId__c,
                    Apttus_Config2__CartDataCache__c, Apttus_Config2__CartDataCache2__c, Apttus_Config2__PriceListId__c,
                    Apttus_Config2__EffectiveDate__c, Apttus_Config2__BusinessObjectType__c, Apttus_Config2__SummaryGroupType__c
                    FROM Apttus_Config2__ProductConfiguration__c
                    WHERE APTS_Flow__c = :NGSTANDARD_ORDER limit 1];

        return oProductConfiguration;
    }

    @TestVisible private static List<Apttus_Config2__ProductConfiguration__c> getProductConfigurationList() {
        
        List<Apttus_Config2__ProductConfiguration__c> oProductConfiguration = [
                    SELECT Id, APTS_Flow__c, Apttus_Config2__OrderId__c,
                    Apttus_Config2__CartDataCache__c, Apttus_Config2__CartDataCache2__c, Apttus_Config2__PriceListId__c,
                    Apttus_Config2__EffectiveDate__c, Apttus_Config2__BusinessObjectType__c, Apttus_Config2__SummaryGroupType__c
                    FROM Apttus_Config2__ProductConfiguration__c
                    WHERE APTS_Flow__c = :NGSTANDARD_ORDER ];

        return oProductConfiguration;
    }

    @TestVisible private static Apttus_Config2__ProductConfiguration__c getMachineProductConfiguration() {
        
        Apttus_Config2__ProductConfiguration__c oProductConfiguration = [
                    SELECT Id, APTS_Flow__c, Apttus_Config2__OrderId__c,
                    Apttus_Config2__CartDataCache__c, Apttus_Config2__CartDataCache2__c, Apttus_Config2__PriceListId__c,
                    Apttus_Config2__EffectiveDate__c, Apttus_Config2__BusinessObjectType__c, Apttus_Config2__SummaryGroupType__c
                    , Apttus_CMConfig__AgreementId__c FROM Apttus_Config2__ProductConfiguration__c
                    WHERE APTS_Flow__c = :NGMACHINE_ORDER ];

        return oProductConfiguration;
    }

    @TestVisible private static List<Apttus_Config2__LineItem__c> getLineItemList() {
        
        List<Apttus_Config2__LineItem__c> lineItemList = [
                    SELECT Id, Apttus_Config2__LineType__c, Apttus_Config2__ProductId__c, Apttus_Config2__AttributeValueId__c,
                    Apttus_Config2__IsPrimaryLine__c, Apttus_Config2__PriceListItemId__r.APTS_Call_Out_Coverage__c,
                    Apttus_Config2__PriceListItemId__r.APTS_Labour_Coverage__c, Apttus_Config2__PriceListItemId__r.APTS_Spare_Parts_Coverage__c,
                    Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__ParentOptionGroupId__r.Apttus_Config2__Label__c,
                    Apttus_Config2__AttributeValueId__r.APTS_Call_Out_Coverage_chk__c, Apttus_Config2__AttributeValueId__r.APTS_Labour_Coverage_chk__c, Apttus_Config2__AttributeValueId__r.APTS_Spare_Parts_Coverage_chk__c,
                    APTS_Requested_Delivery_Date__c, Apttus_Config2__OptionId__r.Name, Apttus_Config2__PriceListItemId__r.APTS_Default_Selling_Uom__c,
                    Apttus_Config2__SellingUom__c, APTS_Source_Line_Number__c, Apttus_Config2__LineStatus__c, Apttus_Config2__AttributeValueId__r.APTS_Refurbished__c, APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingTerm__c,
                    Apttus_Config2__HasOptions__c,Apttus_Config2__LineNumber__c, APTS_Product_Material_Type__c, Apttus_Config2__ClassificationHierarchy__c,
                    Apttus_Config2__OptionGroupLabel__c, Agreement_Line_Item__c, APTS_Type_of_contract__c
                    FROM Apttus_Config2__LineItem__c ];

        return lineItemList;
    }

    @TestVisible private static List<Apttus_Config2__LineItem__c> getLineItemList(Id productConfigurationId) {
        
        List<Apttus_Config2__LineItem__c> lineItemList = [
                    SELECT Id, Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c, Apttus_Config2__NetPrice__c, CurrencyIsoCode, Apttus_Config2__ProductId__r.APTS_Material_Type__c, Apttus_Config2__AttributeValueId__r.APTS_Type_of_contract__c, Apttus_Config2__AttributeValueId__r.APTS_Include_Free_Service__c, Apttus_Config2__LineType__c, Apttus_Config2__ProductId__c, Apttus_Config2__AttributeValueId__c,
                    Apttus_Config2__IsPrimaryLine__c, Apttus_Config2__PriceListItemId__r.APTS_Call_Out_Coverage__c,
                    Apttus_Config2__PriceListItemId__r.APTS_Labour_Coverage__c, Apttus_Config2__PriceListItemId__r.APTS_Spare_Parts_Coverage__c,
                    Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__ParentOptionGroupId__r.Apttus_Config2__Label__c,
                    Apttus_Config2__AttributeValueId__r.APTS_Call_Out_Coverage_chk__c, Apttus_Config2__AttributeValueId__r.APTS_Labour_Coverage_chk__c, Apttus_Config2__AttributeValueId__r.APTS_Spare_Parts_Coverage_chk__c,
                    APTS_Requested_Delivery_Date__c, Apttus_Config2__OptionId__r.Name, Apttus_Config2__PriceListItemId__r.APTS_Default_Selling_Uom__c,
                    Apttus_Config2__SellingUom__c, APTS_Source_Line_Number__c, Apttus_Config2__LineStatus__c,Apttus_Config2__AttributeValueId__r.APTS_Refurbished__c, APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingTerm__c, APTS_Agreement_Line_Item__c,Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.Apttus_Config2__OrderStartDate__c,
                    Apttus_Config2__HasOptions__c, APTS_Product_Material_Type__c, Apttus_Config2__ClassificationHierarchy__c,
                    Apttus_Config2__OptionGroupLabel__c, Agreement_Line_Item__c, Apttus_Config2__BasePriceOverride__c, APTS_Type_of_contract__c
                    FROM Apttus_Config2__LineItem__c
                    WHERE Apttus_Config2__ConfigurationId__c = :productConfigurationId ];
//added Apttus_Config2__BasePriceOverride__c to increase code coverage - akhilesh
        return lineItemList;
    }

    @TestVisible private static Apttus_Config2__ProductOptionComponent__c getProductOptionComponent(String sName) {

        Apttus_Config2__ProductOptionComponent__c oProductOptionComponent = [SELECT Id FROM Apttus_Config2__ProductOptionComponent__c WHERE Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__ParentOptionGroupId__r.Apttus_Config2__Label__c = :sName LIMIT 1];

        return oProductOptionComponent;
    }

    @TestVisible private static List<Apttus_Config2__OrderLineItem__c> getOrderLineItemList(Id orderId) {
        
        List<Apttus_Config2__OrderLineItem__c> orderLineItemList = [
                    SELECT Id, Name, Apttus_Config2__LocationId__c, APTS_Machine_Age__c,
                    APTS_Serial_Number__c, APTS_Goods_Issue_Date__c, APTS_RefurbishedMachine__c, APTS_Item_Relevant_for_SAP__c,
                    Apttus_Config2__LineType__c,
                    APTS_Physical_Asset__c,
                    APTS_Item_Category__c,
                    Apttus_Config2__IsPrimaryLine__c,
                    Apttus_Config2__ParentBundleNumber__c,
                    APTS_Option_Group_Text__c,
                    APTS_Replaced_Product_Code__c,
                    Apttus_Config2__FulfilledQuantity__c,
                    APTS_SAP_Order_Line_Item_Number__c,
                    Apttus_Config2__EndDate__c,
                    Apttus_Config2__SellingTerm__c,
                    Apttus_Config2__Status__c,
                    APTS_ATP_Cleared__c,
                    Apttus_Config2__ActivatedDate__c,
                    Apttus_Config2__ReadyForBillingDate__c,
                    APTS_Requested_Delivery_Date__c,
                    APTS_Status__c,
                    APTS_Installation_Date_Authorized__c,
                    APTS_De_installation_Date_Authorized__c,
                    APTS_Expected_Delivery_Quantity__c,
                    APTS_Expected_Delivery_Date__c,
                    Apttus_Config2__LineNumber__c, Apttus_Config2__ChargeType__c,
                    Apttus_Config2__AssetLineItemId__c,
                    Apttus_Config2__AssetLineItemId__r.APTS_RefurbishedMachine__c,
                    Apttus_Config2__AssetLineItemId__r.Apttus_Config2__StartDate__c,
                    Apttus_Config2__AssetLineItemId__r.Apttus_Config2__EndDate__c,
                    Apttus_Config2__AssetLineItemId__r.Apttus_Config2__AssetStatus__c,
                    Apttus_Config2__AssetLineItemId__r.APTS_Physical_Asset__c,
                    Apttus_Config2__AssetLineItemId__r.APTS_OwnedByCustomer__c,
                    Apttus_CMConfig__AgreementId__c,
                    Apttus_CMConfig__AgreementLineItemId__c,
                    Apttus_CMConfig__AgreementId__r.RecordType.DeveloperName,
                    Apttus_CMConfig__AgreementId__r.RecordType.Name,
                    Apttus_CMConfig__AgreementId__r.Apttus__Status_Category__c,
                    Apttus_CMConfig__AgreementId__r.Apttus__Status__c,
                    APTS_Order_LSP_Detail__c,
                    APTS_Order_LSP_Detail__r.APTS_Building__c,
                    APTS_Order_LSP_Detail__r.APTS_Floor__c,
                    APTS_Order_LSP_Detail__r.APTS_Area__c,
                    APTS_Order_LSP_Detail__r.APTS_CustomerReference__c,
                    APTS_Order_LSP_Detail__r.APTS_SmokingArea__c,
                    APTS_Order_LSP_Detail__r.APTS_ConfigurationFileURL__c,
                    APTS_Order_LSP_Detail__r.APTS_JDE_crockeryVolumeSize__c,
                    Apttus_Config2__OrderId__c,
                    Apttus_Config2__OrderId__r.Apttus_Config2__PONumber__c,
                    Apttus_Config2__OrderId__r.APTS_Sales_Organization__c,
                    Apttus_Config2__OrderId__r.Apttus_Config2__SoldToAccountId__c,
                    Apttus_Config2__OrderId__r.APTS_Confirmed_De_Installation_Date__c,
                    Apttus_Config2__OrderId__r.APTS_Confirmed_Installation_Date__c,
                    Apttus_Config2__AttributeValueId__c,
                    Apttus_Config2__AttributeValueId__r.APTS_Number_of_months__c,
                    Apttus_Config2__AttributeValueId__r.APTS_Call_Out_Coverage_Percent__c,
                    Apttus_Config2__AttributeValueId__r.APTS_Labour_Coverage_Percent__c,
                    Apttus_Config2__AttributeValueId__r.APTS_Spare_Parts_Coverage_Percent__c,
                    Apttus_Config2__AttributeValueId__r.APTS_WTS_Changed_By__c,
                    Apttus_Config2__ProductId__c,
                    Apttus_Config2__ProductId__r.Name,
                    Apttus_Config2__ProductId__r.Description,
                    Apttus_Config2__ProductId__r.ProductCode,
                    Apttus_Config2__ProductId__r.APTS_Material_Type__c,
                    Apttus_Config2__ProductId__r.Apttus_Config2__ConfigurationType__c,
                    Apttus_Config2__ProductId__r.APTS_Vendor_Code__c,
                    Apttus_Config2__OptionId__c,
                    Apttus_Config2__OptionId__r.Name,
                    Apttus_Config2__OptionId__r.Description,
                    Apttus_Config2__OptionId__r.ProductCode,
                    Apttus_Config2__OptionId__r.APTS_Material_Type__c,
                    Apttus_Config2__ShipToAccountId__c,
                    Apttus_Config2__ShipToAccountId__r.ShippingCountry,
                    Apttus_Config2__ShipToAccountId__r.WSONE_DATA__ShippingAddressCountryISO__c,
                    Apttus_Config2__ShipToAccountId__r.ShippingPostalCode,
                    Apttus_Config2__ShipToAccountId__r.ShippingStreet,
                    Apttus_Config2__ShipToAccountId__r.WSONE_DATA__ShippingAddressHouseNumber__c,
                    Apttus_Config2__ShipToAccountId__r.ShippingCity,
                    Apttus_Config2__HasOptions__c,
                    Apttus_CMConfig__AgreementId__r.APTS_Routesales__c,
                    Apttus_Config2__AttributeValueId__r.APTS_Response_Profile__c,
                    Apttus_Config2__DerivedFromId__c,
                    APTS_Material_Availability_Date__c,
                    APTS_Installation_Required__c,
                    APTS_De_Installation_Required__c,
                    Apttus_Config2__LineStatus__c,
                    APTS_Is_Primary_L1_Line__c,
                    APTS_Physical_Machine_Option__c,
                    APTS_Type_of_Contract__c,
                    APTS_PlugPlay__c,
                    APTS_Physical_Asset__r.AccountLocation__c,
                    APTS_Physical_Asset__r.Building__c,
                    APTS_Physical_Asset__r.Area__c,
                    APTS_Physical_Asset__r.Floor__c,
                    APTS_Physical_Asset__r.OwnedByCustomer__c,
                    APTS_Physical_Asset__r.StairClimber__c,
                    APTS_Physical_Asset__r.CustomerReferenceNumber__c,
                    APTS_Physical_Asset__r.SmokingArea__c,
                    APTS_Physical_Asset__r.JDECrockeryVolumeSize__c,
                    APTS_Physical_Asset__r.RequiresLSP__c,
                    APTS_Physical_Asset__r.CommercialUsage__c,
                    APTS_Physical_Asset__r.AccountLocation__r.Main_Service_Contact__c,
                    APTS_Physical_Asset__r.ConfigurationManualAgreementsURL__c,
                    APTS_Plant_Code__c
                    FROM Apttus_Config2__OrderLineItem__c
                    WHERE Apttus_Config2__OrderId__c = :orderId ];

        return orderLineItemList;
    }

    @TestVisible private static List<Apttus_Config2__ProductAttributeValue__c> getProductAttributeValue() {
        
        List<Apttus_Config2__ProductAttributeValue__c> lProdAttrValue = [
                    SELECT Id, APTS_Labour_coverage_Price__c, APTS_Call_out_Price__c
                    FROM Apttus_Config2__ProductAttributeValue__c ];
        return lProdAttrValue ;
    }

    @TestVisible private static List<Apttus__AgreementLineItem__c> getProductAgLineItem(String sConfType) {
        
        List<Apttus__AgreementLineItem__c> lAGLI = [
                    SELECT id, Apttus__ProductId__c, Apttus_CMConfig__OptionId__c,
                    Apttus_CMConfig__ChargeType__c, Apttus_CMConfig__ClassificationId__c, Apttus_CMConfig__ClassificationHierarchy__c,
                    Apttus_CMConfig__ProductOptionId__c, Apttus_CMConfig__PriceListItemId__c, Apttus__Quantity__c,
                    Apttus_CMConfig__SellingFrequency__c, Apttus_CMConfig__SellingTerm__c, Apttus_CMConfig__AdjustmentType__c,
                    Apttus_CMConfig__AdjustmentAmount__c, Apttus_CMConfig__Comments__c, Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c,
                    Apttus_CMConfig__IsPrimaryLine__c, Apttus__AgreementId__c, Apttus_CMConfig__LineNumber__c,Apttus_CMConfig__SellingUom__c
                    FROM Apttus__AgreementLineItem__c
                    WHERE Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c = : sConfType ];

        return lAGLI;
    }

    @TestVisible private static List<Apttus__AgreementLineItem__c> getOptionAgLineItem() {
        
        List<Apttus__AgreementLineItem__c> lAGLI = [
                    SELECT id, Apttus__ProductId__c, Apttus_CMConfig__OptionId__c,
                    Apttus_CMConfig__ChargeType__c, Apttus_CMConfig__ClassificationId__c, Apttus_CMConfig__ClassificationHierarchy__c,
                    Apttus_CMConfig__ProductOptionId__c, Apttus_CMConfig__PriceListItemId__c, Apttus__Quantity__c,
                    Apttus_CMConfig__SellingFrequency__c, Apttus_CMConfig__SellingTerm__c, Apttus_CMConfig__AdjustmentType__c,
                    Apttus_CMConfig__AdjustmentAmount__c, Apttus_CMConfig__Comments__c, Apttus_CMConfig__IsPrimaryLine__c,
                    Apttus_CMConfig__ProductOptionId__r.Apttus_Config2__ComponentProductId__c, Apttus_CMConfig__LineType__c,
                    Apttus__AgreementId__c, Apttus_CMConfig__LineNumber__c,Apttus_CMConfig__SellingUom__c
                    FROM Apttus__AgreementLineItem__c
                    WHERE Apttus_CMConfig__OptionId__c != null ];

        return lAGLI;
    }

    @TestVisible private static List<Apttus__AgreementLineItem__c> getAgreementLineItem(Id agreementId) {
        
        List<Apttus__AgreementLineItem__c> agreementLineItemList = [
                    SELECT id, Apttus__ProductId__c, Apttus_CMConfig__OptionId__c,
                    Apttus_CMConfig__ChargeType__c, Apttus_CMConfig__ClassificationId__c, Apttus_CMConfig__ClassificationHierarchy__c,
                    Apttus_CMConfig__ProductOptionId__c, Apttus_CMConfig__PriceListItemId__c, Apttus__Quantity__c,
                    Apttus_CMConfig__SellingFrequency__c, Apttus_CMConfig__SellingTerm__c, Apttus_CMConfig__AdjustmentType__c,
                    Apttus_CMConfig__AdjustmentAmount__c, Apttus_CMConfig__Comments__c, Apttus_CMConfig__IsPrimaryLine__c,
                    Apttus_CMConfig__ProductOptionId__r.Apttus_Config2__ComponentProductId__c, Apttus_CMConfig__LineType__c,
                    Apttus__AgreementId__c, Apttus_CMConfig__LineNumber__c
                    FROM Apttus__AgreementLineItem__c
                    WHERE Apttus__AgreementId__c = :agreementId ];

        return agreementLineItemList;
    }

    @TestVisible private static List<Apttus_Config2__AssetLineItem__c> getAssetLineItem() {
        
        List<Apttus_Config2__AssetLineItem__c> assetLineItemList = [
                    SELECT Id
                    FROM Apttus_Config2__AssetLineItem__c ];

        return assetLineItemList;
    }

    @TestVisible private static Apttus_Config2__ClassificationHierarchy__c getClassificationHierarchy(String sName) {

        Apttus_Config2__ClassificationHierarchy__c oClassificationHierarchy;
        
        List<Apttus_Config2__ClassificationHierarchy__c> classificationHierarchyList = [
                    SELECT Id
                    FROM Apttus_Config2__ClassificationHierarchy__c
                    WHERE Name = :sName ];

        if (!classificationHierarchyList.isEmpty()) {
            oClassificationHierarchy = classificationHierarchyList.get(0);
        }

        return oClassificationHierarchy;
    }

    @TestVisible private static APTS_Order_LSP_Details__c getLSPDetails(Id lspDetailsId) {
        
        APTS_Order_LSP_Details__c oLSPDetails = [
                SELECT Id, APTS_Require_Installation__c, APTS_Require_De_Installation__c, APTS_Project_Number__c
                FROM APTS_Order_LSP_Details__c
                WHERE Id = :lspDetailsId ];

        return oLSPDetails;
    }
}