/**
 * Created by kvermachelen on 2019-02-26.
 */

public without sharing class EventMonitoringExceptionSyncUtil {
    private final static string ID_REPLACEMENT_REGEX = '[a-zA-Z0-9]{5}0[a-zA-Z0-9]{9}([a-zA-Z0-5]{3})?';
    private final static string ID_REPLACEMENT = 'XXXXXXXX_ID_XXXXXX';

    public static void stageEventLogDataParts(List<EventLogFile> eventLogFileRecords, Id externalDataId, Integer partNumber){
        String orgId = String.valueOf(UserInfo.getOrganizationId());
        String replaceCompanyNameRegex = 'Developer script exception from [^:]+ : '; // Remove this standard line showing org name as it has no value

        //  Loop over the EventLogFile records.
        //  each LogFile is a base64binary containing either the daily or hourly exception logs in CSV
        List<InsightsExternalDataPart> externalDataParts = new List<InsightsExternalDataPart>();

        for (EventLogFile e : eventLogFileRecords) {
            //System.debug(e.LogFile.toString());
            Integer i = 0;
            String result = '';
            for (String s : e.LogFile.toString().split('(?<=")\n')) {
                if (i++ == 0) {
                    continue; // Skipping header
                }
                s = s.replaceAll('"' + orgId + '",', ''); // Get rid of org id
                s = s.replaceAll('"' + orgId.substring(0,15) + '",', ''); // Get rid of org id, also match against Id with length 15
                s = s.replaceAll(ID_REPLACEMENT_REGEX, ID_REPLACEMENT);
                s = s.replaceAll(replaceCompanyNameRegex,'');
                result += s + '\r\n';
            }
            System.debug('Result: ' + result);
            Blob resultBlob = Blob.valueOf(result);
            
            InsightsExternalDataPart externalDataPart = createExternalDataPart(resultBlob, partNumber++, externalDataId);
            externalDataParts.add(externalDataPart);
        }

        /*for (Integer i = 0; i < eventLogFileRecords.size(); i++) {
            Blob eventLogFileBlob = eventLogFileRecords[i].LogFile;
            String eventLogFileCSVString = eventLogFileBlob.toString();
            String replacedEventLogFileCSVString = '';

            System.debug('eventLogFileCSVString: ' + (partNumber>0) + ' : ' + eventLogFileCSVString);

            if(partNumber>0){
                eventLogFileCSVString = eventLogFileCSVString.substringAfter('\n');
            }else{
                eventLogFileCSVString = eventLogFileCSVString;
            }

            //  an iterator to read the CSV, needed as these CSV strings can get long so a split on newline wouldn't work
            EventMonitoringCsvIterator csvReader = New EventMonitoringCsvIterator(eventLogFileCSVString,'\n');

            String csvRow;
            while(csvReader.hasNext()){
                csvRow = csvReader.next();
                System.debug('csvRow: ' + csvRow);
                
                csvRow = csvRow.replaceAll('"' + orgId + '",', ''); // Get rid of org id
                csvRow = csvRow.replaceAll('"' + orgId.substring(0,15) + '",', ''); // Get rid of org id, also match against Id with length 15
                csvRow = csvRow.replaceAll('"ORGANIZATION_ID",', ''); // Get rid of org column
                csvRow = csvRow.replaceAll(ID_REPLACEMENT_REGEX, ID_REPLACEMENT);
                csvRow = csvRow.replaceAll(replaceCompanyNameRegex,'');

                csvRow += '\r\n';

                replacedEventLogFileCSVString += csvRow;
            }

            System.debug('replacedEventLogFileCSVString result: ' + replacedEventLogFileCSVString);

            Blob replacedEventLogFileBlob = Blob.valueOf(replacedEventLogFileCSVString);
            
            InsightsExternalDataPart externalDataPart = createExternalDataPart(replacedEventLogFileBlob, partNumber++, externalDataId);
            externalDataParts.add(externalDataPart);
        }*/
        
        insert externalDataParts;
    }

    //  create the InsightsExternalData object which contains info such as the object schema and to which dataset it should go
    public static Id createUnexpectedExceptionExternalDataObject(String datasetName) {
        //  get the json schema for the ApexUnexpectedException EventLog type
        StaticResource exceptionLogTypeSchema = [SELECT Body FROM StaticResource WHERE Name = 'EventMonitoringApexUnexpectedExceptionSchema'];
        Blob exceptionLogTypeSchemaBody = exceptionLogTypeSchema.Body;

        InsightsExternalData extDataObject = new InsightsExternalData();
        extDataObject.put('Format', 'csv');
        extDataObject.put('EdgemartAlias', datasetName);
        extDataObject.put('Operation', 'Overwrite');
        if (exceptionLogTypeSchemaBody != null) {
            extDataObject.put('metadataJson', exceptionLogTypeSchemaBody);
        }
        extDataObject.put('Action', 'None');
        Insert extDataObject;

        return extDataObject.Id;
    }

    //  create the InsightsExternalDataPart object which contains the actual csv data (staging of the data)
    private static InsightsExternalDataPart createExternalDataPart(Blob csv, Integer partNumber, Id extDataObjectId) {
        InsightsExternalDataPart extDataPartObject = new InsightsExternalDataPart();
        extDataPartObject.put('DataFile', csv);
        extDataPartObject.put('InsightsExternalDataId', extDataObjectId);
        extDataPartObject.put('PartNumber', partNumber);
        return extDataPartObject;
    }

    public static void processUploadToAnalyticsDataset(Id extDataObjectId) {
        //  update the InsightsExternalData object to tell the system to start processing the upload
        InsightsExternalData extDataObject = new InsightsExternalData();
        extDataObject.put('Id', extDataObjectId);
        extDataObject.put('Action', 'Process');
        Upsert extDataObject;
    }
}