global without sharing class SM_CheckAccountsSetToInactive implements Database.Batchable<SObject>, Database.Stateful{

    public static Boolean hasException = false;
    global id serviceproviderId = SM_Constants.recordTypeIdServiceProvider;
    global string errormessage;
    public string accountsflaggedfordeletion = 'Select Id, Last_Relevant_Activity_Date__c, IsActive__c from Account where IsActive__c = true and Last_Relevant_Activity_Date__c != null and RecordTypeID != :serviceproviderId';
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(accountsflaggedfordeletion);
    }
    
    global void execute(Database.BatchableContext bc, List<Account> scope){
        CustomLogging.push('execute', 'SM_CheckAccountsSetToInactive');
        List <Account> acclist = scope;
        List <Account> accupdate = new List<Account>();
        Date startDate;
        Date dateToday = System.today();
        Integer datecompared;
        try{
           if (!acclist.isEmpty()){
               for (Account acc : acclist){
                   startDate = acc.Last_Relevant_Activity_Date__c;
                   datecompared = startDate.daysBetween(dateToday) + 1;
                   if (datecompared >= 547){
                       acc.IsActive__c = false;
                       accupdate.add(acc);
                   } else {
                       // do nothing
                   }
               }
           }
           
               
           if (!accupdate.isEmpty()){
               update accupdate;
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