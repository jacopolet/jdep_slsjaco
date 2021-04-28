//-------------------------------------------------------------------------------------------//
// Author       :   Glenn Serrano - Accenture
// Created Date :   2020-09-24
// Usage        :   Opting Out of Contact / Lead as an end user.
//                  
//-------------------------------------------------------------------------------------------//
public without sharing class SM_OptOut {
	@InvocableMethod
    public static void optoutContact(List<Id> objectId){
        if (TriggerSettings__c.getInstance().ConsentTrigger__c == true){
            List<Contact> updateContactConsent = new List<Contact>();
            List<ContactPointTypeConsent> updatecptc = new List<ContactPointTypeConsent>();
            Map<String, ContactPointTypeConsent> cptcvalues = new Map<String, ContactPointTypeConsent>();
            List<ContactPointTypeConsent> cptclist = new List<ContactPointTypeConsent>();
            Set<Id> individualId = new Set<Id>();
            List<Contact> updateContact = new List<Contact>();
            if (!objectId.isEmpty()){
                updateContact = [Select Id, IndividualId, Consent_Status_Marketing__c, Consent_Status_Profiling__c, Consent_Status_Surveys__c from Contact where Id = :objectId];
            }
            if (!updateContact.isEmpty()){
                for (Contact c : updateContact){
                    c.Consent_Status_Marketing__c = 'Opt-Out';
                    c.Consent_Status_Profiling__c = 'Opt-Out';
                    c.Consent_Status_Surveys__c = 'Opt-Out';
                    individualId.add(c.IndividualId);
                    updateContactConsent.add(c);
                }
                if (!updateContactConsent.isEmpty()){
                    update updateContactConsent;
                }
            }
            if (!individualId.isEmpty()){
                cptclist = [Select Id, PrivacyConsentStatus, Consent_Text_Version__c, CaptureContactPointType, DataUsePurpose.Name, LastModifiedDate,
                            DataUsePurposeId, PartyId from ContactPointTypeConsent where PartyId = :individualId ORDER BY CreatedDate DESC LIMIT 30];
                if (!cptclist.isEmpty()){
                    for (ContactPointTypeConsent cptcval : cptclist){
                        String key;
                        if (cptcvalues.isEmpty()){
                            key = cptcval.PartyId + cptcval.DataUsePurpose.Name;
                            cptcvalues.put(key, cptcval);
                        }
                        else {
                            key = cptcval.PartyId + cptcval.DataUsePurpose.Name;
                            if (!cptcvalues.containsKey(key)){
                                cptcvalues.put(key, cptcval);
                            }
                        }
                    }
                }
                
                if (!updateContact.isEmpty()){
                    for (Contact c : updateContact){
                        if (!cptcvalues.isEmpty()){
                            if (cptcvalues.containsKey(c.IndividualId + SM_Constants.Marketing)){
                                if (c.Consent_Status_Marketing__c == 'Opt-Out' && cptcvalues.get(c.IndividualId + SM_Constants.Marketing).PrivacyConsentStatus != 'OptOut'){
                                    ContactPointTypeConsent cptcvaluesforupdate = new ContactPointTypeConsent();
                                    cptcvaluesforupdate.Id = cptcvalues.get(c.IndividualId + SM_Constants.Marketing).Id;
                                    cptcvaluesforupdate.CaptureDate = System.Now();
                                    cptcvaluesforupdate.PrivacyConsentStatus = 'OptOut';
                                    cptcvaluesforupdate.EffectiveTo = System.Now();
                                    updatecptc.add(cptcvaluesforupdate);
                                }
                            } 
                            if (cptcvalues.containsKey(c.IndividualId + SM_Constants.Profiling)){
                                if (c.Consent_Status_Profiling__c == 'Opt-Out' && cptcvalues.get(c.IndividualId + SM_Constants.Profiling).PrivacyConsentStatus != 'OptOut'){
                                    ContactPointTypeConsent cptcvaluesforupdate = new ContactPointTypeConsent();
                                    cptcvaluesforupdate.Id = cptcvalues.get(c.IndividualId + SM_Constants.Profiling).Id;
                                    cptcvaluesforupdate.CaptureDate = System.Now();
                                    cptcvaluesforupdate.PrivacyConsentStatus = 'OptOut';
                                    cptcvaluesforupdate.EffectiveTo = System.Now();
                                    updatecptc.add(cptcvaluesforupdate);
                                }
                            } 
                            if (cptcvalues.containsKey(c.IndividualId + SM_Constants.Survey)){
                                if (c.Consent_Status_Surveys__c == 'Opt-Out' && cptcvalues.get(c.IndividualId + SM_Constants.Survey).PrivacyConsentStatus != 'OptOut'){
                                    ContactPointTypeConsent cptcvaluesforupdate = new ContactPointTypeConsent();
                                    cptcvaluesforupdate.Id = cptcvalues.get(c.IndividualId + SM_Constants.Survey).Id;
                                    cptcvaluesforupdate.CaptureDate = System.Now();
                                    cptcvaluesforupdate.PrivacyConsentStatus = 'OptOut';
                                    cptcvaluesforupdate.EffectiveTo = System.Now();
                                    updatecptc.add(cptcvaluesforupdate);
                                }
                            } 
                        } 
                    }

                    if (!updatecptc.isEmpty()){
                        update updatecptc;
                    }
                }
            }
        }
    }
}