/*
* @author        Karen Hung
* @date          20.06.2019
* @description   Controller class for TS_WorkOrderLineItemListViewCLONEOFFSET DOO-496 FOR PORTAL PERFORMANCE
*/
public with sharing class TS_WorkOrderListMobileControllerCLONE {
    
    public static final Integer OPGThreshold = Integer.valueOf(System.Label.TS_OPGDayThreshold);
    public static final String WO_TYPE_S20_MACHINECARE = TS_Constants.WO_TYPE_S20_MACHINECARE; //FIX FOR DYNAMIC SOQL QUERY
	public static Boolean hasException = false;
    public class TS_WorkOrderListMobileControllerCLONEException extends Exception {}
    
    //METHODS FOR GETTING ALL RECORDS FOR THE LIST VIEW
    //1. GET MY OPEN RECORDS
    @AuraEnabled
    public static String getAllRecords2(Integer offset, Boolean isThirdParty) {

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
                    if(isThirdParty == true){
                        taskToReturn = [SELECT Id, JDELineItemNumber__c, toLabel(WorkOrderType__c), toLabel(WorkOrderLineItemType__c), StartDate__c, EndDate__c, TaskDueDate__c, Status, Case__r.Account.Name, ParentWorkOrderLineItem.JDELineItemNumber__c, ParentWorkOrderLineItemId, ExecutingEngineer__c, ExecutingEngineer__r.EmployeeFirstName__c, ExecutingEngineer__r.EmployeeLastName__c, AccountLocation__r.Name, AccountLocation__r.Shipping_PostalCode__c, ProductDescription__c, Executing_Engineer_First_Name__c, Executing_Engineer_Last_Name__c, AccountLocationPostalCode__c, Account_Location_Name__c, AccountLocationHouseNumber__c, AccountLocationStreet__c FROM WorkOrderLineItem WHERE (Status != 'Canceled' AND Status != 'Open' AND Status !='Completed' AND Status != 'Review Needed' AND ExecutingEngineer__c IN: resourceIdSet) AND WorkOrderType__c !=: WO_TYPE_S20_MACHINECARE ORDER BY TaskDueDate__c ASC LIMIT 20 OFFSET :offset ];                         
                    }
                    else {
                        taskToReturn = [SELECT Id, JDELineItemNumber__c, toLabel(WorkOrderType__c), toLabel(WorkOrderLineItemType__c), StartDate__c, EndDate__c, TaskDueDate__c, Status, Case__r.Account.Name, ParentWorkOrderLineItem.JDELineItemNumber__c, ParentWorkOrderLineItemId, ExecutingEngineer__c, ExecutingEngineer__r.EmployeeFirstName__c, ExecutingEngineer__r.EmployeeLastName__c, AccountLocation__r.Name, AccountLocation__r.Shipping_PostalCode__c, ProductDescription__c, Executing_Engineer_First_Name__c, Executing_Engineer_Last_Name__c, AccountLocationPostalCode__c, Account_Location_Name__c, AccountLocationHouseNumber__c, AccountLocationStreet__c FROM WorkOrderLineItem WHERE (Status != 'Canceled' AND Status != 'Open' AND Status !='Completed' AND Status != 'Review Needed' AND ExecutingEngineer__c IN: resourceIdSet) ORDER BY TaskDueDate__c ASC LIMIT 20 OFFSET :offset ];    
                    }
                    
                }
            }
            //lResponse.returnValue = 'SELECT Id, JDELineItemNumber__c, toLabel(WorkOrderType__c), toLabel(WorkOrderLineItemType__c), StartDate__c, EndDate__c, TaskDueDate__c, Status, Case__r.Account.Name, ParentWorkOrderLineItem.JDELineItemNumber__c, ParentWorkOrderLineItemId, ExecutingEngineer__c, ExecutingEngineer__r.EmployeeFirstName__c, ExecutingEngineer__r.EmployeeLastName__c, AccountLocation__r.Name, AccountLocation__r.Shipping_PostalCode__c, ProductDescription__c, Executing_Engineer_First_Name__c, Executing_Engineer_Last_Name__c, AccountLocationPostalCode__c, Account_Location_Name__c, AccountLocationHouseNumber__c, AccountLocationStreet__c FROM WorkOrderLineItem WHERE (Status != \'Canceled\' AND Status != \'Open\' AND Status !=\'Completed\' AND ExecutingEngineer__c IN:'+ resourceIdSet+') AND WorkOrderType__c !='+WO_TYPE_S20_MACHINECARE+' ORDER BY JDELineItemNumber__c DESC LIMIT 20 OFFSET '+ offset;
            lResponse.returnValue = JSON.serialize(taskToReturn);
            
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_WorkOrderListMobileControllerCLONEException('Force to throw an exception');
            }

        } catch (Exception e){
            lResponse.status = 'ERROR';
            lResponse.message = 'Error: ' + e.getMessage() + '\nSTACK TRACE: ' + e.getStackTraceString();
        }
        
        return JSON.serialize(lResponse);
    }
    //2. GET MY CLOSED RECORDS
    @AuraEnabled
    public static String getAllRecords3(Integer offset, Boolean isThirdParty) {

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
                    if(isThirdParty == true){
                        //taskToReturn = [SELECT Id, JDELineItemNumber__c, toLabel(WorkOrderType__c), toLabel(WorkOrderLineItemType__c), StartDate__c, EndDate__c, TaskDueDate__c, Status, Case__r.Account.Name, ParentWorkOrderLineItem.JDELineItemNumber__c, ParentWorkOrderLineItemId, ExecutingEngineer__c, ExecutingEngineer__r.EmployeeFirstName__c, ExecutingEngineer__r.EmployeeLastName__c, AccountLocation__r.Name, AccountLocation__r.Shipping_PostalCode__c, ProductDescription__c, Executing_Engineer_First_Name__c, Executing_Engineer_Last_Name__c, AccountLocationPostalCode__c, Account_Location_Name__c, AccountLocationHouseNumber__c, AccountLocationStreet__c FROM WorkOrderLineItem WHERE (Status ='Completed' AND ExecutingEngineer__c IN: resourceIdSet) AND WorkOrderType__c !=: WO_TYPE_S20_MACHINECARE ORDER BY JDELineItemNumber__c DESC LIMIT 20 OFFSET :offset ];    
                        taskToReturn = Database.query('SELECT Id, JDELineItemNumber__c, toLabel(WorkOrderType__c), toLabel(WorkOrderLineItemType__c), StartDate__c, EndDate__c, TaskDueDate__c, Status, Case__r.Account.Name, ParentWorkOrderLineItem.JDELineItemNumber__c, ParentWorkOrderLineItemId, ExecutingEngineer__c, ExecutingEngineer__r.EmployeeFirstName__c, ExecutingEngineer__r.EmployeeLastName__c, AccountLocation__r.Name, AccountLocation__r.Shipping_PostalCode__c, ProductDescription__c, Executing_Engineer_First_Name__c, Executing_Engineer_Last_Name__c, AccountLocationPostalCode__c, Account_Location_Name__c, AccountLocationHouseNumber__c, AccountLocationStreet__c FROM WorkOrderLineItem WHERE Status =\'Completed\'  AND ExecutingEngineer__c IN: resourceIdSet AND WorkOrderType__c !=: WO_TYPE_S20_MACHINECARE AND CreatedDate = LAST_N_DAYS:' + OPGThreshold + ' ORDER BY TaskDueDate__c DESC LIMIT 20 OFFSET :offset');                             
                        
                    }
                    else {
                        //taskToReturn = [SELECT Id, JDELineItemNumber__c, toLabel(WorkOrderType__c), toLabel(WorkOrderLineItemType__c), StartDate__c, EndDate__c, TaskDueDate__c, Status, Case__r.Account.Name, ParentWorkOrderLineItem.JDELineItemNumber__c, ParentWorkOrderLineItemId, ExecutingEngineer__c, ExecutingEngineer__r.EmployeeFirstName__c, ExecutingEngineer__r.EmployeeLastName__c, AccountLocation__r.Name, AccountLocation__r.Shipping_PostalCode__c, ProductDescription__c, Executing_Engineer_First_Name__c, Executing_Engineer_Last_Name__c, AccountLocationPostalCode__c, Account_Location_Name__c, AccountLocationHouseNumber__c, AccountLocationStreet__c FROM WorkOrderLineItem WHERE (Status ='Completed' AND ExecutingEngineer__c IN: resourceIdSet) ORDER BY JDELineItemNumber__c DESC LIMIT 20 OFFSET :offset ];    
                        taskToReturn = Database.query('SELECT Id, JDELineItemNumber__c, toLabel(WorkOrderType__c), toLabel(WorkOrderLineItemType__c), StartDate__c, EndDate__c, TaskDueDate__c, Status, Case__r.Account.Name, ParentWorkOrderLineItem.JDELineItemNumber__c, ParentWorkOrderLineItemId, ExecutingEngineer__c, ExecutingEngineer__r.EmployeeFirstName__c, ExecutingEngineer__r.EmployeeLastName__c, AccountLocation__r.Name, AccountLocation__r.Shipping_PostalCode__c, ProductDescription__c, Executing_Engineer_First_Name__c, Executing_Engineer_Last_Name__c, AccountLocationPostalCode__c, Account_Location_Name__c, AccountLocationHouseNumber__c, AccountLocationStreet__c FROM WorkOrderLineItem WHERE Status =\'Completed\'  AND ExecutingEngineer__c IN: resourceIdSet AND CreatedDate = LAST_N_DAYS:' + OPGThreshold + ' ORDER BY TaskDueDate__c DESC LIMIT 20 OFFSET :offset');    
                    }                    
                }
            }

            lResponse.returnValue = JSON.serialize(taskToReturn);
            
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_WorkOrderListMobileControllerCLONEException('Force to throw an exception');
            }

        } catch (Exception e){
            lResponse.status = 'ERROR';
            lResponse.message = 'Error: ' + e.getMessage() + '\nSTACK TRACE: ' + e.getStackTraceString();
        }
        
        return JSON.serialize(lResponse);
    }
    //3. GET MY TEAMS OPEN RECORDS
    @AuraEnabled
    public static String getOpenRecordsTeam(Integer offset) {

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
                            taskToReturn = [SELECT Id, JDELineItemNumber__c, toLabel(WorkOrderType__c), toLabel(WorkOrderLineItemType__c), StartDate__c, EndDate__c, TaskDueDate__c, Status, Case__r.Account.Name, ParentWorkOrderLineItem.JDELineItemNumber__c, ParentWorkOrderLineItemId, ExecutingEngineer__c, ExecutingEngineer__r.EmployeeFirstName__c, ExecutingEngineer__r.EmployeeLastName__c, AccountLocation__r.Name, AccountLocation__r.Shipping_PostalCode__c, ProductDescription__c, Executing_Engineer_First_Name__c, Executing_Engineer_Last_Name__c, AccountLocationPostalCode__c, Account_Location_Name__c, AccountLocationHouseNumber__c, AccountLocationStreet__c FROM WorkOrderLineItem WHERE (Status != 'Canceled' AND Status != 'Open' AND Status !='Completed' AND Status != 'Review Needed' AND ExecutingEngineer__c IN:resourceIdSetTeam AND ExecutingEngineer__c NOT IN:resourceIdSet) ORDER BY TaskDueDate__c ASC LIMIT 20 OFFSET :offset];
                        }
                    }
                }
            }

            lResponse.returnValue = JSON.serialize(taskToReturn);
            
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_WorkOrderListMobileControllerCLONEException('Force to throw an exception');
            }

        } catch (Exception e){
            lResponse.status = 'ERROR';
            lResponse.message = 'Error: ' + e.getMessage() + '\nSTACK TRACE: ' + e.getStackTraceString();
        }    

        return JSON.serialize(lResponse);
    }
    //4. GET MY TEAMS CLOSED RECORDS
    @AuraEnabled
    public static String getClosedRecordsTeam(Integer offset) {

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
                            //taskToReturn = [SELECT Id, JDELineItemNumber__c, toLabel(WorkOrderType__c), toLabel(WorkOrderLineItemType__c), StartDate__c, EndDate__c, TaskDueDate__c, Status, Case__r.Account.Name, ParentWorkOrderLineItem.JDELineItemNumber__c, ParentWorkOrderLineItemId, ExecutingEngineer__c, ExecutingEngineer__r.EmployeeFirstName__c, ExecutingEngineer__r.EmployeeLastName__c, AccountLocation__r.Name, AccountLocation__r.Shipping_PostalCode__c, ProductDescription__c, Executing_Engineer_First_Name__c, Executing_Engineer_Last_Name__c, AccountLocationPostalCode__c, Account_Location_Name__c, AccountLocationHouseNumber__c, AccountLocationStreet__c FROM WorkOrderLineItem WHERE (Status != 'Canceled' AND Status != 'Open' AND Status ='Completed' AND ExecutingEngineer__c IN:resourceIdSetTeam AND ExecutingEngineer__c NOT IN:resourceIdSet) ORDER BY JDELineItemNumber__c DESC LIMIT 20 OFFSET :offset];                            
                            taskToReturn = Database.query('SELECT Id, JDELineItemNumber__c, toLabel(WorkOrderType__c), toLabel(WorkOrderLineItemType__c), StartDate__c, EndDate__c, TaskDueDate__c, Status, Case__r.Account.Name, ParentWorkOrderLineItem.JDELineItemNumber__c, ParentWorkOrderLineItemId, ExecutingEngineer__c, ExecutingEngineer__r.EmployeeFirstName__c, ExecutingEngineer__r.EmployeeLastName__c, AccountLocation__r.Name, AccountLocation__r.Shipping_PostalCode__c, ProductDescription__c, Executing_Engineer_First_Name__c, Executing_Engineer_Last_Name__c, AccountLocationPostalCode__c, Account_Location_Name__c, AccountLocationHouseNumber__c, AccountLocationStreet__c FROM WorkOrderLineItem WHERE Status =\'Completed\'  AND ExecutingEngineer__c IN:resourceIdSetTeam AND ExecutingEngineer__c NOT IN:resourceIdSet AND CreatedDate = LAST_N_DAYS:' + OPGThreshold + ' ORDER BY TaskDueDate__c DESC LIMIT 20 OFFSET :offset');                                                                                   
                        }
                    }
                }
            }

            lResponse.returnValue = JSON.serialize(taskToReturn);
            
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_WorkOrderListMobileControllerCLONEException('Force to throw an exception');
            }

        } catch (Exception e){
            lResponse.status = 'ERROR';
            lResponse.message = 'Error: ' + e.getMessage() + '\nSTACK TRACE: ' + e.getStackTraceString();
        }    

        return JSON.serialize(lResponse);
    }
    //5. GET THIRDPARTY OPERATING OPEN RECORDS
    @AuraEnabled
    public static String getOpenRecordsOperating(Integer offset) {

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
                    taskToReturn = Database.query('SELECT Id, JDELineItemNumber__c, toLabel(WorkOrderType__c), toLabel(WorkOrderLineItemType__c), StartDate__c, EndDate__c, TaskDueDate__c, Status, Case__r.Account.Name, ParentWorkOrderLineItem.JDELineItemNumber__c, ParentWorkOrderLineItemId, ExecutingEngineer__c, ExecutingEngineer__r.EmployeeFirstName__c, ExecutingEngineer__r.EmployeeLastName__c, AccountLocation__r.Name, AccountLocation__r.Shipping_PostalCode__c, ProductDescription__c, Executing_Engineer_First_Name__c, Executing_Engineer_Last_Name__c, AccountLocationPostalCode__c, Account_Location_Name__c, AccountLocationHouseNumber__c, AccountLocationStreet__c FROM WorkOrderLineItem WHERE Status != \'Canceled\' AND Status != \'Open\' AND Status !=\'Completed\' AND Status != \'Review Needed\' AND ExecutingEngineer__c IN:resourceIdSet AND WorkOrderType__c =:WO_TYPE_S20_MACHINECARE ORDER BY TaskDueDate__c ASC LIMIT 20 OFFSET :offset');
                }
            }
            
            lResponse.returnValue = JSON.serialize(taskToReturn); 
            
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_WorkOrderListMobileControllerCLONEException('Force to throw an exception');
            }
                                                                           
        } catch (Exception e){
            lResponse.status = 'ERROR';
            lResponse.message = 'Error: ' + e.getMessage() + '\nSTACK TRACE: ' + e.getStackTraceString();
        }
        
        return JSON.serialize(lResponse);
    }
    //6. GET THIRDPARTY OPERATING CLOSED RECORDS
    @AuraEnabled
    public static String getClosedRecordsOperating(Integer offset) {

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
                    taskToReturn = Database.query('SELECT Id, JDELineItemNumber__c, toLabel(WorkOrderType__c), toLabel(WorkOrderLineItemType__c), StartDate__c, EndDate__c, TaskDueDate__c, Status, Case__r.Account.Name, ParentWorkOrderLineItem.JDELineItemNumber__c, ParentWorkOrderLineItemId, ExecutingEngineer__c, ExecutingEngineer__r.EmployeeFirstName__c, ExecutingEngineer__r.EmployeeLastName__c, AccountLocation__r.Name, AccountLocation__r.Shipping_PostalCode__c, ProductDescription__c, Executing_Engineer_First_Name__c, Executing_Engineer_Last_Name__c, AccountLocationPostalCode__c, Account_Location_Name__c, AccountLocationHouseNumber__c, AccountLocationStreet__c FROM WorkOrderLineItem WHERE (Status =\'Completed\' OR Status =\'Canceled\') AND ExecutingEngineer__c IN: resourceIdSet AND WorkOrderType__c =: WO_TYPE_S20_MACHINECARE AND CreatedDate = LAST_N_DAYS:' + OPGThreshold + ' ORDER BY TaskDueDate__c DESC LIMIT 20 OFFSET :offset');
                }
            }

            lResponse.returnValue = JSON.serialize(taskToReturn);
            
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_WorkOrderListMobileControllerCLONEException('Force to throw an exception');
            }

        } catch (Exception e){
            lResponse.status = 'ERROR';
            lResponse.message = 'Error: ' + e.getMessage() + '\nSTACK TRACE: ' + e.getStackTraceString();
        }
        
        return JSON.serialize(lResponse);
    }


    //METHODS TO GET TOTAL NUMBER OF RECORDS PER LIST VIEW
    //1. GET NUMBER OF MY OPEN RECORDS
    @AuraEnabled
    public static Integer getAllRecordsNumberOpen(Boolean isThirdParty){

        LightningResponse lResponse = new LightningResponse();
        Integer totalRecords = 0;
        Id currentUserId = UserInfo.getUserId();
        Set<Id> resourceIdSet = new Set<Id>();

        try{
            //get resource ids related to the user
            for(Resource__c userResource : [SELECT Id, RelatedUser__c, TeamNumber__c FROM Resource__c WHERE RelatedUser__c =: currentUserId] ){
                resourceIdSet.add(userResource.Id);
            }
            if(!resourceIdSet.isEmpty()){
                if(isThirdParty == true){
                     AggregateResult results = [SELECT Count(Id) TotalRec FROM WorkOrderLineItem WHERE (Status != 'Canceled' AND Status != 'Open' AND Status !='Completed' AND Status != 'Review Needed' AND ExecutingEngineer__c IN: resourceIdSet) AND WorkOrderType__c !=: WO_TYPE_S20_MACHINECARE];
                     totalRecords = (Integer)results.get('TotalRec'); 
                }
                else {                                    
                     AggregateResult results = [SELECT Count(Id) TotalRec FROM WorkOrderLineItem WHERE (Status != 'Canceled' AND Status != 'Open' AND Status !='Completed' AND Status != 'Review Needed' AND ExecutingEngineer__c IN: resourceIdSet)];
                     totalRecords = (Integer)results.get('TotalRec'); 
                }                
                    
            }
            
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_WorkOrderListMobileControllerCLONEException('Force to throw an exception');
            }

        } catch (Exception e){
            lResponse.status = 'ERROR';
            lResponse.message = 'Error: ' + e.getMessage() + '\nSTACK TRACE: ' + e.getStackTraceString();
        }


        return totalRecords;
    } 
    //2. GET NUMBER OF MY CLOSED RECORDS
    @AuraEnabled
    public static Integer getAllMyRecordsNumberClosed(Boolean isThirdParty){

        LightningResponse lResponse = new LightningResponse();
        Integer totalRecords = 0;
        Id currentUserId = UserInfo.getUserId();
        Set<Id> resourceIdSet = new Set<Id>();

        try{
            //get resource ids related to the user
            for(Resource__c userResource : [SELECT Id, RelatedUser__c, TeamNumber__c FROM Resource__c WHERE RelatedUser__c =: currentUserId] ){
                resourceIdSet.add(userResource.Id);
            }
            if(!resourceIdSet.isEmpty()){
                if(isThirdParty == true){
                    //AggregateResult results = [SELECT Count(Id) TotalRec FROM WorkOrderLineItem WHERE (Status != 'Canceled' AND Status != 'Open' AND Status ='Completed' AND ExecutingEngineer__c IN: resourceIdSet) AND WorkOrderType__c !=: WO_TYPE_S20_MACHINECARE];
                    AggregateResult results = Database.query('SELECT Count(Id) TotalRec FROM WorkOrderLineItem WHERE Status =\'Completed\'  AND ExecutingEngineer__c IN: resourceIdSet AND WorkOrderType__c !=: WO_TYPE_S20_MACHINECARE AND CreatedDate = LAST_N_DAYS:' + OPGThreshold);
                    totalRecords = (Integer)results.get('TotalRec');    
                    
                }
                else {
                    //AggregateResult results = [SELECT Count(Id) TotalRec FROM WorkOrderLineItem WHERE (Status != 'Canceled' AND Status != 'Open' AND Status ='Completed' AND ExecutingEngineer__c IN: resourceIdSet)];
                    AggregateResult results = Database.query('SELECT Count(Id) TotalRec FROM WorkOrderLineItem WHERE Status =\'Completed\'  AND ExecutingEngineer__c IN: resourceIdSet AND CreatedDate = LAST_N_DAYS:' + OPGThreshold);                     
                    totalRecords = (Integer)results.get('TotalRec');    
                }                               
            }
            
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_WorkOrderListMobileControllerCLONEException('Force to throw an exception');
            }

        } catch (Exception e){
            lResponse.status = 'ERROR';
            lResponse.message = 'Error: ' + e.getMessage() + '\nSTACK TRACE: ' + e.getStackTraceString();
        }


        return totalRecords;
    } 
    //3. GET NUMBER OF MY TEAM'S OPEN RECORDS
    @AuraEnabled
    public static Integer getAllRecordsTeamNumberOpen(){

        LightningResponse lResponse = new LightningResponse();

        //FIND ALL EXECUTING ENGINEER/RESOURCE RECORD RELATED TO THE CURRENT USER
        Id currentUserId = UserInfo.getUserId();
        Set<String> teamNumbersSet = new Set<String>();
        Set<Id> resourceIdSet = new Set<Id>();
        Set<Id> resourceIdSetTeam = new Set<Id>();
        Integer totalRecords = 0;

        try{
            //get resource ids and teamnumbers related to the user
            for(Resource__c userResource : [SELECT Id, RelatedUser__c, TeamNumber__c FROM Resource__c WHERE RelatedUser__c =: currentUserId] ){
                    resourceIdSet.add(userResource.Id);
                    if(userResource.TeamNumber__c != null){
                        teamNumbersSet.add(userResource.TeamNumber__c);
                    }
            }
            if(!teamNumbersSet.isEmpty()){
                //get all the resources in those teams where the user is a member of
                for(Resource__c resource : [SELECT Id FROM Resource__c WHERE TeamNumber__c IN :teamNumbersSet]){
                    resourceIdSetTeam.add(resource.Id);
                }
                if(!resourceIdSetTeam.isEmpty()){
                    AggregateResult results = [SELECT Count(Id) TotalRec FROM WorkOrderLineItem WHERE (Status != 'Canceled' AND Status != 'Open' AND Status !='Completed' AND Status != 'Review Needed' AND ExecutingEngineer__c IN:resourceIdSetTeam AND ExecutingEngineer__c NOT IN:resourceIdSet)];
                    totalRecords = (Integer)results.get('TotalRec');        
                }
                
            }
            
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_WorkOrderListMobileControllerCLONEException('Force to throw an exception');
            }

        } catch (Exception e){
            lResponse.status = 'ERROR';
            lResponse.message = 'Error: ' + e.getMessage() + '\nSTACK TRACE: ' + e.getStackTraceString();
        }


        return totalRecords;
    }
    //4. GET NUMBER OF MY TEAM'S CLOSED RECORDS
    @AuraEnabled
    public static Integer getAllRecordsTeamNumberClosed(){

        LightningResponse lResponse = new LightningResponse();

        //FIND ALL EXECUTING ENGINEER/RESOURCE RECORD RELATED TO THE CURRENT USER
        Id currentUserId = UserInfo.getUserId();
        Set<String> teamNumbersSet = new Set<String>();
        Set<Id> resourceIdSet = new Set<Id>();
        Set<Id> resourceIdSetTeam = new Set<Id>();
        Integer totalRecords = 0;

        try{
            //get resource ids and teamnumbers related to the user
            for(Resource__c userResource : [SELECT Id, RelatedUser__c, TeamNumber__c FROM Resource__c WHERE RelatedUser__c =: currentUserId] ){
                    resourceIdSet.add(userResource.Id);
                    if(userResource.TeamNumber__c != null){
                        teamNumbersSet.add(userResource.TeamNumber__c);
                    }
            }
            if(!teamNumbersSet.isEmpty()){
                //get all the resources in those teams where the user is a member of
                for(Resource__c resource : [SELECT Id FROM Resource__c WHERE TeamNumber__c IN :teamNumbersSet]){
                    resourceIdSetTeam.add(resource.Id);
                }
                if(!resourceIdSetTeam.isEmpty()){
                    //AggregateResult results = [SELECT Count(Id) TotalRec FROM WorkOrderLineItem WHERE (Status = 'Completed' OR Status = 'Review Needed') AND ExecutingEngineer__c IN:resourceIdSetTeam AND ExecutingEngineer__c NOT IN:resourceIdSet];
                    AggregateResult results = Database.query('SELECT Count(Id) TotalRec FROM WorkOrderLineItem WHERE Status =\'Completed\'  AND ExecutingEngineer__c IN:resourceIdSetTeam AND ExecutingEngineer__c NOT IN:resourceIdSet AND CreatedDate = LAST_N_DAYS:' + OPGThreshold);
                    totalRecords = (Integer)results.get('TotalRec');        
                }                
            }
            
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_WorkOrderListMobileControllerCLONEException('Force to throw an exception');
            }

        } catch (Exception e){
            lResponse.status = 'ERROR';
            lResponse.message = 'Error: ' + e.getMessage() + '\nSTACK TRACE: ' + e.getStackTraceString();
        }


        return totalRecords;
    }
    //5. GET NUMBER OF MY OPERATING OPEN RECORDS
    @AuraEnabled
    public static Integer getAllOperatingNumberOpen(){

        LightningResponse lResponse = new LightningResponse();
        Integer totalRecords = 0;
        Id currentUserId = UserInfo.getUserId();
        Set<Id> resourceIdSet = new Set<Id>();

        try{
            //get resource ids related to the user
            for(Resource__c userResource : [SELECT Id, RelatedUser__c, TeamNumber__c FROM Resource__c WHERE RelatedUser__c =: currentUserId] ){
                resourceIdSet.add(userResource.Id);
            }
            if(!resourceIdSet.isEmpty()){                                                                    
                AggregateResult results = Database.query('SELECT Count(Id) TotalRec FROM WorkOrderLineItem WHERE Status != \'Canceled\' AND Status != \'Open\' AND Status !=\'Completed\' AND Status != \'Review Needed\' AND ExecutingEngineer__c IN:resourceIdSet AND WorkOrderType__c =:WO_TYPE_S20_MACHINECARE');
                totalRecords = (Integer)results.get('TotalRec');    
            }
            
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_WorkOrderListMobileControllerCLONEException('Force to throw an exception');
            }

        } catch (Exception e){
            lResponse.status = 'ERROR';
            lResponse.message = 'Error: ' + e.getMessage() + '\nSTACK TRACE: ' + e.getStackTraceString();
        }
    
        return totalRecords;
    }
    //6. GET NUMBER OF MY OPERATING CLOSED RECORDS
    @AuraEnabled
    public static Integer getAllOperatingNumberClosed(){

        LightningResponse lResponse = new LightningResponse();
        Integer totalRecords = 0;
        Id currentUserId = UserInfo.getUserId();
        Set<Id> resourceIdSet = new Set<Id>();

        try{
            //get resource ids related to the user
            for(Resource__c userResource : [SELECT Id, RelatedUser__c, TeamNumber__c FROM Resource__c WHERE RelatedUser__c =: currentUserId] ){
                resourceIdSet.add(userResource.Id);
            }
            if(!resourceIdSet.isEmpty()){                             
                AggregateResult results = Database.query('SELECT Count(Id) TotalRec FROM WorkOrderLineItem WHERE (Status =\'Completed\' OR Status =\'Canceled\') AND ExecutingEngineer__c IN: resourceIdSet AND WorkOrderType__c =: WO_TYPE_S20_MACHINECARE AND CreatedDate = LAST_N_DAYS:' + OPGThreshold);
                totalRecords = (Integer)results.get('TotalRec');    
            }
            
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_WorkOrderListMobileControllerCLONEException('Force to throw an exception');
            }

        } catch (Exception e){
            lResponse.status = 'ERROR';
            lResponse.message = 'Error: ' + e.getMessage() + '\nSTACK TRACE: ' + e.getStackTraceString();
        }
    
        return totalRecords;
    }


    //METHODS FOR SEARCHING RECORDS AND FILTERING THE LISTVIEW
    //1. SEARCH MY OPEN RECORDS
    @AuraEnabled
    public static String searchMyOpen(String searchString, Boolean isThirdParty) {

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
                    if(isThirdParty == true){
                        taskToReturn = [SELECT Id, JDELineItemNumber__c, toLabel(WorkOrderType__c), toLabel(WorkOrderLineItemType__c), StartDate__c, EndDate__c, TaskDueDate__c, Status, Case__r.Account.Name, ParentWorkOrderLineItem.JDELineItemNumber__c, ParentWorkOrderLineItemId, ExecutingEngineer__c, ExecutingEngineer__r.EmployeeFirstName__c, ExecutingEngineer__r.EmployeeLastName__c, AccountLocation__r.Name, AccountLocation__r.Shipping_PostalCode__c, ProductDescription__c, Executing_Engineer_First_Name__c, Executing_Engineer_Last_Name__c, AccountLocationPostalCode__c, Account_Location_Name__c, AccountLocationHouseNumber__c, AccountLocationStreet__c FROM WorkOrderLineItem WHERE (JDELineItemNumber__c = :searchString OR Status = :searchString OR Executing_Engineer_First_Name__c = :searchString OR Executing_Engineer_Last_Name__c = :searchString OR AccountLocationPostalCode__c = :searchString OR Account_Location_Name__c = :searchString OR AccountLocationHouseNumber__c = :searchString OR AccountLocationStreet__c = :searchString OR Delivery_Id__c = :searchString) AND (Status != 'Canceled' AND Status != 'Open' AND Status !='Completed' AND Status != 'Review Needed' AND ExecutingEngineer__c IN: resourceIdSet) AND WorkOrderType__c !=: WO_TYPE_S20_MACHINECARE ORDER BY TaskDueDate__c ASC];
                    }
                    else {                                            
                        taskToReturn = [SELECT Id, JDELineItemNumber__c, toLabel(WorkOrderType__c), toLabel(WorkOrderLineItemType__c), StartDate__c, EndDate__c, TaskDueDate__c, Status, Case__r.Account.Name, ParentWorkOrderLineItem.JDELineItemNumber__c, ParentWorkOrderLineItemId, ExecutingEngineer__c, ExecutingEngineer__r.EmployeeFirstName__c, ExecutingEngineer__r.EmployeeLastName__c, AccountLocation__r.Name, AccountLocation__r.Shipping_PostalCode__c, ProductDescription__c, Executing_Engineer_First_Name__c, Executing_Engineer_Last_Name__c, AccountLocationPostalCode__c, Account_Location_Name__c, AccountLocationHouseNumber__c, AccountLocationStreet__c FROM WorkOrderLineItem WHERE (JDELineItemNumber__c = :searchString OR Status = :searchString OR Executing_Engineer_First_Name__c = :searchString OR Executing_Engineer_Last_Name__c = :searchString OR AccountLocationPostalCode__c = :searchString OR Account_Location_Name__c = :searchString OR AccountLocationHouseNumber__c = :searchString OR AccountLocationStreet__c = :searchString OR Delivery_Id__c = :searchString) AND (Status != 'Canceled' AND Status != 'Open' AND Status !='Completed' AND Status != 'Review Needed' AND ExecutingEngineer__c IN: resourceIdSet) ORDER BY TaskDueDate__c ASC];
                    }
                }
            }

            lResponse.returnValue = JSON.serialize(taskToReturn);
            
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_WorkOrderListMobileControllerCLONEException('Force to throw an exception');
            }

        } catch (Exception e){
            lResponse.status = 'ERROR';
            lResponse.message = 'Error: ' + e.getMessage() + '\nSTACK TRACE: ' + e.getStackTraceString();
        }
        
        return JSON.serialize(lResponse);
    }
    //2. SEARCH MY CLOSED RECORDS     
    @AuraEnabled
    public static String searchMyClosed(String searchString, Boolean isThirdParty) {

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
                    if(isThirdParty == true){
                        //taskToReturn = [SELECT Id, JDELineItemNumber__c, toLabel(WorkOrderType__c), toLabel(WorkOrderLineItemType__c), StartDate__c, EndDate__c, TaskDueDate__c, Status, Case__r.Account.Name, ParentWorkOrderLineItem.JDELineItemNumber__c, ParentWorkOrderLineItemId, ExecutingEngineer__c, ExecutingEngineer__r.EmployeeFirstName__c, ExecutingEngineer__r.EmployeeLastName__c, AccountLocation__r.Name, AccountLocation__r.Shipping_PostalCode__c, ProductDescription__c, Executing_Engineer_First_Name__c, Executing_Engineer_Last_Name__c, AccountLocationPostalCode__c, Account_Location_Name__c, AccountLocationHouseNumber__c, AccountLocationStreet__c FROM WorkOrderLineItem WHERE (Status = 'Completed' AND ExecutingEngineer__c IN: resourceIdSet AND (JDELineItemNumber__c = :searchString OR Status = :searchString OR Executing_Engineer_First_Name__c = :searchString OR Executing_Engineer_Last_Name__c = :searchString OR AccountLocationPostalCode__c = :searchString OR Account_Location_Name__c = :searchString OR AccountLocationHouseNumber__c = :searchString OR AccountLocationStreet__c = :searchString OR Delivery_Id__c = :searchString)) AND WorkOrderType__c !=: WO_TYPE_S20_MACHINECARE];
                        taskToReturn = Database.query('SELECT Id, JDELineItemNumber__c, toLabel(WorkOrderType__c), toLabel(WorkOrderLineItemType__c), StartDate__c, EndDate__c, TaskDueDate__c, Status, Case__r.Account.Name, ParentWorkOrderLineItem.JDELineItemNumber__c, ParentWorkOrderLineItemId, ExecutingEngineer__c, ExecutingEngineer__r.EmployeeFirstName__c, ExecutingEngineer__r.EmployeeLastName__c, AccountLocation__r.Name, AccountLocation__r.Shipping_PostalCode__c, ProductDescription__c, Executing_Engineer_First_Name__c, Executing_Engineer_Last_Name__c, AccountLocationPostalCode__c, Account_Location_Name__c, AccountLocationHouseNumber__c, AccountLocationStreet__c FROM WorkOrderLineItem WHERE (JDELineItemNumber__c = :searchString OR Status = :searchString OR Executing_Engineer_First_Name__c = :searchString OR Executing_Engineer_Last_Name__c = :searchString OR AccountLocationPostalCode__c = :searchString OR Account_Location_Name__c = :searchString OR AccountLocationHouseNumber__c = :searchString OR AccountLocationStreet__c = :searchString OR Delivery_Id__c = :searchString) AND Status =\'Completed\'  AND ExecutingEngineer__c IN: resourceIdSet AND WorkOrderType__c !=: WO_TYPE_S20_MACHINECARE AND CreatedDate = LAST_N_DAYS:' + OPGThreshold + ' ORDER BY TaskDueDate__c DESC');                             
                    }
                    else {                                            
                        //taskToReturn = [SELECT Id, JDELineItemNumber__c, toLabel(WorkOrderType__c), toLabel(WorkOrderLineItemType__c), StartDate__c, EndDate__c, TaskDueDate__c, Status, Case__r.Account.Name, ParentWorkOrderLineItem.JDELineItemNumber__c, ParentWorkOrderLineItemId, ExecutingEngineer__c, ExecutingEngineer__r.EmployeeFirstName__c, ExecutingEngineer__r.EmployeeLastName__c, AccountLocation__r.Name, AccountLocation__r.Shipping_PostalCode__c, ProductDescription__c, Executing_Engineer_First_Name__c, Executing_Engineer_Last_Name__c, AccountLocationPostalCode__c, Account_Location_Name__c, AccountLocationHouseNumber__c, AccountLocationStreet__c FROM WorkOrderLineItem WHERE (Status = 'Completed' AND ExecutingEngineer__c IN: resourceIdSet AND (JDELineItemNumber__c = :searchString OR Status = :searchString OR Executing_Engineer_First_Name__c = :searchString OR Executing_Engineer_Last_Name__c = :searchString OR AccountLocationPostalCode__c = :searchString OR Account_Location_Name__c = :searchString OR AccountLocationHouseNumber__c = :searchString OR AccountLocationStreet__c = :searchString OR Delivery_Id__c = :searchString))];
                        taskToReturn = Database.query('SELECT Id, JDELineItemNumber__c, toLabel(WorkOrderType__c), toLabel(WorkOrderLineItemType__c), StartDate__c, EndDate__c, TaskDueDate__c, Status, Case__r.Account.Name, ParentWorkOrderLineItem.JDELineItemNumber__c, ParentWorkOrderLineItemId, ExecutingEngineer__c, ExecutingEngineer__r.EmployeeFirstName__c, ExecutingEngineer__r.EmployeeLastName__c, AccountLocation__r.Name, AccountLocation__r.Shipping_PostalCode__c, ProductDescription__c, Executing_Engineer_First_Name__c, Executing_Engineer_Last_Name__c, AccountLocationPostalCode__c, Account_Location_Name__c, AccountLocationHouseNumber__c, AccountLocationStreet__c FROM WorkOrderLineItem WHERE (JDELineItemNumber__c = :searchString OR Status = :searchString OR Executing_Engineer_First_Name__c = :searchString OR Executing_Engineer_Last_Name__c = :searchString OR AccountLocationPostalCode__c = :searchString OR Account_Location_Name__c = :searchString OR AccountLocationHouseNumber__c = :searchString OR AccountLocationStreet__c = :searchString OR Delivery_Id__c = :searchString) AND Status =\'Completed\'  AND ExecutingEngineer__c IN: resourceIdSet AND CreatedDate = LAST_N_DAYS:' + OPGThreshold + ' ORDER BY TaskDueDate__c DESC');   
                    }
                }
            }

            lResponse.returnValue = JSON.serialize(taskToReturn);
            
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_WorkOrderListMobileControllerCLONEException('Force to throw an exception');
            }

        } catch (Exception e){
            lResponse.status = 'ERROR';
            lResponse.message = 'Error: ' + e.getMessage() + '\nSTACK TRACE: ' + e.getStackTraceString();
        }
        
        return JSON.serialize(lResponse);
    }
    //3. SEARCH TEAM'S OPEN RECORDS
    @AuraEnabled
    public static String searchTeamsOpen(String searchString) {

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
                            taskToReturn = [SELECT Id, JDELineItemNumber__c, toLabel(WorkOrderType__c), toLabel(WorkOrderLineItemType__c), StartDate__c, EndDate__c, TaskDueDate__c, Status, Case__r.Account.Name, ParentWorkOrderLineItem.JDELineItemNumber__c, ParentWorkOrderLineItemId, ExecutingEngineer__c, ExecutingEngineer__r.EmployeeFirstName__c, ExecutingEngineer__r.EmployeeLastName__c, AccountLocation__r.Name, AccountLocation__r.Shipping_PostalCode__c, ProductDescription__c, Executing_Engineer_First_Name__c, Executing_Engineer_Last_Name__c, AccountLocationPostalCode__c, Account_Location_Name__c, AccountLocationHouseNumber__c, AccountLocationStreet__c FROM WorkOrderLineItem WHERE (JDELineItemNumber__c = :searchString OR Status = :searchString OR Executing_Engineer_First_Name__c = :searchString OR Executing_Engineer_Last_Name__c = :searchString OR AccountLocationPostalCode__c = :searchString OR Account_Location_Name__c = :searchString OR AccountLocationHouseNumber__c = :searchString OR AccountLocationStreet__c = :searchString OR Delivery_Id__c = :searchString) AND (Status != 'Canceled' AND Status != 'Open' AND Status !='Completed' AND Status != 'Review Needed' AND ExecutingEngineer__c IN:resourceIdSetTeam AND ExecutingEngineer__c NOT IN:resourceIdSet) ORDER BY TaskDueDate__c ASC];
                        }
                    }
                }
            }

            lResponse.returnValue = JSON.serialize(taskToReturn);
            
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_WorkOrderListMobileControllerCLONEException('Force to throw an exception');
            }

        } catch (Exception e){
            lResponse.status = 'ERROR';
            lResponse.message = 'Error: ' + e.getMessage() + '\nSTACK TRACE: ' + e.getStackTraceString();
        }    

        return JSON.serialize(lResponse);
    }
    //4. SEARCH TEAM'S CLOSED RECORDS
    @AuraEnabled
    public static String searchTeamsClosed(String searchString) {

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
                            //taskToReturn = [SELECT Id, JDELineItemNumber__c, toLabel(WorkOrderType__c), toLabel(WorkOrderLineItemType__c), StartDate__c, EndDate__c, TaskDueDate__c, Status, Case__r.Account.Name, ParentWorkOrderLineItem.JDELineItemNumber__c, ParentWorkOrderLineItemId, ExecutingEngineer__c, ExecutingEngineer__r.EmployeeFirstName__c, ExecutingEngineer__r.EmployeeLastName__c, AccountLocation__r.Name, AccountLocation__r.Shipping_PostalCode__c, ProductDescription__c, Executing_Engineer_First_Name__c, Executing_Engineer_Last_Name__c, AccountLocationPostalCode__c, Account_Location_Name__c, AccountLocationHouseNumber__c, AccountLocationStreet__c FROM WorkOrderLineItem WHERE (Status ='Completed' AND ExecutingEngineer__c IN:resourceIdSetTeam AND ExecutingEngineer__c NOT IN:resourceIdSet AND (JDELineItemNumber__c = :searchString OR Status = :searchString OR Executing_Engineer_First_Name__c = :searchString OR Executing_Engineer_Last_Name__c = :searchString OR AccountLocationPostalCode__c = :searchString OR Account_Location_Name__c = :searchString OR AccountLocationHouseNumber__c = :searchString OR AccountLocationStreet__c = :searchString OR Delivery_Id__c = :searchString))];
                            taskToReturn = Database.query('SELECT Id, JDELineItemNumber__c, toLabel(WorkOrderType__c), toLabel(WorkOrderLineItemType__c), StartDate__c, EndDate__c, TaskDueDate__c, Status, Case__r.Account.Name, ParentWorkOrderLineItem.JDELineItemNumber__c, ParentWorkOrderLineItemId, ExecutingEngineer__c, ExecutingEngineer__r.EmployeeFirstName__c, ExecutingEngineer__r.EmployeeLastName__c, AccountLocation__r.Name, AccountLocation__r.Shipping_PostalCode__c, ProductDescription__c, Executing_Engineer_First_Name__c, Executing_Engineer_Last_Name__c, AccountLocationPostalCode__c, Account_Location_Name__c, AccountLocationHouseNumber__c, AccountLocationStreet__c FROM WorkOrderLineItem WHERE (JDELineItemNumber__c = :searchString OR Status = :searchString OR Executing_Engineer_First_Name__c = :searchString OR Executing_Engineer_Last_Name__c = :searchString OR AccountLocationPostalCode__c = :searchString OR Account_Location_Name__c = :searchString OR AccountLocationHouseNumber__c = :searchString OR AccountLocationStreet__c = :searchString OR Delivery_Id__c = :searchString)) ANDStatus =\'Completed\'  AND ExecutingEngineer__c IN:resourceIdSetTeam AND ExecutingEngineer__c NOT IN:resourceIdSet AND CreatedDate = LAST_N_DAYS:' + OPGThreshold + ' ORDER BY TaskDueDate__c DESC');
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
    //5. SEARCH OPERATING OPEN RECORDS
    @AuraEnabled
    public static String searchOperatingOpen(String searchString) {

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
                    taskToReturn = Database.query('SELECT Id, JDELineItemNumber__c, toLabel(WorkOrderType__c), toLabel(WorkOrderLineItemType__c), StartDate__c, EndDate__c, TaskDueDate__c, Status, Case__r.Account.Name, ParentWorkOrderLineItem.JDELineItemNumber__c, ParentWorkOrderLineItemId, ExecutingEngineer__c, ExecutingEngineer__r.EmployeeFirstName__c, ExecutingEngineer__r.EmployeeLastName__c, AccountLocation__r.Name, AccountLocation__r.Shipping_PostalCode__c, ProductDescription__c, Executing_Engineer_First_Name__c, Executing_Engineer_Last_Name__c, AccountLocationPostalCode__c, Account_Location_Name__c, AccountLocationHouseNumber__c, AccountLocationStreet__c FROM WorkOrderLineItem WHERE (JDELineItemNumber__c = :searchString OR Status = :searchString OR Executing_Engineer_First_Name__c = :searchString OR Executing_Engineer_Last_Name__c = :searchString OR AccountLocationPostalCode__c = :searchString OR Account_Location_Name__c = :searchString OR AccountLocationHouseNumber__c = :searchString OR AccountLocationStreet__c = :searchString OR Delivery_Id__c = :searchString) AND Status != \'Canceled\' AND Status != \'Open\' AND Status !=\'Completed\' AND Status != \'Review Needed\' AND ExecutingEngineer__c IN:resourceIdSet AND WorkOrderType__c =:WO_TYPE_S20_MACHINECARE ORDER BY TaskDueDate__c ASC');                    
                }
            }

            lResponse.returnValue = JSON.serialize(taskToReturn);
            
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_WorkOrderListMobileControllerCLONEException('Force to throw an exception');
            }

        } catch (Exception e){
            lResponse.status = 'ERROR';
            lResponse.message = 'Error: ' + e.getMessage() + '\nSTACK TRACE: ' + e.getStackTraceString();
        }
        
        return JSON.serialize(lResponse);
    }
    //6. SEARCH OPERATING CLOSED RECORDS
    @AuraEnabled
    public static String searchOperatingClosed(String searchString) {

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
                    taskToReturn = Database.query('SELECT Id, JDELineItemNumber__c, toLabel(WorkOrderType__c), toLabel(WorkOrderLineItemType__c), StartDate__c, EndDate__c, TaskDueDate__c, Status, Case__r.Account.Name, ParentWorkOrderLineItem.JDELineItemNumber__c, ParentWorkOrderLineItemId, ExecutingEngineer__c, ExecutingEngineer__r.EmployeeFirstName__c, ExecutingEngineer__r.EmployeeLastName__c, AccountLocation__r.Name, AccountLocation__r.Shipping_PostalCode__c, ProductDescription__c, Executing_Engineer_First_Name__c, Executing_Engineer_Last_Name__c, AccountLocationPostalCode__c, Account_Location_Name__c, AccountLocationHouseNumber__c, AccountLocationStreet__c FROM WorkOrderLineItem WHERE (JDELineItemNumber__c = :searchString OR Status = :searchString OR Executing_Engineer_First_Name__c = :searchString OR Executing_Engineer_Last_Name__c = :searchString OR AccountLocationPostalCode__c = :searchString OR Account_Location_Name__c = :searchString OR AccountLocationHouseNumber__c = :searchString OR AccountLocationStreet__c = :searchString OR Delivery_Id__c = :searchString) AND (Status =\'Completed\' OR Status =\'Canceled\') AND ExecutingEngineer__c IN: resourceIdSet AND WorkOrderType__c =: WO_TYPE_S20_MACHINECARE AND CreatedDate = LAST_N_DAYS:' + OPGThreshold + ' ORDER BY TaskDueDate__c DESC');                     
                }
            }

            lResponse.returnValue = JSON.serialize(taskToReturn);
            
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_WorkOrderListMobileControllerCLONEException('Force to throw an exception');
            }

        } catch (Exception e){
            lResponse.status = 'ERROR';
            lResponse.message = 'Error: ' + e.getMessage() + '\nSTACK TRACE: ' + e.getStackTraceString();
        }
        
        return JSON.serialize(lResponse);
    }

    
    @AuraEnabled
    public static String checkIfThirdParty() {

        LightningResponse lResponse = new LightningResponse();  
        lResponse.returnValue = 'false';    
        Id currentUserId = UserInfo.getUserId();        
 
        try{
            Resource__c relatedResource = [SELECT Id, RLS_Portal_User__c FROM Resource__c WHERE RelatedUser__c =: currentUserId];       
            if(relatedResource != null){
                lResponse.returnValue = String.valueOf(relatedResource.RLS_Portal_User__c);
            }
            
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_WorkOrderListMobileControllerCLONEException('Force to throw an exception');
            }
            
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