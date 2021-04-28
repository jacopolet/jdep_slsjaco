/*************************************************************
@Name: APTS_ComplianceTaskUtils
@Author: Shanmuga Prasath
@CreateDate: 04-11-2018
@Description: 
@Used By :  
******************************************************************/

public with sharing class APTS_ComplianceTaskUtils{
    
    public static final String AGREEMENTCOMPLIANCE = 'Agreement Compliance';
    public static final String APTTUS = 'APTTUS';
    public static final String BATCH = 'Batch';
    public static final String AGREEMENTOBJECT = 'Agreement';
    public static final String CLM = 'CLM';
    public static final String FIXEDTERMCHECK = 'FIXED TERM CHECK';
    public static final String FIXEDTERMSSETTL = 'FIXED TERMS SETTL';
    public static final String BUDGETCHECK = 'BUDGET CHECK';
    public static final String KPISLACHECK = 'KPI-SLA CHECK';
    public static final String KPISLASETTL = 'KPI-SLA SETTL';
    public static final String VOLUMEOBLIGCHECK = 'VOLUME OBLIG CHECK';
    public static final String VOLUMEOBLIGSETTL = 'VOLUME OBLIG SETTL';
    public static final String PONUMBERREQUEST = 'P.O. NUMBER REQUEST';
    public static final String ONETIMEBONUS = 'ONE-TIME BONUS';
    public static final String EMPTYSTRING = ' ';
    public static final String SLASH = '/';
    public static List<User> lstUsers = new List<User>();



    public static List<Task> createComplianceTaskForOneTime(Apttus__APTS_Agreement__c agreement, String touchPoint, String priority, Integer score, Date startDate, String status, String description, Internal_contract_compliance__c intConCom, Contact contactName) {
         try{        
            Task complianceTask = new Task();
            List<Task> complaianceTasksForOnetime = new List<Task>();
              List<APTS_OneTimeComplaince__mdt> CustomMetaData=[SELECT Role__c,User__c FROM APTS_OneTimeComplaince__mdt];
            if(CustomMetaData[0].Role__c != NULL)
            lstUsers = new List<User>([Select id from User where UserRole.Name=:CustomMetaData[0].Role__c]);
            if(CustomMetaData[0].User__c != NULL)
            {
            List<String> UserNames = CustomMetaData[0].User__c.split(';');
            lstUsers = new List<User>([Select id from User where Name=:UserNames]);
            }
            for(User instUser : lstUsers)
                {  
                    complianceTask = new Task();                    
                    //complianceTask.Subject = agreement.Apttus__Account__r.name +EMPTYSTRING+ touchPoint +EMPTYSTRING+Date.Today().month()+SLASH+Date.Today().year();
                    complianceTask.Subject = 'Call';
                    complianceTask.Priority = priority;
                    complianceTask.Type = AGREEMENTCOMPLIANCE;
                    complianceTask.Touchpoint_Type__c = touchPoint;
                    complianceTask.Task_Source__c = APTTUS;
                    complianceTask.WhatId = agreement.Id;
                    Id userId = getAssignedTo(intConCom, touchPoint);        
                   complianceTask.OwnerId = instUser.id;            
                    if(agreement.Apttus__Primary_Contact__c != null){
                        complianceTask.WhoId = agreement.Apttus__Primary_Contact__c;
                    }else if(contactName != null){
                        complianceTask.WhoId = contactName.Id;
                    }else{
                        complianceTask.WhoId = null;
                    }            
                    complianceTask.Priority_Score__c = score;
                    complianceTask.Start_DateCS__c = startDate;
                    //complianceTask.Due_Date__c = null;
                    complianceTask.Suggested_Completion_Date__c = null;
                    complianceTask.Task_Expiration_Date__c = null;
                    complianceTask.Status = status;
                    complianceTask.Reason__c = null;
                    complianceTask.Guidance__c = null;
                    complianceTask.Contract_Asset_Lifetime__c = null;
                    complianceTask.Contract_Asset_Expiration_Date__c = null;
                    complianceTask.Date_Time_Closed__c = null;
                    complianceTask.Segment__c = null;
                    complianceTask.Account_Lifecycle_HANA__c = null;
                    complianceTask.Description = description;
                    complianceTask.ActivityDate = null;
                    //complianceTask.ActivityDate= system.today();
                    complianceTask.Description__c = null; 
                    complianceTask.Status = Label.APTS_Open;
                    complianceTask.OTC_relevant_flag__c = true;
                    complaianceTasksForOnetime.add(complianceTask);
                    }   return complaianceTasksForOnetime;  

    }
    catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), BATCH, ex.getStackTraceString(), AGREEMENTOBJECT, null, CLM, false, false, null, true); return null;}
        
    }
    
    public static Task createComplianceTask(Apttus__APTS_Agreement__c agreement, String touchPoint, String priority, Integer score, Date startDate, String status, String description, Internal_contract_compliance__c intConCom, Contact contactName) {
        
        try{        
            Task complianceTask = new Task();
            //complianceTask.Subject = agreement.Apttus__Account__r.name +EMPTYSTRING+ touchPoint +EMPTYSTRING+Date.Today().month()+SLASH+Date.Today().year();
      complianceTask.Subject = 'Call';
            complianceTask.Priority = priority;
            complianceTask.Type = AGREEMENTCOMPLIANCE;
            complianceTask.Touchpoint_Type__c = touchPoint;
            complianceTask.Task_Source__c = APTTUS;
            complianceTask.WhatId = agreement.Id;
            Id userId = getAssignedTo(intConCom, touchPoint);
            if(intConCom != null && intConCom.APTS_Queue_Task__c == true){
                complianceTask.OwnerId = userId != null ? userId : agreement.OwnerId;
            }
            else{
                complianceTask.OwnerId = agreement.OwnerId;
            }
            
            if(agreement.Apttus__Primary_Contact__c != null){
                complianceTask.WhoId = agreement.Apttus__Primary_Contact__c;
            }else if(contactName != null){
                complianceTask.WhoId = contactName.Id;
            }else{
                complianceTask.WhoId = null;
            }
            
            complianceTask.Priority_Score__c = score;
            complianceTask.Start_DateCS__c = startDate;
            //complianceTask.Due_Date__c = null;
            complianceTask.Suggested_Completion_Date__c = null;
            complianceTask.Task_Expiration_Date__c = null;
            complianceTask.Status = status;
            complianceTask.Reason__c = null;
            complianceTask.Guidance__c = null;
            complianceTask.Contract_Asset_Lifetime__c = null;
            complianceTask.Contract_Asset_Expiration_Date__c = null;
            complianceTask.Date_Time_Closed__c = null;
            complianceTask.Segment__c = null;
            complianceTask.Account_Lifecycle_HANA__c = null;
            complianceTask.Description = description;
            complianceTask.ActivityDate = null;
            //complianceTask.ActivityDate= system.today();
            complianceTask.Description__c = null; 
            complianceTask.Status = Label.APTS_Open;
      complianceTask.OTC_relevant_flag__c = true;
            return complianceTask;
        }catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), BATCH, ex.getStackTraceString(), AGREEMENTOBJECT, null, CLM, false, false, null, true); return null;}
        
    }
    
    public static ID getAssignedTo(Internal_contract_compliance__c intConCom, String touchPoint){
        try{
            Id userId;
            if(intConCom != null){
                if(FIXEDTERMCHECK.equalsIgnoreCase(touchPoint) && intConCom.Fixed_Terms_internal_task_user__c != null){
                    userId = intConCom.Fixed_Terms_internal_task_user__c;
                }
                else if(FIXEDTERMSSETTL.equalsIgnoreCase(touchPoint) && intConCom.Fixed_Terms_Settlement_task_User__c != null){
                    userId = intConCom.Fixed_Terms_Settlement_task_User__c;
                }
                else if(BUDGETCHECK.equalsIgnoreCase(touchPoint) && intConCom.Budget_internal_task_User__c != null){
                    userId = intConCom.Budget_internal_task_User__c;
                }
                else if(KPISLACHECK.equalsIgnoreCase(touchPoint) && intConCom.KPI_SLA_internal_task_User__c != null){
                    userId = intConCom.KPI_SLA_internal_task_User__c;
                }
                else if(KPISLASETTL.equalsIgnoreCase(touchPoint) && intConCom.KPI_SLA_Settlement_task_User__c != null){
                    userId = intConCom.KPI_SLA_internal_task_User__c;
                }
                else if(VOLUMEOBLIGCHECK.equalsIgnoreCase(touchPoint) && intConCom.Volume_Obligation_internal_task_User__c != null){
                    userId = intConCom.KPI_SLA_internal_task_User__c;
                }
                else if(VOLUMEOBLIGSETTL.equalsIgnoreCase(touchPoint) && intConCom.Volume_Obligation_Settlement_task_User__c != null){
                    userId = intConCom.Volume_Obligation_Settlement_task_User__c;
                }
                else if(PONUMBERREQUEST.equalsIgnoreCase(touchPoint) && intConCom.PO_Number_internal_task_User__c != null){
                    userId = intConCom.PO_Number_internal_task_User__c;
                }
                else if(ONETIMEBONUS.equalsIgnoreCase(touchPoint) && intConCom.One_time_Bonus_internal_task_User__c != null){
                    userId = intConCom.One_time_Bonus_internal_task_User__c ;
                }
            }
            return userId; 
        }catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), BATCH, ex.getStackTraceString(), AGREEMENTOBJECT, null, CLM, false, false, null, true);return null;} 
    }

}