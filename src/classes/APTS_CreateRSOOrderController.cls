/*************************************************************
@Name: APTS_CreateRSOOrderController
@Author: Neev Shah
@CreateDate: 22-05-2018
@Description: create RSO Order from Apttus
******************************************************************/

//v100 16-10-2018 Akanksha: Set fields from account location
//v101 22-10-2018 Aarthi: Added fix for Defect #20508
//v102 23-10-2018 Akanksha: Added condition in query for defect 20076
//v103 24-10-2018 Rajesh Patel: Added fix for Defect #20508
//V104 27-10-2018 Aarthi: Added logic to set the Requested delivery date based on Country Offset value similar to Standard Order - Defect #20678
//V105 20-02-2019 Neev  Defect#4920 : Set Location from account instead of Agreement.
//V106 08-03-2019 CR#2240 : Changes on Requested Delivery Date by Nikita
//V107 30-08-2019 Nikita Modi: QTCFLEX1-986 : Agreement selection for RSO order should be equal to Standard order
//v108 11-Sept-2020 Sneha Jaiwant: DQ2456 Agreements with the end date in future
//V109 01-Dec-2020 Aarthi Pitchai: DQ-4020 Issue fix

public without sharing class APTS_CreateRSOOrderController { //V109 ++<<>>
    private static final String PAGE_PARAM_ID = 'id';
    private static final String PAGE_PARAM_LOCID = 'locId';
    private static final String PAGE_PARAM_TYPE = 'type';
    private static final String PARAM_TYPE_ROUTE = 'Route';
    private static final String PARAM_TYPE_OPERATING = 'Operating';
    private static final String PAGE_MSG_ID_NULL = 'Id can\'t be blank, please try again.';
    private static final String PAGE_MSG_RS_AG_NULL = 'No Active RouteSales Agreement found for this Customer.';
    private static final String PAGE_MSG_OP_AG_NULL = 'No Active Operating Agreement found for this Customer.';
    private static final String PAGE_MSG_CUST_NO_RSO = 'Customer can\'t create RouteSales Order.';
    private static final String PAGE_MSG_CUST_NO_OPERATING = 'Customer can\'t create Operating Order.';
    private static final String PAGE_MSG_ACC_NULL = 'Account does not exists. Please try with valid record.';
    private static final String PAGE_MSG_NO_CONSIGNMENT = 'No Consignment Products found on selected Agreement.';
    private static final String PAGE_MSG_NO_STOCKCOUNT = 'Stock Count is not allowed for selected Agreement.';
    private static final String WO_TYPE_ROUTESALES = 'S25';
    private static final String WO_TYPE_OPERATING = 'S20';
    private static final String ORDERTYPE_ROUTESALES = 'Route Sales Order';
    private static final String ORDERTYPE_OPERATING = 'Operating Order';
    private static final String AGTYPE_CONSUMPTIONDEAL = 'Consumption Model';
    private static final String AGTYPE_STANDARD = 'Standard Deal';
    private static final String ORDERSUBTYPE_STOCKCOUNT = 'Stock Count';
    private static final String ACCOUNT_STATUS = 'Valid';
    private static final String FIRSTPARAM = System.Label.APTS_firstParam;
    private static final String PAGE_MSG_End='There is no active agreement with an end date in the future for this account' ;

    private Id locationId = NULL;
    private Id accountId = NULL;
    private Id sourceRecordId = NULL;
    private String stype = NULL;
    private Account initialAccount = NULL;
    public Apttus_Config2__Order__c oRSOOrder {get; set;}
    public Apttus__APTS_Agreement__c oAgreement {get; set;}
    public List<AgreementWrapper> listAgWrapper {get; set;}
    public Boolean isSelectedAgreement {get; set;}
    public Boolean isStockCountVisible {get; set;}
    public List<ConsignmentProductsWrapper> listConsignmentProds {get; set;}
    private List<ConsignmentProductsWrapper> listAllConsignmentWrapper = new List<ConsignmentProductsWrapper>();
    private Map<Id, APTS_RSOProductCatalogWrapper.ContractedProducts> mapContProducts = new Map<Id, APTS_RSOProductCatalogWrapper.ContractedProducts>();

    //V103 ++ <<
    public Boolean hasError {get; set;}
    //V103 ++ >>

    public String sProductName {get; set;}
    public selectOption[] lstGender { get; set; }

    public class ConsignmentProductsWrapper {
        public Boolean isSelected {get; set;}
        public Integer quantity {get; set;}
        public APTS_RSOProductCatalogWrapper.ContractedProducts contractedProd {get; set;}
    }

    public with sharing class AgreementWrapper {
        public Boolean isSelected {get; set;}
        public Apttus__APTS_Agreement__c oAgreement {get; set;}
    }

    public APTS_CreateRSOOrderController() {
        String sErrMsg;

        isSelectedAgreement = TRUE;
        isStockCountVisible = FALSE;
        hasError = FALSE;

        try {

            accountId = ApexPages.currentPage().getParameters().get(PAGE_PARAM_ID);
            locationId = ApexPages.currentPage().getParameters().get(PAGE_PARAM_LOCID);
            sType = ApexPages.currentPage().getParameters().get(PAGE_PARAM_TYPE);
            sourceRecordId = locationId != null ? locationId : accountId;
            oRSOOrder = new Apttus_Config2__Order__c();

            //You can use any object in place of account
            lstGender = new selectoption[] {};
            //code to populate all Selling UOM
            /*Schema.describeFieldresult  f1 = Apttus_Config2__LineItem__c.Apttus_Config2__SellingUom__c.getdescribe();

            for (Schema.picklistEntry p1 : f1.getPicklistValues()) {
                lstGender.add(new selectOption(p1.getLabel(), p1.getLabel()));
            }*/

            lstGender.add(new selectOption('SAP_BX', 'Box'));
            lstGender.add(new selectOption('SAP_PCE', 'Piece'));

            System.debug('lstGender = ' + lstGender);

        } catch (Exception ex) {

            //APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString(), 'RouteSalesOrOperating', sourceRecordId, 'OM', false, false, APTS_OrderConstants.APTS_EMAIL, true);
            sErrMsg = ex.getLineNumber() + '. StackTrace = ' + ex.getStackTraceString();

        } finally {

            if (String.isNotBlank(sErrMsg)) {
                hasError = true;
                ApexPages.Message oErrorMessage = new ApexPages.Message(ApexPages.Severity.ERROR, sErrMsg);
                ApexPages.addMessage(oErrorMessage);
            }
        }
    }

    public void prepareData() {
        String sErrMsg;
        hasError = false;

        try {

            listConsignmentProds = new List<ConsignmentProductsWrapper>();
            listAgWrapper = new List<AgreementWrapper>();

            if (String.isNotBlank(accountId) && String.isNotBlank(sType)) {

                String sWorkOrderType = sType.equalsIgnoreCase(PARAM_TYPE_ROUTE) ?  WO_TYPE_ROUTESALES : null;
                sWorkOrderType = sType.equalsIgnoreCase(PARAM_TYPE_OPERATING) ?  WO_TYPE_OPERATING : sWorkOrderType;

                if (String.isNotBlank(sWorkOrderType)) {
                    oRSOOrder.APTS_Order_Type__c = sType.equalsIgnoreCase(PARAM_TYPE_ROUTE) ? ORDERTYPE_ROUTESALES : ORDERTYPE_OPERATING;

                    Set<Id> setAccId = new Set<Id> {accountId};
                    List<Id> ListAccId = new List<Id> {accountId};  //v107
                    Map<Id, Account> mapAccounts = APTS_RSOOrderUtils.getAccounts(setAccId);
                    initialAccount = mapAccounts.get(accountId);

                    if (initialAccount != null) {
                        Map<Id,Apttus__APTS_Agreement__c> mapTemAg= new Map<Id,Apttus__APTS_Agreement__c>();
                        Map<Id, List<Apttus__APTS_Agreement__c>> mapAccAgreements;

                        //add parent and grand parent id
                        if (initialAccount.ParentId != null) {
                            setAccId.add(initialAccount.ParentId);
                            ListAccId.add(initialAccount.ParentId);  //V107
                            if (initialAccount.Parent.ParentId != null) {
                                setAccId.add(initialAccount.Parent.ParentId);
                                ListAccId.add(initialAccount.Parent.ParentId); //V107 
                            }
                        }

                        
                        //v107 ++<< Passing list to method instead of Set
                        system.debug('ListAccId-------'+ListAccId);
                        APTS_RSOOrderUtils.RSOWrapper rsoWrapper = APTS_RSOOrderUtils.getRSOAgreements(oRSOOrder.APTS_Order_Type__c, ListAccId);
                        //v108 ++<<
                        mapAccAgreements = rsoWrapper.mapAccAgr;
                        system.debug('$$1'+mapAccAgreements);
                        //v108 ++>>
                        //v107 -->>

                     
                        
                        if (mapAccAgreements != null && !mapAccAgreements.isEmpty()  ) {

                            for (Id acc : mapAccAgreements.keySet()) {
                        system.debug('$$2'+acc);

                                if (mapAccAgreements.get(acc) != null) {
                                 system.debug('$$2'+mapAccAgreements.get(acc));
                                    for (Apttus__APTS_Agreement__c oAg : mapAccAgreements.get(acc)) {
                                    if(!mapTemAg.containskey(oAg.Id)){
                                        mapTemAg.put(oAg.ID,oAg);
                                        }
                                    }
                                }
                            }
                            
                        }

                        if (mapTemAg!= null && !mapTemAg.isEmpty()) {
                            Boolean hasConsumptionAg = false;
                            Boolean isSelected = false;
                            String recordType;
                            //prepare list of Agreements
                            for (Apttus__APTS_Agreement__c oTempAg : mapTemAg.values()) {
                                if ((sType.equalsIgnoreCase(PARAM_TYPE_ROUTE) && oTempAg.APTS_Routesales__c) || (sType.equalsIgnoreCase(PARAM_TYPE_OPERATING))) {
                                    AgreementWrapper oAgWrapper = new AgreementWrapper();
                                    oAgWrapper.oAgreement = oTempAg;
                                    listAgWrapper.add(oAgWrapper);
                                    recordType = oTempAg.RecordTypeId != null && oTempAg.RecordType.Name != null ? oTempAg.RecordType.Name : null;
                                    oAgWrapper.isSelected = !isSelected && ((sType.equalsIgnoreCase(PARAM_TYPE_OPERATING) && AGTYPE_CONSUMPTIONDEAL.equalsIgnoreCase(recordType)) || (sType.equalsIgnoreCase(PARAM_TYPE_ROUTE) && oTempAg.APTS_Routesales__c)) ? TRUE : FALSE;
                                    isSelected = oAgWrapper.isSelected ? true : isSelected;
                                }
                               

                            }
                             listAgWrapper[0].isSelected = !isSelected ? TRUE : listAgWrapper[0].isSelected;


                            /*List<PhysicalAsset__c> phyAssetList = [SELECT id FROM PhysicalAsset__c WHERE (AccountLocation__c = :locationId OR AccountLocation__r.Apttus_Config2__AccountId__c  = : locationId) AND OptionType__c IN :optionType LIMIT 1];
                            if (!phyAssetList.isEmpty()) 
                            */


                            //For Operating Order with Consumption Model get Consignment products
                            if (ORDERTYPE_OPERATING.equalsIgnoreCase(oRSOOrder.APTS_Order_Type__c)) {
                                Map<Id, Apttus__APTS_Agreement__c> mapContributingAg = APTS_RSOOrderUtils.getRSOAgreement(ORDERTYPE_OPERATING, mapAccounts.keySet());
                                //get all RSO products with Categories map
                              //  APTS_RSOProductCatalogWrapper prodWrapper = APTS_RSOOrderUtils.getRSOCatalogProducts('Operating', initialAccount.Sales_Organization__c, FALSE, null,FALSE);
                                APTS_RSOProductCatalogWrapper prodWrapper = APTS_RSOOrderUtils.getRSOCatalogProducts('Operating', initialAccount.Sales_Organization__c, FALSE, null);

                                if (prodWrapper != NULL && prodWrapper.mapAllRSOProducts != NULL && !prodWrapper.mapAllRSOProducts.isEmpty()) {
                                    //prepare map of contracted products
                                    Map<Id, List<APTS_RSOProductCatalogWrapper.ContractedProducts>> mapContratedProd = APTS_RSOOrderUtils.getContractedProducts(ORDERTYPE_OPERATING, setAccId, mapContributingAg, prodWrapper.mapAllRSOProducts, prodWrapper.mapCategoryProductsId);

                                    if (mapContratedProd != null && !mapContratedProd.isEmpty()) {
                                        List<APTS_RSOProductCatalogWrapper.ContractedProducts> listContProd = mapContratedProd.get(accountId);
                                        if (listContProd != null) {
                                            for (APTS_RSOProductCatalogWrapper.ContractedProducts oProd : listContProd) {
                                                APTS_CreateRSOOrderController.ConsignmentProductsWrapper oWrapper = new APTS_CreateRSOOrderController.ConsignmentProductsWrapper();
                                                oWrapper.contractedProd = oProd;

                                                if (oProd.Consignment && !mapContProducts.containsKey(oProd.ProductID)) {
                                                    mapContProducts.put(oProd.ProductID, oProd);
                                                    listConsignmentProds.add(oWrapper);
                                                }
                                            }

                                            if (listConsignmentProds != null && !listConsignmentProds.isEmpty()) {
                                                listAllConsignmentWrapper.addAll(listConsignmentProds);
                                            }
                                        }
                                    }

                                }
                            }
                        } 
                       else if(rsoWrapper.IsAgreement){
                            sErrMsg = sType.equalsIgnoreCase(PARAM_TYPE_ROUTE) ? PAGE_MSG_CUST_NO_RSO + PAGE_MSG_RS_AG_NULL : PAGE_MSG_CUST_NO_OPERATING + PAGE_MSG_OP_AG_NULL;
                        }
                     //v108 ++<<
                     else if(!rsoWrapper.IsAgreement){
                     sErrMsg = PAGE_MSG_End;
                    }
                    //v108 ++>>
                    } 
                    else {
                        sErrMsg = PAGE_MSG_ACC_NULL;
                    }
                } else {
                    sErrMsg = sType.equalsIgnoreCase(PARAM_TYPE_ROUTE) ? PAGE_MSG_CUST_NO_RSO : PAGE_MSG_CUST_NO_OPERATING;
                }
            } else {
                sErrMsg = PAGE_MSG_ID_NULL;
            }

        } catch (Exception ex) {

            sErrMsg = ex.getLineNumber() + '. StackTrace = ' + ex.getStackTraceString();

        } finally {

            if (String.isNotBlank(sErrMsg)) {
                hasError = true;
                ApexPages.Message oErrorMessage = new ApexPages.Message(ApexPages.Severity.ERROR, sErrMsg);
                ApexPages.addMessage(oErrorMessage);
            }

        }
    }

    public void setOrderSubType() {
        try {
            stockCountData(false);
        } catch (Exception ex) {
            String sErrMsg = ex.getLineNumber() + '. StackTrace = ' + ex.getStackTraceString();
            ApexPages.Message oErrorMessage = new ApexPages.Message(ApexPages.Severity.ERROR, sErrMsg);
            ApexPages.addMessage(oErrorMessage);
        }
    }

    public void selectAgreement() {
        try {
            stockCountData(true);
        } catch (Exception ex) {
            String sErrMsg = ex.getLineNumber() + '. StackTrace = ' + ex.getStackTraceString();
            ApexPages.Message oErrorMessage = new ApexPages.Message(ApexPages.Severity.ERROR, sErrMsg);
            ApexPages.addMessage(oErrorMessage);
        }
    }

    public PageReference createOrder() {
        PageReference pageRef = new PageReference(ApexPages.currentPage().getUrl());
        String sErrMsg = '';
        hasError = false;

        try {
            List<Apttus_CPQApi.CPQ.SelectedProductDO> listProdToAdd = new List<Apttus_CPQApi.CPQ.SelectedProductDO>();

            //validation before Order Creation
            sErrMsg = String.isBlank(oRSOOrder.APTS_Order_Sub_Type__c) ? ' Please select Order Sub Type.' : sErrMsg;
            sErrMsg = oAgreement == null ? 'Select atleast one agreement.' : sErrMsg;

            if (ORDERSUBTYPE_STOCKCOUNT.equalsIgnoreCase(oRSOOrder.APTS_Order_Sub_Type__c)) {

                for (ConsignmentProductsWrapper oWrapper : listConsignmentProds) {
                    if (oWrapper.isSelected) {
                        if (oWrapper.quantity != null) {
                            Apttus_Config2__LineItem__c oLineItem = getLineItem(oWrapper);
                            Apttus_CPQApi.CPQ.SelectedProductDO sProd = APTS_OrderUtils.addStandaloneProductWithQuantity(oLineItem, oWrapper.quantity);
                            listProdToAdd.add(sProd);
                        } else {
                            sErrMsg = 'Quantity field can\'t be blank for selected product.';
                        }
                    }
                }

                if (listProdToAdd.isEmpty()) {
                    sErrMsg = 'No products selected for Stock Count. Please select atleast one.';
                }
            }


            if (sErrMsg == null || String.isBlank(sErrMsg)) {
                //set data on Order Header
                oRSOOrder = setOrderHeaderFields(initialAccount, oAgreement, oRSOOrder);
                Database.SaveResult sr = Database.insert(oRSOOrder, FALSE);

                if (sr.isSuccess()) {
                    if (ORDERSUBTYPE_STOCKCOUNT.equalsIgnoreCase(oRSOOrder.APTS_Order_Sub_Type__c)) {
                        addConsignmentProductsToCart(listProdToAdd);
                    }
                    pageRef = new PageReference('/' + oRSOOrder.Id);
                } else {
                    for (Database.Error e : sr.getErrors() ) {
                        sErrMsg += e.getMessage();
                    }
                }
            }
        } catch (Exception e) {
            //APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString(), 'RouteSalesOrOperating', locationId, 'OM', false, false, APTS_OrderConstants.APTS_EMAIL, true);
            sErrMsg = 'Exception on LineNumber' + e.getLineNumber() + '. Exception Message = ' + e.getMessage();
        } finally {
            if (String.isNotBlank(sErrMsg)) {
                hasError = true;
                ApexPages.Message oErrorMessage = new ApexPages.Message(ApexPages.Severity.ERROR, sErrMsg);
                ApexPages.addMessage(oErrorMessage);
            }
        }

        return pageRef;
    }

    public PageReference back() {
        PageReference pageRef;
        pageRef = new PageReference('/' + sourceRecordId);
        return pageRef;
    }

    public void filterProducts() {

        if (String.isNotBlank(sProductName)) {
            listConsignmentProds = new List<ConsignmentProductsWrapper>();

            if (listAllConsignmentWrapper != null && !listAllConsignmentWrapper.isEmpty()) {
                for (ConsignmentProductsWrapper oWrap : listAllConsignmentWrapper) {
                    if (oWrap.contractedProd != null &&
                            ((oWrap.contractedProd.ProductName != null && oWrap.contractedProd.ProductName.containsIgnoreCase(sProductName))
                             || (oWrap.contractedProd.ProductCode != null && oWrap.contractedProd.ProductCode.containsIgnoreCase(sProductName))
                             || (oWrap.contractedProd.Category != null && oWrap.contractedProd.Category.containsIgnoreCase(sProductName))
                             || (oWrap.contractedProd.SubCategory != null && oWrap.contractedProd.SubCategory.containsIgnoreCase(sProductName))
                             || (oWrap.contractedProd.SubSubCategory != null && oWrap.contractedProd.SubSubCategory.containsIgnoreCase(sProductName)))) {
                        listConsignmentProds.add(oWrap);
                    }
                }
            }

            if (listConsignmentProds == null || listConsignmentProds.isEmpty()) {
                //no products found
            }
        } else {
            //empty search
            resetSearch();
        }
    }

    //reset search
    public void resetSearch() {
        sProductName = null;
        listConsignmentProds = new List<ConsignmentProductsWrapper>();

        if (listAllConsignmentWrapper != null && !listAllConsignmentWrapper.isEmpty()) {
            listConsignmentProds.addAll(listAllConsignmentWrapper);
        }
    }

    public Apttus_Config2__Order__c setOrderHeaderFields(Account oAccount, Apttus__APTS_Agreement__c oAgreement, Apttus_Config2__Order__c oRSOOrder) {
        oRSOOrder.RecordTypeId = Schema.SObjectType.Apttus_Config2__Order__c.getRecordTypeInfosByName().get(oRSOOrder.APTS_Order_Type__c).getRecordTypeId();
        oRSOOrder = APTS_OrderUtils.setOrderHeader(oRSOOrder, oAccount);
        oRSOOrder = APTS_OrderUtils.setOrderHeader(oRSOOrder, oAgreement, oAccount);
        oRSOOrder.Apttus_Config2__Source__c = 'ACCOUNT';
        oRSOOrder.Apttus_CMConfig__AgreementId__c = oAgreement.Id;

        //location was set according to defect 19381, check agreement, if not than get first location
        //Defect 4920 - don't take Location from Agreement as Agreement can be Parent / Grand Parent Agreement
        Id locId = locationId != NULL ? locationId : null;
        /*if (oAgreement != null && oAgreement.APTS_Location__c != null) {
            //oRSOOrder.APTS_Invoice_Remark__c = oAgreement.APTS_Location__r.Billing_header_text__c;
            //if comments were added by user on page than keep them as it is else take from location
            oRSOOrder.APTS_Customer_Comments__c = oRSOOrder.APTS_Customer_Comments__c == null ? oAgreement.APTS_Location__r.Delivery_text__c : oRSOOrder.APTS_Customer_Comments__c ;
        }*/

        //get default Account Location
        if (locationId == NULL) {
            List<Apttus_Config2__AccountLocation__c> listDefLoc = [SELECT Id, Billing_header_text__c, Delivery_text__c FROM Apttus_Config2__AccountLocation__c WHERE Apttus_Config2__AccountId__c = : initialAccount.Id AND SAP_Customer_ID__c = : initialAccount.SAP_Customer_ID__c
                    AND Account_Location_Status__c = :ACCOUNT_STATUS AND Delivery_Block_Reason__c = NULL LIMIT 1];
            locId = listDefLoc.isEmpty() ? NULL : listDefLoc[0].Id;
            //oRSOOrder.APTS_Invoice_Remark__c = listDefLoc[0].Billing_header_text__c;
            //if comments were added by user on page than keep them as it is else take from location
            oRSOOrder.APTS_Customer_Comments__c = oRSOOrder.APTS_Customer_Comments__c == null && !listDefLoc.isEmpty() ? listDefLoc[0].Delivery_text__c : oRSOOrder.APTS_Customer_Comments__c;
        }

        if (initialAccount.Billing_header_text__c != null && initialAccount.Billing_header_text__c.length() > 255) {
            oRSOOrder.APTS_Invoice_Remark__c = initialAccount.Billing_header_text__c.left(255);
        } else {
            oRSOOrder.APTS_Invoice_Remark__c = initialAccount.Billing_header_text__c;
        }

        oRSOOrder.Apttus_Config2__LocationId__c = locId;
        oRSOOrder.Apttus_Config2__OrderStartDate__c = Date.today();
        oRSOOrder.Apttus_Config2__OrderEndDate__c = Date.today();
        oRSOOrder.Apttus_Config2__OrderDate__c = Date.today();
        oRSOOrder.APTS_Status__c = oRSOOrder.Apttus_Config2__Status__c;
        oRSOOrder.Apttus_Config2__PriceListId__c = oAgreement.Apttus_CMConfig__PriceListId__c;
        //Defect 4920 - don't copy contact from Agreement as Agreement can be Parent / Grand Parent Agreement
        //oRSOOrder.Apttus_Config2__PrimaryContactId__c = oAgreement.Apttus__Primary_Contact__c;

        if (oRSOOrder.Apttus_Config2__PrimaryContactId__c == NULL) {
            Map<Id, Contact> idToContactMap = new Map<Id, Contact>([SELECT Id, Name, Function__c, Main_Commercial_Person__c, Main_Service_Person__c FROM Contact WHERE AccountId = :oAccount.Id]);
            oRSOOrder.Apttus_Config2__PrimaryContactId__c = APTS_OrderUtils.getPrimaryContactId(idToContactMap, System.Label.APTS_Standard);
        }

        oRSOOrder.APTS_SAP_OrderType__c = APTS_RSOOrderUtils.getSAPOrderType(oRSOOrder);

        // <<++V106
        //oRSOOrder.APTS_Requested_Delivery_Date__c = (oRSOOrder.APTS_Fulfill_From_To_Van__c) ? Date.today() : APTS_OrderUtils.getRequestedDeliveryDate();
        //oRSOOrder.APTS_Requested_Delivery_Date__c = APTS_OrderUtils.checkRequestedDeliveryDateInWorkingHours(oRSOOrder, oRSOOrder.APTS_Requested_Delivery_Date__c);
        oRSOOrder.APTS_Requested_Delivery_Date__c = (oRSOOrder.APTS_Fulfill_From_To_Van__c) ? Date.today() : APTS_OrderUtils.checkRequestedDeliveryDateInWorkingHours(oRSOOrder, oRSOOrder.APTS_Requested_Delivery_Date__c);
        // V106++>>

        return oRSOOrder;
    }

    public Boolean addConsignmentProductsToCart(List<Apttus_CPQApi.CPQ.SelectedProductDO> listProdToAdd) {
        Boolean isSuccess = FALSE;

        Id cartId = APTS_OrderUtils.createCart(oRSOOrder.Id);
        if (String.isNotBlank(cartId)) {

            Apttus_CPQApi.CPQ.AddMultiProductResponseDO response = APTS_OrderUtils.addMultiProducts(listProdToAdd, cartId);

            if (response != null) {
                if (response.LineNumbers != NULL && !response.LineNumbers.isEmpty()) {
                    System.enqueueJob(new APTS_RepriceFinalizationQueue(cartId));
                }
            }
        }

        return isSuccess;
    }

    public Apttus_Config2__LineItem__c getLineItem(ConsignmentProductsWrapper oWrapper) {
        Apttus_Config2__LineItem__c oLineItem = new Apttus_Config2__LineItem__c();
        oLineItem.Apttus_Config2__StartDate__c = System.today();
        oLineItem.Apttus_Config2__EndDate__c = System.today();
        oLineItem.Apttus_Config2__Comments__c = 'RSO Order';
        oLineItem.Apttus_Config2__ProductId__c = oWrapper.contractedProd.ProductID;
        oLineItem.Apttus_Config2__SellingUom__c = getSellingUOM(oWrapper.contractedProd.UOM);

        return oLineItem;
    }

    public Apttus__APTS_Agreement__c getSelectedAgreement() {
        Apttus__APTS_Agreement__c oSelectedAg;

        for (AgreementWrapper oWrap : listAgWrapper) {

            if (oWrap.isSelected) {
                oSelectedAg = oWrap.oAgreement;
                break;
            }
        }

        return oSelectedAg;
    }

    public void stockCountData(Boolean overrideStockCountSel) {
        isStockCountVisible = FALSE;
        oAgreement = getSelectedAgreement();

        if (ORDERSUBTYPE_STOCKCOUNT.equalsIgnoreCase(oRSOOrder.APTS_Order_Sub_Type__c)) {

            isStockCountVisible = !listConsignmentProds.isEmpty() && oAgreement != null && oAgreement.RecordType != null && AGTYPE_CONSUMPTIONDEAL.equalsIgnoreCase(oAgreement.RecordType.Name) ? TRUE : FALSE;
            hasError = isStockCountVisible ? FALSE : TRUE;

            if (hasError) {

                String pgErrMsg = oAgreement != null && oAgreement.RecordType != null && AGTYPE_CONSUMPTIONDEAL.equalsIgnoreCase(oAgreement.RecordType.Name) ? PAGE_MSG_NO_CONSIGNMENT : PAGE_MSG_NO_STOCKCOUNT;
                ApexPages.Message oErrorMessage = new ApexPages.Message(ApexPages.Severity.ERROR, pgErrMsg);
                ApexPages.addMessage(oErrorMessage);

            }
        }

        //resets stock count selection
        if (overrideStockCountSel && !isStockCountVisible && listConsignmentProds != null && !listConsignmentProds.isEmpty()) {
            for (ConsignmentProductsWrapper oWrap : listConsignmentProds) {
                oWrap.isSelected = FALSE;
            }
        }
    }

    public static string getSellingUOM(string value) {
        string label = null;
        try {

            if (value != null) {

                for (PickListEntry pe : Apttus_Config2__LineItem__c.Apttus_Config2__SellingUom__c.getDescribe().getPicklistValues()) {
                    //check if value is picklist API, sent as it is
                    label = value.equalsIgnoreCase(pe.getValue()) ? value : null;
                    //check if value is picklist Label than set API
                    label = label == null && value.equalsIgnoreCase(pe.getLabel()) ? pe.getValue() : label;

                    if (label != null)                   
                    {
                        break;
                    }
                }

            }
        } catch (Exception ex) {
            throw ex;
        }
        return label;
    }

}