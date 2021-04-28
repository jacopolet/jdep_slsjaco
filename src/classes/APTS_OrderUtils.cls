/*************************************************************
  @Name: APTS_OrderUtils
  @Author: Galin Georgiev
  @CreateDate: 04-01-2018
  @Description: Order utils
  @UsedBy:
  *****************************************************************/
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes
//v100 04-01-2018 Galin Georgiev: Initial version.
//v101 29-Nov-2018 Nikita Modi : Added logic for setting ZX10 at OLI based on Adjustment amount - CR#2141
//v101 05-Dec-2018 Aarthi Pitchai : Added logic for Setting BillTo Payer To for Admin Orders similar to Machines - Defect# 22370
//v102 19-Dec-2018 Akanksha : Added method for Delivery Frame - Defect# 22816
//v103 08-Jan-2019 Akanksha : Added code for defect# 23415
//v104 16-Jan-2019 Sanjay  : Added code for defect# 23566
//v105 12-Feb-2019 Sanjay  : Added code for BSS defect# 4812 - Retrieve APTS_Customer_Specific_Freight_charge__c from Config
//v106 19-Feb-2019 Akanksha : Added code for defect # 4213
//v107 20-Feb-2019 Rajesh : Defect#4920
//v108 03-Mar-2019 Nikita : CR#2240 CHange in logic of Requested delivery date calculation
//v109 04-Apr-2019 Nikita : Def#6373 : Altered the condition on resetting the EDD and EDQ and ATP cleared on submit of order
//v110 09-Apr-2019 Aarthi : Def#6373 : Altered the SOQL where condition without ATP cleared Flag check
//v111 11-Apr-2019 Akanksha : Updated setOrderHeader method without Agreement
//v112 17-Apr-2019 Aarthi : Added logic to set the Item Category for Consumption Model with usage Fee and BPO - Defect #6723
//v113 18-Apr-2019 Aarthi : Added logic to enable PO Number validation for RSO ordering from Apttus, also included code optimization - Defect #6778
//v114 30-Apr-2019 Aarthi : Updated logic on Item Category for XD12 to not consider ZX10 in case of BPO=0 - Defect #7022
//v115 30-May-2019 Aarthi :DOQOM-39
//v116 15-Aug-2019 Aarthi: QTCFLEX1-579 - ZX10 to be determined from Asset adjustments in case of deInstall
//v117 14-Oct-2019 Aarthi: QTCFLEX1-1451 - Added method to get the default Location Id based on Account   
//v118 23-Oct-2019 Aarthi: QTCFLEX1-1479 - Requested delivery date calculation logic - Update on Additional Offset been considered on Ingredients order  
//v119 03-Jan-2020 Amit: DFT2C-2126 - Set Item Category of XD09 OLI with Net price and Base price Zero without adjsutment.
//v120 07-Jan-2020 Renuka: QTCFLEX1-1896 - Set Item Category for 'Free of Charge 100% disc' in OLI.
//v121 05-Feb-2020 Aarthi: DQ-1042 - Add Freight charge product for reOrder
//DQ-56 Contract change - Restricting Picklist value to No for non - Contract change Orders.
//V122 10-Feb-2020 Aarthi Pitchai : Apttus upgrade issue workaround - Linestatus not filled while using APi for SO
//V123 24-Feb-2020 Aarthi Pitchai : XD09 - Net price logic updated
//V124 23-Mar-2020 Renuka: DQ-472 - Enable Item Relevant Flag and Item Category logic for XD01
//V125 29-July-2020 Sneha Jaiwant:DQ-3150 - Bypassing the account validations before activation of orderlineitem
//V126 29-JULY-2020 Renuka: DQ-3458 : POC-XC09 CreditOrder
//V127 30-Jul-2020 Aarthi : DQ-3153 - Added method to deactivate the existing counters in case of refubhised Machines

public without sharing class APTS_OrderUtils {

    private static final String FINALIZED = System.Label.APTS_Finalized;
    private static final String OPTION = System.Label.APTS_Option;
    private static final String STANDALONE = System.Label.APTS_Standalone;
    private static final String BUNDLE = System.Label.APTS_Bundle;
    private static final String SALES_PRICE = System.Label.APTS_Sales_Price;
    private static final String USAGE_FEE = System.Label.APTS_Usage_Fee;
    private static final String COMPLETE = System.Label.APTS_Complete;
    private static final String APTS_SYNCHRONIZED = System.Label.APTS_Synchronized;
    private static final String STANDARD_ORDER = System.Label.APTS_Standard_Order;
    private static final String MACHINE_ORDER = System.Label.APTS_Machine_Order;
    private static final String ADMIN_ORDER = 'Admin Order';
    private static final String NO = 'No';
    private static final String STANDARD_RETURN = System.Label.APTS_Standard_Return;
    private static final String ZD1 = System.Label.APTS_ZD1;
    private static final String XB01 = System.Label.APTS_XB01;
    private static final String APTS_NEW = System.Label.APTS_New;
    private static final String SAVED = System.Label.APTS_Saved;
    private static final String PENDING = System.Label.APTS_Pending;
    private static final String DRAFT = System.Label.APTS_Draft;
    private static final String USEADVANCEDAPPROVAL = System.Label.APTS_useAdvancedApproval;
    private static final String USEDEALOPTIMIZER = System.Label.APTS_useDealOptimizer;
    private static final String FLOW = System.Label.APTS_Flow;
    private static final String ORDER = System.Label.APTS_Order;
    private static final String SUBMITTED = System.Label.APTS_Submitted;
    private static final String BEINGAMENDED = System.Label.APTS_Being_Amended;
    private static final String SUBSCRIPTION_ORDER = System.Label.APTS_Subscription_Order; //v105++
    private static final String BUYER_INGREDIENTS = System.Label.APTS_Buyer_Ingredients;
    private static final String BUYER_ALL = System.Label.APTS_Buyer_All;
    private static final String SAT = System.Label.APTS_Sat;
    private static final String SUN = System.Label.APTS_Sun;
    private static final String STANDARD = System.Label.APTS_Standard;
    private static final String XA01 = System.Label.APTS_XA01;
    private static final String XA13 = System.Label.APTS_XA13;
    private static final String Z6 = System.Label.APTS_Z6;
    private static final String TASK_OPEN = System.Label.APTS_Open;
    private static final String SUBSCRIPTION_TASK_GUIDANCE = System.Label.APTS_Subscription_Task_Guidance;
    private static final String EMAIL = System.Label.APTS_Email;
    private static final String PROSPECT = 'Prospect Valid';
    private static final String ACCOUNT_HIERARCHY = 'Account Hierarchy';
    private static final String ADMIN = System.Label.APTS_AdminOrder;
    private static final String DEBIT_MEMO = System.Label.APTS_DebitMemo;
    private static final String XD01 = System.Label.APTS_XD01;
    private static final String CREDIT_MEMO = 'Credit Memo';
    private static final String XC01 = 'XC01';
    private static final String ACTIVATED = System.Label.APTS_Activated;
    private static final String APEX = 'Apex';
    private static final String BIR = 'BIR';
    private static final String XA23 = System.Label.APTS_XA23;
    private static final String TRIAL = System.Label.APTS_Trial;
    private static final String ACCOUNT = System.Label.APTS_Account;
    private static Boolean bUpdateInstallDate = false;
    private static final String ACCOUNT_STATUS = 'Valid';
    private static final String LINETYPE_OPTION = 'Option';
    // v104++<<
    private static final String YOCI = 'YOCI';
    private static final String YOFT = 'YOFT';
    //v125++<<
    public static boolean deleteAfterVRS = false;
    public static boolean isVRSUpdated = false;
    //V125++>>
    //v100-->>

    //public static List<CountrySetting__c> countrySettingList;

    private static Set<String> fieldsNotToCopySet = new Set<String> {
        'Apttus_Config2__AttributeValueId__c', 'Apttus_Config2__ConfigurationId__c',
        'Apttus_Config2__AddedByRuleInfo__c', 'Apttus_Config2__AddedBy__c',
        'Apttus_Config2__PriceListId__c', 'Apttus_Config2__ProductId__c', 'Apttus_Config2__ProductOptionId__c',
        'APTS_Requested_Installation_Date__c', 'APTS_Requested_Delivery_Date__c',
        'APTS_ATP_Cleared__c', 'APTS_Expected_Delivery_Quantity__c', 'APTS_Expected_Delivery_Date__c'
    };

    //@Description: Method to return line items with needed fields
    public static Map<Id, Apttus_Config2__LineItem__c> getLineItemDataAll(Set<Id> lineItemIdSet) {

        String query = String.format(
                                     'SELECT ' +
                                     'Apttus_Config2__ProductOptionId__r.Apttus_Config2__ComponentProductId__c, ' +
                                     'Apttus_Config2__ProductId__r.Apttus_Config2__ConfigurationType__c, ' +
                                     '{0} FROM {1} WHERE Id IN :lineItemIdSet',
                                     new String[] {
                                        String.join(
                                                    new List<String> (
                                                                      Apttus_Config2__LineItem__c.SObjectType.getDescribe().fields.getMap().keySet() //get all fields
            ),
                                                    ','
            ),
                                        String.valueOf(Apttus_Config2__LineItem__c.SObjectType)
                                     }
        );

        List<Apttus_Config2__LineItem__c> lineItemList = Database.query(query);
        Map<Id, Apttus_Config2__LineItem__c> idToLineItemMap = new Map<Id, Apttus_Config2__LineItem__c> (lineItemList);

        return idToLineItemMap;
    }

    //@Description: Method would set initail fields on order
    public static Apttus_Config2__Order__c setOrderHeaderMandatoryFields(Apttus_Config2__Order__c oOrder, String sType) {
        //try{
        if (sType.equals(STANDARD)) {
            oOrder.APTS_Order_Type__c = STANDARD_ORDER;
            oOrder.RecordTypeId = Schema.SObjectType.Apttus_Config2__Order__c.getRecordTypeInfosByName().get(STANDARD_ORDER).getRecordTypeId();
            oOrder.APTS_SAP_OrderType__c = XA01;
            oOrder.APTS_Requested_Delivery_Date__c = checkRequestedDeliveryDateInWorkingHours(oOrder, system.today());
        } else if (sType.equals(ADMIN)) {
            oOrder.APTS_Order_Type__c = ADMIN;
            oOrder.RecordTypeId = Schema.SObjectType.Apttus_Config2__Order__c.getRecordTypeInfosByName().get(ADMIN).getRecordTypeId();
        } else if (sType.equals(DEBIT_MEMO)) {
            oOrder.APTS_Order_Type__c = DEBIT_MEMO;
            oOrder.APTS_SAP_OrderType__c = XD01;
            oOrder.RecordTypeId = Schema.SObjectType.Apttus_Config2__Order__c.getRecordTypeInfosByName().get(ADMIN).getRecordTypeId();
        }
        else if (sType.equals(CREDIT_MEMO)) {
            oOrder.APTS_Order_Type__c = CREDIT_MEMO;
            oOrder.APTS_SAP_OrderType__c = XC01;
            oOrder.RecordTypeId = Schema.SObjectType.Apttus_Config2__Order__c.getRecordTypeInfosByName().get(ADMIN).getRecordTypeId();
        }
        else {
            oOrder.APTS_Order_Type__c = MACHINE_ORDER;
            oOrder.RecordTypeId = Schema.SObjectType.Apttus_Config2__Order__c.getRecordTypeInfosByName().get(MACHINE_ORDER).getRecordTypeId();
            oOrder.APTS_SAP_OrderType__c = XA13;
            oOrder.APTS_Delivery_Block__c = Z6;
            oOrder.APTS_Requested_Installation_Date__c = getTheNextMonday(); //Date.today().addDays(7).toStartOfWeek();
            oOrder.APTS_Requested_Delivery_Date__c = oOrder.APTS_Requested_Installation_Date__c.addDays(- 3);
        }
        oOrder.Apttus_Config2__OrderStartDate__c = Date.today();
        oOrder.Apttus_Config2__OrderDate__c = Date.today();
        //oOrder.Apttus_Config2__OrderEndDate__c  = Date.today();
        system.debug('***oOrder.Apttus_Config2__Status__c' + oOrder.Apttus_Config2__Status__c);
        oOrder.APTS_Status__c = oOrder.Apttus_Config2__Status__c;
        oOrder.APTS_Contract_Change__c = NO;
        oOrder.Apttus_Config2__Source__c = ACCOUNT; // 23-Sep-2018 -Aarthi - Added this line as part of defect fix# 19505 related to Order Activation issue
        //} catch (Exception e) {
        //    APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id), 'OM', false, true, EMAIL, true);
        //}
        return oOrder;
    }

    /*Method to fetch Coming Monday*/
    public static Date getTheNextMonday() {
        date myDate = date.newInstance(1900, 1, 1);
        date StartOfThisWeek = system.today().toStartOfWeek();
        Date comingMonday;
        Integer getDayValue = Integer.valueOf(math.mod(StartOfThisWeek.daysBetween(myDate), 7));
        if (getDayValue != 0 && getDayValue != 5) { comingMonday = System.today().toStartOfWeek().addDays(8); }
        else if (getDayValue != 6 && getDayValue != 5) { comingMonday = System.today().toStartOfWeek().addDays(7); }
        else { comingMonday = System.today().toStartOfWeek().addDays(9); }
        return comingMonday;
    }

    //@Description: this method copy header information from agreement or account to order
    public static Apttus_Config2__Order__c setOrderHeader(Apttus_Config2__Order__c oOrder, Apttus__APTS_Agreement__c oAgreement, Account oAccount) {
        Set<String> sSalesOrg = new Set<String> { 'SAP_0976' };
        List<String> orderFieldList = new List<String> {
            'Apttus_CMConfig__AgreementId__c', 'APTS_Name__c', 'Apttus_Config2__PriceListId__c', 'Apttus_Config2__BillingPreferenceId__c',
            /*'Apttus_Config2__SoldToAccountId__c',*/ 'Apttus_Config2__PONumber__c', 'Apttus_Config2__PaymentTermId__c', 'APTS_Language_Preference__c',
            'APTS_Sales_Organization__c', 'APTS_Division__c', 'APTS_Distribution_Channel__c',
            'Apttus_Config2__BillToAccountId__c', 'APTS_Payer__c'
        };
        List<String> agreementFieldList = new List<String> {
            'Id', 'Name', 'Apttus_CMConfig__PriceListId__c', 'Apttus_CMConfig__BillingPreferenceId__c',
            /*'Apttus__Account__c',*/ 'Apttus_CMConfig__PONumber__c', 'Apttus_CMConfig__PaymentTermId__c', 'APTS_Language__c',
            'null', 'null', 'null', //'APTS_Distribution_Channel__c',
            'APTS_Bill_to_Party_Ingredients__c', 'APTS_Payer_Ingredients__c', 'APTS_Bill_to_Party_MachServ__c', 'APTS_Payer_Machines_Services__c'
        };
        List<String> accountFieldList = new List<String> {
            'null', 'null', 'null', 'Apttus_Config2__BillingPreferenceId__c',
            /*'Id',*/ 'null', 'Apttus_Config2__PaymentTermId__c', 'Language__c',
            'Sales_Organization__c', 'Division__c', 'Distribution_Channel__c',
            'Bill_To_Payer_Account__c', 'Related_Payer_Account__c', 'null' /*'Related_Bill_to_Machines_Services__c'*/, 'Related_Payer_Machines_Services__c'
        };

        Integer iIndex = 0;
        try {
            for (String sOrderField : orderFieldList) {

                String sAgreementField;
                String sAccountField;

                if ((oOrder.APTS_Order_Type__c == MACHINE_ORDER || oOrder.APTS_Order_Type__c == ADMIN_ORDER) && (sOrderField.equals('Apttus_Config2__BillToAccountId__c') || sOrderField.equals('APTS_Payer__c'))) {
                    sAgreementField = agreementFieldList.get(iIndex + 2);
                    sAccountField = accountFieldList.get(iIndex + 2);
                } else {
                    sAgreementField = agreementFieldList.get(iIndex);
                    sAccountField = accountFieldList.get(iIndex);
                }

                if (checkNotNull(oAgreement, sAgreementField)) {
                    oOrder.put(sOrderField, oAgreement.get(sAgreementField));
                } else if (checkNotNull(oAccount, sAccountField)) {
                    oOrder.put(sOrderField, oAccount.get(sAccountField));
                }

                iIndex++;
            }

            oOrder.Apttus_Config2__SoldToAccountId__c = oAccount.Id;

            if (oOrder.Apttus_Config2__BillToAccountId__c == null) {
                oOrder.Apttus_Config2__BillToAccountId__c = oOrder.Apttus_Config2__SoldToAccountId__c;
            }

            if (oOrder.APTS_Payer__c == null) {
                oOrder.APTS_Payer__c = oOrder.Apttus_Config2__SoldToAccountId__c;
            }
            APTS_BIRUtils.setInvoiceData(oAgreement, oOrder);
            // << v106 ++
            if (oOrder.APTS_Order_Type__c == APTS_OrderConstants.MACHINE_ORDER && oOrder.APTS_Order_Sub_Type__c == APTS_OrderConstants.INSTALLATION) {
                oOrder.APTS_InvoiceType__c = 'Single invoice';
                oOrder.APTS_Invoice_List_Indicator__c = 'No';
                oOrder.APTS_Collective_Billing_Indicator__c = False;
            }
            // v106 ++ >>

            if (!oOrder.APTS_Boomerang_Invoicing__c) {
                if (oOrder.APTS_Order_Type__c == MACHINE_ORDER) {
                    if (sSalesOrg.contains(oOrder.APTS_Sales_Organization__c) && !bUpdateInstallDate && oOrder.APTS_Requested_Installation_Date__c != null) {
                        bUpdateInstallDate = true;
                        oOrder.APTS_Requested_Installation_Date__c = oOrder.APTS_Requested_Installation_Date__c + 14;
                    }
                    oOrder.APTS_Requested_Delivery_Date__c = checkRequestedDeliveryDateInWorkingHours(oOrder, oOrder.APTS_Requested_Installation_Date__c);
                } else {
                    oOrder.APTS_Requested_Delivery_Date__c = checkRequestedDeliveryDateInWorkingHours(oOrder, system.today());
                }
                oOrder.Apttus_Config2__PONumber__c = APTS_OrderUtils.getagreementPODetails(oOrder, oAgreement); //Added by Sethu - Defect-19549 PO Number Changes
            }
            oOrder.Apttus_Config2__Source__c = ACCOUNT; // 23-Sep-2018 -Aarthi - Added this line as part of defect fix# 19505 related to Order Activation issue
        } catch(Exception e) {
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString(), 'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id), 'OM', false, true, null, true);
        }
        return oOrder;
    }

    //v111 ++ <<
    //@Description: this method copy header information from agreement or account to order
    public static Apttus_Config2__Order__c setOrderHeader(Apttus_Config2__Order__c oOrder, Account oAccount) {

        Set<String> sSalesOrg = new Set<String> { 'SAP_0976' };
        List<String> orderFieldList = new List<String> {
            'Apttus_CMConfig__AgreementId__c', 'APTS_Name__c', 'Apttus_Config2__PriceListId__c', 'Apttus_Config2__BillingPreferenceId__c',
            'Apttus_Config2__SoldToAccountId__c', 'Apttus_Config2__PONumber__c', 'Apttus_Config2__PaymentTermId__c', 'APTS_Language_Preference__c',
            'APTS_Sales_Organization__c', 'APTS_Division__c', 'APTS_Distribution_Channel__c',
            'Apttus_Config2__BillToAccountId__c', 'APTS_Payer__c'
        };

        List<String> accountFieldList = new List<String> {
            'null', 'null', 'null', 'Apttus_Config2__BillingPreferenceId__c',
            'Id', 'null', 'Apttus_Config2__PaymentTermId__c', 'Language__c',
            'Sales_Organization__c', 'Division__c', 'Distribution_Channel__c',
            'Bill_To_Payer_Account__c', 'Related_Payer_Account__c', 'null' /*'Related_Bill_to_Machines_Services__c'*/, 'Related_Payer_Machines_Services__c'
        };

        Integer iIndex = 0;
        //try{
        for (String sOrderField : orderFieldList) {

            String sAccountField;

            if ((oOrder.APTS_Order_Type__c == MACHINE_ORDER || oOrder.APTS_Order_Type__c == ADMIN_ORDER) && (sOrderField.equals('Apttus_Config2__BillToAccountId__c') || sOrderField.equals('APTS_Payer__c'))) {
                sAccountField = accountFieldList.get(iIndex + 2);
            } else {
                sAccountField = accountFieldList.get(iIndex);
            }
            if (checkNotNull(oAccount, sAccountField)) {
                oOrder.put(sOrderField, oAccount.get(sAccountField));
            } iIndex++;
        }

        oOrder.Apttus_Config2__SoldToAccountId__c = oAccount.Id;

        if (oOrder.Apttus_Config2__BillToAccountId__c == null) {
            oOrder.Apttus_Config2__BillToAccountId__c = oOrder.Apttus_Config2__SoldToAccountId__c;
        }
        if (oOrder.APTS_Payer__c == null) {
            oOrder.APTS_Payer__c = oOrder.Apttus_Config2__SoldToAccountId__c;
        }

        APTS_BIRUtils.setInvoiceData(oAccount, oOrder);

        if (oOrder.APTS_Order_Type__c == APTS_OrderConstants.MACHINE_ORDER && oOrder.APTS_Order_Sub_Type__c == APTS_OrderConstants.INSTALLATION) {
            oOrder.APTS_InvoiceType__c = 'Single invoice';
            oOrder.APTS_Invoice_List_Indicator__c = 'No';
            oOrder.APTS_Collective_Billing_Indicator__c = False;
        }

        if (!oOrder.APTS_Boomerang_Invoicing__c) {
            if (oOrder.APTS_Order_Type__c == MACHINE_ORDER) {
                if (sSalesOrg.contains(oOrder.APTS_Sales_Organization__c) && !bUpdateInstallDate && oOrder.APTS_Requested_Installation_Date__c != null) {
                    bUpdateInstallDate = true;
                    oOrder.APTS_Requested_Installation_Date__c = oOrder.APTS_Requested_Installation_Date__c + 14;
                }
                oOrder.APTS_Requested_Delivery_Date__c = checkRequestedDeliveryDateInWorkingHours(oOrder, oOrder.APTS_Requested_Installation_Date__c);
            } else {
                oOrder.APTS_Requested_Delivery_Date__c = checkRequestedDeliveryDateInWorkingHours(oOrder, system.today());
            }
            //oOrder.Apttus_Config2__PONumber__c = APTS_OrderUtils.getagreementPODetails(oOrder, oAgreement);   //Added by Sethu - Defect-19549 PO Number Changes
        } oOrder.Apttus_Config2__Source__c = ACCOUNT; // 23-Sep-2018 -Aarthi - Added this line as part of defect fix# 19505 related to Order Activation issue
        //} catch (Exception e) {
        //    APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id), 'OM', false, true, EMAIL, true);
        //}
        return oOrder;
    }

    //@Description: check wheter field is null
    public static Boolean checkNotNull(SObject oRecord, String sFieldName) {

        Boolean bResult = false;
        //try{
        if (sFieldName != 'null' && oRecord != null) {
            if (oRecord.get(sFieldName) != null) { bResult = true; }
        } return bResult;
        //} catch (Exception e) {
        //    APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id), 'OM', false, true, EMAIL, true);
        //}   
    }

    //@Description:PO Number Changes - Added by Sethu - Defect-19549
    public static string getagreementPODetails(Apttus_Config2__Order__c oOrder, Apttus__APTS_Agreement__c oAgreement) {

        if (oAgreement != null) {

            Id agreementId = oAgreement.Id;
            //V113 ++ <<
            set<String> setExternalOrderTypes = new Set<String> { APTS_OrderConstants.ORDER_TYPE_ROUTESALES, APTS_OrderConstants.ORDER_TYPE_OPERATING, APTS_OrderConstants.ORDER_TYPE_DIGITAL };
            set<String> setStandardOrderSubTypes = new Set<String> { APTS_OrderConstants.STANDARD_ORDER, APTS_OrderConstants.CONSIGNMENT_ISSUE, APTS_OrderConstants.CONSIGNMENT_FILLUP, APTS_OrderConstants.STANDARD_RETURN, APTS_OrderConstants.UNPLANNED_RETURN };
            set<String> setStandardOrderTypes = new Set<String> { APTS_OrderConstants.STANDARD_ORDER, APTS_OrderConstants.ORDER_TYPE_ROUTESALES, APTS_OrderConstants.ORDER_TYPE_OPERATING };
            for (APTS_Agreement_PO_Details__c agreementPODetails :[SELECT APTS_Agreement__c, APTS_PO_Category__c, APTS_PO_Expiration_Date__c, APTS_PO_Number__c, APTS_PO_Number_Type__c
                 FROM APTS_Agreement_PO_Details__c
                 WHERE APTS_Agreement__c = :agreementId]) {

                String PoCategory = (setExternalOrderTypes.contains(oOrder.APTS_Order_Type__c) && agreementPODetails.APTS_PO_Category__c == APTS_OrderConstants.INGREDIENTS && oOrder.APTS_Source_Order_Number__c != null) ? APTS_OrderConstants.EXTERNAL : null;
                PoCategory = (oOrder.APTS_Order_Type__c == APTS_OrderConstants.MACHINE_ORDER && agreementPODetails.APTS_PO_Category__c == APTS_OrderConstants.MACHINE) ? APTS_OrderConstants.MACHINE : PoCategory;
                PoCategory = (setStandardOrderTypes.contains(oOrder.APTS_Order_Type__c) && setStandardOrderSubTypes.contains(oOrder.APTS_Order_Sub_Type__c) && agreementPODetails.APTS_PO_Category__c == APTS_OrderConstants.INGREDIENTS) ? APTS_OrderConstants.INGREDIENTS : PoCategory;

                if (String.isNotBlank(PoCategory)) {
                    if (agreementPODetails.APTS_PO_Expiration_Date__c<System.today()) {
                        oOrder.Apttus_Config2__PONumber__c = APTS_OrderConstants.PO_HAS_EXPIRED;
                    } else if (PoCategory != APTS_OrderConstants.EXTERNAL) {
                        if (agreementPODetails.APTS_PO_Number_Type__c == APTS_OrderConstants.FIXED) {
                            oOrder.Apttus_Config2__PONumber__c = agreementPODetails.APTS_PO_Number__c;
                        } else if (agreementPODetails.APTS_PO_Number_Type__c == APTS_OrderConstants.VARIABLE) {
                            oOrder.Apttus_Config2__PONumber__c = APTS_OrderConstants.ENTER_PO_NUMBER_MANUALLY;
                        }
                    }
                }
            }
            //V113 ++ >>
        }
        return oOrder.Apttus_Config2__PONumber__c;
    }
    //@Description: calculate Requested Delivery Date
    public static Date getRequestedDeliveryDate() {

        Date dtTodayPlusTwo = Date.today().addDays(2);
        Datetime dtimeTodayPlusTwo = Datetime.newInstance(dtTodayPlusTwo.year(), dtTodayPlusTwo.month(), dtTodayPlusTwo.day());
        String dayOfWeek = dtimeTodayPlusTwo.format('E');

        //try{
        if (dayOfWeek.equals(SUN)) { dtTodayPlusTwo = dtTodayPlusTwo.addDays(1); }
        if (dayOfWeek.equals(SAT)) { dtTodayPlusTwo = dtTodayPlusTwo.addDays(2); }
        //} catch (Exception e) {
        //    APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id), 'OM', false, true, EMAIL, true);
        //}
        return dtTodayPlusTwo;
    }

    //@Description: Calculate requested delivery date as TS
    public static Map<Id, List<CountrySetting__c>> prepareOrderIdToCountrySettingListMap(Map<Id, Apttus_Config2__Order__c> idToOrderMap) {

        Map<Id, String> orderIdToSalesOrganizationMap = new Map<Id, String> ();

        //try{
        for (Apttus_Config2__Order__c oOrder : idToOrderMap.values()) {
            orderIdToSalesOrganizationMap.put(oOrder.Id, oOrder.APTS_Sales_Organization__c);
        }

        Set<String> developerNameSet = APTS_OrderConstants.DEVELOPER_NAME_SET;

        List<CountrySetting__c> countrySettingAllList = [
                                                         SELECT Country__c, RoundTrip__c, DeliveryOffset__c, PickupOffset__c,
                                                         RecordType.DeveloperName, Business_Hours__c, AdditionalOffset__c, Additional_Offset_Time__c
                                                         FROM CountrySetting__c
                                                         WHERE Country__c IN :orderIdToSalesOrganizationMap.values() AND RoundTrip__c = false AND RecordType.DeveloperName IN :developerNameSet];

        Map<Id, List<CountrySetting__c>> orderIdToCountrySettingListMap = new Map<Id, List<CountrySetting__c>> ();

        for (Apttus_Config2__Order__c oOrder : idToOrderMap.values()) {

            List<CountrySetting__c> countrySettingList = new List<CountrySetting__c> ();

            for (CountrySetting__c oCountrySetting : countrySettingAllList) {
                if (oOrder.APTS_Sales_Organization__c == oCountrySetting.Country__c) {
                    countrySettingList.add(oCountrySetting);
                }
            } orderIdToCountrySettingListMap.put(oOrder.Id, countrySettingList);
        } return orderIdToCountrySettingListMap;
        //} catch (Exception e) {
        //    APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id), 'OM', false, true, EMAIL, true);
        //}     
    }

    //@Description: Calculate requested delivery date as TS
    public static Date checkRequestedDeliveryDateInWorkingHours(Apttus_Config2__Order__c oOrder, Date dtRequestedDeliveryDate) {

        Date dtRequestedDeliveryDateResult = dtRequestedDeliveryDate;
        //system.debug('oOrder.APTS_Sales_Organization__c: '+ oOrder.APTS_Sales_Organization__c);

        //try{
        if (dtRequestedDeliveryDate != null && oOrder.APTS_Sales_Organization__c != null) {

            Set<String> developerNameSet = APTS_OrderConstants.DEVELOPER_NAME_SET;

            //if(countrySettingList.isEmpty()){
            List<CountrySetting__c> countrySettingList = [SELECT Country__c, RoundTrip__c, DeliveryOffset__c, PickupOffset__c,
                                                          RecordType.DeveloperName, Business_Hours__c, AdditionalOffset__c, Additional_Offset_Time__c
                                                          FROM CountrySetting__c
                                                          WHERE Country__c = :oOrder.APTS_Sales_Organization__c AND RoundTrip__c = false AND RecordType.DeveloperName IN :developerNameSet AND Active__c = true];
            // }
            CountrySetting__c countrySchedulingRule;
            CountrySetting__c countryDefaultBusinessHours;

            for (CountrySetting__c oCountrySetting : countrySettingList) {

                //changed logic as part of defect# 23673
                countrySchedulingRule = MACHINE_ORDER.equalsIgnoreCase(oOrder.APTS_Order_Type__c) && APTS_OrderConstants.DEVELOPER_NAME_SCH_RULES.equalsIgnoreCase(oCountrySetting.RecordType.DeveloperName) ? oCountrySetting : countrySchedulingRule;
                countrySchedulingRule = !MACHINE_ORDER.equalsIgnoreCase(oOrder.APTS_Order_Type__c) && APTS_OrderConstants.DEVELOPER_NAME_SCH_RULES_INGRI.equalsIgnoreCase(oCountrySetting.RecordType.DeveloperName) ? oCountrySetting : countrySchedulingRule;
                countryDefaultBusinessHours = APTS_OrderConstants.DEVELOPER_NAME_BUS_HOURS.equalsIgnoreCase(oCountrySetting.RecordType.DeveloperName) ? oCountrySetting : countryDefaultBusinessHours;
            }
            dtRequestedDeliveryDateResult = requestedDeliveryDateCalculation(oOrder, countrySchedulingRule, countryDefaultBusinessHours, dtRequestedDeliveryDate);
            system.debug('dtRequestedDeliveryDateResult = ' + dtRequestedDeliveryDateResult);
        } return dtRequestedDeliveryDateResult;
        //} catch (Exception e) {
        //    APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id), 'OM', false, true, EMAIL, true);
        //}    
    }

    //@Description: Calculate requested delivery date as TS
    public static Date checkRequestedDeliveryDateInWorkingHours(Apttus_Config2__Order__c oOrder, List<CountrySetting__c> countrySettingList, Date dtRequestedDeliveryDate) {

        Date dtRequestedDeliveryDateResult = dtRequestedDeliveryDate;
        //try{
        if (!countrySettingList.isEmpty() && dtRequestedDeliveryDate != null) {

            CountrySetting__c countrySchedulingRule;
            CountrySetting__c countryDefaultBusinessHours;

            for (CountrySetting__c oCountrySetting : countrySettingList) {
                //changed logic as part of defect# 23673
                countrySchedulingRule = MACHINE_ORDER.equalsIgnoreCase(oOrder.APTS_Order_Type__c) && APTS_OrderConstants.DEVELOPER_NAME_SCH_RULES.equalsIgnoreCase(oCountrySetting.RecordType.DeveloperName) ? oCountrySetting : countrySchedulingRule;
                countrySchedulingRule = !MACHINE_ORDER.equalsIgnoreCase(oOrder.APTS_Order_Type__c) && APTS_OrderConstants.DEVELOPER_NAME_SCH_RULES_INGRI.equalsIgnoreCase(oCountrySetting.RecordType.DeveloperName) ? oCountrySetting : countrySchedulingRule;
                countryDefaultBusinessHours = APTS_OrderConstants.DEVELOPER_NAME_BUS_HOURS.equalsIgnoreCase(oCountrySetting.RecordType.DeveloperName) ? oCountrySetting : countryDefaultBusinessHours;
            } dtRequestedDeliveryDateResult = requestedDeliveryDateCalculation(oOrder, countrySchedulingRule, countryDefaultBusinessHours, dtRequestedDeliveryDate);
        } return dtRequestedDeliveryDateResult;

        //} catch (Exception e) {
        //    APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id), 'OM', false, true, EMAIL, true);
        //}     
    }

    public static Boolean checkWithIBusinessHoursRDD(DateTime deliveryDate) {
        Boolean bdeliveryDate = deliveryDate.date() == Date.today() ? TRUE : FALSE;
        return bdeliveryDate;
    }

    public static Date requestedDeliveryDateCalculation(Apttus_Config2__Order__c oOrderRec, CountrySetting__c countrySchedulingRuleRec, CountrySetting__c countryDefaultBusinessHoursRec, Date dtRequestedDeliveryDateRec) {
        DateTime deliveryDate = DateTime.newInstance(dtRequestedDeliveryDateRec.year(), dtRequestedDeliveryDateRec.month(), dtRequestedDeliveryDateRec.day());
        DateTime RequestedInstallationDate;
        DateTime RequestedDeInstallationDate;
        Boolean bDateCheck;
        Boolean bCalculateDeliveryDateLogic = False;
        if (oOrderRec.APTS_Requested_Installation_Date__c != null) {
            RequestedInstallationDate = DateTime.newInstance(oOrderRec.APTS_Requested_Installation_Date__c.year(), oOrderRec.APTS_Requested_Installation_Date__c.month(), oOrderRec.APTS_Requested_Installation_Date__c.day());
        }
        if (oOrderRec.APTS_Requested_De_Installation_Date__c != null) {
            RequestedDeInstallationDate = DateTime.newInstance(oOrderRec.APTS_Requested_De_Installation_Date__c.year(), oOrderRec.APTS_Requested_De_Installation_Date__c.month(), oOrderRec.APTS_Requested_De_Installation_Date__c.day());
        }
        if (countrySchedulingRuleRec != null && countryDefaultBusinessHoursRec != null) {
            //v108 <<++

            DateTime Current = DateTime.now();
            Boolean bWeekend = (Current.format('E') == 'Sat' || Current.format('E') == 'Sun'); //V118 ++ <<>>
            if (countrySchedulingRuleRec.Additional_Offset_Time__c != NULL && ((Current.hour()> countrySchedulingRuleRec.Additional_Offset_Time__c.hour() || (Current.hour() == countrySchedulingRuleRec.Additional_Offset_Time__c.hour() && Current.minute() > countrySchedulingRuleRec.Additional_Offset_Time__c.minute())) || bWeekend)) { //V118 ++ <<>>
                bCalculateDeliveryDateLogic = True;
            }
            //v108 -->>
            Set<String> SAPOrderTypeSet1 = new Set<String> { 'XA13', 'XA23' };
            Set<String> SAPOrderTypeSet2 = new Set<String> { 'XA01', 'XA03', 'XA04', 'XA07' };
            Set<String> SAPOrderTypeSet3 = new Set<String> { 'XB01', 'XB02', 'XB03', 'XB04', 'XB05' };

            Integer deliveryOffset = Integer.valueOf(countrySchedulingRuleRec.DeliveryOffset__c);
            Integer pickUpOffset = Integer.valueOf(countrySchedulingRuleRec.PickupOffset__c);
            Integer pickOffsetPlusNumberOfDaysOffset;
            Integer deliveryOffsetPlusNumberOfDaysOffset;

            if (countrySchedulingRuleRec.AdditionalOffset__c != NULL) {
                pickOffsetPlusNumberOfDaysOffset = countrySchedulingRuleRec.AdditionalOffset__c > 0 ? Integer.valueOf(countrySchedulingRuleRec.AdditionalOffset__c) + pickUpOffset : pickUpOffset;
                deliveryOffsetPlusNumberOfDaysOffset = countrySchedulingRuleRec.AdditionalOffset__c > 0 ? Integer.valueOf(countrySchedulingRuleRec.AdditionalOffset__c) + deliveryOffset : deliveryOffset;
            } else {
                pickOffsetPlusNumberOfDaysOffset = pickUpOffset;
                deliveryOffsetPlusNumberOfDaysOffset = deliveryOffset;
            }
            if (oOrderRec.APTS_Order_Type__c == MACHINE_ORDER) {
                if ((SAPOrderTypeSet1.contains(oOrderRec.APTS_SAP_OrderType__c)) && RequestedInstallationDate != null) {
                    deliveryDate = BusinessHours.nextStartDate(countryDefaultBusinessHoursRec.Business_Hours__c, RequestedInstallationDate);
                    deliveryDate = TS_LSPDatesCalculator.getNextBusinessDay(countryDefaultBusinessHoursRec.Business_Hours__c, deliveryDate, deliveryOffset, false);
                    //Requested Delivery Date = Requested Installation Date - [Delivery Offset]
                } else if (oOrderRec.APTS_SAP_OrderType__c == 'XA14' && oOrderRec.APTS_Requested_Movement_Date__c != null) {
                    deliveryDate = oOrderRec.APTS_Requested_Movement_Date__c;
                    //Requested Delivery Date = Requested Movement Date
                } else if (oOrderRec.APTS_SAP_OrderType__c == 'XB13' && RequestedDeInstallationDate != null) {
                    deliveryDate = BusinessHours.nextStartDate(countryDefaultBusinessHoursRec.Business_Hours__c, RequestedDeInstallationDate);
                    deliveryDate = TS_LSPDatesCalculator.getNextBusinessDay(countryDefaultBusinessHoursRec.Business_Hours__c, deliveryDate, pickUpOffset, True);
                    //Requested Delivery Date = Requested De-installation Date + [Pickup Offset]
                }
            } else {
                if (SAPOrderTypeSet2.contains(oOrderRec.APTS_SAP_OrderType__c)) {
                    //v108 <<--
                    if (bCalculateDeliveryDateLogic == TRUE && oOrderRec.APTS_SAP_OrderType__c == 'XA01') { //True if Additional Offset Time is less than current time
                        deliveryDate = BusinessHours.nextStartDate(countryDefaultBusinessHoursRec.Business_Hours__c, System.now());
                        bDateCheck = checkWithIBusinessHoursRDD(deliveryDate);
                        if (bDateCheck) { //True if nextStartDate returns today's date
                            deliveryDate = TS_LSPDatesCalculator.getNextBusinessDay(countryDefaultBusinessHoursRec.Business_Hours__c, deliveryDate, deliveryOffsetPlusNumberOfDaysOffset, true);
                        } else {
                            deliveryDate = deliveryDate.addDays(- 1);
                            deliveryDate = TS_LSPDatesCalculator.getNextBusinessDay(countryDefaultBusinessHoursRec.Business_Hours__c, deliveryDate, deliveryOffsetPlusNumberOfDaysOffset, true);
                        }
                    }
                    //v108 -->>
                    else {
                        deliveryDate = BusinessHours.nextStartDate(countryDefaultBusinessHoursRec.Business_Hours__c, System.now());
                        bDateCheck = checkWithIBusinessHoursRDD(deliveryDate);
                        if (bDateCheck) {
                            deliveryDate = TS_LSPDatesCalculator.getNextBusinessDay(countryDefaultBusinessHoursRec.Business_Hours__c, deliveryDate, deliveryOffset, true);
                        } else {
                            deliveryDate = deliveryDate.addDays(- 1);
                            deliveryDate = TS_LSPDatesCalculator.getNextBusinessDay(countryDefaultBusinessHoursRec.Business_Hours__c, deliveryDate, deliveryOffset, true);
                        }

                    } //Requested Delivery Date = Today () + [Delivery Offset]
                } else if (oOrderRec.APTS_SAP_OrderType__c == 'XA02') {
                    //v108 <<--
                    if (bCalculateDeliveryDateLogic == TRUE) {
                        deliveryDate = BusinessHours.nextStartDate(countryDefaultBusinessHoursRec.Business_Hours__c, System.now());
                        bDateCheck = checkWithIBusinessHoursRDD(deliveryDate);
                        if (bDateCheck) {
                            deliveryDate = TS_LSPDatesCalculator.getNextBusinessDay(countryDefaultBusinessHoursRec.Business_Hours__c, deliveryDate, deliveryOffsetPlusNumberOfDaysOffset, true);
                        } else {
                            deliveryDate = deliveryDate.addDays(- 1);
                            deliveryDate = TS_LSPDatesCalculator.getNextBusinessDay(countryDefaultBusinessHoursRec.Business_Hours__c, deliveryDate, deliveryOffsetPlusNumberOfDaysOffset, true); }
                    }
                    else {
                        //v108 -->>
                        deliveryDate = BusinessHours.nextStartDate(countryDefaultBusinessHoursRec.Business_Hours__c, System.now());
                        bDateCheck = checkWithIBusinessHoursRDD(deliveryDate);
                        deliveryDate = bDateCheck ? deliveryDate : deliveryDate.addDays(- 1);
                    } //Requested Delivery Date = Today ()
                } else if (SAPOrderTypeSet3.contains(oOrderRec.APTS_SAP_OrderType__c)) {
                    if (bCalculateDeliveryDateLogic == TRUE) {
                        deliveryDate = BusinessHours.nextStartDate(countryDefaultBusinessHoursRec.Business_Hours__c, System.now());
                        bDateCheck = checkWithIBusinessHoursRDD(deliveryDate);
                        if (bDateCheck) {
                            deliveryDate = TS_LSPDatesCalculator.getNextBusinessDay(countryDefaultBusinessHoursRec.Business_Hours__c, deliveryDate, pickOffsetPlusNumberOfDaysOffset, True);
                        } else {
                            deliveryDate = deliveryDate.addDays(- 1);
                            deliveryDate = TS_LSPDatesCalculator.getNextBusinessDay(countryDefaultBusinessHoursRec.Business_Hours__c, deliveryDate, pickOffsetPlusNumberOfDaysOffset, True);
                        }
                    }
                    else {
                        deliveryDate = BusinessHours.nextStartDate(countryDefaultBusinessHoursRec.Business_Hours__c, System.now());
                        bDateCheck = checkWithIBusinessHoursRDD(deliveryDate);
                        if (bDateCheck) {
                            deliveryDate = TS_LSPDatesCalculator.getNextBusinessDay(countryDefaultBusinessHoursRec.Business_Hours__c, deliveryDate, pickUpOffset, True);
                        } else {
                            deliveryDate = deliveryDate.addDays(- 1);
                            deliveryDate = TS_LSPDatesCalculator.getNextBusinessDay(countryDefaultBusinessHoursRec.Business_Hours__c, deliveryDate, pickUpOffset, True);
                        }
                    } //Requested Delivery Date = Today () + [Pickup Offset]
                }
            }
        } return deliveryDate.date();
    }


    public static Map<Id, Contact> getAllContacts(Id accountId) {

        Map<Id, Contact> idToContactMap = new Map<Id, Contact> ([
                                                                SELECT Id, Name, Function__c, Main_Commercial_Person__c, Main_Service_Person__c FROM Contact WHERE Id IN(SELECT ContactId FROM AccountContactRelation WHERE AccountId = :accountId)]);
        return idToContactMap;
    }

    //@Description: find primary contact
    public static Id getPrimaryContactId(Map<Id, Contact> idToContactMap, String sType) {

        Id primaryContactId = null;
        String sFunction = '';
        Set<Id> buyerIngredientsSet = new Set<Id> ();
        Set<Id> buyerIngredientsMCPSet = new Set<Id> ();
        Set<Id> buyerAllSet = new Set<Id> ();
        Set<Id> buyerAllMCPSet = new Set<Id> ();
        Set<Id> buyerMCPSet = new Set<Id> ();

        //try{
        for (Contact oContact : idToContactMap.values()) {

            if (oContact.Function__c != null) {
                sFunction = oContact.Function__c;
            }

            if (sType.equals(STANDARD)) {
                if (sFunction.equals(BUYER_INGREDIENTS)) {
                    buyerIngredientsSet.add(oContact.Id);
                    if (oContact.Main_Commercial_Person__c) {
                        buyerIngredientsMCPSet.add(oContact.Id);
                    }
                } else if (sFunction.equals(BUYER_ALL)) {
                    buyerAllSet.add(oContact.Id);
                    if (oContact.Main_Commercial_Person__c) {
                        buyerAllMCPSet.add(oContact.Id);
                    }
                } else if (oContact.Main_Commercial_Person__c) {
                    buyerMCPSet.add(oContact.Id);
                }
            } else {
                if (oContact.Main_Service_Person__c) {
                    primaryContactId = oContact.Id;
                    break;
                }
            }
        }

        if (sType.equals(STANDARD)) {
            if (buyerIngredientsSet.size() == 1) {
                primaryContactId = new List<Id> (buyerIngredientsSet) [0];
            } else if (buyerIngredientsMCPSet.size() == 1) {
                primaryContactId = new List<Id> (buyerIngredientsMCPSet) [0];
            } else if (buyerAllSet.size() == 1) {
                primaryContactId = new List<Id> (buyerAllSet) [0];
            } else if (buyerAllMCPSet.size() == 1) {
                primaryContactId = new List<Id> (buyerAllMCPSet) [0];
            } else if (buyerMCPSet.size() == 1) {
                primaryContactId = new List<Id> (buyerMCPSet) [0];
            }
        } return primaryContactId;
        //} catch (Exception e) {
        //    APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id), 'OM', false, true, EMAIL, true);
        //}     
    }

    //v107 ++<<
    public static map<Id, Contact> getPrimaryContactsRSO(String sType, Set<Id> accountId) {
        Map<Id, Contact> mapContact = new Map<Id, Contact> ();
        Contact tempContact;
        String sContactFun, sTempContactFun;

        for (Contact oContact :[SELECT Id, Name, AccountId, Function__c, Main_Commercial_Person__c, Main_Service_Person__c FROM Contact WHERE Id IN(SELECT ContactId FROM AccountContactRelation WHERE AccountId<> null AND AccountId IN :accountId)]) {
            tempContact = mapContact.get(oContact.AccountId);

            if (tempContact != null) {
                sTempContactFun = tempContact.Function__c != null ? tempContact.Function__c : null;
                sContactFun = oContact.Function__c != null ? oContact.Function__c : null;

                if (STANDARD.equalsIgnoreCase(sType)) {
                    if (BUYER_INGREDIENTS.equalsIgnoreCase(sTempContactFun)) {
                        continue;
                    } else if (BUYER_INGREDIENTS.equalsIgnoreCase(sContactFun)) {
                        mapContact.put(oContact.accountId, oContact);
                    } else if (BUYER_ALL.equalsIgnoreCase(sContactFun)) {
                        mapContact.put(oContact.accountId, oContact);
                    } else if (!BUYER_ALL.equalsIgnoreCase(sTempContactFun) && oContact.Main_Commercial_Person__c) {
                        mapContact.put(oContact.accountId, oContact);
                    }
                } else if (oContact.Main_Service_Person__c) {
                    mapContact.put(oContact.accountId, oContact);
                }
            } else { mapContact.put(oContact.accountId, oContact); }
        } return mapContact;
    }
    //v107 ++>>

    public static map<Id, Apttus_Config2__AccountLocation__c> getAccountLocation(Set<Id> accountId) {
        Map<id, Apttus_Config2__AccountLocation__c> mapAccountLocation = new Map<id, Apttus_Config2__AccountLocation__c> ();
        Apttus_Config2__AccountLocation__c accLocation;

        for (Apttus_Config2__AccountLocation__c acLoc :[SELECT Id, Billing_header_text__c, Delivery_text__c, SAP_Customer_ID__c, Apttus_Config2__AccountId__c, Apttus_Config2__AccountId__r.SAP_Customer_ID__c FROM Apttus_Config2__AccountLocation__c WHERE Apttus_Config2__AccountId__c IN :accountId AND Account_Location_Status__c = :ACCOUNT_STATUS AND Delivery_Block_Reason__c = NULL]) {
            if (String.isNotBlank(acLoc.SAP_Customer_ID__c) && String.isNotBlank(acLoc.Apttus_Config2__AccountId__r.SAP_Customer_ID__c) && acLoc.SAP_Customer_ID__c.equalsIgnoreCase(acLoc.Apttus_Config2__AccountId__r.SAP_Customer_ID__c)) {
                mapAccountLocation.put(acLoc.Apttus_Config2__AccountId__c, acLoc);
            }
        } return mapAccountLocation;
    }

    // >> ++ Primary contact for RSO Batch Change end

    public static Apttus_Config2__Order__c cloneOrder(Id orderId) {

        Apttus_Config2__Order__c oClonedOrder = new Apttus_Config2__Order__c();

        String sQuery = String.format(
                                      'SELECT {0} FROM {1} WHERE Id = :orderId',
                                      new String[] {
                                         String.join(
                                                     new List<String> (
                                                                       Apttus_Config2__Order__c.SObjectType.getDescribe().fields.getMap().keySet() //get all fields
            ),
                                                     ','
            ),
                                         String.valueOf(Apttus_Config2__Order__c.SObjectType)
                                      }
        );

        List<Apttus_Config2__Order__c> orderList = Database.query(sQuery);

        if (!orderList.isEmpty()) {
            Apttus_Config2__Order__c oOrder = orderList.get(0);
            oClonedOrder = oOrder.clone(false, false, false, false);
        } return oClonedOrder;
    }

    public static APTS_Order_LSP_Details__c cloneLSPDetails(Id lspDetailsId) {

        APTS_Order_LSP_Details__c oClonedLSPDetails = new APTS_Order_LSP_Details__c();

        String sQuery = String.format(
                                      'SELECT {0} FROM {1} WHERE Id = :lspDetailsId',
                                      new String[] {
                                         String.join(
                                                     new List<String> (
                                                                       APTS_Order_LSP_Details__c.SObjectType.getDescribe().fields.getMap().keySet() //get all fields
            ),
                                                     ','
            ),
                                         String.valueOf(APTS_Order_LSP_Details__c.SObjectType)
                                      }
        );

        List<APTS_Order_LSP_Details__c> lspDetailsList = Database.query(sQuery);

        if (!lspDetailsList.isEmpty()) {
            APTS_Order_LSP_Details__c oLSPDetails = lspDetailsList.get(0);
            oClonedLSPDetails = oLSPDetails.clone(false, false, false, false);
        } return oClonedLSPDetails;
    }

    //@Description: method would return cart ID
    public static Id createCart(Id orderId) {

        Id cartId;
        //try{
        if (String.isNotBlank(orderId)) {
            // Create config properties
            List<Apttus_Config2.Property> configProps = new List<Apttus_Config2.Property> ();
            Apttus_Config2.Property prop = new Apttus_Config2.Property();
            prop.Name = USEADVANCEDAPPROVAL;
            prop.Value = 'false';
            configProps.add(prop);
            prop = new Apttus_Config2.Property();
            prop.Name = USEDEALOPTIMIZER;
            prop.Value = 'false';
            configProps.add(prop);

            // Create the request
            Apttus_Config2.CPQStruct.CreateCartRequestDO request = new Apttus_Config2.CPQStruct.CreateCartRequestDO();
            request.OrderId = orderId;
            request.Properties.addAll(configProps);
            //Response
            Apttus_Config2.CPQStruct.CreateCartResponseDO result = Apttus_Config2.OrderWebService.createCart(request);
            cartId = result.CartId;
        } return cartId;
        //} catch (Exception e) {
        //    APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id), 'OM', false, true, EMAIL, true);
        //}  
    }

    //@Description: this method store proposal id and agreement id
    public static Apttus_Config2__ProductConfiguration__c updateCart(Id cartId, Id agreementId, Id proposalId) {

        Apttus_Config2__ProductConfiguration__c oConfiguration = null;
        //try{
        if (String.isNotBlank(cartId)) {
            List<Apttus_Config2__ProductConfiguration__c> listConfiguration = [SELECT Id, Apttus_QPConfig__Proposald__c, Apttus_Config2__Status__c, Apttus_Config2__FinalizedDate__c FROM Apttus_Config2__ProductConfiguration__c WHERE Id = :cartId LIMIT 1];
            if (listConfiguration != null && !listConfiguration.isEmpty()) {
                oConfiguration = listConfiguration.get(0);
                if (proposalId != null) oConfiguration.Apttus_QPConfig__Proposald__c = proposalId;
                if (agreementId != null) oConfiguration.Apttus_CMConfig__AgreementId__c = agreementId;
                update oConfiguration;
            }
        } return oConfiguration;
        //} catch (Exception e) {
        //    APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id), 'OM', false, true, EMAIL, true);
        //}  
    }

    //@Description: this method creates map of bundle line number and list of options for this bundle
    public static Map<Decimal, List<Apttus_CPQApi.CPQ.SelectedOptionDO>> prepareOptionsList(Map<Id, Apttus_Config2__LineItem__c> idToLineItemMap) {

        Map<Decimal, List<Apttus_CPQApi.CPQ.SelectedOptionDO>> bundelLineNumberToOptionListMap = new Map<Decimal, List<Apttus_CPQApi.CPQ.SelectedOptionDO>> ();
        List<Apttus_CPQApi.CPQ.SelectedOptionDO> optionList;
        //try{
        for (Apttus_Config2__LineItem__c oLI : idToLineItemMap.values()) {

            if (oLI.Apttus_Config2__LineType__c == OPTION) {

                if (bundelLineNumberToOptionListMap.containsKey(oLI.Apttus_Config2__LineNumber__c)) {
                    optionList = bundelLineNumberToOptionListMap.get(oLI.Apttus_Config2__LineNumber__c);
                } else {
                    optionList = new List<Apttus_CPQApi.CPQ.SelectedOptionDO> ();
                }
                Apttus_CPQApi.CPQ.SelectedOptionDO objSelectedOptionDO = new Apttus_CPQApi.CPQ.SelectedOptionDO();
                objSelectedOptionDO.ComponentId = oLI.Apttus_Config2__ProductOptionId__c;
                objSelectedOptionDO.ComponentProductId = oLI.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ComponentProductId__c;
                objSelectedOptionDO.StartDate = oLI.Apttus_Config2__StartDate__c;
                objSelectedOptionDO.EndDate = oLI.Apttus_Config2__EndDate__c;
                objSelectedOptionDO.Comments = oLI.Apttus_Config2__ChargeType__c;

                //Added for Usage price tier
                objSelectedOptionDO.Quantity = oLI.Apttus_Config2__Quantity__c;

                Apttus_Config2__LineItem__c oLineItem = setLineItemFields(oLI);
                objSelectedOptionDO.CustomData = oLineItem;
                objSelectedOptionDO.CustomFields = setLineItemFieldList();

                optionList.add(objSelectedOptionDO);
                bundelLineNumberToOptionListMap.put(oLI.Apttus_Config2__LineNumber__c, optionList);
            }
        } return bundelLineNumberToOptionListMap;
        //} catch (Exception e) {
        //    APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id), 'OM', false, true, EMAIL, true);
        //}   
    }

    //@Description: method would add Standalone products
    public static Apttus_CPQApi.CPQ.SelectedProductDO addStandaloneProductWithQuantity(Apttus_Config2__LineItem__c oLI, Integer iOrderedQuantity) {

        Apttus_CPQApi.CPQ.SelectedProductDO selProdDO;
        //try{
        if (oLI != null) {
            selProdDO = new Apttus_CPQApi.CPQ.SelectedProductDO();
            selProdDO.ProductID = oLI.Apttus_Config2__ProductId__c;
            selProdDO.SellingTerm = oLI.Apttus_Config2__SellingTerm__c;
            // selProdDO.StartDate = Date.Today();
            // selProdDO.EndDate = Date.Today().addMonths(12);
            // selProdDO.StartDate = oLI.Apttus_Config2__StartDate__c;
            // selProdDO.EndDate = oLI.Apttus_Config2__EndDate__c; //V121
            selProdDO.Comments = oLI.Apttus_Config2__Comments__c;
            selProdDO.Quantity = iOrderedQuantity;
            //V21 - Commented the below 3 lines due to empty category issue found in Apttus Upgrade testing.
            //Apttus_Config2__LineItem__c oLineItem = setLineItemFields(oLI);
            //selProdDO.CustomData = oLineItem;
            //selProdDO.CustomFields = setLineItemFieldList();

            List<String> setStandaloneFieldList = new List<String> ();
            setStandaloneFieldList.add('APTS_Source_Line_Number__c');
            setStandaloneFieldList.add('Apttus_Config2__SellingUom__c');
            Apttus_Config2__LineItem__c oLineItem = setLineItemFields(oLI);
            selProdDO.CustomData = oLineItem;
            selProdDO.CustomFields = setStandaloneFieldList;

        } return selProdDO;
        //} catch (Exception e) {
        //    APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id), 'OM', false, true, EMAIL, true);
        //} 
    }

    //@Description: method would add bundle with options
    public static void addBundleWithOptions(Id cartId, Apttus_Config2__LineItem__c oLI, Integer iOrderedQuantity, Map<Decimal, List<Apttus_CPQApi.CPQ.SelectedOptionDO>> bundelLineNumberToOptionListMap) {

        Apttus_CPQApi.CPQ.AddBundleRequestDO request = new Apttus_CPQApi.CPQ.AddBundleRequestDO();
        request.CartId = cartId;
        request.SelectedBundle = new Apttus_CPQApi.CPQ.SelectedBundleDO();
        request.SelectedBundle.SelectedProduct = new Apttus_CPQApi.CPQ.SelectedProductDO();
        request.SelectedBundle.SelectedProduct.ProductId = oLI.Apttus_Config2__ProductId__c;
        //request.SelectedBundle.SelectedProduct.StartDate = oLI.Apttus_Config2__StartDate__c; //V121
        //request.SelectedBundle.SelectedProduct.EndDate = oLI.Apttus_Config2__EndDate__c;
        request.SelectedBundle.SelectedProduct.Quantity = iOrderedQuantity;

        Apttus_Config2__LineItem__c oLineItem = setLineItemFields(oLI);
        request.SelectedBundle.SelectedProduct.CustomData = oLineItem;
        request.SelectedBundle.SelectedProduct.CustomFields = setLineItemFieldList();

        List<Apttus_CPQApi.CPQ.SelectedOptionDO> optionList = new List<Apttus_CPQApi.CPQ.SelectedOptionDO> ();

        if (!bundelLineNumberToOptionListMap.isEmpty() && bundelLineNumberToOptionListMap != null) {

            optionList = bundelLineNumberToOptionListMap.get(oLI.Apttus_Config2__LineNumber__c);
            for (Apttus_CPQApi.CPQ.SelectedOptionDO objSelectedOptionDO : optionList) {
                objSelectedOptionDO.Quantity = iOrderedQuantity;
            }
        }

        if (optionList.size() > 0) { request.SelectedBundle.SelectedOptions = optionList; }
        Apttus_CPQApi.CPQ.AddBundleResponseDO response = Apttus_CPQApi.CPQWebService.addBundle(request);
    }

    //@Description: call apis
    public static Apttus_CPQApi.CPQ.AddMultiProductResponseDO addMultiProducts(List<Apttus_CPQApi.CPQ.SelectedProductDO> selectedProductList, Id cartId) {

        Apttus_CPQApi.CPQ.AddMultiProductResponseDO response;

        //try{
        //Add Standalone list of products
        if (selectedProductList != null && !selectedProductList.isEmpty()) {
            Apttus_CPQApi.CPQ.AddMultiProductRequestDO request = new Apttus_CPQApi.CPQ.AddMultiProductRequestDO();
            request.CartId = cartId;
            request.SelectedProducts = selectedProductList;
            System.debug('request for adding multiproducts, CardId: ' + cartId + ' / selected productList: ' + selectedProductList.size());
            response = Apttus_CPQApi.CPQWebService.addMultiProducts(request);
        } return response;
        //} catch (Exception e) {
        //    APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id), 'OM', false, true, EMAIL, true);
        //}
    }

    //@Description: this method copy fields from source line item to new line item
    public static Apttus_Config2__LineItem__c setLineItemFields(Apttus_Config2__LineItem__c oLI) {

        Apttus_Config2__LineItem__c oLineItem = new Apttus_Config2__LineItem__c();
        // oLineItem.Apttus_Config2__ConfigStatus__c = COMPLETE;
        //oLineItem.Apttus_Config2__SyncStatus__c = APTS_SYNCHRONIZED;
        //oLineItem.Apttus_Config2__DerivedFromId__c = oLI.Apttus_Config2__DerivedFromId__c;
        //oLineItem.Apttus_Config2__ChargeType__c = oLI.Apttus_Config2__ChargeType__c;
        // oLineItem.Apttus_Config2__ServiceLocationId__c = oLI.Apttus_Config2__ServiceLocationId__c;
        // oLineItem.Apttus_Config2__Term__c = oLI.Apttus_Config2__Term__c;
        // oLineItem.Agreement_Line_Item__c = oLI.Agreement_Line_Item__c;
        //oLineItem.Apttus_Config2__SellingTerm__c = oLI.Apttus_Config2__SellingTerm__c;
        // oLineItem.Apttus_Config2__SellingFrequency__c = oLI.Apttus_Config2__SellingFrequency__c;
        // oLineItem.Apttus_Config2__ClassificationId__c = oLI.Apttus_Config2__ClassificationId__c;
        //oLineItem.Apttus_Config2__ClassificationHierarchy__c = oLI.Apttus_Config2__ClassificationHierarchy__c;
        // oLineItem.Apttus_Config2__AdjustmentType__c = oLI.Apttus_Config2__AdjustmentType__c;
        //oLineItem.Apttus_Config2__AdjustmentAmount__c = oLI.Apttus_Config2__AdjustmentAmount__c;
        //oLineItem.Apttus_Config2__LineStatus__c = oLI.Apttus_Config2__LineStatus__c;
        // oLineItem.Apttus_Config2__AssetLineItemId__c = oLI.Apttus_Config2__AssetLineItemId__c;
        // oLineItem.Apttus_Config2__AttributeValueId__c = oLI.Apttus_Config2__AttributeValueId__c;
        oLineItem.APTS_Source_Line_Number__c = oLI.APTS_Source_Line_Number__c;

        //selling uom
        oLineItem.Apttus_Config2__SellingUom__c = oLI.Apttus_Config2__SellingUom__c;
        return oLineItem;
    }

    //@Description: this method define fields to be copied from source line item to new line item
    public static List<String> setLineItemFieldList() {

        List<String> listCustomFields = new List<String> ();
        listCustomFields.add('Apttus_Config2__ConfigStatus__c');
        listCustomFields.add('Apttus_Config2__SyncStatus__c');
        listCustomFields.add('Apttus_Config2__DerivedFromId__c');
        listCustomFields.add('Apttus_Config2__ChargeType__c');
        listCustomFields.add('Apttus_Config2__ServiceLocationId__c');
        listCustomFields.add('Apttus_Config2__Term__c');
        listCustomFields.add('Agreement_Line_Item__c');
        listCustomFields.add('Apttus_Config2__SellingTerm__c');
        listCustomFields.add('Apttus_Config2__SellingFrequency__c');
        listCustomFields.add('Apttus_Config2__ClassificationId__c');
        listCustomFields.add('Apttus_Config2__ClassificationHierarchy__c');
        listCustomFields.add('Apttus_Config2__AdjustmentType__c');
        listCustomFields.add('Apttus_Config2__AdjustmentAmount__c');
        listCustomFields.add('Apttus_Config2__LineStatus__c');
        listCustomFields.add('Apttus_Config2__AssetLineItemId__c');
        listCustomFields.add('Apttus_Config2__AttributeValueId__c');
        listCustomFields.add('APTS_Source_Line_Number__c');
        //selling uom
        listCustomFields.add('Apttus_Config2__SellingUom__c');
        return listCustomFields;
    }

    //@Description: this method creates map of bundle line number and list of options for this bundle
    public static Map<Decimal, List<Apttus_CPQApi.CPQ.SelectedOptionDO>> prepareOptionsListAll(Map<Id, Apttus_Config2__LineItem__c> idToLineItemMap) {

        Map<Decimal, List<Apttus_CPQApi.CPQ.SelectedOptionDO>> bundelLineNumberToOptionListMap = new Map<Decimal, List<Apttus_CPQApi.CPQ.SelectedOptionDO>> ();
        List<Apttus_CPQApi.CPQ.SelectedOptionDO> optionList;
        //try{
        for (Apttus_Config2__LineItem__c oLI : idToLineItemMap.values()) {

            if (oLI.Apttus_Config2__LineType__c == OPTION) {

                if (bundelLineNumberToOptionListMap.containsKey(oLI.Apttus_Config2__LineNumber__c)) {
                    optionList = bundelLineNumberToOptionListMap.get(oLI.Apttus_Config2__LineNumber__c);
                } else {
                    optionList = new List<Apttus_CPQApi.CPQ.SelectedOptionDO> ();
                }

                Apttus_CPQApi.CPQ.SelectedOptionDO objSelectedOptionDO = new Apttus_CPQApi.CPQ.SelectedOptionDO();
                objSelectedOptionDO.ComponentId = oLI.Apttus_Config2__ProductOptionId__c;
                objSelectedOptionDO.ComponentProductId = oLI.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ComponentProductId__c;
                //  objSelectedOptionDO.StartDate = oLI.Apttus_Config2__StartDate__c; //V121
                //  objSelectedOptionDO.EndDate = oLI.Apttus_Config2__EndDate__c;
                objSelectedOptionDO.Comments = oLI.Apttus_Config2__ChargeType__c;

                //Added for Usage price tier
                objSelectedOptionDO.Quantity = oLI.Apttus_Config2__Quantity__c;

                Apttus_Config2__LineItem__c oLineItem = setLineItemFieldsAll(oLI);
                objSelectedOptionDO.CustomData = oLineItem;
                objSelectedOptionDO.CustomFields = setLineItemFieldListAll();

                optionList.add(objSelectedOptionDO);
                bundelLineNumberToOptionListMap.put(oLI.Apttus_Config2__LineNumber__c, optionList);
            }
        } return bundelLineNumberToOptionListMap;
        //} catch (Exception e) {
        //    APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id), 'OM', false, true, EMAIL, true);
        //}
    }

    //@Description: method would add bundle with options
    public static void addBundleWithOptionsAll(Id cartId, Apttus_Config2__LineItem__c oLI, Integer iOrderedQuantity, Map<Decimal, List<Apttus_CPQApi.CPQ.SelectedOptionDO>> bundelLineNumberToOptionListMap) {

        Apttus_CPQApi.CPQ.AddBundleRequestDO request = new Apttus_CPQApi.CPQ.AddBundleRequestDO();
        request.CartId = cartId;
        request.SelectedBundle = new Apttus_CPQApi.CPQ.SelectedBundleDO();
        request.SelectedBundle.SelectedProduct = new Apttus_CPQApi.CPQ.SelectedProductDO();
        request.SelectedBundle.SelectedProduct.ProductId = oLI.Apttus_Config2__ProductId__c;
        request.SelectedBundle.SelectedProduct.StartDate = oLI.Apttus_Config2__StartDate__c;
        request.SelectedBundle.SelectedProduct.EndDate = oLI.Apttus_Config2__EndDate__c;
        request.SelectedBundle.SelectedProduct.Quantity = iOrderedQuantity;

        Apttus_Config2__LineItem__c oLineItem = setLineItemFieldsAll(oLI);
        request.SelectedBundle.SelectedProduct.CustomData = oLineItem;
        request.SelectedBundle.SelectedProduct.CustomFields = setLineItemFieldListAll();

        List<Apttus_CPQApi.CPQ.SelectedOptionDO> optionList = new List<Apttus_CPQApi.CPQ.SelectedOptionDO> ();

        if (!bundelLineNumberToOptionListMap.isEmpty() && bundelLineNumberToOptionListMap != null) {

            optionList = bundelLineNumberToOptionListMap.get(oLI.Apttus_Config2__LineNumber__c);
            for (Apttus_CPQApi.CPQ.SelectedOptionDO objSelectedOptionDO : optionList) {
                objSelectedOptionDO.Quantity = iOrderedQuantity;
            }
        }

        if (optionList.size() > 0) { request.SelectedBundle.SelectedOptions = optionList; }
        Apttus_CPQApi.CPQ.AddBundleResponseDO response = Apttus_CPQApi.CPQWebService.addBundle(request);
    }

    //@Description: this method copy fields from source line item to new line item
    public static Apttus_Config2__LineItem__c setLineItemFieldsAll(Apttus_Config2__LineItem__c oLI) {

        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Apttus_Config2__LineItem__c.fields.getMap();
        List<Schema.SObjectField> fieldList = fieldMap.values();
        Set<String> fieldNameSet = new Set<String> ();

        for (Schema.SObjectField sField : fieldList) {
            String sFieldName = sField.getDescribe().getName();

            //Check that Fields are Writeable
            Schema.DescribeFieldResult fd = sField.getDescribe();
            if (fd.isCreateable() && fd.isUpdateable()) { fieldNameSet.add(sFieldName); }
        }

        Apttus_Config2__LineItem__c oLineItem = new Apttus_Config2__LineItem__c();

        for (String sFieldName : fieldNameSet) {
            if (sFieldName == 'Apttus_Config2__DerivedFromId__c') {
                oLineItem.Apttus_Config2__DerivedFromId__c = oLI.Id;
            } else if (!fieldsNotToCopySet.contains(sFieldName)) {
                oLineItem.put(sFieldName, oLI.get(sFieldName));
            }
        } return oLineItem;
    }

    //@Description: this method define fields to be copied from source line item to new line item
    public static List<String> setLineItemFieldListAll() {

        List<String> listCustomFields = new List<String> ();

        new List<String> (Apttus_Config2__LineItem__c.SObjectType.getDescribe().fields.getMap().keySet());

        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Apttus_Config2__LineItem__c.fields.getMap();
        List<Schema.SObjectField> fieldList = fieldMap.values();
        Set<String> fieldNameSet = new Set<String> ();

        for (Schema.SObjectField sField : fieldList) {
            String sFieldName = sField.getDescribe().getName();

            //Check that Fields are Writeable
            Schema.DescribeFieldResult fd = sField.getDescribe();
            if (fd.isCreateable() && fd.isUpdateable()) {
                fieldNameSet.add(sFieldName);
            }
        }

        for (String sFieldName : fieldNameSet) {
            if (!fieldsNotToCopySet.contains(sFieldName)) {
                listCustomFields.add(sFieldName);
            }
        } return listCustomFields;
    }

    //@Description: fix product attribute valuse
    public static List<Apttus_Config2__ProductAttributeValue__c> updateProductAttributeValues(Map<Id, Apttus_Config2__LineItem__c> idToLineItemNewMap, Map<Id, Apttus_Config2__LineItem__c> idToLineItemOldMap) {

        Set<Id> productAttributeValueIdNewSet = new Set<Id> ();
        Set<Id> productAttributeValueIdSet = new Set<Id> ();

        for (Apttus_Config2__LineItem__c oLineItem : idToLineItemNewMap.values()) {
            productAttributeValueIdNewSet.add(oLineItem.Apttus_Config2__AttributeValueId__c);
        }

        for (Apttus_Config2__LineItem__c oLineItem : idToLineItemOldMap.values()) {
            productAttributeValueIdSet.add(oLineItem.Apttus_Config2__AttributeValueId__c);
        }

        String sQueryNew = String.format(
                                         'SELECT {0} FROM {1} WHERE Id IN :productAttributeValueIdNewSet',
                                         new String[] {
                                            String.join(
                                                        new List<String> (
                                                                          Apttus_Config2__ProductAttributeValue__c.SObjectType.getDescribe().fields.getMap().keySet() //get all fields
            ),
                                                        ','
            ),
                                            String.valueOf(Apttus_Config2__ProductAttributeValue__c.SObjectType)
                                         }
        );

        String sQueryOld = String.format(
                                         'SELECT {0} FROM {1} WHERE Id IN :productAttributeValueIdSet',
                                         new String[] {
                                            String.join(
                                                        new List<String> (
                                                                          Apttus_Config2__ProductAttributeValue__c.SObjectType.getDescribe().fields.getMap().keySet() //get all fields
            ),
                                                        ','
            ),
                                            String.valueOf(Apttus_Config2__ProductAttributeValue__c.SObjectType)
                                         }
        );

        List<Apttus_Config2__ProductAttributeValue__c> productAttributeValueNewList = Database.query(sQueryNew);
        Map<Id, Apttus_Config2__ProductAttributeValue__c> idToProductAttributeValueNewMap = new Map<Id, Apttus_Config2__ProductAttributeValue__c> (productAttributeValueNewList);

        List<Apttus_Config2__ProductAttributeValue__c> productAttributeValueOldList = Database.query(sQueryOld);
        Map<Id, Apttus_Config2__ProductAttributeValue__c> idToProductAttributeValueOldMap = new Map<Id, Apttus_Config2__ProductAttributeValue__c> (productAttributeValueOldList);

        Map<Id, Apttus_Config2__ProductAttributeValue__c> derivedFromIdToProductAttributeValueOldMap = new Map<Id, Apttus_Config2__ProductAttributeValue__c> ();

        for (Apttus_Config2__LineItem__c oLineItem : idToLineItemOldMap.values()) {

            Apttus_Config2__ProductAttributeValue__c oProductAttributeValue = idToProductAttributeValueOldMap.get(oLineItem.Apttus_Config2__AttributeValueId__c);
            if (oProductAttributeValue != null) {
                derivedFromIdToProductAttributeValueOldMap.put(oLineItem.Id, oProductAttributeValue);
            }
        }

        Map<String, Schema.SObjectField> pavFieldsNameMap = Schema.SObjectType.Apttus_Config2__ProductAttributeValue__c.fields.getMap();
        List<Schema.SObjectField> pavFieldsNameList = pavFieldsNameMap.values();
        Set<String> pavFieldsNameSet = new Set<String> ();

        for (Schema.SObjectField sPAVField : pavFieldsNameList) {
            String sFieldName = sPAVField.getDescribe().getName();

            //Check that Fields are Writeable
            Schema.DescribeFieldResult fd = sPAVField.getDescribe();
            if (fd.isCreateable() && fd.isUpdateable()) {
                pavFieldsNameSet.add(sFieldName);
            }
        }

        List<Apttus_Config2__ProductAttributeValue__c> pavToUpdateList = new List<Apttus_Config2__ProductAttributeValue__c> ();
        Set<Id> pavIdToUpdateSet = new Set<Id> ();

        for (Apttus_Config2__LineItem__c oLineItem : idToLineItemNewMap.values()) {

            Apttus_Config2__ProductAttributeValue__c oProductAttributeValueNew = idToProductAttributeValueNewMap.get(oLineItem.Apttus_Config2__AttributeValueId__c);
            if (oProductAttributeValueNew != null && !pavIdToUpdateSet.contains(oProductAttributeValueNew.Id)) {

                Apttus_Config2__ProductAttributeValue__c oProductAttributeValueOld;
                oProductAttributeValueOld = derivedFromIdToProductAttributeValueOldMap.get(oLineItem.Apttus_Config2__DerivedFromId__c);

                for (String sFieldName : pavFieldsNameSet) {
                    if (sFieldName != 'Apttus_Config2__LineItemId__c') {
                        oProductAttributeValueNew.put(sFieldName, oProductAttributeValueOld.get(sFieldName));
                    }
                }
                pavToUpdateList.add(oProductAttributeValueNew);
                pavIdToUpdateSet.add(oProductAttributeValueNew.Id);
            }
        } return pavToUpdateList;
    }

    public static List<Apttus_Config2__LineItem__c> fixNonPrimaryLines(Id cartId, Map<String, Id> productIdAndLineNumberAndChargeTypeToLIIdMap) {

        List<Apttus_Config2__LineItem__c> lineItemToUpdateList = new List<Apttus_Config2__LineItem__c> ();

        Set<Id> nonPrimaryLineIdOldSet = new Set<Id> ();

        for (Id lineItemIdOld : productIdAndLineNumberAndChargeTypeToLIIdMap.values()) {

            nonPrimaryLineIdOldSet.add(lineItemIdOld);
        }

        Map<Id, Apttus_Config2__LineItem__c> idToNPLineItemOldMap = getLineItemDataAll(nonPrimaryLineIdOldSet);
        String query;
        if (!Test.isRunningTest())
        query = String.format(
                              'SELECT {0} FROM {1} WHERE Apttus_Config2__ConfigurationId__c = :cartId AND Apttus_Config2__IsPrimaryLine__c = false',
                              new String[] {
                                 String.join(
                                             new List<String> (
                                                               Apttus_Config2__LineItem__c.SObjectType.getDescribe().fields.getMap().keySet() //get all fields
            ),
                                             ','
            ),
                                 String.valueOf(Apttus_Config2__LineItem__c.SObjectType)
                              }
        );
        else
        query = String.format(
                              'SELECT {0} FROM {1} WHERE Apttus_Config2__ConfigurationId__c = :cartId AND Apttus_Config2__IsPrimaryLine__c = false LIMIT 10',
                              new String[] {
                                 String.join(
                                             new List<String> (
                                                               Apttus_Config2__LineItem__c.SObjectType.getDescribe().fields.getMap().keySet() //get all fields
            ),
                                             ','
            ),
                                 String.valueOf(Apttus_Config2__LineItem__c.SObjectType)
                              }
        );


        List<Apttus_Config2__LineItem__c> lineItemList = Database.query(query);
        Map<Id, Apttus_Config2__LineItem__c> idToNPLineItemNewMap = new Map<Id, Apttus_Config2__LineItem__c> (lineItemList);

        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Apttus_Config2__LineItem__c.fields.getMap();
        List<Schema.SObjectField> fieldList = fieldMap.values();
        Set<String> fieldNameSet = new Set<String> ();

        for (Schema.SObjectField sField : fieldList) {
            String sFieldName = sField.getDescribe().getName();

            //Check that Fields are Writeable
            Schema.DescribeFieldResult fd = sField.getDescribe();
            if (fd.isCreateable() && fd.isUpdateable()) {
                fieldNameSet.add(sFieldName);
            }
        }

        for (Apttus_Config2__LineItem__c oLineItem : idToNPLineItemNewMap.values()) {

            String sProductIdLNAndChargeType;

            if (oLineItem.Apttus_Config2__HasOptions__c) {
                sProductIdLNAndChargeType = oLineItem.Apttus_Config2__ProductId__c + String.valueOf(oLineItem.Apttus_Config2__LineNumber__c) + oLineItem.Apttus_Config2__ChargeType__c;
            } else {
                sProductIdLNAndChargeType = oLineItem.Apttus_Config2__OptionId__c + String.valueOf(oLineItem.Apttus_Config2__LineNumber__c) + oLineItem.Apttus_Config2__ChargeType__c;
            }

            Id lineItemOldId = productIdAndLineNumberAndChargeTypeToLIIdMap.get(sProductIdLNAndChargeType);
            Apttus_Config2__LineItem__c oLineItemOld = idToNPLineItemOldMap.get(lineItemOldId);

            if (oLineItemOld != null) {

                for (String sFieldName : fieldNameSet) {
                    if (sFieldName == 'Apttus_Config2__DerivedFromId__c') {
                        oLineItem.Apttus_Config2__DerivedFromId__c = oLineItemOld.Id;
                    } else if (!fieldsNotToCopySet.contains(sFieldName)) {
                        oLineItem.put(sFieldName, oLineItemOld.get(sFieldName));
                    }
                } lineItemToUpdateList.add(oLineItem);
            }
        } return lineItemToUpdateList;
    }

    //@Description: method to create return order
    public static Apttus_Config2__Order__c createReturnOrder(Apttus_Config2__Order__c oOrder) {

        Apttus_Config2__Order__c oReturnOrder = cloneOrder(oOrder.Id);

        oReturnOrder.Apttus_Config2__Status__c = DRAFT;
        oReturnOrder.Apttus_Config2__OrderDate__c = System.today();
        oReturnOrder.Apttus_Config2__OrderStartDate__c = System.today();
        oReturnOrder.Apttus_Config2__OrderEndDate__c = System.today();
        oReturnOrder.Apttus_Config2__PricingDate__c = System.today();
        oReturnOrder.Apttus_Config2__ActivatedDate__c = null;
        oReturnOrder.Apttus_Config2__FulfilledDate__c = null;
        oReturnOrder.Apttus_Config2__ReadyForBillingDate__c = null;
        oReturnOrder.Apttus_Config2__ReadyForRevRecDate__c = null;
        oReturnOrder.Apttus_Config2__CancelledDate__c = null;
        oReturnOrder.APTS_Order_Type__c = STANDARD_ORDER;
        oReturnOrder.APTS_Order_Sub_Type__c = STANDARD_RETURN;
        //oReturnOrder.APTS_Order_Reason__c = ZD1;
        oReturnOrder.APTS_SAP_OrderType__c = XB01;
        oReturnOrder.Apttus_Config2__Type__c = APTS_NEW;
        oReturnOrder.Apttus_Config2__ParentOrderId__c = oOrder.Id;
        oReturnOrder.APTS_Order_Header_SAP_ID__c = null;
        oReturnOrder.APTS_ATP_Check_Status__c = null;
        oReturnOrder.APTS_ATP_Check_Message__c = null;
        oReturnOrder.APTS_Picking_Status__c = null;
        oReturnOrder.APTS_POD_Status__c = null;
        oReturnOrder.APTS_GoodsIssue_Status__c = null;
        //V115 ++ <<
        oReturnOrder.Approval_Status__c = null;
        oReturnOrder.OwnerId = UserInfo.getUserId();
        //V115 ++ >>
        oReturnOrder.APTS_Requested_Delivery_Date__c = APTS_OrderUtils.getRequestedDeliveryDate();
        oReturnOrder.Apttus_Config2__PricingDate__c = system.today();

        return oReturnOrder;
    }

    //@Description: method to start order trigger
    public static TriggerSettings__c getTriggerSettings() {

        TriggerSettings__c oTriggerSettings;
        Id userProfileId = userinfo.getProfileId();
        List<TriggerSettings__c> triggerSettingsList = [SELECT Id, APTS_Order_Trigger__c, APTS_OrderLineItemTrigger__c, AssetLineItemTrigger__c FROM TriggerSettings__c WHERE SetupOwnerId = :userProfileId LIMIT 1];
        //try{
        if (!triggerSettingsList.isEmpty()) {
            oTriggerSettings = triggerSettingsList.get(0);
        } return oTriggerSettings;
        //} catch (Exception e) {
        //    APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id), 'OM', false, true, EMAIL, true);
        //}  
    }

    //@Description: method to start order trigger
    public static void startOrderTrigger() {

        APTS_OrderTriggerHandler.setTriggerDisabled(false);
    }

    //@Description: method to stop order trigger
    public static void stopOrderTrigger() {
        APTS_OrderTriggerHandler.setTriggerDisabled(true);
    }

    //@Description: method to start order trigger
    public static void startOrderLineItemTrigger() {

        APTS_OrderLineItemTriggerHandler.setTriggerDisabled(false);
    }

    //@Description: method to stop order trigger
    public static void stopOrderLineItemTrigger() {

        APTS_OrderLineItemTriggerHandler.setTriggerDisabled(true);
    }

    //@Description: method to start order trigger
    public static void startAssetLineItemTrigger() {

        APTS_AssetLineItemTriggerHandler.isTriggerDisabled = false;
    }

    //@Description: method to stop order trigger
    public static void stopAssetLineItemTrigger() {

        APTS_AssetLineItemTriggerHandler.isTriggerDisabled = true;
    }

    //v101++<<
    //@Description: Method would return cloned Order Header instance without Inserting new Order
    public static Apttus_Config2__Order__c cloneOrderHeader(Apttus_Config2__Order__c oOrder) {

        Apttus_Config2__Order__c oCloneOrder = oOrder.clone(false, false, false, false);

        oCloneOrder.Apttus_Config2__Status__c = DRAFT;
        oCloneOrder.Apttus_Config2__OrderDate__c = System.today();
        oCloneOrder.Apttus_Config2__OrderStartDate__c = System.today();
        oCloneOrder.Apttus_Config2__OrderEndDate__c = System.today();
        oCloneOrder.Apttus_Config2__PricingDate__c = System.today();
        oCloneOrder.Apttus_Config2__ActivatedDate__c = null;
        oCloneOrder.Apttus_Config2__FulfilledDate__c = null;
        oCloneOrder.Apttus_Config2__ReadyForBillingDate__c = null;
        oCloneOrder.Apttus_Config2__ReadyForRevRecDate__c = null;
        oCloneOrder.Apttus_Config2__CancelledDate__c = null;

        return oCloneOrder;
    }

    //@Description: Method call updatePriceForCart API to Reprice cart
    public static Boolean repriceCart(Id cartId) {

        Apttus_CpqApi.CPQ.UpdatePriceRequestDO objUpdatePriceRequestDO = new Apttus_CpqApi.CPQ.UpdatePriceRequestDO();
        objUpdatePriceRequestDO.CartId = cartId;
        Apttus_CpqApi.CPQ.UpdatePriceResponseDO objUpdatePrice = Apttus_CpqApi.CPQWebService.updatePriceForCart(objUpdatePriceRequestDO);

        return objUpdatePrice.IsPricePending;
    }

    //@Description: Method call finalizeConfiguration API to Finalize cart
    public static void finalizeCart(Id cartId) {

        Apttus_Config2.CPQWebService.finalizeConfiguration(cartID);
    }

    //@Description: Method call synchronizeCart API which sync up lineItems with orderLineItems
    public static Boolean syncCart(Id cartId) {

        Apttus_Config2.CPQStruct.SynchronizeCartRequestDO request = new Apttus_Config2.CPQStruct.SynchronizeCartRequestDO();
        request.CartId = cartId;
        Apttus_Config2.CPQStruct.SynchronizeCartResponseDO result = Apttus_Config2.OrderWebService.synchronizeCart(request);

        return result.IsSuccess;
    }

    //@Description: Method call Accept Order API
    public static Boolean acceptOrder(Id orderId) {

        Apttus_Config2.CPQStruct.AcceptOrderRequestDO oAcceptOrderRequestDO = new Apttus_Config2.CPQStruct.AcceptOrderRequestDO();
        oAcceptOrderRequestDO.OrderId = orderId;
        Apttus_Config2.CPQStruct.AcceptOrderResponseDO oAcceptOrderResponseDO = Apttus_Config2.OrderWebService.acceptOrder(oAcceptOrderRequestDO);

        return oAcceptOrderResponseDO.IsSuccess;
    }

    //Change assets - call changeAssets API
    public static Map<Id, Apttus_Config2__LineItem__c> changeAssets(Id cartId, List<Id> assetIdList) {

        Apttus_Config2.CPQStruct.ChangeAssetsRequestDO changeRequest = new Apttus_Config2.CPQStruct.ChangeAssetsRequestDO();
        changeRequest.AssetIds = assetIdList;
        changeRequest.CartId = cartId;

        Apttus_Config2.CPQStruct.ChangeAssetsResponseDO changeResponse = Apttus_Config2.AssetService.changeAssets(changeRequest);

        if (changeResponse.Errors != null && !changeResponse.Errors.isEmpty()) {

            for (String sErr : changeResponse.Errors) {

                throw new applicationException(sErr);
            }
        } return changeResponse.LineItemMap;
    }

    //Cancel assets - call cancelAssets API
    public static Map<Id, Apttus_Config2__LineItem__c> cancelAssets(Id cartId, List<Id> assetIdList) {

        Apttus_Config2.CPQStruct.CancelAssetsRequestDO cancelRequest = new Apttus_Config2.CPQStruct.CancelAssetsRequestDO();
        cancelRequest.CancelDate = System.today();
        cancelRequest.AssetIds = assetIdList;
        cancelRequest.CartId = cartId;

        Apttus_Config2.CPQStruct.CancelAssetsResponseDO cancelResponse = Apttus_Config2.AssetService.cancelAssets(cancelRequest);

        if (cancelResponse.Errors != null && !cancelResponse.Errors.isEmpty()) {

            for (String sErr : cancelResponse.Errors) {
                throw new applicationException(sErr);
            }
        } return cancelResponse.LineItemMap;
    }

    public class applicationException extends Exception { }

    //@Description: Method would save cart / save configuration
    public static Apttus_Config2__ProductConfiguration__c saveCart(Id cartId) {

        Apttus_Config2__ProductConfiguration__c oCartObj = new Apttus_Config2__ProductConfiguration__c();
        oCartObj.Id = cartId;
        oCartObj.Apttus_Config2__Status__c = SAVED;
        oCartObj.Apttus_Config2__IsPricePending__c = true;

        return oCartObj;
    }

    //@Description: Method to submit the order and to create a intergrationloglist
    public static void submitOrder(Id orderId) {

        if (String.isNotBlank(orderId)) {
            Set<Id> setOrderId = new Set<Id> ();
            setOrderId.add(orderId);
            submitMultipleOrders(setOrderId);
        }
    }

    //@Description: Method to submit multiple orders and to create a intergrationloglist
    public static void submitMultipleOrders(Set<Id> setOrderId) {
        List<Apttus_Config2__Order__c> orderList = [
                                                    SELECT Id, Apttus_Config2__Status__c, APTS_Status__c, Apttus_Config2__PreviousVersion__c,
                                                    Apttus_Config2__SoldToAccountId__c, Apttus_Config2__SoldToAccountId__r.SAP_Customer_Id__c,
                                                    Apttus_Config2__SoldToAccountId__r.RecordType.Name, Apttus_Config2__SoldToAccountId__r.Parent_Change_Indicator__c,
                                                    Apttus_Config2__SoldToAccountId__r.Parent_Valid_From__c, Apttus_Config2__SoldToAccountId__r.Parent_Valid_To__c
                                                    FROM Apttus_Config2__Order__c
                                                    WHERE Id IN :setOrderId];
        submitMultipleOrders(false, orderList);
    }

    //@Description: Method to submit multiple orders and to create a intergrationloglist
    public static void submitMultipleOrders(Boolean bSkipAccept, List<Apttus_Config2__Order__c> orderList) {
        //try{
        if (!orderList.isEmpty()) {
            List<Integration_Log__c> listIntegrationLog = new List<Integration_Log__c> ();
            for (Apttus_Config2__Order__c oOrder : orderList) {
                //Create Integration Log
                Integration_Log__c oIntegrationLog = new Integration_Log__c(Object_Id__c = oOrder.Id,
                                                                            Object__c = ORDER, Integration_Status__c = INT_Constants.INITIAL,
                                                                            Account__c = oOrder.Apttus_Config2__SoldToAccountId__c, Order__c = oOrder.Id);
                listIntegrationLog.add(oIntegrationLog);
                if (oOrder.Apttus_Config2__SoldToAccountId__r.SAP_Customer_Id__c == null && oOrder.Apttus_Config2__SoldToAccountId__r.RecordType.Name == PROSPECT &&
                    oOrder.Apttus_Config2__SoldToAccountId__r.Parent_Valid_From__c == null && oOrder.Apttus_Config2__SoldToAccountId__r.Parent_Valid_To__c == null && oOrder.Apttus_Config2__SoldToAccountId__r.Parent_Change_Indicator__c != 'I') {
                    listIntegrationLog.add(new Integration_Log__c(Object_Id__c = oOrder.Apttus_Config2__SoldToAccountId__c,
                                                                  Object__c = ACCOUNT_HIERARCHY,
                                                                  Integration_Status__c = INT_Constants.INITIAL,
                                                                  Account__c = oOrder.Apttus_Config2__SoldToAccountId__c,
                                                                  Order__c = oOrder.Id));
                }

                if (!bSkipAccept) {
                    //Accept order will set status to pending on order and order line items
                    acceptOrder(oOrder.Id);
                }
            }

            if (!listIntegrationLog.isEmpty()) {
                Database.insert(listIntegrationLog);
            }
        }
        //} catch (Exception e) {
        //    APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id), 'OM', false, true, EMAIL, true);
        //}
    }

    public static List<Apttus_Config2__OrderLineItem__c> clearATPResultsMultiOrders(Set<Id> setOrderId) {

        List<Apttus_Config2__OrderLineItem__c> orderLineItemList = [
                                                                    SELECT Id, APTS_Expected_Delivery_Quantity__c, APTS_Expected_Delivery_Date__c, APTS_ATP_Cleared__c,
                                                                    APTS_Requested_Delivery_Date__c, Apttus_Config2__OrderId__r.APTS_Requested_Delivery_Date__c,
                                                                    APTS_Requested_Installation_Date__c, Apttus_Config2__OrderId__r.APTS_Requested_Installation_Date__c
                                                                    FROM Apttus_Config2__OrderLineItem__c
                                                                    WHERE Apttus_Config2__OrderId__c IN :setOrderId AND APTS_Item_Relevant_for_SAP__c = true];
        // v109 -- APTS_Expected_Delivery_Quantity__c != null AND APTS_Expected_Delivery_Date__c != null];
        // v110 -- AND APTS_ATP_Cleared__c =  false

        try {
            for (Apttus_Config2__OrderLineItem__c oOrderLineItem : orderLineItemList) {

                oOrderLineItem.APTS_Requested_Delivery_Date__c = oOrderLineItem.Apttus_Config2__OrderId__r.APTS_Requested_Delivery_Date__c;
                oOrderLineItem.APTS_Requested_Installation_Date__c = oOrderLineItem.Apttus_Config2__OrderId__r.APTS_Requested_Installation_Date__c;
                oOrderLineItem.APTS_Expected_Delivery_Quantity__c = null;
                oOrderLineItem.APTS_Expected_Delivery_Date__c = null;
                oOrderLineItem.APTS_ATP_Cleared__c = false;
            }
        } catch(Exception e) {
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString(), 'Order', null, 'OM', false, true, null, true);
        }
        return orderLineItemList;
    }

    //@Description: Method to create a intergrationloglist
    public static Integration_Log__c createIntegrationLog(Apttus_Config2__Order__c oOrder) {

        //Create Integration Log
        Integration_Log__c oIntegrationLog = new Integration_Log__c(Object_Id__c = oOrder.Id,
                                                                    Object__c = ORDER, Integration_Status__c = INT_Constants.INITIAL, Account__c = oOrder.Apttus_Config2__SoldToAccountId__c, Order__c = oOrder.Id);
        return oIntegrationLog;
    }

    //Description : Method to call Amend Order API
    public static ID amendOrder(String amendOrdId) {
        ID newOrderId = null;
        // try {
        Apttus_Config2.CPQStruct.AmendOrderRequestDO request = new Apttus_Config2.CPQStruct.AmendOrderRequestDO();
        request.OrderId = amendOrdId;
        Apttus_Config2.CPQStruct.AmendOrderResponseDO response = Apttus_Config2.OrderWebService.AmendOrder(request);
        newOrderId = response.AmendOrderSO.Id;
        //} catch (Exception e) {
        //    APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id), 'OM', false, true, EMAIL, true);
        //}
        return newOrderId;
    }

    //Description : Method would, add AgreementLineItem (Standalone or Bundle) To cart
    public static Decimal addAgreementLineItemToCart(Id cartId, Apttus__AgreementLineItem__c oAgreementLineItem, List<Apttus__AgreementLineItem__c> listOptionAgLineItems) {

        Decimal dclineNumber = NULL;
        //try{
        if (String.isNotBlank(oAgreementLineItem.Apttus__ProductId__c)) {
            List<Decimal> listLineNumbers = new List<Decimal> ();
            if (STANDALONE.equalsIgnoreCase(oAgreementLineItem.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c)) {
                //Add Standalone Product
                Apttus_CPQApi.CPQ.SelectedProductDO sProd = NULL;
                List<Apttus_CPQApi.CPQ.SelectedProductDO> listStandaloneProduct = new List<Apttus_CPQApi.CPQ.SelectedProductDO> ();

                //get wrapper to add standalone product
                sProd = getStandaloneWrapper(oAgreementLineItem);
                if (sProd != NULL) {
                    listStandaloneProduct.add(sProd);
                }

                if (!listStandaloneProduct.isEmpty()) {
                    Apttus_CPQApi.CPQ.AddMultiProductResponseDO response = addMultiProducts(listStandaloneProduct, cartId);
                    if (response.LineNumbers != NULL && !response.LineNumbers.isEmpty()) {
                        dclineNumber = response.LineNumbers[0];
                    }
                }
            } else {
                //Add Bundle Product
                List<Apttus_CPQApi.CPQ.SelectedOptionDO> listOptions = NULL;
                if (listOptionAgLineItems != NULL && !listOptionAgLineItems.isEmpty()) {
                    listOptions = new List<Apttus_CPQApi.CPQ.SelectedOptionDO> ();
                    for (Apttus__AgreementLineItem__c oAGOptionLineItem : listOptionAgLineItems) {
                        if (oAGOptionLineItem.Apttus_CMConfig__IsPrimaryLine__c && OPTION.equalsIgnoreCase(oAGOptionLineItem.Apttus_CMConfig__LineType__c)) {
                            Apttus_CPQApi.CPQ.SelectedOptionDO objSelectedOptionDO = getOptionLineforAPI(oAGOptionLineItem);
                            listOptions.add(objSelectedOptionDO);
                        }
                    }
                }

                Apttus_CPQApi.CPQ.AddBundleRequestDO oBundleRequest = getBundleLineForAPI(cartId, oAgreementLineItem, listOptions);
                if (oBundleRequest != NULL) {
                    Apttus_CPQApi.CPQ.AddBundleResponseDO oBundleResponse = Apttus_CPQApi.CPQWebService.addBundle(oBundleRequest);
                    if (oBundleResponse != NULL && oBundleResponse.LineNumber > 0) {
                        dclineNumber = oBundleResponse.LineNumber;
                    }
                }
            }
        } return dclineNumber;
        //} catch (Exception e) {
        //    APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id), 'OM', false, true, EMAIL, true);
        //}    
    }

    //Description : Method would,return standalone wrapper to add product to cart via API from AgreementLineItem data
    public static Apttus_CPQApi.CPQ.SelectedProductDO getStandaloneWrapper(Apttus__AgreementLineItem__c oAGLine) {

        Apttus_CPQApi.CPQ.SelectedProductDO selProdDO = new Apttus_CPQApi.CPQ.SelectedProductDO();
        selProdDO.StartDate = null;
        selProdDO.EndDate = null;
        selProdDO.ProductID = oAGLine.Apttus__ProductId__c;
        selProdDO.Comments = oAGLine.Apttus_CMConfig__Comments__c;
        selProdDO.Quantity = oAGLine.Apttus__Quantity__c;
        selProdDO.CustomFields = getCustomLIFieldList();
        selProdDO.CustomData = getCustomLIData(oAGLine);

        return selProdDO;
    }

    //Description : method return option object to add via API from AgreementLineItem data
    public static Apttus_CPQApi.CPQ.SelectedOptionDO getOptionLineforAPI(Apttus__AgreementLineItem__c oAGLine) {

        Apttus_CPQApi.CPQ.SelectedOptionDO objSelectedOptionDO = new Apttus_CPQApi.CPQ.SelectedOptionDO();
        objSelectedOptionDO.ComponentId = oAGLine.Apttus_CMConfig__ProductOptionId__c;
        objSelectedOptionDO.ComponentProductId = oAGLine.Apttus_CMConfig__ProductOptionId__r.Apttus_Config2__ComponentProductId__c;
        objSelectedOptionDO.StartDate = null;
        objSelectedOptionDO.EndDate = null;
        objSelectedOptionDO.Comments = SUBSCRIPTION_ORDER;
        objSelectedOptionDO.CustomFields = getCustomLIFieldList();
        objSelectedOptionDO.CustomData = getCustomLIData(oAGLine);

        return objSelectedOptionDO;
    }

    //Description : method return bundle object to add via API from AgreementLineItem data
    public static Apttus_CPQApi.CPQ.AddBundleRequestDO getBundleLineForAPI(Id cartId, Apttus__AgreementLineItem__c oAGLine, List<Apttus_CPQApi.CPQ.SelectedOptionDO> listOptions) {

        Apttus_CPQApi.CPQ.AddBundleRequestDO addBundleRequest = new Apttus_CPQApi.CPQ.AddBundleRequestDO();
        addBundleRequest.CartId = cartId;
        addBundleRequest.SelectedBundle = new Apttus_CPQApi.CPQ.SelectedBundleDO();
        addBundleRequest.SelectedBundle.SelectedProduct = new Apttus_CPQApi.CPQ.SelectedProductDO();
        addBundleRequest.SelectedBundle.SelectedProduct.ProductId = oAGLine.Apttus__ProductId__c;
        addBundleRequest.SelectedBundle.SelectedProduct.StartDate = null;
        addBundleRequest.SelectedBundle.SelectedProduct.EndDate = null;
        addBundleRequest.SelectedBundle.SelectedProduct.Quantity = oAGLine.Apttus__Quantity__c;
        addBundleRequest.SelectedBundle.SelectedProduct.CustomFields = getCustomLIFieldList();
        addBundleRequest.SelectedBundle.SelectedProduct.CustomData = getCustomLIData(oAGLine);

        //try{
        if (NULL != listOptions && !listOptions.isEmpty()) {
            addBundleRequest.SelectedBundle.SelectedOptions = listOptions;
        } return addBundleRequest;
        //} catch (Exception e) {
        //    APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id), 'OM', false, true, EMAIL, true);
        //}   
    }

    //Description : method return bundle object to add via API from AgreementLineItem data
    private static List<String> getCustomLIFieldList() {

        List<String> listCustomFields = new List<String> ();
        //listCustomFields.add('Apttus_Config2__ChargeType__c');
        //listCustomFields.add('Apttus_Config2__SellingFrequency__c');
        listCustomFields.add('Apttus_Config2__ClassificationId__c');
        listCustomFields.add('Apttus_Config2__ClassificationHierarchy__c');
        listCustomFields.add('Apttus_Config2__AdjustmentType__c');
        listCustomFields.add('Apttus_Config2__AdjustmentAmount__c');
        listCustomFields.add('APTS_Agreement_Line_Item__c');
        listCustomFields.add('Apttus_Config2__SellingUom__c');
        return listCustomFields;
    }

    // Description : method return bundle object to add via API from AgreementLineItem data
    private static Apttus_Config2__LineItem__c getCustomLIData(Apttus__AgreementLineItem__c oAGLine) {

        Apttus_Config2__LineItem__c oCustomLineItemData = new Apttus_Config2__LineItem__c();
        //oCustomLineItemData.Apttus_Config2__ChargeType__c = oAGLine.Apttus_CMConfig__ChargeType__c;
        //oCustomLineItemData.Apttus_Config2__SellingFrequency__c = oAGLine.Apttus_CMConfig__SellingFrequency__c;
        oCustomLineItemData.Apttus_Config2__ClassificationId__c = oAGLine.Apttus_CMConfig__ClassificationId__c;
        oCustomLineItemData.Apttus_Config2__ClassificationHierarchy__c = oAGLine.Apttus_CMConfig__ClassificationHierarchy__c;
        oCustomLineItemData.Apttus_Config2__AdjustmentType__c = oAGLine.Apttus_CMConfig__AdjustmentType__c;
        oCustomLineItemData.Apttus_Config2__AdjustmentAmount__c = oAGLine.Apttus_CMConfig__AdjustmentAmount__c;
        oCustomLineItemData.APTS_Agreement_Line_Item__c = oAGLine.Id;
        oCustomLineItemData.Apttus_Config2__SellingUom__c = oAGLine.Apttus_CMConfig__SellingUom__c;
        return oCustomLineItemData;
    }

    //Method to get Task list
    /*public static List<Task> getTaskList(List<Apttus_Config2__Order__c> listOrders) {
     
      List<task> listTasks = new List<task>();
      String userId = UserInfo.getUserId();
      //try{
      for (Apttus_Config2__Order__c oOrdr : listOrders) {
      Task newtask = new Task(whatid = oOrdr.Id,
      Status = TASK_OPEN, OwnerId = userId,
      Subject = SUBSCRIPTION_ORDER,
      ActivityDate = System.today(),
      Guidance__c = SUBSCRIPTION_TASK_GUIDANCE);
      listTasks.add(newtask);
      }
      //} catch (Exception e) {
      //    APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id), 'OM', false, true, EMAIL, true);
      //}
      return listTasks;
      }*/

    //v103 << ++
    /* Def #22879 #23415*/
    public static Boolean checkAdjLIYOCIYOFTValue(Apttus_Config2__OrderLineItem__c oOrderLineItem, Map<Id, Apttus_Config2__AdjustmentLineItem__c> adjustmentLineItemMap, Boolean isYOCI) {
        Boolean bCheckYOCIYOFT = false;
        string condType = isYOCI ? 'YOCI' : 'YOFT';
        List<Apttus_Config2__AdjustmentLineItem__c> lstAdjustmentLines = new List<Apttus_Config2__AdjustmentLineItem__c> ();
        for (Apttus_Config2__AdjustmentLineItem__c adjLI : adjustmentLineItemMap.Values()) {
            if (condType == adjLI.Apttus_Config2__SubType__c && adjLI.Apttus_Config2__LineItemId__r.Apttus_Config2__LineNumber__c == oOrderLineItem.Apttus_Config2__LineNumber__c) {
                if (oOrderLineItem.Apttus_Config2__DerivedFromId__c == adjLI.Apttus_Config2__LineItemId__c) {
                    bCheckYOCIYOFT = true;
                    break;
                }
            } //v101 Start
        } return bCheckYOCIYOFT;
    }
    /*Def 22879 #23415*/
    //v103 ++ >>
    // V104 -->>

    public static String getItemCategory(Map<Id, APTS_ItemCategoryDetermination__c> itemCategoryDeterminationMap, Apttus_Config2__OrderLineItem__c oOrderLineItem, Boolean bAdjLIYOCI, Boolean bAdjLIYOFT) {

        String itemCategory = null;
        //V124 - enabled below logic for XD01,V126 
        String contractType = ((oOrderLineItem.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c == 'XD01' || oOrderLineItem.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c == 'XD09' || oOrderLineItem.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c == 'XD12' || oOrderLineItem.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c == 'XC09') ? oOrderLineItem.APTS_Type_Of_Contract__c : oOrderLineItem.APTS_Type_Of_Contract_IC__c);
        String chargeType = oOrderLineItem.Apttus_Config2__ChargeType__c;
        String sSAPOrderType = oOrderLineItem.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c;

        for (APTS_ItemCategoryDetermination__c oItemCategoryDetermination : itemCategoryDeterminationMap.values()) {

            Boolean bContractType = oItemCategoryDetermination.APTS_Type_Of_Contract__c == contractType;
            Boolean bChargeType = oItemCategoryDetermination.APTS_Charge_Type__c == oOrderLineItem.Apttus_Config2__ChargeType__c;
            Boolean bZX10 = oItemCategoryDetermination.APTS_ZX10__c == 'N/A' || oItemCategoryDetermination.APTS_ZX10__c == String.valueOf(oOrderLineItem.APTS_ZX10__c);
            String sSAPOrderTypeList = oItemCategoryDetermination.APTS_SAP_Order_Type_List__c;
            Boolean bContainsSAPOrderType = false;
            Boolean bICDandYOCI = (String.isNotBlank(oItemCategoryDetermination.YOCI_YOFT__c) && oItemCategoryDetermination.YOCI_YOFT__c == 'YOCI') && bAdjLIYOCI;

            if (sSAPOrderTypeList != null && sSAPOrderType != null) {
                bContainsSAPOrderType = sSAPOrderTypeList.contains(sSAPOrderType);
            }

            //21Aug2018 - Aarthi added below to bypass the SAP Order Type check in case of Trial, since the SAPOrder TYpe is updated to XA23 from XA13 after this stage.
            if (bContractType && bChargeType && !bContainsSAPOrderType && contractType != null && contractType == TRIAL && sSAPOrderTypeList.contains(XA23)) {
                bContainsSAPOrderType = true;
            }

            if (bContractType && bChargeType && bZX10 && bContainsSAPOrderType && bAdjLIYOCI) {
                if (bICDandYOCI) {
                    itemCategory = oItemCategoryDetermination.APTS_Item_Category__c;
                    if (itemCategory != null) break;
                }
            } else if (bContractType && bChargeType && bContainsSAPOrderType && !bICDandYOCI) {

                if (bAdjLIYOFT && oItemCategoryDetermination.APTS_ZX10__c != '100') {
                    itemCategory = oItemCategoryDetermination.APTS_Item_Category__c;
                    oOrderLineItem.APTS_ZX10__c = 100;
                    oOrderLineItem.APTS_Item_Category_Adjustment__c = 'YOFT';
                    if (itemCategory != null) break;
                }
                else { //v120 - Setting Item Category for 'Free of Charge'. 
                    if (bZX10 && oItemCategoryDetermination.YOCI_YOFT__c != 'YOCI') {
                        itemCategory = oItemCategoryDetermination.APTS_Item_Category__c;
                        if (itemCategory != null) break;
                    }
                    else if (!bZX10 && oOrderLineItem.APTS_Is_Primary_L1_Line__c && contractType == 'Free On Loan') {
                        itemCategory = oItemCategoryDetermination.APTS_Item_Category__c;
                        if (itemCategory != null) break;
                    }
                }
            }
        }
        //v114  ++<< >>
        if (String.isBlank(itemCategory) || itemCategory == 'BLANK')
        {
            //V112++ <<
            if (sSAPOrderType == 'XD12' && oOrderLineItem.Apttus_Config2__BasePriceOverride__c == 0 && oOrderLineItem.Apttus_Config2__ChargeType__c == 'Usage Fee') {
                itemCategory = 'A02';
            }
            //V112++ >>
            else if (String.valueOf(oOrderLineItem.APTS_ZX10__c) == null)
            {
                if (oOrderLineItem.Apttus_Config2__OrderId__r.APTS_Order_Type__c == 'Standard Order' && oOrderLineItem.Apttus_Config2__NetPrice__c == 0 && !(oOrderLineItem.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c == 'Standard Return' || oOrderLineItem.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c == 'Unplanned Return'))
                {
                    itemCategory = 'A02';
                }
                else if (oOrderLineItem.Apttus_Config2__OrderId__r.APTS_Order_Type__c == 'Machine Order' && oOrderLineItem.Apttus_Config2__NetPrice__c == 0) {
                    itemCategory = oOrderLineItem.Apttus_Config2__ChargeType__c == 'Rental Fee' ? 'A03' : 'A04';
                } //v119 - Removing Charge type check for XD09 
                else if (sSAPOrderType == 'XD09' && oOrderLineItem.Apttus_Config2__NetPrice__c == 0 && oOrderLineItem.Apttus_Config2__LineType__c == LINETYPE_OPTION && oOrderLineItem.Apttus_Config2__ChargeType__c == 'Service Fee') { //V123 ++ <<>>
                    itemCategory = 'A09';
                }
                if (sSAPOrderType == 'XD12' && oOrderLineItem.APTS_Net_List_Price__c == 0 && oOrderLineItem.Apttus_Config2__ChargeType__c == 'Additional Service Fee' && String.valueOf(oOrderLineItem.APTS_ZX10__c) == null) {
                    itemCategory = 'A01';
                }
            }




        } return itemCategory;
    }


    public static Boolean getItemRelevancy(Map<Id, APTS_ItemRelevancyDetermination__c> itemRelevancyDeterminationMap, Apttus_Config2__OrderLineItem__c oOrderLineItem) {

        Boolean bIsRelevant = false;
        Boolean bCheckFreightCharge = false;
        //31 Oct 2018 - Aarthi - Modified below for CR 2079, V124
        string oLIContractType = (oOrderLineItem.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c == 'XD01' || oOrderLineItem.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c == 'XD09' || oOrderLineItem.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c == 'XD12') ? oOrderLineItem.APTS_Type_of_contract__c : oOrderLineItem.Apttus_Config2__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Type_of_contract__c;

        for (APTS_ItemRelevancyDetermination__c oItemRelevancyDetermination : itemRelevancyDeterminationMap.values()) {

            Boolean bContractType = oItemRelevancyDetermination.APTS_Contract_Type__c == 'N/A' || oItemRelevancyDetermination.APTS_Contract_Type__c == oLIContractType;
            Boolean bChargeType = oItemRelevancyDetermination.APTS_Charge_Type__c == oOrderLineItem.Apttus_Config2__ChargeType__c;
            String sSAPOrderTypeList = oItemRelevancyDetermination.APTS_SAP_Order_Type_List__c;
            String sSAPOrderType = oOrderLineItem.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c;
            Boolean bContainsSAPOrderType = false;
            if (sSAPOrderTypeList != null && sSAPOrderType != null) {
                bContainsSAPOrderType = sSAPOrderTypeList.contains(sSAPOrderType);
            }
            //16Aug2018 - Aarthi added below to bypass the SAP Order Type check in case of Trial, since the SAPOrder TYpe is updated to XA23 from XA13 after this stage. //&& sSAPOrderType == 'XA13'
            if (bContractType && bChargeType && !bContainsSAPOrderType && oLIContractType != null && oLIContractType == TRIAL && sSAPOrderTypeList.contains(XA23)) {
                bContainsSAPOrderType = True;
            }
            if (oOrderLineItem.Apttus_Config2__ProductId__r.APTS_Not_relevant_for_SAP__c == TRUE && (oOrderLineItem.Apttus_Config2__BasePrice__c == NULL || oOrderLineItem.Apttus_Config2__BasePrice__c == 0)) {
                bCheckFreightCharge = true;
            }

            bIsRelevant = bContractType && bChargeType && bContainsSAPOrderType && (!bCheckFreightCharge);
            if (bIsRelevant) break;
        } return bIsRelevant;
    }
    //check OrderLines if it satisfies the condition for adjustment Type ZX10
    // Moved the methods from APTS_OrderLineItemTriggerHandler to APTS_OrderUtils
    // V104 ++ <<- Defect # 23566 set the new field Item Category Adjustment based on the Adjustment Sub Type


    //v102 ++ << Method for calculating Delivery TimeFrames in OLI
    public static String getDeliveryTimeframes(Apttus_Config2__OrderLineItem__c oLI, Apttus_Config2__AccountLocation__c acctLoc) {
        system.debug('getDeliveryTimeframes--------' + acctLoc);
        String deliveryFrames = null;
        if (oLI != null && oLI.Apttus_Config2__LocationId__c != null && oLI.APTS_Requested_Delivery_Date__c != null) {

            Date reqDeliveryDate = oLI.APTS_Requested_Delivery_Date__c;
            Datetime reqDeliveryDatetime = (Datetime) reqDeliveryDate;
            String dayOfWeek = reqDeliveryDatetime.format('EEEE');

            List<String> fieldList = new List<String> { dayOfWeek + '_Morning_From_Receiving__c', dayOfWeek + '_Morning_To_Receiving__c', dayOfWeek + '_Afternoon_From_Receiving__c', dayOfWeek + '_Afternoon_To_Receiving__c' };

            String morning_to = fieldList.get(0);
            String morning_from = fieldList.get(1);
            String afternoon_to = fieldList.get(2);
            String afternoon_from = fieldList.get(3);

            if (acctLoc != NULL) {
                deliveryFrames = acctLoc.get(morning_to) + ' - ' + acctLoc.get(morning_from) + '; ' + acctLoc.get(afternoon_to) + ' - ' + acctLoc.get(afternoon_from);
            }
        } return deliveryFrames;
    }
    //v102 ++>>
    //v105 ++<< 
    public static Boolean checkfreefreight(Id cartID) {
        Boolean freefreight = false;
        Id agreementRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Consumption Model').getRecordTypeId(); //V121 ++ <<>>
        for (Apttus_Config2__ProductConfiguration__c config :[SELECT Apttus_Config2__AccountId__r.APTS_Free_Freight_Charges__c, Apttus_Config2__OrderId__r.Apttus_CMConfig__AgreementId__r.RecordTypeId
             FROM Apttus_Config2__ProductConfiguration__c
             WHERE ID = :cartId]) {
            freefreight = config.Apttus_Config2__AccountId__r.APTS_Free_Freight_Charges__c;
            //V121 ++ <<
            if (config.Apttus_Config2__OrderId__r.Apttus_CMConfig__AgreementId__r.RecordTypeId != null)
            {
                Boolean isConsumptionContract = (agreementRecordTypeId == config.Apttus_Config2__OrderId__r.Apttus_CMConfig__AgreementId__r.RecordTypeId);
                if (!freefreight && isConsumptionContract)
                freefreight = isConsumptionContract;
            } //V121 ++ >>
        }
        return freefreight;
    }
    //v105 -->>

    //V116 ++<<
    public static List<APTS_AdjustmentLIWrapper> getRelatedAdjustments(set<ID> lineItemIdSet, set<ID> assetIdSet, set<ID> ordLineItemIdSet)
    {
        Map<Id, sObject> adjLineItemMap = new Map<Id, sObject> ();
        Map<Id, Apttus_Config2__OrderAdjustmentLineItem__c> ordAdjustmentLineItemMap = APTS_OrderLineItemDAO.getOrderAdjustmentLineItems(ordLineItemIdSet);
        adjLineItemMap.putAll(ordAdjustmentLineItemMap);
        Map<Id, Apttus_Config2__AdjustmentLineItem__c> adjustmentLineItemMap = APTS_OrderLineItemDAO.getAdjustmentLineItems(lineItemIdSet);
        adjLineItemMap.putAll(adjustmentLineItemMap);
        Map<Id, Apttus_Config2_AssetAdjustItem__c> assetAdjustmentLineItemMap = APTS_OrderLineItemDAO.getAssetAdjustmentLineItems(assetIdSet);
        adjLineItemMap.putAll(assetAdjustmentLineItemMap);
        system.debug('ordLineItemIdSet:: ' + ordLineItemIdSet);
        system.debug('lineItemIdSet:: ' + lineItemIdSet);
        system.debug('assetIdSet:: ' + assetIdSet);

        system.debug('adjLineItemMap:: ' + adjLineItemMap.Values());
        system.debug('ordAdjustmentLineItemMap:: ' + ordAdjustmentLineItemMap.Values());
        system.debug('adjustmentLineItemMap:: ' + adjustmentLineItemMap.Values());
        system.debug('assetAdjustmentLineItemMap :: ' + assetAdjustmentLineItemMap.Values());
        List<APTS_AdjustmentLIWrapper> adjLineItemWrapperList = new List<APTS_AdjustmentLIWrapper> ();
        for (sObject adjLineItem : adjLineItemMap.Values())
        {
            APTS_AdjustmentLIWrapper aLIWrapperItem = new APTS_AdjustmentLIWrapper();
            aLIWrapperItem.itemID = (id) adjLineItem.get('id');

            ID uniqueAssetID = null;
            ID uniqueLineItemID = null;
            if (assetAdjustmentLineItemMap.KeySet().contains(aLIWrapperItem.itemID))
            uniqueAssetID = (id) adjLineItem.get('Apttus_Config2_AssetLineItemId__c');
            else
            uniqueLineItemID = (id) adjLineItem.get('Apttus_Config2__LineItemId__c');
            if (uniqueAssetID != null && assetIdSet.contains(uniqueAssetID))
            {
                aLIWrapperItem.lineItemID = uniqueAssetID;
                aLIWrapperItem.subType = (string) adjLineItem.get('Apttus_Config2_SubType__c');
                aLIWrapperItem.lineNumber = (Decimal) (adjLineItem.getSobject('Apttus_Config2_AssetLineItemId__r').get('Apttus_Config2__LineNumber__c'));
                aLIWrapperItem.lineItemID = (Id) adjLineItem.get('Apttus_Config2_AssetLineItemId__c');
            }
            else if (uniqueLineItemID != null && (lineItemIdSet.contains(uniqueLineItemID) || ordLineItemIdSet.contains(uniqueLineItemID)))
            {
                aLIWrapperItem.lineItemID = uniqueLineItemID;
                aLIWrapperItem.subType = (string) adjLineItem.get('Apttus_Config2__SubType__c');
                aLIWrapperItem.lineNumber = (lineItemIdSet.contains(uniqueLineItemID)) ? (Decimal) (adjLineItem.getSobject('Apttus_Config2__LineItemId__r').get('Apttus_Config2__LineNumber__c')) : (Decimal) adjLineItem.get('Apttus_Config2__LineNumber__c');

            }
            adjLineItemWrapperList.add(aLIWrapperItem);
        }
        system.debug('adjLineItemWrapperList :: ' + adjLineItemWrapperList);
        return adjLineItemWrapperList;
    }


    public static id getLineItemId(Apttus_Config2__OrderLineItem__c oOrderLineItem)
    {
        id lineItemId = null;

        if (oOrderLineItem.APTS_SAP_OrderType__c == 'XB13')
        {
            lineItemId = oOrderLineItem.Apttus_Config2__AssetLineItemId__c;
        }
        else
        lineItemId = (oOrderLineItem.Apttus_Config2__OrderId__r.APTS_Order_Type__c == 'Admin Order' && oOrderLineItem.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c!=null && oOrderLineItem.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c.equalsIgnoreCase(APTS_BIRUtils.ORDERSUBTYPE)) ? oOrderLineItem.Id : oOrderLineItem.Apttus_Config2__DerivedFromId__c;

        return lineItemId;
    }
    public static Boolean checkAdjLIYOCIYOFTValue(Apttus_Config2__OrderLineItem__c oOrderLineItem, List<APTS_AdjustmentLIWrapper> adjustmentLineItemList, Boolean isYOCI) {
        Boolean bCheckYOCIYOFT = false;
        string condType = isYOCI ? 'YOCI' : 'YOFT';
        id lineItemId = getLineItemId(oOrderLineItem);
        for (APTS_AdjustmentLIWrapper adjLI : adjustmentLineItemList) {
            if (condType == adjLI.subType && adjLI.lineNumber == oOrderLineItem.Apttus_Config2__LineNumber__c) {
                if (lineItemId == adjLI.lineItemID) {
                    bCheckYOCIYOFT = true;
                    break;
                }
            } //v101 Start
        } return bCheckYOCIYOFT;
    }
    public static Boolean checkIfAdjustmentValueIsZX10(Apttus_Config2__OrderLineItem__c oOrderLineItem, List<APTS_AdjustmentLIWrapper> adjustmentLineItemList) {
        Boolean bHasZX10 = false;
        Set<String> setFreeOfCharge = new Set<String> { 'ZX10', 'YOCI', 'YOFT' };
        Decimal checkAdjustmentAmount = 0;
        //If Option -> check if any of the associated Adjustment lines has ZX10/YOCI
        List<Apttus_Config2__AdjustmentLineItem__c> lstAdjustmentLines = new List<Apttus_Config2__AdjustmentLineItem__c> ();
        id lineItemId = getLineItemId(oOrderLineItem);

        for (APTS_AdjustmentLIWrapper adjLI : adjustmentLineItemList) {
            if (setFreeOfCharge.Contains(adjLI.subType) && adjLI.lineNumber == oOrderLineItem.Apttus_Config2__LineNumber__c) {
                if (lineItemId == adjLI.lineItemID) {
                    if (adjLI.subType == YOCI || adjLI.subType == YOFT) {
                        oOrderLineItem.APTS_Item_Category_Adjustment__c = adjLI.subType;
                    }
                    bHasZX10 = true;
                    break;
                }
            } //v101 Start
        }
        //30-Nov-2018 Aarthi - Removed the condition oOrderLineItem.Apttus_Config2__LineType__c == 'Option'=> for SO
        if (bHasZX10 == false) {
            if (oOrderLineItem.Apttus_Config2__DerivedFromId__c != null && oOrderLineItem.Apttus_Config2__DerivedFromId__r.Apttus_Config2__NetAdjustmentPercent__c != null && math.abs(oOrderLineItem.Apttus_Config2__DerivedFromId__r.Apttus_Config2__NetAdjustmentPercent__c) == 100) {
                bHasZX10 = true;
            }
        } return bHasZX10;
    }
    public class APTS_AdjustmentLIWrapper
    {
        public id itemID { get; set; }
        public string subType { get; set; }
        public Decimal lineNumber { get; set; }
        public id lineItemID { get; set; }
    }
    //V116 ++>>
    //V117 ++<<
    public static Id getAccountLocationId(Account initialAccount)
    {
        Id locId = null;
        List<Apttus_Config2__AccountLocation__c> listDefLoc = [
                                                               SELECT Id,SAP_Customer_ID__c FROM Apttus_Config2__AccountLocation__c
                                                               WHERE Apttus_Config2__AccountId__c = :initialAccount.Id AND SAP_Customer_ID__c = :initialAccount.SAP_Customer_ID__c
                                                               AND Account_Location_Status__c = :APTS_OrderConstants.ACCOUNT_STATUS AND Delivery_Block_Reason__c = null LIMIT 1];

        if (!listDefLoc.isEmpty()) {
            locId = listDefLoc[0].Id;
        }
        return locId;
    }
    //V117 ++>>
    //V125++<<
   public static void stopAccValidations(){

 
        if(ValidationRulesSettings__c.getValues(UserInfo.getUserId())==null){
            ValidationRulesSettings__c valSettings = new ValidationRulesSettings__c();
            valSettings.SetupOwnerId = UserInfo.getUserId();
            valSettings.AccountValidationRules__c=false;
            insert valSettings;
            APTS_OrderUtils.deleteAfterVRS = true;
        }
        else{
        ValidationRulesSettings__c valSettings = ValidationRulesSettings__c.getValues(UserInfo.getUserId());    
            if(valSettings.AccountValidationRules__c){ 
                APTS_OrderUtils.isVRSUpdated = true;   
                valSettings.AccountValidationRules__c=false;
                update valSettings;
            }
        }

    }
    
    public static void startAccValidation(){
        if(APTS_OrderUtils.deleteAfterVRS){
            ValidationRulesSettings__c valSettings = ValidationRulesSettings__c.getValues(UserInfo.getUserId());    
            delete valSettings;
        }else if(APTS_OrderUtils.isVRSUpdated) {
            ValidationRulesSettings__c valSettings = ValidationRulesSettings__c.getValues(UserInfo.getUserId());
            valSettings.AccountValidationRules__c = true;
            update valSettings;
        }       
      }
    
    //V125++>>
    //V127 ++ <<
    public static void deactivateExistingCounters(Set<id> phAIds)
    {
        List<APTS_CounterReadingData__c> lstExistingCounters = [Select id, APTS_Counter_Status__c,APTS_Asset_Line_Item__c from APTS_CounterReadingData__c where APTS_Counter_Status__c = 'Active' and TS_Physical_Asset__c in: phAIDs];
        if(!lstExistingCounters.isEmpty())
        {
            for(APTS_CounterReadingData__c oCounter : lstExistingCounters)
            {
                oCounter.APTS_Counter_Status__c = 'Deactive';            
            }
            Database.Update(lstExistingCounters, false);
        }
    }
    //V127 ++>>
}