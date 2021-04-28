public without sharing class TaskTriggerHandler implements ITriggerHandler{
    public static Boolean isTriggerDisabled = true;
    private static final User u = UserDAO.userInformation();
    Map<Id, Task> oldMap = new  Map<Id, Task>();
    
    private List<Task> filterToProcessTasks(List<Task> newList){
        List<Task> tasksToProcess = new List<Task>();

        for(Task t : newList){
            if((t.Touchpoint_Type__c != null && t.Task_Source__c != null) || t.CallObject != null){
                tasksToProcess.add(t);
            }
        }

        return tasksToProcess;
    }
    
    public void beforeInsert(List<Task> newListTask){
        List<Task> filteredToProcessTasks = filterToProcessTasks(newListTask);

        if(filteredToProcessTasks.size()>0){
            populateContactLookup(filteredToProcessTasks, oldMap);
            populateContact (filteredToProcessTasks, oldMap);
            stampAccountLifecycleSegment (filteredToProcessTasks);
            stapmSalesOrganizationfornonintegrationuser (filteredToProcessTasks);
            populateAssignedTo(filteredToProcessTasks, oldMap);
            populateAccountLookup (filteredToProcessTasks, oldMap);
            populateOpportunityLookup(filteredToProcessTasks, oldMap);
            populateCaseLookup(filteredToProcessTasks, oldMap);
            populateLeadLookup (filteredToProcessTasks, oldMap);
            populateAccountAddress(filteredToProcessTasks, oldMap);
            stampCTITasks (filteredToProcessTasks);
            StampAccountLifecycleSegmentAccountnamewhenrelatedtoopptyoraccloc(filteredToProcessTasks, oldMap);
            populatecontactcallistingredients(filteredToProcessTasks);
            validationforqueueanduser(filteredToProcessTasks, oldMap);
            stampTaskInProgressTimestamp(filteredToProcessTasks, oldMap);
        }
    } 
 
    public void beforeUpdate(List<Task> newListTask, Map<Id, SObject> newItems, List<Task> oldList, Map<Id, SObject> oldSobjectMap){
        List<Task> filteredToProcessTasks = filterToProcessTasks(newListTask);
        Map<Id, Task> oldMapTask = (Map<Id, Task>) oldSobjectMap;
        if(filteredToProcessTasks.size() > 0){
            if (SM_CheckRecursive.run == true) { 
                populateContactLookup(filteredToProcessTasks, oldMapTask);
                populateContact (filteredToProcessTasks, oldMapTask); 
                populateAssignedTo(filteredToProcessTasks, oldMapTask);
                populateAccountLookup (filteredToProcessTasks, oldMapTask);
                populateOpportunityLookup(filteredToProcessTasks, oldMapTask);
                populateCaseLookup(filteredToProcessTasks, oldMapTask);
                populateLeadLookup (filteredToProcessTasks, oldMapTask);
                populateAccountAddress(filteredToProcessTasks, oldMapTask);
                StampAccountLifecycleSegmentAccountnamewhenrelatedtoopptyoraccloc(filteredToProcessTasks, oldMapTask);
                validationforqueueanduser(filteredToProcessTasks, oldMapTask);
                stampTaskInProgressTimestamp(filteredToProcessTasks, oldMapTask);
            }
        }
    }
 
    public void beforeDelete(List<Task> oldList, Map<Id, SObject> oldItems){
        preventDeletion((List<Task>) oldList);
    }
 
    public void afterInsert(List<Task> newListTask, Map<Id, SObject> newItems){
        List<Task> filteredToProcessTasks = filterToProcessTasks(newListTask);

        if(filteredToProcessTasks.size() > 0){
            taskScoring(filteredToProcessTasks, oldMap);
            stampSLATask(filteredToProcessTasks, oldMap);
            createHistoryRecord(filteredToProcessTasks, oldMap);
            updateActivityCount(filteredToProcessTasks, oldMap); //Karen Hung 19.8.2020 DOO-4804 
            notifyHotLeadGroupfromTask(filteredToProcessTasks, oldMap);
            StampWhatTypeWhoType(filteredToProcessTasks, oldMap);
        }
    }
 
    public void afterUpdate(List<Task> newListTask , Map<Id, SObject> newItems, List<Task> oldList, Map<Id, SObject> oldSobjectMap){
        List<Task> filteredToProcessTasks = filterToProcessTasks(newListTask);
        Map<Id, Task> oldMapTask = (Map<Id, Task>) oldSobjectMap;
        if(filteredToProcessTasks.size() > 0){
            if (SM_CheckRecursive.run == true) {
                stampSLATask(filteredToProcessTasks, oldMapTask);
                taskScoring(filteredToProcessTasks, oldMapTask);
                createHistoryRecord(filteredToProcessTasks, oldMapTask);
                updateActivityCount(filteredToProcessTasks, oldMapTask); //Karen Hung 19.8.2020 DOO-4804 
                StampWhatTypeWhoType(filteredToProcessTasks, oldMapTask); 
            }
        }
        
    }
 
    public void afterDelete(List<Task> oldList, Map<Id, SObject> oldItems){

    }
 
    public void afterUndelete(List<Task> newList, Map<Id, SObject> newItems){
        
    }
    
    public Boolean IsDisabled() {
        if (TriggerSettings__c.getInstance().TaskTrigger__c) {
            isTriggerDisabled = false;
        } else {
            isTriggerDisabled = true;
        }
        
        return isTriggerDisabled;
    }

    public static void validationforqueueanduser(List<Task> newListTask,  Map<Id, Task> oldMapTask){
        CustomLogging.push('validationforqueueanduser', 'TaskTriggerHandler');
        try {
            
            for(Task t : newListTask){
                if (oldMapTask != null && !oldMapTask.isEmpty()){
                Task oldTask = (Task) oldMapTask.get(t.Id);
                    if (t.OwnerId != oldTask.OwnerId){
                        if (t.OwnerId != null && String.valueOf(t.OwnerId).left(3) == SM_Constants.queuePrefix && (u.Profile.Name != SM_Constants.SystemAdmin && u.Profile.Name != SM_Constants.JDEDigital && u.Profile.Name != SM_Constants.JDESAP && u.Profile.Name != SM_Constants.JDEMARKETING)) {
                            QueueGateKeepers__c gatekeeper = QueueGateKeepers__c.getInstance(t.OwnerId);
                            if (gatekeeper != null) {
                                if (u.Sales_Organization__c != gatekeeper.Sales_Org_ID__c){
                                    t.addError('Country of the Queue and your Sales Organization does not match, you can not add this to the queue');
                                }
                            }
                        }
                    }
                }
                else {
                    if (t.OwnerId != null && String.valueOf(t.OwnerId).left(3) == SM_Constants.queuePrefix) {
                        QueueGateKeepers__c gatekeeper = QueueGateKeepers__c.getInstance(t.OwnerId);
                        if (gatekeeper != null) {
                            if (u.Sales_Organization__c != gatekeeper.Sales_Org_ID__c && (u.Profile.Name != SM_Constants.SystemAdmin && u.Profile.Name != SM_Constants.JDEDigital && u.Profile.Name != SM_Constants.JDESAP && u.Profile.Name != SM_Constants.JDEMARKETING)){
                                t.addError('Country of the Queue and your Sales Organization does not match, you can not add this to the queue');
                            }
                        }
                    }
                }
            }
            
    
           
        } catch (Exception e) {
           CustomLogging.debugException(e);
           CustomLogging.pop();      
           System.debug(e.getMessage() + '\n' + e.getStackTraceString());
       }
       CustomLogging.pop();
    }
    
    public static void stampCTITasks (List<Task> newListTask){
        CustomLogging.push('stampCTITasks', 'TaskTriggerHandler');
        try{
            List<Task> TasksFromCTI = new List<Task>();
            for (Task t : newListTask){
                if (t.CallType != null && t.CallObject != null){
                    TasksFromCTI.add(t);
                }
            }

            if (!TasksFromCTI.isEmpty()) {
               SM_TaskUtil.stampCTITasks(TasksFromCTI); 
            } 
        } catch (Exception e) { 
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop();
    }
    
    public static void stapmSalesOrganizationfornonintegrationuser (List<Task> newListTask){
        CustomLogging.push('stapmSalesOrganizationfornonintegrationuser', 'TaskTriggerHandler');
        try {
            if (u.Profile.Name != Label.JDE_Integ_Digital && u.Profile.Name != Label.JDE_Integ_Sap && u.Profile.Name != Label.JDE_Integ_CTI && u.Profile.Name != Label.JDE_Integ_MC){
                for (task t : newListTask){
                    if (u.Sales_Organization__c != null && t.Sales_Organization__c == null){
                        t.Sales_Organization__c = u.Sales_Organization__c;
                    }
                }
            }
                
            
        } catch (Exception e) { 
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop();
    }
    
    public static void stampAccountLifecycleSegment (List<Task> newListTask) {
        CustomLogging.push('stampAccountLifecycleSegment', 'TaskTriggerHandler');
        try {
            List <Task> tasksmeetscriteriaforstamping = new List<Task>();
            for (Task t : newListTask){
                if (t.WhatId != null && t.Touchpoint_Type__c != 'NPS' && String.valueOf(t.WhatId).left(3) == SM_Constants.accountPrefix){
                    tasksmeetscriteriaforstamping.add(t);
                }
            }
            if (!tasksmeetscriteriaforstamping.isEmpty()){
                List <Task> processedTasks = SM_TaskUtil.stampAccountLifecycleSegment(tasksmeetscriteriaforstamping);
            }
            
        } catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop();
    }
    
    public static void populatecontactcallistingredients (List<Task> newListTask) {
        CustomLogging.push('populatecontactcallistingredients', 'TaskTriggerHandler');
        try {
            List <Task> tasksmeetscriteriaforstamping = new List<Task>();
                
            for (Task t : newListTask){
                if (t.WhatId != null && t.Touchpoint_Type__c == 'CALL LIST INGREDIENTS' && String.valueOf(t.WhatId).left(3) == SM_Constants.accountPrefix && u.Profile.Name == SM_Constants.SystemAdministrator){
                    tasksmeetscriteriaforstamping.add(t);
                }
            }
            if (!tasksmeetscriteriaforstamping.isEmpty()){
                List <Task> processedTasks = SM_TaskUtil.populatecontactcallistingredients(tasksmeetscriteriaforstamping);
            }
            
        } catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop();
    }
    
    public static void preventDeletion(List<Task> oldList) {
        CustomLogging.push('preventDeletion', 'TaskTriggerHandler');
        try {
          String UserID = UserInfo.getUserId(); 
          User currentUser = new User();
          if (Task.sObjectType.getDescribe().isDeletable()){
              currentUser = [Select Id, Name, Sales_Organization__c, Profile.Name FROM User WHERE ID = :UserID];

              Country_Super_Users__c csu = Country_Super_Users__c.getInstance(UserID);
              Map<String, String> countrySU = new Map<String, String>();
              List<Task> tasksfordeletion = new List<Task>();
              if (currentUser != null){
                  for(Task t : oldList){
                        if (csu != null){
                            if (currentUser.Id != csu.Name && currentUser.Sales_Organization__c != csu.Sales_Organization__c && currentUser.Profile.Name != SM_Constants.SystemAdmin) {
                                t.addError(SM_Constants.InsufficientDeletion);
                            } else if (currentUser.Profile.Name == SM_Constants.SystemAdmin || currentUser.Id == csu.Name && currentUser.Sales_Organization__c == csu.Sales_Organization__c) {
                                tasksfordeletion.add(t);
                            }
                        }
                        else {
                            if (currentUser.Profile.Name != SM_Constants.SystemAdmin){
                                t.addError(SM_Constants.InsufficientDeletion);
                            }
                            else {
                                tasksfordeletion.add(t);
                            }
                        }
                        
                  }
                  if (!tasksfordeletion.isEmpty()){
                      List<Task> processedfordeletion = deleteRelatedOT(tasksfordeletion);
                  }
                   
              }
                   
            }
        
        } catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop();
    }
    
    public static List<Task> deleteRelatedOT(List<Task> tasks) {
        CustomLogging.push('deleteRelatedOT', 'TaskTriggerHandler');
        try {
            Set<ID> operationaltaskIDs = new Set<ID>();
            if(Operational_Tasks__c.sObjectType.getDescribe().isDeletable()){
                List<Task> deleterelatedoperationaltask = new List<Task>(tasks);
            
                if (!deleterelatedoperationaltask.isEmpty()) {
                    List<Operational_Tasks__c> otRec = new List<Operational_Tasks__c> ();
                    
                    for (Task t : deleterelatedoperationaltask){
                         operationaltaskIDs.add(t.Operational_Tasks__c);
                    }
                    otRec = [Select Id, Name FROM Operational_Tasks__c WHERE Id IN :operationaltaskIDs];
                    
                    if(otRec != Null){
                        
                        delete otRec;
                        
                    }
                }
            }
            return tasks;
        } catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
            return null;
        }
    }
    
    public static void populateAccountLookup (List<Task> newListTask, Map<Id, Task> oldMapTask){
        CustomLogging.push('populateAccountLookup', 'TaskTriggerHandler');
        try{
            List<Task> filteredTasks = new List<Task>();
            
            for (task t : newListTask){
                if (filterTasksWithChangedWhatIdOrNew(t, oldMapTask)){
                    if(t.WhatId != null && String.valueOf(t.WhatId).left(3) == SM_Constants.accountPrefix){
                        filteredTasks.add(t);
                    }
                }
            }
            List<Task> processedTasks = new List<Task>();
            processedTasks = SM_TaskUtil.populateAccountLookUponTask(filteredTasks);

        } catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop();
    }
    
    public static void populateOpportunityLookup (List<Task> newListTask, Map<Id, Task> oldMapTask){
        CustomLogging.push('populateOpportunityLookup', 'TaskTriggerHandler');
        try{
            List<Task> filteredTasks = new List<Task>();
            
            for (task t : newListTask){
                if (filterTasksWithChangedWhatIdOrNew(t, oldMapTask)){
                    if(t.WhatId != null && String.valueOf(t.WhatId).left(3) == SM_Constants.oppPrefix){
                        filteredTasks.add(t);
                    }
                }
            }
            List<Task> processedTasks = new List<Task>();
            processedTasks = SM_TaskUtil.populateOpportunityLookUponTask(filteredTasks);

        } catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop();
    }
    
    public static void populateCaseLookup (List<Task> newListTask, Map<Id, Task> oldMapTask){
        CustomLogging.push('populateCaseLookup', 'TaskTriggerHandler');
        try{
            List<Task> filteredTasks = new List<Task>();
            
            for (task t : newListTask){
                if (filterTasksWithChangedWhatIdOrNew(t, oldMapTask)){
                    if(t.WhatId != null && String.valueOf(t.WhatId).left(3) == SM_Constants.casePrefix){
                        filteredTasks.add(t);
                    }
                }
            }
            List<Task> processedTasks = new List<Task>();
            processedTasks = SM_TaskUtil.populateCaseLookUponTask(filteredTasks);


        } catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop();
    }
    
    public static void populateLeadLookup (List<Task> newListTask, Map<Id, Task> oldMapTask){
        CustomLogging.push('populateLeadLookup', 'TaskTriggerHandler');
        try{
            List<Task> filteredTasks = new List<Task>();
            
            for (task t : newListTask){
                if (filterTasksWithChangedWhoIdOrNew(t, oldMapTask)){
                    if(t.WhoId != null && String.valueOf(t.WhoId).left(3) == SM_Constants.leadPrefix){
                        filteredTasks.add(t);
                    }
                }
            }
            List<Task> processedTasks = new List<Task>();
            processedTasks = SM_TaskUtil.populateLeadLookUponTask(filteredTasks);
        } catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop();
    }
    
    public static void populateContactLookup (List<Task> newListTask, Map<Id, Task> oldMapTask){
        CustomLogging.push('populateContactLookup', 'TaskTriggerHandler');
        try{
            List<Task> filteredTasks = new List<Task>();
            
            for (task t : newListTask){
                if (filterTasksWithChangedWhoIdOrNew(t, oldMapTask)){
                    if(t.WhoId != null && String.valueOf(t.WhoId).left(3) == SM_Constants.contactPrefix){
                        filteredTasks.add(t);
                    }
                }
            }
            List<Task> processedTasks = new List<Task>();
            processedTasks = SM_TaskUtil.populateContactLookUponTask(filteredTasks);

            
        
        } catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop();
    }
    
    public static void populateContact (List<Task> newListTask,  Map<Id, Task> oldMapTask){
        CustomLogging.push('populateContact', 'TaskTriggerHandler');
        try {
            List<Task> tasksFilteredForSettingCommercialContact = new List<Task>();
            for(Task t : newListTask){
                if (filterTasksWithChangedWhatIdOrNew(t, oldMapTask)){
                    if(t.CLoned__c == False && 
                            (t.Touchpoint_Type__c == 'NEW STARTED COMPANY' || t.Touchpoint_Type__c == 'COMPANY CHANGE' || t.Touchpoint_Type__c == 'PROSPECT LIST'
                                    || t.Touchpoint_Type__c == 'END WARR' ||  t.Touchpoint_Type__c == 'MPV' || t.Touchpoint_Type__c == 'WARM WELCOME FOLL UP'
                                    || (t.Task_Source__c == 'CTI' && t.Type == 'Call')
                            )
                        ){
                        tasksFilteredForSettingCommercialContact.add(t);
                    }
                }
                
            }

            //  PASS THOSE CONTACTS TO THE UTIL CLASS TO RUN THE CONTACT LOOKUP CODE IN BULK
            if (!tasksFilteredForSettingCommercialContact.isEmpty()){
                List<Task> processedTasks = SM_TaskUtil.setMainCommercialContact(tasksFilteredForSettingCommercialContact);
            }
            

        } catch (Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop();
    }
    //  NOTE THAT THIS METHOD IS RE-USABLE
    private static Boolean filterTasksWithChangedWhatIdOrNew(Task t, Map<Id, Task> oldMapTask){
        Task oldtask;
        Boolean taskChangeWhatId = false;

        if (!oldMapTask.isEmpty()){
            oldTask = oldMapTask.get(t.Id);
            if (t.WhatId != oldTask.WhatId){
                taskChangeWhatId = true;
            }
        }
        else {
            if (t.WhatId != null){
                taskChangeWhatId =true;
            }
        }

        return taskChangeWhatId;
    }
    
     private static Boolean filterTasksrelatedtooppty(Task t, Map<Id, Task> oldMapTask){
         Task oldTask;
         Boolean taskrelatedtooppty = false;
         if (!oldMapTask.isEmpty()){
            oldTask = oldMapTask.get(t.Id);
            if (t.WhatId != oldTask.WhatId || t.Touchpoint_Type__c != oldTask.Touchpoint_Type__c) {
                taskrelatedtooppty = true;
            }
         }
         else {
             if (t.WhatId != null || t.Touchpoint_Type__c != null){
                taskrelatedtooppty = true;
             }
         }

         return taskrelatedtooppty;
    }

    private static Boolean filterTasksWithChangedWhoIdOrNew(Task t, Map<Id, Task> oldMapTask){
        Task oldtask;
        Boolean changedwhoId = false;
        if (!oldMapTask.isEmpty()){
            oldtask = oldMaptask.get(t.Id);
            if (t.WhoId != oldTask.WhoId){
                changedwhoId = true;
            }
        }
        else {
            if (t.WhoId != null){
                changedwhoId = true;
            }
        }

        return changedwhoId;
    }
    
    private static boolean filterTasksWithChangedStatusOrNew(Task t, Map<Id, Task> oldMapTask){
        Task oldtask;
        Boolean changedstatus = false;
        if (!oldMapTask.isEmpty()){
            oldtask = oldMaptask.get(t.Id);
            if (t.Status != oldTask.Status){
                changedstatus = true;
            }
        }
        else {
            if (t.Status != null){
                changedstatus = true;
            }
        }

        return changedstatus;
    }
    
    private static Boolean filterTasksWithChangedWhoIdOrWhatIdorNew(Task t, Map<Id, Task> oldMapTask){
        Task oldtask;
        Boolean changedWhoIdorWhatId = false;

        if (!oldMapTask.isEmpty()){
            oldtask = oldMapTask.get(t.Id);
            if ((t.WhoId != oldTask.WhoId || t.WhatId != oldTask.WhatId) && (t.WhoId != null || t.WhatId != null)){
                changedWhoIdorWhatId = true;
            }
        }
        else {
            if (t.WhoId != null || t.WhatId != null){
                changedWhoIdorWhatId = true;
            }
        }

        return changedWhoIdorWhatId;
    }
    
    private static Boolean filterTasksforPopulateAssignedTo(Task t, Map<Id, Task> oldMapTask){
        Task oldTask;
        Boolean changedforAssignedto = false;

        if (!oldMapTask.isEmpty()){
            oldTask = oldMapTask.get(t.Id);
            if ((t.WhoId != oldTask.WhoId || t.WhatId != oldTask.WhatId) || t.Touchpoint_Type__c != oldTask.Touchpoint_Type__c){
                changedforAssignedto = true;
            }
        }
        else {
            if ((t.WhoId != null || t.WhatId != null) || t.Touchpoint_Type__c != null){
                changedforAssignedto = true;
            }
        }

        return changedforAssignedto;
    }
    
    private static Boolean filterchangeTaskScoring(Task t, Map<Id, Task> oldMapTask){
        Task oldTask;
        Boolean changedTaskScoring = false;
        
        if (!oldMapTask.isEmpty()){
            oldTask = oldMapTask.get(t.Id);
            if (t.Touchpoint_Type__c != oldTask.Touchpoint_Type__c || t.WhatId != oldTask.WhatId || t.WhoId != oldTask.WhoId){
                changedTaskScoring = true;
            }
        }
        else {
            if (t.Touchpoint_Type__c != null || t.WhatId != null || t.WhoId != null){
                changedTaskScoring = true;
            }
        }

        return changedTaskScoring;
    }
    
    private static Boolean SLATouchpointTypeChange(Task t, Map<Id, Task> oldMapTask){
        Task oldTask;
        Boolean changedTouchpointType = false;
        
        if (!oldMapTask.isEmpty()){
            oldTask = oldMapTask.get(t.Id);
            if (t.Touchpoint_Type__c != oldTask.Touchpoint_Type__c){
                changedTouchpointType = true;
            }
        }
        else {
            if (t.Touchpoint_Type__c != null){
                changedTouchpointType = true;
            }
        }

        return changedTouchpointType;
    }
    
    public static void stampSLATask (List<Task> newListTask, Map<Id, Task> oldMapTask) {
        CustomLogging.push('stampSLATask', 'TaskTriggerHandler');
        try {
            List<Task> recordsforSLAstamp = new List<Task>();
            for (Task t : newListTask){
                if (SLATouchpointTypeChange(t, oldMapTask)){
                    if (t.Touchpoint_Type__c != null){
                        recordsforSLAstamp.add(t);
                    }
                }
            }
            List<Task> processedTasks = new List<Task>();
            processedTasks = SM_TaskUtil.stampSLATask(recordsforSLAstamp);
            if (!processedTasks.isEmpty()){
                update processedTasks;
            }
        } catch (Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop();
    }
    
    public static void taskScoring (List<Task> newListTask, Map<Id, Task> oldMapTask) {
        CustomLogging.push('taskScoring', 'TaskTriggerHandler');
        try {
            List <Task> recordstoScore = new List<Task>();
            
            for (Task t : newListTask){
                if (filterchangeTaskScoring(t, oldMapTask)){
                    if (t.Touchpoint_Type__c != null){
                        recordstoScore.add(t);
                    }
                }
            }

            List<Task> processedTasks = new List<Task>();
            processedTasks = SM_TaskUtil.taskScoring(recordstoScore);

            if(!processedTasks.isEmpty()){
                update processedTasks;    
            }
        } catch (Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop();
    }

    public static void populateAssignedTo (List<Task> newListTask, Map<Id, Task> oldMapTask){
        CustomLogging.push('populateAssignedTo', 'TaskTriggerHandler');
        try {
            List<Task> tasksmeetscriteriaforownerchange = new List<Task>();
            for(Task t : newListTask){
                if (filterTasksforPopulateAssignedTo(t, oldMapTask)){
                    if ((t.WhatID != null && (String.valueOf(t.WhatId).left(3) == SM_Constants.accountPrefix || String.valueOf(t.WhatId).left(3) == Label.Account_Location_Prefix) || t.WhoId != null && (String.valueOf(t.WhoId).left(3) == SM_Constants.contactPrefix 
                    || String.valueOf(t.WhoId).left(3)  == SM_Constants.leadPrefix)) && t.Sales_Organization__c != null && (u.Profile.Name == 'JDE-Integration-Digital' || u.Profile.Name == SM_Constants.SystemAdministrator
                    || u.Profile.Name == 'JDE-Integration-Marketing Cloud') && t.SAP_HANA_Queue_Task__c == true){
                    tasksmeetscriteriaforownerchange.add(t);
                    }
                }
            }
            if (!tasksmeetscriteriaforownerchange.isEmpty()){
                List <Task> processedTasks = SM_TaskUtil.populateAssigned(tasksmeetscriteriaforownerchange);
            }
            
        
        } catch (Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop();                                     
    }
    
     public static void StampWhatTypeWhoType (List<Task> newListTask, Map<Id, Task> oldMapTask){
         CustomLogging.push('StampWhatTypeWhoType', 'TaskTriggerHandler');
         try{
            List<Task> taskmeetscriteriafortypestamp = new List<Task>();
            for (Task t : newListTask){
                if (filterTasksWithChangedWhoIdOrWhatIdorNew(t, oldMapTask)){
                    taskmeetscriteriafortypestamp.add(t);
                }
            }
            List<Task> processedTasks = new List<Task>();
            processedTasks = SM_TaskUtil.StampWhatTypeWhoType(taskmeetscriteriafortypestamp);
            if(!processedTasks.isEmpty()){
                update processedTasks;    
            }
         }catch (Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }   
        CustomLogging.pop();
    }
    
    public static void StampAccountLifecycleSegmentAccountnamewhenrelatedtoopptyoraccloc (List<Task> newListTask, Map<Id, Task> oldMapTask){
        CustomLogging.push('StampAccountLifecycleSegmentAccountnamewhenrelatedtoopptyoraccloc', 'TaskTriggerHandler');
        try{
            List<Task> taskmeetscriteriatostamp = new List<Task>();
            for (Task t : newListTask){
                if (filterTasksrelatedtooppty(t, oldMapTask)){
                    if (t.WhatId != null && (String.valueOf(t.WhatId).left(3) == SM_Constants.oppPrefix || String.valueOf(t.WhatId).left(3) == Label.Account_Location_Prefix)){
                        taskmeetscriteriatostamp.add(t);
                    }
                }
            }
            List<Task> processedTask = new List<Task>();
            if (!taskmeetscriteriatostamp.isEmpty()){
                processedTask = SM_TaskUtil.StampAccountLifecycleSegmentAccountnamewhenrelatedtoopptyoraccloc(taskmeetscriteriatostamp);
            }

        }catch (Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop();
    }
    
    public Boolean validateIfHasChange(Task newTask, Task oldTask) {
        Boolean result = false;
        for(Schema.FieldSetMember fields :Schema.SObjectType.Task.fieldSets.getMap().get('HistoryFieldSet').getFields()) {
			if(newTask.get(fields.getFieldPath()) != oldTask.get(fields.getFieldPath())) {
                result = true;
                break;
            }                
        }   
        return result;
    }
    
    public void createHistoryRecord(List<Task> newListTask, Map<Id, Task> oldMapTask) {
        CustomLogging.push('createHistoryRecord', 'TaskTriggerHandler');
        try{  
            Map<String, Schema.SObjectField> schemaTaskHistoryMap = Schema.SObjectType.Task_History__c.fields.getMap();
            Map<String, Schema.SObjectField> schemaTaskMap = Schema.SObjectType.Task.fields.getMap();
            Set<Schema.SObjectField> schemaTaskHistoryFieldSet = new Set<Schema.SObjectField>();
            Set<Schema.SObjectField> schemaTaskFieldSet = new Set<Schema.SObjectField>();
            Set<String> schemaTaskHistoryFieldSetString = new Set<String>();
            Set<String> schemaTaskFieldSetString = new Set<String>();
            List<SObject> sourceList = new List<SObject>();
            List<String> updatedTaskList = new List<String>();
            List<Task_History__c> taskHistoryToInsertList = new List<Task_History__c>();
            
            //GET ALL FIELD NAMES OF TASK HISTORY OBJECT
            for(Schema.SObjectField schm : schemaTaskHistoryMap.values()){
                schemaTaskHistoryFieldSet.add(schm);
                schemaTaskHistoryFieldSetString.add(String.valueOf(schm));
            }
            
            //GET ALL FIELD NAMES OF TASK OBJECT
            for(Schema.SObjectField schm : schemaTaskMap.values()){
                schemaTaskFieldSet.add(schm);
                schemaTaskFieldSetString.add(String.valueOf(schm));
            }
            
            //CHECK IF INSERT OR UPDATE
            if(!oldMapTask.isEmpty()){
                
                //GET ALL UPDATED TASK
                for(Task t : newListTask){
                    if(validateIfHasChange(t, oldMapTask.get(t.Id))){
                        updatedTaskList.add(t.Id);
                    }
                }
                
                //UPDATE LATEST TASK HISTORY RECORD
                if(!updatedTaskList.isEmpty()){
                    List<Task_History__c> historyToUpdateList = [SELECT Id, Valid_To__c, Task_Id__c FROM Task_History__c 
                                                                 WHERE Task_Id__c IN: updatedTaskList AND Valid_To__c = null];

                    if(!historyToUpdateList.isEmpty()){
                        for(Task_History__c his : historyToUpdateList){
                            his.Valid_To__c = DateTime.now();
                            taskHistoryToInsertList.add(his);
                        }
                    }
                    
                    //CREATE NEW TASK HISTORY RECORD
                    for(Task t: newListTask){
                        Task_History__c history = new Task_History__c();
                        
                        //ITERATE ON  TASK HISTORY OBJECT FIELDS
                        for(Schema.SObjectField field : schemaTaskHistoryFieldSet){
                            Schema.DescribeFieldResult dfr = field.getDescribe();
                            if (schemaTaskHistoryFieldSetString.contains('Status__c')){
                                history.put('Status__c', t.get(String.valueOf('Status')));
                            }
                            if (schemaTaskHistoryFieldSetString.contains('Type__c')){
                                history.put('Type__c', t.get(String.valueOf('Type')));
                            }
                            if(dfr.isUpdateable() && schemaTaskFieldSetString.contains(String.valueOf(field))){
                                history.put(String.valueOf(field), t.get(String.valueOf(field)));
                                System.debug(String.valueOf(field) + ' ' + t.get(String.valueOf(field)));
                            }
                        }
                        
                        history.Task_Id__c = t.Id;
                        history.Task_Name__c = t.Subject;
                        taskHistoryToInsertList.add(history);
                    }					
                    
                    if(!taskHistoryToInsertList.isEmpty()){
                        upsert taskHistoryToInsertList;
                    }
                }
            } else {
                //CREATE NEW TASK HISTORY RECORD ON CREATE/INSERT
                for(Task t : newListTask){
                    Task_History__c history = new Task_History__c();
                    
                    //ITERATE ON  TASK HISTORY OBJECT FIELDS
                    for(Schema.SObjectField field : schemaTaskHistoryFieldSet){
                        Schema.DescribeFieldResult dfr = field.getDescribe();
                        if (schemaTaskHistoryFieldSetString.contains('Status__c')){
                            history.put('Status__c', t.get(String.valueOf('Status')));
                        }
                        if (schemaTaskHistoryFieldSetString.contains('Type__c')){
                            history.put('Type__c', t.get(String.valueOf('Type')));
                        }        
                        if(dfr.isUpdateable() && schemaTaskFieldSetString.contains(String.valueOf(field))){
                            history.put(String.valueOf(field), t.get(String.valueOf(field)));
                        }
                    }
                    
                    history.Task_Id__c = t.Id;
                    history.Task_Name__c = t.Subject;
                    taskHistoryToInsertList.add(history);
                }
                
                if(!taskHistoryToInsertList.isEmpty()){
                    insert taskHistoryToInsertList;
                } 
            }   
        }catch (Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop();    
    }

    /*Karen Hung 19.8.2020 DOO-4804 
    * Method to execute logic from TS_Number of Activities process builder & TS_ModifyCountonCase flow
    */
    public void updateActivityCount(List<Task> newListTask, Map<Id, Task> oldMapTask){
        CustomLogging.push('updateActivityCount', 'TaskTriggerHandler');
        try{
            List<Task> taskmeetscriteriaforcountupdate = new List<Task>();
            Map<String,Integer> caseNumMap = new Map<String,Integer>();

            for (Task t : newListTask){
                if(t.WhatID != null && t.Task_Source__c != 'CTI' && t.Type == 'Case' &&
                    ((oldMapTask.isEmpty() && t.Status == 'Open') || //NEW AND OPEN TASK SCENARIO
                    (!oldMapTask.isEmpty() && oldMapTask.containsKey(t.Id) && !oldMapTask.get(t.Id).Status.contains('Completed') && t.Status.contains('Completed')) || //TASK CLOSURE
                    (!oldMapTask.isEmpty() && oldMapTask.containsKey(t.Id) && oldMapTask.get(t.Id).Status == 'Completed Effective' && t.Status == 'Open'))){ //TASK REOPEN
                        if(t.Status == 'Open'){
                            caseNumMap.put(t.WhatID, 1);
                        }else if(t.Status.contains('Completed')){
                            caseNumMap.put(t.WhatID, -1);
                        }
                    
                        taskmeetscriteriaforcountupdate.add(t); 
                }
            }

            if(!taskmeetscriteriaforcountupdate.isEmpty()){
                List<Task> processedTasks = new List<Task>();
                processedTasks = SM_TaskUtil.updateCountOnCase(taskmeetscriteriaforcountupdate,caseNumMap);
                if(!processedTasks.isEmpty()){
                    update processedTasks;    
                }
            }

            SM_CheckRecursive.run = false;
        }catch (Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }   
        CustomLogging.pop();
    }
    
    private static Boolean checkAddress(Task t, Map<Id, Task> oldMapTask){
        Task oldTask;
        Boolean addressChange = false;
        if (!oldMapTask.isEmpty()){
            oldTask = oldMapTask.get(t.Id);
            if((t.WhatId != oldTask.WhatId && (String.valueOf(t.WhatId).left(3) == SM_Constants.accountPrefix || String.valueOf(t.WhatId).left(3) == SM_Constants.oppPrefix || String.valueOf(t.WhatId).left(3) == SM_Constants.casePrefix)) || (t.WhoId != oldTask.WhoId && (String.valueOf(t.WhoId).left(3) == SM_Constants.leadPrefix || String.valueOf(t.WhoId).left(3) == SM_Constants.contactPrefix))) {
                addressChange = true;
            }
        }
        else {
            if((t.WhatId != Null && (String.valueOf(t.WhatId).left(3) == SM_Constants.accountPrefix || String.valueOf(t.WhatId).left(3) == SM_Constants.oppPrefix || String.valueOf(t.WhatId).left(3) == SM_Constants.casePrefix)) || (t.WhoId != Null && (String.valueOf(t.WhoId).left(3) == SM_Constants.leadPrefix || String.valueOf(t.WhoId).left(3) == SM_Constants.contactPrefix))) {
                addressChange = true;
            }
        }

        return addressChange;
    }
    
    /** Catherine Aragon 28-08-2020 DOS-1989
    *** Method that stamp account address based on related to task (Opportunity, Account, Case, Lead and Contact)
    **/
    private static void populateAccountAddress(List<Task> newListTask, Map<Id, Task> oldMapTask) {
       CustomLogging.push('populateAccountAddress', 'TaskTriggerHandler');
       try{ 
           List<Task> taskToChange = new List<Task>();
           for(Task t : newListTask) {
               if(checkAddress(t, oldMapTask)) {
					taskToChange.add(t);                   
               }
           }
           
           if(!taskToChange.isEmpty()) {
               SM_TaskUtil.populateAccountAddress(taskToChange);
           }
       }catch (Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }   
        CustomLogging.pop();
    }
    
    // Glenn Serrano 10/28/2020 DOS-2128
    // Method to Show Chatter Notification of a task related to a hot lead.
   
	private static void notifyHotLeadGroupfromTask(List<Task> newListTask, Map<Id, Task> oldMapTask) {
       CustomLogging.push('notifyHotLeadGroupfromTask', 'TaskTriggerHandler');
       try{ 
           Map<String, Queue_Lead_Tasks__mdt> getqueueleadval = SM_GetMetadata.getqueueleadtasks(); 
           List<Task> taskswithwhoId = new List<Task>();
           for(Task t : newListTask) {
               if (getqueueleadval.containsKey(t.Sales_Organization__c + t.Touchpoint_Type__c)) {
                   if (getqueueleadval.get(t.Sales_Organization__c + t.Touchpoint_Type__c).Chatter_Group_ID__c != null){
                       taskswithwhoId.add(t);
                   }
               }
           }
           
           if(!taskswithwhoId.isEmpty()) {
               SM_TaskUtil.notifyHotLeadGroupfromTask(taskswithwhoId);
           }
           SM_CheckRecursive.run = false;
       }catch (Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }   
        CustomLogging.pop();
    }
    
    // Glenn Serrano 12/01/2020 DOS-1940	
    // Ability to track time to follow up on SQL; Task Status in Progress
   
	public void stampTaskInProgressTimestamp(List<Task> newListTask, Map<Id, Task> oldMapTask) {
       CustomLogging.push('stampTaskInProgressTimestamp', 'TaskTriggerHandler');
       try{ 
           List<Task> taskswithchangeonstatus = new List<Task>();
           for(Task t : newListTask) {
               if (filterTasksWithChangedStatusOrNew(t, oldMapTask) && t.Task_In_Progress_Timestamp__c == null) {
                   taskswithchangeonstatus.add(t);
               }
           }
           
           if(!taskswithchangeonstatus.isEmpty()) {
               SM_TaskUtil.stampTaskInProgressTimestamp(taskswithchangeonstatus);
           }
       }catch (Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }   
        CustomLogging.pop();
    }
}