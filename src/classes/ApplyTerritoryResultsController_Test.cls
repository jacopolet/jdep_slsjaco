/**
 * Class Name: ApplyTerritoryResultsController_Test
 * @author: James Azana
 * Date: 28-Jun-2017
 * @description: Test Class for ApplyTerritoryResultsController
 *
 */
 
@isTest(SeeAllData=false)
public class ApplyTerritoryResultsController_Test{
    
    public static List<Territory_Model__c> modelList = new List<Territory_Model__c>();
    public static Account acc;
    public static Territory__c territory;
    public static Territory_Rule__c rule;
    
    private static testMethod void TestProceed(){
        
        CreateTestData();
        
        system.test.startTest();
        
        ApexPages.StandardController sc = new ApexPages.standardController(modelList[0]); 
        ApplyTerritoryResultsController controller = new ApplyTerritoryResultsController(sc);
        
        //simulate press of 'Apply on Account' and 'Yes' button
        controller.applyResultsAndReturnToModel();
        controller.applyModeResult();
        
        //check status update after batch process
        Territory_Model__c updatedModel_beforeBatch = [SELECT id, Definition_Status__c, Active__c FROM Territory_Model__c WHERE id = :modelList[0].id];
       
        system.assertEquals(updatedModel_beforeBatch.Definition_Status__c, 'Applying on Accounts');
        
        system.test.stopTest();
        
        //check status and active checkbox update after batch process
        Territory_Model__c updatedModel_afterBatch = [SELECT id, Definition_Status__c, Active__c FROM Territory_Model__c WHERE id = :modelList[0].id];
        system.assertEquals(updatedModel_afterBatch.Definition_Status__c, 'Complete');
        system.assertEquals(updatedModel_afterBatch.Active__c, TRUE);
        
        Territory_Model__c updatedModel_afterBatch2 = [SELECT id, Definition_Status__c, Active__c FROM Territory_Model__c WHERE id = :modelList[1].id];
        system.assertEquals(updatedModel_afterBatch2.Active__c, TRUE);
        
        //check account updates
        Account accUpdated = [SELECT id, name, Territory__c, Applied_Territory_Rule__c, OwnerId FROM Account WHERE Id = :acc.id][0];
        system.assertEquals(accUpdated.Territory__c, territory.id);
        system.assertEquals(accUpdated.Applied_Territory_Rule__c, rule.id);
        system.assertEquals(accUpdated.OwnerId, territory.Commercial_Territory_Owner__c);
    }
    
    private static testMethod void testValidationOnApply(){
        
        CreateTestData();
        
        system.test.startTest();
        
        ApexPages.StandardController sc = new ApexPages.standardController(modelList[0]); 
        ApplyTerritoryResultsController controller = new ApplyTerritoryResultsController(sc);
        
        //simulate press of 'Apply on Account' and 'Yes' button
        controller.applyResultsAndReturnToModel();
        controller.applyModeResult();
        
        //check status update after batch process
        Territory_Model__c updatedModel_beforeBatch = [SELECT id, Definition_Status__c, Active__c FROM Territory_Model__c WHERE id = :modelList[0].id];
       
        system.assertEquals(updatedModel_beforeBatch.Definition_Status__c, 'Applying on Accounts');
        
        system.test.stopTest();
        ValidationRulesSettings__c vatRule = new ValidationRulesSettings__c();
        vatRule.AccountTerritory__c = true;
        insert vatRule;
        
        //check status and active checkbox update after batch process
        Territory_Model__c updatedModel_afterBatch = [SELECT id, Definition_Status__c, Last_Run__c, Active__c FROM Territory_Model__c WHERE id = :modelList[0].id];
        system.assertEquals(updatedModel_afterBatch.Definition_Status__c, 'Complete');
        system.assertEquals(updatedModel_afterBatch.Active__c, TRUE);
        System.assertNotEquals(updatedModel_afterBatch.Last_Run__c, Null);
        
        ApexPages.StandardController sc2 = new ApexPages.standardController(updatedModel_afterBatch); 
        ApplyTerritoryResultsController controller2 = new ApplyTerritoryResultsController(sc2);
        
		//simulate press of 'Apply on Account' and 'Yes' button
		ValidationRulesSettings__c vat = ValidationRulesSettings__c.getInstance();
        controller2.applyResultsAndReturnToModel();   
    }
    
    private static testMethod void testApplyTerritory(){
        
        CreateTestData();
        
        system.test.startTest();
        
        ApexPages.StandardController sc = new ApexPages.standardController(modelList[0]); 
        ApplyTerritoryResultsController controller = new ApplyTerritoryResultsController(sc);
        
        //simulate press of 'Apply on Account' and 'Yes' button
        controller.applyResultsAndReturnToModel();
        controller.applyModeResult();
        
        //check status update after batch process
        Territory_Model__c updatedModel_beforeBatch = [SELECT id, Definition_Status__c, Active__c FROM Territory_Model__c WHERE id = :modelList[0].id];
        
        system.assertEquals(updatedModel_beforeBatch.Definition_Status__c, 'Applying on Accounts');
        
        system.test.stopTest();
        
        //check status and active checkbox update after batch process
        Territory_Model__c updatedModel_afterBatch = [SELECT id, Definition_Status__c, Last_Run__c, Active__c FROM Territory_Model__c WHERE id = :modelList[0].id];
        system.assertEquals(updatedModel_afterBatch.Definition_Status__c, 'Complete');
        system.assertEquals(updatedModel_afterBatch.Active__c, TRUE);
        System.assertNotEquals(updatedModel_afterBatch.Last_Run__c, Null);
        
        ApexPages.StandardController sc2 = new ApexPages.standardController(updatedModel_afterBatch); 
        ApplyTerritoryResultsController controller2 = new ApplyTerritoryResultsController(sc2);

		//simulate press of 'Apply on Account' and 'Yes' button
		ValidationRulesSettings__c vat = ValidationRulesSettings__c.getInstance();
        controller2.applyResultsAndReturnToModel();   
    }
    
    private static testMethod void TestCancel(){
        
        CreateTestData();
        
        system.test.startTest();
        
        ApexPages.StandardController sc = new ApexPages.standardController(modelList[0]); 
        ApplyTerritoryResultsController controller = new ApplyTerritoryResultsController(sc);
        
        //simulate press of 'Apply on Account' and 'No' button
        controller.returnToModel();
        
        system.test.stopTest();
        
        system.assertEquals(controller.model.Id, modelList[0].Id);
    }
    
    private static void CreateTestData() {
        
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
        acc = new Account();
        acc.Name = 'Test Account';
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
        insert acc;
        
        //Create Territory Models
        Territory_Model__c model1 = new Territory_Model__c();
        model1.Name = 'Test Model 1';
        model1.Description__c = 'Test';
        model1.Sales_Organization__c = 'SAP_0111';
        model1.Country__c = 'Netherlands';
        model1.Account_Type__c = 'Customer';
        model1.Active__c = false;
        modelList.add(model1);
        
        Territory_Model__c model2 = new Territory_Model__c();
        model2.Name = 'Test Model 2';
        model2.Description__c = 'Test';
        model2.Sales_Organization__c = 'SAP_0333';
        model2.Country__c = 'Netherlands';
        model2.Account_Type__c = 'Customer';
        model2.Active__c = true;
        modelList.add(model2);
        
        insert modelList;
        
        //Create Territory
        territory = new Territory__c();
        territory.Commercial_Territory_Owner__c = UserInfo.getUserId();
        insert territory;       
        
        //Create Territory Rule
        rule = new Territory_Rule__c();
        //rule.Area_Code_From__c = '0';
        //rule.Area_Code_To__c = '1000';
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
        rule.Territory_Model__c = modelList[0].id;
        rule.Account_Lifecycle__c = 'Active Customer';
        insert rule;
        
        //Create Territory Results
        Territory_Result__c result = new Territory_Result__c();
        result.Name = 'Test Result';
        result.Assigned_Territory__c = territory.id;
        result.Account__c = acc.id;
        result.Territory_Model__c = modelList[0].id;
        result.Territory_Rule__c = rule.id;
        insert result;
    }

}