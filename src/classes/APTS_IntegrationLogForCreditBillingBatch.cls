/**********************************************************************************
 * @Author: Renuka
 * @Description: Handles the integreation Log entry for the inserted Admin Orders XC09
 * @Created Date: 28/07/2020
 * @History:
  **********************************************************************************/
global class APTS_IntegrationLogForCreditBillingBatch implements Database.Batchable<sObject> {

    Set<Id> adminOrderSubmissionToSAP = new Set<Id>();
    public String salesOrgToBeProcessedNext = '';
  
    global APTS_IntegrationLogForCreditBillingBatch(Set<Id> orderIdSet, String salesOrgToBeProcessedNext){
        adminOrderSubmissionToSAP.addAll(orderIdSet);
        this.salesOrgToBeProcessedNext = salesOrgToBeProcessedNext;
        //system.debug('orderIdSet==>'+salesOrgToBeProcessedNext);
    }
    /** Method Name : start
    * Description : start method of Batch class
    **/
    global Database.QueryLocator start(Database.BatchableContext batchContext) {

        String query  = 'SELECT Id,APTS_Number_of_Unfulfilled_Line_Item__c FROM Apttus_Config2__Order__c';
            query += ' WHERE APTS_Order_Type__c = \'Admin Order\' AND APTS_Order_Sub_Type__c = \'Billing Schedule\'AND CreatedDate >= TODAY';
            query += APTS_BIRUtils.EMPTY_STRING+' AND (APTS_SAP_OrderType__c =  \'XC09\') AND APTS_Order_Header_SAP_ID__c = null';
            //system.debug('query==>'+query);
        return Database.getQueryLocator(query);
    }
    /** Method Name : execute
    * Description : execute method of Batch class
    **/
    global void execute(Database.BatchableContext BC, List<Apttus_Config2__Order__c> adminOrderInsertedRecords){
    List<Integration_Log__c> listIntegrationLog = new List<Integration_Log__c>();
    List<Apttus_Config2__Order__c> deleteEmptyOrderList = new List<Apttus_Config2__Order__c>();
    try{
        if(!adminOrderInsertedRecords.isEmpty()
        && !adminOrderSubmissionToSAP.isEmpty()){
            for(Apttus_Config2__Order__c oOrder : adminOrderInsertedRecords){
                if(adminOrderSubmissionToSAP.contains(oOrder.Id) && oOrder.APTS_Number_of_Unfulfilled_Line_Item__c!=NULL 
                    && oOrder.APTS_Number_of_Unfulfilled_Line_Item__c >0){
                    Integration_Log__c oIntegrationLog = new Integration_Log__c();
                    oIntegrationLog.Object_Id__c = oOrder.Id;
                    oIntegrationLog.Object__c = APTS_BIRUtils.ORDEROBJECTNAME; 
                    oIntegrationLog.Integration_Status__c = INT_Constants.INITIAL;
                    oIntegrationLog.Order__c = oOrder.Id;
                    listIntegrationLog.add(oIntegrationLog);
                }else if(adminOrderSubmissionToSAP.contains(oOrder.Id) && oOrder.APTS_Number_of_Unfulfilled_Line_Item__c!=NULL 
                    && oOrder.APTS_Number_of_Unfulfilled_Line_Item__c ==0){
                    deleteEmptyOrderList.add(oOrder);
                }
            }
        }
        if(!listIntegrationLog.isEmpty()){
           Database.SaveResult[] srList = Database.insert(listIntegrationLog,false);
           APTS_BIRUtils.logError(null,srList,null,null,APTS_BIRUtils.BATCH,APTS_BIRUtils.SUBMITORDER,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,false);
        }
        if(!deleteEmptyOrderList.isEmpty()){
           APTS_OrderUtils.stopOrderTrigger();
           Database.DeleteResult[] srList = Database.delete(deleteEmptyOrderList,false);
           APTS_BIRUtils.logError(srList,null,null,null,APTS_BIRUtils.BATCH,APTS_BIRUtils.SUBMITORDER,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,false);
           APTS_OrderUtils.startOrderTrigger();
        }
    }catch(Exception e){APTS_BIRUtils.logError(null,null,null,e,APTS_BIRUtils.BATCH,APTS_BIRUtils.SUBMITORDER,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,true);} 
    }
    /** Method Name : finish
    * Description : finish method of Batch class
    **/
    global void finish(Database.BatchableContext BC){
    //v101 start
    try{
        //system.debug('salesOrg @ Integration log Table ===>'+salesOrgToBeProcessedNext);
        APTS_CreditBillingBatchHelper.callRecurringBatchIfReqd(salesOrgToBeProcessedNext);

    }catch(Exception e){APTS_BIRUtils.logError(null,null,null,e,APTS_BIRUtils.BATCH,APTS_CreditBillingBatch.CREATEADMINORDERFINISH,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,true);}
    //v101 end
    }
}