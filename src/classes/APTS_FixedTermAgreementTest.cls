@isTest
public class APTS_FixedTermAgreementTest
{
    
    @TestSetup
    private static void createTestData()
    {
        //Create Price Lsit - Begin
        Apttus_Config2__PriceList__c priceList = APTS_TestUtils.createPriceList();
        Database.Insert(priceList);
        //Create Price Lsit - End
        
        //Create Billing Preference - Begin
        Apttus_Config2__BillingPreference__c billingPreference = APTS_TestUtils.createBillingPrefrence('June');
        billingPreference.name='Test Preference';
        billingPreference.APTS_Invoice_Delivery_Preference__c ='P001';
        billingPreference.APTS_Invoice_Type__c ='Single Invoice';
        billingPreference.APTS_Billing_Rule_Contract__c = 'Bill in Advance';
        Database.Insert(billingPreference);
        //Create Billing Preference - End
        
        //Create Payment Term - Begin 
        APTS_Payment_Method__c paymentMethod = APTS_TestUtils.paymentMethod();
        Database.Insert(paymentMethod);
        // Create Payment Term - End
        
        //Create Payment Method - Begin
        Apttus_Config2__PaymentTerm__c paymentTerm = APTS_TestUtils.paymentTerm();
        paymentTerm.Apttus_Config2__Sequence__c = 5;
        Database.Insert(paymentTerm);
        //Create Payment Method - End
        
        //Create Account - Begin
        Account account = APTS_TestUtils.createGrandParentAccount();
        account.name= 'Test';
        //Update Billing Key Fields
        account.Apttus_Config2__BillingPreferenceId__c = billingPreference.Id;
        account.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        account.APTS_Payment_Method__c = paymentMethod.Id;
        Database.Insert(account);
        
        
        Account account1 = APTS_TestUtils.createGrandParentAccount();
        account1.Name = 'Test1';
        //Update Billing Key Fields
        account1.Apttus_Config2__BillingPreferenceId__c = billingPreference.Id;
        account1.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        account1.APTS_Payment_Method__c = paymentMethod.Id;
        Database.Insert(account1);
        //Create Account - End
        
        Product2 product = APTS_TestUtils.createProduct('Dummy High Tax', '26940998', 'Coffee');
        Database.Insert(product);
        
        Product2 product2 = APTS_TestUtils.createProduct('Dummy Low Tax', '26940992', 'Coffee');
        Database.Insert(product2); 
        
        Apttus_Config2__ClassificationName__c category = APTS_TestUtils.createCategory();
        Database.Insert(category);
        
        Apttus_Config2__ClassificationHierarchy__c categoryHierarchy = 
            APTS_TestUtils.createCategoryHierarchy(category.Id);
        Database.Insert(categoryHierarchy);
        
        Apttus_Config2__ClassificationHierarchy__c subCategoryHierarchy = 
            APTS_TestUtils.createSubCategory(category.Id, categoryHierarchy.Id);
        Database.Insert(subCategoryHierarchy);
        
        Apttus_Config2__ClassificationHierarchy__c subSubCategoryHierarchy = 
            APTS_TestUtils.createSubCategory(category.Id, categoryHierarchy.Id);
        Database.Insert(subSubCategoryHierarchy);      
        
        Apttus_Config2__ProductClassification__c productClassification = 
            APTS_TestUtils.createProductClassification(subCategoryHierarchy.Id, product.id);
        Database.Insert(productClassification);
        
        Apttus_Config2__ProductClassification__c productClassification2 = 
            APTS_TestUtils.createProductClassification(subCategoryHierarchy.Id, product2.id);
        Database.Insert(productClassification2);
        
        
        APTS_Fixed_Term_Dummy_Product__c dummyProduct = new APTS_Fixed_Term_Dummy_Product__c(name= 'High tax',
                                                                                             Product_Name__c='Dummy High Tax',Product_Type__c='Machine');
        Database.Insert(dummyProduct);
        
        
        
        
        //Get RecordType ID 
        Id RecId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
        // Create Agreement
        Apttus__APTS_Agreement__c   agreementWithBillTo = new Apttus__APTS_Agreement__c(Apttus__Account__c = account.Id, 
                                                                                        Name = 'AgreementWithBillTo',
                                                                                        RecordTypeId = RecId,
                                                                                        APTS_Fixed_Term_Type__c = 'Fixed Costs and Ingredients',
                                                                                        Apttus__Contract_Start_Date__c = Date.today(),
                                                                                        Apttus__Contract_End_Date__c = Date.today()+365, 
                                                                                        Apttus_CMConfig__PriceListId__c = priceList.id,
                                                                                        Apttus__Status_Category__c = 'In Signatures',
                                                                                        Apttus__Status__c = 'Ready for Signatures',
                                                                                        Apttus__Subtype__c ='Default',
                                                                                        APTS_Bill_to_Party_Ingredients__c = account.Id,
                                                                                        APTS_Bill_to_Party_MachServ__c = account.Id);
        Database.Insert(agreementWithBillTo);
        // Associate Billing setting
        APTS_Billing_Settings__c billsetting = APTS_TestUtils.createBillingSetting(agreementWithBillTo.Id,agreementWithBillTo.APTS_Bill_to_Party_Ingredients__c,billingPreference.Id,paymentMethod.Id,paymentTerm.Id);
        billsetting.APTS_Agreement_Billing_Type__c ='Ingredients';
        billsetting.APTS_Invoice_Delivery_Preference__c = 'P001';
        Database.Insert(billsetting);
        APTS_Billing_Settings__c billsetting1 = APTS_TestUtils.createBillingSetting(agreementWithBillTo.Id,agreementWithBillTo.APTS_Bill_to_Party_MachServ__c,billingPreference.Id,paymentMethod.Id,paymentTerm.Id);
        billsetting1.APTS_Agreement_Billing_Type__c ='Machine';
        billsetting1.APTS_Invoice_Delivery_Preference__c = 'P001';
        Database.Insert(billsetting1);
        
        
        Apttus__AgreementLineItem__c agreementLineItem = new Apttus__AgreementLineItem__c();
        agreementLineItem.Apttus__ProductId__c = product.Id;
        agreementLineItem.Apttus__AgreementId__c = agreementWithBillTo.Id;
        agreementLineItem.Apttus__Quantity__c = 1;
        Database.Insert(agreementLineItem);
        
        Apttus__AgreementLineItem__c agreementLineItem2 = new Apttus__AgreementLineItem__c();
        agreementLineItem2.Apttus__ProductId__c = product2.Id;
        agreementLineItem2.Apttus__AgreementId__c = agreementWithBillTo.Id;
        agreementLineItem2.Apttus__Quantity__c = 1;
        Database.Insert(agreementLineItem2);
        
        TriggerSettings__c settings = TriggerSettings__c.getOrgDefaults();
        settings.Agreement__c = true;
        Database.insert(settings);

        ValidationRulesSettings__c settings1 = ValidationRulesSettings__c.getOrgDefaults();
        settings1.APTS_AgreementValidationRules__c = false;
        Database.insert(settings1);
        
    }
    
    
    public static testMethod void fixedTermAgreementActivationTest()
    {
        Apttus__APTS_Agreement__c testAgreement = [SELECT Id,Name,APTS_Fixed_Term_Type__c,
                                                   Apttus__Contract_Start_Date__c,Apttus_CMConfig__PriceListId__c,
                                                   APTS_Bill_to_Party_Ingredients__c,APTS_Bill_to_Party_MachServ__c,
                                                   Apttus__Contract_End_Date__c, APTS_Country__c,recordtype.name,
                                                   Apttus__Status_Category__c,Apttus__Status__c, Apttus__Account__c
                                                   FROM Apttus__APTS_Agreement__c LIMIT 1];
        
        
        
        System.assertnotequals(null,testAgreement.Id);
        Apttus__APTS_Agreement__c testAgreementOld = [SELECT Id,Name,APTS_Fixed_Term_Type__c,Apttus__Contract_Start_Date__c,Apttus_CMConfig__PriceListId__c,APTS_Bill_to_Party_Ingredients__c,APTS_Bill_to_Party_MachServ__c,Apttus__Contract_End_Date__c, APTS_Country__c,recordtype.name,Apttus__Status_Category__c,Apttus__Status__c FROM Apttus__APTS_Agreement__c LIMIT 1];
        
        Map<Id, Apttus__APTS_Agreement__c> mapoldAgreement = new Map<Id, Apttus__APTS_Agreement__c>();
        
        mapoldAgreement.put(testAgreementOld.Id, testAgreementOld);                                           
        
        Test.startTest();
        testAgreement.Apttus__Status_Category__c = 'In Effect';
        testAgreement.Apttus__Status__c = 'Activated';
        update testAgreement;
        
        //create order
        Apttus_Config2__Order__c createOrder = new Apttus_Config2__Order__c();
        //createOrder.APTS_SAP_OrderType__c = 'XD01';
        createOrder.APTS_Requested_Delivery_Date__c = System.Today();
        createOrder.Apttus_Config2__BillToAccountId__c = testAgreement.Apttus__Account__c;
        createOrder.APTS_Bill_to_Party_Machines_Services__c = testAgreement.Apttus__Account__c;
        INSERT createOrder;
        
        
        Map<Id, Apttus__APTS_Agreement__c> mapAgreement = new Map<Id, Apttus__APTS_Agreement__c>();
        
        mapAgreement.put(testAgreement.Id, testAgreement);
        System.assertnotequals(null,testAgreement.Id);
        
        APTS_FixedTermAgreement.fixedTermAgreementActivation(mapAgreement, mapoldAgreement);
        APTS_FixedTermAgreement.activateOrder(createOrder);
        
        Set<Id> agreementIds = new Map<Id, Apttus__APTS_Agreement__c>([SELECT Id FROM Apttus__APTS_Agreement__c]).keySet();
        
        List<Apttus_Config2__Order__c> orderList = [Select Id,Apttus_Config2__Status__c,Apttus_CMConfig__AgreementId__c 
                                                    FROM Apttus_Config2__Order__c 
                                                    WHERE Apttus_CMConfig__AgreementId__c IN :agreementIds 
                                                    LIMIT 50000];
        
        Test.stopTest();  
    }
}