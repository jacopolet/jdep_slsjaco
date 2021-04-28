/*
* @author        Francis Allen Alindogan
* @date          05.12.2020
* @description   Controller class for TS_CreateOperatingTask lightning component.
* @revision(s)
*/
public without sharing class TS_CreateOperatingTaskController {
    
    //Karen Hung 25/2/2021 DOO-5308 feature flags
    public static Map<Id,TS_Feature_Flag__mdt> featureFlags =  new Map<Id,TS_Feature_Flag__mdt>([SELECT Id, QualifiedApiName, Enable__c FROM TS_Feature_Flag__mdt WHERE QualifiedApiName != null]);
    public static Boolean thirdPartyS20Enabled= false;
    public static Boolean operatingBucketEnabled = false;
    
    /*check featureflag if enabled*/
    @AuraEnabled
    public static Boolean checkFeatureFlag(){
        CustomLogging.push('checkFeatureFlag', 'TS_CreateOperatingTaskController'); 

        Boolean enabledFeature = false;
        Map<Id,TS_Feature_Flag__mdt> featureFlags =  new Map<Id,TS_Feature_Flag__mdt>([SELECT Id, QualifiedApiName, Enable__c FROM TS_Feature_Flag__mdt WHERE QualifiedApiName != null]);
        if(!featureFlags.isEmpty()){
            for(TS_Feature_Flag__mdt flag : featureFlags.values()){
                //Karen Hung DOO-5269 2/3/2021
                if(flag.Enable__c){
                    if(flag.QualifiedApiName == 'DOO_5308_Manual_S20_for_3PO') enabledFeature= true;
                    if(flag.QualifiedApiName == 'DOO_5269_Operating_Task_Bucket') operatingBucketEnabled = true;
                }
            }
        }
        
        CustomLogging.pop();
        return enabledFeature;
    }

    @AuraEnabled
    public static String createOperatingTask(Id paId, String salesOrg, Id accLocId, String woType, String taskActType, DateTime slaDate, DateTime earlyStartDate, String description) {
        CustomLogging.push('createOperatingTask', 'TS_CreateOperatingTaskController');
        String ret;
        
        //Karen Hung 25/2/2021 DOO-5308 populate executing engineer if type is small or cups and account location has third party operator
        Id thirdPartyOperator = [SELECT Id,Third_Party_Resource__c FROM Apttus_Config2__AccountLocation__c WHERE Id= :accLocId][0]?.Third_Party_Resource__c;
        
		if(!Test.isRunningTest()) thirdPartyS20Enabled = checkFeatureFlag();
                
        WorkOrder wo = new WorkOrder();
        wo.OP_Physical_Asset__c = paId != null ? paId : null;
        wo.SalesOrganization__c = salesOrg != null ? salesOrg : null;
        wo.Account_Location__c = accLocId != null ? accLocId : null;
        wo.WorkOrderType__c = woType != null ? woType : null;
        wo.Task_Activity_Type__c = taskActType != null ? taskActType : null;
        if(woType != null && woType == 'S20'){
            wo.SLA_Date__c = slaDate != null ? slaDate : null;
            wo.Early_Start_Date__c = earlyStartDate != null ? earlyStartDate : null;
        }
        //Karen Hung DOO-5101 22.12.2020
        if(woType != null && woType == 'S22' && description != '' && description != null){
        	wo.Description = description;
        }
        
        //Karen Hung DOO-5269 2/3/2021
        if(operatingBucketEnabled) wo.OPG_Source__c = 'Manual';
        
        //Karen Hung DOO-5308 25.2.2021
        if(thirdPartyS20Enabled && thirdPartyOperator != null && (taskActType.contains(TS_Constants.ACTIVITY_SMALL) || taskActType.contains(TS_Constants.ACTIVITY_CUPS))){
            wo.Third_Party__c = true;
			wo.Status = TS_Constants.WOLI_STATUS_SCHEDULED;
            wo.ExecutingEngineer__c = thirdPartyOperator;
            wo.Travel_Start_Time__c = earlyStartDate;
            wo.Travel_Stop_Time__c = earlyStartDate;
            wo.StartDate__c = earlyStartDate;
            wo.EndDate__c = earlyStartDate;                
        }
        
        try {
            insert wo;
            ret = String.ValueOf(wo.Id);
        } 
        catch(Exception ex) {
            ret = 'ERROR';
            CustomLogging.debugException(ex);
            CustomLogging.pop();
        }
        return ret;
    }
    
    /*
    * @author        Karen Hung
    * @date          18.08.2020
    * @description   DOO-4807 method to check if machine is part of a route 
    * @revision(s)
    */
    @AuraEnabled
    public static Boolean noRoute(Id paId){
        CustomLogging.push('noRoute', 'TS_CreateOperatingTaskController');
        Boolean emptyRoute = false;
            List<Route_Line_Item__c> itemList = [SELECT Id FROM Route_Line_Item__c WHERE PhysicalAssetId__c = :paId];
            if(itemList.isEmpty() || itemList == null){
                emptyRoute = true;
            }
        CustomLogging.pop();
        return emptyRoute;
    }    
}