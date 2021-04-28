@isTest
private class APTS_ActivateAgreementQueueTest {
    
    @testsetup
    private static void setupTestData() {
        List<Apttus__APTS_Agreement__c> agmtList = new List<Apttus__APTS_Agreement__c>();
        for(Integer i = 0; i < 4; i++) {
            Apttus__APTS_Agreement__c agmt = APTS_TestUtils.createAgreement(null, null, null, null);
            agmt.Apttus__Contract_End_Date__c = Date.Today() + 365;
            agmt.Apttus__Status__c = 'Fully Signed';
            agmtList.add(agmt);
        }
        insert agmtList;
        
        List<Attachment> attList = new List<Attachment>();
        for(Apttus__APTS_Agreement__c agmt : agmtList) {
            Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
            Attachment att = new Attachment(Name = 'Test_signed.pdf', Body = bodyBlob, ParentId = agmt.Id);
            attList.add(att);
        }
        insert attList;
    }

    private static testMethod void testExecute() {
        Map<Id, Apttus__APTS_Agreement__c> agmtMap = new Map<Id, Apttus__APTS_Agreement__c>([SELECT Id FROM Apttus__APTS_Agreement__c LIMIT 200]); 
        Test.startTest();
            Id jobID = System.enqueueJob(new APTS_ActivateAgreementQueue(agmtMap.keySet()));
        Test.stopTest();
        
        List<Apttus__APTS_Agreement__c> uAgmtLst = [SELECT Id, Apttus__Status__c FROM Apttus__APTS_Agreement__c WHERE Id IN :agmtMap.keySet() LIMIT 200]; 
        for(Apttus__APTS_Agreement__c agmt :  uAgmtLst) {
            System.assertEquals('Activated', agmt.Apttus__Status__c);
        }
    }
    
    private static testMethod void testExecuteError() {
        Set<Id> agtmIds = new Set<Id>{null};
        Test.startTest();
            Id jobID = System.enqueueJob(new APTS_ActivateAgreementQueue(agtmIds));
        Test.stopTest();
        
        List<Apttus__APTS_Agreement__c> uAgmtLst = [SELECT Id, Apttus__Status__c FROM Apttus__APTS_Agreement__c WHERE Id IN :agtmIds LIMIT 200]; 
        System.assertEquals(0, uAgmtLst.size());
    }

}