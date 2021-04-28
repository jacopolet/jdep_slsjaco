/**
 * @author        Abram Vixen Reyes
 * @date          January 30, 2020
 * @description   Apex batch class to send all generated work orders from TS_RouteTask_Batch to ClickSoftware
 * @revision(s)  
 */
global without sharing class TS_RouteTaskIntegrationRoute_Batch implements Database.Batchable <sObject> {

    Boolean isFirstRun;
    Date taskDate;
    Integer runCount;

    //DOO-3001 Karen Hung 3-4-2020 variable for nordics 
    public Boolean nordics = false;

    //XEN REYES DOO-4347 April 8, 2020
    Set<Id> additionalWorkOrder = new Set<Id>();

    global TS_RouteTaskIntegrationRoute_Batch(Date task, Boolean first, Integer cnt, Set<Id> addSet) {
        taskDate = task;
        runCount = cnt;
        isFirstRun = first;
        additionalWorkOrder = addSet;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        CustomLogging.push('START', 'TS_RouteTaskIntegrationRoute_Batch');
        String query = '';
        String final_query = '';
        String recordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get(TS_Constants.TS_WO_RECORDTYPE_OPERATINGROUTEWO).getRecordTypeId();
        DescribeSObjectResult wo_Describe = WorkOrder.getSObjectType().getDescribe();
        List<String> fields = new List<String>(wo_Describe.fields.getMap().keySet());

        /*if(isFirstRun == true){
            query = 'SELECT ' + String.join(fields, ',') +' FROM WorkOrder WHERE RecordtypeId =' +'\''+ recordTypeId +'\''+
                       ' AND Status IN (\'Open\',\'Scheduled\') '+
                       ' AND WorkOrderType__c =\'S20\' ' +
                       ' AND CreatedDate = TODAY ' +
                       ' AND SalesOrganization__c = \'SAP_0111\' ' + 
                       ' AND DAY_ONLY(SLA_Date__c) = :taskdate' ;
        }*/
        
        //XEN REYES DOO-4347 April 8, 2020 (Pre-query)
        //Karen Hung 7/4/2020 updated query to accommodate nordics scenario DOO-4349
        query = 'SELECT ' + String.join(fields, ',') +' FROM WorkOrder WHERE RecordtypeId =' +'\''+ recordTypeId +'\''+
                    ' AND Status IN (\'Open\',\'Scheduled\') '+
                    ' AND WorkOrderType__c =\'S20\' ' +
                    ' AND CreatedDate = TODAY ' +
            		' AND Third_Party__c = false ' + //Karen Hung 08/02/2021 DOO-5161 Exclude Third Party
                    (!nordics ? ' AND SalesOrganization__c = \'SAP_0111\' ' : ' AND SalesOrganization__c != \'SAP_0111\' ') + 
                    (!nordics ? ' AND DAY_ONLY(SLA_Date__c) = :taskdate' : '') +
                    ' AND Id NOT IN (SELECT Work_Order__c FROM Integration_Log__c WHERE Integration_Status__c = \'Target System Success\' AND CreatedDate = TODAY) ';
        
        List<WorkOrder> woList = Database.query(query);
        Map<Id, WorkOrder> map_preQuery = new Map<Id, WorkOrder>(woList);
        Set<Id> keySet = map_preQuery.keySet();

        final_query = 'SELECT ' + String.join(fields, ',') +' FROM WorkOrder' +
                        ' WHERE Id IN: keySet OR Id IN: additionalWorkOrder ';
   
        CustomLogging.pop();
    	return Database.getQueryLocator(final_query);
    }

    global void execute(Database.BatchableContext BC, List<WorkOrder> wo_items_list) {
		CustomLogging.push('EXECUTE', 'TS_RouteTaskIntegrationRoute_Batch');

        List<Integration_Log__c> integ_list = new List<Integration_Log__c>();
        if(!wo_items_list.isEmpty()){
            for(WorkOrder wo_var : wo_items_list){
                integ_list.add(new Integration_Log__c( Object__c = INT_Constants.WOLI_CREATEUPDATE_OPERATINGROUTE_TASK,
                                                       Object_Id__c = wo_var.Id,
                                                       Work_Order__c = wo_var.Id,
                                                       Ready_To_Be_Sent__c = true,
                                                       Integration_Status__c = 'Initial',
                                                       Triggered_Timestamp__c = DateTime.now()));
            }

            if(!integ_list.isEmpty()){
                try{
                    insert integ_list;
                } catch(Exception ex){
                    CustomLogging.debugException(ex);
                    CustomLogging.pop();
                    System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
                }
            }
        }

        CustomLogging.pop();
    }

    global void finish(Database.BatchableContext BC) {    
        CustomLogging.push('finish', 'TS_RouteTaskIntegrationRoute_Batch');
        //START RERUN OF BATCHES
        if( Integer.valueOf(System.Label.TS_RouteTaskIntRouBatchCount) >= 0 && 
            Integer.valueOf(System.Label.TS_RouteTaskIntRouBatchCount) > runCount ){
            runCount = runCount+1;
            //Karen Hung DOO-3001 Integration 6.4.2020
            TS_RouteTaskIntegration_Batch intBatch = new TS_RouteTaskIntegration_Batch(taskDate, false, runCount);
            intBatch.nordicsBatch = nordics;
            Database.executeBatch(intBatch, 1);
        }        
    }
}