/*************************************************************
@Name: APTS_OrderLineItemUtils
@Author: Galin Georgiev
@CreateDate: 14-03-2018
@Description: Order line item utils
@UsedBy:
******************************************************************/
//v100 14-03-2018 Galin Georgiev: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes
//V101 01-Jun-2019 Aarthi : DOK31-207 Phsyical Asset update on Movement order
//v102 22 July -2019: Sai - DFT2C-740 
//v103 30 July -2019: Sai - DFT2C-1050
//v104 15 Aug -2019: Sai - DFT2C-1158
//v105 21st Aug -2019: Sai - DFT2C-1101
//v106 27th Aug - 2019: Sai - DFT2C-1332 TOC "Sales" Date FIX on PA
//v107 13th Sep - 2019: Sai - DFT2C-1429 TOC "Sales" Warranty Date FIX
//v108 12 Oct - 2019: Sai - DFT2C-1552
//v109 12 Oct - 2019: Sanjay - DFT2C-1511 PA-address - Use from Account Location Instead of Sold to Account 
//V11 5 Nov 2019: Renuka - QTCFLEX1-1584 Added PhysicalAsset Name in getPhysicalAsset(). 
//v12 - dq-56 Waranty Dates reset if there is no waranty,PHA status updation for Asset contract Change
//V113 14-Sep-2020 Aarthi : DQ-3716 Physical Asset Update logic readdition on Physical Movement Orders
//v114 19-Nov-2020 Manisha: DQ-3293 Configuring the WTSChangedby attribute
//V115 21-Jan-2021 Aarthi: DQ-4117 Billing settings issue fix
//V116 09-Feb-2021 Renuka: DQ-5187 Populating Last WTS date and Last Prev Maint date field.
//V117 09-Feb-2021 Renuka: DQ-5194 Populating Planogram Number in PhA.

public without sharing class APTS_OrderLineItemUtils {

    private static final String ACTIVATED = System.Label.APTS_Activated;
    private static final String IN_EFFECT = 'In Effect';
    private static final String OPTION = System.Label.APTS_Option;
    private static final String BUNDLE = System.Label.APTS_Bundle;
    private static final String EMAIL = System.Label.APTS_Email;
    private static final String JDE_ENGINEER = 'JDE Engineer';
    private static final List<Schema.PicklistEntry> machineCareField ;
    //private static Map<String,String> mapOfwtsChangeOLI = new Map<String,String>();
    
    static{
        Schema.DescribeFieldResult physicalassetFields = PhysicalAsset__c.Machine_Care__c.getDescribe();
        machineCareField = physicalassetFields.getPicklistValues();
       }

    /* Logic Added by the Shanmuga Prasath for Creating the Physical Asset of Option Type Which is Used by CLM Team*/
    public static Map<Id, Apttus_Config2__OrderLineItem__c> getOrderLineItemAdditionalData(Set<Id> orderLineItemIdSet) {

        Map<Id, Apttus_Config2__OrderLineItem__c> idToOrderLineItemMap = new Map<Id, Apttus_Config2__OrderLineItem__c>([
                    SELECT Id, Name, Apttus_Config2__LocationId__c, APTS_Machine_Age__c,
                    APTS_Serial_Number__c, APTS_Goods_Issue_Date__c, APTS_RefurbishedMachine__c,
                    Apttus_Config2__LineType__c, APTS_Physical_Asset__c, Apttus_Config2__ParentBundleNumber__c,
                    Apttus_Config2__LineNumber__c, Apttus_Config2__ChargeType__c, Apttus_Config2__HasOptions__c,
                    APTS_De_installation_Date__c, APTS_Option_Group_Text__c, APTS_Serial_Number2__c,
                    APTS_Type_of_Contract__c,Apttus_Config2__LineStatus__c,Apttus_Config2__Quantity__c,
                    APTS_Is_Primary_L1_Line__c, APTS_Batch__c ,
                    // v102 Sai-JIRA-DFT2C-740 
                    APTS_Parent_Order_Line_Item__c,                    
                    Apttus_Config2__AssetLineItemId__c, Apttus_Config2__Description__c,
                    Apttus_Config2__AssetLineItemId__r.APTS_RefurbishedMachine__c,
                    Apttus_Config2__AssetLineItemId__r.Apttus_Config2__StartDate__c,
                    Apttus_Config2__AssetLineItemId__r.Apttus_Config2__EndDate__c,
                    Apttus_Config2__AssetLineItemId__r.Apttus_Config2__AssetStatus__c,
                    Apttus_Config2__AssetLineItemId__r.APTS_Physical_Asset__c,
                    Apttus_Config2__AssetLineItemId__r.APTS_OwnedByCustomer__c,

                    Apttus_CMConfig__AgreementId__c,
                    Apttus_CMConfig__AgreementId__r.RecordType.DeveloperName,
                    Apttus_CMConfig__AgreementId__r.RecordType.Name,
                    Apttus_CMConfig__AgreementId__r.Apttus__Status_Category__c,
                    Apttus_CMConfig__AgreementId__r.Apttus__Status__c,
                    Apttus_CMConfig__AgreementId__r.APTS_Routesales__c,
                    Apttus_CMConfig__AgreementId__r.APTS_Check_on_Account_Machines__c, 
                    Apttus_Config2__OrderId__r.APTS_Contract_Change__c, 
                    Apttus_Config2__DerivedFromId__r.APTS_Terminated_Asset_Line__c,
                    Apttus_Config2__DerivedFromId__r.APTS_Terminated_Asset_Line__r.APTS_PhysicalAssetExtId__c,
                    APTS_Order_LSP_Detail__c,
                    APTS_Order_LSP_Detail__r.APTS_Building__c,
                    APTS_Order_LSP_Detail__r.APTS_Floor__c,
                    APTS_Order_LSP_Detail__r.APTS_Area__c,
                    APTS_Order_LSP_Detail__r.APTS_CustomerReference__c,
                    APTS_Order_LSP_Detail__r.APTS_SmokingArea__c,
                    APTS_Order_LSP_Detail__r.APTS_ConfigurationFileURL__c,
                    APTS_Order_LSP_Detail__r.APTS_JDE_crockeryVolumeSize__c,
                    APTS_Order_LSP_Detail__r.APTS_ConfigurationManualAgreementsURL__c,

                    Apttus_Config2__OrderId__c,
                    Apttus_Config2__OrderId__r.Apttus_Config2__PONumber__c,
                    Apttus_Config2__OrderId__r.APTS_Sales_Organization__c,
                    Apttus_Config2__OrderId__r.Apttus_Config2__SoldToAccountId__c,
                    Apttus_Config2__OrderId__r.APTS_Confirmed_De_Installation_Date__c,
                    Apttus_Config2__OrderId__r.APTS_Confirmed_Installation_Date__c,
                    Apttus_Config2__OrderId__r.APTS_Merchant_ID__c,
                    Apttus_Config2__OrderId__r.APTS_Closed_User_Group_Code_1__c,
                    Apttus_Config2__OrderId__r.APTS_Closed_User_Group_Code_2__c,
                    Apttus_Config2__OrderId__r.APTS_Closed_User_Group_Code_3__c,

                    Apttus_Config2__AttributeValueId__c,
                    Apttus_Config2__AttributeValueId__r.APTS_Number_of_months__c,
                    Apttus_Config2__AttributeValueId__r.APTS_Call_Out_Coverage_Percent__c,
                    Apttus_Config2__AttributeValueId__r.APTS_Labour_Coverage_Percent__c,
                    Apttus_Config2__AttributeValueId__r.APTS_Spare_Parts_Coverage_Percent__c,
                    Apttus_Config2__AttributeValueId__r.APTS_WTS_Changed_By__c,
                    Apttus_Config2__AttributeValueId__r.APTS_Service_Window__c,
                    Apttus_Config2__AttributeValueId__r.APTS_Response_Profile__c,
                    Apttus_Config2__AttributeValueId__r.APTS_Merchant__c,
                    Apttus_Config2__AttributeValueId__r.APTS_Consumer_Price__c,
                    Apttus_Config2__AttributeValueId__r.APTS_Cup_Size__c,
                    Apttus_Config2__AttributeValueId__r.APTS_Taste_Pallet__c,
                    Apttus_Config2__AttributeValueId__r.APTS_Type_of_payment__c,
                    Apttus_Config2__AttributeValueId__r.APTS_Number_of_hours_per_month__c,
                    Apttus_Config2__AttributeValueId__r.APTS_First_Line_Response_Time__c,

                    Apttus_Config2__ProductId__c,
                    Apttus_Config2__ProductId__r.Name,
                    Apttus_Config2__ProductId__r.Description,
                    Apttus_Config2__ProductId__r.ProductCode,
                    Apttus_Config2__ProductId__r.APTS_Material_Type__c,
                    Apttus_Config2__ProductId__r.Apttus_Config2__ConfigurationType__c,
                    Apttus_Config2__ProductId__r.APTS_Vendor_Code__c,
                    Apttus_Config2__OptionId__c,
                    Apttus_Config2__OptionId__r.Name,
                    Apttus_Config2__OptionId__r.Description,
                    Apttus_Config2__OptionId__r.ProductCode,
                    Apttus_Config2__OptionId__r.APTS_Material_Type__c,
                    Apttus_Config2__OptionId__r.APTS_Response_Time_Hours__c,
                    Apttus_Config2__OptionId__r.Water_Filter_Replacement__c,
                    Apttus_Config2__OptionId__r.APTS_Full_Operating__c,

                //v109 <<++ PA - Address fetch from Account Location
                    Apttus_Config2__ShipToAccountId__c,
                    Apttus_Config2__LocationId__r.Shipping_Country__c,
                    Apttus_Config2__LocationId__r.Shipping_Country_ISO__c,
                    Apttus_Config2__LocationId__r.Apttus_Config2__PostalCode__c,
                    Apttus_Config2__LocationId__r.Apttus_Config2__Street__c,
                    Apttus_Config2__LocationId__r.Shipping_House_Number__c,
                    Apttus_Config2__LocationId__r.Apttus_Config2__City__c,
            //v109 ++>>
                    //V101 ++ <<        
                    APTS_SAP_OrderType__c       
                    //V101 ++ >>        
                    FROM Apttus_Config2__OrderLineItem__c
                    WHERE Id IN :orderLineItemIdSet AND Apttus_Config2__LineStatus__c != 'Cancelled']);
        return idToOrderLineItemMap;
    }

    public static PhysicalAsset__c createPhysicalAsset(Apttus_Config2__OrderLineItem__c oOrderLineItem) {

        PhysicalAsset__c oPhysicalAsset;
        Boolean bCreateMachinePhysicalAsset = false;
        Boolean bCreateOptionPhysicalAsset = false;
        
        
        //try{
        if (oOrderLineItem.Apttus_Config2__ProductId__c != null && oOrderLineItem.Apttus_Config2__ProductId__r.APTS_Material_Type__c != null && oOrderLineItem.Apttus_Config2__HasOptions__c && oOrderLineItem.Apttus_Config2__ProductId__r.APTS_Material_Type__c == 'ZCMA') {
            bCreateMachinePhysicalAsset = true;
        } else if (oOrderLineItem.Apttus_Config2__OptionId__c != null && oOrderLineItem.Apttus_Config2__OptionId__r.APTS_Material_Type__c != null && oOrderLineItem.Apttus_Config2__LineType__c == OPTION && oOrderLineItem.Apttus_Config2__OptionId__r.APTS_Material_Type__c == 'ZOPT') {
            bCreateOptionPhysicalAsset = true;
        }

        if (bCreateMachinePhysicalAsset || bCreateOptionPhysicalAsset) {

            oPhysicalAsset = new PhysicalAsset__c();

            if (bCreateMachinePhysicalAsset) {
                oPhysicalAsset.RecordTypeId = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get('Machine').getRecordTypeId();
            } else if (bCreateOptionPhysicalAsset) {
                oPhysicalAsset.RecordTypeId = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get('Option').getRecordTypeId();
            }
            
            oPhysicalAsset.Name = oOrderLineItem.Apttus_Config2__Description__c;
            
             if(!bCreateOptionPhysicalAsset){
                 
                /*String serialNumber = oOrderLineItem.APTS_Serial_Number__c;
                if (serialNumber != null) {
                    Pattern myPattern = pattern.compile('(a-zA-Z)'); 
                    matcher myMatcher = myPattern.matcher(serialNumber.substring(0,1));
                    if (myMatcher.matches()) {
                        serialNumber = serialNumber.substring(1);
                    }
                    String vendorCode = oOrderLineItem.Apttus_Config2__ProductId__r.APTS_Vendor_Code__c;
                    if(oOrderLineItem.Apttus_Config2__ProductId__r.APTS_Vendor_Code__c != null) {
                        oPhysicalAsset.UniqueNumber__c = vendorCode + serialNumber;
                    } else {
                        oPhysicalAsset.UniqueNumber__c = serialNumber;
                    }
                }*/
                
               
               if (oOrderLineItem.Apttus_Config2__ProductId__r.APTS_Vendor_Code__c != null && oOrderLineItem.APTS_Serial_Number__c != null) {
                    oPhysicalAsset.UniqueNumber__c = oOrderLineItem.Apttus_Config2__ProductId__r.APTS_Vendor_Code__c + oOrderLineItem.APTS_Serial_Number__c;
                } else if(oOrderLineItem.Apttus_Config2__ProductId__r.APTS_Vendor_Code__c == null && oOrderLineItem.APTS_Serial_Number__c != null){
                    oPhysicalAsset.UniqueNumber__c = oOrderLineItem.APTS_Serial_Number__c;
                } else if(oOrderLineItem.APTS_Serial_Number__c == null && oOrderLineItem.Apttus_Config2__ProductId__r.APTS_Vendor_Code__c != null){
                    oPhysicalAsset.UniqueNumber__c = oOrderLineItem.Apttus_Config2__ProductId__r.APTS_Vendor_Code__c;
                }
                oPhysicalAsset.Name = oPhysicalAsset.UniqueNumber__c;
             }
             
               
            if(bCreateOptionPhysicalAsset){
                oPhysicalAsset.Product__c = oOrderLineItem.Apttus_Config2__OptionId__c;
            }else{
                oPhysicalAsset.Product__c = oOrderLineItem.Apttus_Config2__ProductId__c;
            }
            
            //DQ-56 - Asset contract change - Bypass OLIdata flow to PHA on Finalisation 
            if(oOrderLineItem.Apttus_Config2__OrderId__r.APTS_Contract_Change__c!=null && !oOrderLineItem.Apttus_Config2__OrderId__r.APTS_Contract_Change__c.equalsIgnoreCase('Yes'))             
            oPhysicalAsset.AssetStatus__c = 'Pending Activation';
            else
            oPhysicalAsset.AssetStatus__c = 'Activated';
            //oPhysicalAsset.PONumberRequiredMachines__c = 'Yes';
            oPhysicalAsset.SerialNumber__c = oOrderLineItem.APTS_Serial_Number__c;
            oPhysicalAsset.AccountLocation__c =  oOrderLineItem.Apttus_Config2__LocationId__c;
            oPhysicalAsset.RefurbishedMachine__c = oOrderLineItem.APTS_RefurbishedMachine__c;
            oPhysicalAsset.DeInstallationDate__c = oOrderLineItem.APTS_De_installation_Date__c;
            //oPhysicalAsset.Connected__c = 'No';
            //oPhysicalAsset.CounterReading__c = 'No';

            if (oOrderLineItem.APTS_Option_Group_Text__c != null && oOrderLineItem.APTS_Option_Group_Text__c.containsIgnoreCase('Machine Care')) {
                /**if (oOrderLineItem.Apttus_Config2__Description__c.containsIgnoreCase('Comfort Operating')) {
                    oPhysicalAsset.Machine_Care__c = 'Comfort Operating';
                } else if (oOrderLineItem.Apttus_Config2__Description__c.containsIgnoreCase('Full Co Operating')) {
                    oPhysicalAsset.Machine_Care__c = 'Full Co Operating';
                } else if (oOrderLineItem.Apttus_Config2__Description__c.containsIgnoreCase('Full Operating')) {
                    oPhysicalAsset.Machine_Care__c = 'Full Operating';
                    oPhysicalAsset.CounterReading__c = 'Yes';
                }else if (oOrderLineItem.Apttus_Config2__Description__c.containsIgnoreCase('Semi Operating')) {
                    oPhysicalAsset.Machine_Care__c = 'Semi Operating';
                }else if (oOrderLineItem.Apttus_Config2__Description__c.containsIgnoreCase('Machine Clean Operating')) {
                    oPhysicalAsset.Machine_Care__c = 'Machine Clean Operating';
                }**/
                
                if(machineCareField != null){
                    for (Schema.PicklistEntry mapMachinecare : machineCareField){
                        if(oOrderLineItem.Apttus_Config2__Description__c.containsIgnoreCase(mapMachinecare.getLabel())){
                            oPhysicalAsset.Machine_Care__c = mapMachinecare.getLabel();
                        }
                    }
                }
                
                oPhysicalAsset.MachineCareHours__c = String.IsNotBlank(oOrderLineItem.Apttus_Config2__AttributeValueId__c) ? oOrderLineItem.Apttus_Config2__AttributeValueId__r.APTS_Number_of_hours_per_month__c : 0.00;
            }
            /*else{
                if (oPhysicalAsset != null && !oOrderLineItem.Apttus_Config2__Description__c.containsIgnoreCase('Full Operating')) {
                    oPhysicalAsset.Machine_Care__c = '';
                    oPhysicalAsset.CounterReading__c = 'No';
            }}*/

          

            oPhysicalAsset.SalesOrganization__c = oOrderLineItem.Apttus_Config2__OrderId__r.APTS_Sales_Organization__c;
            oPhysicalAsset.SoldTo__c = oOrderLineItem.Apttus_Config2__OrderId__r.Apttus_Config2__SoldToAccountId__c;
            oPhysicalAsset.PONumberMachines__c = oOrderLineItem.Apttus_Config2__OrderId__r.Apttus_Config2__PONumber__c; //Need to change
            if(oOrderLineItem.Apttus_Config2__OrderId__r.APTS_Contract_Change__c!=null && !oOrderLineItem.Apttus_Config2__OrderId__r.APTS_Contract_Change__c.equalsIgnoreCase('Yes'))   
            oPhysicalAsset.TypeOfContract__c = (String.IsNotBlank(oOrderLineItem.APTS_Type_of_Contract__c)) ? oOrderLineItem.APTS_Type_of_Contract__c : null;
            oPhysicalAsset.AgreementRecordType__c = oOrderLineItem.Apttus_CMConfig__AgreementId__r.RecordType.Name;
            oPhysicalAsset.ActiveContract__c = oOrderLineItem.Apttus_CMConfig__AgreementId__r.Apttus__Status_Category__c == IN_EFFECT && oOrderLineItem.Apttus_CMConfig__AgreementId__r.Apttus__Status__c == ACTIVATED;
            oPhysicalAsset.RefurbishedMachine__c= oOrderLineItem.APTS_RefurbishedMachine__c;
            
            oPhysicalAsset = updateLSPDetailOnPhA(oPhysicalAsset, oOrderLineItem, true);  //V113 ++ << >>          
            
           
            //v109 ++<< PA - Address fetch from Account Location   
            oPhysicalAsset.Country__c = oOrderLineItem.Apttus_Config2__LocationId__r.Shipping_Country__c;
            oPhysicalAsset.ShippingCountryISO__c = oOrderLineItem.Apttus_Config2__LocationId__r.Shipping_Country_ISO__c;
            oPhysicalAsset.PostalCode__c = oOrderLineItem.Apttus_Config2__LocationId__r.Apttus_Config2__PostalCode__c;
            oPhysicalAsset.Street__c = oOrderLineItem.Apttus_Config2__LocationId__r.Apttus_Config2__Street__c;
            oPhysicalAsset.HouseNumber__c = oOrderLineItem.Apttus_Config2__LocationId__r.Shipping_House_Number__c;
            oPhysicalAsset.City__c = oOrderLineItem.Apttus_Config2__LocationId__r.Apttus_Config2__City__c;
            //v109 ++>>
            oPhysicalAsset.Warranty__c = oOrderLineItem.Apttus_Config2__AttributeValueId__r.APTS_Number_of_months__c;           
            system.debug('24645 createPhysicalAsset -- ' + oPhysicalAsset.Warranty__c);
            if(String.IsNotBlank(oOrderLineItem.APTS_Option_Group_Text__c) && oOrderLineItem.APTS_Option_Group_Text__c.containsIgnoreCase('Value Added Service')){
                if (oOrderLineItem.Apttus_Config2__LineType__c == 'Option' && oOrderLineItem.Apttus_Config2__OptionId__c != null ) {
                        oPhysicalAsset.IncludesWTSCoverage__c = true;
                        oPhysicalAsset.WaterfilterCoverage__c = 100;
                }
            }
            if (String.IsNotBlank(oOrderLineItem.APTS_Option_Group_Text__c) && oOrderLineItem.APTS_Option_Group_Text__c.containsIgnoreCase('Response Time')) {
                if (String.IsNotBlank(oOrderLineItem.Apttus_Config2__OptionId__c) && oOrderLineItem.Apttus_Config2__OptionId__r.APTS_Response_Time_Hours__c != null) {                    
                    /* --------- v104 -- End -------- */
                    oPhysicalAsset.ResponseTime__c = getResponseTime(oOrderLineItem.Apttus_Config2__OrderId__r.APTS_Sales_Organization__c ,String.valueOf(Integer.valueOf(oOrderLineItem.Apttus_Config2__OptionId__r.APTS_Response_Time_Hours__c)));
                }
                if (String.IsNotBlank(oOrderLineItem.Apttus_Config2__AttributeValueId__c) && oOrderLineItem.Apttus_Config2__AttributeValueId__r.APTS_First_Line_Response_Time__c != null){
                    oPhysicalAsset.ResponseTimeS15__c = oOrderLineItem.Apttus_Config2__AttributeValueId__r.APTS_First_Line_Response_Time__c;
                }
            }
            
            if (String.IsNotBlank(oOrderLineItem.Apttus_Config2__Description__c)) {
                if (oOrderLineItem.Apttus_Config2__Description__c.containsIgnoreCase('ALL-IN COVERAGE')) {
                    oPhysicalAsset.CallOutChargeCoverage__c = oOrderLineItem.Apttus_Config2__AttributeValueId__r.APTS_Call_Out_Coverage_Percent__c;
                    oPhysicalAsset.LabourChargeCoverage__c = oOrderLineItem.Apttus_Config2__AttributeValueId__r.APTS_Labour_Coverage_Percent__c;
                    oPhysicalAsset.SparePartCoverage__c = oOrderLineItem.Apttus_Config2__AttributeValueId__r.APTS_Spare_Parts_Coverage_Percent__c;
                }
            }
            if (String.IsNotBlank(oOrderLineItem.APTS_Option_Group_Text__c) && oOrderLineItem.APTS_Option_Group_Text__c.containsIgnoreCase('Connectivity System')) {
                oPhysicalAsset.Connected__c = 'Yes';
                oPhysicalAsset.CounterReading__c = 'Yes';
            }
            if (String.IsNotBlank(oOrderLineItem.Apttus_Config2__AttributeValueId__c)) {
                if(String.IsNotBlank(oOrderLineItem.APTS_Option_Group_Text__c) && oOrderLineItem.APTS_Option_Group_Text__c.containsIgnoreCase('Service Window')){
                    if (oOrderLineItem.Apttus_Config2__Description__c.containsIgnoreCase('Standard Weekdays & Weekend')) {
                        oPhysicalAsset.ServiceWindow__c = 'Standard Weekdays & Weekend';
                    } else if (oOrderLineItem.Apttus_Config2__Description__c.containsIgnoreCase('Standard Weekdays')) {
                        oPhysicalAsset.ServiceWindow__c = 'Standard Weekdays';
                    } else if (oOrderLineItem.Apttus_Config2__Description__c.containsIgnoreCase('Extended Weekdays & Weekend')) {
                        oPhysicalAsset.ServiceWindow__c = 'Extended Weekdays & Weekend';
                    } else if (oOrderLineItem.Apttus_Config2__Description__c.containsIgnoreCase('Extended Weekdays')) {
                        oPhysicalAsset.ServiceWindow__c = 'Extended Weekdays';
                    } 
                }
                oPhysicalAsset.ConsumptionPrice__c = oOrderLineItem.Apttus_Config2__AttributeValueId__r.APTS_Consumer_Price__c;
                oPhysicalAsset.CupSize__c = oOrderLineItem.Apttus_Config2__AttributeValueId__r.APTS_Cup_Size__c;
                oPhysicalAsset.TastePallet__c = oOrderLineItem.Apttus_Config2__AttributeValueId__r.APTS_Taste_Pallet__c;
                oPhysicalAsset.TypeOfConsumption__c = oOrderLineItem.Apttus_Config2__AttributeValueId__r.APTS_Type_of_payment__c;
            }
            
        }
        
       
        /* }
        catch(Exception e)
          {
        APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id),'OM',false,true, EMAIL, true);

          } */
          
        return oPhysicalAsset;
    }

    public static void setAgreementPODetails(PhysicalAsset__c oPhysicalAsset, List<APTS_Agreement_PO_Details__c> oAgreementPODetailsList) {

        // try{
        if (oAgreementPODetailsList != null && oPhysicalAsset != null) {
            for(APTS_Agreement_PO_Details__c oAgreementPODetails : oAgreementPODetailsList){
                if (oAgreementPODetails.APTS_PO_Category__c == 'Machine') {
                    oPhysicalAsset.PONumberRequiredMachines__c = (oAgreementPODetails.APTS_PO_Number_Required__c != null) ? oAgreementPODetails.APTS_PO_Number_Required__c : oPhysicalAsset.PONumberRequiredMachines__c;
                    oPhysicalAsset.PONumberTypeMachines__c = (oAgreementPODetails.APTS_PO_Number_Type__c != null) ? oAgreementPODetails.APTS_PO_Number_Type__c : oPhysicalAsset.PONumberTypeMachines__c;
                    oPhysicalAsset.PONumberMachines__c = (oAgreementPODetails.APTS_PO_Number__c != null) ? oAgreementPODetails.APTS_PO_Number__c : oPhysicalAsset.PONumberMachines__c;
                } else if (oAgreementPODetails.APTS_PO_Category__c == 'Services') {
                    oPhysicalAsset.PONumberRequiredServices__c = (oAgreementPODetails.APTS_PO_Number_Required__c != null) ? oAgreementPODetails.APTS_PO_Number_Required__c : oPhysicalAsset.PONumberRequiredServices__c;
                    oPhysicalAsset.PONumberServices__c = (oAgreementPODetails.APTS_PO_Number__c != null) ? oAgreementPODetails.APTS_PO_Number__c : oPhysicalAsset.PONumberServices__c;
                    oPhysicalAsset.PONumberTypeServices__c = (oAgreementPODetails.APTS_PO_Number_Type__c != null) ? oAgreementPODetails.APTS_PO_Number_Type__c : oPhysicalAsset.PONumberTypeServices__c;
                }
            }
        }
        /*}
        catch(Exception e)
         {

        APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id),'OM',false,true, EMAIL, true);
         } */
    }

    public static void updatePhysicalAssetOnALIUpdate(List<Apttus_Config2__AssetLineItem__c> newList, Map<Id, Apttus_Config2__AssetLineItem__c> oldMap) {

        Map<Id,PhysicalAsset__c> physicalAssetUpdateMap = new Map<Id,PhysicalAsset__c>();
        List<Apttus_Config2__AssetLineItem__c> primaryLinesForSalesTOC = new List<Apttus_Config2__AssetLineItem__c>();      Set<Id> salesContractAssets = new Set<Id>();
        Map<Id,Id> assetPhysicalAssetmap = new Map<Id,Id>();
        //try{
        for (Apttus_Config2__AssetLineItem__c oAssetLineItem : newList) {
            //<< v103 Updated If Start Date change or Status Change on Asset Line Item update the Physical Asset
            if(oldMap.get(oAssetLineItem.Id) != null) {
            PhysicalAsset__c oPhysicalAsset = new PhysicalAsset__c(Id = oAssetLineItem.APTS_Physical_Asset__c);
            if((oldMap.get(oAssetLineItem.Id).Apttus_Config2__LocationId__c !=  oAssetLineItem.Apttus_Config2__LocationId__c)){
            oPhysicalAsset.AccountLocation__c = oAssetLineItem.Apttus_Config2__LocationId__c;
            oPhysicalAsset.SoldTo__c = oAssetLineItem.Apttus_Config2__AccountId__c;
            }
              if(  ( (oldMap.get(oAssetLineItem.Id).Apttus_Config2__AssetStatus__c !=  oAssetLineItem.Apttus_Config2__AssetStatus__c) || (oldMap.get(oAssetLineItem.Id).Apttus_Config2__StartDate__c != oAssetLineItem.Apttus_Config2__StartDate__c) ||  
                    (oldMap.get(oAssetLineItem.Id).Apttus_Config2__EndDate__c != oAssetLineItem.Apttus_Config2__EndDate__c)) && oAssetLineItem.APTS_Physical_Asset__c != null){
                
                //PhysicalAsset__c oPhysicalAsset = new PhysicalAsset__c(Id = oAssetLineItem.APTS_Physical_Asset__c);
                   //DQ-56- Asset Contract Change Logic - Bypassing Pending Cancellation Logic for Contract Change Orders.
                if((oAssetLineItem.APTS_Contract_Change__c == true && oAssetLineItem.Apttus_Config2__AssetStatus__c == 'Activated') || oAssetLineItem.APTS_Contract_Change__c != true)                
                {
                oPhysicalAsset.AssetStatus__c = oAssetLineItem.Apttus_Config2__AssetStatus__c;
                oPhysicalAsset.TypeOfContract__c = (String.IsNotBlank(oAssetLineItem.APTS_Type_of_Contract__c)) ? oAssetLineItem.APTS_Type_of_Contract__c : null;                
                oPhysicalAsset.StartDate__c = oAssetLineItem.Apttus_Config2__StartDate__c;
                oPhysicalAsset.EndDate__c = oAssetLineItem.Apttus_Config2__EndDate__c;
                System.debug('USER DEBUG'+oPhysicalAsset.StartDate__c+'ed'+oPhysicalAsset.EndDate__c+'id'+oPhysicalAsset.id+'ali'+oAssetLineItem.id);
                oPhysicalAsset.APTS_PhysicalAssetExtId__c = oAssetLineItem.APTS_PhysicalAssetExtId__c;                          
                if(String.IsNotBlank(oAssetLineItem.APTS_Physical_Asset__r.Warranty__c) && oAssetLineItem.APTS_Physical_Asset__r.Warranty__c != '0' && oAssetLineItem.APTS_Type_Of_Contract__c == 'Sales'){
                    oPhysicalAsset.WarrantyStartDate__c = oAssetLineItem.Apttus_Config2__StartDate__c;
                } 
                if(oAssetLineItem.Apttus_Config2__LineType__c == 'Product/Service' && oAssetLineItem.APTS_Type_Of_Contract__c == 'Sales'){
                    assetPhysicalAssetmap.put(oAssetLineItem.Id,oPhysicalAsset.Id);                    
                }  
                //physicalAssetUpdateMap.put(oPhysicalAsset.Id,oPhysicalAsset);  
                }                                      
            }
            physicalAssetUpdateMap.put(oPhysicalAsset.Id,oPhysicalAsset);  
            }
            // << v106
            if(oldMap.get(oAssetLineItem.Id) != null && ( (oldMap.get(oAssetLineItem.Id).Apttus_Config2__AssetStatus__c !=  oAssetLineItem.Apttus_Config2__AssetStatus__c) || 
                    (oldMap.get(oAssetLineItem.Id).Apttus_Config2__StartDate__c != oAssetLineItem.Apttus_Config2__EndDate__c)  || (oldMap.get(oAssetLineItem.Id).Apttus_Config2__EndDate__c != oAssetLineItem.Apttus_Config2__EndDate__c))
                    && oAssetLineItem.APTS_Type_Of_Contract__c == 'Sales' && oAssetLineItem.APTS_Is_Primary_L1_Asset__c != null && 
                    oAssetLineItem.Apttus_Config2__LineType__c == 'Product/Service' && oAssetLineItem.Apttus_Config2__IsPrimaryLine__c == true) {       
                if(physicalAssetUpdateMap != null && physicalAssetUpdateMap.containsKey(oAssetLineItem.APTS_Is_Primary_L1_Asset__r.APTS_Physical_Asset__c)){
                    PhysicalAsset__c oPhysicalAsset = physicalAssetUpdateMap.get(oAssetLineItem.APTS_Is_Primary_L1_Asset__r.APTS_Physical_Asset__c);
                   
                    oPhysicalAsset.AssetStatus__c = oAssetLineItem.Apttus_Config2__AssetStatus__c;
                    oPhysicalAsset.StartDate__c = oAssetLineItem.Apttus_Config2__StartDate__c;
                    oPhysicalAsset.EndDate__c = oAssetLineItem.Apttus_Config2__EndDate__c;
                    System.debug('USER DEBUG'+oPhysicalAsset.StartDate__c+'ed'+oPhysicalAsset.EndDate__c+'id'+oPhysicalAsset.id+'ali'+oAssetLineItem.id);          
                    physicalAssetUpdateMap.put(oPhysicalAsset.Id,oPhysicalAsset);   
                }else{
                    PhysicalAsset__c oPhysicalAsset = new PhysicalAsset__c(Id = oAssetLineItem.APTS_Is_Primary_L1_Asset__r.APTS_Physical_Asset__c);
                   
                    oPhysicalAsset.AssetStatus__c = oAssetLineItem.Apttus_Config2__AssetStatus__c;
                    oPhysicalAsset.StartDate__c = oAssetLineItem.Apttus_Config2__StartDate__c;
                    oPhysicalAsset.EndDate__c = oAssetLineItem.Apttus_Config2__EndDate__c;                          
                    physicalAssetUpdateMap.put(oPhysicalAsset.Id,oPhysicalAsset);           
                }                                           
            }           
            // v106 >>
        }
                   
        if(assetPhysicalAssetmap != null && assetPhysicalAssetmap.size() > 0){
            for(Apttus_Config2__AssetLineItem__c oAssetLineItem: [select id,APTS_Is_Primary_L1_Asset__c,Apttus_Config2__AssetStatus__c,Apttus_Config2__StartDate__c,Apttus_Config2__IsPrimaryLine__c,Apttus_Config2__EndDate__c from Apttus_Config2__AssetLineItem__c 
                                                                    where APTS_Is_Primary_L1_Asset__c =: assetPhysicalAssetmap.keySet()  and Apttus_Config2__LineType__c = 'Product/Service' AND
                                                                    Apttus_Config2__IsPrimaryLine__c = true]){
                PhysicalAsset__c oPhysicalAsset = new PhysicalAsset__c(Id = assetPhysicalAssetmap.get(oAssetLineItem.APTS_Is_Primary_L1_Asset__c));
                if(physicalAssetUpdateMap != null && physicalAssetUpdateMap.containsKey(oPhysicalAsset.Id)){
                    oPhysicalAsset = physicalAssetUpdateMap.get(oPhysicalAsset.Id);
                }
               
                oPhysicalAsset.AssetStatus__c = oAssetLineItem.Apttus_Config2__AssetStatus__c;
                oPhysicalAsset.StartDate__c = oAssetLineItem.Apttus_Config2__StartDate__c;
                oPhysicalAsset.EndDate__c = oAssetLineItem.Apttus_Config2__EndDate__c;  
                System.debug('USER DEBUG'+oPhysicalAsset.StartDate__c+'ed'+oPhysicalAsset.EndDate__c+'id'+oPhysicalAsset.id+'ali'+oAssetLineItem.id);                        
                physicalAssetUpdateMap.put(oPhysicalAsset.Id,oPhysicalAsset);                  
            }               
        }   
                
        if(physicalAssetUpdateMap != null && !physicalAssetUpdateMap.IsEmpty() && physicalAssetUpdateMap.size() > 0){
            Database.update(physicalAssetUpdateMap.values(), false);
        }
        /* }
        catch(Exception e)
        {

        APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id),'OM',false,true, EMAIL, true);
        } */
    }

    public static List<PhysicalAsset__c> getPhysicalAssetOli(Map<Id, Apttus_Config2__OrderLineItem__c> physicalAssetIdToOLIMap) {

        return [SELECT Id, ParentPhysicalAsset__c, SalesOrganization__c,
                AssetStatus__c, ActiveContract__c, StartDate__c, EndDate__c,
                RefurbishedMachine__c, AccountLocation__c, Product__c, SoldTo__c,
                TypeOfContract__c, SerialNumber__c, UniqueNumber__c, Warranty__c,
                WarrantyStartDate__c, CommercialUsage__c, AgreementRecordType__c,
                Routesales__c, IncludesWTSCoverage__c, WTSInterval__c, Building__c,
                Floor__c, Area__c, CustomerReferenceNumber__c, SmokingArea__c, CounterReading__c,
                WTSChangedBy__c, IncludesPreventiveMaintenanceCoverage__c, PreventiveMaintenanceInterval__c,
                ResponseTime__c, CallOutChargeCoverage__c, SparePartCoverage__c, LabourChargeCoverage__c,
                WaterfilterCoverage__c, PreventiveMaintenanceCoverage__c, FullOperatingCoverage__c,
                ConfigurationFileURL__c, ConfigurationManualAgreementsURL__c, JDECrockeryVolumeSize__c,
                OwnedByCustomer__c, Machine_Care__c, PONumberRequiredMachines__c, PONumberRequiredServices__c,
                PONumberTypeMachines__c, PONumberTypeServices__c, PONumberMachines__c, PONumberServices__c, Billing_Setting__c
                FROM PhysicalAsset__c WHERE Id IN: physicalAssetIdToOLIMap.keyset() LIMIT 50000 ];
    }

    public static List<PhysicalAsset__c> updatePhysicalAssetOnOLIUpdate(map<Id, Apttus_Config2__OrderLineItem__c> physicalAssetIdToOLIMap, Map<Id, List<APTS_Agreement_PO_Details__c>> agreementPOMap) {

        List<PhysicalAsset__c> physicalAssetUpdateList = new List<PhysicalAsset__c>();
        Set<Id> orderIdSet = new Set<Id>(new Map<Id, Apttus_Config2__OrderLineItem__c>(physicalAssetIdToOLIMap.values()).keySet());
        Map<Id, Apttus_Config2__OrderLineItem__c> oLIMap = getOrderLineItemAdditionalData(orderIdSet);
        //try{
        
        for (PhysicalAsset__c updatedPA : getPhysicalAssetOli(physicalAssetIdToOLIMap)) {

            Apttus_Config2__OrderLineItem__c oLI = oLIMap.get(physicalAssetIdToOLIMap.get(updatedPA.Id).Id);
            system.debug('Oli Location'+ oLI.Apttus_Config2__LocationId__c);
            system.debug('Oli Sales Org'+ oLI.Apttus_Config2__OrderId__r.APTS_Sales_Organization__c);
            system.debug('Oli Sold To'+ oLI.Apttus_Config2__OrderId__r.Apttus_Config2__SoldToAccountId__c);
            updatedPA.RefurbishedMachine__c = oLI.APTS_RefurbishedMachine__c;
            updatedPA.AccountLocation__c = oLI.Apttus_Config2__LocationId__c;
            //updatedPA.Product__c = oLI.Apttus_Config2__ProductId__c;
            //updatedPA.SerialNumber__c = oLI.APTS_Serial_Number__c;
            updatedPA.SalesOrganization__c = oLI.Apttus_Config2__OrderId__r.APTS_Sales_Organization__c;
            updatedPA.SoldTo__c = oLI.Apttus_Config2__OrderId__r.Apttus_Config2__SoldToAccountId__c;
            /**if (oLI.Apttus_Config2__HasOptions__c && oLI.Apttus_Config2__ProductId__r.APTS_Material_Type__c == 'ZCMA') {
                if (oLI.Apttus_Config2__ProductId__r.APTS_Vendor_Code__c != null) {
                    updatedPA.UniqueNumber__c = oLI.Apttus_Config2__ProductId__r.APTS_Vendor_Code__c + oLI.APTS_Serial_Number__c ;
                } else {
                    updatedPA.UniqueNumber__c = oLI.APTS_Serial_Number__c;
                }
            }**/
            //updatedPA.AssetStatus__c = oLI.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__AssetStatus__c;
            updatedPA.StartDate__c = oLI.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__StartDate__c;
            updatedPA.EndDate__c = oLI.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__EndDate__c;
            updatedPA.OwnedByCustomer__c = oLI.Apttus_Config2__AssetLineItemId__r.APTS_OwnedByCustomer__c;
            updatedPA.AgreementRecordType__c = oLI.Apttus_CMConfig__AgreementId__r.RecordType.Name;
            updatedPA.Routesales__c = oLI.Apttus_CMConfig__AgreementId__r.APTS_Routesales__c;
            updatedPA.Warranty__c = oLI.Apttus_Config2__AttributeValueId__r.APTS_Number_of_months__c;
             //DQ-3293- Configuring the WTSChangedby attribute
             updatedPA.WTSChangedBy__c = oLI.Apttus_Config2__AttributeValueId__r.APTS_WTS_Changed_By__c;
                /* ---------  Defect fix : DOQCL-13 -- Start -------- */
                //v114-Commenting as part of DQ-3293
           /* if(oLI.APTS_Option_Group_Text__c != null){
                if(oLI.APTS_Option_Group_Text__c == 'Water System' && oLI.Apttus_Config2__Quantity__c > 0){
                    mapOfwtsChangeOLI.put(oLI.id, oLI.APTS_Parent_Order_Line_Item__c + 'C1');
                }
                else if(oLI.APTS_Option_Group_Text__c == 'Value Added Service' && oLI.Apttus_Config2__OptionId__r.Water_Filter_Replacement__c == 'Yes'){
                    mapOfwtsChangeOLI.put(oLI.id, oLI.APTS_Parent_Order_Line_Item__c + 'C2');
                }
                else if(oLI.APTS_Option_Group_Text__c == 'Machine Care' && oLI.Apttus_Config2__Quantity__c > 0 && oLI.Apttus_Config2__OptionId__r.APTS_Full_Operating__c == 'Yes'){
                    mapOfwtsChangeOLI.put(oLI.id, oLI.APTS_Parent_Order_Line_Item__c+ 'C3');
                }
            }
                
            set<String> wtsConditionCheck = new set<String>();
            //system.debug('Akhilesh new--> mapOfwtsChangeOLI: ' + mapOfwtsChangeOLI);
            if(mapOfwtsChangeOLI.size() > 0 ){
                for(String parentNo : mapOfwtsChangeOLI.Values()){
                    // v102 Sai-JIRA-DFT2C-740 NULL Check
                    if(oLI.APTS_Parent_Order_Line_Item__c != null && parentNo.contains(oLI.APTS_Parent_Order_Line_Item__c)){
                        wtsConditionCheck.add(parentNo);
                    } 
                }
            }
            
          
            if(wtsConditionCheck.size() == 3){
                updatedPA.WTSChangedBy__c = 'Operator';
            }else if(wtsConditionCheck.size() == 2){
                updatedPA.WTSChangedBy__c = JDE_ENGINEER;
            }else if(wtsConditionCheck.size() == 1){
                updatedPA.WTSChangedBy__c = 'Customer';
            }
          
            wtsConditionCheck.clear(); */
            
            /* ---------  Defect fix : DOQCL-13 -- End -------- */
            system.debug('24645 updatePhysicalAssetOnOLIUpdate -- ' + oLI.Apttus_Config2__LineType__c + oLI.Apttus_Config2__OptionId__c + ' - '+ updatedPA.WTSChangedBy__c);
            if(String.IsNotBlank(oLI.APTS_Option_Group_Text__c) && oLI.APTS_Option_Group_Text__c.containsIgnoreCase('Value Added Service')){
            if (oLI.Apttus_Config2__LineType__c == 'Option' && oLI.Apttus_Config2__OptionId__c != null ) {
                updatedPA.IncludesWTSCoverage__c = true;
                updatedPA.WaterfilterCoverage__c = 100;
            }
            }
                        
            /* --------- v104 -- End -------- */
            updatedPA.ResponseTime__c = getResponseTime(oLI.Apttus_Config2__OrderId__r.APTS_Sales_Organization__c ,String.valueOf(Integer.valueOf(oLI.Apttus_Config2__OptionId__r.APTS_Response_Time_Hours__c)));
            updatedPA.CallOutChargeCoverage__c = oLI.Apttus_Config2__AttributeValueId__r.APTS_Call_Out_Coverage_Percent__c;
            updatedPA.SparePartCoverage__c = oLI.Apttus_Config2__AttributeValueId__r.APTS_Spare_Parts_Coverage_Percent__c;
            updatedPA.LabourChargeCoverage__c = oLI.Apttus_Config2__AttributeValueId__r.APTS_Labour_Coverage_Percent__c;
            //boolean optionflag = oLI.Apttus_Config2__OptionId__r.Name.containsIgnoreCase('Preventive maintenance');
            //updatedPA.IncludesPreventiveMaintenanceCoverage__c = optionflag ? true : false;
            updatedPA.IncludesPreventiveMaintenanceCoverage__c = false;
            if (String.IsNotBlank(oLI.APTS_Option_Group_Text__c) && oLI.APTS_Option_Group_Text__c.containsIgnoreCase('Preventive Maintenance')) {
                updatedPA.PreventiveMaintenanceCoverage__c = 100;
                //v105 - Populate Preventive Mantenance Intervel based on Product Name
                if(String.IsNotBlank(oLI.Apttus_Config2__OptionId__c) && oLI.Apttus_Config2__OptionId__r.Name != null){
                    updatedPA.PreventiveMaintenanceInterval__c = getPrevenetiveMaintenanceIntervel(oLI.Apttus_Config2__OptionId__r.Name);
                }
            }
            
             updatedPA = updateLSPDetailOnPhA(updatedPA, oLI, false); //V113 ++ <<>>        
           
            
            if(updatedPA != null && oLI.APTS_Option_Group_Text__c != null && oLI.Apttus_Config2__Description__c != null && oLI.Apttus_Config2__Description__c.containsIgnoreCase('Full Operating') && oLI.APTS_Option_Group_Text__c.containsIgnoreCase('Machine Care')){
                updatedPA.CounterReading__c = 'Yes';
            }

            //APTS_Agreement_PO_Details__c oAgreementPODetails = agreementPOMap.get(oLI.Apttus_CMConfig__AgreementId__c);

            /***if (oAgreementPODetails != null ) {
                if (oAgreementPODetails.APTS_PO_Category__c == 'Machine') {
                    updatedPA.PONumberRequiredMachines__c = oAgreementPODetails.APTS_PO_Number_Required__c;
                    updatedPA.PONumberTypeMachines__c = oAgreementPODetails.APTS_PO_Number_Type__c;
                    updatedPA.PONumberMachines__c = oAgreementPODetails.APTS_PO_Number__c;
                } else if (oAgreementPODetails.APTS_PO_Category__c == 'services') {
                    updatedPA.PONumberRequiredServices__c = oAgreementPODetails.APTS_PO_Number_Required__c;
                    updatedPA.PONumberServices__c = oAgreementPODetails.APTS_PO_Number__c;
                    updatedPA.PONumberTypeServices__c = oAgreementPODetails.APTS_PO_Number_Type__c;
                }
            }**/
            system.debug('24645 updatePhysicalAssetOnOLIUpdate-- ' + updatedPA.WaterfilterCoverage__c);
            setAgreementPODetails(updatedPA, agreementPOMap.get(oLI.Apttus_CMConfig__AgreementId__c));

            physicalAssetUpdateList.add(updatedPA);
        }
        /* }
             catch(Exception e)
               {

        APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id),'OM',false,true, EMAIL, true);
               } */
        return physicalAssetUpdateList;
    }
    
    /*Method to get Child OLIs from Parent OLI*/
    public static Map<String, Apttus_Config2__OrderLineItem__c> getChildOLIFromParentOLI(Set<Id> orderIdSet){
        return new Map<String, Apttus_Config2__OrderLineItem__c>([
                    SELECT Id, Name, Apttus_Config2__LocationId__c, APTS_Machine_Age__c,APTS_Physical_Asset__c,
                    APTS_Physical_Asset__r.SerialNumber__c,
                    APTS_Serial_Number__c, APTS_Goods_Issue_Date__c, APTS_RefurbishedMachine__c,
                    Apttus_Config2__LineType__c,  Apttus_Config2__ParentBundleNumber__c,
                    Apttus_Config2__LineNumber__c, Apttus_Config2__ChargeType__c, Apttus_Config2__HasOptions__c,
                    APTS_De_installation_Date__c, APTS_Option_Group_Text__c, APTS_Serial_Number2__c, Apttus_Config2__Quantity__c,
                    APTS_Parent_Order_Line_Item__c, APTS_Type_of_Contract__c,Apttus_Config2__LineStatus__c,
                    Apttus_Config2__StartDate__c,
                    
                    Apttus_Config2__AssetLineItemId__c, Apttus_Config2__Description__c,
                    Apttus_Config2__AssetLineItemId__r.APTS_RefurbishedMachine__c,
                    Apttus_Config2__AssetLineItemId__r.Apttus_Config2__StartDate__c,
                    Apttus_Config2__AssetLineItemId__r.Apttus_Config2__EndDate__c,
                    Apttus_Config2__AssetLineItemId__r.Apttus_Config2__AssetStatus__c,
                    Apttus_Config2__AssetLineItemId__r.APTS_Physical_Asset__c,
                    Apttus_Config2__AssetLineItemId__r.APTS_OwnedByCustomer__c,

                    Apttus_CMConfig__AgreementId__c,
                    Apttus_CMConfig__AgreementId__r.RecordType.DeveloperName,
                    Apttus_CMConfig__AgreementId__r.RecordType.Name,
                    Apttus_CMConfig__AgreementId__r.Apttus__Status_Category__c,
                    Apttus_CMConfig__AgreementId__r.Apttus__Status__c,
                    Apttus_CMConfig__AgreementId__r.APTS_Routesales__c,

                    APTS_Order_LSP_Detail__c,
                    APTS_Order_LSP_Detail__r.APTS_Building__c,
                    APTS_Order_LSP_Detail__r.APTS_Floor__c,
                    APTS_Order_LSP_Detail__r.APTS_Area__c,
                    APTS_Order_LSP_Detail__r.APTS_CustomerReference__c,
                    APTS_Order_LSP_Detail__r.APTS_SmokingArea__c,
                    APTS_Order_LSP_Detail__r.APTS_ConfigurationFileURL__c,
                    APTS_Order_LSP_Detail__r.APTS_JDE_crockeryVolumeSize__c,
                    APTS_Order_LSP_Detail__r.APTS_ConfigurationManualAgreementsURL__c,

                    Apttus_Config2__OrderId__c,
                    Apttus_Config2__OrderId__r.Apttus_Config2__PONumber__c,
                    Apttus_Config2__OrderId__r.APTS_Sales_Organization__c,
                    Apttus_Config2__OrderId__r.Apttus_Config2__SoldToAccountId__c,
                    Apttus_Config2__OrderId__r.APTS_Confirmed_De_Installation_Date__c,
                    Apttus_Config2__OrderId__r.APTS_Confirmed_Installation_Date__c,
                    Apttus_Config2__OrderId__r.APTS_Merchant_ID__c,
                    Apttus_Config2__OrderId__r.APTS_Closed_User_Group_Code_1__c,
                    Apttus_Config2__OrderId__r.APTS_Closed_User_Group_Code_2__c,
                    Apttus_Config2__OrderId__r.APTS_Closed_User_Group_Code_3__c,
                    Apttus_Config2__OrderId__r.APTS_Contract_Change__c, 
                    Apttus_Config2__DerivedFromId__r.APTS_Terminated_Asset_Line__c,
                    Apttus_Config2__DerivedFromId__r.APTS_Terminated_Asset_Line__r.APTS_PhysicalAssetExtId__c,

                    Apttus_Config2__AttributeValueId__c,
                    Apttus_Config2__AttributeValueId__r.APTS_Number_of_months__c,
                    Apttus_Config2__AttributeValueId__r.APTS_Call_Out_Coverage_Percent__c,
                    Apttus_Config2__AttributeValueId__r.APTS_Labour_Coverage_Percent__c,
                    Apttus_Config2__AttributeValueId__r.APTS_Spare_Parts_Coverage_Percent__c,
                    Apttus_Config2__AttributeValueId__r.APTS_WTS_Changed_By__c,
                    Apttus_Config2__AttributeValueId__r.APTS_Service_Window__c,
                    Apttus_Config2__AttributeValueId__r.APTS_Response_Profile__c,
                    Apttus_Config2__AttributeValueId__r.APTS_Merchant__c,
                    Apttus_Config2__AttributeValueId__r.APTS_Consumer_Price__c,
                    Apttus_Config2__AttributeValueId__r.APTS_Cup_Size__c,
                    Apttus_Config2__AttributeValueId__r.APTS_Taste_Pallet__c,
                    Apttus_Config2__AttributeValueId__r.APTS_Type_of_payment__c,
                    Apttus_Config2__AttributeValueId__r.APTS_Number_of_hours_per_month__c,
                    Apttus_Config2__AttributeValueId__r.APTS_First_Line_Response_Time__c,

                    Apttus_Config2__ProductId__c,
                    Apttus_Config2__ProductId__r.Name,
                    Apttus_Config2__ProductId__r.Description,
                    Apttus_Config2__ProductId__r.ProductCode,
                    Apttus_Config2__ProductId__r.APTS_Material_Type__c,
                    Apttus_Config2__ProductId__r.Apttus_Config2__ConfigurationType__c,
                    Apttus_Config2__ProductId__r.APTS_Vendor_Code__c,
                    Apttus_Config2__OptionId__c,
                    Apttus_Config2__OptionId__r.Name,
                    Apttus_Config2__OptionId__r.Description,
                    Apttus_Config2__OptionId__r.ProductCode,
                    Apttus_Config2__OptionId__r.APTS_Material_Type__c,
                    Apttus_Config2__OptionId__r.APTS_Option_Group_Indicator__c,
                    Apttus_Config2__OptionId__r.APTS_Response_Time_Hours__c,
                    Apttus_Config2__OptionId__r.Water_Filter_Replacement__c,
                    Apttus_Config2__OptionId__r.APTS_Full_Operating__c,
            //v109 <<++ PA - Address fetch from Account Location
                    Apttus_Config2__ShipToAccountId__c,
                    Apttus_Config2__LocationId__r.Shipping_Country__c,
                    Apttus_Config2__LocationId__r.Shipping_Country_ISO__c,
                    Apttus_Config2__LocationId__r.Apttus_Config2__PostalCode__c,
                    Apttus_Config2__LocationId__r.Apttus_Config2__Street__c,
                    Apttus_Config2__LocationId__r.Shipping_House_Number__c,
                    Apttus_Config2__LocationId__r.Apttus_Config2__City__c
            //v109 ++>>

                    FROM Apttus_Config2__OrderLineItem__c
                    WHERE Apttus_Config2__OrderId__c IN: orderIdSet 
                    AND Apttus_Config2__LineType__c =: OPTION AND 
                    Apttus_Config2__LineStatus__c != 'Cancelled'
                    LIMIT 50000]);
    }
    
    public static PhysicalAsset__c populatePhysicalAssetFields(Apttus_Config2__OrderLineItem__c oLI, PhysicalAsset__c physicalAsset){

        if(oLI != null && physicalAsset != null && String.IsNotBlank(oLI.APTS_Option_Group_Text__c)){
            if (oLI.APTS_Option_Group_Text__c.containsIgnoreCase('Machine Care')){
                /**if (oLI.Apttus_Config2__Description__c.containsIgnoreCase('Comfort Operating')) {
                    physicalAsset.Machine_Care__c = 'Comfort Operating';
                } else if (oLI.Apttus_Config2__Description__c.containsIgnoreCase('Full Co Operating')) {
                    physicalAsset.Machine_Care__c = 'Full Co Operating';
                } else if (oLI.Apttus_Config2__Description__c.containsIgnoreCase('Full Operating')) {
                    physicalAsset.Machine_Care__c = 'Full Operating';
                    physicalAsset.CounterReading__c = 'Yes';
                }else if (oLI.Apttus_Config2__Description__c.containsIgnoreCase('Semi Operating')) {
                    physicalAsset.Machine_Care__c = 'Semi Operating';
                }else if (oLI.Apttus_Config2__Description__c.containsIgnoreCase('Machine Clean Operating')) {
                    physicalAsset.Machine_Care__c = 'Machine Clean Operating';
                }**/
                if(machineCareField != null){
                    for (Schema.PicklistEntry mapMachinecare : machineCareField){
                        if(oLI.Apttus_Config2__Description__c.containsIgnoreCase(mapMachinecare.getLabel())){
                            physicalAsset.Machine_Care__c = mapMachinecare.getLabel();
                        }
                    }
                }
                
                physicalAsset.MachineCareHours__c = String.IsNotBlank(oLI.Apttus_Config2__AttributeValueId__c) ? oLI.Apttus_Config2__AttributeValueId__r.APTS_Number_of_hours_per_month__c : 0.00; 
            }else if (oLI.APTS_Option_Group_Text__c.containsIgnoreCase('Preventive Maintenance')){
                physicalAsset.IncludesPreventiveMaintenanceCoverage__c =  true;
                physicalAsset.PreventiveMaintenanceCoverage__c = Decimal.valueOf('100.00');
                //v105 - Populate Preventive Mantenance Intervel based on Product Name
                if(String.IsNotBlank(oLI.Apttus_Config2__OptionId__c) && oLI.Apttus_Config2__OptionId__r.Name != null){
                    physicalAsset.PreventiveMaintenanceInterval__c = getPrevenetiveMaintenanceIntervel(oLI.Apttus_Config2__OptionId__r.Name);
                }  
                physicalAsset.LastPreventiveMaintenanceDate__c = physicalAsset.LastPreventiveMaintenanceDate__c == null ? oLI.Apttus_Config2__StartDate__c : physicalAsset.LastPreventiveMaintenanceDate__c; //V116
                             
            }else if (oLI.APTS_Option_Group_Text__c.containsIgnoreCase('Connectivity System')) {
                physicalAsset.Connected__c = 'Yes';
                physicalAsset.CounterReading__c = 'Yes';
            }else if(oLI.APTS_Option_Group_Text__c.containsIgnoreCase('Service Window') && String.IsNotBlank(oLI.Apttus_Config2__Description__c)){
                if (oLI.Apttus_Config2__Description__c.containsIgnoreCase('Standard Weekdays & Weekend')) {
                    physicalAsset.ServiceWindow__c = 'Standard Weekdays & Weekend';
                } else if (oLI.Apttus_Config2__Description__c.containsIgnoreCase('Standard Weekdays')) {
                    physicalAsset.ServiceWindow__c = 'Standard Weekdays';
                } else if (oLI.Apttus_Config2__Description__c.containsIgnoreCase('Extended Weekdays & Weekend')) {
                    physicalAsset.ServiceWindow__c = 'Extended Weekdays & Weekend';
                } else if (oLI.Apttus_Config2__Description__c.containsIgnoreCase('Extended Weekdays')) {
                    physicalAsset.ServiceWindow__c = 'Extended Weekdays';
                }
            }else if (oLI.APTS_Option_Group_Text__c.containsIgnoreCase('Response Time')) {
                if (String.IsNotBlank(oLI.Apttus_Config2__OptionId__c) && oLI.Apttus_Config2__OptionId__r.APTS_Response_Time_Hours__c != null) {
                    /* ---------  v104 -- End -------- */
                    physicalAsset.ResponseTime__c = getResponseTime(oLI.Apttus_Config2__OrderId__r.APTS_Sales_Organization__c ,String.valueOf(Integer.valueOf(oLI.Apttus_Config2__OptionId__r.APTS_Response_Time_Hours__c)));
                }
                if (String.IsNotBlank(oLI.Apttus_Config2__AttributeValueId__c) && oLI.Apttus_Config2__AttributeValueId__r.APTS_First_Line_Response_Time__c != null){
                    physicalAsset.ResponseTimeS15__c = oLI.Apttus_Config2__AttributeValueId__r.APTS_First_Line_Response_Time__c;
                }
            }
        }
        if(String.IsNotBlank(oLI.Apttus_Config2__Description__c) && physicalAsset != null){
            if(oLI.Apttus_Config2__Description__c.containsIgnoreCase('Full Operating')){
                physicalAsset.FullOperatingCoverage__c = Decimal.valueOf('100.00');
            }else if(oLI.Apttus_Config2__Description__c.containsIgnoreCase('Payment Module')){
                physicalAsset.MerchantId__c = oLI.Apttus_Config2__OrderId__r.APTS_Merchant_ID__c;
                physicalAsset.Merchant__c = String.IsNotBlank(oLI.Apttus_Config2__AttributeValueId__c) ? oLI.Apttus_Config2__AttributeValueId__r.APTS_Merchant__c : null;
                physicalAsset.ClosedUserGroupCode1__c = oLI.Apttus_Config2__OrderId__r.APTS_Closed_User_Group_Code_1__c;
                physicalAsset.ClosedUserGroupCode2__c = oLI.Apttus_Config2__OrderId__r.APTS_Closed_User_Group_Code_2__c;
                physicalAsset.ClosedUserGroupCode3__c = oLI.Apttus_Config2__OrderId__r.APTS_Closed_User_Group_Code_3__c;
            }else if (String.IsNotBlank(oLI.Apttus_Config2__AttributeValueId__c) &&  String.IsNotBlank(oLI.APTS_Option_Group_Text__c) && 'Technical Service'.equalsIgnoreCase(oLI.APTS_Option_Group_Text__c)) {
                physicalAsset.CallOutChargeCoverage__c = oLI.Apttus_Config2__AttributeValueId__r.APTS_Call_Out_Coverage_Percent__c;
                physicalAsset.LabourChargeCoverage__c = oLI.Apttus_Config2__AttributeValueId__r.APTS_Labour_Coverage_Percent__c;
                physicalAsset.SparePartCoverage__c = oLI.Apttus_Config2__AttributeValueId__r.APTS_Spare_Parts_Coverage_Percent__c;
            }
        }
        /**------------------ v108 ---------------------------*/
        if(physicalAsset != null && oLI.APTS_Option_Group_Text__c != null && oLI.Apttus_Config2__Description__c != null &&
            oLI.APTS_Option_Group_Text__c.containsIgnoreCase('Machine Care') && 
            (oLI.Apttus_Config2__Description__c.containsIgnoreCase('Full Operating') || oLI.Apttus_Config2__Description__c.containsIgnoreCase('Full Operating') || 
                oLI.Apttus_Config2__Description__c.containsIgnoreCase('Semi Operating')) ){
                physicalAsset.CounterReading__c = 'Yes';
        }
        //v114-DQ-3293- Configuring the WTSChangedby attribute
        if(oLI.Apttus_Config2__AttributeValueId__r.APTS_WTS_Changed_By__c!=null){
            physicalAsset.WTSChangedBy__c = oLI.Apttus_Config2__AttributeValueId__r.APTS_WTS_Changed_By__c;
        }
        /* ---------  Defect fix : DOQCL-13 -- Start -------- */
        //v114-Commenting as part of DQ-3293
        /*if(oLI.APTS_Option_Group_Text__c != null){
            if(oLI.APTS_Option_Group_Text__c == 'Water System' && oLI.Apttus_Config2__Quantity__c > 0){
                mapOfwtsChangeOLI.put(oLI.id, oLI.APTS_Parent_Order_Line_Item__c + 'C1');
            }
            else if(oLI.APTS_Option_Group_Text__c == 'Value Added Service' && oLI.Apttus_Config2__OptionId__r.Water_Filter_Replacement__c == 'Yes'){
                mapOfwtsChangeOLI.put(oLI.id, oLI.APTS_Parent_Order_Line_Item__c + 'C2');
            }
            else if(oLI.APTS_Option_Group_Text__c == 'Machine Care' && oLI.Apttus_Config2__Quantity__c > 0 && oLI.Apttus_Config2__OptionId__r.APTS_Full_Operating__c == 'Yes'){
                mapOfwtsChangeOLI.put(oLI.id, oLI.APTS_Parent_Order_Line_Item__c+ 'C3');
            }
        }
            
            set<String> wtsConditionCheck = new set<String>();
            system.debug('Akhilesh new--> mapOfwtsChangeOLI: ' + mapOfwtsChangeOLI);
            if(mapOfwtsChangeOLI.size() > 0 ){
                for(String parentNo : mapOfwtsChangeOLI.Values()){
                    // Sai-JIRA-DFT2C-740 Null Check
                    if(oLI.APTS_Parent_Order_Line_Item__c != null && parentNo.contains(oLI.APTS_Parent_Order_Line_Item__c)){
                        wtsConditionCheck.add(parentNo);
                    } 
                }
            }
        
        
        if(wtsConditionCheck.size() == 3){
            physicalAsset.WTSChangedBy__c = 'Operator';
        }else if(wtsConditionCheck.size() == 2){
            physicalAsset.WTSChangedBy__c = JDE_ENGINEER;
        }else if(wtsConditionCheck.size() == 1){
            physicalAsset.WTSChangedBy__c = 'Customer';
        }
       
        wtsConditionCheck.clear();*/
        
        /* ---------------- DOQCL-13 fix end ---------------*/
        
        system.debug('24645 populatePhysicalAssetFields -- ' + oLI.Apttus_Config2__LineType__c + oLI.Apttus_Config2__OptionId__c + ' - ' + physicalAsset.WTSChangedBy__c);
        if(String.IsNotBlank(oLI.APTS_Option_Group_Text__c) && oLI.APTS_Option_Group_Text__c.containsIgnoreCase('Value Added Service')){
            if (oLI.Apttus_Config2__LineType__c == 'Option' && oLI.Apttus_Config2__OptionId__c != null  ) {
                physicalAsset.IncludesWTSCoverage__c = true;
                physicalAsset.WaterfilterCoverage__c = 100;
                physicalAsset.LastWTSDate__c = physicalAsset.LastWTSDate__c == null ? oLI.Apttus_Config2__StartDate__c : physicalAsset.LastWTSDate__c; //V116
            }
        }
        /*if(physicalAsset != null && oLI.Apttus_Config2__AttributeValueId__c != null && oLI.Apttus_Config2__AttributeValueId__r.APTS_WTS_Changed_By__c == 'JDE Engineer') {
            physicalAsset.IncludesWTSCoverage__c = true;
            physicalAsset.WaterfilterCoverage__c = 100;
        }*/
        system.debug('24645 populatePhysicalAssetFields -- ' + physicalAsset.WaterfilterCoverage__c);
        //V117 Populating Planograms Product code and Description
        if(String.IsNotBlank(oLI.APTS_Option_Group_Text__c) && oLI.APTS_Option_Group_Text__c.containsIgnoreCase('Menu')){
            if (oLI.Apttus_Config2__LineType__c == 'Option' && oLI.Apttus_Config2__OptionId__c != null ) {
                physicalAsset.APTS_Product_Code__c = oLI.Apttus_Config2__OptionId__r.ProductCode+'_'+oLI.Apttus_Config2__OptionId__r.Description;
            }
        }
        
        return physicalAsset;
    }
    
    /* Method to get the 'Machines & Services' Billing Setting records related to Set of Agreements*/
    public static Map<Id, Id> getBillingSettings(Set<Id> agreementIdSet){
        Map<Id, Id> idToBillingSettingsIdMap = new Map<Id, Id>();
        for(APTS_Billing_Settings__c billingSetting : [SELECT Id,
                                                                APTS_Agreement_ID__c
                                                                FROM APTS_Billing_Settings__c
                                                                WHERE APTS_Agreement_ID__c IN: agreementIdSet
                                                                AND APTS_Agreement_Billing_Type__c = 'Machine'
                                                                LIMIT 50000]){
            idToBillingSettingsIdMap.put(billingSetting.APTS_Agreement_ID__c, billingSetting.Id);
        }
        return idToBillingSettingsIdMap;
    }
    
    /* Method to get the Physical Asset records based on the Unique Number*/
    public static Map<String, PhysicalAsset__c> getPhysicalAsset(Set<String> serialNumberSet){
        Map<String, PhysicalAsset__c> physicalAssetMap = new Map<String, PhysicalAsset__c>();
        for(PhysicalAsset__c oPhysicalAsset : [SELECT Id,Name,
                                                        UniqueNumber__c,
                                                        APTS_FinanceId__c,AssetStatus__c 
                                                        FROM PhysicalAsset__c
                                                        WHERE UniqueNumber__c IN: serialNumberSet]){
            physicalAssetMap.put(oPhysicalAsset.UniqueNumber__c, oPhysicalAsset);
        }
        return physicalAssetMap;
    }

    /* --------- v104 -- End --------
    Method to Populate Physical Asset Response Time Based on SalesOrg */
    Public static string getResponseTime(String SalesOrg,String OptionValue){
        String responseValue = OptionValue;
        if(SalesOrg != null && OptionValue != null){
            String customSettingKey = SalesOrg+'_'+OptionValue;
            PhysicalAssetResponseTimeMapping__c responeTimeMapping = PhysicalAssetResponseTimeMapping__c.getall().get(customSettingKey);
            responseValue = responeTimeMapping == null ? OptionValue:responeTimeMapping.New_Value__c == null ? OptionValue : responeTimeMapping.New_Value__c;
        }
        return responseValue;
    }
        

    /* v105--------- v105 --------/
    Method to Populate Physical Asset PreventiveMaintenanceInterval Based on Option Name */
    Public static string getPrevenetiveMaintenanceIntervel(String productOptionName){
        String maintenanceIntervel = '';
        if(productOptionName != null && productOptionName != ''){   
            List<String> prdNameSplit = productOptionName.split(' ');
            if(prdNameSplit.size() > 2){
                maintenanceIntervel = prdNameSplit[prdNameSplit.size()-2];
                if(maintenanceIntervel != '' && maintenanceIntervel.contains('X')){
                    maintenanceIntervel = maintenanceIntervel.replace('X','');
                }
            }
        }
        return maintenanceIntervel;
    }
    
    //V113 ++ <<
    public static List<PhysicalAsset__c> updatePhAOnMovements(map<Id, Apttus_Config2__OrderLineItem__c> physicalAssetIdToOLIMap, Map<Id, List<APTS_Agreement_PO_Details__c>> agreementPOMap, Map<Id, Apttus_Config2__OrderLineItem__c> idToAllOrderLineItemMap) {

        List<PhysicalAsset__c> physicalAssetUpdateList = new List<PhysicalAsset__c>();
        Set<Id> orderIdSet = new Set<Id>(new Map<Id, Apttus_Config2__OrderLineItem__c>(physicalAssetIdToOLIMap.values()).keySet());
        Set<Id> agreementIdSet = new Set<Id>(); //V115 ++<<>>
        // Map<Id, Apttus_Config2__OrderLineItem__c> oLIMap = getOrderLineItemAdditionalData(orderIdSet);
        //try{
        
        //Add option phA to the map
        for(Apttus_Config2__OrderLineItem__c oOrderLine : idToAllOrderLineItemMap.Values())
        {
            if(oOrderLine.APTS_Physical_Asset__c != null && !oOrderLine.APTS_Is_Primary_L1_Line__c)
            {
                physicalAssetIdToOLIMap.put(oOrderLine.APTS_Physical_Asset__c, oOrderLine);
                agreementIdSet.add(oOrderLine.Apttus_CMConfig__AgreementId__c);//V115 ++<<>>
            }
        }
        Map<Id, Id> idToBillingSettingsIdMap = APTS_OrderLineItemUtils.getBillingSettings(agreementIdSet); //V115 ++<<>>
        for (PhysicalAsset__c updatedPA : getPhysicalAssetOli(physicalAssetIdToOLIMap)) {

            Apttus_Config2__OrderLineItem__c oLI = idToAllOrderLineItemMap.get(physicalAssetIdToOLIMap.get(updatedPA.Id).Id);            
            updatedPA.RefurbishedMachine__c = oLI.APTS_RefurbishedMachine__c;
            updatedPA.AccountLocation__c = oLI.Apttus_Config2__LocationId__c;            
            updatedPA.SalesOrganization__c = oLI.Apttus_Config2__OrderId__r.APTS_Sales_Organization__c;
            updatedPA.SoldTo__c = oLI.Apttus_Config2__OrderId__r.Apttus_Config2__SoldToAccountId__c;           
            updatedPA.StartDate__c = oLI.Apttus_Config2__StartDate__c;
            updatedPA.EndDate__c = oLI.Apttus_Config2__EndDate__c;
            updatedPA.OwnedByCustomer__c = oLI.Apttus_Config2__AssetLineItemId__r.APTS_OwnedByCustomer__c;
            updatedPA.AgreementRecordType__c = oLI.Apttus_CMConfig__AgreementId__r.RecordType.Name;
            updatedPA.Routesales__c = oLI.Apttus_CMConfig__AgreementId__r.APTS_Routesales__c;           
            updatedPA.Billing_Setting__c = idToBillingSettingsIdMap.get(oLI.Apttus_CMConfig__AgreementId__c); //V115 ++ <<>>
            updatedPA = updateLSPDetailOnPhA(updatedPA, oLI, false);             
            if(agreementPOMap != null && !agreementPOMap.isEmpty()) { setAgreementPODetails(updatedPA, agreementPOMap.get(oLI.Apttus_CMConfig__AgreementId__c)); }
            physicalAssetUpdateList.add(updatedPA);
        }
        /* }
             catch(Exception e)
               {

        APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id),'OM',false,true, EMAIL, true);
               } */
        return physicalAssetUpdateList;
    }
    public static PhysicalAsset__c updateLSPDetailOnPhA(PhysicalAsset__c updatedPA, Apttus_Config2__OrderLineItem__c oLI, boolean bAgreementURLApplicable)
    {             
            if(oLI.APTS_Order_LSP_Detail__c != null){
                updatedPA.ConfigurationFileURL__c = oLI.APTS_Order_LSP_Detail__r.APTS_ConfigurationFileURL__c;
                updatedPA.JDECrockeryVolumeSize__c = oLI.APTS_Order_LSP_Detail__r.APTS_JDE_crockeryVolumeSize__c;
                updatedPA.Building__c = oLI.APTS_Order_LSP_Detail__r.APTS_Building__c;
                updatedPA.Floor__c = oLI.APTS_Order_LSP_Detail__r.APTS_Floor__c;
                updatedPA.Area__c = oLI.APTS_Order_LSP_Detail__r.APTS_Area__c;
                updatedPA.CustomerReferenceNumber__c = oLI.APTS_Order_LSP_Detail__r.APTS_CustomerReference__c;
                updatedPA.SmokingArea__c = oLI.APTS_Order_LSP_Detail__r.APTS_SmokingArea__c;
                if(bAgreementURLApplicable)
                    updatedPA.ConfigurationManualAgreementsURL__c = oLI.APTS_Order_LSP_Detail__r.APTS_ConfigurationManualAgreementsURL__c;
                /*if(bPhysicalMovement)
                {
                    updatedPA.StairClimber__c = oLI.APTS_Order_LSP_Detail__r.APTS_StairClimber__c;
                    updatedPA.RequiresLSP__c = oLI.APTS_Order_LSP_Detail__r.APTS_Requires_LSP__c;
                    //updatedPA.CommercialUsage__c = oLI.APTS_Order_LSP_Detail__r.APTS_CommercialMachine__c;
                    updatedPA.SmokingArea__c = oLI.APTS_Order_LSP_Detail__r.APTS_SmokingArea__c;
                    //updatedPA.StairClimber__c = oLI.APTS_Order_LSP_Detail__r.APTS_Elevator_Available__c;                   
                } */
          
            }  
            return  updatedPA;
    }
    //V113 ++ >>
}