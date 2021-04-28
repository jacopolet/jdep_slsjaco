/*************************************************************
@Name: APTS_LSPDetailsController
@Author: Galin Georgiev
@CreateDate: 05-02-2018
@Description: Add LSP Details for installation order
@UsedBy: LSP Details button in cart on line item
******************************************************************/
//v100 05-02-2018 Galin Georgiev: Initial version.
//v101 05-07-2019 Akanksha : DOK31-14 changed flow for de-install order
//v102 27-05-2019 Akanksha : DOK31-235 Changed APTS_Requires_LSP__c logic
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes
// v103 : Nikita Modi : Delivery Only
//v104: 12-08-2020 Sneha Jaiwant: DQ2122 Removing the XA14 logic for bundle details
//v105: 20-10-2020 Renuka: DQ-3907 Credit Proposal Changes
//v106: 03-11-2020 Renuka: DQ-3907 Adding BillingDetails button to CTC flow NGContractChange cart
//v107: 27-Jan-2021 Sneha Jaiwant:DQ:5206 XB23-De-installation required checkbox missing in bundle details page
//v108: 11-Feb-2021 Sneha Jaiwant: De-installation: case description & case subject from the installation order pops-up whilst description was updated


public without sharing class APTS_LSPDetailsController {

    private static final String NGMACHINE_ORDER = System.Label.APTS_NGMachineOrder;
    private static final String ID = System.Label.APTS_Id;
    private static final String CARTPAGEURL = '/apex/Apttus_Config2__Cart?configRequestId={0}&id={1}&flow={2}&launchState=cart#/cart';
    private static final String EMAIL = System.Label.APTS_Email;
    private static final String COMMERCIAL_SWAP = System.Label.APTS_Commercial_Swap;
    private static final String APTS_XA13 = System.Label.APTS_XA13;
    private static final String LSPDETAILSOBJ = 'APTS_Order_LSP_Details__c';
    private static final String ORDEROBJ = 'Apttus_Config2__Order__c';
    private static final String LINEITEMOBJ = 'Apttus_Config2__LineItem__c';
    private static final String LINE_NUM = 'lineNum';
    private static final String CREDIT_PROPOSAL ='When credit proposal applied on the future conversion orders where it was not included earlier then it is applicable for the billing schedules of the future Ready for Invoice date.';
    private static final String YES= 'Yes';
    private static final String NGCONTRACT_CHANGE ='NGContractChange';
    
    private Apttus_Config2__LineItem__c oSelectedLineItem;
    public Apttus_Config2__LineItem__c oL1LineItem{get;set;}

    private Id selectedLineItemId;
    private Id configId;
    private Id orderId;
    private String lineNumber;

    public Boolean isValidationError {get; set;}
    public Boolean isFieldHide { get; set; }
    public Boolean isSecondServReq { get; set; }
    public Boolean isProjectCheck { get; set; }
    //v103 << ++
    public Boolean isInstallation {get; set;}
    public Boolean isDeInstallation {get; set;}

    //Conversion order changes | Billing details - start
    public Boolean isConversion {get; set;}
    public Boolean isBillUpdComp {get; set;}
    public String selectedBillingPref {get;set;}
    public String selectedPaymentTerm {get;set;}
    public String selectedPaymentMethod {get;set;}
    public String billingSalesOrg;
    //Conversion order changes | Billing details - end
    //v103 -->>

    public APTS_Order_LSP_Details__c oLSPDetail {get; set;}

    //commercial swap
    private Set<String> setSerialNum2 = new Set<String>();
    public List<PrevSerialNumWrapper> listSerialNumberWrap {get; set;}
    public Map<String, PrevSerialNumWrapper> mapSerialNumberWrap {get; set;}
    
    //CreditBlock Changes
    public Map<Id,Apttus_Config2__LineItem__c> creditBlockMap = new Map<Id,Apttus_Config2__LineItem__c>();
    public Boolean creditBlock {get; set;}
    public Boolean isContractChange {get; set;}

    //wrapper class
    public with sharing class PrevSerialNumWrapper {
        public Boolean isSelected {get; set;}
        public Apttus_Config2__OrderLineItem__c oLineItem {get; set;}
    }

    public APTS_LSPDetailsController() {
        Id lspDetailsId;
        Boolean isRequired = false;
        isConversion = false;
        Set<Id> productIdSet = new Set<Id>();
        Map<Id, Apttus_Config2__LineItem__c> allPrimaryL1LineMap = new Map<Id, Apttus_Config2__LineItem__c>();
        Map<Id, List<Decimal>> lspDetailsIdTolineItemNumberListMap = new Map<Id, List<Decimal>>();

        //v103 << ++
        isInstallation = false;
        isDeInstallation = false;
        Boolean bTechNotRequired = true;
        //v103 -->>

        //get Page Parameters
        selectedLineItemId = ApexPages.currentPage().getParameters().get(APTS_OrderConstants.ID);
        configId = ApexPages.currentPage().getParameters().get(APTS_OrderConstants.CONFIG_ID);
        lineNumber = ApexPages.currentPage().getParameters().get(LINE_NUM);

        Decimal dclineNumber = Decimal.valueOf(lineNumber);



        //############ SOQL Section ############

        for (Apttus_Config2__LineItem__c oLineItemTmp : [SELECT Apttus_Config2__ConfigurationId__c, Apttus_Config2__ChargeType__c, Apttus_Config2__LineNumber__c,
                Apttus_Config2__LineType__c, Apttus_Config2__ProductId__c, Apttus_Config2__HasOptions__c, APTS_Order_LSP_Detail__c, APTS_Type_of_Contract__c,
                APTS_Serial_Number2__c, Apttus_Config2__ShipToAccountId__r.Sales_Organization__c, Apttus_Config2__ConfigurationId__r.Order_Sub_Type__c,
                Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__c,
                Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Contract_Change__c,
                Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c,
                Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.Apttus_Config2__ParentOrderId__c,
                Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Subject__c,
                Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_LSP_Description__c,
                Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c,
                Agreement_Line_Item__r.APTS_ConfigurationFileURL__c,
                Apttus_Config2__IsPrimaryLine__c,
                Agreement_Line_Item__r.APTS_ConfigurationManualAgreementsURL__c,
                Apttus_Config2__ProductId__r.APTS_Technician_Not_Required__c,
                Apttus_Config2__OptionId__r.APTS_Technician_Not_Required__c,
                Apttus_Config2__BillingPreferenceId__c,
                Apttus_Config2__BillingPreferenceId__r.APTS_SalesOrg__c,
                Apttus_Config2__BillingPreferenceId__r.name,
                APTS_Payment_Method__c,
                Apttus_Config2__PaymentTermId__c, 
                APTS_Credit_Proposal_XC09_Block__c, Apttus_Config2__PriceType__c 
                FROM Apttus_Config2__LineItem__c
                WHERE Apttus_Config2__ConfigurationId__c = :configId AND Apttus_Config2__LineNumber__c = :dclineNumber]) {

            oSelectedLineItem = selectedLineItemId == oLineItemTmp.Id ? oLineItemTmp : oSelectedLineItem;

            //get primary L1 line item
            if (APTS_OrderConstants.PRODUCT_OR_SERVICE.equalsIgnoreCase(oLineItemTmp.Apttus_Config2__LineType__c) && checkPrimaryL1Line(oLineItemTmp)) {
                oL1LineItem = oLineItemTmp;
            }
            

            //v103 << ++
            //if (oSelectedLineItem.Apttus_Config2__LineNumber__c == oLineItemTmp.Apttus_Config2__LineNumber__c) {
            if (oLineItemTmp.Apttus_Config2__HasOptions__c) {
                bTechNotRequired = bTechNotRequired && !oLineItemTmp.Apttus_Config2__ProductId__r.APTS_Technician_Not_Required__c;
            } else {
                bTechNotRequired = bTechNotRequired && !oLineItemTmp.Apttus_Config2__OptionId__r.APTS_Technician_Not_Required__c;
            }
            //}
            //v103 -->>

            if (isConversion) {
                //Check if the Flag is set for any of the Products in the Cart, Set the value to True by Default on the LSP Details Screen
                productIdSet.add(oLineItemTmp.Apttus_Config2__ProductId__c);
            }

            if (String.isNotBlank(oLineItemTmp.APTS_Serial_Number2__c)) {
                setSerialNum2.add(oLineItemTmp.APTS_Serial_Number2__c);
            }

            lspDetailsId = oLineItemTmp.APTS_Order_LSP_Detail__c != null ? oLineItemTmp.APTS_Order_LSP_Detail__c : lspDetailsId;

           if(oLineItemTmp.Apttus_Config2__HasOptions__c && oLineItemTmp.Apttus_Config2__IsPrimaryLine__c){
                if (String.isNotBlank(oLineItemTmp.Apttus_Config2__BillingPreferenceId__c)) {
                    selectedBillingPref = oLineItemTmp.Apttus_Config2__BillingPreferenceId__c;
                    billingSalesOrg = oLineItemTmp.Apttus_Config2__BillingPreferenceId__r.APTS_SalesOrg__c;
                }else{
                    selectedBillingPref = '';
                }
               
                //System.debug('selectedBillingPref=========>'+selectedBillingPref);
                if (String.isNotBlank(oLineItemTmp.APTS_Payment_Method__c)) {
                    selectedPaymentMethod = oLineItemTmp.APTS_Payment_Method__c;
                }else{
                    selectedPaymentMethod = '';
                }
                //System.debug('selectedPaymentMethod=========>'+selectedPaymentMethod);
                if (String.isNotBlank(oLineItemTmp.Apttus_Config2__PaymentTermId__c)) {
                    selectedPaymentTerm = oLineItemTmp.Apttus_Config2__PaymentTermId__c;
                }else{
                    selectedPaymentTerm='';
                }
                //System.debug('selectedPaymentTerm=========>'+selectedPaymentTerm);
                //105 <<++
                creditBlock = oLineItemTmp.APTS_Credit_Proposal_XC09_Block__c;
            }
            creditBlockMap.put(oLineItemTmp.Id,oLineItemTmp);
            // 105 -->>
        }

        //############ SOQL Section ############

        if (oL1LineItem == null) {
            isValidationError = true;
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, APTS_OrderConstants.PRIMARY_L1_ITEM));
        } else {

            orderId = oSelectedLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__c;

            // Added the orderSubType and isFieldHide to hide the fields on the Bundle Detail Page
            String orderSubType = oSelectedLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c;
            String sapOrderType = oSelectedLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c ;


            // Created a Boolean isSecondServReq to make Second Service Contact Required in case of external movement
            isSecondServReq = APTS_OrderConstants.EXTERNAL_MOVEMENT_WITH_CONTRACT_CHANGE.equalsIgnoreCase(orderSubType) || APTS_OrderConstants.EXTERNAL_MOVEMENT_WITHOUT_CONTRACT_CHANGE.equalsIgnoreCase(orderSubType) ? true : false;
            isFieldHide = APTS_OrderConstants.INTERNAL_MOVEMENT.equalsIgnoreCase(orderSubType) || APTS_OrderConstants.EXTERNAL_MOVEMENT_WITH_CONTRACT_CHANGE.equalsIgnoreCase(orderSubType) || APTS_OrderConstants.EXTERNAL_MOVEMENT_WITHOUT_CONTRACT_CHANGE.equalsIgnoreCase(orderSubType) ? true : false;
            isConversion = APTS_OrderConstants.CONVERSION_ORDER.equalsIgnoreCase(oSelectedLineItem.Apttus_Config2__ConfigurationId__r.Order_Sub_Type__c);

            //v102 << ++
            isInstallation = APTS_OrderConstants.XA13.equalsIgnoreCase(sapOrderType)||APTS_OrderConstants.XA23.equalsIgnoreCase(sapOrderType)?True : False;//107
            isDeInstallation = APTS_OrderConstants.XB13.equalsIgnoreCase(sapOrderType)||APTS_OrderConstants.XB23.equalsIgnoreCase(sapOrderType)?True : False;//v107
            //v102 ++ >>
            
            //v106 <<++
            isContractChange= YES.equalsIgnoreCase(oSelectedLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Contract_Change__c);
            
            if (isConversion && !productIdSet.isEmpty()) {

                String sSalesOrg = (oSelectedLineItem.Apttus_Config2__ShipToAccountId__r.Sales_Organization__c).right(4);

                //Check if the Flag is set for any of the Products in the Cart, Set the value to True by Default on the LSP Details Screen
                Integer lSPRequiredCount = [
                                               SELECT Count()
                                               FROM APTS_Sales_Org_Data__c
                                               WHERE APTS_Product__c IN :productIdSet AND APTS_Sales_Org_Data_Name__c = :sSalesOrg AND APTS_LSP_Required__c = true ];

                if (lSPRequiredCount != null && lSPRequiredCount > 0) {
                    isRequired = true;
                }
            }

            //Below code is old code, OM team were not sure why this was written so commenting it
            /*for (Apttus_Config2__LineItem__c oLineItemTmp : allPrimaryL1LineMap.values()) {

                List<Decimal> lineItemNumberList = lspDetailsIdTolineItemNumberListMap.get(oLineItemTmp.APTS_Order_LSP_Detail__c);

                if (lineItemNumberList == null) {
                    lineItemNumberList = new List<Decimal>();
                    lspDetailsIdTolineItemNumberListMap.put(oLineItemTmp.APTS_Order_LSP_Detail__c, lineItemNumberList);
                }

                lineItemNumberList.add(oLineItemTmp.Apttus_Config2__LineNumber__c);

                if (oSelectedLineItem.Apttus_Config2__LineNumber__c == oLineItemTmp.Apttus_Config2__LineNumber__c) {

                    oLineItem = oLineItemTmp;
                }
            }


            for (Id lspDetailsId : lspDetailsIdTolineItemNumberListMap.keySet()) {

                List<Decimal> lineItemNumberList = lspDetailsIdTolineItemNumberListMap.get(lspDetailsId);

                if (lineItemNumberList != null && lineItemNumberList.size() > 1) {
                    lineItemNumberList.sort();

                    lineItemNumberList.remove(0);
                    for (Decimal dLineNumber : lineItemNumberList) {
                        if (oLineItem.Apttus_Config2__LineNumber__c == dLineNumber) {
                            oLineItem.APTS_Order_LSP_Detail__c = null;
                        }
                    }
                }
            }*/


            if (lspDetailsId != null) {

                List<APTS_Order_LSP_Details__c> lspDetailList = [
                            SELECT
                            Id, APTS_Subject__c, APTS_LSP_Description__c,  APTS_PlugPlay__c, APTS_Workshop__c, APTS_Project_Number__c, APTS_isProject__c, APTS_CollectCounters__c,
                            APTS_Installation_Contact__c, APTS_Second_Service_Contact__c, APTS_Schedule_Exceptions__c,
                            APTS_Deinstall_NonJDEMachine__c, APTS_Stopover__c, APTS_RefurbishedMachine__c, APTS_CommercialMachine__c,
                            APTS_SmokingArea__c, APTS_OwnedByCustomer__c, APTS_Building__c, APTS_Floor__c, APTS_Area__c,
                            APTS_CustomerReference__c, APTS_StairClimber__c, APTS_Requires_LSP__c,
                            APTS_ConfigurationFileURL__c, APTS_ConfigurationManualAgreementsURL__c, APTS_JDE_crockeryVolumeSize__c,
                            APTS_IncludesWaterfilterCoverage__c, APTS_Require_Installation__c, APTS_Require_De_Installation__c,
                            APTS_Elevator_Available__c
                            FROM APTS_Order_LSP_Details__c
                            WHERE Id = :lspDetailsId LIMIT 1];

                oLSPDetail = lspDetailList.isEmpty() ?  null : lspDetailList.get(0);
            }

            oLSPDetail = oLSPDetail == null ?  new APTS_Order_LSP_Details__c() : oLSPDetail;
            //v108 ++<<
            if(oSelectedLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Subject__c != null && (oSelectedLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c == 'XB23' || oSelectedLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c == 'XB13')){
                        oLSPDetail.APTS_Subject__c = oSelectedLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Subject__c;
            }
             if(oSelectedLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_LSP_Description__c != null && (oSelectedLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c == 'XB23' || oSelectedLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c == 'XB13')){
                        oLSPDetail.APTS_LSP_Description__c = oSelectedLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_LSP_Description__c ;
            }
            //v108 ++>>
            oLSPDetail.APTS_Subject__c = oLSPDetail.APTS_Subject__c == null ? oSelectedLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Subject__c : oLSPDetail.APTS_Subject__c;
            oLSPDetail.APTS_LSP_Description__c = oLSPDetail.APTS_LSP_Description__c == null ? oSelectedLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_LSP_Description__c : oLSPDetail.APTS_LSP_Description__c;
            oLSPDetail.APTS_ConfigurationFileURL__c = oLSPDetail.APTS_ConfigurationFileURL__c == null ? oSelectedLineItem.Agreement_Line_Item__r.APTS_ConfigurationFileURL__c : oLSPDetail.APTS_ConfigurationFileURL__c;
            oLSPDetail.APTS_ConfigurationManualAgreementsURL__c = oLSPDetail.APTS_ConfigurationManualAgreementsURL__c == null ? oSelectedLineItem.Agreement_Line_Item__r.APTS_ConfigurationManualAgreementsURL__c : oLSPDetail.APTS_ConfigurationManualAgreementsURL__c;
            //v102 << ++
            oLSPDetail.APTS_Requires_LSP__c = (isConversion) ? isRequired : oLSPDetail.APTS_Requires_LSP__c;
            if (isConversion) {
                oLSPDetail.APTS_Requires_LSP__c = isRequired;
            } else if (isInstallation) {
                oLSPDetail.APTS_Requires_LSP__c =  true;
            } else {
                oLSPDetail.APTS_Requires_LSP__c = oLSPDetail.APTS_Requires_LSP__c;
            }
            //v102 ++ >>

            //v103 <<++
            if (APTS_OrderConstants.XA13.equalsIgnoreCase(sapOrderType) || APTS_OrderConstants.XA23.equalsIgnoreCase(sapOrderType)) {//v107
                oLSPDetail.APTS_Require_Installation__c  = oLSPDetail.APTS_Floor__c != Null ? oLSPDetail.APTS_Require_Installation__c : bTechNotRequired;
            } else if (APTS_OrderConstants.XB13.equalsIgnoreCase(sapOrderType) || APTS_OrderConstants.XB23.equalsIgnoreCase(sapOrderType)) { //v107
                oLSPDetail.APTS_Require_De_Installation__c = oLSPDetail.APTS_Floor__c != Null ? oLSPDetail.APTS_Require_De_Installation__c : bTechNotRequired;
            }
            //v104--< 
            /*else if (APTS_OrderConstants.XA14.equalsIgnoreCase(sapOrderType)) {
                oLSPDetail.APTS_Require_Installation__c = true;
                oLSPDetail.APTS_Require_De_Installation__c = true;
            }*/
            //v104--> 
            // Checking for APTS_Floor__c as it is mandatory ; first click it is blank and subsequent button click it always has a value
            //v103 -->>

            //if commercial swap, get all serial numbers selected for deinstallation and prepare map
            if (COMMERCIAL_SWAP.equalsIgnoreCase(oSelectedLineItem.Apttus_Config2__ConfigurationId__r.Order_Sub_Type__c) && oSelectedLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__c != NULL && APTS_XA13.equalsIgnoreCase(oSelectedLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c)) {
                listSerialNumberWrap = new List<PrevSerialNumWrapper>();
                mapSerialNumberWrap = new Map<String, PrevSerialNumWrapper>();
                PrevSerialNumWrapper oWrap = new PrevSerialNumWrapper();

                for (Apttus_Config2__OrderLineItem__c oLineItem : [SELECT Id, APTS_Serial_Number__c, Apttus_Config2__ProductId__r.Name, Apttus_Config2__NetPrice__c,
                        APTS_Order_LSP_Detail__r.APTS_Floor__c, APTS_Order_LSP_Detail__r.APTS_Area__c, APTS_Order_LSP_Detail__r.APTS_Building__c,
                        APTS_Order_LSP_Detail__r.APTS_Subject__c, APTS_Order_LSP_Detail__r.APTS_LSP_Description__c,
                        APTS_Order_LSP_Detail__r.APTS_StairClimber__c, APTS_Order_LSP_Detail__r.APTS_Requires_LSP__c, APTS_Order_LSP_Detail__r.APTS_CommercialMachine__c,
                        APTS_Order_LSP_Detail__r.APTS_OwnedByCustomer__c, APTS_Order_LSP_Detail__r.APTS_SmokingArea__c, APTS_Order_LSP_Detail__r.APTS_Elevator_Available__c,
                        APTS_Order_LSP_Detail__r.APTS_CustomerReference__c, APTS_Order_LSP_Detail__r.APTS_JDE_crockeryVolumeSize__c,
                        APTS_Order_LSP_Detail__r.APTS_ConfigurationManualAgreementsURL__c, APTS_Order_LSP_Detail__r.APTS_Project_Number__c, APTS_Order_LSP_Detail__r.APTS_isProject__c,
                        APTS_Order_LSP_Detail__r.APTS_CollectCounters__c, APTS_Order_LSP_Detail__r.APTS_Schedule_Exceptions__c, APTS_Order_LSP_Detail__r.APTS_Installation_Contact__c,
                        APTS_Order_LSP_Detail__r.APTS_Second_Service_Contact__c
                        FROM Apttus_Config2__OrderLineItem__c WHERE Apttus_Config2__OrderId__c   = : oSelectedLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.Apttus_Config2__ParentOrderId__c
                                AND APTS_Serial_Number__c <> NULL AND Apttus_Config2__OptionId__c = NULL ]) {

                    if (oLineItem.APTS_Serial_Number__c.equalsIgnoreCase(oSelectedLineItem.APTS_Serial_Number2__c) || !setSerialNum2.contains(oLineItem.APTS_Serial_Number__c)) {

                        oWrap.oLineItem = oLineItem;
                        oWrap.isSelected = oLineItem.APTS_Serial_Number__c.equalsIgnoreCase(oSelectedLineItem.APTS_Serial_Number2__c) ? true : false;
                        listSerialNumberWrap.add(oWrap);
                        mapSerialNumberWrap.put(oLineItem.APTS_Serial_Number__c, oWrap);
                    }
                }
            }
        }
    }

    public void setLSPDetails() {
        String serialNum = Apexpages.currentPage().getParameters().get(APTS_OrderConstants.SERIAL_NUM);
        PrevSerialNumWrapper oWrap = mapSerialNumberWrap.get(serialNum);

        if (oWrap != NULL && oWrap.oLineItem != NULL && oWrap.oLineItem.APTS_Order_LSP_Detail__r != NULL) {
            oLSPDetail.APTS_Floor__c = oWrap.oLineItem.APTS_Order_LSP_Detail__r.APTS_Floor__c;
            oLSPDetail.APTS_Area__c = oWrap.oLineItem.APTS_Order_LSP_Detail__r.APTS_Area__c;
            oLSPDetail.APTS_Building__c = oWrap.oLineItem.APTS_Order_LSP_Detail__r.APTS_Building__c;
            oLSPDetail.APTS_Subject__c = oWrap.oLineItem.APTS_Order_LSP_Detail__r.APTS_Subject__c;
            oLSPDetail.APTS_LSP_Description__c = oWrap.oLineItem.APTS_Order_LSP_Detail__r.APTS_LSP_Description__c;
            oLSPDetail.APTS_StairClimber__c = oWrap.oLineItem.APTS_Order_LSP_Detail__r.APTS_StairClimber__c;
            oLSPDetail.APTS_Requires_LSP__c = oWrap.oLineItem.APTS_Order_LSP_Detail__r.APTS_Requires_LSP__c;
            oLSPDetail.APTS_CommercialMachine__c = oWrap.oLineItem.APTS_Order_LSP_Detail__r.APTS_CommercialMachine__c;
            oLSPDetail.APTS_OwnedByCustomer__c = oWrap.oLineItem.APTS_Order_LSP_Detail__r.APTS_OwnedByCustomer__c;
            oLSPDetail.APTS_SmokingArea__c = oWrap.oLineItem.APTS_Order_LSP_Detail__r.APTS_SmokingArea__c;
            oLSPDetail.APTS_Elevator_Available__c = oWrap.oLineItem.APTS_Order_LSP_Detail__r.APTS_Elevator_Available__c;
            oLSPDetail.APTS_CustomerReference__c = oWrap.oLineItem.APTS_Order_LSP_Detail__r.APTS_CustomerReference__c;
            oLSPDetail.APTS_JDE_crockeryVolumeSize__c = oWrap.oLineItem.APTS_Order_LSP_Detail__r.APTS_JDE_crockeryVolumeSize__c;
            oLSPDetail.APTS_ConfigurationManualAgreementsURL__c = oWrap.oLineItem.APTS_Order_LSP_Detail__r.APTS_ConfigurationManualAgreementsURL__c;
            oLSPDetail.APTS_Project_Number__c = oWrap.oLineItem.APTS_Order_LSP_Detail__r.APTS_Project_Number__c;
            oLSPDetail.APTS_isProject__c = oWrap.oLineItem.APTS_Order_LSP_Detail__r.APTS_isProject__c;
            oLSPDetail.APTS_CollectCounters__c = oWrap.oLineItem.APTS_Order_LSP_Detail__r.APTS_CollectCounters__c;
            oLSPDetail.APTS_Schedule_Exceptions__c = oWrap.oLineItem.APTS_Order_LSP_Detail__r.APTS_Schedule_Exceptions__c;
            oLSPDetail.APTS_Installation_Contact__c = oWrap.oLineItem.APTS_Order_LSP_Detail__r.APTS_Installation_Contact__c;
            oLSPDetail.APTS_Second_Service_Contact__c = oWrap.oLineItem.APTS_Order_LSP_Detail__r.APTS_Second_Service_Contact__c;
        }
        isProjectCheck = oLSPDetail.APTS_isProject__c;
    }

    public PageReference addLSPDetails() {
        Boolean isLineItemUpdated = false;
        DescribeSObjectResult objResultLSP = APTS_OTCUtil.getsObjectAccess(LSPDETAILSOBJ);
        DescribeSObjectResult objResultLineItem = APTS_OTCUtil.getsObjectAccess(LINEITEMOBJ);
        DescribeSObjectResult objResultOrder = APTS_OTCUtil.getsObjectAccess(ORDEROBJ);
        Map<Id,Apttus_Config2__LineItem__c> lineItemUpdateMap = new Map<Id,Apttus_Config2__LineItem__c>();
        
        if (validate() && oLSPDetail != null && (objResultLSP.isCreateable() || objResultLSP.isUpdateable())) {
            Database.upsert(oLSPDetail);

            if (oL1LineItem != null && oL1LineItem.APTS_Order_LSP_Detail__c == null) {
                oL1LineItem.APTS_Order_LSP_Detail__c = oLSPDetail.Id;
                isLineItemUpdated = true;
            }

            if (listSerialNumberWrap != NULL) {
                isLineItemUpdated = true;
                oL1LineItem.APTS_Serial_Number2__c = NULL;
                for (PrevSerialNumWrapper oWrap : listSerialNumberWrap) {
                    if (oWrap.isSelected) {
                        oL1LineItem.APTS_Serial_Number2__c = oWrap.oLineItem.APTS_Serial_Number__c;
                        break;
                    }
                }
            }
            // v105 <<++
            if(creditBlock != null && creditBlockMap.values().size()>0){
                Apttus_Config2__LineItem__c li;
                for(Apttus_Config2__LineItem__c lineItem : creditBlockMap.values()){
                    li = new Apttus_Config2__LineItem__c();
                    li.Id = lineItem.Id;
                    li.APTS_Credit_Proposal_XC09_Block__c = creditBlock;
                    lineItemUpdateMap.put(li.Id,li);
                }
            }// v105 -->>
            
            if (isLineItemUpdated && objResultLineItem.isUpdateable()) {
                Database.update(oL1LineItem);
            }
            if(lineItemUpdateMap.values().size()>0){// v105 <<++
                Database.update(lineItemUpdateMap.values());
            } // v105 -->>

            //Update Order Header with APTS_LSP_Required_Indicator__c//Galin : this is wrong
            if (oLSPDetail.APTS_Requires_LSP__c && orderId != null) {
                Apttus_Config2__Order__c ordToUpdate = [Select id, APTS_LSP_Required_Indicator__c from Apttus_Config2__Order__c where Id = :orderId ];
                ordToUpdate.APTS_LSP_Required_Indicator__c = oLSPDetail.APTS_Requires_LSP__c;
                if (objResultOrder.isUpdateable()) {
                    APTS_OrderUtils.stopOrderTrigger();
                    Database.Update(ordToUpdate, false);
                    APTS_OrderUtils.startOrderTrigger();
                }
            }

            return back();
        } else {
            return null;
        }
    }

    public Boolean validate() {

        Boolean bResult = true;

        Boolean isBuildingSpecified = oLSPDetail.APTS_Building__c != null;
        Boolean isFloorSpecified = oLSPDetail.APTS_Floor__c != null;
        Boolean isAreaSpecified = oLSPDetail.APTS_Area__c != null;

        if (!isBuildingSpecified || !isFloorSpecified || !isAreaSpecified) {

            String sMsg = 'Missing mandatory fields :' + ((!isBuildingSpecified) ? ' Building, ' : '') + ((!isFloorSpecified) ? 'Floor, ' : '')  + ((!isAreaSpecified) ? ' Area' : '') ;
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, sMsg));
            bResult = false;
        }

        return bResult;
    }

    public PageReference back() {

        Id cartId = oSelectedLineItem.Apttus_Config2__ConfigurationId__c;
        Id tempObjectId = getTempObject(cartId);
        String oSubType = oSelectedLineItem.Apttus_Config2__ConfigurationId__r.Order_Sub_Type__c;

        /*//v101 ++ <<
        String sCartPage = oSubType == APTS_OrderConstants.DE_INSTALLATION ? '/apex/Apttus_Config2__Cart?configRequestId=' + tempObjectId + '&id=' + cartId + '&flow=' + APTS_OrderConstants.NG_MACHINEDEINSTALLORDER + '&launchState=cart#/cartgrid' : '/apex/Apttus_Config2__Cart?configRequestId=' + tempObjectId + '&id=' + cartId + '&flow=' + NGMACHINE_ORDER + '&launchState=cart#/cart';
        //v101 ++ >>
        // List<String> filterList = new String[] {tempObjectId, cartId, sFlow};
        // String sCartPage = String.format(CARTPAGEURL, filterList);
        //String sCartPage = '/apex/Apttus_Config2__Cart?configRequestId='+tempObjectId +'&id='+cartId+'&flow='+sFlow+'&launchState=cart#/cart' ;

        return new PageReference(sCartPage);*/
        PageReference pg;
        pg = Page.Apttus_Config2__Cart;
        pg.getParameters().put('id', cartId);       
        pg.getParameters().put('configRequestId', tempObjectId);  
        pg.getParameters().put('launchState','cart');    
        if(oSubType == APTS_OrderConstants.DE_INSTALLATION){
             pg.getParameters().put(APTS_CPQConstants.FLOW,APTS_OrderConstants.NG_MACHINEDEINSTALLORDER);
        }
        else if(YES.equalsIgnoreCase(oSelectedLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Contract_Change__c)){
            pg.getParameters().put(APTS_CPQConstants.FLOW,NGCONTRACT_CHANGE);
        }
        else if(oSubType == APTS_OrderConstants.CONVERSION_ORDER){
            pg.getParameters().put(APTS_CPQConstants.FLOW,APTS_OrderConstants.NG_ADMINORDER);
        }
        else{
             pg.getParameters().put(APTS_CPQConstants.FLOW,NGMACHINE_ORDER);
        }
        return pg;
    }

    private Id getTempObject(Id cartId) {

        Id tempObjectId = null;
        List<Apttus_Config2__TempObject__c> tempObjectList = [SELECT Id FROM Apttus_Config2__TempObject__c WHERE Apttus_Config2__ConfigurationId__c = :cartId ];

        if (tempObjectList != null && !tempObjectList.isEmpty()) {
            tempObjectId = tempObjectList.get(0).Id;
        }

        return tempObjectId;
    }


    private Boolean checkPrimaryL1Line(Apttus_Config2__LineItem__c oLineItem) {

        Boolean isPrimaryL1Line = false;

        Set<String> setSAPOrderTypesMO = new Set<String> {APTS_OrderConstants.XA13, APTS_OrderConstants.XB13, APTS_OrderConstants.XA14};
        Set<String> setSAPOrderTypesSO = new Set<String> {APTS_OrderConstants.XA01, APTS_OrderConstants.XB01, APTS_OrderConstants.XB02};
        Set<String> setContractTypes_RF = new Set<String> {APTS_OrderConstants.RENT, APTS_OrderConstants.FREE_ON_LOAN, APTS_OrderConstants.CONSUMPTION};

        String orderType = oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c;

        Boolean bSalesSPCase = APTS_OrderConstants.SALES.equalsIgnoreCase(oLineItem.APTS_Type_of_Contract__c) && APTS_OrderConstants.SALES_PRICE.equalsIgnoreCase(oLineItem.Apttus_Config2__ChargeType__c) && setSAPOrderTypesMO.contains(orderType);
        Boolean bTrailCase = APTS_OrderConstants.TRAIL.equalsIgnoreCase(oLineItem.APTS_Type_of_Contract__c) && APTS_OrderConstants.SALES_PRICE.equalsIgnoreCase(oLineItem.Apttus_Config2__ChargeType__c) && (setSAPOrderTypesMO.contains(orderType) || APTS_OrderConstants.XA23.equalsIgnoreCase(orderType) || APTS_OrderConstants.XB23.equalsIgnoreCase(orderType));
        Boolean bRFCase = setContractTypes_RF.contains(oLineItem.APTS_Type_of_Contract__c) && APTS_OrderConstants.RENTAL_FEE.equalsIgnoreCase(oLineItem.Apttus_Config2__ChargeType__c) && (setSAPOrderTypesMO.contains(orderType) || APTS_OrderConstants.XD09.equalsIgnoreCase(orderType));
        Boolean bSubscriptionCase = APTS_OrderConstants.SUBSCRIPTION.equalsIgnoreCase(oLineItem.APTS_Type_of_Contract__c) && APTS_OrderConstants.SALES_PRICE.equalsIgnoreCase(oLineItem.Apttus_Config2__ChargeType__c) && setSAPOrderTypesSO.contains(orderType);
        Boolean bRentBuyCase = APTS_OrderConstants.RENTBUY.equalsIgnoreCase(oLineItem.APTS_Type_of_Contract__c) && APTS_OrderConstants.RENTAL_FEE.equalsIgnoreCase(oLineItem.Apttus_Config2__ChargeType__c) && (setSAPOrderTypesMO.contains(orderType) || APTS_OrderConstants.XD09.equalsIgnoreCase(orderType));
        Boolean bSalesFoLCase = (APTS_OrderConstants.SALES.equalsIgnoreCase(oLineItem.APTS_Type_of_Contract__c) || APTS_OrderConstants.FREE_ON_LOAN.equalsIgnoreCase(oLineItem.APTS_Type_of_Contract__c)) && (APTS_OrderConstants.SERVICE_FEE.equalsIgnoreCase(oLineItem.Apttus_Config2__ChargeType__c) || APTS_OrderConstants.ADDITIONAL_FEE.equalsIgnoreCase(oLineItem.Apttus_Config2__ChargeType__c)) && APTS_OrderConstants.XD09.equalsIgnoreCase(orderType);
        Boolean bConsumptionModelCase = APTS_OrderConstants.CONSUMPTION.equalsIgnoreCase(oLineItem.APTS_Type_of_Contract__c) && APTS_OrderConstants.USAGE_FEE.equalsIgnoreCase(oLineItem.Apttus_Config2__ChargeType__c) && APTS_OrderConstants.XD12.equalsIgnoreCase(orderType);

        if (bSalesSPCase || bTrailCase || bRFCase || bSubscriptionCase || bRentBuyCase || bSalesFoLCase || bConsumptionModelCase) {

            isPrimaryL1Line = true;
        }
        return isPrimaryL1Line;
    }

    public List<SelectOption> getBillingPrefListbySo(){
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('','--None--'));
        for(Apttus_Config2__BillingPreference__c pref: [select id,name from Apttus_Config2__BillingPreference__c where APTS_SalesOrg__c=: billingSalesOrg]) {
            options.add(new SelectOption(pref.id,pref.name));
        }
        //System.debug('options=======>'+options);
        return options;
    }
     public List<SelectOption> getPaymentMethodbySo(){
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('','--None--'));
        for(APTS_Payment_Method__c pref: [select id,name from APTS_Payment_Method__c where APTS_Sales_Org__c=: billingSalesOrg]) {
            options.add(new SelectOption(pref.id,pref.name));
        }
        //System.debug('options===2====>'+options);
        return options;
    }
    public List<SelectOption> getPaymentTermListbySo(){
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('','--None--'));
        for(Apttus_Config2__PaymentTerm__c pref: [select id,name from Apttus_Config2__PaymentTerm__c where APTS_Sales_Org__c=: billingSalesOrg]) {
            options.add(new SelectOption(pref.id,pref.name));
        }
        //System.debug('options====3===>'+options);
        return options;
    }
    public PageReference updateAndCascadeBillingDetails(){
        List<Apttus_Config2__LineItem__c> optionAndRollupLineItemList = new List<Apttus_Config2__LineItem__c>();
        boolean isBDChanged=false;
        boolean isError=false;
        //System.debug('configId===>'+configId);
        //System.debug('lineNumber===>'+lineNumber);
        //System.debug('selectedBillingPref===>'+selectedBillingPref);
        //System.debug('selectedPaymentTerm===>'+selectedPaymentTerm);
        //System.debug('selectedPaymentMethod===>'+selectedPaymentMethod);
        if(String.isBlank(selectedPaymentTerm) || String.isBlank(selectedBillingPref)){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,System.Label.APTS_BillingDetailsRequiredError));
            isError=true;
        }
        if(!isError){
            if(configId!=null && lineNumber!=null){
                For(Apttus_Config2__LineItem__c lineitem : [select id,Apttus_Config2__LineType__c,Apttus_Config2__PriceType__c,Apttus_Config2__LineStatus__c,
                Apttus_Config2__BillingPreferenceId__c,APTS_Payment_Method__c,Apttus_Config2__PaymentTermId__c, APTS_Credit_Proposal_XC09_Block__c 
                from Apttus_Config2__LineItem__c 
                where Apttus_Config2__ConfigurationId__c =: configId 
                and Apttus_Config2__LineNumber__c =: Decimal.valueOf(lineNumber)]){
                    if (lineitem.Apttus_Config2__LineStatus__c!='Cancelled' &&
                        APTS_BIRUtils.RECURRING.equalsIgnoreCase(lineitem.Apttus_Config2__PriceType__c))
                    {
                        IF(selectedBillingPref!=null && lineitem.Apttus_Config2__BillingPreferenceId__c!=selectedBillingPref){
                            lineitem.Apttus_Config2__BillingPreferenceId__c=selectedBillingPref;
                            isBDChanged = true;
                        }
                        IF(selectedPaymentMethod!=null && lineitem.APTS_Payment_Method__c!=selectedPaymentMethod){
                            lineitem.APTS_Payment_Method__c=selectedPaymentMethod;
                            isBDChanged = true;
                        }
                        IF(selectedPaymentTerm!=null && lineitem.Apttus_Config2__PaymentTermId__c!=selectedPaymentTerm){
                            lineitem.Apttus_Config2__PaymentTermId__c=selectedPaymentTerm;
                            isBDChanged = true;
                        }
                    }
                    lineitem.APTS_Credit_Proposal_XC09_Block__c = creditBlock;
                    //System.debug('lineitem.Apttus_Config2__LineStatus__c====>'+lineitem.Apttus_Config2__LineStatus__c);
                    if(isBDChanged && lineitem.Apttus_Config2__LineType__c.equalsIgnoreCase('Option') && lineitem.Apttus_Config2__LineStatus__c.equalsIgnoreCase('Existing')){
                       lineitem.Apttus_Config2__LineStatus__c='Amended';
                    }
                    optionAndRollupLineItemList.add(lineitem);
                }
                if(!optionAndRollupLineItemList.isEmpty()){
                    //System.debug('optionAndRollupLineItemList============>'+optionAndRollupLineItemList);
                    Database.update(optionAndRollupLineItemList,false);
                }
            }
            return back();
        }
        return null;
    }
    
    // v105 <<++
    public void checkCredit(){
        if(creditBlock){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,CREDIT_PROPOSAL ));
        }
    } // v105 -->>
}