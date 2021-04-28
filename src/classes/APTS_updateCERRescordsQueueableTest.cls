/*******************************************************************************************
Name            : APTS_updateCERRescordsQueueableTest
Created By      : Sai Sagar
Created Date    : 09/12/2018
Description     : This Apex Class is test class for CER Update which covers APTS_updateCERRecordsQueueable.
Version history : 
Test Class      : 
*********************************************************************************************/
@isTest 
private class APTS_updateCERRescordsQueueableTest {
public static List<Account> oTestAccountlist = new List<Account>();
    public static Contact oTestContact;
    public static Product2 oproduct; 
    public static Apttus_Config2__PriceList__c oTestPricelist;
    public static List<Apttus__APTS_Agreement__c> oAggremtlist = new List<Apttus__APTS_Agreement__c>();
    public static List<APTS_CER_Transaction__c > certranslist = new list<APTS_CER_Transaction__c >();

    @isTest
    private static void testCERUpdate() {
        // Create purchasing organization
        //Account organisation = APTS_TestUtils.createBuyingGroup();
        //insert organisation;

        Test.startTest();  
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
       // createTrans.APTS_Contributing_IND__c ='Migrated';
        insert createTrans;
        certranslist.add(createTrans); 
      
            System.enqueueJob(new APTS_updateCERRecordsQueueable());
       
        Test.stopTest();
        
    }
}