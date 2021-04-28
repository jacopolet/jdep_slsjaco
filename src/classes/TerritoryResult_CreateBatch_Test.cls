/**
 * Class Name: TerritoryResult_CreateBatch_Test
 * @author: Alvin Lomod
 * Date: 07-July-2017
 * @description: Test Class for TerritoryResult_CreateBatch
 *
 */
 
@isTest
public class TerritoryResult_CreateBatch_Test{
    
    public static boolean createRule;
    public static boolean withExistingResult;
    public static boolean badData;
    public static Territory_Model__c model;
        
    private static testMethod void TestPositive_WithoutExistingResult() {
        createRule = true;
        withExistingResult = false;
        badData = false;
        CreateTestData();
                
        system.test.startTest();
        
        Territory_Model__c model = [SELECT id, name, Sales_Organization__c, Account_Type__c, Country__c, RecordTypeId FROM Territory_Model__c LIMIT 1];
        List<Territory_Rule__c> rule = new List<Territory_Rule__c>();
        Map<String, List<Territory_Rule__c>> ruleMap = new Map<String, List<Territory_Rule__c>>();
        boolean noRule;
        
        String[] SegmentValues;
        
        for(Territory_Rule__c ruleRec : [SELECT id, Segment__c, Territory_Model__c, Beds_From__c, Beds_To__c, Drinks_From__c, Drinks_To__c,
                                         Employees_From__c, Employees_To__c, Seats_From__c, Seats_To__c, Assigned_Owner__c, Assigned_Territory__c,
                                         Assigned_Territory__r.Commercial_Territory_Owner__c, Account_Lifecycle__c, Visitors_From__c, Visitors_To__c,
                                         Postal_Code_From__c, Postal_Code_To__c, Industry_Code_From__c, Industry_Code_To__c, Territory_Model__r.Country__c
                                         FROM Territory_Rule__c]){
            
            //split segment values since it is a multi-select picklist and may contain more than one values
            if(ruleRec.Segment__c != null){
                SegmentValues = ruleRec.Segment__c.split(';');
                
                for(String seg : SegmentValues){
                    if(ruleMap.containsKey(seg)){
                        List<Territory_Rule__c> ruleList = ruleMap.get(seg);
                        ruleList.add(ruleRec);
                        ruleMap.put(seg, ruleList);
                    }else{
                        ruleMap.put(seg, new List<Territory_Rule__c> {ruleRec});
                    }
                }
            }
        }
        
        Map<String, AccountTerritoryAssignmentValues__c> cons = null;
        cons = AccountTerritoryAssignmentValues__c.getAll();
        AccountTerritoryAssignmentValues__c consVal;
        
        TerritoryResult_CreateBatch new_bat = new TerritoryResult_CreateBatch();
        new_bat.modelId =  model.id;
        new_bat.modelCountry =  model.Country__c;
        new_bat.modelAccountType =  model.Account_Type__c;
        new_bat.ruleMap = ruleMap;
        
        consVal = cons.get('createBatchScope');
        database.executeBatch(new_bat, 2000);
                
        system.test.stopTest();
        
        //check status update after batch process
        Territory_Model__c updatedModel_afterBatch = [SELECT id, Definition_Status__c FROM Territory_Model__c WHERE id = :model.id];
        system.assertEquals(updatedModel_afterBatch.Definition_Status__c, 'Results Generated (Preview)');
        
        //check if Territory Results are created
        List<Territory_Result__c> result = [SELECT id, name, Territory_Model__c FROM Territory_Result__c WHERE Territory_Model__c = :model.id];
        system.assertEquals(result.size(), 6);
        
    }
    
    private static testMethod void TestNegative_BadData() {
        createRule = true;
        withExistingResult = false;
        badData = true;
        CreateTestData();
        
        system.test.startTest();
        
        Territory_Model__c model = [SELECT id, name, Sales_Organization__c, Account_Type__c, Country__c, RecordTypeId FROM Territory_Model__c LIMIT 1];
        List<Territory_Rule__c> rule = new List<Territory_Rule__c>();
        Map<String, List<Territory_Rule__c>> ruleMap = new Map<String, List<Territory_Rule__c>>();
        boolean noRule;
        
        String[] SegmentValues;
        
        for(Territory_Rule__c ruleRec : [SELECT id, Segment__c, Territory_Model__c, Beds_From__c, Beds_To__c, Drinks_From__c, Drinks_To__c,
                                         Employees_From__c, Employees_To__c, Seats_From__c, Seats_To__c, Assigned_Owner__c, Assigned_Territory__c,
                                         Assigned_Territory__r.Commercial_Territory_Owner__c, Account_Lifecycle__c, Visitors_From__c, Visitors_To__c,
                                         Postal_Code_From__c, Postal_Code_To__c, Industry_Code_From__c, Industry_Code_To__c, Territory_Model__r.Country__c
                                         FROM Territory_Rule__c]){
            
            //split segment values since it is a multi-select picklist and may contain more than one values
            if(ruleRec.Segment__c != null){
                SegmentValues = ruleRec.Segment__c.split(';');
                
                for(String seg : SegmentValues){
                    if(ruleMap.containsKey(seg)){
                        List<Territory_Rule__c> ruleList = ruleMap.get(seg);
                        ruleList.add(ruleRec);
                        ruleMap.put(seg, ruleList);
                    }else{
                        ruleMap.put(seg, new List<Territory_Rule__c> {ruleRec});
                    }
                }
            }
        }
        
        Map<String, AccountTerritoryAssignmentValues__c> cons = null;
        cons = AccountTerritoryAssignmentValues__c.getAll();
        AccountTerritoryAssignmentValues__c consVal;
        
        TerritoryResult_CreateBatch new_bat = new TerritoryResult_CreateBatch();
        new_bat.modelId =  model.id;
        new_bat.modelCountry =  model.Country__c;
        new_bat.modelAccountType =  model.Account_Type__c;
        new_bat.ruleMap = ruleMap;
        
        consVal = cons.get('createBatchScope');
        try{
            database.executeBatch(new_bat, 2000);
        }
        catch(Exception ex){
        
        }
                
        system.test.stopTest();
        
        //check status update after batch process
        Territory_Model__c updatedModel_afterBatch = [SELECT id, Definition_Status__c FROM Territory_Model__c WHERE id = :model.id];
        system.assertEquals(updatedModel_afterBatch.Definition_Status__c, 'Results Generated (Preview)');
        
        //check if Territory Results are created
        List<Territory_Result__c> result = [SELECT id, name, Territory_Model__c FROM Territory_Result__c WHERE Territory_Model__c = :model.id];
        system.assertEquals(result.size(), 0);
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
            acc.Main_Country__c = 'Netherlands';
            acc.Account_Type__c = 'Customer';
            acc.Segment__c = 'SAP_A';
            acc.of_Beds__c = 10;
            acc.of_drinks__c = 10;
            acc.of_Employees_FTE__c = 10;
            acc.Exclude_from_Territory_Assignment__c = false;
            //acc.Area_Code__c = 1000;
            acc.of_Seats__c = 10;
            acc.of_visitors__c = 10;
            acc.Account_Lifecycle__c = 'Active Customer';
            if(badData){
                acc.Main_Postal_Code__c = 'AAAA';
            }else{
                acc.Main_Postal_Code__c = '1000';
            }
            acc.Industry_Code__c = '1000';
            acc.Main_Address_Validation_Timestamp__c = System.today()+x;
            accList.add(acc);
        }
        accList[1].Exclude_from_Territory_Assignment__c = true;
        accList[1].Main_Postal_Code__c = null;
        accList[1].Industry_Code__c = null;        
        accList[3].of_Beds__c = 99;
        accList[3].of_drinks__c = 99;
        accList[3].of_Employees_FTE__c = 99;
        accList[3].of_Seats__c = 99;
        accList[3].of_visitors__c = 99;
        accList[3].Main_Postal_Code__c = '9999';
        accList[3].Industry_Code__c = '9999';
        
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
                rule.Industry_Code_From__c = '0000';
                rule.Industry_Code_To__c = '1000';
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
        }

    }
}