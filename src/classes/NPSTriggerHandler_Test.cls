@isTest
public class NPSTriggerHandler_Test {
    //Description: This is for test setup of the test class
    static void testSetup(){
        //insert custom settings
        TriggerSettings__c ts = new TriggerSettings__c();
        ts.NPSDetailTrigger__c = true;
        insert ts;
        
        Profile p = [SELECT Id FROM Profile WHERE  Name =: 'System Administrator']; 
        User u = new User(Alias = 'standt', Email='sample@testUser1.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sample@testUser11.com', Sales_Organization__c = 'SAP_0333', Country= 'Netherlands',
        Elevated_Access_Reason__c = 'Defect or Incident Resolution', Elevated_Access_Reference__c = 'ASDF');
        insert u;
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        acc.Customer_Relations_1__c = u.Id;
        insert acc;
        
        NPS__c npsRec = new NPS__c();
        npsRec.Account__c = acc.Id;
        insert npsRec;

    }
    
    private static testMethod void createTaskOnNPS() { 
        testSetup();
        
        List<NPS__c> npsRecords = new List<NPS__c>([Select Id, Name, Account__r.Name, Account__r.Customer_Relations_1__c
                                                    FROM NPS__c]);
        
        System.assert(npsRecords[0].Account__r.Name == 'accName');
        System.assert(npsRecords[0].Account__r.Customer_Relations_1__c <> Null);
        
        NPSTriggerHandler npsDetail = new NPSTriggerHandler();

        List<SObject> newItems;
        List<SObject> oldList;
        Map<Id, SObject> oldItems;
        List<SObject> newList;
        Map<Id, SObject> newItemsMap;
        
        npsDetail.BeforeInsert(newItems); 
        npsDetail.BeforeDelete(oldList, oldItems);
        npsDetail.BeforeUpdate(newList, newItemsMap, oldList, oldItems);
        npsDetail.AfterUpdate(newList, newItemsMap, oldList, oldItems);
        npsDetail.AfterDelete(oldList, oldItems);
        npsDetail.AfterUndelete(newList, newItemsMap);
                                                
        
    }
}