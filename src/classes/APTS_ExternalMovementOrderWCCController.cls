/*************************************************************
@Name: APTS_ExternalMovementOrderWCCController
@Author: Galin Georgiev
@CreateDate: 01-06-2018
@Description: External Movement Order without contract change from Account
@UsedBy: Create Order button on Account page
******************************************************************/
//v100 01-06-2018 Galin Georgiev: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes
public with sharing class APTS_ExternalMovementOrderWCCController {

    private static final String MACHINE_ORDER = System.Label.APTS_Machine_Order;
    private static final String ACCOUNT = System.Label.APTS_Account;
    private static final String ID = System.Label.APTS_Id;
    private static final String AID = System.Label.APTS_aId;
    private static final String FIRSTPARAM = System.Label.APTS_firstParam;
    private static final String CREATEMACHINEORDERURL = System.Label.APTS_CreateMachineOrderUrl;
    private static final String PRODUCTORSERVICE = 'Product/Service';
    private static final String PAGE_MSG_NO_MACHINE_FOUND = 'No Machines found';
    private static final String PAGE_MSG_SELECT_MIN_ONE_MACHINE = 'Please select at least one Machine';
    private static final String XB13 = System.Label.APTS_XB13;
    private static final String TEMPORARY_DEACTIVATED = 'Temporary Deactivated';
    private static final String EMAIL = System.Label.APTS_Email;

    private Id accountId;
    private Id deInstallOrderId;
    private Id amendedAgreementId;
    public Id installAgreementId;
    private Set<String> availableSerialNumberSet = new Set<String>();
    private Set<String> availableSerialNumberInitialSet = new Set<String>();
    private Integer iInitialCountToDisplay;
    private Integer iCountToDisplay;
    private Id installAccountId;
    private Apttus_Config2__Order__c oInstallOrder;
    private Map<Id, Apttus_Config2__LineItem__c> idToLineItemMap = new Map<Id, Apttus_Config2__LineItem__c>();
    private Map<String, Id> productIdAndLineNumberAndChargeTypeToLIIdMap = new Map<String, Id>();
    private Set<String> selectedSerialNumberSet = new Set<String>();
    private Map<Id, Apttus__AgreementLineItem__c> installAgreementLineItemMap = new Map<Id, Apttus__AgreementLineItem__c>();
    private Map<Id, Apttus_Config2__OrderLineItem__c> installOrderLineItemMap;

    public Account oAccount {get; set;}
    public Apttus_Config2__Order__c oDeInstallOrder {get; set;}
    public Apttus__APTS_Agreement__c oInstallAgreement {get; set;}
    public Date dtInstallDate {get; set;}
    public Date dtDeInstallDate {get; set;}
    public List<AssetWrapper> assetWrapperList {get; set;}
    public List<AssetWrapper> assetWrapperTmpList {get; set;}
    public List<AssetWrapper> assetWrapperDisplayList {get; set;}
    public AssetWrapper oSelectedAssetWrapper {get; set;}
    public Boolean bErrorOccurred {get; set;}
    public Boolean bLSPRequiredIndicator = false;
    public Boolean bRoundTripIndicator = false;

    public Id deInstallCartId = null;
    public Id installCartId = null;
    public Map<Id, Apttus_Config2__LineItem__c> changedLineItemMap = null;

    public List<Id> assetIdDeInstallList = new List<Id>();
    public Map<Id, Apttus_Config2__LineItem__c> deInstalledLineItemMap = null;

    public Id accountHierarchyId {get; set;}

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

    public APTS_ExternalMovementOrderWCCController() {

        accountId = ApexPages.currentPage().getParameters().get(AID);
        deInstallOrderId = ApexPages.currentPage().getParameters().get(ID);

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

        oDeInstallOrder = [
                              SELECT Id, Name, Apttus_Config2__PriceListId__c, Apttus_Config2__BillToAccountId__c,
                              Apttus_CMConfig__AgreementId__c, Apttus_Config2__PaymentTermId__c, Apttus_Config2__PrimaryContactId__c,
                              Apttus_Config2__SoldToAccountId__c, Apttus_Config2__ShipToAccountId__c, APTS_Payer__c, APTS_SAP_OrderType__c,
                              APTS_Delivery_Block__c, APTS_Order_Type__c, APTS_Order_Sub_Type__c, APTS_Requested_Delivery_Date__c,
                              APTS_Requested_Installation_Date__c, Apttus_CMConfig__AgreementId__r.Name, Apttus_Config2__PrimaryContactId__r.Name,
                              APTS_ServiceContact__c
                              FROM Apttus_Config2__Order__c
                              WHERE Id = :deInstallOrderId];

        amendedAgreementId = oDeInstallOrder.Apttus_CMConfig__AgreementId__c;

        Map<Id, Apttus__AgreementLineItem__c> amendedAgreementLineItemMap = new Map<Id, Apttus__AgreementLineItem__c>([
                    SELECT Id, Apttus_CMConfig__AssetLineItemId__r.APTS_Physical_Asset__r.SerialNumber__c,
                    Apttus_CMConfig__IsPrimaryLine__c, Apttus_CMConfig__HasOptions__c, Apttus_CMConfig__AssetLineItemId__c
                    FROM Apttus__AgreementLineItem__c
                    WHERE Apttus__AgreementId__c = :amendedAgreementId AND Apttus_CMConfig__LineStatus__c = 'Cancelled']);

        Set<String> serialNumberSet = new Set<String>();
        Set<Id> bundleAssetIdSet = new Set<Id>();

        for (Apttus__AgreementLineItem__c oAmendedAgreementLineItem : amendedAgreementLineItemMap.values()) {

            if (oAmendedAgreementLineItem.Apttus_CMConfig__AssetLineItemId__r.APTS_Physical_Asset__r.SerialNumber__c != null) {
                serialNumberSet.add(oAmendedAgreementLineItem.Apttus_CMConfig__AssetLineItemId__r.APTS_Physical_Asset__r.SerialNumber__c);
                bundleAssetIdSet.add(oAmendedAgreementLineItem.Apttus_CMConfig__AssetLineItemId__c);
            }

            if (oAmendedAgreementLineItem.Apttus_CMConfig__IsPrimaryLine__c && oAmendedAgreementLineItem.Apttus_CMConfig__HasOptions__c) {
                bundleAssetIdSet.add(oAmendedAgreementLineItem.Apttus_CMConfig__AssetLineItemId__c);
            }
        }

        Map<Id, Apttus__AgreementLineItem__c> sameSerialNumberAgreementLineItemMap = new Map<Id, Apttus__AgreementLineItem__c>([
                    SELECT Id, Apttus_CMConfig__DerivedFromId__c, Apttus_CMConfig__IsPrimaryLine__c,
                    Apttus_CMConfig__HasOptions__c, Apttus__ProductId__c, Apttus_CMConfig__LineNumber__c,
                    Apttus_CMConfig__ChargeType__c, Apttus_CMConfig__OptionId__c, APTS_Serial_Number__c,
                    Apttus_CMConfig__AssetLineItemId__c, Apttus_CMConfig__LineStatus__c, Apttus__AgreementId__c,
                    Apttus__AgreementId__r.Apttus__Account__c, APTS_Serial_Number2__c
                    FROM Apttus__AgreementLineItem__c
                    WHERE APTS_Serial_Number2__c IN :serialNumberSet]);

        Set<Id> installAgreementIdSet = new Set<Id>();
        List<Id> installAgreementIdList = new List<Id>();

        for (Apttus__AgreementLineItem__c oSameSerialNumberAgreementLineItem : sameSerialNumberAgreementLineItemMap.values()) {

            Boolean bLineStatusNew = oSameSerialNumberAgreementLineItem.Apttus_CMConfig__LineStatus__c == 'New';
            Boolean bDifferentSoldTo = oSameSerialNumberAgreementLineItem.Apttus__AgreementId__r.Apttus__Account__c != accountId;

            if (bLineStatusNew && bDifferentSoldTo) {
                installAgreementIdSet.add(oSameSerialNumberAgreementLineItem.Apttus__AgreementId__c);
                installAgreementIdList.add(oSameSerialNumberAgreementLineItem.Apttus__AgreementId__c);
            }
        }

        if (sameSerialNumberAgreementLineItemMap.isEmpty()) {
            ApexPages.Message oErrorMessage = new ApexPages.Message(ApexPages.Severity.ERROR, PAGE_MSG_NO_MACHINE_FOUND);
            ApexPages.addMessage(oErrorMessage);
        }

        if (!installAgreementIdSet.isEmpty()) {
            if (installAgreementIdSet.size() == 1) {
                installAgreementId = installAgreementIdList.get(0);
            } else {
                ApexPages.Message oErrorMessage = new ApexPages.Message(ApexPages.Severity.ERROR, 'More than one install agreement');
                ApexPages.addMessage(oErrorMessage);
            }
        } else {
            ApexPages.Message oErrorMessage = new ApexPages.Message(ApexPages.Severity.ERROR, 'There is no install agreement');
            ApexPages.addMessage(oErrorMessage);
        }

        List<Apttus__APTS_Agreement__c> installAgreementList = [
                    SELECT Id, Name, Apttus__Account__r.Name,
                    Apttus_CMConfig__PriceListId__c, Apttus_CMConfig__BillingPreferenceId__c,
                    Apttus__Account__c, Apttus_CMConfig__PONumber__c, Apttus_CMConfig__PaymentTermId__c,
                    APTS_Bill_to_Party_Ingredients__c, APTS_Payer_Ingredients__c, APTS_Bill_to_Party_MachServ__c,
                    APTS_Language__c, APTS_Payer_Machines_Services__c,
                    APTS_Check_on_Account_Machines__c,APTS_Check_on_Account_Ingredients__c
                    FROM Apttus__APTS_Agreement__c
                    WHERE Id = :installAgreementId];

        if (!installAgreementList.isEmpty()) {
            oInstallAgreement = installAgreementList.get(0);
            installAccountId = oInstallAgreement.Apttus__Account__c;
        }

        Map<Id, Apttus__AgreementLineItem__c> allAgreementLineItemMap = new Map<Id, Apttus__AgreementLineItem__c>([
                    SELECT Id, Apttus_CMConfig__DerivedFromId__c, Apttus_CMConfig__IsPrimaryLine__c,
                    Apttus_CMConfig__HasOptions__c, Apttus__ProductId__c, Apttus_CMConfig__LineNumber__c,
                    Apttus_CMConfig__ChargeType__c, Apttus_CMConfig__OptionId__c, APTS_Serial_Number__c,
                    Apttus_CMConfig__AssetLineItemId__c, Apttus_CMConfig__LineStatus__c, Apttus__AgreementId__c,
                    Apttus__AgreementId__r.Apttus__Account__c, APTS_Serial_Number2__c
                    FROM Apttus__AgreementLineItem__c
                    WHERE Apttus__AgreementId__c = :installAgreementId]);


        for (Apttus__AgreementLineItem__c oAllAgreementLineItem : allAgreementLineItemMap.values()) {

            Boolean bLineStatusNew = oAllAgreementLineItem.Apttus_CMConfig__LineStatus__c == 'New';
            Boolean bDifferentSoldTo = oAllAgreementLineItem.Apttus__AgreementId__r.Apttus__Account__c != accountId;

            if (bLineStatusNew && bDifferentSoldTo) {
                installAgreementLineItemMap.put(oAllAgreementLineItem.Id, oAllAgreementLineItem);
            }
        }

        List<Apttus_Config2__OrderSystemProperties__c> orderSystemPropertyList = Apttus_Config2__OrderSystemProperties__c.getall().values();
        iInitialCountToDisplay = Integer.valueOf(orderSystemPropertyList[0].APTS_Orders_to_display__c);

        Map<Id, Apttus_Config2__AssetLineItem__c> assetLineItemMap = getAssetLineItemMap(bundleAssetIdSet);

        Integer iId = 0;
        for (Apttus_Config2__AssetLineItem__c oAssetLineItem : assetLineItemMap.values()) {

            if (oAssetLineItem.APTS_Physical_Asset__r.SerialNumber__c != null) {
                if (oAssetLineItem.Apttus_Config2__IsPrimaryLine__c) {
                    assetWrapperList.add(new AssetWrapper(iId, false, oAssetLineItem, oAssetLineItem));
                } else {
                    //search for primary asset line item
                    for (Apttus_Config2__AssetLineItem__c oAssetLineItemTmp : assetLineItemMap.values()) {
                        if (oAssetLineItemTmp.Apttus_Config2__IsPrimaryLine__c && oAssetLineItemTmp.Apttus_Config2__LineNumber__c == oAssetLineItem.Apttus_Config2__LineNumber__c) {
                            assetWrapperList.add(new AssetWrapper(iId, false, oAssetLineItemTmp, oAssetLineItem));
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

        sServiceContactFrom = oDeInstallOrder.Apttus_Config2__PrimaryContactId__r.Name;
        serviceContactFromId = oDeInstallOrder.Apttus_Config2__PrimaryContactId__c;
    }

    private Map<Id, Apttus_Config2__AssetLineItem__c> getAssetLineItemMap(Set<Id> assetIdSet) {

        Map<Id, Apttus_Config2__AssetLineItem__c> assetLineItemMap = new Map<Id, Apttus_Config2__AssetLineItem__c>([
                    SELECT Id, Name, Apttus_Config2__ProductId__r.Name,
                    Apttus_Config2__ProductId__c, Apttus_Config2__ProductId__r.APTS_LSP_Required__c, Apttus_Config2__BusinessLineItemId__c,
                    Apttus_Config2__Quantity__c, Apttus_Config2__SellingTerm__c, Apttus_Config2__StartDate__c,
                    Apttus_Config2__EndDate__c, Apttus_Config2__NetPrice__c, Apttus_Config2__AttributeValueId__r.APTS_Type_of_contract__c,
                    APTS_Physical_Asset__r.Id, APTS_Physical_Asset__r.SerialNumber__c, Apttus_Config2__PriceListId__c,
                    APTS_Physical_Asset__r.Building__c, APTS_Physical_Asset__r.Floor__c, APTS_Physical_Asset__r.Area__c,Apttus_Config2__IsPrimaryLine__c,
                    APTS_Order_LSP_Detail__c, APTS_Physical_Asset__c, Apttus_Config2__LocationId__r.Name, 
                    Apttus_Config2__LineNumber__c
                    FROM Apttus_Config2__AssetLineItem__c
                    WHERE Id = :assetIdSet AND APTS_Sub_Status__c <> :TEMPORARY_DEACTIVATED LIMIT 10000]);

        if (assetLineItemMap.isEmpty()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, PAGE_MSG_NO_MACHINE_FOUND));
        }

        return assetLineItemMap;
    }

    public void createMovementOrder() {

        if (validate()) {

            oDeInstallOrder.APTS_Requested_De_Installation_Date__c = dtDeInstallDate;
            oDeInstallOrder.APTS_SAP_OrderType__c = XB13;
            oDeInstallOrder.APTS_LSP_Required_Indicator__c = bLSPRequiredIndicator;
            oDeInstallOrder.APTS_Round_Trip_Indicator__c = bRoundTripIndicator;
            oDeInstallOrder.Apttus_Config2__PrimaryContactId__c = serviceContactFromId;
            oDeInstallOrder.APTS_ServiceContact__c = serviceContactToId;
            Database.update(oDeInstallOrder);

            bErrorOccurred = false;
        } else {
            bErrorOccurred = true;
        }
    }

    public Boolean validate() {

        Boolean bResult = true;

        bLSPRequiredIndicator = false;
        bRoundTripIndicator = false;

        assetIdDeInstallList.clear();

        for (AssetWrapper oAssetWrapper : assetWrapperDisplayList) {
            if (oAssetWrapper.selected) {
                assetIdDeInstallList.add(oAssetWrapper.oAssetLineItem.Id);
                selectedSerialNumberSet.add(oAssetWrapper.oAssetLineItem.APTS_Physical_Asset__r.SerialNumber__c);

                if (oAssetWrapper.oAssetLineItem.Apttus_Config2__ProductId__r.APTS_LSP_Required__c) {
                    bLSPRequiredIndicator = true;
                }
                if (oAssetWrapper.bRoundTripIndicator) {
                    bRoundTripIndicator = true;
                }
            }
        }

        if (assetIdDeInstallList.isEmpty()) {
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

    //Create deinstall cart
    public void createDeInstallCart() {

        try {
            if (!bErrorOccurred) {

                deInstallCartId = APTS_OrderUtils.createCart(oDeInstallOrder.Id);
            }
        } catch (Exception e) {
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id),'OM',false,true, EMAIL, true);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error in deinstall cart creation.'));
            bErrorOccurred = true;
        }
    }

    public void cancelAssets() {

        try {
            if (!bErrorOccurred) {
                deInstalledLineItemMap = APTS_OrderUtils.cancelAssets(deInstallCartId, assetIdDeInstallList);
            }
        } catch (Exception e) {
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id),'OM',false,true, EMAIL, true);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error in asset cancelation.'));
            bErrorOccurred = true;
        }
    }

    public void repriceDeInstallCart() {

        try {
            if (!bErrorOccurred) {

                APTS_OrderUtils.repriceCart(deInstallCartId);
            }
        } catch (Exception e) {
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id),'OM',false,true, EMAIL, true);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error while repricing the deinstall cart.'));
            bErrorOccurred = true;
        }
    }

    public void saveDeInstallCart() {

        try {
            if (!bErrorOccurred) {

                Apttus_Config2__ProductConfiguration__c oDeInstalledCart = APTS_OrderUtils.saveCart(deInstallCartId);
                Database.update(oDeInstalledCart);
            }
        } catch (Exception e) {
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id),'OM',false,true, EMAIL, true);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error while saving the deinstall cart.'));
            bErrorOccurred = true;
        }
    }

    public void finalizeDeInstallCart() {

        try {
            if (!bErrorOccurred) {

                APTS_OrderUtils.finalizeCart(deInstallCartId);
            }
        } catch (Exception e) {
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id),'OM',false,true, EMAIL, true);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error while finalizing deinstall order cart.'));
            bErrorOccurred = true;
        }
    }

    public void synchronizeDeInstallCart() {

        try {
            if (!bErrorOccurred) {
                APTS_OrderUtils.syncCart(deInstallCartId);
            }
        } catch (Exception e) {
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id),'OM',false,true, EMAIL, true);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error while sunchronizing deinstall order cart.'));
            bErrorOccurred = true;
        }
    }

    public void createInstallOrder() {

        bErrorOccurred = false;

        try {
            if (!bErrorOccurred) {

                oInstallOrder = new Apttus_Config2__Order__c();
                oInstallOrder = APTS_OrderUtils.setOrderHeaderMandatoryFields(oInstallOrder, MACHINE_ORDER);

                Map<Id, Contact> idToContactMap = APTS_OrderUtils.getAllContacts(installAccountId);
                oInstallOrder.Apttus_Config2__PrimaryContactId__c = APTS_OrderUtils.getPrimaryContactId(idToContactMap, MACHINE_ORDER);

                oInstallOrder.Apttus_Config2__Source__c = ACCOUNT;
                oInstallOrder.APTS_SAP_OrderType__c = 'XA14';

                List<Account> installAccountList = [
                                                       SELECT Id, Name, Apttus_Config2__BillingPreferenceId__c,
                                                       Apttus_Config2__PaymentTermId__c, Language__c,
                                                       Sales_Organization__c, Division__c, Distribution_Channel__c,
                                                       Bill_To_Payer_Account__c, Related_Payer_Account__c, Related_Payer_Machines_Services__c
                                                       FROM Account
                                                       WHERE Id = :installAccountId];

                Account oInstallAccount;
                if (!installAccountList.isEmpty()) {
                    oInstallAccount = installAccountList.get(0);
                }

                APTS_OrderUtils.setOrderHeader(oInstallOrder, oInstallAgreement, oInstallAccount);

                oInstallOrder.APTS_LSP_Required_Indicator__c = bLSPRequiredIndicator;
                oInstallOrder.APTS_Round_Trip_Indicator__c = bRoundTripIndicator;
                oInstallOrder.APTS_Require_Installation__c = true;
                oInstallOrder.APTS_Requested_Installation_Date__c = dtInstallDate;
                oInstallOrder.Apttus_Config2__PrimaryContactId__c = serviceContactFromId;
                oInstallOrder.APTS_ServiceContact__c = serviceContactToId;

                Database.insert(oInstallOrder);

                oDeInstallOrder.Apttus_Config2__ParentOrderId__c = oInstallOrder.Id;
                Database.update(oDeInstallOrder);
            }
        } catch (Exception e) {
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id),'OM',false,true, EMAIL, true);
            ApexPages.Message oErrorMessage = new ApexPages.Message(ApexPages.Severity.ERROR, 'Error in install order creation.');
            ApexPages.addMessage(oErrorMessage);
            bErrorOccurred = true;
        }
    }

    //Create install cart
    public void createInstallCart() {

        try {
            if (!bErrorOccurred) {

                installCartId = APTS_OrderUtils.createCart(oInstallOrder.Id);
            }
        } catch (Exception e) {
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id),'OM',false,true, EMAIL, true);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error in install cart creation.'));
            bErrorOccurred = true;
        }
    }

    public void addProductsToInstallCart() {

        Set<Id> lineItemIdSet = new Set<Id>();
        Map<Decimal, Id> bundelLineNumberToLineItemIdMap = new Map<Decimal, Id>();

        try {
            if (!bErrorOccurred) {

                for (Apttus__AgreementLineItem__c oAgreementLineItem : installAgreementLineItemMap.values()) {

                    lineItemIdSet.add(oAgreementLineItem.Apttus_CMConfig__DerivedFromId__c);

                    if (oAgreementLineItem.Apttus_CMConfig__IsPrimaryLine__c) {
                        if (selectedSerialNumberSet.contains(oAgreementLineItem.APTS_Serial_Number2__c)) {
                            bundelLineNumberToLineItemIdMap.put(oAgreementLineItem.Apttus_CMConfig__LineNumber__c, oAgreementLineItem.Apttus_CMConfig__DerivedFromId__c);
                        }
                    } else {

                        String sProductIdAndLNAndChargeType;

                        if (oAgreementLineItem.Apttus_CMConfig__HasOptions__c) {
                            sProductIdAndLNAndChargeType = oAgreementLineItem.Apttus__ProductId__c + String.valueOf(oAgreementLineItem.Apttus_CMConfig__LineNumber__c) + oAgreementLineItem.Apttus_CMConfig__ChargeType__c;
                        } else {
                            sProductIdAndLNAndChargeType = oAgreementLineItem.Apttus_CMConfig__OptionId__c + String.valueOf(oAgreementLineItem.Apttus_CMConfig__LineNumber__c) + oAgreementLineItem.Apttus_CMConfig__ChargeType__c;
                        }

                        productIdAndLineNumberAndChargeTypeToLIIdMap.put(sProductIdAndLNAndChargeType, oAgreementLineItem.Apttus_CMConfig__DerivedFromId__c);
                    }
                }

                idToLineItemMap = APTS_OrderUtils.getLineItemDataAll(lineItemIdSet);

                Map<Decimal, List<Apttus_CPQApi.CPQ.SelectedOptionDO>> bundelLineNumberToOptionListMap = APTS_OrderUtils.prepareOptionsListAll(idToLineItemMap);

                for (Decimal bundelLineNumber : bundelLineNumberToOptionListMap.keySet()) {

                    Id oBundleLineItemId = bundelLineNumberToLineItemIdMap.get(bundelLineNumber);
                    Apttus_Config2__LineItem__c oBundleLineItem = idToLineItemMap.get(oBundleLineItemId);
                    APTS_OrderUtils.addBundleWithOptionsAll(installCartId, oBundleLineItem, 1, bundelLineNumberToOptionListMap);
                }
            }
        } catch (Exception e) {
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id),'OM',false,true, EMAIL, true);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error in adding products to install cart.'));
            bErrorOccurred = true;
        }
    }

    public void updateProductAttributeValues() {

        try {
            if (!bErrorOccurred) {

                Map<Id, Apttus_Config2__LineItem__c> idToLineItemNewMap = new Map<Id, Apttus_Config2__LineItem__c>([
                            SELECT Id, Apttus_Config2__AttributeValueId__c, Apttus_Config2__DerivedFromId__c
                            FROM Apttus_Config2__LineItem__c
                            WHERE Apttus_Config2__ConfigurationId__c = :installCartId]);

                List<Apttus_Config2__ProductAttributeValue__c> pavToUpdateList = APTS_OrderUtils.updateProductAttributeValues(idToLineItemNewMap, idToLineItemMap);

                if (!pavToUpdateList.isEmpty()) {
                    Database.update(pavToUpdateList);
                }
            }
        } catch (Exception e) {
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id),'OM',false,true, EMAIL, true);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error while updating product attribute values.'));
            bErrorOccurred = true;
        }
    }

    public void repriceInstallCart() {

        try {
            if (!bErrorOccurred) {

                APTS_OrderUtils.repriceCart(installCartId);
            }
        } catch (Exception e) {
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id),'OM',false,true, EMAIL, true);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error while repricing the install cart.'));
            bErrorOccurred = true;
        }
    }

    public void fixNonPrimaryLines() {

        try {
            if (!bErrorOccurred) {
                List<Apttus_Config2__LineItem__c> lineItemToUpdateList = APTS_OrderUtils.fixNonPrimaryLines(installCartId, productIdAndLineNumberAndChargeTypeToLIIdMap);

                if (!lineItemToUpdateList.isEmpty()) {
                    Database.update(lineItemToUpdateList);
                }
            }
        } catch (Exception e) {
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id),'OM',false,true, EMAIL, true);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error in fixing non primary lines in install cart.'));
            bErrorOccurred = true;
        }
    }

    public void cloneLSPDetails() {

        try {
            if (!bErrorOccurred) {

                Map<Id, Apttus_Config2__LineItem__c> installLineItemMap = new Map<Id, Apttus_Config2__LineItem__c>([
                            SELECT Id, APTS_Serial_Number2__c, APTS_Order_LSP_Detail__c
                            FROM Apttus_Config2__LineItem__c
                            WHERE Apttus_Config2__ConfigurationId__c = :installCartId]);

                Map<String, APTS_Order_LSP_Details__c> serialNumberToLSPDetailsMap = new Map<String, APTS_Order_LSP_Details__c>();

                List<Apttus_Config2__LineItem__c> lineItemToUpdateList = new List<Apttus_Config2__LineItem__c>();

                for (AssetWrapper oAssetWrapper : assetWrapperDisplayList) {
                    if (oAssetWrapper.selected) {

                        APTS_Order_LSP_Details__c oLSPDetails = APTS_OrderUtils.cloneLSPDetails(oAssetWrapper.oAssetLineItem.APTS_Order_LSP_Detail__c);

                        oLSPDetails.APTS_Building__c = oAssetWrapper.sMovementToBuilding;
                        oLSPDetails.APTS_Floor__c = oAssetWrapper.sMovementToFloor;
                        oLSPDetails.APTS_Area__c = oAssetWrapper.sMovementToArea;
                        oLSPDetails.APTS_Requires_LSP__c = bLSPRequiredIndicator;
                        oLSPDetails.APTS_Require_Installation__c = oAssetWrapper.bInstallationRequired;

                        serialNumberToLSPDetailsMap.put(oAssetWrapper.oAssetLineItem.APTS_Physical_Asset__r.SerialNumber__c, oLSPDetails);
                    }
                }

                if (!serialNumberToLSPDetailsMap.isEmpty()) {
                    Database.insert(serialNumberToLSPDetailsMap.values());
                }

                System.debug('serialNumberToLSPDetailsMap : ' + serialNumberToLSPDetailsMap);

                for (Apttus_Config2__LineItem__c oLineItem : installLineItemMap.values()) {

                    APTS_Order_LSP_Details__c oLSPDetails = serialNumberToLSPDetailsMap.get(oLineItem.APTS_Serial_Number2__c);

                    if (oLSPDetails != null) {
                        oLineItem.APTS_Order_LSP_Detail__c = oLSPDetails.Id;
                        System.debug('oLineItem.APTS_Serial_Number2__c : ' + oLineItem.APTS_Serial_Number2__c);
                        System.debug('oLineItem.Id : ' + oLineItem.Id);
                        lineItemToUpdateList.add(oLineItem);
                    }
                }

                if (!lineItemToUpdateList.isEmpty()) {
                    Database.update(lineItemToUpdateList);
                }
            }
        } catch (Exception e) {
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id),'OM',false,true, EMAIL, true);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error while removing asset from install agreement line item.'));
            bErrorOccurred = true;
        }
    }

    public void saveInstallCart() {

        try {
            if (!bErrorOccurred) {

                Apttus_Config2__ProductConfiguration__c oInstalledCart = APTS_OrderUtils.saveCart(installCartId);
                Database.update(oInstalledCart);
            }
        } catch (Exception e) {
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id),'OM',false,true, EMAIL, true);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error while saving the install cart.'));
            bErrorOccurred = true;
        }
    }

    public void finalizeInstallCart() {

        try {
            if (!bErrorOccurred) {

                APTS_OrderUtils.finalizeCart(installCartId);
            }
        } catch (Exception e) {
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id),'OM',false,true, EMAIL, true);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error while finalizing install order cart.'));
            bErrorOccurred = true;
        }
    }

    public void synchronizeInstallCart() {

        try {
            if (!bErrorOccurred) {
                APTS_OrderUtils.syncCart(installCartId);
            }
        } catch (Exception e) {
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id),'OM',false,true, EMAIL, true);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error while sunchronizing install order cart.'));
            bErrorOccurred = true;
        }
    }

    public void createInstallPhysicalAsset() {

        try {
            if (!bErrorOccurred) {

                Id installOrderId = oInstallOrder.Id;

                installOrderLineItemMap = new Map<Id, Apttus_Config2__OrderLineItem__c>([
                            SELECT Id, APTS_Serial_Number2__c, APTS_Serial_Number__c
                            FROM Apttus_Config2__OrderLineItem__c
                            WHERE Apttus_Config2__OrderId__c = :installOrderId]);

                Set<Id> orderLineItemIdWithSerialNumberSet = new Set<Id>();

                for (Apttus_Config2__OrderLineItem__c oOrderLineItem : installOrderLineItemMap.values()) {
                    if (oOrderLineItem.APTS_Serial_Number2__c != null) {
                        orderLineItemIdWithSerialNumberSet.add(oOrderLineItem.Id);
                    }
                }

                Map<Id, Apttus_Config2__OrderLineItem__c> idToOrderLineItemWithPhysicalDataMap = APTS_OrderLineItemUtils.getOrderLineItemAdditionalData(orderLineItemIdWithSerialNumberSet);

                Map<Apttus_Config2__OrderLineItem__c, PhysicalAsset__c> orderLineItemToPhysicalAssetToCreateMap = new Map<Apttus_Config2__OrderLineItem__c, PhysicalAsset__c>();

                for (Apttus_Config2__OrderLineItem__c oOrderLineItem : idToOrderLineItemWithPhysicalDataMap.values()) {

                    oOrderLineItem.APTS_Serial_Number__c = oOrderLineItem.APTS_Serial_Number2__c;

                    PhysicalAsset__c oPhysicalAsset = APTS_OrderLineItemUtils.createPhysicalAsset(oOrderLineItem);

                    if (oPhysicalAsset != null) {
                        orderLineItemToPhysicalAssetToCreateMap.put(oOrderLineItem, oPhysicalAsset);
                    }
                }

                if (!orderLineItemToPhysicalAssetToCreateMap.isEmpty()) {

                    Database.insert(orderLineItemToPhysicalAssetToCreateMap.values());
                }

                List<Apttus_Config2__OrderLineItem__c> orderLineItemToUpdateList = new List<Apttus_Config2__OrderLineItem__c>();

                for (Apttus_Config2__OrderLineItem__c oOrderLineItemToUpdate : orderLineItemToPhysicalAssetToCreateMap.keySet()) {

                    PhysicalAsset__c oPhysicalAsset = orderLineItemToPhysicalAssetToCreateMap.get(oOrderLineItemToUpdate);
                    if (oPhysicalAsset != null) {
                        oOrderLineItemToUpdate.APTS_Physical_Asset__c = oPhysicalAsset.Id;
                        orderLineItemToUpdateList.add(oOrderLineItemToUpdate);
                    }
                }

                if (!orderLineItemToUpdateList.isEmpty()) {
                    APTS_OrderUtils.stopOrderLineItemTrigger();
                    Database.update(orderLineItemToUpdateList);
                    APTS_OrderUtils.startOrderLineItemTrigger();
                }
            }
        } catch (Exception e) {
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id),'OM',false,true, EMAIL, true);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error while creating new physical assets for install order line items.'));
            bErrorOccurred = true;
        }
    }

    public PageReference goToOrder() {

        PageReference pageRef;
        pageRef = new PageReference('/' + deInstallOrderId);

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

        if (oDeInstallOrder != null) {
            Database.delete(oDeInstallOrder);
        }

        if (deInstallCartId != null) {
            Apttus_Config2__ProductConfiguration__c oDeInstallCart = new Apttus_Config2__ProductConfiguration__c(Id = deInstallCartId);
            Database.delete(oDeInstallCart);
        }

        if (oInstallOrder != null) {
            Database.delete(oInstallOrder);
        }

        if (installCartId != null) {
            Apttus_Config2__ProductConfiguration__c oInstallCartId = new Apttus_Config2__ProductConfiguration__c(Id = installCartId);
            Database.delete(oInstallCartId);
        }

        return pageRef;
    }

    public PageReference backToAgreement() {

        PageReference pageRef;
        pageRef = new PageReference(CREATEMACHINEORDERURL + accountId);

        if (oDeInstallOrder != null) {
            Database.delete(oDeInstallOrder);
        }

        if (deInstallCartId != null) {
            Apttus_Config2__ProductConfiguration__c oDeInstallCart = new Apttus_Config2__ProductConfiguration__c(Id = deInstallCartId);
            Database.delete(oDeInstallCart);
        }

        if (oInstallOrder != null) {
            Database.delete(oInstallOrder);
        }

        if (installCartId != null) {
            Apttus_Config2__ProductConfiguration__c oInstallCartId = new Apttus_Config2__ProductConfiguration__c(Id = installCartId);
            Database.delete(oInstallCartId);
        }

        return pageRef;
    }

    public with sharing class AssetWrapper {

        public Integer iId {get; set;}
        public Boolean selected {get; set;}
        public Apttus_Config2__AssetLineItem__c oAssetLineItem {get; set;}
        public Apttus_Config2__AssetLineItem__c oPrimaryLIAssetLineItem {get; set;}
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

        public AssetWrapper(Integer iId, Boolean selected, Apttus_Config2__AssetLineItem__c oAssetLineItem, Apttus_Config2__AssetLineItem__c oPrimaryLIAssetLineItem) {

            this.iId = iId;
            this.selected = selected;
            this.oAssetLineItem = oAssetLineItem;
            this.oPrimaryLIAssetLineItem = oPrimaryLIAssetLineItem;
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