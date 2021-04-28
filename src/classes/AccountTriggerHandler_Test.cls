//-------------------------------------------------------------------------------------------
// Author       :   Catherine Aragon - Accenture
// Created Date :   March 14, 2017
// Usage        :   Test Class for AccountTriggerHandler
//-------------------------------------------------------------------------------------------
@isTest
private class AccountTriggerHandler_Test {
    private static User createDellIntegUser(){

        Id p = [SELECT Id FROM Profile WHERE Name='JDE-Integration-Digital'].id;
        Id RAdmin = [SELECT Id FROM UserRole WHERE Name = 'JDE Professional'].Id;
                  
        User IntegUser = new User(alias = 'test123', email='test123@noemail.com',
                emailencodingkey='UTF-8', lastname='LastNamePartner', firstName = 'FirstNamePartner', languagelocalekey='en_US',
                localesidkey='en_US', profileid = p, country='United States',IsActive =true, Sales_Organization__c = 'SAP_0333',userroleId = RAdmin,
                timezonesidkey='America/Los_Angeles', username='tester@notemail.com');
       
        insert IntegUser;
        
        return IntegUser;
    }
    //Description: This is for test setup of the test class
    @testSetup
    static void testSetup(){
    
        // Profile p = [SELECT Id FROM Profile WHERE Name =: SM_Constants.SystemAdmin]; 
        // User u = new User(Alias = 'standt', Email='ample@testUser.com', 
        // EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',  
        // LocaleSidKey='en_US', ProfileId = p.Id, 
        // TimeZoneSidKey='America/Los_Angeles', UserName='sample@ksdjflskje.com', Sales_Organization__c = 'SAP_0333');
        
        // System.runAs(u) {
            //insert custom settings
            insert new TriggerSettings__c(SetupOwnerId = UserInfo.getOrganizationId(), AccountTrigger__c = true, BulkDataSwitch__c = true);
            
            Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
            paymentTerm.Name = 'Sample';
            paymentTerm.Apttus_Config2__Sequence__c = 1;
            paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
        	paymentTerm.APTS_Ext_ID__c = 'asdfsadfsadfdsfasdf';
            insert paymentTerm;
            
            Mini_Template__c mt = new Mini_Template__c();
            mt.Name = 'SAP_0333';
            mt.Mini_Sales_Organization__c ='SAP_0333';
            mt.Mini_Currency__c = 'EUR';
            mt.Mini_Terms_of_payment__c = 'asdfsadfsadfdsfasdf';
            insert mt;
    
            MiniTemplateTax__c mtt = new MiniTemplateTax__c();
            mtt.Name = 'SAP-0033 -1';
            mtt.Sales_Organization__c = 'SAP_0333';
            insert mtt;
      
            List<Account> accList = new List<Account>();
            for(Account acc : TestDataFactory.createAccounts(10,'38751')){            
                accList.add(acc);
            }
            
            insert accList;
            system.debug('###'+accList);
        //}
    }
    
    private static testMethod void testDefault() {
        Id p = [SELECT Id FROM Profile WHERE Name = :SM_Constants.SystemAdmin].id;
                  
        User u = new User(alias = 'test123', email='test123@noemail.com',
                emailencodingkey='UTF-8', lastname='LastNamePartner', firstName = 'FirstNamePartner', languagelocalekey='en_US',
                localesidkey='en_US', profileid = p, country='United States',IsActive =true, Sales_Organization__c = 'SAP_0333',
                timezonesidkey='America/Los_Angeles', username='tester@notemail.com');
       
        insert u;
        
        System.runAs(u) {
            Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
            paymentTerm.Name = 'Sample';
            paymentTerm.Apttus_Config2__Sequence__c = 1;
            paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
            paymentTerm.APTS_Ext_ID__c = 'asdfsadfsadfdsfasdf1';
            insert paymentTerm;
            
            Mini_Template__c mt = new Mini_Template__c();
            mt.Name = 'SAP_0333';
            mt.Mini_Sales_Organization__c ='SAP_0333';
            mt.Mini_Currency__c = 'EUR';
            mt.Mini_Terms_of_payment__c = 'asdfsadfsadfdsfasdf1';
            insert mt;
            
            MiniTemplateTax__c mtt = new MiniTemplateTax__c();
            mtt.Name = 'SAP-0033 -1';
            mtt.Sales_Organization__c = 'SAP_0333';
            insert mtt;
            
            test.startTest();
            Account acc = new Account();
            acc.Name = 'accName1';
            acc.BillingStreet = 'mainstreet1';
            acc.Main_House_Number__c = '121';
            acc.Main_Street_Only__c = 'streetOnly1';
            acc.BillingCity = 'mainCity1';
            acc.BillingState = 'state1';
            acc.BillingPostalCode = 'pCode1';
            acc.BillingCountry = 'country1';
            acc.Main_Country_ISO__c = 'countryISO1';
            //acc.Main_Postal_Box__c = 'pBox1';
            acc.Language__c = 'SAP_SR';
            acc.Bill_Block_Reason__c = 'SAP_00';
            acc.Transactional_Block_Reason__c = 'SAP_00';
            acc.Delivery_Block_Reason__c = 'SAP_D3';
            acc.SAP_Customer_ID__c = '76509';
            acc.Phone = '+31302979111';      
            acc.Sales_Organization__c = 'SAP_0333';
            acc.Duplicate_Reason__c='Office building';
            acc.Being_Converted__c = true;
            insert acc;
            Account testaccount = [SELECT Id, Sales_Organization__c 
                                   FROM Account 
                                   WHERE Id = :acc.id];
            List<Account> accountFiltered = new List<Account>();
            Map<Id, String> salesOrg = new Map<Id, String>();
            if (u.Profile.Name <> 'JDE-Integration-Digital'){
                accountFiltered.add(testaccount);
                salesOrg.put(testaccount.Id, u.Sales_Organization__c); 
            } else {
                accountFiltered.add(testaccount);
                salesOrg.put(testaccount.Id,testaccount.Sales_Organization__c);
            }
            System.debug('HERE!!!!!!!!!!!: ' + salesOrg);
            Mini_Template__c miniTemplate = Mini_Template__c.getInstance(salesOrg.get(testaccount.Id));
            System.debug('HERE!!!!!!!!!!!miniTemplate: ' + miniTemplate);
            Account accR = [SELECT Id, Apttus_Config2__PaymentTermId__c 
                                   FROM Account 
                                   WHERE Id = :testaccount.Id];
            System.assert(accR.Apttus_Config2__PaymentTermId__c <> Null);
         	test.stopTest();
        }
    }
 
    private static testMethod void testValidationVAT1() {
        try {  
            List<VAT_Rule__mdt> vatRules = [Select DeveloperName, Rule__c from VAT_Rule__mdt];
            Map <String, Decimal> vatRulehMap = new Map<String, Decimal>();
            if (!vatRules.isEmpty()){
                for (VAT_Rule__mdt vatRule : vatRules){
                    vatRulehMap.put(vatRule.DeveloperName, vatRule.Rule__c);
                }
            }
            
            List<VAT_Length__mdt> vatLengths = [Select DeveloperName, Length__c from VAT_Length__mdt];
            Map <String, Decimal> vatLengthMap = new Map<String, Decimal>();
            if (!vatLengths.isEmpty()){
                for (VAT_Length__mdt vatLength : vatLengths){
                    vatLengthMap.put(vatLength.DeveloperName, vatLength.Length__c);
                }
            }
            
            List<Account> acctList = new List<Account>();
            Account acc = new Account();
            acc.Name = 'accName';
            acc.Second_Account_Name__c = 'sAccName';
            acc.Archiving_Flag__c = false;
            acc.BillingStreet = 'mainstreet';
            acc.Main_House_Number__c = '123';
            acc.Main_Street_Only__c = 'streetOnly';
            acc.BillingCity = 'mainCity';
            acc.BillingState = 'state';
            acc.BillingPostalCode = 'pCode';
            acc.BillingCountry = 'country';
            acc.Language__c = 'SAP_SR';
            acc.Bill_Block_Reason__c = 'SAP_00';
            acc.Transactional_Block_Reason__c = 'SAP_00';
            acc.Delivery_Block_Reason__c = 'SAP_D3';
            acc.Phone = '+31302979111';
            acc.SAP_Customer_ID__c = '38162';
            acc.VAT_Registration_Number__c = '782908';
            acc.Main_Country_ISO__c = 'CZ';
            acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
            acctList.add(acc);
            Test.startTest();
            insert acc;
            System.debug('acc: ' + acc);
  
            
            Account accRec = [Select Id, VAT_Registration_Number__c, Name 
                                FROM Account
                                WHERE Id = :acc.id];
            
                        
            System.assert(accRec.VAT_Registration_Number__c.length() == 6);
            Test.stopTest();
        } catch (Exception e) {
            System.debug(e);
        } 
    }
    
    private static testMethod void testValidationVAT3() {
        try {  
            
            List<VAT_Rule__mdt> vatRules = [Select DeveloperName, Rule__c from VAT_Rule__mdt];
            Map <String, Decimal> vatRulehMap = new Map<String, Decimal>();
            if (!vatRules.isEmpty()){
                for (VAT_Rule__mdt vatRule : vatRules){
                    vatRulehMap.put(vatRule.DeveloperName, vatRule.Rule__c);
                }
            }
            
            List<VAT_Length__mdt> vatLengths = [Select DeveloperName, Length__c from VAT_Length__mdt];
            Map <String, Decimal> vatLengthMap = new Map<String, Decimal>();
            if (!vatLengths.isEmpty()){
                for (VAT_Length__mdt vatLength : vatLengths){
                    vatLengthMap.put(vatLength.DeveloperName, vatLength.Length__c);
                }
            }
            
            List<Account> acctList = new List<Account>();
            Account acc = new Account();
            acc.Name = 'accName';
            acc.Second_Account_Name__c = 'sAccName';
            acc.Archiving_Flag__c = false;
            acc.BillingStreet = 'mainstreet';
            acc.Main_House_Number__c = '123';
            acc.Main_Street_Only__c = 'streetOnly';
            acc.BillingCity = 'mainCity';
            acc.BillingState = 'state';
            acc.BillingPostalCode = 'pCode';
            acc.BillingCountry = 'country';
            acc.Language__c = 'SAP_SR';
            acc.Bill_Block_Reason__c = 'SAP_00';
            acc.Transactional_Block_Reason__c = 'SAP_00';
            acc.Delivery_Block_Reason__c = 'SAP_D3';
            acc.Phone = '+31302979111';
            acc.SAP_Customer_ID__c = '38162';
            acc.VAT_Registration_Number__c = 'p7829080opl';
            acc.Main_Country_ISO__c = 'AT';
            acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
            acctList.add(acc);
            Test.startTest();
            insert acc;
            System.debug('acc: ' + acc);
  
            
            Account accRec = [Select Id, VAT_Registration_Number__c, Name 
                                FROM Account
                                WHERE Id = :acc.id];
            
                        
            System.assert(accRec.VAT_Registration_Number__c.length() == 11);
            Test.stopTest();
        } catch (Exception e) {
            System.debug(e);
        } 
    }
    
    private static testMethod void testValidationVAT0() {
        try {
            List<Account> acctList = new List<Account>();
            Account acc = new Account();
            acc.Name = 'accName';
            acc.Second_Account_Name__c = 'sAccName';
            acc.Archiving_Flag__c = false;
            acc.BillingStreet = 'mainstreet';
            acc.Main_House_Number__c = '123';
            acc.Main_Street_Only__c = 'streetOnly';
            acc.BillingCity = 'mainCity';
            acc.BillingState = 'state';
            acc.BillingPostalCode = 'pCode';
            acc.BillingCountry = 'country';
            acc.Language__c = 'SAP_SR';
            acc.Bill_Block_Reason__c = 'SAP_00';
            acc.Transactional_Block_Reason__c = 'SAP_00';
            acc.Delivery_Block_Reason__c = 'SAP_D3';
            acc.Phone = '+31302979111';
            acc.SAP_Customer_ID__c = '38162';
            acc.VAT_Registration_Number__c = '782908';
            acc.Main_Country_ISO__c = 'EL';
            acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
            acctList.add(acc);
            Test.startTest();
            insert acc;
            System.debug('acc: ' + acc);
  
            
            Account accRec = [Select Id, VAT_Registration_Number__c, Name 
                                FROM Account
                                WHERE Id = :acc.id];
            
                        
            System.assert(accRec.VAT_Registration_Number__c.length() == 6);
            Test.stopTest();
        } catch (Exception e) {
            System.debug(e);
        } 
    }
    
    private static testMethod void testValidationPostalCheckRule4() {
        try { 
            
            List<Postal_Box_Length__mdt> poLengths = [Select DeveloperName, Length__c from Postal_Box_Length__mdt];
            Map <String, Decimal> poLengthMap = new Map<String, Decimal>();
            if (!poLengths.isEmpty()){
                for (Postal_Box_Length__mdt poLength : poLengths){
                    poLengthMap.put(poLength.DeveloperName, poLength.Length__c);
                }
            }
            
            List<Postal_Box_Rule__mdt> poRules = [Select DeveloperName, Rule__c from Postal_Box_Rule__mdt];
            Map <String, Decimal> poRuleMap = new Map<String, Decimal>();
            if (!poRules.isEmpty()){
                for (Postal_Box_Rule__mdt poRule : poRules){
                    poLengthMap.put(poRule.DeveloperName, poRule.Rule__c);
                }
            }
            
            Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
            paymentTerm.Name = 'testValidationPostalCheckRule4';
            paymentTerm.Apttus_Config2__Sequence__c = 1;
            paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
            paymentTerm.APTS_Ext_ID__c = 'testValidationPostalCheckRule4';
            insert paymentTerm;
            
            List<Account> acctList = new List<Account>();
            Account acc = new Account();
            acc.Name = 'accName';
            acc.Second_Account_Name__c = 'sAccName';
            acc.Archiving_Flag__c = false;
            acc.BillingStreet = 'mainstreet';
            acc.Main_House_Number__c = '123';
            acc.Main_Street_Only__c = 'streetOnly';
            acc.BillingCity = 'mainCity';
            acc.BillingState = 'state';
            acc.BillingPostalCode = 'pCode';
            acc.BillingCountry = 'country';
            //acc.Main_Postal_Box__c = 'pBox';
            acc.Language__c = 'SAP_SR';
            acc.Bill_Block_Reason__c = 'SAP_00';
            acc.Transactional_Block_Reason__c = 'SAP_00';
            acc.Delivery_Block_Reason__c = 'SAP_D3';
            acc.Phone = '+31302979111';
            acc.SAP_Customer_ID__c = '38162';
            acc.Apttus_Config2__PaymentTermId__c =paymentTerm.Id;
            acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
            acctList.add(acc);
            Test.startTest();
            insert acc;
            System.debug('acc: ' + acc);
            
            acctList[0].Main_Country_ISO__c = 'AT';
            acctList[0].Main_Postal_Box_Postal_Code__c = 'as d';
            checkrecursive.run = true;
            update acctList;
            
            Account accRec = [Select Id, Name, Main_Country_ISO__c 
                                FROM Account
                                WHERE Id = :acctList[0].Id];
                        
            System.assert(poRuleMap.get(accRec.Main_Country_ISO__c) == 4);
            Test.stopTest();
        } catch (Exception e) {
            System.debug(e);
        } 
    }
    
    private static testMethod void testValidationPostalCheckRule4exceed() {
        try {  
            List<Postal_Box_Length__mdt> poLengths = [Select DeveloperName, Length__c from Postal_Box_Length__mdt];
            Map <String, Decimal> poLengthMap = new Map<String, Decimal>();
            if (!poLengths.isEmpty()){
                for (Postal_Box_Length__mdt poLength : poLengths){
                    poLengthMap.put(poLength.DeveloperName, poLength.Length__c);
                }
            }
            
            List<Postal_Box_Rule__mdt> poRules = [Select DeveloperName, Rule__c from Postal_Box_Rule__mdt];
            Map <String, Decimal> poRuleMap = new Map<String, Decimal>();
            if (!poRules.isEmpty()){
                for (Postal_Box_Rule__mdt poRule : poRules){
                    poLengthMap.put(poRule.DeveloperName, poRule.Rule__c);
                }
            }
            
            Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
            paymentTerm.Name = 'testValidationPostalCheckRule4exceed';
            paymentTerm.Apttus_Config2__Sequence__c = 1;
            paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
            paymentTerm.APTS_Ext_ID__c = 'testValidationPostalCheckRule4exceed';
            insert paymentTerm;
            
            List<Account> acctList = new List<Account>();
            Account acc = new Account();
            acc.Name = 'accName';
            acc.Second_Account_Name__c = 'sAccName';
            acc.Archiving_Flag__c = false;
            acc.BillingStreet = 'mainstreet';
            acc.Main_House_Number__c = '123';
            acc.Main_Street_Only__c = 'streetOnly';
            acc.BillingCity = 'mainCity';
            acc.BillingState = 'state';
            acc.BillingPostalCode = 'pCode';
            acc.BillingCountry = 'country';
            //acc.Main_Postal_Box__c = 'pBox';
            acc.Language__c = 'SAP_SR';
            acc.Bill_Block_Reason__c = 'SAP_00';
            acc.Transactional_Block_Reason__c = 'SAP_00';
            acc.Delivery_Block_Reason__c = 'SAP_D3';
            acc.Phone = '+31302979111';
            acc.SAP_Customer_ID__c = '38162';
            acc.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
            acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
            acctList.add(acc);
            Test.startTest();
            insert acc;
            System.debug('acc: ' + acc);
            
            acctList[0].Main_Country_ISO__c = 'AT';
            acctList[0].Main_Postal_Box_Postal_Code__c = 'as dqw';
            checkrecursive.run = true;
            update acctList;
            
            Account accRec = [Select Id, Name, Main_Country_ISO__c 
                                FROM Account
                                WHERE Id = :acctList[0].Id];
            
                        
            System.assert(poRuleMap.get(accRec.Main_Country_ISO__c) == 4);
            Test.stopTest();
        } catch (Exception e) {
            System.debug(e);
        } 
    }
    
    private static testMethod void testValidationPostalCheckRule5() {
        try {  
            List<Postal_Box_Length__mdt> poLengths = [Select DeveloperName, Length__c from Postal_Box_Length__mdt];
            Map <String, Decimal> poLengthMap = new Map<String, Decimal>();
            if (!poLengths.isEmpty()){
                for (Postal_Box_Length__mdt poLength : poLengths){
                    poLengthMap.put(poLength.DeveloperName, poLength.Length__c);
                }
            }
            
            List<Postal_Box_Rule__mdt> poRules = [Select DeveloperName, Rule__c from Postal_Box_Rule__mdt];
            Map <String, Decimal> poRuleMap = new Map<String, Decimal>();
            if (!poRules.isEmpty()){
                for (Postal_Box_Rule__mdt poRule : poRules){
                    poLengthMap.put(poRule.DeveloperName, poRule.Rule__c);
                }
            }
            
            Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
            paymentTerm.Name = 'testValidationPostalCheckRule5';
            paymentTerm.Apttus_Config2__Sequence__c = 1;
            paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
            paymentTerm.APTS_Ext_ID__c = 'testValidationPostalCheckRule5';
            insert paymentTerm;
            
            List<Account> acctList = new List<Account>();
            Account acc = new Account();
            acc.Name = 'accName';
            acc.Second_Account_Name__c = 'sAccName';
            acc.Archiving_Flag__c = false;
            acc.BillingStreet = 'mainstreet';
            acc.Main_House_Number__c = '123';
            acc.Main_Street_Only__c = 'streetOnly';
            acc.BillingCity = 'mainCity';
            acc.BillingState = 'state';
            acc.BillingPostalCode = 'pCode';
            acc.BillingCountry = 'country';
            //acc.Main_Postal_Box__c = 'pBox';
            acc.Language__c = 'SAP_SR';
            acc.Bill_Block_Reason__c = 'SAP_00';
            acc.Transactional_Block_Reason__c = 'SAP_00';
            acc.Delivery_Block_Reason__c = 'SAP_D3';
            acc.Phone = '+31302979111';
            acc.SAP_Customer_ID__c = '38162';
            acc.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
            acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
            acctList.add(acc);
            Test.startTest();
            insert acc;
            System.debug('acc: ' + acc);
            
            acctList[0].Main_Country_ISO__c = 'GB';
            acctList[0].Main_Postal_Box_Postal_Code__c = 'as dioikjhg';
            checkrecursive.run = true;
            update acctList;
            
            Account accRec = [Select Id, Name, Main_Country_ISO__c 
                                FROM Account
                                WHERE Id = :acctList[0].Id];
            
                        
            System.assert(poRuleMap.get(accRec.Main_Country_ISO__c) == 5);
            Test.stopTest();
        } catch (Exception e) {
            System.debug(e);
        } 
    }
    
    private static testMethod void testValidationPostalCheckRule9exceed() {
        try {  
            List<Postal_Box_Length__mdt> poLengths = [Select DeveloperName, Length__c from Postal_Box_Length__mdt];
            Map <String, Decimal> poLengthMap = new Map<String, Decimal>();
            if (!poLengths.isEmpty()){
                for (Postal_Box_Length__mdt poLength : poLengths){
                    poLengthMap.put(poLength.DeveloperName, poLength.Length__c);
                }
            }
            
            List<Postal_Box_Rule__mdt> poRules = [Select DeveloperName, Rule__c from Postal_Box_Rule__mdt];
            Map <String, Decimal> poRuleMap = new Map<String, Decimal>();
            if (!poRules.isEmpty()){
                for (Postal_Box_Rule__mdt poRule : poRules){
                    poLengthMap.put(poRule.DeveloperName, poRule.Rule__c);
                }
            }
            
            Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
            paymentTerm.Name = 'testValidationPostalCheckRule9exceed';
            paymentTerm.Apttus_Config2__Sequence__c = 1;
            paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
            paymentTerm.APTS_Ext_ID__c = 'testValidationPostalCheckRule9exceed';
            insert paymentTerm;
            
            List<Account> acctList = new List<Account>();
            Account acc = new Account();
            acc.Name = 'accName';
            acc.Second_Account_Name__c = 'sAccName';
            acc.Archiving_Flag__c = false;
            acc.BillingStreet = 'mainstreet';
            acc.Main_House_Number__c = '123';
            acc.Main_Street_Only__c = 'streetOnly';
            acc.BillingCity = 'mainCity';
            acc.BillingState = 'state';
            acc.BillingPostalCode = 'pCode';
            acc.BillingCountry = 'country';
            //acc.Main_Postal_Box__c = 'pBox';
            acc.Language__c = 'SAP_SR';
            acc.Bill_Block_Reason__c = 'SAP_00';
            acc.Transactional_Block_Reason__c = 'SAP_00';
            acc.Delivery_Block_Reason__c = 'SAP_D3';
            acc.Phone = '+31302979111';
            acc.SAP_Customer_ID__c = '38162';
            acc.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
            acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
            acctList.add(acc);
            Test.startTest();
            insert acc;
            System.debug('acc: ' + acc);
            
            acctList[0].Main_Country_ISO__c = 'MT';
            acctList[0].Main_Postal_Box_Postal_Code__c = 'as dioikjhg';
            checkrecursive.run = true;
            update acctList;
            
            Account accRec = [Select Id, Name, Main_Country_ISO__c 
                                FROM Account
                                WHERE Id = :acctList[0].Id];
            
                        
            System.assert(poRuleMap.get(accRec.Main_Country_ISO__c) == 9);
            Test.stopTest();
        } catch (Exception e) {
            System.debug(e);
        } 
    }
    
    private static testMethod void testValidationPostalCheckRule9MT() {
        try {  
            List<Postal_Box_Length__mdt> poLengths = [Select DeveloperName, Length__c from Postal_Box_Length__mdt];
            Map <String, Decimal> poLengthMap = new Map<String, Decimal>();
            if (!poLengths.isEmpty()){
                for (Postal_Box_Length__mdt poLength : poLengths){
                    poLengthMap.put(poLength.DeveloperName, poLength.Length__c);
                }
            }
            
            List<Postal_Box_Rule__mdt> poRules = [Select DeveloperName, Rule__c from Postal_Box_Rule__mdt];
            Map <String, Decimal> poRuleMap = new Map<String, Decimal>();
            if (!poRules.isEmpty()){
                for (Postal_Box_Rule__mdt poRule : poRules){
                    poLengthMap.put(poRule.DeveloperName, poRule.Rule__c);
                }
            }
            
            Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
            paymentTerm.Name = 'testValidationPostalCheckRule9MT';
            paymentTerm.Apttus_Config2__Sequence__c = 1;
            paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
            paymentTerm.APTS_Ext_ID__c = 'testValidationPostalCheckRule9MT';
            insert paymentTerm;
            
            List<Account> acctList = new List<Account>();
            Account acc = new Account();
            acc.Name = 'accName';
            acc.Second_Account_Name__c = 'sAccName';
            acc.Archiving_Flag__c = false;
            acc.BillingStreet = 'mainstreet';
            acc.Main_House_Number__c = '123';
            acc.Main_Street_Only__c = 'streetOnly';
            acc.BillingCity = 'mainCity';
            acc.BillingState = 'state';
            acc.BillingPostalCode = 'pCode';
            acc.BillingCountry = 'country';
            //acc.Main_Postal_Box__c = 'pBox';
            acc.Language__c = 'SAP_SR';
            acc.Bill_Block_Reason__c = 'SAP_00';
            acc.Transactional_Block_Reason__c = 'SAP_00';
            acc.Delivery_Block_Reason__c = 'SAP_D3';
            acc.Phone = '+31302979111';
            acc.SAP_Customer_ID__c = '38162';
            acc.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
            acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
            acctList.add(acc);
            Test.startTest();
            insert acc;
            System.debug('acc: ' + acc);
            
            acctList[0].Main_Country_ISO__c = 'MT';
            acctList[0].Main_Postal_Box_Postal_Code__c = '123 QWER';
            checkrecursive.run = true;
            update acctList;
            
            Account accRec = [Select Id, Name, Main_Country_ISO__c 
                                FROM Account
                                WHERE Id = :acctList[0].Id];
            
                        
            System.assert(poRuleMap.get(accRec.Main_Country_ISO__c) == 9);
            Test.stopTest();
        } catch (Exception e) {
            System.debug(e);
        } 
    }
    
    private static testMethod void testValidationPostalCheckRule9NL() {
        try {  
            List<Postal_Box_Length__mdt> poLengths = [Select DeveloperName, Length__c from Postal_Box_Length__mdt];
            Map <String, Decimal> poLengthMap = new Map<String, Decimal>();
            if (!poLengths.isEmpty()){
                for (Postal_Box_Length__mdt poLength : poLengths){
                    poLengthMap.put(poLength.DeveloperName, poLength.Length__c);
                }
            }
            
            List<Postal_Box_Rule__mdt> poRules = [Select DeveloperName, Rule__c from Postal_Box_Rule__mdt];
            Map <String, Decimal> poRuleMap = new Map<String, Decimal>();
            if (!poRules.isEmpty()){
                for (Postal_Box_Rule__mdt poRule : poRules){
                    poLengthMap.put(poRule.DeveloperName, poRule.Rule__c);
                }
            }
            
            Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
            paymentTerm.Name = 'testValidationPostalCheckRule9NL';
            paymentTerm.Apttus_Config2__Sequence__c = 1;
            paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
            paymentTerm.APTS_Ext_ID__c = 'testValidationPostalCheckRule9NL';
            insert paymentTerm;
            
            List<Account> acctList = new List<Account>();
            Account acc = new Account();
            acc.Name = 'accName';
            acc.Second_Account_Name__c = 'sAccName';
            acc.Archiving_Flag__c = false;
            acc.BillingStreet = 'mainstreet';
            acc.Main_House_Number__c = '123';
            acc.Main_Street_Only__c = 'streetOnly';
            acc.BillingCity = 'mainCity';
            acc.BillingState = 'state';
            acc.BillingPostalCode = 'pCode';
            acc.BillingCountry = 'country';
            //acc.Main_Postal_Box__c = 'pBox';
            acc.Language__c = 'SAP_SR';
            acc.Bill_Block_Reason__c = 'SAP_00';
            acc.Transactional_Block_Reason__c = 'SAP_00';
            acc.Delivery_Block_Reason__c = 'SAP_D3';
            acc.Phone = '+31302979111';
            acc.SAP_Customer_ID__c = '38162';
            acc.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
            acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
            acctList.add(acc);
            Test.startTest();
            insert acc;
            System.debug('acc: ' + acc);
            
            acctList[0].Main_Country_ISO__c = 'NL';
            acctList[0].Main_Postal_Box_Postal_Code__c = 'QWER 56';
            checkrecursive.run = true;
            update acctList;
            
            Account accRec = [Select Id, Name, Main_Country_ISO__c 
                                FROM Account
                                WHERE Id = :acctList[0].Id];
            
                        
            System.assert(poRuleMap.get(accRec.Main_Country_ISO__c) == 9);
            Test.stopTest();
        } catch (Exception e) {
            System.debug(e);
        } 
    }
    
    private static testMethod void testValidationPostalCheckRule9PL() {
        try {  
            List<Postal_Box_Length__mdt> poLengths = [Select DeveloperName, Length__c from Postal_Box_Length__mdt];
            Map <String, Decimal> poLengthMap = new Map<String, Decimal>();
            if (!poLengths.isEmpty()){
                for (Postal_Box_Length__mdt poLength : poLengths){
                    poLengthMap.put(poLength.DeveloperName, poLength.Length__c);
                }
            }
            
            List<Postal_Box_Rule__mdt> poRules = [Select DeveloperName, Rule__c from Postal_Box_Rule__mdt];
            Map <String, Decimal> poRuleMap = new Map<String, Decimal>();
            if (!poRules.isEmpty()){
                for (Postal_Box_Rule__mdt poRule : poRules){
                    poLengthMap.put(poRule.DeveloperName, poRule.Rule__c);
                }
            }
            
            Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
            paymentTerm.Name = 'testValidationPostalCheckRule9PL';
            paymentTerm.Apttus_Config2__Sequence__c = 1;
            paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
            paymentTerm.APTS_Ext_ID__c = 'testValidationPostalCheckRule9PL';
            insert paymentTerm;
            
            List<Account> acctList = new List<Account>();
            Account acc = new Account();
            acc.Name = 'accName';
            acc.Second_Account_Name__c = 'sAccName';
            acc.Archiving_Flag__c = false;
            acc.BillingStreet = 'mainstreet';
            acc.Main_House_Number__c = '123';
            acc.Main_Street_Only__c = 'streetOnly';
            acc.BillingCity = 'mainCity';
            acc.BillingState = 'state';
            acc.BillingPostalCode = 'pCode';
            acc.BillingCountry = 'country';
            //acc.Main_Postal_Box__c = 'pBox';
            acc.Language__c = 'SAP_SR';
            acc.Bill_Block_Reason__c = 'SAP_00';
            acc.Transactional_Block_Reason__c = 'SAP_00';
            acc.Delivery_Block_Reason__c = 'SAP_D3';
            acc.Phone = '+31302979111';
            acc.SAP_Customer_ID__c = '38162';
            acc.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
            acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
            acctList.add(acc);
            Test.startTest();
            insert acc;
            System.debug('acc: ' + acc);
            
            acctList[0].Main_Country_ISO__c = 'PL';
            acctList[0].Main_Postal_Box_Postal_Code__c = 'QW-IOI';
            checkrecursive.run = true;
            update acctList;
            
            Account accRec = [Select Id, Name, Main_Country_ISO__c 
                                FROM Account
                                WHERE Id = :acctList[0].Id];
            
                        
            System.assert(poRuleMap.get(accRec.Main_Country_ISO__c) == 9);
            Test.stopTest();
        } catch (Exception e) {
            System.debug(e);
        } 
    }
    
    private static testMethod void testValidationPostalCheckRule9PT() {
        try {  
            List<Postal_Box_Length__mdt> poLengths = [Select DeveloperName, Length__c from Postal_Box_Length__mdt];
            Map <String, Decimal> poLengthMap = new Map<String, Decimal>();
            if (!poLengths.isEmpty()){
                for (Postal_Box_Length__mdt poLength : poLengths){
                    poLengthMap.put(poLength.DeveloperName, poLength.Length__c);
                }
            }
            
            List<Postal_Box_Rule__mdt> poRules = [Select DeveloperName, Rule__c from Postal_Box_Rule__mdt];
            Map <String, Decimal> poRuleMap = new Map<String, Decimal>();
            if (!poRules.isEmpty()){
                for (Postal_Box_Rule__mdt poRule : poRules){
                    poLengthMap.put(poRule.DeveloperName, poRule.Rule__c);
                }
            }
            
            Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
            paymentTerm.Name = 'testValidationPostalCheckRule9PT';
            paymentTerm.Apttus_Config2__Sequence__c = 1;
            paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
            paymentTerm.APTS_Ext_ID__c = 'testValidationPostalCheckRule9PT';
            insert paymentTerm;
            
            List<Account> acctList = new List<Account>();
            Account acc = new Account();
            acc.Name = 'accName';
            acc.Second_Account_Name__c = 'sAccName';
            acc.Archiving_Flag__c = false;
            acc.BillingStreet = 'mainstreet';
            acc.Main_House_Number__c = '123';
            acc.Main_Street_Only__c = 'streetOnly';
            acc.BillingCity = 'mainCity';
            acc.BillingState = 'state';
            acc.BillingPostalCode = 'pCode';
            acc.BillingCountry = 'country';
            //acc.Main_Postal_Box__c = 'pBox';
            acc.Language__c = 'SAP_SR';
            acc.Bill_Block_Reason__c = 'SAP_00';
            acc.Transactional_Block_Reason__c = 'SAP_00';
            acc.Delivery_Block_Reason__c = 'SAP_D3';
            acc.Phone = '+31302979111';
            acc.SAP_Customer_ID__c = '38162';
            acc.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
            acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
            acctList.add(acc);
            Test.startTest();
            insert acc;
            System.debug('acc: ' + acc);
            
            acctList[0].Main_Country_ISO__c = 'PT';
            acctList[0].Main_Postal_Box_Postal_Code__c = 'QWER 566';
            checkrecursive.run = true;
            update acctList;
            
            
            Account accRec = [Select Id, Name, Main_Country_ISO__c 
                                FROM Account
                                WHERE Id = :acctList[0].Id];
            
                        
            System.assert(poRuleMap.get(accRec.Main_Country_ISO__c) == 9);
            Test.stopTest();
        } catch (Exception e) {
            System.debug(e);
        } 
    }
    
    private static testMethod void testValidationPostalCheckRule9SE() {
        try {  
            List<Postal_Box_Length__mdt> poLengths = [Select DeveloperName, Length__c from Postal_Box_Length__mdt];
            Map <String, Decimal> poLengthMap = new Map<String, Decimal>();
            if (!poLengths.isEmpty()){
                for (Postal_Box_Length__mdt poLength : poLengths){
                    poLengthMap.put(poLength.DeveloperName, poLength.Length__c);
                }
            }
            
            List<Postal_Box_Rule__mdt> poRules = [Select DeveloperName, Rule__c from Postal_Box_Rule__mdt];
            Map <String, Decimal> poRuleMap = new Map<String, Decimal>();
            if (!poRules.isEmpty()){
                for (Postal_Box_Rule__mdt poRule : poRules){
                    poLengthMap.put(poRule.DeveloperName, poRule.Rule__c);
                }
            }
            
            Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
            paymentTerm.Name = 'testValidationPostalCheckRule9SE';
            paymentTerm.Apttus_Config2__Sequence__c = 1;
            paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
            paymentTerm.APTS_Ext_ID__c = 'testValidationPostalCheckRule9SE';
            insert paymentTerm;
            
            List<Account> acctList = new List<Account>();
            Account acc = new Account();
            acc.Name = 'accName';
            acc.Second_Account_Name__c = 'sAccName';
            acc.Archiving_Flag__c = false;
            acc.BillingStreet = 'mainstreet';
            acc.Main_House_Number__c = '123';
            acc.Main_Street_Only__c = 'streetOnly';
            acc.BillingCity = 'mainCity';
            acc.BillingState = 'state';
            acc.BillingPostalCode = 'pCode';
            acc.BillingCountry = 'country';
            //acc.Main_Postal_Box__c = 'pBox';
            acc.Language__c = 'SAP_SR';
            acc.Bill_Block_Reason__c = 'SAP_00';
            acc.Transactional_Block_Reason__c = 'SAP_00';
            acc.Delivery_Block_Reason__c = 'SAP_D3';
            acc.Phone = '+31302979111';
            acc.SAP_Customer_ID__c = '38162';
            acc.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
            acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
            acctList.add(acc);
            Test.startTest();
            insert acc;
            System.debug('acc: ' + acc);
            
            acctList[0].Main_Country_ISO__c = 'SE';
            acctList[0].Main_Postal_Box_Postal_Code__c = 'UIO DS';
            checkrecursive.run = true;
            update acctList;
            
            Account accRec = [Select Id, Name, Main_Country_ISO__c 
                                FROM Account
                                WHERE Id = :acctList[0].Id];
            
                        
            System.assert(poRuleMap.get(accRec.Main_Country_ISO__c) == 9);
            Test.stopTest();
        } catch (Exception e) {
            System.debug(e);
        } 
    }
    
    //Description: Test method for updating account field value.
    private static testMethod void testPositive() {
        Test.startTest();
        List<Account> updateAccList = new List<Account>();
        Integer i = 0;

        List<Account_Value_Estimation_Size_Price__c> aveList = new List<Account_Value_Estimation_Size_Price__c>();

        for(Account_Value_Estimation_Size_Price__c ave : TestDataFactory.createAVESize(1)){
            ave.Size_Type_Input__c = '# of FTE';
            aveList.add(ave);
        }
        
        for(Account_Value_Estimation_Size_Price__c ave : TestDataFactory.createAVEPrice(1)){
            aveList.add(ave);
        }

        insert aveList;
                    
        for(Account acc: [SELECT Name, Archiving_Flag__c, SAP_Customer_ID__c  FROM Account LIMIT 1]){
            acc.Name = 'Name' + i;
            //acc.isNew__c = false;
            acc.Archiving_Flag__c = false;
            acc.of_Employees_FTE__c = 100;
            acc.Estimated_Revenue_Potential__c  = 1000;
            acc.Mini_Company_Code__c = 'SAP_0202';
            acc.Segment__c= 'SAP_A';
            acc.Subsegment__c= 'Construction';
            acc.Penetration__c = 100;
            acc.Tea_Drinks__c = 20;
            acc.Avg_Coffee_Dosage__c = 10;
            
            acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
            i++;
            updateAccList.add(acc);
            
        }
        
        System.debug('updateAccList: ' + updateAccList);
        checkrecursive.run = true;
        update updateAccList;
        System.debug('updateAccList: ' + updateAccList);
        
        Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
        paymentTerm.Name = 'Sample';
        paymentTerm.Apttus_Config2__Sequence__c = 1;
        paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
        insert paymentTerm;
        
        List<Account> updateAccList1 = new List<Account>();
        
        for(Account acc1: [SELECT Name FROM Account]){
            //acc1.Name = 'Name' + i;
            //acc1.isNew__c = false;
            acc1.Second_Account_Name__c = 'test2n';
            //acc1.Sales_Office__c = 'SAP_FR50';
            acc1.Archiving_Flag__c = true;
            acc1.BillingStreet = 'Main Street 2';
            acc1.Main_House_Number__c = 'House Number X';
            acc1.Main_Street_Only__c = 'test data';
            acc1.BillingCity = 'test data';
            acc1.BillingState = 'test data';
            acc1.BillingPostalCode = 'test data';
            acc1.BillingCountry = 'test data';
            acc1.Main_Country_ISO__c = 'test data';
            //acc1.Main_Postal_Box__c = 'test data';
            acc1.Language__c = 'SAP_JA';
            acc1.Bill_Block_Reason__c = 'SAP_13';
            acc1.Transactional_Block_Reason__c = 'SAP_01';
            acc1.Delivery_Block_Reason__c = 'SAP_Z0';
            acc1.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
            acc1.Phone = '+31302979111';
            acc1.SAP_Customer_ID__c = '57310' + i;
            acc1.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
            acc1.Apttus_Config2__PaymentTermId__c = paymentTerm.id;
            i++;
            updateAccList1.add(acc1);
        }
        

            update updateAccList1;
            System.debug('updateAccList1: ' + updateAccList1);
        test.stopTest();
        
        Account acc = [SELECT Name, Updated_Account_Name__c, RecordTypeId FROM Account WHERE Id = :updateAccList1[0].Id];
        
        // System.assertEquals(acc.RecordTypeId, Schema.SObjectType.Account.getRecordTypeInfosByName().get('End Customer Validation').getRecordTypeId());
        System.assertNotEquals(acc.Name, acc.Updated_Account_Name__c);
    
        
        AccountTriggerHandler acct = new AccountTriggerHandler();
        List<SObject> newItems;
        List<SObject> oldList;
        Map<Id, SObject> oldItems;
        List<SObject> newList;
        Map<Id, SObject> newItemsMap;
        
        acct.BeforeDelete(oldList, oldItems);
        acct.AfterDelete(oldList, oldItems);
        acct.AfterUndelete(newList, newItemsMap);
        
        
    }
    
    //Description: Test method for updating account field value.
    private static testMethod void testPositive2() {
        test.startTest();

        List<Account> updateAccList = new List<Account>();
        Integer i = 0;
        
        List<Account_Value_Estimation_Size_Price__c> aveList = new List<Account_Value_Estimation_Size_Price__c>();

        for(Account_Value_Estimation_Size_Price__c ave : TestDataFactory.createAVESize(1)){
            ave.Size_Type_Input__c = '# of Seats';
            aveList.add(ave);
        }
        
        for(Account_Value_Estimation_Size_Price__c ave : TestDataFactory.createAVEPrice(1)){
            aveList.add(ave);
        }

        insert aveList;
        
        for(Account acc: [SELECT Name, SAP_Customer_ID__c FROM Account limit 2] ){
            acc.Name = 'Name1' + i;
            acc.Second_Account_Name__c = 'S1 ' + i;
            acc.of_Seats__c = 100;
            acc.Mini_Company_Code__c = 'SAP_0202';
            acc.Segment__c= 'SAP_A';
            i++;
            updateAccList.add(acc);
        }
        
        checkrecursive.run = true;
        updateAccList[0].of_Employees_FTE__c = 100;
        updateAccList[0].Estimated_Revenue_Potential__c  = 1000;
        updateAccList[0].Subsegment__c= 'Construction';
        updateAccList[0].Penetration__c = 100;
        updateAccList[0].Tea_Drinks__c = 20;
        updateAccList[0].Avg_Coffee_Dosage__c = 10;
        update updateAccList;
        test.stopTest(); 
        
        Account acc = [SELECT Name, Updated_Account_Name__c, RecordTypeId FROM Account WHERE Id = : updateAccList[0].Id];
        
        System.assert(aveList.size() <> 0);
        
    }
    
    //Description: Test method for inserting new account record.
    private static testMethod void testPositive3() {
        test.startTest();
        
        Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
        paymentTerm.Name = 'SamplePositive3';
        paymentTerm.Apttus_Config2__Sequence__c = 1;
        paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
        paymentTerm.APTS_Ext_ID__c = 'SamplePositive3';
        insert paymentTerm;
        
        Mini_Template__c mt = new Mini_Template__c();
        mt.Name = 'SAP_0333';
        mt.Mini_Sales_Organization__c ='SAP_0333';
        mt.Mini_Currency__c = 'EUR';
        mt.Mini_Terms_of_payment__c = 'SamplePositive3';
        insert mt;

        MiniTemplateTax__c mtt = new MiniTemplateTax__c();
        mtt.Name = 'SAP-0033 -1';
        mtt.Sales_Organization__c = 'SAP_0333';
        insert mtt;
 
 
        Profile p = [SELECT Id FROM Profile WHERE  Name = 'JDE-Integration-Digital']; 
        User u = new User(Alias = 'standt', Email='sample@testUser133.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sample@iukjiyhgjyjcxrd.com', Sales_Organization__c = 'SAP_0333', CurrencyIsoCode = 'EUR', Elevated_Access_Reason__c = 'Defect or Incident Resolution', Elevated_Access_Reference__c = 'ASDF');
        
        Mini_Template__c miniTemplate = Mini_Template__c.getInstance(u.Sales_Organization__c);
        List<MiniTemplateTax__c> miniTemplateTaxes = [Select Id, Name, Sales_Organization__c from MiniTemplateTax__c];

        
        System.runAs(u) {
        
        //insert accounts
        /*List<Account> accList = new List<Account>();
        for(Account acc : TestDataFactory.createAccounts(5,'67031')){
            accList.add(acc);
        }*/
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Archiving_Flag__c = true;
        acc.BillingStreet = 'mainstreet';
        acc.Main_House_Number__c = '123';
        acc.Main_Street_Only__c = 'streetOnly';
        acc.BillingCity = 'mainCity';
        acc.BillingState = 'state';
        acc.BillingPostalCode = 'pCode';
        acc.BillingCountry = 'country';
        acc.Main_Country_ISO__c = 'countryISO';
        //acc.Main_Postal_Box__c = 'pBox';
        acc.Language__c = 'SAP_SR';
        acc.Bill_Block_Reason__c = 'SAP_00';
        acc.Transactional_Block_Reason__c = 'SAP_00';
        acc.Delivery_Block_Reason__c = 'SAP_D3';
        acc.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        acc.SAP_Customer_ID__c = '76509';
        acc.Phone = '+31302979111';      
        acc.Sales_Organization__c = 'SAP_0333';
        acc.Machine_Park_Validated__c = true;
        
          System.debug('u: ' + u);
          //System.debug('miniTemplateTaxes: ' + miniTemplateTaxes);
          
          insert acc;
          test.stopTest();
          Account acct = [SELECT Name, Sales_Organization__c, CurrencyIsoCode, RecordTypeId FROM Account where ID = :acc.Id LIMIT 1];
          System.assertEquals(miniTemplate.Mini_Sales_Organization__c, acct.Sales_Organization__c);
        }
    }
    
    private static testMethod void testPositiveInteg() {
        test.startTest();
        Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
        paymentTerm.Name = 'SamplePositiveInteg';
        paymentTerm.Apttus_Config2__Sequence__c = 1;
        paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
        paymentTerm.APTS_Ext_ID__c = 'SamplePositiveInteg';
        insert paymentTerm;
        
        Mini_Template__c mt = new Mini_Template__c();
        mt.Name = 'SAP_0333';
        mt.Mini_Sales_Organization__c ='SAP_0333';
        mt.Mini_Currency__c = 'EUR';
        mt.Mini_Terms_of_payment__c = 'SamplePositiveInteg';
        insert mt;

        MiniTemplateTax__c mtt = new MiniTemplateTax__c();
        mtt.Name = 'SAP-0033 -1';
        mtt.Sales_Organization__c = 'SAP_0333';
        insert mtt;
 
 
        Profile p = [SELECT Id FROM Profile WHERE  Name =: 'JDE-Integration-Digital']; 
        User u = new User(Alias = 'standt', Email='sample@testUser133000.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sample@iukjiyhgjyjcxrd000.com', Sales_Organization__c = 'SAP_0333', CurrencyIsoCode = 'EUR');
        
        System.runAs(u) {
        
        //insert accounts
        /*List<Account> accList = new List<Account>();
        for(Account acc : TestDataFactory.createAccounts(5,'67031')){
            accList.add(acc);
        }*/
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Archiving_Flag__c = true;
        acc.BillingStreet = 'mainstreet';
        acc.Main_House_Number__c = '123';
        acc.Main_Street_Only__c = 'streetOnly';
        acc.BillingCity = 'mainCity';
        acc.BillingState = 'state';
        acc.BillingPostalCode = 'pCode';
        acc.BillingCountry = 'country';
        acc.Main_Country_ISO__c = 'countryISO';
        //acc.Main_Postal_Box__c = 'pBox';
        acc.Language__c = 'SAP_SR';
        //acc.Bill_Block_Reason__c = 'SAP_00';
        acc.Transactional_Block_Reason__c = 'SAP_00';
        acc.Delivery_Block_Reason__c = 'SAP_D3';
        acc.Apttus_Config2__PaymentTermId__c =paymentTerm.Id;
        acc.SAP_Customer_ID__c = '76509';
        acc.Phone = '+31302979111';        
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
        
          System.debug('u: ' + u);
          //System.debug('miniTemplateTaxes: ' + miniTemplateTaxes);
          
          insert acc;
          Account acct = [SELECT Name, Sales_Organization__c, CurrencyIsoCode, RecordTypeId FROM Account where Name =: acc.Name LIMIT 1];
          Mini_Template__c miniTemplate = Mini_Template__c.getInstance(acc.Sales_Organization__c);
          List<MiniTemplateTax__c> miniTemplateTaxes = [Select Id, Name, Sales_Organization__c from MiniTemplateTax__c];
          test.stopTest();
          
          System.assertEquals(miniTemplate.Mini_Sales_Organization__c, acct.Sales_Organization__c);
        }
    }
    
    private static testMethod void testPositive4() {

        List<Account_Value_Estimation_Size_Price__c> aveList = new List<Account_Value_Estimation_Size_Price__c>();

        for(Account_Value_Estimation_Size_Price__c ave : TestDataFactory.createAVESize(1)){
            ave.Size_Type_Input__c = '# of Seats';
            aveList.add(ave);
        }
        
        for(Account_Value_Estimation_Size_Price__c ave : TestDataFactory.createAVEPrice(1)){
            aveList.add(ave);
        }

        insert aveList;
        
        Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
        paymentTerm.Name = 'Sample';
        paymentTerm.Apttus_Config2__Sequence__c = 1;
        paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
        paymentTerm.APTS_Ext_ID__c = 'abc24';
        insert paymentTerm;
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Archiving_Flag__c = true;
        acc.BillingStreet = 'mainstreet';
        acc.Main_House_Number__c = '123';
        acc.Main_Street_Only__c = 'streetOnly';
        acc.BillingCity = 'mainCity';
        acc.BillingState = 'state';
        acc.BillingPostalCode = 'pCode';
        acc.BillingCountry = 'country';
        acc.Main_Country_ISO__c = 'countryISO';
        //acc.Main_Postal_Box__c = 'pBox';
        acc.Language__c = 'SAP_SR';
        acc.Bill_Block_Reason__c = 'SAP_00';
        acc.Transactional_Block_Reason__c = 'SAP_00';
        acc.Delivery_Block_Reason__c = 'SAP_D3';
        acc.Phone = '+31302979111';
        acc.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
         
        acc.SAP_Customer_ID__c = '04814';
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
        acc.of_seats__c = 100;
        acc.Mini_Company_Code__c = 'SAP_0202';
        acc.Segment__c= 'SAP_A';
        acc.Penetration__c = 100;

        Test.startTest();
        insert acc;
        System.debug('acc: ' + acc);
        
        Account updateAcct = new Account();
        updateAcct = [Select Id, Name FROM Account WHERE Id = :acc.Id];
        
        updateAcct.Name = 'test';
        updateAcct.Second_Account_Name__c = 'SecondTest 1';
        //updateAcct.Sales_Office__c = 'SAP_DK10';
        updateAcct.Archiving_Flag__c = false;
        updateAcct.BillingStreet = 'st';
        updateAcct.Main_House_Number__c = '0000';
        updateAcct.Main_Street_Only__c = 'so';
        updateAcct.BillingCity = 'ct';
        updateAcct.BillingState = 'st';
        updateAcct.BillingPostalCode = 'pCode1';
        updateAcct.BillingCountry = 'country1';
        updateAcct.Main_Country_ISO__c = 'mciso';
        //updateAcct.Main_Postal_Box__c = 'box';
        updateAcct.Language__c = 'SAP_ZH';
        updateAcct.Bill_Block_Reason__c = 'SAP_08';
        updateAcct.Transactional_Block_Reason__c = 'SAP_04';
        updateAcct.Delivery_Block_Reason__c = ' SAP_Z1';
        updateAcct.of_Employees_FTE__c = 100;
        updateAcct.Estimated_Revenue_Potential__c  = 1000;
        updateAcct.Mini_Company_Code__c = 'SAP_0202';
        updateAcct.Segment__c= 'SAP_A';
        updateAcct.Subsegment__c= 'Construction';
        updateAcct.Penetration__c = 100;
        updateAcct.Tea_Drinks__c = 20;
        updateAcct.Avg_Coffee_Dosage__c = 10;
       
    	checkrecursive.run = true;
        update updateAcct;
        System.debug('updateAcct: ' + updateAcct);
        
        Account updateSecond = new Account();
        updateSecond = [Select Id, Name FROM Account WHERE Id = :updateAcct.Id];
        updateSecond.Name = 'Test 2';
        updateSecond.Second_Account_Name__c = 'SecondTest 2';
        //updateSecond.Sales_Office__c = 'SAP_DK20';
        updateSecond.Archiving_Flag__c = true;
        updateSecond.BillingStreet = 'sts';
        updateSecond.Main_House_Number__c = '11111';
        updateSecond.Main_Street_Only__c = 'os';
        updateSecond.BillingCity = 'tc';
        updateSecond.BillingState = 'ts';
        updateSecond.BillingPostalCode = 'Code';
        updateSecond.BillingCountry = 'country2';
        updateSecond.Main_Country_ISO__c = 'iso';
        //updateSecond.Main_Postal_Box__c = 'ox';
        updateSecond.Language__c = 'SAP_TH';
        updateSecond.Bill_Block_Reason__c = 'SAP_09';
        updateSecond.Transactional_Block_Reason__c = '';
        updateSecond.Delivery_Block_Reason__c = 'SAP_Z2';
      
        
        update updateSecond;
        
        Account accRecUpdate = [Select Id, Name, Updated_Account_Name__c
                                FROM Account
                                WHERE Id = :updateSecond.Id];
                        
        System.assertNotEquals(accRecUpdate.Name, accRecUpdate.Updated_Account_Name__c);
        
        Test.stopTest();
    }
    
    private static testMethod void testPositive5() {
        Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
        paymentTerm.Name = 'Sample';
        paymentTerm.Apttus_Config2__Sequence__c = 1;
        paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
        paymentTerm.APTS_Ext_ID__c = 'abc23';
        insert paymentTerm;
            
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Archiving_Flag__c = true;
        acc.BillingStreet = 'mainstreet';
        acc.Main_House_Number__c = '123';
        acc.Main_Street_Only__c = 'streetOnly';
        acc.BillingCity = 'mainCity';
        acc.BillingState = 'state';
        acc.BillingPostalCode = 'pCode';
        acc.BillingCountry = 'country';
        acc.Main_Country_ISO__c = 'countryISO';
        //acc.Main_Postal_Box__c = 'pBox';
        acc.Language__c = 'SAP_SR';
        acc.Bill_Block_Reason__c = 'SAP_00';
        acc.Transactional_Block_Reason__c = 'SAP_00';
        acc.Delivery_Block_Reason__c = 'SAP_D3';
        acc.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
         
        acc.Phone = '+31302979111';
        acc.SAP_Customer_ID__c = '38162';
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Administrative Address').getRecordTypeId();

        Test.startTest();
        insert acc;
        System.debug('acc: ' + acc);
        
        Account updateAcct = new Account();

        //Test.startTest();
        updateAcct = [Select Id, Name FROM Account WHERE Id = :acc.Id];
        
        updateAcct.Name = 'test';
        updateAcct.Second_Account_Name__c = 'SecondTest 1';
        //updateAcct.Sales_Office__c = 'SAP_DK10';
        updateAcct.Archiving_Flag__c = false;
        updateAcct.BillingStreet = 'st';
        updateAcct.Main_House_Number__c = '0000';
        updateAcct.Main_Street_Only__c = 'so';
        updateAcct.BillingCity = 'ct';
        updateAcct.BillingState = 'st';
        updateAcct.BillingPostalCode = 'pCode1';
        updateAcct.BillingCountry = 'country1';
        updateAcct.Main_Country_ISO__c = 'mciso';
        //updateAcct.Main_Postal_Box__c = 'box';
        updateAcct.Language__c = 'SAP_ZH';
        updateAcct.Bill_Block_Reason__c = 'SAP_08';
        updateAcct.Transactional_Block_Reason__c = 'SAP_04';
        updateAcct.Delivery_Block_Reason__c = ' SAP_Z1';
    
        

        update updateAcct;
        
        System.debug('updateAcct: ' + updateAcct);
        
        Account updateSecond = new Account();
        updateSecond = [Select Id, Name FROM Account WHERE Id = :updateAcct.Id];
        updateSecond.Name = 'Test 2';
        updateSecond.Second_Account_Name__c = 'SecondTest 2';
        //updateSecond.Sales_Office__c = 'SAP_DK20';
        updateSecond.Archiving_Flag__c = true;
        updateSecond.BillingStreet = 'sts';
        updateSecond.Main_House_Number__c = '11111';
        updateSecond.Main_Street_Only__c = 'os';
        updateSecond.BillingCity = 'tc';
        updateSecond.BillingState = 'ts';
        updateSecond.BillingPostalCode = 'Code';
        updateSecond.BillingCountry = 'country2';
        updateSecond.Main_Country_ISO__c = 'iso';
        //updateSecond.Main_Postal_Box__c = 'ox';
        updateSecond.Language__c = 'SAP_TH';
        //updateSecond.Bill_Block_Reason__c = 'SAP_10';
        updateSecond.Transactional_Block_Reason__c = '';
        updateSecond.Delivery_Block_Reason__c = 'SAP_Z2';
     
                
        update updateSecond; 
        
        Account accRecUpdate = [Select Id, Name, Updated_Account_Name__c
                                FROM Account
                                WHERE Id = :updateSecond.Id];
                        
        System.assertNotEquals(accRecUpdate.Name, accRecUpdate.Updated_Account_Name__c);
        
        Test.stopTest();
    }
    
    private static testMethod void testpositive6() {
        Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
        paymentTerm.Name = 'Sample';
        paymentTerm.Apttus_Config2__Sequence__c = 1;
        paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
        paymentTerm.APTS_Ext_ID__c = 'abc11';
        insert paymentTerm;
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Archiving_Flag__c = true;
        acc.BillingStreet = 'mainstreet';
        acc.Main_House_Number__c = '123';
        acc.Main_Street_Only__c = 'streetOnly';
        acc.BillingCity = 'mainCity';
        acc.BillingState = 'state';
        acc.BillingPostalCode = 'pCode';
        acc.Main_Country_ISO__c = 'countryISO';
        //acc.Main_Postal_Box__c = 'pBox';
        acc.Language__c = 'SAP_SR';
        acc.Bill_Block_Reason__c = 'SAP_00';
        acc.Transactional_Block_Reason__c = 'SAP_00';
        acc.Delivery_Block_Reason__c = 'SAP_D3';
        acc.Phone = '+31302979111';
        acc.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
         
        acc.SAP_Customer_ID__c = '83195';
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Administrative Address').getRecordTypeId();
        Test.startTest();
        insert acc;
        System.assert(acc.SAP_Customer_ID__c <> Null); 
        Test.stopTest();
    }
    
    //Updated by Alvin Lomod
    private static testMethod void testpositive7Bill2PayerUpdate(){
        Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
        paymentTerm.Name = 'Sample';
        paymentTerm.Apttus_Config2__Sequence__c = 1;
        paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
        paymentTerm.APTS_Ext_ID__c = 'abc12';
        insert paymentTerm;
        
        Account acct = new Account();
        acct.Name = 'accName';
        acct.Second_Account_Name__c = 'sAccName';
        acct.Archiving_Flag__c = true;
        acct.BillingStreet = 'mainstreet';
        acct.Main_House_Number__c = '123';
        acct.Main_Street_Only__c = 'streetOnly';
        acct.BillingCity = 'mainCity';
        acct.BillingState = 'state';
        acct.BillingPostalCode = 'pCode';
        acct.Main_Country_ISO__c = 'countryISO';
        //acct.Main_Postal_Box__c = 'pBox';
        acct.Language__c = 'SAP_SR';
        acct.Bill_Block_Reason__c = 'SAP_00';
        acct.Transactional_Block_Reason__c = 'SAP_00';
        acct.Delivery_Block_Reason__c = 'SAP_D3';
        acct.Phone = '+31302979111';
        acct.SAP_Customer_ID__c = '83195';
        acct.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        acct.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Administrative Address').getRecordTypeId();
        insert acct;
        
        List<Account> accList = new List<Account>();
        
        for(Integer x=0 ; x < 2 ; x++){
            Account acc = new Account();
            acc.Name = 'Account X '+x;
            acc.Phone = '+31302979111'+x;
            //acc.Sales_Office__c = 'SAP_F020';
            acc.Archiving_Flag__c = true;
            acc.BillingStreet = 'mainstreet';
            acc.Main_House_Number__c = '123';
            acc.Main_Street_Only__c = 'streetOnly';
            acc.Main_Country_ISO__c = 'countryISO';
            //acc.Main_Postal_Box__c = 'pBox';
            acc.Language__c = 'SAP_SR';
            acc.Bill_Block_Reason__c = 'SAP_00';
            acc.Transactional_Block_Reason__c = 'SAP_00';
            acc.Delivery_Block_Reason__c = 'SAP_D3';
            acc.Bill_To_Payer_Account__c = acct.Id;
            acc.SAP_Customer_ID__c = '83195'+x;
            acc.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
            acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Administrative Address').getRecordTypeId();
            accList.add(acc);
        }
        
        insert accList;
        
        List<Account> newAccList = [Select Id, Name, Bill_To_Payer_Account__c FROM Account];
        
        newAccList[0].Bill_To_Payer_Account__c = newAccList[1].Id;  
        
        try{
            checkrecursive.run = true;
            test.starttest();
            update newAccList[0];
            
            newAccList[1].Bill_To_Payer_Account__c = newAccList[0].Id;
            update newAccList[1];
            
            System.assertEquals(newAccList[0].Bill_To_Payer_Account__c, newAccList[0].Bill_To_Payer_Account__c);
            test.stoptest(); 
        }                      
        catch (Exception e){
            System.debug(e); 
        }
    }
    
    //Target assignTerritoryDigital
    private static testMethod void testpositive8() {
        Test.startTest();
        
        User integTestUser = createDellIntegUser();
		Account testaccount;
        system.runAs(integTestUser){
        
        Territory_Model__c TMtest = new Territory_Model__c();
        TMtest.Account_Type__c = 'Prospect';
        TMtest.Sales_Organization__c = 'SAP_0111';
        TMtest.Country__c = 'Netherlands';
        TMtest.Active__c = True;
        
        insert TMtest;
            
        Territory__c TerritoryTest = new Territory__c();
        TerritoryTest.Commercial_Territory_Owner__c = integTestUser.Id;
        TerritoryTest.Sales_Inside_1__c = integTestUser.Id;
        TerritoryTest.Sales_Inside_2__c = integTestUser.Id;
        TerritoryTest.Sales_Inside_2__c = integTestUser.Id;
        TerritoryTest.Sales_Outside_2__c = integTestUser.Id;
        TerritoryTest.Customer_Relations_1__c = integTestUser.Id;
        TerritoryTest.Customer_Relations_2__c = integTestUser.Id;
            insert TerritoryTest;
            
        Territory_Rule__c TRtest = new Territory_Rule__c();
        TRtest.Territory_Model__c = TMtest.Id;
        TRtest.Segment__c = 'SAP_A';
        TRtest.Postal_Code_From__c = '123456';
        TRtest.Postal_Code_To__c = '123456';
        TRtest.Industry_Code_From__c = '123456';
        TRtest.Industry_Code_To__c = '123456';
        TRtest.Employees_From__c = '99';
        TRtest.Employees_To__c = '99';
        TRtest.Drinks_To__c = '3';
        TRtest.Beds_To__c = '3';
        TRtest.Seats_To__c = '3';
        TRtest.Visitors_To__c = '100';
        TRtest.Visitors_From__c = '100';
        TRtest.Account_Lifecycle__c = 'Prospect';
        TRtest.Assigned_Territory__c = TerritoryTest.Id;
        insert TRtest;
            
        Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
        paymentTerm.Name = 'Sample';
        paymentTerm.Apttus_Config2__Sequence__c = 1;
        paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
        paymentTerm.APTS_Ext_ID__c = 'asdfsadfsadfdsfasdf4';
        insert paymentTerm;
        
        Mini_Template__c mt = new Mini_Template__c();
        mt.Name = 'SAP_0111';
        mt.Mini_Sales_Organization__c ='SAP_0111';
        mt.Mini_Currency__c = 'EUR';
        mt.Mini_Terms_of_payment__c = 'asdfsadfsadfdsfasdf4';
        insert mt;
        
        MiniTemplateTax__c mtt = new MiniTemplateTax__c();
        mtt.Name = 'SAP_0111 -1';
        mtt.Sales_Organization__c = 'SAP_0111';
        insert mtt;
            
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Archiving_Flag__c = true;
        acc.BillingStreet = 'mainstreet';
        acc.Main_House_Number__c = '123';
        acc.Main_Street_Only__c = 'streetOnly';
        acc.BillingCity = 'mainCity';
        acc.BillingState = 'state';
        acc.BillingPostalCode = 'pCode';
        acc.Main_Country_ISO__c = 'countryISO';
        //acc.Main_Postal_Box__c = 'pBox';
        acc.Language__c = 'SAP_SR';
        acc.Bill_Block_Reason__c = 'SAP_00';
        acc.Transactional_Block_Reason__c = 'SAP_00';
        acc.Delivery_Block_Reason__c = 'SAP_D3';
        acc.Phone = '+31302979111';
        acc.Account_Type__c = 'Customer';
        acc.Sales_Organization__c = 'SAP_0111';
        acc.Main_Country__c = 'Netherlands';
        acc.Account_Tier__c = 'Gold';
        //acc.Segment__c = 'Large Business';
        acc.Account_Lifecycle__c = 'Active Customer';
        acc.Created_by_Integration__c = True;
        acc.Main_Postal_Code__c = '123456';
        acc.of_Employees_FTE__c = 99;
            //acc.of_visitors__c = 3;
            acc.Industry_Code__c = '123456';
        //acc.Apttus_Config2__PaymentTermId__c ='PaymentTerm' + i;
         
        acc.SAP_Customer_ID__c = '83195';
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
        System.debug('Rianno');
        System.debug(acc);
        insert acc; 

        testaccount = [Select Account_Lifecycle__c, 
                           Main_Postal_Code__c, 
                           Industry_Code__c, 
                           of_Beds__c,
                           of_drinks__c,
                           of_Seats__c,
                           of_Employees_FTE__c,
                           of_visitors__c,
                           Sales_Organization__c
                       FROM Account where Id =: acc.Id];
       system.debug(testaccount);
            
       Territory_Rule__c testTR = [Select Account_Lifecycle__c, 
                                        Postal_Code_From__c, 
                                        Industry_Code_From__c, 
                                        Beds_From__c,
                                        Drinks_From__c,
                                        Seats_From__c,
                                        Employees_From__c,
                                        Visitors_From__c,
                                        Industry_Code_To__c FROM Territory_Rule__c where Id =: TRtest.Id];
            
        System.assert(acc.SAP_Customer_ID__c <> Null); 
            
        }
        List<Account> accountFiltered = new List<Account>();
        Map<Id, String> salesOrg = new Map<Id, String>();
        if (integTestUser.Profile.Name <> 'JDE-Integration-Digital'){
            accountFiltered.add(testaccount);
            salesOrg.put(testaccount.Id, integTestUser.Sales_Organization__c); 
        } else {
            accountFiltered.add(testaccount);
            salesOrg.put(testaccount.Id,testaccount.Sales_Organization__c);
        }
        Mini_Template__c miniTemplate = Mini_Template__c.getInstance(salesOrg.get(testaccount.Id));
        Test.stopTest();
        
    }
    //Target stampTransportationZoneBasedOnMainCountryISO
    private static testMethod void testPositive9() {
        
        Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
        paymentTerm.Name = 'Sample';
        paymentTerm.Apttus_Config2__Sequence__c = 1;
        paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
        paymentTerm.APTS_Ext_ID__c = 'abc25';
        insert paymentTerm;
        
        Transportation_Zone__c TZtestAD = new Transportation_Zone__c();
        TZtestAD.Name = 'AD';
        TZtestAD.Transportation_Zone__c = 'SAP_AD001';
		TZtestAD.Main_Country_ISO_Code__c = 'AD';
        insert TZtestAD;
        
        Transportation_Zone__c TZtestAT = new Transportation_Zone__c();
        TZtestAT.Name = 'AT';
        TZtestAT.Transportation_Zone__c = 'SAP_AT001';
		TZtestAT.Main_Country_ISO_Code__c = 'AT';
        insert TZtestAT;
        
        Account acc2 = new Account();
        acc2.Name = 'Test Account';
        acc2.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.Customer).getRecordTypeId();
        acc2.Main_Street_Only__c = 'Test Street';
        acc2.Main_Postal_Code__c = null;
        acc2.Industry_Code__c = null;
        acc2.Phone = '+1234567890';
        acc2.CurrencyIsoCode = 'EUR';
        acc2.Language__c = 'SAP_EN';
        acc2.Sales_Organization__c = 'SAP_0333';
        acc2.Account_Type__c = 'Customer';
        acc2.Segment__c = 'SAP_A'; //Indicator for change of rule
        acc2.of_Beds__c = 10;
        acc2.of_drinks__c = 10;
        acc2.of_Employees_FTE__c = 10;
        acc2.Exclude_from_Territory_Assignment__c = false;
        acc2.of_Seats__c = 10;
        acc2.Account_Lifecycle__c = 'Active Customer';
        acc2.Main_Country_ISO__c = 'AD';
        acc2.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;

        
		system.debug(Transportation_Zone__c.getInstance(acc2.Main_Country_ISO__c));        
        //Update Account
        
        
        Account acc3 = new Account();
        acc3.Name = 'Test Account';
        acc3.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.Customer).getRecordTypeId();
        acc3.Main_Street_Only__c = 'Test Street';
        acc3.Main_Postal_Code__c = null;
        acc3.Industry_Code__c = null;
        acc3.Phone = '+1234567890';
        acc3.CurrencyIsoCode = 'EUR';
        acc3.Language__c = 'SAP_EN';
        acc3.Sales_Organization__c = 'SAP_0333';
        acc3.Account_Type__c = 'Customer';
        acc3.Segment__c = 'SAP_A'; //Indicator for change of rule
        acc3.of_Beds__c = 10;
        acc3.of_drinks__c = 10;
        acc3.of_Employees_FTE__c = 10;
        acc3.Exclude_from_Territory_Assignment__c = false;
        acc3.of_Seats__c = 10;
        acc3.Account_Lifecycle__c = 'Active Customer';
        acc3.Main_Country_ISO__c = 'AD';
        acc3.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        acc3.Updated_Main_Country_ISO__c = 'AD';
		
        test.startTest();
        insert acc2;
        insert acc3;    
        List<Account> acclist = new List<Account>();
        acclist.add(acc2);
        acclist.add(acc3);
        acc2.Main_Country_ISO__c = 'AT';
        //Update Updated_Main_Country_ISO__c Account
        acc3.Updated_Main_Country_ISO__c = 'AT';
        checkrecursive.run = true;
        update acclist;
        Integration_Log__c ilog = SM_AccountUtil.CreateIntegrationLogForAgreementAcc(null, acc2.Id);
        test.stopTest();
        Account accreccheck = [Select Id, Transportation_Zone__c from Account where Id = :acc2.Id];
        system.assertEquals('SAP_AT001', accreccheck.Transportation_zone__c);
        Account accreccheck2 = [Select Id, Transportation_Zone__c from Account where Id = :acc3.Id];
        system.assertEquals('SAP_AT001', accreccheck2.Transportation_zone__c);
    }
    
    //Updated by Alvin Lomod **doesnt make sense**
    /*private static testMethod void testpositive8Bill2PayerInsert(){    
                
        try{
            test.startTest();
            
            //Mass insert bill2payer
            List<Account> accList = new List<Account>();
            for(Integer x=0 ; x < 3 ; x++){
                Account acc = new Account();
                acc.Name = 'Account X '+x;
                acc.Phone = '+31302979111';
                accList.add(acc);
            }
            
            accList[1].Bill_To_Payer_Account__c = accList[2].Id;
            accList[2].Bill_To_Payer_Account__c = accList[1].Id;
            
            insert accList;
            
            test.stopTest();
        }
        catch(Exception e){
            System.debug(e);
        }
               
    }*/
    
    //Description: This is just calling the method.
    //Need to create new scenario/method if the method were used in the trigger.
    /*private static testMethod void callMethod() {
        AccountTriggerHandler acct = new AccountTriggerHandler();
        List<SObject> newItems;
        List<SObject> oldList;
        Map<Id, SObject> oldItems;
        List<SObject> newList;
        Map<Id, SObject> newItemsMap;
        
        acct.BeforeDelete(oldList, oldItems);
        acct.AfterDelete(oldList, oldItems);
        acct.AfterUndelete(newList, newItemsMap);
        
    }*/
    
    private static testMethod void AfterInsert_createIntegratinLogs_Test()
    {   
        Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
        paymentTerm.Name = 'Sample1';
        paymentTerm.Apttus_Config2__Sequence__c = 1;
        paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
        paymentTerm.APTS_Ext_ID__c = 'asdf6';
        insert paymentTerm;
        
        List<Account> accList = new List<Account>();
        Integer i = 10;
        String randSapID = '12344';
        for(integer x = 0; x<=i; x++){
            Account acc = new Account();
            acc.Name = 'accName' + i;
            acc.Second_Account_Name__c = 'sAccName' + i;
            acc.Archiving_Flag__c = false;
            acc.BillingStreet = 'mainstreet' + i;
            acc.Main_House_Number__c = '123' + i;
            acc.Main_Street_Only__c = 'streetOnly' + i;
            acc.BillingCity = 'mainCity' + i;
            acc.BillingState = 'state' + i;
            acc.BillingPostalCode = 'pCode' + i;
            acc.BillingCountry = 'country' + i;
            acc.Main_Country_ISO__c = 'countryISO' + i;
            acc.Language__c = 'SAP_SR';
            acc.Bill_Block_Reason__c = 'SAP_00';
            acc.Transactional_Block_Reason__c = 'SAP_00';
            acc.Delivery_Block_Reason__c = 'SAP_D3';
            acc.Apttus_Config2__PaymentTermId__c =paymentTerm.Id;
            acc.SAP_Customer_ID__c = randSapID + x;
            acc.Phone = '+31302979111';
            acc.Creditworthiness_Flag__c = 'Green';
            acc.Main_Address_Validation_Pending__c = false;
            acc.Sales_Office__c = null;
            accList.add(acc);
        }
        
        Profile p = [SELECT Id FROM Profile WHERE Name =: SM_Constants.SystemAdmin]; 
        User u = new User(Alias = 'standt', Email='sample@testUser1.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sample@testUser1535324.com', Sales_Organization__c = 'SAP_0333', Elevated_Access_Reason__c = 'Defect or Incident Resolution', Elevated_Access_Reference__c = 'ASDF');
        
        Mini_Template__c miniTemplate = Mini_Template__c.getInstance(u.Sales_Organization__c);
        List<MiniTemplateTax__c> miniTemplateTaxes = MiniTemplateTax__c.getall().values();
        
        System.runAs(u) {
          System.debug('u: ' + u);
          System.debug('miniTemplateTaxes: ' + miniTemplateTaxes);
          test.startTest();
          insert accList;
          System.assert(accList[0].Mini_Company_Code__c <> '');
          test.stopTest();
        }
    }
    
    private static testMethod void AfterUpdate_createIntegratinLogs_Test()
    {   
        
        Profile p = [SELECT Id FROM Profile WHERE Name =: SM_Constants.SystemAdmin]; 
        User u = new User(Alias = 'standt', Email='sample@testUser1.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sample@testUser12343.com', Sales_Organization__c = 'SAP_0333', Elevated_Access_Reason__c = 'Defect or Incident Resolution', Elevated_Access_Reference__c = 'ASDF');
        
        System.runAs(u) {
        Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
        paymentTerm.Name = 'Sample2';
        paymentTerm.Apttus_Config2__Sequence__c = 1;
        paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
        paymentTerm.APTS_Ext_ID__c = 'asdf7';
        insert paymentTerm;
            
        List<Account> accList = new List<Account>();
        Integer i = 10;
        String randSapID = '12344';
        for(integer x = 0; x<=i; x++){
            Account acc = new Account();
            acc.Name = 'accName' + i;
            acc.Second_Account_Name__c = 'sAccName' + i;
            acc.Archiving_Flag__c = false;
            acc.BillingStreet = 'mainstreet' + i;
            acc.Main_House_Number__c = '123' + i;
            acc.Main_Street_Only__c = 'streetOnly' + i;
            acc.BillingCity = 'mainCity' + i;
            acc.BillingState = 'state' + i;
            acc.BillingPostalCode = 'pCode' + i;
            acc.BillingCountry = 'country' + i;
            acc.Main_Country_ISO__c = 'countryISO' + i;
            acc.Language__c = 'SAP_SR';
            acc.Bill_Block_Reason__c = 'SAP_00';
            acc.Transactional_Block_Reason__c = 'SAP_00';
            acc.Delivery_Block_Reason__c = 'SAP_D3';
            acc.Apttus_Config2__PaymentTermId__c =paymentTerm.Id;
            acc.SAP_Customer_ID__c = randSapID + x;
            acc.Phone = '+31302979111';
            acc.Creditworthiness_Flag__c = 'Green';
            acc.Main_Address_Validation_Pending__c = false;
            acc.Sales_Office__c = null;
            accList.add(acc);
        }
            
        Mini_Template__c miniTemplate = Mini_Template__c.getInstance(u.Sales_Organization__c);
        List<MiniTemplateTax__c> miniTemplateTaxes = MiniTemplateTax__c.getall().values();
        test.startTest();
        insert accList;
        Integer a = 0;
        for(Account acc : accList)
        {
            acc.SAP_Customer_ID__c = '48107' + a;
            a++;
        }
        
        
          System.debug('u: ' + u);
          System.debug('miniTemplateTaxes: ' + miniTemplateTaxes);
          
          update accList;
          System.assert(accList[0].SAP_Customer_ID__c <> Null);
          test.stopTest();
        }
    }
    
    private static testMethod void BeforeUpdateChangeFieldValueTestSysAd()
    {   
        
        Profile p = [SELECT Id FROM Profile WHERE Name =: SM_Constants.SystemAdmin]; 
        User u = new User(Alias = 'standt', Email='sample@testUser123222.com', 
        EmailEncodingKey='UTF-8', LastName='TestingTest123', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sample@testUser14565.com', Sales_Organization__c = 'SAP_0333', Elevated_Access_Reason__c = 'Defect or Incident Resolution', Elevated_Access_Reference__c = 'ASDF');
        
        System.runAs(u) {
        
        Apttus_Config2__PaymentTerm__c paymentTerm2 = new Apttus_Config2__PaymentTerm__c();
        paymentTerm2.Name = 'Ssdsa';
        paymentTerm2.Apttus_Config2__Sequence__c = 1;
        paymentTerm2.APTS_Sales_Org__c = 'SAP_0333';
        paymentTerm2.APTS_Ext_ID__c = 'smpl123';
        insert paymentTerm2;
            
        List<Account> accList = new List<Account>();
        Integer i = 10;
        String randSapID = '12344';
        for(integer x = 0; x<=i; x++){
            Account acc = new Account();
            acc.Name = 'accName' + i;
            acc.Second_Account_Name__c = 'sAccName' + i;
            acc.Archiving_Flag__c = false;
            acc.BillingStreet = 'mainstreet' + i;
            acc.Main_House_Number__c = '123' + i;
            acc.Main_Street_Only__c = 'streetOnly' + i;
            acc.BillingCity = 'mainCity' + i;
            acc.BillingState = 'state' + i;
            acc.BillingPostalCode = 'pCode' + i;
            acc.BillingCountry = 'country' + i;
            acc.Main_Country_ISO__c = 'countryISO' + i;
            acc.Language__c = 'SAP_SR';
            acc.Bill_Block_Reason__c = 'SAP_00';
            acc.Transactional_Block_Reason__c = 'SAP_00';
            acc.Delivery_Block_Reason__c = 'SAP_D3';
            acc.Apttus_Config2__PaymentTermId__c =paymentTerm2.Id;
            acc.SAP_Customer_ID__c = randSapID + x;
            acc.Phone = '+31302979111';
            acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.AdministrativeAddress).getRecordTypeId();
            acc.Segment__c = 'SAP_A';
            //acc.Mini_Dunning_procedure__c = 'SAP_0079';
            acc.Mini_Invoicing_dates__c = 'SAP_2M';
            acc.Invoice_List_Dates__c = 'SAP_2M';
            acc.Update_Request_Validation_Payment_Term__c = SM_Constants.NoUpdateRequest;
            acc.Update_Request_Validation_Payment_Method__c = SM_Constants.NoUpdateRequest;
            acc.Sales_Office__c = null;
            acc.Creditworthiness_Flag__c = 'Green';
            acc.Main_Address_Validation_Pending__c = false;
            acc.Archiving_Flag__c = false;
            
            accList.add(acc);
        }
        
        Mini_Template__c miniTemplate = Mini_Template__c.getInstance(u.Sales_Organization__c);
        List<MiniTemplateTax__c> miniTemplateTaxes = MiniTemplateTax__c.getall().values();
        test.startTest();
        insert accList;
        Integer a = 0;
        for(Account acc : accList)
        {
            acc.Name = 'Test new eman eman eman';
            acc.Second_Account_Name__c = 'New Test 2nd Name';
            acc.SAP_Customer_ID__c = '48107' + a;
            acc.Main_House_Number__c = '123Test'+a;
            acc.Main_Street_Only__c = 'Street Test' +a;
            acc.BillingCity = 'City of Dreams' + a;
            acc.BillingCountry = 'Netherlands';
            acc.Main_Country_ISO__c = '12345' + a;
            //acc.Main_Postal_Box__c = '54321' + i;
            acc.Bill_Block_Reason__c = 'SAP_11';
            acc.Archiving_Flag__c = true;
            acc.Transactional_Block_Reason__c = 'SAP_03';
            acc.Delivery_Block_Reason__c = 'SAP_Z3';
            acc.Segment__c = 'SAP_B';
            //acc.Mini_Dunning_procedure__c = 'SAP_0079';
            acc.Mini_Invoicing_dates__c = 'SAP_1M';
            acc.Invoice_List_Dates__c = 'SAP_1M';
            acc.howManyLoop__c = 4;
            acc.Apttus_Config2__PaymentTermId__c = paymentTerm2.Id;
            //acc.APTS_Payment_Method__c = pmList[1].Id;
            
            a++;
        }
        
        
          System.debug('u: ' + u);
          System.debug('miniTemplateTaxes: ' + miniTemplateTaxes);
          
          update accList;
          System.assertEquals(accList[0].Apttus_Config2__PaymentTermId__c,  paymentTerm2.Id);
          test.stopTest();
        }
    }
    
    private static testMethod void BeforeUpdateChangeFieldValueTestPRFSales()
    {   
        /*Profile p1 = [SELECT Id FROM Profile WHERE Name =: SM_Constants.SystemAdmin]; 
        User uo = new User(Alias = 'nonamt', Email='sample@testUser2223232.com', 
        EmailEncodingKey='UTF-8', LastName='Testing33', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p1.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sample33@kjhfdksie.com', Sales_Organization__c = 'SAP_0333', Elevated_Access_Reason__c = 'Defect or Incident Resolution', Elevated_Access_Reference__c = 'ASDF');
        
        insert uo;
        
        System.runAs(uo) {
        
        
        
        }*/
        
        Profile p = [SELECT Id FROM Profile WHERE Name =: SM_Constants.JDEEndUser]; 
        User u = new User(Alias = 'standt', Email='sample@testUser1.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sample@testUser134534.com', Sales_Organization__c = 'SAP_0333');
        
        insert u;
        
        PermissionSet ps = [SELECT ID From PermissionSet WHERE Name = 'JDE_Field_Sales_Representative'];
        insert new PermissionSetAssignment(AssigneeId = u.id, PermissionSetId = ps.Id);
        
        System.runAs(u) {
            
        Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
        paymentTerm.Name = 'Test0';
        paymentTerm.Apttus_Config2__Sequence__c = 1;
        paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
        paymentTerm.APTS_Ext_ID__c = 'asdf4';
        insert paymentTerm;
            
        List<Account> accList = new List<Account>();
        Integer i = 10;
        String randSapID = '12344';
        for(integer x = 0; x<=i; x++){
            Account acc = new Account();
            acc.Name = 'accName' + i;
            acc.Second_Account_Name__c = 'sAccName' + i;
            acc.Archiving_Flag__c = false;
            acc.BillingStreet = 'mainstreet' + i;
            acc.Main_House_Number__c = '123' + i;
            acc.Main_Street_Only__c = 'streetOnly' + i;
            acc.BillingCity = 'mainCity' + i;
            acc.BillingState = 'state' + i;
            acc.BillingPostalCode = 'pCode' + i;
            acc.BillingCountry = 'country' + i;
            acc.Main_Country_ISO__c = 'countryISO' + i;
            acc.Language__c = 'SAP_SR';
            acc.Bill_Block_Reason__c = 'SAP_00';
            acc.Transactional_Block_Reason__c = 'SAP_00';
            acc.Delivery_Block_Reason__c = 'SAP_D3';
            acc.Apttus_Config2__PaymentTermId__c =paymentTerm.Id;
            acc.SAP_Customer_ID__c = randSapID + x;
            acc.Phone = '+31302979111';
            acc.Creditworthiness_Flag__c = 'Green';
            acc.Main_Address_Validation_Pending__c = false;
            acc.Archiving_Flag__c = false;
            acc.BillingCity = 'City of Nightmares';
            acc.BillingCountry = 'Belgium';
            acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.AdministrativeAddress).getRecordTypeId();
            acc.Update_Request_Validation_Payment_Term__c = SM_Constants.NoUpdateRequest;
            acc.Update_Request_Validation_Payment_Method__c = SM_Constants.NoUpdateRequest;
            acc.Sales_Office__c = null;
            
            accList.add(acc);
        }
        
        Mini_Template__c miniTemplate = Mini_Template__c.getInstance(u.Sales_Organization__c);
        List<MiniTemplateTax__c> miniTemplateTaxes = MiniTemplateTax__c.getall().values();
        test.startTest();
        insert accList;
        Integer a = 0;
        for(Account acc1 : accList)
        {
            acc1.Name = 'Test new eman eman eman';
            acc1.Second_Account_Name__c = 'New Test 2nd Name';
            acc1.SAP_Customer_ID__c = '48107' + a;
            acc1.Main_House_Number__c = '123Test'+ a;
            acc1.Main_Street_Only__c = 'Street Test' +a;
            acc1.BillingCity = 'City of Dreams' + a;
            acc1.BillingCountry = 'Norway';
            acc1.Main_Country_ISO__c = '12345' + a;
            //acc1.Main_Postal_Box__c = '54321' + i;
            acc1.Bill_Block_Reason__c = 'SAP_11';
            acc1.Archiving_Flag__c = true;
            acc1.Transactional_Block_Reason__c = 'SAP_03';
            acc1.Delivery_Block_Reason__c = 'SAP_Z3';
            //acc1.howManyLoop__c = 4;
            acc1.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
            
            a++;
        }
        
        
          System.debug('u: ' + u);
          System.debug('miniTemplateTaxes: ' + miniTemplateTaxes);
          
          update accList;
          System.assertEquals(accList[0].Apttus_Config2__PaymentTermId__c, paymentTerm.Id);
          test.stopTest();
        }
    }
    
    private static testMethod void BeforeUpdateChangeFieldValueTestPRFSales2()
    {        
        /*Profile p1 = [SELECT Id FROM Profile WHERE Name =: SM_Constants.SystemAdmin]; 
        User uo = new User(Alias = 'nonamt', Email='sample@testUser2212312.com', 
        EmailEncodingKey='UTF-8', LastName='Testing33', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p1.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sample33@testUser1275465.com', Sales_Organization__c = 'SAP_0333', Elevated_Access_Reason__c = 'Defect or Incident Resolution', Elevated_Access_Reference__c = 'ASDF');
        
        insert uo;
        
        System.runAs(uo) {
        
        
            
        }*/
        
        Profile p = [SELECT Id FROM Profile WHERE Name =: SM_Constants.JDEEndUser]; 
        User u = new User(Alias = 'standt', Email='sample@testUser1.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sample@testUser156565.com', Sales_Organization__c = 'SAP_0333', Finance_Controller_Unique__c = 'finance');
        
        insert u;
        
        PermissionSet ps = [SELECT ID From PermissionSet WHERE Name = 'JDE_Field_Sales_Representative'];
        insert new PermissionSetAssignment(AssigneeId = u.id, PermissionSetId = ps.Id);
        
        System.runAs(u) {
        //List<APTS_Payment_Method__c> paymentMethods = [SELECT Id FROM APTS_Payment_Method__c WHERE Name LIKE '%Sample Method%'];
        Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
        paymentTerm.Name = 'Test01';
        paymentTerm.Apttus_Config2__Sequence__c = 1;
        paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
        paymentTerm.APTS_Ext_ID__c = 'asdf5';
        insert paymentTerm;
            
        List<Account> accList = new List<Account>();
        Integer i = 10;
        String randSapID = '12344';
        for(integer x = 0; x<=i; x++){
            Account acc = new Account();
            acc.Name = 'accName' + i;
            acc.Second_Account_Name__c = 'sAccName' + i;
            acc.Archiving_Flag__c = false;
            acc.BillingStreet = 'mainstreet' + i;
            acc.Main_House_Number__c = '123' + i;
            acc.Main_Street_Only__c = 'streetOnly' + i;
            acc.BillingCity = 'mainCity' + i;
            acc.BillingState = 'state' + i;
            acc.BillingPostalCode = 'pCode' + i;
            acc.BillingCountry = 'country' + i;
            acc.Main_Country_ISO__c = 'countryISO' + i;
            acc.Language__c = 'SAP_SR';
            acc.Bill_Block_Reason__c = 'SAP_00';
            acc.Transactional_Block_Reason__c = 'SAP_00';
            acc.Delivery_Block_Reason__c = 'SAP_D3';
            acc.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
            acc.SAP_Customer_ID__c = randSapID + x;
            acc.Phone = '+31302979111';
            acc.Creditworthiness_Flag__c = 'Green';
            acc.Main_Address_Validation_Pending__c = false;
            acc.Archiving_Flag__c = false;
            acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.AdministrativeAddress).getRecordTypeId();
            acc.Update_Request_Validation_Payment_Term__c = SM_Constants.NoUpdateRequest;
            acc.Update_Request_Validation_Payment_Method__c = SM_Constants.NoUpdateRequest;
            acc.Sales_Office__c = null;
            accList.add(acc);
        }
        
        Mini_Template__c miniTemplate = Mini_Template__c.getInstance(u.Sales_Organization__c);
        List<MiniTemplateTax__c> miniTemplateTaxes = MiniTemplateTax__c.getall().values();
        test.startTest();
        insert accList;
        Integer a = 0;
        for(Account acc : accList)
        {
            acc.Updated_Main_City__c = null;
            acc.Updated_Main_Country__c = null;
            acc.SAP_Customer_ID__c = '48107' + a;
            acc.BillingCity = 'City of Dreams' + a;
            acc.BillingCountry = 'Norway';
            acc.Main_Country_ISO__c = '12345' + a;
            //acc.Main_Postal_Box__c = '54321' + i;
            acc.Bill_Block_Reason__c = 'SAP_11';
            acc.Archiving_Flag__c = true;
            acc.Transactional_Block_Reason__c = 'SAP_03';
            acc.Delivery_Block_Reason__c = 'SAP_Z3';
            //acc.howManyLoop__c = 4;
            acc.Second_Account_Name__c = 'Account 2nd Name Test';
            acc.Updated_Second_Account_Name__c = null;
            
            a++;
        }
        
        
          System.debug('u: ' + u);
          System.debug('miniTemplateTaxes: ' + miniTemplateTaxes);
          
          update accList;
          System.assertEquals(accList[0].Apttus_Config2__PaymentTermId__c, paymentTerm.Id);
          test.stopTest();
        }
    }
    
    private static testMethod void AssignAndReassignAccountTerritory(){
        test.startTest();
        
        List<Territory_Model__c> modelList = new List<Territory_Model__c>();
        
        //Create Territory Models
        Territory_Model__c model1 = new Territory_Model__c();
        model1.Name = 'Test Model 1';
        model1.Description__c = 'Test';
        model1.Sales_Organization__c = 'SAP_0111';
        model1.Country__c = 'Netherlands';
        model1.Account_Type__c = 'Customer';
        model1.Active__c = true;
        modelList.add(model1);
        
        Territory_Model__c model2 = new Territory_Model__c();
        model2.Name = 'Test Model 2';
        model2.Description__c = 'Test';
        model2.Sales_Organization__c = 'SAP_0111';
        model2.Country__c = 'Netherlands';
        model2.Account_Type__c = 'Customer';
        model2.Active__c = false;
        modelList.add(model2);
        
        insert modelList;
        
        //Create Territory
        Territory__c territory = new Territory__c();
        territory.Commercial_Territory_Owner__c = UserInfo.getUserId();
        insert territory;       
        
        //Create Territory Rule1
        Territory_Rule__c rule1 = new Territory_Rule__c();
        rule1.Account_Lifecycle__c = 'Active Customer';
        rule1.Beds_From__c = '0';
        rule1.Beds_To__c = '1000';
        rule1.Drinks_From__c = '0';
        rule1.Drinks_To__c = '1000';
        rule1.Employees_From__c = '0';
        rule1.Employees_To__c = '1000';
        rule1.Seats_From__c = '0';
        rule1.Seats_To__c = '1000';
        rule1.Assigned_Territory__c = territory.id;
        rule1.Postal_Code_From__c = '0';
        rule1.Postal_Code_To__c = '1000';
        rule1.Industry_Code_From__c = '0';
        rule1.Industry_Code_To__c = '1000';
        rule1.Segment__c = 'SAP_A;'; //Indicator for change of rule
        rule1.Territory_Model__c = modelList[0].id;
        insert rule1;
        
        //Create Territory Rule2
        Territory_Rule__c rule2 = new Territory_Rule__c();
        rule2.Account_Lifecycle__c = 'Active Customer';
        rule2.Beds_From__c = '0';
        rule2.Beds_To__c = '1000';
        rule2.Drinks_From__c = '0';
        rule2.Drinks_To__c = '1000';
        rule2.Employees_From__c = '0';
        rule2.Employees_To__c = '1000';
        rule2.Seats_From__c = '0';
        rule2.Seats_To__c = '1000';
        rule2.Assigned_Territory__c = territory.id;
        rule2.Postal_Code_From__c = '0';
        rule2.Postal_Code_To__c = '1000';
        rule2.Industry_Code_From__c = '0000';
        rule2.Industry_Code_To__c = '1000';
        rule2.Segment__c = 'SAP_B'; //Indicator for change of rule
        rule2.Territory_Model__c = modelList[0].id;
        insert rule2;
        
        //Automatically assign account to the territory Model
        //Create Account
        Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
        paymentTerm.Name = 'Sample';
        paymentTerm.Apttus_Config2__Sequence__c = 1;
        paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
        paymentTerm.APTS_Ext_ID__c = 'abc13';
        insert paymentTerm;
        
        List<Account> accList = new List<Account>();
        Account acc1 = new Account();
        acc1.Name = 'Test Account';
        acc1.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.Customer).getRecordTypeId();
        acc1.Main_Street_Only__c = 'Test Street';
        acc1.Main_Postal_Code__c = '1000';
        acc1.Industry_Code__c = '100';
        acc1.Phone = '+1234567890';
        acc1.CurrencyIsoCode = 'EUR';
        acc1.Language__c = 'SAP_EN';
        acc1.Sales_Organization__c = 'SAP_0111';
        acc1.Main_Country__c = 'Netherlands';
        acc1.Account_Type__c = 'Customer';
        acc1.Segment__c = 'SAP_A'; //Indicator for change of rule
        acc1.of_Beds__c = 10;
        acc1.of_drinks__c = 10;
        acc1.of_Employees_FTE__c = 10;
        acc1.Exclude_from_Territory_Assignment__c = false;
        acc1.of_Seats__c = 10;
        acc1.Account_Lifecycle__c = 'Active Customer';
        acc1.Apttus_Config2__PaymentTermId__c =paymentTerm.Id;
        accList.add(acc1);
        
        Account acc2 = new Account();
        acc2.Name = 'Test Account';
        acc2.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.Customer).getRecordTypeId();
        acc2.Main_Street_Only__c = 'Test Street';
        acc2.Main_Postal_Code__c = null;
        acc2.Industry_Code__c = null;
        acc2.Phone = '+1234567890';
        acc2.CurrencyIsoCode = 'EUR';
        acc2.Language__c = 'SAP_EN';
        acc2.Sales_Organization__c = 'SAP_0111';
        acc2.Main_Country__c = 'Netherlands';
        acc2.Account_Type__c = 'Customer';
        acc2.Segment__c = 'SAP_A'; //Indicator for change of rule
        acc2.of_Beds__c = 10;
        acc2.of_drinks__c = 10;
        acc2.of_Employees_FTE__c = 10;
        acc2.Exclude_from_Territory_Assignment__c = false;
        acc2.of_Seats__c = 10;
        acc2.Account_Lifecycle__c = 'Active Customer';
        acc2.Apttus_Config2__PaymentTermId__c =paymentTerm.Id;
        accList.add(acc2);
        
        insert accList;
        
        Account accResIns = [SELECT Id, Applied_Territory_Rule__c FROM Account WHERE Id =: accList[0].Id LIMIT 1];
        //Account is assigned to Rule1
        system.assertEquals(accResIns.Applied_Territory_Rule__c, null);
        
        //Update Account
        accList[0].Segment__c = 'SAP_B';
        accList[0].Main_Postal_Code__c = null;
        accList[0].Industry_Code__c = null;
        accList[0].Main_Address_Validation_Timestamp__c = System.today();
        accList[1].Segment__c = 'SAP_B';
        accList[1].Main_Postal_Code__c = '999';
        accList[1].Industry_Code__c = '1000';
        accList[1].Main_Address_Validation_Timestamp__c = System.today() + 1;
        checkrecursive.run = true;
        update accList;
        
        //Error Account
        Account acc3 = new Account();
        acc3.Name = 'Test Account';
        acc3.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.Customer).getRecordTypeId();
        acc3.Main_Street_Only__c = 'Test Street';
        acc3.Main_Postal_Code__c = 'ABCD';
        acc3.Industry_Code__c = null;
        acc3.Phone = '+1234567890';
        acc3.CurrencyIsoCode = 'EUR';
        acc3.Language__c = 'SAP_EN';
        acc3.Sales_Organization__c = 'SAP_0111';
        acc3.Account_Type__c = 'Customer';
        acc3.Segment__c = 'SAP_A'; //Indicator for change of rule
        acc3.of_Beds__c = 10;
        acc3.of_drinks__c = 10;
        acc3.of_Employees_FTE__c = 10;
        acc3.Exclude_from_Territory_Assignment__c = false;
        acc3.of_Seats__c = 10;
        acc3.Account_Lifecycle__c = 'Active Customer';
        acc3.Apttus_Config2__PaymentTermId__c =paymentTerm.Id;
        accList.add(acc3);
        
        try{
            accList[1].Main_Postal_Code__c = 'ABCD';
            accList[1].Industry_Code__c = '1000';
            checkrecursive.run = true;
            upsert accList;
             Account accResUpd = [SELECT Id, Applied_Territory_Rule__c FROM Account WHERE Id =: accList[1].Id LIMIT 1];
            //Account is assigned to Rule2
            system.assert(accResUpd.Applied_Territory_Rule__c != null);
            
            
            test.stopTest();
            
        } catch(Exception ex){
            
        }
        
       
    }
    
    static testMethod void testTriggerOff(){
        
        TriggerSettings__c triggerSettings = TriggerSettings__c.getOrgDefaults();
        triggerSettings.AccountTrigger__c = false;
        upsert triggerSettings TriggerSettings__c.Id;
        //insert new TriggerSettings__c(AccountTrigger__c = false);
        
        test.startTest();
        AccountTriggerHandler accth = new AccountTriggerHandler();
        TriggerDispatcher.Run(accth);
        test.stopTest();
        //TriggerSettings__c triggerSettings = TriggerSettings__c.getInstance();
        System.Assert(triggerSettings.AccountTrigger__c == false);
    
    }
    
     private static testMethod void testSicCodesInsert() {
        Profile p = [SELECT Id FROM Profile WHERE  Name =: SM_Constants.JDEEndUser]; 
        User u = new User(Alias = 'standt', Email='sample@testUser11.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sample@testUser123432.com', Country= 'Belgium');
        
        Profile p1 = [SELECT Id FROM Profile WHERE  Name =: SM_Constants.SystemAdmin]; 
        User u1 = new User(Alias = 'standt', Email='sample@testUser111.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p1.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sample@testUser22324.com', Country= 'Belgium');
        
        JDE_SIC_Mapping__c sicmapping = new JDE_SIC_Mapping__c();
        sicmapping.Name = '1234 - sample';
        sicmapping.SIC_Code__c = '1234';
        sicmapping.SIC_Description__c = 'sample';
        sicmapping.Segment_2__c = 'Business';
        sicmapping.Sub_Segment__c = 'Trading & Retail';
        
        JDE_SIC_Mapping__c sicmappingdoc = new JDE_SIC_Mapping__c();
        sicmappingdoc.Name = '4321 - sample';
        sicmappingdoc.SIC_Code__c = '4321';
        sicmappingdoc.SIC_Description__c = 'sample';
        sicmappingdoc.Segment_2__c = 'Health & Care';
        sicmappingdoc.Sub_Segment__c = 'Doctors, Dentists and other practitioners';
        
        JDE_SIC_Mapping__c sicmappingally = new JDE_SIC_Mapping__c();
        sicmappingally.Name = '2345 - sample';
        sicmappingally.SIC_Code__c = '2345';
        sicmappingally.SIC_Description__c = 'sample';
        sicmappingally.Segment_2__c = 'Health & Care';
        sicmappingally.Sub_Segment__c = 'Health and allied services';
        
        JDE_SIC_Mapping__c sicmappingeduc = new JDE_SIC_Mapping__c();
        sicmappingeduc.Name = '5432 - sample';
        sicmappingeduc.SIC_Code__c = '5432';
        sicmappingeduc.SIC_Description__c = 'sample';
        sicmappingeduc.Segment_2__c = 'Education';
        sicmappingeduc.Sub_Segment__c = 'Other Education';
       
        
        JDE_SIC_Mapping__c sicmapping1to1 = new JDE_SIC_Mapping__c();
        sicmapping1to1.Name = '1111 - sample';
        sicmapping1to1.SIC_Code__c = '1111';
        sicmapping1to1.SIC_Description__c = 'sample';
        sicmapping1to1.Segment_2__c = 'Leisure';
        sicmapping1to1.Sub_Segment__c = 'Sports & Recreation';

        
        JDE_SIC_Mapping__c sicmapping1to12 = new JDE_SIC_Mapping__c();
        sicmapping1to12.Name = '2222 - sample';
        sicmapping1to12.SIC_Code__c = '2222';
        sicmapping1to12.SIC_Description__c = 'sample';
        sicmapping1to12.Segment_2__c = 'Convenience & Retail';
        sicmapping1to12.Sub_Segment__c = 'Gas stations';
    
        
        JDE_SIC_Mapping__c sicmapping1to13 = new JDE_SIC_Mapping__c();
        sicmapping1to13.Name = '6666 - sample';
        sicmapping1to13.SIC_Code__c = '6666';
        sicmapping1to13.SIC_Description__c = 'sample';
        sicmapping1to13.Segment_2__c = 'Quick Ser & Coffee';
        sicmapping1to13.Sub_Segment__c = 'QSR';
    
        
        JDE_SIC_Mapping__c sicmapping1to14 = new JDE_SIC_Mapping__c();
        sicmapping1to14.Name = '3333 - sample';
        sicmapping1to14.SIC_Code__c = '3333';
        sicmapping1to14.SIC_Description__c = 'sample';
        sicmapping1to14.Segment_2__c = 'Rest. Cafes & Bars';
        sicmapping1to14.Sub_Segment__c = 'Restaurants';
        
        
        JDE_SIC_Mapping__c sicmapping1to15 = new JDE_SIC_Mapping__c();
        sicmapping1to15.Name = '4444 - sample';
        sicmapping1to15.SIC_Code__c = '4444';
        sicmapping1to15.SIC_Description__c = 'sample';
        sicmapping1to15.Segment_2__c = 'Hotels and Gaming';
        sicmapping1to15.Sub_Segment__c = 'Hotels';
       
        
        JDE_SIC_Mapping__c sicmapping1to16 = new JDE_SIC_Mapping__c();
        sicmapping1to16.Name = '5555 - sample';
        sicmapping1to16.SIC_Code__c = '5555';
        sicmapping1to16.SIC_Description__c = 'sample';
        sicmapping1to16.Segment_2__c = 'Education';
        sicmapping1to16.Sub_Segment__c = 'Universities & Colleges';
        
        JDE_SIC_Mapping__c sicmapping1to17 = new JDE_SIC_Mapping__c();
        sicmapping1to17.Name = '7777 - sample';
        sicmapping1to17.SIC_Code__c = '7777';
        sicmapping1to17.SIC_Description__c = 'sample';
        sicmapping1to17.Segment_2__c = 'Health & Care';
        sicmapping1to17.Sub_Segment__c = 'Hospitals';
        
        List<JDE_SIC_Mapping__c> sicmaplist = new List<JDE_SIC_Mapping__c>();
        sicmaplist.add(sicmapping);
        sicmaplist.add(sicmappingdoc);
        sicmaplist.add(sicmappingally);
        sicmaplist.add(sicmapping1to1);
        sicmaplist.add(sicmapping1to12);
        sicmaplist.add(sicmapping1to13);
        sicmaplist.add(sicmapping1to14);
        sicmaplist.add(sicmapping1to15);
        sicmaplist.add(sicmapping1to16);
        sicmaplist.add(sicmapping1to17);
        sicmaplist.add(sicmappingeduc);
        
        Test.startTest();
        insert sicmaplist;
        
        System.runAs(u){
        Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
        paymentTerm.Name = 'Sample';
        paymentTerm.Apttus_Config2__Sequence__c = 1;
        paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
        paymentTerm.APTS_Ext_ID__c = 'abc6';
        insert paymentTerm;   
            
        Account acc1 = new Account();
        acc1.Name = 'SicTest';
        acc1.Main_House_Number__c = '1234';
        acc1.Main_Street_Only__c = 'streetOnly';
        acc1.Main_Postal_Code__c = '1234';
        acc1.Main_City__c = '1234';
        acc1.Phone = '+31302979111';
        acc1.Account_Tier__c = 'Gold';
        acc1.SIC_Name__c = sicmaplist[1].Id;
        acc1.of_Employees_FTE__c = 1;
        acc1.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        acc1.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
        
        Account acc2 = new Account();
        acc2.Name = 'SicTest2';
        acc2.Main_House_Number__c = '1111';
        acc2.Main_Street_Only__c = 'streetOnly';
        acc2.Main_Postal_Code__c = '1111';
        acc2.Main_City__c = '1111';
        acc2.Phone = '+31302979111';
        acc2.Account_Tier__c = 'Gold';
        acc2.SIC_Name__c = sicmaplist[1].Id;
        acc2.of_Employees_FTE__c = 52;
        acc2.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        acc2.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
        
        Account acc3 = new Account();
        acc3.Name = 'SicTest3';
        acc3.Main_House_Number__c = '2222';
        acc3.Main_Street_Only__c = 'streetOnly';
        acc3.Main_Postal_Code__c = '2222';
        acc3.Main_City__c = '2222';
        acc3.Phone = '+31302979111';
        acc3.Account_Tier__c = 'Gold';
        acc3.SIC_Name__c = sicmaplist[1].Id;
        acc3.of_Employees_FTE__c = 300;
        acc3.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        acc3.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
        
        Account acc4 = new Account();
        acc4.Name = 'SicTest4';
        acc4.Main_House_Number__c = '3333';
        acc4.Main_Street_Only__c = 'streetOnly';
        acc4.Main_Postal_Code__c = '3333';
        acc4.Main_City__c = '3333';
        acc4.Phone = '+31302979111';
        acc4.Account_Tier__c = 'Gold';
        acc4.SIC_Name__c = sicmaplist[10].Id;
        acc4.of_Employees_FTE__c = 1;
        acc4.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        acc4.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
        
        Account acc5 = new Account();
        acc5.Name = 'SicTest5';
        acc5.Main_House_Number__c = '4444';
        acc5.Main_Street_Only__c = 'streetOnly';
        acc5.Main_Postal_Code__c = '4444';
        acc5.Main_City__c = '4444';
        acc5.Phone = '+31302979111';
        acc5.Account_Tier__c = 'Gold';
        acc5.SIC_Name__c = sicmaplist[10].Id;
        acc5.of_Employees_FTE__c = 52;
        acc5.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        acc5.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
        
        Account acc6 = new Account();
        acc6.Name = 'SicTest6';
        acc6.Main_House_Number__c = '5555';
        acc6.Main_Street_Only__c = 'streetOnly';
        acc6.Main_Postal_Code__c = '5555';
        acc6.Main_City__c = '5555';
        acc6.Phone = '+31302979111';
        acc6.Account_Tier__c = 'Gold';
        acc6.SIC_Name__c = sicmaplist[10].Id;
        acc6.of_Employees_FTE__c = 300;
        acc6.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        acc6.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
        
        Account acc7 = new Account();
        acc7.Name = 'SicTest7';
        acc7.Main_House_Number__c = '6666';
        acc7.Main_Street_Only__c = 'streetOnly';
        acc7.Main_Postal_Code__c = '6666';
        acc7.Main_City__c = '6666';
        acc7.Phone = '+31302979111';
        acc7.Account_Tier__c = 'Gold';
        acc7.SIC_Name__c = sicmaplist[3].Id;
        acc7.of_Employees_FTE__c = 1;
        acc7.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        acc7.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
        
        Account acc8 = new Account();
        acc8.Name = 'SicTest8';
        acc8.Main_House_Number__c = '7777';
        acc8.Main_Street_Only__c = 'streetOnly';
        acc8.Main_Postal_Code__c = '7777';
        acc8.Main_City__c = '7777';
        acc8.Phone = '+31302979111';
        acc8.Account_Tier__c = 'Gold';
        acc8.SIC_Name__c = sicmaplist[4].Id;
        acc8.of_Employees_FTE__c = 1;
        acc8.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        acc8.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
        
        Account acc9 = new Account();
        acc9.Name = 'SicTest9';
        acc9.Main_House_Number__c = '8888';
        acc9.Main_Street_Only__c = 'streetOnly';
        acc9.Main_Postal_Code__c = '8888';
        acc9.Main_City__c = '8888';
        acc9.Phone = '+31302979111';
        acc9.Account_Tier__c = 'Gold';
        acc9.SIC_Name__c = sicmaplist[5].Id;
        acc9.of_Employees_FTE__c = 1;
        acc9.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        acc9.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
        
        Account acc10 = new Account();
        acc10.Name = 'SicTest10';
        acc10.Main_House_Number__c = '1010';
        acc10.Main_Street_Only__c = 'streetOnly';
        acc10.Main_Postal_Code__c = '1010';
        acc10.Main_City__c = '1010';
        acc10.Phone = '+31302979111';
        acc10.Account_Tier__c = 'Gold';
        acc10.SIC_Name__c = sicmaplist[6].Id;
        acc10.of_Employees_FTE__c = 1;
        acc10.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        acc10.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
        
        Account acc11 = new Account();
        acc11.Name = 'SicTest11';
        acc11.Main_House_Number__c = '0101';
        acc11.Main_Street_Only__c = 'streetOnly';
        acc11.Main_Postal_Code__c = '0101';
        acc11.Main_City__c = '0101';
        acc11.Phone = '+31302979111';
        acc11.Account_Tier__c = 'Gold';
        acc11.SIC_Name__c = sicmaplist[7].Id;
        acc11.of_Employees_FTE__c = 1;
        acc11.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        acc11.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
        
        Account acc12 = new Account();
        acc12.Name = 'SicTest12';
        acc12.Main_House_Number__c = '2323';
        acc12.Main_Street_Only__c = 'streetOnly';
        acc12.Main_Postal_Code__c = '2323';
        acc12.Main_City__c = '2323';
        acc12.Phone = '+31302979111';
        acc12.Account_Tier__c = 'Gold';
        acc12.SIC_Name__c = sicmaplist[8].Id;
        acc12.of_Employees_FTE__c = 1;
        acc12.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        acc12.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
        
        Account acc13 = new Account();
        acc13.Name = 'SicTest9';
        acc13.Main_House_Number__c = '3232';
        acc13.Main_Street_Only__c = 'streetOnly';
        acc13.Main_Postal_Code__c = '3232';
        acc13.Main_City__c = '3232';
        acc13.Phone = '+31302979111';
        acc13.Account_Tier__c = 'Gold';
        acc13.SIC_Name__c = sicmaplist[9].Id;
        acc13.of_Employees_FTE__c = 1;
        acc13.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        acc13.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
        
        Account acc14 = new Account();
        acc14.Name = 'SicTest';
        acc14.Main_House_Number__c = '1234';
        acc14.Main_Street_Only__c = 'streetOnly';
        acc14.Main_Postal_Code__c = '1234';
        acc14.Main_City__c = '1234';
        acc14.Phone = '+31302979111';
        acc14.Account_Tier__c = 'Gold';
        acc14.SIC_Name__c = sicmaplist[0].Id;
        acc14.of_Employees_FTE__c = 1;
        acc14.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        acc14.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
        
        Account acc15 = new Account();
        acc15.Name = 'SicTest2';
        acc15.Main_House_Number__c = '1111';
        acc15.Main_Street_Only__c = 'streetOnly';
        acc15.Main_Postal_Code__c = '1111';
        acc15.Main_City__c = '1111';
        acc15.Phone = '+31302979111';
        acc15.Account_Tier__c = 'Gold';
        acc15.SIC_Name__c = sicmaplist[0].Id;
        acc15.of_Employees_FTE__c = 52;
        acc15.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        acc15.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
        
        Account acc16 = new Account();
        acc16.Name = 'SicTest3';
        acc16.Main_House_Number__c = '2222';
        acc16.Main_Street_Only__c = 'streetOnly';
        acc16.Main_Postal_Code__c = '2222';
        acc16.Main_City__c = '2222';
        acc16.Phone = '+31302979111';
        acc16.Account_Tier__c = 'Gold';
        acc16.SIC_Name__c = sicmaplist[0].Id;
        acc16.of_Employees_FTE__c = 300;
        acc16.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        acc16.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();     

		Account acc17 = new Account();
        acc17.Name = 'SicTest';
        acc17.Main_House_Number__c = '1234';
        acc17.Main_Street_Only__c = 'streetOnly';
        acc17.Main_Postal_Code__c = '1234';
        acc17.Main_City__c = '1234';
        acc17.Phone = '+31302979111';
        acc17.Account_Tier__c = 'Gold';
        acc17.SIC_Name__c = sicmaplist[2].Id;
        acc17.of_Employees_FTE__c = 1;
        acc17.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        acc17.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
        
        Account acc18 = new Account();
        acc18.Name = 'SicTest2';
        acc18.Main_House_Number__c = '1111';
        acc18.Main_Street_Only__c = 'streetOnly';
        acc18.Main_Postal_Code__c = '1111';
        acc18.Main_City__c = '1111';
        acc18.Phone = '+31302979111';
        acc18.Account_Tier__c = 'Gold';
        acc18.SIC_Name__c = sicmaplist[2].Id;
        acc18.of_Employees_FTE__c = 52;
        acc18.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        acc18.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
        
        Account acc19 = new Account();
        acc19.Name = 'SicTest3';
        acc19.Main_House_Number__c = '2222';
        acc19.Main_Street_Only__c = 'streetOnly';
        acc19.Main_Postal_Code__c = '2222';
        acc19.Main_City__c = '2222';
        acc19.Phone = '+31302979111';
        acc19.Account_Tier__c = 'Gold';
        acc19.SIC_Name__c = sicmaplist[2].Id;
        acc19.of_Employees_FTE__c = 300;
        acc19.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        acc19.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();	
            
        List<Account> insertsic = new List<Account>();
        insertsic.add(acc1);
        insertsic.add(acc2);
        insertsic.add(acc3);
        insertsic.add(acc4);
        insertsic.add(acc5);
        insertsic.add(acc7);
        insertsic.add(acc8);
        insertsic.add(acc9);
        insertsic.add(acc10);
        insertsic.add(acc11);
        insertsic.add(acc12);
        insertsic.add(acc13);
        insertsic.add(acc6);
        insertsic.add(acc14);
        insertsic.add(acc15);
        insertsic.add(acc16);
        insertsic.add(acc17);
        insertsic.add(acc18);
        insertsic.add(acc19);
        
        insert insertsic;
        
        Account updateAcct = new Account();
        updateAcct = [Select Id, Name, Segment__c, Subsegment__c FROM Account WHERE Id = :acc7.Id];
        updateAcct.SIC_Name__c = sicmaplist[6].Id;
        update updateAcct;
        
        Account updateAcct1 = new Account();
        updateAcct1 = [Select Id, Name, Segment__c, Subsegment__c FROM Account WHERE Id = :updateAcct.Id];
        updateAcct1.SIC_Name__c = sicmaplist[7].Id;
        update updateAcct1;
        
        Account updateAcct2 = new Account();
        updateAcct2 = [Select Id, Name, Segment__c, Subsegment__c FROM Account WHERE Id = :updateAcct1.Id];
        updateAcct2.SIC_Name__c = sicmaplist[8].Id;
        update updateAcct2;
        
        Account updateAcct3 = new Account();
        updateAcct3 = [Select Id, Name, Segment__c, Subsegment__c FROM Account WHERE Id = :updateAcct2.Id];
        updateAcct3.SIC_Name__c = sicmaplist[9].Id;
        updateAcct3.Segment__c = null;
        updateAcct3.Subsegment__c = null;
        update updateAcct3;
               
        System.assertEquals(updateAcct2.Segment__c, 'SAP_A');    
        System.assertEquals(updateAcct2.Subsegment__c, 'Education');  
        System.assertEquals(updateAcct3.Segment__c, null);    
        System.assertEquals(updateAcct3.Subsegment__c, null);  
        }
        Test.stopTest();
     }
     private static testMethod void testSicCodesInsert2() {
        Profile p = [SELECT Id FROM Profile WHERE  Name =: SM_Constants.SystemAdmin]; 
        User u = new User(Alias = 'standt', Email='sample@testUser11.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sample@testUser123432.com', Country= 'Ireland', Elevated_Access_Reason__c = 'Defect or Incident Resolution', Elevated_Access_Reference__c = 'ASDF');
        
        Profile p1 = [SELECT Id FROM Profile WHERE  Name =: SM_Constants.SystemAdmin]; 
        User u1 = new User(Alias = 'standta', Email='sample@testUser111.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p1.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sample@testUser22324.com', Country= 'Sweden', Elevated_Access_Reason__c = 'Defect or Incident Resolution', Elevated_Access_Reference__c = 'ASDF');
        
        Profile p2 = [SELECT Id FROM Profile WHERE  Name =: SM_Constants.SystemAdmin]; 
        User u2 = new User(Alias = 'standtb', Email='sample@testUser1111.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p2.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sample@testUser1111.com', Country= 'Denmark', Elevated_Access_Reason__c = 'Defect or Incident Resolution', Elevated_Access_Reference__c = 'ASDF');
        
        
        Test.startTest();
        
        System.runAs(u){
        Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
        paymentTerm.Name = 'Sample';
        paymentTerm.Apttus_Config2__Sequence__c = 1;
        paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
        paymentTerm.APTS_Ext_ID__c = 'abc7';
        insert paymentTerm;
            
        Account acc1 = new Account();
        acc1.Name = 'SicTest1';
        acc1.Main_House_Number__c = '12341';
        acc1.Main_Street_Only__c = 'streetOnly1';
        acc1.Main_Postal_Code__c = '12341';
        acc1.Main_City__c = '12341';
        acc1.Phone = '+31302979111';
        acc1.Account_Tier__c = 'Gold';
        acc1.of_Employees_FTE__c = 1;
        acc1.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
        acc1.Segment__c = 'SAP_A';
        acc1.Subsegment__c = 'Trading & Retail';
        acc1.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        
        Account acc2 = new Account();
        acc2.Name = 'SicTest2';
        acc2.Main_House_Number__c = '12342';
        acc2.Main_Street_Only__c = 'streetOnly2';
        acc2.Main_Postal_Code__c = '12342';
        acc2.Main_City__c = '12342';
        acc2.Phone = '+31302979111';
        acc2.Account_Tier__c = 'Gold';
        acc2.of_Employees_FTE__c = 51;
        acc2.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
        acc2.Segment__c = 'SAP_A';
        acc2.Subsegment__c = 'Trading & Retail';
        acc2.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        
        List<Account> insertaccounts = new List<Account>();
        insertaccounts.add(acc1);
        insertaccounts.add(acc2);
        insert insertaccounts;
        
        Account updateAcct = new Account();
        updateAcct = [Select Id, Name FROM Account WHERE Id = :acc1.Id];
        updateAcct.of_Employees_FTE__c = 301;
        update updateAcct;
        
        Account updateAcct1 = new Account();
        updateAcct1 = [Select Id, Name FROM Account WHERE Id = :acc2.Id];
        updateAcct1.of_Employees_FTE__c = 1;
        update updateAcct1;
        
        }
        System.runAs(u1){
        Apttus_Config2__PaymentTerm__c paymentTerm1 = new Apttus_Config2__PaymentTerm__c();
        paymentTerm1.Name = 'Sample';
        paymentTerm1.Apttus_Config2__Sequence__c = 1;
        paymentTerm1.APTS_Sales_Org__c = 'SAP_0333';
        paymentTerm1.APTS_Ext_ID__c = 'abc8';
        insert paymentTerm1;
            
        Account acc3 = new Account();
        acc3.Name = 'SicTest3';
        acc3.Main_House_Number__c = '12343';
        acc3.Main_Street_Only__c = 'streetOnly3';
        acc3.Main_Postal_Code__c = '12343';
        acc3.Main_City__c = '12343';
        acc3.Phone = '+31302979111';
        acc3.Account_Tier__c = 'Gold';
        acc3.of_Employees_FTE__c = 301;
        acc3.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
        acc3.Segment__c = 'SAP_A';
        acc3.Subsegment__c = 'Trading & Retail';
        acc3.Apttus_Config2__PaymentTermId__c = paymentTerm1.Id;
        
        Account acc4 = new Account();
        acc4.Name = 'SicTest4';
        acc4.Main_House_Number__c = '12344';
        acc4.Main_Street_Only__c = 'streetOnly4';
        acc4.Main_Postal_Code__c = '12344';
        acc4.Main_City__c = '12344';
        acc4.Phone = '+31302979111';
        acc4.Account_Tier__c = 'Gold';
        acc4.of_Employees_FTE__c = 1;
        acc4.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
        acc4.Segment__c = 'SAP_D';
        acc4.Subsegment__c = 'Health and allied services';
        acc4.Apttus_Config2__PaymentTermId__c = paymentTerm1.Id;
        
        List<Account> insertaccounts = new List<Account>();
        insertaccounts.add(acc3);
        insertaccounts.add(acc4);
        insert insertaccounts;
        
        Account updateAcct = new Account();
        updateAcct = [Select Id, Name FROM Account WHERE Id = :acc4.Id];
        updateAcct.of_Employees_FTE__c = 51;
        update updateAcct;
        
        }
        System.runAs(u2){
        Apttus_Config2__PaymentTerm__c paymentTerm2 = new Apttus_Config2__PaymentTerm__c();
        paymentTerm2.Name = 'Sample';
        paymentTerm2.Apttus_Config2__Sequence__c = 1;
        paymentTerm2.APTS_Sales_Org__c = 'SAP_0333';
        paymentTerm2.APTS_Ext_ID__c = 'abc9';
        insert paymentTerm2;
            
        Account acc5 = new Account();
        acc5.Name = 'SicTest5';
        acc5.Main_House_Number__c = '12345';
        acc5.Main_Street_Only__c = 'streetOnly5';
        acc5.Main_Postal_Code__c = '12345';
        acc5.Main_City__c = '12345';
        acc5.Phone = '+31302979111';
        acc5.Account_Tier__c = 'Gold';
        acc5.of_Employees_FTE__c = 51;
        acc5.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
        acc5.Segment__c = 'SAP_D';
        acc5.Subsegment__c = 'Health and allied services';
        acc5.Apttus_Config2__PaymentTermId__c = paymentTerm2.Id;
        
        Account acc6 = new Account();
        acc6.Name = 'SicTest6';
        acc6.Main_House_Number__c = '12346';
        acc6.Main_Street_Only__c = 'streetOnly6';
        acc6.Main_Postal_Code__c = '12346';
        acc6.Main_City__c = '12346';
        acc6.Phone = '+31302979111';
        acc6.Account_Tier__c = 'Gold';
        acc6.of_Employees_FTE__c = 301;
        acc6.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
        acc6.Segment__c = 'SAP_D';
        acc6.Subsegment__c = 'Health and allied services';
        acc6.Apttus_Config2__PaymentTermId__c = paymentTerm2.Id;
        
        Account acc7 = new Account();
        acc7.Name = 'SicTest7';
        acc7.Main_House_Number__c = '12347';
        acc7.Main_Street_Only__c = 'streetOnly7';
        acc7.Main_Postal_Code__c = '12347';
        acc7.Main_City__c = '12347';
        acc7.Phone = '+31302979111';
        acc7.Account_Tier__c = 'Gold';
        acc7.of_Employees_FTE__c = 1;
        acc7.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
        acc7.Segment__c = 'SAP_E';
        acc7.Subsegment__c = 'Elementary and Secondary schools';
        acc7.Apttus_Config2__PaymentTermId__c = paymentTerm2.Id;
         
        Account acc8 = new Account();
        acc8.Name = 'SicTest8';
        acc8.Main_House_Number__c = '12348';
        acc8.Main_Street_Only__c = 'streetOnly8';
        acc8.Main_Postal_Code__c = '12348';
        acc8.Main_City__c = '12348';
        acc8.Phone = '+31302979111';
        acc8.Account_Tier__c = 'Gold';
        acc8.of_Employees_FTE__c = 51;
        acc8.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
        acc8.Segment__c = 'SAP_E';
        acc8.Subsegment__c = 'Elementary and Secondary schools';
        acc8.Apttus_Config2__PaymentTermId__c = paymentTerm2.Id;
         
        Account acc9 = new Account();
        acc9.Name = 'SicTest9';
        acc9.Main_House_Number__c = '12349';
        acc9.Main_Street_Only__c = 'streetOnly9';
        acc9.Main_Postal_Code__c = '12349';
        acc9.Main_City__c = '12349';
        acc9.Phone = '+31302979111';
        acc9.Account_Tier__c = 'Gold';
        acc9.of_Employees_FTE__c = 301;
        acc9.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
        acc9.Segment__c = 'SAP_E';
        acc9.Subsegment__c = 'Elementary and Secondary schools'; 
        acc9.Apttus_Config2__PaymentTermId__c = paymentTerm2.Id;
         
        List<Account> insertaccounts = new List<Account>();
        insertaccounts.add(acc5);
        insertaccounts.add(acc6);
        insertaccounts.add(acc7);
        insertaccounts.add(acc8);
        insertaccounts.add(acc9);
        insert insertaccounts;
        
        Account updateAcct = new Account();
        updateAcct = [Select Id, Name, Segment__c, Subsegment__c FROM Account WHERE Id = :acc5.Id];
        updateAcct.of_Employees_FTE__c = 301;
        update updateAcct;
        
        Account updateAcct1 = new Account();
        updateAcct1 = [Select Id, Name, Segment__c, Subsegment__c FROM Account WHERE Id = :acc6.Id];
        updateAcct1.of_Employees_FTE__c = 1;
        update updateAcct1;
        
        Account updateAcct3 = new Account();
        updateAcct3 = [Select Id, Name, Segment__c, Subsegment__c FROM Account WHERE Id = :acc7.Id];
        updateAcct3.of_Employees_FTE__c = 301;
        update updateAcct3;
        
        Account updateAcct4 = new Account();
        updateAcct4 = [Select Id, Name, Segment__c, Subsegment__c FROM Account WHERE Id = :acc8.Id];
        updateAcct4.of_Employees_FTE__c = 1;
        update updateAcct4;
        
        Account updateAcct5 = new Account();
        updateAcct5 = [Select Id, Name, Segment__c, Subsegment__c FROM Account WHERE Id = :acc9.Id];
        updateAcct5.of_Employees_FTE__c = 51;
        update updateAcct5;
        checkrecursive.run = true;
        
        System.assertEquals(updateAcct.Segment__c, 'SAP_B');    
        System.assertEquals(updateAcct.Subsegment__c, 'Health & Care');
            
        System.assertEquals(updateAcct1.Segment__c, 'SAP_D');    
        System.assertEquals(updateAcct1.Subsegment__c, 'Health and allied services');
            
        System.assertEquals(updateAcct3.Segment__c, 'SAP_A');    
        System.assertEquals(updateAcct3.Subsegment__c, 'Education');
        
        System.assertEquals(updateAcct4.Segment__c, 'SAP_B');    
        System.assertEquals(updateAcct4.Subsegment__c, 'Education');
          
        System.assertEquals(updateAcct5.Segment__c, 'SAP_E');    
        System.assertEquals(updateAcct5.Subsegment__c, 'Elementary and Secondary schools');
        }
        Test.stopTest();
     }
     
     public static testMethod void acctApproval() {
        test.startTest();
        APTS_Payment_Method__c pm = new APTS_Payment_Method__c();
        pm.name = 'Sample Method';
        pm.APTS_Payment_Method_Code__c = 'D';
        //pm.APTS_Company_Code2__c = 'SAP_6864';
        pm.APTS_Country_Code__c = 'BE';
        pm.APTS_Ext_ID__c = 'BE6864D';
        
        insert pm;
        
        Apttus_Config2__PaymentTerm__c pt = new Apttus_Config2__PaymentTerm__c();
        pt.Name = 'Sample PT';
        pt.Apttus_Config2__Label__c = 'Net 30 Days';
        pt.Apttus_Config2__Sequence__c = 3;
        pt.APTS_Sales_Org__c = 'SAP_0333';
        pt.APTS_Ext_ID__c = 'abc14';
        insert pt;
         
        Apttus_Config2__PaymentTerm__c pt1 = new Apttus_Config2__PaymentTerm__c();
        pt1.Name = 'Sample PT';
        pt1.Apttus_Config2__Label__c = 'Net 30 Days';
        pt1.Apttus_Config2__Sequence__c = 3;
        pt1.APTS_Sales_Org__c = 'SAP_0333';
        insert pt1;
        
        
        List<Account> accList = new List<Account>();
        Account acc2 = new Account();
        acc2.Name = 'Test Account';
        acc2.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.EndCustomerValidation).getRecordTypeId();
        acc2.Main_Street_Only__c = 'Test Street';
        acc2.Main_Postal_Code__c = null;
        acc2.Industry_Code__c = null;
        acc2.Phone = '+1234567890';
        acc2.CurrencyIsoCode = 'EUR';
        acc2.Language__c = 'SAP_EN';
        acc2.Sales_Organization__c = 'SAP_0333';
        acc2.Account_Type__c = 'Customer';
        acc2.Segment__c = 'SAP_A'; //Indicator for change of rule
        acc2.of_Beds__c = 10;
        acc2.of_drinks__c = 10;
        acc2.of_Employees_FTE__c = 10;
        acc2.Exclude_from_Territory_Assignment__c = false;
        acc2.of_Seats__c = 10;
        acc2.Account_Lifecycle__c = 'Active Customer';
        acc2.Approval_Pending_Payment_Method__c = pm.Id;
        acc2.Approval_Pending_Payment_Term__c = pt.Id;
        acc2.Approval_Pending_Commercial_Register_No__c = '000000000000000';
        acc2.Approval_Pending_Partner__c = true;
        acc2.Approval_Pending_Customer_Pricing_Proc__c = 'SAP_M';
        acc2.SAP_Customer_ID__c = '89382';
        acc2.Apttus_Config2__PaymentTermId__c = pt.Id;
        accList.add(acc2);
        
        insert accList;
        
        //Update Account
        accList[0].Approval_Status__c = SM_Constants.ApprovalApproved;
        checkrecursive.run = true;
        update accList;
        
        Account accResIns = [SELECT Id, Approval_Required__c FROM Account WHERE Id =: accList[0].Id LIMIT 1];
        System.assert(accResIns.Approval_Required__c == false);
       
        test.stopTest();
     }

     public static testMethod void acctApprovalProcess() {
        APTS_Payment_Method__c pm = new APTS_Payment_Method__c();
        pm.name = 'Sample Method';
        pm.APTS_Payment_Method_Code__c = 'D';
        //pm.APTS_Company_Code2__c = 'SAP_6864';
        pm.APTS_Country_Code__c = 'BE';
        pm.APTS_Ext_ID__c = 'BE6864D';
        
        insert pm;
        
        Apttus_Config2__PaymentTerm__c pt = new Apttus_Config2__PaymentTerm__c();
        pt.Name = 'Sample PT';
        pt.Apttus_Config2__Label__c = 'Net 30 Days';
        pt.Apttus_Config2__Sequence__c = 3;
        pt.APTS_Sales_Org__c = 'SAP_0333';
        pt.APTS_Ext_ID__c = 'abc14';
        insert pt;
         
        Apttus_Config2__PaymentTerm__c pt1 = new Apttus_Config2__PaymentTerm__c();
        pt1.Name = 'Sample PT';
        pt1.Apttus_Config2__Label__c = 'Net 30 Days';
        pt1.Apttus_Config2__Sequence__c = 3;
        pt1.APTS_Sales_Org__c = 'SAP_0333';
        insert pt1;
        
        
        List<Account> accList = new List<Account>();
        Account acc2 = new Account();
        acc2.Name = 'Test Account';
        acc2.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.Customer).getRecordTypeId();
        acc2.Main_Street_Only__c = 'Test Street';
        acc2.Main_Postal_Code__c = null;
        acc2.Industry_Code__c = null;
        acc2.Phone = '+1234567890';
        acc2.CurrencyIsoCode = 'EUR';
        acc2.Language__c = 'SAP_EN';
        acc2.Sales_Organization__c = 'SAP_0333';
        acc2.Account_Type__c = 'Prospect';
        acc2.Segment__c = 'SAP_A'; //Indicator for change of rule
        acc2.of_Beds__c = 10;
        acc2.of_drinks__c = 10;
        acc2.of_Employees_FTE__c = 10;
        acc2.Exclude_from_Territory_Assignment__c = false;
        acc2.of_Seats__c = 10;
        acc2.Account_Lifecycle__c = 'Prospect';
        acc2.Approval_Pending_Payment_Method__c = pm.Id;
        acc2.Approval_Pending_Payment_Term__c = pt.Id;
        acc2.Approval_Pending_Commercial_Register_No__c = '000000000000000';
        acc2.Approval_Pending_Partner__c = true;
        acc2.Approval_Pending_Customer_Pricing_Proc__c = 'SAP_M';
        acc2.Apttus_Config2__PaymentTermId__c = pt.Id;
        accList.add(acc2);
        
         
        test.startTest(); 
        insert accList;
        
        //Update Account
        accList[0].Commercial_Register_Number__c = '9873291829380923';
        accList[0].Approval_Status__c = 'Approval Validated';
        accList[0].Apttus_Config2__PaymentTermId__c = pt1.Id;
        accList[0].SAP_PO_Updated__c = true;
        checkrecursive.run = true;
        update accList;
        test.stopTest();
         
        Account accResIns = [SELECT Id, Approval_Required__c FROM Account WHERE Id =: accList[0].Id LIMIT 1];
        System.assert(accResIns.Approval_Required__c == false);
        
     }
     
     public static testMethod void acctApprovalPartner() {
        
        Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
        paymentTerm.Name = 'Sample';
        paymentTerm.Apttus_Config2__Sequence__c = 1;
        paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
        paymentTerm.APTS_Ext_ID__c = 'abc15';
        insert paymentTerm;
         
        List<Account> accList = new List<Account>();
        Account acc2 = new Account();
        acc2.Name = 'Test Account';
        acc2.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.Customer).getRecordTypeId();
        acc2.Main_Street_Only__c = 'Test Street';
        acc2.Main_Postal_Code__c = null;
        acc2.Industry_Code__c = null;
        acc2.Phone = '+1234567890';
        acc2.CurrencyIsoCode = 'EUR';
        acc2.Language__c = 'SAP_EN';
        acc2.Sales_Organization__c = 'SAP_0333';
        acc2.Account_Type__c = 'Customer';
        acc2.Segment__c = 'SAP_A'; //Indicator for change of rule
        acc2.of_Beds__c = 10;
        acc2.of_drinks__c = 10;
        acc2.of_Employees_FTE__c = 10;
        acc2.Exclude_from_Territory_Assignment__c = false;
        acc2.of_Seats__c = 10;
        acc2.Account_Lifecycle__c = 'Active Customer';
        acc2.Approval_Pending_Partner__c = false;
        acc2.SAP_Customer_ID__c = '89382';
        acc2.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        acc2.Approval_Status__c = 'No Update Request';
        accList.add(acc2);
        
        test.startTest();
        insert accList;
        
        //Update Account
        accList[0].Approval_Status__c = 'Approval Validated';
        accList[0].Update_Request_Validation_Partner__c = SM_Constants.ApprovalApproved;
        checkrecursive.run = true;
        update accList;
        test.stopTest(); 
        
        Account accResIns = [SELECT Id, Approval_Required__c FROM Account WHERE Id =: accList[0].Id LIMIT 1];
        System.assert(accResIns.Approval_Required__c == false);
        
    }
    
    public static testMethod void acctApprovalPartner2() {
        
        Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
        paymentTerm.Name = 'Sample';
        paymentTerm.Apttus_Config2__Sequence__c = 1;
        paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
        paymentTerm.APTS_Ext_ID__c = 'abc15';
        insert paymentTerm;
         
        List<Account> accList = new List<Account>();
        Account acc2 = new Account();
        acc2.Name = 'Test Account';
        acc2.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.EndCustomerValidation).getRecordTypeId();
        acc2.Main_Street_Only__c = 'Test Street';
        acc2.Main_Postal_Code__c = null;
        acc2.Industry_Code__c = null;
        acc2.Phone = '+1234567890';
        acc2.CurrencyIsoCode = 'EUR';
        acc2.Language__c = 'SAP_EN';
        acc2.Sales_Organization__c = 'SAP_0333';
        acc2.Account_Type__c = 'Customer';
        acc2.Segment__c = 'SAP_A'; //Indicator for change of rule
        acc2.of_Beds__c = 10;
        acc2.of_drinks__c = 10;
        acc2.of_Employees_FTE__c = 10;
        acc2.Exclude_from_Territory_Assignment__c = false;
        acc2.of_Seats__c = 10;
        acc2.Account_Lifecycle__c = 'Active Customer';
        acc2.Approval_Pending_Partner__c = false;
        acc2.SAP_Customer_ID__c = '89382';
        acc2.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        acc2.Approval_Status__c = 'No Update Request';
        accList.add(acc2);
        
        test.startTest();
        insert accList;
        
        //Update Account
        accList[0].Approval_Status__c = 'Approval Validated';
        accList[0].Update_Request_Validation_Partner__c = SM_Constants.ApprovalApproved;
        checkrecursive.run = true;
        update accList;
        test.stopTest();
        
        Account accResIns = [SELECT Id, Approval_Required__c FROM Account WHERE Id =: accList[0].Id LIMIT 1];
        System.assert(accResIns.Approval_Required__c == false);
        
     }
     
     public static testMethod void populateAvgCoffeeDosage() {
        Brewing_System__c brew = new Brewing_System__c();
        brew.Name = 'SAP_0333';
        brew.Cafitesse__c = '5.2';
        brew.Espresso__c = '8';
        brew.Freshbrew__c = '7.5';
        brew.Instant__c = '1.5';
        brew.Promesso__c = '6.4';
        
        insert brew;
         
        Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
        paymentTerm.Name = 'Sample';
        paymentTerm.Apttus_Config2__Sequence__c = 1;
        paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
        paymentTerm.APTS_Ext_ID__c = 'abc19';
        insert paymentTerm;
        
        List<Account> accList = new List<Account>();
        Account acc2 = new Account();
        acc2.Name = 'Test Account';
        acc2.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.Customer).getRecordTypeId();
        acc2.Main_Street_Only__c = 'Test Street';
        acc2.Main_Postal_Code__c = null;
        acc2.Industry_Code__c = null;
        acc2.Phone = '+1234567890';
        acc2.CurrencyIsoCode = 'EUR';
        acc2.Language__c = 'SAP_EN';
        acc2.Sales_Organization__c = 'SAP_0333';
        acc2.Account_Type__c = 'Customer';
        acc2.Segment__c = 'SAP_A'; //Indicator for change of rule
        acc2.of_Beds__c = 10;
        acc2.of_drinks__c = 10;
        acc2.of_Employees_FTE__c = 10;
        acc2.Exclude_from_Territory_Assignment__c = false;
        acc2.of_Seats__c = 10;
        acc2.Account_Lifecycle__c = 'Active Customer';
        acc2.Approval_Pending_Partner__c = true;
        acc2.Brewing_System__c = 'Cafitesse';
        acc2.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
         
         
        accList.add(acc2);
        test.startTest();
        insert accList;
        test.stopTest();
        //Update Account
        // accList[0].Approval_Pending_Partner__c = false;
        // accList[0].Update_Request_Validation_Partner__c = SM_Constants.ApprovalApproved;
        // update accList;
        
        Account accResIns = [SELECT Id, Avg_Coffee_Dosage__c FROM Account WHERE Id =: accList[0].Id LIMIT 1];
        System.assert(accResIns.Avg_Coffee_Dosage__c == 5.2);
        
     }
     
     public static testMethod void createilog() {
        Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
        paymentTerm.Name = 'Sample';
        paymentTerm.Apttus_Config2__Sequence__c = 1;
        paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
        paymentTerm.APTS_Ext_ID__c = 'abc16';
        insert paymentTerm;
         
        List<Account> accList = new List<Account>();
        Account acc2 = new Account();
        acc2.Name = 'Test Account';
        acc2.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.Customer).getRecordTypeId();
        acc2.Main_Street_Only__c = 'Test Street';
        acc2.Main_Postal_Code__c = null;
        acc2.Industry_Code__c = null;
        acc2.Phone = '+1234567890';
        acc2.CurrencyIsoCode = 'EUR';
        acc2.Language__c = 'SAP_EN';
        acc2.Sales_Organization__c = 'SAP_0333';
        acc2.Account_Type__c = 'Customer';
        acc2.Segment__c = 'SAP_A'; //Indicator for change of rule
        acc2.of_Beds__c = 10;
        acc2.of_drinks__c = 10;
        acc2.of_Employees_FTE__c = 10;
        acc2.Exclude_from_Territory_Assignment__c = false;
        acc2.of_Seats__c = 10;
        acc2.Account_Lifecycle__c = 'Active Customer';
        acc2.SAP_PO_Updated__c = false;
        acc2.SAP_Customer_ID__c = '89382';
        acc2.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        accList.add(acc2);
        
        test.startTest();
        insert accList;
        
        //Update Account
        accList[0].recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.EndCustomerValidation).getRecordTypeId();
        checkrecursive.run = true;
        update accList;
        test.stopTest();
         
        Account accResIns = [SELECT Id, SAP_PO_Updated__c FROM Account WHERE Id =: accList[0].Id LIMIT 1];
        System.assert(accResIns.SAP_PO_Updated__c == false);
        
     }
     
     public static testMethod void createilogSAP() {
        Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
        paymentTerm.Name = 'Sample';
        paymentTerm.Apttus_Config2__Sequence__c = 1;
        paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
        paymentTerm.APTS_Ext_ID__c = 'abc17';
        insert paymentTerm;
         
        List<Account> accList = new List<Account>();
        Account acc2 = new Account();
        acc2.Name = 'Test Account';
        acc2.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.PromotionRequested).getRecordTypeId();
        acc2.Main_Street_Only__c = 'Test Street';
        acc2.Main_Postal_Code__c = null;
        acc2.Industry_Code__c = null;
        acc2.Phone = '+1234567890';
        acc2.CurrencyIsoCode = 'EUR';
        acc2.Language__c = 'SAP_EN';
        acc2.Sales_Organization__c = 'SAP_0333';
        acc2.Account_Type__c = 'Customer';
        acc2.Segment__c = 'SAP_A'; //Indicator for change of rule
        acc2.of_Beds__c = 10;
        acc2.of_drinks__c = 10;
        acc2.of_Employees_FTE__c = 10;
        acc2.Exclude_from_Territory_Assignment__c = false;
        acc2.of_Seats__c = 10;
        acc2.Account_Lifecycle__c = 'Active Customer';
        acc2.SAP_PO_Updated__c = false;
        acc2.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        accList.add(acc2);
        
        test.startTest();
        insert accList;
        
        //Update Account
        accList[0].recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.EndCustomerValidation).getRecordTypeId();
        accList[0].SAP_PO_Updated__c = true;
        accList[0].SAP_Customer_Id__c = '9238409304';
        checkrecursive.run = true;
        update accList;
        test.stopTest();
         
        Account accResIns = [SELECT Id, SAP_Customer_Id__c FROM Account WHERE Id =: accList[0].Id LIMIT 1];
        System.assert(accResIns.SAP_Customer_Id__c == '9238409304');
        
     }
     
     public static testMethod void reassignToManager () {
        Id p = [SELECT Id FROM Profile WHERE Name= :SM_Constants.SystemAdmin].id;
        Id RAdmin = [SELECT Id FROM UserRole WHERE Name = 'JDE Professional'].Id;
        User manager = new User(alias = 'test123', email='testmanager@noemail.com',
                                   emailencodingkey='UTF-8', lastname='LastNamePartner', firstName = 'FirstNamePartner', languagelocalekey='en_US',
                                   localesidkey='en_US', profileid = p, country='United States',IsActive =true, Sales_Organization__c = 'SAP_0333',userroleId = RAdmin,
                                   timezonesidkey='America/Los_Angeles', username='testmanager@notemail.com');
        insert manager;
        User superUser = new User(alias = 'test123', email='testsuperU@noemail.com',
                                   emailencodingkey='UTF-8', lastname='LastNamePartner', firstName = 'FirstNamePartner', languagelocalekey='en_US',
                                   localesidkey='en_US', profileid = p, country='United States',IsActive =true, Sales_Organization__c = 'SAP_0333',userroleId = RAdmin,
                                   timezonesidkey='America/Los_Angeles', username='testsuperU@notemail.com', ManagerID =manager.id);
        insert superUser;
        System.runAs(superUser){
            Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
            paymentTerm.Name = 'Sample';
            paymentTerm.Apttus_Config2__Sequence__c = 1;
            paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
            paymentTerm.APTS_Ext_ID__c = 'abc20';
            insert paymentTerm;
            
            Account acc2 = new Account();
            acc2.Name = 'Test Account';
            acc2.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.PromotionRequested).getRecordTypeId();
            acc2.Main_Street_Only__c = 'Test Street';
            acc2.Main_Postal_Code__c = null;
            acc2.Industry_Code__c = null;
            acc2.Phone = '+1234567890';
            acc2.CurrencyIsoCode = 'EUR';
            acc2.Language__c = 'SAP_EN';
            acc2.Sales_Organization__c = 'SAP_0333';
            acc2.Account_Type__c = 'Customer';
            acc2.Segment__c = 'SAP_A'; //Indicator for change of rule
            acc2.of_Beds__c = 10;
            acc2.of_drinks__c = 10;
            acc2.of_Employees_FTE__c = 10;
            acc2.Exclude_from_Territory_Assignment__c = false;
            acc2.of_Seats__c = 10;
            acc2.Account_Lifecycle__c = 'Active Customer';
            acc2.SAP_PO_Updated__c = false;
            acc2.Reject_to_Transfer__c = false;
            acc2.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
            test.startTest();
            insert acc2;
            
            acc2.Finance_Controller_for_Account_Validatio__c = superUser.id;
            acc2.Reject_to_Transfer__c = true;
            checkrecursive.run = true;
            update acc2;
            test.stopTest();
            Account accResIns = [SELECT Id, Reject_to_Transfer__c FROM Account WHERE Id =: acc2.Id];
            System.assert(accResIns.Reject_to_Transfer__c == true);
        }     
        
        
    }
    //For Calculate Method FTE and KG / L with matching Account Value Estimation Price
    public static testMethod void populateAverage () {
        List<Account_Value_Estimation_Size_Price__c> aveList = new List<Account_Value_Estimation_Size_Price__c>();

        for(Account_Value_Estimation_Size_Price__c ave : TestDataFactory.createAVESize(1)){
            ave.Size_Type_Input__c = '# of FTE';
            aveList.add(ave);
        }
        
        for(Account_Value_Estimation_Size_Price__c ave : TestDataFactory.createAVEPrice(1)){
            aveList.add(ave);
        }
		test.startTest();
        insert aveList;
        
        Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
        paymentTerm.Name = 'Sample';
        paymentTerm.Apttus_Config2__Sequence__c = 1;
        paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
        paymentTerm.APTS_Ext_ID__c = 'abc18';
        insert paymentTerm;
        
        Account acc2 = new Account();
        acc2.Name = 'Test Account';
        acc2.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.PromotionRequested).getRecordTypeId();
        acc2.Main_Street_Only__c = 'Test Street';
        acc2.Main_Postal_Code__c = null;
        acc2.Industry_Code__c = null;
        acc2.Phone = '+1234567890';
        acc2.CurrencyIsoCode = 'EUR';
        acc2.Language__c = 'SAP_EN';
        acc2.Sales_Organization__c = 'SAP_0333';
        acc2.Account_Type__c = 'Customer';
        acc2.Segment__c = 'SAP_A'; //Indicator for change of rule
        acc2.of_Beds__c = 10;
        acc2.of_drinks__c = 10;
        acc2.Exclude_from_Territory_Assignment__c = false;
        acc2.of_Seats__c = 10;
        acc2.Account_Lifecycle__c = 'Active Customer';
        acc2.SAP_PO_Updated__c = false;
        acc2.Reject_to_Transfer__c = false;
        acc2.of_Employees_FTE__c = 100;
        acc2.Estimated_Revenue_Potential__c  = 1000;
        acc2.Mini_Company_Code__c = 'SAP_0202';
        acc2.Segment__c= 'SAP_A';
        acc2.Subsegment__c= 'Construction';
        acc2.Penetration__c = 100;
        acc2.Tea_Drinks__c = 20;
        acc2.Avg_Coffee_Dosage__c = 10;
        acc2.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        insert acc2;
        
        Account acc3 = new Account();
        acc3.Name = 'Test Account';
        acc3.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.PromotionRequested).getRecordTypeId();
        acc3.Main_Street_Only__c = 'Test Street';
        acc3.Main_Postal_Code__c = null;
        acc3.Industry_Code__c = null;
        acc3.Phone = '+1234567890';
        acc3.CurrencyIsoCode = 'EUR';
        acc3.Language__c = 'SAP_EN';
        acc3.Sales_Organization__c = 'SAP_0333';
        acc3.Account_Type__c = 'Customer';
        acc3.Segment__c = 'SAP_A'; //Indicator for change of rule
        acc3.of_Beds__c = 10;
        acc3.of_drinks__c = 10;
        acc3.Exclude_from_Territory_Assignment__c = false;
        acc3.of_Seats__c = 10;
        acc3.Account_Lifecycle__c = 'Active Customer';
        acc3.SAP_PO_Updated__c = false;
        acc3.Reject_to_Transfer__c = false;
        acc3.of_Employees_FTE__c = 100;
        acc3.Estimated_Revenue_Potential__c  = 1000;
        acc3.Mini_Company_Code__c = 'SAP_0202';
        acc3.Segment__c= 'SAP_A';
        acc3.Subsegment__c= 'Construction';
        acc3.Penetration__c = 100;
        acc3.Tea_Drinks__c = 20;
        acc3.Avg_Coffee_Dosage__c = 10;
        acc3.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        acc3.Calculation_Method__c = 'KG / L';
        acc3.Estimated_Coffee_Potential_in_KG_L__c = 1000;
        insert acc3;
        
        Account accrecord2 = [Select Id, Estimated_Coffee_Potential_in_KG_L__c from Account where ID = :acc2.Id];
        Account accrecord3 = [Select Id, Share_of_Wallet__c from Account where ID = :acc3.Id];
        
        System.assertEquals(accrecord2.Estimated_Coffee_Potential_in_KG_L__c, 0);
        System.assertEquals(accrecord3.Share_of_Wallet__c, 0);
        test.stopTest();
    }
     //For Calculate Method FTE and KG / L without matching Account Value Estimation Price
    public static testMethod void populateAverage2 () {
        List<Account_Value_Estimation_Size_Price__c> aveList = new List<Account_Value_Estimation_Size_Price__c>();

        for(Account_Value_Estimation_Size_Price__c ave : TestDataFactory.createAVESize(1)){
            ave.Size_Type_Input__c = '# of FTE';
            ave.Subsegment__c = 'Construction';
            aveList.add(ave);
        }
        
        for(Account_Value_Estimation_Size_Price__c ave : TestDataFactory.createAVEPrice(1)){
            ave.Subsegment__c = 'Construction';
            aveList.add(ave);
        }
		test.startTest();
        insert aveList;
        
        Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
        paymentTerm.Name = 'Sample';
        paymentTerm.Apttus_Config2__Sequence__c = 1;
        paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
        paymentTerm.APTS_Ext_ID__c = 'abc18';
        insert paymentTerm;
        
        Account acc2 = new Account();
        acc2.Name = 'Test Account';
        acc2.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.PromotionRequested).getRecordTypeId();
        acc2.Main_Street_Only__c = 'Test Street';
        acc2.Main_Postal_Code__c = null;
        acc2.Industry_Code__c = null;
        acc2.Phone = '+1234567890';
        acc2.CurrencyIsoCode = 'EUR';
        acc2.Language__c = 'SAP_EN';
        acc2.Sales_Organization__c = 'SAP_0333';
        acc2.Account_Type__c = 'Customer';
        acc2.Segment__c = 'SAP_A'; //Indicator for change of rule
        acc2.of_Beds__c = 10;
        acc2.of_drinks__c = 10;
        acc2.Exclude_from_Territory_Assignment__c = false;
        acc2.of_Seats__c = 10;
        acc2.Account_Lifecycle__c = 'Active Customer';
        acc2.SAP_PO_Updated__c = false;
        acc2.Reject_to_Transfer__c = false;
        acc2.of_Employees_FTE__c = 100;
        acc2.Estimated_Revenue_Potential__c  = 1000;
        acc2.Mini_Company_Code__c = 'SAP_0202';
        acc2.Subsegment__c= 'Construction';
        acc2.Penetration__c = 100;
        acc2.Tea_Drinks__c = 20;
        acc2.Avg_Coffee_Dosage__c = 10;
        acc2.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        insert acc2;
        
        Account acc3 = new Account();
        acc3.Name = 'Test Account';
        acc3.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.PromotionRequested).getRecordTypeId();
        acc3.Main_Street_Only__c = 'Test Street';
        acc3.Main_Postal_Code__c = null;
        acc3.Industry_Code__c = null;
        acc3.Phone = '+1234567890';
        acc3.CurrencyIsoCode = 'EUR';
        acc3.Language__c = 'SAP_EN';
        acc3.Sales_Organization__c = 'SAP_0333';
        acc3.Account_Type__c = 'Customer';
        acc3.Segment__c = 'SAP_A'; //Indicator for change of rule
        acc3.of_Beds__c = 10;
        acc3.of_drinks__c = 10;
        acc3.Exclude_from_Territory_Assignment__c = false;
        acc3.of_Seats__c = 10;
        acc3.Account_Lifecycle__c = 'Active Customer';
        acc3.SAP_PO_Updated__c = false;
        acc3.Reject_to_Transfer__c = false;
        acc3.of_Employees_FTE__c = 100;
        acc3.Estimated_Revenue_Potential__c  = 1000;
        acc3.Mini_Company_Code__c = 'SAP_0202';
        acc3.Subsegment__c= 'Construction';
        acc3.Penetration__c = 100;
        acc3.Tea_Drinks__c = 20;
        acc3.Avg_Coffee_Dosage__c = 10;
        acc3.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        acc3.Calculation_Method__c = 'KG / L';
        acc3.Estimated_Coffee_Potential_in_KG_L__c = 1000;
        insert acc3;
        
        Account acc4 = new Account();
        acc4.Name = 'Test Account';
        acc4.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.PromotionRequested).getRecordTypeId();
        acc4.Main_Street_Only__c = 'Test Street';
        acc4.Main_Postal_Code__c = null;
        acc4.Industry_Code__c = null;
        acc4.Phone = '+1234567890';
        acc4.CurrencyIsoCode = 'EUR';
        acc4.Language__c = 'SAP_EN';
        acc4.Sales_Organization__c = 'SAP_0333';
        acc4.Account_Type__c = 'Customer';
        acc4.Segment__c = 'SAP_A'; //Indicator for change of rule
        acc4.of_Beds__c = 10;
        acc4.of_drinks__c = 10;
        acc4.Exclude_from_Territory_Assignment__c = false;
        acc4.of_Seats__c = 10;
        acc4.Account_Lifecycle__c = 'Active Customer';
        acc4.SAP_PO_Updated__c = false;
        acc4.Reject_to_Transfer__c = false;
        acc4.of_Employees_FTE__c = 100;
        acc4.Estimated_Revenue_Potential__c  = 1000;
        acc4.Mini_Company_Code__c = 'SAP_0202';
        acc4.Subsegment__c= 'Trading & Retail';
        acc4.Penetration__c = 100;
        acc4.Tea_Drinks__c = 20;
        acc4.Avg_Coffee_Dosage__c = 10;
        acc4.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        acc4.Calculation_Method__c = 'KG / L';
        acc4.Estimated_Coffee_Potential_in_KG_L__c = 0;
        insert acc4;
        
        Account accrecord2 = [Select Id, Estimated_Coffee_Potential_in_KG_L__c from Account where ID = :acc2.Id];
        Account accrecord3 = [Select Id, Share_of_Wallet__c from Account where ID = :acc3.Id];
        Account accrecord4 = [Select Id, Share_of_Wallet__c from Account where ID = :acc4.Id];
        
        System.assertEquals(accrecord2.Estimated_Coffee_Potential_in_KG_L__c, 3.20);
        System.assertEquals(accrecord3.Share_of_Wallet__c, 0.00);
        System.assertEquals(accrecord4.Share_of_Wallet__c, 0.00);
        test.stopTest();
    }
    
    private static testMethod void testStampChildAccount() {
        Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
        paymentTerm.Name = 'Sample';
        paymentTerm.Apttus_Config2__Sequence__c = 1;
        paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
        paymentTerm.APTS_Ext_ID__c = 'abc10';
        insert paymentTerm;
        
        //Parent
        List<Account> accList = new List<Account>();
        Account acc2 = new Account();
        acc2.Name = 'Test Account';
        acc2.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.PromotionRequested).getRecordTypeId();
        acc2.Main_Street_Only__c = 'Test Street';
        acc2.Main_Postal_Code__c = null;
        acc2.Industry_Code__c = null;
        acc2.Phone = '+1234567890';
        acc2.CurrencyIsoCode = 'EUR';
        acc2.Language__c = 'SAP_EN';
        acc2.Sales_Organization__c = 'SAP_0333';
        acc2.Account_Type__c = 'Customer';
        acc2.Segment__c = 'SAP_A'; //Indicator for change of rule
        acc2.of_Beds__c = 10;
        acc2.of_drinks__c = 10;
        acc2.of_Employees_FTE__c = 10;
        acc2.Exclude_from_Territory_Assignment__c = false;
        acc2.of_Seats__c = 10;
        acc2.Account_Lifecycle__c = 'Active Customer';
        acc2.SAP_PO_Updated__c = false;
        acc2.APTS_BizIsland_Bonsai_Account__c = false;
        acc2.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        accList.add(acc2);
        insert accList;
        
        //Child
        Account acc = new Account();
        acc.Name = 'Test Account Child';
        acc.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.PromotionRequested).getRecordTypeId();
        acc.Main_Street_Only__c = 'Test Street';
        acc.Main_Postal_Code__c = null;
        acc.Industry_Code__c = null;
        acc.Phone = '+1234567890';
        acc.CurrencyIsoCode = 'EUR';
        acc.Language__c = 'SAP_EN';
        acc.Sales_Organization__c = 'SAP_0333';
        acc.Account_Type__c = 'Customer';
        acc.Segment__c = 'SAP_A'; //Indicator for change of rule
        acc.of_Beds__c = 10;
        acc.of_drinks__c = 10;
        acc.of_Employees_FTE__c = 10;
        acc.Exclude_from_Territory_Assignment__c = false;
        acc.of_Seats__c = 10;
        acc.Account_Lifecycle__c = 'Active Customer';
        acc.SAP_PO_Updated__c = false;
        acc.APTS_BizIsland_Bonsai_Account__c = true;
        acc.ParentId = accList[0].Id;
        acc.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        insert acc;
        
        test.startTest();
        
        Account accountToupdate = [Select Id, APTS_Has_Child_Accounts__c FROM Account WHERE Id = :accList[0].Id];
        accountToupdate.APTS_BizIsland_Bonsai_Account__c = true;
        checkrecursive.run = true;
        update accountToupdate;
        
        test.stopTest();
        
        System.debug('accList: ' + accList[0].APTS_BizIsland_Bonsai_Account__c);
        System.debug('ParentId: ' + accList[0].ParentId);
        
        Account acheck = [Select Id, APTS_Has_Child_Accounts__c FROM Account WHERE Id = :accountToupdate.Id];
        System.debug('acheck: ' + acheck);
        
        System.assert(acheck.APTS_Has_Child_Accounts__c == true); 
        
    }
    
    private static testMethod void testChangeRecordType() {
        //Parent
        Id recordTypeIdProspectInvalid = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.ProspectInvalid).getRecordTypeId();
        Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
        paymentTerm.Name = 'Sample';
        paymentTerm.Apttus_Config2__Sequence__c = 1;
        paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
        paymentTerm.APTS_Ext_ID__c = 'abc22';
        insert paymentTerm;
        
        List<Account> accList = new List<Account>();
        Account acc2 = new Account();
        acc2.Name = 'Test Account';
        acc2.recordtypeId = recordTypeIdProspectInvalid;
        acc2.Main_Street_Only__c = 'Test Street';
        acc2.Main_Postal_Code__c = null;
        acc2.Industry_Code__c = null;
        acc2.Phone = '+1234567890';
        acc2.CurrencyIsoCode = 'EUR';
        acc2.Language__c = 'SAP_EN';
        acc2.Sales_Organization__c = 'SAP_0333';
        acc2.Account_Type__c = 'Customer';
        acc2.Segment__c = 'SAP_A'; //Indicator for change of rule
        acc2.of_Beds__c = 10;
        acc2.of_drinks__c = 10;
        acc2.of_Employees_FTE__c = 10;
        acc2.Exclude_from_Territory_Assignment__c = false;
        acc2.of_Seats__c = 10;
        acc2.Account_Lifecycle__c = 'Active Customer';
        acc2.SAP_PO_Updated__c = false;
        acc2.APTS_BizIsland_Bonsai_Account__c = false;
        acc2.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        accList.add(acc2);
        
        test.startTest();
        insert accList;
        
        accList[0].Main_Address_Validation_Timestamp__c = Date.today();
        checkrecursive.run = true;
        update accList;
        test.stopTest();
        
        Account acc = [Select Id, RecordTypeId FROM Account WHERE Id = :accList[0].Id];
		Id recordTypeIdProspectValid = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.ProspectValid).getRecordTypeId();
        
        System.assert(acc.RecordTypeId == recordTypeIdProspectValid); 
        
    }
    
    private static testMethod void testDigital() {
        Id p = [SELECT Id FROM Profile WHERE Name = :SM_Constants.JDEDigital].id;
                  
        User u = new User(alias = 'test123', email='test123@noemail.com',
                emailencodingkey='UTF-8', lastname='LastNamePartner', firstName = 'FirstNamePartner', languagelocalekey='en_US',
                localesidkey='en_US', profileid = p, country='United States',IsActive =true, Sales_Organization__c = 'SAP_0333',
                timezonesidkey='America/Los_Angeles', username='tester@notemail.com');
       
        insert u;
        
        Id p1 = [SELECT Id FROM Profile WHERE Name = :SM_Constants.SystemAdministrator].id;
                  
        User u1 = new User(alias = 'test123', email='test123@noemail.com',
                emailencodingkey='UTF-8', lastname='LastNamePartner', firstName = 'FirstNamePartner', languagelocalekey='en_US',
                localesidkey='en_US', profileid = p, country='United States',IsActive =true, Sales_Organization__c = 'SAP_0333',
                timezonesidkey='America/Los_Angeles', username='tester123@notemail.com');
        
        insert u1;
        
        System.runAs(u) {
            test.startTest();
            Account acc = new Account();
            acc.Name = 'Test Account';
            acc.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.ProspectValid).getRecordTypeId();
            acc.Main_Street_Only__c = 'Test Street';
            acc.Main_Postal_Code__c = null;
            acc.Industry_Code__c = null;
            acc.Phone = '+1234567890';
            acc.CurrencyIsoCode = 'EUR';
            acc.Language__c = 'SAP_EN';
            acc.Sales_Organization__c = 'SAP_0333';
            acc.Account_Type__c = 'Customer';
            acc.Segment__c = 'SAP_A'; //Indicator for change of rule
            acc.of_Beds__c = 10;
            acc.of_drinks__c = 10;
            acc.of_Employees_FTE__c = 10;
            acc.Exclude_from_Territory_Assignment__c = false;
            acc.of_Seats__c = 10;
            acc.Account_Lifecycle__c = 'Active Customer';
            acc.SAP_PO_Updated__c = false;
            acc.APTS_BizIsland_Bonsai_Account__c = true;
            insert acc;
            
            Id al = Schema.SObjectType.Apttus_Config2__AccountLocation__c.getRecordTypeInfosByName().get(SM_Constants.AccountLocationRO).getRecordTypeId();
            Apttus_Config2__AccountLocation__c acctLoc = new Apttus_Config2__AccountLocation__c();
            acctLoc.RecordTypeId = al;
            acctLoc.Copy_of_Parent_Account__c = true;
            acctLoc.Apttus_Config2__AccountId__c = acc.Id;
            acctLoc.Name = 'Test Account ';
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
            insert acctLoc;
            
            acc.Name = 'Test Update Acc';
            checkrecursive.run = true;
            update acc;
            test.stopTest();
            Account acct = [Select Id, Name FROM Account WHERE Id = :acc.Id];
            Apttus_Config2__AccountLocation__c accL = [Select Id, Name FROM Apttus_Config2__AccountLocation__c WHERE Id = :acctLoc.Id];
            
           	System.assert(acct.Name == 'Test Update Acc'); 
        }
    }
 
    
    private static testMethod void testAddTerritory() {
        Territory_Rule__c rule = new Territory_Rule__c();
        rule.Area_Code_From__c = '0';
        rule.Area_Code_To__c = '1000';
        rule.Beds_From__c = '0';
        rule.Beds_To__c = '1000';
        rule.Drinks_From__c = '0';
        rule.Drinks_To__c = '1000';
        rule.Employees_From__c = '0';
        rule.Employees_To__c = '1000';
        rule.Seats_From__c = '0';
        rule.Seats_To__c = '1000';
        rule.Postal_Code_From__c = '0';
        rule.Postal_Code_To__c = '1000';
        rule.Visitors_From__c = '0';
        rule.Visitors_To__c = '1000';
        rule.Industry_Code_From__c = '0000';
        rule.Industry_Code_To__c = '1000';
        rule.Segment__c = 'SAP_A;SAP_B;SAP_C';
        rule.Account_Lifecycle__c = 'Active Customer';
        insert rule;
        
        Id recordTypeIdProspectInvalid = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.ProspectValid).getRecordTypeId();
        Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
        paymentTerm.Name = 'Sample';
        paymentTerm.Apttus_Config2__Sequence__c = 1;
        paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
        paymentTerm.APTS_Ext_ID__c = 'abc21';
        insert paymentTerm;
        
        List<Account> accList = new List<Account>();
        Account acc2 = new Account();
        acc2.Name = 'Test Account';
        acc2.recordtypeId = recordTypeIdProspectInvalid;
        acc2.Main_Street_Only__c = 'Test Street';
        acc2.Main_Postal_Code__c = null;
        acc2.Industry_Code__c = null;
        acc2.Phone = '+1234567890';
        acc2.CurrencyIsoCode = 'EUR';
        acc2.Language__c = 'SAP_EN';
        acc2.Sales_Organization__c = 'SAP_0333';
        acc2.Account_Type__c = 'Customer';
        acc2.Segment__c = 'SAP_A'; //Indicator for change of rule
        acc2.of_Beds__c = 10;
        acc2.of_drinks__c = 10;
        acc2.of_Employees_FTE__c = 10;
        acc2.Exclude_from_Territory_Assignment__c = false;
        acc2.of_Seats__c = 10;
        acc2.Account_Lifecycle__c = 'Active Customer';
        acc2.SAP_PO_Updated__c = false;
        acc2.Main_Address_Validation_Timestamp__c = System.today();
        acc2.Exclude_from_Territory_Assignment__c = true;
        acc2.Applied_Territory_Rule__c = rule.Id;
        acc2.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        accList.add(acc2);
        test.startTest();
        insert accList;
        
        Territory__c tRecord = new Territory__c();
        Territory__c territory = new Territory__c();
        territory.Commercial_Territory_Owner__c = UserInfo.getUserId();
        insert territory;  
        
        accList[0].Territory__c = territory.Id;
        checkrecursive.run = true;
        update accList;	
        test.stopTest();
        
        Account acc = [Select Id, OwnerId FROM Account WHERE Id = :accList[0].Id];
        
        System.assert(acc.OwnerId == UserInfo.getUserId()); 
        
    }
    
    private static testMethod void testNonDigital() {
        Id p = [SELECT Id FROM Profile WHERE Name = :SM_Constants.SystemAdmin].id;
                  
        User u = new User(alias = 'test123', email='test123@noemail.com',
                emailencodingkey='UTF-8', lastname='LastNamePartner', firstName = 'FirstNamePartner', languagelocalekey='en_US',
                localesidkey='en_US', profileid = p, country='United States',IsActive =true, Sales_Organization__c = 'SAP_0333',
                timezonesidkey='America/Los_Angeles', username='tester@notemail.com');
       
        insert u;
        
        Id p1 = [SELECT Id FROM Profile WHERE Name = :SM_Constants.SystemAdmin].id;
                  
        User u1 = new User(alias = 'test123', email='test123@noemail.com',
                emailencodingkey='UTF-8', lastname='LastNamePartner', firstName = 'FirstNamePartner', languagelocalekey='en_US',
                localesidkey='en_US', profileid = p, country='United States',IsActive =true, Sales_Organization__c = 'SAP_0333',
                timezonesidkey='America/Los_Angeles', username='tester123@notemail.com');
        
        insert u1;
        
        System.runAs(u) {
            test.startTest();
            Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
            paymentTerm.Name = 'testNonDigital';
            paymentTerm.Apttus_Config2__Sequence__c = 1;
            paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
            paymentTerm.APTS_Ext_ID__c = 'testNonDigital';
            insert paymentTerm;
            
            Account acc = new Account();
            acc.Name = 'Test Account';
            acc.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.ProspectValid).getRecordTypeId();
            acc.Main_Street_Only__c = 'Test Street';
            acc.Main_Postal_Code__c = null;
            acc.Industry_Code__c = null;
            acc.Phone = '+1234567890';
            acc.CurrencyIsoCode = 'EUR';
            acc.Language__c = 'SAP_EN';
            acc.Sales_Organization__c = 'SAP_0333';
            acc.Account_Type__c = 'Customer';
            acc.Segment__c = 'SAP_A'; //Indicator for change of rule
            acc.of_Beds__c = 10;
            acc.of_drinks__c = 10;
            acc.of_Employees_FTE__c = 10;
            acc.Exclude_from_Territory_Assignment__c = false;
            acc.of_Seats__c = 10;
            acc.Account_Lifecycle__c = 'Active Customer';
            acc.SAP_PO_Updated__c = false;
            acc.APTS_BizIsland_Bonsai_Account__c = true;
            acc.First_Account_Location_created__c = true;
            acc.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
            insert acc;
            
            Id al = Schema.SObjectType.Apttus_Config2__AccountLocation__c.getRecordTypeInfosByName().get(SM_Constants.AccountLocationRO).getRecordTypeId();
            Apttus_Config2__AccountLocation__c acctLoc = new Apttus_Config2__AccountLocation__c();
            acctLoc.RecordTypeId = al;
            acctLoc.Copy_of_Parent_Account__c = true;
            acctLoc.Apttus_Config2__AccountId__c = acc.Id;
            acctLoc.Name = 'Test Account ';
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
            acctLoc.Apttus_Config2__AccountId__c = acc.Id;
            insert acctLoc;
            
            acc.Name = 'Test Update Acc';
            checkrecursive.run = true;
            update acc;
            test.stopTest();
            
            Account acct = [Select Id, Name FROM Account WHERE Id = :acc.Id];
            Apttus_Config2__AccountLocation__c accL = [Select Id, Name FROM Apttus_Config2__AccountLocation__c WHERE Id = :acctLoc.Id];
            
           	System.assert(acct.Name == 'Test Update Acc'); 
        }
    }
    
    private static testMethod void testJDEDigital() {
        Id p = [SELECT Id FROM Profile WHERE Name = :SM_Constants.JDEDigital].id;
                  
        User u = new User(alias = 'test123', email='test123@noemail.com',
                emailencodingkey='UTF-8', lastname='LastNamePartner', firstName = 'FirstNamePartner', languagelocalekey='en_US',
                localesidkey='en_US', profileid = p, country='United States',IsActive =true, Sales_Organization__c = 'SAP_0333',
                timezonesidkey='America/Los_Angeles', username='tester@notemail.com');
       
        insert u;
        
        System.runAs(u) {
            Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
            paymentTerm.Name = 'testJDEDigital';
            paymentTerm.Apttus_Config2__Sequence__c = 1;
            paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
            paymentTerm.APTS_Ext_ID__c = 'testJDEDigital';
            insert paymentTerm;
            
            Account acc = new Account();
            acc.Name = 'Test Account';
            acc.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.ProspectValid).getRecordTypeId();
            acc.Main_Street_Only__c = 'Test Street';
            acc.Main_Postal_Code__c = null;
            acc.Industry_Code__c = null;
            acc.Phone = '+1234567890';
            acc.CurrencyIsoCode = 'EUR';
            acc.Language__c = 'SAP_EN';
            acc.Sales_Organization__c = 'SAP_0333';
            acc.Account_Type__c = 'Customer';
            acc.Segment__c = 'SAP_A'; //Indicator for change of rule
            acc.of_Beds__c = 10;
            acc.of_drinks__c = 10;
            acc.of_Employees_FTE__c = 10;
            acc.Exclude_from_Territory_Assignment__c = false;
            acc.of_Seats__c = 10;
            acc.Account_Lifecycle__c = 'Active Customer';
            acc.SAP_PO_Updated__c = false;
            acc.APTS_BizIsland_Bonsai_Account__c = true;
            acc.First_Account_Location_created__c = true;
            acc.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
            test.startTest();
            insert acc;
            
            Id al = Schema.SObjectType.Apttus_Config2__AccountLocation__c.getRecordTypeInfosByName().get(SM_Constants.AccountLocationRO).getRecordTypeId();
            Apttus_Config2__AccountLocation__c acctLoc = new Apttus_Config2__AccountLocation__c();
            acctLoc.RecordTypeId = al;
            acctLoc.Copy_of_Parent_Account__c = true;
            acctLoc.Apttus_Config2__AccountId__c = acc.Id;
            acctLoc.Name = 'Test Account ';
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
            acctLoc.Apttus_Config2__AccountId__c = acc.Id;
            insert acctLoc;
            
            acc.Name = 'Test Update Acc';
            checkrecursive.run = true;
            update acc;
            test.stopTest();
            Account acct = [Select Id, Name FROM Account WHERE Id = :acc.Id];
            Apttus_Config2__AccountLocation__c accL = [Select Id, Name FROM Apttus_Config2__AccountLocation__c WHERE Id = :acctLoc.Id];
            
           	System.assert(acct.Name == 'Test Update Acc'); 
        }
    }
    
    private static testMethod void testPOBox() {
        try {
            Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
            paymentTerm.Name = 'testPOBox';
            paymentTerm.Apttus_Config2__Sequence__c = 1;
            paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
            paymentTerm.APTS_Ext_ID__c = 'testPOBox';
            insert paymentTerm;
            
            List<Account> accList = new List<Account>();
            Account acc2 = new Account();
            acc2.Name = 'Test Account';
            acc2.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
            acc2.Main_Street_Only__c = 'Test Street';
            acc2.Main_Postal_Code__c = null;
            acc2.Industry_Code__c = null;
            acc2.Phone = '+1234567890';
            acc2.CurrencyIsoCode = 'EUR';
            acc2.Language__c = 'SAP_EN';
            acc2.Sales_Organization__c = 'SAP_0333';
            acc2.Account_Type__c = 'Customer';
            acc2.Segment__c = 'SAP_A'; //Indicator for change of rule
            acc2.of_Beds__c = 10;
            acc2.of_drinks__c = 10;
            acc2.of_Employees_FTE__c = 10;
            acc2.of_Seats__c = 10;
            acc2.Account_Lifecycle__c = 'Active Customer';
            acc2.SAP_PO_Updated__c = false;
            acc2.APTS_BizIsland_Bonsai_Account__c = false;
            acc2.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
            accList.add(acc2);
            test.startTest();
            insert accList;
            
            accList[0].Main_Postal_Box__c = 'samplePO';
            checkrecursive.run = true;
            update accList;
    		test.stopTest();
            Account acc = [Select Id, Main_Postal_Box__c FROM Account WHERE Id = :accList[0].Id];
            
            System.assert(acc.Main_Postal_Box__c == null);
            
        } catch (Exception e) {
            //do nothing
        }
        
    }
    
    private static testMethod void testPostalBox() {
        try {
            Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
            paymentTerm.Name = 'testPOBox1';
            paymentTerm.Apttus_Config2__Sequence__c = 1;
            paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
            paymentTerm.APTS_Ext_ID__c = 'testPOBox1';
            insert paymentTerm;
            
            List<Account> accList = new List<Account>();
            Account acc2 = new Account();
            acc2.Name = 'Test Account';
            acc2.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
            acc2.Main_Street_Only__c = 'Test Street';
            acc2.Main_Postal_Code__c = null;
            acc2.Industry_Code__c = null;
            acc2.Phone = '+1234567890';
            acc2.CurrencyIsoCode = 'EUR';
            acc2.Language__c = 'SAP_EN';
            acc2.Sales_Organization__c = 'SAP_0333';
            acc2.Account_Type__c = 'Customer';
            acc2.Segment__c = 'SAP_A'; //Indicator for change of rule
            acc2.of_Beds__c = 10;
            acc2.of_drinks__c = 10;
            acc2.of_Employees_FTE__c = 10;
            acc2.of_Seats__c = 10;
            acc2.Account_Lifecycle__c = 'Active Customer';
            acc2.SAP_PO_Updated__c = false;
            acc2.APTS_BizIsland_Bonsai_Account__c = false;
            acc2.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
            accList.add(acc2);
            test.startTest();
            insert accList;
            
            accList[0].Main_Postal_Box_Postal_Code__c = '123 43';
            checkrecursive.run = true;
            update accList;
    		test.stopTest();
            Account acc = [Select Id, Main_Postal_Box__c FROM Account WHERE Id = :accList[0].Id];
            
            System.assert(acc.Main_Postal_Box__c == null);
            
        } catch (Exception e) {
            //do nothing
        }
        
    }
    
    private static testMethod void testPoCityBox() {
        try {
            Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
            paymentTerm.Name = 'testPOBoxCity';
            paymentTerm.Apttus_Config2__Sequence__c = 1;
            paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
            paymentTerm.APTS_Ext_ID__c = 'testPOBoxCity';
            insert paymentTerm;
            
            List<Account> accList = new List<Account>();
            Account acc2 = new Account();
            acc2.Name = 'Test Account';
            acc2.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
            acc2.Main_Street_Only__c = 'Test Street';
            acc2.Main_Postal_Code__c = null;
            acc2.Industry_Code__c = null;
            acc2.Phone = '+1234567890';
            acc2.CurrencyIsoCode = 'EUR';
            acc2.Language__c = 'SAP_EN';
            acc2.Sales_Organization__c = 'SAP_0333';
            acc2.Account_Type__c = 'Customer';
            acc2.Segment__c = 'SAP_A'; //Indicator for change of rule
            acc2.of_Beds__c = 10;
            acc2.of_drinks__c = 10;
            acc2.of_Employees_FTE__c = 10;
            acc2.of_Seats__c = 10;
            acc2.Account_Lifecycle__c = 'Active Customer';
            acc2.SAP_PO_Updated__c = false;
            acc2.APTS_BizIsland_Bonsai_Account__c = false;
            acc2.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
            accList.add(acc2);
            test.startTest();
            insert accList;
            
            accList[0].Main_Postal_Box_City__c = 'sampleCity';
            checkrecursive.run = true;
            update accList;
    		test.stopTest();
            Account acc = [Select Id, Main_Postal_Box__c FROM Account WHERE Id = :accList[0].Id];
            
            System.assert(acc.Main_Postal_Box__c == null);
            
        } catch (Exception e) { 
            //do nothing
        }
        
    }
    
    public static testMethod void testAccountBlockUpdate(){
        try{
            Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
            paymentTerm.Name = 'testAccountBlockUpdate';
            paymentTerm.Apttus_Config2__Sequence__c = 1;
            paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
            paymentTerm.APTS_Ext_ID__c = 'testAccountBlockUpdate';
            insert paymentTerm;
            
            List<Account> accList = new List<Account>();
            Account acc2 = new Account();
            acc2.Name = 'Test Account';
            acc2.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.Customer).getRecordTypeId();
            acc2.Main_Street_Only__c = 'Test Street';
            acc2.Main_Postal_Code__c = null;
            acc2.Industry_Code__c = null;
            acc2.Phone = '+1234567890';
            acc2.CurrencyIsoCode = 'EUR';
            acc2.Language__c = 'SAP_EN';
            acc2.Sales_Organization__c = 'SAP_0333';
            acc2.Account_Block__c = true;
            acc2.Account_Type__c = 'Customer';
            acc2.Segment__c = 'SAP_A'; //Indicator for change of rule
            acc2.of_Beds__c = 10;
            acc2.of_drinks__c = 10;
            acc2.of_Employees_FTE__c = 10;
            acc2.Exclude_from_Territory_Assignment__c = false;
            acc2.of_Seats__c = 10;
            acc2.Account_Lifecycle__c = 'Active Customer';
            acc2.SAP_PO_Updated__c = false;
            acc2.SAP_Customer_ID__c = '89382';
            acc2.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
            test.startTest();
            accList.add(acc2);
            
            insert accList;
            accList[0].Account_Block__c = false;
            accList[0].Archiving_Flag__c = true;
            checkrecursive.run = true;
            update accList;
    		test.stopTest();
            Account updatedAcc = [SELECT Id, Updated_Account_Block__c FROM Account WHERE Id =: accList[0].Id LIMIT 1];
            System.assert(updatedAcc.Updated_Account_Block__c == 'false');
        } catch (Exception e){
            //do nothing
        }
    }
    
    private static testMethod void testPaymentTermValidation() {
        try {
            List<Account> accList = new List<Account>();
            Account acc2 = new Account();
            acc2.Name = 'Test Account';
            acc2.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
            acc2.Main_Street_Only__c = 'Test Street';
            acc2.Main_Postal_Code__c = null;
            acc2.Industry_Code__c = null;
            acc2.Phone = '+1234567890';
            acc2.CurrencyIsoCode = 'EUR';
            acc2.Language__c = 'SAP_EN';
            acc2.Sales_Organization__c = 'SAP_0333';
            acc2.Account_Type__c = 'Customer';
            acc2.Segment__c = 'SAP_A'; //Indicator for change of rule
            acc2.of_Beds__c = 10;
            acc2.of_drinks__c = 10;
            acc2.of_Employees_FTE__c = 10;
            acc2.of_Seats__c = 10;
            acc2.Account_Lifecycle__c = 'Active Customer';
            acc2.SAP_PO_Updated__c = false;
            acc2.APTS_BizIsland_Bonsai_Account__c = false;
            accList.add(acc2);
            test.startTest();
            insert accList;
            
            accList[0].Apttus_Config2__PaymentTermId__c = null;
            checkrecursive.run = true;
            update accList;
    		test.stopTest();
            Account acc = [Select Id, Apttus_Config2__PaymentTermId__c FROM Account WHERE Id = :accList[0].Id];
            
            System.assert(acc.Apttus_Config2__PaymentTermId__c == null);
            
        } catch (Exception e) {
            //do nothing
        }
        
    }
    
    private static testMethod void testAccountLifeCycle() {
        Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
        paymentTerm.Name = 'testAccountBlockUpdate';
        paymentTerm.Apttus_Config2__Sequence__c = 1;
        paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
        paymentTerm.APTS_Ext_ID__c = 'testAccountBlockUpdate';
        insert paymentTerm;
        
        List<Account> accList = new List<Account>();
        
        Account acc4 = new Account();
        acc4.Name = 'Test Account';
        acc4.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect Valid').getRecordTypeId();
        acc4.Main_Street_Only__c = 'Test Street';
        acc4.Main_Postal_Code__c = null;
        acc4.Industry_Code__c = null;
        acc4.Phone = '+1234567890';
        acc4.CurrencyIsoCode = 'EUR';
        acc4.Language__c = 'SAP_EN';
        acc4.Sales_Organization__c = 'SAP_0333';
        acc4.Account_Type__c = 'Prospect';
        acc4.Segment__c = 'SAP_A'; //Indicator for change of rule
        acc4.of_Employees_FTE__c = 10;
        acc4.Account_Lifecycle__c = 'Prospect';
        acc4.SAP_PO_Updated__c = false;
        acc4.APTS_BizIsland_Bonsai_Account__c = false;
        acc4.IsActive__c = false;
        acc4.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        acc4.Mini_Customer_Pricing_Procedure__c = 'SAP_X';
        
        Account acc3 = new Account();
        acc3.Name = 'Test Account';
        acc3.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        acc3.Main_Street_Only__c = 'Test Street';
        acc3.Main_Postal_Code__c = null;
        acc3.Industry_Code__c = null;
        acc3.Phone = '+1234567890';
        acc3.CurrencyIsoCode = 'EUR';
        acc3.Language__c = 'SAP_EN';
        acc3.Sales_Organization__c = 'SAP_0333';
        acc3.Account_Type__c = 'Customer';
        acc3.Segment__c = 'SAP_A'; //Indicator for change of rule
        acc3.of_Employees_FTE__c = 10;
        acc3.Account_Lifecycle__c = 'Active Customer';
        acc3.SAP_PO_Updated__c = false;
        acc3.APTS_BizIsland_Bonsai_Account__c = false;
        acc3.IsActive__c = true;
        acc3.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        acc4.Mini_Customer_Pricing_Procedure__c = 'SAP_S';
        
        Account acc2 = new Account();
        acc2.Name = 'Test Account';
        acc2.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        acc2.Main_Street_Only__c = 'Test Street';
        acc2.Main_Postal_Code__c = null;
        acc2.Industry_Code__c = null;
        acc2.Phone = '+1234567890';
        acc2.CurrencyIsoCode = 'EUR';
        acc2.Language__c = 'SAP_EN';
        acc2.Sales_Organization__c = 'SAP_0333';
        acc2.Account_Type__c = 'Customer';
        acc2.Segment__c = 'SAP_A'; //Indicator for change of rule
        acc2.of_Beds__c = 10;
        acc2.of_drinks__c = 10;
        acc2.of_Employees_FTE__c = 10;
        acc2.of_Seats__c = 10;
        acc2.Account_Lifecycle__c = 'Active Customer';
        acc2.SAP_PO_Updated__c = false;
        acc2.APTS_BizIsland_Bonsai_Account__c = false;
        acc2.IsActive__c = false;
        acc2.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        
        Account acc1 = new Account();
        acc1.Name = 'Test Account';
        acc1.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Administrative Address').getRecordTypeId();
        acc1.Main_Street_Only__c = 'Test Street';
        acc1.Main_Postal_Code__c = null;
        acc1.Industry_Code__c = null;
        acc1.Phone = '+1234567890';
        acc1.CurrencyIsoCode = 'EUR';
        acc1.Language__c = 'SAP_EN';
        acc1.Sales_Organization__c = 'SAP_0333';
        acc1.Account_Type__c = 'Customer';
        acc1.Segment__c = 'SAP_A'; //Indicator for change of rule
        acc1.of_Beds__c = 10;
        acc1.of_drinks__c = 10;
        acc1.of_Employees_FTE__c = 10;
        acc1.of_Seats__c = 10;
        acc1.Account_Lifecycle__c = 'Active Customer';
        acc1.SAP_PO_Updated__c = false;
        acc1.APTS_BizIsland_Bonsai_Account__c = false;
        acc1.IsActive__c = false;
        acc1.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        test.startTest();
        accList.add(acc2);
        accList.add(acc1);
        accList.add(acc3);
        accList.add(acc4);
        insert accList;
        
        accList[0].IsActive__c = true;
        accList[1].IsActive__c = true;
        accList[2].IsActive__c = false;
        accList[3].IsActive__c = true;
        checkrecursive.run = true;
        update accList;
        test.stopTest();
        Account acc = [Select Id, IsActive__c FROM Account WHERE Id = :accList[0].Id];
        
        System.assert(acc.IsActive__c == true);
        
        Account acctest = [Select Id, Account_Lifecycle__c FROM Account WHERE Id = :accList[2].Id];
        
        System.assert(acctest.Account_Lifecycle__c == 'Inactive Customer');
               
    }
    
     private static testMethod void testAccountAddressValidation() {
        Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
        paymentTerm.Name = 'testAccountBlockUpdate';
        paymentTerm.Apttus_Config2__Sequence__c = 1;
        paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
        paymentTerm.APTS_Ext_ID__c = 'testAccountBlockUpdate';
        insert paymentTerm;
        
        List<Account> accList = new List<Account>();
        Account acc2 = new Account();
        acc2.Name = 'Test Account';
        acc2.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        acc2.Main_Street_Only__c = 'Test Street';
        acc2.Main_Postal_Code__c = null;
        acc2.Industry_Code__c = null;
        acc2.Phone = '+1234567890';
        acc2.CurrencyIsoCode = 'EUR';
        acc2.Language__c = 'SAP_EN';
        acc2.Sales_Organization__c = 'SAP_0333';
        acc2.Account_Type__c = 'Customer';
        acc2.Segment__c = 'SAP_A'; //Indicator for change of rule
        acc2.of_Beds__c = 10;
        acc2.of_drinks__c = 10;
        acc2.of_Employees_FTE__c = 10;
        acc2.of_Seats__c = 10;
        acc2.Account_Lifecycle__c = 'Active Customer';
        acc2.SAP_PO_Updated__c = false;
        acc2.APTS_BizIsland_Bonsai_Account__c = false;
        acc2.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        acc2.Address_Validation__c = 'Request Address Validation';
        accList.add(acc2);
        test.startTest();
        insert accList;
        
        acc2.Address_Validation__c = 'Valid';
        checkrecursive.run = true;
        update accList;
        test.stopTest();
        Account acc = [Select Id, RecordTypeId FROM Account WHERE Id = :accList[0].Id];
        
        System.assert(acc.RecordTypeId == SM_Constants.recordTypeIdEndCustomerValidation);
    }

    private static testMethod void testAccountArchiving() {
        //test for Account Archiving, DMU Process
        Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
        paymentTerm.Name = 'testAccountBlockUpdate';
        paymentTerm.Apttus_Config2__Sequence__c = 1;
        paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
        paymentTerm.APTS_Ext_ID__c = 'testAccountBlockUpdate';
        insert paymentTerm;
        
        List<Account> accList = new List<Account>();
        Account acc2 = new Account();
        acc2.Name = 'Created Archived Acc';
        acc2.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        acc2.Main_Street_Only__c = 'Test Street';
        acc2.Main_Postal_Code__c = null;
        acc2.Industry_Code__c = null;
        acc2.Phone = '+1234567890';
        acc2.CurrencyIsoCode = 'EUR';
        acc2.Language__c = 'SAP_EN';
        acc2.Sales_Organization__c = 'SAP_0333';
        acc2.Account_Type__c = 'Customer';
        acc2.Segment__c = 'SAP_A'; //Indicator for change of rule
        acc2.of_Employees_FTE__c = 10;
        acc2.SAP_PO_Updated__c = false;
        acc2.APTS_BizIsland_Bonsai_Account__c = false;
        acc2.IsActive__c = false;
        acc2.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        acc2.Account_Lifecycle__c = 'Inactive Customer';
        acc2.Archiving_Flag__c = true;
        acc2.Archiving_Reason__c = 'Duplicate Account';
        
        Account acc1 = new Account();
        acc1.Name = 'Created Active Acc';
        acc1.recordtypeId = SM_Constants.recordTypeIdAdministrativeAddress;
        acc1.Main_Street_Only__c = 'Test Street';
        acc1.Main_Postal_Code__c = null;
        acc1.Industry_Code__c = null;
        acc1.Phone = '+1234567890';
        acc1.CurrencyIsoCode = 'EUR';
        acc1.Language__c = 'SAP_EN';
        acc1.Sales_Organization__c = 'SAP_0333';
        acc1.Account_Type__c = 'Administrative';
        acc1.Segment__c = 'SAP_A'; //Indicator for change of rule
        acc1.of_Beds__c = 10;
        acc1.of_drinks__c = 10;
        acc1.of_Employees_FTE__c = 10;
        acc1.of_Seats__c = 10;
        acc1.Account_Lifecycle__c = 'Administrative';
        acc1.SAP_PO_Updated__c = false;
        acc1.APTS_BizIsland_Bonsai_Account__c = false;
        acc1.IsActive__c = true;
        acc1.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        
        Account acc3 = new Account();
        acc3.Name = 'Created Archived Acc';
        acc3.recordtypeId = SM_Constants.recordTypeIdAdministrativeAddress;
        acc3.Main_Street_Only__c = 'Test Street';
        acc3.Main_Postal_Code__c = null;
        acc3.Industry_Code__c = null;
        acc3.Phone = '+1234567890';
        acc3.CurrencyIsoCode = 'EUR';
        acc3.Language__c = 'SAP_EN';
        acc3.Sales_Organization__c = 'SAP_0333';
        acc3.Account_Type__c = 'Customer';
        acc3.Segment__c = 'SAP_A'; //Indicator for change of rule
        acc3.of_Employees_FTE__c = 10;
        acc3.SAP_PO_Updated__c = false;
        acc3.APTS_BizIsland_Bonsai_Account__c = false;
        acc3.IsActive__c = false;
        acc3.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        acc3.Archiving_Flag__c = true;
        acc3.Archiving_Reason__c = 'Duplicate Account';
        
        test.startTest();
        accList.add(acc2);
        accList.add(acc1);
        accList.add(acc3);
        insert accList;
        
        accList[0].Archiving_Flag__c = false;
        accList[1].Archiving_Flag__c = true;
        accList[2].Archiving_Flag__c = false;
        checkrecursive.run = true;
        update accList;
        Account a1 = [Select Id, Name, Account_Lifecycle__c, IsActive__c, Last_Relevant_Activity_Date__c, Archiving_Reason__c, Archiving_Flag__c FROM Account WHERE Id = :accList[0].Id];
        system.assertEquals(system.today(), a1.Last_Relevant_Activity_Date__c);
        system.assertEquals('Duplicate Account', a1.Archiving_Reason__c);
        system.assertEquals(true, a1.isActive__c);
        
        Account a2 = [Select Id, Name, Account_Lifecycle__c, IsActive__c, Last_Relevant_Activity_Date__c, Archiving_Reason__c, Archiving_Flag__c, DMU__c, Key_Account__c FROM Account WHERE Id = :accList[1].Id];
        system.assertEquals(true, a2.isActive__c); 
        system.assertEquals(false, a2.DMU__c);
        system.assertEquals(false, a2.Key_Account__c);
        system.assertEquals('Archived', a2.Account_Lifecycle__c);
        
        Account a3 = [Select Id, Name, Account_Lifecycle__c, IsActive__c, Last_Relevant_Activity_Date__c, Archiving_Reason__c, Archiving_Flag__c FROM Account WHERE Id = :accList[2].Id];
        system.assertEquals(system.today(), a3.Last_Relevant_Activity_Date__c);
        system.assertEquals('Administrative', a3.Account_Lifecycle__c);
        system.assertEquals(true, a3.isActive__c);
        test.stopTest();
    }

    private static testMethod void testAccountValidated() {
        //test for Account Archiving, DMU Process
        Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
        paymentTerm.Name = 'testAccountBlockUpdate3';
        paymentTerm.Apttus_Config2__Sequence__c = 1;
        paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
        paymentTerm.APTS_Ext_ID__c = 'testAccountBlockUpdate3';
        insert paymentTerm;

        Apttus_Config2__PaymentTerm__c paymentTerm2 = new Apttus_Config2__PaymentTerm__c();
        paymentTerm2.Name = 'testAccountBlockUpdate2';
        paymentTerm2.Apttus_Config2__Sequence__c = 1;
        paymentTerm2.APTS_Sales_Org__c = 'SAP_0333';
        paymentTerm2.APTS_Ext_ID__c = 'testAccountBlockUpdate2';
        insert paymentTerm2;

        APTS_Payment_Method__c pm = new APTS_Payment_Method__c();
        pm.name = 'Sample Method';
        pm.APTS_Payment_Method_Code__c = 'D';
        //pm.APTS_Company_Code2__c = 'SAP_6864';
        pm.APTS_Country_Code__c = 'BE';
        pm.APTS_Ext_ID__c = 'BE6864D';
        
        insert pm;

        Account acc2 = new Account();
        acc2.Name = 'Created Archived Acc1';
        acc2.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        acc2.Main_Street_Only__c = 'Test Street1';
        acc2.Main_Postal_Code__c = null;
        acc2.Industry_Code__c = null;
        acc2.Phone = '+1234567890';
        acc2.CurrencyIsoCode = 'EUR';
        acc2.Language__c = 'SAP_EN';
        acc2.Sales_Organization__c = 'SAP_0333';
        acc2.Account_Type__c = 'Customer';
        acc2.Segment__c = 'SAP_A'; //Indicator for change of rule
        acc2.of_Employees_FTE__c = 10;
        acc2.SAP_PO_Updated__c = false;
        acc2.APTS_BizIsland_Bonsai_Account__c = false;
        acc2.IsActive__c = false;
        acc2.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        acc2.Account_Lifecycle__c = 'Inactive Customer';
        acc2.Archiving_Flag__c = true;
        acc2.Archiving_Reason__c = 'Duplicate Account';
        acc2.Approval_Status__c = 'Approval Pending';
        acc2.Approval_Pending_Payment_Term__c = paymentTerm2.Id;
        acc2.Approval_Pending_Partner__c = true;
        acc2.Approval_Pending_Commercial_Register_No__c = '0000000';
        acc2.Approval_Pending_Payment_Method__c = pm.Id;
 		test.startTest();
        insert acc2;
        
        acc2.Approval_Status__c = 'Approval Validated';
        checkrecursive.run = true;
        update acc2;
        test.stopTest();
        Account a1 = [Select Id, Approval_Status__c FROM Account WHERE Id = :acc2.Id];
        system.assertEquals(a1.Approval_Status__c, 'Approval Validated');
    }

    private static testMethod void testAccountRejectedRecall() {
        //test for Account Archiving, DMU Process
        Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
        paymentTerm.Name = 'testAccountBlockUpdate';
        paymentTerm.Apttus_Config2__Sequence__c = 1;
        paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
        paymentTerm.APTS_Ext_ID__c = 'testAccountBlockUpdate';
        insert paymentTerm;

        Apttus_Config2__PaymentTerm__c paymentTerm2 = new Apttus_Config2__PaymentTerm__c();
        paymentTerm2.Name = 'testAccountBlockUpdate1';
        paymentTerm2.Apttus_Config2__Sequence__c = 1;
        paymentTerm2.APTS_Sales_Org__c = 'SAP_0333';
        paymentTerm2.APTS_Ext_ID__c = 'testAccountBlockUpdate1';
        insert paymentTerm2;

        APTS_Payment_Method__c pm = new APTS_Payment_Method__c();
        pm.name = 'Sample Method';
        pm.APTS_Payment_Method_Code__c = 'D';
        //pm.APTS_Company_Code2__c = 'SAP_6864';
        pm.APTS_Country_Code__c = 'BE';
        pm.APTS_Ext_ID__c = 'BE6864D';
        
        insert pm;

        Account acc2 = new Account();
        acc2.Name = 'Created Archived Acc2';
        acc2.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        acc2.Main_Street_Only__c = 'Test Street2';
        acc2.Main_Postal_Code__c = null;
        acc2.Industry_Code__c = null;
        acc2.Phone = '+1234567890';
        acc2.CurrencyIsoCode = 'EUR';
        acc2.Language__c = 'SAP_EN';
        acc2.Sales_Organization__c = 'SAP_0333';
        acc2.Account_Type__c = 'Customer';
        acc2.Segment__c = 'SAP_A'; //Indicator for change of rule
        acc2.of_Employees_FTE__c = 10;
        acc2.SAP_PO_Updated__c = false;
        acc2.APTS_BizIsland_Bonsai_Account__c = false;
        acc2.IsActive__c = false;
        acc2.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        acc2.Account_Lifecycle__c = 'Inactive Customer';
        acc2.Archiving_Flag__c = true;
        acc2.Archiving_Reason__c = 'Duplicate Account';
        acc2.Approval_Status__c = 'Approval Pending';
        acc2.Approval_Pending_Payment_Term__c = paymentTerm2.Id;
        acc2.Approval_Pending_Partner__c = true;
        acc2.Approval_Pending_Commercial_Register_No__c = '0000000';
        acc2.Approval_Pending_Payment_Method__c = pm.Id;
 		test.startTest();
        insert acc2;
        
        acc2.Approval_Status__c = 'Approval Declined';
        checkrecursive.run = true;
        update acc2;
        test.stopTest();
        Account a1 = [Select Id, Approval_Status__c FROM Account WHERE Id = :acc2.Id];
        system.assertEquals(a1.Approval_Status__c, 'Approval Declined');
    }
    
    private static testMethod void testBillingAddressAlignment() {
        Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
        paymentTerm.Name = 'testPT';
        paymentTerm.Apttus_Config2__Sequence__c = 1;
        paymentTerm.APTS_Sales_Org__c = 'SAP_0111';
        paymentTerm.APTS_Ext_ID__c = 'testPT';
        insert paymentTerm;
        
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
        acc.Main_Street_Only__c = 'Test Street';
        acc.Main_City__c = 'Test City';
        acc.Main_House_Number__c = '12';
        acc.Main_Postal_Code__c = '1234 PO';
        acc.Main_Country__c = 'Netherlands';
        acc.Phone = '+1234567890';
        acc.CurrencyIsoCode = 'EUR';
        acc.Language__c = 'SAP_EN';
        acc.Sales_Organization__c = 'SAP_0111';
        acc.Segment__c = 'SAP_A';
        acc.of_Employees_FTE__c = 10;
        acc.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        acc.Main_Address_Validation_Timestamp__c = date.today();
        acc.Address_Validation__c = 'Valid';
        
        Test.startTest();
        insert acc;
        
        Account newacc = [SELECT Id, BillingStreet, BillingCity, BillingCountry, BillingPostalCode, Main_City__c, Main_Country__c, Main_Postal_Code__c, Main_Street__c FROM Account WHERE Id = :acc.Id];
        system.assertEquals(newacc.Main_City__c, newacc.BillingCity);
        system.assertEquals(newacc.Main_Country__c, newacc.BillingCountry);
        system.assertEquals(newacc.Main_Postal_Code__c, newacc.BillingPostalCode);
        system.assertEquals(newacc.Main_Street__c, newacc.BillingStreet);
        
        newacc.Main_Street_Only__c = 'Updated Test Street';
        newacc.Main_City__c = 'Updated Test City';
        checkrecursive.run = true;
        update newacc;
        Account updatedacc = [Select Id, BillingStreet, BillingCity, BillingCountry, BillingPostalCode, Main_City__c, Main_Country__c, Main_Postal_Code__c, Main_Street__c FROM Account WHERE Id = :acc.Id];
        system.assertEquals(updatedacc.Main_City__c, updatedacc.BillingCity);
        system.assertEquals(updatedacc.Main_Country__c, updatedacc.BillingCountry);
        system.assertEquals(updatedacc.Main_Postal_Code__c, updatedacc.BillingPostalCode);
        system.assertEquals(updatedacc.Main_Street__c, updatedacc.BillingStreet);
        Test.stopTest();
    }

    private static testMethod void testUltimateParent() {
        //test for Account Archiving, DMU Process
        Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
        paymentTerm.Name = 'testAccountBlockUpdate';
        paymentTerm.Apttus_Config2__Sequence__c = 1;
        paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
        paymentTerm.APTS_Ext_ID__c = 'testAccountBlockUpdate';
        insert paymentTerm;

        Account accParent = new Account();
        accParent.Name = 'TestPArent';
        accParent.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        accParent.Main_Street_Only__c = 'Test Street9';
        accParent.Main_Postal_Code__c = null;
        accParent.Industry_Code__c = null;
        accParent.Phone = '+1234567890';
        accParent.CurrencyIsoCode = 'EUR';
        accParent.Language__c = 'SAP_EN';
        accParent.Sales_Organization__c = 'SAP_0111';
        accParent.Account_Type__c = 'Customer';
        accParent.Segment__c = 'SAP_A'; //Indicator for change of rule
        accParent.of_Employees_FTE__c = 10;
        accParent.SAP_PO_Updated__c = false;
        accParent.APTS_BizIsland_Bonsai_Account__c = false;
        accParent.IsActive__c = false;
        accParent.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        

        Account acc2 = new Account();
        acc2.Name = 'Parent acc';
        acc2.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        acc2.Main_Street_Only__c = 'Test Street';
        acc2.Main_Postal_Code__c = null;
        acc2.Industry_Code__c = null;
        acc2.Phone = '+1234567890';
        acc2.CurrencyIsoCode = 'EUR';
        acc2.Language__c = 'SAP_EN';
        acc2.Sales_Organization__c = 'SAP_0111';
        acc2.Account_Type__c = 'Customer';
        acc2.Segment__c = 'SAP_A'; //Indicator for change of rule
        acc2.of_Employees_FTE__c = 10;
        acc2.SAP_PO_Updated__c = false;
        acc2.APTS_BizIsland_Bonsai_Account__c = false;
        acc2.IsActive__c = false;
        acc2.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        acc2.ParentId = accParent.Id;
        test.startTest();
        insert accParent;
        insert acc2;
        test.stopTest();
        Account a1 = [Select Id, Ultimate_Parent_Account_Name_Search__c, Ultimate_Parent_Account__c, ParentId  FROM Account WHERE Id = :acc2.Id];
        system.assertEquals(a1.Ultimate_Parent_Account__c, a1.Ultimate_Parent_Account_Name_Search__c);
    }

    private static testMethod void testChangeAfterPromotion() {
        //test for Account Archiving, DMU Process
        Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
        paymentTerm.Name = 'testAccountBlockUpdate';
        paymentTerm.Apttus_Config2__Sequence__c = 1;
        paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
        paymentTerm.APTS_Ext_ID__c = 'testAccountBlockUpdate';
        insert paymentTerm;

        Account acc = new Account();
        acc.Name = 'testSAP';
        acc.recordtypeId = SM_Constants.recordTypeIdPromotionRequested;
        acc.Main_Street_Only__c = 'Test StreetSAP';
        acc.Main_Postal_Code__c = null;
        acc.Industry_Code__c = null;
        acc.Phone = '+1234567890';
        acc.CurrencyIsoCode = 'EUR';
        acc.Language__c = 'SAP_EN';
        acc.Sales_Organization__c = 'SAP_0111';
        acc.Account_Type__c = 'Prospect';
        acc.Segment__c = 'SAP_A'; //Indicator for change of rule
        acc.of_Employees_FTE__c = 10;
        acc.SAP_PO_Updated__c = false;
        acc.APTS_BizIsland_Bonsai_Account__c = false;
        acc.IsActive__c = true;
        acc.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        acc.Archiving_Flag__c = false;
        acc.Account_Lifecycle__c = 'Prospect';
        test.startTest();
        insert acc;

        acc.SAP_PO_Updated__c = true;
        acc.SAP_Customer_ID__c = '79302'; 
        checkrecursive.run = true;
        update acc;
        test.stopTest();
        Account a1 = [Select Id, Account_Type__c FROM Account WHERE Id = :acc.Id];
        system.assertEquals(a1.Account_Type__c, 'Customer');
    }

    private static testMethod void testDefaultLSP() {
        Id p = [SELECT Id FROM Profile WHERE Name = :SM_Constants.SystemAdmin].id;
                  
        User u = new User(alias = 'test123', email='test123@noemail.com',
                emailencodingkey='UTF-8', lastname='LastNamePartner', firstName = 'FirstNamePartner', languagelocalekey='en_US',
                localesidkey='en_US', profileid = p, country='United States',IsActive =true, Sales_Organization__c = 'SAP_0333',
                timezonesidkey='America/Los_Angeles', username='tester@notemail.com', Forwarding_Partner_Number__c= '99999');
       
        insert u;
        
        System.runAs(u) {
            //test for Account Archiving, DMU Process
            Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
            paymentTerm.Name = 'testAccountBlockUpdate';
            paymentTerm.Apttus_Config2__Sequence__c = 1;
            paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
            paymentTerm.APTS_Ext_ID__c = 'testAccountBlockUpdate';
            insert paymentTerm;

            Account acc = new Account();
            acc.Name = 'TestPArent';
            acc.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
            acc.Main_Street_Only__c = 'Test Street9';
            acc.Main_Postal_Code__c = null;
            acc.Industry_Code__c = null;
            acc.Phone = '+1234567890';
            acc.CurrencyIsoCode = 'EUR';
            acc.Language__c = 'SAP_EN';
            acc.Sales_Organization__c = 'SAP_0111';
            acc.Account_Type__c = 'Customer';
            acc.Segment__c = 'SAP_A'; //Indicator for change of rule
            acc.of_Employees_FTE__c = 10;
            acc.SAP_PO_Updated__c = false;
            acc.APTS_BizIsland_Bonsai_Account__c = false;
            acc.IsActive__c = false;
            acc.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
            acc.LSP_Forwarding_Partner__c = true;
            test.startTest();
            insert acc;
			test.stopTest();
            Account a = [Select Id, Forwarding_Partner_Number__c FROM Account WHERE Id = :acc.Id];
            System.assert(a.Forwarding_Partner_Number__c != '99999');
        }
    }

    private static testMethod void testSAPLSP() {
        Id p = [SELECT Id FROM Profile WHERE Name = :SM_Constants.SystemAdmin].id;
                  
        User u = new User(alias = 'test123', email='test123@noemail.com',
                emailencodingkey='UTF-8', lastname='LastNamePartner', firstName = 'FirstNamePartner', languagelocalekey='en_US',
                localesidkey='en_US', profileid = p, country='United States',IsActive =true, Sales_Organization__c = 'SAP_6712',
                timezonesidkey='America/Los_Angeles', username='tester@notemail.com', Forwarding_Partner_Number__c= '99999');
       
        insert u;
        
        System.runAs(u) {
            //test for Account Archiving, DMU Process
            Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
            paymentTerm.Name = 'testAccountBlockUpdate';
            paymentTerm.Apttus_Config2__Sequence__c = 1;
            paymentTerm.APTS_Sales_Org__c = 'SAP_6712';
            paymentTerm.APTS_Ext_ID__c = 'testAccountBlockUpdate';
            insert paymentTerm;

            Account acc = new Account();
            acc.Name = 'TestPArent';
            acc.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
            acc.Main_Street_Only__c = 'Test Street9';
            acc.Main_Postal_Code__c = null;
            acc.Industry_Code__c = null;
            acc.Phone = '+1234567890';
            acc.CurrencyIsoCode = 'EUR';
            acc.Language__c = 'SAP_EN';
            acc.Sales_Organization__c = 'SAP_6712';
            acc.Account_Type__c = 'Customer';
            acc.Segment__c = 'SAP_A'; //Indicator for change of rule
            acc.of_Employees_FTE__c = 10;
            acc.SAP_PO_Updated__c = false;
            acc.APTS_BizIsland_Bonsai_Account__c = false;
            acc.IsActive__c = false;
            acc.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
            acc.LSP_Forwarding_Partner__c = false;
            acc.Forwarding_Partner_Number__c = '';
            test.startTest();
            insert acc;

            acc.Forwarding_Partner_Number__c = '174168';
            acc.SAP_PO_Updated__c = true;
            checkrecursive.run = true;
            update acc;

            Map<String, String> defaultLSP = UserDAO.logisticPartnerInformation();
            defaultLSP.get(acc.Sales_Organization__c);
			test.stopTest();
            Account a = [Select Id, LSP_Forwarding_Partner__c FROM Account WHERE Id = :acc.Id];
            System.assert(a.LSP_Forwarding_Partner__c == true);
        }
    }
    
    public static testMethod void testSubSegmentUpdate(){
        
        Profile p = [SELECT Id FROM Profile WHERE  Name =: 'JDE-Integration-SAP']; 
        User u = new User(Alias = 'standt', Email='sample@testUser133000.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='sample@iukjiyhgjyjcxrd000.com', Sales_Organization__c = 'SAP_0333', CurrencyIsoCode = 'EUR');
            
        System.runAs(u){
            
            Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
            paymentTerm.Name = 'testAccountBlockUpdate';
            paymentTerm.Apttus_Config2__Sequence__c = 1;
            paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
            paymentTerm.APTS_Ext_ID__c = 'testAccountBlockUpdate';
            insert paymentTerm;
            
            test.startTest();
            
            Account acc = new Account();
            acc.Name = 'test Subsegment';
            acc.recordtypeId = SM_Constants.recordTypeIdEndCustomerValidation;
            acc.Main_Street_Only__c = 'Test StreetSAP';
            acc.Main_Postal_Code__c = null;
            acc.Industry_Code__c = null;
            acc.Phone = '+1234567890';
            acc.CurrencyIsoCode = 'EUR';
            acc.Language__c = 'SAP_EN';
            acc.Account_Type__c = 'Prospect';
            acc.Sales_Organization__c = 'SAP_0333';
            acc.Segment__c = 'SAP_A';
            acc.Subsegment__c = 'Construction';
            acc.Updated_Segment__c = 'SAP_B';
            acc.Updated_Sub_Segment__c = 'Industry';
            acc.of_Employees_FTE__c = 10;
            acc.APTS_BizIsland_Bonsai_Account__c = false;
            acc.IsActive__c = true;
            acc.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
            acc.Archiving_Flag__c = false;
            acc.Account_Lifecycle__c = 'Active Customer';
            acc.Sap_Customer_Id__c = '1223344';
            insert acc;
            
            acc.SAP_PO_Updated__c = true;
            acc.Segment__c = 'SAP_B';
            checkrecursive.run = true;
            update acc;
            
            Account updatedAcc = [SELECT Id, Subsegment__c FROM Account WHERE Id =: acc.Id];
        	system.assertEquals('Industry', updatedAcc.Subsegment__c);
            test.stopTest();
        }
    }
    
    private static testMethod void testUpdateRelOpp() {
        test.startTest();
        Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
        paymentTerm.Name = 'testAccountBlockUpdate';
        paymentTerm.Apttus_Config2__Sequence__c = 1;
        paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
        paymentTerm.APTS_Ext_ID__c = 'testAccountBlockUpdate';
        insert paymentTerm;

        Account accPartner = new Account();
        accPartner.Name = 'test accPartner';
        accPartner.recordtypeId = SM_Constants.recordTypeIdCustomer;
        accPartner.Main_Street_Only__c = 'Test accPartner';
        accPartner.Main_Postal_Code__c = null;
        accPartner.Industry_Code__c = null;
        accPartner.Phone = '+0987654321';
        accPartner.CurrencyIsoCode = 'EUR';
        accPartner.Language__c = 'SAP_EN';
        accPartner.Sales_Organization__c = 'SAP_0111';
        accPartner.Account_Type__c = 'Prospect';
        accPartner.Segment__c = 'SAP_A';
        accPartner.of_Employees_FTE__c = 10;
        accPartner.IsActive__c = true;
        accPartner.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        accPartner.Archiving_Flag__c = false;
        accPartner.Account_Lifecycle__c = 'Active Customer';
        accPartner.Sap_Customer_Id__c = '888989';
        insert accPartner;

        Account accPartner2 = new Account();
        accPartner2.Name = 'test accPartner2';
        accPartner2.recordtypeId = SM_Constants.recordTypeIdCustomer;
        accPartner2.Main_Street_Only__c = 'Test accPartner2';
        accPartner2.Main_Postal_Code__c = null;
        accPartner2.Industry_Code__c = null;
        accPartner2.Phone = '+1234567890';
        accPartner2.CurrencyIsoCode = 'EUR';
        accPartner2.Language__c = 'SAP_EN';
        accPartner2.Sales_Organization__c = 'SAP_0111';
        accPartner2.Account_Type__c = 'Prospect';
        accPartner2.Segment__c = 'SAP_A';
        accPartner2.of_Employees_FTE__c = 9;
        accPartner2.IsActive__c = true;
        accPartner2.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        accPartner2.Archiving_Flag__c = false;
        accPartner2.Account_Lifecycle__c = 'Active Customer';
        accPartner2.Sap_Customer_Id__c = '1223344';
        insert accPartner2;

        Account acc = new Account();
        acc.Name = 'test Subsegment';
        acc.recordtypeId = SM_Constants.recordTypeIdCustomer;
        acc.Main_Street_Only__c = 'Test StreetSAP';
        acc.Main_Postal_Code__c = null;
        acc.Industry_Code__c = null;
        acc.Phone = '+8888888888';
        acc.CurrencyIsoCode = 'EUR';
        acc.Language__c = 'SAP_EN';
        acc.Sales_Organization__c = 'SAP_0111';
        acc.Account_Type__c = 'Prospect';
        acc.Segment__c = 'SAP_A';
        acc.of_Employees_FTE__c = 10;
        acc.APTS_BizIsland_Bonsai_Account__c = false;
        acc.IsActive__c = true;
        acc.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        acc.Archiving_Flag__c = false;
        acc.Account_Lifecycle__c = 'Active Customer';
        acc.Sap_Customer_Id__c = '098967';
        acc.GTM_Ingredients__c = accPartner.Id;
        insert acc;

        Opportunity opp = new Opportunity();
        opp.Name = 'oppName';
        opp.AccountId = acc.id;
        opp.CLoseDate = Date.Today();
        opp.StageName = 'Open';
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(SM_Constants.OppPrfPartnerRT).getRecordTypeId();
        opp.Sales_Organization__c = 'SAP_0111';
        insert opp;

        Map<String, String> internalAssignedMap = SM_GetMetadata.getInternalAssigment();
        checkrecursive.run = true;
        acc.GTM_Ingredients__c = accPartner2.Id;
        update acc;

        Opportunity oppr = [Select Id, OwnerId, Partner_Opportunity_Owner__c, StageName, AccountId, Sales_Organization__c FROM Opportunity WHERE Id = :opp.Id];

        System.assert(oppr.StageName == 'No Bid');
        System.assert(oppr.Partner_Opportunity_Owner__c == accPartner.Id);

        test.stopTest();
    }

    private static testMethod void testArchivingAL() {
        test.startTest();
        Id al = Schema.SObjectType.Apttus_Config2__AccountLocation__c.getRecordTypeInfosByName().get('Account Location').getRecordTypeId();
        //test for Account Archiving, DMU Process
        Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
        paymentTerm.Name = 'testAccountBlockUpdate';
        paymentTerm.Apttus_Config2__Sequence__c = 1;
        paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
        paymentTerm.APTS_Ext_ID__c = 'testAccountBlockUpdate';
        insert paymentTerm;
        
        List<Account> accList = new List<Account>();
        Account acc2 = new Account();
        acc2.Name = 'Created Archived Acc';
        acc2.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        acc2.Main_Street_Only__c = 'Test Street';
        acc2.Main_Postal_Code__c = null;
        acc2.Industry_Code__c = null;
        acc2.Phone = '+1234567890';
        acc2.CurrencyIsoCode = 'EUR';
        acc2.Language__c = 'SAP_EN';
        acc2.Sales_Organization__c = 'SAP_0333';
        acc2.Account_Type__c = 'Customer';
        acc2.Segment__c = 'SAP_A'; //Indicator for change of rule
        acc2.of_Employees_FTE__c = 10;
        acc2.SAP_PO_Updated__c = false;
        acc2.APTS_BizIsland_Bonsai_Account__c = false;
        acc2.IsActive__c = false;
        acc2.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        acc2.Account_Lifecycle__c = 'Inactive Customer';
        acc2.Archiving_Flag__c = true;
        acc2.Archiving_Reason__c = 'Duplicate Account';
        acc2.First_Account_Location_created__c = true;
        
        accList.add(acc2);
        insert accList;

        Apttus_Config2__AccountLocation__c acctLoc = new Apttus_Config2__AccountLocation__c();
        acctLoc.RecordTypeId = al;
        acctLoc.Apttus_Config2__AccountId__c = acc2.Id;
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
        acctLoc.Archiving_Flag__c = true;
        insert acctLoc;
        
        accList[0].Archiving_Flag__c = false;
        checkrecursive.run = true;
        update accList;
        
        Account a2 = [Select Id, Name, Account_Lifecycle__c, IsActive__c, Last_Relevant_Activity_Date__c, Archiving_Reason__c, Archiving_Flag__c, DMU__c, Key_Account__c FROM Account WHERE Id = :accList[0].Id];
        system.assertEquals(true, a2.isActive__c); 
        test.stopTest();
    }
    
    public static testMethod void testRemoveBillBlockReason(){
        test.startTest();
        Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
        paymentTerm.Name = 'testAccountBlockUpdate';
        paymentTerm.Apttus_Config2__Sequence__c = 1;
        paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
        paymentTerm.APTS_Ext_ID__c = 'testAccountBlockUpdate';
        insert paymentTerm;
        
        Account acc = new Account();
        acc.Name = 'test Subsegment';
        acc.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        acc.Main_Street_Only__c = 'Test StreetSAP';
        acc.Main_Postal_Code__c = null;
        acc.Industry_Code__c = null;
        acc.Phone = '+1234567890';
        acc.CurrencyIsoCode = 'EUR';
        acc.Language__c = 'SAP_EN';
        acc.Sales_Organization__c = 'SAP_0333';
        acc.Account_Type__c = 'Customer';
        acc.Segment__c = 'SAP_A';
        acc.of_Employees_FTE__c = 10;
        acc.APTS_BizIsland_Bonsai_Account__c = false;
        acc.IsActive__c = true;
        acc.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        acc.Archiving_Flag__c = false;
        acc.Account_Lifecycle__c = 'Active Customer';
        acc.Sap_Customer_Id__c = '1222344';
        acc.Account_Block__c = true;
        acc.Bill_Block_Reason__c = 'SAP_00';
        insert acc;
        
        
        User userrec = UserDAO.userInformation();
        acc.Account_Block__c = false;
        checkrecursive.run = true;
        update acc;
        
        Account updatedAcc = [SELECT Id, Bill_Block_Reason__c, RecordType.Name, Account_Block__c, Updated_Bill_Block_Reason__c FROM Account WHERE Id =: acc.Id];
        system.assertEquals('NULL', updatedAcc.Updated_Bill_Block_Reason__c);
        test.stopTest();
    }
    
    public static testMethod void accountnotvalid(){
        test.startTest();
        Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
        paymentTerm.Name = 'testAccountBlockUpdate';
        paymentTerm.Apttus_Config2__Sequence__c = 1;
        paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
        paymentTerm.APTS_Ext_ID__c = 'testAccountBlockUpdate';
        insert paymentTerm;
        
        Account acc = new Account();
        acc.Name = 'test Subsegment';
        acc.recordtypeId = SM_Constants.recordTypeIdProspectValid;
        acc.Main_Street_Only__c = 'Test StreetSAP';
        acc.Main_Postal_Code__c = null;
        acc.Industry_Code__c = null;
        acc.Phone = '+1234567890';
        acc.CurrencyIsoCode = 'EUR';
        acc.Language__c = 'SAP_EN';
        acc.Sales_Organization__c = 'SAP_0333';
        acc.Account_Type__c = 'Prospect';
        acc.Segment__c = 'SAP_A';
        acc.of_Employees_FTE__c = 10;
        acc.APTS_BizIsland_Bonsai_Account__c = false;
        acc.IsActive__c = true;
        acc.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        acc.Archiving_Flag__c = false;
        acc.Account_Lifecycle__c = 'Prospect';
        acc.Address_Validation__c = 'Valid';
        acc.Sap_Customer_Id__c = '1222344';
        acc.Account_Block__c = true;
        acc.Bill_Block_Reason__c = 'SAP_00';
        acc.Main_Address_Validation_Pending__c = false;
        insert acc;
        
        
        acc.Main_Address_Validation_Pending__c = true;
        checkrecursive.run = true;
        update acc;
        
        Account updatedAcc = [SELECT Id, Address_Validation__c FROM Account WHERE Id =: acc.Id];
        system.assertEquals('Not Valid', updatedAcc.Address_Validation__c);
        test.stopTest();
    }
    
    private static testMethod void BeforeUpdateChangeFieldValueTestSysAdVATValidation(){   
        try{
            Profile p = [SELECT Id FROM Profile WHERE Name =: SM_Constants.SystemAdmin]; 
            User u = new User(Alias = 'standt', Email='sample@testUser123222.com', 
            EmailEncodingKey='UTF-8', LastName='TestingTest123', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='sample@testUser14565.com', Sales_Organization__c = 'SAP_0333', Elevated_Access_Reason__c = 'Defect or Incident Resolution', Elevated_Access_Reference__c = 'ASDF');
            
            System.runAs(u) {
            
            Apttus_Config2__PaymentTerm__c paymentTerm2 = new Apttus_Config2__PaymentTerm__c();
            paymentTerm2.Name = 'Ssdsa';
            paymentTerm2.Apttus_Config2__Sequence__c = 1;
            paymentTerm2.APTS_Sales_Org__c = 'SAP_0333';
            paymentTerm2.APTS_Ext_ID__c = 'smpl123';
            insert paymentTerm2;
                
            List<Account> accList = new List<Account>();
            Integer i = 10;
            String randSapID = '12344';
            for(integer x = 0; x<=i; x++){
                Account acc = new Account();
                acc.Name = 'accName' + i;
                acc.Second_Account_Name__c = 'sAccName' + i;
                acc.Archiving_Flag__c = false;
                acc.BillingStreet = 'mainstreet' + i;
                acc.Main_House_Number__c = '123' + i;
                acc.Main_Street_Only__c = 'streetOnly' + i;
                acc.BillingCity = 'mainCity' + i;
                acc.BillingState = 'state' + i;
                acc.BillingPostalCode = 'pCode' + i;
                acc.BillingCountry = 'country' + i;
                acc.Main_Country_ISO__c = 'countryISO' + i;
                acc.Language__c = 'SAP_SR';
                acc.Bill_Block_Reason__c = 'SAP_00';
                acc.Transactional_Block_Reason__c = 'SAP_00';
                acc.Delivery_Block_Reason__c = 'SAP_D3';
                acc.Apttus_Config2__PaymentTermId__c =paymentTerm2.Id;
                acc.SAP_Customer_ID__c = randSapID + x;
                acc.Phone = '+31302979111';
                acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.Customer).getRecordTypeId();
                acc.Segment__c = 'SAP_A';
                //acc.Mini_Dunning_procedure__c = 'SAP_0079';
                acc.Mini_Invoicing_dates__c = 'SAP_2M';
                acc.Invoice_List_Dates__c = 'SAP_2M';
                acc.Update_Request_Validation_Payment_Term__c = SM_Constants.NoUpdateRequest;
                acc.Update_Request_Validation_Payment_Method__c = SM_Constants.NoUpdateRequest;
                acc.Sales_Office__c = null;
                acc.Creditworthiness_Flag__c = 'Green';
                acc.Main_Address_Validation_Pending__c = false;
                acc.Archiving_Flag__c = false;
                acc.VAT_Registration_Number__c = 'BE0401288505';
                
                accList.add(acc);
            }
            
            Mini_Template__c miniTemplate = Mini_Template__c.getInstance(u.Sales_Organization__c);
            List<MiniTemplateTax__c> miniTemplateTaxes = MiniTemplateTax__c.getall().values();
            test.startTest();
            insert accList;
            Integer a = 0;
            for(Account acc : accList)
            {
                acc.Name = 'Test new eman eman eman';
                acc.Second_Account_Name__c = 'New Test 2nd Name';
                acc.SAP_Customer_ID__c = '48107' + a;
                acc.Main_House_Number__c = '123Test'+a;
                acc.Main_Street_Only__c = 'Street Test' +a;
                acc.BillingCity = 'City of Dreams' + a;
                acc.BillingCountry = 'Netherlands';
                acc.Main_Country_ISO__c = '12345' + a;
                //acc.Main_Postal_Box__c = '54321' + i;
                acc.Bill_Block_Reason__c = 'SAP_11';
                acc.Archiving_Flag__c = true;
                acc.Transactional_Block_Reason__c = 'SAP_03';
                acc.Delivery_Block_Reason__c = 'SAP_Z3';
                acc.Segment__c = 'SAP_B';
                //acc.Mini_Dunning_procedure__c = 'SAP_0079';
                acc.Mini_Invoicing_dates__c = 'SAP_1M';
                acc.Invoice_List_Dates__c = 'SAP_1M';
                acc.howManyLoop__c = 4;
                acc.Apttus_Config2__PaymentTermId__c = paymentTerm2.Id;
                acc.VAT_Registration_Number__c = null;
                //acc.APTS_Payment_Method__c = pmList[1].Id;
                
                a++;
            }
            
            
              System.debug('u: ' + u);
              System.debug('miniTemplateTaxes: ' + miniTemplateTaxes);
              checkrecursive.run = true;
              update accList;
              System.assertEquals(accList[0].Apttus_Config2__PaymentTermId__c,  paymentTerm2.Id);
              test.stopTest();
            }
        } catch (Exception e) {
            System.debug(e);
        } 
        
    }
    
    private static testMethod void testAccountArchivingInactive() {
        test.startTest();
        //test for Account Archiving, DMU Process
        Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
        paymentTerm.Name = 'testAccountBlockUpdate';
        paymentTerm.Apttus_Config2__Sequence__c = 1;
        paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
        paymentTerm.APTS_Ext_ID__c = 'testAccountBlockUpdate';
        insert paymentTerm;
        
        List<Account> accList = new List<Account>();
        Account acc2 = new Account();
        acc2.Name = 'Created Archived Acc';
        acc2.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        acc2.Main_Street_Only__c = 'Test Street';
        acc2.Main_Postal_Code__c = null;
        acc2.Industry_Code__c = null;
        acc2.Phone = '+1234567890';
        acc2.CurrencyIsoCode = 'EUR';
        acc2.Language__c = 'SAP_EN';
        acc2.Sales_Organization__c = 'SAP_0333';
        acc2.Account_Type__c = 'Customer';
        acc2.Segment__c = 'SAP_A'; //Indicator for change of rule
        acc2.of_Employees_FTE__c = 10;
        acc2.SAP_PO_Updated__c = false;
        acc2.APTS_BizIsland_Bonsai_Account__c = false;
        acc2.IsActive__c = false;
        acc2.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        acc2.Account_Lifecycle__c = 'Inactive Customer';
        acc2.Archiving_Flag__c = true;
        acc2.Archiving_Reason__c = 'Duplicate Account';
        acc2.Deactivation_Reason__c = 'Lost to competitor - Price';
        
        
        Account acc3 = new Account();
        acc3.Name = 'Created Archived Acc';
        acc3.recordtypeId = SM_Constants.recordTypeIdAdministrativeAddress;
        acc3.Main_Street_Only__c = 'Test Street';
        acc3.Main_Postal_Code__c = null;
        acc3.Industry_Code__c = null;
        acc3.Phone = '+1234567890';
        acc3.CurrencyIsoCode = 'EUR';
        acc3.Language__c = 'SAP_EN';
        acc3.Sales_Organization__c = 'SAP_0333';
        acc3.Account_Type__c = 'Customer';
        acc3.Segment__c = 'SAP_A'; //Indicator for change of rule
        acc3.of_Employees_FTE__c = 10;
        acc3.SAP_PO_Updated__c = false;
        acc3.APTS_BizIsland_Bonsai_Account__c = false;
        acc3.IsActive__c = false;
        acc3.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        acc3.Archiving_Flag__c = true;
        acc3.Archiving_Reason__c = 'Duplicate Account';
        acc3.Deactivation_Reason__c = 'Lost to competitor - Price';
        
        accList.add(acc2);
        accList.add(acc3);
        insert accList;
        
        accList[0].Archiving_Flag__c = false;
        accList[1].Archiving_Flag__c = false;
        checkrecursive.run = true;
        update accList;
        
        Account a1 = [Select Id, Name, Account_Lifecycle__c FROM Account WHERE Id = :accList[0].Id];
        system.assertEquals('Inactive Customer', a1.Account_Lifecycle__c);
        
        Account a3 = [Select Id, Name, Account_Lifecycle__c FROM Account WHERE Id = :accList[1].Id];
        system.assertEquals('Administrative', a3.Account_Lifecycle__c);
        test.stopTest();
    }
    
    public static testMethod void testAdministrativeAddressSAPReturn(){
        
        Profile p = [SELECT Id FROM Profile WHERE  Name =: 'JDE-Integration-SAP']; 
        User u = new User(Alias = 'standt', Email='sample@testUser133000.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='sample@iukjiyhgjyjcxrd000.com', Sales_Organization__c = 'SAP_0333', CurrencyIsoCode = 'EUR');
            
        System.runAs(u){
            
            Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
            paymentTerm.Name = 'testAccountBlockUpdate';
            paymentTerm.Apttus_Config2__Sequence__c = 1;
            paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
            paymentTerm.APTS_Ext_ID__c = 'testAccountBlockUpdate';
            insert paymentTerm;
            
            test.startTest();
            
            Account acc = new Account();
            acc.Name = 'test Subsegment';
            acc.recordtypeId = SM_Constants.recordTypeIdAdministrativeAddressValidation;
            acc.Main_Street_Only__c = 'Test StreetSAP';
            acc.Main_Postal_Code__c = null;
            acc.Industry_Code__c = null;
            acc.Phone = '+1234567890';
            acc.CurrencyIsoCode = 'EUR';
            acc.Language__c = 'SAP_EN';
            acc.Account_Type__c = 'Prospect';
            acc.Sales_Organization__c = 'SAP_0333';
            acc.Segment__c = 'SAP_A';
            acc.Subsegment__c = 'Construction';
            acc.Updated_Segment__c = 'SAP_B';
            acc.Updated_Sub_Segment__c = 'Industry';
            acc.of_Employees_FTE__c = 10;
            acc.APTS_BizIsland_Bonsai_Account__c = false;
            acc.IsActive__c = true;
            acc.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
            acc.Archiving_Flag__c = false;
            acc.Account_Lifecycle__c = 'Administrative';
            acc.Sap_Customer_Id__c = '1223344';
            acc.Duplicate_Reason__c = 'Online Registered Customer';
            acc.House_Number_Supplement__c = '-32';
            insert acc;
            
            acc.SAP_PO_Updated__c = true;
            acc.Segment__c = 'SAP_B';
            checkrecursive.run = true;
            update acc;
            
            Account updatedAcc = [SELECT Id, RecordTypeId FROM Account WHERE Id =: acc.Id];
        	system.assertEquals(SM_Constants.recordTypeIdAdministrativeAddress, updatedAcc.RecordTypeId);
            test.stopTest();
        }
    }
}