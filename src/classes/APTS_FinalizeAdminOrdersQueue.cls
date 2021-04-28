/***
 * Change history
 * v100 - Sai
 * Test Class: APTS_AdminOrderQueueTest
***/

public class APTS_FinalizeAdminOrdersQueue implements Queueable  {
    Id cartId;
    Id orderId;
	String operation;

	public APTS_FinalizeAdminOrdersQueue(Id cartId,Id orderId, string operation){
		this.cartId = cartId;
		this.orderId = orderId;
		this.operation = operation;
	}

	// Invoke the Order Finlization once Prcing for Cart is completed
	public void execute(QueueableContext context) {
		try{
			if(operation == 'reprice'){
				Boolean isPricePending = true;
				while (isPricePending) {            
					isPricePending = APTS_OrderUtils.repriceCart(cartId);
					if (!isPricePending) {break;}
				}
				if(!Test.isRunningTest()){
					System.enqueueJob(new APTS_FinalizeAdminOrdersQueue(cartId,orderId,'finalizeCart'));
				}						
			}
			if(operation == 'finalizeCart'){
				APTS_OrderUtils.finalizeCart(cartId);
				APTS_OrderUtils.syncCart(cartId);
				// Update the OLI with recaliculated Net Price			 
				if(!Test.isRunningTest()){
					System.enqueueJob(new APTS_FinalizeAdminOrdersQueue(cartId,orderId,'acceptOrder'));
				}
			}
			if(operation == 'acceptOrder'){	
				APTS_AdminOrderQueue.reCalculateNetPrice(orderId); 	        
				APTS_CLMUtil.updateReadyForBillingDateOnOrderLineItems(APTS_AdminOrderQueue.childOLIList);
				APTS_OrderUtils.acceptOrder(orderId);
				// Update PhyscalAsset for Admin Movement
				APTS_AdminOrderQueue.updatePhyAssetOnMovement(orderId);	
			}
		}catch(Exception ex){
			APTS_CustomErrorLogging.createErrorLog('APTS_FinalizeAdminOrdersQueue', 'Apex', ex.getMessage() + ':' + ex.getStackTraceString(), 'Order',orderId, 'OM', false, false, null, true,orderId, null, ex.getMessage());
			APTS_CustomErrorLogging.saveErrorLog();
		}
	}

}