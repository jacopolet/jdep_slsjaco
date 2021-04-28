/**
 * This class contains unit tests for validating the behavior of TerritoryModelTriggerHandler
 * and triggers.
 */
//-------------------------------------------------------------------------------------------//
// Author       :   Alvin Lomod - Accenture
// Created Date :   June 27, 2017
// Usage        :   
// Updates      :   September 19, 2017 - Alvin Lomod - Remediation - Assert
//-------------------------------------------------------------------------------------------//
@isTest
private class TerritoryModelTriggerHandlerTest{
    
    public static boolean createRule;
    public static boolean withExistingResult;
    public static Territory_Model__c model;
    
    static testMethod void CloneTestTriggerEnabled(){
        
        Test.startTest();
        createRule = true;
        withExistingResult = true;
        insert new TriggerSettings__c(TerritoryModelTrigger__c = true);
        insert new WorkflowSettings__c(TerritoryModelWorkflows__c = true);
        
        CreateTestData();
        
        Territory_Model__c tm = [SELECT Id, Record_Id__c, Name, Description__c, Sales_Organization__c, Account_Type__c from Territory_Model__c LIMIT 1];
            
        system.debug(tm);
        
        Territory_Model__c newTM;
        newTM = new Territory_Model__c();
        newTM.Name = 'Test Model';
        newTM.Description__c = 'Test';
        newTM.Sales_Organization__c = 'SAP_0333';
        newTM.Account_Type__c = 'Customer';
        newTM.Record_Id__c = tm.Record_Id__c;
        insert newTM;
        
        Test.stopTest();
        
        system.debug(newTM);
        
        List<Territory_Rule__c> ruleList = [SELECT Id FROM Territory_Rule__c WHERE Territory_Model__r.Id =: newTM.Id];
        system.assertEquals(3, ruleList.size());
        
        
        
    }
    
    static testMethod void EditDeleteUndeleteTest(){
        
        Test.startTest();
        createRule = true;
        withExistingResult = true;
        insert new TriggerSettings__c(TerritoryModelTrigger__c = true);
        insert new WorkflowSettings__c(TerritoryModelWorkflows__c = true);
        
        CreateTestData();
        
        Territory_Model__c tm = [SELECT Id, Record_Id__c, Name, Description__c, Sales_Organization__c, Account_Type__c from Territory_Model__c LIMIT 1];
            
        tm.Name = 'Hello Test';
        update tm;
        
        delete tm;
        
        undelete tm;
        
        List<Territory_Model__c> undeltm = [SELECT Id, Record_Id__c, Name, Description__c, Sales_Organization__c, Account_Type__c from Territory_Model__c];
        system.assertEquals( 1 , undeltm.size());
        test.stopTest();
        
         
        
    }
    
    static testMethod void TestTriggerOff(){
        
        insert new TriggerSettings__c(TerritoryModelTrigger__c = false);
        
        TerritoryModelTriggerHandler territory = new TerritoryModelTriggerHandler();
        TriggerDispatcher.Run(territory);
        
        TriggerSettings__c ts = TriggerSettings__c.getInstance();
        system.assertEquals(false, ts.TerritoryModelTrigger__c);
    
    }
    
    private static void CreateTestData() {  
        
        //Create Account
        List<Account> accList = new List<Account>();
        for(integer x = 0; x < 2; x++){
            Account acc = new Account();
            acc.Name = 'Test Account' + x;
            acc.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.Customer).getRecordTypeId();
            acc.Main_Street_Only__c = 'Test Street';
            acc.Phone = '+1234567890';
            acc.CurrencyIsoCode = 'EUR';
            acc.Language__c = 'SAP_EN';
            acc.Sales_Organization__c = 'SAP_0333';
            acc.Account_Type__c = 'Customer';
            acc.Segment__c = 'SAP_A';
            acc.of_Beds__c = 10;
            acc.of_drinks__c = 10;
            acc.of_Employees_FTE__c = 10;
            acc.Exclude_from_Territory_Assignment__c = false;
            acc.Area_Code__c = 1000;
            acc.of_Seats__c = 10;
            accList.add(acc);
        }
        accList[1].Exclude_from_Territory_Assignment__c = true;
        insert accList;
        
        //Create Territory Model
        model = new Territory_Model__c();
        model.Name = 'Test Model';
        model.Description__c = 'Test';
        model.Sales_Organization__c = 'SAP_0333';
        model.Account_Type__c = 'Customer';
        insert model;
        
        //Create Territory
        Territory__c territory = new Territory__c();
        territory.Commercial_Territory_Owner__c = UserInfo.getUserId();
        insert territory;       
        
        //Create Territory Rule
        List<Territory_Rule__c> ruleList = new List<Territory_Rule__c>();
        
        if(createRule == true){
            for(integer x = 0; x < 3; x++){
                Territory_Rule__c rule = new Territory_Rule__c();
                rule.Area_Code_From__c = '0';
                rule.Area_Code_To__c = '1000';
                rule.Beds_From__c = '0';
                rule.Beds_To__c = '1000';
                rule.Drinks_From__c = '0';
                rule.Drinks_To__c = '1000';
                rule.Employees_From__c = '0';
                rule.Employees_To__c = '1000';
                rule.Seats_From__c = '0';
                rule.Seats_To__c = '1000';
                rule.Assigned_Territory__c = territory.id;
                rule.Postal_Code_From__c = '0';
                rule.Postal_Code_To__c = '1000';
                rule.Segment__c = 'SAP_A;SAP_B;SAP_C';
                rule.Territory_Model__c = model.id;
                ruleList.add(rule);
            }
            insert ruleList;
        }       
        
        //Create Territory Results - to test scenario where there are existing Territory Results associated with the Territory Model
        if(withExistingResult == true){
            Territory_Result__c result = new Territory_Result__c();
            result.Name = 'Test Result';
            result.Assigned_Territory__c = territory.id;
            result.Account__c = accList[0].id;
            result.Territory_Model__c = model.id;
            result.Territory_Rule__c = ruleList[0].id;
            insert result;
        }
    }
    
}