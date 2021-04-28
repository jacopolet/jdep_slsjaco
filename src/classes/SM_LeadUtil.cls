//-------------------------------------------------------------------------------------------//
// Author       :   Glenn Serrano - Accenture
// Created Date :   June 18, 2020
// Usage        :   Utility Class for Lead
//
//-------------------------------------------------------------------------------------------//
public without sharing class SM_LeadUtil {
    public static void ChangeOwnerToQueueDellBoomi(List<Lead> leads){
        CustomLogging.push('ChangeOwnerToQueueDellBoomi', 'SM_LeadUtil');
        try{
            Map<String, Queue_Lead_Tasks__mdt> queueleadtaskmap = SM_GetMetadata.getqueueleadtasks();
            String campaignlength = '';
            String queueleadkey = '';
            for (Lead leadrec : leads){
                campaignlength = leadrec.Campaign_Online_ID__c;
                queueleadkey = leadrec.Sales_Organization__c + leadrec.Touchpoint_Type__c;
                if (queueleadtaskmap.get(queueleadkey) != null){
                    if (queueleadtaskmap.get(queueleadkey).Queue_for_Lead__c != null){
                        leadrec.OwnerId = queueleadtaskmap.get(queueleadkey).Queue_for_Lead__c;
                    }
                }
                else {
                    if (queueleadtaskmap.get(queueleadkey) == null){
                        leadrec.OwnerId = queueleadtaskmap.get(leadrec.Sales_Organization__c + 'Default').Queue_for_Lead__c;
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
    
    public static void Ownerchangedtoqueuenotification(List<Lead> leads){
        CustomLogging.push('Ownerchangedtoqueuenotification', 'SM_LeadUtil');
        try{
            FeedItem post = new FeedItem();
            List<ConnectApi.BatchInput> batchInputs = new List<ConnectApi.BatchInput>();
    
            if (!leads.isEmpty()){
                for (Lead ld : leads){
                    Queue_Lead_Notification__c queuechattergroup = Queue_Lead_Notification__c.getInstance(ld.OwnerId);
                    if (queuechattergroup != null){
                        ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();            
                        ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();   
                        messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
                        
                        ConnectApi.TextSegmentInput textSegmentInput1 = new ConnectApi.TextSegmentInput();
                        if (queuechattergroup.Queue_Name__c == 'Hot Lead Queue United Kingdom'){
                            textSegmentInput1.text = 'There is a new lead with Postal Code: ' + ld.Main_Postal_Code__c + ' ';   
                        }
                        else {
                            textSegmentInput1.text = 'There is a new lead ';   
                        }     
                        messageBodyInput.messageSegments.add(textSegmentInput1);
                        ConnectApi.EntityLinkSegmentInput entityLinkSegmentInputContact = new ConnectApi.EntityLinkSegmentInput();
                        entityLinkSegmentInputContact.entityId = LD.Id;   
                        messageBodyInput.messageSegments.add(entityLinkSegmentInputContact);
                        ConnectApi.TextSegmentInput textSegmentInput2 = new ConnectApi.TextSegmentInput();
                        textSegmentInput2.text = ' available in the queue,' + ' ';     
                        messageBodyInput.messageSegments.add(textSegmentInput2);
                        ConnectApi.EntityLinkSegmentInput entityLinkSegmentInputOpportunity = new ConnectApi.EntityLinkSegmentInput();
                        entityLinkSegmentInputOpportunity.entityId = queuechattergroup.Chatter_Group_ID__c;  
                        messageBodyInput.messageSegments.add(entityLinkSegmentInputOpportunity); 
                        ConnectApi.TextSegmentInput textSegmentInput3 = new ConnectApi.TextSegmentInput();
                        textSegmentInput3.text = ' , go go go, you hustlers! Last one there is a slowpoke!';     
                        messageBodyInput.messageSegments.add(textSegmentInput3);
                        
                        feedItemInput.body = messageBodyInput;
                        feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
                        feedItemInput.subjectId = queuechattergroup.Chatter_Group_ID__c; 
                        
                        ConnectApi.BatchInput batchInput = new ConnectApi.BatchInput(feedItemInput);
                        batchInputs.add(batchInput);
                    }
                }
                ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), batchInputs);
            }
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        CustomLogging.pop();   
    }
    
    public static void leadisDisqualifiedclosetask(Set<Id> leads, Map<Id, Lead> leadmap){
        CustomLogging.push('leadisDisqualifiedclosetask', 'SM_LeadUtil');
        try{
            List<Task> closeTaskswithDisqualifiedLead = new List<Task>();
            List<Task> taskRecords = new List<Task>();
            taskRecords = [Select Id, WhoId, Touchpoint_Type__c, Status, Reason__c from Task where WhoId IN:leads];
            if (taskRecords != null){
                for (Task t : taskRecords){
                    Lead leadTTmatch = leadmap.get(t.WhoId);
                    if (leadTTmatch != null){
                        if (t.Touchpoint_Type__c == leadmap.get(t.WhoId).Touchpoint_Type__c){
                            Task taskupdate = new Task();
                            taskupdate.Id = t.Id;
                            taskupdate.Status = 'Completed Non-Effective';
                            taskupdate.Reason__c = leadmap.get(t.WhoId).Reason_Disqualified__c;
                            closeTaskswithDisqualifiedLead.add(taskupdate);
                        }
                    }
                }
            }
           
            if (!closeTaskswithDisqualifiedLead.isEmpty()){
                update closeTaskswithDisqualifiedLead;
            }
            
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        CustomLogging.pop();   
    }
    
    public static void leadisConvertedclosetask(Set<Id> leads, Map<Id, Lead> leadmap){
        CustomLogging.push('leadisConvertedclosetask', 'SM_LeadUtil');
        try{
            List<Task> closeTaskswithConvertedLead = new List<Task>();
            List<Task> taskRecords = new List<Task>();
            taskRecords = [Select Id, WhoId, Touchpoint_Type__c, Status, Reason__c from Task where WhoId IN:leads];
            if (taskRecords != null){
                for (Task t : taskRecords){
                    Lead leadTTmatch = leadmap.get(t.WhoId);
                    if (leadTTmatch != null){
                        if (t.Touchpoint_Type__c == leadmap.get(t.WhoId).Touchpoint_Type__c){
                            Task taskupdate = new Task();
                            taskupdate.Id = t.Id;
                            if (leadmap.get(t.WhoId).Status == 'Converted with Opportunity'){
                                taskupdate.Status = 'Completed Effective';
                                taskupdate.Reason__c = 'Converted to Opportunity';
                            }
                            else if (leadmap.get(t.WhoId).Status == 'Converted without Opportunity'){
                                taskupdate.Status = 'Completed Effective';
                                taskupdate.Reason__c = 'No follow up needed';
                            }
                            else if (leadmap.get(t.WhoId).Status == 'Converted to Opportunity with Event'){
                                taskupdate.Status = 'Completed Effective';
                                taskupdate.Reason__c = 'Converted to Event';
                            }
                            closeTaskswithConvertedLead.add(taskupdate);
                        }
                    }
                }
            }
            if (!closeTaskswithConvertedLead.isEmpty()){
                SM_CheckRecursive.run = true;
                update closeTaskswithConvertedLead;
            }
            
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        CustomLogging.pop();   
    }
    
    public static void leadScoring(List<Lead> leads){
        CustomLogging.push('leadScoring', 'SM_LeadUtil');
        try{
            Map<String, Decimal> ttcMap = new Map<String, Decimal>();
            Touchpoint_Type_Score__c ttc = Touchpoint_Type_Score__c.getOrgDefaults();
            ttcMap.put('INBOUND CALL', ttc.INBOUND_CALL_Score__c);
            ttcMap.put('REFERRAL PARTNER', ttc.REFERRAL_PARTNER_Score__c);
            ttcMap.put('TRADE SHOW/EVENT', ttc.TRADE_SHOW_EVENT_Score__c);
            ttcMap.put('STAND AGREEMENT', ttc.STAND_AGREEMENT_Score__c);
            ttcMap.put('OTHER REQUEST', ttc.OTHER_REQUEST_Score__c);
            ttcMap.put('EXP', ttc.EXP_Score__c);
            ttcMap.put('FOLL UP', ttc.FOLL_UP_Score__c);
            ttcMap.put('RM', ttc.RM_Score__c);
            ttcMap.put('MPO', ttc.MPO_Score__c);
            ttcMap.put('RM + MPO', ttc.RM_MPO_Score__c);
            ttcMap.put('END WARR', ttc.END_WARR_Score__c);
            ttcMap.put('NPS', ttc.NPS_Score__c);
            ttcMap.put('AFT INSTAL', ttc.AFT_INSTAL_Score__c);
            ttcMap.put('MOVEMNT', ttc.MOVEMNT_Score__c);
            ttcMap.put('MPV', ttc.MPV_Score__c);
            ttcMap.put('REFERRAL EMPLOYEE', ttc.REFERRAL_EMPLOYEE_Score__c);
            ttcMap.put('REFERRAL TECHNICIAN', ttc.REFERRAL_TECHNICIAN_Score__c);
            ttcMap.put('REFERRAL ROUTESALES', ttc.REFERRAL_ROUTESALES_Score__c);
            ttcMap.put('REFERRAL CUSTOMER', ttc.REFERRAL_CUSTOMER_Score__c);
            ttcMap.put('REFERRAL BUYING GROUP', ttc.REFERRAL_BUYING_GROUP_Score__c);
            ttcMap.put('COLD AQCUISITION', ttc.COLD_AQCUISITION_Score__c);
            ttcMap.put('TAILOR-MADE AGREEMENT', ttc.TAILOR_MADE_AGREEMENT_Score__c);
            ttcMap.put('GENERIC REQUEST', ttc.GENERIC_REQUEST_Score__c);
            ttcMap.put('ONLINE INFORMATION REQUEST MC', ttc.ONLINE_INFORMATION_REQUEST_MC_Score__c);
            ttcMap.put('ONLINE QUOTE REQUEST MC', ttc.ONLINE_QUOTE_REQUEST_MC_Score__c);
            ttcMap.put('WARM WELCOME FOLL UP', ttc.WARM_WELCOME_FOLL_UP_Score__c);
            ttcMap.put('NEW STARTED COMPANY', ttc.NEW_STARTED_COMPANY_Score__c);
            ttcMap.put('COMPANY CHANGE', ttc.COMPANY_CHANGE_Score__c);
            ttcMap.put('PROSPECT LIST', ttc.PROSPECT_LIST_Score__c);
            ttcMap.put('KPI/SLA', ttc.KPI_SLA_Score__c);
            ttcMap.put('BUDGETS', ttc.BUDGETS_Score__c);
            ttcMap.put('ONE-TIME BONUS', ttc.ONE_TIME_BONUS_Score__c);
            ttcMap.put('INDEXATION', ttc.INDEXATION_Score__c);
            ttcMap.put('RENT-BUY', ttc.RENT_BUY_Score__c);
            ttcMap.put('P.O. NUMBER', ttc.P_O_NUMBER_Score__c);
            ttcMap.put('VOLUME OBLIGATION', ttc.VOLUME_OBLIGATION_Score__c);
            ttcMap.put('FIXED PAYMENT TERMS', ttc.FIXED_PAYMENT_TERMS_Score__c);
            ttcMap.put('SELL-OUT DATA', ttc.BUDGETS_Score__c);
            ttcMap.put('ONLINE INFORMATION REQUEST', ttc.ONLINE_INFORMATION_REQUEST_Score__c);
            ttcMap.put('ONLINE QUOTE REQUEST', ttc.ONLINE_QUOTE_REQUEST_Score__c);
            ttcMap.put('CMD CHANGE', ttc.CMD_CHANGE_Score__c);
            ttcMap.put('SIGNED CONTRACT', ttc.SIGNED_CONTRACT_Score__c);
            ttcMap.put('REPORT REQUEST', ttc.REPORT_REQUEST_Score__c);
            ttcMap.put('CONTACT REQUEST', ttc.CONTACT_REQUEST_Score__c);
            ttcMap.put('PROMOTION', ttc.PROMOTION_Score__c);
            ttcMap.put('NEW PRODUCT INTRO', ttc.NEW_PRODUCT_INTRO_Score__c);
            ttcMap.put('DEEP/CROSS/UP SELL', ttc.CROSS_UP_SELL_Score__c);
            ttcMap.put('PRODUCT CHANGE', ttc.PRODUCT_CHANGE_Score__c);
            ttcMap.put('CAMPAIGN', ttc.CAMPAIGN_Score__c);
            ttcMap.put('FIRST ORDER SURVEY', ttc.FIRST_ORDER_SURVEY_Score__c);
            ttcMap.put('MANUAL', ttc.MANUAL__c);
            ttcMap.put('REMINDER', ttc.REMINDER__c);
            ttcMap.put('CREDIT CHECK', ttc.CREDIT_CHECK__c);
            ttcMap.put('LEAD NURTURING', ttc.LEAD_NURTURING__c);
            ttcMap.put('ONLINE CAMPAIGN', ttc.ONLINE_CAMPAIGN__c);
            
            Lead_Individual_Score__c atl = Lead_Individual_Score__c.getOrgDefaults();
            
            for (Lead newLead : leads) {            
                if (newLead.Touchpoint_Type__c <> SM_Constants.STANDAGREEMENT && newLead.Touchpoint_Type__c <> SM_Constants.TAILORMADEAGREEMENT && 
                    newLead.Touchpoint_Type__c <> SM_Constants.CMDCHANGE && newLead.Touchpoint_Type__c <> SM_Constants.SIGNEDCONTRACT &&
                    newLead.Touchpoint_Type__c <> SM_Constants.GENERICREQUEST && newLead.Touchpoint_Type__c <> SM_Constants.REPORTREQUEST &&
                    newLead.Touchpoint_Type__c <> SM_Constants.CONTACTREQUEST && newLead.Touchpoint_Type__c <> SM_Constants.OTHERREQUEST && 
                    newLead.Touchpoint_Type__c <> SM_Constants.NPS && newLead.Touchpoint_Type__c <> SM_Constants.AFTINSTAL &&
                    newLead.Touchpoint_Type__c <> SM_Constants.MOVEMNT && newLead.Touchpoint_Type__c <> SM_Constants.MPV &&
                    newLead.Touchpoint_Type__c <> SM_Constants.WARMWELCOMEFOLLUP && newLead.Touchpoint_Type__c <> SM_Constants.FIRSTORDERSURVEY &&
                    newLead.Touchpoint_Type__c <> SM_Constants.KPISLA && newLead.Touchpoint_Type__c <> SM_Constants.BUDGETS &&
                    newLead.Touchpoint_Type__c <> SM_Constants.ONETIMEBONUS && newLead.Touchpoint_Type__c <> SM_Constants.INDEXATION &&
                    newLead.Touchpoint_Type__c <> SM_Constants.RENTBUY && newLead.Touchpoint_Type__c <> SM_Constants.PONUMBER &&
                    newLead.Touchpoint_Type__c <> SM_Constants.VOLUMEOBLIGATION && newLead.Touchpoint_Type__c <> SM_Constants.FIXEDPAYMENTTERMS &&
                    newLead.Touchpoint_Type__c <> SM_Constants.SELLOUTDATA && newLead.Touchpoint_Type__c <> SM_Constants.OUTBOUNDCALL) {
                    if (newLead.Touchpoint_Type__c != null){
                        if (atl.Lead_Score__c <> Null) {
                          newLead.Priority_Score__c = ttcMap.get(newLead.Touchpoint_Type__c) + atl.Lead_Score__c;
                          if (newLead.Priority_Score__c > 100){
                              newLead.Priority_Score__c = 100;
                          }
                        } else {
                          newLead.Priority_Score__c = ttcMap.get(newLead.Touchpoint_Type__c);
                        }
                    }
                    
                } else {
                    newLead.Priority_Score__c = Null;
                }
    
            }
            
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        CustomLogging.pop();   
    }
    
    public static void createSubscription(List<Lead> leads){
        CustomLogging.push('createSubscription', 'SM_LeadUtil');
        try{
            List<Subscription__c> createSubs = new List<Subscription__c>();
            for (Lead l : leads){
                Subscription__c subs = new Subscription__c();
                subs.Consent_Registration_Date__c = l.Consent_Registration_Date__c;
                subs.Consent_Registration_IP_Address__c = l.Consent_Registration_IP_Address__c;
                subs.Consent_Registration_Source_URL__c = l.Consent_Registration_Source_URLs__c;
                subs.Consent_Status__c = l.Consent_Status__c;
                subs.Consent_Text_Version__c = l.Consent_Text_Version__c;
                subs.Consent_Text__c = l.Consent_Texts__c;
                subs.Events__c = l.Events__c;
                subs.Has_Opted_Out__c = l.HasOptedOutOfEmail;
                subs.Lead__c = l.Id;
                subs.NewsLetter__c = l.NewsLetter__c;
                subs.Opt_in_URL__c = l.Opt_in_URL__c;
                subs.Opt_out_URL__c = l.Opt_out_URL__c;
                subs.Privacy_Policy_Version__c = l.Privacy_Policy_Version__c;
                subs.Promotions__c = l.Promotions__c;
                createSubs.add(subs);
            }
            
            if (!createSubs.isEmpty()){
                insert createSubs;
            }
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        CustomLogging.pop();   
    }

    public static void createIndividual(List<Lead> leads){
        CustomLogging.push('createIndividual', 'SM_LeadUtil');
        try{
            Map<Id, Id> individualleadorcontactmatch = new Map<Id, Id>();
            
            Set<Id> updateLeadIds = new Set<Id>();
            List<Individual> createindv = new List<Individual>();
            List<Lead> updateleadrec = new List<Lead>();
            for (Lead l : leads){
                Individual ind = new Individual();
                ind.FirstName = l.FirstName;
                ind.MiddleName = l.MiddleName;
                ind.LastName = l.LastName;
                ind.Related_To__c = l.Id;
                createindv.add(ind);
            }
            
            if (!createindv.isEmpty()){
                insert createindv;

                List<Individual> individualrec = [Select Id, Related_To__c from Individual where Id IN: createindv];
                if (!individualrec.isEmpty()){
                    for (Individual i : individualrec){
                        individualleadorcontactmatch.put(i.Related_To__c, i.Id);
                    }
                }

                if (!individualleadorcontactmatch.isEmpty()){
                    for (Lead l : leads){
                        Lead leadupdate = new Lead();
                        leadupdate.Id = l.Id;
                        leadupdate.IndividualId = individualleadorcontactmatch.get(l.Id);
                        if (!updateLeadIds.contains(l.Id)){
                            updateleadrec.add(leadupdate);
                            updateLeadIds.add(l.Id);
                        }
                    }
    
                    if (!updateleadrec.isEmpty()){
                        update updateleadrec;
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
    
    public static void generateHash(List<Lead> leads){
        CustomLogging.push('generateHash', 'SM_LeadUtil');
        try{
            if (leads != null){
                for (Lead l : leads){
                     if (l.Email != null){
                        Blob emailBlob = Blob.valueOf(l.Email);
                        Blob emailHash = Crypto.generateDigest('SHA-256', emailBlob);
                        l.Email_SHA256__c = EncodingUtil.convertToHex(emailHash);
                     }
                     else {
                         l.Email_SHA256__c = null;
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
}