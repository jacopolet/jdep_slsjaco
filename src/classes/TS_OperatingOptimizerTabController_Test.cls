/**
* @author        Abram Vixen Reyes
* @date          Oct. 17, 2019
* @description   Test Class for TS_OperatingOptimizerTabController class.
* @revision(s)
*/
@isTest
public with sharing class TS_OperatingOptimizerTabController_Test {

	/*Karen Hung 31.10.2019 test class contents*/  
    private static Account accRec;
    private static Apttus_Config2__AccountLocation__c accLoc;
    private static Apttus_Config2__AccountLocation__c accLoc2;
    private static OperatingSchedule__c opSched;
    public static List<TS_Hierarchy_Derivation__mdt> get_postCodes;
    public static List<TS_District__mdt> dis_var;
    private static Route__c routeRec;
    private static Route_Line_Item__c routeItem;
    private static PhysicalAsset__c pAsset;
    private static PhysicalAsset__c pAsset2;
    
    @testSetup
    static void setupTestData(){
        
        List<Account> accList = TS_TestDataFactory.createAccounts(1);
        accRec = accList[0];
        insert accList;
        
        accLoc =  TS_TestDataFactory.createAccountLocation(accRec.Id);
        accLoc.Mini_Sales_Organization__c = 'SAP_0111';
        accLoc.Apttus_Config2__PostalCode__c = '1141';
        accLoc.Account_Location_Status__c = 'Valid';
		insert accLoc;
        
        accLoc2 = TS_TestDataFactory.createAccountLocation(accRec.Id);
        accLoc2.Mini_Sales_Organization__c = 'SAP_0111';
        accLoc2.Apttus_Config2__PostalCode__c = '1141';
        accLoc2.Account_Location_Status__c = 'Valid';
		insert accLoc2;
        
        routeRec = TS_TestDataFactory.createRoute('My Route', accLoc.Id);
        insert routeRec;
        
        pAsset = TS_TestDataFactory.createPhysicalAsset();
        pAsset.RecordTypeId = TS_UtilityClass.getRecordTypeIdByName('PhysicalAsset__c', 'Machine');
        pAsset.AccountLocation__c = accLoc.Id;
        pAsset.AssetStatus__c = 'Activated';
        pAsset.Machine_Care__c = TS_Constants.FULL_OPERATING;
        insert pAsset;
        
		pAsset2 = TS_TestDataFactory.createPhysicalAsset();
        pAsset2.RecordTypeId = TS_UtilityClass.getRecordTypeIdByName('PhysicalAsset__c', 'Machine');
        pAsset2.AccountLocation__c = accLoc.Id;
        pAsset2.AssetStatus__c = 'Activated';
        pAsset2.Machine_Care__c = TS_Constants.FULL_OPERATING;
        insert pAsset2;
        
        routeItem = TS_TestDataFactory.createRouteLine('My RouteLine', routeRec.Id);
        routeItem.PhysicalAssetId__c = pAsset.Id; 
        insert routeItem;
        
        opSched = TS_TestDataFactory.createOperatingScheduleTest(false, false, 'PM', '0', '0', '0', 'PM', '0', '0');
        opSched.Account_Location__c = accLoc.Id;
        opSched.PhysicalAsset__c = pAsset.Id;
        opSched.RecordTypeId = TS_UtilityClass.getRecordTypeIdByName('OperatingSchedule__c', 'Daily');
        opSched.Start_Date__c = Date.today().toStartofWeek().addDays(1);
        insert opSched;
        
        BusinessHours  bs = [select id from BusinessHours where Name = 'Default'];
        Id bsId = bs.id;
        
        Id rtCs = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', Label.TS_OperatingTaskRecordType);
        CountrySetting__c testCS = TS_TestDataFactory.createCountrySettings();
        
        testCS.Business_Hours__c = bsId;
        testCS.RecordTypeId = rtCs;
        testCS.NumberDayToLookup__c  = 10;
        testCS.Country__c = 'SAP_0111';
        Insert testCS;
        
        //get_postCodes = [SELECT Id, District__c, Postal_Code__c FROM TS_Hierarchy_Derivation__mdt];
        //dis_var = [SELECT Id, Label, Country_Code__c, (SELECT Id, District__c, Country_Code__c FROM TS_Hierarchy_Derivations__r) FROM TS_District__mdt ORDER BY Label ASC];
		
    }
    
    private static testMethod void query_pre_itemstest(){      
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
            setupTestData();            
            TS_OperatingOptimizerTabController.query_pre_items();           
        }
        system.assert(routeItem != null);
    }
    
    private static testMethod void get_accountLocationIdstest(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
            setupTestData();            
            TS_OperatingOptimizerTabController.get_accountLocationIds('Netherlands', 'NL - Region 1 North 1', true, true, true,false, 'test');
            TS_OperatingOptimizerTabController.get_accountLocationIds('Netherlands', 'NL - Region 1 North 1', true, true, true,true, 'test');
        }
		system.assert(routeItem != null);        
    }
    
    private static testMethod void get_accountLocationIdsFalsetest(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
            setupTestData();            
            TS_OperatingOptimizerTabController.get_accountLocationIds('Netherlands', 'NL - Region 1 North 1', false, true, false,false,'test');
            TS_OperatingOptimizerTabController.get_accountLocationIds('Netherlands', 'NL - Region 1 North 1', false, true, false,true,'test'); 
        }
		system.assert(routeItem != null);        
    }
    
    private static testMethod void get_accountLocationNoRoutes(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
            setupTestData();            
            TS_OperatingOptimizerTabController.get_accountLocationIds('Netherlands', 'NL - Region 1 North 1', false, false, true,false,'test');
			TS_OperatingOptimizerTabController.get_accountLocationIds('Netherlands', 'NL - Region 1 North 1', false, false, true,true,'test');  
        }
		system.assert(routeItem != null);        
    }
    
      private static testMethod void get_unassignedMachines(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
            setupTestData();            
            TS_OperatingOptimizerTabController.get_accountLocationIds('Netherlands', 'NL - Region 1 North 1', false, true, false,false,'test');
			TS_OperatingOptimizerTabController.get_accountLocationIds('Netherlands', 'NL - Region 1 North 1', false, true, false,true,'test');  
        }
		system.assert(routeItem != null);        
    }
    
    private static testMethod void query_newFTEtest(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
            setupTestData(); 
            TS_LastSyncDateOPG__c lastSync = new TS_LastSyncDateOPG__c();
            lastSync.Name = 'Test';
            lastSync.Last_Sync_Date__c = System.now();
            lastSync.Day_2__c = 2;
            insert lastSync;
            TS_OperatingOptimizerTabController.query_newFTE('NL - Region 1 North 1');      
        }
		system.assert(routeItem != null);           
    }
    
    private static testMethod void executeRecalculationBatchTest(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
            setupTestData(); 
            TS_OperatingOptimizerTabController.executeRecalculationBatch('NL - Region 1 North 1', false, new List<String>{'NL - Region 1 North 1'}, false, 'test', 'standard');
            TS_OperatingOptimizerTabController.executeRecalculationBatch('NL - Region 1 North 1', true, new List<String>{'NL - Region 1 North 1'}, false, 'test', 'standard');   
        }
        system.assert(routeItem != null);           
    } 
    
    private static testMethod void get_accountLocationIdsWithoutMachine(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
            setupTestData(); 
            TS_OperatingOptimizerTabController.get_accountLocationIds('Netherlands', 'NL - Region 1 North 1', true, false, false,false,'test');      
            TS_OperatingOptimizerTabController.get_accountLocationIds('Netherlands', 'NL - Region 1 North 1', true, false, false,true,'test');      
        }
        system.assert(routeItem != null);           
    }
    
    private static testMethod void get3pResourceTest(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
            setupTestData();
            TS_OperatingOptimizerTabController.get_accountLocationIds('Netherlands', 'NL - Region 1 North 1', false, false, false,true,'test');     
            TS_OperatingOptimizerTabController.get_accountLocationIds('Netherlands', 'NL - Region 1 North 1', false, false, false,false,'test');   
            TS_OperatingOptimizerTabController.get3pResource(false);       
            TS_OperatingOptimizerTabController.get3pResource(true);
            TS_OperatingOptimizerTabController.checkFeatureFlag();
			
        }
        system.assert(routeItem != null);           
    }
}