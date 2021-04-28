/*************************************************************
@Name: APTS_CreateReOrderController
@Author: MaheshSharan Velu
@CreateDate: 22-05-2019
@Description: Create Reorder from Account
@UsedBy: Create Reorder button on Account page
******************************************************************/
//v100 22-05-2019 MaheshSharan Velu: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes
//V100++  30-05-2019 Rajesh Patel: added code for Backend Order creating and adding product to cart based on  user selection.
//V101 14-Oct-2019 Aarthi Pitchai: QTCFLEX1-1451 Remove the logic to set customer comments and picking list text
//V102 05-Feb-2020 Aarthi Pitchai: DQ-1402 Add Freight charge product to reOrders
//v103 27-Aug-2020 Manisha  : DQ-3187 Added validation to select an Agreement if it exists
//v104 17-Sep-2020 Sneha :DQ-2456 Agreements with the end date in future, throwing warning message
//v105 23-Oct-2020 Sneha :DQ-3233 Restricting the blocked products 
//v106 22-Jan-2020 Aarthi :DQ-5095 Set the Default Selling UOM from Asset line item

public without sharing class APTS_CreateReOrderController {

    private Id accountId;
    private Id locId;
    private Account initialAccount;
    private Map<Id, Account> idToAccountMap;
    private Map<Id, Apttus__APTS_Agreement__c> idToAgreementMap;

    private Set<Id> accountSet ;
    private Boolean bOrdersLoaded;
    private Id cartId;
    private Apttus_Config2__Order__c oReturnOrder;

    private Set<String> availableProductSet;
    private Set<String> availableOrderNumberSet;
    private Set<String> availableOrderNumberInitialSet;
    private Map<Id, Decimal> assetIdForChangeToQuantityMap;
    private List<Id> assetIdForCancelList;
    private Map<Id, Apttus_Config2__LineItem__c> deInstalledLineItemMap;
    private Integer iInitialCountToDisplay;
    private Integer iCountToDisplay;
    private Set<String> setAgStatus = APTS_OrderConstants.STANDARD_ORDER_AG_STATUS;


    public Apttus_Config2__Order__c oOrder {get; set;}
    public List<AgreementWrapper> agreementWrapperList {get; set;}
    public List<Apttus_Config2__AssetLineItem__c> filterAssetLineItemToProductCode {get; set;}
    public Map<String, Apttus_Config2__AssetLineItem__c> productNameSetCheckDisplayMap;
    public Map<String, Apttus_Config2__AssetLineItem__c> productNameSetCheckDisplayMapAll;
    public Map<String, Apttus_Config2__AssetLineItem__c> productToALIMap; //V106 ++ <<>>

    public List<ProductWrapper> productWrapperList {get; set;}
    public Map<String, String> productCode;
    public String sProductName {get; set;}
    public String sProductCode {get; set;}
    public String sAllProductsByName {get; set;}
    public String sAllProductsByCode {get; set;}
    public Boolean bShowProducts  {get; set;}
    public Boolean bDisableProductName {get; set;}
    public Boolean bDisableProductCode {get; set;}
    public Boolean bCreateOrder {get; set;}
    public Boolean bShowNoProducts {get; set;}

    public Map<String, String> productDetails;
    public Map<String, String> productDetailsDisplay;
    public Map<String, String> productCodeAndNameSync;
    public Integer displayMoreProductsByFive;
    public Integer displayMoreProductsByFiveTemp;
    public Set<String> productNameSetCheck;
    public Set<String> productFamily;
    public Set<String> productNameSetCheckDisplay;
    public List<Apttus_Config2__AssetLineItem__c> addProductCodeOnSearchByName;
    public Integer iRemainProduct;
    public Boolean bRemainProduct;
    public Integer iMoreProducts;
    public Integer iCount;
    public Integer iTotalRecords;
    public Integer iInitialProducts;
    public Integer iLoadLess;
    public Boolean bErrorOccurred {get; set;}

    public Boolean bShowAgreements {get; set;}
    public Boolean bShowOrders {get; set;}


    public String sOrderNumber {get; set;}
    public String dtOrderStartDate {get; set;}

    public String sAllProducts {get; set;}
    public String sAllOrderNumbers {get; set;}

    public Boolean bDisableMore {get; set;}
    public Boolean bDisableLess {get; set;}

    public Boolean bShowCreate {get; set;}
    public Boolean bReturnOrder {get; set;}
    public Boolean bFirstClickOnAgreement {get; set;}

    //V100++ ++<<
    private static final String URL1 = '/apex/Apttus_Config2__OrderConfiguration?id=';
    private static final String URL2 = '&flow=';
    private static final String URL3 = '&launchState=cart';
    private static final String NGRSO_ORDERWOC = 'NGStandardOrder';
    //V100++ ++>>

    //V102++ <<
    private static final String FREIGHT_CHARGE = System.Label.APTS_FREIGHT_CHARGE;
    //V102++ >>

    public APTS_CreateReOrderController() {

        accountId = ApexPages.currentPage().getParameters().get(APTS_OrderConstants.ID);
        locId = ApexPages.currentPage().getParameters().get(APTS_OrderConstants.LOCID);

        bShowAgreements = true;

        bFirstClickOnAgreement = true;
        bOrdersLoaded = false;
        bShowOrders = false;
        sProductName = null;
        sProductCode = null;
        sOrderNumber = null;
        bDisableMore = true;
        bDisableLess = true;
        bShowCreate = true;
        bReturnOrder = false;
        bShowProducts = true;
        bShowOrders = true;
        bDisableProductName = true;
        bDisableProductCode = true;
        bCreateOrder = true;
        bShowNoProducts = true;

        iRemainProduct = 0;
        iMoreProducts = 5;
        iCount = 0;
        iTotalRecords = 0;
        iInitialProducts = 7;
        displayMoreProductsByFive = 7;
        displayMoreProductsByFiveTemp = 0;
        bRemainProduct = false;
        iLoadLess = 0;
        productFamily = new Set<String> {'SAP_01', 'SAP_02', 'SAP_03'};



        agreementWrapperList = new List<AgreementWrapper>();
        idToAccountMap = new Map<Id, Account>();

        accountSet = new Set<Id> ();
        //loadProducts();
        //V100++ ++<<
        oOrder = new Apttus_Config2__Order__c();
        oOrder.APTS_Order_Type__c = APTS_OrderConstants.STANDARD_ORDER;

        oOrder.Apttus_Config2__Source__c = APTS_OrderConstants.ACCOUNT;
        oOrder = APTS_OrderUtils.setOrderHeaderMandatoryFields(oOrder, APTS_OrderConstants.STANDARD);

        Map<Id, Contact> idToContactMap = APTS_OrderUtils.getAllContacts(accountId);
        oOrder.Apttus_Config2__PrimaryContactId__c = APTS_OrderUtils.getPrimaryContactId(idToContactMap, APTS_OrderConstants.STANDARD);
        //V100++ ++>>
    }

    public void doSOQLS() {

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

            accountSet.add(initialAccount.Id);
            if (initialAccount.ParentId != null) {accountSet.add(initialAccount.ParentId);}
            if (initialAccount.Parent.Parent.Id != null) {accountSet.add(initialAccount.Parent.Parent.Id);}

        } else {

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

                        APTS_Check_on_Account_Ingredients__c,APTS_Check_on_Account_Machines__c,
                        Apttus__Account__c,

                        APTS_Location__r.Billing_header_text__c,
                        APTS_Location__r.Delivery_text__c,

                        APTS_Location__r.Picking_list_text__c

                        FROM Apttus__APTS_Agreement__c

                        WHERE Apttus__Account__c IN :accountSet AND Apttus__Status_Category__c = :APTS_OrderConstants.IN_EFFECT
                                AND Apttus__Status__c IN :setAgStatus]);


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
            //v104
            if((sortCriteriaToAgreementMap.isEmpty() && sortCriteriaToAgreementMap.size() ==0) &&(!idToAgreementMap.isEmpty() && idToAgreementMap.size() >=1) ){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, '<font color="black">'+APTS_OrderConstants.Past_EndDate+'</font>'));
            }
            //v104

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

            if (agreementWrapperList.size() >= 1) {
                agreementWrapperList[0].selected = true;
            }
        }

        bFirstClickOnAgreement = false;
    }

    public void loadProducts() {
        try {
            if (bShowProducts) {

                productCode = new Map<String, String>();
                productDetails = new Map<String, String>();
                productDetailsDisplay = new Map<String, String>();
                productCodeAndNameSync = new Map<String, String>();
                productWrapperList = new List<ProductWrapper>();
                productNameSetCheck = new Set<String>();
                productNameSetCheckDisplay = new Set<String>();
                productNameSetCheckDisplayMap = new Map<String, Apttus_Config2__AssetLineItem__c>();
                productNameSetCheckDisplayMapAll = new Map<String, Apttus_Config2__AssetLineItem__c>();
                productToALIMap = new Map<String, Apttus_Config2__AssetLineItem__c>();
                bDisableMore = false;
                bDisableProductName = false;
                bDisableProductCode = false;
                bCreateOrder = false;
                bShowCreate = true;

                //V106 ++ << Added Selling UOM field to the below query >>
                List<Apttus_Config2__AssetLineItem__c> assetLineItemToProductCode = [SELECT Id, Apttus_Config2__SellingUom__c, 
                                                       Apttus_Config2__ProductId__r.Name,
                                                       Apttus_Config2__ProductId__r.ProductCode
                                                       FROM Apttus_Config2__AssetLineItem__c
                                                       WHERE Apttus_Config2__AccountId__c IN :accountSet
                                                       AND Apttus_Config2__AssetStatus__c = 'Activated'
                                                               AND Apttus_Config2__BasePrice__c != null
                                                               AND Apttus_Config2__BasePrice__c != 0
                                                               AND Apttus_Config2__ProductId__r.APTS_Not_relevant_for_SAP__c = false
                                                               //v105++<<
                                                               AND Apttus_Config2__ProductId__r.APTS_Associated_Sales_Org__c includes(:[Select Id, Sales_Organization__c from Account where Id =: accountSet LIMIT 1].Sales_Organization__c)
                                                               //v105++>>
                                                               AND Apttus_Config2__ProductId__r.Family IN :productFamily
                                                               ];


                for (Apttus_Config2__AssetLineItem__c assetLI : assetLineItemToProductCode) {

                    productCode.put(assetLI.Apttus_Config2__ProductId__r.ProductCode, assetLI.ID);
                    productDetails.put(assetLI.Apttus_Config2__ProductId__r.ProductCode, assetLI.Apttus_Config2__ProductId__r.Name);
                    productNameSetCheck.add(assetLI.Apttus_Config2__ProductId__r.Name.replaceAll( '\\s+', ''));
                    //V106 ++ <<
                    if(productToALIMap.isEmpty())
                        productToALIMap.put(assetLI.Apttus_Config2__ProductId__c, assetLI);
                    else if(!productToALIMap.KeySet().contains(assetLI.Apttus_Config2__ProductId__c))
                        productToALIMap.put(assetLI.Apttus_Config2__ProductId__c, assetLI);
                    //V106 ++ >>
                }

                filterAssetLineItemToProductCode = [SELECT Id,
                                                    Apttus_Config2__ProductId__r.Name,
                                                    Apttus_Config2__ProductId__r.ProductCode,
                                                    Apttus_Config2__Quantity__c,
                                                    Apttus_Config2__NetPrice__c,
                                                    toLabel(Apttus_Config2__SellingUom__c)
                                                    FROM Apttus_Config2__AssetLineItem__c
                                                    WHERE Id In :productCode.values()
                                                    AND Apttus_Config2__AssetStatus__c = 'Activated'
                                                            ORDER BY CreatedDate DESC ];

                iTotalRecords = filterAssetLineItemToProductCode.size();


                for (Integer i = 0; i < filterAssetLineItemToProductCode.size(); i++) {
                    productNameSetCheckDisplayMapAll.put(filterAssetLineItemToProductCode[i].Apttus_Config2__ProductId__r.Name.replaceAll( '\\s+', ''), filterAssetLineItemToProductCode[i]);
                    productCodeAndNameSync.put(filterAssetLineItemToProductCode[i].Apttus_Config2__ProductId__r.Name.replaceAll( '\\s+', ''), filterAssetLineItemToProductCode[i].Apttus_Config2__ProductId__r.ProductCode);

                }

                if (filterAssetLineItemToProductCode.size() < displayMoreProductsByFive) {
                    for (Integer i = 0; i < filterAssetLineItemToProductCode.size(); i++) {
                        ProductWrapper productwrapper = new ProductWrapper(false, filterAssetLineItemToProductCode[i], 0);
                        productWrapperList.add(productwrapper);
                        productDetailsDisplay.put(filterAssetLineItemToProductCode[i].Apttus_Config2__ProductId__r.ProductCode, filterAssetLineItemToProductCode[i].Apttus_Config2__ProductId__r.Name);
                        productNameSetCheckDisplay.add(filterAssetLineItemToProductCode[i].Apttus_Config2__ProductId__r.Name.replaceAll( '\\s+', ''));
                        productNameSetCheckDisplayMap.put(filterAssetLineItemToProductCode[i].Apttus_Config2__ProductId__r.Name.replaceAll( '\\s+', ''), filterAssetLineItemToProductCode[i]);
                        iRemainProduct = iTotalRecords - 1;
                        bDisableMore = true;
                    }
                } else {
                    for (Integer i = 0; i < displayMoreProductsByFive; i++) {
                        ProductWrapper productwrapper = new ProductWrapper(false, filterAssetLineItemToProductCode[i], 0);
                        productWrapperList.add(productwrapper);
                        //productDetails.clear();
                        productDetailsDisplay.put(filterAssetLineItemToProductCode[i].Apttus_Config2__ProductId__r.ProductCode, filterAssetLineItemToProductCode[i].Apttus_Config2__ProductId__r.Name);
                        productNameSetCheckDisplay.add(filterAssetLineItemToProductCode[i].Apttus_Config2__ProductId__r.Name.replaceAll( '\\s+', ''));
                        productNameSetCheckDisplayMap.put(filterAssetLineItemToProductCode[i].Apttus_Config2__ProductId__r.Name.replaceAll( '\\s+', ''), filterAssetLineItemToProductCode[i]);
                        iRemainProduct = iTotalRecords - 1;
                    }
                }

            }

            if (filterAssetLineItemToProductCode.isEmpty()) {
                bDisableMore = true;
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, 'There are no products to reorder in this account.'));
            }
            bShowProducts = false;
        } catch (Exception ex) {raiseError(ex, 'Whoops!. Looks like something went wrong' + ex.getStackTraceString());}
    }

    public void callTwoMethods() {

        doSOQLS();

        loadProducts();
    }

    public void addProductsOnSearch() {
        try {

            Integer iIndexRemove = 0;
            Integer iIndexSize = 0;
            if (!String.isBlank(sProductCode) && (!productDetailsDisplay.containsKey(sProductCode)) && (!sProductCode.equalsIgnoreCase('No Results Found'))) {
                List<Apttus_Config2__AssetLineItem__c> addProductCodeOnSearch = [SELECT Id,
                                                       Apttus_Config2__ProductId__r.Name,
                                                       Apttus_Config2__ProductId__r.ProductCode,
                                                       Apttus_Config2__Quantity__c,
                                                       Apttus_Config2__NetPrice__c,
                                                       toLabel(Apttus_Config2__SellingUom__c)
                                                       FROM Apttus_Config2__AssetLineItem__c
                                                       WHERE Apttus_Config2__AccountId__c IN :accountSet
                                                       AND Apttus_Config2__ProductId__r.ProductCode = : sProductCode
                                                               AND Apttus_Config2__AssetStatus__c = 'Activated'
                                                                       ORDER BY CreatedDate DESC ];

                ProductWrapper productwrapper = new ProductWrapper(false, addProductCodeOnSearch[0], 0);
                productWrapperList.add(productwrapper);
                productDetailsDisplay.put(addProductCodeOnSearch[0].Apttus_Config2__ProductId__r.ProductCode, addProductCodeOnSearch[0].Apttus_Config2__ProductId__r.Name);
                productNameSetCheckDisplayMap.put(addProductCodeOnSearch[0].Apttus_Config2__ProductId__r.Name.replaceAll( '\\s+', ''), addProductCodeOnSearch[0]);
                for (Apttus_Config2__AssetLineItem__c oProductRemove : filterAssetLineItemToProductCode) {


                    if (oProductRemove.Apttus_Config2__ProductId__r.ProductCode == sProductCode) {
                        iIndexRemove = iIndexSize;
                    }

                    iIndexSize++;
                }
                filterAssetLineItemToProductCode.remove(iIndexRemove);
                iTotalRecords = filterAssetLineItemToProductCode.size() + 1;
                iRemainProduct = iTotalRecords - productWrapperList.size();
                bDisableMore = (iRemainProduct == 0) ? true : false;

            } else if (sProductCode.equalsIgnoreCase('No Results Found')) {
                errorMessageForNoProducts(sProductCode);
            }

            else {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, 'The Product you have selected is already in the product list'));
            }
        } catch (Exception ex) {raiseError(ex, 'Whoops!. Looks like something went wrong' + ex.getStackTraceString());}
    }

    public void addProductsOnSearchByName() {
        try {
            loadProducts();
            Integer iIndexRemove = 0;
            Integer iIndexSize = 0;
            String sProductNamewoSpacess = sProductName.replaceAll( '\\s+', '');
            addProductCodeOnSearchByName = new List<Apttus_Config2__AssetLineItem__c>();

            if (!String.isBlank(sProductNamewoSpacess) && (!productNameSetCheckDisplayMap.containsKey(sProductNamewoSpacess)) && (!sProductNamewoSpacess.equalsIgnoreCase('NoResultsFound'))) {

                Apttus_Config2__AssetLineItem__c addToProductMap = new Apttus_Config2__AssetLineItem__c();
                addToProductMap = productNameSetCheckDisplayMapAll.get(sProductNamewoSpacess);
                addProductCodeOnSearchByName.add(addToProductMap);

                ProductWrapper productwrapper = new ProductWrapper(false, addProductCodeOnSearchByName[0], 0);
                productWrapperList.add(productwrapper);
                productNameSetCheckDisplay.add(sProductNamewoSpacess);
                productNameSetCheckDisplayMap.put(sProductNamewoSpacess, addToProductMap);
                productDetailsDisplay.put(productCodeAndNameSync.get(sProductNamewoSpacess), sProductNamewoSpacess);


                for (Apttus_Config2__AssetLineItem__c oProductRemove : filterAssetLineItemToProductCode) {


                    if ((oProductRemove.Apttus_Config2__ProductId__r.Name).replaceAll( '\\s+', '') == sProductNamewoSpacess) {
                        iIndexRemove = iIndexSize;
                    }

                    iIndexSize++;
                }
                filterAssetLineItemToProductCode.remove(iIndexRemove);
                iTotalRecords = filterAssetLineItemToProductCode.size() + 1;
                iRemainProduct = iTotalRecords - productWrapperList.size();
                bDisableMore = (iRemainProduct == 0) ? true : false;
            } else if (sProductNamewoSpacess.equalsIgnoreCase('NoResultsFound')) {
                errorMessageForNoProducts(sProductCode);
            } else {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, 'The Product you have selected is already in the product list'));
            }
        } catch (Exception ex) {raiseError(ex, 'Whoops!. Looks like something went wrong' + ex.getStackTraceString());}
    }
    //V100++ ++<<
    public void createOrder() {
        if(validate()){
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
            if (oSelectedAgreement == null) {
                APTS_DefaultPriceList oDefaultPriceList = new APTS_DefaultPriceList();
                oOrder.Apttus_Config2__PriceListId__c = oDefaultPriceList.getDefaultPriceListId(initialAccount);
            }

            oOrder.APTS_Requested_Delivery_Date__c = APTS_OrderUtils.checkRequestedDeliveryDateInWorkingHours(oOrder, system.today());
            oOrder.APTS_Order_Sub_Type__c = APTS_OrderConstants.STANDARD_ORDER;
            oOrder.APTS_Source_of_Order_Creation__c = APTS_OrderConstants.REORDER;

            Database.insert(oOrder);
            bErrorOccurred = false;
        }
         catch (Exception e) {
            raiseError(e, 'Error in creation of order!' + e.getStackTraceString());
        }
      }else {
            bErrorOccurred = true;
        }
    }

    public PageReference goToOrder() {

        PageReference pageRef = null;

        try {
            if (!bErrorOccurred) {
                createCartAddProdcts(oOrder.id);
                pageRef  = new PageReference(URL1 + oOrder.Id + URL2 + NGRSO_ORDERWOC + URL3);
            }
        } catch (Exception e) {  ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, APTS_OrderConstants.ERROR_WHILE_REDIRECT_TO_CART));  }

        return pageRef;
    }
    //v103++<< Added validation to select an Agreement if it exists
     private Boolean validate() {

        Boolean bResult = true;

        
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

            if (iSelectedCount == 0 && !agreementWrapperList.isEmpty() ) { //V105
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, APTS_OrderConstants.SELECT_AN_AGREEMENT));
                bResult = false;
            }
        }
     return bResult;
     }
    //v103++>>
    public void createCartAddProdcts(ID orderId) {
        Apttus_Config2__ProductConfiguration__c cartObj = null;
        try {
            if (orderId != null) {
                Id cartId = APTS_OrderUtils.createCart(orderId);
                if (cartId != null) {

                    APTS_AdjustmentLineItemCallback.setIsDisabled(true);
                    addProductsViaAPI(oOrder.id, cartId);
                    
                    APTS_AdjustmentLineItemCallback.setIsDisabled(false);
                     Boolean reprice = APTS_OrderUtils.repriceCart(cartId);
                    APTS_CERUtility.applyBPO(cartId,false); 
                     reprice = APTS_OrderUtils.repriceCart(cartId);
                    cartObj = APTS_OrderUtils.saveCart(cartId);
                } else {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, APTS_OrderConstants.ERROR_IN_CART));   bErrorOccurred = true;
                }
            }
        }  catch (Exception e) { raiseError(e, 'Error in creation of order!' + e.getStackTraceString()); }
        update cartObj;

    }

    private  List<Decimal> addProductsViaAPI(Id orderId, Id cartId) {
        List<Decimal> listLineNumbers;
        List<Apttus_CPQApi.CPQ.SelectedProductDO> listStandaloneProduct = getProducts(cartId);

        if (!listStandaloneProduct.isEmpty()) {
            try {
                Apttus_CPQApi.CPQ.AddMultiProductResponseDO response = APTS_OrderUtils.addMultiProducts(listStandaloneProduct, cartId);
                listLineNumbers = response.LineNumbers != NULL && !response.LineNumbers.isEmpty() ?  response.LineNumbers : listLineNumbers;
            } catch (Exception ex) {

            }
        }

        return listLineNumbers;
    }


    private  List<Apttus_CPQApi.CPQ.SelectedProductDO> getProducts(Id cartId) {
        Apttus_CPQApi.CPQ.SelectedProductDO sProd = NULL;
        List<Apttus_CPQApi.CPQ.SelectedProductDO> listStandaloneProduct = new List<Apttus_CPQApi.CPQ.SelectedProductDO>();

        for (ProductWrapper oProductWrapper : productWrapperList) {
            if (oProductWrapper.editableQuantity > 0 && oProductWrapper.selected ) {
                Apttus_Config2__AssetLineItem__c oALI = productToALIMap.get(oProductWrapper.oProduct.Apttus_Config2__ProductId__c); //V106 ++ <<>>
                Apttus_Config2__LineItem__c oLI = getLineItemWrapper(oProductWrapper.oProduct.Apttus_Config2__ProductId__c, oProductWrapper.editableQuantity);
                oLI.Apttus_Config2__SellingUom__c = oALI.Apttus_Config2__SellingUom__c; //V106 ++ <<>>
                sProd = APTS_OrderUtils.addStandaloneProductWithQuantity(oLI, Integer.valueOf(oProductWrapper.editableQuantity));
                if (sProd != NULL) {
                    listStandaloneProduct.add(sProd);
                }
            }
        }
        //V102 ++ <<
        system.debug('cartId :: '+cartId);
        boolean bfreeFreightCharge = APTS_OrderUtils.checkfreefreight(cartId);
        system.debug('bfreeFreightCharge :: '+bfreeFreightCharge);
        if(!bfreeFreightCharge)
        {
            Product2 freightProduct = [select id from Product2 where ProductCode =: FREIGHT_CHARGE and IsActive = true LIMIT 1];
            Apttus_Config2__LineItem__c oLI = getLineItemWrapper(freightProduct.Id, 1);
            sProd = APTS_OrderUtils.addStandaloneProductWithQuantity(oLI, 1);
            if (sProd != NULL) {
                    listStandaloneProduct.add(sProd);
                }
        }
        return listStandaloneProduct;
    }


    private  Apttus_Config2__LineItem__c getLineItemWrapper(Id productId, Decimal pQuantity) {


        Apttus_Config2__LineItem__c oLineItem = new Apttus_Config2__LineItem__c();
        try {
            oLineItem.Apttus_Config2__StartDate__c = System.today();
            oLineItem.Apttus_Config2__EndDate__c = System.today();
            String oProductId = productId != null ? productId : null;
            oLineItem.Apttus_Config2__ProductId__c = oProductId;
            Decimal proQuantity = pQuantity != null ? pQuantity : 1;
            oLineItem.Apttus_Config2__Quantity__c = proQuantity;
        } catch (Exception e) { raiseError(e, 'Whoops!. Looks like something went wrong while creating Line item' + e.getStackTraceString());}
            return oLineItem;
        }

        //V100++ ++>>
        public void searchProductsByName() {
            try {
                sAllProductsByName = '[';

                String searchStr = ApexPages.currentPage().getParameters().get(APTS_OrderConstants.FIRST_PARAM);

                Set<String> filteredProductNameSet = new Set<String>();

                for (String sProductName : productDetails.values()) {
                    if (sProductName.containsIgnoreCase(searchStr)) {
                        filteredProductNameSet.add(sProductName);
                    }
                }

                if (!filteredProductNameSet.isEmpty()) {
                    Integer count = filteredProductNameSet.size();
                    Integer iId = 0;
                    for (String sProductName : filteredProductNameSet) {

                        sAllProductsByName += '{\'label\':\'' + sProductName + '\',\'value\':\'' + iId +  '\'}';
                        if (--count != 0) {
                            sAllProductsByName += ',';
                        }
                        iId++;
                    }
                }
                if ((searchStr != null) && filteredProductNameSet.isEmpty()) {
                    if (searchStr.equalsIgnoreCase('No Results Found')) {
                        errorMessageForNoProducts(searchStr);
                    } else {
                        sAllProductsByName = '[{\'label\':\'' + 'No Results Found' + '\',\'value\':\'' + '0'  +  '\'}';
                    }
                }

                sAllProductsByName += ']';

            } catch (Exception ex) {raiseError(ex, 'Whoops!. Looks like something went wrong' + ex.getStackTraceString());}
        }

        public void searchProductsByCode() {
            try {
                sAllProductsByCode = '[';

                String searchStr = ApexPages.currentPage().getParameters().get(APTS_OrderConstants.FIRST_PARAM);

                Set<String> filteredProductCodeSet = new Set<String>();

                for (String sProductCode : productDetails.keyset()) {
                    if (sProductCode.containsIgnoreCase(searchStr)) {
                        filteredProductCodeSet.add(sProductCode);
                    }

                }

                if (!filteredProductCodeSet.isEmpty()) {
                    Integer count = filteredProductCodeSet.size();
                    Integer iId = 0;
                    for (String sProductCode : filteredProductCodeSet) {

                        sAllProductsByCode += '{\'label\':\'' + sProductCode + '\',\'value\':\'' + iId +  '\'}';
                        if (--count != 0) {
                            sAllProductsByCode += ',';
                        }
                        iId++;
                    }
                }

                if ((searchStr != null) && filteredProductCodeSet.isEmpty()) {
                    if (searchStr.equalsIgnoreCase('No Results Found')) {
                        errorMessageForNoProducts(searchStr);
                    } else {
                        sAllProductsByCode = '[{\'label\':\'' + 'No Results Found' + '\',\'value\':\'' + '0'  +  '\'}';
                    }
                }

                sAllProductsByCode += ']';

            } catch (Exception ex) {raiseError(ex, 'Whoops!. Looks like something went wrong' + ex.getStackTraceString());}
        }


        public void errorMessageForNoProducts(String searchString) {

            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, 'Whoops!!. The Product you have selected is not available for Reorder.'));

        }


        public void resetOrderSearch() {

            sProductName = null;
            sProductCode = null;
        }

        public void loadMore() {
            try {
                if (iRemainProduct > 0 ) {
                    bDisableLess = false;
                    iMoreProducts = 5 ;
                    iRemainProduct = iTotalRecords - productWrapperList.size();
                    if (iMoreProducts >= iRemainProduct) {
                        iCount = iRemainProduct;
                    } else {
                        iCount = iMoreProducts;
                    }
                    for (Integer iIndex = 0; iIndex < iCount; iIndex++) {
                        ProductWrapper productwrapper = new ProductWrapper(false, filterAssetLineItemToProductCode[iIndex + iInitialProducts], 0);
                        productWrapperList.add(productwrapper);
                        iRemainProduct = iRemainProduct - 1;
                        iLoadLess = iCount ;

                    }
                } else {
                    bDisableMore = true;
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, 'Look\'s like you have reached the end of the product list to reorder'));
                }
            } catch (Exception ex) {raiseError(ex, 'Whoops!. Looks like something went wrong' + ex.getStackTraceString());}
        }

        public void loadLess() {
            try {
                Integer iTemp = 0 ;
                if (iLoadLess > 0 ) {
                    bDisableMore = false;
                    if ((iLoadLess - iInitialProducts) <= iInitialProducts) {
                        iCount = iLoadLess;
                        bDisableLess = true;
                    } else {
                        iCount = iInitialProducts;
                    }
                    iTemp = iCount;
                    for (Integer iIndex = iTemp; iIndex > 0; --iIndex) {
                        productWrapperList.remove(productWrapperList.size() - 1);


                        iLoadLess = iLoadLess - 1;
                        iRemainProduct = iRemainProduct + 1;
                    }
                } else {
                    bDisableLess = true;
                    bDisableMore = false;

                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, 'Look\'s like you have reached the end of the product list to reorder'));
                }
            } catch (Exception ex) {raiseError(ex, 'Whoops!. Looks like something went wrong' + ex.getStackTraceString());}

        }

        /*public void selectAll() {

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
        }*/

        public PageReference back() {

            PageReference pageRef;

            pageRef = new PageReference('/' + accountId);

            return pageRef;
        }

        private void raiseError(Exception ex, String sMessage) {

            APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString() + ':: ' + ex.getMessage(), 'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id), 'OM', false, true, null, true);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, sMessage + ex.getStackTraceString()));
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

        public without sharing class ProductWrapper {

            public Boolean selected {get; set;}
            public Apttus_Config2__AssetLineItem__c oProduct {get; set;}
            public Integer editableQuantity {get; set;}

            public ProductWrapper() {

                this.selected = false;
                this.oProduct = null;
                this.editableQuantity = 0;
            }

            public ProductWrapper(Boolean selected, Apttus_Config2__AssetLineItem__c oProduct, Integer editableQuantity) {

                this.selected = selected;
                this.oProduct = oProduct;
                this.editableQuantity = editableQuantity;

            }
        }    


    }