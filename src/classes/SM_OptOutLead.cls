//-------------------------------------------------------------------------------------------//
// Author       :   Glenn Serrano - Accenture
// Created Date :   2020-09-24
// Usage        :   Opting Out of Contact / Lead as an end user.
//                  
//-------------------------------------------------------------------------------------------//
public without sharing class SM_OptOutLead {
	@InvocableMethod
    public static void optoutLead(List<Id> objectId){
        if (TriggerSettings__c.getInstance().ConsentTrigger__c == true){
            List<Lead> updateLeadConsent = new List<Lead>();
            List<ContactPointTypeConsent> updatecptc = new List<ContactPointTypeConsent>();
            Map<String, ContactPointTypeConsent> cptcvalues = new Map<String, ContactPointTypeConsent>();
            List<ContactPointTypeConsent> cptclist = new List<ContactPointTypeConsent>();
            Set<Id> individualId = new Set<Id>();
            List<Lead> updateLead = new List<Lead>();
            if (!objectId.isEmpty()){
                updateLead = [Select Id, IndividualId, Consent_Status_Marketing__c, Consent_Status_Profiling__c, Consent_Status_Surveys__c from Lead where Id = :objectId];
            }
            if (!updateLead.isEmpty()){
                for (Lead l : updateLead){
                    l.Consent_Status_Marketing__c = 'Opt-Out';
                    l.Consent_Status_Profiling__c = 'Opt-Out';
                    l.Consent_Status_Surveys__c = 'Opt-Out';
                    individualId.add(l.IndividualId);
                    updateLeadConsent.add(l);
                }
                if (!updateLeadConsent.isEmpty()){
                    update updateLeadConsent;
                }
            }
            if (!individualId.isEmpty()){
                cptclist = [Select Id, PrivacyConsentStatus, Consent_Text_Version__c, CaptureContactPointType, DataUsePurpose.Name, LastModifiedDate,
                            DataUsePurposeId, PartyId from ContactPointTypeConsent where PartyId = :individualId ORDER BY LastModifiedDate DESC LIMIT 30];
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
                
                if (!updateLead.isEmpty()){
                    for (Lead l : updateLead){
                        if (!cptcvalues.isEmpty()){
                            if (cptcvalues.containsKey(l.IndividualId + SM_Constants.Marketing)){
                                if (l.Consent_Status_Marketing__c == 'Opt-Out' && cptcvalues.get(l.IndividualId + SM_Constants.Marketing).PrivacyConsentStatus != 'OptOut'){
                                    ContactPointTypeConsent cptcvaluesforupdate = new ContactPointTypeConsent();
                                    cptcvaluesforupdate.Id = cptcvalues.get(l.IndividualId + SM_Constants.Marketing).Id;
                                    cptcvaluesforupdate.CaptureDate = System.Now();
                                    cptcvaluesforupdate.PrivacyConsentStatus = 'OptOut';
                                    cptcvaluesforupdate.EffectiveTo = System.Now();
                                    updatecptc.add(cptcvaluesforupdate);
                                }
                            } 
                            if (cptcvalues.containsKey(l.IndividualId + SM_Constants.Profiling)){
                                if (l.Consent_Status_Profiling__c == 'Opt-Out' && cptcvalues.get(l.IndividualId + SM_Constants.Profiling).PrivacyConsentStatus != 'OptOut'){
                                    ContactPointTypeConsent cptcvaluesforupdate = new ContactPointTypeConsent();
                                    cptcvaluesforupdate.Id = cptcvalues.get(l.IndividualId + SM_Constants.Profiling).Id;
                                    cptcvaluesforupdate.CaptureDate = System.Now();
                                    cptcvaluesforupdate.PrivacyConsentStatus = 'OptOut';
                                    cptcvaluesforupdate.EffectiveTo = System.Now();
                                    updatecptc.add(cptcvaluesforupdate);
                                }
                            } 
                            if (cptcvalues.containsKey(l.IndividualId + SM_Constants.Survey)){
                                if (l.Consent_Status_Surveys__c == 'Opt-Out' && cptcvalues.get(l.IndividualId + SM_Constants.Survey).PrivacyConsentStatus != 'OptOut'){
                                    ContactPointTypeConsent cptcvaluesforupdate = new ContactPointTypeConsent();
                                    cptcvaluesforupdate.Id = cptcvalues.get(l.IndividualId + SM_Constants.Survey).Id;
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