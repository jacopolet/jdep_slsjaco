/**
 * Created by kvermachelen on 2019-02-28.
 */

global class EventMonitoringExceptionBatch implements Database.Batchable<sObject>, Database.Stateful{
    private Id externalDataObjectId;
    private Integer partNumber = 1;

    @TestVisible
    private String query = 'Select LogFile From EventLogFile where EventType=\'ApexUnexpectedException\' and ((LogDate=today and Interval=\'Hourly\') or (LogDate<today and Interval=\'Daily\'))';

    global Database.QueryLocator start(Database.BatchableContext bc) {
        //  prepare an external data object which is the header for uploading the different event log data parts
        externalDataObjectId = EventMonitoringExceptionSyncUtil.createUnexpectedExceptionExternalDataObject('ApexUnexpectedException');

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<EventLogFile> scope) {
        if(externalDataObjectId!=null) {
            EventMonitoringExceptionSyncUtil.stageEventLogDataParts(scope, externalDataObjectId, partNumber);
            // Prepare for next Chunk by adding scope size to partNumber:
            partNumber += scope.size();
        }else{
            throw new EventMonitoringExceptionSyncException('Staging of external data parts failed because the external data header object was not created.');
        }
    }

    global void finish(Database.BatchableContext bc) {
        //  indicate to analytics that it can start processing the data upload of the staged data parts
        EventMonitoringExceptionSyncUtil.processUploadToAnalyticsDataset(externalDataObjectId);
    }
}