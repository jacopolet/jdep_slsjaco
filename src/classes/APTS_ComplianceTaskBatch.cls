/*************************************************************
@Name: APTS_ComplianceTaskBatch
@Author: Shanmuga Prasath
@CreateDate: 04-11-2018
@Description: This batch is for compliance task 
@Note for testing: Update the Custom Label APTS_ComplianceTaskBatchTest to 'true' for testing all the scenario else keep it as 'false'.
@Used By :  
***************************************************************/ 
global class APTS_ComplianceTaskBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {

    private String query;
    
    //Update the Custom Label APTS_ComplianceTaskBatchTest to 'true' for testing else keep it as 'false'.
    @TestVisible private static Integer todayDate = Label.APTS_ComplianceTaskBatchTest == 'true' ? 1 : Date.Today().day();
    //@TestVisible private static Integer todayDate = 1;
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        query = 'SELECT Id, OwnerId, APTS_Fixed_Term_Type__c, APTS_Country__c, Apttus__Contract_Start_Date__c, Apttus__FF_Agreement_Number__c,'+
                'Apttus__Status__c, Apttus__Status_Category__c, Apttus__Primary_Contact__c, APTS_Fixed_Term_Startdate__c, Apttus__Contract_End_Date__c,'+
                'Fixed_Terms_Internal_Freq__c, kpi_internal_freq__c,volume_obligation_internal_freq__c, Apttus__Account__c, Apttus__Account__r.Name,'+
                'APTS_Fixed_Term_Frequency__c, budget_internal_freq__c, volume_obligation_internal_triggerpoint__c FROM Apttus__APTS_Agreement__c '+
                'WHERE Apttus__Status_Category__c = \'In Effect\''+
                'OR Apttus__Status__c = \'Activated\''+
                'OR Apttus__Status_Category__c = \'Terminated\''+
                'OR Apttus__Status_Category__c = \'Expired\'';
        return Database.getQueryLocator(query);
     }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        
        Date DateToCompareTest;
        final String INEFFECT = 'In Effect';
        final String ACTIVATED = 'Activated';
        final String FIXED = 'Fixed';
        final String SATURDAY = 'Saturday';
        final String SUNDAY = 'Sunday';
        final String TERMINATED = 'Terminated';
        final String LINEFEED = '\n';
        final String EXPIRED = 'Expired';
        final String MONTHLY = 'Monthly';
        final String QUARTERLY = 'Quarterly';
        final String HALFYEARLY = 'Half Yearly';
        final String YEARLY = 'Yearly';
        final String FIXEDTERMCHECK = 'FIXED TERM CHECK';
        final String FIXEDTERMINTFREQ1 = 'Periodic evaluation needed for actual vs fixed amount for contract';
        final String FIXEDTERMINTFREQ2 = ', acquire fixed term report';
        final String FIXEDTERMSETTLFREQ1 = 'Periodic evaluation needed for actual vs fixed amount for contract';
        final String FIXEDTERMSETTLFREQ2 = ', acquire fixed term report,';
        final String FIXEDTERMSETTLFREQ3 = '-CMR/DMR creation';
        final String FIXEDTERMSSETTL = 'FIXED TERMS SETTL';
        final String BUDGETINTFREQ1 = '-Check budget';
        final String BUDGETCHECK = 'BUDGET CHECK';
        final String SLASH = '/';
        final String KPISLAFREQ1 = '- Check contracted KPI\'s/ SLA\'s';
        final String KPISLAFREQ2 = '- Check customer reports which contains the KPI\'s/ SLA\'s';
        final String KPISLAFREQ3 = 'information.';
        final String KPISLAFREQ4 = '- Compare both values';
        final String KPISLAFREQ5 = '- Check whether action is needed ';
        final String KPISLACHECK = 'KPI-SLA CHECK';
        final String KPISLASETTLE = 'KPI-SLA SETTL';
        final String VOLOBLIINTFREQ1 = '- Expected volume ordered: ';
        final String VOLOBLIINTFREQ2 = '- Actual volume ordered: ';
        final String VOLOBLIINTFREQ3 = 'consequence at end of year: ';
        final String VOLUMEOBLIGCHECK = 'VOLUME OBLIG CHECK';
        final String VOLOBLISETTLEFREQ1 = '- Contracted volume obligation: ';
        final String VOLOBLISETTLEFREQ2 = '- Contracted action needed: ';
        final String VOLOBLISETTLEFREQ3 = '- (in case of "Invoice customer") Estimated Malus: ';
        final String VOLUMEOBLIGSETTL = 'VOLUME OBLIG SETTL';
        final String PONUMFREQ1 = '- Contact';
        final String PONUMFREQ2 = 'for new PO Number.';
        final String PONUMFREQ3 = 'Update PO Number in';
        final String PONUMFREQ4 = '- Experation date of current PO number: ';
        final String PONUMREQ = 'P.O. NUMBER REQUEST';
        final String BATCH = 'Batch';
        final String AGREEMENT = 'Agreement';
        final String CLM = 'CLM';
    
        DateTime myDateTime = (DateTime) system.today();
        String dayOfWeek = myDateTime.format('EEEEE');
        Date tdy;
        Map<String,Internal_contract_compliance__c> intConComMap = new Map<String,Internal_contract_compliance__c>();
        for(Internal_contract_compliance__c intCom: [Select Id, Name, budget_internal_freq__c, Budget_internal_task_User__c, Contracted_Indexation_task_User__c, Country__c, fixed_terms_internal_freq__c, Fixed_Terms_internal_task_user__c, Fixed_Terms_Settlement_task_User__c, 
                                                          kpi_internal_freq__c, KPI_SLA_internal_task_User__c, KPI_SLA_Settlement_task_User__c,
                                                          volume_obligation_internal_freq__c, Volume_Obligation_internal_task_User__c, volume_obligation_internal_triggerpoint__c, Volume_Obligation_Settlement_task_User__c, One_time_Bonus_internal_task_User__c, OwnerId, 
                                                          PO_Number_internal_task_User__c, Standard_Indexation_queue_user__c, APTS_Queue_Task__c FROM Internal_contract_compliance__c 
                                                          LIMIT 50000 ])
                                                          {intConComMap.put(intCom.Country__c,intCom);
                                                          }
        
        Map<Id,Contact> contactMap = new Map<Id,Contact>();
        for(Contact accountContact: [SELECT Id, Name, Account.Name, AccountId, Main_Commercial_Person__c 
                                     FROM Contact 
                                     WHERE Main_Commercial_Person__c = true LIMIT 50000])
        {
            contactMap.put(accountContact.AccountId, accountContact);
        }
        List<Apttus__APTS_Agreement__c> listAgreements = (List<Apttus__APTS_Agreement__c>) scope;

        List<APTS_Agreement_Budget__c> agreementBudgetList = [SELECT Id, APTS_Category__c, APTS_Subcategory__c,APTS_Start_Date__c,APTS_End_Date__c, APTS_Frequency__c FROM APTS_Agreement_Budget__c where Agreement__c IN: listAgreements];
        List<Contracted_kpi_sla__c> contractedKPISLAList = [SELECT Id, Name,kpi_contract__c,kpi_frequency__c  From Contracted_kpi_sla__c where kpi_contract__c IN: listAgreements];
        List<APTS_AgreementTotalVolumeObligation__c> agreementTotalVolumeObligationList = [SELECT Id, Name, APTS_Agreement__c, APTS_Action__c From APTS_AgreementTotalVolumeObligation__c where APTS_Agreement__c IN: listAgreements];
        List<APTS_AgreementVolumeObligation__c> agreementVolumeObligationList = [SELECT Id, Name, APTS_Agreement__c, APTS_Start_Date__c, APTS_End_Date__c, APTS_Ordered_Quantity__c, APTS_Volume_Obligation__c, APTS_Agreement_Total_Volume_Obligation__c, APTS_Agreement_Total_Volume_Obligation__r.APTS_Action__c, APTS_Malus__c From APTS_AgreementVolumeObligation__c where APTS_Agreement__c IN: listAgreements];
        List<APTS_Agreement_PO_Details__c> agreementPODetailsList = [SELECT Id, Name, APTS_Agreement__c, APTS_PO_Number_Required__c, APTS_PO_Expiration_Date__c, APTS_PO_Number_Type__c FROM APTS_Agreement_PO_Details__c where APTS_Agreement__c IN: listAgreements];
        List<Apttus_Rebate__AgreementPayoutSchedule__c> agreementPayoutScheduleList = [SELECT Id, Name, Apttus_Rebate__AgreementId__c FROM Apttus_Rebate__AgreementPayoutSchedule__c WHERE Apttus_Rebate__AgreementId__c != null AND Apttus_Rebate__AgreementId__c IN: listAgreements];


        List<Task> taskList = new List<Task>();   
        if(dayOfWeek == SATURDAY)
        {tdy = system.today() + 2;
        }
        else if(dayOfWeek == SUNDAY)
        {tdy = system.today() + 1;
        }
        else{
        tdy = system.today();
        }
        if(listAgreements != null && listAgreements.size() > 0){
            for(Apttus__APTS_Agreement__c aggr: listAgreements){
             system.debug('First If'+aggr);   
            Boolean bActivatedagree = aggr.Apttus__Status_Category__c == INEFFECT;
            Boolean bTerminatedagree = aggr.Apttus__Status_Category__c == TERMINATED;
            Boolean bExpiredagree = aggr.Apttus__Status_Category__c == EXPIRED;
            /**Creating the compliance task for the Fixed Term Internal Frequency**/
            if(aggr.Fixed_Terms_Internal_Freq__c != null && aggr.APTS_Fixed_Term_Type__c != null && bActivatedagree && aggr.Apttus__Contract_Start_Date__c != null){
                system.debug('inside internal Fixed if'+aggr.Fixed_Terms_Internal_Freq__c);
                /**Monthly**/
                String description = FIXEDTERMINTFREQ1+aggr.Apttus__FF_Agreement_Number__c+FIXEDTERMINTFREQ2;
                if(aggr.Fixed_Terms_Internal_Freq__c == MONTHLY && Integer.valueOf(todayDate)-1 == 0  )
                {
                    Task exTask = APTS_ComplianceTaskUtils.createComplianceTask(aggr, FIXEDTERMCHECK, Label.APTS_Medium, 50, tdy+1 , Label.APTS_Open, description, intConComMap.get(aggr.APTS_Country__c), contactMap.get(aggr.Apttus__Account__c));
                    taskList.add(exTask);
                }
                /**Quarterly**/
                if(aggr.Fixed_Terms_Internal_Freq__c == QUARTERLY  && Integer.valueOf(todayDate)-1 == 0  )
                {   system.debug('inside internal Fixed if'+aggr.Fixed_Terms_Internal_Freq__c);
                    /**First Quarter**/
                    if((Integer.valueOf(aggr.Apttus__Contract_Start_Date__c.month()) + 3) == Integer.valueOf(System.Today().month()))
                    {
                   system.debug('inside internal Fixed if'+aggr.Apttus__Contract_Start_Date__c);
                    Task exTask = APTS_ComplianceTaskUtils.createComplianceTask(aggr, FIXEDTERMCHECK, Label.APTS_Medium, 50, tdy+1, Label.APTS_Open, description, intConComMap.get(aggr.APTS_Country__c), contactMap.get(aggr.Apttus__Account__c));
                    taskList.add(exTask);
                    }
                    /**Second Quarter**/
                    else if((Integer.valueOf(aggr.Apttus__Contract_Start_Date__c.month()) + 6) == Integer.valueOf(System.Today().month()))
                    {
                    Task exTask = APTS_ComplianceTaskUtils.createComplianceTask(aggr, FIXEDTERMCHECK, Label.APTS_Medium, 50, tdy+1, Label.APTS_Open, description, intConComMap.get(aggr.APTS_Country__c), contactMap.get(aggr.Apttus__Account__c));
                    taskList.add(exTask);
                    }
                    /**Third Quarter**/
                    else if((Integer.valueOf(aggr.Apttus__Contract_Start_Date__c.month()) + 9) == Integer.valueOf(System.Today().month()))
                    {
                    Task exTask = APTS_ComplianceTaskUtils.createComplianceTask(aggr, FIXEDTERMCHECK, Label.APTS_Medium, 50, tdy+1, Label.APTS_Open, description, intConComMap.get(aggr.APTS_Country__c), contactMap.get(aggr.Apttus__Account__c));
                    taskList.add(exTask);  
                    }
                    /**Fourth Quarter**/
                    else if(aggr.Apttus__Contract_Start_Date__c.month() == System.Today().month() && aggr.Apttus__Contract_Start_Date__c != System.Today())
                    {
                    Task exTask = APTS_ComplianceTaskUtils.createComplianceTask(aggr, FIXEDTERMCHECK, Label.APTS_Medium, 50, tdy+1, Label.APTS_Open, description, intConComMap.get(aggr.APTS_Country__c), contactMap.get(aggr.Apttus__Account__c));
                    taskList.add(exTask);
                    }
                } 
                /**Half Yearly**/
               if(aggr.Fixed_Terms_Internal_Freq__c == HALFYEARLY && ((Integer.valueOf(aggr.Apttus__Contract_Start_Date__c.month()) + 6) == Integer.valueOf(System.Today().month()) || aggr.Apttus__Contract_Start_Date__c.month() == System.Today().month())
                       && aggr.Apttus__Contract_Start_Date__c != System.Today()  && Integer.valueOf(todayDate)-1 == 0  )
                {   
                    Task exTask = APTS_ComplianceTaskUtils.createComplianceTask(aggr, FIXEDTERMCHECK, Label.APTS_Medium, 50, tdy+1, Label.APTS_Open, description, intConComMap.get(aggr.APTS_Country__c), contactMap.get(aggr.Apttus__Account__c));
                    taskList.add(exTask);
                 } 
            }
            
            /**Creating the compliance task for the Fixed Term Settlement Frequency**/
            if(aggr.APTS_Fixed_Term_Frequency__c != null && aggr.APTS_Fixed_Term_Type__c != null && bActivatedagree && aggr.APTS_Fixed_Term_Startdate__c != null)
            { 
                String description = FIXEDTERMSETTLFREQ1+aggr.Apttus__FF_Agreement_Number__c+FIXEDTERMSETTLFREQ2+ LINEFEED +FIXEDTERMSETTLFREQ3;
               /**Quarterly**/
               if(aggr.APTS_Fixed_Term_Frequency__c == QUARTERLY  && Integer.valueOf(todayDate)-1 == 0 )
                {   
                    /**First Quarter**/
                    if((Integer.valueOf(aggr.APTS_Fixed_Term_Startdate__c.month()) + 3) == Integer.valueOf(System.Today().month()))
                    {
                    Task exTask = APTS_ComplianceTaskUtils.createComplianceTask(aggr, FIXEDTERMSSETTL, Label.APTS_High, 80, tdy+1, Label.APTS_Open, description, intConComMap.get(aggr.APTS_Country__c), contactMap.get(aggr.Apttus__Account__c));
                    taskList.add(exTask);
                    }
                    /**Second Quarter**/
                    else if((Integer.valueOf(aggr.APTS_Fixed_Term_Startdate__c.month()) + 6) == Integer.valueOf(System.Today().month()))
                    {
                    Task exTask = APTS_ComplianceTaskUtils.createComplianceTask(aggr, FIXEDTERMSSETTL, Label.APTS_High, 80, tdy+1, Label.APTS_Open, description, intConComMap.get(aggr.APTS_Country__c), contactMap.get(aggr.Apttus__Account__c));
                    taskList.add(exTask);
                    }
                    /**Third Quarter**/
                    else if((Integer.valueOf(aggr.APTS_Fixed_Term_Startdate__c.month()) + 9) == Integer.valueOf(System.Today().month()))
                    {
                    Task exTask = APTS_ComplianceTaskUtils.createComplianceTask(aggr, FIXEDTERMSSETTL, Label.APTS_High, 80, tdy+1, Label.APTS_Open, description, intConComMap.get(aggr.APTS_Country__c), contactMap.get(aggr.Apttus__Account__c));
                    taskList.add(exTask);  
                    }
                    /**Fourth Quarter**/
                    else if(aggr.APTS_Fixed_Term_Startdate__c.month() == System.Today().month() && aggr.APTS_Fixed_Term_Startdate__c != System.Today())
                    {
                    Task exTask = APTS_ComplianceTaskUtils.createComplianceTask(aggr, FIXEDTERMSSETTL, Label.APTS_High, 80, tdy+1, Label.APTS_Open, description, intConComMap.get(aggr.APTS_Country__c), contactMap.get(aggr.Apttus__Account__c));
                    taskList.add(exTask);
                    }
                } 
                /**Half Yearly**/
                if(aggr.APTS_Fixed_Term_Frequency__c == HALFYEARLY && ((Integer.valueOf(aggr.APTS_Fixed_Term_Startdate__c.month()) + 6) == Integer.valueOf(System.Today().month()) || aggr.APTS_Fixed_Term_Startdate__c.month() == System.Today().month())
                       && aggr.APTS_Fixed_Term_Startdate__c != System.Today()  && Integer.valueOf(todayDate)-1 == 0 )
                {   
                    Task exTask = APTS_ComplianceTaskUtils.createComplianceTask(aggr, FIXEDTERMSSETTL, Label.APTS_High, 80, tdy+1, Label.APTS_Open, description, intConComMap.get(aggr.APTS_Country__c), contactMap.get(aggr.Apttus__Account__c));
                    taskList.add(exTask);
                 } 
                 /**Yearly**/
                 if(aggr.APTS_Fixed_Term_Frequency__c == YEARLY && aggr.APTS_Fixed_Term_Startdate__c.month() == System.Today().month() && aggr.APTS_Fixed_Term_Startdate__c != System.Today()  && Integer.valueOf(todayDate)-1 == 0 )
                {   
                    Task exTask = APTS_ComplianceTaskUtils.createComplianceTask(aggr, FIXEDTERMSSETTL, Label.APTS_High, 80, tdy+1, Label.APTS_Open, description, intConComMap.get(aggr.APTS_Country__c), contactMap.get(aggr.Apttus__Account__c));
                    taskList.add(exTask);
                 } 
            }
            
            /**Creating Compliance task for the Budget Internal Frequency **/
            if(agreementBudgetList.size() > 0 && aggr.budget_internal_freq__c != null && bActivatedagree && aggr.Apttus__Contract_Start_Date__c != null){
                for(APTS_Agreement_Budget__c agrBud : agreementBudgetList){
                String description = BUDGETINTFREQ1+ LINEFEED + URL.getSalesforceBaseUrl().toExternalForm() +SLASH + agrBud.Id ;
                 /**Monthly**/
                 if(aggr.budget_internal_freq__c == MONTHLY && Integer.valueOf(todayDate)-1 == 0 && agrBud.APTS_Start_Date__c < System.Today() && agrBud.APTS_End_Date__c > System.Today() && agrBud.APTS_Start_Date__c != null && agrBud.APTS_End_Date__c != null)
                {    
                    Task exTask = APTS_ComplianceTaskUtils.createComplianceTask(aggr, BUDGETCHECK, Label.APTS_Medium, 50, tdy+1, Label.APTS_Open, description, intConComMap.get(aggr.APTS_Country__c), contactMap.get(aggr.Apttus__Account__c));
                    taskList.add(exTask);
                }
                /**Quarterly**/
                if(aggr.budget_internal_freq__c == QUARTERLY  && Integer.valueOf(todayDate)-1 == 0  && agrBud.APTS_Start_Date__c < System.Today() && agrBud.APTS_End_Date__c > System.Today() && agrBud.APTS_Start_Date__c != null && agrBud.APTS_End_Date__c != null)
                {   
                    /**First Quarter**/
                    if((Integer.valueOf(aggr.Apttus__Contract_Start_Date__c.month()) + 3) == Integer.valueOf(System.Today().month()))
                    {
                    Task exTask = APTS_ComplianceTaskUtils.createComplianceTask(aggr, BUDGETCHECK, Label.APTS_Medium, 50, tdy+1, Label.APTS_Open, description, intConComMap.get(aggr.APTS_Country__c), contactMap.get(aggr.Apttus__Account__c));
                    taskList.add(exTask);
                    }
                    /**Second Quarter**/
                    else if((Integer.valueOf(aggr.Apttus__Contract_Start_Date__c.month()) + 6) == Integer.valueOf(System.Today().month()))
                    {
                    Task exTask = APTS_ComplianceTaskUtils.createComplianceTask(aggr, BUDGETCHECK, Label.APTS_Medium, 50, tdy+1, Label.APTS_Open, description, intConComMap.get(aggr.APTS_Country__c), contactMap.get(aggr.Apttus__Account__c));
                    taskList.add(exTask);
                    }
                    /**Third Quarter**/
                    else if((Integer.valueOf(aggr.Apttus__Contract_Start_Date__c.month()) + 9) == Integer.valueOf(System.Today().month()))
                    {
                    Task exTask = APTS_ComplianceTaskUtils.createComplianceTask(aggr, BUDGETCHECK, Label.APTS_Medium, 50, tdy+1, Label.APTS_Open, description, intConComMap.get(aggr.APTS_Country__c), contactMap.get(aggr.Apttus__Account__c));
                    taskList.add(exTask);  
                    }
                    /**Fourth Quarter**/
                    else if(aggr.Apttus__Contract_Start_Date__c.month() == System.Today().month() && aggr.Apttus__Contract_Start_Date__c != System.Today())
                    {
                    Task exTask = APTS_ComplianceTaskUtils.createComplianceTask(aggr, BUDGETCHECK, Label.APTS_Medium, 50, tdy+1, Label.APTS_Open, description, intConComMap.get(aggr.APTS_Country__c), contactMap.get(aggr.Apttus__Account__c));
                    taskList.add(exTask);
                    }
                } 
                 /**Half Yearly**/
               if(aggr.budget_internal_freq__c == HALFYEARLY && ((Integer.valueOf(aggr.Apttus__Contract_Start_Date__c.month()) + 6) == Integer.valueOf(System.Today().month()) || aggr.Apttus__Contract_Start_Date__c.month() == System.Today().month())
                       && aggr.Apttus__Contract_Start_Date__c != System.Today()  && Integer.valueOf(todayDate)-1 == 0  && agrBud.APTS_Start_Date__c < System.Today() && agrBud.APTS_End_Date__c > System.Today() && agrBud.APTS_Start_Date__c != null && agrBud.APTS_End_Date__c != null)
                {   
                    Task exTask = APTS_ComplianceTaskUtils.createComplianceTask(aggr, BUDGETCHECK, Label.APTS_Medium, 50, tdy+1, Label.APTS_Open, description, intConComMap.get(aggr.APTS_Country__c), contactMap.get(aggr.Apttus__Account__c));
                    taskList.add(exTask);
            } }
            }
           
            /**Creating the Internal Compliance task for KPI/SLA**/
             if(contractedKPISLAList.size() > 0 && aggr.kpi_internal_freq__c != null && bActivatedagree && aggr.Apttus__Contract_End_Date__c != null && aggr.Apttus__Contract_Start_Date__c != null)
             {for(Contracted_kpi_sla__c kpiSLA : contractedKPISLAList){
             String description = KPISLAFREQ1+ LINEFEED+ KPISLAFREQ2+ KPISLAFREQ3+ LINEFEED +KPISLAFREQ4 + LINEFEED +KPISLAFREQ5+ LINEFEED + URL.getSalesforceBaseUrl().toExternalForm() +SLASH + kpiSLA.Id;
                /**Monthly**/
                if(aggr.kpi_internal_freq__c == MONTHLY && ((Integer.valueOf(date.today().adddays(7).day()) == 1)||(aggr.Apttus__Contract_End_Date__c == System.Today()+7)))
                {
                    Task exTask = APTS_ComplianceTaskUtils.createComplianceTask(aggr, KPISLACHECK, Label.APTS_Medium, 50, tdy+1, Label.APTS_Open, description, intConComMap.get(aggr.APTS_Country__c), contactMap.get(aggr.Apttus__Account__c));
                    taskList.add(exTask);
                }
                /**Quarterly**/
                if(aggr.kpi_internal_freq__c == QUARTERLY  && ((Integer.valueOf(date.today().adddays(7).day()) == 1)||(aggr.Apttus__Contract_End_Date__c == System.Today()+7)))
                {  
                    /**First Quarter**/
                    if(Integer.valueOf(aggr.Apttus__Contract_Start_Date__c.month()) == 2)
                    {
                    Task exTask = APTS_ComplianceTaskUtils.createComplianceTask(aggr, KPISLACHECK, Label.APTS_Medium, 50, tdy+1, Label.APTS_Open, description, intConComMap.get(aggr.APTS_Country__c), contactMap.get(aggr.Apttus__Account__c));
                    taskList.add(exTask);
                    }
                    /**Second Quarter**/
                    else if(Integer.valueOf(aggr.Apttus__Contract_Start_Date__c.month()) == 5)
                    {
                    Task exTask = APTS_ComplianceTaskUtils.createComplianceTask(aggr, KPISLACHECK, Label.APTS_Medium, 50, tdy+1, Label.APTS_Open, description, intConComMap.get(aggr.APTS_Country__c), contactMap.get(aggr.Apttus__Account__c));
                    taskList.add(exTask);
                    }
                    /**Third Quarter**/
                    else if(Integer.valueOf(aggr.Apttus__Contract_Start_Date__c.month()) == 8)
                    {
                    Task exTask = APTS_ComplianceTaskUtils.createComplianceTask(aggr, KPISLACHECK, Label.APTS_Medium, 50, tdy+1, Label.APTS_Open, description, intConComMap.get(aggr.APTS_Country__c), contactMap.get(aggr.Apttus__Account__c));
                    taskList.add(exTask);
                    }
                    /**Fourth Quarter**/
                    else if(Integer.valueOf(aggr.Apttus__Contract_Start_Date__c.month()) == 11)
                    {
                    Task exTask = APTS_ComplianceTaskUtils.createComplianceTask(aggr, KPISLACHECK, Label.APTS_Medium, 50, tdy+1, Label.APTS_Open, description, intConComMap.get(aggr.APTS_Country__c), contactMap.get(aggr.Apttus__Account__c));
                    taskList.add(exTask);
                    }
                } 
                /**Half Yearly**/
               if(aggr.kpi_internal_freq__c == HALFYEARLY && ((Integer.valueOf(aggr.Apttus__Contract_Start_Date__c.month()) == 5) || (Integer.valueOf(aggr.Apttus__Contract_Start_Date__c.month()) == 11)) && aggr.Apttus__Contract_Start_Date__c != System.Today()  && ((Integer.valueOf(date.today().adddays(7).day()) == 1) || (aggr.Apttus__Contract_End_Date__c == System.Today()+7)) )
                {   
                    Task exTask = APTS_ComplianceTaskUtils.createComplianceTask(aggr, KPISLACHECK, Label.APTS_Medium, 50, tdy+1, Label.APTS_Open, description, intConComMap.get(aggr.APTS_Country__c), contactMap.get(aggr.Apttus__Account__c));
                    taskList.add(exTask);
                 } 
            
}}

             /**Creating the Settlement Compliance task for KPI/SLA**/
             if(contractedKPISLAList.size() > 0 && bActivatedagree && aggr.Apttus__Contract_Start_Date__c != null && aggr.Apttus__Contract_End_Date__c != null)
             {for(Contracted_kpi_sla__c kpiSLA : contractedKPISLAList){
             String description = KPISLAFREQ1+ LINEFEED+ KPISLAFREQ2+ KPISLAFREQ3+ LINEFEED +KPISLAFREQ4 + LINEFEED +KPISLAFREQ5+ LINEFEED + URL.getSalesforceBaseUrl().toExternalForm() +SLASH + kpiSLA.Id;
                /**Monthly**/
                if(kpiSLA.kpi_frequency__c == MONTHLY && ((Integer.valueOf(date.today().adddays(7).day()) == 1)||(aggr.Apttus__Contract_End_Date__c == System.Today()+7)) && kpiSLA.kpi_frequency__c != null)
                {
                    Task exTask = APTS_ComplianceTaskUtils.createComplianceTask(aggr, KPISLASETTLE, Label.APTS_Medium, 50, tdy+1, Label.APTS_Open, description, intConComMap.get(aggr.APTS_Country__c), contactMap.get(aggr.Apttus__Account__c));
                    taskList.add(exTask);
                }
                /**Quarterly**/
                if(kpiSLA.kpi_frequency__c == QUARTERLY  && ((Integer.valueOf(date.today().adddays(7).day()) == 1)||(aggr.Apttus__Contract_End_Date__c == System.Today()+7)) && kpiSLA.kpi_frequency__c != null)
                {   
                    /**First Quarter**/
                    if(Integer.valueOf(aggr.Apttus__Contract_Start_Date__c.month()) == 2)
                    {
                    Task exTask = APTS_ComplianceTaskUtils.createComplianceTask(aggr, KPISLASETTLE, Label.APTS_Medium, 50, tdy+1, Label.APTS_Open, description, intConComMap.get(aggr.APTS_Country__c), contactMap.get(aggr.Apttus__Account__c));
                    taskList.add(exTask);
                    }
                    /**Second Quarter**/
                    else if(Integer.valueOf(aggr.Apttus__Contract_Start_Date__c.month()) == 5)
                    {
                    Task exTask = APTS_ComplianceTaskUtils.createComplianceTask(aggr, KPISLASETTLE, Label.APTS_Medium, 50, tdy+1, Label.APTS_Open, description, intConComMap.get(aggr.APTS_Country__c), contactMap.get(aggr.Apttus__Account__c));
                    taskList.add(exTask);
                    }
                    /**Third Quarter**/
                    else if(Integer.valueOf(aggr.Apttus__Contract_Start_Date__c.month()) == 8)
                    {
                    Task exTask = APTS_ComplianceTaskUtils.createComplianceTask(aggr, KPISLASETTLE, Label.APTS_Medium, 50, tdy+1, Label.APTS_Open, description, intConComMap.get(aggr.APTS_Country__c), contactMap.get(aggr.Apttus__Account__c));
                    taskList.add(exTask);
                    }
                    /**Fourth Quarter**/
                    else if(Integer.valueOf(aggr.Apttus__Contract_Start_Date__c.month()) == 11)
                    {
                    Task exTask = APTS_ComplianceTaskUtils.createComplianceTask(aggr, KPISLASETTLE, Label.APTS_Medium, 50, tdy+1, Label.APTS_Open, description, intConComMap.get(aggr.APTS_Country__c), contactMap.get(aggr.Apttus__Account__c));
                    taskList.add(exTask);
                    }
                } 
                /**Half Yearly**/
               if(kpiSLA.kpi_frequency__c == 'Half-Yearly' && ((Integer.valueOf(aggr.Apttus__Contract_Start_Date__c.month()) == 5) || (Integer.valueOf(aggr.Apttus__Contract_Start_Date__c.month()) == 11)) && aggr.Apttus__Contract_Start_Date__c != System.Today()  && ((Integer.valueOf(date.today().adddays(7).day()) == 1)||(aggr.Apttus__Contract_End_Date__c == System.Today()+7)) && kpiSLA.kpi_frequency__c != null)
                {   
                    Task exTask = APTS_ComplianceTaskUtils.createComplianceTask(aggr, KPISLASETTLE, Label.APTS_Medium, 50, tdy+1, Label.APTS_Open, description, intConComMap.get(aggr.APTS_Country__c), contactMap.get(aggr.Apttus__Account__c));
                    taskList.add(exTask);
                 } 
                 /**Yearly**/
                 if(kpiSLA.kpi_frequency__c == YEARLY && (Integer.valueOf(aggr.Apttus__Contract_Start_Date__c.month()) == 11) && ((Integer.valueOf(date.today().adddays(7).day()) == 1)||(aggr.Apttus__Contract_End_Date__c == System.Today()+7)) && kpiSLA.kpi_frequency__c != null)
                {   
                    Task exTask = APTS_ComplianceTaskUtils.createComplianceTask(aggr, KPISLASETTLE, Label.APTS_High, 80, tdy+1, Label.APTS_Open, description, intConComMap.get(aggr.APTS_Country__c), contactMap.get(aggr.Apttus__Account__c));
                    taskList.add(exTask);
                 }
            
}}

            /**Creating the internal Compliance task for Volume Obligation**/
            if(agreementVolumeObligationList.size() > 0 && bActivatedagree && aggr.Apttus__Contract_Start_Date__c != null)
            {
                for(APTS_AgreementVolumeObligation__c avo : agreementVolumeObligationList){
                    
                if(avo.APTS_Start_Date__c != null && avo.APTS_End_Date__c != null && aggr.volume_obligation_internal_triggerpoint__c != null && avo.APTS_Volume_Obligation__c != null && avo.APTS_Ordered_Quantity__c != null){
                Date startDate = Date.newInstance(avo.APTS_Start_Date__c.year(),avo.APTS_Start_Date__c.month(),avo.APTS_Start_Date__c.day());
                Date endDate = Date.newInstance(avo.APTS_End_Date__c.year(),avo.APTS_End_Date__c.month(),avo.APTS_End_Date__c.day());
                Integer noOfDays = Date.today().daysBetween(startDate);
                Integer noOfDays1 = endDate.daysBetween(startDate);
                if((Decimal)noOfDays1 != 0 && (avo.APTS_Volume_Obligation__c * ((Decimal)noOfDays/(Decimal)noOfDays1) * aggr.volume_obligation_internal_triggerpoint__c) > avo.APTS_Ordered_Quantity__c && avo.APTS_End_Date__c > System.Today()){
                    String description;
                    if(avo.APTS_Agreement_Total_Volume_Obligation__r.APTS_Action__c != null){
                    description = VOLOBLIINTFREQ1+ (avo.APTS_Volume_Obligation__c * ((Decimal)noOfDays/(Decimal)noOfDays1) * aggr.volume_obligation_internal_triggerpoint__c) + LINEFEED +VOLOBLIINTFREQ2+ avo.APTS_Ordered_Quantity__c + LINEFEED +VOLOBLIINTFREQ3+ avo.APTS_Agreement_Total_Volume_Obligation__r.APTS_Action__c + LINEFEED + URL.getSalesforceBaseUrl().toExternalForm() +SLASH + avo.Id;
                    }
                    else{
                    description = VOLOBLIINTFREQ1+ (avo.APTS_Volume_Obligation__c * ((Decimal)noOfDays/(Decimal)noOfDays1) * aggr.volume_obligation_internal_triggerpoint__c) + LINEFEED +VOLOBLIINTFREQ2+ avo.APTS_Ordered_Quantity__c + LINEFEED +VOLOBLIINTFREQ3+ ' ' + LINEFEED + URL.getSalesforceBaseUrl().toExternalForm() +SLASH + avo.Id;
                    }
                    if(aggr.volume_obligation_internal_freq__c != null){
                
                /**Monthly**/
                if(aggr.volume_obligation_internal_freq__c == MONTHLY && Integer.valueOf(todayDate)-1 == 0 )
                {
                    Task exTask = APTS_ComplianceTaskUtils.createComplianceTask(aggr, VOLUMEOBLIGCHECK, Label.APTS_Medium, 50, tdy+1, Label.APTS_Open, description, intConComMap.get(aggr.APTS_Country__c), contactMap.get(aggr.Apttus__Account__c));
                    taskList.add(exTask);
                }
                /**Quarterly**/
                if(aggr.volume_obligation_internal_freq__c == QUARTERLY  && Integer.valueOf(todayDate)-1 == 0 )
                {   
                    /**First Quarter**/
                    if((Integer.valueOf(aggr.Apttus__Contract_Start_Date__c.month()) + 3) == Integer.valueOf(System.Today().month()))
                    {
                    Task exTask = APTS_ComplianceTaskUtils.createComplianceTask(aggr, VOLUMEOBLIGCHECK, Label.APTS_Medium, 50, tdy+1, Label.APTS_Open, description, intConComMap.get(aggr.APTS_Country__c), contactMap.get(aggr.Apttus__Account__c));
                    taskList.add(exTask);
                    }
                    /**Second Quarter**/
                    else if((Integer.valueOf(aggr.Apttus__Contract_Start_Date__c.month()) + 6) == Integer.valueOf(System.Today().month()))
                    {
                    Task exTask = APTS_ComplianceTaskUtils.createComplianceTask(aggr, VOLUMEOBLIGCHECK, Label.APTS_Medium, 50, tdy+1, Label.APTS_Open, description, intConComMap.get(aggr.APTS_Country__c), contactMap.get(aggr.Apttus__Account__c));
                    taskList.add(exTask);
                    }
                    /**Third Quarter**/
                    else if((Integer.valueOf(aggr.Apttus__Contract_Start_Date__c.month()) + 9) == Integer.valueOf(System.Today().month()))
                    {
                    Task exTask = APTS_ComplianceTaskUtils.createComplianceTask(aggr, VOLUMEOBLIGCHECK, Label.APTS_Medium, 50, tdy+1, Label.APTS_Open, description, intConComMap.get(aggr.APTS_Country__c), contactMap.get(aggr.Apttus__Account__c));
                    taskList.add(exTask);  
                    }
                    /**Fourth Quarter**/
                    else if(aggr.Apttus__Contract_Start_Date__c.month() == System.Today().month() && aggr.Apttus__Contract_Start_Date__c != System.Today())
                    {
                    Task exTask = APTS_ComplianceTaskUtils.createComplianceTask(aggr, VOLUMEOBLIGCHECK, Label.APTS_Medium, 50, tdy+1, Label.APTS_Open, description, intConComMap.get(aggr.APTS_Country__c), contactMap.get(aggr.Apttus__Account__c));
                    taskList.add(exTask);
                    }
                } 
                /**Half Yearly**/
               if(aggr.volume_obligation_internal_freq__c == HALFYEARLY && ((Integer.valueOf(aggr.Apttus__Contract_Start_Date__c.month()) + 6) == Integer.valueOf(System.Today().month()) || aggr.Apttus__Contract_Start_Date__c.month() == System.Today().month())
                       && aggr.Apttus__Contract_Start_Date__c != System.Today()  && Integer.valueOf(todayDate)-1 == 0 )
                {   
                    Task exTask = APTS_ComplianceTaskUtils.createComplianceTask(aggr, VOLUMEOBLIGCHECK, Label.APTS_Medium, 50, tdy+1, Label.APTS_Open, description, intConComMap.get(aggr.APTS_Country__c), contactMap.get(aggr.Apttus__Account__c));
                    taskList.add(exTask);
                 } 
            }
                }   }
                }
            }
            
            /**Creating the Settlement Compliance task for Volume Obligation**/
            if(agreementTotalVolumeObligationList.size() > 0){
                if((bActivatedagree && aggr.Apttus__Contract_End_Date__c != null && aggr.Apttus__Contract_End_Date__c == System.Today()+1) || (bTerminatedagree && aggr.Apttus__Contract_End_Date__c == System.Today()) || (bExpiredagree && aggr.Apttus__Contract_End_Date__c == System.Today())){
                    for(APTS_AgreementVolumeObligation__c avo : agreementVolumeObligationList){
                        String description;
                        if(avo.APTS_Agreement_Total_Volume_Obligation__r.APTS_Action__c != null){
                        description = VOLOBLISETTLEFREQ1+ avo.APTS_Volume_Obligation__c + LINEFEED+ VOLOBLIINTFREQ2+ avo.APTS_Ordered_Quantity__c + LINEFEED +VOLOBLISETTLEFREQ2 + avo.APTS_Agreement_Total_Volume_Obligation__r.APTS_Action__c + LINEFEED +VOLOBLISETTLEFREQ3+ avo.APTS_Malus__c + LINEFEED + URL.getSalesforceBaseUrl().toExternalForm() +SLASH + avo.Id;
                        }
                        else{
                        description = VOLOBLISETTLEFREQ1+ avo.APTS_Volume_Obligation__c + LINEFEED+ VOLOBLIINTFREQ2+ avo.APTS_Ordered_Quantity__c + LINEFEED +VOLOBLISETTLEFREQ2 + ' ' + LINEFEED +VOLOBLISETTLEFREQ3+ avo.APTS_Malus__c + LINEFEED + URL.getSalesforceBaseUrl().toExternalForm() +SLASH + avo.Id;
                        }
                        if(avo.APTS_End_Date__c != null && avo.APTS_Volume_Obligation__c != null && avo.APTS_Ordered_Quantity__c != null && avo.APTS_End_Date__c == System.Today()-1 && avo.APTS_Volume_Obligation__c > avo.APTS_Ordered_Quantity__c)
                        {
                            Task exTask = APTS_ComplianceTaskUtils.createComplianceTask(aggr, VOLUMEOBLIGSETTL, Label.APTS_High, 80, tdy+1, Label.APTS_Open, description, intConComMap.get(aggr.APTS_Country__c), contactMap.get(aggr.Apttus__Account__c));
                            taskList.add(exTask);
                        }
                    }
                    
                }
            }
            
            /**Creating the compliance task for the PO Number change**/
            if(agreementPODetailsList.size()>0 && bActivatedagree){
                for(APTS_Agreement_PO_Details__c pod : agreementPODetailsList){
                String description = PONUMFREQ1 + aggr.Apttus__Account__c +PONUMFREQ2+ LINEFEED+ PONUMFREQ3+ aggr.Id + LINEFEED +PONUMFREQ4+ pod.APTS_PO_Expiration_Date__c;
                    if(pod.APTS_PO_Number_Required__c != null && pod.APTS_PO_Number_Type__c != null && pod.APTS_PO_Expiration_Date__c != null && pod.APTS_PO_Number_Type__c == FIXED && pod.APTS_PO_Expiration_Date__c == (System.Today()+7)){
                    Task exTask = APTS_ComplianceTaskUtils.createComplianceTask(aggr, PONUMREQ, Label.APTS_High, 80, pod.APTS_PO_Expiration_Date__c-7, Label.APTS_Open, description , intConComMap.get(aggr.APTS_Country__c), contactMap.get(aggr.Apttus__Account__c));
                    taskList.add(exTask);
                    }
                }
            }
            /**Email Notification for the SellOut Announcement**/
            if(agreementPayoutScheduleList.size()>0 && bActivatedagree)
            {
                if(Integer.valueOf(System.Today().month()) == 12 && (System.Today() + 1 != Date.today().toStartofWeek() || System.Today() + 2 != Date.today().toStartofWeek()))
                {
                /** EmailTemplate templateId = [Select id from EmailTemplate where name = 'Your template Name'];
                    List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setTemplateID(templateId.Id); 
                    mail.setTargetObjectId(contactId)
                    mail.setSaveAsActivity(false);
                    allmsg.add(mail);
                    Messaging.sendEmail(allmsg,false); **/
                }
            }
        }
                    try{
                        Database.Insert(taskList , false);
                  }
                    catch (Exception ex) {
                         APTS_CustomLogging.createErrorLog(ex.getTypeName(), BATCH, ex.getStackTraceString() ,AGREEMENT, null,CLM,false,false, null, true);
                  }
        }}
        
      

    global void finish(Database.BatchableContext BC) {
       
   }
}