/**
 * @author        Karen Hung
 * @date           02/04/2020
 * @description   Apex Class for Cancelling Route Tasks
 * @revision(s) 
 */
global with sharing class TS_CancelRouteTasks_Batch implements Database.Batchable<sObject>, Database.Stateful{
    public class TS_CancelRouteTasks_BatchException extends Exception {}
    public static Boolean hasException = false;
	private List<String> exception_List = new List<String>();
    
    Set<String> woIds = new Set<String>();
    
     /******************************************************************************
     * @author        Karen Hung
     * @date           02/04/2020
     * @description   Constructor
     * @revision(s)
     ******************************************************************************/
    global TS_CancelRouteTasks_Batch() {
    }

    /******************************************************************************
     * @author         Karen Hung
     * @date            02/04/2020
     * @description    This method is the start of the batch job
     * @revision(s)
     ******************************************************************************/
    global Database.QueryLocator start(Database.BatchableContext BC) {
        CustomLogging.push('start', 'TS_CancelRouteTasks_Batch');
        DateTime dateToday = DateTime.now();
        String recordTypeId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get(TS_Constants.TS_WOLI_RECORDTYPE_OPERATINGTASK).getRecordTypeId();
        DescribeSObjectResult woliDescribe = WorkOrderLineItem.getSObjectType().getDescribe();
        List<String> fields = new List<String>(woliDescribe.fields.getMap().keySet());
        String query = 'SELECT ' + String.join(fields, ',') +' FROM WorkOrderLineItem WHERE RecordtypeId =' +'\''+recordTypeId+'\''+
                       ' AND Status NOT IN (\'Completed\',\'Canceled\') AND WorkOrderType__c =\'S20\' AND isFromRoute__c = TRUE'+
                       ' AND WorkOrder.SalesOrganization__c = \'SAP_0111\' AND SLADate__c <= :dateToday';

        CustomLogging.pop();
    	return Database.getQueryLocator(query);
    }

    /******************************************************************************
    * @author         Karen Hung
    * @date           02/04/2020
    * @description    This method proceses the result of query. Where the WOLI tasks are updated. 
    *                
    * @revision(s)
    ******************************************************************************/
    global void execute(Database.BatchableContext BC, List<WorkOrderLineItem> woliItems) {
        CustomLogging.push('execute', 'TS_CancelRouteTasks_Batch');
        
        List<Integration_log__c> iLogtoInsert = new List<Integration_log__c>();
        
        if(!woliItems.isEmpty()){ 
            for(WorkOrderLineItem woli : woliItems){
                woli.Status = TS_Constants.STATUS_CANCELED;
                woli.OP_CancelationReasonMachine__c = TS_Constants.EOD_BATCH;
				
				//add workorderIds for iLog creation in TS_CancelRouteWorkOrder_Batch
                if(woli.SendCounterReadingsOperating__c == true && woli.WorkOrderId != null){   
                    woIds.add(woli.WorkOrderId);
                }
            }

            try{

                //update woli
                database.update(woliItems);

                //Exception for test class purposes
                if (Test.isRunningTest() && hasException) {
                    throw new TS_CancelRouteTasks_BatchException('Force to throw an exception');
                }   
            }catch(Exception ex){
                CustomLogging.debugException(ex);
                CustomLogging.pop();
                System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
            }


        }
  
        CustomLogging.pop();
    }

    /******************************************************************************
     * @author         Karen Hung
     * @date           02/04/2020
     * @description    This method to perform actions when the batch is finished
     * @revision(s)
     ******************************************************************************/
    global void finish(Database.BatchableContext BC) {        
        CustomLogging.push('finish', 'TS_CancelRouteTasks_Batch'); 
		
        //CHECK QUEUE CAPACITY
        List<AsyncApexJob> routeIntegrationBatch = [SELECT Id, ApexClassID 
                                            FROM AsyncApexJob 
                                            WHERE Status IN ('Processing', 'Preparing') 
                                            AND ApexClassId IN (SELECT Id FROM ApexClass WHERE Name = 'TS_CancelRouteWorkOrder_Batch') ];
        
        //COUNT THE PROCESSING JOBS AND THOSE IN QUEUE
        Integer batchCount_ProcessingPreparing = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND Status IN (\'Processing\', \'Preparing\')');
        Integer batchCount_HoldingQueued = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND Status IN (\'Queued\', \'Holding\')');

        if ((batchCount_ProcessingPreparing < 5 || batchCount_HoldingQueued < 100) && (routeIntegrationBatch == null || routeIntegrationBatch.size() == 0) && !Test.isRunningTest()) { 
           Database.executeBatch(new TS_CancelRouteWorkOrder_Batch(woIds), Integer.valueOf(System.label.TS_CancelRTBatchSize));

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