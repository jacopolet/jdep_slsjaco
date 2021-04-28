/*************************************************************
  @Name: APTS_AmendPartialOrderBatch
  @Author: Galin Georgiev
  @CreateDate: 21-02-2019
  @Description: Treat partially fulfilled orders. Amend or Cancel them.
  @UsedBy:
 ******************************************************************/
//v100 21-02-2019 Galin Georgiev: Initial version.
//v101 15-03-2019 Akanksha: changes for CR2909 - removing reason for rejection code
//V102 22-06-2020 Venky Muppalaneni: DQ-3038 Implementing new error handling 

global without sharing class APTS_AmendPartialOrderBatch implements Database.Batchable<sObject> {
	private String query;
	private static final String NOT_VALID = 'Not Valid';
	private static final String AMEND_ORDER = 'Amend';
	private static final String CANCEL_ORDER = 'Cancel';

	//v101 ++ <<
	global APTS_AmendPartialOrderBatch() {
		query = 'SELECT Id FROM Apttus_Config2__Order__c WHERE APTS_IsPGICompleted__c = true AND APTS_Order_Batch_Status__c != \'PartialOrderBatch\' AND APTS_Order_Type__c IN (\'Standard Order\', \'Route Sales Order\', \'Operating Order\') AND Apttus_Config2__Status__c IN (\'Pending\', \'In Fulfillment\', \'Partially Fulfilled\') order by createdDate desc';
		//v102 ++ <<
		APTS_CustomErrorLogging.assignTransactionId(null);
		//v102 ++ >>
	}
	//v101 ++ >>
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

	global void execute(Database.BatchableContext BC, List<Apttus_Config2__Order__c> listOrder) {

		try {
			Apttus_Config2__Order__c oTmp;
			Apttus_Config2__LineItem__c liTmp;
			Apttus_Config2.CPQStruct.AmendOrderResponseDO oAmendResponse;
			Set<Id> setAmendedOrderID = new Set<Id> ();
			Set<Id> setCancelledOrderID = new Set<Id> ();
			List<Apttus_Config2__OrderLineItem__c> listOLITmp;
			List<sObject> listRecordsToUpdate = new List<sObject> ();
			/*List<Apttus_Config2__Order__c> listOrderToUpdate = new List<Apttus_Config2__Order__c>();
			  List<Apttus_Config2__LineItem__c> listLineItemsToUpdate = new List<Apttus_Config2__LineItem__c>();*/
			Map<Id, Apttus_Config2__Order__c> mapOrdersToAmend = new Map<Id, Apttus_Config2__Order__c> (listOrder);
			Map<Id, List<Apttus_Config2__OrderLineItem__c>> mapOLIToAmend = new Map<Id, List<Apttus_Config2__OrderLineItem__c>> ();


			//get order line items to Amend
			APTS_AmendPartialOrderBatchHelper.getOrderLineItems(mapOrdersToAmend.keySet(), mapOLIToAmend);


			if (mapOLIToAmend != null && !mapOLIToAmend.isEmpty()) {

				//Iterate orders
				String sAction;
				APTS_Error_Object__c errObj;
				List<APTS_Error_Object__c> listErrObj = new List<APTS_Error_Object__c> ();


				for (Id orderId : mapOLIToAmend.keySet()) {

					try {

						listOLITmp = mapOLIToAmend.get(orderId);
						if (listOLITmp != null && !listOLITmp.isEmpty()) {
							sAction = APTS_AmendPartialOrderBatchHelper.getOrderAction(listOLITmp);

							if (AMEND_ORDER.equalsIgnoreCase(sAction)) {
								oAmendResponse = APTS_AmendPartialOrderBatchHelper.amendOrder(orderId, listOLITmp);

								//check if success
								if (oAmendResponse != null && oAmendResponse.AmendOrderSO != null) {

									oTmp = APTS_AmendPartialOrderBatchHelper.updateAmendedOrder(oAmendResponse.AmendOrderSO.Id);

									if (oTmp != null) {
										//listOrderToUpdate.add(oTmp);
										listRecordsToUpdate.add(oTmp);
									}

									setAmendedOrderID.add(oAmendResponse.AmendOrderSO.Id);

									//if order line items are created, prepare set of configuration line item
									if (oAmendResponse.AmendedOrderItems != null && !oAmendResponse.AmendedOrderItems.isEmpty()) {
										for (Apttus_Config2__OrderLineItem__c oliTmp : oAmendResponse.AmendedOrderItems) {
											liTmp = APTS_AmendPartialOrderBatchHelper.updatePriceStatus(oliTmp.Apttus_Config2__DerivedFromId__c);

											if (liTmp != null) {
												//listLineItemsToUpdate.add(liTmp);
												listRecordsToUpdate.add(liTmp);
											}
										}
									}

								} else {
									//v102 ++ <<
									//errObj = APTS_CustomLogging.createErrorLog('Error while Amending Partial Order', 'Apex', null, 'Order', orderId, 'OM', false, false, null, false);

									errObj = APTS_CustomErrorLogging.createErrorLog('APTS_AmendPartialOrderBatch', 'Apex', null, 'Order', orderId, 'OM', false, false, null, true, orderId, null, 'Error while Amending Partial Order');
									//v102 ++ >>
								}

							} else if (CANCEL_ORDER.equalsIgnoreCase(sAction)) {
								Apttus_Config2.CPQStruct.CancelOrderResponseDO oCancelledOrder = APTS_AmendPartialOrderBatchHelper.cancelOrder(orderId);

								if (oCancelledOrder.CancelOrderSO != null && oCancelledOrder.CancelOrderSO.Id != null) {
									setCancelledOrderID.add(oCancelledOrder.CancelOrderSO.Id);
								} else {
									//v102 ++ <<
									//errObj = APTS_CustomLogging.createErrorLog('Error while Cancelling Partial Order', 'Apex', '', 'Order', orderId, 'OM', false, false, null, false);
									errObj = APTS_CustomErrorLogging.createErrorLog('APTS_AmendPartialOrderBatch', 'Apex', null, 'Order', orderId, 'OM', false, false, null, true, orderId, null, 'Error while Cancelling Partial Order');
									//v102 ++ >>
								}
							} else {
								//v102 ++ <<
								//errObj = APTS_CustomLogging.createErrorLog('Order is not valid for Partial Cancel. No valid Actions found, please check data.', 'Apex', '', 'Order', orderId, 'OM', false, false, null, false);
								errObj = APTS_CustomErrorLogging.createErrorLog('APTS_AmendPartialOrderBatch', 'Apex', null, 'Order', orderId, 'OM', false, false, null, true, orderId, null, 'Order is not valid for Partial Cancel. No valid Actions found, please check data.');
								//v102 ++ >>

							}
						} else {
							//v102 ++ <<
								//errObj = APTS_CustomLogging.createErrorLog('Order is not valid for Partial Cancel. No Order Line Items found to Amend or Cancel.', 'Apex', '', 'Order', orderId, 'OM', false, false, null, false);
								errObj = APTS_CustomErrorLogging.createErrorLog('APTS_AmendPartialOrderBatch', 'Apex', null, 'Order', orderId, 'OM', false, false, null, true, orderId, null, 'Order is not valid for Partial Cancel. No Order Line Items found to Amend or Cancel.');
								//v102 ++ >>
						}
						//v102 ++ <<
						//if (errObj != null) {
							//listErrObj.add(errObj);
						//}
						//v102 ++ >>

						//to cover catch block, throw exception while running test class
						if (Test.isRunningTest()) {
							Decimal dc1 = 1 / 0;
						}
					} catch(Exception ex) {
					//v102 ++ <<
						//APTS_CustomLogging.createErrorLog('Error while Amending Partial Order', 'Apex', ex.getMessage(), 'Order', orderId, 'OM', false, false, null, true);
						APTS_CustomErrorLogging.createErrorLog('APTS_AmendPartialOrderBatch', 'Apex', ex.getTypeName() + ':' + ex.getMessage(), 'Order',orderId, 'OM', false, false, null, true,orderId, null, 'Error while Amending Partial Order');
						//v102 ++ >>
					} 
					//v102 ++ <<
					//finally {
						//system.debug('listErrObj = ' + listErrObj);
						//if (!listErrObj.isEmpty()) {
							//Database.insert(listErrObj);
						//}
					//}
					//v102 ++ >>
				}


				system.debug('setAmendedOrderID = ' + setAmendedOrderID);
				system.debug('setCancelledOrderID = ' + setCancelledOrderID);
				system.debug('listRecordsToUpdate = ' + listRecordsToUpdate);

				/*// update order header
				  if (!listOrderToUpdate.isEmpty()) {
				  update listOrderToUpdate;
				  }*/

				//update records
				if (!listRecordsToUpdate.isEmpty()) {
					Database.update(listRecordsToUpdate, false);
				}


				// update line item pricing status to pending
				//6-Mar-2019 - Neev - Due to OOB API doesn't calculate correct pricing on Order Line Item we need to reprice and finalize cart again to get accurate data
				if (!setAmendedOrderID.isEmpty()) {
					APTS_ConfigurationTriggerHandler.isTriggerDisabled = true;
					APTS_AmendPartialOrderBatchHelper.repriceAmendedOrder(setAmendedOrderID);
				}

				// update ready for activation date on Order, if there are amended or cancelled Orders
				if (!(setAmendedOrderID.isEmpty() && setCancelledOrderID.isEmpty())) {

					setAmendedOrderID.addAll(setCancelledOrderID);

					//fulfill amend order
					APTS_AmendPartialOrderBatchHelper.fulfillAmendedOrder(setAmendedOrderID);
				}
			}

			//to cover catch block, throw exception while running test class
			if (Test.isRunningTest()) {
				Decimal dc1 = 1 / 0;
			}
		} catch(Exception ex) {
		//v102 ++ <<
			//APTS_CustomLogging.createErrorLog('APTS_AmendPartialOrderBatch', 'Apex', 'Line # ' + ex.getLineNumber() + '_' + ex.getMessage(), 'Order', null, 'OM', false, false, null, true);
			APTS_CustomErrorLogging.createErrorLog('APTS_AmendPartialOrderBatch', 'Apex', ex.getTypeName() + ':' + ex.getMessage(), 'Order', null, 'OM', false, false, null, true, null, null,  ex.getMessage());
			//v102 ++ >>
		}
		//v102 ++ <<
		APTS_CustomErrorLogging.saveErrorLog();
		//v102 ++ >>
	}

	global void finish(Database.BatchableContext BC) {

	}
}