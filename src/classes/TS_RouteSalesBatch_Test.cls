/**
* @author        Paul Jarred Aguiling
* @date          04.14.2018          
* @description   Test class for TS_RouteSalesBatch
* @revision(s)
*/
@isTest
private class TS_RouteSalesBatch_Test {
	
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
    * @date          04.14.2018            
    * @description   Method responsible for creating test data
    * @revision(s)
    */
    static void setupTestData() {
        acct = new Account(Name='Account', Phone='+31302979111');
        insert acct;
        
        con = TS_TestDataFactory.createContact();  
        con.Preferred_Language__c = 'SAP_EN';
        con.AccountId = acct.Id;
        insert con;
        
        c = TS_TestDataFactory.createFieldServiceCase();
        c.ContactId = con.Id;
        c.AccountId = acct.Id;
        c.Status = Label.TS_Status_InProgress;
        insert c;

        acctLoc = new Apttus_Config2__AccountLocation__c(Name='AL Test Account', 
                                                        Apttus_Config2__AccountId__c = acct.Id, 
                                                        Customer_calendar_key__c = 'SAP_BE',
                                                        Additional_Case_Contact__c = con.Id,
                                                        RoutesalesInterval__c = 1,
                                                        RoutesalesPlanned__c = false,
                                                        Mini_Sales_Organization__c = 'SAP_0111',
                                                        LastRoutesalesDate__c = Date.newInstance(2018, 2, 21));
        insert acctLoc;

        BusinessHours bh = [SELECT Id FROM BusinessHours LIMIT 1];

        CountrySetting__c countrySetting = new CountrySetting__c(Name = 'Test BHRs', 
            RecordTypeId = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', 'Country Default Business Hours'),
            Country__c = Label.TS_SalesOrg_Netherlands, Business_Hours__c = bh.Id, Active__c = true);
        insert countrySetting; 

        CountrySetting__c countrySetting2 = new CountrySetting__c(Name = 'Test ConTrig',
            RecordTypeId = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', 'Route Sales Setting'),
            Country__c = Label.TS_SalesOrg_Netherlands, RouteSalesThreshold__c = 9, Active__c = true);
        insert countrySetting2; 
    }

    /**
    * @author        Paul Aguiling
    * @date          04.14.2018            
    * @description   Test class for TS_RouteSalesBatch
    * @revision(s)   
    */
    static testMethod void testRouteSalesBatch(){
        
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();
            
            Test.startTest();
                Id result = Database.executeBatch(new TS_RouteSalesBatch(null));
                System.assert(result != null);
            Test.stopTest(); 
        }
    }

    /**
    * @author        Paul Aguiling
    * @date          04.14.2018            
    * @description   Test class for TS_RouteSalesBatch Exception
    * @revision(s)
    */
    static testMethod void testRouteSalesBatchEx() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(u) {

            setupTestData();

            Test.startTest();
                TS_RouteSalesBatch.hasException = true;
                Id result = Database.executeBatch(new TS_RouteSalesBatch(null));
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
    static testMethod void testRouteSalesBatch_DatabaseError(){
        
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();
            
            Test.startTest();
                TS_RouteSalesBatch.forceError = true;
                Id result = Database.executeBatch(new TS_RouteSalesBatch(null));
                System.assert(result != null);
            Test.stopTest(); 
        }
    }

}