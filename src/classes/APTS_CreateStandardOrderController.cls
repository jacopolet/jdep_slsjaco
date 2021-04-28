/*************************************************************
@Name: APTS_CreateStandardOrderController
@Author: Galin Georgiev
@CreateDate: 02-01-2018
@Description: Create Standard Order from Account
@UsedBy: Create Standard Order button on Account page
******************************************************************/
//v100 02-01-2018 Galin Georgiev: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes
//V101 06.11.2018 Aarthi Pitchai : Added logic to allow standard order creation without an agreement as part of Defect Fix #21143
//V102 16.01.2019 Venky Muppalaneni: FD 2168 : added the columns in select list of agreement
//V103 24.01.2019 Sanjay Nair: Defect 23849 : Changed the query for Accout Hierarchy Lookup
//V104 14.03.2019 Nikita Modi : Def#5946 Added the logic for return of digital order
//V105 09.04.2019 Nikita Modi : Def#6582 Added the logic: By creating a return there's an error that asks to select an agreement
//V106 10.04.2019 Neev Shah : Defect#5930 -- order creation for Being Renewed Agreement, removed Expired Status
//V107 13.05.2019 Rajesh Patel : UserStory#40 - Based on planned and unplanned return set LSP indicator and SAP order type
//V108 16-05-2019  Sethu: DOQOM-37 Populate picking list text on the order from Account location
//v109 28-05-2019 Akanksha: DOK31-246 Adding where condition in the agreement query to filter out Registration form
//V110 13.08.2019 Nikita Modi : QTCFLEX1-700 ; LSP Required checkbox for unplanned return order should be defaulted to false
//v111 30-08-2019 Renuka: DFT2C-1360 Added APTS_Check_on_Account_Machines__c in the loadAgreement().
//v112 13-09-2019 Akanksha: QTCFLEX1-1262 Initialized lSPIndicator on controller load.
//v113 14-Oct-2019 Aarthi: QTCFLEX1-1451 Remove the logic to set customer comments and picking list text
//v114 09-Dec-2019 Aarthi: QTCFLEX1-1760 BPO consideration for planned return orders
//v115 25-Feb-2020 Aarthi: DQ-1674 Apttus Upgrade Issue - Planned Return issue on Update quantity
//v116 03-Mar-2020 Aarthi: DQ-1709 Apttus Upgrade Issue - Planned return - Do additional reprice before finalize to apply the adjustments
//V117 30-Jun-2020 Aarthi: DQ-3055 Apttus Upgrade - Patch 6 Issue - Planned return - Partial return usecase fix
//v118 9-Sept-2020 Sneha Jaiwant: DQ2456 Agreements with the end date in future

public without sharing class APTS_CreateStandardOrderController {

    private Id accountId;
    private Id locId;
    private Account initialAccount;
    private Map<Id, Account> idToAccountMap;
    private Map<Id, Apttus__APTS_Agreement__c> idToAgreementMap;
    //v103 << ++
    private Set<Id> accountSet ;
    //v103 -->>
    private Boolean bOrdersLoaded;
    private Id cartId;
    private Apttus_Config2__Order__c oReturnOrder;
    private List<OrderWrapper> orderWrapperTmpList;
    private Set<String> availableProductSet;
    private Set<String> availableOrderNumberSet;
    private Set<String> availableOrderNumberInitialSet;
    private Map<Id, Decimal> assetIdForChangeToQuantityMap;
    private List<Id> assetIdForCancelList;
    private Map<Id, Apttus_Config2__LineItem__c> deInstalledLineItemMap;
    private Map<Id, Decimal> changeAssetsOriginalQtyMap; //v115 ++ <<>>
    private Integer iInitialCountToDisplay;
    private Integer iCountToDisplay;
    private Set<String> setAgStatus = APTS_OrderConstants.STANDARD_ORDER_AG_STATUS;


    public Apttus_Config2__Order__c oOrder {get; set;}
    public List<AgreementWrapper> agreementWrapperList {get; set;}

    public List<OrderWrapper> orderWrapperList {get; set;}
    public List<OrderWrapper> orderWrapperDisplayList {get; set;}

    public Boolean bErrorOccurred {get; set;}

    public Boolean bShowAgreements {get; set;}
    public Boolean bShowOrders {get; set;}

    public String sProductName {get; set;}
    public String sOrderNumber {get; set;}
    public String dtOrderStartDate {get; set;}

    public String sAllProducts {get; set;}
    public String sAllOrderNumbers {get; set;}

    public Boolean bDisableMore {get; set;}
    public Boolean bDisableLess {get; set;}

    public Boolean bShowCreate {get; set;}
    public Boolean bReturnOrder {get; set;}
    //v107++<<
    public Boolean bShowLSP {get; set;} //V107 ++>>

    public Boolean bFirstClickOnAgreement {get; set;}
    //v107++<<
    public Boolean lSPIndicator {get; set;} //v107++>>
    
    public Boolean bRepricePending {get; set;} //V116++<<>>
    
    public APTS_CreateStandardOrderController() {

        accountId = ApexPages.currentPage().getParameters().get(APTS_OrderConstants.ID);
        locId = ApexPages.currentPage().getParameters().get(APTS_OrderConstants.LOCID);

        bShowAgreements = true;
        //v107++<<
        bShowLSP = false; //v107++>>
        bFirstClickOnAgreement = true;
        bOrdersLoaded = false;
        bShowOrders = false;
        sProductName = null;
        sOrderNumber = null;
        bDisableMore = false;
        bDisableLess = true;
        bShowCreate = true;
        bReturnOrder = false;
        //v112 << ++
        lSPIndicator = false;
        //v112 ++ >>

        agreementWrapperList = new List<AgreementWrapper>();
        idToAccountMap = new Map<Id, Account>();
        //v103 << ++
        accountSet = new Set<Id> ();
        //v103 -->> << ++
        oOrder = new Apttus_Config2__Order__c();
        oOrder.APTS_Order_Type__c = APTS_OrderConstants.STANDARD_ORDER;

        oOrder.Apttus_Config2__Source__c = APTS_OrderConstants.ACCOUNT;
        oOrder = APTS_OrderUtils.setOrderHeaderMandatoryFields(oOrder, APTS_OrderConstants.STANDARD);

        Map<Id, Contact> idToContactMap = APTS_OrderUtils.getAllContacts(accountId);
        oOrder.Apttus_Config2__PrimaryContactId__c = APTS_OrderUtils.getPrimaryContactId(idToContactMap, APTS_OrderConstants.STANDARD);
    }

    public void doSOQLS() {
// v103 - Changes in the seciton , Query the Parent id, Parents Parent ID, (Grand Parent). The Account Levels are checked in the loop for agreement
        Map<Id, Account> initialAccountMap = new  Map<Id, Account>([
                    SELECT Id,
                    APTS_Ultimate_Parent_Id__c,
                    APTS_Account_Level__c,
                    SAP_Customer_ID__c,
                    Apttus_Config2__BillingPreferenceId__c,
                    Apttus_Config2__PaymentTermId__c,
                    Language__c,
                    Sales_Organization__c,
                    Division__c,
                    Distribution_Channel__c,
                    Bill_To_Payer_Account__c,
                    Related_Payer_Account__c,
                    APTS_Price_List__c,
                    Partner__c,
                    Billing_header_text__c,
                    ParentId,
                    Parent.Parent.Id
                    FROM Account
                    WHERE Id = :accountId LIMIT 1]);

        initialAccount = initialAccountMap.get(accountId);

        if (initialAccount != null && initialAccount.Id != initialAccount.APTS_Ultimate_Parent_Id__c) {
            // Map<Id, Account> idToAccountMapTmp = new Map<Id, Account>([SELECT Id, APTS_Account_Level__c FROM Account WHERE APTS_Ultimate_Parent_Id__c = :initialAccount.APTS_Ultimate_Parent_Id__c]);
            // idToAccountMap = filterAccounts(initialAccount, idToAccountMapTmp);
            accountSet.add(initialAccount.Id);
            if (initialAccount.ParentId != null) {accountSet.add(initialAccount.ParentId);}
            if (initialAccount.Parent.Parent.Id != null) {accountSet.add(initialAccount.Parent.Parent.Id);}

        } else {
            //idToAccountMap = initialAccountMap;
            accountSet.add(initialAccount.Id);
        }
    }

    public void loadAgreements() {

        if (bFirstClickOnAgreement) {


            Map<Id, Apttus__APTS_Agreement__c> idToAgreementMap = new Map<Id, Apttus__APTS_Agreement__c>([
                        SELECT Id,
                        Name,
                        Apttus__Status_Category__c,
                        Apttus__Status__c,
                        RecordTypeId,
                        Apttus__Contract_Start_Date__c,
                        Apttus__Contract_End_Date__c,
                        Apttus__Account__r.APTS_Account_Level__c,
                        Apttus_CMConfig__PriceListId__c,
                        Apttus_CMConfig__BillingPreferenceId__c,
                        Apttus_CMConfig__PONumber__c,
                        Apttus_CMConfig__PaymentTermId__c,
                        APTS_Language__c,
                        APTS_Bill_to_Party_Ingredients__c,
                        APTS_Payer_Ingredients__c,
                        APTS_Bill_to_Party_MachServ__c,
                        APTS_Payer_Machines_Services__c,
                        APTS_Location__c,
                        //V102++>>
                        APTS_Check_on_Account_Ingredients__c,APTS_Check_on_Account_Machines__c,
                        Apttus__Account__c,
                        //V102++<<
                        APTS_Location__r.Billing_header_text__c,
                        APTS_Location__r.Delivery_text__c,
                        //V108++<<
                        APTS_Location__r.Picking_list_text__c
                        //V108++>>
                        FROM Apttus__APTS_Agreement__c
                        //V106 ++ <<
                        WHERE Apttus__Account__c IN :accountSet AND Apttus__Status_Category__c = :APTS_OrderConstants.IN_EFFECT
                                AND Apttus__Status__c IN :setAgStatus AND //v109
                                RecordType.Name != :APTS_OrderConstants.REGISTRATION_FORM ]);
            //V106 ++ >>

            Map<String, Apttus__APTS_Agreement__c> sortCriteriaToAgreementMap = new Map<String, Apttus__APTS_Agreement__c>();
            Integer iCountStandardDeal = 0;
            Integer iCountConsumptionsModel = 0;



            for (Apttus__APTS_Agreement__c oAgreement : idToAgreementMap.values()) {
                if(oAgreement.Apttus__Contract_End_Date__c >= system.today() ){
                String sSortCriteria;
                String sAccountLevel = oAgreement.Apttus__Account__r.APTS_Account_Level__c.substring(0, 1);
                String sInitialAccountLevel = initialAccount.APTS_Account_Level__c.substring(0, 1);
                if (sAccountLevel <= sInitialAccountLevel) {
                    String sRecordType = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosById().get(oAgreement.RecordTypeId).getname();

                    if (sRecordType == APTS_OrderConstants.STANDARD_DEAL) {
                        sSortCriteria = APTS_OrderConstants.AA + sAccountLevel + iCountStandardDeal;
                        iCountStandardDeal++;
                    } else {
                        sSortCriteria = APTS_OrderConstants.BB + sAccountLevel + iCountConsumptionsModel;
                        iCountConsumptionsModel++;
                    }
                    sortCriteriaToAgreementMap.put(sSortCriteria, oAgreement);
                }
                }
            }
            //v118
            if((sortCriteriaToAgreementMap.isEmpty() && sortCriteriaToAgreementMap.size() ==0) &&(!idToAgreementMap.isEmpty() && idToAgreementMap.size() >=1) ){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, '<font color="black">'+APTS_OrderConstants.Past_EndDate+'</font>'));
            }
            //v118
            List<String> sortCriteriaList = new List<String>(sortCriteriaToAgreementMap.keySet());
            sortCriteriaList.sort();
            if (iCountStandardDeal > 0) {
                String sSortCriteria = sortCriteriaList.get(iCountStandardDeal - 1);
                AgreementWrapper oAgreementWrapper = new AgreementWrapper(false, sortCriteriaToAgreementMap.get(sSortCriteria));
                agreementWrapperList.add(oAgreementWrapper);
            }

            if (iCountConsumptionsModel > 0) {
                String sSortCriteria = sortCriteriaList.get(iCountStandardDeal + iCountConsumptionsModel - 1);
                AgreementWrapper oAgreementWrapper = new AgreementWrapper(false, sortCriteriaToAgreementMap.get(sSortCriteria));
                agreementWrapperList.add(oAgreementWrapper);
            }

            if (agreementWrapperList.size() == 1) {
                agreementWrapperList[0].selected = true;
            }
        }

        bFirstClickOnAgreement = false;
        
    }

    public void loadOrders() {

        if (!bOrdersLoaded) {

            availableProductSet = new Set<String>();
            availableOrderNumberSet = new Set<String>();
            availableOrderNumberInitialSet = new Set<String>();
            assetIdForChangeToQuantityMap = new Map<Id, Decimal>();
            changeAssetsOriginalQtyMap = new Map<Id, Decimal>(); //v115 ++ <<>>
            assetIdForCancelList = new List<Id>();

            List<Apttus_Config2__OrderSystemProperties__c> orderSystemPropertyList = Apttus_Config2__OrderSystemProperties__c.getall().values();
            iInitialCountToDisplay = Integer.valueOf(orderSystemPropertyList[0].APTS_Orders_to_display__c);

            orderWrapperList = new List<OrderWrapper>();
            orderWrapperDisplayList = new List<OrderWrapper>();
            Date dtSixMonthsAgo = Date.today().addMonths(-6);

            Map<Id, Apttus_Config2__Order__c> idToOrderMap = new Map<Id, Apttus_Config2__Order__c>([
                        SELECT Id, Name, APTS_Name__c, Apttus_Config2__Status__c, RecordTypeId,
                        Apttus_Config2__OrderStartDate__c, Apttus_Config2__OrderEndDate__c,
                        Apttus_CMConfig__AgreementId__c, Apttus_Config2__BillingPreferenceId__c,
                        Apttus_Config2__BillToAccountId__c, Apttus_Config2__PriceListId__c, Apttus_Config2__ShipToAccountId__c,
                        Apttus_Config2__SoldToAccountId__c, Apttus_Config2__Source__c
                        FROM Apttus_Config2__Order__c
                        WHERE Apttus_Config2__SoldToAccountId__c = :accountId AND Apttus_Config2__Status__c = :APTS_OrderConstants.ACTIVATED
                                AND (APTS_Order_Sub_Type__c = :APTS_OrderConstants.STANDARD_ORDER OR APTS_Order_Sub_Type__c = : APTS_OrderConstants.ORDER_TYPE_DIGITAL) AND Apttus_Config2__OrderStartDate__c > :dtSixMonthsAgo]); //V104

            Map<Id, List<Apttus_Config2__OrderLineItem__c>> orderIdToOrderLineItemListMap = new Map<Id, List<Apttus_Config2__OrderLineItem__c>>();

            Map<Id, Apttus_Config2__OrderLineItem__c> idToOrderLineItemMap = new Map<Id, Apttus_Config2__OrderLineItem__c>([
                        SELECT Id, Apttus_Config2__OrderId__c, Apttus_Config2__ProductId__r.Name, Apttus_Config2__Quantity__c,
                        Apttus_Config2__FulfilledQuantity__c, Apttus_Config2__NetPrice__c, Apttus_Config2__AssetLineItemId__c,
                        Apttus_Config2__AssetLineItemId__r.Apttus_Config2__Quantity__c
                        FROM Apttus_Config2__OrderLineItem__c
                        WHERE Apttus_Config2__OrderId__c IN :idToOrderMap.keySet() AND Apttus_Config2__IsPrimaryLine__c = true AND Apttus_Config2__AssetLineItemId__r.Apttus_Config2__AssetStatus__c = :APTS_OrderConstants.ACTIVATED]);

            for (Apttus_Config2__OrderLineItem__c oOrderLineItem : idToOrderLineItemMap.values()) {
                List<Apttus_Config2__OrderLineItem__c> orderLineItemList = orderIdToOrderLineItemListMap.get(oOrderLineItem.Apttus_Config2__OrderId__c);
                if (orderLineItemList == null) {
                    orderLineItemList = new List<Apttus_Config2__OrderLineItem__c>();
                    orderIdToOrderLineItemListMap.put(oOrderLineItem.Apttus_Config2__OrderId__c, orderLineItemList);
                }
                orderLineItemList.add(oOrderLineItem);
                availableProductSet.add(oOrderLineItem.Apttus_Config2__ProductId__r.Name);
            }

            for (Id orderId : orderIdToOrderLineItemListMap.keySet()) {

                List<APTS_OrderLineItemWrapper> orderLineItemWrapperList = new List<APTS_OrderLineItemWrapper>();
                for (Apttus_Config2__OrderLineItem__c oOrderLineItem : orderIdToOrderLineItemListMap.get(orderId)) {
                    APTS_OrderLineItemWrapper oOrderLineItemWrapper = new APTS_OrderLineItemWrapper(false, oOrderLineItem, 0);
                    orderLineItemWrapperList.add(oOrderLineItemWrapper);
                }

                Apttus_Config2__Order__c oOrder = idToOrderMap.get(orderId);
                OrderWrapper oOrderWrapper = new OrderWrapper(false, oOrder, orderLineItemWrapperList);
                orderWrapperList.add(oOrderWrapper);
                availableOrderNumberSet.add(oOrder.Name);
            }

            orderWrapperList.sort();
            orderWrapperTmpList = new List<OrderWrapper>();
            orderWrapperTmpList.addAll(orderWrapperList);

            if (iInitialCountToDisplay >= orderWrapperList.size()) {
                iCountToDisplay = orderWrapperList.size();
                bDisableMore = true;
            } else {
                iCountToDisplay = iInitialCountToDisplay;
            }

            for (Integer iIndex = 0; iIndex < iCountToDisplay; iIndex++) {
                OrderWrapper oOrderWrapper = orderWrapperList.get(iIndex);
                orderWrapperDisplayList.add(oOrderWrapper);
            }

            availableOrderNumberInitialSet.addAll(availableOrderNumberSet);
        }

        bOrdersLoaded = true;
    }

    public Map<Id, Account> filterAccounts(Account initialAccount, Map<Id, Account> idToAccountMapTmp) {


        Map<Id, Account> idToAccountMapFilter = new Map<Id, Account>();

        String sInitialAccountLevel = initialAccount.APTS_Account_Level__c.substring(0, 1);
        String sAccountLevel;

        idToAccountMapFilter.put(initialAccount.Id, initialAccount);

        for (Account oAccount : idToAccountMapTmp.values()) {

            sAccountLevel = oAccount.APTS_Account_Level__c.substring(0, 1);
            if (sAccountLevel < sInitialAccountLevel) {
                idToAccountMapFilter.put(oAccount.Id, oAccount);
            }
        }

        return idToAccountMapFilter;
    }

    public List<SelectOption> getOrderSubTypePicklist() {

        List<SelectOption> options = new List<SelectOption>();

        options.add(new SelectOption(APTS_OrderConstants.STANDARD_ORDER, APTS_OrderConstants.STANDARD_ORDER));
        options.add(new SelectOption(APTS_OrderConstants.STANDARD_RETURN, APTS_OrderConstants.STANDARD_RETURN));
        options.add(new SelectOption(APTS_OrderConstants.UNPLANNED_RETURN, APTS_OrderConstants.UNPLANNED_RETURN));
        options.add(new SelectOption(APTS_OrderConstants.CONSIGNMENT_ISSUE, APTS_OrderConstants.CONSIGNMENT_ISSUE));
        options.add(new SelectOption(APTS_OrderConstants.CONSIGNMENT_FILLUP, APTS_OrderConstants.CONSIGNMENT_FILLUP));

        return options;
    }

    public void checkHidden() {

        ApexPages.getMessages().clear();

        if (oOrder.APTS_Order_Sub_Type__c == APTS_OrderConstants.STANDARD_RETURN) {

            lSPIndicator = true; //v110
            bShowAgreements = false;
            bShowOrders = true;
            bShowCreate = true;
            //V107<<++
            bShowLSP = true; //V107++>>
            bFirstClickOnAgreement = false;
            loadOrders();

            if (orderWrapperList.isEmpty() || Test.isRunningTest()) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, APTS_OrderConstants.NO_ORDER));
                bShowOrders = false;
                bShowCreate = false;
                //V107<<++
                bShowLSP = false; //V107++>>
            }
        } else {
            lSPIndicator = false;  //v110
            bShowAgreements = true;
            bShowOrders = false;
            bShowCreate = true;
            //V107<<++
            Boolean checkLsp = oOrder.APTS_Order_Sub_Type__c == APTS_OrderConstants.UNPLANNED_RETURN ? true : false;
            bShowLSP = checkLsp; //V107++>>
        }
        
       
    }
    
    public void createOrder() {
        if (assetIdForChangeToQuantityMap != null) {
            assetIdForChangeToQuantityMap.clear();
        }

        if (assetIdForCancelList != null) {
            assetIdForCancelList.clear();
        }


        if (validate()) {
            try {
                //Create standard order

                Apttus__APTS_Agreement__c oSelectedAgreement;

                for (AgreementWrapper oAgreementWrapper : agreementWrapperList) {
                    if (oAgreementWrapper.selected) {
                        oSelectedAgreement = oAgreementWrapper.oAgreement;
                    }
                }

                if (oSelectedAgreement != null) {
                    oOrder = APTS_OrderUtils.setOrderHeader(oOrder, oSelectedAgreement, initialAccount);
                } else {
                    oOrder = APTS_OrderUtils.setOrderHeader(oOrder, initialAccount);
                }

                //If Order from Account than get location from Account
                if (locId == null) {
                    locId = APTS_OrderUtils.getAccountLocationId(initialAccount);
                }               
                oOrder.Apttus_Config2__LocationId__c = locId;

                if (initialAccount.Billing_header_text__c != null && initialAccount.Billing_header_text__c.length() > 255) {
                    oOrder.APTS_Invoice_Remark__c = initialAccount.Billing_header_text__c.left(255);
                } else {
                    oOrder.APTS_Invoice_Remark__c = initialAccount.Billing_header_text__c;
                }

                if (oOrder.APTS_Order_Sub_Type__c == APTS_OrderConstants.STANDARD_RETURN) {

                    bReturnOrder = true;
                    //Return order section
                    Apttus_Config2__Order__c oSelectedOrder;
                    List<APTS_OrderLineItemWrapper> selectedOrderLineItemWrapperList = new List<APTS_OrderLineItemWrapper>();

                    Set<String> developerNameSet = APTS_OrderConstants.DEVELOPER_NAME_SET;

                    //Added for calculating Requested Delivery Date - Akanksha
                    List<CountrySetting__c> countrySettingList = [
                                SELECT Country__c, RoundTrip__c, DeliveryOffset__c, PickupOffset__c,
                                RecordType.DeveloperName, Business_Hours__c, AdditionalOffset__c, Additional_Offset_Time__c
                                FROM CountrySetting__c
                                WHERE Country__c = :oOrder.APTS_Sales_Organization__c AND RoundTrip__c = false AND RecordType.DeveloperName IN :developerNameSet AND Active__c = true];
                    for (OrderWrapper oOrderWrapper : orderWrapperList) {
                        for (APTS_OrderLineItemWrapper oOrderLineItemWrapper : oOrderWrapper.orderLineItemWrapperList) {
                            if (oOrderLineItemWrapper.selected) {
                                oSelectedOrder = oOrderWrapper.oOrder;
                                selectedOrderLineItemWrapperList.add(oOrderLineItemWrapper);
                            }
                        }
                    }

                    if (oSelectedOrder != null) {

                        oReturnOrder = APTS_OrderUtils.createReturnOrder(oSelectedOrder);
                        oReturnOrder.APTS_Requested_Delivery_Date__c = APTS_OrderUtils.checkRequestedDeliveryDateInWorkingHours(oReturnOrder, countrySettingList, system.today());
                        //V107<<++
                        oReturnOrder.APTS_LSP_Required_Indicator__c = lSPIndicator ;
                        String sReturnSAP = lSPIndicator ? APTS_OrderConstants.XB01 : APTS_OrderConstants.XB02;
                        oReturnOrder.APTS_SAP_OrderType__c = sReturnSAP; //V107++>>
                        Database.insert(oReturnOrder);
                    }
                } else {

                    if (oSelectedAgreement == null) {
                        APTS_DefaultPriceList oDefaultPriceList = new APTS_DefaultPriceList();
                        oOrder.Apttus_Config2__PriceListId__c = oDefaultPriceList.getDefaultPriceListId(initialAccount);
                    }

                    if (oOrder.APTS_Order_Sub_Type__c == APTS_OrderConstants.UNPLANNED_RETURN) { //V107<<++
                        oOrder.APTS_LSP_Required_Indicator__c = lSPIndicator ;
                        String sReturnSAP = lSPIndicator ? APTS_OrderConstants.XB01 : APTS_OrderConstants.XB02;
                        oOrder.APTS_SAP_OrderType__c = sReturnSAP; //V107++>>
                    } else if (oOrder.APTS_Order_Sub_Type__c == APTS_OrderConstants.CONSIGNMENT_ISSUE) {
                        oOrder.APTS_SAP_OrderType__c = APTS_OrderConstants.XA07;
                    } else if (oOrder.APTS_Order_Sub_Type__c == APTS_OrderConstants.CONSIGNMENT_FILLUP) {
                        oOrder.APTS_SAP_OrderType__c = APTS_OrderConstants.XA03;
                    }
                    oOrder.APTS_Requested_Delivery_Date__c = APTS_OrderUtils.checkRequestedDeliveryDateInWorkingHours(oOrder, system.today());
                    Database.insert(oOrder);
                }

                bErrorOccurred = false;
            } catch (Exception e) {
                raiseError(e, 'Error in creation of order!' + e.getStackTraceString());
            }
        } else {
            bErrorOccurred = true;
        }
    }

    //Create cart
    public void createCart() {

        try {
            if (!bErrorOccurred) {

                cartId = APTS_OrderUtils.createCart(oReturnOrder.Id);
            }
        } catch (Exception e) {
            raiseError(e, 'Error in cart creation!');
        }
    }

    public void changeAssets() {

        try {
            if ((!bErrorOccurred && !assetIdForChangeToQuantityMap.isEmpty()) || Test.isRunningTest()) {

                List<Id> assetIdList = new List<Id>(assetIdForChangeToQuantityMap.keySet());
                deInstalledLineItemMap = APTS_OrderUtils.changeAssets(cartId, assetIdList);
            }
        } catch (Exception e) {
            raiseError(e, 'Error in asset change!');
        }
    }

    public void cancelAssets() {

        try {
            if ((!bErrorOccurred && !assetIdForCancelList.isEmpty()) || Test.isRunningTest()) {
                Map<Id, Apttus_Config2__LineItem__c> mapLines =  APTS_OrderUtils.cancelAssets(cartId, assetIdForCancelList);
                if (mapLines == NULL || mapLines.isEmpty()) {
                    return;
                }

                //Prepare map of Asset Line Item ID
                Set<Id> setAssetIds = new Set<Id>();
                for (Apttus_Config2__LineItem__c lineItem : mapLines.values()) {
                    if (lineItem.Apttus_Config2__AssetLineItemId__c != NULL) {
                        setAssetIds.add(lineItem.Apttus_Config2__AssetLineItemId__c);
                    }
                }

                setAssetPricing(true, setAssetIds, mapLines);
            }
        } catch (Exception e) {
            //29-Aug-2018 - Defect# 18261 - Delete the created Order and Cart if the Asset termination fails.
            if (cartId != null) {
                Database.delete(cartId, false);
            }
            if (oReturnOrder != null) {
                Database.delete(oReturnOrder, false);
            }
            raiseError(e, 'Error in asset cancelation!');
        }
    }

    public void updateQuantity() {

        try {
            if ((!bErrorOccurred && !assetIdForChangeToQuantityMap.isEmpty()) || Test.isRunningTest()) {
                Set<Id> setAssetIds = new Set<Id>();
                for (Apttus_Config2__LineItem__c oReturnLineItem : deInstalledLineItemMap.values()) {
                    if (oReturnLineItem.Apttus_Config2__IsPrimaryLine__c) {
                        //v115 ++ <<
                        Decimal originalQty = (oReturnLineItem.Apttus_Config2__Quantity__c == null) ? changeAssetsOriginalQtyMap.get(oReturnLineItem.Apttus_Config2__AssetLineItemId__c): oReturnLineItem.Apttus_Config2__Quantity__c;
                        oReturnLineItem.Apttus_Config2__Quantity__c = originalQty - assetIdForChangeToQuantityMap.get(oReturnLineItem.Apttus_Config2__AssetLineItemId__c);
                        //v115 ++ >>
                        //v101 ++ <<
                        oReturnLineItem.APTS_Returned_Quantity__c = assetIdForChangeToQuantityMap.get(oReturnLineItem.Apttus_Config2__AssetLineItemId__c);
                        //v101 ++ >> 
                                               
                        for (Apttus_Config2__LineItem__c oReturnNPLineItem : deInstalledLineItemMap.values()) {
                            if (!oReturnNPLineItem.Apttus_Config2__IsPrimaryLine__c && oReturnLineItem.Apttus_Config2__LineNumber__c == oReturnNPLineItem.Apttus_Config2__LineNumber__c) {
                                oReturnNPLineItem.Apttus_Config2__Quantity__c = oReturnLineItem.Apttus_Config2__Quantity__c;
                            }
                        }
                    }

                    if (oReturnLineItem.Apttus_Config2__AssetLineItemId__c != NULL) {
                        setAssetIds.add(oReturnLineItem.Apttus_Config2__AssetLineItemId__c);
                    }
                }

                Boolean isLineItemUpdated = setAssetPricing(false, setAssetIds, deInstalledLineItemMap);

                if (!isLineItemUpdated) {
                    Database.update(deInstalledLineItemMap.values());
                }
            }
        } catch (Exception e) {
            raiseError(e, 'Error in quantity update!');
        }
    }

    public void repriceCart() {

        try {
            if (!bErrorOccurred) {
            //V116 ++ <<
               
               bRepricePending = APTS_DigitalOrderBatchHelper.repriceCart(cartId);
               //V116 ++ >>
            }
        } catch (Exception e) {
            raiseError(e, 'Error while repricing the cart!');
        }
    }

    public void saveCart() {

        try {
            if (!bErrorOccurred) {                

                Apttus_Config2__ProductConfiguration__c oDeInstalledCart = APTS_OrderUtils.saveCart(cartId);
                Database.update(oDeInstalledCart);
            }
        } catch (Exception e) {
            raiseError(e, 'Error while saving the cart!');
        }
    }

    public void finalizeCart() {

        try {
            if (!bErrorOccurred) {
                //repriceCart(); //V116 ++ <<>>
                if(bRepricePending)
                {
                    repriceCart();
                }
                APTS_OrderUtils.finalizeCart(cartId);
            }
        } catch (Exception e) {
            raiseError(e, 'Error while finalizing order cart!');
        }
    }

    public void synchronizeCart() {

        try {
            if (!bErrorOccurred) {
                APTS_OrderUtils.syncCart(cartId);
            }
        } catch (Exception e) {
            raiseError(e, 'Error while sunchronizing order cart!');
        }
    }

    public PageReference goToOrder() {

        PageReference pageRef = null;

        if (!bErrorOccurred) {
            if (bReturnOrder) {
                pageRef = new PageReference('/' + oReturnOrder.Id);
            } else {
                pageRef = new PageReference('/' + oOrder.Id);
            }

        }

        return pageRef;
    }

    private Boolean validate() {

        Boolean bResult = true;

        //try {
        //if user click on create order before clicking on agreement section
        if (bFirstClickOnAgreement) {

            loadAgreements();
        }

        if (!agreementWrapperList.isEmpty()) {

            Integer iSelectedCount = 0;

            for (AgreementWrapper oAgreementWrapper : agreementWrapperList) {
                if (oAgreementWrapper.selected) {
                    iSelectedCount++;
                }
            }

            if (iSelectedCount > 1) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, APTS_OrderConstants.ONE_AGREEMENT));
                bResult = false;
            }

            if (iSelectedCount == 0 && !agreementWrapperList.isEmpty() && oOrder.APTS_Order_Sub_Type__c != APTS_OrderConstants.STANDARD_RETURN ) { //V105
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, APTS_OrderConstants.SELECT_AN_AGREEMENT));
                bResult = false;
            }
        }

        if (bShowOrders) {

            assetIdForChangeToQuantityMap.clear();
            changeAssetsOriginalQtyMap.clear(); //v115 ++ <<>>

            Integer iSelectedCount = 0;
            Boolean bOneSelected;

            for (OrderWrapper oOrderWrapper : orderWrapperList) {
                bOneSelected = false;
                for (APTS_OrderLineItemWrapper oOrderLineItemWrapper : oOrderWrapper.orderLineItemWrapperList) {
                    if (oOrderLineItemWrapper.selected) {

                        if (oOrderLineItemWrapper.oOrderLineItem.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__Quantity__c == oOrderLineItemWrapper.returnedQuantity) {
                            assetIdForCancelList.add(oOrderLineItemWrapper.oOrderLineItem.Apttus_Config2__AssetLineItemId__c);
                        } else  if (oOrderLineItemWrapper.oOrderLineItem.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__Quantity__c < oOrderLineItemWrapper.returnedQuantity) {
                            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, APTS_OrderConstants.RETURN_QUANTITY_SHOULD_BE_LESS));
                            bResult = false;
                        }

                        else {
                            assetIdForChangeToQuantityMap.put(oOrderLineItemWrapper.oOrderLineItem.Apttus_Config2__AssetLineItemId__c, oOrderLineItemWrapper.returnedQuantity);
                            changeAssetsOriginalQtyMap.put(oOrderLineItemWrapper.oOrderLineItem.Apttus_Config2__AssetLineItemId__c, oOrderLineItemWrapper.oOrderLineItem.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__Quantity__c); //v115 ++ <<>>
                        }

                        if (oOrderLineItemWrapper.returnedQuantity <= 0) {
                            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, APTS_OrderConstants.POSITIVE_RETURN_QUANTITY));
                            bResult = false;
                            iSelectedCount++;
                            break;
                        }

                        if (!bOneSelected) {
                            iSelectedCount++;
                        }
                        bOneSelected = true;
                    }
                }
            }

            if (iSelectedCount > 1) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, APTS_OrderConstants.PRODUCTS_FROM_ONE_ORDER));
                bResult = false;
            }
            if (iSelectedCount == 0) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, APTS_OrderConstants.PRODUCT_MANDATORY));
                bResult = false;
            }
        }
        //} catch (Exception e) {
        //  APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id), 'OM', false, true, APTS_OrderConstants.EMAIL, true);
        //}


        return bResult;
    }

    public void searchProducts() {

        sAllProducts = '[';

        String searchStr = ApexPages.currentPage().getParameters().get(APTS_OrderConstants.FIRST_PARAM);

        Set<String> filteredProductNameSet = new Set<String>();

        for (String sProductName : availableProductSet) {
            if (sProductName.containsIgnoreCase(searchStr)) {
                filteredProductNameSet.add(sProductName);
            }
        }

        if (!filteredProductNameSet.isEmpty()) {
            Integer count = filteredProductNameSet.size();
            Integer iId = 0;
            for (String sProductName : filteredProductNameSet) {

                sAllProducts += '{\'label\':\'' + sProductName + '\',\'value\':\'' + iId +  '\'}';
                if (--count != 0) {
                    sAllProducts += ',';
                }
                iId++;
            }
        }

        sAllProducts += ']';
    }

    public void searchOrderNumbers() {

        sAllOrderNumbers = '[';

        String searchStr = ApexPages.currentPage().getParameters().get(APTS_OrderConstants.FIRST_PARAM);

        Set<String> filteredOrderNumberSet = new Set<String>();
        for (String sOrderNumber : availableOrderNumberSet) {
            if (sOrderNumber.containsIgnoreCase(searchStr)) {
                filteredOrderNumberSet.add(sOrderNumber);
            }
        }

        if (!filteredOrderNumberSet.isEmpty()) {
            Integer count = filteredOrderNumberSet.size();
            Integer iId = 0;
            for (String sOrderNumber : filteredOrderNumberSet) {

                sAllOrderNumbers += '{\'label\':\'' + sOrderNumber + '\',\'value\':\'' + iId +  '\'}';
                if (--count != 0) {
                    sAllOrderNumbers += ',';
                }
                iId++;
            }
        }

        sAllOrderNumbers += ']';
    }

    public void doOrderSearch() {

        Set<Integer> indexToRemoveSet = new Set<Integer>();
        Integer index = 0;

        orderWrapperList.clear();
        orderWrapperList.addAll(orderWrapperTmpList);

        availableOrderNumberSet.clear();
        availableOrderNumberSet.addAll(availableOrderNumberInitialSet);

        for (OrderWrapper oOrderWrapper : orderWrapperList) {
            if (!String.isBlank(sProductName)) {
                String sProductNameWOSpaces = sProductName.replaceAll( '\\s+', '');
                if (!oOrderWrapper.productNameSet.contains(sProductNameWOSpaces)) {
                    indexToRemoveSet.add(index);
                }
            }
            if (!String.isBlank(sOrderNumber)) {
                if (oOrderWrapper.oOrder.Name != sOrderNumber) {
                    indexToRemoveSet.add(index);
                }
            }
            index++;
        }

        for (Integer i : indexToRemoveSet) {
            OrderWrapper oOrderWrapper = orderWrapperList.get(i);
            availableOrderNumberSet.remove(oOrderWrapper.oOrder.Name);
        }

        for (Integer i = orderWrapperList.size(); i >= 0; i--) {
            if (indexToRemoveSet.contains(i)) {
                orderWrapperList.remove(i);
            }
        }

        orderWrapperDisplayList.clear();
        if (iInitialCountToDisplay >= orderWrapperList.size()) {
            iCountToDisplay = orderWrapperList.size();
            bDisableMore = true;
        } else {
            iCountToDisplay = iInitialCountToDisplay;
        }

        for (Integer iIndex = 0; iIndex < iCountToDisplay; iIndex++) {
            OrderWrapper oOrderWrapper = orderWrapperList.get(iIndex);
            orderWrapperDisplayList.add(oOrderWrapper);
        }
    }

    public void resetOrderSearch() {

        sProductName = null;
        sOrderNumber = null;
        dtOrderStartDate = null;

        orderWrapperList.clear();
        orderWrapperList.addAll(orderWrapperTmpList);

        availableOrderNumberSet.clear();
        availableOrderNumberSet.addAll(availableOrderNumberInitialSet);

        iCountToDisplay = iInitialCountToDisplay;
        Integer iMinCount = iInitialCountToDisplay <= orderWrapperList.size() ? iInitialCountToDisplay : orderWrapperList.size();
        orderWrapperDisplayList.clear();
        bDisableLess = true;

        for (Integer iIndex = 0; iIndex < iMinCount; iIndex++) {
            OrderWrapper oOrderWrapper = orderWrapperList.get(iIndex);
            orderWrapperDisplayList.add(oOrderWrapper);
        }

        if (iCountToDisplay < orderWrapperList.size()) {
            bDisableMore = false;
        } else {
            bDisableMore = true;
        }
    }

    public void loadMore() {

        bDisableLess = false;
        iCountToDisplay = iCountToDisplay + iInitialCountToDisplay;
        Integer iMaxCount = iCountToDisplay;
        //try {
        if (iCountToDisplay >= orderWrapperList.size()) {
            iMaxCount = orderWrapperList.size();
            bDisableMore = true;
        }

        orderWrapperDisplayList.clear();
        for (Integer iIndex = 0; iIndex < iMaxCount; iIndex++) {
            OrderWrapper oOrderWrapper = orderWrapperList.get(iIndex);
            orderWrapperDisplayList.add(oOrderWrapper);
        }
        //} catch (Exception e) {
        //  APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id), 'OM', false, true, APTS_OrderConstants.EMAIL, true);
        //}
    }

    public void loadLess() {

        bDisableMore = false;
        //try{
        if ((iCountToDisplay - iInitialCountToDisplay) <= iInitialCountToDisplay) {
            iCountToDisplay = iInitialCountToDisplay;
            bDisableLess = true;
        } else {
            iCountToDisplay = iCountToDisplay - iInitialCountToDisplay;
        }

        orderWrapperDisplayList.clear();
        for (Integer iIndex = 0; iIndex < iCountToDisplay; iIndex++) {
            OrderWrapper oOrderWrapper = orderWrapperList.get(iIndex);
            orderWrapperDisplayList.add(oOrderWrapper);
        }
        //} catch (Exception e) {
        //  APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id), 'OM', false, true, APTS_OrderConstants.EMAIL, true);
        //}
    }

    public void selectAll() {

        //try{
        for (OrderWrapper oOrderWrapper : orderWrapperList) {
            for (APTS_OrderLineItemWrapper oOrderLineItemWrapper : oOrderWrapper.orderLineItemWrapperList) {
                if (oOrderWrapper.selected) {
                    oOrderLineItemWrapper.returnedQuantity = Integer.valueOf(oOrderLineItemWrapper.oOrderLineItem.Apttus_Config2__FulfilledQuantity__c);
                } else {
                    oOrderLineItemWrapper.returnedQuantity = 0;
                }

                oOrderLineItemWrapper.selected = oOrderWrapper.selected;
            }
        }
        //} catch (Exception e) {
        //  APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id), 'OM', false, true, APTS_OrderConstants.EMAIL, true);
        //}
    }

    public PageReference back() {

        PageReference pageRef;

        if (oReturnOrder != null) {
            List<Apttus_Config2__Order__c> listOrders = [SELECT Id FROM Apttus_Config2__Order__c WHERE Id = : oReturnOrder.Id];
            if (!listOrders.isEmpty()) {
                Database.delete(oReturnOrder);

                if (cartId != null) {
                    List<Apttus_Config2__ProductConfiguration__c> listCarts = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c WHERE Id = : cartId];
                    if (!listCarts.isEmpty()) {
                        Apttus_Config2__ProductConfiguration__c oNewCart = new Apttus_Config2__ProductConfiguration__c(Id = cartId);
                        Database.delete(oNewCart);
                    }
                }
            }
        }

        pageRef = new PageReference('/' + accountId);

        return pageRef;
    }

    //Removed asset adjustment copy code from here to adjustmentlineitem callback due to 19711 & 19469
    public Boolean setAssetPricing(Boolean isCancelAsset, Set<Id> setAssetIds, Map<Id, Apttus_Config2__LineItem__c> mapLines) {

        Boolean isLineItemUpdated = false;

        if (setAssetIds == null || setAssetIds.isEmpty() || mapLines == null || mapLines.isEmpty()) {
            return isLineItemUpdated;
        }

        Map<Id, Apttus_Config2__AssetLineItem__c> mapAssetLineItem = new Map<Id, Apttus_Config2__AssetLineItem__c>([SELECT Id, Apttus_Config2__ListPrice__c, APTS_BasePriceOverride__c FROM Apttus_Config2__AssetLineItem__c WHERE Id = : setAssetIds]); 

        if (mapAssetLineItem != null && !mapAssetLineItem.isEmpty()) {

            List<Apttus_Config2__LineItem__c> listLineItemsToUpdate = new List<Apttus_Config2__LineItem__c>();
            Map<Id, Id> mapAssetID = new Map<Id, Id>();
            for (Apttus_Config2__LineItem__c lineItem : mapLines.values()) {

                Apttus_Config2__AssetLineItem__c oAssetLineItem = mapAssetLineItem.get(lineItem.Apttus_Config2__AssetLineItemId__c);
                if (oAssetLineItem != null) {
                    lineItem.Apttus_Config2__IsAssetPricing__c = false;
                    lineItem.Apttus_Config2__BasePriceOverride__c = (oAssetLineItem.APTS_BasePriceOverride__c != null)? oAssetLineItem.APTS_BasePriceOverride__c : oAssetLineItem.Apttus_Config2__ListPrice__c; //V114 ++ <<>>
                   
                    listLineItemsToUpdate.add(lineItem);
                }

                mapAssetID.put(lineItem.Apttus_Config2__AssetLineItemId__c, lineItem.Id);
            }

            if (isCancelAsset) {
                addAssetAdjustments(mapAssetID);
            }

            if (!listLineItemsToUpdate.isEmpty()) {
                update listLineItemsToUpdate;
                isLineItemUpdated = true;
            }

        }

        return isLineItemUpdated;
    }

    //for cancelled asset, adjustment callback doesn't gets invoked,
    @TestVisible
    private Boolean addAssetAdjustments(Map<Id, Id> mapAssetID) {

        Boolean isLineItemUpdated = false;

        if (mapAssetID == null || mapAssetID.isEmpty()) {
            return isLineItemUpdated;
        }

        //Get Asset Adjustments
        List<Apttus_Config2__AdjustmentLineItem__c> listAdjustmentLineItemsToAdd = new List<Apttus_Config2__AdjustmentLineItem__c>();

        for (Apttus_Config2_AssetAdjustItem__c oAssetAdjustment : [
                    SELECT Id, Apttus_Config2_AssetAdjustAmount__c, Apttus_Config2_AssetAdjustAppliesTo__c, Apttus_Config2_AssetAdjustType__c,
                    Apttus_Config2_Adjustment_Uom__c, Apttus_Config2_Bucket__c, Apttus_Config2_LineNumber__c, Apttus_Config2_SubType__c,
                    Apttus_Config2_Type__c, Apttus_Config2_AssetLineItemId__c, Apttus_Config2_LineType__c, Apttus_Config2_IsModifiable__c,
                    Apttus_Config2_AssetLineItemId__r.Apttus_Config2__BasePrice__c, Apttus_Config2_AssetLineItemId__r.Apttus_Config2__ListPrice__c,
                    RunningTotalAdjustedPrice__c, Apttus_Config2_IncentiveAsetAdjustAmount__c
                    FROM Apttus_Config2_AssetAdjustItem__c
                    WHERE Apttus_Config2_AssetLineItemId__c = :mapAssetID.keySet()]) {

            Id lineItemID = mapAssetID.get(oAssetAdjustment.Apttus_Config2_AssetLineItemId__c);

            if (lineItemID != null) {

                Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem = new Apttus_Config2__AdjustmentLineItem__c();
                adjustmentLineItem.Apttus_Config2__LineItemId__c = lineItemID;
                adjustmentLineItem.Apttus_Config2__LineType__c = oAssetAdjustment.Apttus_Config2_LineType__c;
                adjustmentLineItem.Apttus_Config2__LineNumber__c = oAssetAdjustment.Apttus_Config2_LineNumber__c;
                adjustmentLineItem.Apttus_Config2__IsModifiable__c = oAssetAdjustment.Apttus_Config2_IsModifiable__c;
                adjustmentLineItem.Apttus_Config2__AdjustmentType__c = oAssetAdjustment.Apttus_Config2_AssetAdjustType__c;
                adjustmentLineItem.Apttus_Config2__AdjustmentAmount__c = oAssetAdjustment.Apttus_Config2_AssetAdjustAmount__c;
                adjustmentLineItem.Apttus_Config2__Bucket__c = oAssetAdjustment.Apttus_Config2_Bucket__c;
                adjustmentLineItem.Apttus_Config2__AdjustmentAppliesTo__c = oAssetAdjustment.Apttus_Config2_AssetAdjustAppliesTo__c;
                adjustmentLineItem.Apttus_Config2__Type__c = oAssetAdjustment.Apttus_Config2_Type__c;
                adjustmentLineItem.Apttus_Config2__SubType__c = oAssetAdjustment.Apttus_Config2_SubType__c;
                adjustmentLineItem.Apttus_Config2_SellingUom__c = oAssetAdjustment.Apttus_Config2_Adjustment_Uom__c;
                adjustmentLineItem.Apttus_Config2__AdjustmentUom__c = oAssetAdjustment.Apttus_Config2_Adjustment_Uom__c;
                adjustmentLineItem.Apttus_Config2__RunningTotalAdjustedPrice__c = oAssetAdjustment.RunningTotalAdjustedPrice__c;
                adjustmentLineItem.Apttus_Config2__IncentiveAdjustmentAmount__c = oAssetAdjustment.Apttus_Config2_IncentiveAsetAdjustAmount__c;

                listAdjustmentLineItemsToAdd.add(adjustmentLineItem);
            }
        }

        if (!listAdjustmentLineItemsToAdd.isEmpty()) {
            insert listAdjustmentLineItemsToAdd;
        }

        return isLineItemUpdated;
    }

    private void raiseError(Exception e, String sMessage) {

        APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() + ':: ' + e.getMessage(), 'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id), 'OM', false, true, null, true);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, sMessage + e.getStackTraceString()));
        bErrorOccurred = true;
    }

    public without sharing class AgreementWrapper {

        public Boolean selected {get; set;}
        public Apttus__APTS_Agreement__c oAgreement {get; set;}
        public String sAgreementRecordType {get; set;}

        public AgreementWrapper(Boolean selected, Apttus__APTS_Agreement__c oAgreement) {

            this.selected = selected;
            this.oAgreement = oAgreement;
            this.sAgreementRecordType = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosById().get(oAgreement.RecordTypeId).getname();
        }
    }

    public with sharing class OrderWrapper implements Comparable {

        public Boolean selected {get; set;}
        public Apttus_Config2__Order__c oOrder {get; set;}
        public String sOrderRecordType {get; set;}
        public List<APTS_OrderLineItemWrapper> orderLineItemWrapperList {get; set;}
        public Date dtOrderStartDate {get; set;}
        public Set<String> productNameSet {get; set;}

        public OrderWrapper(Boolean selected, Apttus_Config2__Order__c oOrder, List<APTS_OrderLineItemWrapper> orderLineItemWrapperList) {

            this.selected = selected;
            this.oOrder = oOrder;
            this.sOrderRecordType = Schema.SObjectType.Apttus_Config2__Order__c.getRecordTypeInfosById().get(oOrder.RecordTypeId).getname();
            this.orderLineItemWrapperList = orderLineItemWrapperList;
            this.dtOrderStartDate = oOrder.Apttus_Config2__OrderStartDate__c;

            Set<String> productNameTmpSet = new Set<String>();
            for (APTS_OrderLineItemWrapper oOrderLineItemWrapper : orderLineItemWrapperList) {
                Apttus_Config2__OrderLineItem__c oOrderLineItem = oOrderLineItemWrapper.oOrderLineItem;
                String sProductName = oOrderLineItem.Apttus_Config2__ProductId__r.Name;
                String sProductNameWOSpaces = sProductName.replaceAll( '\\s+', '');

                productNameTmpSet.add(sProductNameWOSpaces);
            }

            this.productNameSet = productNameTmpSet;
        }

        public Integer compareTo(Object orderWrapper) {

            OrderWrapper compareToPW = (OrderWrapper)orderWrapper;
            if (dtOrderStartDate == compareToPW.dtOrderStartDate) return 0;
            if (dtOrderStartDate < compareToPW.dtOrderStartDate) return 1;
            return -1;
        }
    }

    public with sharing class APTS_OrderLineItemWrapper {

        public Boolean selected {get; set;}
        public Apttus_Config2__OrderLineItem__c oOrderLineItem {get; set;}
        public Integer returnedQuantity {get; set;}

        public APTS_OrderLineItemWrapper() {

            this.selected = false;
            this.oOrderLineItem = null;
            this.returnedQuantity = 0;
        }

        public APTS_OrderLineItemWrapper(Boolean selected, Apttus_Config2__OrderLineItem__c oOrderLineItem, Integer returnedQuantity) {

            this.selected = selected;
            this.oOrderLineItem = oOrderLineItem;
            this.returnedQuantity = returnedQuantity;
        }
    }
   
   
}