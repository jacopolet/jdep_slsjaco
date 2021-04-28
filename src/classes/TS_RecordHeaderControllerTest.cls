/**
* @author        Rey Austral
* @date          10.2.2017           
* @description   Test Class for TS_RecordHeaderController
* @revision(s)
*/
@isTest
public class TS_RecordHeaderControllerTest {
    
    @testSetup static void dataSetup() {        
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
        insert alocation;
        
        // Instantiate the Pricebook2 record first, setting the Id
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        
        // Run an update DML on the Pricebook2 record
        // This is the weird workaround that enables IsStandard to become true
        // on the PricebookEntry record
        update standardPricebook;
        
        Pricebook2 standardPB = [SELECT Id FROM Pricebook2 WHERE isStandard = true];
        
        Product2 prod = TS_TestDataFactory.createProduct('name','family');
        prod.ProductCode = 'prod';
        insert prod;
        
        Pricebook2 pb = new pricebook2(Name='test', IsActive = true, Sales_Organization__c = 'SAP_0333');
        insert pb;
        
        Pricebook2 pb2 = new pricebook2(Name='test2', IsActive = true, Sales_Organization__c = 'SAP_0111');
        insert pb2;
        
        PricebookEntry standardPrice = new PricebookEntry(Pricebook2Id = standardPB.Id, Product2Id = prod.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
        insert standardPrice;
        
        PricebookEntry newProduct = new PricebookEntry (Pricebook2Id = pb2.id, Product2Id = prod.id, IsActive=true, UseStandardPrice = false, UnitPrice=100.0);
        insert newProduct;
        
        PhysicalAsset__c testAsset = new PhysicalAsset__c();
        testAsset.RecordTypeId = TS_UtilityClass.getRecordTypeIdByName('PhysicalAsset__c', 'Machine');
        testAsset.Name = 'Test Asset';
        testAsset.UniqueNumber__c = '1234567890';
        testAsset.AccountLocation__c = alocation.Id;
        insert testAsset;
        
        ProcessBuilderSettings__c pbTest = new ProcessBuilderSettings__c();
        pbTest.CasePBFlows__c = true;
        insert pbTest;
        
        Case cseData = TS_TestDataFactory.createFieldServiceCase();
        cseData.AccountId = accountList[0].Id;
        cseData.ContactId = con.Id;       
        cseData.SalesOrganization__c = 'SAP_0111';
        cseData.Subject = 'Bas';
        cseData.Description = 'Bas';
        cseData.Priority = 'Medium';
        cseData.PhysicalAsset__c = testAsset.Id;
        cseData.SLADate__c = System.now() + 7;
        insert cseData;
    }
    
    @isTest static void test_FollowFunction() {
        
        Case cse = [SELECT Id, Subject FROM Case WHERE Subject = 'Bas' LIMIT 1];
        Test.startTest();
        
        TS_RecordHeaderController.hasException = true;
        
        Boolean checkIfFollowing = TS_RecordHeaderController.isFollowingCheck(cse.Id);
        System.assertEquals(false, checkIfFollowing);
        
        TS_RecordHeaderController.followRecord(cse.Id);
        checkIfFollowing = TS_RecordHeaderController.isFollowingCheck(cse.Id);
        System.assertEquals(true, checkIfFollowing);
        
        TS_RecordHeaderController.unfollowRecord(cse.Id);
        checkIfFollowing = TS_RecordHeaderController.isFollowingCheck(cse.Id);
        System.assertEquals(false, checkIfFollowing);
        
        TS_RecordHeaderController.getCaseAccess(cse.Id);
        
        Test.stopTest();
    }
    
    @isTest static void test_InsertComment() {
        
        Case cse = [SELECT Id, Subject FROM Case WHERE Subject = 'Bas' LIMIT 1];
        Test.startTest();
        TS_RecordHeaderController.insertComments(cse.Id, 'Test Comment');
        Test.stopTest();
        
        List<CaseComment> ccList = [Select id from CaseComment where ParentId =: cse.Id];
        System.assertEquals(1, ccList.size());
    }
    
    @isTest static void test_getRecordTypeAndUser() {
        
        Case cse = [SELECT Id, Subject FROM Case WHERE Subject = 'Bas' LIMIT 1];
        Test.startTest();		
        String recordName = TS_RecordHeaderController.getRecordType(cse.Id);
        String loginName = TS_RecordHeaderController.currentUserId();
        String accessCheck = TS_RecordHeaderController.checkButtonAccess();
        Test.stopTest();
        System.assertNotEquals('', recordName);
        System.assertNotEquals('', loginName);
        System.assertNotEquals('', accessCheck);
    }
    
    @isTest static void test_getRecordTypeIds() {
        Test.startTest();		
        String fieldService = TS_RecordHeaderController.getRecordTypeFS();
        String caseRegistration = TS_RecordHeaderController.getRecordTypeCR();
        String serviceJob = TS_RecordHeaderController.getRecordTypeAS();
        String inboundTask = TS_RecordHeaderController.getRecordTypeInboundTask();
        String addServiceJob = TS_RecordHeaderController.getRecordTypeGeneric('WorkOrderLineItem', 'Register Task');
        Test.stopTest();
        
        System.assertNotEquals('', fieldService);
        System.assertNotEquals('', caseRegistration);
        System.assertNotEquals('', serviceJob);
        System.assertNotEquals('', inboundTask);
        System.assertNotEquals('', addServiceJob);
    }
    
    @isTest static void test_createOrderClass() {
        
        Id taskId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Register Task').getRecordTypeId();
        Id partsId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Register Required Part').getRecordTypeId();
        
        Case cse = [SELECT Id, Subject, Status, CaseSubStatus__c, CreatedOrderedManually__c, RecordTypeId FROM Case WHERE Subject = 'Bas' LIMIT 1];
        
        TriggerSettings__c trg = TriggerSettings__c.getOrgDefaults();
        trg.CaseTrigger__c = true;
        upsert trg; 
        
        Case qCase = TS_RecordHeaderController.queryCase(cse.Id);
        
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        TS_RecordHeaderController.executeTakeOwnership(cse.Id, u.Id, 'New');
        TS_RecordHeaderController.changeOwner(cse.Id, u.Id);
        
        String orderResult = TS_RecordHeaderController.createOrderClass(cse.Id);
        System.assertEquals('SUCCESS', orderResult);
        
        Case cseUpdated = [SELECT Id, Subject, Status, CaseSubStatus__c, CreatedOrderedManually__c, SLADate__c, RecordTypeId FROM Case WHERE Id =: cse.Id LIMIT 1];
        System.assertEquals('In progress', cseUpdated.Status);
        System.assertEquals('Order Open', cseUpdated.CaseSubStatus__c);
        System.assertEquals(true, cseUpdated.CreatedOrderedManually__c);
        
        TS_RecordHeaderController.counters(cseUpdated.Id);
        //System.assertEquals(1, count);
        
        Test.startTest();
        
        WorkOrder wo = TS_RecordHeaderController.getFirstWOinCase(cseUpdated.Id);
        
        String getSLADate = TS_RecordHeaderController.getCorrectSLADate(cseUpdated);
        
        List<WorkOrderLineItem> openTaskList = TS_RecordHeaderController.getOpenTasks(cseUpdated.Id);
        TS_RecordHeaderController.getScheduledAndOpenTasks(cseUpdated.Id, false);
        
        //Test Search WOLI via JDELineItemNumber__c - Jan. 21, 2019 Xen Reyes
        List<WorkOrderLineItem> searchRes = TS_RecordHeaderController.getWorkOrderLineItemSearch(openTaskList[0].JDELineItemNumber__c);
        String getInfo = TS_RecordHeaderController.getInfoForTask();
        String inboundRecordTypeId = TS_RecordHeaderController.getRecordTypeInboundTask();
        
        WorkOrderLineItem toBeScheduled = openTaskList[0];
        toBeScheduled.Status = 'Scheduled';
        update toBeScheduled;
        
        List<WorkOrderLineItem> scheduled = TS_RecordHeaderController.getScheduledTasks(cseUpdated.Id, false);
        System.assertEquals(1, scheduled.size());
        
        Product2 prod = [SELECT Id FROM Product2 WHERE ProductCode = 'prod'];
        Pricebook2 pbook = [SELECT Id FROM Pricebook2 WHERE Name = 'test2'];
        PricebookEntry prodAsset = [SELECT Id FROM PricebookEntry WHERE Pricebook2Id =: pbook.Id AND Product2Id =: prod.Id];
        
        WorkOrderLineItem newRequiredPart = new WorkOrderLineItem();
        newRequiredPart.RecordTypeId = partsId;
        newRequiredPart.WorkOrderId = wo.Id;
        newRequiredPart.Case__c = cseUpdated.Id;
        newRequiredPart.WorkOrderLineItemType__c = 'RequiredSpareparts';
        newRequiredPart.ParentWorkOrderLineItemId = toBeScheduled.Id;
        newRequiredPart.Quantity = 1;
        newRequiredPart.PricebookEntryId = prodAsset.Id;
        insert newRequiredPart;
        
        String updateParts = TS_RecordHeaderController.updateRequiredParts(new List<String>{newRequiredPart.Id});
        System.assertEquals('SUCCESS', updateParts);
        
        List<WorkOrderLineItem> getReqs = TS_RecordHeaderController.getReqParts(cseUpdated.Id);
        
        TS_RecordHeaderController.AddServiceWrapper add = TS_RecordHeaderController.queryAddService(cseUpdated.Id, prod.Id);
        
        WorkOrderLineItem schTask = scheduled[0];
        String reschedule = TS_RecordHeaderController.rescheduleApppointment(cseUpdated.Id, new List<String>{schTask.Id}, System.now() + 1 , System.now() + 3);
        
        schTask.Status = 'Open';
        update schTask;
        
        Resource__c res = [SELECT Id FROM Resource__c WHERE Name = 'Test Resource Number' LIMIT 1];
        String schedOpen = TS_RecordHeaderController.scheduleOpenTask(System.now() + 1, System.now() + 5, res.Id, false, new List<String>{schTask.Id});
        //System.assertEquals('SUCCESS', schedOpen);
        
        Test.stopTest();
    }
    
    @isTest static void test_getCaseRecord() {
        
        Case cse = [SELECT Id, Subject FROM Case WHERE Subject = 'Bas' LIMIT 1];
        Test.startTest();
        Case cse2 = TS_RecordHeaderController.getCaseRecord(cse.Id);
        System.assertEquals(cse.Id, cse2.Id);
        Test.stopTest();
    }
    
    @isTest static void test_getObjectTypeOfRecord() {
        
        Case cse = [SELECT Id, Subject FROM Case WHERE Subject = 'Bas' LIMIT 1];
        Test.startTest();
        String objType = TS_RecordHeaderController.getObjectTypeOfRecord(cse.Id);
        System.assertEquals('Case', objType);
        Test.stopTest();
    }
    
    @isTest static void test_picklistValues() {
        
        Test.startTest();
        Map<String, String> getMapPL = TS_RecordHeaderController.getPicklistValuesMap('Case', 'Type');
        Map<String, List<String>> getMapListPL = TS_RecordHeaderController.getPLvalueOption2('Case', 'Type', 'SubType__c');
        Map<String,TS_PicklistEntryWrapper> getMapListPL2 = TS_RecordHeaderController.getPLvalueOption3('Case', 'Type', 'SubType__c');
        Map<String, TS_PicklistEntryWrapper> getValues = TS_RecordHeaderController.getDependentValue('Case', 'Type', 'SubType__c');
        Test.stopTest();
    }
    
    @isTest static void test_Exception() {
        
        Case cse = [SELECT Id, Subject, Status, CaseSubStatus__c, CreatedOrderedManually__c, RecordTypeId FROM Case WHERE Subject = 'Bas' LIMIT 1];
        
        Test.startTest();
        
        TS_RecordHeaderController.hasException = true;
        
        String orderResult = TS_RecordHeaderController.createOrderClass(cse.Id);
        String recordName = TS_RecordHeaderController.getRecordType(cse.Id);
        Case csTest = TS_RecordHeaderController.getCaseRecord(cse.Id);
        
        //System.assertEquals('Force to throw an exception', orderResult);
        
        /* String recordName = TS_RecordHeaderController.getRecordType(cse.Id);
		System.assertEquals('Force to throw an exception', recordName); */
        
        Test.stopTest();
    }
    
}