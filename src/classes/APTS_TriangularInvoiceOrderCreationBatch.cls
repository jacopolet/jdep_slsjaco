/*************************************************************
@Name: APTS_TriangularInvoiceOrderCreationBatch 
@Author: Sai Sagar
@CreateDate: 
@Description: Batch class created for APTS_TriangularInvoiceUpload Batch Size should be ONE - AS IT IS invoking ALL APTTUS API for each ORDER
@UsedBy: 
******************************************************************/
global without sharing class APTS_TriangularInvoiceOrderCreationBatch implements Database.Batchable<String>, Database.Stateful {
    
    global string batchId;
    map<string, list<Sobject>> orderLineMap = new map<string, list<Sobject>>();
    public list<Apttus_Config2__Order__c> orderList;
   global set<Id> orderIDSet;
   global set<Id> ordIDSet = new set<Id>();
   global set<Id> orderIDtoFinalizeBatch = new set<Id>();

    global APTS_TriangularInvoiceOrderCreationBatch(string batchId, map<string, list<Sobject>> orderLineMap) {
        this.orderLineMap = orderLineMap; 
        this.batchId = batchId;
    }

    global list<string> start(Database.BatchableContext BC) {
        list<string> orderRefList = new list<string>();
        orderRefList.addall(orderLineMap.keyset());
        return orderRefList;
    }

    global void execute(Database.BatchableContext BC, list<string> scope) {  
        APTS_TriangularInvoicebatchHandler invoiceHandler = new APTS_TriangularInvoicebatchHandler();
        orderIDSet = invoiceHandler.ProcessOrderCreation(scope, orderLineMap);
        orderIDtoFinalizeBatch.addAll(orderIDSet);  
        
    }
    
    global void finish(Database.BatchableContext BC) {

        try {

        system.debug('Finish Method :: '+ordIDSet);
        ordIDSet = new set<Id>();
        //v100 << ++ Added as part of the Duplicate Integration Log Issue 
        Set<String> orderComp = (Set<String>)JSON.deserialize(JSON.serialize(orderIDtoFinalizeBatch), Set<String>.class);
        //v100 ++ >> 
        


        for(APTS_TriangleInvoiceOrders__c ord : [Select Id, Order__c from APTS_TriangleInvoiceOrders__c where BatchId__c =: batchId and Order__c IN : orderComp])
        {
            
            
            if(!ordIDSet.contains(ord.Order__c))
            {
                ordIDSet.add(ord.Order__c);
            }
        }
        if(ordIDSet.contains(null))
        {
            ordIDSet.remove(null);
        }
        

         if(orderIDtoFinalizeBatch.size() > 0) {
            APTS_TriangularInvoiceFinalizeBatch batch = new APTS_TriangularInvoiceFinalizeBatch(batchId, ordIDSet);
            database.executeBatch(batch, 1);
        }        
       
        }catch(Exception ex){
            APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString(), 'APTS_TriangularInvoiceOrderCreationBatch', null, 'OM', false, false, null, true);}
        }
  
 
}