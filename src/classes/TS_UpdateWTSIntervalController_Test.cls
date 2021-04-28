/**
* @author        Francis Alindogan
* @date          01.31.2020
* @description   Test class for TS_UpdateWTSIntervalController
* @revision(s)   
*/
@isTest
public class TS_UpdateWTSIntervalController_Test {
    
    static PhysicalAsset__c pa;
    static Product2 prod;
    
    static void setupTestData() {
        prod = TS_TestDataFactory.createProduct('Test','Coffee');
		prod.Description = 'Desc';
        prod.APTS_Vendor_Code__c = 'CMS';
		insert prod;
        
        pa = new PhysicalAsset__c(Name='Test', 
                                  UniqueNumber__c='1234567-TestMachine', 
								  Product__c = prod.Id,
                                  RecordTypeId = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get('Machine').getRecordTypeId());
        
        insert pa;
        
        APTS_CounterReadingData__c apts = new APTS_CounterReadingData__c();
        apts.TS_Physical_Asset__c = pa.Id;
        apts.APTS_Counter_Status__c = 'Active';
        apts.APTS_Machine_Serial_No__c = '234';
        
        insert apts;
        
    }
    
    static testmethod void testCustomPermission() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
        	Test.startTest();
        	System.assert(TS_UpdateWTSIntervalController.hasCustomPermission('test-class') == false);
        	Test.stopTest();    
        }
    }
    
    static testmethod void test_checkOpenOrders() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
            setupTestData();
            
        	Test.startTest();
        	TS_UpdateWTSIntervalController.checkOpenOrders(pa.Id, '12345678');
        	Test.stopTest();    
        }
    }
    
    static testmethod void test_checkOpenOrdersException() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
            setupTestData();
            
        	Test.startTest();
            TS_UpdateWTSIntervalController.hasException = true;
        	TS_UpdateWTSIntervalController.checkOpenOrders(pa.Id, '12345678');
        	Test.stopTest();    
        }
    }
}