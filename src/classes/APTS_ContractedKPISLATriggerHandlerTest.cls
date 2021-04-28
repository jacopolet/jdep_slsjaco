/*************************************************************
@Name: APTS_ContractedKPISLATriggerHandlerTest
@Author: Santosh Kumar
@CreateDate: 19-Feb-2018
@Description: Test Class for APTS_ContractedKPISLATriggerHandler

******************************************************************/

@isTest
private class APTS_ContractedKPISLATriggerHandlerTest {
	
	public static Account oTestAccount;
	public static Contact oTestContact;
	public static Apttus_Config2__PriceList__c oTestPricelist;
	public static Apttus__APTS_Agreement__c oAggremt;
	public static List<Contracted_kpi_sla__c> conkpislalist = new List<Contracted_kpi_sla__c>();

	public static void init() {

		oTestAccount = APTS_TestUtils.createGrandParentAccount();
        Database.Insert(oTestAccount);

        oTestContact = APTS_TestUtils.createContact();
        insert oTestContact;

		oTestPricelist = APTS_TestUtils.createPriceList();
        insert oTestPricelist;        

        oAggremt = APTS_TestUtils.createAgreement(oTestContact.Id, null, oTestPricelist.Id, oTestAccount.Id);
        insert oAggremt;

        insert new TriggerSettings__c(APTS_ContractedKPISLATrigger__c = true);

        List<String> freqlist = new List<String>{'Monthly','Half-Yearly','Yearly','Quarterly'};
        List<String> typelist = new List<String>{'Down time %','Invoicing','Availability % per machine','Availability % total'};
        for(integer row=0;row<3;row++) {
        	for(integer col=0;col<4;col++){
        		conkpislalist.add(APTS_TestUtils.getcontractkpisla(oAggremt.Id, freqlist[col],typelist[row],10.00));
        	}
        }
        for(integer row=2;row<4;row++) {
        	for(integer col=0;col<4;col++) {
        		conkpislalist.add(APTS_TestUtils.getcontractkpisla(oAggremt.Id, freqlist[col],typelist[row],null));
        	}
        }

	}
	
	public static testMethod void createaggtest() {

        init();
        Test.startTest();
        	
        	insert conkpislalist;
			conkpislalist[13].KPI_Penalty__c = 20.00;
			update conkpislalist;

			delete conkpislalist[14];

            Apttus__APTS_Agreement__c oagg = [select id,APTS_KPISLA_RelatedList_Details__c from Apttus__APTS_Agreement__c where id=:oAggremt.Id];
            system.assertNotEquals(oagg.APTS_KPISLA_RelatedList_Details__c,null);

        Test.stopTest();

    }

}