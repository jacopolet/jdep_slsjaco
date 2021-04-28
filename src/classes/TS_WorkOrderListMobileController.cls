/*
* @author        Xen Reyes
* @date          3.5.2018
* @description   Controller class for TS_WorkOrderListMobile && TS_WorkOrderLineItemListView
*/
public with sharing class TS_WorkOrderListMobileController {

	@AuraEnabled
    public static String getAllRecords() {

        LightningResponse lResponse = new LightningResponse();

    	//FIND ALL EXECUTING ENGINEER/RESOURCE RECORD RELATED TO THE CURRENT USER
    	Id currentUserId = UserInfo.getUserId();
    	Set<Id> resourceIdSet = new Set<Id>();
    	List<Resource__c> relatedResourcesList = [SELECT Id, RelatedUser__c, TeamNumber__c FROM Resource__c WHERE RelatedUser__c =: currentUserId];
    	List<WorkOrderLineItem> taskToReturn = new List<WorkOrderLineItem>();

        try{
        	if(!relatedResourcesList.isEmpty()){
        		for(Resource__c rs : relatedResourcesList){
        			resourceIdSet.add(rs.Id);
        		}

        		if(!resourceIdSet.isEmpty()){
                    //Karen Hung 16.7.2020 added Waterfilter_Suggestion__c in query
        			taskToReturn = [SELECT Id, JDELineItemNumber__c, Waterfilter_Suggestion__c, toLabel(WorkOrderType__c), toLabel(WorkOrderLineItemType__c), StartDate__c, EndDate__c, TaskDueDate__c, Status, Case__r.Account.Name, ParentWorkOrderLineItem.JDELineItemNumber__c, ParentWorkOrderLineItemId, ExecutingEngineer__c, ExecutingEngineer__r.EmployeeFirstName__c, ExecutingEngineer__r.EmployeeLastName__c, AccountLocation__r.Name, AccountLocation__r.Shipping_PostalCode__c, ProductDescription__c, Executing_Engineer_First_Name__c, Executing_Engineer_Last_Name__c, AccountLocationPostalCode__c, Account_Location_Name__c, AccountLocationHouseNumber__c, AccountLocationStreet__c FROM WorkOrderLineItem WHERE (Status != 'Canceled' AND Status != 'Open' AND ExecutingEngineer__c IN: resourceIdSet) ORDER BY JDELineItemNumber__c DESC];

                    ///WorkOrderLineItemType__c = 'Task'
        		}
        	}

            system.debug('taskToReturn----->' + taskToReturn.size() );
            lResponse.returnValue = JSON.serialize(taskToReturn);

        } catch (Exception e){
            lResponse.status = 'ERROR';
            lResponse.message = 'Error: ' + e.getMessage() + '\nSTACK TRACE: ' + e.getStackTraceString();
        }
    	
    	return JSON.serialize(lResponse);
    }

    @AuraEnabled
    public static String getAllRecordsTeam() {

        LightningResponse lResponse = new LightningResponse();

        //FIND ALL EXECUTING ENGINEER/RESOURCE RECORD RELATED TO THE CURRENT USER
        Id currentUserId = UserInfo.getUserId();
        Set<Id> resourceIdSet = new Set<Id>();
        Set<Id> resourceIdSetTeam = new Set<Id>();
        Set<String> teamNumbersSet = new Set<String>();
        List<Resource__c> relatedResourcesTeamList = new List<Resource__c>();
        List<WorkOrderLineItem> taskToReturn = new List<WorkOrderLineItem>();
        List<Resource__c> relatedResourcesList = new List<Resource__c>();

        try{

            relatedResourcesList = [SELECT Id, RelatedUser__c, TeamNumber__c FROM Resource__c WHERE RelatedUser__c =: currentUserId];

            if(!relatedResourcesList.isEmpty()){

                for(Resource__c res : relatedResourcesList){
                    resourceIdSet.add(res.Id);
                }

                for(Resource__c res : relatedResourcesList){
                    if(res.TeamNumber__c != null){
                        teamNumbersSet.add(res.TeamNumber__c);
                    }
                }

                if(!teamNumbersSet.isEmpty()){
                    relatedResourcesTeamList = [SELECT Id, RelatedUser__c, TeamNumber__c FROM Resource__c WHERE TeamNumber__c IN: teamNumbersSet];

                    if(!relatedResourcesTeamList.isEmpty()){
                        for(Resource__c rs : relatedResourcesTeamList){
                            resourceIdSetTeam.add(rs.Id);
                        }

                        if(!resourceIdSetTeam.isEmpty()){
                            //Karen Hung 16.7.2020 added Waterfilter_Suggestion__c in query
                            taskToReturn = [SELECT Id, JDELineItemNumber__c,Waterfilter_Suggestion__c, toLabel(WorkOrderType__c), toLabel(WorkOrderLineItemType__c), StartDate__c, EndDate__c, TaskDueDate__c, Status, Case__r.Account.Name, ParentWorkOrderLineItem.JDELineItemNumber__c, ParentWorkOrderLineItemId, ExecutingEngineer__c, ExecutingEngineer__r.EmployeeFirstName__c, ExecutingEngineer__r.EmployeeLastName__c, AccountLocation__r.Name, AccountLocation__r.Shipping_PostalCode__c, ProductDescription__c, Executing_Engineer_First_Name__c, Executing_Engineer_Last_Name__c, AccountLocationPostalCode__c, Account_Location_Name__c, AccountLocationHouseNumber__c, AccountLocationStreet__c FROM WorkOrderLineItem WHERE (Status != 'Canceled' AND Status != 'Open' AND ExecutingEngineer__c IN:resourceIdSetTeam AND ExecutingEngineer__c NOT IN:resourceIdSet) ORDER BY JDELineItemNumber__c DESC];
                        }
                    }
                }
            }

            lResponse.returnValue = JSON.serialize(taskToReturn);

        } catch (Exception e){
            lResponse.status = 'ERROR';
            lResponse.message = 'Error: ' + e.getMessage() + '\nSTACK TRACE: ' + e.getStackTraceString();
        }    

        return JSON.serialize(lResponse);
    }

     public class LightningResponse{
        @AuraEnabled
        public String returnValue;
        @AuraEnabled
        public String status;
        @AuraEnabled
        public String message;

        public LightningResponse(){
            this.returnValue = returnValue;
            this.status = status;
            this.message = message;
        }
    }
}