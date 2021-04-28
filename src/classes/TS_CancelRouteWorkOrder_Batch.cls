/**
 * @author        Karen Hung
 * @date          02/13/2020
 * @description   Apex Class for Cancelling Route Work Order Tasks DOO-3116
 * @revision(s) 
 */
global with sharing class TS_CancelRouteWorkOrder_Batch implements Database.Batchable<sObject>{
    public class TS_CancelRouteWorkOrder_BatchException extends Exception {}
    public static Boolean hasException = false;
    
    Set<String> woIds = new Set<String>();
    
     /******************************************************************************
     * @author        Karen Hung
     * @date           02/13/2020
     * @description   Constructor
     * @revision(s)
     ******************************************************************************/
    global TS_CancelRouteWorkOrder_Batch(Set<String> workOrderIds) {
        woIds = workOrderIds;
    }

    /******************************************************************************
     * @author         Karen Hung
     * @date            02/13/2020
     * @description    This method is the start of the batch job
     * @revision(s)
     ******************************************************************************/
    global Database.QueryLocator start(Database.BatchableContext BC) {
        CustomLogging.push('start', 'TS_CancelRouteWorkOrder_Batch');
        DateTime dateToday = DateTime.now();
        Set<String> woLog = woIds;
        String recordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('Operating (Route) Work Order').getRecordTypeId();
        DescribeSObjectResult woDescribe = WorkOrder.getSObjectType().getDescribe();
        List<String> fields = new List<String>(woDescribe.fields.getMap().keySet());
        String query = 'SELECT ' + String.join(fields, ',') +' FROM WorkOrder WHERE RecordtypeId =' +'\''+recordTypeId+'\''+
            		   ' AND WorkOrder.SalesOrganization__c = \'SAP_0111\''+
                       ' AND ((Status NOT IN (\'Completed\',\'Canceled\') AND SLA_Date__c <= :dateToday)' + 
            		   ' OR Id IN :woLog)';

        CustomLogging.pop();
    	return Database.getQueryLocator(query);
    }

    /******************************************************************************
    * @author         Karen Hung
    * @date           02/13/2020
    * @description    This method proceses the result of query. Where the Work Order tasks are updated. 
    *                
    * @revision(s)
    ******************************************************************************/
    global void execute(Database.BatchableContext BC, List<WorkOrder> woItems) {
        CustomLogging.push('execute', 'TS_CancelRouteWorkOrder_Batch');
        
        List<Integration_log__c> iLogtoInsert = new List<Integration_log__c>();
        List<WorkOrder> wotoCancel = new List<WorkOrder>();
        
        if(!woItems.isEmpty()){ 
            for(WorkOrder wo : woItems){
                if(wo.Status != TS_Constants.STATUS_CANCELED && wo.Status != TS_Constants.STATUS_COMPLETED && wo.SLA_Date__c <= DateTime.now()){
                    wo.Status = TS_Constants.STATUS_CANCELED;
                    
                    //FRANCIS ALINDOGAN DOO-4332 April 9, 2020
                	wo.OP_CancelationReasonCustomer__c = TS_Constants.EOD_BATCH;
                    wotoCancel.add(wo);
                }
                
                iLogtoInsert.add(new Integration_Log__c( Object__c = INT_Constants.WOLI_CREATEUPDATE_OPERATINGROUTE_TASK,
                                                        Object_Id__c = wo.Id,
                                                        Work_Order__c = wo.Id,
                                                        Ready_To_Be_Sent__c = true,
                                                        Integration_Status__c = 'Initial',
                                                        Triggered_Timestamp__c = DateTime.now(),
                                                        Cancelation__c = true));

            }


            try{

                //update work orders
                if(!wotoCancel.isEmpty()){
                    update wotoCancel;
                }
				//insert integration logs
                if(!iLogtoInsert.isEmpty()){
                    insert iLogtoInsert;
                }
                
                //Exception for test class purposes
                if (Test.isRunningTest() && hasException) {
                    throw new TS_CancelRouteWorkOrder_BatchException('Force to throw an exception');
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
        CustomLogging.push('finish', 'TS_CancelRouteWorkOrder_Batch'); 

        CustomLogging.pop();
    }
}