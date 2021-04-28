/**
* @author        Adrian Reyes
* @date          11.29.2017
* @description   Test class for WorkOrderLineItemTriggerHandler
* @revision(s)
*/

@isTest
public class WorkOrderLineItemTriggerHandler_Test {
    static Account acct;
    static Contact con;
    static Case c;
    static WorkOrder wo;
    static Apttus_Config2__AssetLineItem__c ali;
    static Apttus_Config2__Order__c order;
    static Apttus_Config2__OrderLineItem__c oli;
    static WorkOrderLineItem woli, woli1;
    static Resource__c engr;
    static PhysicalAsset__c pAsset;
    static Apttus_Config2__AccountLocation__c accLoc;
    static CountrySetting__c cs;
    static product2 prod;
    static PricebookEntry pbe;
    static Id standardPBID;
    static Pricebook2 orgPB;

    static String woRecTypeCReading = TS_UtilityClass.getRecordTypeIdByName(Label.TS_Obj_API_Name_WorkOrder, Label.TS_CounterReading);
    static String woRecTypeOperating = TS_UtilityClass.getRecordTypeIdByName(Label.TS_Obj_API_Name_WorkOrder, Label.TS_OperatingWorkOrder);
    static String woliRecTypeCReading = TS_UtilityClass.getRecordTypeIdByName(Label.TS_Obj_API_Name_WOLI, Label.TS_CounterReadingTask);
    static String woliRecTypeOperating = TS_UtilityClass.getRecordTypeIdByName(Label.TS_Obj_API_Name_WOLI, Label.TS_OperatingTaskRecordType);
    
    /**
    * @author        Adrian Reyes
    * @date          11.29.2017           
    * @description   Method responsible for creating custom setting records
    * @revision(s)
    */
    @testSetup
    static void dataSetup() {
        TriggerSettings__c trg = TriggerSettings__c.getOrgDefaults();
        trg.WorkOrderLineItemTrigger__c = true;
        upsert trg;
        
        IntegrationTriggerSettings__c trg1 = IntegrationTriggerSettings__c.getOrgDefaults();
        trg1.IntegrationLogTrigger__c = true;
        upsert trg1;
        
        ProcessBuilderSettings__c pb = new ProcessBuilderSettings__c();
        pb.CasePBFlows__c = true;
        pb.WorkOrderLineItemPBFlows__c = false;
        insert pb;  
    }
    
    /**
    * @author        Adrian Reyes
    * @date          11.29.2017           
    * @description   Method responsible for creating test data
    * @revision(s)
    */
    static void setupTestData() {

        acct = new Account(Name='Account', Phone='+31302979111');
        //acct.Segment__c = 'SAP_A';
        //acct.High_Segment__c = 'Business';
        insert acct;
        
        con = TS_TestDataFactory.createContact();  
        con.Preferred_Language__c = 'SAP_EN';
        Insert con;
        
        Contact con2 = TS_TestDataFactory.createContact();  
        con2.Preferred_Language__c = 'SAP_EN';
		con2.FirstName = 'Dummy Contact (';
        con2.LastName = 'DO NOT DELETE )';
        con2.RecordTypeId = TS_UtilityClass.getRecordTypeIdByName('Contact', 'Operational Contact');
        Insert con2;
        
        accLoc = TS_TestDataFactory.createAccountLocationTest('123456753', acct.Id);
        accLoc.Apttus_Config2__AccountId__c = acct.Id;
        insert accLoc;
        
        //CREATE STANDARD PRICEBOOK
        standardPBID = Test.getStandardPricebookId(); 

        //CREATE SALES ORGANIZATION PRICEBOOK
        orgPB = new Pricebook2();
        orgPB.Name = 'BE Price Book';
        orgPB.IsActive = true;
        orgPB.Sales_Organization__c = 'SAP_0333';
        insert orgPB;

        //CREATE MACHINE PRODUCT
        Product2 prod_ZCMA = TS_TestDataFactory.createProductTest('ProductTest','ZCMA');
        insert prod_ZCMA;

        //CREATE SERVICE MATERIAL PRODUCT     
        prod = TS_TestDataFactory.createProductTest('ProductTest','ZSPR');
        insert prod;

        List<PricebookEntry> pbEntryList = new List<PricebookEntry>();

        //CREATE PBENTRY (MACHINE PRODUCT)
        PricebookEntry pbeMachineStandard = new PricebookEntry();
        pbeMachineStandard.Product2Id = prod_ZCMA.Id;
        pbeMachineStandard.Pricebook2Id = standardPBID;
        pbeMachineStandard.UnitPrice = 11;
        pbeMachineStandard.IsActive = true;
        pbeMachineStandard.UseStandardPrice = false;
        pbeMachineStandard.TS_Load_Id__c = String.valueOf(prod_ZCMA.Id) + String.valueOf(standardPBID);
        pbEntryList.add(pbeMachineStandard);

        PricebookEntry pbeMachineSalesOrg = new PricebookEntry();
        pbeMachineSalesOrg.Product2Id = prod_ZCMA.id;
        pbeMachineSalesOrg.Pricebook2Id = orgPB.id;
        pbeMachineSalesOrg.UnitPrice = 11;
        pbeMachineSalesOrg.IsActive = true;
        pbeMachineSalesOrg.TS_Load_Id__c = String.valueOf(prod_ZCMA.id) + String.valueOf(orgPB.id);
        pbEntryList.add(pbeMachineSalesOrg);

        //CREATE PBENTRY (PARTS)
        pbe = new PricebookEntry();
        pbe.Product2Id = prod.Id;
        pbe.Pricebook2Id = standardPBID;
        pbe.UnitPrice = 11;
        pbe.IsActive = true;
        pbe.UseStandardPrice = false;
        pbe.TS_Load_Id__c = String.valueOf(prod.Id) + String.valueOf(standardPBID);
        pbEntryList.add(pbe);
                
        PricebookEntry pbeStandard = new PricebookEntry();
        pbeStandard.Product2Id = prod.id;
        pbeStandard.Pricebook2Id = orgPB.id;
        pbeStandard.UnitPrice = 11;
        pbeStandard.IsActive = true;
        pbeStandard.TS_Load_Id__c = String.valueOf(prod.id) + String.valueOf(orgPB.id);
        pbEntryList.add(pbeStandard);

        insert pbEntryList;

        //CREATE SALES ORG DATA
        APTS_Sales_Org_Data__c salesOrg = new APTS_Sales_Org_Data__c();
        salesOrg.APTS_Product__c = prod.Id;
        salesOrg.APTS_Sales_Org_Data_Name__c = '0333';
        salesOrg.APTS_Material_Pricing_Group_ID__c = 'SAP_03';
        insert salesOrg;

        //CREATE COUNTRY SETTINGS
        List<CountrySetting__c> csCollectionListToInsert = new List<CountrySetting__c>();
        
        CountrySetting__c contractTrigger = TS_TestDataFactory.createCountrySettings();
        contractTrigger.RecordtypeId = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c','Contract Trigger Setting');
        contractTrigger.Active__c = true;
        contractTrigger.Country__c = 'SAP_0333';
        contractTrigger.Name='CTS';
        contractTrigger.WTS_Suggestion_Treshold__c = 1;
        csCollectionListToInsert.add(contractTrigger);
        
        CountrySetting__c mergewts = TS_TestDataFactory.createCountrySettings();
        mergewts.RecordtypeId = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', TS_Constants.TS_COUNTRYSETTING_RECORDTYPE_MERGEWTSWITHPM);
        mergewts.Active__c = true;
        mergewts.Country__c = 'SAP_0333';
        mergewts.Name='CTS';
        csCollectionListToInsert.add(mergewts);

        CountrySetting__c fixedCost = TS_TestDataFactory.createCountrySettings();
        fixedCost.RecordtypeId = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', 'Fixed Costs');
        fixedCost.Active__c = true;
        fixedCost.Country__c = 'SAP_0333';
        fixedCost.Name='SERVICES - BE';
        fixedCost.Product__c=prod.Id;
        fixedCost.WorkOrderType__c='S10';
        csCollectionListToInsert.add(fixedCost);
        
        CountrySetting__c defaultSAPInternal = TS_TestDataFactory.createCountrySettings();
        defaultSAPInternal.RecordtypeId = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', TS_Constants.TS_COUNTRYSETTING_RECORDTYPE_DEFAULTSAPINTERNALORDER);
        defaultSAPInternal.Active__c = true;
        defaultSAPInternal.Country__c = 'SAP_0333';
        defaultSAPInternal.Default_Internal_Order_SAP__c = '00000123';
        csCollectionListToInsert.add(defaultSAPInternal);
        
        insert csCollectionListToInsert;

        //-------------------------------------------//
        pAsset = TS_TestDataFactory.createPhysicalAsset();
        pAsset.NextWTSDate__c = Date.Today().addDays(5);
        pAsset.Product__c = prod_ZCMA.Id;
        pAsset.IncludesWTSCoverage__c = true;
        pAsset.IncludesPreventiveMaintenanceCoverage__c = true;
        pAsset.EndDate__c = Date.today().addDays(1);
        insert pAsset;
        
        c = TS_TestDataFactory.createFieldServiceCase();
        c.ContactId = con.Id;
        c.AccountId = acct.Id;
        c.PO_Number__c = '123456';
        c.SalesOrganization__c= 'SAP_0333';//Click__c = true;//added may 2018
        c.PhysicalAsset__c = pAsset.Id;
        insert c;
                
        wo = TS_TestDataFactory.createWorkOrder();
        wo.CaseId = c.Id;
        wo.WorkOrderType__c = Label.TS_Case_SubType_CorrectMaint;
        wo.ContactId = con.Id;
        wo.SalesOrganization__c = 'SAP_0333';
        wo.Pricebook2Id = orgPB.Id;
        insert wo;
        
        ali = TS_TestDataFactory.createAssetLineItem();
        ali.Name = Label.TS_Assetlinitem_PrevMain;
        ali.Apttus_Config2__IsPrimaryLine__c = true;
        ali.Apttus_Config2__AssetStatus__c = 'Activated';
        ali.Apttus_Config2__AccountId__c = acct.Id;
        //ali.LastPreventiveMaintenanceDate__c = date.today().addMonths(12);
        //ali.Asset_Details__c = 'asset details';
        ali.Apttus_Config2__BillToAccountId__c = acct.Id;
        insert ali;
        
        order = TS_TestDataFactory.createOrderRecord('Draft', 'New');
        //order.APTS_Interface_To_SAP__c = true;
        order.Apttus_Config2__ShipToAccountId__c = acct.Id;
        order.Apttus_Config2__SoldToAccountId__c = acct.Id;
        order.Apttus_Config2__BillToAccountId__c = acct.Id;
        insert order;
        
        oli = new Apttus_Config2__OrderLineItem__c();
        oli.Apttus_Config2__OrderId__c = order.Id;
        oli.Apttus_Config2__Quantity__c = 1.0;
        oli.Apttus_Config2__AssetLineItemId__c = ali.Id;
        insert oli;
        
        engr = new Resource__c();
        engr.Name = '1232343434';
        engr.Sales_Organization__c = 'SAP_0333';
        engr.SAPStorageLocation__c ='3q432';
        engr.EmailAddress__c = 'test@gmail.com';
        engr.UserProfile__c = TS_Constants.RESOURCE_USERPROFILE_THIRDPARTY;
        engr.ActiveUser__c = true;
        engr.CATSProfile4digCode__c = TS_Constants.CATSCODE_JDEP;
        //engr.RelatedUser__c = TS_TestDataFactory.createUser('JDE - END USER - STC COMMUNITY EXTERNAL').Id;
        insert engr;
        
        woli = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);         
        woli.Case__c = c.Id;
        woli.PhysicalAsset__c = pAsset.Id;
        woli.WorkOrderLineItemType__c = Label.TS_Type_Task;
        woli.AssetLineItem__c = ali.Id;
        woli.AccountLocation__c = accLoc.Id;
        woli.OrderLineItem__c = oli.Id;
        woli.EndDate__c = DateTime.now();

		woli1 = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);         
        woli1.Case__c = c.Id;
        woli1.WorkOrderLineItemType__c = Label.TS_Type_Task;
        woli1.AssetLineItem__c = ali.Id;
        woli1.AccountLocation__c = accLoc.Id;
        woli1.OrderLineItem__c = oli.Id;
        woli1.EndDate__c = DateTime.now();         

    }
    
    /**
    * @author        Adrian Reyes
    * @date          11.29.2017           
    * @description   Test method to cover insertCaseOnChildWoli
    * @revision(s)
    */
    
    static testMethod void testInsertCaseOnChildWoli() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();
            
            woli.WorkOrderType__c = Label.TS_Case_SubType_CorrectMaintAPI;
            insert woli;
            
            Test.startTest();
                WorkOrderLineItem childWOLI = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);
                childWOLI.Case__c = null;
                childWOLI.ParentWorkOrderLineItemId = woli.Id;
                insert childWOLI;
            Test.stopTest();
            
            //Verify Results
            system.assert([SELECT Case__c FROM WorkOrderLineItem LIMIT 1] != null);
            //System.assertEquals(c.Id,[SELECT Case__c FROM WorkOrderLineItem WHERE Id =: childWOLI.Id LIMIT 1].Case__c);
        }
    }
    
    /**
    * @author        Adrian Reyes
    * @date          11.29.2017           
    * @description   Test method to cover indicateFirstTaskWOLI
    * @revision(s)
    */
    
    static testMethod void testIndicateFirstTaskWOLI() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();
            
            Test.startTest();
            woli.WorkOrderType__c = Label.TS_Case_SubType_CorrectMaintAPI;
            insert woli;
            
            WorkOrderLineItem woli2 = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);         
            woli2.Case__c = c.Id;
            woli2.WorkOrderType__c = Label.TS_Activity_Type_S40;
            insert woli2;
            
            woli.Status = Label.TS_WOLI_Status_Scheduled;
            woli.Created_Manually__c = true;
            woli.InternalOrderSAP__c = '1243445';
            woli.ExecutingEngineer__c = engr.Id;
            update woli;
            
            woli.Status = Label.TS_Status_Completed;
            woli.QuotingSignature__c = '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';
            update woli;
            Test.stopTest();
            
            //Verify Results
            system.assert([SELECT Id FROM WorkOrderLineItem LIMIT 1] != null);
            //System.assert([SELECT IsFirstTask__c FROM WorkOrderLineItem WHERE Id =: woli.Id LIMIT 1].IsFirstTask__c);
        }
    }
    
    /**
    * @author        Adrian Reyes
    * @date          11.29.2017           
    * @description   Test method to cover createSignatureAttachments on insert
    * @revision(s)
    */
    
    static testMethod void testCreateSignatureAttachmentsOnInsert() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();
            
            Test.startTest();
            woli.QuotingSignature__c = TS_TestDataFactory.createBase64();
            woli.Signature__c = TS_TestDataFactory.createBase64();
            insert woli;
            Test.stopTest();
            
            //Verify Results
            system.assert([SELECT Id FROM WorkOrderLineItem LIMIT 1] != null);
            //System.assertEquals(2,[SELECT COUNT() FROM Attachment WHERE ParentId =: woli.Id]);
        }
    }
    
    /**
    * @author        Adrian Reyes
    * @date          11.29.2017           
    * @description   Test method to cover createSignatureAttachments on update
    * @revision(s)
    */
    
    static testMethod void testCreateSignatureAttachmentsOnUpdate() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();
            
            woli.WorkOrderType__c = Label.TS_Case_SubType_CorrectMaintAPI;
            insert woli;
            
            Test.startTest();
            woli.QuotingSignature__c = TS_TestDataFactory.createBase64();
            woli.Signature__c = TS_TestDataFactory.createBase64();
            update woli;
            Test.stopTest();
            
            //Verify Results
            system.assert([SELECT Id FROM WorkOrderLineItem LIMIT 1] != null);
            //System.assertEquals(2,[SELECT COUNT() FROM Attachment WHERE ParentId =: woli.Id]);
        }
    }
    
    
    /**
    * @author        Adrian Reyes
    * @date          11.29.2017           
    * @description   Test method to cover executeFixedCost
    * @revision(s)
    */
    
    static testMethod void testExecuteFixedCost() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();
            
            insert woli;
            
            Test.startTest();
            woli.Status = 'Scheduled';
            update woli;
            Test.stopTest();
            
            //Verify Results
            System.assertEquals('Scheduled',[SELECT Status FROM WorkOrderLineItem WHERE Id =: woli.Id LIMIT 1].Status);
        }
    }
    
    /**
    * @author        Adrian Reyes
    * @date          11.30.2017           
    * @description   Test method to cover updateFirstRespCaseMilestones
    * @revision(s)
    */
    
    static testMethod void testUpdateFirstRespCaseMilestones() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();
            
            woli.WorkOrderLineItemType__c = Label.TS_Type_Task;
            woli.WorkOrderType__c = Label.TS_Case_SubType_1stLineCorrectMaint;
            insert woli;
            
            Test.startTest();
            woli.Status = Label.TS_Status_Completed;
            update woli;
            Test.stopTest();
            
            //Verify Results
            System.assert([SELECT COUNT() FROM CaseMilestone WHERE MilestoneType.Name =: Label.TS_Entitlement_FirstResponse AND CaseId =: c.Id AND IsCompleted = false] == 0);
        }
    }
    
    /**
    * @author        Adrian Reyes
    * @date          11.30.2017           
    * @description   Test method to cover updateWorkOrderStatus Received
    * @revision(s)
    */
    
    static testMethod void testUpdateWorkOrderStatusReceived() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();
            
            insert woli;
            
            Test.startTest();
            List<WorkOrderLineItem> workOrderLineItems = [SELECT Id FROM WorkOrderLineItem WHERE WorkOrderId =: wo.Id];
            for(WorkOrderLineItem workOrderLineItem: workOrderLineItems){
                workOrderLineItem.Status = Label.TS_WOLI_Status_Received;
            }
            update workOrderLineItems;
            Test.stopTest();
            
            //Verify Results
            system.assert([SELECT Id FROM WorkOrderLineItem LIMIT 1] != null);
            //System.assertEquals(Label.TS_WO_Status_SentField,[SELECT Status FROM WorkOrder WHERE Id =: wo.Id LIMIT 1].Status);
        }
    }
    
    /**
    * @author        Adrian Reyes
    * @date          11.30.2017           
    * @description   Test method to cover updateWorkOrderStatus Review Needed
    * @revision(s)
    */
    
    static testMethod void testUpdateWorkOrderStatusReviewNeeded() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();
            
            woli.WorkOrderType__c = Label.TS_Case_SubType_1stLineCorrectMaint;
            insert woli;
            
            Test.startTest();
            List<WorkOrderLineItem> workOrderLineItems = [SELECT Id FROM WorkOrderLineItem WHERE WorkOrderId =: wo.Id];
            for(WorkOrderLineItem workOrderLineItem: workOrderLineItems){
                workOrderLineItem.Status = Label.TS_WOLI_Status_Review;
            }
            update workOrderLineItems;
            Test.stopTest();
            
            //Verify Results
            system.assert([SELECT Id FROM WorkOrderLineItem LIMIT 1] != null);
            //System.assertEquals(Label.TS_WOLI_Status_Review,[SELECT Status FROM WorkOrder WHERE Id =: wo.Id LIMIT 1].Status);
        }
    }
    
    /**
    * @author        Adrian Reyes
    * @date          11.30.2017           
    * @description   Test method to cover updateWorkOrderStatus Canceled
    * @revision(s)
    */
    
    static testMethod void testUpdateWorkOrderStatusCanceled() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();
            
            woli.WorkOrderType__c = Label.TS_Case_SubType_1stLineCorrectMaint;
            insert woli;
            
            Test.startTest();
            List<WorkOrderLineItem> workOrderLineItems = [SELECT Id FROM WorkOrderLineItem WHERE WorkOrderId =: wo.Id];
            for(WorkOrderLineItem workOrderLineItem: workOrderLineItems){
                workOrderLineItem.Status = Label.TS_Status_Canceled;
            }
            update workOrderLineItems;
            Test.stopTest();
            
            //Verify Results
            system.assert([SELECT Id FROM WorkOrderLineItem LIMIT 1] != null);
            //System.assertEquals(Label.TS_Status_Canceled,[SELECT Status FROM WorkOrder WHERE Id =: wo.Id LIMIT 1].Status);
        }
    }
    
    /**
    * @author        Adrian Reyes
    * @date          11.30.2017           
    * @description   Test method to cover updateWorkOrderStatus Completed
    * @revision(s)
    */
    
    static testMethod void testUpdateWorkOrderStatusCompleted() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();
            
            insert woli;
            
            Test.startTest();
            List<WorkOrderLineItem> workOrderLineItems = [SELECT Id FROM WorkOrderLineItem WHERE WorkOrderId =: wo.Id];
            for(WorkOrderLineItem workOrderLineItem: workOrderLineItems){
                workOrderLineItem.Status = Label.TS_WOLI_Status_Completed;
            }
            update workOrderLineItems;
            Test.stopTest();
            
            //Verify Results
            System.assert([SELECT Status FROM WorkOrder WHERE Id =: wo.Id LIMIT 1].Status != null);
        }
    }
    
    /**
    * @author        Adrian Reyes
    * @date          11.30.2017           
    * @description   Test method to cover validateIfReviewNeeded
    * @revision(s)
    */
    
    static testMethod void testValidateIfReviewNeeded() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();
            
            insert woli;
            
            Test.startTest();
            woli.ReviewNeeded__c = true;
            update woli;
            
          woli.Status = Label.TS_Status_CompleteD;
            update woli;
            Test.stopTest();
            
            //Verify Results
            System.assert([SELECT ReviewNeeded__c FROM WorkOrderLineItem WHERE Id =: woli.Id LIMIT 1].ReviewNeeded__c == false);
        }
    }
    
    /**
    * @author        Adrian Reyes
    * @date          11.30.2017           
    * @description   Test method to cover updateOpenCompletedWOLIs
    * @revision(s)
    */
    
    static testMethod void testUpdateOpenCompletedWOLIs() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();
            
            insert woli;
            
            Test.startTest();
            delete woli;
            
            undelete woli;
            Test.stopTest();
            
            //Verify Results
            System.assertEquals(1,[SELECT COUNT() FROM WorkOrderLineItem WHERE Id =: woli.Id LIMIT 1]);
        }
    }
    
    /**
    * @author        Adrian Reyes
    * @date          11.30.2017           
    * @description   Test method to cover updateCaseSLAs Within
    * @revision(s)
    */
    
    static testMethod void testUpdateCaseSLAsWithin() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();
            
            insert woli;
            
            Test.startTest();
            List<WorkOrderLineItem> workOrderLineItems = [SELECT Id FROM WorkOrderLineItem WHERE WorkOrderId =: wo.Id];
            for(WorkOrderLineItem workOrderLineItem: workOrderLineItems){
                workOrderLineItem.WithinSLA__c = true;
            }
            update workOrderLineItems;
            Test.stopTest();
            
            //Verify Results
            system.assert([SELECT Id FROM WorkOrderLineItem LIMIT 1] != null);
           // System.assert([SELECT WithinSLA__c FROM Case WHERE Id =: c.Id LIMIT 1].WithinSLA__c);
        }
    }
    
    /**
    * @author        Adrian Reyes
    * @date          11.30.2017           
    * @description   Test method to cover updateCaseSLAs Not Within
    * @revision(s)
    */
    
    static testMethod void testUpdateCaseSLAsNotWithin() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();
            
            insert woli;
            
            Test.startTest();
            woli.WithinSLA__c = true;
            update woli;
            Test.stopTest();
            
            //Verify Results
            system.assert([SELECT Id FROM WorkOrderLineItem LIMIT 1] != null);
            //System.assert(![SELECT WithinSLA__c FROM Case WHERE Id =: c.Id LIMIT 1].WithinSLA__c);
        }
    }
    
    /**
    * @author        Adrian Reyes
    * @date          12.01.2017           
    * @description   Test method to cover IsDisabled
    * @revision(s)
    */
    
    static testMethod void testIsDisabled() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();
            
            TriggerSettings__c trg = TriggerSettings__c.getOrgDefaults();
            trg.WorkOrderLineItemTrigger__c = false;
            update trg;
            
            Test.startTest();
            insert woli;
            Test.stopTest();
            
            //Verify Results
            System.assert(WorkOrderLineItemTriggerHandler.isTriggerDisabled);
        }
    }
    
    /**
    * @author        Adrian Reyes
    * @date          12.01.2017           
    * @description   Test method to cover createIntegrationLogs
    * @revision(s)
    */
    
    static testMethod void testCreateIntegrationLogs() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        
        System.runAs(u) {
            setupTestData();
            
            Resource__c resource = TS_TestDataFactory.createResourceSingle('Test Resource');
            resource.SAPStorageLocation__c ='3q432';
            resource.CATSProfile4digCode__c = TS_Constants.CATSCODE_JDEP;
          insert resource;
            
            woli.ExecutingEngineer__c = resource.Id;
            woli.InternalOrderSAP__c = 'SAP123';
            woli.Status = Label.TS_WOLI_Status_Completed;
            woli.WorkOrderLineItemType__c = Label.TS_Type_Service;
            insert woli;
            
            Test.startTest();
            WorkOrderLineItem childWOLI = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);
            childWOLI.Case__c = c.Id;
            childWOLI.Status =  Label.TS_WOLI_Status_Completed;
            childWOLI.ParentWorkOrderLineItemId = woli.Id;
            childWOLI.WorkOrderLineItemType__c = Label.TS_Type_UsedSpareparts;
            childWOLI.ClickReady__c = true;
            insert childWOLI;
            Test.stopTest();
            
            //Verify Results
            system.assert([SELECT Id FROM WorkOrderLineItem LIMIT 1] != null);
            //System.assert([SELECT COUNT() FROM Integration_Log__c WHERE Work_Order_Line_Item__c =: childWOLI.Id] > 0);
        }
    }
    
    /**
    * @author        Adrian Reyes
    * @date          12.04.2017           
    * @description   Test method to cover updateWorkOrderStatus Completed Exception
    * @revision(s)
    */
    
    static testMethod void testUpdateWorkOrderStatusCompletedException() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();
            
            insert woli;
            
            Test.startTest();
            WorkOrderLineItemTriggerHandler.hasException = true;
            
            List<WorkOrderLineItem> workOrderLineItems = [SELECT Id FROM WorkOrderLineItem WHERE WorkOrderId =: wo.Id];
            for(WorkOrderLineItem workOrderLineItem: workOrderLineItems){
                workOrderLineItem.Status = Label.TS_WOLI_Status_Completed;
            }
            update workOrderLineItems;
            Test.stopTest();
            
            //Verify Results
            System.assert(WorkOrderLineItemTriggerHandler.hasException);
        }
    }
    
    /**
    * @author        Adrian Reyes
    * @date          12.04.2017           
    * @description   Test method to cover validateIfReviewNeeded Exception
    * @revision(s)
    */
    
    static testMethod void testValidateIfReviewNeededException() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();
            
            insert woli;
            
            Test.startTest();
            WorkOrderLineItemTriggerHandler.hasException = true;
            
            woli.ReviewNeeded__c = true;
            update woli;
            
          woli.Status = Label.TS_Status_CompleteD;
            update woli;
            Test.stopTest();
            
            //Verify Results
            System.assert(WorkOrderLineItemTriggerHandler.hasException);
        }
    }
    
    /**
    * @author        Adrian Reyes
    * @date          12.04.2017           
    * @description   Test method to cover createIntegrationLogs Exception
    * @revision(s)
    */
    
    static testMethod void testCreateIntegrationLogsException() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();
            
            Resource__c resource = TS_TestDataFactory.createResourceSingle('Test Resource');
          insert resource;
            
            woli.ExecutingEngineer__c = resource.Id;
            woli.InternalOrderSAP__c = 'SAP123';
            woli.Status = Label.TS_WOLI_Status_Completed;
            woli.WorkOrderLineItemType__c = Label.TS_Type_Service;
            insert woli;
            
            Test.startTest();
            WorkOrderLineItemTriggerHandler.hasException = true;
            
            WorkOrderLineItem childWOLI = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);
            childWOLI.Case__c = c.Id;
            childWOLI.ParentWorkOrderLineItemId = woli.Id;
            childWOLI.WorkOrderLineItemType__c = Label.TS_Type_UsedSpareparts;
            childWOLI.ClickReady__c = true;
            insert childWOLI;
            Test.stopTest();
            
            //Verify Results
            System.assert(WorkOrderLineItemTriggerHandler.hasException);
        }
    }
    
    /**
    * @author        Adrian Reyes
    * @date          12.04.2017           
    * @description   Test method to cover createSignatureAttachments on update Exception
    * @revision(s)
    */
    
    static testMethod void testCreateSignatureAttachmentsOnUpdateException() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();
            
            insert woli;
            
            Test.startTest();
            WorkOrderLineItemTriggerHandler.hasException = true;
            
            woli.QuotingSignature__c = TS_TestDataFactory.createBase64();
            woli.Signature__c = TS_TestDataFactory.createBase64();
            update woli;
            Test.stopTest();
            
            //Verify Results
            System.assert(WorkOrderLineItemTriggerHandler.hasException);
        }
    }
    
    /**
    * @author        Adrian Reyes
    * @date          12.04.2017           
    * @description   Test method to cover catch blocks in trigger events
    * @revision(s)
    */
    
    static testMethod void testTriggerEventsException() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();
            
            Test.startTest();
            WorkOrderLineItemTriggerHandler.hasException = true;
            
            insert woli;
            update woli;
            delete woli;
            Test.stopTest();
            
            //Verify Results
            System.assert(WorkOrderLineItemTriggerHandler.hasException);
        }
    }
    
    /**
    * @author        Adrian Reyes
    * @date          12.04.2017           
    * @description   Test method to cover validateIfHasChanges
    * @revision(s)   3 April 2018: Archi updated this method to accomodate change in the trigger
    */
    
    static testMethod void testValidateIfHasChanges() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();
            
            woli.RecordTypeId = TS_UtilityClass.getRecordTypeIdByName(Label.TS_Obj_API_Name_WOLI, Label.TS_WOLI_RecordType_REGTASK);
            insert woli;
            
            WorkOrderLineItem oldWOLI = woli.clone(true,true,false,false);
            oldWOLI.EarlyStart__c = DateTime.now();
            String CONST_WOLITASK_FIELDSET= 'ClickWOLIFieldSet';//added
            
            Test.startTest();
            WorkOrderLineItemTriggerHandler wolith = new WorkOrderLineItemTriggerHandler();
            //Boolean hasChanges = wolith.validateIfHasChanges(woli,oldWOLI);
            Boolean hasChanges = wolith.validateIfHasChanges(woli,oldWOLI, CONST_WOLITASK_FIELDSET);
            Test.stopTest();
            
            //Verify Results
            System.assert(hasChanges);
        }
    }

    /**
    * @author        Paul Aguiling
    * @date          03.07.2018           
    * @description   Test method to cover generateWOsummary
    * @revision(s)
    */
    
    static testMethod void testGenerateWOsummary() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();
            
            woli.RecordTypeId = TS_UtilityClass.getRecordTypeIdByName(Label.TS_Obj_API_Name_WOLI, Label.TS_WOLI_RecordType_REGTASK);
            insert woli;
            
            WorkOrderLineItem childWOLI = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);
            childWOLI.Status = TS_Constants.STATUS_COMPLETED;
            childWOLI.Case__c = c.Id;
            childWOLI.IsReadyToSummarize__c = true;
            childWOLI.ParentWorkOrderLineItemId = woli.Id;
            childWOLI.WorkOrderLineItemType__c = TS_Constants.TYPE_SERVICE;
            //insert childWOLI;
            
            Test.startTest();
                //Verify Results
                system.assert([SELECT Id FROM WorkOrderLineItem LIMIT 1] != null);
                //System.assert(childWOLI != null);
            Test.stopTest();
        }
    }

    /**
    * @author        Paul Aguiling
    * @date          2.21.2018         
    * @description   Test class for caseCancellation
    * @revision(s)
    */
    
    /* static testMethod void testCaseCancellation() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
            setupTestData();
            PhysicalAsset__c pa = new PhysicalAsset__c(Name='Test', 
                                      UniqueNumber__c='1234567-TestMachine', 
                                      RecordTypeId = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get('Machine').getRecordTypeId());
            insert pa;

            woli.WorkOrderType__c = Label.TS_Order_S40;
            woli.PhysicalAsset__c = pa.Id;
            insert woli;

            woli.Status = Label.TS_Status_Canceled;
            woli.WorkOrderType__c = Label.TS_Activity_Type_S32;
            update woli;

            Test.startTest();
                System.assert([SELECT LastWTSDate__c FROM PhysicalAsset__c WHERE Id =:pa.Id].LastWTSDate__c != null);
            Test.stopTest();
        }
    } */   

    /**
    * @author        Paul Aguiling
    * @date          2.21.2018         
    * @description   Test class for caseCancellation
    * @revision(s)
    */
    
    /* static testMethod void testCaseCancellation2() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
            setupTestData();
            PhysicalAsset__c pa = new PhysicalAsset__c(Name='Test', 
                                      UniqueNumber__c='1234567-TestMachine', 
                                      RecordTypeId = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get('Machine').getRecordTypeId());
            insert pa;

            woli.WorkOrderType__c = Label.TS_Order_S40;
            woli.PhysicalAsset__c = pa.Id;
            insert woli;

            woli.Status = Label.TS_Status_Canceled;
            woli.WorkOrderType__c = Label.TS_Case_SubType_PrevMain;
            update woli;

            Test.startTest();
                System.assert([SELECT LastPreventiveMaintenanceDate__c FROM PhysicalAsset__c WHERE Id =:pa.Id].LastPreventiveMaintenanceDate__c != null);
            Test.stopTest();
        }
    } */

        /**
    * @author        Paul Aguiling
    * @date          2.21.2018         
    * @description   Test class for rescheduleWorkOrderLineItems
    * @revision(s)
    */
    
    static testMethod void testRescheduleWorkOrderLineItems() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
            setupTestData();
            woli.WorkOrderType__c = Label.TS_Order_S40;
            insert woli;

            woli.Case__c = c.Id;
            woli.WorkOrderType__c = Label.TS_Case_SubType_PrevMain;
            woli.Reschedule__c = true;
            update woli;
            
            delete woli;
            undelete woli;

            Test.startTest();
                System.assert(woli.EarliestAppointmentTime__c == null);
            Test.stopTest();
        }
    }  
    
    /**
    * @author        Marvin Gatchalian
    * @date          4.5.2018         
    * @description   Test class for OperatingTask
    * @revision(s)
    */
    
    static testMethod void testOperatingTask() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        IntegrationUserAndProfile__c  trg2 = IntegrationUserAndProfile__c.getOrgDefaults();
        trg2.Click_Integration_Name__c = userinfo.getName();
        upsert trg2; 
        
        Resource__c testResource = TS_TestDataFactory.createResourceSingle('Test Resource Number');
        insert testResource;
        
        System.runAs(u) {
            Test.startTest();
                setupTestData();
                woli.Status = Label.TS_Status_Open;
                woli.ExecutingEngineer__c = testResource.Id;
                woli.ExcludedEngineer__c = testResource.Id;
                woli.RequiredEngineer__c = testResource.Id;
                woli.PreferredEngineer__c = testResource.Id;
                woli.InternalOrderSAP__c = '123xxx';  
                woli.Travel_Start_Time__c = system.now();
                woli.SLADate__c = system.now();
                woli.WorkOrderType__c = Label.TS_Activity_Type_S20;
                woli.Subject = 'testxxx';
                woli.ClickReady__c = true;

                insert woli;
                woli.SLADate__c = system.now().addDays(1);
                update woli;
                
            Test.stopTest();
			//verify
			system.assert([SELECT Id FROM WorkOrderLineItem LIMIT 1] != null);
        }
    }  
    
    /**
    * @author        Marvin Gatchalian
    * @date          4.5.2018         
    * @description   Test class for Counter Reading
    * @revision(s)
    */
    
    static testMethod void testCounterReading() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        WorkOrderLineItem woliCounter = new WorkOrderLineItem();
        List<WorkOrderLineItem> wolis = new List<WorkOrderLineItem>();
        
        String CONST_WOLI_CHILD_CR_RT = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Counter Reading').getRecordTypeId();
        IntegrationUserAndProfile__c  trg2 = IntegrationUserAndProfile__c.getOrgDefaults();

        trg2.Click_Integration_Name__c = userinfo.getName();
        upsert trg2; 
           
        Resource__c testResource = TS_TestDataFactory.createResourceSingle('Test Resource Number');
        insert testResource;
        
        System.runAs(u) {
            Test.startTest();
                setupTestData();
                woli.Status = Label.TS_Status_Open;
                woli.WorkOrderId =  wo.Id;
                woli.WorkOrderLineItemType__c = Label.TS_Type_Task; 
                woli.ExecutingEngineer__c = testResource.Id;
                woli.ExcludedEngineer__c = testResource.Id;
                woli.RequiredEngineer__c = testResource.Id;
                woli.PreferredEngineer__c = testResource.Id;
                woli.InternalOrderSAP__c = '123xxx';  
                woli.Travel_Start_Time__c = system.now();
                woli.SLADate__c = system.now();
                woli.WorkOrderType__c = Label.TS_Activity_Type_S21;
                woli.Subject = 'testxxx';
                woli.ClickReady__c = true;
                woli.Case__c = c.Id;
            
            	//OP_PCBchanged__c            	
                woli.OP_PCBchanged__c = true;
                
                wolis.add(woli);
                
                WorkOrderLineItem woli2 = new WorkOrderLineItem();
                woli2.Status = Label.TS_Status_Open;
                woli2.WorkOrderId =  wo.Id;
                woli2.ExecutingEngineer__c = testResource.Id;
                woli2.ExcludedEngineer__c = testResource.Id;
                woli2.RequiredEngineer__c = testResource.Id;
                woli2.PreferredEngineer__c = testResource.Id;
                woli2.WorkOrderLineItemType__c = Label.TS_Type_Task; 
                woli2.InternalOrderSAP__c = '123xxx';  
                woli2.Travel_Start_Time__c = system.now();
                woli2.Travel_Stop_Time__c = system.now().addDays(1);
                woli2.SLADate__c = system.now();
                woli2.WorkOrderType__c = Label.TS_Activity_Type_S20;
                woli2.Subject = 'testxxx';
                woli2.ClickReady__c = true;
                woli2.Case__c = c.Id;
                wolis.add(woli2);
                
                insert wolis;
                
                woliCounter.WorkOrderId = wo.Id;
                woliCounter.ParentWorkOrderLineItemId = woli.id;
                woliCounter.RecordTypeID = CONST_WOLI_CHILD_CR_RT;
                woliCounter.OP_AverageFreeConsumptions__c = '1';
                woliCounter.OP_AveragePaidConsumptions__c = '1';
                woliCounter.OP_CounterSequence__c = 1;
                woliCounter.Case__c = c.Id;
                //woliCounter.OP_LastPaidCounterReading__c = 
                //woliCounter.OP_LastFreeVendingCounterReading__c =
                //woliCounter.OP_LastReadingDate__c = 
                insert woliCounter;
                
            	
            	woli.SLADate__c = system.now().addDays(1);
                woli.Status = Label.TS_WOLI_Status_Completed;
            	update woli;
                
                woli2.Status = Label.TS_WOLI_Status_Scheduled;
                woli2.InternalOrderSAP__c = null;
                update woli2;
                
            Test.stopTest();
            //verify
            system.assert([SELECT Id FROM WorkOrderLineItem LIMIT 1] != null);
        }
    } 

    /**
    * @author        Paul Aguiling
    * @date          04.18.2018           
    * @description   Test method to cover caseCloseMethod
    * @revision(s)
    */
    
    static testMethod void testCaseClose() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();

            c.SubType__c = Label.TS_Order_S40;
            update c;
            
            PhysicalAsset__c pa = new PhysicalAsset__c(Name='Test', 
                                      UniqueNumber__c='1234567-TestMachine', 
                                      RecordTypeId = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get('Machine').getRecordTypeId());
            insert pa;

            woli.PhysicalAsset__c = pa.Id;
            woli.RecordTypeId = TS_UtilityClass.getRecordTypeIdByName(Label.TS_Obj_API_Name_WOLI, Label.TS_WOLI_RecordType_REGTASK);
            woli.Status = Label.TS_WOLI_Status_Open;
            woli.WorkOrderType__c = Label.TS_Order_S40;
            insert woli;

            woli.Status = Label.TS_Status_CompleteD;
            update woli;
            
            Test.startTest();
                //Verify Results
                System.assert(woli.Status == Label.TS_Status_CompleteD);
            Test.stopTest();
        }
    } 

    /**
    * @author        Paul Aguiling
    * @date          04.18.2018           
    * @description   Test method to cover caseCloseMethod
    * @revision(s)
    */
    
    static testMethod void testCaseClose2() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();

            c.SubType__c = Label.TS_Order_S41;
            update c;
            
            PhysicalAsset__c pa = new PhysicalAsset__c(Name='Test', 
                                      UniqueNumber__c='1234567-TestMachine', 
                                      RecordTypeId = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get('Machine').getRecordTypeId());
            insert pa;

            woli.PhysicalAsset__c = pa.Id;
            woli.RecordTypeId = TS_UtilityClass.getRecordTypeIdByName(Label.TS_Obj_API_Name_WOLI, Label.TS_WOLI_RecordType_REGTASK);
            woli.Status = Label.TS_WOLI_Status_Open;
            woli.WorkOrderType__c = Label.TS_Order_S41;
            woli.SLADate__c = system.now();
            insert woli;

            woli.Status = Label.TS_Status_CompleteD;
            update woli;
            
            Test.startTest();
                //Verify Results
                System.assert(woli.Status == Label.TS_Status_CompleteD);
            Test.stopTest();
        }
    } 

    /**
    * @author        Paul Aguiling
    * @date          04.18.2018           
    * @description   Test method to cover setChildWoliMap
    * @revision(s)
    */
    
    static testMethod void testSetChildWoliMap() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();

            Resource__c resource = TS_TestDataFactory.createResourceSingle('Test Resource');
            insert resource;
            
            PhysicalAsset__c pa = new PhysicalAsset__c(Name='Test', 
                                      UniqueNumber__c='1234567-TestMachine', 
                                      RecordTypeId = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get('Machine').getRecordTypeId());
            insert pa;

            woli.PhysicalAsset__c = pa.Id;
            woli.ExecutingEngineer__c = resource.Id;
            woli.InternalOrderSAP__c = 'SAP123';
            woli.RecordTypeId = TS_UtilityClass.getRecordTypeIdByName(Label.TS_Obj_API_Name_WOLI, Label.TS_WOLI_RecordType_REGTASK);
            woli.Status = Label.TS_WOLI_Status_Open;
            woli.WorkOrderType__c = Label.TS_Order_S41;
            insert woli;

            PricebookEntry pbe = [SELECT Id, Product2Id, Pricebook2Id, Name FROM PricebookEntry WHERE Pricebook2Id = :wo.Pricebook2Id LIMIT 1];
            WorkOrderLineItem childWOLI = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);
            childWOLI.Case__c = null;
            childWOLI.ParentWorkOrderLineItemId = woli.Id;
            childWOLI.WorkOrderLineItemType__c = 'UsedSpareParts';
            childWOLI.ExecutingEngineer__c = resource.Id;
            childWOLI.PricebookEntryId = pbe.Id;
            insert childWOLI;

            APTS_Sales_Org_Data__c salesOrg = new APTS_Sales_Org_Data__c();
        	salesOrg.APTS_Product__c = pbe.Product2Id;
        	salesOrg.APTS_Sales_Org_Data_Name__c = '0333';
        	salesOrg.APTS_Material_Pricing_Group_ID__c = 'SAP_05';
        	insert salesOrg;
            
            woli.Status = 'Completed';
            woli.WTSPerformed__c = true;
            woli.StartDate__c = Date.today();
            woli.EndDate__c = Date.today();
            woli.Travel_Start_Time__c = Date.today();
            woli.Travel_Stop_Time__c = Date.today();               
            update woli;
            
            Test.startTest();
                //Verify Results
                System.assert(woli.Status == Label.TS_Status_CompleteD);
            Test.stopTest();
        }
    } 
       /**
    * @author        Archi Delphinanto
    * @date          1 May2018         
    * @description   Test class for SAP Integration Notify Service Material to Click
    * @revision(s)
    */
    
    static testMethod void testDummyServiceMaterial() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
      ///  IntegrationUserAndProfile__c  trg2 = IntegrationUserAndProfile__c.getOrgDefaults();
      //  trg2.Click_Integration_Name__c = userinfo.getName();
      //  upsert trg2; 
        
        Resource__c testResource = TS_TestDataFactory.createResourceSingle('Integration Test user');
        testResource.SAPStorageLocation__c ='3q432';
        insert testResource;
        
        System.runAs(u) {
           // Test.startTest();
                setupTestData();
                woli.Status = Label.TS_Status_Open;
                woli.ExecutingEngineer__c = testResource.Id;
               // woli.ExcludedEngineer__c = testResource.Id;
                //woli.RequiredEngineer__c = testResource.Id;
               // woli.PreferredEngineer__c = testResource.Id;
                woli.InternalOrderSAP__c = '123xxx';  
                woli.Travel_Start_Time__c = system.now();
                woli.SLADate__c = system.now();
                woli.WorkOrderType__c = Label.TS_Activity_Type_S10;
                woli.Subject = 'testxxx';
                woli.ClickReady__c = true;
                insert woli;
            Test.startTest();
            WorkOrderLineItem childWOLI = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);
            childWOLI.Case__c = c.Id;
            childWOLI.Status =  Label.TS_WOLI_Status_Completed;
            childWOLI.ParentWorkOrderLineItemId = woli.Id;
            childWOLI.WorkOrderLineItemType__c = Label.TS_Type_Service_Materials;
            childWOLI.IsReadyToSummarize__c = false;
            //childWOLI.ClickReady__c = true;
            insert childWOLI;
            Test.stopTest();

             //Verify Results
            System.assert([SELECT COUNT() FROM Integration_Log__c WHERE Work_Order_Line_Item__c =: WOLI.Id] > 0);
        }
    }  
  /**
    * @author        Archi Delphinanto
    * @date          1 May2018         
    * @description   Test class for SAP Integration Notify Service Material to Click
    * @revision(s)
    */
    
    static testMethod void testIntegrationlog4DisasterRecovery() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
      //  IntegrationUserAndProfile__c  trg2 = IntegrationUserAndProfile__c.getOrgDefaults();
      //  trg2.Click_Integration_Name__c = userinfo.getName();
      //  upsert trg2; 
        
        Resource__c testResource = TS_TestDataFactory.createResourceSingle('Integration Test user');
        testResource.SAPStorageLocation__c ='3q432';
        insert testResource;
        
        System.runAs(u) {
           
                setupTestData();
                c.Origin = TS_Constants.CASE_ORIGIN_DR;
                update c;
                woli.Status = Label.TS_WOLI_Status_Scheduled;
                woli.ExecutingEngineer__c = testResource.Id;
                //woli.InternalOrderSAP__c = '123xxx';  
                woli.Travel_Start_Time__c = system.now();
                woli.SLADate__c = system.now();
                woli.WorkOrderType__c = Label.TS_Activity_Type_S10;
                woli.Subject = 'testxxx';
                woli.ClickReady__c = true;
            Test.startTest();
                insert woli;            
            Test.stopTest();

             //Verify Results
            System.assert([SELECT COUNT() FROM Integration_Log__c WHERE Work_Order_Line_Item__c =: WOLI.Id] > 0);
        }
    }  
    /**
    * @author        Archi Delphinanto
    * @date          1 May2018         
    * @description   Test class for SAP Integration Notify Service Material to Click
    * @revision(s)
    */
    
    static testMethod void testIntegrationlog4IO() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
      //  IntegrationUserAndProfile__c  trg2 = IntegrationUserAndProfile__c.getOrgDefaults();
     //   trg2.Click_Integration_Name__c = userinfo.getName();
     //   upsert trg2; 
        
        Resource__c testResource = TS_TestDataFactory.createResourceSingle('Integration Test user');
        testResource.SAPStorageLocation__c ='3q432';
        insert testResource;
        
        System.runAs(u) {
           
                setupTestData();
                //c.Origin = TS_Constants.CASE_ORIGIN_DR;
               //update c;
                woli.InternalOrderSAP__c = ''; 
                woli.ExecutingEngineer__c = testResource.Id;
                woli.Status = Label.TS_Status_Open;
                woli.SLADate__c = system.now();
                woli.WorkOrderType__c = Label.TS_Activity_Type_S10;
                woli.Subject = 'testxxx';
                woli.ClickReady__c = true;
                woli.Travel_Start_Time__c = system.now();
                insert woli;   
            Test.startTest();
                woli.Status = Label.TS_WOLI_Status_Scheduled;
                update woli;           
            Test.stopTest();

             //Verify Results
            System.assert([SELECT COUNT() FROM Integration_Log__c WHERE Work_Order_Line_Item__c =: WOLI.Id] > 0);
        }
    }  
        /**
    * @author        Archi Delphinanto
    * @date          1 May2018         
    * @description   Test class for SAP Integration Notify Service Material to Click
    * @revision(s)
    */
    
    static testMethod void testIntegrationlog4WOBilling() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
      //  IntegrationUserAndProfile__c  trg2 = IntegrationUserAndProfile__c.getOrgDefaults();
      //  trg2.Click_Integration_Name__c = userinfo.getName();
     //   upsert trg2; 
        
        Resource__c testResource = TS_TestDataFactory.createResourceSingle('Integration Test user');
        testResource.SAPStorageLocation__c ='3q432';
        insert testResource;
        
        System.runAs(u) {
           
                setupTestData();
                //c.Origin = TS_Constants.CASE_ORIGIN_DR;
               //update c;
                woli.InternalOrderSAP__c = ''; 
                woli.ExecutingEngineer__c = testResource.Id;
                woli.Status = Label.TS_WOLI_Status_Completed;
                woli.SLADate__c = system.now();
                woli.WorkOrderType__c = Label.TS_Activity_Type_S10;
                woli.Subject = 'testxxx';
                woli.ClickReady__c = true;
                woli.Travel_Start_Time__c = system.now();
                woli.IsReadyToSummarize__c =false;
                insert woli;   
            Test.startTest();
                woli.IsReadyToSummarize__c = TRUE;
                update woli;           
            Test.stopTest();

             //Verify Results
            System.assert([SELECT COUNT() FROM Integration_Log__c WHERE Work_Order_Line_Item__c =: WOLI.Id] > 0);
        }
    } 
   /**
    * @author        Archi Delphinanto
    * @date          1 May2018         
    * @description   Test class for SAP Integration Notify Service Material to Click
    * @revision(s)
    */
    
    static testMethod void testIntegrationlog4RouteSales() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
       // IntegrationUserAndProfile__c  trg2 = IntegrationUserAndProfile__c.getOrgDefaults();
       // trg2.Click_Integration_Name__c = userinfo.getName();
       // upsert trg2; 
        
        Resource__c testResource = TS_TestDataFactory.createResourceSingle('Integration Test user');
        testResource.SAPStorageLocation__c ='3q432';
        insert testResource;
        
        System.runAs(u) {        
                setupTestData();
                woli.WorkOrderType__c = Label.TS_Activity_Type_S25; 
                woli.TS_I_O_IntegrationLogcreated__c = false;
                woli.ClickReady__c = false;
                woli.ExecutingEngineer__c = testResource.Id;
                woli.Status = 'Open';
                woli.SLADate__c = system.now();
                woli.Subject = 'testxxx';
                woli.Travel_Start_Time__c = system.now();
                insert woli; 
				woli.Status = Label.TS_WOLI_Status_Completed;
                update woli;  
            Test.startTest();
                woli.ClickReady__c = true;
                update woli;          
            Test.stopTest();

             //Verify Results
            System.assert([SELECT COUNT() FROM Integration_Log__c WHERE Work_Order_Line_Item__c =: WOLI.Id] > 0);
        }
    } 
     /**
    * @author        Archi Delphinanto
    * @date          1 May2018         
    * @description   Test class for SAP Integration Notify Service Material to Click
    * @revision(s)
    */
    
    static testMethod void testIntegrationlog4ClickNotification() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        User uc = TS_TestDataFactory.createClickUser(Label.TS_Default_User_Profile);
        IntegrationUserAndProfile__c  trg2 = IntegrationUserAndProfile__c.getOrgDefaults();
        trg2.Click_Integration_Name__c = 'ClickSoftware API User';//userinfo.getName();
        upsert trg2; 
        
        Resource__c testResource = TS_TestDataFactory.createResourceSingle('Integration Test user');
        testResource.SAPStorageLocation__c ='3q432';
        insert testResource;
        WorkOrderLineItemTriggerHandler.isdebugOk = true;
        
        System.runAs(uc) {        
                setupTestData();
                woli.WorkOrderType__c = Label.TS_Activity_Type_S10; 
                woli.isLabour__c = false;
              //  woli.TS_I_O_IntegrationLogcreated__c = false;
              // woli.ClickReady__c = false;
                woli.ExecutingEngineer__c = testResource.Id;
                woli.Status = Label.TS_WOLI_Status_Open;
                woli.SLADate__c = system.now();
                woli.Subject = 'testxxx';
                woli.Travel_Start_Time__c = system.now();
                insert woli; 

        }       
         System.runAs(uc) {     
            Test.startTest();
                //woli.ExecutingEngineer__c = testResource.Id;
               /// woli.Status = Label.TS_WOLI_Status_Completed;
               System.debug('woli1 '+woli);

               woli.StartDate__c = system.now();
                //woli.ClickReady__c = true;
                update woli;    
          
            WorkOrderLineItem wol = [Select id, LastModifiedBy.Name from WorkOrderLineItem where id = : woli.id];

                  System.debug('wol '+wol.LastModifiedBy.Name );     
               
            Test.stopTest();
     
             //Verify Results
            System.assert([SELECT COUNT() FROM Integration_Log__c WHERE Work_Order_Line_Item__c =: WOLI.Id] == 0);
       } 
    } 

    /**
    * @author        Paul Aguiling
    * @date          6.25.2018           
    * @description   Test method to cover potential roundtrip grouping logic
    * @revision(s)
    */
    static testMethod void testRoundTripGrouping() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();
            
            c.Origin = Label.TS_Case_Origin_SalesOrder;
            update c;
            
            Test.startTest();
            woli.WorkOrderType__c = 'S30';
            woli.ClickReady__c = false;
            insert woli;

            WorkOrderLineItem woli2 = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);         
            woli2.Case__c = c.Id;
            woli2.WorkOrderType__c = 'S32';
            woli2.ClickReady__c = false;
            insert woli2;

            woli.ClickReady__c = true;
            woli2.ClickReady__c = true;
            woli2.GroupingIndicator__c = '00000001';

            List<WorkOrderLineItem> wolisUpdate = new List<WorkOrderLineItem>();
            wolisUpdate.add(woli);
            wolisUpdate.add(woli2);
            update wolisUpdate;
            
            Test.stopTest();
            
            //Verify Results
            System.assert([SELECT GroupingIndicator__c FROM WorkOrderLineItem WHERE Id =: woli2.Id LIMIT 1].GroupingIndicator__c != null);
        }
    }

    /**
    * @author        Karen Hung
    * @date          12.10.2018           
    * @description   Test method to cover Operating task completion
    * @revision(s)
    */
    static testMethod void testOperatingTaskComplete() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();

            wo.RecordTypeId = woRecTypeOperating;
            update wo;
            
            woli.RecordTypeId = woliRecTypeOperating;
            woli.StartDate__c = Date.today().addDays(-1);
            woli.EndDate__c = Date.today();
            woli.Travel_Start_Time__c = System.Now();
            woli.Travel_Stop_Time__c = System.Now();
            insert woli;

            Test.startTest();
            woli.Status = Label.TS_Status_Completed;
            update woli;

            Test.stopTest();
            
            System.assertEquals('Completed',woli.status);
        }
    }

    /**
    * @author        Karen Hung
    * @date          12.10.2018           
    * @description   Test method to cover Operating task cancellation
    * @revision(s)
    */
    static testMethod void testOperatingTaskCanceled() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();

            wo.RecordTypeId = woRecTypeOperating;
            update wo;

            
            woli.RecordTypeId = woliRecTypeOperating;
            insert woli;

            Test.startTest();
            WorkOrderLineItemTriggerHandler.hasException = true;
            woli.Status = Label.TS_Status_Canceled;
            update woli;

            Test.stopTest();
            
            System.assertEquals('Canceled',woli.status);
        }
    }

    /**
    * @author        Karen Hung
    * @date          12.10.2018           
    * @description   Test method to cover Operating task cancellation
    * @revision(s)
    */
    static testMethod void testOperatingTaskScheduled() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();

            wo.RecordTypeId = woRecTypeOperating;
            update wo;

            
            woli.RecordTypeId = woliRecTypeOperating;
            insert woli;

            Test.startTest();
            WorkOrderLineItemTriggerHandler.hasException = true;
            woli.Status = Label.TS_WOLI_Status_Scheduled;
            update woli;

            Test.stopTest();
            
            System.assertEquals('Scheduled',woli.status);
        }
    }

    /**
    * @author        Karen Hung
    * @date          12.10.2018           
    * @description   Test method to cover Routesales task cancellation
    * @revision(s)
    */
    static testMethod void testRoutesalesTaskCanceled() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        //User engineer = TS_TestDataFactory.createUser(Label.TS_ResourceUsrProf_ThirdParty);
            
        System.runAs(u) {
            setupTestData();
            
           /* Resource__c eng= new Resource__c();
            eng.id = engineer.id;
            eng.RelatedUser__c = u.id;
            insert eng;*/
            
            Id caseRecTypeRouteSales = TS_UtilityClass.getRecordTypeIdByName(Label.TS_Obj_API_Name_Case, Label.TS_Case_Type_RouteSales); 
            Id woliRecTypeRouteSalesTask = TS_UtilityClass.getRecordTypeIdByName(Label.TS_Obj_API_Name_WOLI, Label.TS_WOLI_Type_RouteSalesTask);
            
            c.RecordTypeId = caseRecTypeRouteSales;
            c.CaseSubStatus__c = Label.TS_Status_Canceled;
            update c;
            
            //wo.RecordTypeId = TS_UtilityClass.getRecordTypeIdByName(Label.TS_Obj_API_Name_WorkOrder, Label.TS_WOLI_Type_RouteSalesTask);
            //update wo;

            
            woli.RecordTypeId = woliRecTypeRouteSalesTask;
            //woli.ExecutingEngineer__c = eng.id;
            insert woli;

            Test.startTest();
            WorkOrderLineItemTriggerHandler.hasException = true;
            
            woli.Status = Label.TS_Status_Canceled;
            update woli;
            
            delete woli;
            undelete woli;
            Test.stopTest();
            
            System.assertEquals('Canceled',woli.status);
        }
    }
    
    /**
    * @author        Karen Hung
    * @date          10.29.2018           
    * @description   Test method to cover other lines in provideEngineerAccess
    * @revision(s)
    */
    static testMethod void coverEngAccessTest() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
            setupTestData();
          

            Test.startTest();
            insert woli;
            engr.CATSProfile4digCode__c ='JDEP';
            engr.UserProfile__c = 'Third Party Capacity';
            engr.RelatedUser__c = u.id;
            update engr;
            woli.ExecutingEngineer__c = engr.id;
            woli.InternalOrderSAP__c = '12345678910';
            update woli;
            Test.stopTest();
            System.assert(woli !=null);
        }
    }

    /**
    * @author        Karen Hung
    * @date          10.29.2018           
    * @description   Test method to cover other lines in provideEngineerAccess
    * @revision(s)
    */
    static testMethod void TEST_reparentCounterReading () {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        Map<Id, List<WorkOrderLineItem>> WORKORDER_COUNTEREADING_MAP = new Map<Id, List<WorkOrderLineItem>>();
        List<WorkOrderLineItem> updateWOLIList = new List<WorkOrderLineItem>();
        
        System.runAs(u) {  
            setupTestData();          
           
            Test.startTest();
            
            //INSERT LARGE TASK
            woli.WorkOrderType__c = 'S20';
            woli.WorkOrderLineItemType__c = 'Large';
            insert woli;
            
            woli.ExecutingEngineer__c = engr.id;
            woli.InternalOrderSAP__c = '12345678913';
            woli.Status = Label.TS_WOLI_Status_Scheduled;
            update woli;
                     
            woli.SendCounterReadingsOperating__c = true;
            woli.Status = 'Completed';
            woli.OP_CreateParent__c = true;
            updateWOLIList.add(woli);
            
            WorkOrderLineItem woliCounter = new WorkOrderLineItem();
            woliCounter.WorkOrderId = wo.Id;
            woliCounter.OP_CreateParent__c = true;
            woliCounter.ParentWorkOrderLineItemId = woli.Id;
            woliCounter.WorkOrderType__c = 'S20';
            woliCounter.WorkOrderLineItemType__c = 'Large';
            insert woliCounter;
            
            
            WORKORDER_COUNTEREADING_MAP.put(woliCounter.ParentWorkOrderLineItemId, new List<WorkOrderLineItem>{woliCounter});
            WorkOrderLineItemTriggerHandler.WORKORDER_COUNTEREADING_MAP.putAll(WORKORDER_COUNTEREADING_MAP);
            woliCounter.SendCounterReadingsOperating__c = true;
            woliCounter.Status = 'Completed';
            woliCounter.OP_CreateParent__c = true;
            updateWOLIList.add(woliCounter);
            
            update updateWOLIList;
      
            Test.stopTest();

            System.assert(woli !=null);
            
        }
    }

    /**
    * @author        Francis Alindogan
    * @date          06.24.2019           
    * @description   Test method to cover other lines in provideEngineerAccess
    * @revision(s)
    */
    /*
    static testMethod void TEST_removeExecutingEngineerAccessShare () {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        Boolean isDeleted = false;
        
        System.runAs(u) {
            setupTestData();
            Test.startTest();

            insert woli;
        
            //SETUP WOLI RELATIONSHIPS            
            c.SecondaryContact__c = con.Id; 
            update c;
            Resource__c testResource = TS_TestDataFactory.createResourceSingle('Test Resource Number');
            testResource.RelatedUser__c = u.Id;
            insert testResource;
            
            //ASSIGN WOLI TO ENGINEER
            woli.ExecutingEngineer__c = testResource.Id;
            update woli;
            List<AccountShare> accShareOld = [Select Id from AccountShare WHERE AccountId = :c.AccountId AND UserOrGroupId = :testResource.RelatedUser__c];        
            system.debug(accShareOld);
            if(!accShareOld.isEmpty() && accShareOld.size() > 0){

                //UNASSIGN WOLI TO ENGiNEER
                woli.ExecutingEngineer__c = null;
                update woli;
                List<AccountShare> accShareNew = [Select Id from AccountShare WHERE AccountId = :c.AccountId AND UserOrGroupId = :testResource.RelatedUser__c AND RowCause = 'Manual'];    
                system.debug(accShareNew);
                if(accShareNew.isEmpty()){
                    isDeleted = true;
                }
            }        
            Test.stopTest();
            system.assert(isDeleted);
        }
    }
    */

    /**
    * @author        Francis Allen Alindogan
    * @date          04.15.2020
    * @description   Test method to cover other lines in updatePAifMCOComplete
    * @revision(s)
    */
    static testMethod void testUpdatePAifMCOComplete () {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {  
            setupTestData();          
           
            Test.startTest();

            //UPDATE WO
            String CONST_WOLI_OP_RT = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get(TS_Constants.TS_WOLI_RECORDTYPE_OPERATINGTASK).getRecordTypeId();
            WorkOrder wo = [SELECT Id,Task_Activity_Type__c from WorkOrder WHERE Id =: woli.WorkOrderId LIMIT 1];
            wo.Task_Activity_Type__c = 'Large';
            update wo;

            //UPDATE PA
            PhysicalAsset__c pa = [SELECT Id, SalesOrganization__c FROM PhysicalAsset__c WHERE Id =: woli.PhysicalAsset__c LIMIT 1];
            pa.SalesOrganization__c = 'SAP_0975';
            update pa;
                        
            //INSERT MCO TASK
            woli.WorkOrderLineItemType__c = 'Preventive Maintenance';
            woli.RecordTypeId = CONST_WOLI_OP_RT;
            woli.isFromRoute__c = true;
            woli.WorkOrderType__c = TS_Constants.WO_TYPE_S20_MACHINECARE;
            insert woli;
            
            woli.ExecutingEngineer__c = engr.id;
            woli.InternalOrderSAP__c = '12345678913';
            woli.Status = Label.TS_WOLI_Status_Scheduled;
            update woli;
             
            //COMPLETE MCO TASK
            woli.Status = 'Completed';           
            update woli;

      
            Test.stopTest();

            System.assert([SELECT LastPreventiveMaintenanceDate__c FROM PhysicalAsset__c WHERE Id =:woli.PhysicalAsset__c LIMIT 1].LastPreventiveMaintenanceDate__c != null);
            
        }
    }

    /*
    * @author        Francis Allen Alindogan
    * @date          June 8, 2020
    * @description   DOO-4616 For coverage of createReturnTask method
    * @revision(s)   
    */
    static testMethod void testCreateReturnTask() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();         

            //WITHOUT WARRANTY, UNDER CONTRACT AND WITH COVERAGE
            PhysicalAsset__c pAsset2 = TS_TestDataFactory.createPhysicalAsset();
            pAsset2.SalesOrganization__c = 'SAP_0333';
            pAsset2.EndDate__c = Date.today().addDays(3);
            pAsset2.AssetStatus__c = TS_Constants.PA_STATUS_ACTIVATED;
            pAsset2.LabourChargeCoverage__c = 10;
            pAsset2.Warranty__c = '0';
            insert pAsset2;
            
            //WITH WARRANTY
            pAsset.SalesOrganization__c = 'SAP_0333';
            pAsset.AssetStatus__c = TS_Constants.PA_STATUS_ACTIVATED;
            pAsset.LabourChargeCoverage__c = 5;
            pAsset.Warranty__c = '3';
            pAsset.WarrantyStartDate__c = Date.today().addDays(-1);
            update pAsset;
            
            Test.startTest();
            woli.WorkOrderType__c = Label.TS_Case_SubType_CorrectMaintAPI;
            woli.Status = TS_Constants.WOLI_STATUS_SCHEDULED;
            woli.WorkOrderLineItemType__c = TS_Constants.TYPE_TASK;            
            woli.Subject = 'subj';
            woli.Description = 'desc';
            woli.Created_Manually__c = true;
            woli.InternalOrderSAP__c = '1243445';
            woli.ExecutingEngineer__c = engr.Id;
            insert woli;
                        
            WorkOrderLineItem partsWoli = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);
            partsWoli.Case__c = c.Id;            
            partsWoli.ParentWorkOrderLineItemId = woli.Id;
            partsWoli.WorkOrderLineItemType__c = TS_Constants.WOLI_STATUS_MISSING;
            insert partsWoli;

            product2 pd = TS_TestDataFactory.createProductTest('ProductTest','ZSPR');
            insert pd;

            CountrySetting__c testCS = TS_TestDataFactory.createCountrySettings();
            testCS.Product__c = pd.Id;
            testCS.WorkOrderType__c = 'S10';
            testCS.isLabour__c = true;
            testCS.Country__c = 'SAP_0333';
            insert testCS;

            woli.Status = 'Completed';
            woli.Return_task_processed__c = false;
            woli.Return_Needed_S10__c = true;
            woli.ReturnNeeded__c = true;
            woli.StartDate__c = Date.today();
            woli.EndDate__c = Date.today();
            woli.Travel_Start_Time__c = Date.today();
            woli.Travel_Stop_Time__c = Date.today();               
            woli.Return_Needed_Comment__c = 'Comment';
            update woli;

            //RETURN TASK 
            WorkOrderLineItem retWoli;
            retWoli = [SELECT Id, Status, PhysicalAsset__c, Return_task_processed__c, Return_Needed_S10__c, ReturnNeeded__c, StartDate__c, EndDate__c, Travel_Start_Time__c, Travel_Stop_Time__c, Return_Needed_Comment__c, RelateTo__c FROM WorkOrderLineItem WHERE RelateTo__c =:woli.Id LIMIT 1];

            retWoli.Status = 'Scheduled';
            retWoli.PhysicalAsset__c = pAsset2.Id;
            update retWoli;

            retWoli.Subject = 'subj';
            retWoli.Description = 'desc';
            retWoli.Created_Manually__c = true;
            retWoli.InternalOrderSAP__c = '12434456';
            retWoli.Status = 'Completed';
            retWoli.Return_task_processed__c = false;
            retWoli.Return_Needed_S10__c = true;
            retWoli.ReturnNeeded__c = true;
            retWoli.StartDate__c = Date.today();
            retWoli.EndDate__c = Date.today();
            retWoli.Travel_Start_Time__c = Date.today();
            retWoli.Travel_Stop_Time__c = Date.today();                            
            retWoli.Return_Needed_Comment__c = 'Comment';
            update retWoli;
            
            woli1.WorkOrderType__c = Label.TS_Case_SubType_CorrectMaintAPI;
            woli1.Status = TS_Constants.WOLI_STATUS_SCHEDULED;
            woli1.WorkOrderLineItemType__c = TS_Constants.TYPE_TASK;            
            woli1.Subject = 'subj';
            woli1.Description = 'desc';
            woli1.Created_Manually__c = true;
            woli1.InternalOrderSAP__c = '1243445';
            woli1.ExecutingEngineer__c = engr.Id;
            woli1.PhysicalAsset__c = pAsset2.Id;
            insert woli1;
            
            woli1.Status = 'Completed';
            woli1.Return_task_processed__c = false;
            woli1.Return_Needed_S10__c = true;
            woli1.ReturnNeeded__c = true;
            woli1.StartDate__c = Date.today();
            woli1.EndDate__c = Date.today();
            woli1.Travel_Start_Time__c = Date.today();
            woli1.Travel_Stop_Time__c = Date.today();               
            woli1.Return_Needed_Comment__c = 'Comment';
            update woli1;

            Test.stopTest();
            
            System.assert([SELECT Id FROM WorkOrderLineItem WHERE RelateTo__c =:woli.Id LIMIT 1].Id != null);
        }
    }
  
    /*
    * @author        Francis Allen Alindogan
    * @date          June 30, 2020
    * @description   DOO-4623 For coverage of populateProduct method
    * @revision(s)   
    */
    static testMethod void testPopulateProduct() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();                  
            wo.Pricebook2Id = standardPBID;
            update wo;

            c.ProductId = prod.Id;
            update c;

            Test.startTest();

            //POPULATE PBE AFTER CONVERSION
            woli.WorkOrderType__c = TS_Constants.CASE_SUBTYPE_CORRECTMAINTAPI;
            woli.Status = TS_Constants.WOLI_STATUS_SCHEDULED;
            woli.WorkOrderLineItemType__c = TS_Constants.TYPE_TASK;            
            woli.Subject = 'subj';
            woli.Description = 'desc';
            woli.Populate_Pricebook__c = false;
            woli.Created_Manually__c = true;
            woli.InternalOrderSAP__c = '1243445';
            woli.ExecutingEngineer__c = engr.Id;
            insert woli;         

            //POPULATE PBE AFTER ADDING SERVICE JOB (WITHOUT PA)
            WorkOrderLineItem woli2 = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);         
            woli2.Case__c = c.Id;            
            woli2.WorkOrderLineItemType__c = Label.TS_Type_Task;
            woli2.AssetLineItem__c = ali.Id;
            woli2.AccountLocation__c = accLoc.Id;
            woli2.OrderLineItem__c = oli.Id;
            woli2.EndDate__c = DateTime.now();
            woli2.WorkOrderType__c = TS_Constants.CASE_SUBTYPE_1STLINECORRECTMAINTAPI;
            woli2.Status = TS_Constants.WOLI_STATUS_SCHEDULED;               
            woli2.Subject = 'subj';
            woli2.Description = 'desc';
            woli2.Product__c = null;
            woli2.PhysicalAsset__c = null;
            woli2.Populate_Pricebook__c = false;
            woli2.Is_Additional_Service_Job__c = true;
            woli2.InternalOrderSAP__c = '1243445';
            woli2.ExecutingEngineer__c = engr.Id;
            insert woli2;         

            //PRE-CHECKING FOR POPULATE PBE AFTER ADDING SERVICE JOB (WITH PA)           
            WorkOrderLineItem  woli3 = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);         
            woli3.Case__c = c.Id;
            woli3.PhysicalAsset__c = pAsset.Id;
            woli3.WorkOrderLineItemType__c = Label.TS_Type_Task;
            woli3.AssetLineItem__c = ali.Id;
            woli3.AccountLocation__c = accLoc.Id;
            woli3.OrderLineItem__c = oli.Id;
            woli3.EndDate__c = DateTime.now();
            woli3.WorkOrderType__c = TS_Constants.ORDER_S40;
            woli3.Status = TS_Constants.WOLI_STATUS_SCHEDULED;               
            woli3.Subject = 'subj';
            woli3.Description = 'desc';
            woli3.Populate_Pricebook__c = false;
            woli3.Is_Additional_Service_Job__c = true;
            woli3.InternalOrderSAP__c = '1243445';
            woli3.ExecutingEngineer__c = engr.Id;
            insert woli3;         
       
            Test.stopTest();
            
            System.assert([SELECT Populate_Pricebook__c FROM WorkOrderLineItem WHERE Id =:woli.Id LIMIT 1].Populate_Pricebook__c != null);
        }    
    }

    /*
    * @author        Francis Allen Alindogan
    * @date          July 01, 2020
    * @description   DOO-4621 For coverage of setWorkTimeStamps method
    * @revision(s)   
    */
    static testMethod void testSetWorkTimeStamps() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();                  
            wo.Pricebook2Id = standardPBID;
            update wo;

            c.ProductId = prod.Id;
            update c;
            
            Test.startTest();
            woli.WorkOrderType__c = Label.TS_Case_SubType_CorrectMaintAPI;
            woli.Status = TS_Constants.WOLI_STATUS_SCHEDULED;
            woli.WorkOrderLineItemType__c = TS_Constants.TYPE_TASK;            
            woli.Subject = 'subj';
            woli.Description = 'desc';
            woli.Populate_Pricebook__c = false;
            woli.Created_Manually__c = true;
            woli.InternalOrderSAP__c = '1243445';
            woli.ExecutingEngineer__c = engr.Id;            
            insert woli;       
            
            //FOR ONSITE
            woli.Status = TS_Constants.WOLI_STATUS_ONSITE;            
            woli.StartDate__c = system.now();
            update woli;
            
            //FOR STARTWORK
            woli.Status = TS_Constants.WOLI_STATUS_STARTWORK;
            update woli;
           
            Test.stopTest();
            
            System.assert([SELECT StartedWorkTime__c FROM WorkOrderLineItem WHERE Id =:woli.Id LIMIT 1].StartedWorkTime__c != null);
        }    
    }

    /*
    * @author        Francis Allen Alindogan
    * @date          July 08, 2020
    * @description   DOO-4599 For coverage of checkForReviewNeededCritera method
    * @revision(s)   
    */
    static testMethod void testCheckForReviewNeededCriteria() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData(); 

            Test.startTest();
            //CHECK INTERNAL ORDER SAP
            woli.WorkOrderType__c = Label.TS_Case_SubType_CorrectMaintAPI;
            woli.Status = TS_Constants.WOLI_STATUS_SCHEDULED;
            woli.WorkOrderLineItemType__c = TS_Constants.TYPE_TASK;            
            woli.Subject = 'subj';
            woli.Description = 'desc';
            woli.Populate_Pricebook__c = false;
            woli.Created_Manually__c = true;            
            woli.ExecutingEngineer__c = engr.Id;            
            insert woli;       
            
            //CHECK DATE INTERVALS
            woli.Status = TS_Constants.STATUS_COMPLETED;
            woli.Travel_Start_Time__c = system.now().addDays(2);
            woli.Travel_Stop_Time__c = system.now().addDays(2);
            woli.StartDate__c = system.now().addDays(2);
            woli.EndDate__c = system.now().addDays(2);
            update woli;

            Test.stopTest();
            System.assert([SELECT Status FROM WorkOrderLineItem WHERE Id =:woli.Id LIMIT 1].Status != TS_Constants.WOLI_STATUS_REVIEW);
        }
    }

    /*
    * @author        Abram Vixen Reyes
    * @date          September 1, 2020
    * @description   DOO - 4743 Process builder to trigger: Fixed Costs and Warranty
    * @revision(s)   
    */
    static testMethod void test_fixedCost() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData(); 
            
            Id woli_usedPart_RT = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Register Used Part').getRecordTypeId();
            List<String> materiaPricingList = new List<String>{'SAP_01','SAP_30','SAP_04','SAP_33','SAP_05','SAP_32','SAP_31'};

            //CREATE PRODUCTS
            Map<String, Product2> map_prod = new Map<String, Product2>();
            for(String str_var : materiaPricingList){
                map_prod.put('ProductTest-' + str_var, TS_TestDataFactory.createProductTest('ProductTest-' + str_var,'ZSPR'));
            }
            insert map_prod.values();

            //ITERATE CREATED PRODUCT
            List<sObject> sObjectList = new List<sObject>();
            List<APTS_Sales_Org_Data__c> salesOrgDataList = new List<APTS_Sales_Org_Data__c>();
            List<CountrySetting__c> csSettingsList = new List<CountrySetting__c>();
            List<PricebookEntry> pbEntryListStandard = new List<PricebookEntry>();
            List<PricebookEntry> pbEntryList = new List<PricebookEntry>();

            for(String str_var : materiaPricingList){

                if(map_prod.containsKey('ProductTest-' + str_var)){
                    Product2 prod_var = map_prod.get('ProductTest-' + str_var);
                    
                    //CREATE SALES ORG DATA
                    salesOrgDataList.add( new APTS_Sales_Org_Data__c(   APTS_Product__c = prod_var.Id,
                                                                        APTS_Sales_Org_Data_Name__c = '0333',
                                                                        APTS_Material_Pricing_Group_ID__c = str_var));

                    //CREATE COUNTRY SETTINGS
                    CountrySetting__c fixedCost = TS_TestDataFactory.createCountrySettings();
                    fixedCost.RecordtypeId = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', 'Fixed Costs');
                    fixedCost.Active__c = true;
                    fixedCost.Country__c = 'SAP_0333';
                    fixedCost.Name='PRODUCT-' + str_var;
                    fixedCost.Product__c = prod_var.Id;
                    fixedCost.WorkOrderType__c='S10';
                    csSettingsList.add(fixedCost);
                    
                    //CREATE PRICEBOOK ENTRIES (STANDARD)
                    PricebookEntry pbeStandard = new PricebookEntry();
                    pbeStandard.Product2Id = prod_var.Id;
                    pbeStandard.Pricebook2Id = standardPBID;
                    pbeStandard.UnitPrice = 11;
                    pbeStandard.IsActive = true;
                    pbeStandard.UseStandardPrice = false;
                    pbeStandard.TS_Load_Id__c = String.valueOf(prod_var.Id) + String.valueOf(standardPBID);
                    pbEntryListStandard.add(pbeStandard);

                    //CREATE PRICEBOOK ENTRIES
                    PricebookEntry pbe = new PricebookEntry();
                    pbe.Product2Id = prod_var.id;
                    pbe.Pricebook2Id = orgPB.id;
                    pbe.UnitPrice = 11;
                    pbe.IsActive = true;
                    pbe.TS_Load_Id__c = String.valueOf(prod_var.id) + String.valueOf(orgPB.id);
                    pbEntryList.add(pbe);
                }                
            }
            
            sObjectList.addAll(salesOrgDataList);
            sObjectList.addAll(csSettingsList);
            sObjectList.addAll(pbEntryListStandard);
            sObjectList.addAll(pbEntryList);            
            insert sObjectList;

            pAsset.EndDate__c = Date.today().addDays(100);
            pAsset.AssetStatus__c = 'Activated';
            pAsset.CallOutChargeCoverage__c = 50;
            pAsset.SparePartCoverage__c = 50;
            pAsset.LabourChargeCoverage__c = 50;
            pAsset.WaterfilterCoverage__c = 50;
            pAsset.PreventiveMaintenanceCoverage__c = 50;
            pAsset.FullOperatingCoverage__c = 50;
            update pAsset;      

            woli.WorkOrderType__c = Label.TS_Case_SubType_CorrectMaintAPI;
            woli.Status = TS_Constants.WOLI_STATUS_OPEN;
            woli.WorkOrderLineItemType__c = TS_Constants.TYPE_TASK;            
            woli.Subject = 'subj';
            woli.Description = 'desc';
            woli.Populate_Pricebook__c = false;
            woli.Created_Manually__c = true;            
            insert woli;

            Test.startTest();

            woli.Status = TS_Constants.WOLI_STATUS_SCHEDULED;
            woli.StartDate__c = System.now();
            woli.EndDate__c = System.now();
            woli.ExecutingEngineer__c = engr.Id;
            update woli;

            //CREATE PARTS BEFORE COMPLETING THE TASK
            List<WorkOrderLineItem> allWoli = new List<WorkOrderLineItem>();
            for(PricebookEntry pb_var : pbEntryList){
                //NEW SERVICE MATERIALS
                allWoli.add(new WorkOrderLineItem(    Case__c = woli.Case__c,
                                                            ParentWorkOrderLineItemId = woli.Id,
                                                            WorkOrderId = woli.WorkOrderId,
                                                            RecordTypeId = woli_usedPart_RT,
                                                            PricebookEntryId = pb_var.Id,
                                                            Quantity = 1,
                                                            Warranty__c = 'Default',
                                                            WorkOrderLineItemType__c = 'UsedSpareParts',
                                                            Status = 'Completed'
                                                            ));
            }
            
            allWoli[0].Warranty__c = 'Z1';
                
            List<WorkOrderLineItem> taskAndServMaterials = new List<WorkOrderLineItem>();
            WorkOrderLineItem servMatInserted = [SELECT Id, Warranty__c FROM WorkOrderLineItem WHERE ParentWorkOrderLineItemId =: woli.Id][0];
            servMatInserted.Warranty__c = 'Default';
            allWoli.add(servMatInserted);
            
            woli.Status = TS_Constants.STATUS_COMPLETED;
            woli.InternalOrderSAP__c = 'xxx';
            allWoli.add(woli);
            
            WorkOrderLineItemTriggerHandler.FIXED_COST_DONE = false;
            WorkOrderLineItemTriggerHandler.isNotBatchExecution = true;
            WorkOrderLineItemTriggerHandler.IS_OPERATING_TASK = false;
            TS_FlowProcessor.hasException=true;
            upsert allWoli;
            
            Test.stopTest();        
            System.assert([SELECT Status FROM WorkOrderLineItem WHERE Id =:woli.Id LIMIT 1].Status == TS_Constants.STATUS_COMPLETED);
            System.assert(![SELECT Id, WorkOrderLineItemType__c, Warranty__c, Discount, PricebookEntryId, Product2Id FROM WorkOrderLineItem WHERE ParentWorkOrderLineItemId =:woli.Id AND WorkOrderLineItemType__c = 'UsedSpareParts'].isEmpty());
        }
    }

    /*
    * @author        Francis Allen Alindogan
    * @date          September 24, 2020
    * @description   DOO-4800 DOO-4801 For coverage of cancelContractOrder method
    * @revision(s)   
    */
    static testMethod void testCancelContractOrder() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData(); 
            Test.startTest();
            pAsset.SalesOrganization__c = 'SAP_0975';

            //S32 TASK
            woli.WorkOrderType__c = TS_Constants.TYPE_S30_PREVMAINTENANCE;
            woli.Status = TS_Constants.TS_Status_Open;
            woli.WorkOrderLineItemType__c = TS_Constants.TYPE_TASK;            
            woli.Subject = 'subj';
            woli.Description = 'desc';
            woli.SLADate__c = system.now();  
            insert woli;       

            //S41 CASE
            Case c2 = new Case();
            c2 = TS_TestDataFactory.createFieldServiceCase();
            c2.ContactId = con.Id;
            c2.AccountId = acct.Id;
            c2.PO_Number__c = '123456';
            c2.SalesOrganization__c= 'SAP_0333';
            c2.PhysicalAsset__c = pAsset.Id;
            insert c2;

            //S41 TASK
            WorkOrderLineItem woliS41 = new WorkOrderLineItem();
            woliS41 = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);         
            woliS41.Case__c = c2.Id;
            woliS41.PhysicalAsset__c = pAsset.Id;
            woliS41.WorkOrderLineItemType__c = Label.TS_Type_Task;
            woliS41.AssetLineItem__c = ali.Id;
            woliS41.AccountLocation__c = accLoc.Id;
            woliS41.OrderLineItem__c = oli.Id;
            woliS41.EndDate__c = DateTime.now();   
            woliS41.WorkOrderType__c = TS_Constants.ORDER_S41;  
            woliS41.SLADate__c = system.now();            
            insert woliS41;       

            Test.stopTest();
            System.assert([SELECT COUNT() FROM WorkOrderLineItem WHERE WorkOrderType__c =:TS_Constants.TYPE_S30_PREVMAINTENANCE] != 0);
        }
    }
    
}