//-------------------------------------------------------------------------------------------
// Author       :   Catherine Aragon - Accenture
// Created Date :   March 28, 2017
// Usage        :   Test Class for AccountLocationTriggerHandler
//-------------------------------------------------------------------------------------------
@isTest
private class AccountLocationTriggerHandler_Test {
    
    @testSetup
    static void testSetup(){
        
        insert new TriggerSettings__c(AccountLocationTrigger__c = true);
        
        MiniTemplateTax__c mtt = new MiniTemplateTax__c();
        mtt.Name = 'SAP-0033 -1';
        mtt.Sales_Organization__c = 'SAP_0333';
        insert mtt;
        
        String recordTypeId = Schema.SObjectType.CountrySetting__c.getRecordTypeInfosByName().get('Route Sales Setting').getRecordTypeId();
        CountrySetting__c cset = new CountrySetting__c();
        cset.Country__c = 'SAP_0333';
        cset.RecordTypeId = recordTypeId;
        cset.Active__c = true;
        insert cset;
        
        /*
        List<Apttus_Config2__AccountLocation__c> acctLocList = new List<Apttus_Config2__AccountLocation__c>();
        for(Apttus_Config2__AccountLocation__c acctLoc : TestDataFactory.createAccountLocation(100)){
            acctLoc.Sales_Office__c = null;
            acctLocList.add(acctLoc);
        }
        */
        
        Id alRO = Schema.SObjectType.Apttus_Config2__AccountLocation__c.getRecordTypeInfosByName().get('Account Location RO').getRecordTypeId();
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        List<Apttus_Config2__AccountLocation__c> acctLocList = new List<Apttus_Config2__AccountLocation__c>();
        
        for(integer x = 0; x<=5; x++){
            Apttus_Config2__AccountLocation__c acctLoc = new Apttus_Config2__AccountLocation__c();
            acctLoc.RecordTypeId = alRO;
            acctLoc.Copy_of_Parent_Account__c = true;
            acctLoc.Apttus_Config2__AccountId__c = acc.Id;
            acctLoc.Name = 'SAMP';
            acctLoc.Customer_calendar_key__c = 'SAP_32';
            acctLoc.Mini_Language__c = 'SAP_FR';
            acctLoc.Pallet_type__c = 'SAP_007';
            acctLoc.Saturday_Afternoon_From_Receiving__c = '14:30';
            acctLoc.Saturday_Afternoon_To_Receiving__c = '15:00';
            acctLoc.Saturday_Morning_From_Receiving__c = '02:45';
            acctLoc.Saturday_Morning_To_Receiving__c = '02:15';
            acctLoc.Sunday_Afternoon_From_Receiving__c = '15:15';
            acctLoc.Sunday_Afternoon_To_Receiving__c = '15:30';
            acctLoc.Sunday_Morning_From_Receiving__c = '03:30';
            acctLoc.Sunday_Morning_To_Receiving__c = '   01:00';
            acctLocList.add(acctLoc);
        }
        
        insert acctLocList;

        //XEN REYES DOO-4539 June 19, 2020
        List<CountrySetting__c> cset_calendar_list = new List<CountrySetting__c>();
    
        CountrySetting__c cset_calendar_BE = new CountrySetting__c();
        cset_calendar_BE.Active__c = true;
        cset_calendar_BE.Country__c = 'SAP_0333';
        cset_calendar_BE.RecordTypeId = Schema.SObjectType.CountrySetting__c.getRecordTypeInfosByName().get(TS_Constants.TS_COUNTRYSETTING_RECORDTYPE_DEFAULT_CALENDAR).getRecordTypeId();
        cset_calendar_BE.StartofBusinessDay__c = '08h00';
        cset_calendar_BE.EndofBusinessDay__c = '17h00';
        cset_calendar_BE.MondayException__c = 'O';
        cset_calendar_BE.TuesdayException__c = 'O';
        cset_calendar_BE.WednesdayException__c = 'A';
        cset_calendar_BE.ThursdayException__c = 'O';
        cset_calendar_BE.FridayException__c = 'P';
        cset_calendar_BE.Business_Unit__c = 'TCS';
        cset_calendar_list.add(cset_calendar_BE);

        CountrySetting__c cset_calendar_NL = new CountrySetting__c();
        cset_calendar_NL.Active__c = true;
        cset_calendar_NL.Country__c = 'SAP_0111';
        cset_calendar_NL.RecordTypeId = Schema.SObjectType.CountrySetting__c.getRecordTypeInfosByName().get(TS_Constants.TS_COUNTRYSETTING_RECORDTYPE_DEFAULT_CALENDAR).getRecordTypeId();
        cset_calendar_NL.StartofBusinessDay__c = '08h00';
        cset_calendar_NL.EndofBusinessDay__c = '17h00';
        cset_calendar_NL.MondayException__c = 'O';
        cset_calendar_NL.TuesdayException__c = 'O';
        cset_calendar_NL.WednesdayException__c = 'A';
        cset_calendar_NL.ThursdayException__c = 'O';
        cset_calendar_NL.FridayException__c = 'P';
        cset_calendar_NL.Business_Unit__c = 'TCS';
        cset_calendar_list.add(cset_calendar_NL);

        insert cset_calendar_list;                
    }
    
    private static testMethod void AfterInsert_createIntegratinLogs_Test()
    {   
        
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        User u = new User(Alias = 'standt', Email='sample@testUser1.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sample@testUser1.com', Sales_Organization__c = 'SAP_0333',  Elevated_Access_Reason__c = 'Defect or Incident Resolution', Elevated_Access_Reference__c = 'ASDF');

        System.runAs(u) {
            
            Id al = Schema.SObjectType.Apttus_Config2__AccountLocation__c.getRecordTypeInfosByName().get('Account Location').getRecordTypeId();
            Account acc = new Account();
            acc.Name = 'accName1';
            acc.Second_Account_Name__c = 'sAccName1';
            acc.Phone = '+31302979111';
            insert acc;
            
            List<Apttus_Config2__AccountLocation__c> accLocList = new List<Apttus_Config2__AccountLocation__c>();
          
            Apttus_Config2__AccountLocation__c acctLoc = new Apttus_Config2__AccountLocation__c();
            acctLoc.RecordTypeId = al;
            acctLoc.Copy_of_Parent_Account__c = true;
            acctLoc.Apttus_Config2__AccountId__c = acc.Id;
            acctLoc.Name = 'SAMP ';
            acctLoc.Customer_calendar_key__c = 'SAP_32';
            acctLoc.Mini_Language__c = 'SAP_FR';
            acctLoc.Pallet_type__c = 'SAP_007';
            acctLoc.SAP_Customer_ID__c = '890391892';
            acctLoc.Saturday_Afternoon_From_Receiving__c = '14:30';
            acctLoc.Saturday_Afternoon_To_Receiving__c = '15:00';
            acctLoc.Saturday_Morning_From_Receiving__c = '02:45';
            acctLoc.Saturday_Morning_To_Receiving__c = '02:15';
            acctLoc.Sunday_Afternoon_From_Receiving__c = '15:15';
            acctLoc.Sunday_Afternoon_To_Receiving__c = '15:30';
            acctLoc.Sunday_Morning_From_Receiving__c = '03:30';
            acctLoc.Sunday_Morning_To_Receiving__c = '   01:00';
            acctLoc.Shipping_Address_Validation_Timestamp__c = date.Today();
            acctLoc.Shipping_Address_Validation_Pending__c = false;
            acctLoc.Shipping_Address_Validation_Code__c = '90379120udojdlw';
            acctLoc.Address_Validation__c = 'Valid';
            acctLoc.Mini_Sales_Organization__c = 'SAP_0333';
            acctLoc.Duplicate_Reason__c = 'Office building';
            
            
            //Mini_Template__c miniTemplate = Mini_Template__c.getInstance(u.Sales_Organization__c);
            List<MiniTemplateTax__c> miniTemplateTaxes = MiniTemplateTax__c.getall().values();
            
            test.startTest();
            checkRecursive.run = true;
            AccountLocationTriggerHandlerHelper.integLogFirstTime = true;
            insert acctLoc;
           
            
            Apttus_Config2__AccountLocation__c accLocRec = [Select Id, Shipping_Address_Validation_Timestamp__c FROM Apttus_Config2__AccountLocation__c
                                                        WHERE Shipping_Address_Validation_Timestamp__c =: date.Today() and Shipping_Address_Validation_Pending__c = false];
        
            system.assertequals(accLocRec.Shipping_Address_Validation_Timestamp__c, date.Today());
            test.stopTest();
        }
    }
    
    private static testMethod void AfterUpdate_createIntegratinLogs_Test()
    {   
        Id recTypeIdALValid = Schema.SObjectType.Apttus_Config2__AccountLocation__c.getRecordTypeInfosByName().get('Account Location Valid').getRecordTypeId();
        Id recTypeIdAL = Schema.SObjectType.Apttus_Config2__AccountLocation__c.getRecordTypeInfosByName().get('Account Location').getRecordTypeId();
        Id recTypeIdPR = Schema.SObjectType.Apttus_Config2__AccountLocation__c.getRecordTypeInfosByName().get('Promotion Requested').getRecordTypeId();
        
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        User u = new User(Alias = 'standt', Email='sample@testUser1.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sample@testUser1.com', Sales_Organization__c = 'SAP_0111',  Elevated_Access_Reason__c = 'Defect or Incident Resolution', Elevated_Access_Reference__c = 'ASDF');
        insert u;
        
        
        System.runAs(u) {
            
            Id alRO = Schema.SObjectType.Apttus_Config2__AccountLocation__c.getRecordTypeInfosByName().get('Account Location RO').getRecordTypeId();
            Account acc = new Account();
            acc.Name = 'accName';
            acc.Second_Account_Name__c = 'sAccName';
            //acc.Sales_Office__c = 'SAP_F020';
            acc.Phone = '+31302979111';
            insert acc;
            
            List<Apttus_Config2__AccountLocation__c> accLocList = new List<Apttus_Config2__AccountLocation__c>();
            for(integer x = 0; x<=1; x++){
                Apttus_Config2__AccountLocation__c accLoc = new Apttus_Config2__AccountLocation__c();
                accLoc.RecordTypeId = recTypeIdALValid;
                accLoc.Apttus_Config2__AccountId__c = acc.Id;
                accLoc.Shipping_Address_Validation_Code__c = '90379120udojdl';
                accLoc.Shipping_Address_Validation_Timestamp__c = date.Today();
                accLoc.Shipping_Address_Validation_Pending__c = false;
                accLoc.Address_Validation__c = 'Valid';
                accLoc.Customer_calendar_key__c = 'SAP_32';
                accLoc.Mini_Language__c = 'SAP_SR';
                //accLoc.Pallet_type__c = 'SAP_004';
                accLoc.Apttus_Config2__City__c = 'City';
                accLoc.Apttus_Config2__Country__c = 'Country';
                accLoc.Shipping_Country_ISO__c = 'Country ISO';
                accLoc.Shipping_House_Number__c = 'House Number';
                accLoc.Apttus_Config2__PostalCode__c = 'PostalCode';
                accLoc.Apttus_Config2__State__c = 'State';
                //accLoc.Shipping_Street__c = 'Street';
                accLoc.Shipping_Street_Only__c = 'Street Only';
                accLoc.Saturday_Afternoon_From_Receiving__c = '13:30';
                accLoc.Saturday_Afternoon_To_Receiving__c = '12:45';
                accLoc.Saturday_Morning_From_Receiving__c = '01:45';
                accLoc.Saturday_Morning_To_Receiving__c = '01:15';
                accLoc.Sunday_Afternoon_From_Receiving__c = '14:15';
                accLoc.Sunday_Afternoon_To_Receiving__c = '14:30';
                accLoc.Sunday_Morning_From_Receiving__c = '00:30';
                accLoc.Sunday_Morning_To_Receiving__c = '   03:00';
                accLoc.Mini_Sales_Organization__c = 'SAP_0111';
                accLocList.add(accLoc);
            }
            //Mini_Template__c miniTemplate = Mini_Template__c.getInstance(u.Sales_Organization__c);
            List<MiniTemplateTax__c> miniTemplateTaxes = MiniTemplateTax__c.getall().values();
            insert accLocList;
            
            accLocList[0].SAP_Customer_ID__c = '12345';
            accLocList[0].RecordTypeId = recTypeIdAL;

            System.debug('u: ' + u);
            System.debug('miniTemplateTaxes: ' + miniTemplateTaxes);
            
            test.startTest();
            checkRecursive.run = true;
            AccountLocationTriggerHandlerHelper.integLogFirstTime = true;
            update accLocList[0];
            
            accLocList[0].Pallet_type__c = 'SAP_004';
            update accLocList[0];
            
            accLocList[0].SAP_PO_Updated__c = true;
            accLocList[0].EPI_Field_Updated__c = true;
            accLocList[0].RecordTypeId = recTypeIdPR;
            update accLocList[0];
            
            accLocList[0].Address_Validation__c = 'Not Valid';
            accLocList[0].SAP_PO_Updated__c = false;
            update accLocList[0];
            
            accLocList[0].Address_Validation__c = 'Valid';
            update accLocList[0];
            
            
            test.stopTest();
            
            List <Apttus_Config2__AccountLocation__c> accLocRec = [Select Id FROM Apttus_Config2__AccountLocation__c
                                                        WHERE Shipping_Address_Validation_Timestamp__c =: date.Today() and Shipping_Address_Validation_Pending__c = false];
        
            system.assertequals(accLocRec.size(),2);

        }
    }
    
     private static testMethod void TestUpdateLogicAL(){   
        
        Id recTypeIdAL = Schema.SObjectType.Apttus_Config2__AccountLocation__c.getRecordTypeInfosByName().get('Account Location RO').getRecordTypeId();
         
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        Apttus_Config2__AccountLocation__c acctLoc = new Apttus_Config2__AccountLocation__c();
        acctLoc.Copy_of_Parent_Account__c = true;
        acctLoc.Apttus_Config2__AccountId__c = acc.Id;
        acctLoc.Name = 'SAMP';
        acctLoc.Mini_Language__c = 'SAP_FR';
        acctLoc.Pallet_type__c = 'SAP_007';
        acctLoc.SAP_Customer_ID__c = '1239710';
        acctLoc.Saturday_Afternoon_From_Receiving__c = '12:30';
        acctLoc.Saturday_Afternoon_To_Receiving__c = '13:45';
        acctLoc.Saturday_Morning_From_Receiving__c = '02:45';
        acctLoc.Saturday_Morning_To_Receiving__c = '02:15';
        acctLoc.Sunday_Afternoon_From_Receiving__c = '15:15';
        acctLoc.Sunday_Afternoon_To_Receiving__c = '15:30';
        acctLoc.Sunday_Morning_From_Receiving__c = '01:30';
        acctLoc.Sunday_Morning_To_Receiving__c = '02:00';
        acctLoc.Monday_Afternoon_From_Receiving__c = '12:30';
        acctLoc.Monday_Afternoon_To_Receiving__c = '14:00';
        acctLoc.Monday_Morning_From_Receiving__c = '02:30';
        acctLoc.Monday_Morning_To_Receiving__c = '12:00';
        acctLoc.Tuesday_Afternoon_From_Receiving__c = '13:00';
        acctLoc.Tuesday_Afternoon_To_Receiving__c = '14:00';
        acctLoc.Tuesday_Morning_From_Receiving__c = '05:15';
        acctLoc.Tuesday_Morning_To_Receiving__c = '07:15';
        acctLoc.Wednesday_Afternoon_From_Receiving__c = '12:00';
        acctLoc.Wednesday_Afternoon_To_Receiving__c = '15:00';
        acctLoc.Wednesday_Morning_From_Receiving__c = '08:15';
        acctLoc.Wednesday_Morning_To_Receiving__c = '12:00';
        acctLoc.Thursday_Afternoon_From_Receiving__c = '15:00';
        acctLoc.Thursday_Afternoon_To_Receiving__c = '19:00';
        acctLoc.Thursday_Morning_From_Receiving__c = '08:00';
        acctLoc.Thursday_Morning_To_Receiving__c = '12:00';
        acctLoc.Friday_Afternoon_From_Receiving__c = '15:00';
        acctLoc.Friday_Afternoon_To_Receiving__c = '17:00';

        acctLoc.Friday_Morning_To_Receiving__c = '12:00';
        acctLoc.Address_Validation__c = 'Valid';
        acctLoc.RecordTypeId = recTypeIdAL;
        insert acctLoc;
        
        Apttus_Config2__AccountLocation__c updateAL = new Apttus_Config2__AccountLocation__c();
        updateAL = [Select Id, Name FROM Apttus_Config2__AccountLocation__c WHERE Id = :acctLoc.Id];
        updateAL.Customer_calendar_key__c = 'SAP_32';
        updateAL.Name = 'SAMP Edit';
        updateAL.Mini_Language__c = 'SAP_SR';
        updateAL.Pallet_type__c = 'SAP_004';
        updateAL.Apttus_Config2__City__c = 'City';
        updateAL.Apttus_Config2__Country__c = 'Country';
        updateAL.Shipping_Country_ISO__c = 'Country ISO';
        updateAL.Shipping_House_Number__c = 'House Number';
        updateAL.Apttus_Config2__PostalCode__c = 'PostalCode';
        updateAL.Apttus_Config2__State__c = 'State';
        //updateAL.Shipping_Street__c = 'Street';
        updateAL.Shipping_Street_Only__c = 'Street Only';
        updateAL.Saturday_Afternoon_From_Receiving__c = '13:30';
        updateAL.Saturday_Afternoon_To_Receiving__c = '12:45';
        updateAL.Saturday_Morning_From_Receiving__c = '01:45';
        updateAL.Saturday_Morning_To_Receiving__c = '01:15';
        updateAL.Sunday_Afternoon_From_Receiving__c = '14:15';
        updateAL.Sunday_Afternoon_To_Receiving__c = '14:30';
        updateAL.Sunday_Morning_From_Receiving__c = '00:30';
        updateAL.Sunday_Morning_To_Receiving__c = '03:00';
        updateAL.Monday_Afternoon_From_Receiving__c = '13:30';
        updateAL.Monday_Afternoon_To_Receiving__c = '15:00';
        updateAL.Monday_Morning_From_Receiving__c = '03:30';
        updateAL.Monday_Morning_To_Receiving__c = '11:00';
        updateAL.Tuesday_Afternoon_From_Receiving__c = '14:00';
        updateAL.Tuesday_Afternoon_To_Receiving__c = '15:00';
        updateAL.Tuesday_Morning_From_Receiving__c = '04:15';
        updateAL.Tuesday_Morning_To_Receiving__c = '06:15';
        updateAL.Wednesday_Afternoon_From_Receiving__c = '14:00';
        updateAL.Wednesday_Afternoon_To_Receiving__c = '16:00';
        updateAL.Wednesday_Morning_From_Receiving__c = '09:15';
        updateAL.Wednesday_Morning_To_Receiving__c = '11:00';
        updateAL.Thursday_Afternoon_From_Receiving__c = '14:00';
        updateAL.Thursday_Afternoon_To_Receiving__c = '18:00';
        updateAL.Thursday_Morning_From_Receiving__c = '07:00';
        updateAL.Thursday_Morning_To_Receiving__c = '11:00';
        updateAL.Friday_Afternoon_From_Receiving__c = '14:00';
        updateAL.Friday_Afternoon_To_Receiving__c = '16:00';
        updateAL.Friday_Morning_From_Receiving__c = '08:15';
        updateAL.Friday_Morning_To_Receiving__c = '11:00';
        checkRecursive.run = true;
        update updateAL;

        Apttus_Config2__AccountLocation__c accLocRec = [Select Id FROM Apttus_Config2__AccountLocation__c
                                                        WHERE id =: acctLoc.id];
        
            system.assertequals(accLocRec.id, updateAL.id);
 
       
    }
    
     private static testMethod void TestRequestAddressValidation(){   
        
        Id recTypeIdAL = Schema.SObjectType.Apttus_Config2__AccountLocation__c.getRecordTypeInfosByName().get('Account Location').getRecordTypeId();
         
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        Apttus_Config2__AccountLocation__c acctLoc = new Apttus_Config2__AccountLocation__c();
        acctLoc.Customer_calendar_key__c = 'SAP_32';
        acctLoc.Apttus_Config2__AccountId__c = acc.Id;
        acctLoc.Name = 'SAMP Edit';
        acctLoc.Mini_Language__c = 'SAP_SR';
        acctLoc.Pallet_type__c = 'SAP_004';
        acctLoc.Apttus_Config2__City__c = 'City';
        acctLoc.Apttus_Config2__Country__c = 'Country';
        acctLoc.Shipping_Country_ISO__c = 'Country ISO';
        acctLoc.Shipping_House_Number__c = 'House Number';
        acctLoc.Apttus_Config2__PostalCode__c = 'PostalCode';
        acctLoc.Apttus_Config2__State__c = 'State';
        acctLoc.Shipping_Street_Only__c = 'Street Only';
        acctLoc.House_Number_Supplement__c = 'SAMP TEst';
        acctLoc.SAP_Customer_ID__c = '1239710';
        acctLoc.Saturday_Afternoon_From_Receiving__c = '12:30';
        acctLoc.Saturday_Afternoon_To_Receiving__c = '13:45';
        acctLoc.Saturday_Morning_From_Receiving__c = '02:45';
        acctLoc.Saturday_Morning_To_Receiving__c = '02:15';
        acctLoc.Sunday_Afternoon_From_Receiving__c = '15:15';
        acctLoc.Sunday_Afternoon_To_Receiving__c = '15:30';
        acctLoc.Sunday_Morning_From_Receiving__c = '01:30';
        acctLoc.Sunday_Morning_To_Receiving__c = '02:00';
        acctLoc.Monday_Afternoon_From_Receiving__c = '12:30';
        acctLoc.Monday_Afternoon_To_Receiving__c = '14:00';
        acctLoc.Monday_Morning_From_Receiving__c = '02:30';
        acctLoc.Monday_Morning_To_Receiving__c = '12:00';
        acctLoc.Tuesday_Afternoon_From_Receiving__c = '13:00';
        acctLoc.Tuesday_Afternoon_To_Receiving__c = '14:00';
        acctLoc.Tuesday_Morning_From_Receiving__c = '05:15';
        acctLoc.Tuesday_Morning_To_Receiving__c = '07:15';
        acctLoc.Wednesday_Afternoon_From_Receiving__c = '12:00';
        acctLoc.Wednesday_Afternoon_To_Receiving__c = '15:00';
        acctLoc.Wednesday_Morning_From_Receiving__c = '08:15';
        acctLoc.Wednesday_Morning_To_Receiving__c = '12:00';
        acctLoc.Thursday_Afternoon_From_Receiving__c = '15:00';
        acctLoc.Thursday_Afternoon_To_Receiving__c = '19:00';
        acctLoc.Thursday_Morning_From_Receiving__c = '08:00';
        acctLoc.Thursday_Morning_To_Receiving__c = '12:00';
        acctLoc.Friday_Afternoon_From_Receiving__c = '15:00';
        acctLoc.Friday_Afternoon_To_Receiving__c = '17:00';
        acctLoc.Friday_Morning_To_Receiving__c = '12:00';
        acctLoc.Address_Validation__c = 'Request Address Validation';
        acctLoc.Shipping_Address_Validation_Timestamp__c = date.today();
        insert acctLoc;
        
        Apttus_Config2__AccountLocation__c updateAL = new Apttus_Config2__AccountLocation__c();
        updateAL = [Select Id, Name FROM Apttus_Config2__AccountLocation__c WHERE Id = :acctLoc.Id];
        updateAL.Address_Validation__c = 'Valid';
        checkRecursive.run = true;
        update updateAL;

        Apttus_Config2__AccountLocation__c accLocRec = [Select Id FROM Apttus_Config2__AccountLocation__c
                                                        WHERE id =: acctLoc.id];
        
            system.assertequals(accLocRec.id, updateAL.id);
 
       
    }
    
    private static testMethod void testSapreturn() {
        Id recTypeIdAL = Schema.SObjectType.Apttus_Config2__AccountLocation__c.getRecordTypeInfosByName().get('Account Location Validation').getRecordTypeId();
         
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Phone = '+31302979111';
        insert acc;
        
        Apttus_Config2__AccountLocation__c acctLoc = new Apttus_Config2__AccountLocation__c();
        acctLoc.Copy_of_Parent_Account__c = true;
        acctLoc.Apttus_Config2__AccountId__c = acc.Id;
        acctLoc.Name = 'SAMP';
        acctLoc.Mini_Language__c = 'SAP_FR';
        acctLoc.Pallet_type__c = 'SAP_007';
        acctLoc.Saturday_Afternoon_From_Receiving__c = '12:30';
        acctLoc.Saturday_Afternoon_To_Receiving__c = '13:45';
        acctLoc.Saturday_Morning_From_Receiving__c = '02:45';
        acctLoc.Saturday_Morning_To_Receiving__c = '02:15';
        acctLoc.Sunday_Afternoon_From_Receiving__c = '15:15';
        acctLoc.Sunday_Afternoon_To_Receiving__c = '15:30';
        acctLoc.Sunday_Morning_From_Receiving__c = '01:30';
        acctLoc.Sunday_Morning_To_Receiving__c = '02:00';
        acctLoc.Monday_Afternoon_From_Receiving__c = '12:30';
        acctLoc.Monday_Afternoon_To_Receiving__c = '14:00';
        acctLoc.Monday_Morning_From_Receiving__c = '02:30';
        acctLoc.Monday_Morning_To_Receiving__c = '12:00';
        acctLoc.Tuesday_Afternoon_From_Receiving__c = '13:00';
        acctLoc.Tuesday_Afternoon_To_Receiving__c = '14:00';
        acctLoc.Tuesday_Morning_From_Receiving__c = '05:15';
        acctLoc.Tuesday_Morning_To_Receiving__c = '07:15';
        acctLoc.Wednesday_Afternoon_From_Receiving__c = '12:00';
        acctLoc.Wednesday_Afternoon_To_Receiving__c = '15:00';
        acctLoc.Wednesday_Morning_From_Receiving__c = '08:15';
        acctLoc.Wednesday_Morning_To_Receiving__c = '12:00';
        acctLoc.Thursday_Afternoon_From_Receiving__c = '15:00';
        acctLoc.Thursday_Afternoon_To_Receiving__c = '19:00';
        acctLoc.Thursday_Morning_From_Receiving__c = '08:00';
        acctLoc.Thursday_Morning_To_Receiving__c = '12:00';
        acctLoc.Friday_Afternoon_From_Receiving__c = '15:00';
        acctLoc.Friday_Afternoon_To_Receiving__c = '17:00';
        acctLoc.Friday_Morning_From_Receiving__c = '09:15';
        acctLoc.Friday_Morning_To_Receiving__c = '12:00';
        acctLoc.Address_Validation__c = 'Valid';
        acctLoc.RecordTypeId = recTypeIdAL;
        insert acctLoc;
        
        acctLoc.SAP_PO_Updated__c = true;
        acctLoc.EPI_Field_Updated__c = true;
        acctLoc.SAP_Customer_ID__c = '78948923';
        AccountLocationTriggerHandlerHelper.integLogFirstTime = true;
        checkRecursive.run = true;
        update acctLoc;
        
        System.assertequals(acctLoc.SAP_PO_Updated__c, true);
        
    }
    
     private static testMethod void TestAddressValitionStamp(){   
        
        Id recTypeIdAL = Schema.SObjectType.Apttus_Config2__AccountLocation__c.getRecordTypeInfosByName().get('Account Location RO').getRecordTypeId();
         
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Phone = '+31302979111';
        insert acc;
        
        Apttus_Config2__AccountLocation__c acctLoc = new Apttus_Config2__AccountLocation__c();
        acctLoc.Copy_of_Parent_Account__c = true;
        acctLoc.Apttus_Config2__AccountId__c = acc.Id;
        acctLoc.Name = 'SAMP';
        acctLoc.Mini_Language__c = 'SAP_FR';
        acctLoc.Pallet_type__c = 'SAP_007';
        acctLoc.SAP_Customer_ID__c = '1239710';
        acctLoc.Saturday_Afternoon_From_Receiving__c = '12:30';
        acctLoc.Saturday_Afternoon_To_Receiving__c = '13:45';
        acctLoc.Saturday_Morning_From_Receiving__c = '02:45';
        acctLoc.Saturday_Morning_To_Receiving__c = '02:15';
        acctLoc.Sunday_Afternoon_From_Receiving__c = '15:15';
        acctLoc.Sunday_Afternoon_To_Receiving__c = '15:30';
        acctLoc.Sunday_Morning_From_Receiving__c = '01:30';
        acctLoc.Sunday_Morning_To_Receiving__c = '02:00';
        acctLoc.Monday_Afternoon_From_Receiving__c = '12:30';
        acctLoc.Monday_Afternoon_To_Receiving__c = '14:00';
        acctLoc.Monday_Morning_From_Receiving__c = '02:30';
        acctLoc.Monday_Morning_To_Receiving__c = '12:00';
        acctLoc.Tuesday_Afternoon_From_Receiving__c = '13:00';
        acctLoc.Tuesday_Afternoon_To_Receiving__c = '14:00';
        acctLoc.Tuesday_Morning_From_Receiving__c = '05:15';
        acctLoc.Tuesday_Morning_To_Receiving__c = '07:15';
        acctLoc.Wednesday_Afternoon_From_Receiving__c = '12:00';
        acctLoc.Wednesday_Afternoon_To_Receiving__c = '15:00';
        acctLoc.Wednesday_Morning_From_Receiving__c = '08:15';
        acctLoc.Wednesday_Morning_To_Receiving__c = '12:00';
        acctLoc.Thursday_Afternoon_From_Receiving__c = '15:00';
        acctLoc.Thursday_Afternoon_To_Receiving__c = '19:00';
        acctLoc.Thursday_Morning_From_Receiving__c = '08:00';
        acctLoc.Thursday_Morning_To_Receiving__c = '12:00';
        acctLoc.Friday_Afternoon_From_Receiving__c = '15:00';
        acctLoc.Friday_Afternoon_To_Receiving__c = '17:00';
        acctLoc.Friday_Morning_To_Receiving__c = '12:00';
        acctLoc.Address_Validation__c = 'Not Valid';
        acctLoc.Shipping_Address_Validation_Timestamp__c = date.today();
        acctLoc.RecordTypeId = recTypeIdAL;
        insert acctLoc;
        
       
        Apttus_Config2__AccountLocation__c accLocRec = [Select Id, Address_Validation__c FROM Apttus_Config2__AccountLocation__c
                                                        WHERE id =: acctLoc.id];
        
        System.assertequals(accLocRec.Address_Validation__c, 'Valid');
 
       
    }
    
    private static testMethod void TestRecordTypeDigital(){   
        
        Id recTypeIdAL = Schema.SObjectType.Apttus_Config2__AccountLocation__c.getRecordTypeInfosByName().get('Account Location Valid').getRecordTypeId();
        Id recTypeIdAccountLocationRO = Schema.SObjectType.Apttus_Config2__AccountLocation__c.getRecordTypeInfosByName().get('Account Location RO').getRecordTypeId();
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Phone = '+31302979111';
        insert acc;
        
        Apttus_Config2__AccountLocation__c acctLoc = new Apttus_Config2__AccountLocation__c();
        acctLoc.Copy_of_Parent_Account__c = true;
        acctLoc.Apttus_Config2__AccountId__c = acc.Id;
        acctLoc.Name = 'SAMP';
        acctLoc.Mini_Language__c = 'SAP_FR';
        acctLoc.Pallet_type__c = 'SAP_007';
        acctLoc.SAP_Customer_ID__c = '1239710';
        acctLoc.Saturday_Afternoon_From_Receiving__c = '12:30';
        acctLoc.Saturday_Afternoon_To_Receiving__c = '13:45';
        acctLoc.Saturday_Morning_From_Receiving__c = '02:45';
        acctLoc.Saturday_Morning_To_Receiving__c = '02:15';
        acctLoc.Sunday_Afternoon_From_Receiving__c = '15:15';
        acctLoc.Sunday_Afternoon_To_Receiving__c = '15:30';
        acctLoc.Sunday_Morning_From_Receiving__c = '01:30';
        acctLoc.Sunday_Morning_To_Receiving__c = '02:00';
        acctLoc.Monday_Afternoon_From_Receiving__c = '12:30';
        acctLoc.Monday_Afternoon_To_Receiving__c = '14:00';
        acctLoc.Monday_Morning_From_Receiving__c = '02:30';
        acctLoc.Monday_Morning_To_Receiving__c = '12:00';
        acctLoc.Tuesday_Afternoon_From_Receiving__c = '13:00';
        acctLoc.Tuesday_Afternoon_To_Receiving__c = '14:00';
        acctLoc.Tuesday_Morning_From_Receiving__c = '05:15';
        acctLoc.Tuesday_Morning_To_Receiving__c = '07:15';
        acctLoc.Wednesday_Afternoon_From_Receiving__c = '12:00';
        acctLoc.Wednesday_Afternoon_To_Receiving__c = '15:00';
        acctLoc.Wednesday_Morning_From_Receiving__c = '08:15';
        acctLoc.Wednesday_Morning_To_Receiving__c = '12:00';
        acctLoc.Thursday_Afternoon_From_Receiving__c = '15:00';
        acctLoc.Thursday_Afternoon_To_Receiving__c = '19:00';
        acctLoc.Thursday_Morning_From_Receiving__c = '08:00';
        acctLoc.Thursday_Morning_To_Receiving__c = '12:00';
        acctLoc.Friday_Afternoon_From_Receiving__c = '15:00';
        acctLoc.Friday_Afternoon_To_Receiving__c = '17:00';
        acctLoc.Friday_Morning_To_Receiving__c = '12:00';
        acctLoc.Address_Validation__c = 'Valid';
        acctLoc.Shipping_Address_Validation_Timestamp__c = date.today();
        acctLoc.RecordTypeId = recTypeIdAL;
        insert acctLoc;
        
       
        Apttus_Config2__AccountLocation__c accLocRec = [Select Id, RecordTypeId FROM Apttus_Config2__AccountLocation__c
                                                        WHERE id =: acctLoc.id];
        
        System.assertequals(accLocRec.RecordTypeId, recTypeIdAccountLocationRO);
 
       
    }
    

    
    /*
    * @author        Francis Allen Alindogan
    * @date          March 11, 2020
    * @description   Test method for flushRSDetails DOO-4256
    * @revision(s)   
    */

    private static testMethod void testFlushRSDetails(){   
        //USER AND PROFILE
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        User u = new User(Alias = 'standt', Email='sample@testUser1.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sample@testUser1.com', Sales_Organization__c = 'SAP_0111',  Elevated_Access_Reason__c = 'Defect or Incident Resolution', Elevated_Access_Reference__c = 'ASDF');
        insert u;
        
        System.runAs(u) {

            Contact con = TS_TestDataFactory.createContact();  
            con.Preferred_Language__c = 'SAP_EN';
            Insert con;
            
            Case c = TS_TestDataFactory.createFieldServiceCase();
            c.ContactId = con.Id;
            c.Status = Label.TS_Status_InProgress;
            c.OwnerId = userinfo.getUserId();
            insert c;
            
            WorkOrder wo = TS_TestDataFactory.createWorkOrder();
            wo.CaseId = c.Id;
            wo.WorkOrderType__c = Label.TS_Case_SubType_CorrectMaint;
            wo.ContactId = con.Id;
            insert wo;
            
            Apttus_Config2__AccountLocation__c accLoc = [Select Id, Shipping_Address_Validation_Timestamp__c FROM Apttus_Config2__AccountLocation__c LIMIT 1];
            accLoc.LastRoutesalesDate__c = date.today();
            accLoc.RequestedRoutesalesVisit__c = true;
            accLoc.RoutesalesDateOverriden__c = true;
            update accLoc;

            WorkOrderLineItem woli = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);
            woli.WorkOrderType__c = TS_Constants.TYPE_S25_ROUTESALES;
            woli.status = TS_Constants.STATUS_COMPLETED;
            woli.AccountLocation__c = accLoc.Id;
            insert woli;
            
            //Third Party Resource        
            Resource__c engr = new Resource__c();
            engr.Name = 'Test Engr';
            engr.Sales_Organization__c = 'SAP_0111';
            engr.SAPStorageLocation__c ='xxxx';
            engr.CompanyCode__c ='0607';
            engr.RelatedUser__c = u.Id;
            insert engr;
            
        	accLoc.Third_Party_Resource__c = engr.Id;        
            update accLoc;

            System.assertequals(accLoc.NextRoutesalesDate__c, null);
        }            

    }

    private static testMethod void testTZoneValidation() {
        Id recTypeIdAL = Schema.SObjectType.Apttus_Config2__AccountLocation__c.getRecordTypeInfosByName().get('Account Location Valid').getRecordTypeId();
         
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Phone = '+31302979111';
        insert acc;
        
        Apttus_Config2__AccountLocation__c acctLoc = new Apttus_Config2__AccountLocation__c();
        acctLoc.Copy_of_Parent_Account__c = true;
        acctLoc.Apttus_Config2__AccountId__c = acc.Id;
        acctLoc.Name = 'SAMP';
        acctLoc.Mini_Language__c = 'SAP_FR';
        acctLoc.Pallet_type__c = 'SAP_007';
        acctLoc.Saturday_Afternoon_From_Receiving__c = '12:30';
        acctLoc.Saturday_Afternoon_To_Receiving__c = '13:45';
        acctLoc.Saturday_Morning_From_Receiving__c = '02:45';
        acctLoc.Saturday_Morning_To_Receiving__c = '02:15';
        acctLoc.Sunday_Afternoon_From_Receiving__c = '15:15';
        acctLoc.Sunday_Afternoon_To_Receiving__c = '15:30';
        acctLoc.Sunday_Morning_From_Receiving__c = '01:30';
        acctLoc.Sunday_Morning_To_Receiving__c = '02:00';
        acctLoc.Monday_Afternoon_From_Receiving__c = '12:30';
        acctLoc.Monday_Afternoon_To_Receiving__c = '14:00';
        acctLoc.Monday_Morning_From_Receiving__c = '02:30';
        acctLoc.Monday_Morning_To_Receiving__c = '12:00';
        acctLoc.Tuesday_Afternoon_From_Receiving__c = '13:00';
        acctLoc.Tuesday_Afternoon_To_Receiving__c = '14:00';
        acctLoc.Tuesday_Morning_From_Receiving__c = '05:15';
        acctLoc.Tuesday_Morning_To_Receiving__c = '07:15';
        acctLoc.Wednesday_Afternoon_From_Receiving__c = '12:00';
        acctLoc.Wednesday_Afternoon_To_Receiving__c = '15:00';
        acctLoc.Wednesday_Morning_From_Receiving__c = '08:15';
        acctLoc.Wednesday_Morning_To_Receiving__c = '12:00';
        acctLoc.Thursday_Afternoon_From_Receiving__c = '15:00';
        acctLoc.Thursday_Afternoon_To_Receiving__c = '19:00';
        acctLoc.Thursday_Morning_From_Receiving__c = '08:00';
        acctLoc.Thursday_Morning_To_Receiving__c = '12:00';
        acctLoc.Friday_Afternoon_From_Receiving__c = '15:00';
        acctLoc.Friday_Afternoon_To_Receiving__c = '17:00';
        acctLoc.Friday_Morning_From_Receiving__c = '09:15';
        acctLoc.Friday_Morning_To_Receiving__c = '12:00';
        acctLoc.Address_Validation__c = 'Valid';
        acctLoc.RecordTypeId = recTypeIdAL;
        acctLoc.SAP_Customer_ID__c = '78948923';
        acctLoc.Shipping_Country_ISO__c = 'NL';
        acctLoc.Mini_Transportation_zone__c = 'SAP_NL001';
        insert acctLoc;
        
        try{
            acctLoc.Mini_Transportation_zone__c = 'SAP_IE002';
            AccountLocationTriggerHandlerHelper.integLogFirstTime = true;
            checkRecursive.run = true;
            update acctLoc;
            
            System.assertequals(acctLoc.Mini_Transportation_zone__c, 'SAP_NL001');
        } catch(Exception e) {
            
        }
    }       
}