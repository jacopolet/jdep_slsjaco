/*************************************************************
@Name: APTS_OrderTriggerHandler
@Author: Galin Georgiev
@CreateDate: 04-04-2018
@Description: APTS_OrderTriggerHandler
@UsedBy:
******************************************************************/ 
//v100 04-01-2018 Galin Georgiev: Initial version.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes
//v101.1 13-08-2018 Neev Shah : added code for amend or order
//v101.2 15-10-2018 Rajesh Patel : added code for APTS_Fix_Term_Billing_Flag__c field value set, based on Fixed Term Type on the Agreement.
//v101.3 15-10-2018 Akanksha : Fields are made null after cloning order
//v101.4 16-10-2018 Rajesh patel : Set the Remove Billing block indicator to TRUE when creating De-Installation order.
//v101.5 17-10-2018 Aarthi Pitchai : Defect #20334  Modified the logic to calculate the Requested delivery date based on Country Offset before second submission to SAP.
//v101.6 17-10-2018 Akanksha : Added code to set account location fields on updation
//v101.7 24-10-2018 Amit : Added logic to mute overridng bill to account on order header for Credit memo order
//v101.8 27-10-2018 Aarthi : Commented out the lines that resets the Requested delivery date as part of Defect #19816 resolution
//v101.9 31-10-2018 Nikita : CR#2079 to update the CurrencyISOCode based on the Price List
//v101.10 10-11-2018 Balashanthi : Defect # 21146 -  Billing date is not set on order header
//v101.11 13-11-2018 Balashanthi : Defect # 21401 -  Bypassing the logic Billing date = null for Admin order with SAP order Type XD09 & XD12
//v101.12 11-12-2018 Aarthi : Defect # 22448 -  Added Logic to bypass the Order end date calculation to default + 5yrs only in case of XD01 - Defect #22448
//v101.13 81-12-2018 Balashanthi : Defect # 22988 - Added Logic - Task Force DMV -  Admin Orders with line items not pushed to SAP - Data Migration
//v101.14 10-01-2019 Rajesh Patel: Defect#23536 added Logic APTS_Fix_Term_Billing_Flag__c field value set, based on Fixed Term Type on the Agreement
//v101.15 29-01-2019 Aarthi Pitchai : Added fix for setting the requested Delivery date as Pickup date in case of DeInstall
//101.16 13-02-2019 Rajesh Patel : changed logic for keeping case, start date and end date for defect #4877
//v101.17 22-02-2019 Akanksha : Changed code for defect# 5173
//v101.18 25-02-2019 Balashanthi : Defect # 5361 ADMIN orders payer not correct showing sold to party instead of payer
//v101.19 11-03-2019 Akanksha: Commented code for Defect 5768 related to Approval
//v101.20 25-03-2019 Sethu: Added code for Delay CR
//v101.21 28-03-2019 Akanksha : Added code for CR 2158
//v101.22 09-04-2019 Aarthi : Defect 6212 - Added lock order field condition check before Auto submitting orders in case of Approval
//v101.23 15-04-2019 Akanksha : Defect 6762 : Checking old ATP check status as well
//v101.24 29-04-2019 Mahesh : 
//V101.25 006-05-2019  Sethu: DOQOM-37 Populate picking list text on the order from Account location
//v101.26 20-05-2019 Akanksha : Defect 24492(DOK31-194) Requested Delivery date change with requested installation date -- <<3.1>>--
//v101.27 23-05-2019 Akanksha : Defect 24508(DOK31-208) Requested De-Installation Date should be Monday only  -- <<3.1>>--
//v101.28 18-05-2019 Akanksha : Defect 24578 (DOK31-271) Changing condition for Requested Delivery Date after TS update
//v101.29 25-06-2019 Nikita : Defect 24578 (DOKOM-317) Approval Status Copied to Next version when Cancelling Order
//v101.30 25-06-2019 Akanksha : DOK31-263 Requested Movement Date adding condition for XA14
//v101.31 27-08-2019 Renuka: DFT2C-1017 Stopping the overriding of Bill-to Party and Payer fields in Order, which is been set from APTS_BIRUtils.
//v101.32 26-09-2019 Renuka: QTCFLEX1-1307 If Bill-to Party and Payer fields in Order is Null, Orders SoldTo Account should be populated
//v101.33 14-10-2019 Aarthi: QTCFLEX1-1451 Set Delivery Text based on Account Location
//v101.34 30-10-2019 Renuka: QTCFLEX1-1599 XC01 Credit Notes - Auto submit to SAP once it is Approved.
//v101.35 12-11-2019 Aarthi: QTCFLEX1-1556 Remove APTS_Primary_ContactId_Filtered__c logic due to new solution
//v101.36 31-07-2020 Manisha: DQ-3403 Updating the Custom Status as Status
//v101.37 21-12-2020 Renuka: DQ-4820 Z Indicator logic for XD01,XC01
//v101.38 25-01-2021 Aarthi: DQ-4639 - Trigger Integration log on every TS update on LSP schedule
//v101.39 2-2-2021 Sneha:Successful trial: CTC(Trial->Sales)- XD01 order, Order reason, picklist value
//v101.40 15-4-2021 Aarthi: DQ-5655 - Populate ATP Cleared status on WOLI

public without sharing  class APTS_OrderTriggerHandler implements ITriggerHandler {

    public static Boolean isTriggerDisabled = false;
    private static final String DRAFT = System.Label.APTS_Draft;
    private static final String PENDING = System.Label.APTS_Pending;
    private static final String SUBMITTED = System.Label.APTS_Submitted;
    private static final String ACTIVATED = System.Label.APTS_Activated;
    private static final String SAP_INTEGRATION_USER = System.Label.APTS_SAPIntegrationUser;
    private static final String L004 = System.Label.APTS_004;
    private static final String INSTALLATION = System.Label.APTS_Installation;
    private static final String DE_INSTALLATION = System.Label.APTS_De_installation;
    private static final String INTERNAL_MOVEMENT = System.Label.APTS_Internal_Movement;
    private static final String EXTERNAL_MOVEMENT_WITH_CONTRACT_CHANGE = 'External Movement With Contract Change';
    private static final String EXTERNAL_MOVEMENT_WITHOUT_CONTRACT_CHANGE = 'External Movement Without Contract Change';
    private static final String TECHNICAL_SWAP = System.Label.APTS_Technical_Swap;
    private static final String COMMERCIAL_SWAP = System.Label.APTS_Commercial_Swap;
    private static final String PASS = System.Label.APTS_Pass;
    private static final String FAIL = System.Label.APTS_Fail;
    private static final String MACHINE_ORDER = System.Label.APTS_Machine_Order;
    private static final String IN_AMENDMENT = System.Label.APTS_In_Amendment;
    private static final String EMAIL = System.Label.APTS_Email;
    public static final String ADMINORDER = 'Admin Order';
    public static final String STANDARDORDER = 'Standard Order';
    public static final String MACHINEORDER = 'Machine Order';
    public static final String FIXEDTERMTYPE = System.Label.APTS_FixedTermType;
    private static final String XB13 = System.Label.APTS_XB13;
    private static final String XA13 = System.Label.APTS_XA13;
    private static final String STANDARD_RETURN = 'Standard Return';
    private static final String INTLOG = 'Integration_Log__c';
    private static final String WORKOTRIGGER = 'WorkOrderTrigger__c';
    private static final String ORDERCRUD = 'Apttus_Config2__Order__c';
    private static final String ORDElIRCRUD = 'Apttus_Config2__OrderLineItem__c';
    private static final String PHYASST = 'PhysicalAsset__c';
    //v101.27 (3.1) ++ <<
    private static final String E = 'E';
    private static final String MON = 'Mon';
    private static final String REQUESTEDDELIVERYDATEMONDAYMSG = 'Requested DeInstallation Date must be set to Monday.';
    private static final String REQUESTEDMOVEMENTDATEMONDAYMSG = 'Requested Movement Date must be set to Monday.';
    //v101.27 (3.1) ++ >>
    //v101.7 ++ <<
    private static final string CREDITDOC = 'XC01';
    //v101.8 ++ <<
    private static final string ADMINORDERDOCTYPE = 'XD09';
    private static final string CONSUMTPIONDOCTYPE = 'XD12';

    //v101.2 ++ <<
    private static final String FIXEDCOST = System.Label.APTS_SAP_Order_Type_Fixed_Cost;
    private static final String ALLINGREDIENTS = System.Label.APTS_SAP_Order_Type_All_Ingredients;
    private static final String FIXEDCOSTANDINGREDIENTS = System.Label.APTS_SAP_Order_Type_Fixed_Costs_and_Ingredients;
    //v101.2 ++ >>

    //v101.1 ++ <<
    private static final String STATUS_PENDING_CANCEL = 'Pending Cancellation';
    //v101.1 ++ >>

    private static final String WTYPE_SWAP = 'swap';
    
    //v101.21  ++ <<
     List<String> orderTypesList = new List<String>{'Standard Order', 'Route Sales Order', 'Operating Order'};
    //v101.21  ++ >>
    private static final String ACCOUNT = 'Account';

    //@Description : Method to get the beforeInsert on OrderTriggerHandler
         public void beforeInsert(List<SObject> newItems) {
             System.debug('Order trigger in beforeInsert-------------');
             
             //Variable Section
             List<Apttus_Config2__Order__c> orderList = (List<Apttus_Config2__Order__c>) newItems;
             Set<Id> agreementIdSet = new Set<Id>();
             Set<Id> soldToAccountIdSet = new Set<Id>();
             List<String> fixedTermTypeList = new List<String>();
             List<String> SapFixedCostList = new List<String>();
             List<String> SapAllIngredientsList = new List<String>();
             List<String> SapFixedCostsAndIngredients = new List<String>();
             //v101.9 ++ <<
             ID plID;
             List<ID> priceListID = new List<ID>();
             //v101.9 ++ >>
             Boolean isCheckOnAccount = true;
             Id billToAccountId = NULL;
             Id payerAccountID = NULL;
             Account soldToAccount = NULL;
             Set<id> setLocationIDs = new Set<id>();
             //Variable Section
             
             //Initial loop
             for (Apttus_Config2__Order__c oOrder : orderList) {
                 if (oOrder.Apttus_Config2__PriceListId__c != Null) {
                     priceListID.add(oOrder.Apttus_Config2__PriceListId__c);  //v101.9 ++
                 }
                 agreementIdSet.add(oOrder.Apttus_CMConfig__AgreementId__c);
                 soldToAccountIdSet.add(oOrder.Apttus_Config2__SoldToAccountId__c);   
                 if(!ADMINORDER.equalsIgnoreCase(oOrder.APTS_Order_Type__c) && oOrder.Apttus_Config2__LocationId__c != null)
                 {
                     setLocationIDs.add(oOrder.Apttus_Config2__LocationId__c);
                 }             
                 oOrder = defaultFieldValues(oOrder);  //v101.33   ++ <<>>              
                 //v101.24 ++ >>
             }
             //Initial loop
             Map<ID, Apttus_Config2__PriceList__c> MapIDPriceList = new Map<ID, Apttus_Config2__PriceList__c>([SELECT Id, CurrencyISOCode from Apttus_Config2__PriceList__c where id IN : priceListID ]);
             //SOQL Section
             Map<Id, Apttus__APTS_Agreement__c> agreementMap = getAgreements(agreementIdSet);
             Map<Id, Account> accountMap = getAccounts(soldToAccountIdSet);
             Map<Id, Apttus_Config2__AccountLocation__c> accountLocationMap = new  Map<Id, Apttus_Config2__AccountLocation__c>();  //v101.33 ++ <<>>
             
             if(!setLocationIDs.isEmpty())
             {
                 accountLocationMap = getAccountLocation(setLocationIDs);    //v101.33 ++ <<>>           
             }
             //SOQL Section
             
             if (String.isNotBlank(FIXEDTERMTYPE)) {
                 fixedTermTypeList = FIXEDTERMTYPE.split(',');
             }
             
             //v101.2 ++ <<
             if (String.isNotBlank(FIXEDCOST)) {
                 SapFixedCostList = FIXEDCOST.split(',');
             }
             
             if (String.isNotBlank(ALLINGREDIENTS)) {
                 SapAllIngredientsList = ALLINGREDIENTS.split(',');
             }
             
             if (String.isNotBlank(FIXEDCOSTANDINGREDIENTS)) {
                 SapFixedCostsAndIngredients = FIXEDCOSTANDINGREDIENTS.split(',');
             }
             //v101.2 ++ >>
             
             //Main loop
             for (Apttus_Config2__Order__c oOrder : orderList) {
                 
                 soldToAccount = accountMap.get(oOrder.Apttus_Config2__SoldToAccountId__c);
                 //v101.13 ++ >> bypassing setting of custom status for SAP order Type XD09 and XD12
                 //Copy status to custom status on order creation: Draft, In Amendment other than Admin Order - XD09 & XD12
                 if (!(APTS_BIRUtils.ADMINORDERSAPORDERTYPE.equalsIgnoreCase(oOrder.APTS_SAP_OrderType__c)
                       || APTS_BIRUtils.CONSUMPTIONSAPORDERTYPE.equalsIgnoreCase(oOrder.APTS_SAP_OrderType__c))
                     && ! APTS_BIRUtils.ADMINORDER.equalsIgnoreCase(oOrder.APTS_Order_Type__c)) {
                         oOrder.APTS_Status__c = oOrder.Apttus_Config2__Status__c;
                     }
                 
                 //v101.13 -- >> bypassing setting of custom status for SAP order Type XD09 and XD12
                 //Set way of delivery and ordering
                 if (oOrder.APTS_Order_Type__c == 'Standard Order' && oOrder.APTS_Order_Sub_Type__c == 'Digital Order') {
                     oOrder.APTS_Way_Of_Delivery__c = 'LSP';
                     oOrder.APTS_Way_Of_Ordering__c = 'Online';
                 } else if (oOrder.APTS_Order_Type__c == 'Route Sales Order') {
                     oOrder.APTS_Way_Of_Delivery__c = 'Routesales';
                     oOrder.APTS_Way_Of_Ordering__c = 'Routesales';
                 } else if (oOrder.APTS_Order_Type__c == 'Operating Order') {
                     oOrder.APTS_Way_Of_Delivery__c = 'LSP';
                     oOrder.APTS_Way_Of_Ordering__c = 'Operator';
                 } else if (oOrder.APTS_Order_Type__c == 'Standard Order' || oOrder.APTS_Order_Type__c == 'Machine Order') {
                     oOrder.APTS_Way_Of_Delivery__c = 'LSP';
                     oOrder.APTS_Way_Of_Ordering__c = 'Sales Support';  
                 }
                 
                 //v101.9 ++ <<
                 if ( oOrder.APTS_Order_Sub_Type__c != 'Digital Order') {
                     if (MapIDPriceList.containsKey(oOrder.Apttus_Config2__PriceListId__c)) {
                         oOrder.CurrencyISOCode = MapIDPriceList.get(oOrder.Apttus_Config2__PriceListId__c).CurrencyISOCode;
                     }
                 }
                 //v101.9 ++ >>
                //v101.39 ++<<
                   if(oOrder.APTS_SAP_OrderType__c =='XD01' && oOrder.APTS_Scenario__c=='Trial to Sales' && oOrder.APTS_Contract_Change__c=='Yes'){
                    oOrder.APTS_Order_Reason__c ='X98';
                }
                //v101.39 ++>>
                 
                 Apttus__APTS_Agreement__c oAgreement = agreementMap.get(oOrder.Apttus_CMConfig__AgreementId__c);
                 if (oAgreement != null) {
                     //v101.31,v101.32 ++<<
                     system.debug('@@@'+oOrder.APTS_Bill_to_Party_Ingredients_and_Payer__c);
                     oOrder.APTS_Bill_to_Party_Ingredients_and_Payer__c = oOrder.APTS_Bill_to_Party_Ingredients_and_Payer__c==null?oOrder.Apttus_Config2__SoldToAccountId__c:oOrder.APTS_Bill_to_Party_Ingredients_and_Payer__c;
                     oOrder.APTS_Bill_to_Party_Machines_Services__c = oOrder.APTS_Bill_to_Party_Machines_Services__c==null?oOrder.Apttus_Config2__SoldToAccountId__c:oOrder.APTS_Bill_to_Party_Machines_Services__c;
                     oOrder.APTS_PayerIngredients__c = oOrder.APTS_PayerIngredients__c==null?oOrder.Apttus_Config2__SoldToAccountId__c:oOrder.APTS_PayerIngredients__c;
                     oOrder.APTS_PayerMachinesServices__c = oOrder.APTS_PayerMachinesServices__c==null?oOrder.Apttus_Config2__SoldToAccountId__c:oOrder.APTS_PayerMachinesServices__c;
                     //v101.31,v101.32 ++>>
                     
                     
                     //v101.2 ++ <<
                     // check APTS_Fixed_Term_Type value
                     if (oAgreement.APTS_Fixed_Term_Type__c != null && oAgreement.APTS_Fixed_Term_Type__c == 'Fixed Cost') {
                         if (SapFixedCostList.contains(oOrder.APTS_SAP_OrderType__c)) {
                             oOrder.APTS_Fix_Term_Billing_Flag__c = 'Z';
                         }
                     } else if (oAgreement.APTS_Fixed_Term_Type__c != null && oAgreement.APTS_Fixed_Term_Type__c == 'All Ingredients') {
                         if (SapAllIngredientsList.contains(oOrder.APTS_SAP_OrderType__c)) {
                             oOrder.APTS_Fix_Term_Billing_Flag__c = 'Z';
                         }
                         
                     } else if (oAgreement.APTS_Fixed_Term_Type__c != null && oAgreement.APTS_Fixed_Term_Type__c == 'Fixed Costs and Ingredients') {
                         if (!SapFixedCostsAndIngredients.contains(oOrder.APTS_SAP_OrderType__c) && oOrder.APTS_SAP_OrderType__c != 'XD09' && oOrder.APTS_Fix_Term_Billing_Flag__c == null) {
                             oOrder.APTS_Fix_Term_Billing_Flag__c = 'Z';
                         }
                     }
                     
                     //v101.2 ++ >>
                     //check on Contract false
                     if (MACHINEORDER.equalsIgnoreCase(oOrder.APTS_Order_Type__c) || (oOrder.APTS_Order_Type__c == 'Admin Order' && oOrder.APTS_Order_Sub_Type__c == 'Conversion Order')) {
                         //if Machine Order than check below fields
                         if (!oAgreement.APTS_Check_on_Account_Machines__c) {
                             isCheckOnAccount = false;
                             oOrder.Apttus_Config2__BillToAccountId__c = oAgreement.APTS_Bill_to_Party_MachServ__c;
                             oOrder.APTS_Payer__c = oAgreement.APTS_Payer_Machines_Services__c;
                         }
                     } 
                     //  v101.18 ++ << 25-02-2019 Balashanthi : Defect # 5361 ADMIN orders payer not correct showing sold to party instead of payer - Added XD12 and XD09 Rsstriction condition
                     else if (!STANDARD_RETURN.equalsIgnoreCase(oOrder.APTS_Order_Sub_Type__c)
                              && !ADMINORDERDOCTYPE.equalsIgnoreCase(oOrder.APTS_SAP_OrderType__c)
                              && !CONSUMTPIONDOCTYPE.equalsIgnoreCase(oOrder.APTS_SAP_OrderType__c)) {
                                  //if not Machine Order and Not Standard Return Order
                                  if (!oAgreement.APTS_Check_on_Account_Ingredients__c) {
                                      isCheckOnAccount = false;
                                      oOrder.Apttus_Config2__BillToAccountId__c = oAgreement.APTS_Bill_to_Party_Ingredients__c;
                                      oOrder.APTS_Payer__c = oAgreement.APTS_Payer_Ingredients__c;
                                  }
                              }
                 }
                 //v101.7 ++ >> Logic added in else if condition
                 //v101.8 ++ >> Restricting BillTo overrriden for Doc Type XD01,XD12 - Added in else if condition
                 if (isCheckOnAccount && soldToAccount != NULL) {
                     if (MACHINEORDER.equalsIgnoreCase(oOrder.APTS_Order_Type__c) || (oOrder.APTS_Order_Type__c == 'Admin Order' && oOrder.APTS_Order_Sub_Type__c == 'Conversion Order')) {
                         oOrder.Apttus_Config2__BillToAccountId__c = soldToAccount.Related_Bill_to_Machines_Services__c;
                         oOrder.APTS_Payer__c = soldToAccount.Related_Payer_Machines_Services__c;
                     } else if (!STANDARD_RETURN.equalsIgnoreCase(oOrder.APTS_Order_Sub_Type__c)
                                && !CREDITDOC.equalsIgnoreCase(oOrder.APTS_SAP_OrderType__c)
                                && !ADMINORDERDOCTYPE.equalsIgnoreCase(oOrder.APTS_SAP_OrderType__c)
                                && !CONSUMTPIONDOCTYPE.equalsIgnoreCase(oOrder.APTS_SAP_OrderType__c)) {
                                    oOrder.Apttus_Config2__BillToAccountId__c = soldToAccount.Bill_To_Payer_Account__c;
                                    oOrder.APTS_Payer__c = soldToAccount.Related_Payer_Account__c;
                                }
                 }
                 if (oOrder.Apttus_Config2__BillToAccountId__c == NULL) {
                     oOrder.Apttus_Config2__BillToAccountId__c = oOrder.Apttus_Config2__SoldToAccountId__c;
                 }
                 
                 if (oOrder.APTS_Payer__c == NULL) {
                     oOrder.APTS_Payer__c = oOrder.Apttus_Config2__SoldToAccountId__c;
                 }
                 
                 if (oOrder.Apttus_Config2__ShipToAccountId__c == NULL) {
                     oOrder.Apttus_Config2__ShipToAccountId__c = oOrder.Apttus_Config2__SoldToAccountId__c;
                 }
                 
                 //set end date on all order types except Machine Order
                 if (!MACHINEORDER.equalsIgnoreCase(oOrder.APTS_Order_Type__c) && oOrder.APTS_SAP_OrderType__c != 'XD01') {
                     if (oAgreement != NULL && oAgreement.Apttus__Subtype__c == 'Fixed End Date') {
                         oOrder.Apttus_Config2__OrderEndDate__c = oAgreement.Apttus__Contract_End_Date__c;
                     } else {
                         oOrder.Apttus_Config2__OrderEndDate__c = oAgreement != NULL && oAgreement.APTS_Agreement_Duration_Months__c != NULL && oAgreement.APTS_Agreement_Duration_Months__c > 0 ? System.today().addMonths(Integer.valueOf(Math.Round(oAgreement.APTS_Agreement_Duration_Months__c))) : System.today().addYears(5);
                     }
                 }
                 // v101.10 ++ << changes by balashanthi for Defect # 21146 starts
                 if (APTS_BIRUtils.ACTIVATED.equalsIgnoreCase(oOrder.Apttus_Config2__Status__c)
                     &&  APTS_BIRUtils.CREDITMEMO.equalsIgnoreCase(oOrder.APTS_Order_Type__c)
                     &&  APTS_BIRUtils.CREDITSAPORDERTYPE.equalsIgnoreCase(oOrder.APTS_SAP_OrderType__c)) {
                         if (oOrder.Apttus_Config2__ActivatedDate__c != null) {
                             oOrder.APTS_Billing_Date__c = oOrder.Apttus_Config2__ActivatedDate__c.date();
                         }
                     }
                 // v101.10 ++ >> Defect # 21146 ENDS
                 
                 //v101.21 ++ << CR 2158
                 if(soldToAccount != null && orderTypesList.contains(oOrder.APTS_Order_Type__c)) {
                     oOrder.APTS_EDI_Reference_Number__c = soldToAccount.EDI_Reference_Number__c;
                 }
                 
                /* if(oOrder.APTS_Primary_ContactId_Filtered__c != NULL && oOrder.Apttus_Config2__PrimaryContactId__c == NULL){
                     oOrder.Apttus_Config2__PrimaryContactId__c = oOrder.APTS_Primary_ContactId_Filtered__c;
                 }else if(oOrder.APTS_Primary_ContactId_Filtered__c == NULL && oOrder.Apttus_Config2__PrimaryContactId__c != NULL){
                     oOrder.APTS_Primary_ContactId_Filtered__c = oOrder.Apttus_Config2__PrimaryContactId__c;
                 } */
                 ////v101.21 ++ >>  
                 //V101.33 ++ <<        
                 if(!accountLocationMap.isEmpty()) 
                 {      
                 if(string.isBlank(oOrder.APTS_Customer_Comments__c))
                 {
                     oOrder.APTS_Customer_Comments__c = accountLocationMap.get(oOrder.Apttus_Config2__LocationId__c).Delivery_text__c;
                 }
                 if(string.isBlank(oOrder.APTS_Picking_list_text__c))
                 {
                    oOrder.APTS_Picking_list_text__c = accountLocationMap.get(oOrder.Apttus_Config2__LocationId__c).Picking_list_text__c;
                 }
                 }
                 //V101.33 ++ >>
             }
             //Main loop
         }

    //@Description : Method to get executed afterInsert
    public void afterInsert(List<SObject> newList, Map<Id, SObject> newItems) {
    }

    //@Description : Method to get executed beforeUpdate
    public void beforeUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldItems) {
        DescribeSObjectResult objResultOIntLog = APTS_OTCUtil.getsObjectAccess(INTLOG); // CRUD/FLS Check
        System.debug('Order trigger in beforeUpdate-------------');
        //Variable Section
        Map<Id, Apttus_Config2__Order__c> orderIdToOrderMap = (Map<Id, Apttus_Config2__Order__c>) newItems;
        Map<Id, Apttus_Config2__Order__c> orderIdToOldOrderMap = (Map<Id, Apttus_Config2__Order__c>) oldItems;
        System.debug('@@@@@@orderIdToOrderMap  '+orderIdToOrderMap);
        System.debug('@@@@@@orderIdToOldOrderMap  '+orderIdToOldOrderMap);

        Account soldToAccount = null;

        Set<Id> orderFromAcceptOrderSet = new Set<Id>();
        Set<Id> orderWithStatusUpdateSet = new Set<Id>();
        Set<Id> orderWithFistSAPUpdateSet = new Set<Id>();
        Set<Id> orderWithFirstTSUpdateSet = new Set<Id>();
        Set<Id> orderWithActivatedStatusSet = new Set<Id>();
        Set<Id> orderWithInstallationDateChangeSet = new Set<Id>();
        //v101.26 (3.1) << ++
        Set<Id> orderWithDeInstallationDateChangeOnlySet = new Set<Id>();
        //v101.26 (3.1) ++ >>
        Set<Id> orderWithDeliveryDateChangeSet = new Set<Id>();
        Set<Id> orderidset = new Set<Id>();
        Set<Id> orderSet = new Set<Id>();
        Set<Id> accountLocationSetId = new Set<Id>();
        Set<Id> soldToAccountIdSet = new Set<Id>();
        Map<Id, List<CountrySetting__c>> orderIdToCountrySettingListMap = new Map<Id, List<CountrySetting__c>>();
        List<Integration_Log__c> integrationLogToInsertList = new List<Integration_Log__c>();
        List<APTS_FixTerm_Billing_Flag__mdt> fixTermBillingMdt = [Select Id,DeveloperName,Credit_Debit_For__c,
                                                                    Fixed_Term_Type__c,FixTerm_Billing_Flag__c,Order_Source__c,
                                                                    Order_Type__c From APTS_FixTerm_Billing_Flag__mdt];
        List<String> fixedTermList = new List<String>();
        Set<Id> agreementIdSet = new Set<Id>();

        //Variable Section
        
        //try {
        //Initial loop
        for (Apttus_Config2__Order__c oOrder : orderIdToOrderMap.values()) {

            //Order will call acceptOrder API this will change Apttus_Config2__Status__c from Draft or In Amendment to Pending
            //On this action we'll set custom status to SUBMITTED
            Boolean bOldStatusDraftOrInAmendment = orderIdToOldOrderMap.get(oOrder.Id).Apttus_Config2__Status__c == DRAFT || orderIdToOldOrderMap.get(oOrder.Id).Apttus_Config2__Status__c == IN_AMENDMENT;
            if (bOldStatusDraftOrInAmendment && oOrder.Apttus_Config2__Status__c == PENDING) {
                orderFromAcceptOrderSet.add(oOrder.Id);
            } 
            // v101.20 ++ << 
            /*else if (oOrder.Apttus_Config2__Status__c != PENDING && orderIdToOldOrderMap.get(oOrder.Id).Apttus_Config2__Status__c != PENDING && orderIdToOldOrderMap.get(oOrder.Id).Apttus_Config2__Status__c != oOrder.Apttus_Config2__Status__c) {
                //For all other updates on order status set order custom status to order status 
                orderWithStatusUpdateSet.add(oOrder.Id);
            }*/
            // v101.20 ++ >>
            // v101.36 ++ <<
              else if(oOrder.Apttus_Config2__Status__c != PENDING && orderIdToOldOrderMap.get(oOrder.Id).Apttus_Config2__Status__c != oOrder.Apttus_Config2__Status__c){ 
                orderWithStatusUpdateSet.add(oOrder.Id);
            } 
            // v101.36 ++ >>
            //First SAP update: SAP will populate APTS_Order_Header_SAP_ID__c
            //On this action we will set APTS_Sales_Order_Change_Indicator__c = L004;
            //Boolean bSAPUpdate = oOrder.LastModifiedBy.Name == SAP_INTEGRATION_USER;//TO DO- Add this check on all SAP updates
            //if (bSAPUpdate && orderIdToOldOrderMap.get(oOrder.Id).APTS_Order_Header_SAP_ID__c == null && oOrder.APTS_Order_Header_SAP_ID__c != null) {
            if (orderIdToOldOrderMap.get(oOrder.Id).APTS_Order_Header_SAP_ID__c == null && oOrder.APTS_Order_Header_SAP_ID__c != null) {
                orderWithFistSAPUpdateSet.add(oOrder.Id);
            }

            //If ATP fails for machine orders then user needs to change requested installation date then requested delivery date must be recalculated
            if (orderIdToOldOrderMap.get(oOrder.Id).APTS_Requested_Installation_Date__c != oOrder.APTS_Requested_Installation_Date__c) {
                orderWithInstallationDateChangeSet.add(oOrder.Id);
            }
            
            //v101.26 (3.1) ++ <<
            if (orderIdToOldOrderMap.get(oOrder.Id).APTS_Requested_De_Installation_Date__c != oOrder.APTS_Requested_De_Installation_Date__c) {
                //v101.27 (3.1) ++ <<
                String dayOfWeek = oOrder.APTS_Requested_De_Installation_Date__c.format(E);
                if (!MON.equalsIgnoreCase(dayOfWeek)) {
                    oOrder.addError(REQUESTEDDELIVERYDATEMONDAYMSG);
                }
                //v101.27 (3.1) ++ >>
                else {
                    orderWithDeInstallationDateChangeOnlySet.add(oOrder.Id);
                }
            }
            //v101.26 (3.1) ++ >>
            
            //v101.30 ++ <<
            if (orderIdToOldOrderMap.get(oOrder.Id).APTS_Requested_Movement_Date__c != oOrder.APTS_Requested_Movement_Date__c) {
                String dayOfWeek = oOrder.APTS_Requested_Movement_Date__c.format(E);
                if (!MON.equalsIgnoreCase(dayOfWeek)) {
                    oOrder.addError(REQUESTEDMOVEMENTDATEMONDAYMSG);
                }
            }
            //v101.30 ++ >>
            

            //If ATP fails for standard order then user needs to change requested delivery date then requested delivery date must be recalculated
            if (orderIdToOldOrderMap.get(oOrder.Id).APTS_Requested_Delivery_Date__c != oOrder.APTS_Requested_Delivery_Date__c) {
                orderWithDeliveryDateChangeSet.add(oOrder.Id);
            }

            //First TS update: TS will store APTS_Delivery_Date_Authorized__c, APTS_Pick_Up_Date_Authorized__c and APTS_Movement_Date_Authorized__c
            //On this action we will set APTS_Delivery_Block__c to blank, APTS_Requested_Delivery_Date__c = APTS_Delivery_Date_Authorized__c
            //and will Order to SAP
            //Boolean bLSPDeliveryDateChanged = orderIdToOldOrderMap.get(oOrder.Id).APTS_Delivery_Date_Authorized__c == null && oOrder.APTS_Delivery_Date_Authorized__c != null;
            //Boolean bLSPPickUpDateChanged = orderIdToOldOrderMap.get(oOrder.Id).APTS_Pick_Up_Date_Authorized__c == null && oOrder.APTS_Pick_Up_Date_Authorized__c != null;
            //Boolean bLSPMovementDateChanged = orderIdToOldOrderMap.get(oOrder.Id).APTS_Movement_Date_Authorized__c == null && oOrder.APTS_Movement_Date_Authorized__c != null;
            //v101.38 ++ <<
            Boolean bLSPDeliveryDateChanged = orderIdToOldOrderMap.get(oOrder.Id).APTS_Delivery_Date_Authorized__c != oOrder.APTS_Delivery_Date_Authorized__c;
            Boolean bLSPPickUpDateChanged = orderIdToOldOrderMap.get(oOrder.Id).APTS_Pick_Up_Date_Authorized__c != oOrder.APTS_Pick_Up_Date_Authorized__c;
            Boolean bLSPMovementDateChanged = orderIdToOldOrderMap.get(oOrder.Id).APTS_Movement_Date_Authorized__c != oOrder.APTS_Movement_Date_Authorized__c;
            //v101.38 ++ >>

            if (bLSPDeliveryDateChanged || bLSPPickUpDateChanged || bLSPMovementDateChanged) {
                orderWithFirstTSUpdateSet.add(oOrder.Id);
            }

            //After order is Activated we must calculate max activation date
            if (orderIdToOldOrderMap.get(oOrder.Id).Apttus_Config2__Status__c != ACTIVATED && oOrder.Apttus_Config2__Status__c == ACTIVATED) {
                orderWithActivatedStatusSet.add(oOrder.Id);
            }
            //If Requested de-installation date is changed set this date as RDD???
            //v101.8 ++ <<
            /*  if (orderIdToOldOrderMap.get(oOrder.Id).APTS_Requested_De_Installation_Date__c == null && oOrder.APTS_Requested_De_Installation_Date__c != null && oOrder.APTS_SAP_OrderType__c == 'XB13') {
                oOrder.APTS_Requested_Delivery_Date__c = Date.valueof(oOrder.APTS_Requested_De_Installation_Date__c) ;
            } */
            //v101.8 ++ >>

            //Set order end date based on the roll up summary of the Selling Term
            if (oOrder.APTS_Order_Selling_Term__c != null && oOrder.APTS_Order_Selling_Term__c != 0) {
                if (oOrder.Apttus_CMConfig__AgreementId__r != NULL && oOrder.Apttus_CMConfig__AgreementId__r.Apttus__Subtype__c == 'Fixed End Date') {
                    oOrder.Apttus_Config2__OrderEndDate__c = oOrder.Apttus_CMConfig__AgreementId__r.Apttus__Contract_End_Date__c;
                } else {
                    oOrder.Apttus_Config2__OrderEndDate__c = oOrder.Apttus_Config2__OrderStartDate__c.addMonths(Integer.ValueOf(oOrder.APTS_Order_Selling_Term__c));
                } 
            }
            //v101.6 ++ << Adding account location Id to set variable
            if (oOrder.Apttus_Config2__LocationId__c != NULL && orderIdToOldOrderMap.get(oOrder.Id).Apttus_Config2__LocationId__c != oOrder.Apttus_Config2__LocationId__c) {
                accountLocationSetId.add(oOrder.Apttus_Config2__LocationId__c);
            }
            //v101.6
            soldToAccountIdSet.add(oOrder.Apttus_Config2__SoldToAccountId__c);
            agreementIdSet.add(oOrder.Apttus_CMConfig__AgreementId__c);

        }

        //SOQL Section
        Map<Id, List<Apttus_Config2__OrderLineItem__c>> orderIdToOrderLineItemsMap = getOrderLineItems(orderWithActivatedStatusSet);
        Map<Id, Apttus_Config2__AccountLocation__c> accountLocationMap = getAccountLocation(accountLocationSetId);
        Map<Id, Account> accountMap = getAccounts(soldToAccountIdSet);

        if (!orderWithInstallationDateChangeSet.isEmpty() || !orderWithDeliveryDateChangeSet.isEmpty()) {
            orderIdToCountrySettingListMap = APTS_OrderUtils.prepareOrderIdToCountrySettingListMap(orderIdToOrderMap);
        }
        Map<Id, Apttus__APTS_Agreement__c> agreementMap = getAgreements(agreementIdSet);

        //SOQL Section 

        //Main loop
        for (Apttus_Config2__Order__c oOrder : orderIdToOrderMap.values()) {
                     
            //Order will call acceptOrder API
            if (orderFromAcceptOrderSet.contains(oOrder.Id)) {
                oOrder.APTS_Status__c = SUBMITTED;
            }
            
            //Handle all other status updates: Being Amended, Superseded
            if (orderWithStatusUpdateSet.contains(oOrder.Id)) {
                oOrder.APTS_Status__c = oOrder.Apttus_Config2__Status__c;
            }
            //First SAP update
            if (orderWithFistSAPUpdateSet.contains(oOrder.Id)) {
                oOrder.APTS_Sales_Order_Change_Indicator__c = L004;
            }
            //change of requested installation date
            if (orderWithInstallationDateChangeSet.contains(oOrder.Id)) {
                //v101.5 ++ <<
                List<CountrySetting__c> countrySettingList = orderIdToCountrySettingListMap.get(oOrder.Id);
                oOrder.APTS_Requested_Delivery_Date__c = APTS_OrderUtils.checkRequestedDeliveryDateInWorkingHours(oOrder, countrySettingList, oOrder.APTS_Requested_Installation_Date__c);
                //v101.5 ++ >>
            }
            
            //change of requested de-installation date
            //v101.26 (3.1) ++ <<
             if (orderWithDeInstallationDateChangeOnlySet.contains(oOrder.Id)) {
                DateTime dT = oOrder.APTS_Requested_De_Installation_Date__c;
                Date reqDeinstalldate = Date.newinstance(dT.year(), dT.month(), dT.day());
                oOrder.APTS_Requested_Delivery_Date__c = APTS_OrderUtils.checkRequestedDeliveryDateInWorkingHours(oOrder, reqDeinstalldate);
            }
            //v101.26 (3.1) ++ <<

            //First TS update
            if (orderWithFirstTSUpdateSet.contains(oOrder.Id)) {
                oOrder.APTS_Delivery_Block__c = null;
                //V101.15
                //v101.28 << ++
                oOrder.APTS_Requested_Delivery_Date__c = (oOrder.APTS_Movement_Date_Authorized__c != null) ? oOrder.APTS_Movement_Date_Authorized__c :((oOrder.APTS_Delivery_Date_Authorized__c != null) ? oOrder.APTS_Delivery_Date_Authorized__c : oOrder.APTS_Pick_Up_Date_Authorized__c);
                //v101.28 ++ >>
                oOrder.APTS_LSP_Movement_Date__c = oOrder.APTS_Movement_Date_Authorized__c;
                oOrder.APTS_LSP_Delivery_Date__c = oOrder.APTS_Delivery_Date_Authorized__c;
                oOrder.APTS_LSP_Pick_Up_Date__c = oOrder.APTS_Pick_Up_Date_Authorized__c;

                integrationLogToInsertList.add(APTS_OrderUtils.createIntegrationLog(oOrder));
            }
            //After order is Activated we must calculate max activation date
            if (orderWithActivatedStatusSet.contains(oOrder.Id)) {
                List<Apttus_Config2__OrderLineItem__c> orderLineItemList = orderIdToOrderLineItemsMap.get(oOrder.Id);
                if (oOrder.APTS_Order_Sub_Type__c == INSTALLATION) {

                    Datetime dtMaxDate = getMaxOrderActivationDate(orderLineItemList, oOrder.APTS_Order_Sub_Type__c);

                    if (dtMaxDate != null) {
                        oOrder.APTS_Confirmed_Installation_Date__c = dtMaxDate;
                    }
                } else if (oOrder.APTS_Order_Sub_Type__c == DE_INSTALLATION) {

                    Datetime dtMaxDate = getMaxOrderActivationDate(orderLineItemList, oOrder.APTS_Order_Sub_Type__c);

                    if (dtMaxDate != null) {
                        oOrder.APTS_Confirmed_De_Installation_Date__c = dtMaxDate;
                    }
                }
            }
 
            if (oOrder.APTS_LSP_Delivery_Date__c != NULL) {
                oOrder.APTS_Delivery_Block__c = Null;
            }
            //v101.6 ++ <<
            if (oOrder.Apttus_Config2__LocationId__c != NULL && orderIdToOldOrderMap.get(oOrder.Id).Apttus_Config2__LocationId__c != oOrder.Apttus_Config2__LocationId__c) {
                oOrder.APTS_Customer_Comments__c = accountLocationMap.get(oOrder.Apttus_Config2__LocationId__c).Delivery_text__c;
                //oOrder.APTS_Invoice_Remark__c = accountLocationMap.get(oOrder.Apttus_Config2__LocationId__c).Billing_header_text__c;
            //V101.25 ++ << 
             if (MACHINEORDER.equalsIgnoreCase(oOrder.APTS_Order_Type__c) || STANDARDORDER.equalsIgnoreCase(oOrder.APTS_Order_Type__c)) {
                oOrder.APTS_Picking_list_text__c = accountLocationMap.get(oOrder.Apttus_Config2__LocationId__c).Picking_list_text__c;
               }
            //V101.25 ++ >>
            }

            soldToAccount = accountMap.get(oOrder.Apttus_Config2__SoldToAccountId__c);
            /*if (soldToAccount.Billing_header_text__c != null && soldToAccount.Billing_header_text__c.length() > 255) {
                oOrder.APTS_Invoice_Remark__c = soldToAccount.Billing_header_text__c.left(255);
            } else {
                oOrder.APTS_Invoice_Remark__c = soldToAccount.Billing_header_text__c;
            }*/
            if (String.isBlank(oOrder.APTS_Invoice_Remark__c) && soldToAccount != null && soldToAccount.Billing_header_text__c != null) {
                oOrder.APTS_Invoice_Remark__c = soldToAccount.Billing_header_text__c.length() > 255 ? soldToAccount.Billing_header_text__c.left(255) : soldToAccount.Billing_header_text__c;
            }
            //v101.6 ++ >>
            //check locked
            if (oOrder.APTS_Lock_Order__c && orderIdToOldOrderMap.get(oOrder.Id).APTS_Lock_Order__c) {
                oOrder.addError('This Order record is locked.');
            }
            
           /* if(orderIdToOldOrderMap.get(oOrder.Id).APTS_Primary_ContactId_Filtered__c != oOrder.APTS_Primary_ContactId_Filtered__c){
                oOrder.Apttus_Config2__PrimaryContactId__c = oOrder.APTS_Primary_ContactId_Filtered__c;
            }else if(orderIdToOldOrderMap.get(oOrder.Id).Apttus_Config2__PrimaryContactId__c != oOrder.Apttus_Config2__PrimaryContactId__c){
                oOrder.APTS_Primary_ContactId_Filtered__c = oOrder.Apttus_Config2__PrimaryContactId__c;
            } */
            //v101.34 <<Starts++
            if(oOrder.APTS_SAP_OrderType__c==CREDITDOC
                && orderIdToOldOrderMap.get(oOrder.Id).Approval_Status__c!='Approved' 
                && oOrder.Approval_Status__c =='Approved'){
                oOrder.Apttus_Config2__Status__c = ACTIVATED;
                oOrder.APTS_Status__c = APTS_BIRUtils.INVOICINGSTATUS;//v130
                oOrder.APTS_Remove_Billing_Block_Indicator__c = true;
                oOrder.APTS_Billing_Date__c = system.today();
                integrationLogToInsertList.add(APTS_OrderUtils.createIntegrationLog(oOrder));
            }
            ///v101.34 ++Ends>>
            
            //v101.37 << Starts++
            Apttus__APTS_Agreement__c oAgreement = agreementMap.get(oOrder.Apttus_CMConfig__AgreementId__c);

            if(String.IsNotBlank(oOrder.APTS_Credit_Debit_For__c) && String.IsNotBlank(oOrder.Apttus_Config2__Source__c) 
                && oOrder.Apttus_Config2__Source__c == ACCOUNT && oAgreement != null){
                oOrder.APTS_Fix_Term_Billing_Flag__c = '';
                for(APTS_FixTerm_Billing_Flag__mdt fixTermFlag: fixTermBillingMdt){
                    fixedTermList = fixTermFlag.Fixed_Term_Type__c.split(',');
                    if(fixTermFlag.Credit_Debit_For__c.equalsIgnoreCase(oOrder.APTS_Credit_Debit_For__c) 
                        && fixTermFlag.Order_Type__c.contains(oOrder.APTS_SAP_OrderType__c)
                        && (fixedTermList.contains(oAgreement.APTS_Fixed_Term_Type__c) 
                            || (String.IsBlank(oAgreement.APTS_Fixed_Term_Type__c) && fixedTermList.contains('BLANK')))){
                        oOrder.APTS_Fix_Term_Billing_Flag__c = fixTermFlag.FixTerm_Billing_Flag__c;
                        break;
                    }
                }
            }
            //v101.37 ++Ends>>
        }

        //Additional logic
        List<Integration_Log__c> integrationLogToInsert = APTS_BIRUtils.removeBillingBlockForStandardOrders(newList, newItems, oldList, oldItems);
        if (!integrationLogToInsert.isEmpty()) {
            for (Integration_Log__c integrationLog : integrationLogToInsert) {
                if (!integrationLogToInsertList.contains(integrationLog)) {
                    integrationLogToInsertList.add(integrationLog);
                }
            }
        }
        //Additional logic

        //DML Section
        if (!integrationLogToInsertList.isEmpty()) {
            if (objResultOIntLog.isCreateable()) {
                Database.insert(integrationLogToInsertList);
            }
        }

        //DML Section
        //} catch (Exception e) {
        //    APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id), 'OM', false, true, EMAIL, true);
        //}
    }

    //@Description : Method to get executed afterUpdate
    public void afterUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldItems) {
        System.debug('Order trigger in afterUpdate ==>');

        DescribeSObjectResult objResultWorkOrder = APTS_OTCUtil.getsObjectAccess(WORKOTRIGGER); // CRUD/FLS Check
        DescribeSObjectResult objResultOrder = APTS_OTCUtil.getsObjectAccess(ORDERCRUD); // CRUD/FLS Check
        DescribeSObjectResult objResultOrderLI = APTS_OTCUtil.getsObjectAccess(ORDElIRCRUD); // CRUD/FLS Check
        DescribeSObjectResult objResultPhyAssets = APTS_OTCUtil.getsObjectAccess(PHYASST); // CRUD/FLS Check

        //Variable Section
        Map<Id, Apttus_Config2__Order__c> orderIdToOrderMap = (Map<Id, Apttus_Config2__Order__c>) newItems;
        Map<Id, Apttus_Config2__Order__c> orderIdToOldOrderMap = (Map<Id, Apttus_Config2__Order__c>) oldItems;

        //APTS_GalinUtils.compareOrderTriggerNewAndOld(orderIdToOrderMap, orderIdToOldOrderMap, 'afterUpdate');
        Set<Id> orderIdWithSoldToChangeSet = new Set<Id>();
        Set<Id> orderIdForOLISelectSet = new Set<Id>();
        Set<Id> orderIdForWOTCreationSet = new Set<Id>();
        Set<Id> orderIdForInstallWorkOrderCreationSet = new Set<Id>();
        Set<Id> orderIdForDeInstallWorkOrderCreationSet = new Set<Id>();
        Set<Id> orderIdForConversionWorkOrderCreationSet = new Set<Id>();
        Set<Id> orderIdForMovementWorkOrderCreationSet = new Set<Id>();
        Set<Id> orderIdForSwapWorkOrderCreationSet = new Set<Id>();
        List<PhysicalAsset__c> physicalAssetToUpdateList = new List<PhysicalAsset__c>();
        List<WorkOrderTrigger__c> workOrderToCreateList = new List<WorkOrderTrigger__c>();
        List<Apttus_Config2__Order__c> orderToUpdateList = new List<Apttus_Config2__Order__c>();
        Map<Id, Apttus_Config2__Order__c> idToOrderForWorkOrderCreationMap = new Map<Id, Apttus_Config2__Order__c>();
        String sWOTType = '';
        //v101.1 ++ <<
        Set<Id> orderWithRejectReasonUpdateSet = new Set<Id>();
        List<Apttus_Config2__OrderLineItem__c> listOrderLineItemToUpdate = new List<Apttus_Config2__OrderLineItem__c>();
        List<Id> orderIdToSubmitList = new List<Id>();
        //v101.1 ++ >>
        Boolean bUpdateATPResultOnWOLI = false;
        //Variable Section

        //try {
        //Initial loop

        for (Apttus_Config2__Order__c oOrder : orderIdToOrderMap.values()) {

            //First SAP update on order line items: If all order line items are good OLI trigger will store APTS_ATP_Check_Status__c == PASS
            //On this action we will create work order
            //v101.23 ++ <<
            Boolean bATPCheckStatusPass =  orderIdToOldOrderMap.get(oOrder.Id).APTS_ATP_Check_Status__c != PASS && oOrder.APTS_ATP_Check_Status__c == PASS && oOrder.APTS_Work_Order_Created__c == false; 
            Boolean bInstallationRequired ;
            //v101.23 ++ >>
            
           //Install order - WOT
            if (bATPCheckStatusPass && oOrder.APTS_Order_Type__c == MACHINE_ORDER && oOrder.APTS_Order_Sub_Type__c == INSTALLATION) {
                    orderIdForOLISelectSet.add(oOrder.Id);
                    orderIdForInstallWorkOrderCreationSet.add(oOrder.Id);
                    sWOTType = 'install';
                    orderIdForWOTCreationSet.add(oOrder.Id);
            }
            //De-Install order - WOT
            if (bATPCheckStatusPass && oOrder.APTS_Order_Type__c == MACHINE_ORDER && oOrder.APTS_Order_Sub_Type__c == DE_INSTALLATION) {

                orderIdForOLISelectSet.add(oOrder.Id);
                orderIdForDeInstallWorkOrderCreationSet.add(oOrder.Id);
                sWOTType = 'deInstall';
                orderIdForWOTCreationSet.add(oOrder.Id);
            }
            //Conversion order - WOT
            if (bATPCheckStatusPass && oOrder.APTS_Order_Sub_Type__c == 'Conversion Order') {

                orderIdForOLISelectSet.add(oOrder.Id);
                orderIdForConversionWorkOrderCreationSet.add(oOrder.Id);
                sWOTType = 'conversion';
                orderIdForWOTCreationSet.add(oOrder.Id);
            }
            //Movement order - WOT
            if (bATPCheckStatusPass && (oOrder.APTS_Order_Sub_Type__c == INTERNAL_MOVEMENT || oOrder.APTS_Order_Sub_Type__c == EXTERNAL_MOVEMENT_WITHOUT_CONTRACT_CHANGE || oOrder.APTS_Order_Sub_Type__c == EXTERNAL_MOVEMENT_WITH_CONTRACT_CHANGE)) {

                orderIdForOLISelectSet.add(oOrder.Id);
                orderIdForMovementWorkOrderCreationSet.add(oOrder.Id);
                sWOTType = 'movement';
                orderIdForWOTCreationSet.add(oOrder.Id);
            }
            //Movement order - WOT
            if (bATPCheckStatusPass && (oOrder.APTS_Order_Sub_Type__c == TECHNICAL_SWAP || oOrder.APTS_Order_Sub_Type__c == COMMERCIAL_SWAP) && XA13.equalsIgnoreCase(oOrder.APTS_SAP_OrderType__c)) {
                orderIdForOLISelectSet.add(oOrder.Id);
                orderIdForOLISelectSet.add(oOrder.Apttus_Config2__ParentOrderId__c);
                orderIdForSwapWorkOrderCreationSet.add(oOrder.Id);
                orderIdForSwapWorkOrderCreationSet.add(oOrder.Apttus_Config2__ParentOrderId__c);
                sWOTType = 'swap';
                orderIdForWOTCreationSet.add(oOrder.Id);
            }

            Boolean bSoldToAccountCheck = orderIdToOldOrderMap.get(oOrder.Id).Apttus_Config2__SoldToAccountId__c != oOrder.Apttus_Config2__SoldToAccountId__c;
            if (bSoldToAccountCheck && String.IsNotBlank(oOrder.Apttus_Config2__SoldToAccountId__c)) {
                orderIdWithSoldToChangeSet.add(oOrder.Id);
                orderIdForOLISelectSet.add(oOrder.Id);
            }

            //v101.1++ <<
            if (oOrder.APTS_Reason_For_Rejection__c != NULL && oOrder.APTS_Reason_For_Rejection__c != orderIdToOldOrderMap.get(oOrder.Id).APTS_Reason_For_Rejection__c) {
                orderIdForOLISelectSet.add(oOrder.Id);
                orderWithRejectReasonUpdateSet.add(oOrder.Id);
            }
            //v101.1 ++ >>

            //v101.34++<<
            if(oOrder.APTS_SAP_OrderType__c==CREDITDOC
                && orderIdToOldOrderMap.get(oOrder.Id).Approval_Status__c!='Approved' 
                && oOrder.Approval_Status__c =='Approved'){
                orderIdForOLISelectSet.add(oOrder.Id);
            }//v101.34++>>
            //v101.40 ++ <<
            Boolean bATPResponseUpdate =  orderIdToOldOrderMap.get(oOrder.Id).APTS_ATP_Check_Status__c != oOrder.APTS_ATP_Check_Status__c && oOrder.APTS_Work_Order_Created__c == true; 
            Boolean bCaseCreated = orderIdToOldOrderMap.get(oOrder.Id).APTS_Case__c == null && oOrder.APTS_Case__c != null && oOrder.APTS_ATP_Check_Status__c == 'Pass';
            if (oOrder.APTS_Order_Type__c == MACHINE_ORDER && (bATPResponseUpdate || bCaseCreated || Test.isRunningTest())) {
                bUpdateATPResultOnWOLI = true;
            } //v101.40 ++ >>
              
        }
        //Initial loop

        //SOQL Section
        Map<Id, List<Apttus_Config2__OrderLineItem__c>> orderIdToOrderLineItemsMap = getOrderLineItems(orderIdForOLISelectSet);
        //V101.26 <<++
        List<Integer> lineNumberList = new List<Integer>();
        List<Apttus_Config2__OrderLineItem__c> oliList = new List<Apttus_Config2__OrderLineItem__c>();
        Map<Id, List<Apttus_Config2__OrderLineItem__c>> orderIdToOrderLineItemsInstDeInstReqMap = new Map<Id, List<Apttus_Config2__OrderLineItem__c>>(); 
                
        for (List<Apttus_Config2__OrderLineItem__c> oOrderLineItemList : orderIdToOrderLineItemsMap.values()) {
            for(Apttus_Config2__OrderLineItem__c oOrderLineItem : oOrderLineItemList){
                if(orderIdForOLISelectSet.contains(oOrderLineItem.Apttus_Config2__OrderId__c) && ((oOrderLineItem.APTS_Is_Primary_L1_Line__c == true && oOrderLineItem.APTS_Installation_Required__c == true) || (oOrderLineItem.APTS_Is_Primary_L1_Line__c == true && oOrderLineItem.APTS_de_Installation_Required__c == true)) ){
                    lineNumberList.add(Integer.valueOf(oOrderLineItem.Apttus_Config2__LineNumber__c));
                }
            }
        }
        for (List<Apttus_Config2__OrderLineItem__c> oOrderLineItemList : orderIdToOrderLineItemsMap.values()) {
            for(Apttus_Config2__OrderLineItem__c oOrderLineItem : oOrderLineItemList){
                if( orderIdForOLISelectSet.contains(oOrderLineItem.Apttus_Config2__OrderId__c) && lineNumberList.contains(Integer.valueOf(oOrderLineItem.Apttus_Config2__LineNumber__c))){
                    oliList.add(oOrderLineItem);
                }
            }
        }
        
        for (Apttus_Config2__OrderLineItem__c oliRec : oliList) {
                            
            if(orderIdToOrderLineItemsInstDeInstReqMap.containsKey(oliRec.Apttus_Config2__OrderId__c)){
                orderIdToOrderLineItemsInstDeInstReqMap.get(oliRec.Apttus_Config2__OrderId__c).add(oliRec);
            }else{
                orderIdToOrderLineItemsInstDeInstReqMap.put(oliRec.Apttus_Config2__OrderId__c, new List <Apttus_Config2__OrderLineItem__c>{oliRec});
            }
        }
        // orderIdToOrderLineItemsInstDeInstReqMap Map to hold Order ID and OrderLineItem List where installation/Deinstalltion is Required
        //V101.26 -->>        
        
        //Query orders with WOT
        if (!orderIdForInstallWorkOrderCreationSet.isEmpty()) {
            idToOrderForWorkOrderCreationMap = getOrder(orderIdForInstallWorkOrderCreationSet);
        } else if (!orderIdForDeInstallWorkOrderCreationSet.isEmpty()) {
            idToOrderForWorkOrderCreationMap = getOrder(orderIdForDeInstallWorkOrderCreationSet);
        }  else if (!orderIdForConversionWorkOrderCreationSet.isEmpty()) {
            idToOrderForWorkOrderCreationMap = getOrder(orderIdForConversionWorkOrderCreationSet);
        } else if (!orderIdForMovementWorkOrderCreationSet.isEmpty()) {
            idToOrderForWorkOrderCreationMap = getOrder(orderIdForMovementWorkOrderCreationSet);
        } else if (!orderIdForSwapWorkOrderCreationSet.isEmpty()) {
            idToOrderForWorkOrderCreationMap = getOrder(orderIdForSwapWorkOrderCreationSet);
        }

        Map<Id, List<Apttus_Config2__OrderLineItem__c>> bundleIdToOptionsMap = new Map<Id, List<Apttus_Config2__OrderLineItem__c>>();
        Map<Id, Apttus_Config2__OrderLineItem__c> idToOrderLineItemMap = new Map<Id, Apttus_Config2__OrderLineItem__c>();
        Map<Id, APTS_Order_LSP_Details__c> bundleIdToLSPDetailMap = new Map<Id, APTS_Order_LSP_Details__c>();
        
        for (Apttus_Config2__Order__c oOrder : orderIdToOrderMap.values()) {
            //V101.26 <<++ If check added ; also replaced orderIdToOrderLineItemsMap to orderIdToOrderLineItemsInstDeInstReqMap
            if(!orderIdToOrderLineItemsInstDeInstReqMap.isEmpty() && orderIdToOrderLineItemsInstDeInstReqMap!=NULL){  
                if (orderIdForWOTCreationSet.contains(oOrder.Id)) {

                    bundleIdToOptionsMap.putAll(APTS_WorkOrderUtils.prepareBundleIdToOptionsMap(orderIdToOrderLineItemsInstDeInstReqMap.get(oOrder.Id)));

                    for (Apttus_Config2__OrderLineItem__c oOrderLineItem : orderIdToOrderLineItemsInstDeInstReqMap.get(oOrder.Id)) {
                        idToOrderLineItemMap.put(oOrderLineItem.Id, oOrderLineItem);
                    }
                }
            }
        }

        if (!orderIdForWOTCreationSet.isEmpty() && !orderIdToOrderLineItemsInstDeInstReqMap.isEmpty() && orderIdToOrderLineItemsInstDeInstReqMap!=NULL) {
            bundleIdToLSPDetailMap = APTS_WorkOrderUtils.prepareBundleIdToLSPDetailMap(bundleIdToOptionsMap.keySet(), idToOrderLineItemMap);
        }//V101.26 -->>
        //SOQL Section

        //Main loop
        for (Apttus_Config2__Order__c oOrder : orderIdToOrderMap.values()) {

            //Create work order
            //V101.26 <<++ If check added ; also replaced orderIdToOrderLineItemsMap to orderIdToOrderLineItemsInstDeInstReqMap
            if (orderIdForWOTCreationSet.contains(oOrder.Id) ) {
                if(!orderIdToOrderLineItemsInstDeInstReqMap.isEmpty() && orderIdToOrderLineItemsInstDeInstReqMap!=NULL){
                    if (orderIdToOrderLineItemsInstDeInstReqMap.get(oOrder.Id) != null) {
                        List<WorkOrderTrigger__c> workOrderToCreateTmpList;
                        if (WTYPE_SWAP.equalsIgnoreCase(sWOTType)) {
                            workOrderToCreateTmpList = APTS_WorkOrderUtils.createWorkOrderSwap(sWOTType, oOrder, orderIdToOrderLineItemsInstDeInstReqMap.get(oOrder.Id), idToOrderForWorkOrderCreationMap.get(oOrder.Apttus_Config2__ParentOrderId__c), orderIdToOrderLineItemsInstDeInstReqMap.get(oOrder.Apttus_Config2__ParentOrderId__c), bundleIdToOptionsMap, bundleIdToLSPDetailMap);
                        } else {
                            workOrderToCreateTmpList = APTS_WorkOrderUtils.createWorkOrders(sWOTType, oOrder, orderIdToOrderLineItemsInstDeInstReqMap.get(oOrder.Id), bundleIdToOptionsMap, bundleIdToLSPDetailMap);
                        }

                        //If there are no LSP Details Work order is not created
                        if (!workOrderToCreateTmpList.isEmpty()) {

                            Apttus_Config2__Order__c oOrderToUpdate = idToOrderForWorkOrderCreationMap.get(oOrder.Id);
                            oOrderToUpdate.APTS_Work_Order_Created__c = true;
                            orderToUpdateList.add(oOrderToUpdate);
                            workOrderToCreateList.addAll(workOrderToCreateTmpList);
                        }
                    }
                }else{
                    Apttus_Config2__Order__c oOrderToUpdate = idToOrderForWorkOrderCreationMap.get(oOrder.Id);
                    oOrderToUpdate.APTS_Delivery_Block__c = null;
                    orderToUpdateList.add(oOrderToUpdate);
                }   
            }
            //V101.26 -->>

            //Set Sold to on physical asset when     sold to on order is changed
            if (orderIdWithSoldToChangeSet.contains(oOrder.Id) && orderIdToOrderLineItemsMap != null && orderIdToOrderLineItemsMap.containsKey(oOrder.Id)) {
                for (Apttus_Config2__OrderLineItem__c oOrderLineItem : orderIdToOrderLineItemsMap.get(oOrder.Id)) {

                    if (oOrderLineItem.APTS_Physical_Asset__c != null) {
                        PhysicalAsset__c oPhysicalAsset = new PhysicalAsset__c(Id = oOrderLineItem.APTS_Physical_Asset__c);
                        oPhysicalAsset.SoldTo__c = oOrder.Apttus_Config2__SoldToAccountId__c;
                        physicalAssetToUpdateList.add(oPhysicalAsset);
                    }
                }
            }

            //v101.1 ++ <<
            if (!orderWithRejectReasonUpdateSet.isEmpty() && orderIdToOrderLineItemsMap != null && orderIdToOrderLineItemsMap.containsKey(oOrder.Id)) {
                for (Apttus_Config2__OrderLineItem__c oOrderLineItem : orderIdToOrderLineItemsMap.get(oOrder.Id)) {
                    if (STATUS_PENDING_CANCEL.equalsIgnoreCase(oOrderLineItem.Apttus_Config2__Status__c)) {
                        //v101.17 ++ <<
                        if(oOrderLineItem.Apttus_Config2__OrderId__r.APTS_Order_Type__c == MACHINE_ORDER) {
                            if(oOrderLineItem.APTS_Is_Primary_L1_Line__c) {
                                oOrderLineItem.APTS_Reason_For_Rejection__c = oOrder.APTS_Reason_For_Rejection__c;
                            }
                        }
                        else {
                            oOrderLineItem.APTS_Reason_For_Rejection__c = oOrder.APTS_Reason_For_Rejection__c;
                        }
                        //v101.17 ++ >>
                        listOrderLineItemToUpdate.add(oOrderLineItem);
                    }
                }
            }
            //v101.1 ++ >>
            //v101.19 ++ <<
            
            //Submit order
            //V101.22 ++
            if (oOrder.APTS_SAP_OrderType__c!=CREDITDOC && oOrder.Approval_Status__c == 'Approved' && orderIdToOldOrderMap.get(oOrder.Id).Approval_Status__c != 'Approved' && oOrder.APTS_Lock_Order__c == false && orderIdToOldOrderMap.get(oOrder.Id).APTS_Lock_Order__c == true) {
                orderIdToSubmitList.add(oOrder.Id);
            }
            //v101.19 ++ >>

            //v101.34++<<
            if(oOrder.APTS_SAP_OrderType__c ==CREDITDOC && orderIdForOLISelectSet.contains(oOrder.Id)
                && orderIdToOrderLineItemsMap != null && orderIdToOrderLineItemsMap.containsKey(oOrder.Id)){
                for(Apttus_Config2__OrderLineItem__c oOrderLineItem : orderIdToOrderLineItemsMap.get(oOrder.Id)) {
                    oOrderLineItem.Apttus_Config2__Status__c=ACTIVATED;
                    oOrderLineItem.APTS_Status__c=ACTIVATED;
                    listOrderLineItemToUpdate.add(oOrderLineItem);
                }
            }
            //v101.34++>>            
        }
        //v101.40 ++ <<
        if(bUpdateATPResultOnWOLI)
        {
            updateATPResultsOnWOLI(orderIdToOrderMap);
        } //v101.40 ++ >>
        //Main loop

        //DML Section
        if (!physicalAssetToUpdateList.IsEmpty()) {
            if (objResultPhyAssets.isUpdateable()) {
                database.update(physicalAssetToUpdateList, false);
            }
        }
        
        APTS_OrderUtils.stopOrderLineItemTrigger();
        APTS_OrderUtils.stopOrderTrigger();
        if (!workOrderToCreateList.isEmpty()) {
            APTS_WorkOrderUtils.doDMLWorkOrderCreation(orderIdToOrderMap, workOrderToCreateList, sWOTType, objResultWorkOrder);
        }
        APTS_OrderUtils.startOrderTrigger();
        APTS_OrderUtils.startOrderLineItemTrigger();
        
        
        if (!orderToUpdateList.isEmpty()) {
            isTriggerDisabled = true;
            if (objResultOrder.isUpdateable()) {
                Database.update(orderToUpdateList);
            }
            isTriggerDisabled = false;
        }

        //v101.1 ++
        if (!listOrderLineItemToUpdate.isEmpty()) {
            APTS_OrderUtils.stopOrderLineItemTrigger();
            if (objResultOrderLI.isUpdateable()) {
                Database.update(listOrderLineItemToUpdate, FALSE);
            }
            APTS_OrderUtils.startOrderLineItemTrigger();
        }
        //v101.1 ++
        //v101.19 ++ <<
        
        //Submit order
        //v101.22 ++ <<
        if (!orderIdToSubmitList.isEmpty()) {
            System.enqueueJob(new APTS_SubmitOrderQueueable(orderIdToSubmitList));
        }
        //v101.22 ++ <<
        //v101.19 ++ >>
    }

    //@Description : Method to get executed beforeDelete
    public void beforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems) {

    }

    //@Description : Method to get executed afterDelete
    public void afterDelete(List<SObject> oldList, Map<Id, SObject> oldItems) {

    }

    //@Description : Method to get executed afterUndelete
    public void afterUndelete(List<SObject> newList, Map<Id, SObject> newItems) {

    }

    //@Description : Method to get the isDisabled on OrderTriggerHandler
    public static Boolean isDisabled() {
        return isTriggerDisabled;
    }

   
    //@Description : Method to get the maximum of OLI's Ready for Activation date per Order
    public Datetime getMaxOrderActivationDate(List<Apttus_Config2__OrderLineItem__c> orderLineItemList, String sRequestType) {

        Datetime dtMaxDate = null;
        List<Datetime> instalationDateList = new List<Datetime>();
        List<Date> deInstalationDateList = new List<Date>();
        //try {
        for (Apttus_Config2__OrderLineItem__c oOrderLineItem : orderLineItemList) {
            if (oOrderLineItem.APTS_Is_Primary_L1_Line__c == true && oOrderLineItem.Apttus_Config2__HasOptions__c) {
                if (oOrderLineItem.APTS_Installation_Date__c != null) {
                    instalationDateList.add(oOrderLineItem.APTS_Installation_Date__c);
                }
                if (oOrderLineItem.APTS_De_installation_Date__c != null) {
                    deInstalationDateList.add(oOrderLineItem.APTS_De_installation_Date__c);
                }
            }
        }

        instalationDateList.sort();
        deInstalationDateList.sort();

        if (!instalationDateList.isEmpty() && sRequestType.equals(INSTALLATION)) {
            dtMaxDate = instalationDateList.get(instalationDateList.size() - 1);
        }

        if (!deInstalationDateList.isEmpty() && sRequestType.equals(DE_INSTALLATION)) {
            Date dtMacDateTmp = deInstalationDateList.get(deInstalationDateList.size() - 1);
            dtMaxDate = Datetime.newInstance(dtMacDateTmp.year(), dtMacDateTmp.month(), dtMacDateTmp.day());
        }
        //} catch (Exception e)             {
        //    APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id), 'OM', false, true, EMAIL, true);
        //}

        return dtMaxDate;
    }

    //@Description : Method to get the isDisabled on OrderTriggerHandler
    public static void setTriggerDisabled(Boolean isDisabled) {

        isTriggerDisabled = isDisabled;
    }

    public Map<Id, Apttus_Config2__Order__c> getOrder(Set<Id> orderIdSet) {

        Map<Id, Apttus_Config2__Order__c> idToOrderMap = new Map<Id, Apttus_Config2__Order__c>([
                    SELECT Id, APTS_Work_Order_Created__c, Apttus_CMConfig__AgreementId__r.Apttus__Version_Number__c,
                    APTS_Require_Installation__c, APTS_Order_Sub_Type__c, APTS_Requested_Installation_Date__c,
                    APTS_Sales_Organization__c, APTS_Subject__c, APTS_LSP_Description__c,
                    APTS_ProjectNumber__c, APTS_IsProject__c, APTS_ScheduleExceptions__c, Apttus_Config2__PONumber__c,
                    APTS_Requested_De_Installation_Date__c, Apttus_Config2__ParentOrderId__c, Apttus_Config2__LocationId__c,APTS_Delivery_Block__c,
                    Apttus_Config2__LocationId__r.Delivery_text__c,Apttus_Config2__LocationId__r.Picking_list_text__c, Apttus_Config2__LocationId__r.Billing_header_text__c, Apttus_Config2__PrimaryContactId__c, APTS_ServiceContact__c
                    FROM Apttus_Config2__Order__c
                    WHERE Id IN :orderIdSet]);

        return  idToOrderMap;
    }

    //@Description : Method to get the getOrderLineItems on OrderTriggerHandler
    public static Map<Id, List<Apttus_Config2__OrderLineItem__c>> getOrderLineItems(Set<Id> orderIdSet) {


        Map<Id, List<Apttus_Config2__OrderLineItem__c>> orderIdToOrderLineItemsMap = new Map<Id, List<Apttus_Config2__OrderLineItem__c>>();

        //v101.1 ++ <<
        List<Apttus_Config2__OrderLineItem__c> orderLineItemList = [SELECT Id,
                                               Apttus_Config2__OrderId__c,
                                               APTS_Item_Relevant_for_SAP__c,
                                               APTS_Is_Primary_L1_Line__c,
                                               Apttus_Config2__IsPrimaryLine__c,
                                               Apttus_Config2__LineNumber__c,
                                               Apttus_Config2__OptionId__c,
                                               Apttus_Config2__LineType__c,
                                               Apttus_Config2__ProductId__c,
                                               APTS_Order_LSP_Detail__c,
                                               Apttus_Config2__LocationId__c,
                                               APTS_Physical_Asset__c,
                                               APTS_Physical_Asset__r.AccountLocation__c,
                                               APTS_Physical_Asset__r.Building__c,
                                               APTS_Physical_Asset__r.Area__c,
                                               APTS_Physical_Asset__r.Floor__c,
                                               APTS_Physical_Asset__r.OwnedByCustomer__c,
                                               APTS_Physical_Asset__r.StairClimber__c,
                                               APTS_Physical_Asset__r.CustomerReferenceNumber__c,
                                               APTS_Physical_Asset__r.SmokingArea__c,
                                               APTS_Physical_Asset__r.JDECrockeryVolumeSize__c,
                                               APTS_Physical_Asset__r.RequiresLSP__c,
                                               APTS_Physical_Asset__r.CommercialUsage__c,
                                               APTS_Physical_Asset__r.AccountLocation__r.Main_Service_Contact__c,
                                               APTS_Physical_Asset__r.ConfigurationManualAgreementsURL__c,   
                                               APTS_Status__c,
                                               Apttus_CMConfig__AgreementId__c,
                                               APTS_Material_Availability_Date__c,
                                               Apttus_Config2__ActivatedDate__c,
                                               Apttus_Config2__ReadyForBillingDate__c,
                                               Apttus_Config2__Status__c,
                                               APTS_Installation_Date__c,
                                               APTS_De_installation_Date__c,
                                               APTS_Installation_Required__c,
                                               APTS_De_Installation_Required__c,
                                               Apttus_Config2__HasOptions__c,
                                               Apttus_Config2__AutoRenew__c,
                                               Apttus_Config2__LineStatus__c,
                                               Apttus_Config2__ProductId__r.Apttus_Config2__ConfigurationType__c,
                                               Apttus_Config2__PriceType__c,
                                               Apttus_Config2__Frequency__c,
                                               Apttus_Config2__BillingFrequency__c,
                                               Apttus_Config2__Term__c,
                                               APTS_Requested_Installation_Date__c,
                                               APTS_Requested_Delivery_Date__c,
                                               APTS_PlugPlay__c,
                                               APTS_Option_Group_Text__c,
                                               Apttus_Config2__Description__c,
                                               APTS_SAP_OrderType__c,
                                               Apttus_Config2__OrderId__r.APTS_Order_Type__c, 
                                               APTS_ATP_Check_Status__c , 
                                               APTS_Reason_For_Rejection__c,
                                               APTS_Plant_Code__c
                                               FROM Apttus_Config2__OrderLineItem__c
                                               WHERE Apttus_Config2__OrderId__c IN :orderIdSet LIMIT 50000];
        //v101.1 ++ >>

        for (Apttus_Config2__OrderLineItem__c oOrderLineItem : orderLineItemList) {

            List<Apttus_Config2__OrderLineItem__c> tmpOrderLineItemList =
                orderIdToOrderLineItemsMap.get(oOrderLineItem.Apttus_Config2__OrderId__c);
            if (tmpOrderLineItemList == null) {
                tmpOrderLineItemList = new List<Apttus_Config2__OrderLineItem__c>();
                orderIdToOrderLineItemsMap.put(oOrderLineItem.Apttus_Config2__OrderId__c, tmpOrderLineItemList);
            }
            tmpOrderLineItemList.add(oOrderLineItem);
        }

        return orderIdToOrderLineItemsMap;
    }

    public Map<Id, Apttus__APTS_Agreement__c> getAgreements(Set<Id> agreementIdSet) {

        Map<Id, Apttus__APTS_Agreement__c> agreementMap = new Map<Id, Apttus__APTS_Agreement__c>([
                    SELECT Id,
                    Name,
                    APTS_Fixed_Term_Type__c,
                    APTS_Bill_to_Party_Ingredients__c,
                    APTS_Bill_to_Party_MachServ__c,
                    APTS_Payer_Ingredients__c,
                    APTS_Payer_Machines_Services__c,
                    APTS_Check_on_Account_Machines__c,
                    APTS_Check_on_Account_Ingredients__c,
                    APTS_Agreement_Duration_Months__c,
                    Apttus__Contract_End_Date__c,
                    Apttus__Subtype__c
                    FROM Apttus__APTS_Agreement__c
                    WHERE Id IN :agreementIdSet ]);

        return agreementMap;
    }
  
    public Map<Id, Account> getAccounts(Set<Id> accountIdSet) {

        Map<Id, Account> accountMap = new Map<Id, Account>([
                    SELECT Id,
                    Bill_To_Payer_Account__c,
                    Related_Bill_to_Machines_Services__c,
                    Related_Payer_Account__c,
                    Related_Payer_Machines_Services__c,
                    Billing_header_text__c,
                    EDI_Reference_Number__c
                    FROM Account
                    WHERE Id IN :accountIdSet]);
        return accountMap; 
    }

    public static Map<Id, Apttus_Config2__AccountLocation__c> getAccountLocation(Set<Id> acctLocIdSet) {

        Map<Id, Apttus_Config2__AccountLocation__c> acctLocMap = new Map<Id, Apttus_Config2__AccountLocation__c>([
                    SELECT Id,
                    Delivery_text__c,
                    Picking_list_text__c,
                    Billing_header_text__c
                    FROM Apttus_Config2__AccountLocation__c
                    WHERE Id IN :acctLocIdSet]);

        return acctLocMap;
    }
    //V101.33 ++ <<
    public Apttus_Config2__Order__c defaultFieldValues(Apttus_Config2__Order__c oOrder)
    {
        //v101.1 ++ <<
                 //add comments to avoid validation rule
                 if (Test.isRunningTest()) { 
                     oOrder.APTS_Customer_Comments__c  = 'TestRunning';
                 }
                 
                 //if order is amend or cancel or clone, we need to remove SAP Header ID
                 oOrder.APTS_Order_Header_SAP_ID__c = NULL;
                 //v101.3 ++ <<
                 oOrder.APTS_Credit_Limit_Alert__c = NULL;
                 oOrder.APTS_ATP_Check_Status__c = NULL;
                 oOrder.APTS_LSP_Delivery_Date__c = NULL;
                 oOrder.APTS_GoodsIssue_Status__c = NULL;
                 oOrder.APTS_Delivery_Date_Authorized__c = NULL;
                 oOrder.APTS_Picking_Status__c = NULL;
                 oOrder.APTS_POD_Status__c = NULL;
                 //oOrder.APTS_Delivery_Block__c = NULL;
                 oOrder.APTS_LSP_Movement_Date__c = NULL;
                 oOrder.APTS_LSP_Pick_Up_Date__c = NULL;
                 oOrder.APTS_Movement_Date_Authorized__c = NULL;
                 oOrder.APTS_Pick_Up_Date_Authorized__c = NULL;
                 oOrder.Apttus_Config2__OrderDate__c = NULL;
                 oOrder.APTS_Confirmed_Installation_Date__c = NULL;
                 //oOrder.APTS_Requested_De_Installation_Date__c = NULL;
                 oOrder.APTS_Confirmed_De_Installation_Date__c = NULL;
                 //v101.30 << ++
                 if(oOrder.APTS_SAP_OrderType__c != APTS_OrderConstants.XA14) {
                     oOrder.APTS_Requested_Movement_Date__c = NULL;
                 }
                 //v101.30 ++ >>
                 oOrder.APTS_Confirmed_Movement_Date__c = NULL;
                 oOrder.APTS_Rental_Start_Date__c = NULL;
                 oOrder.APTS_Rental_End_Date__c = NULL;
                 oOrder.APTS_Detailed_Delivery_Date__c = NULL;
                 oOrder.Approval_Status__c = 'Not Submitted';  //v101.29
                 // v101.11 ++ << changes by balashanthi for Defect # 21401 starts
                 if (!(APTS_BIRUtils.ADMINORDERSAPORDERTYPE.equalsIgnoreCase(oOrder.APTS_SAP_OrderType__c)
                       || APTS_BIRUtils.CONSUMPTIONSAPORDERTYPE.equalsIgnoreCase(oOrder.APTS_SAP_OrderType__c))
                     && ! APTS_BIRUtils.ADMINORDER.equalsIgnoreCase(oOrder.APTS_Order_Type__c)) {
                         oOrder.APTS_Billing_Date__c = NULL;
                     }
                 //v101.11 ++ << changes by balashanthi for Defect # 21401 Ends
                 oOrder.APTS_ScheduleDate__c = NULL;
                 oOrder.APTS_Work_Order_Created__c = False;
                 //101.16 ++ <<
                 if (!(APTS_OrderConstants.ORDER_TYPE_ROUTESALES.equalsIgnoreCase(oOrder.APTS_Order_Type__c) || APTS_OrderConstants.ORDER_TYPE_OPERATING.equalsIgnoreCase(oOrder.APTS_Order_Type__c) || APTS_OrderConstants.ORDER_TYPE_DIGITAL.equalsIgnoreCase(oOrder.APTS_Order_Sub_Type__c))) {
                     oOrder.APTS_Case__c = NULL;
                     oOrder.Apttus_Config2__OrderStartDate__c = System.today();
                     oOrder.Apttus_Config2__OrderEndDate__c = System.today();
                 }
                 //101.16 ++ <<
                 
                 
                 //v101.3 ++ >>
                 
                 
                 //v101.1 ++ >>
                 
                 //v101.24 ++ <<
                 //Added as part of defect#6952, to stop the copying of the Approval Status from the Amended Order
                 if(oOrder.Apttus_Config2__PreviousVersion__c != null && oOrder.Apttus_Config2__Status__c == 'In Amendment' &&  oOrder.Apttus_Config2__Status__c != 'Pending') {
                     oOrder.Approval_Status__c = 'Not Submitted';
                 }
                 return oOrder;
    }
    //V101.33 ++ >>
    //v101.40 ++ <<
    public void updateATPResultsOnWOLI(Map<Id, Apttus_Config2__Order__c> orderIdToOrderMap)
    {
        Map<Id, string> mapCaseIdToATPStatus = new Map<Id, string>();
        try
        {
            if(!orderIdToOrderMap.isEmpty())
            {
                for(Apttus_Config2__Order__c oOrder : orderIdToOrderMap.values())
                {
                    if(oOrder.APTS_Case__c != null || Test.isRunningTest())
                    {
                        mapCaseIdToATPStatus.put(oOrder.APTS_Case__c, oOrder.APTS_ATP_Check_Status__c);
                    }
                }
                if(!mapCaseIdToATPStatus.isEmpty())
                {
                    Map<Id, WorkOrderLineItem> mapWOLIToUpdate = new Map<Id, WorkOrderLineItem>([Select id, ATP_Check_Status__c, Case__c from WorkOrderLineItem where Case__c IN: mapCaseIdToATPStatus.keyset()]);
                    for(WorkOrderLineItem objWOLI : mapWOLIToUpdate.values())
                    {
                        objWOLI.ATP_Check_Status__c = (mapCaseIdToATPStatus.get(objWOLI.Case__c) == 'Pass')? true: false;
                    }
                    if(!mapWOLIToUpdate.isEmpty())
                    {
                        Database.update(mapWOLIToUpdate.values(), false);
                    }
                }
            }
        }
        catch(Exception ex)
        {
            APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString() , 'Order', null, 'OM', false, true, null, true);  
        }
        //v101.40 ++ >>
    }
}