/*
* @author        Aditya
* @date          11.12.2018           
* @description   This class will call batch class called UpdateAccountCallList
* @revision(s)
* @class         Test class :Salescall_Scheduleclass_Test ,Batch class:UpdateAccountCallList
*/


global with sharing class SalescallScheduleforBelgium  implements Schedulable {
    global void execute(SchedulableContext sc) {
        CustomLogging.push('execute', 'SalescallScheduleforBelgium');
		try {
            //get value from custom settings
            Map<String, Sales_Call_Batch_Scope__c> cons = null;
            cons = Sales_Call_Batch_Scope__c.getAll();
            Sales_Call_Batch_Scope__c consVal;
            
            String[] OrgApis = new String[] {'SAP_0333'};      
            DateTime dt = System.now();
            
            consVal = cons.get('salesCallScopeBelgium');
            Database.executeBatch(new UpdateAccountCallList(OrgApis), integer.valueOf(consVal.Value__c));
        } catch(exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop(); 
    }
}