/**
    * @author        Alvin Lomod
    * @date          19.01.2018 - Alvin Lomod KASM-1017         
    * @description   Update all Contacts' Last Relevant Activity Date under Event's Contact Attendees
    * @revision(s)   
    */

public with sharing class UpdateEventContacts{
    @InvocableMethod
    public static void UpdateContactFromEventAttendees(List<Id> EventIds){
        CustomLogging.push('UpdateContactFromEventAttendees', 'UpdateEventContacts');
        List<EventRelation> erList = new List<EventRelation>();
        try{
            
        
            if (Schema.sObjectType.EventRelation.fields.RelationId.isAccessible() && Schema.sObjectType.EventRelation.fields.EventId.isAccessible()){
            	erList = [SELECT RelationId FROM EventRelation WHERE EventId in: EventIds AND Relation.Type = 'Contact' LIMIT 5000];
            }
            
            if(erList.size() > 0){
                Set<Id> conIds = new Set<Id>();
                
                //Get all contactIds
                for(EventRelation er : erList){
                    conIds.add(er.RelationId);
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