/**
* @author        Marvin Gatchalian
* @date          19.April.2018
* @description   Test class for TS_DisasterRecoveryBatch.
* @revision(s)
*/

@isTest
public with sharing class TS_DisasterRecoveryBatch_Test {
    
    
    
    public static void dataSetup() {
		List <Disaster_Recovery__c> drToInsert = new List <Disaster_Recovery__c> ();
        id rtpa = TS_UtilityClass.getRecordTypeIdByName('PhysicalAsset__c', 'Machine');
        Id caseRecTypeId = TS_UtilityClass.getRecordTypeIdByName(Label.TS_Obj_API_Name_DR, Label.TS_Obj_API_Name_Case);
        
        Account acct = new Account ();
        Contact con = new Contact();
        
        Apttus_Config2__AccountLocation__c acctLocSingle = new  Apttus_Config2__AccountLocation__c();
        for(Apttus_Config2__AccountLocation__c acctLoc : TestDataFactory.createAccountLocation(1)){
            acctLocSingle = acctLoc;
        }
        insert acctLocSingle;    
        
        product2 prod = new product2();
        prod.Name = 'Operating Sched Product Test';
        prod.APTS_Material_Type__c = 'ZSPR';
        insert prod;
        
        //Create sales org pricebook
        pricebook2 orgPB = new pricebook2();
        orgPB.name = 'BE Price Book';
        orgPB.IsActive = true;
        orgPB.Sales_Organization__c = 'SAP_0333';
        insert orgPB;
        
        //Create Pricebookentry with standard and sales org pricebook
        pricebookentry pbe = new pricebookentry();
        pbe.product2id = prod.id;
        pbe.pricebook2id = Test.getStandardPricebookId();
        pbe.UnitPrice = 1;
        pbe.IsActive = true;
        //pbe.TS_Load_Id__c = String.valueOf(p.id) + String.valueOf(Test.getStandardPricebookId());
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
        pa.AccountLocation__c = acctLocSingle.id;
        insert pa;
        
        acct = new Account(Name='Account', Phone='+31302979111');
        //acct.Segment__c = 'SAP_A';
        //acct.High_Segment__c = 'Business';
        insert acct;
        
        con = TS_TestDataFactory.createContact();  
        con.Preferred_Language__c = 'SAP_EN';
        con.AccountId = acct.id;
        Insert con;
        
        for (Integer i = 0; i < 20; i++) {
            Disaster_Recovery__c newDr = new Disaster_Recovery__c();
            newDr.Subject__c = 'Test' + i;
            newDR.Description__c = 'Test' + i;
            newDR.Contact__c = con.id;
            newDR.Physical_Asset__c = pa.id;
            newDR.CoffeeIsRunning__c = true;
            newDR.WorkOrderRequired__c = true;
            newDR.WorkOrderType__c = 'S10';
            newDR.RecordTypeId = caseRecTypeId;
            newDR.SalesOrganization__c = 'SAP_0333';
            drToInsert.add(newDr);
        }
        insert drToInsert;
		
    }

    private static testMethod void TS_DisasterRecovery_Batch() {
		dataSetup();
		
		Test.startTest();
			TS_DisasterRecoveryBatch  dr = new TS_DisasterRecoveryBatch ();
        	Database.executeBatch(dr, 20);
		Test.stopTest();
		System.assertEquals(20, [Select id from Disaster_Recovery__c where Already_Processed__c = true].size());
	    	
    }
			
}