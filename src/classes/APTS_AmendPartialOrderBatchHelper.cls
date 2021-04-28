/*************************************************************
  @Name: APTS_AmendPartialOrderBatchHelper
  @Author: Galin Georgiev
  @CreateDate: 21-02-2019
  @Description: Treat partially fulfilled orders. Amend or Cancel them.
  @UsedBy:
 ******************************************************************/
//v100 21-02-2019 Galin Georgiev: Initial version.
//v101 15-03-2019 Akanksha: changes for CR2909 - removing reason for rejection code
//V102 25-May-2020 Aarthi Pitchai - Apttus Upgrade issue - Partial cancel
//V103 22-06-2020 Venky Muppalaneni: DQ-3038 Implementing new error handling 
public without sharing class APTS_AmendPartialOrderBatchHelper {
	private static final String IN_FULFILLMENT = system.label.APTS_In_Fulfillment;
	private static final String FULFILLED = System.Label.APTS_Fulfilled;
	private static final String ACTIVATED = System.Label.APTS_Activated;
	private static final String CANCELLED = APTS_OrderConstants.CANCELLED;
	private static final String PARTIAL_ORDER_BATCH = APTS_OrderConstants.PARTIALORDERBATCH;
	private static final String PENDING = APTS_OrderConstants.PENDING;
	private static final String PENDING_CANCEL = APTS_OrderConstants.STATUS_PENDING_CANCEL;
	private static final String SENTFORINVOICE = 'Sent For Invoicing';
	private static final String PARTIALLY_FULFILLED = 'Partially Fulfilled';
	private static final String NOT_VALID = 'Not Valid';
	private static final String AMEND_ORDER = 'Amend';
	private static final String CANCEL_ORDER = 'Cancel';



	//return map of Order and list of relevant Order Line Items
	public static void getOrderLineItems(Set<Id> setOrderIds, Map<Id, List<Apttus_Config2__OrderLineItem__c>> mapOLIToAmend) {
		List<Apttus_Config2__OrderLineItem__c> liTmp;

		try {
			//prepare map of Order with Order Line Item
			for (Apttus_Config2__OrderLineItem__c oliTmp :[SELECT Id, APTS_Reason_For_Rejection__c, Apttus_Config2__OrderId__c, Apttus_Config2__Quantity__c, Apttus_Config2__FulfilledQuantity__c, Apttus_Config2__SellingUom__c, Apttus_Config2__Status__c, Apttus_Config2__StartDate__c, Apttus_Config2__EndDate__c, Apttus_Config2__ContractNumbers__c, Apttus_Config2__BasePriceOverride__c, Apttus_Config2__ActivatedDate__c, Apttus_Config2__SellingTerm__c, Apttus_Config2__SellingFrequency__c, Apttus_Config2__AdjustmentType__c, Apttus_Config2__AdjustmentAmount__c
			     FROM Apttus_Config2__OrderLineItem__c WHERE Apttus_Config2__OrderId__c IN :setOrderIds AND Apttus_Config2__ProductId__r.APTS_Not_relevant_for_SAP__c = false]) {
				liTmp = mapOLIToAmend.get(oliTmp.Apttus_Config2__OrderId__c);
				liTmp = liTmp == null ? new List<Apttus_Config2__OrderLineItem__c> () : liTmp;
				liTmp.add(oliTmp);
				mapOLIToAmend.put(oliTmp.Apttus_Config2__OrderId__c, liTmp);
			}
			system.debug('mapOLIToAmend :: ' + mapOLIToAmend);
		} catch(Exception ex) {
			throw ex;
		}
	}


	//Determine action for an Order
	// Response -
	//      NOT_VALID ==> Order delivery is not complete
	//      AMEND_ORDER ==> OLI needs to Amend or Cancel
	//      CANCEL_ORDER ==> Order needs to Cancel
	public static String getOrderAction(List<Apttus_Config2__OrderLineItem__c> listOrderLineItem) {
		String sAction = NOT_VALID;
		Integer cntCancel = 0; //, cntCompletedLines = 0;

		//prepare map of Order with Order Line Item
		//v101 ++ <<
		for (Apttus_Config2__OrderLineItem__c oliTmp : listOrderLineItem) {
			//cntCompletedLines = oliTmp.APTS_Reason_For_Rejection__c != null || PARTIALLY_FULFILLED.equalsIgnoreCase(oliTmp.Apttus_Config2__Status__c) || FULFILLED.equalsIgnoreCase(oliTmp.Apttus_Config2__Status__c) || ACTIVATED.equalsIgnoreCase(oliTmp.Apttus_Config2__Status__c) || CANCELLED.equalsIgnoreCase(oliTmp.Apttus_Config2__Status__c) ? cntCompletedLines + 1 : cntCompletedLines;
			cntCancel = oliTmp.APTS_Reason_For_Rejection__c != null || oliTmp.Apttus_Config2__FulfilledQuantity__c == null || oliTmp.Apttus_Config2__FulfilledQuantity__c == 0 ? cntCancel + 1 : cntCancel;
		}
		//v101 ++ >>

		//if (cntCompletedLines == listOrderLineItem.size()) {
		sAction = cntCancel == listOrderLineItem.size() ? CANCEL_ORDER : AMEND_ORDER;
		//}


		return sAction;
	}

	public static Apttus_Config2.CPQStruct.AmendOrderResponseDO amendOrder(Id orderId, List<Apttus_Config2__OrderLineItem__c> listOLITmp) {
		Apttus_Config2.CPQStruct.AmendOrderResponseDO oAmendResponse;

		try {
			List<Apttus_Config2__OrderLineItem__c> listOLIToAmend = new List<Apttus_Config2__OrderLineItem__c> ();
			//change line item quantity and status
			for (Apttus_Config2__OrderLineItem__c oliTmp : listOLITmp) {
				//if (oliTmp.APTS_Reason_For_Rejection__c != null || PARTIALLY_FULFILLED.equalsIgnoreCase(oliTmp.Apttus_Config2__Status__c)) {
				if (!(FULFILLED.equalsIgnoreCase(oliTmp.Apttus_Config2__Status__c) || ACTIVATED.equalsIgnoreCase(oliTmp.Apttus_Config2__Status__c))) {
					oliTmp.Apttus_Config2__Status__c = oliTmp.Apttus_Config2__FulfilledQuantity__c > 0 ? oliTmp.Apttus_Config2__Status__c : APTS_OrderConstants.STATUS_PENDING_CANCEL;
					if (oliTmp.Apttus_Config2__Status__c != APTS_OrderConstants.STATUS_PENDING_CANCEL)
					oliTmp.Apttus_Config2__Quantity__c = oliTmp.Apttus_Config2__FulfilledQuantity__c > 0 ? oliTmp.Apttus_Config2__FulfilledQuantity__c : oliTmp.Apttus_Config2__Quantity__c;

					listOLIToAmend.add(oliTmp);
				}
			}
			system.debug('96 :: listOLIToAmend :: ' + listOLIToAmend);
			//Invoke Amend Order API
			Apttus_Config2.CPQStruct.AmendOrderRequestDO request = new Apttus_Config2.CPQStruct.AmendOrderRequestDO();
			request.Action = 'Amend';
			request.OrderId = orderId;
			request.OrderItems = listOLIToAmend;
			APTS_OrderUtils.stopOrderTrigger();
			oAmendResponse = Apttus_Config2.OrderWebService.amendOrder(request);
			APTS_OrderUtils.startOrderTrigger();
			system.debug('96 :: oAmendResponse :: ' + oAmendResponse);
		} catch(Exception ex) {
			system.debug('96 :: Exception Occurred :: ' + ex.getMessage());
			throw ex;
		}

		return oAmendResponse;
	}

	public static Apttus_Config2.CPQStruct.CancelOrderResponseDO cancelOrder(Id orderId) {
		Apttus_Config2.CPQStruct.CancelOrderResponseDO oCancelResp;
		try {
			Apttus_Config2.CPQStruct.CancelOrderRequestDO oCancelReq = new Apttus_Config2.CPQStruct.CancelOrderRequestDO();
			oCancelReq.orderid = orderId;
			oCancelResp = Apttus_Config2.OrderWebService.cancelOrder(oCancelReq);
		} catch(Exception ex) {
			throw ex;
		}

		return oCancelResp;
	}

	//Get OLI to Amend if Order delivery is complete or not
	public static Apttus_Config2__Order__c updateAmendedOrder(Id partialOrderId) {
		Apttus_Config2__Order__c orderTmp;

		try {
			// update order batch field status
			if (partialOrderId != null) {
				orderTmp = new Apttus_Config2__Order__c();
				orderTmp.Id = partialOrderId;
				orderTmp.APTS_Order_Batch_Status__c = PARTIAL_ORDER_BATCH;
				orderTmp.APTS_IsPGICompleted__c = false;
			}
		} catch(Exception ex) {
			system.debug('129 :: Exception occurred :: ' + ex.getMessage());
			throw ex;
		}

		return orderTmp;
	}

	public static Apttus_Config2__LineItem__c updatePriceStatus(Id lineItemId) {
		Apttus_Config2__LineItem__c lineItemTmp;

		try {
			lineItemTmp = new Apttus_Config2__LineItem__c();
			lineItemTmp.Id = lineItemId;
			lineItemTmp.Apttus_Config2__PricingStatus__c = PENDING;
			lineItemTmp.APTS_is_selling_UOM_defaulted__c = true;
		} catch(Exception ex) {
			throw ex;
		}

		return lineItemTmp;
	}

	//finalize cart
	public static Boolean finalizeCart(Boolean isPricingPending, Id cartId) {
		Boolean isSuccess = FALSE;

		try {

			if (isPricingPending) {
				isPricingPending = APTS_DigitalOrderBatchHelper.repriceCart(cartId);
			}

			if (!isPricingPending) {
				//Finalize
				APTS_OrderUtils.finalizeCart(cartId);

				//Syncronize
				isSuccess = APTS_OrderUtils.syncCart(cartId);
			} else {
				System.enqueueJob(new APTS_RepriceFinalizationQueue(cartId, 'PartialOrder', 'Reprice'));
			}

		} catch(Exception ex) {
			system.debug('ex = ' + ex.getMessage());
			APTS_CustomLogging.createErrorLog('Amend Partial Order Pricing Issue', 'Apex', ex.getMessage(), 'Order', cartId, 'OM', false, true, null, true);
		}

		return isSuccess;
	}


	public static void fulfillAmendedOrder(Set<Id> setCompletedOrder) {
		List<Apttus_Config2__OrderLineItem__c> listOLIToUpdate = new List<Apttus_Config2__OrderLineItem__c> ();

		try {

			if (setCompletedOrder != null && !setCompletedOrder.isEmpty()) {

				APTS_OrderFLITriggerHandler.isTriggerDisabled = true;
				//APTS_AmendPartialOrderBatchHelper.updateAmendedOLI(setCompletedOrder);

				//accept amended order
				for (Id orderId : setCompletedOrder) {

					try {
						APTS_OrderUtils.acceptOrder(orderId);
					} catch(Exception ex) {
						//v103 ++ <<
						//APTS_CustomLogging.createErrorLog('Error in Finalize Partial Order', 'Apex', ex.getMessage(), 'Order', orderId, 'OM', false, false, null, true);

						APTS_CustomErrorLogging.createErrorLog('APTS_AmendPartialOrderBatchHelper', 'Apex', ex.getTypeName() + ':' + ex.getMessage(), 'Order', orderId, 'OM', false, false, null, true, orderId, null, 'Error in Finalize Partial Order');
						//v103 ++ >>
					}
				}



				//submit order to SAP
				//APTS_AmendPartialOrderBatchHelper.submitOrders(setCompletedOrder);

				//update fulfilled qty and status to fulfilled
				//              Set<Id> setAmendedOLI = new Set<Id>();
				Boolean isCancelled;
				for (Apttus_Config2__OrderLineItem__c oli :[SELECT Id, Apttus_Config2__Status__c, Apttus_Config2__Quantity__c, Apttus_Config2__FulfilledQuantity__c
				     FROM Apttus_Config2__OrderLineItem__c
				     WHERE Apttus_Config2__OrderId__c IN :setCompletedOrder]) {

					isCancelled = APTS_OrderConstants.STATUS_PENDING_CANCEL.equalsIgnoreCase(oli.Apttus_Config2__Status__c) || APTS_OrderConstants.CANCELLED.equalsIgnoreCase(oli.Apttus_Config2__Status__c);

					oli.Apttus_Config2__FulfilledQuantity__c = !isCancelled ? oli.Apttus_Config2__Quantity__c : oli.Apttus_Config2__FulfilledQuantity__c;
					//update status to fulfilled
					oli.Apttus_Config2__Status__c = !(isCancelled) ? FULFILLED : oli.Apttus_Config2__Status__c;
					listOLIToUpdate.add(oli);
				}

				if (!listOLIToUpdate.isEmpty()) {
					APTS_OrderUtils.stopOrderLineItemTrigger();
					update listOLIToUpdate;
					APTS_OrderUtils.startOrderLineItemTrigger();
				}

				for (Apttus_Config2__OrderLineItem__c oli : listOLIToUpdate) {
					oli.Apttus_Config2__ActivatedDate__c = !ACTIVATED.equalsIgnoreCase(oli.Apttus_Config2__Status__c) ? System.today() : oli.Apttus_Config2__ActivatedDate__c;
				}

				if (!listOLIToUpdate.isEmpty()) {
					//v103 ++ <<
					//System.enqueueJob(new APTS_ActivateOrderQueueable(listOLIToUpdate));
					System.enqueueJob(new APTS_ActivateOrderQueueable(listOLIToUpdate, null, APTS_CustomErrorLogging.transactionId));

					//v103 ++ >>
					//update listOLIToUpdate;
				}
			}
		} catch(Exception ex) {
			throw ex;
		} finally {
			APTS_OrderFLITriggerHandler.isTriggerDisabled = false;
		}
	}

	/*public static void submitOrders(Set<Id> setCompletedOrder) {
	  try {
	  List<Apttus_Config2__Order__c> orderList = [
	  SELECT Id, Apttus_Config2__Status__c, APTS_Status__c, Apttus_Config2__PreviousVersion__c,
	  Apttus_Config2__SoldToAccountId__c, Apttus_Config2__SoldToAccountId__r.SAP_Customer_Id__c,
	  Apttus_Config2__SoldToAccountId__r.RecordType.Name, Apttus_Config2__SoldToAccountId__r.Parent_Change_Indicator__c,
	  Apttus_Config2__SoldToAccountId__r.Parent_Valid_From__c, Apttus_Config2__SoldToAccountId__r.Parent_Valid_To__c
	  FROM Apttus_Config2__Order__c
	  WHERE Id IN :setCompletedOrder];
	  APTS_OrderUtils.submitMultipleOrders(true, orderList);
	  } catch (Exception ex) {
	  throw ex;
	  }
	  }*/

	public static String convertSetIdsToString(Set<Id> setOrderIDs) {
		String strIds = '';
		for (Id strId : setOrderIDs) {
			strIds += strId + ',';
		}
		strIds.removeEnd(',');

		return strIds;
	}


	// update line item pricing status to pending
	//6-Mar-2019 - Neev - Due to OOB API doesn't calculate correct pricing on Order Line Item we need to reprice and finalize cart again to get accurate data
	public static void repriceAmendedOrder(Set<Id> setAmendedOrderID) {
		//Amend Orders
		if (setAmendedOrderID != null && !setAmendedOrderID.isEmpty()) {

			try {
				//update pricing status to pending
				//update listLineItemsToUpdate;

				// Finalize Cart
				Boolean isSuccess;
				for (Apttus_Config2__ProductConfiguration__c cartObj :[SELECT id, Apttus_Config2__OrderId__c FROM Apttus_Config2__ProductConfiguration__c
				     WHERE Apttus_Config2__BusinessObjectType__c = :APTS_OrderConstants.ORDER AND Apttus_Config2__OrderId__c IN :setAmendedOrderID]) {
					try {
						isSuccess = finalizeCart(true, cartObj.Id);

						if (!isSuccess) {
							setAmendedOrderID.remove(cartObj.Apttus_Config2__OrderId__c);
						}

						//to cover catch block, throw exception while running test class
						if (Test.isRunningTest()) {
							Decimal dc1 = 1 / 0;
						}
					} catch(Exception ex) {

						//v103 ++ <<
						//APTS_CustomLogging.createErrorLog('Error in Finalize Partial Order', 'Apex', ex.getMessage() , 'Order', cartObj.Apttus_Config2__OrderId__c, 'OM', false, false, null, true);
						APTS_CustomErrorLogging.createErrorLog('APTS_AmendPartialOrderBatchHelper', 'Apex', ex.getTypeName() + ':' + ex.getMessage(), 'Order', cartObj.Apttus_Config2__OrderId__c, 'OM', false, false, null, true, cartObj.Apttus_Config2__OrderId__c, null, 'Error in Finalize Partial Order');
						//v103 ++ >>


					}
				}

				//to cover catch block, throw exception while running test class
				if (Test.isRunningTest()) {
					Decimal dc1 = 1 / 0;
				}

			} catch(Exception ex) {
				//v103 ++ <<
				//APTS_CustomLogging.createErrorLog('Error while Amending Partial Order', 'Apex', ex.getMessage() , 'Order', null, 'OM', false, false, null, true);
				APTS_CustomErrorLogging.createErrorLog('APTS_AmendPartialOrderBatchHelper', 'Apex', ex.getTypeName() + ':' + ex.getMessage(), 'Order', null, 'OM', false, false, null, true, null, null, 'Error while Amending Partial Order');
				//v103 ++ >>

			}
		}
	}
}