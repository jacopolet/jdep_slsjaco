//-------------------------------------------------------------------------------------------//
// Author       :   Vince Canlas
// Created Date :   January 18, 2021
// Usage        :   Schedulable class for EMT Batch Monitoring
// Requirement  :   Emails a CSV file every run that contains failed Apex jobs
// 
//-------------------------------------------------------------------------------------------//
public with sharing class EmailBatchMonitoring implements Schedulable {

      public void execute(Schedulablecontext sC) {
        string header = 'ApexClassName,CompletedDate,CreatedDate,StatusDetail,JobType,MethodName,Status\n';
        string finalstr = header ;
        for(AsyncApexJob a : [SELECT ApexClass.Name,CompletedDate,CreatedDate,ExtendedStatus,JobType,MethodName,
                          Status,TotalJobItems,NumberOfErrors FROM AsyncApexJob WHERE ExtendedStatus != NULL AND JobType != 'Future' 
                          AND CreatedDate = LAST_N_DAYS:3 AND CreatedBy.Name LIKE '%Batch%' ORDER BY CreatedDate ASC NULLS FIRST]){
             string recordString = a.ApexClass.Name+','+a.CompletedDate+','+a.CreatedDate+','+a.ExtendedStatus+','+a.JobType+','+a.MethodName+','+a.Status+'\n';
             finalstr = finalstr + recordString;
         }
	  Date d = Date.Today();
        String dt = DateTime.newInstance(d.year(),d.month(),d.day()).format('yyyy-MM-dd');
        Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
        blob csvBlob = Blob.valueOf(finalstr);
        string csvname= 'FailedBatches - ' + dt + '.csv';
        csvAttc.setFileName(csvname);
        csvAttc.setBody(csvBlob);
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        String[] toAddresses = Label.EMTBatchMonitoringEmails.split(',');
        String subject ='Failed Batches CSV - ' + dt;
        email.setSubject(subject);
        email.setToAddresses( toAddresses );
        email.setPlainTextBody('Failed Batches CSV ');
        email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
        Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});

     }
}