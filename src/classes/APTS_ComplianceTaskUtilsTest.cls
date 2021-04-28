/*************************************************************
@Name: APTS_ComplianceTaskUtilsTest
@Author: Shanmuga Prasath
@CreateDate: 04-11-2018
@Description: Test class for APTS_ComplianceTaskUtils
@Used By : APTS_ComplianceTaskUtils
******************************************************************/
@isTest
private class APTS_ComplianceTaskUtilsTest{
    
    static final String FIXEDTERMCHECK = 'FIXED TERM CHECK';
    static final String FIXEDTERMSSETTL = 'FIXED TERMS SETTL';
    static final String BUDGETCHECK = 'BUDGET CHECK';
    static final String KPISLACHECK = 'KPI-SLA CHECK';
    static final String KPISLASETTL = 'KPI-SLA SETTL';
    static final String VOLUMEOBLIGCHECK = 'VOLUME OBLIG CHECK';
    static final String VOLUMEOBLIGSETTL = 'VOLUME OBLIG SETTL';
    static final String PONUMBERREQUEST = 'P.O. NUMBER REQUEST';
    static final String ONETIMEBONUS = 'ONE-TIME BONUS';
    
    @testSetup
    static void testData(){
        Contact contact = APTS_TestUtils.createContact();
        Database.insert(contact,false);
        
        Apttus_Config2__PriceList__c priceList = APTS_TestUtils.createPriceList();
        Database.insert(priceList,false);
        
        Account account = APTS_TestUtils.createaccount();
        Database.insert(account,false);
        
        Apttus__APTS_Agreement__c agreement = APTS_TestUtils.createAgreement(contact.Id, null, priceList.Id, account.Id);
        agreement.Apttus__Status__c = Label.Apttus.Activated;
        agreement.Apttus__Status_Category__c = Label.APTS_In_Effect;
        agreement.Apttus__Auto_Renewal__c = false;
        agreement.Apttus__Contract_End_Date__c = System.Today() - 1;
        agreement.Apttus__Primary_Contact__c = NULL;
        Database.insert(agreement,false);
        
        Internal_contract_compliance__c compliance = new Internal_contract_compliance__c();
        compliance.Name = 'Test Compliance';
        compliance.budget_internal_freq__c = 'Monthly';
        compliance.Country__c = 'Belgium';
        compliance.fixed_terms_internal_freq__c = 'Monthly';
        compliance.kpi_internal_freq__c = 'Monthly';
        compliance.volume_obligation_internal_freq__c = 'Monthly';
        compliance.volume_obligation_internal_triggerpoint__c = 90000.00;
        compliance.Fixed_Terms_internal_task_user__c = UserInfo.getUserId();
        compliance.Fixed_Terms_Settlement_task_User__c = UserInfo.getUserId();
        compliance.Budget_internal_task_User__c = UserInfo.getUserId();
        compliance.KPI_SLA_internal_task_User__c = UserInfo.getUserId();
        compliance.KPI_SLA_Settlement_task_User__c = UserInfo.getUserId();
        compliance.Volume_Obligation_internal_task_User__c = UserInfo.getUserId();
        compliance.Volume_Obligation_Settlement_task_User__c = UserInfo.getUserId();
        compliance.PO_Number_internal_task_User__c = UserInfo.getUserId();
        compliance.One_time_Bonus_internal_task_User__c = UserInfo.getUserId();
        compliance.APTS_Queue_Task__c = true;
        Database.insert(compliance, false);
        
    }
    
    @isTest
    static void testCreation(){
        
        Internal_contract_compliance__c compliance = [SELECT Id, Name, budget_internal_freq__c, Country__c, fixed_terms_internal_freq__c,
        kpi_internal_freq__c, volume_obligation_internal_freq__c, volume_obligation_internal_triggerpoint__c, Fixed_Terms_internal_task_user__c,
        Fixed_Terms_Settlement_task_User__c, Budget_internal_task_User__c, KPI_SLA_internal_task_User__c, KPI_SLA_Settlement_task_User__c,
        Volume_Obligation_internal_task_User__c, Volume_Obligation_Settlement_task_User__c, PO_Number_internal_task_User__c, APTS_Queue_Task__c, One_time_Bonus_internal_task_User__c
        FROM Internal_contract_compliance__c LIMIT 1];
        
        Contact contact = [SELECT Id FROM Contact LIMIT 1];
        
        Apttus__APTS_Agreement__c agreement = [SELECT Id, Apttus__Primary_Contact__c, Apttus__Account__r.name, ownerId FROM Apttus__APTS_Agreement__c LIMIT 1];
        
        Task complianceTask = APTS_ComplianceTaskUtils.createComplianceTask(agreement, FIXEDTERMCHECK, 'Low', 1, System.Today(), 'New', 'Test', compliance, contact);
        
        Id assignedToId1 = APTS_ComplianceTaskUtils.getAssignedTo(compliance, FIXEDTERMCHECK);
        Id assignedToId2 = APTS_ComplianceTaskUtils.getAssignedTo(compliance, FIXEDTERMSSETTL);
        Id assignedToId3 = APTS_ComplianceTaskUtils.getAssignedTo(compliance, BUDGETCHECK);
        Id assignedToId4 = APTS_ComplianceTaskUtils.getAssignedTo(compliance, KPISLACHECK);
        Id assignedToId5 = APTS_ComplianceTaskUtils.getAssignedTo(compliance, KPISLASETTL);
        Id assignedToId6 = APTS_ComplianceTaskUtils.getAssignedTo(compliance, VOLUMEOBLIGCHECK);
        Id assignedToId7 = APTS_ComplianceTaskUtils.getAssignedTo(compliance, VOLUMEOBLIGSETTL);
        Id assignedToId8 = APTS_ComplianceTaskUtils.getAssignedTo(compliance, PONUMBERREQUEST);
        Id assignedToId9 = APTS_ComplianceTaskUtils.getAssignedTo(compliance, ONETIMEBONUS);
        
        System.assertEquals(compliance.Fixed_Terms_internal_task_user__c,assignedToId1);
        System.assertEquals(compliance.Fixed_Terms_Settlement_task_User__c,assignedToId2);
        System.assertEquals(compliance.Budget_internal_task_User__c,assignedToId3);

    }
    
    @isTest
    static void testCreationForOneTime(){
        
        Internal_contract_compliance__c compliance = [SELECT Id, Name, budget_internal_freq__c, Country__c, fixed_terms_internal_freq__c,
        kpi_internal_freq__c, volume_obligation_internal_freq__c, volume_obligation_internal_triggerpoint__c, Fixed_Terms_internal_task_user__c,
        Fixed_Terms_Settlement_task_User__c, Budget_internal_task_User__c, KPI_SLA_internal_task_User__c, KPI_SLA_Settlement_task_User__c,
        Volume_Obligation_internal_task_User__c, Volume_Obligation_Settlement_task_User__c, PO_Number_internal_task_User__c, One_time_Bonus_internal_task_User__c
        FROM Internal_contract_compliance__c LIMIT 1];
        
        Contact contact = [SELECT Id FROM Contact LIMIT 1];
        
        Apttus__APTS_Agreement__c agreement = [SELECT Id, Apttus__Primary_Contact__c, Apttus__Account__r.name, ownerId FROM Apttus__APTS_Agreement__c LIMIT 1];
        
        List<Task> complianceTaskForOnetime = APTS_ComplianceTaskUtils.createComplianceTaskForOneTime(agreement,'ONE-TIME BONUS', 'Low', 1, System.Today(), 'New', 'Test', compliance, contact);
        
        
        Id assignedToId1 = APTS_ComplianceTaskUtils.getAssignedTo(compliance, FIXEDTERMCHECK);
        Id assignedToId2 = APTS_ComplianceTaskUtils.getAssignedTo(compliance, FIXEDTERMSSETTL);
        Id assignedToId3 = APTS_ComplianceTaskUtils.getAssignedTo(compliance, BUDGETCHECK);
        Id assignedToId4 = APTS_ComplianceTaskUtils.getAssignedTo(compliance, KPISLACHECK);
        Id assignedToId5 = APTS_ComplianceTaskUtils.getAssignedTo(compliance, KPISLASETTL);
        Id assignedToId6 = APTS_ComplianceTaskUtils.getAssignedTo(compliance, VOLUMEOBLIGCHECK);
        Id assignedToId7 = APTS_ComplianceTaskUtils.getAssignedTo(compliance, VOLUMEOBLIGSETTL);
        Id assignedToId8 = APTS_ComplianceTaskUtils.getAssignedTo(compliance, PONUMBERREQUEST);
        Id assignedToId9 = APTS_ComplianceTaskUtils.getAssignedTo(compliance, ONETIMEBONUS);
        
        System.assertEquals(compliance.Fixed_Terms_internal_task_user__c,assignedToId1);
        System.assertEquals(compliance.Fixed_Terms_Settlement_task_User__c,assignedToId2);
        System.assertEquals(compliance.Budget_internal_task_User__c,assignedToId3);

    }
    
}