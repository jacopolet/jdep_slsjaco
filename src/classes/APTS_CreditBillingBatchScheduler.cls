/**
* Class Name : APTS_CreditBillingBatchScheduler 
* Description : Apex Class to schedule APTS_CreditBillingBatchScheduler Class
* Author : Renuka (Accenture)
* Date Created : 07/08/2020
********************************************************************************************/
global without sharing class APTS_CreditBillingBatchScheduler implements Schedulable {
   global void execute(SchedulableContext sc) {
        //Get all the country values from custom setting and pass the one with Sequence=1
        String salesOrg = '';
        Map<Integer, APTS_Credit_Batch_Countries__c> countrySeqMap = new Map<Integer, APTS_Credit_Batch_Countries__c>();
        for(APTS_Credit_Batch_Countries__c bcRec : APTS_Credit_Batch_Countries__c.getAll().values()){
            countrySeqMap.put(Integer.valueOf(bcRec.APTS_Sequence__c), bcRec);
        }
        APTS_Credit_Batch_Countries__c rbcRec;
        for(Integer i=1 ; i<=countrySeqMap.size() ; i++){  
            rbcRec = countrySeqMap.get(i);
            if(!rbcRec.APTS_Processed__c && rbcRec.APTS_Sequence__c == 1){
                salesOrg = rbcRec.APTS_Sales_Org__c;
                break;
            }
        }
        APTS_CreditBillingBatch obj = new APTS_CreditBillingBatch(salesOrg);
        Database.executeBatch(obj,100);
    }
}