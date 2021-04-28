/**
* @author        Rey Austral
* @date          8.17.2017           
* @description   Class to be called in the process builder TS_RetrieveTargetDate
* @revision(s) 	 Karen Hung 10.24.2018 added exception
*/
global with sharing class TS_UpdateSLADateCallApex {
    
    public class TS_UpdateSLADateCallApexException extends Exception {}
    
    public static Boolean hasException = false;
    
    @InvocableMethod
    global static void InvokeQueueableClass(List<UpdateSLARequest> requestList) {
        CustomLogging.push('InvokeQueueableClass', 'TS_UpdateSLADateCallApex');

        try {
            TS_UpdateSLADateQueueable controller = new TS_UpdateSLADateQueueable();
            controller.caseIds = requestList.get(0).caseIds;
            //controller.processName = requestList.get(0).processName;
            controller.numberOfExecution = 1;
            System.enqueueJob(controller);
            
            if (Test.isRunningTest() && hasException) {            }
        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        
        CustomLogging.pop();
    }
    
    global class UpdateSLARequest {
        @InvocableVariable(required=true)
        global Id caseIds;
        
        @InvocableVariable(required=false)
        global String processName;
    }
}