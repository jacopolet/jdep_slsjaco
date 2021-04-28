@RestResource(urlMapping='/consentapi')
global without sharing class SM_ConsentAPI {
  public class SM_InboundLeadException extends Exception {
  }
  @HttpPost
  global static void consentapi() {
        CustomLogging.push('consentAPI', 'SM_ConsentAPI');
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        try {
            List<Custom_Log__c> customloggingadd = new List<Custom_Log__c>();
            if (TriggerSettings__c.getInstance().ConsentTrigger__c == true){
                //convert to Apex Object
                Object inboundvalue = JSON.deserialize(req.requestBody.toString(),InboundLead.class);
                Map<String, InboundLeadResponse> responseMap = new Map<String, InboundLeadResponse>();
                List<InboundLeadResponse> errormess = new List<InboundLeadResponse>();
                List<InboundLeadResponse> returnresults = new List<InboundLeadResponse>();
                InboundLeadResponse successresults = new InboundLeadResponse();
                InboundLeadResponse errorresults = new InboundLeadResponse();
                InboundLead wrappedvalues = (InboundLead) inboundvalue;
                Contact contactreturnval = matchContact(wrappedvalues.Channel.email, wrappedvalues.Channel.emailhash);
                Lead leadreturnval;
                List<Lead> newleadlist = new List<Lead>();
                Map<String,String> salesorgsoidoi = SM_GetMetadata.getsalesorgdoisoi();
                String newlycreatedleadId;
                if (contactreturnval == null){
                    leadreturnval = matchLead(wrappedvalues.Channel.email, wrappedvalues.Channel.emailhash);
                } 
            
                if(contactreturnval == null && leadreturnval == null){
                    InboundLeadResponse il = new InboundLeadResponse();
                    il.errorMessage = 'There was no contact or lead that matched';
                    il.email = wrappedvalues.Channel.email;
                    errormess.add(il);
                }
                if (wrappedvalues.action != null){
                    if (contactreturnval != null){
                        Map<String, ContactPointTypeConsent> contactvalues = checkContactPointTypeConsent(contactreturnval.IndividualId, contactreturnval.Individual.Name, wrappedvalues);
                        List<Contact> contactupdate = new List<Contact>();
                        if (!contactvalues.isEmpty()){
                            Contact updateContact = new Contact();
                            updateContact.Id = contactreturnval.Id;
                            Map<String, String> datausepurposeIds = fetchDataUsePurposeIds();
                            Set<String> loopthis = datausepurposeIds.keyset();
                            Map<String, String> privacyconsentstatusmap = fetchPrivacyConsentStatus();
                            String parsingTextvalue;
                            for (String val : loopthis){
                                String pcsvalues;
                                if (contactvalues.keyset().contains(val) == true){
                                
                                    if (val == SM_Constants.Marketing){
                                        if (contactvalues.get(val).Consent_Text_Version__c != null){
                                            updateContact.Consent_Version_Marketing__c = integer.valueOf(contactvalues.get(val).Consent_Text_Version__c);
                                        }
                                        updateContact.Consent_Status_Marketing__c = privacyconsentstatusmap.get(contactvalues.get(val).PrivacyConsentStatus);
                                    }
                                    else if (val == SM_Constants.Profiling){
                                        if (contactvalues.get(val).Consent_Text_Version__c != null){
                                            updateContact.Consent_Version_Profiling__c = integer.valueOf(contactvalues.get(val).Consent_Text_Version__c);
                                        }
                                        updateContact.Consent_Status_Profiling__c = privacyconsentstatusmap.get(contactvalues.get(val).PrivacyConsentStatus);
                                    }
                                    else if (val == SM_Constants.Survey){
                                        if (contactvalues.get(val).Consent_Text_Version__c != null){
                                            updateContact.Consent_Version_Surveys__c = integer.valueOf(contactvalues.get(val).Consent_Text_Version__c);
                                        }
                                        updateContact.Consent_Status_Surveys__c = privacyconsentstatusmap.get(contactvalues.get(val).PrivacyConsentStatus);
                                    }
            
                                    if ((salesorgsoidoi.get(wrappedvalues.sales_organization) == 'DOI' && (privacyconsentstatusmap.get(contactvalues.get(val).PrivacyConsentStatus) == 'Pending')) || 
                                        (salesorgsoidoi.get(wrappedvalues.sales_organization) == 'SOI' && (privacyconsentstatusmap.get(contactvalues.get(val).PrivacyConsentStatus) == 'Opt-In')) &&
                                        privacyconsentstatusmap.get(contactvalues.get(val).CaptureSource) != 'Sales Cloud'){
                                        if (parsingTextvalue == null){
                                            parsingTextvalue = contactvalues.get(val).Id + '|' + val + '^';
                                        } else {
                                            parsingTextvalue = parsingTextvalue + contactvalues.get(val).Id + '|' + val + '^';
                                        }
                                    }
                                    if (updateContact.Consent_Status_Marketing__c == 'Opt-Out' && updateContact.Consent_Status_Profiling__c == 'Opt-Out' && updateContact.Consent_Status_Surveys__c == 'Opt-Out'){
                                        updateContact.HasOptedOutOfEmail = true;
                                    }
                                    else {
                                        updateContact.HasOptedOutOfEmail = false;
                                    }
                                }
                            }
                            contactupdate.add(updateContact);
                            if (!contactupdate.isEmpty()){
                                Database.SaveResult[] srErrorList = Database.update(contactupdate, false);
                                for (Database.SaveResult sr : srErrorList) {
                                        if (sr.isSuccess()) {
                                            successresults.contactId = sr.getId();
                                            successresults.contactstatus = 'Contact Updated';
                                        } else {
                                            Custom_Log__c log = new Custom_Log__c();
                                            log.StackTrace__c = 'SM_ConsentAPI : consentapi';
                                            log.Message__c = sr.getErrors()[0].getMessage() + ' status code: ' + sr.getErrors()[0].getStatusCode() + ' field: ' + sr.getErrors()[0].getFields();
                                            log.LogType__c = 'Exception';
                                            log.Sequence__c = 0;
                                            log.Limits__c = getLimits();
                                            log.ExceptionType__c = 'System.DMLException';
                                            customloggingadd.add(log);
                                            
                                            errorresults.contactId = sr.getId();
                                            errorresults.contactstatus = sr.getErrors()[0].getMessage();
                                        }
                                }
                            }
                            if (parsingTextvalue != null){
                                if (salesorgsoidoi.get(wrappedvalues.sales_organization) == 'DOI'){
                                    Journey_Trigger__c journeytriggervalues = new Journey_Trigger__c();
                                    journeytriggervalues.Parsing_Text__c = parsingTextvalue.removeEnd('^');
                                    journeytriggervalues.Journey_Trigger_Type__c = 'Consent';
                                    journeytriggervalues.Journey_Trigger_SubType__c = 'Double Opt-In';
                                    journeytriggervalues.Contact__c = contactreturnval.Id;
                                    insert journeytriggervalues;
                                } else {
                                    if (salesorgsoidoi.get(wrappedvalues.sales_organization) == 'SOI'){
                                        Journey_Trigger__c journeytriggervalues = new Journey_Trigger__c();
                                        journeytriggervalues.Parsing_Text__c = parsingTextvalue.removeEnd('^');
                                        journeytriggervalues.Journey_Trigger_Type__c = 'Consent';
                                        journeytriggervalues.Journey_Trigger_SubType__c = 'Single Opt-In';
                                        journeytriggervalues.Contact__c = contactreturnval.Id;
                                        insert journeytriggervalues;
                                    }
                                }
                            }
                        }
                    }
                    else if (leadreturnval != null){
                        Map<String, ContactPointTypeConsent> leadvalues = checkContactPointTypeConsent(leadreturnval.IndividualId, leadreturnval.Individual.Name, wrappedvalues);
                        if (!leadvalues.isEmpty()){
                            updateLead(leadreturnval.Id, leadvalues, wrappedvalues, errorresults, successresults, customloggingadd);
                        }
                    }
                    
                }
                if (errorresults.leadId != null || errorresults.updatedLeadId != null || errorresults.contactId != null || errorresults.campaignMemberId != null || 
                    errorresults.taskId != null || errorresults.leadstatus != null || errorresults.leadupdatedstatus != null || errorresults.contactstatus != null || errorresults.taskStatus != null || 
                    errorresults.campaignMemberStatus != null || errorresults.errorMessage != null || errorresults.email != null){
                    errormess.add(errorresults);
                } else {
                    returnresults.add(successresults);
                }
                
                if (!errormess.isEmpty()){
                    res.statusCode = 500;
                    res.addHeader('Content-Type', 'application/json');
                    res.responseBody = Blob.valueOf(JSON.serialize(errormess));
                }
                else if (!returnresults.isEmpty()){
                    res.statusCode = 200;
                    res.addHeader('Content-Type', 'application/json');
                    res.responseBody = Blob.valueOf(JSON.serialize(returnresults));
                }
                if (!customloggingadd.isEmpty()){
                    insert customloggingadd;
                }
                
            }
        } catch (Exception ex) {
            HandleError(res, ex.getMessage(), req.requestBody.toString());
            CustomLogging.debugException(ex); 
            CustomLogging.pop(); 
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        CustomLogging.pop(); 
  }

  private static void HandleError(RestResponse res,String message,String extendedMessage) {
        res.statusCode = 500;
        Map<String, Object> e = new Map<String, Object>{
        'message' => message,
        'details' => extendedMessage
        };
        res.addHeader('Content-Type', 'application/json');
        res.responseBody = Blob.valueOf(JSON.serialize(e));
  }

  private static Map<String, ContactPointTypeConsent> checkContactPointTypeConsent(String individualId, String individualName, InboundLead wrappedvalues){
        CustomLogging.push('checkContactPointTypeConsent', 'SM_ConsentAPI');
        try{
            Map<String,String> salesorgsoidoi = SM_GetMetadata.getsalesorgdoisoi();
            DateTime recentmarketing, recentprofiling, recentsurvey;
            String recentmarketingId, recentprofilingId, recentsurveyId;
            Map<String,ContactPointTypeConsent> cptcvalues = new Map<String,ContactPointTypeConsent>();
            List<ContactPointTypeConsent> cptclist = [Select Id, PrivacyConsentStatus, Consent_Text_Version__c, CaptureContactPointType, DataUsePurpose.Name, LastModifiedDate,
                                                    DataUsePurposeId, CaptureSource from ContactPointTypeConsent where PartyId = :individualId ORDER BY CreatedDate DESC LIMIT 30];
            Set<String> dupforcreation = new Set<String>();
            Map<String, Consent> consentvalues = new Map<String, Consent>();
            List<ContactPointTypeConsent> cptcupdate = new List<ContactPointTypeConsent>();
            List<ContactPointTypeConsent> cptcinsert = new List<ContactPointTypeConsent>();
            Map<String, ContactPointTypeConsent> updateforleadorcontact = new Map<String, ContactPointTypeConsent>();
            Map<String, String> datausepurposeIds = fetchDataUsePurposeIds();

            for (ContactPointTypeConsent cptcval : cptclist){
                if (cptcvalues.isEmpty()){
                    cptcvalues.put(cptcval.DataUsePurpose.Name, cptcval);
                    
                } else {
                    if (!cptcvalues.containsKey(cptcval.DataUsePurpose.Name)){
                        cptcvalues.put(cptcval.DataUsePurpose.Name, cptcval);
                    }
                }
            }

            if (wrappedvalues.consent != null && wrappedvalues.action == 'Update'){
                String removebefore;
                for (Consent c : wrappedvalues.consent){
                    if (!cptcvalues.isEmpty()){
                        if (cptcvalues.containsKey(c.dataUsePurpose)){
                            if (cptcvalues.get(c.dataUsePurpose).DataUsePurpose.Name == c.dataUsePurpose){
                                ContactPointTypeConsent conupdate = new ContactPointTypeConsent();
                                conupdate.Id = cptcvalues.get(c.dataUsePurpose).Id;
                                if ((cptcvalues.get(c.dataUsePurpose).Consent_Text_Version__c != null && integer.valueOf(cptcvalues.get(c.dataUsePurpose).Consent_Text_Version__c) != integer.valueOf(c.captureVersion) 
                                    && c.privacyConsentStatus != 'opt-out') || cptcvalues.get(c.dataUsePurpose).PrivacyConsentStatus == 'OptOut' && c.privacyConsentStatus == 'opt-in'){
                                    dupforcreation.add(c.dataUsePurpose);
                                    consentvalues.put(c.dataUsePurpose, c);
                                    if (cptcvalues.get(c.dataUsePurpose).PrivacyConsentStatus == 'OptIn' && salesorgsoidoi.get(wrappedvalues.sales_organization) != 'DOI'){
                                        conupdate.EffectiveTo = System.Now();
                                        conupdate.PrivacyConsentStatus = 'OptOut';
                                    }
                                    cptcupdate.add(conupdate);
                                }
                                else {
                                    if (c.privacyConsentStatus == 'Opt-Out' && cptcvalues.get(c.dataUsePurpose).PrivacyConsentStatus == 'OptIn'){
                                        conupdate.PrivacyConsentStatus = 'OptOut';
                                        //conupdate.Consent_Text_Version__c = string.valueOf(integer.valueOf(cptcvalues.get(c.dataUsePurpose).Consent_Text_Version__c));
                                        conupdate.EffectiveTo = System.Now();
                                        conupdate.PartyId = individualId;
                                        cptcupdate.add(conupdate);
                                        updateforleadorcontact.put(c.dataUsePurpose, conupdate);
                                    }
                                }
                            }
                        } else {
                            dupforcreation.add(c.dataUsePurpose);
                            consentvalues.put(c.dataUsePurpose, c);
                        }
                    }
                    else{
                        //for no contact point type consent yet
                        dupforcreation.add(c.dataUsePurpose);
                        consentvalues.put(c.dataUsePurpose, c);
                    }
                }
                if (!cptcupdate.isEmpty()){
                    update cptcupdate;
                }

                if (!dupforcreation.isEmpty()){

                    for (String dup : dupforcreation){
                        ContactPointTypeConsent cptcvaluesforinsert = new ContactPointTypeConsent();
                        cptcvaluesforinsert.Name = individualName + ' ' + dup + ' ' + wrappedvalues.RequestData.datetimevalue;
                        cptcvaluesforinsert.CaptureSource = wrappedvalues.RequestData.consentSource;
                        removebefore = wrappedvalues.RequestData.sourceUrl;
                        cptcvaluesforinsert.Capture_URL__c = removebefore.substringBefore('?');
                        cptcvaluesforinsert.Consent_Capture_IP_Address__c = wrappedvalues.RequestData.ip;
                        cptcvaluesforinsert.CaptureDate = wrappedvalues.RequestData.datetimevalue;
                        cptcvaluesforinsert.DataUsePurposeId = datausepurposeIds.get(dup);
                        cptcvaluesforinsert.CaptureContactPointType = 'Web';
                    	cptcvaluesforinsert.ContactPointType = 'Email';
                        cptcvaluesforinsert.Consent_Text_Version__c = string.valueOf(integer.valueOf(consentvalues.get(dup).captureVersion));
                        if (salesorgsoidoi.get(wrappedvalues.sales_organization) == 'DOI'){
                            if (consentvalues.get(dup).privacyConsentStatus == 'Opt-In'){
                                cptcvaluesforinsert.PrivacyConsentStatus = 'Seen';
                            }
                            else {
                                if (consentvalues.get(dup).privacyConsentStatus == 'Opt-Out'){
                                    cptcvaluesforinsert.PrivacyConsentStatus = 'OptOut';
                                    cptcvaluesforinsert.EffectiveTo = System.Now();
                                }
                            }
                        }
                        else {
                            if (consentvalues.get(dup).privacyConsentStatus == 'Opt-Out'){
                                cptcvaluesforinsert.PrivacyConsentStatus = 'OptOut';
                                cptcvaluesforinsert.EffectiveTo = System.Now();
                            }
                            else {
                                if (consentvalues.get(dup).privacyConsentStatus == 'Opt-In'){
                                    cptcvaluesforinsert.PrivacyConsentStatus = 'OptIn';
                                	cptcvaluesforinsert.EffectiveFrom = System.Now();
                                }
                            }
                            
                        }
                        cptcvaluesforinsert.PartyId = individualId;
                        if (consentvalues.get(dup).privacyConsentStatus == 'Opt-In'){
                            cptcinsert.add(cptcvaluesforinsert);
                        }
                        updateforleadorcontact.put(dup, cptcvaluesforinsert);
                    }
                    if (!cptcinsert.isEmpty()){
                        insert cptcinsert;
                    }
                }
            }
            else if (wrappedvalues.consent != null && wrappedvalues.action == 'Confirm'){
                Set<Id> cptcIds = new Set<Id>();
                Set<String> datausepurposetoconfirm = new Set<String>();
                for (Consent c : wrappedvalues.consent){
                    if (c.Id != null){
                        cptcIds.add(c.Id);
                    }
                }
                if (!cptcIds.isEmpty()){
                    List<ContactPointTypeConsent> cptclistforconfirm = [Select Id, PrivacyConsentStatus, Consent_Text_Version__c, CaptureContactPointType, DataUsePurpose.Name, 
                                                                        LastModifiedDate, DataUsePurposeId, Consent_Capture_IP_Address__c, Capture_URL__c 
                                                                        from ContactPointTypeConsent where Id = :cptcIds];
                    if (!cptclistforconfirm.isEmpty()){
                        for (ContactPointTypeConsent cptcval : cptclistforconfirm){
                            if (cptcval.PrivacyConsentStatus == 'Seen'){
                                ContactPointTypeConsent updatecptc = new ContactPointTypeConsent();
                                updatecptc.Id = cptcval.Id;
                                updatecptc.PrivacyConsentStatus = 'OptIn';
                                updatecptc.EffectiveFrom = System.Now();
                                updatecptc.DoubleConsentCaptureDate = System.now();
                                if (cptcval.Capture_URL__c == null){
                                    updatecptc.Capture_URL__c = wrappedvalues.RequestData.consentSource;
                                }
                                if (cptcval.Consent_Capture_IP_Address__c == null){
                                    updatecptc.Consent_Capture_IP_Address__c = wrappedvalues.RequestData.ip;
                                }
                                datausepurposetoconfirm.add(cptcval.DataUsePurpose.Name);
                                cptcupdate.add(updatecptc);
                                updateforleadorcontact.put(cptcval.DataUsePurpose.Name, updatecptc);
                            }
                        }
                        
                        List<ContactPointTypeConsent> cptclistupdatetooptout = [Select Id, PrivacyConsentStatus, Consent_Text_Version__c, CaptureContactPointType, DataUsePurpose.Name, 
                                                                           	    LastModifiedDate, DataUsePurposeId, EffectiveTo from ContactPointTypeConsent where PartyId = :individualId and ID NOT IN :cptcIds
                                                                                and DataUsePurpose.Name IN :datausepurposetoconfirm ORDER BY CreatedDate DESC LIMIT 30];
                        if (cptclistupdatetooptout != null){
                            for (ContactPointTypeConsent consentoptout : cptclistupdatetooptout){
                                if (consentoptout.PrivacyConsentStatus == 'OptIn'){
                                    ContactPointTypeConsent updatecptc = new ContactPointTypeConsent();
                                    updatecptc.Id = consentoptout.Id;
                                    updatecptc.PrivacyConsentStatus = 'OptOut';
                                    updatecptc.EffectiveTo = System.Now();
                                    cptcupdate.add(updatecptc);
                                }
                            }
                        }
                        
                        if (!cptcupdate.isEmpty()){
                            update cptcupdate;
                        }
                    }      
                }
                
            }
            CustomLogging.pop(); 
            return updateforleadorcontact;
        } catch (Exception ex) {
            CustomLogging.debugException(ex); 
            CustomLogging.pop(); 
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
            return null;
        }
  }
  private static Contact matchContact(String email, String emailHash){
        CustomLogging.push('matchContact', 'SM_ConsentAPI');
        try{
            List<Contact> contactquery = new List<Contact>();
            if (String.isNotEmpty(email) && String.isNotEmpty(emailhash)){
                contactquery = [Select Id, Email, Email_SHA256__c, IndividualId, Individual.Name, AccountId from Contact where Email = :email OR Email_SHA256__c = :emailHash];
            }
            else if (String.isNotEmpty(email) && String.isEmpty(emailHash)){
                contactquery = [Select Id, Email, Email_SHA256__c, IndividualId, Individual.Name, AccountId from Contact where Email = :email];
            }
            else if (String.isEmpty(email) && string.isNotEmpty(emailHash)){
                contactquery = [Select Id, Email, Email_SHA256__c, IndividualId, Individual.Name, AccountId from Contact where Email_SHA256__c = :emailHash];
            }
            
            Contact contactreturn;
            if (!contactquery.isEmpty()){
                for (Contact conval : contactquery){
                    if (conval.Email == email || conval.Email_SHA256__c == emailHash){
                        contactreturn = conval;
                    }
                    else {
                        contactreturn = null;
                    }
                }
            }
            CustomLogging.pop(); 
            return contactreturn;
        } catch (Exception ex) {
            CustomLogging.debugException(ex); 
            CustomLogging.pop(); 
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
            return null;
        }
    
  }

  private static Lead matchLead(String email, String emailHash){
        CustomLogging.push('matchLead', 'SM_ConsentAPI');
        try{
            List<Lead> leadquery = new List<Lead>();

            if (String.isNotEmpty(email) && String.isNotEmpty(emailhash)){
                leadquery = [Select Id, Email, Email_SHA256__c, IndividualId, Individual.Name from Lead where Email = :email OR Email_SHA256__c = :emailHash];
            }
            else if (String.isNotEmpty(email) && String.isEmpty(emailHash)){
                leadquery = [Select Id, Email, Email_SHA256__c, IndividualId, Individual.Name from Lead where Email = :email];
            }
            else if (String.isEmpty(email) && string.isNotEmpty(emailHash)){
                leadquery = [Select Id, Email, Email_SHA256__c, IndividualId, Individual.Name from Lead where Email_SHA256__c = :emailHash];
            }
            
            Lead leadreturn;
            if (!leadquery.isEmpty()){
                for (Lead leadval : leadquery){
                    if (leadval.Email == email || leadval.Email_SHA256__c == emailHash){
                        leadreturn = leadval;
                    }
                    else {
                        leadreturn = null;
                    }
                }
            }
            CustomLogging.pop(); 
            return leadreturn;
        } catch (Exception ex) {
            CustomLogging.debugException(ex); 
            CustomLogging.pop(); 
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
            return null;
        }
  }

  private static void updateLead(String Id, Map<String, ContactPointTypeConsent> consentMap, InboundLead wrappedvalues, InboundLeadResponse errorresults, InboundLeadResponse successresults, List<Custom_Log__c> customloggingadd){
        CustomLogging.push('updateLead', 'SM_ConsentAPI');
        try{
            Map<String,String> salesorgsoidoi = SM_GetMetadata.getsalesorgdoisoi();
            List<Lead> leadupdate = new List<Lead>();
            if (!consentMap.isEmpty()){
                Lead updateLead = new Lead();
                updateLead.Id = Id;
                Map<String, String> datausepurposeIds = fetchDataUsePurposeIds();
                Set<String> loopthisids = datausepurposeIds.keyset();
                Map<String, String> privacyconsentstatusmap = fetchPrivacyConsentStatus();
                String parsingTextvalue;
                for (String val : loopthisids){
                    if (consentMap.keyset().contains(val) == true){
                        if (val == SM_Constants.Marketing){
                            if (consentMap.get(val).Consent_Text_Version__c != null){
                                updateLead.Consent_Version_Marketing__c = integer.valueOf(consentMap.get(val).Consent_Text_Version__c);
                            }
                            updateLead.Consent_Status_Marketing__c = privacyconsentstatusmap.get(consentMap.get(val).PrivacyConsentStatus);
                            }
                        else if (val == SM_Constants.Profiling){
                            if (consentMap.get(val).Consent_Text_Version__c != null){
                                updateLead.Consent_Version_Profiling__c = integer.valueOf(consentMap.get(val).Consent_Text_Version__c);
                            }
                            updateLead.Consent_Status_Profiling__c = privacyconsentstatusmap.get(consentMap.get(val).PrivacyConsentStatus);
                        }
                        else if (val == SM_Constants.Survey){
                            if (consentMap.get(val).Consent_Text_Version__c != null){
                                updateLead.Consent_Version_Surveys__c = integer.valueOf(consentMap.get(val).Consent_Text_Version__c);
                            }
                            updateLead.Consent_Status_Surveys__c = privacyconsentstatusmap.get(consentMap.get(val).PrivacyConsentStatus);
                        } 

                        if ((salesorgsoidoi.get(wrappedvalues.sales_organization) == 'DOI' && (privacyconsentstatusmap.get(consentMap.get(val).PrivacyConsentStatus) == 'Pending')) || 
                            (salesorgsoidoi.get(wrappedvalues.sales_organization) == 'SOI' && (privacyconsentstatusmap.get(consentMap.get(val).PrivacyConsentStatus) == 'Opt-In'))  &&
                            privacyconsentstatusmap.get(consentMap.get(val).CaptureSource) != 'Sales Cloud'){
                            if (parsingTextvalue == null){
                                parsingTextvalue = consentMap.get(val).Id + '|' + val + '^';
                            }
                            else{
                                parsingTextvalue = parsingTextvalue + consentMap.get(val).Id + '|' + val + '^';
                            }
                        }
                        if (updateLead.Consent_Status_Marketing__c == 'Opt-Out' && updateLead.Consent_Status_Profiling__c == 'Opt-Out' && updateLead.Consent_Status_Surveys__c == 'Opt-Out'){
                            updateLead.HasOptedOutOfEmail = true;
                        }
                        else {
                            updateLead.HasOptedOutOfEmail = false;
                        }
                    }
                }
                leadupdate.add(updateLead);
                if (!leadupdate.isEmpty()){
                    Database.SaveResult[] srErrorList = Database.update(leadupdate, false);
                    for (Database.SaveResult sr : srErrorList) {
                        if (sr.isSuccess()) {
                        successresults.leadId = sr.getId();
                        successresults.leadstatus = 'Lead Updated';
                        } else {
                            Custom_Log__c log = new Custom_Log__c();
                            log.StackTrace__c = 'SM_ConsentAPI : consentapi SM_ConsentAPI : updateLead';
                            log.Message__c = sr.getErrors()[0].getMessage() + ' status code: ' + sr.getErrors()[0].getStatusCode() + ' field: ' + sr.getErrors()[0].getFields();
                            log.LogType__c = 'Exception';
                            log.Sequence__c = 0;
                            log.Limits__c = getLimits();
                            log.ExceptionType__c = 'System.DMLException';
                            customloggingadd.add(log);
                        
                            errorresults.leadId = sr.getId();
                            errorresults.leadstatus = sr.getErrors()[0].getMessage();
                        }
                    }
                }
                if (parsingTextvalue != null){
                    if (salesorgsoidoi.get(wrappedvalues.sales_organization) == 'DOI'){
                        Journey_Trigger__c journeytriggervalues = new Journey_Trigger__c();
                        journeytriggervalues.Parsing_Text__c = parsingTextvalue.removeEnd('^');
                        journeytriggervalues.Journey_Trigger_Type__c = 'Consent';
                        journeytriggervalues.Journey_Trigger_SubType__c = 'Double Opt-In';
                        journeytriggervalues.Lead__c = Id;
                        insert journeytriggervalues;
                    } else {
                        if (salesorgsoidoi.get(wrappedvalues.sales_organization) == 'SOI'){
                            Journey_Trigger__c journeytriggervalues = new Journey_Trigger__c();
                            journeytriggervalues.Parsing_Text__c = parsingTextvalue.removeEnd('^');
                            journeytriggervalues.Journey_Trigger_Type__c = 'Consent';
                            journeytriggervalues.Journey_Trigger_SubType__c = 'Single Opt-In';
                            journeytriggervalues.Lead__c = Id;
                            insert journeytriggervalues;
                        }
                    }
                }
            }
        } catch (Exception ex) {
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

  public static Map<String,String> fetchPrivacyConsentStatus(){
    Map <String, String> privacyConsentStatusMap = new Map<String, String>();
    privacyConsentStatusMap.put('OptIn', 'Opt-In');
    privacyConsentStatusMap.put('OptOut', 'Opt-Out');
    privacyConsentStatusMap.put('Seen', 'Pending');

    return privacyConsentStatusMap;
  }

  static private string getLimits(){        
    string limitstring = '';        
    limitstring += 'Query Limits: '+ Limits.getQueries() + '/' + Limits.getLimitQueries() +'\n';
    limitstring += 'DML Rows Limits: '+Limits.getDMLRows()+'/' + Limits.getLimitDMLRows()+'\n';
    limitstring += 'Heap Size Limits: '+Limits.getHeapSize()+'/' +Limits.getLimitHeapSize()+'\n';
    limitstring += 'Query Return Limits: '+Limits.getQueryRows()+'/' + Limits.getLimitQueryRows()+'\n';      
    limitstring += 'Aggregate Queries: '+Limits.getAggregateQueries()+'/' + Limits.getLimitAggregateQueries();
    limitstring += 'Callouts: '+Limits.getCallouts()+'/' +Limits.getLimitCallouts();    
    limitstring += 'CPU Time: '+Limits.getCpuTime()+'/' +Limits.getLimitCpuTime();
    limitstring += 'DML Statements: '+Limits.getDMLStatements()+'/' +Limits.getLimitDMLStatements();
    limitstring += 'Email Invocations: '+Limits.getEmailInvocations()+'/' +Limits.getLimitEmailInvocations();    
    limitstring += 'Future Calls: '+Limits.getFutureCalls()+'/' +Limits.getLimitFutureCalls();     
    limitstring += 'Query Locator Rows: '+Limits.getQueryLocatorRows() +'/'+Limits.getLimitQueryLocatorRows();     
    
    return limitstring.left(254);
    
  }

  public class InboundLead {
    public String sales_organization;
    public RequestData requestData;
    public List<Consent> consent;
    public Channel channel;
    public String action;
  }
  public class RequestData {
    public String messageId;
    public String utmcsr;
    public String utmcmd;
    public String utmccn;
    public String utmcct;
    public String utmctr;
    public String utmgclid;
    public String utmdclid;
    public String consentSource;
    public String sourceUrl;
    public String ip;
    public DateTime datetimevalue;
    public String trackingcookie;
  }
  public class Consent {
    public String dataUsePurpose;
    public String privacyConsentStatus;
    public Integer captureVersion;
    public ID id;

  }
  public class Channel {
    public String email;
    public String emailhash;
  } 
  public class InboundLeadResponse {
    public ID leadId;
    public ID updatedLeadId;
    public ID contactId;
    public ID campaignMemberId;
    public ID taskId;
    public string leadstatus;
    public string leadupdatedstatus;
    public String contactstatus;
    public String taskStatus;
    public String campaignMemberStatus;
    public String errorMessage;
    public String email;
  }
}