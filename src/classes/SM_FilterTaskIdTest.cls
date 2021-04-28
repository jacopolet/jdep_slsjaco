@isTest
public without sharing class SM_FilterTaskIdTest {
    private static testMethod void callFilterTaskId() {
        Id InboundRT = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();

        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        acc.Account_Tier__c = 'Platinum';
        insert acc;

        List<Task> taskRecords = new List<Task>();
        for(integer x = 0; x <= 1; x++) {
            Task taskRec = new Task();
            taskRec.WhatId = acc.Id;
            taskRec.RecordTypeId = InboundRT;
            taskRecords.add(taskRec);
            
        }

        Test.startTest();
        Test.setCurrentPage(Page.SM_ChangeTaskOwner);
        ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(taskRecords);
        stdSetController.setSelected(taskRecords);
        SM_FilterTaskId ext = new SM_FilterTaskId(stdSetController);
        Test.stopTest();
    }

    private static testMethod void callFilterTaskIdChangeStatus() {
        Id InboundRT = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Inbound').getRecordTypeId();

        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        acc.Account_Tier__c = 'Platinum';
        insert acc;

        List<Task> taskRecords = new List<Task>();
        for(integer x = 0; x <= 1; x++) {
            Task taskRec = new Task();
            taskRec.WhatId = acc.Id;
            taskRec.RecordTypeId = InboundRT;
            taskRecords.add(taskRec);
            
        }

        Test.startTest();
        Test.setCurrentPage(Page.SM_ChangeTaskStatus);
        ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(taskRecords);
        stdSetController.setSelected(taskRecords);
        SM_FilterTaskId ext = new SM_FilterTaskId(stdSetController);
        Test.stopTest();
    }
}