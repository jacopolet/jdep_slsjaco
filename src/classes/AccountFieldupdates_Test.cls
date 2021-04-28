@isTest
private class AccountFieldupdates_Test {

	private static testMethod void test() {
        //Create account record
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
        acc.Call_List__c = true;
        acc.Start_Date_Frequency__c = date.today();
        acc.Call_Frequency__c = 2;
        acc.Call_List_Next_Preferred_Date__c = date.today();
        acc.Call_List_Preferred_Day__c = 'Monday';
        
        insert acc;
        
        AccountFieldupdates.updateCheck(acc.id);
        Account acccheck = [Select Id, Call_List__c from Account where ID =: acc.Id];
        System.assert(acccheck.Call_List__c == false);
	}

}