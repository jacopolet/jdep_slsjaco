@isTest
private class APTS_RebateDefinitionTriggerHandlerTest {

	public static Account oTestAccount;
	public static Contact oTestContact;
	public static Apttus_Config2__PriceList__c oTestPricelist;
	public static Apttus__APTS_Agreement__c oAggremt;
	public static List<APTS_RebateDefiniation__c> rebdeflist = new List<APTS_RebateDefiniation__c>();

	public static void init() {

		oTestAccount = APTS_TestUtils.createGrandParentAccount();
        Database.Insert(oTestAccount);

        oTestContact = APTS_TestUtils.createContact();
        insert oTestContact;

		oTestPricelist = APTS_TestUtils.createPriceList();
        insert oTestPricelist;        

        oAggremt = APTS_TestUtils.createAgreement(oTestContact.Id, null, oTestPricelist.Id, oTestAccount.Id);
        oAggremt.APTS_IncentivesRelatedDetails__c = 'TestAgreement';
        insert oAggremt;

        insert new TriggerSettings__c(APTS_IncentiveTrigger__c = true);

        
        rebdeflist.add(APTS_TestUtils.getrebate(oAggremt.Id ,'rebtest', 'Rate Per Each Tier', 'Volume', 'Test description'));
        rebdeflist.add(APTS_TestUtils.getrebate(oAggremt.Id ,'rebtest1', 'Highest Tier Rate', 'Revenue', 'Test description1'));

    }

	public static testMethod void createrebtest() {

        init();
        Test.startTest();
        	
        	insert rebdeflist;
			rebdeflist[1].APTS_RebateTableTierType__c = 'Rate Per Each Tier';
			update rebdeflist;

			delete rebdeflist[1];

			Apttus__APTS_Agreement__c oagg = [select id,APTS_IncentivesRelatedDetails__c from Apttus__APTS_Agreement__c where id=:oAggremt.Id];
            system.assertNotEquals(oagg.APTS_IncentivesRelatedDetails__c,null);			

        Test.stopTest();

    }
	

	
}