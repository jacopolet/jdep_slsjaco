/*************************************************************
@Name: APTS_DigitalOrderUtils
@Author: Neev Shah
@CreateDate: 3-04-2018
@Description: A class who have common methods for Digital Order
******************************************************************/
//v101 10-Dec-2018 : Neev Shah : Cleaned up utils class as few methods moved to APTS_DigitalOrderHelper
//v102 29-Mar-2019 : Neev Shah : 6353 - Account Parent Hierarchy to set Agreement on Order Header
//v103 11-Oct-2019 : Aarthi : QTCFLEX1-1542 - Digital order Type field mapping on Order Header
//v104 20-Jan-2020 : Renuka : DQ-48 - Added Null check to avoid overriding of Agreement from Parent and GP Account

public without sharing class APTS_DigitalOrderUtils {
    private static final String STR_DIGITAL = 'Digital';
    private static final String STR_JSON_INVALID = 'JSON cannot be NULL';
    private static final String STR_SOURCE_INVALID = 'Source cannot be blank. \n';
    private static final String STR_SOURCE_NUM_INVALID = 'SourceOrderNumber cannot be blank. \n';
    private static final String STR_ACC_INVALID = 'SalesforceAccountID cannot be blank. For OneTime customer please send dummy account. \n';
    private static final String STR_SALES_ORG_INVALID = 'SalesOrganization cannot be blank. \n';
    private static final String STR_SOURCE_LI_NUM_INVALID = 'SourceLineNumber cannot be blank. \n';
    private static final String STR_PROD_COD_INVALID = 'ProductCode cannot be blank. \n';
    private static final String STR_QTY_INVALID = 'Quantity cannot be NULL or negative.  \n';
    private static final String STR_UOM_INVALID = 'SellingUnitofMeasure cannot be blank. \n';
    private static final String STR_CONF_TYPE_INVALID = 'ConfigurationType cannot be blank. \n';
    private static final String STR_YES = 'Yes';
    private static final String STR_NO = 'No';
    private static final String STR_STANDARD = System.Label.APTS_Standard;
    private final static Set<String> setAgStatus = APTS_OrderConstants.STANDARD_ORDER_AG_STATUS;


    /** Method : validateData
        ** Description : method would validateData received from EPI Server
        ** Input : APTS_DOEPIReqWrapper
        ** Output : String sErrMsg, error message if data is not valid
        **/
    public static String validateData(APTS_DOEPIReqWrapper objWrapper) {
        String sErrMsg = objWrapper == null ? STR_JSON_INVALID : null;

        if (String.isNotBlank(sErrMsg)) {
            return sErrMsg;
        }

        sErrMsg = String.isBlank(objWrapper.Source) ? STR_SOURCE_INVALID : '';

        if (STR_DIGITAL.equalsIgnoreCase(objWrapper.Source)) {
            sErrMsg = String.isBlank(objWrapper.SourceOrderNumber) ? STR_SOURCE_NUM_INVALID : sErrMsg;
            sErrMsg = String.isBlank(objWrapper.SalesforceAccountID) ? sErrMsg + STR_ACC_INVALID : sErrMsg;
            sErrMsg = String.isBlank(objWrapper.SalesOrganization) ? sErrMsg + STR_SALES_ORG_INVALID : sErrMsg;

            for (APTS_DOEPIReqWrapper.EPIOrderLI oEPILI : objWrapper.OrderLineItems) {

                sErrMsg = String.isBlank(oEPILI.SourceLineNumber) ? sErrMsg + STR_SOURCE_LI_NUM_INVALID : sErrMsg;
                sErrMsg = String.isBlank(oEPILI.ProductCode) ? sErrMsg +  STR_PROD_COD_INVALID : sErrMsg;
                sErrMsg = oEPILI.Quantity == NULL || oEPILI.Quantity < 1 ? sErrMsg + STR_QTY_INVALID : sErrMsg;
                sErrMsg = String.isBlank(oEPILI.SellingUnitofMeasure) ?  sErrMsg + STR_UOM_INVALID : sErrMsg;
                sErrMsg = String.isBlank(oEPILI.ConfigurationType) ? sErrMsg + STR_CONF_TYPE_INVALID : sErrMsg;
            }
        }

        return sErrMsg;
    }

    /** Method : getAccounts
        ** Description : method would return Accounts and its related data
        ** Input : Set<Id>
        ** Output : Map of <AccountId, Account>
        **/
    public static Map<Id, Account> getAccounts(Set<Id> setSoldToId) {
        Map<Id, Account> mapAccount = new Map<Id, Account>([SELECT Id, Name, SAP_Customer_ID__c, ParentId, Parent.ParentId, Sales_Organization__c,
                Partner__c, Division__c, Distribution_Channel__c, APTS_Payment_Method__c, APTS_Price_List__c,
                Apttus_Config2__BillingPreferenceId__c, Apttus_Config2__PaymentTermId__c, Language__c, Bill_To_Payer_Account__c,
                Related_Payer_Account__c, Related_Payer_Machines_Services__c, Billing_header_text__c
                FROM Account WHERE Id IN :setSoldToId]);

        return mapAccount;
    }

    /** Method : getProductCodes
        ** Description : method would return products and its related data
        ** Input : Set<String>
        ** Output : Map of <String ProductCode, Product2>
        **/
    public static Map<String, Product2> getProductCodes(Set<String> setProductCode) {
        Map<String, Product2> mapProductCodes = new Map<String, Product2>();
        for (Product2 oProd :  [SELECT id, ProductCode FROM product2 WHERE ProductCode = :setProductCode]) {
            mapProductCodes.put(oProd.ProductCode, oProd);
        }

        return mapProductCodes;
    }

    /** Method : getContacts
        ** Description : method would return contacts and its related data
        ** Input : Set<Id>
        ** Output : Map of <AccountId, Contact>
        **/
    public static Map<Id, Contact> getContacts(Set<Id> setSoldToId) {
        Map<Id, Contact> mapContancts = new Map<Id, Contact>();
        for (Contact oContact : [SELECT Id, AccountId FROM Contact WHERE AccountId IN :setSoldToId ]) {
            mapContancts.put(oContact.AccountId, oContact);
        }

        return mapContancts;
    }

    /** Method : getDefaultPaymentTerm
        ** Description : method would return Payment term with ZOLP type
        ** Input : NA
        ** Output : Apttus_Config2__PaymentTerm__c or null
        **/
    public static Apttus_Config2__PaymentTerm__c getDefaultPaymentTerm() {
        Apttus_Config2__PaymentTerm__c oPrepaidPT;

        try {
            List<Apttus_Config2__PaymentTerm__c> listPrepaidPT = [Select id from Apttus_Config2__PaymentTerm__c where APTS_Ext_ID__c = :APTS_OrderConstants.ZOLP LIMIT 1];
            oPrepaidPT = !listPrepaidPT.isEmpty() ? listPrepaidPT[0] : null;
        } catch (Exception ex) {
            throw ex;
        }

        return oPrepaidPT;
    }

    /*****
    *** getDigitalAgreements
    *** Parameters :
    *** 1. AccountHierarchyWrapper : Ids of Parent and Grand Parent
    *** Description : returns contributing Agreement in Account Hierarchy which qualifies for Accounts
    ***/
    public static Map<Id, Apttus__APTS_Agreement__c> getDigitalAgreements(Set<Id> setAccountToVisitId, Set<Id> setAllAccountId, Map<Id, Id> mapParentId, Map<Id, Id> mapGrandParentId) {
        Map<Id, Apttus__APTS_Agreement__c> mapContributingAgrs = new Map<Id, Apttus__APTS_Agreement__c>();

        try {

            if (setAccountToVisitId == null || setAccountToVisitId.isEmpty()) {
                return null;
            }

            Map<Id, Apttus__APTS_Agreement__c> mapAgreementsTmp = new Map<Id, Apttus__APTS_Agreement__c> ();

            for (Apttus__APTS_Agreement__c agTmp : [SELECT Id, RecordTypeId, Apttus__Account__c, APTS_Order_Non_Contracted_Products__c, RecordType.Name,
                                                    Name,  APTS_Location__c, Apttus_CMConfig__PriceListId__c,
                                                    Apttus_CMConfig__PONumber__c, Apttus_CMConfig__BillingPreferenceId__c, Apttus_CMConfig__PaymentTermId__c,
                                                    Apttus__Status_Category__c, Apttus__Status__c, Apttus__Contract_Start_Date__c, Apttus__Contract_End_Date__c,
                                                    Apttus__Primary_Contact__c, APTS_Language__c, APTS_Bill_to_Party_Ingredients__c, APTS_Payer_Ingredients__c,
                                                    APTS_Bill_to_Party_MachServ__c, APTS_Payer_Machines_Services__c, 
                            APTS_Check_on_Account_Ingredients__c, APTS_Check_on_Account_Machines__c, APTS_Routesales__c,
                                                    Apttus__Account__r.APTS_Account_Level__c, Apttus__Account__r.Name, APTS_Location__r.Billing_header_text__c,
                                                    APTS_Location__r.Delivery_text__c
                                                    FROM Apttus__APTS_Agreement__c WHERE Apttus__Account__c != null AND Apttus__Account__c IN :setAllAccountId
                                                    AND RecordType.Name = :APTS_OrderConstants.STANDARD_DEAL AND Apttus__Status__c IN :setAgStatus]) {

                mapAgreementsTmp.put(agTmp.Apttus__Account__c, agTmp);

            }

            if (mapAgreementsTmp != null && !mapAgreementsTmp.isEmpty()) {
                Id parentId, grandParentId;
                Apttus__APTS_Agreement__c agTmp = null;

                for (Id accId : setAccountToVisitId) {
                    agTmp = mapContributingAgrs.get(accId);

                    if (mapAgreementsTmp.containsKey(accId)) {
                        agTmp = mapAgreementsTmp.get(accId);
                    }

                    parentId = mapParentId == null ? null : mapParentId.get(accId);
                    if (parentId != null && mapAgreementsTmp.containsKey(parentId) && agTmp == null) {//v104
                        agTmp = mapAgreementsTmp.get(parentId);
                    }

                    grandParentId = mapGrandParentId == null ? null : mapGrandParentId.get(accId);
                    if (grandParentId != null && mapAgreementsTmp.containsKey(grandParentId) && agTmp == null) {//v104
                        agTmp = mapAgreementsTmp.get(grandParentId);
                    }

                    if (agTmp != null) {
                        mapContributingAgrs.put(accId, agTmp);
                    }
                }
            }
        } catch (Exception ex) {
            throw ex;
        }

        return mapContributingAgrs;

    }


    /** Method : createOrderHeader
    ** Description : method would return order record for Digital ORder
    **/
    public static Apttus_Config2__Order__c createOrderHeader(APTS_DOEPIReqWrapper objWrapper, Map<Id, Account> mapAccount, Map<Id, Contact> mapContancts, Map<Id, Apttus__APTS_Agreement__c> mapStandardAgs, Apttus_Config2__PaymentTerm__c oPrepaidPT, Map<Id, APTS_Billing_Settings__c> mapBS) {
        //get Account data
        Account oAcc = mapAccount != NULL ? mapAccount.get(objWrapper.SalesforceAccountID) : NULL;
        if (oAcc == null) {
            return null;
        }

        Apttus_Config2__Order__c oDigOrder = new Apttus_Config2__Order__c();
        oDigOrder = APTS_OrderUtils.setOrderHeaderMandatoryFields(oDigOrder, STR_STANDARD);
        oDigOrder.APTS_Order_Sub_Type__c = APTS_OrderConstants.ORDER_TYPE_DIGITAL;
        //30-Sep-2019 - Aarthi Pitchai - Added below as part of Defect# 19538
        oDigOrder.APTS_Delivery_Block__c = null;
        oDigOrder.APTS_Requested_Installation_Date__c = null;

        oDigOrder.Apttus_Config2__BillToAccountId__c = objWrapper.SalesforceAccountID;
        oDigOrder.Apttus_Config2__SoldToAccountId__c = objWrapper.SalesforceAccountID;
        oDigOrder.Apttus_Config2__LocationId__c = objWrapper.SalesforceAccountLocationID;
        oDigOrder.Apttus_Config2__PONumber__c = objWrapper.PONumber;
        oDigOrder.APTS_Payer__c = objWrapper.SalesforceAccountID;
        oDigOrder.APTS_Source_Order_Number__c = objWrapper.SourceOrderNumber;
        oDigOrder.APTS_Prepaid_Flag__c = objWrapper.PrepaidFlag;
        oDigOrder.APTS_Payment_Reference_Number__c = objWrapper.PaymentReferenceNumber;
        //oDigOrder.APTS_Payment_Method_Code__c = objWrapper.PaymentMethod;
        oDigOrder.APTS_Reference_Number__c = objWrapper.ReferenceNumber;
        oDigOrder.CurrencyIsoCode = objWrapper.CurrencyCode;
        oDigOrder.APTS_Sales_Organization__c = objWrapper.SalesOrganization;

        oDigOrder.APTS_Adjustment_Type__c = objWrapper.AdjustmentType;
        oDigOrder.APTS_Order_Adjustment__c = objWrapper.TotalOrderAdjustment != null ?  -1 * objWrapper.TotalOrderAdjustment : objWrapper.TotalOrderAdjustment;
        oDigOrder.APTS_External_Total_Order_Amount__c = objWrapper.TotalOrderAmount;
        oDigOrder.APTS_External_Total_Shipping_costs__c = objWrapper.TotalShippingCost;
        oDigOrder.APTS_External_Total_Adjustment__c = objWrapper.TotalAdjustment;
        oDigOrder.APTS_External_Total_Adjusted_Price__c = objWrapper.TotalAdjustedPrice;
        oDigOrder.APTS_External_Total_Tax_Amount__c = objWrapper.TotalTaxAmount;
        oDigOrder.APTS_External_Total_VAT_Amount__c = objWrapper.TotalVATAmount;
        oDigOrder.APTS_External_Currency__c = objWrapper.CurrencyCode;
        oDigOrder.APTS_External_Total_Order_Adjustment__c = objWrapper.TotalOrderAdjustment;
        //4-Sep-2018 - Aarthi - Added below as part of Defect Fix# 18999 setting the APTS_Order_Adjustment__c same as APTS_External_Total_Shipping_costs__c at Order Header
        //oDigOrder.APTS_Order_Adjustment__c = objWrapper.TotalShippingCost;

        oDigOrder.APTS_Is_One_Time_Customer__c = objWrapper.OneTimeCustomer;
        oDigOrder.APTS_One_Time_Contact_Name__c = objWrapper.OneTimeContactName;
        oDigOrder.APTS_One_Time_Email__c = objWrapper.OneTimeEmail;
        oDigOrder.APTS_Ship_To_Override__c = objWrapper.ShipToOverride;
        oDigOrder.APTS_One_Time_Company_Name__c = objWrapper.ShipToCompanyName;
        oDigOrder.APTS_One_Time_Bill_to_Contact_Name__c = objWrapper.BillToContactName;
        oDigOrder.APTS_One_Time_Bill_to_Email__c = objWrapper.BillToEmail;
        oDigOrder.APTS_One_Time_Bill_to_Company_Name__c = objWrapper.BillToCompanyName;

        oDigOrder.APTS_Division__c = oAcc.Division__c;
        oDigOrder.APTS_Distribution_Channel__c = oAcc.Distribution_Channel__c;
        if (oAcc.Billing_header_text__c != null) {
            oDigOrder.APTS_Invoice_Remark__c = oAcc.Billing_header_text__c.length() > 255 ? oAcc.Billing_header_text__c.left(255) : oAcc.Billing_header_text__c;
        }
        oDigOrder.Apttus_Config2__PrimaryContactId__c = String.isNotBlank(objWrapper.SalesforceContactID) ? objWrapper.SalesforceContactID : NULL;
        oDigOrder.Apttus_Config2__PriceListId__c = String.isNotBlank(objWrapper.SalesforcePriceListID) ? objWrapper.SalesforcePriceListID : null;

        //get Agreement data
        Apttus__APTS_Agreement__c oSelectedAg = mapStandardAgs.get(objWrapper.SalesforceAccountID);

        if (oSelectedAg != null) {
            oDigOrder = APTS_OrderUtils.setOrderHeader(oDigOrder, oSelectedAg, oAcc);
            oDigOrder.Apttus_CMConfig__AgreementId__c = oSelectedAg.Id;
            oDigOrder.Apttus_Config2__PriceListId__c = oDigOrder.Apttus_Config2__PriceListId__c == null ? oSelectedAg.Apttus_CMConfig__PriceListId__c : oDigOrder.Apttus_Config2__PriceListId__c;

            APTS_Billing_Settings__c oBS = mapBS.get(oSelectedAg.Id);
            //Set paymentmethod for orders that are not prepaid
            oDigOrder.APTS_Payment_Method__c = STR_NO.equalsIgnoreCase(oDigOrder.APTS_Prepaid_Flag__c) && oBS != null && (string.isBlank(objWrapper.PaymentReferenceNumber) || objWrapper.PaymentReferenceNumber == null) ? oBS.APTS_Payment_Method__c : oDigOrder.APTS_Payment_Method__c;
            oDigOrder.Apttus_Config2__PaymentTermId__c = STR_NO.equalsIgnoreCase(oDigOrder.APTS_Prepaid_Flag__c)  && oSelectedAg.Apttus_CMConfig__PaymentTermId__c != null ? oSelectedAg.Apttus_CMConfig__PaymentTermId__c : oDigOrder.Apttus_Config2__PaymentTermId__c;
        } else {
            //set data from account
            oDigOrder = APTS_OrderUtils.setOrderHeader(oDigOrder, oAcc);
            APTS_DefaultPriceList oDfPricelist = new APTS_DefaultPriceList();
            oDigOrder.Apttus_Config2__PriceListId__c = oDfPricelist.getDefaultPriceListId(oAcc);
        }

        //contact id
        if (oDigOrder.Apttus_Config2__PrimaryContactId__c == null && mapContancts != null && mapContancts.get(oDigOrder.Apttus_Config2__BillToAccountId__c) != null) {
            oDigOrder.Apttus_Config2__PrimaryContactId__c = mapContancts.get(oDigOrder.Apttus_Config2__BillToAccountId__c).Id;
        }

        //19-Sep Aarthi Pitchai - Added below to default the Payment Term for Prepaid orders
        oDigOrder.Apttus_Config2__PaymentTermId__c = STR_YES.equalsIgnoreCase(oDigOrder.APTS_Prepaid_Flag__c) ? oPrepaidPT.Id : oDigOrder.Apttus_Config2__PaymentTermId__c;

        //If in Agreement Payment Method is not found than copy from Account
        oDigOrder.APTS_Payment_Method__c = string.isBlank(oDigOrder.APTS_Payment_Method__c) || oDigOrder.APTS_Payment_Method__c == null ? oAcc.APTS_Payment_Method__c : oDigOrder.APTS_Payment_Method__c;
        oDigOrder.Apttus_Config2__PaymentTermId__c = string.isBlank(oDigOrder.Apttus_Config2__PaymentTermId__c) || oDigOrder.Apttus_Config2__PaymentTermId__c == null ? oAcc.Apttus_Config2__PaymentTermId__c : oDigOrder.Apttus_Config2__PaymentTermId__c;
        oDigOrder.APTS_Digital_Order_Type__c = objWrapper.Type; //v103 ++ <<>>
        
        return oDigOrder;
    }
}