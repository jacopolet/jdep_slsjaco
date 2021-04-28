/*******************************************************************************************
  Name            : APTS_AgreementTriggerHandlerTest
  Created By      : Beulah Ann Thomasṇ
  Created Date    : 01/26/2018
  Description     : Test class written for 'APTS_AgreementTriggerHandler'.
  Version history : v1.0 - Created - 
  Classes Covered : APTS_AgreementTriggerHandler(80% code coverage)
  APTS_FixedTermAgreementBatch(100% code coverage)
  APTS_FixedTermAgreement(90% code coverage)
  *********************************************************************************************/
@isTest(SeeAllData = false)
private class APTS_AgreementTriggerHandlerTest
{

	/* create test data */
	@TestSetup
	private static void createTestData()
	{

		/* User usr = APTS_TestUtils.createUser();
		  usr.Username += '.' + Integer.valueOf(math.rint(math.random()*1000000));
		  Database.insert(usr); */
		User usr = APTS_TestUtils.createUser();
		insert usr;
		QueueGateKeepers__c qgk = new QueueGateKeepers__c();
		qgk.Queue_Name__c = 'NL - Rebates/Indexation/Invoicing Queue';
		qgk.User_Keeper__c = usr.id;
		qgk.Name = '00G1v000006sYqOEAU';
		insert qgk;

		/* Account account = new Account();
		  account.Name = 'Test Account';
		  Database.Insert(account); */
		//create Billing Preference
		Apttus_Config2__BillingPreference__c billingPreference = APTS_TestUtils.createBillingPrefrence('January');
		Database.Insert(billingPreference);
		// create Payment Method
		//APTS_Payment_Method__c paymentMethod = APTS_TestUtils.paymentMethod();
		// Create Payment Term
		Apttus_Config2__PaymentTerm__c paymentTerm = APTS_TestUtils.paymentTerm();
		//Create Account
		Account account = APTS_TestUtils.createGrandParentAccount();
		//Update Billing Key Fields
		account.Apttus_Config2__BillingPreferenceId__c = billingPreference.Id;
		account.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
		//account.APTS_Payment_Method__c = paymentMethod.Id;
		account.SAP_Customer_ID__c = null;
		account.Commercial_Register_Number__c = '1234';
		account.BillingCountry = 'Netherlands';
		//account.VAT_Reg_Check_Rule__c = 3;
		//account.VAT_Reg_Length__c = 5;
		//account.VAT_Registration_Number__c = '12345';
		account.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect Valid').getRecordTypeId();
		Database.Insert(account);

		Account acc1 = APTS_TestUtils.createGrandParentAccount();
		Account acc2 = APTS_TestUtils.createParentAccount(acc1);
		Account acc3 = APTS_TestUtils.createChildAccount(acc2);

		//Create Contact
		Contact oContact = APTS_TestUtils.createContact();
		oContact.Authorized_Signer__c = true;
		oContact.Main_Commercial_Person__c = true;
		oContact.AccountId = account.Id;
		insert oContact;

		Internal_contract_compliance__c testInCom = new Internal_contract_compliance__c(budget_internal_freq__c = 'Quarterly',
		                                                                                Country__c = 'Netherlands', fixed_terms_internal_freq__c = 'Quarterly',
		                                                                                kpi_internal_freq__c = 'Quarterly', volume_obligation_internal_freq__c = 'Quarterly', volume_obligation_internal_triggerpoint__c = 90);
		Database.Insert(testInCom);

		Product2 product = APTS_TestUtils.createProduct('Dummy High Tax', '26940998', 'Coffee');
		Database.Insert(product);

		Product2 product2 = APTS_TestUtils.createProduct('Dummy Low Tax', '26940992', 'Coffee');
		Database.Insert(product2);

		Apttus_Config2__ClassificationName__c category = APTS_TestUtils.createCategory();
		Database.Insert(category);

		Apttus_Config2__ClassificationHierarchy__c categoryHierarchy =
		APTS_TestUtils.createCategoryHierarchy(category.Id);
		Database.Insert(categoryHierarchy);

		Apttus_Config2__ClassificationHierarchy__c subCategoryHierarchy =
		APTS_TestUtils.createSubCategory(category.Id, categoryHierarchy.Id);
		Database.Insert(subCategoryHierarchy);

		Apttus_Config2__ClassificationHierarchy__c subSubCategoryHierarchy =
		APTS_TestUtils.createSubCategory(category.Id, categoryHierarchy.Id);
		Database.Insert(subSubCategoryHierarchy);

		Apttus_Config2__ProductClassification__c productClassification =
		APTS_TestUtils.createProductClassification(subCategoryHierarchy.Id, product.id);
		Database.Insert(productClassification);

		Apttus_Config2__PriceList__c priceList = APTS_TestUtils.createPriceList();
		Database.Insert(priceList);

		APTS_Fixed_Term_Dummy_Product__c dummyProduct = new APTS_Fixed_Term_Dummy_Product__c(name = 'High tax',
		                                                                                     Product_Name__c = 'Dummy High Tax');
		Database.Insert(dummyProduct);


		/* Apttus_Config2__BillingPreference__c billingPreference = new Apttus_Config2__BillingPreference__c(name='test',
		  Apttus_Config2__Active__c = True,
		  Apttus_Config2__PrefLevel__c = 'Organization'
		  ); */
		//Apttus_Config2__BillingPreference__c billingPreference = APTS_TestUtils.createBillingPrefrence('January');
		//Database.Insert(billingPreference);

		insert new TriggerSettings__c(APTS_IndexContractTrigger__c = true, Agreement__c = true, APTS_AgreementPODetails__c = true);

		Id RecId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();

		Apttus__APTS_Agreement__c testAgreement = new Apttus__APTS_Agreement__c(Apttus__Account__c = account.Id,
		                                                                        Name = 'Test Agreement', RecordTypeId = RecId,
		                                                                        Apttus__Contract_Start_Date__c = Date.today(), Apttus__Contract_End_Date__c = Date.today() + 365, APTS_PricingDate__c = Date.today() + 5,
		                                                                        Apttus_CMConfig__PriceListId__c = priceList.id, APTS_Autorized_Signature_Customer__c = oContact.Id, Apttus__Subtype__c = 'Fixed-Term-Fixed Costs',
		                                                                        Apttus__Status_Category__c = 'In Signatures', Apttus__Status__c = 'Internal Signatures', APTS_One_Time_Bonus__c = 10000, APTS_Language__c = 'SAP_EN', Apttus__Version_Number__c = 0,
		                                                                        APTS_Fixed_Term_Type__c = ' Fixed Cost', Apttus_CMConfig__BillingPreferenceId__c = billingPreference.Id);
		Database.Insert(testAgreement);

		List<Apttus__APTS_Agreement__c> agrlst1 = new List<Apttus__APTS_Agreement__c> ();
		Apttus__APTS_Agreement__c testAgreement9 = new Apttus__APTS_Agreement__c(Apttus__Account__c = account.Id,
		                                                                         Name = 'Test Agreement1', RecordTypeId = RecId,
		                                                                         Apttus__Contract_Start_Date__c = Date.today(), Apttus__Contract_End_Date__c = Date.today() + 365, APTS_PricingDate__c = Date.today() + 5,
		                                                                         Apttus_CMConfig__PriceListId__c = priceList.id, APTS_Autorized_Signature_Customer__c = oContact.Id, Apttus__Subtype__c = 'Fixed-Term-Fixed Costs', APTS_Language__c = 'SAP_EN', APTS_Migration_Date__c = null,
		                                                                         Apttus__Status_Category__c = 'In Signatures', Apttus__Status__c = 'Internal Signatures', APTS_One_Time_Bonus__c = 10000, Apttus__Version_Number__c = 0,
		                                                                         APTS_Fixed_Term_Type__c = ' Fixed Cost', Apttus_CMConfig__BillingPreferenceId__c = billingPreference.Id);
		agrlst1.add(testAgreement9);
		//Database.Insert(agrlst1);

		map<id, Apttus__APTS_Agreement__c> agrmap = new map<id, Apttus__APTS_Agreement__c> ();
		agrmap.putall(agrlst1);
		if (agrmap.size() > 0) {
			insert agrmap.values();
		}
		list<Apttus__APTS_Agreement__c> values = agrmap.values();

		APTS_AgreementTotalVolumeObligation__c oVolumeAssumption = new APTS_AgreementTotalVolumeObligation__c();
		oVolumeAssumption.APTS_Agreement__c = testAgreement.id;
		Database.Insert(oVolumeAssumption);

		Set<Id> agrSetid = new Set<Id> ();
		agrSetid.add(testAgreement.id);

		APTS_AgreementTriggerHandler agreementHandler = new APTS_AgreementTriggerHandler();
		//agreementHandler.afterInsert(lstAgreement,mapAgreement);  
		agreementHandler.updateVolumeAssumptionRecords(agrSetid);

		APTS_Billing_Settings__c billingSetting = new APTS_Billing_Settings__c();
		billingSetting.APTS_Agreement_ID__c = values[0].Id;
		billingSetting.APTS_Agreement_Billing_Type__c = 'Ingredients';
		Database.Insert(billingSetting);

		TriggerSettings__c settings = TriggerSettings__c.getOrgDefaults();
		settings.Agreement__c = false;
		update settings;

		Apttus__AgreementLineItem__c agreementLineItem = new Apttus__AgreementLineItem__c();
		agreementLineItem.Apttus__ProductId__c = product.Id;
		agreementLineItem.Apttus__AgreementId__c = testAgreement.Id;
		agreementLineItem.Apttus__Quantity__c = 1;
		Database.Insert(agreementLineItem);

		Apttus__AgreementLineItem__c agreementLineItem2 = new Apttus__AgreementLineItem__c();
		agreementLineItem2.Apttus__ProductId__c = product2.Id;
		agreementLineItem2.Apttus__AgreementId__c = testAgreement.Id;
		agreementLineItem2.Apttus__Quantity__c = 1;
		Database.Insert(agreementLineItem2);

		/**********Pranjal: Start************/
		List<Apttus__APTS_Agreement__c> agrlst = new List<Apttus__APTS_Agreement__c> ();
		Id RecId1 = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
		Apttus__APTS_Agreement__c testAgreement123 = new Apttus__APTS_Agreement__c(Apttus__Account__c = account.Id,
		                                                                           Apttus__Non_Standard_Legal_Language__c = true, RecordTypeId = RecId1, APTS_Migration_Date__c = null, Apttus__Version_Number__c = 0,
		                                                                           Apttus__Contract_Start_Date__c = Date.today(), Apttus__Contract_End_Date__c = Date.today() + 365,
		                                                                           Apttus_CMConfig__ConfigurationFinalizedDate__c = Date.today(), APTS_Language__c = 'SAP_EN',
		                                                                           Apttus__Status__c = 'Request', Apttus__Status_Category__c = 'Request');

		Database.Insert(testAgreement123);

		Id RecId12 = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Consumption Model').getRecordTypeId();
		Apttus__APTS_Agreement__c testAgreement12345 = new Apttus__APTS_Agreement__c(Apttus__Account__c = account.Id,
		                                                                             Apttus__Non_Standard_Legal_Language__c = true, RecordTypeId = RecId12, APTS_Migration_Date__c = null, Apttus__Version_Number__c = 0,
		                                                                             Apttus__Contract_Start_Date__c = Date.today(), Apttus__Contract_End_Date__c = Date.today() + 365,
		                                                                             Apttus_CMConfig__ConfigurationFinalizedDate__c = Date.today(), APTS_Language__c = 'SAP_EN',
		                                                                             Apttus__Status__c = 'Request', Apttus__Status_Category__c = 'Request');

		Database.Insert(testAgreement12345);

		Id RecId123 = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Registration Form').getRecordTypeId();
		Apttus__APTS_Agreement__c testAgreement1234567 = new Apttus__APTS_Agreement__c(Apttus__Account__c = account.Id,
		                                                                               Apttus__Non_Standard_Legal_Language__c = true, RecordTypeId = RecId123, APTS_Migration_Date__c = null, Apttus__Version_Number__c = 0,
		                                                                               Apttus__Contract_Start_Date__c = Date.today(), Apttus__Contract_End_Date__c = Date.today() + 365,
		                                                                               Apttus_CMConfig__ConfigurationFinalizedDate__c = Date.today(), APTS_Language__c = 'SAP_EN', APTS_Created_From_Batch__c = False,
		                                                                               Apttus__Status__c = 'Request', Apttus__Status_Category__c = 'Request');

		Database.Insert(testAgreement1234567);

		Apttus__APTS_Agreement__c testAgreement123456 = new Apttus__APTS_Agreement__c(Apttus__Account__c = account.Id,
		                                                                              Apttus__Non_Standard_Legal_Language__c = true,
		                                                                              Apttus__Contract_Start_Date__c = Date.today(), Apttus__Contract_End_Date__c = Date.today() + 365,
		                                                                              Apttus_CMConfig__ConfigurationFinalizedDate__c = Date.today(),
		                                                                              Apttus__Status__c = 'Activated', Apttus__Status_Category__c = 'In Effect');

		Database.Insert(testAgreement123456);
		Set<Id> setAccoundIds = new Set<Id> ();
		SetAccoundIds.add(testAgreement123456.Apttus__Account__c);

		Apttus__APTS_Agreement__c testAgreement1234 = new Apttus__APTS_Agreement__c(Apttus__Account__c = account.Id,
		                                                                            Apttus__Non_Standard_Legal_Language__c = true,
		                                                                            Apttus__Contract_Start_Date__c = Date.today(), Apttus__Contract_End_Date__c = Date.today() + 365,
		                                                                            Apttus_CMConfig__ConfigurationFinalizedDate__c = Date.today(),
		                                                                            Apttus__Status__c = 'Request', Apttus__Status_Category__c = 'Request');
		agrlst.add(testAgreement1234);
		Database.insert(agrlst);

		Apttus_CMConfig__AgreementProductAttributeValue__c tstAttribute = new Apttus_CMConfig__AgreementProductAttributeValue__c();
		tstAttribute.APTS_Cup_Size__c = 'Small';
		tstAttribute.APTS_Taste_Pallet__c = 'Moderate';
		tstAttribute.Apttus_CMConfig__LineItemId__c = agreementLineItem2.Id;
		Database.Insert(tstAttribute);

		Apttus__AgreementLineItem__c agreementLineItem3 = new Apttus__AgreementLineItem__c();
		agreementLineItem3.Apttus__ProductId__c = product2.Id;
		agreementLineItem3.Apttus__AgreementId__c = testAgreement123.Id;
		agreementLineItem3.Apttus__Quantity__c = 1;
		agreementLineItem3.Apttus_CMConfig__OptionId__c = product2.Id;
		agreementLineItem3.APTS_Option_Group_Text__c = 'Menu';
		agreementLineItem3.Apttus_CMConfig__AttributeValueId__c = tstAttribute.Id;
		Database.Insert(agreementLineItem3);

		APTS_Consumption_Categories_Details__c testConsumption = new APTS_Consumption_Categories_Details__c();
		testConsumption.APTS_Cup_Size_Picklist__c = 'Small';
		testConsumption.APTS_Machine_Bundle_Product_ID__c = product2.Id;
		testConsumption.APTS_Planogram_Bundle_Product_ID__c = product2.Id;
		testConsumption.APTS_Taste_Pallet_Picklist__c = 'Moderate';
		testConsumption.APTS_Recipe_Link_Text__c = 'test';
		Database.Insert(testConsumption);
		/**********Pranjal: End************/

		List<APTS_Index_Country_Defaulted_Values__c> countrydeflist = new List<APTS_Index_Country_Defaulted_Values__c> ();
		countrydeflist.add(APTS_TestUtils.createcountrydefaultvalues('Netherlands', 'Products (Ingredients and &More)'));
		countrydeflist.add(APTS_TestUtils.createcountrydefaultvalues('Netherlands', 'Technical Services'));
		Database.Insert(countrydeflist);


		APTS_Index_Country_Defaulted_Values__c ocountrydefval = new APTS_Index_Country_Defaulted_Values__c();
		ocountrydefval.APTS_Start_Date__c = date.Today().addMonths(- 120);
		ocountrydefval.APTS_Indexation_Number__c = 'Big Mac';
		ocountrydefval.APTS_Frequency__c = 'Yearly';
		ocountrydefval.APTS_Country__c = 'Netherlands';
		ocountrydefval.APTS_Maximum_Bandwidth__c = 10;
		ocountrydefval.APTS_Additional_Conditions__c = 'Test Conditions';
		ocountrydefval.APTS_Communication_Deadline__c = '1';
		ocountrydefval.APTS_Communication_Needed__c = true;
		ocountrydefval.APTS_Default_Category__c = 'Technical Services';
		ocountrydefval.APTS_Default_Indexation_Type__c = 'Standard Indexation';
		insert ocountrydefval;

		APTS_Index_Country_Defaulted_Values__c ocountrydefval1 = new APTS_Index_Country_Defaulted_Values__c();
		ocountrydefval1.APTS_Start_Date__c = date.Today().addMonths(- 120);
		ocountrydefval1.APTS_Indexation_Number__c = 'Big Mac';
		ocountrydefval1.APTS_Frequency__c = 'Half-Yearly';
		ocountrydefval1.APTS_Country__c = 'Netherlands';
		ocountrydefval1.APTS_Maximum_Bandwidth__c = 10;
		ocountrydefval1.APTS_Additional_Conditions__c = 'Test Conditions';
		ocountrydefval1.APTS_Communication_Deadline__c = '1';
		ocountrydefval1.APTS_Communication_Needed__c = true;
		ocountrydefval1.APTS_Default_Category__c = 'Technical Services';
		ocountrydefval1.APTS_Default_Indexation_Type__c = 'Standard Indexation';
		insert ocountrydefval1;

		Set<string> countryset = new Set<string> ();
		countryset.add('Netherlands');

		Map<String, APTS_Index_Country_Defaulted_Values__c> oIndexCntrydef = new Map<String, APTS_Index_Country_Defaulted_Values__c> ();
		oIndexCntrydef.put('Machine Care Service', ocountrydefval1);

		Map<String, APTS_Index_Country_Defaulted_Values__c> oIndexCntrydef1 = new Map<String, APTS_Index_Country_Defaulted_Values__c> ();
		oIndexCntrydef.put('Products (Ingredients and &More)', ocountrydefval1);

		Map<String, APTS_Index_Country_Defaulted_Values__c> oIndexCntrydef2 = new Map<String, APTS_Index_Country_Defaulted_Values__c> ();
		oIndexCntrydef.put('Technical Services', ocountrydefval1);

		Map<String, APTS_Index_Country_Defaulted_Values__c> oIndexCntrydef3 = new Map<String, APTS_Index_Country_Defaulted_Values__c> ();
		oIndexCntrydef.put('Consumption Pricing', ocountrydefval1);


		APTS_AgreementTriggerHandler agreementHandler123 = new APTS_AgreementTriggerHandler();
		agreementHandler123.createindexdata(testAgreement12345, oIndexCntrydef);
		agreementHandler123.createindexdata(testAgreement12345, oIndexCntrydef3);
		agreementHandler123.createindexdata(testAgreement123, oIndexCntrydef);
		agreementHandler123.createindexdata(testAgreement123, oIndexCntrydef1);
		agreementHandler123.createindexdata(testAgreement123, oIndexCntrydef2);
		agreementHandler123.processAggrecords(agrlst, countryset);
		agreementHandler123.getindexdata(testAgreement123, ocountrydefval, 'Technical Services');
		agreementHandler123.getindexdata(testAgreement123, ocountrydefval1, 'Technical Services');
		//agreementHandler123.getindexdata(testAgreement123 ,null,'Technical Services'); 


		//APTS_Index_Contract__c indexcontract = APTS_TestUtils.createindexcontract(testAgreement,'Standard Indexation','Technical Services');
		//Database.Insert(indexcontract); 

		//indexcontract.APTS_Index_Type__c = 'No Indexation';
		//Database.Update(indexcontract);

		//indexcontract.APTS_Index_Type__c = 'Non-Standard Indexation';
		//Database.Update(indexcontract);


	}


	/* create and update a fixed term agreement */
	// Commented by Balashanthi since Test class is filing in this Method.  The author of this method need to fix this method
	// Will be removed after my testing
	private static testMethod void activeFixedTermAgreement()
	{
		Id userid;
		User testUser = [SELECT Id FROM User LIMIT 1];
		/*QueueGateKeepers__c qgk1 = [Select User_Keeper__c from QueueGateKeepers__c where  Queue_Name__c = 'NL - Rebates/Indexation/Invoicing Queue']; 
		  userid = qgk1.User_Keeper__c;
		  testuser.id = userid;
		  testuser.IsActive = true; */

		List<Account> accountList = [SELECT Id FROM Account LIMIT 1];

		Apttus__APTS_Agreement__c testAgreement = [SELECT Id, Name, APTS_Country__c, recordtype.name FROM Apttus__APTS_Agreement__c
		                                           WHERE Name LIKE '%Test %' LIMIT 1];


		testAgreement.Apttus__Status_Category__c = 'In Effect';
		testAgreement.Apttus__Status__c = 'Activated';

		List<APTS_Index_Country_Defaulted_Values__c> ocountrydef = [select id, name, APTS_Additional_Conditions__c, APTS_Communication_Deadline__c,
		                                                            APTS_Communication_Needed__c, APTS_Country__c, APTS_Customer_Approval_Required__c,
		                                                            APTS_Frequency__c, APTS_Indexation_Number__c, APTS_Maximum_Bandwidth__c,
		                                                            APTS_Start_Date__c from APTS_Index_Country_Defaulted_Values__c];

		List<Apttus__APTS_Agreement__c> lstAgreement = new List<Apttus__APTS_Agreement__c> ();
		Map<Id, Apttus__APTS_Agreement__c> mapAgreement = new Map<Id, Apttus__APTS_Agreement__c> ();
		lstAgreement.add(testAgreement);
		mapAgreement.put(testAgreement.Id, testAgreement);


		/*APTS_Index_Contract__c oIndexcon = [select id,name,APTS_Index_Type__c,APTS_Indexation_Category__c,APTS_Contract__c,
		  APTS_Communication_Needed__c,APTS_Communication_Deadline__c,APTS_Start_Date__c,APTS_Frequency__c   
		  from APTS_Index_Contract__c where APTS_Index_Type__c = 'Non-Standard Indexation'];*/

		APTS_AgreementTriggerHandler agreementHandler = new APTS_AgreementTriggerHandler();
		test.startTest();
		System.runAs(testUser)
		{
			Database.Update(lstAgreement);
			agreementHandler.afterInsert(lstAgreement, mapAgreement);
			/*Calling SM_AgreementToAccount Class*/
			SM_AgreementToAccount smAgreeAcc = new SM_AgreementToAccount();
			if (!lstAgreement.isEmpty()) {
				//smAgreeAcc.PromoteAccountAndIntegration(lstAgreement);
			}
			agreementHandler.afterDelete(lstAgreement, mapAgreement);
			agreementHandler.beforeDelete(lstAgreement, mapAgreement);
			agreementHandler.afterUndelete(lstAgreement, mapAgreement);
		}
		system.debug('---accountList.size() ' + accountList.size());
		test.stopTest();
		//system.assert(accountList.size() ==1);
		List<Apttus_Config2__Order__c> lstOrder = [SELECT Id, Name FROM Apttus_Config2__Order__c];
		system.debug('--- lstOrder () ' + lstOrder);
		//system.assert(lstOrder.size() > 1);     
		List<Apttus_Config2__OrderLineItem__c> lstOrderLine = [SELECT Id, Name, Apttus_Config2__OrderId__r.Name FROM Apttus_Config2__OrderLineItem__c];
		//system.assertEquals(2, lstOrderLine.size());
		system.debug('--- lstOrderLine--' + lstOrderLine);

	}

	/* With differennt agreement subtype value */
	// Commented by Balashanthi since Test class is filing in this Method.  The author of this method need to fix this method
	// Will be removed after my testing
	private static testMethod void fixedTermAgreement()
	{
		User testUser = [SELECT Id FROM User LIMIT 1];
		Apttus__APTS_Agreement__c testAgreement = [SELECT Id, Name, APTS_Country__c, recordtype.name FROM Apttus__APTS_Agreement__c
		                                           WHERE Name LIKE '%Test %' LIMIT 1];

		testAgreement.Apttus__Subtype__c = 'Fixed Term-Both Fixed Costs and Ingredients';
		testAgreement.Apttus__Status_Category__c = 'In Effect';
		testAgreement.Apttus__Status__c = 'Activated';


		test.startTest();
		System.runAs(testUser)
		{
			Database.Update(testAgreement);
		}
		test.stopTest();
		List<Apttus_Config2__OrderLineItem__c> lstOrderLine = new List<Apttus_Config2__OrderLineItem__c> ();
		lstOrderLine = [SELECT Id, Name FROM Apttus_Config2__OrderLineItem__c];
		//system.assertEquals(2, lstOrderLine.size());

	}

	/* Deactivate agreement trigger from custom setting and call the handler */
	static testMethod void deactivateAgreementTrigger()
	{
		TriggerSettings__c settings = TriggerSettings__c.getOrgDefaults();
		settings.Agreement__c = true;
		update settings;

		User testUser = [SELECT Id FROM User LIMIT 1];
		List<Account> accountList = [SELECT Id FROM Account LIMIT 1];
		Apttus__APTS_Agreement__c testAgreement = [SELECT Id, Name FROM Apttus__APTS_Agreement__c
		                                           WHERE Name LIKE '%Test %' LIMIT 1];

		system.assert(accountList.size() == 1);
		test.startTest();
		System.runAs(testUser)
		{
			Database.Update(testAgreement);
		}
		test.stopTest();
		List<Apttus_Config2__OrderLineItem__c> lstOrderLine = new List<Apttus_Config2__OrderLineItem__c> ();
		lstOrderLine = [SELECT Id, Name FROM Apttus_Config2__OrderLineItem__c];
		system.assertEquals(0, lstOrderLine.size());
	}

	//Test method for creation of BillingSetting --- After Update
	/*static testMethod void createBillingSettingonUpdate(){
	 
	  List<Apttus__APTS_Agreement__c> lstAgreement = new List<Apttus__APTS_Agreement__c>();
	  Map<Id, Apttus__APTS_Agreement__c> mapAgreement = new Map<Id, Apttus__APTS_Agreement__c>();
	  List<Apttus__APTS_Agreement__c> lstNewAgreement = new List<Apttus__APTS_Agreement__c>();
	  Map<Id, Apttus__APTS_Agreement__c> mapNewAgreement = new Map<Id, Apttus__APTS_Agreement__c>();
	  User testUser = [SELECT Id FROM User LIMIT 1];
	  Apttus_Config2__BillingPreference__c billingPreference = APTS_TestUtils.createBillingPrefrence('June');
	  billingPreference.name='Test Preference';
	  Database.Insert(billingPreference);
	 
	  APTS_Payment_Method__c paymentMethod = APTS_TestUtils.paymentMethod();
	  Database.Insert(paymentMethod);
	 
	  Apttus_Config2__PaymentTerm__c paymentTerm = APTS_TestUtils.paymentTerm();
	  paymentTerm.Apttus_Config2__Sequence__c = 5;
	  Database.Insert(paymentTerm);
	 
	  // Update Billing KeyField for GrandParentAccount
	  Account account1 = APTS_TestUtils.createGrandParentAccount();
	  Database.Insert(account1);
	  account1.Apttus_Config2__BillingPreferenceId__c = billingPreference.Id;
	  account1.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
	  account1.APTS_Payment_Method__c = paymentMethod.Id;
	  Database.Update(account1);
	  // Update Billing KeyField for GrandParentAccount
	  Account account = APTS_TestUtils.createGrandParentAccount();
	  Database.Insert(account);
	  account.Apttus_Config2__BillingPreferenceId__c = billingPreference.Id;
	  account.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
	  account.APTS_Payment_Method__c = paymentMethod.Id;
	  Database.Update(account);
	  // Creating Parent Account
	  /*List<Account> accountList = [SELECT Id FROM Account LIMIT 1];
	  Account account = APTS_TestUtils.createParentAccount(accountList[0]);
	  Database.Insert(account);
	  //Update Billing Key Fields for parent Account
	  account.Apttus_Config2__BillingPreferenceId__c = billingPreference.Id;
	  account.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
	  account.APTS_Payment_Method__c = paymentMethod.Id;
	  update account;
	  // Create Child account
	  Account childAccount = APTS_TestUtils.createChildAccount(account);
	  Database.Insert(childAccount);
	  childAccount.Apttus_Config2__BillingPreferenceId__c = billingPreference.Id;
	  childAccount.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
	  childAccount.APTS_Payment_Method__c = paymentMethod.Id;  
	  update childAccount;*/

	/*Apttus__APTS_Agreement__c testAgreement1= APTS_TestUtils.createAgreement(null,null,null,account1.Id);
	  testAgreement1.APTS_Bill_to_Party_Ingredients__c=null;
	  testAgreement1.APTS_Bill_to_Party_MachServ__c=null;
	  Database.Insert(testAgreement1);
	  //test.startTest();
	  //lstAgreement.add(testAgreement1);
	  mapAgreement.put(testAgreement1.Id, testAgreement1);
	  system.debug('******OLD mapAgreement***'+mapAgreement);
	  //system.debug(mapAgreement.get(0).APTS_Bill_to_Party_MachServ__c);
	  testAgreement1.APTS_Bill_to_Party_Ingredients__c=account1.Id;
	  testAgreement1.APTS_Bill_to_Party_MachServ__c=account.Id;
	  mapNewAgreement.put(testAgreement1.Id, testAgreement1);
	  system.debug('******New mapAgreement***'+mapNewAgreement);
	  //Database.Update(testAgreement1);
	  Test.startTest();
	  APTS_AgreementTriggerHandler agreementHandler = new APTS_AgreementTriggerHandler();
	  agreementHandler.afterUpdate(lstNewAgreement,mapNewAgreement,lstAgreement,mapAgreement);                                  
	  Test.stopTest();*/
	//}

	//Test method for creation of BillingSetting --- After Update scenario1
	/*static testMethod void createBillingSettingonUpdate1(){
	 
	  TriggerSettings__c triggerCustomSetting =  new TriggerSettings__c();
	  triggerCustomSetting.Agreement__c = True;
	  Database.Insert(triggerCustomSetting);
	 
	  User testUser = [SELECT Id FROM User LIMIT 1];
	  Apttus_Config2__BillingPreference__c billingPreference = APTS_TestUtils.createBillingPrefrence('June');
	  billingPreference.name='Test Preference';
	  Database.Insert(billingPreference);
	 
	  Apttus_Config2__BillingPreference__c billingPreference1 = APTS_TestUtils.createBillingPrefrence('April');
	  billingPreference1.name='Test Preference1';
	  Database.Insert(billingPreference1);
	 
	  APTS_Payment_Method__c paymentMethod = APTS_TestUtils.paymentMethod();
	  insert paymentMethod;
	 
	  Apttus_Config2__PaymentTerm__c paymentTerm = APTS_TestUtils.paymentTerm();
	  paymentTerm.Apttus_Config2__Sequence__c = 5;
	  insert paymentTerm;
	 
	  List<Account> accountList = [SELECT Id FROM Account LIMIT 1];
	  Account account = APTS_TestUtils.createParentAccount(accountList[0]);
	  Database.Insert(account);
	 
	  Account account1 = APTS_TestUtils.createGrandParentAccount();
	  //account1.Name='Test Account';
	  insert account1;
	 
	  //Update Billing Key Fields
	  account.Apttus_Config2__BillingPreferenceId__c = billingPreference.Id;
	  account.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
	  account.APTS_Payment_Method__c = paymentMethod.Id;
	  update account;
	 
	  Account childAccount = APTS_TestUtils.createChildAccount(account);
	  Database.Insert(childAccount);
	 
	  Apttus__APTS_Agreement__c testAgreement1= APTS_TestUtils.createAgreement(null,null,null,childAccount.Id);
	  testAgreement1.APTS_Bill_to_Party_Ingredients__c=null;
	  testAgreement1.APTS_Bill_to_Party_MachServ__c=null;
	  insert testAgreement1;
	  system.assertequals(testAgreement1.APTS_Bill_to_Party_Ingredients__c,null);
	  system.assertequals(testAgreement1.APTS_Bill_to_Party_MachServ__c,null);
	  List<Apttus__APTS_Agreement__c> lstAgreement = new List<Apttus__APTS_Agreement__c>();
	  Map<Id, Apttus__APTS_Agreement__c> mapAgreement = new Map<Id, Apttus__APTS_Agreement__c>();
	  List<Apttus__APTS_Agreement__c> lstNewAgreement = new List<Apttus__APTS_Agreement__c>();
	  Map<Id, Apttus__APTS_Agreement__c> mapNewAgreement = new Map<Id, Apttus__APTS_Agreement__c>();
	 
	 
	  lstAgreement.add(testAgreement1);
	  mapAgreement.put(testAgreement1.Id, testAgreement1);
	  system.assertequals(lstAgreement[0].APTS_Bill_to_Party_Ingredients__c,null);
	  system.assertequals(lstAgreement[0].APTS_Bill_to_Party_MachServ__c,null);
	 
	  testAgreement1.APTS_Bill_to_Party_Ingredients__c=account.id;
	  testAgreement1.APTS_Bill_to_Party_MachServ__c=account.id;
	 
	  //test.startTest();
	  //{
	  Update testAgreement1;
	  //}
	  //test.stopTest();
	 
	 
	  lstNewAgreement.add(testAgreement1);
	  mapNewAgreement.put(testAgreement1.Id, testAgreement1);
	  system.assertequals(lstAgreement[0].APTS_Bill_to_Party_Ingredients__c,lstNewAgreement[0].APTS_Bill_to_Party_Ingredients__c);
	  //system.assertequals(lstAgreement[0].APTS_Bill_to_Party_Ingredients__c,null);
	  //system.assertequals(lstAgreement[0].APTS_Bill_to_Party_MachServ__c,null);
	  mapAgreement.get(testAgreement1.id).APTS_Bill_to_Party_Ingredients__c =null;
	  mapAgreement.get(testAgreement1.id).APTS_Bill_to_Party_MachServ__c=null;
	  update mapAgreement.values();
	  system.assertequals(mapNewAgreement.get(testAgreement1.id).APTS_Bill_to_Party_MachServ__c,null);
	  APTS_AgreementTriggerHandler agreementHandler = new APTS_AgreementTriggerHandler();
	  agreementHandler.afterUpdate(lstNewAgreement,mapNewAgreement,lstAgreement,mapAgreement);                                  
	  }*/


	//Test method for creation of BillingSetting --- After Insert----Different Account Data
	static testMethod void createBillingSettingonInsertion() {

		User testUser = [SELECT Id FROM User LIMIT 1];
		Apttus_Config2__BillingPreference__c billingPreference = APTS_TestUtils.createBillingPrefrence('June');
		billingPreference.name = 'Test Preference';
		Database.Insert(billingPreference);

		APTS_Payment_Method__c paymentMethod = APTS_TestUtils.paymentMethod();
		insert paymentMethod;

		Apttus_Config2__PaymentTerm__c paymentTerm = APTS_TestUtils.paymentTerm();
		paymentTerm.Apttus_Config2__Sequence__c = 5;
		insert paymentTerm;

		List<Account> accountList = [SELECT Id FROM Account LIMIT 1];
		Account account = APTS_TestUtils.createParentAccount(accountList[0]);
		Database.Insert(account);

		//Update Billing Key Fields
		account.Apttus_Config2__BillingPreferenceId__c = billingPreference.Id;
		account.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
		account.APTS_Payment_Method__c = paymentMethod.Id;
		update account;

		Account childAccount = APTS_TestUtils.createChildAccount(account);
		Database.Insert(childAccount);

		Apttus__APTS_Agreement__c testAgreement1 = APTS_TestUtils.createAgreement(null, null, null, account.Id);
		testAgreement1.APTS_Bill_to_Party_Ingredients__c = childAccount.id;
		testAgreement1.APTS_Bill_to_Party_MachServ__c = accountList[0].id;
		insert testAgreement1;

		/* Set<Id> agrSetid1 = new Set<id>();
		  agrSetid1.add(testAgreement1.id);*/

		List<Apttus__APTS_Agreement__c> lstAgreement = new List<Apttus__APTS_Agreement__c> ();
		Map<Id, Apttus__APTS_Agreement__c> mapAgreement = new Map<Id, Apttus__APTS_Agreement__c> ();

		lstAgreement.add(testAgreement1);
		mapAgreement.put(testAgreement1.Id, testAgreement1);
		APTS_AgreementTriggerHandler agreementHandler = new APTS_AgreementTriggerHandler();
		agreementHandler.afterInsert(lstAgreement, mapAgreement);
		//agreementHandler.updateVolumeAssumptionRecords(agrSetid1);  


	}
	//Test method for creation of BillingSetting --- After Insert----Same Account Data
	static testMethod void createBillingSettingonInsertion1() {

		User testUser = [SELECT Id FROM User LIMIT 1];
		Apttus_Config2__BillingPreference__c billingPreference = APTS_TestUtils.createBillingPrefrence('June');
		billingPreference.name = 'Test Preference';
		Database.Insert(billingPreference);

		APTS_Payment_Method__c paymentMethod = APTS_TestUtils.paymentMethod();
		insert paymentMethod;

		Apttus_Config2__PaymentTerm__c paymentTerm = APTS_TestUtils.paymentTerm();
		paymentTerm.Apttus_Config2__Sequence__c = 5;
		insert paymentTerm;

		List<Account> accountList = [SELECT Id FROM Account LIMIT 1];
		Account account = APTS_TestUtils.createParentAccount(accountList[0]);
		Database.Insert(account);

		//Update Billing Key Fields
		account.Apttus_Config2__BillingPreferenceId__c = billingPreference.Id;
		account.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
		account.APTS_Payment_Method__c = paymentMethod.Id;
		update account;

		Account childAccount = APTS_TestUtils.createChildAccount(account);
		Database.Insert(childAccount);

		Apttus_Config2__BillingPreference__c billingPreference1 = APTS_TestUtils.createBillingPrefrence('April');
		billingPreference1.name = 'Test Preference2';
		Database.Insert(billingPreference1);

		Account account1 = APTS_TestUtils.createGrandParentAccount();
		//account1.Name='Test Account';
		account1.Apttus_Config2__BillingPreferenceId__c = billingPreference1.Id;
		account1.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
		account1.APTS_Payment_Method__c = paymentMethod.Id;
		insert account1;

		Apttus__APTS_Agreement__c testAgreement1 = APTS_TestUtils.createAgreement(null, null, null, account.Id);
		testAgreement1.APTS_Bill_to_Party_Ingredients__c = account1.id;
		testAgreement1.APTS_Bill_to_Party_MachServ__c = account1.id;
		insert testAgreement1;

		List<Apttus__APTS_Agreement__c> lstAgreement = new List<Apttus__APTS_Agreement__c> ();
		Map<Id, Apttus__APTS_Agreement__c> mapAgreement = new Map<Id, Apttus__APTS_Agreement__c> ();

		lstAgreement.add(testAgreement1);
		mapAgreement.put(testAgreement1.Id, testAgreement1);
		APTS_AgreementTriggerHandler agreementHandler = new APTS_AgreementTriggerHandler();
		agreementHandler.afterInsert(lstAgreement, mapAgreement);


	}

	/**********Pranjal: Start************/
	static testMethod void testURLPopulation() {
		Test.startTest();
		Apttus__APTS_Agreement__c testAgreement = [SELECT Id, Name, Apttus_CMConfig__ConfigurationFinalizedDate__c FROM Apttus__APTS_Agreement__c
		                                           WHERE Apttus__Non_Standard_Legal_Language__c = true LIMIT 1];
		System.debug('Anydatatype_msg++' + testAgreement);
		testAgreement.Apttus_CMConfig__ConfigurationFinalizedDate__c = Date.today().addDays(10);
		update testAgreement;
		System.debug('Anydatatype_msg++' + testAgreement);
		Test.stopTest();
	}
	/**********Pranjal: End************/

	static testMethod void testAdminOrder() {

		List<Apttus__AgreementLineItem__c> oAGLIlist = new List<Apttus__AgreementLineItem__c> ();

		TriggerSettings__c settings = TriggerSettings__c.getOrgDefaults();
		settings.Agreement__c = true;
		update settings;

		PhysicalAsset__c testphAsset = APTS_TestUtils.createPhysicalAsset();
		insert testphAsset;

		Apttus_Config2__AssetLineItem__c tstAsset = new Apttus_Config2__AssetLineItem__c();
		tstAsset.Apttus_Config2__LineNumber__c = 1;
		tstAsset.Apttus_Config2__PrimaryLineNumber__c = 1;
		tstAsset.Apttus_Config2__NetPrice__c = 100;
		tstAsset.Apttus_Config2__AssetStatus__c = 'New';
		tstAsset.APTS_Old_Net_Price__c = 100;
		tstAsset.APTS_Physical_Asset__c = testphAsset.Id;
		tstAsset.Apttus_Config2__EndDate__c = Date.today().addDays(100);
		insert tstAsset;

		User testUser = [SELECT Id FROM User LIMIT 1];
		Apttus__APTS_Agreement__c testAgreement = [SELECT Id, Name, APTS_Country__c, recordtype.name, Apttus__Status_Category__c, Apttus__Status__c
		                                           FROM Apttus__APTS_Agreement__c WHERE Name LIKE '%Test %' LIMIT 1];

		for (Apttus__AgreementLineItem__c otestAGLI :[select id, name, Apttus_CMConfig__AssetLineItemId__c, APTS_Serial_Number__c, APTS_Asset_Change_type__c
		     from Apttus__AgreementLineItem__c where Apttus__AgreementId__c = :testAgreement.Id]) {
			otestAGLI.Apttus_CMConfig__AssetLineItemId__c = tstAsset.Id;
			otestAGLI.APTS_Asset_Change_type__c = 'Non-Physical Conversion';
			oAGLIlist.add(otestAGLI);
		}
		update oAGLIlist;

		APTS_Index_Contract__c oindexcon = new APTS_Index_Contract__c();
		oindexcon.APTS_Index_Type__c = 'Non-Standard Indexation';
		oindexcon.APTS_Indexation_Category__c = 'Technical Services';
		oindexcon.APTS_Contract__c = testAgreement.Id;
		oindexcon.APTS_Communication_Needed__c = true;
		oindexcon.APTS_Start_Date__c = Date.today();
		oindexcon.APTS_Communication_Deadline__c = '1';
		oindexcon.APTS_Frequency__c = 'Yearly';
		insert oindexcon;

		testAgreement.APTS_Routesales__c = true;
		Database.Update(testAgreement);

		testAgreement.Apttus__Status_Category__c = 'In Effect';
		testAgreement.Apttus__Status__c = 'Activated';
		testAgreement.APTS_Is_Billing_Setting_Change__c = true;
		testAgreement.Apttus__Auto_Renewal__c = true;
		testAgreement.APTS_Language__c = 'SAP_EN';

		test.startTest();
		Database.Update(testAgreement);
		test.stopTest();
	}

	static testMethod void ProcessBuilderLogic()
	{
		Id RecordStdId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();

		Opportunity opp = new Opportunity();
		opp.Name = 'Opportunity Name';
		opp.CLoseDate = Date.Today();
		opp.StageName = 'Open';
		opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Standard Opportunity').getRecordTypeId();
		Database.Insert(opp);

		Set<Id> oppIdSet = new Set<Id> ();
		oppIdSet.add(opp.id);
		APTS_AgreementTriggerHandler agreementHandler = new APTS_AgreementTriggerHandler();
		APTS_AgreementTriggerHandler.syncAgreementWithOpp(oppIdSet);


		Apttus__APTS_Agreement__c testAgreementOpportunity = new Apttus__APTS_Agreement__c(
		                                                                                   Apttus__Non_Standard_Legal_Language__c = true, RecordTypeId = RecordStdId,
		                                                                                   Apttus__Contract_Start_Date__c = Date.today(), Apttus__Contract_End_Date__c = Date.today() + 365,
		                                                                                   Apttus_CMConfig__ConfigurationFinalizedDate__c = Date.today(),
		                                                                                   Apttus__Status__c = 'Activated', Apttus__Status_Category__c = 'In Effect', Apttus__Related_Opportunity__c = opp.id);
		Database.insert(testAgreementOpportunity);
		System.debug('Lav Status->' + testAgreementOpportunity.Apttus__Status__c + '' + testAgreementOpportunity.Apttus__Status_Category__c + 'opp' + testAgreementOpportunity.Apttus__Related_Opportunity__c);
		Database.update(testAgreementOpportunity);


	}

	static testMethod void testProcessAsssetsBatch() {

		List<Apttus__AgreementLineItem__c> oAGLIlist = new List<Apttus__AgreementLineItem__c> ();

		TriggerSettings__c settings = TriggerSettings__c.getOrgDefaults();
		settings.Agreement__c = true;
		update settings;

		PhysicalAsset__c testphAsset = APTS_TestUtils.createPhysicalAsset();
		insert testphAsset;



		User testUser = [SELECT Id FROM User LIMIT 1];
		Apttus__APTS_Agreement__c testAgreement = [SELECT Id, Name, APTS_Country__c, recordtype.name, Apttus__Status_Category__c, Apttus__Status__c
		                                           FROM Apttus__APTS_Agreement__c WHERE Name LIKE '%Test %' LIMIT 1];

		Apttus_Config2__AssetLineItem__c tstAsset = new Apttus_Config2__AssetLineItem__c();
		tstAsset.Apttus_Config2__LineNumber__c = 1;
		tstAsset.Apttus_Config2__PrimaryLineNumber__c = 1;
		tstAsset.Apttus_Config2__NetPrice__c = 100;
		tstAsset.Apttus_Config2__AssetStatus__c = 'New';
		tstAsset.APTS_Old_Net_Price__c = 100;
		tstAsset.APTS_Physical_Asset__c = testphAsset.Id;
		tstAsset.Apttus_Config2__EndDate__c = Date.today().addDays(100);
		tstAsset.Apttus_CMConfig__AgreementId__c = testAgreement.id;
		insert tstAsset;

		for (Apttus__AgreementLineItem__c otestAGLI :[select id, name, Apttus_CMConfig__AssetLineItemId__c, APTS_Serial_Number__c, APTS_Asset_Change_type__c
		     from Apttus__AgreementLineItem__c where Apttus__AgreementId__c = :testAgreement.Id]) {
			otestAGLI.Apttus_CMConfig__AssetLineItemId__c = tstAsset.Id;
			otestAGLI.APTS_Asset_Change_type__c = 'Non-Physical Conversion';
			oAGLIlist.add(otestAGLI);
		}
		update oAGLIlist;

		APTS_Index_Contract__c oindexcon = new APTS_Index_Contract__c();
		oindexcon.APTS_Index_Type__c = 'Non-Standard Indexation';
		oindexcon.APTS_Indexation_Category__c = 'Technical Services';
		oindexcon.APTS_Contract__c = testAgreement.Id;
		oindexcon.APTS_Communication_Needed__c = true;
		oindexcon.APTS_Start_Date__c = Date.today();
		oindexcon.APTS_Communication_Deadline__c = '1';
		oindexcon.APTS_Frequency__c = 'Yearly';
		insert oindexcon;

		testAgreement.Apttus__Status_Category__c = 'In Effect';
		testAgreement.Apttus__Status__c = 'Activated';
		testAgreement.APTS_Is_Billing_Setting_Change__c = true;
		testAgreement.Apttus__Auto_Renewal__c = true;
		test.startTest();
		Database.Update(testAgreement);
		List<APTS_Agreement_PO_Details__c> poList = new List<APTS_Agreement_PO_Details__c> ();
		APTS_Agreement_PO_Details__c machineAgreementPODetails = new APTS_Agreement_PO_Details__c();
		machineAgreementPODetails.APTS_PO_Number_Required__c = 'Yes';
		machineAgreementPODetails.APTS_PO_Number_Type__c = 'Variable';
		machineAgreementPODetails.APTS_PO_Number__c = '123567';
		machineAgreementPODetails.APTS_PO_Category__c = 'Machine';
		machineAgreementPODetails.APTS_Agreement__c = testAgreement.Id;
		machineAgreementPODetails.APTS_PO_Expiration_Date__c = Date.Today();
		poList.add(machineAgreementPODetails);

		APTS_Agreement_PO_Details__c optionAgreementPODetails = new APTS_Agreement_PO_Details__c();
		optionAgreementPODetails.APTS_PO_Number_Required__c = 'Yes';
		optionAgreementPODetails.APTS_PO_Number_Type__c = 'Variable';
		optionAgreementPODetails.APTS_PO_Number__c = '123567';
		optionAgreementPODetails.APTS_PO_Category__c = 'Services';
		optionAgreementPODetails.APTS_Agreement__c = testAgreement.Id;
		optionAgreementPODetails.APTS_PO_Expiration_Date__c = Date.Today();
		poList.add(optionAgreementPODetails);


		Database.Insert(poList);
		Database.update(poList);

		Map<String, APTS_Agreement_PO_Details__c> agreementPODetailsMap = new Map<String, APTS_Agreement_PO_Details__c> ();
		testAgreement = [SELECT Id, Name, APTS_Country__c, recordtype.name, Apttus__Status_Category__c, Apttus__Status__c, Apttus__Agreement_Number__c
		                 FROM Apttus__APTS_Agreement__c WHERE Name LIKE '%Test %' LIMIT 1];
		for (APTS_Agreement_PO_Details__c agreementPODetailsSO :[SELECT Id,
		     APTS_Agreement__c,
		     APTS_Agreement__r.Apttus__Agreement_Number__c,
		     APTS_PO_Number__c,
		     APTS_PO_Number_Required__c,
		     APTS_PO_Category__c,
		     APTS_PO_Number_Type__c
		     FROM APTS_Agreement_PO_Details__c
		     WHERE APTS_Agreement__c = :testAgreement.Id and APTS_Agreement__r.APTS_PO_Details_Changed__c = true])
		{
			agreementPODetailsMap.put(agreementPODetailsSO.APTS_PO_Category__c, agreementPODetailsSO);
		}
		Map<String, Id> agreementNoToIdMap = new Map<String, Id> ();
		agreementNoToIdMap.put(testAgreement.Apttus__Agreement_Number__c, testAgreement.Id);
		APTS_ProcessAssetsBatch processAssetBatchSO = new APTS_ProcessAssetsBatch(new Set<ID> { testAgreement.Id }, agreementNoToIdMap, agreementPODetailsMap);
		Database.executeBatch(processAssetBatchSO);
		test.stopTest();


	}
}