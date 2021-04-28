//-------------------------------------------------------------------------------------------//
// Author       :   Karen Mae Hung
// Created Date :   Jan 19, 2021
// Usage        :   DOO-5148 Test Class for postload report
//-------------------------------------------------------------------------------------------//
@isTest
public class TS_PostLoadReport_Test {

    static OperatingSchedule__c testOS;
    static PhysicalAsset__c pa2;
    static PhysicalAsset__c pa3;
    static Route__c r;
    static Route_Line_Item__c rli;
    static WorkOrder wo;
    static WorkOrderLineItem woli;
    static CountrySetting__c csetting;
    static Apttus_Config2__AccountLocation__c accLocation;
    
    //@testSetup
    public static void dataSetup(String lTask, String sTask, String cTasks, String machineCare, Boolean isRinse, Boolean is247) {
        
            BusinessHours  bs = [select id from BusinessHours where Name = 'Default'];
            Id bsId = bs.id;
            
            id rt = TS_UtilityClass.getRecordTypeIdByName('OperatingSchedule__c', 'Every Day');
            id rtpa = TS_UtilityClass.getRecordTypeIdByName('PhysicalAsset__c', 'Machine');
        	
        	csetting = new CountrySetting__c();
        	csetting.RecordTypeId = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', 'Mean Time To Operate per Call Type');
        	csetting.Mean_Time_To_Operate__c = 1;
			csetting.Active__c = TRUE;
        	csetting.WorkOrderType__c = 'S20';
        	insert csetting;
        
        	CountrySetting__c cset = new CountrySetting__c();
            cset.RecordTypeId = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', 'Mean Time To Operate per Call Type');
        	cset.Mean_Time_To_Operate__c = 2;
			cset.Active__c = TRUE;
        	cset.WorkOrderType__c = 'S20';
        	insert cset;
                
            //Create product
            product2 prod = new product2();
            prod.Name = 'Operating Sched Product Test';
            prod.APTS_Material_Type__c = 'ZSPR';
            insert prod;
            
            List<Account> account_List = TS_TestDataFactory.createAccounts(1);
            insert account_List;
            
            accLocation = TS_TestDataFactory.createAccountLocationTest('454545577868',account_List[0].Id );
        	accLocation.AverageRoutePrep__c = 1;
        	accLocation.MTTTWithinSite__c = 2;
            accLocation.MTTOLocationSpecific__c = 1;
            accLocation.Mini_Sales_Organization__c = 'SAP_0111';
            insert accLocation;

            PhysicalAsset__c pa = TS_TestDataFactory.createPhysicalAsset();
            pa.RecordTypeId = rtpa;
            pa.Machine_Care__c = machineCare;
            pa.StartDate__c = date.today().addDays(-365);
            pa.EndDate__c = date.today().addDays(365);
            pa.TypeOfContract__c = 'Sales';
            pa.AssetStatus__c = 'Activated';
            pa.ActiveContract__c = true;
            pa.SalesOrganization__c = 'SAP_0111';
            pa.Product__c = prod.id;
            pa.UniqueNumber__c = '123ABC';
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
            pa2.SalesOrganization__c = 'SAP_0111';
            pa2.Product__c = prod.id;
            pa2.UniqueNumber__c = '456DEF';
            pa.AccountLocation__c = accLocation.Id;
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
            pa3.UniqueNumber__c = '789GHI';
            pa.AccountLocation__c = accLocation.Id;
            insert pa3;
            
            testOS = TS_TestDataFactory.createOperatingSchedule();
            testOS.PhysicalAsset__c = pa.id;
            testOS.RecordTypeId = rt;
            testOS.Start_Date__c = date.today().toStartofWeek().addDays(1);
            testOS.Interval_in_Weeks__c = '1';
            testOS.LM_1_Monday__c = lTask;
            testOS.SM_1_Monday__c = sTask;
            testOS.SM_1_Friday__c = 'PM';
            testOS.SM_1_Thursday__c = '1';
            testOS.SM_2_Thursday__c = '1';
            testOS.SM_1_Wednesday__c = 'PM';
            testOS.C_1_Monday__c = cTasks;
            testOS.R_1_Monday__c = isRinse;
            testOS.R_1_Tuesday__c = isRinse;
            testOS.OP_247Customer__c = is247;
            Insert testOS;
            
            Id rtCs = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', Label.TS_OperatingTaskRecordType);
            CountrySetting__c testCS = TS_TestDataFactory.createCountrySettings();
            
            testCS.Business_Hours__c = bsId;
            testCS.RecordTypeId = rtCs;
            testCS.NumberDayToLookup__c  = 10;
            Insert testCS;
            
            //Create Standard Pricebook
            //Create sales org pricebook
            pricebook2 orgPB = new pricebook2();
            orgPB.name = 'NL Price Book';
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
        	pbe.MeanTimeToOperateC__c = 1;
            pbe.MeanTimeToOperateLM__c = 1;
        	pbe.MeanTimeToOperateSM__c = 1;
            insert pbe;
            

            r = TS_TestDataFactory.createRoute('TEST R', accLocation.Id);
            insert r;
        
        	Route__c route2 = new Route__c();
        	route2 = TS_TestDataFactory.createRoute('TEST R2', accLocation.Id);
        	insert route2;

            rli = TS_TestDataFactory.createRouteLine('TEST RLI', r.Id);
            rli.PhysicalAssetId__c = pa.Id;
            insert rli;
        	
       		Date mdate = date.today().toStartofWeek().addDays(2);
        	mdate = mdate.addDays(1);
        	mdate = mdate.addDays(-14);
        
        	wo = TS_TestDataFactory.createWorkOrder();
        	wo.Route_Number__c = '1';
        	wo.RecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('Operating (Route) Work Order').getRecordTypeId();
        	wo.WorkOrderType__c = Label.TS_Activity_Type_S20;    
        	wo.SalesOrganization__c = 'SAP_0111';
        	wo.Route_Id__c = r.Id;
        	wo.Early_Start_Date__c = DateTime.newInstance(mdate.year(), mdate.month(), mdate.day(), 8, 0, 0);
            wo.SLA_Date__c = DateTime.newInstance(mdate.year(), mdate.month(), mdate.day(), 16, 0, 0);
        	wo.OwnerId = UserInfo.getUserId();
        	wo.Pricebook2Id = orgPB.Id;
       		insert wo;
        	
        	woli = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);
        	woli.PhysicalAsset__c = pa.Id;
        	woli.EarlyStart__c = DateTime.newInstance(mdate.year(), mdate.month(), mdate.day(), 8, 0, 0);
        	woli.SLADate__c =  DateTime.newInstance(mdate.year(), mdate.month(), mdate.day(), 16, 0, 0);
        	woli.StartDate__c =  DateTime.newInstance(mdate.year(), mdate.month(), mdate.day(), 8, 0, 0);
           	woli.EndDate__c = DateTime.newInstance(mdate.year(), mdate.month(), mdate.day(), 11, 0, 0);
        	woli.WorkOrderType__c = Label.TS_Activity_Type_S20; 
        	woli.WorkOrderLineItemType__c = 'Small';
        	woli.RecordTypeId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Operating Task').getRecordTypeId();
        	woli.Status = 'Open';
        	woli.PricebookEntryId = pbe.Id;
        		
			insert woli;  
        	woli.Status = 'Completed';
        	update woli;
        
        	
        	WorkOrder wo2 = new WorkOrder();
        	wo2 = TS_TestDataFactory.createWorkOrder();
        	wo2.Route_Number__c = '2';
        	wo2.RecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('Operating (Route) Work Order').getRecordTypeId();
        	wo2.WorkOrderType__c = Label.TS_Activity_Type_S20;    
        	wo2.SalesOrganization__c = 'SAP_0111';
        	wo2.Route_Id__c = route2.Id;
        	wo2.Early_Start_Date__c = DateTime.newInstance(mdate.year(), mdate.month(), mdate.day(), 8, 0, 0);
            wo2.SLA_Date__c = DateTime.newInstance(mdate.year(), mdate.month(), mdate.day(), 16, 0, 0);
        	wo2.OwnerId = UserInfo.getUserId();
        	wo2.Pricebook2Id = orgPB.Id;
       		insert wo2;
        
        	WorkOrderLineItem woli2 = new WorkOrderLineItem();
        	woli2 = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);
        	woli2.PhysicalAsset__c = pa.Id;
        	woli2.EarlyStart__c = DateTime.newInstance(mdate.year(), mdate.month(), mdate.day(), 8, 0, 0);
        	woli2.SLADate__c =  DateTime.newInstance(mdate.year(), mdate.month(), mdate.day(), 16, 0, 0);
        	woli2.StartDate__c =  DateTime.newInstance(mdate.year(), mdate.month(), mdate.day(), 8, 0, 0);
           	woli2.EndDate__c = DateTime.newInstance(mdate.year(), mdate.month(), mdate.day(), 11, 0, 0);
        	woli2.WorkOrderType__c = Label.TS_Activity_Type_S20; 
        	woli2.WorkOrderLineItemType__c = 'Large';
        	woli2.RecordTypeId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Operating Task').getRecordTypeId();
        	woli2.Status = 'Open';
        	woli2.PricebookEntryId = pbe.Id;        		
			insert woli2;
        	woli2.Status = 'Completed';
        	update woli2;
        	
    }
	
    /*test method to run regularly*/
    private static testMethod void RegularBatchTest() {
        User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        usr.LastName = 'JDE-Apex-Batch';
        update usr;
        
        System.runAs(usr) {

            dataSetup('1', 'PM', '1', 'Full Operating', true, true);  // lTask,  sTask,  cTasks, sTomorrow, isRinse,  is247
            testOS.LM_1_Monday__c = '1';
            testOS.LM_1_Tuesday__c = '1';
            testOS.LM_1_Wednesday__c = '1';
            testOS.LM_1_Thursday__c = '1';
            testOS.LM_1_Friday__c = '1';
            
            testOS.LM_2_Monday__c = '1';
            
            testOS.C_1_Monday__c = '1';
            testOS.C_2_Monday__c = '1';
            
            testOS.SM_1_Monday__c = 'PM';
            testOS.SM_1_Tuesday__c = '1';
            testOS.SM_1_Wednesday__c = '1';
            testOS.SM_1_Thursday__c = '1';
            testOS.SM_1_Friday__c = '1';
            testOS.SM_1_Saturday__c = '1';
            testOS.SM_1_Sunday__c = '1';
			
            testOS.R_1_Monday__c = true;
            testOS.R_1_Tuesday__c = true;
            testOS.R_1_Wednesday__c = true;
            testOS.R_1_Thursday__c = true;
            
            testOS.R_2_Wednesday__c = true;
            testOS.R_2_Thursday__c = true;
            testOS.R_2_Friday__c = true;
            testOS.R_2_Saturday__c = true;           
            
            testOS.SM_2_Monday__c = 'PM';            
            testOS.SM_2_Tuesday__c = '1';
            testOS.SM_2_Wednesday__c = '1';
            testOS.SM_2_Thursday__c = '1';
            testOS.SM_2_Friday__c = '1';
            testOS.SM_2_Saturday__c = '1';
            testOS.SM_2_Sunday__c = '1';
            
            update testOS;
            
            Id rtCs = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', Label.TS_OperatingTaskRecordType);
            Date mdate = date.today().toStartofWeek().addDays(2);
            BusinessHours  bs = [select id from BusinessHours where Name = 'Default'];
            String bhId = String.valueOf(bs.id);
            String batchType = 'regularbatch';
            
            Resource__c res = TS_TestDataFactory.createResourceTest('0981231');
            res.EmailAddress__c = 'thirdparty@gmail.com';
            insert res;
            
            accLocation.Third_Party_Resource__c = res.Id;
            update accLocation;                        

            Test.startTest();       
                CountrySetting__c cs = [Select id, DefaultStartTime__c, DefaultEndTime__c, NumberDayToLookup__c , Business_Hours__r.Id
                                                     From CountrySetting__c
                                                     Where Business_Hours__c = :bhId And RecordTypeId = :rtCs AND Active__c = true Limit 1];
                
                TS_OperatingTaskUtility tsUtils = new TS_OperatingTaskUtility();
                Map<Integer, boolean> fHM = tsUtils.getFutureHolidayMap (Integer.valueOf(cs.NumberDayToLookup__c), bhId, mdate);
                Map<Integer, boolean> pHM = tsUtils.getPastHolidayMap (Integer.valueOf(cs.NumberDayToLookup__c), bhId, mdate);
                
            	TS_PostLoadReport.hasException = true;
            	TS_PostLoadReport.SOQL_OVERRIDE = true;
            	TS_PostLoadReport.NEW_SOQL_STRING ='SELECT Id, WorkOrderId, WorkOrderType__c, JDELineItemNumber__c, Status, OP_CancelationReasonMachine__c, CreatedBy.LastName, WorkOrder.WorkOrderNumber,WorkOrder.Early_Start_Date__c,  WorkOrderLineItemType__c, AccountLocation__c, SLADate__c, ' +
                                                    'AccountLocation__r.Name,  AccountLocation__r.Apttus_Config2__Street__c, AccountLocation__r.Apttus_Config2__City__c, AccountLocation__r.Apttus_Config2__PostalCode__c, AccountLocation__r.Third_Party_Resource__c, '+
                                                    'AccountLocation__r.Third_Party_Resource__r.EmailAddress__c, AccountLocation__r.Third_Party_Resource__r.Name,Operating_Bucket__c, '+
                                                    'PhysicalAsset__r.Name, PhysicalAsset__r.Product__r.Name, PhysicalAsset__r.Building__c, PhysicalAsset__r.Floor__c, PhysicalAsset__r.Area__c, PhysicalAsset__r.CustomerReferenceNumber__c '+
                                                    'FROM WorkOrderLineItem '+
                                                    'WHERE WorkOrderType__c = \'S20\' '+
                                                    'AND WorkOrderLineItemType__c != \'Large\'';
                
                TS_RouteTask_Batch regBatch = new TS_RouteTask_Batch
                                                    (batchType, mdate.addDays(1), fHM, pHM, cs, true, 1); 
                                                            
                Database.executeBatch(regBatch);
            
            Test.stopTest();
            
        }
        system.assert([select id from workorderlineitem] != null); 
    }
}