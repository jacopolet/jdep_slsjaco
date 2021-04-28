//-------------------------------------------------------------------------------------------//
// Author       :   Glenn Serrano - Accenture
// Created Date :   2021-03-10
// Usage        :   Opt In From Salesforce
//                  This has been created to create Contact Point Type Consents for NBA
//-------------------------------------------------------------------------------------------//
public without sharing class SM_OptInClassFromSF {
	@InvocableMethod
    public static List<String> createContactPointTypeConsent(List<Id> ListID){
        List<String> parsetextlist = new List<String>();
        List<Contact> contactList = new List<Contact>();
        List<Journey_Trigger__c> journeytriggerinsert = new List<Journey_Trigger__c>();
        List<Contact> contacts = [Select Id, IndividualId, Consent_Status_Profiling__c, Consent_Status_Marketing__c, Name FROM Contact WHERE Id IN :ListID];
        Map<String, String> datausepurposeIds = fetchDataUsePurposeIds();
        Map<String, ContactPointTypeConsent> updatecontact = new Map<String, ContactPointTypeConsent>();
        List<ContactPointTypeConsent> cptcinsert = new List<ContactPointTypeConsent>();
        
        String parsetextvalue;
        // Create Contact Point Type Consent
        if (contacts != null){
            for (Contact contactrec : contacts){
                //if (contactrec.Consent_Status_Profiling__c == null){
                //    ContactPointTypeConsent cptcvaluesforinsert = new ContactPointTypeConsent();
                //    cptcvaluesforinsert.Name = contactrec.Name + ' profiling ' + string.valueOf(System.now());
                //    cptcvaluesforinsert.CaptureDate = System.now();
                //    cptcvaluesforinsert.DataUsePurposeId = datausepurposeIds.get('profiling');
                //    cptcvaluesforinsert.CaptureContactPointType = 'Phone';
                //    cptcvaluesforinsert.ContactPointType = 'Email';
                //    cptcvaluesforinsert.Consent_Text_Version__c = '1';
                //    cptcvaluesforinsert.PartyId = contactrec.IndividualId;
                //    cptcvaluesforinsert.PrivacyConsentStatus = 'Seen';
                //    cptcvaluesforinsert.CaptureSource = 'Sales Cloud';
                //    cptcinsert.add(cptcvaluesforinsert);
                //    updatecontact.put('profiling', cptcvaluesforinsert);
                //}
                
                if (contactrec.Consent_Status_Marketing__c == null){
                    ContactPointTypeConsent cptcvaluesforinsert = new ContactPointTypeConsent();
                    cptcvaluesforinsert.Name = contactrec.Name + ' marketing ' + string.valueOf(System.now());
                    cptcvaluesforinsert.CaptureDate = System.now();
                    cptcvaluesforinsert.DataUsePurposeId = datausepurposeIds.get('marketing');
                    cptcvaluesforinsert.CaptureContactPointType = 'Phone';
                    cptcvaluesforinsert.ContactPointType = 'Email';
                    cptcvaluesforinsert.Consent_Text_Version__c = '1';
                    cptcvaluesforinsert.PartyId = contactrec.IndividualId;
                    cptcvaluesforinsert.PrivacyConsentStatus = 'Seen';
                    cptcvaluesforinsert.CaptureSource = 'Sales Cloud';
                    cptcinsert.add(cptcvaluesforinsert);
                    updatecontact.put('marketing', cptcvaluesforinsert);
                }
            }
            
            if (!cptcinsert.isEmpty()){
				insert cptcinsert;                
            }
            // Update Lead and return parsevalue for Marketing
            if (updatecontact != null){
                if (updatecontact.containsKey('marketing')){
                    parsetextvalue = updatecontact.get('marketing').Id + '|marketing^';
                }
                
                //if (updatecontact.containsKey('profiling')){
                //    if (parsetextvalue != null){
                //        parsetextvalue = parsetextvalue + updatecontact.get('profiling').Id + '|profiling^';
                //    } else {
                //        parsetextvalue = updatecontact.get('profiling').Id + '|profiling^';
                //    }
                //    
                //}
                
                if (parsetextvalue != null){
                    for (Contact c : contacts){
                        Contact contactval = new Contact();
                        contactval.Id = c.Id;
                        //if (c.Consent_Status_Profiling__c == null){
                        //    contactval.Consent_Status_Profiling__c = 'Pending';
                        //    contactval.Consent_Version_Profiling__c = 1;
                        //}
                        if (c.Consent_Status_Marketing__c == null){
                            contactval.Consent_Status_Marketing__c = 'Pending';
                            contactval.Consent_Version_Marketing__c = 1;
                        }
                        contactval.Consent_Registration_Date__c = System.today();
                        contactlist.add(contactval);
                    }
                    
                    if (contactlist != null && !contactlist.isEmpty()){
                        update contactlist;
                    }
                }
            }
            parsetextlist.add(parsetextvalue.removeEnd('^'));
        }
        return parsetextlist;
    }  
    
    private static Map<String,String> fetchDataUsePurposeIds(){
        Map <String, String> datausepurposeIds = new Map<String, String>();
        List<DataUsePurpose> datausepurposerec = new List<DataUsePurpose>();
      	datausepurposerec = [Select Id, Name from DataUsePurpose];
        for (DataUsePurpose duprec : datausepurposerec){
            if (duprec.Name == 'marketing'){
                datausepurposeIds.put('marketing', duprec.Id);
            } else if (duprec.Name == 'survey'){
                datausepurposeIds.put('survey', duprec.Id);
            } else {
                if (duprec.Name == 'profiling'){
                    datausepurposeIds.put('profiling', duprec.Id);
                }
            }
        }
        
        return datausepurposeIds;
  }
}