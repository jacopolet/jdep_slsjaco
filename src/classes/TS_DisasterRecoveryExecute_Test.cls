/**
* @author        Marvin Gatchalian
* @date          19.April.2018
* @description   Test class for TS_DisasterRecoveryExecute.
* @revision(s)
*/

@isTest
public with sharing class TS_DisasterRecoveryExecute_Test {
    
   /* public static void dataSetup() {
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
    
*/    
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

    private static testMethod void TS_DisasterRecovery_Execute() {
        dataSetup();
        Id caseRecTypeId = TS_UtilityClass.getRecordTypeIdByName(Label.TS_Obj_API_Name_DR, Label.TS_Obj_API_Name_Case);
        DescribeSObjectResult drRecords = Disaster_Recovery__c.getSObjectType().getDescribe();
        List<String> fields = new List<String>(drRecords.fields.getMap().keySet());
                
        String strQuery = ' SELECT ' + String.join(fields,',') + 
                       ' , Physical_Asset__r.PONumberMachines__c , Physical_Asset__r.Building__c, ' +
                       ' Physical_Asset__r.Floor__c, Physical_Asset__r.SmokingArea__c, ' +
                       ' Physical_Asset__r.Area__c, Physical_Asset__r.CustomerReferenceNumber__c, ' +
                       ' TS_Case_Reference__r.WorkOrderType__c, TS_Case_Reference__r.SLADate__c, ' +
                       ' TS_Case_Reference__r.RepeatVisit__c FROM ' + drRecords.getName() + 
                       ' WHERE ProcessRecord__c = true AND RecordTypeId = :caseRecTypeId' +
                       ' AND Already_Processed__c = false';
        
        /*Disaster_Recovery__c dr = [SELECT MissingWorkOrderType__c, MissingContact__c, MissingSubjectAndOrDescription__c,
        							MissingSchedulingDetails__c,  MissingPAorLocationandProduct__c, 
        							MissingPAwithFaultConifguration__c, MissingCaseCompletionDetails__c,
        							Missing_Sales_Organization__c FROM Disaster_Recovery__c	limit 1];*/
        
    /*    system.debug('...dr.MissingWorkOrderType__c > : ' + dr.MissingWorkOrderType__c);
        system.debug('...dr.MissingContact__c > : ' + dr.MissingContact__c);
        system.debug('...dr.MissingSubjectAndOrDescription__c > : ' + dr.MissingSubjectAndOrDescription__c);
        system.debug('...dr.MissingSchedulingDetails__c > : ' + dr.MissingSchedulingDetails__c);
        system.debug('...dr.MissingPAorLocationandProduct__c > : ' + dr.MissingPAorLocationandProduct__c);
        system.debug('...dr.MissingPAwithFaultConifguration__c > : ' + dr.MissingPAwithFaultConifguration__c);
        system.debug('...dr.MissingCaseCompletionDetails__c > : ' + dr.MissingCaseCompletionDetails__c);
        system.debug('...dr.Missing_Sales_Organization__c > : ' + dr.Missing_Sales_Organization__c	);*/
                                   
        /*Test.startTest();
            List<Disaster_Recovery__c> drList = Database.query(strQuery);
            TS_DisasterRecoveryBatch drExecuter = new TS_DisasterRecoveryBatch();
           	drExecuter.execute(null, drList);
            System.assertEquals(20, [Select id from Disaster_Recovery__c where Already_Processed__c = true].size());
        Test.stopTest();*/
        
        Test.startTest();
			TS_DisasterRecoveryBatch  dr = new TS_DisasterRecoveryBatch ();
        	Database.executeBatch(dr, 20);
		Test.stopTest();
		System.assertEquals(20, [Select id from Disaster_Recovery__c where Already_Processed__c = true].size());

            
    }
    
    
}