@RestResource(urlMapping='/formapi')
global without sharing class SM_FormAPI {
  public class SM_InboundLeadException extends Exception {
  }
  @HttpPost
  global static void formapi() {
        CustomLogging.push('formapi', 'SM_FormAPI');
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        try {
            if (TriggerSettings__c.getInstance().SM_FormAPImethod__c == true){
                //convert to Apex Object
                String descvalues;
                String newleadId;
                String newlycreatedleadId;
                List<Custom_Log__c> customloggingadd = new List<Custom_Log__c>();
                Object inboundvalue = JSON.deserialize(req.requestBody.toString(),InboundLead.class);
                Map<String, InboundLeadResponse> responseMap = new Map<String, InboundLeadResponse>();
                InboundLeadResponse successresults = new InboundLeadResponse();
                InboundLeadResponse errorresults = new InboundLeadResponse();
                List<InboundLeadResponse> errormess = new List<InboundLeadResponse>();
                List<InboundLeadResponse> returnresults = new List<InboundLeadResponse>();
                List<CampaignMember> insertcampaignmember = new List<CampaignMember>();
                Lead leadreturnval;
                List<Lead> newleadlist = new List<Lead>();
                List<Case> newcaselist = new List<Case>();
                Map<String,String> salesorgsoidoi = SM_GetMetadata.getsalesorgdoisoi();
                Map<String, Queue_Lead_Tasks__mdt> taskcreationchecker = SM_GetMetadata.getqueueleadtasks();
                Map<String,String> campaignmapfromCMDT = SM_GetMetadata.getcampaignfromcmdt();
                InboundLead wrappedvalues = (InboundLead) inboundvalue;
                
                Boolean casecreationchecker = false;
                String keyforcase = wrappedvalues.sales_organization + wrappedvalues.Details.touchpointType;
                
                if (taskcreationchecker.containsKey(keyforcase)){
                    if (taskcreationchecker.get(keyforcase).Queue_for_Case__c != null){
                        casecreationchecker = true;
                    }
                } 
                
                if (casecreationchecker == true){
                    //create case here
                    String emailhashholder;
                    String descriptionval;
                    String physicalassetId;
                    descriptionval = 'LastName : ' + wrappedvalues.Individual.lastname + '\n' + 'Company : ' +wrappedvalues.Individual.company + '\n' + 
                        			 'Phone : ' + wrappedvalues.Individual.phone + '\n' + 'PostalCode : ' + wrappedvalues.Individual.postalCode + '\n' + 'Street : ' + wrappedvalues.Individual.street;
                    List<CustomFields> customfieldscheck = wrappedvalues.CustomFields;
                    Map<String, String> customfieldmap = new Map<String,String>();
                    if (customfieldscheck != null){
                        for (CustomFields c : wrappedvalues.customFields){
                            customfieldmap.put(c.Name, c.value);
                            if (descvalues == null){
                                descvalues = c.Name + ': ' + c.value + ', \n';
                            }
                            else {
                                descvalues = descvalues + c.Name + ': ' + c.value + ', \n';
                            }
                        }
                    }
                    if (customfieldmap.containsKey('machinenumber')){
                        physicalassetId = matchPhysicalAsset(customfieldmap.get('machinenumber'));
                    }
                    Contact findcontact = matchContact(wrappedvalues.Channel.email, emailhashholder);
                    Case casecreate = new Case();
                    casecreate.Origin = 'Web';
                    casecreate.SalesOrganization__c = wrappedvalues.sales_organization;
                    casecreate.Type = 'Qualify Case';
                    casecreate.Touchpoint_Type__c = wrappedvalues.Details.touchpointType;
                    casecreate.OwnerId = taskcreationchecker.get(keyforcase).Queue_for_Case__c;
                    casecreate.RecordTypeId = SM_Constants.recordTypeIdQualifyCase;
                    casecreate.Description = descriptionval + '\n' + descvalues.removeEnd(', \n');
                    if (findcontact != null){
                        casecreate.SuppliedEmail = findcontact.Email;
                        casecreate.ContactId = findcontact.Id;
                    } else {
                        casecreate.SuppliedEmail = wrappedvalues.Channel.email;
                    }
                    if (physicalassetId != null){
                        casecreate.PhysicalAsset__c = physicalassetId;
                    }
                    if (customfieldmap.containsKey('coffeeisrunning')){
                        casecreate.CoffeeIsRunning__c = Boolean.valueOf(customfieldmap.get('coffeeisrunning'));
                    }
                    if (customfieldmap.containsKey('shortdescription')){
                        casecreate.Subject = customfieldmap.get('shortdescription');
                    }
                    
                    newcaselist.add(casecreate);
                    // insert case
                    Database.SaveResult[] srErrorList = Database.insert(newcaselist, false);
                    for (Database.SaveResult sr : srErrorList) {
                        if (sr.isSuccess()) {
                            successresults.caseId = sr.getId();
                            successresults.casestatus = 'Case Created';
                        } 
                        else {
                            Custom_Log__c log = new Custom_Log__c();
                            log.StackTrace__c = 'SM_FormAPI : formapi';
                            log.Message__c = sr.getErrors()[0].getMessage() + ' status code: ' + sr.getErrors()[0].getStatusCode() + ' field: ' + sr.getErrors()[0].getFields();
                            log.LogType__c = 'Exception';
                            log.Sequence__c = 0;
                            log.Limits__c = getLimits();
                            log.ExceptionType__c = 'System.DMLException';
                            customloggingadd.add(log);
                            
                            errorresults.caseId = sr.getId();
                            errorresults.casestatus = sr.getErrors()[0].getMessage();
                        }
                    }
                } else {
                    List<CustomFields> customfieldscheck = wrappedvalues.CustomFields;
                    
                    if (customfieldscheck != null){
                        for (CustomFields c : wrappedvalues.customFields){
                            if (descvalues == null){
                                descvalues = c.Name + ': ' + c.value + ', \n';
                            }
                            else {
                                descvalues = descvalues + c.Name + ': ' + c.value + ', \n';
                            }
                        }
                    }
                    
                    Contact contactreturnval = matchContact(wrappedvalues.Channel.email, wrappedvalues.Channel.emailhash);
                    if (contactreturnval == null){
                        leadreturnval = matchLead(wrappedvalues.Channel.email, wrappedvalues.Channel.emailhash);
                    } 
                
                    if(contactreturnval == null && leadreturnval == null){
                        Lead newl = new Lead();
                        newl.Sales_Organization__c = wrappedvalues.sales_organization;
                        newl.Cookie__c = wrappedvalues.RequestData.trackingcookie;
                        newl.Opt_in_Source__c = wrappedvalues.RequestData.consentSource;
                        newl.Consent_Registration_Source_URLs__c = wrappedvalues.RequestData.sourceUrl;
                        newl.Consent_Registration_IP_Address__c = wrappedvalues.RequestData.ip;
                        newl.Consent_Registration_Date__c = wrappedvalues.RequestData.datetimevalue;
                        newl.utmcsr__c = wrappedvalues.RequestData.utmcsr;
                        newl.utmcmd__c = wrappedvalues.RequestData.utmcmd;
                        newl.utmccn__c = wrappedvalues.RequestData.utmccn;
                        newl.utmcct__c = wrappedvalues.RequestData.utmcct;
                        newl.utmctr__c = wrappedvalues.RequestData.utmctr;
                        newl.utmgclid__c = wrappedvalues.RequestData.utmgclid;
                        newl.utmdclid__c = wrappedvalues.RequestData.utmdclid;
                        newl.Email = wrappedvalues.Channel.email;
                        newl.Email_SHA256__c = wrappedvalues.Channel.emailhash;
                        newl.Salutation = wrappedvalues.Individual.salutation;
                        newl.FirstName = wrappedvalues.Individual.firstname;
                        newl.MiddleName = wrappedvalues.Individual.middleName;
                        newl.LastName = wrappedvalues.Individual.lastname;
                        newl.Company = wrappedvalues.Individual.company;
                        newl.Phone = wrappedvalues.Individual.phone;
                        newl.Main_Postal_Code__c = wrappedvalues.Individual.postalCode;
                        newl.Main_City__c = wrappedvalues.Individual.city;
                        newl.Main_Country__c = wrappedvalues.Individual.country;
                        newl.Main_House_Number__c = wrappedvalues.Individual.houseNumber;
                        newl.Main_State__c = wrappedvalues.Individual.state;
                        newl.Main_Street__c = wrappedvalues.Individual.street;
                        newl.Language__c = wrappedvalues.Individual.language;
                        newl.Title = wrappedvalues.Individual.title;
                        newl.Subject__c = wrappedvalues.Details.subject;
                        newl.Campaign_Online_ID__c = wrappedvalues.Details.campaignId;
                        newl.Touchpoint_Type__c = wrappedvalues.Details.touchpointType;
                        newl.LeadSource = wrappedvalues.Details.leadSource;
                        if (descvalues != null){
                            newl.Description = descvalues.removeEnd(', \n');
                        }
                        newleadlist.add(newl);
                        //  insert newleadlist;
                        Database.SaveResult[] srErrorList = Database.insert(newleadlist, false);
                        for (Database.SaveResult sr : srErrorList) {
                            if (sr.isSuccess()) {
                                successresults.leadId = sr.getId();
                                successresults.leadstatus = 'Lead Created';
                            } 
                            else {
                                Custom_Log__c log = new Custom_Log__c();
                                log.StackTrace__c = 'SM_FormAPI : formapi';
                                log.Message__c = sr.getErrors()[0].getMessage() + ' status code: ' + sr.getErrors()[0].getStatusCode() + ' field: ' + sr.getErrors()[0].getFields();
                                log.LogType__c = 'Exception';
                                log.Sequence__c = 0;
                                log.Limits__c = getLimits();
                                log.ExceptionType__c = 'System.DMLException';
                                customloggingadd.add(log);
                                
                                errorresults.leadId = sr.getId();
                                errorresults.leadstatus = sr.getErrors()[0].getMessage();
                                errorresults.email = wrappedvalues.Channel.email;
                            }
                        }
                        if (!newleadlist.isEmpty()){
                            for (Lead l : newleadlist){
                                if (l.Id != null){
                                    newleadid = l.Id;
                                }
                            }
                        }
                    }
                    List<Consent> consentchecker = wrappedvalues.consent;
                    if (TriggerSettings__c.getInstance().ConsentTrigger__c == true){
                        if (contactreturnval != null){ // check emptystring
                            Map<String, ContactPointTypeConsent> contactvalues = new Map<String, ContactPointTypeConsent>();
                            if (contactreturnval != null && consentchecker != null){
                                if (!consentchecker.isEmpty()){
                                    contactvalues = checkContactPointTypeConsent(contactreturnval.IndividualId, contactreturnval.Individual.Name, wrappedvalues);
                                }
                            }
                            
                            List<Contact> contactupdate = new List<Contact>();
                            Contact updateContact = new Contact();
                            updateContact.Id = contactreturnval.Id;
                            Map<String, String> datausepurposeIds = fetchDataUsePurposeIds();
                            Set<String> loopthis = datausepurposeIds.keyset();
                            Map<String, String> privacyconsentstatusmap = fetchPrivacyConsentStatus();
                            String parsingTextvalue;
                            
                            if (contactreturnval.Cookie__c == null && wrappedvalues.RequestData.trackingcookie != null){
                                 updateContact.Cookie__c = wrappedvalues.RequestData.trackingcookie;
                            }
                            
                            if (contactreturnval.Opt_in_Source__c == null && wrappedvalues.RequestData.consentSource != null){
                                 updateContact.Opt_in_Source__c = wrappedvalues.RequestData.consentSource;
                            }
                            
                            if (contactreturnval.Consent_Registration_Source_URLs__c == null && wrappedvalues.RequestData.sourceUrl != null){
                                 updateContact.Consent_Registration_Source_URLs__c = wrappedvalues.RequestData.sourceUrl;
                            }
                            
                            if (contactreturnval.Consent_Registration_IP_Address__c == null && wrappedvalues.RequestData.ip != null){
                                 updateContact.Consent_Registration_IP_Address__c = wrappedvalues.RequestData.ip;
                            }
                            
                            if (contactreturnval.Consent_Registration_Date__c == null && wrappedvalues.RequestData.datetimevalue != null){
                                 updateContact.Consent_Registration_Date__c = wrappedvalues.RequestData.datetimevalue;
                            }
                            
                            if (contactreturnval.utmcsr__c == null && wrappedvalues.RequestData.utmcsr != null){
                                 updateContact.utmcsr__c = wrappedvalues.RequestData.utmcsr;
                            }
                            
                            if (contactreturnval.utmcmd__c == null && wrappedvalues.RequestData.utmcmd != null){
                                 updateContact.utmcmd__c = wrappedvalues.RequestData.utmcmd;
                            }
                            
                            if (contactreturnval.utmccn__c == null && wrappedvalues.RequestData.utmccn != null){
                                 updateContact.utmccn__c = wrappedvalues.RequestData.utmccn;
                            }
                            
                            if (contactreturnval.utmcct__c == null && wrappedvalues.RequestData.utmcct != null){
                                 updateContact.utmcct__c = wrappedvalues.RequestData.utmcct;
                            }
                            
                            if (contactreturnval.utmctr__c == null && wrappedvalues.RequestData.utmctr != null){
                                 updateContact.utmctr__c = wrappedvalues.RequestData.utmctr;
                            }
                            
                            if (contactreturnval.utmgclid__c == null && wrappedvalues.RequestData.utmgclid != null){
                                 updateContact.utmgclid__c = wrappedvalues.RequestData.utmgclid;
                            }
                            
                            if (contactreturnval.utmdclid__c == null && wrappedvalues.RequestData.utmdclid != null){
                                 updateContact.utmdclid__c = wrappedvalues.RequestData.utmdclid;
                            }
                            
                            if (contactreturnval.Salutation == null && wrappedvalues.Individual.salutation != null){
                                 updateContact.Salutation = wrappedvalues.Individual.salutation;
                            }
                            
                            if (contactreturnval.FirstName == null && wrappedvalues.Individual.firstname != null){
                                 updateContact.FirstName = wrappedvalues.Individual.firstname;
                            }
                            
                            if (contactreturnval.MiddleName == null && wrappedvalues.Individual.middlename != null){
                                 updateContact.MiddleName = wrappedvalues.Individual.middlename;
                            }
                            
                            if (contactreturnval.LastName == null && wrappedvalues.Individual.lastname != null){
                                 updateContact.LastName = wrappedvalues.Individual.lastname;
                            }
							
							if (contactreturnval.Phone == null && wrappedvalues.Individual.phone != null){
                                 updateContact.Phone = wrappedvalues.Individual.phone;
                            }
                            
                            if (contactreturnval.Preferred_Language__c == null && wrappedvalues.Individual.language != null){
                                 updateContact.Preferred_Language__c = wrappedvalues.Individual.language;
                            }
                            
                            if (!contactvalues.isEmpty()){
                                for (String val : loopthis){
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
                                            (salesorgsoidoi.get(wrappedvalues.sales_organization) == 'SOI' && (privacyconsentstatusmap.get(contactvalues.get(val).PrivacyConsentStatus) == 'Opt-In'))){
                                            if (parsingTextvalue == null){
                                                parsingTextvalue = contactvalues.get(val).Id + '|' + val + '^';
                                            }
                                            else{
                                                parsingTextvalue = parsingTextvalue + contactvalues.get(val).Id + '|' + val + '^';
                                            }
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

                            contactupdate.add(updateContact);
                            
                            if (!contactupdate.isEmpty() && !contactupdate.toString().containsOnly('(Contact:{Id=' + contactreturnval.Id +'})')){
                                Database.SaveResult[] srErrorList = Database.update(contactupdate, false);
                                for (Database.SaveResult sr : srErrorList) {
                                    if (sr.isSuccess()) {
                                        successresults.contactId = sr.getId();
                                        successresults.contactstatus = 'Contact Updated';
                                    } else {
                                        Custom_Log__c log = new Custom_Log__c();
                                        log.StackTrace__c = 'SM_FormAPI : formapi';
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
                        }
                        else if (leadreturnval != null){
                            Map<String, ContactPointTypeConsent> leadvalues = checkContactPointTypeConsent(leadreturnval.IndividualId, leadreturnval.Individual.Name, wrappedvalues );
                            updateLead(leadreturnval, leadvalues, wrappedvalues, errorresults, successresults, customloggingadd);
                        }
                        else {
                                String idofnewlycreatedlead, indid, indname;
                                Lead leadupdate = new Lead();
                                if (!newleadlist.isEmpty()){
                                    for (Lead l : newleadlist){
                                        if (l.Id != null){
                                            idofnewlycreatedlead = l.Id;
                                            newleadid = l.Id;
                                            leadupdate = l;
                                        }
                                    }
                                }
                                List<Lead> consentfornewlead = new List<Lead>();
                                consentfornewlead = [Select Id, Individual.Id, Individual.Name, Cookie__c, Opt_in_Source__c, Consent_Registration_Source_URLs__c, Consent_Registration_IP_Address__c,
                                                     Consent_Registration_Date__c, utmcsr__c, utmcmd__c, utmccn__c, utmcct__c, utmctr__c, utmgclid__c, utmdclid__c, Salutation, FirstName, MiddleName, 
                                                     LastName, Company, Phone, Main_Postal_Code__c, Main_City__c, Main_Country__c, Main_House_Number__c, Main_State__c, Main_Street__c, Language__c, 
                                                     Title, Subject__c, Campaign_Online_ID__c from Lead where Id = :idofnewlycreatedlead];
                                for (Lead lval : consentfornewlead){
                                    if (lval.IndividualId != null){
                                        indid = lval.IndividualId;
                                        indname = lval.Individual.Name;
                                    }
                                }
                                Map<String, ContactPointTypeConsent> newleadvalues = new Map<String, ContactPointTypeConsent>();
                                if (indid != null && indname != null){
                                    newleadvalues = checkContactPointTypeConsent(indid, indname, wrappedvalues);
                                }
                                if (!newleadvalues.isEmpty()){
                                    updateLead(leadupdate, newleadvalues, wrappedvalues, errorresults, successresults, customloggingadd);
                                }
                        }
                    }
                    //Create Task here
                    
                    Boolean checker = false;
                    String ownerId;
                    String queueleadkey = wrappedvalues.sales_organization + wrappedvalues.Details.touchpointType;
                    if (taskcreationchecker.containsKey(queueleadkey)){
                        checker = taskcreationchecker.get(queueleadkey).Create_Task_from_Form_API__c;
                        ownerId = taskcreationchecker.get(queueleadkey).Queue_for_Task_Record__c;
                    }
                    else {
                        queueleadkey = wrappedvalues.sales_organization + 'Default';
                        checker = taskcreationchecker.get(queueleadkey).Create_Task_from_Form_API__c;
                        ownerId = taskcreationchecker.get(queueleadkey).Queue_for_Task_Record__c;
                    }
                    List<Task> taskinsert = new List<Task>();
                    if (checker == true){
                        Task createTaskValues = new Task();
                        if (contactreturnval != null ){
                            createTaskValues.WhoId = contactreturnval.Id;
                            createTaskValues.WhatId = contactreturnval.AccountId;
                        }
                        else if (leadreturnval != null){
                            createTaskValues.WhoId = leadreturnval.Id;
                        }
                        else if (newleadId != null){
                            createTaskValues.WhoId = newleadId;
                        }
                        createTaskValues.OwnerId = ownerId;
                        createTaskValues.Status = 'Open';
                        createTaskValues.Subject = 'x';
                        if (descvalues != null || String.isNotEmpty(descvalues)){
                            createTaskValues.Description = descvalues.removeEnd(', \n') + ', \n' + 'subject : ' + wrappedvalues.Details.subject;
                        } else {
                            if (wrappedvalues.Details.subject != null){
                                createTaskValues.Description = 'subject : ' + wrappedvalues.Details.subject;
                            }
                        }
                        createTaskValues.ActivityDate = System.Today();
                        createTaskValues.Type = 'Campaign';
                        createTaskValues.Touchpoint_Type__c = wrappedvalues.Details.touchpointType;
                        createTaskValues.Task_Source__c = wrappedvalues.Details.leadSource;
                        createTaskValues.Sales_Organization__c = wrappedvalues.sales_organization;
                        createTaskValues.SAP_HANA_Queue_Task__c = true;
                        if (wrappedvalues.Details.campaignId != null){
                            createTaskValues.Campaign__c = wrappedvalues.Details.campaignId;
                        } else {
                            if (campaignmapfromCMDT.containsKey(wrappedvalues.sales_organization + wrappedvalues.Details.leadSource)){
                                createTaskValues.Campaign__c = campaignmapfromCMDT.get(wrappedvalues.sales_organization + wrappedvalues.Details.leadSource);
                            }
                        }
                        //   createTaskValues.Machine_Code__c = wrappedvalues.Individual.coffeemachinecode;
                        taskinsert.add(createTaskValues);
                    }
                    if (!taskinsert.isEmpty()){
                        // insert taskinsert;
                        Database.SaveResult[] srErrorList = Database.insert(taskinsert, false);
                        for (Database.SaveResult sr : srErrorList) {
                            if (sr.isSuccess()) {
                                successresults.taskId = sr.getId();
                                successresults.taskStatus = 'Task Created';
                            } else {
                                Custom_Log__c log = new Custom_Log__c();
                                log.StackTrace__c = 'SM_FormAPI : formapi';
                                log.Message__c = sr.getErrors()[0].getMessage() + ' status code: ' + sr.getErrors()[0].getStatusCode() + ' field: ' + sr.getErrors()[0].getFields();
                                log.LogType__c = 'Exception';
                                log.Sequence__c = 0;
                                log.Limits__c = getLimits();
                                log.ExceptionType__c = 'System.DMLException';
                                customloggingadd.add(log);
                                
                                errorresults.taskId = sr.getId();
                                errorresults.taskStatus = sr.getErrors()[0].getMessage();
                            }
                        }
                    }
                        
                    // Create Campaign
                    if (wrappedvalues.Details != null){
                        if (wrappedvalues.Details.campaignId != null){
                            CampaignMember campaignmemberval = new CampaignMember();
                            campaignmemberval.CampaignId = wrappedvalues.Details.campaignId;
                            if (contactreturnval != null){
                                campaignmemberval.ContactId = contactreturnval.Id;
                            } else if (leadreturnval != null){
                                campaignmemberval.LeadId = leadreturnval.Id;
                            } else {
                                if (newleadId != null){
                                    campaignmemberval.LeadId = newleadId;
                                }
                            }
                            insertcampaignmember.add(campaignmemberval);
                        } else {
                            if (campaignmapfromCMDT.containsKey(wrappedvalues.sales_organization + wrappedvalues.Details.leadSource)){
                                CampaignMember campaignmemberval = new CampaignMember();
                                campaignmemberval.CampaignId = campaignmapfromCMDT.get(wrappedvalues.sales_organization + wrappedvalues.Details.leadSource);
                                if (contactreturnval != null){
                                    campaignmemberval.ContactId = contactreturnval.Id;
                                } else if (leadreturnval != null){
                                    campaignmemberval.LeadId = leadreturnval.Id;
                                } else {
                                    if (newleadId != null){
                                        campaignmemberval.LeadId = newleadId;
                                    }
                                }
                                insertcampaignmember.add(campaignmemberval);
                            }
                        }
                    }
    
                    if (!insertcampaignmember.isEmpty()){
                        Database.SaveResult[] srErrorList = Database.insert(insertcampaignmember, false);
                        for (Database.SaveResult sr : srErrorList) {
                            if (sr.isSuccess()) {
                                successresults.campaignMemberId = sr.getId();
                                successresults.campaignMemberStatus = 'Campaign Created';
                            } else {
                                Custom_Log__c log = new Custom_Log__c();
                                log.StackTrace__c = 'SM_FormAPI : formapi';
                                log.Message__c = sr.getErrors()[0].getMessage() + ' status code: ' + sr.getErrors()[0].getStatusCode() + ' field: ' + sr.getErrors()[0].getFields();
                                log.LogType__c = 'Exception';
                                log.Sequence__c = 0;
                                log.Limits__c = getLimits();
                                log.ExceptionType__c = 'System.DMLException';
                                customloggingadd.add(log);
                                if (sr.getErrors()[0].getMessage() == 'Already a campaign member.'){
                                    successresults.campaignMemberId = sr.getId();
                                    successresults.campaignMemberStatus = sr.getErrors()[0].getMessage();
                                } else {
                                    errorresults.campaignMemberId = sr.getId();
                                    errorresults.campaignMemberStatus = sr.getErrors()[0].getMessage();
                                }
                            }
                        }
                    }
                }
                
               	
                if (errorresults.leadId != null || errorresults.updatedLeadId != null || errorresults.contactId != null || errorresults.campaignMemberId != null || 
                    errorresults.taskId != null || errorresults.leadstatus != null || errorresults.leadupdatedstatus != null || errorresults.contactstatus != null || errorresults.taskStatus != null || 
                    errorresults.campaignMemberStatus != null || errorresults.errorMessage != null || errorresults.email != null || errorresults.caseId != null || errorresults.casestatus != null){
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
        CustomLogging.push('checkContactPointTypeConsent', 'SM_FormAPI');
        try{
            List<Consent> consentchecker = wrappedvalues.consent;
            Map<String,String> salesorgsoidoi = SM_GetMetadata.getsalesorgdoisoi();
            DateTime recentmarketing, recentprofiling, recentsurvey;
            String recentmarketingId, recentprofilingId, recentsurveyId;
            Map<String,ContactPointTypeConsent> cptcvalues = new Map<String,ContactPointTypeConsent>();
            Set<String> dupforcreation = new Set<String>();
            Map<String, Consent> consentvalues = new Map<String, Consent>();
            List<ContactPointTypeConsent> cptcupdate = new List<ContactPointTypeConsent>();
            List<ContactPointTypeConsent> cptcinsert = new List<ContactPointTypeConsent>();
            Map<String, ContactPointTypeConsent> updateforleadorcontact = new Map<String, ContactPointTypeConsent>();
            Map<String, String> datausepurposeIds = fetchDataUsePurposeIds();
            String removebefore;
            if (consentchecker != null && !consentchecker.isEmpty()){
                
                List<ContactPointTypeConsent> cptclist = [Select Id, PrivacyConsentStatus, Consent_Text_Version__c, CaptureContactPointType, DataUsePurpose.Name, LastModifiedDate,
                                                        DataUsePurposeId from ContactPointTypeConsent where PartyId = :individualId ORDER BY CreatedDate DESC LIMIT 30];
                
                
                for (ContactPointTypeConsent cptcval : cptclist){
                    if (cptcvalues.isEmpty()){
                        cptcvalues.put(cptcval.DataUsePurpose.Name, cptcval);
                        
                    } else {
                        if (!cptcvalues.containsKey(cptcval.DataUsePurpose.Name)){
                            cptcvalues.put(cptcval.DataUsePurpose.Name, cptcval);
                        }
                    }
                }
    
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
                                        //conupdate.Consent_Text_Version__c = string.valueof(integer.valueOf(cptcvalues.get(c.dataUsePurpose).Consent_Text_Version__c));
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
                            } else {
                                if (consentvalues.get(dup).privacyConsentStatus == 'Opt-Out'){
                                    cptcvaluesforinsert.PrivacyConsentStatus = 'OptOut';
                                }
                            }
                        } else {
                            if (consentvalues.get(dup).privacyConsentStatus == 'Opt-Out'){
                                cptcvaluesforinsert.PrivacyConsentStatus = 'OptOut';
                            } else {
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
                return updateforleadorcontact;
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
        CustomLogging.push('matchContact', 'SM_FormAPI');
        try{
            List<Contact> contactquery = new List<Contact>();
            if (String.isNotEmpty(email) && String.isNotEmpty(emailhash)){
                contactquery = [Select Id, Email, Email_SHA256__c, IndividualId, Individual.Name, AccountId, Cookie__c, Opt_in_Source__c,Consent_Registration_Source_URLs__c,
                                Consent_Registration_IP_Address__c, Consent_Registration_Date__c, utmcsr__c, utmcmd__c, utmccn__c, utmcct__c, utmctr__c, utmgclid__c, utmdclid__c,
                                Salutation, FirstName, MiddleName, LastName, Phone, Preferred_Language__c from Contact where Email = :email OR Email_SHA256__c = :emailHash];
            }
            else if (String.isNotEmpty(email) && String.isEmpty(emailHash)){
                contactquery = [Select Id, Email, Email_SHA256__c, IndividualId, Individual.Name, AccountId, Cookie__c, Opt_in_Source__c,Consent_Registration_Source_URLs__c,
                                Consent_Registration_IP_Address__c, Consent_Registration_Date__c, utmcsr__c, utmcmd__c, utmccn__c, utmcct__c, utmctr__c, utmgclid__c, utmdclid__c,
                                Salutation, FirstName, MiddleName, LastName, Phone, Preferred_Language__c from Contact where Email = :email];
            }
            else if (String.isEmpty(email) && string.isNotEmpty(emailHash)){
                contactquery = [Select Id, Email, Email_SHA256__c, IndividualId, Individual.Name, AccountId, Cookie__c, Opt_in_Source__c,Consent_Registration_Source_URLs__c,
                                Consent_Registration_IP_Address__c, Consent_Registration_Date__c, utmcsr__c, utmcmd__c, utmccn__c, utmcct__c, utmctr__c, utmgclid__c, utmdclid__c,
                                Salutation, FirstName, MiddleName, LastName, Phone, Preferred_Language__c from Contact where Email_SHA256__c = :emailHash];
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
    
  private static String matchPhysicalAsset(String serialnumber){
        CustomLogging.push('matchPhysicalAsset', 'SM_FormAPI');
        try{
            string physicalassetID;
            List<PhysicalAsset__c> physicalassetrec = [Select Id, SerialNumber__c from PhysicalAsset__c where SerialNumber__c = :serialnumber Limit 1];
            if (!physicalassetrec.isEmpty()){
                for (PhysicalAsset__c prec : physicalassetrec){
                    physicalassetID = prec.Id;
                }
            }
            
            return physicalassetID;
        } catch (Exception ex) {
            CustomLogging.debugException(ex); 
            CustomLogging.pop(); 
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
            return null;
        }
  }

  private static Lead matchLead(String email, String emailHash){
        CustomLogging.push('matchLead', 'SM_FormAPI');
        try{
            List<Lead> leadquery = new List<Lead>();
            if (String.isNotEmpty(email) && String.isNotEmpty(emailhash)){
                leadquery = [Select Id, Email, Email_SHA256__c, IndividualId, Individual.Name, Cookie__c, Opt_in_Source__c, Consent_Registration_Source_URLs__c, Consent_Registration_IP_Address__c,
                             Consent_Registration_Date__c, utmcsr__c, utmcmd__c, utmccn__c, utmcct__c, utmctr__c, utmgclid__c, utmdclid__c, Salutation, FirstName, MiddleName, LastName, Company, 
                             Phone, Main_Postal_Code__c, Main_City__c, Main_Country__c, Main_House_Number__c, Main_State__c, Main_Street__c, Language__c, Title, Subject__c, Campaign_Online_ID__c
                             from Lead where Email = :email OR Email_SHA256__c = :emailHash];
            }
            else if (String.isNotEmpty(email) && String.isEmpty(emailHash)){
                leadquery = [Select Id, Email, Email_SHA256__c, IndividualId, Individual.Name, Cookie__c, Opt_in_Source__c, Consent_Registration_Source_URLs__c, Consent_Registration_IP_Address__c,
                             Consent_Registration_Date__c, utmcsr__c, utmcmd__c, utmccn__c, utmcct__c, utmctr__c, utmgclid__c, utmdclid__c, Salutation, FirstName, MiddleName, LastName, Company, 
                             Phone, Main_Postal_Code__c, Main_City__c, Main_Country__c, Main_House_Number__c, Main_State__c, Main_Street__c, Language__c, Title, Subject__c, Campaign_Online_ID__c
                             from Lead where Email = :email];
            }
            else if (String.isEmpty(email) && string.isNotEmpty(emailHash)){
                leadquery = [Select Id, Email, Email_SHA256__c, IndividualId, Individual.Name, Cookie__c, Opt_in_Source__c, Consent_Registration_Source_URLs__c, Consent_Registration_IP_Address__c,
                             Consent_Registration_Date__c, utmcsr__c, utmcmd__c, utmccn__c, utmcct__c, utmctr__c, utmgclid__c, utmdclid__c, Salutation, FirstName, MiddleName, LastName, Company, 
                             Phone, Main_Postal_Code__c, Main_City__c, Main_Country__c, Main_House_Number__c, Main_State__c, Main_Street__c, Language__c, Title, Subject__c, Campaign_Online_ID__c
                             from Lead where Email_SHA256__c = :emailHash];
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

  private static void updateLead(Lead ld, Map<String, ContactPointTypeConsent> consentMap, InboundLead wrappedvalues, InboundLeadResponse errorresults, InboundLeadResponse successresults, List<Custom_Log__c> customloggingadd){
        CustomLogging.push('updateLead', 'SM_FormAPI');
        try{
            Map<String,String> salesorgsoidoi = SM_GetMetadata.getsalesorgdoisoi();
            List<Lead> leadupdate = new List<Lead>();
            Lead updateLead = new Lead();
            updateLead.Id = ld.Id;
            Map<String, String> datausepurposeIds = fetchDataUsePurposeIds();
            Set<String> loopthis = datausepurposeIds.keyset();
            Map<String, String> privacyconsentstatusmap = fetchPrivacyConsentStatus();
            String parsingTextvalue;
            
            if (ld.Cookie__c == null && wrappedvalues.RequestData.trackingcookie != null){
                updateLead.Cookie__c = wrappedvalues.RequestData.trackingcookie;
            }
            
            if (ld.Opt_in_Source__c == null && wrappedvalues.RequestData.consentSource != null){
                updateLead.Opt_in_Source__c = wrappedvalues.RequestData.consentSource;
            }
            
            if (ld.Consent_Registration_Source_URLs__c == null && wrappedvalues.RequestData.sourceUrl != null){
                updateLead.Consent_Registration_Source_URLs__c = wrappedvalues.RequestData.sourceUrl;
            }
            
            if (ld.Consent_Registration_IP_Address__c == null && wrappedvalues.RequestData.ip != null){
                updateLead.Consent_Registration_IP_Address__c = wrappedvalues.RequestData.ip;
            }
            
            if (ld.Consent_Registration_Date__c == null && wrappedvalues.RequestData.datetimevalue != null){
                updateLead.Consent_Registration_Date__c = wrappedvalues.RequestData.datetimevalue;
            }
            
            if (ld.utmcsr__c == null && wrappedvalues.RequestData.utmcsr != null){
                updateLead.utmcsr__c = wrappedvalues.RequestData.utmcsr;
            }
            
            if (ld.utmcmd__c == null && wrappedvalues.RequestData.utmcmd != null){
                updateLead.utmcmd__c = wrappedvalues.RequestData.utmcmd;
            }
            
            if (ld.utmccn__c == null && wrappedvalues.RequestData.utmccn != null){
                updateLead.utmccn__c = wrappedvalues.RequestData.utmccn;
            }
            
            if (ld.utmcct__c == null && wrappedvalues.RequestData.utmcct != null){
                updateLead.utmcct__c = wrappedvalues.RequestData.utmcct;
            }
            
            if (ld.utmctr__c == null && wrappedvalues.RequestData.utmctr != null){
                updateLead.utmctr__c = wrappedvalues.RequestData.utmctr;
            }
            
            if (ld.utmgclid__c == null && wrappedvalues.RequestData.utmgclid != null){
                updateLead.utmgclid__c = wrappedvalues.RequestData.utmgclid;
            }
            
            if (ld.utmdclid__c == null && wrappedvalues.RequestData.utmdclid != null){
                updateLead.utmdclid__c = wrappedvalues.RequestData.utmdclid;
            }
            
            if (ld.Salutation == null && wrappedvalues.Individual.salutation != null){
                updateLead.Salutation = wrappedvalues.Individual.salutation;
            }
            
            if (ld.FirstName == null && wrappedvalues.Individual.firstname != null){
                updateLead.FirstName = wrappedvalues.Individual.firstname;
            }
            
            if (ld.MiddleName == null && wrappedvalues.Individual.middlename != null){
                updateLead.MiddleName = wrappedvalues.Individual.middlename;
            }
            
            if (ld.LastName == null && wrappedvalues.Individual.lastname != null){
                updateLead.LastName = wrappedvalues.Individual.lastname;
            }
            
            if (ld.Phone == null && wrappedvalues.Individual.phone != null){
                updateLead.Phone = wrappedvalues.Individual.phone;
            }
            
            if (ld.Company == null && wrappedvalues.Individual.company != null){
                updateLead.Company = wrappedvalues.Individual.company;
            }
            
            if (ld.Main_Postal_Code__c == null && wrappedvalues.Individual.postalCode != null){
                updateLead.Main_Postal_Code__c = wrappedvalues.Individual.postalCode;
            }
            
            if (ld.Main_City__c == null && wrappedvalues.Individual.city != null){
                updateLead.Main_City__c = wrappedvalues.Individual.city;
            }
            
            if (ld.Main_Country__c == null && wrappedvalues.Individual.country != null){
                updateLead.Main_Country__c = wrappedvalues.Individual.country;
            }
            
            if (ld.Main_House_Number__c == null && wrappedvalues.Individual.houseNumber != null){
                updateLead.Main_House_Number__c = wrappedvalues.Individual.houseNumber;
            }
            
            if (ld.Main_State__c == null && wrappedvalues.Individual.state != null){
                updateLead.Main_State__c = wrappedvalues.Individual.state;
            }
            
            if (ld.Main_Street__c == null && wrappedvalues.Individual.street != null){
                updateLead.Main_Street__c = wrappedvalues.Individual.street;
            }
            
            if (ld.Language__c == null && wrappedvalues.Individual.language != null){
                updateLead.Language__c = wrappedvalues.Individual.language;
            }
            
            if (ld.Title == null && wrappedvalues.Individual.title != null){
                updateLead.Title = wrappedvalues.Individual.title;
            }
            
            if (ld.Subject__c == null && wrappedvalues.Details.subject != null){
                updateLead.Subject__c = wrappedvalues.Details.subject;
            }
            
            if (ld.Campaign_Online_ID__c == null && wrappedvalues.Details.campaignId != null){
                updateLead.Campaign_Online_ID__c = wrappedvalues.Details.campaignId;
            }
            
            if (!consentMap.isEmpty()){
                for (String val : loopthis){
                    String pcsvalues;
                    if (consentMap.keyset().contains(val) == true){
                        if (val == SM_Constants.Marketing){
                            if (consentMap.get(val).Consent_Text_Version__c != null){
                                updateLead.Consent_Version_Marketing__c = integer.valueOf(consentMap.get(val).Consent_Text_Version__c);
                            }
                            updateLead.Consent_Status_Marketing__c = privacyconsentstatusmap.get(consentMap.get(val).PrivacyConsentStatus);
                        } else if (val == SM_Constants.Profiling){
                            if (consentMap.get(val).Consent_Text_Version__c != null){
                                updateLead.Consent_Version_Profiling__c = integer.valueOf(consentMap.get(val).Consent_Text_Version__c);
                            }
                            updateLead.Consent_Status_Profiling__c = privacyconsentstatusmap.get(consentMap.get(val).PrivacyConsentStatus);
                        } else if (val == SM_Constants.Survey){
                            if (consentMap.get(val).Consent_Text_Version__c != null){
                                updateLead.Consent_Version_Surveys__c = integer.valueOf(consentMap.get(val).Consent_Text_Version__c);
                            }
                            updateLead.Consent_Status_Surveys__c = privacyconsentstatusmap.get(consentMap.get(val).PrivacyConsentStatus);
                        } 

                        if ((salesorgsoidoi.get(wrappedvalues.sales_organization) == 'DOI' && (privacyconsentstatusmap.get(consentMap.get(val).PrivacyConsentStatus) == 'Pending')) || 
                            (salesorgsoidoi.get(wrappedvalues.sales_organization) == 'SOI' && (privacyconsentstatusmap.get(consentMap.get(val).PrivacyConsentStatus) == 'Opt-In'))){
                            if (parsingTextvalue == null){
                                parsingTextvalue = consentMap.get(val).Id + '|' + val + '^';
                            }
                            else{
                                parsingTextvalue = parsingTextvalue + consentMap.get(val).Id + '|' + val + '^';
                            }
                        }
                    }
                }
                if (parsingTextvalue != null){
                    if (salesorgsoidoi.get(wrappedvalues.sales_organization) == 'DOI'){
                    Journey_Trigger__c journeytriggervalues = new Journey_Trigger__c();
                    journeytriggervalues.Parsing_Text__c = parsingTextvalue.removeEnd('^');
                    journeytriggervalues.Journey_Trigger_Type__c = 'Consent';
                    journeytriggervalues.Journey_Trigger_SubType__c = 'Double Opt-In';
                    journeytriggervalues.Lead__c = ld.Id;
                    insert journeytriggervalues;
                    } else {
                        if (salesorgsoidoi.get(wrappedvalues.sales_organization) == 'SOI'){
                            Journey_Trigger__c journeytriggervalues = new Journey_Trigger__c();
                            journeytriggervalues.Parsing_Text__c = parsingTextvalue.removeEnd('^');
                            journeytriggervalues.Journey_Trigger_Type__c = 'Consent';
                            journeytriggervalues.Journey_Trigger_SubType__c = 'Single Opt-In';
                            journeytriggervalues.Lead__c = ld.Id;
                            insert journeytriggervalues;
                        }
                    } 
                }
            }
            
            leadupdate.add(updateLead);
            
            if (!leadupdate.isEmpty() && !leadupdate.toString().containsOnly('(Lead:{Id=' + ld.Id +'})')){
                Database.SaveResult[] srErrorList = Database.update(leadupdate, false);
                for (Database.SaveResult sr : srErrorList) {
                    if (sr.isSuccess()) {
                        successresults.updatedLeadId = sr.getId();
                        successresults.leadupdatedstatus = 'Lead Updated';
                    } else {
                        Custom_Log__c log = new Custom_Log__c();
                        log.StackTrace__c = 'SM_FormAPI : formapi SM_FormAPI : updateLead';
                        log.Message__c = sr.getErrors()[0].getMessage() + ' status code: ' + sr.getErrors()[0].getStatusCode() + ' field: ' + sr.getErrors()[0].getFields();
                        log.LogType__c = 'Exception';
                        log.Sequence__c = 0;
                        log.Limits__c = getLimits();
                        log.ExceptionType__c = 'System.DMLException';
                        customloggingadd.add(log);
                        
                        errorresults.updatedLeadId = sr.getId();
                        errorresults.leadupdatedstatus = sr.getErrors()[0].getMessage();
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
        public List<CustomFields> customFields;
        public Channel channel;
        public Individual individual;
        public Details details;
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
  public class Individual {
        public String lastname;
        public String firstname;
        public String salutation;
        public String middleName;
        public String company;
        public String phone;
        public String postalCode;
        public String country;
        public String city;
        public String houseNumber;
        public String street;
        public String state;
        public String title;
        public String language;
        public String coffeemachinecode;
  }
  public class Details {
        public String touchpointType;
        public Id campaignId;
        public String leadSource;
        public String subject;
  }
  public class InboundLeadResponse {
        public ID leadId;
      	public ID updatedLeadId;
        public ID contactId;
        public ID campaignMemberId;
        public ID taskId;
        public ID caseId;
        public string leadstatus;
      	public string leadupdatedstatus;
        public String contactstatus;
        public String taskStatus;
        public String campaignMemberStatus;
      	public String casestatus;
        public String errorMessage;
        public String email;
  }
  public class CustomFields{
        public String name;
        public string value;
  }
}