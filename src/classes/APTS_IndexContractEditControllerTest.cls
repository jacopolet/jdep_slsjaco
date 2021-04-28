/*************************************************************
@Name: APTS_IndexContractEditControllerTest
@Author: Santosh Kumar
@CreateDate: 19-Feb-2018
@Description: Test Class for APTS_IndexContractEditController

******************************************************************/
@isTest
private class APTS_IndexContractEditControllerTest {
	
	public static Account oTestAccount;
	public static Contact oTestContact;
	public static Opportunity oTestOpp;
	public static Apttus_Config2__PriceList__c oTestPricelist;
	public static Apttus__APTS_Agreement__c oAggremt;
	public static APTS_Index_Contract__c indexcontract;

	public static void init() {
		
        
		oTestAccount = APTS_TestUtils.createGrandParentAccount();
        Database.Insert(oTestAccount);

        oTestContact = APTS_TestUtils.createContact();
        insert oTestContact;

        oTestOpp = APTS_TestUtils.createOpportunity(oTestAccount.Id);
        insert oTestOpp;

		oTestPricelist = APTS_TestUtils.createPriceList();
        insert oTestPricelist;        

        oAggremt = APTS_TestUtils.createAgreement(oTestContact.Id, null, oTestPricelist.Id, oTestAccount.Id);
        insert oAggremt;

		indexcontract = APTS_TestUtils.createindexcontract(oAggremt,'Non-Standard Indexation','Technical Services');			

		insert indexcontract;
	}

	public static testMethod void createaggtest() {

        init();
        PageReference pref = Page.APTS_IndexContractEditPage;
        Test.setCurrentPage(pref);

        ApexPages.StandardController sc = new ApexPages.StandardController(indexcontract);
        APTS_IndexContractEditController Controller = new APTS_IndexContractEditController(sc);

        Test.startTest();

        PageReference pg = Controller.docontinue();
        system.assertEquals(pg, null);

        pg = Controller.docancel();
        system.assertNotEquals(pg, null);

        Controller.valueupdate();

        pg = Controller.indextypechange();
        system.assertEquals(pg, null);

        pg = Controller.docontinue();
        system.assertNotEquals(pg, null);

        indexcontract.APTS_Index_Type__c = 'Standard Indexation';

        sc = new ApexPages.StandardController(indexcontract);
        Controller = new APTS_IndexContractEditController(sc);

        pg = Controller.docontinue();
        system.assertNotEquals(pg, null);

        indexcontract.APTS_Index_Type__c = 'Standard Indexation(incl Fixed Prices)';
        indexContract.APTS_Indexation_Category__c = 'Products (Ingredients and &More)';

        sc = new ApexPages.StandardController(indexcontract);
        Controller = new APTS_IndexContractEditController(sc);

        pg = Controller.docontinue();
        system.assertEquals(pg, null);
        
        Test.stopTest();
    }

	
}