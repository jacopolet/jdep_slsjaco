/**
* Class Name: AssetLineItemSharingRecalc 
* @author: Alvin Lomod
* Date: 30-Oct-2017
* Requirement: KASM-228
* @description: Batch process to recalculate Asset Line Item sharing.
*
*/

global without sharing class AssetLineItemSharingRecalc implements Database.Batchable<sObject> {
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([SELECT Id, Apttus_Config2__AccountId__c, Name 
                                         FROM Apttus_Config2__AssetLineItem__c WHERE Apttus_Config2__AccountId__r.isPartner =: true]);  
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        CustomLogging.push('execute', 'AssetLineItemSharingRecalc');
        
        // Create a map for the chunk of records passed into method.
        Map<ID, Apttus_Config2__AssetLineItem__c> ALIMap = new Map<ID, Apttus_Config2__AssetLineItem__c>((List<Apttus_Config2__AssetLineItem__c>)scope);  
        
        // Create a list of Apttus_Config2__AssetLineItem__share objects to be inserted.
        List<Apttus_Config2__AssetLineItem__share> NewALIshares = new List<Apttus_Config2__AssetLineItem__share>();
               
        // Locate all existing sharing records for the ALI records in the batch.
        // Only records using an Apex sharing reason for this app should be returned. 
        List<Apttus_Config2__AssetLineItem__share> OldALIshares = [SELECT Id, ParentId, RowCause FROM Apttus_Config2__AssetLineItem__share WHERE ParentId IN: ALIMap.keySet() AND RowCause =: Schema.Apttus_Config2__AssetLineItem__Share.RowCause.Asset_Line_Item_Apex_Sharing__c];
        
        
        Set<Id> PartnerAccSetIds = new Set<Id>();
        List<User> PartnerUserList = new List<User>();
        
        //Get all Account Ids related to the Asset Line Items
        for(Apttus_Config2__AssetLineItem__c ali : ALIMap.values()){
            PartnerAccSetIds.add(ali.Apttus_Config2__AccountId__c);
            
        }
        
        if(Schema.sObjectType.User.fields.ContactId.isAccessible() &&
            Schema.sObjectType.User.fields.Id.isAccessible() &&
            Schema.sObjectType.User.fields.Name.isAccessible()){
               
            PartnerUserList = [SELECT Id, ContactId, Contact.AccountId, Contact.Account.Name, Name FROM User WHERE Contact.AccountId in: PartnerAccSetIds];
        }
        
        system.debug('Partner User List :' + PartnerUserList);
        
        
        if(PartnerUserList.size() > 0){
            
            Apttus_Config2__AssetLineItem__share ALIshare = new Apttus_Config2__AssetLineItem__share();
            
            //Create Asset Line Item Share. Grouped by asset line item's account
            for(Apttus_Config2__AssetLineItem__c ali : ALIMap.values()){
                
                for(User u : PartnerUserList){
                    
                    if(u.Contact.AccountId == ali.Apttus_Config2__AccountId__c){
                        ALIshare = new Apttus_Config2__AssetLineItem__Share();
                        ALIshare.ParentId = ali.Id;
                        ALIshare.UserOrGroupId = u.Id;
                        ALIshare.AccessLevel = 'Read';
                        ALIshare.RowCause = Schema.Apttus_Config2__AssetLineItem__Share.RowCause.Asset_Line_Item_Apex_Sharing__c; //To distinguish the Sharing Reason
                        
                        NewALIshares.add(ALIshare);                
                    }
                }
                
                system.debug('ALIShare Current Size: ' + NewALIshares.size());
            }
            
            system.debug('ALIShare Total Size: ' + NewALIshares.size());
        }
        
        
        try{
                
            //Delete sharing from old related account first
            if(Apttus_Config2__AssetLineItem__Share.sObjectType.getDescribe().isDeletable()){
                
                delete OldALIshares;
            }
            
            //insert asset line item user sharing
            if(Schema.sObjectType.Apttus_Config2__AssetLineItem__Share.fields.ParentId.isCreateable() &&
               Schema.sObjectType.Apttus_Config2__AssetLineItem__Share.fields.UserOrGroupId.isCreateable() &&
               Schema.sObjectType.Apttus_Config2__AssetLineItem__Share.fields.AccessLevel.isCreateable() &&
               Schema.sObjectType.Apttus_Config2__AssetLineItem__Share.fields.RowCause.isCreateable()){
                   
                   insert NewALIshares;
               }
           
        }catch(Exception ex){
            
            CustomLogging.debugException(ex);
            CustomLogging.pop();      
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
            
        }
    }
    
    // The finish method is called at the end of a sharing recalculation.
    global void finish(Database.BatchableContext BC){  
        // Send an email to the Apex job's submitter notifying of job completion.
        
        AsyncApexJob a = [SELECT Id, Status, ExtendedStatus, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email 
                          FROM AsyncApexJob where Id =:BC.getJobId()];
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {a.CreatedBy.Email}; 
        mail.setToAddresses(toAddresses); 
        mail.setSubject('Apex Sharing Recalculation Completed.');
        mail.setPlainTextBody
                      ('The Apex sharing recalculation finished processing');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}