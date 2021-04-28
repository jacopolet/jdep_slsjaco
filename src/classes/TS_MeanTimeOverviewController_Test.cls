/**
* @author        Abram Vixen Reyes
* @date          Oct. 17, 2019
* @description   Test Class for TS_MeanTimeOverviewController class.
* @revision(s)
*/
@isTest
public with sharing class TS_MeanTimeOverviewController_Test {
    
    private static List<Account>  accList;
    private static List<Customer_Holiday__c> chList;
    private static List<Apttus_Config2__AccountLocation__c> alList;
    private static List<Route_Line_Item__c>  rliList;
    private static List<Route__c> rList;
    private static List<PhysicalAsset__c> paList;
    private static List<Resource__c> resList;
    private static List<OperatingSchedule__c> osList;
    private static List<Product2> pList;
    
    
    @TestSetup
    static void setupTestData() {     
        //Creation
        List<Account> acc = TS_TestDataFactory.createAccounts(1);
        insert acc;
        
        Apttus_Config2__AccountLocation__c al = TS_TestDataFactory.createAccountLocation(acc[0].Id);
        al.Mini_Sales_Organization__c = 'SAP_0111';
        insert al;
        
        Customer_Holiday__c ch = TS_TestDataFactory.createHoliday('My Holiday', al.Id);
        insert ch;
        
        Route__c r = TS_TestDataFactory.createRoute('My Route', al.Id);
        r.Cups__c ='{"day_14":0,"day_13":0,"day_12":0,"day_11":0,"day_10":0,"day_9":0,"day_8":0,"day_7":0,"day_6":0,"day_5":0,"day_4":0,"day_3":0,"day_2":0,"day_1":1}';
        r.Large__c='{"day_14":0,"day_13":0,"day_12":0,"day_11":0,"day_10":0,"day_9":0,"day_8":0,"day_7":0,"day_6":0,"day_5":0,"day_4":0,"day_3":0,"day_2":0,"day_1":1}';
        r.Small__c = '{"day_14":0,"day_13":0,"day_12":0,"day_11":0,"day_10":0,"day_9":0,"day_8":0,"day_7":0,"day_6":0,"day_5":0,"day_4":0,"day_3":0,"day_2":0,"day_1":1}';        
        r.MTTO_All__c='{"day_14":0,"day_13":0,"day_12":0,"day_11":0,"day_10":0,"day_9":0,"day_8":0,"day_7":0,"day_6":0,"day_5":0,"day_4":0,"day_3":0,"day_2":0,"day_1":1}';
        r.Cups_3rd_Party__c ='{"day_14":0,"day_13":0,"day_12":0,"day_11":0,"day_10":0,"day_9":0,"day_8":0,"day_7":0,"day_6":0,"day_5":0,"day_4":0,"day_3":0,"day_2":0,"day_1":1}';
        r.Small_3rd_Party__c = '{"day_14":0,"day_13":0,"day_12":0,"day_11":0,"day_10":0,"day_9":0,"day_8":0,"day_7":0,"day_6":0,"day_5":0,"day_4":0,"day_3":0,"day_2":0,"day_1":1}';
        r.MTTO_3rd_Party__c='{"day_14":0,"day_13":0,"day_12":0,"day_11":0,"day_10":0,"day_9":0,"day_8":0,"day_7":0,"day_6":0,"day_5":0,"day_4":0,"day_3":0,"day_2":0,"day_1":1}';        
        r.Large_JDEOnly__c='{"day_14":0,"day_13":0,"day_12":0,"day_11":0,"day_10":0,"day_9":0,"day_8":0,"day_7":0,"day_6":0,"day_5":0,"day_4":0,"day_3":0,"day_2":0,"day_1":1}';
        r.Cups_JDEOnly__c ='{"day_14":0,"day_13":0,"day_12":0,"day_11":0,"day_10":0,"day_9":0,"day_8":0,"day_7":0,"day_6":0,"day_5":0,"day_4":0,"day_3":0,"day_2":0,"day_1":1}';
        r.Small_JDEOnly__c = '{"day_14":0,"day_13":0,"day_12":0,"day_11":0,"day_10":0,"day_9":0,"day_8":0,"day_7":0,"day_6":0,"day_5":0,"day_4":0,"day_3":0,"day_2":0,"day_1":1}';
        r.MTTO_JDEOnly__c='{"day_14":0,"day_13":0,"day_12":0,"day_11":0,"day_10":0,"day_9":0,"day_8":0,"day_7":0,"day_6":0,"day_5":0,"day_4":0,"day_3":0,"day_2":0,"day_1":1}';        
        r.MCO__c='{"nordics_12":0,"nordics_11":0,"nordics_10":0,"nordics_9":0,"nordics_8":0,"nordics_7":0,"nordics_6":0,"nordics_5":0,"nordics_4":0,"nordics_3":0,"nordics_2":0,"nordics_1":0}';
        r.Nordics_1__c=1;
        r.Nordics_12__c=60;
        r.Day1__c=1;
        r.Day3__c=60;
        insert r;
        
        Route_Line_Item__c rli = TS_TestDataFactory.createRouteLine('My RouteLine', r.Id);
        insert rli;
        
        Product2 p = TS_TestDataFactory.createProductTest('My Product', 'Material Type');
        p.APTS_Sales_Organization__c = 'SAP_0111';
        insert p;
        
        PhysicalAsset__c pa = TS_TestDataFactory.createPhysicalAsset();
        pa.Product__c = p.Id;
        pa.Machine_Care__c = 'Full Operating';
        pa.MothballAssetIndicator__c = false;
        pa.AccountLocation__c = al.Id;
        pa.AssetStatus__c = 'Activated';
        pa.SalesOrganization__c = 'SAP_0111';
        insert pa;
        
        Resource__c res = TS_TestDataFactory.createResourceSingle('My resource');
        insert res;     
        
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pbEntrySTD= TS_TestDataFactory.createPricebookEntryTest(p.Id,pricebookId);
        Insert pbEntrySTD;
        
        Pricebook2 Pricebook = new Pricebook2(Name=' Pricebook', isActive=true, Sales_Organization__c ='SAP_0111');
        insert Pricebook;
        
        PricebookEntry pbEntry= TS_TestDataFactory.createPricebookEntryTest(p.Id,Pricebook.Id);
        Insert pbEntry;
        
        //Updates
        rli.PhysicalAssetId__c = pa.Id;
        update rli;
        
        //For Operating Schedule
        Date startOfWeek = Date.today().toStartOfWeek();
        DateTime dt = DateTime.newInstance(startOfWeek, Time.newInstance(0, 0, 0, 0));
        String dayOfWeek = dt.format('EEEE');
        Date sundayStartDate = dayOfWeek == 'Sunday' ? startOfWeek : startOfWeek.addDays(-1);
        BusinessHours  bh = [SELECT Id, Name FROM BusinessHours WHERE Name = 'Default' LIMIT 1];
        Id opsRecordType = TS_UtilityClass.getRecordTypeIdByName('OperatingSchedule__c', 'Every Day');
        
        OperatingSchedule__c operatingSchedule = TS_TestDataFactory.createOperatingScheduleTest(false, false, 'PM', '0', '0', '0', 'PM', '0', '0');
        operatingSchedule.Start_Date__c = sundayStartDate;//Date.newInstance(2018,08,06);
        operatingSchedule.OP_Business_Hours__c = bh.Id;
        operatingSchedule.Sales_Organization__c = 'SAP_0111';
        operatingSchedule.PhysicalAsset__c = pa.Id;
        operatingSchedule.recordTypeId = opsRecordType;
        operatingSchedule.Interval_in_Weeks__c = '1';
        operatingSchedule.Schedule_Type__c = 'Regular';
        insert operatingSchedule;        
    }
    
    //method to get all records
    static void getAllRecords(){
        accList = [SELECT Id FROM Account];
        alList = [SELECT Id FROM Apttus_Config2__AccountLocation__c];
        chList = [SELECT Id FROM Customer_Holiday__c];
        rList = [SELECT Id FROM Route__c];
        rliList = [SELECT Id FROM Route_Line_Item__c];
        paList = [SELECT Id FROM PhysicalAsset__c];
        resList = [SELECT Id FROM Resource__c];
        osList = [SELECT Id,PhysicalAsset__c,OperatingReady__c,Active__c,TypeofContract__c,PhysicalAsset__r.MothballAssetIndicator__c,PhysicalAsset__r.AccountLocation__c,PhysicalAsset__r.AssetStatus__c,Schedule_Type__c  FROM OperatingSchedule__c];
        pList = [SELECT Id FROM Product2];
    }
    
    
    @isTest
    private static void testGetInformation(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) { 
            setupTestData();
            getAllRecords();
            Test.startTest();
            
            //Date Preparation
            List<String> recordList = New List<String>();
            recordList.add(rList[0].Id);
            rliList[0].PhysicalAssetId__c = paList[0].Id;
            update rliList;
            List<String> accLocList = New List<String>();
            accLocList.add(alList[0].Id);
            
            //Call Method
            TS_MeanTimeOverviewController.getInformation(recordList, true, true, true, true, true, true, false, accLocList, accLocList, accLocList, false, 'all', true);
            
            TS_MeanTimeOverviewController.getInformation(recordList, true, true, true, true, true, true, false, accLocList, accLocList, accLocList, true, 'all', true);
            
            TS_MeanTimeOverviewController.getInformation(recordList, false, true, true, true, true, true, false, accLocList, accLocList, accLocList, false, 'all', true);
            
            TS_MeanTimeOverviewController.getInformation(recordList, false, false, true, true, true, true, false, accLocList, accLocList, accLocList, false, 'all', true);
            
            TS_MeanTimeOverviewController.getInformation(recordList, false, false, false, true, true, true, false, accLocList, accLocList, accLocList, false, 'all', true);
            
            TS_MeanTimeOverviewController.getInformation(recordList, false, false, false, true, false, false, false, accLocList, accLocList, accLocList, false, 'all', true);
            
            TS_MeanTimeOverviewController.getInformation(recordList, true, true, true, true, true, true, false, accLocList, accLocList, accLocList, false, '3po', true);
            
            TS_MeanTimeOverviewController.getInformation(recordList, true, true, true, true, true, true, false, accLocList, accLocList, accLocList, true, '3po', true);
            
            Test.stopTest();
            //Verify Results
            System.assertEquals(2,[SELECT COUNT() FROM PhysicalAsset__c WHERE Id IN :paList]);
        }
    }
    
    @isTest
    private static void testCreateContainers(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) { 
            setupTestData();
            getAllRecords();
            Test.startTest();
            
            //Data Preparation
            List<String> accLocList = new List<String>();
            accLocList.add(alList[0].Id);
            
            Map<Id, List<Route__c>> rMap = new Map<Id, List<Route__c>>();
            rMap.put(rList[0].Id, rList);
            
            Map<Id, List<Route_Line_Item__c>> rliMap = new Map<Id, List<Route_Line_Item__c>>();
            rliMap.put(rliList[0].Id,  rliList);
            
            //Call Method
            TS_MeanTimeOverviewController.createContainers(true, true, accLocList, accLocList, rMap, rliMap, accLocList);
            TS_MeanTimeOverviewController.createContainers(false, true, accLocList, accLocList, rMap, rliMap, accLocList);
            
            Test.stopTest();
            //Verify Results
            System.assertEquals(2,[SELECT COUNT() FROM PhysicalAsset__c WHERE Id IN :paList]);
        }
    }
    
    @isTest
    private static void testCreateContainers2(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) { 
            setupTestData();
            getAllRecords();
            Test.startTest();
            
            //Data Preparation
            List<String> accLocList = new List<String>();
            accLocList.add(alList[0].Id);
            
            Map<Id, List<Route__c>> rMap = new Map<Id, List<Route__c>>();
            rMap.put(rList[0].Id, rList);
            
            Map<Id, List<Route_Line_Item__c>> rliMap = new Map<Id, List<Route_Line_Item__c>>();
            rliMap.put(rliList[0].Id,  rliList);
            
            //Call Method
            TS_MeanTimeOverviewController.createContainersNoRoutes(accLocList, false, 'all', true);
            TS_MeanTimeOverviewController.createContainersNoRoutes(accLocList, true, 'all', true);
            TS_MeanTimeOverviewController.createContainersNoRoutes(accLocList, false, '3po', false);
            TS_MeanTimeOverviewController.createContainersNoRoutes(accLocList, true, '3po', false);
            
            Test.stopTest();
            //Verify Results
            System.assertEquals(2,[SELECT COUNT() FROM PhysicalAsset__c WHERE Id IN :paList]);
        }
    }
    
    
}