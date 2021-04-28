/**
* @author        Adrian Reyes
* @date          01.08.2018
* @description   Test class for DynamicFirstResponseCalculator
* @revision(s)
*/

@isTest
public class DynamicFirstResponseCalculatorTest {
    static Entitlement entitlement;
    static PhysicalAsset__c physicalAsset;
    static CountrySetting__c countrySetting;
    static Case c;
    static WorkOrder wo;
    
    /**
    * @author        Adrian Reyes
    * @date          11.29.2017           
    * @description   Method responsible for creating custom setting records
    * @revision(s)
    */
    @testSetup
    static void dataSetup() {
        TriggerSettings__c trg = TriggerSettings__c.getOrgDefaults();
        trg.CaseTrigger__c = true;
        trg.WorkOrderLineItemTrigger__c = true;
        trg.WorkOrderTrigger__c = true;
        upsert trg;
    }
    
    /**
    * @author        Adrian Reyes
    * @date          11.29.2017           
    * @description   Method responsible for creating test data
    * @revision(s)
    */
    static void setupTestData() {
        Account acct = new Account(Name='Account', Phone='+31302979111');
        insert acct;
        
        entitlement = new Entitlement();
        entitlement.Name = 'Belgium - Field Service First Response - Service Standard';
        entitlement.AccountId = acct.Id;
        entitlement.SlaProcessId = [SELECT Id FROM SlaProcess WHERE IsActive = true AND Name = 'Belgium - Field Service First Response' LIMIT 1].Id;
        entitlement.SalesOrganization__c = 'SAP_0333';
        entitlement.CaseType__c = Label.TS_Case_Type_FieldService;
        //entitlement.BusinessHoursId = [SELECT Id FROM BusinessHours WHERE IsActive = true AND Name = 'BE - Service Standard' LIMIT 1].Id;
        entitlement.BusinessHoursId = [SELECT Id FROM BusinessHours WHERE IsActive = true AND Name = 'BE - Default' LIMIT 1].Id;
        entitlement.StartDate = Date.newInstance(2018, 1, 2);
        entitlement.EndDate = Date.newInstance(2048, 12, 31);
        entitlement.ActualWorkingHours__c = 9;
        entitlement.CountryDefault__c = true;
        insert entitlement;
        
        physicalAsset = new PhysicalAsset__c(ActiveContract__c = true);
        
        countrySetting = new CountrySetting__c(Name = 'BE - High Priority', 
                                               Country__c = 'SAP_0333', 
                                               RecordTypeId = Schema.SObjectType.CountrySetting__c.getRecordTypeInfosByName().get('Country Response Profile').getRecordTypeId(), 
                                               Priority__c = TS_Constants.CASE_PRIORITY_MEDIUM, 
                                               Coffee_is_Running__c = true,
                                               AssetResponseProfile__c = 'No Contract',
                                               ResponseProfile__c = 'EOD1',
                                               Active__c = true);
        insert countrySetting;
        
        c = TS_TestDataFactory.createFieldServiceCase();
        c.CoffeeIsRunning__c = true;
        
    }
    
    /**
    * @author        Abram Vixen Reyes
    * @date          Feb. 5, 2021
    * @description   Test method to cover SLA recalculation when creating an order
    * @revision(s)
    */
    static testMethod void testSLARecalculation() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        u.Sales_Organization__c = 'SAP_0333';
        update u;
        
        System.runAs(u) {
            setupTestData();
            
            physicalAsset.ResponseTime__c = '4';
            physicalAsset.StartDate__c = Date.today().addDays(-1);
			physicalAsset.EndDate__c = Date.today().addYears(1);
            insert physicalAsset;
            
            c.Priority = Label.TS_Case_Priority_Medium;
            c.PhysicalAsset__c = physicalAsset.Id;
            c.SalesOrganization__c = 'SAP_0333';    //Hardcoding while case sales org logic not yet final
            c.CoffeeIsRunning__c = false;
            insert c;
            
            System.debug('SLA Case: ' + c.SLADate__c);
            
            physicalAsset.ResponseTime__c = '24';
            update physicalAsset;
            
            Contact con = TS_TestDataFactory.createContact();  
        	con.Preferred_Language__c = 'SAP_EN';
			con.FirstName = 'Dummy Contact (';
        	con.LastName = 'DO NOT DELETE )';
        	con.RecordTypeId = TS_UtilityClass.getRecordTypeIdByName('Contact', 'Operational Contact');
        	Insert con;
        
        	wo = TS_TestDataFactory.createWorkOrder();
        	wo.CaseId = c.Id;
        	wo.WorkOrderType__c = Label.TS_Case_SubType_CorrectMaint;
        	wo.ContactId = con.Id;
        	wo.SalesOrganization__c = 'SAP_0333';
        	insert wo;
            
            WorkOrderLineItem woli = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);         
            woli.Case__c = c.Id;            
            woli.WorkOrderLineItemType__c = Label.TS_Type_Task;
            woli.IsFirstTask__c = true;
            woli.EndDate__c = DateTime.now();
            woli.WorkOrderType__c = TS_Constants.CASE_SUBTYPE_1STLINECORRECTMAINTAPI;
            woli.Status = 'Open';               
            woli.Subject = 'subj';
            woli.Description = 'desc';
            woli.Product__c = null;
            woli.PhysicalAsset__c = physicalAsset.Id;
            woli.Populate_Pricebook__c = false;
            woli.Is_Additional_Service_Job__c = true;
            woli.InternalOrderSAP__c = '1243445';
            insert woli;   
            
            Test.startTest();
            TS_CaseModificationController.createOrderClass(c.Id);
            Test.stopTest();
            
            WorkOrderLineItem woli1 = [SELECT Id, SLADate__c,Case__c,IsFirstTask__c,Status,WorkOrderLineItemType__c FROM WorkOrderLineItem LIMIT 1];
            system.assertNotEquals(Date.today(), woli1.SLADate__c);
        }
    }
    
    /**
    * @author        Adrian Reyes
    * @date          01.08.2018           
    * @description   Test method to cover Physical Asset less than 24 hours scenario
    * @revision(s)
    */
    static testMethod void testPhysicalAssetLessThan24Hours() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        u.Sales_Organization__c = 'SAP_0333';
        update u;
        
        System.runAs(u) {
            setupTestData();
            
            physicalAsset.ResponseTime__c = '4';
            physicalAsset.StartDate__c = Date.today().addDays(-1);
			physicalAsset.EndDate__c = Date.today().addYears(1);
            insert physicalAsset;
            
            c.Priority = Label.TS_Case_Priority_Medium;
            c.PhysicalAsset__c = physicalAsset.Id;
            c.SalesOrganization__c = 'SAP_0333';    //Hardcoding while case sales org logic not yet final
            c.CoffeeIsRunning__c = false;
            insert c;
            
            Test.startTest();
            DynamicFirstResponseCalculator dfrc = new DynamicFirstResponseCalculator();
            Integer result = dfrc.calculateMilestoneTriggerTime(c.Id, '');
            Test.stopTest();
            
            //Verify Results
            System.assertNotEquals(null, result);
        }
    }
    
    /**
    * @author        Adrian Reyes
    * @date          01.08.2018           
    * @description   Test method to cover Physical Asset more than 24 hours scenario
    * @revision(s)
    */
    static testMethod void testPhysicalAssetMoreThan24Hours() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        u.Sales_Organization__c = 'SAP_0333';
        update u;
        
        System.runAs(u) {
            setupTestData();
            
            physicalAsset.ResponseTime__c = '48';
            physicalAsset.StartDate__c = Date.today().addDays(-1);
			physicalAsset.EndDate__c = Date.today().addYears(1);
            insert physicalAsset;
            
            c.Priority = Label.TS_Case_Priority_Medium;
            c.PhysicalAsset__c = physicalAsset.Id;
            c.SalesOrganization__c = 'SAP_0333';    //Hardcoding while case sales org logic not yet final
            c.CoffeeIsRunning__c = false;
            c.SLARecalculation__c = true;
            insert c;            
            
            Test.startTest();
            DynamicFirstResponseCalculator dfrc = new DynamicFirstResponseCalculator();
            Integer result = dfrc.calculateMilestoneTriggerTime(c.Id, '');
            Test.stopTest();
            
            //Verify Results
            System.assertNotEquals(null, result);
        }
    }
    
    /**
    * @author        Adrian Reyes
    * @date          04.26.2018           
    * @description   Test method to cover bulk less than 24 hours scenario
    * @revision(s)
    */
    static testMethod void testBulkLessThan24Hours() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        u.Sales_Organization__c = 'SAP_0333';
        update u;
        
        System.runAs(u) {
            setupTestData();
            
            physicalAsset.ResponseTime__c = '4';
            physicalAsset.StartDate__c = Date.today().addDays(-1);
			physicalAsset.EndDate__c = Date.today().addYears(1);
            insert physicalAsset;
            
            c.Priority = Label.TS_Case_Priority_Medium;
            c.PhysicalAsset__c = physicalAsset.Id;
            c.SalesOrganization__c = 'SAP_0333';    //Hardcoding while case sales org logic not yet final
            c.CoffeeIsRunning__c = false;
            insert c;
            
            Test.startTest();
            DynamicFirstResponseCalculator dfrc = new DynamicFirstResponseCalculator();
            Integer result = dfrc.calculateMilestoneTriggerTimeBulk(new Set<Id>{c.Id});
            Test.stopTest();
            
            //Verify Results
            System.assertEquals(240, result);
        }
    }
    
    /**
    * @author        Adrian Reyes
    * @date          04.26.2018           
    * @description   Test method to cover bulk more than 24 hours scenario
    * @revision(s)
    */
    static testMethod void testBulkMoreThan24Hours() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        u.Sales_Organization__c = 'SAP_0333';
        update u;
        
        System.runAs(u) {
            setupTestData();
            
            physicalAsset.ResponseTime__c = '48';
            physicalAsset.StartDate__c = Date.today().addDays(-1);
			physicalAsset.EndDate__c = Date.today().addYears(1);
            insert physicalAsset;
            
            c.Priority = Label.TS_Case_Priority_Medium;
            c.PhysicalAsset__c = physicalAsset.Id;
            c.SalesOrganization__c = 'SAP_0333';    //Hardcoding while case sales org logic not yet final
            c.CoffeeIsRunning__c = false;
            insert c;
            
            Test.startTest();
            DynamicFirstResponseCalculator dfrc = new DynamicFirstResponseCalculator();
            Integer result = dfrc.calculateMilestoneTriggerTimeBulk(new Set<Id>{c.Id});
            Test.stopTest();
            
            //Verify Results
           System.assertNotEquals(null, result);
        }
    }
    
    /**
    * @author        Karen Hung
    * @date          07.17.2019         
    * @description   Test method to cover EOD1 response profile
    * @revision(s)
    */
    static testMethod void testEOD1Profile() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        u.Sales_Organization__c = 'SAP_0333';
        u.TimeZoneSidKey = 'Europe/Amsterdam';
        update u;
        
        System.runAs(u) {
            setupTestData();
            
            physicalAsset.ResponseTime__c = '91';
            physicalAsset.StartDate__c = Date.today().addDays(-1);
			physicalAsset.EndDate__c = Date.today().addYears(1);
            insert physicalAsset;
            
            c.Priority = Label.TS_Case_Priority_Medium;
            c.PhysicalAsset__c = physicalAsset.Id;
            c.SalesOrganization__c = 'SAP_0333';//Hardcoding while case sales org logic not yet final
            c.CoffeeIsRunning__c = false;
            insert c;
            
            Test.startTest();
            DynamicFirstResponseCalculator dfrc = new DynamicFirstResponseCalculator();
            Integer result = dfrc.calculateMilestoneTriggerTime(c.Id,'');
            Test.stopTest();
            
            //Verify Results
            System.assertNotEquals(null, result);
        }
    }

    /**
    * @author        Xen Reyes
    * @date          Sept 16, 2019
    * @description   Test method to cover EOD2 response profile
    * @revision(s)
    */
    static testMethod void testEODProfile() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        u.Sales_Organization__c = 'SAP_0333';
        u.TimeZoneSidKey = 'Europe/Amsterdam';
        update u;
        
        System.runAs(u) {
            setupTestData();
            
            physicalAsset.ResponseTime__c = '92';
            physicalAsset.StartDate__c = Date.today().addDays(-1);
			physicalAsset.EndDate__c = Date.today().addYears(1);
            insert physicalAsset;
            
            c.Priority = Label.TS_Case_Priority_Medium;
            c.PhysicalAsset__c = physicalAsset.Id;
            c.SalesOrganization__c = 'SAP_0333';//Hardcoding while case sales org logic not yet final
            c.CoffeeIsRunning__c = false;
            insert c;
            
            Test.startTest();
            DynamicFirstResponseCalculator dfrc = new DynamicFirstResponseCalculator();
            Integer result = dfrc.calculateMilestoneTriggerTime(c.Id,'');
            Test.stopTest();
            
            //Verify Results
            System.assertNotEquals(null, result);
        }
    }

     /**
    * @author        Xen Reyes
    * @date          Sept 16, 2019
    * @description   Test method to cover EOD2 response profile
    * @revision(s)
    */
    static testMethod void testEOD3Profile() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        u.Sales_Organization__c = 'SAP_0333';
        u.TimeZoneSidKey = 'Europe/Amsterdam';
        update u;
        
        System.runAs(u) {
            setupTestData();
            
            physicalAsset.ResponseTime__c = '93';
            physicalAsset.StartDate__c = Date.today().addDays(-1);
			physicalAsset.EndDate__c = Date.today().addYears(1);
            insert physicalAsset;
            
            c.Priority = Label.TS_Case_Priority_Medium;
            c.PhysicalAsset__c = physicalAsset.Id;
            c.SalesOrganization__c = 'SAP_0333';//Hardcoding while case sales org logic not yet final
            c.CoffeeIsRunning__c = false;
            insert c;
            
            Test.startTest();
            DynamicFirstResponseCalculator dfrc = new DynamicFirstResponseCalculator();
            Integer result = dfrc.calculateMilestoneTriggerTime(c.Id,'');
            Test.stopTest();
            
            //Verify Results
            System.assertNotEquals(null, result);
        }
    }

     /**
    * @author        Xen Reyes
    * @date          Sept 16, 2019
    * @description   Test method to cover EOD2 response profile
    * @revision(s)
    */
    static testMethod void testEOD4Profile() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        u.Sales_Organization__c = 'SAP_0333';
        u.TimeZoneSidKey = 'Europe/Amsterdam';
        update u;
        
        System.runAs(u) {
            setupTestData();
            
            physicalAsset.ResponseTime__c = '94';
            physicalAsset.StartDate__c = Date.today().addDays(-1);
			physicalAsset.EndDate__c = Date.today().addYears(1);
            insert physicalAsset;
            
            c.Priority = Label.TS_Case_Priority_Medium;
            c.PhysicalAsset__c = physicalAsset.Id;
            c.SalesOrganization__c = 'SAP_0333';//Hardcoding while case sales org logic not yet final
            c.CoffeeIsRunning__c = false;
            insert c;
            
            Test.startTest();
            DynamicFirstResponseCalculator dfrc = new DynamicFirstResponseCalculator();
            Integer result = dfrc.calculateMilestoneTriggerTime(c.Id,'');
            Test.stopTest();
            
            //Verify Results
            System.assertNotEquals(null, result);
        }
    }

     /**
    * @author        Francis Alindogan
    * @date          11/24/2019
    * @description   Test method to cover calculateSLADate
    * @revision(s)
    */
    static testMethod void testCalculateSLADate() {    
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        u.Sales_Organization__c = 'SAP_0333';
        u.TimeZoneSidKey = 'Europe/Amsterdam';
        update u;
        
        System.runAs(u) {
            setupTestData(); 
            Account acct = [SELECT Id FROM Account Limit 1];
			List<WorkOrderLineItem> returnwoliList = new List<WorkOrderLineItem>();
                
            CountrySetting__c countrySetting = new CountrySetting__c(Account__c = acct.Id, CaseSubtype__c = 'Bonus', 
            RecordTypeId = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', 'Country Response Profile'),
            Country__c = 'SAP_0333', Priority__c=TS_Constants.CASE_PRIORITY_MEDIUM, SLAinHours__c=240, CaseType__c = 'Complaint', 
            Email__c = 'test@accenture1.com', Active__c = true);
			
            Contact con = new Contact();
            con = TS_TestDataFactory.createContact();  
            con.Preferred_Language__c = 'SAP_EN';
            Insert con;

            physicalAsset.ResponseTime__c = '91';
            physicalAsset.StartDate__c = Date.today().addDays(-1);
			physicalAsset.EndDate__c = Date.today().addYears(1);
            insert physicalAsset;
                    
            c.Priority = Label.TS_Case_Priority_Medium;
            c.PhysicalAsset__c = physicalAsset.Id;
            c.SalesOrganization__c = 'SAP_0333';
            c.CoffeeIsRunning__c = false;
            c.SubType__c = TS_Constants.CASE_SUBTYPE_CORRECTMAINT;
            c.BusinessHoursId = [SELECT Id FROM BusinessHours WHERE IsActive = true AND Name = 'BE - Default' LIMIT 1].Id;
            c.ContactId = con.Id;
            c.PO_Number__c = '123456';
            insert c;

            WorkOrder wo = new WorkOrder();
            wo = TS_TestDataFactory.createWorkOrder();
            wo.CaseId = c.Id;
            wo.WorkOrderType__c = Label.TS_Case_SubType_CorrectMaint;
            wo.ContactId = con.Id;
            insert wo;

            WorkOrderLineItem woli = new WorkOrderLineItem();
            woli = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);      
            woli.StartDate__c = Date.today().addDays(-1);
            woli.EndDate__c = Date.today();   
            woli.Case__c = c.Id;
            woli.PhysicalAsset__c = physicalAsset.Id;
            woli.WorkOrderLineItemType__c = Label.TS_Type_Task;
            woli.EndDate__c = Date.today().addYears(1);
            woli.WorkOrderType__c = TS_Constants.CASE_SUBTYPE_CORRECTMAINTAPI;
            woli.Priority = TS_Constants.CASE_PRIORITY_MEDIUM;
            woli.isCoffeeRunning__c = false;
			woli.ReturnTask__c = false;
            woli.Status = TS_Constants.STATUS_COMPLETED;
            insert woli;

            WorkOrderLineItem retWoli = new WorkOrderLineItem();
            retWoli = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);         
            retWoli.Case__c = c.Id;
            retWoli.StartDate__c = Date.today().addDays(-1);
            retWoli.EndDate__c = Date.today();
            retWoli.ReturnTask__c = true;
            retWoli.PhysicalAsset__c = physicalAsset.Id;
            retWoli.WorkOrderLineItemType__c = Label.TS_Type_Task;
            retWoli.EndDate__c = Date.today().addYears(1);
            retWoli.WorkOrderType__c = TS_Constants.CASE_SUBTYPE_CORRECTMAINTAPI;
            retWoli.Priority = TS_Constants.CASE_PRIORITY_MEDIUM;
            retWoli.RelateTo__c = woli.Id;
            retWoli.Status = TS_Constants.STATUS_OPEN;
            retWoli.isCoffeeRunning__c = true;
            returnwoliList.add(retWoli);
            
            WorkOrderLineItem retWoli1 = new WorkOrderLineItem();
            retWoli1 = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);         
            retWoli1.Case__c = c.Id;
            retWoli1.StartDate__c = Date.today().addDays(-1);
            retWoli1.EndDate__c = Date.today();
            retWoli1.ReturnTask__c = true;
            retWoli1.WorkOrderLineItemType__c = Label.TS_Type_Task;
            retWoli1.EndDate__c = Date.today().addYears(1);
            retWoli1.WorkOrderType__c = TS_Constants.CASE_SUBTYPE_CORRECTMAINTAPI;
            retWoli1.Priority = TS_Constants.CASE_PRIORITY_MEDIUM;
            retWoli1.RelateTo__c = woli.Id;
            retWoli1.Status = TS_Constants.STATUS_OPEN;
            retWoli1.isCoffeeRunning__c = true;
            returnwoliList.add(retWoli1);
            
            insert returnwoliList;

            WorkOrderLineItemTriggerHandler wolith = new WorkOrderLineItemTriggerHandler(); 
            Map<Id, Datetime> resultMap = new Map<Id,Datetime>(); 
            
            Map<Id, WorkOrderLineItem> woliMap = new Map<Id, WorkOrderLineItem>();           
            List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
            Set<Id> woliSet = new Set<Id>();
            woliList.addAll(returnwoliList);
            woliSet.add(woli.Id);
            woliMap = wolith.getExtWoliMap(woliSet);                 
            Test.startTest();       
            //WITH PA RESPONSE TIME
            resultMap = DynamicFirstResponseCalculator.calculateSLADate(woliList, woliMap);                                                                                   
            Test.stopTest();
            
            //Verify Results
            System.assertNotEquals(null, resultMap.get(woli.Id));
        }


    }
    
     /**
    * @author        Pandian Sundaramoorthy
    * @date          04/16/2021
    * @description   Test method to improve code coverage
    * @revision(s)
    */
    static testMethod void testCalculateResponseprofile() {    
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        u.Sales_Organization__c = 'SAP_0333';
        u.TimeZoneSidKey = 'Europe/Amsterdam';
        update u;
        
        System.runAs(u) {
            setupTestData(); 
            Account acct = [SELECT Id FROM Account Limit 1];
			
            CountrySetting__c countrySetting = new CountrySetting__c(Account__c = acct.Id, CaseSubtype__c = 'Bonus', 
            RecordTypeId = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', 'Country Response Profile'),
            Country__c = 'SAP_0333', Priority__c='High', SLAinHours__c=240, CaseType__c = 'Complaint', 
            Email__c = 'test@accenture1.com', ResponseProfile__c = '120', Coffee_is_Running__c = true,
            AssetResponseProfile__c = 'N/A', Active__c = true);
			insert countrySetting;
            
            Contact con = new Contact();
            con = TS_TestDataFactory.createContact();  
            con.Preferred_Language__c = 'SAP_EN';
            Insert con;

            physicalAsset.ResponseTime__c = '91';
            physicalAsset.StartDate__c = Date.today().addDays(-1);
			physicalAsset.EndDate__c = Date.today().addYears(1);
            insert physicalAsset;
                    
            c.Priority = 'High';
            c.PhysicalAsset__c = physicalAsset.Id;
            c.SalesOrganization__c = 'SAP_0333';
            c.CoffeeIsRunning__c = false;
            c.SubType__c = TS_Constants.CASE_SUBTYPE_CORRECTMAINT;
            c.BusinessHoursId = [SELECT Id FROM BusinessHours WHERE IsActive = true AND Name = 'BE - Default' LIMIT 1].Id;
            c.ContactId = con.Id;
            c.PO_Number__c = '123456';
            insert c;

            WorkOrder wo = new WorkOrder();
            wo = TS_TestDataFactory.createWorkOrder();
            wo.CaseId = c.Id;
            wo.WorkOrderType__c = Label.TS_Case_SubType_CorrectMaint;
            wo.ContactId = con.Id;
            insert wo;

            WorkOrderLineItem woli = new WorkOrderLineItem();
            woli = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);      
            woli.StartDate__c = Date.today().addDays(-1);
            woli.EndDate__c = Date.today();   
            woli.Case__c = c.Id;
            woli.PhysicalAsset__c = physicalAsset.Id;
            woli.WorkOrderLineItemType__c = Label.TS_Type_Task;
            woli.EndDate__c = Date.today().addYears(1);
            woli.WorkOrderType__c = TS_Constants.CASE_SUBTYPE_CORRECTMAINTAPI;
            woli.Priority = TS_Constants.CASE_PRIORITY_MEDIUM;
            woli.isCoffeeRunning__c = true;
			woli.ReturnTask__c = false;
            woli.Status = TS_Constants.STATUS_COMPLETED;
            insert woli;

            WorkOrderLineItem retWoli1 = new WorkOrderLineItem();
            retWoli1 = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);         
            retWoli1.Case__c = c.Id;
            retWoli1.StartDate__c = Date.today().addDays(-1);
            retWoli1.EndDate__c = Date.today();
            retWoli1.ReturnTask__c = false;
            retWoli1.WorkOrderLineItemType__c = Label.TS_Type_Task;
            retWoli1.EndDate__c = Date.today().addYears(1);
            retWoli1.WorkOrderType__c = TS_Constants.CASE_SUBTYPE_CORRECTMAINTAPI;
            retWoli1.Priority = TS_Constants.CASE_PRIORITY_MEDIUM;
            retWoli1.RelateTo__c = woli.Id;
            retWoli1.Status = TS_Constants.STATUS_OPEN;
            retWoli1.isCoffeeRunning__c = true;
            insert retWoli1;

            WorkOrderLineItemTriggerHandler wolith = new WorkOrderLineItemTriggerHandler(); 
            Map<Id, Datetime> resultMap = new Map<Id,Datetime>(); 
            
            Map<Id, WorkOrderLineItem> woliMap = new Map<Id, WorkOrderLineItem>();           
            List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
            Set<Id> woliSet = new Set<Id>();
            woliList.add(retWoli1);
            woliSet.add(woli.Id);
            woliMap = wolith.getExtWoliMap(woliSet);                 
            Test.startTest();       
            //WITH PA RESPONSE TIME
            resultMap = DynamicFirstResponseCalculator.calculateSLADate(woliList, woliMap);                                                                                   
            Test.stopTest();
            
            //Verify Results
            System.assertNotEquals(null, resultMap.get(woli.Id));
        }


    }
}