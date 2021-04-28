/*************************************************************
@Name: APTS_DeInstallOrderController
@Author: Galin Georgiev
@CreateDate: 02-05-2018
@Description: Create De-Install and Commercial Swap order from Account
@UsedBy: Create Order button on Account page
******************************************************************/
//v100 01-06-2018 Galin Georgiev: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes
//v101 11-1-2018 Akanksha: Updated requested de-installation date logic

/* APTS_DeInstallOrderController Class */
public  without sharing  class APTS_DeInstallOrderController {

    private static final String CARTPAGEURL = System.Label.APTS_Cart_Page_Url;
    private static final String PAGE_PARAM_ID = System.Label.APTS_Id;
    private static final String CREATEMACHINEORDERURL = '/apex/APTS_CreateMachineOrder?Id='; //System.Label.APTS_CreateMachineOrderUrl;
    private static final String PAGE_MSG_ORDER_ID_BLANK = 'OrderId can\'t be blank';
    private static final String PAGE_MSG_INVALID_ORDER_ID = 'Invalid OrderId. Please try again.';
    private static final String PAGE_MSG_SELECT_MIN_ONE_MACHINE = 'Please select at least one Machine';
    private static final String OPTION = System.Label.APTS_Option;
    private static final String EMAIL = System.Label.APTS_Email;
    private static final String XB13 = System.Label.APTS_XB13;
    private static final String TEMPORARY_DEACTIVATED = 'Temporary Deactivated';
    private static final String FIRSTPARAM = System.Label.APTS_firstParam;
    private static final String CANCELLED = 'Cancelled';
    private static final String COMMERCIALSWAP = 'Commercial Swap';
    private static final String MON = 'Mon';
    private static final String REQUESTEDDELIVERYDATEMONDAYMSG = 'Requested DeInstallation Date must be set to next Monday.';
    private static final String ERRORINCARTCREATION = 'Error in cart creation';
    private static final String ERRORINASSETCANCELATION = 'Error in asset cancelation';
    private static final String ERRORWHILESAVINGCARTMSG = 'Error while saving the cart';
    private static final String ERRORWHILEREDIRECTINGCART = 'Error while redirecting to cart';
    private static final String AGREEMENTVALIDASSETCANCELLED = 'Agreement do not have any valid asset to be cancelled!';
    private static final String NGMACHINESWAPORDER = 'NGMachineSwapOrder';
    private static final String NGMACHINEORDER = 'NGMachineOrder';
    private static final String COMMA = ',';
    private static final String E = 'E';
    private static final String URL1 = '/apex/Apttus_Config2__OrderConfiguration?id=';
    private static final String URL2 = '&flow=';
    private static final String URL3 = '&launchState=cart';



    private Map<Id, Id> mapAssetAgId = new Map<Id, Id>();
    private Set<String> availableSerialNumberSet = new Set<String>();
    private Set<String> availableSerialNumberInitialSet = new Set<String>();
    private Integer iInitialCountToDisplay;
    private Integer iCountToDisplay;

    public Id newOrderID = null;
    public Id newCartId = null;
    public Map<Id, Apttus_Config2__LineItem__c> deInstalledLineItemMap = null;
    public List<Id> assetIdDeInstallList = new List<Id>();

    public Apttus_Config2__Order__c oNewOrder {get; set;}
    public Apttus__APTS_Agreement__c oAgreement {get; set;}
    public List<APTS_AgreementLineItemWrapper> agreementLineItemWrapperList {get; set;}
    public List<APTS_AgreementLineItemWrapper> agreementLineItemWrapperDisplayList {get; set;}

    public Id agreementID {get; set;}
    public Date deInstallDate {get; set;}
    public Id accountId {get; set;}

    public Boolean bErrorOccurred {get; set;}
    public Boolean isAssetCancelled {get; set;}
    public Boolean bLSPRequiredIndicator = false;

    public String sSerialNumber {get; set;}
    public String sAllSerialNumbers {get; set;}

    public Boolean bDisableMore {get; set;}
    public Boolean bDisableLess {get; set;}
    
    /* APTS_DeInstallOrderController Controller */
    public APTS_DeInstallOrderController() {

        newOrderID = ApexPages.currentPage().getParameters().get(PAGE_PARAM_ID);
        bErrorOccurred = false;
        isAssetCancelled = false;
        bDisableMore = false;
        bDisableLess = true;
        sSerialNumber = null;
        agreementLineItemWrapperList = new List<APTS_AgreementLineItemWrapper>();
        agreementLineItemWrapperDisplayList = new List<APTS_AgreementLineItemWrapper>();

        List<Apttus_Config2__OrderSystemProperties__c> orderSystemPropertyList = Apttus_Config2__OrderSystemProperties__c.getall().values();
        iInitialCountToDisplay = Integer.valueOf(orderSystemPropertyList[0].APTS_Orders_to_display__c);

        try {
            if (String.isNotBlank(newOrderID)) {
                //v101 ++ <<
                deInstallDate = system.today().addDays(math.abs(math.mod(Date.newInstance(1900, 1, 8).daysBetween(system.today()),7)-7));
                //v101 ++ >>
                oNewOrder = getOrder(newOrderID);
                if (oNewOrder != null) {
                    agreementID = oNewOrder.Apttus_CMConfig__AgreementId__c;
                    accountID = oNewOrder.Apttus_Config2__BillToAccountId__c;
                    prepareAgreementList();
                } else {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, PAGE_MSG_INVALID_ORDER_ID));
                }
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, PAGE_MSG_ORDER_ID_BLANK));
            }
        } catch (Exception e) {  APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id), 'OM', false, true, EMAIL, true); }
    }

    /*De-Install selected Machine*/
    public void deInstallOrder() {
        try{
            if (validate()) {

                System.debug('oNewOrder.APTS_Order_Sub_Type__c : ' + oNewOrder.APTS_Order_Sub_Type__c);

                if (COMMERCIALSWAP.equalsIgnoreCase(oNewOrder.APTS_Order_Sub_Type__c)) {
                    //create new Order
                    Apttus_Config2__Order__c oParentInstallOrder = APTS_OrderUtils.cloneOrderHeader(oNewOrder);
                    oParentInstallOrder.APTS_SAP_OrderType__c = System.Label.APTS_XA13;
                    oParentInstallOrder.APTS_Requested_Installation_Date__c = deInstallDate;
                    oParentInstallOrder.APTS_Requested_De_Installation_Date__c = DateTime.newInstance(deInstallDate.year(), deInstallDate.month(), deInstallDate.day());
                    oParentInstallOrder.APTS_Requested_Delivery_Date__c = APTS_OrderUtils.checkRequestedDeliveryDateInWorkingHours(oParentInstallOrder, deInstallDate);
                    //14/9/2018, As part of new flow for TS, Deinstallation Order would be Parent and Installation would be child so removed below code
                    oParentInstallOrder.Apttus_Config2__ParentOrderId__c = oNewOrder.Id;

                    Database.SaveResult sres = Database.insert(oParentInstallOrder, FALSE);

                    //14/9/2018, As part of new flow for TS, Deinstallation Order would be Parent and Installation would be child so removed below code
                    //oNewOrder.Apttus_Config2__ParentOrderId__c = oParentInstallOrder.Id;
                }
                System.debug('-------------------');
                oNewOrder.APTS_Requested_De_Installation_Date__c = DateTime.newInstance(deInstallDate.year(), deInstallDate.month(), deInstallDate.day());
                System.debug('oNewOrder.APTS_Requested_De_Installation_Date__c : ' + oNewOrder.APTS_Requested_De_Installation_Date__c);
                oNewOrder.APTS_Requested_Delivery_Date__c = APTS_OrderUtils.checkRequestedDeliveryDateInWorkingHours(oNewOrder, deInstallDate);
                System.debug('oNewOrder.APTS_Requested_Delivery_Date__c : ' + oNewOrder.APTS_Requested_Delivery_Date__c);
                oNewOrder.APTS_LSP_Required_Indicator__c = bLSPRequiredIndicator;
                Database.update(oNewOrder);

                bErrorOccurred = false;
            } else {
                bErrorOccurred = true;
            }
        } catch(Exception ex){ system.debug('Exception is'+ex); }
    }
    /* validate Method Body */
    public Boolean validate() {

        Boolean bResult = true;
        bLSPRequiredIndicator = false;
        try{
            assetIdDeInstallList.clear();

            for (APTS_AgreementLineItemWrapper oAgreementLineItemWrapper : agreementLineItemWrapperList) {
                if (oAgreementLineItemWrapper.selected) {
                    assetIdDeInstallList.add(oAgreementLineItemWrapper.oBundleLineItem.Apttus_CMConfig__AssetLineItemId__c);
                    if (oAgreementLineItemWrapper.oBundleLineItem.Apttus_CMConfig__AssetLineItemId__r.Apttus_Config2__ProductId__r.APTS_LSP_Required__c) {
                        bLSPRequiredIndicator = true;
                    }
                }
            }

            if (assetIdDeInstallList.isEmpty()) {
                bResult = false;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, PAGE_MSG_SELECT_MIN_ONE_MACHINE));
            }

            DateTime dtInstallDate = DateTime.newInstance(deInstallDate.year(), deInstallDate.month(), deInstallDate.day());
            String dayOfWeek = dtInstallDate.format(E);

            if (!MON.equalsIgnoreCase(dayOfWeek)) {
                bResult = false;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, REQUESTEDDELIVERYDATEMONDAYMSG));
            }
        } catch(Exception ex){ system.debug('Exception is'+ex); }
        return bResult;
    }

    /* Create cart */
    public void createCart() {

        try {
            if (!bErrorOccurred) {
                newCartId = APTS_OrderUtils.createCart(newOrderID);
            }
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,ERRORINCARTCREATION));   bErrorOccurred = true; }
    }
    /*  cancelAssets Method */
    public void cancelAssets() {

        try {
            if (!bErrorOccurred) {
                deInstalledLineItemMap = APTS_OrderUtils.cancelAssets(newCartId, assetIdDeInstallList);

                List<Apttus_Config2__LineItem__c> lineToUpdate = new List<Apttus_Config2__LineItem__c>();
                if (deInstalledLineItemMap != null && !deInstalledLineItemMap.isEmpty()) {
                    for (Apttus_Config2__LineItem__c oLI : deInstalledLineItemMap.values()) {
                        Id agLIId = mapAssetAgId.containsKey(oLI.Apttus_Config2__AssetLineItemId__c) ? mapAssetAgId.get(oLI.Apttus_Config2__AssetLineItemId__c) : NULL;
                        if (agLIId != NULL) {
                            Apttus_Config2__LineItem__c oLIToUp = new Apttus_Config2__LineItem__c(Id = oLI.Id, APTS_Agreement_Line_Item__c = agLIId);
                            lineToUpdate.add(oLIToUp);
                        }
                    }

                    if (!lineToUpdate.isEmpty()) {
                        Database.update(lineToUpdate, FALSE);
                    }
                }
            }
        } catch (Exception e) {

            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ERRORINASSETCANCELATION));
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            bErrorOccurred = true;
        }
    }
    /* saveCart Method body */
    public void saveCart() {

        try {
            if (!bErrorOccurred) {
                Apttus_Config2__ProductConfiguration__c oDeInstalledCart = APTS_OrderUtils.saveCart(newCartId);
                Database.update(oDeInstalledCart);
            }
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ERRORWHILESAVINGCARTMSG));  bErrorOccurred = true; }
    }
    /* goToPricing Method body */
    public PageReference goToPricing() {

        PageReference pageRef = null;

        try {
            if (!bErrorOccurred) {
                String sFlow = NGMACHINEORDER;
                if (COMMERCIALSWAP.equalsIgnoreCase(oNewOrder.APTS_Order_Sub_Type__c)) {
                    sFlow = NGMACHINESWAPORDER;
                }
                pageRef = new PageReference(URL1 + oNewOrder.Id + URL2 + sFlow + URL3);
            }
        } catch (Exception e) {  ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ERRORWHILEREDIRECTINGCART));  }

        return pageRef;
    }
    /* backToAgreement Method body */
    public PageReference backToAgreement() {

        PageReference pageRef;
        try{
            pageRef = new PageReference(CREATEMACHINEORDERURL + accountId);

            if (oNewOrder != null) {
                Database.delete(oNewOrder);
            }

            if (newCartId != null) {
                Apttus_Config2__ProductConfiguration__c oNewCart = new Apttus_Config2__ProductConfiguration__c(Id = newCartId);
                Database.delete(oNewCart);
            }
        }
        catch(Exception ex){ system.debug('Exception is'+ex); }
        return pageRef;
    }

    /*Gets Order Data*/
    private Apttus_Config2__Order__c getOrder(Id newOrderID) {

        Apttus_Config2__Order__c oOrder;
        try{
            List<Apttus_Config2__Order__c> orderList = [SELECT id, Name, Apttus_Config2__PriceListId__c, Apttus_Config2__BillToAccountId__c,
                                           Apttus_CMConfig__AgreementId__c, Apttus_Config2__PaymentTermId__c, Apttus_Config2__PrimaryContactId__c,
                                           Apttus_Config2__SoldToAccountId__c, Apttus_Config2__ShipToAccountId__c, APTS_Payer__c, APTS_SAP_OrderType__c,
                                           APTS_Delivery_Block__c, APTS_Order_Type__c, APTS_Order_Sub_Type__c, APTS_Requested_Delivery_Date__c,
                                           APTS_Requested_Installation_Date__c, Apttus_Config2__LocationId__c, APTS_Sales_Organization__c, APTS_Distribution_Channel__c,
                                           APTS_Division__c, APTS_Way_Of_Ordering__c, APTS_Way_Of_Delivery__c, Apttus_Config2__PONumber__c, Apttus_Config2__PODate__c,
                                           APTS_Payment_Method__c, APTS_Payment_Method_Code__c, Apttus_Config2__BillingPreferenceId__c, APTS_Collective_Billing_Indicator__c,
                                           APTS_InvoiceType__c, APTS_InvoiceDeliveryPreference__c, APTS_Language_Preference__c
                                           FROM Apttus_Config2__Order__c WHERE Id = :newOrderID LIMIT 1];

            if (!orderList.isEmpty()) {
                oOrder = orderList.get(0);
            }
        } catch(Exception ex){ system.debug('Exception is'+ex); }
        return oOrder;
    }
    /* prepareAgreementList Method Body */
    public void prepareAgreementList() {
        try{
            Map<Id, Apttus__APTS_Agreement__c> idToAgreementMap = new Map<Id, Apttus__APTS_Agreement__c>([
                        SELECT Id, Name, RecordTypeId, Apttus__FF_Agreement_Number__c,
                        Apttus__Contract_Start_Date__c
                        FROM Apttus__APTS_Agreement__c
                        WHERE Id = :agreementId LIMIT 1]);

            oAgreement = idToAgreementMap.get(agreementId);

            Map<Id, Apttus__AgreementLineItem__c> idToAgreementLineItemMap = new Map<Id, Apttus__AgreementLineItem__c>([
                        SELECT Id, Apttus__AgreementId__c, Apttus__ProductId__r.Name, Apttus_CMConfig__LineStatus__c,
                        Apttus_CMConfig__AssetLineItemId__r.Apttus_Config2__Quantity__c, Apttus__Quantity__c, Apttus__NetPrice__c,
                        Apttus_CMConfig__HasOptions__c, Apttus_CMConfig__IsPrimaryLine__c, Apttus_CMConfig__LineType__c,
                        Apttus_CMConfig__LineNumber__c, Apttus_CMConfig__OptionId__r.Name, Apttus_CMConfig__DerivedFromId__c, Apttus_CMConfig__AssetLineItemId__c,
                        Apttus_CMConfig__AssetLineItemId__r.APTS_Physical_Asset__r.SerialNumber__c, Apttus_CMConfig__AssetLineItemId__r.Apttus_Config2__ProductId__r.APTS_LSP_Required__c
                        FROM Apttus__AgreementLineItem__c
                        WHERE Apttus__AgreementId__c IN :idToAgreementMap.keySet() AND Apttus_CMConfig__LineStatus__c = : CANCELLED
                                AND Apttus_CMConfig__AssetLineItemId__r.APTS_Sub_Status__c <> :TEMPORARY_DEACTIVATED AND Apttus_CMConfig__AssetLineItemId__r.Apttus_Config2__AssetStatus__c != : CANCELLED limit 1000]);

            Map<Id, Apttus__AgreementLineItem__c> primaryAgreementLineItemMap = new Map<Id, Apttus__AgreementLineItem__c>();
            Map<Decimal, Apttus__AgreementLineItem__c> lineNumberToPrimaryL1LineMap = new Map<Decimal, Apttus__AgreementLineItem__c>();
            Map<Decimal, List<Apttus__AgreementLineItem__c>> lineNumberToOptionListMap = new Map<Decimal, List<Apttus__AgreementLineItem__c>>();
            List<Apttus__AgreementLineItem__c> optionList = new List<Apttus__AgreementLineItem__c>();

            if (idToAgreementLineItemMap.size() > 0) {

                for (Apttus__AgreementLineItem__c oAgreementLineItem : idToAgreementLineItemMap.values()) {

                    mapAssetAgId.put(oAgreementLineItem.Apttus_CMConfig__AssetLineItemId__c, oAgreementLineItem.Id);

                    if (oAgreementLineItem.Apttus_CMConfig__HasOptions__c && oAgreementLineItem.Apttus_CMConfig__IsPrimaryLine__c) {
                        primaryAgreementLineItemMap.put(oAgreementLineItem.Id, oAgreementLineItem);
                    }

                    if (oAgreementLineItem.Apttus_CMConfig__HasOptions__c && !oAgreementLineItem.Apttus_CMConfig__IsPrimaryLine__c && oAgreementLineItem.Apttus_CMConfig__AssetLineItemId__r.APTS_Physical_Asset__c != null) {
                        lineNumberToPrimaryL1LineMap.put(oAgreementLineItem.Apttus_CMConfig__LineNumber__c, oAgreementLineItem);
                    }

                    if (oAgreementLineItem.Apttus_CMConfig__LineType__c == OPTION) {

                        if (lineNumberToOptionListMap.containsKey(oAgreementLineItem.Apttus_CMConfig__LineNumber__c)) {
                            optionList = lineNumberToOptionListMap.get(oAgreementLineItem.Apttus_CMConfig__LineNumber__c);
                        } else {
                            optionList = new List<Apttus__AgreementLineItem__c>();
                        }

                        optionList.add(oAgreementLineItem);
                        lineNumberToOptionListMap.put(oAgreementLineItem.Apttus_CMConfig__LineNumber__c, optionList);
                    }
                }

                for (Apttus__AgreementLineItem__c oPrimaryAgreementLineItem : primaryAgreementLineItemMap.values()) {

                    Apttus__AgreementLineItem__c oPrimaryL1BundleLineItem = lineNumberToPrimaryL1LineMap.get(oPrimaryAgreementLineItem.Apttus_CMConfig__LineNumber__c);
                    if (oPrimaryL1BundleLineItem == null) {
                        oPrimaryL1BundleLineItem = oPrimaryAgreementLineItem;
                    }

                    List<Apttus__AgreementLineItem__c> optionLineItemList = lineNumberToOptionListMap.get(oPrimaryAgreementLineItem.Apttus_CMConfig__LineNumber__c);

                    APTS_AgreementLineItemWrapper oAgreementLineItemWrapper = new APTS_AgreementLineItemWrapper(false, oPrimaryAgreementLineItem, oPrimaryL1BundleLineItem, optionLineItemList);
                    agreementLineItemWrapperList.add(oAgreementLineItemWrapper);

                    availableSerialNumberSet.add(oPrimaryL1BundleLineItem.Apttus_CMConfig__AssetLineItemId__r.APTS_Physical_Asset__r.SerialNumber__c);
                }

                availableSerialNumberInitialSet.addAll(availableSerialNumberSet);

                if (iInitialCountToDisplay >= agreementLineItemWrapperList.size()) {
                    iCountToDisplay = agreementLineItemWrapperList.size();
                    bDisableMore = true;
                } else {
                    iCountToDisplay = iInitialCountToDisplay;
                }

                for (Integer iIndex = 0; iIndex < iCountToDisplay; iIndex++) {
                    APTS_AgreementLineItemWrapper oAgreementLineItemWrapper = agreementLineItemWrapperList.get(iIndex);
                    agreementLineItemWrapperDisplayList.add(oAgreementLineItemWrapper);
                }
            } else {
                isAssetCancelled = true;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, AGREEMENTVALIDASSETCANCELLED));
            }
        } catch(Exception ex){ system.debug('Exception is'+ex); }
    }
    /* resetAssetSearch Method Body */
    public void resetAssetSearch() {

        sSerialNumber = null;
        try{
            availableSerialNumberSet.clear();
            availableSerialNumberSet.addAll(availableSerialNumberInitialSet);

            iCountToDisplay = iInitialCountToDisplay;
            Integer iMinCount = iInitialCountToDisplay <= agreementLineItemWrapperList.size() ? iInitialCountToDisplay : agreementLineItemWrapperList.size();
            agreementLineItemWrapperDisplayList.clear();
            bDisableLess = true;

            for (Integer iIndex = 0; iIndex < iMinCount; iIndex++) {
                APTS_AgreementLineItemWrapper oAgreementLineItemWrapper = agreementLineItemWrapperList.get(iIndex);
                oAgreementLineItemWrapper.selected = false;
                agreementLineItemWrapperDisplayList.add(oAgreementLineItemWrapper);
            }

            if (iCountToDisplay < agreementLineItemWrapperList.size()) {
                bDisableMore = false;
            } else {
                bDisableMore = true;
            }
        }  catch(Exception ex){ system.debug('Exception is'+ex); }
    }
    /* searchSerialNumbers Method Body */
    public void searchSerialNumbers() {

        sAllSerialNumbers = '[';

        String searchStr = ApexPages.currentPage().getParameters().get(FIRSTPARAM);

        Set<String> filteredSerialNumberSet = new Set<String>();
        try{
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
                        sAllSerialNumbers += COMMA;
                    }
                    iId++;
                }
            }

            sAllSerialNumbers += ']';
        } catch(Exception ex){ system.debug('Exception is'+ex); }
    }
    /* doAssetSearch Method Body */
    public void doAssetSearch() {

        Set<Integer> indexToRemoveSet = new Set<Integer>();
        Integer index = 0;
        try{
            availableSerialNumberSet.clear();
            availableSerialNumberSet.addAll(availableSerialNumberInitialSet);
            for (APTS_AgreementLineItemWrapper oAgreementLineItemWrapper : agreementLineItemWrapperList) {

                if (!String.isBlank(sSerialNumber)) {
                    if (oAgreementLineItemWrapper.oPrimaryL1BundleLineItem.Apttus_CMConfig__AssetLineItemId__r.APTS_Physical_Asset__r.SerialNumber__c != sSerialNumber) {
                        indexToRemoveSet.add(index);
                    }
                }

                index++;
            }

            for (Integer i : indexToRemoveSet) {
                APTS_AgreementLineItemWrapper oAgreementLineItemWrapper = agreementLineItemWrapperList.get(i);
                availableSerialNumberSet.remove(oAgreementLineItemWrapper.oPrimaryL1BundleLineItem.Apttus_CMConfig__AssetLineItemId__r.APTS_Physical_Asset__r.SerialNumber__c);
            }

            List<APTS_AgreementLineItemWrapper> agreementLineItemWrapperTmpList = new List<APTS_AgreementLineItemWrapper>();
            agreementLineItemWrapperTmpList.addAll(agreementLineItemWrapperList);

            for (Integer i = agreementLineItemWrapperTmpList.size(); i >= 0; i--) {
                if (indexToRemoveSet.contains(i)) {
                    agreementLineItemWrapperTmpList.remove(i);
                }
            }

            agreementLineItemWrapperDisplayList.clear();

            if (iInitialCountToDisplay >= agreementLineItemWrapperTmpList.size()) {
                iCountToDisplay = agreementLineItemWrapperTmpList.size();
                bDisableMore = true;
            } else {
                iCountToDisplay = iInitialCountToDisplay;
            }

            for (Integer iIndex = 0; iIndex < iCountToDisplay; iIndex++) {
                APTS_AgreementLineItemWrapper oAgreementLineItemWrapper = agreementLineItemWrapperTmpList.get(iIndex);
                agreementLineItemWrapperDisplayList.add(oAgreementLineItemWrapper);
            }
        } catch(Exception ex){ system.debug('Exception is'+ex); }
    }
    /* loadMore Method Body */
    public void loadMore() {

        bDisableLess = false;
        try{
            iCountToDisplay = iCountToDisplay + iInitialCountToDisplay;
            Integer iMaxCount = iCountToDisplay;

            if (iCountToDisplay >= agreementLineItemWrapperList.size()) {
                iMaxCount = agreementLineItemWrapperList.size();
                bDisableMore = true;
            }

            agreementLineItemWrapperDisplayList.clear();

            for (Integer iIndex = 0; iIndex < iMaxCount; iIndex++) {
                APTS_AgreementLineItemWrapper oAgreementLineItemWrapper = agreementLineItemWrapperList.get(iIndex);
                agreementLineItemWrapperDisplayList.add(oAgreementLineItemWrapper);
            }
        } catch(Exception ex){ system.debug('Exception is'+ex); }
    }
    /* loadLess Method Body */
    public void loadLess() {

        bDisableMore = false;
        try{
            if ((iCountToDisplay - iInitialCountToDisplay) <= iInitialCountToDisplay) {
                iCountToDisplay = iInitialCountToDisplay;
                bDisableLess = true;
            } else {
                iCountToDisplay = iCountToDisplay - iInitialCountToDisplay;
            }

            agreementLineItemWrapperDisplayList.clear();

            for (Integer iIndex = 0; iIndex < iCountToDisplay; iIndex++) {
                APTS_AgreementLineItemWrapper oAgreementLineItemWrapper = agreementLineItemWrapperList.get(iIndex);
                agreementLineItemWrapperDisplayList.add(oAgreementLineItemWrapper);
            }
        } catch(Exception ex){ system.debug('Exception is'+ex); }
    }
    /* Wrapper Class APTS_AgreementLineItemWrapper */
    public with sharing class APTS_AgreementLineItemWrapper {

        public Boolean selected {get; set;}
        public Apttus__AgreementLineItem__c oBundleLineItem {get; set;}
        public Apttus__AgreementLineItem__c oPrimaryL1BundleLineItem {get; set;}
        public List<Apttus__AgreementLineItem__c> optionLineItemList {get; set;}
        /* Constructor APTS_AgreementLineItemWrapper */
        public APTS_AgreementLineItemWrapper() {

            this.selected = false;
            this.oBundleLineItem = null;
            this.oPrimaryL1BundleLineItem = null;
            this.optionLineItemList = null;
        }
        /* Constructor APTS_AgreementLineItemWrapper with parameters*/
        public APTS_AgreementLineItemWrapper(Boolean selected, Apttus__AgreementLineItem__c oBundleLineItem, Apttus__AgreementLineItem__c oPrimaryL1BundleLineItem, List<Apttus__AgreementLineItem__c> optionLineItemList) {

            this.selected = selected;
            this.oBundleLineItem = oBundleLineItem;
            this.oPrimaryL1BundleLineItem = oPrimaryL1BundleLineItem;
            this.optionLineItemList = optionLineItemList;
        }
    }
}