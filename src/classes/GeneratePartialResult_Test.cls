@isTest(SeeAllData=false)
public class GeneratePartialResult_Test {
    public static Territory_Model__c model;
    
    private static void createTestData() {
        //Custom setting create value
        List<AccountTerritoryAssignmentValues__c> atavList = new List<AccountTerritoryAssignmentValues__c>();
        
        AccountTerritoryAssignmentValues__c atav1 = new AccountTerritoryAssignmentValues__c();
        atav1.Name = 'createBatchScope';
        atav1.Value__c = '200';
        atavList.add(atav1);
        
        AccountTerritoryAssignmentValues__c atav2 = new AccountTerritoryAssignmentValues__c();
        atav2.Name = 'updateBatchScope';
        atav2.Value__c = '200';
        atavList.add(atav2);
        
        AccountTerritoryAssignmentValues__c atav3 = new AccountTerritoryAssignmentValues__c();
        atav3.Name = 'deleteBatchScope';
        atav3.Value__c = '200';
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
        
        //Custom settings for validation
        ValidationRulesSettings__c validationR = new ValidationRulesSettings__c();
        validationR.AccountTerritory__c = true;
        insert validationR;
        
        //Create Territory Model
        model = new Territory_Model__c();
        model.Name = 'Test Model';
        model.Description__c = 'Test';
        model.Sales_Organization__c = 'SAP_0111';
        model.Account_Type__c = 'Customer';
        insert model;
        
        //Create Territory
        Territory__c territory = new Territory__c();
        territory.Commercial_Territory_Owner__c = UserInfo.getUserId();
        territory.Territory_Model__c = model.Id;
        territory.isChanged__c = true;
        insert territory;
        
        //Create Account with Existing Territory
        List<Account> accList = new List<Account>();

        for(integer x = 0; x < 4; x++){
            Account acc = new Account();
            acc.Name = 'Test Account' + x;
            acc.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.Customer).getRecordTypeId();
            acc.Main_Street_Only__c = 'Test Street';
            acc.Phone = '+1234567890';
            acc.CurrencyIsoCode = 'EUR';
            acc.Language__c = 'SAP_EN';
            acc.Sales_Organization__c = 'SAP_0111';
            acc.Account_Type__c = 'Customer';
            acc.Segment__c = 'SAP_A';
            acc.of_Beds__c = 10;
            acc.of_drinks__c = 10;
            acc.of_Employees_FTE__c = 10;
            acc.Exclude_from_Territory_Assignment__c = false;
            acc.of_Seats__c = 10;
            acc.of_visitors__c = 10;
            acc.Account_Lifecycle__c = 'Active Customer';
            acc.Industry_Code__c = '1000';
            acc.Main_Address_Validation_Timestamp__c = System.today()+x;
            acc.Territory__c = territory.Id;
            acc.Mini_Incoterms_Part_1__c = 'SAP_FH';
            accList.add(acc);
        }
               
        insert accList;
    }
    
    private static testMethod void testPositiveExecutePartialTerritory() {
        createTestData();
                
        system.test.startTest();
         
        ApexPages.StandardController sc = new ApexPages.standardController(model); 
        GeneratePartialResultController controller = new GeneratePartialResultController(sc);
        
        //simulate press of Generate Results button
        Pagereference pageRef = controller.refreshPage();
                
        //check status update before batch process
        Territory_Model__c updatedModel_beforeBatch = [SELECT id, Definition_Status__c FROM Territory_Model__c WHERE id = :model.id];
        system.assertEquals(updatedModel_beforeBatch.Definition_Status__c, 'Generating Results (Preview)');
        
        Territory_Model__c model = [SELECT id, name, Sales_Organization__c, Account_Type__c, RecordTypeId FROM Territory_Model__c LIMIT 1];
        
        List<Territory__c> territories = [Select ID FROM Territory__c WHERE isChanged__c = true AND Territory_Model__c = :model.id];
        Integer listPartialAccounts = [SELECT COUNT() FROM Account WHERE Territory__c IN :territories];
        
        Map<String, AccountTerritoryAssignmentValues__c> cons = null;
        cons = AccountTerritoryAssignmentValues__c.getAll();
        AccountTerritoryAssignmentValues__c consVal;
        
        TerritoryResult_PartialCreateBatch new_batPartial = new TerritoryResult_PartialCreateBatch();
        new_batPartial.modelId =  model.id;
        new_batPartial.territories = territories;
        
        consVal = cons.get('createBatchScope');
        database.executeBatch(new_batPartial, 50);
                
        system.test.stopTest();
        
        //check status update after batch process
        Territory_Model__c updatedModel_afterBatch = [SELECT id, Definition_Status__c FROM Territory_Model__c WHERE id = :model.id];
        system.assertEquals(updatedModel_afterBatch.Definition_Status__c, 'Results Generated (Preview)');
        
        //check if Territory Results are created
        List<Territory_Result__c> result = [SELECT id, name, Territory_Model__c FROM Territory_Result__c WHERE Territory_Model__c = :model.id];
        system.assertEquals(result.size(), 8);
        
    }
    
    private static testMethod void testNegativeExecutePartialTerritory() {
        createTestData();
                
        system.test.startTest();
        try {
            Territory_Model__c model = [SELECT id, name, Sales_Organization__c, Account_Type__c, RecordTypeId FROM Territory_Model__c LIMIT 1];
            
            List<Territory__c> territories = [Select ID FROM Territory__c WHERE isChanged__c = true AND Territory_Model__c = :model.id];
            Integer listPartialAccounts = [SELECT COUNT() FROM Account WHERE Territory__c IN :territories];
        
            Map<String, AccountTerritoryAssignmentValues__c> cons = null;
            cons = AccountTerritoryAssignmentValues__c.getAll();
            AccountTerritoryAssignmentValues__c consVal;
            
            TerritoryResult_PartialCreateBatch new_batPartial = new TerritoryResult_PartialCreateBatch();
            new_batPartial.modelId =  model.id;
            new_batPartial.territories = territories;
            new_batPartial.errors = 1;
            
            consVal = cons.get('createBatchScope');
            database.executeBatch(new_batPartial, 50); 
    
            system.test.stopTest();
            
            //check status update after batch process
            Territory_Model__c updatedModel_afterBatch = [SELECT id, Definition_Status__c FROM Territory_Model__c WHERE id = :model.id];
            system.assertEquals(updatedModel_afterBatch.Definition_Status__c, 'Results Generated (Preview)');
        } catch (Exception e) {
            //do nothing
        }
        
    }
    
    private static testMethod void testPositiveExecutePartialTerritoryWithExistingRule() {
        createTestData();
        Territory_Result__c result = new Territory_Result__c();
        result.Name = 'Test Result';
        result.Territory_Model__c = model.id;
        insert result;
                
        system.test.startTest();
         
        ApexPages.StandardController sc = new ApexPages.standardController(model); 
        GeneratePartialResultController controller = new GeneratePartialResultController(sc);
        
        //simulate press of Generate Results button
        Pagereference pageRef = controller.refreshPage();
                
        //check status update before batch process
        Territory_Model__c updatedModel_beforeBatch = [SELECT id, Definition_Status__c FROM Territory_Model__c WHERE id = :model.id];
        
        system.assertEquals(updatedModel_beforeBatch.Definition_Status__c, 'Generating Results (Preview)');
        
        system.test.stopTest();
    }
    
    private static testMethod void testNegative_noRule() {
        CreateTestData();
        
        system.test.startTest();
        
        ApexPages.StandardController sc = new ApexPages.standardController(model); 
        GeneratePartialResultController controller = new GeneratePartialResultController(sc);
        
        //simulate press of Generate Results button - no rules associated
        Pagereference pageRef_001 = controller.refreshPage();
        
        
        //simulate press of Back button
        Pagereference pageRef_002 = controller.returnToModelPage();
        
        system.assert(pageRef_001 != null);
        system.test.stopTest();
    }
    
}