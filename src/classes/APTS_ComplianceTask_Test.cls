@isTest
public class APTS_ComplianceTask_Test {
  @testSetup
   static void testData()
   {   
   
       APTS_ComplianceTaskBatch.todayDate = 1;
       
       /*Test Records creation for Monthly Frequency*/
       Account monthlyTestAccount = new Account();
       monthlyTestAccount.Name = 'Monthly Test Account';
       monthlyTestAccount.Phone = '+919898468401';
       monthlyTestAccount.Main_Street_Only__c = 'Test Street';
       monthlyTestAccount.Main_House_Number__c = 'Test no.';
       monthlyTestAccount.billingcountry = 'Netherlands';
       Database.Insert(monthlyTestAccount);
       
       Id RecId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
       
       Apttus__APTS_Agreement__c monthlyTestAgreement = new Apttus__APTS_Agreement__c(Apttus__Account__c = monthlyTestAccount.Id, 
                        Name = 'Monthly Test Agreement',RecordTypeId = RecId,
                        Apttus__Contract_Start_Date__c = Date.today() - 10, Apttus__Contract_End_Date__c = Date.today() + 7,
                        APTS_Fixed_Term_Startdate__c = Date.today(),                  
                        Apttus__Subtype__c ='Fixed-Term-Fixed Costs',
                        Apttus__Status_Category__c = 'In Effect', Apttus__Status__c = 'Activated', APTS_Fixed_Term_Type__c = 'Fixed Cost', Fixed_Terms_Internal_Freq__c = 'Monthly', kpi_internal_freq__c = 'Monthly', volume_obligation_internal_freq__c = 'Monthly', APTS_Fixed_Term_Frequency__c = 'Quarterly', budget_internal_freq__c = 'Monthly', volume_obligation_internal_triggerpoint__c = 90);
        Database.Insert(monthlyTestAgreement);
        
         Apttus__APTS_Agreement__c KPISLATestAgreement = new Apttus__APTS_Agreement__c(Apttus__Account__c = monthlyTestAccount.Id, 
                        Name = 'KPISLA Test Agreement',RecordTypeId = RecId,
                        Apttus__Contract_Start_Date__c = Date.today() - 10, Apttus__Contract_End_Date__c = Date.today() + 7,
                        APTS_Fixed_Term_Startdate__c = Date.today(),                  
                        Apttus__Subtype__c ='Fixed-Term-Fixed Costs',
                        Apttus__Status_Category__c = 'In Effect', Apttus__Status__c = 'Activated', APTS_Fixed_Term_Type__c = 'Fixed Cost', Fixed_Terms_Internal_Freq__c = 'Monthly', kpi_internal_freq__c = 'Monthly', volume_obligation_internal_freq__c = 'Monthly', APTS_Fixed_Term_Frequency__c = 'Quarterly', budget_internal_freq__c = 'Monthly', volume_obligation_internal_triggerpoint__c = 90);
        Database.Insert(KPISLATestAgreement);
       
       APTS_Agreement_Budget__c monthlyAgreeBudget = new APTS_Agreement_Budget__c(APTS_Category__c = 'Promotions', APTS_Subcategory__c = 'Merchandise', APTS_Start_Date__c = System.today() - 5, APTS_End_Date__c = System.today() + 5, Agreement__c = monthlyTestAgreement.Id);
       Database.Insert(monthlyAgreeBudget);
       
       Contracted_kpi_sla__c monthlyKPISLA = new Contracted_kpi_sla__c(kpi_contract__c = KPISLATestAgreement.Id, KPI_type__c = 'Availability % per machine', kpi_frequency__c = 'Monthly');
       Database.Insert(monthlyKPISLA);
       
       APTS_AgreementTotalVolumeObligation__c MonthlyAgrTotalVolObl = new APTS_AgreementTotalVolumeObligation__c(APTS_Agreement__c = monthlyTestAgreement.Id);
       Database.Insert(MonthlyAgrTotalVolObl);
       
       APTS_AgreementVolumeObligation__c monthlyAgrVolObl = new APTS_AgreementVolumeObligation__c(APTS_Agreement__c = monthlyTestAgreement.Id, APTS_Start_Date__c = System.today() - 10, APTS_End_Date__c = System.today() + 10, APTS_Volume_Obligation__c = 1000);
       Database.Insert(monthlyAgrVolObl);
        
       APTS_Agreement_PO_Details__c poDetails = new APTS_Agreement_PO_Details__c(APTS_PO_Number_Required__c = 'Yes', APTS_PO_Number_Type__c = 'Fixed', APTS_PO_Expiration_Date__c = System.Today()+7, APTS_Agreement__c = monthlyTestAgreement.Id);
       Database.insert(poDetails);
       
   }
   static testMethod void createMonthlyComlianceTask()
   {
    User testUser = [SELECT Id FROM User LIMIT 1];
    
    APTS_ComplianceTaskBatch.todayDate = 1;
    
    Date firstQuarter = Date.newInstance(System.Today().Year(), (System.Today().Month()-3), System.Today().Day());
    Date secondQuarter = Date.newInstance(System.Today().Year(), (System.Today().Month()-6), System.Today().Day());
    Date thirdQuarter = Date.newInstance(System.Today().Year(), (System.Today().Month()-9), System.Today().Day());
    Date foruthQuarter = Date.newInstance(System.Today().Year(), (System.Today().Month()-12), System.Today().Day());
    
    Date firstQuarter1 = Date.newInstance(System.Today().Year(), (System.Today().Month()-2), System.Today().Day());
    Date secondQuarter1 = Date.newInstance(System.Today().Year(), (System.Today().Month()-5), System.Today().Day());
    Date thirdQuarter1 = Date.newInstance(System.Today().Year(), (System.Today().Month()-8), System.Today().Day());
    Date foruthQuarter1 = Date.newInstance(System.Today().Year(), (System.Today().Month()-11), System.Today().Day());
    
    Apttus__APTS_Agreement__c monthlyTestAgreement = [SELECT Id, Name, APTS_Country__c, recordtype.name, APTS_Fixed_Term_Type__c, Apttus__Contract_Start_Date__c, Apttus__Account__c, Apttus__Contract_End_Date__c, 
                                                      APTS_Fixed_Term_Startdate__c, Apttus__Subtype__c,
                                                      Apttus__Status_Category__c, Apttus__Status__c, Fixed_Terms_Internal_Freq__c, 
                                                      kpi_internal_freq__c, APTS_Fixed_Term_Frequency__c, budget_internal_freq__c,
                                                      volume_obligation_internal_triggerpoint__c
                                                      FROM Apttus__APTS_Agreement__c 
                                                      WHERE Name LIKE 'Monthly Test Agreement' LIMIT 1];    
                                                      
    Apttus__APTS_Agreement__c KPISLA = [SELECT Id, Name, APTS_Country__c, recordtype.name, APTS_Fixed_Term_Type__c, Apttus__Contract_Start_Date__c, Apttus__Account__c, Apttus__Contract_End_Date__c, 
                                                      APTS_Fixed_Term_Startdate__c, Apttus__Subtype__c,
                                                      Apttus__Status_Category__c, Apttus__Status__c, Fixed_Terms_Internal_Freq__c, 
                                                      kpi_internal_freq__c, APTS_Fixed_Term_Frequency__c, budget_internal_freq__c,
                                                      volume_obligation_internal_triggerpoint__c
                                                      FROM Apttus__APTS_Agreement__c 
                                                      WHERE Name LIKE 'KPISLA Test Agreement' LIMIT 1];                                                   
       
   APTS_Agreement_Budget__c monthlyAgreeBudget = [SELECT APTS_Category__c, APTS_Subcategory__c, APTS_Start_Date__c, APTS_End_Date__c, Agreement__c
                                                 FROM APTS_Agreement_Budget__c WHERE Agreement__c =: monthlyTestAgreement.Id LIMIT 1];
                                                 
   Contracted_kpi_sla__c monthlyKPISLA = [SELECT kpi_contract__c, KPI_type__c, kpi_frequency__c FROM Contracted_kpi_sla__c WHERE kpi_contract__c =: KPISLA.Id LIMIT 1];
   
   APTS_AgreementTotalVolumeObligation__c monthlyAgreeTotalVolObli = [SELECT APTS_Agreement__c FROM APTS_AgreementTotalVolumeObligation__c WHERE APTS_Agreement__c =: monthlyTestAgreement.Id LIMIT 1];
   
   APTS_AgreementVolumeObligation__c monthlyAgreeVolObli = [SELECT APTS_Agreement__c, APTS_Start_Date__c, APTS_End_Date__c, APTS_Volume_Obligation__c FROM APTS_AgreementVolumeObligation__c WHERE APTS_Agreement__c =: monthlyTestAgreement.Id                                                         LIMIT 1];
   
   APTS_Agreement_PO_Details__c poDetails = [SELECT APTS_PO_Number_Required__c, APTS_PO_Number_Type__c, APTS_PO_Expiration_Date__c, APTS_Agreement__c
                                             FROM APTS_Agreement_PO_Details__c WHERE APTS_Agreement__c =: monthlyTestAgreement.Id LIMIT 1];
  
   test.startTest();
        APTS_ComplianceTaskBatch batch = new APTS_ComplianceTaskBatch();
        Database.executeBatch(batch, 200);
   test.stopTest();
   
   /* ---------- Start of PI fix # 718083 ----------------------- */
   List<Task> tsklst = [Select Id,WhoId,Touchpoint_Type__c from Task];
   System.assertEquals('FIXED TERM CHECK',tsklst[0].Touchpoint_Type__c);  
   /* ---------- End of PI fix # 718083----------------------- */  
                                                        
   }
   
   static testMethod void createFirstQuarterComlianceTask()
   {
    User testUser = [SELECT Id FROM User LIMIT 1];
    
    APTS_ComplianceTaskBatch.todayDate = 1;
    
    Date firstQuarter = Date.newInstance(System.Today().Year(), (System.Today().Month()-3), System.Today().Day());
    Date secondQuarter = Date.newInstance(System.Today().Year(), (System.Today().Month()-6), System.Today().Day());
    Date thirdQuarter = Date.newInstance(System.Today().Year(), (System.Today().Month()-9), System.Today().Day());
    Date foruthQuarter = Date.newInstance(System.Today().Year(), (System.Today().Month()-12), System.Today().Day());
    
    Date firstQuarter1 = Date.newInstance(System.Today().Year(), (System.Today().Month()-2), System.Today().Day());
    Date secondQuarter1 = Date.newInstance(System.Today().Year(), (System.Today().Month()-5), System.Today().Day());
    Date thirdQuarter1 = Date.newInstance(System.Today().Year(), (System.Today().Month()-8), System.Today().Day());
    Date foruthQuarter1 = Date.newInstance(System.Today().Year(), (System.Today().Month()-11), System.Today().Day());
    
    Apttus__APTS_Agreement__c firstQuarterTestAgreement = [SELECT Id, Name, APTS_Country__c, recordtype.name, APTS_Fixed_Term_Type__c, Apttus__Contract_Start_Date__c, Apttus__Account__c, Apttus__Contract_End_Date__c, 
                                                      APTS_Fixed_Term_Startdate__c, Apttus__Subtype__c,
                                                      Apttus__Status_Category__c, Apttus__Status__c, Fixed_Terms_Internal_Freq__c, 
                                                      kpi_internal_freq__c, APTS_Fixed_Term_Frequency__c, budget_internal_freq__c,
                                                      volume_obligation_internal_triggerpoint__c
                                                      FROM Apttus__APTS_Agreement__c 
                                                      WHERE Name LIKE 'Monthly Test Agreement' LIMIT 1];
                                                      firstQuarterTestAgreement.Apttus__Contract_Start_Date__c = firstQuarter;
                                                      firstQuarterTestAgreement.APTS_Fixed_Term_Startdate__c = firstQuarter;
                                                      firstQuarterTestAgreement.Fixed_Terms_Internal_Freq__c = 'Quarterly';
                                                      firstQuarterTestAgreement.kpi_internal_freq__c = 'Quarterly';
                                                      firstQuarterTestAgreement.APTS_Fixed_Term_Frequency__c = 'Quarterly'; 
                                                      firstQuarterTestAgreement.budget_internal_freq__c = 'Quarterly';
                                                      firstQuarterTestAgreement.volume_obligation_internal_freq__c = 'Quarterly';
                                                      Database.update(firstQuarterTestAgreement);
                                                      
    Apttus__APTS_Agreement__c KPISLA = [SELECT Id, Name, APTS_Country__c, recordtype.name, APTS_Fixed_Term_Type__c, Apttus__Contract_Start_Date__c, Apttus__Account__c, Apttus__Contract_End_Date__c, 
                                                      APTS_Fixed_Term_Startdate__c, Apttus__Subtype__c,
                                                      Apttus__Status_Category__c, Apttus__Status__c, Fixed_Terms_Internal_Freq__c, 
                                                      kpi_internal_freq__c, APTS_Fixed_Term_Frequency__c, budget_internal_freq__c,
                                                      volume_obligation_internal_triggerpoint__c
                                                      FROM Apttus__APTS_Agreement__c 
                                                      WHERE Name LIKE 'KPISLA Test Agreement' LIMIT 1];
                                                      KPISLA.Apttus__Contract_Start_Date__c = firstQuarter1;
                                                      KPISLA.kpi_internal_freq__c = 'Quarterly'; 
                                                      Database.update(KPISLA);
       
   APTS_Agreement_Budget__c monthlyAgreeBudget = [SELECT APTS_Category__c, APTS_Subcategory__c, APTS_Start_Date__c, APTS_End_Date__c, Agreement__c
                                                 FROM APTS_Agreement_Budget__c WHERE Agreement__c =: firstQuarterTestAgreement.Id LIMIT 1];
                                                 
   Contracted_kpi_sla__c monthlyKPISLA = [SELECT kpi_contract__c, KPI_type__c, kpi_frequency__c FROM Contracted_kpi_sla__c WHERE kpi_contract__c =: KPISLA.Id LIMIT 1];
                                          monthlyKPISLA.kpi_frequency__c = 'Quarterly';
                                          Database.update(monthlyKPISLA);
   
   APTS_AgreementTotalVolumeObligation__c monthlyAgreeTotalVolObli = [SELECT APTS_Agreement__c FROM APTS_AgreementTotalVolumeObligation__c WHERE APTS_Agreement__c =: firstQuarterTestAgreement.Id LIMIT 1];
   
   APTS_AgreementVolumeObligation__c monthlyAgreeVolObli = [SELECT APTS_Agreement__c, APTS_Start_Date__c, APTS_End_Date__c, APTS_Volume_Obligation__c FROM APTS_AgreementVolumeObligation__c WHERE APTS_Agreement__c =: firstQuarterTestAgreement.Id LIMIT 1];
  
   test.startTest();
        APTS_ComplianceTaskBatch batch = new APTS_ComplianceTaskBatch();
        Database.executeBatch(batch, 200);
   test.stopTest();
   
   /* ---------- Start of PI fix # 718083----------------------- */
   List<Task> tsklst = [Select Id,WhoId,Touchpoint_Type__c from Task];
   System.assertEquals('FIXED TERM CHECK',tsklst[0].Touchpoint_Type__c);
   /* ---------- End of PI fix # 718083----------------------- */ 
                                                        
   }
   
   static testMethod void createSecondQuarterComlianceTask()
   {
    User testUser = [SELECT Id FROM User LIMIT 1];
    
    APTS_ComplianceTaskBatch.todayDate = 1;
    
    Date firstQuarter = Date.newInstance(System.Today().Year(), (System.Today().Month()-3), System.Today().Day());
    Date secondQuarter = Date.newInstance(System.Today().Year(), (System.Today().Month()-6), System.Today().Day());
    Date thirdQuarter = Date.newInstance(System.Today().Year(), (System.Today().Month()-9), System.Today().Day());
    Date foruthQuarter = Date.newInstance(System.Today().Year(), (System.Today().Month()-12), System.Today().Day());
    
    Date firstQuarter1 = Date.newInstance(System.Today().Year(), (System.Today().Month()-2), System.Today().Day());
    Date secondQuarter1 = Date.newInstance(System.Today().Year(), (System.Today().Month()-5), System.Today().Day());
    Date thirdQuarter1 = Date.newInstance(System.Today().Year(), (System.Today().Month()-8), System.Today().Day());
    Date foruthQuarter1 = Date.newInstance(System.Today().Year(), (System.Today().Month()-11), System.Today().Day());
    
    Apttus__APTS_Agreement__c secondQuarterTestAgreement = [SELECT Id, Name, APTS_Country__c, recordtype.name, APTS_Fixed_Term_Type__c, Apttus__Contract_Start_Date__c, Apttus__Account__c, Apttus__Contract_End_Date__c, 
                                                      APTS_Fixed_Term_Startdate__c, Apttus__Subtype__c,
                                                      Apttus__Status_Category__c, Apttus__Status__c, Fixed_Terms_Internal_Freq__c, 
                                                      kpi_internal_freq__c, APTS_Fixed_Term_Frequency__c, budget_internal_freq__c,
                                                      volume_obligation_internal_triggerpoint__c
                                                      FROM Apttus__APTS_Agreement__c 
                                                      WHERE Name LIKE 'Monthly Test Agreement' LIMIT 1];
                                                      secondQuarterTestAgreement.Apttus__Contract_Start_Date__c = secondQuarter;
                                                      secondQuarterTestAgreement.APTS_Fixed_Term_Startdate__c = secondQuarter;
                                                      secondQuarterTestAgreement.Fixed_Terms_Internal_Freq__c = 'Quarterly';
                                                      secondQuarterTestAgreement.kpi_internal_freq__c = 'Quarterly';
                                                      secondQuarterTestAgreement.APTS_Fixed_Term_Frequency__c = 'Quarterly'; 
                                                      secondQuarterTestAgreement.budget_internal_freq__c = 'Quarterly';
                                                      secondQuarterTestAgreement.volume_obligation_internal_freq__c = 'Quarterly';
                                                      Database.update(secondQuarterTestAgreement);
                                                      
   Apttus__APTS_Agreement__c KPISLA = [SELECT Id, Name, APTS_Country__c, recordtype.name, APTS_Fixed_Term_Type__c, Apttus__Contract_Start_Date__c, Apttus__Account__c, Apttus__Contract_End_Date__c, 
                                                      APTS_Fixed_Term_Startdate__c, Apttus__Subtype__c,
                                                      Apttus__Status_Category__c, Apttus__Status__c, Fixed_Terms_Internal_Freq__c, 
                                                      kpi_internal_freq__c, APTS_Fixed_Term_Frequency__c, budget_internal_freq__c,
                                                      volume_obligation_internal_triggerpoint__c
                                                      FROM Apttus__APTS_Agreement__c 
                                                      WHERE Name LIKE 'KPISLA Test Agreement' LIMIT 1];
                                                      KPISLA.Apttus__Contract_Start_Date__c = secondQuarter1;
                                                      KPISLA.kpi_internal_freq__c = 'Quarterly'; 
                                                      Database.update(KPISLA);
       
   APTS_Agreement_Budget__c monthlyAgreeBudget = [SELECT APTS_Category__c, APTS_Subcategory__c, APTS_Start_Date__c, APTS_End_Date__c, Agreement__c
                                                 FROM APTS_Agreement_Budget__c WHERE Agreement__c =: secondQuarterTestAgreement.Id LIMIT 1];
                                                 
   Contracted_kpi_sla__c monthlyKPISLA = [SELECT kpi_contract__c, KPI_type__c, kpi_frequency__c FROM Contracted_kpi_sla__c WHERE kpi_contract__c =: KPISLA.Id LIMIT 1];
                                          monthlyKPISLA.kpi_frequency__c = 'Quarterly';
                                          Database.update(monthlyKPISLA);
   
   APTS_AgreementTotalVolumeObligation__c monthlyAgreeTotalVolObli = [SELECT APTS_Agreement__c FROM APTS_AgreementTotalVolumeObligation__c WHERE APTS_Agreement__c =: secondQuarterTestAgreement.Id LIMIT 1];
   
   APTS_AgreementVolumeObligation__c monthlyAgreeVolObli = [SELECT APTS_Agreement__c, APTS_Start_Date__c, APTS_End_Date__c, APTS_Volume_Obligation__c FROM APTS_AgreementVolumeObligation__c WHERE APTS_Agreement__c =: secondQuarterTestAgreement.Id LIMIT 1];
  
   test.startTest();
        APTS_ComplianceTaskBatch batch = new APTS_ComplianceTaskBatch();
        Database.executeBatch(batch, 200);
   test.stopTest();
   
   /* ---------- Start of PI fix # 718083 ----------------------- */
   List<Task> tsklst = [Select Id,WhoId,Touchpoint_Type__c from Task];
   System.assertEquals('P.O. NUMBER REQUEST',tsklst[0].Touchpoint_Type__c);  
   /* ---------- End of PI fix # 718083----------------------- */                                                
   }
   
   static testMethod void createThirdQuarterComlianceTask()
   {
    User testUser = [SELECT Id FROM User LIMIT 1];
    
    APTS_ComplianceTaskBatch.todayDate = 1;
    
    Date firstQuarter = Date.newInstance(System.Today().Year(), (System.Today().Month()-3), System.Today().Day());
    Date secondQuarter = Date.newInstance(System.Today().Year(), (System.Today().Month()-6), System.Today().Day());
    Date thirdQuarter = Date.newInstance(System.Today().Year(), (System.Today().Month()-9), System.Today().Day());
    Date foruthQuarter = Date.newInstance(System.Today().Year(), (System.Today().Month()-12), System.Today().Day());
    
    Date firstQuarter1 = Date.newInstance(System.Today().Year(), (System.Today().Month()-2), System.Today().Day());
    Date secondQuarter1 = Date.newInstance(System.Today().Year(), (System.Today().Month()-5), System.Today().Day());
    Date thirdQuarter1 = Date.newInstance(System.Today().Year(), (System.Today().Month()-8), System.Today().Day());
    Date foruthQuarter1 = Date.newInstance(System.Today().Year(), (System.Today().Month()-11), System.Today().Day());
    
    Apttus__APTS_Agreement__c thirdQuarterTestAgreement = [SELECT Id, Name, APTS_Country__c, recordtype.name, APTS_Fixed_Term_Type__c, Apttus__Contract_Start_Date__c, Apttus__Account__c, Apttus__Contract_End_Date__c, 
                                                      APTS_Fixed_Term_Startdate__c, Apttus__Subtype__c,
                                                      Apttus__Status_Category__c, Apttus__Status__c, Fixed_Terms_Internal_Freq__c, 
                                                      kpi_internal_freq__c, APTS_Fixed_Term_Frequency__c, budget_internal_freq__c,
                                                      volume_obligation_internal_triggerpoint__c
                                                      FROM Apttus__APTS_Agreement__c 
                                                      WHERE Name LIKE 'Monthly Test Agreement' LIMIT 1];
                                                      thirdQuarterTestAgreement.Apttus__Contract_Start_Date__c = thirdQuarter;
                                                      thirdQuarterTestAgreement.APTS_Fixed_Term_Startdate__c = thirdQuarter;
                                                      thirdQuarterTestAgreement.Fixed_Terms_Internal_Freq__c = 'Quarterly';
                                                      thirdQuarterTestAgreement.kpi_internal_freq__c = 'Quarterly';
                                                      thirdQuarterTestAgreement.APTS_Fixed_Term_Frequency__c = 'Quarterly'; 
                                                      thirdQuarterTestAgreement.budget_internal_freq__c = 'Quarterly';
                                                      thirdQuarterTestAgreement.volume_obligation_internal_freq__c = 'Quarterly';
                                                      Database.update(thirdQuarterTestAgreement);
                                                      
    Apttus__APTS_Agreement__c KPISLA = [SELECT Id, Name, APTS_Country__c, recordtype.name, APTS_Fixed_Term_Type__c, Apttus__Contract_Start_Date__c, Apttus__Account__c, Apttus__Contract_End_Date__c, 
                                                      APTS_Fixed_Term_Startdate__c, Apttus__Subtype__c,
                                                      Apttus__Status_Category__c, Apttus__Status__c, Fixed_Terms_Internal_Freq__c, 
                                                      kpi_internal_freq__c, APTS_Fixed_Term_Frequency__c, budget_internal_freq__c,
                                                      volume_obligation_internal_triggerpoint__c
                                                      FROM Apttus__APTS_Agreement__c 
                                                      WHERE Name LIKE 'KPISLA Test Agreement' LIMIT 1];
                                                      KPISLA.Apttus__Contract_Start_Date__c = thirdQuarter1;
                                                      KPISLA.kpi_internal_freq__c = 'Quarterly'; 
                                                      Database.update(KPISLA);
       
   APTS_Agreement_Budget__c monthlyAgreeBudget = [SELECT APTS_Category__c, APTS_Subcategory__c, APTS_Start_Date__c, APTS_End_Date__c, Agreement__c
                                                 FROM APTS_Agreement_Budget__c WHERE Agreement__c =: thirdQuarterTestAgreement.Id LIMIT 1];
                                                 
   Contracted_kpi_sla__c monthlyKPISLA = [SELECT kpi_contract__c, KPI_type__c, kpi_frequency__c FROM Contracted_kpi_sla__c WHERE kpi_contract__c =: KPISLA.Id LIMIT 1];
                                          monthlyKPISLA.kpi_frequency__c = 'Quarterly';
                                          Database.update(monthlyKPISLA);
   
   APTS_AgreementTotalVolumeObligation__c monthlyAgreeTotalVolObli = [SELECT APTS_Agreement__c FROM APTS_AgreementTotalVolumeObligation__c WHERE APTS_Agreement__c =: thirdQuarterTestAgreement.Id LIMIT 1];
   
   APTS_AgreementVolumeObligation__c monthlyAgreeVolObli = [SELECT APTS_Agreement__c, APTS_Start_Date__c, APTS_End_Date__c, APTS_Volume_Obligation__c FROM APTS_AgreementVolumeObligation__c WHERE APTS_Agreement__c =: thirdQuarterTestAgreement.Id LIMIT 1];
  
   test.startTest();
        APTS_ComplianceTaskBatch batch = new APTS_ComplianceTaskBatch();
        Database.executeBatch(batch, 200);
   test.stopTest();
        
   /* ---------- Start of PI fix # 718083----------------------- */
   List<Task> tsklst = [Select Id,WhoId,Touchpoint_Type__c from Task];
   System.assertEquals('P.O. NUMBER REQUEST',tsklst[0].Touchpoint_Type__c);  
   /* ---------- End of PI fix # 718083----------------------- */                                            
   }
   
   static testMethod void createFourthQuarterComlianceTask()
   {
    User testUser = [SELECT Id FROM User LIMIT 1];
    
    APTS_ComplianceTaskBatch.todayDate = 1;
    
    Date firstQuarter = Date.newInstance(System.Today().Year(), (System.Today().Month()-3), System.Today().Day());
    Date secondQuarter = Date.newInstance(System.Today().Year(), (System.Today().Month()-6), System.Today().Day());
    Date thirdQuarter = Date.newInstance(System.Today().Year(), (System.Today().Month()-9), System.Today().Day());
    Date foruthQuarter = Date.newInstance(System.Today().Year(), (System.Today().Month()-12), System.Today().Day());
    
    Date firstQuarter1 = Date.newInstance(System.Today().Year(), (System.Today().Month()-2), System.Today().Day());
    Date secondQuarter1 = Date.newInstance(System.Today().Year(), (System.Today().Month()-5), System.Today().Day());
    Date thirdQuarter1 = Date.newInstance(System.Today().Year(), (System.Today().Month()-8), System.Today().Day());
    Date foruthQuarter1 = Date.newInstance(System.Today().Year(), (System.Today().Month()-11), System.Today().Day());
    
    Apttus__APTS_Agreement__c fourthQuarterTestAgreement = [SELECT Id, Name, APTS_Country__c, recordtype.name, APTS_Fixed_Term_Type__c, Apttus__Contract_Start_Date__c, Apttus__Account__c, Apttus__Contract_End_Date__c, 
                                                      APTS_Fixed_Term_Startdate__c, Apttus__Subtype__c,
                                                      Apttus__Status_Category__c, Apttus__Status__c, Fixed_Terms_Internal_Freq__c, 
                                                      kpi_internal_freq__c, APTS_Fixed_Term_Frequency__c, budget_internal_freq__c,
                                                      volume_obligation_internal_triggerpoint__c
                                                      FROM Apttus__APTS_Agreement__c 
                                                      WHERE Name LIKE 'Monthly Test Agreement' LIMIT 1];
                                                      fourthQuarterTestAgreement.Apttus__Contract_Start_Date__c = foruthQuarter;
                                                      fourthQuarterTestAgreement.APTS_Fixed_Term_Startdate__c = foruthQuarter;
                                                      fourthQuarterTestAgreement.Fixed_Terms_Internal_Freq__c = 'Quarterly';
                                                      fourthQuarterTestAgreement.kpi_internal_freq__c = 'Quarterly';
                                                      fourthQuarterTestAgreement.APTS_Fixed_Term_Frequency__c = 'Quarterly'; 
                                                      fourthQuarterTestAgreement.budget_internal_freq__c = 'Quarterly';
                                                      fourthQuarterTestAgreement.volume_obligation_internal_freq__c = 'Quarterly';
                                                      Database.update(fourthQuarterTestAgreement);
                                                      
     Apttus__APTS_Agreement__c KPISLA = [SELECT Id, Name, APTS_Country__c, recordtype.name, APTS_Fixed_Term_Type__c, Apttus__Contract_Start_Date__c, Apttus__Account__c, Apttus__Contract_End_Date__c, 
                                                      APTS_Fixed_Term_Startdate__c, Apttus__Subtype__c,
                                                      Apttus__Status_Category__c, Apttus__Status__c, Fixed_Terms_Internal_Freq__c, 
                                                      kpi_internal_freq__c, APTS_Fixed_Term_Frequency__c, budget_internal_freq__c,
                                                      volume_obligation_internal_triggerpoint__c
                                                      FROM Apttus__APTS_Agreement__c 
                                                      WHERE Name LIKE 'KPISLA Test Agreement' LIMIT 1];
                                                      KPISLA.Apttus__Contract_Start_Date__c = foruthQuarter1;
                                                      KPISLA.kpi_internal_freq__c = 'Quarterly'; 
                                                      Database.update(KPISLA);
       
   APTS_Agreement_Budget__c monthlyAgreeBudget = [SELECT APTS_Category__c, APTS_Subcategory__c, APTS_Start_Date__c, APTS_End_Date__c, Agreement__c
                                                 FROM APTS_Agreement_Budget__c WHERE Agreement__c =: fourthQuarterTestAgreement.Id LIMIT 1];
                                                 
   Contracted_kpi_sla__c monthlyKPISLA = [SELECT kpi_contract__c, KPI_type__c, kpi_frequency__c FROM Contracted_kpi_sla__c WHERE kpi_contract__c =: KPISLA.Id LIMIT 1];
                                          monthlyKPISLA.kpi_frequency__c = 'Quarterly';
                                          Database.update(monthlyKPISLA);
   
   APTS_AgreementTotalVolumeObligation__c monthlyAgreeTotalVolObli = [SELECT APTS_Agreement__c FROM APTS_AgreementTotalVolumeObligation__c WHERE APTS_Agreement__c =: fourthQuarterTestAgreement.Id LIMIT 1];
   
   APTS_AgreementVolumeObligation__c monthlyAgreeVolObli = [SELECT APTS_Agreement__c, APTS_Start_Date__c, APTS_End_Date__c, APTS_Volume_Obligation__c FROM APTS_AgreementVolumeObligation__c WHERE APTS_Agreement__c =:fourthQuarterTestAgreement.Id LIMIT 1];
  
   test.startTest();
        APTS_ComplianceTaskBatch batch = new APTS_ComplianceTaskBatch();
        Database.executeBatch(batch, 200);
   test.stopTest();
       
   /* ---------- Start of PI fix # 718083 ----------------------- */
   List<Task> tsklst = [Select Id,WhoId,Touchpoint_Type__c from Task];
   System.assertEquals('FIXED TERM CHECK',tsklst[0].Touchpoint_Type__c);  
   /* ---------- End of PI fix # 718083----------------------- */                                               
   }
   
   static testMethod void createHalfYearComlianceTask()
   {
    User testUser = [SELECT Id FROM User LIMIT 1];
    
    APTS_ComplianceTaskBatch.todayDate = 1;
    
    Date firstHalfYear = Date.newInstance(System.Today().Year(), (System.Today().Month()-6), System.Today().Day());
    Date secondtHalfYear = Date.newInstance(System.Today().Year(), (System.Today().Month()-12), System.Today().Day());
    
    Date firstHalfYear1 = Date.newInstance(System.Today().Year(), (System.Today().Month()-8), System.Today().Day());
    Date secondtHalfYear2 = Date.newInstance(System.Today().Year(), (System.Today().Month()-11), System.Today().Day());
    
    Apttus__APTS_Agreement__c halfYearTestAgreement = [SELECT Id, Name, APTS_Country__c, recordtype.name, APTS_Fixed_Term_Type__c, Apttus__Contract_Start_Date__c, Apttus__Account__c, Apttus__Contract_End_Date__c, 
                                                      APTS_Fixed_Term_Startdate__c, Apttus__Subtype__c,
                                                      Apttus__Status_Category__c, Apttus__Status__c, Fixed_Terms_Internal_Freq__c, 
                                                      kpi_internal_freq__c, APTS_Fixed_Term_Frequency__c, budget_internal_freq__c,
                                                      volume_obligation_internal_triggerpoint__c
                                                      FROM Apttus__APTS_Agreement__c 
                                                      WHERE Name LIKE 'Monthly Test Agreement' LIMIT 1];
                                                      halfYearTestAgreement.Apttus__Contract_Start_Date__c = firstHalfYear;
                                                      halfYearTestAgreement.APTS_Fixed_Term_Startdate__c = firstHalfYear;
                                                      halfYearTestAgreement.Fixed_Terms_Internal_Freq__c = 'Half Yearly';
                                                      halfYearTestAgreement.kpi_internal_freq__c = 'Half Yearly';
                                                      halfYearTestAgreement.APTS_Fixed_Term_Frequency__c = 'Half Yearly';
                                                      halfYearTestAgreement.budget_internal_freq__c = 'Half Yearly';
                                                      halfYearTestAgreement.volume_obligation_internal_freq__c = 'Half Yearly';
                                                      Database.update(halfYearTestAgreement);
                                                      
    Apttus__APTS_Agreement__c KPISLA = [SELECT Id, Name, APTS_Country__c, recordtype.name, APTS_Fixed_Term_Type__c, Apttus__Contract_Start_Date__c, Apttus__Account__c, Apttus__Contract_End_Date__c, 
                                                      APTS_Fixed_Term_Startdate__c, Apttus__Subtype__c,
                                                      Apttus__Status_Category__c, Apttus__Status__c, Fixed_Terms_Internal_Freq__c, 
                                                      kpi_internal_freq__c, APTS_Fixed_Term_Frequency__c, budget_internal_freq__c,
                                                      volume_obligation_internal_triggerpoint__c
                                                      FROM Apttus__APTS_Agreement__c 
                                                      WHERE Name LIKE 'KPISLA Test Agreement' LIMIT 1];
                                                      KPISLA.Apttus__Contract_Start_Date__c = firstHalfYear1;
                                                      KPISLA.kpi_internal_freq__c = 'Quarterly'; 
                                                      Database.update(KPISLA);
       
   APTS_Agreement_Budget__c monthlyAgreeBudget = [SELECT APTS_Category__c, APTS_Subcategory__c, APTS_Start_Date__c, APTS_End_Date__c, Agreement__c
                                                 FROM APTS_Agreement_Budget__c WHERE Agreement__c =: halfYearTestAgreement.Id LIMIT 1];
                                                 
   Contracted_kpi_sla__c monthlyKPISLA = [SELECT kpi_contract__c, KPI_type__c, kpi_frequency__c FROM Contracted_kpi_sla__c WHERE kpi_contract__c =: KPISLA.Id LIMIT 1];
                                          monthlyKPISLA.kpi_frequency__c = 'Half-Yearly';
                                          Database.update(monthlyKPISLA);
   
   APTS_AgreementTotalVolumeObligation__c monthlyAgreeTotalVolObli = [SELECT APTS_Agreement__c FROM APTS_AgreementTotalVolumeObligation__c WHERE APTS_Agreement__c =: halfYearTestAgreement.Id LIMIT 1];
   
   APTS_AgreementVolumeObligation__c monthlyAgreeVolObli = [SELECT APTS_Agreement__c, APTS_Start_Date__c, APTS_End_Date__c, APTS_Volume_Obligation__c FROM APTS_AgreementVolumeObligation__c WHERE APTS_Agreement__c =:halfYearTestAgreement.Id LIMIT 1];
  
   test.startTest();
        APTS_ComplianceTaskBatch batch = new APTS_ComplianceTaskBatch();
        Database.executeBatch(batch, 200);
   test.stopTest();
       
   /* ---------- Start of PI fix # 718083 ----------------------- */
   List<Task> tsklst = [Select Id,WhoId,Touchpoint_Type__c from Task];
   System.assertEquals('P.O. NUMBER REQUEST',tsklst[0].Touchpoint_Type__c);     
   /* ---------- End of PI fix # 718083----------------------- */                                            
   }
   
   static testMethod void createYearlyComlianceTask()
   {
    User testUser = [SELECT Id FROM User LIMIT 1];
    
    APTS_ComplianceTaskBatch.todayDate = 1;
    
    Date Yearly = Date.newInstance(System.Today().Year(), (System.Today().Month()-12), System.Today().Day());
    
    Date Yearly2 = Date.newInstance(System.Today().Year(), (System.Today().Month()-11), System.Today().Day());
    
    Apttus__APTS_Agreement__c YearlyTestAgreement = [SELECT Id, Name, APTS_Country__c, recordtype.name, APTS_Fixed_Term_Type__c, Apttus__Contract_Start_Date__c, Apttus__Account__c, Apttus__Contract_End_Date__c, 
                                                      APTS_Fixed_Term_Startdate__c, Apttus__Subtype__c,
                                                      Apttus__Status_Category__c, Apttus__Status__c, Fixed_Terms_Internal_Freq__c, 
                                                      kpi_internal_freq__c, APTS_Fixed_Term_Frequency__c, budget_internal_freq__c,
                                                      volume_obligation_internal_triggerpoint__c
                                                      FROM Apttus__APTS_Agreement__c 
                                                      WHERE Name LIKE 'Monthly Test Agreement' LIMIT 1];
                                                      YearlyTestAgreement.Apttus__Contract_Start_Date__c = Yearly;
                                                      YearlyTestAgreement.APTS_Fixed_Term_Startdate__c = Yearly;
                                                      YearlyTestAgreement.Fixed_Terms_Internal_Freq__c = 'Half Yearly';
                                                      YearlyTestAgreement.kpi_internal_freq__c = 'Half Yearly';
                                                      YearlyTestAgreement.APTS_Fixed_Term_Frequency__c = 'Yearly';
                                                      YearlyTestAgreement.budget_internal_freq__c = 'Half Yearly';
                                                      Database.update(YearlyTestAgreement);
                                                      
   Apttus__APTS_Agreement__c KPISLA = [SELECT Id, Name, APTS_Country__c, recordtype.name, APTS_Fixed_Term_Type__c, Apttus__Contract_Start_Date__c, Apttus__Account__c, Apttus__Contract_End_Date__c, 
                                                      APTS_Fixed_Term_Startdate__c, Apttus__Subtype__c,
                                                      Apttus__Status_Category__c, Apttus__Status__c, Fixed_Terms_Internal_Freq__c, 
                                                      kpi_internal_freq__c, APTS_Fixed_Term_Frequency__c, budget_internal_freq__c,
                                                      volume_obligation_internal_triggerpoint__c
                                                      FROM Apttus__APTS_Agreement__c 
                                                      WHERE Name LIKE 'KPISLA Test Agreement' LIMIT 1];
                                                      KPISLA.Apttus__Contract_Start_Date__c = Yearly2;
                                                      KPISLA.kpi_internal_freq__c = 'Quarterly'; 
                                                      Database.update(KPISLA);
       
   APTS_Agreement_Budget__c monthlyAgreeBudget = [SELECT APTS_Category__c, APTS_Subcategory__c, APTS_Start_Date__c, APTS_End_Date__c, Agreement__c
                                                 FROM APTS_Agreement_Budget__c WHERE Agreement__c =: YearlyTestAgreement.Id LIMIT 1];
                                                 
   Contracted_kpi_sla__c monthlyKPISLA = [SELECT kpi_contract__c, KPI_type__c, kpi_frequency__c FROM Contracted_kpi_sla__c WHERE kpi_contract__c =: KPISLA.Id LIMIT 1];
                                          monthlyKPISLA.kpi_frequency__c = 'Yearly';
                                          Database.update(monthlyKPISLA);
   
   APTS_AgreementTotalVolumeObligation__c monthlyAgreeTotalVolObli = [SELECT APTS_Agreement__c FROM APTS_AgreementTotalVolumeObligation__c WHERE APTS_Agreement__c =: YearlyTestAgreement.Id LIMIT 1];
   
   APTS_AgreementVolumeObligation__c monthlyAgreeVolObli = [SELECT APTS_Agreement__c, APTS_Start_Date__c, APTS_End_Date__c, APTS_Volume_Obligation__c FROM APTS_AgreementVolumeObligation__c WHERE APTS_Agreement__c =:YearlyTestAgreement.Id LIMIT 1];
  
   test.startTest();
        APTS_ComplianceTaskBatch batch = new APTS_ComplianceTaskBatch();
        Database.executeBatch(batch, 200);
   test.stopTest();
      
      /* ---------- Start of PI fix # 718083 ----------------------- */
      List<Task> tsklst = [Select Id,WhoId,Touchpoint_Type__c from Task];
      System.assertEquals('FIXED TERM CHECK',tsklst[0].Touchpoint_Type__c); 
      /* ---------- End of PI fix # 718083 ----------------------- */                                                 
   }
   
    static testMethod void createVolObligationComlianceTask()
   {
    User testUser = [SELECT Id FROM User LIMIT 1];
    
    APTS_ComplianceTaskBatch.todayDate = 1;
    
    Date firstQuarter = Date.newInstance(System.Today().Year(), (System.Today().Month()-3), System.Today().Day());
    Date secondQuarter = Date.newInstance(System.Today().Year(), (System.Today().Month()-6), System.Today().Day());
    Date thirdQuarter = Date.newInstance(System.Today().Year(), (System.Today().Month()-9), System.Today().Day());
    Date foruthQuarter = Date.newInstance(System.Today().Year(), (System.Today().Month()-12), System.Today().Day());
    
    Apttus__APTS_Agreement__c monthlyTestAgreement = [SELECT Id, Name, APTS_Country__c, recordtype.name, APTS_Fixed_Term_Type__c, Apttus__Contract_Start_Date__c, Apttus__Account__c, Apttus__Contract_End_Date__c, 
                                                      APTS_Fixed_Term_Startdate__c, Apttus__Subtype__c,
                                                      Apttus__Status_Category__c, Apttus__Status__c, Fixed_Terms_Internal_Freq__c, 
                                                      kpi_internal_freq__c, APTS_Fixed_Term_Frequency__c, budget_internal_freq__c,
                                                      volume_obligation_internal_triggerpoint__c
                                                      FROM Apttus__APTS_Agreement__c 
                                                      WHERE Name LIKE 'Monthly Test Agreement' LIMIT 1];
                                                      monthlyTestAgreement.Apttus__Contract_End_Date__c = System.Today()+1;
                                                      Database.update(monthlyTestAgreement);                                              
       
   APTS_Agreement_Budget__c monthlyAgreeBudget = [SELECT APTS_Category__c, APTS_Subcategory__c, APTS_Start_Date__c, APTS_End_Date__c, Agreement__c
                                                 FROM APTS_Agreement_Budget__c WHERE Agreement__c =: monthlyTestAgreement.Id LIMIT 1];
                                                 
   //Contracted_kpi_sla__c monthlyKPISLA = [SELECT kpi_contract__c, KPI_type__c, kpi_frequency__c FROM Contracted_kpi_sla__c WHERE kpi_contract__c =: monthlyTestAgreement.Id LIMIT 1];
   
   APTS_AgreementTotalVolumeObligation__c monthlyAgreeTotalVolObli = [SELECT APTS_Agreement__c FROM APTS_AgreementTotalVolumeObligation__c WHERE APTS_Agreement__c =: monthlyTestAgreement.Id LIMIT 1];
   
   APTS_AgreementVolumeObligation__c monthlyAgreeVolObli = [SELECT APTS_Agreement__c, APTS_Start_Date__c, APTS_End_Date__c, APTS_Volume_Obligation__c                                                         FROM APTS_AgreementVolumeObligation__c 
                                                            WHERE APTS_Agreement__c =: monthlyTestAgreement.Id LIMIT 1];
                                                            monthlyAgreeVolObli.APTS_End_Date__c = System.Today()-1;
                                                            Database.update(monthlyAgreeVolObli);
  
   test.startTest();
        APTS_ComplianceTaskBatch batch = new APTS_ComplianceTaskBatch();
        Database.executeBatch(batch, 200);
   test.stopTest();
   
   /* ---------- Start of PI fix # 718083----------------------- */
   List<Task> tsklst = [Select Id,WhoId,Touchpoint_Type__c from Task];
   System.assertEquals('FIXED TERM CHECK',tsklst[0].Touchpoint_Type__c);
   /* ---------- End of PI fix # 718083----------------------- */
                                                  
   }
   
 
}