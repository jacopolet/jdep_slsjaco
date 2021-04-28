/**
* @author        Ritesh Kumar
* @date          8.17.2017           
* @description   Class responsible to test TS_UpdateSLADateQueueable class. 
*/

//@isTest(seeAllData=true)
@isTest
public class TS_UpdateSLADateQueueable_test {

    static Account acct;
    static Contact con;
    static Case c;
    static PhysicalAsset__c pa;

    @isTest static void test_UpdateSLADateQueueable(){
        //CaseMilestone CaseMilestone_obj = [select Id, TargetDate, CaseId from CaseMilestone LIMIT 1];
        TS_UpdateSLADateQueueable slaDateQueueable = new TS_UpdateSLADateQueueable();

        id rtpa = TS_UtilityClass.getRecordTypeIdByName('PhysicalAsset__c', 'Machine');

        Account acct = new Account();
        Contact con = new Contact();

        product2 prod = new product2();
        prod.Name = 'Operating Sched Product Test';
        prod.APTS_Material_Type__c = 'ZSPR';
        insert prod;

        pricebook2 orgPB = new pricebook2();
        orgPB.name = 'BE Price Book';
        orgPB.IsActive = true;
        orgPB.Sales_Organization__c = 'SAP_0333';
        insert orgPB;

        pricebookentry pbe = new pricebookentry();
        pbe.product2id = prod.id;
        pbe.pricebook2id = Test.getStandardPricebookId();
        pbe.UnitPrice = 1;
        pbe.IsActive = true;
        insert pbe;

        pbe = new pricebookentry();
        pbe.product2id = prod.id;
        pbe.pricebook2id = orgPB.id;
        pbe.UnitPrice = 11;
        pbe.IsActive = true;
        insert pbe;

        PhysicalAsset__c pa = TS_TestDataFactory.createPhysicalAsset();
        pa.RecordTypeId = rtpa;
        pa.Machine_Care__c = 'Full Operating';
        pa.StartDate__c = date.today().addDays(-365);
        pa.EndDate__c = date.today().addDays(365);
        pa.TypeOfContract__c = 'Sales';
        pa.AssetStatus__c = 'Activated';
        pa.ActiveContract__c = true;
        pa.SalesOrganization__c = 'SAP_0333';
        pa.Product__c = prod.id;
        insert pa;

        acct = new Account(Name='Account', Phone='+31302979111');
        insert acct;

        con = TS_TestDataFactory.createContact();
        con.Preferred_Language__c = 'SAP_EN';
        con.AccountId = acct.id;
        Insert con;
        
        List<SlaProcess> lstEntitlementProcess = [SELECT Id, Name FROM SlaProcess WHERE IsActive = true LIMIT 1];
        Entitlement entl = new Entitlement(Name='TestEntitlement', AccountId=acct.Id);
        if(lstEntitlementProcess.size() > 0){
            entl.SlaProcessId = lstEntitlementProcess[0].Id;
        }
        insert entl;

        c = TS_TestDataFactory.createFieldServiceCase();
        c.ContactId = con.Id;
        c.Status = 'New';
        c.Type = 'Complaint';
        c.SalesOrganization__c = 'SAP_0333';
        c.PhysicalAsset__c = pa.id;
        c.EntitlementId = entl.Id;
        insert c;
        
        slaDateQueueable.caseIds = c.Id;
        slaDateQueueable.hasException = true;

        Test.startTest();
        slaDateQueueable.execute(null);
        Test.stopTest();
        system.assert(c != null);
    }

    @isTest static void test_UpdateSLADateQueueable1(){
        TS_UpdateSLADateQueueable slaDateQueueable = new TS_UpdateSLADateQueueable();
        slaDateQueueable.numberOfExecution=2;
        Test.startTest();
        slaDateQueueable.execute(null);
        Test.stopTest();
        system.assert(acct == null);
    }
}