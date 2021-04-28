/**
* Class Name: TerritoryResult_UpdateBatch 
* @author: James Azana
* Date: 13-Jun-2017
* Requirement: Batch process to apply Territory Results to Accounts
* @description: Updates Account based on Territory Results
*
*/
 
global with sharing class TerritoryResult_UpdateBatch implements Database.Batchable<SObject>, Database.Stateful{
    
    global id modelId;
    global String modelCountry;
    global integer errors = 0;
    global integer sequence = 0;
    
    //Custom Setting variables
    global List<ProcessBuilderSettings__c> PBSList;
    global List<ValidationRulesSettings__c> VRSList;
    global List<WorkflowSettings__c> WFSList;
    global List<TriggerSettings__c> TSList;
    
    global ProcessBuilderSettings__c PBS;
    global ValidationRulesSettings__c VRS;
    global WorkflowSettings__c WFS;
    global TriggerSettings__c TS;
    
    global boolean revertAccountPBS = false;
    global boolean revertAccountVRS = false;
    global boolean revertAccountWFS = false;
    global boolean revertAccountTS = false;
    
    global boolean deleteAfterPBS = false;
    global boolean deleteAfterVRS = false;
    global boolean deleteAfterWFS = false;
    global boolean deleteAfterTS = false;
    
    //define query statement to retrieve existing territory results to be deleted
    public String resultQuery =  'SELECT id, Territory_Model__c, Account__c, Territory_Rule__c, Territory_Rule__r.Assigned_Territory__c, Territory_Rule__r.Assigned_Territory__r.Commercial_Territory_Owner__c,Territory_Rule__r.Assigned_Territory__r.Sales_Inside_1__c, Territory_Rule__r.Assigned_Territory__r.Sales_Inside_2__c, Territory_Rule__r.Assigned_Territory__r.Sales_Outside_1__c, Territory_Rule__r.Assigned_Territory__r.Sales_Outside_2__c, Territory_Rule__r.Assigned_Territory__r.Customer_Relations_1__c, Territory_Rule__r.Assigned_Territory__r.Customer_Relations_2__c FROM Territory_Result__c WHERE Territory_Model__c = :modelId AND Excl_on_Account__c = false AND Assigned_Owner__c != null AND Territory_Rule__c != null';
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        CustomLogging.push('start', 'TerritoryResult_UpdateBatch');
        //Muting of AccountTriggerHandler
        AccountTriggerHandler.isBatchRun = true;
        //Muting of Custom Settings
        //Process Builder
        PBSList = [SELECT id, SetupOwnerId, AccountPBFlows__c FROM ProcessBuilderSettings__c WHERE SetupOwnerId =: UserInfo.getUserId()];
        try{
            if(PBSList.isEmpty()){
                PBS = new ProcessBuilderSettings__c();
                PBS.SetupOwnerId = UserInfo.getUserId();
                PBS.AccountPBFlows__c = false;
                deleteAfterPBS = true;
                
                if(Schema.sObjectType.ProcessBuilderSettings__c.fields.SetupOwnerId.isCreateable() && 
                   Schema.sObjectType.ProcessBuilderSettings__c.fields.AccountPBFlows__c.isCreateable()){
                    insert PBS;
                }
            }
            else{
                PBS = PBSList[0];
                if(PBS.AccountPBFlows__c){
                    revertAccountPBS = PBS.AccountPBFlows__c;
                    PBS.AccountPBFlows__c = false;
                    
                    if(Schema.sObjectType.ProcessBuilderSettings__c.fields.AccountPBFlows__c.isUpdateable()){
                        update PBS;
                    }
                }           
            }
            
            //Validation Rules
            VRSList = [SELECT id, SetupOwnerId, AccountValidationRules__c FROM ValidationRulesSettings__c WHERE SetupOwnerId =: UserInfo.getUserId()];
            if(VRSList.isEmpty()){
                VRS = new ValidationRulesSettings__c();
                VRS.SetupOwnerId = UserInfo.getUserId();
                VRS.AccountValidationRules__c = false;
                deleteAfterVRS = true;
                
                if(Schema.sObjectType.ValidationRulesSettings__c.fields.SetupOwnerId.isCreateable() && 
                   Schema.sObjectType.ValidationRulesSettings__c.fields.AccountValidationRules__c.isCreateable()){
                    insert VRS;
                }
            }
            else{
                VRS = VRSList[0];
                if(VRS.AccountValidationRules__c){
                    revertAccountVRS = VRS.AccountValidationRules__c;
                    VRS.AccountValidationRules__c = false;
                    
                    if(Schema.sObjectType.ValidationRulesSettings__c.fields.AccountValidationRules__c.isUpdateable()){
                        update VRS;
                    }
                }           
            }
            
            //Workflow Settings
            WFSList = [SELECT id, SetupOwnerId, AccountWorkflows__c FROM WorkflowSettings__c WHERE SetupOwnerId =: UserInfo.getUserId()];
            if(WFSList.isEmpty()){
                WFS = new WorkflowSettings__c();
                WFS.SetupOwnerId = UserInfo.getUserId();
                WFS.AccountWorkflows__c = false;
                deleteAfterWFS = true;
                
                if(Schema.sObjectType.WorkflowSettings__c.fields.SetupOwnerId.isCreateable() && 
                   Schema.sObjectType.WorkflowSettings__c.fields.AccountWorkflows__c.isCreateable()){
                    insert WFS;
                }
            }
            else{
                WFS = WFSList[0];
                if(WFS.AccountWorkflows__c){
                    revertAccountWFS = WFS.AccountWorkflows__c;
                    WFS.AccountWorkflows__c = false;
                    
                    if(Schema.sObjectType.WorkflowSettings__c.fields.AccountWorkflows__c.isUpdateable()){
                        update WFS;
                    }                
                }           
            }
            
            //Trigger Settings
            TSList = [SELECT id, SetupOwnerId, AccountTrigger__c FROM TriggerSettings__c WHERE SetupOwnerId =: UserInfo.getUserId()];
            if(TSList.isEmpty()){
                TS = new TriggerSettings__c();
                TS.SetupOwnerId = UserInfo.getUserId();
                TS.AccountTrigger__c = false;
                deleteAfterTS = true;
                
                if(Schema.sObjectType.TriggerSettings__c.fields.SetupOwnerId.isCreateable() && 
                   Schema.sObjectType.TriggerSettings__c.fields.AccountTrigger__c.isCreateable()){
                    insert TS;
                }
            }
            else{
                TS = TSList[0];
                if(TS.AccountTrigger__c){
                    revertAccountTS = TS.AccountTrigger__c;
                    TS.AccountTrigger__c = false;
                    
                    if(Schema.sObjectType.TriggerSettings__c.fields.AccountTrigger__c.isUpdateable()){
                        update TS;
                    }
                }           
            }
            
        }catch(Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();                 
        }
        //execute query
        return Database.getQueryLocator(resultQuery);
        
    }
    
    global void execute(Database.BatchableContext BC, List<SObject> scope){
        CustomLogging.push('execute', 'TerritoryResult_UpdateBatch');
        //get Ids of records linked to the Territory Results
        List<Territory_Result__c> resultList = scope;
        List<Id> accIds = new List<Id>();
        Map<Id, Id> accRuleMap = new Map<Id, Id>();
        Map<Id, Id> accTerritoryMap = new Map<Id, Id>();
        Map<Id, Id> accSalesInside1Map = new Map<Id, Id>();
        Map<Id, Id> accSalesInside2Map = new Map<Id, Id>();
        Map<Id, Id> accSalesOutside1Map = new Map<Id, Id>();
        Map<Id, Id> accSalesOutside2Map = new Map<Id, Id>();
        Map<Id, Id> accCustRel1Map = new Map<Id, Id>();
        Map<Id, Id> accCustRel2Map = new Map<Id, Id>();
        Map<Id, Id> accOwnerMap = new Map<Id, Id>();
        List<Account> accToUpdate = new List<Account>();
        Database.SaveResult[] SaveResultList;
        List<String> exception_List;
        
        try{
            for (integer x = 0; x < resultList.size(); x++){
                accIds.add(resultList[x].Account__c);
                accRuleMap.put(resultList[x].Account__c, resultList[x].Territory_Rule__c);
                accTerritoryMap.put(resultList[x].Account__c, resultList[x].Territory_Rule__r.Assigned_Territory__c);
                accSalesInside1Map.put(resultList[x].Account__c, resultList[x].Territory_Rule__r.Assigned_Territory__r.Sales_Inside_1__c);
                accSalesInside2Map.put(resultList[x].Account__c, resultList[x].Territory_Rule__r.Assigned_Territory__r.Sales_Inside_2__c);
                accSalesOutside1Map.put(resultList[x].Account__c, resultList[x].Territory_Rule__r.Assigned_Territory__r.Sales_Outside_1__c);
                accSalesOutside2Map.put(resultList[x].Account__c, resultList[x].Territory_Rule__r.Assigned_Territory__r.Sales_Outside_2__c);
                accCustRel1Map.put(resultList[x].Account__c, resultList[x].Territory_Rule__r.Assigned_Territory__r.Customer_Relations_1__c);
                accCustRel2Map.put(resultList[x].Account__c, resultList[x].Territory_Rule__r.Assigned_Territory__r.Customer_Relations_2__c);
                accOwnerMap.put(resultList[x].Account__c, resultList[x].Territory_Rule__r.Assigned_Territory__r.Commercial_Territory_Owner__c);
            }
            
            //update accounts
            List<Account> accList = [SELECT id, Territory__c, Applied_Territory_Rule__c, OwnerId FROM Account WHERE Id IN :accIds];
            
            for(Account acc : accList){
            
                if(accTerritoryMap.containsKey(acc.id)){
                    acc.Territory__c = accTerritoryMap.get(acc.id);
                }
                
                if(accSalesInside1Map.containsKey(acc.id)){
                    acc.Sales_Inside_1__c = accSalesInside1Map.get(acc.id);
                }
                
                if(accSalesInside2Map.containsKey(acc.id)){
                    acc.Sales_Inside_2__c = accSalesInside2Map.get(acc.id);
                }
                
                if(accSalesOutside1Map.containsKey(acc.id)){
                    acc.Sales_Outside_1__c = accSalesOutside1Map.get(acc.id);
                }
                
                if(accSalesOutside2Map.containsKey(acc.id)){
                    acc.Sales_Outside_2__c = accSalesOutside2Map.get(acc.id);
                }
                
                if(accCustRel1Map.containsKey(acc.id)){
                    acc.Customer_Relations_1__c = accCustRel1Map.get(acc.id);
                }
                
                if(accCustRel2Map.containsKey(acc.id)){
                    acc.Customer_Relations_2__c = accCustRel2Map.get(acc.id);
                }
                
                if(accRuleMap.containsKey(acc.id)){
                    acc.Applied_Territory_Rule__c = accRuleMap.get(acc.id);
                }
                
                if(accOwnerMap.containsKey(acc.id)){
                    acc.OwnerId = accOwnerMap.get(acc.id);
                }
                
                accToUpdate.add(acc);
            }
            
            if(!accToUpdate.isEmpty()){
                update accToUpdate;
            }
            
            
         }catch(Exception ex){            
            errors = errors + 1;          
            CustomLogging.debugException(ex);
            CustomLogging.pop();               
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        try{
            AsyncApexJob a = [SELECT Id, CreatedById FROM AsyncApexJob where Id =:BC.getJobId()];
            
            Territory_Model__c model = [SELECT id, name, Definition_Status__c, RecordTypeId, Country__c, Description__c FROM Territory_Model__c WHERE Id = :modelId];
            List<Territory__c> territories = [Select Id, isChanged__c FROM Territory__c WHERE Territory_Model__c = :modelId AND isChanged__c = true];
                
                //update Definition Status and Generate Batch Id of Model
                model.RecordTypeId = Schema.SObjectType.Territory_Model__c.getRecordTypeInfosByName().get(SM_Constants.modelRecTypeCompleted).getRecordTypeId(); //@Updated - Alvin Lomod - added recordtype on complete
                model.Definition_Status__c = SM_Constants.modelStatusComplete;
                model.Active__c = true;
                model.Last_Run__c = datetime.now();
                update model;
                
                for (Territory__c t : territories){
                    t.isChanged__c = false;
                }
                
                update territories;
                
                //create chatter post 
            if(!Test.isRunningTest()){
               ConnectApi.FeedItem post = (ConnectApi.FeedItem) ConnectApiHelper.postFeedItemWithMentions(Network.getNetworkId(), model.Id,  '{' + a.CreatedById + '}' + ' the Territory Model has finished running and has updated the Accounts!'); 
            }       
                            
            //Revert or Delete Custom Setting
            //Process Builder
            if(deleteAfterPBS){           
                if(ProcessBuilderSettings__c.sObjectType.getDescribe().isDeletable()){
                    delete PBS;
                }
            }
            if(revertAccountPBS){
                PBS.AccountPBFlows__c = revertAccountPBS;               
                if(Schema.sObjectType.ProcessBuilderSettings__c.fields.AccountPBFlows__c.isUpdateable()){
                    update PBS;
                }
            }
            
            //Validation Rules
            if(deleteAfterVRS){               
                if(ValidationRulesSettings__c.sObjectType.getDescribe().isDeletable()){
                    delete VRS;
                }
            }
            if(revertAccountVRS){
                VRS.AccountValidationRules__c = revertAccountVRS;
                if(Schema.sObjectType.ValidationRulesSettings__c.fields.AccountValidationRules__c.isUpdateable()){
                    update VRS;
                }
            }
            
            //Workflow Rules
            if(deleteAfterWFS){              
                if(WorkflowSettings__c.sObjectType.getDescribe().isDeletable()){
                    delete WFS;
                }
            }
            if(revertAccountWFS){
                WFS.AccountWorkflows__c = revertAccountWFS;
                
                if(Schema.sObjectType.WorkflowSettings__c.fields.AccountWorkflows__c.isUpdateable()){
                    update WFS;
                }
            }
            
            //Trigger
            if(deleteAfterTS){              
                if(TriggerSettings__c.sObjectType.getDescribe().isDeletable()){
                    delete TS;
                }
            }
            if(revertAccountTS){
                TS.AccountTrigger__c = revertAccountTS;    
                if(Schema.sObjectType.TriggerSettings__c.fields.AccountTrigger__c.isUpdateable()){
                    update TS;
                }
            }
        }catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();                
        }
    }
 }