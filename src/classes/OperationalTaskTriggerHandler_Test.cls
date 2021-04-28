/**
 * Class Name: OperationalTaskTriggerHandler_Test
 * @author: Catherine Aragon
 * Date: 14-Mar-2018
 * @description: Test class for OperationalTasktriggerHandler
 *
 */
@isTest
public class OperationalTaskTriggerHandler_Test {
    //Description: This is for test setup of the test class
    static void testSetup(){
        //insert custom settings
        TriggerSettings__c ts = new TriggerSettings__c();
        ts.OperationalTaskTrigger__c = true;
        insert ts;
        
        // Account acc = new Account();
        // acc.Name = 'accName';
        // acc.Second_Account_Name__c = 'sAccName';
        // acc.Sales_Organization__c = 'SAP_0333';
        // //acc.Sales_Office__c = 'SAP_F020';
        // acc.Phone = '+31302979111';
        // insert acc;
        
        // Profile p = [SELECT Id FROM Profile WHERE  Name =: 'System Administrator']; 
        // User u = new User(Alias = 'standt', Email='sample@testUser1.com', 
        // EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        // LocaleSidKey='en_US', ProfileId = p.Id, 
        // TimeZoneSidKey='America/Los_Angeles', UserName='sample@testUser19801.com', Sales_Organization__c = 'SAP_0333', Country= 'Netherlands');
        // insert u;
        
        // Task taskRec = new Task();
        // taskRec.WhatId = acc.Id;
        // taskRec.OwnerId = u.Id;
        // insert taskRec;
        
        
        // Operational_Tasks__c otRec = new Operational_Tasks__c();
        // otRec.Task_ID__c = taskRec.Id;
        // //otRec.OwnerId = u.Id;
        // insert otRec;
        
        List<Operational_Tasks__c> otList = new List<Operational_Tasks__c>();
        for(Operational_Tasks__c ot : TestDataFactory.createOT(10)){            
            otList.add(ot);
        }
        test.startTest();
        insert otList;
        test.stopTest();
        
    }
    
    private static testMethod void testPositive() {
        testSetup();
        
        User userInfo = new User();
        userInfo = [Select Id, Name FROM User LIMIT 1];
        List<Operational_Tasks__c> updateOT = new List<Operational_Tasks__c>();
        
        Profile p = [SELECT Id FROM Profile WHERE  Name =: 'JDE - End User - Basic Internal']; 
        User u = new User(Alias = 'standt', Email='sample@testUser1.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sample@testUser17989.com', Sales_Organization__c = 'SAP_0333', Country= 'Netherlands');
        insert u;
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        Operational_Tasks__c asdf = new Operational_Tasks__c();
        asdf.Status__c = 'Completed Effective';
        asdf.Due_Date__c = Date.today();
        asdf.Task_Source__c = 'CTI';
        
        insert asdf;
        
        
        Task task = new Task();
        task.Touchpoint_Type__c = 'INBOUND CALL';
        task.WhatId = acc.Id;
        task.ActivityDate = date.today();
        task.Operational_Tasks__c = asdf.Id;
        
        insert task;
        
        Operational_Tasks__c asdf1 = new Operational_Tasks__c();
        asdf1 = [Select Id, Status__c, Due_Date__c, Task_Source__c, Task_ID__c from Operational_Tasks__c WHERE Id = :asdf.Id];
        asdf1.Status__c = 'Open';
        asdf1.Task_Source__c = 'EPI';
        SM_CheckRecursive.run = true;
        update asdf1;
        for(Operational_Tasks__c oTask: [SELECT Id, Name FROM Operational_Tasks__c]){
            oTask.Status__c = 'Redial';
            oTask.Due_Date__c = Date.today();
            oTask.Task_Source__c = 'CTI';
            oTask.Task_ID__c = task.Id;
            updateOT.add(oTask);
        }
        
        SM_CheckRecursive.run = true;
        SM_CheckRecursive.run = true;
        update updateOT;
        
        
        List<Operational_Tasks__c> updatedOT = new List<Operational_Tasks__c>([Select Id, Name, Status__c FROM Operational_Tasks__c WHERE Id IN :updateOT]);
        
        System.assert(updatedOT[0].Status__c == 'Redial'); 
        
        OperationalTaskTriggerHandler ot = new OperationalTaskTriggerHandler();
        List<SObject> newList;
        Map<Id, SObject> newItemsMap;
        List<SObject> oldList;
        Map<Id, SObject> oldItems;
        
        ot.AfterUndelete(newList, newItemsMap);
        ot.afterDelete(oldList, oldItems);
        
    }
    
    private static testMethod void testPositive1() {
        testSetup();
        
        User userInfo = new User();
        userInfo = [Select Id, Name FROM User LIMIT 1];
        List<Operational_Tasks__c> updateOT = new List<Operational_Tasks__c>();
        
        Profile p = [SELECT Id FROM Profile WHERE  Name =: 'JDE - End User - Basic Internal']; 
        User u = new User(Alias = 'standt', Email='sample@testUser1.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sample@testUser17989.com', Sales_Organization__c = 'SAP_0333', Country= 'Netherlands');
        insert u;
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        Task task = new Task();
        task.Touchpoint_Type__c = 'INBOUND CALL';
        task.WhatId = acc.Id;
        task.ActivityDate = date.today();
        
        Operational_Tasks__c asdf = new Operational_Tasks__c();
        asdf.Status__c = 'Completed Effective';
        asdf.Due_Date__c = Date.today();
        asdf.Task_Source__c = 'CTI';
        asdf.Task_ID__c = task.Id;
        
        insert asdf;
        
        Operational_Tasks__c asdf1 = new Operational_Tasks__c();
        asdf1 = [Select Id, Status__c, Due_Date__c, Task_Source__c, Task_ID__c from Operational_Tasks__c WHERE Id = :asdf.Id];
        asdf1.Status__c = 'Open';
        asdf1.Task_Source__c = 'EPI';
        SM_CheckRecursive.run = true;
        update asdf1;
        for(Operational_Tasks__c oTask: [SELECT Id, Name FROM Operational_Tasks__c]){
            oTask.Status__c = 'Redial';
            oTask.Due_Date__c = Date.today();
            oTask.Task_Source__c = 'CTI';
            oTask.Task_ID__c = task.Id;
            updateOT.add(oTask);
        }
        
        SM_CheckRecursive.run = true;
        SM_CheckRecursive.run = true;
        update updateOT;
        
    }
    
    private static testMethod void testPositiveBel() {
        testSetup();
        
        User userInfo = new User();
        userInfo = [Select Id, Name FROM User LIMIT 1];
        List<Operational_Tasks__c> updateOT = new List<Operational_Tasks__c>();
        
        Profile p = [SELECT Id FROM Profile WHERE  Name =: 'System Administrator']; 
        User u = new User(Alias = 'standt', Email='sample@testUser1.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sample@testUser16509.com', Sales_Organization__c = 'SAP_0333', Country= 'Belgium',
        Elevated_Access_Reason__c = 'Defect or Incident Resolution', Elevated_Access_Reference__c = 'ASDF');
        insert u;
        
        Queue_Lead_Task__c mc = new Queue_Lead_Task__c();
        mc.Name = SM_Constants.SAP0333;
        mc.User_Keeper__c = u.id;
        insert mc;  

        System.runAs(u){
            Group testGroup = new Group(Name='Task Queue Belgium', Type='Queue');
            insert testGroup;
            QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SObjectType = 'Operational_Tasks__c');
            insert testQueue;
            
            for(Operational_Tasks__c oTask: [SELECT Id, Name, OwnerId, Owner.Type FROM Operational_Tasks__c]){
               
                oTask.OwnerId = testGroup.Id;
                oTask.Status__c = 'Redial';
                updateOT.add(oTask);
                
                System.debug('updateOT: ' + updateOT);
               
                
                
                
            }
            SM_CheckRecursive.run = true;
            update updateOT;
            List <Operational_Tasks__c> updatedOT = new List <Operational_Tasks__c>([SELECT Id, Name, OwnerId, Owner.Type FROM Operational_Tasks__c]);
            Map<Id, Id> taskGroup = new Map<Id, Id>();
            for (Operational_Tasks__c ot : updatedOT) {
                if (ot.Owner.Type == 'Queue') {
                    taskGroup.put(ot.Id, ot.OwnerId);
                }
            }

            Map<Id, Group> queues = new Map<Id, Group>();
            if (!taskGroup.values().isEmpty()){
                queues = new Map<Id, Group>([Select Id, Name 
                            FROM Group 
                            WHERE Type = :SM_Constants.queue AND Id IN :taskGroup.values()]);
            }
            
            // Set<String> userName = new Set<String>();
            // userName.add(mc.Belgium__c);
            
            // List<User> users= new List<User>([Select Id, Name FROM User WHERE Name IN :userName]);
            // Map<String, Id> userId = new Map<String, Id>();
            
            // for (User userR : users) {
            //     userId.put(userR.Name, userR.Id);
            // }
            
            Group otGroup = new Group(); 
            otGroup = [Select Id, Name 
                        FROM Group 
                        WHERE Id = :testGroup.Id];
            System.assert(otGroup.Name == 'Task Queue Belgium');
        }
        
    }
    
    private static testMethod void testPositiveFRA() {
        testSetup();
        
        User userInfo = new User();
        userInfo = [Select Id, Name FROM User LIMIT 1];
        List<Operational_Tasks__c> updateOT = new List<Operational_Tasks__c>();
        
        Profile p = [SELECT Id FROM Profile WHERE  Name =: 'System Administrator']; 
        User u = new User(Alias = 'standt', Email='sample@testUser1.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sample@testUser1121212.com', Sales_Organization__c = 'SAP_6706', Country= 'France',
        Elevated_Access_Reason__c = 'Defect or Incident Resolution', Elevated_Access_Reference__c = 'ASDF');
        insert u;
        
        Queue_Lead_Task__c mc = new Queue_Lead_Task__c();
        mc.Name = SM_Constants.SAP6706;
        mc.User_Keeper__c = u.id;
        insert mc;

        System.runAs(u){
            Group testGroup = new Group(Name='Task Queue France', Type='Queue');
            insert testGroup;
            QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SObjectType = 'Operational_Tasks__c');
            insert testQueue;
            
            for(Operational_Tasks__c oTask: [SELECT Id, Name, OwnerId, Owner.Type FROM Operational_Tasks__c]){
               
                oTask.OwnerId = testGroup.Id;
                oTask.Status__c = 'Redial';
                updateOT.add(oTask);
                
                System.debug('updateOT: ' + updateOT);
               
                
                
                
            }
            SM_CheckRecursive.run = true;
            update updateOT;
            List <Operational_Tasks__c> updatedOT = new List <Operational_Tasks__c>([SELECT Id, Name, OwnerId, Owner.Type FROM Operational_Tasks__c]);
            Map<Id, Id> taskGroup = new Map<Id, Id>();
            for (Operational_Tasks__c ot : updatedOT) {
                if (ot.Owner.Type == 'Queue') {
                    taskGroup.put(ot.Id, ot.OwnerId);
                }
            }

            Map<Id, Group> queues = new Map<Id, Group>();
            if (!taskGroup.values().isEmpty()){
                queues = new Map<Id, Group>([Select Id, Name 
                            FROM Group 
                            WHERE Type = :SM_Constants.queue AND Id IN :taskGroup.values()]);
            }
            
            // Set<String> userName = new Set<String>();
            // userName.add(mc.France__c);
            
            // List<User> users= new List<User>([Select Id, Name FROM User WHERE Name IN :userName]);
            // Map<String, Id> userId = new Map<String, Id>();
            
            // for (User userR : users) {
            //     userId.put(userR.Name, userR.Id);
            // }
            
            Group otGroup = new Group(); 
            otGroup = [Select Id, Name 
                        FROM Group 
                        WHERE Id = :testGroup.Id];
            System.assert(otGroup.Name == 'Task Queue France');
             
        }
        
    }
    
    private static testMethod void testPositiveNLS() {
        testSetup();
        
        User userInfo = new User();
        userInfo = [Select Id, Name FROM User LIMIT 1];
        List<Operational_Tasks__c> updateOT = new List<Operational_Tasks__c>();
        
        Profile p = [SELECT Id FROM Profile WHERE  Name =: 'System Administrator']; 
        User u = new User(Alias = 'standt', Email='sample@testUser1.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sample@testUser1121212.com', Sales_Organization__c = 'SAP_0333', Country= 'Belgium',
        Elevated_Access_Reason__c = 'Defect or Incident Resolution', Elevated_Access_Reference__c = 'ASDF');
        insert u;
        
        Queue_Lead_Task__c mc = new Queue_Lead_Task__c();
        mc.Name = SM_Constants.SAP0111;
        mc.User_Keeper__c = u.id;
        insert mc;  

        System.runAs(u){
            Group testGroup = new Group(Name='NL Small Business', Type='Queue');
            insert testGroup;
            QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SObjectType = 'Operational_Tasks__c');
            insert testQueue;
            
            for(Operational_Tasks__c oTask: [SELECT Id, Name, OwnerId, Owner.Type FROM Operational_Tasks__c]){
               
                oTask.OwnerId = testGroup.Id;
                oTask.Status__c = 'Redial';
                updateOT.add(oTask);
                
                System.debug('updateOT: ' + updateOT);
               
                
                
                
            }
            SM_CheckRecursive.run = true;
            update updateOT;
            List <Operational_Tasks__c> updatedOT = new List <Operational_Tasks__c>([SELECT Id, Name, OwnerId, Owner.Type FROM Operational_Tasks__c]);
            Map<Id, Id> taskGroup = new Map<Id, Id>();
            for (Operational_Tasks__c ot : updatedOT) {
                if (ot.Owner.Type == 'Queue') {
                    taskGroup.put(ot.Id, ot.OwnerId);
                }
            }

            Map<Id, Group> queues = new Map<Id, Group>();
            if (!taskGroup.values().isEmpty()){
                queues = new Map<Id, Group>([Select Id, Name 
                            FROM Group 
                            WHERE Type = :SM_Constants.queue AND Id IN :taskGroup.values()]);
            }
            
            // Set<String> userName = new Set<String>();
            // userName.add(mc.Belgium__c);
            
            // List<User> users= new List<User>([Select Id, Name FROM User WHERE Name IN :userName]);
            // Map<String, Id> userId = new Map<String, Id>();
            
            // for (User userR : users) {
            //     userId.put(userR.Name, userR.Id);
            // }
            
            Group otGroup = new Group(); 
            otGroup = [Select Id, Name 
                        FROM Group 
                        WHERE Id = :testGroup.Id];
            System.assert(otGroup.Name == 'NL Small Business');
             
        }
        
    }
    
    private static testMethod void testPositiveNLM() {
        testSetup();
        
        User userInfo = new User();
        userInfo = [Select Id, Name FROM User LIMIT 1];
        List<Operational_Tasks__c> updateOT = new List<Operational_Tasks__c>();
        
        Profile p = [SELECT Id FROM Profile WHERE  Name =: 'System Administrator']; 
        User u = new User(Alias = 'standt', Email='sample@testUser1.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sample@testUser1432.com', Sales_Organization__c = 'SAP_0333', Country= 'Belgium',
        Elevated_Access_Reason__c = 'Defect or Incident Resolution', Elevated_Access_Reference__c = 'ASDF');
        insert u;
        
        Queue_Lead_Task__c mc = new Queue_Lead_Task__c();
        mc.Name = SM_Constants.SAP0111;
        mc.User_Keeper__c = u.id;
        insert mc;

        System.runAs(u){
            Group testGroup = new Group(Name='NL Medium Business', Type='Queue');
            insert testGroup;
            QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SObjectType = 'Operational_Tasks__c');
            insert testQueue;
            
            for(Operational_Tasks__c oTask: [SELECT Id, Name, OwnerId, Owner.Type FROM Operational_Tasks__c]){
               
                oTask.OwnerId = testGroup.Id;
                oTask.Status__c = 'Redial';
                updateOT.add(oTask);
                
                System.debug('updateOT: ' + updateOT);
               
                
                
                
            }
            SM_CheckRecursive.run = true;
            update updateOT;
            List <Operational_Tasks__c> updatedOT = new List <Operational_Tasks__c>([SELECT Id, Name, OwnerId, Owner.Type FROM Operational_Tasks__c]);
            Map<Id, Id> taskGroup = new Map<Id, Id>();
            for (Operational_Tasks__c ot : updatedOT) {
                if (ot.Owner.Type == 'Queue') {
                    taskGroup.put(ot.Id, ot.OwnerId);
                }
            }

            Map<Id, Group> queues = new Map<Id, Group>();
            if (!taskGroup.values().isEmpty()){
                queues = new Map<Id, Group>([Select Id, Name 
                            FROM Group 
                            WHERE Type = :SM_Constants.queue AND Id IN :taskGroup.values()]);
            }
            
            // Set<String> userName = new Set<String>();
            // userName.add(mc.Belgium__c);
            
            // List<User> users= new List<User>([Select Id, Name FROM User WHERE Name IN :userName]);
            // Map<String, Id> userId = new Map<String, Id>();
            
            // for (User userR : users) {
            //     userId.put(userR.Name, userR.Id);
            // }
            
            Group otGroup = new Group(); 
            otGroup = [Select Id, Name 
                        FROM Group 
                        WHERE Id = :testGroup.Id];
            System.assert(otGroup.Name == 'NL Medium Business');
             
        }
        
    }
    
    private static testMethod void testPositiveESP() {
        testSetup();
        
        User userInfo = new User();
        userInfo = [Select Id, Name FROM User LIMIT 1];
        List<Operational_Tasks__c> updateOT = new List<Operational_Tasks__c>();
        
        Profile p = [SELECT Id FROM Profile WHERE  Name =: 'System Administrator']; 
        User u = new User(Alias = 'standt', Email='sample@testUser1.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sample@testUser109.com', Sales_Organization__c = 'SAP_0333', Country= 'Belgium',
        Elevated_Access_Reason__c = 'Defect or Incident Resolution', Elevated_Access_Reference__c = 'ASDF');
        insert u;
        
        Queue_Lead_Task__c mc = new Queue_Lead_Task__c();
        mc.Name = SM_Constants.SAP0080;
        mc.User_Keeper__c = u.id;
        insert mc;

        System.runAs(u){
            Group testGroup = new Group(Name='Task Queue Spain', Type='Queue');
            insert testGroup;
            QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SObjectType = 'Operational_Tasks__c');
            insert testQueue;
            
            for(Operational_Tasks__c oTask: [SELECT Id, Name, OwnerId, Owner.Type FROM Operational_Tasks__c]){
               
                oTask.OwnerId = testGroup.Id;
                oTask.Status__c = 'Redial';
                updateOT.add(oTask);
                
                System.debug('updateOT: ' + updateOT);
               
               
                
                
            }
            SM_CheckRecursive.run = true;
            update updateOT;
            List <Operational_Tasks__c> updatedOT = new List <Operational_Tasks__c>([SELECT Id, Name, OwnerId, Owner.Type FROM Operational_Tasks__c]);
            Map<Id, Id> taskGroup = new Map<Id, Id>();
            for (Operational_Tasks__c ot : updatedOT) {
                if (ot.Owner.Type == 'Queue') {
                    taskGroup.put(ot.Id, ot.OwnerId);
                }
            }

            Map<Id, Group> queues = new Map<Id, Group>();
            if (!taskGroup.values().isEmpty()){
                queues = new Map<Id, Group>([Select Id, Name 
                            FROM Group 
                            WHERE Type = :SM_Constants.queue AND Id IN :taskGroup.values()]);
            }
            
            // Set<String> userName = new Set<String>();
            // userName.add(mc.Belgium__c);
            
            // List<User> users= new List<User>([Select Id, Name FROM User WHERE Name IN :userName]);
            // Map<String, Id> userId = new Map<String, Id>();
            
            // for (User userR : users) {
            //     userId.put(userR.Name, userR.Id);
            // }
            
            Group otGroup = new Group(); 
            otGroup = [Select Id, Name 
                        FROM Group 
                        WHERE Id = :testGroup.Id];
            System.assert(otGroup.Name == 'Task Queue Spain');
             
        }
        
    }
    
    private static testMethod void testPositiveDEU() {
        testSetup();
        
        User userInfo = new User();
        userInfo = [Select Id, Name FROM User LIMIT 1];
        List<Operational_Tasks__c> updateOT = new List<Operational_Tasks__c>();
        
        Profile p = [SELECT Id FROM Profile WHERE  Name =: 'System Administrator']; 
        User u = new User(Alias = 'standt', Email='sample@testUser1.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sample@testUser101029.com', Sales_Organization__c = 'SAP_0333', Country= 'Belgium',
        Elevated_Access_Reason__c = 'Defect or Incident Resolution', Elevated_Access_Reference__c = 'ASDF');
        insert u;
        
        Queue_Lead_Task__c mc = new Queue_Lead_Task__c();
        mc.Name = SM_Constants.SAP6712;
        mc.User_Keeper__c = u.id;
        insert mc; 
        
        
        
        System.runAs(u){
            Group testGroup = new Group(Name='Task Queue Germany', Type='Queue');
            insert testGroup;
            QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SObjectType = 'Operational_Tasks__c');
            insert testQueue;
            
            QueueGateKeepers__c mc1 = new QueueGateKeepers__c();
            mc1.Name = testGroup.Id;
            mc1.Sales_Org_ID__c = 'SAP_0333';
            mc1.User_Keeper__c = u.id;
            insert mc1; 
            
            for(Operational_Tasks__c oTask: [SELECT Id, Name, OwnerId, Owner.Type FROM Operational_Tasks__c]){
               
                oTask.OwnerId = testGroup.Id;
                oTask.Status__c = 'Redial';
                updateOT.add(oTask);
                
                System.debug('updateOT: ' + updateOT);
                
                
            }
            SM_CheckRecursive.run = true;
            update updateOT;
            List <Operational_Tasks__c> updatedOT = new List <Operational_Tasks__c>([SELECT Id, Name, OwnerId, Owner.Type FROM Operational_Tasks__c]);
            Map<Id, Id> taskGroup = new Map<Id, Id>();
            for (Operational_Tasks__c ot : updatedOT) {
                if (ot.Owner.Type == 'Queue') {
                    taskGroup.put(ot.Id, ot.OwnerId);
                }
            }

            Map<Id, Group> queues = new Map<Id, Group>();
            if (!taskGroup.values().isEmpty()){
                queues = new Map<Id, Group>([Select Id, Name 
                            FROM Group 
                            WHERE Type = :SM_Constants.queue AND Id IN :taskGroup.values()]);
            }
            
            // Set<String> userName = new Set<String>();
            // userName.add(mc.Belgium__c);
            
            // List<User> users= new List<User>([Select Id, Name FROM User WHERE Name IN :userName]);
            // Map<String, Id> userId = new Map<String, Id>();
            
            // for (User userR : users) {
            //     userId.put(userR.Name, userR.Id);
            // }
            
            Group otGroup = new Group(); 
            otGroup = [Select Id, Name 
                        FROM Group 
                        WHERE Id = :testGroup.Id];
            System.assert(otGroup.Name == 'Task Queue Germany');
             
        }
        
    }
    
    private static testMethod void testPositiveGBR() {
        testSetup();
        
        User userInfo = new User();
        userInfo = [Select Id, Name FROM User LIMIT 1];
        List<Operational_Tasks__c> updateOT = new List<Operational_Tasks__c>();
        
        Profile p = [SELECT Id FROM Profile WHERE  Name =: 'System Administrator']; 
        User u = new User(Alias = 'standt', Email='sample@testUser1.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sample@testUser19019.com', Sales_Organization__c = 'SAP_0333', Country= 'Belgium',
        Elevated_Access_Reason__c = 'Defect or Incident Resolution', Elevated_Access_Reference__c = 'ASDF');
        insert u;
        
        Queue_Lead_Task__c mc = new Queue_Lead_Task__c();
        mc.Name = SM_Constants.SAP6750;
        mc.User_Keeper__c = u.id;
        insert mc;  

        System.runAs(u){
            Group testGroup = new Group(Name='Task Queue United Kingdom', Type='Queue');
            insert testGroup;
            QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SObjectType = 'Operational_Tasks__c');
            insert testQueue;
            
            for(Operational_Tasks__c oTask: [SELECT Id, Name, OwnerId, Owner.Type FROM Operational_Tasks__c]){
               
                oTask.OwnerId = testGroup.Id;
                oTask.Status__c = 'Redial';
                updateOT.add(oTask);
                
                System.debug('updateOT: ' + updateOT);
               
            }
             SM_CheckRecursive.run = true;
update updateOT;
                
            List <Operational_Tasks__c> updatedOT = new List <Operational_Tasks__c>([SELECT Id, Name, OwnerId, Owner.Type FROM Operational_Tasks__c]);
            Map<Id, Id> taskGroup = new Map<Id, Id>();
            for (Operational_Tasks__c ot : updatedOT) {
                if (ot.Owner.Type == 'Queue') {
                    taskGroup.put(ot.Id, ot.OwnerId);
                }
            }

            Map<Id, Group> queues = new Map<Id, Group>();
            if (!taskGroup.values().isEmpty()){
                queues = new Map<Id, Group>([Select Id, Name 
                            FROM Group 
                            WHERE Type = :SM_Constants.queue AND Id IN :taskGroup.values()]);
            }
            
            // Set<String> userName = new Set<String>();
            // userName.add(mc.Belgium__c);
            
            // List<User> users= new List<User>([Select Id, Name FROM User WHERE Name IN :userName]);
            // Map<String, Id> userId = new Map<String, Id>();
            
            // for (User userR : users) {
            //     userId.put(userR.Name, userR.Id);
            // }
            
            Group otGroup = new Group(); 
            otGroup = [Select Id, Name 
                        FROM Group 
                        WHERE Id = :testGroup.Id];
            System.assert(otGroup.Name == 'Task Queue United Kingdom');
             
        }
        
    }
    
    private static testMethod void testPositiveDNK() {
        testSetup();
        
        User userInfo = new User();
        userInfo = [Select Id, Name FROM User LIMIT 1];
        List<Operational_Tasks__c> updateOT = new List<Operational_Tasks__c>();
        
        Profile p = [SELECT Id FROM Profile WHERE  Name =: 'System Administrator']; 
        User u = new User(Alias = 'standt', Email='sample@testUser1.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sample@testUser18728.com', Sales_Organization__c = 'SAP_0333', Country= 'Belgium',
        Elevated_Access_Reason__c = 'Defect or Incident Resolution', Elevated_Access_Reference__c = 'ASDF');
        insert u;
        
        Queue_Lead_Task__c mc = new Queue_Lead_Task__c();
        mc.Name = SM_Constants.SAP0975;
        mc.User_Keeper__c = u.id;
        insert mc;  

        System.runAs(u){
            Group testGroup = new Group(Name='Task Queue Denmark', Type='Queue');
            insert testGroup;
            QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SObjectType = 'Operational_Tasks__c');
            insert testQueue;
            
            for(Operational_Tasks__c oTask: [SELECT Id, Name, OwnerId, Owner.Type FROM Operational_Tasks__c]){
               
                oTask.OwnerId = testGroup.Id;
                oTask.Status__c = 'Redial';
                updateOT.add(oTask);
                
                System.debug('updateOT: ' + updateOT);
 
               
                
                
            }
             SM_CheckRecursive.run = true;
            update updateOT;
            List <Operational_Tasks__c> updatedOT = new List <Operational_Tasks__c>([SELECT Id, Name, OwnerId, Owner.Type FROM Operational_Tasks__c]);
            Map<Id, Id> taskGroup = new Map<Id, Id>();
            for (Operational_Tasks__c ot : updatedOT) {
                if (ot.Owner.Type == 'Queue') {
                    taskGroup.put(ot.Id, ot.OwnerId);
                }
            }

            Map<Id, Group> queues = new Map<Id, Group>();
            if (!taskGroup.values().isEmpty()){
                queues = new Map<Id, Group>([Select Id, Name 
                            FROM Group 
                            WHERE Type = :SM_Constants.queue AND Id IN :taskGroup.values()]);
            }
            
            // Set<String> userName = new Set<String>();
            // userName.add(mc.Belgium__c);
            
            // List<User> users= new List<User>([Select Id, Name FROM User WHERE Name IN :userName]);
            // Map<String, Id> userId = new Map<String, Id>();
            
            // for (User userR : users) {
            //     userId.put(userR.Name, userR.Id);
            // }
            
            Group otGroup = new Group(); 
            otGroup = [Select Id, Name 
                        FROM Group 
                        WHERE Id = :testGroup.Id];
            System.assert(otGroup.Name == 'Task Queue Denmark');
             
        }
        
    }
    
    private static testMethod void testPositiveSWE() {
        testSetup();
        
        User userInfo = new User();
        userInfo = [Select Id, Name FROM User LIMIT 1];
        List<Operational_Tasks__c> updateOT = new List<Operational_Tasks__c>();
        
        Profile p = [SELECT Id FROM Profile WHERE  Name =: 'System Administrator']; 
        User u = new User(Alias = 'standt', Email='sample@testUser1.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sample@testUser102918.com', Sales_Organization__c = 'SAP_0333', Country= 'Belgium',
        Elevated_Access_Reason__c = 'Defect or Incident Resolution', Elevated_Access_Reference__c = 'ASDF');
        insert u;
        
        Queue_Lead_Task__c mc = new Queue_Lead_Task__c();
        mc.Name = SM_Constants.SAP0976;
        mc.User_Keeper__c = u.id;
        insert mc; 

        System.runAs(u){
            Group testGroup = new Group(Name='Task Queue Sweden', Type='Queue');
            insert testGroup;
            QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SObjectType = 'Operational_Tasks__c');
            insert testQueue;
            
            for(Operational_Tasks__c oTask: [SELECT Id, Name, OwnerId, Owner.Type FROM Operational_Tasks__c]){
               
                oTask.OwnerId = testGroup.Id;
                oTask.Status__c = 'Redial';
                updateOT.add(oTask);
                
                System.debug('updateOT: ' + updateOT);
               
                
                
                
            }
            SM_CheckRecursive.run = true;
            update updateOT;
            List <Operational_Tasks__c> updatedOT = new List <Operational_Tasks__c>([SELECT Id, Name, OwnerId, Owner.Type FROM Operational_Tasks__c]);
            Map<Id, Id> taskGroup = new Map<Id, Id>();
            for (Operational_Tasks__c ot : updatedOT) {
                if (ot.Owner.Type == 'Queue') {
                    taskGroup.put(ot.Id, ot.OwnerId);
                }
            }

            Map<Id, Group> queues = new Map<Id, Group>();
            if (!taskGroup.values().isEmpty()){
                queues = new Map<Id, Group>([Select Id, Name 
                            FROM Group 
                            WHERE Type = :SM_Constants.queue AND Id IN :taskGroup.values()]);
            }
            
            // Set<String> userName = new Set<String>();
            // userName.add(mc.Belgium__c);
            
            // List<User> users= new List<User>([Select Id, Name FROM User WHERE Name IN :userName]);
            // Map<String, Id> userId = new Map<String, Id>();
            
            // for (User userR : users) {
            //     userId.put(userR.Name, userR.Id);
            // }
            
            Group otGroup = new Group(); 
            otGroup = [Select Id, Name 
                        FROM Group 
                        WHERE Id = :testGroup.Id];
            System.assert(otGroup.Name == 'Task Queue Sweden');
             
        }
        
    }
    
    private static testMethod void testPositiveNOR() {
        testSetup();
        
        User userInfo = new User();
        userInfo = [Select Id, Name FROM User LIMIT 1];
        List<Operational_Tasks__c> updateOT = new List<Operational_Tasks__c>();
        
        Profile p = [SELECT Id FROM Profile WHERE  Name =: 'System Administrator']; 
        User u = new User(Alias = 'standt', Email='sample@testUser1.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sample@testUser101928.com', Sales_Organization__c = 'SAP_0333', Country= 'Belgium',
        Elevated_Access_Reason__c = 'Defect or Incident Resolution', Elevated_Access_Reference__c = 'ASDF');
        insert u;
        
        Queue_Lead_Task__c mc = new Queue_Lead_Task__c();
        mc.Name = SM_Constants.SAP6864;
        mc.User_Keeper__c = u.id;
        insert mc;   

        System.runAs(u){
            Group testGroup = new Group(Name='Task Queue Norway', Type='Queue');
            insert testGroup;
            QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SObjectType = 'Operational_Tasks__c');
            insert testQueue;
            
            for(Operational_Tasks__c oTask: [SELECT Id, Name, OwnerId, Owner.Type FROM Operational_Tasks__c]){
               
                oTask.OwnerId = testGroup.Id;
                oTask.Status__c = 'Redial';
                updateOT.add(oTask);
                
                System.debug('updateOT: ' + updateOT);
               
                
                
                
            }
            SM_CheckRecursive.run = true;
update updateOT;
            List <Operational_Tasks__c> updatedOT = new List <Operational_Tasks__c>([SELECT Id, Name, OwnerId, Owner.Type FROM Operational_Tasks__c]);
            Map<Id, Id> taskGroup = new Map<Id, Id>();
            for (Operational_Tasks__c ot : updatedOT) {
                if (ot.Owner.Type == 'Queue') {
                    taskGroup.put(ot.Id, ot.OwnerId);
                }
            }

            Map<Id, Group> queues = new Map<Id, Group>();
            if (!taskGroup.values().isEmpty()){
                queues = new Map<Id, Group>([Select Id, Name 
                            FROM Group 
                            WHERE Type = :SM_Constants.queue AND Id IN :taskGroup.values()]);
            }
            
            // Set<String> userName = new Set<String>();
            // userName.add(mc.Belgium__c);
            
            // List<User> users= new List<User>([Select Id, Name FROM User WHERE Name IN :userName]);
            // Map<String, Id> userId = new Map<String, Id>();
            
            // for (User userR : users) {
            //     userId.put(userR.Name, userR.Id);
            // }
            
            Group otGroup = new Group(); 
            otGroup = [Select Id, Name 
                        FROM Group 
                        WHERE Id = :testGroup.Id];
            System.assert(otGroup.Name == 'Task Queue Norway');
             
        }
        
    }
    
    private static testMethod void testPositiveIRL() {
        testSetup();
        
        User userInfo = new User();
        userInfo = [Select Id, Name FROM User LIMIT 1];
        List<Operational_Tasks__c> updateOT = new List<Operational_Tasks__c>();
        
        Profile p = [SELECT Id FROM Profile WHERE  Name =: 'System Administrator']; 
        User u = new User(Alias = 'standt', Email='sample@testUser1.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sample@testUser19812.com', Sales_Organization__c = 'SAP_0333', Country= 'Belgium',
        Elevated_Access_Reason__c = 'Defect or Incident Resolution', Elevated_Access_Reference__c = 'ASDF');
        insert u;
        
        Queue_Lead_Task__c mc = new Queue_Lead_Task__c();
        mc.Name = SM_Constants.SAP6709;
        mc.User_Keeper__c = u.id;
        insert mc;   

        System.runAs(u){
            Group testGroup = new Group(Name='Task Queue Ireland', Type='Queue'); 
            insert testGroup;
            QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SObjectType = 'Operational_Tasks__c');
            insert testQueue;
            
            for(Operational_Tasks__c oTask: [SELECT Id, Name, OwnerId, Owner.Type FROM Operational_Tasks__c]){
               
                oTask.OwnerId = testGroup.Id;
                oTask.Status__c = 'Redial';
                updateOT.add(oTask);
                
                System.debug('updateOT: ' + updateOT);
               
                
                
                
            }
            SM_CheckRecursive.run = true;
update updateOT;
            List <Operational_Tasks__c> updatedOT = new List <Operational_Tasks__c>([SELECT Id, Name, OwnerId, Owner.Type FROM Operational_Tasks__c]);
            Map<Id, Id> taskGroup = new Map<Id, Id>();
            for (Operational_Tasks__c ot : updatedOT) {
                if (ot.Owner.Type == 'Queue') {
                    taskGroup.put(ot.Id, ot.OwnerId);
                }
            }

            Map<Id, Group> queues = new Map<Id, Group>();
            if (!taskGroup.values().isEmpty()){
                queues = new Map<Id, Group>([Select Id, Name 
                            FROM Group 
                            WHERE Type = :SM_Constants.queue AND Id IN :taskGroup.values()]);
            }
            
            // Set<String> userName = new Set<String>();
            // userName.add(mc.Belgium__c);
            
            // List<User> users= new List<User>([Select Id, Name FROM User WHERE Name IN :userName]);
            // Map<String, Id> userId = new Map<String, Id>();
            
            // for (User userR : users) {
            //     userId.put(userR.Name, userR.Id);
            // }
            
            Group otGroup = new Group(); 
            otGroup = [Select Id, Name 
                        FROM Group 
                        WHERE Id = :testGroup.Id];
            System.assert(otGroup.Name == 'Task Queue Ireland');
             
        }
        
    }
    
    
    private static testMethod void testDeletion1() {
        testSetup();
        
        Profile p = [SELECT Id FROM Profile WHERE  Name =: 'System Administrator']; 
        User u = new User(Alias = 'standt', Email='sample@testUser1.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sample@testUser101981.com', Country= 'Belgium',
        Elevated_Access_Reason__c = 'Defect or Incident Resolution', Elevated_Access_Reference__c = 'ASDF');
        
        System.runAs(u){
            Account acc = new Account();
            acc.Name = 'accName';
            acc.Second_Account_Name__c = 'sAccName';
            acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
            acc.Phone = '+31302979111';
            insert acc;
            
            Task taskRec = new Task();
            taskRec.WhatId = acc.Id;
            insert taskRec;
            
            Operational_Tasks__c otRec = new Operational_Tasks__c();
            otRec.Task_ID__c = taskRec.Id;
            insert otRec;
            
            try {
                delete otRec;
                System.assert(otRec != Null);
            }catch(Exception e){
                System.debug('Exception');
            }
            
        }
        
    }
    
    private static testMethod void testDeletion2() {
        testSetup();
        
        Profile p = [SELECT Id FROM Profile WHERE  Name = : 'System Administrator']; 
        User u = new User(Alias = 'standt', Email='sample@testUser1.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sample@testUser1019281.com', Country= 'Netherlands',
        Elevated_Access_Reason__c = 'Defect or Incident Resolution', Elevated_Access_Reference__c = 'ASDF');
        
        System.runAs(u){
            Account acc = new Account();
            acc.Name = 'accName';
            acc.Second_Account_Name__c = 'sAccName';
            acc.Sales_Organization__c = 'SAP_0333';
            //acc.Sales_Office__c = 'SAP_F020';
            acc.Phone = '+31302979111';
            insert acc;
            
            Task taskRec = new Task();
            taskRec.WhatId = acc.Id;
            insert taskRec;
            
            Operational_Tasks__c otRec = new Operational_Tasks__c();
            otRec.Task_ID__c = taskRec.Id;
            insert otRec;
            
            try {
                delete otRec;
                
            }catch(Exception e){
                System.debug('Exception');
                System.assert(e != Null);
            }
            
        }
        
    }
    
    
}