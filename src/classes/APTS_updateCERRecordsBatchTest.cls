/*************************************************************
@Name: APTS_updateCERRecordsBatchTest
@Description: Test Class for APTS_updateCERRecordsBatch

******************************************************************/
@isTest
private class APTS_updateCERRecordsBatchTest {
        
    public static List<Account> oTestAccountlist = new List<Account>();
    public static Contact oTestContact;
    public static Product2 oproduct; 
    public static Apttus_Config2__PriceList__c oTestPricelist;
    public static List<Apttus__APTS_Agreement__c> oAggremtlist = new List<Apttus__APTS_Agreement__c>();
    public static List<APTS_CER_Transaction__c > certranslist = new list<APTS_CER_Transaction__c >();
    
    public static void init() {        
        
        oTestAccountlist.add(APTS_TestUtils.createGrandParentAccount());
        oTestAccountlist.add(APTS_TestUtils.createGrandParentAccount());
        Database.Insert(oTestAccountlist);

        oTestContact = APTS_TestUtils.createContact();
        insert oTestContact;

        oproduct = APTS_TestUtils.createProduct('Test Package Cafitesse 50','26940997','Machines'); 
        insert oproduct;

        oTestPricelist = APTS_TestUtils.createPriceList();
        insert oTestPricelist;

        Apttus__APTS_Agreement__c oAggremt1 = APTS_TestUtils.createAgreement(oTestContact.Id, null, oTestPricelist.Id, oTestAccountlist[0].Id);
        oAggremt1.Apttus__Status_Category__c = 'In Effect';
        oAggremt1.Apttus__Status__c = 'Activated';
        oAggremt1.Apttus__Contract_End_Date__c = Date.today().addYears(3);
        oAggremtlist.add(oAggremt1);
        
        insert oAggremtlist;       

        APTS_CER_Transaction__c createTrans = new APTS_CER_Transaction__c();
        createTrans.APTS_Process_Status__c = 'Created';
        createTrans.APTS_Agreement_Id__c = oAggremt1.id;
        insert createTrans;
        certranslist.add(createTrans);       

    }

    public static testMethod void Certranstest() {

        init();       

        Test.startTest();

        APTS_updateCERRecordsBatch  cerrecordbatch = new APTS_updateCERRecordsBatch (certranslist);
        Database.executeBatch(cerrecordbatch);

        Test.stopTest();
        
    }    
}