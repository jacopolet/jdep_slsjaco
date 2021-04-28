//-------------------------------------------------------------------------------------------//
// Author       :   Glenn Serrano - Accenture
// Created Date :   November 12 2018
// Usage        :   Utility Class for Task
//
//-------------------------------------------------------------------------------------------//
public without sharing class SM_TaskUtil {
    public static boolean BoomiClosetask = false;
    //  THIS METHOD WILL SET THE CONTACT LOOKUP FOR TASKS WHERE THE WHAT ID IS AN ACCOUNT AND WILL RETURN THE LIST OF TASKS
    public static List<Task> setMainCommercialContact(List<Task> tasks){
        Set<Id> accIds = new Set<Id>();
        List<Task> tasksWithAccountAsWhatId = filterTasksWithAccountAsWhatId(tasks);

    
        if (!tasksWithAccountAsWhatId.isEmpty()) {
            //  get a set of the contact ID's
            for (Task t : tasksWithAccountAsWhatId) {
                if (!accIds.contains(t.WhatId)) {
                    accIds.add(t.WhatId);
                }
            }

            if (!accIds.isEmpty()) {
                List<Contact> contactList = [Select Id, AccountId FROM Contact WHERE AccountId in:accIds and Main_Commercial_Person__c = True];

                if (!contactList.isEmpty()) {
                    //  we make an assumption here that there is only one main commercial person per account
                    Map<Id, Id> mapAccountToContact = new Map<Id, Id>();
                    for (Contact c : contactList) {
                        mapAccountToContact.put(c.AccountId, c.Id);
                    }

                    //  loop once more over the tasks to set the contact lookup
                    for (Task t : tasks) {
                        if (mapAccountToContact.get(t.WhatId) != null) {
                            t.WhoId = mapAccountToContact.get(t.WhatId);
                            t.Contact__c = mapAccountToContact.get(t.WhatId);
                        }
                    }
                }
            }
        }
    

        return tasks;
    }
    
    public static List<Task> populatecontactcallistingredients(List<Task> tasks){
        Set<Id> accIds = new Set<Id>();
        List<Task> tasksWithAccountAsWhatId = filterTasksWithAccountAsWhatId(tasks);
        Map<String, Call_List_Day_Counter__mdt> getUserId = SM_GetMetadata.getcalllistmdtrecords();
        Map<Id, Id> mapAccountToContact = new Map<Id, Id>();
        if (!tasksWithAccountAsWhatId.isEmpty()) {
            //  get a set of the contact ID's
            for (Task t : tasksWithAccountAsWhatId) {
                if (!accIds.contains(t.WhatId)) {
                    accIds.add(t.WhatId);
                }
            }

            if (!accIds.isEmpty()) {
                List<Contact> contactList = [Select Id, AccountId, Function__c, Main_Commercial_Person__c from Contact where AccountID IN :accIds];

                if (!contactList.isEmpty()) {
                    //  we make an assumption here that there is only one main commercial person per account
                    
                    for (Contact c : contactList) {
                        if (c.Function__c == 'Buyer Ingredients' || c.Function__c == 'Buyer All' || c.Main_Commercial_Person__c == true){
                            mapAccountToContact.put(c.AccountId, c.Id);
                        }
                        
                    }
                }
                //  loop once more over the tasks to set the contact lookup
                for (Task t : tasks) {
                    if (mapAccountToContact.get(t.WhatId) != null) {
                        t.WhoId = mapAccountToContact.get(t.WhatId);
                        t.Contact__c = mapAccountToContact.get(t.WhatId);
                    }
                    if (getUserId.containsKey(t.Sales_Organization__c)){
                        t.OwnerId = getUserId.get(t.Sales_Organization__c).Queue__c;
                    }
                }
            }
        }
    

        return tasks;
    }
    
     //  NOTE THAT THIS METHOD IS RE-USABLE
    public static List<Task> filterTasksWithAccountAsWhatId(List<Task> tasks){
        List<Task> filteredTasks = new List<Task>();

        for(Task t : tasks) {
            if (t.WhatId <> Null) {
                if(String.valueOf(t.WhatId).left(3) == SM_Constants.accountPrefix){
                    filteredTasks.add(t);
                }
            }
        }

        return filteredTasks;
    }
    
    public static void stampCTITasks(List<Task> tasks){
       if (!tasks.isEmpty()){
           for (Task t : tasks){
               if (t.CallType == 'Inbound' && t.CallObject != null){
                   t.Touchpoint_Type__c = 'INBOUND CALL';
                   t.Task_Source__c = 'CTI';
                   t.Status = 'Open';
                   t.Type = 'Call';
               }
               else if ((t.CallType == 'Outbound' || t.CallType == 'Internal') && t.CallObject != null){
                   t.Touchpoint_Type__c = 'OUTBOUND CALL';
                   t.Task_Source__c = 'CTI';
                   t.Status = 'Completed Effective';
                   t.Type = 'Call';
               }
           }
       }
    }
    
    
    public static List<Task> stampAccountLifecycleSegment(List<Task> tasks){
        Set<ID> accounts = new Set<ID>();
        
    
        if (!tasks.isEmpty()){
            for (task t : tasks){
                if (!accounts.contains(t.WhatId)){
                    accounts.add(t.WhatId);
                }
            }
            if (!accounts.isEmpty()){
                List<Account> accountlist = [Select Id, Account_Lifecycle__c, Segment__c, Territory__r.Name, Main_Postal_Code__c, Name FROM Account WHERE Id IN :accounts];
                if (!accountlist.isEmpty()){
                    Map<Id, Account> mapAccountValues = new Map<Id, Account>();
                    for (Account a : accountlist){
                        mapAccountValues.put(a.Id, a);
                    }
                    
                    for (Task t : tasks){
                        if (!mapAccountValues.isEmpty()){
                            Account aVal = (Account) mapAccountValues.get(t.WhatId);
                            t.Account_Lifecycle_HANA__c = aVal.Account_Lifecycle__c;
                            t.Segment__c = aVal.Segment__c;
                            t.Territory__c = aVal.Territory__r.Name;
                            //t.Main_Postal_Code__c = aVal.Main_Postal_Code__c;
                            t.Account_Name__c = aVal.Name;
                            t.Account__c = aVal.Id;
                        }
                    }
                }
            }
        }
        
        return tasks;
    }
    
    public static DateTime removeWeekendsDateTime(DateTime dVal, Decimal addedDays) {
        CustomLogging.push('removeWeekendsDateTime', 'SM_TaskUtil');
        try {
            DateTime dateValue;
            if (dVal != Null) {
                String dayOfWeek = dVal.format('E');
                System.debug('dayOfWeek: ' + dayOfWeek);
                System.debug('addedDays: ' + addedDays);
                if (addedDays >= 5 && !(addedDays >= 28) && (dayOfWeek == 'Mon' || dayOfWeek == 'Tue' || dayOfWeek == 'Wed' || dayOfWeek == 'Thu' || dayOfWeek == 'Fri' || dayOfWeek == 'Sat' || dayOfWeek == 'Sun')) {
                    System.debug('Here 1');
                    dateValue = dVal + 2;
                    System.debug('dateValue1: ' + dateValue);
                } else if ((addedDays == 3 || addedDays == 2)  && (dayOfWeek == 'Mon' || dayOfWeek == 'Sun')) {
                    System.debug('Here 2');
                    dateValue = dVal + 2;
                } else if (dayOfWeek == 'Sat') {
                    System.debug('Here 3');
                    dateValue = dVal + 2;
                    System.debug('dateValue2: ' + dateValue);
                } else if (dayOfWeek == 'Sun') {
                    System.debug('Here 4');
                    dateValue = dVal + 1;
                    System.debug('dateValue3: ' + dateValue);
                } else {
                    dateValue = dVal;
                }
            }
            
            return dateValue;
        } catch (Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
            return null;
        }
    }
    
    public static List<Task> populateAccountLookUponTask (List<Task> tasks){
        CustomLogging.push('populateAccountLookUp', 'SM_TaskUtil');
        try {           
        
            if (!tasks.isEmpty()){
                for (Task t : tasks){
                    t.Account__c = t.WhatId;
                }
            }
        
            
            return tasks;
        
            
        } catch (Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
            return null;
        }
    }
    
    public static List<Task> populateOpportunityLookUponTask (List<Task> tasks){
        CustomLogging.push('populateOpportunityLookUponTask', 'SM_TaskUtil');
        try {           
        
            if (!tasks.isEmpty()){
                for (Task t : tasks){
                    t.Opportunity__c = t.WhatId;
                }
            }
        
            
            return tasks;
        
            
        } catch (Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
            return null;
        } 
    }
    
    public static List<Task> populateCaseLookUponTask (List<Task> tasks){
        CustomLogging.push('populateCaseLookUponTask', 'SM_TaskUtil');
        try {           
        
            if (!tasks.isEmpty()){
                for (Task t : tasks){
                    t.Case__c = t.WhatId;
                }
            }
        
            
            return tasks;
        
            
        } catch (Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
            return null;
        }
    }
    
    public static List<Task> populateLeadLookUponTask (List<Task> tasks){
        CustomLogging.push('populateLeadLookUponTask', 'SM_TaskUtil');
        try {           
        
            if (!tasks.isEmpty()){
                for (Task t : tasks){
                    t.Lead__c = t.WhoId;
                }
            }
        
            
            return tasks;
        
            
        } catch (Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
            return null;
        }
    }
    
    public static List<Task> populateContactLookUponTask (List<Task> tasks){
        CustomLogging.push('populateContactLookUponTask', 'SM_TaskUtil');
        try {   
            if (!tasks.isEmpty()){
                for (Task t : tasks){
                    t.Contact__c = t.WhoId;
                }
            }
            return tasks;
        } catch (Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
            return null;
        }
    }
    
    public static List<Task> getQueue (List<Task> tasks){
        CustomLogging.push('getQueue', 'SM_TaskUtil');
        try {   
            Map<String, Queue_Lead_Tasks__mdt> queueleadtask = SM_GetMetadata.getqueueleadtasks();
            String queueleadkey = '';
            if (!tasks.isEmpty()){
                for (Task t : tasks){
                    queueleadkey = t.Sales_Organization__c + t.Touchpoint_Type__c;
                    if(queueleadtask.get(queueleadkey) != null){
                        if (queueleadtask.get(queueleadkey).Queue_for_Task_Record__c != null && queueleadtask.get(queueleadkey).Queue_for_Task_Record__c != ''){
                            t.OwnerId = queueleadtask.get(queueleadkey).Queue_for_Task_Record__c;
                        }
                    }
                    else {
                        if (queueleadtask.get(t.Sales_Organization__c + 'Default') != null){
                            if (queueleadtask.get(t.Sales_Organization__c + 'Default').Queue_for_Task_Record__c != null && queueleadtask.get(t.Sales_Organization__c + 'Default').Queue_for_Task_Record__c != ''){
                                t.OwnerId = queueleadtask.get(t.Sales_Organization__c + 'Default').Queue_for_Task_Record__c;
                            }
                        }
                    }
                }
            }
            return tasks;
        } catch (Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
            return null;
        }
    }
    
    public static List<Task> populateAssigned(List<Task> tasks) {
        CustomLogging.push('populateAssigned', 'SM_TaskUtil');
        try {
            
            Set<Id> accountrecords = new Set<Id>();
            Set<Id> accountlocationrecords = new Set<Id>();
            Set<Id> contactrecords = new Set<Id>();
            Set<Id> leadrecords = new Set<Id>();
            List<Task> taskPlaceHolder = new List<Task>();
            List<Task> listofTaskRelatedToAccounts = new List<Task>();
            List<Task> listofTasksRelateToAccountLocations = new List<Task>();
            List<Task> listofTasksNameisContacts = new List<Task>();
            List<Task> listofTasksNameisLeads = new List<Task>();
            for (Task t : tasks){
                if(t.WhatId != null){
                    if(String.valueOf(t.WhatId).left(3) == SM_Constants.accountPrefix){
                        listofTaskRelatedToAccounts.add(t);
                    }
                    else if (String.valueOf(t.WhatId).left(3)  == Label.Account_Location_Prefix){
                        listofTasksRelateToAccountLocations.add(t);
                    }
                }
                if (t.WhoId != null){
                    if (String.valueOf(t.WhoId).left(3)  == SM_Constants.contactPrefix){
                        listofTasksNameisContacts.add(t);
                    }
                    else if (String.valueOf(t.WhoId).left(3)  == SM_Constants.leadPrefix){
                        listofTasksNameisLeads.add(t);
                    }  
                }
                
            }
            
            if(!listofTaskRelatedToAccounts.isEmpty()){
                taskPlaceHolder = getQueue(listofTaskRelatedToAccounts);
            }
            if(!listofTasksRelateToAccountLocations.isEmpty()){
                 taskPlaceHolder = getQueue(listofTasksRelateToAccountLocations);
            }
            if(!listofTasksNameisContacts.isEmpty()){
                 taskPlaceHolder = getQueue(listofTasksNameisContacts);
            }
            if(!listofTasksNameisLeads.isEmpty()){
                 taskPlaceHolder = getQueue(listofTasksNameisLeads);
            }
        
         return tasks;
        } catch (Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
            return null;
        }
    }
    
    public static List<Task> taskScoring (List<Task> tasks){
        CustomLogging.push('taskScoring', 'SM_TaskUtil');
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
        ttcMap.put('KPI-SLA CHECK', ttc.KPI_SLA_Score__c);
        ttcMap.put('BUDGET CHECK', ttc.BUDGETS_Score__c);
        ttcMap.put('ONE-TIME BONUS', ttc.ONE_TIME_BONUS_Score__c);
        ttcMap.put('INDEXATION NON STD', ttc.INDEXATION_Score__c);
        ttcMap.put('RENT-BUY', ttc.RENT_BUY_Score__c);
        ttcMap.put('P.O. NUMBER REQUEST', ttc.P_O_NUMBER_Score__c);
        ttcMap.put('VOLUME OBLIG CHECK', ttc.VOLUME_OBLIGATION_Score__c);
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
        ttcMap.put('SUBSCR ORDER ALERT', ttc.SUBSCR_ORDER_ALERT__c);
        ttcMap.put('CREDIT LIMIT ALERT', ttc.CREDIT_LIMIT_ALERT__c);
        ttcMap.put('VOLUME OBLIG SETTL', ttc.VOLUME_OBLIG_SETTL__c);
        ttcMap.put('KPI-SLA SETTL', ttc.KPI_SLA_SETTL__c);
        ttcMap.put('FIXED TERM CHECK', ttc.FIXED_TERM_CHECK__c);
        ttcMap.put('FIXED TERM SETTL', ttc.FIXED_TERMS_SETTL__c);
        ttcMap.put('3+1+1 AGREEMENT RENEWAL', ttc.X3_1_1_AGREEMENT_RENEWAL__c);
        ttcMap.put('3+1+1 ASSET RENEWAL', ttc.X3_1_1_ASSET_RENEWAL__c);
        ttcMap.put('TERMINATED ASSETS - CHECK AGREEMENT', ttc.TERMINATED_ASSETS_CHECK_AGREEMENT__c);
        ttcMap.put('RENEWED ASSET TERMINATION CMR', ttc.RENEWED_ASSET_TERMINATION_CMR__c);
        ttcMap.put('CASE FOLL UP', ttc.CASE_FOLL_UP__c);
        ttcMap.put('ACCOUNT BLOCK RELEASE REQUEST', ttc.ACCOUNT_BLOCK_RELEASE_REQUEST__c);
        ttcMap.put('CALL LIST INGREDIENTS', ttc.CALL_LIST_INGREDIENTS__c);
        ttcMap.put('ROUTE SALES RESCHEDULING', ttc.ROUTE_SALES_RESCHEDULING__c);
        ttcMap.put('ONLINE MASTER DATA CHANGE REQ', ttc.ONLINE_MASTER_DATA_CHANGE_REQ__c);
        ttcMap.put('MACHINE CASE WITH NO WARRANTY', ttc.MACHINE_CASE_WITH_NO_WARRANTY__c);
        ttcMap.put('OUTBOUND CALL', ttc.OUTBOUND_CALL__c);
        ttcMap.put('INSTALLATION / DE-INSTALLATION', ttc.INSTALLATION_DE_INSTALLATION__c); 
        ttcMap.put('MOVEMNT (ADMIN)', ttc.MOVEMNT_ADMIN__c);
        ttcMap.put('BREAKDOWN',ttc.BREAKDOWN__c);
        ttcMap.put('MACHINE SWAP',ttc.MACHINE_SWAP__c);
        ttcMap.put('COUNTER READINGS',ttc.COUNTER_READINGS__c);
        ttcMap.put('E-INVOICING REQUEST', ttc.E_INVOICING_REQUEST__c);
        ttcMap.put('MANUAL',ttc.MANUAL__c);
        ttcMap.put('REMINDER',ttc.REMINDER__c);
        ttcMap.put('CREDIT CHECK',ttc.CREDIT_CHECK__c);
        ttcMap.put('ONLINE GENERAL REQUEST MC', ttc.ONLINE_GENERAL_REQUEST_MC__c);
        ttcMap.put('LEAD NURTURING', ttc.LEAD_NURTURING__c);
        ttcMap.put('ONLINE CAMPAIGN', ttc.ONLINE_CAMPAIGN__c);
        ttcMap.put('CONVERSION (MACHINE)', ttc.CONVERSION_MACHINE__c);
        ttcMap.put('CONVERSION (SERVICE)', ttc.CONVERSION_SERVICE__c);
            
        Map<String, Decimal> atlMap = new Map<String, Decimal>();
        Account_Tier_Lead_Score__c atl = Account_Tier_Lead_Score__c.getOrgDefaults();
        atlMap.put('Bronze', atl.Bronze__c);
        atlMap.put('Gold', atl.Gold_Score__c);
        atlMap.put('Platinum', atl.Platinum_Score__c);
        atlMap.put('Silver', atl.Silver_Score__c);
        atlMap.put('Lead Score', atl.Lead_Score__c);
        Set<Id> updateTasksId = new Set<Id>();
        List<Task> updateTasks = new List<Task>();
        Set<Id> accountIds = new Set<Id>();
        List<Task> taskwithaccountWhatId = new List<Task>();
        List<Task> taskwithleadWhoId = new List<Task>();
        List<Task> taskwithTTscoreonly = new List<Task>();
        try {
    
        if(!tasks.isEmpty()){
            for (Task t : tasks){
                if (t.WhatId != null){
                    if (String.valueOf(t.WhatId).left(3) == SM_Constants.accountPrefix){
                        taskwithaccountWhatId.add(t);
                    }
                    else if(String.valueOf(t.WhatId).left(3) != SM_Constants.accountPrefix){
                        taskwithTTscoreonly.add(t);
                    }
                }
                if (t.WhoId != null){
                    if (String.valueOf(t.WhoId).left(3)  == SM_Constants.leadPrefix){
                        taskwithleadWhoId.add(t);
                    }
                    else if(t.WhoId != null && String.valueOf(t.WhoId).left(3) != SM_Constants.leadPrefix ){
                        taskwithTTscoreonly.add(t);
                    }
                }
                if (t.WhatId == null && t.WhoId == null){
                    taskwithTTscoreonly.add(t);
                }
            }
            
            if (!taskwithaccountWhatId.isEmpty()){
                for (Task t : taskwithaccountWhatId){
                    if (!accountIds.contains(t.WhatId)){
                        accountIds.add(t.WhatId);
                    }
                }
                if (!accountIds.isEmpty()){
                    List<Account> accountrecords = [Select Id, Account_Tier__c FROM Account WHERE Id IN :accountIds];
                    Map<Id, String> accounttier = new Map<Id,String>();
                    for (Account a : accountrecords){
                        accounttier.put(a.Id, a.Account_Tier__c);
                    }
                    for (Task t : taskwithaccountWhatId){
                        Task taskrec = new Task();
                        taskrec.Id = t.Id;
                        if (atlMap.get(accounttier.get(t.WhatId)) != null && ttcMap.get(t.Touchpoint_Type__c) != null){
                            taskrec.Priority_Score__c = atlMap.get(accounttier.get(t.WhatId)) + ttcMap.get(t.Touchpoint_Type__c);
                            if (taskrec.Priority_Score__c > 100){
                                taskrec.Priority_Score__c = 100;
                            }
                        }
                        else{
                            taskrec.Priority_Score__c = atlMap.get(accounttier.get(t.WhatId));
                        }
                        
                        if (!updateTasksId.contains(taskrec.Id)) {
                            updateTasksId.add(taskrec.Id);
                            updateTasks.add(taskrec);
                        }
                    }
                }
            }
            if (!taskwithleadWhoId.isEmpty()){
                for (Task t : taskwithleadWhoId){
                    Task taskrec = new Task();
                    taskrec.Id = t.Id;
                    
                    if (t.Touchpoint_Type__c != SM_Constants.STANDAGREEMENT && t.Touchpoint_Type__c != SM_Constants.TAILORMADEAGREEMENT && 
                    t.Touchpoint_Type__c != SM_Constants.CMDCHANGE && t.Touchpoint_Type__c != SM_Constants.SIGNEDCONTRACT &&
                    t.Touchpoint_Type__c != SM_Constants.GENERICREQUEST && t.Touchpoint_Type__c != SM_Constants.REPORTREQUEST &&
                    t.Touchpoint_Type__c != SM_Constants.CONTACTREQUEST && t.Touchpoint_Type__c != SM_Constants.OTHERREQUEST && 
                    t.Touchpoint_Type__c != SM_Constants.NPS && t.Touchpoint_Type__c != SM_Constants.AFTINSTAL &&
                    t.Touchpoint_Type__c != SM_Constants.MOVEMNT && t.Touchpoint_Type__c != SM_Constants.MPV &&
                    t.Touchpoint_Type__c != SM_Constants.WARMWELCOMEFOLLUP && t.Touchpoint_Type__c != SM_Constants.FIRSTORDERSURVEY &&
                    t.Touchpoint_Type__c != SM_Constants.KPISLA && t.Touchpoint_Type__c != SM_Constants.BUDGETS &&
                    t.Touchpoint_Type__c != SM_Constants.ONETIMEBONUS && t.Touchpoint_Type__c != SM_Constants.INDEXATION &&
                    t.Touchpoint_Type__c != SM_Constants.RENTBUY && t.Touchpoint_Type__c != SM_Constants.PONUMBER &&
                    t.Touchpoint_Type__c != SM_Constants.VOLUMEOBLIGATION && t.Touchpoint_Type__c != SM_Constants.FIXEDPAYMENTTERMS &&
                    t.Touchpoint_Type__c != SM_Constants.SELLOUTDATA && t.Touchpoint_Type__c != SM_Constants.SUBSCRORDER &&
                    t.Touchpoint_Type__c != SM_Constants.CREDITLIMITALERT && t.Touchpoint_Type__c != SM_Constants.VOLUMEOBLIGATION && 
                    t.Touchpoint_Type__c != SM_Constants.VOLUMEOBLIGSETTL && t.Touchpoint_Type__c != SM_Constants.KPISLASETTL && 
                    t.Touchpoint_Type__c != SM_Constants.FIXEDTERMCHECK && t.Touchpoint_Type__c != SM_Constants.FIXEDTERMSSETTL &&
                    t.Touchpoint_Type__c != SM_Constants.AGREEMENTRENEWAL && t.Touchpoint_Type__c != SM_Constants.ASSETRENEWAL && 
                    t.Touchpoint_Type__c != SM_Constants.ASSETSCHECKAGREEMENT && t.Touchpoint_Type__c != SM_Constants.ASSETTERMINATIONCMR && 
                    t.Touchpoint_Type__c != SM_Constants.CASEFOLLUP && t.Touchpoint_Type__c != SM_Constants.ACCOUNTBLOCKRELEASE &&
                    t.Touchpoint_Type__c != SM_Constants.CALLLISTINGREDIENTS && t.Touchpoint_Type__c != SM_Constants.ROUTESALESRESCHEDULING && 
                    t.Touchpoint_Type__c != SM_Constants.ONLINEMASTERDATACHANGE && t.Touchpoint_Type__c != SM_Constants.MACHINECASEWITHNOWARRANTY && 
                    t.Touchpoint_Type__c != SM_Constants.OUTBOUNDCALL && t.Touchpoint_Type__c != SM_Constants.CONVERSIONMACHINE &&
                    t.Touchpoint_Type__c != SM_Constants.CONVERSIONSERVICE) {
                        if (atlMap.get('Lead Score') != Null) {
                            taskrec.Priority_Score__c = ttcMap.get(t.Touchpoint_Type__c) + atlMap.get('Lead Score');
                            if (taskrec.Priority_Score__c > 100){
                                taskrec.Priority_Score__c = 100;
                            }
                        } else {
                            taskrec.Priority_Score__c = ttcMap.get(t.Touchpoint_Type__c);
                        }
                    }
                    if (!updateTasksId.contains(taskrec.Id)) {
                        updateTasksId.add(taskrec.Id);
                        updateTasks.add(taskrec);
                    }
                }
            }
            if (!taskwithTTscoreonly.isEmpty()){
                for (Task t : taskwithTTscoreonly){
                    Task taskrec = new Task();
                    taskrec.Id = t.Id;
                    taskrec.Priority_Score__c = ttcMap.get(t.Touchpoint_Type__c);
                     if (!updateTasksId.contains(taskrec.Id)) {
                        updateTasksId.add(taskrec.Id);
                        updateTasks.add(taskrec);
                    }
                }
            }
        }
    
        return updateTasks;
        } catch (Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
            return null;
        }
    }
    public static List<Task> StampWhatTypeWhoType (List<Task> tasks){
        CustomLogging.push('StampWhatTypeWhoType', 'SM_TaskUtil');
        try{
            Set<Id> updateTaskIds = new Set<Id>();
            List<Task> updateTask = new List<Task>();
            List<Task> taskRecs = new List<Task>();
        
            if (!tasks.isEmpty()){
                taskRecs = [Select Id, Who.type, What.type, WhatId, WhoId from Task WHERE ID in : tasks];
                for (Task t : taskRecs){
                    if (t.WhatId != null || t.WhoId != null) {
                        t.WhatType__c = t.What.type;
                        t.WhoType__c = t.Who.type;
                        if (!updateTaskIds.contains(t.Id)){
                            updateTask.add(t);
                            updateTaskIds.add(t.Id);
                        }
                    }
                }
            }
            
        return updateTask;
        } catch (Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
            return null;
        }
    }
    public static List<Task> stampSLATask (List<Task> tasks){
        CustomLogging.push('stampSLaTask', 'SM_TaskUtil');
        List<Task> updateTasks = new List<Task>();
        Set<Id> updateTaskIds = new Set<Id>();
        Datetime startDate;
        Datetime dueDate;
        Datetime targetCompletionDate;
        Datetime taskExpiratioDate;
        DateTime tExpirationDate;
        Date DateDue;
        Time DateDueTime;
        User userInfor = new User();
        userInfor = [Select Id, Name, Profile.Name, Country FROM User WHERE ID = :UserInfo.getUserId()];
        try {
        
                for (Task t : tasks){
                    Task taskrec = new Task();
                    taskrec.Id = t.Id;
                    taskrec.Touchpoint_Type__c = t.Touchpoint_Type__c;
                    taskrec.Start_DateCS__c = t.Start_DateCS__c;
                    taskrec.OwnerId = t.OwnerId;
                    taskrec.Task_Source__c = t.Task_Source__c;
                    taskrec.Type = t.Type;
                    taskrec.RecordTypeId = t.RecordTypeId;
                    taskrec.Suggested_Completion_Date__c = t.Suggested_Completion_Date__c;
                    taskrec.Task_Expiration_Date__c = t.Task_Expiration_Date__c;
                    taskrec.ActivityDate = t.ActivityDate;
                    taskrec.DueDateTime__c = t.DueDateTime__c;
                    if (taskRec.Touchpoint_Type__c == SM_Constants.INBOUNDCALL || taskRec.Touchpoint_Type__c == SM_Constants.ONLINEINFORMATIONREQUEST || taskRec.Touchpoint_Type__c == SM_Constants.ONLINEQUOTEREQUEST 
                        || taskRec.Touchpoint_Type__c == SM_Constants.REFERRALPARTNER || taskRec.Touchpoint_Type__c == SM_Constants.REFERRALEMPLOYEE || taskRec.Touchpoint_Type__c == SM_Constants.REFERRALTECHNICIAN || taskRec.Touchpoint_Type__c == SM_Constants.REFERRALROUTESALES
                        || taskRec.Touchpoint_Type__c == SM_Constants.REFERRALCUSTOMER || taskRec.Touchpoint_Type__c == SM_Constants.REFERRALBUYINGGROUP || taskRec.Touchpoint_Type__c == SM_Constants.TAILORMADEAGREEMENT || taskRec.Touchpoint_Type__c == SM_Constants.STANDAGREEMENT 
                        || taskRec.Touchpoint_Type__c == SM_Constants.CMDCHANGE || taskRec.Touchpoint_Type__c == SM_Constants.SIGNEDCONTRACT || taskRec.Touchpoint_Type__c == SM_Constants.GENERICREQUEST || taskRec.Touchpoint_Type__c == SM_Constants.REPORTREQUEST
                        || taskRec.Touchpoint_Type__c == SM_Constants.CONTACTREQUEST) {
                        SLA_Task__c slas = SLA_Task__c.getInstance(taskRec.Touchpoint_Type__c);
                        //Start Date
                        if (taskRec.Start_DateCS__c == Null) {
                         startDate = t.CreatedDate + slas.Start_Date__c;
                         taskRec.Start_DateCS__c = removeWeekendsDateTime(startDate, slas.Start_Date__c);   
                        }
                        //Due Date
                        dueDate = taskRec.Start_DateCS__c + slas.Due_Date__c;
                        taskRec.ActivityDate = removeWeekendsDateTime(dueDate, slas.Due_Date__c).date();
                         
                        //Target Completion Date
                        targetCompletionDate = taskRec.Start_DateCS__c + slas.Target_Completion_Date__c;
                        taskRec.Suggested_Completion_Date__c = removeWeekendsDateTime(targetCompletionDate, slas.Target_Completion_Date__c);
                        //Task Expiration Date
                        taskExpiratioDate = taskRec.Start_DateCS__c + slas.Task_Expiration_Date__c;
                        tExpirationDate = removeWeekendsDateTime(taskExpiratioDate, slas.Task_Expiration_Date__c);
                        taskRec.Task_Expiration_Date__c = DateTime.newInstance(tExpirationDate.Year(), tExpirationDate.Month(), tExpirationDate.Day(), taskRec.Start_DateCS__c.hour(), taskRec.Start_DateCS__c.minute(), taskRec.Start_DateCS__c.second());
                    
                    } else if (taskRec.Touchpoint_Type__c == SM_Constants.COLDAQCUISITION || taskRec.Touchpoint_Type__c == SM_Constants.OTHERREQUEST || taskRec.Touchpoint_Type__c == SM_Constants.OUTBOUNDCALL) {
                        SLA_Task__c slas = SLA_Task__c.getInstance(taskRec.Touchpoint_Type__c);
                        //Start Date
                        if (taskRec.Start_DateCS__c == Null) {
                         startDate = t.CreatedDate + slas.Start_Date__c;
                         taskRec.Start_DateCS__c = removeWeekendsDateTime(startDate, slas.Start_Date__c);
                        }
                        //Target Completion Date
                        if (taskRec.ActivityDate != null && taskRec.DueDateTime__c != null) {
                        DateDue = taskRec.ActivityDate;
                        List<String> timepart = taskRec.DueDateTime__c.split(':');
                        DateDueTime = time.newInstance(Integer.valueOf(timepart[0]), Integer.valueOf(timepart[1]), 0, 0);
                        targetCompletionDate = DateTime.newInstance(DateDue.Year(), DateDue.Month(), DateDue.Day(), DateDueTime.hour(), DateDueTime.minute(), DateDueTime.second());
                        taskRec.Suggested_Completion_Date__c = targetCompletionDate;
                        }
                        //Task Expiration Date
                        taskExpiratioDate = taskRec.Start_DateCS__c + slas.Task_Expiration_Date__c;
                        tExpirationDate = removeWeekendsDateTime(taskExpiratioDate, slas.Task_Expiration_Date__c);
                        taskRec.Task_Expiration_Date__c = DateTime.newInstance(tExpirationDate.Year(), tExpirationDate.Month(), tExpirationDate.Day(), taskRec.Start_DateCS__c.hour(), taskRec.Start_DateCS__c.minute(), taskRec.Start_DateCS__c.second());

                    } else if (taskRec.Touchpoint_Type__c == SM_Constants.ONLINEINFORMATIONREQUESTMC || taskRec.Touchpoint_Type__c == SM_Constants.ONLINEQUOTEREQUESTMC || taskRec.Touchpoint_Type__c == SM_Constants.ENDWARR
                              || taskRec.Touchpoint_Type__c == SM_Constants.PROMOTION || taskRec.Touchpoint_Type__c == SM_Constants.NEWPRODUCTINTRO || taskRec.Touchpoint_Type__c == SM_Constants.CROSSUPSELL 
                              || taskRec.Touchpoint_Type__c == SM_Constants.PRODUCTCHANGE || taskRec.Touchpoint_Type__c == SM_Constants.CAMP || taskRec.Touchpoint_Type__c == SM_Constants.LEADNURTURING || taskRec.Touchpoint_Type__c == SM_Constants.ONLINECAMPAIGN) {
                               
                        SLA_Task__c slas = SLA_Task__c.getInstance(taskRec.Touchpoint_Type__c);
                        //Start Date
                        startDate = t.CreatedDate + slas.Start_Date__c;
                        taskRec.Start_DateCS__c = removeWeekendsDateTime(startDate, slas.Start_Date__c);
                        //Due Date
                        dueDate = taskRec.Start_DateCS__c + slas.Due_Date__c;
                        taskRec.ActivityDate = removeWeekendsDateTime(dueDate, slas.Due_Date__c).date();
                         
                        //Target Completion Date
                        targetCompletionDate = taskRec.Start_DateCS__c + slas.Target_Completion_Date__c;
                        taskRec.Suggested_Completion_Date__c = removeWeekendsDateTime(targetCompletionDate, slas.Target_Completion_Date__c);
                        //Task Expiration Date
                        taskExpiratioDate = taskRec.Start_DateCS__c + slas.Task_Expiration_Date__c;
                        tExpirationDate = removeWeekendsDateTime(taskExpiratioDate, slas.Task_Expiration_Date__c);
                        taskRec.Task_Expiration_Date__c = DateTime.newInstance(tExpirationDate.Year(), tExpirationDate.Month(), tExpirationDate.Day(), taskRec.Start_DateCS__c.hour(), taskRec.Start_DateCS__c.minute(), taskRec.Start_DateCS__c.second());
    
                    
                    } else if (taskRec.Touchpoint_Type__c == SM_Constants.TRADESHOWEVENT || taskRec.Touchpoint_Type__c == SM_Constants.CREDITLIMITALERT) {
                        SLA_Task__c slas = SLA_Task__c.getInstance(taskRec.Touchpoint_Type__c);
                        //Start Date
                        if (taskRec.Start_DateCS__c == Null) {
                            startDate = t.CreatedDate + slas.Start_Date__c;
                            taskRec.Start_DateCS__c = removeWeekendsDateTime(startDate, slas.Start_Date__c);
                            //Due Date
                            dueDate = taskRec.Start_DateCS__c + slas.Due_Date__c;
                            taskRec.ActivityDate = removeWeekendsDateTime(dueDate, slas.Due_Date__c).date(); 
            
                             
                            //Target Completion Date
                            targetCompletionDate = taskRec.Start_DateCS__c + slas.Target_Completion_Date__c;
                            taskRec.Suggested_Completion_Date__c = removeWeekendsDateTime(targetCompletionDate, slas.Target_Completion_Date__c);
                            //Task Expiration Date
                            taskExpiratioDate = taskRec.Start_DateCS__c + slas.Task_Expiration_Date__c;
                            tExpirationDate = removeWeekendsDateTime(taskExpiratioDate, slas.Task_Expiration_Date__c);
                            taskRec.Task_Expiration_Date__c = DateTime.newInstance(tExpirationDate.Year(), tExpirationDate.Month(), tExpirationDate.Day(), taskRec.Start_DateCS__c.hour(), taskRec.Start_DateCS__c.minute(), taskRec.Start_DateCS__c.second());
                        } else {
                            startDate = removeWeekendsDateTime(taskRec.Start_DateCS__c, slas.Start_Date__c);
                            dueDate = startDate + slas.Due_Date__c;
                            taskRec.ActivityDate = removeWeekendsDateTime(dueDate, slas.Due_Date__c).date();
                            targetCompletionDate = startDate + slas.Target_Completion_Date__c;
                            taskRec.Suggested_Completion_Date__c = removeWeekendsDateTime(targetCompletionDate, slas.Target_Completion_Date__c);
                            //Task Expiration Date
                            taskExpiratioDate = startDate + slas.Task_Expiration_Date__c;
                            tExpirationDate = removeWeekendsDateTime(taskExpiratioDate, slas.Task_Expiration_Date__c);
                            taskRec.Task_Expiration_Date__c = DateTime.newInstance(tExpirationDate.Year(), tExpirationDate.Month(), tExpirationDate.Day(), startDate.hour(), startDate.minute(), startDate.second());
                        }

                    } else if (taskRec.Touchpoint_Type__c == SM_Constants.NEWSTARTEDCOMPANY || taskRec.Touchpoint_Type__c == SM_Constants.COMPANYCHANGE || taskRec.Touchpoint_Type__c == SM_Constants.PROSPECTLIST) {
                        SLA_Task__c slas = SLA_Task__c.getInstance(taskRec.Touchpoint_Type__c);
                        //Start Date
                        if (taskRec.Start_DateCS__c == Null) {
                         startDate = t.CreatedDate + slas.Start_Date__c;
                         taskRec.Start_DateCS__c = removeWeekendsDateTime(startDate, slas.Start_Date__c);  
                        }
                        //Due Date
                        if (taskRec.ActivityDate == Null) {
                          dueDate = taskRec.Start_DateCS__c + slas.Due_Date__c;
                          taskRec.ActivityDate = removeWeekendsDateTime(dueDate, slas.Due_Date__c).date(); 
                        }
                         
                        //Target Completion Date
                        targetCompletionDate = taskRec.Start_DateCS__c + slas.Target_Completion_Date__c;
                        taskRec.Suggested_Completion_Date__c = removeWeekendsDateTime(targetCompletionDate, slas.Target_Completion_Date__c);
                        //Task Expiration Date
                        taskExpiratioDate = taskRec.Start_DateCS__c + slas.Task_Expiration_Date__c;
                        tExpirationDate = removeWeekendsDateTime(taskExpiratioDate, slas.Task_Expiration_Date__c);
                        taskRec.Task_Expiration_Date__c = DateTime.newInstance(tExpirationDate.Year(), tExpirationDate.Month(), tExpirationDate.Day(), taskRec.Start_DateCS__c.hour(), taskRec.Start_DateCS__c.minute(), taskRec.Start_DateCS__c.second());
    
                    } else if (taskRec.Touchpoint_Type__c == SM_Constants.AFTINSTAL || taskRec.Touchpoint_Type__c == SM_Constants.MOVEMNT) {
                        SLA_Task__c slas = SLA_Task__c.getInstance(taskRec.Touchpoint_Type__c);
                        if (taskRec.Start_DateCS__c != Null){
                            //Due Date
                            dueDate = taskRec.Start_DateCS__c + slas.Due_Date__c;
                            taskRec.ActivityDate = removeWeekendsDateTime(dueDate, slas.Due_Date__c).date();
                             
                            //Target Completion Date
                            targetCompletionDate = taskRec.Start_DateCS__c + slas.Target_Completion_Date__c;
                            taskRec.Suggested_Completion_Date__c = removeWeekendsDateTime(targetCompletionDate, slas.Target_Completion_Date__c);
                            //Task Expiration Date
                            taskExpiratioDate = taskRec.Start_DateCS__c + slas.Task_Expiration_Date__c;
                            tExpirationDate = removeWeekendsDateTime(taskExpiratioDate, slas.Task_Expiration_Date__c);
                            taskRec.Task_Expiration_Date__c = DateTime.newInstance(tExpirationDate.Year(), tExpirationDate.Month(), tExpirationDate.Day(), taskRec.Start_DateCS__c.hour(), taskRec.Start_DateCS__c.minute(), taskRec.Start_DateCS__c.second());
                        }

                    } else if (taskRec.Touchpoint_Type__c == SM_Constants.NPS || taskRec.Touchpoint_Type__c == SM_Constants.WARMWELCOMEFOLLUP || taskRec.Touchpoint_Type__c == SM_Constants.FIRSTORDERSURVEY
                                || taskRec.Touchpoint_Type__c == SM_Constants.KPISLA || taskRec.Touchpoint_Type__c == SM_Constants.BUDGETS || taskRec.Touchpoint_Type__c == SM_Constants.PONUMBER
                                || taskRec.Touchpoint_Type__c == SM_Constants.VOLUMEOBLIGATION || taskRec.Touchpoint_Type__c == SM_Constants.SUBSCRORDER || taskRec.Touchpoint_Type__c == SM_Constants.VOLUMEOBLIGSETTL
                                || taskRec.Touchpoint_Type__c == SM_Constants.ONETIMEBONUS || taskRec.Touchpoint_Type__c == SM_Constants.KPISLASETTL || taskRec.Touchpoint_Type__c == SM_Constants.FIXEDTERMCHECK
                                || taskRec.Touchpoint_Type__c == SM_Constants.FIXEDTERMSSETTL || taskRec.Touchpoint_Type__c == SM_Constants.AGREEMENTRENEWAL || taskRec.Touchpoint_Type__c == SM_Constants.ASSETRENEWAL
                                || taskRec.Touchpoint_Type__c == SM_Constants.ASSETSCHECKAGREEMENT || taskRec.Touchpoint_Type__c == SM_Constants.ASSETTERMINATIONCMR || taskRec.Touchpoint_Type__c == SM_Constants.ACCOUNTBLOCKRELEASE
                                || taskRec.Touchpoint_Type__c == SM_Constants.ROUTESALESRESCHEDULING || taskRec.Touchpoint_Type__c == SM_Constants.ONLINEMASTERDATACHANGE || taskRec.Touchpoint_Type__c == SM_Constants.CALLLISTINGREDIENTS
                                || taskRec.Touchpoint_Type__c == SM_Constants.INDEXATIONNONSTD) {
                        SLA_Task__c slas = SLA_Task__c.getInstance(taskRec.Touchpoint_Type__c);
                        //Start Date
                        taskRec.Start_DateCS__c = t.CreatedDate;
                        if (taskRec.Touchpoint_Type__c <> SM_Constants.CALLLISTINGREDIENTS && (userInfor.Profile.Name <> 'JDE-Integration-Marketing Cloud' || userInfor.Profile.Name <> 'System Administrator')) {
                            //Due Date
                            dueDate = taskRec.Start_DateCS__c + slas.Due_Date__c;
                            taskRec.ActivityDate = removeWeekendsDateTime(dueDate, slas.Due_Date__c).date();
                        }
                        //Target Completion Date
                        targetCompletionDate = taskRec.Start_DateCS__c + slas.Target_Completion_Date__c;
                        taskRec.Suggested_Completion_Date__c = removeWeekendsDateTime(targetCompletionDate, slas.Target_Completion_Date__c);
                        //Task Expiration Date
                        taskExpiratioDate = taskRec.Start_DateCS__c + slas.Task_Expiration_Date__c;
                        tExpirationDate = removeWeekendsDateTime(taskExpiratioDate, slas.Task_Expiration_Date__c);
                        taskRec.Task_Expiration_Date__c = DateTime.newInstance(tExpirationDate.Year(), tExpirationDate.Month(), tExpirationDate.Day(), taskRec.Start_DateCS__c.hour(), taskRec.Start_DateCS__c.minute(), taskRec.Start_DateCS__c.second());
    
                    } else if (taskRec.Touchpoint_Type__c == SM_Constants.CASEFOLLUP) {
                        SLA_Task__c slas = SLA_Task__c.getInstance(taskRec.Touchpoint_Type__c);
                        //Start Date
                        if (taskRec.Start_DateCS__c != Null) {
                         startDate = taskRec.Start_DateCS__c + slas.Start_Date__c;
                         taskRec.Start_DateCS__c = removeWeekendsDateTime(startDate, slas.Start_Date__c);   
                        }
                        else{
                         taskRec.Start_DateCS__c = t.CreatedDate;
                        }
                                
                        //Target Completion Date
                        if (taskRec.ActivityDate != null && taskRec.DueDateTime__c != null) {
                        DateDue = taskRec.ActivityDate;
                        List<String> timepart = taskRec.DueDateTime__c.split(':');
                        DateDueTime = time.newInstance(Integer.valueOf(timepart[0]), Integer.valueOf(timepart[1]), 0, 0);
                        targetCompletionDate = DateTime.newInstance(DateDue.Year(), DateDue.Month(), DateDue.Day(), DateDueTime.hour(), DateDueTime.minute(), DateDueTime.second());
                        taskRec.Suggested_Completion_Date__c = targetCompletionDate;
                        }
                                 
                        //Task Expiration Date
                        taskExpiratioDate = taskRec.Start_DateCS__c + slas.Task_Expiration_Date__c;
                        tExpirationDate = removeWeekendsDateTime(taskExpiratioDate, slas.Task_Expiration_Date__c);
                        taskRec.Task_Expiration_Date__c = DateTime.newInstance(tExpirationDate.Year(), tExpirationDate.Month(), tExpirationDate.Day(), taskRec.Start_DateCS__c.hour(), taskRec.Start_DateCS__c.minute(), taskRec.Start_DateCS__c.second());
    
                    } else if (taskRec.Touchpoint_Type__c == SM_Constants.MACHINECASEWITHNOWARRANTY) {
                        SLA_Task__c slas = SLA_Task__c.getInstance(taskRec.Touchpoint_Type__c); 
                        //Start Date
                        if (taskRec.Start_DateCS__c != Null) {
                         startDate = taskRec.Start_DateCS__c + slas.Start_Date__c;
                         taskRec.Start_DateCS__c = removeWeekendsDateTime(startDate, slas.Start_Date__c);   
                        }
                        else{
                            taskRec.Start_DateCS__c = t.CreatedDate;
                        }
                        //Due Date
                        dueDate = taskRec.Start_DateCS__c + slas.Due_Date__c;
                        taskRec.ActivityDate = removeWeekendsDateTime(dueDate, slas.Due_Date__c).date();
                         
                        //Target Completion Date
                        targetCompletionDate = taskRec.Start_DateCS__c + slas.Target_Completion_Date__c;
                        taskRec.Suggested_Completion_Date__c = removeWeekendsDateTime(targetCompletionDate, slas.Target_Completion_Date__c);
                        //Task Expiration Date
                        taskExpiratioDate = taskRec.Start_DateCS__c + slas.Task_Expiration_Date__c;
                        tExpirationDate = removeWeekendsDateTime(taskExpiratioDate, slas.Task_Expiration_Date__c);
                        taskRec.Task_Expiration_Date__c = DateTime.newInstance(tExpirationDate.Year(), tExpirationDate.Month(), tExpirationDate.Day(), taskRec.Start_DateCS__c.hour(), taskRec.Start_DateCS__c.minute(), taskRec.Start_DateCS__c.second());
    
                    } else if (taskRec.Touchpoint_Type__c == SM_Constants.INSTALLATIONDEINSTALLATION || taskRec.Touchpoint_Type__c == SM_Constants.MOVEMENTADMIN ||
                               taskRec.Touchpoint_Type__c == SM_Constants.BREAKDOWN || taskRec.Touchpoint_Type__c == SM_Constants.MACHINESWAP || 
                               taskRec.Touchpoint_Type__c == SM_Constants.MACHINESWAP || taskRec.Touchpoint_Type__c == SM_Constants.COUNTERREADINGS ||
                               taskRec.Touchpoint_Type__c == SM_Constants.EINVOICINGREQUEST || taskRec.Touchpoint_Type__c == SM_Constants.CREDITCHECK ||
                               taskRec.Touchpoint_Type__c == SM_Constants.ONLINEGENERALREQUESTMC || taskRec.Touchpoint_Type__c == SM_Constants.CONVERSIONMACHINE ||
                               taskRec.Touchpoint_Type__c == SM_Constants.CONVERSIONSERVICE) {
                        SLA_Task__c slas = SLA_Task__c.getInstance(taskRec.Touchpoint_Type__c);
                        //Start Date
                        if (taskRec.Start_DateCS__c == Null) {
                         startDate = t.CreatedDate + slas.Start_Date__c;
                         taskRec.Start_DateCS__c = removeWeekendsDateTime(startDate, slas.Start_Date__c);   
                        }
                        //Due Date
                        dueDate = taskRec.Start_DateCS__c + slas.Due_Date__c;
                        taskRec.ActivityDate = removeWeekendsDateTime(dueDate, slas.Due_Date__c).date();
                         
                        //Target Completion Date
                        taskRec.Suggested_Completion_Date__c = removeWeekendsDateTime(dueDate, slas.Due_Date__c);
                        //Task Expiration Date
                        taskExpiratioDate = taskRec.Start_DateCS__c + slas.Task_Expiration_Date__c;
                        tExpirationDate = removeWeekendsDateTime(taskExpiratioDate, slas.Task_Expiration_Date__c);
                        taskRec.Task_Expiration_Date__c = DateTime.newInstance(tExpirationDate.Year(), tExpirationDate.Month(), tExpirationDate.Day(), taskRec.Start_DateCS__c.hour(), taskRec.Start_DateCS__c.minute(), taskRec.Start_DateCS__c.second());
                    } else if (taskRec.Touchpoint_Type__c == SM_Constants.MANUAL || taskRec.Touchpoint_Type__c == SM_Constants.REMINDER || taskRec.Touchpoint_Type__c == SM_Constants.COLDAQCUISITION ||
                               taskRec.Touchpoint_Type__c == SM_Constants.GENERICREQUEST) {
                        SLA_Task__c slas = SLA_Task__c.getInstance(taskRec.Touchpoint_Type__c);
                        //Start Date
                        if (taskRec.Start_DateCS__c == Null) {
                         startDate = t.CreatedDate + slas.Start_Date__c;
                         taskRec.Start_DateCS__c = removeWeekendsDateTime(startDate, slas.Start_Date__c);   
                        }
                        
                        //Task Expiration Date
                        taskExpiratioDate = taskRec.Start_DateCS__c + slas.Task_Expiration_Date__c;
                        tExpirationDate = removeWeekendsDateTime(taskExpiratioDate, slas.Task_Expiration_Date__c);
                        taskRec.Task_Expiration_Date__c = DateTime.newInstance(tExpirationDate.Year(), tExpirationDate.Month(), tExpirationDate.Day(), taskRec.Start_DateCS__c.hour(), taskRec.Start_DateCS__c.minute(), taskRec.Start_DateCS__c.second());
                    }
                    
                
                if (!updateTaskIds.contains(TaskRec.Id)) {
                    updateTasks.add(taskrec);
                    updateTaskIds.add(taskrec.Id);
                }
            }
        
    
        return updateTasks;
        } catch(exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
            return null;
        }  
    }
    
    public static List<Task> StampAccountLifecycleSegmentAccountnamewhenrelatedtoopptyoraccloc (List<Task> tasks){
        CustomLogging.push('StampAccountLifecycleSegmentAccountnamewhenrelatedtoopptyoraccloc', 'SM_TaskUtil');
        try{
            Datetime dateToday = datetime.now();
            String monthName = dateToday.format(SM_Constants.dateFormat);
            Set<Id> tasksrelatedtooppty = new Set<Id>();
            Set<Id> tasksrelatedtoaccloc = new Set<Id>();
            
            if (!tasks.isEmpty()){
                for (Task t : tasks){
                    if (String.valueOf(t.WhatId).left(3) == SM_Constants.oppPrefix){
                        tasksrelatedtooppty.add(t.WhatId);
                    }
                    else if (String.valueOf(t.WhatId).left(3) == Label.Account_Location_Prefix){
                        tasksrelatedtoaccloc.add(t.WhatId);
                    }
                }
            }
            
            if (!tasksrelatedtooppty.isEmpty()){
                List<Opportunity> opptyrecords = [Select Id, Account.Id, Account.Name, Account.Segment__c, Account.Account_Lifecycle__c, Account.Main_Postal_Code__c, Account.Territory__r.Name from Opportunity where Id IN :tasksrelatedtooppty];
                if (!opptyrecords.isEmpty()){
                    Map<Id, Opportunity> mapaccountfromoppty = new Map<Id, Opportunity>();
                    for (Opportunity o : opptyrecords){
                        mapaccountfromoppty.put(o.Id, o);
                    }
                    for (Task t : tasks){
                        if (!mapaccountfromoppty.isEmpty()){
                            Opportunity opptyvalues = (Opportunity) mapaccountfromoppty.get(t.WhatId);
                            t.Account_Lifecycle_HANA__c = opptyvalues.Account.Account_Lifecycle__c;
                            t.Segment__c = opptyvalues.Account.Segment__c;
                            t.Account_Name__c = opptyvalues.Account.Name;
                            t.Account__c = opptyvalues.Account.Id;
                            //t.Main_Postal_Code__c = opptyvalues.Account.Main_Postal_Code__c;
                            t.Territory__c = opptyvalues.Account.Territory__r.Name;
                            //t.Subject = opptyvalues.Account.Name + ' ' + t.Touchpoint_Type__c + ' ' + monthName + ' ' + dateToday.year();
                        }
                    }
                }
            }
            
            if (!tasksrelatedtoaccloc.isEmpty()){
                List<Apttus_Config2__AccountLocation__c> acclocrecords = [Select Id, Apttus_Config2__AccountId__r.Id, Apttus_Config2__AccountId__r.Name, Apttus_Config2__AccountId__r.Segment__c, Apttus_Config2__AccountId__r.Account_Lifecycle__c, Apttus_Config2__AccountId__r.Main_Postal_Code__c, Apttus_Config2__AccountId__r.Territory__r.Name From Apttus_Config2__AccountLocation__c where Id IN : tasksrelatedtoaccloc];
                if (!acclocrecords.isEmpty()){
                    Map<Id, Apttus_Config2__AccountLocation__c> mapaccountfromaccloc = new Map<Id, Apttus_Config2__AccountLocation__c>();
                    for (Apttus_Config2__AccountLocation__c accloc : acclocrecords){
                        mapaccountfromaccloc.put(accloc.Id, accloc);
                    }
                    for (Task t : tasks){
                        if (!mapaccountfromaccloc.isEmpty()){
                            Apttus_Config2__AccountLocation__c accloc = (Apttus_Config2__AccountLocation__c) mapaccountfromaccloc.get(t.WhatId);
                            t.Account_Lifecycle_HANA__c = accloc.Apttus_Config2__AccountId__r.Account_Lifecycle__c;
                            t.Segment__c = accloc.Apttus_Config2__AccountId__r.Segment__c;
                            t.Account_Name__c = accloc.Apttus_Config2__AccountId__r.Name;
                            t.Account__c = accloc.Apttus_Config2__AccountId__r.Id;
                            //t.Main_Postal_Code__c = accloc.Apttus_Config2__AccountId__r.Main_Postal_Code__c;
                            t.Territory__c = accloc.Apttus_Config2__AccountId__r.Territory__r.Name;
                            
                        }
                    }
                }
            }
            
        
        return tasks;
        } catch(exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
            return null;
        }  
    }

    /*Karen Hung 19.8.2020 DOO-4804 
    * Method to execute logic from TS_Number of Activities process builder & TS_ModifyCountonCase flow
    */
    public static List<Task> updateCountOnCase(List<Task> tasks, Map<String,Integer> caseActivityMap){
        CustomLogging.push('updateCountOnCase', 'SM_TaskUtil');
        try{
            
            List<Task> updateTask = new List<Task>();
            List<Task> taskRecs = new List<Task>();

            //UPDATE Number_of_Open_Tasks__c ON CASE
            if(caseActivityMap != null){
                List<Case> casetoUpdate = [SELECT Id, Number_of_Open_Tasks__c FROM Case WHERE Id IN :caseActivityMap.keySet() AND Number_of_Open_Tasks__c >= 1];
                if(!casetoUpdate.isEmpty()){
                    for(Case eachCase : casetoUpdate){
                        eachCase.Number_of_Open_Tasks__c = eachCase.Number_of_Open_Tasks__c + caseActivityMap.get(eachCase.Id);
                    }
                    
                    //MUTING BEFORE CASE UPDATE
                    CaseTriggerHandler.IS_RETURN_NEEDED = true;
                    update casetoUpdate;
                }
            }
        
            if (!tasks.isEmpty()){
                taskRecs = [SELECT Id, IsRelatedToCase__c, Who.type, What.type, WhatId, WhoId FROM Task WHERE ID in :tasks];
                for(Task t : taskRecs){
                    if(t.IsRelatedToCase__c == false){
                        t.IsRelatedToCase__c = true;
                        updateTask.add(t);
                    }
                }
            }
            
            return updateTask;
        } catch (Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
            return null;
        }
    }
    
    public static void populateAccountAddress (List<Task> tasks){
        CustomLogging.push('populateAccountAddress', 'SM_TaskUtil');
        try{
            Set<Id> tasksrelatedtoacc = new Set<Id>();
            Set<Id> tasksrelatedtooppty = new Set<Id>();
            Set<Id> tasksrelatedtocase = new Set<Id>();
            Set<Id> tasksrelatedtolead = new Set<Id>();
            Set<Id> tasksrelatedtocon = new Set<Id>();
            
            if (!tasks.isEmpty()){
                for (Task t : tasks){
                    if (t.WhatId != Null) {
                        if (String.valueOf(t.WhatId).left(3) == SM_Constants.accountPrefix){
                            tasksrelatedtoacc.add(t.WhatId);
                        } else if (String.valueOf(t.WhatId).left(3) == SM_Constants.oppPrefix){
                            tasksrelatedtooppty.add(t.WhatId);
                        } else if (String.valueOf(t.WhatId).left(3) == SM_Constants.casePrefix) {
                            tasksrelatedtocase.add(t.WhatId);
                        }
                    } else if (t.WhoId != Null) {
                        if (String.valueOf(t.WhoId).left(3) == SM_Constants.leadPrefix){
                            tasksrelatedtolead.add(t.WhoId);
                        }
                        else if (String.valueOf(t.WhoId).left(3) == SM_Constants.contactPrefix){
                            tasksrelatedtocon.add(t.WhoId);
                        }
                    }
                    
                }
            }
            if (!tasksrelatedtoacc.isEmpty()){
                List<Account> accRecords = [SELECT Id, Main_Street__c, Main_Postal_Code__c, Main_City__c from Account WHERE Id IN :tasksrelatedtoacc];
                if (!accRecords.isEmpty()){
                    Map<Id, Account> mapAcc = new Map<Id, Account>();
                    for (Account a : accRecords){
                        for(Task t : tasks){
                           mapAcc.put(a.Id, a); 
                        }
                    }
                    if (!mapAcc.isEmpty()){
                    	for (Task t : tasks){
                            t.Account_Address__c = mapAcc.get(t.WhatId).Main_Postal_Code__c + ' ' + mapAcc.get(t.WhatId).Main_Street__c + ' ' + mapAcc.get(t.WhatId).Main_City__c;
                        }
                    }
                }
            }
            
            if (!tasksrelatedtooppty.isEmpty()){
                List<Opportunity> opptyrecords = [Select Id, Account.Id, Account.Main_Street__c, Account.Main_Postal_Code__c, Account.Main_City__c from Opportunity where Id IN :tasksrelatedtooppty];
                if (!opptyrecords.isEmpty()){
                    Map<Id, Opportunity> mapAccFromOpp = new Map<Id, Opportunity>();
                    for (Opportunity o : opptyrecords){
                        mapAccFromOpp.put(o.Id, o);
                    }
                    if (!mapAccFromOpp.isEmpty()){
                    	for (Task t : tasks){
                            t.Account_Address__c = mapAccFromOpp.get(t.WhatId).Account.Main_Postal_Code__c + ' ' + mapAccFromOpp.get(t.WhatId).Account.Main_Street__c + ' ' + mapAccFromOpp.get(t.WhatId).Account.Main_City__c;
                        }
                    }
                }
            }
            
            if (!tasksrelatedtocase.isEmpty()){
                List<Case> caseRecords = [Select Id, Account.Id, Account.Main_Street__c, Account.Main_Postal_Code__c, Account.Main_City__c from Case where Id IN :tasksrelatedtocase];
                if (!caseRecords.isEmpty()){
                    Map<Id, Case> mapAccFromCase = new Map<Id, Case>();
                    for (Case c : caseRecords){
                        mapAccFromCase.put(c.Id, c);
                    }
                    
                    if (!mapAccFromCase.isEmpty()){
                    	for (Task t : tasks){
                            t.Account_Address__c = mapAccFromCase.get(t.WhatId).Account.Main_Postal_Code__c + ' ' + mapAccFromCase.get(t.WhatId).Account.Main_Street__c + ' ' + mapAccFromCase.get(t.WhatId).Account.Main_City__c;
                        }
                    }
                }
            }
            
            if (!tasksrelatedtolead.isEmpty()){
                List<Lead> leadRecords = [Select Id, Main_Street__c, Main_Postal_Code__c, Main_City__c from Lead where Id IN :tasksrelatedtolead];
                if (!leadRecords.isEmpty()){
                    Map<Id, Lead> mapAcctFromLead = new Map<Id, Lead>();
                    for (Lead c : leadRecords){
                        mapAcctFromLead.put(c.Id, c);
                    }
                    
                    if (!mapAcctFromLead.isEmpty()){
                    	for (Task t : tasks){
                            t.Account_Address__c = mapAcctFromLead.get(t.WhoId).Main_Postal_Code__c + ' ' + mapAcctFromLead.get(t.WhoId).Main_Street__c + ' ' + mapAcctFromLead.get(t.WhoId).Main_City__c;
                        }
                    }
                }
            }
            
            if (!tasksrelatedtocon.isEmpty()){
                List<Contact> conRecords = [Select Id, Account.Id, Account.Main_Street__c, Account.Main_Postal_Code__c, Account.Main_City__c from Contact where Id IN :tasksrelatedtocon];
                if (!conRecords.isEmpty()){
                    Map<Id, Contact> mapAccFromCon = new Map<Id, Contact>();
                    for (Contact c : conRecords){
                        mapAccFromCon.put(c.Id, c);
                    }
                    
                    if (!mapAccFromCon.isEmpty()){
                    	for (Task t : tasks){
                            t.Account_Address__c = mapAccFromCon.get(t.WhoId).Account.Main_Postal_Code__c + ' ' + mapAccFromCon.get(t.WhoId).Account.Main_Street__c + ' ' + mapAccFromCon.get(t.WhoId).Account.Main_City__c;
                        }
                    }
                }
            }
            
        } catch(exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop(); 
    }
    
    public static void notifyHotLeadGroupfromTask (List<Task> tasks){
        CustomLogging.push('notifyHotLeadGroupfromTask', 'SM_TaskUtil');
        try{
            List<Lead> leadrecords = new List<Lead>();
            List<Account> accountrecords = new List<Account>();
            Map<Id,Id> mapleadtask = new Map<Id,Id>();
            Map<Id,Id> mapcontacttask = new Map<Id,Id>();
            Map<Id,Lead> mapleadmpcval = new Map<Id,Lead>();
            Map<Id,Account> mapaccountmpcval = new Map<Id,Account>();
            Set<Id> leadids = new Set<Id>();
            
            FeedItem post = new FeedItem();
            List<ConnectApi.BatchInput> batchInputs = new List<ConnectApi.BatchInput>();
            
            Map<String, Queue_Lead_Tasks__mdt> chatternotifvalues = SM_GetMetadata.getqueueleadtasks(); 
            for (Task t : tasks){
                if (string.valueOf(t.WhoId).left(3) == SM_Constants.leadPrefix){
                    mapleadtask.put(t.Id, t.WhoId);
                } else {
                    if (string.valueOf(t.WhoId).left(3) == SM_Constants.contactPrefix && string.valueOf(t.WhatId).left(3) == SM_Constants.accountPrefix){
                        mapcontacttask.put(t.Id, t.WhatId);
                    }
                }
            }
            if (!mapleadtask.isEmpty()){
                leadrecords = [Select Id, Main_Postal_Code__c, OwnerId from Lead where Id in: mapleadtask.values()];
                for (Lead l : leadrecords){
                     mapleadmpcval.put(l.Id, l);
                }
            } else {
                if (!mapcontacttask.isEmpty()){
                    accountrecords = [Select Id, Main_Postal_Code__c from Account where Id in: mapcontacttask.values()];
                }
                for (Account a : accountrecords){
                     mapaccountmpcval.put(a.Id, a);
                }
                
            }
           
            for (Task taskval : tasks){
                String mainpostalcodeval = null;
                String chattergroupId = null;
                Queue_Lead_Notification__c queuechattergroup = new Queue_Lead_Notification__c();
                if (string.valueOf(taskval.WhoId).left(3) == SM_Constants.leadPrefix){
                    queuechattergroup = Queue_Lead_Notification__c.getInstance(mapleadmpcval.get(mapleadtask.get(taskval.Id)).OwnerId);
                    mainpostalcodeval = mapleadmpcval.get(mapleadtask.get(taskval.Id)).Main_Postal_Code__c;
                    chattergroupId = queuechattergroup.Chatter_Group_ID__c;
                }
                else {
                    if (string.valueOf(taskval.WhoId).left(3) == SM_Constants.contactPrefix && string.valueOf(taskval.WhatId).left(3) == SM_Constants.accountPrefix){
                        mainpostalcodeval = mapaccountmpcval.get(mapcontacttask.get(taskval.Id)).Main_Postal_Code__c;
                        chattergroupId = chatternotifvalues.get(taskval.Sales_Organization__c + taskval.Touchpoint_Type__c).Chatter_Group_ID__c;
                    }
                }
                if (chattergroupId != null){
                    ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();            
                    ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();   
                    messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
                    
                    ConnectApi.TextSegmentInput textSegmentInput1 = new ConnectApi.TextSegmentInput();
                    textSegmentInput1.text = 'There is a new Task related to a Lead with Postal Code: ' + mainpostalcodeval + ' ';    
                    messageBodyInput.messageSegments.add(textSegmentInput1);
                    ConnectApi.EntityLinkSegmentInput entityLinkSegmentInputContact = new ConnectApi.EntityLinkSegmentInput();
                    entityLinkSegmentInputContact.entityId = taskval.Id;  
                    messageBodyInput.messageSegments.add(entityLinkSegmentInputContact);
                    ConnectApi.TextSegmentInput textSegmentInput2 = new ConnectApi.TextSegmentInput();
                    textSegmentInput2.text = ' available in the queue for task,' + ' ';     
                    messageBodyInput.messageSegments.add(textSegmentInput2);
                    ConnectApi.EntityLinkSegmentInput entityLinkSegmentInputOpportunity = new ConnectApi.EntityLinkSegmentInput();
                    entityLinkSegmentInputOpportunity.entityId = chattergroupId;  
                    messageBodyInput.messageSegments.add(entityLinkSegmentInputOpportunity); 
                    
                    feedItemInput.body = messageBodyInput;
                    feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
                    feedItemInput.subjectId = chattergroupId; 
                    
                    ConnectApi.BatchInput batchInput = new ConnectApi.BatchInput(feedItemInput);
                    batchInputs.add(batchInput);
                }
                
                
            }
            ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), batchInputs);
        } catch(exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop(); 
    }
    
    public static List<Task> stampTaskInProgressTimestamp(List<Task> tasks) {
        CustomLogging.push('stampTaskInProgressTimestamp', 'SM_TaskUtil');
        try {
            if (!tasks.isEmpty()){
                for (Task t: tasks){
                    if (t.Status == 'In Progress' || t.Status == 'Redial' || t.Status == 'Completed Effective' || t.Status == 'Completed Non-Effective'){
                        t.Task_In_Progress_Timestamp__c = System.now();
                    }
                }
            }
            return tasks;
        } catch (Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
            return null;
        }
    }
}