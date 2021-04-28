@isTest
private class APTS_UOMConversionUtils_Test {
	
	@isTest static void productBased() {
		// Implement test code
		Set<String> uomParams = new Set<String>();
		List<Apttus_Config2__FrequencyConversionRate__c> freqList=new List<Apttus_Config2__FrequencyConversionRate__c>();

		test.startTest();
		User testUser = APTS_TestDataFactory.createUser();
        testUser.Email = 'testuser123@jdecoffee.com';
        system.runAs(testUser){
	        Apttus_Config2__FrequencyConversionRate__c fre=new Apttus_Config2__FrequencyConversionRate__c();
	        fre.Apttus_Config2__FromUom__c ='SAP_PCE';
	        fre.Apttus_Config2__ToUom__c  ='SAP_BX';
	        fre.APTS_ProductCode__c='12345';
	        fre.Apttus_Config2__ConversionFactor__c=1000;

	        Apttus_Config2__FrequencyConversionRate__c fre1=new Apttus_Config2__FrequencyConversionRate__c();
	        fre1.Apttus_Config2__FromUom__c ='SAP_PCE';
	        fre1.Apttus_Config2__ToUom__c  ='SAP_PCE';
	        fre1.APTS_ProductCode__c='12345';
	        fre1.Apttus_Config2__ConversionFactor__c=1000;

	        freqList.add(fre);
	        freqList.add(fre1);

	        Database.insert(freqList);

			uomParams.add('12345;SAP_PCE;SAP_BX');
			uomParams.add('12345;SAP_PCE;SAP_PCE');
			APTS_UOMConversionUtils.getUOMConversions(uomParams);
		}
		test.stopTest();
	}
	
	@isTest static void categorybased() {
		// Implement test code
		Set<String> uomParams = new Set<String>();
		List<Apttus_Config2__FrequencyConversionRate__c> freqList=new List<Apttus_Config2__FrequencyConversionRate__c>();

		test.startTest();
		User testUser = APTS_TestDataFactory.createUser();
        testUser.Email = 'testuser123@jdecoffee.com';
        system.runAs(testUser){
	        Apttus_Config2__FrequencyConversionRate__c fre=new Apttus_Config2__FrequencyConversionRate__c();
	        fre.Apttus_Config2__FromUom__c ='SAP_PCE';
	        fre.Apttus_Config2__ToUom__c  ='SAP_BX';
	        fre.APTS_Product_Family2__c='Beans';
	        fre.Apttus_Config2__ConversionFactor__c=1000;
	        freqList.add(fre);

	        Apttus_Config2__FrequencyConversionRate__c fre1=new Apttus_Config2__FrequencyConversionRate__c();
	        fre1.Apttus_Config2__FromUom__c ='SAP_PCE';
	        fre1.Apttus_Config2__ToUom__c  ='SAP_PCE';
	        fre1.APTS_Product_Family2__c='Beans';
	        fre1.Apttus_Config2__ConversionFactor__c=1000;
	        freqList.add(fre1);

	        Database.insert(freqList);

			uomParams.add('Beans;SAP_PCE;SAP_BX');
			uomParams.add('Beans;SAP_PCE;SAP_PCE');

			APTS_UOMConversionUtils.getSubcategoryConversions(uomParams);
		}
		test.stopTest();
	}

	@isTest static void subSubCategoryBased() {
		// Implement test code
		Set<String> uomParams = new Set<String>();
		List<Apttus_Config2__FrequencyConversionRate__c> freqList=new List<Apttus_Config2__FrequencyConversionRate__c>();

		test.startTest();
		User testUser = APTS_TestDataFactory.createUser();
        testUser.Email = 'testuser123@jdecoffee.com';
        system.runAs(testUser){
	        Apttus_Config2__FrequencyConversionRate__c fre=new Apttus_Config2__FrequencyConversionRate__c();
	        fre.Apttus_Config2__FromUom__c ='SAP_PCE';
	        fre.Apttus_Config2__ToUom__c  ='SAP_BX';
	        fre.APTS_Product_Family3__c='SAP_010101';
	        fre.Apttus_Config2__ConversionFactor__c=1000;
	        freqList.add(fre);

	        Apttus_Config2__FrequencyConversionRate__c fre1=new Apttus_Config2__FrequencyConversionRate__c();
	        fre1.Apttus_Config2__FromUom__c ='SAP_PCE';
	        fre1.Apttus_Config2__ToUom__c  ='SAP_PCE';
	        fre1.APTS_Product_Family3__c='SAP_010101';
	        fre1.Apttus_Config2__ConversionFactor__c=1000;
	        freqList.add(fre1);

	        Database.insert(freqList);

			uomParams.add('SAP_010101;SAP_PCE;SAP_BX');
			uomParams.add('SAP_010101;SAP_PCE;SAP_PCE');
			APTS_UOMConversionUtils.getSubsubcategoryConversions(uomParams);
		}
		test.stopTest();
	}
	
}