//-------------------------------------------------------------------------------------------//
// Author       :   Karen Mae Hung
// Created Date :   Feb 25, 2020
// Usage        :   Test Class for TS_PreloadReportQueueable
//-------------------------------------------------------------------------------------------//
@isTest
public class TS_PreloadReportQueueable_Test {

	static OperatingSchedule__c testOS;
    static PhysicalAsset__c pa;
    static PhysicalAsset__c pa2;
    static PhysicalAsset__c pa3;
    static Route__c ra1;
    static Apttus_Config2__AccountLocation__c accLocation;
    
    //@testSetup
    public static void dataSetup(String lTask, String sTask, String cTasks, String machineCare, Boolean isRinse, Boolean is247) {
            BusinessHours  bs = [select id from BusinessHours where Name = 'Default'];
            Id bsId = bs.id;
            
            id rt = TS_UtilityClass.getRecordTypeIdByName('OperatingSchedule__c', 'Every Day');
            id rtpa = TS_UtilityClass.getRecordTypeIdByName('PhysicalAsset__c', 'Machine');

            //Create product
            product2 prod = new product2();
            prod.Name = 'Operating Sched Product Test';
            prod.APTS_Material_Type__c = 'ZSPR';
            insert prod;
        
            List<Account> account_List = TS_TestDataFactory.createAccounts(1);
            insert account_List;
            
            accLocation = TS_TestDataFactory.createAccountLocationTest('454545577868',account_List[0].Id );
        	accLocation.Mini_Sales_Organization__c = 'SAP_0111';
            insert accLocation;
            
            pa = TS_TestDataFactory.createPhysicalAsset();
            pa.RecordTypeId = rtpa;
            pa.Machine_Care__c = 'Full Operating';
            pa.StartDate__c = date.today().addDays(-365);
            pa.EndDate__c = date.today().addDays(365);
            pa.TypeOfContract__c = 'Sales';
            pa.AssetStatus__c = 'Activated';
            pa.ActiveContract__c = true;
            pa.SalesOrganization__c = 'SAP_0111';
            pa.Product__c = prod.id;
            pa.UniqueNumber__c = '123ABC';
        	pa.MothballAssetIndicator__c = false;
        	pa.AccountLocation__c = accLocation.Id;
            insert pa;

            pa2 = TS_TestDataFactory.createPhysicalAsset();
            pa2.RecordTypeId = rtpa;
            pa2.Machine_Care__c = machineCare;
            pa2.StartDate__c = date.today().addDays(-365);
            pa2.EndDate__c = date.today().addDays(365);
            pa2.TypeOfContract__c = 'Sales';
            pa2.AssetStatus__c = 'Activated';
            pa2.ActiveContract__c = true;
            pa2.SalesOrganization__c = 'SAP_0333';
            pa2.Product__c = prod.id;
        	pa2.MothballAssetIndicator__c = false;
            pa2.UniqueNumber__c = '456DEF';
        	pa2.AccountLocation__c = accLocation.Id;
            insert pa2;

            pa3 = TS_TestDataFactory.createPhysicalAsset();
            pa3.RecordTypeId = rtpa;
            pa3.Machine_Care__c = machineCare;
            pa3.StartDate__c = date.today().addDays(-365);
            pa3.EndDate__c = date.today().addDays(365);
            pa3.TypeOfContract__c = 'Sales';
            pa3.AssetStatus__c = 'Activated';
            pa3.ActiveContract__c = true;
            pa3.SalesOrganization__c = 'SAP_0111';
            pa3.Product__c = prod.id;
        	pa3.MothballAssetIndicator__c = false;
            pa3.UniqueNumber__c = '789GHI';
        	pa3.AccountLocation__c = accLocation.Id;
            insert pa3;
            
            testOS = TS_TestDataFactory.createOperatingSchedule();
            testOS.PhysicalAsset__c = pa.id;
            testOs.Schedule_Type__c = 'Regular';
            testOS.RecordTypeId = rt;
        	testOS.Schedule_Tasks_for_Holiday__c = TRUE;
        	testOS.Active__c = true;
            testOS.Start_Date__c = date.today().toStartofWeek().addDays(1);
            testOS.Interval_in_Weeks__c = '1';
        	testOS.Account_Location__c = accLocation.Id;

            testOS.SM_1_Monday__c = '1';
            testOS.SM_1_Tuesday__c = '1';
            testOS.SM_1_Wednesday__c = '1';
            testOS.SM_1_Thursday__c = '1';
            testOS.SM_1_Friday__c = '1';
        	testOS.SM_1_Sunday__c = '1';
            testOS.SM_1_Saturday__c = 'AM';

        	testOS.R_1_Monday__c = TRUE;
            testOS.R_1_Tuesday__c = TRUE;
            testOS.R_1_Wednesday__c = TRUE;
            testOS.R_1_Thursday__c = TRUE;
            testOS.R_1_Friday__c = TRUE;
        	testOS.R_1_Saturday__c = TRUE;
            testOS.R_1_Sunday__c = TRUE;

            testOS.LM_1_Monday__c = '1';
        	testOS.LM_1_Tuesday__c = '1';
            testOS.LM_1_Wednesday__c = '1';
            testOS.LM_1_Thursday__c = '1';
            testOS.LM_1_Friday__c = '1';
            testOS.LM_1_Saturday__c = '1';
            testOS.LM_1_Sunday__c = '1';

            testOS.C_1_Monday__c = '1';
            testOS.C_1_Tuesday__c = '1';
            testOS.C_1_Wednesday__c = '1';
            testOS.C_1_Thursday__c = '1';
            testOS.C_1_Friday__c = '1';
            testOS.C_1_Saturday__c = '1';
            testOS.C_1_Sunday__c = '1';
			
        	testOS.Schedule_Tasks_for_Holiday__c = true;
            testOS.OP_247Customer__c = is247;
            Insert testOS;
            
            Id rtCs = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', Label.TS_OperatingTaskRecordType);
            CountrySetting__c testCS = TS_TestDataFactory.createCountrySettings ();
            
            testCS.Business_Hours__c = bsId;
            testCS.RecordTypeId = rtCs;
            testCS.NumberDayToLookup__c  = 10;
            Insert testCS;

            Id rtCs2 = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', TS_Constants.TS_COUNTRYSETTING_RECORDTYPE_MCO_PM_RULES);
            CountrySetting__c testCSmco = TS_TestDataFactory.createCountrySettings();
            
            testCSmco.From__c = '5';
            testCSmco.RecordTypeId = rtCs2;
            testCSmco.To__c  = '4';
            testCSmco.Active__c = true;
            testCSmco.Country__c = 'SAP_0975';
            Insert testCSmco;
            
            
            //Create Standard Pricebook
            //Create sales org pricebook
            pricebook2 orgPB = new pricebook2();
            orgPB.name = 'BE Price Book';
            orgPB.IsActive = true;
            orgPB.Sales_Organization__c = 'SAP_0111';
            insert orgPB;
            
            //Create Pricebookentry with standard and sales org pricebook
            pricebookentry pbe = new pricebookentry();
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
            insert pbe;
        
        	ra1 = new Route__c();
        	ra1.Name = 'Test Route 1';
        	ra1.Account_Location__c = accLocation.Id;
        	insert ra1;
        
        	Route_Line_Item__c ral1 = new Route_Line_Item__c();
        	ral1.Name = pa.UniqueNumber__c;
            ral1.PhysicalAssetId__c = pa.Id;
        	ral1.RouteId__c = ra1.Id;
        	insert ral1;
        
        	Route_Line_Item__c ral2 = new Route_Line_Item__c();
        	ral2.Name = pa2.UniqueNumber__c;
            ral2.PhysicalAssetId__c = pa2.Id;
        	ral2.RouteId__c = ra1.Id;
        	insert ral2;
        
        	Route_Line_Item__c ral3 = new Route_Line_Item__c();
        	ral3.Name = pa3.UniqueNumber__c;
            ral3.PhysicalAssetId__c = pa3.Id;
        	ral3.RouteId__c = ra1.Id;
        	insert ral3;            
    }
    
   
	private static testMethod void TriggerSchedule() {
		Test.startTest();

		User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(usr) {
        	  dataSetup('1', 'PM', '1', 'Full Operating', true, true);
        } 
		
			BusinessHours  bs = [select id, Name from BusinessHours where Name = 'Default'];
		 	String bhName = 'Netherlands';
			id rt = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', Label.TS_OperatingTaskRecordType);
			
			CountrySetting__c testCS = TS_TestDataFactory.createCountrySettings ();
			testCS.Business_Hours__c = bs.id;
			testCS.RecordTypeId = rt;
			testCS.NumberDayToLookup__c	 = 10;
			testCS.Active__c = true;
			testCS.Country__c = 'SAP_0111';
			insert testCS;
			
			Datetime currentDate = System.now();
			Datetime computedDate = currentDate.addMinutes(1);
			
			String day = string.valueOf(computedDate .day());
			String month = string.valueOf(computedDate .month());
			String hour = string.valueOf(computedDate .hour());
			String minute = string.valueOf(computedDate .minute()); 
			String second = string.valueOf(computedDate .second());
			String year = string.valueOf(computedDate .year());
			String strSchedule = second + ' ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ?' + ' ' + year;
			
            Date mdate = date.today().toStartofWeek().addDays(1);
        
			TS_RouteTask_Scheduler opTaskSChed = new TS_RouteTask_Scheduler(null);
			opTaskSChed.country_Name = 'Netherlands';

			String jobID = System.schedule('Operating Route Task Scheduler Test Class:', strSchedule, opTaskSChed);
			
			CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
   					          FROM CronTrigger WHERE id = :jobId];
   			// Verify the job has not run
   			System.assertEquals(0, ct.TimesTriggered);
			
		Test.stopTest();
    }
    
    private static testMethod void TriggerScheduleThirdParty() {
		Test.startTest();

		User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(usr) {
        	dataSetup('1', 'PM', '1', 'Full Operating', true, true);
            Resource__c res = TS_TestDataFactory.createResourceTest('0981231');
            insert res;
            
            accLocation.Third_Party_Resource__c = res.Id;
            update accLocation;
            
        } 
		
			BusinessHours  bs = [select id, Name from BusinessHours where Name = 'Default'];
		 	String bhName = 'Netherlands';
			id rt = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', Label.TS_OperatingTaskRecordType);
			
			CountrySetting__c testCS = TS_TestDataFactory.createCountrySettings ();
			testCS.Business_Hours__c = bs.id;
			testCS.RecordTypeId = rt;
			testCS.NumberDayToLookup__c	 = 10;
			testCS.Active__c = true;
			testCS.Country__c = 'SAP_0111';
			insert testCS;
			
			Datetime currentDate = System.now();
			Datetime computedDate = currentDate.addMinutes(1);
			
			String day = string.valueOf(computedDate .day());
			String month = string.valueOf(computedDate .month());
			String hour = string.valueOf(computedDate .hour());
			String minute = string.valueOf(computedDate .minute()); 
			String second = string.valueOf(computedDate .second());
			String year = string.valueOf(computedDate .year());
			String strSchedule = second + ' ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ?' + ' ' + year;
			
            Date mdate = date.today().toStartofWeek().addDays(1);
        
			TS_RouteTask_Scheduler opTaskSChed = new TS_RouteTask_Scheduler(null);
			opTaskSChed.country_Name = 'Netherlands';

			String jobID = System.schedule('Operating Route Task Scheduler Test Class:', strSchedule, opTaskSChed);
			
			CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
   					          FROM CronTrigger WHERE id = :jobId];
   			// Verify the job has not run
   			System.assertEquals(0, ct.TimesTriggered);
			
		Test.stopTest();
    }
    
    private static testMethod void TriggerScheduleNordicsDaily() {
		Test.startTest();

		User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(usr) {
      		dataSetup('1', 'PM', '1', 'Full Operating', true, true);
            accLocation.Mini_Sales_Organization__c = 'SAP_0975';
            update accLocation;
            
            pa.SalesOrganization__c = 'SAP_0975';
            pa.Machine_Care__c = 'Machine Clean Operating';
            update pa;
            
            id rt = TS_UtilityClass.getRecordTypeIdByName('OperatingSchedule__c', 'Machine Clean Operating');
            testOS.Sales_Organization__c = 'SAP_0975';
            testOS.RecordTypeId = rt;
            testOS.FrequencyofL__c = 'Daily';
            testOS.Schedule_Tasks_for_Holiday__c = TRUE;
            testOS.Last_Early_Start_Date__c = date.newInstance(2020, 03, 01);
            testOS.PM_Months__c = '1;2;3;4;5;6;7;8;9;10;11;12';
            update testOS;
            
            Operating_Schedule_Rule__c osr = new Operating_Schedule_Rule__c();
            osr.Rule_Type__c = TS_CONSTANTS.RULE_MODIFY_EARLY_START;
            osr.Active__c = true;
            osr.Machine_Clean_Operating_Types__c = 'Preventive Maintenance';
            osr.From__c = '4';
            osr.To__c = '3';
            osr.Operating_Schedule__c = testOS.Id;
            insert osr;
            
            
        } 
			
        	
			BusinessHours  bs = [select id, Name from BusinessHours where Name = 'Default'];
		 	String bhName = 'Denmark';
			id rt = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', Label.TS_OperatingTaskRecordType);
			
			CountrySetting__c testCS = TS_TestDataFactory.createCountrySettings ();
			testCS.Business_Hours__c = bs.id;
			testCS.RecordTypeId = rt;
			testCS.NumberDayToLookup__c	 = 10;
			testCS.Active__c = true;
			testCS.Country__c = 'SAP_0975';
			insert testCS;
			
			Datetime currentDate = System.now();
			Datetime computedDate = currentDate.addMinutes(1);
			
			String day = string.valueOf(computedDate .day());
			String month = string.valueOf(computedDate .month());
			String hour = string.valueOf(computedDate .hour());
			String minute = string.valueOf(computedDate .minute()); 
			String second = string.valueOf(computedDate .second());
			String year = string.valueOf(computedDate .year());
			String strSchedule = second + ' ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ?' + ' ' + year;
			
            Date mdate = date.today().toStartofWeek().addDays(1);
        
			Integer daysBet = Date.today().DaysBetween(date.newInstance(2020, 3, 29));
        
			TS_MCOperating_Scheduler mco = new TS_MCOperating_Scheduler(daysBet);

			String jobID = System.schedule('Operating Route Task Scheduler Test Class:', strSchedule, mco);
			
			CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
   					          FROM CronTrigger WHERE id = :jobId];
   			// Verify the job has not run
   			System.assertEquals(0, ct.TimesTriggered);
			
		Test.stopTest();
    }
    
    private static testMethod void TriggerScheduleNordicsWeekly() {
		Test.startTest();

		User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(usr) {
      		dataSetup('1', 'PM', '1', 'Full Operating', true, true);
            accLocation.Mini_Sales_Organization__c = 'SAP_0975';
            update accLocation;
            
            pa.SalesOrganization__c = 'SAP_0975';
            pa.Machine_Care__c = 'Machine Clean Operating';
            update pa;
            
            id rt = TS_UtilityClass.getRecordTypeIdByName('OperatingSchedule__c', 'Machine Clean Operating');
            testOS.Sales_Organization__c = 'SAP_0975';
            testOS.RecordTypeId = rt;
            testOS.FrequencyofL__c = 'Weekly';
            testOS.Last_Early_Start_Date__c = date.newInstance(2020, 03, 01);
            testOS.PM_Months__c = '1;2;3;4;5;6;7;8;9;10;11;12';
            update testOS;
            
            Operating_Schedule_Rule__c osr = new Operating_Schedule_Rule__c();
            osr.Rule_Type__c = TS_CONSTANTS.RULE_MODIFY_EARLY_START;
            osr.Active__c = true;
            osr.Machine_Clean_Operating_Types__c = 'Preventive Maintenance';
            osr.From__c = '5';
            osr.To__c = '4';
            osr.Operating_Schedule__c = testOS.Id;
            insert osr;
            
            
        } 
			
        	
			BusinessHours  bs = [select id, Name from BusinessHours where Name = 'Default'];
		 	String bhName = 'Denmark';
			id rt = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', Label.TS_OperatingTaskRecordType);
			
			CountrySetting__c testCS = TS_TestDataFactory.createCountrySettings ();
			testCS.Business_Hours__c = bs.id;
			testCS.RecordTypeId = rt;
			testCS.NumberDayToLookup__c	 = 10;
			testCS.Active__c = true;
			testCS.Country__c = 'SAP_0975';
			insert testCS;
			
			Datetime currentDate = System.now();
			Datetime computedDate = currentDate.addMinutes(1);
			
			String day = string.valueOf(computedDate .day());
			String month = string.valueOf(computedDate .month());
			String hour = string.valueOf(computedDate .hour());
			String minute = string.valueOf(computedDate .minute()); 
			String second = string.valueOf(computedDate .second());
			String year = string.valueOf(computedDate .year());
			String strSchedule = second + ' ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ?' + ' ' + year;
			
            Date mdate = date.today().toStartofWeek().addDays(1);
        
        	Integer daysBet = Date.today().DaysBetween(date.newInstance(2020, 3, 29));
        
			TS_MCOperating_Scheduler mco = new TS_MCOperating_Scheduler(daysBet);

			String jobID = System.schedule('Operating Route Task Scheduler Test Class:', strSchedule, mco);
			
			CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
   					          FROM CronTrigger WHERE id = :jobId];
   			// Verify the job has not run
   			System.assertEquals(0, ct.TimesTriggered);
			
		Test.stopTest();
    }
    
    private static testMethod void TriggerScheduleNordicsWeekly2() {
		Test.startTest();

		User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(usr) {
      		dataSetup('1', 'PM', '1', 'Full Operating', true, true);
            accLocation.Mini_Sales_Organization__c = 'SAP_0975';
            update accLocation;
            
            pa.SalesOrganization__c = 'SAP_0975';
            pa.Machine_Care__c = 'Machine Clean Operating';
            update pa;
            
            id rt = TS_UtilityClass.getRecordTypeIdByName('OperatingSchedule__c', 'Machine Clean Operating');
            testOS.Sales_Organization__c = 'SAP_0975';
            testOS.RecordTypeId = rt;
            testOS.FrequencyofL__c = 'Weekly';
            testOS.Specific_Days_in_Week__c = true;
            testOS.Schedule_Tasks_for_Holiday__c = TRUE;
            testOS.Last_Early_Start_Date__c = date.newInstance(2020, 03, 01);
            testOS.PM_Months__c = '1;2;3;4;5;6;7;8;9;10;11;12';
            update testOS;
            
            Operating_Schedule_Rule__c osr = new Operating_Schedule_Rule__c();
            osr.Rule_Type__c = TS_CONSTANTS.RULE_MODIFY_EARLY_START;
            osr.Active__c = true;
            osr.Machine_Clean_Operating_Types__c = 'Preventive Maintenance';
            osr.From__c = '5';
            osr.To__c = '4';
            osr.Operating_Schedule__c = testOS.Id;
            insert osr;
            
            
        } 
			
        	
			BusinessHours  bs = [select id, Name from BusinessHours where Name = 'Default'];
		 	String bhName = 'Denmark';
			id rt = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', Label.TS_OperatingTaskRecordType);
			
			CountrySetting__c testCS = TS_TestDataFactory.createCountrySettings ();
			testCS.Business_Hours__c = bs.id;
			testCS.RecordTypeId = rt;
			testCS.NumberDayToLookup__c	 = 10;
			testCS.Active__c = true;
			testCS.Country__c = 'SAP_0975';
			insert testCS;
			
			Datetime currentDate = System.now();
			Datetime computedDate = currentDate.addMinutes(1);
			
			String day = string.valueOf(computedDate .day());
			String month = string.valueOf(computedDate .month());
			String hour = string.valueOf(computedDate .hour());
			String minute = string.valueOf(computedDate .minute()); 
			String second = string.valueOf(computedDate .second());
			String year = string.valueOf(computedDate .year());
			String strSchedule = second + ' ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ?' + ' ' + year;
			
            Date mdate = date.today().toStartofWeek().addDays(1);
        	Integer daysBet = Date.today().DaysBetween(date.newInstance(2020, 3, 29));
        
			TS_MCOperating_Scheduler mco = new TS_MCOperating_Scheduler(daysBet);

			String jobID = System.schedule('Operating Route Task Scheduler Test Class:', strSchedule, mco);
			
			CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
   					          FROM CronTrigger WHERE id = :jobId];
   			// Verify the job has not run
   			System.assertEquals(0, ct.TimesTriggered);
			
		Test.stopTest();
    }
    
        private static testMethod void TriggerScheduleNordicsMonthly() {
		Test.startTest();

		User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(usr) {
      		dataSetup('1', 'PM', '1', 'Full Operating', true, true);
            accLocation.Mini_Sales_Organization__c = 'SAP_0975';
            update accLocation;
            
            pa.SalesOrganization__c = 'SAP_0975';
            pa.Machine_Care__c = 'Machine Clean Operating';
            update pa;
            
            id rt = TS_UtilityClass.getRecordTypeIdByName('OperatingSchedule__c', 'Machine Clean Operating');
            testOS.Sales_Organization__c = 'SAP_0975';
            testOS.RecordTypeId = rt;
            testOS.FrequencyofL__c = 'Monthly';
            testOS.Specific_Days_in_Week__c = true;
            testOS.Schedule_Tasks_for_Holiday__c = TRUE;
            testOS.Last_Early_Start_Date__c = date.newInstance(2020, 03, 01);
            testOS.PM_Months__c = '1;2;3;4;5;6;7;8;9;10;11;12';
            testOS.Waterfilter_Months__c = '3;4;5';
            testOS.Bottle_Months__c = '3;4';
            testOS.L_Months__c = '3;4;5';
            update testOS;
            
            Operating_Schedule_Rule__c osr = new Operating_Schedule_Rule__c();
            osr.Rule_Type__c = TS_CONSTANTS.RULE_MODIFY_EARLY_START;
            osr.Active__c = true;
            osr.Machine_Clean_Operating_Types__c = 'Preventive Maintenance';
            osr.From__c = '5';
            osr.To__c = '4';
            osr.Operating_Schedule__c = testOS.Id;
            insert osr;
            
            
        } 
			    	
			BusinessHours  bs = [select id, Name from BusinessHours where Name = 'Default'];
		 	String bhName = 'Denmark';
			id rt = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', Label.TS_OperatingTaskRecordType);
			
			CountrySetting__c testCS = TS_TestDataFactory.createCountrySettings ();
			testCS.Business_Hours__c = bs.id;
			testCS.RecordTypeId = rt;
			testCS.NumberDayToLookup__c	 = 10;
			testCS.Active__c = true;
			testCS.Country__c = 'SAP_0975';
			insert testCS;
			
			Datetime currentDate = System.now();
			Datetime computedDate = currentDate.addMinutes(1);
			
			String day = string.valueOf(computedDate .day());
			String month = string.valueOf(computedDate .month());
			String hour = string.valueOf(computedDate .hour());
			String minute = string.valueOf(computedDate .minute()); 
			String second = string.valueOf(computedDate .second());
			String year = string.valueOf(computedDate .year());
			String strSchedule = second + ' ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ?' + ' ' + year;
			
            Date mdate = date.today().toStartofWeek().addDays(1);
        	Integer daysBet = Date.today().DaysBetween(date.newInstance(2020, 3, 29));
        
			TS_MCOperating_Scheduler mco = new TS_MCOperating_Scheduler(daysBet);

			String jobID = System.schedule('Operating Route Task Scheduler Test Class:', strSchedule, mco);
			
			CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
   					          FROM CronTrigger WHERE id = :jobId];
   			// Verify the job has not run
   			System.assertEquals(0, ct.TimesTriggered);
			
		Test.stopTest();
    }

}