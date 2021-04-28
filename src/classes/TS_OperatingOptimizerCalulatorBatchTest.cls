/**
* @author        Francis Alindogan
* @date          12/2/2019
* @description   Test class for TS_OperatingOptimizerCalculator_Batch.
* @revision(s)
*/
@isTest
public with sharing class TS_OperatingOptimizerCalulatorBatchTest {
    
    private static Account accRec;
    private static List<TS_Hierarchy_Derivation__mdt> get_postCodes;
    
    private static Apttus_Config2__AccountLocation__c accLoc;    
    private static Route__c routeRec;
    private static Route_Line_Item__c routeItem;
    private static PhysicalAsset__c pAsset;
    
    private static Apttus_Config2__AccountLocation__c accLoc2;    
    private static Route__c routeRec2;
    private static Route__c routeRec3;
    private static Route_Line_Item__c routeItem2;
    private static Route_Line_Item__c routeItem3;
    private static PhysicalAsset__c pAsset2;
    private static OperatingSchedule__c testOS;
    private static Resource__c engr;
    
    @testSetup
    static void setupTestData(){
        
        engr = new Resource__c();
        engr.Name = 'Test Engr';
        engr.Sales_Organization__c = 'SAP_0111';
        engr.SAPStorageLocation__c ='xxxx';
        engr.CompanyCode__c ='0607';
        insert engr;
        
        List<Account> accList = TS_TestDataFactory.createAccounts(1);
        accRec = accList[0];
        insert accList;
        
        //ACCOUNT LOCATION 1
        accLoc =  TS_TestDataFactory.createAccountLocation(accRec.Id);
        accLoc.Mini_Sales_Organization__c = 'SAP_0111';
        accLoc.Account_Location_Status__c = 'Valid';
        accLoc.AverageRoutePrep__c = 1;
        accLoc.MTTTWithinSite__c = 2;
        accLoc.MTTOLocationSpecific__c = 1;
        accLoc.Third_Party_Resource__c = engr.Id;
		insert accLoc;
        
        Integer currentYear = System.Today().year();
        Integer nextYear = currentYear + 1;
        String defaultBucketizeJSON = '{"January '+nextYear+'":{"TTL":2,"STTL":2,"S15":1,"EOD_Cancel":0,"Buckets":{"Q":"1(0)","B":"1(0)"}},"December":{"TTL":1,"STTL":1,"S15":1,"EOD_Cancel":0,"Buckets":{"Q":"1(0)","P":"1(0)"}},"January '+currentYear+'":{"TTL":1,"STTL":1,"S15":0,"EOD_Cancel":0,"Buckets":{"Q":"1(0)","C":"1(0)"}}}';                
        routeRec = TS_TestDataFactory.createRoute('My Route', accLoc.Id);
        routeRec.Large__c='{"day_14":0,"day_13":0,"day_12":0,"day_11":0,"day_10":0,"day_9":0,"day_8":0,"day_7":0,"day_6":0,"day_5":0,"day_4":0,"day_3":0,"day_2":0,"day_1":1}';
        routeRec.Cups__c ='{"day_14":0,"day_13":0,"day_12":0,"day_11":0,"day_10":0,"day_9":0,"day_8":0,"day_7":0,"day_6":0,"day_5":0,"day_4":0,"day_3":0,"day_2":0,"day_1":1}';        
        routeRec.Small__c = '{"day_14":0,"day_13":0,"day_12":0,"day_11":0,"day_10":0,"day_9":0,"day_8":0,"day_7":0,"day_6":0,"day_5":0,"day_4":0,"day_3":0,"day_2":0,"day_1":1}';        
        routeRec.Cups_3rd_Party__c = '{"day_14":0,"day_13":0,"day_12":0,"day_11":0,"day_10":0,"day_9":0,"day_8":0,"day_7":0,"day_6":0,"day_5":0,"day_4":0,"day_3":0,"day_2":0,"day_1":1}';     
        routeRec.Small_3rd_Party__c = '{"day_14":0,"day_13":0,"day_12":0,"day_11":0,"day_10":0,"day_9":0,"day_8":0,"day_7":0,"day_6":0,"day_5":0,"day_4":0,"day_3":0,"day_2":0,"day_1":1}';             
        routeRec.MTTO_3rd_Party__c = '{"day_14":0,"day_13":0,"day_12":0,"day_11":0,"day_10":0,"day_9":0,"day_8":0,"day_7":0,"day_6":0,"day_5":0,"day_4":0,"day_3":0,"day_2":0,"day_1":1}';             
        routeRec.MTTO_All__c = '{"day_14":0,"day_13":0,"day_12":0,"day_11":0,"day_10":0,"day_9":0,"day_8":0,"day_7":0,"day_6":0,"day_5":0,"day_4":0,"day_3":0,"day_2":0,"day_1":1}';  
        routeRec.MCO__c = '{"nordics_12":0,"nordics_11":0,"nordics_10":0,"nordics_9":0,"nordics_8":0,"nordics_7":0,"nordics_6":0,"nordics_5":0,"nordics_4":0,"nordics_3":0,"nordics_2":0,"nordics_1":1}';  
        routeRec.Large_JDEOnly__c='{"day_14":0,"day_13":0,"day_12":0,"day_11":0,"day_10":0,"day_9":0,"day_8":0,"day_7":0,"day_6":0,"day_5":0,"day_4":0,"day_3":0,"day_2":0,"day_1":1}';
        routeRec.Cups_JDEOnly__c = '{"day_14":0,"day_13":0,"day_12":0,"day_11":0,"day_10":0,"day_9":0,"day_8":0,"day_7":0,"day_6":0,"day_5":0,"day_4":0,"day_3":0,"day_2":0,"day_1":1}';     
        routeRec.Small_JDEOnly__c = '{"day_14":0,"day_13":0,"day_12":0,"day_11":0,"day_10":0,"day_9":0,"day_8":0,"day_7":0,"day_6":0,"day_5":0,"day_4":0,"day_3":0,"day_2":0,"day_1":1}';             
        routeRec.MTTO_JDEOnly__c = '{"day_14":0,"day_13":0,"day_12":0,"day_11":0,"day_10":0,"day_9":0,"day_8":0,"day_7":0,"day_6":0,"day_5":0,"day_4":0,"day_3":0,"day_2":0,"day_1":1}';             
        routeRec.Small_Bucketize_All_Actual__c = defaultBucketizeJSON;
        routeRec.Cups_Bucketize_All_Actual__c = defaultBucketizeJSON;
        routeRec.Large_Bucketize_All_Actual__c = defaultBucketizeJSON;  
        routeRec.Small_Bucketize_JDEOnly_Actual__c = defaultBucketizeJSON;  
        routeRec.Cups_Bucketize_JDEOnly_Actual__c = defaultBucketizeJSON;  
        routeRec.Large_Bucketize_JDEOnly_Actual__c = defaultBucketizeJSON;  
        routeRec.Small_Bucketize_3rdParty_Actual__c = defaultBucketizeJSON;  
        routeRec.Cups_Bucketize_3rdParty_Actual__c = defaultBucketizeJSON;    
        insert routeRec;
        
        //Create product
        Product2 prod = new Product2();
        prod.Name = 'Operating Sched Product Test';
        prod.APTS_Material_Type__c = 'ZSPR';
        insert prod;
        
        pAsset = TS_TestDataFactory.createPhysicalAsset();
        pAsset.RecordTypeId = TS_UtilityClass.getRecordTypeIdByName('PhysicalAsset__c', 'Machine');
        pAsset.AccountLocation__c = accLoc.Id;
        pAsset.AssetStatus__c = 'Activated';
        pAsset.Machine_Care__c = TS_Constants.FULL_OPERATING;
        pAsset.SalesOrganization__c = 'SAP_0111';
        pAsset.StartDate__c = date.today().addDays(-365);
        pAsset.EndDate__c = date.today().addDays(365);
        pAsset.TypeOfContract__c = 'Sales';
        pAsset.ActiveContract__c = true;
        pAsset.Product__c = prod.Id;
        insert pAsset;
        
        routeItem = TS_TestDataFactory.createRouteLine('My RouteLine', routeRec.Id);
        insert routeItem;
        
        //ACCOUNT LOCATION 2
        accLoc2 =  TS_TestDataFactory.createAccountLocation(accRec.Id);
        accLoc2.Mini_Sales_Organization__c = 'SAP_0111';
        accLoc2.Account_Location_Status__c = 'Valid';
        accLoc2.Third_Party_Resource__c = engr.Id;
		insert accLoc2;
                        
        routeRec2 = TS_TestDataFactory.createRoute('My Route', accLoc2.Id);
        routeRec2.Large__c='{"day_14":0,"day_13":0,"day_12":0,"day_11":0,"day_10":0,"day_9":0,"day_8":0,"day_7":0,"day_6":0,"day_5":0,"day_4":0,"day_3":0,"day_2":0,"day_1":1}';
        routeRec2.Cups__c ='{"day_14":0,"day_13":0,"day_12":0,"day_11":0,"day_10":0,"day_9":0,"day_8":0,"day_7":0,"day_6":0,"day_5":0,"day_4":0,"day_3":0,"day_2":0,"day_1":1}';        
        routeRec2.Small__c = '{"day_14":0,"day_13":0,"day_12":0,"day_11":0,"day_10":0,"day_9":0,"day_8":0,"day_7":0,"day_6":0,"day_5":0,"day_4":0,"day_3":0,"day_2":0,"day_1":1}';
        routeRec2.MTTO_All__c = '{"day_14":0,"day_13":0,"day_12":0,"day_11":0,"day_10":0,"day_9":0,"day_8":0,"day_7":0,"day_6":0,"day_5":0,"day_4":0,"day_3":0,"day_2":0,"day_1":1}';  
        routeRec2.Cups_3rd_Party__c = '{"day_14":0,"day_13":0,"day_12":0,"day_11":0,"day_10":0,"day_9":0,"day_8":0,"day_7":0,"day_6":0,"day_5":0,"day_4":0,"day_3":0,"day_2":0,"day_1":1}';     
        routeRec2.Small_3rd_Party__c = '{"day_14":0,"day_13":0,"day_12":0,"day_11":0,"day_10":0,"day_9":0,"day_8":0,"day_7":0,"day_6":0,"day_5":0,"day_4":0,"day_3":0,"day_2":0,"day_1":1}';             
        routeRec2.MTTO_3rd_Party__c = '{"day_14":0,"day_13":0,"day_12":0,"day_11":0,"day_10":0,"day_9":0,"day_8":0,"day_7":0,"day_6":0,"day_5":0,"day_4":0,"day_3":0,"day_2":0,"day_1":1}';             
        routeRec2.Small_Bucketize_All_Actual__c = defaultBucketizeJSON;
        routeRec2.Cups_Bucketize_All_Actual__c = defaultBucketizeJSON;
        routeRec2.Large_Bucketize_All_Actual__c = defaultBucketizeJSON;  
        routeRec2.Small_Bucketize_JDEOnly_Actual__c = defaultBucketizeJSON;  
        routeRec2.Cups_Bucketize_JDEOnly_Actual__c = defaultBucketizeJSON;  
        routeRec2.Large_Bucketize_JDEOnly_Actual__c = defaultBucketizeJSON;  
        routeRec2.Small_Bucketize_3rdParty_Actual__c = defaultBucketizeJSON;  
        routeRec2.Cups_Bucketize_3rdParty_Actual__c = defaultBucketizeJSON;          
        routeRec2.MCO__c = '{"nordics_12":0,"nordics_11":0,"nordics_10":0,"nordics_9":0,"nordics_8":0,"nordics_7":0,"nordics_6":0,"nordics_5":0,"nordics_4":0,"nordics_3":0,"nordics_2":0,"nordics_1":1}';  
        
        insert routeRec2;
        
        routeRec3 = TS_TestDataFactory.createRoute('My Route', accLoc2.Id);
        routeRec3.Large__c='{"day_14":0,"day_13":0,"day_12":0,"day_11":0,"day_10":0,"day_9":0,"day_8":0,"day_7":0,"day_6":0,"day_5":0,"day_4":0,"day_3":0,"day_2":0,"day_1":1}';
        routeRec3.Cups__c ='{"day_14":0,"day_13":0,"day_12":0,"day_11":0,"day_10":0,"day_9":0,"day_8":0,"day_7":0,"day_6":0,"day_5":0,"day_4":0,"day_3":0,"day_2":0,"day_1":1}';        
        routeRec3.Small__c = '{"day_14":0,"day_13":0,"day_12":0,"day_11":0,"day_10":0,"day_9":0,"day_8":0,"day_7":0,"day_6":0,"day_5":0,"day_4":0,"day_3":0,"day_2":0,"day_1":1}';
        routeRec3.MTTO_All__c = '{"day_14":0,"day_13":0,"day_12":0,"day_11":0,"day_10":0,"day_9":0,"day_8":0,"day_7":0,"day_6":0,"day_5":0,"day_4":0,"day_3":0,"day_2":0,"day_1":1}';  
        routeRec3.Cups_3rd_Party__c = '{"day_14":0,"day_13":0,"day_12":0,"day_11":0,"day_10":0,"day_9":0,"day_8":0,"day_7":0,"day_6":0,"day_5":0,"day_4":0,"day_3":0,"day_2":0,"day_1":1}';     
        routeRec3.Small_3rd_Party__c = '{"day_14":0,"day_13":0,"day_12":0,"day_11":0,"day_10":0,"day_9":0,"day_8":0,"day_7":0,"day_6":0,"day_5":0,"day_4":0,"day_3":0,"day_2":0,"day_1":1}';             
        routeRec3.MTTO_3rd_Party__c = '{"day_14":0,"day_13":0,"day_12":0,"day_11":0,"day_10":0,"day_9":0,"day_8":0,"day_7":0,"day_6":0,"day_5":0,"day_4":0,"day_3":0,"day_2":0,"day_1":1}';                     
        routeRec3.Small_Bucketize_All_Actual__c = defaultBucketizeJSON;
        routeRec3.Cups_Bucketize_All_Actual__c = defaultBucketizeJSON;
        routeRec3.Large_Bucketize_All_Actual__c = defaultBucketizeJSON;  
        routeRec3.Small_Bucketize_JDEOnly_Actual__c = defaultBucketizeJSON;  
        routeRec3.Cups_Bucketize_JDEOnly_Actual__c = defaultBucketizeJSON;  
        routeRec3.Large_Bucketize_JDEOnly_Actual__c = defaultBucketizeJSON;  
        routeRec3.Small_Bucketize_3rdParty_Actual__c = defaultBucketizeJSON;  
        routeRec3.Cups_Bucketize_3rdParty_Actual__c = defaultBucketizeJSON;          
        routeRec3.MCO__c = '{"nordics_12":0,"nordics_11":0,"nordics_10":0,"nordics_9":0,"nordics_8":0,"nordics_7":0,"nordics_6":0,"nordics_5":0,"nordics_4":0,"nordics_3":0,"nordics_2":0,"nordics_1":1}';  
        
        insert routeRec3;
        
        pAsset2 = TS_TestDataFactory.createPhysicalAsset();
        pAsset2.RecordTypeId = TS_UtilityClass.getRecordTypeIdByName('PhysicalAsset__c', 'Machine');
        pAsset2.AccountLocation__c = accLoc2.Id;
        pAsset2.AssetStatus__c = 'Activated';
        pAsset2.Machine_Care__c = TS_Constants.FULL_OPERATING;
        insert pAsset2;
        
        //Create Standard Pricebook
        //Create sales org pricebook
        PriceBook2 orgPB = new Pricebook2();
        orgPB.name = 'NL Price Book';
        orgPB.IsActive = true;
        orgPB.Sales_Organization__c = 'SAP_0111';
        insert orgPB;
        
        //Create Pricebookentry with standard and sales org pricebook
        Pricebookentry pbe = new pricebookentry();
        pbe.product2id = prod.id;
        pbe.pricebook2id = Test.getStandardPricebookId();
        pbe.UnitPrice = 1;
        pbe.IsActive = true;
        pbe.TS_Load_Id__c = String.valueOf(prod.id) + String.valueOf(Test.getStandardPricebookId());
        insert pbe;
        
        pbe = new pricebookentry();
        pbe.product2id = prod.id;
        pbe.pricebook2id = orgPB.id;
        pbe.UnitPrice = 11;
        pbe.IsActive = true;
        pbe.TS_Load_Id__c = String.valueOf(prod.id) + String.valueOf(orgPB.id);
        pbe.MeanTimeToOperateC__c = 1;
        pbe.MeanTimeToOperateLM__c = 1;
        pbe.MeanTimeToOperateSM__c = 1;
        insert pbe;
        
        testOS = TS_TestDataFactory.createOperatingSchedule();
        testOS.PhysicalAsset__c = pAsset.id;
        testOS.RecordTypeId = TS_UtilityClass.getRecordTypeIdByName('OperatingSchedule__c', 'Every Day');
        testOS.Start_Date__c = date.today().toStartofWeek().addDays(1);
        testOS.Interval_in_Weeks__c = '1';
        testOS.LM_1_Monday__c = '1';
        testOS.SM_1_Monday__c = '1';
        testOS.SM_1_Friday__c = 'PM';
        testOS.SM_1_Thursday__c = '1';
        testOS.SM_2_Thursday__c = '1';
        testOS.SM_1_Wednesday__c = 'PM';
        Insert testOS;
        
        routeItem2 = TS_TestDataFactory.createRouteLine('My RouteLine2', routeRec2.Id);
        insert routeItem2;
        
        routeItem3 = TS_TestDataFactory.createRouteLine('My RouteLine2', routeRec3.Id);
        insert routeItem3;
        
        get_postCodes = [SELECT Id, District__c, Postal_Code__c, District__r.Label FROM TS_Hierarchy_Derivation__mdt WHERE District__r.Label != null and Postal_Code__c != null];
        
        accLoc.Apttus_Config2__PostalCode__c = get_postCodes[0].Postal_Code__c;  
        update accLoc;
        
        accLoc2.Apttus_Config2__PostalCode__c = get_postCodes[1].Postal_Code__c;  
        update accLoc2;       
 
    }
    static testMethod void testOperatingOptimizerCalculatorStandardNL() {
   		User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
            Test.startTest();            
            setupTestData();
            
			Map<String, Map<Integer, Decimal>> accLoc_map = new Map<String, Map<Integer, Decimal>>();            
            Map<Integer, Decimal> testMap = new Map<Integer, Decimal>();
            testMap.put(1, 1.0);
            testMap.put(2, 1.0);
            accLoc_map.put('Team 1', testMap);
            system.debug(engr);
            TS_OperatingOptimizerCalculator_Batch tsBatch = new TS_OperatingOptimizerCalculator_Batch('test - ' + get_postCodes[0].District__r.Label);
            tsBatch.thirdPartyResource = engr.Name;
            tsBatch.accLoc_map = accLoc_map;
            tsBatch.salesOrg = 'SAP_0111';
            tsBatch.filterType = 'all';
            tsBatch.isNordics = false;
            Id result = Database.executeBatch(tsBatch);
            Test.stopTest();
            System.assert(result != null);
        }
    }
    
    static testMethod void testOperatingOptimizerCalculatorStandardNordics() {
   		User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
            Test.startTest();            
            setupTestData();
            
			Map<String, Map<Integer, Decimal>> accLoc_map = new Map<String, Map<Integer, Decimal>>();            
            Map<Integer, Decimal> testMap = new Map<Integer, Decimal>();
            testMap.put(1, 1.0);
            testMap.put(2, 1.0);
            accLoc_map.put('Team 1', testMap);
            system.debug(engr);
            TS_OperatingOptimizerCalculator_Batch tsBatch = new TS_OperatingOptimizerCalculator_Batch('test - ' + get_postCodes[0].District__r.Label);
            tsBatch.thirdPartyResource = engr.Name;
            tsBatch.accLoc_map = accLoc_map;
            tsBatch.salesOrg = 'SAP_0111';
            tsBatch.filterType = 'all';
            tsBatch.isNordics = true;
            Id result = Database.executeBatch(tsBatch);
            Test.stopTest();
            System.assert(result != null);
        }
    }
    
	static testMethod void testOperatingOptimizerCalculator3PO() {
   		User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
            Test.startTest();            
            setupTestData();
            
			Map<String, Map<Integer, Decimal>> accLoc_map = new Map<String, Map<Integer, Decimal>>();            
            Map<Integer, Decimal> testMap = new Map<Integer, Decimal>();
            testMap.put(1, 1.0);
            testMap.put(2, 1.0);
            accLoc_map.put('Team 1', testMap);
            system.debug(engr);
            TS_OperatingOptimizerCalculator_Batch tsBatch = new TS_OperatingOptimizerCalculator_Batch('test - ' + get_postCodes[0].District__r.Label);
            tsBatch.thirdPartyResource = engr.Name;
            tsBatch.accLoc_map = accLoc_map;
            tsBatch.salesOrg = 'SAP_0111';
            tsBatch.filterType = '3po';
            tsBatch.isNordics = false;
            Id result = Database.executeBatch(tsBatch);
            Test.stopTest();
            System.assert(result != null);
        }
    }
    
}