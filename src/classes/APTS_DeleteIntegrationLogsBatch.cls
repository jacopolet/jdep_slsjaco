/**
* Class Name : APTS_DeleteIntegrationLogsBatch
* Description :  Batch Apex Class to delete old Integration Log records
* Author : V. Shankaranarayanan (v.shankaranarayanan@accenture.com)
* Date Created : 01/31/2018
**/
global without sharing class APTS_DeleteIntegrationLogsBatch implements Database.Batchable<sObject>{

    private String query = Label.APTS_IntegrationLogBatchQuery;
    private String interfaceType;
    private Integer deletionAge;
    private Static String EMPTY_STRING = ' ';
    
    /** Method Name : APTS_DeleteIntegrationLogsBatch
    * Description : Constructor method to build dynamic query
    **/
    public APTS_DeleteIntegrationLogsBatch(String type, Integer age){
        this.interfaceType = type;
        this.deletionAge = age;
        if(String.isNotBlank(interfaceType) && !interfaceType.equals(Label.APTS_IntegrationLogBatchTypeAll)){
            query += EMPTY_STRING + Label.APTS_IntegrationLogBatchTypeFilter + interfaceType + Label.APTS_IntegrationLogBatchWildcard;
        }
        query += EMPTY_STRING + Label.APTS_IntegrationLogBatchFilter + age + EMPTY_STRING + Label.APTS_IntegrationLogBatchLimit;
    }
    
    /** Method Name : start
    * Description : start method of Batch class
    **/
    global Database.QueryLocator start(Database.BatchableContext batchContext){
        return Database.getQueryLocator(query);
    }

    /** Method Name : execute
    * Description : execute method of Batch class
    **/
    global void execute(Database.BatchableContext batchContext, List<Integration_Log__c> records){
        try{
            List<Database.DeleteResult> deleteResult = Database.delete(records, false);
        }catch(DMLException ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Batch Apex', ex.getStackTraceString(), 'APTS_DeleteIntegrationLogsBatch', null, 'OM', false, false, null, true);}
    }    

    /** Method Name : finish
    * Description : finish method of Batch class
    **/
    global void finish(Database.BatchableContext batchContext){}    

}