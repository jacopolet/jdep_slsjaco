/*************************************************************
@Name: APTS_OrderLineItemDAO
@Author: Galin Georgiev
@CreateDate: 12-10-2018
@Description: Order line item dao
@UsedBy: Order line item trigger
******************************************************************/
//v100 12-10-2018 Georgiev: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes
//V101 25-10-2018 Aarthi Pitchai Added Apttus_Config2__AutoRenew__c to the getOrder() query - Defect #20477
//v102 19-Dec-2018 Akanksha : Added method for account location - Defect# 22816
//v103 16-Jan-2019 Sanjay : Added the new field for update  - Defect# 23566
//v104 21-Feb-2019 Balashanthi A : Added Apttus_Config2__BillingPreferenceId__c,APTS_Payment_Method__c,Apttus_Config2__PaymentTermId__c @ getOrder() Method SOQL
//v105 08-Mar-2019 Balashanthi A : Defect # 5662 LAE/RAR Missing Hierarchy level in XD09 recurring billing orders
//v106 12-Mar-2019 Akanksha : Defect# 5632,6373 Added field APTS_Status__c in getOrder() method.
//v107 4-Apr-2019 Nikita : Defect# 6373 Added field APTS_Status__c in getOrder() method.
//v108 8-Apr-2019 Akanksha : CR 2259 Added fields in methods getorder() and getAssetLineItems()
//v109 17-Apr-2019 Aarthi: Defect #6723 Added fields in getOrderLineItems()
//v113 17-Apr-2019 Sanjay Nair : Added fields in getOrderLineItems() - Defect #6329
//v114 22-May-2019 Nikita Modi : Delivery only
//v115 27-May-2019 Aarthi Pitchai : Delivery only - DOKOM-123
//v116 14-Aug-2019 Aarthi Pitchai : QTCFLEX1-579 - ZX10 to be determined from Asset adjustments in case of deInstall
//v117 28-Aug-2019 Renuka : DFT2C-1017 Added Partner fields in getOrder()
//v118 11-Sep-2019 Aarthi : QTCFLEX1-1205 - Set contract details on DeInstall OLIs
//v119 17-Oct-2019 Aarthi : QTCFLEX1-12- Renewal changes
//v120 25-Aug-2020 Venky Muppalaneni : DQ-3470 Adding Sub Sub Type
//v121 09-Sept-2020 Renuka : DQ-3265 Added fields related to TerminatedPhA getAssetLineItems()
//V122 15-Sep-2020 Aarthi: DQ-3716 Physical Movement related changes
//V123 09-Oct-2020 Aarthi : DQ-3205 : PhA field updates on XA13 case cancellation
//V124 05-Apr-2021 Aarthi : DQ-5898 : CTC related fields addition in OLI query

without sharing public class APTS_OrderLineItemDAO {

    public static Map<Id, Apttus_Config2__OrderLineItem__c> getOrderLineItems(Set<Id> orderLineItemIdSet) {
        // Added APTS_SAP_OrderType__c in the below query for Defect # 5662
        Map<Id, Apttus_Config2__OrderLineItem__c> idToOrderLineItemMap = new Map<Id, Apttus_Config2__OrderLineItem__c>([
                    SELECT Id,
                    Name,
                    APTS_SAP_OrderType__c,
                    Apttus_Config2__DerivedFromId__r.APTS_CancelledDate__c,
                    APTS_Item_Relevant_for_SAP__c,
                    APTS_Serial_Number__c,
                    Apttus_Config2__OrderId__c,
                    APTS_Material_Availability_Date__c,
                    Apttus_Config2__IsPrimaryLine__c,
                    Apttus_Config2__OptionId__r.ProductCode,
                    Apttus_Config2__LineNumber__c,
                    Apttus_Config2__HasOptions__c,                    
                    APTS_Physical_Asset__r.SerialNumber__c,
                    Apttus_Config2__LineType__c,
                    Apttus_Config2__LineStatus__c,
                    Apttus_Config2__DerivedFromId__r.APTS_Agreement__c,
                    APTS_Item_Category__c,
                    Apttus_Config2__ChargeType__c,
                    Apttus_Config2__PriceType__c,
                    APTS_Net_List_Price_Condition__c,
                    Apttus_Config2__ListPrice__c,
                    APTS_Physical_Machine_Option__c,
                    APTS_Is_Primary_L1_Line__c,
                    APTS_ZX10__c,
                    APTS_Status__c,
                    Apttus_Config2__Status__c,
                    Apttus_Config2__NetPrice__c,
                    Apttus_Config2__BasePrice__c,
                    APTS_Type_of_Contract__c,
                    APTS_Net_List_Price__c,
                    APTS_Services_within_Machine__c,
                    APTS_Physical_Asset__c,
                    Apttus_Config2__AssetLineItemId__c,
                    APTS_Parent_Order_Line_Item__c,
                    APTS_Batch__c,
                    APTS_Type_Of_Contract_IC__c,
                    APTS_De_installation_Date_Authorized__c,
                    APTS_Installation_Date_Authorized__c,
                    Apttus_Config2__PreviousVersion__c,
                    APTS_Reason_For_Rejection__c,
                    APTS_Refurbished_or_New__c,
                    APTS_Option_Group_Text__c,
                    APTS_ATP_Cleared__c,

                    Apttus_Config2__OrderId__r.APTS_Order_Header_SAP_ID__c,
                    Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c,
                    Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c,
                    Apttus_Config2__OrderId__r.APTS_Order_Type__c,
                    Apttus_Config2__OrderId__r.APTS_Contract_Change__c, //DQ-56
                    APTS_RefurbishedMachine__c,
                    APTS_Is_Primary_L1_Parent__c,

                    Apttus_Config2__ProductId__r.Apttus_Config2__ConfigurationType__c,
                    Apttus_Config2__ProductId__r.APTS_Material_Type__c,
                    Apttus_Config2__ProductId__r.APTS_Vendor_Code__c,
                    Apttus_Config2__ProductId__r.APTS_Not_relevant_for_SAP__c,  //Def#21466
                    Apttus_Config2__OptionId__r.APTS_Material_Type__c,
                    Apttus_Config2__OptionId__r.APTS_Plug_and_Play_Indicator__c,
                    APTS_PlugPlay__c,
                    Apttus_CMConfig__AgreementLineItemId__r.Apttus_CMConfig__SellingTerm__c,
                    Apttus_CMConfig__AgreementLineItemId__c,
                    Apttus_Config2__DerivedFromId__c,
                    Apttus_Config2__DerivedFromId__r.APTS_Agreement_Line_Item__c,
                    Apttus_Config2__DerivedFromId__r.Apttus_Config2__OptionGroupLabel__c,
                    Apttus_Config2__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Allow_sales_price_for_options__c,
                    Apttus_Config2__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Type_of_contract__c,
                    Apttus_Config2__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Refurbished__c,
                    Apttus_Config2__DerivedFromId__r.APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingTerm__c,
                    Apttus_Config2__DerivedFromId__r.Apttus_Config2__NetAdjustmentPercent__c,
                    Apttus_Config2__DerivedFromId__r.APTS_Asset_Change_type__c,
                    Apttus_Config2__DerivedFromId__r.APTS_Terminated_Asset_Line__c, //V124 ++ 
                    Apttus_Config2__DerivedFromId__r.APTS_Terminated_Asset_Line__r.APTS_Installation_Sales_Order_Item__c, //V124 ++ 
            //v103 << ++
                    APTS_Item_Category_Adjustment__c,
            //v103 -->>
            //v109 << ++
                    Apttus_Config2__BasePriceOverride__c,
            //v109 >> ++
                    APTS_Installation_Contact__c,
                    APTS_Installation_Contact__r.MobilePhone,
                    APTS_Installation_Contact__r.Phone,
                    APTS_Installation_Contact_Phone__c,
            //v114  << ++  
                    Apttus_Config2__DerivedFromId__r.APTS_Order_LSP_Detail__r.APTS_Require_Installation__c,
                    Apttus_Config2__DerivedFromId__r.APTS_Order_LSP_Detail__r.APTS_Require_De_Installation__c,
            //v114  -- >>
            //v115  << ++ 
            APTS_Installation_Required__c,
            APTS_De_Installation_Required__c,
            //v115  >> ++ 
            //V118 ++ <<
            Apttus_Config2__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c,
            Apttus_Config2__AssetLineItemId__r.Apttus_CMConfig__AgreementLineItemId__c,
            //V118 ++ >>
            Apttus_Config2__AssetLineItemId__r.APTS_Is_Primary_L1_Line__c,
            Apttus_Config2__OrderId__r.APTS_Scenario__c
                    FROM Apttus_Config2__OrderLineItem__c
                    WHERE Id IN :orderLineItemIdSet ]);

        return idToOrderLineItemMap;
    }

    public static Map<Id, Apttus_Config2__OrderLineItem__c> getAllOrderLineItems(Set<Id> orderIdSet) {

        Map<Id, Apttus_Config2__OrderLineItem__c> idToOrderLineItemMap = new Map<Id, Apttus_Config2__OrderLineItem__c>([
                    SELECT Id,
                    APTS_Status__c,
                    Apttus_Config2__Status__c,
                    Apttus_Config2__StartDate__c,
                    Apttus_Config2__EndDate__c,
                    Apttus_Config2__SellingTerm__c,
                    Apttus_Config2__ChargeType__c,
                    Apttus_Config2__PriceType__c,
                    APTS_Option_Group_Text__c,
                    Apttus_Config2__OrderId__r.APTS_Contract_Change__c,//DQ-56
                    Apttus_Config2__DerivedFromId__r.APTS_CancelledDate__c,
                    Apttus_Config2__LineStatus__c,
                    Apttus_Config2__LineType__c,
                    APTS_Is_Primary_L1_Line__c,
                    Apttus_Config2__DerivedFromId__r.APTS_Terminated_Asset_Line__r.APTS_Type_Of_Contract__c,//DQ-56
                    Apttus_Config2__LineNumber__c,
                    Apttus_Config2__IsPrimaryLine__c,
                    Apttus_Config2__HasOptions__c,
                    APTS_Item_Relevant_for_SAP__c,
                    APTS_ATP_Cleared__c ,
                    APTS_Material_Availability_Date__c ,
                    Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c,
                    Apttus_Config2__AttributeValueId__r.APTS_Number_of_months__c,
                    APTS_Type_of_contract__c,
                    Apttus_Config2__SellingFrequency__c,
                    Apttus_Config2__OrderId__c,
                    APTS_Reason_For_Rejection__c,
                    Apttus_Config2__AssetLineItemId__c,
                    Apttus_Config2__AssetLineItemId__r.Apttus_Config2__SellingTerm__c,
                    Apttus_Config2__OrderId__r.Apttus_CMConfig__AgreementId__c,
                    Apttus_Config2__OrderId__r.Apttus_CMConfig__AgreementId__r.Apttus__Subtype__c,
                    Apttus_Config2__OrderId__r.Apttus_CMConfig__AgreementId__r.Apttus__Contract_End_Date__c,
                    Apttus_CMConfig__AgreementLineItemId__c,
                    Apttus_CMConfig__AgreementLineItemId__r.Apttus_CMConfig__StartDate__c,
                    Apttus_Config2__ProductId__r.APTS_Not_relevant_for_SAP__c, 
                    APTS_RefurbishedMachine__c,
                    //v115  << ++ 
            APTS_Installation_Required__c,
            APTS_De_Installation_Required__c,
            APTS_Physical_Asset__c,
            //v115  >> ++  //V122 ++ <<
            APTS_Physical_Asset__r.InitialActivationDate__c, APTS_SAP_OrderType__c, //V123++<<>>
            Apttus_Config2__LocationId__c, 
            Apttus_Config2__OrderId__r.APTS_Sales_Organization__c, Apttus_Config2__OrderId__r.Apttus_Config2__SoldToAccountId__c, Apttus_Config2__AssetLineItemId__r.APTS_OwnedByCustomer__c, Apttus_CMConfig__AgreementId__r.RecordType.Name, Apttus_CMConfig__AgreementId__r.APTS_Routesales__c, 
            APTS_Order_LSP_Detail__c,
            APTS_Order_LSP_Detail__r.APTS_ConfigurationFileURL__c,
            APTS_Order_LSP_Detail__r.APTS_JDE_crockeryVolumeSize__c,
            APTS_Order_LSP_Detail__r.APTS_Building__c,
            APTS_Order_LSP_Detail__r.APTS_Floor__c,
            APTS_Order_LSP_Detail__r.APTS_Area__c,
            APTS_Order_LSP_Detail__r.APTS_CustomerReference__c,
            APTS_Order_LSP_Detail__r.APTS_SmokingArea__c,
            APTS_Order_LSP_Detail__r.APTS_ConfigurationManualAgreementsURL__c,  //V122 ++ >>
            Apttus_Config2__ReadyForBillingDate__c
            FROM Apttus_Config2__OrderLineItem__c
                    WHERE Apttus_Config2__OrderId__c IN :orderIdSet ]);

        return idToOrderLineItemMap;
    }

    public static Map<Id, Apttus_Config2__Order__c> getOrder(Set<Id> orderIdSet) {

        Map<Id, Apttus_Config2__Order__c> idToOrderMap = new Map<Id, Apttus_Config2__Order__c>([
                    SELECT Id,
                    APTS_Status__c,APTS_Invoice__c,
                    Apttus_CMConfig__AgreementId__c,
                    APTS_Contract_Change__c,
                    APTS_Order_Type__c ,
                    APTS_Order_Sub_Type__c,
                    APTS_Order_Sub_Sub_Type__c,//v120
                    APTS_Requested_De_Installation_Date__c,
                    APTS_Requested_Installation_Date__c,
                    APTS_Location_From__c,
                    Apttus_Config2__LocationId__c,
                    APTS_Movement_From_Account__c,
                    APTS_SAP_OrderType__c,
                    APTS_Fix_Term_Billing_Flag__c,
                    Apttus_Config2__Status__c,
                    APTS_Order_Reason__c,
                    APTS_Order_Selling_Term__c,
                    Apttus_Config2__OrderStartDate__c,
                    Apttus_Config2__OrderEndDate__c,
                    Apttus_Config2__BillingPreferenceId__c,
                    APTS_Payment_Method__c,
                    Apttus_Config2__PaymentTermId__c,
                    APTS_IsPGICompleted__c,
                    APTS_Order_Batch_Status__c,
                    APTS_LSP_Required_Indicator__c,
                    APTS_ATP_Check_Status__c,
                    Apttus_CMConfig__AgreementId__r.Apttus__Auto_Renewal__c,
                    Apttus_CMConfig__AgreementId__r.APTS_Bill_to_Party_Ingredients__c,
                    Apttus_CMConfig__AgreementId__r.APTS_Bill_to_Party_MachServ__c,
                    Apttus_CMConfig__AgreementId__r.APTS_Payer_Ingredients__c,
                    Apttus_CMConfig__AgreementId__r.APTS_Payer_Machines_Services__c,
                    APTS_Bill_to_Party_Ingredients_and_Payer__c,
                    APTS_Bill_to_Party_Machines_Services__c,
                    APTS_PayerIngredients__c,
                    APTS_PayerMachinesServices__c,
                    APTS_Auto_renewal_staging_source_id__c,   //V119 ++<<>>    
                    APTS_Credit_Memo__c,
                    Apttus_CMConfig__AgreementId__r.recordtype.name,APTS_Scenario__c        
                    FROM Apttus_Config2__Order__c
                    WHERE Id IN :orderIdSet ]);

        return idToOrderMap;
    }

    public static Map<Id, Apttus_Config2__AssetLineItem__c> getAssetLineItems(Set<Id> assetIdSet) {

        Map<Id, Apttus_Config2__AssetLineItem__c> idToAssetLineItemMap = new Map<Id, Apttus_Config2__AssetLineItem__c>([
                    SELECT Id,
                    APTS_Physical_Asset__c,
                    APTS_Physical_Asset__r.SerialNumber__c,
                    APTS_Physical_Asset__r.InitialActivationDate__c,
                    APTS_Physical_Asset__r.APTS_FinanceId__c,
                    Apttus_Config2__ProductId__c,
                    Apttus_Config2__ProductId__r.APTS_LSP_Required__c,
                    APTS_Terminated_Physical_Asset__c,
                    APTS_Terminated_PHA_serial_number__c,
                    Apttus_Config2__AssetStatus__c,
                    APTS_Option_Group_Text__c
                    FROM Apttus_Config2__AssetLineItem__c
                    WHERE Id IN :assetIdSet ]);

        return idToAssetLineItemMap;
    }

    /*public static Map<Id, Apttus__APTS_Agreement__c> getAgreementLineItems(Set<Id> agreementIdSet) {

        Map<Id, Apttus__APTS_Agreement__c> agreementMap = new Map<Id, Apttus__APTS_Agreement__c>([
                    SELECT Id,
                    Name,
                    Apttus__Auto_Renewal__c,
                    APTS_Bill_to_Party_Ingredients__c,
                    APTS_Bill_to_Party_MachServ__c,
                    APTS_Payer_Ingredients__c,
                    APTS_Payer_Machines_Services__c
                    FROM Apttus__APTS_Agreement__c
                    WHERE Id IN: agreementIdSet]);

        return agreementMap;
    }*/

    public static Map<Id, APTS_ItemCategoryDetermination__c> getItemCategoryDetermination() {

        Map<Id, APTS_ItemCategoryDetermination__c> itemCategoryDeterminationMap = new Map<Id, APTS_ItemCategoryDetermination__c>([
                    SELECT APTS_Type_Of_Contract__c,
                    APTS_Charge_Type__c,
                    APTS_ZX10__c,
                    APTS_SAP_Order_Type_List__c,
                    APTS_Item_Category__c,
                    YOCI_YOFT__c
                    FROM APTS_ItemCategoryDetermination__c]);

        return itemCategoryDeterminationMap;
    }

    public static Map<Id, APTS_ItemRelevancyDetermination__c> getItemRelevancyDetermination() {

        Map<Id, APTS_ItemRelevancyDetermination__c> itemRelevancyDeterminationMap = new Map<Id, APTS_ItemRelevancyDetermination__c>([
                    SELECT APTS_Contract_Type__c,
                    APTS_Charge_Type__c,
                    APTS_SAP_Order_Type_List__c
                    FROM APTS_ItemRelevancyDetermination__c]);

        return itemRelevancyDeterminationMap;
    }

    public static Map<Id, WorkOrderTrigger__c> getWorkOrderTrigger(Set<Id> orderLineItemIdSet) {

        Map<Id, WorkOrderTrigger__c> idToWorkOrderTriggerMap = new Map<Id, WorkOrderTrigger__c>([
                    SELECT Id,PhysicalAsset__c,
                    OrderLineItem__c
                    FROM WorkOrderTrigger__c
                    WHERE OrderLineItem__c IN :orderLineItemIdSet]);

        return idToWorkOrderTriggerMap;
    }

    public static Map<Id, WorkOrderLineItem> getWorkOrderLineItem(Set<Id> orderLineItemIdSet) {

        Map<Id, WorkOrderLineItem> idToWorkOrderLineItemMap = new Map<Id, WorkOrderLineItem>([
                    SELECT Id,PhysicalAsset__c,Status,StatusCategory,
                    OrderLineItem__c
                    FROM WorkOrderLineItem
                    WHERE OrderLineItem__c IN :orderLineItemIdSet]);
        //system.debug('idToWorkOrderLineItemMap$$' +idToWorkOrderLineItemMap);
        return idToWorkOrderLineItemMap;
    } 

    public static Map<Id, APTS_Agreement_PO_Details__c> getAgreementPODetails(Set<Id> agreementIdSet) {

        Map<Id, APTS_Agreement_PO_Details__c> idToAgreementPODetailsMap = new Map<Id, APTS_Agreement_PO_Details__c>([
                    SELECT Id,
                    APTS_Agreement__c,
                    APTS_PO_Number__c,
                    APTS_PO_Number_Required__c,
                    APTS_PO_Category__c,
                    APTS_PO_Number_Type__c
                    FROM APTS_Agreement_PO_Details__c
                    WHERE APTS_Agreement__c IN :agreementIdSet ]);

        return idToAgreementPODetailsMap;
    }

    public static Map<Id, PhysicalAsset__c> getPhysicalAsset(Set<String> serialNumberSet) {

        Map<Id, PhysicalAsset__c> idToPhysicalAssetMap = new Map<Id, PhysicalAsset__c>([
                    SELECT Id,
                    UniqueNumber__c, APTS_FinanceId__c
                    FROM PhysicalAsset__c
                    WHERE UniqueNumber__c IN :serialNumberSet ]) ;

        return idToPhysicalAssetMap;
    }

    public static Map<Id, Apttus_Config2__OrderLineItem__c> getOrderLineItemByParentOLI(Set<String> parentOLIIdSet) {

        Map<Id, Apttus_Config2__OrderLineItem__c> idToOrderLineItem = new Map<Id, Apttus_Config2__OrderLineItem__c>([
                    SELECT Id,
                    APTS_Physical_Asset__c,
                    APTS_Parent_Order_Line_Item__c
                    FROM Apttus_Config2__OrderLineItem__c
                    WHERE APTS_Parent_Order_Line_Item__c IN :parentOLIIdSet]);

        return idToOrderLineItem;
    }

    public static Map<Id, Apttus_Config2__AdjustmentLineItem__c> getAdjustmentLineItems(Set<id> lineItemIdSet) {

        Map<Id, Apttus_Config2__AdjustmentLineItem__c> idToAdjustmentLineItem = new Map<Id, Apttus_Config2__AdjustmentLineItem__c>([
                    SELECT Id,
                    Apttus_Config2__LineItemId__r.Apttus_Config2__LineType__c,
                    Apttus_Config2__LineNumber__c,
                    Apttus_Config2__SubType__c,
                    Apttus_Config2__LineItemId__c,
                    Apttus_Config2__AdjustmentAmount__c,
                    Apttus_Config2__LineItemId__r.Apttus_Config2__LineNumber__c
                    FROM Apttus_Config2__AdjustmentLineItem__c
                    WHERE Apttus_Config2__LineItemId__c IN: lineItemIdSet ]);

        return idToAdjustmentLineItem;
    }
     public static Map<Id, Apttus_Config2__OrderAdjustmentLineItem__c> getOrderAdjustmentLineItems(Set<id> orderLineItemIdSet) {

        Map<Id, Apttus_Config2__OrderAdjustmentLineItem__c> idToAdjustmentLineItem = new Map<Id, Apttus_Config2__OrderAdjustmentLineItem__c>([
                    SELECT Id,
                    Apttus_Config2__LineType__c,
                    Apttus_Config2__LineNumber__c,
                    Apttus_Config2__SubType__c,
                    Apttus_Config2__LineItemId__c,
                    Apttus_Config2__LineItemId__r.Apttus_Config2__LineNumber__c
                    FROM Apttus_Config2__OrderAdjustmentLineItem__c
                    WHERE Apttus_Config2__LineItemId__c IN: orderLineItemIdSet ]);

        return idToAdjustmentLineItem;
    }
    //V116 ++ <<
    public static Map<Id, Apttus_Config2_AssetAdjustItem__c> getAssetAdjustmentLineItems(Set<id> assetIdSet) {

        Map<Id, Apttus_Config2_AssetAdjustItem__c> idToAdjustmentLineItem = new Map<Id, Apttus_Config2_AssetAdjustItem__c>([
                    SELECT Id,
                    Apttus_Config2_AssetLineItemId__r.Apttus_Config2__LineType__c,
                    Apttus_Config2_LineNumber__c,
                    Apttus_Config2_SubType__c,
                    Apttus_Config2_AssetLineItemId__c,
                    Apttus_Config2_AssetLineItemId__r.Apttus_Config2__LineNumber__c
                    FROM Apttus_Config2_AssetAdjustItem__c
                    WHERE Apttus_Config2_AssetLineItemId__c IN: assetIdSet ]);

        return idToAdjustmentLineItem;
    }
    //V116 ++ >>
    
    public static Map<Id, Apttus_Config2__AccountLocation__c> getAccountLocation(Set<Id> accountLocIdSet) {
        
        Map<Id, Apttus_Config2__AccountLocation__c> idToAccountLocMap = new Map<Id, Apttus_Config2__AccountLocation__c>([
                    SELECT id,
                    Monday_Afternoon_From_Receiving__c,
                    Monday_Afternoon_To_Receiving__c,
                    Monday_Morning_From_Receiving__c,
                    Monday_Morning_To_Receiving__c,
                    Tuesday_Afternoon_From_Receiving__c,
                    Tuesday_Afternoon_To_Receiving__c,
                    Tuesday_Morning_From_Receiving__c,
                    Tuesday_Morning_To_Receiving__c,
                    Wednesday_Afternoon_From_Receiving__c,
                    Wednesday_Afternoon_To_Receiving__c,
                    Wednesday_Morning_From_Receiving__c,
                    Wednesday_Morning_To_Receiving__c,
                    Thursday_Afternoon_From_Receiving__c,
                    Thursday_Afternoon_To_Receiving__c,
                    Thursday_Morning_From_Receiving__c,
                    Thursday_Morning_To_Receiving__c,
                    Friday_Afternoon_From_Receiving__c,
                    Friday_Afternoon_To_Receiving__c,
                    Friday_Morning_From_Receiving__c,
                    Friday_Morning_To_Receiving__c,
                    Saturday_Afternoon_From_Receiving__c,
                    Saturday_Afternoon_To_Receiving__c,
                    Saturday_Morning_From_Receiving__c,
                    Saturday_Morning_To_Receiving__c,
                    Sunday_Afternoon_From_Receiving__c,
                    Sunday_Afternoon_To_Receiving__c,
                    Sunday_Morning_From_Receiving__c,
                    Sunday_Morning_To_Receiving__c
                    from Apttus_Config2__AccountLocation__c where id IN: accountLocIdSet]);
        
        return idToAccountLocMap;
                                                        
    }
    
     //@Description : Method to get the getOrderLineItems 
    public static List<Apttus_Config2__OrderLineItem__c> getOrderLineItemstoOrder(Set<Id> orderIdSet) {

        List<Apttus_Config2__OrderLineItem__c> orderLineItemList = [SELECT Id,
        Apttus_Config2__ProductId__r.Name ,Apttus_Config2__OptionId__r.Name,
        Apttus_Config2__OptionId__r.ProductCode,Apttus_Config2__ProductId__r.ProductCode,
                                               Apttus_Config2__OrderId__c,
                                               Apttus_Config2__ChargeType__c,
                                               APTS_Type_of_Contract__c,
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
                                               APTS_Physical_Asset__r.Name,
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
                                               APTS_Item_Category_Adjustment__c,
                                               Apttus_Config2__OrderId__r.APTS_Order_Type__c, APTS_ATP_Check_Status__c , APTS_Reason_For_Rejection__c,
                                               APTS_Treated_By_Activation_Batch__c,Apttus_Config2__AssetLineItemId__r.APTS_Is_Primary_L1_Line__c
                                               FROM Apttus_Config2__OrderLineItem__c
                                               WHERE Apttus_Config2__OrderId__c IN :orderIdSet];

        
        return orderLineItemList;
    }

}