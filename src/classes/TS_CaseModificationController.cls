/**
* @author        Paul Jarred Aguiling
* @date          8.16.2017           
* @description   Class responsible for executing Case Modification batch job
* @revision(s)
*/
global with sharing class TS_CaseModificationController {
    
    public static Boolean hasException = false;

    /******************************************************************************
    * @author         Paul Jarred Aguiling
    * @date           07.06.2017
    * @description    Method responsible for throwing an exception
    * @revision(s)
    ******************************************************************************/ 
    public class TS_CaseModificationException extends Exception {  }

    /**
    * @author        Paul Jarred Aguiling
    * @date          8.16.2017           
    * @description   Method responsible for redirecting page to case record
    * @revision(s)    
    */
    
    @AuraEnabled
    webService static String runBatchJob(Case cse) {
        createMassCaseRecords(cse);
        PageReference pageRef = new PageReference('/' + cse.Id);
        pageRef.setRedirect(true);
        return String.valueOf(pageRef.getUrl());
    }

    /**
    * @author        Paul Jarred Aguiling
    * @date          7.6.2017           
    * @description   Method responsible for creating case modifications records 
    *                through invocation of batch.
    * @revision(s)
    */
    
    @AuraEnabled
    public static void createMassCaseRecords(Case cse) {
        CustomLogging.push('createMassCaseRecords', 'TS_CaseModificationController');
        List<Case> caseList = new List<Case>();
        List<Id> accountIds = new List<Id>();
        List<Id> accLocIds = new List<Id>();
        List<Id> productIds = new List<Id>();
        
        try {

            if (Test.isRunningTest() && hasException) {
                throw new TS_CaseModificationException('Force to throw an exception');
            }

            //Query Case required lookup records
            Case cseRecord = [SELECT Id, AccountId, AccountLocation__c, ProductId, 
                                     Status, GenerateOrder__c, Subject, Description,
                                     EarlyStartDate__c, SLADate__c, OwnerId, Re_active__c,
                                     SalesOrganization__c
                              FROM Case 
                              WHERE Id =: cse.Id LIMIT 1];
            caseList.add(cseRecord);

            // 10.09.2017 TSWS - 496
            //if (!Label.TS_Status_CompleteD.equals(cseRecord.Status) && cseRecord.GenerateOrder__c) {
            if (!Label.TS_Status_Closed.equals(cseRecord.Status) && cseRecord.GenerateOrder__c) {
                if (cseRecord.AccountId != null)
                    accountIds.add(cseRecord.AccountId);

                if (cseRecord.AccountLocation__c != null)
                    accLocIds.add(cseRecord.AccountLocation__c);

                if (cseRecord.ProductId != null)
                    productIds.add(cseRecord.ProductId);
            }

            /* Jan. 17, 2019 - Product cannot be empty. XEN REYES */
            //if ((!accountIds.isEmpty() || !accLocIds.isEmpty()) && !productIds.isEmpty()) {
            if (!productIds.isEmpty()) {
                
                /* JANUARY 16, 2019: Queue Capacity Checker - XEN REYES */
                //CHECK IF THE JOB IS STILL RUNNING
                /* List<AsyncApexJob> batchJob = [SELECT Id, ApexClassID 
                                                    FROM AsyncApexJob 
                                                    WHERE Status IN ('Processing', 'Preparing') 
                                                    AND ApexClassId IN (SELECT Id FROM ApexClass WHERE Name = 'CaseModificationBatch') ]; */
                
                //COUNT THE PROCESSING JOBS AND THOSE IN QUEUE
                Integer batchCount_ProcessingPreparing = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType =\'BatchApex\' AND Status IN (\'Processing\', \'Preparing\')');
                Integer batchCount_HoldingQueued = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType =\'BatchApex\' AND Status IN (\'Queued\', \'Holding\')');

                if (batchCount_ProcessingPreparing < 5 && batchCount_HoldingQueued < 100 && !Test.isRunningTest()) { 
                   Database.executeBatch(new CaseModificationBatch(caseList, accountIds, accLocIds, productIds), 40);

                } else {
                   //EXECUTE THE SCHEDULER AGAIN IN NTH MINS.
                   CaseModificationBatch_Scheduler schedClass = new CaseModificationBatch_Scheduler(caseList, accountIds, accLocIds, productIds);
                   Datetime dt = Datetime.now().addMinutes(10);
                   String timeForScheduler = dt.format('s m H d M \'?\' yyyy');
                   System.schedule('Case Modification Job Retry ' + timeForScheduler, timeForScheduler, schedClass);
                }
            }

        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
        } finally {
            CustomLogging.pop();
        }
    }

    @AuraEnabled
    public static String createOrderClass (String recordId){
        
        String result = 'SUCCESS';
        if(!String.isEmpty(recordId)){
            Case cs = new Case(id=recordId);
            cs.Status = 'In Progress';
            cs.CaseSubStatus__c = 'Order Open';
            cs.CreatedOrderedManually__c = true;
            cs.SLARecalculation__c = true; //DOO-5274 XEN REYES - Jan. 26, 2020

            try{
                update cs;
            } catch(Exception e){
                String err = e.getMessage();
                return err.substringAfter(',');
            }
        }
        return result;
    }

}