@isTest
private class APTS_AgreementHierarchyViewTest {
	
	private static Apttus__APTS_Agreement__c tstAggr;
	private static Account tstAcc;

	static{
		tstAcc = APTS_TestUtils.createOrganisationproduct();
		insert tstAcc;

		tstAggr = new Apttus__APTS_Agreement__c();
		tstAggr.Apttus__Account__c  = tstAcc.Id;
		insert tstAggr;
	}

	@isTest static void tstAgreementHierarchy() {
		Test.startTest();
		APTS_AgreementHierarchyViewController.getCERData(tstAggr.Id);
		Test.stopTest();
	}
	
	@isTest static void tstAccountHierarchy() {
		Test.startTest();
		APTS_AgreementHierarchyViewController.getCERData(tstAcc.Id);
		Test.stopTest();
	}
	
}