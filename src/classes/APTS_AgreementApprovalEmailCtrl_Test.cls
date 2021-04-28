@isTest
public class APTS_AgreementApprovalEmailCtrl_Test{
        
    @testSetup
    private static void testDataSetup() {
        Account acc = APTS_TestClassUtils.createGrandParentAccount();
        insert acc;
        
        Product2 product =APTS_TestClassUtils.createProduct(true,'Piazza DOro Estremo Bonen 1000 Gram','26940998','Espresso');
        product.Family = 'SAP_01';
        Update product;
        
        Apttus_Config2__PriceList__c priceList = APTS_TestClassUtils.createPriceList(false);
        priceList.APTS_SalesOrg__c = 'SAP_0033';
        insert priceList;
        
        APTS_Payment_Method__c paymentMethod = APTS_TestUtils.paymentMethod();
        paymentMethod.APTS_Ext_ID__c = 'SAP_02024';
        Database.Insert(paymentMethod);
        
        Apttus_Config2__PaymentTerm__c paymentTerm = APTS_TestUtils.paymentTerm();
        paymentTerm.Apttus_Config2__Sequence__c = 5;
        paymentTerm.APTS_Ext_ID__c ='SAP_0211';
        Database.Insert(paymentTerm);
        
        Apttus_Config2__PriceListItem__c priceListItem = APTS_TestClassUtils.createPriceListItem(true,priceList.id,product.id);
        
        Apttus__APTS_Agreement__c agreement = APTS_TestClassUtils.createAgreement(true, priceList.Id, acc.Id);
        
        Apttus_Config2__ProductConfiguration__c agreementCart = 
        APTS_TestClassUtils.createProductConfigurationAgreement(false, agreement.id, priceList.id);
        agreementCart.Apttus_Config2__BusinessObjectRefId__c = agreement.Id;
        insert agreementCart;

        Apttus_Config2__LineItem__c lineItem1 = APTS_TestClassUtils.createConfigLineItem(false,agreementCart.id, null, 1, true, 2, '', product.id, false, null,product.id, null, '', 2.3, false, '', 1, priceList.id, priceListItem.Id, '', '', 'Sales Price', '',false, false, 22.00, 24.00, '', 34.00, 23.00, 33.50, '');
        lineItem1.Apttus_Config2__IsPrimaryLine__c = true;
        lineItem1.Apttus_Config2__LineType__c = system.label.APTS_ProductService;
        lineItem1.Apttus_Config2__ClassificationHierarchy__c = 'Coffee | Beans | Beans|Douwe Egberts';
        //lineItem1.APTS_Type_of_Contract__c = 'Trial';
        insert lineItem1;
        
        Apttus__AgreementLineItem__c agli =APTS_TestDataFactory.createAgreementLineItem(product.Id,agreement.Id,acc.Id,priceListItem.Id);
        agli.Apttus_CMConfig__DerivedFromId__c = lineItem1.id;
        insert agli;
        
        APTS_Billing_Settings__c billsetting = APTS_TestUtils.createBillingSetting(agreement.Id,acc.id,null,paymentMethod.Id,paymentTerm.Id);
        billsetting.APTS_Agreement_Billing_Type__c ='Machine';
        billsetting.APTS_Invoice_Delivery_Preference__c='P001';
        billsetting.APTS_Billing_Rule_Contract__c = 'Bill in Arrears';
        Database.Insert(billsetting);
    }
    static testMethod void APTS_AgreementApprovalEmailCtrl_method(){
        Apttus__APTS_Agreement__c agreement = [Select Id,Name from Apttus__APTS_Agreement__c Limit 1];
        List<Apttus__AgreementLineItem__c> agliList = [select id,name,Apttus__ProductId__r.Name,Apttus__Quantity__c,APTS_Type_of_Contract__c,Apttus_CMConfig__ClassificationHierarchy__c,Apttus__AgreementId__r.Apttus__Account__r.Name,Apttus__ProductId__r.Family,Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Number_of_weeks__c  from Apttus__AgreementLineItem__c where Apttus__AgreementId__c=: agreement.Id];
        
        test.startTest();
            APTS_AgreementApprovalEmailCtrl agrmaprl = new APTS_AgreementApprovalEmailCtrl();
            agrmaprl.getagreementId();
            agrmaprl.setagreementId(agreement.Id);
            agrmaprl.agreementLineItems();
            agrmaprl.getagreementDetails();
            agrmaprl.getbShowIngredient();
            agrmaprl.getKPIRecord();
            agrmaprl.getIngredientCategory();
            string pmedstring = agrmaprl.getPaymentMethods();
            agrmaprl.getWithIncentives();
        test.stopTest();
        
        system.assertNotEquals(null, agrmaprl.listAgreementLineItems);
        system.assertNotEquals(null, pmedstring);
    }
    
}