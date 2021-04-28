/*************************************************************
  @Name: APTS_ActivateOrdersBatch
  @Author: Galin Georgiev
  @CreateDate: 27-08-2018
  @Description: Set ready for activation date on primary order line items. This trigger OOB activation process
  @UsedBy:
 ******************************************************************/
//v100 27-08-2018 Galin Georgiev: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes
//V101 29-01-2019 Aarthi Pitchai - Added fix for DeInstall Flow to prevent OOB activation as part of Defect #23878
//V102 20-03-2019 Nikita Modi : Movement Order condition
//v103 01-04-2019 Akanksha : Activating OLIs (Standalone products) for movement order
//v104 19-08-2019 Nikita Modi : Option OLIs flipping back to Fulfilled upon Activation (Build/Test) ; QTCFLEX1-875
//v105 27-12-2019 Renuka: Setting Activation date and Ready for Billing Date in ExternalMovementLine
//V106 03-03-2020 Aarthi: DQ-1719 Moved the Billing date logic to OLI handler 
//V107 19-06-2020 Venky Muppalaneni: DQ-3038 Implementing new error handling 

global class APTS_ActivateOrdersBatch implements Database.Batchable<sObject>, Database.Stateful {

	private String query;
	//v103 ++ <<
	DateTime installDateMovement = null;
	//v103 ++ >>

	private List<Apttus_Config2__OrderLineItem__c> orderLineItemToUpdateList = new List<Apttus_Config2__OrderLineItem__c> ();

	global APTS_ActivateOrdersBatch() {
		//v107 ++ <<
		APTS_CustomErrorLogging.assignTransactionId(null);
		//v107 ++ >>
		query = 'SELECT Id, APTS_Installation_Date_Authorized__c, APTS_De_installation_Date_Authorized__c,' +
		'Apttus_Config2__LineNumber__c, Apttus_Config2__IsPrimaryLine__c, Apttus_Config2__ActivatedDate__c,' +
		'Apttus_Config2__OrderId__c, APTS_SAP_OrderType__c, APTS_Treated_By_Activation_Batch__c, Apttus_Config2__ReadyForBillingDate__c, ' +
		'Apttus_Config2__Status__c, Apttus_Config2__ChargeType__c, APTS_Type_of_Contract__c,Apttus_Config2__LineType__c,APTS_Goods_Issue_Date__c ' +
		'FROM Apttus_Config2__OrderLineItem__c ' +
		'WHERE APTS_Treated_By_Activation_Batch__c != true AND ' +
		'((APTS_Installation_Date_Authorized__c != null AND Apttus_Config2__Status__c = \'Fulfilled\' AND Apttus_Config2__LineType__c = \'Product/Service\' )OR (APTS_Installation_Date_Authorized__c != null AND Apttus_Config2__Status__c = \'In Fulfillment\' AND APTS_SAP_OrderType__c = \'XA14\' )' +
		' OR (Apttus_Config2__ChargeType__c = \'Sales Price\' AND APTS_Type_of_Contract__c = null AND Apttus_Config2__LineType__c = \'Product/Service\' AND Apttus_Config2__Status__c = \'Fulfilled\' AND APTS_SAP_OrderType__c = \'XA14\')' +
		' OR (APTS_De_installation_Date_Authorized__c != null AND Apttus_Config2__Status__c = \'In Fulfillment\' AND APTS_SAP_OrderType__c = \'XB13\')) LIMIT 50'; //v102 APTS_SAP_OrderType__c != \'XA14\'  //v104 added check Apttus_Config2__LineType__c = \'Product/Service\' 
	}

	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

	global void execute(Database.BatchableContext BC, List<Apttus_Config2__OrderLineItem__c> scope) {

		Set<Id> orderIdSet = new Set<Id> ();
		Set<Decimal> lineNumberSet = new Set<Decimal> ();
		Map<Id, Apttus_Config2__OrderLineItem__c> idToOLIL1Map = new Map<Id, Apttus_Config2__OrderLineItem__c> ();
		Map<Id, Apttus_Config2__OrderLineItem__c> idToOLIPrimaryL1Map = new Map<Id, Apttus_Config2__OrderLineItem__c> ();
		Map<Id, Apttus_Config2__OrderLineItem__c> oLIL1IdToOLIPrimaryMap = new Map<Id, Apttus_Config2__OrderLineItem__c> ();
		List<Apttus_Config2__OrderLineItem__c> orderLineItemTreatedList = new List<Apttus_Config2__OrderLineItem__c> ();
		Set<Id> deInstallOrderIdSet = new Set<Id> ();
		Set<Decimal> deInsatllLineNumberSet = new Set<Decimal> ();
		Map<Id, Decimal> deInsatllLineNumberMap = new Map<Id, Decimal> ();
		//v103 ++ <<
		Map<Id, Apttus_Config2__OrderLineItem__c> movementOLIMap = new Map<Id, Apttus_Config2__OrderLineItem__c> ();
		//v103 ++ >>
		//v107 ++ <<
		Apttus_Config2__OrderLineItem__c errorOrderLineItem = new Apttus_Config2__OrderLineItem__c();
		try {
		//v107 ++ >>
			for (Apttus_Config2__OrderLineItem__c oOrderLineItem : scope) {
				//v103 ++ <<
				//v107 ++ <<
				errorOrderLineItem = oOrderLineItem;
				//v107 ++ >>
				if (oOrderLineItem.Apttus_Config2__ChargeType__c == 'Sales Price' && oOrderLineItem.APTS_Type_of_Contract__c == null &&
				    oOrderLineItem.Apttus_Config2__LineType__c == 'Product/Service' && oOrderLineItem.Apttus_Config2__Status__c == 'Fulfilled' && oOrderLineItem.APTS_SAP_OrderType__c == 'XA14') {
					movementOLIMap.put(oOrderLineItem.Id, oOrderLineItem);
				}
				//V103 ++ >>
				else if (oOrderLineItem.Apttus_Config2__IsPrimaryLine__c) {
					idToOLIPrimaryL1Map.put(oOrderLineItem.Id, oOrderLineItem);
				} else {
					orderIdSet.add(oOrderLineItem.Apttus_Config2__OrderId__c);
					lineNumberSet.add(oOrderLineItem.Apttus_Config2__LineNumber__c);
					idToOLIL1Map.put(oOrderLineItem.Id, oOrderLineItem);
				}

				oOrderLineItem.APTS_Treated_By_Activation_Batch__c = true;

				if (oOrderLineItem.Apttus_Config2__Status__c == 'In Fulfillment') {
					oOrderLineItem.Apttus_Config2__Status__c = 'Fulfilled';
				}

				orderLineItemTreatedList.add(oOrderLineItem);
			}

			APTS_OrderUtils.stopOrderLineItemTrigger();
			Database.update(orderLineItemTreatedList);
			APTS_OrderUtils.startOrderLineItemTrigger();

			if (!idToOLIL1Map.isEmpty()) {

				Map<Id, Apttus_Config2__OrderLineItem__c> bundleIdToOrderLineItemMap = new Map<Id, Apttus_Config2__OrderLineItem__c> ([
				                                                                                                                      SELECT Id, Apttus_Config2__LineNumber__c, Apttus_Config2__OrderId__c, APTS_Treated_By_Activation_Batch__c,
				                                                                                                                      APTS_Installation_Date_Authorized__c, Apttus_Config2__ActivatedDate__c, Apttus_Config2__ReadyForBillingDate__c,
				                                                                                                                      APTS_De_installation_Date_Authorized__c, Apttus_Config2__Status__c
				                                                                                                                      FROM Apttus_Config2__OrderLineItem__c
				                                                                                                                      WHERE Apttus_Config2__LineNumber__c IN :lineNumberSet AND Apttus_Config2__OrderId__c IN :orderIdSet AND Apttus_Config2__IsPrimaryLine__c = true AND Apttus_Config2__HasOptions__c = true]);


				for (Apttus_Config2__OrderLineItem__c oOrderLineItemL1 : idToOLIL1Map.values()) {
					//v107 ++ <<
					errorOrderLineItem = oOrderLineItemL1;
					//v107 ++ >>

					DateTime installDate = oOrderLineItemL1.APTS_Installation_Date_Authorized__c != null ? oOrderLineItemL1.APTS_Installation_Date_Authorized__c : oOrderLineItemL1.APTS_De_installation_Date_Authorized__c;

					for (Apttus_Config2__OrderLineItem__c oOrderLineItemTmp : bundleIdToOrderLineItemMap.values()) {

						Boolean bSameLineNumber = oOrderLineItemL1.Apttus_Config2__LineNumber__c == oOrderLineItemTmp.Apttus_Config2__LineNumber__c;
						Boolean bSameOrder = oOrderLineItemL1.Apttus_Config2__OrderId__c == oOrderLineItemTmp.Apttus_Config2__OrderId__c;

						if (bSameLineNumber && bSameOrder) {

							oOrderLineItemTmp.Apttus_Config2__ActivatedDate__c = installDate;
							//V106 ++ <<
							//oOrderLineItemTmp.Apttus_Config2__ReadyForBillingDate__c = oOrderLineItemTmp.APTS_De_installation_Date_Authorized__c == null ? oOrderLineItemTmp.Apttus_Config2__ActivatedDate__c : null;
							if (oOrderLineItemTmp.APTS_De_installation_Date_Authorized__c != null)
							{
								//oOrderLineItemTmp.Apttus_Config2__ReadyForBillingDate__c = null;
							}
							//V106 ++ >>
							orderLineItemToUpdateList.add(oOrderLineItemTmp);
						}
					}
					//v103 ++ <<
					if (installDateMovement == null) {
						installDateMovement = installDate;
					}
					//v103 ++ >>
				}
			}

			for (Apttus_Config2__OrderLineItem__c oOrderLineItemL1 : idToOLIPrimaryL1Map.values()) {
				//v107 ++ <<
				errorOrderLineItem = oOrderLineItemL1;
				//v107 ++ >>
				DateTime installDate = oOrderLineItemL1.APTS_Installation_Date_Authorized__c != null ? oOrderLineItemL1.APTS_Installation_Date_Authorized__c : oOrderLineItemL1.APTS_De_installation_Date_Authorized__c;

				oOrderLineItemL1.Apttus_Config2__ActivatedDate__c = installDate;
				//V106 ++ <<
				// oOrderLineItemL1.Apttus_Config2__ReadyForBillingDate__c = oOrderLineItemL1.APTS_De_installation_Date_Authorized__c == null ? oOrderLineItemL1.Apttus_Config2__ActivatedDate__c : null;
				if (oOrderLineItemL1.APTS_De_installation_Date_Authorized__c != null)
				{
					//oOrderLineItemL1.Apttus_Config2__ReadyForBillingDate__c = null;
				} //V106 ++ >>
				orderLineItemToUpdateList.add(oOrderLineItemL1);
				//v103 ++ <<
				if (installDateMovement == null) {
					installDateMovement = installDate;
				}
				//v103 ++ >>
			}
			//v103 ++ <<
			if (!movementOLIMap.isEmpty()) {
				for (Apttus_Config2__OrderLineItem__c oOrderLineItemL1 : movementOLIMap.values()) {
					//v107 ++ <<
					errorOrderLineItem = oOrderLineItemL1;
					//v107 ++ >>
					oOrderLineItemL1.Apttus_Config2__ActivatedDate__c = installDateMovement;
					// oOrderLineItemL1.Apttus_Config2__ReadyForBillingDate__c = installDateMovement;   //V106 ++ <<>>   

					//v105++<<
					if (installDateMovement == null) {
						oOrderLineItemL1.Apttus_Config2__ActivatedDate__c = oOrderLineItemL1.APTS_Goods_Issue_Date__c;
						//oOrderLineItemL1.Apttus_Config2__ReadyForBillingDate__c = oOrderLineItemL1.APTS_Goods_Issue_Date__c; //V106 ++ <<>>
					}
					//v105++>>

					orderLineItemToUpdateList.add(oOrderLineItemL1);
				}
			}
			//v103 ++ >>
		//v107 ++ <<
		}
		catch(Exception ex) {
			APTS_CustomErrorLogging.createErrorLog('APTS_ActivateOrdersBatch', 'Apex', ex.getTypeName() + ':' + ex.getMessage(), 'Order',
			(errorOrderLineItem != null) ? errorOrderLineItem.Id : null, 'OM', false, false, null, true,
			(errorOrderLineItem != null) ? errorOrderLineItem.Apttus_Config2__OrderId__c : null, null, ex.getMessage());
		}
		//v107 ++ >>
	}

	global void finish(Database.BatchableContext BC) {
		 //v107 ++ <<
		 APTS_CustomErrorLogging.saveErrorLog();
		 //v107 ++ >>
		System.enqueueJob(new APTS_ActivateOrderQueueable(orderLineItemToUpdateList,null,APTS_CustomErrorLogging.transactionId));
	}
}