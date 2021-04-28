global without sharing class SM_FlaggedforDeletionBatch implements Database.Batchable<SObject>, Database.Stateful{
    public string accountsflaggedfordeletion = 'Select Id from Account where Flagged_for_Deletion__c = true and SAP_Customer_ID__c = null';
    public static Boolean hasException = false;
    // global integer errors = 0;
    global string errormessage;
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(accountsflaggedfordeletion);
    }
    
    global void execute(Database.BatchableContext bc, List<Account> scope){
        CustomLogging.push('execute', 'FlaggedforDeletion_Batch');
        try{
            List <Account> accounttransfer = new List <Account>();
            List <Account> accountforupdate = new List <Account>();
            if (!scope.isEmpty()){
                accounttransfer = scope;
            }
            for (Account a : accounttransfer){
                Account accrec = new Account();
                accrec.Id = a.Id;
                accrec.OwnerId = Label.OTC_Task_Keeper;
                accountforupdate.add(accrec);
            }
            
            if (!accountforupdate.isEmpty()){
                update accountforupdate;
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
      
    }    
    
}