/*************************************************************
  @Name: APTS_AcceptOrderQueue
  @Author: Shanmuga Prasath
  @CreateDate: 27-05-2019
  @Description: Invoked from APTS_AcceptOrder
  @Test Class : Covered by APTS_AcceptOrder_Test
  @UsedBy: Create Accept button on Order page
  //DQ-56 v1.1 Asset Contract Change
 ******************************************************************/
//V101 22-06-2020 Venky Muppalaneni: DQ-3038 Implementing new error handling 

public without sharing class APTS_AcceptOrderQueue implements Queueable {
	Id orderId;
	@testVisible
	private static Boolean doChainJob = true;
	public Boolean isContractChange = false;
	Set<Id> orderLineItemIdWithSerialNumberSet = new Set<Id> ();
	Map<Id, Id> orderLineItemIdToAgreementIdMap = new Map<Id, Id> ();
	Map<String, Apttus_Config2__OrderLineItem__c> serialNoToOLIMap = new Map<String, Apttus_Config2__OrderLineItem__c> ();
	Map<Id, Apttus_Config2__OrderLineItem__c> idToOrderLineItemMap = new Map<Id, Apttus_Config2__OrderLineItem__c> ();
	Map<Id, Apttus_Config2__OrderLineItem__c> idToOrderLineItemTmpMap = new Map<Id, Apttus_Config2__OrderLineItem__c> ();
	Set<String> agreementIdSet = new Set<String> ();
	set<Id> refurbishedOLIs = new set<Id> ();
	List<SObject> oldList = new List<SObject> ();
	Map<Id, SObject> oldItems = new Map<Id, SObject> ();
	Set<Id> orderLineItemIdSet = new Set<Id> ();

	public APTS_AcceptOrderQueue(Id orderId) {
		this.orderId = orderId;
	}
	//v101 ++ <<
	public APTS_AcceptOrderQueue(Id orderId, string transactionId) {
		this.orderId = orderId;
		APTS_CustomErrorLogging.assignTransactionId(transactionId);
	}
	//v101 ++ >>
	public void execute(QueueableContext context) {
		Set<Id> orderIdSet = new Set<Id> ();
		List<Apttus_Config2__OrderLineItem__c> childOLIList = new List<Apttus_Config2__OrderLineItem__c> ();
		List<PhysicalAsset__c> updatedAssetList = new List<PhysicalAsset__c> ();
		List<Apttus_Config2__OrderLineItem__c> l1OLIList = new List<Apttus_Config2__OrderLineItem__c> ();
		List<Apttus_Config2__OrderLineItem__c> updateOLIList = new List<Apttus_Config2__OrderLineItem__c> ();
		Set<Id> agreementIdSet = new Set<Id> ();
		Set<Id> physicalAssetIdSet = new Set<Id> ();
		Map<Id, PhysicalAsset__c> physicalAssetMap = new Map<Id, PhysicalAsset__c> ();
		Map<Id, PhysicalAsset__c> physicalUpsertMap = new Map<Id, PhysicalAsset__c> ();
		PhysicalAsset__c oPhysicalAsset = new PhysicalAsset__c();

		orderIdSet.add(orderId);
		//oOrder = new Apttus_Config2__Order__c();
		//oOrder.Id = orderId;
		try {
			childOLIList = APTS_AdminOrderQueue.getChildOLIs(orderIdSet);
			for (Apttus_Config2__OrderLineItem__c oLI : childOLIList) {

				// DQ-56

				/*  if(oLI.APTS_Serial_Number__c != null)
				  orderLineItemIdWithSerialNumberSet.add(oLI.Id);
				 
				  if (oLi.Apttus_CMConfig__AgreementId__c != null) {
				  orderLineItemIdToAgreementIdMap.put(oLi.Id, oLi.Apttus_CMConfig__AgreementId__c);
				  agreementIdSet.add(OLi.Apttus_CMConfig__AgreementId__c);
				  }
				  if (String.IsNotBlank(OLi.Apttus_Config2__ProductId__c)
				  && String.IsNotBlank(OLi.Apttus_Config2__ProductId__r.APTS_Vendor_Code__c) && String.IsNotBlank(OLi.APTS_Serial_Number__c)) {
				  serialNoToOLIMap.put(OLi.Apttus_Config2__ProductId__r.APTS_Vendor_Code__c + OLi.APTS_Serial_Number__c, oLi);
				  if(OLi.APTS_RefurbishedMachine__c){
				  refurbishedOLIs.add(OLi.id);
				  }
				  }
				  orderLineItemIdSet.add(oLI.id);
				  idToOrderLineItemTmpMap.put(oLI.id,oli);    
				  Map<Id, Apttus_Config2__OrderLineItem__c> idToOrderLineItemMap = APTS_OrderLineItemDAO.getOrderLineItems(orderLineItemIdSet);   
				 */

				// DQ- 56 
				if (oli.Apttus_Config2__OrderId__r.APTS_Contract_Change__c == 'Yes')
				isContractChange = true;
				oLI.APTS_Item_Relevant_for_SAP__c = false;
				oLI.Apttus_Config2__Status__c = 'Fulfilled';
				oLI.Apttus_Config2__ReadyForBillingDate__c = oLI.Apttus_Config2__StartDate__c;
				updateOLIList.add(oLI);
				if (oLI.APTS_Is_Primary_L1_Line__c && oLI.Apttus_Config2__LineStatus__c != 'New') {
					physicalAssetIdSet.add(oLI.APTS_Physical_Asset__c);
				}
				if (oLI.Apttus_Config2__IsPrimaryLine__c && oLI.Apttus_Config2__LineType__c == 'Product/Service') {
					Apttus_Config2__OrderLineItem__c oLITemp = new Apttus_Config2__OrderLineItem__c();
					oLITemp.Id = oLI.Id;
					// oLITemp.Apttus_Config2__ReadyForBillingDate__c = oLI.Apttus_Config2__StartDate__c;
					oLITemp.Apttus_Config2__ActivatedDate__c = oLI.Apttus_Config2__StartDate__c;
					oLITemp.Apttus_Config2__OrderId__c = oLI.Apttus_Config2__OrderId__c;
					l1OLIList.add(oLITemp);
				}
			}

			//  APTS_OrderLineItemTriggerHandler instOli = new APTS_OrderLineItemTriggerHandler();
			// instOli.CreatePhysicalAssetMethod(orderLineItemIdWithSerialNumberSet,orderLineItemIdToAgreementIdMap,agreementIdSet,serialNoToOLIMap,idToOrderLineItemTmpMap,refurbishedOLIs,idToOrderLineItemMap,null,null);

			APTS_OrderUtils.stopOrderLineItemTrigger();
			APTS_OrderUtils.stopOrderTrigger();
			APTS_OrderTriggerHandler.isTriggerDisabled = TRUE;
			APTS_OrderLineItemTriggerHandler.isTriggerDisabled = TRUE;
			APTS_BillingScheduleTriggerHandler.isSkipBillingScheduleTrigger = true;

			if (isContractChange == true)
			APTS_OrderLineItemTriggerHandler.isTriggerDisabled = false;
			if (updateOLIList.size() > 0) {
				Database.update(updateOLIList, false);
			}
			if (l1OLIList.size() > 0) {
				if (doChainJob) {
					//APTS_ActivateOrderQueueable belongs to OM team
					if (!Test.isRunningTest())
					{
						//v101 ++ <<
						System.enqueueJob(new APTS_ActivateOrderQueueable(l1OLIList, 'Admin Order', APTS_CustomErrorLogging.transactionId));
						//System.enqueueJob(new APTS_ActivateOrderQueueable(l1OLIList, 'Admin Order'));
						//v101 ++ >>
					}
				}
			}
			//APTS_CLMUtil.updateReadyForBillingDateOnOrderLineItems(childOLIList);
			//APTS_BillingScheduleTriggerHandler.isSkipBillingScheduleTrigger = false;
			APTS_AdminOrderQueue.reCalculateNetPrice(orderId);
			//APTS_OrderUtils.acceptOrder(orderId); 
			//update oOrder;
			//system.debug('++oOrder.APTS_Status__c++'+ oOrder.APTS_Status__c);

			Map<Id, List<APTS_Agreement_PO_Details__c>> idToAgreementPODetailsMap = APTS_AdminOrderQueue.getAgreementPODetails(agreementIdSet);
			Map<Id, Id> idToBillingSettingsIdMap = APTS_OrderLineItemUtils.getBillingSettings(agreementIdSet);
			List<PhysicalAsset__c> tempTostore = new List<PhysicalAsset__c> ();

			/*if (!physicalAssetIdSet.IsEmpty()) {
				for (Id physicalAssetId : physicalAssetIdSet) {
					for (Apttus_Config2__OrderLineItem__c oLI : childOLIList) {
						if (oLi.Apttus_Config2__LineStatus__c != 'Cancelled') {
							if (!physicalAssetMap.containsKey(physicalAssetId)) {

								oPhysicalAsset.Id = physicalAssetId;
								PhysicalAsset__c updatedAsset = APTS_OrderLineItemUtils.populatePhysicalAssetFields(oLI, oPhysicalAsset);
								if (idToBillingSettingsIdMap != null && idToBillingSettingsIdMap.containsKey(oLI.Apttus_CMConfig__AgreementId__c)) {
									updatedAsset.Billing_Setting__c = idToBillingSettingsIdMap.get(oLI.Apttus_CMConfig__AgreementId__c);
								}
								if (oLI.APTS_Is_Primary_L1_Line__c) {
									tempTostore = APTS_OrderLineItemUtils.updatePhysicalAssetOnOLIUpdate(new Map<Id, Apttus_Config2__OrderLineItem__c> { updatedAsset.Id => oLI }, idToAgreementPODetailsMap);
									if (tempTostore.size() > 0) {
										updatedAsset = tempTostore[0];
									}
								}

								physicalAssetMap.put(updatedAsset.Id, updatedAsset);

							} else {
								PhysicalAsset__c updatedAsset = physicalAssetMap.get(physicalAssetId);
								updatedAsset = APTS_OrderLineItemUtils.populatePhysicalAssetFields(oLI, updatedAsset);
								if (idToBillingSettingsIdMap != null && idToBillingSettingsIdMap.containsKey(oLI.Apttus_CMConfig__AgreementId__c)) {
									updatedAsset.Billing_Setting__c = idToBillingSettingsIdMap.get(oLI.Apttus_CMConfig__AgreementId__c);
								}
								if (oLI.APTS_Is_Primary_L1_Line__c) {
									tempTostore = APTS_OrderLineItemUtils.updatePhysicalAssetOnOLIUpdate(new Map<Id, Apttus_Config2__OrderLineItem__c> { updatedAsset.Id => oLI }, idToAgreementPODetailsMap);
									if (tempTostore.size() > 0) {
										updatedAsset = tempTostore[0];
									}
								}
								if (!physicalAssetMap.containsKey(updatedAsset.Id) && updatedAsset != null && updatedAsset.Id != null) {
									physicalAssetMap.put(updatedAsset.Id, updatedAsset);
								}
								system.debug('updatedAsset ELSE ' + updatedAsset.Id);
							}
						}
					}
				}
				if (physicalAssetMap != null) { Database.update(physicalAssetMap.values()); }*/
				/*  if(physicalAssetMap != null){
				 
				  for(PhysicalAsset__c instphysicalAsset : physicalAssetMap.values())
				  {
				  if(!physicalUpsertMap.containsKey(instphysicalAsset.id))  
				  physicalUpsertMap.put(instphysicalAsset.id,instphysicalAsset)  ;
				  }
				  system.debug('updatedAsset ELSE '+physicalUpsertMap);
				  Database.update(physicalUpsertMap.values());
				}
			}*/
		} catch(Exception e) {
			//v101 ++ <<
			APTS_CustomErrorLogging.createErrorLog('APTS_AcceptOrderQueue', 'Apex', e.getTypeName() + ':' + e.getMessage() + '__StackTrace:_' + e.getStackTraceString(), 'Order',
			                                       orderId, 'OM', false, false, null, true, orderId, null, e.getMessage());
		}
		APTS_CustomErrorLogging.saveErrorLog();
		//v101 ++ >>
	}
}