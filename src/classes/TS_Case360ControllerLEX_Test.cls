/**
* @author        Abram Vixen Reyes
* @date          22.3.2017           
* @description   Test Class for TS_Case360ControllerLEX
*/
@isTest
public class TS_Case360ControllerLEX_Test {
    
    @testSetup static void dataSetup() {
        List<Account> accountList = TS_TestDataFactory.createAccounts(1);
        accountList.get(0).Name = 'SendToClick_Test Name';
        insert accountList;
        
        Contact con = TS_TestDataFactory.createContact();  
        con.Preferred_Language__c = 'SAP_EN';
        Insert con;
        
        Apttus_Config2__AccountLocation__c alocation = TS_TestDataFactory.createAccountLocation( accountList.get(0).Id );
        alocation.Apttus_Config2__PostalCode__c   = '123';
        alocation.Shipping_Country_ISO__c = 'NL';
        alocation.Shipping_Street_Only__c = '1';
        alocation.Apttus_Config2__City__c = 'city';
        insert alocation;
        
        PhysicalAsset__c testAsset = new PhysicalAsset__c();
        testAsset.RecordTypeId = TS_UtilityClass.getRecordTypeIdByName('PhysicalAsset__c', 'Machine');
        testAsset.Name = 'Test Asset';
        testAsset.UniqueNumber__c = '1234' ;
        testAsset.AccountLocation__c = alocation.Id;
        insert testAsset;
        
        PhysicalAsset__c testAssetOptions = new PhysicalAsset__c();
        testAssetOptions.RecordTypeId = TS_UtilityClass.getRecordTypeIdByName('PhysicalAsset__c', 'Option');
        testAssetOptions.Name = 'Test AssetOption';
        testAssetOptions.UniqueNumber__c = '5678';
        testAssetOptions.AccountLocation__c = alocation.Id;
        testAssetOptions.ParentPhysicalAsset__c = testAsset.Id;
        insert testAssetOptions;
        
        Case cseData = TS_TestDataFactory.createFieldServiceCase();
        cseData.AccountId = accountList[0].Id;
        cseData.ContactId = con.Id;       
        cseData.SalesOrganization__c = 'SAP_0333';
        cseData.Subject = 'Bas';
        cseData.Description = 'Bas';
        cseData.Priority = 'Medium';
        cseData.PhysicalAsset__c = testAsset.Id;
        cseData.SLADate__c = System.now() + 7;
        insert cseData;
        
        /**
        * @author        Ritesh
        * @date          10.8.2018           
        * @description   Test Class for TS_Case360ControllerLEX Coverage
        */
        WorkOrder workOrder_obj = TS_TestDataFactory.createWorkOrder();
        workOrder_obj.RecordTypeId = TS_UtilityClass.getRecordTypeIdByName('WorkOrder','TS Work Order');
        workOrder_obj.OP_Physical_Asset__c = testAsset.id;
        workOrder_obj.CaseId = cseData.id;
        Insert workOrder_obj;

        //DOO-4643 Francis Allen Alindogan 06.26.2020
        OperatingHourAssociation__c oha = TS_TestDataFactory.createOperatingHourAssociation(alocation.Id);
        insert oha;
        
    }
    
    @isTest static void test_getOptions() {
        
        //PhysicalAsset__c pa = [SELECT Id FROM PhysicalAsset__c WHERE Name = 'Test Asset' LIMIT 1];
        PhysicalAsset__c pa = [SELECT Id FROM PhysicalAsset__c WHERE UniqueNumber__c = '1234' LIMIT 1];
        Case cse = [SELECT Id FROM Case WHERE Subject = 'Bas' LIMIT 1];
        Test.startTest();
        
        List<PhysicalAsset__c> getAllOptions = TS_Case360ControllerLEX.getOptions(pa.Id);
        System.assertEquals(getAllOptions.size() > 0, true);
        
        Case cse2 = TS_Case360ControllerLEX.getDetails(cse.Id);
        
        Test.stopTest();
    }
    
    @isTest static void test_exceptions() {
        
        //PhysicalAsset__c pa = [SELECT Id FROM PhysicalAsset__c WHERE Name = 'Test Asset' LIMIT 1];
        PhysicalAsset__c pa = [SELECT Id FROM PhysicalAsset__c WHERE UniqueNumber__c = '5678' LIMIT 1];
        Case cse = [SELECT Id FROM Case WHERE Subject = 'Bas' LIMIT 1];
        Test.startTest();
        
        TS_Case360ControllerLEX.hasException = true;
        List<PhysicalAsset__c> getAllOptions = TS_Case360ControllerLEX.getOptions(pa.Id);
        Case cse2 = TS_Case360ControllerLEX.getDetails(cse.Id);
        
        Test.stopTest();
    }
    
    /**
    * @author        Ritesh
    * @date          10.8.2018           
    * @description   Test Class for TS_Case360ControllerLEX Coverage
    */
        
    @isTest static void test_getWODetails(){
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        Test.startTest();
        
        TS_Case360ControllerLEX.hasException = true;
        WorkOrder workOrder_obj = TS_Case360ControllerLEX.getWODetails(wo.Id);
        
        Test.stopTest();
    }

      /**
    * @author        Francis Allen Alindogan
    * @date          06.26.2020
    * @description   Test Class for getOHAList method
    */        
    @isTest static void test_getOHAList(){        
        Apttus_Config2__AccountLocation__c aLoc = [SELECT Id FROM Apttus_Config2__AccountLocation__c limit 1];

        Test.startTest();        
        TS_Case360ControllerLEX.hasException = true;
        List<OperatingHourAssociation__c> ohaList = new List<OperatingHourAssociation__c>();
        ohaList = TS_Case360ControllerLEX.getOHAList(aLoc.Id);
        
        Test.stopTest();

        System.assert(ohaList != null);
    }

}