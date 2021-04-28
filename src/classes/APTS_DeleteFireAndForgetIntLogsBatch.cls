/**
* Class Name : APTS_DeleteFireAndForgetIntLogsBatch
* Description :  Batch Apex Class to delete old Integration Log records of Fire and Forget (F&F) interfaces
* Author : V. Shankaranarayanan (v.shankaranarayanan@accenture.com)
* Date Created : 07-05-2018
**/
global without sharing class APTS_DeleteFireAndForgetIntLogsBatch implements Database.Batchable<sObject>{

    //query to fetch the 'Outbound Message Triggered' Int Logs
    private String query = Label.APTS_IntegrationLogFandFBatchQuery;
    //Do not rename the below set. If renamed, please update 'APTS_IntegrationLogFandFBatchQuery' custom label
    private Set<String> objectNameSet = new Set<String>();
    private Integer deletionAge = 0;
    private Static String EMPTY_STRING = ' ';
    
    /** Method Name : APTS_DeleteFireAndForgetIntLogsBatch
    * Description : Constructor method to build dynamic query
    **/
    public APTS_DeleteFireAndForgetIntLogsBatch(){
        
        //IntegrationUserAndProfile__c custom setting to get the F&F interface deletion day
        IntegrationUserAndProfile__c custSetting = IntegrationUserAndProfile__c.getOrgDefaults();
        
        //APTS_IntegrationLogFireForgetInterfaces__c custom setting to get the list of F&F interfaces
        if(APTS_IntegrationLogFireForgetInterfaces__c.getAll() != null){
            for(APTS_IntegrationLogFireForgetInterfaces__c interfaces : APTS_IntegrationLogFireForgetInterfaces__c.getAll().values()){
                objectNameSet.add(interfaces.Name);
            }
        }
        
        //populating the deletionAge with F&F interface deletion day from IntegrationUserAndProfile__c custom setting
        if(custSetting != null && custSetting.APTS_IntegrationLogFandFDeletionDay__c != null && objectNameSet.size()>0){
            this.deletionAge = Integer.valueOf(custSetting.APTS_IntegrationLogFandFDeletionDay__c);
        }
        
        //query to filter the Int Logs based on the age specified in the IntegrationUserAndProfile__c custom setting
        query += EMPTY_STRING + Label.APTS_IntegrationLogBatchFilter + deletionAge + EMPTY_STRING + Label.APTS_IntegrationLogBatchLimit;
    }
    
    /** Method Name : start
    * Description : start method of Batch class
    **/
    global Database.QueryLocator start(Database.BatchableContext batchContext){
        //querylocator to query the Int Log records using the dynamic 'query' variable
        return Database.getQueryLocator(query);
    }

    /** Method Name : execute
    * Description : execute method of Batch class
    **/
    global void execute(Database.BatchableContext batchContext, List<Integration_Log__c> records){
        //DML to delete the queried Int Logs
        try{
            List<Database.DeleteResult> deleteResult = Database.delete(records, false);
        }catch(DMLException ex){APTS_CustomLogging.createErrorLog('Fire and Forget Batch DML Exception', 'Batch', ex.getMessage(), 'Integration Log', null, 'OM', false, false, null, true);}
    }    

    /** Method Name : finish
    * Description : finish method of Batch class
    **/
    global void finish(Database.BatchableContext batchContext){}

}