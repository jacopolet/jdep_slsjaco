/*************************************************************
@Name: APTS_BIRUtils
@Author: Balashanthi A
@CreateDate: 12-03-2018
@Description: BIR utils
@UsedBy: APTS_PricingCallBack.cls
@Test Classes : APTS_VolumeObligationLineItemsTest
                APTS_BIRUtilsTest
                APTS_ConsumptionCounterReadingDataTest
******************************************************************/
//v101 24-Aug-2018 Aarthi Pitchai: Added logic to set the Payment Method Code at Order Header based on associated Payment Method - Defect #18352.
//v102 06-Sep-2018 Ankit Joshi : Added code to populate Price Type on Counter Reading Data from Asset Line Item's Attribute's Type Of Consumption field
//v103 27-Sep-2018 Ankit Joshi : Added code to populate quantity after conversions based on UoM
//v104 16-Oct-2018 Beulah Thomas : Updated condition to check 'Remove billing block' indicator if an order is activated and if SAP Order type contains XA, XC, XD or XL
//v105 26-Oct-2018 Raul Mora(RM) : Adjust logic to made the conversion depending on the selling UOM. Related to defect 20308.
//v106 29-Oct-2018 Ankit Joshi : Populate billing date on Order header based on Billing Preference
//v107 07-Nov-2018 Balashanthi : Restrict the submission of Fixed Term Order created during Cart Finalization to SAP
//v108 07-Nov-2018 Balashanthi : Modified assignBillingDateToOrder() method and also it's invoking point
//v109 11-Nov-2018 Beulah Thomas : Updated to query order for SAP Order Type. If SAP Order Type is XC01, XD01, XD09, XD12 then volume obligation line shouldnt be created.
//v110 22-Nov-2018 Beulah Thomas : Updated to check subcategory combination for OLI.
//v111 04-Dec-2018 Beulah Thomas : Updated to check subcategory and subsubcategory combination during volume obligation line item creation from External OLI
//v112 04-Dec-2018 Ankit Joshi : Populate Physical asset on corresponding counter reading data on Order Activation
//v113 10-Dec-2018 Ankit Joshi : CR 2159/FD 3741 - Create new counters for new order line items on same agreement
//v114 07-JAN-2019 Renuka : Defect 23202 Setting Billing date for Digital order
//v115 16-JAN-2019 Venky Muppalaneni : FD 2168 (Order Header is stamped with the Agreement and the Flag APTS_Check_on_Account_Ingredients__c is set then the fields (Payment method,Payment term,   Billing Preference ) will be taken from Account   For Machine ans Standard Order )
//v116 01-FEB-2019 Balashanthi A : Defect # 24009 - Billing frequency not setting correctly on agreement line Item. Remove billing preference cascading from billing setting prefrence will to PLI as behaviour of OOB.
//v117 02-Feb-2019 Amit Singh :  Defect # 4197 : In case check box "Use BT/Payer Ingredients from Account" on Agreement is checked take Billing preference, Payment term and Payment method from Bill-to account instead of from Sold-to account
//v118 03-FEB-2019 Balashanthi A : Defect #  - In case check box "Use BT/Payer Ingredients from Account" on Agreement , if payment method is blank Leave it as blank, not populate Billing setting
//v119 27-FEB-2019 Nagavi Babu : Defect #5383 - When check box on Agreement 'Use BT/Payer from Account' is checked AND 'Invoice delivery preference' on the Bill-to's Billing preference = 'Invoice list - with summary page' THEN P005-P008 AND 'Invoice list indicator' = 'YES' should be applied to Order
//v200 27-FEB-2019 Balashanthi A : Defect # 5429 : billing date incorrect - triangular invoicing
//V201 27-FEB-2019 Balashanthi A : triangular invoicing - billing preference, payment term and payment method are not populated on triangular orders as per standard logic
//v202 22-Mar-2019 Ankit Joshi : Defect BSS 6074 To prevent sending Conversion Admin orders to SAP for invoicing
//v203 26-Mar-2019 Balashanthi A : Defect BSS 6171 - In case there is no Agreement on a Standard order header (here: Digital order) then the Billing preference, Payment term and Payment method need to come from the related Bill-to account
//v204 17-May-2019 DOQBI-10 - For SAPOrder Type = 'XA04', we need to restrict the creation of Integration Log during Order Activation
//v205 Defect 24345/CR 2303 - Update Billing Schedules when 'Sold To' or 'Bill To' values are modified in Asset Line Item
//v206 27-Aug-2019 Renuka: DFT2C-1017 Consider the Use BT flags for Conversion Orders.
//v207 09-Sept-2019 Mahesh Chilaka : DFT2C-856 - Assign new agreement on contract changed.
//v208 26-Sept-2019 Renuka : QTCFLEX1-1307 - Fix for BillToParty fields should consider BT checkbox in Agreement for RSO,Triangular&Digital Orders 
//v210 29-Oct-2019 Amit: DFT2C-1820 - Create counter with correct field value and status on clone.
//v211 12-Nov-2019 Renuka: QTCFLEX1-1583 - Enable BTP checkbox logic for Standard and Machine order subtypes.
//v212 23-Jul-2020 Renuka: DQ-3395 - Added logic for New InvoiceType - Collective+InvoiceList
//V213 30-Jul-2020 Aarthi : DQ-3153 - Added method to deactivate the existing counters in case of refubhised Machines
//v214 29-Dec-2020 Renuka: DQ-4634 - removing v107 - allowing fixed term debit memos to create integration logs
//v215 18-Feb-2021 Manisha: DQ-3967 - Commenting and updating the query to avoid the error.
//v214 23-Feb-2021 Renuka: DQ-5503 - Adding logic for Period Start Date.
public with sharing class APTS_BIRUtils {

    private static final String INVOICELISTINDICATOR = System.Label.APTS_InvoicelistIndicator;
    private static final String COLLECTIVEINVOICE = 'Collective Invoice';
    public static final String COLLECTIVEINVOICE_WITHSMRYPAGE = 'Collective Invoice – With Summary Page';//v212
    public static final String STANDARD_ORDER = System.Label.APTS_Standard_Order;
    public static final String MACHINE_ORDER = System.Label.APTS_Machine_Order;
    private static final String YES = 'YE';
    private static final String PREPAIDFLAG_YES = 'Yes';
    private static final String NO = 'NO';
    private static final String AGREEMENT = 'Agreement';
    private static final String ORDER = 'Order';
    private static final String MACHINES = 'Machines';
    private static final String SERVICES = 'Services';
    private static final String SERVICE = 'Service';
    private static final String INGREDIENTS = 'Ingredients';
    public static final String STREAM = 'BIR';
    private static final String LINENUMBER = 'Line Number :';
    private static final String COLON = ' :';
    private static final String AGREEMNTVOLOBLIGATIONLINE = 'APTS_Agreement_Volume_Obligation_Line__c';
    private static final String LINEITEMOBJECTNAME = 'Apttus_Config2__LineItem__c';
    private static final String BILLINGSETTINGOBJECTNAME = 'APTS_Billing_Settings__c';
    private static final String CREDITMEMOOBJECTNAME = 'Apttus_Billing__CreditMemo__c';
    public static final String ORDERLINEITEMOBJECTNAME = 'Apttus_Config2__OrderLineItem__c';
    public static final String ORDERADJUSTMENTLINEITEMOBJECT = 'Apttus_Config2__OrderAdjustmentLineItem__c';
    public static final String AGREEMENTOBJECT = 'Apttus__APTS_Agreement__c';
    public static final String AGREEMENTVOLOBLIGATIONOBJECT = 'APTS_AgreementVolumeObligation__c';
    public static final String BATCH = 'Batch';
    public static final String EMPTY_STRING = '';
    public static final String ORDEROBJECTNAME = 'Apttus_Config2__Order__c';
    public static final String APEX = 'Apex';
    public static final String VISUALFORCE = 'Visualforce';
    public static final String TRIGGERVALUE = 'Trigger';
    public static final String INCENTIVEOBJECT = 'Apttus_Config2__Incentive__c';
    public static final String PREPAREAGRMTBILLINSETTINGMETHOD = 'prepareAgreementBillingSettingMap() Method';
    public static final String STANDALONE = 'Standalone';
    public static final String ACTIVATED = 'Activated';
    public static final String STANDARDORDER = 'Standard Order';
    public static final String ONETIME = 'One Time';
    public static final String REMOVEBILLINGBLOCKMETHOD = 'removeBillingBlockForStandardOrders() Method';
    public static final String ADMINORDER = 'Admin Order';
    public static final String FIXEDTERMFLAG = 'z';
    public static final String DEBITSAPORDERTYPE = 'XD01';
    public static final String CREDITSAPORDERTYPE = 'XC01';
    public static final String DIGITALSAPORDERTYPE= 'XA01';
    public static final String DIGITALORDER_PAYMENTTERM='SAP_ZOLP';
    public static final String STATUS = 'Pending';
    public static final String ORDERSUBTYPE = 'Billing Schedule';
    public static final String RECURRING = 'Recurring';
    public static final String PRODUCTORSERVICE = 'Product/Service';
    public static final String OPTION = 'Option';  
    public static final String MACHINE = 'Machine';  
    public static final String NEWMACHINE = 'N';
    public static final String USEDMACHINE = 'U';   
    public static final String CREATEADMINORDER ='createAdminOrder() Method';
    public static final String CREATEADMINORDERFINISH ='RecurringBillingBatch finish() Method';
    public static final String CREATEADMINORDEREXECUTE ='RecurringBillingBatch execute() Method';
    public static final String ACTIVATEANDSUBMITORDER = 'activateAndSubmitOrder() Method';
    public static final String SUBMITORDER = 'SubmitOrder() Method';
    public static final String FIXEDTERMINDICATOR = 'Z';
    public static final String UPSERTEXCEPTION = 'UpsertFailure';
    public static final String INSERTEXCEPTION = 'InsertOrUpdateFailure';
    public static final String DELETEEXCEPTION = 'DeleteFailure';
    public static final String PENDINGBILLINGSTATUS = 'Pending Invoiced'; 
    public static final String BILLINGSCHEDULESUPDATE = 'updateBillingscheduleStatus() Method';
    public static final String INVOICINGSTATUS = 'Sent For Invoicing';
    public static final String COMPLETED = 'Completed';
    public static final String BILLINGSCHEDULEOBJECTNAME = 'Apttus_Billing__BillingSchedule__c';
    public static final String SAPINVOICELINEITEMFAILURE = 'SAP InvoiceLineItem Retrieval Failure';
    public static final String LIKINVOICEMETHOD = 'linkInvoiceToOrder() Method';
    public static final String INVOICEDSTATUS = 'Invoiced';
    public static final String ADMINORDERSAPORDERTYPE = 'XD09';
    public static final String CONSUMPTIONSAPORDERTYPE = 'XD12';
    public static final String READYFORBILLINGDATE = 'Bill on Ready for Billing Date';
    public static final String INVOICELISTWITHSUMMARY = 'Invoice List – With Summary Page';
    public static final string INVOICELISTWITHOUTSUMMARY = 'Invoice List – Without Summary Page';
    public static final String CONSUMPTIONTYPEOFCONTRACT = 'Consumption';
    public static final String APPROVED = 'Approved';
    public static final String EXTERNALORDERSUMMARYOBJECT = 'Apttus_Config2__ExternalOrderSummary__c';
    public static final String EXTERNALORDERSUMMARYLINEITEMOBJECT = 'Apttus_Config2__ExternalOrderSummaryItem__c';
    public static final String SELLOUTDATA = 'APTS_Sellout_Data__c';
    public static final String SELLOUTDATAITEM = 'APTS_SelloutDataItem__c';
    public static final String READYFORINCENTIVE = 'Ready for Incentive Processing';
    public static final String INREVIEW = 'In Review';
    public static final String JDEINVOICE = 'JDE Invoice';
    public static final String DIRECT = 'Direct';
    public static final String AUTOMATICVERIFICATION = 'Passed Automatic Verification';
    public static final String PENDINGINVOICED = 'Pending Invoiced'; 
    public static final String PENDINGBILLING = 'Pending Billing';
    public static final String CREDITMEMO = 'Credit Memo'; 
    public static final String DEBITMEMO = 'Debit Memo'; 
    public static final String READYFORBILLING = 'Ready for Billing Date';
    public static final String INSTALLATION = 'Installation';  
    public static final String CONVERSIONORDER = 'Conversion Order';
    public static string SELLOUT = 'Sellout Data';//v111 
    //v101++<<
    private static final String ORDERTYPE_ROUTESALES = 'Route Sales Order';
    private static final String ORDERTYPE_OPERATING = 'Operating Order';
    //v101++>>
    
    //v1.1 starts here
    private static String pending = System.Label.APTS_Pending;
    private static String partially_fulfilled = System.Label.APTS_Partially_Fulfilled;
    private static String fulfilled = System.Label.APTS_Fulfilled; 
    //private static String activated = System.Label.APTS_Activated;
    //v1.1 ends here
    
    
    //v102 starts here
    private static final String FREE = 'Free';
    private static final String FREE_VEND = 'Free Vend';
    //v102 ends here
    
    private static final String DRINKS = 'SAP_DRKS';
    private static final String LITER = 'SAP_LTR';
    private static final String KILOGRAMS = 'SAP_KGM';
    private static final String STOCK_COUNT = 'Stock Count';
    
    //v104 starts here
    private static final String XA = 'XA';
    private static final String XC = 'XC';
    private static final String XD = 'XD';
    private static final String XL = 'XL';
    //v104 ends here
    
    private static final String BILL_IN_ARREARS = 'Bill in Arrears';
    private static final String CONSUMPTION_MODEL = 'Consumption Model';
    
    //v106 starts here
    
    private static final String BILLING_DAY_OF_MONTH = 'Billing Day of Month';
    private static final String END_OF_MONTH = 'End of Month';
    
    //v112 starts here
    private static final String S40 = 'S40';
    //v112 ends here
    
    //v113 starts here
    private static final String CREATED = 'Created';
    //v113 ends here
    private static final String LINESTATUSNEW = 'New';
    
    //v204
    private static final String STOCKSAPORDERTYPE = 'XA04';
    
    //v205
    private static final String PENDING_BILLING = 'Pending Billing';
    private static final String EXTERNAL_MOVEMENT_WITH_CONTRACT_CHANGE = 'External Movement With Contract Change';
    
    //v210
    public static final string ACTIVE_COUNTER = 'Active';
    
    public static final string PERIOD_START_DATE = 'Period Start Date';
    /* Method to associate Billing Setting record to Agreement Based on Bill To(Machine/Services or Ingredients)
    * createBillingSetting() will be invoked from APTS_AgreementTriggerHandler after Update event
    */
    public static void createBillingSetting( Map<Id, Apttus__APTS_Agreement__c> mapAgreements,
                                                Map<Id, Apttus__APTS_Agreement__c> mapOldAgreements,Boolean isEventAfterUpdate) {
        // Variable Declaration
        Map<Id,Id> newAccountIdMap = new Map<Id,Id>();
        Map<Id,Id> oldBillToAgreementMap = new Map<Id,Id>();
        List<APTS_Billing_Settings__c> billingSettingListToInsert = new List<APTS_Billing_Settings__c>();
        List<APTS_Billing_Settings__c> billingSettingListToDelete = new List<APTS_Billing_Settings__c>();
        Map<Id,Account> accountBillingSettingMap = new Map<Id,Account>();
        Savepoint savePnt = Database.setSavepoint();
        Database.DeleteResult[] drList;
        Database.SaveResult[] insertedList;
        Map<String, APTS_AgreementBillingManual__c> billingSettingMap = APTS_AgreementBillingManual__c.getAll();
        Boolean muteBillingSetting  = false;
        if(billingSettingMap.containsKey('Mute Billing') && billingSettingMap.get('Mute Billing') != null){
            muteBillingSetting = billingSettingMap.get('Mute Billing').fullLogicDisabledFlag__c;
        }
        // Logic Starts
        try{
        
        if(muteBillingSetting == false){ 
            if(!mapOldAgreements.isEmpty() && (!mapAgreements.isEmpty())){
                for(Apttus__APTS_Agreement__c agreementBillTo : mapAgreements.values()){
                    // SCENARIO 1: Change in Bill-To Ingredients from the old Fields 
                    if(agreementBillTo.APTS_Bill_to_Party_Ingredients__c != null){
                            if(mapOldAgreements.get(agreementBillTo.Id).APTS_Bill_to_Party_Ingredients__c 
                                                != agreementBillTo.APTS_Bill_to_Party_Ingredients__c){
                                newAccountIdMap.put(agreementBillTo.APTS_Bill_to_Party_Ingredients__c,agreementBillTo.Id);
                                oldBillToAgreementMap.put(mapOldAgreements.get(agreementBillTo.Id).APTS_Bill_to_Party_Ingredients__c,mapOldAgreements.get(agreementBillTo.Id).Id);  
                            }
                    }else{
                    // SCENARIO 2: Removing  Ingredients Bill-To Account from old value     
                        if(mapOldAgreements.get(agreementBillTo.Id).APTS_Bill_to_Party_Ingredients__c != null){
                            oldBillToAgreementMap.put(mapOldAgreements.get(agreementBillTo.Id).APTS_Bill_to_Party_Ingredients__c,mapOldAgreements.get(agreementBillTo.Id).Id);
                        }
                    }
                    // SCENARIO 3: Change in Bill-To Machines or services from the old Fields 
                    if(agreementBillTo.APTS_Bill_to_Party_MachServ__c != null){
                        if(mapOldAgreements.get(agreementBillTo.Id).APTS_Bill_to_Party_MachServ__c 
                                                    != agreementBillTo.APTS_Bill_to_Party_MachServ__c){
                            newAccountIdMap.put(agreementBillTo.APTS_Bill_to_Party_MachServ__c,agreementBillTo.Id);
                            oldBillToAgreementMap.put(mapOldAgreements.get(agreementBillTo.Id).APTS_Bill_to_Party_MachServ__c,mapOldAgreements.get(agreementBillTo.Id).Id);
                        }
                    }else{
                        // SCENARIO 4: Removing Machines/Services Bill-To Account from Old value    
                        if(mapOldAgreements.get(agreementBillTo.Id).APTS_Bill_to_Party_MachServ__c != null){
                            oldBillToAgreementMap.put(mapOldAgreements.get(agreementBillTo.Id).APTS_Bill_to_Party_MachServ__c,mapOldAgreements.get(agreementBillTo.Id).Id);
                        }
                    }
                }
            }else{
                // Below logic will get executed on after Insert Event
                // SCENRIO 4: For Account Hierachy During Agreement Creation, Bill-To(Ingredients/Machines) will get populated and for the same to create Billing setting Record
                if(!mapAgreements.isEmpty()){
                    for(Apttus__APTS_Agreement__c agreementBillTo : mapAgreements.values()){
                        if(String.isNotBlank(agreementBillTo.Apttus__FF_Agreement_Number__c)){
                            Integer versionIndex = agreementBillTo.Apttus__FF_Agreement_Number__c.indexOf('.');
                            String version = agreementBillTo.Apttus__FF_Agreement_Number__c.subString(versionIndex+1,agreementBillTo.Apttus__FF_Agreement_Number__c.length());
                            if(agreementBillTo.APTS_Bill_to_Party_MachServ__c != null && version == '0'){
                                newAccountIdMap.put(agreementBillTo.APTS_Bill_to_Party_MachServ__c,agreementBillTo.Id);
                            }
                            if(agreementBillTo.APTS_Bill_to_Party_Ingredients__c != null && version == '0'){
                                newAccountIdMap.put(agreementBillTo.APTS_Bill_to_Party_Ingredients__c,agreementBillTo.Id);
                            }  
                        }
                    }
                }
            }       
            // Logic to insert new  Bill-To Billing Setting Record 
            if(!newAccountIdMap.isEmpty()){
                for (Account accountBillingData : [SELECT Id, 
                                                    Apttus_Config2__BillingPreferenceId__c,
                                                    Apttus_Config2__PaymentTermId__c,
                                                    APTS_Payment_Method__c,
                                                    Sales_Organization__c
                                                FROM Account
                                                WHERE Id IN:newAccountIdMap.keyset()
                                                ]) {
                    accountBillingSettingMap.put(accountBillingData.Id, accountBillingData);
                }
            } 
            if(accountBillingSettingMap.size()>0){
                for(Apttus__APTS_Agreement__c agreement : mapAgreements.values()){
                    APTS_Billing_Settings__c billSettingRecord = new APTS_Billing_Settings__c();
                    // New record Creation for Ingredeints
                    if(accountBillingSettingMap.containsKey(agreement.APTS_Bill_to_Party_Ingredients__c) 
                        && accountBillingSettingMap.get(agreement.APTS_Bill_to_Party_Ingredients__c) != null){
                        if(isEventAfterUpdate){
                            if(mapOldAgreements.get(agreement.Id).APTS_Bill_to_Party_Ingredients__c != agreement.APTS_Bill_to_Party_Ingredients__c){
                                billSettingRecord = setBillingSettingData(agreement,accountBillingSettingMap.get(agreement.APTS_Bill_to_Party_Ingredients__c),INGREDIENTS);
                            }
                        }else{
                            billSettingRecord = setBillingSettingData(agreement,accountBillingSettingMap.get(agreement.APTS_Bill_to_Party_Ingredients__c),INGREDIENTS);
                        }
                        if(!billingSettingListToInsert.contains(billSettingRecord)){
                            billingSettingListToInsert.add(billSettingRecord);
                        }
                    }
                    // New record Creation for Machines/Services
                    if(accountBillingSettingMap.containsKey(agreement.APTS_Bill_to_Party_MachServ__c) 
                        && accountBillingSettingMap.get(agreement.APTS_Bill_to_Party_MachServ__c)!= null){
                        if(isEventAfterUpdate){
                            if(mapOldAgreements.get(agreement.Id).APTS_Bill_to_Party_MachServ__c != agreement.APTS_Bill_to_Party_MachServ__c){
                                billSettingRecord = setBillingSettingData(agreement,accountBillingSettingMap.get(agreement.APTS_Bill_to_Party_MachServ__c),MACHINE);
                            }
                        }else{
                            billSettingRecord = setBillingSettingData(agreement,accountBillingSettingMap.get(agreement.APTS_Bill_to_Party_MachServ__c),MACHINE);
                        }
                        if(!billingSettingListToInsert.contains(billSettingRecord)){
                            billingSettingListToInsert.add(billSettingRecord);
                        }
                    }
                }
            }
            
            if(billingSettingListToInsert.size()>0){
                insertedList = Database.insert(billingSettingListToInsert,false);
                logError(null,insertedList,null,null,TRIGGERVALUE,BILLINGSETTINGOBJECTNAME,EMPTY_STRING,false,false,EMPTY_STRING,false);
            }
            // Logic to Delete associated old Bill-To Billing Setting Record 
            if(oldBillToAgreementMap.size()>0){
                Map<Id,APTS_Billing_Settings__c> agreementBSData = retrieveAssociatedBillingData(oldBillToAgreementMap.values(), oldBillToAgreementMap.keySet());
                if(!agreementBSData.isEmpty()){
                    for(APTS_Billing_Settings__c billSettingRecord : agreementBSData.values()){
                        if(billSettingRecord.APTS_Bill_To_ID__c != null && mapOldAgreements.get(billSettingRecord.APTS_Agreement_ID__c) != null){
                            if(mapOldAgreements.get(billSettingRecord.APTS_Agreement_ID__c).APTS_Bill_to_Party_MachServ__c != null
                                && billSettingRecord.APTS_Bill_To_ID__c == mapOldAgreements.get(billSettingRecord.APTS_Agreement_ID__c).APTS_Bill_to_Party_MachServ__c
                                && mapOldAgreements.get(billSettingRecord.APTS_Agreement_ID__c).APTS_Bill_to_Party_MachServ__c != mapAgreements.get(billSettingRecord.APTS_Agreement_ID__c).APTS_Bill_to_Party_MachServ__c
                                && MACHINE.equalsIgnoreCase(billSettingRecord.APTS_Agreement_Billing_Type__c)){
                                billingSettingListToDelete.add(billSettingRecord);
                            }
                            if(mapOldAgreements.get(billSettingRecord.APTS_Agreement_ID__c).APTS_Bill_to_Party_Ingredients__c != null
                                && billSettingRecord.APTS_Bill_To_ID__c == mapOldAgreements.get(billSettingRecord.APTS_Agreement_ID__c).APTS_Bill_to_Party_Ingredients__c
                                && mapOldAgreements.get(billSettingRecord.APTS_Agreement_ID__c).APTS_Bill_to_Party_Ingredients__c != mapAgreements.get(billSettingRecord.APTS_Agreement_ID__c).APTS_Bill_to_Party_Ingredients__c
                                && INGREDIENTS.equalsIgnoreCase(billSettingRecord.APTS_Agreement_Billing_Type__c)){
                               billingSettingListToDelete.add(billSettingRecord); 
                            }
                        }   
                    }
                }
            }
            if(billingSettingListToDelete.size()>0){
                drList = Database.Delete(billingSettingListToDelete,false);
                logError(drList,null,null,null,TRIGGERVALUE,BILLINGSETTINGOBJECTNAME,EMPTY_STRING,false,false,EMPTY_STRING,false);
            }   
            checkRecursive.run = false;    
        }
        }catch (Exception e){
            Database.rollback(savePnt);
            logError(null,null,null,e,TRIGGERVALUE,BILLINGSETTINGOBJECTNAME,EMPTY_STRING,false,false,EMPTY_STRING,true);
        }
    }
    /*
    * Method to retrieve associate Billing Setting record from agreement
    * retrieveAssociatedBillingData() will be invoked from createBillingSetting()
    */
    public static Map<Id,APTS_Billing_Settings__c> retrieveAssociatedBillingData(List<Id> agreementIdList, set<Id> accountIdList) {
        Map<Id,APTS_Billing_Settings__c> agreementBillingSettingMap = new Map<Id,APTS_Billing_Settings__c>();
        try{
            
            for (APTS_Billing_Settings__c existingBillingSettingRec : [SELECT Id, 
                                                                            APTS_Bill_To_ID__c,
                                                                            APTS_Agreement_ID__c,
                                                                            APTS_Billing_Preference_Setting__c,
                                                                            APTS_Payment_Method__c,
                                                                            APTS_Payment_Term_Setting__c,
                                                                            APTS_Billing_Rule_Contract__c,
                                                                            APTS_Invoice_Delivery_Preference__c,
                                                                            APTS_Invoice_Type__c,
                                                                            APTS_Agreement_Billing_Type__c
                                                                    FROM APTS_Billing_Settings__c
                                                                    WHERE APTS_Bill_To_ID__c IN:accountIdList
                                                                    AND APTS_Agreement_ID__c IN:agreementIdList
                                                                    ]) {
                agreementBillingSettingMap.put(existingBillingSettingRec.Id, existingBillingSettingRec);
            }
        }catch(Exception e){
            logError(null,null,null,e,APEX,'retrieveAssociatedBillingData() Method',EMPTY_STRING,false,false,EMPTY_STRING,true);
            return null;
        }
        return agreementBillingSettingMap;
    }
    
    /*
    * Method to set BillingSetting record to Agreement Based on Bill To(Machine/Services or Ingredients)
    * setBillingSettingData() will be invoked from createBillingSetting() Method
    */
    public static APTS_Billing_Settings__c setBillingSettingData(Apttus__APTS_Agreement__c  agreement, Account accountData, String billingSettingType) {
        APTS_Billing_Settings__c billingSettingObj = new APTS_Billing_Settings__c();
        try{
            
            billingSettingObj.APTS_Bill_To_ID__c = accountData.Id;
            billingSettingObj.APTS_Agreement_ID__c = agreement.Id;
            String consumptionAgrRecTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get(CONSUMPTION_MODEL).getRecordTypeId();
            // Billing Preference,Payment Term,Payment Method - Population from Account
            if(accountData.Apttus_Config2__BillingPreferenceId__c != null){
                billingSettingObj.APTS_Billing_Preference_Setting__c = accountData.Apttus_Config2__BillingPreferenceId__c;
                // Billing Rule, Invoice Delivery preference, Invoice Type - Population from Billing preference
                for (Apttus_Config2__BillingPreference__c billPrefData : [SELECT Id, 
                                                                                APTS_Billing_Rule_Contract__c,
                                                                                APTS_Invoice_Delivery_Preference__c,
                                                                                APTS_Invoice_Type__c
                                                                            FROM Apttus_Config2__BillingPreference__c
                                                                            WHERE Id =:accountData.Apttus_Config2__BillingPreferenceId__c
                                                                            ]) {
                    if(agreement.RecordTypeId == consumptionAgrRecTypeId){
                        billingSettingObj.APTS_Billing_Rule_Contract__c = BILL_IN_ARREARS;
                    }
                    else{
                        billingSettingObj.APTS_Billing_Rule_Contract__c = billPrefData.APTS_Billing_Rule_Contract__c;
                    }                
                    billingSettingObj.APTS_Invoice_Delivery_Preference__c = billPrefData.APTS_Invoice_Delivery_Preference__c;
                    billingSettingObj.APTS_Invoice_Type__c = billPrefData.APTS_Invoice_Type__c;
                }
            }
            billingSettingObj.APTS_Payment_Method__c = accountData.APTS_Payment_Method__c !=null?accountData.APTS_Payment_Method__c:null;
            billingSettingObj.APTS_Payment_Term_Setting__c = accountData.Apttus_Config2__PaymentTermId__c!=null?accountData.Apttus_Config2__PaymentTermId__c:null;
            billingSettingObj.APTS_Sales_Organization__c = accountData.Sales_Organization__c !=null?accountData.Sales_Organization__c : null;
            if(String.isNotBlank(billingSettingType)){
                billingSettingObj.APTS_Agreement_Billing_Type__c =  billingSettingType;
            }
            
        }catch(Exception e){
            logError(null,null,null,e,APEX,'setBillingSettingData() Method',EMPTY_STRING,false,false,EMPTY_STRING,true);
            return null;
        }
        return billingSettingObj;
    }
    
    
    /*
    * Method to retrieve BillingSettingData related to Agreement Based on Bill To(Machine/Services or Ingredients)
    * retrieveBillingSetting() will return the respective Billing setting record to APTS_PricingCallBack.cls
    */
    public static Map<Id,Map<String,APTS_Billing_Settings__c>> retrieveBillingSetting(Id agreementId) {
        Set<Id> agreementIdSet = new Set<Id>();
        Map<Id,Map<String,APTS_Billing_Settings__c>> billingSettingMap = new Map<Id,Map<String,APTS_Billing_Settings__c>>();
        try{
            // the below logic will be invoked on click of "Configure Products" 
            if(agreementId != null){
                agreementIdSet.add(agreementId);
                billingSettingMap = APTS_BIRUtils.prepareAgreementBillingSettingMap(agreementIdSet);
            }
        }catch(Exception e){
            logError(null,null,null,e,APEX,'retrieveBillingSettingData() Method',EMPTY_STRING,false,false,EMPTY_STRING,true);
        }
        return billingSettingMap;    
    }
    
    /*
    * Method to retrieve BillingSettingData related to Agreement Based on Bill To(Machine/Services or Ingredients)
    * retrieveAgreement() will return the respective Billing setting record to APTS_PricingCallBack.cls
    */
    public static Map<Id,Apttus_Config2__Order__c> retrieveAgreement(Id orderId) {
        Map<Id,Apttus_Config2__Order__c> orderAgreementMap = new Map<Id,Apttus_Config2__Order__c>();
        try{
            
            // the below logic will be invoked on click of "Configure Products" form Order
            if(orderId != null){
                for (Apttus_Config2__Order__c oOrder : [SELECT Id,Apttus_Config2__BillingPreferenceId__c,
                                                                Apttus_Config2__BillingPreferenceId__r.APTS_Billing_Rule_Contract__c,
                                                                Apttus_Config2__PaymentTermId__c,APTS_Payment_Method__c,
                                                                Apttus_CMConfig__AgreementId__c
                                                            FROM Apttus_Config2__Order__c
                                                            WHERE Id =: orderId
                                                            ]) {
                    if(oOrder.Apttus_CMConfig__AgreementId__c != null){
                        orderAgreementMap.put(oOrder.Id,oOrder);
                    }   
                }
            }
        }catch(Exception e){
            logError(null,null,null,e,APEX,'retrieveAgreement() Method',EMPTY_STRING,false,false,EMPTY_STRING,true);
            return null;
        }
        return orderAgreementMap;    
    }
    /*
    * Method to retrieve Bill-To account related to Order 
    * retrieveBillToAccount() will return map of Billto's id associated to agreement
    */
    public static Map<Id,Map<String,APTS_Billing_Settings__c>> prepareAgreementBillingSettingMap(Set<Id> agreementId) {
        Map<Id,Map<String,APTS_Billing_Settings__c>> billingSettingMap = new Map<Id,Map<String,APTS_Billing_Settings__c>>();
        try{
            
           if(agreementId.size()>0){
                List<APTS_Billing_Settings__c> billingSettingRec = [SELECT Id, 
                                                                            APTS_Bill_To_ID__c,
                                                                            APTS_Agreement_ID__c,
                                                                            APTS_Billing_Preference_Setting__c,
                                                                            APTS_Billing_Preference_Setting__r.Apttus_Config2__BillingInterval__c,
                                                                            APTS_Billing_Preference_Setting__r.Apttus_Config2__BillingCycleStart__c, //v106
                                                                            APTS_Billing_Preference_Setting__r.Apttus_Config2__BillingDayOfMonth2__c, //v106
                                                                            APTS_Payment_Method__c,
                                                                            APTS_Payment_Method__r.APTS_Payment_Method_Code__c,
                                                                            APTS_Payment_Term_Setting__c,
                                                                            APTS_Billing_Rule_Contract__c,
                                                                            APTS_Agreement_Billing_Type__c,
                                                                            APTS_Invoice_Delivery_Preference__c,
                                                                            APTS_Invoice_Type__c
                                                                        FROM APTS_Billing_Settings__c
                                                                        WHERE APTS_Agreement_ID__c IN: agreementId
                                                                        ];
                for (APTS_Billing_Settings__c bSRec : billingSettingRec) {
                    if (billingSettingMap.containsKey(bSRec.APTS_Agreement_ID__c)) {
                        Map<string, APTS_Billing_Settings__c> bSRecByBillingSettingType = billingSettingMap.get(bSRec.APTS_Agreement_ID__c);
                        if (!bSRecByBillingSettingType.containsKey(bSRec.APTS_Agreement_Billing_Type__c)) {
                            bSRecByBillingSettingType.put(bSRec.APTS_Agreement_Billing_Type__c, bSRec);
                        }
                    }else {
                        billingSettingMap.put(bSRec.APTS_Agreement_ID__c, new Map<string, APTS_Billing_Settings__c>{ bSRec.APTS_Agreement_Billing_Type__c => bSRec });
                    }  
                }
            }
        }catch(Exception e){
            logError(null,null,null,e,APEX,BILLINGSETTINGOBJECTNAME+PREPAREAGRMTBILLINSETTINGMETHOD,EMPTY_STRING,false,false,EMPTY_STRING,true);
        }
        return billingSettingMap;   
    }
    
    /*
    * Method to set Billing key info on line Items
    * overrideBillingFieldsOnLineItem() will return map of Billto's id associated to agreement
    */
    public static void overrideBillingFieldsOnLineItem(Apttus_Config2__LineItem__c oLineItem,Map<Id,Map<String,APTS_Billing_Settings__c>> agreementBillingSettingMap) {
        Map<String,APTS_Billing_Settings__c> billingSettingTypeMap = new Map<String,APTS_Billing_Settings__c>();
        try{
            if(agreementBillingSettingMap.size()>0){
                if (LINESTATUSNEW.equalsIgnoreCase(oLineItem.Apttus_Config2__LineStatus__c)) {
                    //system.debug('==> Inside OverrideBillingLineItem 1==> '+oLineItem.Id);
                    // Pull the respective Billing Setting Type Record
                    if(oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__c != null){
                        billingSettingTypeMap = agreementBillingSettingMap.get(oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__c);  
                    }else {
                        if(oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__c != null){
                            if (oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.Apttus_CMConfig__AgreementId__c!= null) {
                                billingSettingTypeMap = agreementBillingSettingMap.get(oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.Apttus_CMConfig__AgreementId__c);
                            }    
                        }
                    }
                    //Logic to set the respective Billing Setting Data on Line item based on Product Category
                    if(oLineItem.Apttus_Config2__ClassificationId__c != null){
                        if(oLineItem.Apttus_Config2__ClassificationId__r.Apttus_Config2__HierarchyId__c != null){
                            //Logic to set Machine/Services Billing Setting's Data from Agreement on Line item based for Machine/Services Product Category
                            if(MACHINES.equalsIgnoreCase(oLineItem.Apttus_Config2__ClassificationId__r.Apttus_Config2__HierarchyId__r.name)
                                    || SERVICES.equalsIgnoreCase(oLineItem.Apttus_Config2__ClassificationId__r.Apttus_Config2__HierarchyId__r.name)){
                                // Overwriting Mahines/Services Billing setting on Line item 
                                if(billingSettingTypeMap.get(MACHINE) != null){
                                    APTS_Billing_Settings__c machineOrServiceBillingSetting = billingSettingTypeMap.get(MACHINE);
                                     APTS_BIRUtils.setBillingKeyFieldsOnLineItem(oLineItem,machineOrServiceBillingSetting);
                                }
                            }else{
                                // Other than Machine/Servies setting Ingredients Billing Setting's Data from Agreement on Line item 
                                APTS_Billing_Settings__c ingredientBillingSetting = billingSettingTypeMap.get(INGREDIENTS);
                                APTS_BIRUtils.setBillingKeyFieldsOnLineItem(oLineItem,ingredientBillingSetting);
                            }
                        }
                    }else{
                        // Logic for Option Line items without Hierarchy values
                        if(oLineItem.Apttus_Config2__ProductOptionId__c != null
                            && oLineItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__c != null
                            && oLineItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__ParentOptionGroupId__c != null){
                            if((MACHINE.equalsIgnoreCase(oLineItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__ParentOptionGroupId__r.Apttus_Config2__Label__c) 
                                || MACHINES.equalsIgnoreCase(oLineItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__ParentOptionGroupId__r.Apttus_Config2__Label__c)
                                || SERVICES.equalsIgnoreCase(oLineItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__ParentOptionGroupId__r.Apttus_Config2__Label__c)
                                || SERVICE.equalsIgnoreCase(oLineItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__ParentOptionGroupId__r.Apttus_Config2__Label__c))
                                && billingSettingTypeMap.get(MACHINE) != null){
                                APTS_Billing_Settings__c optionProductBillingSetting = billingSettingTypeMap.get(MACHINE);
                                APTS_BIRUtils.setBillingKeyFieldsOnLineItem(oLineItem,optionProductBillingSetting);
                            }else {
                                // Other than Machine/Servies setting Ingredients Billing Setting's Data from Agreement on Line item 
                                APTS_Billing_Settings__c ingredientBillingSetting = billingSettingTypeMap.get(INGREDIENTS);
                                APTS_BIRUtils.setBillingKeyFieldsOnLineItem(oLineItem,ingredientBillingSetting);
                            }
                        }
                    }
                }
            } 
        }catch(Exception e){
            logError(null,null,null,e,APEX,'overrideBillingFieldsOnLineItem() method',EMPTY_STRING,false,false,EMPTY_STRING,true);
        }
    }
    /*
    * Method to set Billing key info on line Items
    * setBillingKeyFieldsOnLineItem() will set value for Invoice Type and Invoice Preference if the order is associated with an Agreement
    */
    public static void setBillingKeyFieldsOnLineItem(Apttus_Config2__LineItem__c oLineItem,APTS_Billing_Settings__c billingSetting) {
        try{
            if(billingSetting != null){
                // Set Billing Preference / Billing Frequency
                if(billingSetting.APTS_Billing_Preference_Setting__c != null){
                    oLineItem.Apttus_Config2__BillingPreferenceId__c = billingSetting.APTS_Billing_Preference_Setting__c;
                    // V116 >> Changes for defect # 24009 - Billing frequency not setting correctly on agreement line Item. Remove billing preference cascading from billing setting prefrence will to PLI as behaviour of OOB.
                    /*if(billingSetting.APTS_Billing_Preference_Setting__r.Apttus_Config2__BillingInterval__c != null){
                        oLineItem.Apttus_Config2__BillingFrequency__c = billingSetting.APTS_Billing_Preference_Setting__r.Apttus_Config2__BillingInterval__c;
                    }*/
                    // V116 >> Changes for defect # 24009 - Billing frequency not setting correctly on agreement line Item. Remove billing preference cascading from billing setting prefrence will to PLI as behaviour of OOB.
                }
                // Billing Rule
                if(billingSetting.APTS_Billing_Rule_Contract__c != null){
                    oLineItem.Apttus_Config2__BillingRule__c = billingSetting.APTS_Billing_Rule_Contract__c;
                }
                // payment Term 
                if(billingSetting.APTS_Payment_Term_Setting__c != null){
                    oLineItem.Apttus_Config2__PaymentTermId__c = billingSetting.APTS_Payment_Term_Setting__c;
                }
                // Payment Method 
                if(billingSetting.APTS_Payment_Method__c != null){
                    oLineItem.APTS_Payment_Method__c = billingSetting.APTS_Payment_Method__c;
                }
            }  
        }catch(Exception e){
            logError(null,null,null,e,APEX,'setBillingKeyFieldsOnLineItem() method',EMPTY_STRING,false,false,EMPTY_STRING,true);
        }   
    }
    /*
    * Method to set Billing key info on line Items
    * getInvoiceData() will set value for Invoice Type and Invoice Preference if the order is associated with an Agreement
    */
    public static void setInvoiceData(Apttus__APTS_Agreement__c oAgreement,Apttus_Config2__Order__c oOrder) {
        Map<Id,Map<String,APTS_Billing_Settings__c>> billingSettingMap = new Map<Id,Map<String,APTS_Billing_Settings__c>>();
        Set<Id> agreementId = new Set<Id>();
        Map<String,APTS_Billing_Settings__c> billingSettingTypeMap = new Map<String,APTS_Billing_Settings__c>();//Defect#5961 
        try {
            if(oAgreement!= NULL){
               
                agreementId.add(oAgreement.Id);
                // Check whether  billing Setting Record is present or not
                billingSettingMap = APTS_BIRUtils.prepareAgreementBillingSettingMap(agreementId);
                if(!billingSettingMap.isEmpty() && billingSettingMap.containsKey(oAgreement.Id)){// Added Null-check for Defect#5961
                    billingSettingTypeMap = billingSettingMap.get(oAgreement.Id);
                }
                
                Map<String,String> invoiceMap = APTS_BIRUtils.getInvoiceDeliveryPreferenceMapping();
                
                if((oOrder.APTS_Order_Type__c == STANDARD_ORDER || oOrder.APTS_Order_Type__c == ORDERTYPE_ROUTESALES 
                    || oOrder.APTS_Order_Type__c == ORDERTYPE_OPERATING || oOrder.APTS_Order_Type__c == DEBITMEMO) 
                    && oAgreement.APTS_Bill_to_Party_Ingredients__c != null ){
                    if(!billingSettingTypeMap.isEmpty()){
                        if(billingSettingTypeMap.containsKey(INGREDIENTS) && 
                            billingSettingTypeMap.get(INGREDIENTS) != null){
                            APTS_Billing_Settings__c invoiceData = billingSettingTypeMap.get(INGREDIENTS);
                            oOrder.APTS_InvoiceType__c = invoiceData.APTS_Invoice_Type__c != null? invoiceData.APTS_Invoice_Type__c : null;
                            oOrder.APTS_InvoiceDeliveryPreference__c = invoiceData.APTS_Invoice_Delivery_Preference__c != null? invoiceData.APTS_Invoice_Delivery_Preference__c : null;
                            
                            if(invoiceData.APTS_Invoice_Type__c != null
                                && (INVOICELISTWITHSUMMARY.equalsIgnoreCase(invoiceData.APTS_Invoice_Type__c) || COLLECTIVEINVOICE_WITHSMRYPAGE.equalsIgnoreCase(oOrder.APTS_InvoiceType__c))//v212
                                && invoiceData.APTS_Invoice_Delivery_Preference__c != null
                                && !invoiceMap.isEmpty()
                                && invoiceMap.containsKey(invoiceData.APTS_Invoice_Delivery_Preference__c)
                                && invoiceMap.get(invoiceData.APTS_Invoice_Delivery_Preference__c) != null){
                                oOrder.APTS_InvoiceDeliveryPreference__c =  invoiceMap.get(invoiceData.APTS_Invoice_Delivery_Preference__c);
                            }
                            
                            oOrder.Apttus_Config2__BillingPreferenceId__c = invoiceData.APTS_Billing_Preference_Setting__c != null? invoiceData.APTS_Billing_Preference_Setting__c:null;
                            oOrder.APTS_Payment_Method__c = invoiceData.APTS_Payment_Method__c != null? invoiceData.APTS_Payment_Method__c:null;
                            //v101++<<
                            oOrder.APTS_Payment_Method_Code__c = invoiceData.APTS_Payment_Method__c != null? invoiceData.APTS_Payment_Method__r.APTS_Payment_Method_Code__c : null;
                            //v100++>>
                            oOrder.Apttus_Config2__PaymentTermId__c = invoiceData.APTS_Payment_Term_Setting__c != null? invoiceData.APTS_Payment_Term_Setting__c:null;
                        }
                    }    
                }else if((MACHINE_ORDER.equalsIgnoreCase(oOrder.APTS_Order_Type__c)
                            || (ADMINORDER.equalsIgnoreCase(oOrder.APTS_Order_Type__c)
                                && CONVERSIONORDER.equalsIgnoreCase(oOrder.APTS_Order_Sub_Type__c))) 
                            && oAgreement.APTS_Bill_to_Party_MachServ__c != null){
                    if(!billingSettingTypeMap.isEmpty()){
                        if(billingSettingTypeMap.containsKey(MACHINE) && 
                            billingSettingTypeMap.get(MACHINE) != null){
                            APTS_Billing_Settings__c invoiceData = billingSettingTypeMap.get(MACHINE);
                            oOrder.APTS_InvoiceDeliveryPreference__c = String.isNotBlank(invoiceData.APTS_Invoice_Delivery_Preference__c)? invoiceData.APTS_Invoice_Delivery_Preference__c : '';
                            oOrder.APTS_InvoiceType__c = String.isNotBlank(invoiceData.APTS_Invoice_Type__c)? invoiceData.APTS_Invoice_Type__c : '';
                            if(invoiceData.APTS_Invoice_Type__c != null
                                && (INVOICELISTWITHSUMMARY.equalsIgnoreCase(invoiceData.APTS_Invoice_Type__c) || COLLECTIVEINVOICE_WITHSMRYPAGE.equalsIgnoreCase(oOrder.APTS_InvoiceType__c))//v212
                                && invoiceData.APTS_Invoice_Delivery_Preference__c != null
                                && !invoiceMap.isEmpty()
                                && invoiceMap.containsKey(invoiceData.APTS_Invoice_Delivery_Preference__c)
                                && invoiceMap.get(invoiceData.APTS_Invoice_Delivery_Preference__c) != null && oOrder.APTS_Order_Sub_Type__c != APTS_OrderConstants.INSTALLATION){
                                oOrder.APTS_InvoiceDeliveryPreference__c =  invoiceMap.get(invoiceData.APTS_Invoice_Delivery_Preference__c);
                            }
                            oOrder.Apttus_Config2__BillingPreferenceId__c = invoiceData.APTS_Billing_Preference_Setting__c != null? invoiceData.APTS_Billing_Preference_Setting__c:null;
                            oOrder.APTS_Payment_Method__c = invoiceData.APTS_Payment_Method__c != null? invoiceData.APTS_Payment_Method__c:null;
                            //v101++<<
                            oOrder.APTS_Payment_Method_Code__c = invoiceData.APTS_Payment_Method__c != null? invoiceData.APTS_Payment_Method__r.APTS_Payment_Method_Code__c : null;
                            //v101++>>
                            oOrder.Apttus_Config2__PaymentTermId__c = invoiceData.APTS_Payment_Term_Setting__c != null? invoiceData.APTS_Payment_Term_Setting__c:null;
                        }
                    }
                }
                
                
            //V115++>>
            //V201 ++>> 27-FEB-2019 Balashanthi A : triangular invoicing - billing preference, payment term and payment method are not populated on triangular orders as per standard logic
            // Added APTS_Boomerang_Invoicing__c flag for identifying triangular invoicing to apply the standard order logic for Triangular invoicing orders also V201 -->>
            //v206 Including Conversion Orders,v208 Enabled for RSO,Triangular,Digital Orders hence referring StandardOrder. Specific conditions are moved inside.
               //DQ-1545-- Fix for InvoiceDeliveryPreference getting overriden.
                if(((oOrder.APTS_Order_Type__c == STANDARD_ORDER || oOrder.APTS_Order_Type__c == ORDERTYPE_ROUTESALES||oOrder.APTS_Order_Type__c == ORDERTYPE_OPERATING) && oAgreement.APTS_Check_on_Account_Ingredients__c)
                    || (oOrder.APTS_Order_Type__c == MACHINE_ORDER && oAgreement.APTS_Check_on_Account_Machines__c && (oOrder.APTS_Order_Sub_Type__c==INSTALLATION || oOrder.APTS_Order_Sub_Type__c== APTS_OrderConstants.COMMERCIAL_SWAP || oOrder.APTS_Order_Sub_Type__c== APTS_OrderConstants.TECHNICAL_SWAP))
                    || (oOrder.APTS_Order_Type__c == ADMINORDER && oOrder.APTS_Order_Sub_Type__c==CONVERSIONORDER )
                    || (oOrder.APTS_Boomerang_Invoicing__c && oAgreement.APTS_Check_on_Account_Ingredients__c))
                {
                    for(Account a : [SELECT Related_Bill_to_Machines_Services__c,Related_Payer_Machines_Services__c,
                                        Bill_To_Payer_Account__c,Related_Payer_Account__c,
                                        Related_Bill_to_Machines_Services__r.Apttus_Config2__BillingPreferenceId__c,
                                        Related_Bill_to_Machines_Services__r.Apttus_Config2__PaymentTermId__c,
                                        Related_Bill_to_Machines_Services__r.APTS_Payment_Method__c,
                                        Related_Bill_to_Machines_Services__r.APTS_Payment_Method__r.APTS_Payment_Method_Code__c,
                                        Related_Bill_to_Machines_Services__r.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Type__c,
                                        Related_Bill_to_Machines_Services__r.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Delivery_Preference__c,
                                        Bill_To_Payer_Account__r.Apttus_Config2__BillingPreferenceId__c,
                                        Bill_To_Payer_Account__r.Apttus_Config2__PaymentTermId__c,
                                        Bill_To_Payer_Account__r.APTS_Payment_Method__c,
                                        Bill_To_Payer_Account__r.APTS_Payment_Method__r.APTS_Payment_Method_Code__c,
                                        Bill_To_Payer_Account__r.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Type__c,
                                        Bill_To_Payer_Account__r.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Delivery_Preference__c,
                                        Apttus_Config2__BillingPreferenceId__c,
                                        Apttus_Config2__PaymentTermId__c,
                                        APTS_Payment_Method__c,
                                        APTS_Payment_Method__r.APTS_Payment_Method_Code__c,
                                        Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Type__c,
                                        Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Delivery_Preference__c
                                        FROM Account WHERE Id =:oOrder.Apttus_Config2__SoldToAccountId__c LIMIT: 1])
                    {
                        //v206- Including Conversion Orders.
                        if(oOrder.APTS_Order_Type__c == MACHINE_ORDER && oAgreement.APTS_Check_on_Account_Machines__c){
                            if(a.Related_Bill_to_Machines_Services__r != null && a.Related_Bill_to_Machines_Services__r.Apttus_Config2__BillingPreferenceId__c !=null){
                                oOrder.Apttus_Config2__BillingPreferenceId__c =a.Related_Bill_to_Machines_Services__r.Apttus_Config2__BillingPreferenceId__c;
                                oOrder.APTS_InvoiceType__c =a.Related_Bill_to_Machines_Services__r.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Type__c;
                                oOrder.APTS_InvoiceDeliveryPreference__c = a.Related_Bill_to_Machines_Services__r.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Delivery_Preference__c;
    
                            }    
                            oOrder.Apttus_Config2__PaymentTermId__c =a.Related_Bill_to_Machines_Services__r.Apttus_Config2__PaymentTermId__c;
                            if(a.Related_Bill_to_Machines_Services__r != null && a.Related_Bill_to_Machines_Services__r.APTS_Payment_Method__c !=null){    
                                oOrder.APTS_Payment_Method__c =a.Related_Bill_to_Machines_Services__r.APTS_Payment_Method__c;
                                oOrder.APTS_Payment_Method_Code__c =a.Related_Bill_to_Machines_Services__r.APTS_Payment_Method__r.APTS_Payment_Method_Code__c;
                            }
                            if(a.Related_Bill_to_Machines_Services__c == null){
                                oOrder.Apttus_Config2__BillingPreferenceId__c = a.Apttus_Config2__BillingPreferenceId__c;
                                if(a.Apttus_Config2__BillingPreferenceId__c!=null){
                                    oOrder.APTS_InvoiceType__c = a.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Type__c;
                                    oOrder.APTS_InvoiceDeliveryPreference__c = a.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Delivery_Preference__c;
                                }
                                oOrder.Apttus_Config2__PaymentTermId__c =a.Apttus_Config2__PaymentTermId__c;
                                if(a.APTS_Payment_Method__c != null){
                                    oOrder.APTS_Payment_Method__c = a.APTS_Payment_Method__c;
                                    oOrder.APTS_Payment_Method_Code__c = a.APTS_Payment_Method__r.APTS_Payment_Method_Code__c;
                                }
                                // v118 -  Defect # 4416 - Agreement's refering to Account's Bill-to Checkbox | Payment Method Null values incorrectly defaulting to Billing Setting. Correctly they shold retain null values from bill-to account
                                else{
                                    oOrder.APTS_Payment_Method__c = null;
                                    oOrder.APTS_Payment_Method_Code__c = null;
                                }
                                // v118 -  Defect # 4416 - Agreement's refering to Account's Bill-to Checkbox | Payment Method Null values incorrectly defaulting to Billing Setting. Correctly they shold retain null values from bill-to account
                                //if(a.APTS_Payment_Method__c!=null)
                                //oOrder.APTS_Payment_Method_Code__c = a.APTS_Payment_Method__r.APTS_Payment_Method_Code__c;
                            }
                            // v118 -  Defect # 4416 - Agreement's refering to Account's Bill-to Checkbox | Payment Method Null values incorrectly defaulting to Billing Setting. Correctly they shold retain null values from bill-to account
                            if(a.Related_Bill_to_Machines_Services__r != null && a.Related_Bill_to_Machines_Services__r.APTS_Payment_Method__c == null){    
                                oOrder.APTS_Payment_Method__c = null;
                                oOrder.APTS_Payment_Method_Code__c = null;
                            }
                            // v118 -  Defect # 4416  - Agreement's refering to Account's Bill-to Checkbox | Payment Method Null values incorrectly defaulting to Billing Setting. Correctly they shold retain null values from bill-to account  
                        }else if((oOrder.APTS_Order_Type__c == STANDARD_ORDER || oOrder.APTS_Order_Type__c == ORDERTYPE_ROUTESALES||oOrder.APTS_Order_Type__c == ORDERTYPE_OPERATING)  && oAgreement.APTS_Check_on_Account_Ingredients__c){
                            if(a.Bill_To_Payer_Account__r != null && a.Bill_To_Payer_Account__r.Apttus_Config2__BillingPreferenceId__c !=null){
                                oOrder.Apttus_Config2__BillingPreferenceId__c =a.Bill_To_Payer_Account__r.Apttus_Config2__BillingPreferenceId__c;
                                oOrder.APTS_InvoiceType__c =a.Bill_To_Payer_Account__r.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Type__c;
                                oOrder.APTS_InvoiceDeliveryPreference__c = a.Bill_To_Payer_Account__r.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Delivery_Preference__c;
                            }  
                                
                                oOrder.Apttus_Config2__PaymentTermId__c =a.Bill_To_Payer_Account__r.Apttus_Config2__PaymentTermId__c;
                            if(a.Bill_To_Payer_Account__r != null && a.Bill_To_Payer_Account__r.APTS_Payment_Method__c !=null){    
                                oOrder.APTS_Payment_Method__c =a.Bill_To_Payer_Account__r.APTS_Payment_Method__c;
                                oOrder.APTS_Payment_Method_Code__c =a.Bill_To_Payer_Account__r.APTS_Payment_Method__r.APTS_Payment_Method_Code__c;
                            }
                            if(a.Bill_To_Payer_Account__c ==null){
                                oOrder.Apttus_Config2__BillingPreferenceId__c = a.Apttus_Config2__BillingPreferenceId__c;
                                if(a.Apttus_Config2__BillingPreferenceId__c!=null){
                                    oOrder.APTS_InvoiceType__c = a.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Type__c;
                                    
                                    oOrder.APTS_InvoiceDeliveryPreference__c = a.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Delivery_Preference__c;
                                    
                                }
                               
                                oOrder.Apttus_Config2__PaymentTermId__c =a.Apttus_Config2__PaymentTermId__c;
                                if(a.APTS_Payment_Method__c != null){
                                    oOrder.APTS_Payment_Method__c = a.APTS_Payment_Method__c;
                                    oOrder.APTS_Payment_Method_Code__c = a.APTS_Payment_Method__r.APTS_Payment_Method_Code__c;
                                }
                                // v118 -  Defect # 4416 - Agreement's refering to Account's Bill-to Checkbox | Payment Method Null values incorrectly defaulting to Billing Setting. Correctly they shold retain null values from bill-to account
                                else{
                                    oOrder.APTS_Payment_Method__c = null;
                                    oOrder.APTS_Payment_Method_Code__c = null;
                                }
                                // v118 -  Defect # 4416 - Agreement's refering to Account's Bill-to Checkbox | Payment Method Null values incorrectly defaulting to Billing Setting. Correctly they shold retain null values from bill-to account
                                //if(a.APTS_Payment_Method__c!=null)
                                //oOrder.APTS_Payment_Method_Code__c = a.APTS_Payment_Method__r.APTS_Payment_Method_Code__c;
                            }
                            // v118 -  Defect # 4416 - Agreement's refering to Account's Bill-to Checkbox | Payment Method Null values incorrectly defaulting to Billing Setting. Correctly they shold retain null values from bill-to account
                            if(a.Bill_To_Payer_Account__r != null && a.Bill_To_Payer_Account__r.APTS_Payment_Method__c == null){    
                                oOrder.APTS_Payment_Method__c = null;
                                oOrder.APTS_Payment_Method_Code__c = null;
                            }
                            // v118 -  Defect # 4416  - Agreement's refering to Account's Bill-to Checkbox | Payment Method Null values incorrectly defaulting to Billing Setting. Correctly they shold retain null values from bill-to account  
                        }
                        //V206 ++<<
                        oOrder.APTS_PayerMachinesServices__c=oAgreement.APTS_Check_on_Account_Machines__c?a.Related_Payer_Machines_Services__c:oAgreement.APTS_Payer_Machines_Services__c;
                        oOrder.APTS_Bill_to_Party_Machines_Services__c=oAgreement.APTS_Check_on_Account_Machines__c?a.Related_Bill_to_Machines_Services__c:oAgreement.APTS_Bill_to_Party_MachServ__c;
                        oOrder.APTS_PayerIngredients__c=oAgreement.APTS_Check_on_Account_Ingredients__c?a.Related_Payer_Account__c:oAgreement.APTS_Payer_Ingredients__c;
                        oOrder.APTS_Bill_to_Party_Ingredients_and_Payer__c=oAgreement.APTS_Check_on_Account_Ingredients__c?a.Bill_To_Payer_Account__c:oAgreement.APTS_Bill_to_Party_Ingredients__c;
                        //V206 ++>>
                        break;
                    }
    
                    //v119
                    if(oOrder.APTS_Order_Type__c != ADMINORDER
                        && !(oOrder.APTS_Order_Type__c == APTS_OrderConstants.MACHINE_ORDER && oOrder.APTS_Order_Sub_Type__c == APTS_OrderConstants.INSTALLATION)
                     && (INVOICELISTWITHSUMMARY.equalsIgnoreCase(oOrder.APTS_InvoiceType__c) || COLLECTIVEINVOICE_WITHSMRYPAGE.equalsIgnoreCase(oOrder.APTS_InvoiceType__c))//v212
                        && oOrder.APTS_InvoiceDeliveryPreference__c != null
                        && !invoiceMap.isEmpty() && invoiceMap.containsKey(oOrder.APTS_InvoiceDeliveryPreference__c)){
                        oOrder.APTS_InvoiceDeliveryPreference__c= invoiceMap.get(oOrder.APTS_InvoiceDeliveryPreference__c);  
                    }
                }
                //V115++<< Moved tis code outside as part of v119
                if(String.isNotBlank(oOrder.APTS_InvoiceType__c)){
                    
                    if(COLLECTIVEINVOICE.equalsIgnoreCase(oOrder.APTS_InvoiceType__c)){
                        oOrder.APTS_Collective_Billing_Indicator__c = true;
                        oOrder.APTS_Invoice_List_Indicator__c = NO;
                    }else if(COLLECTIVEINVOICE_WITHSMRYPAGE.equalsIgnoreCase(oOrder.APTS_InvoiceType__c)){//v212
                        oOrder.APTS_Collective_Billing_Indicator__c = true;
                        oOrder.APTS_Invoice_List_Indicator__c = YES;
                    }else if(INVOICELISTWITHOUTSUMMARY.equalsIgnoreCase(oOrder.APTS_InvoiceType__c) || INVOICELISTWITHSUMMARY.equalsIgnoreCase(oOrder.APTS_InvoiceType__c)){
                        oOrder.APTS_Invoice_List_Indicator__c = YES;
                    }
                    else{
                        oOrder.APTS_Invoice_List_Indicator__c = NO;
                        oOrder.APTS_Collective_Billing_Indicator__c = false;
                    }
                }
            }
        } catch (Exception e) {
            system.debug('Exception @@@@@@@==>'+e);
            system.debug('Exception Number @@@@@@@==>'+e.getLineNumber());
            logError(null,null,null,e,APEX,'setInvoiceData() Method',EMPTY_STRING,false,false,EMPTY_STRING,true);
        }
    }
    /*
    public static void setOrderBTPPayer(string BF, string PT, string PM, string PMCode,string IVT, string INVP){
    }*/
    
    /*
    * Method to set Billing key info on line Items
    * getInvoiceData() will set value for Invoice Type and Invoice Preference if the order is associated with an Agreement
    */
    public static void setInvoiceDataForDB(Apttus__APTS_Agreement__c oAgreement,Apttus_Config2__Order__c oOrder) {
        Map<Id,Map<String,APTS_Billing_Settings__c>> billingSettingMap = new Map<Id,Map<String,APTS_Billing_Settings__c>>();
        Map<String,APTS_Billing_Settings__c> billingSettingTypeMap = new Map<String,APTS_Billing_Settings__c>();//Defect#5961 
        Set<Id> agreementId = new Set<Id>();
        try {
            if(oAgreement!= NULL){
               
                agreementId.add(oAgreement.Id);
                // Check whether  billing Setting Record is present or not
                billingSettingMap = APTS_BIRUtils.prepareAgreementBillingSettingMap(agreementId);
                if(!billingSettingMap.isEmpty() && billingSettingMap.containsKey(oAgreement.Id)){// Added Null-check for Defect#5961
                    billingSettingTypeMap = billingSettingMap.get(oAgreement.Id);
                }
                
                if((oOrder.APTS_Order_Type__c == STANDARD_ORDER || oOrder.APTS_Order_Type__c == ORDERTYPE_ROUTESALES 
                    || oOrder.APTS_Order_Type__c == ORDERTYPE_OPERATING || oOrder.APTS_Order_Type__c == DEBITMEMO || oOrder.APTS_Order_Type__c == CREDITMEMO) 
                    && oAgreement.APTS_Bill_to_Party_Ingredients__c != null ){
                    if(!billingSettingTypeMap.isEmpty()){
                        if(billingSettingTypeMap.containsKey(INGREDIENTS) && 
                            billingSettingTypeMap.get(INGREDIENTS) != null){
                            APTS_Billing_Settings__c invoiceData = billingSettingTypeMap.get(INGREDIENTS);
                            oOrder.APTS_InvoiceType__c = invoiceData.APTS_Invoice_Type__c != null? invoiceData.APTS_Invoice_Type__c : null;
                            system.debug('==>Debite Memo ==>'+invoiceData.APTS_Invoice_Delivery_Preference__c);
                            oOrder.APTS_InvoiceDeliveryPreference__c = invoiceData.APTS_Invoice_Delivery_Preference__c != null? invoiceData.APTS_Invoice_Delivery_Preference__c : null;                 
                            oOrder.Apttus_Config2__BillingPreferenceId__c = invoiceData.APTS_Billing_Preference_Setting__c != null? invoiceData.APTS_Billing_Preference_Setting__c:null;
                            oOrder.APTS_Payment_Method__c = invoiceData.APTS_Payment_Method__c != null? invoiceData.APTS_Payment_Method__c:null;
                            //v101++<<
                            oOrder.APTS_Payment_Method_Code__c = invoiceData.APTS_Payment_Method__c != null? invoiceData.APTS_Payment_Method__r.APTS_Payment_Method_Code__c : null;
                            //v100++>>
                            oOrder.Apttus_Config2__PaymentTermId__c = invoiceData.APTS_Payment_Term_Setting__c != null? invoiceData.APTS_Payment_Term_Setting__c:null;
                        }
                    }   
                    
                }else if(oOrder.APTS_Order_Type__c == MACHINE_ORDER && oAgreement.APTS_Bill_to_Party_MachServ__c != null){
                    if(!billingSettingTypeMap.isEmpty()){
                        if(billingSettingTypeMap.containsKey(MACHINE) && 
                                billingSettingTypeMap.get(MACHINE) != null){
                                APTS_Billing_Settings__c invoiceData = billingSettingTypeMap.get(MACHINE);
                                oOrder.APTS_InvoiceDeliveryPreference__c = String.isNotBlank(invoiceData.APTS_Invoice_Delivery_Preference__c)? invoiceData.APTS_Invoice_Delivery_Preference__c : '';
                                oOrder.APTS_InvoiceType__c = String.isNotBlank(invoiceData.APTS_Invoice_Type__c)? invoiceData.APTS_Invoice_Type__c : '';
                                oOrder.Apttus_Config2__BillingPreferenceId__c = invoiceData.APTS_Billing_Preference_Setting__c != null? invoiceData.APTS_Billing_Preference_Setting__c:null;
                                oOrder.APTS_Payment_Method__c = invoiceData.APTS_Payment_Method__c != null? invoiceData.APTS_Payment_Method__c:null;
                                //v101++<<
                                oOrder.APTS_Payment_Method_Code__c = invoiceData.APTS_Payment_Method__c != null? invoiceData.APTS_Payment_Method__r.APTS_Payment_Method_Code__c : null;
                                //v101++>>
                                oOrder.Apttus_Config2__PaymentTermId__c = invoiceData.APTS_Payment_Term_Setting__c != null? invoiceData.APTS_Payment_Term_Setting__c:null;
                        }
                    }
                }
                if(String.isNotBlank(oOrder.APTS_InvoiceType__c)){
                    if(COLLECTIVEINVOICE.equalsIgnoreCase(oOrder.APTS_InvoiceType__c)){
                        oOrder.APTS_Collective_Billing_Indicator__c = true;
                        oOrder.APTS_Invoice_List_Indicator__c = NO;
                    }else if(COLLECTIVEINVOICE_WITHSMRYPAGE.equalsIgnoreCase(oOrder.APTS_InvoiceType__c)){//v212
                        oOrder.APTS_Collective_Billing_Indicator__c = true;
                        oOrder.APTS_Invoice_List_Indicator__c = YES;
                    }else if(INVOICELISTWITHOUTSUMMARY.equalsIgnoreCase(oOrder.APTS_InvoiceType__c) || INVOICELISTWITHSUMMARY.equalsIgnoreCase(oOrder.APTS_InvoiceType__c)){
                        oOrder.APTS_Invoice_List_Indicator__c = YES;
                    }
                    else{
                        oOrder.APTS_Invoice_List_Indicator__c = NO;
                        oOrder.APTS_Collective_Billing_Indicator__c = false;
                    }
                }
            }
        } catch (Exception e) {
            logError(null,null,null,e,APEX,'setInvoiceData() Method',EMPTY_STRING,false,false,EMPTY_STRING,true);
        }
    }
    
    /*
    * Method to set Billing key info on line Items
    * getInvoiceData() will set value for Invoice Type and Invoice Preference if the order is not associated with Agreement
    */
    public static void setInvoiceData(Account oAccount,Apttus_Config2__Order__c oOrder) {
        List<Account> billToAccountBillingSettingList = new List<Account>();
        try {
            //<<++ v203 Changes for defect# 6171 Starts
            if(oOrder.Apttus_Config2__SoldToAccountId__c != null){
                for(Account a : [SELECT Related_Bill_to_Machines_Services__c,
                                    Related_Payer_Machines_Services__c,
                                    Bill_To_Payer_Account__c,Related_Payer_Account__c,
                                    Related_Bill_to_Machines_Services__r.Apttus_Config2__BillingPreferenceId__c,
                                    Related_Bill_to_Machines_Services__r.Apttus_Config2__PaymentTermId__c,
                                    Related_Bill_to_Machines_Services__r.APTS_Payment_Method__c,
                                    Related_Bill_to_Machines_Services__r.APTS_Payment_Method__r.APTS_Payment_Method_Code__c,
                                    Related_Bill_to_Machines_Services__r.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Type__c,
                                    Related_Bill_to_Machines_Services__r.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Delivery_Preference__c,
                                    Bill_To_Payer_Account__r.Apttus_Config2__BillingPreferenceId__c,
                                    Bill_To_Payer_Account__r.Apttus_Config2__PaymentTermId__c,
                                    Bill_To_Payer_Account__r.APTS_Payment_Method__c,
                                    Bill_To_Payer_Account__r.APTS_Payment_Method__r.APTS_Payment_Method_Code__c,
                                    Bill_To_Payer_Account__r.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Type__c,
                                    Bill_To_Payer_Account__r.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Delivery_Preference__c,
                                    Apttus_Config2__BillingPreferenceId__c,
                                    Apttus_Config2__PaymentTermId__c,
                                    APTS_Payment_Method__c,
                                    APTS_Payment_Method__r.APTS_Payment_Method_Code__c,
                                    Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Type__c,
                                    Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Delivery_Preference__c
                                    FROM Account WHERE Id =:oOrder.Apttus_Config2__SoldToAccountId__c LIMIT: 1]){
                    if(oOrder.APTS_Order_Type__c == MACHINE_ORDER){
                        if(a.Related_Bill_to_Machines_Services__r != null && a.Related_Bill_to_Machines_Services__r.Apttus_Config2__BillingPreferenceId__c !=null){
                            oOrder.Apttus_Config2__BillingPreferenceId__c =a.Related_Bill_to_Machines_Services__r.Apttus_Config2__BillingPreferenceId__c;
                            oOrder.APTS_InvoiceType__c =a.Related_Bill_to_Machines_Services__r.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Type__c;
                            oOrder.APTS_InvoiceDeliveryPreference__c = a.Related_Bill_to_Machines_Services__r.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Delivery_Preference__c;
    
                        }    
                        oOrder.Apttus_Config2__PaymentTermId__c =a.Related_Bill_to_Machines_Services__r.Apttus_Config2__PaymentTermId__c;
                        if(a.Related_Bill_to_Machines_Services__r != null && a.Related_Bill_to_Machines_Services__r.APTS_Payment_Method__c !=null){    
                            oOrder.APTS_Payment_Method__c =a.Related_Bill_to_Machines_Services__r.APTS_Payment_Method__c;
                            oOrder.APTS_Payment_Method_Code__c =a.Related_Bill_to_Machines_Services__r.APTS_Payment_Method__r.APTS_Payment_Method_Code__c;
                        }
                        if(a.Related_Bill_to_Machines_Services__c == null){
                            oOrder.Apttus_Config2__BillingPreferenceId__c = a.Apttus_Config2__BillingPreferenceId__c;
                            if(a.Apttus_Config2__BillingPreferenceId__c!=null){
                                oOrder.APTS_InvoiceType__c = a.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Type__c;
                                oOrder.APTS_InvoiceDeliveryPreference__c = a.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Delivery_Preference__c;
                            }
                            oOrder.Apttus_Config2__PaymentTermId__c =a.Apttus_Config2__PaymentTermId__c;
                            if(a.APTS_Payment_Method__c != null){
                                oOrder.APTS_Payment_Method__c = a.APTS_Payment_Method__c;
                                oOrder.APTS_Payment_Method_Code__c = a.APTS_Payment_Method__r.APTS_Payment_Method_Code__c;
                            }
                            else{
                                oOrder.APTS_Payment_Method__c = null;
                            }
                        }
                        if(a.Related_Bill_to_Machines_Services__r != null && a.Related_Bill_to_Machines_Services__r.APTS_Payment_Method__c == null){    
                            oOrder.APTS_Payment_Method__c = null;
                        }
                    }else{
                        if(a.Bill_To_Payer_Account__r != null && a.Bill_To_Payer_Account__r.Apttus_Config2__BillingPreferenceId__c !=null){
                            oOrder.Apttus_Config2__BillingPreferenceId__c =a.Bill_To_Payer_Account__r.Apttus_Config2__BillingPreferenceId__c;
                            oOrder.APTS_InvoiceType__c =a.Bill_To_Payer_Account__r.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Type__c;
                            oOrder.APTS_InvoiceDeliveryPreference__c = a.Bill_To_Payer_Account__r.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Delivery_Preference__c;
                        }  
                            
                            oOrder.Apttus_Config2__PaymentTermId__c =a.Bill_To_Payer_Account__r.Apttus_Config2__PaymentTermId__c;
                        if(a.Bill_To_Payer_Account__r != null && a.Bill_To_Payer_Account__r.APTS_Payment_Method__c !=null){    
                            oOrder.APTS_Payment_Method__c =a.Bill_To_Payer_Account__r.APTS_Payment_Method__c;
                            oOrder.APTS_Payment_Method_Code__c =a.Bill_To_Payer_Account__r.APTS_Payment_Method__r.APTS_Payment_Method_Code__c;
                        }
                        if(a.Bill_To_Payer_Account__c ==null){
                            oOrder.Apttus_Config2__BillingPreferenceId__c = a.Apttus_Config2__BillingPreferenceId__c;
                            if(a.Apttus_Config2__BillingPreferenceId__c!=null){
                                oOrder.APTS_InvoiceType__c = a.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Type__c;
                                
                                oOrder.APTS_InvoiceDeliveryPreference__c = a.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Delivery_Preference__c;
                                
                            }
                           
                            oOrder.Apttus_Config2__PaymentTermId__c =a.Apttus_Config2__PaymentTermId__c;
                            if(a.APTS_Payment_Method__c != null){
                                oOrder.APTS_Payment_Method__c = a.APTS_Payment_Method__c;
                                oOrder.APTS_Payment_Method_Code__c = a.APTS_Payment_Method__r.APTS_Payment_Method_Code__c;
                            }
                            
                            else{
                                oOrder.APTS_Payment_Method__c = null;
                            }
                        }
                        if(a.Bill_To_Payer_Account__r != null && a.Bill_To_Payer_Account__r.APTS_Payment_Method__c == null){    
                            oOrder.APTS_Payment_Method__c = null;
                        }
                    }
                    oOrder.APTS_PayerMachinesServices__c=a.Related_Payer_Machines_Services__c;
                    oOrder.APTS_Bill_to_Party_Machines_Services__c=a.Related_Bill_to_Machines_Services__c;
                    oOrder.APTS_PayerIngredients__c=a.Related_Payer_Account__c;
                    oOrder.APTS_Bill_to_Party_Ingredients_and_Payer__c=a.Bill_To_Payer_Account__c;
    
                    break;
                }
            }
            //<<++ v203 Changes for defect# 6171 Starts
            if(String.isNotBlank(oOrder.APTS_InvoiceType__c)){
                if(COLLECTIVEINVOICE.equalsIgnoreCase(oOrder.APTS_InvoiceType__c)){
                    oOrder.APTS_Collective_Billing_Indicator__c = true;
                    oOrder.APTS_Invoice_List_Indicator__c = NO;
                }else if(INVOICELISTWITHOUTSUMMARY.equalsIgnoreCase(oOrder.APTS_InvoiceType__c) || INVOICELISTWITHSUMMARY.equalsIgnoreCase(oOrder.APTS_InvoiceType__c)){
                    oOrder.APTS_Invoice_List_Indicator__c = YES;
                }
                else{
                    oOrder.APTS_Invoice_List_Indicator__c = NO;
                    oOrder.APTS_Collective_Billing_Indicator__c = false;
                }
            }
            //<<++ v203 Changes for defect# 6171 ENDS
            /*Id accountId = oAccount.Id;
            // Check whether  billing Setting Record is present or not
            Map<String,String> invoiceMap = APTS_BIRUtils.getInvoiceDeliveryPreferenceMapping();
            billToAccountBillingSettingList = [SELECT Id, 
                                                    Apttus_Config2__BillingPreferenceId__c,
                                                    Apttus_Config2__PaymentTermId__c,
                                                    APTS_Payment_Method__c,
                                                    APTS_Payment_Method__r.APTS_Payment_Method_Code__c                                              
                                                FROM Account
                                                WHERE Id =: accountId
                                                ];
            if(!billToAccountBillingSettingList.isEmpty()){
                Account acctData = billToAccountBillingSettingList[0];
                oOrder.Apttus_Config2__BillingPreferenceId__c = acctData.Apttus_Config2__BillingPreferenceId__c != null? acctData.Apttus_Config2__BillingPreferenceId__c:null;
                oOrder.APTS_Payment_Method__c = acctData.APTS_Payment_Method__c != null? acctData.APTS_Payment_Method__c:null;
               //v101++<<
                oOrder.APTS_Payment_Method_Code__c = acctData.APTS_Payment_Method__c != null? acctData.APTS_Payment_Method__r.APTS_Payment_Method_Code__c : null;
               //v101++>>
                oOrder.Apttus_Config2__PaymentTermId__c = acctData.Apttus_Config2__PaymentTermId__c != null? acctData.Apttus_Config2__PaymentTermId__c:null;
            }
            if(oOrder.Apttus_Config2__BillingPreferenceId__c != null){
                
                // Billing Rule, Invoice Delivery preference, Invoice Type - Population from Billing preference
                List<Apttus_Config2__BillingPreference__c> billPrefData = [SELECT Id, 
                                                                                APTS_Billing_Rule_Contract__c,
                                                                                APTS_Invoice_Delivery_Preference__c,
                                                                                APTS_Invoice_Type__c,
                                                                                Apttus_Config2__BillingCycleStart__c,
                                                                                Apttus_Config2__BillingDayOfMonth2__c
                                                                            FROM Apttus_Config2__BillingPreference__c
                                                                            WHERE Id =:oOrder.Apttus_Config2__BillingPreferenceId__c
                                                                            ];
                if(!billPrefData.isEmpty()){
                    Apttus_Config2__BillingPreference__c billPref = billPrefData[0];
                    if(String.isNotBlank(billPref.APTS_Invoice_Delivery_Preference__c)){
                        oOrder.APTS_InvoiceDeliveryPreference__c = billPref.APTS_Invoice_Delivery_Preference__c;
                    }
                    if(String.isNotBlank(billPref.APTS_Invoice_Type__c)){
                        oOrder.APTS_InvoiceType__c = billPref.APTS_Invoice_Type__c;
                        if(INVOICELISTWITHSUMMARY.equalsIgnoreCase(billPref.APTS_Invoice_Type__c)
                                && billPref.APTS_Invoice_Delivery_Preference__c != null
                                && !invoiceMap.isEmpty()
                                && invoiceMap.containsKey(billPref.APTS_Invoice_Delivery_Preference__c)
                                && invoiceMap.get(billPref.APTS_Invoice_Delivery_Preference__c) != null){
                                oOrder.APTS_InvoiceDeliveryPreference__c =  invoiceMap.get(billPref.APTS_Invoice_Delivery_Preference__c);
                        }
                    }
                }                                                           
            }*/
                    
        } catch (Exception e) {
            logError(null,null,null,e,APEX,'setInvoiceData() Method',EMPTY_STRING,false,false,EMPTY_STRING,true);
        }
    } 
    
    //v106 Start here
    /*  Method Name : assignBillingDateToOrder()
    *   Parameters  : Billing Setting, Order
    *   Description : Assing Billing Date to Order based on */
    public static void assignBillingDateToOrder(Map<Id, Apttus_Config2__BillingPreference__c> billPrefMap, Apttus_Config2__Order__c oOrder){
        if(oOrder.Apttus_Config2__ActivatedDate__c != null){
            if(string.isNotEmpty(oOrder.APTS_SAP_OrderType__c)
                && !CREDITSAPORDERTYPE.equalsIgnoreCase(oOrder.APTS_SAP_OrderType__c)
                && !ADMINORDERSAPORDERTYPE.equalsIgnoreCase(oOrder.APTS_SAP_OrderType__c)
                && !CONSUMPTIONSAPORDERTYPE.equalsIgnoreCase(oOrder.APTS_SAP_OrderType__c)
                && !INSTALLATION.equalsIgnoreCase(oOrder.APTS_Order_Sub_Type__c)
                && oOrder.Apttus_Config2__BillingPreferenceId__c != null
                && !billPrefMap.isEmpty()
                && billPrefMap.containsKey(oOrder.Apttus_Config2__BillingPreferenceId__c)
                && billPrefMap.get(oOrder.Apttus_Config2__BillingPreferenceId__c) != null
                && billPrefMap.get(oOrder.Apttus_Config2__BillingPreferenceId__c).Apttus_Config2__BillingCycleStart__c != null
                && !CONVERSIONORDER.equalsIgnoreCase(oOrder.APTS_Order_Sub_Type__c)){
                if(BILLING_DAY_OF_MONTH.equalsIgnoreCase(billPrefMap.get(oOrder.Apttus_Config2__BillingPreferenceId__c).Apttus_Config2__BillingCycleStart__c)){
                    if(billPrefMap.get(oOrder.Apttus_Config2__BillingPreferenceId__c).Apttus_Config2__BillingDayOfMonth2__c != null){
                        String billingDayStr = '';
                        Integer billingDayNumber;
                        if(END_OF_MONTH.equalsIgnoreCase(billPrefMap.get(oOrder.Apttus_Config2__BillingPreferenceId__c).Apttus_Config2__BillingDayOfMonth2__c)){
                            billingDayNumber = date.daysInMonth(oOrder.Apttus_Config2__ActivatedDate__c.Year(), oOrder.Apttus_Config2__ActivatedDate__c.Month());
                        }
                        else{
                            for(integer i =0;i<2;i++){
                                String s= billPrefMap.get(oOrder.Apttus_Config2__BillingPreferenceId__c).Apttus_Config2__BillingDayOfMonth2__c.mid(i,1);
                                if(s.isNumeric()){
                                    billingDayStr +=s;
                                }
                            }
                           billingDayNumber = Integer.valueOf(billingDayStr);
                        }
                        Integer orderActivationDay = (oOrder.Apttus_Config2__ActivatedDate__c).Day();
                        if(orderActivationDay > billingDayNumber){
                            oOrder.APTS_Billing_Date__c = Date.newInstance(oOrder.Apttus_Config2__ActivatedDate__c.Year(), oOrder.Apttus_Config2__ActivatedDate__c.Month(), billingDayNumber).addMonths(1);
                        }
                        else{
                            //<<++v200 27-FEB-2019 Balashanthi A : Defect # 5429 : billing date incorrect - triangular invoicing
                            Integer year = oOrder.Apttus_Config2__ActivatedDate__c.Year();
                            Integer month =  oOrder.Apttus_Config2__ActivatedDate__c.Month();
                            Integer noOfDaysInMonth = date.daysInMonth(year,month);
                            if(billingDayNumber > noOfDaysInMonth){
                                billingDayNumber = noOfDaysInMonth;
                            }
                            //<<++v200 27-FEB-2019 Balashanthi A : Defect # 5429 : billing date incorrect - triangular invoicing
                            oOrder.APTS_Billing_Date__c = Date.newInstance(oOrder.Apttus_Config2__ActivatedDate__c.Year(), oOrder.Apttus_Config2__ActivatedDate__c.Month(), billingDayNumber);
                        }
                    }
                }else if(READYFORBILLING.equalsIgnoreCase(billPrefMap.get(oOrder.Apttus_Config2__BillingPreferenceId__c).Apttus_Config2__BillingCycleStart__c)
                            || PERIOD_START_DATE.equalsIgnoreCase(billPrefMap.get(oOrder.Apttus_Config2__BillingPreferenceId__c).Apttus_Config2__BillingCycleStart__c)){
                    oOrder.APTS_Billing_Date__c = oOrder.Apttus_Config2__ActivatedDate__c.date();
                }
            }else{
                if(string.isNotEmpty(oOrder.APTS_SAP_OrderType__c)){
                    if(CREDITSAPORDERTYPE.equalsIgnoreCase(oOrder.APTS_SAP_OrderType__c)){
                        oOrder.APTS_Billing_Date__c = oOrder.Apttus_Config2__ActivatedDate__c.date();
                    }
                }
                if(string.isNotEmpty(oOrder.APTS_Order_Sub_Type__c)){
                    if(INSTALLATION.equalsIgnoreCase(oOrder.APTS_Order_Sub_Type__c)){
                        oOrder.APTS_Billing_Date__c = oOrder.Apttus_Config2__ActivatedDate__c.date();
                    }
                }
            }
        }
    }
    //v106 Ends here
    
        /* Create volume obligation line items for child record if the matching records are present. Otherwise look into its immediate 
        parent Account's volumne obligation schedule, if its present then mapping the line item to it. If not present at parent level 
        also then look into grandparent account and map to its volume obligation schedule. In all cases the value should be rolled into
        buying group account. */
        
        /********************************* FOR CONTRACT HIERARCHY  ***********************************/
        //v1.1 starts here
        public static void createVolumeObligationLineItems(List<SObject> newList, Map<Id, SObject> mapOrderLineItems, 
                                                List<SObject> oldList, Map<Id, SObject> mapOldOrderLineItems, 
                                                Map<Id, Apttus_Config2__Order__c> mapOrders)
        { 
            List<Database.UpsertResult> listSaveResult = new List<Database.UpsertResult>();
            //Map<Id, Apttus_Config2__Order__c> mapOrders = new Map<Id, Apttus_Config2__Order__c>();
            List<APTS_Error_Object__c> lstErrorObject = new List<APTS_Error_Object__c>();
            try
            {
            
            Set<Id> setAgreementIds = new Set<Id>();
            Set<Id> setOLIs = new Set<Id>(); //v109
            Set<Id> setAllOLIs = new Set<Id>(); //v109
            Boolean statusChanged;
            Decimal orderedQuantity; 
            Decimal quantityDifference;
            Decimal orderInProgressQuantity; 
            Apttus_Config2__OrderLineItem__c oldOrderLineItem;
            List<APTS_AgreementVolumeObligation__c> tempAgreement;
            List<APTS_AgreementVolumeObligation__c> lstTempVolumeObligation;
            List<APTS_AgreementVolumeObligation__c> lstVolumeObligation;
            APTS_Agreement_Volume_Obligation_Line__c agreementVolumeObligationLineItem;
            //Set<String> toUOMSet = new Set<String>();
            //Set<String> prodCodeSet = new Set<String>();
            Map<ID,Apttus_Config2__FrequencyConversionRate__c> uomConversionMap= new Map<ID,Apttus_Config2__FrequencyConversionRate__c>();
            Set<String> uomAPIParamSet = new Set<String>();
            //Map<Id, String> orderLIOrderType = new Map<Id, String>();
            //Set<Id> orderLiSet = new Set<Id>();
            //Boolean isInsert = True;
            Map<Id, Apttus_Config2__OrderLineItem__c> mapOLICategory = new Map<Id, Apttus_Config2__OrderLineItem__c>(); //v110
            
            for(Apttus_Config2__OrderLineItem__c lineItem : (List<Apttus_Config2__OrderLineItem__c>)mapOrderLineItems.values())
            {
                if(lineItem.Apttus_Config2__Status__c.equals(ACTIVATED) && lineItem.APTS_Returned_Quantity__c > 0)
                {
                    setAgreementIds.add(lineItem.Apttus_CMConfig__AgreementId__c);
                }
                oldOrderLineItem = (Apttus_Config2__OrderLineItem__c)mapOldOrderLineItems.get(lineItem.Id);
                statusChanged = oldOrderLineItem.Apttus_Config2__Status__c != lineItem.Apttus_Config2__Status__c;
                quantityDifference = (oldOrderLineItem != null && oldOrderLineItem.Apttus_Config2__FulfilledQuantity__c != null)
                                                 ? lineItem.Apttus_Config2__FulfilledQuantity__c - oldOrderLineItem.Apttus_Config2__FulfilledQuantity__c
                                                 : lineItem.Apttus_Config2__FulfilledQuantity__c;
                
                if((quantityDifference > 0 || statusChanged) && (lineItem.Apttus_Config2__Status__c.equals(pending)
                                || lineItem.Apttus_Config2__Status__c.equals(partially_fulfilled)
                                || lineItem.Apttus_Config2__Status__c.equals(fulfilled)
                                || lineItem.Apttus_Config2__Status__c.equals(ACTIVATED)))
                {
                
                    setAgreementIds.add(lineItem.Apttus_CMConfig__AgreementId__c);
                    setAllOLIs.add(lineItem.Id); //v109 
                }
                //creating set for Selling UOM
                if(lineItem.APTS_Replaced_Product_Code__c != null){
                    //26-10-2018 RM. Replace APTS_CPQConstants.PIECE_UOM_API with the selling UOM.
                    uomAPIParamSet.add(lineitem.APTS_Replaced_Product_Code__c+';'+ lineitem.Apttus_Config2__SellingUom__c +';'+DRINKS);
                    uomAPIParamSet.add(lineitem.APTS_Replaced_Product_Code__c+';'+ lineitem.Apttus_Config2__SellingUom__c +';'+LITER);
                    uomAPIParamSet.add(lineitem.APTS_Replaced_Product_Code__c+';'+ lineitem.Apttus_Config2__SellingUom__c +';'+KILOGRAMS);
                }
                //orderLiSet.add(lineItem.Id);
    
            }
    
            //Created map for UOM table | gets all UOM table records matching with line item pricing UOM and selling UOM
            //26-10-2018 RM. Use the method to obtain the appropriate conversion rate.
            Map<String,Decimal> uomAPIResponseMap = APTS_UOMConversionUtils.getUOMConversions(uomAPIParamSet);
            
    
           //v109 starts here        
            if(!setAgreementIds.isEmpty() && !setAllOLIs.isEmpty())
            {
                Set<String> setSAPTypesToExclude = new Set<String>{DEBITSAPORDERTYPE, CREDITSAPORDERTYPE, ADMINORDERSAPORDERTYPE, CONSUMPTIONSAPORDERTYPE};
                for(Apttus_Config2__OrderLineItem__c oli : [SELECT Id, Apttus_Config2__OrderId__c,
                                        //v110 starts here
                                        Apttus_Config2__ClassificationId__c, Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c, 
                                        Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__r.Apttus_Config2__Level__c
                                        //v110 ends here
                                         FROM Apttus_Config2__OrderLineItem__c WHERE Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c NOT IN: setSAPTypesToExclude AND Id IN: setAllOLIs ])
                {
                    setOLIs.add(oli.Id);
                    mapOLICategory.put(oli.Id, oli);//v110
                }
            }
            //v109 ends here
            if(!setAgreementIds.isEmpty() && !setOLIs.isEmpty())
            {
                Map<Id, Id> mapAgreementSoldTo = new Map<Id, Id>();
                List<APTS_Agreement_Volume_Obligation_Line__c> lstAgreementLineItem = new List<APTS_Agreement_Volume_Obligation_Line__c>();
                List<APTS_Agreement_Volume_Obligation_Line__c> lstVolumeObligationLine = new List<APTS_Agreement_Volume_Obligation_Line__c>();
                Map<String, APTS_Contract_Entitlement_Repository__c> mapCategorySoldToCombo = new Map<String, APTS_Contract_Entitlement_Repository__c >();
                
                Map<String, APTS_Contract_Entitlement_Repository__c> mapParentCategorySoldToCombo = new Map<String, APTS_Contract_Entitlement_Repository__c >();
                Map<String, APTS_Contract_Entitlement_Repository__c> mapGParentCategorySoldToCombo = new Map<String, APTS_Contract_Entitlement_Repository__c >();
                
                Set<Id> setSoldToIds = new Set<Id>();
            
                lstAgreementLineItem = [SELECT Id, APTS_Order_Line_Item__c, APTS_Inactive__c 
                                        FROM APTS_Agreement_Volume_Obligation_Line__c 
                                        WHERE APTS_Order_Line_Item__c IN : mapOrderLineItems.KeySet() 
                                        AND APTS_Inactive__c = FALSE
                                        ];                
                Map<String, List<APTS_AgreementVolumeObligation__c>> mapChildObligationSchedule = new Map<String, List<APTS_AgreementVolumeObligation__c>>();
                Map<String, List<APTS_AgreementVolumeObligation__c>> mapParentObligationSchedule = new Map<String, List<APTS_AgreementVolumeObligation__c>>();
                Map<String, List<APTS_AgreementVolumeObligation__c>> mapGParentbligationSchedule = new Map<String, List<APTS_AgreementVolumeObligation__c>>();
                Map<String, List<APTS_AgreementVolumeObligation__c>> mapBuyingGrpObligationSchedule = new Map<String, List<APTS_AgreementVolumeObligation__c>>();
                
                //Get the hierarchy from account.
                Map<Id, APTS_CERUtility.AccountHierarchy> mapAccountHierarchy = new Map<Id, APTS_CERUtility.AccountHierarchy>();
                Map<Id, Id> mapAccountParent = new Map<Id, Id>();
                Map<Id, Id> mapAccountGrandParent = new Map<Id, Id>();
                Map<Id, Id> mapAccountBuyingGroup = new Map<Id, Id>();
                
                //Map of all agreement and its record types.
                Map<Id, String> mapAgreementRecordType = new Map<Id, String>();
                String agreementRecordType = '';
                
                
                
                //Query record type of agreement for which order line item is created.
                for(Apttus__APTS_Agreement__c agreement : [SELECT Id,RecordtypeId, APTS_Sold_To__c
                                                            FROM Apttus__APTS_Agreement__c 
                                                            WHERE Id IN : setAgreementIds 
                                                            ])
                {
                    mapAgreementRecordType.put(agreement.Id, agreement.RecordTypeId);
                    mapAgreementSoldTo.put(agreement.Id, agreement.APTS_Sold_To__c);
                    if(agreement.APTS_Sold_To__c!=null){
                        setSoldToIds.add(agreement.APTS_Sold_To__c);
                    }
                }
            
                mapAccountHierarchy = APTS_CERUtility.getAccountHierarchy(setSoldToIds);
                for(Id accountID : mapAccountHierarchy.keySet())
                {
                    
                    if(mapAccountHierarchy.get(accountID ).parentId != Null)  
                    {
                        mapAccountParent.put(accountID, mapAccountHierarchy.get(accountID ).parentId); 
                        setSoldToIds.add(mapAccountHierarchy.get(accountID ).parentId);  
                    }
                    if(mapAccountHierarchy.get(accountID ).grandParentId != Null)  
                    { 
                        mapAccountGrandParent.put(accountID, mapAccountHierarchy.get(accountID ).grandParentId);
                        setSoldToIds.add(mapAccountHierarchy.get(accountID ).grandParentId);    
                    }
                    
                    if(mapAccountHierarchy.get(accountID ).buyingGroupId!= Null)  
                    {
                        mapAccountBuyingGroup.put(accountID, mapAccountHierarchy.get(accountID ).buyingGroupId);
                        setSoldToIds.add(mapAccountHierarchy.get(accountID ).buyingGroupId);    
                    }
                }
                //v215-->
                //Query obligation schedule which are created for child, parent, and grand parent accounts
                for(APTS_AgreementVolumeObligation__c obligationSchedule : [SELECT Id, APTS_Agreement__c, APTS_Agreement_Total_Volume_Obligation__c,
                                                                            APTS_Agreement_Total_Volume_Obligation__r.APTS_Value__c, 
                                                                            APTS_End_Date__c, APTS_Start_Date__c, APTS_Value_Name__c, APTS_Type__c, 
                                                                            APTS_Agreement__r.RecordtypeId, APTS_Agreement__r.APTS_Sold_To__c, 
                                                                            APTS_Unit_of_Measure__c
                                                                            FROM APTS_AgreementVolumeObligation__c 
                                                                            WHERE APTS_Agreement__r.APTS_Sold_To__c IN: setSoldToIds 
                                                                            //OR APTS_Agreement__r.APTS_Sold_To__c IN : mapAccountParent.values()
                                                                            //OR APTS_Agreement__r.APTS_Sold_To__c IN : mapAccountGrandParent.values()
                                                                            //OR APTS_Agreement__r.APTS_Sold_To__c IN : mapAccountBuyingGroup.values()) 
                                                                            //AND APTS_Status__c != 'Closed'
                                                                            AND APTS_Status__c = 'Open'
                                                                            AND APTS_Agreement__r.Apttus__Status_Category__c='In Effect' 
                                                                            AND APTS_Agreement__r.Apttus__Status__c='Activated' 
                                                                            //Limit :(Limits.getLimitQueryRows() - Limits.getQueryRows())
                                                                            ])
                {
                    mapAgreementRecordType.put(obligationSchedule.APTS_Agreement__c, obligationSchedule.APTS_Agreement__r.RecordTypeId);
                    lstTempVolumeObligation = new List<APTS_AgreementVolumeObligation__c>();
                    lstVolumeObligation = new List<APTS_AgreementVolumeObligation__c>();
                    
                    //If volume obligation schedules are present for the same account itself, then it would be mapped in this statement.
                    if(setSoldToIds.contains(obligationSchedule.APTS_Agreement__r.APTS_Sold_To__c))
                    {
                        if(!mapChildObligationSchedule.isEmpty() && 
                        mapChildObligationSchedule.ContainsKey(string.ValueOf(obligationSchedule.APTS_Agreement_Total_Volume_Obligation__r.APTS_Value__c) +
                        string.valueOf(obligationSchedule.APTS_Agreement__r.APTS_Sold_To__c)))
                        {
                            lstVolumeObligation = mapChildObligationSchedule.get(string.ValueOf(obligationSchedule.APTS_Agreement_Total_Volume_Obligation__r.APTS_Value__c) +
                            string.valueOf(obligationSchedule.APTS_Agreement__r.APTS_Sold_To__c));
                             
                             
                            lstTempVolumeObligation.add(obligationSchedule);
                            mapChildObligationSchedule.put(string.ValueOf(obligationSchedule.APTS_Agreement_Total_Volume_Obligation__r.APTS_Value__c) +
                            string.valueOf(obligationSchedule.APTS_Agreement__r.APTS_Sold_To__c), lstVolumeObligation );
                        }
                        else
                        {
                            lstVolumeObligation.add(obligationSchedule);
                            mapChildObligationSchedule.put(string.ValueOf(obligationSchedule.APTS_Agreement_Total_Volume_Obligation__r.APTS_Value__c) +
                            string.valueOf(obligationSchedule.APTS_Agreement__r.APTS_Sold_To__c), lstVolumeObligation);
                        }
                    }
                    
                    if(!mapAccountParent.isEmpty())  
                    {
                        if(!mapParentObligationSchedule.isEmpty() && 
                        mapParentObligationSchedule.ContainsKey(string.ValueOf(obligationSchedule.APTS_Agreement_Total_Volume_Obligation__r.APTS_Value__c) +
                        string.valueOf(obligationSchedule.APTS_Agreement__r.APTS_Sold_To__c)))
                        {
                            lstTempVolumeObligation = mapParentObligationSchedule.get(string.ValueOf(obligationSchedule.APTS_Agreement_Total_Volume_Obligation__r.APTS_Value__c) +
                            string.valueOf(obligationSchedule.APTS_Agreement__r.APTS_Sold_To__c));
                            
                             
                            lstTempVolumeObligation.add(obligationSchedule);
                            mapParentObligationSchedule.put(string.ValueOf(obligationSchedule.APTS_Agreement_Total_Volume_Obligation__r.APTS_Value__c) +
                            string.valueOf(obligationSchedule.APTS_Agreement__r.APTS_Sold_To__c), lstTempVolumeObligation);
                        }
                        
                        else
                        {
                            //Add parent account and all its relavent volume obligation schedule.
                            lstTempVolumeObligation.add(obligationSchedule);
                            mapParentObligationSchedule.put(string.ValueOf(obligationSchedule.APTS_Agreement_Total_Volume_Obligation__r.APTS_Value__c) +
                            string.valueOf(obligationSchedule.APTS_Agreement__r.APTS_Sold_To__c), lstTempVolumeObligation);
                        }
                    }
                    
                    if(!mapAccountGrandParent.isEmpty())  
                    {
                    
                        if(!mapGParentbligationSchedule.isEmpty() && 
                        mapGParentbligationSchedule.ContainsKey(string.ValueOf(obligationSchedule.APTS_Agreement_Total_Volume_Obligation__r.APTS_Value__c) +
                        string.valueOf(obligationSchedule.APTS_Agreement__r.APTS_Sold_To__c)))
                        {
                            lstTempVolumeObligation = mapGParentbligationSchedule.get(string.ValueOf(obligationSchedule.APTS_Agreement_Total_Volume_Obligation__r.APTS_Value__c) +
                            string.valueOf(obligationSchedule.APTS_Agreement__r.APTS_Sold_To__c));
                             
                             
                            lstTempVolumeObligation.add(obligationSchedule);
                            mapGParentbligationSchedule.put(string.ValueOf(obligationSchedule.APTS_Agreement_Total_Volume_Obligation__r.APTS_Value__c) +
                            string.valueOf(obligationSchedule.APTS_Agreement__r.APTS_Sold_To__c), lstTempVolumeObligation);
                        }
                        else
                        {
                            lstTempVolumeObligation.clear();
                            lstTempVolumeObligation.add(obligationSchedule);
                            mapGParentbligationSchedule.put(string.ValueOf(obligationSchedule.APTS_Agreement_Total_Volume_Obligation__r.APTS_Value__c) +
                             string.valueOf(obligationSchedule.APTS_Agreement__r.APTS_Sold_To__c), lstTempVolumeObligation);
                         }
                    }
                   
                    
                    if(!mapAccountBuyingGroup.isEmpty()) 
                    {
                        if(!mapBuyingGrpObligationSchedule.isEmpty() && 
                        mapBuyingGrpObligationSchedule.ContainsKey(string.ValueOf(obligationSchedule.APTS_Agreement_Total_Volume_Obligation__r.APTS_Value__c) +
                        string.valueOf(obligationSchedule.APTS_Agreement__r.APTS_Sold_To__c)))
                        {
                            lstTempVolumeObligation = mapBuyingGrpObligationSchedule.get(string.ValueOf(obligationSchedule.APTS_Agreement_Total_Volume_Obligation__r.APTS_Value__c) +
                            string.valueOf(obligationSchedule.APTS_Agreement__r.APTS_Sold_To__c));
                             
                             
                            lstTempVolumeObligation.add(0, obligationSchedule);
                            mapBuyingGrpObligationSchedule.put(string.ValueOf(obligationSchedule.APTS_Agreement_Total_Volume_Obligation__r.APTS_Value__c) +
                            string.valueOf(obligationSchedule.APTS_Agreement__r.APTS_Sold_To__c), lstTempVolumeObligation);
                        }
                         
                        else
                        {
                            lstTempVolumeObligation.clear();
                            lstTempVolumeObligation.add(obligationSchedule);
                            
                            mapBuyingGrpObligationSchedule.put(string.ValueOf(obligationSchedule.APTS_Agreement_Total_Volume_Obligation__r.APTS_Value__c) +
                            string.valueOf(obligationSchedule.APTS_Agreement__r.APTS_Sold_To__c), lstTempVolumeObligation);
                        }
                    }
                }
                
                
               // loop through order line item, get combination of category and sold to id. 
               //if category and sold to combo is not matching, then get product combo.
               //if both are not present on child level, go to parent and grand parent. 
               //In all cases get buying group and add its active agreement with same Agreement type to volume obligation line item.
                Datetime fulfillmentDate;
                List<APTS_Agreement_Volume_Obligation_Line__c> agreementVolumeObligationLineItemsToUpsert = 
                   new List<APTS_Agreement_Volume_Obligation_Line__c>();
               
                for(Apttus_Config2__OrderLineItem__c orderLine : (List<Apttus_Config2__OrderLineItem__c>)mapOrderLineItems.values())
                {
                   
                    oldOrderLineItem = (Apttus_Config2__OrderLineItem__c)mapOldOrderLineItems.get(orderLine.Id);
                    agreementRecordType = (!mapAgreementRecordType.isEmpty() && mapAgreementRecordType.ContainsKey(orderLine.Apttus_CMConfig__AgreementId__c)) ? 
                    mapAgreementRecordType.get(orderLine.Apttus_CMConfig__AgreementId__c) : Null;
                    orderedQuantity = orderLine.Apttus_Config2__FulfilledQuantity__c != null ? orderLine.Apttus_Config2__FulfilledQuantity__c : 0;
                    orderInProgressQuantity = orderLine.Apttus_Config2__Quantity__c - orderedQuantity;
                    statusChanged = oldOrderLineItem.Apttus_Config2__Status__c != orderLine.Apttus_Config2__Status__c;
                    quantityDifference = (oldOrderLineItem != null && oldOrderLineItem.Apttus_Config2__FulfilledQuantity__c != null)
                                                 ? orderLine.Apttus_Config2__FulfilledQuantity__c - oldOrderLineItem.Apttus_Config2__FulfilledQuantity__c
                                                 : orderLine.Apttus_Config2__FulfilledQuantity__c;
                    Decimal sellingUomConversionRate=0;
                    
                    if(!setAgreementIds.isEmpty() && setAgreementIds.contains(orderLine.Apttus_CMConfig__AgreementId__c) && !setOLIs.isEmpty() && setOLIs.contains(orderLine.Id))
                    {
                        
                        tempAgreement = new List<APTS_AgreementVolumeObligation__c>();
                        if(!mapChildObligationSchedule.isEmpty() && 
                            (mapChildObligationSchedule.containsKey(string.ValueOf(orderLine.Apttus_Config2__ClassificationId__c) + 
                                               string.ValueOf(mapAgreementSoldTo.get(orderLine.Apttus_CMConfig__AgreementId__c)))|| 
                            mapChildObligationSchedule.containsKey(string.ValueOf(orderLine.Apttus_Config2__ProductId__c) + 
                                               string.ValueOf(mapAgreementSoldTo.get(orderLine.Apttus_CMConfig__AgreementId__c)))))
                        {
                            
                            tempAgreement =  orderLine.Apttus_Config2__ProductId__c!= Null && mapChildObligationSchedule.containsKey(string.ValueOf(orderLine.Apttus_Config2__ProductId__c) + 
                                               string.ValueOf(mapAgreementSoldTo.get(orderLine.Apttus_CMConfig__AgreementId__c))) ? mapChildObligationSchedule.get(string.ValueOf(orderLine.Apttus_Config2__ProductId__c) + 
                                               string.ValueOf(mapAgreementSoldTo.get(orderLine.Apttus_CMConfig__AgreementId__c)))
                                               : mapChildObligationSchedule.get(string.ValueOf(orderLine.Apttus_Config2__ClassificationId__c) + 
                                               string.ValueOf(mapAgreementSoldTo.get(orderLine.Apttus_CMConfig__AgreementId__c)));
                            
                         }
                         //v110 starts here
                        if(!mapChildObligationSchedule.isEmpty() && (!mapOLICategory.isEmpty() && mapOLICategory.get(orderLine.Id).Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c != Null &&
                            mapChildObligationSchedule.containsKey(string.ValueOf(mapOLICategory.get(orderLine.Id).Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c) + 
                            string.ValueOf(mapAgreementSoldTo.get(orderLine.Apttus_CMConfig__AgreementId__c)))))
                        {
                            tempAgreement = mapChildObligationSchedule.get(string.ValueOf(mapOLICategory.get(orderLine.Id).Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c) + 
                                               string.ValueOf(mapAgreementSoldTo.get(orderLine.Apttus_CMConfig__AgreementId__c)));
                        }
                         //v110 ends here
                         //If no volume obligation is present at child level, check for same in parent and grand parent level.
                        else if(!mapParentObligationSchedule.isEmpty() && 
                                (mapParentObligationSchedule.containsKey(string.ValueOf(orderLine.Apttus_Config2__ClassificationId__c) + 
                                    mapAccountParent.get(string.ValueOf(mapAgreementSoldTo.get(orderLine.Apttus_CMConfig__AgreementId__c))))
                                    || mapParentObligationSchedule.containsKey(string.ValueOf(orderLine.Apttus_Config2__ProductId__c) + 
                                               mapAccountParent.get(string.ValueOf(mapAgreementSoldTo.get(orderLine.Apttus_CMConfig__AgreementId__c))))))
                            {
                               
                                tempAgreement = mapParentObligationSchedule.containsKey(string.ValueOf(orderLine.Apttus_Config2__ProductId__c) + 
                                               mapAccountParent.get(string.ValueOf(mapAgreementSoldTo.get(orderLine.Apttus_CMConfig__AgreementId__c)))) 
                                               ?
                                               mapParentObligationSchedule.get(string.ValueOf(orderLine.Apttus_Config2__ProductId__c) + 
                                               mapAccountParent.get(string.ValueOf(mapAgreementSoldTo.get(orderLine.Apttus_CMConfig__AgreementId__c))))
                                               :
                                               mapParentObligationSchedule.get(string.ValueOf(orderLine.Apttus_Config2__ClassificationId__c) + 
                                               mapAccountParent.get(string.ValueOf(mapAgreementSoldTo.get(orderLine.Apttus_CMConfig__AgreementId__c))));
                            }
                            //v110 starts here
                            else if(!mapParentObligationSchedule.isEmpty() && 
                                !mapOLICategory.isEmpty() && mapOLICategory.get(mapOLICategory.get(orderLine.Id).Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c)!= Null &&
                                mapParentObligationSchedule.containsKey(string.ValueOf(mapOLICategory.get(orderLine.Id).Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c) + 
                                    mapAccountParent.get(string.ValueOf(mapAgreementSoldTo.get(orderLine.Apttus_CMConfig__AgreementId__c)))))
                            {
                                tempAgreement = mapParentObligationSchedule.get(string.ValueOf(mapOLICategory.get(orderLine.Id).Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c) + 
                                                 mapAccountParent.get(string.ValueOf(mapAgreementSoldTo.get(orderLine.Apttus_CMConfig__AgreementId__c))));  
                            }
                            //v110 ends here
                            //Correction required. Grand parent obligation schedule should have its own account id and down also update.
                            else if(!mapGParentbligationSchedule.isEmpty() && 
                                (mapGParentbligationSchedule.containsKey(string.ValueOf(orderLine.Apttus_Config2__ClassificationId__c) + 
                                               mapAccountGrandParent.get(string.ValueOf(mapAgreementSoldTo.get(orderLine.Apttus_CMConfig__AgreementId__c)))) || 
                                 mapGParentbligationSchedule.containsKey(string.ValueOf(orderLine.Apttus_Config2__ProductId__c) + 
                                               mapAccountGrandParent.get(string.ValueOf(mapAgreementSoldTo.get(orderLine.Apttus_CMConfig__AgreementId__c))))))
                            {
                                tempAgreement = mapGParentbligationSchedule.ContainsKey(string.ValueOf(orderLine.Apttus_Config2__ProductId__c) + 
                                               mapAccountGrandParent.get(string.ValueOf(mapAgreementSoldTo.get(orderLine.Apttus_CMConfig__AgreementId__c))))
                                               ?
                                               mapGParentbligationSchedule.get(string.ValueOf(orderLine.Apttus_Config2__ProductId__c) + 
                                               mapAccountGrandParent.get(string.ValueOf(mapAgreementSoldTo.get(orderLine.Apttus_CMConfig__AgreementId__c)))) 
                                               :
                                               mapGParentbligationSchedule.get(string.ValueOf(orderLine.Apttus_Config2__ClassificationId__c) + 
                                               mapAccountGrandParent.get(string.ValueOf(mapAgreementSoldTo.get(orderLine.Apttus_CMConfig__AgreementId__c))));                       
                            
                            }
                            //v110 starts here
                            else if(!mapGParentbligationSchedule.isEmpty() && !mapOLICategory.isEmpty() && mapOLICategory.get(orderLine.Id).Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c!= Null &&
                                mapGParentbligationSchedule.containsKey(string.ValueOf(mapOLICategory.get(orderLine.Id).Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c) + 
                                               mapAccountGrandParent.get(string.ValueOf(mapAgreementSoldTo.get(orderLine.Apttus_CMConfig__AgreementId__c)))))
                                
                                
                            {
                                tempAgreement = mapGParentbligationSchedule.get(string.ValueOf(mapOLICategory.get(orderLine.Id).Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c) + 
                                               mapAccountGrandParent.get(string.ValueOf(mapAgreementSoldTo.get(orderLine.Apttus_CMConfig__AgreementId__c))));  
                            }
                            //v110 ends here
                            //Check wither the account is having buying group. If its present, then create volume obligation line item for that as well.
                            if(!mapBuyingGrpObligationSchedule.isEmpty() && 
                                (mapBuyingGrpObligationSchedule.containsKey(string.ValueOf(orderLine.Apttus_Config2__ClassificationId__c) + 
                                               mapAccountBuyingGroup.get(string.ValueOf(mapAgreementSoldTo.get(orderLine.Apttus_CMConfig__AgreementId__c)))) || 
                                mapBuyingGrpObligationSchedule.containsKey(string.ValueOf(orderLine.Apttus_Config2__ProductId__c) + 
                                               mapAccountBuyingGroup.get(string.ValueOf(mapAgreementSoldTo.get(orderLine.Apttus_CMConfig__AgreementId__c))))) || 
                                 //v110 starts here
                                mapBuyingGrpObligationSchedule.containsKey(string.ValueOf(mapOLICategory.get(orderLine.Id).Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c) + 
                                               mapAccountBuyingGroup.get(string.ValueOf(mapAgreementSoldTo.get(orderLine.Apttus_CMConfig__AgreementId__c)))))
                                 //v110 ends here
                                               
                            {
                               
                                if(mapBuyingGrpObligationSchedule.containsKey(string.ValueOf(orderLine.Apttus_Config2__ProductId__c) + 
                                               mapAccountBuyingGroup.get(string.ValueOf(mapAgreementSoldTo.get(orderLine.Apttus_CMConfig__AgreementId__c)))))
                                {
                                    tempAgreement.addAll(mapBuyingGrpObligationSchedule.get(string.ValueOf(orderLine.Apttus_Config2__ProductId__c) + 
                                               mapAccountBuyingGroup.get(string.ValueOf(mapAgreementSoldTo.get(orderLine.Apttus_CMConfig__AgreementId__c)))));
                                }
                               //v110 - Updated from else to else if. Added condtion to check whether classification id is present, if not get from Sub category
                                else if(mapBuyingGrpObligationSchedule.containsKey(string.ValueOf(orderLine.Apttus_Config2__ClassificationId__c) + 
                                               mapAccountBuyingGroup.get(string.ValueOf(mapAgreementSoldTo.get(orderLine.Apttus_CMConfig__AgreementId__c)))))
                                {
                                    tempAgreement.addAll(mapBuyingGrpObligationSchedule.get(string.ValueOf(orderLine.Apttus_Config2__ClassificationId__c) + 
                                               mapAccountBuyingGroup.get(string.ValueOf(mapAgreementSoldTo.get(orderLine.Apttus_CMConfig__AgreementId__c)))));
                                  
                                }
                               //v110 starts here
                                else
                                {
                                    tempAgreement.addAll(mapBuyingGrpObligationSchedule.get(string.ValueOf(mapOLICategory.get(orderLine.Id).Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c) + 
                                               mapAccountBuyingGroup.get(string.ValueOf(mapAgreementSoldTo.get(orderLine.Apttus_CMConfig__AgreementId__c)))));
                                  
                                }
                               //v110 ends here
                            }
                            
                            fulfillmentDate = orderLine.Apttus_Config2__FulfilledDate__c != null ? orderLine.Apttus_Config2__FulfilledDate__c : Date.today();
                            
                            if(!tempAgreement.isEmpty())
                            {
                                for(APTS_AgreementVolumeObligation__c volumeObligation : tempAgreement)
                                {
                                    
                                    
                                    if(mapAgreementRecordType.get(volumeObligation.APTS_Agreement__c) == 
                                        mapAgreementRecordType.get(orderLine.Apttus_CMConfig__AgreementId__c))
                                    {
                                        if(volumeObligation.APTS_Start_Date__c <= fulfillmentDate && 
                                            volumeObligation.APTS_End_Date__c >= fulfillmentDate && 
                                            !(mapOrders.get(
                                            orderLine.Apttus_Config2__OrderId__c
                                            ).APTS_Order_Sub_Type__c.equals('Unplanned Return') || 
                                            mapOrders.get(
                                            orderLine.Apttus_Config2__OrderId__c
                                            ).APTS_Order_Sub_Type__c.equals('Standard Return')) &&
                                            (orderLine.APTS_Returned_Quantity__c == Null || orderLine.APTS_Returned_Quantity__c <=0) )
                                        {
                                            agreementVolumeObligationLineItem = new APTS_Agreement_Volume_Obligation_Line__c();
                                            agreementVolumeObligationLineItem.APTS_Order_Line_Item__c = orderLine.Id;
                                            agreementVolumeObligationLineItem.APTS_Agreement_Volume_Obligation__c = volumeObligation.Id;
                                            agreementVolumeObligationLineItem.APTS_Agreement__c=volumeObligation.APTS_Agreement__c;
                                            agreementVolumeObligationLineItem.APTS_Fulfillment_Date__c = DateTime.now();
                                            if(volumeObligation.APTS_Unit_of_Measure__c!=null && orderLine.APTS_Replaced_Product_Code__c != null){
                                                //get UOM converted value for line item based on volume obligation UOM
                                                //26-10-2018 RM. Replace APTS_CPQConstants.PIECE_UOM_API with the selling UOM.
                                                String uomKey = orderLine.APTS_Replaced_Product_Code__c+';'+ orderLine.Apttus_Config2__SellingUom__c +';'+volumeObligation.APTS_Unit_of_Measure__c;
                                                if(uomAPIResponseMap.containsKey(uomKey) && uomAPIResponseMap.get(uomKey) != null){
                                                    sellingUomConversionRate = uomAPIResponseMap.get(uomKey);
                                                }
                                            }
                                            if(orderLine.APTS_Order_Sub_Type_Formula__c != STOCK_COUNT){
                                                agreementVolumeObligationLineItem.APTS_Ordered_Quantity__c = sellingUomConversionRate > 0 ? orderedQuantity * sellingUomConversionRate : orderedQuantity;
                                                agreementVolumeObligationLineItem.APTS_Order_In_Progress_Quantity__c = sellingUomConversionRate > 0 ? orderInProgressQuantity * sellingUomConversionRate : orderInProgressQuantity;
                                            }
                                            agreementVolumeObligationLineItemsToUpsert.add(agreementVolumeObligationLineItem);
                                        }
                                        else if(volumeObligation.APTS_Start_Date__c <= fulfillmentDate && 
                                            volumeObligation.APTS_End_Date__c >= fulfillmentDate && 
                                            orderLine.Apttus_Config2__Status__c.equals(ACTIVATED) 
                                            && ((mapOrders.get(
                                            orderLine.Apttus_Config2__OrderId__c
                                            ).APTS_Order_Sub_Type__c.equals('Standard Return') && 
                                            orderLine.APTS_Returned_Quantity__c > 0) || 
                                            (mapOrders.get(
                                            orderLine.Apttus_Config2__OrderId__c
                                            ).APTS_Order_Sub_Type__c.equals('Unplanned Return') 
                                            && (orderLine.Apttus_Config2__Quantity__c > 0 || 
                                            orderLine.APTS_Returned_Quantity__c > 0))))
                                        {
                                            agreementVolumeObligationLineItem = new APTS_Agreement_Volume_Obligation_Line__c();
                                            agreementVolumeObligationLineItem.APTS_Order_Line_Item__c = orderLine.Id;
                                            agreementVolumeObligationLineItem.APTS_Agreement_Volume_Obligation__c = volumeObligation.Id;
                                            agreementVolumeObligationLineItem.APTS_Fulfillment_Date__c = DateTime.now();
                                            if(volumeObligation.APTS_Unit_of_Measure__c!=null && orderLine.APTS_Replaced_Product_Code__c != null){
                                                //get UOM converted value for line item based on volume obligation UOM
                                                //26-10-2018 RM. Replace APTS_CPQConstants.PIECE_UOM_API with the selling UOM.
                                                String uomKey = orderLine.APTS_Replaced_Product_Code__c+';'+ orderLine.Apttus_Config2__SellingUom__c +';'+volumeObligation.APTS_Unit_of_Measure__c;
                                                if(uomAPIResponseMap.containsKey(uomKey) && uomAPIResponseMap.get(uomKey) != null){
                                                    sellingUomConversionRate = uomAPIResponseMap.get(uomKey);
                                                }
                                            }
                                            if(sellingUomConversionRate > 0){
                                            agreementVolumeObligationLineItem.APTS_Ordered_Quantity__c = orderLine.APTS_Returned_Quantity__c > 0 ? 
                                                                                                        -orderLine.APTS_Returned_Quantity__c * sellingUomConversionRate : 
                                                                                                        -orderLine.Apttus_Config2__Quantity__c * sellingUomConversionRate;
                                            }
                                            else{
                                            agreementVolumeObligationLineItem.APTS_Ordered_Quantity__c = orderLine.APTS_Returned_Quantity__c > 0 ? 
                                                                                                        -orderLine.APTS_Returned_Quantity__c : 
                                                                                                        -orderLine.Apttus_Config2__Quantity__c;
                                            }
                                            agreementVolumeObligationLineItem.APTS_Order_In_Progress_Quantity__c = 0;
                                            agreementVolumeObligationLineItemsToUpsert.add(agreementVolumeObligationLineItem);
                                        }
                                        
                                    }
                                }
                            }
                            //make the records inactive for which order line item already exist.
                            for(APTS_Agreement_Volume_Obligation_Line__c lineItem : lstAgreementLineItem)
                            {
                                if(lineItem.APTS_Order_Line_Item__c == orderLine.Id)
                                {
                                    lineItem.APTS_Inactive__c = True;
                                    agreementVolumeObligationLineItemsToUpsert.add(lineItem);
                                }
                            }
                        }
                    } 
                    if(!agreementVolumeObligationLineItemsToUpsert.isEmpty())
                    {
                        listSaveResult = Database.UPSERT(agreementVolumeObligationLineItemsToUpsert);
                        logError(null,null,listSaveResult,null,APEX,AGREEMNTVOLOBLIGATIONLINE,EMPTY_STRING,false,false,EMPTY_STRING,false);
                    }  
                }
            }
            catch(exception ex){
                logError(null,null,null,ex,APEX,AGREEMNTVOLOBLIGATIONLINE,EMPTY_STRING,false,false,EMPTY_STRING,true);
            }
        }
        
        /********************************* FOR CONTRACT HIERARCHY  ***********************************/
        /* 
        * Method to create Error Log
        * This method Will enter an entry in APTS_Error_Object__c whenever an expection happended during Runtime
        */
        public static void logError(Database.DeleteResult[] drList, Database.SaveResult[] insertedList, 
                                                Database.UpsertResult[] upsertListRec, Exception ex,String errorType,String objectName,String objectId,Boolean reprocess, Boolean notify,String recipients, Boolean isErrorNeedtobeLogged){
            List<APTS_Error_Object__c> lstErrorObject = new List<APTS_Error_Object__c>();
            //Log Upserted Error Record
            if(upsertListRec != null){
                for(Database.UpsertResult upsertList : upsertListRec){
                   if (!upsertList.isSuccess()){
                       for(Database.Error err : upsertList.getErrors()) 
                       {
                           lstErrorObject.add(APTS_CustomLogging.createErrorLog(UPSERTEXCEPTION,errorType,err.getMessage(), 
                           objectName,objectId,STREAM,reprocess,notify,recipients,false));
                       }
                    }   
                }
            }
            
            //Log inserted Error Record
            if(insertedList != null){
                for( Database.SaveResult saveReslt : insertedList){
                   if (!saveReslt.isSuccess()){
                       for(Database.Error err : saveReslt.getErrors()){
                           lstErrorObject.add(APTS_CustomLogging.createErrorLog(INSERTEXCEPTION,errorType,err.getMessage(), 
                           objectName,objectId,STREAM,reprocess,notify,recipients,false));
                       }
                    }   
                }
            }
            //Log Deleted Error Record
            if(drList != null){
                for( Database.DeleteResult deleteList : drList){
                   if (!deleteList.isSuccess()){
                       for(Database.Error err : deleteList.getErrors()){
                           lstErrorObject.add(APTS_CustomLogging.createErrorLog(DELETEEXCEPTION,errorType,err.getMessage(), 
                           objectName,objectId,STREAM,reprocess,notify,recipients,false));
                        }
                    }   
                }
            }
            
            if(!lstErrorObject.isEmpty()){
                Database.insert(lstErrorObject,false);
            }else{
                if(ex != null){
                    APTS_CustomLogging.createErrorLog(ex.getTypeName(),errorType,LINENUMBER+String.valueof(ex.getLineNumber())+COLON+ex.getMessage(), 
                           objectName,objectId,STREAM,reprocess,notify,recipients,true);
                }
            }
        }
        /* 
        * Method to Remove Billing Block for an order
        * This method Will submit the orders to SAP and also activate Invoicing at SAP side
        */
        public static List<Integration_Log__c> removeBillingBlockForStandardOrders(List<SObject> newList, Map<Id,SObject> newItems, List<SObject> oldList, Map<Id,SObject> oldItems){
            Map<Id, Apttus_Config2__Order__c> newOrderMap = (Map<Id, Apttus_Config2__Order__c>) newItems;
            Map<Id, Apttus_Config2__Order__c> oldOrderMap = (Map<Id, Apttus_Config2__Order__c>) oldItems;
            //Set<Id> orderToSAPInvoicing = new Set<Id>();
            //Set<Id> agreementIdSet = new Set<Id>();
            Set<Id> billingPrefId = new Set<Id>();
            Set<Id> paymentTermIdSet= new Set<Id>();
            //Map<Id, Apttus__APTS_Agreement__c> agreementMap = new Map<Id, Apttus__APTS_Agreement__c>();
            Map<Id, Apttus_Config2__BillingPreference__c> billPrefMap = new Map<Id, Apttus_Config2__BillingPreference__c>();
            Map<Id, Apttus_Config2__PaymentTerm__c> paymentTermMap= new Map<Id, Apttus_Config2__PaymentTerm__c>();
            List<Integration_Log__c> integrationLogListToInsert = new List<Integration_Log__c>();
            //List<string> fixedTermTypeList = new List<string>();
            try{
                
                // v107 ==> Restrict the submission of Fixed Term Order created during Cart Finalization to SAP  STarts
                // Extract the agreement for orders
                for(Apttus_Config2__Order__c oOrder : newOrderMap.values()){
                    if (!ACTIVATED.equalsIgnoreCase(oldOrderMap.get(oOrder.Id).Apttus_Config2__Status__c)
                            && ACTIVATED.equalsIgnoreCase(oOrder.Apttus_Config2__Status__c)){
                        /*if(oOrder.Apttus_CMConfig__AgreementId__c != null
                            && DEBITSAPORDERTYPE.equalsIgnoreCase(oOrder.APTS_SAP_OrderType__c)){
                            agreementIdSet.add(oOrder.Apttus_CMConfig__AgreementId__c);
                        }*/
                        if(oOrder.Apttus_Config2__BillingPreferenceId__c != null){
                            billingPrefId.add(oOrder.Apttus_Config2__BillingPreferenceId__c);
                        }
                        if(string.isNotBlank(oOrder.Apttus_Config2__PaymentTermId__c) && DIGITALSAPORDERTYPE.equalsIgnoreCase(oOrder.APTS_SAP_OrderType__c)
                            && String.isNotBlank(oOrder.APTS_Prepaid_Flag__c) && PREPAIDFLAG_YES.equalsIgnoreCase(oOrder.APTS_Prepaid_Flag__c)){
                            paymentTermIdSet.add(oOrder.Apttus_Config2__PaymentTermId__c);
                        }
                    }
                }
                /*if(!agreementIdSet.isEmpty()){
                    String fixedTermType = System.Label.APTS_FixedTermType;
                    if(String.isNotBlank(fixedTermType)){
                        fixedTermTypeList = fixedTermType.split(',');
                    }
                    for(Apttus__APTS_Agreement__c agreement : [SELECT Id,
                                                                      APTS_Fixed_Term_Type__c
                                                                    FROM  Apttus__APTS_Agreement__c 
                                                                    WHERE Id IN : agreementIdSet
                                                                    ]){
                        if(agreement.APTS_Fixed_Term_Type__c != null
                            && fixedTermTypeList.contains(agreement.APTS_Fixed_Term_Type__c)){
                                agreementMap.put(agreement.Id,agreement);
                        }
                    }
                }*/
                // Retrieve respective Billing Prefernce ID
                if(!billingPrefId.isEmpty()){
                    
                    for(Apttus_Config2__BillingPreference__c billingPreference : [SELECT Id,
                                                                                        Apttus_Config2__BillingCycleStart__c,
                                                                                        Apttus_Config2__BillingDayOfMonth2__c
                                                                                    FROM  Apttus_Config2__BillingPreference__c 
                                                                                    WHERE Id IN : billingPrefId
                                                                                    ]){
                        billPrefMap.put(billingPreference.Id,billingPreference);
                    }
                }
                if(!paymentTermIdSet.isEmpty()){
                    for(Apttus_Config2__PaymentTerm__c paymentTerm: [SELECT Id, APTS_Ext_ID__c FROM  Apttus_Config2__PaymentTerm__c
                                                                                    WHERE Id IN : paymentTermIdSet
                                                                                    ]){
                        if(string.isNotBlank(paymentTerm.APTS_Ext_ID__c)){
                            paymentTermMap.put(paymentTerm.Id,paymentTerm);
                        }
                    }
                }
                // v107 ==> Restrict the submission of Fixed Term Order created during Cart Finalization to SAP  ENDS
                for(Apttus_Config2__Order__c oOrder : newOrderMap.values()){
                    if (!ACTIVATED.equalsIgnoreCase(oldOrderMap.get(oOrder.Id).Apttus_Config2__Status__c)
                        && ACTIVATED.equalsIgnoreCase(oOrder.Apttus_Config2__Status__c)){
                        // Set Billing Date
                        //v114Starts Here- Defect 23202 Setting Billing date for Digital order
                        if(string.isNotBlank(oOrder.APTS_SAP_OrderType__c) && DIGITALSAPORDERTYPE.equalsIgnoreCase(oOrder.APTS_SAP_OrderType__c)
                            && String.isNotBlank(oOrder.APTS_Prepaid_Flag__c) && PREPAIDFLAG_YES.equalsIgnoreCase(oOrder.APTS_Prepaid_Flag__c)
                            && String.isNotBlank(oOrder.Apttus_Config2__PaymentTermId__c) && paymentTermMap.containsKey(oOrder.Apttus_Config2__PaymentTermId__c)
                            && DIGITALORDER_PAYMENTTERM.equalsIgnoreCase(paymentTermMap.get(oOrder.Apttus_Config2__PaymentTermId__c).APTS_Ext_ID__c)
                            && oOrder.Apttus_Config2__ActivatedDate__c != null){
                            oOrder.APTS_Billing_Date__c = oOrder.Apttus_Config2__ActivatedDate__c.date();
                        }//v114 Ends Here
                        else {
                            assignBillingDateToOrder(billPrefMap,oOrder);
                        }
                        //v104 starts here
                        if(string.isNotEmpty(oOrder.APTS_SAP_OrderType__c) 
                            && (oOrder.APTS_SAP_OrderType__c.containsIgnoreCase(XA) 
                                || oOrder.APTS_SAP_OrderType__c.containsIgnoreCase(XC)
                                || oOrder.APTS_SAP_OrderType__c.containsIgnoreCase(XD) 
                                || oOrder.APTS_SAP_OrderType__c.containsIgnoreCase(XL)) //v104 ends here
                                && !CONVERSIONORDER.equalsIgnoreCase(oOrder.APTS_Order_Sub_Type__c) //Added as part of v202
                                && !STOCKSAPORDERTYPE.equalsIgnoreCase(oOrder.APTS_SAP_OrderType__c)) {  //Added as part of v204
                            // v107 ==> Restrict the submission of Fixed Term Order created during Cart Finalization to SAP
                            if(!DEBITSAPORDERTYPE.equalsIgnoreCase(oOrder.APTS_SAP_OrderType__c)){
                                    //orderToSAPInvoicing.add(oOrder.Id);
                                    oOrder.APTS_Remove_Billing_Block_Indicator__c = true; 
                                    oOrder.APTS_Status__c = APTS_BIRUtils.INVOICINGSTATUS;
                                    integrationLogListToInsert.add(APTS_OrderUtils.createIntegrationLog(oOrder));
                            }else{
                                if(DEBITSAPORDERTYPE.equalsIgnoreCase(oOrder.APTS_SAP_OrderType__c)
                                    /*&& !agreementMap.containsKey(oOrder.Apttus_CMConfig__AgreementId__c)*/){ // Not Fixed Term Order
                                        oOrder.APTS_Remove_Billing_Block_Indicator__c = true; 
                                        oOrder.APTS_Status__c = APTS_BIRUtils.INVOICINGSTATUS;
                                        if(oOrder.Apttus_Config2__ActivatedDate__c != null){
                                            oOrder.APTS_Billing_Date__c = oOrder.Apttus_Config2__ActivatedDate__c.date();
                                        }
                                        integrationLogListToInsert.add(APTS_OrderUtils.createIntegrationLog(oOrder));      
                                }  
                            }
                        }
                    }
                }
            }catch(Exception e){
                APTS_BIRUtils.logError(null,null,null,null,APTS_BIRUtils.TRIGGERVALUE,REMOVEBILLINGBLOCKMETHOD,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,true);
                return null;
            }
            return integrationLogListToInsert;
        }
        
        //v112 Starts here
        /*For Consumption model counter data. When order line item is updated with Physical Asset, then its corresponding counter data has 
        to be updated with relavent data. */
        /* 
        * Method : updateCounterReading()
        * This method Will update Asset counter reading data with fields on Order Line item's population with Physical Asset.
        * Author: Beulah Ann Thomas
        */
        public static void updateCounterReadingWithPhysicalAsset(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldItems)
        {
            Set<Id> setAgreementLineItems = new Set<Id>();
            Map<Id, Apttus_Config2__OrderLineItem__c> mapNewOrderLine = (Map<Id, Apttus_Config2__OrderLineItem__c>)newItems;
            Map<Id, Apttus_Config2__OrderLineItem__c> mapNewOrderLines = New Map<Id, Apttus_Config2__OrderLineItem__c>();
            Map<Id, Id> mapOrderToPhysicalAsset = new Map<Id, Id>();
            Map<Id, String> mapConsumptionDetail = new Map<Id, String>();
            Map<Id, List<APTS_CounterReadingData__c>> mapCounterReading = new Map<Id, List<APTS_CounterReadingData__c>>();
            Map<Id, Apttus_Config2__OrderLineItem__c> mapOldOrderLine = (Map<Id, Apttus_Config2__OrderLineItem__c>) oldItems;
            List<APTS_CounterReadingData__c> lstCounterReading = new List<APTS_CounterReadingData__c>();
            List<APTS_CounterReadingData__c> lstTempCounterReading;
            String ConsumptionDetailName;
            APTS_CounterReadingData__c newCounterReading;
            Map<Id, Apttus_Config2__OrderLineItem__c> mapOrderNPhysicalAsset = new Map<Id, Apttus_Config2__OrderLineItem__c>();
            Map<Id, Apttus_Config2__OrderLineItem__c> mapNewOrderData = new Map<Id, Apttus_Config2__OrderLineItem__c>();
            Map<Id, PhysicalAsset__c> mapPhysicalAsset = new Map<Id, PhysicalAsset__c>();
            PhysicalAsset__c tempPhysicalAsset;
            Set<Id> L1IdSet = new Set<Id>();
            Set<Id> OrderIdSet = new Set<Id>();
            List<Apttus_Config2__OrderLineItem__c> oliNewList = new List<Apttus_Config2__OrderLineItem__c>();
            List<WorkOrderLineItem> workOLIList = new List<WorkOrderLineItem>();
            //WorkOrderLineItem tempWorkOLI;
            //Integer sequenceNumber = 0;
            string CONSUMPTION = 'Consumption Categories';
            try
            {
                Set<Id> setRefurbishedPhAIDs = new Set<Id>();
                //Identify the L1 OLI and its Order's Type and Sub Type
                for(Apttus_Config2__OrderLineItem__c orderLine : (List<Apttus_Config2__OrderLineItem__c>)newList){
                    if(orderLine.APTS_Is_Primary_L1_Line__c && orderLine.APTS_Physical_Asset__c != null && orderLine.APTS_Physical_Asset__c != mapOldOrderLine.get(orderLine.Id).APTS_Physical_Asset__c){
                        L1IdSet.add(orderLine.Id);
                        OrderIdSet.add(orderLine.Apttus_Config2__OrderId__c);
                        //V213 ++ <<
                        if(orderLine.APTS_RefurbishedMachine__c != null && orderLine.APTS_RefurbishedMachine__c)
                            setRefurbishedPhAIDs.add(orderLine.APTS_Physical_Asset__c);
                        //V213 ++ >>
                    }
                }
                //V213 ++ <<
                if(!setRefurbishedPhAIDs.isEmpty())
                {
                    APTS_OrderUtils.deactivateExistingCounters(setRefurbishedPhAIDs);
                }
                //V213 ++ >>
                if(!L1IdSet.isEmpty()){
                    for(Apttus_Config2__OrderLineItem__c oli : [SELECT Id, APTS_Physical_Asset__r.SerialNumber__c, APTS_Physical_Asset__r.UniqueNumber__c, Apttus_Config2__Status__c, Apttus_Config2__OptionId__c,
                        Apttus_Config2__AttributeValueId__r.APTS_Type_of_Consumption__c, APTS_Physical_Asset__c, APTS_Option_Group_Text__c, Apttus_CMConfig__AgreementLineItemId__c, APTS_Is_Primary_L1_Parent__c,
                        Apttus_Config2__OrderId__c, Apttus_Config2__OrderId__r.APTS_Order_Type__c, Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c, Apttus_Config2__AssetLineItemId__c,
                        (Select id, WorkOrderType__c, OrderLineItem__c from Work_Order_Line_Items__r) 
                        FROM Apttus_Config2__OrderLineItem__c 
                        WHERE Apttus_Config2__OrderId__c IN: OrderIdSet ]){
                        if((L1IdSet.contains(oli.Id) || L1IdSet.contains(oli.APTS_Is_Primary_L1_Parent__c)) && oli.Apttus_Config2__OrderId__r.APTS_Order_Type__c == MACHINE_ORDER && oli.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c == INSTALLATION){
                            oliNewList.add(oli);
                        }
                        //Check if any Work Order Line Items Exists of Type S40
                        if(oli.Work_Order_Line_Items__r != null){
                            for(WorkOrderLineItem woli : oli.Work_Order_Line_Items__r){
                                if(woli.WorkOrderType__c == S40){
                                    woli.SendCounterReadings__c = true;
                                    workOLIList.add(woli);
                                }
                            }
                        }
                    }
                }
    
                for(Apttus_Config2__OrderLineItem__c orderLine : oliNewList)
                {               
                    if(CONSUMPTION.equalsIgnoreCase(orderLine.APTS_Option_Group_Text__c) && 
                       orderLine.Apttus_CMConfig__AgreementLineItemId__c!= NULL)
                   {
                       setAgreementLineItems.add(orderLine.Apttus_CMConfig__AgreementLineItemId__c);
                       mapNewOrderLines.put(orderLine.Id, orderLine);
                       mapNewOrderData.put(orderLine.Id, orderLine);
                   }
                   if(orderLine.APTS_Physical_Asset__c != null)
                       {
                           mapOrderNPhysicalAsset.put(orderLine.Id, orderLine);
                       }
                    
                }
                
                if(!setAgreementLineItems.isEmpty())
                {
                
                    for(Apttus_Config2__OrderLineItem__c orderLine : mapOrderNPhysicalAsset.values())
                    {
                        mapPhysicalAsset.put(orderLine.APTS_Physical_Asset__c, orderLine.APTS_Physical_Asset__r);  
                        mapOrderToPhysicalAsset.put(orderLine.Id, orderLine.APTS_Physical_Asset__c);
                    }                  
                    
                    for(APTS_CounterReadingData__c counterReading : [SELECT Id, APTS_AgreementLineItem__c, APTS_Asset_Line_Item__c,
                                                                    TS_Physical_Asset__c, APTS_Machine_Serial_No__c, APTS_ConsumerPrice__c,
                                                                    APTS_PriceType__c, APTS_CounterSequence__c, 
                                                                    APTS_Consumption_Group_ID__c, 
                                                                    APTS_Consumption_Group_ID__r.APTS_Consumption_Detail__r.Name, APTS_Grammages_Chocolate__c,
                                                                    APTS_Grammages_Coffee__c, APTS_Grammages_Decaf__c, APTS_Grammages_Milk__c, APTS_Grammages_Soup__c,
                                                                    APTS_Grammages_Sugar__c, APTS_Grammages_Tea__c, APTS_Cup_Size__c, APTS_Charge_Type__c,
                                                                    CurrencyIsoCode, APTS_LineItem__c
                                                                    FROM APTS_CounterReadingData__c 
                                                                    WHERE APTS_AgreementLineItem__c IN : setAgreementLineItems ])
                    {
                        lstTempCounterReading = new List<APTS_CounterReadingData__c>();
                        
                        if(!mapCounterReading.isEmpty() && mapCounterReading.containsKey(counterReading.APTS_AgreementLineItem__c))
                        {
                            lstTempCounterReading = mapCounterReading.get(counterReading.APTS_AgreementLineItem__c);
                            lstTempCounterReading.add(counterReading);
                        }
                        else
                        {
                            lstTempCounterReading.add(counterReading);
                        }
                        mapCounterReading.put(counterReading.APTS_AgreementLineItem__c, lstTempCounterReading);
                        mapConsumptionDetail.put(counterReading.APTS_AgreementLineItem__c, 
                        counterReading.APTS_Consumption_Group_ID__r.APTS_Consumption_Detail__r.Name);
                    }
                    for(Apttus_Config2__OrderLineItem__c orderLine : mapNewOrderLines.values())
                    {                     
                        
                        if(!mapCounterReading.isEmpty() && mapCounterReading.containsKey(orderLine.Apttus_CMConfig__AgreementLineItemId__c) 
                        && !mapPhysicalAsset.isEmpty())
                        {
                            Boolean cloneFlag=true;
                            for(APTS_CounterReadingData__c tempCounterReading : mapCounterReading.get(orderLine.Apttus_CMConfig__AgreementLineItemId__c))
                            {
                                // Check if Physical Asset exist for the counter reading. If doesn't, then populate. Else clone the counter reading to create a new one
                                if(tempCounterReading.TS_Physical_Asset__c == null){
                                    cloneFlag=false;
                                    tempCounterReading.TS_Physical_Asset__c = orderLine.APTS_Is_Primary_L1_Parent__c != NULL ? 
                                                                                  mapOrderToPhysicalAsset.get(orderLine.APTS_Is_Primary_L1_Parent__c) : 
                                                                                  orderLine.APTS_Physical_Asset__c;
    
                                    ConsumptionDetailName = !mapConsumptionDetail.isEmpty() && 
                                                       mapConsumptionDetail.containsKey(
                                                       orderLine.Apttus_CMConfig__AgreementLineItemId__c) ? 
                                                       mapConsumptionDetail.get(
                                                       orderLine.Apttus_CMConfig__AgreementLineItemId__c) : 
                                                       EMPTY_STRING;
                                                                           
                                    if(mapPhysicalAsset.containsKey(tempCounterReading.TS_Physical_Asset__c))
                                    {
    
                                       //tempCounterReading.APTS_Asset_Line_Item__c = orderLine.Apttus_Config2__AssetLineItemId__c;
                                       tempCounterReading.APTS_Machine_Serial_No__c = mapPhysicalAsset.get(
                                                           tempCounterReading.TS_Physical_Asset__c).UniqueNumber__c; 
                                       tempCounterReading.APTS_Counter_Status__c = ACTIVE_COUNTER;                                               
                                       //v102 starts here
                                       if(!mapNewOrderData.isEmpty() && mapNewOrderData.containsKey(orderLine.Id)){
                                            String assetLIPriceType =  mapNewOrderData.get(orderLine.Id).Apttus_Config2__AttributeValueId__r.APTS_Type_of_Consumption__c;
                                            if(assetLIPriceType != null && assetLIPriceType!=''){
                                                tempCounterReading.APTS_PriceType__c = assetLIPriceType == FREE_VEND ? FREE : assetLIPriceType;
                                                }
                                            }
                                        //v102 ends here
                                       lstCounterReading.add(tempCounterReading);  
                                    }
                                }
                            }                                                                                 
    
                           //v113 Starts here
                           if(cloneFlag && mapCounterReading.containsKey(orderLine.Apttus_CMConfig__AgreementLineItemId__c)){
                            //Clone the existing counter data as per FD 3741
                            for(APTS_CounterReadingData__c tempCounterReading: mapCounterReading.get(orderLine.Apttus_CMConfig__AgreementLineItemId__c)){
                                if(tempCounterReading.TS_Physical_Asset__c == mapCounterReading.get(orderLine.Apttus_CMConfig__AgreementLineItemId__c)[0].TS_Physical_Asset__c ){
    
                                    newCounterReading = new APTS_CounterReadingData__c();
    
                                    newCounterReading.TS_Physical_Asset__c = orderLine.APTS_Is_Primary_L1_Parent__c != NULL ? 
                                                                                      mapOrderToPhysicalAsset.get(orderLine.APTS_Is_Primary_L1_Parent__c) : 
                                                                                      orderLine.APTS_Physical_Asset__c;
                                    newCounterReading.APTS_AgreementLineItem__c = tempCounterReading.APTS_AgreementLineItem__c;
                                    newCounterReading.APTS_Consumption_Group_ID__c = tempCounterReading.APTS_Consumption_Group_ID__c;
                                    newCounterReading.APTS_ConsumerPrice__c = tempCounterReading.APTS_ConsumerPrice__c;
                                    newCounterReading.APTS_Machine_Serial_No__c = mapPhysicalAsset.containsKey(newCounterReading.TS_Physical_Asset__c) ? mapPhysicalAsset.get(
                                                                                                                        newCounterReading.TS_Physical_Asset__c).UniqueNumber__c : null;
                                    newCounterReading.APTS_PriceType__c = tempCounterReading.APTS_PriceType__c;
                                    newCounterReading.APTS_CounterSequence__c = tempCounterReading.APTS_CounterSequence__c;
                                    newCounterReading.APTS_Grammages_Chocolate__c = tempCounterReading.APTS_Grammages_Chocolate__c;
                                    newCounterReading.APTS_Grammages_Coffee__c = tempCounterReading.APTS_Grammages_Coffee__c;
                                    newCounterReading.APTS_Grammages_Decaf__c = tempCounterReading.APTS_Grammages_Decaf__c;
                                    newCounterReading.APTS_Grammages_Milk__c = tempCounterReading.APTS_Grammages_Milk__c;
                                    newCounterReading.APTS_Grammages_Soup__c = tempCounterReading.APTS_Grammages_Soup__c;
                                    newCounterReading.APTS_Grammages_Sugar__c = tempCounterReading.APTS_Grammages_Sugar__c;
                                    newCounterReading.APTS_Grammages_Tea__c = tempCounterReading.APTS_Grammages_Tea__c;
                                    newCounterReading.APTS_Cup_Size__c = tempCounterReading.APTS_Cup_Size__c;
                                    newCounterReading.APTS_Charge_Type__c = tempCounterReading.APTS_Charge_Type__c;
                                    newCounterReading.CurrencyIsoCode = tempCounterReading.CurrencyIsoCode;
                                    newCounterReading.APTS_LineItem__c = tempCounterReading.APTS_LineItem__c;
                                    //v210 Added for defect DFT2C-1820
                                    newCounterReading.APTS_Counter_Status__c = ACTIVE_COUNTER;
    
                                    lstCounterReading.add(newCounterReading);
                                    }
                                }
                           }  
                        //v113 Ends here   
                        }       
                    }
                    if(!lstCounterReading.isEmpty())
                    {
                        Database.UPSERT(lstCounterReading);
                    } 
                    if(!workOLIList.isEmpty())
                    {
                        Database.UPDATE(workOLIList);
                    } 
                }
            }
            catch(Exception ex)
            {
                logError(null,null,null,ex,TRIGGERVALUE,'CounterReading',EMPTY_STRING,false,false,EMPTY_STRING,false);
            }        
        }
        //v112 Ends here
        
        /* 
        * Method : cloneCounterReading()
        * This method Will For machine breakdown, an asset line item will be updated with status amended or existing,
        * for such records counter reading data for older asset line item should be cloned and in the
        * newly created counter reading data, new asset line item has to be updated .
        * Author: Beulah Ann Thomas
        */
        public static void cloneCounterReading(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldItems)
        {
            
            Map<Id, Id> mapOldNewPhysicalAsset = new Map<Id, Id>();
            Map<Id, Apttus_Config2__AssetLineItem__c> mapNewAssetLine = (Map<Id, Apttus_Config2__AssetLineItem__c>)newItems;
            Map<Id, Apttus_Config2__AssetLineItem__c> mapNewAssetLines = new Map<Id, Apttus_Config2__AssetLineItem__c>();
            Map<Id, Id> mapAssetToPhysicalAsset = new Map<Id, Id>();
            Map<Id, APTS_CounterReadingData__c> mapCounterReading = new Map<Id, APTS_CounterReadingData__c>();
            List<APTS_CounterReadingData__c> lstCounterReading = new List<APTS_CounterReadingData__c>();
            APTS_CounterReadingData__c clonedCounterReading; 
            Map<Id, Apttus_Config2__AssetLineItem__c> mapOldAssetLine = (Map<Id, Apttus_Config2__AssetLineItem__c>)oldItems;
            
            try
            {
                
                for(Apttus_Config2__AssetLineItem__c assetLine : (List<Apttus_Config2__AssetLineItem__c>)newList)
                {
                    if(('Amended'.equalsIgnoreCase(assetLine.Apttus_Config2__AssetStatus__c) || 
                       'Existing'.equalsIgnoreCase(assetLine.Apttus_Config2__AssetStatus__c)) &&
                       //assetLine.Apttus_Config2__OptionId__c != NULL && 
                       'Consumption Categories'.equalsIgnoreCase(assetLine.APTS_Option_Group_Text__c) && 
                       mapOldAssetLine.get(assetLine.Id).APTS_Physical_Asset__c != NULL && 
                       mapOldAssetLine.get(assetLine.Id).APTS_Physical_Asset__c != assetLine.APTS_Physical_Asset__c
                       )
                   {
                       
                       mapNewAssetLines.put(assetLine.Id, assetLine);
                       
                       if(assetLine.APTS_Physical_Asset__c != Null)
                       {
                           mapOldNewPhysicalAsset.put(mapOldAssetLine.get(assetLine.Id).APTS_Physical_Asset__c, 
                           assetLine.APTS_Physical_Asset__c);
                           mapAssetToPhysicalAsset.put(assetLine.Id, assetLine.APTS_Physical_Asset__c);
                       }
                      
                   } 
                }
                if(!mapAssetToPhysicalAsset.isEmpty())
                {
                    Map<Id, Apttus_Config2__AssetLineItem__c> mapAssetNPhysicalAsset = new Map<Id, Apttus_Config2__AssetLineItem__c>([
                        SELECT Id, Apttus_Config2__BundleAssetId__c, APTS_Physical_Asset__r.SerialNumber__c, APTS_Physical_Asset__r.UniqueNumber__c, 
                    APTS_Physical_Asset__c FROM Apttus_Config2__AssetLineItem__c WHERE 
                    Apttus_Config2__BundleAssetId__c IN : mapNewAssetLines.values() ]);
                    
                    
                    Map<Id, PhysicalAsset__c> mapPhysicalAsset = new Map<Id, PhysicalAsset__c>(
                                        [SELECT Id, SerialNumber__c, UniqueNumber__c
                                         FROM PhysicalAsset__c
                                         WHERE Id IN : mapAssetToPhysicalAsset.Values() ]);
                    //v210 Begin - Added for defect DFT2C-1820 
                    for(APTS_CounterReadingData__c counterReading : [SELECT Id, APTS_AgreementLineItem__c, APTS_Asset_Line_Item__c,
                                                                        TS_Physical_Asset__c, APTS_Machine_Serial_No__c,
                                                                        APTS_PriceType__c, APTS_CounterSequence__c, 
                                                                        APTS_Consumption_Group_ID__c, 
                                                                        APTS_Consumption_Group_ID__r.APTS_Consumption_Detail__r.Name,
                                                                        APTS_ConsumerPrice__c,
                                                                        APTS_Grammages_Chocolate__c,
                                                                        APTS_Grammages_Coffee__c,
                                                                        APTS_Grammages_Milk__c,
                                                                        APTS_Grammages_Soup__c,
                                                                        APTS_Grammages_Sugar__c,
                                                                        APTS_Grammages_Tea__c,
                                                                        APTS_Cup_Size__c,
                                                                        APTS_Charge_Type__c,
                                                                        CurrencyIsoCode,
                                                                        APTS_LineItem__c
                                                                        FROM APTS_CounterReadingData__c 
                                                                        WHERE TS_Physical_Asset__c IN : mapOldNewPhysicalAsset.KeySet() ])
                    {
                        clonedCounterReading = counterReading.clone(false,true);
                        
                        clonedCounterReading.TS_Physical_Asset__c = mapOldNewPhysicalAsset.get(counterReading.TS_Physical_Asset__c);
                        
                        clonedCounterReading.APTS_Machine_Serial_No__c = !mapPhysicalAsset.isEmpty() && 
                                                                         mapPhysicalAsset.containsKey(
                                                                         mapAssetToPhysicalAsset.get(counterReading.APTS_Asset_Line_Item__c)) ?  
                                                                         mapPhysicalAsset.get(
                                                                         mapAssetToPhysicalAsset.get(counterReading.APTS_Asset_Line_Item__c)
                                                                         ).UniqueNumber__c : EMPTY_STRING;     
                        clonedCounterReading.APTS_Counter_Status__c = ACTIVE_COUNTER;   
                        //v210 End - Added for defect DFT2C-1820
                        lstCounterReading.add(clonedCounterReading);
                    }
                    if(!lstCounterReading.isEmpty())
                    {
                        Database.INSERT(lstCounterReading);
                    }                                                        
                }                                                         
            }
            catch(Exception ex)
            {
                logError(null,null,null,ex,TRIGGERVALUE,'COUNTERRREADING',EMPTY_STRING,false,false,EMPTY_STRING,false);
            }
        }
        
        /********************************* FOR EXTERNAL SUMMARY ORDER LINE  CONTRACT HIERARCHY  ***********************************/
        //v1.1 starts here
    
        /* 
        * Method : createVolumeOLIForExternalOLI()
        * Method Description: On creation of external orderline item it's corresponding volume obligation is searched 
        * Author: Beulah Ann Thomas
        */
        public static void createVolumeOLIForExternalOLI(List<SObject> newList, Map<Id, SObject> mapOrderLineItems)
        { 
            List<Database.UpsertResult> listSaveResult = new List<Database.UpsertResult>();
            //Map<Id, Apttus_Config2__ExternalOrderSummary__c> mapOrders = new Map<Id, Apttus_Config2__ExternalOrderSummary__c>();
            List<APTS_Error_Object__c> lstErrorObject = new List<APTS_Error_Object__c>();
            try
            {
            
            Set<Id> setAgreementIds = new Set<Id>();
            Set<Id> setExternalOrderIds = new Set<Id>();
            Set<Id> setEOLIFromInvoice = new Set<Id>(); //v111
            Boolean statusChanged;
            Decimal orderedQuantity; 
            Decimal quantityDifference;
            Decimal orderInProgressQuantity; 
            Apttus_Config2__ExternalOrderSummaryItem__c oldOrderLineItem;
            List<APTS_AgreementVolumeObligation__c> tempAgreement;
            List<APTS_AgreementVolumeObligation__c> lstTempVolumeObligation;
            List<APTS_AgreementVolumeObligation__c> lstVolumeObligation;
            APTS_Agreement_Volume_Obligation_Line__c agreementVolumeObligationLineItem;
            Map<Id, Id> mapAgreementSoldTo = new Map<Id, Id>();
            Map<Id, Id> mapOrderToAgreement = new Map<Id,Id>();
            //v111 starts here
            Map<Id, Id> mapEOLIFromSelloutData = new Map<Id, Id>();
            //v111 ends here
            Map<ID,Apttus_Config2__FrequencyConversionRate__c> uomConversionMap= new Map<ID,Apttus_Config2__FrequencyConversionRate__c>();
            Set<String> uomAPIParamSet = new Set<String>();        
            //Map of all agreement and its record types.
            Map<Id, String> mapAgreementRecordType = new Map<Id, String>();
            String agreementRecordType = '';
            
            
            List<APTS_Agreement_Volume_Obligation_Line__c> lstAgreementLineItem = new List<APTS_Agreement_Volume_Obligation_Line__c>();
            List<APTS_Agreement_Volume_Obligation_Line__c> lstVolumeObligationLine = new List<APTS_Agreement_Volume_Obligation_Line__c>();
            
            
            Set<Id> setSoldToIds = new Set<Id>();
            
            for(Apttus_Config2__ExternalOrderSummaryItem__c lineItem : (List<Apttus_Config2__ExternalOrderSummaryItem__c>)mapOrderLineItems.values())
            {
                if(//lineItem.Apttus_Config2__Status__c.equals(ACTIVATED) && 
                lineItem.Apttus_Config2__Quantity__c != Null && 
                lineItem.Apttus_Config2__Quantity__c > 0 && lineItem.Apttus_Config2__ProductId__c!= Null)
                {
                    //setAgreementIds.add(lineItem.Apttus_CMConfig__AgreementId__c);
                    setExternalOrderIds.add(lineItem.Apttus_Config2__OrderSummaryId__c);
                }
    
                //creating set for Selling UOM
                if(lineItem.APTS_Product_Code__c != null){
                    //26-10-2018 RM. Replace APTS_CPQConstants.PIECE_UOM_API with the selling UOM.
                    uomAPIParamSet.add(lineitem.APTS_Product_Code__c+';'+ lineitem.Apttus_Config2__SellingUom__c +';'+DRINKS);
                    uomAPIParamSet.add(lineitem.APTS_Product_Code__c+';'+ lineitem.Apttus_Config2__SellingUom__c +';'+LITER);
                    uomAPIParamSet.add(lineitem.APTS_Product_Code__c+';'+ lineitem.Apttus_Config2__SellingUom__c +';'+KILOGRAMS);
                }
            }
            //Created map for UOM table | gets all UOM table records matching with line item pricing UOM and selling UOM
            //26-10-2018 RM. Use the method to obtain the appropriate conversion rate.
            Map<String,Decimal> uomAPIResponseMap = APTS_UOMConversionUtils.getUOMConversions(uomAPIParamSet);
            
            /*//Created map for UOM table | gets all UOM table records matching with line item pricing UOM and selling UOM
                    for( Apttus_Config2__FrequencyConversionRate__c freqConversion : [select id,Apttus_Config2__FromUom__c,Apttus_Config2__ToUom__c,Apttus_Config2__ProductFamily__c,Apttus_Config2__ConversionFactor__c,Apttus_Config2__ProductId__c,APTS_ProductCode__c from Apttus_Config2__FrequencyConversionRate__c where Apttus_Config2__ToUom__c IN : toUOMSet and Apttus_Config2__FromUom__c =: APTS_CPQConstants.PIECE_UOM_API and APTS_ProductCode__c IN: prodCodeSet]){
                        if(uomConversionMap.get(freqConversion.id)==null){
                            uomConversionMap.put(freqConversion.id,freqConversion);
                        }
                    }*/
            
            for(Apttus_Config2__ExternalOrderSummary__c externalOrder : [SELECT Id, APTS_Calculate_Rebate_On__c, Apttus_CMConfig__AgreementId__c, Apttus_CMConfig__AgreementId__r.RecordTypeId, 
                    Apttus_CMConfig__AgreementId__r.APTS_Sold_To__c 
                    FROM Apttus_Config2__ExternalOrderSummary__c 
                    WHERE Id IN : setExternalOrderIds 
                    //v111 starts here
                    AND APTS_Calculate_Rebate_On__c !=: JDEINVOICE ])
                    //v111 ends here
                    
            {
                setAgreementIds.add(externalOrder.Apttus_CMConfig__AgreementId__c);
                mapAgreementRecordType.put(externalOrder.Apttus_CMConfig__AgreementId__c, externalOrder.Apttus_CMConfig__AgreementId__r.RecordTypeId);
                mapAgreementSoldTo.put(externalOrder.Apttus_CMConfig__AgreementId__c, externalOrder.Apttus_CMConfig__AgreementId__r.APTS_Sold_To__c);
                setSoldToIds.add(externalOrder.Apttus_CMConfig__AgreementId__r.APTS_Sold_To__c);
                mapOrderToAgreement.put(externalOrder.Id, externalOrder.Apttus_CMConfig__AgreementId__c);
                //v111 starts here
                if(SELLOUT.equalsIgnoreCase(externalOrder.APTS_Calculate_Rebate_On__c)){
                    mapEOLIFromSelloutData.put(externalOrder.Id, externalOrder.Apttus_CMConfig__AgreementId__c);
                }
                //v111 ends here
                
            }
            if(!setAgreementIds.isEmpty())
            {
                
                
            
            Map<String, List<APTS_AgreementVolumeObligation__c>> mapChildObligationSchedule = new Map<String, List<APTS_AgreementVolumeObligation__c>>();
            Map<String, List<APTS_AgreementVolumeObligation__c>> mapParentObligationSchedule = new Map<String, List<APTS_AgreementVolumeObligation__c>>();
            Map<String, List<APTS_AgreementVolumeObligation__c>> mapGParentbligationSchedule = new Map<String, List<APTS_AgreementVolumeObligation__c>>();
            Map<String, List<APTS_AgreementVolumeObligation__c>> mapBuyingGrpObligationSchedule = new Map<String, List<APTS_AgreementVolumeObligation__c>>();
            
            //Get the hierarchy from account.
            Map<Id, APTS_CERUtility.AccountHierarchy> mapAccountHierarchy = new Map<Id, APTS_CERUtility.AccountHierarchy>();
            Map<Id, Id> mapAccountParent = new Map<Id, Id>();
            Map<Id, Id> mapAccountGrandParent = new Map<Id, Id>();
            Map<Id, Id> mapAccountBuyingGroup = new Map<Id, Id>();
                    
            
            //Query record type of agreement for which order line item is created.
            
            
            mapAccountHierarchy = APTS_CERUtility.getAccountHierarchy(setSoldToIds);
            for(Id accountID : mapAccountHierarchy.keySet())
            {
                
                if(mapAccountHierarchy.get(accountID ).parentId != Null)  
                {
                    mapAccountParent.put(accountID, mapAccountHierarchy.get(accountID ).parentId);   
                }
                if(mapAccountHierarchy.get(accountID ).grandParentId != Null)  
                { 
                    mapAccountGrandParent.put(accountID, mapAccountHierarchy.get(accountID ).grandParentId);   
                }
                
                if(mapAccountHierarchy.get(accountID ).buyingGroupId!= Null)  
                {
                    mapAccountBuyingGroup.put(accountID, mapAccountHierarchy.get(accountID ).buyingGroupId);   
                }
            }
                
                //Query obligation schedule which are created for child, parent, and grand parent accounts
                for(APTS_AgreementVolumeObligation__c obligationSchedule : [SELECT Id, APTS_Agreement__c, APTS_Agreement_Total_Volume_Obligation__c,
                                                                            APTS_Agreement_Total_Volume_Obligation__r.APTS_Value__c, 
                                                                            APTS_Agreement_Total_Volume_Obligation__r.APTS_IncludeSelloutData__c, 
                                                                            APTS_End_Date__c, APTS_Start_Date__c, APTS_Value_Name__c, APTS_Type__c, 
                                                                            APTS_Agreement__r.RecordtypeId, APTS_Agreement__r.APTS_Sold_To__c, APTS_Unit_of_Measure__c
                                                                            FROM APTS_AgreementVolumeObligation__c 
                                                                            WHERE (APTS_Agreement__r.APTS_Sold_To__c IN: setSoldToIds 
                                                                            OR APTS_Agreement__r.APTS_Sold_To__c IN : mapAccountParent.values()
                                                                            OR APTS_Agreement__r.APTS_Sold_To__c IN : mapAccountGrandParent.values()
                                                                            OR APTS_Agreement__r.APTS_Sold_To__c IN : mapAccountBuyingGroup.values()) 
                                                                            AND APTS_Status__c != 'Closed'
                                                                            AND APTS_Agreement__r.Apttus__Status_Category__c='In Effect' 
                                                                            AND APTS_Agreement__r.Apttus__Status__c='Activated' Limit :(Limits.getLimitQueryRows() - Limits.getQueryRows())
                                                                            ])
                {
                    mapAgreementRecordType.put(obligationSchedule.APTS_Agreement__c, obligationSchedule.APTS_Agreement__r.RecordTypeId);
                    lstTempVolumeObligation = new List<APTS_AgreementVolumeObligation__c>();
                    lstVolumeObligation = new List<APTS_AgreementVolumeObligation__c>();
                    
                    //If volume obligation schedules are present for the same account itself, then it would be mapped in this statement.
                    if(setSoldToIds.contains(obligationSchedule.APTS_Agreement__r.APTS_Sold_To__c))
                    {
                         if(!mapChildObligationSchedule.isEmpty() && 
                         mapChildObligationSchedule.ContainsKey(string.ValueOf(obligationSchedule.APTS_Agreement_Total_Volume_Obligation__r.APTS_Value__c) +
                         string.valueOf(obligationSchedule.APTS_Agreement__r.APTS_Sold_To__c)))
                         {
                             lstVolumeObligation = mapChildObligationSchedule.get(string.ValueOf(obligationSchedule.APTS_Agreement_Total_Volume_Obligation__r.APTS_Value__c) +
                             string.valueOf(obligationSchedule.APTS_Agreement__r.APTS_Sold_To__c));
                             
                             
                             lstTempVolumeObligation.add(obligationSchedule);
                             mapChildObligationSchedule.put(string.ValueOf(obligationSchedule.APTS_Agreement_Total_Volume_Obligation__r.APTS_Value__c) +
                             string.valueOf(obligationSchedule.APTS_Agreement__r.APTS_Sold_To__c), lstVolumeObligation );
                         }
                         else
                         {
                             lstVolumeObligation.add(obligationSchedule);
                             mapChildObligationSchedule.put(string.ValueOf(obligationSchedule.APTS_Agreement_Total_Volume_Obligation__r.APTS_Value__c) +
                             string.valueOf(obligationSchedule.APTS_Agreement__r.APTS_Sold_To__c), lstVolumeObligation);
                         }
                    }
                    
                    if(!mapAccountParent.isEmpty())  
                    {
                        if(!mapParentObligationSchedule.isEmpty() && 
                         mapParentObligationSchedule.ContainsKey(string.ValueOf(obligationSchedule.APTS_Agreement_Total_Volume_Obligation__r.APTS_Value__c) +
                         string.valueOf(obligationSchedule.APTS_Agreement__r.APTS_Sold_To__c)))
                         {
                             lstTempVolumeObligation = mapParentObligationSchedule.get(string.ValueOf(obligationSchedule.APTS_Agreement_Total_Volume_Obligation__r.APTS_Value__c) +
                             string.valueOf(obligationSchedule.APTS_Agreement__r.APTS_Sold_To__c));
                             
                             
                             lstTempVolumeObligation.add(obligationSchedule);
                             mapParentObligationSchedule.put(string.ValueOf(obligationSchedule.APTS_Agreement_Total_Volume_Obligation__r.APTS_Value__c) +
                             string.valueOf(obligationSchedule.APTS_Agreement__r.APTS_Sold_To__c), lstTempVolumeObligation);
                         }
                        
                        else
                        {
                            //Add parent account and all its relavent volume obligation schedule.
                            lstTempVolumeObligation.add(obligationSchedule);
                            mapParentObligationSchedule.put(string.ValueOf(obligationSchedule.APTS_Agreement_Total_Volume_Obligation__r.APTS_Value__c) +
                             string.valueOf(obligationSchedule.APTS_Agreement__r.APTS_Sold_To__c), lstTempVolumeObligation);
                         }
                    }
                    
                    
                    if(!mapAccountGrandParent.isEmpty())  
                    {
                    
                        if(!mapGParentbligationSchedule.isEmpty() && 
                         mapGParentbligationSchedule.ContainsKey(string.ValueOf(obligationSchedule.APTS_Agreement_Total_Volume_Obligation__r.APTS_Value__c) +
                         string.valueOf(obligationSchedule.APTS_Agreement__r.APTS_Sold_To__c)))
                         {
                             lstTempVolumeObligation = mapGParentbligationSchedule.get(string.ValueOf(obligationSchedule.APTS_Agreement_Total_Volume_Obligation__r.APTS_Value__c) +
                             string.valueOf(obligationSchedule.APTS_Agreement__r.APTS_Sold_To__c));
                             
                             
                             lstTempVolumeObligation.add(obligationSchedule);
                             mapGParentbligationSchedule.put(string.ValueOf(obligationSchedule.APTS_Agreement_Total_Volume_Obligation__r.APTS_Value__c) +
                             string.valueOf(obligationSchedule.APTS_Agreement__r.APTS_Sold_To__c), lstTempVolumeObligation);
                         }
                        else
                        {
                            lstTempVolumeObligation.clear();
                            lstTempVolumeObligation.add(obligationSchedule);
                            mapGParentbligationSchedule.put(string.ValueOf(obligationSchedule.APTS_Agreement_Total_Volume_Obligation__r.APTS_Value__c) +
                             string.valueOf(obligationSchedule.APTS_Agreement__r.APTS_Sold_To__c), lstTempVolumeObligation);
                         }
                         
                    }
                   
                    
                    if(!mapAccountBuyingGroup.isEmpty()) 
                    {
                        if(!mapBuyingGrpObligationSchedule.isEmpty() && 
                         mapBuyingGrpObligationSchedule.ContainsKey(string.ValueOf(obligationSchedule.APTS_Agreement_Total_Volume_Obligation__r.APTS_Value__c) +
                         string.valueOf(obligationSchedule.APTS_Agreement__r.APTS_Sold_To__c)))
                         {
                             lstTempVolumeObligation = mapBuyingGrpObligationSchedule.get(string.ValueOf(obligationSchedule.APTS_Agreement_Total_Volume_Obligation__r.APTS_Value__c) +
                             string.valueOf(obligationSchedule.APTS_Agreement__r.APTS_Sold_To__c));
                             
                             
                             lstTempVolumeObligation.add(0, obligationSchedule);
                             mapBuyingGrpObligationSchedule.put(string.ValueOf(obligationSchedule.APTS_Agreement_Total_Volume_Obligation__r.APTS_Value__c) +
                             string.valueOf(obligationSchedule.APTS_Agreement__r.APTS_Sold_To__c), lstTempVolumeObligation);
                         }
                         
                        else
                        {
                            lstTempVolumeObligation.clear();
                            lstTempVolumeObligation.add(obligationSchedule);
                            
                            mapBuyingGrpObligationSchedule.put(string.ValueOf(obligationSchedule.APTS_Agreement_Total_Volume_Obligation__r.APTS_Value__c) +
                             string.valueOf(obligationSchedule.APTS_Agreement__r.APTS_Sold_To__c), lstTempVolumeObligation);
                         }
                    }
                    
                         
                }
                
                
                
               // loop through order line item, get combination of category and sold to id. 
               //if category and sold to combo is not matching, then get product combo.
               //if both are not present on child level, go to parent and grand parent. 
               //In all cases get buying group and add its active agreement with same Agreement type to volume obligation line item.
               Datetime fulfillmentDate;
               List<APTS_Agreement_Volume_Obligation_Line__c> agreementVolumeObligationLineItemsToUpsert = 
                   new List<APTS_Agreement_Volume_Obligation_Line__c>();
               
               for(Apttus_Config2__ExternalOrderSummaryItem__c orderLine : (List<Apttus_Config2__ExternalOrderSummaryItem__c>)mapOrderLineItems.values())
               {
                   
                   oldOrderLineItem = (Apttus_Config2__ExternalOrderSummaryItem__c)mapOrderLineItems.get(orderLine.Id);
                   agreementRecordType = (!mapAgreementRecordType.isEmpty() && mapAgreementRecordType.ContainsKey(
                   mapOrderToAgreement.get(orderLine.Apttus_Config2__OrderSummaryId__c))) ? 
                   mapAgreementRecordType.get(mapOrderToAgreement.get(orderLine.Apttus_Config2__OrderSummaryId__c)) : Null;
                   
                   orderedQuantity = orderLine.Apttus_Config2__Quantity__c != null ? orderLine.Apttus_Config2__Quantity__c : 0;
                  
                    if(!setAgreementIds.isEmpty() && setAgreementIds.contains(mapOrderToAgreement.get(orderLine.Apttus_Config2__OrderSummaryId__c)))
                    {
                        
                        tempAgreement = new List<APTS_AgreementVolumeObligation__c>();
                        if(!mapChildObligationSchedule.isEmpty())
                        {
                                                    
                            tempAgreement =  orderLine.Apttus_Config2__ProductId__c != Null && mapChildObligationSchedule.containsKey(string.ValueOf(orderLine.Apttus_Config2__ProductId__c) + 
                                               string.ValueOf(mapAgreementSoldTo.get(mapOrderToAgreement.get(orderLine.Apttus_Config2__OrderSummaryId__c)))) ? 
                                               mapChildObligationSchedule.get(string.ValueOf(orderLine.Apttus_Config2__ProductId__c) + 
                                               string.ValueOf(mapAgreementSoldTo.get(mapOrderToAgreement.get(orderLine.Apttus_Config2__OrderSummaryId__c))))
                                               : //v111 starts here
                                               orderLine.APTS_SubSubCategoryClassificationId__c != Null && mapChildObligationSchedule.containsKey(string.ValueOf(orderLine.APTS_SubSubCategoryClassificationId__c) + 
                                               string.ValueOf(mapAgreementSoldTo.get(mapOrderToAgreement.get(orderLine.Apttus_Config2__OrderSummaryId__c)))) ? 
                                               mapChildObligationSchedule.get(string.ValueOf(orderLine.APTS_SubSubCategoryClassificationId__c) + 
                                               string.ValueOf(mapAgreementSoldTo.get(mapOrderToAgreement.get(orderLine.Apttus_Config2__OrderSummaryId__c))))
                                               :
                                               orderLine.APTS_SubCategoryClassificationId__c != Null && mapChildObligationSchedule.containsKey(string.ValueOf(orderLine.APTS_SubCategoryClassificationId__c) + 
                                               string.ValueOf(mapAgreementSoldTo.get(mapOrderToAgreement.get(orderLine.Apttus_Config2__OrderSummaryId__c)))) ? 
                                               mapChildObligationSchedule.get(string.ValueOf(orderLine.APTS_SubCategoryClassificationId__c) + 
                                               string.ValueOf(mapAgreementSoldTo.get(mapOrderToAgreement.get(orderLine.Apttus_Config2__OrderSummaryId__c)))) : Null;
                                               //v111 ends here
                         }
                         //If no volume obligation is present at child level, check for same in parent and grand parent level.
                            else if(!mapParentObligationSchedule.isEmpty()) {
                               
                                tempAgreement = mapParentObligationSchedule.containsKey(string.ValueOf(orderLine.Apttus_Config2__ProductId__c) + 
                                               mapAccountParent.get(string.ValueOf(mapAgreementSoldTo.get(
                                               mapOrderToAgreement.get(orderLine.Apttus_Config2__OrderSummaryId__c))))) ?
                                               mapParentObligationSchedule.get(string.ValueOf(orderLine.Apttus_Config2__ProductId__c) + mapAccountParent.get(string.ValueOf(mapAgreementSoldTo.get(mapOrderToAgreement.get(orderLine.Apttus_Config2__OrderSummaryId__c))))) 
                                               //v111 starts here
                                               : orderLine.APTS_SubSubCategoryClassificationId__c != Null && mapParentObligationSchedule.containsKey(string.ValueOf(orderLine.APTS_SubSubCategoryClassificationId__c) + mapAccountParent.get(string.ValueOf(mapAgreementSoldTo.get(mapOrderToAgreement.get(orderLine.Apttus_Config2__OrderSummaryId__c))))) ? 
                                               mapParentObligationSchedule.get(string.ValueOf(orderLine.APTS_SubSubCategoryClassificationId__c) + mapAccountParent.get(string.ValueOf(mapAgreementSoldTo.get(mapOrderToAgreement.get(orderLine.Apttus_Config2__OrderSummaryId__c)))))
                                               : orderLine.APTS_SubCategoryClassificationId__c != Null && mapParentObligationSchedule.containsKey(string.ValueOf(orderLine.APTS_SubCategoryClassificationId__c) + mapAccountParent.get(string.ValueOf(mapAgreementSoldTo.get(mapOrderToAgreement.get(orderLine.Apttus_Config2__OrderSummaryId__c))))) ? 
                                               mapParentObligationSchedule.get(string.ValueOf(orderLine.APTS_SubCategoryClassificationId__c) + mapAccountParent.get(string.ValueOf(mapAgreementSoldTo.get(mapOrderToAgreement.get(orderLine.Apttus_Config2__OrderSummaryId__c))))) : Null;
                                               //v111 ends here;
                            }
                            //Correction required. Grand parent obligation schedule should have its own account id and down also update.
                        else if(!mapGParentbligationSchedule.isEmpty()){ 
                                tempAgreement = mapGParentbligationSchedule.ContainsKey(string.ValueOf(orderLine.Apttus_Config2__ProductId__c) + mapAccountGrandParent.get(string.ValueOf(mapAgreementSoldTo.get(mapOrderToAgreement.get(orderLine.Apttus_Config2__OrderSummaryId__c)))))
                                               ?mapGParentbligationSchedule.get(string.ValueOf(orderLine.Apttus_Config2__ProductId__c) + mapAccountGrandParent.get(string.ValueOf(mapAgreementSoldTo.get(mapOrderToAgreement.get(orderLine.Apttus_Config2__OrderSummaryId__c))))) 
                                               : //v111 starts here
                                               orderLine.APTS_SubSubCategoryClassificationId__c != Null && mapGParentbligationSchedule.containsKey(string.ValueOf(orderLine.APTS_SubSubCategoryClassificationId__c) + mapAccountGrandParent.get(string.ValueOf(mapAgreementSoldTo.get(mapOrderToAgreement.get(orderLine.Apttus_Config2__OrderSummaryId__c))))) ? 
                                               mapGParentbligationSchedule.get(string.ValueOf(orderLine.APTS_SubSubCategoryClassificationId__c) + mapAccountGrandParent.get(string.ValueOf(mapAgreementSoldTo.get(mapOrderToAgreement.get(orderLine.Apttus_Config2__OrderSummaryId__c)))))
                                               :
                                               orderLine.APTS_SubCategoryClassificationId__c != Null && mapGParentbligationSchedule.containsKey(string.ValueOf(orderLine.APTS_SubCategoryClassificationId__c) + mapAccountGrandParent.get(string.ValueOf(mapAgreementSoldTo.get(mapOrderToAgreement.get(orderLine.Apttus_Config2__OrderSummaryId__c))))) ? 
                                               mapGParentbligationSchedule.get(string.ValueOf(orderLine.APTS_SubCategoryClassificationId__c) + mapAccountGrandParent.get(string.ValueOf(orderLine.APTS_SubCategoryClassificationId__c))) : Null;
                                               //v111 ends here;                       
                            
                            }
                            //Check wither the account is having buying group. If its present, then create volume obligation line item for that as well.
                            if(!mapBuyingGrpObligationSchedule.isEmpty() && 
                            mapBuyingGrpObligationSchedule.containsKey(string.ValueOf(orderLine.Apttus_Config2__ProductId__c) + 
                                               mapAccountBuyingGroup.get(string.ValueOf(mapAgreementSoldTo.get(
                                               mapOrderToAgreement.get(orderLine.Apttus_Config2__OrderSummaryId__c))))))
                            {
    
                                   tempAgreement.addAll(mapBuyingGrpObligationSchedule.get(string.ValueOf(orderLine.Apttus_Config2__ProductId__c) + 
                                               mapAccountBuyingGroup.get(string.ValueOf(mapAgreementSoldTo.get(
                                               mapOrderToAgreement.get(orderLine.Apttus_Config2__OrderSummaryId__c))))));
                               
                            }
                            //v111 starts here
                            else if(!mapBuyingGrpObligationSchedule.isEmpty() && orderLine.APTS_SubSubCategoryClassificationId__c != Null && mapBuyingGrpObligationSchedule.containsKey(string.ValueOf(orderLine.APTS_SubSubCategoryClassificationId__c)+ mapAccountBuyingGroup.get(string.ValueOf(mapAgreementSoldTo.get(mapOrderToAgreement.get(orderLine.Apttus_Config2__OrderSummaryId__c)))))){
                                        
                                        
                                   tempAgreement.addAll(mapBuyingGrpObligationSchedule.get(string.ValueOf(orderLine.APTS_SubSubCategoryClassificationId__c) + 
                                               mapAccountBuyingGroup.get(string.ValueOf(mapAgreementSoldTo.get(
                                               mapOrderToAgreement.get(orderLine.Apttus_Config2__OrderSummaryId__c))))));
                               
                            }
                            else if(!mapBuyingGrpObligationSchedule.isEmpty() && orderLine.APTS_SubCategoryClassificationId__c != Null && mapBuyingGrpObligationSchedule.containsKey(string.ValueOf(orderLine.APTS_SubCategoryClassificationId__c) + mapAccountBuyingGroup.get(string.ValueOf(mapAgreementSoldTo.get(mapOrderToAgreement.get(orderLine.Apttus_Config2__OrderSummaryId__c)))))){
                                   tempAgreement.addAll(mapBuyingGrpObligationSchedule.get(string.ValueOf(orderLine.APTS_SubCategoryClassificationId__c) + 
                                               mapAccountBuyingGroup.get(string.ValueOf(mapAgreementSoldTo.get(
                                               mapOrderToAgreement.get(orderLine.Apttus_Config2__OrderSummaryId__c))))));
                               
                            }
                            //v111 ends here
                            if(!tempAgreement.isEmpty())
                            {
                                for(APTS_AgreementVolumeObligation__c volumeObligation : tempAgreement)
                                {
    
                                    if(mapAgreementRecordType.get(volumeObligation.APTS_Agreement__c).equalsIgnoreCase(mapAgreementRecordType.get(mapOrderToAgreement.get(orderLine.Apttus_Config2__OrderSummaryId__c)))  
                                      //v111 starts here
                                       &&(mapEOLIFromSelloutData.isEmpty() || !mapEOLIFromSelloutData.containsKey(orderLine.Apttus_Config2__OrderSummaryId__c) || (volumeObligation.APTS_Agreement_Total_Volume_Obligation__r.APTS_IncludeSelloutData__c == True && mapEOLIFromSelloutData.containsKey(orderLine.Apttus_Config2__OrderSummaryId__c)))){
                                      //v111 ends here
                                        if(volumeObligation.APTS_Start_Date__c <= orderLine.Apttus_Config2__PeriodStartDate__c && volumeObligation.APTS_End_Date__c >= orderLine.Apttus_Config2__PeriodEndDate__c && orderLine.Apttus_Config2__Quantity__c >=0){
                                            agreementVolumeObligationLineItem = new APTS_Agreement_Volume_Obligation_Line__c();
                                            
                                            //agreementVolumeObligationLineItem.APTS_Order_Line_Item__c = orderLine.Id;
                                            agreementVolumeObligationLineItem.APTS_External_Order_Line_Item__c = orderLine.Id;
                                            agreementVolumeObligationLineItem.APTS_Agreement_Volume_Obligation__c = volumeObligation.Id;
                                            agreementVolumeObligationLineItem.APTS_Agreement__c=volumeObligation.APTS_Agreement__c;
                                            agreementVolumeObligationLineItem.APTS_Fulfillment_Date__c = DateTime.now();
                                            Decimal sellingUomConversionRate=0;
                                            if(volumeObligation.APTS_Unit_of_Measure__c!=null && orderLine.APTS_Product_Code__c != null){
                                                //get UOM converted value for line item based on volume obligation UOM
                                                //26-10-2018 RM. Replace APTS_CPQConstants.PIECE_UOM_API with the selling UOM.
                                                String uomKey = orderLine.APTS_Product_Code__c+';'+ orderLine.Apttus_Config2__SellingUom__c +';'+volumeObligation.APTS_Unit_of_Measure__c;
                                                if(uomAPIResponseMap.containsKey(uomKey) && uomAPIResponseMap.get(uomKey) != null){
                                                    sellingUomConversionRate = uomAPIResponseMap.get(uomKey);
                                                }
                                            }
                                            agreementVolumeObligationLineItem.APTS_Ordered_Quantity__c = sellingUomConversionRate > 0 ? orderLine.Apttus_Config2__Quantity__c * sellingUomConversionRate : orderLine.Apttus_Config2__Quantity__c;
                                            agreementVolumeObligationLineItem.APTS_Order_In_Progress_Quantity__c = 0;
                                            
                                            agreementVolumeObligationLineItemsToUpsert.add(agreementVolumeObligationLineItem);
                                        }
                                    }
                                }
                            }
                        }
                    } 
                   if(!agreementVolumeObligationLineItemsToUpsert.isEmpty())
                   {
                      listSaveResult = Database.UPSERT(agreementVolumeObligationLineItemsToUpsert);
                      logError(null,null,listSaveResult,null,APEX,AGREEMNTVOLOBLIGATIONLINE,EMPTY_STRING,false,false,EMPTY_STRING,false);
                   }  
                }
            }
           catch(exception ex)
           {
               
               logError(null,null,null,ex,APEX,AGREEMNTVOLOBLIGATIONLINE,EMPTY_STRING,false,false,EMPTY_STRING,true);
           }
        
        }
        /********************************* FOR EXTERNAL SUMMARY ORDER LINE  CONTRACT HIERARCHY  ENDS ***********************************/
        /* 
        * Method : addLeadingZeros()
        * Method Description: To add leading zeros for a string
        * Author: Balashanthi A
        */
        public static String addLeadingZeros(String salesDocumentNumber, Integer maxLength){
            String tempValue = salesDocumentNumber;
            Integer originalLength = maxLength - salesDocumentNumber.length();
            for (Integer i = 0; i<originalLength; i++) {
               tempValue = '0'+tempValue;   
            }
            return tempValue;
        }
        /** Method Name : getInvoiceDeliveryPreferenceMapping
        * Description : Method to build and return invoice Delivery preference mapping
        **/
        public static Map<String, String> getInvoiceDeliveryPreferenceMapping(){
            
            Map<String, String> invoiceDeliveryPreferenceMap = new Map<String, String>();
            for(APTS_Invoice_Delivery_Preference__mdt meta : [SELECT Id, MasterLabel, APTS_Value__c FROM APTS_Invoice_Delivery_Preference__mdt ]){
                invoiceDeliveryPreferenceMap.put(meta.MasterLabel, meta.APTS_Value__c);
            }
            return invoiceDeliveryPreferenceMap;
        }
    
        
        /* Method Name : updateCounterReading()
        * To update Asset LI on corresponding Counter Reading Data Record based on Agreement LI
        */
    
        public static void updateCounterReading(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldItems)
        {
            Map<Id, List<Apttus_Config2__AssetLineItem__c>> mapAgreementLIAssetLIMap = New Map<Id, List<Apttus_Config2__AssetLineItem__c>>();
            Map<Id, Apttus_Config2__AssetLineItem__c> mapOldAssetLine = (Map<Id, Apttus_Config2__AssetLineItem__c>) oldItems;
            Map<Id, Id> assetPhysicalAssetMap = new Map<Id, Id>();
            Set<Id> consumptionAssetIdSet = new Set<Id>();
            List<APTS_CounterReadingData__c> lstCounterReading = new List<APTS_CounterReadingData__c>();
            string CONSUMPTION = 'Consumption Categories';
            try
            {
                
                for(Apttus_Config2__AssetLineItem__c assetLine : (List<Apttus_Config2__AssetLineItem__c>)newList)
                {
                     
                    if(mapOldAssetLine.get(assetLine.Id).Apttus_Config2__AssetStatus__c != 
                       assetLine.Apttus_Config2__AssetStatus__c && 
                        ACTIVATED.equalsIgnoreCase(assetLine.Apttus_Config2__AssetStatus__c) &&
                       CONSUMPTION.equalsIgnoreCase(assetLine.APTS_Option_Group_Text__c) && 
                       assetLine.Apttus_CMConfig__AgreementLineItemId__c!= NULL)
                   {
                       consumptionAssetIdSet.add(assetLine.Id);
                   }
                    
                }
    
                for(Apttus_Config2__AssetLineItem__c assetLine : [Select id,Apttus_Config2__BundleAssetId__c, Apttus_Config2__BundleAssetId__r.APTS_Physical_Asset__c, Apttus_CMConfig__AgreementLineItemId__c
                                                                    FROM Apttus_Config2__AssetLineItem__c
                                                                    WHERE ID IN : consumptionAssetIdSet ]){
    
                    if(assetLine.Apttus_Config2__BundleAssetId__r.APTS_Physical_Asset__c != null){
                        assetPhysicalAssetMap.put(assetLine.Id, assetLine.Apttus_Config2__BundleAssetId__r.APTS_Physical_Asset__c);
                    }
    
                    if(mapAgreementLIAssetLIMap != null && mapAgreementLIAssetLIMap.containsKey(assetLine.Apttus_CMConfig__AgreementLineItemId__c)){
                        mapAgreementLIAssetLIMap.get(assetLine.Apttus_CMConfig__AgreementLineItemId__c).add(assetLine);
                    }
                    else{
                        mapAgreementLIAssetLIMap.put(assetLine.Apttus_CMConfig__AgreementLineItemId__c, new List<Apttus_Config2__AssetLineItem__c>{assetLine});
                    }
    
                }
    
                if(!mapAgreementLIAssetLIMap.keySet().isEmpty()){
                    
                    for(APTS_CounterReadingData__c counterReading : [SELECT Id, APTS_AgreementLineItem__c, APTS_Asset_Line_Item__c, TS_Physical_Asset__c 
                                                                    FROM APTS_CounterReadingData__c 
                                                                    WHERE APTS_AgreementLineItem__c IN : mapAgreementLIAssetLIMap.keySet() ]){
                        if(mapAgreementLIAssetLIMap.containsKey(counterReading.APTS_AgreementLineItem__c)){
                            for(Apttus_Config2__AssetLineItem__c assetLine : mapAgreementLIAssetLIMap.get(counterReading.APTS_AgreementLineItem__c)){
                                if(assetPhysicalAssetMap.containsKey(assetLine.ID) && counterReading.TS_Physical_Asset__c == assetPhysicalAssetMap.get(assetLine.ID)){
                                    counterReading.APTS_Asset_Line_Item__c = assetLine.Id;
                                    lstCounterReading.add(counterReading);
                                }
                            }
                        }
    
                    }
    
                }
                if(!lstCounterReading.isEmpty()){
                    Database.UPDATE(lstCounterReading);
                } 
    
            }catch(Exception ex){
                logError(null,null,null,ex,TRIGGERVALUE,'CounterReading',EMPTY_STRING,false,false,EMPTY_STRING,false);
            }
        }
        
        //v205
        /**
        * @Method Name: updateBillingScheduleSoldTo
        * @Description: Whenever the 'Sold To' or 'Bill To' field value in the 'Asset Line Item' record is modified and the following conditions satisfy:
            To be checked from the Order record (Business Object): 
                1.  Type = Admin Order with Order Sub Type = Conversion.  
                2.  Type = Machine Order with Order Sub Type = External Movement With Contract Change
            the related 'Billing Schedules' records with status 'Pending Billing' should be compared for the same 'Ship To' and 'Bill To' values from its parent; 
            only if it doesn't match, update the Billing Schedules records.
        **/
        public static void updateBillingScheduleSoldTo(List<SObject> newList, Map<Id, SObject> oldItems) {
            
            List<Apttus_Config2__AssetLineItem__c> newAssetList = (List<Apttus_Config2__AssetLineItem__c>) newList;
            Map<Id, String> orderAssetLineItemMap = new Map<Id, String>();
            Set<Id> orderIdsSet = new Set<Id>();
            List<Apttus_Billing__BillingSchedule__c> billingScheduleList = new List<Apttus_Billing__BillingSchedule__c>();
            
            try { //v207 - Added new condition check on old and new agreement change.
                for (Apttus_Config2__AssetLineItem__c  assetLine : newAssetList) {
                    Apttus_Config2__AssetLineItem__c oldasst = (Apttus_Config2__AssetLineItem__c)oldItems.get(assetLine.Id);
                    if(assetLine.Apttus_Config2__AccountId__c != oldasst.Apttus_Config2__AccountId__c || 
                        assetLine.Apttus_Config2__BillToAccountId__c != oldasst.Apttus_Config2__BillToAccountId__c || 
                        assetLine.Apttus_CMConfig__AgreementId__c != oldasst.Apttus_CMConfig__AgreementId__c){
                        orderAssetLineItemMap.put(assetLine.Id, assetLine.Apttus_Config2__BusinessObjectId__c);
                    }
                }
      
                //Query the Order object to check the Order Type and Order Sub Type
                for(Apttus_Config2__Order__c order : [SELECT Id, APTS_Order_Type__c, APTS_Order_Sub_Type__c FROM Apttus_Config2__Order__c 
                                                        WHERE Id IN :orderAssetLineItemMap.values() LIMIT 50000]) {
                    
                    if(((order.APTS_Order_Type__c.equalsIgnoreCase(Label.APTS_AdminOrder) && order.APTS_Order_Sub_Type__c.equalsIgnoreCase(Label.APTS_ConversionOrder)) ||
                        (order.APTS_Order_Type__c.equalsIgnoreCase(Label.APTS_Machine_Order) && order.APTS_Order_Sub_Type__c.equalsIgnoreCase(EXTERNAL_MOVEMENT_WITH_CONTRACT_CHANGE)))) {
                        
                        orderIdsSet.add(order.Id);
                    }
                }
                
                //Query the matching Billing Schedule records to update
                if(!orderIdsSet.isEmpty()) { //v207 - Added BillingSchedule agreement field and its associated ALI agreement field.
                    for(Apttus_Billing__BillingSchedule__c billSch : [SELECT Id, Apttus_Billing__BillToAccountId__c, Apttus_Billing__ShipToAccountId__c, Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c,
                                                                             Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillToAccountId__c, APTS_Agreement__c, 
                                                                             Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c
                                                                        FROM Apttus_Billing__BillingSchedule__c 
                                                                        WHERE Apttus_Billing__AssetLineItemId__c IN :orderAssetLineItemMap.keySet() 
                                                                        AND Apttus_Billing__Status__c = :PENDING_BILLING and Apttus_Billing__PeriodStartDate__c > TODAY LIMIT 50000]) {
                        
                        if(orderIdsSet.contains(orderAssetLineItemMap.get(billSch.Apttus_Billing__AssetLineItemId__c)) &&
                            (billSch.Apttus_Billing__BillToAccountId__c != billSch.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillToAccountId__c || 
                              billSch.Apttus_Billing__ShipToAccountId__c != billSch.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c)) {
                            
                            billSch.Apttus_Billing__BillToAccountId__c = billSch.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillToAccountId__c;
                            billSch.Apttus_Billing__ShipToAccountId__c = billSch.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c;
                            //v207 - Added below assignment- START.
                            billSch.APTS_Agreement__c = billSch.Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c;
                            //v207 - END.
                            billingScheduleList.add(billSch);
                        }
                    }
                }
                
                if(!billingScheduleList.isEmpty()) {
                    //Stop the Billing Schedule Trigger here
                    APTS_BillingScheduleTriggerHandler.isSkipBillingScheduleTrigger = true;
                    Database.update(billingScheduleList);
                    APTS_BillingScheduleTriggerHandler.isSkipBillingScheduleTrigger = false;
                }
            }
            //Catch the exception and store it as log record
            catch(Exception ex) {
                APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Trigger', String.valueOf(ex), 'Asset Line Item', null, STREAM, false, false, null, true); 
            }
        }
    }