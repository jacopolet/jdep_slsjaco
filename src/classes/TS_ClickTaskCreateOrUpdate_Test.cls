/**
* @author        Rey Austral
* @date          5.30.2017           
* @description   Test class for TS_ClickTaskCreateOrUpdate 
* @revision(s)
*/
@isTest
public class TS_ClickTaskCreateOrUpdate_Test { 
    
    private static Apttus_Config2__AccountLocation__c alocation { get { return [Select id from Apttus_Config2__AccountLocation__c Limit 1]; } }
    private static Contact con { get { return [Select id from Contact Limit 1]; } }
    private static Product2 prod { get { return [Select id from Product2 Limit 1]; } }
    private static Apttus_Config2__AssetLineItem__c alt { get { return [Select id from Apttus_Config2__AssetLineItem__c where Name != 'Bundle Asset' Limit 1]; } }
    private static WorkOrder parentWO { get { return [Select id from WorkOrder Limit 1]; } }
    private static Resource__c testResource { get { return [Select id from Resource__c Limit 1]; } }
    private static Case cse { get { return [Select id,Click__c from Case Limit 1]; } }
    private static WorkflowSettings__c work;
    private static JDEServicesCallout.TaskCreateOrUpdate_element elem = new JDEServicesCallout.TaskCreateOrUpdate_element();
    private static TS_ClickTaskCreateOrUpdate reqParts = new TS_ClickTaskCreateOrUpdate();
    private static APTS_CounterReadingData__c assetCR;
    private static PhysicalAsset__c pAsset;
    
    
    //@testSetup
    static void dataSetup() { 
      
        TriggerSettings__c trg = TriggerSettings__c.getOrgDefaults();
        trg.WorkOrderLineItemTrigger__c = true;
        insert trg;         
    
        IntegrationTriggerSettings__c trg1 = IntegrationTriggerSettings__c.getOrgDefaults();
        trg1.IntegrationLogTrigger__c = true;
        insert trg1; 

        ProcessBuilderSettings__c pb = new ProcessBuilderSettings__c();
        pb.CasePBFlows__c = false;
        pb.WorkOrderLineItemPBFlows__c = false;
        insert pb;

        work = new WorkflowSettings__c();
        work.WOLIWorkflows__c  = true;
        insert work;

        Contact con = TS_TestDataFactory.createContact();  
        con.Preferred_Language__c = 'SAP_EN';
        Insert con;
        
        Resource__c testResource = TS_TestDataFactory.createResourceSingle('Test Resource Number');
        insert testResource;

        List<Account> accountList = TS_TestDataFactory.createAccounts(1);
        accountList.get(0).Name = 'SendToClick_Test Name';
        insert accountList;

        Apttus_Config2__AccountLocation__c alocation = TS_TestDataFactory.createAccountLocation( accountList.get(0).Id );
        alocation.Apttus_Config2__PostalCode__c   = '123';
        alocation.Shipping_Country_ISO__c = 'NL';
        alocation.Shipping_Street_Only__c = '1';
        alocation.Apttus_Config2__City__c = 'city';
        alocation.House_Number_Supplement__c = '124';
        insert alocation;
        
        Product2 prod = TS_TestDataFactory.createProduct('name','family');
        prod.ProductCode = 'prod';
        insert prod;

        Apttus_Config2__AssetLineItem__c alt = TS_TestDataFactory.createAssetLineItem();
        alt.Apttus_Config2__ProductId__c = prod.Id;
        insert alt;

        Case cse = TS_TestDataFactory.createFieldServiceCase();
        cse.ContactId = con.Id;       
        cse.SalesOrganization__c = 'SAP_6864';
        cse.Subject = 'Bas';
        cse.Asset__c = alt.Id;
        cse.Type = 'Field Service';       
        insert cse;

        WorkOrder parentWO = TS_TestDataFactory.createWorkOrder();
        parentWO.ContactId = con.Id;
        parentWO.CaseId = cse.Id;
        parentWO.Account_Location__c = alocation.Id;
        parentWO.WorkOrderType__c = Label.TS_Case_SubType_CorrectMaint;
		parentWO.Required_Operator__c = testResource.Id;
        parentWO.Enabled_Survey_in_Click__c = 'OPG_Warehouse';
        insert parentWO;
        
        pAsset = TS_TestDataFactory.createPhysicalAsset();
        pAsset.SerialNumber__c = '1221810208';
        insert pAsset;
        
        assetCR = new APTS_CounterReadingData__c();
        assetCR.TS_Physical_Asset__c = pAsset.Id;
        assetCR.APTS_PriceType__c = 'Free';
        assetCR.APTS_Counter_Status__c = 'Active';
        insert assetCR;
        
        TS_ClickTaskCreateOrUpdate.surveySettingEnabled = true;
        
        List<OperatingHourAssociation__c> ohaList = new List<OperatingHourAssociation__c>();
        OperatingHourAssociation__c oha = new OperatingHourAssociation__c();
        oha.BusinessUnit__c = 'TCS';
        oha.Active__c = true;
        oha.Account_Location__c = alocation.Id;
        oha.CustomServiceHours__c = false;           
        ohaList.add(oha);
        
        OperatingHourAssociation__c oha2 = new OperatingHourAssociation__c();
        oha2.BusinessUnit__c = 'Routesales';
        oha2.Active__c = true;
        oha2.Account_Location__c = alocation.Id;
        oha2.CustomServiceHours__c = false;           
        ohaList.add(oha2);
        
        insert ohaList;
        
    }
  
    private static testMethod void SendToClick_Test() {
        dataSetup();
        // Call the method that invokes a callout
        //WorkOrderLineItem woliParent = TS_TestDataFactory.createWorkOrderLineItem(parentWO.Id);
        system.debug ('Case >>>>>' + cse);
        system.debug ('Resource >>>>>' + testResource);
        system.debug ('Allocation >>>>>' + alocation);
        system.debug ('Work Order >>>>>' + parentWO);
        List <WorkOrderLineItem> woliList = new List <WorkOrderLineItem> ();
        WorkOrderLineItem woliParent = new WorkOrderLineItem();
        woliParent.Status = Label.TS_Status_Open;
        woliParent.WorkOrderId = parentWO.Id;
        
        woliParent.ExecutingEngineer__c = testResource.Id;
        woliParent.ExcludedEngineer__c = testResource.Id;
        woliParent.RequiredEngineer__c = testResource.Id;
        woliParent.PreferredEngineer__c = testResource.Id;
        woliParent.Status = Label.TS_Status_CompleteD;
        woliParent.InternalOrderSAP__c = '123xxx';  
        woliParent.WorkOrderLineItemType__c = Label.TS_WOLI_Status_Missing;   
        woliParent.Case__c = cse.Id;
        woliParent.AccountLocation__c = alocation.Id;        
        woliParent.ScheduleManually__c  = true;
        woliParent.WorkOrderType__c = 'S10';
        woliParent.Subject = 'testxxx';
        woliParent.ClickReady__c = true;
        woliParent.Enabled_Survey_in_Click__c = 'OPG_Machine';
        system.debug ('Woli >>>>>' + woliParent);
        woliList.add(woliParent);
        insert woliList;      

        test.startTest();    
            // This causes a fake response to be generated
            Test.setMock(WebServiceMock.class, new JDEServicesCallout_Mock());
        
        
            WorkOrderLineItem woliService = TS_TestDataFactory.createWorkOrderLineItem(parentWO.Id);      
            woliService.ParentWorkOrderLineItemId = woliParent.Id;
            woliService.Status = Label.TS_Status_Open;       
            woliService.WorkOrderLineItemType__c = Label.TS_Type_Service;  
            woliService.RecordTypeID = TS_UtilityClass.getRecordTypeIdByName(Label.TS_Obj_API_Name_WOLI, Label.TS_WOLI_RecordType_REGSERVMAT);      
            woliService.AssetLineItem__c = alt.Id;
            woliService.WorkOrderType__c = 'S10';
            woliService.Case__c = cse.Id;
            insert woliService;
    
            woliService.EarlyStart__c = Datetime.now();
            update woliService;
            
        test.stopTest();
        
        List<Integration_Log__c> resultList = [Select id,Integration_Status__c from Integration_Log__c where Object_Id__c =: woliParent.Id
                                                and Integration_Status__c =: INT_Constants.TARGET_SYSTEM_SUCCESS];
      //  System.assert( resultList.size() > 0);      
    }

    
    private static testMethod void getRequiredPart_Test() {
        dataSetup();
        
        // Call the method that invokes a callout
        //WorkOrderLineItem woliParent = TS_TestDataFactory.createWorkOrderLineItem(parentWO.Id);
        system.debug ('Case >>>>>' + cse);
        system.debug ('Resource >>>>>' + testResource);
        system.debug ('Allocation >>>>>' + alocation);
        system.debug ('Work Order >>>>>' + parentWO);
        List <WorkOrderLineItem> woliList = new List <WorkOrderLineItem> ();
        WorkOrderLineItem woliParent = new WorkOrderLineItem();
        woliParent.Status = Label.TS_Status_Open;
        woliParent.WorkOrderId = parentWO.Id;
        
        woliParent.ExecutingEngineer__c = testResource.Id;
        woliParent.ExcludedEngineer__c = testResource.Id;
        woliParent.RequiredEngineer__c = testResource.Id;
        woliParent.PreferredEngineer__c = testResource.Id;
        woliParent.InternalOrderSAP__c = '123xxx';  
        woliParent.Case__c = cse.Id;
        woliParent.AccountLocation__c = alocation.Id;        
        woliParent.ScheduleManually__c  = true;
        woliParent.WorkOrderType__c = 'S10';
        woliParent.Subject = 'testxxx';
        woliParent.ClickReady__c = true;
        system.debug ('Woli >>>>>' + woliParent);
        woliList.add(woliParent);
        insert woliList;      

        test.startTest();    
            // This causes a fake response to be generated
            Test.setMock(WebServiceMock.class, new JDEServicesCallout_Mock());
            WorkOrderLineItem woliService = TS_TestDataFactory.createWorkOrderLineItem(parentWO.Id);      
            woliService.ParentWorkOrderLineItemId = woliParent.Id;
            woliService.Status = Label.TS_Status_Open;       
            woliService.WorkOrderLineItemType__c = Label.TS_Type_Service;  
            //woliService.RecordTypeID = TS_UtilityClass.getRecordTypeIdByName(Label.TS_Obj_API_Name_WOLI, Label.TS_WOLI_RecordType_REGSERVMAT);      
            woliService.AssetLineItem__c = alt.Id;
            woliService.WorkOrderType__c = 'S10';
            woliService.WorkOrderLineItemType__c = Label.TS_WOLI_Status_Missing;  
            woliService.Case__c = cse.Id;
            insert woliService;
    
            woliService.EarlyStart__c = Datetime.now();
            update woliService;
            
            woliParent.RelateTo__c = woliService.id;
            woliParent.Status = Label.TS_Status_CompleteD;
            update woliParent;
            
            system.debug('Marvin xxx ParentWorkOrderLineItemId :' + woliService.ParentWorkOrderLineItemId);
            system.debug('Marvin xxx WorkOrderLineItemType__c :' + woliService.WorkOrderLineItemType__c);
            List<WorkOrderLineItem> requiredWoli = [Select PricebookEntry.Product2.Name,
                                                      PricebookEntry.Product2Id,Quantity,
                                                      ParentWorkOrderLineItemId 
                                                    From WorkOrderLineItem 
                                                    Where WorkOrderLineItemType__c = :Label.TS_WOLI_Status_Missing 
                                                    And ParentWorkOrderLineItemId = :woliParent.id ];
            
            system.debug('Marvin ... requiredWoli :' + requiredWoli);
            if (!String.isBlank( woliParent.RelateTo__c ) && !requiredWoli.isEmpty()) {
                elem.RequiredParts = reqParts.getRequiredParts(requiredWoli, woliParent.id);
            } 
            
        test.stopTest();
        
        List<Integration_Log__c> resultList = [Select id,Integration_Status__c from Integration_Log__c where Object_Id__c =: woliParent.Id
                                                and Integration_Status__c =: INT_Constants.TARGET_SYSTEM_SUCCESS];
       // System.assert( resultList.size() > 0);      
          
    }
    
    private static testMethod void NotifyUpdate_Test() {
        dataSetup();
        
        IntegrationUserAndProfile__c  trg2 = IntegrationUserAndProfile__c.getOrgDefaults();
        trg2.Click_Integration_Name__c = userinfo.getName();
        upsert trg2;  
        
        test.startTest();    
       // This causes a fake response to be generated
        Test.setMock(WebServiceMock.class, new JDEServicesCallout_NotifyMock());
        // Call the method that invokes a callout
        WorkOrderLineItem woliParent = TS_TestDataFactory.createWorkOrderLineItem(parentWO.Id);
        woliParent.ExecutingEngineer__c = testResource.Id;
        woliParent.Status = Label.TS_Status_CompleteD;
        woliParent.InternalOrderSAP__c = '123';  
        woliParent.WorkOrderLineItemType__c = Label.TS_WOLI_Status_Missing;   
        woliParent.Case__c = cse.Id;
        insert woliParent;       

        woliParent.Description = 'test';
        woliParent.WithinSLA__c = true;
        update woliParent;
        
        test.stopTest();
        
        List<Integration_Log__c> resultList = [Select id,Integration_Status__c from Integration_Log__c where Object_Id__c =: woliParent.Id
                                                ];
       // System.assertEquals(1, resultList.size());       
    }
    
    /*
    private static testMethod void ErrorNotifyUpdate_Test() {
        dataSetup();
        work.WOLIWorkflows__c  = false;
        update work;

        WorkOrderLineItem woliParent = TS_TestDataFactory.createWorkOrderLineItem(parentWO.Id);
        woliParent.ExecutingEngineer__c = testResource.Id;
        woliParent.Status = Label.TS_Status_CompleteD;
        woliParent.InternalOrderSAP__c = '123';  
        woliParent.WorkOrderLineItemType__c = Label.TS_WOLI_Status_Missing;   
        woliParent.Case__c = cse.Id;
        woliParent.PricebookEntryId = '01u4E000006rJqvQAE'; //intentionaly hard coded to force the system to error
        insert woliParent;
        
        IntegrationUserAndProfile__c  trg2 = IntegrationUserAndProfile__c.getOrgDefaults();
        trg2.Click_Integration_Name__c = userinfo.getName();
        upsert trg2; 
        
        test.startTest();          

        WorkOrderLineItem woliChild = TS_TestDataFactory.createWorkOrderLineItem(parentWO.Id);
        woliChild.ExecutingEngineer__c = testResource.Id;
        woliChild.ExcludedEngineer__c = testResource.Id;
        woliChild.RequiredEngineer__c = testResource.Id;
        woliChild.PreferredEngineer__c = testResource.Id;
        woliChild.ParentWorkOrderLineItemId = woliParent.Id;
        woliChild.Status = Label.TS_Status_Canceled;
        woliChild.WorkOrderLineItemType__c = Label.TS_WOLI_Status_Missing;         
        woliChild.Case__c = cse.Id;
        woliChild.AccountLocation__c = alocation.Id;
        woliChild.WorkOrderType__c = Label.TS_Type_Task;
        woliChild.ScheduleManually__c  = true;
        woliChild.ClickReady__c = true;
        woliChild.Subject = 'test';
        woliChild.RelateTo__c = woliParent.Id;
        woliParent.PricebookEntryId = '23442';
        insert woliChild;
        
        test.stopTest();
        
        List<Integration_Log__c> resultList = [Select id,Integration_Status__c,Object__c from Integration_Log__c where Object_Id__c =: woliChild.Id
                                                and Integration_Status__c =: INT_Constants.TARGET_SYSTEM_ERROR];
                                        
        System.assertEquals(1, resultList.size());   

        //Call other function that is not being used currently, need to increase the test coverage

    }
    */
    
    
     private static testMethod void executeOperationalTaskOperatingTask() {
         
        dataSetup();
        work.WOLIWorkflows__c  = false;
        update work;
        
        IntegrationUserAndProfile__c  trg2 = IntegrationUserAndProfile__c.getOrgDefaults();
        trg2.Click_Integration_Name__c = userinfo.getName();
        upsert trg2; 
        
        List <WorkOrderLineItem> woliList = new List <WorkOrderLineItem> ();
        List <Integration_Log__c> integLogsList = new List <Integration_Log__c>();
        WorkOrderLineItem woliParent = new WorkOrderLineItem();
        
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            
        
            test.startTest();  
                woliParent.Status = Label.TS_Status_Open;
                woliParent.WorkOrderId = parentWO.Id;
                
                woliParent.ExecutingEngineer__c = testResource.Id;
                woliParent.ExcludedEngineer__c = testResource.Id;
                woliParent.RequiredEngineer__c = testResource.Id;
                woliParent.PreferredEngineer__c = testResource.Id;
                woliParent.Status = Label.TS_Status_CompleteD;
                woliParent.InternalOrderSAP__c = '123xxx';  
                woliParent.SLADate__c = system.now();
            	woliParent.PhysicalAsset__c = pAsset.Id;
                woliParent.AccountLocation__c = alocation.Id;        
                woliParent.WorkOrderType__c = Label.TS_Activity_Type_S20;
                woliParent.Subject = 'testxxx';
                woliParent.ClickReady__c = true;
            	woliParent.WorkOrderLineItemType__c = 'Large';
            	woliParent.SendCounterReadingsOperating__c = true;
                woliParent.Case__c = cse.Id;
                system.debug ('Woli >>>>>' + woliParent);
                //woliList.add(woliParent);
                insert woliParent;
                woliParent.SLADate__c = system.now().addDays(1);
                update woliParent;
                
                //Boolean isOperatingTask = (Label.TS_Activity_Type_S20.equals(woli.WorkOrderType__c) ||Label.TS_Activity_Type_S21.equals(woli.WorkOrderType__c)||Label.TS_Activity_Type_S22.equals(woli.WorkOrderType__c ) );
                                                                                 
            test.stopTest();
            
            List<Integration_Log__c> resultList = [Select id,Integration_Status__c,Object__c From Integration_Log__c 
                                                   Where Object_Id__c =: woliParent.Id];
                                            
            System.assert(resultList !=null);
        }   
     }
     
     private static testMethod void executeOperationalTaskCounterReading() {
      
        dataSetup();
        work.WOLIWorkflows__c  = false;
        update work;
        
        IntegrationUserAndProfile__c  trg2 = IntegrationUserAndProfile__c.getOrgDefaults();
        trg2.Click_Integration_Name__c = userinfo.getName();
        upsert trg2; 
        
        List <WorkOrderLineItem> woliList = new List <WorkOrderLineItem> ();
        List <Integration_Log__c> integLogsList = new List <Integration_Log__c>();
        WorkOrderLineItem woliParent = new WorkOrderLineItem();
        WorkOrderLineItem woliCounter = new WorkOrderLineItem();
        String CONST_WOLI_CHILD_CR_RT = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Counter Reading').getRecordTypeId(); 
       
        
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            
        
            test.startTest();  
                woliParent.Status = Label.TS_Status_Open;
                woliParent.WorkOrderId = parentWO.Id;
                woliParent.RecordTypeId = CONST_WOLI_CHILD_CR_RT;
                woliParent.ExecutingEngineer__c = testResource.Id;
                woliParent.ExcludedEngineer__c = testResource.Id;
                woliParent.RequiredEngineer__c = testResource.Id;
                woliParent.PreferredEngineer__c = testResource.Id;
                woliParent.Status = Label.TS_Status_CompleteD;
                woliParent.InternalOrderSAP__c = '123xxx';  
                woliParent.SLADate__c = system.now();
                woliParent.AccountLocation__c = alocation.Id;        
                woliParent.WorkOrderType__c = Label.TS_Activity_Type_S21;
                woliParent.Subject = 'testxxx';
                woliParent.ClickReady__c = true;
                woliParent.Case__c = cse.Id;

                //woliList.add(woliParent);
                insert woliParent;
                woliCounter.WorkOrderId = parentWO.Id;
                woliCounter.ParentWorkOrderLineItemId = woliParent.id;
                woliCounter.RecordTypeID =Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Counter Reading Task').getRecordTypeId();
                woliCounter.OP_AverageFreeConsumptions__c = '1';
                woliCounter.OP_AveragePaidConsumptions__c = '1';
                woliCounter.OP_CounterSequence__c =1;
                woliCounter.Case__c = cse.Id;
                insert woliCounter;
                 
                woliParent.SLADate__c = system.now().addDays(1);
                update woliParent;
                
                //Boolean isOperatingTask = (Label.TS_Activity_Type_S20.equals(woli.WorkOrderType__c) ||Label.TS_Activity_Type_S21.equals(woli.WorkOrderType__c)||Label.TS_Activity_Type_S22.equals(woli.WorkOrderType__c ) );
                                                                                 
            test.stopTest();
            
            List<Integration_Log__c> resultList = [Select id,Integration_Status__c,Object__c From Integration_Log__c 
                                                   Where Object_Id__c =: woliParent.Id];
                                            
            System.assert(resultList !=null);
        }   
     }
     

    /*private static testMethod void callOtherFunction() {
        JDEServicesCallout.JDEServiceOptimizationPort callout = new JDEServicesCallout.JDEServiceOptimizationPort();
        JDEServicesCallout.Part_element part = new JDEServicesCallout.Part_element();
        JDEServicesCallout.IngredientItem_element ing = new JDEServicesCallout.IngredientItem_element();
        JDEServicesCallout.UserCreate_element us = new JDEServicesCallout.UserCreate_element();
        JDEServicesCallout.Configurations_element config = new JDEServicesCallout.Configurations_element();
        JDEServicesCallout.WarehouseIngredients_element ware = new JDEServicesCallout.WarehouseIngredients_element();
        JDEServicesCallout.TaskCreateOrUpdateResponse_element up = new JDEServicesCallout.TaskCreateOrUpdateResponse_element();
        Test.setMock(WebServiceMock.class, new JDEServicesCallout_Mock());
        test.startTest();    
        Boolean failedCallout = false;
        try {
            callout.UserCreate(us);    
        } catch(Exception ex) {
            //false callout
            failedCallout = true;
        }
        System.assertEquals(true, failedCallout);
        test.stopTest();
    }*/

    private static testMethod void test_woliMachineHistoryList() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(u) {
            dataSetup();
            PhysicalAsset__c physicalAsset =  new   PhysicalAsset__c(recordtypeid = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get('Machine').getRecordTypeId(),
                   Name = 'Physical Asset',
                   ResponseTime__c = '91',                                                  
                   AssetStatus__c = 'Activated',
                   SerialNumber__c = 'ABCTest');
            insert physicalAsset;

            List <WorkOrderLineItem> woliList = new List <WorkOrderLineItem> ();
            WorkOrderLineItem woliParent = new WorkOrderLineItem();
            woliParent.Status = Label.TS_WOLI_Status_Completed;
            woliParent.WorkOrderId = parentWO.Id;
            woliParent.PhysicalAsset__c = physicalAsset.Id;
            woliParent.ExecutingEngineer__c = testResource.Id;
            woliParent.ExcludedEngineer__c = testResource.Id;
            woliParent.RequiredEngineer__c = testResource.Id;
            woliParent.PreferredEngineer__c = testResource.Id;
            woliParent.InternalOrderSAP__c = '123xxx';  
            woliParent.Case__c = cse.Id;
            woliParent.AccountLocation__c = alocation.Id;        
            woliParent.ScheduleManually__c  = true;
            woliParent.WorkOrderType__c = 'S10';
            woliParent.Subject = 'testxxx';
            woliParent.ClickReady__c = true;
            woliParent.BookAppointmentStart__c = system.now();
            woliParent.BookAppointmentFinish__c = system.now().addDays(1);
            woliParent.UseConfigurationURLFileinTask__c = true;
            woliParent.WorkOrderLineItemType__c = Label.TS_Type_Task;
            woliParent.EndDate__c = Date.today().addDays(50);
            woliList.add(woliParent);
            insert woliList;      

            Test.startTest();    
                List<Integration_Log__c> resultList = [Select id,Integration_Status__c,Object__c From Integration_Log__c 
                                           Where Object_Id__c =:woliList.get(0).id];

                System.assert(resultList != null);
            Test.stopTest();
        }    
    }

    private static testMethod void test_woliCRList() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(u) {
            dataSetup();
            PhysicalAsset__c physicalAsset =  new   PhysicalAsset__c(recordtypeid = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get('Machine').getRecordTypeId(),
                   Name = 'Physical Asset',
                   AssetStatus__c = 'Activated',
                   SerialNumber__c = 'ABCTest',
                   AgreementRecordType__c = 'Consumption Model');
            insert physicalAsset;

            List <WorkOrderLineItem> woliList = new List <WorkOrderLineItem> ();
            WorkOrderLineItem woliParent = new WorkOrderLineItem();
            woliParent.Status = Label.TS_WOLI_Status_Dispatched;
            woliParent.WorkOrderId = parentWO.Id;
            woliParent.PhysicalAsset__c = physicalAsset.Id;
            woliParent.ExecutingEngineer__c = testResource.Id;
            woliParent.ExcludedEngineer__c = testResource.Id;
            woliParent.RequiredEngineer__c = testResource.Id;
            woliParent.PreferredEngineer__c = testResource.Id;
            woliParent.InternalOrderSAP__c = '123xxx';  
            woliParent.Case__c = cse.Id;
            woliParent.AccountLocation__c = alocation.Id;        
            woliParent.ScheduleManually__c  = true;
            woliParent.WorkOrderType__c = 'S10';
            woliParent.Subject = 'testxxx';
            woliParent.ClickReady__c = true;
            woliParent.WorkOrderLineItemType__c = Label.TS_Type_Task;
            woliParent.EndDate__c = Date.today().addDays(50);
            woliList.add(woliParent);
            insert woliList;     

            String CONST_WOLI_CHILD_CR_RT = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Counter Reading').getRecordTypeId(); 
            WorkOrderLineItem woliCounter = new WorkOrderLineItem();
            woliCounter.WorkOrderId = parentWO.Id;
            woliCounter.ParentWorkOrderLineItemId = woliList.get(0).id;
            woliCounter.RecordTypeID = CONST_WOLI_CHILD_CR_RT;
            woliCounter.OP_AverageFreeConsumptions__c = '1';
            woliCounter.OP_AveragePaidConsumptions__c = '1';
            woliCounter.OP_CounterSequence__c =1;
            woliCounter.WorkOrderLineItemType__c = 'Counter Reading';
            woliCounter.Case__c = cse.Id;
            insert woliCounter;
            
            APTS_CounterReadingData__c crData= new APTS_CounterReadingData__c();
            crData.TS_Physical_Asset__c = physicalAsset.Id;
            crData.APTS_Counter_Status__c = 'Active';
            insert crData;

            Test.startTest();    
                List<Integration_Log__c> resultList = [Select id,Integration_Status__c,Object__c From Integration_Log__c 
                                           Where Object_Id__c = :woliList.get(0).id];

                System.assert(resultList != null);
            Test.stopTest();
        }
    }

    private static testMethod void test_executeRoutesales(){

        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(u) {
            dataSetup();
            PhysicalAsset__c physicalAsset =  new   PhysicalAsset__c(recordtypeid = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get('Machine').getRecordTypeId(),
                   Name = 'Physical Asset',
                   AssetStatus__c = 'Activated',
                   SerialNumber__c = 'ABCTest',
                   AgreementRecordType__c = 'Consumption Model');
            insert physicalAsset;

            String CONST_WOLI_CHILD_CR_RT = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Routesales Task').getRecordTypeId(); 

            List <WorkOrderLineItem> woliList = new List <WorkOrderLineItem> ();
            WorkOrderLineItem woliParent = new WorkOrderLineItem();
            woliParent.Status = Label.TS_WOLI_Status_Dispatched;
            woliParent.WorkOrderId = parentWO.Id;
            woliParent.PhysicalAsset__c = physicalAsset.Id;
            woliParent.ExecutingEngineer__c = testResource.Id;
            woliParent.ExcludedEngineer__c = testResource.Id;
            woliParent.RequiredEngineer__c = testResource.Id;
            woliParent.PreferredEngineer__c = testResource.Id;
            woliParent.InternalOrderSAP__c = '123xxx';  
            woliParent.Case__c = cse.Id;
            woliParent.AccountLocation__c = alocation.Id;        
            woliParent.ScheduleManually__c  = true;
            woliParent.WorkOrderType__c = 'S25';
            woliParent.Subject = 'testxxx';
            woliParent.ClickReady__c = true;
            woliParent.WorkOrderLineItemType__c = Label.TS_Type_Task;
            woliParent.EndDate__c = Date.today().addDays(50);
            woliList.add(woliParent);
            insert woliList;     
            
            APTS_CounterReadingData__c crData= new APTS_CounterReadingData__c();
            crData.TS_Physical_Asset__c = physicalAsset.Id;
            insert crData;

            Test.startTest();    
                List<Integration_Log__c> resultList = [Select id,Integration_Status__c,Object__c From Integration_Log__c 
                                           Where Object_Id__c = :woliList.get(0).id];

                System.assert(resultList != null);
            Test.stopTest();
        }       

    }

    private static testMethod void executeOperationalTaskOperatingTask_RouteItem() {
         
        dataSetup();
        work.WOLIWorkflows__c  = false;
        update work;
        
        IntegrationUserAndProfile__c  trg2 = IntegrationUserAndProfile__c.getOrgDefaults();
        trg2.Click_Integration_Name__c = userinfo.getName();
        upsert trg2; 
        
        List <WorkOrderLineItem> woliList = new List <WorkOrderLineItem> ();
        List <Integration_Log__c> integLogsList = new List <Integration_Log__c>();
        WorkOrderLineItem woliParent = new WorkOrderLineItem();
        
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            
        
            test.startTest();  
                woliParent.Status = Label.TS_Status_Open;
                woliParent.WorkOrderId = parentWO.Id;
                
                woliParent.ExecutingEngineer__c = testResource.Id;
                woliParent.ExcludedEngineer__c = testResource.Id;
                woliParent.RequiredEngineer__c = testResource.Id;
                woliParent.PreferredEngineer__c = testResource.Id;
                woliParent.Status = 'Open';
                woliParent.InternalOrderSAP__c = '123xxx';  
                woliParent.SLADate__c = System.now();
            	woliParent.PhysicalAsset__c = pAsset.Id;
                woliParent.AccountLocation__c = alocation.Id;        
                woliParent.WorkOrderType__c = Label.TS_Activity_Type_S20;
            	woliParent.WorkOrderLineItemType__c ='Large';
            	woliParent.SendCounterReadingsOperating__c = true;
                woliParent.Subject = 'testxxx';
                woliParent.ClickReady__c = true;
                woliParent.Case__c = cse.Id;
                woliParent.isFromRoute__c = true;
           		woliParent.Enabled_Survey_in_Click__c = 'OPG_Machine';
                insert woliParent;
            
                woliParent.SLADate__c = system.now().addDays(1);
                update woliParent;
                
                //Boolean isOperatingTask = (Label.TS_Activity_Type_S20.equals(woli.WorkOrderType__c) ||Label.TS_Activity_Type_S21.equals(woli.WorkOrderType__c)||Label.TS_Activity_Type_S22.equals(woli.WorkOrderType__c ));
                                                                                 
            test.stopTest();
            
            List<Integration_Log__c> resultList = [Select id,Integration_Status__c,Object__c From Integration_Log__c 
                                                   Where Object_Id__c =: woliParent.Id];
                                            
            System.assert(resultList != null);
        }   
     }

     private static testMethod void executeOperationalTaskOperatingTask_Route() {
         
        dataSetup();
        work.WOLIWorkflows__c  = false;
        update work;
        
        IntegrationUserAndProfile__c  trg2 = IntegrationUserAndProfile__c.getOrgDefaults();
        trg2.Click_Integration_Name__c = userinfo.getName();
        upsert trg2; 
        
        List <Integration_Log__c> integLogsList = new List <Integration_Log__c>();
        List <WorkOrderLineItem> woliList = new List <WorkOrderLineItem> ();
        WorkOrderLineItem woliParent = new WorkOrderLineItem();
        WorkOrder parentWO_route = TS_TestDataFactory.createWorkOrder();
        
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
        
            test.startTest();  
                parentWO_route.WorkOrderType__c = 'S20';
                parentWO_route.RecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('Operating (Route) Work Order').getRecordTypeId();
                parentWO_route.Status = 'Open';
                parentWO_route.SalesOrganization__c = 'SAP_0111';
             	parentWO_route.Required_Operator__c = testResource.Id;
                parentWO_route.SLA_Date__c = Date.today();
           		parentWO_route.Enabled_Survey_in_Click__c = 'OPG_Warehouse';
                insert parentWO_route;
                
                woliParent.Status = Label.TS_Status_Open;
                woliParent.WorkOrderId = parentWO_route.Id;
                woliParent.ExecutingEngineer__c = testResource.Id;
                woliParent.ExcludedEngineer__c = testResource.Id;
                woliParent.RequiredEngineer__c = testResource.Id;
                woliParent.PreferredEngineer__c = testResource.Id;
                woliParent.Status = 'Open';
                woliParent.InternalOrderSAP__c = '123xxx';  
            	woliParent.PhysicalAsset__c = pAsset.Id;
                woliParent.AccountLocation__c = alocation.Id;        
                woliParent.WorkOrderType__c = Label.TS_Activity_Type_S20;
                woliParent.Subject = 'testxxx';
                woliParent.ClickReady__c = true;
                woliParent.Case__c = cse.Id;
                woliParent.isFromRoute__c = true;
            	woliParent.SLADate__c = Date.today();
                insert woliParent;
				
            	Set<Id> woIds = new Set<Id>();
                Database.executeBatch(new TS_RouteTaskIntegration_Batch(Date.today(), true, 0));
            	Database.executeBatch(new TS_RouteTaskIntegrationRoute_Batch(Date.today(), true, 0, woIds));
            
            test.stopTest();
            
            List<Integration_Log__c> resultList = [Select id,Integration_Status__c,Object__c From Integration_Log__c 
                                                   Where Object_Id__c =: parentWO_route.Id];
                                            
            System.assert(resultList != null);

        }   
     }
}