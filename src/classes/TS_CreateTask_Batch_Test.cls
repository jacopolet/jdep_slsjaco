/*
* @author        Karen Hung
* @date          6.Sep.2018          
* @description   Test class for TS_CreateTask_Batch
* @revision(s)
*/
@isTest
public class TS_CreateTask_Batch_Test {
    
    public static void dataSetup(){
        
        BusinessHours  bs = [select id from BusinessHours where Name = 'Default'];
        Id bsId = bs.id;
        
        Id rtCs = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', 'Operating Task');
        CountrySetting__c testCS = TS_TestDataFactory.createCountrySettings ();      
        testCS.Business_Hours__c = bsId;
        testCS.RecordTypeId = rtCs;
        testCS.NumberDayToLookup__c  = 10;
        testCS.Active__c = true;
        testCS.Country__c = 'SAP_0333';
        Insert testCS;
    }
    

    /*
	* @author        Ritesh Kumar
	* @date          6.Sep.2018          
	* @description   Test class for TS_CreateTask_Batch (1. weekly task -Scenario 1, 1 wo and 1 woli for the whole week ---- Specific_Days_in_Week__c == false)
	* @revision(s)
	*/
    @isTest
    public static void  scenarioOneTest(){
        
        dataSetup();
        
        Date startOfWeek = Date.today().toStartOfWeek();
        DateTime dt = DateTime.newInstance(startOfWeek, Time.newInstance(0, 0, 0, 0));
        String dayOfWeek = dt.format('EEEE');
        Date sundayStartDate = dayOfWeek == 'Sunday' ? startOfWeek : startOfWeek.addDays(-1);

        List<Account> account_List = TS_TestDataFactory.createAccounts(1);
        Insert account_List;
        
        product2 pd = TS_TestDataFactory.createProductTest('ProductTest','ZSPR');
        Insert pd;
        
        Apttus_Config2__AccountLocation__c accLocation = TS_TestDataFactory.createAccountLocationTest('454545577868',account_List[0].Id );
        Insert accLocation;

        List <BusinessHours> businessHours_List = [SELECT Id, Name FROM BusinessHours WHERE Name = 'Default' LIMIT 1];

        Resource__c resource_obj = TS_TestDataFactory.createResourceTest('ResourceTest');
        Insert resource_obj;	
        
        Id recordType =  TS_UtilityClass.getRecordTypeIdByName('PhysicalAsset__c', 'Machine');
        PhysicalAsset__c physicalAsset = TS_TestDataFactory.createPhysicalAssetTest(recordType, pd.Id,'SAP_0333', account_List[0].Id, accLocation.Id, 'building', 'floor', resource_obj.Id, 'Full Operating');
        Insert physicalAsset;
        
        Id opsRecordType = TS_UtilityClass.getRecordTypeIdByName('OperatingSchedule__c', Label.APTS_Weekly);
        List<OperatingSchedule__c> operatingScheduleList = new List<OperatingSchedule__c>();  
        
        OperatingSchedule__c operatingSchedule = TS_TestDataFactory.createOperatingScheduleTest(false, false, 'PM', '0', '0', '0', 'PM', '0', '0');
        operatingSchedule.Start_Date__c = sundayStartDate;//Date.newInstance(2018,08,06);
        operatingSchedule.OP_Business_Hours__c = businessHours_List[0].Id;
        operatingSchedule.Sales_Organization__c = 'SAP_0333';
        operatingSchedule.PhysicalAsset__c= physicalAsset.Id;
        operatingSchedule.recordTypeId = opsRecordType;
        operatingSchedule.Interval_in_Weeks__c = '1';
  
        operatingScheduleList.add(operatingSchedule);
        Insert operatingScheduleList;

        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pbEntrySTD= TS_TestDataFactory.createPricebookEntryTest(pd.Id,pricebookId);
        Insert pbEntrySTD;

        Pricebook2 Pricebook = new Pricebook2(Name=' Pricebook', isActive=true, Sales_Organization__c ='SAP_0333');
        insert Pricebook;

        PricebookEntry pbEntry= TS_TestDataFactory.createPricebookEntryTest(pd.Id,Pricebook.Id);
        Insert pbEntry;
        
        Test.startTest();
		TS_CreateTask_Batch createTaskBatch = new TS_CreateTask_Batch(sundayStartDate);
		Database.QueryLocator  queryLocator = createTaskBatch.start(null);
		Database.executeBatch(createTaskBatch);
		createTaskBatch.Finish(null);

        Test.stopTest();
		System.assertEquals(operatingSchedule.Sales_Organization__c, 'SAP_0333');
        
        
    }

    /*
	* @author        Ritesh Kumar
	* @date          7.Sep.2018          
	* @description   Test class for TS_CreateTask_Batch (daily task - scenario 2 daily workorders with woli---Specific_Days_in_Week__c == true AND Schedule_Tasks_for_Holiday__c == true)
	* @revision(s)
	*/
    @isTest
    public static void  scenarioTwoTest(){
        dataSetup();
        
        Date startOfWeek = Date.today().toStartOfWeek();
        DateTime dt = DateTime.newInstance(startOfWeek, Time.newInstance(0, 0, 0, 0));
        String dayOfWeek = dt.format('EEEE');
        Date sundayStartDate = dayOfWeek == 'Sunday' ? startOfWeek : startOfWeek.addDays(-1);

        List<Account> account_List = TS_TestDataFactory.createAccounts(1);
        Insert account_List;
        
        product2 pd = TS_TestDataFactory.createProductTest('ProductTest','ZSPR');
        Insert pd;
        
        Apttus_Config2__AccountLocation__c accLocation = TS_TestDataFactory.createAccountLocationTest('123456789013',account_List[0].Id );
        Insert accLocation;
        
        Resource__c resource_obj = TS_TestDataFactory.createResourceTest('ResourceTest');
        Insert resource_obj;

        List<BusinessHours> businessHours_list = [SELECT Id, Name FROM BusinessHours WHERE Name = 'Default' LIMIT 1];
        String recordTypeId = Schema.SObjectType.CountrySetting__c.getRecordTypeInfosByName().get('Operating Task').getRecordTypeId(); 
        List<CountrySetting__c> cList = [SELECT Country__c, DefaultStartTime__c, DefaultEndTime__c, Business_Hours__c FROM CountrySetting__c WHERE Active__c = true AND RecordTypeId =: recordTypeId];
        
        Id recordType =  TS_UtilityClass.getRecordTypeIdByName('PhysicalAsset__c', 'Machine');
        PhysicalAsset__c physicalAsset = TS_TestDataFactory.createPhysicalAssetTest(recordType, pd.Id,'SAP_0333', account_List[0].Id, accLocation.Id, 'building', 'floor', resource_obj.Id, 'Full Operating');
        Insert physicalAsset;
        
        Id opsRecordType = TS_UtilityClass.getRecordTypeIdByName('OperatingSchedule__c', Label.APTS_Weekly);
        List<OperatingSchedule__c> operatingScheduleList = new List<OperatingSchedule__c>();  
        
        OperatingSchedule__c operatingSchedule = TS_TestDataFactory.createOperatingScheduleTest(true, true, 'PM', '1', '1', '1', 'PM', '0', '0');
        operatingSchedule.Start_Date__c = sundayStartDate; //Date.newInstance(2018,09,07);
        operatingSchedule.OP_Business_Hours__c = businessHours_List[0].Id;
        operatingSchedule.Sales_Organization__c = 'SAP_0333';
        operatingSchedule.PhysicalAsset__c= physicalAsset.Id;
        operatingSchedule.recordTypeId = opsRecordType;
        operatingSchedule.Interval_in_Weeks__c = '1';
  
        operatingScheduleList.add(operatingSchedule);
        Insert operatingScheduleList;

        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pbEntrySTD= TS_TestDataFactory.createPricebookEntryTest(pd.Id,pricebookId);
        Insert pbEntrySTD;

        Pricebook2 Pricebook = new Pricebook2(Name=' Pricebook', isActive=true, Sales_Organization__c ='SAP_0333');
        insert Pricebook;

        PricebookEntry pbEntry= TS_TestDataFactory.createPricebookEntryTest(pd.Id,Pricebook.Id);
        Insert pbEntry;
        
		Test.startTest();

		TS_CreateTask_Batch createTaskBatch = new TS_CreateTask_Batch(sundayStartDate);
		Database.QueryLocator  queryLocator = createTaskBatch.start(null);
		Database.executeBatch(createTaskBatch);
		createTaskBatch.Finish(null);

        Test.stopTest(); 
        System.assertEquals(operatingSchedule.Sales_Organization__c, 'SAP_0333');
    }

    /*
	* @author        Ritesh Kumar
	* @date          7.Sep.2018          
	* @description   Test class for TS_CreateTask_Batch (daily without holiday - scenario 3 daily workorders with woli except holiday---Specific_Days_in_Week__c == true AND Schedule_Tasks_for_Holiday__c == FALSE)
	* @revision(s)
	*/
   @isTest
    public static void  scenarioThreeTest(){
        dataSetup();
        Date startOfWeek = Date.today().toStartOfWeek();
        DateTime dt = DateTime.newInstance(startOfWeek, Time.newInstance(0, 0, 0, 0));
        String dayOfWeek = dt.format('EEEE');
        Date sundayStartDate = dayOfWeek == 'Sunday' ? startOfWeek : startOfWeek.addDays(-1);

        List<Account> account_List = TS_TestDataFactory.createAccounts(1);
        Insert account_List;
        
        product2 pd = TS_TestDataFactory.createProductTest('ProductTest','ZSPR');
        Insert pd;
        
        Apttus_Config2__AccountLocation__c accLocation = TS_TestDataFactory.createAccountLocationTest('123456789013',account_List[0].Id );
        Insert accLocation;
        
        Resource__c resource_obj = TS_TestDataFactory.createResourceTest('ResourceTest');
        Insert resource_obj;

        List<BusinessHours> businessHours_list = [SELECT Id, Name FROM BusinessHours WHERE Name = 'BE - Default' LIMIT 1];
        String recordTypeId = Schema.SObjectType.CountrySetting__c.getRecordTypeInfosByName().get('Operating Task').getRecordTypeId(); 
        List<CountrySetting__c> cList = [SELECT Country__c, DefaultStartTime__c, DefaultEndTime__c, Business_Hours__c FROM CountrySetting__c WHERE Active__c = true AND RecordTypeId =: recordTypeId];
        
        Id recordType =  TS_UtilityClass.getRecordTypeIdByName('PhysicalAsset__c', 'Machine');
        PhysicalAsset__c physicalAsset = TS_TestDataFactory.createPhysicalAssetTest(recordType, pd.Id,'SAP_0333', account_List[0].Id, accLocation.Id, 'building', 'floor', resource_obj.Id, 'Full Operating');
        Insert physicalAsset;
        
        Id opsRecordType = TS_UtilityClass.getRecordTypeIdByName('OperatingSchedule__c', Label.APTS_Weekly);
        List<OperatingSchedule__c> operatingScheduleList = new List<OperatingSchedule__c>();  
        
        OperatingSchedule__c operatingSchedule = TS_TestDataFactory.createOperatingScheduleTest(true, false, 'PM', '1', '1', '0', 'PM', '0', '1');
        operatingSchedule.Start_Date__c = sundayStartDate;
        operatingSchedule.OP_Business_Hours__c = businessHours_List[0].Id;
        operatingSchedule.Sales_Organization__c = 'SAP_0333';
        operatingSchedule.PhysicalAsset__c= physicalAsset.Id;
        operatingSchedule.recordTypeId = opsRecordType;
        operatingSchedule.Interval_in_Weeks__c = '1';
  
        operatingScheduleList.add(operatingSchedule);
        Insert operatingScheduleList;

        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pbEntrySTD= TS_TestDataFactory.createPricebookEntryTest(pd.Id,pricebookId);
        Insert pbEntrySTD;

        Pricebook2 Pricebook = new Pricebook2(Name=' Pricebook', isActive=true, Sales_Organization__c ='SAP_0333');
        insert Pricebook;

        PricebookEntry pbEntry= TS_TestDataFactory.createPricebookEntryTest(pd.Id,Pricebook.Id);
        Insert pbEntry;
        
		Test.startTest();

		TS_CreateTask_Batch createTaskBatch = new TS_CreateTask_Batch(sundayStartDate);
		Database.QueryLocator  queryLocator = createTaskBatch.start(null);
		Database.executeBatch(createTaskBatch,10);
		createTaskBatch.Finish(null);

        Test.stopTest(); 
        System.assertEquals(operatingSchedule.Sales_Organization__c, 'SAP_0333');
    }

}