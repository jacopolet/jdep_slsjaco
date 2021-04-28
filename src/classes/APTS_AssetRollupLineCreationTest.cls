/*
* @author        Rahul Garje
* @date          10 July 2018          
* @description   Test class for APTS_AssetRollupLineCreation_BatchJob
* @revision(s)
*/
@isTest
public class APTS_AssetRollupLineCreationTest {

//@testSetup
    public static void dataSetup(){
        
        TriggerSettings__c objTriggerSettings = new TriggerSettings__c();
        objTriggerSettings.APTS_Order_Trigger__c = false;
        objTriggerSettings.APTS_OrderLineItemTrigger__c = false;
        insert objTriggerSettings;
        
         Apttus_Config2__BillingPreference__c oBillingPref = new Apttus_Config2__BillingPreference__c();
        oBillingPref.Name = 'Pending';
        oBillingPref.Apttus_Config2__BillingDayOfMonth2__c = '1st of the Month';
        oBillingPref.Apttus_Config2__Active__c = true;
        oBillingPref.Apttus_Config2__BillingCycleStart__c = 'Billing Day of Month';
        oBillingPref.Apttus_Config2__BillingInterval__c = 'Anytime';
        oBillingPref.Apttus_Config2__CalendarCycleStart__c = 'January';
        oBillingPref.Apttus_Config2__TaxLevel__c = 'Product';
        oBillingPref.Apttus_Config2__InvoiceDeliveryMethod__c = 'Email';
        oBillingPref.Apttus_Config2__InvoiceOutputFormat__c = 'PDF';
        insert oBillingPref;
        
        Account acc = new Account();
        acc.Name = 'accNameDM';
        acc.Phone = '+31302979111';
        insert acc;
        
        Opportunity opp = new Opportunity();
        opp.Name = 'oppNameDM';
        opp.Amount = 1000;
        opp.StageName = 'Proposal/Price Quote';
        opp.CloseDate = system.today() + 20;
        opp.AccountId = acc.id;
        insert opp;
        
        Contact contact = new Contact();
        contact.AccountId = acc.id;
        contact.MobilePhone = '+31302979111';
        contact.LastName = acc.Name;
        contact.Email = 'DataMigContact@qp1.org';
        insert contact;
        
        Apttus_Config2__PriceList__c price = new Apttus_Config2__PriceList__c();
        price.Apttus_Config2__Active__c = true;
        price.Name = 'DMPriceList';
        price.Apttus_Config2__EffectiveDate__c = System.today().addYears(-1);
        price.Apttus_Config2__ExpirationDate__c = System.today().addYears(2);
        price.APTS_SalesOrg__c = 'Netherlands';
        insert price;
        
        Apttus__APTS_Agreement__c oAgreement = new Apttus__APTS_Agreement__c();
        oAgreement.Name = 'Agreement';
        oAgreement.Apttus__Primary_Contact__c = contact.id;
        oAgreement.Apttus__Agreement_Category__c = 'Standard';
        oAgreement.Apttus_CMConfig__PriceListId__c = price.id;
        oAgreement.Apttus_CMConfig__PricingDate__c = System.Today();
        oAgreement.Apttus__Account__c = acc.id;
        oAgreement.APTS_SourceSystem__c = 'NL';
        insert oAgreement;

        List<Apttus_Config2__AssetLineItem__c> assetLineItems = new List<Apttus_Config2__AssetLineItem__c>();
        Apttus_Config2__AssetLineItem__c assetLineItem = new Apttus_Config2__AssetLineItem__c();
        assetLineItem.Apttus_Config2__PriceType__c = 'Recurring';
        assetLineItem.Apttus_Config2__LineType__c = 'Option';
        assetLineItem.Apttus_Config2__ChargeType__c = 'Service Fee';
        assetLineItem.Apttus_CMConfig__AgreementId__c = oAgreement.id; 
        assetLineItem.Apttus_Config2__ItemSequence__c = 1;
        assetLineItem.Apttus_Config2__Quantity__c = 1;
        assetLineItem.Apttus_Config2__BaseExtendedPrice__c = 100;
        assetLineItem.Apttus_Config2__SellingTerm__c =1;
        assetLineItem.Apttus_Config2__BillingPreferenceId__c = oBillingPref.id;
        assetLineItem.APTS_MigrationDate__c = System.Today();
        insert assetLineItem; 
        
        Apttus_Config2__AssetLineItem__c assetLineItem1 = new Apttus_Config2__AssetLineItem__c();
        assetLineItem1.Apttus_Config2__PriceType__c = 'Recurring';
        assetLineItem1.Apttus_Config2__LineType__c = 'Product/Service';
        assetLineItem1.Apttus_Config2__IsOptionRollupLine__c = True;
        assetLineItem1.Apttus_Config2__ChargeType__c = 'Sales Price';
        assetLineItem1.Apttus_CMConfig__AgreementId__c = oAgreement.id; 
        assetLineItem1.Apttus_Config2__ItemSequence__c = 2;
        assetLineItem1.Apttus_Config2__Quantity__c = 2;
        assetLineItem1.Apttus_Config2__BaseExtendedPrice__c = 200;
        assetLineItem1.Apttus_Config2__SellingTerm__c =1;
        assetLineItem1.Apttus_Config2__BillingPreferenceId__c = oBillingPref.id;
        assetLineItem1.APTS_MigrationDate__c = System.Today();
        insert assetLineItem1; 
        
        Apttus_Config2__AssetLineItem__c assetLineItem2 = new Apttus_Config2__AssetLineItem__c();
        assetLineItem2.Apttus_Config2__PriceType__c = 'Recurring';
        assetLineItem2.Apttus_Config2__LineType__c = 'Product/Service';
        assetLineItem2.Apttus_CMConfig__AgreementId__c = oAgreement.id; 
        assetLineItem2.Apttus_Config2__ItemSequence__c = 3;
        assetLineItem2.Apttus_Config2__Quantity__c = 3;
        assetLineItem2.Apttus_Config2__BaseExtendedPrice__c = 300;
        assetLineItem2.Apttus_Config2__SellingTerm__c =1;
        assetLineItem2.Apttus_Config2__BillingPreferenceId__c = oBillingPref.id;
        assetLineItem2.APTS_MigrationDate__c = System.Today();
        insert assetLineItem2; 
    }
    
     public static testmethod void testBatch() {
         //User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        //System.runAs(usr) {
            dataSetup();      
            Test.startTest();
            Database.executeBatch(new APTS_AssetRollupLineCreation(),1);
            Test.stopTest();
      // }    
    }
    
    private static testMethod void test_modifyTriggers() {
        Test.startTest();
        
        TriggerSettings__c objTriggerSettings = new TriggerSettings__c();
        objTriggerSettings.APTS_Order_Trigger__c = false;
        objTriggerSettings.APTS_OrderLineItemTrigger__c = false;
        insert objTriggerSettings;
        
        Set<string> setTriggers = new Set<string>(); 
        setTriggers.add('APTS_Order_Trigger__c');
        String action = 'Activate';
        APTS_BillingSchedulesLoadBatchHelper.modifyTriggers(setTriggers,action);
        APTS_BillingSchedulesLoadBatchHelper.createBatchErrorObject('Test',null,'Test');
        Test.stopTest();
    }
    
}