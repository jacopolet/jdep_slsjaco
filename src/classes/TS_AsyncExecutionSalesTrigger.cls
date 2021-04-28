/**
* @author        Abram Vixen F. Reyes
* @date          01.17.2018     
* @description   Queueable interface for TS_SalesTriggerController
* @revision(s)   
*/
public with sharing class TS_AsyncExecutionSalesTrigger implements Queueable {
    public List<Id> parentOrderIdList = new List<Id>();
    public static Boolean hasException = false;
    public class TS_AsyncExecutionSalesTriggerException extends Exception {  }
    
    public void execute(QueueableContext context) {
        CustomLogging.push('execute', 'TS_AsyncExecutionSalesTrigger');
        
        try{
            TS_SalesTriggerController ts = new TS_SalesTriggerController();
            ts.getWorkOrderTriggerRecords(parentOrderIdList);
            
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_AsyncExecutionSalesTriggerException('Force to throw an exception');
            }
        }
        catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
        }
        
        CustomLogging.pop();
    }
}