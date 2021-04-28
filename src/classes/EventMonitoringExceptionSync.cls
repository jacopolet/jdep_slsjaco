/**
 * Created by kvermachelen on 2019-02-25.
 * This class will query the ApexUnexpectedException event log records and push the data to the analytics data set.
 * see for more info: https://developer.salesforce.com/docs/atlas.en-us.bi_dev_guide_ext_data.meta/bi_dev_guide_ext_data/bi_ext_data_overview.htm
 *
 * TODO:
 * -    it could be that a file would exceed 10 MB, so we should work with multiple InsightsExternalDataPart's
 *          -   create a file first?
 *          -   somehow calculate byte size of the string?
 */

global class EventMonitoringExceptionSync implements Schedulable {
    global void execute(SchedulableContext ctx) {
        Database.executeBatch(new EventMonitoringExceptionBatch(),1);
    }


}