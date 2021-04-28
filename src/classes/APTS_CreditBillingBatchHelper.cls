/**
* Class Name : APTS_CreditBillingBatchHelper
* Description : Helper class for APTS_RecurringBillingBatchScheduler Class
* Author : Renuka (Accenture)
* Date Created : 28/07/2020
**/
//v100 17-09-2020: Renuka - DQ-3868 - Populating InvoiceRemark field from the references of superseded BS.
//v101 16-12-2020: Renuka - DQ-4550 - FixTermBillingFlag changes
//v102 23-02-2021: Renuka - DQ-5503 - Adding logic for PeriodStartDate.
//v103 23-03-2021: Renuka - DQ-5773 - ZIndicator fix
public with sharing class APTS_CreditBillingBatchHelper{

    private static final String DEFAULTORDERREASON = 'X99';
    private static final String COLLECTIVEINVOICE = 'Collective Invoice';
    private static final String SINGLEINVOICE = 'Single Invoice';
    private static final String COLLECTIVEINVOICE_WITHSMRYPAGE = 'Collective Invoice – With Summary Page';
    private static final String YES = 'YE';
    private static final String NO = 'NO';
    private static final String CONSUMPTIONMODEL = 'Consumption';
    private static final String BILL_IN_ARREARS = 'Bill In Arrears';
    private static final String BILL_IN_ADVANCE = 'Bill In Advance';
    private static final String BILLING_DAY_OF_MONTH = 'Billing Day of Month';
    private static final String READY_FOR_BILLING_DATE = 'Ready for Billing Date';
    private static final String END_OF_MONTH = 'End of Month';
    private static final String CONSUMPTIONINDICATORFLAG = 'A01';
    private static final String CONSUMPTIONRECORDTYPE = 'Consumption Model';
    private static final String NONUSAGETYPE = 'NonUsage';
    private static final String BILLINGSCHEDULE = 'Billing Schedule';
    private static final String ADMINORDER = 'Admin Order';
    private static final String STARTDATE = 'StartDate';
    private static final String ENDDATE = 'EndDate';
    private static final String CREDITORDERSAPORDERTYPE ='XC09';
    private static final String MACHINE ='Machine';
    private static final Set<String> fixedTermTypeXD09 = new Set<String>{'Fixed Cost','Fixed Costs and Ingredients'};
    private static final string PERIOD_START_DATE = 'Period Start Date';

    
    /** Method Name : createAdminOrder
    * Description : Method to create admin Order and Send the Order and Order Line Item to SAP for Invoicing
    **/
    public static Map<String,Id> createAdminOrder(List<Apttus_Billing__BillingSchedule__c> billingScheduleRecords,
                                                    Map<String, Id> adminOrderCreatedInEachChunk,
                                                    Map<Id,Apttus_Config2__OrderLineItem__c> primaryOrderLineToUpdate,
                                                    Map<String,String> invoiceMap,
                                                    Map<String,Date> primaryL1DateMap,
                                                    Map<String,String> invoiceRemarkMap){

        Set<Id> primaryAssetLine = new Set<Id>();
        Set<Id> agreementId = new Set<Id>();
        Set<Id> accountId = new Set<Id>();
        Map<Id,Apttus_Billing__BillingSchedule__c> billingSchedulesMap = new  Map<Id,Apttus_Billing__BillingSchedule__c>();
        Map<Id,Apttus_Billing__BillingSchedule__c> billingSchedulesOrderLineMap = new  Map<Id,Apttus_Billing__BillingSchedule__c>();
        Map<Id,List<APTS_Agreement_PO_Details__c>> assetAgrmntPODetailsMap = new  Map<Id,List<APTS_Agreement_PO_Details__c>>();
        Map<Id,Account> accountDataMap = new Map<Id,Account>();
        List<string> fixedTermTypeList = new List<string>();
        Map<Id,Apttus__APTS_Agreement__c> fixedTermagreementMap = new Map<Id,Apttus__APTS_Agreement__c>();//V101
        //Set<Id> fixedTermagreementId = new Set<Id>();
        Map<Id,APTS_Billing_Settings__c> billingSetting = new Map<Id,APTS_Billing_Settings__c>();
        try{ 
            String fixedTermType = System.Label.APTS_FixedTermType;
            if(String.isNotBlank(fixedTermType)){
                fixedTermTypeList = fixedTermType.split(',');
            }
            //From the billing schdedules create Asset Billing Schedules Map
            for (Apttus_Billing__BillingSchedule__c billingScheduleList : billingScheduleRecords) {
                billingSchedulesMap.put(billingScheduleList.Id,billingScheduleList);
               
                if(billingScheduleList.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__c != null){
                    agreementId.add(billingScheduleList.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__c);
                }else{
                    agreementId.add(billingScheduleList.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c);
                }
                // retieve the orginated Bundle Line Item from options and primaryAssetLine Set
                if(billingScheduleList.Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Asset__c != null){
                    //Populate ExternalInvoice Number from superseded BS.
                    String keyforInvoiceMap = String.valueOf(billingScheduleList.Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Asset__c+NONUSAGETYPE);
                    system.debug(+billingScheduleList.Id+' , '+billingScheduleList.Apttus_Billing__InvoicedScheduleId__c);
                    if(billingScheduleList.Apttus_Billing__InvoicedScheduleId__c != NULL 
                        && billingScheduleList.Apttus_Billing__InvoicedScheduleId__r.APTS_Invoice__c != NULL
                        && billingScheduleList.Apttus_Billing__InvoicedScheduleId__r.APTS_Invoice__r.APTS_External_Invoice_Number__c != NULL){
                        if(invoiceRemarkMap.containsKey(keyforInvoiceMap)) {
                            if( ! invoiceRemarkMap.get(keyforInvoiceMap).contains(billingScheduleList.Apttus_Billing__InvoicedScheduleId__r.APTS_Invoice__r.APTS_External_Invoice_Number__c)){
                                String externalInvoiceNr = invoiceRemarkMap.get(keyforInvoiceMap)+', '+billingScheduleList.Apttus_Billing__InvoicedScheduleId__r.APTS_Invoice__r.APTS_External_Invoice_Number__c;
                                invoiceRemarkMap.put(keyforInvoiceMap, externalInvoiceNr);
                            }
                        }else{
                            invoiceRemarkMap.put(keyforInvoiceMap, billingScheduleList.Apttus_Billing__InvoicedScheduleId__r.APTS_Invoice__r.APTS_External_Invoice_Number__c);
                        }
                    }
                    String keyForDate = String.valueOf(billingScheduleList.Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Asset__c);
                    if(!primaryAssetLine.contains(billingScheduleList.Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Asset__c)){
                        primaryAssetLine.add(billingScheduleList.Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Asset__c);
                    }
                    //populate p1LineBillingScheduleStartDateMap with the earliest start date 
                    if(billingScheduleList.Apttus_Billing__PeriodStartDate__c != null && !billingScheduleList.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__IsOptionRollupLine__c){
                        if(!primaryL1DateMap.containsKey(keyForDate+STARTDATE)){
                            primaryL1DateMap.put(keyForDate+STARTDATE,billingScheduleList.Apttus_Billing__PeriodStartDate__c);
                        }   
                        else if(primaryL1DateMap.get(keyForDate+STARTDATE) > billingScheduleList.Apttus_Billing__PeriodStartDate__c){
                            primaryL1DateMap.put(keyForDate+STARTDATE,billingScheduleList.Apttus_Billing__PeriodStartDate__c);
                        }
                    }
                    
                    if(billingScheduleList.Apttus_Billing__PeriodEndDate__c != null && !billingScheduleList.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__IsOptionRollupLine__c){
                        if(!primaryL1DateMap.containsKey(keyForDate+ENDDATE)){
                            primaryL1DateMap.put(keyForDate+ENDDATE,billingScheduleList.Apttus_Billing__PeriodEndDate__c);
                        }   
                        else if(primaryL1DateMap.get(keyForDate+ENDDATE) < billingScheduleList.Apttus_Billing__PeriodEndDate__c){
                            primaryL1DateMap.put(keyForDate+ENDDATE,billingScheduleList.Apttus_Billing__PeriodEndDate__c);
                        }
                    } 
                    
                }
                //system.debug('@@@p1LineBillingScheduleEndDateMap:'+p1LineBillingScheduleEndDateMap); 
                // Account Id related to billing schedules
                if(billingScheduleList.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c != null){
                    accountId.add(billingScheduleList.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c);  
                }
                if(APTS_BIRUtils.PRODUCTORSERVICE.equalsIgnoreCase(billingScheduleList.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__LineType__c)){
                    // this condition is for skipping the Line Type == Product /Service other than P1 lines
                    if(billingScheduleList.Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Line__c){
                        billingSchedulesOrderLineMap.put(billingScheduleList.Id,billingScheduleList);
                    }
                }else{
                    billingSchedulesOrderLineMap.put(billingScheduleList.Id,billingScheduleList);
                }
                //v103
                if(billingScheduleList.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__c != null){
                    if(billingScheduleList.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__r.APTS_Fixed_Term_Type__c != null
                        && fixedTermTypeList != null
                        && fixedTermTypeList.contains(billingScheduleList.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__r.APTS_Fixed_Term_Type__c)){
                        //fixedTermagreementId.add(billingScheduleList.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__c);
                        fixedTermagreementMap.put(billingScheduleList.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__c,billingScheduleList.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__r);
                    }
                }else if(billingScheduleList.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c != null){
                    if(billingScheduleList.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__r.APTS_Fixed_Term_Type__c != null
                        && fixedTermTypeList != null
                        && fixedTermTypeList.contains(billingScheduleList.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__r.APTS_Fixed_Term_Type__c)){
                        //fixedTermagreementId.add(billingScheduleList.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c);
                        fixedTermagreementMap.put(billingScheduleList.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c,billingScheduleList.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__r);
                    }
                }
                
            }
            
            List<APTS_Agreement_PO_Details__c> tempListPo;
            if(agreementId.size()>0){
                for (APTS_Agreement_PO_Details__c agreementPoDetailsData : [SELECT Id,
                                                                            APTS_Agreement__c,
                                                                            APTS_PO_Category__c,
                                                                            APTS_PO_Number__c,
                                                                            APTS_PO_Number_Required__c,
                                                                            APTS_PO_Number_Type__c
                                                                        FROM APTS_Agreement_PO_Details__c
                                                                        WHERE APTS_Agreement__c IN: agreementId
                                                                        LIMIT 50000]){
                    tempListPo = new List<APTS_Agreement_PO_Details__c>();
                    if(assetAgrmntPODetailsMap.containsKey(agreementPoDetailsData.APTS_Agreement__c)){
                        tempListPo = assetAgrmntPODetailsMap.get(agreementPoDetailsData.APTS_Agreement__c);
                        if (!tempListPo.contains(agreementPoDetailsData)){
                            tempListPo.add(agreementPoDetailsData);
                            assetAgrmntPODetailsMap.put(agreementPoDetailsData.APTS_Agreement__c,tempListPo);
                        }
                    }else{
                        tempListPo.add(agreementPoDetailsData);
                        assetAgrmntPODetailsMap.put(agreementPoDetailsData.APTS_Agreement__c, new List<APTS_Agreement_PO_Details__c>(tempListPo));
                    }          
                }
                // Retrieve Agreement's Billing Setting
                for (APTS_Billing_Settings__c agreementBillingSetting : [SELECT Id,
                                                                            APTS_Agreement_ID__c,
                                                                            APTS_Agreement_ID__r.APTS_Bill_to_Party_MachServ__c,
                                                                            APTS_Agreement_ID__r.APTS_Payer_Machines_Services__c,
                                                                            APTS_Agreement_Billing_Type__c,
                                                                            APTS_Billing_Preference_Setting__c,
                                                                            APTS_Billing_Rule_Contract__c,
                                                                            APTS_Bill_To_ID__c,
                                                                            APTS_Invoice_Delivery_Preference__c,
                                                                            APTS_Invoice_Type__c,
                                                                            APTS_Payment_Method__c,
                                                                            APTS_Payment_Method__r.APTS_Payment_Method_Code__c,
                                                                            APTS_Payment_Term_Setting__c,
                                                                            APTS_Sales_Organization__c
                                                                        FROM APTS_Billing_Settings__c
                                                                        WHERE APTS_Agreement_ID__c IN: agreementId
                                                                        AND APTS_Agreement_Billing_Type__c =: MACHINE
                                                                        LIMIT 50000]){
                    billingSetting.put(agreementBillingSetting.APTS_Agreement_ID__c,agreementBillingSetting);
                }
            }
            // Retrieve Division, Distribution Channel, Sales Organization from  Account, V42 Added EDI fields to the query.
            if(accountId.size()>0){
                for(Account account  :  [SELECT  Id,
                                                Sales_Organization__c,
                                                Division__c,
                                                Distribution_Channel__c,
                                                Related_Payer_Machines_Services__c,
                                                Apttus_Config2__BillingPreferenceId__c,
                                                Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Delivery_Preference__c,
                                                Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Type__c,
                                                Apttus_Config2__BillingPreferenceId__r.Apttus_Config2__BillingInterval__c,
                                                APTS_Payment_Method__c,
                                                APTS_Payment_Method__r.APTS_Payment_Method_Code__c,
                                                Apttus_Config2__PaymentTermId__c,
                                                Related_Bill_to_Machines_Services__c,
                                                Related_Bill_to_Machines_Services__r.Apttus_Config2__BillingPreferenceId__c,
                                                Related_Bill_to_Machines_Services__r.Apttus_Config2__PaymentTermId__c,
                                                Related_Bill_to_Machines_Services__r.APTS_Payment_Method__c,
                                                Related_Bill_to_Machines_Services__r.APTS_Payment_Method__r.APTS_Payment_Method_Code__c,
                                                Related_Bill_to_Machines_Services__r.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Type__c,
                                                Related_Bill_to_Machines_Services__r.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Delivery_Preference__c,
                                                EDI_Name_of_Orderer__c,
                                                EDI_Payer_Head_Text__c,
                                                EDI_Reference_Number__c
                                                FROM Account
                                                WHERE Id IN: accountId
                                                LIMIT 50000]){
                    accountDataMap.put(account.Id,account);
                }
            }
            // Create Admin Order Header
            Map<String,Apttus_Config2__Order__c> adminOrderHeaderMap = processAdminOrderFromAssets(billingSchedulesMap,
                                                                                                    assetAgrmntPODetailsMap,
                                                                                                    accountDataMap,billingSetting,
                                                                                                    adminOrderCreatedInEachChunk,
                                                                                                    fixedTermagreementMap,
                                                                                                    invoiceMap);
            for(String createdAdminOrderKey : adminOrderHeaderMap.keySet()){
                if(adminOrderHeaderMap.containsKey(createdAdminOrderKey)
                    && adminOrderHeaderMap.get(createdAdminOrderKey) != null){
                    adminOrderCreatedInEachChunk.put(createdAdminOrderKey,adminOrderHeaderMap.get(createdAdminOrderKey).Id);

                }
            }
            //system.debug('*****After adminOrder Line item *********'+adminOrderCreatedInEachChunk);
            // Create Order Line Item & Order Adjustment Line Item
            Map<Id,Apttus_Config2__OrderLineItem__c> newOrderLineBillingMap = processAdminOrderLineItemFromAssets(billingSchedulesMap,
                                                                                                                billingSchedulesOrderLineMap,
                                                                                                                adminOrderCreatedInEachChunk,
                                                                                                                primaryAssetLine,
                                                                                                                fixedTermTypeList,
                                                                                                                fixedTermagreementMap,
                                                                                                                primaryOrderLineToUpdate,
                                                                                                                primaryL1DateMap);
            // Update Billing schedules
            updateBillingscheduleStatus(billingScheduleRecords,newOrderLineBillingMap); 
        }catch(Exception e){
            APTS_BIRUtils.logError(null,null,null,e,APTS_BIRUtils.BATCH,APTS_BIRUtils.CREATEADMINORDER,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,true);
            return null;
        }
        return adminOrderCreatedInEachChunk;
    }
    /** Method Name : ProcessAdminOrderFromAssets
    * Description : Method to create admin Order and Send the Order and Order Line Item to SAP for Invoicing
    **/
    public static Map<String,Apttus_Config2__Order__c> processAdminOrderFromAssets(Map<Id,Apttus_Billing__BillingSchedule__c> billingSchedulesMap,
                                                                                    Map<Id,List<APTS_Agreement_PO_Details__c>> assetAgrmntPODetailsMap,
                                                                                    Map<Id,Account> accountDataMap,
                                                                                    Map<Id,APTS_Billing_Settings__c> billingSetting,
                                                                                    Map<String,Id> adminOrderCreatedInEachChunk,
                                                                                    Map<Id,Apttus__APTS_Agreement__c> fixedTermagreementMap,
                                                                                    Map<String,String> invoiceMap){
        Map<String,Apttus_Config2__Order__c> finalOrderMapToInsert = new Map<String,Apttus_Config2__Order__c>();
        Id adminOrderId;
        try{
            // Admin Order Record Id
            if(Schema.SObjectType.Apttus_Config2__Order__c.getRecordTypeInfosByName().get(APTS_BIRUtils.ADMINORDER)!=null){
                adminOrderId = Schema.SObjectType.Apttus_Config2__Order__c.getRecordTypeInfosByName().get(APTS_BIRUtils.ADMINORDER).getRecordTypeId();
            }
            
            //Splitting logic for Different SAP Order Type - XD09 and XD12
            for (Apttus_Billing__BillingSchedule__c  billingScheduleData : billingSchedulesMap.values()){
                // For creating Admin Order header Look for the options's APTS_Is_Primary_L1_Asset__c field. 
                // For each Primary L1 line picked in the Billing Run, a new Admin Order Header need to be created
                if(!APTS_BIRUtils.PRODUCTORSERVICE.equalsIgnoreCase(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__LineType__c)){
                    createAdminOrderHeader(billingScheduleData,assetAgrmntPODetailsMap,accountDataMap,
                                                                                    billingSetting,fixedTermagreementMap,adminOrderId,
                                                                                    NONUSAGETYPE,finalOrderMapToInsert,adminOrderCreatedInEachChunk,
                                                                                    invoiceMap);
                }
                //system.debug('**************finalOrderMapToInsert SIZE *****'+finalOrderMapToInsert.size());
                //system.debug('**************finalOrderMapToInsert*****'+finalOrderMapToInsert);
            }
            if(!finalOrderMapToInsert.isEmpty()
                && finalOrderMapToInsert.values() != null){
                //system.debug('**************INSERT INSIDE *****');
                Database.SaveResult[] srList = Database.insert(finalOrderMapToInsert.values(), false);
                APTS_BIRUtils.logError(null,srList,null,null,APTS_BIRUtils.BATCH,APTS_BIRUtils.ORDEROBJECTNAME,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,false);
            }
        }catch(Exception e){APTS_BIRUtils.logError(null,null,null,e,APTS_BIRUtils.BATCH,APTS_BIRUtils.ORDEROBJECTNAME,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,true);
            return null;
        }
        return finalOrderMapToInsert;  
    }

    /** Method Name : createAdminOrderHeader
    * Description : Method to create admin Order header XC09
    **/
    public static void createAdminOrderHeader(Apttus_Billing__BillingSchedule__c billingScheduleData,
                                                                                Map<Id,List<APTS_Agreement_PO_Details__c>> assetAgrmntPODetailsMap,
                                                                                Map<Id,Account> accountDataMap,
                                                                                Map<Id,APTS_Billing_Settings__c> billingSetting,
                                                                                Map<Id,Apttus__APTS_Agreement__c> fixedTermagreementMap,
                                                                                Id adminOrderId,
                                                                                String typeOfKey,
                                                                                Map<String,Apttus_Config2__Order__c> orderMapToInsert,
                                                                                Map<String,Id> adminOrderCreatedInEachChunk,
                                                                                Map<String,String> invoiceMap){
        try{
            if(!orderMapToInsert.containsKey(String.valueOf(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Asset__c)+typeOfKey)
                && !adminOrderCreatedInEachChunk.containsKey(String.valueOf(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Asset__c)+typeOfKey)){
                Apttus_Config2__Order__c order = new Apttus_Config2__Order__c();
                if(adminOrderId!=null){
                    order.RecordTypeId = adminOrderId;
                }
                order.Apttus_Config2__Status__c = APTS_BIRUtils.ACTIVATED;
                order.APTS_Status__c = APTS_BIRUtils.INVOICINGSTATUS;
                order.APTS_Order_Sub_Type__c = APTS_BIRUtils.ORDERSUBTYPE;
                order.APTS_Order_Type__c = APTS_BIRUtils.ADMINORDER;
                order.APTS_Remove_Billing_Block_Indicator__c = true;
                order.APTS_Order_Reason__c = DEFAULTORDERREASON;
                //order.Apttus_Config2__ActivatedDate__c = system.today(); 
                order.Apttus_Config2__ReadyForBillingDate__c = system.today();
                order.APTS_Name__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__r.Name;
                order.Apttus_Config2__OrderStartDate__c = Date.today();
                order.Apttus_Config2__PriceListId__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PriceListId__c;
                if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__c  != null){
                    order.Apttus_CMConfig__AgreementId__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__c;
                }else{
                   order.Apttus_CMConfig__AgreementId__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c; 
                }
                order.Apttus_Config2__SoldToAccountId__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c;
                order.Apttus_Config2__LocationId__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__LocationId__c;
                order.Apttus_Config2__PricingDate__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PricingDate__c;
                order.APTS_Billing_Date__c = getBillingDate(billingScheduleData);
                if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PriceListId__c != null){
                   order.CurrencyIsoCode = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PriceListId__r.CurrencyIsoCode; 
                }
                /**************************************************************************
                *******TYPE***********==*******SAP ORDER TYPE******==FIXED TERM FLAG******
                * Machines and Services              XC09              BLANK
                * Fixed+Machines and Services        XC09                Z
                * Consumption                        XC09               A01
                * Consumption+Services(Non Usage)    XC09               A01
                * Consumption 
                    +Services Fixed term(Non USAGE)  XC09               A01
                /**************************************************************************/
                if(APTS_BIRUtils.CONSUMPTIONTYPEOFCONTRACT.equalsIgnoreCase(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_Type_Of_Contract__c)){
                    order.APTS_SAP_OrderType__c = CREDITORDERSAPORDERTYPE;
                    // consumption+Fixed Term V101
                    order.APTS_Fix_Term_Billing_Flag__c = CONSUMPTIONINDICATORFLAG;
                }else{
                    // Only Machine & Services
                    order.APTS_SAP_OrderType__c = CREDITORDERSAPORDERTYPE;
                    // Machine & Services with Fixed Term
                    if(!fixedTermagreementMap.isEmpty() //v101 Changed the fix_termLogic
                            && fixedTermagreementMap.containsKey(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__c) 
                            && fixedTermagreementMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__c) != null 
                            && fixedTermTypeXD09.contains(fixedTermagreementMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__c).APTS_Fixed_Term_Type__c)){
                            
                        order.APTS_Fix_Term_Billing_Flag__c = APTS_BIRUtils.FIXEDTERMINDICATOR;   
                    
                    }else if(!fixedTermagreementMap.isEmpty() //v101 Changed the fix_termLogic
                            && fixedTermagreementMap.containsKey(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c) 
                            && fixedTermagreementMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c) != null 
                            && fixedTermTypeXD09.contains(fixedTermagreementMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c).APTS_Fixed_Term_Type__c)){
                        order.APTS_Fix_Term_Billing_Flag__c = APTS_BIRUtils.FIXEDTERMINDICATOR;   
                    }
                }
                /**************************************************************************/
                if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__r.Apttus__Primary_Contact__c != null){
                    order.Apttus_Config2__PrimaryContactId__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__r.Apttus__Primary_Contact__c;
                }
                else if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__r.Apttus__Primary_Contact__c != null){
                    order.Apttus_Config2__PrimaryContactId__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__r.Apttus__Primary_Contact__c;
                }
                // payer Ingredients
                if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_PayerIngredients__c != null){
                    order.APTS_PayerIngredients__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_PayerIngredients__c;
                }
                
                // Payer Machine/Services
                if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_PayerMachinesServices__c != null){
                    order.APTS_PayerMachinesServices__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_PayerMachinesServices__c;
                }
                
                // Bill To Ingredients
                if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_Bill_to_Party_Ingredients_and_Payer__c != null){
                    order.APTS_Bill_to_Party_Ingredients_and_Payer__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_Bill_to_Party_Ingredients_and_Payer__c;   
                } 
                // Bill to Services
                if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_Bill_to_Party_Machines_Services__c != null){
                    order.APTS_Bill_to_Party_Machines_Services__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_Bill_to_Party_Machines_Services__c;
                }

                // Setting of Billing key fields on Order Header
                if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__c != null){
                    populateBillingPreference(billingSetting,billingScheduleData,accountDataMap,order, 
                        billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__c,
                        billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__r.APTS_Check_on_Account_Machines__c,
                        invoiceMap);
                }else if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c != null){
                    populateBillingPreference(billingSetting,billingScheduleData,accountDataMap,order,
                        billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c,
                        billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__r.APTS_Check_on_Account_Machines__c,
                        invoiceMap);
                }
                // Invoice list Indicator and Collective list indicator flag setting
                if(String.isNotBlank(order.APTS_InvoiceType__c)){
                    if(COLLECTIVEINVOICE.equalsIgnoreCase(order.APTS_InvoiceType__c)){
                        order.APTS_InvoiceType__c = SINGLEINVOICE;
                        //order.APTS_Collective_Billing_Indicator__c = true; Collective Invoice is not applicable for XC09
                        order.APTS_Invoice_List_Indicator__c = NO;
                    }else if(COLLECTIVEINVOICE_WITHSMRYPAGE.equalsIgnoreCase(order.APTS_InvoiceType__c)){
                        order.APTS_InvoiceType__c = SINGLEINVOICE;
                        //order.APTS_Collective_Billing_Indicator__c = true; Collective Invoice is not applicable for XC09
                        order.APTS_Invoice_List_Indicator__c = YES;
                    }else if(APTS_BIRUtils.INVOICELISTWITHOUTSUMMARY.equalsIgnoreCase(order.APTS_InvoiceType__c) 
                        || APTS_BIRUtils.INVOICELISTWITHSUMMARY.equalsIgnoreCase(order.APTS_InvoiceType__c)){
                        order.APTS_Invoice_List_Indicator__c = YES;
                    }
                    else{
                        order.APTS_Invoice_List_Indicator__c = NO;
                        order.APTS_Collective_Billing_Indicator__c = false;
                    }
                }
                
                // Setting Sales Organisation, Distribution channel and Division
                if(!accountDataMap.isEmpty()
                    && billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c != null
                    && accountDataMap.containsKey(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c) != null
                    && accountDataMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c) != null){
                        order.APTS_Sales_Organization__c = accountDataMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c).Sales_Organization__c != null? accountDataMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c).Sales_Organization__c : null;
                        order.APTS_Distribution_Channel__c = accountDataMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c).Distribution_Channel__c != null? accountDataMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c).Distribution_Channel__c : null;
                        order.APTS_Division__c = accountDataMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c).Division__c != null? accountDataMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c).Division__c : null;  
                        order.APTS_EDI_Name_of_Orderer__c=accountDataMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c).EDI_Name_of_Orderer__c != null? accountDataMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c).EDI_Name_of_Orderer__c : null;  
                        order.APTS_EDI_Payer_Head_Text__c=accountDataMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c).EDI_Payer_Head_Text__c != null? accountDataMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c).EDI_Payer_Head_Text__c : null;  
                        order.APTS_EDI_Reference_Number__c=accountDataMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c).EDI_Reference_Number__c != null? accountDataMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c).EDI_Reference_Number__c : null;  
                }
                if(!assetAgrmntPODetailsMap.isEmpty()){
                    if(assetAgrmntPODetailsMap.containsKey(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__c) 
                        && assetAgrmntPODetailsMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__c) != null){
                        List<APTS_Agreement_PO_Details__c> poDetails = assetAgrmntPODetailsMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__c);
                        for(APTS_Agreement_PO_Details__c agreementPoDetail : poDetails){
                            if(APTS_BIRUtils.MACHINE.equalsIgnoreCase(agreementPoDetail.APTS_PO_Category__c)){
                                order.Apttus_Config2__PONumber__c = agreementPoDetail.APTS_PO_Number__c;
                            }
                        }
                    }
                }
                else if(!assetAgrmntPODetailsMap.isEmpty()){
                    if(assetAgrmntPODetailsMap.containsKey(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c) 
                        && assetAgrmntPODetailsMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c) != null){
                        List<APTS_Agreement_PO_Details__c> poDetails = assetAgrmntPODetailsMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c);
                        for(APTS_Agreement_PO_Details__c agreementPoDetail : poDetails){
                            if(APTS_BIRUtils.MACHINE.equalsIgnoreCase(agreementPoDetail.APTS_PO_Category__c)){
                                order.Apttus_Config2__PONumber__c = agreementPoDetail.APTS_PO_Number__c;
                            }
                        }
                    }
                }
                orderMapToInsert.put(String.valueOf(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Asset__c+NONUSAGETYPE),order); 
            }
            //system.debug('==>inSIE create Admin Order Method orderMapToInsert ==>'+orderMapToInsert);
        }catch(Exception e){APTS_BIRUtils.logError(null,null,null,e,APTS_BIRUtils.BATCH,APTS_BIRUtils.ORDEROBJECTNAME,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,true);}  
    }
    /** Method Name : ProcessAdminOrderFromAssets
    * Description : Method to create admin Order and Send the Order and Order Line Item to SAP for Invoicing
    **/
    public static Map<Id,Apttus_Config2__OrderLineItem__c> processAdminOrderLineItemFromAssets(Map<Id,Apttus_Billing__BillingSchedule__c> billingSchedulesMap,
                                                                                                Map<Id,Apttus_Billing__BillingSchedule__c> billingSchedulesOrderLineMap,
                                                                                                Map<String,Id> adminOrderCreatedInEachChunk,
                                                                                                Set<Id> primaryAssetLine,
                                                                                                List<string> fixedTermTypeList,
                                                                                                Map<Id,Apttus__APTS_Agreement__c> fixedTermagreementMap,
                                                                                                Map<Id,Apttus_Config2__OrderLineItem__c> primaryOrderLineToUpdate,
                                                                                                Map<String,Date> primaryL1DateMap){
        Map<Id,Apttus_Config2__OrderLineItem__c> oliBillingScheduleMap = new Map<Id,Apttus_Config2__OrderLineItem__c>();
        Map<Id,Apttus_Config2__OrderLineItem__c> primaryOliToInsert = new Map<Id,Apttus_Config2__OrderLineItem__c>();
        Map<Id,Apttus_Config2__OrderLineItem__c> insertedPrimaryLine = new Map<Id,Apttus_Config2__OrderLineItem__c>();
        Map<Id,Apttus_Config2__OrderLineItem__c> insertedOrderLineMap = new Map<Id,Apttus_Config2__OrderLineItem__c>();
        // Temp Map
        Map<String,Apttus_Config2__OrderLineItem__c> finalOLIMap = new Map<String,Apttus_Config2__OrderLineItem__c>();
        Map<String,List<Apttus_Config2__OrderLineItem__c>> oldprimaryLineWithNewOptionsMap = new Map<String,List<Apttus_Config2__OrderLineItem__c>>();
        Map<String,Apttus_Config2__OrderLineItem__c> tempNewPrimaryMap = new Map<String,Apttus_Config2__OrderLineItem__c>();
        Set<Id> primaryLineOLIToCreate = new Set<Id>();
        Map<String,Apttus_Config2__OrderLineItem__c> createdP1LineMap = new Map<String,Apttus_Config2__OrderLineItem__c>();
        try{
            if(!primaryAssetLine.isEmpty()){
                Map<String,Apttus_Config2__OrderLineItem__c> tempMap = existingP1LineCheck(adminOrderCreatedInEachChunk.values(),primaryAssetLine);
                //system.debug('tempMap==> Inside Primary Line Check'+tempMap);
                for(Id primaryL1assetId : primaryAssetLine){
                    if(tempMap.containskey(primaryL1assetId+CREDITORDERSAPORDERTYPE)){
                        insertedPrimaryLine.put(tempMap.get(primaryL1assetId+CREDITORDERSAPORDERTYPE).Apttus_Config2__OrderId__c,
                                                                            tempMap.get(primaryL1assetId+CREDITORDERSAPORDERTYPE));
                        createdP1LineMap.put(String.valueOf(primaryL1assetId)+NONUSAGETYPE,tempMap.get(primaryL1assetId+CREDITORDERSAPORDERTYPE)); 
                    }
                    else{
                        primaryLineOLIToCreate.add(primaryL1assetId);
                    }
                }
            }
            //system.debug('primaryLineOLIToCreate==>'+primaryLineOLIToCreate);
            //system.debug('==> primaryAssetLine ==>'+primaryAssetLine);
            //system.debug('createdP1LineMap==>'+createdP1LineMap);
            Id orderId ;
            for (Apttus_Billing__BillingSchedule__c  billingScheduleData : billingSchedulesMap.values()){

                if(!adminOrderCreatedInEachChunk.isEmpty()){
                    //DFT2C-2144 : Fix P4 - 2 machines on one order
                    orderId = null;
                    // Option Lines - Look for Pl Asset Line
                    if(!APTS_BIRUtils.PRODUCTORSERVICE.equalsIgnoreCase(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__LineType__c)){

                        if(adminOrderCreatedInEachChunk.containsKey(String.valueOf(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Asset__c)+ NONUSAGETYPE)
                                && adminOrderCreatedInEachChunk.get(String.valueOf(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Asset__c)+ NONUSAGETYPE)!= null
                                && billingSchedulesOrderLineMap.containsKey(billingScheduleData.Id)){
                                orderId = adminOrderCreatedInEachChunk.get(String.valueOf(String.valueOf(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Asset__c)+NONUSAGETYPE));
                                //system.debug('==> INSIDE NON USAGE TYPE ADMIN ORDER==='+orderId);
                        }
                    }
                    // Primary Lines - Look for It's Id
                    else{
                        if(APTS_BIRUtils.CONSUMPTIONTYPEOFCONTRACT.equalsIgnoreCase(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_Type_Of_Contract__c)){
                             if(adminOrderCreatedInEachChunk.containsKey(String.valueOf(billingScheduleData.Apttus_Billing__AssetLineItemId__c)
                                                        + NONUSAGETYPE)
                                && adminOrderCreatedInEachChunk.get(String.valueOf(billingScheduleData.Apttus_Billing__AssetLineItemId__c)
                                                        + NONUSAGETYPE)!= null
                                && billingSchedulesOrderLineMap.containsKey(billingScheduleData.Id)
                                && !createdP1LineMap.containsKey(String.valueOf(billingScheduleData.Apttus_Billing__AssetLineItemId__c)+NONUSAGETYPE)){
                                orderId = adminOrderCreatedInEachChunk.get(String.valueOf(billingScheduleData.Apttus_Billing__AssetLineItemId__c)
                                                                                            +NONUSAGETYPE);
                                //system.debug('==> INSIDE NON USAGE CONMSUPTION ADMIN ORDER==='+orderId);
                            }
                        }else {
                            if(adminOrderCreatedInEachChunk.containsKey(String.valueOf(billingScheduleData.Apttus_Billing__AssetLineItemId__c)
                                                    + NONUSAGETYPE)
                                && adminOrderCreatedInEachChunk.get(String.valueOf(billingScheduleData.Apttus_Billing__AssetLineItemId__c)
                                                    + NONUSAGETYPE)!= null
                                && billingSchedulesOrderLineMap.containsKey(billingScheduleData.Id)
                                && !createdP1LineMap.containsKey(String.valueOf(billingScheduleData.Apttus_Billing__AssetLineItemId__c)+NONUSAGETYPE)){
                                orderId = adminOrderCreatedInEachChunk.get(String.valueOf(billingScheduleData.Apttus_Billing__AssetLineItemId__c)
                                                                                        +NONUSAGETYPE);
                                //system.debug('==> INSIDE NON USAGE CONMSUPTION ADMIN ORDER==='+orderId);
                            }
                        }
                    } 
                    //system.debug('===OrderId==='+orderId);
                    if( orderId != null){
                        Apttus_Config2__OrderLineItem__c orderLineItem = new Apttus_Config2__OrderLineItem__c();
                        orderLineItem.Apttus_Config2__OrderId__c = orderId;
                        //orderLineItem.Apttus_Config2__ActivatedDate__c = system.today(); 
                        orderLineItem.Apttus_Config2__ReadyForBillingDate__c = system.today();
                        orderLineItem.APTS_Status__c = APTS_BIRUtils.ACTIVATED;
                        orderLineItem.Apttus_Config2__Status__c = APTS_BIRUtils.ACTIVATED;
                        orderLineItem.APTS_Item_Relevant_for_SAP__c = true;
                        //Added below line to capture the currency from the price list for defect# 22384
                        orderLineItem.CurrencyIsoCode=billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PriceListId__r.CurrencyIsoCode;
                        orderLineItem.APTS_SAP_OrderType__c = CREDITORDERSAPORDERTYPE;
                        orderLineItem.APTS_BillingSchedule__c = billingScheduleData.Id;
                        if(billingScheduleData.Apttus_Billing__OrderLineItemId__c != null){
                            orderLineItem.APTS_Original_Order_Line_Item__c = billingScheduleData.Apttus_Billing__OrderLineItemId__c;
                        }
                        orderLineItem.Apttus_Config2__StartDate__c = billingScheduleData.Apttus_Billing__PeriodStartDate__c;
                        orderLineItem.Apttus_Config2__EndDate__c = billingScheduleData.Apttus_Billing__PeriodEndDate__c;
                        orderLineItem.Apttus_Config2__IsPrimaryLine__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__IsPrimaryLine__c;
                        orderLineItem.Apttus_Config2__LineType__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__LineType__c;
                        orderLineItem.Apttus_Config2__HasOptions__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__HasOptions__c;
                        orderLineItem.Apttus_Config2__ChargeType__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ChargeType__c;
                        orderLineItem.APTS_Option_Group_Text__c = String.isNotBlank(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_Option_Group_Text__c) ? 
                                                                            billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_Option_Group_Text__c : APTS_BIRUtils.EMPTY_STRING;
                        orderLineItem.APTS_Type_of_Contract__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_Type_of_Contract__c;
                        orderLineItem.Apttus_Config2__PriceListId__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PriceListId__c;
                        orderLineItem.Apttus_Config2__PriceListItemId__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PriceListItemId__c;
                        orderLineItem.Apttus_Config2__ProductId__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ProductId__c;
                        if( billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__c != null){
                            orderLineItem.Apttus_CMConfig__AgreementId__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__c;
                        }else {
                            orderLineItem.Apttus_CMConfig__AgreementId__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c;
                        }
                        
                        orderLineItem.Apttus_Config2__Quantity__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__Quantity__c;
                        orderLineItem.Apttus_Config2__SellingUom__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__SellingUom__c;
                        orderLineItem.Apttus_Config2__AssetLineItemId__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Id;
                        // Bill to Ingredients
                        if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_Bill_to_Party_Ingredients_and_Payer__c != null){
                            orderLineItem.APTS_Bill_to_Party_Ingredients_and_Payer__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_Bill_to_Party_Ingredients_and_Payer__c;
                        }
                       
                        // Bill To Machines and SERvices
                        if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_Bill_to_Party_Machines_Services__c != null){
                            orderLineItem.APTS_Bill_to_Party_Machines_Services__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_Bill_to_Party_Machines_Services__c;
                        }
                       
                        // Payer Ingredients
                        if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_PayerIngredients__c != null){
                            orderLineItem.APTS_PayerIngredients__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_PayerIngredients__c;
                        }
                       
                        // Payer Machines /Services
                        if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_PayerMachinesServices__c != null){
                            orderLineItem.APTS_PayerMachinesServices__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_PayerMachinesServices__c;
                        }
                     
                        //Defect # 23766 - Payer assignment incorrect for Admin Orders in Apttus >>> V4

                        if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_RefurbishedMachine__c){
                            orderLineItem.APTS_Refurbished_or_New__c = APTS_BIRUtils.USEDMACHINE;
                        }else{
                            orderLineItem.APTS_Refurbished_or_New__c = APTS_BIRUtils.NEWMACHINE;
                        }
                        if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_Payment_Method__c != null){
                            orderLineItem.APTS_Payment_Method__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_Payment_Method__c; 
                        }
                        if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PaymentTermId__c != null){
                           orderLineItem.Apttus_Config2__PaymentTermId__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PaymentTermId__c; 
                        }
                        if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillingPreferenceId__c != null){
                           orderLineItem.Apttus_Config2__BillingPreferenceId__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillingPreferenceId__c; 
                        }
                        if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillingRule__c != null){
                           orderLineItem.Apttus_Config2__BillingRule__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillingRule__c; 
                        }
                        if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillingFrequency__c != null){
                           orderLineItem.Apttus_Config2__BillingFrequency__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillingFrequency__c; 
                        }
                        orderLineItem.Apttus_Config2__BillToAccountId__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillToAccountId__c;
                        orderLineItem.Apttus_Config2__SellingFrequency__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__SellingFrequency__c;
                        orderLineItem.Apttus_Config2__SellingTerm__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__SellingTerm__c;
                        orderLineItem.Apttus_Config2__OptionId__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__OptionId__c != null? billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__OptionId__c : null;
                        orderLineItem.Apttus_Config2__PriceType__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PriceType__c;
                        orderLineItem.Apttus_Config2__LineNumber__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__LineNumber__c;
                        orderLineItem.Apttus_Config2__ItemSequence__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ItemSequence__c;
                        if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_ZX10__c != null
                            && billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_ZX10__c == 100
                            && (String.isBlank(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_Item_Category_Adjustment__c)
                                || String.isEmpty(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_Item_Category_Adjustment__c))){
                            orderLineItem.APTS_ZX10__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_ZX10__c;
                        }
                        /****************************************************************************/
                        /*            PRICING CONDITIONS FOR CREDIT ORDER                           */
                        Decimal feeAmt = -1*billingScheduleData.Apttus_Billing__FeeAmount__c;
                        orderLineItem.APTS_Z030_GSV_Consumption__c = feeAmt;
                        orderLineItem.Apttus_Config2__BasePriceOverride__c = feeAmt;
                        orderLineItem.Apttus_Config2__ListPrice__c = feeAmt;
                        orderLineItem.Apttus_Config2__NetPrice__c = feeAmt;
                        if(APTS_BIRUtils.PRODUCTORSERVICE.equalsIgnoreCase(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__LineType__c)
                            && billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Line__c){
                            if(!finalOLIMap.containskey(String.valueOf(billingScheduleData.Apttus_Billing__AssetLineItemId__c)+NONUSAGETYPE)){
                                finalOLIMap.put(String.valueOf(billingScheduleData.Apttus_Billing__AssetLineItemId__c)+NONUSAGETYPE, orderLineItem);
                            }
                        }
                        //oldprimaryLineWithNewOptionsMap - This Map will hold all option Lines
                        else if(APTS_BIRUtils.OPTION.equalsIgnoreCase(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__LineType__c)
                            && billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Asset__c != null){
                            List<Apttus_Config2__OrderLineItem__c> tempOLIList = new List<Apttus_Config2__OrderLineItem__c>();

                            String keyForOption = String.valueOf(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Asset__c)+NONUSAGETYPE;

                            if(oldprimaryLineWithNewOptionsMap.containskey(keyForOption)){
                                tempOLIList = oldprimaryLineWithNewOptionsMap.get(keyForOption);
                                if (!tempOLIList.contains(orderLineItem)){
                                    tempOLIList.add(orderLineItem);
                                    oldprimaryLineWithNewOptionsMap.put(keyForOption,tempOLIList);   
                                }           
                            }else{
                                tempOLIList.add(orderLineItem);
                                oldprimaryLineWithNewOptionsMap.put(keyForOption, new List<Apttus_Config2__OrderLineItem__c>(tempOLIList));
                            }
                        }
                    }// End of final if
                } // First if 
            }// End of for
            //system.debug('==> oldprimaryLineWithNewOptionsMap ==>'+oldprimaryLineWithNewOptionsMap);
            //system.debug('==> finalOLIMap ==>'+finalOLIMap);
            //system.debug('==finalOLIMap Keyset()==>'+finalOLIMap.keySet());
            
            if(!primaryLineOLIToCreate.isEmpty()){
                //system.debug('After primaryLineOLIToCreate ***** ==>');
                Id primaryOrderId;
                for(Apttus_Config2__AssetLineItem__c primaryAssetLineItem : [SELECT Id,
                                                                                Apttus_Config2__PriceListId__r.CurrencyIsoCode,
                                                                                Apttus_Config2__IsPrimaryLine__c,
                                                                                Apttus_Config2__LineType__c,
                                                                                Apttus_Config2__HasOptions__c,
                                                                                Apttus_Config2__ChargeType__c,
                                                                                APTS_Option_Group_Text__c,
                                                                                APTS_Type_of_Contract__c,
                                                                                Apttus_Config2__PriceListId__c,
                                                                                Apttus_Config2__PriceListItemId__c,
                                                                                Apttus_Config2__ProductId__c,
                                                                                Apttus_CMConfig__AgreementId__c,
                                                                                APTS_relatedlist_agreement__c,
                                                                                Apttus_Config2__Quantity__c,
                                                                                Apttus_Config2__SellingUom__c,
                                                                                APTS_Payment_Method__c,
                                                                                Apttus_Config2__PaymentTermId__c,
                                                                                Apttus_Config2__BillingPreferenceId__c,
                                                                                Apttus_Config2__BillingRule__c,
                                                                                Apttus_Config2__BillingFrequency__c,
                                                                                Apttus_Config2__BillToAccountId__c,
                                                                                Apttus_Config2__SellingFrequency__c,
                                                                                Apttus_Config2__SellingTerm__c,
                                                                                Apttus_Config2__OptionId__c,
                                                                                Apttus_Config2__PriceType__c,
                                                                                Apttus_Config2__LineNumber__c,
                                                                                Apttus_Config2__ItemSequence__c,
                                                                                Apttus_CMConfig__AgreementId__r.APTS_Fixed_Term_Type__c,
                                                                                APTS_Bill_to_Party_Ingredients_and_Payer__c,
                                                                                APTS_Bill_to_Party_Machines_Services__c,
                                                                                APTS_PayerIngredients__c,
                                                                                APTS_PayerMachinesServices__c
                                                                            FROM Apttus_Config2__AssetLineItem__c
                                                                            WHERE Id IN : primaryLineOLIToCreate
                                                                            AND APTS_Is_Primary_L1_Line__c = true
                                                                            LIMIT 50000]){
                    String assetKey = String.valueOf(primaryAssetLineItem.Id);
                    //DFT2C-2144 : Fix P4 - 2 machines on one order
                    primaryOrderId = null;
                    //system.debug('===>assetKey ****'+assetKey);
                    //system.debug('===>primaryAssetLineItem.APTS_Type_of_Contract__c ****'+primaryAssetLineItem.APTS_Type_of_Contract__c);
                     
                    if(!adminOrderCreatedInEachChunk.isEmpty()
                        && adminOrderCreatedInEachChunk.containsKey(String.valueOf(primaryAssetLineItem.Id)+ NONUSAGETYPE)
                        && adminOrderCreatedInEachChunk.get(String.valueOf(primaryAssetLineItem.Id)+ NONUSAGETYPE)!= null
                        && !createdP1LineMap.containsKey(assetKey+NONUSAGETYPE)){
                        primaryOrderId = adminOrderCreatedInEachChunk.get(String.valueOf(primaryAssetLineItem.Id)+ NONUSAGETYPE);
                        //system.debug('===>ISNDIE USAGE PRIMARY LINE 55 ==>');
                    }    
                    //system.debug('==>primaryOrderId==>'+primaryOrderId);
                    if(primaryOrderId != null){
                        Apttus_Config2__OrderLineItem__c primaryOrderLineItem = new Apttus_Config2__OrderLineItem__c();
                        primaryOrderLineItem.Apttus_Config2__OrderId__c = primaryOrderId;
                        primaryOrderLineItem.Apttus_Config2__IsPrimaryLine__c = primaryAssetLineItem.Apttus_Config2__IsPrimaryLine__c;
                        primaryOrderLineItem.APTS_Item_Relevant_for_SAP__c = true;
                        //<<++Begin  V41
                        String keyForDate = String.valueOf(primaryAssetLineItem.Id);
                        if(!primaryL1DateMap.isEmpty() && primaryL1DateMap.containsKey(keyForDate+STARTDATE)){
                            primaryOrderLineItem.Apttus_Config2__StartDate__c = primaryL1DateMap.get(keyForDate+STARTDATE);
                        }
                        
                        if(!primaryL1DateMap.isEmpty() && primaryL1DateMap.containsKey(keyForDate+ENDDATE)){
                            primaryOrderLineItem.Apttus_Config2__EndDate__c = primaryL1DateMap.get(keyForDate+ENDDATE);
                        }
                        primaryOrderLineItem.Apttus_Config2__LineType__c = primaryAssetLineItem.Apttus_Config2__LineType__c;
                        primaryOrderLineItem.Apttus_Config2__HasOptions__c = primaryAssetLineItem.Apttus_Config2__HasOptions__c;
                        primaryOrderLineItem.Apttus_Config2__ChargeType__c = primaryAssetLineItem.Apttus_Config2__ChargeType__c;
                        primaryOrderLineItem.APTS_Option_Group_Text__c = String.isNotBlank(primaryAssetLineItem.APTS_Option_Group_Text__c) ?primaryAssetLineItem.APTS_Option_Group_Text__c : APTS_BIRUtils.EMPTY_STRING;
                        primaryOrderLineItem.APTS_Type_of_Contract__c = primaryAssetLineItem.APTS_Type_of_Contract__c;
                        primaryOrderLineItem.Apttus_Config2__PriceListId__c = primaryAssetLineItem.Apttus_Config2__PriceListId__c;
                        primaryOrderLineItem.Apttus_Config2__PriceListItemId__c = primaryAssetLineItem.Apttus_Config2__PriceListItemId__c;
                        primaryOrderLineItem.Apttus_Config2__ProductId__c = primaryAssetLineItem.Apttus_Config2__ProductId__c;
                        if(primaryAssetLineItem.APTS_relatedlist_agreement__c != null){
                            primaryOrderLineItem.Apttus_CMConfig__AgreementId__c = primaryAssetLineItem.APTS_relatedlist_agreement__c;
                        }else{
                            primaryOrderLineItem.Apttus_CMConfig__AgreementId__c = primaryAssetLineItem.Apttus_CMConfig__AgreementId__c;
                        }
                        
                        primaryOrderLineItem.Apttus_Config2__Quantity__c = primaryAssetLineItem.Apttus_Config2__Quantity__c;
                        primaryOrderLineItem.Apttus_Config2__SellingUom__c = primaryAssetLineItem.Apttus_Config2__SellingUom__c;
                        primaryOrderLineItem.Apttus_Config2__AssetLineItemId__c = primaryAssetLineItem.Id;
                        primaryOrderLineItem.APTS_Payment_Method__c = primaryAssetLineItem.APTS_Payment_Method__c;
                        primaryOrderLineItem.Apttus_Config2__PaymentTermId__c = primaryAssetLineItem.Apttus_Config2__PaymentTermId__c;
                        primaryOrderLineItem.Apttus_Config2__BillingPreferenceId__c = primaryAssetLineItem.Apttus_Config2__BillingPreferenceId__c; 
                        primaryOrderLineItem.Apttus_Config2__BillingRule__c = primaryAssetLineItem.Apttus_Config2__BillingRule__c;
                        primaryOrderLineItem.Apttus_Config2__BillingFrequency__c = primaryAssetLineItem.Apttus_Config2__BillingFrequency__c; 
                        primaryOrderLineItem.Apttus_Config2__BillToAccountId__c = primaryAssetLineItem.Apttus_Config2__BillToAccountId__c;
                        primaryOrderLineItem.Apttus_Config2__SellingFrequency__c = primaryAssetLineItem.Apttus_Config2__SellingFrequency__c;
                        primaryOrderLineItem.Apttus_Config2__SellingTerm__c = primaryAssetLineItem.Apttus_Config2__SellingTerm__c;
                        primaryOrderLineItem.Apttus_Config2__OptionId__c = primaryAssetLineItem.Apttus_Config2__OptionId__c != null? primaryAssetLineItem.Apttus_Config2__OptionId__c : null;
                        primaryOrderLineItem.Apttus_Config2__PriceType__c = primaryAssetLineItem.Apttus_Config2__PriceType__c;
                        //primaryOrderLineItem.Apttus_Config2__ActivatedDate__c = system.today(); 
                        primaryOrderLineItem.Apttus_Config2__ReadyForBillingDate__c = system.today();
                        primaryOrderLineItem.APTS_Status__c = APTS_BIRUtils.ACTIVATED;
                        primaryOrderLineItem.Apttus_Config2__Status__c = APTS_BIRUtils.ACTIVATED;
                        primaryOrderLineItem.Apttus_Config2__LineNumber__c = primaryAssetLineItem.Apttus_Config2__LineNumber__c;
                        primaryOrderLineItem.Apttus_Config2__ItemSequence__c = primaryAssetLineItem.Apttus_Config2__ItemSequence__c;
                        primaryOrderLineItem.CurrencyIsoCode = primaryAssetLineItem.Apttus_Config2__PriceListId__r.CurrencyIsoCode;
                        primaryOrderLineItem.Apttus_Config2__NetPrice__c = 0.00;
                        primaryOrderLineItem.Apttus_Config2__NetUnitPrice__c = 0.00;
                        primaryOrderLineItem.Apttus_Config2__ListPrice__c = 0.00;
                        primaryOrderLineItem.Apttus_Config2__BasePrice__c = 0.00;
                        // bill to Ingredients
                        if(primaryAssetLineItem.APTS_Bill_to_Party_Ingredients_and_Payer__c != null){
                            primaryOrderLineItem.APTS_Bill_to_Party_Ingredients_and_Payer__c = primaryAssetLineItem.APTS_Bill_to_Party_Ingredients_and_Payer__c;
                        }
                        // Bill to Machine/Services
                        if(primaryAssetLineItem.APTS_Bill_to_Party_Machines_Services__c != null){
                            primaryOrderLineItem.APTS_Bill_to_Party_Machines_Services__c = primaryAssetLineItem.APTS_Bill_to_Party_Machines_Services__c;
                        }
                        // Payer Ingredients
                        if(primaryAssetLineItem.APTS_PayerIngredients__c != null){
                            primaryOrderLineItem.APTS_PayerIngredients__c = primaryAssetLineItem.APTS_PayerIngredients__c;
                        }
                        // Payer MachineServices
                        if(primaryAssetLineItem.APTS_PayerMachinesServices__c != null){
                            primaryOrderLineItem.APTS_PayerMachinesServices__c = primaryAssetLineItem.APTS_PayerMachinesServices__c;
                        }
                        primaryOrderLineItem.APTS_SAP_OrderType__c = CREDITORDERSAPORDERTYPE;
                        if(!tempNewPrimaryMap.containskey(String.valueOf(primaryAssetLineItem.Id)+NONUSAGETYPE)){
                            //system.debug('===>Inside Consumption NON Usage 44****');
                            tempNewPrimaryMap.put(String.valueOf(primaryAssetLineItem.Id)+NONUSAGETYPE, primaryOrderLineItem);
                        }
                    }
                }// End of for
            }//End of if
            /******************************************************************************************************
            * Structuring of Primary Line and it's options picked by the billing run
            * finalOLIMap ==> Will have all primary Lines picked by billing Run
            * oldprimaryLineWithNewOptionsMap ==> will have all options picked by Billing run
            * createdP1LineMap ==> Will hold the P1 lines created in Prior Batch Chunk Execution
            *******************************************************************************************************/
            if(!finalOLIMap.isEmpty()){
                for(String primaryLineKey : finalOLIMap.keySet()){
                    //system.debug('===primaryLineKey=='+primaryLineKey);
                    if(finalOLIMap.get(primaryLineKey) != null){
                        Apttus_Config2__OrderLineItem__c p1Line = finalOLIMap.get(primaryLineKey);
                        //system.debug('****p1Line Inside *****'+p1Line);
                        // Adding Option Line
                        if(oldprimaryLineWithNewOptionsMap.containsKey(primaryLineKey)
                            && oldprimaryLineWithNewOptionsMap.get(primaryLineKey) != null){
                            Map<Id,Apttus_Config2__OrderLineItem__c> optionTempMap = findOptionLine(oldprimaryLineWithNewOptionsMap,primaryLineKey,oliBillingScheduleMap); 
                            // If Options are present for that Primary line then add the primary Line first followed by the options
                            if(!optionTempMap.isEmpty()){
                                // Add Primary line
                                primaryOliToInsert.put(p1Line.Apttus_Config2__OrderId__c,p1Line);
                                // Add it's corresponding Options
                                oliBillingScheduleMap.putAll(optionTempMap);
                            }
                        }
                    }
                    //system.debug('****oliBillingScheduleMap  finalOLIMap *****==>'+oliBillingScheduleMap);
                }// End of For P1 Lines picked by Billing Schedules
            }
            /******************************************************************************************************
            * Structuring of Primary Line and it's options picked by the billing run
            * tempNewPrimaryMap ==> Will have all primary Lines created for options picked in Billing Run
            * oldprimaryLineWithNewOptionsMap ==> will have all options picked by Billing run
            * createdP1LineMap ==> Will hold the P1 lines created in Prior Batch Chunk Execution
            *******************************************************************************************************/
            //system.debug('==>tempNewPrimaryMap==>'+tempNewPrimaryMap);
            if(!tempNewPrimaryMap.isEmpty()){
                for(String primaryLineKey : tempNewPrimaryMap.keySet()){
                    if(tempNewPrimaryMap.get(primaryLineKey) != null){
                        Apttus_Config2__OrderLineItem__c p1Line = tempNewPrimaryMap.get(primaryLineKey);
                        // Adding Option Line
                        if(oldprimaryLineWithNewOptionsMap.containsKey(primaryLineKey)
                            && oldprimaryLineWithNewOptionsMap.get(primaryLineKey) != null){
                            Map<Id,Apttus_Config2__OrderLineItem__c> optionTempMap = findOptionLine(oldprimaryLineWithNewOptionsMap,primaryLineKey,oliBillingScheduleMap); 
                            // If Options are present for that Primary line then add the primary Line first followed by the options
                            if(!optionTempMap.isEmpty()){
                                // Add Primary line
                                primaryOliToInsert.put(p1Line.Apttus_Config2__OrderId__c,p1Line);
                                // Add it's corresponding Options
                                oliBillingScheduleMap.putAll(optionTempMap);
                            }
                        }
                    }
                }// End of For P1 Lines picked by Billing Schedules
            }
            // Adding the options for the Primary Line created in Prior Chunks by billing Batch
            if(!createdP1LineMap.isEmpty()){
                for(Apttus_Config2__OrderLineItem__c  oOrderLineItem  : createdP1LineMap.values()){
                    String keyForOption = String.valueOf(oOrderLineItem.Apttus_Config2__AssetLineItemId__c)+NONUSAGETYPE;
                    primaryOrderLineToUpdate.put(oOrderLineItem.Id,oOrderLineItem);
                    // Revision V9 - Code Added for Skipping option Lines in prior chunks  Execution Starts
                    // check for the options avaiable in the current chunk execution but it's  P1 line already inserted
                    // if Primary L1 line is already inserted and in the current chunk only if options are available then add the options
                    if(oldprimaryLineWithNewOptionsMap.containsKey(keyForOption)
                        && oldprimaryLineWithNewOptionsMap.get(keyForOption) != null){
                        Map<Id,Apttus_Config2__OrderLineItem__c> optionTempMap = findOptionLine(oldprimaryLineWithNewOptionsMap,keyForOption,oliBillingScheduleMap); 
                        if(!optionTempMap.isEmpty()){
                            oliBillingScheduleMap.putAll(optionTempMap);
                        } 
                    }
                }
            }
            //system.debug('****primaryOliToInsert*****'+primaryOliToInsert.values());
            //system.debug('****primaryOliToInsert keySet*****'+primaryOliToInsert.keySet());
            if(!primaryOliToInsert.isEmpty()){
                Database.SaveResult[] resultList = Database.insert(primaryOliToInsert.values(), false);
                APTS_BIRUtils.logError(null,resultList,null,null,APTS_BIRUtils.BATCH,APTS_BIRUtils.ORDERLINEITEMOBJECTNAME,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,false);
            }
            //system.debug('****oliBillingScheduleMap*****'+oliBillingScheduleMap.values());
            //system.debug('****oliBillingScheduleMap keySet*****'+oliBillingScheduleMap.keySet());
            Id adminOrderId;
            if(Schema.SObjectType.Apttus_Config2__Order__c.getRecordTypeInfosByName().get(APTS_BIRUtils.ADMINORDER)!=null){
                adminOrderId = Schema.SObjectType.Apttus_Config2__Order__c.getRecordTypeInfosByName().get(APTS_BIRUtils.ADMINORDER).getRecordTypeId();
            }
            for(Apttus_Config2__OrderLineItem__c oli : [SELECT Id,Name,Apttus_Config2__LineType__c,Apttus_Config2__OrderId__c
                                                            FROM Apttus_Config2__OrderLineItem__c
                                                            WHERE Apttus_Config2__OrderId__c IN : primaryOliToInsert.keySet()
                                                            AND APTS_SAP_OrderType__c =: CREDITORDERSAPORDERTYPE 
                                                            AND Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c =: BILLINGSCHEDULE
                                                            AND Apttus_Config2__OrderId__r.RecordTypeId =: adminOrderId
                                                            AND Apttus_Config2__OrderId__r.APTS_Order_Type__c =: ADMINORDER
                                                            AND Apttus_Config2__LineType__c =: APTS_BIRUtils.PRODUCTORSERVICE
                                                        LIMIT 50000]){
                insertedPrimaryLine.put(oli.Apttus_Config2__OrderId__c,oli);
            } 
            if(!oliBillingScheduleMap.isEmpty()){
                for(Apttus_Config2__OrderLineItem__c orderLineItem : oliBillingScheduleMap.values()){
                    if(insertedPrimaryLine.containsKey(orderLineItem.Apttus_Config2__OrderId__c)
                        && insertedPrimaryLine.get(orderLineItem.Apttus_Config2__OrderId__c) != null
                        && APTS_BIRUtils.OPTION.equalsIgnoreCase(orderLineItem.Apttus_Config2__LineType__c)){
                        Apttus_Config2__OrderLineItem__c primaryOrderLineItem = insertedPrimaryLine.get(orderLineItem.Apttus_Config2__OrderId__c);
                        //system.debug('primaryOrderLineItem 2 ==>'+primaryOrderLineItem);
                        //system.debug('primaryOrderLineItem 3 ==>'+orderLineItem.Apttus_Config2__OrderId__c);
                        //system.debug('primaryOrderLineItem #####==>'+primaryOrderLineItem.Apttus_Config2__OrderId__c);
                        if(primaryOrderLineItem.Apttus_Config2__OrderId__c == orderLineItem.Apttus_Config2__OrderId__c){
                            orderLineItem.APTS_Parent_Order_Line_Item__c = primaryOrderLineItem.Name.right(5);
                            orderLineItem.APTS_Is_Primary_L1_Parent__c = primaryOrderLineItem.Id;
                        }
                    }
                }
                Database.SaveResult[] srList = Database.insert(oliBillingScheduleMap.values(), false);
                APTS_BIRUtils.logError(null,srList,null,null,APTS_BIRUtils.BATCH,APTS_BIRUtils.ORDERLINEITEMOBJECTNAME,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,false);
            }
            for(Apttus_Config2__OrderLineItem__c oli: oliBillingScheduleMap.values()){
                if(oli.APTS_BillingSchedule__c != null){
                    insertedOrderLineMap.put(oli.APTS_BillingSchedule__c,oli);
                } 
            }
        }catch(Exception e){APTS_BIRUtils.logError(null,null,null,e,APTS_BIRUtils.BATCH,APTS_BIRUtils.ORDERLINEITEMOBJECTNAME,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,true);
            insertedOrderLineMap = null;
        }
        return insertedOrderLineMap;
    }
    /** Method Name : findOptionLine
    * Description : Method to create admin Order's Adjustment Line item from Asset Adjustment Line Item
    **/
    public static Map<Id,Apttus_Config2__OrderLineItem__c> findOptionLine(Map<String,List<Apttus_Config2__OrderLineItem__c>> oldprimaryLineWithNewOptionsMap,
                                                                            String primaryLineKey,Map<Id,Apttus_Config2__OrderLineItem__c> oliBillingScheduleMap){
        Map<Id,Apttus_Config2__OrderLineItem__c> optionToAdded = new Map<Id,Apttus_Config2__OrderLineItem__c>();
        try{
            List<Apttus_Config2__OrderLineItem__c> optionLine = oldprimaryLineWithNewOptionsMap.get(primaryLineKey);
            for(Apttus_Config2__OrderLineItem__c oOrderLine : optionLine){
                if(oOrderLine.APTS_BillingSchedule__c != null
                    && !oliBillingScheduleMap.containsKey(oOrderLine.APTS_BillingSchedule__c)){
                    optionToAdded.put(oOrderLine.APTS_BillingSchedule__c,oOrderLine);
                }
            }
            //system.debug('****optionToAdded in loop*****'+optionToAdded);
        }catch(Exception e){APTS_BIRUtils.logError(null,null,null,e,APTS_BIRUtils.BATCH,'findOptionLine',APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,true); return null;} 
        return optionToAdded;
    }
   
    /** Method Name : existingP1LineCheck
    * Description : Method to check P1 Line exisiting for the Admin Order Created
    **/
    public static Map<String,Apttus_Config2__OrderLineItem__c> existingP1LineCheck(List<Id> adminOrderCreatedInEachChunk,
                                                    Set<Id> assetLineIdToCheck){
        Id adminOrderId;
        Map<String,Apttus_Config2__OrderLineItem__c> primaryLineSet = new Map<String,Apttus_Config2__OrderLineItem__c>();
        if(Schema.SObjectType.Apttus_Config2__Order__c.getRecordTypeInfosByName().get(APTS_BIRUtils.ADMINORDER)!=null){
            adminOrderId = Schema.SObjectType.Apttus_Config2__Order__c.getRecordTypeInfosByName().get(APTS_BIRUtils.ADMINORDER).getRecordTypeId();
        }
        for(Apttus_Config2__OrderLineItem__c oli : [SELECT Id,
                                                            Name,
                                                            APTS_Type_of_Contract__c,
                                                            APTS_SAP_OrderType__c,
                                                            Apttus_Config2__AssetLineItemId__c,
                                                            Apttus_Config2__LineNumber__c,
                                                            Apttus_Config2__PriceType__c,
                                                            Apttus_Config2__ChargeType__c,
                                                            Apttus_Config2__OrderId__c,
                                                            Apttus_Config2__LineType__c,
                                                            Apttus_Config2__StartDate__c,
                                                            Apttus_Config2__EndDate__c,
                                                            APTS_Item_Relevant_for_SAP__c,
                                                            APTS_Order_Sub_Type__c
                                                        FROM Apttus_Config2__OrderLineItem__c
                                                        WHERE Apttus_Config2__AssetLineItemId__c IN:assetLineIdToCheck
                                                        AND Apttus_Config2__OrderId__c IN:adminOrderCreatedInEachChunk
                                                        AND APTS_SAP_OrderType__c =: CREDITORDERSAPORDERTYPE
                                                        AND Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c =: BILLINGSCHEDULE
                                                        AND Apttus_Config2__OrderId__r.RecordTypeId =: adminOrderId
                                                        AND Apttus_Config2__OrderId__r.APTS_Order_Type__c =: ADMINORDER
                                                        AND Apttus_Config2__LineType__c =: APTS_BIRUtils.PRODUCTORSERVICE
                                                        LIMIT 50000]){
            //system.debug('===>existingP1LineCheck ****'+oli);
            primaryLineSet.put(String.valueOf(oli.Apttus_Config2__AssetLineItemId__c)
                                    +oli.APTS_SAP_OrderType__c,oli);
        }
        //system.debug('===>primaryLineSet ****'+primaryLineSet);
        return primaryLineSet;
    }
    
    /** Method Name : updateBillingscheduleStatus
    * Description : Method to Update the billing sh
    **/
    public static void updateBillingscheduleStatus(List<Apttus_Billing__BillingSchedule__c> billingScheduleRecords,
                                                    Map<Id,Apttus_Config2__OrderLineItem__c> orderLineBillingScheduleMap){
        List<Apttus_Billing__BillingSchedule__c> billingSchedulesToUpdate = new List<Apttus_Billing__BillingSchedule__c>();
        try{
            if(!billingScheduleRecords.isEmpty()){
                for(Apttus_Billing__BillingSchedule__c billingSchedules: billingScheduleRecords){
                    if(!orderLineBillingScheduleMap.isEmpty()
                        && orderLineBillingScheduleMap.containsKey(billingSchedules.Id)
                        && orderLineBillingScheduleMap.get(billingSchedules.Id) != null){
                            billingSchedules.APTS_Admin_Order_Line__c = orderLineBillingScheduleMap.get(billingSchedules.Id).Id;
                            billingSchedules.Apttus_Billing__Status__c = APTS_BIRUtils.PENDINGINVOICED;
                            billingSchedulesToUpdate.add(billingSchedules);
                        //system.debug('@@@@@@@@billingSchedules ==> '+billingSchedules); 
                    }   
                }
            }
            if(!billingSchedulesToUpdate.isEmpty()){
                Database.SaveResult[] srList = Database.update(billingSchedulesToUpdate,false);
                APTS_BIRUtils.logError(null,srList,null,null,APTS_BIRUtils.BATCH,APTS_BIRUtils.BILLINGSCHEDULESUPDATE,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,false);
            }
        }catch(Exception e){APTS_BIRUtils.logError(null,null,null,e,APTS_BIRUtils.BATCH,APTS_BIRUtils.BILLINGSCHEDULESUPDATE,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,true);}   
    }
    
    /** Method Name : getReccurringBatchQueryStringExecute
    * Description : Method to get the query string for APTS_RecurringBillingScheduleBatch
    **/
    public static string getReccurringBatchQueryStringStart(String salesOrg){
        String currentDate = String.valueOf(Date.today());
        String EMPTY = 'EMPTY';
        String query = 'SELECT Id \n'+
        ' FROM '+APTS_BIRUtils.EMPTY_STRING+'Apttus_Billing__BillingSchedule__c';
        query += ' WHERE Apttus_Billing__Status__c = \'Pending Billing\' AND Apttus_Billing__Type__c = \'Contracted\' ';
        query += APTS_BIRUtils.EMPTY_STRING+' AND Apttus_Billing__IsSuperseded__c = false ';
        if(!Test.isRunningTest() && Label.APTS_CreditBatchFilter != null && !EMPTY.equalsIgnoreCase(Label.APTS_CreditBatchFilter)){
            query += APTS_BIRUtils.EMPTY_STRING + Label.APTS_CreditBatchFilter;
        }
        query += APTS_BIRUtils.EMPTY_STRING+' AND Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillingFrequency__c IN (\'Hourly\', \'Daily\',\'Monthly\',\'Quarterly\',\'Half Yearly\',\'Yearly\')';
        query += APTS_BIRUtils.EMPTY_STRING+' AND Apttus_Billing__FeeAmount__c < 0 ';
        query += APTS_BIRUtils.EMPTY_STRING+' AND Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__r.Sales_Organization__c=\''+ salesOrg + '\' ';
        
        return query;

    }

    /** Method Name : getReccurringBatchQueryStringStart
    * Description : Method to get the query string for APTS_RecurringBillingScheduleBatch
    **/
    public static string getReccurringBatchQueryStringExecute(Set<Id> billingSchedulesID){

        String query = 'SELECT Id,'+
        'Apttus_Billing__AssetLineItemId__c,'+ 
        'Apttus_Billing__FeeAmount__c,'+ 
        'Apttus_Billing__OrderLineItemId__c,'+ 
        'Apttus_Billing__OrderLineItemId__r.APTS_Credit_Proposal_XC09_Block__c,'+ 
        'Apttus_Billing__PeriodEndDate__c,'+ 
        'Apttus_Billing__PeriodStartDate__c,'+ 
        'Apttus_Billing__InvoicedScheduleId__c,'+
        'Apttus_Billing__InvoicedScheduleId__r.APTS_Invoice__c,'+
        'Apttus_Billing__InvoicedScheduleId__r.APTS_Invoice__r.APTS_External_Invoice_Number__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PriceListId__r.CurrencyIsoCode,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__LineType__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__IsOptionRollupLine__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ItemSequence__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillingRule__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillingFrequency__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Line__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillingPreferenceId__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_Payment_Method__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PaymentTermId__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillingPreferenceId__r.Apttus_Config2__BillingCycleStart__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillingPreferenceId__r.Apttus_Config2__BillingDayOfMonth2__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillingPreferenceId__r.APTS_Billing_Rule_Contract__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_Bill_to_Party_Ingredients_and_Payer__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillToAccountId__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_Bill_to_Party_Machines_Services__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__LineNumber__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Asset__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PricingDate__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_Option_Group_Text__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__IsPrimaryLine__c,'+ 
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__HasOptions__c,'+ 
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ChargeType__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_Type_of_Contract__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PriceListId__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PriceListItemId__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__OptionId__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ProductId__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__Quantity__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_RefurbishedMachine__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__SellingFrequency__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__SellingTerm__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__SellingUom__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_PayerIngredients__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_PayerMachinesServices__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PriceType__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__LocationId__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_ZX10__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_Item_Category_Adjustment__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__r.Name,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__r.APTS_Check_on_Account_Machines__c,'+    
        'Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__r.APTS_Fixed_Term_Type__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__r.Apttus__Primary_Contact__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__r.APTS_Check_on_Account_Machines__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__r.Apttus__Primary_Contact__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__r.APTS_Fixed_Term_Type__c \n'+
        ' FROM '+APTS_BIRUtils.EMPTY_STRING+'Apttus_Billing__BillingSchedule__c';
        query += ' WHERE ID IN: billingSchedulesID' ;
        //system.debug('query##'+query);
        return query;

    }
    
    /** Method Name : getBillingDate
    * Description : Method to get BillingDate for order header
    **/
    public static date getBillingDate(Apttus_Billing__BillingSchedule__c billingSchedule){
        Date tempDate;
        Date currentDate=date.today();
        Integer currentDay=currentDate.day();
        if(READY_FOR_BILLING_DATE.equalsIgnoreCase(billingSchedule.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillingPreferenceId__r.Apttus_Config2__BillingCycleStart__c)
            || PERIOD_START_DATE.equalsIgnoreCase(billingSchedule.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillingPreferenceId__r.Apttus_Config2__BillingCycleStart__c)){
            tempDate=date.today();  
        }
        else if(BILLING_DAY_OF_MONTH.equalsIgnoreCase(billingSchedule.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillingPreferenceId__r.Apttus_Config2__BillingCycleStart__c)){
            if(BILL_IN_ADVANCE.equalsIgnoreCase(billingSchedule.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillingPreferenceId__r.APTS_Billing_Rule_Contract__c)){
                Integer tempDay=getDayOfMonth(billingSchedule.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillingPreferenceId__r.Apttus_Config2__BillingDayOfMonth2__c,currentDate);
                if(tempDay < currentDay){ // if Billing Day of month is less than current Date , then set the date to next month
                    tempDate=currentDate.addMonths(1).toStartofMonth().addDays(tempDay-1);
                }else if(tempDay == currentDay){ // If both the days are same
                    tempDate=date.today(); 
                } 
                else if(tempDay > currentDay){ // If Billing Day of month is less than current Date, then set the date to the billing date
                    tempDate=currentDate.toStartofMonth().addDays(tempDay-1);
                }
            }
            else if(BILL_IN_ARREARS.equalsIgnoreCase(billingSchedule.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillingPreferenceId__r.APTS_Billing_Rule_Contract__c)){
                tempDate=date.today();
            }
        }
        return tempDate;
    }

    /** Method Name : getDayOfMonth
    * Description : Method to get the day of the month
    **/

    public static integer getDayOfMonth(String dayOfMonthString,Date currentDate){
        Integer noOfDaysInMonth=date.daysInMonth(currentDate.Year(),currentDate.Month());
                
        Integer dayOfMonth;
            if(END_OF_MONTH.equalsIgnoreCase(dayOfMonthString)){
                dayOfMonth=noOfDaysInMonth;
            }
            else{ // To remove the alphabets and get the integer
                String regex = '[a-zA-Z]{1,}|\\-';
                dayOfMonth = Integer.ValueOf(dayOfMonthString.replaceAll(regex, '').trim());
            }
        if(dayOfMonth > noOfDaysInMonth){ // If the number set in billing day of month is greater than actual days in the month
            dayOfMonth=noOfDaysInMonth;
        }
        //System.debug(dayOfMonth);
        return dayOfMonth;
    }

    /** Method Name : populateBillingPreference
    * Description : To populate Billing Key Fields On Order Header
    **/
    public static void populateBillingPreference(Map<Id,APTS_Billing_Settings__c> billingSetting,
                                                Apttus_Billing__BillingSchedule__c  billingScheduleData,
                                                Map<Id,Account> accountDataMap,
                                                Apttus_Config2__Order__c order,
                                                Id agreementId,
                                                Boolean isMachinesCheckBoxchecked,
                                                Map<String,String> invoiceMap){
        try{
            // If the checkbox is  not checked populate from Billing setting
            if(!isMachinesCheckBoxchecked && !billingSetting.isEmpty()
                    && billingSetting.containsKey(agreementId)
                    && billingSetting.get(agreementId) != null){
                    
                // invoice Delivery Prefernce
                if(billingSetting.get(agreementId).APTS_Invoice_Delivery_Preference__c != null){
                    order.APTS_InvoiceDeliveryPreference__c = billingSetting.get(agreementId).APTS_Invoice_Delivery_Preference__c;
                }
                // Invoice Type
                if(billingSetting.get(agreementId).APTS_Invoice_Type__c != null){
                    order.APTS_InvoiceType__c = billingSetting.get(agreementId).APTS_Invoice_Type__c;
                }
                // Payment Method
                if(billingSetting.get(agreementId).APTS_Payment_Method__c != null){
                    order.APTS_Payment_Method__c = billingSetting.get(agreementId).APTS_Payment_Method__c; 
                    order.APTS_Payment_Method_Code__c = billingSetting.get(agreementId).APTS_Payment_Method__r.APTS_Payment_Method_Code__c;
                }
                // Payment Term
                order.Apttus_Config2__PaymentTermId__c = billingSetting.get(agreementId).APTS_Payment_Term_Setting__c != null?billingSetting.get(agreementId).APTS_Payment_Term_Setting__c  : null; 
                // Billing Preference
                order.Apttus_Config2__BillingPreferenceId__c = billingSetting.get(agreementId).APTS_Billing_Preference_Setting__c != null? billingSetting.get(agreementId).APTS_Billing_Preference_Setting__c : null; 
                if(billingSetting.get(agreementId).APTS_Agreement_ID__c != null){
                    if(billingSetting.get(agreementId).APTS_Agreement_ID__r.APTS_Bill_to_Party_MachServ__c != null){
                        order.Apttus_Config2__BillToAccountId__c = billingSetting.get(agreementId).APTS_Agreement_ID__r.APTS_Bill_to_Party_MachServ__c;
                    }
                    // Bill To account Population
                    if(billingSetting.get(agreementId).APTS_Agreement_ID__r.APTS_Payer_Machines_Services__c != null){
                        order.APTS_Payer__c = billingSetting.get(agreementId).APTS_Agreement_ID__r.APTS_Payer_Machines_Services__c;
                    }
                    //<<-- Added on Version V17 Starts - Setting the Payer and Bill to from AGreement.      
                }
            }
            // If the check box is checked populated from Asset's Sold To Account
            else if(isMachinesCheckBoxchecked && !accountDataMap.isEmpty()
                    && billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c != null
                    && accountDataMap.containsKey(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c) != null
                    && accountDataMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c) != null){
                    
                Account soldToAccount = accountDataMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c);
                if(soldToAccount.Related_Bill_to_Machines_Services__c != null){
                    // Billing Preference, Invoice Delivery Preference and Invoice Type
                    if(soldToAccount.Related_Bill_to_Machines_Services__r.Apttus_Config2__BillingPreferenceId__c !=null){
                        order.Apttus_Config2__BillingPreferenceId__c  = soldToAccount.Related_Bill_to_Machines_Services__r.Apttus_Config2__BillingPreferenceId__c;
                        order.APTS_InvoiceType__c = soldToAccount.Related_Bill_to_Machines_Services__r.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Type__c;
                        order.APTS_InvoiceDeliveryPreference__c = soldToAccount.Related_Bill_to_Machines_Services__r.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Delivery_Preference__c;
                    }
                    // Billing Preference, Invoice Delivery Preference and Invoice Type
                    if(soldToAccount.Related_Bill_to_Machines_Services__r.Apttus_Config2__PaymentTermId__c != null){
                        order.Apttus_Config2__PaymentTermId__c = soldToAccount.Related_Bill_to_Machines_Services__r.Apttus_Config2__PaymentTermId__c;  
                    }
                    // Payment Term
                    if(soldToAccount.Related_Bill_to_Machines_Services__r != null && soldToAccount.Related_Bill_to_Machines_Services__r.APTS_Payment_Method__c !=null){    
                        order.APTS_Payment_Method__c = soldToAccount.Related_Bill_to_Machines_Services__r.APTS_Payment_Method__c;
                        order.APTS_Payment_Method_Code__c = soldToAccount.Related_Bill_to_Machines_Services__r.APTS_Payment_Method__r.APTS_Payment_Method_Code__c;
                    }
                    order.Apttus_Config2__BillToAccountId__c = soldToAccount.Related_Bill_to_Machines_Services__c;
                }else if(soldToAccount.Related_Bill_to_Machines_Services__c == null){
                    if(soldToAccount.Apttus_Config2__BillingPreferenceId__c != null){
                        order.APTS_InvoiceDeliveryPreference__c = soldToAccount.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Delivery_Preference__c;
                        order.APTS_InvoiceType__c = soldToAccount.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Type__c;
                        order.Apttus_Config2__BillingPreferenceId__c = soldToAccount.Apttus_Config2__BillingPreferenceId__c;
                    }
                    // Payment method and Payment code
                    if(soldToAccount.APTS_Payment_Method__c != null){
                        order.APTS_Payment_Method__c = soldToAccount.APTS_Payment_Method__c;
                        order.APTS_Payment_Method_Code__c = soldToAccount.APTS_Payment_Method__r.APTS_Payment_Method_Code__c;
                    }
                    // Payment Term
                    if(soldToAccount.Apttus_Config2__PaymentTermId__c != null){
                        order.Apttus_Config2__PaymentTermId__c = soldToAccount.Apttus_Config2__PaymentTermId__c;
                    }
                }
                // Payer account population 
                if(soldToAccount.Related_Payer_Machines_Services__c != null){
                    order.APTS_Payer__c = soldToAccount.Related_Payer_Machines_Services__c;
                }
            }
            if((APTS_BIRUtils.INVOICELISTWITHSUMMARY.equalsIgnoreCase(order.APTS_InvoiceType__c) || COLLECTIVEINVOICE_WITHSMRYPAGE.equalsIgnoreCase(order.APTS_InvoiceType__c)) && order.APTS_InvoiceDeliveryPreference__c != null
                && !invoiceMap.isEmpty() && invoiceMap.containsKey(order.APTS_InvoiceDeliveryPreference__c)){
                order.APTS_InvoiceDeliveryPreference__c= invoiceMap.get(order.APTS_InvoiceDeliveryPreference__c);  
            }
        }catch(Exception e){APTS_BIRUtils.logError(null,null,null,e,APTS_BIRUtils.BATCH,APTS_BIRUtils.ORDEROBJECTNAME,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,true);}
    }

    public static void callRecurringBatchIfReqd(String salesOrg){
        //system.debug('salesOrg callRecurringBatchIfReqd ===>'+salesOrg);
        if(salesOrg != ''){
            //system.debug('INSIDE BATCH Execution callRecurringBatchIfReqd ===>'+salesOrg);
            
            APTS_CreditBillingBatch obj = new APTS_CreditBillingBatch(salesOrg);
            Database.executeBatch(obj,100);
        }
        else{
            //system.debug('INSIDE ELSE callRecurringBatchIfReqd ===>'+salesOrg);
            for(APTS_Credit_Batch_Countries__c rbcRecord : APTS_Credit_Batch_Countries__c.getAll().values()){
                if(!rbcRecord.APTS_Ignore_Billing_Run__c){
                    rbcRecord.APTS_Processed__c = false;
                }
            }
            update APTS_Credit_Batch_Countries__c.getAll().values();
        }
    }
}