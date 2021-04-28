/**
* Class Name : APTS_BillingSettingTriggerHandlerTest 
* Description :  Test class for APTS_BillingSettingTriggerHandler
* Author : Juhi Rawal (Apttus)
* Date Created : 8th June,2018
**/
@isTest
public class APTS_BillingSettingTriggerHandlerTest{
 
    private static testMethod void updateAgrFieldTestMethod() {
        TriggerSettings__c settings = new TriggerSettings__c();
        settings.APTS_BillingSettingTrigger__c = true;
        insert settings;

        Apttus_Config2__PriceList__c priceList = APTS_TestUtils.createPriceList();
        Database.Insert(priceList);
        Apttus_Config2__BillingPreference__c billingPreference = APTS_TestUtils.createBillingPrefrence('June');
        billingPreference.name='Test Preference';
        billingPreference.APTS_Invoice_Delivery_Preference__c ='P001';
        billingPreference.APTS_Invoice_Type__c ='Single Invoice';
        billingPreference.APTS_Billing_Rule_Contract__c = 'Bill in Advance';
        Database.Insert(billingPreference);
        
        APTS_Payment_Method__c paymentMethod = APTS_TestUtils.paymentMethod();
        Database.Insert(paymentMethod);
        
        Apttus_Config2__PaymentTerm__c paymentTerm = APTS_TestUtils.paymentTerm();
        paymentTerm.Apttus_Config2__Sequence__c = 5;
        paymentTerm.APTS_Ext_ID__c ='SAP_0211';
        Database.Insert(paymentTerm);

        Apttus_Config2__PaymentTerm__c paymentTerm1 = APTS_TestUtils.paymentTerm();
        paymentTerm1.Apttus_Config2__Sequence__c = 4; 
        paymentTerm1.Apttus_Config2__Value__c = 0;
        paymentTerm1.APTS_Ext_ID__c ='SAP_0202I';
        Database.Insert(paymentTerm1);

        Account account = APTS_TestUtils.createGrandParentAccount();
        account.name= 'Test';
        //Update Billing Key Fields
        account.Apttus_Config2__BillingPreferenceId__c = billingPreference.Id;
        account.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        account.APTS_Payment_Method__c = paymentMethod.Id;
        account.Creditworthiness_Flag__c = 'Red';
        Database.Insert(account);

        Id RecId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
        Apttus__APTS_Agreement__c   agreementWithBillTo = new Apttus__APTS_Agreement__c(Apttus__Account__c = account.Id, 
                                                                                Name = 'AgreementWithBillTo',
                                                                                RecordTypeId = RecId,
                                                                                Apttus__Contract_Start_Date__c = Date.today(),
                                                                                Apttus__Contract_End_Date__c = Date.today()+365, 
                                                                                Apttus_CMConfig__PriceListId__c = priceList.id,
                                                                                Apttus__Subtype__c ='Default',
                                                                                APTS_Bill_to_Party_Ingredients__c = account.Id,
                                                                                APTS_Bill_to_Party_MachServ__c = account.Id);
        Database.Insert(agreementWithBillTo);

        Test.startTest();  
            APTS_Billing_Settings__c billsetting = APTS_TestUtils.createBillingSetting(agreementWithBillTo.Id,agreementWithBillTo.APTS_Bill_to_Party_Ingredients__c,billingPreference.Id,paymentMethod.Id,paymentTerm.Id);
            billsetting.APTS_Agreement_Billing_Type__c ='Machine';
            billsetting.APTS_Invoice_Delivery_Preference__c='P001';
            billsetting.APTS_Billing_Rule_Contract__c = 'Bill in Arrears';
            Database.Insert(billsetting);

            APTS_Billing_Settings__c billsetting1 = APTS_TestUtils.createBillingSetting(agreementWithBillTo.Id,agreementWithBillTo.APTS_Bill_to_Party_MachServ__c,billingPreference.Id,paymentMethod.Id,paymentTerm.Id);
            billsetting1.APTS_Agreement_Billing_Type__c ='Ingredients';
            billsetting1.APTS_Invoice_Delivery_Preference__c='P001';
            Database.Insert(billsetting1);          
            
            APTS_Billing_Settings__c oBill = [select id from APTS_Billing_Settings__c where APTS_Billing_Rule_Contract__c='Bill in Arrears'];
            oBill.APTS_Billing_Rule_Contract__c = 'Bill in Advance';
            oBill.APTS_Payment_Term_Setting__c = paymentTerm1.Id;
            Database.Update(oBill);
            Database.Delete([select id from APTS_Billing_Settings__c]);
        Test.stopTest();
    }
}