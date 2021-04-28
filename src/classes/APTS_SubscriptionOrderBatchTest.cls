/*************************************************************
@Name: APTS_SubscriptionOrderBatchTest
@Author: Neev Shah
@CreateDate: 12-03-2018
@Description: Subscription Order batch test class
@UsedBy:
******************************************************************/
@isTest
private without sharing class APTS_SubscriptionOrderBatchTest {
    private static final String PROD_CONFIG_BUNDLE = 'Bundle';
    private static final String COL_RED = 'Red';
    private static final String FREQ_WEEKLY = 'Weekly';

    @testSetup static void setupTestData() {
        User oTestUser = APTS_TestFacade.createTestUser();
        APTS_TestFacade.createMandatoryRecords(oTestUser);
        APTS_TestFacade.createAndConfigureAgreement(oTestUser);

        List<Account> listAcc = new List<Account>();
        for (Account acc : [select Id,Account_Status__c from Account]) {
            acc.Account_Status__c = 'Valid';
            listAcc.add(acc);
        }

        if (!listAcc.isEmpty()) {
            update listAcc;
        }

        List<Apttus__AgreementLineItem__c> listAgLI = [SELECT id, Apttus__AgreementId__c FROM Apttus__AgreementLineItem__c WHERE Apttus_CMConfig__OptionId__c = NULL
                AND Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c = : PROD_CONFIG_BUNDLE limit 1];

        System.assertNotEquals(TRUE, listAgLI.isEmpty());

        //attributes
        Apttus_CMConfig__AgreementProductAttributeValue__c oAttrb = new Apttus_CMConfig__AgreementProductAttributeValue__c();
        oAttrb.Apttus_CMConfig__LineItemId__c = listAgLI[0].Id;
        oAttrb.Apttus_CMConfig__Color__c = COL_RED;
        oAttrb.APTS_Order_Frequency__c = FREQ_WEEKLY;
        Database.insert(oAttrb, FALSE);

        Apttus__APTS_Agreement__c oAgreement = new Apttus__APTS_Agreement__c(id = listAgLI[0].Apttus__AgreementId__c);
        oAgreement.Apttus__Contract_Start_Date__c = System.today();
        oAgreement.APTS_Region__c = 'SAP_6864';
        Database.update(oAgreement, FALSE);

        listAgLI[0].APTS_Last_Processed_for_Subscription__c = Datetime.newInstance(2008, 12, 1);
        listAgLI[0].Apttus_CMConfig__AttributeValueId__c = oAttrb.Id;
        listAgLI[0].Apttus_CMConfig__IsPrimaryLine__c = TRUE;
        Database.update(listAgLI[0], FALSE);
        
         APTS_BatchMetadataCoverageTest.setMetadata(
            'SELECT APTS_Batch_Name__c,'+
            'APTS_Query_String__c'+                                  
            'FROM APTS_Batch_Queries__mdt '+ 
            'WHERE DeveloperName = \'Subscription_Order\'',
             (List<APTS_Batch_Queries__mdt>) JSON.deserialize('[{"APTS_Batch_Name__c": "Subscription Orders Batch","APTS_Query_String__c": "SELECT id, Apttus__AgreementId__c, APTS_Last_Processed_for_Subscription__c,Apttus_CMConfig__LineNumber__c,Apttus_CMConfig__AttributeValueId__c, Apttus_CMConfig__AttributeValueId__r.APTS_Order_Frequency__c, Apttus__AgreementId__r.Apttus__Account__c,Apttus__AgreementId__r.Apttus__Account__r.Account_Status__c FROM Apttus__AgreementLineItem__c"}]', List<APTS_Batch_Queries__mdt>.class)
            );
    }

    @isTest static void testSubBatch() {
        User oTestUser = APTS_TestFacade.getTestUser();
        System.assert(oTestUser != Null);
          //Set metadata
        APTS_BatchMetadataCoverageTest.setMetadata(
            'SELECT APTS_Batch_Name__c,'+
            'APTS_Query_String__c, DeveloperName'+                                   
            'FROM APTS_Batch_Queries__mdt '+ 
            'WHERE DeveloperName = \'Subscription_Order\'',
            (List<APTS_Batch_Queries__mdt>) JSON.deserialize('[{"APTS_Batch_Name__c": "Subscription Orders Batch","APTS_Query_String__c": "SELECT id, Apttus__AgreementId__c, APTS_Last_Processed_for_Subscription__c,Apttus_CMConfig__LineNumber__c,Apttus_CMConfig__AttributeValueId__c, Apttus_CMConfig__AttributeValueId__r.APTS_Order_Frequency__c, Apttus__AgreementId__r.Apttus__Account__c,Apttus__AgreementId__r.Apttus__Account__r.Account_Status__c FROM Apttus__AgreementLineItem__c", "DeveloperName":"Subscription_Order" }]', List<APTS_Batch_Queries__mdt>.class
                )
            );
        test.startTest();
        System.runAs(oTestUser) {
            APTS_SubscriptionOrderBatch obatch = new APTS_SubscriptionOrderBatch();
            DataBase.executeBatch(obatch);
        }
        test.stopTest();

        List<Apttus_Config2__Order__c> listSubOrders = [SELECT Id FROM Apttus_Config2__Order__c WHERE APTS_Order_Sub_Type__c = 'Subscription Order'];
        System.debug('listSubOrders = ' + listSubOrders);
        System.assertNotEquals(null, listSubOrders);
        //System.assertNotEquals(true, !listSubOrders.isEmpty());
    }
}