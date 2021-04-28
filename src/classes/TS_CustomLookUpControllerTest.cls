/**
* @author        Rey Austral
* @date          9.29.2017           
* @description   Test Class for TS_CustomLookUpController
* @revision(s)
*/
@isTest
private class TS_CustomLookUpControllerTest {
    static Account acc;
    static Apttus_Config2__AccountLocation__c accLoc;
    static Contact con;
    static PhysicalAsset__c pAsset;
        
    
	@testSetup
    static void dataSetup() {
        acc = new Account(Name='Account 1', Phone='+31302979111');   
        insert acc;                
                
        Product2 prod_ZCMA = TS_TestDataFactory.createProductTest('ProductTest','ZCMA');
        insert prod_ZCMA;
                
        con = TS_TestDataFactory.createContact();  
        con.Preferred_Language__c = 'SAP_EN';
        con.AccountId = acc.Id;
        insert con;
        
        accLoc = TS_TestDataFactory.createAccountLocationTest('123456753', acc.Id);
        accLoc.Apttus_Config2__AccountId__c = acc.Id;               
        insert accLoc;
        
		pAsset = TS_TestDataFactory.createPhysicalAsset();
        pAsset.NextWTSDate__c = Date.Today().addDays(5);
        pAsset.Product__c = prod_ZCMA.Id;
        pAsset.IncludesWTSCoverage__c = true;
        pAsset.IncludesPreventiveMaintenanceCoverage__c = true;
        pAsset.EndDate__c = Date.today().addDays(1);        
        pAsset.AccountLocation__c = accLoc.Id;
        insert pAsset;
    }
    
    static void setupTestData() {
        pAsset = [SELECT Id FROM PhysicalAsset__c LIMIT 1];
        acc = [SELECT Id FROM Account LIMIT 1];        
    }
    	
	@isTest static void test_fetchLookUpValues() {
		User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);        
        System.runAs(u) {
            setupTestData();
            Test.startTest();
            List < sObject > sObjectList = TS_CustomLookUpController.fetchLookUpValues('Acc','Account','', false, '', '', '', '', '',
                                                                                       false, null, null, null, null, 
                                                                                       false, false, false);        
            Test.stopTest();
    
            System.assertEquals(1, sObjectList.size());
        }
	}
    
    @isTest static void test_fetchLookUpValuesFiltered() {
		User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);        
        System.runAs(u) {
            setupTestData();
            Test.startTest();
            List < sObject > sObjectList = TS_CustomLookUpController.fetchLookUpValues('Acc','Account','', true, '', '', '', '', '',
                                                                                       false, null, null, null, null, 
                                                                                       false, false, false);        
            Test.stopTest();
    
            System.assertEquals(1, sObjectList.size());
        }
	}
    
    @isTest static void test_fetchLookUpValuesNested() {
		User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);        
        System.runAs(u) {
            setupTestData();
            Test.startTest();            
            List < sObject > sObjectList = TS_CustomLookUpController.fetchLookUpValues(null,'Contact','', false, 'AccountId IN', '', '', '', '',
                                                                                       true, 'AccountLocation__r.Apttus_Config2__AccountId__c', 'PhysicalAsset__c', 'Id IN', pAsset.Id,
                                                                                       true, true, true);              
            Test.stopTest();                
        }            
	}  
    
    @isTest static void test_fetchLookUpValuesExact() {
		User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);        
        System.runAs(u) {
            setupTestData();
            Test.startTest();            
            List < sObject > sObjectList = TS_CustomLookUpController.fetchLookUpValues(acc.Id,'Account','', false, 'AccountId IN', '', '', '', 'Exact',
                                                                                       false, '', '', '', '',
                                                                                       true, true, true);              
            Test.stopTest();                
        }            
	}  
       	
	@isTest static void test_exception() {
		User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);        
        System.runAs(u) {                
            setupTestData();
            Test.startTest();
            TS_CustomLookUpController.hasException = true;
            List < sObject > sObjectList = TS_CustomLookUpController.fetchLookUpValues('Acc','Account','', false, '', '', '', '', '',
                                                                                       false, null, null, null, null, 
                                                                                       false, false, false);        
            Test.stopTest();
    
            System.assertEquals(1, sObjectList.size());
        }            
	}            
}