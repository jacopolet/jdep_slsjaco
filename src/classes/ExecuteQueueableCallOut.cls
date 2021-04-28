//-------------------------------------------------------------------------------------------//
// Author       :   Rey Austral - Accenture
// Created Date :   May 11, 2017
// Usage        :   Cannot make a call out when there is a dml execution running in same transaction
//                  Seperate the transaction of the callout by using queueable approach
// Revision:    :   4 May 2018, Archi Delphinanto implemented Object Level (Access) Security, as part of Code Review actions.
//              :   7.16.2018 Paul Aguiling KTS-1675: Updated execute()
//-------------------------------------------------------------------------------------------//
public class ExecuteQueueableCallOut implements Queueable, Database.AllowsCallouts {    
    public Boolean hasException = false;

    /******************************************************************************
    * @author         Paul Jarred Aguiling
    * @date           6.14.2017
    * @description    Method responsible for throwing an exception
    * @revision(s)
    ******************************************************************************/ 
    public class TS_SchedulerException extends Exception {
    }

    public List<Integration_Log__c> iLogList = new List<Integration_Log__c>();
    public JDEServicesCallout.PartTypes[] elem = new List<JDEServicesCallout.PartTypes>();
    public List<JDEServicesCallout.UserCreate_element> userElem = new List<JDEServicesCallout.UserCreate_element>();//KTS-1675: User Creation Mapping
    public void execute(QueueableContext context) {
        CustomLogging.push('execute','ExecuteQueueableCallOut');
        JDEServicesCallout.JDEServiceOptimizationPort port = new JDEServicesCallout.JDEServiceOptimizationPort();
        try {
            if (Test.isRunningTest() && hasException) {
                throw new TS_SchedulerException('Force to throw an exception');
            }

            if (!elem.isEmpty())
                port.SyncMasterData(elem);     

            //KTS-1675: User Creation Mapping -- START
            if (!userElem.isEmpty()) {
                for (JDEServicesCallout.UserCreate_element userParam : userElem) {
                    port.UserCreate(userParam); 
                }
            }
            //KTS-1675: User Creation Mapping -- END

            updateIntegrationLog(false, null);            
        } catch(Exception ex) {
            updateIntegrationLog(true, ex.getMessage());                     
            CustomLogging.debugException(ex);
            CustomLogging.pop();
        } 
        try {
            if (Test.isRunningTest() && hasException) {
                throw new TS_SchedulerException('Force to throw an exception');
            }
            // Added as part of security best practice, CRUD check on the object 
          Boolean hasUpdateRightOnIntegrationLog  = TS_UtilityClass.isSObjectUpdateable(new String[] {'Integration_Log__c'});      
          if(hasUpdateRightOnIntegrationLog )     update iLogList;
        } catch(Exception ex) {          
            CustomLogging.debugException(ex);
            CustomLogging.pop();
        }
    }
    
    private void updateIntegrationLog(Boolean hasError, String errorMessage) {
        for(Integration_Log__c currentLog : iLogList) {           
            if (hasError) {
                currentLog.Integration_Status__c = INT_Constants.TARGET_SYSTEM_ERROR;
                currentLog.Integration_Message__c = errorMessage;
            } else {
                currentLog.Integration_Status__c = INT_Constants.TARGET_SYSTEM_SUCCESS;
                currentLog.Target_System_Processed_TimeStamp__c = Datetime.now(); 
            }  
        }
    }
    
}