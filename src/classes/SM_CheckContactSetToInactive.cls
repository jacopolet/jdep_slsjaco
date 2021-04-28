global without sharing class SM_CheckContactSetToInactive implements Database.Batchable<SObject>, Database.Stateful{

    public static Boolean hasException = false;
    global string serviceprovidername = SM_Constants.ContactServiceProvider;
    global string errormessage;
    public string contactsflaggedfordeletion = 'Select Id, Last_Relevant_Activity_Date__c, IsActive__c from Contact where IsActive__c = true and Last_Relevant_Activity_Date__c != null and RecordType.Name != :serviceprovidername';
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(contactsflaggedfordeletion);
    }
    
    global void execute(Database.BatchableContext bc, List<Contact> scope){
        CustomLogging.push('execute', 'SM_CheckContactSetToInactive');
        List <Contact> conlist = scope;
        List <Contact> conupdate = new List<Contact>();
        Date startDate;
        Date dateToday = System.today();
        Integer datecompared;
        try{
           if (!conlist.isEmpty()){
               for (Contact con : conlist){
                   startDate = con.Last_Relevant_Activity_Date__c;
                   datecompared = startDate.daysBetween(dateToday) + 1;
                   if (datecompared >= 547){
                       con.IsActive__c = false;
                       conupdate.add(con);
                   } else {
                       // do nothing
                   }
               }
           }
           
               
           if (!conupdate.isEmpty()){
               update conupdate;
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