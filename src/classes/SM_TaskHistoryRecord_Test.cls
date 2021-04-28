@isTest
public without sharing class SM_TaskHistoryRecord_Test {
    static testMethod void fetchTaskHistoryRecord() {
        test.startTest();
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        acc.Phone = '+31302979111';
        acc.Account_Tier__c = 'Platinum';
        insert acc;

        Task taskRec = new Task();
        taskRec.WhatId = acc.Id;
        taskRec.Status = 'Open';
        insert taskRec;

        Task_History__c th = new Task_History__c();
        th.Status__c = taskRec.Status;
        th.Task_Id__c = taskRec.Id;
        insert th;

        List<Task_History__c> result = SM_TaskHistoryRecord.getTaskHistory(taskRec.Id);
        System.assert(result.size() > 0);
    }
}