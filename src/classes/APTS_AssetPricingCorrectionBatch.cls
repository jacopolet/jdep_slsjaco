/*************************************************************
@Name: APTS_AssetPricingCorrectionBatch
@Author: Aarthi Pitchai
@CreateDate: 27-06-2019
@Description: Batch implemented to correct the Pricing at Asset Line Items of Machine orders
******************************************************************/
global class APTS_AssetPricingCorrectionBatch implements Database.Batchable<sObject>, Database.Stateful{

    private Map<Id, Apttus_Config2__AssetLineItem__c> mapUpdatedAssetLines;
    private List<APTS_Asset_Correction_Configuration__c> lstAssetCorrectionRecords;
    private set<Id> setUpdatedAssetLines;   
    private Map<Id, string> mapErroredAssetLines;
    private set<Id> setAssetLines;
    private Set<Id> setAllOrders;
    public APTS_AssetPricingCorrectionBatch() {
        mapUpdatedAssetLines = new Map<Id, Apttus_Config2__AssetLineItem__c >();
        lstAssetCorrectionRecords = new List<APTS_Asset_Correction_Configuration__c>();
        setUpdatedAssetLines = new set<Id>();   
        mapErroredAssetLines = new Map<Id, String>();
        setAssetLines = new set<Id>();
        setAllOrders = new set<Id>();
    }
    /** Method : start
    ** Description : Query locator which will query records with Status = New and ParentLog = NULL
    **/
    global Database.QueryLocator start(Database.BatchableContext BC) {
        
        set<id> setAssetIds = new set<id>();
        lstAssetCorrectionRecords = [Select id, APTS_Asset_Line_Item__c, APTS_Error_Message__c, APTS_Has_Error__c, APTS_Is_Updated__c from APTS_Asset_Correction_Configuration__c where APTS_Is_Updated__c = false];
       for(APTS_Asset_Correction_Configuration__c oACC: lstAssetCorrectionRecords)
       {
            setAssetIds.add(oACC.APTS_Asset_Line_Item__c);
       }
        String query = 'Select id, Apttus_Config2__AccountId__c, Apttus_Config2__BillToAccountId__c, Apttus_CMConfig__AgreementId__c, Apttus_Config2__PriceListId__c, Apttus_Config2__BillingPreferenceId__c from Apttus_Config2__AssetLineItem__c where id IN :setAssetIds';
        return Database.getQueryLocator(query);
    }
    /** Method : execute
    ** Description : batch execute method would process and create Admin orders
    **/
    global void execute(Database.BatchableContext BC, List<Apttus_Config2__AssetLineItem__c> assetList) {    
        List<Apttus_Config2__AssetLineItem__c> lstAssetLines = new List<Apttus_Config2__AssetLineItem__c >();
        Map<Id, Apttus_Config2__AssetLineItem__c> mapAssetLines = new Map<Id, Apttus_Config2__AssetLineItem__c >();
        Apttus_Config2__AssetLineItem__c currentAsset = new Apttus_Config2__AssetLineItem__c();
        Set<Id> orderIdSet = new Set<Id>();
        List<Apttus_Config2__OrderLineItem__c> childOLIList = new List<Apttus_Config2__OrderLineItem__c>();
      
        List<Apttus_Config2__OrderLineItem__c> l1OLIList = new List<Apttus_Config2__OrderLineItem__c>();
        List<Apttus_Config2__OrderLineItem__c> updateOLIList = new List<Apttus_Config2__OrderLineItem__c>();
        //Map<Id, Apttus_Config2__AssetLineItem__c> mapErroredAssetLines = new Map<Id, Apttus_Config2__AssetLineItem__c >();
       APTS_OrderUtils.stopOrderTrigger();
        APTS_OrderUtils.stopOrderLineItemTrigger();
        APTS_OrderUtils.stopAssetLineItemTrigger();
    try{  
    if(!assetList.isEmpty())
    {
        for(Apttus_Config2__AssetLineItem__c oAsset :assetList)
        {
            mapAssetLines.put(oAsset.Id, oAsset); 
            lstAssetLines.add(oAsset);
            setAssetLines.add(oAsset.Id);
        }
        
        currentAsset = lstAssetLines[0];
        Apttus_Config2__Order__c oOrder = new Apttus_Config2__Order__c();
        oOrder = APTS_OrderUtils.setOrderHeaderMandatoryFields(oOrder, 'Admin Order');
        oOrder.Apttus_Config2__Source__c = 'ACCOUNT';
        oOrder.APTS_SAP_OrderType__c = 'XA13';
        oOrder.Apttus_Config2__AutoActivateOrder__c = true;
        oOrder.Apttus_Config2__SoldToAccountId__c = currentAsset.Apttus_Config2__AccountId__c;
        oOrder.Apttus_Config2__BillToAccountId__c = currentAsset.Apttus_Config2__BillToAccountId__c;
        oOrder.Apttus_CMConfig__AgreementId__c = currentAsset.Apttus_CMConfig__AgreementId__c;
        oOrder.Apttus_Config2__PriceListId__c = currentAsset.Apttus_Config2__PriceListId__c;
        oOrder.Apttus_Config2__BillingPreferenceId__c = currentAsset.Apttus_Config2__BillingPreferenceId__c;
        Database.Insert(oOrder, false);
        
        Id cartId = null;
       
            cartId = APTS_OrderUtils.createCart(oOrder.Id);
            system.debug('AssetId = ' + currentAsset.id + ' OrderId = ' + oOrder.Id + ' CartId = ' + cartId);
            Apttus_Config2.CPQStruct.ChangeAssetsRequestDO request = new Apttus_Config2.CPQStruct.ChangeAssetsRequestDO();
            request.AssetIds = new List<Id> {currentAsset.id};
            request.CartId = cartId;
            Apttus_Config2.CPQStruct.ChangeAssetsResponseDO response = Apttus_Config2.AssetService.changeAssets(request);
            Map<Id, Apttus_Config2__LineItem__c> mapLines = response.LineItemMap;
            List<Apttus_Config2__LineItem__c> listLineItemsToUpdate = new List<Apttus_Config2__LineItem__c>();
         
            for (Apttus_Config2__LineItem__c lineItem : mapLines.values()) {
                   lineItem.Apttus_Config2__IsAssetPricing__c = false;
                   listLineItemsToUpdate.add(lineItem);
            }
             if (!listLineItemsToUpdate.isEmpty()) {
                update listLineItemsToUpdate;                
            }
           //Update Pricing until isPricingPending flag becomes 'False'
                    Boolean isPricePending = true;
                    while (isPricePending) {
                        isPricePending = APTS_OrderUtils.repriceCart(cartId);
                        if (!isPricePending) {
                            break;
                        }
                    }
            APTS_OrderUtils.finalizeCart(cartId);
            APTS_OrderUtils.syncCart(cartId);
            setUpdatedAssetLines.add(currentAsset.id);
            orderIdSet.add(oOrder.Id);         
            setAllOrders.add(oOrder.Id);
            APTS_BillingScheduleTriggerHandler.isSkipBillingScheduleTrigger = true;
            childOLIList = APTS_AdminOrderQueue.getChildOLIs(orderIdSet);
            for(Apttus_Config2__OrderLineItem__c oLI : childOLIList){
                oLI.APTS_Item_Relevant_for_SAP__c = false;
                oLI.Apttus_Config2__Status__c = 'Fulfilled';
                updateOLIList.add(oLI); 
               
                if(oLI.Apttus_Config2__IsPrimaryLine__c && oLI.Apttus_Config2__LineType__c == 'Product/Service'){
                Apttus_Config2__OrderLineItem__c oLITemp = new Apttus_Config2__OrderLineItem__c();
                oLITemp.Id = oLI.Id; 
                oLITemp.Apttus_Config2__ReadyForBillingDate__c = oLI.Apttus_Config2__StartDate__c;
                oLITemp.Apttus_Config2__ActivatedDate__c = oLI.Apttus_Config2__StartDate__c;
                l1OLIList.add(oLITemp);
                }
                
            }
            if(updateOLIList.size()>0){
            Database.update(updateOLIList, false);
            }
            if(l1OLIList.size()>0){
               System.enqueueJob(new APTS_ActivateOrderQueueable(l1OLIList));        
            }
            }
        }
        catch(Exception e)
        {
            mapErroredAssetLines.put(currentAsset.id,e.getStackTraceString());
             APTS_CustomLogging.createErrorLog('Asset Correction :: ' +e.getTypeName(), 'Apex', e.getStackTraceString() , 'Asset Line Item', (currentAsset != null)? currentAsset.id: null , 'OM', false, true, null, true);
       
        }
    }
    /** Method : finish
    ** Description : batch finish
    **/
    global void finish(Database.BatchableContext BC) {
        APTS_OrderUtils.stopOrderTrigger();
        APTS_OrderUtils.stopOrderLineItemTrigger();
        APTS_OrderUtils.stopAssetLineItemTrigger();
        try{
        //Update the Asset Line Items Batch update Type
        List<Apttus_Config2__AssetLineItem__c> lstALI = new List<Apttus_Config2__AssetLineItem__c>();
        List<Apttus_Config2__OrderLineItem__c> lstAllOrderLineItems = [Select id, Apttus_Config2__AssetLineItemId__c from Apttus_Config2__OrderLineItem__c where Apttus_Config2__OrderId__c IN :setAllOrders];
        
        system.debug('setAssetLines :: '+setAssetLines);
        for(Apttus_Config2__OrderLineItem__c oOLI : lstAllOrderLineItems)
        {
            Apttus_Config2__AssetLineItem__c oAsset = new Apttus_Config2__AssetLineItem__c();
            oAsset.Id = oOLI.Apttus_Config2__AssetLineItemId__c;
            oAsset.APTS_Batch_Update_Type__c = 'Asset Pricing correction';
            lstALI.add(oAsset);
        }
        system.debug('lstALI :: '+lstALI);
        if(!lstALI.isEmpty())
        {
            Database.update(lstALI, false);
        }
        //Update the Custom settings with values
        system.debug('lstAssetCorrectionRecords :: '+lstAssetCorrectionRecords);
        List<APTS_Asset_Correction_Configuration__c> lstAssetCorrectionRecordsToUpdate = new List<APTS_Asset_Correction_Configuration__c>();
        if(!lstAssetCorrectionRecords.isEmpty())
        {
            for(APTS_Asset_Correction_Configuration__c oACR : lstAssetCorrectionRecords)
            {
                if(setUpdatedAssetLines.contains(oACR.APTS_Asset_Line_Item__c))
                {
                    oACR.APTS_Is_Updated__c = true;
                    lstAssetCorrectionRecordsToUpdate.add(oACR);
                }
                else if(mapErroredAssetLines.containsKey(oACR.APTS_Asset_Line_Item__c))
                {
                    oACR.APTS_Is_Updated__c = false;
                    oACR.APTS_Has_Error__c = true;
                    oACR.APTS_Error_Message__c = mapErroredAssetLines.get(oACR.APTS_Asset_Line_Item__c);
                    lstAssetCorrectionRecordsToUpdate.add(oACR);
                }              

            }
            if(!lstAssetCorrectionRecordsToUpdate.isEmpty())
            {
                Database.update(lstAssetCorrectionRecordsToUpdate, false);
            }
        }
        }
        catch(Exception e)
        {
              APTS_CustomLogging.createErrorLog('Asset Correction :: ' +e.getTypeName(), 'Apex', e.getStackTraceString() , 'Asset Line Item', null , 'OM', false, true, null, true);   
        }

        APTS_OrderUtils.startAssetLineItemTrigger();
        APTS_OrderUtils.startOrderLineItemTrigger();
        APTS_OrderUtils.startOrderTrigger();
    }
    

 }