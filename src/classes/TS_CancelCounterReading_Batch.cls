/**
 * @author        Karen Hung
 * @date          24/09/2019
 * @description   Apex Class for Cancelling Counter Reading Orders, scheduled every end of month
 * @revision(s) 
 */
global with sharing class TS_CancelCounterReading_Batch implements Database.Batchable<sObject>{
    public class TS_CancelCounterReading_BatchException extends Exception {}
    public static Boolean hasException = false;
    
     /******************************************************************************
     * @author        Karen Hung
     * @date          24/09/2019
     * @description   Constructor
     * @revision(s)
     ******************************************************************************/
    global TS_CancelCounterReading_Batch() {
    }

    /******************************************************************************
     * @author         Karen Hung
     * @date           24/09/2019
     * @description    This method is the start of the batch job
     * @revision(s)
     ******************************************************************************/
    global Database.QueryLocator start(Database.BatchableContext BC) {
        CustomLogging.push('start', 'TS_CancelCounterReading_Batch');
        DateTime dateToday = DateTime.now();
        String recordTypeId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get(TS_Constants.TS_WOLI_RECORDTYPE_COUNTERREADINGTASK).getRecordTypeId();
        DescribeSObjectResult woliDescribe = WorkOrderLineItem.getSObjectType().getDescribe();
        List<String> fields = new List<String>(woliDescribe.fields.getMap().keySet());
        String query = 'SELECT ' + String.join(fields, ',') +' FROM WorkOrderLineItem WHERE RecordtypeId =' +'\''+recordTypeId+'\''+
                       ' AND Status NOT IN (\'Completed\',\'Canceled\') AND WorkOrderType__c =\'S22\''; 
                       //' AND MachineCare__c = \'Full Operating\' AND PhysicalAsset__r.Connected__c = \'No\''; //DOO-4582 05.28.2020 Francis Allen Alindogan
        CustomLogging.pop();
    	return Database.getQueryLocator(query);
    }

    /******************************************************************************
    * @author         Karen Hung
    * @date           24/09/2019
    * @description    This method proceses the result of query. Where the WOLI tasks are updated. 
    *                
    * @revision(s)
    ******************************************************************************/
    global void execute(Database.BatchableContext BC, List<WorkOrderLineItem> woliItems) {
		CustomLogging.push('execute', 'TS_CancelCounterReading_Batch');
        
        if(!woliItems.isEmpty()){
            
            for(WorkOrderLineItem woli : woliItems){
                woli.Status = TS_Constants.STATUS_CANCELED;
                woli.OP_CancelationReasonMachine__c = 'Not Needed';
                //woli.OP_CancelationReasonMachine__c = 'EoD Batch';
            }
                        
            try{
                database.update(woliItems);
                //Exception for test class purposes
                if (Test.isRunningTest() && hasException) {
                    throw new TS_CancelCounterReading_BatchException('Force to throw an exception');
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
     * @date           11/27/2018
     * @description    This method to perform actions when the batch is finished
     * @revision(s)
     ******************************************************************************/
    global void finish(Database.BatchableContext BC) {        
        CustomLogging.push('finish', 'TS_CancelCounterReading_Batch');       
        CustomLogging.pop();
    }
}