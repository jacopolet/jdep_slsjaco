/**
* @author        Shashank Shekhar
* @date          7.5.2017           
* @description   Test class for WorkOrderTriggerHandler
* @revision(s)
*/
@isTest
private class WorkOrderTriggerHandlerTest {
    
    @testSetup
    static void dataSetup() {
        //Custom settings is being shared by all test class, if another test class has already inserted the record 
        //this test class will throw "UNABLE_TO_LOCK_ROW, unable to obtain exclusive access to this record"
        
        TriggerSettings__c trg = TriggerSettings__c.getOrgDefaults();
        trg.WorkOrderTrigger__c = true;
        trg.WorkOrderLineItemTrigger__c = true;
        upsert trg;      
     
        IntegrationTriggerSettings__c trg1 = IntegrationTriggerSettings__c.getOrgDefaults();
        trg1.IntegrationLogTrigger__c = true;
        upsert trg1; 
      

        ProcessBuilderSettings__c pb = new ProcessBuilderSettings__c();
        pb.WorkOrderPBFlows__c = true;
        pb.CasePBFlows__c = true;
        insert pb;
        
    }

   
    /**
    * @author        Marvin Gatchalian
    * @date          3.22.2018           
    * @description   Test method for validateOneOrderOnlyTest() in WorkOrderTriggerHandler
    * @revision(s)
    */      
    private static testMethod void validateOneOrderOnlyTest() {
        Account newAccount = new Account(Name='Sample Account', Phone='+31302979111');
        insert newAccount;
        
        BusinessHours bh = [select id,name from BusinessHours where isDefault = true limit 1 ];
        system.debug('bh is:'+bh);
        
        Apttus_Config2__Order__c orderRecord = TS_TestDataFactory.createOrderRecord('Pending', 'New');
        orderRecord.Apttus_Config2__AutoActivateOrder__c = false;
        orderRecord.Apttus_Config2__OrderDate__c = datetime.now();
        orderRecord.Apttus_Config2__PricingDate__c = datetime.now();
        orderRecord.Apttus_Config2__ShipToAccountId__c = newAccount.id;
        orderRecord.Apttus_Config2__SoldToAccountId__c = newAccount.id;
        orderRecord.CurrencyIsoCode = 'EUR';
        insert orderRecord;
        
        Id CSrecordTypeId=Schema.SObjectType.CountrySetting__c.getRecordTypeInfosByName().get('Country Scheduling Rules').getRecordTypeId();
        CountrySetting__c countrySetting = new CountrySetting__c(Name='Test CS', Country__c = 'SAP_0333',recordTypeId=CSrecordTypeId, DeliveryOffset__c=2, PickupOffset__c=1,RoundTrip__c=false, WorkshopOffset__c=1.0, TransportOffset__c=1.0, Active__c = true);
        insert countrySetting;
        
        //04.10.2018 Karen Hung Added country setting
        Id csCurrencyTypeId=Schema.SObjectType.CountrySetting__c.getRecordTypeInfosByName().get(Label.Currency_Code_Mappings).getRecordTypeId();
        CountrySetting__c countrySetting1 = new CountrySetting__c(Name='Test CS1', Country__c = 'SAP_0333', CurrencyIsoCode = 'EUR', Active__c = true, RecordTypeId = csCurrencyTypeId);
        insert countrySetting1;
        
        Contact con = TS_TestDataFactory.createContact();
        con.Accountid = newAccount.id;
        con.lastName = 'Test';
        con.Preferred_Language__c = 'SAP_NL';
        insert con;
        
        Case case1=TS_TestDataFactory.createFieldServiceCase();
        case1.BusinessHours=bh;
        case1.SalesOrganization__c='SAP_0333';
        case1.PickingDate__c = date.valueof('2017-07-22');
        case1.ApptusOrder__c = orderRecord.Id;
        case1.subtype__c='S40';
        case1.SalesOrganization__c = 'SAP_0333';
        case1.EarlyStartDate__c =date.valueof('2017-07-29');
        insert case1;
        
        Case case2=TS_TestDataFactory.createFieldServiceCase();
        case2.BusinessHours=bh;
        case2.SalesOrganization__c='SAP_0333';
        case2.PickingDate__c = date.valueof('2017-07-22');
        case2.ApptusOrder__c = orderRecord.Id;
        case2.subtype__c='S41';
        case2.SalesOrganization__c = 'SAP_0333';
        case2.EarlyStartDate__c = date.valueof('2017-07-23');
        case2.Work_Order_Count__c = 1;
        insert case2;
       
        WorkOrder parentWO = TS_TestDataFactory.createWorkOrder();
        parentWO.CaseId = case1.Id;
        parentWO.contactId=con.id;
        parentWO.WorkOrderType__c = Label.TS_Case_SubType_CorrectMaint;
        parentWO.ScheduleNow__c = true;
        
        try{insert parentWO;}
        catch (Exception e){  system.debug(e);}
        
        List<WorkOrder> woInserted1 = [Select id from WorkOrder where CaseId = :case1.Id];
        system.assertEquals(woInserted1.size(), 1);
        
        WorkOrder parentWO2 = TS_TestDataFactory.createWorkOrder();
        parentWO2.CaseId = case2.Id;
        parentWO2.contactId=con.id;
        parentWO2.WorkOrderType__c = Label.TS_Case_SubType_CorrectMaint;
        parentWO2.SalesOrganization__c = 'SAP_0333'; //Karen Hung 04.10.2018
        parentWO2.ScheduleNow__c = true;
        
        try{insert parentWO2;}
        catch (Exception e){  system.debug(e);}
        List<WorkOrder> woInserted2 = [Select id from WorkOrder where CaseId = :case2.Id];
        system.assertEquals(woInserted2.size(), 0);
        
        
        TriggerSettings__c trg = TriggerSettings__c.getOrgDefaults();
        trg.WorkOrderTrigger__c = false;
        update trg;
        
        delete woInserted1;
        List<WorkOrder> woDeleted = [Select id from WorkOrder where CaseId = :case1.Id];
        system.assertEquals(woDeleted.size(), 0);
        
    }

   
    /**
    * @author        Karen Hung
    * @date          28.02.2020           
    * @description   Test method for updateRelatedItems() in WorkOrderTriggerHandler
    * @revision(s)
    */      
    private static testMethod void updateRelatedItemsTest() {
        
        Pricebook2 orgPB = new Pricebook2();
        orgPB.name = 'NL Price Book';
        orgPB.IsActive = true;
        orgPB.Sales_Organization__c = 'SAP_0111';
        insert orgPB;
        
    	WorkOrder wo = TS_TestDataFactory.createWorkOrder();
        wo.Route_Number__c = '1';
        wo.RecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('Operating (Route) Work Order').getRecordTypeId();
        wo.WorkOrderType__c = Label.TS_Activity_Type_S20;    
        wo.SalesOrganization__c = 'SAP_0111';
        wo.OwnerId = UserInfo.getUserId();
        wo.Pricebook2Id = orgPB.Id;
		wo.Status= 'Open';
        insert wo;	

		WorkOrderLineItem woli = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);
        woli.WorkOrderType__c = Label.TS_Activity_Type_S20; 
        woli.WorkOrderLineItemType__c = 'Small';
        woli.RecordTypeId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Operating Task').getRecordTypeId();
        woli.Status = 'Open';		
		insert woli;
		
        Test.startTest();
		User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(usr) {
        	wo.Status='Dispatched';
			wo.StartDate__c = System.now();
			update wo;
			delete wo;
			undelete wo;
			WorkOrderTriggerHandler.hasException=true;
            wo.EndDate__c = System.now().addDays(1);
            update wo;
        }
		System.assertEquals(wo.Status, 'Dispatched');
		Test.stopTest();
        
        
    }

     /**
    * @author        Francis Allen Alindogan
    * @date          04.01.2020           
    * @description   Test method for createWOfromPA() in WorkOrderTriggerHandler
    * @revision(s)
    */  
    private static testMethod void testCreateWOfromPA(){
        
        BusinessHours  bs = [select id from BusinessHours where Name = 'Default'];
        
        List<CountrySetting__c> csettoInsert = new List<CountrySetting__c>();
        CountrySetting__c csetting = new CountrySetting__c();
        Id rt = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', Label.TS_OperatingTaskRecordType);
        csetting.RecordTypeId = rt;
        csetting.Active__c = TRUE;
        csetting.DefaultStartTime__c = 5;
        csetting.DefaultEndTime__c = 17;
        csetting.NumberDayToLookup__c = 10;
        csetting.Business_Hours__c = bs.Id;
        csetting.WorkOrderType__c = 'S20';
        csetting.Country__c = 'SAP_0111';
        csettoInsert.add(csetting);
        
        String recordTypeId = Schema.getGlobalDescribe().get('CountrySetting__c').getDescribe().getRecordTypeInfosByName().get('Country Survey').getRecordTypeId();
        CountrySetting__c cset2 = new CountrySetting__c();
        cset2.RecordTypeId = recordTypeId;
        cset2.Country__c = 'SAP_0111';
        cset2.Active__c = TRUE;
        cset2.WorkOrderType__c = 'S20';
        cset2.Activity_Type__c = 'Small';
        cset2.Survey_Type__c = 'OPG_Machine';
        csettoInsert.add(cset2);
        
        CountrySetting__c cset3 = new CountrySetting__c();
        cset3.RecordTypeId = recordTypeId;
        cset3.Country__c = 'SAP_0111';
        cset3.Active__c = TRUE;
        cset3.WorkOrderType__c = 'S20';
        cset3.Activity_Type__c = 'Cups';
        cset3.Survey_Type__c = 'OPG_Warehouse';
        csettoInsert.add(cset3);
        
        CountrySetting__c cset4 = TS_TestDataFactory.createCountrySettings();
        cset4.RecordtypeId = recordTypeId;
        cset4.WorkOrderType__c = 'S20';
        cset4.Activity_Type__c = 'Large';
        cset4.Country__c = 'SAP_0111';
        cset4.Survey_Type__c = 'OPG_Machine';
        csettoInsert.add(cset4);        
        insert csettoInsert;
    
        Pricebook2 orgPB = new Pricebook2();
        orgPB.name = 'NL Price Book';
        orgPB.IsActive = true;
        orgPB.Sales_Organization__c = 'SAP_0111';
        insert orgPB;

        product2 prod = new product2();
        prod.Name = 'Operating Sched Product Test';
        prod.APTS_Material_Type__c = 'ZSPR';
        insert prod;
        
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

        Account newAccount = new Account(Name='Sample Account', Phone='+31302979111');
        insert newAccount;

        Resource__c res = TS_TestDataFactory.createResourceTest('0000123');
        insert res;
        
        Apttus_Config2__AccountLocation__c accLoc = TS_TestDataFactory.createAccountLocation(newAccount.Id);
        accLoc.Third_Party_Resource__c = res.Id;
        insert accLoc;

        PhysicalAsset__c pa = TS_TestDataFactory.createPhysicalAsset();
        pa.AccountLocation__c = accLoc.Id;
        pa.SalesOrganization__c = 'SAP_0111';
        pa.Product__c = prod.Id;
        insert pa;         
        
        Route__c r = TS_TestDataFactory.createRoute('My Route', accLoc.Id);
        insert r;
        
        Route_Line_Item__c rli = TS_TestDataFactory.createRouteLine('My RouteLine', r.Id);
        rli.PhysicalAssetId__c = pa.Id;
        insert rli;
        
        WorkOrderTriggerHandler.surveySettingEnabled = true;
        WorkOrderTriggerHandler.operatingBucketEnabled = true;
        WorkOrder wo = TS_TestDataFactory.createWorkOrder();
        wo.OP_Physical_Asset__c = pa.Id;
        wo.SalesOrganization__c = 'SAP_0111';
        wo.Account_Location__c = accLoc.Id;
        wo.WorkOrderType__c = Label.TS_Activity_Type_S20; 
        wo.Task_Activity_Type__c = 'Large';
        wo.SLA_Date__c = date.valueof('2020-01-01');
        wo.Early_Start_Date__c = date.valueof('2020-01-01');	
        wo.OwnerId = UserInfo.getUserId();
        wo.Pricebook2Id = orgPB.Id;
        wo.Third_Party__c = true;
        insert wo;	

        WorkOrder woCR = TS_TestDataFactory.createWorkOrder();
        woCR.OP_Physical_Asset__c = pa.Id;
        woCR.SalesOrganization__c = 'SAP_0111';
        woCR.Account_Location__c = accLoc.Id;
        woCR.WorkOrderType__c = Label.TS_Activity_Type_S22; 
        woCR.Task_Activity_Type__c = 'Counter';
        woCR.OwnerId = UserInfo.getUserId();
        woCR.Pricebook2Id = orgPB.Id;
        insert woCR;	
        
        List<WorkOrder> woList = new List<WorkOrder>();
        woList.add(wo);
        
        List<WorkOrderLineItem>  woliList = [SELECT Id, WorkOrderId FROM WorkOrderLineItem WHERE WorkOrderId =: wo.Id OR WorkOrderId =: woCR.Id];
        WorkOrderTriggerHandler.createOperatingIntegLog(woList);
        WorkOrderTriggerHandler.checkForIntegration(woliList);
        System.assertEquals(woliList.size(), 2);
        
    }

    /**
    * @author        Francis Allen Alindogan
    * @date          08.06.2020           
    * @description   Test method for calculateLSPDate() in WorkOrderTriggerHandler
    * @revision(s)
    */  
    private static testMethod void calculateLSPDate(){

        Pricebook2 orgPB = new Pricebook2();
        orgPB.name = 'NL Price Book';
        orgPB.IsActive = true;
        orgPB.Sales_Organization__c = 'SAP_0111';
        insert orgPB;

        WorkOrder wo = TS_TestDataFactory.createWorkOrder();
        wo.Route_Number__c = '1';
        wo.RecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get(TS_Constants.TS_WO_RECORDTYPE_OPERATINGWO).getRecordTypeId();
        wo.WorkOrderType__c = Label.TS_Activity_Type_S20;    
        wo.SalesOrganization__c = 'SAP_0111';
        wo.OwnerId = UserInfo.getUserId();
        wo.Pricebook2Id = orgPB.Id;
        wo.Status= 'Open';
        WorkOrderTriggerHandler.surveySettingEnabled = true;
        insert wo;	
		
        Resource__c res = TS_TestDataFactory.createResourceSingle('12344');
        res.EmailAddress__c = 'test@gmail.com';
        insert res;
        
        WorkOrderLineItem woli = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);
        woli.WorkOrderType__c = Label.TS_Activity_Type_S20; 
        woli.WorkOrderLineItemType__c = 'Small';
        woli.RecordTypeId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Operating Task').getRecordTypeId();
        woli.Status = 'Open';	
        woli.RequiresLSP__c = true;
        woli.ExecutingEngineer__c = res.Id;
		insert woli;
        
        Test.startTest();
		User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(usr) {
            WorkOrderTriggerHandler.surveySettingEnabled = true;
            WorkOrderTriggerHandler.provideAccessEnabled = true;
            wo.OwnerId = usr.Id;
            wo.Status= 'Open';
			update wo;			
        }
		System.assertEquals(wo.Status, 'Open');
		Test.stopTest();
    }
    
}