/**************************************************************
 * @Author: jason.e.mactal
 * @Company: Accenture
 * @Description: Test class for APTS_CalculateROSController
 * @Created Date: May 23, 2018
 * @Revisions:
 *      <Name>              <Date>          <Description>
 *      jason.e.mactal      May 23, 2018     Initial Version
 * 
 *************************************************************/
@isTest
private class APTS_CalculateROSControllerTest {
    
    @testSetup
    static void testSetup() {
        
        User testUser = APTS_TestDataFactory.createUser();
        testUser.Email = 'testuser123@jdecoffee.com';
        system.runAs(testUser){
            Account oAcc = APTS_TestDataFactory.createAccount('Test Account');
            insert oAcc;
            
            Apttus__APTS_Agreement__c oAgg = APTS_TestDataFactory.createAgreement(null, null, oAcc.id, 'Standard Deal');
            oAgg.APTS_Region__c = 'SAP_0111';
            oAgg.APTS_Distribution_Cost__c = 5;
            oAgg.APTS_Warehousing_Cost__c = 8;
            insert oAgg;
            
            Apttus__AgreementLineItem__c oAggLI = new Apttus__AgreementLineItem__c();
            oAggLI.Apttus__AgreementId__c = oAgg.Id;
            oAggLI.Apttus_CMConfig__IsPrimaryLine__c = true;
            oAggLI.Apttus_CMConfig__HasOptions__c = true;
            oAggLI.Apttus_CMConfig__LineType__c = 'Product/Service';
            oAggLI.Apttus__Quantity__c = 1;
            oAggLI.APTS_Depreciation_Cost__c = 15;
            oAggLI.Apttus_CMConfig__ClassificationHierarchy__c = 'Machines';
            insert oAggLI;
            
            Apttus__AgreementLineItem__c oAggLI2 = new Apttus__AgreementLineItem__c();
            oAggLI2.Apttus__AgreementId__c = oAgg.Id;
            oAggLI2.APTS_Is_Not_Rollup_Line__c = true;
            oAggLI2.APTS_Net_Adjustment_Amount_2_decimals__c = 15;
            oAggLI2.APTS_Base_Extended_Price_2_decimals__c = 100;
            oAggLI2.APTS_Extended_Cost_2_decimals__c = 10;
            oAggLI2.Apttus_CMConfig__ExtendedCost__c = 10;
            oAggLI2.Apttus_CMConfig__ClassificationHierarchy__c = 'Machines';
            oAggLI2.Apttus__NetPrice__c = 85;
            insert oAggLI2;
            
            APTS_AgreementTotalVolumeObligation__c oVAO = new APTS_AgreementTotalVolumeObligation__c();
            oVAO.APTS_Total_Expected_Discount_Amount__c = 20;
            oVAO.APTS_Total_Estimated_Contract_Value__c = 200;
            oVAO.APTS_Total_Expected_Cost_Amount__c = 25;
            oVAO.APTS_Agreement__c = oAgg.Id;
            insert OVAO;
        }
        
    }

    private static testMethod void calculateROS() {
        user testUser = [SELECT Id FROM USER WHERE Email = 'testuser123@jdecoffee.com'];
        Apttus__APTS_Agreement__c oAgg = [SELECT Id FROM Apttus__APTS_Agreement__c LIMIT 1];
        PageReference pr = page.APTS_CalculateROS;
        pr.getParameters().put('Id', String.valueOf(oAgg.Id));
        
        system.runAs(testUser){
            Test.startTest();
                Test.setCurrentPage(pr);
                ApexPages.StandardController scAgg = new ApexPages.StandardController(oAgg);
                APTS_CalculateROSController cont = new APTS_CalculateROSController(scAgg);
                cont.calculateROS();
            Test.stopTest();
        }
        Apttus__APTS_Agreement__c oAggCheck = [SELECT Id, APTS_ROS__c FROM Apttus__APTS_Agreement__c LIMIT 1];
        system.assert(oAggCheck.APTS_ROS__c!=null && oAggCheck.APTS_ROS__c!=0);

    }
    private static testMethod void negativeTest() {
        user testUser = [SELECT Id FROM USER WHERE Email = 'testuser123@jdecoffee.com'];
        Apttus__APTS_Agreement__c oAgg = [SELECT Id, APTS_Adj_EBIT__c FROM Apttus__APTS_Agreement__c LIMIT 1];
        PageReference pr = page.APTS_CalculateROS;
        pr.getParameters().put('Id', String.valueOf(oAgg.Id));
        
        try{
        system.runAs(testUser){
            Test.startTest();
                oAgg.APTS_Distribution_Cost__c = 0;
                update oAgg;
                Test.setCurrentPage(pr);
                ApexPages.StandardController scAgg = new ApexPages.StandardController(oAgg);
                APTS_CalculateROSController cont = new APTS_CalculateROSController(scAgg);
                cont.calculateROS();
                cont.doCancel();
            Test.stopTest();
        }
        }catch(exception e){
            system.assert(e.getMessage().contains(Label.APTS_ROSCalculationError));
        }

    }

}