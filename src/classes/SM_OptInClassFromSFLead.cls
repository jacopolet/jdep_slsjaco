//-------------------------------------------------------------------------------------------//
// Author       :   Glenn Serrano - Accenture
// Created Date :   2021-03-10
// Usage        :   Opt In From Salesforce
//                  This has been created to create Contact Point Type Consents for NBA
//-------------------------------------------------------------------------------------------//
public without sharing class SM_OptInClassFromSFLead {
	@InvocableMethod
    public static List<String> createContactPointTypeConsent(List<Id> ListID){
        List<String> parsetextlist = new List<String>();
        List<Lead> contactList = new List<Lead>();
        List<Journey_Trigger__c> journeytriggerinsert = new List<Journey_Trigger__c>();
        List<Lead> leads = [Select Id, IndividualId, Consent_Status_Profiling__c, Consent_Status_Marketing__c, Name FROM Lead WHERE Id IN :ListID];
        Map<String, String> datausepurposeIds = fetchDataUsePurposeIds();
        Map<String, ContactPointTypeConsent> updatecontact = new Map<String, ContactPointTypeConsent>();
        List<ContactPointTypeConsent> cptcinsert = new List<ContactPointTypeConsent>();
        
        String parsetextvalue;
		//Create Contact Point Type Consent where needed        
        if (leads != null){
            for (Lead leadrec : leads){
                if (leadrec.Consent_Status_Profiling__c == null){
                    ContactPointTypeConsent cptcvaluesforinsert = new ContactPointTypeConsent();
                    cptcvaluesforinsert.Name = leadrec.Name + ' profiling ' + string.valueOf(System.now());
                    cptcvaluesforinsert.CaptureDate = System.now();
                    cptcvaluesforinsert.DataUsePurposeId = datausepurposeIds.get('profiling');
                    cptcvaluesforinsert.CaptureContactPointType = 'Phone';
                    cptcvaluesforinsert.ContactPointType = 'Email';
                    cptcvaluesforinsert.Consent_Text_Version__c = '1';
                    cptcvaluesforinsert.PartyId = leadrec.IndividualId;
                    cptcvaluesforinsert.PrivacyConsentStatus = 'Seen';
                    cptcvaluesforinsert.CaptureSource = 'Sales Cloud';
                    cptcinsert.add(cptcvaluesforinsert);
                    updatecontact.put('profiling', cptcvaluesforinsert);
                }
                
                if (leadrec.Consent_Status_Marketing__c == null){
                    ContactPointTypeConsent cptcvaluesforinsert = new ContactPointTypeConsent();
                    cptcvaluesforinsert.Name = leadrec.Name + ' marketing ' + string.valueOf(System.now());
                    cptcvaluesforinsert.CaptureDate = System.now();
                    cptcvaluesforinsert.DataUsePurposeId = datausepurposeIds.get('marketing');
                    cptcvaluesforinsert.CaptureContactPointType = 'Phone';
                    cptcvaluesforinsert.ContactPointType = 'Email';
                    cptcvaluesforinsert.Consent_Text_Version__c = '1';
                    cptcvaluesforinsert.PartyId = leadrec.IndividualId;
                    cptcvaluesforinsert.PrivacyConsentStatus = 'Seen';
                    cptcvaluesforinsert.CaptureSource = 'Sales Cloud';
                    cptcinsert.add(cptcvaluesforinsert);
                    updatecontact.put('marketing', cptcvaluesforinsert);
                }
            }
            
            if (!cptcinsert.isEmpty()){
				insert cptcinsert;                
            }
            //Update Lead and return parsevalue for Marketing
            if (updatecontact != null){
                if (updatecontact.containsKey('marketing')){
                    parsetextvalue = updatecontact.get('marketing').Id + '|marketing^';
                }
                
                if (updatecontact.containsKey('profiling')){
                    if (parsetextvalue != null){
                        parsetextvalue = parsetextvalue + updatecontact.get('profiling').Id + '|profiling^';
                    } else {
                        parsetextvalue = updatecontact.get('profiling').Id + '|profiling^';
                    }
                    
                }
                
                if (parsetextvalue != null){
                    for (Lead l : leads){
                        Lead leadval = new Lead();
                        leadval.Id = l.Id;
                        if (l.Consent_Status_Profiling__c == null){
                            leadval.Consent_Status_Profiling__c = 'Pending';
                        }
                        if (l.Consent_Status_Marketing__c == null){
                            leadval.Consent_Status_Marketing__c = 'Pending';
                        }
                        leadval.Consent_Registration_Date__c = System.today();
                        contactlist.add(leadval);
                    }
                    
                    if (contactlist != null && !contactlist.isEmpty()){
                        update contactlist;
                    }
                    parsetextvalue = parsetextvalue.removeEnd('^');
                }
            }
            parsetextlist.add(parsetextvalue);
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