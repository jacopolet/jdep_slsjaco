//-------------------------------------------------------------------------------------------//
// Author       :   Catherine Aragon - Accenture
// Created Date :   2020-04-17
// Usage        :   Archive Contact without user access on related account
//                  This has been created as standalone flow runs in user sharing
//-------------------------------------------------------------------------------------------//
public without sharing class SM_ArchiveContact {
	@InvocableMethod
    public static void archiveContact(List<Id> ListID){
        List<Contact> contactList = new List<Contact>();
        List<Contact> contacts = [Select Id, AccountId, Sales_Organization__c FROM Contact WHERE Id IN :ListID];
        Id archiveUser = [Select Id FROM User WHERE Name = :'JDE-Apex-Batch'].Id;
        list<AccountContactRelation> deleteAccountContactRel = new list<AccountContactRelation>();
        Map<String,String> salesorgarchiveaccount = SM_GetMetadata.getsalesorgarchiveaccount();
        
        
        for (Contact contact: contacts) {
            contact.Prior_Account__c = contact.AccountId;
            contact.Archiving_Flag__c = true;
            contact.Archiving_Time__c = Datetime.now();
            contact.Contact_Status__c = 'Not Valid';
            contact.OwnerId = archiveUser;
            contact.Consent_Status_Marketing__c = 'Opt-Out';
            contact.Consent_Status_Profiling__c = 'Opt-Out';
            contact.Consent_Status_Surveys__c = 'Opt-Out';
            contact.Main_Service_Person__c = false;
            contact.Main_Commercial_Person__c = false;
            if (salesorgarchiveaccount.containsKey(contact.Sales_Organization__c)){
                contact.AccountId = salesorgarchiveaccount.get(contact.Sales_Organization__c);
            }
            contactList.add(contact);
        }

        if (!contactList.isEmpty()) {
            update contactList;
        }
        
        List<Contact> getUpdatedcontacts = [Select Id, AccountId, Prior_Account__c FROM Contact WHERE Id IN :contactList];
        
        //delete account contact relationship
        for(AccountContactRelation accConRel : [Select Id, AccountId, IsDirect FROM AccountContactRelation where ContactId IN :getUpdatedcontacts]) { 
            for (Contact contact: getUpdatedcontacts) {
                if (contact.Prior_Account__c == accConRel.AccountId && accConRel.IsDirect == false) {
                    deleteAccountContactRel.add(accConRel);
                }
            }
        }
        
        if (!deleteAccountContactRel.isEmpty()) {
            delete deleteAccountContactRel;
        }
    }
}