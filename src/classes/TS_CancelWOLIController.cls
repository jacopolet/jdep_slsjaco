/*Karen Hung 10.9.2020
*DOO-4648 Apex Controller for TS_CancelWOLI Lightning Component
*
*/
public with sharing class TS_CancelWOLIController {

    public class TS_CancelWOLIControllerException extends Exception {}
    public static Boolean hasException = false;
    
    /**to check if there's completed task only*/
    @AuraEnabled
    public static Boolean hasCompletedTask(String recordId){
        CustomLogging.push('hasCompletedTask','TS_CancelWOLIController');
        
        Boolean hasCompletedWOLI = false;
        Boolean hasOpenWOLI = false;
        Boolean enableButton = false;

        Set<String> caseId = new Set<String>();
        for(WorkOrderLineItem woliRec : [SELECT Id, Case__c FROM WorkOrderLineItem WHERE Id =:recordId AND Case__r.Status != :TS_Constants.STATUS_CLOSED]){
            if(woliRec.Case__c != null) caseId.add(woliRec.Case__c);
        }

        if(caseId != null){
            List<WorkOrderLineItem> siblingTasks = [SELECT Id, Status from WorkOrderLineItem WHERE Case__c IN :caseId AND Id != :recordId and Status != :TS_Constants.STATUS_CANCELED and WorkOrderLineItemType__c = :TS_Constants.TYPE_TASK];
            if(siblingTasks != null && !siblingTasks.isEmpty()){
                for(WorkOrderLineItem woli : siblingTasks){
                    if(woli.Status == TS_Constants.STATUS_COMPLETED){
                        hasCompletedWOLI = true;
                    }else{
                        hasOpenWOLI = true;
                    }
                }  
            }

            if(hasCompletedWOLI && !hasOpenWOLI){
                enableButton = true;    
            }
        }

        CustomLogging.pop();
        return enableButton;
    }

    /*Cancel WOLI and Close Case*/
    @AuraEnabled
    public static String cancelAndCompleteCase(String recordId, String caseId, String cancelationReason){
        CustomLogging.push('cancelAndCompleteCase','TS_CancelWOLIController');

        LightningResponse lResponse = new LightningResponse();
        
        try{
            
            if (Test.isRunningTest() && hasException) {
                throw new TS_CancelWOLIControllerException('Force to throw an exception');
            }
            List<Case> caseforUpdate = new List<Case>();
            List<WorkOrderLineItem> woliforUpdate = new List<WorkOrderLineItem>();

            WorkOrderLineItem woli = new WorkOrderLineItem(Id = recordId, Status = TS_Constants.STATUS_CANCELED, CancelationReason__c = cancelationReason);
            woliforUpdate.add(woli);

            if(!woliforUpdate.isEmpty()){
                update woliforUpdate;
            }

            if(caseId != '' && caseId != null){
                Case forUpdate = new Case(Id = caseId, Status = TS_Constants.STATUS_CLOSED, CaseSubstatus__c = TS_Constants.STATUS_CLOSED);
                caseforUpdate.add(forUpdate);

                if(!caseforUpdate.isEmpty()){
                    update caseforUpdate;
                }
            }

            lResponse.status = 'Record Updated';
            
        }catch (Exception e){
            lResponse.status = 'ERROR';
            lResponse.message = 'Error: ' + e.getMessage() + '\nSTACK TRACE: ' + e.getStackTraceString();
        }
        
        CustomLogging.pop();
        return JSON.serialize(lResponse);
    }

    /*response format*/
    public class LightningResponse{
       /* @AuraEnabled
        public String returnValue;*/
        @AuraEnabled
        public String status;
        @AuraEnabled
        public String message;

        public LightningResponse(){
            //this.returnValue = returnValue;
            this.status = status;
            this.message = message;
        }
    }
}