@isTest
private class APTS_CreateUOMsBatch_test {
	
	@isTest static void test_createUOM_usecase1() {
		test.startTest();

		List<Product2> productList = TestDataFactory.createProduct(10);
		insert productList;

		List<Apttus_Config2__FrequencyConversionRate__c> insertFrequencyList = new List<Apttus_Config2__FrequencyConversionRate__c>();
		for(integer i=0;i<productList.size();i++){
			Apttus_Config2__FrequencyConversionRate__c freqConversionBX = new Apttus_Config2__FrequencyConversionRate__c();
			freqConversionBX.Apttus_Config2__ProductId__c=productList[i].id;
			freqConversionBX.Apttus_Config2__ConversionFactor__c=5;
			freqConversionBX.Apttus_Config2__FromUom__c = 'SAP_PCE';
			freqConversionBX.Apttus_Config2__ToUom__c = 'SAP_BX';
			insertFrequencyList.add(freqConversionBX);

			Apttus_Config2__FrequencyConversionRate__c freqConversionPF = new Apttus_Config2__FrequencyConversionRate__c();
			freqConversionPF.Apttus_Config2__ProductId__c=productList[i].id;
			freqConversionPF.Apttus_Config2__ConversionFactor__c=10;
			freqConversionPF.Apttus_Config2__FromUom__c = 'SAP_PCE';
			freqConversionPF.Apttus_Config2__ToUom__c = 'SAP_PF';
			insertFrequencyList.add(freqConversionPF);
		}
		insert insertFrequencyList;
		APTS_CreateUOMsBatchHandler handler = new APTS_CreateUOMsBatchHandler();
		Database.executeBatch(new APTS_CreateUOMsBatch(),200);
		test.stopTest();
	}
}