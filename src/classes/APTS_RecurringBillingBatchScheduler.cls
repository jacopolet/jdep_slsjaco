/**
* Class Name : APTS_RecurringBillingBatchScheduler 
* Description : Apex Class to schedule APTS_RecurringBillingBatchScheduler Class
* Author : BALASHANTHI (b.arigopalan@accenture.com)
* Date Created : 21/05/2018
********************************************************************************************
* * Revision V101 - Balashanthi A - CR # 2265 To run Recurring Batch for all countries
**/
global without sharing class APTS_RecurringBillingBatchScheduler implements Schedulable {
	/** Method Name : execute
    * Description : Schedular Class to call APTS_RecurringBillingScheduleBatch.cls
    **/
    global void execute(SchedulableContext sc) {
        //Get all the country values from custom setting and pass the one with Sequence=1
        String salesOrg = '';
        Map<Integer, APTS_Recurring_Batch_Countries__c> countrySeqMap = new Map<Integer, APTS_Recurring_Batch_Countries__c>();
        for(APTS_Recurring_Batch_Countries__c bcRec : APTS_Recurring_Batch_Countries__c.getAll().values()){
            countrySeqMap.put(Integer.valueOf(bcRec.APTS_Sequence__c), bcRec);
        }
        APTS_Recurring_Batch_Countries__c rbcRec;
        for(Integer i=1 ; i<=countrySeqMap.size() ; i++){  
            rbcRec = countrySeqMap.get(i);
            if(!rbcRec.APTS_Processed__c && rbcRec.APTS_Sequence__c == 1){
                salesOrg = rbcRec.APTS_Sales_Org__c;
                break;
            }
        }
        APTS_RecurringBillingScheduleBatch obj = new APTS_RecurringBillingScheduleBatch(salesOrg);
        Database.executeBatch(obj,100);
    }
}