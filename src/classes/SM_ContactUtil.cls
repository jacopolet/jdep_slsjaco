//-------------------------------------------------------------------------------------------//
// Author       :   Glenn Serrano - Accenture
// Created Date :   June 18, 2020
// Usage        :   Utility Class for Contact
//
//-------------------------------------------------------------------------------------------//
public without sharing class SM_ContactUtil {
    private static final User u = UserDAO.userInformation();
    
    public static void createIndividual(List<Contact> contacts){
        CustomLogging.push('createIndividual', 'SM_ContactUtil');
        try{
            Map<Id, Id> individualContactorcontactmatch = new Map<Id, Id>();
            Map<String, String> datausepurposeIds = fetchDataUsePurposeIds();
            List<ContactPointTypeConsent> insertcptc = new List<ContactPointTypeConsent>();
            Set<Id> updateContactIds = new Set<Id>();
            List<Individual> createindv = new List<Individual>();
            List<Contact> updacontactrec = new List<Contact>();
            String nameval;
            for (Contact c : contacts){
                Individual ind = new Individual();
                ind.FirstName = c.FirstName;
                ind.MiddleName = c.MiddleName;
                ind.LastName = c.LastName;
                ind.Related_To__c = c.Id;
                createindv.add(ind);
            }
            
            if (!createindv.isEmpty()){
                insert createindv;

                List<Individual> individualrec = [Select Id, Related_To__c from Individual where Id IN: createindv];
                if (!individualrec.isEmpty()){
                    for (Individual i : individualrec){
                        individualContactorcontactmatch.put(i.Related_To__c, i.Id);
                    }
                }

                if (!individualContactorcontactmatch.isEmpty()){
                    for (Contact c : contacts){
                        Contact contactupdate = new Contact();
                        contactupdate.Id = c.Id;
                        contactupdate.IndividualId = individualContactorcontactmatch.get(c.Id);
                        if (!updateContactIds.contains(c.Id)){
                            updacontactrec.add(contactupdate);
                            updateContactIds.add(c.Id);
                        }
                        if (u.Profile.Name == SM_Constants.JDEDigital){
                            if (c.FirstName != null){
                                if (nameval == null){
                                    nameval = c.FirstName;
                                } else {
                                    nameval = nameval + ' ' + c.FirstName;
                                }
                            }
                            
                            if (c.MiddleName != null){
                                if (nameval == null){
                                    nameval = c.MiddleName;
                                } else {
                                    nameval = nameval + ' ' + c.MiddleName;
                                }
                            }
                            
                            if (c.LastName != null){
                                if (nameval == null){
                                    nameval = c.LastName;
                                } else {
                                    nameval = nameval + ' ' + c.LastName;
                                }
                            }
                            
                            if (c.Consent_Status_Marketing__c != null){
                                 ContactPointTypeConsent cptcvaluesforinsert = new ContactPointTypeConsent();
                                 cptcvaluesforinsert.Name = nameval + ' ' + SM_Constants.Marketing + ' ' + System.Now();
                                 cptcvaluesforinsert.CaptureSource = 'EpiServer';
                                 cptcvaluesforinsert.CaptureDate = System.Now();
                                 cptcvaluesforinsert.DataUsePurposeId = datausepurposeIds.get(SM_Constants.Marketing);
                                 cptcvaluesforinsert.CaptureContactPointType = 'Web';
                                 cptcvaluesforinsert.ContactPointType = 'Email';
                                 if (c.Consent_Status_Marketing__c == 'Opt-In'){
                                     cptcvaluesforinsert.PrivacyConsentStatus = 'OptIn';
                                     cptcvaluesforinsert.Consent_Text_Version__c = string.valueOf(integer.valueOf(c.Consent_Version_Marketing__c));
                                     cptcvaluesforinsert.EffectiveFrom = System.Now();
                                 }
                                 else {
                                     if (c.Consent_Status_Marketing__c == 'Opt-Out'){
                                         cptcvaluesforinsert.PrivacyConsentStatus = 'OptOut';
                                     }
                                 }
                                 cptcvaluesforinsert.PartyId = individualContactorcontactmatch.get(c.Id);
                                 if (c.Consent_Status_Marketing__c == 'Opt-In'){
                                     insertcptc.add(cptcvaluesforinsert);
                                 }
                             }
                            
                             if (c.Consent_Status_Profiling__c != null){
                                 ContactPointTypeConsent cptcvaluesforinsert = new ContactPointTypeConsent();
                                 cptcvaluesforinsert.Name = nameval + ' ' + SM_Constants.Profiling + ' ' + System.Now();
                                 cptcvaluesforinsert.CaptureSource = 'EpiServer';
                                 cptcvaluesforinsert.CaptureDate = System.Now();
                                 cptcvaluesforinsert.DataUsePurposeId = datausepurposeIds.get(SM_Constants.Profiling);
                                 cptcvaluesforinsert.CaptureContactPointType = 'Web';
                                 cptcvaluesforinsert.ContactPointType = 'Email';
                                 if (c.Consent_Status_Profiling__c == 'Opt-In'){
                                     cptcvaluesforinsert.PrivacyConsentStatus = 'OptIn';
                                     cptcvaluesforinsert.Consent_Text_Version__c = string.valueOf(integer.valueOf(c.Consent_Version_Profiling__c));
                                     cptcvaluesforinsert.EffectiveFrom = System.Now();
                                 }
                                 else {
                                     if (c.Consent_Status_Profiling__c == 'Opt-Out'){
                                         cptcvaluesforinsert.PrivacyConsentStatus = 'OptOut';
                                     }
                                 }
                                 cptcvaluesforinsert.PartyId = individualContactorcontactmatch.get(c.Id);
                                 if (c.Consent_Status_Profiling__c == 'Opt-In'){
                                     insertcptc.add(cptcvaluesforinsert);
                                 }
                             }
                            
                             if (c.Consent_Status_Surveys__c != null){
                                 ContactPointTypeConsent cptcvaluesforinsert = new ContactPointTypeConsent();
                                 cptcvaluesforinsert.Name = nameval + ' ' + SM_Constants.Survey + ' ' + System.Now();
                                 cptcvaluesforinsert.CaptureSource = 'EpiServer';
                                 cptcvaluesforinsert.CaptureDate = System.Now();
                                 cptcvaluesforinsert.DataUsePurposeId = datausepurposeIds.get(SM_Constants.Survey);
                                 cptcvaluesforinsert.CaptureContactPointType = 'Web';
                                 cptcvaluesforinsert.ContactPointType = 'Email';
                                 if (c.Consent_Status_Surveys__c == 'Opt-In'){
                                     cptcvaluesforinsert.PrivacyConsentStatus = 'OptIn';
                                     cptcvaluesforinsert.Consent_Text_Version__c = string.valueOf(integer.valueOf(c.Consent_Version_Surveys__c));
                                     cptcvaluesforinsert.EffectiveFrom = System.Now();
                                 }
                                 else {
                                     if (c.Consent_Status_Surveys__c == 'Opt-Out'){
                                         cptcvaluesforinsert.PrivacyConsentStatus = 'OptOut';
                                     }
                                 }
                                 cptcvaluesforinsert.PartyId = individualContactorcontactmatch.get(c.Id);
                                 if (c.Consent_Status_Surveys__c == 'Opt-In'){
                                     insertcptc.add(cptcvaluesforinsert);
                                 }
                             } 
                        }
                        
                    }
                    
                    if (!insertcptc.isEmpty()){
                        insert insertcptc;
                    }
    
                    if (!updacontactrec.isEmpty()){
                        update updacontactrec;
                    }
                }
                
            }
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        CustomLogging.pop();   
    }

    public static void generateHash(List<Contact> Contacts){
        CustomLogging.push('generateHash', 'SM_ContactUtil');
        try{
            if (Contacts != null){
                for (Contact c : Contacts){
                     if (c.Email != null){
                        Blob emailBlob = Blob.valueOf(c.Email);
                        Blob emailHash = Crypto.generateDigest('SHA-256', emailBlob);
                        c.Email_SHA256__c = EncodingUtil.convertToHex(emailHash);
                     }
                     else {
                         c.Email_SHA256__c = null;
                     }
                }
            }
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        CustomLogging.pop();   
    }

    public static void consentUpdateFromBoomi(List<Contact> Contacts, Map<Id, Contact>  oldContactMap, Set<Id> indids){
        CustomLogging.push('consentUpdateFromBoomi', 'SM_ContactUtil');
        try{
            List<Individual> indnameval = new List<Individual>();
            List<ContactPointTypeConsent> insertnewcptc = new List<ContactPointTypeConsent>();
            List<ContactPointTypeConsent> updatecptc = new List<ContactPointTypeConsent>();
            Map<String, ContactPointTypeConsent> cptcvalues = new Map<String, ContactPointTypeConsent>();
            Map<Id, String> indmapnames = new Map<Id, String>();    
            List<ContactPointTypeConsent> cptclist = new List<ContactPointTypeConsent>();
            
            if (!indids.isEmpty()){
                cptclist = [Select Id, PrivacyConsentStatus, Consent_Text_Version__c, CaptureContactPointType, DataUsePurpose.Name, LastModifiedDate,
                            DataUsePurposeId, PartyId, CaptureDate from ContactPointTypeConsent where PartyId = :indids ORDER BY CreatedDate DESC LIMIT 30];
                indnameval = [Select Id, Name from Individual where Id = :indids];
            }
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
            if(!indnameval.isEmpty()){
                for (Individual ival : indnameval){
                     indmapnames.put(ival.Id, ival.Name);
                }
            }

            if (Contacts != null){
                Map<String, String> datausepurposeIds = fetchDataUsePurposeIds();
                Contact oldContact;
                for (Contact c : Contacts){
                    oldContact = oldContactMap.get(c.Id);
                     if (!cptcvalues.isEmpty()){
                         if (cptcvalues.containsKey(c.IndividualId + SM_Constants.Marketing)){
                             
                             if ((c.Consent_Status_Marketing__c == 'Opt-In' && cptcvalues.get(c.IndividualId + SM_Constants.Marketing).PrivacyConsentStatus != 'OptIn') || 
                                 (c.Consent_Status_Marketing__c == 'Opt-In' && c.Consent_Version_Marketing__c != integer.valueOf(cptcvalues.get(c.IndividualId + SM_Constants.Marketing).Consent_Text_Version__c))){
                                    ContactPointTypeConsent cptcvaluesforinsert = new ContactPointTypeConsent();
                                    cptcvaluesforinsert.Name = indmapnames.get(c.IndividualId) + ' ' + SM_Constants.Marketing + ' ' + System.Now();
                                    cptcvaluesforinsert.CaptureSource = 'EpiServer';
                                    cptcvaluesforinsert.CaptureDate = System.Now();
                                    cptcvaluesforinsert.DataUsePurposeId = datausepurposeIds.get(SM_Constants.Marketing);
                                    cptcvaluesforinsert.CaptureContactPointType = 'Web';
                    				cptcvaluesforinsert.ContactPointType = 'Email';
                                    cptcvaluesforinsert.Consent_Text_Version__c = string.valueOf(integer.valueOf(c.Consent_Version_Marketing__c));
                                    cptcvaluesforinsert.PrivacyConsentStatus = 'OptIn';
                                    cptcvaluesforinsert.PartyId = c.IndividualId;
									cptcvaluesforinsert.EffectiveFrom = System.Now();
                                    insertnewcptc.add(cptcvaluesforinsert);
                                    
                                    if (cptcvalues.get(c.IndividualId + SM_Constants.Marketing).PrivacyConsentStatus == 'OptIn'){
                                        ContactPointTypeConsent cptcvaluesforupdate = new ContactPointTypeConsent();
                                        cptcvaluesforupdate.Id = cptcvalues.get(c.IndividualId + SM_Constants.Marketing).Id;
                                        cptcvaluesforupdate.EffectiveTo = System.Now();
                                        cptcvaluesforupdate.PrivacyConsentStatus = 'OptOut';
                                        updatecptc.add(cptcvaluesforupdate);
                                    }
                                    
                             } else {
                                 if (c.Consent_Status_Marketing__c == 'Opt-Out' && cptcvalues.get(c.IndividualId + SM_Constants.Marketing).PrivacyConsentStatus != 'OptOut'){
                                        ContactPointTypeConsent cptcvaluesforupdate = new ContactPointTypeConsent();
                                        cptcvaluesforupdate.Id = cptcvalues.get(c.IndividualId + SM_Constants.Marketing).Id;
                                        cptcvaluesforupdate.CaptureDate = System.Now();
                                        cptcvaluesforupdate.PrivacyConsentStatus = 'OptOut';
                                        cptcvaluesforupdate.EffectiveTo = System.Now();
                                        updatecptc.add(cptcvaluesforupdate);
                                 }
                             }
                         } else {
                                //no Contact Point Type Consent but Contact Marketing Status Set by Digital;
                                if (!cptcvalues.containsKey(c.IndividualId + SM_Constants.Marketing) && c.Consent_Status_Marketing__c != oldContact.Consent_Status_Marketing__c &&
                                    c.Consent_Status_Marketing__c != 'Pending' && c.Consent_Status_Marketing__c != null){
                                    ContactPointTypeConsent cptcvaluesforinsert = new ContactPointTypeConsent();
                                    cptcvaluesforinsert.Name = indmapnames.get(c.IndividualId) + ' ' + SM_Constants.Marketing + ' ' + System.Now();
                                    cptcvaluesforinsert.CaptureSource = 'EpiServer';
                                    cptcvaluesforinsert.CaptureDate = System.Now();
                                    cptcvaluesforinsert.DataUsePurposeId = datausepurposeIds.get(SM_Constants.Marketing);
                                    cptcvaluesforinsert.CaptureContactPointType = 'Web';
                    				cptcvaluesforinsert.ContactPointType = 'Email';
                                    if (c.Consent_Status_Marketing__c == 'Opt-In'){
                                        cptcvaluesforinsert.PrivacyConsentStatus = 'OptIn';
                                        cptcvaluesforinsert.Consent_Text_Version__c = string.valueOf(integer.valueOf(c.Consent_Version_Marketing__c));
										cptcvaluesforinsert.EffectiveFrom = System.Now();
                                    }
                                    else {
                                        if (c.Consent_Status_Marketing__c == 'Opt-Out'){
                                            cptcvaluesforinsert.PrivacyConsentStatus = 'OptOut';
                                            cptcvaluesforinsert.EffectiveTo = System.Now();
                                        }
                                    }
                                    cptcvaluesforinsert.PartyId = c.IndividualId;
                                    if (c.Consent_Status_Marketing__c == 'Opt-In'){
                                        insertnewcptc.add(cptcvaluesforinsert);
                                    }
                                } 
                         }
                         if (cptcvalues.containsKey(c.IndividualId + SM_Constants.Profiling)){
                                    if ((c.Consent_Status_Profiling__c == 'Opt-In' && cptcvalues.get(c.IndividualId + SM_Constants.Profiling).PrivacyConsentStatus != 'OptIn') ||  
                                        (c.Consent_Status_Profiling__c == 'Opt-In' && c.Consent_Version_Profiling__c != integer.valueOf(cptcvalues.get(c.IndividualId + SM_Constants.Profiling).Consent_Text_Version__c))){
                                            ContactPointTypeConsent cptcvaluesforinsert = new ContactPointTypeConsent();
                                            cptcvaluesforinsert.Name = indmapnames.get(c.IndividualId) + ' ' + SM_Constants.Profiling + ' ' + System.Now();
                                            cptcvaluesforinsert.CaptureSource = 'EpiServer';
                                            cptcvaluesforinsert.CaptureDate = System.Now();
                                            cptcvaluesforinsert.DataUsePurposeId = datausepurposeIds.get(SM_Constants.Profiling);
                                            cptcvaluesforinsert.CaptureContactPointType = 'Web';
                    						cptcvaluesforinsert.ContactPointType = 'Email';
                                            cptcvaluesforinsert.Consent_Text_Version__c = string.valueOf(integer.valueOf(c.Consent_Version_Profiling__c));
                                            cptcvaluesforinsert.PrivacyConsentStatus = 'OptIn';
                                            cptcvaluesforinsert.PartyId = c.IndividualId;
											cptcvaluesforinsert.EffectiveFrom = System.Now();
                                            insertnewcptc.add(cptcvaluesforinsert);
                                            if (cptcvalues.get(c.IndividualId + SM_Constants.Profiling).PrivacyConsentStatus == 'OptIn'){
                                                ContactPointTypeConsent cptcvaluesforupdate = new ContactPointTypeConsent();
                                                cptcvaluesforupdate.Id = cptcvalues.get(c.IndividualId + SM_Constants.Profiling).Id;
                                                cptcvaluesforupdate.EffectiveTo = System.Now();
                                                cptcvaluesforupdate.PrivacyConsentStatus = 'OptOut';
                                                updatecptc.add(cptcvaluesforupdate);
                                            }
                                    } else {
                                        if (c.Consent_Status_Profiling__c == 'Opt-Out' && cptcvalues.get(c.IndividualId + SM_Constants.Profiling).PrivacyConsentStatus != 'OptOut'){
                                            ContactPointTypeConsent cptcvaluesforupdate = new ContactPointTypeConsent();
                                            cptcvaluesforupdate.Id = cptcvalues.get(c.IndividualId + SM_Constants.Profiling).Id;
                                            cptcvaluesforupdate.CaptureDate = System.Now();
                                            cptcvaluesforupdate.PrivacyConsentStatus = 'OptOut';
                                            cptcvaluesforupdate.EffectiveTo = System.Now();
                                            updatecptc.add(cptcvaluesforupdate);
                                        }
                                    }
                         } else {
                                if (!cptcvalues.containsKey(c.IndividualId + SM_Constants.Profiling) && c.Consent_Status_Profiling__c != oldContact.Consent_Status_Profiling__c &&
                                    c.Consent_Status_Profiling__c != 'Pending' && c.Consent_Status_Profiling__c != null){
                                    ContactPointTypeConsent cptcvaluesforinsert = new ContactPointTypeConsent();
                                    cptcvaluesforinsert.Name = indmapnames.get(c.IndividualId) + ' ' + SM_Constants.Profiling + ' ' + System.Now();
                                    cptcvaluesforinsert.CaptureSource = 'EpiServer';
                                    cptcvaluesforinsert.CaptureDate = System.Now();
                                    cptcvaluesforinsert.DataUsePurposeId = datausepurposeIds.get(SM_Constants.Profiling);
                                    cptcvaluesforinsert.CaptureContactPointType = 'Web';
                    				cptcvaluesforinsert.ContactPointType = 'Email';
                                    if (c.Consent_Status_Profiling__c == 'Opt-In'){
                                        cptcvaluesforinsert.PrivacyConsentStatus = 'OptIn';
                                        cptcvaluesforinsert.Consent_Text_Version__c = string.valueOf(integer.valueOf(c.Consent_Version_Profiling__c));
										cptcvaluesforinsert.EffectiveFrom = System.Now();
                                    }
                                    else {
                                        if (c.Consent_Status_Profiling__c == 'Opt-Out'){
                                            cptcvaluesforinsert.PrivacyConsentStatus = 'OptOut';
                                            cptcvaluesforinsert.EffectiveTo = System.Now();
                                        }
                                    }
                                    cptcvaluesforinsert.PartyId = c.IndividualId;
                                    if (c.Consent_Status_Profiling__c == 'Opt-In'){
                                        insertnewcptc.add(cptcvaluesforinsert);
                                    }
                                } 
                         }
                         if (cptcvalues.containsKey(c.IndividualId + SM_Constants.Survey)){
                                    if ((c.Consent_Status_Surveys__c == 'Opt-In' && cptcvalues.get(c.IndividualId + SM_Constants.Survey).PrivacyConsentStatus != 'OptIn') || 
                                        (c.Consent_Status_Surveys__c == 'Opt-In' && c.Consent_Version_Surveys__c != integer.valueOf(cptcvalues.get(c.IndividualId + SM_Constants.Survey).Consent_Text_Version__c))){
                                            ContactPointTypeConsent cptcvaluesforinsert = new ContactPointTypeConsent();
                                            cptcvaluesforinsert.Name = indmapnames.get(c.IndividualId) + ' ' + SM_Constants.Survey + ' ' + System.Now();
                                            cptcvaluesforinsert.CaptureSource = 'EpiServer';
                                            cptcvaluesforinsert.CaptureDate = System.Now();
                                            cptcvaluesforinsert.DataUsePurposeId = datausepurposeIds.get(SM_Constants.Survey);
                                            cptcvaluesforinsert.CaptureContactPointType = 'Web';
                    						cptcvaluesforinsert.ContactPointType = 'Email';
                                            cptcvaluesforinsert.Consent_Text_Version__c = string.valueOf(integer.valueOf(c.Consent_Version_Surveys__c));
                                            cptcvaluesforinsert.PrivacyConsentStatus = 'OptIn';
                                            cptcvaluesforinsert.PartyId = c.IndividualId;
											cptcvaluesforinsert.EffectiveFrom = System.Now();
                                            insertnewcptc.add(cptcvaluesforinsert);
                                            if (cptcvalues.get(c.IndividualId + SM_Constants.Survey).PrivacyConsentStatus == 'OptIn'){
                                                ContactPointTypeConsent cptcvaluesforupdate = new ContactPointTypeConsent();
                                                cptcvaluesforupdate.Id = cptcvalues.get(c.IndividualId + SM_Constants.Survey).Id;
                                                cptcvaluesforupdate.EffectiveTo = System.Now();
                                                cptcvaluesforupdate.PrivacyConsentStatus = 'OptOut';
                                                updatecptc.add(cptcvaluesforupdate);
                                            }
                                    } else {
                                        if (c.Consent_Status_Surveys__c == 'Opt-Out' && cptcvalues.get(c.IndividualId + SM_Constants.Survey).PrivacyConsentStatus != 'OptOut'){
                                            ContactPointTypeConsent cptcvaluesforupdate = new ContactPointTypeConsent();
                                            cptcvaluesforupdate.Id = cptcvalues.get(c.IndividualId + SM_Constants.Survey).Id;
                                            cptcvaluesforupdate.CaptureDate = System.Now();
                                            cptcvaluesforupdate.PrivacyConsentStatus = 'OptOut';
                                            cptcvaluesforupdate.EffectiveTo = System.Now();
                                            updatecptc.add(cptcvaluesforupdate);
                                        }
                                    }
                         } else {
                                
                                if (!cptcvalues.containsKey(c.IndividualId + SM_Constants.Survey) && c.Consent_Status_Surveys__c != oldContact.Consent_Status_Surveys__c &&
                                    c.Consent_Status_Surveys__c != 'Pending' && c.Consent_Status_Surveys__c != null){
                                    ContactPointTypeConsent cptcvaluesforinsert = new ContactPointTypeConsent();
                                    cptcvaluesforinsert.Name = indmapnames.get(c.IndividualId) + ' ' + SM_Constants.Survey + ' ' + System.Now();
                                    cptcvaluesforinsert.CaptureSource = 'EpiServer';
                                    cptcvaluesforinsert.CaptureDate = System.Now();
                                    cptcvaluesforinsert.DataUsePurposeId = datausepurposeIds.get(SM_Constants.Survey);
                                    cptcvaluesforinsert.CaptureContactPointType = 'Web';
                    				cptcvaluesforinsert.ContactPointType = 'Email';
                                    if (c.Consent_Status_Surveys__c == 'Opt-In'){
                                        cptcvaluesforinsert.PrivacyConsentStatus = 'OptIn';
                                        cptcvaluesforinsert.Consent_Text_Version__c = string.valueOf(integer.valueOf(c.Consent_Version_Surveys__c));
										cptcvaluesforinsert.EffectiveFrom = System.Now();
                                    }
                                    else {
                                        if (c.Consent_Status_Surveys__c == 'Opt-Out'){
                                            cptcvaluesforinsert.PrivacyConsentStatus = 'OptOut';
                                            cptcvaluesforinsert.EffectiveTo = System.Now();
                                        }
                                    }
                                    cptcvaluesforinsert.PartyId = c.IndividualId;
                                    if (c.Consent_Status_Surveys__c == 'Opt-In'){
                                        insertnewcptc.add(cptcvaluesforinsert);
                                    }
                                }
                         }
                     } else {
                        if (!cptcvalues.containsKey(c.IndividualId + SM_Constants.Marketing) && c.Consent_Status_Marketing__c != null && c.Consent_Status_Marketing__c != oldContact.Consent_Status_Marketing__c &&
                            c.Consent_Status_Marketing__c != 'Pending'){
                            ContactPointTypeConsent cptcvaluesforinsert = new ContactPointTypeConsent();
                            cptcvaluesforinsert.Name = indmapnames.get(c.IndividualId) + ' ' + SM_Constants.Marketing + ' ' + System.Now();
                            cptcvaluesforinsert.CaptureSource = 'EpiServer';
                            cptcvaluesforinsert.CaptureDate = System.Now();
                            cptcvaluesforinsert.DataUsePurposeId = datausepurposeIds.get(SM_Constants.Marketing);
                            cptcvaluesforinsert.CaptureContactPointType = 'Web';
                    		cptcvaluesforinsert.ContactPointType = 'Email';
                            if (c.Consent_Status_Marketing__c == 'Opt-In'){
                                cptcvaluesforinsert.PrivacyConsentStatus = 'OptIn';
                                cptcvaluesforinsert.Consent_Text_Version__c = string.valueOf(integer.valueOf(c.Consent_Version_Marketing__c));
								cptcvaluesforinsert.EffectiveFrom = System.Now();
                            }
                            else {
                                if (c.Consent_Status_Marketing__c == 'Opt-Out'){
                                    cptcvaluesforinsert.PrivacyConsentStatus = 'OptOut';
                                }
                            }
                            cptcvaluesforinsert.PartyId = c.IndividualId;
                            if (c.Consent_Status_Marketing__c == 'Opt-In'){
                                insertnewcptc.add(cptcvaluesforinsert);
                            }
                        } 
                        if (!cptcvalues.containsKey(c.IndividualId + SM_Constants.Profiling) && c.Consent_Status_Profiling__c != null && c.Consent_Status_Profiling__c != oldContact.Consent_Status_Profiling__c &&
                            c.Consent_Status_Profiling__c != 'Pending'){
                            ContactPointTypeConsent cptcvaluesforinsert = new ContactPointTypeConsent();
                            cptcvaluesforinsert.Name = indmapnames.get(c.IndividualId) + ' ' + SM_Constants.Profiling + ' ' + System.Now();
                            cptcvaluesforinsert.CaptureSource = 'EpiServer';
                            cptcvaluesforinsert.CaptureDate = System.Now();
                            cptcvaluesforinsert.DataUsePurposeId = datausepurposeIds.get(SM_Constants.Profiling);
                            cptcvaluesforinsert.CaptureContactPointType = 'Web';
                    		cptcvaluesforinsert.ContactPointType = 'Email';
                            if (c.Consent_Status_Profiling__c == 'Opt-In'){
                                cptcvaluesforinsert.PrivacyConsentStatus = 'OptIn';
                                cptcvaluesforinsert.Consent_Text_Version__c = string.valueOf(integer.valueOf(c.Consent_Version_Profiling__c));
								cptcvaluesforinsert.EffectiveFrom = System.Now();
                            }
                            else {
                                if (c.Consent_Status_Profiling__c == 'Opt-Out'){
                                    cptcvaluesforinsert.PrivacyConsentStatus = 'OptOut';
                                }
                            }
                            cptcvaluesforinsert.PartyId = c.IndividualId;
                            if (c.Consent_Status_Profiling__c == 'Opt-In'){
                                insertnewcptc.add(cptcvaluesforinsert);
                            }
                        } 
                        if (!cptcvalues.containsKey(c.IndividualId + SM_Constants.Survey) && c.Consent_Status_Surveys__c != null && c.Consent_Status_Surveys__c != oldContact.Consent_Status_Surveys__c &&
                            c.Consent_Status_Surveys__c != 'Pending'){
                            ContactPointTypeConsent cptcvaluesforinsert = new ContactPointTypeConsent();
                            cptcvaluesforinsert.Name = indmapnames.get(c.IndividualId) + ' ' + SM_Constants.Survey + ' ' + System.Now();
                            cptcvaluesforinsert.CaptureSource = 'EpiServer';
                            cptcvaluesforinsert.CaptureDate = System.Now();
                            cptcvaluesforinsert.DataUsePurposeId = datausepurposeIds.get(SM_Constants.Survey);
                            cptcvaluesforinsert.CaptureContactPointType = 'Web';
                    		cptcvaluesforinsert.ContactPointType = 'Email';
                            if (c.Consent_Status_Surveys__c == 'Opt-In'){
                                cptcvaluesforinsert.PrivacyConsentStatus = 'OptIn';
                                cptcvaluesforinsert.Consent_Text_Version__c = string.valueOf(integer.valueOf(c.Consent_Version_Surveys__c));
								cptcvaluesforinsert.EffectiveFrom = System.Now();
                            }
                            else {
                                if (c.Consent_Status_Surveys__c == 'Opt-Out'){
                                    cptcvaluesforinsert.PrivacyConsentStatus = 'OptOut';
                                }
                            }
                            cptcvaluesforinsert.PartyId = c.IndividualId;
                            if (c.Consent_Status_Surveys__c == 'Opt-In'){
                                insertnewcptc.add(cptcvaluesforinsert);
                            }
                        }
                     }
                }
                if (!insertnewcptc.isEmpty()){
                    insert insertnewcptc;
                }

                if (!updatecptc.isEmpty()){
                    update updatecptc;
                }
            }
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        CustomLogging.pop();   
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

    public static void updateconsentonarchive(List<Contact> Contacts, Map<Id, Contact>  oldContactMap, Set<Id> indids){
        CustomLogging.push('updateconsentonarchive', 'SM_ContactUtil');
        try{
            List<ContactPointTypeConsent> updatecptc = new List<ContactPointTypeConsent>();
            Map<String, ContactPointTypeConsent> cptcvalues = new Map<String, ContactPointTypeConsent>();
            List<ContactPointTypeConsent> cptclist = new List<ContactPointTypeConsent>();
            if (!indids.isEmpty()){
                cptclist = [Select Id, PrivacyConsentStatus, Consent_Text_Version__c, CaptureContactPointType, DataUsePurpose.Name, LastModifiedDate,
                            DataUsePurposeId, PartyId from ContactPointTypeConsent where PartyId = :indids ORDER BY LastModifiedDate DESC];
            }
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

            if (Contacts != null){
                Map<String, String> datausepurposeIds = fetchDataUsePurposeIds();
                for (Contact c : Contacts){
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
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        CustomLogging.pop();   
    }
    
    public static void updateRecordTypeId(List<Contact> contactList){
    	CustomLogging.push('updateRecordTypeId', 'SM_ContactUtil');
        try{
            //get recordtype id of standard contact
            String standardContactType = TS_UtilityClass.getRecordTypeIdByName(TS_Constants.OBJ_APINAME_CONTACT, SM_Constants.ContactStandard);
            for(Contact con : contactList){
            	con.RecordTypeId = standardContactType;  
            }
            
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        
     	CustomLogging.pop();      
    }
}