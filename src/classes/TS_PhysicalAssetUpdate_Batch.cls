/**
* @author        Karen Hung
* @date          10.31.2018
* @description   Class used to update Physical Asset Fields when the contract expires
* @revision(s)
*/
global with sharing class TS_PhysicalAssetUpdate_Batch implements Database.Batchable <sObject> {

	/*to handle exception*/
	public class TS_PhysicalAssetUpdate_BatchException extends Exception {}
	public static Boolean hasException = false;

	Date runDate;

    /******************************************************************************
     * @author        Karen Hung
     * @date          31.Oct.2018
     * @description   Constructor
     * @revision(s)
     ******************************************************************************/
    global TS_PhysicalAssetUpdate_Batch(Date rDate) {
        CustomLogging.push('TS_PhysicalAssetUpdate_Batch', 'TS_PhysicalAssetUpdate_Batch');
        runDate = rDate;        
        CustomLogging.pop();
    }
    /******************************************************************************
     * @author         Karen Hung
     * @date           31.Oct.2018
     * @description    This method is the start of the batch job
     * @revision(s)
     ******************************************************************************/
    global Database.QueryLocator start(Database.BatchableContext BC) {
    	//Get all machines with Contract End Date + 1 = Date.Today(). (Instead of using directly, the date.today() method, we can use the runDate approach so we can flexibly test the scenarios)
    	CustomLogging.push('start', 'TS_PhysicalAssetUpdate_Batch');
    	DescribeSObjectResult physicalAsset = PhysicalAsset__c.getSObjectType().getDescribe();
        List<String> fields = new List<String>(physicalAsset.fields.getMap().keySet());
        String s = String.valueOf(runDate.addDays(-1));
        String machineId = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get('Machine').getRecordTypeId();
        String query = 'SELECT ' + String.join(fields, ',') + ' FROM PhysicalAsset__c WHERE RecordTypeId = ' + '\''+  machineId + '\'' + ' AND EndDate__c <=' + s;
    	CustomLogging.pop();
    	return Database.getQueryLocator(query);
	}
	
	/******************************************************************************
     * @author         Karen Hung
     * @date           31.Oct.2018
     * @description    This method to perform actions when the batch is executinng
     * @revision(s)
     ******************************************************************************/
	global void execute(Database.BatchableContext BC, List<PhysicalAsset__c> paList) {
		CustomLogging.push('execute', 'TS_PhysicalAssetUpdate_Batch');
		List<PhysicalAsset__c> paToUpdate = TS_PhysicalAssetDataRemover.removeServicesFieldValues(paList);

		try{
			if (Test.isRunningTest() && hasException) {
				 throw new TS_PhysicalAssetUpdate_BatchException('Force to throw an exception');
			}
			if(!paToUpdate.isEmpty() && Schema.sObjectType.PhysicalAsset__c.isUpdateable()){
		 		database.update(paToUpdate);	
			}
		}catch(Exception e){
			System.debug('TS_PhysicalAssetUpdate_Batch Error : ' + e);
		}

		CustomLogging.pop();	
	}

	 /******************************************************************************
     * @author         Karen Hung
     * @date           31.Oct.2018
     * @description    This method to perform actions when the batch is finished
     * @revision(s)
     ******************************************************************************/
    global void finish(Database.BatchableContext BC) {
	    CustomLogging.push('finish', 'TS_PhysicalAssetUpdate_Batch');
		CustomLogging.pop();
    }
}