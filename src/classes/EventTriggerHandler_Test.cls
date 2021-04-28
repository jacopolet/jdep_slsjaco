@isTest
public class EventTriggerHandler_Test {
    //Description: This is for test setup of the test class
    static void testSetup(){
        //insert custom settings
        TriggerSettings__c ts = new TriggerSettings__c();
        ts.EventTrigger__c = true;
        insert ts;
    }
    
    static void testSetupFalse(){
        //insert custom settings
        TriggerSettings__c ts = new TriggerSettings__c();
        ts.EventTrigger__c = false;
        insert ts;
    }
    
    private static testMethod void testCreateEvent() {
        
        testSetup();
        
        Campaign camp = new Campaign();
        camp.Name = 'Camp name';
        
        insert camp;
        
        Lead leadtest = new Lead();
        leadtest.Lastname = 'leadtest';
        leadtest.Touchpoint_Type__c = 'INBOUND CALL';
        leadtest.Company = 'testacce';
        leadtest.Phone = '+63912312312';
        leadtest.Campaign_Online_ID__c = camp.Id;
        insert leadtest;
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        acc.Segment__c = 'SAP_B';
        acc.Account_Lifecycle__c = 'Prospect';
        acc.IsActive__c = false;
        acc.Archiving_Flag__c = true;
        insert acc;
        
        Contact con = new Contact();
        con.Firstname = 'con';
        con.Lastname = 'name';
        con.AccountId = acc.id;
        con.function__c = 'Director';
        con.Preferred_Language__c = 'SAP_EN';
        con.Main_Commercial_Person__c = True;
        con.Email = 'test1@google.com';
        con.Phone = '+31302979111';
        con.Campaign_Online_ID__c = camp.Id;
        Insert con;
        
        Opportunity opp = new Opportunity();
        opp.Name = 'Test opp';
        opp.AccountId = acc.Id;
        opp.StageName = 'Open';
        opp.CloseDate = Date.valueOf(System.Now());
        opp.Touchpoint_Type__c = 'COMPANY CHANGE';
        insert opp;
        
        Apttus_Config2__AccountLocation__c accloc = new Apttus_Config2__AccountLocation__c();
        accloc.Apttus_Config2__AccountId__c = acc.Id;
        accloc.Name = 'accName';
        accloc.Mini_Language__c = 'SAP_EN';
        accloc.Apttus_Config2__Street__c = 'Prins Hendrikkade 123';
        accloc.Shipping_House_Number__c = '123';
        accloc.Apttus_Config2__PostalCode__c = '1011 AM';
        accloc.Apttus_Config2__City__c = 'AMSTERDAM';
        accloc.Apttus_Config2__Country__c = 'NETHERLANDS';
        insert accloc;

        Event eventRec = new Event();        
        eventRec.WhatId = acc.Id;
        eventRec.Status__c = 'Completed';
        eventRec.StartDateTime = System.Now();
        eventRec.EndDateTime = System.Now() + 1;

        insert eventRec;     
        
        Event eventRec1 = new Event();        
        eventRec1.WhatId = opp.Id;
        eventRec1.StartDateTime = System.Now();
        eventRec1.EndDateTime = System.Now() + 1;
        
        insert eventRec1;
        
        Event eventRec2 = new Event();        
        eventRec2.WhatId = accloc.Id;
        eventRec2.StartDateTime = System.Now();
        eventRec2.EndDateTime = System.Now() + 1;
        
        insert eventRec2;
        
        Event eventRec3 = new Event();        
        eventRec3.WhoId = leadtest.Id;
        eventRec3.StartDateTime = System.Now();
        eventRec3.EndDateTime = System.Now() + 1;
        
        insert eventRec3;
        
        Event eventRec4 = new Event();        
        eventRec4.WhoId = con.Id;
        eventRec4.Status__c = 'Completed';
        eventRec4.StartDateTime = System.Now();
        eventRec4.EndDateTime = System.Now() + 1;
        
        insert eventRec4;
        
        //Check if Event is created
        List<Event> evnt = [SELECT id FROM Event WHERE Id =: eventRec.id];
                                                 
        system.assertEquals(evnt.size(), 1);
            
    }
    
    static testMethod void EditDeleteUndeleteTest(){
        
        testSetup();
    
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        Account acc2 = new Account();
        acc2.Name = 'acc2222Name';
        acc2.Second_Account_Name__c = 'sAccName';
        //acc2.Sales_Office__c = 'SAP_F020';
        acc2.Phone = '+31302979111';
        insert acc2;

        Event eventRec = new Event();        
        eventRec.WhatId = acc.Id;
        eventRec.StartDateTime = System.Now();
        eventRec.EndDateTime = System.Now() + 1;

        test.startTest();
        
        insert eventRec;        
        
        //Check if Event is created
        List<Event> evnt = [SELECT id FROM Event WHERE Id =: eventRec.id];
                                                 
        system.assertEquals(evnt.size(), 1);
        
        eventRec.Subject = 'Test Event';
        eventRec.WhatId = acc2.Id;
        
        update eventRec;
        
        delete eventRec;
        
        undelete eventRec;
        
        test.stopTest();
    }
    
    static testMethod void TestTriggerOff(){
        
        testSetupFalse();
        
        EventTriggerHandler eventhandler = new EventTriggerHandler();
        TriggerDispatcher.Run(eventhandler);
        
        TriggerSettings__c ts = TriggerSettings__c.getInstance();
        system.assertEquals(false, ts.EventTrigger__c);
    
    }
}