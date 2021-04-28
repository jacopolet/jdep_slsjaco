/*************************************
Common Bantch Handler Interface for Batch Execution
***************************************/

public interface APTS_CommonBatchHandler {
	void processBatchRecords(Database.BatchableContext context, List<sObject> listObject, boolean batchControl);
}