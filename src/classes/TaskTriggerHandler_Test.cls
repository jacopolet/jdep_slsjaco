@isTest
public class TaskTriggerHandler_Test {
    //Description: This is for test setup of the test class
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
        acc.Account_Tier__c = 'Platinum';
        insert acc;
        

        List<Task> taskList = new List<Task>();
        Id serviceRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        
        for(integer x = 0; x <= 1; x++) {
            Task taskRec = new Task();
            taskRec.WhatId = acc.Id;
            taskRec.RecordTypeId = serviceRecordTypeId;
            taskRec.SAP_HANA_Queue_Task__c = true;
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
        SM_CheckRecursive.run = true;
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
            insert acc;
            
            Operational_Tasks__c ot = new Operational_Tasks__c();
            ot.Status__c = 'Open';
            insert ot;
            
            Task taskRec = new Task();
            taskRec.WhatId = acc.Id;
            taskRec.Operational_Tasks__c = ot.Id;
    
            insert taskRec;
            
            try {
                SM_CheckRecursive.run = true;
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
    
    private static testMethod void SLAUPDATENEWTT() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'CREDIT CHECK';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'Manual';
        tasks.Touchpoint_Type__c = 'CREDIT CHECK';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'CREDIT CHECK');
        
    }
    
     private static testMethod void SLAUPDATENEWTT2() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'REMINDER';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'Manual';
        tasks.Touchpoint_Type__c = 'REMINDER';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'REMINDER');
        
    }
    
    private static testMethod void testPositiveSLA1() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
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
        tasks.Task_Source__c = 'Manual';
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
        tasks.Task_Source__c = 'Manual';
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
        tasks.Task_Source__c = 'Manual';
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
        tasks.Task_Source__c = 'Manual';
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
        tasks.Task_Source__c = 'Manual';
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
        tasks.Task_Source__c = 'Manual';
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
        tasks.Task_Source__c = 'Manual';
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
        tasks.Task_Source__c = 'Manual';
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
        tasks.Task_Source__c = 'Manual';
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
        tasks.Task_Source__c = 'Manual';
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
        tasks.Task_Source__c = 'Manual';
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
        tasks.Task_Source__c = 'Manual';
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
        tasks.Task_Source__c = 'Manual';
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
        tasks.Task_Source__c = 'Manual';
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
        tasks.Task_Source__c = 'Manual';
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
        tasks.Task_Source__c = 'Manual';
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
        tasks.Task_Source__c = 'Manual';
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
        tasks.Task_Source__c = 'Manual';
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
        tasks.Task_Source__c = 'SFDC';
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
        
        Id recTypeIdALValid = Schema.SObjectType.Apttus_Config2__AccountLocation__c.getRecordTypeInfosByName().get('Account Location Valid').getRecordTypeId();
        
        Apttus_Config2__AccountLocation__c accLoc = new Apttus_Config2__AccountLocation__c();
        accLoc.RecordTypeId = recTypeIdALValid;
        accLoc.Apttus_Config2__AccountId__c = acc.Id;
        accLoc.Shipping_Address_Validation_Code__c = '90379120udojdl';
        accLoc.Shipping_Address_Validation_Timestamp__c = date.Today();
        accLoc.Shipping_Address_Validation_Pending__c = false;
        accLoc.Address_Validation__c = 'Valid';
        accLoc.Customer_calendar_key__c = 'SAP_32';
        accLoc.Mini_Language__c = 'SAP_SR';
        //accLoc.Pallet_type__c = 'SAP_004';
        accLoc.Apttus_Config2__City__c = 'City';
        accLoc.Apttus_Config2__Country__c = 'Country';
        accLoc.Shipping_Country_ISO__c = 'Country ISO';
        accLoc.Shipping_House_Number__c = 'House Number';
        accLoc.Apttus_Config2__PostalCode__c = 'PostalCode';
        accLoc.Apttus_Config2__State__c = 'State';
        //accLoc.Shipping_Street__c = 'Street';
        accLoc.Shipping_Street_Only__c = 'Street Only';
        accLoc.Saturday_Afternoon_From_Receiving__c = '13:30';
        accLoc.Saturday_Afternoon_To_Receiving__c = '12:45';
        accLoc.Saturday_Morning_From_Receiving__c = '01:45';
        accLoc.Saturday_Morning_To_Receiving__c = '01:15';
        accLoc.Sunday_Afternoon_From_Receiving__c = '14:15';
        accLoc.Sunday_Afternoon_To_Receiving__c = '14:30';
        accLoc.Sunday_Morning_From_Receiving__c = '00:30';
        accLoc.Sunday_Morning_To_Receiving__c = '   03:00';
        
        insert accloc;
        
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
        tasks.Task_Source__c = 'SFDC';
        tasks.Touchpoint_Type__c = 'ONLINE QUOTE REQUEST MC';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Task tasks1 = new Task();
        tasks1.Task_Source__c = 'SFDC';
        tasks1.Touchpoint_Type__c = 'ONLINE QUOTE REQUEST MC';
        tasks1.WhatId = accloc.Id;
        tasks1.RecordTypeId = recordTypeId;
        
       
        insert tasks1;
        
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
        tasks.Task_Source__c = 'SFDC';
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
        tasks.Task_Source__c = 'SFDC';
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
        tasks.Task_Source__c = 'SFDC';
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
        slas.Name = 'DEEP/CROSS/UP SELL';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'SFDC';
        tasks.Touchpoint_Type__c = 'DEEP/CROSS/UP SELL';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'DEEP/CROSS/UP SELL');
        
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
        tasks.Task_Source__c = 'SFDC';
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
        tasks.Task_Source__c = 'SFDC';
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
        tasks.Task_Source__c = 'SFDC';
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
        tasks.Task_Source__c = 'SFDC';
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
        tasks.Task_Source__c = 'SFDC';
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
        tasks.Task_Source__c = 'SFDC';
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
        tasks.Task_Source__c = 'SFDC';
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
        tasks.Task_Source__c = 'SFDC';
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
        tasks.Task_Source__c = 'SFDC';
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
        tasks.Task_Source__c = 'SFDC';
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
        tasks.Task_Source__c = 'SFDC';
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
        tasks.Task_Source__c = 'SFDC';
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
        tasks.Task_Source__c = 'SFDC';
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
        tasks.Task_Source__c = 'SFDC';
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
        tasks.Task_Source__c = 'SFDC';
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
        tasks.Task_Source__c = 'SFDC';
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
        tasks.Task_Source__c = 'SFDC';
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
        tasks.Task_Source__c = 'SFDC';
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
        tasks.Task_Source__c = 'SFDC';
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
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'Manual';
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
    
    private static testMethod void testPositiveSLAUpdate1() {
        testSetup();
        SM_CheckRecursive.run = true;
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
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
        tasks.Task_Source__c = 'Manual';
        tasks.Touchpoint_Type__c = 'INBOUND CALL';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST';
        update taskRec;
        
        Task taskRec1 = new Task();
        taskRec1 = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST';
        taskrec1.Start_DateCS__c = DateTime.now();
        
        update taskRec1;
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'ONLINE INFORMATION REQUEST');
        
        
    }
    
    private static testMethod void testPositiveSLAUpdate2() {
        testSetup();
        SM_CheckRecursive.run = true;
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'Manual';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'INBOUND CALL';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'INBOUND CALL';
        update taskRec;
        
        Task taskRec1 = new Task();
        taskRec1 = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec1.Touchpoint_Type__c = 'INBOUND CALL';
        taskrec1.Start_DateCS__c = DateTime.now();
        
        update taskRec1;
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'INBOUND CALL');
        
        
    }
    
    private static testMethod void testPositiveSLAUpdate3() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'Manual';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'ONLINE QUOTE REQUEST';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'ONLINE QUOTE REQUEST';
        SM_CheckRecursive.run = true;
        update taskRec;
        
        Task taskRec1 = new Task();
        taskRec1 = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'ONLINE QUOTE REQUEST';
        taskrec1.Start_DateCS__c = DateTime.now();
        update taskRec1;
        
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'ONLINE QUOTE REQUEST');
        
        
    }
    
    private static testMethod void testPositiveSLAUpdate4() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'Manual';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'REFERRAL PARTNER';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'REFERRAL PARTNER';
        SM_CheckRecursive.run = true;
        update taskRec;
        
        Task taskRec1 = new Task();
        taskRec1 = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'REFERRAL PARTNER';
        taskrec1.Start_DateCS__c = DateTime.now();
        update taskRec1;
        
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'REFERRAL PARTNER');
        
        
    }
    
    private static testMethod void testPositiveSLAUpdate5() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'Manual';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'REFERRAL EMPLOYEE';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'REFERRAL EMPLOYEE';
        SM_CheckRecursive.run = true;
        update taskRec;
        
        Task taskRec1 = new Task();
        taskRec1 = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'REFERRAL EMPLOYEE';
        taskrec1.Start_DateCS__c = DateTime.now();
        update taskRec1;
        
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'REFERRAL EMPLOYEE');
        
        
    }
    
    private static testMethod void testPositiveSLAUpdate6() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'Manual';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'REFERRAL TECHNICIAN';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'REFERRAL TECHNICIAN';
        SM_CheckRecursive.run = true;
        update taskRec;
        
        Task taskRec1 = new Task();
        taskRec1 = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'REFERRAL TECHNICIAN';
        taskrec1.Start_DateCS__c = DateTime.now();
        update taskRec1;
        
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'REFERRAL TECHNICIAN');
        
        
    }
    
    private static testMethod void testPositiveSLAUpdate7() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'Manual';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'REFERRAL ROUTESALES';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'REFERRAL ROUTESALES';
        SM_CheckRecursive.run = true;
        update taskRec;
        
        Task taskRec1 = new Task();
        taskRec1 = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'REFERRAL ROUTESALES';
        taskrec1.Start_DateCS__c = DateTime.now();
        update taskRec1;
        
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'REFERRAL ROUTESALES');
        
        
    }
    
    private static testMethod void testPositiveSLAUpdate8() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'Manual';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'REFERRAL CUSTOMER';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'REFERRAL CUSTOMER';
        SM_CheckRecursive.run = true;
        update taskRec;
        
        Task taskRec1 = new Task();
        taskRec1 = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'REFERRAL CUSTOMER';
        taskrec1.Start_DateCS__c = DateTime.now();
        update taskRec1;
        
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'REFERRAL CUSTOMER');
        
        
    }
    
    private static testMethod void testPositiveSLAUpdate9() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'Manual';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'REFERRAL BUYING GROUP';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'REFERRAL BUYING GROUP';
        SM_CheckRecursive.run = true;
        update taskRec;
        
        Task taskRec1 = new Task();
        taskRec1 = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'REFERRAL BUYING GROUP';
        taskrec1.Start_DateCS__c = DateTime.now();
        update taskRec1;
        
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'REFERRAL BUYING GROUP');
        
        
    }
    
    private static testMethod void testPositiveSLAUpdate10() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'Manual';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'COLD AQCUISITION';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'COLD AQCUISITION';
        SM_CheckRecursive.run = true;
        update taskRec;
        
        Task taskRec1 = new Task();
        taskRec1 = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'COLD AQCUISITION';
        taskrec1.Start_DateCS__c = DateTime.now();
        update taskRec1;
        
        
        
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'COLD AQCUISITION');
        
        
    }
    
    private static testMethod void testPositiveSLAUpdate11() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'Manual';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'TAILOR-MADE AGREEMENT';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'TAILOR-MADE AGREEMENT';
        SM_CheckRecursive.run = true;
        update taskRec;
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'TAILOR-MADE AGREEMENT');
        
        
    }
    
    private static testMethod void testPositiveSLAUpdate12() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'Manual';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'STAND AGREEMENT';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'STAND AGREEMENT';
        SM_CheckRecursive.run = true;
        update taskRec;
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'STAND AGREEMENT');
        
        
    }
    
    private static testMethod void testPositiveSLAUpdate13() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'Manual';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'CMD CHANGE';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'CMD CHANGE';
        SM_CheckRecursive.run = true;
        update taskRec;
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'CMD CHANGE');
        
        
    }
    
    private static testMethod void testPositiveSLAUpdate14() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'Manual';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'SIGNED CONTRACT';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'SIGNED CONTRACT';
        SM_CheckRecursive.run = true;
        update taskRec;
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'SIGNED CONTRACT');
        
        
    }
    
    private static testMethod void testPositiveSLAUpdate15() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'Manual';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'GENERIC REQUEST';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'GENERIC REQUEST';
        SM_CheckRecursive.run = true;
        update taskRec;
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'GENERIC REQUEST');
        
        
    }
    
    private static testMethod void testPositiveSLAUpdate16() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'Manual';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'REPORT REQUEST';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'REPORT REQUEST';
        SM_CheckRecursive.run = true;
        update taskRec;
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'REPORT REQUEST');
        
        
    }
    
    private static testMethod void testPositiveSLAUpdate17() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'Manual';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'CONTACT REQUEST';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'CONTACT REQUEST';
        SM_CheckRecursive.run = true;
        update taskRec;
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'CONTACT REQUEST');
        
        
    }
    
    private static testMethod void testPositiveSLAUpdate18() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'Manual';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'OTHER REQUEST';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'OTHER REQUEST';
        SM_CheckRecursive.run = true;
        update taskRec;
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'OTHER REQUEST');
        
        
    }
    
    private static testMethod void testPositiveSLAUpdate19() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE QUOTE REQUEST MC';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'SFDC';
        tasks.Touchpoint_Type__c = 'ONLINE QUOTE REQUEST MC';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'ONLINE INFORMATION REQUEST MC';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST MC';
        SM_CheckRecursive.run = true;
        update taskRec;
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'ONLINE INFORMATION REQUEST MC');
        
        
    }
    
    private static testMethod void testPositiveSLAUpdate20() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST MC';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'SFDC';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST MC';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'ONLINE QUOTE REQUEST MC';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'ONLINE QUOTE REQUEST MC';
        SM_CheckRecursive.run = true;
        update taskRec;
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'ONLINE QUOTE REQUEST MC');
        
        
    }
    
    private static testMethod void testPositiveSLAUpdate21() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST MC';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'SFDC';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST MC';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'END WARR';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'END WARR';
        SM_CheckRecursive.run = true;
        update taskRec;
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'END WARR');
        
        
    }
    
    private static testMethod void testPositiveSLAUpdate22() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST MC';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'SFDC';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST MC';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'PROMOTION';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'PROMOTION';
        SM_CheckRecursive.run = true;
        update taskRec;
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'PROMOTION');
        
        
    }
    
    private static testMethod void testPositiveSLAUpdate23() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST MC';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'SFDC';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST MC';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'NEW PRODUCT INTRO';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'NEW PRODUCT INTRO';
        SM_CheckRecursive.run = true;
        update taskRec;
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'NEW PRODUCT INTRO');
        
        
    }
    
    private static testMethod void testPositiveSLAUpdate24() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST MC';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'SFDC';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST MC';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'PRODUCT CHANGE';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'PRODUCT CHANGE';
        SM_CheckRecursive.run = true;
        update taskRec;
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'PRODUCT CHANGE');
        
        
    }
    
    private static testMethod void testPositiveSLAUpdate25() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST MC';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'SFDC';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST MC';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'CAMPAIGN';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'CAMPAIGN';
        SM_CheckRecursive.run = true;
        update taskRec;
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'CAMPAIGN');
        
        
    }
    
    private static testMethod void testPositiveSLAUpdate26() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST MC';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'SFDC';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST MC';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'TRADE SHOW/EVENT';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'TRADE SHOW/EVENT';
        SM_CheckRecursive.run = true;
        update taskRec;
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'TRADE SHOW/EVENT');
        
        
    }
    
    private static testMethod void testPositiveSLAUpdate27() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST MC';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'SFDC';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST MC';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'NEW STARTED COMPANY';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'NEW STARTED COMPANY';
        SM_CheckRecursive.run = true;
        update taskRec;
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'NEW STARTED COMPANY');
        
        
    }
    
    private static testMethod void testPositiveSLAUpdate28() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST MC';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'SFDC';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST MC';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'COMPANY CHANGE';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'COMPANY CHANGE';
        SM_CheckRecursive.run = true;
        update taskRec;
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'COMPANY CHANGE');
        
        
    }
    
    private static testMethod void testPositiveSLAUpdate29() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST MC';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'SFDC';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST MC';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'PROSPECT LIST';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'PROSPECT LIST';
        SM_CheckRecursive.run = true;
        update taskRec;
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'PROSPECT LIST');
        
        
    }
    
    private static testMethod void testPositiveSLAUpdate30() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST MC';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'SFDC';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST MC';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'NPS';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'NPS';
        SM_CheckRecursive.run = true;
        update taskRec;
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'NPS');
        
        
    }
    
    private static testMethod void testPositiveSLAUpdate31() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST MC';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'SFDC';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST MC';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'WARM WELCOME FOLL UP';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'WARM WELCOME FOLL UP';
        SM_CheckRecursive.run = true;
        update taskRec;
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'WARM WELCOME FOLL UP');
        
        
    }
    
    private static testMethod void testPositiveSLAUpdate32() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST MC';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'SFDC';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST MC';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'FIRST ORDER SURVEY';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'FIRST ORDER SURVEY';
        SM_CheckRecursive.run = true;
        update taskRec;
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'FIRST ORDER SURVEY');
        
        
    }
    
    private static testMethod void testPositiveSLAUpdate33() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST MC';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'SFDC';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST MC';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'DEEP/CROSS/UP SELL';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'DEEP/CROSS/UP SELL';
        SM_CheckRecursive.run = true;
        update taskRec;
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'DEEP/CROSS/UP SELL');
        
        
    }
    
    private static testMethod void testPositiveSLAUpdate34() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST MC';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'SFDC';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST MC';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'AFT INSTAL';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'AFT INSTAL';
        SM_CheckRecursive.run = true;
        update taskRec;
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'AFT INSTAL');
        
        
    }
    
    private static testMethod void testPositiveSLAUpdate35() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST MC';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'SFDC';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST MC';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'MOVEMNT';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'MOVEMNT';
        SM_CheckRecursive.run = true;
        update taskRec;
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'MOVEMNT');
        
        
    }
    
    private static testMethod void testPositiveSLAUpdate36() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST MC';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'SFDC';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST MC';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'KPI-SLA CHECK';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'KPI-SLA CHECK';
        SM_CheckRecursive.run = true;
        update taskRec;
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'KPI-SLA CHECK');
        
        
    }
    
    private static testMethod void testPositiveSLAUpdate37() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST MC';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'SFDC';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST MC';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'BUDGET CHECK';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'BUDGET CHECK';
        SM_CheckRecursive.run = true;
        update taskRec;
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'BUDGET CHECK');
        
        
    }
    
    private static testMethod void testPositiveSLAUpdate38() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST MC';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'SFDC';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST MC';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'ONE-TIME BONUS';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'ONE-TIME BONUS';
        SM_CheckRecursive.run = true;
        update taskRec;
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'ONE-TIME BONUS');
        
        
    }
    
    private static testMethod void testPositiveSLAUpdate39() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST MC';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'SFDC';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST MC';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'INDEXATION NON STD';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'INDEXATION NON STD';
        SM_CheckRecursive.run = true;
        update taskRec;
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'INDEXATION NON STD');
        
        
    }
    
    private static testMethod void testPositiveSLAUpdate40() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST MC';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'SFDC';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST MC';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'KPI-SLA CHECK';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'KPI-SLA CHECK';
        SM_CheckRecursive.run = true;
        update taskRec;
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'KPI-SLA CHECK');
        
        
    }
    
    private static testMethod void testPositiveSLAUpdate41() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST MC';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'SFDC';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST MC';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'P.O. NUMBER REQUEST';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'P.O. NUMBER REQUEST';
        SM_CheckRecursive.run = true;
        update taskRec;
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'P.O. NUMBER REQUEST');
        
        
    }
    
    private static testMethod void testPositiveSLAUpdate42() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST MC';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'SFDC';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST MC';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'VOLUME OBLIG CHECK';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'VOLUME OBLIG CHECK';
        SM_CheckRecursive.run = true;
        update taskRec;
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'VOLUME OBLIG CHECK');
        
        
    }
    
    private static testMethod void testPositiveSLAUpdate43() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST MC';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'SFDC';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST MC';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'VOLUME OBLIG SETTL';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'VOLUME OBLIG SETTL';
        SM_CheckRecursive.run = true;
        update taskRec;
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'VOLUME OBLIG SETTL');
        
        
    }
    
    private static testMethod void testPositiveSLAUpdate44() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST MC';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'SFDC';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST MC';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'CREDIT LIMIT ALERT';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'CREDIT LIMIT ALERT';
        taskRec.recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        SM_CheckRecursive.run = true;
        update taskRec;
        Test.stopTest();
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
        SM_CheckRecursive.run = true;
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
        tasks.Task_Source__c = 'SFDC';
        tasks.Touchpoint_Type__c = 'SUBSCR ORDER ALERT';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'SUBSCR ORDER ALERT');
        
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
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST MC';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'SFDC';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST MC';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        Task tasks1 = new Task();
        tasks1.Task_Source__c = 'SFDC';
        tasks1.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST MC';
        tasks1.WhoId = con.Id;
        tasks1.RecordTypeId = recordTypeId;
        
        insert tasks1;
        
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
        SM_CheckRecursive.run = true;
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
        leadtest.FirstName = 'FirstName';
        leadtest.MiddleName = 'MiddleName';
        leadtest.Lastname = 'Leadtest';
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
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'Manual';
        tasks.Touchpoint_Type__c = 'CREDIT LIMIT ALERT';
        tasks.WhoId = leadtest.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'CREDIT LIMIT ALERT');
        
    }
    private static testMethod void testPositiveSLAUpdate47() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST MC';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        Lead leadtest = new Lead();
        leadtest.Lastname = 'leadtest';
        leadtest.Touchpoint_Type__c = 'INBOUND CALL';
        leadtest.Company = 'testacce';
        leadtest.Phone = '+63912312312';
        
        insert leadtest;
        
        Lead leadtest1 = new Lead();
        leadtest1.Lastname = 'leadtest';
        leadtest1.Touchpoint_Type__c = 'INBOUND CALL';
        leadtest1.Company = 'testacce';
        leadtest1.Phone = '+63912312312';
        
        insert leadtest1;
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'SFDC';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST MC';
        tasks.WhoId = leadtest1.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'CREDIT LIMIT ALERT';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        taskRec.Touchpoint_Type__c = 'CREDIT LIMIT ALERT';
        taskrec.WhoId = leadtest.Id;
        SM_CheckRecursive.run = true;
        update taskRec;
        Test.stopTest();
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
        acc.Last_Relevant_Activity_Date__c = date.valueOf('2010-12-12');
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'FIXED TERM CHECK';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Contact conttest = new Contact();
        conttest.LastName = 'contest';
        conttest.AccountId = acc.Id;
        conttest.Preferred_Language__c = 'SAP_EN';
        
        insert conttest;
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'SFDC';
        tasks.Touchpoint_Type__c = 'FIXED TERM CHECK';
        tasks.WhatId = acc.Id;
        tasks.WhoId = conttest.Id;
        tasks.Status = 'Completed Effective';
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'FIXED TERM CHECK');
        
    }
    private static testMethod void testPositiveSLAUpdate48() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST MC';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        Contact conttest = new Contact();
        conttest.LastName = 'contest';
        conttest.AccountId = acc.Id;
        conttest.Preferred_Language__c = 'SAP_EN';
        
        insert conttest;
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'SFDC';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST MC';
        tasks.WhoId = conttest.Id;
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'FIXED TERM CHECK';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'FIXED TERM CHECK';
        taskRec.WhoId = conttest.Id;
        SM_CheckRecursive.run = true;
        update taskRec;
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'FIXED TERM CHECK');
        
        
    }
    private static testMethod void testPositiveSLA49() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'FIXED TERMS SETTL';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'SFDC';
        tasks.Touchpoint_Type__c = 'FIXED TERMS SETTL';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'FIXED TERMS SETTL');
        
    }
    private static testMethod void testPositiveSLAUpdate49() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST MC';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'SFDC';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST MC';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'FIXED TERMS SETTL';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'FIXED TERMS SETTL';
        taskRec.Status = 'In Progress';
        SM_CheckRecursive.run = true;
        update taskRec;
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'FIXED TERMS SETTL');
        
        
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
        slas.Name = 'CASE FOLL UP';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'Manual';
        tasks.Touchpoint_Type__c = 'CASE FOLL UP';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'CASE FOLL UP');
        
    }
    private static testMethod void testPositiveSLAUpdate50() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'INBOUND CALL';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'Manual';
        tasks.Touchpoint_Type__c = 'INBOUND CALL';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'CASE FOLL UP';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'CASE FOLL UP';
        SM_CheckRecursive.run = true;
        update taskRec;
        Test.stopTest();
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
        slas.Name = '3+1+1 AGREEMENT RENEWAL';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'SFDC';
        tasks.Touchpoint_Type__c = '3+1+1 AGREEMENT RENEWAL';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == '3+1+1 AGREEMENT RENEWAL');
        
    }
    private static testMethod void testPositiveSLAUpdate51() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'INBOUND CALL';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'Manual';
        tasks.Touchpoint_Type__c = 'INBOUND CALL';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = '3+1+1 AGREEMENT RENEWAL';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = '3+1+1 AGREEMENT RENEWAL';
        taskRec.recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        SM_CheckRecursive.run = true;
        update taskRec;
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == '3+1+1 AGREEMENT RENEWAL');
        
        
    }
    private static testMethod void testPositiveSLA52() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = '3+1+1 ASSET RENEWAL';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'SFDC';
        tasks.Touchpoint_Type__c = '3+1+1 ASSET RENEWAL';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == '3+1+1 ASSET RENEWAL');
        
    }
    private static testMethod void testPositiveSLAUpdate52() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'INBOUND CALL';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'Manual';
        tasks.Touchpoint_Type__c = 'INBOUND CALL';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = '3+1+1 ASSET RENEWAL';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = '3+1+1 ASSET RENEWAL';
        taskRec.recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        SM_CheckRecursive.run = true;
        update taskRec;
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == '3+1+1 ASSET RENEWAL');
        
        
    }
    private static testMethod void testPositiveSLA53() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'TERMINATED ASSETS - CHECK AGREEMENT';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'SFDC';
        tasks.Touchpoint_Type__c = 'TERMINATED ASSETS - CHECK AGREEMENT';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'TERMINATED ASSETS - CHECK AGREEMENT');
        
    }
    private static testMethod void testPositiveSLAUpdate53() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST MC';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'SFDC';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST MC';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'TERMINATED ASSETS - CHECK AGREEMENT';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'TERMINATED ASSETS - CHECK AGREEMENT';
        SM_CheckRecursive.run = true;
        update taskRec;
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'TERMINATED ASSETS - CHECK AGREEMENT');
        
        
    }
    private static testMethod void testPositiveSLA54() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'RENEWED ASSET TERMINATION CMR';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'SFDC';
        tasks.Touchpoint_Type__c = 'RENEWED ASSET TERMINATION CMR';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'RENEWED ASSET TERMINATION CMR');
        
    }
    private static testMethod void testPositiveSLAUpdate54() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST MC';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'SFDC';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST MC';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'RENEWED ASSET TERMINATION CMR';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'RENEWED ASSET TERMINATION CMR';
        SM_CheckRecursive.run = true;
        update taskRec;
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'RENEWED ASSET TERMINATION CMR');
        
        
    }
     private static testMethod void testPositiveSLA55() {
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
        tasks.Task_Source__c = 'SFDC';
        tasks.Touchpoint_Type__c = 'INDEXATION NON STD';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'INDEXATION NON STD');
        
    }
    private static testMethod void testPositiveSLAUpdate55() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST MC';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'SFDC';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST MC';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'INDEXATION NON STD';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'INDEXATION NON STD';
        SM_CheckRecursive.run = true;
        update taskRec;
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'INDEXATION NON STD');
        
        
    }
    private static testMethod void testPositiveSLA56() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'ACCOUNT BLOCK RELEASE REQUEST';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'SFDC';
        tasks.Touchpoint_Type__c = 'ACCOUNT BLOCK RELEASE REQUEST';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'ACCOUNT BLOCK RELEASE REQUEST');
        
    }
    private static testMethod void testPositiveSLAUpdate56() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST MC';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'SFDC';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST MC';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'ACCOUNT BLOCK RELEASE REQUEST';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'ACCOUNT BLOCK RELEASE REQUEST';
        SM_CheckRecursive.run = true;
        update taskRec;
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'ACCOUNT BLOCK RELEASE REQUEST');
        
        
    }
    private static testMethod void testPositiveSLA57() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'CALL LIST INGREDIENTS';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'SFDC';
        tasks.Touchpoint_Type__c = 'CALL LIST INGREDIENTS';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'CALL LIST INGREDIENTS');
        
    }
    private static testMethod void testPositiveSLAUpdate57() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST MC';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'SFDC';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST MC';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'CALL LIST INGREDIENTS';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'CALL LIST INGREDIENTS';
        SM_CheckRecursive.run = true;
        update taskRec;
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'CALL LIST INGREDIENTS');
        
        
    }
    private static testMethod void testPositiveSLA58() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'ROUTE SALES RESCHEDULING';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'SFDC';
        tasks.Touchpoint_Type__c = 'ROUTE SALES RESCHEDULING';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'ROUTE SALES RESCHEDULING');
        
    }
    private static testMethod void testPositiveSLAUpdate58() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST MC';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'SFDC';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST MC';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'ROUTE SALES RESCHEDULING';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'ROUTE SALES RESCHEDULING';
        SM_CheckRecursive.run = true;
        update taskRec;
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'ROUTE SALES RESCHEDULING');
        
        
    }
    
    private static testMethod void testPositiveSLA59() {
        testSetup();
        
        Profile p = [SELECT Id FROM Profile WHERE  Name =: 'System Administrator']; 
        User u = new User(Alias = 'standt', Email='sample@testUser1.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sample@testUser1.com', Country= 'Netherlands', Elevated_Access_Reason__c = 'Defect or Incident Resolution', Elevated_Access_Reference__c = 'ASDF');
        insert u;
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        acc.Customer_Relations_1__c = u.id;
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'ONLINE MASTER DATA CHANGE REQ';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'SFDC';
        tasks.Touchpoint_Type__c = 'ONLINE MASTER DATA CHANGE REQ';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'ONLINE MASTER DATA CHANGE REQ');
        
    }
    
    private static testMethod void testPositiveSLAUpdate59() {
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
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'ONLINE INFORMATION REQUEST MC';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'SFDC';
        tasks.Touchpoint_Type__c = 'ONLINE INFORMATION REQUEST MC';
        tasks.WhatId = acc.Id;
        tasks.WhoId = con.Id;
        tasks.RecordTypeId = recordTypeId;
        tasks.Sales_Organization__c = 'SAP_6750';
        
        insert tasks;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'ONLINE MASTER DATA CHANGE REQ';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'ONLINE MASTER DATA CHANGE REQ';
        SM_CheckRecursive.run = true;
        update taskRec;
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'ONLINE MASTER DATA CHANGE REQ');
        
        
    }
    private static testMethod void testPositiveSLA60() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'MACHINE CASE WITH NO WARRANTY';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'Manual';
        tasks.Touchpoint_Type__c = 'MACHINE CASE WITH NO WARRANTY';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
       
        insert tasks;
        
        Test.stopTest();
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c FROM Task WHERE Id = :tasks.Id];
        System.assert(taskRec.Touchpoint_Type__c == 'MACHINE CASE WITH NO WARRANTY');
        
    }
    private static testMethod void testPositiveSLAUpdate60() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        acc.Last_Relevant_Activity_Date__c = System.today();
        acc.Archiving_Flag__c = true;
        acc.IsActive__c = false;
        insert acc;
        
        SLA_Task__c slas1 = new SLA_Task__c();
        slas1.Name = 'INBOUND CALL';
        slas1.Start_Date__c = 0;
        slas1.Due_Date__c = 1;
        slas1.Target_Completion_Date__c = 1;
        slas1.Task_Expiration_Date__c = 180;
        insert slas1;
        
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'Manual';
        tasks.Touchpoint_Type__c = 'INBOUND CALL';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        Id recordTypeId1 = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks1 = new Task();
        tasks1.Task_Source__c = 'SFDC';
        tasks1.CallType = 'Inbound';
        tasks1.CallObject = '123123123';
        tasks1.RecordTypeId = recordTypeId1;
        
        insert tasks1;

        Task tasks2 = new Task();
        tasks2.Task_Source__c = 'SFDC';
        tasks2.CallType = 'Outbound';
        tasks2.CallObject = '123123123';
        tasks2.RecordTypeId = recordTypeId1;
        
        insert tasks2;
        
        SLA_Task__c slas = new SLA_Task__c();
        slas.Name = 'MACHINE CASE WITH NO WARRANTY';
        slas.Start_Date__c = 0;
        slas.Due_Date__c = 1;
        slas.Target_Completion_Date__c = 1;
        slas.Task_Expiration_Date__c = 180;
        Test.startTest();
        insert slas;
        
        Task taskRec = new Task();
        taskRec = [Select Subject, WhatId, Operational_Tasks__c, Touchpoint_Type__c, Status FROM Task WHERE Id = :tasks.Id];
        taskRec.Touchpoint_Type__c = 'MACHINE CASE WITH NO WARRANTY';
        taskRec.Status = 'Completed Effective';
        SM_CheckRecursive.run = true;
        update taskRec;
        Test.stopTest();
        System.assert(taskRec.Touchpoint_Type__c == 'MACHINE CASE WITH NO WARRANTY');
        
        
    }
    
    private static testMethod void teststampfromopportunity() {
        testSetup();
        SM_CheckRecursive.run = true;
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        acc.Phone = '+31302979111';
        acc.Segment__c = 'SAP_B';
        acc.Account_Lifecycle__c = 'Prospect';
        acc.Main_Postal_Code__c = 'asdf12';
        insert acc;
        
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
        
        Case cse =  new Case(AccountId = acc.Id, Priority = Label.TS_Case_Priority_Medium , SLADate__c=datetime.now(), SubType__c=Label.TS_Case_SubType_CorrectMaint, Type='Field Service', Origin=Label.TS_Case_Origin_Email,
                             RecordTypeId = TS_UtilityClass.getRecordTypeIdByName(Label.TS_Obj_API_Name_Case, Label.TS_Case_RecordType_Field),
                             Status = Label.TS_Status_New, CaseSubStatus__c = Label.TS_Status_New, SalesOrganization__c = 'SAP_0333');
        
        insert cse;
        
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        Task tasks = new Task();
        tasks.Task_Source__c = 'Manual';
        tasks.Touchpoint_Type__c = 'INBOUND CALL';
        tasks.WhatId = acc.Id;
        tasks.RecordTypeId = recordTypeId;
        
        insert tasks;
        
        Task tasks1 = new Task();
        tasks1.Task_Source__c = 'Manual';
        tasks1.Touchpoint_Type__c = 'INBOUND CALL';
        tasks1.WhatId = opp.Id;
        tasks1.RecordTypeId = recordTypeId;
        
        insert tasks1;
        
        Task tasks2 = new Task();
        tasks2.Task_Source__c = 'Manual';
        tasks2.Touchpoint_Type__c = 'INBOUND CALL';
        tasks2.WhatId = accloc.Id;
        tasks2.RecordTypeId = recordTypeId;
        
        insert tasks2;
        
        Task tasks3 = new Task();
        tasks3.Task_Source__c = 'Manual';
        tasks3.Touchpoint_Type__c = 'INBOUND CALL';
        tasks3.WhatId = cse.Id;
        tasks3.RecordTypeId = recordTypeId;
        
        insert tasks3;
        
        Task taskrec = new Task();
        taskrec = [Select ID, Account_Lifecycle_HANA__c, Segment__c, Account_Name__c from Task where ID = :tasks2.Id];
        System.assert(taskrec.Account_Lifecycle_HANA__c == 'Prospect');
        System.assert(taskrec.Segment__c == 'SAP_B');
        System.assert(taskrec.Account_Name__c == 'accName');
    }    

    private static testMethod void testUpdateActivityCount() {
        testSetup();
        
        Account acc = new Account();
        acc = [Select Id FROM Account LIMIT 1];

        Case cse =  new Case(AccountId = acc.Id, Priority = Label.TS_Case_Priority_Medium , SLADate__c=datetime.now(), SubType__c=Label.TS_Case_SubType_CorrectMaint, Type='Field Service', Origin=Label.TS_Case_Origin_Email,
        RecordTypeId = TS_UtilityClass.getRecordTypeIdByName(Label.TS_Obj_API_Name_Case, Label.TS_Case_RecordType_Field),
        Status = Label.TS_Status_New, CaseSubStatus__c = Label.TS_Status_New, SalesOrganization__c = 'SAP_0333', Number_of_Open_Tasks__c = 1);
        insert cse;

        Task taskrec = new Task();
        taskrec = [Select Id, WhatId, Touchpoint_Type__c, CallObject, Status, Case__c, Task_Source__c, Type, IsRelatedToCase__c FROM Task LIMIT 1];
                
        Test.startTest();
        taskrec.WhatID = cse.Id;
        taskrec.Task_Source__c = 'Manual';
        taskrec.Touchpoint_Type__c = 'REMINDER';
        taskrec.CallObject = '123123123';
        taskrec.Type = 'Case';
        taskrec.Status = 'Completed';
        taskrec.Case__c = cse.Id;
        update taskrec;
        Test.stopTest();

        Task taskrec2 = new Task();
        taskrec2 = [Select IsRelatedToCase__c FROM Task WHERE Id =: taskrec.Id];

        Case cse2 = new Case();
        cse2 = [SELECT Number_of_Open_Tasks__c FROM Case WHERE Id =: cse.Id];

        System.assert(taskrec2.IsRelatedToCase__c == true);          
        System.assert(cse.Number_of_Open_Tasks__c != cse2.Number_of_Open_Tasks__c);    
    }
    
    /*private static testMethod void testMuteOTC() {
        OTC_Related_Task_Object__c otcRelatedTask = new OTC_Related_Task_Object__c();
        otcRelatedTask.Name = 'Account Location';
        otcRelatedTask.Object_Name__c = 'Apttus_Config2__AccountLocation__c';
        insert otcRelatedTask;
        
        Account acctRec = new Account(Name = 'Test Account', Phone = '+31302979111');
        insert acctRec;
        
        Id al = Schema.SObjectType.Apttus_Config2__AccountLocation__c.getRecordTypeInfosByName().get('Account Location').getRecordTypeId();
        Apttus_Config2__AccountLocation__c acctLoc = new Apttus_Config2__AccountLocation__c();
        acctLoc.RecordTypeId = al;
        acctLoc.Copy_of_Parent_Account__c = true;
        acctLoc.Apttus_Config2__AccountId__c = acctRec.Id;
        acctLoc.Name = 'SAMP';
        acctLoc.Customer_calendar_key__c = 'SAP_32';
        acctLoc.Mini_Language__c = 'SAP_FR';
        acctLoc.Pallet_type__c = 'SAP_007';
        acctLoc.Saturday_Afternoon_From_Receiving__c = '14:30';
        acctLoc.Saturday_Afternoon_To_Receiving__c = '15:00';
        acctLoc.Saturday_Morning_From_Receiving__c = '02:45';
        acctLoc.Saturday_Morning_To_Receiving__c = '02:15';
        acctLoc.Sunday_Afternoon_From_Receiving__c = '15:15';
        acctLoc.Sunday_Afternoon_To_Receiving__c = '15:30';
        acctLoc.Sunday_Morning_From_Receiving__c = '03:30';
        acctLoc.Sunday_Morning_To_Receiving__c = '   01:00';
        insert acctLoc;
        
        Id inbound = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();
        Task taskRec = new Task();
        taskRec.WhatId = acctLoc.Id;
        taskRec.RecordTypeId = inbound;
        insert taskRec;
        
        Task taskR = [Select Id, OwnerId, WhatId  FROM Task WHERE Id = :taskRec.Id];
        
        System.assert(String.valueOf(taskR.WhatId.getSObjectType()) == otcRelatedTask.Object_Name__c);
    }*/

    
    
}