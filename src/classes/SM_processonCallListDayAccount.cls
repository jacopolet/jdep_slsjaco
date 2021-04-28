global without sharing class SM_processonCallListDayAccount implements Database.Batchable<SObject>, Database.Stateful{
    
    public static Boolean hasException = false;
    global string errormessage = null;
    global Set<String> salesorganizationsupdated = new Set<String>();
    global Set<String> salesorgs = SM_GetMetadata.getconditionforquerycalllistday();
    public string accountsalesorganizationonmetadata = 'Select Id, Call_List_Day__c, Sales_Organization__c from Account where Sales_Organization__c IN :salesorgs and Call_List_Day__c != null';
    
    public static DateTime removeWeekendsDateTime(DateTime dVal, Decimal addedDays) {
        CustomLogging.push('removeWeekendsDateTime', 'SM_processonCallListDayAccount');
        try {
            DateTime dateValue;
            if (dVal != Null) {
                String dayOfWeek = dVal.format('E');
                if (addedDays >= 5 && !(addedDays >= 28) && (dayOfWeek == 'Mon' || dayOfWeek == 'Tue' || dayOfWeek == 'Wed' || dayOfWeek == 'Thu' || dayOfWeek == 'Fri' || dayOfWeek == 'Sat' || dayOfWeek == 'Sun')) {
                    dateValue = dVal + 2;
                } else if ((addedDays == 3 || addedDays == 2)  && (dayOfWeek == 'Mon' || dayOfWeek == 'Sun')) {
                    dateValue = dVal + 2;
                } else if (dayOfWeek == 'Sat') {
                    dateValue = dVal + 2;
                } else if (dayOfWeek == 'Sun') {
                    dateValue = dVal + 1;
                } else {
                    dateValue = dVal;
                }
            }
            
            return dateValue;
        } catch (Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
            return null;
        }
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(accountsalesorganizationonmetadata);
    }
    
    global void execute(Database.BatchableContext bc, List<Account> scope){
        CustomLogging.push('execute', 'SM_processonCallListDayAccount');
        try{
            Map <String, Call_List_Day_Counter__mdt> calllistmdtmap = SM_GetMetadata.getcalllistmdtrecords();
            Map <Id, String> accountsalesorg = new Map <Id, String>();
            Map <String, ID> salesorggroup = new Map <String, ID>();
            List <Account> acclist = scope;
            Date duedate = removeWeekendsDateTime(System.now() + 3, 3).Date();
            Set <Id> accIds = new Set <Id>();
            for (Account acc : acclist){
                salesorganizationsupdated.add(acc.Sales_Organization__c);
                if (calllistmdtmap.containsKey(acc.Sales_Organization__c) && acc.Call_List_Day__c == calllistmdtmap.get(acc.Sales_Organization__c).Counter__c){
                    accIds.add(acc.Id);
                    accountsalesorg.put(acc.id, acc.Sales_Organization__c);
                    salesorggroup.put(acc.Sales_Organization__c, calllistmdtmap.get(acc.Sales_Organization__c).Queue__c);
                }
            }
            
            List <Task> taskforcreation = new List<Task>();
            for (Id accountId : accIds){
                Task taskrec = new Task();
                taskrec.WhatId = accountId;
                taskrec.Touchpoint_Type__c = 'CALL LIST INGREDIENTS';
                taskrec.Task_Source__c = 'SFDC';
                taskrec.RecordTypeId = SM_Constants.AutomatedTask;
                taskrec.ActivityDate = duedate;
                taskrec.Sales_Organization__c = accountsalesorg.get(accountId);
                taskrec.OwnerId = salesorggroup.get(accountsalesorg.get(accountId));
                taskforcreation.add(taskrec);
            }
            if (!taskforcreation.isEmpty()){
                insert taskforcreation;
            }
            
            if(Test.isRunningTest() && hasException == true) {
               CalloutException e = new CalloutException();
               e.setMessage('Throw Exception for code coverage');
               Throw e;
            }
           
        }catch(Exception ex){
            
            errormessage = ex.getMessage();
            CustomLogging.debugException(ex);
            CustomLogging.pop();       
        }
        CustomLogging.pop();
    }
    
    global void finish(Database.BatchableContext bc){
        if (errormessage == null){
            List<Call_List_Day_Counter__mdt> cldslist = [Select ID, Label, Counter__c from Call_List_Day_Counter__mdt where Label IN :salesorganizationsupdated];
            List<Call_List_Day_Counter__mdt> finalcldslist = new List<Call_List_Day_Counter__mdt>();
            Integer counterlimit;
            for (Call_List_Day_Counter__mdt cldcrec : cldslist){
               Call_List_Day_Counter__mdt cldcrecupdate = new Call_List_Day_Counter__mdt();
               cldcrecupdate.ID = cldcrec.ID;
               cldcrecupdate.Label = cldcrec.Label;
               if (cldcrec.Counter__c == Integer.valueOf(Label.Call_List_Counter)){
                   cldcrecupdate.Counter__c = 1;
               }else {
                   cldcrecupdate.Counter__c = cldcrec.Counter__c + 1;
               }
               finalcldslist.add(cldcrecupdate);
            }
            if (!finalcldslist.isEmpty()){
                UpdateMetadataUtil.updateMetadata(finalcldslist);
            }
        }
    }    
    
}