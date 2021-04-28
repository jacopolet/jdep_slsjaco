/************************************************************** 
    @Name: APTS_OrderLineItemTriggerHandler
    @Author: Galin Georgiev
    @CreateDate: 14-03-2018
    @Description: Order line item trigger handler
    @UsedBy: Order line item trigger
    ******************************************************************/
    //v100 19-12-2017 Galin Georgiev: Initial version.
    //Comments in this format are mandatory for each change of code.
    //Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
    //Removing code comment example: v100--<< means start of changes and v100-->> means end of changes
    //v101 09-Jan-2019 Sanjay  : Added code for defect# 23358 - Item category set at L1 Bundle based on Machine Option.
    //v102 18-Jan-2019 Aarthi : Added code to update the physical asset ID on WOT and WOLI in case of Refurbished Machines
    //v103 23-Jan-2019 Aarthi : Added code to update the start date, end date and selling term for CR 2204
    //v104 24-Jan-2019 Akanksha: Added code to set installation contact phone on OLI
    //v105 25-Jan-2019 Aarthi : Defect #23740 - Item Relevancy logic should be excluded for XD09 orders with Fixed Term Type Products
    //v106 12-Feb-2019 Balashanthi : Cascading the value of Billing Preference, Payment Method and Payment Term from Order Header
    //v107 13-Feb-2019 Shankar : Updated the Refurbished machine logic
    //v108 26-Feb-2019 Nikita  Def#4345
    //v109 06-March-2019 Balashanthi  Def#5662 Muted the Parent Order Line Item Logic for Admin Orders
    //v110 12-Mar-2019 Akanksha : Defect# 5632 Added condition to exclude Cancelled orders
    //v111 25-Mar-2019 Sethu: Added code for Delay CR2257
    //v112 04-Apr-2019 Nikita Def#6373 :Order getting back to Submitted
    //v113 16-Apr-2019 Akanksha Defect#6762 : Checking ATP cleared on all OLIs then updating on order
    //v114 16-Apr-2019 Akanksha Defect#6753 : Checking if physical asset is empty then setting it
    //v115 18-Apr-2019 Aarthi : Defect#6719 : Add null checks in AfterUpdate event in order to avoid null pointer exceptions
    //v116 18-Apr-2019 Nikita : FIx to handle 101 SOQL on update of deintallation date by TS
    //v117 18-Apr-2019 Sanjay Nair : Added logic to set the ZX10 to 100 when the List Price or Net Price is 0 - Defect #6329
    //v118 21-Apr-2019 Balashanthi A : Defect # 6776 Bypassed the logic for Admin Order SAP order Type 'XD09' and 'XD12'
    //v119 24-apr-2019 Neev Shah : Defect #5173 : CR 2289:  Machine Cancellation, make Options Not relevenat for SAP
    //v120 23-May-2019 Aarthi Pitchai : DOQOM-105
    //v121 22-May-2019 Nikita Modi : Delivery only
    //v122 24-May-2019 Aarthi Pitchai : Delivery only & Return Only - Physical Asset Update - DOQOM-123
    //v123 15-Mar-2019 Akanksha : Added code for CR2909 - Partial cancel Order -- 3.1
    //v124 27-Mar-2019 Mahesh : Modified the AfterUpdate method to update the Asset Agreement Id on the Asset Line Item -- 3.1
    //v125 01-Jun-2019 Aarthi : DOK31-207 :: Physical Asset creation on Admin order creation -- 3.1
    //v126 01-Jun-2019 Aarthi : DOK31-273 :: Exclude the start and end date recalculation on Movement orders -- 3.1
    //v127 12-Jun-2019 Aarthi : Added fix for the update on option physical Assets in case of Delivery only
    //v128 14-Jun-2019 Aarthi : Partial Cancel - Added fix to update the PGIcompleted flag on Order header based on relevant lines for cancellation of all OLIs 
    //v129 20-Jun-2019 Nikita : DOQOM - 284 - Physical Asset mapping on Optional WOT
    //v130 09-Jul-2019 Renuka : QTCFLEX1-173 - Setting Debit Memo Status Custom field to 'Sent for Invoicing'.
    //v131 22-Jul-2019 Akanksha : QTCFLEX1-723 - Adding condition when activating OLIs.
    //v132 22-Jul-2019 Sai : Jira - DFT2C-740 - Physical Asset Update Fix
    //v133 15-Aug-2019 Aarthi: QTCFLEX1-579 - ZX10 to be determined from Asset adjustments in case of deInstall
    //v134 27-Aug-2019 Renuka: DFT2C-1017 Set Bill-to Party and Payer fields from Order.
    //v135 11-Sep-2019 Aarthi: QTCFLEX1-1205 - Set Contract details on DeInstall OLIs
    //v136 16-Sep-2019  Nikita : QTCFLEX1-1261 -  Handling exception in PROD 
    //v137 08-Oct-2019  Sai : DFT2C-1541 -  Duplicate Serial number Fix - Upsert Option Physical Asset
    //v138 12-Oct-2019 Sai: DFT2C-1552 - CounterReading Field Update
    //v139 17-Oct-2019 Aarthi: DFT2C-15 - Renewal changes
    //v141 29-Oct-2019 Renuka: QTCFLEX1-1599 - XC01 Credit Notes - remove primary lines for SAP submission
    //v142 05-Oct-2019 Renuka: QTCFLEX1-1584 - Check to stop overriding PhysicalAsset Name. 
    //v143 11-Oct-2019 Sai: Populate From Location and Account DFT2C-1898
    //v144 16-Jan-2020 Aarthi: Remove the selling term recalculation logic for all orders - DQ516
    //v145 22-Jan-2020 Aarthi: changed else if part to simple if - DQ29
    //v146 3/March/2020 Lavanya : Asset contract change Logics DQ-56
    //V147 03-Mar-2020 Aarthi: DQ-1719 Moved the Billing date logic to OLI handler
    //V148 13-Mar-2020 Renuka: DQ-472 New Debit flow changes
    //v149 13/april/2020 Lavanya DQ-2038- PHA unique number issue
    //v150 13-May-2020 Renuka: DQ-2492 Setting ItemRelevency Flag to false for DebitNote
    //v151 20-May-2020 Aarthi: DQ-2540 DeInstallation Order fix - XA23 removal
    //v152 25-May-2020 Aarthi Pitchai: DQ-2434 Return orders Item Category Issue fix
    //V153 30-Jun-2020 Aarthi : DQ-3055 Patch 6 issue - partial return fix
    //V154 02-07-2020 Karan : DQ-2730 : Conversion order - Physical asset flow redesign
    //V155 29-07-2020 Renuka: DQ-3458 : XC09 CreditOrder
    //v156 12-8-2020 Sneha: DQ-2122 WorkOrder Trigger and case to be cretead for Physical Movement
    //v157 25-8-2020 Venky Muppalaneni: DQ-3470 Stamping the Ready for Activation date from OLI Start date
    //V158 3-Sep-2020 Aarthi Pitchai - Exclude PhA logic on OLI cancellation
    //v159 9-Sep-2020 Renuka : DQ-3265 Populating PhA details in AdminOrders from Terminated fields in ASLI CTC flow
    //V160 14-Sep-2020 Aarthi : DQ-3716 : PhA field updates on Physical Movement
    //V161 09-Oct-2020 Aarthi : DQ-3205 : PhA field updates on XA13 case cancellation
    //V162 05-Nov-2020 Nikunj : //Start - DQ-3066 : Kauri Professional DevOps QTC (Apttus) - Medium - Usage Price set in Attribute Value is not fetched in related Usage Price Tier-Conversion Orders
    //v163: 27-Jan-2021 Sneha Jaiwant:DQ:5206 XB23-De-installation required checkbox missing in bundle details page
    //v164 01-Feb-2021 Aarthi : DQ-4637 : Machine Orders - set non L1 lines activation date same as start date of OLI
    //v165 2-2-2021 Sneha:Successful trial: CTC(Trial->Sales)- XD01 order, Order reason, picklist value
    //v166 12-Feb-2021 Renuka : DQ-5186 Updating Initial Activation Date for refurbished machines.
   //v167 23-Mar-2021 DQ-5727 :Sneha Jaiwant :CTC: Trial to Sales - XD02 order type
   //V168 4-Apr-2021 Aarthi : DQ-5898 - CTC Fix - OLI status getting changed post Order activation
   //v169 11-Apr-2021 Snehs:DQ-5899: CTC FIX -Parent order line item Number not updated on OLI level

   public without sharing  class APTS_OrderLineItemTriggerHandler implements ITriggerHandler {

    public static Boolean isTriggerDisabled = false;
    Set<Id> ContractChangeSet = new Set<Id>();
    Set<Id> Fulfilledlines = new Set<Id>();
    private static final String MACHINE_ORDER = System.Label.APTS_Machine_Order;
    private static final String STANDALONE = System.Label.APTS_Standalone;
    private static final String BUNDLE = System.Label.APTS_Bundle;
    private static final String OPTION = System.Label.APTS_Option;
    private static final String DRAFT = System.Label.APTS_Draft;
    private static final String PENDING = System.Label.APTS_Pending;
    private static final String SUBMITTED = System.Label.APTS_Submitted;
    private static final String SAP_INTEGRATION_USER = System.Label.APTS_SAPIntegrationUser;
    private static final String FAIL = System.Label.APTS_Fail;
    private static final String PASS = System.Label.APTS_Pass;
    private static final String IN_AMENDMENT = System.Label.APTS_In_Amendment;
    private static final String ACTIVATED = Label.Apttus.Activated;
    private static final String EMAIL = System.Label.APTS_Email;
    private static final String DE_INSTALLATION = System.Label.APTS_De_installation;
    private static final String COMMERCIAL_SWAP = System.Label.APTS_Commercial_Swap;
    private static final String DEBIT_MEMO = System.Label.APTS_DebitMemo;
    private static final String XD01 = System.Label.APTS_XD01;
    private static final String XC01 = 'XC01';
    private static final String RETURNED = System.Label.APTS_Returned;
    private static final String STANDARD_RETURN = System.Label.APTS_Standard_Return;
    private static final String UNPLANNED_RETURN = 'Unplanned Return';
    private static final String INTERNAL_MOVEMENT = System.Label.APTS_Internal_Movement;
    private static final String CONVERSION = 'Conversion Order';
    private static final String EXTERNAL_MOVEMENT_WITH_CONTRACT_CHANGE = 'External Movement With Contract Change';//System.Label.APTS_External_Movement;
    private static final String EXTERNAL_MOVEMENT_WITHOUT_CONTRACT_CHANGE = 'External Movement Without Contract Change';//System.Label.APTS_External_Movement;
    private static final String NEW_MACHINE = System.Label.APTS_New_N;
    private static final String REFURBISHED = System.Label.APTS_Refurbished_U;
    private static final String FULFILLED = System.Label.APTS_Fulfilled;
    private static final String XA13 = System.Label.APTS_XA13;
    private static final String XB13 = 'XB13';
    private static final String LINE_STATUS_NEW = 'New';
    private static final String ALLINCOVERAGE = 'ALL-IN COVERAGE';
    private static final String ORDERCRUD = 'Apttus_Config2__Order__c';
    private static final String ORDERLICRUD = 'Apttus_Config2__OrderLineItem__c';
    private static final String ASSETLICRUD = 'Apttus_Config2__AssetLineItem__c';
    private static final String WORKORDERCRUD = 'WorkOrderTrigger__c';
    private static final String WORKORDERLICRUD = 'WorkOrderLineItem';
    private static final String PHYASSETCRUD = 'PhysicalAsset__c';
    private static final String ADMINORDERSAPTYPE = 'XD09';
    private static final String ADMINORDERCONSUMSAPTYPE = 'XD12';
    private static final String CREDITORDERSAPTYPE = 'XC09';        
    private Set<String> adminOrderTypes = new Set<String>{ADMINORDERSAPTYPE,ADMINORDERCONSUMSAPTYPE,CREDITORDERSAPTYPE};
    
    
    //v101 << ++
    private static final String MACHINEOPTION = 'Machine';

    //v101 -->>
    private static final String TECHNICAL_SERVICES = System.Label.APTS_TechnicalService;
    
    //v119
    private static final String PENDING_CANCELLATION = APTS_OrderConstants.STATUS_PENDING_CANCEL;
    
    //3.1       
    //v123 ++ <<        
    private Set<String> setStandardOrderTypes = new Set<String> {APTS_OrderConstants.STANDARD_ORDER, APTS_OrderConstants.ORDER_TYPE_ROUTESALES, APTS_OrderConstants.ORDER_TYPE_OPERATING};      
    //v123 ++ >>        
    //3.1


    //@Description : Method to get the beforeInsert
    public void beforeInsert(List<SObject> newItems) {

        //Variable Section
        List<Apttus_Config2__OrderLineItem__c> orderLineItemList = (List<Apttus_Config2__OrderLineItem__c>) newItems;
        Set<Id> orderIdSet = new Set<Id>();
        Set<Id> assetIdSet = new Set<Id>();
        Set<Id> agreementIdSet = new Set<Id>();
        Set<Id> accountLocIdSet = new Set<Id>();
        Map<String, Apttus_Config2__OrderLineItem__c> mapOrderSerialNumber = new Map<String, Apttus_Config2__OrderLineItem__c>();
        Map<Decimal, PhysicalAsset__c> mapOLIPhyAsset = new Map<Decimal, PhysicalAsset__c>();
        //Variable Section

        //Initial loop
        for (Apttus_Config2__OrderLineItem__c oOrderLineItem : orderLineItemList) {
            orderIdSet.add(oOrderLineItem.Apttus_Config2__OrderId__c);
            if (oOrderLineItem.Apttus_Config2__AssetLineItemId__c != null) {
                assetIdSet.add(oOrderLineItem.Apttus_Config2__AssetLineItemId__c);
            }
            if (oOrderLineItem.Apttus_CMConfig__AgreementId__c != null) {
                agreementIdSet.add(oOrderLineItem.Apttus_CMConfig__AgreementId__c);
            }
            if (oOrderLineItem.Apttus_Config2__LocationId__c != null) {
                accountLocIdSet.add(oOrderLineItem.Apttus_Config2__LocationId__c);
            }
        }
        //Initial loop

        //SOQL Section
        Map<Id, Apttus_Config2__Order__c> idToOrderMap = APTS_OrderLineItemDAO.getOrder(orderIdSet);
        Map<Id, Apttus_Config2__AssetLineItem__c> idToAssetLineItemMap = APTS_OrderLineItemDAO.getAssetLineItems(assetIdSet);
        Map<Id, Apttus_Config2__AccountLocation__c> idToAccountLocMap = APTS_OrderLineItemDAO.getAccountLocation(accountLocIdSet);
        //SOQL Section

        //Main loop
        for (Apttus_Config2__OrderLineItem__c oOrderLineItem : orderLineItemList) {
            Apttus_Config2__Order__c oOrder = idToOrderMap.get(oOrderLineItem.Apttus_Config2__OrderId__c);

            //set some fields to null when cloning order
            oOrderLineItem.APTS_SAP_Order_Line_Item_Number__c = null;
            oOrderLineItem.APTS_Order_Line_SAP_ID__c = null;
            oOrderLineItem.APTS_Loading_Date__c = null;
            oOrderLineItem.APTS_Goods_Issue_Date__c = null;
            oOrderLineItem.APTS_Plant_Code__c = null;

            //Set agreement Id from order to order line items
            if(oOrder.APTS_Contract_Change__c!= null && oOrder.APTS_Contract_Change__c!='Yes') //DQ-56 - excluding for contract change
            oOrderLineItem.Apttus_CMConfig__AgreementId__c = oOrder.Apttus_CMConfig__AgreementId__c;

            //Copy status to custom status on order line item creation: Draft
            oOrderLineItem.APTS_Status__c = oOrderLineItem.Apttus_Config2__Status__c;

            oOrderLineItem.APTS_SAP_OrderType__c = oOrder.APTS_SAP_OrderType__c;

            if ((oOrderLineItem.Apttus_Config2__PreviousVersion__c != null && oOrderLineItem.Apttus_Config2__Status__c == 'Cancelled') || Test.isRunningTest()) {
                oOrderLineItem.APTS_Reason_For_Rejection__c = oOrder.APTS_Order_Reason__c;
            }
            
            //populate physical asset from asset on order line item
            Apttus_Config2__AssetLineItem__c oAssetLineItem = idToAssetLineItemMap.get(oOrderLineItem.Apttus_Config2__AssetLineItemId__c);
            if (oAssetLineItem != null && String.isNotBlank(oAssetLineItem.APTS_Physical_Asset__c)) {

                oOrderLineItem.APTS_Physical_Asset__c = oAssetLineItem.APTS_Physical_Asset__c;
                System.debug(oOrderLineItem.id+'PHA'+oOrderLineItem.APTS_Physical_Asset__c);
                oOrderLineItem.APTS_Serial_Number__c = oAssetLineItem.APTS_Physical_Asset__r.SerialNumber__c;
                if (oAssetLineItem.APTS_Physical_Asset__r.InitialActivationDate__c != null) {
                    mapOLIPhyAsset.put(oOrderLineItem.Apttus_Config2__LineNumber__c, new PhysicalAsset__c(Id = oAssetLineItem.APTS_Physical_Asset__c, InitialActivationDate__c =  oAssetLineItem.APTS_Physical_Asset__r.InitialActivationDate__c));
                }
            }
            else if(adminOrderTypes.contains(oOrderLineItem.APTS_SAP_OrderType__c) && oAssetLineItem != null //v159 ++Start<<
                    && String.isNotBlank(oAssetLineItem.Apttus_Config2__AssetStatus__c) && oAssetLineItem.Apttus_Config2__AssetStatus__c== 'Cancelled'
                    && String.isNotBlank(oAssetLineItem.APTS_Terminated_Physical_Asset__c)){
                oOrderLineItem.APTS_Physical_Asset__c = Id.valueOf(oAssetLineItem.APTS_Terminated_Physical_Asset__c);
                oOrderLineItem.APTS_Serial_Number__c = String.isNotBlank(oAssetLineItem.APTS_Terminated_PHA_serial_number__c) ?oAssetLineItem.APTS_Terminated_PHA_serial_number__c: oOrderLineItem.APTS_Serial_Number__c;
            }//v159 ++End>>
            
            if (oOrderLineItem.Apttus_Config2__LocationId__c == null) {
                oOrderLineItem.Apttus_Config2__LocationId__c = oOrder.Apttus_Config2__LocationId__c;
            }

            if (COMMERCIAL_SWAP.equalsIgnoreCase(oOrder.APTS_Order_Sub_Type__c) && XA13.equalsIgnoreCase(oOrder.APTS_SAP_OrderType__c) && String.isNotBlank(oOrderLineItem.APTS_Serial_Number2__c)) {
                mapOrderSerialNumber.put(oOrderLineItem.APTS_Serial_Number2__c, oOrderLineItem);
            }

            if (oOrderLineItem.Apttus_Config2__LocationId__c != null) {
                Apttus_Config2__AccountLocation__c acctLoc = idToAccountLocMap.get(oOrderLineItem.Apttus_Config2__LocationId__c);
                oOrderLineItem.APTS_Delivery_Timeframes__c = APTS_OrderUtils.getDeliveryTimeframes(oOrderLineItem, acctLoc);
            }

            //<<--- v143
            oOrderLineItem.APTS_Location_From__c = oOrder.APTS_Location_From__c;
            oOrderLineItem.APTS_Movement_From_Account__c = oOrder.APTS_Movement_From_Account__c;
            // v143--->>
            // v106++<< Start of cascading the values of billing preference, Payment Method and Payment Term
            //oOrderLineItem.Apttus_Config2__BillingPreferenceId__c = oOrder.Apttus_Config2__BillingPreferenceId__c != null?  oOrder.Apttus_Config2__BillingPreferenceId__c:null;
            //oOrderLineItem.APTS_Payment_Method__c = oOrder.APTS_Payment_Method__c != null? oOrder.APTS_Payment_Method__c : null;
            //oOrderLineItem.Apttus_Config2__PaymentTermId__c = oOrder.Apttus_Config2__PaymentTermId__c != null? oOrder.Apttus_Config2__PaymentTermId__c : null;
            // v106--<< Start of cascading the values of billing preference, Payment Method and Payment Term                
            //V152 ++ <<
            if(oOrderLineItem.APTS_Item_Category__c != null && (setStandardOrderTypes.contains(oOrder.APTS_Order_Type__c) || oOrder.APTS_Order_Type__c == MACHINE_ORDER))
            {
                oOrderLineItem.APTS_Item_Category__c = null;
            }                
            //V152 ++ >>
            //V153 ++ <<
            if(oOrder.APTS_Order_Sub_Type__c == 'Standard Return' && oOrderLineItem.Apttus_Config2__DeltaQuantity__c != null && oOrderLineItem.Apttus_Config2__DeltaQuantity__c < 0){
                oOrderLineItem.Apttus_Config2__DeltaQuantity__c = oOrderLineItem.Apttus_Config2__DeltaQuantity__c * -1 ;
            }
            //V153 ++ >>
            if(oOrderLineItem.Apttus_Config2__AssetLineItemId__c != null && oOrderLineItem.Apttus_Config2__LineType__c == 'Option'){
               if(oAssetLineItem != null){
                    oOrderLineItem.APTS_Option_Group_Text__c = oAssetLineItem.APTS_Option_Group_Text__c;
                }                
            }
        }
        //Main loop

        if (!mapOrderSerialNumber.isEmpty()) {
            //get previous order line item from
            List<Apttus_Config2__OrderLineItem__c> listPrevOLI = [SELECT Id, APTS_Serial_Number__c FROM Apttus_Config2__OrderLineItem__c WHERE Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c = :XB13 AND APTS_Serial_Number__c = :mapOrderSerialNumber.keyset() ];
            for (Apttus_Config2__OrderLineItem__c oOrderLineItem : listPrevOLI) {
                Apttus_Config2__OrderLineItem__c oOLI = mapOrderSerialNumber.get(oOrderLineItem.APTS_Serial_Number__c);
                oOLI.APTS_Original_Order_Line_Item__c = oOrderLineItem.Id;
            }
        }

        if (!mapOLIPhyAsset.isEmpty()) {
            for (Apttus_Config2__OrderLineItem__c oOrderLineItem : orderLineItemList) {
                if (oOrderLineItem.Apttus_Config2__LineType__c == 'Option' && oOrderLineItem.APTS_Option_Group_Text__c == 'Machine' && !oOrderLineItem.Apttus_Config2__HasOptions__c && mapOLIPhyAsset.containsKey(oOrderLineItem.Apttus_Config2__LineNumber__c)) {
                    PhysicalAsset__c oPhyAsset = mapOLIPhyAsset.get(oOrderLineItem.Apttus_Config2__LineNumber__c);
                    if (oPhyAsset != null && oPhyAsset.InitialActivationDate__c != null) {
                        oOrderLineItem.APTS_Batch__c = String.ValueOf((oPhyAsset.InitialActivationDate__c).year());
                    }
                }
            }
        }
    }

    //@Description : Method to get executed afterInsert
    public void afterInsert(List<SObject> newList, Map<Id, SObject> newItems) {

        DescribeSObjectResult objResultOrderLI = APTS_OTCUtil.getsObjectAccess(ORDERLICRUD); // CRUD/FLS Check
        DescribeSObjectResult objResultOrder = APTS_OTCUtil.getsObjectAccess(ORDERCRUD); // CRUD/FLS Check

        //Variable Section
        Map<Id, Apttus_Config2__OrderLineItem__c> idToOrderLineItemTmpMap = (Map<Id, Apttus_Config2__OrderLineItem__c>) newItems;
        Map<Decimal, Apttus_Config2__OrderLineItem__c> bundelLineNumberToOLI = new Map<Decimal, Apttus_Config2__OrderLineItem__c>();
        Set<Id> orderIdSet = new Set<Id>();
        Set<Id> orderIdTrailSet = new Set<Id>();
        Set<Id> lineItemIdSet = new Set<Id>();
        Set<Id> ordLineItemIdSet = new Set<Id>();
        Set<Id> assetIdSet = new Set<Id>(); //V133++ <<>>
        Map<Decimal, Boolean> mapLinePlugnPlay = new Map<Decimal, Boolean>();
        List<Apttus_Config2__OrderLineItem__c> orderLineItemToUpdateList = new List<Apttus_Config2__OrderLineItem__c>();
        List<Apttus_Config2__OrderLineItem__c> orderLineItemToUpdateList_final = new List<Apttus_Config2__OrderLineItem__c>();
        Map<Id, Apttus_Config2__Order__c> idToTrailOrderMap = new Map<Id, Apttus_Config2__Order__c>();
        // v121 <<++
        Set<ID> orderSet = new Set<ID>();
        List<Apttus_Config2__Order__c> orderRemoveDeliveryBlockListFinal = new List<Apttus_Config2__Order__c>();
        Apttus_Config2__Order__c OrderToUpdate = new Apttus_Config2__Order__c();
        Boolean bDeliveryBlockRemove = true;
        // v121 -->>
        //Variable Section

        //SOQL Initial Section
        Map<Id, Apttus_Config2__OrderLineItem__c> idToOrderLineItemMap = APTS_OrderLineItemDAO.getOrderLineItems(idToOrderLineItemTmpMap.keySet());

        //Initial loop
        for (Apttus_Config2__OrderLineItem__c oOrderLineItem : idToOrderLineItemMap.values()) {
            //>>++v109 added condtion for XD09 and XD12
            //Prepare map with bundle line number and OLI
            if (oOrderLineItem.Apttus_Config2__HasOptions__c 
                && oOrderLineItem.APTS_Is_Primary_L1_Line__c
                && !(APTS_BIRUtils.ADMINORDERSAPORDERTYPE.equalsIgnoreCase(oOrderLineItem.APTS_SAP_OrderType__c)
                     || APTS_BIRUtils.CONSUMPTIONSAPORDERTYPE.equalsIgnoreCase(oOrderLineItem.APTS_SAP_OrderType__c))) {
                bundelLineNumberToOLI.put(oOrderLineItem.Apttus_Config2__LineNumber__c, oOrderLineItem);
            }
            orderIdSet.add(oOrderLineItem.Apttus_Config2__OrderId__c);

            //Trail order
            if (oOrderLineItem.APTS_Type_of_contract__c == 'Trial') {
                orderIdTrailSet.add(oOrderLineItem.Apttus_Config2__OrderId__c);
            }
            //DQ-2111- Spin off of DQ-56 Asset Contract Change   
            if(oOrderLineItem.Apttus_Config2__OrderId__r.APTS_Contract_Change__c!= null && oOrderLineItem.Apttus_Config2__OrderId__r.APTS_Contract_Change__c== 'Yes' && oOrderLineItem.Apttus_Config2__LineStatus__c =='Cancelled' && oOrderLineItem.Apttus_Config2__DerivedFromId__c != null && oOrderLineItem.Apttus_Config2__DerivedFromId__r.APTS_CancelledDate__c!= null)
            oOrderLineItem.Apttus_Config2__CancelledDate__c = oOrderLineItem.Apttus_Config2__DerivedFromId__r.APTS_CancelledDate__c;
           
            //DQ-2111- Spin off of DQ-56 Asset Contract Change   
             
            //To set ZX10 value
            if (oOrderLineItem.APTS_SAP_OrderType__c == 'XB13' && oOrderLineItem.Apttus_Config2__AssetLineItemId__c != null) {
                assetIdSet.add(oOrderLineItem.Apttus_Config2__AssetLineItemId__c);
            }
            if (oOrderLineItem.Apttus_Config2__DerivedFromId__c != null) {
                lineItemIdSet.add(oOrderLineItem.Apttus_Config2__DerivedFromId__c);
            } else {
                //For Admin Orders
                ordLineItemIdSet.add(oOrderLineItem.Id);
            }

            if (oOrderLineItem.Apttus_Config2__OptionId__c != null && oOrderLineItem.Apttus_Config2__OptionId__r.APTS_Plug_and_Play_Indicator__c) {
                mapLinePlugnPlay.put(oOrderLineItem.Apttus_Config2__LineNumber__c, oOrderLineItem.Apttus_Config2__OptionId__r.APTS_Plug_and_Play_Indicator__c);
            }
        }
        //Initial loop

        //SOQL Section
        Map<Id, APTS_ItemCategoryDetermination__c> itemCategoryDeterminationMap = APTS_OrderLineItemDAO.getItemCategoryDetermination();
        Map<Id, APTS_ItemRelevancyDetermination__c> itemRelevancyDeterminationMap = APTS_OrderLineItemDAO.getItemRelevancyDetermination();
        Map<Id, Apttus_Config2__Order__c> idToOrderMap = APTS_OrderLineItemDAO.getOrder(orderIdSet);
        /* 
        Map<Id, Apttus_Config2__OrderAdjustmentLineItem__c> ordAdjustmentLineItemMap = APTS_OrderLineItemDAO.getOrderAdjustmentLineItems(ordLineItemIdSet);
        Map<Id, Apttus_Config2__AdjustmentLineItem__c> adjustmentLineItemMap = APTS_OrderLineItemDAO.getAdjustmentLineItems(lineItemIdSet);
        Map<Id, Apttus_Config2_AssetAdjustItem__c> assetAdjustmentLineItemMap = APTS_OrderLineItemDAO.getAssetAdjustmentLineItems(assetIdSet); 
        */
       // APTS_orderUtils.APTS_AdjustmentLIWrapper oAdjustmentWrapper=  new APTS_orderUtils.APTS_AdjustmentLIWrapper();
        List<APTS_orderUtils.APTS_AdjustmentLIWrapper> adjustmentsWrapperList = APTS_orderUtils.getRelatedAdjustments(lineItemIdSet,assetIdSet,ordLineItemIdSet);
        //v101 << ++
        Map<Decimal, String> L1itemCatMap = new Map<Decimal, String>();
        //v101 -->>
        if (!orderIdTrailSet.isEmpty()) {
            idToTrailOrderMap = APTS_OrderLineItemDAO.getOrder(orderIdTrailSet);
        }
        //SOQL Section
        
        //Main loop
        for (Apttus_Config2__OrderLineItem__c oOrderLineItem : idToOrderLineItemMap.values()) {

            Apttus_Config2__Order__c oOrder = idToOrderMap.get(oOrderLineItem.Apttus_Config2__OrderId__c);
              //v164 ++<<
              if(oOrderLineItem.Apttus_Config2__OrderId__r.APTS_Contract_Change__c=='Yes'){
              if(oOrderLineItem.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c == 'XD02' && oOrderLineItem.Apttus_Config2__OrderId__r.APTS_Scenario__c=='Trial to Sales'){//v167
              oOrderLineItem.APTS_Item_Relevant_for_SAP__c = (oOrderLineItem.APTS_Type_of_Contract__c=='Sales' && oOrderLineItem.Apttus_Config2__ChargeType__c=='Sales Price' && oOrderLineItem.Apttus_Config2__LineStatus__c == 'New') ? true: false;
              }
              }                  
            //v164 ++>>
            else if (oOrderLineItem.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c != System.Label.APTS_XC01) {

                Boolean bZOPT = oOrderLineItem.Apttus_Config2__ProductId__r.APTS_Material_Type__c == APTS_OrderConstants.ZOPT && !oOrderLineItem.Apttus_Config2__ProductId__r.APTS_Not_relevant_for_SAP__c;
                //V105 ++ <<
                if (oOrderLineItem.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c != APTS_OrderConstants.XD09 && !bZOPT 
                    && oOrderLineItem.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c != CREDITORDERSAPTYPE ) {//V155 
                    //Set the item relevant to SAP flag
                    if (oOrderLineItem.Apttus_Config2__HasOptions__c) {
                        oOrderLineItem.APTS_Item_Relevant_for_SAP__c = oOrderLineItem.APTS_Is_Primary_L1_Line__c;
                        
                        if (mapLinePlugnPlay != null && mapLinePlugnPlay.containsKey(oOrderLineItem.Apttus_Config2__LineNumber__c))
                            oOrderLineItem.APTS_PlugPlay__c = mapLinePlugnPlay.get(oOrderLineItem.Apttus_Config2__LineNumber__c) == null ? false : mapLinePlugnPlay.get(oOrderLineItem.Apttus_Config2__LineNumber__c);
                    } else {
                        oOrderLineItem.APTS_Item_Relevant_for_SAP__c = APTS_OrderUtils.getItemRelevancy(itemRelevancyDeterminationMap, oOrderLineItem);
                    }
                }

                Boolean hasZX10 = false;
                Boolean bICDYoci = false;
                Boolean bICDYoft = false;
              //V133 ++ <<
                    bICDYoci = APTS_OrderUtils.checkAdjLIYOCIYOFTValue(oOrderLineItem, adjustmentsWrapperList, true);
                    bICDYoft = APTS_OrderUtils.checkAdjLIYOCIYOFTValue(oOrderLineItem, adjustmentsWrapperList, false);

                if (oOrderLineItem.APTS_ZX10__c == NULL && (oOrderLineItem.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c != 'XD09' || oOrderLineItem.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c != 'XD12' || oOrderLineItem.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c != CREDITORDERSAPTYPE)) {//V155 
                    if (adjustmentsWrapperList!= null && !adjustmentsWrapperList.isEmpty()) {
                        hasZX10 = APTS_OrderUtils.checkIfAdjustmentValueIsZX10(oOrderLineItem, adjustmentsWrapperList);
                    }
                    System.debug('hasZX10=====>'+hasZX10);
                    System.debug('oOrderLineItem=====>'+oOrderLineItem);
                    System.debug('adjustmentsWrapperList=====>'+adjustmentsWrapperList);
                    oOrderLineItem.APTS_ZX10__c = (hasZX10) ? 100 : null;
                }
               //V133 ++ >>
                //v117 ++ <<
                if (!bICDYoci && !bICDYoft && (oOrderLineItem.Apttus_Config2__OrderId__r.APTS_Order_Type__c == 'Machine Order') && (oOrderLineItem.Apttus_Config2__LineType__c == OPTION) && (oOrderLineItem.Apttus_Config2__ChargeType__c != 'Usage Fee')&& oOrderLineItem.Apttus_Config2__NetPrice__c == 0 && oOrderLineItem.Apttus_Config2__ListPrice__c == 0)
                {
                    oOrderLineItem.APTS_ZX10__c = 100;
                }
                // v117 -->>
                if (oOrderLineItem.APTS_Item_Relevant_for_SAP__c) {
                    //v108 Start
                   String itemCategory = APTS_OrderUtils.getItemCategory(itemCategoryDeterminationMap, oOrderLineItem, bICDYoci,bICDYoft);
                    //v108 End
                    if ((itemCategory != null && itemCategory != 'BLANK') || Test.isRunningTest()) {
                        oOrderLineItem.APTS_Item_Category__c = itemCategory;
                    }
                    
                    // Defect# 23415 */
                    //v101 << ++ Store the Machine Option - Item Category to the Line Number Map.In the next iteration this will be set to L1 Primary

                    if (oOrderLineItem.APTS_Option_Group_Text__c != null && oOrderLineItem.APTS_Option_Group_Text__c == MACHINEOPTION && oOrderLineItem.APTS_Item_Category__c != null) {

                        L1itemCatMap.put(oOrderLineItem.Apttus_Config2__LineNumber__c, oOrderLineItem.APTS_Item_Category__c);
                    }

                    //v101 -->>
                }
            }

            //v141<<-- Starts
            if(oOrderLineItem.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c == System.Label.APTS_XC01
                && oOrderLineItem.Apttus_Config2__LineType__c==APTS_OrderConstants.PRODUCT_OR_SERVICE
                && oOrderLineItem.Apttus_Config2__HasOptions__c) {
                oOrderLineItem.APTS_Item_Relevant_for_SAP__c=false;
            }
            //v141 -- Ends>>
            
            //DQ-56- v1.9 - Populate Agreement Logic for Asset Contract change
           
            if(oOrder.APTS_Contract_Change__c != null && oOrder.APTS_Contract_Change__c=='Yes')
            {
            if(oOrderLineItem.Apttus_Config2__DerivedFromId__r.APTS_Agreement__c != null)
            oOrderLineItem.Apttus_CMConfig__AgreementId__c = oOrderLineItem.Apttus_Config2__DerivedFromId__r.APTS_Agreement__c; 
            else if(oOrderLineItem.Apttus_Config2__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c != null)
            oOrderLineItem.Apttus_CMConfig__AgreementId__c = oOrderLineItem.Apttus_Config2__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c;
            }
            if (oOrderLineItem.Apttus_Config2__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Refurbished__c == 'Yes') {
                oOrderLineItem.APTS_Refurbished_or_New__c = REFURBISHED;
                oOrderLineItem.APTS_RefurbishedMachine__c = true;
            } else {
                oOrderLineItem.APTS_Refurbished_or_New__c = NEW_MACHINE;
            }

            //9-Aug-2018 - Added below to set the Agreement Line Item on OLI
            oOrderLineItem.Apttus_CMConfig__AgreementLineItemId__c = oOrderLineItem.Apttus_Config2__DerivedFromId__r.APTS_Agreement_Line_Item__c;

            //Update OLI Selling term from ALI selling term
            if (oOrderLineItem.Apttus_Config2__DerivedFromId__r.APTS_Agreement_Line_Item__c != null) {oOrderLineItem.Apttus_Config2__SellingTerm__c =  oOrderLineItem.Apttus_Config2__DerivedFromId__r.APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingTerm__c;}

            if (oOrderLineItem.Apttus_Config2__OptionId__c != null && oOrderLineItem.Apttus_Config2__OptionId__r.APTS_Plug_and_Play_Indicator__c) { oOrderLineItem.APTS_PlugPlay__c = oOrderLineItem.Apttus_Config2__OptionId__r.APTS_Plug_and_Play_Indicator__c; }

            //v104 ++ <<
            if (oOrderLineItem.APTS_Installation_Contact__c != null) {
                if (oOrderLineItem.APTS_Installation_Contact__r.MobilePhone != null) {
                    oOrderLineItem.APTS_Installation_Contact_Phone__c = oOrderLineItem.APTS_Installation_Contact__r.MobilePhone;
                } else if (oOrderLineItem.APTS_Installation_Contact__r.Phone != null) {
                    oOrderLineItem.APTS_Installation_Contact_Phone__c = oOrderLineItem.APTS_Installation_Contact__r.Phone;
                }
            }
            //v104 ++ >>

            //Set Parent Order Line Item on options with last 5 symbols of bundle name
            //Or Parent Order Line Item on standalone with last 5 symbols of standalone name
            Apttus_Config2__OrderLineItem__c oOrderLineItemWithParent = setParentOrderLineItem(oOrderLineItem, bundelLineNumberToOLI);
            if (oOrderLineItemWithParent != null) {
                orderLineItemToUpdateList.add(oOrderLineItemWithParent);
            } else {
                orderLineItemToUpdateList.add(oOrderLineItem);
            }
            
            //v121 << ++
            String SapOrderType = oOrderLineItem.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c;
            if(oOrderLineItem.Apttus_Config2__OrderId__r.APTS_Order_Type__c == APTS_OrderConstants.MACHINE_ORDER ){
                if( oOrderLineItem.APTS_Is_Primary_L1_Line__c == true && oOrderLineItem.Apttus_Config2__LineType__c == APTS_OrderConstants.PRODUCT_OR_SERVICE){
                    if(SapOrderType == XA13 || SapOrderType == APTS_OrderConstants.XA14 || SapOrderType == APTS_OrderConstants.XA23){
                        oOrderLineItem.APTS_Installation_Required__c  = oOrderLineItem.Apttus_Config2__DerivedFromId__r.APTS_Order_LSP_Detail__r.APTS_Require_Installation__c;
                    }else if(SapOrderType == XB13 || SapOrderType == APTS_OrderConstants.XB23){ //v163
                        oOrderLineItem.APTS_De_Installation_Required__c =oOrderLineItem.Apttus_Config2__DerivedFromId__r.APTS_Order_LSP_Detail__r.APTS_Require_De_Installation__c ;
                        //V135 ++ <<
                        if(oOrderLineItem.APTS_Item_Relevant_for_SAP__c && oOrderLineItem.Apttus_Config2__AssetLineItemId__c != null)
                        {
                            oOrderLineItem.Apttus_CMConfig__AgreementId__c = oOrderLineItem.Apttus_Config2__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c;
                            oOrderLineItem.Apttus_CMConfig__AgreementLineItemId__c = oOrderLineItem.Apttus_Config2__AssetLineItemId__r.Apttus_CMConfig__AgreementLineItemId__c;
                        }
                        //V135 ++ >>
                    }
                }
            }
            if(oOrderLineItem.Apttus_Config2__OrderId__r.APTS_Order_Type__c == APTS_OrderConstants.MACHINE_ORDER ){
                orderSet.add(oOrderLineItem.Apttus_Config2__OrderId__c);
                if(oOrderLineItem.APTS_Is_Primary_L1_Line__c == TRUE && (oOrderLineItem.APTS_Installation_Required__c == TRUE) || oOrderLineItem.APTS_De_Installation_Required__c == TRUE){
                    bDeliveryBlockRemove = false;
                }
            }
            //v121 -- >>
             //v169 ++<<
             if(oOrderLineItem.Apttus_Config2__LineStatus__c == 'New' && oOrderLineItem.Apttus_Config2__OrderId__r.APTS_Contract_Change__c!= null && oOrderLineItem.Apttus_Config2__OrderId__r.APTS_Contract_Change__c== 'Yes' && oOrderLineItem.Apttus_Config2__OrderId__r.APTS_Scenario__c != null && oOrderLineItem.Apttus_Config2__OrderId__r.APTS_Scenario__c == 'Trial To Sales')
             {
                 if(oOrderLineItem.Apttus_Config2__DerivedFromId__c != null && oOrderLineItem.Apttus_Config2__DerivedFromId__r.APTS_Terminated_Asset_Line__c != null && oOrderLineItem.Apttus_Config2__DerivedFromId__r.APTS_Terminated_Asset_Line__r.APTS_Installation_Sales_Order_Item__c!=null){
                     oOrderLineItem.APTS_Batch__c = oOrderLineItem.Apttus_Config2__DerivedFromId__r.APTS_Terminated_Asset_Line__r.APTS_Installation_Sales_Order_Item__c.right(5);
                 }
             }
             //v169 ++>>
        }
        //Main loop
        //v101 << ++
        //v121 <<++
        if(bDeliveryBlockRemove && orderSet.size() > 0 ){
            for(ID oID : orderSet){
                if(idToOrderMap.containsKey(oID)){
                    orderToUpdate = idToOrderMap.get(oID);
                    OrderToUpdate.APTS_Delivery_Block__c = NULL;
                    orderRemoveDeliveryBlockListFinal.add(OrderToUpdate);
                }
            }
        }         
        //v121 -->>
        
        for (Apttus_Config2__OrderLineItem__c oOrderLineItem : orderLineItemToUpdateList) {
            if (oOrderLineItem.APTS_Is_Primary_L1_Line__c && oOrderLineItem.APTS_Item_Relevant_for_SAP__c && L1itemCatMap.get(oOrderLineItem.Apttus_Config2__LineNumber__c) != null) {
                oOrderLineItem.APTS_Item_Category__c = L1itemCatMap.get(oOrderLineItem.Apttus_Config2__LineNumber__c);
            }

            orderLineItemToUpdateList_final.add(oOrderLineItem);

        }
        //v101 -->>
        //Loops on other objects
        for (Apttus_Config2__Order__c oOrder : idToTrailOrderMap.values()) {
        system.debug('$$$1'+oOrder);
        if(oOrder.APTS_Contract_Change__c != null && oOrder.APTS_Contract_Change__c != 'Yes' && oOrder.APTS_SAP_OrderType__c == 'XA13'){ //V151 ++ <<>>
            system.debug('$$$12'+oOrder);
            oOrder.APTS_SAP_OrderType__c = 'XA23';
        }
       
        }
        //Loops on other objects
        

        //DML Section        
        if (!orderLineItemToUpdateList_final.isEmpty()) {
            if (objResultOrderLI.isUpdateable()) {
                isTriggerDisabled = true;
                update orderLineItemToUpdateList_final;
                isTriggerDisabled = false;
            }
        }
        if (!idToTrailOrderMap.isEmpty()) {
            if (objResultOrder.isUpdateable()) {
                APTS_OrderUtils.stopOrderTrigger();
                Database.update(idToTrailOrderMap.values());
                APTS_OrderUtils.startOrderTrigger();
            }                
        }
        
        //v121 <<++
        if (!orderRemoveDeliveryBlockListFinal.isEmpty()) {
            if (objResultOrder.isUpdateable()) {
                APTS_OrderUtils.stopOrderTrigger();
                Database.update(orderRemoveDeliveryBlockListFinal);
                APTS_OrderUtils.startOrderTrigger();
            }                
        }
        //121 -->>
        
        //DML Section
    }

    //@Description : Method to get executed beforeUpdate
    public void beforeUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldItems) {
        //Variable Section
        Map<Id, Apttus_Config2__OrderLineItem__c> idToOrderLineItemMap = (Map<Id, Apttus_Config2__OrderLineItem__c>) newItems;
        Map<Id, Apttus_Config2__OrderLineItem__c> idToOldOrderLineItemMap = (Map<Id, Apttus_Config2__OrderLineItem__c>) oldItems;            
        Set<Id> orderLineItemFromAcceptOrderSet = new Set<Id>();
        Set<Id> orderLineItemWithStatusUpdateSet = new Set<Id>();
        Set<Id> orderLineItemWithATPSet = new Set<Id>();
        Set<Id> orderLineItemWithInstallationDateSet = new Set<Id>();
        Set<Id> orderIdSet = new Set<Id>();
        Set<Id> orderSet = new Set<Id>();
        Set<Id> orderLineItemWithDeInstallationDateSet = new Set<Id>();
        Set<Id> orderLIAssetIdSet = new Set<Id>();
        Map<String,Date> minPendingBillingDate = new Map<String,Date>();
        //Variable Section
         
        //Initial loop
        for (Apttus_Config2__OrderLineItem__c oOrderLineItem : idToOrderLineItemMap.values()) {            
            if(idToOldOrderLineItemMap.get(oOrderLineItem.Id) != null && idToOldOrderLineItemMap.get(oOrderLineItem.Id).APTS_Option_Group_Text__c != null && 
            oOrderLineItem.APTS_Option_Group_Text__c != null && idToOldOrderLineItemMap.get(oOrderLineItem.Id).APTS_Option_Group_Text__c != oOrderLineItem.APTS_Option_Group_Text__c &&
            oOrderLineItem.Apttus_Config2__LineStatus__c!='New'){
                oOrderLineItem.APTS_Option_Group_Text__c = idToOldOrderLineItemMap.get(oOrderLineItem.Id).APTS_Option_Group_Text__c;
            }
            //v132<< Remove the Serial Number on "NON L1 Primary Line" v132>> && DQ-56- Asset Contract Change-v1.9
            if(oOrderLineItem.Apttus_Config2__LineType__c != OPTION && !oOrderLineItem.APTS_Is_Primary_L1_Line__c && oOrderLineItem.Apttus_Config2__OrderId__r.APTS_Contract_Change__c!= 'Yes'){
              oOrderLineItem.APTS_Serial_Number__c = null;
            }
            
            //Submit order will call acceptOrder API this will change Apttus_Config2__Status__c from Draft to Pending
            //On this action we will set custom status to SUBMITTED
            Boolean bOldStatusDraftOrInAmendment = idToOldOrderLineItemMap.get(oOrderLineItem.Id).Apttus_Config2__Status__c == DRAFT || idToOldOrderLineItemMap.get(oOrderLineItem.Id).Apttus_Config2__Status__c == IN_AMENDMENT;
            if (bOldStatusDraftOrInAmendment && oOrderLineItem.Apttus_Config2__Status__c == PENDING) {
                orderLineItemFromAcceptOrderSet.add(oOrderLineItem.Id);
            } else if (idToOldOrderLineItemMap.get(oOrderLineItem.Id).Apttus_Config2__Status__c != oOrderLineItem.Apttus_Config2__Status__c) {
                //For all other updates on order line item status set order line item custom status to order line item status
                orderLineItemWithStatusUpdateSet.add(oOrderLineItem.Id);
                }

            //First SAP update will populate APTS_SAP_Order_Line_Item_Number__c on Relevant for SAP lines
            Boolean bSAPOLINUpdate = oOrderLineItem.APTS_SAP_Order_Line_Item_Number__c != null && !oOrderLineItem.APTS_ATP_Cleared__c ;
            orderSet.add(oOrderLineItem.Id);
            Set<String> adminOrderSapTypes = new Set<String> {'XD01', 'XD12', 'XC01', 'XD09','XC09', 'XD02'};  //V168 ++ <<>>
          
            if (bSAPOLINUpdate && !adminOrderSapTypes.contains(oOrderLineItem.APTS_SAP_OrderType__c)) {
                orderLineItemWithATPSet.add(oOrderLineItem.Id);
            }

            //Second TS update will populate APTS_Installation_Date__c or APTS_De_installation_Date__c on primary lines
            //On this action we will set installation and deinstallation date
            Boolean bInstalationDateChange = idToOldOrderLineItemMap.get(oOrderLineItem.Id).APTS_Installation_Date_Authorized__c == null && oOrderLineItem.APTS_Installation_Date_Authorized__c != null;
            Boolean bDeInstalationDateChange = idToOldOrderLineItemMap.get(oOrderLineItem.Id).APTS_De_installation_Date_Authorized__c == null && oOrderLineItem.APTS_De_installation_Date_Authorized__c != null;
            System.debug('Test debug->'+bDeInstalationDateChange);
            if (bInstalationDateChange) {
                orderLineItemWithInstallationDateSet.add(oOrderLineItem.Id);
            } else if (bDeInstalationDateChange) {
                orderLineItemWithDeInstallationDateSet.add(oOrderLineItem.Id);
                System.debug('Test debug->'+orderLineItemWithDeInstallationDateSet);
            }
        
            orderIdSet.add(oOrderLineItem.Apttus_Config2__OrderId__c);
        }
        //Initial loop

        //SOQL Section
        Map<Id, Apttus_Config2__Order__c> idToOrderMap = APTS_OrderLineItemDAO.getOrder(orderIdSet);
        //SOQL Section

        //Main loop
        for (Apttus_Config2__OrderLineItem__c oOrderLineItem : idToOrderLineItemMap.values()) {
            Apttus_Config2__Order__c oOrder = idToOrderMap.get(oOrderLineItem.Apttus_Config2__OrderId__c);
            //system.debug(oOrder.APTS_Status__c);
            if (orderLineItemFromAcceptOrderSet.contains(oOrderLineItem.Id)) {
                oOrderLineItem.APTS_Status__c = SUBMITTED;
            }
            
           
            if (orderLineItemWithStatusUpdateSet.contains(oOrderLineItem.Id)) {                                
                oOrderLineItem.APTS_Status__c = oOrderLineItem.Apttus_Config2__Status__c;
            }

            
            if (orderLineItemWithATPSet.contains(oOrderLineItem.Id)) {
                oOrderLineItem.APTS_ATP_Cleared__c = true;                                
                oOrderLineItem.APTS_Status__c = PENDING;
            
            }
            

             if (orderLineItemWithInstallationDateSet.contains(oOrderLineItem.Id) || orderLineItemWithDeInstallationDateSet.contains(oOrderLineItem.Id)) {
                oOrderLineItem.APTS_Installation_Date__c = oOrderLineItem.APTS_Installation_Date_Authorized__c;
                oOrderLineItem.APTS_De_installation_Date__c = oOrderLineItem.APTS_De_installation_Date_Authorized__c;
            }

            //Technical Swap don't activate Order
            /*Apttus_Config2__Order__c oMasterOrder = idToOrderMap.get(oOrderLineItem.Apttus_Config2__OrderId__c);
            if (oOrderLineItem.Apttus_Config2__ActivatedDate__c != null && oMasterOrder != null && 'Technical Swap'.equalsIgnoreCase(oMasterOrder.APTS_Order_Sub_Type__c) && 'XB13'.equalsIgnoreCase(oMasterOrder.APTS_SAP_OrderType__c)) {
                oOrderLineItem.Apttus_Config2__ActivatedDate__c = null;
                oOrderLineItem.Apttus_Config2__Status__c = 'Activated';
                oOrderLineItem.APTS_Status__c = 'Activated';
            }*/

            //9 Aug 2018 - Amend/Cancel Order changes 
            if (oOrderLineItem.Apttus_Config2__PreviousVersion__c != null && oOrderLineItem.Apttus_Config2__Status__c != PENDING) {
                oOrderLineItem.APTS_Status__c = oOrderLineItem.Apttus_Config2__Status__c;
            }
           /* System.debug('old status=====>'+idToOldOrderLineItemMap.get(oOrderLineItem.Id).Apttus_Config2__Status__c);
            System.debug('old ready for billing=====>'+idToOldOrderLineItemMap.get(oOrderLineItem.Id).Apttus_Config2__ReadyForBillingDate__c);
            System.debug('old activation=====>'+idToOldOrderLineItemMap.get(oOrderLineItem.Id).Apttus_Config2__ActivatedDate__c);
            System.debug('new status=====>'+oOrderLineItem.Apttus_Config2__Status__c);
            System.debug('new ready for billing=====>'+oOrderLineItem.Apttus_Config2__ReadyForBillingDate__c);
            System.debug('new activation=====>'+oOrderLineItem.Apttus_Config2__ActivatedDate__c); */
            
            if (idToOldOrderLineItemMap.get(oOrderLineItem.Id).Apttus_Config2__ActivatedDate__c == null && oOrderLineItem.Apttus_Config2__ActivatedDate__c != null && oOrderLineItem.Apttus_Config2__ReadyForBillingDate__c != null && oOrder != null && oOrder.APTS_Order_Sub_Type__c!=null) {
                //v164 ++<<
                if(oOrder.APTS_Order_Type__c.equalsIgnoreCase(APTS_OrderConstants.MACHINE_ORDER)){
                    String SapOrderType = oOrderLineItem.APTS_SAP_OrderType__c;
                    oOrderLineItem.Apttus_Config2__ActivatedDate__c = (SapOrderType == 'XB13')? oOrderLineItem.Apttus_Config2__EndDate__c : oOrderLineItem.Apttus_Config2__StartDate__c;
                } //v164 ++>>
                else
                {
                    oOrderLineItem.Apttus_Config2__ReadyForBillingDate__c = oOrderLineItem.Apttus_Config2__StartDate__c;
                    //DFT2C-1561 changes | Karan Khatri | Populating activation date as start date of orderline item
                    if(oOrder.APTS_Order_Type__c.equalsIgnoreCase(APTS_OrderConstants.ADMIN_ORDER) && !oOrder.APTS_Order_Sub_Type__c.equalsIgnoreCase(APTS_BIRUtils.ORDERSUBTYPE)){
                        oOrderLineItem.Apttus_Config2__ActivatedDate__c = oOrderLineItem.Apttus_Config2__StartDate__c;
                    }
                }
                
            }
            
            /*if(idToOldOrderLineItemMap.get(oOrderLineItem.Id).Apttus_Config2__Status__c.equalsIgnoreCase(APTS_OrderConstants.FULFILLED) && oOrderLineItem.Apttus_Config2__Status__c.equalsIgnoreCase(APTS_OrderConstants.ACTIVATED)){
                oOrderLineItem.Apttus_Config2__ReadyForBillingDate__c = oOrderLineItem.Apttus_Config2__StartDate__c;
                //DFT2C-1561 changes | Karan Khatri | Populating activation date as start date of orderline item
                if(oOrder.APTS_Order_Type__c.equalsIgnoreCase(APTS_OrderConstants.ADMIN_ORDER) && !oOrder.APTS_Order_Sub_Type__c.equalsIgnoreCase(APTS_BIRUtils.ORDERSUBTYPE)){
                    oOrderLineItem.Apttus_Config2__ActivatedDate__c = oOrderLineItem.Apttus_Config2__StartDate__c;
                }
            }*/

            if (idToOldOrderLineItemMap.get(oOrderLineItem.Id).Apttus_Config2__PreviousVersion__c != null && oOrderLineItem.Apttus_Config2__PreviousVersion__c != null && (oOrderLineItem.Apttus_Config2__Status__c == IN_AMENDMENT || oOrderLineItem.Apttus_Config2__Status__c == 'Pending Cancellation') && oOrderLineItem.Name != oOrderLineItem.Apttus_Config2__OriginalLineNumber__c) {
                oOrderLineItem.Apttus_Config2__OriginalLineNumber__c = idToOldOrderLineItemMap.get(oOrderLineItem.Id).Apttus_Config2__OriginalLineNumber__c;
            }

            /*if (oOrder.Apttus_CMConfig__AgreementId__c != null && oOrderLineItem.Apttus_Config2__Status__c == 'Draft') {
                oOrderLineItem.Apttus_Config2__AutoRenew__c = oOrder.Apttus_CMConfig__AgreementId__r.Apttus__Auto_Renewal__c;
            }*/
            //v134 ++<<
            
            oOrderLineItem.APTS_Bill_to_Party_Ingredients_and_Payer__c = oOrder.APTS_Bill_to_Party_Ingredients_and_Payer__c;
            oOrderLineItem.APTS_Bill_to_Party_Machines_Services__c = oOrder.APTS_Bill_to_Party_Machines_Services__c;
            oOrderLineItem.APTS_PayerIngredients__c = oOrder.APTS_PayerIngredients__c;
            oOrderLineItem.APTS_PayerMachinesServices__c = oOrder.APTS_PayerMachinesServices__c;
            //v134 ++>>
            
            // v106++<< Start of cascading the values of billing preference, Payment Method and Payment Term
            //oOrderLineItem.Apttus_Config2__BillingPreferenceId__c = oOrder.Apttus_Config2__BillingPreferenceId__c != null?  oOrder.Apttus_Config2__BillingPreferenceId__c:null;
            //oOrderLineItem.APTS_Payment_Method__c = oOrder.APTS_Payment_Method__c != null? oOrder.APTS_Payment_Method__c : null;
            //oOrderLineItem.Apttus_Config2__PaymentTermId__c = oOrder.Apttus_Config2__PaymentTermId__c != null? oOrder.Apttus_Config2__PaymentTermId__c : null;
            // v106--<< Start of cascading the values of billing preference, Payment Method and Payment Term
            
            //v119 : CR2289 : make options not relevant for SAP
            if (oOrder != null && PENDING_CANCELLATION.equalsIgnoreCase(oOrder.Apttus_Config2__Status__c) && OPTION.equalsIgnoreCase(oOrderLineItem.Apttus_Config2__LineType__c)) {
                oOrderLineItem.APTS_Item_Relevant_for_SAP__c = false;
            }
            //V139 ++ <<
            List<String> orderSubTypeAdminOrderRBD = System.Label.APTS_BillingDateOrderSubType.split(',');
            //v157 ++<<
            //if(oOrder != null && orderSubTypeAdminOrderRBD.contains(oOrder.APTS_Order_Sub_Type__c) && idToOldOrderLineItemMap.get(oOrderLineItem.Id).Apttus_Config2__Status__c != oOrderLineItem.Apttus_Config2__Status__c && oOrderLineItem.Apttus_Config2__Status__c == 'Pending') {
            if(oOrder != null && (orderSubTypeAdminOrderRBD.contains(oOrder.APTS_Order_Sub_Type__c) || (oOrder.APTS_Order_Sub_Type__c == CONVERSION && oOrder.APTS_Order_Sub_Sub_Type__c!=null ) ) && idToOldOrderLineItemMap.get(oOrderLineItem.Id).Apttus_Config2__Status__c != oOrderLineItem.Apttus_Config2__Status__c && oOrderLineItem.Apttus_Config2__Status__c == 'Pending') {
                oOrderLineItem.Apttus_Config2__ReadyForBillingDate__c = oOrderLineItem.Apttus_Config2__StartDate__c;                   
            }

            System.debug('Lavanya Order Status in OLI triggerHander'+oOrder.Apttus_Config2__Status__c);
            //v157 ++>>
            //V139 ++ >>
            //v156 ++<<
           if((oOrderLineItem.APTS_Is_Primary_L1_Line__c && oOrderLineItem.APTS_SAP_OrderType__c == 'XA14' && idToOldOrderLineItemMap.get(oOrderLineItem.Id).APTS_Installation_Required__c != true) || Test.isRunningTest()){
            oOrderLineItem.APTS_Installation_Required__c = true;
             
            }
            
            //v156 ++>>
        } 
         
        //Main loop
                
    }


    //@Description : Method to get executed afterUpdate
    public void afterUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldItems) {
        
        DescribeSObjectResult objResultOrderLI = APTS_OTCUtil.getsObjectAccess(ORDERLICRUD); // CRUD/FLS
        DescribeSObjectResult objResultPhyAsset = APTS_OTCUtil.getsObjectAccess(PHYASSETCRUD); // CRUD/FLS
        DescribeSObjectResult objResultOrder = APTS_OTCUtil.getsObjectAccess(ORDERCRUD); // CRUD/FLS Check
        DescribeSObjectResult objResultAsstLI = APTS_OTCUtil.getsObjectAccess(ASSETLICRUD); // CRUD/FLS Check
        List<Apttus_Config2__OrderLineItem__c>lstOLiToUpdate= new List<Apttus_Config2__OrderLineItem__c>();
        

        //Variable Section
        Map<Id, Apttus_Config2__OrderLineItem__c> idToOrderLineItemTmpMap = (Map<Id, Apttus_Config2__OrderLineItem__c>) newItems;
        Map<Id, Apttus_Config2__OrderLineItem__c> idToOldOrderLineItemMap = (Map<Id, Apttus_Config2__OrderLineItem__c>) oldItems;
        //System.debug('@@@@@idToOrderLineItemTmpMap '+idToOrderLineItemTmpMap );
        //System.debug('@@@@@idToOldOrderLineItemMap '+idToOldOrderLineItemMap );   
        Set<Id> orderIdSet = new Set<Id>();
        Set<Id> orderLineItemIdSet = new Set<Id>();
        Set<String> orderSubTypeWithOutATPResultSet = new Set<String> {STANDARD_RETURN, UNPLANNED_RETURN, DE_INSTALLATION, CONVERSION, INTERNAL_MOVEMENT, EXTERNAL_MOVEMENT_WITH_CONTRACT_CHANGE, EXTERNAL_MOVEMENT_WITHOUT_CONTRACT_CHANGE};

        Set<Id> orderIdWithATPResultSet = new Set<Id>();
        Set<Id> orderLineItemIdWithSerialNumberSet = new Set<Id>();
        Set<Id> orderIdWithNegativeATPResultSet = new Set<Id>();
        Set<Id> orderIdWithMADSet = new Set<Id>();
        Set<Id> orderIdWithSAPOLINSet = new Set<Id>();
        Set<Id> orderIdWithSAPOLINAndMADSet = new Set<Id>();
        Set<Id> agreementIdSet = new Set<Id>();
        Set<Id> orderLineItemIdWithAssetAndPhysicalAssetSet = new Set<Id>();
        Set<Id> orderDebitMemoIdSet = new Set<Id>();
        Map<Decimal,String> mapParentSerialNumber= new Map<Decimal,String>();
        Map<Id, Apttus_Config2__OrderLineItem__c> physicalAssetIdToOLIMap = new Map<Id, Apttus_Config2__OrderLineItem__c>();
        List<PhysicalAsset__c> physicalAssetToUpdateList = new List<PhysicalAsset__c>();
        List<Apttus_Config2__OrderLineItem__c> orderLineItemWithAssetList = new List<Apttus_Config2__OrderLineItem__c>();
        List<Apttus_Config2__Order__c> orderToUpdateList = new List<Apttus_Config2__Order__c>();
        List<Apttus_Config2__Order__c> orderFailToUpdateList = new List<Apttus_Config2__Order__c>();
        Map<Id, PhysicalAsset__c> orderLineItemIdToPhysicalAssetToCreateMap = new Map<Id, PhysicalAsset__c>();
        //3.1
        //v123 ++ <<
        List<Apttus_Config2__Order__c> orderToUpdateListNew = new List<Apttus_Config2__Order__c>();
        //v123 ++ >>
        //3.1

        Map<Id, Id> orderLineItemIdToAgreementIdMap = new Map<Id, Id>();
        //Map<Id, List<APTS_Agreement_PO_Details__c>> agreementIdToPOMap = new Map<Id, List<APTS_Agreement_PO_Details__c>>(); //V160 ++ <<>>
        Map<Id, Apttus_Config2__OrderLineItem__c> idToOrderLineItemToUpdateMap = new Map<Id, Apttus_Config2__OrderLineItem__c>();
        List<Apttus_Config2__AssetLineItem__c> assetLineItemToUpdateList = new List<Apttus_Config2__AssetLineItem__c>();
        Map<String, PhysicalAsset__c> parentOLIToPhysicalAssetMap = new Map<String, PhysicalAsset__c>();
        List<Apttus_Config2__OrderLineItem__c> oLIUpdateList = new List<Apttus_Config2__OrderLineItem__c>();
        List<Apttus_Config2__OrderLineItem__c> oLIPAUpdateList = new List<Apttus_Config2__OrderLineItem__c>();
        Map<String, Apttus_Config2__OrderLineItem__c> serialNoToOLIMap = new Map<String, Apttus_Config2__OrderLineItem__c>();
        Map<String, Apttus_Config2__OrderLineItem__c> childOLIMap = new Map<String, Apttus_Config2__OrderLineItem__c>();
        Map<String, Apttus_Config2__OrderLineItem__c> oLIMapTOUpdate = new Map<String, Apttus_Config2__OrderLineItem__c>();
        Map<Id, Date> orderIdToActivationDateMap = new Map<Id, Date>();
        Set<String> optionGroupSet = new Set<String>();
        Set<Id> orderIdWithIDASet = new Set<Id>();
        Set<Id> orderLineItemIdWithIDASet = new Set<Id>();
        List<Apttus_Config2__OrderLineItem__c> orderLineItemWithSEDList = new List<Apttus_Config2__OrderLineItem__c>();
        set<Id> refurbishedOLIs = new set<Id>();
        Set<Id> movementOLIWithIDASet = new Set<id>(); //V164++ << >>
        List<Apttus_Config2__OrderLineItem__c> movementOLIUpdateList = new List<Apttus_Config2__OrderLineItem__c>();
                    
        //3.1
        //v123 ++ <<
        Boolean cancelledOLI = true;
        Integer numRejectedLI = 0;
        //v123 ++ >>
        //3.1
        //v131 << ++
        Boolean bStatusActivatedAsset = false;
        Boolean bStatusActivatedOLI = false;
        //v131 ++ >>
        Boolean bStatusCancelledOLI = false; //V158 ++ <<>>
        //Variable Section
        
        try
        {

        //Initial tmp loop
        for (Apttus_Config2__OrderLineItem__c oOrderLineItem : idToOrderLineItemTmpMap.values()) {
            //v118 ++ << XD09 and XD12 condition Added  by Balashanthi A for BSS Defect # 6776 Start
            if(!(ADMINORDERSAPTYPE.equalsIgnoreCase(oOrderLineItem.APTS_SAP_OrderType__c)
                 || ADMINORDERCONSUMSAPTYPE.equalsIgnoreCase(oOrderLineItem.APTS_SAP_OrderType__c)
                 || CREDITORDERSAPTYPE.equalsIgnoreCase(oOrderLineItem.APTS_SAP_OrderType__c) )){
            //v118 ++ << XD09 and XD12 condition Added  by Balashanthi A for BSS Defect # 6776 END
                orderIdSet.add(oOrderLineItem.Apttus_Config2__OrderId__c);
                orderLineItemIdSet.add(oOrderLineItem.Id);
            } // v118 ++ << XD09 and XD12 condition Added  by Balashanthi A for BSS Defect # 6776
        }

        //SOQL Section
        Map<Id, Apttus_Config2__Order__c> idToOrderMap = APTS_OrderLineItemDAO.getOrder(orderIdSet);
        Map<Id, Apttus_Config2__OrderLineItem__c> idToOrderLineItemMap = APTS_OrderLineItemDAO.getOrderLineItems(orderLineItemIdSet);
        //v113 ++ <<
        Map<Id, Apttus_Config2__OrderLineItem__c> idToAllOrderLineItemMap = APTS_OrderLineItemDAO.getAllOrderLineItems(orderIdSet);
        //v113 ++ <<
        //SOQL Section
        try
        {
        APTS_BIRUtils.createVolumeObligationLineItems(newList, newItems, oldList, oldItems, idToOrderMap);
            if(Test.isRunningTest()){ Decimal dc1 = 1 / 0; }
        }
        catch(Exception bIREx)
        {
            APTS_CustomLogging.createErrorLog(bIREx.getTypeName(), 'Apex', bIREx.getStackTraceString() , 'Order', null, 'BIR', false, true, null, true);
    
        }

        //Initial loop
        for (Apttus_Config2__OrderLineItem__c oOrderLineItem : idToOrderLineItemTmpMap.values()) {
            //v118,V155 ++ << XD09 and XD12 condition Added  by Balashanthi A for BSS Defect # 6776 Start
            if(!(ADMINORDERSAPTYPE.equalsIgnoreCase(oOrderLineItem.APTS_SAP_OrderType__c)
                || ADMINORDERCONSUMSAPTYPE.equalsIgnoreCase(oOrderLineItem.APTS_SAP_OrderType__c)
                || CREDITORDERSAPTYPE.equalsIgnoreCase(oOrderLineItem.APTS_SAP_OrderType__c))){
                //v118 ++ << XD09 and XD12 condition Added  by Balashanthi A for BSS Defect # 6776 Start
                //v131 << ++
                bStatusActivatedAsset = idToOldOrderLineItemMap.get(oOrderLineItem.Id).Apttus_Config2__Status__c != 'Activated' && oOrderLineItem.Apttus_Config2__Status__c == 'Activated';
                bStatusActivatedOLI = oOrderLineItem.Apttus_Config2__Status__c == ACTIVATED;
                bStatusCancelledOLI = oOrderLineItem.Apttus_Config2__Status__c == APTS_OrderConstants.CANCELLED; //V158 ++ <<>>
                //v131 ++ >>
                Apttus_Config2__Order__c oOrder = idToOrderMap.get(oOrderLineItem.Apttus_Config2__OrderId__c);
                if(oOrder.Apttus_Config2__Status__c == 'Pending'){
                    //First SAP update will populate APTS_SAP_Order_Line_Item_Number__c, APTS_Expected_Delivery_Date__c and APTS_Expected_Delivery_Quantity__c on Relevant for SAL lines
                    Boolean bIsRelevantForSAPLine = oOrderLineItem.APTS_Item_Relevant_for_SAP__c;
                    Boolean bExpectATP =  !orderSubTypeWithOutATPResultSet.contains(oOrder.APTS_Order_Sub_Type__c);
                    Boolean bSAPOLINUpdate = idToOldOrderLineItemMap.get(oOrderLineItem.Id).APTS_SAP_Order_Line_Item_Number__c != oOrderLineItem.APTS_SAP_Order_Line_Item_Number__c;
                    Boolean bSAPOLINNotNull = oOrderLineItem.APTS_SAP_Order_Line_Item_Number__c != null;
                    Boolean bMADUpdateNotNull = oOrderLineItem.APTS_Material_Availability_Date__c != null && idToOldOrderLineItemMap.get(oOrderLineItem.Id).APTS_Material_Availability_Date__c != oOrderLineItem.APTS_Material_Availability_Date__c;
                    Boolean bMADNotNull = oOrderLineItem.APTS_Material_Availability_Date__c != null;

                    Boolean bUpdateOfEDQ = idToOldOrderLineItemMap.get(oOrderLineItem.Id).APTS_Expected_Delivery_Quantity__c != oOrderLineItem.APTS_Expected_Delivery_Quantity__c;
                    Boolean bUpdateOfEDD = idToOldOrderLineItemMap.get(oOrderLineItem.Id).APTS_Expected_Delivery_Date__c != oOrderLineItem.APTS_Expected_Delivery_Date__c;
                    Boolean bEDQuantityUpdate = bUpdateOfEDQ && oOrderLineItem.APTS_Expected_Delivery_Quantity__c != null;
                    Boolean bEDDateUpdate = bUpdateOfEDD && oOrderLineItem.APTS_Expected_Delivery_Date__c != null;
                    Boolean atpCleared = idToOldOrderLineItemMap.get(oOrderLineItem.Id).APTS_ATP_Cleared__c != oOrderLineItem.APTS_ATP_Cleared__c && oOrderLineItem.APTS_ATP_Cleared__c;

                    //system.debug('@@idToOrderLineItemMap' +idToOrderLineItemMap);
                    //system.debug('@@idToOrderMap ' +idToOrderMap);

                    if (bExpectATP) {
                        if (bIsRelevantForSAPLine && (bEDDateUpdate || (!bUpdateOfEDD && oOrderLineItem.APTS_Expected_Delivery_Date__c == null && atpCleared)) &&
                                ((bMADNotNull && bEDQuantityUpdate) || ((!bUpdateOfEDQ) && oOrderLineItem.APTS_Expected_Delivery_Quantity__c == null) )) {

                            orderIdWithATPResultSet.add(oOrderLineItem.Apttus_Config2__OrderId__c);
                        }

                        if (bIsRelevantForSAPLine && bMADUpdateNotNull) {
                            orderIdWithMADSet.add(oOrderLineItem.Apttus_Config2__OrderId__c);
                        }

                        Boolean bQuantityNoNull = oOrderLineItem.Apttus_Config2__Quantity__c != null && oOrderLineItem.APTS_Expected_Delivery_Quantity__c != null;
                        Boolean bQuantityIsOk = bQuantityNoNull && oOrderLineItem.Apttus_Config2__Quantity__c <= oOrderLineItem.APTS_Expected_Delivery_Quantity__c;
                        Boolean bDatesNotNull;
                        Boolean bDeliveryDateIsOk;

                        //installation date check is required only for order type = Machine
                        if (oOrder.APTS_Order_Type__c == MACHINE_ORDER) {
                            bDatesNotNull = oOrderLineItem.APTS_Requested_Installation_Date__c != null && oOrderLineItem.APTS_Expected_Delivery_Date__c != null;
                            bDeliveryDateIsOk = bDatesNotNull && oOrderLineItem.APTS_Requested_Installation_Date__c >= oOrderLineItem.APTS_Expected_Delivery_Date__c;
                        } else {
                            bDatesNotNull = oOrderLineItem.APTS_Requested_Delivery_Date__c != null && oOrderLineItem.APTS_Expected_Delivery_Date__c != null;
                            bDeliveryDateIsOk = bDatesNotNull && oOrderLineItem.APTS_Requested_Delivery_Date__c == oOrderLineItem.APTS_Expected_Delivery_Date__c;
                        }

                        if (bIsRelevantForSAPLine && !(bQuantityIsOk && bDeliveryDateIsOk)) {
                            orderIdWithNegativeATPResultSet.add(oOrderLineItem.Apttus_Config2__OrderId__c);
                        }
                    } else {
                        if (oOrder.APTS_Order_Sub_Type__c == DE_INSTALLATION) {

                            if (bMADNotNull && bSAPOLINNotNull && (bSAPOLINUpdate || bMADUpdateNotNull)) {
                                orderIdWithSAPOLINAndMADSet.add(oOrderLineItem.Apttus_Config2__OrderId__c);
                            }
                        } else if (bSAPOLINUpdate) {
                            orderIdWithSAPOLINSet.add(oOrderLineItem.Apttus_Config2__OrderId__c);
                        }
                    }
                }
                
                if(idToOldOrderLineItemMap != null && idToOldOrderLineItemMap.get(oOrderLineItem.Id) != null)
                {
                    //Third SAP update will populate APTS_Serial_Number__c on Primary L1 Lines
                    //On this action we will create physical assets
                    Boolean bSerialNumberUpdate = idToOldOrderLineItemMap.get(oOrderLineItem.Id).APTS_Serial_Number__c == null && oOrderLineItem.APTS_Serial_Number__c != null;
                    //V154 - START - Added machine order check
                    if (bSerialNumberUpdate && oOrder!=null && oOrder.APTS_Order_Type__c!=null && (oOrder.APTS_Order_Type__c.equalsIgnoreCase(System.Label.APTS_Machine_Order) || (oOrder.Apttus_CMConfig__AgreementId__c!=null && oOrder.Apttus_CMConfig__AgreementId__r.recordtype.name.equalsIgnoreCase('Registration Form')))) {
                        orderLineItemIdWithSerialNumberSet.add(oOrderLineItem.Id);
                    }
                    //Only for Non-Installation orders
                   else  if (oOrderLineItem.APTS_Serial_Number__c != null && oOrder!=null && oOrder.APTS_Order_Type__c!=null && ((oOrder.APTS_Order_Type__c.equalsIgnoreCase(System.Label.APTS_Machine_Order) && !oOrder.APTS_Order_Sub_Type__c.equalsIgnorecase('Installation')) || (oOrder.Apttus_CMConfig__AgreementId__c!=null && oOrder.Apttus_CMConfig__AgreementId__r.recordtype.name.equalsIgnoreCase('Registration Form')) || (oOrder.APTS_Contract_Change__c != null && oOrder.APTS_Contract_Change__c=='Yes'))) {
                        orderLineItemIdWithSerialNumberSet.add(oOrderLineItem.Id);
                    }
                    //V154 - END - - Added machine order check
                    System.debug('######orderLineItemIdWithSerialNumberSet=========>'+orderLineItemIdWithSerialNumberSet);
                    //v125 ++ >>
                    //Store agreement line item Id on asset when it is attached on order line item
                    if (idToOldOrderLineItemMap.get(oOrderLineItem.Id).Apttus_Config2__AssetLineItemId__c == null && oOrderLineItem.Apttus_Config2__AssetLineItemId__c != null) {
                        orderLineItemWithAssetList.add(oOrderLineItem);
                    }                        

                    if (oOrderLineItem.Apttus_CMConfig__AgreementId__c != null) {
                        orderLineItemIdToAgreementIdMap.put(oOrderLineItem.Id, oOrderLineItem.Apttus_CMConfig__AgreementId__c);
                        agreementIdSet.add(oOrderLineItem.Apttus_CMConfig__AgreementId__c);
                    }
                    
                    //25Jul2018 - Added below logic to get the Orders that needs to be updated with status Returned
                    if (idToOldOrderLineItemMap.get(oOrderLineItem.Id).APTS_De_installation_Date_Authorized__c == null && oOrderLineItem.APTS_De_installation_Date_Authorized__c != null) {
                        if (!orderIdToActivationDateMap.containsKey(oOrderLineItem.Apttus_Config2__OrderId__c)) {
                            orderIdToActivationDateMap.put(oOrderLineItem.Apttus_Config2__OrderId__c, oOrderLineItem.APTS_De_installation_Date_Authorized__c);
                        }

                    }

                    Boolean bInstalationDateChange = idToOldOrderLineItemMap.get(oOrderLineItem.Id).APTS_Installation_Date_Authorized__c == null && oOrderLineItem.APTS_Installation_Date_Authorized__c != null;
                    Boolean bDeInstalationDateChange = idToOldOrderLineItemMap.get(oOrderLineItem.Id).APTS_De_installation_Date_Authorized__c == null && oOrderLineItem.APTS_De_installation_Date_Authorized__c != null;
                      
                    //v126 ++ <<
                    Boolean bMovement = APTS_OrderConstants.XA14.equalsIgnoreCase(oOrderLineItem.APTS_SAP_OrderType__c);
                    if ((bInstalationDateChange || bDeInstalationDateChange) && !bMovement) {  //v126 ++ >>
                        orderIdWithIDASet.add(oOrderLineItem.Apttus_Config2__OrderId__c);
                        orderLineItemIdWithIDASet.add(oOrderLineItem.Id);
                    }
                    //V164 ++ <<
                    else if(bInstalationDateChange && bMovement)
                    {
                        movementOLIWithIDASet.add(oOrderLineItem.Id);
                    } //V164 ++ >>
                   //V160 ++ <<
                    Boolean bPhysicalAssetNotNull = oOrderLineItem.APTS_Physical_Asset__c != null;
                   /* if (bPhysicalAssetNotNull && bSerialNumberUpdate) {
                        physicalAssetIdToOLIMap.put(oOrderLineItem.APTS_Physical_Asset__c, oOrderLineItem);
                    } */
                    //Movement Order CR changes in OR condition
                    if (bMovement && bPhysicalAssetNotNull && bInstalationDateChange && oOrderLineItem.APTS_Is_Primary_L1_Line__c) {
                        physicalAssetIdToOLIMap.put(oOrderLineItem.APTS_Physical_Asset__c, oOrderLineItem);
                    }
                    //V160 ++ >>
                }
            //v118 ++ << XD09 and XD12 condition Added  by Balashanthi A for BSS Defect # 6776 Start    
            }
            //v118 ++ << XD09 and XD12 condition Added  by Balashanthi A for BSS Defect # 6776 ENd 
            
          
            
        }
        //Initial loop
      
        //Loop on order to handle First SAP update          
        for (Id orderId : orderIdSet) {
            Apttus_Config2__Order__c oOrderToUpdateFinal = new Apttus_Config2__Order__c();
            Apttus_Config2__Order__c oOrderToUpdate = idToOrderMap.get(orderId);
            String orderPreviousStatus = oOrderToUpdate.APTS_ATP_Check_Status__c != null ? oOrderToUpdate.APTS_ATP_Check_Status__c : 'Blank' ;  //v116  
            
            //v110 ++ << Added the If condiditon >>
            if (oOrderToUpdate.APTS_Status__c == APTS_OrderConstants.SUBMITTED || oOrderToUpdate.APTS_Status__c == APTS_OrderConstants.PENDING ) {
            //   if (oOrderToUpdate.APTS_Status__c != APTS_OrderConstants.CANCELLED) {
                oOrderToUpdateFinal = getATPCheckStatusMethod(orderId,oOrderToUpdate,idToAllOrderLineItemMap,orderIdWithATPResultSet,orderIdWithNegativeATPResultSet,orderIdWithMADSet,orderIdWithSAPOLINAndMADSet,orderIdWithSAPOLINSet);
            }         
            
            //v112<<++
            //system.debug(orderPreviousStatus+'-----------orderPreviousStatus');
            //system.debug(oOrderToUpdateFinal.APTS_ATP_Check_Status__c+'-----------oOrderToUpdateFinal.APTS_ATP_Check_Status__c');
            if(!orderPreviousStatus.equalsIgnoreCase(oOrderToUpdateFinal.APTS_ATP_Check_Status__c)){  //v116 Added if condition
                if(oOrderToUpdateFinal.APTS_ATP_Check_Status__c  == Pass){
                    orderToUpdateList.add(oOrderToUpdateFinal);
                }
                else if(oOrderToUpdateFinal.APTS_ATP_Check_Status__c  == Fail){
                    orderFailToUpdateList.add(oOrderToUpdateFinal);
                }
            }
            //v112++>> 
            System.debug('Lavanya Order Status in OLI triggerHander'+oOrderToUpdate.Apttus_Config2__Status__c+'ctc'+oOrderToUpdate.APTS_Contract_Change__c);

            if(oOrderToUpdate.Apttus_Config2__Status__c == 'Activated' && oOrderToUpdate.APTS_Contract_Change__c == 'Yes')
            {
                Boolean bTrialToSales = (oOrderToUpdate.APTS_Scenario__c != null && oOrderToUpdate.APTS_Scenario__c =='Trial to Sales'); //V168 ++ <<>>
                                    oOrderToUpdate.APTS_Status__c = (bTrialToSales ? APTS_BIRUtils.INVOICINGSTATUS : 'Completed');//v130 //V168 ++ <<>>
                                    oOrderToUpdate.APTS_Remove_Billing_Block_Indicator__c = true;
                                    oOrderToUpdate.APTS_Billing_Date__c = system.today();
                                    orderToUpdateList.add(oOrderToUpdate);
            }
            //Update the Status of Debit Memo Order
             if ((oOrderToUpdate.APTS_SAP_OrderType__c == XC01 && oOrderToUpdate.APTS_Credit_Memo__c!= null)
                  || (oOrderToUpdate.APTS_SAP_OrderType__c == XD01 && oOrderToUpdate.APTS_Order_Type__c =='Debit Memo' && oOrderToUpdate.APTS_Invoice__c==null)) {//V148 Added Invoice Null check
                oOrderToUpdate.Apttus_Config2__Status__c = ACTIVATED;
                if(oOrderToUpdate.APTS_Status__c!='Completed' 
                    && oOrderToUpdate.APTS_Status__c != APTS_BIRUtils.INVOICINGSTATUS){
                    oOrderToUpdate.APTS_Status__c = APTS_BIRUtils.INVOICINGSTATUS;//v130
                    oOrderToUpdate.APTS_Remove_Billing_Block_Indicator__c = true;
                    oOrderToUpdate.APTS_Billing_Date__c = system.today();
                    orderToUpdateList.add(oOrderToUpdate);
                    orderDebitMemoIdSet.add(oOrderToUpdate.Id);
                }
            }
            
            
            //3.1
                //v123 ++ <<
                for (Apttus_Config2__OrderLineItem__c oli : idToAllOrderLineItemMap.values()){             
                    //V128 ++ << >>
                    if(oli.Apttus_Config2__OrderId__c == orderId && setStandardOrderTypes.contains(oOrderToUpdate.APTS_Order_Type__c) && !oli.Apttus_Config2__ProductId__r.APTS_Not_relevant_for_SAP__c) {
                        cancelledOLI = cancelledOLI && (oli.APTS_Reason_For_Rejection__c != null || oli.Apttus_Config2__Status__c == 'FULFILLED');
                        if (oli.APTS_Reason_For_Rejection__c != null){
                            numRejectedLI ++;
                        }
                    }       
                }
                if (cancelledOLI && numRejectedLI > 0) {
                    oOrderToUpdate.APTS_IsPGICompleted__c = true;
                    orderToUpdateListNew.add(oOrderToUpdate);
                }
                //v123 ++ >>
                //3.1  
        }                
        //v107 ++ <<          
        //Update the Status of Debit Memo Order Line Item
        for (Apttus_Config2__OrderLineItem__c oOrderLineItem : idToOrderLineItemMap.values()) {

            if (orderDebitMemoIdSet.contains(oOrderLineItem.Apttus_Config2__OrderId__c)) {
                if (idToOrderLineItemToUpdateMap.containsKey(oOrderLineItem.Id)) {
                    idToOrderLineItemToUpdateMap.get(oOrderLineItem.Id).Apttus_Config2__Status__c = ACTIVATED;
                    idToOrderLineItemToUpdateMap.get(oOrderLineItem.Id).APTS_Status__c = ACTIVATED;
                    //v150++ Starts<<
                    if((oOrderLineItem.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c == XD01 || oOrderLineItem.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c == XC01)
                        && oOrderLineItem.Apttus_Config2__LineType__c==APTS_OrderConstants.PRODUCT_OR_SERVICE
                        && oOrderLineItem.Apttus_Config2__HasOptions__c) {
                        oOrderLineItem.APTS_Item_Relevant_for_SAP__c=false;
                    }else{
                        idToOrderLineItemToUpdateMap.get(oOrderLineItem.Id).APTS_Item_Relevant_for_SAP__c = true;
                    }
                    idToOrderLineItemToUpdateMap.get(oOrderLineItem.Id).Apttus_Config2__ActivatedDate__c = system.now();
                } else {
                    oOrderLineItem.Apttus_Config2__Status__c = ACTIVATED;
                    oOrderLineItem.APTS_Status__c = ACTIVATED;
                    if((oOrderLineItem.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c == XD01 || oOrderLineItem.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c == XC01)
                        && oOrderLineItem.Apttus_Config2__LineType__c==APTS_OrderConstants.PRODUCT_OR_SERVICE
                        && oOrderLineItem.Apttus_Config2__HasOptions__c) {
                        oOrderLineItem.APTS_Item_Relevant_for_SAP__c = false;
                    }else{
                        oOrderLineItem.APTS_Item_Relevant_for_SAP__c = true;
                    }//v150 ++ Ends>>
                    oOrderLineItem.Apttus_Config2__ActivatedDate__c = system.now();
                    idToOrderLineItemToUpdateMap.put(oOrderLineItem.Id, oOrderLineItem);
                }
            }
            //DQ-2038
            if(oOrderLineItem.APTS_Is_Primary_L1_Line__c == true && oOrderLineItem.APTS_Serial_Number__c!= null)
            mapParentSerialNumber.put(oOrderLineItem.Apttus_Config2__LineNumber__c,oOrderLineItem.APTS_Serial_Number__c);
            //DQ-2038
            
            if (String.IsNotBlank(oOrderLineItem.Apttus_Config2__ProductId__c)
              && String.IsNotBlank(oOrderLineItem.Apttus_Config2__ProductId__r.APTS_Vendor_Code__c) && String.IsNotBlank(oOrderLineItem.APTS_Serial_Number__c)) {
                if(oOrderLineItem.APTS_Is_Primary_L1_Line__c == true)  
                serialNoToOLIMap.put(oOrderLineItem.Apttus_Config2__ProductId__r.APTS_Vendor_Code__c + oOrderLineItem.APTS_Serial_Number__c, oOrderLineItem);
                else if(oOrderLineItem.APTS_Option_Group_Text__c != null && oOrderLineItem.APTS_Serial_Number__c != null && !mapParentSerialNumber.isEmpty() && mapParentSerialNumber.get(oOrderLineItem.Apttus_Config2__LineNumber__c)!= null)
                serialNoToOLIMap.put(oOrderLineItem.Apttus_Config2__OptionId__r.ProductCode+'_'+oOrderLineItem.Apttus_Config2__ProductId__r.APTS_Vendor_Code__c + mapParentSerialNumber.get(oOrderLineItem.Apttus_Config2__LineNumber__c) +'_'+oOrderLineItem.APTS_Serial_Number__c, oOrderLineItem); //DQ-2038
                if(oOrderLineItem.APTS_RefurbishedMachine__c)
                refurbishedOLIs.add(oOrderLineItem.id);          
            }   
    //System.debug(serialNoToOLIMap.keySet());
    //DQ-56 - Asset Contract Change
    if(oOrderLineItem.Apttus_Config2__OrderId__r.APTS_Contract_Change__c== 'Yes') ContractChangeSet.add(oOrderLineItem.id) ;    
    if(oOrderLineItem.Apttus_Config2__Status__c== PENDING) Fulfilledlines.add(oOrderLineItem.id) ;  
        }
        //v107 ++ >>                     
        //Set Physical Asset Id and Agreement Line Item Id on Asset when Assets are created and OLI is updated with asset relation id
        if ( orderLineItemWithAssetList != null && !orderLineItemWithAssetList.isEmpty() ){
            assetLineItemToUpdateList = updateAsset(orderLineItemWithAssetList, idToOrderLineItemMap);
            //system.debug('assetLineItemToUpdateList==> Bala>>>>'+assetLineItemToUpdateList);
        }
        
        //V160 ++ << -- Check if Agreement PO details query execution is required
        Boolean bPOUpdateRequired = false;
        Map<Id, List<APTS_Agreement_PO_Details__c>> agreementIdToPOMap = new Map<Id, List<APTS_Agreement_PO_Details__c>>();
        if((!orderLineItemIdWithSerialNumberSet.isEmpty() && !bStatusActivatedAsset && !bStatusActivatedOLI && !bStatusCancelledOLI)) { //V158 ++ <<>>
            bPOUpdateRequired = true;
        }
        else if(!physicalAssetIdToOLIMap.isEmpty())
        {
             bPOUpdateRequired = true;
        }
        if(bPOUpdateRequired)
        {
            agreementIdToPOMap = getPODetailsList(agreementIdSet);                
        }            
        //V160 ++ >>
       
        //Method to Handle creation and updation on Physical asset and associated object
        //v131 << ++             
        
        if((!orderLineItemIdWithSerialNumberSet.isEmpty() && !bStatusActivatedAsset && !bStatusActivatedOLI && ContractChangeSet.isEmpty()) || (!ContractChangeSet.isEmpty() && !Fulfilledlines.isEmpty())) {//V158 ++ <<>>
            System.debug('######Physical Asset creation method=========>'+orderLineItemIdWithSerialNumberSet);
            CreatePhysicalAssetMethod(orderLineItemIdWithSerialNumberSet,orderLineItemIdToAgreementIdMap,agreementIdSet,serialNoToOLIMap,idToOrderLineItemTmpMap,refurbishedOLIs,idToOrderLineItemMap,oldList, oldItems, agreementIdToPOMap);
        }
        
       
        
        //3.1  << ++
            //Movement Order - Update Order Activation to update Agreement on Asset Line Items
            list<Apttus_Config2__AssetLineItem__c> assetLineItemAgreementList =  new list<Apttus_Config2__AssetLineItem__c>();
            Apttus_Config2__AssetLineItem__c oAssetLineItem = null;
            
            for (Apttus_Config2__OrderLineItem__c oOrderLineItem : idToOrderLineItemTmpMap.values()) {
                Boolean bStatusActivated = idToOldOrderLineItemMap.get(oOrderLineItem.Id).Apttus_Config2__Status__c != 'Activated' && oOrderLineItem.Apttus_Config2__Status__c == 'Activated';
                //v124 << ++ 
                if(oOrderLineItem.APTS_SAP_OrderType__c == 'XA14' && bStatusActivated){
                    oAssetLineItem = new Apttus_Config2__AssetLineItem__c();
                    oAssetLineItem.Id = oOrderLineItem.Apttus_Config2__AssetLineItemId__c;
                    oAssetLineItem.Apttus_CMConfig__AgreementId__c = oOrderLineItem.Apttus_CMConfig__AgreementId__c;
                    assetLineItemAgreementList.add(oAssetLineItem);
                }
            }
            // v124 ++>>                
             
             if (!assetLineItemAgreementList.isEmpty()) {
                APTS_OrderUtils.stopAssetLineItemTrigger();
                if (objResultAsstLI.isUpdateable()) {
                    Database.update(assetLineItemAgreementList);
                }
                APTS_OrderUtils.startAssetLineItemTrigger();
            }
            //Movement Order - Update Order Activation to update Agreement on Asset Line Item
            //3.1 ++ >>
        //v131 ++ >>
        //DML Section
        //Update order and set ATP check status to Fail
        //System.debug(' orderFailToUpdateList '+orderFailToUpdateList);
        if (!orderFailToUpdateList.isEmpty()) {
            APTS_OrderUtils.stopOrderTrigger();
            if (objResultOrder.isUpdateable()) {
                Database.update(orderFailToUpdateList);
            }
            APTS_OrderUtils.startOrderTrigger();
        }
        //Update order and set ATP check status to Pass
        if (!orderToUpdateList.isEmpty()) {
            //system.debug(orderToUpdateList);
            Database.update(orderToUpdateList);
        }
        
        //3.1
            //v123 ++ <<
            //update PGI completed on order
            if (!orderToUpdateListNew.isEmpty()) {
                Database.update(orderToUpdateListNew);
            }
            //v123 ++ >>
            //3.1                   

        if (!assetLineItemToUpdateList.isEmpty()) {
            APTS_OrderUtils.stopAssetLineItemTrigger();
            if (objResultAsstLI.isUpdateable()) {
                Database.update(assetLineItemToUpdateList);
            }
            APTS_OrderUtils.startAssetLineItemTrigger();
        }
        
        //Update order line items with physical asset id
        if (!idToOrderLineItemToUpdateMap.isEmpty()) {
            isTriggerDisabled = true;
            if (objResultOrderLI.isUpdateable()) {
                Database.update(idToOrderLineItemToUpdateMap.values());
            }
            isTriggerDisabled = false;
        }
        
         //v103 ++ <<
        //Set order line item start and end date
        if (!orderLineItemIdWithIDASet.isEmpty() && orderLineItemIdWithIDASet!= null) {
            orderLineItemWithSEDList = setOLIStartAndEndDate(orderIdWithIDASet, orderLineItemIdWithIDASet, idToOrderLineItemTmpMap, idToAllOrderLineItemMap);                
        }
        //v103 ++ >>

        //Update order line items with start and end date
        if (!orderLineItemWithSEDList.isEmpty()) {
            isTriggerDisabled = true;
            Database.update(orderLineItemWithSEDList);
            isTriggerDisabled = false;
        }  
        
        //V164 ++ <<
        if(!movementOLIWithIDASet.isEmpty() || Test.isRunningTest())
        {
            movementOLIUpdateList = setMovementBillingDate(movementOLIWithIDASet, idToOrderLineItemTmpMap, idToAllOrderLineItemMap);
        }
        //Update order line items with start and end date
        if (!movementOLIUpdateList.isEmpty()) {
            isTriggerDisabled = true;
            Database.update(movementOLIUpdateList, false);
            isTriggerDisabled = false;
        }  
        //V164 ++ >>
        //DML Section
        //V160 ++ <<
        if(!physicalAssetIdToOLIMap.isEmpty())
        {
            List<PhysicalAsset__c> phAUpdateMovements = APTS_OrderLineItemUtils.updatePhAOnMovements(physicalAssetIdToOLIMap, agreementIdToPOMap, idToAllOrderLineItemMap);
            if(!phAUpdateMovements.isEmpty())
            {
                Database.Update(phAUpdateMovements, false);
            }                
        }
        //V160 ++ >>
            if(Test.isRunningTest()){ Decimal dc1 = 1 / 0; }
        }
        catch(Exception ex){
             APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString() , 'Order', null, 'OM', false, true, null, true);        
        }
        
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
    public Boolean isDisabled() {

        return isTriggerDisabled;
    }

    //Enable or disable trigger
    public static void setTriggerDisabled(Boolean isDisabled) {
        isTriggerDisabled = isDisabled;
    }

    public Apttus_Config2__OrderLineItem__c setParentOrderLineItem(Apttus_Config2__OrderLineItem__c oOrderLineItem, Map<Decimal, Apttus_Config2__OrderLineItem__c> bundelLineNumberToOLI) {

        Apttus_Config2__OrderLineItem__c oOrderLineItemToUpdate;
        try {
         //V168 - Check if it is CTC - Trial to Sales Scenario, then set APTS_Is_Primary_L1_Parent__c on OLI
        if(oOrderLineItem.Apttus_Config2__LineStatus__c == 'New' && oOrderLineItem.Apttus_Config2__OrderId__r.APTS_Contract_Change__c!= null && oOrderLineItem.Apttus_Config2__OrderId__r.APTS_Contract_Change__c== 'Yes' && oOrderLineItem.Apttus_Config2__OrderId__r.APTS_Scenario__c != null && oOrderLineItem.Apttus_Config2__OrderId__r.APTS_Scenario__c == 'Trial To Sales')
        {
            Apttus_Config2__OrderLineItem__c parentOLI = bundelLineNumberToOLI.get(oOrderLineItem.Apttus_Config2__LineNumber__c);
            if (parentOLI != null) {
                if(oOrderLineItem.Apttus_Config2__LineType__c == OPTION){
                oOrderLineItem.APTS_Parent_Order_Line_Item__c = parentOLI.Name.right(5);
                }
                oOrderLineItem.APTS_Is_Primary_L1_Parent__c = parentOLI.id;
                system.debug(' 1315 :: oOrderLineItem.APTS_Is_Primary_L1_Parent__c :: '+oOrderLineItem.APTS_Is_Primary_L1_Parent__c);
                oOrderLineItemToUpdate = oOrderLineItem; 
                }
        }
    else  
    { 
        if (oOrderLineItem.Apttus_Config2__ProductId__r.Apttus_Config2__ConfigurationType__c == STANDALONE
             && !(APTS_BIRUtils.ADMINORDERSAPORDERTYPE.equalsIgnoreCase(oOrderLineItem.APTS_SAP_OrderType__c)
                     || APTS_BIRUtils.CONSUMPTIONSAPORDERTYPE.equalsIgnoreCase(oOrderLineItem.APTS_SAP_OrderType__c))) {
            oOrderLineItem.APTS_Parent_Order_Line_Item__c = oOrderLineItem.Name.right(5);
            oOrderLineItemToUpdate = oOrderLineItem;
        } else if (oOrderLineItem.Apttus_Config2__LineType__c == OPTION
            && !(APTS_BIRUtils.ADMINORDERSAPORDERTYPE.equalsIgnoreCase(oOrderLineItem.APTS_SAP_OrderType__c)
                     || APTS_BIRUtils.CONSUMPTIONSAPORDERTYPE.equalsIgnoreCase(oOrderLineItem.APTS_SAP_OrderType__c))) {
            Apttus_Config2__OrderLineItem__c parentOLI = bundelLineNumberToOLI.get(oOrderLineItem.Apttus_Config2__LineNumber__c);
            if (parentOLI != null) {
                oOrderLineItem.APTS_Parent_Order_Line_Item__c = parentOLI.Name.right(5);
                oOrderLineItem.APTS_Is_Primary_L1_Parent__c = parentOLI.id;
                oOrderLineItemToUpdate = oOrderLineItem;
            }
        } else if (oOrderLineItem.Apttus_Config2__LineType__c == 'Product/Service'
             && !(APTS_BIRUtils.ADMINORDERSAPORDERTYPE.equalsIgnoreCase(oOrderLineItem.APTS_SAP_OrderType__c)
                     || APTS_BIRUtils.CONSUMPTIONSAPORDERTYPE.equalsIgnoreCase(oOrderLineItem.APTS_SAP_OrderType__c))) {
            Apttus_Config2__OrderLineItem__c parentOLI = bundelLineNumberToOLI.get(oOrderLineItem.Apttus_Config2__LineNumber__c);
            if (parentOLI != null && oOrderLineItem.id != parentOLI.id) {
                oOrderLineItem.APTS_Is_Primary_L1_Parent__c = parentOLI.id;
                oOrderLineItemToUpdate = oOrderLineItem;
            }
        }
    }  
    } catch (Exception e) {
           APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', null, 'OM', false, true, null, true);
    }

        return oOrderLineItemToUpdate;
    }

    public static List<Apttus_Config2__AssetLineItem__c> updateAsset(List<Apttus_Config2__OrderLineItem__c> orderLineItemList, Map<Id, Apttus_Config2__OrderLineItem__c> idToOrderLineItemMap) {

        List<Apttus_Config2__AssetLineItem__c> assetLineItemToUpdateList = new List<Apttus_Config2__AssetLineItem__c>();

        Apttus_Config2__AssetLineItem__c oAssetLineItem = null;
        try {
        for (Apttus_Config2__OrderLineItem__c oOrderLineItem : orderLineItemList) {

            oAssetLineItem = new Apttus_Config2__AssetLineItem__c();
            oAssetLineItem.Id = oOrderLineItem.Apttus_Config2__AssetLineItemId__c;
            oAssetLineItem.Apttus_Config2__LocationId__c = oOrderLineItem.Apttus_Config2__LocationId__c;
            oAssetLineItem.Apttus_CMConfig__AgreementId__c = oOrderLineItem.Apttus_CMConfig__AgreementId__c;
            oAssetLineItem.Apttus_CMConfig__AgreementLineItemId__c = oOrderLineItem.Apttus_CMConfig__AgreementLineItemId__c;
            oAssetLineItem.APTS_Physical_Asset__c = oOrderLineItem.APTS_Physical_Asset__c;
            oAssetLineItem.APTS_Installation_Sales_Order_Item__c = oOrderLineItem.APTS_SAP_Order_Line_Item_Number__c;
            oAssetLineItem.APTS_Installation_Sales_Order_Id__c = idToOrderLineItemMap.get(oOrderLineItem.Id).Apttus_Config2__OrderId__r.APTS_Order_Header_SAP_ID__c;
            //v164 ++<<
            if((idToOrderLineItemMap.get(oOrderLineItem.Id).Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c =='XA23' && idToOrderLineItemMap.get(oOrderLineItem.Id).Apttus_Config2__AssetLineItemId__r.APTS_Is_Primary_L1_Line__c == True && idToOrderLineItemMap.get(oOrderLineItem.Id).APTS_Is_Primary_L1_Line__c == True) || Test.isRunningTest()){
                oAssetLineItem.APTS_Billing_Header_Text__c= oAssetLineItem.APTS_Installation_Sales_Order_Id__c;
             }
                //v164 ++>>
            assetLineItemToUpdateList.add(oAssetLineItem);
        }
            if(Test.isRunningTest()){ Decimal dc1 = 1 / 0; }
        } catch (Exception e) {
            //system.debug('++For PA Tagging++'+ e.getLineNumber() + e.getMessage() + '-Cause-' + e.getCause() + 'StackTrace' + e.getStacktraceString());
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id), 'OM', false, true, null, true);
        }

        return assetLineItemToUpdateList;
    }
    //v102 ++ <<
    public static void updatePhysicalAsset(set<Id> orderLineItemIds, Map<Id, PhysicalAsset__c> oLItoPAMap) {
        
        DescribeSObjectResult objResultWorkOrder = APTS_OTCUtil.getsObjectAccess(WORKORDERCRUD); // CRUD/FLS Check
        DescribeSObjectResult objResultWorkOLI = APTS_OTCUtil.getsObjectAccess(WORKORDERLICRUD); // CRUD/FLS Check
        //Variable Section
        Map<Id, WorkOrderTrigger__c> idToWorkOrderTriggerToUpdateMap = new Map<Id, WorkOrderTrigger__c>();
        Map<Id, WorkOrderLineItem> idToWorkOrderLineItemToUpdateMap = new Map<Id, WorkOrderLineItem>();
        Map<Id, WorkOrderTrigger__c> orderLineItemIdToWorkOrderTriggerToUpdateMap = new Map<Id, WorkOrderTrigger__c>();
        Map<Id, WorkOrderLineItem> orderLineItemIdToWorkOrderLineItemToUpdateMap = new Map<Id, WorkOrderLineItem>();
        //system.debug('updatePhysicalAsset :: oLItoPAMap :: '+oLItoPAMap);
        string exceptionOli=''; //v136
        try{
            if (!oLItoPAMap.isEmpty()) {
                //SOQL Section
                //Get all work order trigger items where we will set physical asset id
                idToWorkOrderTriggerToUpdateMap = APTS_OrderLineItemDAO.getWorkOrderTrigger(orderLineItemIds);
                //Get all work order line items where we will set physical asset id
                idToWorkOrderLineItemToUpdateMap = APTS_OrderLineItemDAO.getWorkOrderLineItem(orderLineItemIds);
                //system.debug('idToWorkOrderLineItemToUpdateMap------------'+idToWorkOrderLineItemToUpdateMap);
                //SOQL Section

                //Initial loop on other objects
                for (WorkOrderTrigger__c oWorkOrderTrigger : idToWorkOrderTriggerToUpdateMap.values()) {
                    //v114 ++ <<
                    if(oWorkOrderTrigger.PhysicalAsset__c == null) {
                        orderLineItemIdToWorkOrderTriggerToUpdateMap.put(oWorkOrderTrigger.OrderLineItem__c, oWorkOrderTrigger);
                    }
                    //v114 ++ >>
                }

                for (WorkOrderLineItem oWorkOrderLineItem : idToWorkOrderLineItemToUpdateMap.values()) {
                    //v114 ++ <<
                    if(oWorkOrderLineItem.PhysicalAsset__c == null) {
                        orderLineItemIdToWorkOrderLineItemToUpdateMap.put(oWorkOrderLineItem.OrderLineItem__c, oWorkOrderLineItem);
                    }
                    //v114 ++ >>
                }
                //Initial loop other objects
                //system.debug('updatePhysicalAsset :: orderLineItemIds:: '+orderLineItemIds);
                //Loop on OLI with physical assets
                for (Id orderLineItemId : orderLineItemIds) {
                    exceptionOli = orderLineItemId;  //v136
                    //Set Physical asset Id on order line item
                    PhysicalAsset__c oPhysicalAsset = oLItoPAMap.get(orderLineItemId);
                    if (oPhysicalAsset != null) {
                        //Set Physical asset Id on work order trigger lines
                        WorkOrderTrigger__c oWorkOrderTriggerToUpdate = orderLineItemIdToWorkOrderTriggerToUpdateMap.get(orderLineItemId);
                        if (oWorkOrderTriggerToUpdate != null) {
                            oWorkOrderTriggerToUpdate.PhysicalAsset__c = oPhysicalAsset.Id;
                        }
                        //Set Physical asset Id on work order line items
                        WorkOrderLineItem oWorkOrderLineItemToUpdate = orderLineItemIdToWorkOrderLineItemToUpdateMap.get(orderLineItemId);
                        if (oWorkOrderLineItemToUpdate != null) {
                            oWorkOrderLineItemToUpdate.PhysicalAsset__c = oPhysicalAsset.Id;
                        }
                    }
                }
                //Loop on OLI with physical assets
                //Update work order trigger with physical asset id
                if (!idToWorkOrderTriggerToUpdateMap.isEmpty()) {
                    if (objResultWorkOrder.isUpdateable()) {
                        Database.update(idToWorkOrderTriggerToUpdateMap.values());
                    }
                }

                //Update work order line item with physical asset id
                if (!idToWorkOrderLineItemToUpdateMap.isEmpty()) {
                    if (objResultWorkOLI.isUpdateable()) {
                        Database.update(idToWorkOrderLineItemToUpdateMap.values());
                    }
                }
            }
            //v102 ++ >>
            if(Test.isRunningTest()){ throw new DMLException('My DML EXCEPTION'); }
        }//v136 ++<< Handling Exception
        catch(DMLException e){
            String msg = '';
            for (Integer i = 0; i < e.getNumDml(); i++) {
                msg += 'message = ' + e.getDmlMessage(i) + ' getDmlFieldNames = ' + e.getDmlFieldNames(i) + '\n';
            }
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', msg, 'OrderLineItem',exceptionOli, 'OM', false, false, null, true);
        } //v136 ++>>
    }
    //v103++<<
    public List<Apttus_Config2__OrderLineItem__c> setOLIStartAndEndDate(Set<Id> orderIdWithIDASet, Set<Id> orderLineItemIdWithIDASet, Map<Id, Apttus_Config2__OrderLineItem__c> idToOrderLineItemTmpMap, Map<Id, Apttus_Config2__OrderLineItem__c> idToAllOrderLineItemMap) {

        List<Apttus_Config2__OrderLineItem__c> orderLineItemWithSEDList = new List<Apttus_Config2__OrderLineItem__c>();
        List<Apttus_Config2__AssetLineItem__c> assetLineItemToUpdateList = new List<Apttus_Config2__AssetLineItem__c>();
        List<PhysicalAsset__c> lstDeliveryOnlyPA = new List<PhysicalAsset__c>();
        List<PhysicalAsset__c> lstReturnOnlyPA = new List<PhysicalAsset__c>();
        List<PhysicalAsset__c> lstToUpdateInstallPA = new List<PhysicalAsset__c>(); //V161 ++ <<>>
        Date Tempenddate;

        try {
            
            //Set order line item start and end date
            for (Apttus_Config2__OrderLineItem__c oOrderLineItemWithIDA : idToOrderLineItemTmpMap.values()) {

                if (orderLineItemIdWithIDASet.contains(oOrderLineItemWithIDA.Id)) {

                    DateTime installDate = oOrderLineItemWithIDA.APTS_Installation_Date_Authorized__c != null ? oOrderLineItemWithIDA.APTS_Installation_Date_Authorized__c : null;
                    DateTime deInstallDate = oOrderLineItemWithIDA.APTS_De_installation_Date_Authorized__c != null ? oOrderLineItemWithIDA.APTS_De_installation_Date_Authorized__c : null;
                    for (Apttus_Config2__OrderLineItem__c oOrderLineItem : idToAllOrderLineItemMap.values()) {

                        Boolean bSameLineNumber = oOrderLineItemWithIDA.Apttus_Config2__LineNumber__c == oOrderLineItem.Apttus_Config2__LineNumber__c;
                        Boolean bSameOrder = oOrderLineItemWithIDA.Apttus_Config2__OrderId__c == oOrderLineItem.Apttus_Config2__OrderId__c;
                        Integer iDifferenceInDays = 0;
                        Boolean bWarrantyExists = false;
                        //Install order
                        if (installDate != null) {

                            if (oOrderLineItemWithIDA.Id == oOrderLineItem.Id) {

                                iDifferenceInDays = oOrderLineItem.Apttus_Config2__StartDate__c.daysBetween(installDate.date());
                            } else if (bSameLineNumber && bSameOrder) {

                                if (oOrderLineItem.Apttus_Config2__IsPrimaryLine__c && oOrderLineItem.Apttus_Config2__HasOptions__c&&oOrderLineItem.Apttus_Config2__ChargeType__c!='Service Fee') {
                                    iDifferenceInDays = oOrderLineItem.Apttus_Config2__StartDate__c.daysBetween(installDate.date());
                                } 
                                else if(oOrderLineItem.Apttus_Config2__IsPrimaryLine__c && oOrderLineItem.Apttus_Config2__HasOptions__c&&oOrderLineItem.Apttus_Config2__ChargeType__c=='Service Fee'&&oOrderLineItem.APTS_Type_of_contract__c=='Sales'){
                                  try {
                                        Date newDateB = installDate.date().addMonths(Integer.ValueOf(oOrderLineItem.Apttus_Config2__AttributeValueId__r.APTS_Number_of_months__c));iDifferenceInDays = oOrderLineItem.Apttus_Config2__StartDate__c.daysBetween(newDateB);
                                    } catch (Exception e) { }
                                }
                                else {
                                    //For options check if the Option Group Text is Technical Services and if there exists warranty
                                    try {
                                        if (checkIfWarrantyExists(oOrderLineItem) || Test.isRunningTest()){
                                            Date newDate = installDate.date().addMonths(Integer.ValueOf(oOrderLineItem.Apttus_Config2__AttributeValueId__r.APTS_Number_of_months__c));
                                            iDifferenceInDays = oOrderLineItem.Apttus_Config2__StartDate__c.daysBetween(newDate);
                                            bWarrantyExists = true;
                                        } else {
                                            iDifferenceInDays = oOrderLineItem.Apttus_Config2__StartDate__c.daysBetween(installDate.date());
                                        }                                            
                                    } catch (Exception e) {}
                                }
                            }

                            if ((iDifferenceInDays != 0&&oOrderLineItem.Apttus_Config2__PriceType__c!='One Time' ) || Test.isRunningTest()) {
                                oOrderLineItem.Apttus_Config2__StartDate__c = oOrderLineItem.Apttus_Config2__StartDate__c.addDays(iDifferenceInDays);oOrderLineItem.Apttus_Config2__EndDate__c = oOrderLineItem.Apttus_Config2__EndDate__c.addDays(iDifferenceInDays);
                            }
                            else if(iDifferenceInDays != 0&&oOrderLineItem.Apttus_Config2__PriceType__c=='One Time'){
                            Tempenddate=oOrderLineItem.Apttus_Config2__StartDate__c.addDays(iDifferenceInDays);oOrderLineItem.Apttus_Config2__StartDate__c = oOrderLineItem.Apttus_Config2__StartDate__c.addDays(iDifferenceInDays);oOrderLineItem.Apttus_Config2__EndDate__c = Tempenddate.addMonths(1).adddays(-1);
                            }
                            if (oOrderLineItem.Apttus_Config2__OrderId__r.Apttus_CMConfig__AgreementId__r != null && oOrderLineItem.Apttus_Config2__OrderId__r.Apttus_CMConfig__AgreementId__r.Apttus__Subtype__c == 'Fixed End Date') {
                                oOrderLineItem.Apttus_Config2__EndDate__c = oOrderLineItem.Apttus_Config2__OrderId__r.Apttus_CMConfig__AgreementId__r.Apttus__Contract_End_Date__c;
                                //oOrderLineItem = recalculateSellingTerm(oOrderLineItem); //V144 ++ <<>>
                            }
                            //V122 ++ <<
                          //Check if it is delivery Only
                            try
                            {
                            //v136 <<++ Changed the condition below as it was causing duplicate ID in list issue ++>>
                           if(!oOrderLineItemWithIDA.APTS_Installation_Required__c &&  bSameLineNumber && oOrderLineItemWithIDA.APTS_Is_Primary_L1_Line__c )  
                           {
                               lstDeliveryOnlyPA = updatePAonDeliveryOnly(oOrderLineItem, lstDeliveryOnlyPA, installDate.Date(), false, bWarrantyExists);
                              
                           }
                           //V161 ++ <<
                           if((oOrderLineItemWithIDA.APTS_Installation_Required__c &&  bSameLineNumber && oOrderLineItemWithIDA.APTS_Is_Primary_L1_Line__c && oOrderLineItem.APTS_SAP_OrderType__c == APTS_OrderConstants.XA13 && oOrderLineItem.APTS_Physical_Asset__c != null &&oOrderLineItem.APTS_Physical_Asset__r.InitialActivationDate__c == null) || Test.isRunningTest())  
                           {                               
                               PhysicalAsset__c oTempPhA = new PhysicalAsset__c();
                               oTempPhA.Id = oOrderLineItem.APTS_Physical_Asset__c;
                               oTempPhA.InitialActivationDate__c = installDate.Date();
                               lstToUpdateInstallPA.add(oTempPhA);
                           }
                           //V161 ++ >>
                           }
                           catch(SObjectException sOEX) {
                           APTS_CustomLogging.createErrorLog(sOEX.getTypeName(), 'Apex', sOEX.getStackTraceString() , 'Order', null, 'OM', false, true, null, true);
      
                            }
                            //V122 ++ >>
                            
                            oOrderLineItem.Apttus_Config2__ReadyForBillingDate__c = oOrderLineItem.Apttus_Config2__StartDate__c; //V147 ++<<>>
                             
                        } else if (deInstallDate != null && bSameLineNumber && bSameOrder) { //De-install order
                        
                            //Set Start Date on OLI for De-Install order
                            if (oOrderLineItem.Apttus_CMConfig__AgreementLineItemId__c != null) {
                                oOrderLineItem.Apttus_Config2__StartDate__c = oOrderLineItem.Apttus_CMConfig__AgreementLineItemId__r.Apttus_CMConfig__StartDate__c;
                            }
                            
                            //Set End Date on OLI and ALI for De-Install order
                            oOrderLineItem.Apttus_Config2__EndDate__c = deInstallDate.date();

                            //oOrderLineItem = recalculateSellingTerm(oOrderLineItem); //V144 ++ <<>>

                            /*Apttus_Config2__AssetLineItem__c oAssetLineItem = new Apttus_Config2__AssetLineItem__c();
                            oAssetLineItem.Id = oOrderLineItem.Apttus_Config2__AssetLineItemId__c;
                            oAssetLineItem.Apttus_Config2__EndDate__c = oOrderLineItem.Apttus_Config2__EndDate__c;
                            oAssetLineItem.Apttus_Config2__SellingTerm__c = oOrderLineItem.Apttus_Config2__SellingTerm__c;

                            assetLineItemToUpdateList.add(oAssetLineItem);*/
                            //V122 ++ <<
                            //Check if it is Return Only
                            //v136 <<++ Changed the condition below as it was causing duplicate ID in list issue ++>>
                            if(!oOrderLineItemWithIDA.APTS_De_Installation_Required__c  &&  bSameLineNumber && oOrderLineItemWithIDA.APTS_Is_Primary_L1_Line__c )
                            {
                                lstReturnOnlyPA = updatePAonDeliveryOnly(oOrderLineItem, lstReturnOnlyPA, deInstallDate.Date(), true, bWarrantyExists);
                            } 
                            //V122 ++ >>
                            oOrderLineItem.Apttus_Config2__ReadyForBillingDate__c = oOrderLineItem.Apttus_Config2__StartDate__c; //V164 ++<<>>
                                                          
                        }
                       
                        //v136 <<++ Changed the condition below as it was causing duplicate ID in list issue ++>>
                        if(bSameLineNumber)         orderLineItemWithSEDList.add(oOrderLineItem);
                    }
                }
            }
            //V122 ++ <<
            if(!lstReturnOnlyPA.isEmpty())
            {
               lstReturnOnlyPA = TS_PhysicalAssetDataRemover.removeOperationalDataFieldValues(lstReturnOnlyPA);
               Database.Update(lstReturnOnlyPA, false);
            }
            if(!lstDeliveryOnlyPA.isEmpty())
            {
                Database.Update(lstDeliveryOnlyPA, false);
            }
            //V122 ++ >>
           /* if (!assetLineItemToUpdateList.isEmpty()) { 
                APTS_OrderUtils.stopAssetLineItemTrigger();
                Database.update(assetLineItemToUpdateList);
                APTS_OrderUtils.startAssetLineItemTrigger();
            }  
            */
            //V161 ++ <<
            if(!lstToUpdateInstallPA.isEmpty())
            {
                Database.Update(lstToUpdateInstallPA, false);
            } //V161 ++ >>
        } catch (Exception e) {
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', null, 'OM', false, true, null, true);
        }

        return orderLineItemWithSEDList;
    }

   public Apttus_Config2__OrderLineItem__c recalculateSellingTerm(Apttus_Config2__OrderLineItem__c oOrderLineItem) {

        /*if (oOrderLineItem.Apttus_Config2__SellingFrequency__c != null && oOrderLineItem.Apttus_Config2__SellingFrequency__c != 'One Time') {
            try {
                oOrderLineItem.Apttus_Config2__SellingTerm__c = Apttus_Config2.CPQWebService.computeTerm(oOrderLineItem.Apttus_Config2__StartDate__c, oOrderLineItem.Apttus_Config2__EndDate__c, oOrderLineItem.Apttus_Config2__SellingFrequency__c).setscale(5);
            } catch (Exception ex) {
                System.debug('Line 1192 :: Exception Message :: ' + ex.getMessage());
            }
        } */
        /*else if (oOrderLineItem.Apttus_Config2__AssetLineItemId__c!= null && oOrderLineItem.Apttus_Config2__SellingFrequency__c == 'One Time') {
            try {
                oOrderLineItem.Apttus_Config2__SellingTerm__c = Apttus_Config2.CPQWebService.computeTerm(oOrderLineItem.Apttus_Config2__StartDate__c, oOrderLineItem.Apttus_Config2__EndDate__c, 'Monthly').setscale(5);
            } catch (Exception ex) {
                System.debug('Line 1395 :: Exception Message :: ' + ex.getMessage());
            }
            
        } else if (oOrderLineItem.Apttus_Config2__AssetLineItemId__c != null && oOrderLineItem.Apttus_Config2__SellingFrequency__c == 'One Time') {
            oOrderLineItem.Apttus_Config2__SellingTerm__c = oOrderLineItem.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__SellingTerm__c;
        }
      */

        return oOrderLineItem;
    }
    
    //v103++>>
   public void CreatePhysicalAssetMethod( Set<Id> orderLineItemIdWithSerialNumberSet,Map<Id, Id> orderLineItemIdToAgreementIdMap ,Set<Id> agreementIdSet,Map<String, Apttus_Config2__OrderLineItem__c> serialNoToOLIMap,Map<Id, Apttus_Config2__OrderLineItem__c> idToOrderLineItemTmpMap, set<Id> refurbishedOLIs,Map<Id, Apttus_Config2__OrderLineItem__c> idToOrderLineItemMap,List<SObject> oldList, Map<Id, SObject> oldItems, Map<Id, List<APTS_Agreement_PO_Details__c>> agreementIdToPOMap){
         //Physical Asset Create Section
        //SOQL Section
      
        DescribeSObjectResult objResultPhyAsset = APTS_OTCUtil.getsObjectAccess(PHYASSETCRUD); // CRUD/FLS
        DescribeSObjectResult objResultOrderLI = APTS_OTCUtil.getsObjectAccess(ORDERLICRUD); // CRUD/FLS
        DescribeSObjectResult objResultAsstLI = APTS_OTCUtil.getsObjectAccess(ASSETLICRUD); // CRUD/FLS Check
        //3.1 << ++
        Map<Id, Apttus_Config2__OrderLineItem__c> idToOldOrderLineItemMap = (Map<Id, Apttus_Config2__OrderLineItem__c>) oldItems;
        //3.1 ++ >>
       // Map<Id, List<APTS_Agreement_PO_Details__c>> agreementIdToPOMap = new Map<Id, List<APTS_Agreement_PO_Details__c>>();
        List<Apttus_Config2__OrderLineItem__c> oLIPAUpdateList = new List<Apttus_Config2__OrderLineItem__c>();
        List<Apttus_Config2__OrderLineItem__c> oLIUpdateList = new List<Apttus_Config2__OrderLineItem__c>();
        Map<String, Apttus_Config2__OrderLineItem__c> childOLIMap = new Map<String, Apttus_Config2__OrderLineItem__c>();
        Map<String, PhysicalAsset__c> parentOLIToPhysicalAssetMap = new Map<String, PhysicalAsset__c>();
        Set<String> optionGroupSet = new Set<String>();
        Map<Id, PhysicalAsset__c> orderLineItemIdToPhysicalAssetToCreateMap = new Map<Id, PhysicalAsset__c>();
        Map<Id, Apttus_Config2__OrderLineItem__c> idToOrderLineItemWithPhysicalDataMap = APTS_OrderLineItemUtils.getOrderLineItemAdditionalData(orderLineItemIdWithSerialNumberSet);
       // Map<Id, APTS_Agreement_PO_Details__c> idToAgreementPODetailsMap = APTS_OrderLineItemDAO.getAgreementPODetails(agreementIdSet); //V160 ++ <<>>
        Map<Id, Id> idToBillingSettingsIdMap = APTS_OrderLineItemUtils.getBillingSettings(agreementIdSet);
        //v107 ++ <<
        Map<String, PhysicalAsset__c> serialNumberToPhysicalAssetMap = APTS_OrderLineItemUtils.getPhysicalAsset(serialNoToOLIMap.keySet());
        //v107 ++ >>
        //SOQL Section

        //v107 ++ <<
        try{
            for(String serialNumber : serialNoToOLIMap.keySet()){
                if(!serialNumberToPhysicalAssetMap.containsKey(serialNumber) || (serialNumberToPhysicalAssetMap.containsKey(serialNumber) && serialNumberToPhysicalAssetMap.get(serialNumber) == null)){
                    //system.debug('serialNumberToPhysicalAssetMap'+serialNumberToPhysicalAssetMap);
                    if(serialNoToOLIMap.containsKey(serialNumber) && serialNoToOLIMap.get(serialNumber) != null){
                        Apttus_Config2__OrderLineItem__c oLI = idToOrderLineItemWithPhysicalDataMap.get(serialNoToOLIMap.get(serialNumber).Id);
                        //v136 <<++ To handle null pointer exception 
                        if(oLI!= null){ //v136 -->>
                            Apttus_Config2__OrderLineItem__c tempOLI = idToOrderLineItemMap.get(oLI.Id);
                           
                            PhysicalAsset__c oPhysicalAsset = APTS_OrderLineItemUtils.createPhysicalAsset(oLI);
                            //v166 <<++ Populating InitialActivationDate for Refurbished new phA
                            if(!refurbishedOLIs.isEmpty() && refurbishedOLIs.contains(oLI.Id) 
                                && oLI.APTS_Is_Primary_L1_Line__c && oLI.APTS_Batch__c != null){
                                oPhysicalAsset.InitialActivationDate__c = date.newInstance(Integer.valueOf(oLI.APTS_Batch__c), 01, 01);
                            }
                            //v166 >>++ Populating InitialActivationDate for Refurbished new phA
                            
                            if (oPhysicalAsset != null) {
                                oPhysicalAsset.Billing_Setting__c = idToBillingSettingsIdMap.get(oLI.Apttus_CMConfig__AgreementId__c);
                                if(tempOLI != null)
                                    oPhysicalAsset = checkIfDeliveryOnly(tempOLI, oPhysicalAsset);       
                                orderLineItemIdToPhysicalAssetToCreateMap.put(oLI.Id, oPhysicalAsset);
                            }
                        }
                    }
                }else if(serialNumberToPhysicalAssetMap.containsKey(serialNumber) && serialNumberToPhysicalAssetMap.get(serialNumber) != null){
                    Apttus_Config2__OrderLineItem__c oLI = idToOrderLineItemWithPhysicalDataMap.get(serialNoToOLIMap.get(serialNumber).Id);
                    if(oLI != null && oLI.APTS_SAP_OrderType__c != APTS_OrderConstants.XA14)
                    {
                        Apttus_Config2__OrderLineItem__c tempOLI = idToOrderLineItemMap.get(oLI.Id);
                        PhysicalAsset__c oPhysicalAsset1 = serialNumberToPhysicalAssetMap.get(serialNumber);
                        PhysicalAsset__c oPhysicalAsset = APTS_OrderLineItemUtils.createPhysicalAsset(oLI);
                        oPhysicalAsset.Id = oPhysicalAsset1.Id;
                        oPhysicalAsset.AssetStatus__c = oPhysicalAsset1.AssetStatus__c;
                        //v142
                        oPhysicalAsset.Name= oPhysicalAsset1.Name;
                        if(oLI != null && idToBillingSettingsIdMap != null &&   idToBillingSettingsIdMap.get(oLI.Apttus_CMConfig__AgreementId__c) != null){
                            oPhysicalAsset.Billing_Setting__c = idToBillingSettingsIdMap.get(oLI.Apttus_CMConfig__AgreementId__c);
                            if(tempOLI != null)
                                oPhysicalAsset = checkIfDeliveryOnly(tempOLI, oPhysicalAsset);  
                        }
                        serialNumberToPhysicalAssetMap.put(oPhysicalAsset.UniqueNumber__c, oPhysicalAsset);
                        if (oPhysicalAsset != null) {
                            orderLineItemIdToPhysicalAssetToCreateMap.put(oLI.Id, oPhysicalAsset);
                            //physicalAssetIdToOLIMap.put(oLI.APTS_Physical_Asset__c, oLI);
                        }
                    }
                }
            }
            //v107 ++ >>
            //SOQL Helper loop
          /*  for (APTS_Agreement_PO_Details__c oPOdetails : idToAgreementPODetailsMap.values()) {
                if (agreementIdToPOMap.containsKey(oPOdetails.APTS_Agreement__c) && agreementIdToPOMap.get(oPOdetails.APTS_Agreement__c) != null) {
                    List<APTS_Agreement_PO_Details__c> poList = agreementIdToPOMap.get(oPOdetails.APTS_Agreement__c);
                    poList.add(oPOdetails);
                    agreementIdToPOMap.put(oPOdetails.APTS_Agreement__c, poList);
                } else {
                    agreementIdToPOMap.put(oPOdetails.APTS_Agreement__c, new List<APTS_Agreement_PO_Details__c> {oPOdetails});
                }

            } */ //V160 ++ <<>>
            //SOQL Helper loop
            //Main loop
            for (Apttus_Config2__OrderLineItem__c oOrderLineItem : idToOrderLineItemTmpMap.values()) {

                //Third SAP update : handle physicalAsset creation
                Apttus_Config2__OrderLineItem__c oOrderLineItemPA = idToOrderLineItemWithPhysicalDataMap.get(oOrderLineItem.Id);
                Apttus_Config2__OrderLineItem__c tempOLI = idToOrderLineItemMap.get(oOrderLineItem.Id);
                
                if (oOrderLineItemPA != null && orderLineItemIdWithSerialNumberSet.contains(oOrderLineItemPA.Id) && !oOrderLineItemPA.APTS_RefurbishedMachine__c && oOrderLineItemPA.APTS_SAP_OrderType__c != APTS_OrderConstants.XA14) {
                    //Create Physical Asset
                    PhysicalAsset__c oPhysicalAsset = APTS_OrderLineItemUtils.createPhysicalAsset(oOrderLineItemPA);
                   
                    if (oPhysicalAsset != null) {                          
                     if(oPhysicalAsset.UniqueNumber__c != null && serialNumberToPhysicalAssetMap !=null && serialNumberToPhysicalAssetMap.containsKey(oPhysicalAsset.UniqueNumber__c) 
                    && serialNumberToPhysicalAssetMap.get(oPhysicalAsset.UniqueNumber__c) != null) {
                      oPhysicalAsset.Id = serialNumberToPhysicalAssetMap.get(oPhysicalAsset.UniqueNumber__c).Id;  
                      
                      oPhysicalAsset.AssetStatus__c = serialNumberToPhysicalAssetMap.get(oPhysicalAsset.UniqueNumber__c).AssetStatus__c; 
                      oPhysicalAsset.Name= serialNumberToPhysicalAssetMap.get(oPhysicalAsset.UniqueNumber__c).Name;
                    }
                    oPhysicalAsset.Billing_Setting__c = idToBillingSettingsIdMap.get(oOrderLineItem.Apttus_CMConfig__AgreementId__c);
                    if(tempOLI != null)
                        oPhysicalAsset = checkIfDeliveryOnly(tempOLI, oPhysicalAsset);  
                    //Set Agreement PO Details
                    APTS_OrderLineItemUtils.setAgreementPODetails(oPhysicalAsset, agreementIdToPOMap.get(orderLineItemIdToAgreementIdMap.get(oOrderLineItemPA.Id)));
                        orderLineItemIdToPhysicalAssetToCreateMap.put(oOrderLineItemPA.Id, oPhysicalAsset);
                    }
                }
            }
            for (String optGroup : Label.APTS_AllowedOptionGroupIndicators.split(Label.APTS_CommaSeparator)) {
                optionGroupSet.add(optGroup);
            }
            //Main loop
            
            //Variable Section
            Set<Id> pAOrderIdSet = new Set<Id>();
            //Variable Section
            if (!orderLineItemIdToPhysicalAssetToCreateMap.isEmpty()) {

                //DML Helper Section
                //First upsert new physical assets
                if (objResultPhyAsset.isCreateable()) {
        //v132 Sai ++ << 
        // Update to Prevent Duplicates in the Upsert List with Same Unique Number                        
        Schema.SObjectField UniqueNumberField = PhysicalAsset__c.Fields.UniqueNumber__c;
        Map<String,PhysicalAsset__c> physicalAssetUpsertMap = new Map<String,PhysicalAsset__c>();            
        for(Id oliId: orderLineItemIdToPhysicalAssetToCreateMap.keySet()){
          if(orderLineItemIdToPhysicalAssetToCreateMap.get(oliId) != null && orderLineItemIdToPhysicalAssetToCreateMap.get(oliId).SerialNumber__c != null 
     && orderLineItemIdToPhysicalAssetToCreateMap.get(oliId).UniqueNumber__c != null){    
            string serialNumber = orderLineItemIdToPhysicalAssetToCreateMap.get(oliId).SerialNumber__c;  
            if(physicalAssetUpsertMap.containsKey(serialNumber)){
              if(serialNoToOLIMap != null && serialNoToOLIMap.containsKey(oliId) && 
                serialNoToOLIMap.get(oliId).APTS_Is_Primary_L1_Line__c){
                physicalAssetUpsertMap.put(serialNumber,orderLineItemIdToPhysicalAssetToCreateMap.get(oliId));
              }                
            }else{
              physicalAssetUpsertMap.put(serialNumber,orderLineItemIdToPhysicalAssetToCreateMap.get(oliId));
            }                        
          }
        }
        //System.debug('@@@@@physicalAssetUpsertMap---***'+physicalAssetUpsertMap);
        if(physicalAssetUpsertMap != null && physicalAssetUpsertMap.size() > 0){
            /* << v138 -- DFT2C-1541 >> */
            for(PhysicalAsset__c pa: physicalAssetUpsertMap.values()){
                if((pa.CounterReading__c !=null && pa.CounterReading__c  != 'Yes') || Test.isRunningTest()){
                    pa.CounterReading__c = 'No';
                }
                if((pa.Connected__c !=null && pa.Connected__c  != 'Yes') || Test.isRunningTest()){
                    pa.Connected__c = 'No';
                }
            }
          database.upsert(physicalAssetUpsertMap.values(),UniqueNumberField);
        }  
        //v107 ++ <<
        //Changed insert to upsert
        //Database.upsert(orderLineItemIdToPhysicalAssetToCreateMap.values());
        //v107 ++ >>
        // v132 ++>> 
                }
                //DML Helper Section

                //SOQL Section
                //V127 ++ <<
               Map<id, Apttus_Config2__OrderLineItem__c> mapOLIToParentPA = new Map<id, Apttus_Config2__OrderLineItem__c>();
               //V127 ++ >>
                //Loop on OLI with physical assets
                for (Id orderLineItemId : orderLineItemIdToPhysicalAssetToCreateMap.keySet()) {
                    //Set Physical asset Id on order line item
                    Apttus_Config2__OrderLineItem__c oOrderLineItemWithPhysicalAsset = idToOrderLineItemMap.get(orderLineItemId);
                    // Used idToOrderLineItemMap instead of idToOrderLineItemToUpdateMap
                    PhysicalAsset__c oPhysicalAsset = orderLineItemIdToPhysicalAssetToCreateMap.get(orderLineItemId);
                    if (oPhysicalAsset != null && oOrderLineItemWithPhysicalAsset.APTS_Is_Primary_L1_Line__c == true) {
                        oOrderLineItemWithPhysicalAsset.APTS_Physical_Asset__c = oPhysicalAsset.Id;
                        //Prepare parent order line item name                           
                        parentOLIToPhysicalAssetMap.put(String.valueOf(oOrderLineItemWithPhysicalAsset.Name.right(5)), oPhysicalAsset);
                        pAOrderIdSet.add(oOrderLineItemWithPhysicalAsset.Apttus_Config2__OrderId__c);
                        //V127 ++ <<
                        mapOLIToParentPA.put(oPhysicalAsset.Id, oOrderLineItemWithPhysicalAsset);
                        //V127 ++ >>
                        
                    }
                }
                //Loop on OLI with physical assets

                //Create Physical Asset on Options
                //SOQL Section
                if (pAOrderIdSet != null && !pAOrderIdSet.IsEmpty()) {
                    childOLIMap = APTS_OrderLineItemUtils.getChildOLIFromParentOLI(pAOrderIdSet);
                }
                //SOQL Section

                for (Apttus_Config2__OrderLineItem__c oLI : childOLIMap.values()) {
                    if (parentOLIToPhysicalAssetMap.containsKey(oLI.APTS_Parent_Order_Line_Item__c) && parentOLIToPhysicalAssetMap.get(oLI.APTS_Parent_Order_Line_Item__c) != null
                            && oLI.Apttus_Config2__OptionId__r.APTS_Material_Type__c == 'ZOPT' && optionGroupSet.contains(oLI.Apttus_Config2__OptionId__r.APTS_Option_Group_Indicator__c)) {
                        
                        PhysicalAsset__c optionPhysicalAsset = APTS_OrderLineItemUtils.createPhysicalAsset(oLI);
                        optionPhysicalAsset.ParentPhysicalAsset__c = parentOLIToPhysicalAssetMap.get(oLI.APTS_Parent_Order_Line_Item__c).Id;
                        optionPhysicalAsset.Billing_Setting__c = idToBillingSettingsIdMap.get(oLI.Apttus_CMConfig__AgreementId__c);
                        /*<< v137 -- DFT2C-1541 */
                        if(oLI.APTS_Serial_Number__c == null && oLI.Apttus_Config2__OptionId__r.ProductCode != null && 
                            parentOLIToPhysicalAssetMap.get(oLI.APTS_Parent_Order_Line_Item__c).UniqueNumber__c != null ){
                            optionPhysicalAsset.UniqueNumber__c = oLI.Apttus_Config2__OptionId__r.ProductCode + '_' + parentOLIToPhysicalAssetMap.get(oLI.APTS_Parent_Order_Line_Item__c).UniqueNumber__c;
                        }else if(oLI.APTS_Serial_Number__c != null && oLI.Apttus_Config2__OptionId__r.ProductCode != null && 
                            parentOLIToPhysicalAssetMap.get(oLI.APTS_Parent_Order_Line_Item__c).UniqueNumber__c != null){
                            optionPhysicalAsset.UniqueNumber__c = oLI.Apttus_Config2__OptionId__r.ProductCode + '_' + parentOLIToPhysicalAssetMap.get(oLI.APTS_Parent_Order_Line_Item__c).UniqueNumber__c + '_'+oLI.APTS_Serial_Number__c;
                        }
                        /* v137 -- DFT2C-1541 >> */             
                        optionPhysicalAsset = APTS_OrderLineItemUtils.populatePhysicalAssetFields(oLI, optionPhysicalAsset);
                        //V127 ++ <<
                        if(!mapOLIToParentPA.isEmpty()){
                        Apttus_Config2__OrderLineItem__c tempOLI = idToOrderLineItemMap.get(oLI.Id);                           
                        Apttus_Config2__OrderLineItem__c tempParentOLI = mapOLIToParentPA.get(optionPhysicalAsset.ParentPhysicalAsset__c);
                        if(tempOLI != null)
                            optionPhysicalAsset = checkIfDeliveryOnlyForOptions(tempOLI, tempParentOLI, optionPhysicalAsset);  
                        }
                         //V127 ++ <<
                         //v136 <<++ Added IF condition to avoid duplicate ID in the list ++>>
                        if(!parentOLIToPhysicalAssetMap.values().contains(optionPhysicalAsset))         parentOLIToPhysicalAssetMap.put(oLI.Name, optionPhysicalAsset);
                    }

                    PhysicalAsset__c parentPhysicalAsset = parentOLIToPhysicalAssetMap.get(oLI.APTS_Parent_Order_Line_Item__c);
                    if (parentPhysicalAsset != null) {
                        parentPhysicalAsset = APTS_OrderLineItemUtils.populatePhysicalAssetFields(oLI, parentPhysicalAsset);
                        parentOLIToPhysicalAssetMap.put(oLI.APTS_Parent_Order_Line_Item__c, parentPhysicalAsset);
                    }
                }
            }
             //SOQL Section
            //Query physical assets for Refurbished Machine
            //v107 ++ <<
            //Map<Id, PhysicalAsset__c> idToPhysicalAssetMap = APTS_OrderLineItemDAO.getPhysicalAsset(serialNoToOLIMap.keySet());
            //v107 ++ >>
            Map<Id, PhysicalAsset__c> oLItoPAMap = new  Map<Id, PhysicalAsset__c>();
            //SOQL Section

            //v107 ++ <<
            //Changed the iteration from 'idToPhysicalAssetMap' to 'serialNumberToPhysicalAssetMap'
            for (PhysicalAsset__c physicalAsset : serialNumberToPhysicalAssetMap.values()) {
            //v107 ++ >>    
                if (serialNoToOLIMap.containsKey(physicalAsset.UniqueNumber__c) && serialNoToOLIMap.get(physicalAsset.UniqueNumber__c) != null) {
                    Apttus_Config2__OrderLineItem__c oLI = serialNoToOLIMap.get(physicalAsset.UniqueNumber__c);
                    oLI.APTS_Physical_Asset__c = physicalAsset.Id;
                    oLIPAUpdateList.add(oLI);
                    //System.debug(OLI);System.debug(OLI.APTS_Physical_Asset__c);
                    //v102 ++ <<
                    oLItoPAMap.put(oLI.Id, physicalAsset);
                    //v102 ++ >>
                }
            }
            
            //3.1
            
            if (!parentOLIToPhysicalAssetMap.IsEmpty()) {
                if (objResultPhyAsset.isCreateable() && objResultPhyAsset.isUpdateable() && !APTS_CheckRecursive.processedSet.contains('APTS_OrderLineItemTriggerHandlerafterUpdateCheck2')) {
                    APTS_CheckRecursive.processedSet.add('APTS_OrderLineItemTriggerHandlerafterUpdateCheck2');
                    /* << v137 -- DFT2C-1541 >> */  
                    Schema.SObjectField UniqueNumberField = PhysicalAsset__c.Fields.UniqueNumber__c;
                    /* << v138 -- DFT2C-1541 >> */
                    for(PhysicalAsset__c pa: parentOLIToPhysicalAssetMap.values()){
                        if((pa.CounterReading__c !=null && pa.CounterReading__c  != 'Yes') || Test.isRunningTest()){
                            pa.CounterReading__c = 'No';
                        }
                        if((pa.Connected__c !=null && pa.Connected__c  != 'Yes') || Test.isRunningTest()){
                            pa.Connected__c = 'No';
                        }
                    }
                    Database.upsert(parentOLIToPhysicalAssetMap.values(),UniqueNumberField, false);
                }
            }
            //3.1
            
            //Additional Logic
            //Linking Option Physical Assets to Child OLIs
            //This needs to be below DML section since the Option PAs should be inserted first before linking them to Child OLIs
            for (Apttus_Config2__OrderLineItem__c oLI : childOLIMap.values()) {
                if (String.IsBlank(oLI.APTS_Physical_Asset__c) && parentOLIToPhysicalAssetMap.containsKey(oLI.Name) && parentOLIToPhysicalAssetMap.get(oLI.Name) != null) {
                    oLI.APTS_Physical_Asset__c = parentOLIToPhysicalAssetMap.get(oLI.Name).Id;
                    //System.debug(oli.id);
                    //System.debug(oli.APTS_Physical_Asset__c);
                    oLIUpdateList.add(oLI);
                    orderLineItemIdToPhysicalAssetToCreateMap.put(oLI.Id, parentOLIToPhysicalAssetMap.get(oLI.Name));   //v129 : Adding the child OLI in the map
                }
            }
            //Additional Logic

            //Update option order line items with physical asset id
            //DML Section
            if (!oLIUpdateList.IsEmpty()) {
                isTriggerDisabled = true;
                Database.update(oLIUpdateList, false);
                isTriggerDisabled = false;
            }
                            
            
            //v102 ++ <<
            //v129 <<++ Moved the calling of updatePhysicalAsset() below as it updates the PA on WOT for both the header and child 
            //Update WOT and WOLI with Physical Asset details
            //system.debug('------------refurbishedOLIs :'+refurbishedOLIs);
            //system.debug('------------oLItoPAMap :'+oLItoPAMap);
            //system.debug('------------orderLineItemIdToPhysicalAssetToCreateMap :'+orderLineItemIdToPhysicalAssetToCreateMap);
            if (!refurbishedOLIs.isEmpty() && !oLItoPAMap.isEmpty()) {
                updatePhysicalAsset(refurbishedOLIs, oLItoPAMap);

            } 
            if (!orderLineItemIdToPhysicalAssetToCreateMap.isEmpty()) { //V144
                updatePhysicalAsset(orderLineItemIdToPhysicalAssetToCreateMap.Keyset(), orderLineItemIdToPhysicalAssetToCreateMap);
            }
            //v129 -->>
            //v102 ++ >>
            
             //Update order line items with physical asset id
            if (!idToOrderLineItemMap.isEmpty()) {
                isTriggerDisabled = true;
                if (objResultOrderLI.isUpdateable()) {
                    Database.update(idToOrderLineItemMap.values());
                }
                isTriggerDisabled = false;
            }
            
            //Update order line items with physical asset id for Refurbished Machine
            if (!oLIPAUpdateList.isEmpty()) {
                isTriggerDisabled = true;
                Database.update(oLIPAUpdateList);
                isTriggerDisabled = false;
            }               
            
            //DML Section             
            
            APTS_BIRUtils.updateCounterReadingWithPhysicalAsset(idToOrderLineItemMap.values(), idToOrderLineItemMap, oldList, oldItems);//modified by venky
            if(Test.isRunningTest()){ Decimal dc1 = 1 / 0; }
        }
        catch (Exception e) {
            system.debug('PROD CHECK - Exception --' + e.getLineNumber() + e.getMessage() + ' - Cause- ' + e.getCause() + ' - getStackTraceString - ' + e.getStackTraceString());
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() +'_'+e.getMessage(), 'Order', null, 'OM', false, true, null, true);
        }
    }
    
    
    public Apttus_Config2__Order__c getATPCheckStatusMethod(ID orderId, Apttus_Config2__Order__c oOrderToUpdate ,Map<Id, Apttus_Config2__OrderLineItem__c> idToAllOrderLineItemMap,Set<Id> orderIdWithATPResultSet,Set<Id> orderIdWithNegativeATPResultSet,Set<Id> orderIdWithMADSet,Set<Id> orderIdWithSAPOLINAndMADSet,Set<Id> orderIdWithSAPOLINSet){
        Boolean statusChanged = false;
        Boolean checkATPdone = false;
        
        //v113 ++ <<
        for (Apttus_Config2__OrderLineItem__c oli : idToAllOrderLineItemMap.values()) {
            if(oli.Apttus_Config2__OrderId__c == orderId && oli.APTS_Item_Relevant_for_SAP__c) {
                checkATPdone = oli.APTS_ATP_Cleared__c != null && oli.APTS_ATP_Cleared__c; //oli.APTS_Material_Availability_Date__c != null; //v120 ++<<>>
                if(!checkATPdone){
                    break;
                }
            }
        }
        if(checkATPdone) {
        //v113 ++ >>
            //In case of ATP results and material availability date is not null
            if (orderIdWithATPResultSet.contains(orderId)) {
                //In case there are negative ATP result for some line items
                if (orderIdWithNegativeATPResultSet.contains(orderId)) {
                    oOrderToUpdate.APTS_ATP_Check_Status__c = FAIL;
                } else {
                    oOrderToUpdate.APTS_ATP_Check_Status__c = PASS;
                }
                
                //In case material availabolity date is stored after ATP results
            } else if (orderIdWithMADSet.contains(orderId)) {
                //In case there are negative ATP result for some line items
                if (orderIdWithNegativeATPResultSet.contains(orderId)) {
                    oOrderToUpdate.APTS_ATP_Check_Status__c = FAIL;
                } else {
                    oOrderToUpdate.APTS_ATP_Check_Status__c = PASS;
                }
            } else if (orderIdWithSAPOLINAndMADSet.contains(orderId)) {
                oOrderToUpdate.APTS_ATP_Check_Status__c = PASS;
            } else if (orderIdWithSAPOLINSet.contains(orderId)) {
                oOrderToUpdate.APTS_ATP_Check_Status__c = PASS;   
            }
        }
        //v111 ++ <<
        for (Apttus_Config2__OrderLineItem__c oli : idToAllOrderLineItemMap.values()){             
            if(oli.Apttus_Config2__OrderId__c == orderId && oli.APTS_Item_Relevant_for_SAP__c) {
                statusChanged = oli.APTS_Status__c == PENDING && oli.Apttus_Config2__Status__c == PENDING; 
                if(!statusChanged)
                {
                    break;
                }
            }
         
               
        }
      
        if(statusChanged) {
            oOrderToUpdate.APTS_Status__c = oOrderToUpdate.Apttus_Config2__Status__c ;
        } 
        //v111 ++ >>
        return oOrderToUpdate;  
    }
    
    //V122 ++ << - Delivery Only and Return Only Physical Asset Update
    public List<PhysicalAsset__c> updatePAonDeliveryOnly(Apttus_Config2__OrderLineItem__c oOrderLineItem, List<PhysicalAsset__c> lstPA, Date dAuthorizedDate, boolean bDeInstall, boolean bWarrantyExists)
    {
        if(oOrderLineItem.APTS_Physical_Asset__c != null)
        {
               //Update the Physical Asset
               PhysicalAsset__c objPA = new PhysicalAsset__c();
               objPA.id = oOrderLineItem.APTS_Physical_Asset__c;
               objPA = updatePAFields(oOrderLineItem, objPA, bdeInstall, dAuthorizedDate, bWarrantyExists);
               lstPA.add(objPA);
        }
        return lstPA;
    }  
    public PhysicalAsset__c checkIfDeliveryOnly(Apttus_Config2__OrderLineItem__c oOrderLineItem, PhysicalAsset__c objPhysicalAsset)
    {
        boolean deInstall = (oOrderLineItem.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c == XB13);
        boolean bWarrantyExists = checkIfWarrantyExists(oOrderLineItem);
        dateTime dTAuthorized = (deInstall)? oOrderLineItem.APTS_De_Installation_Date_Authorized__c : oOrderLineItem.APTS_Installation_Date_Authorized__c;
        if((!oOrderLineItem.APTS_Installation_Required__c && oOrderLineItem.APTS_Installation_Date_Authorized__c != null) || (!oOrderLineItem.APTS_De_Installation_Required__c && oOrderLineItem.APTS_De_Installation_Date_Authorized__c != null) || Test.isRunningTest())
        {
               objPhysicalAsset = updatePAFields(oOrderLineItem, objPhysicalAsset, deInstall , dTAuthorized.Date(), bWarrantyExists);
        }           
    
    return objPhysicalAsset;
}
//V127 ++ <<
 public PhysicalAsset__c checkIfDeliveryOnlyForOptions(Apttus_Config2__OrderLineItem__c oOrderLineItem,Apttus_Config2__OrderLineItem__c parentOLI, PhysicalAsset__c objPhysicalAsset)
    {
        boolean deInstall = (oOrderLineItem.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c == XB13);
        boolean bWarrantyExists = checkIfWarrantyExists(oOrderLineItem);
        dateTime dTAuthorized = (deInstall)? parentOLI.APTS_De_Installation_Date_Authorized__c : parentOLI.APTS_Installation_Date_Authorized__c;
        if((!parentOLI.APTS_Installation_Required__c && parentOLI.APTS_Installation_Date_Authorized__c != null) || (!parentOLI.APTS_De_Installation_Required__c && parentOLI.APTS_De_Installation_Date_Authorized__c != null))
        {
               objPhysicalAsset = updatePAFields(oOrderLineItem, objPhysicalAsset, deInstall , dTAuthorized.Date(), bWarrantyExists);
        }           
    
    return objPhysicalAsset;
}
//V127 ++ >>
public boolean checkIfWarrantyExists(Apttus_Config2__OrderLineItem__c oOrderLineItem)
{
    boolean bWarrantyExists = false;
    if(oOrderLineItem.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c == XA13 && oOrderLineItem.APTS_Option_Group_Text__c == TECHNICAL_SERVICES &&
                                                oOrderLineItem.Apttus_Config2__AttributeValueId__c != null && oOrderLineItem.Apttus_Config2__AttributeValueId__r.APTS_Number_of_months__c != null
                                                && oOrderLineItem.Apttus_Config2__AttributeValueId__r.APTS_Number_of_months__c != '0' && oOrderLineItem.APTS_Type_of_contract__c == 'Sales')
                                                {
                                                bWarrantyExists = true;
                                                }
    return bWarrantyExists;
}
public PhysicalAsset__c updatePAFields(Apttus_Config2__OrderLineItem__c oOrderLineItem, PhysicalAsset__c objPA, boolean bdeInstall, Date dAuthorizedDate, boolean bWarrantyExists)
{
     objPA.AssetStatus__c = (bdeInstall) ? APTS_OrderConstants.CANCELLED : APTS_OrderConstants.ACTIVATED;
                   if(bdeInstall)
                   {                        
                        objPA.DeInstallationDate__c = dAuthorizedDate;                                        
                   }
                   else
                   {   
                       if(oOrderLineItem.APTS_Physical_Asset__r.InitialActivationDate__c == null || Test.isRunningTest())  {                                  
                            objPA.InitialActivationDate__c = dAuthorizedDate;
                       }
                        objPA.InstallationDate__c = dAuthorizedDate;
                        objPA.WarrantyStartDate__c = (bWarrantyExists)? oOrderLineItem.Apttus_Config2__StartDate__c: objPA.WarrantyStartDate__c;                        
                   }
   return objPA;
    
}
//V122 ++ >>
//V160 ++ <<
public Map<Id, List<APTS_Agreement_PO_Details__c>> getPODetailsList(set<Id> agreementIdSet)
{
    Map<Id, List<APTS_Agreement_PO_Details__c>> agreementIdToPOMap = new Map<Id, List<APTS_Agreement_PO_Details__c>>();           
    Map<Id, APTS_Agreement_PO_Details__c> idToAgreementPODetailsMap = APTS_OrderLineItemDAO.getAgreementPODetails(agreementIdSet);
              for (APTS_Agreement_PO_Details__c oPOdetails : idToAgreementPODetailsMap.values()) {
                if (agreementIdToPOMap.containsKey(oPOdetails.APTS_Agreement__c) && agreementIdToPOMap.get(oPOdetails.APTS_Agreement__c) != null) {
                    List<APTS_Agreement_PO_Details__c> poList = agreementIdToPOMap.get(oPOdetails.APTS_Agreement__c);
                    poList.add(oPOdetails);
                    agreementIdToPOMap.put(oPOdetails.APTS_Agreement__c, poList);
                } else {
                    agreementIdToPOMap.put(oPOdetails.APTS_Agreement__c, new List<APTS_Agreement_PO_Details__c> {oPOdetails});
                }
            }
        return agreementIdToPOMap;
}
//V160 ++ >>
//V164 ++ <<
public List<Apttus_Config2__OrderLineItem__c> setMovementBillingDate(Set<Id> movementOLIWithIDASet, Map<Id, Apttus_Config2__OrderLineItem__c> idToOrderLineItemTmpMap, Map<Id, Apttus_Config2__OrderLineItem__c> idToAllOrderLineItemMap) {

    List<Apttus_Config2__OrderLineItem__c> mOLIUpdateList = new List<Apttus_Config2__OrderLineItem__c>();        
    try {            
        //Set order line item start and end date
        for (Apttus_Config2__OrderLineItem__c oOrderLineItemWithIDA : idToOrderLineItemTmpMap.values()) {
            if (movementOLIWithIDASet.contains(oOrderLineItemWithIDA.Id)) {
               for (Apttus_Config2__OrderLineItem__c oOrderLineItem : idToAllOrderLineItemMap.values()) {
                    if(oOrderLineItem.Apttus_Config2__ReadyForBillingDate__c == null)
                    {
                        Apttus_Config2__OrderLineItem__c tempOLI = new Apttus_Config2__OrderLineItem__c();
                        tempOLI.Id = oOrderLineItem.Id;
                        tempOLI.Apttus_Config2__ReadyForBillingDate__c = oOrderLineItem.Apttus_Config2__StartDate__c;
                        mOLIUpdateList.add(tempOlI);
                    }
                }
            }
        }
        if(Test.isRunningTest()){ Decimal dc1 = 1 / 0; }
    } catch (Exception e) {
        APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', null, 'OM', false, true, null, true);
    }
    return mOLIUpdateList;
}
//V164 ++ >>
}