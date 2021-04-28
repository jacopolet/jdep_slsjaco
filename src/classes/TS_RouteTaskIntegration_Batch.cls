/**
 * @author        Abram Vixen Reyes
 * @date          January 14, 2020
 * @description   Apex batch class to send all generated work orders from TS_RouteTask_Batch to ClickSoftware
 * @revision(s)  
 */
global without sharing class TS_RouteTaskIntegration_Batch implements Database.Batchable <sObject>, Database.Stateful {

    Date taskDate;
    Boolean isFirstRun;
    Integer runCount;
    private List<String> exception_List = new List<String>();

    //STATEFUL - XEN REYES DOO-4347 April 8, 2020
    Set<Id> workOrder_id = new Set<Id>();

    //Karen Hung 3/4/2020 DOO-3001 variable for nordics
    public Boolean nordicsBatch = false;
    
    global TS_RouteTaskIntegration_Batch(Date task, Boolean first, Integer cnt) {
        taskDate = task;
        isFirstRun = first;
        runCount = cnt;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        CustomLogging.push('START', 'TS_RouteTaskIntegration_Batch');
        String query = '';
        String recordTypeId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get(TS_Constants.TS_WOLI_RECORDTYPE_OPERATINGTASK).getRecordTypeId();
        DescribeSObjectResult wo_Describe = WorkOrderLineItem.getSObjectType().getDescribe();
        List<String> fields = new List<String>(wo_Describe.fields.getMap().keySet());

        //QUERY FOR ALL WOLI
       /* if(isFirstRun == true){
            query = 'SELECT ' + String.join(fields, ',') +' FROM WorkOrderLineItem WHERE RecordtypeId =' +'\''+ recordTypeId +'\''+
                       ' AND Status NOT IN (\'Completed\',\'Canceled\',\'Scheduled\') AND WorkOrderType__c =\'S20\''+
                       ' AND WorkOrder.SalesOrganization__c = \'SAP_0111\' AND DAY_ONLY(SLADate__c) = :taskdate AND isFromRoute__c = true';

        }*/
        //Karen Hung DOO-4349 07.04.2020 updated for Nordics
        query = 'SELECT ' + String.join(fields, ',') +' FROM WorkOrderLineItem '+
                    'WHERE Status = \'Open\' ' +
                    'AND WorkOrderType__c = \'S20\' ' +
                     (!nordicsBatch ? 'AND WorkOrder.SalesOrganization__c = \'SAP_0111\' ' : 'AND WorkOrder.SalesOrganization__c != \'SAP_0111\' ') +
                    'AND CreatedDate = TODAY '+
            		'AND WorkOrder.Third_Party__c = false '+ //Karen Hung 08/02/2021 DOO-5161 Exclude Third Party
                    'AND RetriggerClick__c = 1 '+
                    'AND WorkOrder.RecordType.DeveloperName = \'Operating_Route_Work_Order\' ' +
                    'AND Id NOT IN (SELECT Work_Order_Line_Item__c FROM Integration_Log__c WHERE Integration_Status__c = \'Target System Success\')';
       

        CustomLogging.pop();
    	return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<WorkOrderLineItem> woli_items_list) {
		CustomLogging.push('EXECUTE', 'TS_RouteTaskIntegration_Batch');

        List<Integration_Log__c> integ_list = new List<Integration_Log__c>();
        if(!woli_items_list.isEmpty()){
            for(WorkOrderLineItem wo_var : woli_items_list){
                integ_list.add(new Integration_Log__c( Object__c = INT_Constants.WOLI_CREATEUPDATE_OPERATING_TASK_ROUTEITEM,
                                                       Object_Id__c = wo_var.Id,
                                                       Work_Order_Line_Item__c = wo_var.Id,
                                                       Ready_To_Be_Sent__c = true,
                                                       Integration_Status__c = 'Initial',
                                                       Triggered_Timestamp__c = DateTime.now()));
                
                //XEN REYES DOO-4347 April 8, 2020
                workOrder_id.add(wo_var.WorkOrderId);
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
        CustomLogging.push('finish', 'TS_RouteTaskIntegration_Batch');

        //CHECK QUEUE CAPACITY
        List<AsyncApexJob> routeIntegrationBatch = [SELECT Id, ApexClassID 
                                            FROM AsyncApexJob 
                                            WHERE Status IN ('Processing', 'Preparing') 
                                            AND ApexClassId IN (SELECT Id FROM ApexClass WHERE Name = 'TS_RouteTaskIntegrationRoute_Batch') ];
        
        //COUNT THE PROCESSING JOBS AND THOSE IN QUEUE
        Integer batchCount_ProcessingPreparing = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND Status IN (\'Processing\', \'Preparing\')');
        Integer batchCount_HoldingQueued = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND Status IN (\'Queued\', \'Holding\')');

        TS_RouteTaskIntegrationRoute_Batch intRoute = new TS_RouteTaskIntegrationRoute_Batch(taskDate, isFirstRun, runCount, workOrder_id);
        intRoute.nordics = nordicsBatch;

        if ((batchCount_ProcessingPreparing < 5 || batchCount_HoldingQueued < 100) && (routeIntegrationBatch == null || routeIntegrationBatch.size() == 0) && !Test.isRunningTest()) { 
            System.scheduleBatch(intRoute, 'TS_RouteTaskIntegrationRoute_Batch ' + String.valueOf(taskDate), 5, Integer.valueOf(System.Label.TS_RouteTaskIntRouBatchSize) );
        }          

        //DISPLAY SUMMARY OF FAILED RECORDS
        if (!exception_List.isEmpty()) {
            System.debug(TS_Constants.ERRBATCH_MSG_02 + exception_List.size());

            //DETAILED LOG OF ERRORS
            for (String err : exception_List) {
                System.debug(err);
            }
        }

        CustomLogging.pop();
    }
}