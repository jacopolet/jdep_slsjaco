/***
 * Change history
 * v100 - Aftab
 * v101 - Sai -JIRA-DFT2C-740 
 * v102 DQ-56 -Asset contrct Change
  ***/
//V103 22-06-2020 Venky Muppalaneni: DQ-3038 Implementing new error handling 
//V104 21-01-2021 Aarthi Pitchai : DQ-4117 Billing Settings issue fix

public class APTS_AdminOrderQueue implements Queueable {
	Id cartId;
	Id orderId;
	Boolean repriceRequired;
	public static List<Apttus_Config2__OrderLineItem__c> childOLIList;
	public static set<Id> agreementIdSet; //V104 ++ <<>>

	public APTS_AdminOrderQueue(Id cartId, Id orderId, Boolean repriceRequired) {
		this.cartId = cartId;
		this.orderId = orderId;
		this.repriceRequired = repriceRequired;
	}

	public void execute(QueueableContext context) {
		//Update Pricing until isPricingPending flag becomes 'False'

		Boolean isPricePending = true;
		//v102 ++ <<

		//try {

		//v102 ++ >>
		if (cartId != null && orderId != null) {
			if (!Test.isRunningTest()) {
				while (isPricePending) {
					if ((Limits.getQueries() > (Limits.getLimitQueries() / 2) || Limits.getCpuTime() > (Limits.getLimitCpuTime() * 0.80)) && isPricePending) {
						break;
					}
					isPricePending = APTS_OrderUtils.repriceCart(cartId);
					if (!isPricePending) { break; }
				}
			} else { isPricePending = false; }
			if (isPricePending) {
				System.enqueueJob(new APTS_AdminOrderQueue(cartId, orderId, false));
			} else {
				/*// Finalize Order Cart
				  APTS_OrderUtils.finalizeCart(cartId);
				  APTS_OrderUtils.syncCart(cartId);
				  // Update the OLI with recaliculated Net Price
				  reCalculateNetPrice(orderId);          
				  APTS_CLMUtil.updateReadyForBillingDateOnOrderLineItems(childOLIList);
				  APTS_OrderUtils.acceptOrder(orderId);
				  // Update PhyscalAsset for Admin Movement
				  APTS_AdminOrderQueue.updatePhyAssetOnMovement(orderId);*/
				if (!Test.isRunningTest()) {
					System.enqueueJob(new APTS_FinalizeAdminOrdersQueue(cartId, orderId, 'reprice'));
				}
			}
		}
		/*} catch (Exception ex) {
		  System.Debug('Error: '+ex.getLineNumber()+'____'+ex.getMessage()+'____'+ex.getStackTraceString());
		  APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString() +'_'+ex.getMessage(), 'Admin order queue', orderId, 'CLM', false, false, null, true);
		  }*/
	}

	/*
	 * Method to substract the NetPrice from the Dummy charge type line at the bundle to overcome the product issue
	 * which throws an error on activating the order when there is a -ve Netprice.
	 */
	public static void reCalculateNetPrice(Id orderId) {
		//try{
		childOLIList = getChildOLIs(new Set<Id> { orderId });
		Map<String, Decimal> cancelledLineNetPriceMap = new Map<String, Decimal> ();
		String mapKey = ''; List<Apttus_Config2__OrderLineItem__c> orderlineUpdateList = new List<Apttus_Config2__OrderLineItem__c> ();
		for (Apttus_Config2__OrderLineItem__c oLI : childOLIList) {
			if (oLI.Apttus_Config2__LineType__c == 'Option' && oLI.Apttus_Config2__LineStatus__c == 'Cancelled' && oLi.Apttus_Config2__NetPrice__c< 0) {
				mapKey = oLI.Apttus_Config2__OrderId__c + '' + oLI.Apttus_Config2__LineNumber__c + '' + oLi.Apttus_Config2__ChargeType__c;
				if (cancelledLineNetPriceMap.containsKey(mapKey)) {
					cancelledLineNetPriceMap.put(mapKey, (cancelledLineNetPriceMap.get(mapKey) + (oLi.Apttus_Config2__NetPrice__c * - 1)));
				}
				else {
					cancelledLineNetPriceMap.put(mapKey, (oLi.Apttus_Config2__NetPrice__c * - 1));
				}
			}
		}
		if (cancelledLineNetPriceMap.size()> 0) {
			for (Apttus_Config2__OrderLineItem__c oLI : childOLIList) {
				mapKey = oLI.Apttus_Config2__OrderId__c + '' + oLI.Apttus_Config2__LineNumber__c + '' + oLi.Apttus_Config2__ChargeType__c;
				if (oLI.Apttus_Config2__LineType__c == 'Product/Service' && cancelledLineNetPriceMap.containsKey(mapKey)) {
					oLI.Apttus_Config2__NetPrice__c += cancelledLineNetPriceMap.get(mapKey);
					orderlineUpdateList.add(oLI);
				}
			}
			// Update OrderLine Items records
			if (orderlineUpdateList != null && orderlineUpdateList.size() > 0) {
				Database.update(orderlineUpdateList);
			}
		}
		//v102 ++ <<
		//}catch (Exception ex) {
		//System.Debug('Error: '+ex.getLineNumber()+'____'+ex.getMessage()+'____'+ex.getStackTraceString());
		//// APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getMessage()+'__StackTrace:_'+ex.getStackTraceString() , 'Admin order queue', orderId, 'CLM', false, false, null, true);
		//// New Exception Logging
		//APTS_CustomErrorLogging.createErrorLog('APTS_AdminOrderQueue', 'Apex', ex.getTypeName()+': '+ex.getMessage()+'__StackTrace:_'+ex.getStackTraceString() , 
		//'Admin order queue', orderId, 'OM', false, false, null, true, orderId, null, ex.getMessage());         
		//}
		//v102 ++ >>
	}

	/*
	 * Method to Get the Agreement for related SoldTo
	 */
	public static Map<Id, List<APTS_Agreement_PO_Details__c>> getAgreementPODetails(Set<Id> agreementIdSet) {
		Map<Id, List<APTS_Agreement_PO_Details__c>> poMap = new Map<Id, List<APTS_Agreement_PO_Details__c>> ();
		for (APTS_Agreement_PO_Details__c poDetails :[SELECT Id,
		     APTS_Agreement__c,
		     APTS_PO_Category__c,
		     APTS_PO_Expiration_Date__c,
		     APTS_PO_Number__c,
		     APTS_PO_Number_Required__c,
		     APTS_PO_Number_Type__c
		     FROM APTS_Agreement_PO_Details__c
		     WHERE APTS_Agreement__c IN :agreementIdSet]) {
			if (poMap.containsKey(poDetails.APTS_Agreement__c)) {
				List<APTS_Agreement_PO_Details__c> poList = poMap.get(poDetails.APTS_Agreement__c);
				poList.add(poDetails);
				poMap.put(poDetails.APTS_Agreement__c, poList);
			} else {
				poMap.put(poDetails.APTS_Agreement__c, new List<APTS_Agreement_PO_Details__c> { poDetails });
			}
		}
		return poMap;
	}

	/*
	 * Method to update the PhysicalAsset for related SoldTo
	 */
	public static void updatePhyAssetOnMovement(Id orderId) {
		try {
			Map<Id, PhysicalAsset__c> updatePhysicalAssetMap = new Map<Id, PhysicalAsset__c> ();
			Map<Id, Apttus_Config2__OrderLineItem__c> oliWithPhysicalAssetMap = new Map<Id, Apttus_Config2__OrderLineItem__c> ();		
			agreementIdSet = new Set<Id>(); //V104 ++ <<>>
			for (Apttus_Config2__OrderLineItem__c oLI : childOLIList) {
				// Sai - Commeted for Jira - DFT2C-740 to take all the Option Lines 
				// if('Product/Service'.equalsIgnoreCase(oLI.Apttus_Config2__LineType__c) && String.IsNotBlank(oLI.APTS_Physical_Asset__c) && oLi.Apttus_Config2__LineStatus__c != 'Cancelled'){
				if (oLi.Apttus_Config2__LineStatus__c != 'Cancelled' && oLI.APTS_Physical_Asset__c != null) {
					oliWithPhysicalAssetMap.put(oLI.id, oLI);
					agreementIdSet.add(oLI.Apttus_CMConfig__AgreementId__c); //V104 ++ <<>>
				}
			}

			if (orderId != null && oliWithPhysicalAssetMap != null && oliWithPhysicalAssetMap.size() > 0) {
				updatePhysicalAssetMap = APTS_AdminOrderQueue.populatePAFieldsForMovement(oliWithPhysicalAssetMap);
				if (updatePhysicalAssetMap != null && updatePhysicalAssetMap.size() > 0) {
					Database.update(updatePhysicalAssetMap.values(), false);
				}
			}
		} catch(Exception ex) {
			APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getMessage() + '__StackTrace:_' + ex.getStackTraceString(), 'Admin order queue', orderId, 'CLM', false, false, null, true);
		}
	}

	// v101 Sai-JIRA-DFT2C-740 +<<
	/* Populate Physical Asset Fields for Asset Movement*/
	public static Map<Id, PhysicalAsset__c> populatePAFieldsForMovement(Map<Id, Apttus_Config2__OrderLineItem__c> oliWithPhysicalAssetMap) {
		Map<Id, PhysicalAsset__c> physicalAssetMap = new Map<Id, PhysicalAsset__c> ();
		Map<Id, Id> idToBillingSettingsIdMap = APTS_OrderLineItemUtils.getBillingSettings(agreementIdSet); //V104 ++ <<>>
		for (Apttus_Config2__OrderLineItem__c oliWithPA : oliWithPhysicalAssetMap.values()) {
			if (oliWithPA.APTS_Physical_Asset__c != null && oliWithPA.Apttus_Config2__LocationId__c != null) {
				PhysicalAsset__c phyAsset = new PhysicalAsset__c();
				phyAsset.Id = oliWithPA.APTS_Physical_Asset__c;
				phyAsset.AccountLocation__c = oliWithPA.Apttus_Config2__LocationId__c;
				phyAsset.SoldTo__c = oliWithPA.Apttus_Config2__OrderId__r.Apttus_Config2__SoldToAccountId__c;
				phyAsset.AgreementRecordType__c = oliWithPA.Apttus_CMConfig__AgreementId__r.RecordType.Name;
				phyAsset.Routesales__c = oliWithPA.Apttus_CMConfig__AgreementId__r.APTS_Routesales__c;
				if (oliWithPA.APTS_Order_LSP_Detail__c != null) {
					phyAsset.Building__c = oliWithPA.APTS_Order_LSP_Detail__r.APTS_Building__c;
					phyAsset.Floor__c = oliWithPA.APTS_Order_LSP_Detail__r.APTS_Floor__c;
					phyAsset.Area__c = oliWithPA.APTS_Order_LSP_Detail__r.APTS_Area__c;
					phyAsset.CustomerReferenceNumber__c = oliWithPA.APTS_Order_LSP_Detail__r.APTS_CustomerReference__c;
					phyAsset.SmokingArea__c = oliWithPA.APTS_Order_LSP_Detail__r.APTS_SmokingArea__c;
					phyAsset.ConfigurationFileURL__c = oliWithPA.APTS_Order_LSP_Detail__r.APTS_ConfigurationFileURL__c;
					phyAsset.JDECrockeryVolumeSize__c = oliWithPA.APTS_Order_LSP_Detail__r.APTS_JDE_crockeryVolumeSize__c;
					phyAsset.ConfigurationManualAgreementsURL__c = oliWithPA.APTS_Order_LSP_Detail__r.APTS_ConfigurationManualAgreementsURL__c;
				}
				phyAsset.Billing_Setting__c = idToBillingSettingsIdMap.get(oliWithPA.Apttus_CMConfig__AgreementId__c); //V104 ++ <<>>
				physicalAssetMap.put(phyAsset.Id, phyAsset);
			}
		}
		return physicalAssetMap;
	}

	public static List<Apttus_Config2__OrderLineItem__c> getChildOLIs(Set<Id> orderIdSet) {
		return[SELECT Id, Name, Apttus_Config2__LocationId__c, APTS_Machine_Age__c, APTS_Is_Primary_L1_Line__c,
		APTS_Serial_Number__c, APTS_Goods_Issue_Date__c, APTS_RefurbishedMachine__c,
		Apttus_Config2__LineType__c, APTS_Physical_Asset__c, Apttus_Config2__ParentBundleNumber__c,
		Apttus_Config2__LineNumber__c, Apttus_Config2__ChargeType__c, Apttus_Config2__HasOptions__c,
		APTS_De_installation_Date__c, APTS_Option_Group_Text__c, APTS_Serial_Number2__c,
		APTS_Parent_Order_Line_Item__c, APTS_Type_of_Contract__c, Apttus_Config2__IsPrimaryLine__c,
		Apttus_Config2__StartDate__c, Apttus_Config2__ReadyForBillingDate__c, Apttus_Config2__ActivatedDate__c,
		Apttus_Config2__AssetLineItemId__c, Apttus_Config2__Description__c,
		Apttus_Config2__AssetLineItemId__r.APTS_RefurbishedMachine__c,
		Apttus_Config2__AssetLineItemId__r.Apttus_Config2__StartDate__c,
		Apttus_Config2__AssetLineItemId__r.Apttus_Config2__EndDate__c,
		Apttus_Config2__AssetLineItemId__r.Apttus_Config2__AssetStatus__c,
		Apttus_Config2__AssetLineItemId__r.APTS_Physical_Asset__c,
		Apttus_Config2__AssetLineItemId__r.APTS_OwnedByCustomer__c,
		Apttus_Config2__AssetLineItemId__r.APTS_Is_Primary_L1_Asset__c,
		Apttus_Config2__AssetLineItemId__r.Apttus_Config2__BillingPreferenceId__c,
		// Sai - Jira - DFT2C-740
		Apttus_Config2__Quantity__c,

		Apttus_CMConfig__AgreementId__c,
		Apttus_CMConfig__AgreementId__r.RecordType.DeveloperName,
		Apttus_CMConfig__AgreementId__r.RecordType.Name,
		Apttus_CMConfig__AgreementId__r.Apttus__Status_Category__c,
		Apttus_CMConfig__AgreementId__r.Apttus__Status__c,
		Apttus_CMConfig__AgreementId__r.APTS_Routesales__c,

		APTS_Order_LSP_Detail__c,
		APTS_Order_LSP_Detail__r.APTS_Building__c,
		APTS_Order_LSP_Detail__r.APTS_Floor__c,
		APTS_Order_LSP_Detail__r.APTS_Area__c,
		APTS_Order_LSP_Detail__r.APTS_CustomerReference__c,
		APTS_Order_LSP_Detail__r.APTS_SmokingArea__c,
		APTS_Order_LSP_Detail__r.APTS_ConfigurationFileURL__c,
		APTS_Order_LSP_Detail__r.APTS_JDE_crockeryVolumeSize__c,
		APTS_Order_LSP_Detail__r.APTS_ConfigurationManualAgreementsURL__c,

		Apttus_Config2__OrderId__c,
		Apttus_Config2__OrderId__r.Apttus_Config2__PONumber__c,
		Apttus_Config2__OrderId__r.APTS_Contract_Change__c, /* DQ-56 -Asset contrct Change */
		Apttus_Config2__OrderId__r.APTS_Sales_Organization__c,
		Apttus_Config2__OrderId__r.Apttus_Config2__SoldToAccountId__c,
		Apttus_Config2__OrderId__r.APTS_Confirmed_De_Installation_Date__c,
		Apttus_Config2__OrderId__r.APTS_Confirmed_Installation_Date__c,
		Apttus_Config2__OrderId__r.APTS_Merchant_ID__c,
		Apttus_Config2__OrderId__r.APTS_Closed_User_Group_Code_1__c,
		Apttus_Config2__OrderId__r.APTS_Closed_User_Group_Code_2__c,
		Apttus_Config2__OrderId__r.APTS_Closed_User_Group_Code_3__c,
		Apttus_Config2__OrderId__r.APTS_Order_Type__c,

		Apttus_Config2__AttributeValueId__c,
		Apttus_Config2__AttributeValueId__r.APTS_Number_of_months__c,
		Apttus_Config2__AttributeValueId__r.APTS_Call_Out_Coverage_Percent__c,
		Apttus_Config2__AttributeValueId__r.APTS_Labour_Coverage_Percent__c,
		Apttus_Config2__AttributeValueId__r.APTS_Spare_Parts_Coverage_Percent__c,
		Apttus_Config2__AttributeValueId__r.APTS_WTS_Changed_By__c,
		Apttus_Config2__AttributeValueId__r.APTS_Service_Window__c,
		Apttus_Config2__AttributeValueId__r.APTS_Response_Profile__c,
		Apttus_Config2__AttributeValueId__r.APTS_Merchant__c,
		Apttus_Config2__AttributeValueId__r.APTS_Consumer_Price__c,
		Apttus_Config2__AttributeValueId__r.APTS_Cup_Size__c,
		Apttus_Config2__AttributeValueId__r.APTS_Taste_Pallet__c,
		Apttus_Config2__AttributeValueId__r.APTS_Type_of_payment__c,
		Apttus_Config2__AttributeValueId__r.APTS_Number_of_hours_per_month__c,
		Apttus_Config2__AttributeValueId__r.APTS_First_Line_Response_Time__c,

		Apttus_Config2__ProductId__c,
		Apttus_Config2__ProductId__r.Name,
		Apttus_Config2__ProductId__r.Description,
		Apttus_Config2__ProductId__r.ProductCode,
		Apttus_Config2__ProductId__r.APTS_Material_Type__c,
		Apttus_Config2__ProductId__r.Apttus_Config2__ConfigurationType__c,
		Apttus_Config2__ProductId__r.APTS_Vendor_Code__c,
		Apttus_Config2__OptionId__c,
		Apttus_Config2__OptionId__r.Name,
		Apttus_Config2__OptionId__r.Description,
		Apttus_Config2__OptionId__r.ProductCode,
		Apttus_Config2__OptionId__r.APTS_Material_Type__c,
		Apttus_Config2__OptionId__r.APTS_Option_Group_Indicator__c,
		Apttus_Config2__OptionId__r.APTS_Response_Time_Hours__c,
		Apttus_Config2__OptionId__r.Water_Filter_Replacement__c,
		Apttus_Config2__OptionId__r.APTS_Full_Operating__c,

		Apttus_Config2__ShipToAccountId__c,
		Apttus_Config2__ShipToAccountId__r.ShippingCountry,
		Apttus_Config2__ShipToAccountId__r.WSONE_DATA__ShippingAddressCountryISO__c,
		Apttus_Config2__ShipToAccountId__r.ShippingPostalCode,
		Apttus_Config2__ShipToAccountId__r.ShippingStreet,
		Apttus_Config2__ShipToAccountId__r.WSONE_DATA__ShippingAddressHouseNumber__c,
		Apttus_Config2__ShipToAccountId__r.ShippingCity,

		Apttus_Config2__LineStatus__c,
		Apttus_Config2__NetPrice__c,
		Createddate

		FROM Apttus_Config2__OrderLineItem__c
		WHERE Apttus_Config2__OrderId__c IN : orderIdSet
		LIMIT 50000];
	}

}