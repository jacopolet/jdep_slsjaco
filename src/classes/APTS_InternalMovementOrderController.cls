/*************************************************************
@Name: APTS_InternalMovementOrderController
@Author: Galin Georgiev
@CreateDate: 01-06-2018
@Description: Create internal movement order
@UsedBy: Create Order button on Account page
******************************************************************/
//v100 01-06-2018 Galin Georgiev: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes
public with sharing class APTS_InternalMovementOrderController {

    private static final String MACHINE_ORDER = System.Label.APTS_Machine_Order;
    private static final String ID = System.Label.APTS_Id;
    private static final String AID = System.Label.APTS_aId;
    private static final String FIRSTPARAM = System.Label.APTS_firstParam;
    private static final String CREATEMACHINEORDERURL = System.Label.APTS_CreateMachineOrderUrl;
    private static final String PRODUCTORSERVICE = 'Product/Service';
    private static final String PAGE_MSG_NO_MACHINE_FOUND = 'No Machines found';
    private static final String PAGE_MSG_SELECT_MIN_ONE_MACHINE = 'Please select at least one Machine';
    private static final String TEMPORARY_DEACTIVATED = 'Temporary Deactivated';
    private static final String EMAIL = System.Label.APTS_Email;

    private Id accountId;
    private Id orderId;
    private Set<String> availableSerialNumberSet = new Set<String>();
    private Set<String> availableSerialNumberInitialSet = new Set<String>();
    private Integer iInitialCountToDisplay;
    private Integer iCountToDisplay;

    public Account oAccount {get; set;}
    public Apttus_Config2__Order__c oOrder {get; set;}
    public Date dtInstallDate {get; set;}
    public Date dtDeInstallDate {get; set;}
    public List<AssetWrapper> assetWrapperList {get; set;}
    public List<AssetWrapper> assetWrapperTmpList {get; set;}
    public List<AssetWrapper> assetWrapperDisplayList {get; set;}
    public AssetWrapper oSelectedAssetWrapper {get; set;}
    public Boolean bErrorOccurred {get; set;}
    public Boolean bLSPRequiredIndicator = false;
    public Boolean bRoundTripIndicator = false;

    public Id newCartId = null;
    public Map<Id, Apttus_Config2__LineItem__c> changedLineItemMap = null;
    public List<Id> assetIdChangeList = new List<Id>();

    public Id accountLocationId {get; set;}

    public String sSerialNumber {get; set;}
    public String sAllSerialNumbers {get; set;}

    public String serviceContactFromId;
    public String sServiceContactFrom {get; set;}
    public String sAllServiceContactFrom {get; set;}

    public String serviceContactToId;
    public String sServiceContactTo {get; set;}
    public String sAllServiceContactTo {get; set;}

    public Boolean bDisableMore {get; set;}
    public Boolean bDisableLess {get; set;}

    public Set<Integer> selectedIdSet = new Set<Integer>();
    public Set<Integer> deSelectedIdSet = new Set<Integer>();

    public APTS_InternalMovementOrderController() {

        accountId = ApexPages.currentPage().getParameters().get(AID);
        orderId = ApexPages.currentPage().getParameters().get(ID);

        bDisableMore = false;
        bDisableLess = true;
        sSerialNumber = null;

        assetWrapperList = new List<AssetWrapper>();
        assetWrapperTmpList = new List<AssetWrapper>();
        assetWrapperDisplayList = new List<AssetWrapper>();

        oAccount = [
                       SELECT Id, Name, Ultimate_Parent_Account__c,
                       Apttus_Config2__BillingPreferenceId__c, Apttus_Config2__PaymentTermId__c, Language__c,
                       Sales_Organization__c, Division__c, Distribution_Channel__c,
                       Bill_To_Payer_Account__c, Related_Payer_Account__c, Related_Payer_Machines_Services__c
                       FROM Account
                       WHERE Id = :accountId];

        oOrder = [
                     SELECT Id, Name, Apttus_Config2__PriceListId__c, Apttus_Config2__BillToAccountId__c,
                     Apttus_CMConfig__AgreementId__c, Apttus_Config2__PaymentTermId__c, Apttus_Config2__PrimaryContactId__c,
                     Apttus_Config2__SoldToAccountId__c, Apttus_Config2__ShipToAccountId__c, APTS_Payer__c, APTS_SAP_OrderType__c,
                     APTS_Delivery_Block__c, APTS_Order_Type__c, APTS_Order_Sub_Type__c, APTS_Requested_Delivery_Date__c,
                     APTS_Requested_Installation_Date__c, Apttus_CMConfig__AgreementId__r.Name, Apttus_Config2__PrimaryContactId__r.Name,
                     APTS_ServiceContact__c
                     FROM Apttus_Config2__Order__c
                     WHERE Id = :orderId];

        List<Apttus_Config2__OrderSystemProperties__c> orderSystemPropertyList = Apttus_Config2__OrderSystemProperties__c.getall().values();
        iInitialCountToDisplay = Integer.valueOf(orderSystemPropertyList[0].APTS_Orders_to_display__c);

        Map<Id, Apttus_Config2__AssetLineItem__c> assetLineItemMap = getAssetLineItemMap();

        Integer iId = 0;
        for (Apttus_Config2__AssetLineItem__c oAssetLineItem : assetLineItemMap.values()) {
            if (oAssetLineItem.APTS_Physical_Asset__r.SerialNumber__c != null) {
                if (oAssetLineItem.Apttus_Config2__IsPrimaryLine__c) {
                    assetWrapperList.add(new AssetWrapper(iId, false, oAssetLineItem, oAssetLineItem));
                } else {
                    //search for primary asset line item
                    for (Apttus_Config2__AssetLineItem__c oAssetLineItemTmp : assetLineItemMap.values()) {
                        if (oAssetLineItemTmp.Apttus_Config2__IsPrimaryLine__c && oAssetLineItemTmp.Apttus_Config2__LineNumber__c == oAssetLineItem.Apttus_Config2__LineNumber__c) {
                            assetWrapperList.add(new AssetWrapper(iId, false, oAssetLineItem, oAssetLineItemTmp));
                        }
                    }
                }

                deSelectedIdSet.add(iId);
                iId++;
                availableSerialNumberSet.add(oAssetLineItem.APTS_Physical_Asset__r.SerialNumber__c);
            }
        }

        availableSerialNumberInitialSet.addAll(availableSerialNumberSet);

        assetWrapperTmpList.addAll(assetWrapperList);

        if (iInitialCountToDisplay >= assetWrapperList.size()) {
            iCountToDisplay = assetWrapperList.size();
            bDisableMore = true;
        } else {
            iCountToDisplay = iInitialCountToDisplay;
        }

        for (Integer iIndex = 0; iIndex < iCountToDisplay; iIndex++) {
            AssetWrapper oAssetWrapper = assetWrapperList.get(iIndex);
            assetWrapperDisplayList.add(oAssetWrapper);
        }

        sServiceContactFrom = oOrder.Apttus_Config2__PrimaryContactId__r.Name;
        serviceContactFromId = oOrder.Apttus_Config2__PrimaryContactId__c;
    }

    private Map<Id, Apttus_Config2__AssetLineItem__c> getAssetLineItemMap() {

        Map<Id, Apttus_Config2__AssetLineItem__c> assetLineItemMap = new Map<Id, Apttus_Config2__AssetLineItem__c>();

        Set<Id> assetIdSet = new Set<Id>();
        List<Id> accountIdList = new List<Id> {accountId};

        Apttus_Config2.CPQStruct.QueryAssetsRequestDO request = new Apttus_Config2.CPQStruct.QueryAssetsRequestDO();
        request.AccountIds = accountIdList;
        Apttus_Config2.CPQStruct.QueryAssetsResponseDO response = Apttus_Config2.AssetService.getAssetLineItems(request);

        if (response != null && response.AssetLineItems != null && !response.AssetLineItems.isEmpty()) {

            assetIdSet = (new Map<Id, SObject>(response.AssetLineItems)).keySet();

            assetLineItemMap = new Map<Id, Apttus_Config2__AssetLineItem__c>([
                        SELECT Id, Name, Apttus_Config2__ProductId__r.Name,
                        Apttus_Config2__ProductId__c, Apttus_Config2__ProductId__r.APTS_LSP_Required__c, Apttus_Config2__BusinessLineItemId__c,
                        Apttus_Config2__Quantity__c, Apttus_Config2__SellingTerm__c, Apttus_Config2__StartDate__c,
                        Apttus_Config2__EndDate__c, Apttus_Config2__NetPrice__c, Apttus_Config2__AttributeValueId__r.APTS_Type_of_contract__c,
                        APTS_Physical_Asset__r.Id, APTS_Physical_Asset__r.SerialNumber__c, Apttus_Config2__PriceListId__c,
                        APTS_Physical_Asset__r.Building__c, APTS_Physical_Asset__r.Floor__c, APTS_Physical_Asset__r.Area__c,
                        APTS_Order_LSP_Detail__c, APTS_Physical_Asset__c, Apttus_Config2__IsPrimaryLine__c,
                        Apttus_Config2__LineNumber__c
                        FROM Apttus_Config2__AssetLineItem__c
                        WHERE Id IN :assetIdSet AND Apttus_Config2__LineType__c = :PRODUCTORSERVICE AND APTS_Sub_Status__c <> :TEMPORARY_DEACTIVATED LIMIT 10000]);
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, PAGE_MSG_NO_MACHINE_FOUND));
        }

        if (assetLineItemMap.isEmpty()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, PAGE_MSG_NO_MACHINE_FOUND));
        }

        return assetLineItemMap;
    }

    public void createMovementOrder() {

        if (validate()) {

            oOrder.APTS_Requested_De_Installation_Date__c = dtDeInstallDate;
            oOrder.APTS_Requested_Installation_Date__c = dtInstallDate;
            oOrder.APTS_LSP_Required_Indicator__c = bLSPRequiredIndicator;
            oOrder.APTS_Round_Trip_Indicator__c = bRoundTripIndicator;
            oOrder.Apttus_Config2__PrimaryContactId__c = serviceContactFromId;
            oOrder.APTS_ServiceContact__c = serviceContactToId;
            Database.update(oOrder);

            bErrorOccurred = false;
        } else {
            bErrorOccurred = true;
        }
    }

    public Boolean validate() {

        Boolean bResult = true;

        bLSPRequiredIndicator = false;
        bRoundTripIndicator = false;

        assetIdChangeList.clear();

        for (AssetWrapper oAssetWrapper : assetWrapperDisplayList) {
            if (oAssetWrapper.selected) {
                assetIdChangeList.add(oAssetWrapper.oPrimaryAssetLineItem.Id);
                if (oAssetWrapper.oAssetLineItem.Apttus_Config2__ProductId__r.APTS_LSP_Required__c) {
                    bLSPRequiredIndicator = true;
                }
                if (oAssetWrapper.bRoundTripIndicator) {
                    bRoundTripIndicator = true;
                }

                Boolean bMovementToBuildingEmpty = String.isEmpty(oAssetWrapper.sMovementToBuilding);
                Boolean bMovementToFloorEmpty = String.isEmpty(oAssetWrapper.sMovementToFloor);
                Boolean bMovementToAreaEmpty = String.isEmpty(oAssetWrapper.sMovementToArea);
                Boolean bMovementToAllEmpty = bMovementToBuildingEmpty && bMovementToFloorEmpty && bMovementToAreaEmpty;

                if (bMovementToAllEmpty) {
                    bResult = false;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter Movement To Details.'));
                }
            }
        }

        if (assetIdChangeList.isEmpty()) {
            bResult = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, PAGE_MSG_SELECT_MIN_ONE_MACHINE));
        }

        if (dtDeInstallDate != null) {

            DateTime dtDeInstallDateTmp = DateTime.newInstance(dtDeInstallDate.year(), dtDeInstallDate.month(), dtDeInstallDate.day());
            String sDeInstallDayOfWeek = dtDeInstallDateTmp.format('E');

            if (!'Mon'.equalsIgnoreCase(sDeInstallDayOfWeek)) {
                bResult = false;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Requested DeInstallation Date must be set to next Monday.'));
            }
        } else {
            bResult = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter Requested DeInstallation Date.'));
        }

        if (dtInstallDate != null) {
            DateTime dtInstallDateTmp = DateTime.newInstance(dtInstallDate.year(), dtInstallDate.month(), dtInstallDate.day());
            String sInstallDayOfWeek = dtInstallDateTmp.format('E');

            if (!'Mon'.equalsIgnoreCase(sInstallDayOfWeek)) {
                bResult = false;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Requested Installation Date must be set to next Monday.'));
            }
        } else {
            bResult = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter Requested Installation Date.'));
        }

        if (serviceContactFromId == null) {
            bResult = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter Service Contact From.'));
        }

        if (serviceContactToId == null) {
            bResult = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter Service Contact To.'));
        }

        return bResult;
    }

    //Create cart
    public void createCart() {

        try {
            if (!bErrorOccurred) {
                newCartId = APTS_OrderUtils.createCart(oOrder.Id);
            }
        } catch (Exception e) {
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id), 'OM', false, true, EMAIL, true);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error in cart creation'));
            bErrorOccurred = true;
        }
    }

    public void changeAssets() {

        try {
            if (!bErrorOccurred) {
                changedLineItemMap = APTS_OrderUtils.changeAssets(newCartId, assetIdChangeList);
            }
        } catch (Exception e) {
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id), 'OM', false, true, EMAIL, true);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error in change of assets'));
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            bErrorOccurred = true;
        }
    }

    public void saveCart() {

        try {
            if (!bErrorOccurred) {
                Apttus_Config2__ProductConfiguration__c oDeInstalledCart = APTS_OrderUtils.saveCart(newCartId);
                Database.update(oDeInstalledCart);
            }
        } catch (Exception e) {
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id), 'OM', false, true, EMAIL, true);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error while saving the cart'));
            bErrorOccurred = true;
        }
    }

    public void updatePhysicalAsset() {

        try {
            if (!bErrorOccurred) {
                /*
                                List<PhysicalAsset__c> physicalAssetToUpdateList = new List<PhysicalAsset__c>();

                                for (AssetWrapper oAssetWrapper : assetWrapperDisplayList) {
                                    if (oAssetWrapper.selected && oAssetWrapper.oAssetLineItem.APTS_Physical_Asset__c != null) {

                                        PhysicalAsset__c oPhysicalAsset = new PhysicalAsset__c(Id = oAssetWrapper.oAssetLineItem.APTS_Physical_Asset__c);
                                        oPhysicalAsset.Building__c = oAssetWrapper.sMovementToBuilding;
                                        oPhysicalAsset.Floor__c = oAssetWrapper.sMovementToFloor;
                                        oPhysicalAsset.Area__c = oAssetWrapper.sMovementToArea;

                                        physicalAssetToUpdateList.add(oPhysicalAsset);
                                    }
                                }

                                Database.update(physicalAssetToUpdateList);
                */
            }
        } catch (Exception e) {
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id), 'OM', false, true, EMAIL, true);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error while updating Physical Assets'));
            bErrorOccurred = true;
        }
    }

    public void updateLSP() {

        try {
            if (!bErrorOccurred) {

                List<APTS_Order_LSP_Details__c> lspDetailsList = new List<APTS_Order_LSP_Details__c>();

                for (AssetWrapper oAssetWrapper : assetWrapperDisplayList) {
                    if (oAssetWrapper.selected && oAssetWrapper.oAssetLineItem.APTS_Order_LSP_Detail__c != null) {

                        APTS_Order_LSP_Details__c oLSPDetails = new APTS_Order_LSP_Details__c(Id = oAssetWrapper.oAssetLineItem.APTS_Order_LSP_Detail__c);
                        oLSPDetails.APTS_Building__c = oAssetWrapper.sMovementToBuilding;
                        oLSPDetails.APTS_Floor__c = oAssetWrapper.sMovementToFloor;
                        oLSPDetails.APTS_Area__c = oAssetWrapper.sMovementToArea;

                        oLSPDetails.APTS_From_Building__c = oAssetWrapper.sMovementFromBuilding;
                        oLSPDetails.APTS_From_Floor__c = oAssetWrapper.sMovementFromFloor;
                        oLSPDetails.APTS_From_Area__c = oAssetWrapper.sMovementFromArea;

                        oLSPDetails.APTS_Require_Installation__c = oAssetWrapper.bInstallationRequired;
                        oLSPDetails.APTS_Require_De_Installation__c = oAssetWrapper.bDeInstallationRequired;
                        
                        oLSPDetails.APTS_Requires_LSP__c = bLSPRequiredIndicator;
                                                
                        lspDetailsList.add(oLSPDetails);
                    }
                }

                Database.update(lspDetailsList);
            }
        } catch (Exception e) {
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id), 'OM', false, true, EMAIL, true);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error while updating LSP Details'));
            bErrorOccurred = true;
        }
    }


    public PageReference goToPricing() {

        PageReference pageRef = null;
        String sFlow = 'NGMachineOrder';

        try {
            if (!bErrorOccurred) {
                pageRef = new PageReference('/apex/Apttus_Config2__OrderConfiguration?id=' + oOrder.Id + '&flow=' + sFlow + '&launchState=cart');
            }
        } catch (Exception e) {
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id), 'OM', false, true, EMAIL, true);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error while redirecting to cart'));
        }

        return pageRef;
    }

    public void setSelectedAssetWrapper() {

        oSelectedAssetWrapper = null;
        Boolean bDeSelectAction = false;

        for (AssetWrapper oAssetWrapper : assetWrapperDisplayList) {

            if (oAssetWrapper.selected) {
                if (!selectedIdSet.contains(oAssetWrapper.iId)) {
                    selectedIdSet.add(oAssetWrapper.iId);
                }
            } else {
                if (selectedIdSet.contains(oAssetWrapper.iId)) {
                    selectedIdSet.remove(oAssetWrapper.iId);
                    deSelectedIdSet.add(oAssetWrapper.iId);
                    bDeSelectAction = true;
                }
            }
        }

        Integer selectedId;

        for (Integer iId : selectedIdSet) {
            if (!bDeSelectAction) {
                if (deSelectedIdSet.contains(iId)) {
                    selectedId = iId;
                }
            } else {
                if (!deSelectedIdSet.contains(iId)) {
                    selectedId = iId;
                }
            }

        }

        deSelectedIdSet.remove(selectedId);

        for (AssetWrapper oAssetWrapper : assetWrapperDisplayList) {
            if (oAssetWrapper.iId == selectedId) {
                oSelectedAssetWrapper = oAssetWrapper;
            }
        }
    }

    public void resetAssetSearch() {

        sSerialNumber = null;

        assetWrapperList.clear();
        assetWrapperList.addAll(assetWrapperTmpList);

        availableSerialNumberSet.clear();
        availableSerialNumberSet.addAll(availableSerialNumberInitialSet);

        iCountToDisplay = iInitialCountToDisplay;
        Integer iMinCount = iInitialCountToDisplay <= assetWrapperList.size() ? iInitialCountToDisplay : assetWrapperList.size();
        assetWrapperDisplayList.clear();
        bDisableLess = true;

        for (Integer iIndex = 0; iIndex < iMinCount; iIndex++) {
            AssetWrapper oAssetWrapper = assetWrapperList.get(iIndex);
            oAssetWrapper.selected = false;
            assetWrapperDisplayList.add(oAssetWrapper);
        }

        if (iCountToDisplay < assetWrapperList.size()) {
            bDisableMore = false;
        } else {
            bDisableMore = true;
        }
    }

    public void searchSerialNumbers() {

        sAllSerialNumbers = '[';

        String searchStr = ApexPages.currentPage().getParameters().get(FIRSTPARAM);

        Set<String> filteredSerialNumberSet = new Set<String>();

        for (String sSerialNumber : availableSerialNumberSet) {
            if (sSerialNumber.containsIgnoreCase(searchStr)) {
                filteredSerialNumberSet.add(sSerialNumber);
            }
        }

        if (!filteredSerialNumberSet.isEmpty()) {
            Integer count = filteredSerialNumberSet.size();
            Integer iId = 0;
            for (String sSerialNumber : filteredSerialNumberSet) {

                sAllSerialNumbers += '{\'label\':\'' + sSerialNumber + '\',\'value\':\'' + iId +  '\'}';
                if (--count != 0) {
                    sAllSerialNumbers += ',';
                }
                iId++;
            }
        }

        sAllSerialNumbers += ']';
    }

    public void doAssetSearch() {

        Set<Integer> indexToRemoveSet = new Set<Integer>();
        Integer index = 0;

        assetWrapperList.clear();
        assetWrapperList.addAll(assetWrapperTmpList);

        availableSerialNumberSet.clear();
        availableSerialNumberSet.addAll(availableSerialNumberInitialSet);

        for (AssetWrapper oAssetWrapper : assetWrapperList) {
            if (!String.isBlank(sSerialNumber)) {
                if (oAssetWrapper.oAssetLineItem.APTS_Physical_Asset__r.SerialNumber__c != sSerialNumber) {
                    indexToRemoveSet.add(index);
                }
            }
            index++;
        }

        for (Integer i : indexToRemoveSet) {
            AssetWrapper oAssetWrapper = assetWrapperList.get(i);
            availableSerialNumberSet.remove(oAssetWrapper.oAssetLineItem.APTS_Physical_Asset__r.SerialNumber__c);
        }

        for (Integer i = assetWrapperList.size(); i >= 0; i--) {
            if (indexToRemoveSet.contains(i)) {
                assetWrapperList.remove(i);
            }
        }

        assetWrapperDisplayList.clear();
        if (iInitialCountToDisplay >= assetWrapperList.size()) {
            iCountToDisplay = assetWrapperList.size();
            bDisableMore = true;
        } else {
            iCountToDisplay = iInitialCountToDisplay;
        }

        for (Integer iIndex = 0; iIndex < iCountToDisplay; iIndex++) {
            AssetWrapper oAssetWrapper = assetWrapperList.get(iIndex);
            assetWrapperDisplayList.add(oAssetWrapper);
        }
    }

    public void searchServiceContactFrom() {

        sAllServiceContactFrom = '[';

        String searchStr = ApexPages.currentPage().getParameters().get('serviceContactFrom');
        searchStr = '%' + searchStr + '%';
        List<Contact> contactList = [
                                        SELECT Id, Name
                                        FROM Contact
                                        WHERE Id IN (SELECT ContactId FROM AccountContactRelation WHERE AccountId = :accountId) AND Name LIKE :searchStr LIMIT 20];

        if (!contactList.isEmpty()) {

            Integer count = contactList.size();

            if (count == 1) {
                serviceContactFromId = contactList.get(0).Id;
            } else {
                serviceContactFromId = null;
            }

            for (Contact oContact : contactList) {
                sAllServiceContactFrom += '{\'label\':\'' + oContact.Name + '\',\'value\':\'' + oContact.Id +  '\'}';
                if (--count != 0) {
                    sAllServiceContactFrom += ',';
                }
            }
        }

        sAllServiceContactFrom += ']'; 
    }

    public void searchServiceContactTo() {

        sAllServiceContactTo = '[';

        String searchStr = ApexPages.currentPage().getParameters().get('serviceContactTo');
        searchStr = '%' + searchStr + '%';
        List<Contact> contactList = [
                                        SELECT Id, Name
                                        FROM Contact
                                        WHERE Id IN (SELECT ContactId FROM AccountContactRelation WHERE AccountId = :accountId) AND Name LIKE :searchStr LIMIT 20];

        if (!contactList.isEmpty()) {
            
            Integer count = contactList.size();
            
            if (count == 1) {
                serviceContactToId = contactList.get(0).Id;
            } else {
                serviceContactToId = null;
            }

            for (Contact oContact : contactList) {
                sAllServiceContactTo += '{\'label\':\'' + oContact.Name + '\',\'value\':\'' + oContact.Id +  '\'}';
                if (--count != 0) {
                    sAllServiceContactTo += ',';
                }
            }
        }

        sAllServiceContactTo += ']';
    }

    public void setServiceContactFrom() {

        serviceContactFromId = ApexPages.currentPage().getParameters().get('serviceContactFrom');
    }

    public void setServiceContactTo() {

        serviceContactToId = ApexPages.currentPage().getParameters().get('serviceContactTo');
    }

    public void loadMore() {

        bDisableLess = false;
        iCountToDisplay = iCountToDisplay + iInitialCountToDisplay;
        Integer iMaxCount = iCountToDisplay;

        if (iCountToDisplay >= assetWrapperList.size()) {
            iMaxCount = assetWrapperList.size();
            bDisableMore = true;
        }

        assetWrapperDisplayList.clear();
        for (Integer iIndex = 0; iIndex < iMaxCount; iIndex++) {
            AssetWrapper oAssetWrapper = assetWrapperList.get(iIndex);
            assetWrapperDisplayList.add(oAssetWrapper);
        }
    }

    public void loadLess() {

        bDisableMore = false;

        if ((iCountToDisplay - iInitialCountToDisplay) <= iInitialCountToDisplay) {
            iCountToDisplay = iInitialCountToDisplay;
            bDisableLess = true;
        } else {
            iCountToDisplay = iCountToDisplay - iInitialCountToDisplay;
        }

        assetWrapperDisplayList.clear();
        for (Integer iIndex = 0; iIndex < iCountToDisplay; iIndex++) {
            AssetWrapper oAssetWrapper = assetWrapperList.get(iIndex);
            assetWrapperDisplayList.add(oAssetWrapper);
        }
    }

    public PageReference back() {

        PageReference pageRef;
        pageRef = new PageReference('/' + accountId);

        if (oOrder != null) {
            Database.delete(oOrder);
        }

        if (newCartId != null) {
            Apttus_Config2__ProductConfiguration__c oNewCart = new Apttus_Config2__ProductConfiguration__c(Id = newCartId);
            Database.delete(oNewCart);
        }

        return pageRef;
    }

    public PageReference backToAgreement() {

        PageReference pageRef;
        pageRef = new PageReference(CREATEMACHINEORDERURL + accountId);

        if (oOrder != null) {
            Database.delete(oOrder);
        }

        if (newCartId != null) {
            Apttus_Config2__ProductConfiguration__c oNewCart = new Apttus_Config2__ProductConfiguration__c(Id = newCartId);
            Database.delete(oNewCart);
        }

        return pageRef;
    }

    public with sharing class AssetWrapper {

        public Integer iId {get; set;}
        public Boolean selected {get; set;}
        public Apttus_Config2__AssetLineItem__c oAssetLineItem {get; set;}
        public Apttus_Config2__AssetLineItem__c oPrimaryAssetLineItem {get; set;}
        public Boolean bDeInstallationRequired {get; set;}
        public Boolean bRoundTripIndicator {get; set;}
        public Date deInstallDate {get; set;}
        public String sMovementFromBuilding {get; set;}
        public String sMovementFromFloor {get; set;}
        public String sMovementFromArea {get; set;}
        public Boolean bInstallationRequired {get; set;}
        public Boolean bLSPRequired {get; set;}
        public Date installDate {get; set;}
        public String sMovementToBuilding {get; set;}
        public String sMovementToFloor {get; set;}
        public String sMovementToArea {get; set;}

        public AssetWrapper(Integer iId, Boolean selected, Apttus_Config2__AssetLineItem__c oAssetLineItem, Apttus_Config2__AssetLineItem__c oPrimaryAssetLineItem) {

            this.iId = iId;
            this.selected = selected;
            this.oAssetLineItem = oAssetLineItem;
            this.oPrimaryAssetLineItem = oPrimaryAssetLineItem;
            this.bDeInstallationRequired = true;
            this.bRoundTripIndicator = false;
            this.deInstallDate = null;
            this.sMovementFromBuilding = oAssetLineItem.APTS_Physical_Asset__r.Building__c;
            this.sMovementFromFloor = oAssetLineItem.APTS_Physical_Asset__r.Floor__c;
            this.sMovementFromArea = oAssetLineItem.APTS_Physical_Asset__r.Area__c;
            this.bInstallationRequired = true;
            this.bLSPRequired = true;
            this.installDate = null;
            this.sMovementToBuilding = '';
            this.sMovementToFloor = '';
            this.sMovementToArea = '';
        }
    }
}