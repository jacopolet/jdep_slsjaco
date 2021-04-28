@isTest
public class SM_AccountUnlockApproval_Test {
	public static testMethod void unlockApproval() {
        List<Account> accList = new List<Account>();
        Account acc2 = new Account();
        acc2.Name = 'Test Account';
        acc2.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.Customer).getRecordTypeId();
        acc2.Main_Street_Only__c = 'Test Street';
        acc2.Main_Postal_Code__c = null;
        acc2.Industry_Code__c = null;
        acc2.Phone = '+1234567890';
        acc2.CurrencyIsoCode = 'EUR';
        acc2.Language__c = 'SAP_EN';
        acc2.Sales_Organization__c = 'SAP_0333';
        acc2.Account_Type__c = 'Customer';
        acc2.Segment__c = 'SAP_A'; //Indicator for change of rule
        acc2.of_Beds__c = 10;
        acc2.of_drinks__c = 10;
        acc2.of_Employees_FTE__c = 10;
        acc2.Exclude_from_Territory_Assignment__c = false;
        acc2.of_Seats__c = 10;
        acc2.Account_Lifecycle__c = 'Active Customer';
        accList.add(acc2);
        
        insert accList;
        
        //Update Account
        accList[0].Commercial_Register_Number__c = '9873291829380923';
        accList[0].Approval_Required__c = true;
        checkrecursive.run = true;
        update accList;
        Approval.LockResult urList = Approval.lock(accList[0]);
        SM_AccountUnlockApproval.unlockApproval(New Id[]{accList[0].Id});
        
        Account accResIns = [SELECT Id, Approval_Required__c FROM Account WHERE Id =: accList[0].Id LIMIT 1];
        System.assert(accResIns.Approval_Required__c == true);
        
     }
}