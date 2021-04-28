@isTest
private class APTS_AgreementExpireCERBatchTest {
	
	static{
		Apttus__APTS_Agreement__c tstAggr = new Apttus__APTS_Agreement__c();
		tstAggr.Apttus__Contract_End_Date__c = Date.today().addDays(-1);
		insert tstAggr;

		APTS_Contract_Entitlement_Repository__c tstCER = new APTS_Contract_Entitlement_Repository__c();
		tstCER.APTS_Agreement_Type__c = 'Standard Deal';
		tstCER.APTS_Contributing_Agreement__c = tstAggr.Id;
		insert tstCER;
	}

	@isTest static void testDeleteCER() {
		Test.startTest();
        
        APTS_AgreementExpireCERBatch oBatch = new APTS_AgreementExpireCERBatch();
        Database.executebatch(oBatch);

        APTS_AgreementExpireCERBatchScheduler oScheduler = new APTS_AgreementExpireCERBatchScheduler();
        Datetime dt = Datetime.now().addMinutes(1);
        String CRON_EXP = '0 ' + dt.minute() + ' * ' + dt.day() + ' ' + dt.month() + ' ? ' + dt.year();
        System.schedule('Test Check', CRON_EXP, oScheduler);
        Test.stopTest();

        List<APTS_Contract_Entitlement_Repository__c> lstCER = [SELECT Id from APTS_Contract_Entitlement_Repository__c];
        System.assertEquals(0, lstCER.size());
	}
	
}