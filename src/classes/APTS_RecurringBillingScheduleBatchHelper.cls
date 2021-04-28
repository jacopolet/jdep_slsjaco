/**
* Class Name : APTS_RecurringBillingScheduleBatchHelper
* Description : Helper class for APTS_RecurringBillingBatchScheduler Class
* Author : BALASHANTHI (b.arigopalan@accenture.com)
* Date Created : 21/05/2018
* Revision v1 - CR 2170
* Revision v2 - Ankit Josji - 8-1-2019 Removing sub query from recurring batch and querying it in createAdminOrder()
* Revision v3 - Balashanthi - 20-1-2019 Changes added for CR 2203 - Design Change - Created Admin Order Per L1 Primary Bundle
* Revision v4 - Balashanthi - changes added for defect # 23766 - Payer assignment incorrect for Admin Orders in Apttus
* Revision v5 - Balashanthi - changes added for defect # 23790 - Proration of Net List prices and List Prices based on frequency incorrect (Month/Quarterly/Half Yearly/Yearly) + incorrect monthly amounts when invoicing 2 billing schedules fot one asset
* Revision v6 - Balashanthi - Changes added for defect # 23764 - Primary header missing in SAP for Consumption Model XD12
* Revision V7 - Nagavi - Added methods to process fixed term orders as part of temporary fix for the defect #23740
* Revision V8 - Balashanthi - ZX100 changes added for CR 2207
* Revision V9 - Balashanthi - Code Added for issue - Options not added for Prior chunk  execution
* Revision V10 - Nagavi - Added getBillingDate(),getDayOfMonth() as part of defect 23887
* Revision V11 - Balashanthi - Added changes for defect 4900 - Cascading the values(Billing Preference, Payment Term and Payment Method) from Asset line item
* Revision V12 - Balashanthi - Added changes for defect 4900 - Cascading the values(Billing Preference, Payment Term and Payment Method) from Agreement based on Check box @ Agreement.
* Revision V13 - Balashanthi - uncommented UpdateBillingSchedule() method which was commented
* Revision V14 - Balashanthi - Defect # 5254 PO number missing on recurring billing document
* Revision V15 - Balashanthi - Defect # 5361 ADMIN orders payer not correct showing sold to party instead of payer
* Revision V16 - Balashanthi - Defect # 5361 Setting correct bill To account field @ order Header
* Revision V17 - Balashanthi - Defect # 5361 Setting Bill to and Payer for Billing Setting
* Revision V18 - Balashanthi - Defect # 5528 Billing Period Values on Billing schedules are not matching with admin order net value.
* Revision V19 - Balashanthi - Defect # 5622 LAE/RAR Missing Hierarchy level in XD09 recurring billing orders
* Revision V20 - Balashanthi - Defect # 5662 Proration should not happen in case of full periods to prevend invoices with different amounts every month
* Revision V21 - Balashanthi - Defect # 5875 Reverting the code changes for Defct #5528
* Revision V22 - Renuka      - Defect # 6221 Change filter condition for recurring billing orders- Batch job-getReccurringBatchQueryString()
* Revision V23 - Balashanthi - Defect # 24312 wrong prices and output
* Revision V24 - Nagavi      - Defect # 6724 map Billing schedule 'Fee amount' to 'Net price' field on related Admin order line item for XD12
* Revision V25 - Ankit Joshi - CR # 2265 To run Recurring Batch for all countires
* Revision V26 - Balashanthi A - Defect # 6794 Admin order (XD09) does not populate - Fixed term Billing flag
* Revision V27 - Balashanthi A - Defect # 6776 The 'Start date' and 'End date' on the Bundle header (machine) should reflect the period of the related Order line items
* Revision V28 - Balashanthi A - Defect # 6785 Consumption input for February duplicated to January
* Revision V29 - Balashanthi A - CR # 2265 To run Recurring Batch for all countires - Running based on the processed check box @ custom setting
* Revision V30 - Balashanthi A -  JIRA : DOQBI-159: P1/P2 - Incident Recurring billing Order linked on superseded 
* Revision V31 - Balashanthi A -  JIRA : DOQBI-141: Adjustment amount applied twice on Admin order sent to SAP
* Revision V32 - Monika - 22-5-2019 - JIRA : DOQBI-138 : exclude XD12 and permanently exclude Sales orgs
* Revision V33 - Balashanthi A - 24-5-2019 - JIRA : DOQBI-250 : XD12 BPO is always populated irrespective of whether Paid or Free vend is used on related Asset Attribute value AND respective Usage fee
* Revision V34 - Balashanthi A - 27-5-2019 - JIRA : DOQBI-290 : fix for multiplying the BPO or List Price for FREE VEND and PAID for 100 Cups
* Revision V35 - Balashanthi A - 24-6-2019 - JIRA : DOQBI-352 : fix for Usage rating batch job should not pick up Usage input in status = error
* Revision V36 - Renuka - 19-08-2019 - JIRA : DFT2C-423 : Fix for 1. Usage Input Rated Amount = 0 and BS Fee Amount = 0, BS to Invoiced and no Admin Order creation.
* Revision V37 - Renuka - 22-08-2019 - JIRA : DFT2C-1274 : Fix Start end date logic on primary L1 admin order line picking Product/Service of Contracted Type.
* Revision V38 - Renuka - 07-09-2019 - JIRA : DFT2C-1408 :Fix for start and end date on primary l1 line item
* Revision V39 - Renuka - 12-11-2019 - JIRA : QTCFLEX1-1583 : Added custom metadata logic to populate the related invoice delivery preference based on Invoice type
* Revision V40 - Amit   - JIRA : DFT2C-2144 : Fix P4 - 2 machines on one order 
* Revision V41 - Renuka - 10-04-2020 - JIRA: DQ-1955: Update the Query Filter  
* Revision V42 - Renuka - 05-05-2020 - JIRA: DQ-2344: Populating EDI fields on XD09 Order Header from  Account. 
* Revision V43 - Renuka - 09-11-2020 - JIRA: DQ-3907: Calling Creditbatch
* Revision V44 - Renuka - 17-11-2020 - JIRA: DQ-4209: Z-Indicator logic specific to XD12 and XD09.
* Revision V45 - Renuka - 23-02-2021 - JIRA: DQ-5503: Adding logic for PeriodStartDate.
* Revision V46 - Renuka - 11-03-2021 - JIRA: DQ-5529: 100% proration logic should include BPO.
* Revision V47 - Renuka - 23-01-2021 - JIRA: DQ-5773: ZIndicator fix
**/
public with sharing class APTS_RecurringBillingScheduleBatchHelper{

    private static final String DEFAULTORDERREASON = 'X99';
    private static final String YSFL = 'YSFL';
    private static final String YSFS = 'YSFS';
    private static final String YSFC = 'YSFC';
    private static final String USAGETYPE = 'Usage';
    private static final String USAGEFEE = 'Usage Fee';
    //Base Price Discount
    private static final String DISCOUNTAMOUNT = 'Base Price Discount';
    private static final String MONTHLY = 'Monthly';
    private static final String QUARTERLY = 'Quarterly';
    private static final String HALFYEARLY = 'Half Yearly';
    private static final String YEARLY = 'Yearly';
    private static final String CALCULATENETPRICE = 'calculateNetPrice() Method';
    private static final String MACHINE ='Machine';
    private static final String COLLECTIVEINVOICE = 'Collective Invoice';
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
    private static final String RATED = 'Rated';
    //v1 start
    private static final String FREE_VEND = 'Free Vend';
    private static final String PAID = 'Paid';
    private static final String BOTH = 'Both';
    //v1 end
    private static final String DEINSTALLATION = 'De-installation';
    private static final String UNPLANNEDRETURN = 'Unplanned Return';
    private static final String STANDARDRETURN = 'Standard Return';
    private static final String FIXEDTERM = 'FixedTerm';
    private static final String NONFIXEDTERM = 'NonFixedTerm';
    //private static final String TYPEUSAGE = 'Usage';
    private static final String NONUSAGETYPE = 'NonUsage';
    private static final String MISC = 'Misc';
    private static final String BILLINGSCHEDULE = 'Billing Schedule';
    private static final String ADMINORDER = 'Admin Order';
    private static final String HOT_WATER = 'HOT WATER';
    private static final String COLD_WATER = 'COLD WATER';
    private static final String STARTDATE = 'StartDate';
    private static final String ENDDATE = 'EndDate';
    private static final String WITHPRICE = 'WithPrice';
    private static final String NOPRICE = 'NoPrice';
    private static final String ORDERADJUSTMENTLINEITEMOBJECT = 'Apttus_Config2__OrderAdjustmentLineItem';
    private static final Set<String> fixedTermTypeXD12 = new Set<String>{'All Ingredients','Fixed Costs and Ingredients'};
    private static final Set<String> fixedTermTypeXD09 = new Set<String>{'Fixed Cost','Fixed Costs and Ingredients'};
    private static final Set<String> counterBased = new Set<String>{'All Ingredients'};
    private static final string PERIOD_START_DATE = 'Period Start Date';
    
    /** Method Name : createAdminOrder
    * Description : Method to create admin Order and Send the Order and Order Line Item to SAP for Invoicing
    **/
    public static Map<String,Id> createAdminOrder(List<Apttus_Billing__BillingSchedule__c> billingScheduleRecords,
                                                    Map<String, Id> adminOrderCreatedInEachChunk,
                                                    Map<Id,Apttus_Config2__OrderLineItem__c> primaryOrderLineToUpdate,
                                                    Map<String,String> invoiceMap,
                                                    Map<String,Date> primaryL1DateMap){

        Set<Id> assetId = new Set<Id>();
        Set<Id> primaryAssetLine = new Set<Id>();
        Set<Id> agreementId = new Set<Id>();
        Set<Id> accountId = new Set<Id>();
        Map<Id,List<Apttus_Config2_AssetAdjustItem__c>> assetAdjMap = new Map<Id,List<Apttus_Config2_AssetAdjustItem__c>>();
        Map<Id,Apttus_Billing__BillingSchedule__c> billingSchedulesMap = new  Map<Id,Apttus_Billing__BillingSchedule__c>();
        Map<Id,Apttus_Billing__BillingSchedule__c> billingSchedulesOrderLineMap = new  Map<Id,Apttus_Billing__BillingSchedule__c>();
        Map<Id,List<APTS_Agreement_PO_Details__c>> assetAgrmntPODetailsMap = new  Map<Id,List<APTS_Agreement_PO_Details__c>>();
        Map<Id,Account> accountDataMap = new Map<Id,Account>();
        List<string> fixedTermTypeList = new List<string>();
        // Added fpr CR 2106
        Map<Id,List<Apttus_Billing__UsageInput__c>> usageBsMap = new  Map<Id,List<Apttus_Billing__UsageInput__c>>();
        //<<++ V28 - Balashanthi A - Defect # 6785 Consumption input for February duplicated to January Starts
        Map<Id,List<Apttus_Billing__UsageSchedule__c>> consumptionBsMap = new  Map<Id,List<Apttus_Billing__UsageSchedule__c>>();
        //<<++ V28 - Balashanthi A - Defect # 6785 Consumption input for February duplicated to January Ends
        //Set<Id> fixedTermagreementId = new Set<Id>();
        Map<Id,Apttus__APTS_Agreement__c> fixedTermagreementMap = new Map<Id,Apttus__APTS_Agreement__c>();//V44 
        Map<Id,APTS_Billing_Settings__c> billingSetting = new Map<Id,APTS_Billing_Settings__c>();
        Map<Id,Apttus_Billing__BillingSchedule__c> bSwithFeeAmountZeroMap = new Map<Id,Apttus_Billing__BillingSchedule__c>();
        Set<ID> bSwithFeeAmountZeroSet = new Set<Id>();
        try{ 
            String fixedTermType = System.Label.APTS_FixedTermType;
            if(String.isNotBlank(fixedTermType)){
                fixedTermTypeList = fixedTermType.split(',');
            }
            //From the billing schdedules create Asset Billing Schedules Map
            for (Apttus_Billing__BillingSchedule__c billingScheduleList : billingScheduleRecords) {
                //system.debug('billingScheduleList :Ed'+billingScheduleList.Apttus_Billing__PeriodEndDate__c );
                // skipping the Subtype De-installation, Unplanned Return and Standard Return
                if(!(DEINSTALLATION.equalsIgnoreCase(billingScheduleList.Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c)
                                    || UNPLANNEDRETURN.equalsIgnoreCase(billingScheduleList.Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c)
                                    || STANDARDRETURN.equalsIgnoreCase(billingScheduleList.Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c))){ 
                    assetId.add(billingScheduleList.Apttus_Billing__AssetLineItemId__c);
                    billingSchedulesMap.put(billingScheduleList.Id,billingScheduleList);
                   
                    //<<++ V30: JIRA : DOQBI-159: P1/P2 - Incident Recurring billing Order linked on superseded  Starts
                    if(billingScheduleList.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__c != null){
                        agreementId.add(billingScheduleList.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__c);
                    }else{
                         agreementId.add(billingScheduleList.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c);
                    }
                    //<<++ V30: JIRA : DOQBI-159: P1/P2 - Incident Recurring billing Order linked on superseded  Ends
                    // retieve the orginated Bundle Line Item from options and primaryAssetLine Set
                    if(billingScheduleList.Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Asset__c != null){
                        String keyForDate = String.valueOf(billingScheduleList.Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Asset__c);
                        if(!primaryAssetLine.contains(billingScheduleList.Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Asset__c)){
                            primaryAssetLine.add(billingScheduleList.Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Asset__c);
                        }
                        //populate p1LineBillingScheduleStartDateMap with the earliest start date 
                        if(billingScheduleList.Apttus_Billing__PeriodStartDate__c != null && !billingScheduleList.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__IsOptionRollupLine__c){
                            if(billingScheduleList.Apttus_Billing__FeeAmount__c>0){//<<++Begin  V41
                                if(!primaryL1DateMap.containsKey(keyForDate+STARTDATE+WITHPRICE)){
                                    primaryL1DateMap.put(keyForDate+STARTDATE+WITHPRICE,billingScheduleList.Apttus_Billing__PeriodStartDate__c);
                                }   
                                else if(primaryL1DateMap.get(keyForDate+STARTDATE+WITHPRICE) > billingScheduleList.Apttus_Billing__PeriodStartDate__c){
                                    primaryL1DateMap.put(keyForDate+STARTDATE+WITHPRICE,billingScheduleList.Apttus_Billing__PeriodStartDate__c);
                                }
                            }else{//Revision V38 : Renuka - Fix for start and end date on primary l1 line item
                                 if(!primaryL1DateMap.containsKey(keyForDate+STARTDATE+NOPRICE)){
                                    primaryL1DateMap.put(keyForDate+STARTDATE+NOPRICE,billingScheduleList.Apttus_Billing__PeriodStartDate__c);
                                }   
                                else if(primaryL1DateMap.get(keyForDate+STARTDATE+NOPRICE) > billingScheduleList.Apttus_Billing__PeriodStartDate__c){
                                    primaryL1DateMap.put(keyForDate+STARTDATE+NOPRICE,billingScheduleList.Apttus_Billing__PeriodStartDate__c);
                                }//<<++End  V41
                            }
                        }
                        
                        if(billingScheduleList.Apttus_Billing__PeriodEndDate__c != null && !billingScheduleList.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__IsOptionRollupLine__c){
                            if(billingScheduleList.Apttus_Billing__FeeAmount__c>0){//<<++Begin  V41
                                if(!primaryL1DateMap.containsKey(keyForDate+ENDDATE+WITHPRICE)){
                                    primaryL1DateMap.put(keyForDate+ENDDATE+WITHPRICE,billingScheduleList.Apttus_Billing__PeriodEndDate__c);
                                }   
                                else if(primaryL1DateMap.get(keyForDate+ENDDATE+WITHPRICE) < billingScheduleList.Apttus_Billing__PeriodEndDate__c){
                                    primaryL1DateMap.put(keyForDate+ENDDATE+WITHPRICE,billingScheduleList.Apttus_Billing__PeriodEndDate__c);
                                }
                            }else{
                                //Revision V38 : Renuka - Fix for start and end date on primary l1 line item
                                if(!primaryL1DateMap.containsKey(keyForDate+ENDDATE+NOPRICE)){
                                    primaryL1DateMap.put(keyForDate+ENDDATE+NOPRICE,billingScheduleList.Apttus_Billing__PeriodEndDate__c);
                                }   
                                else if(primaryL1DateMap.get(keyForDate+ENDDATE+NOPRICE) < billingScheduleList.Apttus_Billing__PeriodEndDate__c){
                                    primaryL1DateMap.put(keyForDate+ENDDATE+NOPRICE,billingScheduleList.Apttus_Billing__PeriodEndDate__c);
                                }//<<++End  V41
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
                    //<<++ V30: JIRA : DOQBI-159: P1/P2 - Incident Recurring billing Order linked on superseded  Starts
                    //V47
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
                            // <<++ V26 Defect # 6794 - Commented for this defect
                            //&& APTS_BIRUtils.CONSUMPTIONTYPEOFCONTRACT.equalsIgnoreCase(billingScheduleList.Apttus_Billing__AssetLineItemId__r.APTS_Type_Of_Contract__c)){
                            // <<++ V26 Defect # 6794 - Commented for this defect
                            //fixedTermagreementId.add(billingScheduleList.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c);
                            fixedTermagreementMap.put(billingScheduleList.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c,billingScheduleList.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__r);
                        }
                    }
                    
                }           
            }// End of For
            //system.debug('==> primaryAssetLine 1==>'+primaryAssetLine);
            // v2 Start
            //Query Usage Tiers based on BillingSchedulesId and populate consumptionBsMap
            //<<++ V28 - Balashanthi A - Defect # 6785 Changes the Mapping of consumptionBsMap
            List<Apttus_Billing__UsageSchedule__c> tempSchedule;
            for(Apttus_Billing__UsageSchedule__c usageSch : [SELECT id, 
                                                                    Name, 
                                                                    Apttus_Billing__AssetLineItemId__c, 
                                                                    Apttus_Billing__BillingScheduleId__c, 
                                                                    Apttus_Billing__BillingScheduleId__r.Apttus_Billing__PeriodEndDate__c, 
                                                                    Apttus_Billing__BillingScheduleId__r.Apttus_Billing__PeriodStartDate__c,
                                                                    Apttus_Billing__BillingScheduleId__r.Apttus_Billing__FeeAmount__c
                                                                FROM Apttus_Billing__UsageSchedule__c
                                                                WHERE Apttus_Billing__BillingScheduleId__c IN: billingSchedulesMap.keyset() 
                                                                LIMIT 50000]){

                tempSchedule = new List<Apttus_Billing__UsageSchedule__c>();
                if(consumptionBsMap.containsKey(usageSch.Apttus_Billing__AssetLineItemId__c)){
                    tempSchedule = consumptionBsMap.get(usageSch.Apttus_Billing__AssetLineItemId__c);
                    if (!tempSchedule.contains(usageSch)) {
                        tempSchedule.add(usageSch);
                        consumptionBsMap.put(usageSch.Apttus_Billing__AssetLineItemId__c,tempSchedule);
                    }
                }else{
                    tempSchedule.add(usageSch);
                    consumptionBsMap.put(usageSch.Apttus_Billing__AssetLineItemId__c, new List<Apttus_Billing__UsageSchedule__c>(tempSchedule));
                }
            }
            //system.debug('consumptionBsMap==>'+consumptionBsMap);
            // Retrieve Asset Adjustment Line Item
            List<Apttus_Config2_AssetAdjustItem__c> tempListAssetAdj;
            for (Apttus_Config2_AssetAdjustItem__c assetAdjLineItemData : [SELECT Id,
                                                                                Apttus_Config2_AssetAdjustAmount__c,
                                                                                Apttus_Config2_AssetAdjustAppliesTo__c,
                                                                                Apttus_Config2_AssetAdjustType__c,
                                                                                Apttus_Config2_Adjustment_Uom__c,
                                                                                APTS_Agreement_Number__c,   
                                                                                Agreement_LineItem_Id__c,
                                                                                Apttus_Config2_BenefitQuantity__c,
                                                                                Apttus_Config2_Bucket__c,
                                                                                Apttus_Config2_CouponCode__c,
                                                                                Apttus_Config2_IncentiveId__c,
                                                                                Apttus_Config2_IncentiveCode__c,
                                                                                Apttus_Config2_LineType__c,
                                                                                Apttus_Config2_PriceRuleId__c,
                                                                                Apttus_Config2_PriceRuleEntryId__c,
                                                                                Apttus_Config2_AssetLineItemId__c,
                                                                                Apttus_Config2_IncentiveAsetAdjustAmount__c,
                                                                                RunningTotalAdjustedPrice__c,
                                                                                Apttus_Config2_LineNumber__c,
                                                                                Apttus_Config2_SubType__c,
                                                                                Apttus_Config2_Type__c
                                                                            FROM Apttus_Config2_AssetAdjustItem__c
                                                                            WHERE Apttus_Config2_AssetLineItemId__c IN: assetId
                                                                            LIMIT 50000]) {
                tempListAssetAdj = new List<Apttus_Config2_AssetAdjustItem__c>();
                if(assetAdjMap.containsKey(assetAdjLineItemData.Apttus_Config2_AssetLineItemId__c)){
                    tempListAssetAdj = assetAdjMap.get(assetAdjLineItemData.Apttus_Config2_AssetLineItemId__c);

                    if (!tempListAssetAdj.contains(assetAdjLineItemData)) {
                        tempListAssetAdj.add(assetAdjLineItemData);
                        assetAdjMap.put(assetAdjLineItemData.Apttus_Config2_AssetLineItemId__c,tempListAssetAdj);
                    }
                }else{
                    tempListAssetAdj.add(assetAdjLineItemData);
                    assetAdjMap.put(assetAdjLineItemData.Apttus_Config2_AssetLineItemId__c, new List<Apttus_Config2_AssetAdjustItem__c>(tempListAssetAdj));
                }             
            }
            // Retrieve Agreement PO  details
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
           // added the field - APTS_Price_Type__c for Revision V33 -  JIRA : DOQBI-250 
            if(assetId.size()>0){
                // Retrieve usage Input records
                for(Apttus_Billing__UsageInput__c usageInput  :  [SELECT  Id,
                                                                            Apttus_Billing__AssetLineItemId__c,
                                                                            Apttus_Billing__AssetLineItemId__r.Name,
                                                                            Apttus_Billing__Quantity__c,
                                                                            Apttus_Billing__UsageDate__c,
                                                                            APTS_Price_Type__c,
                                                                            Apttus_Billing__RatedAmount__c
                                                                            FROM Apttus_Billing__UsageInput__c
                                                                            WHERE Apttus_Billing__AssetLineItemId__c IN: assetId
                                                                            AND Apttus_Billing__Status__c =: RATED
                                                                            LIMIT 50000]){
                    if(!consumptionBsMap.isEmpty()
                        && consumptionBsMap.containskey(usageInput.Apttus_Billing__AssetLineItemId__c)
                        && consumptionBsMap.get(usageInput.Apttus_Billing__AssetLineItemId__c) != null){
                        List<Apttus_Billing__UsageSchedule__c> usageScheduleList = consumptionBsMap.get(usageInput.Apttus_Billing__AssetLineItemId__c);
                        if(!usageScheduleList.isEmpty()){
                            for(Apttus_Billing__UsageSchedule__c usageSchedule : usageScheduleList){
                                if(usageInput.Apttus_Billing__UsageDate__c <= usageSchedule.Apttus_Billing__BillingScheduleId__r.Apttus_Billing__PeriodEndDate__c
                                    && usageInput.Apttus_Billing__UsageDate__c >= usageSchedule.Apttus_Billing__BillingScheduleId__r.Apttus_Billing__PeriodStartDate__c){
                                    if(usageBsMap.containsKey(usageInput.Apttus_Billing__AssetLineItemId__c)){
                                        usageBsMap.get(usageInput.Apttus_Billing__AssetLineItemId__c).add(usageInput);
                                    }
                                    else{
                                        usageBsMap.put(usageInput.Apttus_Billing__AssetLineItemId__c,new List<Apttus_Billing__UsageInput__c>{usageInput}); 
                                    }
                                    //Start V36 - Renuka - DFT2C-423 - Do not create AdminOrder LineItems and update BS as Invoiced. 
                                    if(usageInput.Apttus_Billing__RatedAmount__c==0 
                                        && usageSchedule.Apttus_Billing__BillingScheduleId__r.Apttus_Billing__FeeAmount__c==0
                                        && (usageInput.Apttus_Billing__AssetLineItemId__r.Name.containsIgnoreCase(HOT_WATER) 
                                            || usageInput.Apttus_Billing__AssetLineItemId__r.Name.containsIgnoreCase(COLD_WATER))){
                                        bSwithFeeAmountZeroSet.add(usageSchedule.Apttus_Billing__BillingScheduleId__c);
                                    }//End V36
                                } 
                            }
                        }
                    }
                }
            }
            //system.debug('usageBsMap==>'+usageBsMap);
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
            Map<String,Apttus_Config2__Order__c> adminOrderHeaderMap = processAdminOrderFromAssets(usageBsMap,billingSchedulesMap,
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
                                                                                                                assetAdjMap,
                                                                                                                primaryAssetLine,
                                                                                                                usageBsMap,
                                                                                                                primaryOrderLineToUpdate,
                                                                                                                bSwithFeeAmountZeroSet,
                                                                                                                primaryL1DateMap);
            // Update Billing schedules
            updateBillingscheduleStatus(billingScheduleRecords,newOrderLineBillingMap,bSwithFeeAmountZeroSet); 
        }catch(Exception e){
            APTS_BIRUtils.logError(null,null,null,e,APTS_BIRUtils.BATCH,APTS_BIRUtils.CREATEADMINORDER,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,true);
            return null;
        }
        return adminOrderCreatedInEachChunk;
    }
    /** Method Name : ProcessAdminOrderFromAssets
    * Description : Method to create admin Order and Send the Order and Order Line Item to SAP for Invoicing
    **/
    public static Map<String,Apttus_Config2__Order__c> processAdminOrderFromAssets(Map<Id,List<Apttus_Billing__UsageInput__c>> usageBsMap,
                                                                                    Map<Id,Apttus_Billing__BillingSchedule__c> billingSchedulesMap,
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
                    // Scenario : 1 ==> For Consumption+Fixed term Asset's Create 2 Admin Order per Bundle. 
                    // One for Usage Type Lines and the other with Normal Lines(i.e Charge, Rental) 
                    if(APTS_BIRUtils.CONSUMPTIONTYPEOFCONTRACT.equalsIgnoreCase(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_Type_Of_Contract__c)){
                        // Consumption Type with  Usage Charge Type - Create Separate Admin Order Header
                        if(USAGETYPE.equalsIgnoreCase(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PriceType__c)
                            && USAGEFEE.equalsIgnoreCase(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ChargeType__c)){
                            //STARTS : Revision V35 - Balashanthi A - 24-6-2019 - JIRA : DOQBI-352 : fix for Usage rating batch job should not pick up Usage input in status = error 
                            if (usageBsMap.containsKey(billingScheduleData.Apttus_Billing__AssetLineItemId__c)){
                                for(Apttus_Billing__UsageInput__c usageInputRec : usageBsMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__c)){
                                    if(usageInputRec.Apttus_Billing__UsageDate__c <= billingScheduleData.Apttus_Billing__PeriodEndDate__c
                                        && usageInputRec.Apttus_Billing__UsageDate__c >= billingScheduleData.Apttus_Billing__PeriodStartDate__c){
                                        createAdminOrderHeader(billingScheduleData,assetAgrmntPODetailsMap,accountDataMap,
                                                                                        billingSetting,fixedTermagreementMap,adminOrderId,
                                                                                        USAGETYPE,finalOrderMapToInsert,adminOrderCreatedInEachChunk,
                                                                                        invoiceMap);
                                        break;
                                    }
                                }
                            }
                            // Below line is commented on  Revision V35
                            /*createAdminOrderHeader(billingScheduleData,assetAgrmntPODetailsMap,accountDataMap,
                                                                                    billingSetting,fixedTermagreementId,adminOrderId,
                                                                                    USAGETYPE,finalOrderMapToInsert,adminOrderCreatedInEachChunk);*/
                            //ENDS : Revision V35 - Balashanthi A - 24-6-2019 - JIRA : DOQBI-352 : fix for Usage rating batch job should not pick up Usage input in status = error
                        }else{
                            // Consumption with Service lines =  Create Separate Admin Order Header
                            createAdminOrderHeader(billingScheduleData,assetAgrmntPODetailsMap,accountDataMap,
                                                                                    billingSetting,fixedTermagreementMap,adminOrderId,
                                                                                    NONUSAGETYPE,finalOrderMapToInsert,adminOrderCreatedInEachChunk,
                                                                                    invoiceMap);
                        }
                    }
                    //Scenario 2: For consumption Type without Fixed Term, Create One Admin Order Per bundle
                    // For Non Consumption Type , Create One Admin Order Per Bundle
                    else{
                         createAdminOrderHeader(billingScheduleData,assetAgrmntPODetailsMap,accountDataMap,
                                                                                    billingSetting,fixedTermagreementMap,adminOrderId,
                                                                                    NONUSAGETYPE,finalOrderMapToInsert,adminOrderCreatedInEachChunk,
                                                                                    invoiceMap);
                    }
                }
            }
            //system.debug('**************finalOrderMapToInsert SIZE *****'+finalOrderMapToInsert.size());
            //system.debug('**************finalOrderMapToInsert*****'+finalOrderMapToInsert);
            if(!finalOrderMapToInsert.isEmpty()
                && finalOrderMapToInsert.values() != null){
                //system.debug('**************INSERT INSIDE *****');
                //insert finalOrderMapToInsert.values();
                Database.SaveResult[] srList = Database.insert(finalOrderMapToInsert.values(), false);
                APTS_BIRUtils.logError(null,srList,null,null,APTS_BIRUtils.BATCH,APTS_BIRUtils.ORDEROBJECTNAME,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,false);
            }
        }catch(Exception e){APTS_BIRUtils.logError(null,null,null,e,APTS_BIRUtils.BATCH,APTS_BIRUtils.ORDEROBJECTNAME,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,true);
            return null;
        }
        return finalOrderMapToInsert;  
    }

    /** Method Name : createAdminOrderHeader
    * Description : Method to create admin Order and Send the Order and Order Line Item to SAP for Invoicing
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
                order.Apttus_Config2__ActivatedDate__c = system.today(); 
                order.Apttus_Config2__ReadyForBillingDate__c = system.today();
                order.APTS_Name__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__r.Name;
                order.Apttus_Config2__OrderStartDate__c = Date.today();
                order.Apttus_Config2__PriceListId__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PriceListId__c;
                //<<++ V30: JIRA : DOQBI-159: P1/P2 - Incident Recurring billing Order linked on superseded  Starts
                if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__c  != null){
                    order.Apttus_CMConfig__AgreementId__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__c;
                }else{
                   order.Apttus_CMConfig__AgreementId__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c; 
                }
                //<<++ V30: JIRA : DOQBI-159: P1/P2 - Incident Recurring billing Order linked on superseded  ENDS
                order.Apttus_Config2__SoldToAccountId__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c;
                // <<++ V16 - Balashanthi - Defect # 5361 Commented the below logic
                //order.Apttus_Config2__BillToAccountId__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillToAccountId__c;
                // >>++ V16 - Balashanthi - Defect # 5361 Commented the below logic
                order.Apttus_Config2__LocationId__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__LocationId__c;
                order.Apttus_Config2__PricingDate__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PricingDate__c;
                //order.APTS_Billing_Date__c = billingScheduleData.Apttus_Billing__ReadyForInvoiceDate__c;
                order.APTS_Billing_Date__c = getBillingDate(billingScheduleData);
                if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PriceListId__c != null){
                   order.CurrencyIsoCode = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PriceListId__r.CurrencyIsoCode; 
                }
                /**************************************************************************
                *******TYPE***********==*******SAP ORDER TYPE******==FIXED TERM FLAG******
                * Machines and Services              XD09              BLANK
                * Consumption                        Xd12               A01
                * Fixed+Machines and Services        XD09                Z
                * Consumption+Services(Usage)        XD12              BLANK
                * Consumption+Services(Non Usage)    XD09              A01
                * Consumption 
                    +Services Fixed term(USAGE)      XD12               Z
                *  Consumption 
                    +Services Fixed term(Non USAGE)  XD09               A01
                /**************************************************************************/
                if(APTS_BIRUtils.CONSUMPTIONTYPEOFCONTRACT.equalsIgnoreCase(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_Type_Of_Contract__c)){
                    // Consumption Type with Fixed Term Usage Charge Type 
                    if(USAGETYPE.equalsIgnoreCase(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PriceType__c)
                        && USAGEFEE.equalsIgnoreCase(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ChargeType__c)){
                        order.APTS_SAP_OrderType__c = APTS_BIRUtils.CONSUMPTIONSAPORDERTYPE;
                        // consumption+Fixed Term
                        //<<++ V30: JIRA : DOQBI-159: P1/P2 - Incident Recurring billing Order linked on superseded  Starts
                        if(!fixedTermagreementMap.isEmpty() //V44 Changed the fix_termLogic specific to XD12
                            && fixedTermagreementMap.containsKey(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__c) 
                            && fixedTermagreementMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__c) != null 
                            && fixedTermTypeXD12.contains(fixedTermagreementMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__c).APTS_Fixed_Term_Type__c)){
                            
                            order.APTS_Fix_Term_Billing_Flag__c = APTS_BIRUtils.FIXEDTERMINDICATOR;   
                        }else if (!fixedTermagreementMap.isEmpty() 
                                    && fixedTermagreementMap.containsKey(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c) 
                                    && fixedTermagreementMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c) != null 
                                    && fixedTermTypeXD12.contains(fixedTermagreementMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c).APTS_Fixed_Term_Type__c)){
                            
                            order.APTS_Fix_Term_Billing_Flag__c = APTS_BIRUtils.FIXEDTERMINDICATOR;  
                        }
                        /*if(fixedTermagreementId.contains(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__c)){
                            order.APTS_Fix_Term_Billing_Flag__c = APTS_BIRUtils.FIXEDTERMINDICATOR;   
                        }
                        else if(fixedTermagreementId.contains(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c)){
                            order.APTS_Fix_Term_Billing_Flag__c = APTS_BIRUtils.FIXEDTERMINDICATOR;     
                        }*/
                        //<<++ V30: JIRA : DOQBI-159: P1/P2 - Incident Recurring billing Order linked on superseded  ENDS
                    }else{
                        order.APTS_SAP_OrderType__c = APTS_BIRUtils.ADMINORDERSAPORDERTYPE;
                        if(!fixedTermagreementMap.isEmpty() //V44 Changed the fix_termLogic specific to XD12
                            && fixedTermagreementMap.containsKey(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__c) 
                            && fixedTermagreementMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__c) != null 
                            && fixedTermTypeXD09.contains(fixedTermagreementMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__c).APTS_Fixed_Term_Type__c)
                            && fixedTermagreementMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__c).APTS_CounterBased__c){
                                
                            order.APTS_Fix_Term_Billing_Flag__c = APTS_BIRUtils.FIXEDTERMINDICATOR;
                        }else if(!fixedTermagreementMap.isEmpty() //V44 Changed the fix_termLogic specific to XD12
                            && fixedTermagreementMap.containsKey(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c) 
                            && fixedTermagreementMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c) != null 
                            && fixedTermTypeXD09.contains(fixedTermagreementMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c).APTS_Fixed_Term_Type__c)
                            && fixedTermagreementMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c).APTS_CounterBased__c){
                            
                            order.APTS_Fix_Term_Billing_Flag__c = APTS_BIRUtils.FIXEDTERMINDICATOR;
                        }else if(!fixedTermagreementMap.isEmpty() //V44 Changed the fix_termLogic specific to XD12
                            && fixedTermagreementMap.containsKey(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__c) 
                            && fixedTermagreementMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__c) != null 
                            && counterBased.contains(fixedTermagreementMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__c).APTS_Fixed_Term_Type__c)
                            && fixedTermagreementMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__c).APTS_CounterBased__c){
                                
                            order.APTS_Fix_Term_Billing_Flag__c = '';
                        }else if(!fixedTermagreementMap.isEmpty() //V44 Changed the fix_termLogic specific to XD12
                            && fixedTermagreementMap.containsKey(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c) 
                            && fixedTermagreementMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c) != null 
                            && counterBased.contains(fixedTermagreementMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c).APTS_Fixed_Term_Type__c)
                            && fixedTermagreementMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c).APTS_CounterBased__c){
                            
                            order.APTS_Fix_Term_Billing_Flag__c = '';
                        }else{
                            order.APTS_Fix_Term_Billing_Flag__c = CONSUMPTIONINDICATORFLAG;
                        }
                        
                    } 
                }else{
                    // Only Machine & Services
                    order.APTS_SAP_OrderType__c = APTS_BIRUtils.ADMINORDERSAPORDERTYPE;
                    // Machine & Services with Fixed Term
                    // <<++ V26 Defect # 6794 - Admin order (XD09) does not populate Fixed term Billing flag
                    //<<++ V30: JIRA : DOQBI-159: P1/P2 - Incident Recurring billing Order linked on superseded  Starts
                    if(!fixedTermagreementMap.isEmpty() //V44 Changed the fix_termLogic specific to XD09
                        && fixedTermagreementMap.containsKey(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__c) 
                        && fixedTermagreementMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__c) != null 
                        && fixedTermTypeXD09.contains(fixedTermagreementMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__c).APTS_Fixed_Term_Type__c)){
                        
                        order.APTS_Fix_Term_Billing_Flag__c = APTS_BIRUtils.FIXEDTERMINDICATOR;   
                    }else if (!fixedTermagreementMap.isEmpty() 
                                && fixedTermagreementMap.containsKey(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c) 
                                && fixedTermagreementMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c) != null 
                                && fixedTermTypeXD09.contains(fixedTermagreementMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c).APTS_Fixed_Term_Type__c)){
                        
                        order.APTS_Fix_Term_Billing_Flag__c = APTS_BIRUtils.FIXEDTERMINDICATOR;  
                    }
                    /*if(fixedTermagreementId.contains(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__c)){
                        order.APTS_Fix_Term_Billing_Flag__c = APTS_BIRUtils.FIXEDTERMINDICATOR;  
                    }
                    else if(fixedTermagreementId.contains(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c)){
                        order.APTS_Fix_Term_Billing_Flag__c = APTS_BIRUtils.FIXEDTERMINDICATOR;  
                    }*/
                     //<<++ V30: JIRA : DOQBI-159: P1/P2 - Incident Recurring billing Order linked on superseded  Ends
                    // >>-- V26 Defect # 6794 - Admin order (XD09) does not populate Fixed term Billing flag
                }
                /**************************************************************************/
                //<<++ V30: JIRA : DOQBI-159: P1/P2 - Incident Recurring billing Order linked on superseded  Starts
                if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__r.Apttus__Primary_Contact__c != null){
                    order.Apttus_Config2__PrimaryContactId__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__r.Apttus__Primary_Contact__c;
                }
                else if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__r.Apttus__Primary_Contact__c != null){
                    order.Apttus_Config2__PrimaryContactId__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__r.Apttus__Primary_Contact__c;
                }
                //<<++ V30: JIRA : DOQBI-159: P1/P2 - Incident Recurring billing Order linked on superseded  Ends
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

                //V12 +++> Changes for defect # 4900 Starts
                // Setting of Billing key fields on Order Header
                //<<++ V30: JIRA : DOQBI-159: P1/P2 - Incident Recurring billing Order linked on superseded  Starts
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
                //<<++ V30: JIRA : DOQBI-159: P1/P2 - Incident Recurring billing Order linked on superseded  ENDS
                // Invoice list Indicator and Collective list indicator flag setting
                if(String.isNotBlank(order.APTS_InvoiceType__c)){
                    if(COLLECTIVEINVOICE.equalsIgnoreCase(order.APTS_InvoiceType__c)){
                        order.APTS_Collective_Billing_Indicator__c = true;
                        order.APTS_Invoice_List_Indicator__c = NO;
                    }else if(COLLECTIVEINVOICE_WITHSMRYPAGE.equalsIgnoreCase(order.APTS_InvoiceType__c)){
                        order.APTS_Collective_Billing_Indicator__c = true;
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
                //V12 --> Changes for defect # 4900 Ends
                // Setting Sales Organisation, Distribution channel and Division
                
                if(!accountDataMap.isEmpty()
                    && billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c != null
                    && accountDataMap.containsKey(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c) != null
                    && accountDataMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c) != null){
                        order.APTS_Sales_Organization__c = accountDataMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c).Sales_Organization__c != null? accountDataMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c).Sales_Organization__c : null;
                        order.APTS_Distribution_Channel__c = accountDataMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c).Distribution_Channel__c != null? accountDataMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c).Distribution_Channel__c : null;
                        order.APTS_Division__c = accountDataMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c).Division__c != null? accountDataMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c).Division__c : null;  
                        //V42 ++<< Starts
                        if(order.APTS_SAP_OrderType__c == APTS_BIRUtils.ADMINORDERSAPORDERTYPE){
                            order.APTS_EDI_Name_of_Orderer__c=accountDataMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c).EDI_Name_of_Orderer__c != null? accountDataMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c).EDI_Name_of_Orderer__c : null;  
                            order.APTS_EDI_Payer_Head_Text__c=accountDataMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c).EDI_Payer_Head_Text__c != null? accountDataMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c).EDI_Payer_Head_Text__c : null;  
                            order.APTS_EDI_Reference_Number__c=accountDataMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c).EDI_Reference_Number__c != null? accountDataMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c).EDI_Reference_Number__c : null;  
                        }//V42 ++ Ends>>
                }
                //<<++ V30: JIRA : DOQBI-159: P1/P2 - Incident Recurring billing Order linked on superseded  Starts
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
                            // && billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_Physical_Asset__c != null ==> Commented for defect 5254
                            if(APTS_BIRUtils.MACHINE.equalsIgnoreCase(agreementPoDetail.APTS_PO_Category__c)){
                                order.Apttus_Config2__PONumber__c = agreementPoDetail.APTS_PO_Number__c;
                            }
                        }
                    }
                }
                //<<++ V30: JIRA : DOQBI-159: P1/P2 - Incident Recurring billing Order linked on superseded  ENDS
                if(APTS_BIRUtils.CONSUMPTIONTYPEOFCONTRACT.equalsIgnoreCase(
                        billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_Type_Of_Contract__c)){
                    // Consumption Type with Fixed Term 
                    if(USAGETYPE.equalsIgnoreCase(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PriceType__c)
                        && USAGEFEE.equalsIgnoreCase(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ChargeType__c)){
                        // Fixed Term Consumption Type with Usage Type 
                        orderMapToInsert.put(String.valueOf(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Asset__c)+USAGETYPE,order);
                    }else{
                        // Consumption Type without Usage Type 
                        orderMapToInsert.put(String.valueOf(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Asset__c)+NONUSAGETYPE,order);
                    }
                }else{
                    // Non Consumption Type, Consumption Type
                    orderMapToInsert.put(String.valueOf(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Asset__c+NONUSAGETYPE),order); 
                }
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
                                                                                                Map<Id,List<Apttus_Config2_AssetAdjustItem__c>> assetAdjMap, 
                                                                                                Set<Id> primaryAssetLine,
                                                                                                Map<Id,List<Apttus_Billing__UsageInput__c>> usageBsMap,
                                                                                                Map<Id,Apttus_Config2__OrderLineItem__c> primaryOrderLineToUpdate,
                                                                                                Set<Id> bSwithFeeAmountZeroSet,
                                                                                                Map<String,Date> primaryL1DateMap){
        Map<Id,Apttus_Config2__OrderLineItem__c> oliBillingScheduleMap = new Map<Id,Apttus_Config2__OrderLineItem__c>();
        //<<++ Defect # 5662 - LAE/RAR Missing Hierarchy level in XD09 recurring billing orders Starts
        Map<Id,Apttus_Config2__OrderLineItem__c> primaryOliToInsert = new Map<Id,Apttus_Config2__OrderLineItem__c>();
        Map<Id,Apttus_Config2__OrderLineItem__c> insertedPrimaryLine = new Map<Id,Apttus_Config2__OrderLineItem__c>();
        //<<++ Defect # 5662 - LAE/RAR Missing Hierarchy level in XD09 recurring billing orders Ends
        Map<Id,Apttus_Config2__OrderLineItem__c> insertedOrderLineMap = new Map<Id,Apttus_Config2__OrderLineItem__c>();
        Map<Id,Decimal> assetprorationRatio1Map = new Map<Id,Decimal>();
        Map<Id,Id> orderLineMainLine = new Map<Id,Id>();
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
                    if(tempMap.containskey(primaryL1assetId+APTS_BIRUtils.CONSUMPTIONSAPORDERTYPE)){
                        if(APTS_BIRUtils.CONSUMPTIONTYPEOFCONTRACT.equalsIgnoreCase(tempMap.get(primaryL1assetId+APTS_BIRUtils.CONSUMPTIONSAPORDERTYPE).APTS_Type_of_Contract__c)){
                            //<<++ 5662 - LAE/RAR Missing Hierarchy level in XD09 recurring billing orders
                            insertedPrimaryLine.put(tempMap.get(primaryL1assetId+APTS_BIRUtils.CONSUMPTIONSAPORDERTYPE).Apttus_Config2__OrderId__c,
                                                                            tempMap.get(primaryL1assetId+APTS_BIRUtils.CONSUMPTIONSAPORDERTYPE));
                            //<<-- 5662 - LAE/RAR Missing Hierarchy level in XD09 recurring billing orders
                            createdP1LineMap.put(String.valueOf(primaryL1assetId)+USAGETYPE,tempMap.get(primaryL1assetId+APTS_BIRUtils.CONSUMPTIONSAPORDERTYPE));
                            if(tempMap.containskey(primaryL1assetId+APTS_BIRUtils.ADMINORDERSAPORDERTYPE)){
                                //<<++ 5662 - LAE/RAR Missing Hierarchy level in XD09 recurring billing orders
                                insertedPrimaryLine.put(tempMap.get(primaryL1assetId+APTS_BIRUtils.ADMINORDERSAPORDERTYPE).Apttus_Config2__OrderId__c,
                                                                            tempMap.get(primaryL1assetId+APTS_BIRUtils.ADMINORDERSAPORDERTYPE));
                                //<<-- 5662 - LAE/RAR Missing Hierarchy level in XD09 recurring billing orders
                                createdP1LineMap.put(String.valueOf(primaryL1assetId)+NONUSAGETYPE,tempMap.get(primaryL1assetId+APTS_BIRUtils.ADMINORDERSAPORDERTYPE)); 
                            }else{
                                primaryLineOLIToCreate.add(primaryL1assetId);
                            }
                        }else{
                            //<<++ 5662 - LAE/RAR Missing Hierarchy level in XD09 recurring billing orders
                            insertedPrimaryLine.put(tempMap.get(primaryL1assetId+APTS_BIRUtils.CONSUMPTIONSAPORDERTYPE).Apttus_Config2__OrderId__c,
                                                                            tempMap.get(primaryL1assetId+APTS_BIRUtils.CONSUMPTIONSAPORDERTYPE));
                            //<<-- 5662 - LAE/RAR Missing Hierarchy level in XD09 recurring billing orders
                            createdP1LineMap.put(String.valueOf(primaryL1assetId)+USAGETYPE,tempMap.get(primaryL1assetId+APTS_BIRUtils.CONSUMPTIONSAPORDERTYPE));
                        }
                    }
                    else if(tempMap.containskey(primaryL1assetId+APTS_BIRUtils.ADMINORDERSAPORDERTYPE)){
                        if(APTS_BIRUtils.CONSUMPTIONTYPEOFCONTRACT.equalsIgnoreCase(tempMap.get(primaryL1assetId+APTS_BIRUtils.ADMINORDERSAPORDERTYPE).APTS_Type_of_Contract__c)){
                            //<<++ 5662 - LAE/RAR Missing Hierarchy level in XD09 recurring billing orders
                            insertedPrimaryLine.put(tempMap.get(primaryL1assetId+APTS_BIRUtils.ADMINORDERSAPORDERTYPE).Apttus_Config2__OrderId__c,
                                                                            tempMap.get(primaryL1assetId+APTS_BIRUtils.ADMINORDERSAPORDERTYPE));
                            //<<-- 5662 - LAE/RAR Missing Hierarchy level in XD09 recurring billing orders
                            createdP1LineMap.put(String.valueOf(primaryL1assetId)+NONUSAGETYPE,tempMap.get(primaryL1assetId+APTS_BIRUtils.ADMINORDERSAPORDERTYPE));
                            if(tempMap.containskey(primaryL1assetId+APTS_BIRUtils.CONSUMPTIONSAPORDERTYPE)){
                                //<<++ 5662 - LAE/RAR Missing Hierarchy level in XD09 recurring billing orders
                                insertedPrimaryLine.put(tempMap.get(primaryL1assetId+APTS_BIRUtils.CONSUMPTIONSAPORDERTYPE).Apttus_Config2__OrderId__c,
                                                                            tempMap.get(primaryL1assetId+APTS_BIRUtils.CONSUMPTIONSAPORDERTYPE));
                                //<<-- 5662 - LAE/RAR Missing Hierarchy level in XD09 recurring billing orders
                                createdP1LineMap.put(String.valueOf(primaryL1assetId)+USAGETYPE,tempMap.get(primaryL1assetId+APTS_BIRUtils.CONSUMPTIONSAPORDERTYPE)); 
                            }else{
                                primaryLineOLIToCreate.add(primaryL1assetId);
                            }
                        }else{
                            //<<++ 5662 - LAE/RAR Missing Hierarchy level in XD09 recurring billing orders
                            insertedPrimaryLine.put(tempMap.get(primaryL1assetId+APTS_BIRUtils.ADMINORDERSAPORDERTYPE).Apttus_Config2__OrderId__c,
                                                                            tempMap.get(primaryL1assetId+APTS_BIRUtils.ADMINORDERSAPORDERTYPE));
                            //<<-- 5662 - LAE/RAR Missing Hierarchy level in XD09 recurring billing orders
                            createdP1LineMap.put(String.valueOf(primaryL1assetId)+NONUSAGETYPE,tempMap.get(primaryL1assetId+APTS_BIRUtils.ADMINORDERSAPORDERTYPE)); 
                        }
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
                    if(!APTS_BIRUtils.PRODUCTORSERVICE.equalsIgnoreCase(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__LineType__c)
                       && !bSwithFeeAmountZeroSet.contains(billingScheduleData.Id)){//V36

                        if(USAGETYPE.equalsIgnoreCase(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PriceType__c)
                            && USAGEFEE.equalsIgnoreCase(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ChargeType__c)
                            && adminOrderCreatedInEachChunk.containsKey(String.valueOf(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Asset__c)
                                                                            + USAGETYPE)
                            && adminOrderCreatedInEachChunk.get(String.valueOf(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Asset__c)
                                                                            + USAGETYPE)!= null
                            && billingSchedulesOrderLineMap.containsKey(billingScheduleData.Id)){
                            orderId = adminOrderCreatedInEachChunk.get(String.valueOf(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Asset__c)
                                                                                                    +USAGETYPE);
                            //system.debug('==> ISNDIE USAGE TYPE ORDER==='+orderId);
                        }
                        else{
                            if(adminOrderCreatedInEachChunk.containsKey(String.valueOf(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Asset__c)
                                                        + NONUSAGETYPE)
                                && adminOrderCreatedInEachChunk.get(String.valueOf(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Asset__c)
                                                        + NONUSAGETYPE)!= null
                                && billingSchedulesOrderLineMap.containsKey(billingScheduleData.Id)){
                                orderId = adminOrderCreatedInEachChunk.get(String.valueOf(String.valueOf(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Asset__c)
                                                                                            +NONUSAGETYPE));
                                //system.debug('==> INSIDE NON USAGE TYPE ADMIN ORDER==='+orderId);
                            }
                        }
                    }
                    // Primary Lines - Look for It's Id
                    else{
                        if(APTS_BIRUtils.CONSUMPTIONTYPEOFCONTRACT.equalsIgnoreCase(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_Type_Of_Contract__c)
                            && !bSwithFeeAmountZeroSet.contains(billingScheduleData.Id)){//V36
                            // Usage Primary Lines
                            if(USAGETYPE.equalsIgnoreCase(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PriceType__c)
                                && USAGEFEE.equalsIgnoreCase(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ChargeType__c)
                                && adminOrderCreatedInEachChunk.containsKey(String.valueOf(billingScheduleData.Apttus_Billing__AssetLineItemId__c)
                                                        + USAGETYPE)
                                && adminOrderCreatedInEachChunk.get(String.valueOf(billingScheduleData.Apttus_Billing__AssetLineItemId__c)
                                                        + USAGETYPE)!= null
                                && billingSchedulesOrderLineMap.containsKey(billingScheduleData.Id)
                                && !createdP1LineMap.containsKey(String.valueOf(billingScheduleData.Apttus_Billing__AssetLineItemId__c)+USAGETYPE)){
                                orderId = adminOrderCreatedInEachChunk.get(String.valueOf(billingScheduleData.Apttus_Billing__AssetLineItemId__c)
                                                                                            +USAGETYPE);
                                //system.debug('==> INSIDE NON USAGE CONMSUPTION ADMIN ORDER==='+orderId);
                            }
                            // Non Usage Primary Lines
                            else if(adminOrderCreatedInEachChunk.containsKey(String.valueOf(billingScheduleData.Apttus_Billing__AssetLineItemId__c)
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
                        orderLineItem.Apttus_Config2__ActivatedDate__c = system.today(); 
                        orderLineItem.Apttus_Config2__ReadyForBillingDate__c = system.today();
                        orderLineItem.APTS_Status__c = APTS_BIRUtils.ACTIVATED;
                        orderLineItem.Apttus_Config2__Status__c = APTS_BIRUtils.ACTIVATED;
                        orderLineItem.APTS_Item_Relevant_for_SAP__c = true;
                        //Added below line to capture the currency from the price list for defect# 22384
                        orderLineItem.CurrencyIsoCode=billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PriceListId__r.CurrencyIsoCode;
                        if(APTS_BIRUtils.CONSUMPTIONTYPEOFCONTRACT.equalsIgnoreCase(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_Type_Of_Contract__c)){
                            // Consumption Type with Fixed Term Usage Charge Type 
                            if(USAGETYPE.equalsIgnoreCase(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PriceType__c)
                                && USAGEFEE.equalsIgnoreCase(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ChargeType__c)){
                                orderLineItem.APTS_SAP_OrderType__c = APTS_BIRUtils.CONSUMPTIONSAPORDERTYPE;
                            }else{
                                orderLineItem.APTS_SAP_OrderType__c = APTS_BIRUtils.ADMINORDERSAPORDERTYPE;
                            } 
                        }else{
                            // Only Machine & Services
                            // Machine & Services with Fixed Term
                            orderLineItem.APTS_SAP_OrderType__c = APTS_BIRUtils.ADMINORDERSAPORDERTYPE;
                        }
                       
                        orderLineItem.APTS_BillingSchedule__c = billingScheduleData.Id;
                        if(billingScheduleData.Apttus_Billing__OrderLineItemId__c != null){
                            orderLineItem.APTS_Original_Order_Line_Item__c = billingScheduleData.Apttus_Billing__OrderLineItemId__c;
                        }
                        // XD12 Type Primary Line set Item relevant for SAp = false
                        if(APTS_BIRUtils.PRODUCTORSERVICE.equalsIgnoreCase(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__LineType__c)
                            && USAGETYPE.equalsIgnoreCase(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PriceType__c)
                            && USAGEFEE.equalsIgnoreCase(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ChargeType__c)
                            && billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Line__c){
                            orderLineItem.APTS_Item_Relevant_for_SAP__c = false;
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
                        //<<++ V30: JIRA : DOQBI-159: P1/P2 - Incident Recurring billing Order linked on superseded  Starts
                        if( billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__c != null){
                            orderLineItem.Apttus_CMConfig__AgreementId__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__c;
                        }else {
                            orderLineItem.Apttus_CMConfig__AgreementId__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c;
                        }
                        //<<++ V30: JIRA : DOQBI-159: P1/P2 - Incident Recurring billing Order linked on superseded  Ends
                        
                        orderLineItem.Apttus_Config2__Quantity__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__Quantity__c;
                        orderLineItem.Apttus_Config2__SellingUom__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__SellingUom__c;
                        orderLineItem.Apttus_Config2__AssetLineItemId__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Id;
                        // Defect # 23766 - Payer assignment incorrect for Admin Orders in Apttus >>> V4
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
                        //  Consumption Model - don't do proration Logic
                        if(USAGETYPE.equalsIgnoreCase(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PriceType__c)
                            && USAGEFEE.equalsIgnoreCase(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ChargeType__c)
                            && billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AttributeValueId__c != null){
                            if(!usageBsMap.isEmpty()
                                && usageBsMap.containsKey(billingScheduleData.Apttus_Billing__AssetLineItemId__c)
                                && usageBsMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__c) != null ){
                                // v1 start
                                Decimal quantity = 0;
                                Boolean isPaidPriceTypeExists = false;
                                Boolean isFVPriceTypeExists = false;
                                for(Apttus_Billing__UsageInput__c usageInputRec : usageBsMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__c)){
                                    // V28 <<++ : Balashanthi A - Defect # 6785 Consumption input for February duplicated to January
                                    if(usageInputRec.Apttus_Billing__UsageDate__c <= billingScheduleData.Apttus_Billing__PeriodEndDate__c
                                        && usageInputRec.Apttus_Billing__UsageDate__c >= billingScheduleData.Apttus_Billing__PeriodStartDate__c){
                                    // V28 <<-- : Balashanthi A - Defect # 6785 Consumption input for February duplicated to January
                                        quantity = quantity + usageInputRec.Apttus_Billing__Quantity__c;
                                        orderLineItem.Apttus_Config2__Quantity__c  = quantity;

                                        //<<++ Revision V33 - Balashanthi A - 24-5-2019 - JIRA : DOQBI-250 : XD12 BPO is always populated irrespective of whether Paid or Free vend is used on related Asset Attribute value AND respective Usage fee
                                        if(BOTH.equalsIgnoreCase(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AttributeValueId__r.APTS_Type_of_Consumption__c)){
                                            if(PAID.equalsIgnoreCase(usageInputRec.APTS_Price_Type__c)){
                                                isPaidPriceTypeExists = true;
                                            }
                                            if(FREE_VEND.equalsIgnoreCase(usageInputRec.APTS_Price_Type__c)){
                                                isFVPriceTypeExists = true;
                                            }
                                            // if Both UI of Type Paid and Free Vend Get the Average
                                            if(isPaidPriceTypeExists && isFVPriceTypeExists){
                                                if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AttributeValueId__r.APTS_Base_Price_Override_per_cup__c != null && billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AttributeValueId__r.APTS_Base_Price_Override_per_cup_FV__c != null){
                                                    orderLineItem.Apttus_Config2__BasePriceOverride__c = ((billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AttributeValueId__r.APTS_Base_Price_Override_per_cup__c + billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AttributeValueId__r.APTS_Base_Price_Override_per_cup_FV__c) * 100 ) / 2 ;
                                                }
                                                if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AttributeValueId__r.APTS_List_Price_per_cup__c != null && billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AttributeValueId__r.APTS_List_Price_per_cup_FV__c!= null){
                                                    orderLineItem.APTS_Z030_GSV_Consumption__c = ((billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AttributeValueId__r.APTS_List_Price_per_cup__c + billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AttributeValueId__r.APTS_List_Price_per_cup_FV__c) * 100 ) / 2 ;
                                                }
                                            }
                                            // Only of UI of Paid Price Type Exists
                                            else if(isPaidPriceTypeExists){
                                                //<<++ Revision V34 - Balashanthi A - 27-5-2019 - JIRA : DOQBI-290 : fix for multiplying the BPO or List Price for FREE VEND and PAID for 100 Cups Starts
                                                if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AttributeValueId__r.APTS_Base_Price_Override_per_cup__c != null ){
                                                    orderLineItem.Apttus_Config2__BasePriceOverride__c = 100 * billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AttributeValueId__r.APTS_Base_Price_Override_per_cup__c;
                                                }
                                                if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AttributeValueId__r.APTS_List_Price_per_cup__c != null){
                                                    orderLineItem.APTS_Z030_GSV_Consumption__c = 100 * billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AttributeValueId__r.APTS_List_Price_per_cup__c;
                                                }
                                                //<<++ Revision V34 - Balashanthi A - 27-5-2019 - JIRA : DOQBI-290 : fix for multiplying the BPO or List Price for FREE VEND and PAID for 100 Cups ENDS
                                            }
                                            // Only of UI of FreeVend Price Type Exists
                                            else if(isFVPriceTypeExists){
                                                //<<++ Revision V34 - Balashanthi A - 27-5-2019 - JIRA : DOQBI-290 : fix for multiplying the BPO or List Price for FREE VEND and PAID for 100 Cups Starts
                                                if (billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AttributeValueId__r.APTS_Base_Price_Override_per_cup_FV__c != null){
                                                    orderLineItem.Apttus_Config2__BasePriceOverride__c = 100 * billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AttributeValueId__r.APTS_Base_Price_Override_per_cup_FV__c ;
                                                }
                                                if( billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AttributeValueId__r.APTS_List_Price_per_cup_FV__c!= null){
                                                    orderLineItem.APTS_Z030_GSV_Consumption__c =  100 * billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AttributeValueId__r.APTS_List_Price_per_cup_FV__c;
                                                }
                                                //<<++ Revision V34 - Balashanthi A - 27-5-2019 - JIRA : DOQBI-290 : fix for multiplying the BPO or List Price for FREE VEND and PAID for 100 Cups ENDS
                                            }
                                            
                                        }
                                        else if(PAID.equalsIgnoreCase(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AttributeValueId__r.APTS_Type_of_Consumption__c)
                                            && PAID.equalsIgnoreCase(usageInputRec.APTS_Price_Type__c)){
                                            if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AttributeValueId__r.APTS_Base_Price_Override_per_cup__c != null)
                                                orderLineItem.Apttus_Config2__BasePriceOverride__c = 100 * billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AttributeValueId__r.APTS_Base_Price_Override_per_cup__c;
                                            if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AttributeValueId__r.APTS_List_Price_per_cup__c != null)
                                                orderLineItem.APTS_Z030_GSV_Consumption__c = 100 * billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AttributeValueId__r.APTS_List_Price_per_cup__c;
                                        }
                                        else if(FREE_VEND.equalsIgnoreCase(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AttributeValueId__r.APTS_Type_of_Consumption__c)
                                                    && FREE_VEND.equalsIgnoreCase(usageInputRec.APTS_Price_Type__c)){
                                            if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AttributeValueId__r.APTS_Base_Price_Override_per_cup_FV__c != null)
                                                orderLineItem.Apttus_Config2__BasePriceOverride__c = 100 * billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AttributeValueId__r.APTS_Base_Price_Override_per_cup_FV__c;
                                            if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AttributeValueId__r.APTS_List_Price_per_cup_FV__c != null)
                                                orderLineItem.APTS_Z030_GSV_Consumption__c = 100 * billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AttributeValueId__r.APTS_List_Price_per_cup_FV__c;
                                        }
                                    }
                                    //<<++ Revision V33 - Balashanthi A - 24-5-2019 - JIRA : DOQBI-250 : XD12 BPO is always populated irrespective of whether Paid or Free vend is used on related Asset Attribute value AND respective Usage fee
                                }
                            }
                            //Net Price -- V24
                            orderLineItem.Apttus_Config2__NetPrice__c = billingScheduleData.Apttus_Billing__FeeAmount__c;
                            // List Price
                            if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ListPrice__c != null){
                                orderLineItem.Apttus_Config2__ListPrice__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ListPrice__c;
                            }
                        }
                        else{
                            // Proration Calculation  changes Starts 
                            Decimal prorationRatio1 =0.00; 
                            Decimal prorationRatio2 = 0.00; 
                            if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__NetPrice__c != null){
                                if(billingScheduleData.Apttus_Billing__FeeAmount__c != null
                                    && billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__NetPrice__c > 0
                                    && !APTS_BIRUtils.PRODUCTORSERVICE.equalsIgnoreCase(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__LineType__c)){
                                    // CALCUATION : Proration Ratio = Billing Schedule Amount / Asset Line Net Price
                                    prorationRatio1 = (billingScheduleData.Apttus_Billing__FeeAmount__c / billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__NetPrice__c);
                                    //assetprorationRatio1Map.put(billingScheduleData.Apttus_Billing__AssetLineItemId__c, prorationRatio1); 
                                    assetprorationRatio1Map.put(billingScheduleData.Id, prorationRatio1); 
                                    // Proration Ratio 2 Calcaulation  = Selling Term * Prorpariton Ratio(Proration Ratio 1 * Asset Term)
                                    prorationRatio2 = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__SellingTerm__c * prorationRatio1;
                                    orderLineItem.APTS_AdminOrderProrationRatio__c = prorationRatio2;

                                    //system.debug('Individual Proration Ratio 1 ==>'+orderLineItem.APTS_AdminOrderProrationRatio__c );
                                    //system.debug('Individual Proration Ratio 2 ==>'+prorationRatio2);
                                }
                                //100 % discount logic
                                else if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__NetPrice__c == 0
                                            && billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ExtendedPrice__c != null
                                            && (billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BasePrice__c != null || billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_BasePriceOverride__c != null)
                                            && billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ExtendedPrice__c > 0
                                            && !APTS_BIRUtils.PRODUCTORSERVICE.equalsIgnoreCase(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__LineType__c)){
                                    Decimal billingAmount = 0.00;
                                    Decimal perDayBillingAmount = 0.00;
                                    // calcualte Per day Billing Amount
                                    if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_BasePriceOverride__c != null){//V46
                                        perDayBillingAmount = billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_BasePriceOverride__c / 30;
                                    }else if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BasePrice__c != null){
                                        perDayBillingAmount = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BasePrice__c / 30;
                                    }
                                    
                                    // calculate the netrpice for different Billing frequency
                                    if(MONTHLY.equalsIgnoreCase(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillingFrequency__c)){
                                        billingAmount = calculateNetPrice(billingScheduleData.Apttus_Billing__PeriodStartDate__c, billingScheduleData.Apttus_Billing__PeriodEndDate__c,perDayBillingAmount,30,true); 
                                    }else if(QUARTERLY.equalsIgnoreCase(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillingFrequency__c)){
                                        billingAmount = calculateNetPrice(billingScheduleData.Apttus_Billing__PeriodStartDate__c, billingScheduleData.Apttus_Billing__PeriodEndDate__c,perDayBillingAmount,90,true); 
                                    }else if(HALFYEARLY.equalsIgnoreCase(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillingFrequency__c)){
                                        billingAmount = calculateNetPrice(billingScheduleData.Apttus_Billing__PeriodStartDate__c, billingScheduleData.Apttus_Billing__PeriodEndDate__c,perDayBillingAmount,180,true); 
                                    }else if(YEARLY.equalsIgnoreCase(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillingFrequency__c)){
                                        billingAmount = calculateNetPrice(billingScheduleData.Apttus_Billing__PeriodStartDate__c, billingScheduleData.Apttus_Billing__PeriodEndDate__c,perDayBillingAmount,360,false); 
                                    }
                                   
                                    // CALCUATION : Proration Ratio = Billing Schedule Amount(calcaulted for it's respective frequency) / Asset exended Price
                                    prorationRatio1 = ( billingAmount / billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ExtendedPrice__c);
                                    assetprorationRatio1Map.put(billingScheduleData.Id, prorationRatio1); 
                                    prorationRatio2 = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__SellingTerm__c * prorationRatio1;
                                    orderLineItem.APTS_AdminOrderProrationRatio__c = prorationRatio2;
                                    //system.debug('prorationRatio2 ==>'+orderLineItem.APTS_AdminOrderProrationRatio__c);
                                    //system.debug('prorationRatio1 ==>'+prorationRatio2);
                                }
                            }
                            if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_Cumulative_Call_Out_Coverage__c != null){
                                    orderLineItem.APTS_Cumulative_Call_Out_Coverage__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_Cumulative_Call_Out_Coverage__c * prorationRatio2;
                            }
                            if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_Cumulative_Labour_coverage__c != null){
                              orderLineItem.APTS_Cumulative_Labour_coverage__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_Cumulative_Labour_coverage__c * prorationRatio2;  
                            }
                            if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_Cumulative_Spare_Parts_Coverage__c != null){
                                orderLineItem.APTS_Cumulative_Spare_Parts_Coverage__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_Cumulative_Spare_Parts_Coverage__c * prorationRatio2;
                            }
                            // Prorating List Price
                            if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ListPrice__c != null){
                                orderLineItem.Apttus_Config2__ListPrice__c = prorationRatio2 * billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ListPrice__c;
                            }
                            // Prorating Base Price or Base price Override
                            if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_BasePriceOverride__c != null
                                && billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_BasePriceOverride__c > 0){
                                // <<++ Revision V18 - Balashanthi - Defect # 5528(BSS) Billing Period Values on Billing schedules are not matching with admin order net value.
                                // <<++ Revision V21 - Balashanthi - Defect # 5875(BSS)Reverting the above code changes for Defct #5528
                                // <<++ Revision V23 - Balashanthi - Defect # 24312(Release 3.1) wrong prices and output
                                /*if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__NetUnitPrice__c != null){
                                    if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__NetUnitPrice__c > 0){
                                        orderLineItem.Apttus_Config2__BasePriceOverride__c =  prorationRatio2 * billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__NetUnitPrice__c; 
                                    }else if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__NetUnitPrice__c == 0){
                                        orderLineItem.Apttus_Config2__BasePriceOverride__c =  prorationRatio2 * billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_BasePriceOverride__c; 
                                    }
                                }*/
                                //<<++ Revision V31 - Balashanthi A -  JIRA : DOQBI-141: Adjustment amount applied twice on Admin order sent to SAP Starts
                                if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_BasePriceOverride__c != null){
                                    orderLineItem.Apttus_Config2__BasePriceOverride__c =  prorationRatio2 * billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_BasePriceOverride__c; 
                                }
                                //<<++ Revision V31 - Balashanthi A -  JIRA : DOQBI-141: Adjustment amount applied twice on Admin order sent to SAP Ends
                            }else{
                                // Prorating Base Price
                                if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BasePrice__c != null){
                                    // <<++ Revision V18 - Balashanthi - Defect # 5528 Billing Period Values on Billing schedules are not matching with admin order net value.
                                    // <<++ Revision V21 - Balashanthi - Defect # 5875 Reverting the above code changes for Defct #5528
                                    // <<-- Revision V23 - Balashanthi - Defect # 24312(Release 3.1) wrong prices and output STARTS
                                    /*if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__NetUnitPrice__c != null){
                                        if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__NetUnitPrice__c > 0){
                                            orderLineItem.Apttus_Config2__BasePrice__c =  prorationRatio2 * billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__NetUnitPrice__c; 
                                        }else if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__NetUnitPrice__c == 0){
                                            orderLineItem.Apttus_Config2__BasePrice__c =  prorationRatio2 * billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BasePrice__c; 
                                        }
                                    }*/
                                    // <<-- Revision V23 - Balashanthi - Defect # 24312(Release 3.1) wrong prices and output ENDS
                                    //<<++ Revision V31 - Balashanthi A -  JIRA : DOQBI-141: Adjustment amount applied twice on Admin order sent to SAP Starts
                                    if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BasePrice__c != null){
                                        orderLineItem.Apttus_Config2__BasePrice__c =  prorationRatio2 * billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BasePrice__c; 
                                    }
                                    //<<++ Revision V31 - Balashanthi A -  JIRA : DOQBI-141: Adjustment amount applied twice on Admin order sent to SAP Ends
                                }
                            }
                           
                            if(!APTS_BIRUtils.PRODUCTORSERVICE.equalsIgnoreCase(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__LineType__c)){
                                // Base Extended Price
                                if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BaseExtendedPrice__c != null){
                                    orderLineItem.Apttus_Config2__BaseExtendedPrice__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BaseExtendedPrice__c;
                                }
                                // Extended Price
                                if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ExtendedPrice__c != null){
                                    orderLineItem.Apttus_Config2__ExtendedPrice__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ExtendedPrice__c;
                                }
                                // NEt price 
                                orderLineItem.Apttus_Config2__NetPrice__c = billingScheduleData.Apttus_Billing__FeeAmount__c;
                            }else{
                                orderLineItem.Apttus_Config2__BaseExtendedPrice__c = 0.00;
                                orderLineItem.Apttus_Config2__ExtendedPrice__c = 0.00;
                                orderLineItem.Apttus_Config2__NetPrice__c = 0.00;
                            }
                        }// end of else

                        // finalOLIMap - This map will hold only Primary L1 lines

                        if(APTS_BIRUtils.PRODUCTORSERVICE.equalsIgnoreCase(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__LineType__c)
                            && billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Line__c){
                            // Copy Primary line for consumption + Services Primary Line
                            if(APTS_BIRUtils.CONSUMPTIONTYPEOFCONTRACT.equalsIgnoreCase(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_Type_Of_Contract__c)){
                                if(USAGETYPE.equalsIgnoreCase(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PriceType__c)
                                    && USAGEFEE.equalsIgnoreCase(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ChargeType__c)){
                                    if(!finalOLIMap.containskey(String.valueOf(billingScheduleData.Apttus_Billing__AssetLineItemId__c)+USAGETYPE)){
                                        //system.debug('===>Inside Consumption Usage 1****');
                                        finalOLIMap.put(String.valueOf(billingScheduleData.Apttus_Billing__AssetLineItemId__c)+USAGETYPE, orderLineItem);
                                    }
                                    // Copy the Usage Primary Line as Non Usage Primary Line
                                    Apttus_Config2__OrderLineItem__c copiedP1Line = copyPrimaryL1Line(orderLineItem,APTS_BIRUtils.ADMINORDERSAPORDERTYPE,NONUSAGETYPE,adminOrderCreatedInEachChunk);
                                    if(!finalOLIMap.containskey(String.valueOf(billingScheduleData.Apttus_Billing__AssetLineItemId__c)+NONUSAGETYPE)){
                                        //system.debug('===>Inside NON Consumption Usage 2****');
                                        finalOLIMap.put(String.valueOf(billingScheduleData.Apttus_Billing__AssetLineItemId__c)+NONUSAGETYPE, copiedP1Line);
                                    }
                                }else{
                                    if(!finalOLIMap.containskey(String.valueOf(billingScheduleData.Apttus_Billing__AssetLineItemId__c)+NONUSAGETYPE)){
                                        //system.debug('===>Inside Consumption Usage 3****');
                                        finalOLIMap.put(String.valueOf(billingScheduleData.Apttus_Billing__AssetLineItemId__c)+NONUSAGETYPE, orderLineItem);
                                    }
                                    Apttus_Config2__OrderLineItem__c copiedP1Line = copyPrimaryL1Line(orderLineItem,APTS_BIRUtils.CONSUMPTIONSAPORDERTYPE,USAGETYPE,adminOrderCreatedInEachChunk);
                                     //system.debug('===>Inside Consumption NON Usage 4 copiedP1Line****'+copiedP1Line);
                                    if(!finalOLIMap.containskey(String.valueOf(billingScheduleData.Apttus_Billing__AssetLineItemId__c)+USAGETYPE)){
                                        //system.debug('===>Inside Consumption NON Usage 4****');
                                        finalOLIMap.put(String.valueOf(billingScheduleData.Apttus_Billing__AssetLineItemId__c)+USAGETYPE, copiedP1Line);
                                    }
                                }
                            }else{
                                if(!finalOLIMap.containskey(String.valueOf(billingScheduleData.Apttus_Billing__AssetLineItemId__c)+NONUSAGETYPE)){
                                    //system.debug('===>Inside Final OLI Map non usage 5 ****');
                                    finalOLIMap.put(String.valueOf(billingScheduleData.Apttus_Billing__AssetLineItemId__c)+NONUSAGETYPE, orderLineItem);
                                }
                            }
                        }
                        //oldprimaryLineWithNewOptionsMap - This Map will hold all option Lines
                        else if(APTS_BIRUtils.OPTION.equalsIgnoreCase(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__LineType__c)
                            && billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Asset__c != null){
                            List<Apttus_Config2__OrderLineItem__c> tempOLIList = new List<Apttus_Config2__OrderLineItem__c>();

                            String keyForOption = String.valueOf(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Asset__c);

                            if(USAGETYPE.equalsIgnoreCase(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PriceType__c)
                                && USAGEFEE.equalsIgnoreCase(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ChargeType__c)){
                                keyForOption += billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PriceType__c;
                            }else{
                                keyForOption += NONUSAGETYPE;
                            }
                            //system.debug('==>keyForOption for OPTIONS==> '+keyForOption);

                            if(oldprimaryLineWithNewOptionsMap.containskey(keyForOption)){
                                tempOLIList = oldprimaryLineWithNewOptionsMap.get(keyForOption);
                                if (!tempOLIList.contains(orderLineItem)){
                                    //STARTS : Revision V35 - Balashanthi A - 24-6-2019 - JIRA : DOQBI-352 : fix for Usage rating batch job should not pick up
                                    if(USAGETYPE.equalsIgnoreCase(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PriceType__c)
                                        && USAGEFEE.equalsIgnoreCase(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ChargeType__c)){
                                            if(usageBsMap.containsKey(billingScheduleData.Apttus_Billing__AssetLineItemId__c)){
                                                for(Apttus_Billing__UsageInput__c usageInputRec : usageBsMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__c)){
                                                    if(usageInputRec.Apttus_Billing__UsageDate__c <= billingScheduleData.Apttus_Billing__PeriodEndDate__c
                                                        && usageInputRec.Apttus_Billing__UsageDate__c >= billingScheduleData.Apttus_Billing__PeriodStartDate__c){
                                                        //system.debug('==> ************************99999 ==>');
                                                        tempOLIList.add(orderLineItem);
                                                        oldprimaryLineWithNewOptionsMap.put(keyForOption,tempOLIList);
                                                        break;
                                                    }
                                                }
                                            }
                                            //system.debug('==> oldprimaryLineWithNewOptionsMap1 ==>'+oldprimaryLineWithNewOptionsMap); 
                                    }else{
                                        tempOLIList.add(orderLineItem);
                                        oldprimaryLineWithNewOptionsMap.put(keyForOption,tempOLIList);   
                                    }
                                    //ENDS : Revision V35 - Balashanthi A - 24-6-2019 - JIRA : DOQBI-352 : fix for Usage rating batch job should not pick up
                                }           
                            }else{
                                //STARTS : Revision V35 - Balashanthi A - 24-6-2019 - JIRA : DOQBI-352 : fix for Usage rating batch job should not pick up
                                if(USAGETYPE.equalsIgnoreCase(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PriceType__c)
                                    && USAGEFEE.equalsIgnoreCase(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ChargeType__c)){
                                    if(usageBsMap.containsKey(billingScheduleData.Apttus_Billing__AssetLineItemId__c)){
                                        for(Apttus_Billing__UsageInput__c usageInputRec : usageBsMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__c)){
                                            if(usageInputRec.Apttus_Billing__UsageDate__c <= billingScheduleData.Apttus_Billing__PeriodEndDate__c
                                                && usageInputRec.Apttus_Billing__UsageDate__c >= billingScheduleData.Apttus_Billing__PeriodStartDate__c){
                                                tempOLIList.add(orderLineItem);
                                                //system.debug('==> ************************iiiiiiiii ==>'); 
                                                oldprimaryLineWithNewOptionsMap.put(keyForOption, new List<Apttus_Config2__OrderLineItem__c>(tempOLIList));
                                                break;
                                            }
                                        }
                                    }
                                    //system.debug('==> oldprimaryLineWithNewOptionsMap2 ==>'+oldprimaryLineWithNewOptionsMap); 
                                }else{
                                    //system.debug('==> oldprimaryLineWithNewOptionsMap22222 ==>'+oldprimaryLineWithNewOptionsMap); 
                                    tempOLIList.add(orderLineItem);
                                    oldprimaryLineWithNewOptionsMap.put(keyForOption, new List<Apttus_Config2__OrderLineItem__c>(tempOLIList));
                                }
                                //ENDS : Revision V35 - Balashanthi A - 24-6-2019 - JIRA : DOQBI-352 : fix for Usage rating batch job should not pick up      
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
                                                                                Apttus_Config2__EndDate__c,
                                                                                APTS_Option_Group_Text__c,
                                                                                APTS_Cumulative_Call_Out_Coverage__c,
                                                                                APTS_Cumulative_Labour_coverage__c,
                                                                                APTS_Cumulative_Spare_Parts_Coverage__c,
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
                                                                                Apttus_Config2__StartDate__c,
                                                                                Apttus_Config2__LineNumber__c,
                                                                                Apttus_Config2__ItemSequence__c,
                                                                                Apttus_CMConfig__AgreementId__r.APTS_Fixed_Term_Type__c,
                                                                                APTS_Bill_to_Party_Ingredients_and_Payer__c,
                                                                                APTS_Bill_to_Party_Machines_Services__c,
                                                                                APTS_PayerIngredients__c,
                                                                                APTS_PayerMachinesServices__c,
                                                                                Apttus_CMConfig__AgreementId__r.APTS_Payer_Machines_Services__c,
                                                                                Apttus_CMConfig__AgreementId__r.APTS_Payer_Ingredients__c,
                                                                                Apttus_CMConfig__AgreementId__r.APTS_Bill_to_Party_Ingredients__c,
                                                                                Apttus_CMConfig__AgreementId__r.APTS_Bill_to_Party_MachServ__c
                                                                            FROM Apttus_Config2__AssetLineItem__c
                                                                            WHERE Id IN : primaryLineOLIToCreate
                                                                            AND APTS_Is_Primary_L1_Line__c = true
                                                                            LIMIT 50000]){
                    String assetKey = String.valueOf(primaryAssetLineItem.Id);
                    //DFT2C-2144 : Fix P4 - 2 machines on one order
                    primaryOrderId = null;
                    //system.debug('===>assetKey ****'+assetKey);
                    //system.debug('===>primaryAssetLineItem.APTS_Type_of_Contract__c ****'+primaryAssetLineItem.APTS_Type_of_Contract__c);
                    if(APTS_BIRUtils.CONSUMPTIONTYPEOFCONTRACT.equalsIgnoreCase(primaryAssetLineItem.APTS_Type_of_Contract__c)){ 
                        // Consumption Type with  Usage Charge Type 
                        if(!adminOrderCreatedInEachChunk.isEmpty()
                            && adminOrderCreatedInEachChunk.containsKey(String.valueOf(primaryAssetLineItem.Id)+ USAGETYPE)
                            && adminOrderCreatedInEachChunk.get(String.valueOf(primaryAssetLineItem.Id)+ USAGETYPE) != null
                            && USAGETYPE.equalsIgnoreCase(primaryAssetLineItem.Apttus_Config2__PriceType__c)
                            && USAGEFEE.equalsIgnoreCase(primaryAssetLineItem.Apttus_Config2__ChargeType__c)
                            && !createdP1LineMap.containsKey(assetKey+USAGETYPE)){
                            //system.debug('===>ISNDIE USAGE PRIMARY LINE 1 ==>');
                            primaryOrderId = adminOrderCreatedInEachChunk.get(String.valueOf(primaryAssetLineItem.Id)+ USAGETYPE); 
                            
                        }
                        // Consumption Type with  Non Usage Charge Type 
                        else if(!adminOrderCreatedInEachChunk.isEmpty()
                            && adminOrderCreatedInEachChunk.containsKey(String.valueOf(primaryAssetLineItem.Id)+ NONUSAGETYPE)
                            && adminOrderCreatedInEachChunk.get(String.valueOf(primaryAssetLineItem.Id)+ NONUSAGETYPE)!= null
                            && !createdP1LineMap.containsKey(assetKey+NONUSAGETYPE)){
                            //system.debug('===>ISNDIE USAGE PRIMARY LINE 1 ==>');
                            primaryOrderId = adminOrderCreatedInEachChunk.get(String.valueOf(primaryAssetLineItem.Id)+ NONUSAGETYPE);
                           
                        }else{
                            if(!adminOrderCreatedInEachChunk.isEmpty()
                                && adminOrderCreatedInEachChunk.containsKey(String.valueOf(primaryAssetLineItem.Id)+ USAGETYPE)
                                && adminOrderCreatedInEachChunk.get(String.valueOf(primaryAssetLineItem.Id)+ USAGETYPE)!= null
                                && !createdP1LineMap.containsKey(assetKey+USAGETYPE)){
                                //system.debug('===>ISNDIE USAGE PRIMARY LINE 3 ==>');
                                primaryOrderId = adminOrderCreatedInEachChunk.get(String.valueOf(primaryAssetLineItem.Id)+ USAGETYPE);
                            }
                        }  
                    }
                    // Non Consumption type ==> XD09    
                    else{ 
                        if(!adminOrderCreatedInEachChunk.isEmpty()
                            && adminOrderCreatedInEachChunk.containsKey(String.valueOf(primaryAssetLineItem.Id)+ NONUSAGETYPE)
                            && adminOrderCreatedInEachChunk.get(String.valueOf(primaryAssetLineItem.Id)+ NONUSAGETYPE)!= null
                            && !createdP1LineMap.containsKey(assetKey+NONUSAGETYPE)){
                            primaryOrderId = adminOrderCreatedInEachChunk.get(String.valueOf(primaryAssetLineItem.Id)+ NONUSAGETYPE);
                            //system.debug('===>ISNDIE USAGE PRIMARY LINE 55 ==>');
                        }    
                    }
                    //system.debug('==>primaryOrderId==>'+primaryOrderId);
                    if(primaryOrderId != null){
                        Apttus_Config2__OrderLineItem__c primaryOrderLineItem = new Apttus_Config2__OrderLineItem__c();
                        primaryOrderLineItem.Apttus_Config2__OrderId__c = primaryOrderId;
                        primaryOrderLineItem.Apttus_Config2__IsPrimaryLine__c = primaryAssetLineItem.Apttus_Config2__IsPrimaryLine__c;
                        primaryOrderLineItem.APTS_Item_Relevant_for_SAP__c = true;
                        //<<++Begin  V41
                        String keyForDate = String.valueOf(primaryAssetLineItem.Id);
                        if(!primaryL1DateMap.isEmpty() && primaryL1DateMap.containsKey(keyForDate+STARTDATE+WITHPRICE)){
                            primaryOrderLineItem.Apttus_Config2__StartDate__c = primaryL1DateMap.get(keyForDate+STARTDATE+WITHPRICE);
                        }else if(!primaryL1DateMap.isEmpty() && primaryL1DateMap.containsKey(keyForDate+STARTDATE+NOPRICE)){
                            //Apttus_Billing__BillingSchedule__c   optionBillingschedule = p1LineBillingScheduleStartDateMap.get(primaryAssetLineItem.Id);
                            primaryOrderLineItem.Apttus_Config2__StartDate__c = primaryL1DateMap.get(keyForDate+STARTDATE+NOPRICE);
                        }
                        
                        if(!primaryL1DateMap.isEmpty() && primaryL1DateMap.containsKey(keyForDate+ENDDATE+WITHPRICE)){
                            primaryOrderLineItem.Apttus_Config2__EndDate__c = primaryL1DateMap.get(keyForDate+ENDDATE+WITHPRICE);
                        }else if(!primaryL1DateMap.isEmpty() && primaryL1DateMap.containsKey(keyForDate+ENDDATE+NOPRICE)){
                            //Apttus_Billing__BillingSchedule__c   optionBillingschedule = p1LineBillingScheduleEndDateMap.get(primaryAssetLineItem.Id);
                            primaryOrderLineItem.Apttus_Config2__EndDate__c = primaryL1DateMap.get(keyForDate+ENDDATE+NOPRICE);
                        }//<<++End  V41
                        primaryOrderLineItem.Apttus_Config2__LineType__c = primaryAssetLineItem.Apttus_Config2__LineType__c;
                        primaryOrderLineItem.Apttus_Config2__HasOptions__c = primaryAssetLineItem.Apttus_Config2__HasOptions__c;
                        primaryOrderLineItem.Apttus_Config2__ChargeType__c = primaryAssetLineItem.Apttus_Config2__ChargeType__c;
                        primaryOrderLineItem.APTS_Option_Group_Text__c = String.isNotBlank(primaryAssetLineItem.APTS_Option_Group_Text__c) ? primaryAssetLineItem.APTS_Option_Group_Text__c : APTS_BIRUtils.EMPTY_STRING;
                        primaryOrderLineItem.APTS_Cumulative_Call_Out_Coverage__c = primaryAssetLineItem.APTS_Cumulative_Call_Out_Coverage__c;
                        primaryOrderLineItem.APTS_Cumulative_Labour_coverage__c = primaryAssetLineItem.APTS_Cumulative_Labour_coverage__c;
                        primaryOrderLineItem.APTS_Cumulative_Spare_Parts_Coverage__c = primaryAssetLineItem.APTS_Cumulative_Spare_Parts_Coverage__c;
                        primaryOrderLineItem.APTS_Type_of_Contract__c = primaryAssetLineItem.APTS_Type_of_Contract__c;
                        primaryOrderLineItem.Apttus_Config2__PriceListId__c = primaryAssetLineItem.Apttus_Config2__PriceListId__c;
                        primaryOrderLineItem.Apttus_Config2__PriceListItemId__c = primaryAssetLineItem.Apttus_Config2__PriceListItemId__c;
                        primaryOrderLineItem.Apttus_Config2__ProductId__c = primaryAssetLineItem.Apttus_Config2__ProductId__c;
                        //<<++ V30: JIRA : DOQBI-159: P1/P2 - Incident Recurring billing Order linked on superseded  Starts
                        if(primaryAssetLineItem.APTS_relatedlist_agreement__c != null){
                            primaryOrderLineItem.Apttus_CMConfig__AgreementId__c = primaryAssetLineItem.APTS_relatedlist_agreement__c;
                        }else{
                            primaryOrderLineItem.Apttus_CMConfig__AgreementId__c = primaryAssetLineItem.Apttus_CMConfig__AgreementId__c;
                        }
                        //<<++ V30: JIRA : DOQBI-159: P1/P2 - Incident Recurring billing Order linked on superseded  ENDS

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
                        primaryOrderLineItem.Apttus_Config2__ActivatedDate__c = system.today(); 
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
                        // Defect # 23766 - Payer assignment incorrect for Admin Orders in Apttus >>> V4
                        // bill to Ingredients
                        if(primaryAssetLineItem.APTS_Bill_to_Party_Ingredients_and_Payer__c != null){
                            primaryOrderLineItem.APTS_Bill_to_Party_Ingredients_and_Payer__c = primaryAssetLineItem.APTS_Bill_to_Party_Ingredients_and_Payer__c;
                        }
                        /*else if(primaryAssetLineItem.Apttus_CMConfig__AgreementId__r.APTS_Bill_to_Party_Ingredients__c != null){
                            primaryOrderLineItem.APTS_Bill_to_Party_Ingredients_and_Payer__c = primaryAssetLineItem.Apttus_CMConfig__AgreementId__r.APTS_Bill_to_Party_Ingredients__c;
                        }*/
                        // Bill to Machine/Services
                        if(primaryAssetLineItem.APTS_Bill_to_Party_Machines_Services__c != null){
                            primaryOrderLineItem.APTS_Bill_to_Party_Machines_Services__c = primaryAssetLineItem.APTS_Bill_to_Party_Machines_Services__c;
                        }
                        /*else if(primaryAssetLineItem.Apttus_CMConfig__AgreementId__r.APTS_Bill_to_Party_MachServ__c != null){
                            primaryOrderLineItem.APTS_Bill_to_Party_Machines_Services__c = primaryAssetLineItem.Apttus_CMConfig__AgreementId__r.APTS_Bill_to_Party_MachServ__c;
                        }*/
                        // Payer Ingredients
                        if(primaryAssetLineItem.APTS_PayerIngredients__c != null){
                            primaryOrderLineItem.APTS_PayerIngredients__c = primaryAssetLineItem.APTS_PayerIngredients__c;
                        }
                        /*else if(primaryAssetLineItem.Apttus_CMConfig__AgreementId__r.APTS_Payer_Ingredients__c != null){
                            primaryOrderLineItem.APTS_PayerIngredients__c = primaryAssetLineItem.Apttus_CMConfig__AgreementId__r.APTS_Payer_Ingredients__c;
                        }*/
                        // Payer MachineServices
                        if(primaryAssetLineItem.APTS_PayerMachinesServices__c != null){
                            primaryOrderLineItem.APTS_PayerMachinesServices__c = primaryAssetLineItem.APTS_PayerMachinesServices__c;
                        }
                        /*else if(primaryAssetLineItem.Apttus_CMConfig__AgreementId__r.APTS_Payer_Machines_Services__c != null){
                            primaryOrderLineItem.APTS_PayerMachinesServices__c = primaryAssetLineItem.Apttus_CMConfig__AgreementId__r.APTS_Payer_Machines_Services__c;
                        }*/
                        //Defect # 23766 - Payer assignment incorrect for Admin Orders in Apttus >>> V4
                        if(APTS_BIRUtils.CONSUMPTIONTYPEOFCONTRACT.equalsIgnoreCase(primaryAssetLineItem.APTS_Type_Of_Contract__c)){
                            // Consumption Type with Fixed Term Usage Charge Type 
                            if(USAGETYPE.equalsIgnoreCase(primaryAssetLineItem.Apttus_Config2__PriceType__c)
                                && USAGEFEE.equalsIgnoreCase(primaryAssetLineItem.Apttus_Config2__ChargeType__c)){
                                primaryOrderLineItem.APTS_SAP_OrderType__c = APTS_BIRUtils.CONSUMPTIONSAPORDERTYPE;
                            }else{
                                primaryOrderLineItem.APTS_SAP_OrderType__c = APTS_BIRUtils.ADMINORDERSAPORDERTYPE;
                            } 
                        }else{
                            // Only Machine & Services
                            // Machine & Services with Fixed Term
                            primaryOrderLineItem.APTS_SAP_OrderType__c = APTS_BIRUtils.ADMINORDERSAPORDERTYPE;
                        }
                        // Copy Primary line for consumption + Services Primary Line
                        if(APTS_BIRUtils.CONSUMPTIONTYPEOFCONTRACT.equalsIgnoreCase(primaryAssetLineItem.APTS_Type_Of_Contract__c)){
                            if(USAGETYPE.equalsIgnoreCase(primaryAssetLineItem.Apttus_Config2__PriceType__c)
                                && USAGEFEE.equalsIgnoreCase(primaryAssetLineItem.Apttus_Config2__ChargeType__c)){
                                if(!tempNewPrimaryMap.containskey(String.valueOf(primaryAssetLineItem.Id)+USAGETYPE)
                                    && !finalOLIMap.containskey(String.valueOf(primaryAssetLineItem.Id)+USAGETYPE)){
                                    //system.debug('===>Inside Consumption Usage 11****');
                                    tempNewPrimaryMap.put(String.valueOf(primaryAssetLineItem.Id)+USAGETYPE, primaryOrderLineItem);
                                }
                                // Copy the Usage Primary Line as Non Usage Primary Line
                                Apttus_Config2__OrderLineItem__c copiedP1Line = copyPrimaryL1Line(primaryOrderLineItem,APTS_BIRUtils.ADMINORDERSAPORDERTYPE,NONUSAGETYPE,adminOrderCreatedInEachChunk);
                                if(copiedP1Line != null
                                    && !tempNewPrimaryMap.containskey(String.valueOf(primaryAssetLineItem.Id)+NONUSAGETYPE)){
                                    //system.debug('===>Inside NON Consumption Usage 22****');
                                    tempNewPrimaryMap.put(String.valueOf(primaryAssetLineItem.Id)+NONUSAGETYPE, copiedP1Line);
                                }
                            }else{
                                if(!tempNewPrimaryMap.containskey(String.valueOf(primaryAssetLineItem.Id)+NONUSAGETYPE)
                                    && !finalOLIMap.containskey(String.valueOf(primaryAssetLineItem.Id)+NONUSAGETYPE)){
                                    //system.debug('===>Inside Consumption Usage 33****');
                                    tempNewPrimaryMap.put(String.valueOf(primaryAssetLineItem.Id)+NONUSAGETYPE, primaryOrderLineItem);
                                }
                                Apttus_Config2__OrderLineItem__c copiedP1Line = copyPrimaryL1Line(primaryOrderLineItem,APTS_BIRUtils.CONSUMPTIONSAPORDERTYPE,USAGETYPE,adminOrderCreatedInEachChunk);
                                //system.debug('===>Inside Consumption NON Usage 4 copiedP1Line****'+copiedP1Line);
                                if(copiedP1Line != null
                                    && !tempNewPrimaryMap.containskey(String.valueOf(primaryAssetLineItem.Id)+USAGETYPE)){
                                    //system.debug('===>Inside Consumption NON Usage 4****');
                                    tempNewPrimaryMap.put(String.valueOf(primaryAssetLineItem.Id)+USAGETYPE, copiedP1Line);
                                }
                            }
                        }
                        else{
                            if(!tempNewPrimaryMap.containskey(String.valueOf(primaryAssetLineItem.Id)+NONUSAGETYPE)){
                                //system.debug('===>Inside Consumption NON Usage 44****');
                                tempNewPrimaryMap.put(String.valueOf(primaryAssetLineItem.Id)+NONUSAGETYPE, primaryOrderLineItem);
                            }
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
                //Map<Id,Apttus_Config2__OrderLineItem__c> optionTempMap;
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
                                if(APTS_BIRUtils.CONSUMPTIONTYPEOFCONTRACT.equalsIgnoreCase(p1Line.APTS_Type_of_Contract__c)){
                                    if(USAGETYPE.equalsIgnoreCase(p1Line.Apttus_Config2__PriceType__c)
                                        && USAGEFEE.equalsIgnoreCase(p1Line.Apttus_Config2__ChargeType__c)){
                                        primaryOliToInsert.put(p1Line.Apttus_Config2__OrderId__c,p1Line);
                                        //oliBillingScheduleMap.put(p1Line.Apttus_Config2__OrderId__c,p1Line);
                                    }else{
                                        primaryOliToInsert.put(p1Line.Apttus_Config2__OrderId__c,p1Line);
                                        //oliBillingScheduleMap.put(p1Line.Apttus_Config2__OrderId__c,p1Line);
                                    }
                                }else{
                                    primaryOliToInsert.put(p1Line.Apttus_Config2__OrderId__c,p1Line);
                                    //oliBillingScheduleMap.put(p1Line.Apttus_Config2__OrderId__c,p1Line);
                                }
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
                                if(APTS_BIRUtils.CONSUMPTIONTYPEOFCONTRACT.equalsIgnoreCase(p1Line.APTS_Type_of_Contract__c)){
                                    if(USAGETYPE.equalsIgnoreCase(p1Line.Apttus_Config2__PriceType__c)
                                        && USAGEFEE.equalsIgnoreCase(p1Line.Apttus_Config2__ChargeType__c)){
                                        //oliBillingScheduleMap.put(p1Line.Apttus_Config2__OrderId__c,p1Line);
                                        primaryOliToInsert.put(p1Line.Apttus_Config2__OrderId__c,p1Line);
                                        //system.debug('==>ISNDIE NEW MAP 1==>');
                                    }else{
                                        //system.debug('==>ISNDIE NEW MAP 2==>');
                                        primaryOliToInsert.put(p1Line.Apttus_Config2__OrderId__c,p1Line);
                                        //oliBillingScheduleMap.put(p1Line.Apttus_Config2__OrderId__c,p1Line);
                                    }
                                }else{
                                    //oliBillingScheduleMap.put(p1Line.Apttus_Config2__OrderId__c,p1Line);
                                    primaryOliToInsert.put(p1Line.Apttus_Config2__OrderId__c,p1Line);
                                }
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
                    String keyForOption = String.valueOf(oOrderLineItem.Apttus_Config2__AssetLineItemId__c);
                    // Revision V9 - Code Added for Skipping option Lines in prior chunks  Execution Starts
                    if(APTS_BIRUtils.CONSUMPTIONSAPORDERTYPE.equalsIgnoreCase(oOrderLineItem.APTS_SAP_OrderType__c)){
                        keyForOption += USAGETYPE;
                    }else{
                        keyForOption += NONUSAGETYPE;
                    }
                    primaryOrderLineToUpdate.put(oOrderLineItem.Id,oOrderLineItem);
                    // <<++ V27 - Balashanthi A - Defect # 6776 The 'Start date' and 'End date' on the Bundle header (machine) should reflect the period of the related Order line items
                    //setP1LineStartAndEndDate(p1LineBillingScheduleEndDateMap,p1LineBillingScheduleStartDateMap,oOrderLineItem,primaryOrderLineToUpdate);
                    // <<-- V27 - Balashanthi A - Defect # 6776 The 'Start date' and 'End date' on the Bundle header (machine) should reflect the period of the related Order line items
                    
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
                //update createdP1LineMap.values();
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
            for(Apttus_Config2__OrderLineItem__c oli : [SELECT Id,
                                                                Name,
                                                                Apttus_Config2__LineType__c,
                                                                Apttus_Config2__OrderId__c
                                                            FROM Apttus_Config2__OrderLineItem__c
                                                            WHERE Apttus_Config2__OrderId__c IN : primaryOliToInsert.keySet()
                                                            AND (APTS_SAP_OrderType__c =: APTS_BIRUtils.CONSUMPTIONSAPORDERTYPE
                                                            OR APTS_SAP_OrderType__c =: APTS_BIRUtils.ADMINORDERSAPORDERTYPE)
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
            // Create Order Adjustment Line Item
            createOrderAdjLineItem(assetAdjMap,insertedOrderLineMap,billingSchedulesMap,assetprorationRatio1Map);
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
                                                        AND (APTS_SAP_OrderType__c =: APTS_BIRUtils.CONSUMPTIONSAPORDERTYPE
                                                        OR APTS_SAP_OrderType__c =: APTS_BIRUtils.ADMINORDERSAPORDERTYPE)
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
    /** Method Name : createOrderAdjLineItem
    * Description : Method to create admin Order's Adjustment Line item from Asset Adjustment Line Item
    **/
    public static void createOrderAdjLineItem(Map<Id,List<Apttus_Config2_AssetAdjustItem__c>> assetAdjMap,Map<Id,Apttus_Config2__OrderLineItem__c> newOldOrderLineMap, Map<Id,Apttus_Billing__BillingSchedule__c> billingSchedulesMap,Map<Id,Decimal> assetprorationRatio1Map){
        List<Apttus_Config2__OrderAdjustmentLineItem__c> orderAjstLineItemlist = new List<Apttus_Config2__OrderAdjustmentLineItem__c>();
        Map<Id, Decimal> orderLineAdjustedListPriceMap = new  Map<Id, Decimal>();
        Set<Id> originalAdminOrderLineId = new Set<Id>();
        List<Apttus_Config2__OrderLineItem__c> orderLineItemListToUpdate = new List<Apttus_Config2__OrderLineItem__c>();
        try{
            for(Apttus_Config2__OrderLineItem__c orderLineItemList : newOldOrderLineMap.values()) {
                Decimal sumOfAdjustedAmount = 0.00;
                if(orderLineItemList.Apttus_Config2__AssetLineItemId__c != null
                    && !APTS_BIRUtils.PRODUCTORSERVICE.equalsIgnoreCase(orderLineItemList.Apttus_Config2__LineType__c)
                    && !USAGEFEE.equalsIgnoreCase(orderLineItemList.Apttus_Config2__ChargeType__c)
                    && !USAGETYPE.equalsIgnoreCase(orderLineItemList.Apttus_Config2__PriceType__c)){
                    if(!assetAdjMap.isEmpty()
                        && assetAdjMap.containsKey(orderLineItemList.Apttus_Config2__AssetLineItemId__c)
                        && assetAdjMap.get(orderLineItemList.Apttus_Config2__AssetLineItemId__c)!= null){
                        List<Apttus_Config2_AssetAdjustItem__c> adjstLine = assetAdjMap.get(orderLineItemList.Apttus_Config2__AssetLineItemId__c);
                        for(Apttus_Config2_AssetAdjustItem__c assetAdjstLine:adjstLine){
                            Apttus_Config2__OrderAdjustmentLineItem__c orderAdjLine = new Apttus_Config2__OrderAdjustmentLineItem__c();
                            orderAdjLine.Apttus_Config2__LineItemId__c = orderLineItemList.Id;
                            orderAdjLine.Apttus_Config2__AdjustmentAppliesTo__c = assetAdjstLine.Apttus_Config2_AssetAdjustAppliesTo__c;
                            orderAdjLine.Apttus_Config2__AdjustmentType__c = assetAdjstLine.Apttus_Config2_AssetAdjustType__c;
                            orderAdjLine.Apttus_Config2__SubType__c = assetAdjstLine.Apttus_Config2_SubType__c;
                            orderAdjLine.Apttus_Config2__Type__c = assetAdjstLine.Apttus_Config2_Type__c;
                            orderAdjLine.Apttus_Config2__LineType__c = assetAdjstLine.Apttus_Config2_LineType__c;
                            orderAdjLine.Apttus_Config2__AdjustmentUom__c = assetAdjstLine.Apttus_Config2_Adjustment_Uom__c;
                            orderAdjLine.APTS_Agreement_Number__c = assetAdjstLine.APTS_Agreement_Number__c;
                            orderAdjLine.Apttus_Config2__BenefitQuantity__c = assetAdjstLine.Apttus_Config2_BenefitQuantity__c;
                            orderAdjLine.Apttus_Config2__Bucket__c = assetAdjstLine.Apttus_Config2_Bucket__c;
                            orderAdjLine.Apttus_Config2__CouponCode__c = assetAdjstLine.Apttus_Config2_CouponCode__c;
                            orderAdjLine.Apttus_Config2__IncentiveId__c = assetAdjstLine.Apttus_Config2_IncentiveId__c;
                            orderAdjLine.Apttus_Config2__IncentiveCode__c = assetAdjstLine.Apttus_Config2_IncentiveCode__c;
                            orderAdjLine.Apttus_Config2__PriceRuleId__c = assetAdjstLine.Apttus_Config2_PriceRuleId__c;
                            orderAdjLine.Apttus_Config2__PriceRuleEntryId__c = assetAdjstLine.Apttus_Config2_PriceRuleEntryId__c;
                            if(!DISCOUNTAMOUNT.equalsIgnoreCase(assetAdjstLine.Apttus_Config2_AssetAdjustType__c)){
                                orderAdjLine.Apttus_Config2__AdjustmentAmount__c = assetAdjstLine.Apttus_Config2_AssetAdjustAmount__c;
                            }
                            // Asset Line Item Adjustment Lines calcuation
                            // Incentive Adjustment Amount field *  proration ratio by each of the individual adjustments =  Order Adjustment Lines Incentive Adjustment Amount field . 
                            if(!assetprorationRatio1Map.isEmpty()
                                && assetprorationRatio1Map.containsKey(orderLineItemList.APTS_BillingSchedule__c)
                                && assetprorationRatio1Map.get(orderLineItemList.APTS_BillingSchedule__c) != null){
                                if(assetAdjstLine.RunningTotalAdjustedPrice__c != null){
                                    orderAdjLine.Apttus_Config2__RunningTotalAdjustedPrice__c = assetAdjstLine.RunningTotalAdjustedPrice__c * assetprorationRatio1Map.get(orderLineItemList.APTS_BillingSchedule__c);    
                                }
                                if(assetAdjstLine.Apttus_Config2_IncentiveAsetAdjustAmount__c != null){
                                    orderAdjLine.Apttus_Config2__IncentiveAdjustmentAmount__c = assetAdjstLine.Apttus_Config2_IncentiveAsetAdjustAmount__c * assetprorationRatio1Map.get(orderLineItemList.APTS_BillingSchedule__c);
                                }
                                if(DISCOUNTAMOUNT.equalsIgnoreCase(assetAdjstLine.Apttus_Config2_AssetAdjustType__c)){
                                    orderAdjLine.Apttus_Config2__AdjustmentAmount__c = assetAdjstLine.Apttus_Config2_AssetAdjustAmount__c * assetprorationRatio1Map.get(orderLineItemList.APTS_BillingSchedule__c);
                                }
                            }
                            if(assetAdjstLine.Apttus_Config2_LineNumber__c != null){
                                orderAdjLine.Apttus_Config2__LineNumber__c = assetAdjstLine.Apttus_Config2_LineNumber__c;
                            }else{
                                orderAdjLine.Apttus_Config2__LineNumber__c = 0;
                            }
                            orderAjstLineItemlist.add(orderAdjLine);
                        }
                    }    
                }
            }
            // Order Adjustment  Line Item Insert
            if(orderAjstLineItemlist.size() > 0){
                Database.SaveResult[] srList = Database.insert(orderAjstLineItemlist, false);
                APTS_BIRUtils.logError(null,srList,null,null,APTS_BIRUtils.BATCH,ORDERADJUSTMENTLINEITEMOBJECT,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,false);
            }
        }catch(Exception e){APTS_BIRUtils.logError(null,null,null,e,APTS_BIRUtils.BATCH,ORDERADJUSTMENTLINEITEMOBJECT,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,true);} 
    }
    /** Method Name : submitOrdersToSap
    * Description : Method to Submit admin Order and create IntegrationLog to SAP for Invoicing
    **/
    public static void submitOrdersToSAP(Set<Id> setOrderId){   
        List<Integration_Log__c> listIntegrationLog = new List<Integration_Log__c>();
        try{
            //system.debug('Inside Integration logs==>');
            //Create Integration Log
            for(Id oOrderId : setOrderId){
                Integration_Log__c oIntegrationLog = new Integration_Log__c();
                oIntegrationLog.Object_Id__c = oOrderId;
                oIntegrationLog.Object__c = APTS_BIRUtils.ORDEROBJECTNAME; 
                oIntegrationLog.Integration_Status__c = INT_Constants.INITIAL;
                oIntegrationLog.Order__c = oOrderId;
                listIntegrationLog.add(oIntegrationLog);
            }
            //System.debug('listIntegrationLog = ' + listIntegrationLog);
            if(!listIntegrationLog.isEmpty()){
                Database.SaveResult[] srList = Database.insert(listIntegrationLog,false);
                APTS_BIRUtils.logError(null,srList,null,null,APTS_BIRUtils.BATCH,APTS_BIRUtils.SUBMITORDER,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,false);
            }
            //System.debug('INSIDE listIntegrationLog => ' + listIntegrationLog);
        }catch(Exception e){APTS_BIRUtils.logError(null,null,null,e,APTS_BIRUtils.BATCH,APTS_BIRUtils.SUBMITORDER,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,true);} 
    }
    /** Method Name : updateBillingscheduleStatus
    * Description : Method to Update the billing sh
    **/
    public static void updateBillingscheduleStatus(List<Apttus_Billing__BillingSchedule__c> billingScheduleRecords,
                                                    Map<Id,Apttus_Config2__OrderLineItem__c> orderLineBillingScheduleMap,
                                                    Set<Id> bSwithFeeAmountZeroSet){
        List<Apttus_Billing__BillingSchedule__c> billingSchedulesToUpdate = new List<Apttus_Billing__BillingSchedule__c>();
        try{
            if(!billingScheduleRecords.isEmpty()){
                for(Apttus_Billing__BillingSchedule__c billingSchedules: billingScheduleRecords){
                    if(!orderLineBillingScheduleMap.isEmpty()
                        && orderLineBillingScheduleMap.containsKey(billingSchedules.Id)
                        && orderLineBillingScheduleMap.get(billingSchedules.Id) != null
                        && !bSwithFeeAmountZeroSet.contains(billingSchedules.Id)){//V36 - Renuka excluding BS with 0 Fee Amount
                            billingSchedules.APTS_Admin_Order_Line__c = orderLineBillingScheduleMap.get(billingSchedules.Id).Id;
                            billingSchedules.Apttus_Billing__Status__c = APTS_BIRUtils.PENDINGINVOICED;
                            billingSchedulesToUpdate.add(billingSchedules);
                        //system.debug('@@@@@@@@billingSchedules ==> '+billingSchedules); 
                    }   
                    if(bSwithFeeAmountZeroSet.contains(billingSchedules.Id)){
                        billingSchedules.Apttus_Billing__Status__c = APTS_BIRUtils.INVOICEDSTATUS;
                        billingSchedulesToUpdate.add(billingSchedules);
                    }
                }
            }
            if(!billingSchedulesToUpdate.isEmpty()){
                Database.SaveResult[] srList = Database.update(billingSchedulesToUpdate,false);
                APTS_BIRUtils.logError(null,srList,null,null,APTS_BIRUtils.BATCH,APTS_BIRUtils.BILLINGSCHEDULESUPDATE,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,false);
            }
        }catch(Exception e){APTS_BIRUtils.logError(null,null,null,e,APTS_BIRUtils.BATCH,APTS_BIRUtils.BILLINGSCHEDULESUPDATE,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,true);}   
    }
    /** Method Name : calculateNetPrice
    * Description : Method to calcualte Net price for 100 % discount lines
    **/
    public static Decimal calculateNetPrice(Date startDate, Date endDate, Decimal billingAmountPerDay,Integer noOfDays, Boolean isAddDaysLogicRequired){
        Decimal calculatedBillingAmount = 0.00;
        Integer numberOfDaysToBeBilled = 0;
        Integer noOfDaysInMonth = 0;
        Integer currentYear = 0;
        try{
            if(startDate != null && endDate != null){
                numberOfDaysToBeBilled = startDate.daysBetween(endDate);
                //system.debug('Number of days numberOfDaysToBeBilled Before Calcuation==>'+numberOfDaysToBeBilled); 
                // <<< V5 changes added for defect # 23790 - Proration of Net List prices and List Prices based on frequency incorrect (Month/Quarterly/Half Yearly/Yearly) + incorrect monthly amounts when invoicing 2 billing schedules for one asset
                if(isAddDaysLogicRequired){
                    Integer numberOfMonthsBetween = startDate.monthsBetween(endDate);                                  
                    Integer startmonth = startDate.month();
                    Integer endMonth = startmonth + numberOfMonthsBetween;
                    Integer year = startDate.Year();
                    Integer daysInMonth = date.daysInMonth(year,startmonth);
                    Date endDateOfMonth = Date.newInstance(startDate.Year(), startDate.Month(),daysInMonth);
                    Date firstDate = startDate.toStartOfMonth();
                    //system.debug('endDateOfMonth ==>'+endDateOfMonth);
                    //system.debug('startmonth ==>'+startmonth);
                    //system.debug('noOfDaysInMonth ==>'+daysInMonth);
                    //system.debug('endMonth ==>'+endMonth);
                    //system.debug('firstDate ==>'+firstDate);
                    // Added for the Defect # ==>  Proration DE at 0,9? 15k order impacted.
                    //<<++ V19 - Changes for Defect # 5622 starts
                    if(startmonth == endMonth
                        && firstDate == startDate
                        && endDateOfMonth == endDate){
                        if(daysInMonth <= noOfDays
                            && numberOfDaysToBeBilled < noOfDays){
                            Integer daysdiff = noOfDays - numberOfDaysToBeBilled;
                            //system.debug('daysdiff==before addition ==>'+daysdiff);
                            numberOfDaysToBeBilled +=  daysdiff;
                        }
                        //system.debug('Number of days numberOfDaysToBeBilled in Current Month==>'+numberOfDaysToBeBilled);      
                    }
                    //<<++ V19 - Changes for Defect # 5622 Ends
                    for(Integer i = startmonth; i < endMonth; i ++ ){
                        if(i > 12){
                            currentYear = i/12;
                        }
                        else{
                            currentYear = 0;          
                        }
                        if(currentYear != null 
                          && startDate.year() != null){
                           //system.debug('===> current Month ==>'+i);
                           Integer presentYear =   year + currentYear;
                           //system.debug('===>presentYear ==>'+presentYear);
                           noOfDaysInMonth = date.daysInMonth(presentYear,i);
                           //system.debug('Number of  days ==>'+noOfDaysInMonth); 
                            if(noOfDaysInMonth < 31){
                              Integer daysTobeAdded = 31 - noOfDaysInMonth;
                              //system.debug('daysTobeadded==>'+daysTobeadded);
                              numberOfDaysToBeBilled =  numberOfDaysToBeBilled + daysTobeadded;
                            }
                        }                                                  
                    }
                }
                // <<< V5 changes added for defect # 23790 - Proration of Net List prices and List Prices based on frequency incorrect (Month/Quarterly/Half Yearly/Yearly) + incorrect monthly amounts when invoicing 2 billing schedules for one asset
            }                                                                                 
            //system.debug('Number of days numberOfDaysToBeBilled after Calculation ==>'+numberOfDaysToBeBilled);      
            //>>> V6 changes added for defect # 23790 - Proration of Net List prices and List Prices based on frequency incorrect (Month/Quarterly/Half Yearly/Yearly) + incorrect monthly amounts when invoicing 2 billing schedules fot one asset
            if(numberOfDaysToBeBilled > 0
                && billingAmountPerDay != null){
                if(numberOfDaysToBeBilled >= noOfDays){ // monthly Billing
                    calculatedBillingAmount = billingAmountPerDay * noOfDays;
                }else{
                    calculatedBillingAmount = billingAmountPerDay * numberOfDaysToBeBilled;
                }
            }
        }catch(Exception e){APTS_BIRUtils.logError(null,null,null,e,APTS_BIRUtils.BATCH,CALCULATENETPRICE,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,true);
            return calculatedBillingAmount;
        } 
        //system.debug('calculatedBillingAmount===>'+calculatedBillingAmount);
        return calculatedBillingAmount;
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
        if(!Test.isRunningTest() && Label.APTS_RecurringBatchFilter != null && !EMPTY.equalsIgnoreCase(Label.APTS_RecurringBatchFilter)){
            query += APTS_BIRUtils.EMPTY_STRING + Label.APTS_RecurringBatchFilter;
        }
        query += APTS_BIRUtils.EMPTY_STRING+' AND Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillingFrequency__c IN (\'Hourly\', \'Daily\',\'Monthly\',\'Quarterly\',\'Half Yearly\',\'Yearly\')';
        query += APTS_BIRUtils.EMPTY_STRING+' AND Apttus_Billing__FeeAmount__c >= 0 ';
        query += APTS_BIRUtils.EMPTY_STRING+' AND Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__r.Sales_Organization__c=\''+ salesOrg + '\' ';
        
        return query;

    }

    /** Method Name : getReccurringBatchQueryStringStart
    * Description : Method to get the query string for APTS_RecurringBillingScheduleBatch
    **/
    public static string getReccurringBatchQueryStringExecute(Set<Id> billingSchedulesID){

        String query = 'SELECT Id,'+
        'Apttus_Billing__AgreementLineItemId__c,'+
        'SystemModstamp,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__r.Sales_Organization__c,'+
        'Apttus_Billing__AssetLineItemId__c,'+ 
        'Apttus_Billing__BillToAccountId__c,'+ 
        'Apttus_Billing__BillingRule__c,'+ 
        'Apttus_Billing__FeeAmount__c,'+ 
        'Apttus_Billing__IsSuperseded__c,'+ 
        'Apttus_Billing__OrderLineItemId__c,'+ 
        'Apttus_Billing__PeriodEndDate__c,'+ 
        'Apttus_Billing__PeriodStartDate__c,'+ 
        'Apttus_Billing__Quantity__c,'+ 
        'Apttus_Billing__ReadyForInvoiceDate__c,'+ 
        'Apttus_Billing__Status__c,'+ 
        'Apttus_Billing__SupersededScheduleId__c,'+ 
        'Apttus_Billing__Type__c,'+
        'Apttus_Billing__AssetLineItemId__r.Name,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PriceListId__r.CurrencyIsoCode,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_BasePriceOverride__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__LineType__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__IsOptionRollupLine__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ItemSequence__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillingRule__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillingFrequency__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Line__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementLineItemId__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementLineItemId__r.Apttus_CMConfig__BasePriceOverride__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_Item_Category__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_Asset_Line_Item_Number__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillingPreferenceId__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_Payment_Method__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PaymentTermId__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_Payment_Method__r.APTS_Payment_Method_Code__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillingPreferenceId__r.Apttus_Config2__BillingCycleStart__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillingPreferenceId__r.Apttus_Config2__BillingDayOfMonth2__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillingPreferenceId__r.APTS_Billing_Rule_Contract__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Type__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Delivery_Preference__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_Bill_to_Party_Ingredients_and_Payer__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillToAccountId__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_Bill_to_Party_Machines_Services__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BundleAssetId__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ExtendedPrice__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BaseExtendedPrice__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BasePrice__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BusinessObjectId__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__LineNumber__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ListPrice__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__NetPrice__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__NetUnitPrice__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ParentAssetId__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ParentBundleNumber__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_Physical_Asset__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Asset__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_PhysicalAssetExtId__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PricingDate__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_Option_Group_Text__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_Cumulative_Call_Out_Coverage__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_Cumulative_Labour_coverage__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_Cumulative_Spare_Parts_Coverage__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__IsPrimaryLine__c,'+ 
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__HasOptions__c,'+ 
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ChargeType__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_Type_of_Contract__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PriceListId__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PriceListItemId__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__OptionId__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PriceUom__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PrimaryLineNumber__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ProductId__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__Quantity__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_Reason_code__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_RefurbishedMachine__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__SellingFrequency__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__SellingTerm__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__SellingUom__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ShipToAccountId__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_Ship_to_Party__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_PayerIngredients__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_PayerMachinesServices__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PriceType__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__LocationId__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__EndDate__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__Frequency__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_ZX10__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_Item_Category_Adjustment__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Asset__r.Apttus_Config2__BusinessLineItemId__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ProductId__r.Name,' +
        'Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__r.Name,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__r.RecordTypeId,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__r.APTS_Payer_Machines_Services__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__r.APTS_Payer_Ingredients__c,'+ 
        'Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__r.Apttus__Primary_Contact__c, '+
        'Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__r.APTS_Bill_to_Party_Ingredients__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__r.APTS_Bill_to_Party_MachServ__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__r.APTS_Check_on_Account_Machines__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__r.APTS_Fixed_Term_Type__c,'+      
        'Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__r.APTS_CounterBased__c,'+
        'Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__r.APTS_Fix_Term_Billing_Flag__c, '+
        'Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c, '+
        'Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c, '+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AttributeValueId__r.APTS_Type_of_Consumption__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AttributeValueId__r.APTS_Base_Price_Override_per_cup__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AttributeValueId__r.APTS_Base_Price_Override_per_cup_FV__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AttributeValueId__r.APTS_List_Price_per_cup__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AttributeValueId__r.APTS_List_Price_per_cup_FV__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__r.APTS_Fixed_Term_Type__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__r.APTS_CounterBased__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__r.Apttus__Primary_Contact__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__r.APTS_Check_on_Account_Machines__c \n'+
        ' FROM '+APTS_BIRUtils.EMPTY_STRING+'Apttus_Billing__BillingSchedule__c';
        query += ' WHERE ID IN: billingSchedulesID' ;
        //system.debug('query##'+query);
        return query;

    }
    /** Method Name : copyPrimaryL1Line
    * Description : Method to copy Primary L1 line for SAP order Type "XD12" for Consumption+ Fixed Term Scenario
    **/
    public static Apttus_Config2__OrderLineItem__c copyPrimaryL1Line(Apttus_Config2__OrderLineItem__c p1Line,
                                                                    String sapOrderType,
                                                                    String indicator, 
                                                                    Map<String, Id> adminOrderCreatedInEachChunk){
        Apttus_Config2__OrderLineItem__c p1fixedLine;
        try{
            if(p1Line != null){
                if(adminOrderCreatedInEachChunk.containsKey(String.valueOf(p1Line.Apttus_Config2__AssetLineItemId__c)
                                                        + indicator)
                    && adminOrderCreatedInEachChunk.get(String.valueOf(p1Line.Apttus_Config2__AssetLineItemId__c)
                                                        + indicator) != null){
                    Id orderId = adminOrderCreatedInEachChunk.get(String.valueOf(p1Line.Apttus_Config2__AssetLineItemId__c)
                                                        + indicator);
                    //system.debug('==orderId Inside primary Id Finding==>'+orderId);
                    if(orderId != null){
                        p1fixedLine = new Apttus_Config2__OrderLineItem__c(Apttus_Config2__OrderId__c=orderId,
                        APTS_SAP_OrderType__c = sapOrderType,Apttus_Config2__ActivatedDate__c = system.today(), Apttus_Config2__ReadyForBillingDate__c = system.today(),
                        APTS_Status__c = APTS_BIRUtils.ACTIVATED,Apttus_Config2__Status__c = APTS_BIRUtils.ACTIVATED,Apttus_Config2__IsPrimaryLine__c = p1Line.Apttus_Config2__IsPrimaryLine__c,
                        APTS_Item_Relevant_for_SAP__c = true,Apttus_Config2__StartDate__c = p1Line.Apttus_Config2__StartDate__c,Apttus_Config2__EndDate__c = p1Line.Apttus_Config2__EndDate__c,
                        Apttus_Config2__LineType__c = p1Line.Apttus_Config2__LineType__c,Apttus_Config2__HasOptions__c = p1Line.Apttus_Config2__HasOptions__c,Apttus_Config2__ChargeType__c = p1Line.Apttus_Config2__ChargeType__c,
                        APTS_Option_Group_Text__c = p1Line.APTS_Option_Group_Text__c,APTS_Cumulative_Call_Out_Coverage__c = p1Line.APTS_Cumulative_Call_Out_Coverage__c,APTS_Cumulative_Labour_coverage__c = p1Line.APTS_Cumulative_Labour_coverage__c,
                        APTS_Cumulative_Spare_Parts_Coverage__c = p1Line.APTS_Cumulative_Spare_Parts_Coverage__c,APTS_Type_of_Contract__c = p1Line.APTS_Type_of_Contract__c,Apttus_Config2__PriceListId__c = p1Line.Apttus_Config2__PriceListId__c,
                        Apttus_Config2__PriceListItemId__c = p1Line.Apttus_Config2__PriceListItemId__c,Apttus_Config2__ProductId__c = p1Line.Apttus_Config2__ProductId__c,Apttus_CMConfig__AgreementId__c = p1Line.Apttus_CMConfig__AgreementId__c,
                        Apttus_Config2__Quantity__c = p1Line.Apttus_Config2__Quantity__c,Apttus_Config2__SellingUom__c = p1Line.Apttus_Config2__SellingUom__c,Apttus_Config2__AssetLineItemId__c = p1Line.Apttus_Config2__AssetLineItemId__c,
                        APTS_Payment_Method__c = p1Line.APTS_Payment_Method__c,Apttus_Config2__PaymentTermId__c = p1Line.Apttus_Config2__PaymentTermId__c,Apttus_Config2__BillingPreferenceId__c = p1Line.Apttus_Config2__BillingPreferenceId__c,
                        Apttus_Config2__BillingRule__c = p1Line.Apttus_Config2__BillingRule__c,Apttus_Config2__BillingFrequency__c = p1Line.Apttus_Config2__BillingFrequency__c,Apttus_Config2__BillToAccountId__c = p1Line.Apttus_Config2__BillToAccountId__c,
                        Apttus_Config2__SellingFrequency__c = p1Line.Apttus_Config2__SellingFrequency__c,Apttus_Config2__SellingTerm__c = p1Line.Apttus_Config2__SellingTerm__c,Apttus_Config2__OptionId__c = p1Line.Apttus_Config2__OptionId__c,
                        Apttus_Config2__PriceType__c =p1Line.Apttus_Config2__PriceType__c,Apttus_Config2__LineNumber__c = p1Line.Apttus_Config2__LineNumber__c,Apttus_Config2__ItemSequence__c = p1Line.Apttus_Config2__ItemSequence__c,CurrencyIsoCode = p1Line.CurrencyIsoCode,
                        APTS_Bill_to_Party_Ingredients_and_Payer__c = p1Line.APTS_Bill_to_Party_Ingredients_and_Payer__c,APTS_Bill_to_Party_Machines_Services__c = p1Line.APTS_Bill_to_Party_Machines_Services__c,
                        APTS_PayerIngredients__c = p1Line.APTS_PayerIngredients__c,APTS_PayerMachinesServices__c = p1Line.APTS_PayerMachinesServices__c,
                        Apttus_Config2__NetPrice__c = 0.00,Apttus_Config2__NetUnitPrice__c = 0.00,Apttus_Config2__ListPrice__c = 0.00,Apttus_Config2__BasePrice__c = 0.00);
                        if(APTS_BIRUtils.CONSUMPTIONSAPORDERTYPE.equalsIgnoreCase(p1fixedLine.APTS_SAP_OrderType__c)){
                            p1fixedLine.APTS_Item_Relevant_for_SAP__c = false;
                        }
                    }      
                }
            }
        }catch(Exception e){APTS_BIRUtils.logError(null,null,null,e,APTS_BIRUtils.BATCH,'copyPrimaryL1Line',APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,true);return null;} 
        return p1fixedLine;
    }
    
    
    /************Added below methods as part of temporary fix for the defect #23740 - Nagavi**********************/
    
     public static Map<String,Id> createAdminOrderForFixedTerm(List<Apttus_Billing__BillingSchedule__c> billingScheduleRecords,
                                                                Map<String, Id> adminOrderCreatedInEachChunk,
                                                                Map<String,String> invoiceMap){

        Set<Id> agreementId = new Set<Id>();
        Set<Id> accountId = new Set<Id>();
        Map<Id,Apttus_Billing__BillingSchedule__c> billingSchedulesMap = new  Map<Id,Apttus_Billing__BillingSchedule__c>();
        Map<Id,Account> accountDataMap = new Map<Id,Account>();
        Map<Id,APTS_Billing_Settings__c> billingSetting = new Map<Id,APTS_Billing_Settings__c>();
        Set<ID> bSwithFeeAmountZeroSet = new Set<Id>();
        try{ 
            
            //From the billing schdedules create Asset Billing Schedules Map
            for (Apttus_Billing__BillingSchedule__c billingScheduleList : billingScheduleRecords) {
                //system.debug('billingScheduleList :'+billingScheduleList );
                                
                billingSchedulesMap.put(billingScheduleList.Id,billingScheduleList);

                //<<++ V30: JIRA : DOQBI-159: P1/P2 - Incident Recurring billing Order linked on superseded  Starts
                if(billingScheduleList.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__c != null){
                    agreementId.add(billingScheduleList.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__c);
                }else{
                    agreementId.add(billingScheduleList.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c);
                }
                //<<++ V30: JIRA : DOQBI-159: P1/P2 - Incident Recurring billing Order linked on superseded  Ends
                //agreementId.add(billingScheduleList.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c);
                    
                // Account Id related to billing schedules
                if(billingScheduleList.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c != null){
                    accountId.add(billingScheduleList.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c);  
                }
                    
                          
            }// End of For
            
           
            // Retrieve Agreement PO  details
            List<APTS_Agreement_PO_Details__c> tempListPo;
            if(agreementId.size()>0){
                
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
           
            // Retrieve Division, Distribution Channel, Sales Organization from Account
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
            Map<String,Apttus_Config2__Order__c> adminOrderHeaderMap = processAdminOrderForFixedTerm(billingSchedulesMap,accountDataMap,billingSetting,adminOrderCreatedInEachChunk,
                                                                                                        invoiceMap);
            for(String createdAdminOrderKey : adminOrderHeaderMap.keySet()){
                if(adminOrderHeaderMap.containsKey(createdAdminOrderKey)
                    && adminOrderHeaderMap.get(createdAdminOrderKey) != null){
                    adminOrderCreatedInEachChunk.put(createdAdminOrderKey,adminOrderHeaderMap.get(createdAdminOrderKey).Id);

                }
            }
            //system.debug('*****After adminOrder Line item *********'+adminOrderCreatedInEachChunk);
            // Create Order Line Item 
            Map<Id,Apttus_Config2__OrderLineItem__c> newOrderLineBillingMap=processAdminOLIForFixedTerm(billingSchedulesMap,adminOrderCreatedInEachChunk);
            // Update Billing schedules
            updateBillingscheduleStatus(billingScheduleRecords,newOrderLineBillingMap,bSwithFeeAmountZeroSet); 
                                                                                                                 
        }catch(Exception e){
            APTS_BIRUtils.logError(null,null,null,e,APTS_BIRUtils.BATCH,APTS_BIRUtils.CREATEADMINORDER,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,true);
            return null;
        }
        return adminOrderCreatedInEachChunk;
    }
    
    /** Method Name : processAdminOrderForFixedTerm
    * Description : Method to create admin Order and Send the Order and Order Line Item to SAP for Invoicing
    **/
    public static Map<String,Apttus_Config2__Order__c> processAdminOrderForFixedTerm(Map<Id,Apttus_Billing__BillingSchedule__c> billingSchedulesMap,
                                                                                    Map<Id,Account> accountDataMap,
                                                                                    Map<Id,APTS_Billing_Settings__c> billingSetting,
                                                                                    Map<String,Id> adminOrderCreatedInEachChunk,
                                                                                    Map<String,String> invoiceMap){
        Map<String,Apttus_Config2__Order__c> finalOrderMapToInsert = new Map<String,Apttus_Config2__Order__c>();
        Id adminOrderId;
        
        try{
            // Admin Order Record Id
            if(Schema.SObjectType.Apttus_Config2__Order__c.getRecordTypeInfosByName().get(APTS_BIRUtils.ADMINORDER)!=null){
                adminOrderId = Schema.SObjectType.Apttus_Config2__Order__c.getRecordTypeInfosByName().get(APTS_BIRUtils.ADMINORDER).getRecordTypeId();
            }
            
            for (Apttus_Billing__BillingSchedule__c  billingScheduleData : billingSchedulesMap.values()){
                createAdminOrderHeaderForFT(billingScheduleData,accountDataMap,billingSetting,adminOrderId,finalOrderMapToInsert,adminOrderCreatedInEachChunk,invoiceMap);
            }
            //system.debug('**************finalOrderMapToInsert SIZE *****'+finalOrderMapToInsert.size());
            //system.debug('**************finalOrderMapToInsert*****'+finalOrderMapToInsert);
            if(!finalOrderMapToInsert.isEmpty()
                && finalOrderMapToInsert.values() != null){
                //system.debug('**************INSERT INSIDE *****');
                //insert finalOrderMapToInsert.values();
                Database.SaveResult[] srList = Database.insert(finalOrderMapToInsert.values(), false);
                APTS_BIRUtils.logError(null,srList,null,null,APTS_BIRUtils.BATCH,APTS_BIRUtils.ORDEROBJECTNAME,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,false);
            }
        }catch(Exception e){APTS_BIRUtils.logError(null,null,null,e,APTS_BIRUtils.BATCH,APTS_BIRUtils.ORDEROBJECTNAME,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,true);
            return null;
        }
        return finalOrderMapToInsert;  
    }
    
    public static void createAdminOrderHeaderForFT(Apttus_Billing__BillingSchedule__c billingScheduleData,
                                                                                Map<Id,Account> accountDataMap,
                                                                                Map<Id,APTS_Billing_Settings__c> billingSetting,
                                                                                Id adminOrderId,
                                                                                Map<String,Apttus_Config2__Order__c> orderMapToInsert,
                                                                                Map<String,Id> adminOrderCreatedInEachChunk,
                                                                                Map<String,String> invoiceMap){
        try{
            String tempKey = '';
            //<<++ V30: JIRA : DOQBI-159: P1/P2 - Incident Recurring billing Order linked on superseded  Starts
            if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__c != null){
                tempKey =String.valueOf(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c+':'+billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__c);
            }else{
                tempKey =String.valueOf(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c+':'+billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c);
            }
            //<<++ V30: JIRA : DOQBI-159: P1/P2 - Incident Recurring billing Order linked on superseded  ENDS
            //system.debug('==>tempKey==>'+tempKey);
            if(!orderMapToInsert.containsKey(tempKey) && !adminOrderCreatedInEachChunk.containsKey(tempKey)){
                //system.debug('==>Inside Order Creation==>');
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
                order.Apttus_Config2__ActivatedDate__c = system.today(); 
                order.Apttus_Config2__ReadyForBillingDate__c = system.today();
                order.APTS_Name__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__r.Name;
                order.Apttus_Config2__OrderStartDate__c = Date.today();
                order.Apttus_Config2__PriceListId__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PriceListId__c;
                //<<++ V30: JIRA : DOQBI-159: P1/P2 - Incident Recurring billing Order linked on superseded  Starts
                if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__c != null){
                    order.Apttus_CMConfig__AgreementId__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__c;
                }else{
                    order.Apttus_CMConfig__AgreementId__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c;
                }
                //<<++ V30: JIRA : DOQBI-159: P1/P2 - Incident Recurring billing Order linked on superseded  ENDS
                order.Apttus_Config2__SoldToAccountId__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c;
                //order.Apttus_Config2__BillToAccountId__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillToAccountId__c;
                order.Apttus_Config2__LocationId__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__LocationId__c;
                order.Apttus_Config2__PricingDate__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PricingDate__c;
                //order.APTS_Billing_Date__c = billingScheduleData.Apttus_Billing__ReadyForInvoiceDate__c;
                order.APTS_Billing_Date__c =getBillingDate(billingScheduleData);
                if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PriceListId__c != null){
                   order.CurrencyIsoCode = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PriceListId__r.CurrencyIsoCode; 
                }
                order.APTS_SAP_OrderType__c = APTS_BIRUtils.ADMINORDERSAPORDERTYPE;
                //<<++ V30: JIRA : DOQBI-159: P1/P2 - Incident Recurring billing Order linked on superseded  Starts
                if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__r.Apttus__Primary_Contact__c != null){
                    order.Apttus_Config2__PrimaryContactId__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__r.Apttus__Primary_Contact__c;
                }
                else if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__r.Apttus__Primary_Contact__c != null){
                    order.Apttus_Config2__PrimaryContactId__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__r.Apttus__Primary_Contact__c;
                }
                //<<++ V30: JIRA : DOQBI-159: P1/P2 - Incident Recurring billing Order linked on superseded  ENDS
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
                // Set Billing Preference, Payment Term and Payment Method from Asset Line item.
                //++> Changes added for V12 Starts
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
                //--> Changes added for V12 ENDS
                // Invoice list Indicator and Collective list indicator flag setting
                if(String.isNotBlank(order.APTS_InvoiceType__c)){
                    if(COLLECTIVEINVOICE.equalsIgnoreCase(order.APTS_InvoiceType__c)){
                        order.APTS_Collective_Billing_Indicator__c = true;
                        order.APTS_Invoice_List_Indicator__c = NO;
                    }else if(COLLECTIVEINVOICE_WITHSMRYPAGE.equalsIgnoreCase(order.APTS_InvoiceType__c)){
                        order.APTS_Collective_Billing_Indicator__c = true;
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
                    //V42 ++<< Starts
                    if(order.APTS_SAP_OrderType__c == APTS_BIRUtils.ADMINORDERSAPORDERTYPE){
                        order.APTS_EDI_Name_of_Orderer__c=accountDataMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c).EDI_Name_of_Orderer__c != null? accountDataMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c).EDI_Name_of_Orderer__c : null;  
                        order.APTS_EDI_Payer_Head_Text__c=accountDataMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c).EDI_Payer_Head_Text__c != null? accountDataMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c).EDI_Payer_Head_Text__c : null;  
                        order.APTS_EDI_Reference_Number__c=accountDataMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c).EDI_Reference_Number__c != null? accountDataMap.get(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c).EDI_Reference_Number__c : null;  
                    }//V42 ++ Ends>>
                }
                orderMapToInsert.put(tempKey,order);
            }
            //system.debug('==>inSIE create Admin Order Method orderMapToInsert ==>'+orderMapToInsert);
        }catch(Exception e){APTS_BIRUtils.logError(null,null,null,e,APTS_BIRUtils.BATCH,APTS_BIRUtils.ORDEROBJECTNAME,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,true);}  
    }
    
     public static Map<Id,Apttus_Config2__OrderLineItem__c> processAdminOLIForFixedTerm(Map<Id,Apttus_Billing__BillingSchedule__c> billingSchedulesMap,Map<String,Id> adminOrderCreatedInEachChunk){
        List<Apttus_Config2__OrderLineItem__c> adminOLIForFTList = new List<Apttus_Config2__OrderLineItem__c>();
        Map<Id,Apttus_Config2__OrderLineItem__c> insertedOrderLineMap = new Map<Id,Apttus_Config2__OrderLineItem__c>();
        try{
            Id orderId ;
            
            
            for (Apttus_Billing__BillingSchedule__c  billingScheduleData : billingSchedulesMap.values()){
                if(!adminOrderCreatedInEachChunk.isEmpty()){
                    string tempKey = '';
                    //<<++ V30: JIRA : DOQBI-159: P1/P2 - Incident Recurring billing Order linked on superseded  Starts
                    if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__c != null){
                        tempKey = String.valueOf(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c+':'+billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__c);  
                    }else{
                      tempKey = String.valueOf(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c+':'+billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c);  
                    }
                    //<<++ V30: JIRA : DOQBI-159: P1/P2 - Incident Recurring billing Order linked on superseded  Ends
                    orderId = adminOrderCreatedInEachChunk.get(tempKey);
                    //system.debug('===OrderId==='+orderId);
                    if( orderId != null){
                        Apttus_Config2__OrderLineItem__c orderLineItem = new Apttus_Config2__OrderLineItem__c();
                        orderLineItem.Apttus_Config2__OrderId__c = orderId;
                        orderLineItem.Apttus_Config2__ActivatedDate__c = system.today(); 
                        orderLineItem.Apttus_Config2__ReadyForBillingDate__c = system.today();
                        orderLineItem.APTS_Status__c = APTS_BIRUtils.ACTIVATED;
                        orderLineItem.Apttus_Config2__Status__c = APTS_BIRUtils.ACTIVATED;
                        //Added below line to capture the currency from the price list for defect# 22384
                        orderLineItem.CurrencyIsoCode=billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PriceListId__r.CurrencyIsoCode;
                        orderLineItem.APTS_SAP_OrderType__c = APTS_BIRUtils.ADMINORDERSAPORDERTYPE;
                        
                                               
                        orderLineItem.APTS_BillingSchedule__c = billingScheduleData.Id;
                        if(billingScheduleData.Apttus_Billing__OrderLineItemId__c != null){
                            orderLineItem.APTS_Original_Order_Line_Item__c = billingScheduleData.Apttus_Billing__OrderLineItemId__c;
                        }
                        orderLineItem.APTS_Item_Relevant_for_SAP__c = true;
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
                        //<<++ V30: JIRA : DOQBI-159: P1/P2 - Incident Recurring billing Order linked on superseded  Starts
                        if( billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__c != null){
                            orderLineItem.Apttus_CMConfig__AgreementId__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__c;
                        }else {
                            orderLineItem.Apttus_CMConfig__AgreementId__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c;
                        }
                        //<<++ V30: JIRA : DOQBI-159: P1/P2 - Incident Recurring billing Order linked on superseded  Ends
                        orderLineItem.Apttus_Config2__Quantity__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__Quantity__c;
                        orderLineItem.Apttus_Config2__SellingUom__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__SellingUom__c;
                        orderLineItem.Apttus_Config2__AssetLineItemId__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Id;
                        orderLineItem.Apttus_Config2__BasePriceOverride__c = billingScheduleData.Apttus_Billing__FeeAmount__c;
                        // Defect # 23766 - Payer assignment incorrect for Admin Orders in Apttus >>> V4
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
                        
                        if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ListPrice__c != null){
                            orderLineItem.Apttus_Config2__ListPrice__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ListPrice__c;
                        }
                                 
                            if(!APTS_BIRUtils.PRODUCTORSERVICE.equalsIgnoreCase(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__LineType__c)){
                                // Base Extended Price
                                if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BaseExtendedPrice__c != null){
                                    orderLineItem.Apttus_Config2__BaseExtendedPrice__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BaseExtendedPrice__c;
                                }
                                // Extended Price
                                if(billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ExtendedPrice__c != null){
                                    orderLineItem.Apttus_Config2__ExtendedPrice__c = billingScheduleData.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ExtendedPrice__c;
                                }
                                // NEt price
                                orderLineItem.Apttus_Config2__NetPrice__c = billingScheduleData.Apttus_Billing__FeeAmount__c;
                            }else{
                                orderLineItem.Apttus_Config2__BaseExtendedPrice__c = 0.00;
                                orderLineItem.Apttus_Config2__ExtendedPrice__c = 0.00;
                                orderLineItem.Apttus_Config2__NetPrice__c = 0.00;
                            }
                        adminOLIForFTList.add(orderLineItem);
                    }// End of final if
                } // First if 
            }// End of for
            
            if(!adminOLIForFTList.isEmpty()){
                Database.SaveResult[] srList = Database.insert(adminOLIForFTList, false);
                APTS_BIRUtils.logError(null,srList,null,null,APTS_BIRUtils.BATCH,APTS_BIRUtils.ORDERLINEITEMOBJECTNAME,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,false);
            }
            
            for(Apttus_Config2__OrderLineItem__c oli: adminOLIForFTList){
                if(oli.APTS_BillingSchedule__c != null){
                    insertedOrderLineMap.put(oli.APTS_BillingSchedule__c,oli);
                } 
            }
            
        }catch(Exception e){APTS_BIRUtils.logError(null,null,null,e,APTS_BIRUtils.BATCH,APTS_BIRUtils.ORDERLINEITEMOBJECTNAME,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,true);
            insertedOrderLineMap = null;
        }
         return insertedOrderLineMap;
    }
    
    /** Method Name : getFTDummyProducts
    * Description : Method to get Fixed Term DummyProducts
    **/
    public static Set<String> getFTDummyProducts(){
        List<APTS_Fixed_Term_Dummy_Product__c> ftDummyProducts = APTS_Fixed_Term_Dummy_Product__c.getall().values();
        Set<String> ftDummyProductsSet = new Set<String>();      
        for(APTS_Fixed_Term_Dummy_Product__c ftd : ftDummyProducts ){
            ftDummyProductsSet.add((ftd.name).toUpperCase());
        }
        return ftDummyProductsSet;
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
                //<<++ Added on Version V17 Starts - Setting the Payer and Bill to from AGreement.                       // Payer account population 
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
                    // >> V15 - changes for BSS defect # 5361 starts
                    // Payer account population 
                    /*if(soldToAccount.Related_Payer_Machines_Services__c != null){
                        order.APTS_Payer__c = soldToAccount.Related_Payer_Machines_Services__c;
                    }*/
                    // >>++ V16 - changes for BSS defect # 5361 starts
                    order.Apttus_Config2__BillToAccountId__c = soldToAccount.Related_Bill_to_Machines_Services__c;
                    // >>-- V15 - changes for BSS defect # 5361 Ends
                }else if(soldToAccount.Related_Bill_to_Machines_Services__c == null){
                    // Populate from Sold to Account
                    // Billing Preference, Invoice Delivery Preference and Invoice Type
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
                //<<++ Added on Version V17 Starts - Setting the Payer from Sold To Related Payer Ingredients.
                // Payer account population 
                if(soldToAccount.Related_Payer_Machines_Services__c != null){
                    order.APTS_Payer__c = soldToAccount.Related_Payer_Machines_Services__c;
                }
                //<<++ Added on Version V17 Starts - Setting the Payer from Sold To Related Payer Ingredients.
            }
            //v39++<<
            if((APTS_BIRUtils.INVOICELISTWITHSUMMARY.equalsIgnoreCase(order.APTS_InvoiceType__c) || COLLECTIVEINVOICE_WITHSMRYPAGE.equalsIgnoreCase(order.APTS_InvoiceType__c)) && order.APTS_InvoiceDeliveryPreference__c != null
                && !invoiceMap.isEmpty() && invoiceMap.containsKey(order.APTS_InvoiceDeliveryPreference__c)){
                order.APTS_InvoiceDeliveryPreference__c= invoiceMap.get(order.APTS_InvoiceDeliveryPreference__c);  
            }
            //v39++>>
        }catch(Exception e){APTS_BIRUtils.logError(null,null,null,e,APTS_BIRUtils.BATCH,APTS_BIRUtils.ORDEROBJECTNAME,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,true);}
    }

    //v25 start
    public static void callRecurringBatchIfReqd(String salesOrg){
        //system.debug('salesOrg callRecurringBatchIfReqd ===>'+salesOrg);
        if(salesOrg != ''){
            //system.debug('INSIDE BATCH Execution callRecurringBatchIfReqd ===>'+salesOrg);
            
            APTS_RecurringBillingScheduleBatch obj = new APTS_RecurringBillingScheduleBatch(salesOrg);
            Database.executeBatch(obj,100);
        }
        else{
            //system.debug('INSIDE ELSE callRecurringBatchIfReqd ===>'+salesOrg);
            for(APTS_Recurring_Batch_Countries__c rbcRecord : APTS_Recurring_Batch_Countries__c.getAll().values()){
            //<<++ Revision V32 - Monika - JIRA : DOQBI-164 : exclude XD12 & permanently exclude Sales orgs         
                    if(!rbcRecord.APTS_Ignore_Billing_Run__c){
                        rbcRecord.APTS_Processed__c = false;
                }
            }
            update APTS_Recurring_Batch_Countries__c.getAll().values();
            
            //V43 Calling CreditBatch from here.Get all the country values from custom setting and pass the one with Sequence=1
            String salesOrgCredit = '';
            Map<Integer, APTS_Credit_Batch_Countries__c> countrySeqMap = new Map<Integer, APTS_Credit_Batch_Countries__c>();
            for(APTS_Credit_Batch_Countries__c bcRec : APTS_Credit_Batch_Countries__c.getAll().values()){
                countrySeqMap.put(Integer.valueOf(bcRec.APTS_Sequence__c), bcRec);
            }
            APTS_Credit_Batch_Countries__c rbcRec;
            for(Integer i=1 ; i<=countrySeqMap.size() ; i++){  
                rbcRec = countrySeqMap.get(i);
                if(!rbcRec.APTS_Processed__c && rbcRec.APTS_Sequence__c == 1){
                    salesOrgCredit = rbcRec.APTS_Sales_Org__c;
                    break;
                }
            }
            APTS_CreditBillingBatch obj = new APTS_CreditBillingBatch(salesOrgCredit);
            Database.executeBatch(obj,100);
        }
    }
    //v25 end
}