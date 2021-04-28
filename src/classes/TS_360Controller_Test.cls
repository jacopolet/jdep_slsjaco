/**
* @author        Xen Reyes
* @date          14.3.2017           
* @description   Test Class for TS_360Controller
* @revision(s)
*/
@isTest
public class TS_360Controller_Test{
    
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
        
        PricebookEntry standardPrice = new PricebookEntry(Pricebook2Id = standardPB.Id, Product2Id = prod.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
        insert standardPrice;
        
        PricebookEntry newProduct = new PricebookEntry (Pricebook2Id = pb.id, Product2Id = prod.id, IsActive=true, UseStandardPrice = false, UnitPrice=100.0);
        insert newProduct;
        
        PhysicalAsset__c testAsset = new PhysicalAsset__c();
        testAsset.RecordTypeId = TS_UtilityClass.getRecordTypeIdByName('PhysicalAsset__c', 'Machine');
        testAsset.Name = 'Test Asset';
        testAsset.UniqueNumber__c = '1234567890';
        testAsset.AccountLocation__c = alocation.Id;
        testAsset.AssetStatus__c = 'Activated';
        insert testAsset;
        
        PhysicalAsset__c testAsset2 = new PhysicalAsset__c();
        testAsset2.RecordTypeId = TS_UtilityClass.getRecordTypeIdByName('PhysicalAsset__c', 'Machine');
        testAsset2.Name = 'Test Asset2';
        testAsset2.UniqueNumber__c = '1234567890-123';
        testAsset2.AccountLocation__c = alocation.Id;
        testAsset2.AssetStatus__c = 'Activated';
        insert testAsset2;
        
        ProcessBuilderSettings__c pbTest = new ProcessBuilderSettings__c();
        pbTest.CasePBFlows__c = true;
        insert pbTest;
        
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
    }
    
    @isTest static void test_locationsAndMachines() {
        
        Account acc = [SELECT Id FROM Account WHERE Name = 'SendToClick_Test Name' LIMIT 1];
        Apttus_Config2__AccountLocation__c aloc = [SELECT Id FROM Apttus_Config2__AccountLocation__c WHERE Shipping_Country_ISO__c = 'NL'];
        Test.startTest();
        
        List<TS_360Controller.LocationsWrapper> wrap = TS_360Controller.locationsAndMachines(acc.Id, 'Contact', '');
        List<TS_360Controller.LocationsWrapper> wrap2 = TS_360Controller.locationsAndMachines('', 'Apttus_Config2__AccountLocation__c', aloc.Id);
        
        Test.stopTest();
    }
    
    @isTest static void test_getRecordTypeCR() {
        
        Test.startTest();
        String recId = TS_360Controller.getRecordTypeCR();
        System.assertNotEquals('', recId);
        Test.stopTest();
    }
    
    /**
    * @author        Ritesh Kumar
    * @date          13.01.2018           
    * @description   To Increase the test Coverage
    * @revision(s)
    */
    @isTest static void test_getAllInfoService360(){
        Test.startTest();
        String serialize_JSON = TS_360Controller.getAllInfoService360();
        System.assertNotEquals('', serialize_JSON);
        Test.stopTest();
    }
    
    /**
    * @author        Ritesh Kumar
    * @date          16.01.2018           
    * @description   To Increase the test Coverage
    * @revision(s)
    */
    @isTest static void test_getRecords(){
        PhysicalAsset__c assetID = [SELECT Id FROM PhysicalAsset__c LIMIT 1];
            Test.startTest();
            String status = TS_360Controller.getRecords(assetID.Id, 'Case', true, false, false, 'Generic question', 'open','2018-08-12','2018-08-19');
            Test.stopTest();
        	System.assertNotEquals('', status);
    }
    
    @isTest static void test_getRecords1(){
        PhysicalAsset__c assetID = [SELECT Id FROM PhysicalAsset__c LIMIT 1];
            Test.startTest();
            String status = TS_360Controller.getRecords(assetID.Id, 'WorkOrderLineItem', true, false, false, 'S21', 'open','2018-08-12','2018-08-19');
            Test.stopTest();
        	System.assertNotEquals('', status);
    }
}