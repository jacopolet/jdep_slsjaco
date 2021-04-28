/**********************************************************************************
 * @Author: Balashanthi A
 * @Description: Handles the integreation Log entry for the inserted Admin Orders
 * @Created Date: February 15, 2019
 * @History:
 **********************************************************************************
 *      Name            Version                 Date            Description
 **********************************************************************************
 *      Balashanthi     v100                     15.02.2019        Created
 * V101: Ankit Joshi - 11/4/2019 - To run Recurring Batch for all countires
 * V102: Balashanthi - 08/5/2019 - To run Recurring Batch for all countires 
 **********************************************************************************/
global class APTS_IntegrationLogForBillingBatch implements Database.Batchable<sObject> {
	Set<Id> adminOrderSubmissionToSAP = new Set<Id>();
	public String salesOrgToBeProcessedNext = '';
	
	global APTS_IntegrationLogForBillingBatch(Set<Id> orderIdSet, String salesOrgToBeProcessedNext){
		adminOrderSubmissionToSAP.addAll(orderIdSet);
		this.salesOrgToBeProcessedNext = salesOrgToBeProcessedNext;
		//system.debug('orderIdSet==>'+salesOrgToBeProcessedNext);
	}
	/** Method Name : start
    * Description : start method of Batch class
    **/
	global Database.QueryLocator start(Database.BatchableContext batchContext) {
		
		String query  = 'SELECT Id FROM Apttus_Config2__Order__c';
        query += ' WHERE APTS_Order_Type__c = \'Admin Order\' AND APTS_Order_Sub_Type__c = \'Billing Schedule\'AND CreatedDate >= TODAY';
        query += APTS_BIRUtils.EMPTY_STRING+' AND (APTS_SAP_OrderType__c =  \'XD09\' OR APTS_SAP_OrderType__c =  \'XD12\') AND APTS_Order_Header_SAP_ID__c = null';
        //system.debug('query==>'+query);
		return Database.getQueryLocator(query);
	}
	/** Method Name : execute
    * Description : execute method of Batch class
    **/
	global void execute(Database.BatchableContext BC, List<Apttus_Config2__Order__c> adminOrderInsertedRecords){
		List<Integration_Log__c> listIntegrationLog = new List<Integration_Log__c>();
		try{
			if(!adminOrderInsertedRecords.isEmpty()
				&& !adminOrderSubmissionToSAP.isEmpty()){
				for(Apttus_Config2__Order__c oOrder : adminOrderInsertedRecords){
					if(adminOrderSubmissionToSAP.contains(oOrder.Id)){
						Integration_Log__c oIntegrationLog = new Integration_Log__c();
			            oIntegrationLog.Object_Id__c = oOrder.Id;
			            oIntegrationLog.Object__c = APTS_BIRUtils.ORDEROBJECTNAME; 
			            oIntegrationLog.Integration_Status__c = INT_Constants.INITIAL;
			            oIntegrationLog.Order__c = oOrder.Id;
			            listIntegrationLog.add(oIntegrationLog);
					}
	       		}
			}
			if(!listIntegrationLog.isEmpty()){
           		Database.SaveResult[] srList = Database.insert(listIntegrationLog,false);
            	APTS_BIRUtils.logError(null,srList,null,null,APTS_BIRUtils.BATCH,APTS_BIRUtils.SUBMITORDER,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,false);
        	}
		}catch(Exception e){APTS_BIRUtils.logError(null,null,null,e,APTS_BIRUtils.BATCH,APTS_BIRUtils.SUBMITORDER,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,true);} 
	}
 	/** Method Name : finish
    * Description : finish method of Batch class
    **/
	global void finish(Database.BatchableContext BC){
		//v101 start
        try{
            /*String salesOrg = '';
            Map<String, APTS_Recurring_Batch_Countries__c> countryMap = APTS_Recurring_Batch_Countries__c.getAll();
            Map<Integer, APTS_Recurring_Batch_Countries__c> countrySeqMap = new Map<Integer, APTS_Recurring_Batch_Countries__c>();
            for(APTS_Recurring_Batch_Countries__c rbcRec : countryMap.values()){
                countrySeqMap.put(Integer.valueOf(rbcRec.APTS_Sequence__c), rbcRec);
            }

            APTS_Recurring_Batch_Countries__c rbcRec;
            for(Integer i=1 ; i<=countrySeqMap.size() ; i++){    
                rbcRec = countrySeqMap.get(i);
                if(!(rbcRec.APTS_Processed__c)){
                    if(countrySeqMap.size() >= (i)){
                        salesOrg = countrySeqMap.get(i).APTS_Sales_Org__c;
                        break;
                    }
                }
            }*/
            //system.debug('salesOrg @ Integration log Table ===>'+salesOrgToBeProcessedNext);
            APTS_RecurringBillingScheduleBatchHelper.callRecurringBatchIfReqd(salesOrgToBeProcessedNext);

        }catch(Exception e){APTS_BIRUtils.logError(null,null,null,e,APTS_BIRUtils.BATCH,APTS_BIRUtils.CREATEADMINORDERFINISH,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,true);}
        //v101 end
	}
}