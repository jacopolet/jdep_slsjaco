global class APTS_SubscriptionOrderFinalizeBatch implements Database.Batchable<sObject> {
	private static final String EMAIL = System.Label.APTS_Email;
	private static final String SUBSCRIPTION_ORDER = 'Subscription Order';
	private static final String ORDER_CART_PENDING = 'Cart Creation Pending';

	global Database.QueryLocator start(Database.BatchableContext BC) {
		String query = 'SELECT Id, Apttus_CMConfig__AgreementId__c, Apttus_Config2__SoldToAccountId__c, Apttus_Config2__Description__c FROM Apttus_Config2__Order__c WHERE APTS_Order_Sub_Type__c = :SUBSCRIPTION_ORDER AND APTS_Order_Batch_Status__c = :ORDER_CART_PENDING AND Apttus_Config2__Description__c <> null ';
		return Database.getQueryLocator(query);
	}

	global void execute(Database.BatchableContext BC, List<Apttus_Config2__Order__c> listOrderBatchChunck) {
		try {
			Id accountId;
			Apttus_Config2__ProductConfiguration__c cartTmp;
			Set<Id> setOrderId = new Set<Id>();
			Set<Id> setAgreementId = new Set<Id>();
			List<Apttus_Config2__LineItem__c> listCartLineItems;
			List<Apttus_Config2__ProductConfiguration__c> listCartToUpdate = new List<Apttus_Config2__ProductConfiguration__c>();
			Map<Id, Id> mapNewCartId = new Map<Id, Id>();
			Map<Id, List<Apttus_Config2__LineItem__c>> mapCartLineItems;

			//get List of valid order for subscription
			List<Apttus_Config2__Order__c> listOrderChunck = APTS_SubscriptionOrder.getValidOrderList(listOrderBatchChunck);

			//initial loop
			for (Apttus_Config2__Order__c newOrder : listOrderChunck) {
				setOrderId.add(newOrder.Id);
				setAgreementId.add(newOrder.Apttus_CMConfig__AgreementId__c);
			}

			if (!setOrderId.isEmpty()) {
				mapNewCartId = APTS_SubscriptionOrder.createCartAddProduct(setOrderId, setAgreementId, listOrderChunck);

				//getLineItem and attributes
				//updateAttributes(setNewCartId);

				//save cart
				for (Id cartId : mapNewCartId.keySet()) {
					cartTmp = APTS_OrderUtils.saveCart(cartId);
					listCartToUpdate.add(cartTmp);
				}

				if (!listCartToUpdate.isEmpty()) {
					Database.update(listCartToUpdate, false);

					//add adjustments, reprice and finalize cart
					mapCartLineItems = APTS_SubscriptionOrder.getCartLineItems(mapNewCartId.keySet());
					for (Id cartId : mapNewCartId.keySet()) {
						//add adjustments
						accountId = mapNewCartId.get(cartId);
						listCartLineItems = mapCartLineItems.get(cartId);
						APTS_SubscriptionOrder.addAdjustments(accountId, cartId, listCartLineItems);

						APTS_SubscriptionOrder.applyConstraintsRule(cartId);

						APTS_SubscriptionOrder.repriceCart(cartId);

						APTS_SubscriptionOrder.finalizeCart(cartId);
					}

					//submit order to SAP or create Task for Account's Customer Relationship Person
					APTS_SubscriptionOrder.finalAction(setOrderId);
				}
			}
		} catch (Exception ex) {
			APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString() , 'Subscription Order', null, 'OM', false, true, EMAIL, true);
			throw ex;
		}
	}

	global void finish(Database.BatchableContext BC) {

	}
}