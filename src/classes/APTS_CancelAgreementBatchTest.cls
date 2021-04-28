/**********************************************************************************
 * @Author: Jason Mactal
 * @Company: Accenture
 * @Description: Test Class for APTS_CancelAgreementBatch
 * @Created Date: June 25, 2018
 * @History:
 *      <Name>              <Date>          <Description>
 *      jason.e.mactal      06.25.2018      Created
 * 
 **********************************************************************************/
@isTest
private class APTS_CancelAgreementBatchTest {
    
    @testSetup
    static void testSetup() {
        
        User testUser = APTS_TestDataFactory.createUser();
        
        Account oAcc = APTS_TestDataFactory.createAccount('Test Account');
        insert oAcc;
        
        
        List<Apttus__APTS_Agreement__c> oAggList = new List<Apttus__APTS_Agreement__c>();
        for(integer i=0;i<50;i++){
            Apttus__APTS_Agreement__c oAgg = APTS_TestDataFactory.createAgreement(null, null, oAcc.id, 'Standard Deal');
            oAgg.Apttus__Status_Category__c = 'In Signatures';
            oAgg.Apttus__Status__c = 'Other Party Signatures';
            oAgg.APTS_Agreement_Proposal_Valid_Date__c = date.today().addDays(-1);
            oAggList.add(oAgg);
        }
        
        for(integer i=0;i<50;i++){
            Apttus__APTS_Agreement__c oAgg = APTS_TestDataFactory.createAgreement(null, null, oAcc.id, 'Standard Deal');
            oAgg.Apttus__Status_Category__c = 'In Signatures';
            oAgg.Apttus__Status__c = 'Other Party Signatures';
            oAgg.APTS_Agreement_Proposal_Valid_Date__c = date.today();
            oAggList.add(oAgg);
        }
        insert oAggList;
        
    }
    private static testMethod void test() {

        test.startTest();
            APTS_CancelAgreementScheduler sch = new APTS_CancelAgreementScheduler();
            string cron = '0 0 1 1/1 * ? *';
            String jobId = system.schedule('Cancel Agreement'+system.now(),cron,sch);
        test.stopTest();
        
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(cron,ct.CronExpression);

    }

}