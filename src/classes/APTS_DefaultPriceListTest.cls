/**********************************************************************************
 * @Author: Jason Mactal
 * @Company: Accenture
 * @Description: Test Class for APTS_DefaultPriceList
 * @Created Date: Feb 15, 2018
 * @History:
 *      <Name>              <Date>          <Description>
 *      jason.e.mactal      2.15.2018       Created
 *      jason.e.mactal      9.13.2018       Updated to cover new CSP Logic
 *
 **********************************************************************************/
@isTest
public class APTS_DefaultPriceListTest {
    @testSetup
    static void testSetup() {

        User testUser = APTS_TestDataFactory.createUser();
        testUser.UserName = 'testuser123@jdecoffee.com';
        insert testUser;
        system.runAs(testUser) {
            insert new TriggerSettings__c(SetupOwnerId = UserInfo.getOrganizationId(), Agreement__c = true, AccountTrigger__c = false);
            insert new WorkflowSettings__c(SetupOwnerId = UserInfo.getOrganizationId(), AccountWorkflows__c = false, OpportunityWorkflows__c = false);

            List<Account> accList = TestDataFactory.createAccounts(9, 'TEST1234');
            for(Account acc: accList){
                acc.Sales_Organization__c = 'SAP_0111';
                acc.Sales_Office__c = 'SAP_BICC';
            }
            insert accList;

            Id oppStandardRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Standard Opportunity').getRecordTypeId();

            List<Apttus_Config2__PriceList__c> plList = new List<Apttus_Config2__PriceList__c>();
            Apttus_Config2__PriceList__c directPriceList = new Apttus_Config2__PriceList__c(Name = 'General Price List', Apttus_Config2__Active__c = true, CurrencyIsoCode = 'EUR', APTS_Region__c = 'SAP_0111', APTS_SalesOrg__c = '0111', APTS_PriceList_Type__c = 'Direct');
            Apttus_Config2__PriceList__c indirectPriceList = new Apttus_Config2__PriceList__c(Name = 'Indirect Price List', Apttus_Config2__Active__c = true, CurrencyIsoCode = 'EUR', APTS_Region__c = 'SAP_0111', APTS_SalesOrg__c = '0111', APTS_PriceList_Type__c = 'Indirect');
            Apttus_Config2__PriceList__c routesalesPriceList = new Apttus_Config2__PriceList__c(Name = 'Routesales Price List', Apttus_Config2__Active__c = true, CurrencyIsoCode = 'EUR', APTS_Region__c = 'SAP_0111', APTS_SalesOrg__c = '0111', APTS_PriceList_Type__c = 'Routesales');
            plList.add(directPriceList);
            plList.add(indirectPriceList);
            plList.add(routesalesPriceList);
            insert plList;

            List<Opportunity> oppList = new List<Opportunity>();
            for (Account acc : [SELECT Id, Name, Partner__c, Sales_Organization__c FROM Account]) {
                Opportunity opp = new Opportunity();
                opp.AccountID = acc.id;
                opp.Name = 'Test';
                opp.RecordTypeId = oppStandardRecordTypeId;
                opp.StageName = 'Develop Proposal / Presentation';
                opp.CloseDate = Date.today().addMonths(3);
                opp.CurrencyIsoCode = 'EUR';
                opplist.add(opp);
            }
            insert opplist;
        }

    }
    private static testMethod void defaultDirectPriceList() {
        user testUser = [SELECT Id FROM USER WHERE UserName = 'testuser123@jdecoffee.com' LIMIT 1];
        Id standardDealRT = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
        system.runAs(testUser) {
            List<Account> accList = [SELECT Id, Partner__c FROM Account];
            //Set Account Sales Org to Netherlands
            for (Account acc : accList) {
                acc.Sales_Organization__c = 'SAP_0111';
            }
            update accList;
            List<Apttus__APTS_Agreement__c> agreementList = new List<Apttus__APTS_Agreement__c>();
            for (Opportunity opp : [SELECT Id, Account.Id, Account.Name FROM Opportunity]) {
                Apttus__APTS_Agreement__c agg = new Apttus__APTS_Agreement__c();
                agg.Name = opp.Account.Name + ' Agreement';
                agg.Apttus__Account__c = opp.Account.Id;
                agg.RecordTypeId = standardDealRT;
                agg.Apttus__Related_Opportunity__c = opp.id;
                agreementList.add(agg);
            }
            test.startTest();
            database.insert(agreementList);
            test.stopTest();

            List<Apttus__APTS_Agreement__c> checkAgreementList = [SELECT ID FROM Apttus__APTS_Agreement__c WHERE Apttus_CMConfig__PriceListId__r.APTS_PriceList_Type__c = 'Direct'];
            system.assertEquals(10, checkAgreementList.size());
        }
    }
    private static testMethod void defaultIndirectPriceList() {
        Id standardDealRT = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
        user testUser = [SELECT Id FROM USER WHERE UserName = 'testuser123@jdecoffee.com' LIMIT 1];
        system.runAs(testUser) {
            List<Account> accList = [SELECT Id, Partner__c FROM Account];
            //Set Account Sales Org to Netherlands and Partner = TRUE
            for (Account acc : accList) {
                acc.Partner__c = TRUE;
                acc.Sales_Organization__c = 'SAP_0111';
            }
            update accList;
            List<Apttus__APTS_Agreement__c> agreementList = new List<Apttus__APTS_Agreement__c>();
            for (Opportunity opp : [SELECT Id, Account.Id, Account.Name FROM Opportunity]) {
                Apttus__APTS_Agreement__c agg = new Apttus__APTS_Agreement__c();
                agg.Name = opp.Account.Name + ' Agreement';
                agg.Apttus__Account__c = opp.Account.Id;
                agg.RecordTypeId = standardDealRT;
                agg.Apttus__Related_Opportunity__c = opp.id;
                agreementList.add(agg);
            }
            test.startTest();
            database.insert(agreementList);
            test.stopTest();

            List<Apttus__APTS_Agreement__c> checkAgreementList = [SELECT ID FROM Apttus__APTS_Agreement__c WHERE Apttus_CMConfig__PriceListId__r.APTS_PriceList_Type__c = 'Indirect'];
            system.assertEquals(10, checkAgreementList.size());
        }
    }
    private static testMethod void defaultRoutesalesPriceList() {
        Id standardDealRT = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
        user testUser = [SELECT Id FROM USER WHERE UserName = 'testuser123@jdecoffee.com' LIMIT 1];
        system.runAs(testUser) {
            List<Account> accList = [SELECT Id, Partner__c FROM Account];
            //Set Account Sales Org to Netherlands
            for (Account acc : accList) {
                acc.Sales_Organization__c = 'SAP_0111';
            }
            update accList;
            List<Apttus__APTS_Agreement__c> agreementList = new List<Apttus__APTS_Agreement__c>();
            for (Opportunity opp : [SELECT Id, Account.Id, Account.Name FROM Opportunity]) {
                Apttus__APTS_Agreement__c agg = new Apttus__APTS_Agreement__c();
                agg.Name = opp.Account.Name + ' Agreement';
                agg.Apttus__Account__c = opp.Account.id;
                agg.RecordTypeId = standardDealRT;
                agg.Apttus__Related_Opportunity__c = opp.id;
                agg.APTS_Routesales__c = TRUE;
                agg.CurrencyIsoCode = 'EUR';
                agreementList.add(agg);
            }
            test.startTest();
            database.insert(agreementList);
            test.stopTest();

            List<Apttus__APTS_Agreement__c> checkAgreementList = [SELECT ID FROM Apttus__APTS_Agreement__c WHERE Apttus_CMConfig__PriceListId__r.APTS_PriceList_Type__c = 'Routesales'];
            system.assertEquals(10, checkAgreementList.size());
        }
    }
    private static testMethod void defaultCSPPriceList() {
        Id standardDealRT = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
        Apttus_Config2__PriceList__c cspPriceList = new Apttus_Config2__PriceList__c(Name = 'CSP Price List', Apttus_Config2__Active__c = true, CurrencyIsoCode = 'EUR', APTS_Region__c = 'SAP_0111', APTS_SalesOrg__c = '0111',APTS_PriceList_Type__c = 'CSP');
        

        user testUser = [SELECT Id FROM USER WHERE UserName = 'testuser123@jdecoffee.com' LIMIT 1];
        system.runAs(testUser) {
            insert cspPriceList;

            List<Account> accList = [SELECT Id, Partner__c, APTS_Price_List__c FROM Account];
            ////Set Account Sales Org to Netherlands
            for (Account acc : accList) {
                acc.Sales_Organization__c = 'SAP_0111';
                acc.APTS_Price_List__c = cspPriceList.Id;
            }
            update accList;
            List<Apttus__APTS_Agreement__c> agreementList = new List<Apttus__APTS_Agreement__c>();
            for (Opportunity opp : [SELECT Id, Account.Id, Account.Name FROM Opportunity]) {
                Apttus__APTS_Agreement__c agg = new Apttus__APTS_Agreement__c();
                agg.Name = opp.Account.Name + ' Agreement';
                agg.Apttus__Account__c = opp.Account.Id;
                agg.RecordTypeId = standardDealRT;
                agg.Apttus__Related_Opportunity__c = opp.id;
                agreementList.add(agg);
            }
            test.startTest();
            database.insert(agreementList);
            test.stopTest();

            List<Apttus__APTS_Agreement__c> checkAgreementList = [SELECT ID FROM Apttus__APTS_Agreement__c WHERE Apttus_CMConfig__PriceListId__r.APTS_PriceList_Type__c = 'CSP'];
            system.assertEquals(10, checkAgreementList.size());
        }
    }
    private static testMethod void noPriceListAvailable() {
        Id standardDealRT = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
        List<Apttus_Config2__PriceList__c> plList = [SELECT ID FROM Apttus_Config2__PriceList__c];

        user testUser = [SELECT Id FROM USER WHERE UserName = 'testuser123@jdecoffee.com' LIMIT 1];
        system.runAs(testUser) {
            delete plList;

            List<Account> accList = [SELECT Id, Partner__c FROM Account];
            ////Set Account Sales Org to Netherlands
            for (Account acc : accList) {
                acc.Sales_Organization__c = 'SAP_0111';
            }
            update accList;
            List<Apttus__APTS_Agreement__c> agreementList = new List<Apttus__APTS_Agreement__c>();
            for (Opportunity opp : [SELECT Id, Account.Id, Account.Name FROM Opportunity]) {
                Apttus__APTS_Agreement__c agg = new Apttus__APTS_Agreement__c();
                agg.Name = opp.Account.Name + ' Agreement';
                agg.Apttus__Account__c = opp.Account.Id;
                agg.RecordTypeId = standardDealRT;
                agg.Apttus__Related_Opportunity__c = opp.id;
                agreementList.add(agg);
            }
            test.startTest();
            database.insert(agreementList);
            test.stopTest();

            List<Apttus__APTS_Agreement__c> checkAgreementList = [SELECT ID FROM Apttus__APTS_Agreement__c WHERE Apttus_CMConfig__PriceListId__c = null];
            system.assertEquals(10, checkAgreementList.size());
        }
    }

    @isTest static void test_getDefaultPriceListId() {

        user testUser = [SELECT Id FROM USER WHERE UserName = 'testuser123@jdecoffee.com' LIMIT 1];
        List<Apttus_Config2__PriceList__c> plList = [SELECT Id, APTS_Region__c, APTS_PriceList_Type__c FROM Apttus_Config2__PriceList__c];
        for(Apttus_Config2__PriceList__c priceList: plList){
            if(priceList.APTS_PriceList_Type__c == 'Direct'){
                priceList.APTS_Region__c = 'SAP_0333';
            }
        }
        update plList;

        System.runAs(testUser) {

            List<Account> accList = [SELECT Id, Sales_Organization__c, Partner__c FROM Account];
            //Set Account Sales Org to Netherlands and Partner = TRUE

            Test.startTest();

            APTS_DefaultPriceList oDefaultPriceList = new APTS_DefaultPriceList();

            oDefaultPriceList.getDefaultPriceListId(accList[0]);

            accList[1].Partner__c = true;
            accList[1].Sales_Organization__c = 'SAP_0111';
            Database.update(accList);  
            
            oDefaultPriceList.getDefaultPriceListId(accList[1]);          

            accList[2].Partner__c = false;
            accList[2].Sales_Organization__c = 'SAP_0333';
            Database.update(accList);

            oDefaultPriceList.getDefaultPriceListId(accList[2]);

            Test.stopTest();
        }
    }
    
    @isTest
    static void testDefaultPricelist(){
        try{
            Id standardDealRT = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
            user testUser = [SELECT Id FROM USER WHERE UserName = 'testuser123@jdecoffee.com' LIMIT 1];
    
            Account acc = new Account();
            acc.Name = 'Test Account ';
            acc.Archiving_Flag__c = true;
            acc.BillingStreet = 'mainstreet';
            acc.Main_House_Number__c = '123';
            acc.Main_Street_Only__c = 'streetOnly';
            acc.BillingCity = 'mainCity';
            acc.BillingState = 'state';
            acc.BillingPostalCode = 'pCode';
            acc.BillingCountry = 'country';
            acc.Main_Country_ISO__c = 'countryISO';
            acc.Main_Postal_Box__c = 'pBox';
            acc.Language__c = 'SAP_SR';
            acc.Bill_Block_Reason__c = 'SAP_00';
            acc.Transactional_Block_Reason__c = 'SAP_00';
            acc.Delivery_Block_Reason__c = 'SAP_D3';
            acc.Phone = '+31302979111';
            insert acc;
            
            List<Apttus_Config2__PriceList__c> plList = [SELECT Id, APTS_Region__c, APTS_PriceList_Type__c FROM Apttus_Config2__PriceList__c];
            
            List<Account> accList = new List<Account>();
            
            for(Account acc1 : [SELECT Id, Partner__c FROM Account limit 1]){
                acc1.ParentId = acc.Id;
                accList.add(acc1);
            }
    
            update accList;
            
            List<Apttus__APTS_Agreement__c> aggList = new List<Apttus__APTS_Agreement__c>();
            
            Apttus__APTS_Agreement__c agg = new Apttus__APTS_Agreement__c();
            agg.Name = 'Test Agreement';
            agg.Apttus__Account__c = acc.Id;
            agg.RecordTypeId = standardDealRT;
            agg.CurrencyIsoCode = 'EUR';
            agg.Apttus__Status_Category__c = 'In Effect';
            agg.Apttus__Status__c = 'Activated';
            agg.Apttus_CMConfig__PriceListId__c = plList[0].Id;
            aggList.add(agg);
            
            Apttus__APTS_Agreement__c agg1 = new Apttus__APTS_Agreement__c();
            agg1.Name = 'Test Agreement 2';
            agg1.Apttus__Account__c = accList[0].Id;
            agg1.RecordTypeId = standardDealRT;
            agg1.CurrencyIsoCode = 'EUR';
            aggList.add(agg1);
            insert aggList;
        }catch(Exception ex){}
    }
}