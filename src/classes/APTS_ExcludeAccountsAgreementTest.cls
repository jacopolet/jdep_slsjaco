@isTest
private class APTS_ExcludeAccountsAgreementTest {
    
    private static Apttus__APTS_Agreement__c tstAggr;
    private static Apttus__AgreementLineItem__c tstALI;
    private static Apttus_CMConfig__AgreementAdjustmentLineItem__c tstAALI;

    static{
        Account tstGrandParentAcc = APTS_TestUtils.createGrandParentAccount();
        insert tstGrandParentAcc;

        Account tstParentAcc = APTS_TestUtils.createParentAccount(tstGrandParentAcc);
        insert tstParentAcc;

        Account tstChildAcc = APTS_TestUtils.createChildAccount(tstParentAcc);
        insert tstChildAcc;

        Account tstAcc = APTS_TestUtils.createOrganisationproduct();
        insert tstAcc;

        tstAggr = new Apttus__APTS_Agreement__c();
        //tstAggr.Apttus__Contract_End_Date__c = Date.today().addDays(-1);
        tstAggr.Apttus__Account__c = tstGrandParentAcc.Id;
        insert tstAggr;

        tstALI = new Apttus__AgreementLineItem__c();
        tstALI.Apttus__AgreementId__c = tstAggr.Id;
        insert tstALI;

        tstAALI = new Apttus_CMConfig__AgreementAdjustmentLineItem__c();
        tstAALI.Apttus_CMConfig__LineItemId__c = tstALI.Id;
        tstAALI.Apttus_CMConfig__LineNumber__c = 1;
        insert tstAALI;
        
    }

    @isTest static void testAgreementExclusion() {
        Test.startTest();
        List<APTS_ExcludeAccountsAgreementController.ChildAccountWrapper> lstChild = APTS_ExcludeAccountsAgreementController.getExclusionData(tstAggr.Id);
        String wrapperRec = JSON.serialize(lstChild);
        wrapperRec = wrapperRec.replace('false', 'true');
        APTS_ExcludeAccountsAgreementController.excludeAgreement(wrapperRec, tstAggr.Id);
        Test.stopTest();
        
    }

    @isTest static void testALIExclusion(){
        Test.startTest();
        List<APTS_ExcludeAccountsAgreementController.ChildAccountWrapper> lstChild = APTS_ExcludeAccountsAgreementController.getExclusionData(tstALI.Id);
        String wrapperRec = JSON.serialize(lstChild);
        wrapperRec = wrapperRec.replace('false', 'true');
        APTS_ExcludeAccountsAgreementController.excludeAgreement(wrapperRec, tstALI.Id);
        Test.stopTest();
        Apttus__AgreementLineItem__c oALI = [SELECT Id, Apttus__AgreementId__c FROM Apttus__AgreementLineItem__c WHERE Id = :tstALI.Id LIMIT 1];
        Id aggrId = oALI.Apttus__AgreementId__c;       
        Apttus__APTS_Agreement__c oAggr = [SELECT Id, APTS_ExclusionRelatedDetails__c FROM Apttus__APTS_Agreement__c WHERE Id = :aggrId LIMIT 1];
        System.assertEquals( 'Categories/Products Exclusion',oAggr.APTS_ExclusionRelatedDetails__c);
        System.assertEquals(oALI.Apttus__AgreementId__c,oAggr.Id);
    }

    @isTest static void testAALIExclusion(){
        Test.startTest();
        List<APTS_ExcludeAccountsAgreementController.ChildAccountWrapper> lstChild = APTS_ExcludeAccountsAgreementController.getExclusionData(tstAALI.Id);
        String wrapperRec = JSON.serialize(lstChild);
        wrapperRec = wrapperRec.replace('false', 'true');
        APTS_ExcludeAccountsAgreementController.excludeAgreement(wrapperRec, tstAALI.Id);
        Test.stopTest();
         
        Apttus_CMConfig__AgreementAdjustmentLineItem__c oAALI = [SELECT Apttus_CMConfig__LineItemId__c FROM Apttus_CMConfig__AgreementAdjustmentLineItem__c WHERE Id = :tstAALI.Id LIMIT 1];
        Apttus__AgreementLineItem__c oALI = [SELECT Id, Apttus__AgreementId__c FROM Apttus__AgreementLineItem__c WHERE Id = :oAALI.Apttus_CMConfig__LineItemId__c LIMIT 1]; 
        Id aggrId = oALI.Apttus__AgreementId__c;
        Apttus__APTS_Agreement__c oAggr = [SELECT Id, APTS_ExclusionRelatedDetails__c FROM Apttus__APTS_Agreement__c WHERE Id = :aggrId LIMIT 1];
        System.assertEquals( 'Adjustment Exclusion',oAggr.APTS_ExclusionRelatedDetails__c);
          
    }
}