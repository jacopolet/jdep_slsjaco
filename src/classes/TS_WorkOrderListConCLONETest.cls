/*
* @author        Karen Hung
* @date          20.06.2019
* @description   Test class for TS_WorkOrderListMobileControllerCLONE
*/
@isTest
public with sharing class TS_WorkOrderListConCLONETest {
    
    @testSetup static void dataSetup() {
        
        TriggerSettings__c trg = TriggerSettings__c.getOrgDefaults();
        trg.CaseTrigger__c = true;
        upsert trg; 
        
		Contact con = TS_TestDataFactory.createContact();  
        con.Preferred_Language__c = 'SAP_EN';
        Insert con;
        
        Resource__c testResource = TS_TestDataFactory.createResourceSingle('Test Resource Number');
        testResource.RelatedUser__c = UserInfo.getUserId();
        testResource.TeamNumber__c = '12345';
        insert testResource;
        
        Resource__c testResource2 = TS_TestDataFactory.createResourceSingle('445667775');
        testResource2.TeamNumber__c = '12345';
        insert testResource2;

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
        cseData.Subject = 'Xen';
        cseData.Description = 'Bas';
        cseData.Priority = 'Medium';
        cseData.PhysicalAsset__c = testAsset.Id;
        cseData.SLADate__c = System.now() + 7;
        insert cseData;
        
        Case cseData2 = TS_TestDataFactory.createFieldServiceCase();
        cseData2.AccountId = accountList[0].Id;
        cseData2.ContactId = con.Id;       
        cseData2.SalesOrganization__c = 'SAP_0111';
        cseData2.Subject = 'Xen';
        cseData2.Description = 'Bas';
        cseData2.Priority = 'Medium';
        cseData2.PhysicalAsset__c = testAsset.Id;
        cseData2.SLADate__c = System.now() + 10;
        insert cseData2;
	}
    
    
    @isTest static void test_createOrderClass() {
        
        Id currentId =  UserInfo.getUserId();
        List<Case> cse = [SELECT Id, Subject, Status, CaseSubStatus__c, CreatedOrderedManually__c, RecordTypeId FROM Case WHERE Subject = 'Xen' LIMIT 2];
        Resource__c rs = [SELECT Id, RelatedUser__c FROM Resource__c WHERE RelatedUser__c =:currentId LIMIT 1];
        Resource__c rs2 = [SELECT Id, RelatedUser__c FROM Resource__c WHERE RelatedUser__c !=:currentId LIMIT 1];
        
        Test.startTest();
        TS_WorkOrderListMobileControllerCLONE.hasException = true;
        String orderResult = TS_RecordHeaderController.createOrderClass(cse[0].Id);
        String orderResult2 = TS_RecordHeaderController.createOrderClass(cse[1].Id);
        List<Case> cseUpdated = [SELECT Id, Subject, Status, CaseSubStatus__c, CreatedOrderedManually__c, SLADate__c, RecordTypeId FROM Case WHERE (Id =: cse[0].Id OR Id =: cse[1].Id)  LIMIT 2];
		List<WorkOrderLineItem> openTaskList = TS_RecordHeaderController.getOpenTasks(cseUpdated[0].Id);
		List<WorkOrderLineItem> openTaskList2 = TS_RecordHeaderController.getOpenTasks(cseUpdated[1].Id);                
		
		WorkOrderLineItem toBeScheduled = openTaskList[0];
		toBeScheduled.Status = 'Scheduled';
		toBeScheduled.ExecutingEngineer__c = rs.Id;
		update toBeScheduled;
		
		/*WorkOrderLineItem toBeScheduled2 = openTaskList2[0];
		toBeScheduled.Status = 'Scheduled';
		toBeScheduled.ExecutingEngineer__c = rs2.Id;
		update toBeScheduled2;*/
        
        String searchStr = 'Scheduled';
        Boolean isThirdParty = false;
        
        System.assert(TS_WorkOrderListMobileControllerCLONE.getAllRecords2(0,isThirdParty) != null);
        System.assert(TS_WorkOrderListMobileControllerCLONE.getAllRecords3(0,isThirdParty) != null);
        System.assert(TS_WorkOrderListMobileControllerCLONE.getOpenRecordsTeam(0) != null);
        System.assert(TS_WorkOrderListMobileControllerCLONE.getClosedRecordsTeam(0) != null);
                                        
        System.assert(TS_WorkOrderListMobileControllerCLONE.getAllRecordsNumberOpen(isThirdParty) != null);
        System.assert(TS_WorkOrderListMobileControllerCLONE.getAllMyRecordsNumberClosed(isThirdParty) != null);
        System.assert(TS_WorkOrderListMobileControllerCLONE.getAllRecordsTeamNumberOpen() != null);
        System.assert(TS_WorkOrderListMobileControllerCLONE.getAllRecordsTeamNumberClosed() != null);       
        
        System.assert(TS_WorkOrderListMobileControllerCLONE.searchMyOpen(searchStr,isThirdParty) != null);
        System.assert(TS_WorkOrderListMobileControllerCLONE.searchMyClosed(searchStr,isThirdParty) != null);
        System.assert(TS_WorkOrderListMobileControllerCLONE.searchTeamsOpen(searchStr) != null);
        System.assert(TS_WorkOrderListMobileControllerCLONE.searchTeamsClosed(searchStr) != null);
		     
        Test.stopTest();
	}
    
   @isTest static void test_createOrderClassForThirdParty() {
        
        Id currentId =  UserInfo.getUserId();
        List<Case> cse = [SELECT Id, Subject, Status, CaseSubStatus__c, CreatedOrderedManually__c, RecordTypeId FROM Case WHERE Subject = 'Xen' LIMIT 2];
        Resource__c rs = [SELECT Id, RelatedUser__c FROM Resource__c WHERE RelatedUser__c =:currentId LIMIT 1];
        Resource__c rs2 = [SELECT Id, RelatedUser__c FROM Resource__c WHERE RelatedUser__c !=:currentId LIMIT 1];
        
        Test.startTest();
        TS_WorkOrderListMobileControllerCLONE.hasException = true;
        String orderResult = TS_RecordHeaderController.createOrderClass(cse[0].Id);
        String orderResult2 = TS_RecordHeaderController.createOrderClass(cse[1].Id);
        List<Case> cseUpdated = [SELECT Id, Subject, Status, CaseSubStatus__c, CreatedOrderedManually__c, SLADate__c, RecordTypeId FROM Case WHERE (Id =: cse[0].Id OR Id =: cse[1].Id)  LIMIT 2];
		List<WorkOrderLineItem> openTaskList = TS_RecordHeaderController.getOpenTasks(cseUpdated[0].Id);
		List<WorkOrderLineItem> openTaskList2 = TS_RecordHeaderController.getOpenTasks(cseUpdated[1].Id);                
		
		WorkOrderLineItem toBeScheduled = openTaskList[0];
		toBeScheduled.Status = 'Scheduled';
		toBeScheduled.ExecutingEngineer__c = rs.Id;
		update toBeScheduled;

        String searchStr = 'Scheduled';
        Boolean isThirdParty = true;
       
        System.assert(TS_WorkOrderListMobileControllerCLONE.getOpenRecordsOperating(0) != null);
        System.assert(TS_WorkOrderListMobileControllerCLONE.getClosedRecordsOperating(0) != null);
                                
        System.assert(TS_WorkOrderListMobileControllerCLONE.getAllOperatingNumberOpen() != null);
		System.assert(TS_WorkOrderListMobileControllerCLONE.getAllOperatingNumberClosed() != null);        

		System.assert(TS_WorkOrderListMobileControllerCLONE.searchOperatingOpen(searchStr) != null);
		System.assert(TS_WorkOrderListMobileControllerCLONE.searchOperatingClosed(searchStr) != null);
        
        System.assert(TS_WorkOrderListMobileControllerCLONE.checkIfThirdParty() != 'true');        
        Test.stopTest();
	}
}