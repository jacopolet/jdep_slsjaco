/**
* @author        Adrian Reyes
* @date          1.May.2018
* @description   Test class for TS_TechSpecialistFlowProcessor
* @revision(s)
*/

@isTest
private class TS_TechSpecialistFlowProcessor_Test {
    static Case c;
    
    /**
    * @author        Adrian Reyes
    * @date          1.May.2018           
    * @description   Method responsible for creating test data
    * @revision(s)
    */
    static void setupTestData() {
        CountrySetting__c techSpecialistSetting = new CountrySetting__c();
        techSpecialistSetting.RecordTypeId = Schema.SObjectType.CountrySetting__c.getRecordTypeInfosByName().get('Technical Specialist Indicator').getRecordTypeId();
        techSpecialistSetting.Name = 'Technical Specialist Setting';
        techSpecialistSetting.Country__c = 'SAP_0333';
        techSpecialistSetting.Treshold_Days__c = 1;
        techSpecialistSetting.Max_Visits_Treshhold__c = 1;
        techSpecialistSetting.Active__c = true;
        insert techSpecialistSetting;
        
        Account acct = new Account(Name='Account', Phone='+31302979111');
        insert acct;
        
        Contact con = TS_TestDataFactory.createContact();  
        con.Preferred_Language__c = 'SAP_EN';
        insert con;
        
        Product2 prod = TS_TestDataFactory.createProduct('Test Product I', 'MA');
        prod.ProductCode = '123';
        insert prod;
        
        PhysicalAsset__c pa = new PhysicalAsset__c(Name='Test', UniqueNumber__c='1234567-TestMachine', RecordTypeId = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get('Machine').getRecordTypeId(), Product__c = prod.Id);
        insert pa;
        
        c = TS_TestDataFactory.createFieldServiceCase();
        c.ContactId = con.Id;
        c.PhysicalAsset__c = pa.Id;
        c.SalesOrganization__c = 'SAP_0333';
        insert c;
    }
    
    static testMethod void testTechSpecialistFlowProcessor(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();
            
            Test.startTest();
            TS_TechSpecialistFlowProcessor.executeTechSpecialistFlow(new List<Id>{c.Id});
            Test.stopTest();
            
            //Verify results
            System.assertEquals(1, [SELECT Technical_Specialist_Counter__c FROM Case WHERE Id =: c.Id LIMIT 1].Technical_Specialist_Counter__c);
        }
    }
}