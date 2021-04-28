/**
* @author        Anna Gonzales
* @date          7.03.2017           
* @description   Test class for WaterFilterChangeConTriggerBatch
* @revision(s)   2.20.2018 Paul Aguiling: KTS-1095 Update test methods
*/
@isTest
private class WaterFilterChangeConTriggerBatchTest {
    static Account acct;
    static Contact con;
    static Case c;
    static Apttus_Config2__AccountLocation__c acctLoc;
    static PhysicalAsset__c pa;
    static PhysicalAsset__c pa2;
    static PhysicalAsset__c pa3;
    static PhysicalAsset__c pa4;
    static PhysicalAsset__c pa5;
    static CountrySetting__c ct_merge;
    static WorkOrder wo;

    @testSetup
    static void dataSetup() {
        //Custom settings is being shared by all test class, if another test class has already inserted the record 
        //this test class will throw "UNABLE_TO_LOCK_ROW, unable to obtain exclusive access to this record"
        try {
            TriggerSettings__c trg = TriggerSettings__c.getOrgDefaults();
            trg.CaseTrigger__c = true;
            trg.WorkOrderTrigger__c = true;
            trg.WorkOrderLineItemTrigger__c = true;
            upsert trg;      
            system.debug('trg is:'+trg);
        } catch(Exception ex) {
            system.debug(ex);
        }

         try {
            IntegrationTriggerSettings__c trg1 = IntegrationTriggerSettings__c.getOrgDefaults();
            trg1.IntegrationLogTrigger__c = true;
            upsert trg1; 
        } catch(Exception ex) {
            system.debug(ex);
        }

        ProcessBuilderSettings__c pb = new ProcessBuilderSettings__c();
        pb.WorkOrderPBFlows__c = true;
        pb.CasePBFlows__c = true;
        insert pb;
    }

    /**
    * @author        Paul Aguiling
    * @date          02.12.2018           
    * @description   Method responsible for creating test data
    * @revision(s)
    */
    static void setupTestData() {
        acct = new Account(Name='Account', Phone='+31302979111', Account_Block__c = false);
        insert acct;
        
        con = TS_TestDataFactory.createContact();  
        con.Preferred_Language__c = 'SAP_EN';
        con.AccountId = acct.Id;
        insert con;
        
        c = TS_TestDataFactory.createFieldServiceCase();
        c.ContactId = con.Id;
        c.Status = Label.TS_Status_InProgress;
        c.Type = 'Field Service';
        c.SubType__c = 'Corrective Maintenance';
        c.SalesOrganization__c = 'SAP_0333';
        insert c;
        
        wo = TS_TestDataFactory.createWorkOrder();
      	wo.CaseId = c.Id;
        wo.WorkOrderType__c = Label.TS_Case_SubType_CorrectMaint;
        wo.ContactId = con.Id;
        wo.SalesOrganization__c = 'SAP_0333';
        insert wo;
        
        Product2 prod_ZCMA = TS_TestDataFactory.createProductTest('ProductTest','ZCMA');
        insert prod_ZCMA;

        acctLoc = new Apttus_Config2__AccountLocation__c(Name='AL Test Account', 
                                                        Apttus_Config2__AccountId__c = acct.Id, 
                                                        Customer_calendar_key__c = 'SAP_BE',
                                                        Additional_Case_Contact__c = con.Id);
        insert acctLoc;

        BusinessHours bh = [SELECT Id FROM BusinessHours LIMIT 1];

        CountrySetting__c countrySetting = new CountrySetting__c(Name = 'Test BHRs', 
            RecordTypeId = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', 'Country Default Business Hours'),
            Country__c = 'SAP_0333', Business_Hours__c = bh.Id, Active__c = true);
        insert countrySetting; 

        CountrySetting__c countrySetting2 = new CountrySetting__c(Name = 'Test ConTrig',
            RecordTypeId = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', 'Contract Trigger Setting'), S41_Threshold__c = 120,
            Country__c = 'SAP_0333', PreventiveMainTriggerThreshold__c = 10, WTSTriggerThreshold__c = 9, Default_WTS_Interval__c = 1, Active__c = true, Supported_Operating_Types_for_S32__c = null);
        insert countrySetting2; 
        
        ct_merge = new CountrySetting__c(Name = 'Test MergeWTS',
            RecordTypeId = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', 'Merge WTS with Preventive Maintenance'),
            Country__c = 'SAP_0333', Merge_WTS__c = false, Active__c = true);
        insert ct_merge;

        pa = new PhysicalAsset__c(Name='TestAnonymous', 
                          UniqueNumber__c = 'TestMachine-1', 
                          RecordTypeId = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get('Machine').getRecordTypeId(),
                          SalesOrganization__c='SAP_0333',
                          AccountLocation__c = acctLoc.Id,
                          SoldTo__c = acct.Id,
                          IncludesWTSCoverage__c = true,
                          Machine_Care__c = 'Full Operating',
                          IncludesPreventiveMaintenanceCoverage__c = true,
                          WTSInterval__c = 1,
                          LastWTSDate__c = Date.valueOf('2017-1-2'),
                          NextWTSDate__c = Date.today(),
                          AssetStatus__c = 'Activated',
                          EndDate__c = Date.valueOf('2050-9-9'),
                          WTSChangedBy__c = 'Operator',
                          Product__c = prod_ZCMA.Id,
                          ContractTriggerSettings__c = countrySetting2.Id);
        insert pa;

        pa2 = new PhysicalAsset__c(Name='TestAnonymous2', 
                          UniqueNumber__c = 'TestMachine-2', 
                          RecordTypeId = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get('Machine').getRecordTypeId(),
                          SalesOrganization__c='SAP_0333',
                          AccountLocation__c = acctLoc.Id,
                          SoldTo__c = acct.Id,
                          IncludesWTSCoverage__c = true,
                          Machine_Care__c = 'Full Operating',
                          IncludesPreventiveMaintenanceCoverage__c = true,
                          WTSInterval__c = 1,
                          LastWTSDate__c = Date.valueOf('2017-1-2'),
                          AssetStatus__c = 'Activated',
                          EndDate__c = Date.valueOf('2050-9-9'),
                          WTSChangedBy__c = 'Operator',
                          Product__c = prod_ZCMA.Id,
                          ContractTriggerSettings__c = countrySetting2.Id);
        insert pa2;
        
        pa3 = new PhysicalAsset__c(Name='TestAnonymous3', 
                          UniqueNumber__c = 'TestMachine-3', 
                          RecordTypeId = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get('Machine').getRecordTypeId(),
                          SalesOrganization__c='SAP_0333',
                          AccountLocation__c = acctLoc.Id,
                          SoldTo__c = acct.Id,
                          IncludesWTSCoverage__c = true,
                          Machine_Care__c = 'Full Operating',
                          IncludesPreventiveMaintenanceCoverage__c = true,
                          WTSInterval__c = 1,
                          LastWTSDate__c = Date.valueOf('2017-1-2'),
                          NextWTSDate__c = Date.today().addDays(1),
                          AssetStatus__c = 'Activated',
                          EndDate__c = Date.valueOf('2050-9-9'),
                          WTSChangedBy__c = 'Operator',
                          ContractTriggerSettings__c = countrySetting2.Id);
        insert pa3;
        
        pa4 = new PhysicalAsset__c(Name='TestAnonymous4', 
                          UniqueNumber__c = 'TestMachine-4', 
                          RecordTypeId = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get('Machine').getRecordTypeId(),
                          SalesOrganization__c='SAP_0333',
                          AccountLocation__c = acctLoc.Id,
                          SoldTo__c = acct.Id,
                          IncludesWTSCoverage__c = true,
                          Machine_Care__c = 'Full Operating',
                          IncludesPreventiveMaintenanceCoverage__c = true,
                          WTSInterval__c = 1,
                          LastWTSDate__c = Date.valueOf('2017-1-2'),
                          NextWTSDate__c = Date.today().addDays(2),
                          AssetStatus__c = 'Activated',
                          EndDate__c = Date.valueOf('2050-9-9'),
                          WTSChangedBy__c = 'Operator',
                          ContractTriggerSettings__c = countrySetting2.Id);
        insert pa4;
        
        pa5 = new PhysicalAsset__c(Name='TestAnonymous5', 
                          UniqueNumber__c = 'TestMachine-5', 
                          RecordTypeId = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get('Machine').getRecordTypeId(),
                          SalesOrganization__c='SAP_0333',
                          AccountLocation__c = acctLoc.Id,
                          SoldTo__c = acct.Id,
                          IncludesWTSCoverage__c = true,
                          Machine_Care__c = 'Full Operating',
                          IncludesPreventiveMaintenanceCoverage__c = true,
                          WTSInterval__c = 1,
                          LastWTSDate__c = Date.valueOf('2017-1-2'),
                          NextWTSDate__c = Date.today().addDays(3),
                          AssetStatus__c = 'Activated',
                          EndDate__c = Date.valueOf('2050-9-9'),
                          WTSChangedBy__c = 'Operator',
                          ContractTriggerSettings__c = countrySetting2.Id);
        insert pa5;
    }

    /**
    * @author        Harold Marilag
    * @date          6.20.2017           
    * @description   Test class for WaterFilterChangeConTriggerBatch
    * @revision(s)   
    */
    static testMethod void testWaterFilterChangeConTriggerBatch(){
        
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();
            
            WorkOrderLineItem woli = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);         
            woli.Case__c = c.Id;            
            woli.WorkOrderLineItemType__c = Label.TS_Type_Task;
            woli.WorkOrderType__c = 'S41';
            woli.Status = 'Open';               
            woli.Subject = 'subj';
            woli.Description = 'desc';
            woli.PhysicalAsset__c = pa.Id;
            insert woli;
            
            Test.startTest();
                Id result = Database.executeBatch(new WaterFilterChangeConTriggerBatch());
                System.assert(result != null);
            Test.stopTest(); 
        }
    }
    
    /**
    * @author        Abram Vixen Reyes
    * @date          Nov. 23, 2019   
    * @description   Test class for WaterFilterChangeConTriggerBatch (MergeWTS)
    * @revision(s)   
    */
    static testMethod void testWaterFilterChangeConTriggerBatch_MergeWTS(){
        
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();
            
            WorkOrderLineItem woli = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);         
            woli.Case__c = c.Id;            
            woli.WorkOrderLineItemType__c = Label.TS_Type_Task;
            woli.WorkOrderType__c = 'S41';
            woli.Status = 'Open';               
            woli.Subject = 'subj';
            woli.Description = 'desc';
            woli.PhysicalAsset__c = pa2.Id;
            woli.SLADate__c = Date.today().addDays(-1);
            insert woli;
            
            ct_merge.Merge_WTS__c = true;
            update ct_merge;
            
            Test.startTest();
                Id result = Database.executeBatch(new WaterFilterChangeConTriggerBatch());
                System.assert(result != null);
            Test.stopTest(); 
        }
    }
    
    /**
    * @author        Abram Vixen Reyes
    * @date          Nov. 23, 2019   
    * @description   Test class for WaterFilterChangeConTriggerBatch (DefaultWTS)
    * @revision(s)   
    */
    static testMethod void testWaterFilterChangeConTriggerBatch_DefaultWTS(){
        
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();
            
            pa.WTSInterval__c = null;
            update pa;
            
            pa2.WTSInterval__c = null;
            update pa2;
            
            Test.startTest();
                Id result = Database.executeBatch(new WaterFilterChangeConTriggerBatch());
                System.assert(result != null);
            Test.stopTest(); 
        }
    }

    /**
    * @author        Paul Aguiling
    * @date          02.12.2018           
    * @description   Test class for PrevMaintenanceConTriggerBatch
    * @revision(s)   
    */
    static testMethod void testWaterFilterChangeConTriggerBatch2(){
        
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();

            acct.Account_Block__c = true;
            update acct;

            acctLoc.Upfront_Call_Needed__c = true;
            update acctLoc;

            Test.startTest();
                Id result = Database.executeBatch(new WaterFilterChangeConTriggerBatch());
                System.assert(result != null);
            Test.stopTest(); 
        }
    }

    /**
    * @author        Paul Aguiling
    * @date          02.12.2018           
    * @description   Test class for WaterFilterChangeConTriggerBatch Exception
    * @revision(s)
    */
    static testMethod void testWaterFilterConTriggerBatchEx() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(u) {

            setupTestData();

            Test.startTest();
                WaterFilterChangeConTriggerBatch.hasException = true;
                Id result = Database.executeBatch(new WaterFilterChangeConTriggerBatch());
                System.assert(result != null);
            Test.stopTest();
        }
    }
}