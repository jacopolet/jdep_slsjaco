/*******************
  Purpose: 
  Revision History:
  #No     Name        Date        Purpose
  1.0     Nagavi      15/01/2017  Created the class to handle logics related to sending updates to SAP PO
  2.0     Keerthana   23/01/2019  Defect - 3931 to calculate Cost in PLI with SOD 
  ************************/
public without sharing class APTS_PriceListItemTriggerHandler implements ITriggerHandler {

	public static final String CPQAdminLabel = 'JDE_CPQ_Admin';
	public static final String ApttusCPQAdminLabel = 'ApttusCPQAdmin';

	/*@methodName- IsDisabled
	 *@description- method is used to prevent recursion
	 *@param- empty
	 *@return- returns boolean
	 */
	public Boolean isDisabled() {
		try {
			return TriggerSettings__c.getInstance().PriceLineItemTrigger__c ? false : true;
		} catch(Exception e) { APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString(), 'APTS_PriceListItemTriggerHandler', null, 'CPQ', false, false, null, true); return true; }
	}

	/*@methodName- beforeInsert
	 *@description- method is used to call logic 
	 *@param- Pass the 
	 *@return- no returntype
	 */
	public void beforeInsert(List<Apttus_Config2__PriceListItem__c> newPLItemsList) {
		try {
			onBeforeInsertPLItems(newPLItemsList);
			updateMasterListPriceforCSP(newPLItemsList);
		} catch(Exception e) { APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString(), 'APTS_PriceListItemTriggerHandler', null, 'CPQ', false, false, null, true); }
	}

	/*@methodName- beforeUpdate
	 *@description- method is used to call logic 
	 *@param- Pass the 
	 *@return- no returntype
	 */
	public void beforeUpdate(List<SObject> newPLItemsList, Map<Id, SObject> newPLItemsMap, List<SObject> oldPLItemsList, Map<Id, SObject> oldPLItemsMap) {
		try {
			updateMasterListPriceforCSP(newPLItemsList);
		} catch(Exception e) { APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString(), 'APTS_PriceListItemTriggerHandler', null, 'CPQ', false, false, null, true); }
	}

	/*@methodName- beforeDelete
	 *@description- method is used to call logic related to the beforeDelete event
	 *@param- Pass the 
	 *@return- no returntype
	 */
	public void beforeDelete(List<SObject> oldPLItemsList, Map<Id, SObject> oldPLItemsMap) {
		CheckDeletion(oldPLItemsList);

	}

	/*@methodName- afterInsert
	 *@description- method is used to call logic related to the after insert event
	 *@param- Pass the new records as list and Map
	 *@return- no returntype
	 */
	public void afterInsert(List<SObject> newPLItemsList, Map<Id, SObject> newPLItemsMap) {
		//Logic to check if the PLItem is active and it is newly inserted.If so will trigger digital pricing
		try {
			onAfterInsertPLItems((List<Apttus_Config2__PriceListItem__c>) newPLItemsList);
		} catch(Exception e) { APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString(), 'APTS_PriceListItemTriggerHandler', null, 'CPQ', false, false, null, true); }
	}

	/*@methodName- afterUpdate
	 *@description- method is used to call logic related to the after update event
	 *@param- Pass the new and old records as list and Map from trigger
	 *@return- no returntype
	 */
	public void afterUpdate(List<SObject> newPLItemsList, Map<Id, SObject> newPLItemsMap, List<SObject> oldPLItemsList, Map<Id, SObject> oldPLItemsMap) {
		//Logic to check if the price line item's isactive field and other fields have changed.If so will trigger digital pricing
		try {
			onAfterUpdatePLItems((Map<Id, Apttus_Config2__PriceListItem__c>) newPLItemsMap, (Map<Id, Apttus_Config2__PriceListItem__c>) oldPLItemsMap);

			Map<Id, Apttus_Config2__PriceListItem__c> oldRecMap = (Map<Id, Apttus_Config2__PriceListItem__c>) oldPLItemsMap;
			Set<Id> priceListItemIdSet = new Set<Id> ();
			for (Apttus_Config2__PriceListItem__c newRec : (List<Apttus_Config2__PriceListItem__c>) newPLItemsList) {
				if (newRec.Apttus_Config2__ListPrice__c != oldRecMap.get(newRec.Id).Apttus_Config2__ListPrice__c) {
					if (!priceListItemIdSet.contains(newRec.Id))
					{
						priceListItemIdSet.add(newRec.Id);
					}
				}
			}
			Set<Id> accountSet = new Set<Id> ();
			For (Apttus__AgreementLineItem__c agrLine :[select Apttus__AgreementId__r.Apttus__Account__c from Apttus__AgreementLineItem__c where Apttus_CMConfig__PriceListItemId__c in :priceListItemIdSet and Apttus__AgreementId__r.Apttus__Status_Category__c = :APTS_NetPriceExtraction.IN_EFFECT limit 50000])
			{
				if (!accountSet.contains(agrLine.Apttus__AgreementId__r.Apttus__Account__c))
				{
					accountSet.add(agrLine.Apttus__AgreementId__r.Apttus__Account__c);
				}
			}
			if (accountSet.size() > 0) {
				APTS_NetPriceExtraction.updateNetPriceExtraction(accountSet);
			}


		} catch(Exception e) { APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString(), 'APTS_PriceListItemTriggerHandler', null, 'CPQ', false, false, null, true); }
	}

	/*@methodName- afterDelete
	 *@description- method is used to call logic related to the afterDelete event
	 *@param- Pass the 
	 *@return- no returntype
	 */
	public void afterDelete(List<SObject> oldPLItemsList, Map<Id, SObject> oldPLItemsMap) { }

	/*@methodName- afterUndelete
	 *@description- method is used to call logic related to the afterUndelete event
	 *@param- Pass the 
	 *@return- no returntype
	 */
	public void afterUndelete(List<SObject> newPLItemsList, Map<Id, SObject> newPLItemsMap) { }

	/*************** Business Logic Methods ***********************/
	/*@methodName- onAfterInsertPLItems
	 *@description- method is used to call logic related to the after insert event
	 *@param- Pass only the records to be processed as a list
	 *@return- no returntype
	 */
	public static void onAfterInsertPLItems(List<Apttus_Config2__PriceListItem__c> newPLItemsList) {
		try {
			//List<Apttus_Config2__PriceListItem__c> priceLIToBeSentToSAPPO=  new List<Apttus_Config2__PriceListItem__c>();
			Set<Id> prodIdsToBeSentToSAPPO = new Set<Id> ();
			Set<String> enabledWebshops = new Set<String> ();
			enabledWebshops = APTS_IntegrationLogHandlerUtility.getEnabledWebshops();

			for (Apttus_Config2__PriceListItem__c pli : newPLItemsList) {

				if (pli.APTS_Price_List_Name__c.contains(Label.APTS_Digital_PriceList)) {

					string temp = pli.APTS_Price_List_Name__c.remove(Label.APTS_Digital_PriceList).trim();
					if (pli.Apttus_Config2__Active__c && enabledWebshops.contains(temp)) {
						prodIdsToBeSentToSAPPO.add(pli.Apttus_Config2__ProductId__c);

					} else { }
				}
			}

			//Update the webshops in Product2
			updateWebshopInProduct(newPLItemsList);

			if (!prodIdsToBeSentToSAPPO.isEmpty()) {
				APTS_IntegrationLogHandlerUtility.checkAndCreateIntegrationLogs(prodIdsToBeSentToSAPPO);
			}

		} catch(Exception e) {
			APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString(), 'APTS_PriceListItemTriggerHandler', null, 'CPQ', false, false, null, true);
		}
	}

	/*@methodName- onAfterUpdatePLItems
	 *@description- method is used to call logic related to the after insert event
	 *@param- Pass only the records to be processed as a list
	 *@return- no returntype
	 */
	public static void onAfterUpdatePLItems(Map<Id, Apttus_Config2__PriceListItem__c> newPLItemsMap, Map<Id, Apttus_Config2__PriceListItem__c> oldPLItemsMap) {
		try {
			//Remove webshop from the Product for the inactive pli
			removeWebshopFromProd(newPLItemsMap, oldPLItemsMap);

			//Map<Id,Apttus_Config2__PriceListItem__c> productsToBeSentToSAPPO=  new Map<Id,Apttus_Config2__PriceListItem__c>();
			Set<Id> prodIdsToBeSentToSAPPO = new Set<Id> ();
			List<Apttus_Config2__PriceListItem__c> enableWebshopList = new List<Apttus_Config2__PriceListItem__c> ();
			List<Schema.FieldSetMember> relatedFieldSet = new List<Schema.FieldSetMember> ();
			relatedFieldSet = APTS_IntegrationLogHandlerUtility.readFieldSet('APTS_Digital_Pricing_FieldSet', 'Apttus_Config2__PriceListItem__c');

			Set<String> enabledWebshops = new Set<String> ();
			enabledWebshops = APTS_IntegrationLogHandlerUtility.getEnabledWebshops();

			for (Id pli : newPLItemsMap.keySet()) {
				if (newPLItemsMap.get(pli).APTS_Price_List_Name__c.contains(Label.APTS_Digital_PriceList)) {
					string temp = newPLItemsMap.get(pli).APTS_Price_List_Name__c.remove(Label.APTS_Digital_PriceList).trim();
					if ((enabledWebshops.contains(temp))
					    && ((newPLItemsMap.get(pli).Apttus_Config2__Active__c != oldPLItemsMap.get(pli).Apttus_Config2__Active__c) ||
					(newPLItemsMap.get(pli).Apttus_Config2__Active__c && APTS_IntegrationLogHandlerUtility.checkIfValidToSend(newPLItemsMap.get(pli), oldPLItemsMap.get(pli), relatedFieldSet)))) {

						//if(!productsToBeSentToSAPPO.containsKey(newPLItemsMap.get(pli).Apttus_Config2__ProductId__c)) 
						//productsToBeSentToSAPPO.put(newPLItemsMap.get(pli).Apttus_Config2__ProductId__c,newPLItemsMap.get(pli));
						prodIdsToBeSentToSAPPO.add(newPLItemsMap.get(pli).Apttus_Config2__ProductId__c);
					}
					//Add the webshop to the activated pli
					if (newPLItemsMap.get(pli).Apttus_Config2__Active__c && newPLItemsMap.get(pli).Apttus_Config2__Active__c != oldPLItemsMap.get(pli).Apttus_Config2__Active__c) {
						enableWebshopList.add(newPLItemsMap.get(pli));
					}
				}

			}

			if (!prodIdsToBeSentToSAPPO.isEmpty()) {
				APTS_IntegrationLogHandlerUtility.checkAndCreateIntegrationLogs(prodIdsToBeSentToSAPPO);
			}

			if (!enableWebshopList.isEmpty()) {
				updateWebshopInProduct(enableWebshopList);
			}
		} catch(Exception e) { APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString(), 'APTS_PriceListItemTriggerHandler', null, 'CPQ', false, false, null, true); }
	}

	public static void updateWebshopInProduct(List<Apttus_Config2__PriceListItem__c> newPLItemsList) {
		List<Product2> prodToBeupdated = new List<Product2> ();
		Map<Id, List<Apttus_Config2__PriceListItem__c>> prodPLIMap = new Map<Id, List<Apttus_Config2__PriceListItem__c>> ();
		try {
			for (Apttus_Config2__PriceListItem__c pli : newPLItemsList) {

				if (pli.Apttus_Config2__Active__c && pli.APTS_Price_List_Name__c.contains(Label.APTS_Digital_PriceList)) {
					if (prodPLIMap.containsKey(pli.Apttus_Config2__ProductId__c)) {
						prodPLIMap.get(pli.Apttus_Config2__ProductId__c).add(pli);
					} else {
						prodPLIMap.put(pli.Apttus_Config2__ProductId__c, new List<Apttus_Config2__PriceListItem__c> { pli });
					}
				}
			}
			if (prodPLIMap != null) {
				Map<Id, Product2> prodMap = new
				Map<Id, Product2> ([select id, APTS_Product_Enabled_for_web_shop_s__c FROM Product2 WHERE Id IN :prodPLIMap.keyset()]);
				for (Id prodId : prodPLIMap.KeySet()) {
					Product2 tempProd = prodMap.get(prodId);

					List<Apttus_Config2__PriceListItem__c> relatedPLI = new List<Apttus_Config2__PriceListItem__c> ();
					relatedPLI = prodPLIMap.get(prodId);

					if (!relatedPLI.isEmpty()) {
						for (Apttus_Config2__PriceListItem__c plItem : relatedPLI) {

							string temp = plItem.APTS_Price_List_Name__c.remove(Label.APTS_Digital_PriceList).trim();


							if (tempProd.APTS_Product_Enabled_for_web_shop_s__c == null) {
								tempProd.APTS_Product_Enabled_for_web_shop_s__c = temp;
							}
							else if (tempProd.APTS_Product_Enabled_for_web_shop_s__c != null && !tempProd.APTS_Product_Enabled_for_web_shop_s__c.contains(temp)) {
								tempProd.APTS_Product_Enabled_for_web_shop_s__c = tempProd.APTS_Product_Enabled_for_web_shop_s__c + ';' + temp;
							}
						}
						prodToBeupdated.add(tempProd);
					}

				}
				if (!prodToBeupdated.isEmpty()) {

					String PRODUCT = 'Product2';
					DescribeSObjectResult objResultPROD = APTS_OTCUtil.getsObjectAccess(PRODUCT);
					if (objResultPROD != null && objResultPROD.isUpdateable())
					{
						update prodToBeupdated;
					}
				}
			}

		} catch(Exception e) { APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString(), 'APTS_PriceListItemTriggerHandler', null, 'CPQ', false, false, null, true); }
	}

	public static void removeWebshopFromProd(Map<Id, Apttus_Config2__PriceListItem__c> newPLItemsMap, Map<Id, Apttus_Config2__PriceListItem__c> oldPLItemsMap) {
		set<Id> relatedProdIds = new set<Id> ();
		set<Id> relatedPLIds = new set<Id> ();
		Map<Id, Apttus_Config2__PriceListItem__c> newPLItemMap = new Map<Id, Apttus_Config2__PriceListItem__c> ();
		set<Id> plWithPliIds = new set<Id> ();
		Map<Id, Product2> prodToBeUpdated = new Map<Id, Product2> ();
		//Map<Id,Id> prodPLMap=new Map<Id,Id>();
		List<Apttus_Config2__PriceListItem__c> relatedPLItems = new List<Apttus_Config2__PriceListItem__c> ();
		//Map<Id,List<Apttus_Config2__PriceListItem__c>> pListPLIMap=new Map<Id,List<Apttus_Config2__PriceListItem__c>>();
		Map<Id, Product2> prodMap;

		try {
			for (Id plItem : newPLItemsMap.KeySet()) {
				//Process only PLi whose active field has changed
				if (newPLItemsMap.get(plItem).APTS_Price_List_Name__c.contains(Label.APTS_Digital_PriceList) && !newPLItemsMap.get(plItem).Apttus_Config2__Active__c && newPLItemsMap.get(plItem).Apttus_Config2__Active__c != oldPLItemsMap.get(plItem).Apttus_Config2__Active__c) {
					relatedProdIds.add(newPLItemsMap.get(plItem).Apttus_Config2__ProductId__c);
					relatedPLIds.add(newPLItemsMap.get(plItem).Apttus_Config2__PriceListId__c);
					newPLItemMap.put(plItem, newPLItemsMap.get(plItem));
					//prodPLMap.put(newPLItemsMap.get(plItem).Apttus_Config2__PriceListId__c,newPLItemsMap.get(plItem).Apttus_Config2__ProductId__c);
				}
			}
			// get the pli for the related Pl and product combination
			if (!relatedProdIds.isEmpty() && !relatedPLIds.isEmpty()) {
				relatedPLItems = [Select Id, Apttus_Config2__PriceListId__c from Apttus_Config2__PriceListItem__c where Apttus_Config2__Active__c = true AND Apttus_Config2__ProductId__c IN :relatedProdIds
				                  AND Apttus_Config2__PriceListId__c IN :relatedPLIds AND Id NOT IN :newPLItemMap.Keyset()];
			}
			if (!relatedPLItems.isEmpty()) {
				for (Apttus_Config2__PriceListItem__c pli : relatedPLItems) {

					plWithPliIds.add(pli.Apttus_Config2__PriceListId__c);
				}
			}
			if (!relatedProdIds.IsEmpty()) {
				prodMap = new Map<Id, Product2> ([select id, APTS_Product_Enabled_for_web_shop_s__c FROM Product2 WHERE Id IN :relatedProdIds]);

				for (Id newPli : newPLItemMap.KeySet()) {
					//check if there is any related pli for the related pl
					if (plWithPliIds.contains(newPLItemMap.get(newPli).Apttus_Config2__PriceListId__c)) {
						//Do Nothing 
					}
					// If there is no other pli for that pl
					else {
						String relatedWebShop = newPLItemMap.get(newPli).APTS_Price_List_Name__c.remove(Label.APTS_Digital_PriceList).trim();
						String prodWebShops;
						if (prodToBeUpdated.containsKey(newPLItemMap.get(newPli).Apttus_Config2__ProductId__c)) {
							prodWebShops = prodToBeUpdated.get(newPLItemMap.get(newPli).Apttus_Config2__ProductId__c).APTS_Product_Enabled_for_web_shop_s__c;
						}
						else {
							prodWebShops = prodMap.get(newPLItemMap.get(newPli).Apttus_Config2__ProductId__c).APTS_Product_Enabled_for_web_shop_s__c;
						}
						String webShop = '';
						if (prodWebShops.contains(relatedWebShop)) { // check if the webshop already present in the product. If yes proceed
							// remove the webshop
							set<String> tempSet = APTS_IntegrationLogHandlerUtility.getProdWebshops(prodWebShops);
							tempSet.remove(relatedWebShop);
							if (!tempSet.isEmpty()) {
								webShop = APTS_IntegrationLogHandlerUtility.getWebShopString(tempSet);
							}
							else {
								webShop = '';
							}
							//construct the string to update in the product record
							if (prodToBeUpdated.containsKey(newPLItemMap.get(newPli).Apttus_Config2__ProductId__c)) { // already present in prodToBeUpdated map
								Product2 temp = prodToBeUpdated.get(newPLItemMap.get(newPli).Apttus_Config2__ProductId__c);
								temp.APTS_Product_Enabled_for_web_shop_s__c = webShop;
								prodToBeUpdated.put(temp.Id, temp);

							}
							else {
								Product2 temp = prodMap.get(newPLItemMap.get(newPli).Apttus_Config2__ProductId__c);
								temp.APTS_Product_Enabled_for_web_shop_s__c = webShop;
								prodToBeUpdated.put(temp.Id, temp);
							}
						}
					}
				}

				if (!prodToBeUpdated.isEmpty()) {

					String PRODUCT = 'Product2';
					DescribeSObjectResult objResultPROD = APTS_OTCUtil.getsObjectAccess(PRODUCT);

					if (objResultPROD != null && objResultPROD.isUpdateable())
					{
						update prodToBeUpdated.values();
					}
				}
			}

		} catch(Exception e) { APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString(), 'APTS_PriceListItemTriggerHandler', null, 'CPQ', false, false, null, true); }
	}
	public static void updateMasterListPriceforCSP(List<Apttus_Config2__PriceListItem__c> newPriceListItems) {

		/* Set<ID> pricelistIds = new Set<ID>();
		  Set<ID> productIDSet = new Set<ID>();
		  Map<ID,ID> basedonPriceListMap = new Map<ID,ID>();
		  Map<String,Apttus_Config2__PriceListItem__c> masterPriceListItemMap = new  Map<String,Apttus_Config2__PriceListItem__c>();*/
		Set<id> salesorgdata = new set<id> ();
		Map<id, APTS_Sales_Org_Data__c> sdmap;
		for (Apttus_Config2__PriceListItem__c cspPLI : newPriceListItems) {
			/*pricelistIds.add(cspPLI.Apttus_Config2__PriceListId__c);
			  productIDSet.add(cspPLI.Apttus_Config2__ProductId__c);*/
			if (cspPLI.APTS_Related_sales_org_data__c != Null)
			salesorgdata.add(cspPLI.APTS_Related_sales_org_data__c);
		}
		if (salesorgdata.size() > 0)
		sdmap = new Map<id, APTS_Sales_Org_Data__c> ([select id, APTS_Cost_Price__c, APTS_Cost_Price_Unit__c from APTS_Sales_Org_Data__c where id in :salesorgdata]);

		/*System.debug('PricelistIds=========>'+pricelistIds); 
		  System.debug('productIDSet=========>'+productIDSet); 
		  if(!pricelistIds.isEmpty()){
		  for(Apttus_Config2__PriceList__c pricelist : [select APTS_PriceList_Type__c,Apttus_Config2__BasedOnPriceListId__c from Apttus_Config2__PriceList__c where id IN: pricelistIds and APTS_PriceList_Type__c='CSP']){
		  if(basedonPriceListMap.get(pricelist.id)==null){
		  basedonPriceListMap.put(pricelist.id,pricelist.Apttus_Config2__BasedOnPriceListId__c);
		  }
		  }
		  }
		  System.debug('basedonPriceListMap=========>'+basedonPriceListMap);
		  if(!productIDSet.isEmpty() && !basedonPriceListMap.isEmpty()){
		  for(Apttus_Config2__PriceListItem__c masterPLI : [select id,Apttus_Config2__ListPrice__c,Apttus_Config2__ChargeType__c,Apttus_Config2__ProductId__c,Apttus_Config2__PriceListId__c from Apttus_Config2__PriceListItem__c where Apttus_Config2__PriceListId__c IN : basedonPriceListMap.values() and Apttus_Config2__ProductId__c IN : productIDSet]){
		  System.debug('masterPLI=====>'+masterPLI);
		  if(masterPriceListItemMap.get(masterPLI.Apttus_Config2__ProductId__c+masterPLI.Apttus_Config2__ChargeType__c+masterPLI.Apttus_Config2__PriceListId__c)==null){
		  masterPriceListItemMap.put(masterPLI.Apttus_Config2__ProductId__c+masterPLI.Apttus_Config2__ChargeType__c+masterPLI.Apttus_Config2__PriceListId__c,masterPLI);
		  }
		  }
		  System.debug('masterPriceListItemMap=========>'+masterPriceListItemMap);
		  if(!masterPriceListItemMap.isEmpty() && !basedonPriceListMap.isEmpty()){
		  for(Apttus_Config2__PriceListItem__c cspPLI : newPriceListItems){
		  System.debug('VALUE=====>'+basedonPriceListMap.get(cspPLI.Apttus_Config2__PriceListId__c));
		 
		  if(cspPLI.Apttus_Config2__PriceListId__c!=null && cspPLI.Apttus_Config2__ChargeType__c!=null && cspPLI.Apttus_Config2__ProductId__c!=null && basedonPriceListMap.get(cspPLI.Apttus_Config2__PriceListId__c)!=null){
		  System.debug('GET MASTER DETAILS=====>'+masterPriceListItemMap.get(cspPLI.Apttus_Config2__ProductId__c+cspPLI.Apttus_Config2__ChargeType__c+basedonPriceListMap.get(cspPLI.Apttus_Config2__PriceListId__c)));
		  }
		  if(cspPLI.Apttus_Config2__PriceListId__c!=null && cspPLI.Apttus_Config2__ChargeType__c!=null && cspPLI.Apttus_Config2__ProductId__c!=null && basedonPriceListMap.get(cspPLI.Apttus_Config2__PriceListId__c)!=null && masterPriceListItemMap.get(cspPLI.Apttus_Config2__ProductId__c+cspPLI.Apttus_Config2__ChargeType__c+basedonPriceListMap.get(cspPLI.Apttus_Config2__PriceListId__c))!=null){
		  cspPLI.APTS_Master_list_price__c = masterPriceListItemMap.get(cspPLI.Apttus_Config2__ProductId__c+cspPLI.Apttus_Config2__ChargeType__c+basedonPriceListMap.get(cspPLI.Apttus_Config2__PriceListId__c)).Apttus_Config2__ListPrice__c;
		  }
		  }
		  }
		 
		  System.debug('newPriceListItems=========>'+newPriceListItems);
		  }*/
		for (Apttus_Config2__PriceListItem__c cspPLI : newPriceListItems) {

			if (sdmap != Null && sdmap.containskey(cspPLI.APTS_Related_sales_org_data__c) && sdmap.get(cspPLI.APTS_Related_sales_org_data__c).APTS_Cost_Price__c != Null && sdmap.get(cspPLI.APTS_Related_sales_org_data__c).APTS_Cost_Price_Unit__c != Null) {

				cspPLI.Apttus_Config2__Cost__c = Decimal.valueOf(sdmap.get(cspPLI.APTS_Related_sales_org_data__c).APTS_Cost_Price__c) / Decimal.valueOf(sdmap.get(cspPLI.APTS_Related_sales_org_data__c).APTS_Cost_Price_Unit__c);

			}
		}
	}


	public static void CheckDeletion(List<Apttus_Config2__PriceListItem__c> oldPLItemsList)
	{ Boolean CPQAdminPermission;
		Set<String> setPermission = new Set<String> ();
		List<PermissionSetAssignment> lstcurrentUserPerSet = [SELECT Id, PermissionSet.Name, AssigneeId
		                                                      FROM PermissionSetAssignment
		                                                      WHERE AssigneeId = :Userinfo.getUserId()];

		for (PermissionSetAssignment instPermissionset : lstcurrentUserPerSet)
		{ setPermission.add(instPermissionset.PermissionSet.Name); }

		if (!setPermission.contains(CPQAdminLabel) && !setPermission.contains(ApttusCPQAdminLabel))
		CPQAdminPermission = false;
		else
		CPQAdminPermission = true;

		for (Apttus_Config2__PriceListItem__c instPriceListItem : oldPLItemsList)
		{
			if (instPriceListItem.APTS_Price_List_Type__c.equals('Direct'))
			instPriceListItem.addError('Users should not delete General PriceListItem');
			if (!CPQAdminPermission && !instPriceListItem.APTS_Price_List_Type__c.equals('Direct'))
			instPriceListItem.addError('You do not have CPQ Permission Set with you to delete this CSP PriceListItem');

		}
	}
	/*************** Business Logic Methods ***********************/
	/*@methodName- onBeforeInsertPLItems
	 *@description- method is used to call logic related to the before insert event
	 *@param- Pass only the records to be processed as a list
	 *@return- no returntype
	 */
	public static void onBeforeInsertPLItems(List<Apttus_Config2__PriceListItem__c> newPLItemsList) {

		Set<String> ProductCode = new set<String> ();
		Set<String> CSPPL = new set<String> ();
		Set<String> uomInput = new Set<String> ();
		Map<String, String> uomKey = new Map<String, String> ();
		String tempString = '';
		string tempPid;
		Map<String, Decimal> uomOutput = new Map<String, Decimal> ();
		Decimal uomFactor;
		List<Apttus_Config2__PriceListItem__c> GeneralPLIs = new List<Apttus_Config2__PriceListItem__c> ();
		List<Apttus_Config2__PriceList__c> PL = new List<Apttus_Config2__PriceList__c> ();
		map<string, Apttus_Config2__PriceListItem__c> csptogenmap = new map<string, Apttus_Config2__PriceListItem__c> ();
		try {

			for (Apttus_Config2__PriceListItem__c pli : newPLItemsList) {
				ProductCode.add(pli.Apttus_Config2__ProductCode__c);
				CSPPL.add(pli.Apttus_Config2__PriceListId__c);
			}
			PL = [Select Id, APTS_SalesOrg__c, APTS_Region__c from Apttus_Config2__PriceList__c where id in :CSPPL AND APTS_PriceList_Type__c != 'DIRECT' limit 1];

			GeneralPLIs = [Select Id, Apttus_Config2__PriceUom__c, Apttus_Config2__PriceListId__c, APTS_Related_sales_org_data__c, Apttus_Config2__ProductCode__c, APTS_TXP_Coffee_Tax__c, APTS_TXP_Instant_Coffee_Tax__c, APTS_TXP_Liquid_Coffee_Tax__c, APTS_TXP_Tea_Tax__c, APTS_TXP_Chocolate_Tax__c, APTS_TXP_Disposable_Tableware__c, APTS_TXP_Cappuccino_Tax_Mixed__c, APTS_TXP_Recycle_Con_Pack_Tax__c, APTS_TXP_Disposal_Fee__c, APTS_TXP_Belgian_GSV__c, APTS_Recycling_Fee__c, APTS_TAX_DK_specific_UOM__c, APTS_TAX_all_countries_UOM__c, APTS_Tax_per_UOM__c, APTS_VAT_indicator__c, APTS_VAT_percentage__c, Apttus_Config2__PriceListId__r.APTS_SalesOrg__c from Apttus_Config2__PriceListItem__c where Apttus_Config2__Active__c = true AND Apttus_Config2__ProductCode__c IN :ProductCode AND APTS_Sales_Org__c = :PL[0].APTS_Region__c AND Apttus_Config2__PriceListId__r.APTS_PriceList_Type__c = 'DIRECT'];

			for (Apttus_Config2__PriceListItem__c genpli : GeneralPLIs) {
				String genprdcode = genpli.Apttus_Config2__ProductCode__c;
				csptogenmap.put(genprdcode, genpli);
			}

			for (Apttus_Config2__PriceListItem__c pli11 : newPLItemsList) {
				if (!csptogenmap.isempty()) {
					tempPid = pli11.Apttus_Config2__ProductCode__c;
					tempString = '';
					tempString += pli11.Apttus_Config2__ProductCode__c;
				}
				if (csptogenmap.get(tempPid) != null && csptogenmap.get(tempPid).Apttus_Config2__PriceUom__c != null) {
					tempString += ';' + csptogenmap.get(tempPid).Apttus_Config2__PriceUom__c;
				}
				if (pli11.Apttus_Config2__PriceUom__c != null) {
					tempString += ';' + pli11.Apttus_Config2__PriceUom__c;
				}
				if (!uomInput.contains(tempString))
				{
					uomInput.add(tempString);
					uomKey.put(tempPid, tempString);
				}
			}
			System.debug('uomInput****' + uomInput);
			if (uomInput != null)
			uomOutput = APTS_UOMConversionUtils.getUOMConversions(uomInput);
			System.debug('uomOutput****' + uomOutput);

			for (Apttus_Config2__PriceListItem__c pli1 : newPLItemsList) {
				//https://jdecoffee.atlassian.net/browse/QTCFLEX1-1897- Lavanya
				if (pli1.Apttus_Config2__EffectiveDate__c != null && pli1.Apttus_Config2__ExpirationDate__c != null && pli1.Apttus_Config2__EffectiveDate__c <= System.today() && pli1.Apttus_Config2__ExpirationDate__c > System.today())
				pli1.Apttus_Config2__Active__c = true;
				else
				pli1.Apttus_Config2__Active__c = false;
				//tempPid = pli1.Apttus_Config2__ProductCode__c;
				if (!csptogenmap.isempty()) {
					String ProductCodes = pli1.Apttus_Config2__ProductCode__c;
					tempPid = pli1.Apttus_Config2__ProductCode__c;
					/*  tempString += pli1.Apttus_Config2__ProductCode__c;
					  tempString += ';' + csptogenmap.get(ProductCodes).Apttus_Config2__PriceUom__c;
					  tempString += ';' + pli1.Apttus_Config2__PriceUom__c;
					  system.debug('+++tempString+++'+tempString );
					  uomInput.add(tempString);
					  uomOutput = APTS_UOMConversionUtils.getUOMConversions(uomInput);
					  uomFactor = uomOutput.get(tempString)!= null ? uomOutput.get(tempString): 1;*/
					uomFactor = uomOutput.get(uomKey.get(tempPid)) != null ? uomOutput.get(uomKey.get(tempPid)) : 1;
					pli1.APTS_TXP_Coffee_Tax__c = csptogenmap.get(ProductCodes).APTS_TXP_Coffee_Tax__c != null ? csptogenmap.get(ProductCodes).APTS_TXP_Coffee_Tax__c : 0;
					pli1.APTS_TXP_Instant_Coffee_Tax__c = csptogenmap.get(ProductCodes).APTS_TXP_Instant_Coffee_Tax__c != null ? csptogenmap.get(ProductCodes).APTS_TXP_Instant_Coffee_Tax__c : 0;
					pli1.APTS_TXP_Liquid_Coffee_Tax__c = csptogenmap.get(ProductCodes).APTS_TXP_Liquid_Coffee_Tax__c != null ? csptogenmap.get(ProductCodes).APTS_TXP_Liquid_Coffee_Tax__c : 0;
					pli1.APTS_TXP_Tea_Tax__c = csptogenmap.get(ProductCodes).APTS_TXP_Tea_Tax__c != null ? csptogenmap.get(ProductCodes).APTS_TXP_Tea_Tax__c : 0;
					pli1.APTS_TXP_Chocolate_Tax__c = csptogenmap.get(ProductCodes).APTS_TXP_Chocolate_Tax__c != null ? csptogenmap.get(ProductCodes).APTS_TXP_Chocolate_Tax__c : 0;
					pli1.APTS_TXP_Disposable_Tableware__c = csptogenmap.get(ProductCodes).APTS_TXP_Disposable_Tableware__c != null ? csptogenmap.get(ProductCodes).APTS_TXP_Disposable_Tableware__c : 0;
					pli1.APTS_TXP_Cappuccino_Tax_Mixed__c = csptogenmap.get(ProductCodes).APTS_TXP_Cappuccino_Tax_Mixed__c != null ? csptogenmap.get(ProductCodes).APTS_TXP_Cappuccino_Tax_Mixed__c : 0;
					pli1.APTS_TXP_Recycle_Con_Pack_Tax__c = csptogenmap.get(ProductCodes).APTS_TXP_Recycle_Con_Pack_Tax__c != null ? csptogenmap.get(ProductCodes).APTS_TXP_Recycle_Con_Pack_Tax__c : 0;
					pli1.APTS_TXP_Belgian_GSV__c = csptogenmap.get(ProductCodes).APTS_TXP_Belgian_GSV__c != null ? csptogenmap.get(ProductCodes).APTS_TXP_Belgian_GSV__c : 0;
					pli1.APTS_Recycling_Fee__c = csptogenmap.get(ProductCodes).APTS_Recycling_Fee__c != null ? csptogenmap.get(ProductCodes).APTS_Recycling_Fee__c : 0;
					pli1.APTS_TAX_DK_specific_UOM__c = csptogenmap.get(ProductCodes).APTS_TAX_DK_specific_UOM__c != null ? csptogenmap.get(ProductCodes).APTS_TAX_DK_specific_UOM__c * uomFactor : 0;
					pli1.APTS_TAX_all_countries_UOM__c = csptogenmap.get(ProductCodes).APTS_TAX_all_countries_UOM__c != null ? csptogenmap.get(ProductCodes).APTS_TAX_all_countries_UOM__c * uomFactor : 0;
					pli1.APTS_Tax_per_UOM__c = csptogenmap.get(ProductCodes).APTS_Tax_per_UOM__c != null ? csptogenmap.get(ProductCodes).APTS_Tax_per_UOM__c * uomFactor : 0;
					pli1.APTS_VAT_indicator__c = csptogenmap.get(ProductCodes).APTS_VAT_indicator__c != null ? csptogenmap.get(ProductCodes).APTS_VAT_indicator__c : 0;
					pli1.APTS_VAT_percentage__c = csptogenmap.get(ProductCodes).APTS_VAT_percentage__c != null ? csptogenmap.get(ProductCodes).APTS_VAT_percentage__c : 0;
					pli1.APTS_Related_sales_org_data__c = csptogenmap.get(ProductCodes).APTS_Related_sales_org_data__c;
				}
			}
		}
		catch(Exception e) {
			APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getMessage() + '\n\n' + e.getStackTraceString(), 'APTS_PriceListItemTriggerHandler', null, 'CPQ', false, false, null, true);
		}
	}
}