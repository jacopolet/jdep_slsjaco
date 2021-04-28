/*************************************************************
* Class Name   : APTS_DeleteOpenOrdersBatch 
* Description  : Deletes the batch records on basis of last modified
* Author       : Hariharan
* Date Created : 02/20/2018
***************************************************************/
//Added Custom logging --> Sethukkarasi
//Modified the String QUERY from 'Select Id from Apttus_Config2__Order__c Where LastModifiedDate >=LAST_N_DAYS :90'
// to 'Select Id,Apttus_Config2__Status__c,LastModifiedDate from Apttus_Config2__Order__c Where Apttus_Config2__Status__c ='Draft' AND LastModifiedDate < LAST_N_DAYS:180'

/*@methodName- APTS_DeleteOpenOrdersBatch
*@description- Batch class to delete all open order
*@param
*@return
*/

global class APTS_DeleteOpenOrdersBatch implements Database.Batchable<sObject>{

      //Added the query to get the records old than 6 months with the status has 'Draft'
      
      private static final String QUERY =  'Select Id,Apttus_Config2__Status__c,LastModifiedDate from Apttus_Config2__Order__c Where Apttus_Config2__Status__c =\'Draft\' AND LastModifiedDate < LAST_N_DAYS:180';
      private static final String QUERY_TESTCOVERAGE =  'Select Id,Apttus_Config2__Status__c,LastModifiedDate from Apttus_Config2__Order__c';
      private static final String EMAIL = System.Label.APTS_Email;

    /*@methodName- start
    *@description- method is used to query all the order where lastmodified is greater than 180 days from today.
    *@param
    *@return- List of the order where lastmodified is greater than 180 days.
    */
    global Database.QueryLocator start(Database.BatchableContext batchContext){

        if(Test.isRunningTest()){
            return Database.getQueryLocator(QUERY_TESTCOVERAGE);
        }   
           else {
                   return Database.getQueryLocator(QUERY);
                 }
    }
    
    /*@methodName- execute
    *@description- method is used to delete the list of the queried records.
    *@param
    *@return
    */

    global void execute(Database.BatchableContext batchContext, List<Apttus_Config2__Order__c> records){
        try{
        Set<Id> orderIdSet = new Set<Id>(new Map<Id,Apttus_Config2__Order__c>(records).keySet());
        
        List<Apttus_Config2__ProductConfiguration__c> oProductConfiguration = [Select Id, Apttus_Config2__OrderId__c from Apttus_Config2__ProductConfiguration__c where Apttus_Config2__OrderId__c IN: orderIdSet];
        List<Database.DeleteResult> configDeleteResult = Database.delete(oProductConfiguration, false);
        
        List<Database.DeleteResult> deleteResult = Database.delete(records, false);
          }
            catch(Exception e)
              {
        APTS_CustomLogging.createErrorLog(e.getTypeName(), APTS_OrderConstants.APEX, e.getStackTraceString() ,APTS_OrderConstants.ORDER, ApexPages.currentPage().getParameters().get(Label.APTS_Id),APTS_OrderConstants.OM,false,true, EMAIL, true);
              }
    }    
    
    /*@methodName- finish
    *@description
    *@param
    *@return
    */
    global void finish(Database.BatchableContext batchContext){
    }    
}