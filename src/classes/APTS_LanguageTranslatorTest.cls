/*************************************************************
@Name: APTS_LanguageTranslatorTest
@Author: Pranjal Mittal
@CreateDate: 21-08-2018
@Description: 
@UsedBy: 
******************************************************************/

@isTest
private class APTS_LanguageTranslatorTest {
    private static Apttus__APTS_Agreement__c tstAgreeemnt;

    static{
        APTS_Language_Translation__c tstDutch = new APTS_Language_Translation__c();
        tstDutch.APTS_Language__c = 'SAP_NL';
        tstDutch.APTS_Original_Text__c = 'Quarterly';
        tstDutch.APTS_Translated_Text__c = 'asdf';
        insert tstDutch;

        APTS_Language_Translation__c tstDutch1 = new APTS_Language_Translation__c();
        tstDutch1.APTS_Language__c = 'SAP_NL';
        tstDutch1.APTS_Original_Text__c = 'Tableware';
        tstDutch1.APTS_Translated_Text__c = 'Tableware';
        insert tstDutch1;
       
        APTS_Language_Translation__c tstDutch2 = new APTS_Language_Translation__c();
        tstDutch2.APTS_Language__c = 'SAP_NL';
        tstDutch2.APTS_Original_Text__c = 'Yearly';
        tstDutch2.APTS_Translated_Text__c = 'Tableware';
        insert tstDutch2;

        APTS_Language_Translation__c tstDutch3 = new APTS_Language_Translation__c();
        tstDutch3.APTS_Language__c = 'SAP_NL';
        tstDutch3.APTS_Original_Text__c = 'SAP_EA';
        tstDutch3.APTS_Translated_Text__c = 'Elk';
        insert tstDutch3;

        tstAgreeemnt = new Apttus__APTS_Agreement__c();
        tstAgreeemnt.APTS_Fixed_Term_Frequency__c = 'Quarterly';
        tstAgreeemnt.APTS_Language__c = 'SAP_NL';
        insert tstAgreeemnt;
    }


    static testMethod void testAgreement(){
        Test.startTest();
        Apttus__APTS_Agreement__c tstAggr = new Apttus__APTS_Agreement__c();
        tstAggr.APTS_Fixed_Term_Frequency__c = 'Quarterly';
        tstAggr.APTS_Language__c = 'SAP_NL';
        insert tstAggr;

        List<sObject> lstsObject = new List<sObject>();
        lstsObject.add(tstAggr);

        List<String> lstLang = new List<String>();
        lstLang.add('SAP_NL');

        APTS_LanguageTranslator.translateLanguage(lstsObject, 'Apttus__APTS_Agreement__c', lstLang);

        Test.stopTest();
        system.assertEquals('asdf',tstAggr.APTS_Fixed_Term_Settlement_Freq_Trans__c);
    }

    static testMethod void testALI(){
        Test.startTest();
        Apttus__AgreementLineItem__c tstALI = new Apttus__AgreementLineItem__c();
        tstALI.Apttus_CMConfig__Frequency__c = 'Quarterly';
        tstALI.Apttus__AgreementId__c = tstAgreeemnt.Id;
        insert tstALI;

        List<sObject> lstsObject = new List<sObject>();
        lstsObject.add(tstALI);

        List<String> lstLang = new List<String>();
        lstLang.add('SAP_NL');

        APTS_LanguageTranslator.translateLanguage(lstsObject, 'Apttus__AgreementLineItem__c', lstLang);

        Test.stopTest();
        
         system.assertEquals('asdf',tstALI.APTS_Pricing_Frequency_Translated__c);
    }

    static testMethod void testBudget(){
        Test.startTest();
        APTS_Agreement_Budget__c tstBudget = new APTS_Agreement_Budget__c();
        tstBudget.APTS_Category__c = 'Tableware';
        tstBudget.Agreement__c = tstAgreeemnt.Id;
        insert tstBudget;

        List<sObject> lstsObject = new List<sObject>();
        lstsObject.add(tstBudget);

        List<String> lstLang = new List<String>();
        lstLang.add('SAP_NL');

        APTS_LanguageTranslator.translateLanguage(lstsObject, 'APTS_Agreement_Budget__c', lstLang);

        /*tstBudget.APTS_Category__c = 'Promotions';
        update tstBudget;*/

        Test.stopTest();
        APTS_Agreement_Budget__c bgt = [Select Id,APTS_Category_Translated__c from APTS_Agreement_Budget__c];
        system.assertEquals('Tableware',bgt.APTS_Category_Translated__c);
    }

    static testMethod void testIndexContract(){
        Test.startTest();
        APTS_Index_Contract__c tstIndex = new APTS_Index_Contract__c();
        tstIndex.APTS_Frequency__c = 'Yearly';
        tstIndex.APTS_Contract__c = tstAgreeemnt.Id;
        insert tstIndex;

        List<sObject> lstsObject = new List<sObject>();
        lstsObject.add(tstIndex);

        List<String> lstLang = new List<String>();
        lstLang.add('SAP_NL');

        APTS_LanguageTranslator.translateLanguage(lstsObject, 'APTS_Index_Contract__c', lstLang);

        Test.stopTest();
        APTS_Index_Contract__c indexcntrct = [Select APTS_Agreement_Language__c,APTS_Indexation_Category__c,APTS_Index_Category_Translated__c,APTS_Frequency__c,APTS_Frequency_Translated__c,APTS_Communication_Deadline__c,APTS_Communication_Deadline_Translated__c from APTS_Index_Contract__c];
        system.assertEquals('SAP_NL',indexcntrct.APTS_Agreement_Language__c);
    }

    static testMethod void testKPISLA(){
        Test.startTest();
        Contracted_kpi_sla__c tstKPI = new Contracted_kpi_sla__c();
        tstKPI.kpi_frequency__c = 'Quarterly';
        tstKPI.kpi_contract__c = tstAgreeemnt.Id;
        insert tstKPI;

        List<sObject> lstsObject = new List<sObject>();
        lstsObject.add(tstKPI);

        List<String> lstLang = new List<String>();
        lstLang.add('SAP_NL');

        APTS_LanguageTranslator.translateLanguage(lstsObject, 'Contracted_kpi_sla__c', lstLang);

        Test.stopTest();
        Contracted_kpi_sla__c kpisla = [Select APTS_Agreement_Language__c,kpi_frequency__c,APTS_KPI_or_SLA_Frequency_Translated__c from Contracted_kpi_sla__c];
        system.assertEquals('SAP_NL',kpisla.APTS_Agreement_Language__c);
    }

    /*static testMethod void testBilling(){
        Test.startTest();
        Apttus_Config2__BillingPreference__c tstBilling = new Apttus_Config2__BillingPreference__c();
        tstBilling.Apttus_Config2__BillingInterval__c = 'Quarterly';
        tstBilling.Apttus_CMConfig__AgreementId__c = tstAgreeemnt.Id;
        insert tstBilling;

        List<sObject> lstsObject = new List<sObject>();
        lstsObject.add(tstBilling);

        List<String> lstLang = new List<String>();
        lstLang.add('SAP_NL');

        APTS_LanguageTranslator.translateLanguage(lstsObject, 'Apttus_Config2__BillingPreference__c', lstLang);

        Test.stopTest();
    }*/

    static testMethod void testRebate(){
        Test.startTest();
        APTS_RebateDefiniation__c tstRebate = new APTS_RebateDefiniation__c();
        tstRebate.APTS_BenefitUOM__c = 'SAP_EA';
        tstRebate.APTS_Agreement__c = tstAgreeemnt.Id;
        insert tstRebate;

        List<sObject> lstsObject = new List<sObject>();
        lstsObject.add(tstRebate);

        List<String> lstLang = new List<String>();
        lstLang.add('SAP_NL');

        APTS_LanguageTranslator.translateLanguage(lstsObject, 'APTS_RebateDefiniation__c', lstLang);

        Test.stopTest();
        APTS_RebateDefiniation__c rebatedef = [Select Id,APTS_Agreement_Language__c,APTS_BenefitUOM__c,APTS_Benefit_UOM_Translated__c,APTS_PayoutFrequency__c,APTS_Payout_Frequency_Translated__c from APTS_RebateDefiniation__c];
        system.assertEquals('SAP_NL',rebatedef.APTS_Agreement_Language__c);
        
    }

}