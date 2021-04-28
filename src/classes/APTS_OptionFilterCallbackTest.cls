@isTest
private class APTS_OptionFilterCallbackTest {
	
	@isTest static void test_optionFilter() {
		Id regFormRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Consumption Model').getRecordTypeId();
		test.startTest();
		User otestuser = APTS_TestDataFactory.createUser();
        Database.insert(otestuser);
        System.runAs(otestuser){
        	Account oAccount = APTS_TestDataFactory.createAccount('JDETestAccount');
	        Database.insert(oAccount, FALSE);

	        // create contact
	        Contact oContact = APTS_TestDataFactory.createContact(oAccount,'1010101011');
	        Database.insert(oContact, FALSE);

	        // create opportunity
	        opportunity opportunityObj = APTS_TestDataFactory.createOpportunity('JDETestOpportunity', oAccount.Id);
	        Database.insert(opportunityObj, FALSE);

	        //create price list
	        Apttus_Config2__PriceList__c pricelist = APTS_TestDataFactory.createPriceList('JDETest Price List');
	        Database.insert(pricelist, FALSE);

	        //Create Products
	        List<Product2> prodList = new List<Product2>();
	        Product2 prod1 = APTS_TestDataFactory.createProduct('JDETestAccount', 'JDETestAccount', 'JDETestAccount', 'Standalone', FALSE, FALSE);
	        Product2 prod2 = APTS_TestDataFactory.createProduct('JDETestAccount', 'JDETestAccount', 'JDETestAccount', 'Standalone', FALSE, FALSE);
	        prodList.add(prod1);
	        prodList.add(prod2);
	        Database.insert(prodList, FALSE);

	        Apttus__APTS_Agreement__c agrmt = APTS_TestDataFactory.createAgreement(oContact.id, priceList.id, oAccount.id, 'Standard Deal');
	        agrmt.RecordTypeId=regFormRecordTypeId;
	        Database.insert(agrmt,false);

	        System.debug('agrmt========>'+agrmt);

	        Apttus_Config2__ProductConfiguration__c config = APTS_TestDataFactory.createProductConfig(agrmt);
	        config.APTS_Flow__c = System.Label.APTS_NGDefault;
	        config.Apttus_Config2__Status__c = 'Saved';
	        config.Apttus_Config2__BusinessObjectId__c=agrmt.id;
	        config.Apttus_CMConfig__AgreementId__c=agrmt.id;
	        Database.insert(config, FALSE);

	        System.debug('config========>'+config);

	        List<ID> productIDS = new List<ID>{prod1.id,prod2.id};

			Apttus_Config2.CustomClass.ActionParams actionParam = new Apttus_Config2.CustomClass.ActionParams();
			actionParam.ConfigurationId = config.id;
			actionParam.productIDs = productIDS;
			APTS_OptionFilterCallback ofcb = new APTS_OptionFilterCallback();
			List<ID> listIDs = ofcb.getExcludedOptionIds(actionParam);
		} 
		test.stopTest();
	}
	
}