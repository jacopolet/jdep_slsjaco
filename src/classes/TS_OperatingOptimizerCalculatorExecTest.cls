/**
* @author        Francis Alindogan
* @date          12/2/2019
* @description   Test class for TS_OperatingOptimizerCalculator_Execute.
* @revision(s)
*/
@isTest
public with sharing class TS_OperatingOptimizerCalculatorExecTest {

    private static Account accRec;
    private static Apttus_Config2__AccountLocation__c accLoc;
    private static List<TS_Hierarchy_Derivation__mdt> get_postCodes;
    private static PhysicalAsset__c pAsset;
    private static Route__c routeRec;
    private static Route_Line_Item__c routeItem;
    private static Route__c routeRec2;
    private static Route_Line_Item__c routeItem2;
    private static OperatingSchedule__c opSched;
    private static Pricebook2 Pricebook2;
    private static PricebookEntry pbEntrySTD;
    private static PricebookEntry pbEntry;
    private static Product2 p;
    private static CountrySetting__c cSetting;
    
    private static Account accRec_NO;
    private static Apttus_Config2__AccountLocation__c accLoc_NO;
    private static PhysicalAsset__c pAsset_NO;
    private static PhysicalAsset__c pAsset_NO_2;
    private static Route__c routeRec_NO;
    private static Route_Line_Item__c routeItem_NO;
    private static Route_Line_Item__c routeItem_NO_2;
    private static OperatingSchedule__c opSched_NO;
    private static OperatingSchedule__c opSched_NO_2;
    private static Pricebook2 Pricebook2_NO;
    private static PricebookEntry pbEntrySTD_NO;
    private static PricebookEntry pbEntry_NO;
    private static Product2 p_NO;
            
    private static WorkOrder wo;
    private static WorkOrderLineItem woli;
    private static WorkOrder wo2;
    private static WorkOrderLineItem woli2;
    private static WorkOrder wo3;
    private static WorkOrderLineItem woli3;
            
    static void setupTestData(){
        
        List<Account> accList = TS_TestDataFactory.createAccounts(2);
        accRec = accList[0];
        insert accRec;
        
        //ROUTE OPG - NL
        accLoc =  TS_TestDataFactory.createAccountLocation(accRec.Id);
        accLoc.Mini_Sales_Organization__c = 'SAP_0111';
        accLoc.SAP_Customer_ID__c ='0001234';
        accLoc.Apttus_Config2__PostalCode__c = '1141';
        accLoc.Account_Location_Status__c = 'Valid';
        accLoc.MTTOLocationSpecific__c = 1;
        accLoc.AverageRoutePrep__c= 2;
        accLoc.MTTTWithinSite__c= 1;
        insert accLoc;

        pAsset = TS_TestDataFactory.createPhysicalAsset();
        pAsset.RecordTypeId = TS_UtilityClass.getRecordTypeIdByName('PhysicalAsset__c', 'Machine');
        pAsset.AccountLocation__c = accLoc.Id;
        pAsset.AssetStatus__c = 'Activated';
        pAsset.Machine_Care__c = TS_Constants.FULL_OPERATING;
        pAsset.MothballAssetIndicator__c =FALSE;
        pAsset.SalesOrganization__c = 'SAP_0111';
        pAsset.EndDate__c = system.today().addDays(5);
        insert pAsset;       
                
        Id opsRecordType = TS_UtilityClass.getRecordTypeIdByName('OperatingSchedule__c', 'Every Day');
        List <BusinessHours> businessHours_List = [SELECT Id, Name FROM BusinessHours WHERE Name = 'Default' LIMIT 1];
        opSched = TS_TestDataFactory.createOperatingScheduleTest(false, false, '1', '0', '0', '0', '0', '0', '0');
        opSched.Start_Date__c = Date.newInstance(2018,09,07);//Date.newInstance(2018,08,06);
        opSched.OP_Business_Hours__c = businessHours_List[0].id;
        opSched.Account_Location__c = accLoc.Id;
        opSched.PhysicalAsset__c = pAsset.Id;
        opSched.recordTypeId = opsRecordType;
        opSched.Schedule_Type__c = 'Regular';
        opSched.LM_1_Monday__c = '1';
        opSched.LM_1_Tuesday__c = '1';
        opSched.LM_1_Wednesday__c = '1';
        opSched.LM_1_Thursday__c = '1';
        opSched.LM_1_Friday__c = '1';
        opSched.LM_2_Monday__c = '1';
        opSched.SM_2_Monday__c = '1';            
        opSched.SM_2_Tuesday__c = '1';
        opSched.SM_2_Wednesday__c = '1';
        opSched.SM_2_Thursday__c = '1';
        opSched.SM_2_Friday__c = '1';
        opSched.SM_2_Saturday__c = '1';
        opSched.SM_2_Sunday__c = '1';
        opSched.C_1_Monday__c = '1';
        opSched.C_2_Monday__c = '1';
        insert opSched;
        
        routeRec = TS_TestDataFactory.createRoute('My Route', accLoc.Id);
        routeRec.Cups__c ='{"day_14":0,"day_13":0,"day_12":0,"day_11":0,"day_10":0,"day_9":0,"day_8":0,"day_7":0,"day_6":0,"day_5":0,"day_4":0,"day_3":0,"day_2":0,"day_1":1}';
        routeRec.Large__c='{"day_14":0,"day_13":0,"day_12":0,"day_11":0,"day_10":0,"day_9":0,"day_8":0,"day_7":0,"day_6":0,"day_5":0,"day_4":0,"day_3":0,"day_2":0,"day_1":1}';
        routeRec.Small__c = '{"day_14":0,"day_13":0,"day_12":0,"day_11":0,"day_10":0,"day_9":0,"day_8":0,"day_7":0,"day_6":0,"day_5":0,"day_4":0,"day_3":0,"day_2":0,"day_1":1}';
        insert routeRec;
                
        Route__c extraRoute = TS_TestDataFactory.createRoute('My Route', accLoc.Id);
		insert extraRoute;

        routeItem = TS_TestDataFactory.createRouteLine('My RouteLine', routeRec.Id);
        routeItem.PhysicalAssetId__c = pAsset.Id;
        insert routeItem;
                
        routeRec2 = TS_TestDataFactory.createRoute('My Route', accLoc.Id);
        routeRec2.Cups__c ='{"day_14":0,"day_13":0,"day_12":0,"day_11":0,"day_10":0,"day_9":0,"day_8":0,"day_7":0,"day_6":0,"day_5":0,"day_4":0,"day_3":0,"day_2":0,"day_1":1}';
        routeRec2.Large__c='{"day_14":0,"day_13":0,"day_12":0,"day_11":0,"day_10":0,"day_9":0,"day_8":0,"day_7":0,"day_6":0,"day_5":0,"day_4":0,"day_3":0,"day_2":0,"day_1":1}';
        routeRec2.Small__c = '{"day_14":0,"day_13":0,"day_12":0,"day_11":0,"day_10":0,"day_9":0,"day_8":0,"day_7":0,"day_6":0,"day_5":0,"day_4":0,"day_3":0,"day_2":0,"day_1":1}';
        insert routeRec2;
                      
        Route__c extraRoute2 = TS_TestDataFactory.createRoute('My Route2', accLoc.Id);
		insert extraRoute2;

        routeItem2 = TS_TestDataFactory.createRouteLine('My RouteLine2', routeRec2.Id);
        routeItem2.PhysicalAssetId__c = pAsset.Id;
        insert routeItem2;

        Product2 p = TS_TestDataFactory.createProductTest('My Product', 'Material Type');
        p.APTS_Sales_Organization__c = 'SAP_0111';
        insert p;

        pAsset.Product__c = p.Id;
        update pAsset;

        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pbEntrySTD= TS_TestDataFactory.createPricebookEntryTest(p.Id,pricebookId);
        Insert pbEntrySTD;

        Pricebook2 Pricebook = new Pricebook2(Name=' Pricebook', isActive=true, Sales_Organization__c ='SAP_0111');
        insert Pricebook;

        PricebookEntry pbEntry= TS_TestDataFactory.createPricebookEntryTest(p.Id,Pricebook.Id);
        pbEntry.MeanTimeToOperateSM__c =1;
        pbEntry.MeanTimeToOperateLM__c=2;
        pbEntry.MeanTimeToOperateC__c =1;
        pbEntry.isActive = true;
        Insert pbEntry;     

        get_postCodes = [SELECT Id, District__c, Postal_Code__c, District__r.Label FROM TS_Hierarchy_Derivation__mdt WHERE District__r.Label != null and Postal_Code__c != null];
        accLoc.Apttus_Config2__PostalCode__c = get_postCodes[0].Postal_Code__c;     
        update accLoc;
        
        List<CountrySetting__c> cList = new List<CountrySetting__c>();
        cSetting = TS_TestDataFactory.createCountrySettings();
        cSetting.RecordTypeId = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', 'Mean Time To Operate per Call Type');
        cSetting.Country__c = 'SAP_0111';
        cSetting.WorkOrderType__c = 'S20';
        cSetting.Mean_Time_To_Operate__c=1;
        cList.add(cSetting);
        
        CountrySetting__c cSet = TS_TestDataFactory.createCountrySettings();
        cset.RecordTypeId = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', 'Mean Time To Operate per Call Type');
        cset.Country__c = 'SAP_0975';
        cset.WorkOrderType__c = 'S20';
        cset.Mean_Time_To_Operate__c=1;
        cList.add(cset); 
        
        CountrySetting__c cSet2 = TS_TestDataFactory.createCountrySettings();
        cset2.RecordTypeId = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', 'Operating Task');
        cset2.Country__c = 'SAP_0111';
        cset2.DefaultStartTime__c = 5;
        cset2.DefaultEndTime__c = 16;
        cset2.Business_Hours__c =businessHours_List[0].id;
        cList.add(cset2); 
       	insert cList;
        
        
        Date mdate = date.today().toStartofWeek().addDays(2);
        mdate = mdate.addDays(1);
        mdate = mdate.addDays(-14);
        
        wo = TS_TestDataFactory.createWorkOrder();
        wo.Route_Number__c = '1';
        wo.RecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('Operating (Route) Work Order').getRecordTypeId();
        wo.WorkOrderType__c = Label.TS_Activity_Type_S20;    
        wo.SalesOrganization__c = 'SAP_0111';
        wo.Route_Id__c = extraRoute.Id;
        wo.Early_Start_Date__c = DateTime.newInstance(mdate.year(), mdate.month(), mdate.day(), 8, 0, 0);
        wo.SLA_Date__c = DateTime.newInstance(mdate.year(), mdate.month(), mdate.day(), 16, 0, 0);
        wo.OwnerId = UserInfo.getUserId();
        wo.Pricebook2Id = Pricebook.Id;
        insert wo;
        
        woli = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);
        woli.PhysicalAsset__c = pAsset.Id;
        woli.EarlyStart__c = DateTime.newInstance(mdate.year(), 1, mdate.day(), 8, 0, 0);
        woli.SLADate__c =  DateTime.newInstance(mdate.year(), 1, mdate.day(), 16, 0, 0);
        woli.StartDate__c =  DateTime.newInstance(mdate.year(), 1, mdate.day(), 8, 0, 0);
        woli.EndDate__c = DateTime.newInstance(mdate.year(), 1, mdate.day(), 11, 0, 0);
        woli.WorkOrderType__c = Label.TS_Activity_Type_S20; 
        woli.WorkOrderLineItemType__c = 'Small';
        woli.RecordTypeId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Operating Task').getRecordTypeId();
        woli.Status = 'Completed';
        woli.Route_Line_Item__c = routeItem.Id;
        woli.Operating_Bucket__c = 'A';
        woli.PricebookEntryId = pbEntry.Id;        
        woli.AccountLocation__c = accLoc.Id;
        insert woli;  
       
		wo2 = TS_TestDataFactory.createWorkOrder();
        wo2.Route_Number__c = '2';
        wo2.RecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('Operating (Route) Work Order').getRecordTypeId();
        wo2.WorkOrderType__c = Label.TS_Activity_Type_S20;    
        wo2.SalesOrganization__c = 'SAP_0111';
        wo2.Route_Id__c = extraRoute2.Id;
        wo2.Early_Start_Date__c = DateTime.newInstance(mdate.year(), mdate.month(), mdate.day(), 8, 0, 0);
        wo2.SLA_Date__c = DateTime.newInstance(mdate.year(), mdate.month(), mdate.day(), 16, 0, 0);
        wo2.OwnerId = UserInfo.getUserId();
        wo2.Pricebook2Id = Pricebook.Id;
        insert wo2;
        
        woli2 = TS_TestDataFactory.createWorkOrderLineItem(wo2.Id);
        woli2.PhysicalAsset__c = pAsset.Id;
        woli2.EarlyStart__c = DateTime.newInstance(mdate.year(), 1, mdate.day(), 8, 0, 0);
        woli2.SLADate__c =  DateTime.newInstance(mdate.year(), 1, mdate.day(), 16, 0, 0);
        woli2.StartDate__c =  DateTime.newInstance(mdate.year(), 1, mdate.day(), 8, 0, 0);
        woli2.EndDate__c = DateTime.newInstance(mdate.year(), 1, mdate.day(), 11, 0, 0);
        woli2.WorkOrderType__c = Label.TS_Activity_Type_S20; 
        woli2.WorkOrderLineItemType__c = 'Small';
        woli2.RecordTypeId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Operating Task').getRecordTypeId();
        woli2.Status = 'Completed';
        woli2.Route_Line_Item__c = routeItem2.Id;
        woli2.Operating_Bucket__c = 'A';
        woli2.PricebookEntryId = pbEntry.Id;      
        woli2.AccountLocation__c = accLoc.Id;
        insert woli2;                  
    }

    static void setupTestData2(){
        
        List<Account> accList = TS_TestDataFactory.createAccounts(2);
        accRec_NO = accList[1];
        insert accRec_NO;
                
        //ROUTE OPG - NORDICS
        accLoc_NO =  TS_TestDataFactory.createAccountLocation(accRec_NO.Id);
        accLoc_NO.SAP_Customer_ID__c ='0001234';
        accLoc_NO.Mini_Sales_Organization__c = 'SAP_0975';
        accLoc_NO.Apttus_Config2__PostalCode__c = '1141';
        accLoc_NO.Account_Location_Status__c = 'Valid';
        accLoc_NO.MTTOLocationSpecific__c = 1;
        accLoc_NO.AverageRoutePrep__c= 2;
        accLoc_NO.MTTTWithinSite__c= 1;
        insert accLoc_NO;
        
        List<PhysicalAsset__c> PA_NO_LIST = new List<PhysicalAsset__c>();

        pAsset_NO = TS_TestDataFactory.createPhysicalAsset();
        pAsset_NO.RecordTypeId = TS_UtilityClass.getRecordTypeIdByName('PhysicalAsset__c', 'Machine');
        pAsset_NO.AccountLocation__c = accLoc_NO.Id;
        pAsset_NO.AssetStatus__c = 'Activated';
        pAsset_NO.Machine_Care__c = 'Machine Clean Operating';
        pAsset_NO.MothballAssetIndicator__c = FALSE;
        pAsset_NO.SalesOrganization__c = 'SAP_0975';
        PA_NO_LIST.add(pAsset_NO);

        pAsset_NO_2 = TS_TestDataFactory.createPhysicalAsset();
        pAsset_NO_2.RecordTypeId = TS_UtilityClass.getRecordTypeIdByName('PhysicalAsset__c', 'Machine');
        pAsset_NO_2.AccountLocation__c = accLoc_NO.Id;
        pAsset_NO_2.AssetStatus__c = 'Activated';
        pAsset_NO_2.Machine_Care__c = 'Machine Clean Operating';
        pAsset_NO_2.MothballAssetIndicator__c = FALSE;
        pAsset_NO_2.SalesOrganization__c = 'SAP_0975';
        pAsset_NO_2.UniqueNumber__c = 'Test 2';
        PA_NO_LIST.add(pAsset_NO_2);
        
        insert PA_NO_LIST;

        List<OperatingSchedule__c> OP_NO_LIST = new List<OperatingSchedule__c>();

        Id opsRecordType_MCO = TS_UtilityClass.getRecordTypeIdByName('OperatingSchedule__c', 'Machine Clean Operating');
        List <BusinessHours> businessHours_List = [SELECT Id, Name FROM BusinessHours WHERE Name = 'Default' LIMIT 1];
        opSched_NO = TS_TestDataFactory.createOperatingScheduleTest(false, false, '1', '0', '0', '0', '1', '0', '0');
        opSched_NO.Account_Location__c = accLoc_NO.Id;
        opSched_NO.OP_Business_Hours__c = businessHours_List[0].id;
        opSched_NO.PhysicalAsset__c = pAsset_NO.Id;
        opSched_NO.recordTypeId = opsRecordType_MCO;
        opSched_NO.Schedule_Type__c = 'Machine Clean Operating';
        opSched_NO.Sales_Organization__c = 'SAP_0975';
        opSched_NO.FrequencyofL__c = 'Monthly';
        opSched_NO.Interval_in_Weeks__c = null;
        opSched_NO.Specific_Days_in_Week__c = false;
        opSched_NO.Schedule_Tasks_for_Holiday__c = false;
        opSched_NO.L_Months__c = '1;2;3;4;5;6;7;8;9;10;11;12';
        opSched_NO.Descaling_Months__c = '1;2;3;4;5;6;7;8;9;10;11;12';
        opSched_NO.Bottle_Months__c = '1;2;3;4;5;6;7;8;9;10;11;12';
        opSched_NO.PM_Months__c = '8';
        opSched_NO.Waterfilter_Months__c = '8';
        opSched_NO.Ingredients_Months__c = '1;2;3;4;5;6;7;8;9;10;11;12';
        opSched_NO.LM_1_Monday__c = '0';
        opSched_NO.LM_1_Tuesday__c = '0';
        opSched_NO.LM_1_Wednesday__c = '0';
        opSched_NO.LM_1_Thursday__c = '0';
        opSched_NO.LM_1_Friday__c = '0';
        opSched_NO.LM_1_Saturday__c = '0';
        opSched_NO.LM_1_Sunday__c = '0';
        OP_NO_LIST.add(opSched_NO);

        opSched_NO_2 = TS_TestDataFactory.createOperatingScheduleTest(false, false, '1', '0', '0', '0', '1', '0', '0');
        opSched_NO_2.OP_Business_Hours__c = businessHours_List[0].id;
        opSched_NO_2.PhysicalAsset__c = pAsset_NO_2.Id;
        opSched_NO_2.Account_Location__c = accLoc_NO.Id;
        opSched_NO_2.recordTypeId = opsRecordType_MCO;
        opSched_NO_2.Schedule_Type__c = 'Machine Clean Operating';
        opSched_NO_2.Sales_Organization__c = 'SAP_0975';
        opSched_NO_2.FrequencyofL__c = 'Weekly';
        opSched_NO_2.Interval_in_Weeks__c = '3';
        opSched_NO_2.Specific_Days_in_Week__c = false;
        opSched_NO_2.Schedule_Tasks_for_Holiday__c = false;
        opSched_NO_2.L_Months__c = '1;2;3;4;5;6;7;8;9;10;11;12';
        opSched_NO_2.Descaling_Months__c = '1;2;3;4;5;6;7;8;9;10;11;12';
        opSched_NO_2.Bottle_Months__c = '1;2;3;4;5;6;7;8;9;10;11;12';
        opSched_NO_2.PM_Months__c = '8';
        opSched_NO_2.Waterfilter_Months__c = '8';
        opSched_NO_2.Ingredients_Months__c = '1;2;3;4;5;6;7;8;9;10;11;12';
        opSched_NO_2.LM_1_Monday__c = '0';
        opSched_NO_2.LM_1_Tuesday__c = '0';
        opSched_NO_2.LM_1_Wednesday__c = '0';
        opSched_NO_2.LM_1_Thursday__c = '0';
        opSched_NO_2.LM_1_Friday__c = '0';
        opSched_NO_2.LM_1_Saturday__c = '0';
        opSched_NO_2.LM_1_Sunday__c = '0';
        OP_NO_LIST.add(opSched_NO_2);

        insert OP_NO_LIST;
        
        routeRec_NO = TS_TestDataFactory.createRoute('My Route', accLoc_NO.Id);
        routeRec_NO.Cups__c ='{"day_14":0,"day_13":0,"day_12":0,"day_11":0,"day_10":0,"day_9":0,"day_8":0,"day_7":0,"day_6":0,"day_5":0,"day_4":0,"day_3":0,"day_2":0,"day_1":1}';
        routeRec_NO.Large__c='{"day_14":0,"day_13":0,"day_12":0,"day_11":0,"day_10":0,"day_9":0,"day_8":0,"day_7":0,"day_6":0,"day_5":0,"day_4":0,"day_3":0,"day_2":0,"day_1":1}';
        routeRec_NO.Small__c = '{"day_14":0,"day_13":0,"day_12":0,"day_11":0,"day_10":0,"day_9":0,"day_8":0,"day_7":0,"day_6":0,"day_5":0,"day_4":0,"day_3":0,"day_2":0,"day_1":1}';
        insert routeRec_NO;

        List<Route_Line_Item__c> RITEM_NO_LIST = new List<Route_Line_Item__c>();

        routeItem_NO = TS_TestDataFactory.createRouteLine('My RouteLine', routeRec_NO.Id);
        routeItem_NO.PhysicalAssetId__c = pAsset_NO.Id;
        RITEM_NO_LIST.add(routeItem_NO);
        
        routeItem_NO_2 = TS_TestDataFactory.createRouteLine('My RouteLine 2', routeRec_NO.Id);
        routeItem_NO_2.PhysicalAssetId__c = pAsset_NO_2.Id;
        RITEM_NO_LIST.add(routeItem_NO_2);

        insert RITEM_NO_LIST;
        
        Product2 p_NO = TS_TestDataFactory.createProductTest('My Product 2', 'Material Type');
        p_NO.APTS_Sales_Organization__c = 'SAP_0975';
        insert p_NO;

        List<PhysicalAsset__c> PA_UPDATE = new List<PhysicalAsset__c>();
        pAsset_NO.Product__c = p_NO.Id;
        pAsset_NO.EndDate__c = system.today().addDays(5);
        PA_UPDATE.add(pAsset_NO);

        pAsset_NO_2.Product__c = p_NO.Id;
        pAsset_NO_2.EndDate__c = system.today().addDays(5);
        PA_UPDATE.add(pAsset_NO_2);

        update PA_UPDATE;

        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pbEntrySTD_NO = TS_TestDataFactory.createPricebookEntryTest(p_NO.Id, pricebookId);
        Insert pbEntrySTD_NO;

        Pricebook2 Pricebook_NO = new Pricebook2(Name=' Pricebook', isActive=true, Sales_Organization__c ='SAP_0975');
        insert Pricebook_NO;

        PricebookEntry pbEntry_NO = TS_TestDataFactory.createPricebookEntryTest(p_NO.Id, Pricebook_NO.Id);
        pbEntry_NO.MTTO_MCO_Descaling__c = 1.0;
        pbEntry_NO.MTTO_MCO_Bottles__c = 1.0;
        pbEntry_NO.MTTO_MCO_Large__c = 1.0;
        pbEntry_NO.MTTO_MCO_PM__c = 1.0;
        pbEntry_NO.MTTO_MCO_Waterfilter__c = 1.0;
        insert pbEntry_NO;
        
        get_postCodes = [SELECT Id, District__c, Postal_Code__c, District__r.Label FROM TS_Hierarchy_Derivation__mdt WHERE District__r.Label != null and Postal_Code__c != null];
        accLoc_NO.Apttus_Config2__PostalCode__c = get_postCodes[0].Postal_Code__c;     
        update accLoc_NO;        
        
        List<CountrySetting__c> cList = new List<CountrySetting__c>();
        CountrySetting__c cs_PM_Rule = new CountrySetting__c();
        cs_PM_Rule.Active__c = true;
        cs_PM_Rule.To__c = '7' ;
        cs_PM_Rule.From__c = '8' ;
        cs_PM_Rule.Country__c = 'SAP_0975';
        cs_PM_Rule.RecordTypeId =  TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', 'Machine Clean Operating PM Rules');
        cList.add(cs_PM_Rule);
        
        CountrySetting__c cSet = TS_TestDataFactory.createCountrySettings();
        cset.RecordTypeId = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', 'Mean Time To Operate per Call Type');
        cset.Country__c = 'SAP_0975';
        cset.WorkOrderType__c = 'S20';
        cset.Mean_Time_To_Operate__c=1;
        cList.add(cset);
        
        CountrySetting__c cSet2 = TS_TestDataFactory.createCountrySettings();
        cset2.RecordTypeId = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', 'Operating Task');
        cset2.Country__c = 'SAP_0975';
        cset2.DefaultStartTime__c = 5;
        cset2.DefaultEndTime__c = 16;
        cset2.Business_Hours__c =businessHours_List[0].id;
        cList.add(cset2); 
       	insert cList;
    }

    static testMethod void testCalculateMTTO() {
    User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
            Test.startTest();            
            setupTestData();    
            Map<String, Map<Integer, Decimal>> resultMap = new Map<String, Map<Integer, Decimal>>();
            List<Apttus_Config2__AccountLocation__c> accLocList = new List<Apttus_Config2__AccountLocation__c>();
            accLocList.add(accLoc);
            resultMap = TS_OperatingOptimizerCalculator_Execute.calculateMTTO(accLocList, 'test', false, '3po');
            resultMap = TS_OperatingOptimizerCalculator_Execute.calculateMTTO(accLocList, 'test', false, 'all');            
            Test.stopTest();
            System.assert(resultMap != null);
        }
    }
    
    static testMethod void testCalculateMTTO_NORDICS() {
    User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
            Test.startTest();            
            setupTestData2();            
            Map<String, Map<Integer, Decimal>> resultMap = new Map<String, Map<Integer, Decimal>>();
            List<Apttus_Config2__AccountLocation__c> accLocList = new List<Apttus_Config2__AccountLocation__c>();
            accLocList.add(accLoc_NO);
            resultMap = TS_OperatingOptimizerCalculator_Execute.calculateMTTO(accLocList, 'test', true, 'all');
            Test.stopTest();
            System.assert(resultMap != null);
        }
    }
    
    static testMethod void testCalculateMTTO_NORDICS2() {
    User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
            Test.startTest();            
            setupTestData2();
            opSched_NO_2.Specific_Days_in_Week__c = true;
            update opSched_NO_2;
            Map<String, Map<Integer, Decimal>> resultMap = new Map<String, Map<Integer, Decimal>>();
            List<Apttus_Config2__AccountLocation__c> accLocList = new List<Apttus_Config2__AccountLocation__c>();
            accLocList.add(accLoc_NO);
            resultMap = TS_OperatingOptimizerCalculator_Execute.calculateMTTO(accLocList, 'test', true, 'all');
            Test.stopTest();
            System.assert(resultMap != null);
        }
    }
    
    static testMethod void testCalculateMTTO_NORDICS3() {
    User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
            Test.startTest();            
            setupTestData2();
            opSched_NO_2.FrequencyofL__c = 'Daily';
            update opSched_NO_2;
            Map<String, Map<Integer, Decimal>> resultMap = new Map<String, Map<Integer, Decimal>>();
            List<Apttus_Config2__AccountLocation__c> accLocList = new List<Apttus_Config2__AccountLocation__c>();
            accLocList.add(accLoc_NO);
            resultMap = TS_OperatingOptimizerCalculator_Execute.calculateMTTO(accLocList, 'test', true, 'all');
            Test.stopTest();
            System.assert(resultMap != null);
        }
    } 
}