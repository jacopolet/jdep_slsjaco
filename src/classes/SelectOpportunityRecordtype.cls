public without sharing class SelectOpportunityRecordtype {
    public static Map<Id, String> recordtypemap {get;set;}
    public static Map<Id, String> standardRtMap {get;set;}
    public static Map<Id, String> otherRtMap {get;set;}
    
   @AuraEnabled
    public static String getNamefield(String taskId){
        CustomLogging.push('getNamefield', 'SelectOpportunityRecordtype');
        Task nameId = new Task();
        String result;
        try{
            
            nameId = [Select WhoId from task where id =: taskId];   
            if (nameId.WhoId != null){
                if (String.valueOf(nameId.WhoId).left(3) == '00Q'){
                    result = 'Lead';
                }
                else {
                    result = 'Not a Lead';
                }
            }
            else {
                result = 'Not a Lead';
            }
            
        return result;
        } catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
            return null;
        }
        
    }
    
   @AuraEnabled        
    public static List<String> fetchRecordTypeValues(){
        CustomLogging.push('fetchRecordTypeValues', 'SelectOpportunityRecordtype');
        try{
            
            List<Schema.RecordTypeInfo> recordtypes = Opportunity.SObjectType.getDescribe().getRecordTypeInfos();    
            recordtypemap = new Map<Id, String>();
            standardRtMap = new Map<Id, String>();
            otherRtMap = new Map<Id, String>();
            
            for(RecordTypeInfo rt : recordtypes){
                if(rt.getName() != 'Master') { 
                    if (rt.getName() == SM_Constants.OppStandardRT) {
                        standardRtMap.put(rt.getRecordTypeId(), rt.getName());
                    } else {
                        otherRtMap.put(rt.getRecordTypeId(), rt.getName());
                    }                
                }
            }
            
            for (Id standardRt : standardRtMap.keyset()) {
                recordtypemap.put(standardRt,standardRtMap.get(standardRt));
            }     
            
            for (Id otherRt : otherRtMap.keyset()) {
                recordtypemap.put(otherRt,otherRtMap.get(otherRt));
            }
        
        } catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
          
        return recordtypemap.values();
    }
    
    @AuraEnabled
    public static Id getRecTypeId(String recordTypeLabel){
        CustomLogging.push('getRecTypeId', 'SelectOpportunityRecordtype');
        Id recid;
        try{
            
            recid = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(recordTypeLabel).getRecordTypeId();       
            return recid;
        
        } catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
            return null;
        }
        
    }
    
    @AuraEnabled        
    public static Id getAccountId(Id taskId){
        CustomLogging.push('getAccountId', 'SelectOpportunityRecordtype');
        Task actRecId = new Task();
        try{
            
            if (Schema.sObjectType.Task.fields.Account__c.isAccessible()){
                actRecId = [Select Account__c from task where id =: taskId];
                
            } 
            return actRecId.Account__c;
        
        } catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
            return Null;
        }
       
    }
    
    @AuraEnabled        
    public static String getTouchpointType(Id taskId){
        CustomLogging.push('getTouchpointType', 'SelectOpportunityRecordtype');
        Task taskRec = new Task();
        try{
            
            if (Schema.sObjectType.Task.fields.Touchpoint_Type__c.isAccessible()){
                taskRec = [Select Touchpoint_Type__c from task where id =: taskId];
            } 
            return taskRec.Touchpoint_Type__c;
        
        } catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
            return null;
        }
        
    }
    
    @AuraEnabled        
    public static String getCampaign(Id taskId){
        CustomLogging.push('getCampaign', 'SelectOpportunityRecordtype');
        Task taskRec = new Task();
        try{
            
            if (Schema.sObjectType.Task.fields.Touchpoint_Type__c.isAccessible()){
                taskRec = [Select Campaign__c from task where id =: taskId];
            } 
            return taskRec.Campaign__c;
        
        } catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
            return null;
        }
        
    }
}