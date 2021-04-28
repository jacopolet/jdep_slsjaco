@isTest
public without sharing class SM_DuplicateCheckerHandlerTest {
    
    private static testMethod void duplicatechecknegative() {
        List<SM_DuplicateCheckHandler.variableReceiver> varreclist = new List<SM_DuplicateCheckHandler.variableReceiver>();
        List<Boolean> result = new List<Boolean>();
        SM_DuplicateCheckHandler.variableReceiver varrec = new SM_DuplicateCheckHandler.variableReceiver();
        varrec.maincity = 'asdf';
        varrec.maincountry = 'asdf';
        varrec.mainpostalcode = 'asdf';
        varrec.mainhousenumber = 'asdf';
        varrec.mainstreetonly = 'asdf';
        varrec.mainhousenumbersupplement = 'asdf';
        
        varreclist.add(varrec);
        result = SM_DuplicateCheckHandler.findduplicate(varreclist);
        System.assertEquals(false, result[0]);
    }
    
    private static testMethod void duplicatecheckpositive() {
        List<SM_DuplicateCheckHandler.variableReceiver> varreclist = new List<SM_DuplicateCheckHandler.variableReceiver>();
        List<Boolean> result = new List<Boolean>();
        
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.Customer).getRecordTypeId();
        acc.Main_Street_Only__c = 'Test Street';
        acc.Main_Postal_Code__c = null;
        acc.Industry_Code__c = null;
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
        acc.of_Seats__c = 10;
        acc.Account_Lifecycle__c = 'Active Customer';
        acc.SAP_PO_Updated__c = false;
        acc.Main_City__c = 'Amsterdam';
        acc.Main_House_Number__c = '1';
        acc.Main_Postal_Code__c = '1071 XX';
        acc.Main_Street_Only__c = 'Museumstraat';
        acc.Main_Country__c = 'Netherlands';
        
        insert acc;
        
        SM_DuplicateCheckHandler.variableReceiver varrec = new SM_DuplicateCheckHandler.variableReceiver();
        varrec.maincity = 'Amsterdam';
        varrec.maincountry = 'Netherlands';
        varrec.mainpostalcode = '1071 XX';
        varrec.mainhousenumber = '1';
        varrec.mainstreetonly = 'Museumstraat';
        
        varreclist.add(varrec);
        result = SM_DuplicateCheckHandler.findduplicate(varreclist);
        System.assertEquals(true, result[0]);
    }
}