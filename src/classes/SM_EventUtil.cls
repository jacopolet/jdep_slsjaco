//-------------------------------------------------------------------------------------------//
// Author       :   Glenn Serrano - Accenture
// Created Date :   February 21 2019
// Usage        :   Utility Class for Event
//
//-------------------------------------------------------------------------------------------//

public without sharing class SM_EventUtil {
    public static List<Event> populateAccountLookuponEvents (List<Event> events){
        CustomLogging.push('populateAccountLookuponEvents', 'SM_EventUtil');
        try {           
            if (!events.isEmpty()){
                for (Event e : events){
                    e.Account__c = e.WhatId;
                }
            }
            return events;
        } catch (Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
            return null;
        }
    }
    public static List<Event> populateRoleId (List<Event> events){
        CustomLogging.push('populateRoleId', 'SM_EventUtil');
        try {           
            Set<Id> users = new Set<Id>();
            if (!events.isEmpty()){
                for (Event e : events){
                     if (!users.contains(e.OwnerId)){
                         users.add(e.OwnerId);
                     }
                }
            }
            if (!users.isEmpty()){
                List<User> userrecords = [Select Id, UserRole.Name From User where Id IN :users];
                if (!userrecords.isEmpty()){
                    Map<Id, User> mapusers = new Map<Id, User>();
                    for (User u : userrecords){
                        mapusers.put(u.Id, u);
                    }
                    for (Event e : events){
                        if (!mapusers.isEmpty()){
                            User uval = (User) mapusers.get(e.OwnerId);
                            e.Role_Id__c = uval.UserRole.Name;
                        }
                    }
                }
            }
            return events;
        } catch (Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
            return null;
        }
    }
    
    public static List<Event> stampAccountLifecycleandSegment (List<Event> events){
        CustomLogging.push('stampAccountLifecycleandSegment', 'SM_EventUtil');
        try {           
            Set<Id> accounts = new Set<Id>();
            Set<Id> eventswithOppty = new Set<Id>();
            Set<Id> eventswithAccLoc = new Set<Id>();
            if (!events.isEmpty()){
                for (Event e : events){
                     if (String.valueOf(e.WhatId).left(3) == SM_Constants.accountPrefix){
                         accounts.add(e.WhatId);
                     }
                     else if (String.valueOf(e.WhatId).left(3) == SM_Constants.oppPrefix){
                         eventswithOppty.add(e.WhatId);
                     }
                     else if (String.valueOf(e.WhatId).left(3) == Label.Account_Location_Prefix){
                         eventswithAccLoc.add(e.WhatId);
                     }
                }
            }
            if (!accounts.isEmpty()){
                List<Account> accountrecords = [Select Id, Account_Lifecycle__c, Segment__c from Account where Id IN :accounts];
                if (!accountrecords.isEmpty()){
                    Map<Id, Account> mapaccounts = new Map<Id, Account>();
                    for (Account a : accountrecords){
                        mapaccounts.put(a.Id, a);
                    }
                    for (Event e : events){
                        if (!mapaccounts.isEmpty()){
                            Account aval = (Account) mapaccounts.get(e.whatId);
                            e.Account_Lifecycle_HANA__c = aval.Account_Lifecycle__c;
                            e.Segment__c = aval.Segment__c;
                        }
                    }
                }
            }
            if (!events.isEmpty()){
                for (Event e : events){
                    if (String.valueOf(e.WhatId).left(3) == SM_Constants.oppPrefix){
                        eventswithOppty.add(e.WhatId);
                    }
                    else if (String.valueOf(e.WhatId).left(3) == Label.Account_Location_Prefix){
                        eventswithAccLoc.add(e.WhatId);
                    }
                }
            }
            if (!eventswithOppty.isEmpty()){
                List<Opportunity> opptyrecords = [Select Id, Account.Name, Account.Segment__c, Account.Account_Lifecycle__c from Opportunity where Id IN :eventswithOppty];
                if (!opptyrecords.isEmpty()){
                    Map<Id, Opportunity> mapaccountfromoppty = new Map<Id, Opportunity>();
                    for (Opportunity o : opptyrecords){
                        mapaccountfromoppty.put(o.Id, o);
                    }
                    for (Event e : events){
                        if (!mapaccountfromoppty.isEmpty()){
                            Opportunity opptyvalues = (Opportunity) mapaccountfromoppty.get(e.WhatId);
                            e.Account_Lifecycle_HANA__c = opptyvalues.Account.Account_Lifecycle__c;
                            e.Segment__c = opptyvalues.Account.Segment__c;
                            e.Account_Name__c = opptyvalues.Account.Name;
                        }
                    }
                }
            }
            if (!eventswithAccLoc.isEmpty()){
                List<Apttus_Config2__AccountLocation__c> acclocrecords = [Select Id, Apttus_Config2__AccountId__r.Name, Apttus_Config2__AccountId__r.Segment__c, Apttus_Config2__AccountId__r.Account_Lifecycle__c From Apttus_Config2__AccountLocation__c where Id IN : eventswithAccLoc];
                if (!acclocrecords.isEmpty()){
                    Map<Id, Apttus_Config2__AccountLocation__c> mapaccountfromaccloc = new Map<Id, Apttus_Config2__AccountLocation__c>();
                    for (Apttus_Config2__AccountLocation__c accloc : acclocrecords){
                        mapaccountfromaccloc.put(accloc.Id, accloc);
                    }
                    for (Event e : events){
                        if (!mapaccountfromaccloc.isEmpty()){
                            Apttus_Config2__AccountLocation__c accloc = (Apttus_Config2__AccountLocation__c) mapaccountfromaccloc.get(e.WhatId);
                            e.Account_Lifecycle_HANA__c = accloc.Apttus_Config2__AccountId__r.Account_Lifecycle__c;
                            e.Segment__c = accloc.Apttus_Config2__AccountId__r.Segment__c;
                            e.Account_Name__c = accloc.Apttus_Config2__AccountId__r.Name;
                        }
                    }
                }
            }
            return events;
        } catch (Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
            return null;
        }
    }
    
    public static List<Event> stampCampaignIdFromContactorLead (List<Event> events){
        CustomLogging.push('stampCampaignIdFromContactorLead', 'SM_EventUtil');
        try {
            Set<Id> contactId = new Set<Id>();
            Set<Id> leadId = new Set<Id>();
            
            if (!events.isEmpty()){
                for (Event e : events){
                    if (e.WhoId != null){
                        if (String.valueOf(e.WhoId).left(3) == SM_Constants.contactPrefix){
                            contactId.add(e.WhoId);
                        }
                        else if (String.valueOf(e.WhoId).left(3) == SM_Constants.leadPrefix){
                            leadId.add(e.WhoId);
                        }
                    }
                }
                if (!contactId.isEmpty()){
                    List<Contact> contactrec = [Select Id, Campaign_Online_ID__c from Contact where Id IN:contactID];
                    Map<Id, Contact> mapcontact = new Map<Id, Contact>();
                    if (!contactrec.isEmpty()){
                        for (Contact c : contactrec){
                            if (c.Campaign_Online_ID__c != null){
                                mapcontact.put(c.Id, c);
                            }
                        }
                    }
                    for (Event e : events){
                        if (!mapcontact.isEmpty()){
                            Contact conval = (Contact) mapcontact.get(e.WhoId);
                            e.Campaign__c = conval.Campaign_Online_ID__c;
                        }
                    }
                }
                if (!leadId.isEmpty()){
                    List<Lead> leadrec = [Select Id, Campaign_Online_ID__c from Lead Where Id IN:leadId];
                    Map<Id, Lead> maplead = new Map<Id, Lead>();
                    if (!leadrec.isEmpty()){
                        for (Lead l : leadrec){
                            if (l.Campaign_Online_ID__c != null){
                                maplead.put(l.Id, l);
                            }
                        }
                    }
                    for (Event e : events){
                        if (!maplead.isEmpty()){
                            Lead leadval = (Lead) maplead.get(e.WhoId);
                            e.Campaign__c = leadval.Campaign_Online_ID__c;
                        }
                    }
                }
            }
        return events;
        } catch (Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
            return null;
        }
    }
    
    @future
    public static void StampWhatTypeWhoType (set<Id> events){
        CustomLogging.push('StampWhatTypeWhoType', 'SM_EventUtil');
         try{
            List<Event> EventRecs = new List<Event>();
            List<Event> processedEvents = new List<Event>();
            if (!Events.isEmpty()){
                EventRecs = [Select Id, Who.type, What.type, WhatId, WhoId from Event WHERE ID in : events];
                if (!EventRecs.isEmpty()){
                    for (Event e : EventRecs){
                        if (e.WhatId != null || e.WhoId != null) {
                            Event eu = new Event();
                            eu.Id = e.Id;
                            eu.WhatType__c = e.What.Type;
                            eu.WhoType__c = e.Who.Type;
                            processedEvents.add(eu);
                        }
                    }    
                    update processedEvents;
                }
            }
        } catch (Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
    }
    
    public static void setAccountLastEventDateRelevantDate(Set<ID> accountIds){
        CustomLogging.push('setAccountLastEventDateRelevantDate','SM_EventUtil');
        try{
            List<Account> accountstobeUpdated = new List<Account>();
            if (!accountIds.isEmpty() && accountIds != null){
                List<Account> accountlist = [Select Id, Last_Event_Date__c, Last_Relevant_Activity_Date__c from Account where ID in: accountIds];
                if (!accountlist.isEmpty()){
                    for (Account a : accountlist){
                        Account accupdate = new Account();
                        accupdate.Id = a.Id;
                        if (a.Last_Event_Date__c < date.today() || a.Last_Relevant_Activity_Date__c < date.today() || a.Last_Event_Date__c == null || a.Last_Relevant_Activity_Date__c == null){
                            accupdate.Last_Event_Date__c = date.today();
                            accupdate.Last_Relevant_Activity_Date__c = date.today();
                            accountstobeUpdated.add(accupdate);
                        }
                    }
                    
                    if (!accountstobeUpdated.isEmpty()){
                        update accountstobeUpdated;
                    }
                }
            }
        } catch (Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
    }
}