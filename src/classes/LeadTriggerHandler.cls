/**
 * Class Name: AssetLineItemSharingTriggerHandler
 * @author: Alvin Lomod
 * Date: 3-Nov-2017
 * Requirement: Trigger for Lead; KASM-232
 * @description: 
 *               Created by S&M Team
 *
 */
 
public without sharing class LeadTriggerHandler implements ITriggerHandler{
    private static final User u = UserDAO.userInformation();
    public static Boolean isTriggerDisabled = true;
    Map<Id, Lead> oldMap = new  Map<Id, Lead>();
    
    public void BeforeInsert(List<Lead> newList){
        leadScoring(newList,oldMap);
        stampRoleId(newList);
        stampSalesorganization(newList);
        ChangeOwnerToQueueDellBoomi(newList, oldMap);
        generateHash(newList, oldMap);
    } 
 
    public void BeforeUpdate(List<Lead> newList, Map<Id, SObject> newItems, List<Lead> oldList, Map<Id, SObject> oldSobjectMap){
        Map<Id, Lead> oldLeadMap = (Map<Id, Lead>) oldSobjectMap;
        leadScoring(newList, oldLeadMap);
        ChangeOwnerToQueueDellBoomi(newList, oldLeadMap);
        generateHash(newList, oldLeadMap);
    }
 
    public void BeforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems){
        
    }
 
    public void AfterInsert(List<Lead> newList, Map<Id, SObject> newItems){
        OnAfterInsertLeadTransferToQueuePartnerUser(newList);
        Ownerchangedtoqueuenotification(newList, oldMap);
        createIndividual(newList);
    }
 
    public void AfterUpdate(List<Lead> newList, Map<Id, SObject> newItems, List<Lead> oldList, Map<Id, SObject> oldSobjectMap){
        Map<Id, Lead> oldLeadMap = (Map<Id, Lead>) oldSobjectMap;
        Ownerchangedtoqueuenotification(newList, oldLeadMap);
        createSubscription(newList, oldLeadMap);
        leadisDisqualifiedclosetask(newList, oldLeadMap);
        leadisConvertedclosetask(newList, oldLeadMap);
    }
 
    public void AfterDelete(List<SObject> oldList, Map<Id, SObject> oldItems){
        
    }
 
    public void AfterUndelete(List<SObject> newList, Map<Id, SObject> newItems){
        
    }
    
    public Boolean IsDisabled(){
        if (TriggerSettings__c.getInstance().LeadTrigger__c == true) {
            return false;
        } else {
            return isTriggerDisabled;
        }
    }
    
    /**
     * Method Name: OnAfterInsertLeadTransferToQueuePartnerUser
     * @author: Alvin Lomod
     * Date: 3-Nov-2017
     * Requirement: KASM-232
     * @description: Transfer Lead to Queue if Lead Source is Asset Ownership Change and current user is Partner User. Basically, updating the checkbox to execute the workflow.
     *
     */
    
     //This trigger was made because the quick action throws an error when a lead is created and the owner is instantly changed
    public static void OnAfterInsertLeadTransferToQueuePartnerUser(List<Lead> LeadList){
        CustomLogging.push('OnAfterInsertLeadTransferToQueuePartnerUser', 'LeadTriggerHandler');
        try{
            Set<Id> LeadtoChangeOwner = new Set<Id>();
            Boolean RunningPartnerUser = false;
            Id PRFPartnerLeadRecTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get(SM_Constants.LeadRecTypePRFPartner).getRecordTypeId();
    
            if(UserInfo.getUserType() == 'PowerPartner'){
                RunningPartnerUser = true;
            }
            
            
            for(Lead l : LeadList){
                if(l.LeadSource == 'Asset Ownership Change' && l.RecordTypeId == PRFPartnerLeadRecTypeId){
                    LeadtoChangeOwner.add(l.Id);   
                }
            }
            
            if(LeadtoChangeOwner.size() > 0 && RunningPartnerUser){
                
                ChangeOwnerToQueue(LeadtoChangeOwner);
            }
        
        } catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop();   
    }
     
    @future
    public static void ChangeOwnerToQueue(Set<Id> LeadIds){ 
        CustomLogging.push('ChangeOwnerToQueue', 'LeadTriggerHandler');
        try{
            List<Lead> LeadToChangeOwnerList = new List<Lead>(); 
            //not working in for future
            system.debug('****Accessible');       
            LeadToChangeOwnerList = [SELECT Id, OwnerId, RecordTypeId, Sales_Organization__c, Assign__c FROM Lead WHERE Id in: LeadIds]; 

            for(Lead l : LeadToChangeOwnerList){
                
                //this will trigger the lead workflow and assign the lead record to a queue
                if(l.Assign__c == false){
                    l.Assign__c  = true;
                }
                
            }

            update LeadToChangeOwnerList;
        } catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop();   
        /*  Error Proof 
        }catch(Exception ex){
                
            //CustomLogging.debugException(ex);
            //CustomLogging.pop();
            
            string exceptionInfo = ex.getMessage() + ' stack: ' + ex.getStackTraceString();
            
            string limitstring = '';        
            limitstring += 'Query Limits:'+ Limits.getQueries() + '/' + Limits.getLimitQueries();
            limitstring += 'DML Rows Limits:'+Limits.getDMLRows() + '/' + Limits.getLimitDMLRows();
            limitstring += 'Heap Size Limits:'+Limits.getHeapSize() + '/' +Limits.getLimitHeapSize();
            limitstring += 'Query Return Limits:'+Limits.getQueryRows() + '/' + Limits.getLimitQueryRows();      
            limitstring += 'Aggregate Queries:'+Limits.getAggregateQueries() + '/' + Limits.getLimitAggregateQueries();
            limitstring += 'Callouts:'+Limits.getCallouts() + '/' + Limits.getLimitCallouts();    
            limitstring += 'CPU Time:'+Limits.getCpuTime() + '/' + Limits.getLimitCpuTime();
            limitstring += 'DML Statements:'+Limits.getDMLStatements() + '/' + Limits.getLimitDMLStatements();
            limitstring += 'Email Invocations:'+Limits.getEmailInvocations() + '/' + Limits.getLimitEmailInvocations();    
            limitstring += 'Future Calls:'+Limits.getFutureCalls() + '/' + Limits.getLimitFutureCalls();     
            limitstring += 'Query Locator Rows:'+Limits.getQueryLocatorRows() + '/' + Limits.getLimitQueryLocatorRows();
        
            Custom_Log__c log = new Custom_Log__c(
            StackTrace__c = 'AssetLineItemSharingTriggerHandler : execute',
            Limits__c = limitstring,
            Message__c = exceptionInfo,
            LogType__c = 'Exception',                   
            ExceptionLine__c = ex.getLineNumber(),
            ExceptionType__c = ex.getTypeName(),
            Sequence__c = 1);
            insert log;
        
        }*/
     }
     
    public static void leadScoring (List<Lead> newList, Map<Id,Lead> oldLeadMap) {
        CustomLogging.push('leadScoringonInsert', 'LeadTriggerHandler');
        try{
            List<Lead> filteredleads = new List<Lead>();
            for (Lead l : newList){
                if (touchpointTypeChange(l, oldLeadMap)){
                    filteredleads.add(l);
                }
            }
            if (!filteredleads.isEmpty()){
                SM_LeadUtil.leadScoring(filteredleads);
            }
        } catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop();   
    }
    
    private static Boolean touchpointTypeChange(Lead l, Map<Id, Lead> oldRecordMap) {
        Lead oldLead;
        Boolean ttChange = false;
        
        if (!oldRecordMap.isEmpty()){
            oldLead = oldRecordMap.get(l.id);
            if (l.Touchpoint_Type__c != null && l.Touchpoint_Type__c != oldLead.Touchpoint_Type__c){
                ttChange = true;
            }
        } else {
            if (l.Touchpoint_Type__c != null) {
                ttChange = true;
            }
        }
        return ttChange;
    }
    
    private static Boolean checkchangeforassigntoqueue(Lead ld, Map<Id, Lead> oldLeadMap){
        Lead oldlead;
        Boolean leadupdate = false;
        if (!oldLeadMap.isEmpty()){
            oldlead = oldLeadMap.get(ld.Id);
            if (ld.Sales_Organization__c != null && ld.Sales_Organization__c != oldlead.Sales_Organization__c && (u.Profile.Name == SM_Constants.JDEDigital || u.Profile.Name == SM_Constants.SystemAdmin
                || u.Profile.Name == 'JDE-Integration-Marketing Cloud')){
                leadupdate = true;
            }
        }
        else {
            if (ld.Sales_Organization__c != null && (u.Profile.Name == SM_Constants.JDEDigital || u.Profile.Name == SM_Constants.SystemAdmin || u.Profile.Name == 'JDE-Integration-Marketing Cloud')){
                leadupdate = true;
            }
        }
        return leadupdate;
    }
    
    /**
     * Method Name: ChangeOwnerToQueueDellBoomi
     * @author: Glenn Serrano
     * Date: 16 - October - 2018
     * Requirement: KASM-2843
     * @description: Transfer Lead to Queue if Dell Boomi inserts a lead
     *
     */
     
      public static void ChangeOwnerToQueueDellBoomi (List<Lead> newList, Map <Id, Lead> oldLeadMap) {
        CustomLogging.push('ChangeOwnerToQueueDellBoomionCreate', 'LeadTriggerHandler');
        try{
            List<Lead> filteredleads = new List<Lead>();
            for (Lead leadrecord : newlist) {
                Queue_Lead_Task__c queuelead = Queue_Lead_Task__c.getInstance(leadrecord.Sales_Organization__c);
                if (checkchangeforassigntoqueue(leadrecord, oldLeadMap)){
                    filteredleads.add(leadrecord);
                }
            }
            
            if (!filteredleads.isEmpty()){
                SM_LeadUtil.ChangeOwnerToQueueDellBoomi(filteredleads);
            }
        } catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop();   
        
    }
    
    private static Boolean ownerofleadisqueue(Lead ld, Map<Id, Lead> oldLeadMap){
        Lead oldlead;
        Boolean assignleadownerisqueue = false;
        if (!oldLeadMap.isEmpty()){
            oldlead = oldLeadMap.get(ld.Id);
            if (string.valueOf(ld.OwnerId).left(3) == '00G' && ld.OwnerId != oldlead.OwnerId){
                assignleadownerisqueue = true;
            }
        }
        else{
            if (string.valueOf(ld.OwnerId).left(3) == '00G'){
                assignleadownerisqueue = true;
            }
        }
        return assignleadownerisqueue;
    }
    
    public static void Ownerchangedtoqueuenotification(List<Lead> newLeadList, Map<Id, Lead>  oldLeadMap){
        CustomLogging.push('ownerchangedtoqueuenotification', 'LeadTriggerHandler');
        try{
            List<Lead> leadFiltered = new List<Lead>();
            for (Lead l : newLeadList){
                if (ownerofleadisqueue(l,oldLeadMap)){
                    leadFiltered.add(l);
                }
            }
            if (!leadFiltered.isEmpty()){
                SM_LeadUtil.Ownerchangedtoqueuenotification(leadFiltered);
            }
        } catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop();   
    }
    
    public static void leadisDisqualifiedclosetask(List<Lead> newLeadList, Map<Id, Lead>  oldLeadMap){
        CustomLogging.push('leadisDisqualifiedclosetask', 'LeadTriggerHandler');
        try{
            Lead oldlead;
            Set<Id> leaddisqualifiedIDs = new Set<Id>();
            Map<Id, Lead> leadidandtouchpointtypemap = new Map<Id,Lead>();
            if (!oldLeadMap.isEmpty()){
                for (Lead l : newLeadList){
                    oldlead = oldLeadMap.get(l.Id);
                    if (l.Status == 'Disqualified' && l.Reason_Disqualified__c != null && l.Status != oldlead.Status){
                        leadidandtouchpointtypemap.put(l.Id, l);
                        leaddisqualifiedIDs.add(l.Id);
                    }
                }
            }
            
            
            if (!leaddisqualifiedIDs.isEmpty()){
                SM_LeadUtil.leadisDisqualifiedclosetask(leaddisqualifiedIDs, leadidandtouchpointtypemap);
            }
        } catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop();   
    }
    
    public static void leadisConvertedclosetask(List<Lead> newLeadList, Map<Id, Lead>  oldLeadMap){
        CustomLogging.push('leadisConvertedclosetask', 'LeadTriggerHandler');
        try{
            Lead oldlead;
            Set<Id> leadconvertedIDs = new Set<Id>();
            Map<Id, Lead> leadidandtouchpointtypemap = new Map<Id,Lead>();
            if (!oldLeadMap.isEmpty()){
                for (Lead l : newLeadList){
                    oldlead = oldLeadMap.get(l.Id);
                    if (((l.Status == 'Converted with Opportunity' && l.ConvertedOpportunityId != null) || (l.Status == 'Converted without Opportunity' && l.ConvertedOpportunityId == null) || 
                        (l.Status == 'Converted to Opportunity with Event' && l.ConvertedOpportunityId != null)) && l.Status != oldlead.Status){
                        leadidandtouchpointtypemap.put(l.ConvertedContactId, l);
                        leadconvertedIDs.add(l.ConvertedContactId);
                    }
                }
            }
            
            if (!leadconvertedIDs.isEmpty()){
                SM_LeadUtil.leadisConvertedclosetask(leadconvertedIDs, leadidandtouchpointtypemap);
            }
        } catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop();   
    }
    
    public static void stampRoleId(List<Lead> newList){
        CustomLogging.push('stampRoleId', 'LeadTriggerHandler');
        try{
            if (!newList.isEmpty()){
                for (Lead l : newList){
                    if (l.Status == 'Open'){
                        l.Role_Id__c = u.UserRole.DeveloperName;
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
    
    public static void stampSalesorganization(List<Lead> newList){
        CustomLogging.push('stampSalesorganization', 'LeadTriggerHandler');
        try{
            if (!newList.isEmpty()){
                for (Lead l : newList){
                    if (l.Status != null && u.Sales_Organization__c != null && l.Sales_Organization__c == null){
                        l.Sales_Organization__c = u.Sales_Organization__c;
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
    
    public static void createSubscription(List<Lead> newList, Map<Id, Lead>  oldLeadMap){
        CustomLogging.push('createSubscription', 'LeadTriggerHandler');
        try{
            Lead oldlead;
            List<Lead> filteredleads = new List<Lead>();
            if (!oldLeadMap.isEmpty()){
                for (Lead ld : newlist){
                    oldlead = oldLeadMap.get(ld.Id);
                    if (ld.HasOptedOutOfEmail != oldlead.HasOptedOutOfEmail || ld.NewsLetter__c != oldlead.NewsLetter__c || ld.Opt_in_URL__c != oldlead.Opt_in_URL__c || ld.Consent_Registration_Date__c != oldlead.Consent_Registration_Date__c || 
                        ld.Consent_Text__c != oldlead.Consent_Text__c || ld.Privacy_Policy_Version__c != oldlead.Privacy_Policy_Version__c || ld.Events__c != oldlead.Events__c || ld.Promotions__c != oldlead.Promotions__c || ld.Opt_in_Source__c != oldlead.Opt_in_Source__c || 
                        ld.Consent_Registration_Source_URL__c != oldlead.Consent_Registration_Source_URL__c || ld.Consent_Registration_IP_Address__c != oldlead.Consent_Registration_IP_Address__c || ld.Consent_Text_Version__c != oldlead.Consent_Text_Version__c ||
                        ld.Consent_Status__c != oldlead.Consent_Status__c){
                        filteredleads.add(ld);
                    }
                }
                
                if (!filteredleads.isEmpty()){
                    SM_LeadUtil.createSubscription(filteredleads);
                }
            }
            
        } catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop();   
    }
    /**
     * Lead Management New Functionality
     * @author: Glenn Serrano
     * Date: 17 - June - 2020
     * Requirement: DOS-1596
     * @description: As a marketing manager I want to be able to store consent information so that JDE is compliant
     *
     */

    public static void createIndividual(List<Lead> newLeadList){
        CustomLogging.push('createIndividual', 'LeadTriggerHandler');
        try{
            List<Lead> leadFiltered = new List<Lead>();
            if (!newLeadList.isEmpty()){
                for (Lead l : newLeadList){
                    if (l.LastName != null){
                        leadFiltered.add(l);
                    }
                }

                if (!leadFiltered.isEmpty()){
                    SM_LeadUtil.createIndividual(leadFiltered);
                }
            }

        } catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop();   
    }

    /**
     * Conesnt Management New Functionality
     * @author: Glenn Serrano
     * Date: 1 - September - 2020
     * Requirement: DOS-1628
     * @description: As a marketing manager I want to ensure that personal data is not sent when using URLS so that JDE is compliant
     *
     */

    public static void generateHash(List<Lead> newLeadList, Map<Id, Lead>  oldLeadMap){
        CustomLogging.push('generateHash', 'LeadTriggerHandler');
        try{
            List<Lead> leadFiltered = new List<Lead>();
            if (!newLeadList.isEmpty()){
                for (Lead l : newLeadList){
                    if (checkemailneworupdate(l, oldLeadMap)){
                        leadFiltered.add(l);
                    }
                }

                if (!leadFiltered.isEmpty()){
                    SM_LeadUtil.generateHash(leadFiltered);
                }
            }

        } catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop();   
    }

    private static Boolean checkemailneworupdate(Lead ld, Map<Id, Lead> oldLeadMap){
        Lead oldlead;
        Boolean leadupdate = false;
        if (!oldLeadMap.isEmpty()){
            oldlead = oldLeadMap.get(ld.Id);
            if (ld.Email != oldlead.Email){
                leadupdate = true;
            }
        }
        else {
            if (ld.Email != null){
                leadupdate = true;
            }
        }
        return leadupdate;
    }
 }