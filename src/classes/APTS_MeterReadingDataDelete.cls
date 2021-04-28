/**
* Class Name : APTS_MeterReadingDataDelete
* Description : Batch Class to delete the Meter Reading Data which was created before 30 days                     
* Author : Kiruthika Pachaimaal
* Date Created : 11/05/2018
**/
global class APTS_MeterReadingDataDelete implements Database.Batchable<sObject>{
    
    private String query;
    private DateTime dateValue = Date.today().addDays(-30);
    private static final String METERREADINGERRORSTRING = 'execute() in APTS_MeterReadingDataDelete'; 
    
    /**
    * Method Name : global APTS_MeterReadingDataDelete(String soql)
    * Description : Constructor to initialize query variable which is passed from APTS_MeterRdngDtDeltSchedule
    * Author : Kiruthika Pachaimaal
    * Date Created : 11/05/2018
    **/   
    global APTS_MeterReadingDataDelete(String soql){
        query = soql;
    } 
    
    /**
    * Method Name : global Database.QueryLocator start(Database.BatchableContext bc)
    * Description : Batch Class start() Method to set the query to retrieve bulk Meter Reading Data records
    * Author : Kiruthika Pachaimaal
    * Date Created : 11/05/2018
    **/   
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    
    /**
    * Method Name : global void execute(Database.BatchableContext BC, List<APTS_Meter_Reading_Data__c> scope)
    * Description : Batch Class execute() Method to retrieve queried records and delete it
    * Author : Kiruthika Pachaimaal
    * Date Created : 11/05/2018
    **/   
    global void execute(Database.BatchableContext BC, List<APTS_Meter_Reading_Data__c> scope){
        List<Database.DeleteResult> listDeleteResult = new List<Database.DeleteResult>();
        List<APTS_Error_Object__c> lstErrorObject = new List<APTS_Error_Object__c>();

        try{
            listDeleteResult = Database.delete(scope); 
            APTS_BIRUtils.logError(listDeleteResult,null,null,null,APTS_BIRUtils.BATCH,METERREADINGERRORSTRING,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,true);
        }
        catch(Exception excp){
           APTS_BIRUtils.logError(null,null,null,excp,APTS_BIRUtils.BATCH,METERREADINGERRORSTRING,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,true);
        }
    }
    
    /**
    * Method Name : global void finish(Database.BatchableContext bc)
    * Description : Batch Class finish() Method to Monitor and Track the Batch job execution
    * Author : Kiruthika Pachaimaal
    * Date Created : 11/05/2018
    **/
    global void finish(Database.BatchableContext bc){
        AsyncApexJob job = [SELECT Id, Status FROM AsyncApexJob WHERE Id = :bc.getJobId()]; 
    }
}