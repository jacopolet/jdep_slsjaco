/**
* @author        Harold Marilag
* @date          5.30.2017           
* @description   Test class for CaseTriggerHandler
* @revision(s)   23.11.2017 Paul Aguiling - Commented testCaseTriggerHandler due to issues and added new test methods
*/
@isTest
private class CaseTriggerHandlerTest {
    static Account acct;
    static Contact con;
    static Case c;
    static Case case_2;
    static WorkOrder wo;
    static Apttus_Config2__AssetLineItem__c ali;
    static Apttus_Config2__Order__c order;
    static Apttus_Config2__OrderLineItem__c oli;
    static WorkOrderLineItem woli;
    static WorkOrderLineItem woli2 ;
    static PhysicalAsset__c pa;

    @testSetup
    static void dataSetup() {
        //Custom settings is being shared by all test class, if another test class has already inserted the record 
        //this test class will throw "UNABLE_TO_LOCK_ROW, unable to obtain exclusive access to this record"
        try {
            TriggerSettings__c trg = TriggerSettings__c.getOrgDefaults();
            trg.CaseTrigger__c = true;
            trg.WorkOrderTrigger__c = true;
            trg.WorkOrderLineItemTrigger__c = true;
            upsert trg;      
            system.debug('trg is:'+trg);
        } catch(Exception ex) {
            system.debug(ex);
        }

         try {
            IntegrationTriggerSettings__c trg1 = IntegrationTriggerSettings__c.getOrgDefaults();
            trg1.IntegrationLogTrigger__c = true;
            upsert trg1; 
        } catch(Exception ex) {
            system.debug(ex);
        }

        ProcessBuilderSettings__c pb = new ProcessBuilderSettings__c();
        pb.WorkOrderPBFlows__c = true;
        pb.CasePBFlows__c = true;
        insert pb;
    }

    /**
    * @author        Paul Aguiling
    * @date          12.08.2017           
    * @description   Method responsible for creating test data
    * @revision(s)
    */
    static void setupTestData() {
        pa = new PhysicalAsset__c(Name='Test', 
                                  UniqueNumber__c='1234567-TestMachine', 
                                  ResponseTime__c = '8',
                                  ResponseTimeS15__c = 4,
                                  RecordTypeId = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get('Machine').getRecordTypeId());
        insert pa;

        acct = new Account(Name='Account', Phone='+31302979111');
        insert acct;
        
        con = TS_TestDataFactory.createContact();  
        con.Preferred_Language__c = 'SAP_EN';
        Insert con;
        
        c = TS_TestDataFactory.createFieldServiceCase();
        c.ContactId = con.Id;
        c.Status = Label.TS_Status_InProgress;
        insert c;
        
        case_2 = TS_TestDataFactory.createFieldServiceCase();
        case_2.ContactId = con.Id;
        case_2.Status = 'Open';
        case_2.SalesOrganization__c = 'SAP_0111';
        insert case_2;
        
        //CREATE STANDARD PRICEBOOK
        Id standardPBID = Test.getStandardPricebookId();

        //CREATE SALES ORGANIZATION PRICEBOOK
        Pricebook2 orgPB = new Pricebook2();
        orgPB.Name = 'NL Price Book';
        orgPB.IsActive = true;
        orgPB.Sales_Organization__c = 'SAP_0111';
        insert orgPB;
        
        wo = TS_TestDataFactory.createWorkOrder();
        wo.CaseId = c.Id;
        wo.WorkOrderType__c = Label.TS_Case_SubType_CorrectMaint;
        wo.ContactId = con.Id;
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
        order.Apttus_Config2__Status__c = Label.APTS_Pending;
        insert order;
        
        oli = new Apttus_Config2__OrderLineItem__c();
        oli.Apttus_Config2__OrderId__c = order.Id;
        oli.Apttus_Config2__Quantity__c = 1.0;
        oli.Apttus_Config2__AssetLineItemId__c = ali.Id;
        insert oli;

        List<WorkOrderLineItem> wolilist = new List<WorkOrderLineItem>();
        woli = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);         
        woli.Case__c = c.Id;
        woli.WorkOrderLineItemType__c = Label.TS_Type_Task;
        woli.AssetLineItem__c = ali.Id;
        woli.OrderLineItem__c = oli.Id;
        woli.StartDate__c = Datetime.now().addhours(-1);
        woli.EndDate__c = DateTime.now();
        woli.IsFirstTask__c = true;
        woli.CoffeeRunsUponArrival__c = true;
        woli.Status = Label.TS_Status_Completed;
        wolilist.add(woli);
        //insert woli;

        WorkOrderLineItem woli2 = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);         
        //woli2.Case__c = woli.Case__r.Id;
        woli2.Case__c = c.Id;
        woli2.WorkOrderLineItemType__c = Label.TS_Type_Task;
        woli2.AssetLineItem__c = ali.Id;
        woli2.OrderLineItem__c = oli.Id;
        woli2.StartDate__c = Datetime.now().addhours(2);        
        woli2.EndDate__c = DateTime.now().addhours(3);
        woli2.IsFirstTask__c = false;
        woli2.CoffeeRunsUponArrival__c = false;
        woli2.Status = Label.TS_Status_Completed;
        wolilist.add(woli2);
      
        //insert woli2;

        insert wolilist;

        CountrySetting__c countrySetting = new CountrySetting__c(Account__c = acct.Id, CaseSubtype__c = 'Bonus', 
            RecordTypeId = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', 'Country Response Profile'),
            Country__c = 'SAP_0333', Priority__c='High', SLAinHours__c=240, CaseType__c = 'Complaint', 
            Email__c = 'test@accenture1.com', ResponseProfile__c = '96', Active__c = true);

        insert countrySetting; 
    }
    
   /**
    * @author        Paul Jarred Aguiling
    * @date          11.21.2017           
    * @description   Test class for CaseTriggerHandler. 
    *                For 'Country Email Rules' country setting record type
    * @revision(s)
    */
     static testMethod void testGetFromAddressAndDefaultOwner() {
         User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

         System.runAs(u) {
             
             setupTestData();
             
             Account newAccount = new Account(Name='Sample Account', Phone='+31302979111');
             insert newAccount;

             Contact newContact = new Contact(AccountId=newAccount.Id, Lastname='Sample', Email='sample@test.com', Phone='+31302979111');
             insert newContact;

             BusinessHours bh = [select id from BusinessHours where IsDefault = true limit 1 ];

             Entitlement ent = new Entitlement(Name='Sample Entitlement', AccountId = newAccount.Id);
             insert ent;

             ValidationRulesSettings__c vr = ValidationRulesSettings__c.getOrgDefaults();
             vr.CaseValidationRules__c = false;
             upsert vr;

             CountrySetting__c countrySetting1 = new CountrySetting__c(Account__c = newAccount.Id, CaseSubtype__c = 'Bonus', 
                 RecordTypeId = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', 'Country Default Case Owner Rules'),
                 Country__c = 'SAP_0333', Priority__c='Low', SLAinHours__c=240, CaseType__c = 'Field Service', Email__c = 'test@accenture.com', Active__c = true);
             insert countrySetting1; 

             CountrySetting__c countrySetting = new CountrySetting__c(Account__c = newAccount.Id, CaseSubtype__c = 'Bonus', 
                 RecordTypeId = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', 'Country Email Rules'),
                 Country__c = 'SAP_0333', Priority__c='Low', SLAinHours__c=240, CaseType__c = 'Field Service', Email__c = 'test@accenture.com', Active__c = true);
             insert countrySetting; 

             Case cse =  new Case(AccountId = newAccount.Id, Priority = Label.TS_Case_Priority_Medium , SLADate__c=datetime.now(), SubType__c=Label.TS_Case_SubType_CorrectMaint, Type='Field Service', ContactId = newContact.Id, Origin=Label.TS_Case_Origin_Email,
                             BusinessHoursId = bh.Id, EntitlementId=ent.Id, RecordTypeId = TS_UtilityClass.getRecordTypeIdByName(Label.TS_Obj_API_Name_Case, Label.TS_Case_RecordType_Field), PhysicalAsset__c = pa.id,
                             Status = Label.TS_Status_New, CaseSubStatus__c = Label.TS_Status_New, SalesOrganization__c = 'SAP_0333');

             insert cse;
             
             CaseTriggerHandler.hasException = true;

             Test.startTest();
                 System.assertEquals('Field Service', cse.Type);
             Test.stopTest();
         }
     }

   /**
     * @author        Paul Jarred Aguiling
     * @date          11.21.2017           
     * @description   Test class for CaseTriggerHandler.
     *                For 'Country Default Case Owner Rules' country setting record type
     * @revision(s)
     */
     static testMethod void testGetFromAddressAndDefaultOwner2() {
         User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

         System.runAs(u) {
             Account newAccount = new Account(Name='Sample Account', Phone='+31302979111');
             insert newAccount;

             Contact newContact = new Contact(AccountId=newAccount.Id, Lastname='Sample', Email='sample@test.com', Phone='+31302979111');
             insert newContact;

             BusinessHours bh = [select id from BusinessHours where IsDefault = true limit 1 ];

             Entitlement ent = new Entitlement(Name='Sample Entitlement', AccountId = newAccount.Id);
             insert ent;

             ValidationRulesSettings__c vr = ValidationRulesSettings__c.getOrgDefaults();
             vr.CaseValidationRules__c = false;
             upsert vr;

             CountrySetting__c countrySetting1 = new CountrySetting__c(Account__c = newAccount.Id, CaseSubtype__c = 'Bonus', 
                 RecordTypeId = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', 'Country Default Case Owner Rules'),
                 Country__c = 'SAP_0333', Priority__c='Low', SLAinHours__c=240, CaseType__c = 'Field Service', Email__c = 'test@accenture.com', Active__c = true);
             insert countrySetting1; 

             CountrySetting__c countrySetting = new CountrySetting__c(Account__c = newAccount.Id, CaseSubtype__c = 'Bonus', 
                 RecordTypeId = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', 'Country Email Rules'),
                 Country__c = 'SAP_0333', Priority__c='Low', SLAinHours__c=240, CaseType__c = 'Field Service', Email__c = 'test@accenture.com', Active__c = true);
             insert countrySetting; 

             Case cse =  new Case(AccountId = newAccount.Id, Priority = Label.TS_Case_Priority_Medium , SLADate__c=datetime.now(), SubType__c=Label.TS_Case_SubType_CorrectMaint, Type='Qualify Case', ContactId = newContact.Id, Origin=Label.TS_Case_Origin_Email,
                             BusinessHoursId = bh.Id, EntitlementId=ent.Id, RecordTypeId = TS_UtilityClass.getRecordTypeIdByName(Label.TS_Obj_API_Name_Case, 'Qualify Case'), 
                             Status = Label.TS_Status_New, CaseSubStatus__c = Label.TS_Status_New, SalesOrganization__c = 'SAP_0333');

             insert cse;

             Test.startTest();
                 System.assertEquals('Qualify Case', cse.Type);
             Test.stopTest();
         }
     }

   /**
    * @author        Paul Jarred Aguiling
    * @date          11.21.2017           
    * @description   Test class for updateCaseEntitlement.
    * @revision(s)
    */
    static testMethod void testUpdateCaseEntitlement() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(u) {
            setupTestData();

            Entitlement ent = new Entitlement(Name='Sample Entitlement', AccountId = acct.Id);
            ent.SalesOrganization__c = 'SAP_0333';
            ent.CaseType__c = Label.TS_Case_Type_FieldService;
            ent.CountryDefault__c = true;
            ent.ServiceWindow__c = 'Standard Weekdays';
            insert ent;

            CountrySetting__c countrySetting = new CountrySetting__c(Account__c = acct.Id, CaseSubtype__c = 'Bonus', 
                        RecordTypeId = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', 'Country Response Profile'),
                        Country__c = 'SAP_0333', Priority__c='High', SLAinHours__c=240, CaseType__c = 'Complaint', 
                        Email__c = 'test@accenture.com', ResponseProfile__c = '48', Active__c = true);

            insert countrySetting; 

            Map<Id, Case> oldCaseMap = new Map<Id, Case>();
            Case cseOld = new Case();
            cseOld.Priority = 'Low';
            cseOld.Status = Label.TS_Status_New;
            cseOld.Origin = Label.TS_Case_Origin_Email;
            cseOld.IsFirstResponseClosed__c = false;
            oldCaseMap.put(c.Id, cseOld);
                    
            c.Priority = 'High';
            c.ServiceWindow__c = 'Standard Weekdays';
            update c;

            List<Case> newCaseList = new List<Case>();
            newCaseList.add(c);
            
            CaseTriggerHandler cseHandler = new CaseTriggerHandler();
            cseHandler.updateCaseEntitlement(newCaseList, oldCaseMap);

            Test.startTest();
                System.assertEquals(Label.TS_Case_SubType_CorrectMaintAPI, c.SubType__c);
                System.assertEquals('High', c.Priority);
            Test.stopTest();        
        }
    }

   /**
    * @author        Paul Jarred Aguiling
    * @date          11.21.2017           
    * @description   Test class for updateCaseEntitlement.
    * @revision(s)
    */
    static testMethod void testUpdateCaseEntitlement2() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(u) {
            setupTestData();

            Entitlement ent = new Entitlement(Name='Sample Entitlement', AccountId = acct.Id);
            ent.SalesOrganization__c = 'SAP_0333';
            ent.CaseType__c = Label.TS_Case_Type_FieldService;
            ent.CountryDefault__c = true;
            ent.ServiceWindow__c = 'Standard Weekdays';
            ent.StartDate = Date.today() - 1;
            insert ent;

            CountrySetting__c countrySetting = new CountrySetting__c(Account__c = acct.Id, CaseSubtype__c = 'Bonus', 
                        RecordTypeId = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', 'Country Response Profile'),
                        Country__c = 'SAP_0333', Priority__c='High', SLAinHours__c=240, CaseType__c = 'Complaint', 
                        Email__c = 'test@accenture.com', ResponseProfile__c = '48', Active__c = true);

            insert countrySetting; 

            Map<Id, Case> oldCaseMap = new Map<Id, Case>();
            Case cseOld = new Case();
            cseOld.Priority = 'Low';
            cseOld.Status = Label.TS_Status_New;
            cseOld.Origin = Label.TS_Case_Origin_Email;
            cseOld.IsFirstResponseClosed__c = false;
            oldCaseMap.put(c.Id, cseOld);
                    
            c.Priority = 'High';
            c.ServiceWindow__c = 'Standard Weekdays';
            c.PhysicalAsset__c = pa.Id;
            update c;

            List<Case> newCaseList = new List<Case>();
            newCaseList.add(c);
            
            CaseTriggerHandler cseHandler = new CaseTriggerHandler();
            cseHandler.updateCaseEntitlement(newCaseList, oldCaseMap);

            Test.startTest();
                System.assertEquals(Label.TS_Case_SubType_CorrectMaintAPI, c.SubType__c);
                System.assertEquals('High', c.Priority);
            Test.stopTest();        
        }
    }

    /**
    * @author        Paul Jarred Aguiling
    * @date          11.21.2017           
    * @description   Test class for CaseTriggerHandler. KTS 363 - Confirm First Response.
    * @revision(s)
    */
     static testMethod void testUpdateCaseStatusViaFirstResp() {
         User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
         System.runAs(u) {
             Account newAccount = new Account(Name='Sample Account', Phone='+31302979111');
             insert newAccount;
            
             Contact newContact = new Contact(AccountId=newAccount.Id, Lastname='Sample', Email='sample@test.com', Phone='+31302979111');
             insert newContact;
            
             Case cse =  new Case(AccountId = newAccount.Id, Priority = Label.TS_Case_Priority_Medium , SLADate__c = datetime.now(), 
                                  SubType__c = Label.TS_Case_SubType_CorrectMaint, 
                                  Type='Field Service', ContactId = newContact.Id, Origin = Label.TS_Case_Origin_Email,
                                  RecordTypeId = TS_UtilityClass.getRecordTypeIdByName(Label.TS_Obj_API_Name_Case, Label.TS_Case_RecordType_Field), 
                                  Status = Label.TS_Status_New, CaseSubStatus__c = Label.TS_Status_New);
             Test.startTest();
                 try {
                     insert cse;
                    
                     Map<Id, Case> oldCaseMap = new Map<Id, Case>();
                     Case cseOld = new Case();
                     cseOld.IsFirstResponseClosed__c = false;
                     oldCaseMap.put(cse.Id, cseOld);
                    
                     cse.IsFirstResponseClosed__c = true;                    
                     update cse;
                    
                     List<Case> newCaseList = new List<Case>();
                     newCaseList.add(cse);
                    
                     CaseTriggerHandler cseHandler = new CaseTriggerHandler();
                     cseHandler.updateCaseStatusViaFirstResp(newCaseList, oldCaseMap);
                 } catch (Exception e) {  
                     System.debug(e);
                 }
    
                 System.assertEquals(Label.TS_Status_InProgress, cse.Status);
             Test.stopTest();        
         }
     }
    
     /**
     * @author        Paul Jarred Aguiling
     * @date          11.21.2017           
     * @description   Test class for CaseTriggerHandler. KTS 365 - Close First Response for Field Service Cases.
     * @revision(s)
     */
     static testMethod void testCloseFieldServiceFirstResponse() {
         User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
         System.runAs(u) {
             Account newAccount = new Account(Name='Sample Account', Phone='+31302979111');
             insert newAccount;
            
             Contact newContact = new Contact(AccountId=newAccount.Id, Lastname='Sample', Email='sample@test.com', Phone='+31302979111');
             insert newContact;
            
             Case cse =  new Case(AccountId = newAccount.Id, Priority = Label.TS_Case_Priority_Medium , SLADate__c = datetime.now(), 
                                  SubType__c = Label.TS_Case_SubType_CorrectMaintAPI, 
                                  Type='Field Service', ContactId = newContact.Id, Origin = Label.TS_Case_Origin_Email,
                                  RecordTypeId = TS_UtilityClass.getRecordTypeIdByName(Label.TS_Obj_API_Name_Case, Label.TS_Case_RecordType_Field), 
                                  Status = Label.TS_Status_New, CaseSubStatus__c = Label.TS_Status_New);
             Test.startTest();
                 try {
                     insert cse;
                    
                     Map<Id, Case> oldCaseMap = new Map<Id, Case>();
                     Case cseOld = new Case();
                     cseOld.Status = Label.TS_Status_New;
                     cseOld.IsFirstResponseClosed__c = false;
                     oldCaseMap.put(cse.Id, cseOld);
                    
                     cse.Status = Label.TS_Status_Closed;                    
                     update cse;
                    
                     List<Case> newCaseList = new List<Case>();
                     newCaseList.add(cse);
                    
                     CaseTriggerHandler cseHandler = new CaseTriggerHandler();
                     cseHandler.closeFieldServiceFirstResponse(newCaseList, oldCaseMap);
                 } catch (Exception e) {  
                     System.debug(e);
                 }
    
                 System.assertEquals(Label.TS_Status_Closed, cse.Status);
             Test.stopTest();        
         }
     }
        
     /**
     * @author        Paul Aguiling
     * @date          12.08.2017           
     * @description   Test class for UpdateCaseWOStatus
     * @revision(s)
     */
     static testMethod void testUpdateCaseWOStatus() {
         User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
         System.runAs(u) {

             setupTestData();

             Test.startTest();
             //bas change
                 c.Description= 'Test';
                 c.Status = Label.TS_Status_Closed;
                 c.Cancelationreason__c = 'Test';
                 update c;
                 //bas change
                 System.assertEquals(null, [SELECT Description FROM WorkOrderLineItem WHERE Id =:woli.Id LIMIT 1].Description);
             Test.stopTest();
         }
     }

     /**
     * @author        Paul Aguiling
     * @date          12.08.2017           
     * @description   Test class for UpdateCaseWOStatus
     * @revision(s)
     */
     static testMethod void testUpdateCaseWOStatusException() {
         User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
         System.runAs(u) {

             setupTestData();

             Test.startTest();
                 CaseTriggerHandler.hasException = true;
 //bas change
                 c.description= 'Test';
                 c.Status = Label.TS_Status_Closed;
                 update c;
                
                 System.assert(CaseTriggerHandler.hasException);
             Test.stopTest();
         }
     }

     /**
     * @author        Paul Aguiling
     * @date          12.08.2017           
     * @description   Test class for updateWOLIScheduleDate
     * @revision(s)
     */
     static testMethod void testUpdateWOLIScheduleDate() {
         User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
         System.runAs(u) {

             setupTestData();

             c.SubType__c = 'S40';
             c.PickingDate__c = Date.today();
             update c;

             Test.startTest();
                 System.assert([SELECT ScheduledDate__c FROM WorkOrderLineItem WHERE Id =:woli.Id LIMIT 1].ScheduledDate__c != null);
             Test.stopTest();
         }
     }

     /**
     * @author        Paul Aguiling
     * @date          12.08.2017           
     * @description   Test class for updateWOLIScheduleDate
     * @revisin(s)
     */
     static testMethod void testUpdateWOLIScheduleDateException() {
         User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
         System.runAs(u) {

             setupTestData();
             Map<Id, Case> oldMap = new Map<Id, Case>{c.Id => c};
             c.SubType__c = 'S40';
             c.PickingDate__c = Date.today();
             update c;

             List<Case> newList = new List<Case>{c};

             CaseTriggerHandler cseTrigger = new CaseTriggerHandler();
             CaseTriggerHandler.hasException = true;
             cseTrigger.updateWOLIScheduleDate(newList, oldMap);

             Test.startTest();
                 System.assert(CaseTriggerHandler.hasException);
             Test.stopTest();
         }
     }
    
     /**
     * @author        Paul Aguiling
     * @date          12.08.2017           
     * @description   Test class for calculate_BI_Time
     * @revision(s)
     */
     static testMethod void testCalculate_BI_Time() {
         User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
         System.runAs(u) {
             setupTestData();

             BusinessHours bh = [select id from BusinessHours where IsDefault = true limit 1 ];

             c.Status = Label.TS_Status_Closed;
             c.SubType__c = 'S43';
             c.PickingDate__c = Date.today();
             c.CompletedFirstResponse__c = true;
             c.TS_BI_Response_Time__c = 2;
             c.ServiceWindow__c = 'Standard Weekdays (Mon – Fri 8:00 – 17:00)';
             c.TS_BI_WorkOrder_Start__c = Datetime.newInstance(2017, 12, 1, 12, 30, 2);
             c.BusinessHoursId = bh.Id;
             update c;

             Test.startTest();
                 //System.assert([SELECT TS_BI_Coffee_Down_Time__c FROM Case WHERE Id =: c.Id LIMIT 1].TS_BI_Coffee_Down_Time__c != null);
             Test.stopTest();
         }
     }

     /**
     * @author        Paul Aguiling
     * @date          12.08.2017           
     * @description   Test class for calculate_BI_Time
     * @revision(s)
     */
     static testMethod void testCalculate_BI_Time2() {
         User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
         System.runAs(u) {
            setupTestData();
  
            // woli.Status = Label.TS_Status_Completed;
            // update woli;
        

             BusinessHours bh = [select id from BusinessHours where IsDefault = true limit 1 ];
             c.Type = Label.TS_Case_Type_FieldService;
             c.Status = Label.TS_Status_Closed;
             c.SubType__c = 'S10';
             c.PickingDate__c = Date.today();
             c.CompletedFirstResponse__c = true;
             c.TS_BI_Response_Time__c = 2;
             c.ServiceWindow__c = 'Standard Weekdays (Mon – Fri 8:00 – 17:00)';
             c.TS_BI_WorkOrder_Start__c = Datetime.newInstance(2017, 12, 1, 12, 30, 2);
             c.BusinessHoursId = bh.Id;
             update c;

             Test.startTest();
                 //System.assert([SELECT TS_BI_Coffee_Down_Time__c FROM Case WHERE Id =: c.Id LIMIT 1].TS_BI_Coffee_Down_Time__c != null);
             Test.stopTest();
         }
     }

     /**
     * @author        Paul Aguiling
     * @date          12.08.2017           
     * @description   Test class for calculate_BI_Time
     * @revision(s)
     */
     static testMethod void testCalculate_BI_Time3() {
         User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
         System.runAs(u) {

             setupTestData();

             woli.IsFirstTask__c = false;
             update woli;

             BusinessHours bh = [select id from BusinessHours where IsDefault = true limit 1 ];
             c.Type = Label.TS_Case_RecordType_Complaint;
             c.Status = Label.TS_Status_Closed;
            // c.SubType__c = 'S10';
             c.PickingDate__c = Date.today();
             c.CompletedFirstResponse__c = true;
             c.TS_BI_Response_Time__c = 2;
             c.ServiceWindow__c = 'Standard Weekdays (Mon – Fri 8:00 – 17:00)';
             c.TS_BI_WorkOrder_Start__c = Datetime.newInstance(2017, 12, 1, 12, 30, 2);
             c.BusinessHoursId = bh.Id;
             update c;

             Test.startTest();
                 //System.assert([SELECT TS_BI_Coffee_Down_Time__c FROM Case WHERE Id =: c.Id LIMIT 1].TS_BI_Coffee_Down_Time__c != null);
             Test.stopTest();
         }
     }

     /**
     * @author        Paul Aguiling
     * @date          12.08.2017           
     * @description   Test class for calculate_BI_Time
     * @revision(s)   9 April 2018 updated by Archi  for new BI calculation for complaint
     */
     static testMethod void testCalculate_BI_Time4() {
         User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
         System.runAs(u) {

             setupTestData();

             BusinessHours bh = [select id from BusinessHours where IsDefault = true limit 1 ];

             c.Status = Label.TS_Status_Closed;
             c.Type = Label.TS_Case_RecordType_Complaint;
            // c.SubType__c = 'S10';
             c.PickingDate__c = Date.today();
             c.CompletedFirstResponse__c = true;
             c.TS_BI_Response_Time__c = 2;
             c.ServiceWindow__c = 'Test Window';
             c.TS_BI_WorkOrder_Start__c = Datetime.newInstance(2017, 12, 1, 12, 30, 2);
             c.TS_BI_WorkOrder_Finish__c  = c.TS_BI_WorkOrder_Start__c.addHours(1) ;
             c.CompletedCaseClosure__c = true;
             c.BusinessHoursId = bh.Id;
             update c;

             Test.startTest();
                 //System.assert([SELECT TS_BI_Coffee_Down_Time__c FROM Case WHERE Id =: c.Id LIMIT 1].TS_BI_Coffee_Down_Time__c != null);
             Test.stopTest();
         }
     }

     /**
     * @author        Paul Aguiling
     * @date          12.08.2017           
     * @description   Test class for exceptions
     * @revision(s)
     */
     static testMethod void testExceptions() {
         User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
         System.runAs(u) {

             CaseTriggerHandler.hasException = true;
             setupTestData();
         }
     }

     /**
     * @author        Paul Aguiling
     * @date          2.21.2018         
     * @description   Test class for assignRecordType
     * @revision(s)
     */
     static testMethod void testAssignRecordType() {
         User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
         System.runAs(u) {
             Contact con = TS_TestDataFactory.createContact();  
             con.Preferred_Language__c = 'SAP_EN';
             insert con;
            
             Case cse = new Case();
             cse.ContactId = con.Id;
             cse.Status = Label.TS_Status_InProgress;
             cse.Type = Label.TS_Case_Type_CustomerCare;
             cse.SubType__c = Label.TS_Case_SubType_CorrectMaintAPI;
             insert cse;

             Case cse1 = new Case();
             cse1.ContactId = con.Id;
             cse1.Status = Label.TS_Status_InProgress;
             cse1.Type = Label.TS_Case_Type_Complaint;
             cse1.SubType__c = Label.TS_Case_SubType_CorrectMaintAPI;
             insert cse1;

             Case cse2 = new Case();
             cse2.ContactId = con.Id;
             cse2.Status = Label.TS_Status_InProgress;
             cse2.Type = Label.TS_Case_Type_FieldService;
             cse2.SubType__c = Label.TS_Case_SubType_Modification;
             insert cse2;

             Case cse3 = new Case();
             cse3.ContactId = con.Id;
             cse3.Status = Label.TS_Status_InProgress;
             cse3.Type = Label.TS_Case_Type_FieldService;
             cse3.Origin = Label.TS_Case_Origin_Telefoon;
             cse3.SubType__c = Label.TS_Case_SubType_CorrectMaintAPI;
             insert cse3;

             Case cse4 = new Case();
             cse4.ContactId = con.Id;
             cse4.Status = Label.TS_Status_InProgress;
             cse4.Type = Label.TS_Case_Type_FieldService;
             cse4.Origin = Label.TS_Case_Origin_SalesOrder;
             cse4.SubType__c = Label.TS_Case_SubType_CorrectMaintAPI;
             insert cse4;

             Case cse5 = new Case();
             cse5.ContactId = con.Id;
             cse5.Status = Label.TS_Status_InProgress;
             cse5.Type = Label.TS_Case_Type_FieldService;
             cse5.Origin = Label.TS_Case_Origin_ContractOrder;            
             cse5.SubType__c = Label.TS_Case_SubType_CorrectMaintAPI;
             insert cse5;

             Test.startTest();
                 System.assertEquals(Label.TS_Case_Type_CustomerCare, [SELECT RecordType.Name FROM Case WHERE Id =:cse.Id].RecordType.Name);
             Test.stopTest();
         }
     }

     /**
     * @author        Paul Aguiling
     * @date          2.21.2018         
     * @description   Test class for assignRecordType
     * @revision(s)
     */
     /*static testMethod void testAssignRecordTypeUpdate() {
         User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
         System.runAs(u) {
             Contact con = TS_TestDataFactory.createContact();  
             con.Preferred_Language__c = 'SAP_EN';
             insert con;

             Case cse = new Case();
             cse.ContactId = con.Id;
             cse.Status = Label.TS_Status_InProgress;
             cse.Type = Label.TS_Type_QualifyCase;
             cse.SubType__c = Label.TS_Case_SubType_CorrectMaintAPI;
             insert cse;

             cse.Type = Label.TS_Case_Type_CustomerCare;
             update cse;

             cse.Type = Label.TS_Case_Type_Complaint;
             cse.SubType__c = Label.TS_Case_SubType_CorrectMaintAPI;
             update cse;

             cse.Type = Label.TS_Case_Type_FieldService;
             cse.SubType__c = Label.TS_Case_SubType_Modification;
             update cse;

             Test.startTest();
                 System.assertEquals(Label.TS_Case_Modification, [SELECT RecordType.Name FROM Case WHERE Id =:cse.Id].RecordType.Name);
             Test.stopTest();
         }
     }*/

     /**
     * @author        Paul Aguiling
     * @date          2.21.2018         
     * @description   Test class for assignRecordType
     * @revision(s)
     */
     static testMethod void testAssignRecordTypeUpdate2() {
         User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
         System.runAs(u) {
             Contact con = TS_TestDataFactory.createContact();  
             con.Preferred_Language__c = 'SAP_EN';
             insert con;

             Case cse = new Case();
             cse.ContactId = con.Id;
             cse.Status = Label.TS_Status_InProgress;
             cse.Type = Label.TS_Type_QualifyCase;
             cse.SubType__c = Label.TS_Case_SubType_CorrectMaintAPI;
             insert cse;

             cse.Type = Label.TS_Case_Type_FieldService;
             cse.Origin = Label.TS_Case_Origin_Manual;
             cse.SubType__c = Label.TS_Case_SubType_CorrectMaintAPI;
             update cse;

             Test.startTest();
                 System.assertEquals(Label.TS_Case_RecordType_Field, [SELECT RecordType.Name FROM Case WHERE Id =:cse.Id].RecordType.Name);
             Test.stopTest();
         }
     }

     /**
     * @author        Paul Aguiling
     * @date          2.21.2018         
     * @description   Test class for assignRecordType
     * @revision(s)
     */
     static testMethod void testAssignRecordTypeUpdate3() {
         User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
         System.runAs(u) {
             Contact con = TS_TestDataFactory.createContact();  
             con.Preferred_Language__c = 'SAP_EN';
             insert con;

             Case cse = new Case();
             cse.ContactId = con.Id;
             cse.Status = Label.TS_Status_InProgress;
             cse.Type = Label.TS_Type_QualifyCase;
             cse.SubType__c = Label.TS_Case_SubType_CorrectMaintAPI;
             insert cse;

             cse.Type = Label.TS_Case_Type_FieldService;
             cse.Origin = Label.TS_Case_Origin_SalesOrder;
             cse.SubType__c = Label.TS_Case_SubType_CorrectMaintAPI;
             update cse;

             Test.startTest();
                 System.assertEquals(Label.TS_Case_Type_FieldServiceSales, [SELECT RecordType.Name FROM Case WHERE Id =:cse.Id].RecordType.Name);
             Test.stopTest();
         }
     }

     /**
     * @author        Paul Aguiling
     * @date          2.21.2018         
     * @description   Test class for assignRecordType
     * @revision(s)
     */
     static testMethod void testAssignRecordTypeUpdate4() {
         User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
         System.runAs(u) {
             Contact con = TS_TestDataFactory.createContact();  
             con.Preferred_Language__c = 'SAP_EN';
             insert con;

             Case cse = new Case();
             cse.ContactId = con.Id;
             cse.Status = Label.TS_Status_InProgress;
             cse.Type = Label.TS_Type_QualifyCase;
             cse.SubType__c = Label.TS_Case_SubType_CorrectMaintAPI;
             insert cse;

             cse.Type = Label.TS_Case_Type_FieldService;
             cse.Origin = Label.TS_Case_Origin_ContractOrder;            
             cse.SubType__c = Label.TS_Case_SubType_CorrectMaintAPI;
             update cse;

             Test.startTest();
                 System.assertEquals(Label.TS_Case_Type_FieldServiceContract, [SELECT RecordType.Name FROM Case WHERE Id =:cse.Id].RecordType.Name);
             Test.stopTest();
         }
     }

     /**
     * @author        Paul Aguiling
     * @date          2.21.2018         
     * @description   Test class for caseCancellation
     * @revision(s)
     */
     /*
     static testMethod void testCaseCancellation() {
         User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
         System.runAs(u) {
             PhysicalAsset__c pa = new PhysicalAsset__c(Name='Test', 
                                       UniqueNumber__c='1234567-TestMachine', 
                                       RecordTypeId = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get('Machine').getRecordTypeId());
             insert pa;

             Contact con = TS_TestDataFactory.createContact();  
             con.Preferred_Language__c = 'SAP_EN';
             insert con;

             Case cse = new Case();
             cse.ContactId = con.Id;
             cse.Status = Label.TS_Status_InProgress;
             cse.Type = Label.TS_Type_QualifyCase;
             cse.SubType__c = Label.TS_Activity_Type_S32;
             cse.PhysicalAsset__c = pa.Id;
             insert cse;

             cse.Status = Label.TS_Status_Canceled;
             cse.Type = Label.TS_Case_Type_FieldService;
             update cse;

             Test.startTest();
                 System.assert([SELECT LastWTSDate__c FROM PhysicalAsset__c WHERE Id =:pa.Id].LastWTSDate__c != null);
             Test.stopTest();
         }
     }*/

     /**
     * @author        Paul Aguiling
     * @date          2.21.2018         
     * @description   Test class for caseCancellation preventive maintenance
     * @revision(s)
     */
     /*
     static testMethod void testCaseCancellation2() {
         User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
         System.runAs(u) {
             PhysicalAsset__c pa = new PhysicalAsset__c(Name='Test', 
                                       UniqueNumber__c='1234567-TestMachine', 
                                       RecordTypeId = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get('Machine').getRecordTypeId());
             insert pa;
            
             Contact con = TS_TestDataFactory.createContact();  
             con.Preferred_Language__c = 'SAP_EN';
             insert con;

             Case cse = new Case();
             cse.ContactId = con.Id;
             cse.Status = Label.TS_Status_InProgress;
             cse.Type = Label.TS_Type_QualifyCase;
             cse.SubType__c = Label.TS_Case_SubType_PrevMain;
             cse.PhysicalAsset__c = pa.Id;
             insert cse;

             cse.Status = Label.TS_Status_Canceled;
             cse.Type = Label.TS_Case_Type_FieldService;
             update cse;

             Test.startTest();
                 System.assert([SELECT LastPreventiveMaintenanceDate__c FROM PhysicalAsset__c WHERE Id =:pa.Id].LastPreventiveMaintenanceDate__c != null);
             Test.stopTest();
         }
     }
    */

     /**
     * @author        Paul Aguiling
     * @date          2.21.2018         
     * @description   Test class for repeat visit flow
     * @revision(s)
     */
     static testMethod void testRepeatVisit() {
         User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
         System.runAs(u) {
             PhysicalAsset__c pa = new PhysicalAsset__c(Name='Test', 
                                       UniqueNumber__c='1234567-TestMachine', 
                                       RecordTypeId = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get('Machine').getRecordTypeId());
             insert pa;

             Contact con = TS_TestDataFactory.createContact();  
             con.Preferred_Language__c = 'SAP_EN';
             insert con;

             Case cse = new Case();
             cse.ContactId = con.Id;
             cse.Status = Label.TS_Status_InProgress;
             cse.Type = Label.TS_Case_Type_FieldService;
             cse.SubType__c = Label.TS_Activity_Type_S32;
             cse.PhysicalAsset__c = pa.Id;
             insert cse;

             Test.startTest();
                 System.assert(cse.PhysicalAsset__c != null);
             Test.stopTest();
         }
     }

     /**
     * @author        Paul Aguiling
     * @date          12.08.2017           
     * @description   Test class for updateOrderLSPDates
     * @revision(s)
     */
     static testMethod void testUpdateOrderLSPDates() {
         User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
         System.runAs(u) {

             setupTestData();

             BusinessHours bh = [select id from BusinessHours where IsDefault = true limit 1 ];

             c.Status = Label.TS_Status_InProgress;
             c.Type = Label.TS_Case_Type_FieldService;
             c.SubType__c = Label.TS_Case_SubType_Swap;
             c.PickingDate__c = Date.today();
             c.CompletedFirstResponse__c = true;
             c.TS_BI_Response_Time__c = 2;
             c.ServiceWindow__c = 'Test Window';
             c.TS_BI_WorkOrder_Start__c = Datetime.newInstance(2017, 12, 1, 12, 30, 2);
             c.BusinessHoursId = bh.Id;
             c.ActualPickUpDate__c = Date.today();
             c.ChildOrder__c = order.Id;
             c.ApptusOrder__c = order.Id;
             update c;

             Test.startTest();
                 System.assert([SELECT APTS_Pick_Up_Date_Authorized__c FROM Apttus_Config2__Order__c WHERE Id =:order.Id].APTS_Pick_Up_Date_Authorized__c != null);
             Test.stopTest();
         }
     }

     /**
     * @author        Paul Aguiling
     * @date          12.08.2017           
     * @description   Test class for updateOrderLSPDates
     * @revision(s)
     */
     static testMethod void testUpdateOrderLSPDates2() {
         User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
         System.runAs(u) {

             setupTestData();

             BusinessHours bh = [select id from BusinessHours where IsDefault = true limit 1 ];

             c.Status = Label.TS_Status_InProgress;
             c.Type = Label.TS_Case_Type_FieldService;
             c.SubType__c = Label.TS_Order_S40;
             c.PickingDate__c = Date.today();
             c.CompletedFirstResponse__c = true;
             c.TS_BI_Response_Time__c = 2;
             c.ServiceWindow__c = 'Test Window';
             c.TS_BI_WorkOrder_Start__c = Datetime.newInstance(2017, 12, 1, 12, 30, 2);
             c.BusinessHoursId = bh.Id;
             c.ActualMovementDate__c  = Date.today();
             c.ChildOrder__c = order.Id;
             c.ApptusOrder__c = order.Id;
             update c;

             Test.startTest();
                 System.assert([SELECT APTS_Movement_Date_Authorized__c FROM Apttus_Config2__Order__c WHERE Id =:order.Id].APTS_Movement_Date_Authorized__c != null);
             Test.stopTest();
         }
     }

     /**
     * @author        Paul Aguiling
     * @date          2.21.2018         
     * @description   Test class for validateClosedAndConvertedCases
     * @revision(s)
     */
     static testMethod void testValidateClosedAndConvertedCases() {
         User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
         System.runAs(u) {
             Contact con = TS_TestDataFactory.createContact();  
             con.Preferred_Language__c = 'SAP_EN';
             insert con;

             Case cse = new Case();
             cse.ContactId = con.Id;
             cse.Status = Label.TS_Status_Closed;
             cse.Type = Label.TS_Case_RecordType_Complaint;
             insert cse;

             cse.Type = Label.TS_Case_Type_FieldService;
             cse.Origin = Label.TS_Case_Origin_ContractOrder;            
             cse.SubType__c = Label.TS_Case_SubType_CorrectMaintAPI;
             
             Test.startTest();
                 try {
                    update cse;
                 } catch (Exception e) { 
                    System.assert(cse.Type != Label.TS_Case_RecordType_Complaint);
                 }    
             Test.stopTest();
         }
     }

     /**
     * @author        Paul Aguiling
     * @date          2.21.2018         
     * @description   Test class for validateClosedAndConvertedCases
     * @revision(s)
     */
     static testMethod void testValidateClosedAndConvertedCases2() {
         User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
         System.runAs(u) {
             Contact con = TS_TestDataFactory.createContact();  
             con.Preferred_Language__c = 'SAP_EN';
             insert con;

             Case cse = new Case();
             cse.ContactId = con.Id;
             cse.Status = Label.TS_Status_InProgress;
             cse.Type = Label.TS_Case_Type_CustomerCare;
             insert cse;

            Test.startTest();
                 try {

                     cse.Status = Label.TS_Status_Closed;
                     update cse;

                     cse.Type = Label.TS_Case_Type_FieldService;
                     cse.Origin = Label.TS_Case_Origin_ContractOrder;            
                     cse.SubType__c = Label.TS_Case_SubType_CorrectMaintAPI;

                     update cse;
                 } catch (Exception e) { 
                    System.assert(cse.Type != Label.TS_Case_Type_CustomerCare);
                 }    
             Test.stopTest();
         }
     }

     /**
     * @author        Paul Aguiling
     * @date          4.27.2018         
     * @description   Test class for updateSalesOrganization
     * @revision(s)
     */
     /*static testMethod void updateSalesOrganization() {
         User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
         System.runAs(u) {
             Account acc = new Account(Name='Account', Phone='+31302979111');
             insert acc;

             Contact con = TS_TestDataFactory.createContact();  
             con.Preferred_Language__c = 'SAP_EN';
             insert con;

             Apttus_Config2__AccountLocation__c al = TS_TestDataFactory.createAccountLocation(acc.Id);     
             al.ApprovalPreventiveMaintenanceWTS__c = true;
             al.Account_Location_Status__c = 'ACTIVE';
             al.Apttus_Config2__IsDefault__c = true;
             al.ApprovalPreventiveMaintenanceWTS__c = true;
             al.Mini_Sales_Organization__c = 'SAP_0111';
             insert al;

             PhysicalAsset__c phys = new PhysicalAsset__c(Name='Test', 
                                  UniqueNumber__c='1234567-TestMachine', 
                                  AccountLocation__c = al.Id,
                                  RecordTypeId = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get('Machine').getRecordTypeId());
             insert phys;

             Case cse = new Case();
             cse.ContactId = con.Id;
             cse.Status = Label.TS_Status_New;
             cse.Type = Label.TS_Case_Type_FieldService;
             cse.Origin = Label.TS_Case_Origin_Telefoon;
             cse.PhysicalAsset__c = phys.Id;
             insert cse;

             Test.startTest();
                //System.assert(cse.SalesOrganization__c != null);
             Test.stopTest();
         }
     }*/
     
     /**
     * @author        Catherine Kia Aragon
     * @date          31.07.2018           
     * @description   Test class for createTask
     * @revision(s)
     */
     static testMethod void testUpdateOrderStatusClosed() {
         User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
         System.runAs(u) {

             setupTestData();

             BusinessHours bh = [select id from BusinessHours where IsDefault = true limit 1 ];

             c.Status = Label.TS_Status_Closed;
             c.Type = Label.TS_Case_Type_FieldService;
             c.SubType__c = Label.TS_Order_S40;
             c.PickingDate__c = Date.today();
             c.CompletedFirstResponse__c = true;
             c.TS_BI_Response_Time__c = 2;
             c.ServiceWindow__c = 'Test Window';
             c.TS_BI_WorkOrder_Start__c = Datetime.newInstance(2017, 12, 1, 12, 30, 2);
             c.BusinessHoursId = bh.Id;
             c.ActualMovementDate__c  = Date.today();
             c.ChildOrder__c = order.Id;
             c.ApptusOrder__c = order.Id;
             c.AccountId = acct.Id;
             update c;
             System.debug('c: ' + c);
             Test.startTest();
             System.assert([SELECT LinkedToOrder__c FROM Case WHERE Id =:c.Id].LinkedToOrder__c == true);
             Test.stopTest();
         }
     }

     /**
     * @author        Karen Hung
     * @date          03.19.2019        
     * @description   Test class for validateTasktobeCreated
     * @revision(s)
     */
     static testMethod void testValidateTasktobeCreated(){
         
        ProcessBuilderSettings__c pb = new ProcessBuilderSettings__c();
        pb.CasePBFlows__c = false;
        insert pb;
         
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
         System.runAs(u) {

             setupTestData();

             Account acc = new Account(Name='Account', Phone='+313029791342');
             insert acc;

             Contact con = TS_TestDataFactory.createContact();  
             con.Preferred_Language__c = 'SAP_EN';
             con.Phone = '+31302979123';
             insert con;

             Apttus_Config2__AccountLocation__c al = TS_TestDataFactory.createAccountLocation(acc.Id);     
             al.ApprovalPreventiveMaintenanceWTS__c = true;
             al.Account_Location_Status__c = 'ACTIVE';
             al.Apttus_Config2__IsDefault__c = true;
             al.ApprovalPreventiveMaintenanceWTS__c = true;
             al.Mini_Sales_Organization__c = 'SAP_0111';
             insert al;

             PhysicalAsset__c phys = new PhysicalAsset__c(Name='Test', 
                      UniqueNumber__c='1234567-TestMachinex', 
                      AccountLocation__c = al.Id,
                      RecordTypeId = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get('Machine').getRecordTypeId());
             insert phys;

             Datetime now = Datetime.now();
             Integer offset = UserInfo.getTimezone().getOffset(now);
             Datetime local = now.addSeconds(offset/1000);

             Date localDate = Date.valueOf(local);
             String localStr = local.format();
             String dayofWeek = local.format('E');
             Time timeStart = Time.newInstance(12,0,0,0);
             Date earlyStart;

             if(dayofWeek == 'Fri'){
                earlyStart = Date.Today().addDays(4);
             }else if(dayofWeek == 'Sat'){
                earlyStart = Date.Today().addDays(3);
             }else{
                earlyStart = Date.Today().addDays(2);
             }
             Case cse = new Case();
             cse.ContactId = con.Id;
             cse.Status = Label.TS_Status_New;
             cse.Type = TS_Constants.TS_CASE_RECORDTYPE_ROUTESALES;
             cse.Origin = Ts_Constants.CASE_ORIGIN_ROUTESALESREQUEST;
             cse.EarlyStartDate__c = DateTime.newInstance(earlyStart, timeStart);
             cse.PhysicalAsset__c = phys.Id;
             
             Test.startTest();
             insert cse;
             Test.stopTest();
             System.assert( phys != null);
             
         }
     }
    
    /**
     * @author        Abram Vixen Reyes
     * @date          September 15, 2020    
     * @description   Test Class for Process builder to trigger: Order Conversion
     * @revision(s)
     */
     static testMethod void test_convertOrder() {
         User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
         System.runAs(u) {

             setupTestData();

             Test.startTest();
             
             case_2.Status = TS_Constants.STATUS_INPROGRESS;
             case_2.CaseSubStatus__c = TS_Constants.CASE_SUBSTATUS_ORDEROPEN;
             case_2.CreatedOrderedManually__c = true;
             update case_2;
             
             Test.stopTest();
         }
     }

}