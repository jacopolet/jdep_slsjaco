/*************************************************************
@Name: APTS_SubmitTriangularOrderQueueableTest
@Author: Rajesh Patel
@CreateDate: 23-01-2019
@Description: Test Class APTS_SubmitTriangularOrderQueueable 
@UsedBy: APTS_SubmitTriangularOrderQueueable
******************************************************************/
@isTest
private with sharing class APTS_SubmitTriangularOrderQueueableTest {

private static final String ACCOUNT_NAME = 'JDETestAccount';
private static final String PRICELIST_NAME = 'JDETest Price List';
private static final String CONTACT_NUMBER = '1010101011';
private static final String ACTIVATED = System.Label.APTS_Activated;
private static final String IN_EFFECT = System.Label.APTS_In_Effect;
private static final String STANDARD_DEAL = System.Label.APTS_Standard_Deal;


@isTest static void test_SubmitTriangularOrderQueueable() {

        Account oAccount = APTS_TestDataFactory.createAccount(ACCOUNT_NAME);
        oAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
        Database.insert(oAccount, FALSE);
        System.debug('Account Details : '+oAccount);

        Contact oContact = APTS_TestDataFactory.createContact(oAccount, CONTACT_NUMBER);
        Database.insert(oContact, FALSE);

        Apttus_Config2__PriceList__c oPricelist = APTS_TestDataFactory.createPriceList(PRICELIST_NAME);
        Database.insert(oPricelist, FALSE);

        Apttus__APTS_Agreement__c oAgreement = APTS_TestDataFactory.createAgreement(oContact.Id, oPriceList.Id, oAccount.Id, STANDARD_DEAL, 'Agreement');
            oAgreement.Apttus__Status_Category__c = IN_EFFECT;
            oAgreement.Apttus__Status__c = ACTIVATED;
            oAgreement.Apttus__Contract_End_Date__c = Date.Today().addDays(365);
            oAgreement.APTS_Bill_to_Party_Ingredients__c = oAgreement.Apttus__Account__c;
            oAgreement.APTS_Bill_to_Party_MachServ__c = oAgreement.Apttus__Account__c;
            oAgreement.APTS_Payer_Ingredients__c = oAgreement.Apttus__Account__c;
            oAgreement.APTS_Payer_Machines_Services__c = oAgreement.Apttus__Account__c;
            oAgreement.Apttus__Auto_Renewal__c = true;
            Database.insert(oAgreement);


        List<Apttus_Config2__Order__c> orders = new List<Apttus_Config2__Order__c>();
        Apttus_Config2__Order__c order1 = APTS_TestDataFactory.createOrder(oAccount.Id, oPricelist.Id, oContact.Id);
        order1.Apttus_CMConfig__AgreementId__c = oAgreement.Id;
        order1.APTS_Status__c = 'Draft';
        orders.add(order1);
        Database.insert(orders, FALSE);
        System.debug('Order details' +orders);

        List<Integration_Log__c> intLog = new List<Integration_Log__c>();
        Integration_Log__c iLog = new Integration_Log__c();
        iLog.Object_Id__c = orders[0].id;
        iLog.Object__c = 'Order';
        iLog.Integration_Status__c = INT_Constants.INITIAL;
        iLog.Account__c = orders[0].Apttus_Config2__SoldToAccountId__c;
        iLog.Order__c = orders[0].id;
        intLog.add(iLog);
        Database.insert(intLog,FALSE);



        test.startTest();            
           if (!orders.isEmpty()) {
            System.enqueueJob(new APTS_SubmitTriangularOrderQueueable(orders));
             }
            
        test.stopTest();
}

}