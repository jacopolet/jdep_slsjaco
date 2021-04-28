//-------------------------------------------------------------------------------------------
// Author       :   Catherine Aragon - Accenture
// Created Date :   March 28, 2017
// Usage        :   Test Class for AccountLocation
//-------------------------------------------------------------------------------------------
@isTest
public class AccountLocation_Test {
    private static testMethod void updateSAPCustomerId() {

        insert new TriggerSettings__c(AccountLocationTrigger__c = true, BulkDataSwitch__c = true);
        
        Test.startTest();
        Account acctRec = new Account(Name = 'Test Account', Phone = '+31302979111');
        insert acctRec;
        
        Apttus_Config2__AccountLocation__c acctLoc = new Apttus_Config2__AccountLocation__c(Name='AL Test Account', 
                                                                                            Apttus_Config2__AccountId__c = acctRec.Id, 
                                                                                            Copy_of_Parent_Account__c = true);
        insert acctLoc;
        
        Account acct = new Account();
        acct = [Select ID, Name, SAP_Customer_ID__c FROM Account WHERE ID = :acctRec.Id];
        acct.SAP_Customer_ID__c = '000000000000';
        update acct;

        AccountLocation.updateAccountLocation(New Id[]{acctRec.Id});
        
        Apttus_Config2__AccountLocation__c accLocRec = [Select Id, Apttus_Config2__AccountId__c 
                                                        FROM Apttus_Config2__AccountLocation__c
                                                        WHERE ID = :acctLoc.Id];
        
        System.assertEquals(acctRec.Id, accLocRec.Apttus_Config2__AccountId__c);

        Test.stopTest();

    }
    
    private static testMethod void updateSAPCustomerIdNotCopytoParent() {

        Test.startTest();
        Account acctRec = new Account(Name = 'Test Account',  Phone = '+31302979111');
        insert acctRec;
        
        Apttus_Config2__AccountLocation__c acctLoc = new Apttus_Config2__AccountLocation__c(Name='AL Test Account', 
                                                                                            Apttus_Config2__AccountId__c = acctRec.Id);
        insert acctLoc;
        
        Account acct = new Account();
        acct = [Select ID, Name, SAP_Customer_ID__c FROM Account WHERE ID = :acctRec.Id];
        acct.SAP_Customer_ID__c = '000000000000';
        update acct;

        AccountLocation.updateAccountLocation(New Id[]{acctRec.Id});
        
        Apttus_Config2__AccountLocation__c accLocRec = [Select Id, Apttus_Config2__AccountId__c, Copy_of_Parent_Account__c
                                                        FROM Apttus_Config2__AccountLocation__c
                                                        WHERE ID = :acctLoc.Id];
        
        System.assertEquals(acctRec.Id, accLocRec.Apttus_Config2__AccountId__c);
        System.assert(accLocRec.Copy_of_Parent_Account__c == false);

        Test.stopTest();

    }
}