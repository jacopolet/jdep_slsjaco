/**
    * @author        Alvin Lomod
    * @date          07.02.2018 - Alvin Lomod KASM-1017         
    * @description   Update all Contacts' Last Relevant Activity Date under Task's Contact Relations
    * @revision(s)   
    */

public with sharing class UpdateTaskContacts{
    @InvocableMethod
    public static void UpdateContactFromTaskRelation(List<Id> TaskIds){
        CustomLogging.push('UpdateContactFromTaskRelation', 'UpdateTaskContacts');
        List<TaskRelation> tsList = new List<TaskRelation>();
        try{
            
            if (Schema.sObjectType.TaskRelation.fields.RelationId.isAccessible() && Schema.sObjectType.TaskRelation.fields.TaskId.isAccessible()){
            	tsList = [SELECT RelationId FROM TaskRelation WHERE TaskId in: TaskIds AND Relation.Type = 'Contact' LIMIT 5000];
        	}
            
            if(tsList.size() > 0){
                Set<Id> conIds = new Set<Id>();
                
                //Get all contactIds
                for(TaskRelation ts : tsList){
                    conIds.add(ts.RelationId);
                }
                
                //Update all contacts that are NOT Service Provider record types
                List<Contact> conList = new List<Contact>();
                
                if(Schema.sObjectType.Contact.fields.Id.isAccessible() && Schema.sObjectType.Contact.fields.Last_Relevant_Activity_Date__c.isAccessible() && Schema.sObjectType.Contact.fields.IsActive__c.isAccessible() && Schema.sObjectType.Contact.fields.Archiving_Flag__c.isAccessible()){
                	
                    conList = [SELECT Id, Last_Relevant_Activity_Date__c, IsActive__c, Archiving_Flag__c FROM Contact WHERE Id in: conIds AND RecordTypeId !=: Schema.SObjectType.Contact.getRecordTypeInfosByName().get(SM_Constants.ContactServiceProvider).getRecordTypeId()];
                    
                    List<Contact> updatedConList = new List<Contact>();
                    Boolean isChanged = false;
                    for(Contact con : conList){
                        system.debug('***' + Con);
                        isChanged = false;
                        
                        if(con.Last_Relevant_Activity_Date__c == null || con.Last_Relevant_Activity_Date__c < Date.today()){
                            con.Last_Relevant_Activity_Date__c = Date.today();
                            
                            isChanged = true;
                        }
                        if(!con.IsActive__c){
                            
                            con.IsActive__c = true;
                            
                            isChanged = true;
                            if(con.Archiving_Flag__c){
                                con.Archiving_Flag__c = false;
                            }
                        }
                        
                        if(isChanged){
                            updatedConList.add(con);
                        }
                        
                    }
                    
                    if(updatedConList.size() > 0){
                        
                        if(Schema.sObjectType.Contact.fields.Last_Relevant_Activity_Date__c.isUpdateable()){
                            update updatedConList;
                        }
                        
                    }
                }
            }
        } catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
    }
}