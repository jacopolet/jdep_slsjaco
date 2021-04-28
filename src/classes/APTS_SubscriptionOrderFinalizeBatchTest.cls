/*************************************************************
@Name: APTS_SubscriptionOrderFinalizeBatchTest
@Author: Neev Shah
@CreateDate: 12-03-2018
@Description: Subscription Order test class
@UsedBy:
******************************************************************/

@isTest
private class APTS_SubscriptionOrderFinalizeBatchTest {
  private static final String PROD_CONFIG_BUNDLE = 'Bundle';
  private static final String COL_RED = 'Red';
  private static final String FREQ_WEEKLY = 'Weekly';

  @testSetup static void setupTestData() {
    User oTestUser = APTS_TestFacade.createTestUser();
    APTS_TestFacade.createMandatoryRecords(oTestUser);
    APTS_TestFacade.createAndConfigureAgreement(oTestUser);

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
    Database.update(oAgreement, FALSE);

    listAgLI[0].APTS_Last_Processed_for_Subscription__c = Datetime.newInstance(2008, 12, 1);
    listAgLI[0].Apttus_CMConfig__AttributeValueId__c = oAttrb.Id;
    listAgLI[0].Apttus_CMConfig__IsPrimaryLine__c = TRUE;
    Database.update(listAgLI[0], FALSE);
  }

  @isTest static void testCreateSubscriptionOrder() {
    User oTestUser = APTS_TestFacade.getTestUser();
    System.assert(oTestUser != Null);
    test.startTest();
    System.runAs(oTestUser) {
      APTS_SubscriptionOrderBatch obatch = new APTS_SubscriptionOrderBatch();
      DataBase.executeBatch(obatch);
    }
    test.stopTest();
  }
}