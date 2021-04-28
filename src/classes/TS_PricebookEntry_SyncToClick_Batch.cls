/**
* @author        Marvin Gatchalian
* @date          5.mar.2018
* @description   Apex batch is used to create integration log per pricebookentry at 100 records per batch 
*                This batch should be called by scheduler and should parameterized by 100 records per batch.
* @revision(s)   6.08.2018 Paul Aguiling: KTS-1804 Modified getQuery()
*/

global with sharing  class TS_PricebookEntry_SyncToClick_Batch implements Database.Batchable<sObject>{
    
    /******************************************************************************
    * @author         Marvin Gatchalian
    * @date           5.mar.2018
    * @description    This method is the start of the batch job
    * @revision(s)
    ******************************************************************************/ 
    global Database.QueryLocator start(Database.BatchableContext BC) {
        CustomLogging.push('start', 'TS_PricebookEntry_SyncToClick_Batch');
        CustomLogging.pop();
        return Database.getQueryLocator(getQuery());
    }
    
    /******************************************************************************
    * @author         Marvin Gatchalian
    * @date           5.mar.2018
    * @description    This method returns a SQL syntax on not synchronized pricebookentry
    * @revision(s)
    ******************************************************************************/ 
    String getQuery(){
        CustomLogging.push('getQuery', 'TS_PricebookEntry_SyncToClick_Batch');
        DescribeSObjectResult priceBookEntries = pricebookentry.getSObjectType().getDescribe();
        List <String> fields = new List<String>(priceBookEntries.fields.getMap().keySet());
        
        CustomLogging.pop();
        return 'SELECT ' + String.join(fields,',') + 
               ' FROM ' + priceBookEntries.getName() + 
               ' WHERE TS_Click_Synchronized__c = false AND TS_Load_Id__c != null ' +
               ' AND Product2.APTS_Material_Type__c IN (\'ZSPR\', \'ZSER\') ' + 
               ' AND TS_Click__c = true ';
    }
    
    
    /******************************************************************************
    * @author         Marvin Gatchalian
    * @date           5.mar.2018
    * @description    This method proceses the result of query.  
    *                 
    * @revision(s)
    ******************************************************************************/ 
    global void execute(Database.BatchableContext BC, List<pricebookentry> priceBookEntries) {
        CustomLogging.push('execute', 'TS_PricebookEntry_SyncToClick_Batch');
        
        //Variable Initialization
        TS_PricebookEntry_SyncToClick_Execute tsExecute = new TS_PricebookEntry_SyncToClick_Execute();
        Map <pricebookentry, Integration_Log__c> priceBookEntryIntegrationLogMap = new 
        Map <pricebookentry, Integration_Log__c>();
        List <pricebookentry> priceBookEntriesToBeUpdated = new List <pricebookentry>();
        Boolean hasErrorDuringInsert = false;
        
        
        priceBookEntryIntegrationLogMap = tsExecute.createIntegrationLogPerPriceBookEntry (priceBookEntries);
        
        if (!priceBookEntryIntegrationLogMap.values().isEmpty() && Schema.sObjectType.pricebookentry.isCreateable()) {
            Database.SaveResult[] saveResults = Database.insert(priceBookEntryIntegrationLogMap.values(), false);
            
             //Karen Hung DOO-3536 Error handling through custom log
             INSERT_LOGGING(saveResults, 'Error in inserting Integration Log');  

            for (Database.SaveResult ds :saveResults){
                if (!ds.isSuccess()) {
                    // system.debug('Error in inserting Integration Log  >>>>>  '+ ds);
                     hasErrorDuringInsert = true;            
                }
            }                       
        }
        
        //Update pricebookentries to mark Click Synchronized field to 'True'
        if (!hasErrorDuringInsert && !priceBookEntryIntegrationLogMap.keySet().isEmpty()) {
            priceBookEntriesToBeUpdated.addAll(priceBookEntryIntegrationLogMap.keySet());
            Database.SaveResult[] saveResults = Database.update(priceBookEntriesToBeUpdated, false);
            
            //Karen Hung DOO-3536 Error handling through custom log
            INSERT_LOGGING(saveResults, 'Error in updating price book entry.'); 

           /* for (Database.SaveResult ds :saveResults){
                if (!ds.isSuccess()) system.debug('Error in updating price book entry. '+ ds);
            }*/   
        }
         
        CustomLogging.pop();
    }
    
    /******************************************************************************
    * @author         Marvin Gatchalian
    * @date           5.mar.2018
    * @description    This method to perform actions when the batch is finished
    * @revision(s)
    ******************************************************************************/ 
    global void finish(Database.BatchableContext BC) {
        CustomLogging.push('finish', 'TS_PricebookEntry_SyncToClick_Batch');
        CustomLogging.pop();
    }

    /******************************************************************************
     * Karen Hung DOO-3536
     * 17.02.2020   Method to create a custom log record if there is failed record processed in the batch execution.
     ******************************************************************************/
    public void INSERT_LOGGING ( List<Database.SaveResult> saveResultList,  String description) {

        //Custom Logging for Database.Error
        Set<String> exception_List_batch = new Set<String>();

        /* Create error message to each Database.Error. */
        for (Database.SaveResult sr: saveResultList) {
            if (!sr.isSuccess() || Test.isRunningTest()) {
                //Operation failed. Get error details               
                for(Database.Error err : sr.getErrors()) {
                    String msg = TS_Constants.ERRBATCH_MSG_01 + err.getStatusCode() + ': ' + err.getMessage() + ': ' + err.getFields() + ': ' + sr.getId();
                    exception_List_batch.add(msg);
                }
                
                //For Test Class only
                if(Test.isRunningTest()){
					exception_List_batch.add('Test Error');                    
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
                StackTrace__c = 'TS_PricebookEntry_SyncToClick_Batch ' + description,
                Message__c = mainMessage,
                ExceptionType__c = TS_Constants.DATABASE_ERROR);
            insert log;
        }
    }
    
}