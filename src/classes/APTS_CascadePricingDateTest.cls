/**********************************************************************************
 * @Author: Jason Mactal
 * @Company: Accenture
 * @Description: Test Class for APTS_CascadePricingDate
 * @Created Date: Aug 17, 2018
 * @History:
 *      <Name>              <Date>          <Description>
 *      jason.e.mactal      08.17.2018       Created
 *
 **********************************************************************************/
@isTest
public class APTS_CascadePricingDateTest {
    @testSetup
    static void testSetup() {

        User testUser = APTS_TestDataFactory.createUser();
        testUser.UserName = 'testuser123@jdecoffee.com';
        insert testUser;
        system.runAs(testUser) {
            Account oAcc = APTS_TestDataFactory.createAccount('Test Account');
            insert oAcc;
    
            Apttus__APTS_Agreement__c oAgg = APTS_TestDataFactory.createAgreement(null, null, oAcc.id, 'Standard Deal');
            insert oAgg;
            
            Apttus__AgreementLineItem__c oALI = APTS_TestDataFactory.createAgreementLineItem(null, oAgg.id, oAcc.id, null);
            oALI.Apttus_CMConfig__LineType__c = 'Product/Service';
            insert oALI;
        }

    }
    private static testMethod void cascadePricingDateTest() {
        user testUser = [SELECT Id FROM USER WHERE UserName = 'testuser123@jdecoffee.com' LIMIT 1];
        Apttus__APTS_Agreement__c testAgg = [SELECT Id, APTS_PricingDate__c FROM Apttus__APTS_Agreement__c LIMIT 1];
        system.runAs(testUser) {
            
            test.startTest();
            testAgg.APTS_PricingDate__c = date.today().addDays(1);
            update testAgg;
            List<id> aggList = new List<id>();
            aggList.add(testAgg.id);
            APTS_CascadePricingDate.updateAgreementLineItemPricingDate(aggList);
            test.stopTest();

            Apttus__APTS_Agreement__c checkAgreement = [SELECT Id, APTS_PricingDate__c FROM Apttus__APTS_Agreement__c LIMIT 1];
            Apttus__AgreementLineItem__c checkAgreementLI = [SELECT Id, APTS_PricingDate__c FROM Apttus__AgreementLineItem__c WHERE Apttus__AgreementId__c =: checkAgreement.id];
            system.assertEquals(checkAgreement.APTS_PricingDate__c, checkAgreementLI.APTS_PricingDate__c);
        }
    }
}