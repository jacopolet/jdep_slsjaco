/**
 * Class Name: TerritoryResult_UpdateBatch_Test
 * @author: James Azana
 * Date: 19-Jul-2017
 * @description: Test Class for TerritoryResult_UpdateBatch
 *
 */
 
@isTest(SeeAllData=false)
public class TerritoryResult_UpdateBatch_Test{
    
    public static List<Territory_Model__c> modelList = new List<Territory_Model__c>();
    public static Account acc;
    public static Territory__c territory;
    public static Territory_Rule__c rule;
    public static boolean badData;
    
    private static testMethod void TestPositive(){
        badData = false;
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
    
    private static testMethod void TestNegative(){
        badData = true;
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
        system.assertEquals(updatedModel_afterBatch.Definition_Status__c, 'Complete'); //'Failed to Apply on Accounts');
        system.assertEquals(updatedModel_afterBatch.Active__c, TRUE);
                
    }
    
    private static testMethod void TestWithExistingMuting(){
        badData = false;
        CreateTestData();
        
        //create custom settings for muting
        ProcessBuilderSettings__c cs_pb = new ProcessBuilderSettings__c();
        cs_pb.SetupOwnerId = UserInfo.getUserId();
        cs_pb.AccountPBFlows__c = true;
        insert cs_pb;
        
        ValidationRulesSettings__c cs_vr = new ValidationRulesSettings__c();
        cs_vr.SetupOwnerId = UserInfo.getUserId();
        cs_vr.AccountValidationRules__c = true;
        insert cs_vr;
        
        WorkflowSettings__c cs_wf = new WorkflowSettings__c();
        cs_wf.SetupOwnerId = UserInfo.getUserId();
        cs_wf.AccountWorkflows__c = true;
        insert cs_wf;
        
        TriggerSettings__c cs_trg = new TriggerSettings__c();
        cs_trg.SetupOwnerId = UserInfo.getUserId();
        cs_trg.AccountTrigger__c = true;
        insert cs_trg;
        
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
        
        //Create Accounts
        Account acc_competitor = new Account();
        acc_competitor.Name = 'Test Account';
        acc_competitor.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        acc_competitor.Main_Street_Only__c = 'Test Street';
        acc_competitor.Phone = '+1234567890';
        acc_competitor.CurrencyIsoCode = 'EUR';
        acc_competitor.Language__c = 'SAP_EN';
        acc_competitor.Sales_Organization__c = 'SAP_0111';
        acc_competitor.Main_Country__c = 'Netherlands';
        acc_competitor.Account_Type__c = 'Customer';
        acc_competitor.Segment__c = 'SAP_A';
        acc_competitor.of_Beds__c = 10;
        acc_competitor.of_drinks__c = 10;
        acc_competitor.of_Employees_FTE__c = 10;
        acc_competitor.Exclude_from_Territory_Assignment__c = false;
        acc_competitor.Area_Code__c = 1000;
        acc_competitor.of_Seats__c = 10;
        acc_competitor.of_visitors__c = 10;
        acc_competitor.Account_Lifecycle__c = 'Active Customer';
        insert acc_competitor;
        
        acc = new Account();
        acc.Name = 'Test Account';
        acc.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
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
            acc.GTM_Service__c = acc_competitor.id;
            acc.GTM_Ingredients__c = acc_competitor.id;
        }
        insert acc;
        
        acc_competitor.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Competitor').getRecordTypeId();
        update acc_competitor;
        
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
        model2.Sales_Organization__c = 'SAP_0111';
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
        rule.Industry_Code_From__c = '0000';
        rule.Industry_Code_To__c = '1000';
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