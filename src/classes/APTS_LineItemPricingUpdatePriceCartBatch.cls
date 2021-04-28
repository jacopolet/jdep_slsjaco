/******************************
Class Name: APTS_LineItemPricingUpdatePriceCartBatch
Job Name: 
*******************************/
global with sharing class APTS_LineItemPricingUpdatePriceCartBatch implements Database.Batchable<sObject>,Database.Stateful{

    public integer batchSize;
    public boolean reRunBatch; 
    public string query;
    List<APTS_Batch_Error__c> lstErrorLogs = new List<APTS_Batch_Error__c>();   
              
    public APTS_LineItemPricingUpdatePriceCartBatch(integer batchSize,String query){
        this.batchSize = batchSize;
        this.reRunBatch = false;
        this.query = query;
    }
                           
    global Database.QueryLocator start(Database.BatchableContext BC){
           return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Apttus_Config2__ProductConfiguration__c> scope){  
            lstErrorLogs = new List<APTS_Batch_Error__c>(); 
            for(Apttus_Config2__ProductConfiguration__c cart: scope ){
                try{
                     Apttus_CpqApi.CPQ.UpdatePriceRequestDO objUpdatePriceRequestDO = new Apttus_CpqApi.CPQ.UpdatePriceRequestDO();
                     objUpdatePriceRequestDO.CartId = cart.id;
                     Apttus_CpqApi.CPQ.UpdatePriceResponseDO objUpdatePrice = Apttus_CpqApi.CPQWebService.updatePriceForCart(objUpdatePriceRequestDO);
                     
                     if(!reRunBatch && objUpdatePrice.IsPricePending){
                       reRunBatch = objUpdatePrice.IsPricePending;
                     }
                 }catch(Exception e){
                    lstErrorLogs.add(APTS_CommonBatch_Helper.createBatchErrorObject(null, BC.getJobId()+'---'+e.getMessage() + '<>' +  e.getStackTraceString(), cart.id, 'Product COnfiguration', 'Error Occured During update Price Cart batch', 'APTS_LineItemPricingUpdatePriceCartBatch'));                             
                }
           }
            insert lstErrorLogs;
    }

    global void finish(Database.BatchableContext BC){
       if(reRunBatch){
             Id batchInstanceId = Database.executeBatch(new APTS_LineItemPricingUpdatePriceCartBatch(batchSize,query),batchSize);
        }
    }

}