/*************************************************************
@Name: APTS_AssetLineItemTriggerHandler
@Author: Pranjal Mittal
@CreateDate: 10-01-2018
@Description: Asset Line Item trigger handler
@UsedBy: Asset Line Item trigger
@Version History : v1.0 - created
                v1.1 - For Consumption modal counter reading data.
                Test Class : APTS_ConsumptionCounterReadingDataTest
                v1.2 - QTCFLEX1-992 - Added by akhilesh for Updating and creating the Historical changes - consolidated.
                v1.3 - DFT2C-1332 - Added by Sai included 4 fields (APTS_Type_Of_Contract__c, APTS_Is_Primary_L1_Asset__c,
                                    APTS_Is_Primary_L1_Asset__r.APTS_Physical_Asset__c,APTS_Is_Primary_L1_Asset__r.APTS_Physical_Asset__r.Warranty__c,
                                    Apttus_Config2__LineType__c, Apttus_Config2__IsPrimaryLine__c) in the query 
                v1.4 - 28/08/2019 - LAE/RAR Redesign (Creation of Transaction record logic update) - DFT2C-853.
                v1.5 - DFT2C-1851,DFT2C-1852 - Added by Karan - Changes related to Optimized query + commented unused code
                v1.6 - 19/11/2019 - DFT2C-1963 - Added condition to stop the transactions for sold machines.
                v1.7 - 26/11/2019 - DFT2C-2034 - Added logic for warranty start date on contract effective date for sales machine and service option.  
                v1.8 - 2/1/2020 - DFT2C-2174 - Added logic for Asset adjustments to only run on flow rather than dummy updates.
                v1.9 - 21/01/2020 - DQ-56/DQ-2111- Asset Contract Change-Lavanya
                v1.10 -19/3/2020   - DQ-56- AssetContract Change-Karan  
                v2.0 - 21/01/2020 - DQ - 368 - updating Contract Effective Date on Transaction records for A005 and B005.
                v2.1 - 24/01/2020 - DQ - 980 - Added logic to stop creating second transaction records as 0004 through auto renewal job.
                v2.2 - 03/02/2020 - DQ - 799 - Retain updated BPO values on installation/Conversion order.
                v2.3 - 27/3/2020  - DQ - 1829 - Population logic of Termination flow - old pha, its serial number and its initial activation date - used further in LAE/RAR to calculate pHA staging details
                v2.4 - 02/04/2020 - DQ - 1891 - Changed the signature of calculateAssetBaseExtendedPrice (Changed the signature/Reduced SOQL/Changed Logic of LAE to populate when net price gets changed truely))
                v2.5 - 09-09-2020 - DQ-1855 - Changed the LAE Logic to restrict the creation of 0004 for sales Charge Type.
                v2.6 - 10-09-2020 - DQ-3785, DQ-369 - Replacing the Apttus_Config2__OriginalStartDate__c with APTS_RAR_LAE_OriginalStartDate__c.
                v2.7 - 21-09-2020 - DQ-992 - Replacing the 0002 transaction with 0004 for end date reduction.
                v2.8 - 21-09-2020 - DQ-3777 - Add additional criteria to create transaction record Stop RtR Transactions from.
                v2.9 - 21-09-2020 - DQ-3948 - Movement Order Addition logic Change of Ownership+Financial Agreement population for conversion Order.
                v-2.10- 24/9/2020 DQ-3871 Deinstallation Dates Set-Lavanya
                v-2.11- 25/9/2020 DQ-3894 Populating Financial Agreement on Asset Line Item for movement and Installation Orders-Manisha
                v-2.12- 25/9/2020 DQ-3654 skip the processing of Service headers that only have "dummy" option materials.
                v-2.13- 01/12/2020 DQ-4635 Enable CTC for sales without LAE transaction data
                v-2.14- 10/12/2020 DQ-4750 New UX transaction data creation for No Coverage
                v-2.15- 23/12/2020 DQ-4765 Financial Asset Status field changes
                v-2.16- 11/03/2021 DQ-5528 YOCI/YOFT remains in ASLI even after the removal of adjustments via ABO.
                v-2.17- 05/04/2021 DQ-5898 CTC Fix - Remove logic to update Parent order Line item number on Asset level
                v-2.18- 11/04/2021 DQ-5899 CTC FIX-Remove logic to update Parent Order Line Item
                v-2.19- 16/04/2021 DQ-5986 CTC - 0002 record creation issue fix
******************************************************************/
public without sharing class APTS_AssetLineItemTriggerHandler implements ITriggerHandler {
 
    private Map<Id, String> mapHistory;
     private Static String EMPTY_STRING = ' ';
    private static final String STR_ACTION_ACTIVATED = 'Activated';
    private static final String STR_ACTION_CANCELLED = 'Cancelled';
    private static final String STR_ACTION_PENDINGACTIVATION = 'Pending Activation';
    private static final String STR_ACTION_PENDINGCHANGE = 'Pending Change';
    private static final String STR_ACTION_PENDINGRENEWAL = 'Pending Renewal';
    private static final String TRANS_0001 = '0001';
    private static final String TRANS_0002 = '0002';
    private static final String TRANS_0003 = '0003';
    private static final String TRANS_0004 = '0004';
    private static final String TRANS_0005 = '0005';
    private static final String TRANS_A005 = 'A005';
    private static final String TRANS_B005 = 'B005';
    private static final String ACTION_NEW = 'New';
    private static final String ACTION_RENEW = 'Renew';
    private static final String ACTION_AMEND = 'Amend';
    private static final String ACTION_CANCEL = 'Cancel';
    private static final String STR_SAT_CAT_TERMINATED = 'Terminated';
    private final static String TrialToSalesScenario= 'Trial to Sales';
    private static final String CHAR_S = 'S';
    private static final String CHAR_I = 'I';
    private static final String INTERNAL_MOVEMENT = System.Label.APTS_Internal_Movement;
    private static final String EXTERNAL_MOVEMENT_WITH_CONTRACT_CHANGE = 'External Movement With Contract Change';
    private static final String EXTERNAL_MOVEMENT_WITHOUT_CONTRACT_CHANGE = 'External Movement Without Contract Change';
    public static Boolean isTriggerDisabled = true;
    public static Boolean isSkipAssetlineitemTrigger = false;
    private static Map<Id, String> mapIdOrderSubType = new Map<Id, String>();
    public static Map<Id,Apttus_Config2__AssetLineItem__c> allParentAssetsnew=new Map<id,Apttus_Config2__AssetLineItem__c>();
    private static final String TRIAL = System.Label.APTS_Trial;
    private static final String SALES = 'Sales';
    private static final String SALESPRICE = 'Sales Price';
    private static final String SUBSCRIPTION = 'Subscription';
    private static final String USAGEFEE = 'Usage Fee';
    private static final String ADDITIONALSERVICEFEE = 'Additional Service Fee';
    private static final String SERVICEFEE = 'Service Fee';
    private static final String PRODUCTSERVICE = 'Product/Service';
    private static final String OPTION = 'Option';
    private static final String NO_COVERAGE= 'NO COVERAGE';
    Boolean isFinalStatus = false;
    String allCoverage='Default';
    String bCoverage='Default';
    String noCoverage='Default';
    //Boolean isFinalStatus = false; 
    public static Map<Id, Apttus_Config2__AssetLineItem__c> processAssets = new Map<Id, Apttus_Config2__AssetLineItem__c>();
    Map<ID, RTR_LAE_Transaction_Data__c> lstATLRecordsMap = new Map<ID, RTR_LAE_Transaction_Data__c>();
    Map<ID, ID> additionalFeeToServiceFeeMap = new Map<ID, ID>();
    Set<String> asfStatus=new Set<String>();
    public Map<Id, Boolean> mapServiceWarranty = new Map<Id, Boolean>();
    public Map<Id, Boolean> mapServiceActiveWarranty = new Map<Id, Boolean>();  
    public Map<Id, Date> mapServiceActiveWarrantyDate = new Map<Id, Date>();
    //v-2.15--->  
    public static Set<ID> financialStatusprocessedAssetSet = new Set<ID>();
    public static Set<ID> financialStatusprocessedAssetSetnew = new Set<ID>();
    //<--v-2.15
    public void BeforeInsert(List<SObject> newItems) {
        //v2.6 - START
            for(Apttus_Config2__AssetLineItem__c assets : (List<Apttus_Config2__AssetLineItem__c>) newItems){
                assets.APTS_RAR_LAE_OriginalStartDate__c = assets.Apttus_Config2__OriginalStartDate__c;
                assets.APTS_Financial_Start_Date__c = assets.Apttus_Config2__OriginalStartDate__c;
            }
        //v.2.6 - END
    }
    public void BeforeUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldItems) {
        try{
            List<Apttus_Config2__AssetLineItem__c> newAssetList = (List<Apttus_Config2__AssetLineItem__c>) newList;
            Map<Id,Apttus_Config2__AssetLineItem__c> bundleastAgreementMap = new Map<Id, Apttus_Config2__AssetLineItem__c>();
            Map<Id,Apttus_Config2__AssetLineItem__c> bundleastAgreementPrimaryMap = new Map<Id, Apttus_Config2__AssetLineItem__c>();
            Map<Id, Apttus_Config2__AssetLineItem__c> newMap = (Map<Id, Apttus_Config2__AssetLineItem__c>) newItems;
            Map<Id, Apttus_Config2__AssetLineItem__c> oldMap = (Map<Id, Apttus_Config2__AssetLineItem__c>) oldItems;
            Map<Id,Decimal> orderLineItemBPOMap = new Map<Id,Decimal>();
            Map<Id,String> orderLineItemItemCatMap = new Map<Id,String>();
            Map<Id,PhysicalAsset__c> physicalAssetBundleMap = new Map<Id,PhysicalAsset__c>();
            Set<ID> businessObjectLineItemSet = new Set<ID>();
            String financialAgreement;
            List<Apttus_Config2__OrderLineItem__c> ListOrderLineItem = new List<Apttus_Config2__OrderLineItem__c>();
            //DQ-56  v1.9          
            Map<Id,Id> MapRelatedAgremment= new Map<Id,Id>();
            Set<Id> setOrderParentL1Id = new Set<Id>();
            Map<Id, Id> mapAssetPrimL1Id = new Map<Id, Id>();
            Map<Id, Date> mapAssignOriginalDate = new Map<Id, Date>();
            Map<Id, Apttus_Config2__AssetLineItem__c> mapAssetLineItem = new Map<Id, Apttus_Config2__AssetLineItem__c>();
            Map<Id,Apttus_Config2__AssetLineItem__c> MapOldAssetLine = new Map<Id,Apttus_Config2__AssetLineItem__c>();
            Map<Id,String> MapPHAExtid = new Map<Id,String>();
            Map<Id,String> sapSalesOrderLine = new Map<Id,String>();
            Map<Id,Boolean> MapInvoiced = new Map<id,Boolean>();
            Map<Decimal,Date> MapDeinstallDates= new Map<Decimal,Date>();
            Map<Id,Boolean>  mapContractChange = new Map<id,Boolean>();
            Set<Id> setTerminatedAssetLines = new Set<Id>();
            Map<Id,Apttus_Config2__OrderLineItem__c> businessObjectIdMap = new Map<Id,Apttus_Config2__OrderLineItem__c>();
            Map<Id,Apttus_Config2__OrderLineItem__c> orderlineItemDetailsMap = new Map<Id,Apttus_Config2__OrderLineItem__c>();
            Map<Id,boolean> relatedAgreementExtMovmtAssetMap = new Map<Id,boolean>();
            Map<Id,boolean> financialAgreementMap = new Map<Id,boolean>();
            Map<String,Decimal> financialAssetStatusMap = new Map<String,Decimal>();
            Map<string,Set<String>> asfmap=new Map<string,Set<String>>();
            Set<String> asfStatusfinal=new Set<String>();
            Set<String> financialAssetStatusChargeTypeList = new Set<String>{'Service Fee','Additional Service Fee'};
            //DQ-56
            //v2.2 Karan | Optimized code
            Map<Id,Apttus_Config2__OrderLineItem__c> OrderLineItemMap = new Map<Id,Apttus_Config2__OrderLineItem__c> ();
            for (Apttus_Config2__AssetLineItem__c  assetLine : newAssetList) {
                 if(string.isNotBlank(assetLine.APTS_Is_Primary_L1_Parent__c)){
                setOrderParentL1Id.add(assetLine.APTS_Is_Primary_L1_Parent__c);
            }
                 mapAssetLineItem.put(assetLine.Id, assetLine);
                if(assetLine.Apttus_Config2__BusinessLineItemId__c!=null){
                    businessObjectLineItemSet.add(assetLine.Apttus_Config2__BusinessLineItemId__c);
                }
                if(assetLine.Apttus_Config2__ChargeType__c=='Additional Service Fee'&&assetLine.Apttus_Config2__LineType__c.equalsIgnoreCase('Option')){
                if(asfmap!=null){
                    Set<String> asfStatus=asfmap.get(assetLine.Apttus_Config2__BundleAssetId__c+assetLine.Apttus_Config2__ChargeType__c);
                }
                system.debug('nullcheckShahul'+assetLine);
                if(assetLine!=null){
                if(assetLine.Apttus_Config2__AssetStatus__c!=null){
                asfStatus.add(assetLine.Apttus_Config2__AssetStatus__c);}
                }
                if(asfmap!=null&&asfStatus.size()>0){
                    asfmap.put(assetLine.Apttus_Config2__BundleAssetId__c+assetLine.Apttus_Config2__ChargeType__c,asfStatus);
                }
                }
                
                
                //v-2.15--->
                System.debug('##########assetLine.Apttus_Config2__LineType__c=============>'+assetLine.Apttus_Config2__LineType__c);
                System.debug('##########assetLine.Apttus_Config2__ChargeType__c=============>'+assetLine.Apttus_Config2__ChargeType__c);
                System.debug('##########assetLine.Apttus_Config2__AssetStatus__c=============>'+assetLine.Apttus_Config2__AssetStatus__c);
                System.debug('##########OLD ASSET STATUS=============>'+((Apttus_Config2__AssetLineItem__c)oldItems.get(assetLine.Id)).Apttus_Config2__AssetStatus__c);
                System.debug('##########assetLine.netprice=============>'+assetLine.Apttus_Config2__NetPrice__c);
                if(assetLine.Apttus_Config2__LineType__c!=null &&
                    assetLine.Apttus_Config2__AssetStatus__c!=null && 
                    assetLine.Name!=null &&
                    !financialAssetStatusChargeTypeList.isEmpty() &&
                    assetLine.Apttus_Config2__LineType__c.equalsIgnoreCase('Option') && 
                    ((Apttus_Config2__AssetLineItem__c)oldItems.get(assetLine.Id)).Apttus_Config2__AssetStatus__c.equalsIgnoreCase('Activated') &&
                    assetLine.Apttus_Config2__AssetStatus__c.equalsIgnoreCase('Activated') && 
                    !assetLine.Name.equalsIgnoreCase(NO_COVERAGE) && 
                    financialAssetStatusChargeTypeList.contains(assetLine.Apttus_Config2__ChargeType__c) &&
                    !financialStatusprocessedAssetSet.contains(assetLine.id)){
                        if(financialAssetStatusMap.get(assetLine.Apttus_Config2__BundleAssetId__c+assetLine.Apttus_Config2__ChargeType__c)==null){
                            financialAssetStatusMap.put(assetLine.Apttus_Config2__BundleAssetId__c+assetLine.Apttus_Config2__ChargeType__c,assetLine.Apttus_Config2__NetPrice__c);
                        }else{
                            financialAssetStatusMap.put(assetLine.Apttus_Config2__BundleAssetId__c+assetLine.Apttus_Config2__ChargeType__c,financialAssetStatusMap.get(assetLine.Apttus_Config2__BundleAssetId__c+assetLine.Apttus_Config2__ChargeType__c)+assetLine.Apttus_Config2__NetPrice__c);
                        }
                        financialStatusprocessedAssetSet.add(assetLine.id);
                }
                //<--v-2.15
            }
            System.debug('##########financialAssetStatusMap=============>'+financialAssetStatusMap);
            //v2.2
            System.debug('########## CTC BPO businessObjectLineItemSet=============>'+businessObjectLineItemSet);
            ListOrderLineItem = new List<Apttus_Config2__OrderLineItem__c>([Select id,Apttus_Config2__AssetLineItemId__c,
                                                                            Apttus_Config2__OrderId__r.APTS_Contract_Change__c,
                                                                            Apttus_Config2__OrderId__r.APTS_Order_Type__c,
                                                                            Apttus_Config2__OrderId__r.APTS_Scenario__c,
                                                                            Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c,
                                                                            Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c,
                                                                            Apttus_Config2__OrderId__r.APTS_Change_of_Ownership__c,
                                                                            Apttus_Config2__Status__c,
                                                                            Apttus_Config2__CancelledDate__c,
                                                                            Apttus_Config2__LineStatus__c,
                                                                            Apttus_Config2__BillingFrequency__c,
                                                                            Apttus_Config2__OptionId__r.name,
                                                                            Apttus_Config2__ChargeType__c,
                                                                            APTS_ZX10__c,
                                                                            Apttus_Config2__AssetLineItemId__r.APTS_Is_Primary_L1_Line__c,
                                                                            APTS_Is_Primary_L1_Line__c,
                                                                            APTS_De_installation_Date_Authorized__c,
                                                                            Apttus_Config2__AssetLineItemId__r.Apttus_Config2__LineNumber__c,
                                                                            Apttus_Config2__DerivedFromId__r.APTS_Terminated_Asset_Line__r.Apttus_Config2__ChargeType__c,
                                                                            Apttus_Config2__DerivedFromId__r.APTS_Terminated_Asset_Line__r.Apttus_Config2__BillingFrequency__c,
                                                                            Apttus_Config2__DerivedFromId__r.APTS_Terminated_Asset_Line__r.APTS_relatedlist_agreement__c,
                                                                            Apttus_Config2__DerivedFromId__r.APTS_Terminated_Asset_Line__c,
                                                                            Apttus_Config2__DerivedFromId__r.APTS_Terminated_Asset_Line__r.APTS_Parent_Order_Line_Item__c, //v-2.17 ++
                                                                            Apttus_Config2__DerivedFromId__r.APTS_Terminated_Asset_Line__r.APTS_Type_Of_Contract__c,
                                                                            Apttus_Config2__DerivedFromId__r.APTS_Terminated_Asset_Line__r.APTS_PhysicalAssetExtId__c,
                                                                            Apttus_Config2__BasePriceOverride__c,
                                                                            Apttus_Config2__StartDate__c,
                                                                            Apttus_Config2__EndDate__c,
                                                                            Apttus_Config2__SellingTerm__c,
                                                                            Apttus_Config2__NetPrice__c,
                                                                            Apttus_Config2__NetUnitPrice__c,
                                                                            APTS_Serial_Number__c, APTS_Item_Category_Adjustment__c 
                                                                            from Apttus_Config2__OrderLineItem__c 
                                                                            where id IN: businessObjectLineItemSet 
                                                                           // and Apttus_Config2__Status__c='Activated'
                                                                           ]);
                                                                           
            //DQ-56 -v1.9-Populating Maps to populate AssetLine for Contract Change Logic
            if(ListOrderLineItem != NULL && ListOrderLineItem.size()>0){
                for(Apttus_Config2__OrderLineItem__c instOrderLineItem : ListOrderLineItem){
                    if(instOrderLineItem.Apttus_Config2__OrderId__r.APTS_Contract_Change__c!=null && instOrderLineItem.Apttus_Config2__LineStatus__c!=null && instOrderLineItem.Apttus_Config2__OrderId__r.APTS_Contract_Change__c.equalsIgnoreCase('Yes')){ 
                    mapContractChange.put(instOrderLineItem.Apttus_Config2__AssetLineItemId__c,true); 
                    }
                   //v-2.10 https://jdecoffee.atlassian.net/browse/DQ-3871
                    if(instOrderLineItem.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c=='De-installation' && instOrderLineItem.APTS_De_installation_Date_Authorized__c != null && instOrderLineItem.APTS_Is_Primary_L1_Line__c == true)
                    MapDeinstallDates.put(instOrderLineItem.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__LineNumber__c,instOrderLineItem.APTS_De_installation_Date_Authorized__c);
                    //v-2.10 https://jdecoffee.atlassian.net/browse/DQ-3871
                    
                    if(instOrderLineItem.Apttus_Config2__OrderId__r.APTS_Contract_Change__c!=null && instOrderLineItem.Apttus_Config2__LineStatus__c!=null && instOrderLineItem.Apttus_Config2__OrderId__r.APTS_Contract_Change__c.equalsIgnoreCase('Yes') && instOrderLineItem.Apttus_Config2__LineStatus__c.equalsIgnoreCase('New') && instOrderLineItem.Apttus_Config2__Status__c=='Activated'){
                    if(instOrderLineItem.Apttus_Config2__ChargeType__c == 'Sales Price' && instOrderLineItem.Apttus_Config2__BillingFrequency__c == 'One Time' && instOrderLineItem.Apttus_Config2__DerivedFromId__r.APTS_Terminated_Asset_Line__c!=null && instOrderLineItem.Apttus_Config2__DerivedFromId__r.APTS_Terminated_Asset_Line__r.Apttus_Config2__BillingFrequency__c=='One Time' && instOrderLineItem.Apttus_Config2__DerivedFromId__r.APTS_Terminated_Asset_Line__r.Apttus_Config2__ChargeType__c =='Sales Price' )
                    MapInvoiced.put(instOrderLineItem.Apttus_Config2__AssetLineItemId__c,true); // For OneTimes from Rental/FOL only make them invoiced.
                    if(instOrderLineItem.Apttus_Config2__DerivedFromId__c != null && instOrderLineItem.Apttus_Config2__DerivedFromId__r.APTS_Terminated_Asset_Line__c!=null)
                     MapOldAssetLine.put(instOrderLineItem.Apttus_Config2__AssetLineItemId__c,instOrderLineItem.Apttus_Config2__DerivedFromId__r.APTS_Terminated_Asset_Line__r);
                     if(instOrderLineItem.Apttus_Config2__DerivedFromId__c != null && instOrderLineItem.Apttus_Config2__DerivedFromId__r.APTS_Terminated_Asset_Line__c != null && instOrderLineItem.Apttus_Config2__DerivedFromId__r.APTS_Terminated_Asset_Line__r.APTS_relatedlist_agreement__c != null)
                    MapRelatedAgremment.put(instOrderLineItem.Apttus_Config2__AssetLineItemId__c,instOrderLineItem.Apttus_Config2__DerivedFromId__r.APTS_Terminated_Asset_Line__r.APTS_relatedlist_agreement__c);
                    if(instOrderLineItem.Apttus_Config2__DerivedFromId__c != null && instOrderLineItem.Apttus_Config2__DerivedFromId__r.APTS_Terminated_Asset_Line__c != null && instOrderLineItem.Apttus_Config2__DerivedFromId__r.APTS_Terminated_Asset_Line__r.APTS_PhysicalAssetExtId__c!=null)
                     MapPHAExtid.put(instOrderLineItem.Apttus_Config2__AssetLineItemId__c,instOrderLineItem.Apttus_Config2__DerivedFromId__r.APTS_Terminated_Asset_Line__r.APTS_PhysicalAssetExtId__c);     
                    /*v-2.18
                     if(instOrderLineItem.Apttus_Config2__DerivedFromId__c != null && instOrderLineItem.Apttus_Config2__DerivedFromId__r.APTS_Terminated_Asset_Line__c != null && instOrderLineItem.Apttus_Config2__DerivedFromId__r.APTS_Terminated_Asset_Line__r.APTS_Parent_Order_Line_Item__c!=null && instOrderLineItem.Apttus_Config2__OrderId__r.APTS_Scenario__c != null && instOrderLineItem.Apttus_Config2__OrderId__r.APTS_Scenario__c == TrialToSalesScenario){
                         sapSalesOrderLine.put(instOrderLineItem.Apttus_Config2__AssetLineItemId__c,instOrderLineItem.Apttus_Config2__DerivedFromId__r.APTS_Terminated_Asset_Line__r.APTS_Parent_Order_Line_Item__c); //v-2.17 ++
                     }  */                       
                    }
                    if(instOrderLineItem.Apttus_Config2__OrderId__r.APTS_Contract_Change__c!=null && instOrderLineItem.Apttus_Config2__LineStatus__c!=null && instOrderLineItem.Apttus_Config2__OrderId__r.APTS_Contract_Change__c.equalsIgnoreCase('Yes') && instOrderLineItem.Apttus_Config2__LineStatus__c.equalsIgnoreCase('Cancelled') && instOrderLineItem.Apttus_Config2__Status__c=='Activated'){
                        OrderLineItemMap.put(instOrderLineItem.Apttus_Config2__AssetLineItemId__c,instOrderLineItem);
                        //DQ-56-v1.9 framing Map for unlinking PHA
                    }
                    //v2.2
                    if(instOrderLineItem.Apttus_Config2__AssetLineItemId__c!=null && orderLineItemBPOMap.get(instOrderLineItem.Apttus_Config2__AssetLineItemId__c)==null && instOrderLineItem.Apttus_Config2__OrderId__c!=null && instOrderLineItem.Apttus_Config2__OrderId__r.APTS_Order_Type__c!=null && instOrderLineItem.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c!=null && instOrderLineItem.Apttus_Config2__OrderId__r.APTS_Order_Type__c.equalsIgnoreCase('Admin order') && !instOrderLineItem.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c.equalsIgnoreCase(APTS_BIRUtils.ORDERSUBTYPE) && instOrderLineItem.Apttus_Config2__Status__c=='Activated'){
                       orderLineItemBPOMap.put(instOrderLineItem.Apttus_Config2__AssetLineItemId__c,instOrderLineItem.Apttus_Config2__BasePriceOverride__c);                   
                    }
                    //<<++v2.16
                    if(instOrderLineItem.Apttus_Config2__AssetLineItemId__c!=null && orderLineItemItemCatMap.get(instOrderLineItem.Apttus_Config2__AssetLineItemId__c)==null && instOrderLineItem.Apttus_Config2__OrderId__c!=null && instOrderLineItem.Apttus_Config2__OrderId__r.APTS_Order_Type__c!=null && instOrderLineItem.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c!=null && instOrderLineItem.Apttus_Config2__OrderId__r.APTS_Order_Type__c.equalsIgnoreCase('Admin order') && !instOrderLineItem.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c.equalsIgnoreCase(APTS_BIRUtils.ORDERSUBTYPE) && instOrderLineItem.Apttus_Config2__Status__c=='Activated'){
                        orderLineItemItemCatMap.put(instOrderLineItem.Apttus_Config2__AssetLineItemId__c,instOrderLineItem.APTS_Item_Category_Adjustment__c);                   
                    }// v2.16>>
                    if(instOrderLineItem.Apttus_Config2__AssetLineItemId__c!=null && businessObjectIdMap.get(instOrderLineItem.Apttus_Config2__AssetLineItemId__c)==null && instOrderLineItem.Apttus_Config2__OrderId__c!=null && instOrderLineItem.Apttus_Config2__OrderId__r.APTS_Order_Type__c!=null && instOrderLineItem.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c!=null && (instOrderLineItem.Apttus_Config2__OrderId__r.APTS_Order_Type__c.equalsIgnoreCase('Admin order')||instOrderLineItem.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c.equalsIgnoreCase('Installation')||instOrderLineItem.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c.equalsIgnoreCase('Internal Movement') ||instOrderLineItem.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c.equalsIgnoreCase('External Movement With Contract Change') ||instOrderLineItem.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c.equalsIgnoreCase('External Movement Without Contract Change')) && !instOrderLineItem.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c.equalsIgnoreCase(APTS_BIRUtils.ORDERSUBTYPE) && instOrderLineItem.Apttus_Config2__Status__c=='Activated'){
                        businessObjectIdMap.put(instOrderLineItem.Apttus_Config2__AssetLineItemId__c,instOrderLineItem);                   
                     }
                    if(instOrderLineItem.Apttus_Config2__AssetLineItemId__c!=null && orderlineItemDetailsMap.get(instOrderLineItem.Apttus_Config2__AssetLineItemId__c)==null  && instOrderLineItem.Apttus_Config2__OrderId__c!=null && instOrderLineItem.Apttus_Config2__OrderId__r.APTS_Order_Type__c!=null && instOrderLineItem.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c!=null && !instOrderLineItem.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c.equalsIgnoreCase(APTS_BIRUtils.ORDERSUBTYPE) && instOrderLineItem.Apttus_Config2__Status__c=='Activated'){
                       orderlineItemDetailsMap.put(instOrderLineItem.Apttus_Config2__AssetLineItemId__c,instOrderLineItem);                   
                    }
                    if(instOrderLineItem.Apttus_Config2__AssetLineItemId__c!=null && instOrderLineItem.Apttus_Config2__OrderId__c!=null && instOrderLineItem.Apttus_Config2__OrderId__r.APTS_Order_Type__c!=null && instOrderLineItem.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c!=null && relatedAgreementExtMovmtAssetMap.get(instOrderLineItem.Apttus_Config2__AssetLineItemId__c)==null && instOrderLineItem.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c.contains('Movement') && instOrderLineItem.Apttus_Config2__Status__c=='Activated'){
                       relatedAgreementExtMovmtAssetMap.put(instOrderLineItem.Apttus_Config2__AssetLineItemId__c,true);                   
                    }
                    //v-2.11
                    if((instOrderLineItem.Apttus_Config2__AssetLineItemId__c!=null && instOrderLineItem.Apttus_Config2__OrderId__c!=null && instOrderLineItem.Apttus_Config2__OrderId__r.APTS_Order_Type__c=='Machine Order' && instOrderLineItem.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c!=null && financialAgreementMap.get(instOrderLineItem.Apttus_Config2__AssetLineItemId__c)==null && instOrderLineItem.Apttus_Config2__Status__c=='Activated' )&&((instOrderLineItem.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c.contains('Movement') && instOrderLineItem.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c == APTS_OrderConstants.XA14 && instOrderLineItem.Apttus_Config2__OrderId__r.APTS_Change_of_Ownership__c )||(instOrderLineItem.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c=='Installation' && instOrderLineItem.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c == APTS_OrderConstants.XA13))){
                         financialAgreementMap.put(instOrderLineItem.Apttus_Config2__AssetLineItemId__c,true);                  
                     }
                      //Swap Scenario
                     if(setOrderParentL1Id.contains(instOrderLineItem.Id)&&!setOrderParentL1Id.isempty()&&instOrderLineItem.Apttus_Config2__AssetLineItemId__r.APTS_Is_Primary_L1_Line__c){
                       mapAssetPrimL1Id.put(instOrderLineItem.Id, instOrderLineItem.Apttus_Config2__AssetLineItemId__c);

                     }
                }
            }
            for(Apttus_Config2__AssetLineItem__c asset : [SELECT Id,Apttus_Config2__BundleAssetId__c,APTS_relatedlist_agreement__c,APTS_Financial_Agreement__c,Apttus_Config2__AssetStatus__c,Apttus_CMConfig__AgreementId__c,
                                                          APTS_Physical_Asset__r.InitialActivationDate__c,
                                                          Apttus_Config2__BundleAssetId__r.APTS_relatedlist_agreement__c,
                                                          Apttus_Config2__BundleAssetId__r.Apttus_CMConfig__AgreementId__c,
                                                          APTS_Stop_RtR_Transactions_from__c
                                                          FROM Apttus_Config2__AssetLineItem__c 
                                                          WHERE ID IN: newMap.keySet()]){
              if(asset.Apttus_Config2__BundleAssetId__c != null && (asset.APTS_Financial_Agreement__c ==null ||asset.APTS_relatedlist_agreement__c == null || asset.Apttus_CMConfig__AgreementId__c == null)){
                  bundleastAgreementMap.put(asset.Apttus_Config2__BundleAssetId__c, asset.Apttus_Config2__BundleAssetId__r);
              }
              if(asset.Apttus_Config2__BundleAssetId__c == null && (asset.APTS_Financial_Agreement__c ==null ||asset.APTS_relatedlist_agreement__c == null || asset.Apttus_CMConfig__AgreementId__c == null)){
                bundleastAgreementPrimaryMap.put(asset.Id, asset);
            }
              System.debug('asset.APTS_Physical_Asset__c======>'+asset.APTS_Physical_Asset__c);
              System.debug('oldMap.get(asset.id)======>'+oldMap.get(asset.id));
              System.debug('asset.Apttus_Config2__AssetStatus__c======>'+asset.Apttus_Config2__AssetStatus__c);
              System.debug('oldMap.get(asset.id).Apttus_Config2__AssetStatus__c======>'+oldMap.get(asset.id).Apttus_Config2__AssetStatus__c);
              //System.debug('asset.Apttus_Config2__AssetStatus__c======>'+asset.Apttus_Config2__NetPrice__c);
              //System.debug('oldMap.get(asset.id).Apttus_Config2__AssetStatus__c======>'+oldMap.get(asset.id).Apttus_Config2__NetPrice__c);

              //v2.3 Added by Karan | DQ-1829 START
              if(asset.APTS_Physical_Asset__c!=null && physicalAssetBundleMap.get(asset.id)==null && oldMap.get(asset.id)!=null && asset.Apttus_Config2__AssetStatus__c.equalsIgnoreCase('Cancelled')){
                  physicalAssetBundleMap.put(asset.id,asset.APTS_Physical_Asset__r);
              }
              //v2.3 Added by Karan | DQ-1829 END
            }

            for (Apttus_Config2__AssetLineItem__c  assetLine : newAssetList) {
            
                system.debug('+++businessObjectIdMap+++'+businessObjectIdMap);
                if(businessObjectIdMap!=null&&!businessObjectIdMap.isEmpty()){
                if(businessObjectIdMap.get(assetLine.id).Apttus_Config2__OptionId__r.name=='ALL-IN COVERAGE' &&businessObjectIdMap.get(assetLine.id).Apttus_Config2__LineStatus__c==STR_ACTION_CANCELLED){
                allCoverage='true';
                }
                if(businessObjectIdMap.get(assetLine.id).Apttus_Config2__OptionId__r.name=='BASIC COVERAGE' &&businessObjectIdMap.get(assetLine.id).Apttus_Config2__LineStatus__c==STR_ACTION_CANCELLED){
                bCoverage='true';
                }
                if(businessObjectIdMap.get(assetLine.id).Apttus_Config2__OptionId__r.name=='NO COVERAGE' &&businessObjectIdMap.get(assetLine.id).Apttus_Config2__LineStatus__c==STR_ACTION_CANCELLED){
                noCoverage='true';
                }
                }
                if(bundleastAgreementMap.Containskey(assetLine.Apttus_Config2__BundleAssetId__c)){
                    financialAgreement = bundleastAgreementMap.get(assetLine.Apttus_Config2__BundleAssetId__c).Apttus_CMConfig__AgreementId__c;
                    assetLine.APTS_relatedlist_agreement__c = bundleastAgreementMap.get(assetLine.Apttus_Config2__BundleAssetId__c).APTS_relatedlist_agreement__c;
                    if(String.isBlank(assetLine.Apttus_CMConfig__AgreementId__c)){
                        assetLine.Apttus_CMConfig__AgreementId__c=bundleastAgreementMap.get(assetLine.Apttus_Config2__BundleAssetId__c).Apttus_CMConfig__AgreementId__c;
                    }
                }
//Dq-5516 financial Agreement fix for trial Service lines
                if(bundleastAgreementPrimaryMap.Containskey(assetLine.Id) && bundleastAgreementPrimaryMap.get(assetLine.Id).Apttus_CMConfig__AgreementId__c != null)
                {
                 financialAgreement = bundleastAgreementPrimaryMap.get(assetLine.Id).Apttus_CMConfig__AgreementId__c;
                }
                  //System.debug('APTS_Financial_Agreement__c======>'+assetLine.APTS_Financial_Agreement__c);
                  //System.debug('bundleastAgreementMap======>'+bundleastAgreementMap);
                  //V2.9 Start
                    if(String.isBlank(assetLine.APTS_Financial_Agreement__c)){
                        assetLine.APTS_Financial_Agreement__c=financialAgreement;
                    }
                    //V2.9 END
                
                //v-2.15--->
                //System.debug('##########financialAssetStatusMap=============>'+financialAssetStatusMap);
                if(!financialAssetStatusMap.isEmpty() && assetLine.Apttus_Config2__LineType__c.equalsIgnoreCase(PRODUCTSERVICE)){
                    if(assetLine.Apttus_Config2__ChargeType__c.equalsIgnoreCase(SERVICEFEE)){
                        String bundleassetid = assetLine.Apttus_Config2__IsPrimaryLine__c==true? assetLine.id : assetLine.APTS_Is_Primary_L1_Asset__c;
                        System.debug('financialAssetStatusMap=========>'+financialAssetStatusMap);
                        System.debug('asset=========>'+financialAssetStatusMap);
                        System.debug('bundleassetid=========>'+bundleassetid);
                        System.debug('financialAssetStatusMap.get(bundleassetid+SERVICEFEE)=========>'+financialAssetStatusMap.get(bundleassetid+SERVICEFEE));
                        System.debug('financialAssetStatusMap.get(bundleassetid+ADDITIONALSERVICEFEE)=========>'+financialAssetStatusMap.get(bundleassetid+ADDITIONALSERVICEFEE));
                        if(financialAssetStatusMap.get(bundleassetid+SERVICEFEE)!=null || (financialAssetStatusMap.get(bundleassetid+ADDITIONALSERVICEFEE)!=null && financialAssetStatusMap.get(bundleassetid+ADDITIONALSERVICEFEE) > 0)){
                            assetLine.APTS_Financial_Asset_Status__c='Activated';
                        }else{
                            assetLine.APTS_Financial_Asset_Status__c='Cancelled';
                        }
                    }else{
                        assetLine.APTS_Financial_Asset_Status__c=assetLine.Apttus_Config2__AssetStatus__c;
                    }
                   financialStatusprocessedAssetSetnew.add(assetLine.id);
                }
                
                if(!asfmap.isEmpty() && assetLine.Apttus_Config2__LineType__c.equalsIgnoreCase(PRODUCTSERVICE)){
                    if(assetLine.Apttus_Config2__ChargeType__c.equalsIgnoreCase(ADDITIONALSERVICEFEE)){
                        String bundleassetid = assetLine.Apttus_Config2__IsPrimaryLine__c==true? assetLine.id : assetLine.APTS_Is_Primary_L1_Asset__c;
                        System.debug('asfmap=========>'+asfmap);
                        System.debug('asset=========>'+asfmap);
                        System.debug('bundleassetid=========>'+bundleassetid);
                        System.debug('asfmap.get(bundleassetid+ADDITIONALSERVICEFEE)=========>'+asfmap.get(bundleassetid+ADDITIONALSERVICEFEE));
                        System.debug('asfmap.get(bundleassetid+ADDITIONALSERVICEFEE)=========>'+asfmap.get(bundleassetid+ADDITIONALSERVICEFEE));
                        if(asfmap!=null){
                        asfStatusfinal=asfmap.get(assetLine.Apttus_Config2__BundleAssetId__c+assetLine.Apttus_Config2__ChargeType__c);
                        }
                        if(!asfStatusfinal.isEmpty()&&asfStatusfinal.contains('Activated')){
                            assetLine.APTS_Financial_Asset_Status__c='Activated';
                        }else{
                        assetLine.APTS_Financial_Asset_Status__c='Cancelled';
                        }
                    }
                }
                
                if(!financialStatusprocessedAssetSetnew.contains(assetLine.id)&&financialAssetStatusMap.isEmpty() && assetLine.Apttus_Config2__LineType__c.equalsIgnoreCase(PRODUCTSERVICE) && assetLine.Apttus_Config2__ChargeType__c.equalsIgnoreCase(SERVICEFEE)){
                    assetLine.APTS_Financial_Asset_Status__c='Cancelled';
                }
                //<--v-2.15
                Apttus_Config2__AssetLineItem__c oldasst = (Apttus_Config2__AssetLineItem__c)oldItems.get(assetLine.Id);
                System.debug(' processAssetsoo :'+assetLine.Apttus_CMConfig__AgreementId__c+'  : '+ oldasst.Apttus_CMConfig__AgreementId__c);  
                if(assetLine.Apttus_Config2__AssetStatus__c != oldasst.Apttus_Config2__AssetStatus__c){
                    if(APTS_CheckRecursive.processedSet.contains('APTS_AssetLineItemTriggerHandlerBeforeUpdate')){
                        APTS_CheckRecursive.processedSet.remove('APTS_AssetLineItemTriggerHandlerBeforeUpdate');
                    }
                }
                //v1.4 - 28/08/2019 - LAE/RAR Redesign - Capturing Physical Asset Id on change.
                 if(assetLine.APTS_Physical_Asset__c != oldasst.APTS_Physical_Asset__c && oldasst.APTS_Physical_Asset__c != null){
                     assetLine.APTS_Old_Physical_Asset__c = oldasst.APTS_Physical_Asset__c;
                 }
                //v1.4 
                System.debug('****physicalAssetBundleMap===>'+physicalAssetBundleMap);
                //v-2.10 https://jdecoffee.atlassian.net/browse/DQ-3871
                if(!MapDeinstallDates.isEmpty() && MapDeinstallDates.get(assetLine.Apttus_Config2__LineNumber__c)!= null)
                 assetLine.Apttus_Config2__CancelledDate__c = MapDeinstallDates.get(assetLine.Apttus_Config2__LineNumber__c);
                 //v-2.10 https://jdecoffee.atlassian.net/browse/DQ-3871
                
               //DQ-56 -AssetContractChange Logic  -  Unlink PHA for Cancelled Assets - v1.9
                if(!OrderLineItemMap.isEmpty() && assetLine.Apttus_Config2__AssetStatus__c == 'Cancelled' && OrderLineItemMap.get(assetLine.id) != null)
                { 
                         //DQ-2111- Spin off of DQ-56 Asset Contract Change    
                        assetLine.Apttus_Config2__CancelledDate__c = OrderLineItemMap.get(assetLine.id).Apttus_Config2__CancelledDate__c;
                         //DQ-2111- Spin off of DQ-56 Asset Contract Change   
                    //v2.3 Added by Karan | DQ-1829 START 
                    if(assetLine.APTS_Physical_Asset__c != null && !physicalAssetBundleMap.isEmpty() && physicalAssetBundleMap.get(assetLine.id)!=null){ 
                        assetLine.APTS_Terminated_Physical_Asset__c=assetLine.APTS_Physical_Asset__c;
                        assetLine.APTS_Terminated_PHA_serial_number__c=assetLine.APTS_Serial_Number__c;
                        assetLine.APTS_Term_PHA_Initial_Activation_Date__c = physicalAssetBundleMap.get(assetLine.id).InitialActivationDate__c;
                        //v2.3 Added by Karan | DQ-1829 END
                        assetLine.APTS_Physical_Asset__c=null;                       
                    }
                } 
                
                if(MapRelatedAgremment != null && MapRelatedAgremment.containsKey(assetLine.id))
                assetLine.APTS_relatedlist_agreement__c = MapRelatedAgremment.get(assetLine.id);
                /*v-2.18 System.debug('sapSalesOrderLine--->'+sapSalesOrderLine);
                if(sapSalesOrderLine != null && sapSalesOrderLine.containsKey(assetLine.id))
                 { 
                     assetLine.APTS_Parent_Order_Line_Item__c = sapSalesOrderLine.get(assetLine.id); //v-2.17 ++
                      System.debug('sapSalesOrderLine--->'+assetLine.APTS_Parent_Order_Line_Item__c);
                 }  */
                if(MapOldAssetLine != null && MapOldAssetLine.containsKey(assetLine.id))
                //v-2.13- START
                assetLine.APTS_Terminated_Asset_Line__c= MapOldAssetLine.get(assetLine.id).Id;
                if(MapOldAssetLine != null && MapOldAssetLine.containsKey(assetLine.id)&&MapOldAssetLine.get(assetLine.id).APTS_Type_Of_Contract__c=='Sales')
                assetLine.APTS_Stop_RtR_Transactions_from__c=system.today()-2;
               // v-2.13-END
                if(MapPHAExtid != null && MapPHAExtid.containsKey(assetLine.id))
                assetLine.APTS_PhysicalAssetExtId__c=MapPHAExtid.get(assetLine.id); 
                if(MapInvoiced!=null && MapInvoiced.containsKey(assetLine.id))
                assetLine.APTS_OneTimeInvoiceCheck__c= true;   
                if(mapContractChange != null && mapContractChange.containskey(assetLine.id))
                assetLine.APTS_Contract_Change__c = true;   
                else
                assetLine.APTS_Contract_Change__c = false; 
                
                //AssetContractChange Logic  - DQ-56 - v1.9
                
              if(assetLine.Apttus_Config2__AssetStatus__c!=null && STR_ACTION_ACTIVATED.equalsIgnoreCase(assetLine.Apttus_Config2__AssetStatus__c) && 
                    assetLine.Apttus_Config2__AssetStatus__c != ((Apttus_Config2__AssetLineItem__c)oldItems.get(assetLine.Id)).Apttus_Config2__AssetStatus__c && 
                    assetLine.Apttus_Config2__LineType__c.equalsIgnoreCase('Option')){
                        /*if(orderLineItemBPOMap.get(assetLine.id)!=null){
                            assetLine.APTS_BasePriceOverride__c = orderLineItemBPOMap.get(assetLine.id);
                        }*/
                        if(!orderLineItemBPOMap.isEmpty() && orderLineItemBPOMap.get(assetLine.id)==null){
                            assetLine.APTS_BasePriceOverride__c = null;
                        }
                        //<<++v2.16
                        if(!orderLineItemItemCatMap.isEmpty() && orderLineItemItemCatMap.get(assetLine.id)==null){
                            assetLine.APTS_Item_Category_Adjustment__c = null;
                        }// v2.16>>
                        if(!businessObjectIdMap.isEmpty() &&
                        businessObjectIdMap.get(assetLine.id)!=null){
                            assetLine.APTS_ZX10__c=businessObjectIdMap.get(assetLine.id).APTS_ZX10__c;
                        }
                   System.debug('*****assetLine.APTS_BasePriceOverride__c==============>'+assetLine.APTS_BasePriceOverride__c); 
                }
                //DQ-56 Asset Contract Change Logic - v1.9
                if(assetLine.Apttus_Config2__AssetStatus__c != oldasst.Apttus_Config2__AssetStatus__c &&
                 assetLine.Apttus_Config2__AssetStatus__c.equalsIgnoreCase('Activated')
                && assetLine.APTS_Contract_Change__c){
                    setTerminatedAssetLines.add(assetLine.APTS_Terminated_Asset_Line__c);
                }
                //DQ-56 Asset Contract Change Logic
                
               //
               System.debug('******businessObjectIdMap====>'+businessObjectIdMap);
               System.debug('******assetLine.id======>'+assetLine.id);
               /*if(!businessObjectIdMap.isEmpty() &&
               businessObjectIdMap.get(assetLine.id)!=null &&
               businessObjectIdMap.get(assetLine.id).Apttus_Config2__StartDate__c!=null && 
               businessObjectIdMap.get(assetLine.id).Apttus_Config2__EndDate__c!=null &&
               businessObjectIdMap.get(assetLine.id).Apttus_Config2__SellingTerm__c!=null && 
               businessObjectIdMap.get(assetLine.id).Apttus_Config2__NetPrice__c==0){
                   System.debug('******Asset id====>'+assetLine.id);
                   System.debug('******Start date====>'+businessObjectIdMap.get(assetLine.id).Apttus_Config2__StartDate__c);
                   System.debug('******End date======>'+businessObjectIdMap.get(assetLine.id).Apttus_Config2__EndDate__c);
                   System.debug('******Selling term======>'+businessObjectIdMap.get(assetLine.id).Apttus_Config2__SellingTerm__c);
                   System.debug('******Net price======>'+businessObjectIdMap.get(assetLine.id).Apttus_Config2__NetPrice__c);
                   System.debug('******Net Unit Price======>'+businessObjectIdMap.get(assetLine.id).Apttus_Config2__NetUnitPrice__c);
                   System.debug('******Description======>'+assetLine.Apttus_Config2__Description__c); 
                   assetLine.Apttus_Config2__StartDate__c=businessObjectIdMap.get(assetLine.id).Apttus_Config2__StartDate__c;
                   //assetLine.Apttus_Config2__BillingStartDate__c=businessObjectIdMap.get(assetLine.id).Apttus_Config2__StartDate__c;
                   assetLine.Apttus_Config2__SellingTerm__c=businessObjectIdMap.get(assetLine.id).Apttus_Config2__SellingTerm__c;
                   assetLine.Apttus_Config2__NetPrice__c=businessObjectIdMap.get(assetLine.id).Apttus_Config2__NetPrice__c;
                   assetLine.Apttus_Config2__NetUnitPrice__c=businessObjectIdMap.get(assetLine.id).Apttus_Config2__NetUnitPrice__c;
                   assetLine.Apttus_Config2__EndDate__c=businessObjectIdMap.get(assetLine.id).Apttus_Config2__EndDate__c;
                   assetLine.Apttus_Config2__SellingTerm__c=businessObjectIdMap.get(assetLine.id).Apttus_Config2__SellingTerm__c;
                   assetLine.Apttus_Config2__NetPrice__c=businessObjectIdMap.get(assetLine.id).Apttus_Config2__NetPrice__c;
                  
               }*/
               //Update last related agreement on external movement
               if(!relatedAgreementExtMovmtAssetMap.isEmpty() && relatedAgreementExtMovmtAssetMap.get(assetLine.id)!=null){
                    assetLine.APTS_relatedlist_agreement__c=assetLine.Apttus_CMConfig__AgreementId__c;
               }
               //v-2.11
               if(!financialAgreementMap.isEmpty() && financialAgreementMap.get(assetLine.id)!=null ){                           
                     assetLine.APTS_Financial_Agreement__c=assetLine.Apttus_CMConfig__AgreementId__c;
               }
            }
            
                        system.debug('allCoverage++++'+allCoverage);
                                                system.debug('bCoverage++++'+bCoverage);
                                                                        system.debug('noCoverage++++'+noCoverage);
             for(Apttus_Config2__AssetLineItem__c ali : newAssetList){
             system.debug('ali436++++'+ali );
             if(!businessObjectIdMap.isEmpty() &&
               businessObjectIdMap.get(ali.id)!=null){
            if(ali.Apttus_Config2__Description__c=='ALL-IN COVERAGE'&&ali.Apttus_Config2__ChargeType__c == SERVICEFEE && ali.Apttus_Config2__LineType__c == OPTION && mapAssetPrimL1Id.containsKey(ali.APTS_Is_Primary_L1_Parent__c)&&noCoverage=='true'&&bCoverage=='Default'&&businessObjectIdMap.get(ali.id).Apttus_Config2__LineStatus__c=='New'){
                 mapAssignOriginalDate.put(mapAssetPrimL1Id.get(ali.APTS_Is_Primary_L1_Parent__c), ali.Apttus_Config2__OriginalStartDate__c);
                 system.debug('mapAssignOriginalDateALL-INCOVERAGE++++'+mapAssignOriginalDate);
            }
            if(ali.Apttus_Config2__Description__c=='BASIC COVERAGE'&&ali.Apttus_Config2__ChargeType__c == SERVICEFEE && ali.Apttus_Config2__LineType__c == OPTION && mapAssetPrimL1Id.containsKey(ali.APTS_Is_Primary_L1_Parent__c)&&noCoverage=='true'&&allCoverage=='Default'&&businessObjectIdMap.get(ali.id).Apttus_Config2__LineStatus__c=='New'){
                 mapAssignOriginalDate.put(mapAssetPrimL1Id.get(ali.APTS_Is_Primary_L1_Parent__c), ali.Apttus_Config2__OriginalStartDate__c);
                 system.debug('mapAssignOriginalDateBASICCOVERAGE++++'+mapAssignOriginalDate);
            }
            if(ali.Apttus_Config2__Description__c=='NO COVERAGE'&&ali.Apttus_Config2__ChargeType__c == SERVICEFEE && ali.Apttus_Config2__LineType__c == OPTION && mapAssetPrimL1Id.containsKey(ali.APTS_Is_Primary_L1_Parent__c)&&businessObjectIdMap.get(ali.id).Apttus_Config2__LineStatus__c=='New'&&bCoverage=='Default'&&allCoverage=='Default'){
                 mapAssignOriginalDate.put(mapAssetPrimL1Id.get(ali.APTS_Is_Primary_L1_Parent__c), ali.Apttus_Config2__OriginalStartDate__c);
                 system.debug('mapAssignOriginalDateNOCOVERAGE++++'+mapAssignOriginalDate);
            }
            }
            }
            system.debug('mapAssetPrimL1Id++++'+mapAssetPrimL1Id);
            system.debug('mapAssignOriginalDate++++'+mapAssignOriginalDate);
                    for(Apttus_Config2__AssetLineItem__c ali : [SELECT Id, APTS_Is_Primary_L1_Asset__c, Createddate, Apttus_Config2__OriginalStartDate__c,
                                                                APTS_Is_Primary_L1_Asset__r.Apttus_Config2__OriginalStartDate__c,                                                                                              
                                                                APTS_Stop_RtR_Transactions_from__c FROM Apttus_Config2__AssetLineItem__c 
                                                                    WHERE Apttus_Config2__ChargeType__c =: SERVICEFEE AND 
                                                                    Apttus_Config2__LineType__c =: PRODUCTSERVICE AND 
                                                                    APTS_Is_Primary_L1_Asset__c IN: mapAssetPrimL1Id.values()]){
            
                    system.debug('mapAssignOriginalDate++++'+mapAssignOriginalDate);
                    system.debug('ali++++'+ali);
                                        system.debug('mapAssetLineItem++++'+mapAssetLineItem);
            if(mapAssetLineItem.containsKey(ali.Id) && mapAssignOriginalDate.containsKey(ali.APTS_Is_Primary_L1_Asset__c) && 
                mapAssignOriginalDate.get(ali.APTS_Is_Primary_L1_Asset__c) > ali.APTS_Is_Primary_L1_Asset__r.Apttus_Config2__OriginalStartDate__c){
                //v2.6 - START
                //mapAssetLineItem.get(ali.Id).Apttus_Config2__OriginalStartDate__c = mapAssignOriginalDate.get(ali.APTS_Is_Primary_L1_Asset__c);
                  mapAssetLineItem.get(ali.Id).APTS_RAR_LAE_OriginalStartDate__c = mapAssignOriginalDate.get(ali.APTS_Is_Primary_L1_Asset__c);
                  mapAssetLineItem.get(ali.Id).APTS_Financial_Start_Date__c = mapAssignOriginalDate.get(ali.APTS_Is_Primary_L1_Asset__c);
                  //v2.6 - END
                
            }else if(!mapAssetLineItem.containsKey(ali.Id) && mapAssignOriginalDate.containsKey(ali.APTS_Is_Primary_L1_Asset__c)  && 
                mapAssignOriginalDate.get(ali.APTS_Is_Primary_L1_Asset__c) > ali.APTS_Is_Primary_L1_Asset__r.Apttus_Config2__OriginalStartDate__c) {
                Apttus_Config2__AssetLineItem__c assetlineitem =  new Apttus_Config2__AssetLineItem__c(Id = ali.Id);
                //v2.6 - START
                //assetlineitem.Apttus_Config2__OriginalStartDate__c = mapAssignOriginalDate.get(ali.APTS_Is_Primary_L1_Asset__c);
                assetlineitem.APTS_RAR_LAE_OriginalStartDate__c = mapAssignOriginalDate.get(ali.APTS_Is_Primary_L1_Asset__c);
                assetlineitem.APTS_Financial_Start_Date__c = mapAssignOriginalDate.get(ali.APTS_Is_Primary_L1_Asset__c);
                //v2.6 - END
                mapAssetLineItem.put(assetlineitem.id, assetlineitem);
                            system.debug('mapAssetLineItem++++'+mapAssetLineItem);
                
            }else {ali.APTS_Financial_Start_Date__c =ali.Apttus_Config2__OriginalStartDate__c;}
            
            }
           //DQ-56 Asset Contract Change Logic- Karan changes - v1.10
            Set<String> lstMapValues = new Set<String>();
            Map<id,Apttus_Config2__AssetLineItem__c> terminatedAssetMapCTC = new Map<id,Apttus_Config2__AssetLineItem__c>();
            String str1=''; 
            for(APTS_Asset_Fields_Mapping__mdt meta : [SELECT Id, APTS_New_Asset_Line__c FROM APTS_Asset_Fields_Mapping__mdt]){
            lstMapValues.add(meta.APTS_New_Asset_Line__c);
                str1 += meta.APTS_New_Asset_Line__c+',';
            }
            String str2 = str1.removeEnd(',');            
            String str = Label.APTS_SelectLabel+EMPTY_STRING + str2 +EMPTY_STRING+Label.APTS_AssetLine_ContractChangeQuery;
            //Adding FOR Update to resolve concurrent exception
            System.debug('str=====>'+str);
            for(Apttus_Config2__AssetLineItem__c oldAsset  : Database.query(str)){
                if(terminatedAssetMapCTC.get(oldAsset.id)==null){
                    terminatedAssetMapCTC.put(oldAsset.id,oldAsset);
                }
            }
            
            
           //DQ-56 Asset Contract Change Logic - v.10
            
            if(!APTS_CheckRecursive.processedSet.contains('APTS_AssetLineItemTriggerHandlerBeforeUpdate')){
                APTS_CheckRecursive.processedSet.add('APTS_AssetLineItemTriggerHandlerBeforeUpdate');
                Map<Id, Id> mapOLIIdAssetId = new Map<Id, Id>();
                List<Apttus_Config2__AssetLineItem__c> aLIList = new List<Apttus_Config2__AssetLineItem__c>();
                List<Apttus_Config2__AssetLineItem__c> assetList = new List<Apttus_Config2__AssetLineItem__c>();
                
                APTS_AssetLineItemTriggerHandler.processAsset((Map<Id, Apttus_Config2__AssetLineItem__c>)oldItems, (Map<Id, Apttus_Config2__AssetLineItem__c>)newItems); 
                
                //v1.1 starts here. 25/06/2018. Modified by Beulah Thomas
                /* For machine breakdown, an asset line item will be updated with status amended or existing,
                for such records counter reading data for older asset line item should be cloned and in the
                newly created counter reading data, new asset line item has to be updated
                Test Class : APTS_ConsumptionCounterReadingDataTest */
                APTS_BIRUtils.cloneCounterReading(newList, newItems, oldList, oldItems);
                /*For Consumption model counter data. When asset line item is updated, then its corresponding counter data has
                to be updated with relavent data.
                Test Class : APTS_ConsumptionCounterReadingDataTest*/
                APTS_BIRUtils.updateCounterReading(newList, newItems, oldList, oldItems);
                //v1.1 ends here. 25/06/2018. Modified by Beulah Thomas
            
                for (Apttus_Config2__AssetLineItem__c tmpAsset : (List<Apttus_Config2__AssetLineItem__c>) newItems.values()) {
                    if (STR_ACTION_ACTIVATED.equalsIgnoreCase(tmpAsset.Apttus_Config2__AssetStatus__c) && tmpAsset.Apttus_Config2__AssetStatus__c != ((Apttus_Config2__AssetLineItem__c)oldItems.get(tmpAsset.Id)).Apttus_Config2__AssetStatus__c) {
                        tmpAsset.APTS_Old_Net_Price__c = (tmpAsset.APTS_Consolidated_Price__c!=null ? tmpAsset.APTS_Consolidated_Price__c : 0) + (tmpAsset.APTS_Service_Rollup_Net_Amount__c!=null ? tmpAsset.APTS_Service_Rollup_Net_Amount__c : 0);
                        aLIList.add(tmpAsset);
                    }
                    
                    if(tmpAsset.APTS_Is_Primary_L1_Parent__c != NULL){
                        mapOLIIdAssetId.put(tmpAsset.APTS_Is_Primary_L1_Parent__c, NULL);
                    }
                }
            if(aLIList.size() > 0){
                APTS_CLMUtil.mapAgreementFieldInALI(aLIList);
            }
            
            //CR 2007 Start
            for(Apttus_Config2__OrderLineItem__c tmpOLI : [SELECT Id, Apttus_Config2__AssetLineItemId__c FROM Apttus_Config2__OrderLineItem__c WHERE Id IN :mapOLIIdAssetId.keySet()]){
                mapOLIIdAssetId.put(tmpOLI.Id, tmpOLI.Apttus_Config2__AssetLineItemId__c);
            }
            system.debug('mapOLIIdAssetId :: '+ mapOLIIdAssetId.Values());
            for(Apttus_Config2__AssetLineItem__c assetlineitem : (List<Apttus_Config2__AssetLineItem__c>) newList){
                Apttus_Config2__AssetLineItem__c oldasst = (Apttus_Config2__AssetLineItem__c)oldItems.get(assetlineitem.Id);
                if(assetlineitem.Apttus_Config2__AssetStatus__c != NULL && assetlineitem.Apttus_Config2__AssetStatus__c == 'Activated'
                    && assetlineitem.Apttus_Config2__AssetStatus__c != oldasst.Apttus_Config2__AssetStatus__c
                    && assetlineitem.APTS_Is_Primary_L1_Parent__c != NULL && mapOLIIdAssetId.containsKey(assetlineitem.APTS_Is_Primary_L1_Parent__c) && mapOLIIdAssetId.get(assetlineitem.APTS_Is_Primary_L1_Parent__c) != NULL
                    && assetlineitem.Id != mapOLIIdAssetId.get(assetlineitem.APTS_Is_Primary_L1_Parent__c)){
                    assetlineitem.APTS_Is_Primary_L1_Asset__c = mapOLIIdAssetId.get(assetlineitem.APTS_Is_Primary_L1_Parent__c);
                }
                //DQ-56 - Asset Contract Change Logic v1.10
                if(assetlineitem.APTS_Terminated_Asset_Line__c!=null && !terminatedAssetMapCTC.isEmpty() && terminatedAssetMapCTC.get(assetlineitem.APTS_Terminated_Asset_Line__c)!=null){
                   for(String  newapi : lstMapValues){ 
                   if(newapi!=null && terminatedAssetMapCTC.get(assetlineitem.APTS_Terminated_Asset_Line__c).get(newapi)!=null){
                            assetlineitem.put(newapi,terminatedAssetMapCTC.get(assetlineitem.APTS_Terminated_Asset_Line__c).get(newapi));
                        }
                    }
                } //DQ-56 Asset Contract Change Logic
                //Added logic to populate Latest order sub type and order type
                System.debug('PHA KARAN orderlineItemDetailsMap=====================>'+orderlineItemDetailsMap);
                if(!orderlineItemDetailsMap.isEmpty() && orderlineItemDetailsMap.get(assetlineitem.id)!=null && orderlineItemDetailsMap.get(assetlineitem.id).Apttus_Config2__OrderId__c!=null && orderlineItemDetailsMap.get(assetlineitem.id).Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c!=null){
                    assetlineitem.APTS_Latest_order_sub_type__c= orderlineItemDetailsMap.get(assetlineitem.id).Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c;
                }
                if(!orderlineItemDetailsMap.isEmpty() && orderlineItemDetailsMap.get(assetlineitem.id)!=null && orderlineItemDetailsMap.get(assetlineitem.id).Apttus_Config2__OrderId__c!=null && orderlineItemDetailsMap.get(assetlineitem.id).Apttus_Config2__OrderId__r.APTS_Order_Type__c!=null){
                    assetlineitem.APTS_latest_order_type__c= orderlineItemDetailsMap.get(assetlineitem.id).Apttus_Config2__OrderId__r.APTS_Order_Type__c;
                }
                if(!orderlineItemDetailsMap.isEmpty() && orderlineItemDetailsMap.get(assetlineitem.id)!=null && orderlineItemDetailsMap.get(assetlineitem.id).Apttus_Config2__OrderId__c!=null && orderlineItemDetailsMap.get(assetlineitem.id).APTS_Serial_Number__c!=null){
                    assetlineitem.APTS_OLI_serial_number__c= orderlineItemDetailsMap.get(assetlineitem.id).APTS_Serial_Number__c;
                }
                
                
            }
            //CR 2007 End
        }
    }catch (Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex',ex.getStackTraceString() + '/n/n' + ex.getMessage() ,'AssetLineTriggerHandler','beforeUpdate', 'CLM', false, false, null, true);}   
    }
    public void BeforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems) {}
    public void AfterInsert(List<SObject> newList, Map<Id, SObject> newItems) {
        try{
       // v1.2 - QTCFLEX1-992 START
            List<Apttus_Config2__AssetLineItem__c> newAssetList = (List<Apttus_Config2__AssetLineItem__c>) newList;
            Set<Id> astIdSet = new Set<Id>();
            Map<Id, Integer> assetHstCount = new Map<Id, Integer>();
            List<Apttus_Config2__AssetLineItem__c> assetLineItemList = new List<Apttus_Config2__AssetLineItem__c>();
            List<Apttus_Config2__AssetLineItem__c> lstAssetLineItem = new List<Apttus_Config2__AssetLineItem__c  >();
            List<APTS_Historical_Price_Change__c> createList = new List<APTS_Historical_Price_Change__c>();
            List<APTS_Historical_Price_Change__c> updateList = new List<APTS_Historical_Price_Change__c>();
            Map<id, Apttus_Config2__AssetLineItem__c> netPriceAdditionalServiceToServiceMap = new Map<id, Apttus_Config2__AssetLineItem__c>();
            mapHistory = new Map<Id, String>();
            // v1.2 - QTCFLEX1-992 END     
            //v1.7 - DFT2C-2034 - START
            Map<Id, Date> mapAssignOriginalDate = new Map<Id, Date>();
            Map<Id, Id> mapAssetPrimL1Id = new Map<Id, Id>();
            Set<Id> setOrderParentL1Id = new Set<Id>();
            Set<Id> oliForProcessAdjustmentSet = new Set<Id>();
            Id assetId = null; 
             Map<Id,PhysicalAsset__c> physicalAssetUpdateMap = new Map<Id,PhysicalAsset__c>();              
            Map<Id, Apttus_Config2__AssetLineItem__c> mapAssetLineItem = new Map<Id, Apttus_Config2__AssetLineItem__c>();
            //v1.7 - DFT2C-2034 - END       
            //Added by Swagatika Biswal (CommerceCX) as part of defect 21117
            for (Apttus_Config2__AssetLineItem__c assetlineitem : [SELECT Id, Apttus_Config2__AssetNumber__c, APTS_Is_Primary_L1_Asset__c,APTS_Stop_RtR_Transactions_from__c FROM Apttus_Config2__AssetLineItem__c WHERE Id IN :newItems.keyset()]){
                assetlineitem.Apttus_Config2__AssetNumber__c = assetlineitem.id;
                lstAssetLineItem.add(assetlineitem);
               // v1.2 - QTCFLEX1-992 START
                if(assetHstCount.get(assetlineitem.Id) == NULL){
                    astIdSet.add(assetlineitem.Id);
                }
               // v1.2 - QTCFLEX1-992 END                
            }
           // v1.2 - QTCFLEX1-992 START 
            for (Apttus_Config2__AssetTransactionHistory__c tmpHistory : [SELECT Id, Apttus_Config2__AssetLineItemId__c, Apttus_Config2__Action__c FROM Apttus_Config2__AssetTransactionHistory__c WHERE Apttus_Config2__AssetLineItemId__c IN :newList ORDER BY CreatedDate DESC]) {
                if (mapHistory.get(tmpHistory.Apttus_Config2__AssetLineItemId__c) == null) {
                    if (tmpHistory.Apttus_Config2__Action__c != null) {
                    mapHistory.put(tmpHistory.Apttus_Config2__AssetLineItemId__c, tmpHistory.Apttus_Config2__Action__c);
                    }else{
                    mapHistory.put(tmpHistory.Apttus_Config2__AssetLineItemId__c, '');
                    }
                }  
            }
            for(AggregateResult agr : [SELECT COUNT(ID) counter,APTS_AssetLineItem__c asset FROM APTS_Historical_Price_Change__c where APTS_AssetLineItem__c IN :newItems.keyset() GROUP BY APTS_AssetLineItem__c]){
                assetHstCount.put((Id) agr.get('asset'), (Integer) agr.get('counter'));
            }
            
           /*Added by akhilesh for Updating and creating the Historical changes - consolidated */
            for (Apttus_Config2__AssetLineItem__c aLI : [SELECT Id, Apttus_Config2__EndDate__c, Apttus_Config2__AssetStatus__c, Apttus_Config2__StartDate__c, Apttus_Config2__NetPrice__c, Apttus_Config2__SellingTerm__c, APTS_Amendment_Effective_Date__c,
            Apttus_Config2__SellingFrequency__c, Apttus_Config2__ChargeType__c, APTS_Is_Primary_L1_Parent__c, Apttus_Config2__LineType__c, APTS_Service_Rollup_Net_Amount__c, APTS_Is_Primary_L1_Asset__c, APTS_Consolidated_Price__c, (SELECT Id, APTS_AssetLineItem__c, APTS_End_date__c, APTS_Net_Price__c, APTS_Selling_term__c, APTS_Timestamp__c, APTS_Start_date__c FROM Historical_Price_Changes__r order by APTS_Timestamp__c DESC limit 1),
            APTS_Stop_RtR_Transactions_from__c FROM Apttus_Config2__AssetLineItem__c WHERE Id IN: astIdSet]) {
                assetLineItemList.add(aLI);
            }
             
            for (Apttus_Config2__AssetLineItem__c astLI : assetLineItemList) {
                APTS_Historical_Price_Change__c createHistoricalPriceChange = new APTS_Historical_Price_Change__c();
                if(astLI.Historical_Price_Changes__r.size() <= 0 && !STR_ACTION_CANCELLED.equalsIgnoreCase(astLI.Apttus_Config2__AssetStatus__c)){
                    createHistoricalPriceChange.APTS_Start_date__c = astLI.Apttus_Config2__StartDate__c;
                    createHistoricalPriceChange.APTS_End_date__c = astLI.Apttus_Config2__EndDate__c;
                    createHistoricalPriceChange.APTS_Timestamp__c = System.now();
                    createHistoricalPriceChange.APTS_Net_Price__c = astLI.Apttus_Config2__NetPrice__c;
                    createHistoricalPriceChange.APTS_AssetLineItem__c = astLI.Id;
                    if(astLI.Apttus_Config2__SellingFrequency__c == 'One Time'){
                        createHistoricalPriceChange.APTS_Duration1__c = 1;
                    }
                    else{
                        createHistoricalPriceChange.APTS_Duration1__c = Apttus_Config2.CPQWebService.computeTerm(createHistoricalPriceChange.APTS_Start_date__c, createHistoricalPriceChange.APTS_End_date__c, astLI.Apttus_Config2__SellingFrequency__c);
                    }
                    createHistoricalPriceChange.APTS_Selling_term__c = createHistoricalPriceChange.APTS_Duration1__c;
                    createList.add(createHistoricalPriceChange);
                }
            }
            
            if (createList.size() > 0) {
                Database.insert(createList , false);
            }
            System.debug('Debug Line'+newList);
             System.debug('Debug Line'+mapHistory);
            //v2.4 - START 
            lstAssetLineItem.addAll(APTS_CLMUtil.calculateAssetBaseExtendedPrice(newList, null)); 
            //v2.4 - END
             System.debug('Debug Line'+lstAssetLineItem); 
        // v1.2 - QTCFLEX1-992 END
        // v1.7 - DFT2C-2034 - START        
        system.debug(' lstAssetLineItem --> '+ lstAssetLineItem);
        for(Apttus_Config2__AssetLineItem__c ali : lstAssetLineItem){
                 mapAssetLineItem.put(ali.Id, ali);
        }
        /*for(Apttus_Config2__AssetLineItem__c ali : newAssetList){
            if(string.isNotBlank(ali.APTS_Is_Primary_L1_Parent__c)){
                setOrderParentL1Id.add(ali.APTS_Is_Primary_L1_Parent__c);
            }
        }*/
       /* for(Apttus_Config2__OrderLineItem__c oli :[SELECT Id, Apttus_Config2__AssetLineItemId__c, Apttus_Config2__AssetLineItemId__r.APTS_Is_Primary_L1_Line__c FROM Apttus_Config2__OrderLineItem__c WHERE Id IN: setOrderParentL1Id]){            
            if(oli.Apttus_Config2__AssetLineItemId__r.APTS_Is_Primary_L1_Line__c){
                mapAssetPrimL1Id.put(oli.Id, oli.Apttus_Config2__AssetLineItemId__c);
            }
        }*/
        
            
        for(Apttus_Config2__AssetLineItem__c ali : newAssetList){
            /*if(ali.Apttus_Config2__ChargeType__c == SERVICEFEE && ali.Apttus_Config2__LineType__c == OPTION && mapAssetPrimL1Id.containsKey(ali.APTS_Is_Primary_L1_Parent__c)){
                 mapAssignOriginalDate.put(mapAssetPrimL1Id.get(ali.APTS_Is_Primary_L1_Parent__c), ali.Apttus_Config2__OriginalStartDate__c);
            }*/
            //v1.8 --->
            if(ali.Apttus_Config2__BusinessLineItemId__c!=null){
                oliForProcessAdjustmentSet.add(ali.Apttus_Config2__BusinessLineItemId__c);
            }
            //v1.8  <---
        }
             
     /*
        for(Apttus_Config2__AssetLineItem__c ali : [SELECT Id, APTS_Is_Primary_L1_Asset__c, Createddate, Apttus_Config2__OriginalStartDate__c,
                                                                APTS_Is_Primary_L1_Asset__r.Apttus_Config2__OriginalStartDate__c,                                                                                              
                                                                APTS_Stop_RtR_Transactions_from__c FROM Apttus_Config2__AssetLineItem__c 
                                                                    WHERE Apttus_Config2__ChargeType__c =: SERVICEFEE AND 
                                                                    Apttus_Config2__LineType__c =: PRODUCTSERVICE AND 
                                                                    APTS_Is_Primary_L1_Asset__c IN: mapAssetPrimL1Id.values()]){
            
        
            if(mapAssetLineItem.containsKey(ali.Id) && mapAssignOriginalDate.containsKey(ali.APTS_Is_Primary_L1_Asset__c) && 
                mapAssignOriginalDate.get(ali.APTS_Is_Primary_L1_Asset__c) > ali.APTS_Is_Primary_L1_Asset__r.Apttus_Config2__OriginalStartDate__c){
                //v2.6 - START
                //mapAssetLineItem.get(ali.Id).Apttus_Config2__OriginalStartDate__c = mapAssignOriginalDate.get(ali.APTS_Is_Primary_L1_Asset__c);
                  mapAssetLineItem.get(ali.Id).APTS_RAR_LAE_OriginalStartDate__c = mapAssignOriginalDate.get(ali.APTS_Is_Primary_L1_Asset__c);
                  mapAssetLineItem.get(ali.Id).APTS_Financial_Start_Date__c = mapAssignOriginalDate.get(ali.APTS_Is_Primary_L1_Asset__c);
                  //v2.6 - END
                
            }else if(!mapAssetLineItem.containsKey(ali.Id) && mapAssignOriginalDate.containsKey(ali.APTS_Is_Primary_L1_Asset__c)  && 
                mapAssignOriginalDate.get(ali.APTS_Is_Primary_L1_Asset__c) > ali.APTS_Is_Primary_L1_Asset__r.Apttus_Config2__OriginalStartDate__c) {
                Apttus_Config2__AssetLineItem__c assetlineitem =  new Apttus_Config2__AssetLineItem__c(Id = ali.Id);
                //v2.6 - START
                //assetlineitem.Apttus_Config2__OriginalStartDate__c = mapAssignOriginalDate.get(ali.APTS_Is_Primary_L1_Asset__c);
                assetlineitem.APTS_RAR_LAE_OriginalStartDate__c = mapAssignOriginalDate.get(ali.APTS_Is_Primary_L1_Asset__c);
                assetlineitem.APTS_Financial_Start_Date__c = mapAssignOriginalDate.get(ali.APTS_Is_Primary_L1_Asset__c);
                //v2.6 - END
                mapAssetLineItem.put(assetlineitem.id, assetlineitem);
                
            }
            
            }*/
       
         
            APTS_AssetLineItemTriggerHandler.processAsset(null, (Map<Id, Apttus_Config2__AssetLineItem__c>)newItems); 
            
           /* if(mapAssetLineItem.size() > 0){
                isSkipAssetlineitemTrigger = true;
                update mapAssetLineItem.values();
                isSkipAssetlineitemTrigger = false;
            }*/
            // v1.7 - DFT2C-2034 - END
            //Create Asset Adjustment Line Items
            //v1.8 --->
            if(!oliForProcessAdjustmentSet.isEmpty()){
                APTS_CLMUtil.manageAssetAdjLineItemData(oliForProcessAdjustmentSet);
            }
            //v1.8 <---
        }catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex',ex.getStackTraceString() + '/n/n' + ex.getMessage() ,'AssetLineTriggerHandler','AfterInsert', 'CLM', false, false, null, true);}
    }
    public void AfterUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldItems) {
        try {
            List<Apttus_Config2__AssetLineItem__c> newAssetList = (List<Apttus_Config2__AssetLineItem__c>) newList;
            List<Id> lstAssetForMovementId = new List<Id>();
            Map<ID, ID> L1ToServiceFeeMap = new Map<ID, ID>();
            Map<Id, Apttus_Config2__AssetLineItem__c> oldMapAsset = (Map<Id, Apttus_Config2__AssetLineItem__c>) oldItems;
            // v1.4 - DFT2C-853 - START
            Set<Id> setALIServiceBundleOption = new Set<Id>();
            Set<Id> businessObjectLineItemSet = new Set<Id>();
            Set<String> setServiceAddiFee = new Set<String>{SERVICEFEE, ADDITIONALSERVICEFEE};
            Map<Id, Id> mapAssetPreviousAgreement = new Map<Id, Id>();
            Map<Id, Boolean> mapAssetLineItem = new Map<Id, Boolean>();
            Set<Id> oliForProcessAdjustmentSet = new Set<Id>();
            Map<Id, SObject> oldItemsMachinePha = new Map<Id, SObject>();
            //Map<Id,Apttus_Config2__OrderLineItem__c> businessObjectIdMap = new Map<Id,Apttus_Config2__OrderLineItem__c>();
            Map<Id,Apttus_Config2__OrderLineItem__c> businessObjectIdMap = new Map<Id,Apttus_Config2__OrderLineItem__c>();
            List<Apttus_Config2__OrderLineItem__c> ListOrderLineItem=new List<Apttus_Config2__OrderLineItem__c>();
            String option = 'Option';
            // v1.4 - DFT2C-853 - END
            //v1.7 - DFT2C-2034 - START
             Set<Id> setAssetPrimL1Id = new Set<Id>();
             Id assetId = null;
            //v1.7 - DFT2C-2034 - END
            for (Apttus_Config2__AssetLineItem__c  assetLine : newAssetList) {
                Apttus_Config2__AssetLineItem__c oldasst = (Apttus_Config2__AssetLineItem__c)oldItems.get(assetLine.Id);
                 if(assetLine.Apttus_Config2__BusinessLineItemId__c!=null){
                    businessObjectLineItemSet.add(assetLine.Apttus_Config2__BusinessLineItemId__c);
                }
                if(assetLine.Apttus_Config2__AssetStatus__c != oldasst.Apttus_Config2__AssetStatus__c){
                    if(APTS_CheckRecursive.processedSet.contains('APTS_AssetLineItemTriggerHandlerAfterUpdate')){
                        APTS_CheckRecursive.processedSet.remove('APTS_AssetLineItemTriggerHandlerAfterUpdate');
                    }
                    //v1.8 --->
                    //Added to only process Adjustments when Business Line Item is changed i.e Order line items
                    if(assetLine.Apttus_Config2__BusinessLineItemId__c!=null){
                        oliForProcessAdjustmentSet.add(assetLine.Apttus_Config2__BusinessLineItemId__c);
                    }
                    //v1.8 <---
                }
                if(assetLine.APTS_Is_Primary_L1_Asset__c != null && SERVICEFEE.equalsIgnoreCase(assetLine.Apttus_Config2__ChargeType__c) && assetLine.Apttus_Config2__LineType__c == PRODUCTSERVICE)
                {
                    L1ToServiceFeeMap.put(assetLine.APTS_Is_Primary_L1_Asset__c, assetLine.ID);
                    // v1.4 - DFT2C-853 - START
                    if(SALES.equalsIgnoreCase(assetLine.APTS_Type_Of_Contract__c)){ setALIServiceBundleOption.add(assetLine.APTS_Is_Primary_L1_Asset__c); }
                    // v1.4 - DFT2C-853 - END
                }
                //v2.4 - START
                if(oldMapAsset!=null && assetLine!=null && assetLine.id!=null && !oldMapAsset.isEmpty() && 
                oldMapAsset.get(assetLine.id).Apttus_Config2__AssetStatus__c!=null && oldMapAsset.get(assetLine.id).Apttus_Config2__AssetStatus__c.equalsIgnoreCase('Activated') &&
                assetLine.Apttus_Config2__AssetStatus__c!=null && assetLine.Apttus_Config2__AssetStatus__c.equalsIgnoreCase('Pending Change') &&
                oldMapAsset.get(assetLine.id).Apttus_Config2__NetPrice__c!=null && assetLine.Apttus_Config2__NetPrice__c!=null && 
                oldMapAsset.get(assetLine.id).Apttus_Config2__NetPrice__c!=assetLine.Apttus_Config2__NetPrice__c){
                    if(APTS_CLMUtil.oldMapNetPrice.get(assetLine.id)==null){
                        APTS_CLMUtil.oldMapNetPrice.put(assetLine.id,assetLine);
                     }
                }
                //v2.4 - END
            }
             System.debug('########## CTC BPO businessObjectLineItemSet=============>'+businessObjectLineItemSet);
            ListOrderLineItem = new List<Apttus_Config2__OrderLineItem__c>([Select id,Apttus_Config2__AssetLineItemId__c,
                                                                            Apttus_Config2__OrderId__r.APTS_Contract_Change__c,
                                                                            Apttus_Config2__OrderId__r.APTS_Admin_Movement__c,
                                                                            Apttus_Config2__OrderId__r.APTS_Order_Type__c,
                                                                            Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c,
                                                                            Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c,
                                                                            Apttus_Config2__OrderId__r.APTS_Change_of_Ownership__c,
                                                                            Apttus_Config2__Status__c,
                                                                            Apttus_Config2__CancelledDate__c,
                                                                            Apttus_Config2__LineStatus__c,
                                                                            Apttus_Config2__BillingFrequency__c,
                                                                            Apttus_Config2__ChargeType__c,
                                                                            APTS_ZX10__c,
                                                                            APTS_Is_Primary_L1_Line__c,
                                                                            APTS_De_installation_Date_Authorized__c,
                                                                            Apttus_Config2__AssetLineItemId__r.Apttus_Config2__LineNumber__c,
                                                                            Apttus_Config2__DerivedFromId__r.APTS_Terminated_Asset_Line__r.Apttus_Config2__ChargeType__c,
                                                                            Apttus_Config2__DerivedFromId__r.APTS_Terminated_Asset_Line__r.Apttus_Config2__BillingFrequency__c,
                                                                            Apttus_Config2__DerivedFromId__r.APTS_Terminated_Asset_Line__r.APTS_relatedlist_agreement__c,
                                                                            Apttus_Config2__DerivedFromId__r.APTS_Terminated_Asset_Line__c,
                                                                            Apttus_Config2__DerivedFromId__r.APTS_Terminated_Asset_Line__r.APTS_Type_Of_Contract__c,
                                                                            Apttus_Config2__DerivedFromId__r.APTS_Terminated_Asset_Line__r.APTS_PhysicalAssetExtId__c,
                                                                            Apttus_Config2__BasePriceOverride__c,
                                                                            Apttus_Config2__StartDate__c,
                                                                            Apttus_Config2__EndDate__c,
                                                                            Apttus_Config2__SellingTerm__c,
                                                                            Apttus_Config2__NetPrice__c,
                                                                            Apttus_Config2__NetUnitPrice__c,
                                                                            APTS_Serial_Number__c 
                                                                            from Apttus_Config2__OrderLineItem__c 
                                                                            where id IN: businessObjectLineItemSet 
                                                                           // and Apttus_Config2__Status__c='Activated'
                                                                           ]);
             if(ListOrderLineItem != NULL && ListOrderLineItem.size()>0){
                for(Apttus_Config2__OrderLineItem__c instOrderLineItem : ListOrderLineItem){
                    
                   if(instOrderLineItem.Apttus_Config2__AssetLineItemId__c!=null && businessObjectIdMap.get(instOrderLineItem.Apttus_Config2__AssetLineItemId__c)==null && instOrderLineItem.Apttus_Config2__OrderId__c!=null && instOrderLineItem.Apttus_Config2__OrderId__r.APTS_Order_Type__c!=null && instOrderLineItem.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c!=null){
                       
                   businessObjectIdMap.put(instOrderLineItem.Apttus_Config2__AssetLineItemId__c,instOrderLineItem);                   
                }
                }
             }
            for (Apttus_Config2__AssetLineItem__c  assetLine : newAssetList) {
                
                if(ADDITIONALSERVICEFEE.equalsIgnoreCase(assetLine.Apttus_Config2__ChargeType__c) && assetLine.Apttus_Config2__LineType__c == PRODUCTSERVICE)
                {
                    additionalFeeToServiceFeeMap.put(assetLine.ID, L1ToServiceFeeMap.get(assetLine.APTS_Is_Primary_L1_Asset__c));
                }
                
            }
            if(!APTS_CheckRecursive.processedSet.contains('APTS_AssetLineItemTriggerHandlerAfterUpdate')){
                APTS_CheckRecursive.processedSet.add('APTS_AssetLineItemTriggerHandlerAfterUpdate');
                
                //Defect 24345/CR 2303 - Update Billing Schedules when 'Sold To' and 'Bill To' values are modified in Asset Line Item               
                APTS_BIRUtils.updateBillingScheduleSoldTo(newList, oldItems);
                
                //v1.8 --->
                //Create/Update Asset Adjustment Line Items
                if(!oliForProcessAdjustmentSet.isEmpty()){
                    APTS_CLMUtil.manageAssetAdjLineItemData(oliForProcessAdjustmentSet);
                }
                //v1.8 <---
                
                //Processing Asset Line Items for RtR-LAE Staging
                
                mapHistory = new Map<Id, String>();
                
                for (Apttus_Config2__AssetTransactionHistory__c tmpHistory : [SELECT Id, Apttus_Config2__AssetLineItemId__c, Apttus_Config2__Action__c FROM Apttus_Config2__AssetTransactionHistory__c WHERE Apttus_Config2__AssetLineItemId__c IN :newList ORDER BY CreatedDate DESC]) {
                    if (mapHistory.get(tmpHistory.Apttus_Config2__AssetLineItemId__c) == null) {
                        if (tmpHistory.Apttus_Config2__Action__c != null) {
                            mapHistory.put(tmpHistory.Apttus_Config2__AssetLineItemId__c, tmpHistory.Apttus_Config2__Action__c);
                        }else{
                            mapHistory.put(tmpHistory.Apttus_Config2__AssetLineItemId__c, '');
                        }
                        
                    }
                }
                /*for (Apttus_Config2__OrderLineItem__c tmpOLI : [SELECT Id, Apttus_Config2__AssetLineItemId__c, Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c FROM Apttus_Config2__OrderLineItem__c WHERE Apttus_Config2__AssetLineItemId__c IN :newList AND Apttus_Config2__Status__c =: STR_ACTION_ACTIVATED]) {
                    mapIdOrderSubType.put(tmpOLI.Apttus_Config2__AssetLineItemId__c, tmpOLI.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c);
                }*/
                
                System.debug(' processAssets :'+processAssets.size());
                
                //Movement Order        
                for(Apttus_Config2__AssetLineItem__c mvmntAst : newAssetList){
                System.debug('*****NEW ASSET STATUS=====>'+mvmntAst.Apttus_Config2__AssetStatus__c);
                System.debug('*****OLD ASSET STATUS=====>'+oldMapAsset.get(mvmntAst.id).Apttus_Config2__AssetStatus__c);
                System.debug('*****NEW NET PRICE=====>'+mvmntAst.Apttus_Config2__NetPrice__c);
                System.debug('*****OLD NET PRICE=====>'+oldMapAsset.get(mvmntAst.id).Apttus_Config2__NetPrice__c);
                    if(processAssets.Containskey(mvmntAst.Id)){
                        Apttus_Config2__AssetLineItem__c oldAssetLineItem = (Apttus_Config2__AssetLineItem__c)processAssets.get(mvmntAst.Id);       
                        if(oldAssetLineItem!=null){                             
                            if(mvmntAst.Apttus_CMConfig__AgreementId__c != oldAssetLineItem.Apttus_CMConfig__AgreementId__c && oldAssetLineItem.Apttus_CMConfig__AgreementId__c != null &&mvmntAst.Apttus_Config2__LineType__c == PRODUCTSERVICE){      
                                lstAssetForMovementId.add(mvmntAst.Id);     
                            }       
                        } 
                    }  
                    // v1.4 - DFT2C-853 - START
                    if(mvmntAst.Apttus_Config2__AssetStatus__c == STR_ACTION_ACTIVATED || mvmntAst.Apttus_Config2__AssetStatus__c == STR_ACTION_CANCELLED) {
                        isFinalStatus = true;
                        system.debug('tmpAsset.Apttus_Config2__AssetStatus__c '+mvmntAst.Apttus_Config2__AssetStatus__c);
                    }  
                    // v1.4 - DFT2C-853 - END
                    // v1.7 - DFT2C-2034 - START
                    assetId = mvmntAst.APTS_Is_Primary_L1_Asset__c != null ? mvmntAst.APTS_Is_Primary_L1_Asset__c : mvmntAst.Id;
                    setAssetPrimL1Id.add(assetId);  
                    // v1.7 - DFT2C-2034 - END            
                }       
                List<Apttus_Config2__AssetLineItem__c> mvmntLst = new List<Apttus_Config2__AssetLineItem__c>();     
                if(lstAssetForMovementId != null){      
                    for (Apttus_Config2__AssetLineItem__c aLI : [SELECT Id, APTS_Old_Gross_Price__c, APTS_Old_Net_Price__c, APTS_Amendment_Effective_Date__c,       
                                                                 Apttus_Config2__SellingFrequency__c, (SELECT Id, APTS_AssetLineItem__c, APTS_End_date__c, APTS_Net_Price__c, APTS_Selling_term__c, APTS_Timestamp__c, APTS_Start_date__c FROM Historical_Price_Changes__r order by APTS_Timestamp__c DESC limit 1),     
                                                                 APTS_Stop_RtR_Transactions_from__c FROM Apttus_Config2__AssetLineItem__c WHERE Id IN: lstAssetForMovementId]) {       
                                                                     mvmntLst.add(aLI);     
                                                                 }      
                                
                    List<APTS_Historical_Price_Change__c> lsthistory = new List<APTS_Historical_Price_Change__c>();     
                    List<APTS_Historical_Price_Change__c> inactivehistoricallist = new List<APTS_Historical_Price_Change__c>();     
                            
                    for (Apttus_Config2__AssetLineItem__c astLI : mvmntLst) {       
                        APTS_Historical_Price_Change__c updateHistoricalPriceChange = new APTS_Historical_Price_Change__c();        
                        if (astLI.Historical_Price_Changes__r.size() > 0) {updateHistoricalPriceChange.Id = astLI.Historical_Price_Changes__r[0].Id;updateHistoricalPriceChange.APTS_End_date__c = System.today();lsthistory.add(updateHistoricalPriceChange);}       
                    }       
                            
                    if(lsthistory!=null){       
                        update(lsthistory);     
                    }       
                            
                    List<Apttus_Config2__AssetLineItem__c> Oldvaluesupdate = new List<Apttus_Config2__AssetLineItem__c>([SELECT Id,              APTS_Calculated_Base_Extended_Price__c, APTS_Consolidated_Price__c, APTS_Old_Gross_Price__c, APTS_Old_Net_Price__c,                    APTS_Amendment_Effective_Date__c,       
                                                                 Apttus_Config2__SellingFrequency__c,APTS_Stop_RtR_Transactions_from__c FROM Apttus_Config2__AssetLineItem__c WHERE Id IN: lstAssetForMovementId]);        
                                                                        
                    for(Apttus_Config2__AssetLineItem__c mvast : Oldvaluesupdate){      
                        mvast.APTS_Old_Net_Price__c = mvast.APTS_Consolidated_Price__c;mvast.APTS_Old_Gross_Price__c = mvast.APTS_Calculated_Base_Extended_Price__c;       
                    }       
                            
                    if(Oldvaluesupdate!=null){      
                        update(Oldvaluesupdate);        
                    }       
                            
                    for(APTS_Historical_Price_Change__c inactivateHistorical:lsthistory){       
                        inactivateHistorical.APTS_Isinactive__c = true;inactivehistoricallist.add(inactivateHistorical);       
                    }       
                            
                    if(inactivehistoricallist != null){     
                        update(inactivehistoricallist);     
                    }       
                }       
                system.debug('$$$$$ prv newassetList '+newassetList); 
                map<Id,Apttus_Config2__AssetLineItem__c> allParentAssetsnew=new map<id,Apttus_Config2__AssetLineItem__c>();
                //List<Apttus_Config2__AssetLineItem__c> allParentAssets = NEW List<Apttus_Config2__AssetLineItem__c>();    
                //v2.4 - START  
                List<Apttus_Config2__AssetLineItem__c> allParentAssets = APTS_CLMUtil.calculateAssetBaseExtendedPrice(newassetList, APTS_CLMUtil.oldMapNetPrice);
                //v-2.14-- START
                if(allParentAssets.size()>0){
                 for(Apttus_Config2__AssetLineItem__c finallisttrans:allParentAssets){if(!allParentAssetsnew.containskey(finallisttrans.id)){allParentAssetsnew.put(finallisttrans.id,finallisttrans);}
                 }
                 }
                 //v-2.14-- END
                
                /*if(allParentAssets.size()>0&&blockmultipleExecution==false){
                    
                    allParentAssetsnew.addall(allParentAssets);
                    blockmultipleExecution=true;
                    
                }*/
                //v2.4 - END
                system.debug('$$$$$ aftr newassetList '+newassetList); 
                system.debug('$$$$$ aftr allParentAssets '+allParentAssets);      
                system.debug('$$$$$ aftr allParentAssetsnew '+allParentAssetsnew); 
                Set<Id> astProcesd = new Set<Id>();     
                //Set<Id> primaryL1AssetsSet = new Set<Id>();       
                Map<Id, Apttus_Config2__AssetLineItem__c> primaryL1SrvcAssetsMap = new Map<Id, Apttus_Config2__AssetLineItem__c>();     
                //system.debug('AfterUpdate: processAssets '+processAssets);    
              
               // v1.4 - DFT2C-853 - START
               if(!APTS_CLMUtil.isFirstCall){
                    APTS_CLMUtil.isFirstCall = true;
                                        
                    system.debug('APTS_CLMUtil.isFirstCall '+APTS_CLMUtil.isFirstCall);
                    if(APTS_CLMUtil.isFirstCall){
                        APTS_CLMUtil.newAssetOnFirstCallMap = oldMapAsset; 
                    }
                     system.debug('APTS_CLMUtil.newAssetOnFirstCallMap '+APTS_CLMUtil.newAssetOnFirstCallMap);
                     
                }  
                for (Apttus_Config2__AssetLineItem__c tmpAsset : [SELECT Id, APTS_Is_Primary_L1_Asset__c,APTS_Stop_RtR_Transactions_from__c FROM Apttus_Config2__AssetLineItem__c 
                                                                 WHERE APTS_Is_Primary_L1_Asset__c IN: setALIServiceBundleOption AND
                                                                 Apttus_Config2__ChargeType__c IN: setServiceAddiFee AND
                                                                 Apttus_Config2__LineType__c =: option ]){ 
                    setALIServiceBundleOption.remove(tmpAsset.APTS_Is_Primary_L1_Asset__c);
                }
                
               
                //Logic to send emails on Asset Line Item Termination
                Map<Id, Apttus_Config2__AssetLineItem__c> agreementMap = new Map<Id, Apttus_Config2__AssetLineItem__c>();
                Map<Id, Integer> agreementWithAssets = new Map<Id, Integer>();
                Map<Id, Integer> agreementWithTerminatedAssets = new Map<Id, Integer>();
                //Map<Id, Apttus_Config2__AssetLineItem__c> assetMap = new Map<Id, Apttus_Config2__AssetLineItem__c>();
                List<Apttus__APTS_Agreement__c> agreementUpdateList = new List<Apttus__APTS_Agreement__c>();
                //Commenting short term for Critical defect# 18354
                //List<task> taskUpdateList = new List<task>();
                Set<Id> astIdSet = new Set<Id>();
                Map<Id, Apttus_Config2__AssetLineItem__c> oldRecMap = (Map<Id, Apttus_Config2__AssetLineItem__c>) Olditems;
                List<APTS_Historical_Price_Change__c> createList = new List<APTS_Historical_Price_Change__c>();
                List<APTS_Historical_Price_Change__c> updateList = new List<APTS_Historical_Price_Change__c>();
                Map<Id, Integer> assetHstCount = new Map<Id, Integer>();
                Set<Id> ConversionOrderAssetIdSet = new Set<ID>();
                List<Apttus_Config2__AssetLineItem__c> updatedPrimaryServiceAssets = new List<Apttus_Config2__AssetLineItem__c>();
            
                for(AggregateResult agr : [SELECT COUNT(ID) counter,APTS_AssetLineItem__c asset FROM APTS_Historical_Price_Change__c where APTS_AssetLineItem__c IN :newItems.keyset() GROUP BY APTS_AssetLineItem__c]){
                    assetHstCount.put((Id) agr.get('asset'), (Integer) agr.get('counter'));
                }
           
                for (Apttus_Config2__AssetLineItem__c  assetLine : newAssetList) {
                    agreementMap.put(assetLine.Apttus_CMConfig__AgreementId__c, assetLine);
                    if(assetHstCount.get(assetLine.Id) == NULL){
                        astIdSet.add(assetLine.Id);
                    }else if ((assetLine.Apttus_Config2__AssetStatus__c == STR_ACTION_CANCELLED && oldRecMap.get(assetLine.Id).Apttus_Config2__AssetStatus__c != STR_ACTION_CANCELLED) || (assetLine.Apttus_Config2__NetPrice__c != oldRecMap.get(assetLine.Id).Apttus_Config2__NetPrice__c && (assetLine.Apttus_Config2__AssetStatus__c == STR_ACTION_ACTIVATED || assetLine.Apttus_Config2__AssetStatus__c == STR_ACTION_CANCELLED || assetLine.Apttus_Config2__AssetStatus__c == STR_ACTION_PENDINGACTIVATION || assetLine.Apttus_Config2__AssetStatus__c == STR_ACTION_PENDINGRENEWAL || assetLine.Apttus_Config2__AssetStatus__c == STR_ACTION_PENDINGCHANGE)) || ((mapHistory.containskey(assetLine.Id) && ACTION_RENEW.equalsIgnoreCase(mapHistory.get(assetLine.Id))) && (oldRecMap.get(assetLine.Id).Apttus_Config2__EndDate__c != assetLine.Apttus_Config2__EndDate__c) && oldRecMap.get(assetLine.Id).Apttus_Config2__EndDate__c < assetLine.Apttus_Config2__EndDate__c)){
                        astIdSet.add(assetLine.Id);
                    }
                    if(assetLine.APTS_latest_order_type__c!=null && (assetLine.APTS_latest_order_type__c.equalsIgnoreCase(System.Label.APTS_Machine_Order))){
                        oldItemsMachinePha = oldItems;
                    }
                    if(assetLine.APTS_latest_order_type__c!=null && assetLine.APTS_Latest_order_sub_type__c!=null
                    && assetLine.APTS_latest_order_type__c.equalsIgnoreCase('Admin order') && !assetLine.APTS_Latest_order_sub_type__c.equalsIgnoreCase(APTS_BIRUtils.ORDERSUBTYPE) 
                    && (assetLine.Apttus_Config2__AssetStatus__c.equalsIgnoreCase('Activated') || (!assetLine.APTS_Contract_Change__c && assetLine.Apttus_Config2__AssetStatus__c.equalsIgnoreCase('Cancelled')))){
                        ConversionOrderAssetIdSet.add(assetLine.id);
                    }
                }
                
               // v1.3 - DFT2C-1332 - START
               /*List<Apttus_Config2__AssetLineItem__c> agreementAssetList = [SELECT Id, 
                                                    Apttus_CMConfig__AgreementId__c,
                                                    OwnerId,
                                                    Apttus_Config2__ChargeType__c,
                                                    Apttus_Config2__AssetStatus__c,
                                                    Apttus_CMConfig__AgreementId__r.APTS_Asset_Terminated__c,
                                                    Apttus_CMConfig__AgreementId__r.OwnerId,
                                                    Apttus_Config2__StartDate__c,
                                                    Apttus_Config2__EndDate__c,
                                                    APTS_Type_Of_Contract__c,
                                                    Apttus_Config2__LineType__c,
                                                    Apttus_Config2__IsPrimaryLine__c,                                                    
                                                    APTS_Is_Primary_L1_Asset__c,
                                                    APTS_Is_Primary_L1_Asset__r.APTS_Physical_Asset__c,
                                                    APTS_Is_Primary_L1_Asset__r.APTS_Physical_Asset__r.AssetStatus__c,
                                                    APTS_Is_Primary_L1_Asset__r.APTS_Physical_Asset__r.Warranty__c,
                                                    APTS_Is_Primary_L1_Asset__r.APTS_Physical_Asset__r.WarrantyStartDate__c,
                                                    APTS_Physical_Asset__c,
                                                    APTS_Physical_Asset__r.Warranty__c,
                                                    APTS_Physical_Asset__r.WarrantyStartDate__c,
                                                    APTS_Stop_RtR_Transactions_from__c FROM Apttus_Config2__AssetLineItem__c
                                                    WHERE (Apttus_CMConfig__AgreementId__c != null AND Apttus_CMConfig__AgreementId__c IN: agreementMap.keySet())];*/
                 //v1.5 - DFT2C-1851,DFT2C-1852 - START
                List<Apttus_Config2__AssetLineItem__c> agreementAssetList = [SELECT Id, 
                                                    Apttus_CMConfig__AgreementId__c,
                                                    APTS_PhysicalAssetExtId__c,
                                                    OwnerId,
                                                    Apttus_Config2__ChargeType__c,
                                                    Apttus_Config2__AssetStatus__c,
                                                    Apttus_CMConfig__AgreementId__r.RecordType.Name,
                                                    Apttus_CMConfig__AgreementId__r.Apttus__Status_Category__c,
                                                    Apttus_CMConfig__AgreementId__r.Apttus__Status__c,
                                                    Apttus_CMConfig__AgreementId__r.APTS_Asset_Terminated__c,
                                                    Apttus_CMConfig__AgreementId__r.OwnerId,
                                                    Apttus_Config2__StartDate__c,
                                                    Apttus_Config2__EndDate__c,
                                                    APTS_Type_Of_Contract__c,
                                                    APTS_RefurbishedMachine__c,
                                                    Apttus_Config2__AttributeValueId__r.APTS_Number_of_months__c,
                                                    Apttus_Config2__LineType__c,
                                                    APTS_Contract_Change__c,
                                                    Apttus_Config2__LocationId__c,
                                                    Apttus_Config2__AccountId__c,
                                                    Apttus_Config2__IsPrimaryLine__c,                                                    
                                                    APTS_Is_Primary_L1_Asset__c,
                                                    APTS_Is_Primary_L1_Asset__r.APTS_Physical_Asset__c,
                                                    APTS_Is_Primary_L1_Asset__r.APTS_Physical_Asset__r.AssetStatus__c,
                                                    APTS_Is_Primary_L1_Asset__r.APTS_Physical_Asset__r.Warranty__c,
                                                    APTS_Is_Primary_L1_Asset__r.APTS_Physical_Asset__r.WarrantyStartDate__c,
                                                    APTS_Physical_Asset__c,
                                                    APTS_Physical_Asset__r.Warranty__c,
                                                    APTS_Physical_Asset__r.SoldTo__c,
                                                    APTS_Physical_Asset__r.AccountLocation__c,
                                                    APTS_Physical_Asset__r.WarrantyStartDate__c,
                                                    APTS_Stop_RtR_Transactions_from__c FROM Apttus_Config2__AssetLineItem__c
                                                    WHERE id IN: newItems.keySet()];
                
                //v1.5 - DFT2C-1851,DFT2C-1852 - END                                    
                // v1.3 - DFT2C-1332 - END
                //v1.5 - DFT2C-1851,DFT2C-1852 - START
                /*for (Apttus_Config2__AssetLineItem__c assets : agreementAssetList) {
                
                    if (!agreementWithAssets.isEmpty() && agreementWithAssets.containsKey(assets.Apttus_CMConfig__AgreementId__c)) {
                        agreementWithAssets.put(assets.Apttus_CMConfig__AgreementId__c, agreementWithAssets.get(assets.Apttus_CMConfig__AgreementId__c) + 1);
                    } else if (!agreementWithAssets.containsKey(assets.Apttus_CMConfig__AgreementId__c)) {
                        agreementWithAssets.put(assets.Apttus_CMConfig__AgreementId__c, 1);
                    }
                    if (assets.Apttus_Config2__AssetStatus__c != null && assets.Apttus_Config2__AssetStatus__c.equalsIgnoreCase(STR_SAT_CAT_TERMINATED)) {
                        if (!agreementWithTerminatedAssets.isEmpty() && agreementWithTerminatedAssets.containsKey(assets.Apttus_CMConfig__AgreementId__c)) {
                            agreementWithTerminatedAssets.put(assets.Apttus_CMConfig__AgreementId__c, agreementWithTerminatedAssets.get(assets.Apttus_CMConfig__AgreementId__c) + 1);
                        } else if (!agreementWithTerminatedAssets.containsKey(assets.Apttus_CMConfig__AgreementId__c)) {
                            agreementWithTerminatedAssets.put(assets.Apttus_CMConfig__AgreementId__c, 1);
                        }
                    }
                    
                    //assetMap.put(assets.Apttus_CMConfig__AgreementId__c, assets);
                }*/
                //v1.5 - DFT2C-1851,DFT2C-1852 - END
                
                //v1.5 - DFT2C-1851,DFT2C-1852 - START 
               /*for (Id agreementId : agreementMap.keySet()) {
                    if (agreementWithAssets.get(agreementId) != null && agreementWithTerminatedAssets.get(agreementId) != null) {
                        if (agreementWithAssets.get(agreementId) - agreementWithTerminatedAssets.get(agreementId) == 0) {
                            Apttus__APTS_Agreement__c oAgreement = new Apttus__APTS_Agreement__c ();
                            oAgreement.Id = agreementId;
                            oAgreement.APTS_Asset_Terminated__c = true;
                            agreementUpdateList.add(oAgreement);                        
                            
                        }
                    }
                }*/
                //v1.5 - DFT2C-1851,DFT2C-1852 - END
                //Commenting short term for Critical defect# 18354
                //Database.insert(taskUpdateList, false);
                 //v1.5 - DFT2C-1851,DFT2C-1852 - START
                //Database.update(agreementUpdateList, false);
                 //v1.5 - DFT2C-1851,DFT2C-1852 - END
                /*Added by Shanmuga Prasath for Updating and creating the Historical changes*/
                List<Apttus_Config2__AssetLineItem__c> assetLineItemList = new List<Apttus_Config2__AssetLineItem__c>();
                
                for (Apttus_Config2__AssetLineItem__c aLI : [SELECT Id, Apttus_Config2__EndDate__c, Apttus_Config2__AssetStatus__c, Apttus_Config2__StartDate__c, Apttus_Config2__NetPrice__c, Apttus_Config2__SellingTerm__c, APTS_Amendment_Effective_Date__c,
                Apttus_Config2__SellingFrequency__c, (SELECT Id, APTS_AssetLineItem__c, APTS_End_date__c, APTS_Net_Price__c, APTS_Selling_term__c, APTS_Timestamp__c, APTS_Start_date__c FROM Historical_Price_Changes__r order by APTS_Timestamp__c DESC limit 1),
                APTS_Stop_RtR_Transactions_from__c FROM Apttus_Config2__AssetLineItem__c WHERE Id IN: astIdSet]) {
                    assetLineItemList.add(aLI);
                }
                for (Apttus_Config2__AssetLineItem__c astLI : assetLineItemList) {
                    astLI.APTS_Amendment_Effective_Date__c = System.today();
                    APTS_Historical_Price_Change__c updateHistoricalPriceChange = new APTS_Historical_Price_Change__c();
                    APTS_Historical_Price_Change__c createHistoricalPriceChange = new APTS_Historical_Price_Change__c();
                    if (astLI.Historical_Price_Changes__r.size() > 0) {
                        updateHistoricalPriceChange.Id = astLI.Historical_Price_Changes__r[0].Id;
                        if(STR_ACTION_CANCELLED.equalsIgnoreCase(astLI.Apttus_Config2__AssetStatus__c)){
                            updateHistoricalPriceChange.APTS_End_date__c = astLI.Apttus_Config2__EndDate__c;
                        }else{
                            updateHistoricalPriceChange.APTS_End_date__c = System.today();
                        }
                        updateHistoricalPriceChange.APTS_Duration1__c = Apttus_Config2.CPQWebService.computeTerm(astLI.Historical_Price_Changes__r[0].APTS_Start_date__c, updateHistoricalPriceChange.APTS_End_date__c, astLI.Apttus_Config2__SellingFrequency__c);
                        updateList.add(updateHistoricalPriceChange);
                        if(!STR_ACTION_CANCELLED.equalsIgnoreCase(astLI.Apttus_Config2__AssetStatus__c)){
                            createHistoricalPriceChange.APTS_Start_date__c = System.today();
                            createHistoricalPriceChange.APTS_Net_Price__c = astLI.Apttus_Config2__NetPrice__c;
                            createHistoricalPriceChange.APTS_End_date__c = astLI.Apttus_Config2__EndDate__c;
                            createHistoricalPriceChange.APTS_Timestamp__c = System.now();
                            createHistoricalPriceChange.APTS_AssetLineItem__c = astLI.Id;
                            if(astLI.Apttus_Config2__SellingFrequency__c == 'One Time'){
                                createHistoricalPriceChange.APTS_Duration1__c = 1;
                            }
                            else{
                                createHistoricalPriceChange.APTS_Duration1__c = Apttus_Config2.CPQWebService.computeTerm(createHistoricalPriceChange.APTS_Start_date__c, createHistoricalPriceChange.APTS_End_date__c, astLI.Apttus_Config2__SellingFrequency__c);
                            }
                            createHistoricalPriceChange.APTS_Selling_term__c = createHistoricalPriceChange.APTS_Duration1__c;
                            createList.add(createHistoricalPriceChange);
                        }
                    } else if(astLI.Historical_Price_Changes__r.size() <= 0 && !STR_ACTION_CANCELLED.equalsIgnoreCase(astLI.Apttus_Config2__AssetStatus__c)){
                        createHistoricalPriceChange.APTS_Start_date__c = astLI.Apttus_Config2__StartDate__c;createHistoricalPriceChange.APTS_End_date__c = astLI.Apttus_Config2__EndDate__c;createHistoricalPriceChange.APTS_Timestamp__c = System.now();createHistoricalPriceChange.APTS_Net_Price__c = astLI.Apttus_Config2__NetPrice__c;createHistoricalPriceChange.APTS_AssetLineItem__c = astLI.Id;
                        if(astLI.Apttus_Config2__SellingFrequency__c == 'One Time'){
                            createHistoricalPriceChange.APTS_Duration1__c = 1;
                        }
                        else{
                            createHistoricalPriceChange.APTS_Duration1__c = Apttus_Config2.CPQWebService.computeTerm(createHistoricalPriceChange.APTS_Start_date__c, createHistoricalPriceChange.APTS_End_date__c, astLI.Apttus_Config2__SellingFrequency__c);
                        }
                        createHistoricalPriceChange.APTS_Selling_term__c = createHistoricalPriceChange.APTS_Duration1__c;createList.add(createHistoricalPriceChange);
                    }
                }
                
                if (createList.size() > 0) {
                    Database.insert(createList , false);
                }
                
                if (updateList.size() > 0) {
                    Database.update(updateList , false);
                }
                
                
               
                //Method to activate Physical Asset when ALI's status changes from some status to Activated
                if(!oldItemsMachinePha.isEmpty()){
                    APTS_OrderLineItemUtils.updatePhysicalAssetOnALIUpdate(agreementAssetList, (Map<Id, Apttus_Config2__AssetLineItem__c>) oldItemsMachinePha);
                    //APTS_OrderLineItemUtils.updatePhysicalAssetOnALIUpdate(agreementAssetList, (Map<Id, Apttus_Config2__AssetLineItem__c>) newItems);
                }
                if(!ConversionOrderAssetIdSet.isEmpty()){
                    APTS_ConversionOrderPhaUtils.updatePhysicalAssetFieldsABO(ConversionOrderAssetIdSet);
                }
                // LAE RAR Changes
                 if(isFinalStatus && !APTS_CLMUtil.isQueueableEnable && !APTS_CLMUtil.newAssetOnFirstCallMap.isEmpty()){
                     APTS_CLMUtil.isQueueableEnable = true;
                     // v1.7 - DFT2C-2034 - START
                    APTS_StagingDataJob sdj = new APTS_StagingDataJob(false);
                    sdj.fetchServiceHeaderWarranty(setAssetPrimL1Id);
                    system.debug('$$$$$ sdj.mapServiceWarranty '+sdj.mapServiceWarranty);
                    mapServiceWarranty.putAll(sdj.mapServiceWarranty);
                    mapServiceActiveWarranty.putAll(sdj.mapServiceActiveWarranty);
                    mapServiceActiveWarrantyDate.putAll(sdj.mapServiceActiveWarrantyDate);
                    // v1.7 - DFT2C-2034 - END
                        system.debug('APTS_CLMUtil.isQueueableEnable '+APTS_CLMUtil.isQueueableEnable);                
                    for (Apttus_Config2__AssetLineItem__c tmpAsset : newAssetList){   
                           system.debug('Shah LAE-24th March 841'+tmpAsset); 
                        if(!setALIServiceBundleOption.contains(tmpAsset.APTS_Is_Primary_L1_Asset__c)){
                                system.debug('Shah LAE-24th March Out'); 
                            Apttus_Config2__AssetLineItem__c oldAssetLineItem = (Apttus_Config2__AssetLineItem__c)APTS_CLMUtil.newAssetOnFirstCallMap.get(tmpAsset.Id);       
                            if(oldAssetLineItem == null){                                
                                 oldAssetLineItem = (Apttus_Config2__AssetLineItem__c)oldItems.get(tmpAsset.Id); 
                            }
                                 system.debug('Shah LAE-24th March 848'+oldAssetLineItem);
                                 system.debug('Shah LAE-24th March 848 system batch'+System.isBatch());
                                RTR_LAE_Transaction_Data__c  tempATL = new RTR_LAE_Transaction_Data__c();                                 
                                if(lstAssetForMovementId.contains(tmpAsset.Id)) {                                        
                                    mapAssetLineItem.put(tmpAsset.Id, true);  
                                }else if(oldAssetLineItem != null && tmpAsset.Apttus_Config2__AccountId__c != oldAssetLineItem.Apttus_Config2__AccountId__c&& System.isBatch()){ 
                                    mapAssetLineItem.put(tmpAsset.Id, false);  
                                    system.debug('Shah LAE-24th March Out'+oldAssetLineItem );                                                                         
                                }
                              
                                else if(oldAssetLineItem !=null && (tmpAsset.Apttus_Config2__AssetStatus__c == STR_ACTION_ACTIVATED || tmpAsset.Apttus_Config2__AssetStatus__c == STR_ACTION_CANCELLED) && tmpAsset.Apttus_Config2__HasOptions__c && tmpAsset.Apttus_Config2__LineType__c == PRODUCTSERVICE ){     
                                system.debug('Shah LAE-24th March in');
                                  //v2.12- Start
                                    //if((tmpAsset.APTS_Calculated_Base_Extended_Price__c !=0 && tmpAsset.Apttus_Config2__ChargeType__c==SERVICEFEE) ||(tmpAsset.Apttus_Config2__ChargeType__c!=SERVICEFEE)){
                                        tempATL = processTransData(oldAssetLineItem, tmpAsset,businessObjectIdMap); 
                                    //}
                                     
                                     //v2.12- end
                                }       
                                // v1.2 - DFT2C-853 - End     
                                if(tempATL != null && tempATL.APTS_Asset_Line_Item__c != null){        
                                    astProcesd.add(tmpAsset.Id); 
                                    if(!lstATLRecordsMap.containsKey(tempATL.APTS_Asset_Line_Item__c))      
                                        lstATLRecordsMap.put(tempATL.APTS_Asset_Line_Item__c, tempATL);     
                                    if(tempATL.APTS_Business_Transaction_Type__c == TRANS_0005){     
                                        lstAssetForMovementId.add(tempATL.APTS_Asset_Line_Item__c);     
                                    }       
                                } 
                                
                                        
                                if(ADDITIONALSERVICEFEE.equalsIgnoreCase(tmpAsset.Apttus_Config2__ChargeType__c) &&     
                                oldAssetLineItem != null && oldAssetLineItem.Apttus_Config2__NetPrice__c != tmpAsset.Apttus_Config2__NetPrice__c){      
                                    //primaryL1AssetsSet.add(tmpAsset.APTS_Is_Primary_L1_Asset__c);     
                                    primaryL1SrvcAssetsMap.put(additionalFeeToServiceFeeMap.get(tmpAsset.Id),tmpAsset);     
                                }  
                        }
                     } 
                    // v2.1 - DQ-980 - START.
                    System.debug('Final LIST====>'+allParentAssets);
                    System.debug('Final LIST allParentAssetsnew====>'+allParentAssetsnew);
                    if(allParentAssetsnew.size()>0){
                    for(Apttus_Config2__AssetLineItem__c parentALI : allParentAssetsnew.values()){      
                        RTR_LAE_Transaction_Data__c  tempATL ; 
                        system.debug('ALI ID===>'+parentALI.id);
                        system.debug('Apttus_Config2__ChargeType__c===>'+parentALI.Apttus_Config2__ChargeType__c);     
                        system.debug('Asset line item history===>'+mapHistory.containskey(parentALI.Id));
                        if(parentALI.APTS_Stop_RtR_Transactions_from__c>System.Today()&&!astProcesd.contains(parentALI.Id) && mapHistory.containskey(parentALI.Id) && ACTION_AMEND.equalsIgnoreCase(mapHistory.get(parentALI.Id)) && (parentALI.Apttus_Config2__ChargeType__c != ADDITIONALSERVICEFEE|| parentALI.Apttus_Config2__ChargeType__c != SALESPRICE)&&businessObjectIdMap.get(parentALI.id)!=null&&(businessObjectIdMap.get(parentALI.id).Apttus_Config2__OrderId__r.APTS_Admin_Movement__c==FALSE&&(businessObjectIdMap.get(parentALI.id).Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c=='Indexation'||businessObjectIdMap.get(parentALI.id).Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c=='Conversion Order')&&businessObjectIdMap.get(parentALI.id).Apttus_Config2__OrderId__r.APTS_Order_Type__c.equalsIgnoreCase('Admin order'))){      
                        system.debug('Shah-LAE inside');
                            // v1.2 - DFT2C-853 - Added new parameter for createTransData.
                            tempATL = createTransData(parentALI.Id, TRANS_0004, System.Today());
                            // v1.2 - DFT2C-853 - End.      
                            if(!lstATLRecordsMap.containsKey(tempATL.APTS_Asset_Line_Item__c))      
                                lstATLRecordsMap.put(tempATL.APTS_Asset_Line_Item__c, tempATL);     
                        }       
                    }   
                    }
                    if (lstATLRecordsMap.size() > 0) {      
                        insert lstATLRecordsMap.values();       
                    }
                    system.debug('Shah LAE-24th March 848 mapAssetLineItem'+mapAssetLineItem);
                    if(!mapAssetLineItem.isEmpty()){
                    createTransDataOnContractChanged(mapAssetLineItem,false,false);
                    }
                    // v2.1 - DQ-980 - END.
                } // v1.4 - DFT2C-853 - END.     
                        
                
                if(primaryL1SrvcAssetsMap.size() > 0){ 
                for (Apttus_Config2__AssetLineItem__c asset : [SELECT Id,           
                                                                            APTS_Is_Primary_L1_Asset__c,            
                                                                            Apttus_Config2__ChargeType__c,          
                                                                            APTS_Amendment_Effective_Date__c,           
                                                                         APTS_Service_Rollup_Net_Amount__c,          
                                                                            APTS_Stop_RtR_Transactions_from__c FROM Apttus_Config2__AssetLineItem__c           
                                                                            WHERE Id IN: primaryL1SrvcAssetsMap.keySet()]){         
                        asset.APTS_Service_Rollup_Net_Amount__c = (primaryL1SrvcAssetsMap.get(asset.Id)).APTS_Consolidated_Price__c;            
                        asset.APTS_Amendment_Effective_Date__c = System.Today();            
                        updatedPrimaryServiceAssets.add(asset);         
                    }           
                }
                 if (updatedPrimaryServiceAssets.size() > 0) {
                    Database.update(updatedPrimaryServiceAssets, false);
                }
            }
        }catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex',ex.getStackTraceString() + '/n/n' + ex.getMessage() ,'AssetLineTriggerHandler','AfterUpdate', 'CLM', false, false, null, true);}
    }
    public void AfterDelete(List<SObject> oldList, Map<Id, SObject> oldItems) {}
    public void AfterUndelete(List<SObject> newList, Map<Id, SObject> newItems) {}
    public Boolean isDisabled() {
        if(isSkipAssetlineitemTrigger == true){
           return  isSkipAssetlineitemTrigger;
        }
        else{
            return (TriggerSettings__c.getInstance().AssetLineItemTrigger__c) ? false : isTriggerDisabled ;
        }
        
    }
    //Handles business logic for field values in Staging object records
    
    public RTR_LAE_Transaction_Data__c processTransData(Apttus_Config2__AssetLineItem__c oldALI, Apttus_Config2__AssetLineItem__c newALI,Map<Id,Apttus_Config2__OrderLineItem__c> businessObjectIdMap) {
        system.debug('$$$$$ processTransData '+oldALI);
        system.debug('$$$$$ processTransData1 '+newALI);        
        
        try{
            
            Id assetId = null, assetPL1Id = null;
            String transactionType = null;
            Date dtCED001 = null;
            RTR_LAE_Transaction_Data__c tempATL = new RTR_LAE_Transaction_Data__c();
            RTR_LAE_Transaction_Data__c tempATL1 = new RTR_LAE_Transaction_Data__c();
            // v1.7 - DFT2C-2034 - START
            assetPL1Id = newALI.APTS_Is_Primary_L1_Asset__c != null ? newALI.APTS_Is_Primary_L1_Asset__c : newALI.Id;
            if(newALI.Apttus_Config2__ChargeType__c == SERVICEFEE && newALI.APTS_Type_Of_Contract__c == SALES && mapServiceActiveWarranty.containsKey(assetPL1Id) && 
                 mapServiceActiveWarranty.get(assetPL1Id) && mapServiceWarranty.containsKey(assetPL1Id) && mapServiceWarranty.get(assetPL1Id) ){
                dtCED001 =  mapServiceActiveWarrantyDate.get(assetPL1Id);
            } else {
                //v2.6 - START
                //dtCED001 = newALI.Apttus_Config2__OriginalStartDate__c;
                  dtCED001 = newALI.APTS_RAR_LAE_OriginalStartDate__c;
                //v2.6 - END
            }
            // v1.7 - DFT2C-2034 - END
            //Net price change
            if (newALI.Apttus_Config2__ParentAssetId__c == NULL && !TRIAL.equalsIgnoreCase(newALI.APTS_Type_Of_Contract__c) && !SUBSCRIPTION.equalsIgnoreCase(newALI.APTS_Type_Of_Contract__c)
                && ((SALESPRICE.equalsIgnoreCase(newALI.Apttus_Config2__ChargeType__c) && SALES.equalsIgnoreCase(newALI.APTS_Type_Of_Contract__c)) || !SALESPRICE.equalsIgnoreCase(newALI.Apttus_Config2__ChargeType__c))
                && !USAGEFEE.equalsIgnoreCase(newALI.Apttus_Config2__ChargeType__c) && !ADDITIONALSERVICEFEE.equalsIgnoreCase(newALI.Apttus_Config2__ChargeType__c)){
            /* if (newALI.APTS_Contract_Type__c != null && newALI.APTS_Contract_Type__c.equalsIgnoreCase('Sales')) {      
                    tempATL.APTS_Contractual_Purchase__c = CHAR_S;      
                }*/
                //RtR Integration on Asset Activation
                if (newALI.APTS_Stop_RtR_Transactions_from__c>System.Today()&&newALI.Apttus_Config2__AssetStatus__c == STR_ACTION_ACTIVATED && newALI.Apttus_Config2__AssetStatus__c != oldALI.Apttus_Config2__AssetStatus__c && mapHistory.get(newALI.Id) == ACTION_NEW && newALI.APTS_Manual_Activation_Date__c == null ) {
                    assetId = newALI.Id;
                    transactionType = TRANS_0001;
                    // v1.4 - DFT2C-853 - START
                    tempATL = createTransData(assetId, transactionType, dtCED001);
                    // v1.4 - DFT2C-853 - END.
                }
                    
                //RtR Integration on Asset de-activation
                if (newALI.APTS_Stop_RtR_Transactions_from__c>System.Today()&&STR_ACTION_CANCELLED.equalsIgnoreCase(newALI.Apttus_Config2__AssetStatus__c) && mapHistory.get(newALI.Id) == ACTION_CANCEL  && newALI.Apttus_Config2__AssetStatus__c != oldALI.Apttus_Config2__AssetStatus__c 
                   && newALI.APTS_Manual_DeActivation_Date__c == null && (newALI.Apttus_Config2__EndDate__c < oldALI.Apttus_Config2__EndDate__c || (newALI.APTS_Contract_Change__c != null && newALI.APTS_Contract_Change__c))) { //V2.19 ++ <<>>
                    assetId = newALI.Id;
                    transactionType = TRANS_0002;
                    // v1.4 - DFT2C-853 - START
                     tempATL = createTransData(assetId, transactionType, newALI.Apttus_Config2__EndDate__c);
                     // v1.4 - DFT2C-853 - END
                    /*if (newALI.APTS_Contract_Type__c != null && newALI.APTS_Contract_Type__c.equalsIgnoreCase('Sales')) {           
                        tempATL.APTS_Contractual_Purchase__c = CHAR_S;          
                    } */
                }
                System.debug('Debug Line'+newALI.Id);
   system.debug('Debug Line'+newALI.Apttus_Config2__AssetStatus__c+'OldLine'+oldALI.Apttus_Config2__AssetStatus__c);
   System.debug('Debug Line'+mapHistory.values());
                //RTR Integration for Amendments
                if ((mapHistory.get(newALI.Id) == ACTION_RENEW || mapHistory.get(newALI.Id) == ACTION_AMEND)) {
              
                     if(SALES.equalsIgnoreCase(newALI.APTS_Type_Of_Contract__c) && SERVICEFEE.equalsIgnoreCase(newALI.Apttus_Config2__ChargeType__c) 
                     && oldALI.APTS_Calculated_Base_Extended_Price__c == 0 &&newALI.APTS_Stop_RtR_Transactions_from__c>System.Today()){
                   System.debug('Debug Line 001');
                        assetId = newALI.Id;
                        transactionType = TRANS_0001;
                        // v1.4 - DFT2C-853 - START
                        tempATL = createTransData(assetId, transactionType, dtCED001);
                        // v1.4 - DFT2C-853 - End.
                     }else if(newALI.Apttus_Config2__EndDate__c > oldALI.Apttus_Config2__EndDate__c&&newALI.APTS_Stop_RtR_Transactions_from__c>System.Today()){
                     System.debug('Debug Line 003');
                        assetId = newALI.Id;
                        transactionType = TRANS_0003;
                        // v1.4 - DFT2C-853 - START
                        tempATL = createTransData(assetId, transactionType, newALI.Apttus_Config2__StartDate__c);
                        // v1.4 - DFT2C-853 - End.
                        // v2.7 - DQ-992 - START
                     }else if(newALI.Apttus_Config2__EndDate__c < oldALI.Apttus_Config2__EndDate__c && 
                            STR_ACTION_ACTIVATED.equalsIgnoreCase(newALI.Apttus_Config2__AssetStatus__c)&&newALI.APTS_Stop_RtR_Transactions_from__c>System.Today()){
                           System.debug('Debug Line 004');
                        assetId = newALI.Id;
                        transactionType = TRANS_0004;
                        // v1.4 - DFT2C-853 - START
                        tempATL = createTransData(assetId, transactionType, System.Today());
                        // v1.4 - DFT2C-853 - End.
                        // v2.7 - DQ-992 - end.
                     }else if(newALI.Apttus_Config2__NetPrice__c  != oldALI.Apttus_Config2__NetPrice__c && 
                            newALI.Apttus_Config2__AccountId__c == oldALI.Apttus_Config2__AccountId__c &&newALI.Apttus_Config2__ChargeType__c!=SALESPRICE
                            &&newALI.APTS_Stop_RtR_Transactions_from__c>System.Today()&&!businessObjectIdMap.isEmpty() &&
                            businessObjectIdMap.get(newALI.id)!=null&&(businessObjectIdMap.get(newALI.id).Apttus_Config2__OrderId__r.APTS_Admin_Movement__c==FALSE&&businessObjectIdMap.get(newALI.id).Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c=='Conversion Order'&&businessObjectIdMap.get(newALI.id).Apttus_Config2__OrderId__r.APTS_Order_Type__c.equalsIgnoreCase('Admin order'))){
                            System.debug('Debug Line 004');
                        assetId = newALI.Id;
                        transactionType = TRANS_0004;
                        // v1.4 - DFT2C-853 - Added new parameter for createTransData and removed additional condition from IF statement.
                        tempATL = createTransData(assetId, transactionType, System.Today());
                        // v1.4 - DFT2C-853 - End.
                     }system.debug('Shah-LAE inside last');
                }
                if(ADDITIONALSERVICEFEE.equalsIgnoreCase(newALI.Apttus_Config2__ChargeType__c) 
                    && additionalFeeToServiceFeeMap.containskey(newALI.ID) && 
                    lstATLRecordsMap.containskey(additionalFeeToServiceFeeMap.get(newALI.ID)))
                {
                    tempATL1 = lstATLRecordsMap.get(additionalFeeToServiceFeeMap.get(newALI.ID));
                    if(tempATL1 != null && ((tempATL1.APTS_Business_Transaction_Type__c == TRANS_0003 && transactionType == TRANS_0001)
                        || (tempATL1.APTS_Business_Transaction_Type__c == TRANS_0002 && (transactionType == TRANS_0001 || transactionType == TRANS_0003))
                        || (tempATL1.APTS_Business_Transaction_Type__c == TRANS_0004 && (transactionType == TRANS_0001 || transactionType == TRANS_0002 || transactionType == TRANS_0003))))
                    {
                        tempATL.APTS_Asset_Line_Item__c = additionalFeeToServiceFeeMap.get(newALI.ID);
                    }
                    else
                    {
                        return null;
                    }
                }
                if(SERVICEFEE.equalsIgnoreCase(newALI.Apttus_Config2__ChargeType__c) && lstATLRecordsMap.containskey(newALI.ID))
                {
                    tempATL1 = lstATLRecordsMap.get(newALI.ID);
                    if(tempATL1 != null && ((tempATL1.APTS_Business_Transaction_Type__c == TRANS_0003 && transactionType == TRANS_0001)
                        || (tempATL1.APTS_Business_Transaction_Type__c == TRANS_0002 && (transactionType == TRANS_0001 || transactionType == TRANS_0003))
                        || (tempATL1.APTS_Business_Transaction_Type__c == TRANS_0004 && (transactionType == TRANS_0001 || transactionType == TRANS_0002 || transactionType == TRANS_0003))))
                    {
                        tempATL.APTS_Asset_Line_Item__c = newALI.ID;
                    }
                    else
                    {
                        return null;
                    }
                } 
                if (tempATL.APTS_Asset_Line_Item__c != null && newALI.APTS_Type_Of_Contract__c != null && newALI.APTS_Type_Of_Contract__c.equalsIgnoreCase('Sales')) {
                    tempATL.APTS_Contractual_Purchase__c = CHAR_S;
                    //system.debug('$$$$$ Contractual purchase'+tempATL);
                }
                // v1.4 - DFT2C-853 - START
                if(tempATL.APTS_Asset_Line_Item__c != null){ return tempATL; }
                // v1.4 - DFT2C-853 - END
            }
            return tempATL;
            
        }catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString(), 'Asset Line Item', null, 'CLM', false, false, null, true); return null;}
    }
    //Create new Staging object record
    public static RTR_LAE_Transaction_Data__c createTransData(Id assetId, String transactionType, Date contractEffectiveDate) {
        try{
            RTR_LAE_Transaction_Data__c  tempATL = new RTR_LAE_Transaction_Data__c  ();
            tempATL.APTS_Asset_Line_Item__c = assetId;
            tempATL.APTS_Business_Transaction_Type__c = transactionType;
            // v1.4 - DFT2C-853 - Added new assignment for createTransData.       
            tempATL.APTS_Contract_Effective_Date__c = contractEffectiveDate;
            // v1.4 - DFT2C-853 -End.
            return tempATL;
        }catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString(), 'Asset Line Item', null, 'CLM', false, false, null, true); return null;}
    }
    //Method to be called from Indexation Batch Jobs while applying Indexation
    public void createIndexationTransData(Set<Id> listIndexation) {
        try{
            List<RTR_LAE_Transaction_Data__c> lstTransData = new List<RTR_LAE_Transaction_Data__c>();
            for (Id asset : listIndexation) {
                RTR_LAE_Transaction_Data__c tmpTrans = new RTR_LAE_Transaction_Data__c();
                tmpTrans.APTS_Asset_Line_Item__c = asset;
                tmpTrans.APTS_Business_Transaction_Type__c = TRANS_0004;
                tmpTrans.APTS_Contractual_Purchase__c = CHAR_I;
                // v1.4 - DFT2C-853 - Added new assignment for createTransData.
                tmpTrans.APTS_Contract_Effective_Date__c = System.Today();
                // v1.4- DFT2C-853 - End.
                lstTransData.add(tmpTrans);
            }
            if (lstTransData.size() > 0) {
                insert lstTransData;
            }
        }catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString(), 'Asset Line Item', null, 'CLM', false, false, null, true);}
    }
    
    public static void processAsset(Map<Id, Apttus_Config2__AssetLineItem__c> oldItems, Map<Id, Apttus_Config2__AssetLineItem__c> newItems){
    
        if(oldItems != null && newItems != null){
            for(Apttus_Config2__AssetLineItem__c ast : oldItems.values()){
            Apttus_Config2__AssetLineItem__c newALI = newItems.get(ast.Id);
                if(processAssets == null){
                    processAssets = new Map<Id, Apttus_Config2__AssetLineItem__c>();
                    processAssets.put(ast.Id, ast);
                }else if(processAssets.get(ast.Id)==null && ast.Apttus_Config2__LineType__c == PRODUCTSERVICE && 
                   ast.Apttus_Config2__AssetStatus__c == STR_ACTION_ACTIVATED && newALI.Apttus_Config2__AssetStatus__c != STR_ACTION_ACTIVATED){
                    processAssets.put(ast.Id, ast);
                }
            }           
        }
        
        if(oldItems == null && newItems != null){
            for(Apttus_Config2__AssetLineItem__c ast : newItems.values()){
                if(processAssets == null){
                    processAssets = new Map<Id, Apttus_Config2__AssetLineItem__c>();
                    processAssets.put(ast.Id, ast);
                }else if(processAssets.get(ast.Id)==null && ast.Apttus_Config2__LineType__c == PRODUCTSERVICE ){
                    processAssets.put(ast.Id, ast);
                }
            }
        }
    }
   /********************************************************************************
   @Description: This method will create transaction data record on contract changed.
   @Params : Map<Id, Boolean>
   @return : void
   *********************************************************************************/
   public static void createTransDataOnContractChanged(Map<Id, Boolean> mapAssetLineItem,Boolean ownershipMovement,Boolean isConversion){
       Set<String> setChargeType = new Set<String>{'Service Fee', 'Rental Fee', 'Sales Price'};
       Set<String> setTypeOfContract = new Set<String>{'Rent', 'RentBuy', 'Free On Loan', 'Consumption'};
       String lineType = 'Product/Service';
       List<RTR_LAE_Transaction_Data__c> lstTransData = new List<RTR_LAE_Transaction_Data__c>();
       Map<Id, Boolean> mapPrimaryL1 = new Map<Id, Boolean>();
       Map<Id,Apttus_Config2__OrderLineItem__c> olitoali=new Map<Id,Apttus_Config2__OrderLineItem__c>();
       system.debug(' mapAssetLineItem '+ mapAssetLineItem);
       Boolean FinalBoolean =ownershipMovement;
       Boolean FinalConverBoolean =isConversion;
       for(Apttus_Config2__AssetLineItem__c ali : [SELECT Id, APTS_Is_Primary_L1_Asset__c,
                        (select id,Apttus_Config2__AssetLineItemId__c,Apttus_Config2__OrderId__r.APTS_Change_of_Ownership__c from Apttus_Config2__OrderLineItems__r where 
                        Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c IN('Internal Movement','External Movement With Contract Change','External Movement Without Contract Change')
                        order by LastModifiedDate desc limit 1)
                           APTS_Stop_RtR_Transactions_from__c FROM Apttus_Config2__AssetLineItem__c
                           WHERE Id IN: mapAssetLineItem.keyset()]){
            
            mapPrimaryL1.put(ali.Id, mapAssetLineItem.get(ali.Id));
            if(ali.APTS_Is_Primary_L1_Asset__c != null){     
                mapPrimaryL1.put(ali.APTS_Is_Primary_L1_Asset__c, mapAssetLineItem.get(ali.Id));
            }
            //v2.9 START
            //Map<Id,Apttus_Config2__OrderLineItem__c> olitoali=new Map<Id,Apttus_Config2__OrderLineItem__c>();
            for(Apttus_Config2__OrderLineItem__c olichng:ali.Apttus_Config2__OrderLineItems__r){
                //if(olichng.Apttus_Config2__OrderId__r.APTS_Change_of_Ownership__c=true){
                    olitoali.put(olichng.Apttus_Config2__AssetLineItemId__c,olichng);
                    
                //}
            }//v2.9 END
          }
    
        for(Apttus_Config2__AssetLineItem__c ali : [SELECT Id,APTS_Calculated_Base_Extended_Price__c, APTS_Type_Of_Contract__c, APTS_Is_Primary_L1_Asset__c, Apttus_Config2__ChargeType__c,
                           APTS_Stop_RtR_Transactions_from__c FROM Apttus_Config2__AssetLineItem__c
                           WHERE Apttus_Config2__ChargeType__c IN : setChargeType AND 
                               Apttus_Config2__LineType__c =: lineType AND 
                               APTS_Type_Of_Contract__c!=null AND 
                               (Id IN: mapPrimaryL1.keySet() or APTS_Is_Primary_L1_Asset__c IN: mapPrimaryL1.keySet() )]){
              
                                                         
            if(!ADDITIONALSERVICEFEE.equalsIgnoreCase(ali.Apttus_Config2__ChargeType__c) && !USAGEFEE.equalsIgnoreCase(ali.Apttus_Config2__ChargeType__c)) {  
                system.debug('+++005 debug+++'+olitoali);
                //system.debug('+++olitoali.get(ali.Id).Apttus_Config2__OrderId__r.APTS_Change_of_Ownership__c++'+olitoali.get(ali.Id).Apttus_Config2__OrderId__r.APTS_Change_of_Ownership__c);
                system.debug('+++ali.APTS_Stop_RtR_Transactions_from__c++'+ali.APTS_Stop_RtR_Transactions_from__c);
                system.debug('++mapAssetLineItem+++'+mapAssetLineItem);
                system.debug('+++ali.APTS_Type_Of_Contract__c++'+ali.APTS_Type_Of_Contract__c);
                system.debug('+++ali.APTS_Calculated_Base_Extended_Price__c++'+ali.APTS_Calculated_Base_Extended_Price__c);
                system.debug('++setTypeOfContract+++'+setTypeOfContract);
                system.debug('+++ali.Apttus_Config2__ChargeType__c++'+ali.Apttus_Config2__ChargeType__c);
                system.debug('+++ali.APTS_Is_Primary_L1_Asset__c++'+ali.APTS_Is_Primary_L1_Asset__c);
                system.debug('+OwnershipMovement++'+OwnershipMovement);                
                system.debug('+FinalBoolean++'+FinalBoolean); 
               //v1.6 - START 
               if(FinalBoolean==TRUE&&FinalConverBoolean==TRUE){
                if((ali.APTS_Stop_RtR_Transactions_from__c>System.Today())&&                   (mapAssetLineItem.containsKey(ali.Id) && mapAssetLineItem.get(ali.Id) &&                      ((ali.APTS_Type_Of_Contract__c == 'Sales' && ali.APTS_Calculated_Base_Extended_Price__c > 0 &&                     ali.Apttus_Config2__ChargeType__c != 'Sales Price') || (setTypeOfContract.contains(ali.APTS_Type_Of_Contract__c) &&                     ali.Apttus_Config2__ChargeType__c != 'Sales Price'))                     ) ||                     (((ali.APTS_Is_Primary_L1_Asset__c == null &&  mapPrimaryL1.containsKey(ali.Id) &&                    mapPrimaryL1.get(ali.Id)) || mapPrimaryL1.containsKey(ali.APTS_Is_Primary_L1_Asset__c) &&                    mapPrimaryL1.get(ali.APTS_Is_Primary_L1_Asset__c)) && setTypeOfContract.contains(ali.APTS_Type_Of_Contract__c) &&                    ali.Apttus_Config2__ChargeType__c != 'Sales Price')){
                   //v2.0 - START
                    lstTransData.add(createTransData(ali.Id, TRANS_A005, null));
                    lstTransData.add(createTransData(ali.Id, TRANS_B005, null));
                    system.debug('+OwnershipMovement++'+OwnershipMovement);
                   //v2.0 - END
                } //v1.6 - END
                else if(ali.APTS_Stop_RtR_Transactions_from__c>System.Today()&&(mapAssetLineItem.containsKey(ali.Id) && !mapAssetLineItem.get(ali.Id)) ||                         (((ali.APTS_Is_Primary_L1_Asset__c == null &&  mapPrimaryL1.containsKey(ali.Id) && !mapPrimaryL1.get(ali.Id)) || mapPrimaryL1.containsKey(ali.APTS_Is_Primary_L1_Asset__c) && !mapPrimaryL1.get(ali.APTS_Is_Primary_L1_Asset__c)) &&                          (!setTypeOfContract.contains(ali.APTS_Type_Of_Contract__c) || (setTypeOfContract.contains(ali.APTS_Type_Of_Contract__c) && ali.Apttus_Config2__ChargeType__c != 'Sales Price')))){
                    lstTransData.add(createTransData(ali.Id, TRANS_0004, System.Today()));
                }
               }
               if(FinalBoolean==FALSE&&FinalConverBoolean==TRUE){
                if((ali.APTS_Stop_RtR_Transactions_from__c>System.Today())&&(mapAssetLineItem.containsKey(ali.Id) && mapAssetLineItem.get(ali.Id) &&                      ((ali.APTS_Type_Of_Contract__c == 'Sales' && ali.APTS_Calculated_Base_Extended_Price__c > 0 &&                     ali.Apttus_Config2__ChargeType__c != 'Sales Price') || (setTypeOfContract.contains(ali.APTS_Type_Of_Contract__c) &&                     ali.Apttus_Config2__ChargeType__c != 'Sales Price'))                     ) ||                     (((ali.APTS_Is_Primary_L1_Asset__c == null &&  mapPrimaryL1.containsKey(ali.Id) &&                    mapPrimaryL1.get(ali.Id)) || mapPrimaryL1.containsKey(ali.APTS_Is_Primary_L1_Asset__c) &&                    mapPrimaryL1.get(ali.APTS_Is_Primary_L1_Asset__c)) && setTypeOfContract.contains(ali.APTS_Type_Of_Contract__c) &&                    ali.Apttus_Config2__ChargeType__c != 'Sales Price')){
                   //v2.0 - START
                    lstTransData.add(createTransData(ali.Id, TRANS_0004, System.Today()));
                    system.debug('+OwnershipMovement++'+OwnershipMovement);
                   //v2.0 - END
                } //v1.6 - END
                else if(ali.APTS_Stop_RtR_Transactions_from__c>System.Today()&&(mapAssetLineItem.containsKey(ali.Id) && !mapAssetLineItem.get(ali.Id)) ||(((ali.APTS_Is_Primary_L1_Asset__c == null &&  mapPrimaryL1.containsKey(ali.Id) && !mapPrimaryL1.get(ali.Id)) || mapPrimaryL1.containsKey(ali.APTS_Is_Primary_L1_Asset__c) && !mapPrimaryL1.get(ali.APTS_Is_Primary_L1_Asset__c)) && (!setTypeOfContract.contains(ali.APTS_Type_Of_Contract__c) || (setTypeOfContract.contains(ali.APTS_Type_Of_Contract__c) && ali.Apttus_Config2__ChargeType__c != 'Sales Price')))){
                    lstTransData.add(createTransData(ali.Id, TRANS_0004, System.Today()));
                }
               }
               if(FinalBoolean==FALSE&&FinalConverBoolean==FALSE&&(!olitoali.isEmpty()) &&olitoali.get(ali.Id).Apttus_Config2__OrderId__r.APTS_Change_of_Ownership__c==true){
                if((ali.APTS_Stop_RtR_Transactions_from__c>System.Today())&&(mapAssetLineItem.containsKey(ali.Id) && mapAssetLineItem.get(ali.Id) && ((ali.APTS_Type_Of_Contract__c == 'Sales' && ali.APTS_Calculated_Base_Extended_Price__c > 0 &&ali.Apttus_Config2__ChargeType__c != 'Sales Price') || (setTypeOfContract.contains(ali.APTS_Type_Of_Contract__c) &&ali.Apttus_Config2__ChargeType__c != 'Sales Price'))) || (((ali.APTS_Is_Primary_L1_Asset__c == null &&  mapPrimaryL1.containsKey(ali.Id) &&mapPrimaryL1.get(ali.Id)) || mapPrimaryL1.containsKey(ali.APTS_Is_Primary_L1_Asset__c) &&mapPrimaryL1.get(ali.APTS_Is_Primary_L1_Asset__c)) && setTypeOfContract.contains(ali.APTS_Type_Of_Contract__c) &&ali.Apttus_Config2__ChargeType__c != 'Sales Price')){
                   //v2.0 - START
                    lstTransData.add(createTransData(ali.Id, TRANS_A005, null));
                    lstTransData.add(createTransData(ali.Id, TRANS_B005, null));
                    system.debug('+OwnershipMovement++'+OwnershipMovement);
                   //v2.0 - END
                } //v1.6 - END
                else if(((mapAssetLineItem.containsKey(ali.Id) && !mapAssetLineItem.get(ali.Id)) ||(((ali.APTS_Is_Primary_L1_Asset__c == null &&  mapPrimaryL1.containsKey(ali.Id) && !mapPrimaryL1.get(ali.Id)) || mapPrimaryL1.containsKey(ali.APTS_Is_Primary_L1_Asset__c) && !mapPrimaryL1.get(ali.APTS_Is_Primary_L1_Asset__c)) && (!setTypeOfContract.contains(ali.APTS_Type_Of_Contract__c) || (setTypeOfContract.contains(ali.APTS_Type_Of_Contract__c) && ali.Apttus_Config2__ChargeType__c != 'Sales Price'))))&&ali.APTS_Stop_RtR_Transactions_from__c>System.Today()){
                lstTransData.add(createTransData(ali.Id, TRANS_0004, System.Today()));
                }
               }
               if(FinalBoolean==FALSE&&FinalConverBoolean==FALSE&&(!olitoali.isEmpty())&&olitoali.get(ali.Id).Apttus_Config2__OrderId__r.APTS_Change_of_Ownership__c==false&&(ali.APTS_Stop_RtR_Transactions_from__c>System.Today())){
               /* if((ali.APTS_Stop_RtR_Transactions_from__c>System.Today())&&(mapAssetLineItem.containsKey(ali.Id) && mapAssetLineItem.get(ali.Id) && ((ali.APTS_Type_Of_Contract__c == 'Sales' && ali.APTS_Calculated_Base_Extended_Price__c > 0 &&ali.Apttus_Config2__ChargeType__c != 'Sales Price') || (setTypeOfContract.contains(ali.APTS_Type_Of_Contract__c) &&ali.Apttus_Config2__ChargeType__c != 'Sales Price'))) || (((ali.APTS_Is_Primary_L1_Asset__c == null &&  mapPrimaryL1.containsKey(ali.Id) &&mapPrimaryL1.get(ali.Id)) || mapPrimaryL1.containsKey(ali.APTS_Is_Primary_L1_Asset__c) &&mapPrimaryL1.get(ali.APTS_Is_Primary_L1_Asset__c)) && setTypeOfContract.contains(ali.APTS_Type_Of_Contract__c) &&ali.Apttus_Config2__ChargeType__c != 'Sales Price')){
                   //v2.0 - START
                    lstTransData.add(createTransData(ali.Id, TRANS_0004, System.Today()));
                    system.debug('+OwnershipMovement++'+OwnershipMovement);
                   //v2.0 - END
                } //v1.6 - END
                else if(ali.APTS_Stop_RtR_Transactions_from__c>System.Today()&&(mapAssetLineItem.containsKey(ali.Id) && !mapAssetLineItem.get(ali.Id)) ||(((ali.APTS_Is_Primary_L1_Asset__c == null &&  mapPrimaryL1.containsKey(ali.Id) && !mapPrimaryL1.get(ali.Id)) || mapPrimaryL1.containsKey(ali.APTS_Is_Primary_L1_Asset__c) && !mapPrimaryL1.get(ali.APTS_Is_Primary_L1_Asset__c)) && (!setTypeOfContract.contains(ali.APTS_Type_Of_Contract__c) || (setTypeOfContract.contains(ali.APTS_Type_Of_Contract__c) && ali.Apttus_Config2__ChargeType__c != 'Sales Price')))){
                    lstTransData.add(createTransData(ali.Id, TRANS_0004, System.Today()));
                }*/
                lstTransData.add(createTransData(ali.Id, TRANS_0004, System.Today()));
               }
                       
            
        }
       }
       if(!lstTransData.isEmpty()){ insert lstTransData; }
       
   }
   
     public static void createTransDatanewUX(List<ID> assetLIIdList,Date assetNewDate) {
     
     List<RTR_LAE_Transaction_Data__c> lstTransDataux = new List<RTR_LAE_Transaction_Data__c>();
     if(assetLIIdList.size()>0){
            for(Apttus_Config2__AssetLineItem__c ast:[select id from Apttus_Config2__AssetLineItem__c 
                                                              WHERE (ID IN:assetLIIdList OR Apttus_Config2__BundleAssetId__c IN:assetLIIdList) and Apttus_Config2__LineType__c='Product/Service' and (Apttus_Config2__ChargeType__c='Rental Fee' OR Apttus_Config2__ChargeType__c='Service Fee')]){
                    RTR_LAE_Transaction_Data__c  tempATL = new RTR_LAE_Transaction_Data__c  ();
                    tempATL.APTS_Asset_Line_Item__c = ast.Id;
                    tempATL.APTS_Business_Transaction_Type__c = '0003';    
                    tempATL.APTS_Contract_Effective_Date__c =assetNewDate.addYears(-1).adddays(1);
                    lstTransDataux.add(tempATL);
                }
                if (lstTransDataux.size() > 0) {
                    insert lstTransDataux;
                }
        }
        
    }
   
}