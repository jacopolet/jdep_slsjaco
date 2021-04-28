/**
 * @author        Karen Hung
 * @date          27.03.2020
 * @description   Test class for Apex batch class for generating Route Tasks for Nordics DOO-3001
 * @revision(s)  
 */
@isTest
public class TS_MCOperating_Batch_Test {
    static OperatingSchedule__c testOS;
    static PhysicalAsset__c pa2;
    static PhysicalAsset__c pa3;
    static Route__c r;
    static Route_Line_Item__c rli;
    static WorkOrder wo;
    static WorkOrderLineItem woli;
    static CountrySetting__c csetting;
    static Operating_Schedule_Rule__c rule;
    
    //@testSetup
    public static void dataSetup() {
        
        BusinessHours  bs = [select id from BusinessHours where Name = 'Default'];
        Id bsId = bs.id;
        
        id rt = TS_UtilityClass.getRecordTypeIdByName('OperatingSchedule__c', 'Machine Clean Operating');
        id rtpa = TS_UtilityClass.getRecordTypeIdByName('PhysicalAsset__c', 'Machine');
           
        //Create product
        product2 prod = new product2();
        prod.Name = 'Operating Sched Product Test';
        prod.APTS_Material_Type__c = 'ZSPR';
        insert prod;
        
        List<Account> account_List = TS_TestDataFactory.createAccounts(1);
        insert account_List;
        
        Apttus_Config2__AccountLocation__c accLocation = TS_TestDataFactory.createAccountLocationTest('454545577868',account_List[0].Id );
        accLocation.AverageRoutePrep__c = 1;
        accLocation.MTTTWithinSite__c = 2;
        accLocation.MTTOLocationSpecific__c = 1;
        accLocation.Mini_Sales_Organization__c = 'SAP_0975';
        insert accLocation;

        PhysicalAsset__c pa = TS_TestDataFactory.createPhysicalAsset();
        pa.RecordTypeId = rtpa;
        pa.Machine_Care__c = 'Comfort Operating';
        pa.StartDate__c = date.today().addDays(-365);
        pa.EndDate__c = date.today().addDays(365);
        pa.TypeOfContract__c = 'Sales';
        pa.AssetStatus__c = 'Activated';
        pa.ActiveContract__c = true;
        pa.SalesOrganization__c = 'SAP_0333';
        pa.Product__c = prod.id;
        pa.UniqueNumber__c = '123ABC';
        pa.AccountLocation__c = accLocation.Id;
        pa.MothballAssetIndicator__c = false;
        insert pa;
        
        testOS = TS_TestDataFactory.createOperatingSchedule();
        testOS.PhysicalAsset__c = pa.id;
        testOS.RecordTypeId = rt;
        testOS.Start_Date__c = date.today().toStartofWeek().addDays(1);
        testOS.Interval_in_Weeks__c = '1';
        testOS.LM_1_Monday__c = '1';
        testOS.LM_1_Tuesday__c = '1';
        testOS.LM_1_Friday__c = '1';
        testOS.FrequencyofL__c = 'Monthly';
        testOS.Descaling_Months__c = '3;4';
        testOS.PM_Months__c = '3;4;5';
        testOS.Waterfilter_Months__c = '3;4;5';
        testOS.Bottle_Months__c = '3;4';
        testOS.L_Months__c = '3;4;5';
        testOS.Active__c = true;
        testOS.Sales_Organization__c = 'SAP_0975';
        testOS.Last_Early_Start_Date__c = Date.newInstance(2020, 03, 29);
        Insert testOS;
        
        Id rtCs = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', Label.TS_OperatingTaskRecordType);
        CountrySetting__c testCS = TS_TestDataFactory.createCountrySettings();
        
        testCS.Business_Hours__c = bsId;
        testCS.RecordTypeId = rtCs;
        testCS.NumberDayToLookup__c  = 10;
        testCS.Country__c = 'SAP_0975';
        Insert testCS;

        Id rtCs2 = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', TS_Constants.TS_COUNTRYSETTING_RECORDTYPE_MCO_PM_RULES);
        CountrySetting__c testCSmco = TS_TestDataFactory.createCountrySettings();
        
        testCSmco.From__c = '5';
        testCSmco.RecordTypeId = rtCs2;
        testCSmco.To__c  = '4';
        testCSmco.Active__c = true;
        testCSmco.Country__c = 'SAP_0975';
        Insert testCSmco;

        Id rtCs3 = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', 'Mean Time To Operate per Call Type');
        CountrySetting__c testCSmtto = TS_TestDataFactory.createCountrySettings();
        
        testCSmtto.WorkOrderType__c = 'S20';
        testCSmtto.RecordTypeId = rtCs3;
        testCSmtto.Mean_Time_To_Operate__c  = 1;
        testCSmtto.Active__c = true;
        testCSmtto.Country__c = 'SAP_0975';
        Insert testCSmtto;
        
        //Create Standard Pricebook
        //Create sales org pricebook
        pricebook2 orgPB = new pricebook2();
        orgPB.name = 'DK Price Book';
        orgPB.IsActive = true;
        orgPB.Sales_Organization__c = 'SAP_0975';
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
        pbe.MeanTimeToOperateC__c = 1;
        pbe.MeanTimeToOperateLM__c = 1;
        pbe.MeanTimeToOperateSM__c = 1;
        pbe.MTTO_MCO_Large__c = 1;
        pbe.MTTO_MCO_PM__c = 1;
        pbe.MTTO_MCO_Waterfilter__c = 1;
        pbe.MTTO_MCO_Descaling__c = 1;
        pbe.MTTO_MCO_Bottles__c = 1;
        pbe.MTTO_MCO_Ingredients__c = 1;
        insert pbe;
        
        r = TS_TestDataFactory.createRoute('TEST R', accLocation.Id);
        insert r;

        rli = TS_TestDataFactory.createRouteLine('TEST RLI', r.Id);
        rli.PhysicalAssetId__c = pa.Id;
        insert rli;

        rule = TS_TestDataFactory.createRule(testOS.Id);
        rule.Machine_Clean_Operating_Types__c = 'Preventive Maintenance';
        rule.From__c = '5';
        rule.To__c = '4';
        rule.Rule_Type__c = 'Modify Early Start';
        insert rule;
        
        TS_MCOperating_Batch.operatingBucketEnabled = true;
    }

    static testMethod void testExecuteBatchMonthly(){
        User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(usr) { 
            dataSetup();

            Id rtCs = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', Label.TS_OperatingTaskRecordType);
            Date runDate = Date.newInstance(2020, 03,29);
            BusinessHours  bs = [select id from BusinessHours where Name = 'Default'];
            String bhId = String.valueOf(bs.id);
            test.startTest();
            TS_MCOperating_Batch mcbatch = new TS_MCOperating_Batch(runDate,1);                                        
            Database.executeBatch(mcbatch);
            test.stopTest();
        }
        system.assert([SELECT Id FROM WorkOrderLineItem] != null);
    }

    static testMethod void testExecuteBatchWeekly(){
        User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(usr) { 
            dataSetup();
            testOS.FrequencyofL__c = 'Weekly';
            update testOS;           

            Id rtCs = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', Label.TS_OperatingTaskRecordType);
            Date runDate = Date.newInstance(2020, 03,29);
            BusinessHours  bs = [select id from BusinessHours where Name = 'Default'];
            String bhId = String.valueOf(bs.id);
            test.startTest();
            TS_MCOperating_Batch mcbatch = new TS_MCOperating_Batch(runDate,1);                                        
            Database.executeBatch(mcbatch);
            test.stopTest();
        }
        system.assert([SELECT Id FROM WorkOrderLineItem] != null);
    }

    static testMethod void testExecuteBatchWeeklySpecificDay(){
        User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        usr.TimeZoneSidKey = 'Europe/Amsterdam';
        usr.LocaleSidKey= 'nl_NL';
        update usr;
        System.runAs(usr) { 
            dataSetup();
            testOS.FrequencyofL__c = 'Weekly';
            testOS.Specific_Days_in_Week__c = true;
            update testOS;           

            Id rtCs = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', Label.TS_OperatingTaskRecordType);
            Date runDate = Date.newInstance(2020, 03,29);
            BusinessHours  bs = [select id from BusinessHours where Name = 'Default'];
            String bhId = String.valueOf(bs.id);
            test.startTest();
            TS_MCOperating_Batch mcbatch = new TS_MCOperating_Batch(runDate,1);                                        
            Database.executeBatch(mcbatch);
            test.stopTest();
        }
        system.assert([SELECT Id FROM WorkOrderLineItem] != null);
    }
    
    static testMethod void testExecuteBatchDaily(){
        User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(usr) { 
            dataSetup();
            testOS.FrequencyofL__c = 'Daily';
            update testOS;           
            
            Id rtCs = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', Label.TS_OperatingTaskRecordType);
            Date runDate = Date.newInstance(2020, 03, 29);
            BusinessHours  bs = [select id from BusinessHours where Name = 'Default'];
            String bhId = String.valueOf(bs.id);
            test.startTest();
            TS_MCOperating_Batch mcbatch = new TS_MCOperating_Batch(runDate,1);                                        
            Database.executeBatch(mcbatch);
            test.stopTest();
        }
        system.assert([SELECT Id FROM WorkOrderLineItem] != null);
    }
    
    static testMethod void testExecuteBatchMonthlyEx(){
        User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(usr) { 
            dataSetup();
            
            Id rtCs = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', Label.TS_OperatingTaskRecordType);
            Date runDate = Date.newInstance(2020, 03, 29);
            BusinessHours  bs = [select id from BusinessHours where Name = 'Default'];
            String bhId = String.valueOf(bs.id);
            test.startTest();
            TS_MCOperating_Batch mcbatch = new TS_MCOperating_Batch(runDate,1);
            TS_MCOperating_Batch.hasException = true;
            Database.executeBatch(mcbatch);
            test.stopTest();
        }
        system.assert([SELECT Id FROM WorkOrderLineItem] != null);
    }
}