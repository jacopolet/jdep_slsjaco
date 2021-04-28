/**
* @author        Karen Hung
* @date          11/15/18          
* @description   controller for TS_CloneSchedule lightning component
* @revision(s)   
*/
public with sharing class TS_CloneScheduleController {
    
    public class TS_CloneScheduleControllerException extends Exception {}
    
    public static Boolean hasException = false;
    
    /*returns list of physical assets under the same account location*/
    @AuraEnabled
    public static List<PhysicalAssetWrapper> getPAs(String opschedId){
        CustomLogging.push('getPAs','TS_CloneScheduleController');
        List<PhysicalAssetWrapper> newWrap = new List<PhysicalAssetWrapper>();
        Id accLocId = [SELECT Account_Location__r.id FROM OperatingSchedule__c where Id = :opschedId LIMIT 1][0].Account_Location__c;
        Id pId = [SELECT PhysicalAsset__r.Id FROM OperatingSchedule__c where Id = :opschedId LIMIT 1][0].PhysicalAsset__c;
        //FOR EDIT QUERY- add  AND AccountLocation__c =:accLocId in query
        String machineTypeId = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get(TS_Constants.PA_RECTYPE_MACHINE).getRecordTypeId(); 
        Map<Id, PhysicalAsset__c> physicalAssets = new Map<Id, PhysicalAsset__c> ([SELECT Id,Floor__c,UniqueNumber__c,AccountLocation__r.Name,AccountLocation__c,Building__c,Area__c,CustomerReferenceNumber__c 
                                                                                   FROM PhysicalAsset__c 
                                                                                   WHERE ID != :pId
                                                                                   AND (Machine_Care__c ='Full Operating' OR Machine_Care__c = 'Comfort Operating')
                                                                                   AND (AssetStatus__c ='Pending Activation' OR AssetStatus__c = 'Activated')
                                                                                   AND RecordTypeId =:machineTypeId
                                                                                   AND AccountLocation__c =:accLocId                                                                              
                                                                                   AND AccountLocation__c !=null]); 
       
        Map<Id,OperatingSchedule__c> paSchedMap = new Map<Id,OperatingSchedule__c>();
        for(OperatingSchedule__c opSched: [SELECT PhysicalAsset__c FROM OperatingSchedule__c WHERE PhysicalAsset__c IN :physicalAssets.keySet()]){
            paSchedMap.put(opSched.PhysicalAsset__c,opSched);    
        }
        for(PhysicalAsset__c pa : physicalAssets.values()){
            PhysicalAssetWrapper paWrapper = new PhysicalAssetWrapper();
            paWrapper.uniqueNum = pa.UniqueNumber__c;
            paWrapper.building = pa.Building__c;
            paWrapper.area = pa.Area__c;
            paWrapper.floor = pa.Floor__c;
            paWrapper.custRef = pa.CustomerReferenceNumber__c;
            paWrapper.accountLoc = pa.AccountLocation__r.Name;
            if(paSchedMap.containsKey(pa.Id)){
                paWrapper.hasSched = true;    
            }else{
                paWrapper.hasSched = false;
            }           
            paWrapper.id = pa.Id;
            
            newWrap.add(paWrapper);
        }
        CustomLogging.pop();
        return newWrap;   
    }
    
    /*method to create/cloned operating schedule*/
    @AuraEnabled
    public static Integer createOpSched(String wrapperList,String opId){
        CustomLogging.push('createOpSched','TS_CloneScheduleController');
        system.debug('test');
        system.debug('wrapperList' + wrapperList);
        List<PhysicalAssetWrapper> wrapList = (List<PhysicalAssetWrapper>)System.JSON.deserialize(wrapperList, List<PhysicalAssetWrapper>.class); 
        //set old opSched of physical asset to inactive if active=true
        Set<Id> paId = new Set<Id>();
        
        for(PhysicalAssetWrapper pw :wrapList){
            paId.add(pw.id);
        }
        Map<Id, OperatingSchedule__c> optoUpdateMap = new Map<Id, OperatingSchedule__c>([SELECT ID, Active__c FROM OperatingSchedule__c WHERE PhysicalAsset__c IN :paId AND Active__c = true]);    
        for(OperatingSchedule__c op : optoUpdateMap.values()){
            op.Active__c = false;
            op.UniqueSchedule__c = null;
            op.Comment__c = 'Deactivated from cloning schedule. ' + system.now();
        }

        try{
            
            if(!optoUpdateMap.values().isEmpty() && Schema.sObjectType.OperatingSchedule__c.isUpdateable()){
                database.update(optoUpdateMap.values());
            }
            
        }catch(Exception ex){

            throw new AuraHandledException('Record Update error: ' +ex);
        }
        //clone opSched
        
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType opSchema = schemaMap.get('OperatingSchedule__c');
        Map<String, Schema.SObjectField> fieldMap = opSchema.getDescribe().fields.getMap();        
        
        DescribeSObjectResult operatingScheduleDescribe = OperatingSchedule__c.getSObjectType().getDescribe();
        List<String> fields = new List<String>(operatingScheduleDescribe.fields.getMap().keySet());
        String query = 'SELECT '+ String.join(fields, ',') + ' FROM OperatingSchedule__c WHERE ID =' + '\'' + opId + '\'';
        OperatingSchedule__c opSched = database.query(query);
        List<OperatingSchedule__c> optoCreate = new List<OperatingSchedule__c>();
        for(PhysicalAssetWrapper paWrap : wrapList){
            //try field set
            OperatingSchedule__c newOp2 = new OperatingSchedule__c();
            for(Schema.FieldSetMember fieldMem :Schema.SObjectType.OperatingSchedule__c.fieldSets.getMap().get('CloneFields').getFields()) {
                if(opSched.get(fieldMem.getFieldPath()) !=null){
                    newOp2.put(fieldMem.getFieldPath(), opSched.get(fieldMem.getFieldPath()));
                }
            }
            newOp2.Active__c = true;
            newOp2.PhysicalAsset__c = paWrap.id; 
            
            //old code
            /*OperatingSchedule__c newOp = new OperatingSchedule__c();
            newOp.Active__c = true;
            newOp.RecordTypeId = opSched.RecordTypeId;
            newOp.Account_Location__c = opSched.Account_Location__c;
            newOp.OP_Business_Hours__c = opSched.OP_Business_Hours__c;
            newOp.C_1_Monday__c = opSched.C_1_Monday__c;
            newOp.C_2_Wednesday__c = opSched.C_2_Wednesday__c;
            newOp.C_2_Thursday__c = opSched.C_2_Thursday__c;
            newOp.C_2_Friday__c = opsched.C_2_Friday__c;
            newOp.C_2_Saturday__c = opSched.C_2_Saturday__c;
            newOp.C_2_Sunday__c = opSched.C_2_Sunday__c;
            newOp.C_1_Tuesday__c = opSched.C_1_Tuesday__c;
            newOp.C_1_Wednesday__c = opSched.C_1_Wednesday__c;
            newOp.C_1_Thursday__c = opSched.C_1_Thursday__c;
            newOp.C_1_Friday__c = opsched.C_1_Friday__c;
            newOp.C_1_Saturday__c = opSched.C_1_Saturday__c;
            newOp.C_1_Sunday__c = opSched.C_1_Sunday__c;
            newOp.C_2_Monday__c = opsched.C_2_Monday__c;
            newOp.C_2_Tuesday__c = opSched.C_2_Tuesday__c;
            newOp.CurrencyIsoCode = opSched.CurrencyIsoCode;
            newOp.Cycle_in_Weeks__c = opSched.Cycle_in_Weeks__c;
            newOp.ForceScheduleToNextBusinessDay__c = opsched.ForceScheduleToNextBusinessDay__c;
            newOp.Initial_Re_activation_Date__c = opSched.Initial_Re_activation_Date__c;
            newOp.Interval_in_Weeks__c = opSched.Interval_in_Weeks__c;
            newOp.LM_1_Monday__c = opSched.LM_1_Monday__c;
            newOp.LM_2_Wednesday__c = opSched.LM_2_Wednesday__c;
            newOp.LM_2_Thursday__c = opSched.LM_2_Thursday__c;
            newOp.LM_2_Friday__c = opSched.LM_2_Friday__c;
            newOp.LM_2_Saturday__c = opsched.LM_2_Saturday__c;
            newOp.LM_2_Sunday__c = opSched.LM_2_Sunday__c;
            newOp.LM_1_Tuesday__c = opSched.LM_1_Tuesday__c;
            newOp.LM_1_Wednesday__c = opSched.LM_1_Wednesday__c;
            newOp.LM_1_Thursday__c = opSched.LM_1_Thursday__c;
            newOp.LM_1_Friday__c = opSched.LM_1_Friday__c;
            newOp.LM_1_Saturday__c = opSched.LM_1_Saturday__c;
            newOp.LM_1_Sunday__c = opSched.LM_1_Sunday__c;
            newOp.LM_2_Monday__c = opSched.LM_2_Monday__c;
            newOp.LM_2_Tuesday__c = opSched.LM_2_Tuesday__c;
            newOp.Last_Batch_Date__c = opSched.Last_Batch_Date__c;
            newOp.PhysicalAsset__c = paWrap.id;
            newOp.PreferredOperator__c = opSched.PreferredOperator__c;
            newOp.R_1_Monday__c = opSched.R_1_Monday__c;
            newOp.R_2_Wednesday__c = opSched.R_2_Wednesday__c;
            newOp.R_2_Thursday__c = opsched.R_2_Thursday__c;
            newOp.R_2_Friday__c = opSched.R_2_Friday__c;
            newOp.R_2_Saturday__c = opSched.R_2_Saturday__c;
            newOp.R_2_Sunday__c = opSched.R_2_Sunday__c;
            newOp.R_1_Tuesday__c = opSched.R_1_Tuesday__c;
            newOp.R_1_Wednesday__c = opSched.R_1_Wednesday__c;
            newOp.R_1_Thursday__c = opSched.R_1_Thursday__c;
            newOp.R_1_Friday__c = opSched.R_1_Friday__c;
            newOp.R_1_Saturday__c = opSched.R_1_Saturday__c;
            newOp.R_1_Sunday__c = opSched.R_1_Sunday__c;
            newOp.R_2_Monday__c = opSched.R_2_Monday__c;
            newOp.R_2_Tuesday__c = opSched.R_2_Tuesday__c;
            newOp.Sales_Organization__c = opSched.Sales_Organization__c;
            newOp.Schedule_Tasks_for_Holiday__c = opSched.Schedule_Tasks_for_Holiday__c;
            newOp.Schedule_Type__c = opSched.Schedule_Type__c;
            newOp.SM_1_Monday__c = opSched.SM_1_Monday__c;
            newOp.SM_2_Wednesday__c = opSched.SM_2_Wednesday__c;
            newOp.SM_2_Thursday__c = opSched.SM_2_Thursday__c;
            newOp.SM_2_Friday__c = opSched.SM_2_Friday__c;
            newOp.SM_2_Saturday__c = opSched.SM_2_Saturday__c;
            newOp.SM_2_Sunday__c = opSched.SM_2_Sunday__c;
            newOp.SM_1_Tuesday__c = opSched.SM_1_Tuesday__c;
            newOp.SM_1_Wednesday__c = opSched.SM_1_Wednesday__c;
            newOp.SM_1_Thursday__c = opSched.SM_1_Thursday__c;
            newOp.SM_1_Friday__c = opsched.SM_1_Friday__c;
            newOp.SM_1_Saturday__c = opSched.SM_1_Saturday__c;
            newOp.SM_1_Sunday__c = opSched.SM_1_Sunday__c;
            newOp.SM_2_Monday__c = opSched.SM_2_Monday__c;
            newOp.SM_2_Tuesday__c = opSched.SM_2_Tuesday__c;
            newOp.Specific_Days_in_Week__c = opSched.Specific_Days_in_Week__c;
            newOp.Start_Date__c = opSched.Start_Date__c;
            newOp.TaskRescheduleLogic__c = opsched.TaskRescheduleLogic__c;
            //newOp.UniqueSchedule__c = paWrap.uniqueNum + ''+ opsched.Active__c+newOp.Name;
            newOp.UniqueSchedule__c = 'TRUE'+paWrap.Id+System.now();*/
            optoCreate.add(newOp2);        
        }

        try{
            if(!optoCreate.isEmpty() && Schema.sObjectType.OperatingSchedule__c.isCreateable()){
                database.insert(optoCreate);
            }
            
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_CloneScheduleControllerException('Force to throw an exception');
            }

        }catch(Exception e){
            throw new AuraHandledException('Error in creating record: ' + e);
        }
        CustomLogging.pop();
        return [SELECT ID from OperatingSchedule__c WHERE ID IN :optoCreate].size();
           
    }
    
    /*for data table*/
    public class PhysicalAssetWrapper{
        @AuraEnabled public String uniqueNum {get;set;}
        @AuraEnabled public String building {get;set;}
        @AuraEnabled public String area {get;set;}
        @AuraEnabled public String floor {get;set;}
        @AuraEnabled public String custRef {get;set;}
        @AuraEnabled public String accountLoc {get;set;}
        @AuraEnabled public Boolean hasSched {get;set;}
        @AuraEnabled public String id {get;set;}
    }
        
        
    
}