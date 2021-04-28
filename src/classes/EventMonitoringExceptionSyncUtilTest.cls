/**
 * Created by kvermachelen on 2019-02-27.
 */

@IsTest
private class EventMonitoringExceptionSyncUtilTest {
    @IsTest
    static void testBehavior() {
        test.startTest();
        Id externalDataObjectId = EventMonitoringExceptionSyncUtil.createUnexpectedExceptionExternalDataObject('ApexUnexpectedException');
        System.assertNotEquals(null, externalDataObjectId);

        String logSampleData = 'IkVWRU5UX1RZUEUiLCJUSU1FU1RBTVAiLCJSRVFVRVNUX0lEIiwiRVhDRVBUSU9OX1RZUEUiLCJFWENFUFRJT05fTUVTU0FHRSIsIlNUQUNLX1RSQUNFIiwiVElNRVNUQU1QX0RFUklWRUQiCiJBcGV4VW5leHBlY3RlZEV4Y2VwdGlvbiIsIjIwMTkwMjI1MTI1NjU0Ljc3MSIsIjROUFJna0NpU0tsb3JEa0NhY21qTVYiLCJEbWxFeGVjdXRpb25FeGNlcHRpb24iLCJEZXZlbG9wZXIgc2NyaXB0IGV4Y2VwdGlvbiBmcm9tIFNhbGVzZm9yY2UgOiBVcGxvYWRfSW5pdF9FTSA6IEluc2VydCBmYWlsZWQuIEZpcnN0IGV4Y2VwdGlvbiBvbiByb3cgMDsgZmlyc3QgZXJyb3I6IEZJRUxEX0lOVEVHUklUWV9FWENFUFRJT04sIERhdGFzZXQgUmVwb3J0IGFscmVhZHkgZXhpc3RzIGluIGFwcCBNeV9EVENfU2FsZXMsIGJ1dCByZWdpc3RlciBzcGVjaWZpZWQgYXBwIEV2ZW50X01vbml0b3JpbmcuOiBbRWRnZW1hcnRDb250YWluZXJdIiwiY2F1c2VkIGJ5OiBTeXN0ZW0uRG1sRXhjZXB0aW9uOiBJbnNlcnQgZmFpbGVkLiBGaXJzdCBleGNlcHRpb24gb24gcm93IDA7IGZpcnN0IGVycm9yOiBGSUVMRF9JTlRFR1JJVFlfRVhDRVBUSU9OLCBEYXRhc2V0IFJlcG9ydCBhbHJlYWR5IGV4aXN0cyBpbiBhcHAgTXlfRFRDX1NhbGVzLCBidXQgcmVnaXN0ZXIgc3BlY2lmaWVkIGFwcCBFdmVudF9Nb25pdG9yaW5nLjogW0VkZ2VtYXJ0Q29udGFpbmVyXSIsIjIwMTktMDItMjVUMTI6NTY6NTQuNzcxWiIK';
        List<EventLogFile> sampleEventLogFiles = new List<EventLogFile>();
        EventLogFile sampleEventLog = new EventLogFile();
        sampleEventLog.LogFile = Blob.valueOf(logSampleData);
        sampleEventLogFiles.add(sampleEventLog);

        EventMonitoringExceptionSyncUtil.stageEventLogDataParts(sampleEventLogFiles, externalDataObjectId, 0);

        EventMonitoringExceptionSyncUtil.processUploadToAnalyticsDataset(externalDataObjectId);
        
        test.stopTest();
        InsightsExternalData apexUnexpectedExceptionsUpload = [Select Id, Action, Status, StatusMessage From InsightsExternalData where Id = :externalDataObjectId LIMIT 1];
        System.assertEquals('Process',apexUnexpectedExceptionsUpload.Action);

        List<InsightsExternalDataPart> apexUnexpectedExceptionsDataParts = [Select Id From InsightsExternalDataPart where InsightsExternalDataId=:apexUnexpectedExceptionsUpload.Id];
        System.assertNotEquals(0,apexUnexpectedExceptionsDataParts.size());
    }
}