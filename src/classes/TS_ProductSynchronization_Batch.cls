/**
* @author        Marvin Gatchalian
* @date          2.mar.2018
* @description   Apex class used to executes product synchronization 
* @revision(s)   6.6.2018 Paul Aguiling: KTS-1801 Updated getQuery() due to changes to Master Data Management Filter 
*                Karen Hung :11.26.18 KTS-2363
*/

global with sharing  class TS_ProductSynchronization_Batch implements Database.Batchable<sObject>{
	
	Id standardPriceBookId;
	
	/******************************************************************************
    * @author         Marvin Gatchalian
    * @date           2.mar.2018
    * @description    Constructor
    * @revision(s)
    ******************************************************************************/ 
	global TS_ProductSynchronization_Batch () {
		CustomLogging.push('Constructor', 'TS_ProductSynchronization_Batch');
		
		if (!Test.isRunningTest()) {
			List<pricebook2> standardPriceBook = [select Id from pricebook2 where IsStandard = true limit 1];
			standardPriceBookId = standardPriceBook[0].id;
		}
		else if (Test.isRunningTest()){
			standardPriceBookId = Test.getStandardPricebookId();
		}
        CustomLogging.pop();
    }
    
	
	/******************************************************************************
    * @author         Marvin Gatchalian
    * @date           2.mar.2018
    * @description    This method is the start of the batch job
    * @revision(s)
    ******************************************************************************/ 
    global Database.QueryLocator start(Database.BatchableContext BC) {
        CustomLogging.push('start', 'TS_ProductSynchronization_Batch');
        CustomLogging.pop();
        return Database.getQueryLocator(getQuery());
    }
    
    /******************************************************************************
    * @author         Marvin Gatchalian
    * @date           2.mar.2018
    * @description    This method returns a SQL syntax on active operating schedule table
    * @revision(s)
    ******************************************************************************/ 
    String getQuery(){
        CustomLogging.push('getQuery', 'TS_OperatingTasks_Batch');
        DescribeSObjectResult operatingScheduleDescribe = Apttus_Config2__PriceListItem__c.getSObjectType().getDescribe();
        List <String> fields = new List<String>(operatingScheduleDescribe.fields.getMap().keySet());
        List <String> materialType = new List <String>{'ZCMA','ZOPT','ZSER','ZSPR'};
        
        CustomLogging.pop();
        return 'SELECT Id, Apttus_Config2__ListPrice__c, Apttus_Config2__ProductId__c, APTS_TS_Sales_Organization__c, CurrencyIsoCode ' 
               + 'FROM ' + operatingScheduleDescribe.getName() + ' '
               + 'WHERE Apttus_Config2__ChargeType__c = \'Sales Price\' ' 
               + 'AND Apttus_Config2__PriceListId__r.APTS_PriceList_Type__c = \'Direct\' '
               + 'AND APTS_TS_Synchronized__c = false '
               + 'AND APTS_TS_Material_Type__c IN (\'ZCMA\', \'ZOPT\', \'ZSER\', \'ZSPR\') ';
    }
    
    
    /******************************************************************************
    * @author         Marvin Gatchalian
    * @date           2.mar.2018
    * @description    This method proceses the result of query.  
    *                 
    * @revision(s)
    ******************************************************************************/ 
    global void execute(Database.BatchableContext BC, List<Apttus_Config2__PriceListItem__c> priceListItems) {

        CustomLogging.push('execute', 'TS_ProductSynchronization_Batch');
        List <pricebookentry> defaultPriceBookEntriesToBeUpsert = new List <pricebookentry>();
    	List <pricebookentry> matchedPriceBookEntriesToBeUpsert = new List <pricebookentry>();
    	List <pricebookentry> splitPriceBookEntriesToBeUpdated = new List <pricebookentry>();
    	Map <pricebookentry, Apttus_Config2__PriceListItem__c> matchedPriceBookEntriesToBeUpsertMap = new 
    	Map <pricebookentry, Apttus_Config2__PriceListItem__c>();
    	TS_ProductSynchronization_Execute executeLogic = new TS_ProductSynchronization_Execute();
    	Boolean hasErrorDuringUpsert = false;
    
        
        defaultPriceBookEntriesToBeUpsert = executeLogic.createDefaultPriceBook (priceListItems, standardPriceBookId);
        matchedPriceBookEntriesToBeUpsertMap = executeLogic.createMatchedPriceBook (priceListItems);
        
        //perform upsert for default price book
        Schema.SObjectField externalId = PricebookEntry.TS_Load_Id__c;
        
        List<Custom_Log__c> errorLogs = new List<Custom_Log__c>(); //DOO-3536 to contains list of errors for custom logging

        if (!defaultPriceBookEntriesToBeUpsert.isEmpty()) {              
            Database.UpsertResult[] upsertResults = Database.upsert(defaultPriceBookEntriesToBeUpsert, externalId, false);
            /*for (Database.UpsertResult ds :upsertResults){
            	if (!ds.isSuccess()) system.debug('Error in upserting Default Price Book Entry  >>>>>  '+ ds);
            }*/
            
            //Karen Hung DOO-3536 error handling through custom log
           // INSERT_LOGGING(upsertResults, null, 'Error in upserting Default PricebookEntry');

            
        }
        
        //Split  PBE records to be updated removed productid and pricebookid fields
        for (pricebookentry eachPbe :matchedPriceBookEntriesToBeUpsertMap.keySet()) {
        	pricebookentry newPBE = new pricebookentry();
        	newPBE.UnitPrice = eachPbe.UnitPrice;
        	newPBE.TS_Load_Id__c = eachPbe.TS_Load_Id__c;
        	newPBE.IsActive = eachPbe.IsActive;
            newPBE.TS_Click_Synchronized__c = eachPbe.TS_Click_Synchronized__c; //DOO-5349 Feb. 15, 2021 Xen Reyes
        	splitPriceBookEntriesToBeUpdated.add(newPBE);
        }
        //Split  PBE records to be updated removed productid and pricebookid fields
        
        // Perform upsert for matched price book.
        // This is initial attempt of upsert to insert new records, others (existing record with productid) may fail 
        // due to the field is not writeable during update
        if (!matchedPriceBookEntriesToBeUpsertMap.keySet().isEmpty()) {
        	matchedPriceBookEntriesToBeUpsert.addAll(matchedPriceBookEntriesToBeUpsertMap.keySet());
            Database.UpsertResult[] upsertResults = Database.upsert(matchedPriceBookEntriesToBeUpsert, externalId, false);
           /* for (Database.UpsertResult ds :upsertResults){
            	if (!ds.isSuccess()) {
            		 system.debug('Error in upserting Matched Price Book Entry  >>>>>  '+ ds);
                }  
            } */

            //Karen Hung DOO-3536 Error handling through custom log
            INSERT_LOGGING(upsertResults, null, 'Error in upserting Matched Price Book Entry');                        
        }
        
        //This will handle the update of existing price book entries, the productid and pricebookid fields have been removed
        if (!splitPriceBookEntriesToBeUpdated.isEmpty()) {
            Database.UpsertResult[] upsertResults = Database.upsert(splitPriceBookEntriesToBeUpdated, externalId, false);
            for (Database.UpsertResult ds :upsertResults){
            	if (!ds.isSuccess()) {
            		// system.debug('Error in upserting Split Price Book Entry  >>>>>  '+ ds);
				     hasErrorDuringUpsert = true;      		 
            	}
            }
            
           //Karen Hung DOO-3536 Error handling through custom log
           INSERT_LOGGING(upsertResults, null, 'Error in upserting Split Price Book Entry');  
        }
        
        //Update SLI to mark TS Synchronized field to "True"
        if (!hasErrorDuringUpsert && !matchedPriceBookEntriesToBeUpsertMap.values().isEmpty()) {
        	Database.SaveResult[] SaveResults = Database.update(matchedPriceBookEntriesToBeUpsertMap.values(), false);
           /* for (Database.SaveResult ds :SaveResults){
            	if (!ds.isSuccess()) system.debug('Error in SLI update to mark synchronize to true. '+ ds);
            }*/
            
            //Karen Hung DOO-3536 Error handling through custom log
            INSERT_LOGGING(null, SaveResults, 'Error in SLI update to mark synchronize to true');  
        }
    
        CustomLogging.pop();
    }
    
    /******************************************************************************
    * @author         Marvin Gatchalian
    * @date           2.mar.2018
    * @description    This method to perform actions when the batch is finished
    * @revision(s)
    ******************************************************************************/ 
    global void finish(Database.BatchableContext BC) {
        CustomLogging.push('finish', 'TS_ProductSynchronization_Batch');

        /* JANUARY 14, 2019: Queue Capacity Checker - XEN REYES */
        //CHECK IF THE ROUTESALES JOB IS STILL RUNNING
        List<AsyncApexJob> syncToClickBatchJob = [SELECT Id, ApexClassID 
                                            FROM AsyncApexJob 
                                            WHERE Status IN ('Processing', 'Preparing') 
                                            AND ApexClassId IN (SELECT Id FROM ApexClass WHERE Name = 'TS_PricebookEntry_SyncToClick_Batch') ];
        
        //COUNT THE PROCESSING JOBS AND THOSE IN QUEUE
        Integer batchCount_ProcessingPreparing = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND Status IN (\'Processing\', \'Preparing\')');
        Integer batchCount_HoldingQueued = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND Status IN (\'Queued\', \'Holding\')');

        if (batchCount_ProcessingPreparing < 5 && batchCount_HoldingQueued < 100 && (syncToClickBatchJob == null || syncToClickBatchJob.size() == 0) && !Test.isRunningTest()) { 
           Database.executeBatch(new TS_PricebookEntry_SyncToClick_Batch(), Integer.valueOf(System.label.TS_PBESyncBatchSize)); // Karen Hung DOO-3536 17.02.2020 put batch size in custom label

        } else {
           //EXECUTE THIS SCHEDULER AGAIN IN NTH MINS.
           TS_PricebookEntry_SyncToClick_Scheduler schedClass = new TS_PricebookEntry_SyncToClick_Scheduler(null);
           Datetime dt = Datetime.now().addMinutes(10);
           String timeForScheduler = dt.format('s m H d M \'?\' yyyy');
           System.schedule('PriceBookEntry Sync to Click Job Retry ' + timeForScheduler, timeForScheduler, schedClass);
        }

        CustomLogging.pop();
    }

    /******************************************************************************
     * Karen Hung DOO-3536
     * 17.02.2020   Method to create a custom log record if there is failed record processed in the batch execution.
     ******************************************************************************/
    public void INSERT_LOGGING (List<Database.UpsertResult> upsertResultList, List<Database.SaveResult> saveResultList,  String description) {

        //Custom Logging for Database.Error
        Set<String> exception_List_batch = new Set<String>();

        /* Create error message to each Database.Error. */
        if(upsertResultList != null){
            for (Database.UpsertResult ur: upsertResultList) {
                if (!ur.isSuccess() || Test.isRunningTest()) {
                    //Operation failed. Get error details               
                    for(Database.Error err : ur.getErrors()) {
                        String msg = TS_Constants.ERRBATCH_MSG_01 + err.getStatusCode() + ': ' + err.getMessage() + ': ' + err.getFields() + ': ' + ur.getId();
                        exception_List_batch.add(msg);
                    }
					
                    //For test only
                    if(Test.isRunningTest()){
                    	exception_List_batch.add('Test Error1');    
                    }
                }
            }
        }

        if(saveResultList != null){
            for (Database.SaveResult sr: saveResultList) {
                if (!sr.isSuccess() || Test.isRunningTest()) {
                    //Operation failed. Get error details               
                    for(Database.Error err : sr.getErrors()) {
                        String msg = TS_Constants.ERRBATCH_MSG_01 + err.getStatusCode() + ': ' + err.getMessage() + ': ' + err.getFields() + ': ' + sr.getId();
                        exception_List_batch.add(msg);
                    }
					
					//For test only
                    if(Test.isRunningTest()){
                    	exception_List_batch.add('Test Error1');    
                    }
                }
            }            
        }


        //Create custom log record per batch if there is an error.
        if(!exception_List_batch.isEmpty()){
            String mainMessage = '';

            for(String err : exception_List_batch){
                mainMessage = err + '\n';
            }

            //CREATE CUSTOM LOG
            Custom_Log__c log = new Custom_Log__c(
                StackTrace__c = 'TS_ProductSynchronization_Batch ' + description,
                Message__c = mainMessage,
                ExceptionType__c = TS_Constants.DATABASE_ERROR);
            insert log;
        }
    }
}