@isTest
public class OpportunityTriggerHandler_Test {
    //Description: This is for test setup of the test class
    static void testSetup(){
        //insert custom settings
        TriggerSettings__c ts = new TriggerSettings__c();
        ts.OpportunityTrigger__c = true;
        insert ts;

    }
    
    static void testSetupFalse(){
        //insert custom settings
        TriggerSettings__c ts = new TriggerSettings__c();
        ts.OpportunityTrigger__c = false;
        insert ts;

    }
    
    private static testMethod void testPositive() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        acc.RecordTypeId = SM_Constants.recordTypeIdProspectValid;
        insert acc;
        
        Task tsk = new Task();
        
        Task taskRec = new Task();
        tsk.WhatId = acc.Id;
                
        insert tsk;
       
        Opportunity opp = new Opportunity();
        opp.Name = 'oppName';
        opp.AccountId = acc.id;
        opp.Task_Id__c = tsk.id;
        opp.CLoseDate = Date.Today();
        opp.StageName = 'Open';
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(SM_Constants.OppStandardRT).getRecordTypeId();
        opp.Sales_Organization__c = 'SAP_0333';
        test.startTest();
        
        insert opp;
        update opp;
                
        //Check if Opportunity is created
        List<Opportunity> oppty = [SELECT id FROM Opportunity WHERE Id =: opp.id];
                                                 
        system.assertEquals(oppty.size(), 1);
        
        delete opp;
        undelete opp;
        
        test.stopTest();
    }    
    
    private static testMethod void testPositiveOneContact() {
        testSetup();
    
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        Contact con1 = new Contact();
        
        Con1.FirstName = 'Jed';
        Con1.LastName = 'Samaniego';
        Con1.AccountId = acc.id;
        Con1.Phone = '+31302979111';
        Con1.Main_Commercial_Person__c = True;
        Con1.MobilePhone = '+31302979122';
                
        insert con1;
        
        Task tsk = new Task();
        
        Task taskRec = new Task();
        tsk.WhatId = acc.Id;
        tsk.WhoId = con1.id;
                
        insert tsk;
       
        Opportunity opp = new Opportunity();
        opp.Name = 'oppName';
        opp.AccountId = acc.id;
        opp.Task_Id__c = tsk.id;
        opp.CLoseDate = Date.Today();
        opp.StageName = 'Open';
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(SM_Constants.OppStandardRT).getRecordTypeId();

        test.startTest();
        
        insert opp;
        
        //Check if Opportunity is created
        List<Opportunity> oppty = [SELECT id FROM Opportunity WHERE Id =: opp.id];
                 
        system.assertEquals(oppty.size(), 1);
        
        test.stopTest();
    }
    
    private static testMethod void testStampLastRelevantActivityDate() {
        testSetup();
    
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        acc.Archiving_Flag__c = true;
        insert acc;
        
        Contact con1 = new Contact();
        
        Con1.FirstName = 'Jed';
        Con1.LastName = 'Samaniego';
        Con1.AccountId = acc.id;
        Con1.Phone = '+31302979111';
        Con1.Main_Commercial_Person__c = True;
        Con1.MobilePhone = '+31302979122';
        Con1.IsActive__c = false;
        Con1.Archiving_Flag__c = true;
                
        insert con1;
        
        Task tsk = new Task();
        
        Task taskRec = new Task();
        tsk.WhatId = acc.Id;
        tsk.WhoId = con1.id;
                
        insert tsk;
       
        Opportunity opp = new Opportunity();
        opp.Name = 'oppName';
        opp.AccountId = acc.id;
        opp.Task_Id__c = tsk.id;
        opp.CLoseDate = Date.Today();
        opp.StageName = 'Open';
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(SM_Constants.OppStandardRT).getRecordTypeId();

        test.startTest();
        
        insert opp;
        
        
        //Check if Opportunity is created
        List<Opportunity> oppty = [SELECT id FROM Opportunity WHERE Id =: opp.id];
                                                 
        system.assertEquals(oppty.size(), 1);
        
        test.stopTest();
    }
    
    private static testMethod void testStampLastRelevantActivityDatepastdate() {
        testSetup();
    
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        acc.Archiving_Flag__c = true;
        acc.Last_Relevant_Activity_Date__c = date.today()-1;
        insert acc;
        
        Contact con1 = new Contact();
        
        Con1.FirstName = 'Jed';
        Con1.LastName = 'Samaniego';
        Con1.AccountId = acc.id;
        Con1.Phone = '+31302979111';
        Con1.Main_Commercial_Person__c = True;
        Con1.MobilePhone = '+31302979122';
                
        insert con1;
        
        Task tsk = new Task();
        
        Task taskRec = new Task();
        tsk.WhatId = acc.Id;
        tsk.WhoId = con1.id;
                
        insert tsk;
       
        Opportunity opp = new Opportunity();
        opp.Name = 'oppName';
        opp.AccountId = acc.id;
        opp.Task_Id__c = tsk.id;
        opp.CLoseDate = Date.Today();
        opp.StageName = 'Open';
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(SM_Constants.OppStandardRT).getRecordTypeId();

        test.startTest();
        
        insert opp;
        
        //Check if Opportunity is created
        List<Opportunity> oppty = [SELECT id FROM Opportunity WHERE Id =: opp.id];
                                                 
        system.assertEquals(oppty.size(), 1);
        
        test.stopTest();
    }
    
    private static testMethod void testPositiveNoContact() {
        testSetup();
    
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        Account acc2 = new Account();
        acc2.Name = 'accName two';
        acc2.Second_Account_Name__c = 'sAccName';
        //acc2.Sales_Office__c = 'SAP_F020';
        acc2.Phone = '+31302979111';
        insert acc2;
        
        Contact con1 = new Contact();
        Con1.FirstName = 'Jed';
        Con1.LastName = 'Samaniego';
        Con1.AccountId = acc.id;
        Con1.Phone = '+31302979111';
        Con1.Main_Commercial_Person__c = True;
        Con1.MobilePhone = '+31302979122';
        
        Task tsk = new Task();
        
        Task taskRec = new Task();
        tsk.WhatId = acc.Id;
                
        insert tsk;
       
        Opportunity opp = new Opportunity();
        opp.Name = 'oppName';
        opp.AccountId = acc.id;
        opp.Task_Id__c = tsk.id;
        opp.CLoseDate = Date.Today();
        opp.StageName = 'Open';
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(SM_Constants.OppStandardRT).getRecordTypeId();
        
        test.startTest();
        
        insert opp;
        
        //Check if Opportunity is created
        List<Opportunity> oppty = [SELECT id FROM Opportunity WHERE Id =: opp.id];
                                                 
        system.assertEquals(oppty.size(), 1);
        
        test.stopTest();
    }
    
    private static testMethod void testPositiveMultiConNoMCP() {
        testSetup();
    
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        Account acc2 = new Account();
        acc2.Name = 'accName two';
        acc2.Second_Account_Name__c = 'sAccName';
        //acc2.Sales_Office__c = 'SAP_F020';
        acc2.Phone = '+31302979111';
        insert acc2;
        
        List<Contact> conList = new List<Contact>();
        Contact con;
        for(Integer i = 0; i < 3; i++){
            
            con = new Contact();
            con.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(SM_Constants.ContactStandard).getRecordTypeId();
            con.AccountId = acc.Id;
            con.Function__c = 'Director';
            con.Preferred_Language__c = 'SAP_EN';
            con.Email = 'test'+ String.valueOf(i)+ '@test.com';
            con.FirstName = 'FirstTest' + i;
            con.LastName = 'LastTest' + i;
            Con.Main_Commercial_Person__c = True;
            conList.add(con);
            
        }
        
        conList[0].Phone = '+02139141203';
        conList[1].Phone = '+02139141432';
        conList[1].Archiving_Flag__c = true;
        conList[2].Phone = '+02139141598';
        
        
        insert conList;
        
        Task tsk = new Task();
        
        Task taskRec = new Task();
        tsk.WhatId = acc.Id;
        tsk.WhoId = conList[0].id;
                
        insert tsk;
        
        List<TaskRelation> trList = new List<TaskRelation>();
        TaskRelation tr;
        for(Integer i = 1; i < 3; i++){
            
            tr = new TaskRelation();
            tr.TaskId = tsk.Id;
            tr.RelationId = conList[i].Id;
            tr.IsWhat = false;
            trList.add(tr);
            
        }
        
        insert trList;
       
        Opportunity opp = new Opportunity();
        opp.Name = 'oppName';
        opp.AccountId = acc.id;
        opp.Task_Id__c = tsk.id;
        opp.CLoseDate = Date.Today();
        opp.StageName = 'Open';
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(SM_Constants.OppStandardRT).getRecordTypeId();

        test.startTest();
        
        insert opp;
        
        //Check if Opportunity is created
        List<Opportunity> oppty = [SELECT id FROM Opportunity WHERE Id =: opp.id];
                                                 
        system.assertEquals(oppty.size(), 1);
        
        test.stopTest();
    }
    
    static testMethod void EditDeleteUndeleteTest(){
        
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        Task tsk = new Task();
        
        Task taskRec = new Task();
        tsk.WhatId = acc.Id;
                
        insert tsk;
       
        Opportunity opp = new Opportunity();
        opp.Name = 'oppName';
        opp.AccountId = acc.id;
        opp.Task_Id__c = tsk.id;
        opp.CLoseDate = Date.Today();
        opp.StageName = 'Open';
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(SM_Constants.OppStandardRT).getRecordTypeId();

        test.startTest();
        SM_OpportunityUtil.hasException = true;
        insert opp;
        delete opp;
        undelete opp;
        
        //Check if Opportunity is created
        List<Opportunity> oppty = [SELECT id FROM Opportunity WHERE Id =: opp.id];
                                                 
        system.assertEquals(oppty.size(), 1);
        
        
        test.stopTest();
    }
    
    static testMethod void TestTriggerOff(){
        
        testSetupFalse();
        
        OpportunityTriggerHandler opphandler = new OpportunityTriggerHandler();
        TriggerDispatcher.Run(opphandler);
        
        TriggerSettings__c ts = TriggerSettings__c.getInstance();
        system.assertEquals(false, ts.OpportunityTrigger__c);
    
    }
    
    private static testMethod void testOneTimeNOSCalculation() {
        testSetup();
        List<Opportunity> opptyList = new List<Opportunity>();
        
        Account acc = new Account();
        acc.Name = 'Account Name';
        acc.Phone = '+31302979111';
        acc.RecordTypeId = Label.Prospect_Record_Type_Id;
        acc.Last_Relevant_Activity_Date__c = null;
        
        insert acc;
               
        Opportunity opp = new Opportunity();
        opp.Name = 'Opportunity Name';
        opp.AccountId = acc.id;
        opp.CLoseDate = Date.Today();
        opp.StageName = 'Open';
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(SM_Constants.OppStandardRT).getRecordTypeId();
        opp.Percentage_Rewarded__c = 100;
        
        Opportunity opp1 = new Opportunity();
        opp1.Name = 'Opportunity Name 1';
        opp1.AccountId = acc.id;
        opp1.CLoseDate = Date.Today();
        opp1.StageName = 'Open';
        opp1.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(SM_Constants.OppStandardRT).getRecordTypeId();
        opp.Percentage_Rewarded__c = 100;
        
        opptyList.add(opp);
        opptyList.add(opp1);
        
        test.startTest();
        SM_OpportunityUtil.hasException = false;
        insert opptyList;
        
        Opportunity oppty = [SELECT id, amount FROM Opportunity WHERE Id =: opptyList[0].id];                                                 
        system.assertEquals(0.00, oppty.Amount);
        
        Opportunity oppty1 = [SELECT id, amount FROM Opportunity WHERE Id =: opptyList[1].id];                                                 
        system.assertEquals(0.00, oppty1.Amount);
        
        opptyList[0].One_Time_NOS__c = 10.00;
        opptyList[0].CloseDate = Date.Today();
        opptyList[1].One_Time_NOS__c = 10.00;
        
        update opptyList;
        
        Opportunity updtOppty = [SELECT id, amount, Expected_Revenue_Start_Date__c, CloseDate FROM Opportunity WHERE Id =: opptyList[0].id];                                                 
        system.assertEquals(10.00, updtOppty.Amount);
        system.assertEquals(updtOppty.Expected_Revenue_Start_Date__c, updtOppty.CloseDate);
        
        Opportunity updtOppty1 = [SELECT id, amount FROM Opportunity WHERE Id =: opptyList[1].id];    
        system.assertEquals(10.00, updtOppty1.Amount);
        test.stopTest();
    }
    
}