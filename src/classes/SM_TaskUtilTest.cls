//-------------------------------------------------------------------------------------------//
// Author       :   Glenn Serrano - Accenture
// Created Date :   November 15 2018
// Usage        :   Utility Class for Task
//
//-------------------------------------------------------------------------------------------//
@isTest
public class SM_TaskUtilTest {
    static void testSetup(){
        //insert custom settings
        TriggerSettings__c ts = new TriggerSettings__c();
        ts.TaskTrigger__c = true;
        insert ts;
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        

        List<Task> taskList = new List<Task>();
        Id serviceRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        
        for(integer x = 0; x <= 1; x++) {
            Task taskRec = new Task();
            taskRec.WhatId = acc.Id;
            taskRec.RecordTypeId = serviceRecordTypeId;
            taskList.add(taskRec);
            
        }
        
        insert taskList;
        

    }
    
    static void testSetup1(){
        //insert custom settings
        TriggerSettings__c ts = new TriggerSettings__c();
        ts.TaskTrigger__c = true;
        insert ts;
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        Operational_Tasks__c ot = new Operational_Tasks__c();
        //ot.Status__c = 'Open';
        ot.Name = 'Sample';
        insert ot;
        
        Id serviceRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        
        Task taskRec = new Task();
        taskRec.WhatId = acc.Id;
        taskRec.Operational_Tasks__c = ot.Id;
        taskRec.RecordTypeId = serviceRecordTypeId;
        insert taskRec;
        

    }
    
     private static testMethod void testUpdateTask() {
        testSetup1();

        List<Task> updateTasks = new List<Task>();
        
        List<Task> taskRecs = new List<Task>([Select Id, OwnerId, Subject, Updated_by_Trigger__c, Operational_Tasks__c, Operational_Tasks__r.Id, ActivityDate FROM Task]);
        
        for(Task updateTask : taskRecs) {
            updateTask.Description = 'Sample Description for test class';
            updateTasks.add(updateTask);
        }
        
        test.startTest();
        checkRecursive.run = true;
        update updateTasks;
        test.stopTest();
        
        List<Task> taskRecs1 = new List<Task>([Select Id, OwnerId, Subject, Updated_by_Trigger__c, Operational_Tasks__c, Operational_Tasks__r.Id, ActivityDate, Description
                                                FROM Task
                                                WHERE Id IN :updateTasks]);
    
        
        List <Id> otId = new List<Id>();
        for(Task taskrecord : taskRecs1){
            otId.add(taskrecord.Operational_Tasks__c);
        }
        
        List<Operational_Tasks__c> otRecs = new List<Operational_Tasks__c>([Select Id, Updated_by_Trigger__c, Due_Date__c, Status__c, Name, 
                                                                                        OwnerId, Segment__c, Sub_Status__c, Task_Source__c, Owner.Type
                                                                                FROM Operational_Tasks__c 
                                                                                WHERE Id IN :otId]);
                                                                                
                                                                                
        System.assert(taskRecs1[0].Description == 'Sample Description for test class');
        System.assert(taskRecs1[0].Operational_Tasks__c <> Null);
    
    }
    
    private static testMethod void testPositive() {
       
        testSetup();
        
        List<Task> taskList = new List<Task>([Select Id, Subject, WhatId, Operational_Tasks__c FROM Task]);
        
        
        System.assert(taskList[0].WhatId <> Null);
        //System.assert(taskList[0].Operational_Tasks__c <> Null);
    }
    
    private static testMethod void testDeletion() {
        testSetup();
        
        Profile p = [SELECT Id FROM Profile WHERE  Name =: 'System Administrator']; 
        User u = new User(Alias = 'standt', Email='sample@testUser1.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sample@testUser1.com', Country= 'Netherlands', Elevated_Access_Reason__c = 'Defect or Incident Resolution', Elevated_Access_Reference__c = 'ASDF');
        
        Profile p1 = [SELECT Id FROM Profile WHERE  Name =: 'System Administrator']; 
        User u1 = new User(Alias = 'standt2', Email='sample@testUser12.com', 
        EmailEncodingKey='UTF-8', LastName='Testing2', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p1.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sample@testUser12.com', Country= 'Belgium', Elevated_Access_Reason__c = 'Defect or Incident Resolution', Elevated_Access_Reference__c = 'ASDF');
        
        System.runAs(u){
            Account acc = new Account();
            acc.Name = 'accName';
            acc.Second_Account_Name__c = 'sAccName';
            acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
            acc.Phone = '+31302979111';
            acc.IsActive__c = false;
            acc.Last_Relevant_Activity_Date__c = date.today();
            insert acc;
            
            Operational_Tasks__c ot = new Operational_Tasks__c();
            ot.Status__c = 'Open';
            insert ot;
            
            Task taskRec = new Task();
            taskRec.WhatId = acc.Id;
            taskRec.Operational_Tasks__c = ot.Id;
    
            insert taskRec;
            
            try {
                delete taskRec;
                List<Task> t = new List<Task>([Select Id, Subject FROM Task WHERE Id = :taskRec.Id]);
                System.assert(t.size() == 0);
            }catch(Exception e){
                System.debug('Exception');
            }
            
        }
        
        System.runAs(u1){
            Account acc = new Account();
            acc.Name = 'accName';
            acc.Second_Account_Name__c = 'sAccName';
            acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
            acc.Phone = '+31302979111';
            insert acc;
            
            Operational_Tasks__c ot = new Operational_Tasks__c();
            ot.Status__c = 'Open';
            insert ot;
            
            Task taskRec = new Task();
            taskRec.WhatId = acc.Id;
            taskRec.Operational_Tasks__c = ot.Id;
    
            insert taskRec;
            
            try {
                delete taskRec;
                List<Task> t = new List<Task>([Select Id, Subject FROM Task WHERE Id = :taskRec.Id]);
                System.assert(t.size() == 0);
            }catch(Exception e){
                System.debug('Exception');
            }
            
        }
    }
    
    private static testMethod void testPositiveSLA1() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        acc.IsActive__c = false;
        acc.Last_Relevant_Activity_Date__c = date.newInstance(2014, 8, 8);
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'INBOUND CALL';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        Task tasks = new Task();
        tasks.Touchpoint_Type__c = 'INBOUND CALL';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'INBOUND CALL');
        
    }
    
    private static testMethod void testPositiveSLA2() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'ONLINE INFORMATION REQUEST';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        Task tasks = new Task();
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'ONLINE INFORMATION REQUEST');
        
    }
    
    private static testMethod void testPositiveSLA3() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'ONLINE QUOTE REQUEST';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        Task tasks = new Task();
        tasks.Touchpoint_Type__c = 'ONLINE QUOTE REQUEST';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'ONLINE QUOTE REQUEST');
        
    }
    
    private static testMethod void testPositiveSLA4() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'REFERRAL PARTNER';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        Task tasks = new Task();
        tasks.Touchpoint_Type__c = 'REFERRAL PARTNER';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'REFERRAL PARTNER');
        
    }
    
    private static testMethod void testPositiveSLA5() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'REFERRAL EMPLOYEE';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        Task tasks = new Task();
        tasks.Touchpoint_Type__c = 'REFERRAL EMPLOYEE';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'REFERRAL EMPLOYEE');
        
    }
    
    private static testMethod void testPositiveSLA6() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'REFERRAL TECHNICIAN';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        Task tasks = new Task();
        tasks.Touchpoint_Type__c = 'REFERRAL TECHNICIAN';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'REFERRAL TECHNICIAN');
        
    }
    
    private static testMethod void testPositiveSLA7() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'REFERRAL ROUTESALES';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        Task tasks = new Task();
        tasks.Touchpoint_Type__c = 'REFERRAL ROUTESALES';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'REFERRAL ROUTESALES');
        
    }
    
    private static testMethod void testPositiveSLA8() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'REFERRAL CUSTOMER';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        Task tasks = new Task();
        tasks.Touchpoint_Type__c = 'REFERRAL CUSTOMER';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'REFERRAL CUSTOMER');
        
    }
    
    private static testMethod void testPositiveSLA9() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'REFERRAL BUYING GROUP';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        Task tasks = new Task();
        tasks.Touchpoint_Type__c = 'REFERRAL BUYING GROUP';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'REFERRAL BUYING GROUP');
        
    }
    
    private static testMethod void testPositiveSLA10() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'COLD AQCUISITION';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        Task tasks = new Task();
        tasks.Touchpoint_Type__c = 'COLD AQCUISITION';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        Task tasks1 = new Task();
        tasks1.Touchpoint_Type__c = 'COLD AQCUISITION';
        tasks1.WhatId = acc.Id;
        tasks1.RecordTypeId = recordTypeId;
        tasks1.ActivityDate = date.today();
        tasks1.DueDateTime__c = '0:15';
       
        insert tasks;
        insert tasks1;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'COLD AQCUISITION');
        
    }
    
    private static testMethod void testPositiveSLA11() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'TAILOR-MADE AGREEMENT';
        slas.Start_Date__c = 3;
        slas.Due_Date__c = 5;
        slas.Target_Completion_Date__c = 5;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        Task tasks = new Task();
        tasks.Touchpoint_Type__c = 'TAILOR-MADE AGREEMENT';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'TAILOR-MADE AGREEMENT');
        
    }
    
    private static testMethod void testPositiveSLA12() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'STAND AGREEMENT';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        Task tasks = new Task();
        tasks.Touchpoint_Type__c = 'STAND AGREEMENT';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'STAND AGREEMENT');
        
    }
    
    private static testMethod void testPositiveSLA13() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'CMD CHANGE';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        Task tasks = new Task();
        tasks.Touchpoint_Type__c = 'CMD CHANGE';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'CMD CHANGE');
        
    }
    
    private static testMethod void testPositiveSLA14() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'SIGNED CONTRACT';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        Task tasks = new Task();
        tasks.Touchpoint_Type__c = 'SIGNED CONTRACT';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'SIGNED CONTRACT');
        
    }
    
    private static testMethod void testPositiveSLA15() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'GENERIC REQUEST';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        Task tasks = new Task();
        tasks.Touchpoint_Type__c = 'GENERIC REQUEST';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'GENERIC REQUEST');
        
    }
    
    private static testMethod void testPositiveSLA16() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'REPORT REQUEST';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        Task tasks = new Task();
        tasks.Touchpoint_Type__c = 'REPORT REQUEST';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'REPORT REQUEST');
        
    }
    
    private static testMethod void testPositiveSLA17() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'CONTACT REQUEST';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        Task tasks = new Task();
        tasks.Touchpoint_Type__c = 'CONTACT REQUEST';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'CONTACT REQUEST');
        
    }
    
    private static testMethod void testPositiveSLA18() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'OTHER REQUEST';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        Task tasks = new Task();
        tasks.Touchpoint_Type__c = 'OTHER REQUEST';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        Task tasks1 = new Task();
        tasks1.Touchpoint_Type__c = 'OTHER REQUEST';
        tasks1.WhatId = acc.Id;
        tasks1.RecordTypeId = recordTypeId;
        tasks1.ActivityDate = date.today();
        tasks1.DueDateTime__c = '0:15';
       
        insert tasks;
        insert tasks1; 
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'OTHER REQUEST');
        
    }
    
    private static testMethod void testPositiveSLA19() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'ONLINE INFORMATION REQUEST MC';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST MC';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'ONLINE INFORMATION REQUEST MC');
        
    }
    
    private static testMethod void testPositiveSLA20() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'ONLINE QUOTE REQUEST MC';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Touchpoint_Type__c = 'ONLINE QUOTE REQUEST MC';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'ONLINE QUOTE REQUEST MC');
        
    }
    
    private static testMethod void testPositiveSLA21() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'END WARR';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Touchpoint_Type__c = 'END WARR';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'END WARR');
        
    }
    
    private static testMethod void testPositiveSLA22() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'PROMOTION';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Touchpoint_Type__c = 'PROMOTION';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'PROMOTION');
        
    }
    
    private static testMethod void testPositiveSLA23() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'NEW PRODUCT INTRO';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Touchpoint_Type__c = 'NEW PRODUCT INTRO';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'NEW PRODUCT INTRO');
        
    }
    
    private static testMethod void testPositiveSLA24() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'CROSS/UP SELL';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Touchpoint_Type__c = 'CROSS/UP SELL';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'CROSS/UP SELL');
        
    }
    
    private static testMethod void testPositiveSLA25() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'PRODUCT CHANGE';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Touchpoint_Type__c = 'PRODUCT CHANGE';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'PRODUCT CHANGE');
        
    }
    
    private static testMethod void testPositiveSLA26() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'CAMPAIGN';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Touchpoint_Type__c = 'CAMPAIGN';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'CAMPAIGN');
        
    }
    
    private static testMethod void testPositiveSLA27() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'TRADE SHOW/EVENT';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Touchpoint_Type__c = 'TRADE SHOW/EVENT';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        Task tasks1 = new Task();
        tasks1.Touchpoint_Type__c = 'TRADE SHOW/EVENT';
        tasks1.WhatId = acc.Id;
        tasks1.RecordTypeId = recordTypeId;
        tasks1.Start_DateCS__c = DateTime.now();
        
        insert tasks;
        insert tasks1;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'TRADE SHOW/EVENT');
        
    }
    
    private static testMethod void testPositiveSLA28() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'NEW STARTED COMPANY';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Touchpoint_Type__c = 'NEW STARTED COMPANY';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'NEW STARTED COMPANY');
        
    }
    
    private static testMethod void testPositiveSLA29() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'COMPANY CHANGE';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Touchpoint_Type__c = 'COMPANY CHANGE';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'COMPANY CHANGE');
        
    }
    
    private static testMethod void testPositiveSLA30() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'PROSPECT LIST';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Touchpoint_Type__c = 'PROSPECT LIST';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'PROSPECT LIST');
        
    }
    
    private static testMethod void testPositiveSLA31() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'NPS';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Touchpoint_Type__c = 'NPS';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'NPS');
        
    }
    
    private static testMethod void testPositiveSLA32() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'WARM WELCOME FOLL UP';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Touchpoint_Type__c = 'WARM WELCOME FOLL UP';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'WARM WELCOME FOLL UP');
        
    }
    
     private static testMethod void testPositiveSLA33() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'FIRST ORDER SURVEY';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Touchpoint_Type__c = 'FIRST ORDER SURVEY';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'FIRST ORDER SURVEY');
        
    }
    
    private static testMethod void testPositiveSLA34() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'AFT INSTAL';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Start_DateCS__c = System.today();
        tasks.Touchpoint_Type__c = 'AFT INSTAL';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'AFT INSTAL');
        
    }
    
     private static testMethod void testPositiveSLA35() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'MOVEMNT';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Start_DateCS__c = System.today();
        tasks.Touchpoint_Type__c = 'MOVEMNT';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'MOVEMNT');
        
    }
    
    private static testMethod void testPositiveSLA36() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'KPI-SLA SETTL';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Start_DateCS__c = System.today();
        tasks.Touchpoint_Type__c = 'KPI-SLA SETTL';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'KPI-SLA SETTL');
        
    }
    
    private static testMethod void testPositiveSLA38() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'BUDGET CHECK';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Start_DateCS__c = System.today();
        tasks.Touchpoint_Type__c = 'BUDGET CHECK';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'BUDGET CHECK');
        
    }
    
    private static testMethod void testPositiveSLA39() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'ONE-TIME BONUS';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Start_DateCS__c = System.today();
        tasks.Touchpoint_Type__c = 'ONE-TIME BONUS';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'ONE-TIME BONUS');
        
    }
    
    private static testMethod void testPositiveSLA40() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'INDEXATION NON STD';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Start_DateCS__c = System.today();
        tasks.Touchpoint_Type__c = 'INDEXATION NON STD';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'INDEXATION NON STD');
        
    }
    
    private static testMethod void testPositiveSLA41() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'KPI-SLA CHECK';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Start_DateCS__c = System.today();
        tasks.Touchpoint_Type__c = 'KPI-SLA CHECK';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'KPI-SLA CHECK');
        
    }
    
    private static testMethod void testPositiveSLA42() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'P.O. NUMBER REQUEST';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Start_DateCS__c = System.today();
        tasks.Touchpoint_Type__c = 'P.O. NUMBER REQUEST';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'P.O. NUMBER REQUEST');
        
    }
    
    private static testMethod void testPositiveSLA43() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'VOLUME OBLIG SETTL';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Start_DateCS__c = System.today();
        tasks.Touchpoint_Type__c = 'VOLUME OBLIG SETTL';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'VOLUME OBLIG SETTL');
        
    }
    
    private static testMethod void testPositiveSLA44() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'VOLUME OBLIG CHECK';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Start_DateCS__c = System.today();
        tasks.Touchpoint_Type__c = 'VOLUME OBLIG CHECK';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'VOLUME OBLIG CHECK');
        
    }
    
    private static testMethod void testPositiveSLA45() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'CREDIT LIMIT ALERT';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Start_DateCS__c = System.today();
        tasks.Touchpoint_Type__c = 'CREDIT LIMIT ALERT';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'CREDIT LIMIT ALERT');
        
    }
 private static testMethod void testPositive2() {
       
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        List<Task> taskList = new List<Task>();
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        
        for(integer x = 0; x <= 1; x++) {
            Task taskRec = new Task();
            taskRec.WhatId = acc.Id;
            taskRec.Type = 'Outbound Commercial';
            taskRec.Touchpoint_Type__c = 'EXP';
            taskRec.RecordTypeId = recordTypeId;
            taskList.add(taskRec);
        }
        
        insert taskList;
        
        List<Task> taskLists = new List<Task>([Select Id, Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id IN :taskList]);
        
        
        System.assert(taskLists[0].WhatId <> Null);
        System.assert(taskLists[0].Touchpoint_Type__c == 'EXP');
    }
    
    private static testMethod void testPositive3() {
       
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        List<Task> taskList = new List<Task>();
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        for(integer x = 0; x <= 1; x++) {
            Task taskRec = new Task();
            taskRec.WhatId = acc.Id;
            taskRec.Type = 'Outbound Commercial';
            taskRec.Touchpoint_Type__c = 'EXP';
            taskRec.RecordTypeId = recordTypeId;
            taskRec.Contract_Asset_Lifetime__c = 'Contract Asset Lifetime';
            taskList.add(taskRec);
        }
        
        insert taskList;
        
        List<Task> taskLists = new List<Task>([Select Id, Subject, WhatId, Operational_Tasks__c, Contract_Asset_Lifetime__c FROM Task WHERE Id IN :taskList]);
        
        
        System.assert(taskLists[0].WhatId <> Null);
        System.assert(taskLists[0].Contract_Asset_Lifetime__c == 'Contract Asset Lifetime');
    }
    
    private static testMethod void testPopulateMainContact() {
       
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
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
        Insert con;
        
        Account acc2 = new Account();
        acc2.Name = 'accName2';
        acc2.Second_Account_Name__c = 'sAccName2';
        acc2.Sales_Organization__c = 'SAP_0333';
        acc2.Sales_Office__c = 'SAP_F020';
        acc2.Phone = '+31302979111';
        insert acc2;
        
        Contact con2 = new Contact();
        con2.Firstname = 'con2';
        con2.Lastname = 'name';
        con2.AccountId = acc2.id;
        con2.function__c = 'Director';
        con2.Preferred_Language__c = 'SAP_EN';
        con2.Main_Commercial_Person__c = True;
        con2.Email = 'test2@google.com';
        con2.Phone = '+31302989111';
        Insert con2;
        
        //List<Task> taskList = new List<Task>();
        
        //for(integer x = 0; x <= 1; x++) {
            Task taskRec = new Task();
            taskRec.WhatId = acc.Id;
            taskRec.Contract_Asset_Lifetime__c = 'Contract Asset Lifetime';
            taskRec.Type = 'Inbound Commercial';
        //    taskList.add(taskRec);
        //}
        
        insert taskRec;
        
        List<Task> taskLists = new List<Task>([Select Id, Subject, WhatId, Operational_Tasks__c, Contract_Asset_Lifetime__c FROM Task WHERE Id = :taskRec.id]);
        
        
        System.assert(taskLists[0].WhatId <> Null);
        System.assert(taskLists[0].Contract_Asset_Lifetime__c == 'Contract Asset Lifetime');
        
        taskRec.WhatId = acc2.id;
        checkRecursive.run = true;
        update taskRec;
        
    }
    private static testMethod void testPositiveSLA46() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'SUBSCR ORDER ALERT';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Touchpoint_Type__c = 'SUBSCR ORDER ALERT';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'SUBSCR ORDER ALERT');
        
    }
    private static testMethod void testPositiveSLA50() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'SUBSCR ORDER ALERT';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        Task tasks = new Task();
        tasks.Touchpoint_Type__c = 'CASE FOLL UP';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        tasks.Start_DateCS__c = date.today();
        tasks.ActivityDate = date.today();
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'CASE FOLL UP');
        
    }
    
    private static testMethod void testPositiveSLA51() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'SUBSCR ORDER ALERT';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        Task tasks = new Task();
        tasks.Touchpoint_Type__c = 'MACHINE CASE WITH NO WARRANTY';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        tasks.Start_DateCS__c = date.today();
        tasks.ActivityDate = date.today();
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'MACHINE CASE WITH NO WARRANTY');
        
    }
    private static testMethod void testPositiveSLAUpdate46() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        Account acc1 = new Account();
        acc1.Name = 'accName1';
        acc1.Second_Account_Name__c = 'sAccName1';
        acc1.Sales_Organization__c = 'SAP_0333';
        acc1.Sales_Office__c = 'SAP_F020';
        acc1.Phone = '+31302979111';
        insert acc1;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST MC';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST MC';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'SUBSCR ORDER ALERT';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'SUBSCR ORDER ALERT';
        taskRec.WhatId = acc1.Id;
        checkRecursive.run = true;
        update taskRec;
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'SUBSCR ORDER ALERT');
        
        
    }
    private static testMethod void testPositiveSLA47() {
        testSetup();
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        Lead leadtest = new Lead();
        leadtest.Lastname = 'leadtest';
        leadtest.Touchpoint_Type__c = 'INBOUND CALL';
        leadtest.Company = 'testacce';
        leadtest.Phone = '+63912312312';
        
        insert leadtest;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'CREDIT LIMIT ALERT';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Touchpoint_Type__c = 'CREDIT LIMIT ALERT';
        tasks.WhoId = leadtest.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'CREDIT LIMIT ALERT');
        
    }
    private static testMethod void testPositiveSLA48() {
        testSetup();
                
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        acc.Account_Tier__c = 'Platinum';
        insert acc;
        
        Lead leadtest = new Lead();
        leadtest.Lastname = 'leadtest';
        leadtest.Touchpoint_Type__c = 'INBOUND CALL';
        leadtest.Company = 'testacce';
        leadtest.Phone = '+63912312312';
        
        insert leadtest;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'CREDIT LIMIT ALERT';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Touchpoint_Type__c = 'ONLINE MASTER DATA CHANGE REQ';
        tasks.WhoId = leadtest.Id;
        tasks.ActivityDate = date.today();
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'ONLINE MASTER DATA CHANGE REQ');
        
    }
}