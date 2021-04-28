/**
 * Class Name: GenerateTerritoryResultsController_Test
 * @author: James Azana
 * Date: 27-Jun-2017
 * @description: Test Class for GenerateTerritoryResultsController
 *
 */
 
@isTest(SeeAllData=false)
public class GenerateTerritoryResultsController_Test{
    
    public static boolean createRule;
    public static boolean withExistingResult;
    public static boolean badData;
    public static Territory_Model__c model;
        
    private static testMethod void TestPositive_withExistingResult() {
        createRule = true;
        withExistingResult = true;
        badData = false;
        CreateTestData();
                
        system.test.startTest();
        
        ApexPages.StandardController sc = new ApexPages.standardController(model); 
        GenerateTerritoryResultsController controller = new GenerateTerritoryResultsController(sc);
        
        //simulate press of Generate Results button
        Pagereference pageRef = controller.refreshPage();
        
        //check status update before batch process
        Territory_Model__c updatedModel_beforeBatch = [SELECT id, Definition_Status__c FROM Territory_Model__c WHERE id = :model.id];
        system.assertEquals(updatedModel_beforeBatch.Definition_Status__c, 'Generating Results (Preview)');
        
        system.test.stopTest();
        
        //check status update after batch process
        Territory_Model__c updatedModel_afterBatch = [SELECT id, Definition_Status__c FROM Territory_Model__c WHERE id = :model.id];
        system.assertEquals(updatedModel_afterBatch.Definition_Status__c, 'Results Generated (Preview)');
        
        //check if Territory Results are created
        List<Territory_Result__c> result = [SELECT id, name, Territory_Model__c FROM Territory_Result__c WHERE Territory_Model__c = :model.id];
        system.assertEquals(result.size(), 3);
    }
    
    private static testMethod void TestPositive_withoutExistingResult() {
        createRule = true;
        withExistingResult = false;
        badData = false;
        CreateTestData();
                
        system.test.startTest();
        
        ApexPages.StandardController sc = new ApexPages.standardController(model); 
        GenerateTerritoryResultsController controller = new GenerateTerritoryResultsController(sc);
        
        //simulate press of Generate Results button
        Pagereference pageRef = controller.refreshPage();
        
        //check status update before batch process
        Territory_Model__c updatedModel_beforeBatch = [SELECT id, Definition_Status__c FROM Territory_Model__c WHERE id = :model.id];
        system.assertEquals(updatedModel_beforeBatch.Definition_Status__c, 'Generating Results (Preview)');
                
        system.test.stopTest();
        
        //check status update after batch process
        Territory_Model__c updatedModel_afterBatch = [SELECT id, Definition_Status__c FROM Territory_Model__c WHERE id = :model.id];
        system.assertEquals(updatedModel_afterBatch.Definition_Status__c, 'Results Generated (Preview)');
        
        //check if Territory Results are created
        List<Territory_Result__c> result = [SELECT id, name, Territory_Model__c FROM Territory_Result__c WHERE Territory_Model__c = :model.id];
        system.assertEquals(result.size(), 3);
        
    }

    private static testMethod void TestNegative_noRule() {
        createRule = false;
        badData = false;
        CreateTestData();
        
        system.test.startTest();
        
        ApexPages.StandardController sc = new ApexPages.standardController(model); 
        GenerateTerritoryResultsController controller = new GenerateTerritoryResultsController(sc);
        
        //simulate press of Generate Results button - no rules associated
        Pagereference pageRef_001 = controller.refreshPage();
        
        
        //simulate press of Back button
        Pagereference pageRef_002 = controller.returnToModelPage();
        
        system.assertEquals(pageRef_001, null);
        system.test.stopTest();
    }
    
    private static testMethod void TestNegative_badData() {
        createRule = true;
        withExistingResult = false;
        badData = true;
        CreateTestData();
        
        system.test.startTest();
        
        ApexPages.StandardController sc = new ApexPages.standardController(model); 
        GenerateTerritoryResultsController controller = new GenerateTerritoryResultsController(sc);
        
        try{
            //simulate press of Generate Results button
            Pagereference pageRef = controller.refreshPage();
        }catch(exception e){
        
        }
        
        //check status update before batch process
        Territory_Model__c updatedModel_beforeBatch = [SELECT id, Definition_Status__c FROM Territory_Model__c WHERE id = :model.id];
        system.assertEquals(updatedModel_beforeBatch.Definition_Status__c, 'Generating Results (Preview)');
                
        system.test.stopTest();
        
        //check status update after batch process
        Territory_Model__c updatedModel_afterBatch = [SELECT id, Definition_Status__c FROM Territory_Model__c WHERE id = :model.id];
        system.assertEquals(updatedModel_afterBatch.Definition_Status__c, 'Results Generated (Preview)');
        
        //check if Territory Results are created
        List<Territory_Result__c> result = [SELECT id, name, Territory_Model__c FROM Territory_Result__c WHERE Territory_Model__c = :model.id];
        system.assertEquals(result.size(), 0);
    }
    
    static void CreateTestData() {
    
        //Custom setting create value
        List<AccountTerritoryAssignmentValues__c> atavList = new List<AccountTerritoryAssignmentValues__c>();
        
        AccountTerritoryAssignmentValues__c atav1 = new AccountTerritoryAssignmentValues__c();
        atav1.Name = 'createBatchScope';
        atav1.Value__c = '2000';
        atavList.add(atav1);
        
        AccountTerritoryAssignmentValues__c atav2 = new AccountTerritoryAssignmentValues__c();
        atav2.Name = 'updateBatchScope';
        atav2.Value__c = '2000';
        atavList.add(atav2);
        
        AccountTerritoryAssignmentValues__c atav3 = new AccountTerritoryAssignmentValues__c();
        atav3.Name = 'deleteBatchScope';
        atav3.Value__c = '2000';
        atavList.add(atav3);
        
        AccountTerritoryAssignmentValues__c atav4 = new AccountTerritoryAssignmentValues__c();
        atav4.Name = 'Email_Applied';
        atav4.Text_Area_Value__c = 'Test Body';
        atav4.Value__c = 'Test Subject';
        atavList.add(atav4);
        
        AccountTerritoryAssignmentValues__c atav5 = new AccountTerritoryAssignmentValues__c();
        atav5.Name = 'Email_Generated';
        atav5.Text_Area_Value__c = 'Test Body';
        atav5.Value__c = 'Test Subject';
        atavList.add(atav5);
        
        AccountTerritoryAssignmentValues__c atav6 = new AccountTerritoryAssignmentValues__c();
        atav6.Name = 'Email_Error';
        atav6.Text_Area_Value__c = 'Test Body';
        atav6.Value__c = 'Test Subject';
        atavList.add(atav6);
        
        insert atavList;
        
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
            acc.Sales_Organization__c = 'SAP_0111';
            acc.Main_Country__c = 'Netherlands';
            acc.Account_Type__c = 'Customer';
            acc.Segment__c = 'SAP_A';
            acc.of_Beds__c = 10;
            acc.of_drinks__c = 10;
            acc.of_Employees_FTE__c = 10;
            acc.Exclude_from_Territory_Assignment__c = false;
            acc.Area_Code__c = 1000;
            acc.of_Seats__c = 10;
            acc.of_visitors__c = 10;
            acc.Account_Lifecycle__c = 'Active Customer';
            if(badData){
                acc.Main_Postal_Code__c = 'AAAA';
            }else{
                acc.Main_Postal_Code__c = '1000';
            }
            acc.Main_Address_Validation_Timestamp__c = System.today()+x;
            accList.add(acc);
        }
        accList[1].Exclude_from_Territory_Assignment__c = true;
        insert accList;
        
        //Create Territory Model
        model = new Territory_Model__c();
        model.Name = 'Test Model';
        model.Description__c = 'Test';
        model.Sales_Organization__c = 'SAP_0111';
        model.Country__c = 'Netherlands';
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
                rule.Visitors_From__c = '0';
                rule.Visitors_To__c = '1000';
                rule.Segment__c = 'SAP_A;SAP_B;SAP_C';
                rule.Territory_Model__c = model.id;
                rule.Account_Lifecycle__c = 'Active Customer';
                
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
            System.assertEquals(result.Name,'Test Result');
        }
        
        
    }

}