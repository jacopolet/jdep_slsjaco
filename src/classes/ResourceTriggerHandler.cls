/**
* @author        Paul Aguiling
* @date          7.04.2018           
* @description   Class responsible for the trigger business logic of Resource object
* @revision(s)   
*/
public without sharing class ResourceTriggerHandler implements ITriggerHandler {

    public static Boolean isTriggerDisabled = true;
    public static Boolean hasException = false;
    //private static Map<Id, Resource__c> extResource_map = null;
    
    public void BeforeInsert(List<SObject> newItems) {
        predefinedUserProfile(newItems);
    }
    
    public void BeforeUpdate(List<SObject> newList, Map<Id, SObject> newMapItems, List<SObject> oldList, Map<Id, SObject> oldMapItems) {  
        validateFields(newList, newMapItems, oldMapItems);
    }
    
    public void BeforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems){
        
    }
    
    public void AfterInsert(List<SObject> newList, Map<Id, SObject> newMapItems){
        createUserWithIntegLogs(newList, null);
        permissionSetUpdate(newList, null);
    }
    
    public void AfterUpdate(List<SObject> newList , Map<Id, SObject> newMapItems, List<SObject> oldList, Map<Id, SObject> oldMapItems){
        createUserWithIntegLogs(newList, oldMapItems);
        permissionSetUpdate(newList, oldMapItems);
        deactivateUser(newList, oldMapItems);
    }
    
    public void AfterDelete(List<SObject> oldList, Map<Id, SObject> oldMapItems){
        
    }
    
    public void AfterUndelete(List<SObject> newList, Map<Id, SObject> newMapItems){
        
    }
    
    public Boolean IsDisabled() {
        if (TriggerSettings__c.getInstance().ResourceTrigger__c) {
            return false;
        } else {
            return isTriggerDisabled;
        }
    }

    /**
    * @author         Paul Aguiling
    * @date           07.05.2018
    * @description    Method responsible for throwing an exception
    * @revision(s)
    */ 
    public class TS_ResourceTriggerHandlerException extends Exception {}

    /**
    * @author        Paul Jarred Aguiling
    * @date          7.6.2018           
    * @description   Method responsible for getting additional information on each resource (as by
    *                default fields on related records are not accessible). Kindly reuse the method when querying 
    *                RESOURCE records for 2nd or 3rd level fields.
    * @revision(s)   
    */ 
    //public Map<Id, Resource__c> getExtResourceMap(Set<Id> resourceIds) {
    //    CustomLogging.push('getExtResourceMap', 'ResourceTriggerHandler');
    //    Map<Id, Resource__c> extResourceMap = new Map<Id, Resource__c>();
        
    //    //Only perform the following query if a set of IDs is provided
    //    if (resourceIds != null && !resourceIds.isEmpty()) {
    //        //This query is restrictive enough not to breach the governor limits
    //        extResourceMap = new Map<Id, Resource__c>(
    //            [SELECT Id,
    //                  RelatedContact__r.AccountId
    //             FROM Resource__c             
    //             WHERE Id IN :resourceIds
    //            ]);
    //    }
        
    //    CustomLogging.pop();
    //    return extResourceMap;
    //}  

    /**
    * @author        Paul Jarred Aguiling
    * @date          06.27.2018           
    * @description   [KTS-1931]: Method used to create portal user and integration log for resource record
    * @revision(s)
    */
    public void createUserWithIntegLogs(List<SObject> newList, Map<Id, SObject> oldMapItems) {
        CustomLogging.push('createUserWithIntegLogs', 'ResourceTriggerHandler');
        List<Integration_Log__c> integLogList = new List<Integration_Log__c>();
        //Map<Id, User> userMap = new Map<Id, User>(); 
        Set<Id> resList = new Set<Id>();
        Map<String, Id> map_profile = getProfile();

        System.debug('XEN 8/24 ' + newList);

        //Insert Scenario
        if (oldMapItems == null) {
            //Iterate list of resource (USER) records
            for (Resource__c rsrce : (List<Resource__c>) newList) {
                //Check if the field active user is changed to TRUE and the field "Requires Click User" is set to TRUE
                //Then create integration log.
                if (rsrce.ActiveUser__c) {

                    if(rsrce.RequiresClickUser__c){
                        //Create mapping for integration log specific to user creation
                        Integration_Log__c integLog = new Integration_Log__c();
                        integLog.Object_Id__c = rsrce.Id;
                        integLog.Object__c = TS_Constants.CLICK_USERCREATE;
                        integLog.Integration_Status__c = INT_Constants.INITIAL;
                        integLog.Triggered_Timestamp__c = Datetime.now();
                        integLogList.add(integLog);
                    }
                    
                    if (rsrce.RelatedUser__c == null) {
                        resList.add(rsrce.Id);
                    }
                }
            }

        //Update Scenario        
        } else {
            //Iterate list of resource (USER) records
            for (Resource__c rsrce : (List<Resource__c>) newList) {
                Resource__c oldRes = (Resource__c) oldMapItems.get(rsrce.Id);

                //Check if the field active user is changed to TRUE and the field "Requires Click User" is set to TRUE
                //Then create integration log.
                if ((oldRes.ActiveUser__c != rsrce.ActiveUser__c  
                    || oldRes.RequiresClickUser__c != rsrce.RequiresClickUser__c)
                    && rsrce.ActiveUser__c
                    && !TS_Constants.EMPSTAT_0.equals(rsrce.EmployeeStatus__c)
                    && rsrce.Username__c != null) {

                    if(rsrce.RequiresClickUser__c){
                        //Create mapping for integration log specific to user creation
                        Integration_Log__c integLog = new Integration_Log__c();
                        integLog.Object_Id__c = rsrce.Id;
                        integLog.Object__c = TS_Constants.CLICK_USERCREATE;
                        integLog.Integration_Status__c = INT_Constants.INITIAL;
                        integLog.Triggered_Timestamp__c = Datetime.now();
                        integLogList.add(integLog);
                    }

                    if (rsrce.RelatedUser__c == null || rsrce.RelatedUser__c != oldRes.RelatedUser__c) {
                        resList.add(rsrce.Id);
                    }
                }
            }
        }

        try {
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_ResourceTriggerHandlerException('Force to throw an exception');
            }

            System.debug('XEN 8/24 ' + resList);
            
            //Check if user has access to insert User records
            if (!resList.isEmpty() && Schema.sObjectType.User.isCreateable()) {
                //insert userMap.values();
                TS_AsyncUserCreateOrUpdate userRes = new TS_AsyncUserCreateOrUpdate();
                userRes.resourceList = resList;
                userRes.map_profile = map_profile;
                userRes.integLogList = !integLogList.isEmpty() && Schema.sObjectType.Integration_Log__c.isCreateable()? integLogList : new List<Integration_Log__c>();
                System.enqueueJob(userRes);
            }

            //Check if user has access to insert integration log records
            //if (!integLogList.isEmpty() && Schema.sObjectType.Integration_Log__c.isCreateable()) {
            //    insert integLogList;
            //}
        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }

        CustomLogging.pop();
    }

    /**
    * @author        Paul Jarred Aguiling
    * @date          07.05.2018            
    * @description   Set the default value for the user profile depending on the position description
                     XEN REYES Nov. 27, 2018 - Auto populate username based on email address for non TS Resource/Third Party profile users
    * @revision(s)
    */
    private void predefinedUserProfile(List<sObject> newList) {
        CustomLogging.push('predefinedUserProfile', 'ResourceTriggerHandler');
        for (Resource__c rsrce : (List<Resource__c>) newList) {

            if (rsrce.Click__c && (Label.TS_ResourceUsrProf_Operator.equals(rsrce.UserProfile__c) 
                || Label.TS_ResourceUsrProf_Planner.equals(rsrce.UserProfile__c)
                || Label.TS_ResourceUsrProf_RoutesalesRes.equals(rsrce.UserProfile__c)
                || Label.TS_ResourceUsrProf_BiAnalyst.equals(rsrce.UserProfile__c)
                || Label.TS_ResourceUsrProf_Admin.equals(rsrce.UserProfile__c)
                || Label.TS_ResourceUsrProf_Supervisor.equals(rsrce.UserProfile__c))
                && rsrce.Position_Description__c != null
                && rsrce.Position_Description__c != ''
                && rsrce.EmailAddress__c != null) {

                //Get the custom setting map for the position to user profile
                TS_PositionUserProfileMapping__c userProf = TS_PositionUserProfileMapping__c.getInstance(rsrce.Position_Description__c);
                rsrce.UserProfile__c = userProf != null ? userProf.CustomUserProfile__c : rsrce.UserProfile__c;
                rsrce.RequiresClickUser__c = userProf != null ? true : false; //XEN REYES Dec. 10, 2018
                rsrce.ActiveUser__c = userProf != null ? true : false; //XEN REYES Dec. 10, 2018

                //XEN REYES Nov. 27, 2018
                rsrce.Username__c = rsrce.EmailAddress__c;
            }
        }

        CustomLogging.pop();
    }

    /**
    * @author        Paul Jarred Aguiling
    * @date          07.05.2018            
    * @description   [KTS-1933]: Method used to deactivate user record in SF and Click
    * @revision(s)
    */
    private void deactivateUser(List<sObject> newList, Map<Id, sObject> oldMapItems) {
        CustomLogging.push('deactivateUser', 'ResourceTriggerHandler');
        List<Resource__c> resourceToUpdate = new List<Resource__c>();
        List<Integration_Log__c> integLogList = new List<Integration_Log__c>();
        List<Id> userId = new List<Id>();
        
        //Iterate resource (USER) record
        for (Resource__c newRec : (List<Resource__c>) newList) {
            Resource__c oldRec = (Resource__c) oldMapItems.get(newRec.Id);

            //Whenever a resource is updated we need a trigger to determine if a user needs to be deactivated in Click or 
            //in Salesforce which will be done by evaluating the field employee status. When the status changes from 3 to 0.
            //XEN REYES added additional criteria, from active = true to false
            //XEN REYES Dec. 17, 2018 - Added more fields to flush when deactivating a resource and/or user.

            if ((TS_Constants.EMPSTAT_3.equals(oldRec.EmployeeStatus__c) && TS_Constants.EMPSTAT_0.equals(newRec.EmployeeStatus__c)) ||
                oldRec.ActiveUser__c == true && newRec.ActiveUser__c == false) {
                //newRec.ActiveUser__c = false;
                //resourceToUpdate.add(newRec);

                Resource__c newRes = new Resource__c();
                newRes.Id = newRec.Id;
                newRes.ActiveUser__c = false;
                newRes.Username__c = null;
                newRes.UserProfile__c = null;
                newRes.NickName__c = null;
                newRes.RelatedContact__c = null;
                newRes.RelatedUser__c = null;
                newRes.RequiresClickUser__c = false;
                resourceToUpdate.add(newRes);
                
                //Collect related user from the resource record to be deactivated
                if (newRec.RelatedUser__c != null) {
                    userId.add(newRec.RelatedUser__c);
                }

                //We will need to send an integration message to Click in order to de-activate the user
                //by checking if Requires Click User is TRUE
                if (newRec.RequiresClickUser__c) {
                    //Create mapping for integration log specific to user creation
                    Integration_Log__c integLog = new Integration_Log__c();
                    integLog.Object_Id__c = newRec.Id;
                    integLog.Object__c = TS_Constants.CLICK_USERDELETE;
                    integLog.Integration_Status__c = INT_Constants.INITIAL;
                    integLog.Triggered_Timestamp__c = Datetime.now();
                    integLogList.add(integLog);
                }

            }  
        }

        try {
            //Collect and update the related user
            if (!userId.isEmpty()) {
                List<User> userToUpdate = new List<User>();

                for (User usr: [SELECT Id FROM User WHERE Id IN :userId]) {
                    usr.IsActive = false;
                    userToUpdate.add(usr);
                }

                if (!userToUpdate.isEmpty() && Schema.sObjectType.User.isUpdateable()) {
                    //update userToUpdate;
                    TS_AsyncUserCreateOrUpdate userRes = new TS_AsyncUserCreateOrUpdate();
                    userRes.userToUpdate = userToUpdate;
                    System.enqueueJob(userRes);
                }
            }

            //Check if user has access to insert resource records
            if (!resourceToUpdate.isEmpty() && Schema.sObjectType.Resource__c.isUpdateable()) {
                update resourceToUpdate;
            }

            //Check if user has access to insert integration log records
            if (!integLogList.isEmpty() && Schema.sObjectType.Integration_Log__c.isCreateable()) {
                insert integLogList;
            }
        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        CustomLogging.pop();
    }

    /**
    * @author        Paul Jarred Aguiling
    * @date          07.05.2018           
    * @description   Method used to retrieve profiles involved
    * @revision(s)
    */
    @TestVisible
    private Map<String, Id> getProfile() {
        CustomLogging.push('getProfile', 'ResourceTriggerHandler');
        Map<String, Id> resultMap = new Map<String, Id>();
        List<String> listCommunityProf = new List<String>();
        listCommunityProf.add(TS_Constants.PROFILE_PORTALUSER);
        listCommunityProf.add(TS_Constants.PROFILE_MOBILEUSER);

        //Collect list of profiles 
        for (Profile prof : [SELECT Id, Name 
                             FROM Profile 
                             WHERE Name IN :listCommunityProf]) {
            //Customer portal user
            if (TS_Constants.PROFILE_PORTALUSER.equals(prof.Name)) {
                resultMap.put(Label.TS_ResourceUsrProf_ThirdParty, prof.Id);
            //Mobile user
            } else if (TS_Constants.PROFILE_MOBILEUSER.equals(prof.Name)) {
                resultMap.put(Label.TS_ResourceUsrProf_TSRes, prof.Id);
            }
        }

        Customlogging.pop();
        return resultMap;
    }

    /**
    * @author        Abram Vixen Reyes
    * @date          Nov. 27, 2018    
    * @description   Method used to check if the username already exist for third party and TS_Resource
    * @revision(s)   Dec. 10, 2018: also check if nickname or portal user contact already exist
    */
    public void validateFields(List<SObject> newList, Map<Id, SObject> newMapItems, Map<Id, SObject> oldMapItems) {
        CustomLogging.push('validateFields', 'ResourceTriggerHandler');

        Map<String, Id> map_ResIdUsername = new Map<String, Id>();
        Map<String, Id> map_ResIdNickname = new Map<String, Id>();
        Map<String, Id> map_ResIdPortalUser = new Map<String, Id>();
        List<User> list_userRec = new List<User>();

        for (Resource__c rsrce : (List<Resource__c>) newList) {
            Resource__c resOld = (Resource__c) oldMapItems.get(rsrce.Id);

            if(Label.TS_ResourceUsrProf_ThirdParty.equals(rsrce.UserProfile__c) || Label.TS_ResourceUsrProf_TSRes.equals(rsrce.UserProfile__c)){
                
                if(rsrce.Username__c != resOld.Username__c && rsrce.Username__c != null){
                    map_ResIdUsername.put(rsrce.Username__c, rsrce.Id);
                }

                if(rsrce.NickName__c != resOld.NickName__c && rsrce.NickName__c != null){
                    map_ResIdNickname.put(rsrce.NickName__c, rsrce.Id);
                }

                if(rsrce.RelatedContact__c != resOld.RelatedContact__c && rsrce.RelatedContact__c != null){
                    map_ResIdPortalUser.put(rsrce.RelatedContact__c, rsrce.Id);
                }
            }
        }

        if(!map_ResIdUsername.isEmpty() || !map_ResIdNickname.isEmpty() || !map_ResIdPortalUser.isEmpty()){
            list_userRec = [SELECT Id, Username, CommunityNickname, ContactId FROM User WHERE (Username IN: map_ResIdUsername.keySet() OR CommunityNickname IN: map_ResIdNickname.keySet() OR ContactId IN: map_ResIdPortalUser.keySet())];

            if(list_userRec.isEmpty()){
                return;
            } else {
                for(User userRec : list_userRec){
                    
                    //CHECK FOR USERNAME DUPLICATE
                    if(map_ResIdUsername.containsKey(userRec.Username)){
                        newMapItems.get(map_ResIdUsername.get(userRec.Username)).addError('Username already exists.');
                    }

                    //CHECK FOR NICKNAME DUPLICATE
                    if(map_ResIdNickname.containsKey(userRec.CommunityNickname)){
                        newMapItems.get(map_ResIdNickname.get(userRec.CommunityNickname)).addError('Nickname already exists.');
                    }

                    //CHECK FOR RELATED CONTACT DUPLICATE
                    if(map_ResIdPortalUser.containsKey(userRec.ContactId)){
                        newMapItems.get(map_ResIdPortalUser.get(userRec.ContactId)).addError('User already exists for the related contact.');
                    }
                }
            }
        }

        Customlogging.pop();
    }
    
    /**
    * @author        Karen Mae Hung
    * @date          April 7, 2021          
    * @description   DOO-5217 Method to assign or remove 3rd Party Operating Schedule permission set 
    * @revision(s)
    */
    public void permissionSetUpdate(List<SObject> newList, Map<Id, SObject> oldMapItems) {
        CustomLogging.push('permissionSetUpdate', 'ResourceTriggerHandler');
        
        List<String> forSchedPerm = new List<String>();
        List<String> forPermRemoval = new List<String>();
        for (Resource__c rsrce : (List<Resource__c>) newList) {
       		Resource__c resOld = (Resource__c) oldMapItems?.get(rsrce.Id);
            
            //get id's for permission set assignment
            if(rsrce.Create_Edit_OPG_Schedule__c && (resOld == null || resOld?.Create_Edit_OPG_Schedule__c == false) && rsrce.RelatedUser__c !=null && rsrce.ActiveUser__c){
            	forSchedPerm.add(rsrce.RelatedUser__c);    
            }
            
            //get id's for permission set assignment removal
            if(rsrce.Create_Edit_OPG_Schedule__c == false && resOld !=null && resOld?.Create_Edit_OPG_Schedule__c && rsrce.RelatedUser__c !=null){
            	forPermRemoval.add(rsrce.RelatedUser__c);    
            }
        }
        
        if(!forSchedPerm.isEmpty() || !forPermRemoval.isEmpty()){
            TS_QueueableProcesses varProcess = new TS_QueueableProcesses();
            varProcess.METHOD_3PO_PERMISSIONSET = true;
            varProcess.forSchedPerm = forSchedPerm;
            varProcess.forPermRemoval = forPermRemoval;
            System.enqueueJob(varProcess);    
        }   

        Customlogging.pop();
    }
}