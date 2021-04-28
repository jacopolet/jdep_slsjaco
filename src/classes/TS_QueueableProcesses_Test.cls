//-------------------------------------------------------------------------------------------//
// Author       :   Karen Hung
// Created Date :   March 19, 2020
// Usage        :   Test class for TS_QueueableProcesses
//-------------------------------------------------------------------------------------------//
@isTest
public with sharing class TS_QueueableProcesses_Test {

    static Account acct;
    static Contact con;
    static Case c;             
    static WorkOrder wo;        
    static WorkOrderLineItem woli;
    static Resource__c engr;
    static PhysicalAsset__c pAsset;
    static Apttus_Config2__AccountLocation__c accLoc;
    static CountrySetting__c cs;
    static Route__c r;
    static Route_Line_Item__c rli;
    static WorkOrder wo4;
    static WorkOrderLineItem woli2;
    static WorkOrderLineItem woli4;
    static WorkOrderLineItem woli5;
    
    //FOR S41 CANCELLATION
    static Case s41_c;    
    static Case s41_c2;    
    static WorkOrder s41_wo;
    static WorkOrder s41_wo2;
    static WorkOrder s41_wo3;
    static WorkOrderLineItem s41_woli;
    static WorkOrderLineItem s41_woli2;
    static WorkOrderLineItem s41_woli3;
        

    static void setupTestData() {
        acct = new Account(Name='Account', Phone='+31302979111');
        insert acct;
        
        con = TS_TestDataFactory.createContact();  
        con.Preferred_Language__c = 'SAP_EN';
        Insert con;
        
        accLoc = TS_TestDataFactory.createAccountLocationTest('123456753', acct.Id);
        accLoc.Apttus_Config2__AccountId__c = acct.Id;
        accLoc.MTTOLocationSpecific__c = 1;
        insert accLoc;

        pAsset = TS_TestDataFactory.createPhysicalAsset();
        insert pAsset;

        c = TS_TestDataFactory.createFieldServiceCase();
        c.ContactId = con.Id;
        c.AccountId = acct.Id;
        c.PO_Number__c = '123456';
        c.SalesOrganization__c= 'SAP_0333';//Click__c = true;//added may 2018
        c.SubType__c = TS_Constants.TYPE_S32_WATERFILTER;
        c.PhysicalAsset__c = pAsset.Id;
        insert c;

        String csrecordType = Schema.SObjectType.CountrySetting__c.getRecordTypeInfosByName().get('Mean Time To Operate per Call Type').getRecordTypeId();
        cs = TS_TestDataFactory.createCountrySettings();
        cs.RecordTypeId = csrecordType;
        cs.WorkOrderType__c = Label.TS_Activity_Type_S20; 
        cs.Country__c = 'SAP_0111';
        cs.Active__c = true;
        cs.Mean_Time_To_Operate__c = 2;
        insert cs;
        
        /*WorkOrder work = TS_TestDataFactory.createWorkOrder();
        work.CaseId = c.Id;
        work.WorkOrderType__c = Label.TS_Case_SubType_CorrectMaint;
        work.ContactId = con.Id;
        insert work;

        WorkOrderLineItem wolItem = TS_TestDataFactory.createWorkOrderLineItem(work.Id);         
        wolItem.Case__c = c.Id;
        wolItem.PhysicalAsset__c = pAsset.Id;
        wolItem.WorkOrderLineItemType__c = Label.TS_Type_Task;
        wolItem.AccountLocation__c = accLoc.Id;
        wolItem.EndDate__c = DateTime.now();*/

        //Create product
        product2 prod = new product2();
        prod.Name = 'Operating Sched Product Test';
        prod.APTS_Material_Type__c = 'ZSPR';
        insert prod;

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
        
        r = TS_TestDataFactory.createRoute('TEST R', accLoc.Id);
        insert r;
    
        Route__c route2 = new Route__c();
        route2 = TS_TestDataFactory.createRoute('TEST R2', accLoc.Id);
        insert route2;

        rli = TS_TestDataFactory.createRouteLine('TEST RLI', r.Id);
        rli.PhysicalAssetId__c = pAsset.Id;
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
        woli.PhysicalAsset__c = pAsset.Id;
        woli.EarlyStart__c = DateTime.newInstance(mdate.year(), mdate.month(), mdate.day(), 8, 0, 0);
        woli.SLADate__c =  DateTime.newInstance(mdate.year(), mdate.month(), mdate.day(), 16, 0, 0);
        woli.StartDate__c =  DateTime.newInstance(mdate.year(), mdate.month(), mdate.day(), 8, 0, 0);
        woli.EndDate__c = DateTime.newInstance(mdate.year(), mdate.month(), mdate.day(), 11, 0, 0);
        woli.WorkOrderType__c = Label.TS_Activity_Type_S20; 
        woli.WorkOrderLineItemType__c = 'Large';
        woli.RecordTypeId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Operating Task').getRecordTypeId();
        woli.Status = 'Open';        
        woli.PricebookEntryId = pbe.Id;
            
        insert woli;  
        woli.Status = 'Completed';
        update woli;

        Date mdate2 = mdate.addDays(-14);
        WorkOrderLineItem woli3 = new WorkOrderLineItem();
        woli3 = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);
        woli3.PhysicalAsset__c = pAsset.Id;
        woli3.EarlyStart__c = DateTime.newInstance(mdate2.year(), mdate2.month(), mdate2.day(), 8, 0, 0);
        woli3.SLADate__c =  DateTime.newInstance(mdate2.year(), mdate2.month(), mdate2.day(), 16, 0, 0);
        woli3.StartDate__c =  DateTime.newInstance(mdate2.year(), mdate2.month(), mdate2.day(), 8, 0, 0);
        woli3.EndDate__c = DateTime.newInstance(mdate2.year(), mdate2.month(), mdate2.day(), 11, 0, 0);
        woli3.WorkOrderType__c = Label.TS_Activity_Type_S20; 
        woli3.WorkOrderLineItemType__c = 'Large';
        woli3.RecordTypeId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Operating Task').getRecordTypeId();
        woli3.Status = 'Open';
        woli3.PricebookEntryId = pbe.Id;        		
        insert woli3;
        woli3.Status = 'Completed';
        update woli3;
    
        WorkOrder wo2 = TS_TestDataFactory.createWorkOrder();
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
    
        woli2 =  TS_TestDataFactory.createWorkOrderLineItem(wo2.Id);
        woli2.PhysicalAsset__c = pAsset.Id;
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

        wo4 = TS_TestDataFactory.createWorkOrder();
        wo4.Route_Number__c = '2';
        wo4.RecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('Operating (Route) Work Order').getRecordTypeId();
        wo4.WorkOrderType__c = Label.TS_Activity_Type_S20;    
        wo4.SalesOrganization__c = 'SAP_0111';
        wo4.Route_Id__c = route2.Id;
        wo4.Early_Start_Date__c = DateTime.newInstance(mdate.year(), mdate.month(), mdate.day(), 8, 0, 0);
        wo4.SLA_Date__c = DateTime.newInstance(mdate.year(), mdate.month(), mdate.day(), 16, 0, 0);
        wo4.OwnerId = UserInfo.getUserId();
        wo4.Pricebook2Id = orgPB.Id;

        woli4 = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);
        woli4.EarlyStart__c = DateTime.newInstance(mdate.year(), mdate.month(), mdate.day(), 8, 0, 0);
        woli4.SLADate__c =  DateTime.newInstance(mdate.year(), mdate.month(), mdate.day(), 16, 0, 0);
        woli4.StartDate__c =  DateTime.newInstance(mdate.year(), mdate.month(), mdate.day(), 8, 0, 0);
        woli4.EndDate__c = DateTime.newInstance(mdate.year(), mdate.month(), mdate.day(), 11, 0, 0);
        woli4.WorkOrderType__c = Label.TS_Activity_Type_S20; 
        woli4.WorkOrderLineItemType__c = 'Large';
        woli4.PhysicalAsset__c = pAsset.Id;
        woli4.RecordTypeId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Operating Task').getRecordTypeId();
        woli4.Status = 'Open';
        woli4.PricebookEntryId = pbe.Id;      
    
        woli5 = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);
        woli5.EarlyStart__c = DateTime.newInstance(mdate.year(), mdate.month(), mdate.day(), 8, 0, 0);
        woli5.SLADate__c =  DateTime.newInstance(mdate.year(), mdate.month(), mdate.day(), 16, 0, 0);
        woli5.StartDate__c =  DateTime.newInstance(mdate.year(), mdate.month(), mdate.day(), 8, 0, 0);
        woli5.EndDate__c = DateTime.newInstance(mdate.year(), mdate.month(), mdate.day(), 11, 0, 0);
        woli5.WorkOrderType__c = Label.TS_Activity_Type_S20; 
        woli5.WorkOrderLineItemType__c = TS_Constants.ACTIVITY_WATERFILTER;
        woli5.PhysicalAsset__c = pAsset.Id;
        woli5.RecordTypeId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Operating Task').getRecordTypeId();
        woli5.Status = 'Open';
        woli5.PricebookEntryId = pbe.Id;          
        insert woli5;    

        //FOR S41 CANCELLATION
        s41_c = TS_TestDataFactory.createFieldServiceCase();
        s41_c.ContactId = con.Id;
        s41_c.AccountId = acct.Id;
        s41_c.Type = TS_Constants.CASE_TYPE_FIELDSERVICE;
        s41_c.PO_Number__c = '123456';
        s41_c.SalesOrganization__c= 'SAP_0111';//Click__c = true;//added may 2018
        s41_c.SubType__c = TS_Constants.TYPE_S30_PREVMAINTENANCE;
        s41_c.PhysicalAsset__c = pAsset.Id;
        insert s41_c;

        s41_c2 = TS_TestDataFactory.createFieldServiceCase();
        s41_c2.ContactId = con.Id;
        s41_c2.AccountId = acct.Id;
        s41_c2.Type = TS_Constants.CASE_TYPE_FIELDSERVICE;
        s41_c2.PO_Number__c = '123456';
        s41_c2.SalesOrganization__c= 'SAP_0111';//Click__c = true;//added may 2018
        s41_c2.SubType__c = TS_Constants.TYPE_S31_PRECHECK;
        s41_c2.PhysicalAsset__c = pAsset.Id;
        insert s41_c2;

        s41_wo = TS_TestDataFactory.createWorkOrder();           
        s41_wo.WorkOrderType__c = TS_Constants.TYPE_S30_PREVMAINTENANCE;    
        s41_wo.SalesOrganization__c = 'SAP_0111';        
        s41_wo.Status = TS_Constants.TS_Status_Open;
        insert s41_wo;        

        s41_wo2 = TS_TestDataFactory.createWorkOrder();           
        s41_wo2.WorkOrderType__c = TS_Constants.TYPE_S31_PRECHECK;    
        s41_wo2.SalesOrganization__c = 'SAP_0111';        
        s41_wo2.Status = TS_Constants.TS_Status_Open;
        insert s41_wo2;        

        s41_wo3 = TS_TestDataFactory.createWorkOrder();           
        s41_wo3.WorkOrderType__c = TS_Constants.WO_TYPE_S20_MACHINECARE;    
        s41_wo3.SalesOrganization__c = 'SAP_0111';        
        s41_wo3.Status = TS_Constants.TS_Status_Open;
        insert s41_wo3;        

        s41_woli = TS_TestDataFactory.createWorkOrderLineItem(s41_wo.Id);     
        s41_woli.Case__c = s41_c.Id;
        s41_woli.WorkOrderType__c = TS_Constants.TYPE_S30_PREVMAINTENANCE;
        s41_woli.PhysicalAsset__c = pAsset.Id;        
        s41_woli.AccountLocation__c = accLoc.Id;
        s41_woli.EndDate__c = DateTime.now();
        s41_woli.Status = TS_Constants.TS_Status_Open;
        insert s41_woli;

        s41_woli2 = TS_TestDataFactory.createWorkOrderLineItem(s41_wo2.Id);         
        s41_woli2.Case__c = s41_c2.Id;
        s41_woli2.WorkOrderType__c = TS_Constants.TYPE_S31_PRECHECK;
        s41_woli2.PhysicalAsset__c = pAsset.Id;        
        s41_woli2.AccountLocation__c = accLoc.Id;
        s41_woli2.EndDate__c = DateTime.now();
        s41_woli2.Status = TS_Constants.TS_Status_Open;
        insert s41_woli2;

        s41_woli3 = TS_TestDataFactory.createWorkOrderLineItem(s41_wo3.Id);                 
        s41_woli3.WorkOrderType__c = TS_Constants.WO_TYPE_S20_MACHINECARE;
        s41_woli3.PhysicalAsset__c = pAsset.Id;        
        s41_woli3.AccountLocation__c = accLoc.Id;
        s41_woli3.EndDate__c = DateTime.now();
        s41_woli3.Status = TS_Constants.TS_Status_Open;
        insert s41_woli3;
        //END S41 CANCELLATION
    }


    static testMethod void testQueueableProcesses() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();
            
            //insert woli;
            
            Test.startTest();            
            Map<Id,WorkOrderLineItem> extWoliMap = new Map<Id,WorkOrderLineItem>();
            extWoliMap.put(woli5.Id, woli5);
            Date mdate1 = date.today().toStartofWeek().addDays(2);
            mdate1 = mdate1.addDays(1);
            mdate1 = mdate1.addDays(-14);

            TS_QueueableProcesses process = new TS_QueueableProcesses();
            process.METHOD_CANCELOPENWFTASKS = true;
            process.METHOD_UPDATESEQUENCE_ACTUALDURATION = true;
            process.METHOD_EVALUATE_COMPLETED_SAP05 = true;
            process.METHOD_MISSINGPARTS_SALESORDER = true;                        
            process.caseWoli = new Set<String>{c.Id};
            process.assetIds = new List<String>{pAsset.Id};
            process.paSet = new Set<String>{pAsset.Id};
            process.woliList = new List<String>{woli.Id};            
            process.extWoliNewMap = extWoliMap;
            process.runDate = mdate1.addDays(14);
            process.taskDate =mdate1.addDays(1);
            process.comboSet = new Set<String>{pAsset.Id + woli4.WorkOrderLineItemType__c};
            woli2.SLADate__c = datetime.newInstance(process.taskDate.year(),process.taskDate.month(),process.taskDate.day(),0,0,0);
            woli4.SLADate__c =  datetime.newInstance(process.taskDate.year(),process.taskDate.month(),process.taskDate.day(),0,0,0);
            woli4.WorkorderId = wo.id;
            process.finalWolitoInsertList = new List<WorkOrderLineItem>{woli,woli4};            
            process.map_wo_woliList = new Map<WorkOrder, List<WorkOrderLineItem>>{ wo => new List<WorkOrderLineItem>{woli,woli2}};
            process.wotoInsertList = new List<WorkOrder>{wo4};

            System.enqueueJob(process);
            Test.stopTest();
            
            //Verify Results
            System.assertEquals(null,[SELECT Case__c FROM WorkOrderLineItem LIMIT 1].Case__c);
        }
    }
    
      static testMethod void testQueueableProcesses2() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();
                        
            //insert woli;
            Case c2 = TS_TestDataFactory.createFieldServiceCase();
            c2.ContactId = con.Id;
            c2.AccountId = acct.Id;
            c2.PO_Number__c = '123456';
            c2.SalesOrganization__c= 'SAP_0333';//Click__c = true;//added may 2018
            c2.SubType__c = TS_Constants.TYPE_S32_WATERFILTER;
            c2.PhysicalAsset__c = pAsset.Id;
            insert c2;
            
            WorkOrder newWO = TS_TestDataFactory.createWorkOrder();
            newWO.SalesOrganization__c='SAP_0111';
            newWO.Pricebook2Id = [SELECT Id FROM Pricebook2 where Sales_Organization__c='SAP_0111' limit 1].Id;
            insert newWO;
            
            WorkOrderLineItem woliNew = TS_TestDataFactory.createWorkOrderLineItem(newWO.Id);
            woliNew.WorkOrderType__c = Label.TS_Activity_Type_S20; 
            woliNew.WorkOrderLineItemType__c = 'PWD';
            woliNew.PhysicalAsset__c = pAsset.Id;
            woliNew.RecordTypeId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Operating Task').getRecordTypeId();
            woliNew.Status = 'Open';
            woliNew.PricebookEntryId = [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :newWO.Pricebook2Id].Id;          
            insert woliNew;    
            
            Test.startTest();            
            Map<Id,WorkOrderLineItem> extWoliMap = new Map<Id,WorkOrderLineItem>();
            extWoliMap.put(woli5.Id, woli5);
            Date mdate1 = date.today().toStartofWeek().addDays(2);
            mdate1 = mdate1.addDays(1);
            mdate1 = mdate1.addDays(-14);

            TS_QueueableProcesses process = new TS_QueueableProcesses();
            process.METHOD_CANCELOPENWFTASKS = true;
            process.METHOD_CANCELCONTRACTORDER_S41 = true;
            process.METHOD_UPDATESEQUENCE_ACTUALDURATION = true;
            process.METHOD_EVALUATE_COMPLETED_SAP05 = true;
            process.METHOD_MISSINGPARTS_SALESORDER = true;
            process.wotoInsertList = new List<WorkOrder>{newWO};
            process.caseWoli = new Set<String>{c.Id};
            process.assetIds = new List<String>{pAsset.Id};
            process.paSet = new Set<String>{pAsset.Id};
            process.woliList = new List<String>{woli.Id,woliNew.Id};            
            process.extWoliNewMap = extWoliMap;
            process.runDate = mdate1.addDays(14);
            process.taskDate =mdate1.addDays(1);
            process.comboSet = new Set<String>{pAsset.Id + woli4.WorkOrderLineItemType__c};
            woli2.SLADate__c = datetime.newInstance(process.taskDate.year(),process.taskDate.month(),process.taskDate.day(),0,0,0);
            woli4.SLADate__c =  datetime.newInstance(process.taskDate.year(),process.taskDate.month(),process.taskDate.day(),0,0,0);
            woli4.WorkorderId = wo.id;
            process.finalWolitoInsertList = new List<WorkOrderLineItem>{woli,woli4};            
            process.map_wo_woliList = new Map<WorkOrder, List<WorkOrderLineItem>>{ wo => new List<WorkOrderLineItem>{woli,woli2}};
            process.wotoInsertList = new List<WorkOrder>{wo4};
            TS_QueueableProcesses.hasException = true;

            System.enqueueJob(process);
            Test.stopTest();
            
            //Verify Results
            System.assertEquals(null,[SELECT Case__c FROM WorkOrderLineItem LIMIT 1].Case__c);
        }
    }


    static testMethod void testQueueableProcessesException() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();
        
            Test.startTest();
            Date mdate1 = date.today().toStartofWeek().addDays(2);
            mdate1 = mdate1.addDays(1);
            mdate1 = mdate1.addDays(-14);
            
            TS_QueueableProcesses process = new TS_QueueableProcesses();
            process.METHOD_CANCELOPENWFTASKS = true;
            process.METHOD_UPDATESEQUENCE_ACTUALDURATION = true;
            process.METHOD_EVALUATE_COMPLETED_SAP05 = true;
            process.METHOD_MISSINGPARTS_SALESORDER = true;
            process.METHOD_UPDATE_ORDERLINEITEM_AUTHORIZED = true;                        
            process.caseWoli = new Set<String>{c.Id};
            process.runDate = mdate1.addDays(14);
            process.taskDate =mdate1.addDays(1);
            process.assetIds = new List<String>{pAsset.Id};
            process.map_wo_woliList = new Map<WorkOrder, List<WorkOrderLineItem>>{ wo => new List<WorkOrderLineItem>{woli}};
            process.comboSet = new Set<String>{pAsset.Id + woli.WorkOrderLineItemType__c};
            process.finalWolitoInsertList = new List<WorkOrderLineItem>{woli};
            TS_QueueableProcesses.hasException = true;
			
            System.enqueueJob(process);
            Test.stopTest();
            
            //Verify Results
            System.assertEquals(null,[SELECT Case__c FROM WorkOrderLineItem LIMIT 1].Case__c);
        }
    }
    
    static testMethod void test_UPDATE_ORDERLINEITEM_AUTHORIZED() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        String STANDARD_DEAL = System.Label.APTS_Standard_Deal;
        
        System.runAs(u) {
            
            Test.startTest();
			
            Account acct = APTS_TestDataFactory.createAccount('JDETestAccount');
            acct.SAP_Customer_ID__c = '12345';
            insert acct;
                        
            Apttus_Config2__Order__c order = TS_TestDataFactory.createOrderRecord('Draft', 'New');
            order.Apttus_Config2__ShipToAccountId__c = acct.Id;
            order.Apttus_Config2__SoldToAccountId__c = acct.Id;
            order.Apttus_Config2__BillToAccountId__c = acct.Id;
            insert order;
            
            Apttus_Config2__OrderLineItem__c oli = new Apttus_Config2__OrderLineItem__c();
            oli.Apttus_Config2__OrderId__c = order.Id;
            oli.Apttus_Config2__Quantity__c = 1.0;
            insert oli;
                        
            oli.APTS_Installation_Date_Authorized__c = DateTime.now();
                
            TS_QueueableProcesses process = new TS_QueueableProcesses();
            process.METHOD_UPDATE_ORDERLINEITEM_AUTHORIZED = true;
            process.orderLineList = new List<Apttus_Config2__OrderLineItem__c>{oli} ;
            System.enqueueJob(process);
            
            Test.stopTest();
            //Verify Results
            System.assertEquals(1.0,oli.Apttus_Config2__Quantity__c);
        }
    }
    
    static testMethod void test_MISSINGPARTS_SALESORDER() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();
            
            Test.startTest();
            TS_QueueableProcesses process = new TS_QueueableProcesses();
            process.METHOD_MISSINGPARTS_SALESORDER = true;
            process.woliSet_missingParts = new Set<String>{woli.Id};
            System.enqueueJob(process);
            Test.stopTest();
            //Verify results
			system.assert([SELECT Id FROM Integration_Log__c WHERE Object__c = :INT_Constants.WOLI_MISSINGPARTS] !=null);
        }
    }

    static testMethod void test_CANCELOPENCASE() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {

            setupTestData();
            Test.startTest();
            
            Case c2 = TS_TestDataFactory.createFieldServiceCase();
            c2.ContactId = con.Id;
            c2.AccountId = acct.Id;
            c2.PO_Number__c = '123456';
            c2.SalesOrganization__c= 'SAP_0111';
            c2.SubType__c = TS_Constants.TYPE_S32_WATERFILTER;
            c2.PhysicalAsset__c = pAsset.Id;
            c2.Status = 'Open';
            insert c2;
            
            Case s41_c4 = TS_TestDataFactory.createFieldServiceCase();
            s41_c4.ContactId = con.Id;
            s41_c4.AccountId = acct.Id;
            s41_c4.Type = TS_Constants.CASE_TYPE_FIELDSERVICE;
            s41_c4.PO_Number__c = '123456';
            s41_c4.SalesOrganization__c= 'SAP_0111';//Click__c = true;//added may 2018
            s41_c4.SubType__c = 'S41';
            s41_c4.PhysicalAsset__c = pAsset.Id;
            insert s41_c4;
            
            WorkOrder s41_wo22 = TS_TestDataFactory.createWorkOrder();           
            s41_wo22.WorkOrderType__c = 'S41';    
            s41_wo22.SalesOrganization__c = 'SAP_0111';        
            s41_wo22.Status = TS_Constants.TS_Status_Open;
            insert s41_wo22;    
            
            WorkOrderLineItem s41_woli22 = TS_TestDataFactory.createWorkOrderLineItem(s41_wo22.Id);     
            s41_woli22.Case__c = s41_c4.Id;
            s41_woli22.WorkOrderType__c = 'S41';
            s41_woli22.PhysicalAsset__c = pAsset.Id;        
            s41_woli22.AccountLocation__c = accLoc.Id;
            s41_woli22.EndDate__c = DateTime.now();
            s41_woli22.Status = TS_Constants.TS_Status_Open;
            insert s41_woli22;
            
            s41_woli22.Status = TS_Constants.STATUS_COMPLETED;
            update s41_woli22;

            List<String> assetIds = new List<String>{pAsset.Id};            
            Set<String> caseWoli = new Set<String>{c.Id,s41_c4.Id,c2.Id};     
            Set<String> caseWoli2 = new Set<String>{s41_c.Id, s41_c2.Id};     
            Set<String> woIds = new Set<String>{s41_wo3.Id};       
            Map<String, String> woliReferenceMap = new Map<String, String>();
            woliReferenceMap.put(pAsset.Id, s41_woli.Id);
            woliReferenceMap.put(pAsset.Id, s41_woli2.Id);
            woliReferenceMap.put(pAsset.Id, s41_woli3.Id);
            woliReferenceMap.put(pAsset.Id, s41_woli22.Id);            
            
                        
            TS_QueueableProcesses process = new TS_QueueableProcesses();   
            process.METHOD_CANCELOPENWFTASKS = true;
            process.assetIds = assetIds;
            process.caseWoli = caseWoli;
            System.enqueueJob(process);

            TS_QueueableProcesses process2 = new TS_QueueableProcesses();
            process2.METHOD_CANCELCONTRACTORDER_S41 = true;
            process2.assetIds = assetIds;
            process2.caseWoli = caseWoli;
            System.enqueueJob(process2);
            
            TS_QueueableProcesses process3 = new TS_QueueableProcesses();
            process3.METHOD_CANCELOPENTASK_S41 = true; 
            process3.assetIds = assetIds;
            process3.caseWoli = caseWoli;
            process3.woliReferenceMap = woliReferenceMap;
            TS_QueueableProcesses.hasException = true;
            System.enqueueJob(process3);
            

            TS_QueueableProcesses process4 = new TS_QueueableProcesses();
            process4.METHOD_CANCELOPENCASE_S41 = true; 
            process4.CANCELOPENCASE(assetIds, caseWoli2);  
            TS_QueueableProcesses.hasException = true;
            System.enqueueJob(process4);
            

            TS_QueueableProcesses process5 = new TS_QueueableProcesses();
            process5.METHOD_CANCELOPENWO_S41 = true; 
            process5.CANCELOPENWO(assetIds, woIds);        
            TS_QueueableProcesses.hasException = true;
            System.enqueueJob(process5);

            Test.stopTest();
            //Verify results
			system.assert([SELECT Id FROM WorkOrderLineItem WHERE Status ='Canceled'].size() != 0);
        }
    }
    
    //METHOD TO TEST INSERT_DELETE_PERMSET
    static testMethod void test_INSERT_DELETE_PERMSET() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
            setupTestData();
            test.startTest();
            TS_QueueableProcesses process = new TS_QueueableProcesses();
            process.METHOD_3PO_PERMISSIONSET = true;
            process.forSchedPerm = new List<String>{u.Id};
            TS_QueueableProcesses.hasException = true;
            System.enqueueJob(process);
            
            TS_QueueableProcesses process2 = new TS_QueueableProcesses();
            process2.METHOD_3PO_PERMISSIONSET = true;
            process2.forPermRemoval = new List<String>{u.Id};
            TS_QueueableProcesses.hasException = true;
            System.enqueueJob(process2);
            test.stopTest();
            //Verify results
			system.assert([SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :u.Id].size() != 0);
        }
    }
}