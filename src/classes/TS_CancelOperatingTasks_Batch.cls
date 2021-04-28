/**
 * @author        Karen Hung
 * @date          11/27/2018
 * @description   Apex batch class for cancelling incomplete operating tasks, scheduled daily
 * @revision(s) 
 */

global with sharing class TS_CancelOperatingTasks_Batch implements Database.Batchable <sObject>{
    private Exception[] errors = new Exception[0];
    public class TS_CancelOperatingTasks_BatchException extends Exception {}
    public static Boolean hasException = false;

	/******************************************************************************
     * @author        Karen Hung
     * @date          11/27/2018
     * @description   Constructor
     * @revision(s)
     ******************************************************************************/
    global TS_CancelOperatingTasks_Batch() {
    }

    /******************************************************************************
     * @author         Karen Hung
     * @date           11/27/2018
     * @description    This method is the start of the batch job
     * @revision(s)
     ******************************************************************************/
    global Database.QueryLocator start(Database.BatchableContext BC) {
        CustomLogging.push('start', 'TS_CancelOperatingTasks_Batch');
        DateTime dateToday = DateTime.now();
        String recordTypeId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get(TS_Constants.TS_WOLI_RECORDTYPE_OPERATINGTASK).getRecordTypeId();
        DescribeSObjectResult woliDescribe = WorkOrderLineItem.getSObjectType().getDescribe();
        List<String> fields = new List<String>(woliDescribe.fields.getMap().keySet());
        //add WorkOrderType__c ='s20',  AND WorkOrder.SalesOrganization__c = \'SAP_0111\'
       // Actual End Date indicates <= TODAY.
        String query = 'SELECT ' + String.join(fields, ',') +' FROM WorkOrderLineItem WHERE RecordtypeId =' +'\''+recordTypeId+'\''+
                       ' AND Status NOT IN (\'Completed\',\'Canceled\') AND WorkOrderType__c =\'S20\''+
                       ' AND isFromRoute__c = FALSE'+  //KAREN HUNG DOO-3116 to exclude routetask
                       ' AND WorkOrder.SalesOrganization__c = \'SAP_0111\' AND SLADate__c <= :dateToday';
        CustomLogging.pop();
    	return Database.getQueryLocator(query);
    }

    /******************************************************************************
    * @author         Karen Hung
    * @date           11/27/2018
    * @description    This method proceses the result of query. Where the WOLI tasks are updated. 
    *                
    * @revision(s)
    ******************************************************************************/
    global void execute(Database.BatchableContext BC, List<WorkOrderLineItem> woliItems) {
		CustomLogging.push('execute', 'TS_CancelOperatingTasks_Batch');
        
        if(!woliItems.isEmpty()){
            
            for(WorkOrderLineItem woli : woliItems){
                woli.Status = TS_Constants.STATUS_CANCELED;
                //woli.OP_CancelationReasonCustomer__c = 'Not Needed';
                woli.OP_CancelationReasonMachine__c = 'EoD Batch';
            }
                        
            try{
                database.update(woliItems);
                //Exception for test class purposes
                if (Test.isRunningTest() && hasException) {
                    throw new TS_CancelOperatingTasks_BatchException('Force to throw an exception');
                }   
            }catch(Exception ex){
                CustomLogging.debugException(ex);
                CustomLogging.pop();
                System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
                errors.add(ex);
     
            }
            
        }
     
        CustomLogging.pop();
    }

    /******************************************************************************
     * @author         Karen Hung
     * @date           11/27/2018
     * @description    This method to perform actions when the batch is finished
     * @revision(s)
     ******************************************************************************/
    global void finish(Database.BatchableContext BC) {        
        CustomLogging.push('finish', 'TS_CancelOperatingTasks_Batch');       
        CustomLogging.pop();
    }

}