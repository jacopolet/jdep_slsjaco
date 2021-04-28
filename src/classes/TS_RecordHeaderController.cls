/*
* @author        Xen Reyes
* @date          9.11.2017          
* @description   Controller class for TS_RecordHeader/TS_createCaseRecord/TS_createCaseRecordFS Lightning Component
* @revision(s)  Karen Hung Aug. 6, 2019 added without sharing indication DOO-728
*/
public without sharing class TS_RecordHeaderController {
    
    public static Boolean hasException = false;
    
    public class TS_RecordHeaderControllerException extends Exception {  }
    
    @AuraEnabled
    public static String currentUserId(){
        CustomLogging.push('currentUserId', 'TS_RecordHeaderController');
        CustomLogging.pop();
        return UserInfo.getUserId();
    }

    @AuraEnabled
    public static Boolean getCaseAccess(String recordId){
        CustomLogging.push('getCaseAccess', 'TS_RecordHeaderController');
        CustomLogging.pop();
        return [SELECT RecordId, MaxAccessLevel,HasAllAccess, HasDeleteAccess,  HasEditAccess, HasReadAccess,  HasTransferAccess FROM UserRecordAccess WHERE UserId =: UserInfo.getUserId() AND RecordId =: recordId][0].HasEditAccess;
    }

    @AuraEnabled
    public static String checkButtonAccess(){
		CustomLogging.push('checkButtonAccess', 'TS_RecordHeaderController');
        Map<Id, String> customPermissionNamesById = new Map<Id, String>();
        List<String> withPermission = new List<String>();
        ButtonAccesssWrapper result = new ButtonAccesssWrapper();

        Id userId = UserInfo.getUserId();
        Id userProfileId = UserInfo.getProfileId();
        
        //Profile pf = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1]; //Language Issues
        Map<Id,Profile> pf_map = new Map<Id,Profile>([SELECT Id FROM Profile WHERE PermissionsPrivacyDataAccess = true OR PermissionsCustomizeApplication = true]);

        //Id sysAdId = '00e0Y00000139iNQAQ';
        //if(userProfileId != pf.Id){ //Language Issues
        if(!pf_map.containsKey(userProfileId)){ 
        //if(userProfileId != sysAdId){    
            List<CustomPermission> customPermissions = [SELECT Id, DeveloperName FROM CustomPermission WHERE DeveloperName LIKE 'TS%'];
            for(CustomPermission cc: customPermissions){
                customPermissionNamesById.put(cc.Id, cc.DeveloperName);
            }
             
            List<SetupEntityAccess> setupEntities = [SELECT SetupEntityId FROM SetupEntityAccess WHERE SetupEntityId in :customPermissionNamesById.keySet() 
                                                     AND ParentId IN (SELECT PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId =: userId)];

            /* System.debug('setupEntities::'+setupEntities);
            System.debug('customPermissionNamesById::'+customPermissionNamesById); */

            for(SetupEntityAccess st : setupEntities){
                if(customPermissionNamesById.containsKey(st.SetupEntityId)){
                    withPermission.add(customPermissionNamesById.get(st.SetupEntityId));
                }
            }
            
            /* System.debug('withPermission::'+withPermission); */

            result.isSysAd = false;
            result.buttonsWithPermission = withPermission;
        } else {
            result.isSysAd = true;
        }

		CustomLogging.pop();
        return JSON.serialize(result);
    }

    public class ButtonAccesssWrapper {
        public Boolean isSysAd;
        public List<String> buttonsWithPermission;
    }

    @AuraEnabled
    public static Case queryCase(String recordId){
        CustomLogging.push('queryCase', 'TS_RecordHeaderController');
        CustomLogging.pop();
        return [SELECT Id,
                      ContactId,
                      AccountId,
                      Account_Block__c,
                      CreatedOrderedManually__c,
                      CaseSubStatus__c,
                      Status,
                      Reason__c,
                      Cause__c,
                      Priority,
                      CaseNumber,
                      Subject,
                      IsEscalated,
                      OwnerId,
                      InternalSolution__c,
                      External_Solution__c,
                      RootCauseSolution__c,
                      Type,
                      ApptusOrder__c,
                      Solution_Type__c,
                      CompletionCode__c,
                      DefectCodes__c,
                      Fault_Code__c,
                      SLADate__c,
                      Number_of_Open_WOLI_Tasks__c,
                      Number_of_Completed_WOLI_Tasks__c,
                      CanGenerateOrder__c,
                      SubType__c,
                      Click__c,
                      AccountLocation__c,
                      AccountLocation__r.Name,
                      Contact.Name,
                      PhysicalAsset__c,
                      PhysicalAsset__r.Name,
                      PhysicalAsset__r.Product__c FROM Case WHERE Id =: recordId];
    }
    
    @AuraEnabled
    public static Boolean isFollowingCheck(String recordId){
        CustomLogging.push('isFollowingCheck', 'TS_RecordHeaderController');
        Boolean isFollowing = False;
        try{
            EntitySubscription checkSubs = [SELECT Id, ParentId FROM EntitySubscription WHERE SubscriberId =: UserInfo.getUserId() AND ParentId =: recordId LIMIT 1];
            if(checkSubs != NULL) isFollowing = True;
            
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_RecordHeaderControllerException('Force to throw an exception');
            }
            
        } catch(exception e){
            
        }
        CustomLogging.pop();
        return isFollowing;
    }
    
    @AuraEnabled
    public static void followRecord(String recordId){
        CustomLogging.push('followRecord', 'TS_RecordHeaderController');
        if(recordId != NULL){
            EntitySubscription newSubs = new EntitySubscription();
            newSubs.ParentId = recordId;
            newSubs.SubscriberId = UserInfo.getUserId();
            insert newSubs; 
        }
        CustomLogging.pop();
    }

    @AuraEnabled
    public static String createOrderClass (String recordId){
        CustomLogging.push('createOrderClass', 'TS_RecordHeaderController');
        String result = 'SUCCESS';
        if(!String.isEmpty(recordId)){
            Case cs = new Case(id=recordId);
            cs.Status = 'In progress';
            cs.CaseSubStatus__c = 'Order Open';
            cs.CreatedOrderedManually__c = true;

            try{
                update cs;
                
                //Exception for test class purposes
                if (Test.isRunningTest() && hasException) {
                    throw new TS_RecordHeaderControllerException('Force to throw an exception');
                }
            
            } catch(Exception e){
                String err = e.getMessage();
                return err;
            }
        }
        CustomLogging.pop();
        return result;
    }
    
    @AuraEnabled
    public static void unfollowRecord(String recordId){
        CustomLogging.push('unfollowRecord', 'TS_RecordHeaderController');
        if(recordId != NULL){
            try{
                EntitySubscription checkSubs = [SELECT Id, ParentId FROM EntitySubscription WHERE SubscriberId =: UserInfo.getUserId() AND ParentId =: recordId LIMIT 1];
                if(checkSubs != NULL) delete checkSubs;
                
                //Exception for test class purposes
                if (Test.isRunningTest() && hasException) {
                    throw new TS_RecordHeaderControllerException('Force to throw an exception');
                }
            } catch(exception e){

            }
        }
        CustomLogging.pop();
    }
    
    @AuraEnabled
    public static String getRecordType(String recordId){
        CustomLogging.push('getRecordType', 'TS_RecordHeaderController');
        String recordTypeName;
        if(recordId != NULL){
            try{

                Case checkSubs = [SELECT Id, RecordTypeId, RecordType.DeveloperName FROM Case WHERE Id =: recordId LIMIT 1];
                
                //Exception for test class purposes
                if (Test.isRunningTest() && hasException) {
                    throw new TS_RecordHeaderControllerException('Force to throw an exception');
                }
                
                if(checkSubs != NULL) {
                    return checkSubs.RecordType.DeveloperName;
                }
                
            } catch(exception e){
                String err = e.getMessage();
                return err;
            }
        }
        CustomLogging.pop();
        return recordTypeName;
    }

    @AuraEnabled
    public static Case getCaseRecord(String recordId){
        CustomLogging.push('getCaseRecord', 'TS_RecordHeaderController');
        Case cc = new Case();
        if(recordId != NULL){
            try{
               cc = [SELECT Id, ContactId, RecordTypeId, RecordType.DeveloperName FROM Case WHERE Id =: recordId LIMIT 1];
               
                //Exception for test class purposes
                if (Test.isRunningTest() && hasException) {
                    throw new TS_RecordHeaderControllerException('Force to throw an exception');
                }
                
            } catch(exception e){
                System.debug(e.getMessage());
            }
        }
        CustomLogging.pop();
        return cc;
    }

    @AuraEnabled
    public static void insertComments(String recordId, String comment){
		CustomLogging.push('insertComments', 'TS_RecordHeaderController');
        if(recordId != NULL && comment != NULL){
			CaseComment casecom = new CaseComment();
            casecom.ParentId = recordId;
            casecom.CommentBody = comment;
            insert casecom;
        }
        CustomLogging.pop();
    }
    
    @AuraEnabled
	public static String getRecordTypeFS(){
        CustomLogging.push('getRecordTypeFS', 'TS_RecordHeaderController');
        CustomLogging.pop();
		return TS_UtilityClass.getRecordTypeIdByName(Label.TS_Obj_API_Name_Case, Label.TS_Case_RecordType_Field);                
	}
    
    @AuraEnabled
	public static String getRecordTypeCR(){
        CustomLogging.push('getRecordTypeCR', 'TS_RecordHeaderController');
        CustomLogging.pop();
		return TS_UtilityClass.getRecordTypeIdByName(Label.TS_Obj_API_Name_Case, Label.TS_Case_RecordType_Registration);          
	}
    
    @AuraEnabled
	public static String getRecordTypeAS(){
        CustomLogging.push('getRecordTypeAS', 'TS_RecordHeaderController');
        CustomLogging.pop();
		return TS_UtilityClass.getRecordTypeIdByName('WorkOrderLineItem', 'Add Service Job');          
	}
    
    @AuraEnabled
	public static String getRecordTypeInboundTask(){
        CustomLogging.push('getRecordTypeInboundTask', 'TS_RecordHeaderController');
        CustomLogging.pop();
        
		return TS_UtilityClass.getRecordTypeIdByName('Task', 'Inbound');          
	}

    @AuraEnabled
    public static String getRecordTypeGeneric(String objName, String recordTypeName){
        CustomLogging.push('getRecordTypeGeneric', 'TS_RecordHeaderController');
        CustomLogging.pop();
        
        return TS_UtilityClass.getRecordTypeIdByName(objName, recordTypeName);        
    }
    
    @AuraEnabled
    public static String getInfoForTask(){
        CustomLogging.push('getInfoForTask', 'TS_RecordHeaderController');
        CustomLogging.pop();

        GetInfoForTaskWrapper result = new GetInfoForTaskWrapper();
        result.inboundId = TS_UtilityClass.getRecordTypeIdByName('Task', 'Inbound');
        result.currentDateTimePlus2 = System.Now().addYears(2);
        return JSON.serialize(result);

    }

    public class GetInfoForTaskWrapper {
        public DateTime currentDateTimePlus2;
        public String inboundId;
    }

    @AuraEnabled
	public static WorkOrder getFirstWOinCase(String caseId){
        CustomLogging.push('getFirstWOinCase', 'TS_RecordHeaderController');
        CustomLogging.pop();
		return [SELECT Id, Pricebook2Id FROM WorkOrder WHERE CaseId =:caseId LIMIT 1];
	}
    
    @AuraEnabled
	public static AddServiceWrapper queryAddService(String caseId, String prodId){
        CustomLogging.push('queryAddService', 'TS_RecordHeaderController');
		PricebookEntry getPbEntry = new PricebookEntry();
        WorkOrder getWo = [SELECT Id, Pricebook2Id FROM WorkOrder WHERE CaseId =:caseId LIMIT 1];
        
        if(!String.isEmpty(prodId) && getWo.Pricebook2Id != null){
            try{
                getPbEntry = [SELECT Id FROM PricebookEntry WHERE (Product2Id =: prodId AND Pricebook2Id =: getWo.Pricebook2Id) LIMIT 1];
            } catch (Exception e){
                System.debug(e);
                return new AddServiceWrapper(getWo, getPbEntry);
            }
        }
		CustomLogging.pop();
        return new AddServiceWrapper(getWo, getPbEntry);
	}
    
    @AuraEnabled
	public static String getObjectTypeOfRecord(String recordId){
        CustomLogging.push('getObjectTypeOfRecord', 'TS_RecordHeaderController');
        Id csId = recordId;
        CustomLogging.pop();
		return csId.getSObjectType().getDescribe().getName();    
	}
    
    public class AddServiceWrapper{

        @AuraEnabled public WorkOrder getFirstWOinCase;
        @AuraEnabled public PricebookEntry pbEntry;
       
        public AddServiceWrapper(WorkOrder getFirstWOinCase, PricebookEntry pbEntry){
            this.getFirstWOinCase = getFirstWOinCase;
            this.pbEntry = pbEntry;
        } 
    }
    
    @AuraEnabled
	public static String getCorrectSLADate(Case cs){
        CustomLogging.push('getCorrectSLADate', 'TS_RecordHeaderController');
        String strConvertedDate;
        if(cs.SLADate__c != null){
        	Datetime myDateTime = cs.SLADate__c;
            Datetime GMTDate = Datetime.newInstanceGmt(
                myDateTime.year(),
                myDateTime.month(),
                myDateTime.day(),
                myDateTime.hour(),
                myDateTime.minute(),
                myDateTime.second());
            
            strConvertedDate = GMTDate.format('dd-MM-yyyy HH:mm', ''); 
        }
        CustomLogging.pop();
		return strConvertedDate;          
	}
    
    @AuraEnabled
	public static Map<String,TS_PicklistEntryWrapper> getDependentValue(String objectName, String controllingField, String dependentField) {
        CustomLogging.push('getDependentValue', 'TS_RecordHeaderController');
        CustomLogging.pop();
		return TS_PicklistFieldHelper.getDependentOptionsImpl(objectName, controllingField, dependentField);
	}
    
    @AuraEnabled
	public static Map<String, List<String>> getPLvalueOption2(String objectName, String controllingField, String dependentField) {
        CustomLogging.push('getPLvalueOption2', 'TS_RecordHeaderController');
		Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
        Map<String, Schema.SObjectField> objFieldMap = objType.getDescribe().fields.getMap();
        
        Schema.DescribeFieldResult F = objFieldMap.get(controllingField).getDescribe();
        Schema.sObjectField T = F.getSObjectField();
        
        Schema.DescribeFieldResult F1 = objFieldMap.get(dependentField).getDescribe();
        Schema.sObjectField T1 = F1.getSObjectField();
        CustomLogging.pop();
        return TS_HL_FieldDescribeUtil.getDependentOptionsImpl(T1, T);
	}

    @AuraEnabled
    public static Map<String,TS_PicklistEntryWrapper> getPLvalueOption3(String objectName, String controllingField, String dependentField) {
        CustomLogging.push('getPLvalueOption2', 'TS_CloseTaskWOLIController');
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
        Map<String, Schema.SObjectField> objFieldMap = objType.getDescribe().fields.getMap();
        
        Schema.DescribeFieldResult F = objFieldMap.get(controllingField).getDescribe();
        Schema.sObjectField T = F.getSObjectField();
        
        Schema.DescribeFieldResult F1 = objFieldMap.get(dependentField).getDescribe();
        Schema.sObjectField T1 = F1.getSObjectField();
        CustomLogging.pop();
        return TS_HL_FieldDescribeUtil.getDependentOptionsImpl2(T1, T);
    }

    @AuraEnabled
    public static Map<String, String> getPicklistValuesMap(String objectName, String fieldAPI) {
        CustomLogging.push('getPicklistValuesMap', 'TS_RecordHeaderController');
        Map<String, String> labelValueMap = new Map<String, String>();
        Schema.DescribeSObjectResult sobjectType = Schema.getGlobalDescribe().get(objectName).getDescribe();
        Schema.DescribeFieldResult sObjectResult = sobjectType.fields.getMap().get(fieldAPI).getDescribe();
        List<Schema.PicklistEntry> pick_list_values = sObjectResult.getPickListValues();
        for (Schema.PicklistEntry a : pick_list_values) {
            labelValueMap.put(a.getValue(), a.getLabel());
        }

        //System.debug('labelValueMap');
        //System.debug(labelValueMap);
        
		CustomLogging.pop();
        return labelValueMap;
    }

	@AuraEnabled
    public static List<WorkOrderLineItem> getReqParts(String recordId){
        CustomLogging.push('getReqParts', 'TS_RecordHeaderController');
        List<WorkOrderLineItem> jobsList = new List<WorkOrderLineItem>();
        if(recordId != NULL){
            try{
                jobsList = [SELECT Id, Quantity, WorkOrderLineItemNumber__c, JDELineItemNumber__c, toLabel(WorkOrderType__c), WorkOrderLineItemType__c, PhysicalAsset__c, PhysicalAsset__r.Name, PricebookEntryId, PricebookEntry.Name, Status, ParentWorkOrderLineItemId, ParentWorkOrderLineItem.WorkOrderLineItemNumber__c 
                            FROM WorkOrderLineItem WHERE Case__c =: recordId AND WorkOrderLineItemType__c = 'RequiredSpareparts' AND Status = 'Open' AND PartsOrdered__c = false];
                
            } catch(exception e){
                System.debug(e.getMessage());
            }
        }
        CustomLogging.pop();
        return jobsList;
    }

    @AuraEnabled
    public static List<WorkOrderLineItem> getOpenTasks(String recordId){
        CustomLogging.push('getOpenTasks', 'TS_RecordHeaderController');
        Id taskId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Register Task').getRecordTypeId();
        
        List<WorkOrderLineItem> jobsList = new List<WorkOrderLineItem>();
        if(recordId != NULL){
            try{
                jobsList = [SELECT Id, Quantity, WorkOrderLineItemNumber__c, JDELineItemNumber__c, toLabel(WorkOrderType__c), WorkOrderLineItemType__c, PhysicalAsset__c, PhysicalAsset__r.Name, PricebookEntryId, PricebookEntry.Name, Status, ParentWorkOrderLineItemId, ParentWorkOrderLineItem.WorkOrderLineItemNumber__c 
                            FROM WorkOrderLineItem WHERE Case__c =: recordId AND RecordTypeId =: taskId AND Status = 'Open'];
                
            } catch(exception e){
                System.debug(e.getMessage());
            }
        }
        CustomLogging.pop();
        return jobsList;
    }

    @AuraEnabled
    public static List<WorkOrderLineItem> getScheduledTasks(String recordId, Boolean isRouteSales){
        CustomLogging.push('getScheduledTasks', 'TS_RecordHeaderController');
        List<String> scheduledStatus = new List<String>{'Scheduled', 'Dispatched', 'Received', 'Travelling', 'On Site','Start Work', 'Review Needed'};
        Id recType;

        List<WorkOrderLineItem> jobsList = new List<WorkOrderLineItem>();
        if(recordId != NULL){
            try{

                if(isRouteSales){
                    recType = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Routesales Task').getRecordTypeId();
                } else {
                    recType = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Register Task').getRecordTypeId();
                }

                jobsList = [SELECT Id, StartDate__c, Quantity, WorkOrderLineItemNumber__c, JDELineItemNumber__c, toLabel(WorkOrderType__c), WorkOrderLineItemType__c, PhysicalAsset__c, PhysicalAsset__r.Name, PricebookEntryId, PricebookEntry.Name, Status, ParentWorkOrderLineItemId, ParentWorkOrderLineItem.WorkOrderLineItemNumber__c 
                            FROM WorkOrderLineItem WHERE Case__c =: recordId AND RecordTypeId =: recType AND Status IN: scheduledStatus];
                
            } catch(exception e){
                System.debug(e.getMessage());
            }
        }
        CustomLogging.pop();
        return jobsList;
    }

    @AuraEnabled
    //XEN REYES Jan. 24, 2019
    public static List<WorkOrderLineItem> getScheduledAndOpenTasks(String recordId, Boolean isRouteSales){
        CustomLogging.push('getScheduledTasks', 'TS_RecordHeaderController');
        List<String> scheduledStatus = new List<String>{'Open', 'Scheduled', 'Dispatched', 'Received', 'Travelling', 'On Site','Start Work', 'Review Needed'};
        Id recType;

        List<WorkOrderLineItem> jobsList = new List<WorkOrderLineItem>();
        if(recordId != NULL){
            try{

                if(isRouteSales){
                    recType = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Routesales Task').getRecordTypeId();
                } else {
                    recType = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Register Task').getRecordTypeId();
                }

                jobsList = [SELECT Id, StartDate__c, Quantity, WorkOrderLineItemNumber__c, JDELineItemNumber__c, toLabel(WorkOrderType__c), WorkOrderLineItemType__c, PhysicalAsset__c, PhysicalAsset__r.Name, PricebookEntryId, PricebookEntry.Name, Status, ParentWorkOrderLineItemId, ParentWorkOrderLineItem.WorkOrderLineItemNumber__c 
                            FROM WorkOrderLineItem WHERE Case__c =: recordId AND RecordTypeId =: recType AND Status IN: scheduledStatus];
                
            } catch(exception e){
                System.debug(e.getMessage());
            }
        }
        CustomLogging.pop();
        return jobsList;
    }

 	@AuraEnabled
    public static String updateRequiredParts(List<String> woliIds){
        CustomLogging.push('updateRequiredParts', 'TS_RecordHeaderController');
        String result = 'SUCCESS';
        List<WorkOrderLineItem> woliListToUpdate = new List<WorkOrderLineItem>();
        
        if(!woliIds.isEmpty()){
            try{
				List<WorkOrderLineItem> woliList = [SELECT Id, Status FROM WorkOrderLineItem WHERE Id IN: woliIds];
                for(WorkOrderLineItem wo : woliList){
                    wo.PartsOrdered__c  = true;
                    woliListToUpdate.add(wo);
                }
                update woliListToUpdate;
				              
            } catch(exception e){
                System.debug(e.getMessage());
                result = e.getMessage();
                return result;
            }
        }
        CustomLogging.pop();
        return result;
    }

	@AuraEnabled
    public static String scheduleOpenTask(DateTime actualDate, DateTime actualEndDate, String executingEngineer, Boolean roundTrip, List<String> toUpdate){
        CustomLogging.push('scheduleOpenTask', 'TS_RecordHeaderController');
        String result = 'SUCCESS';
        List<WorkOrderLineItem> woliListToUpdate = new List<WorkOrderLineItem>();
        Id taskId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Register Task').getRecordTypeId();
        
        try{
            List<WorkOrderLineItem> woliList = [SELECT Id, Status, ExecutingEngineer__c, StartDate__c  FROM WorkOrderLineItem 
                                                WHERE RecordTypeId =: taskId AND Id IN: toUpdate];
            
            for(WorkOrderLineItem wo : woliList){
                wo.Status = 'Scheduled';
                wo.ExecutingEngineer__c = executingEngineer;
                wo.StartDate__c = actualDate;
                wo.EndDate__c = actualEndDate;
                wo.RoundTrip__c = roundTrip;
                
                woliListToUpdate.add(wo);
            }
            update woliListToUpdate;
            
        } catch(exception e){
            System.debug(e.getMessage());
            result = e.getMessage();
            return result;
        }
        CustomLogging.pop();
        return result;
    }

    @AuraEnabled
    public static String rescheduleApppointment(String caseId, List<String> toUpdate, DateTime earliestTime, DateTime latestTime){
        CustomLogging.push('rescheduleApppointment', 'TS_RecordHeaderController');
        String result = 'SUCCESS';
        List<WorkOrderLineItem> woliListToUpdate = new List<WorkOrderLineItem>();
        Id taskId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Register Task').getRecordTypeId();
        
        try{
            List<WorkOrderLineItem> woliList = [SELECT Id, Status, ExecutingEngineer__c, StartDate__c  FROM WorkOrderLineItem 
                                                WHERE Id IN: toUpdate];
            
            if(!woliList.isEmpty()){
                
                for(WorkOrderLineItem wo : woliList){
                    wo.Reschedule__c = true;
                    wo.EarliestAppointmentTime__c = earliestTime;
                    wo.LatestAppointmentTime__c = latestTime;
                    wo.OutsideSLA__c = true; //XEN REYES 10.31.2018
                    woliListToUpdate.add(wo);
                }
                update woliListToUpdate;
            }
            
        } catch(exception e){
            System.debug(e.getMessage());
            result = e.getMessage();
            return result;
        }
        CustomLogging.pop();
        return result;
    }

    @AuraEnabled
    public static String counters(String caseId){
        CustomLogging.push('counters', 'TS_RecordHeaderController');
        List<WorkOrderLineItem> countwoli = new List<WorkOrderLineItem>();
        List<Id> recTypeIds = new List<Id>();
        Map<String, Integer> statusCountMap = new Map<String, Integer>{};
        
        Id taskId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Register Task').getRecordTypeId();
        Id routeTaskId;
        
        
        try{

            if(Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().containsKey('Routesales Task')){
                routeTaskId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Routesales Task').getRecordTypeId();
                recTypeIds.add(routeTaskId);
            }

            recTypeIds.add(taskId);

            countwoli = [SELECT Id, Status, RecordTypeId FROM WorkOrderLineItem 
                        WHERE Case__c =: caseId AND (Status = 'Open' OR Status = 'Scheduled') AND RecordTypeId IN: recTypeIds];

            if(!countwoli.isEmpty()){
                for(WorkOrderLineItem wo : countwoli){
                    if(wo.RecordTypeId == taskId){
                        if(statusCountMap.containsKey(wo.Status)){
                            statusCountMap.put(wo.Status, statusCountMap.get(wo.Status) + 1);
                        } else {
                            statusCountMap.put(wo.Status, 1);
                        }
                    } else if(wo.RecordTypeId == routeTaskId){
                        if(statusCountMap.containsKey(wo.Status + 'Route')){
                            statusCountMap.put(wo.Status + 'Route', statusCountMap.get(wo.Status) + 1);
                        } else {
                            statusCountMap.put(wo.Status + 'Route', 1);
                        }
                    }
                    
                }
            }
        } catch(Exception e){
           System.debug(e.getMessage());
        }
        CustomLogging.pop();
        return JSON.serialize(statusCountMap);
    }

    @AuraEnabled
    public static List<WorkOrderLineItem> getWorkOrderLineItemSearch (String itemNumber){
        CustomLogging.push('getWorkOrderLineItemSearch', 'TS_RecordHeaderController');
        
        List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
        
        try{
            woliList = [SELECT Id, JDELineItemNumber__c, Status, toLabel(WorkOrderLineItemType__c), toLabel(WorkOrderType__c), Subject FROM WorkOrderLineItem 
                                                WHERE JDELineItemNumber__c =: itemNumber LIMIT 1];
            
        } catch(exception e){
            System.debug(e.getMessage());
            CustomLogging.debugException(e);
        }

        CustomLogging.pop();
        return woliList;
    }

    @AuraEnabled
    public static String executeTakeOwnership (String caseId, String ownerId, String status){
        CustomLogging.push('executeTakeOwnership', 'TS_RecordHeaderController');

        String retStr = 'SUCCESS';

        try{
            
            //CHECK IF THE CASE OWNER TYPE IS NOT QUEUE
            //XEN REYES DOO-5274 Feb 1, 2021
            if(caseId != null){
                List<Case> csList = [SELECT Id, Owner.Type, RecordType.Name FROM Case WHERE Id =: caseId LIMIT 1];
                if(!csList.isEmpty()){
                    Case csHolder = csList[0];
                    if(csHolder.RecordType.Name == 'Qualify Case' && csHolder.Owner.Type == 'User'){
                        retStr = 'Another user already took ownership to qualify. Please refresh your screen and check for further actions.';
                		return retStr;
                    }
                }                
            }
            
            Case CASE_VAR = new Case(Id = caseId, OwnerId = ownerId);
            if(status == 'New'){
                CASE_VAR.Status = 'Open';
            }
	
            update CASE_VAR;

        } catch(exception e){
            retStr = e.getMessage();
            System.debug(e.getMessage());
            CustomLogging.debugException(e);
        }

        CustomLogging.pop();
        return retStr;
    }

    @AuraEnabled
    public static String changeOwner (String caseId, String ownerId){
        CustomLogging.push('changeOwner', 'TS_RecordHeaderController');

        String retStr = 'SUCCESS';

        try{

            Case CASE_VAR = new Case(Id = caseId, OwnerId = ownerId);
            update CASE_VAR;

        } catch(exception e){
            retStr = e.getMessage();
            System.debug(e.getMessage());
            CustomLogging.debugException(e);
        }

        CustomLogging.pop();
        return retStr;
    }

    @AuraEnabled
    public static String getWeekNumber(String recordId) {
        CustomLogging.push('getWeekNumber', 'TS_RecordHeaderController');
        
        Integer retValue = 0;        
        if(recordId != null && recordId != ''){
            List<OperatingSchedule__c> opSched = [SELECT Id, Active__c, Start_Date__c FROM OperatingSchedule__c WHERE Id =: recordId LIMIT 1];
            if(!opSched.isEmpty()){
                if(opSched[0].Start_Date__c != null && opSched[0].Start_Date__c <= Date.today() && opSched[0].Active__c == true){
                    Date d1 = opSched[0].Start_Date__c.toStartOfWeek();
                    Date d2 = Date.today().toStartOfWeek();
                    Integer numberOfWeeks = d1.daysBetween(d2) / 7;
                    retValue = Math.mod(numberOfWeeks, 2) == 0 ? 1 : 2;
                }
            }
        }
        
        CustomLogging.pop();
        
        return String.valueOf(retValue);
    }

    @AuraEnabled
    public static String getTimeSLAController(String country) {
        CustomLogging.push('getTimeSLAController', 'TS_RecordHeaderController');
        
        CountrySetting__c csRet = new CountrySetting__c();
        if(country != null && country != ''){
            Id recTypeBusinessHours = Schema.SObjectType.CountrySetting__c.getRecordTypeInfosByName().get('Country Default Business Hours').getRecordTypeId();
            CountrySetting__c[] csList = [SELECT Id, 
                                            Business_Hours__r.MondayEndTime, Business_Hours__r.TuesdayEndTime, Business_Hours__r.WednesdayEndTime, Business_Hours__r.ThursdayEndTime, Business_Hours__r.FridayEndTime, Business_Hours__r.SaturdayEndTime, Business_Hours__r.SundayEndTime,
                                            Business_Hours__r.MondayStartTime, Business_Hours__r.TuesdayStartTime, Business_Hours__r.WednesdayStartTime, Business_Hours__r.ThursdayStartTime, Business_Hours__r.FridayStartTime, Business_Hours__r.SaturdayStartTime, Business_Hours__r.SundayStartTime 
                                            FROM CountrySetting__c WHERE Country__c =: country AND RecordTypeId =: recTypeBusinessHours AND Active__c = true];
            
            if(!csList.isEmpty()){
                csRet = csList[0];
            }
            
        }
        
        CustomLogging.pop();
        
        return JSON.serialize(csRet);
    }
}