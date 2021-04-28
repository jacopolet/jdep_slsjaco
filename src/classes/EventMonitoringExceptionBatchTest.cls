/**
 * Created by sbotman on 2019-11-27. Test class for EventMonitoringExceptionBatch
 */
@IsTest
public class EventMonitoringExceptionBatchTest {

    /**
     * Test the batch. EventLog cannot be inserted so not much to assert
     */
    @IsTest
    private static void testBatch() {
        EventMonitoringExceptionBatch emBatch = new EventMonitoringExceptionBatch();
        emBatch.query += ' limit 1'; // Simulate same batch size as run in prod..
        Test.startTest();
            Id batchId = Database.executeBatch(emBatch);
        Test.stopTest();
        System.assert(batchId != null, 'Batch Id must not be null');
    }
}