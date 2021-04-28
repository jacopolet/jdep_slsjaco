/**
* @author        Harold Marilag
* @date          6.20.2017           
* @description   Test class for PrevMaintenanceConTriggerBatch
* @revision(s)   Anna Gonzales 7.10.17
*/
@isTest
private class PrevMaintenanceConTriggerBatchTest {
    static Account acct;
    static Contact con;
    static Case c;
    static Apttus_Config2__AccountLocation__c acctLoc;
    static PhysicalAsset__c pa;

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
        acct = new Account(Name='Account', Phone='+31302979111');
        insert acct;
        
        con = TS_TestDataFactory.createContact();  
        con.Preferred_Language__c = 'SAP_EN';
        con.Main_Contact__c = true;
        con.AccountId = acct.Id;
        insert con;
        
        c = TS_TestDataFactory.createFieldServiceCase();
        c.ContactId = con.Id;
        c.Status = Label.TS_Status_InProgress;
        insert c;
        
       
        product2 pd = TS_TestDataFactory.createProductTest('ProductTest','ZSPR');
        database.insert(pd);
        
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pbEntrySTD= TS_TestDataFactory.createPricebookEntryTest(pd.Id,pricebookId);
        database.insert(pbEntrySTD);
        
        Pricebook2 Pricebook = new Pricebook2(Name=' Pricebook', isActive=true, Sales_Organization__c ='SAP_0333');
        database.insert(Pricebook);
        
        PricebookEntry pbEntry= TS_TestDataFactory.createPricebookEntryTest(pd.Id,Pricebook.Id);
        pbEntry.IsActive = true;
        database.insert(pbEntry);

        acctLoc = new Apttus_Config2__AccountLocation__c(Name='AL Test Account', 
                                                        Apttus_Config2__AccountId__c = acct.Id, 
                                                        Customer_calendar_key__c = 'SAP_BE',
                                                        Additional_Case_Contact__c = con.Id);
        insert acctLoc;
        
        Apttus_Config2__AccountLocation__c acctLoc2 = new Apttus_Config2__AccountLocation__c(Name='AL Test Account2', 
                                                         Apttus_Config2__AccountId__c = acct.Id, 
                                                         Customer_calendar_key__c = 'SAP_BE',
                                                         Additional_Case_Contact__c = con.Id,
                                                         Schedule_Preventive_Maintenance__c =true);
        insert acctLoc2;


        pa = new PhysicalAsset__c(Name='TestAnonymous', 
                          UniqueNumber__c = 'TestMachine-1', 
                          RecordTypeId = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get('Machine').getRecordTypeId(),
                          Product__c = pd.Id,
                          SalesOrganization__c='SAP_0333',
                          AccountLocation__c = acctLoc.Id,
                          SoldTo__c = acct.Id,
                          IncludesPreventiveMaintenanceCoverage__c = true,
                          PreventiveMaintenanceInterval__c = '1',
                          LastPreventiveMaintenanceDate__c = Date.valueOf('2016-1-2'),
                          AssetStatus__c = 'Activated',
                          EndDate__c = Date.valueOf('2050-9-9'));

        insert pa;

        BusinessHours bh = [SELECT Id FROM BusinessHours LIMIT 1];
        // F( TODAY() >= ( NextPreventiveMaintenanceDate__c - ContractTriggerSettings__r.PreventiveMainTriggerThreshold__c), TRUE, FALSE)
                 
                 
        CountrySetting__c countrySetting = new CountrySetting__c(Name = 'Test BHRs', 
            RecordTypeId = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', 'Country Default Business Hours'),
            Country__c = 'SAP_0333', Business_Hours__c = bh.Id, Active__c = true);
        insert countrySetting; 

        CountrySetting__c countrySetting2 = new CountrySetting__c(Name = 'Test ConTrig',
            RecordTypeId = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', 'Contract Trigger Setting'),
            Country__c = 'SAP_0333', PreventiveMainTriggerThreshold__c = 10, WTSTriggerThreshold__c = 9, Active__c = true);
        insert countrySetting2; 
        
        PhysicalAsset__c pa2 = new PhysicalAsset__c();
        pa2.Name='TestAnonymous1'; 
        pa2.UniqueNumber__c = 'TestMachine-4'; 
        pa2.RecordTypeId = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get('Machine').getRecordTypeId();
        pa2.Product__c = pd.Id;
        pa2.SalesOrganization__c='SAP_0333';
        pa2.AccountLocation__c = acctLoc2.Id;
        pa2.SoldTo__c = acct.Id;
        pa2.IncludesPreventiveMaintenanceCoverage__c = true;
        pa2.PreventiveMaintenanceInterval__c = '1';
        pa2.LastPreventiveMaintenanceDate__c = Date.valueOf('2016-1-2');
        pa2.NextPreventiveMaintenanceDate__c = Date.Today().addDays(-30);
        pa2.ContractTriggerSettings__c = countrySetting2.id;
        pa2.AssetStatus__c = 'Activated';
        pa2.EndDate__c = Date.valueOf('2050-9-9');
        insert pa2;
    }

    /**
    * @author        Harold Marilag
    * @date          6.20.2017           
    * @description   Test class for PrevMaintenanceConTriggerBatch
    * @revision(s)   
    */
    static testMethod void testPrevMaintenanceConTriggerBatch(){
        
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();
            
            Test.startTest();
                Id result = Database.executeBatch(new PrevMaintenanceConTriggerBatch());
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
    static testMethod void testPrevMaintenanceConTriggerBatch2(){
        
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();

            acct.Account_Block__c = true;
            update acct;

            acctLoc.Upfront_Call_Needed__c = true;
            update acctLoc;

            Test.startTest();
                Id result = Database.executeBatch(new PrevMaintenanceConTriggerBatch());
                System.assert(result != null);
            Test.stopTest(); 
        }
    }

    /**
    * @author        Paul Aguiling
    * @date          02.12.2018           
    * @description   Test class for PrevMaintenanceConTriggerBatch Exception
    * @revision(s)
    */
    static testMethod void testPrevMaintenanceConTriggerBatchEx() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(u) {

            setupTestData();

            Test.startTest();
                PrevMaintenanceConTriggerBatch.hasException = true;
                Id result = Database.executeBatch(new PrevMaintenanceConTriggerBatch());
                System.assert(result != null);
            Test.stopTest();
        }
    }

    /**
    * @author        Abram Vixen Reyes
    * @date          Jan. 25, 2019   
    * @description   Test class for PrevMaintenanceConTriggerBatch (Force Database.Error)
    * @revision(s)   
    */
    static testMethod void testPrevMaintenanceConTriggerBatch_DatabaseError(){        

        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();
            
            Test.startTest();
                PrevMaintenanceConTriggerBatch.forceError = true;
                Id result = Database.executeBatch(new PrevMaintenanceConTriggerBatch());
                System.assert(result != null);
            Test.stopTest(); 
        }
    }
}