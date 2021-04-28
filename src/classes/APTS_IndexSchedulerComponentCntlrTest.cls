/*************************************************************
@Name: APTS_IndexSchedulerComponentCntlrTest
@Author: Shanmuga Prasath
@CreateDate: 26-03-2019
@Description: Test class for APTS_IndexSchedulerComponentController
******************************************************************/
@isTest
private without sharing class APTS_IndexSchedulerComponentCntlrTest{

    @isTest
    static void testNonStandardBatch(){
        Account acc = APTS_TestUtils.createaccount();
        acc.BillingCountry = 'SAP_NL';
        Database.insert(acc,false);
        
        Contact cont = APTS_TestUtils.createContact();
        Database.insert(cont,false);
        
        Apttus_Config2__PriceList__c plist = APTS_TestUtils.createPriceList();
        Database.insert(plist,false);
       
        List<Apttus__APTS_Agreement__c> agrlst = new List<Apttus__APTS_Agreement__c>(); 
       
        Apttus__APTS_Agreement__c aggr = APTS_TestUtils.createAgreement(cont.Id,null,plist.Id,acc.Id);
        aggr.Apttus__Contract_End_Date__c = System.today()-1;
        aggr.Apttus__Account__c = acc.Id;
        aggr.Apttus__Status_Category__c = 'In Effect';
        aggr.Apttus__Status__c = 'Activated';
        aggr.Apttus__Contract_Start_Date__c = System.today()-50;
        aggr.Apttus__Auto_Renewal__c = true;
        //aggr.APTS_Country__c = 'SAP_NL';
        agrlst.add(aggr);
        Database.insert(agrlst,false);
        

        APTS_Index_Contract__c indexContract = new APTS_Index_Contract__c();
        indexContract.APTS_Indexation_Category__c = 'Technical Services';
        indexContract.APTS_Index_Type__c = 'Non-Standard Indexation';
        indexContract.APTS_Execution_Date__c=system.today();
        indexContract.APTS_Frequency__c = 'Yearly';
        indexContract.APTS_Start_Date__c = system.today();
        indexContract.APTS_Contract__c = aggr.Id;
        indexContract.APTS_Indexation_Number__c = '1';                                          
        Insert indexContract;

        String result = APTS_IndexSchedulerComponentController.scheduleNonStandardBatch(String.valueOf(Date.Today()));
    }
    
    @isTest
    static void testupdateIndexrecords(){
    
        Account acc = APTS_TestUtils.createaccount();
        acc.BillingCountry = 'SAP_NL';
        Database.insert(acc,false);
        
        Contact cont = APTS_TestUtils.createContact();
        Database.insert(cont,false);
        
        Apttus_Config2__PriceList__c plist = APTS_TestUtils.createPriceList();
        Database.insert(plist,false);
       
        List<Apttus__APTS_Agreement__c> agrlst = new List<Apttus__APTS_Agreement__c>(); 
       
        Apttus__APTS_Agreement__c aggr = APTS_TestUtils.createAgreement(cont.Id,null,plist.Id,acc.Id);
        aggr.Apttus__Contract_End_Date__c = System.today()-1;
        aggr.Apttus__Account__c = acc.Id;
        aggr.Apttus__Status_Category__c = 'In Effect';
        aggr.Apttus__Status__c = 'Activated';
        aggr.Apttus__Contract_Start_Date__c = System.today()-50;
        aggr.Apttus__Auto_Renewal__c = true;
        //aggr.APTS_Country__c = 'SAP_NL';
        agrlst.add(aggr);
        Database.insert(agrlst,false);
        
        APTS_Index_Contract__c indexContract = new APTS_Index_Contract__c();
        indexContract.APTS_Indexation_Category__c = 'Technical Services';
        indexContract.APTS_Index_Type__c = 'Standard Indexation';
        indexContract.APTS_Frequency__c = 'Yearly';
        indexContract.APTS_Start_Date__c = system.today();
        indexContract.APTS_Contract__c = aggr.Id;
        indexContract.APTS_Indexation_Number__c = '1234';                                          
        Insert indexContract;
                                   
        APTS_Index_Contract__c indexContract1 = new APTS_Index_Contract__c();
        indexContract1.APTS_Indexation_Category__c = 'Technical Services';
        indexContract1.APTS_Index_Type__c = 'Standard Indexation';
        indexContract1.APTS_Frequency__c = 'Yearly';
        indexContract1.APTS_Start_Date__c = system.today();
        indexContract1.APTS_Contract__c = aggr.Id;
        indexContract1.APTS_Indexation_Number__c = '1234';
        indexContract1.APTS_Index_Type__c = 'Standard Indexation';                                            
        Insert indexContract1;
               
        String result = APTS_IndexSchedulerComponentController.updateIndexContracts('SAP_NL', String.Valueof(100), String.Valueof(20));
        //List<APTS_Indexation_Executing__c> executelst = APTS_IndexSchedulerComponentController.getIndexExecuting();
        string result1 = APTS_IndexSchedulerComponentController.getStandardReportId();
        string result2 = APTS_IndexSchedulerComponentController.displayReportIndexTransactions();
        string result3 = APTS_IndexSchedulerComponentController.getNonStandardReportId();
        //string result4 = APTS_IndexSchedulerComponentController.startTransactionBatch();
        string result5 = APTS_IndexSchedulerComponentController.deleteTransactionBatch();
        APTS_IndexSchedulerComponentController.getPicklistvalues(indexContract1,'APTS_Index_Type__c');
                
    }
    
    @isTest
    static void testStandardBatch(){
        String result = APTS_IndexSchedulerComponentController.scheduleStandardBatch('SAP_NL');
    }
    
}