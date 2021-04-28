/**********************************************************************************
 * @Author: Jason Mactal
 * @Company: Accenture
 * @Description: Sets the Agreement that is In Signatures|Other Party Signatures to Expired|Canceled when it's pass Validity Date
 * @Created Date: June 25, 2018
 * @History:
 *      <Name>              <Date>          <Description>
 *      jason.e.mactal      06.25.2018      Created
 * 
 **********************************************************************************/

global class APTS_CancelAgreementBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    String query;
    
    global APTS_CancelAgreementBatch(){
    
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        
        query = Label.APTS_CancelAgreementBatchQuery;
    
    return Database.getQueryLocator(query);
    
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        //If Agreement is pass its Agreement Proposal Valid Date set Status = 'Cancelled' and Status Category = 'Expired'
        try{
            List<Apttus__APTS_Agreement__c> listAgreements = (List<Apttus__APTS_Agreement__c>) scope;
            if(listAgreements != null && listAgreements.size() > 0 ){
                for(Apttus__APTS_Agreement__c aggr: listAgreements){
                    aggr.Apttus__Status_Category__c = Label.APTS_Expired;
                    aggr.Apttus__Status__c = Label.APTS_Cancelled;
                }
                database.update(listAgreements);
            }
        }catch(Exception e){
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Agreement', null,'CPQ',false,true,'cpqerror@accenture.com',true);
        }
    }
    global void finish(Database.BatchableContext BC){}

}