/**
    * @author        Alvin Lomod
    * @date          07.02.2018 - Alvin Lomod KASM-1017         
    * @description   Test Class of UpdateTaskContacts
    * @revision(s)   
    */
@isTest
private class UpdateTaskContactsTest {
    
    private static testMethod void UpdateTaskContactRelation(){
        
        insert new ProcessBuilderSettings__c(TaskPBFlows__c = true);
        
        Account acc1 = new Account();
        acc1.Name = 'Test Account';
        acc1.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.Customer).getRecordTypeId();
        acc1.Main_Street_Only__c = 'Test Street';
        acc1.Main_Postal_Code__c = '1000';
        acc1.Industry_Code__c = '100';
        acc1.Phone = '+1234567890';
        acc1.CurrencyIsoCode = 'EUR';
        acc1.Language__c = 'SAP_EN';
        acc1.Sales_Organization__c = 'SAP_0333';
        acc1.Account_Type__c = 'Customer';
        acc1.Segment__c = 'SAP_A'; //Indicator for change of rule
        acc1.of_Beds__c = 10;
        acc1.of_drinks__c = 10;        
        acc1.of_Employees_FTE__c = 10;
        acc1.Exclude_from_Territory_Assignment__c = false;
        acc1.of_Seats__c = 10;
        acc1.Account_Lifecycle__c = 'Active Customer';
        
        insert acc1;
        
        List<Contact> conList = new List<Contact>();
        Contact con;
        for(Integer i = 0; i < 3; i++){
            
            con = new Contact();
            con.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(SM_Constants.ContactStandard).getRecordTypeId();
            con.AccountId = acc1.Id;
            con.Function__c = 'Director';
            con.Preferred_Language__c = 'SAP_EN';
            con.Email = 'test'+ String.valueOf(i)+ '@test.com';
            con.FirstName = 'FirstTest' + i;
            con.LastName = 'LastTest' + i;
            conList.add(con);
            
        }
        
        conList[0].Phone = '+02139141203';
        conList[0].Last_Relevant_Activity_Date__c = Date.Today().addDays(-2);
        conList[1].Phone = '+02139141432';
        conList[1].Last_Relevant_Activity_Date__c = Date.Today().addDays(-2);
        conList[1].IsActive__c = false;
        conList[1].Archiving_Flag__c = true;
        conList[2].Phone = '+02139141598';
        conList[2].Last_Relevant_Activity_Date__c = Date.Today().addDays(4);
        
        insert conList;
        
        Task ts = new Task();
        ts.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get(SM_Constants.RTInbound).getRecordTypeId();
        ts.Subject = 'Meeting';
        ts.Touchpoint_Type__c = 'INBOUND CALL';
        ts.Start_DateCS__c = DateTime.now().addDays(1).addHours(1);
        ts.Task_Expiration_Date__c = DateTime.now().addDays(1).addHours(3);
        ts.Priority = 'Low';
        ts.WhoId = conList[0].id;
        
        insert ts;
        
        List<TaskRelation> trList = new List<TaskRelation>();
        TaskRelation tr;
        for(Integer i = 1; i < 3; i++){
            
            tr = new TaskRelation();
            tr.TaskId = ts.Id;
            tr.RelationId = conList[i].Id;
            trList.add(tr);
            
        }
        
        insert trList;
        
    
        ts.Priority = 'Medium';
        update ts;        
        
        List<Contact> updatedConList = [SELECT Id, Last_Relevant_Activity_Date__c, IsActive__c, Archiving_Flag__c FROM Contact];
        system.assertEquals(updatedConList[0].Last_Relevant_Activity_Date__c, Date.Today());
        system.assertEquals(updatedConList[1].Last_Relevant_Activity_Date__c, Date.Today());
        system.assertEquals(updatedConList[1].IsActive__c, true);
        system.assertEquals(updatedConList[1].Archiving_Flag__c, false);
        system.assertEquals(updatedConList[2].Last_Relevant_Activity_Date__c, Date.Today().addDays(4));
        
    }
    
}