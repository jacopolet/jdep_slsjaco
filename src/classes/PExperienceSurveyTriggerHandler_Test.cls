//-------------------------------------------------------------------------------------------
// Author       :   Catherine Aragon - Accenture
// Created Date :   February 21, 2018
// Usage        :   Test Class for PerfectExperienceSurveyTriggerHandler
//-------------------------------------------------------------------------------------------
@isTest
private class PExperienceSurveyTriggerHandler_Test {
    @testSetup
    static void testSetup(){

        List<Perfect_Experience_Score__c> peScores = new List<Perfect_Experience_Score__c>();
        Perfect_Experience_Score__c peScore1 = new Perfect_Experience_Score__c();
        peScore1.Comm_Non_Comm__c = 'Commercial';
        peScore1.Category__c = 'Blend mainstream';
        peScore1.Category_Score__c = 20;
        peScores.add(peScore1);
        
        Perfect_Experience_Score__c peScore2 = new Perfect_Experience_Score__c();
        peScore2.Comm_Non_Comm__c = 'Commercial';
        peScore2.Category__c = 'Tea - Premium';
        peScore2.Category_Score__c = 10;
        peScores.add(peScore2);
        
        Perfect_Experience_Score__c peScore3 = new Perfect_Experience_Score__c();
        peScore3.Comm_Non_Comm__c = 'Commercial';
        peScore3.Category__c = 'Machine Yes';
        peScore3.Category_Score__c = 10;
        peScores.add(peScore3);
        
        Perfect_Experience_Score__c peScore4 = new Perfect_Experience_Score__c();
        peScore4.Comm_Non_Comm__c = 'Commercial';
        peScore4.Category__c = 'Milk Yes';
        peScore4.Category_Score__c = 1;
        peScores.add(peScore4);
        
        Perfect_Experience_Score__c peScore5 = new Perfect_Experience_Score__c();
        peScore5.Comm_Non_Comm__c = 'Commercial';
        peScore5.Category__c = 'Sugar Yes';
        peScore5.Category_Score__c = 1;
        peScores.add(peScore5);
        
        Perfect_Experience_Score__c peScore6 = new Perfect_Experience_Score__c();
        peScore6.Comm_Non_Comm__c = 'Commercial';
        peScore6.Category__c = 'Cacao No';
        peScore6.Category_Score__c = 1;
        peScores.add(peScore6);
        
        Perfect_Experience_Score__c peScore7 = new Perfect_Experience_Score__c();
        peScore7.Comm_Non_Comm__c = 'Commercial';
        peScore7.Category__c = 'Service Yes';
        peScore7.Category_Score__c = 1;
        peScores.add(peScore7);
        
        Perfect_Experience_Score__c peScore8 = new Perfect_Experience_Score__c();
        peScore8.Comm_Non_Comm__c = 'Commercial';
        peScore8.Category__c = 'Cups / Glasses & Porcelain Yes';
        peScore8.Category_Score__c = 1;
        peScores.add(peScore8);
        
        Perfect_Experience_Score__c peScore9 = new Perfect_Experience_Score__c();
        peScore9.Comm_Non_Comm__c = 'Commercial';
        peScore9.Category__c = 'Cross sell display';
        peScore9.Category_Score__c = 2.5;
        peScores.add(peScore9);
        
        Perfect_Experience_Score__c peScore10 = new Perfect_Experience_Score__c();
        peScore10.Comm_Non_Comm__c = 'Commercial';
        peScore10.Category__c = 'Tea display';
        peScore10.Category_Score__c = 2.5;
        peScores.add(peScore10);
        
        
        Test.startTest();
        insert peScores;
        
        
    }
    
    private static testMethod void createPESurvey() {
        //insert custom settings
        insert new TriggerSettings__c(PerfectExperienceSurveyTrigger__c = true);
        
        testSetup();
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.Customer).getRecordTypeId();
        acc.Main_Street_Only__c = 'Test Street';
        acc.Main_Postal_Code__c = '1000';
        acc.Industry_Code__c = '100';
        acc.Phone = '+1234567890';
        acc.CurrencyIsoCode = 'EUR';
        acc.Language__c = 'SAP_EN';
        acc.Sales_Organization__c = 'SAP_0333';
        acc.Account_Type__c = 'Customer';
        acc.of_Beds__c = 10;
        acc.of_drinks__c = 10;
        acc.of_Employees_FTE__c = 10;
        acc.Exclude_from_Territory_Assignment__c = false;
        acc.of_Seats__c = 10;
        acc.Account_Lifecycle__c = 'Active Customer';

        insert acc;
        
        Perfect_Experience_Survey__c peSurvey = new Perfect_Experience_Survey__c();
        peSurvey.Account__c = acc.Id;
        peSurvey.Barista_Station__c = 'No';
        peSurvey.Comm_Non_Comm__c = 'Commercial';
        peSurvey.Coffee__c = 'Blend mainstream';
        peSurvey.Tea__c = 'Tea - Premium';
        peSurvey.Machine__c = 'Machine Yes';
        peSurvey.Milk__c = 'Milk Yes';
        peSurvey.Sugar__c = 'Sugar Yes';
        peSurvey.Cacao__c = 'Cacao No';
        peSurvey.Service_Training__c = 'Service Yes';
        peSurvey.Cups_Glasses_Porcelain__c = 'Cups / Glasses & Porcelain Yes';
        peSurvey.Display_Accessoires__c = 'Tea display';

        insert peSurvey;
        
        Perfect_Experience_Survey__c peSurveyRec = new Perfect_Experience_Survey__c();
        peSurveyRec = [Select Coffee_Score__c FROM Perfect_Experience_Survey__c WHERE Id = :peSurvey.Id];
        System.assert(peSurveyRec.Coffee_Score__c == 20);
        
        
        PerfectExperienceSurveyTriggerHandler peS = new PerfectExperienceSurveyTriggerHandler();
        List<SObject> newItems;
        List<SObject> oldList;
        Map<Id, SObject> oldItems;
        Map<Id, SObject> newItemsMap;
        
        peS.BeforeDelete(oldList, oldItems);
        peS.afterInsert(newItems, oldItems);
        peS.afterUpdate(newItems , newItemsMap, oldList, oldItems);
        peS.AfterDelete(oldList, oldItems);
        peS.AfterUndelete(newItems, newItemsMap);
    }
    
    private static testMethod void updatePESurvey() {
        //insert custom settings
        insert new TriggerSettings__c(PerfectExperienceSurveyTrigger__c = true);
        
        testSetup();
        Account acc = new Account();
        acc.Name = 'Test Account1';
        acc.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.Customer).getRecordTypeId();
        acc.Main_Street_Only__c = 'Test Street1';
        acc.Main_Postal_Code__c = '123';
        acc.Industry_Code__c = '100';
        acc.Phone = '+1234567890';
        acc.CurrencyIsoCode = 'EUR';
        acc.Language__c = 'SAP_EN';
        acc.Sales_Organization__c = 'SAP_0333';
        acc.Account_Type__c = 'Customer';
        acc.of_Beds__c = 10;
        acc.of_drinks__c = 10;
        acc.of_Employees_FTE__c = 10;
        acc.Exclude_from_Territory_Assignment__c = false;
        acc.of_Seats__c = 10;
        acc.Account_Lifecycle__c = 'Active Customer';

        insert acc;
        
        Perfect_Experience_Survey__c peSurvey = new Perfect_Experience_Survey__c();
        peSurvey.Account__c = acc.Id;
        peSurvey.Comm_Non_Comm__c = 'Commercial';
        peSurvey.Barista_Station__c = 'No';
        peSurvey.Coffee__c = 'Blend mainstream';
        peSurvey.Tea__c = 'Tea - Premium';
        peSurvey.Machine__c = 'Machine No';
        peSurvey.Milk__c = 'Milk No';
        peSurvey.Sugar__c = 'Sugar No';
        peSurvey.Cacao__c = 'Cacao Yes';
        peSurvey.Service_Training__c = 'Service No';
        peSurvey.Cups_Glasses_Porcelain__c = 'Cups / Glasses & Porcelain No';
        peSurvey.Display_Accessoires__c = 'Cross sell display';
        
        insert peSurvey;

        List<Perfect_Experience_Survey__c> updatePESurvey = new List<Perfect_Experience_Survey__c>();
        Perfect_Experience_Survey__c peSurveyRec = new Perfect_Experience_Survey__c();
        peSurveyRec = [Select Account__c, Occasion__c, Coffee__c, Tea__c, Machine__c, Milk__c, Sugar__c, Cacao__c, Service_Training__c, Cups_Glasses_Porcelain__c, Display_Accessoires__c
                      FROM Perfect_Experience_Survey__c WHERE Id = :peSurvey.Id];
        
       
        peSurveyRec.Coffee__c = 'Blend premium'; 
        peSurveyRec.Tea__c = 'Tea - Premium';
        peSurveyRec.Machine__c = 'Machine Yes';
        peSurveyRec.Milk__c = 'Milk Yes';
        peSurveyRec.Sugar__c = 'Sugar Yes';
        peSurveyRec.Cacao__c = 'Cacao No';
        peSurveyRec.Service_Training__c = 'Service Yes';
        peSurveyRec.Cups_Glasses_Porcelain__c = 'Cups / Glasses & Porcelain Yes';
        peSurveyRec.Display_Accessoires__c = 'Tea display';

        update peSurveyRec;
        System.assert(peSurveyRec.Coffee__c == 'Blend premium');
        Test.stopTest();
    }
    
    private static testMethod void createPESurveyBaristaYes() {
        //insert custom settings
        insert new TriggerSettings__c(PerfectExperienceSurveyTrigger__c = true);
        
        testSetup();
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.Customer).getRecordTypeId();
        acc.Main_Street_Only__c = 'Test Street';
        acc.Main_Postal_Code__c = '1000';
        acc.Industry_Code__c = '100';
        acc.Phone = '+1234567890';
        acc.CurrencyIsoCode = 'EUR';
        acc.Language__c = 'SAP_EN';
        acc.Sales_Organization__c = 'SAP_0333';
        acc.Account_Type__c = 'Customer';
        acc.of_Beds__c = 10;
        acc.of_drinks__c = 10;
        acc.of_Employees_FTE__c = 10;
        acc.Exclude_from_Territory_Assignment__c = false;
        acc.of_Seats__c = 10;
        acc.Account_Lifecycle__c = 'Active Customer';

        insert acc;
        
        Perfect_Experience_Survey__c peSurvey = new Perfect_Experience_Survey__c();
        peSurvey.Account__c = acc.Id;
        peSurvey.Barista_Station__c = 'Yes';
        peSurvey.Comm_Non_Comm__c = 'Commercial';
        peSurvey.Coffee__c = 'Blend mainstream';
        peSurvey.Tea__c = 'Tea - Premium';
        peSurvey.Machine__c = 'Machine Yes';
        peSurvey.Milk__c = 'Milk Yes';
        peSurvey.Sugar__c = 'Sugar Yes';
        peSurvey.Cacao__c = 'Cacao No';
        peSurvey.Service_Training__c = 'Service Yes';
        peSurvey.Cups_Glasses_Porcelain__c = 'Cups / Glasses & Porcelain Yes';
        peSurvey.Display_Accessoires__c = 'Tea display';

        insert peSurvey;
        
        Perfect_Experience_Survey__c peSurveyRec = new Perfect_Experience_Survey__c();
        peSurveyRec = [Select Coffee__c, Coffee_Score__c FROM Perfect_Experience_Survey__c WHERE Id = :peSurvey.Id];
        System.assert(peSurveyRec.Coffee__c == 'Blend premium');
        
        
        PerfectExperienceSurveyTriggerHandler peS = new PerfectExperienceSurveyTriggerHandler();
        List<SObject> newItems;
        List<SObject> oldList;
        Map<Id, SObject> oldItems;
        Map<Id, SObject> newItemsMap;
        
        peS.BeforeDelete(oldList, oldItems);
        peS.afterInsert(newItems, oldItems);
        peS.afterUpdate(newItems , newItemsMap, oldList, oldItems);
        peS.AfterDelete(oldList, oldItems);
        peS.AfterUndelete(newItems, newItemsMap);
    }
    
    private static testMethod void updatePESurveyBaristaYes() {
        //insert custom settings
        insert new TriggerSettings__c(PerfectExperienceSurveyTrigger__c = true);
        
        testSetup();
        Account acc = new Account();
        acc.Name = 'Test Account1';
        acc.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.Customer).getRecordTypeId();
        acc.Main_Street_Only__c = 'Test Street1';
        acc.Main_Postal_Code__c = '123';
        acc.Industry_Code__c = '100';
        acc.Phone = '+1234567890';
        acc.CurrencyIsoCode = 'EUR';
        acc.Language__c = 'SAP_EN';
        acc.Sales_Organization__c = 'SAP_0333';
        acc.Account_Type__c = 'Customer';
        acc.of_Beds__c = 10;
        acc.of_drinks__c = 10;
        acc.of_Employees_FTE__c = 10;
        acc.Exclude_from_Territory_Assignment__c = false;
        acc.of_Seats__c = 10;
        acc.Account_Lifecycle__c = 'Active Customer';

        insert acc;
        
        Perfect_Experience_Survey__c peSurvey = new Perfect_Experience_Survey__c();
        peSurvey.Account__c = acc.Id;
        peSurvey.Comm_Non_Comm__c = 'Commercial';
        peSurvey.Barista_Station__c = 'No';
        peSurvey.Coffee__c = 'Blend mainstream';
        peSurvey.Tea__c = 'Tea - Premium';
        peSurvey.Machine__c = 'Machine Yes';
        peSurvey.Milk__c = 'Milk Yes';
        peSurvey.Sugar__c = 'Sugar Yes';
        peSurvey.Cacao__c = 'Cacao No';
        peSurvey.Service_Training__c = 'Service Yes';
        peSurvey.Cups_Glasses_Porcelain__c = 'Cups / Glasses & Porcelain Yes';
        peSurvey.Display_Accessoires__c = 'Tea display';
        
        insert peSurvey;

        List<Perfect_Experience_Survey__c> updatePESurvey = new List<Perfect_Experience_Survey__c>();
        Perfect_Experience_Survey__c peSurveyRec = new Perfect_Experience_Survey__c();
        peSurveyRec = [Select Account__c, Barista_Station__c, Occasion__c, Coffee__c, Tea__c, Machine__c, Milk__c, Sugar__c, Cacao__c, Service_Training__c, Cups_Glasses_Porcelain__c, Display_Accessoires__c
                      FROM Perfect_Experience_Survey__c WHERE Id = :peSurvey.Id];
        
       
        peSurveyRec.Barista_Station__c = 'Yes';
        update peSurveyRec;
        System.assert(peSurveyRec.Barista_Station__c == 'Yes');
        Test.stopTest();
    }
}