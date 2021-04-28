/**
* @author        Rey Austral
* @date          8.17.2017           
* @description   Class responsible to stamp the sla date with the milestone target date 
* @revision(s)
*/
public class TS_UpdateSLADateQueueable implements Queueable {
	public Id caseIds;
    public String processName;
    public Integer numberOfExecution = 0;
    public Boolean hasException = false;
    
    public class TS_UpdateSLADateQueueableException extends Exception {  }

	public void execute(QueueableContext context) {
		CustomLogging.push('execute', 'TS_UpdateSLADateQueueable');
        List<Case> toUpdateCaseList = new List<Case>();
        
    	for (CaseMilestone cm : [select Id, TargetDate, CaseId
					             from CaseMilestone cm
					             where CaseId = :caseIds AND IsCompleted = false Order by TargetDate ASC Limit 1]) {
    		system.debug('has case milestone');
    		system.debug(processName);
			Case cse=new Case(id=caseIds,SLADate__c=cm.TargetDate);
			cse.SLADate__c = cm.TargetDate;
			toUpdateCaseList.add(cse);
    	}                 
        system.debug(numberOfExecution);
        if (!toUpdateCaseList.isEmpty()) {
        	try {
                if (Test.isRunningTest() && hasException) {
                    throw new TS_UpdateSLADateQueueableException('Force to throw an exception');
                }

        		update toUpdateCaseList;
        	} catch (Exception ex) {
	            CustomLogging.debugException(ex);
	            CustomLogging.pop();	            
        	}        	
        } else if (numberOfExecution != 3) {             
             TS_UpdateSLADateQueueable controller = new TS_UpdateSLADateQueueable();
             controller.caseIds = caseIds;             
             controller.numberOfExecution = numberOfExecution + 1;
             if (Test.isRunningTest() == false) System.enqueueJob(controller);
        }
        CustomLogging.pop();
	}
}