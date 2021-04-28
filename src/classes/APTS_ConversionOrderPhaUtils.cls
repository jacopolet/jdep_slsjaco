/*************************************************************
    @Name: APTS_ConversionOrderPhaUtils
    @Author: Karan Khatri
    @CreateDate: 29-06-2020
    @Description: This class is used for updating physical asset handled by QTC
    @UsedBy: APTS_Assetlineitemtrigger
    ******************************************************************/
    //v1 - Karan - DQ-2730 - Redesign of Physical Asset flow via Conversion
    //v2 - Karan - DQ-3949 - Restricting flushing Service window and Response time because of data issues in PHA(Commented lines of code).
    //v3 - Manisha-DQ-4011 - Populating WaterfilterCoverage in Conversion flow
    //v4 - Karan - DQ-5062 - Adding Auto-Renew checkbox logic and few optimizations
    //v5 - Renuka - DQ-5187 - Populating Last WTS date and Last Prev Maint date field.
    //v6 - Renuka - DQ-5193 - Skip the validation of WaterSystem for populating WaterFilter coverage to 100%
    //v7 - Renuka - DQ-5307 - Muting the phA PO-Number updating logic 
    //v6 - Karan - DQ-5446 - First Line Response Time changes as per the flow
    //v7 - Karan - DQ-5187 - Extending check for Value Added Services check to consider only WATERFILTER REPLACEMENT
    
    public with sharing class APTS_ConversionOrderPhaUtils {

        private static String COPHAQUERY = 'APTS_ConversionOrderPhaQuery';
        private static String WaterSystem = 'Water System';
        private static String ValueAddedService = 'Value Added Service';
        //v4-S
        private static Date POST_GO_LIVE_DATE = Date.newInstance(2019,02,04);
        private static String COFFEE_KITCHEN_SCI = '0701';
        //v4-E
        
        public static void updatePhysicalAssetFieldsABO(Set<ID> conversionAssetIdSet){
            
            List<Apttus_Config2__AssetLineItem__c> refinedQueryList = new List<Apttus_Config2__AssetLineItem__c>();
            Map<Id,PhysicalAsset__c> physicalAssetUpsertMap = new Map<Id,PhysicalAsset__c>();
            Map<Id,PhysicalAsset__c> parentPhysicalAssetMap = new Map<Id,PhysicalAsset__c>();
            Map<id,Apttus_Config2__AssetAttributeValue__c> techServCoverageMap = new Map<id,Apttus_Config2__AssetAttributeValue__c>();
            Map<id,Boolean> connectivitySystemMap = new Map<id,Boolean>();
            Map<id,String> prevMaintainenceMap = new Map<id,String>();
            Map<id,Apttus_Config2__AssetLineItem__c> prevMaintainenceASLIMap = new Map<id,Apttus_Config2__AssetLineItem__c>();
            Map<String ,Apttus_Config2__AssetLineItem__c> WaterFilterCoverageMap = new Map<String,Apttus_Config2__AssetLineItem__c>();
            Map<id,String> weekDaysMap = new Map<id,String>();
            Map<id,String> mCareMap = new Map<id,String>();
            Set<ID> agreementIdSet = new Set<ID>();
            Map<String,APTS_Agreement_PO_Details__c> oAgreementPODetailsMap = new Map<String,APTS_Agreement_PO_Details__c>();
            Map<String,String> machineCareValues = new  Map<String,String>();
            Map<Id,Apttus_Config2__AssetLineItem__c> assetLineItemsUpdateMap = new Map<id,Apttus_Config2__AssetLineItem__c>();
            Map<Id,String> responseTimeMap = new Map<id,String>();
            //V6-S
            Map<Id,Decimal> responseTimeS15Map = new Map<id,Decimal>();
            //V6-E
            Map<String, String> phaALIMetadataMapping = new Map<String, String>();
            Map<Id,APTS_Order_LSP_Details__c> parentLSPDetails = new Map<Id,APTS_Order_LSP_Details__c>();
            Set<String> recurringPriceTypeSet=new Set<String>{'Usage','Recurring'};
            Set<String> autoRenewalBundleAssetSet = new  Set<String>();
            for( Schema.PicklistEntry v :  PhysicalAsset__c.Machine_Care__c.getDescribe().getPicklistValues()) {
                machineCareValues.put(v.getValue(),v.getLabel());
            }
            //v4-S
            if(!conversionAssetIdSet.isEmpty()){
            //v4-E    
               //Refined Query with additional select clauses.
                List<APTS_ApexClassQuery__mdt> batchQuery = [SELECT Id,APTS_Query__c
                                                            FROM APTS_ApexClassQuery__mdt
                                                            WHERE DeveloperName =: COPHAQUERY limit 1];
                String query = batchQuery[0].APTS_Query__c;   
                //System.debug('***PHA****query=========>'+query);
                refinedQueryList = Database.query(query);
            //v4-S
            }
            //v4-E
            if(!refinedQueryList.isEmpty()){
                for (Apttus_Config2__AssetLineItem__c oAssetLineItem : refinedQueryList) {
                    if(oAssetLineItem.Apttus_Config2__LineType__c!=null && oAssetLineItem.Apttus_Config2__LineType__c.equalsIgnoreCase('Option')  && oAssetLineItem.Apttus_Config2__AssetStatus__c.equalsIgnoreCase('Activated')){
                        if(oAssetLineItem.APTS_Option_Group_Text__c!=null && oAssetLineItem.APTS_Option_Group_Text__c.equalsIgnoreCase('Technical Service')){
                            if(techServCoverageMap.get(oAssetLineItem.Apttus_Config2__BundleAssetId__c)==null){
                                techServCoverageMap.put(oAssetLineItem.Apttus_Config2__BundleAssetId__c,oAssetLineItem.Apttus_Config2__AttributeValueId__r);
                            }
                        }
                        //v3-Populating WaterfilterCoverage in Conversion flow, v6 commented WaterSystem
                        //v7-S
                        if(oAssetLineItem.APTS_Option_Group_Text__c!=null && oAssetLineItem.APTS_Option_Group_Text__c.equalsIgnoreCase('Value Added Service') && oAssetLineItem.Apttus_Config2__Description__c.equalsIgnoreCase('WATERFILTER REPLACEMENT')/*||oAssetLineItem.APTS_Option_Group_Text__c.equalsIgnoreCase('Water System'))*/){
                        //v7-E
                            if(!WaterFilterCoverageMap.containskey(String.valueof(oAssetLineItem.Apttus_Config2__BundleAssetId__c)+oAssetLineItem.APTS_Option_Group_Text__c)){
                                WaterFilterCoverageMap.put(String.valueof(oAssetLineItem.Apttus_Config2__BundleAssetId__c)+oAssetLineItem.APTS_Option_Group_Text__c,oAssetLineItem);
                            }
                        }
                        if(oAssetLineItem.APTS_Option_Group_Text__c!=null && oAssetLineItem.APTS_Option_Group_Text__c.containsIgnoreCase('Connectivity System')){
                            if(connectivitySystemMap.get(oAssetLineItem.Apttus_Config2__BundleAssetId__c)==null){
                                connectivitySystemMap.put(oAssetLineItem.Apttus_Config2__BundleAssetId__c,true);
                            }
                        }
                        if(oAssetLineItem.Apttus_Config2__OptionId__c!=null && 
                        oAssetLineItem.Apttus_Config2__OptionId__r.name!=null && 
                        oAssetLineItem.APTS_Option_Group_Text__c!=null && 
                        oAssetLineItem.APTS_Option_Group_Text__c.containsIgnoreCase('Preventive Maintenance')){
                            String prevInterval;
                            if(APTS_OrderLineItemUtils.getPrevenetiveMaintenanceIntervel(oAssetLineItem.Apttus_Config2__OptionId__r.name)!=null){
                                prevInterval = APTS_OrderLineItemUtils.getPrevenetiveMaintenanceIntervel(oAssetLineItem.Apttus_Config2__OptionId__r.name);
                            }
                            if(prevInterval==null) {prevInterval='0';}
                            if(prevMaintainenceMap.get(oAssetLineItem.Apttus_Config2__BundleAssetId__c)==null){
                                prevMaintainenceMap.put(oAssetLineItem.Apttus_Config2__BundleAssetId__c,prevInterval);
                            }
                            if(!prevMaintainenceASLIMap.containsKey(oAssetLineItem.Apttus_Config2__BundleAssetId__c)){
                                prevMaintainenceASLIMap.put(oAssetLineItem.Apttus_Config2__BundleAssetId__c,oAssetLineItem);
                            }
                        }
                        if(oAssetLineItem.Apttus_Config2__Description__c!=null && oAssetLineItem.Apttus_Config2__Description__c.containsIgnoreCase('Weekdays')){
                            if(weekDaysMap.get(oAssetLineItem.Apttus_Config2__BundleAssetId__c)==null){
                                weekDaysMap.put(oAssetLineItem.Apttus_Config2__BundleAssetId__c,oAssetLineItem.Apttus_Config2__Description__c);
                            }
                        }
                        if(oAssetLineItem.APTS_Option_Group_Text__c!=null &&
                        oAssetLineItem.APTS_Option_Group_Text__c.equalsIgnoreCase('Response Time') &&
                        oAssetLineItem.Apttus_Config2__AccountId__r.Sales_Organization__c!=null){
                            if(oAssetLineItem.Apttus_Config2__OptionId__r.APTS_Response_Time_Hours__c!=null){
                                String responseTime = APTS_OrderLineItemUtils.getResponseTime(oAssetLineItem.Apttus_Config2__AccountId__r.Sales_Organization__c,String.valueOf(Integer.valueOf(oAssetLineItem.Apttus_Config2__OptionId__r.APTS_Response_Time_Hours__c)));
                                if(responseTime!=null && responseTimeMap.get(oAssetLineItem.Apttus_Config2__BundleAssetId__c)==null){
                                    responseTimeMap.put(oAssetLineItem.Apttus_Config2__BundleAssetId__c,responseTime);
                                }
                            }
                            //V6-S
                            if(oAssetLineItem.Apttus_Config2__AttributeValueId__r.APTS_First_Line_Response_Time__c!=null){
                                responseTimeS15Map.put(oAssetLineItem.Apttus_Config2__BundleAssetId__c,oAssetLineItem.Apttus_Config2__AttributeValueId__r.APTS_First_Line_Response_Time__c);
                            }
                            //V6-E
                        }
                        System.debug('PHA KARAN oAssetLineItem.APTS_Physical_Asset__c==========>'+oAssetLineItem.APTS_Physical_Asset__c);
                        //Populate which machine care item customer has brought
                        if(oAssetLineItem.Apttus_Config2__Description__c!=null){
                            for(String mCare : machineCareValues.values()){
                                if(oAssetLineItem.Apttus_Config2__Description__c.containsIgnoreCase(mCare) && mCareMap.get(oAssetLineItem.Apttus_Config2__BundleAssetId__c)==null){
                                    if(oAssetLineItem.Apttus_Config2__AttributeValueId__r.APTS_Number_of_hours_per_month__c!=null){
                                        mCareMap.put(oAssetLineItem.Apttus_Config2__BundleAssetId__c,mCare+';'+oAssetLineItem.Apttus_Config2__AttributeValueId__r.APTS_Number_of_hours_per_month__c);
                                    }else{
                                        mCareMap.put(oAssetLineItem.Apttus_Config2__BundleAssetId__c,mCare);
                                    }
                                }
                            }                            
                        }
                        //v4-S
                        if(oAssetLineItem.Apttus_Config2__EndDate__c >= POST_GO_LIVE_DATE &&
                           oAssetLineItem.Apttus_Config2__AssetStatus__c.equalsIgnoreCase(APTS_CPQConstants.LABEL_ACTIVATED) &&
                           recurringPriceTypeSet.contains(oAssetLineItem.Apttus_Config2__PriceType__c) &&
                           (oAssetLineItem.Apttus_Config2__ProductId__r.APTS_Sales_Catalog__c.startsWith(APTS_CPQConstants.MACHINES_SCI) || oAssetLineItem.Apttus_Config2__ProductId__r.APTS_Sales_Catalog__c.equalsIgnoreCase(COFFEE_KITCHEN_SCI)) &&
                            oAssetLineItem.Apttus_Config2__LineType__c.equalsIgnoreCase(APTS_CPQConstants.LABEL_OPTION) &&
                            oAssetLineItem.Apttus_Config2__BundleAssetId__r.Apttus_Config2__IsPrimaryLine__c &&
                            oAssetLineItem.Apttus_Config2__AutoRenew__c && 
                            oAssetLineItem.Apttus_Config2__BundleAssetId__r.Apttus_Config2__AssetStatus__c.equalsIgnoreCase(APTS_CPQConstants.LABEL_ACTIVATED)){
                                autoRenewalBundleAssetSet.add(oAssetLineItem.Apttus_Config2__BundleAssetId__c);
                        }
                        //v4-E
                    }
                    if(oAssetLineItem.APTS_Is_Primary_L1_Line__c){
                        if(parentPhysicalAssetMap.get(oAssetLineItem.id)==null){
                            parentPhysicalAssetMap.put(oAssetLineItem.id,oAssetLineItem.APTS_Physical_Asset__r);
                        }
                        if(parentLSPDetails.get(oAssetLineItem.id)==null){
                            parentLSPDetails.put(oAssetLineItem.id,oAssetLineItem.APTS_Order_LSP_Detail__r);
                        }
                    }
                    if(oAssetLineItem.APTS_relatedlist_agreement__c!=null){
                        agreementIdSet.add(oAssetLineItem.APTS_relatedlist_agreement__c);
                    }
                }
            }
            //Populating Agreement PO related maps, v6 commented the below logic
            /*if(!agreementIdSet.isEmpty()){
                oAgreementPODetailsMap = getAgreementPODetails(agreementIdSet);
            }*/
            //= APTS_OrderLineItemUtils.getBillingSettings(agreementIdSet);
            
            phaALIMetadataMapping =  getassetPHAfieldMapping();

            if(!refinedQueryList.isEmpty()){
                for(Apttus_Config2__AssetLineItem__c oAssetLineItem : refinedQueryList) {
                    //Label to store option group indicators trigger pha creation
                    PhysicalAsset__c ParentPhA;
                    List<String> phaOptionGroupSet = System.Label.APTS_AllowedOptionGroupIndicators.split(',');
                    List<String> phaFlushingList = System.Label.APTS_PHAAvoidFlushingValueSalesOrg.split(',');
                    if(oAssetLineItem.APTS_Is_Primary_L1_Line__c ||
                    (oAssetLineItem.Apttus_Config2__OptionId__c!=null && phaOptionGroupSet.contains(oAssetLineItem.Apttus_Config2__OptionId__r.APTS_Option_Group_Indicator__c))){
                        PhysicalAsset__c oPhysicalAsset = new PhysicalAsset__c();
                        if(!(oAssetLineItem.APTS_MigrationDate__c!=null && phaFlushingList.contains(oAssetLineItem.Apttus_Config2__AccountId__r.Sales_Organization__c))){
                            resetValuesToBlank(oPhysicalAsset);
                        }
                        if(oAssetLineItem.Apttus_Config2__LineType__c.equalsIgnoreCase('Option') && oAssetLineItem.APTS_Is_Primary_L1_Asset__c!=null && parentPhysicalAssetMap.get(oAssetLineItem.APTS_Is_Primary_L1_Asset__c)!=null){
                            ParentPhA = parentPhysicalAssetMap.get(oAssetLineItem.APTS_Is_Primary_L1_Asset__c);
                        }
                        oPhysicalAsset.Product__c = oAssetLineItem.Apttus_Config2__LineType__c.equalsIgnoreCase('Option') ? oAssetLineItem.Apttus_Config2__OptionId__c : oAssetLineItem.Apttus_Config2__ProductId__c;
                        if(!phaALIMetadataMapping.isEmpty()){
                            mapAssetPHAFields(oPhysicalAsset,oAssetLineItem,phaALIMetadataMapping);
                        }
                        
                        //=========From Account location==========
                        oPhysicalAsset.Country__c = oAssetLineItem.Apttus_Config2__LocationId__r.Apttus_Config2__Country__c;
                        oPhysicalAsset.ShippingCountryISO__c = oAssetLineItem.Apttus_Config2__LocationId__r.Shipping_Country_ISO__c;
                        oPhysicalAsset.PostalCode__c = oAssetLineItem.Apttus_Config2__LocationId__r.Apttus_Config2__PostalCode__c;
                        oPhysicalAsset.Street__c = oAssetLineItem.Apttus_Config2__LocationId__r.Apttus_Config2__Street__c;
                        oPhysicalAsset.HouseNumber__c = oAssetLineItem.Apttus_Config2__LocationId__r.Shipping_House_Number__c;
                        oPhysicalAsset.City__c = oAssetLineItem.Apttus_Config2__LocationId__r.Apttus_Config2__City__c;
                        
                        //=======From Attributes==========
                        if(oAssetLineItem.Apttus_Config2__AttributeValueId__r.APTS_Consumer_Price__c!=null){
                            oPhysicalAsset.ConsumptionPrice__c = oAssetLineItem.Apttus_Config2__AttributeValueId__r.APTS_Consumer_Price__c;
                        }
                        if(oAssetLineItem.Apttus_Config2__AttributeValueId__r.APTS_Cup_Size__c!=null){
                            oPhysicalAsset.CupSize__c = oAssetLineItem.Apttus_Config2__AttributeValueId__r.APTS_Cup_Size__c;
                        }
                        if(oAssetLineItem.Apttus_Config2__AttributeValueId__r.APTS_Taste_Pallet__c!=null){
                            oPhysicalAsset.TastePallet__c = oAssetLineItem.Apttus_Config2__AttributeValueId__r.APTS_Taste_Pallet__c;
                        }
                        if(oAssetLineItem.Apttus_Config2__AttributeValueId__r.APTS_Type_of_payment__c!=null){
                            oPhysicalAsset.TypeOfConsumption__c = oAssetLineItem.Apttus_Config2__AttributeValueId__r.APTS_Type_of_payment__c;
                        }
                        if(oAssetLineItem.Apttus_Config2__AttributeValueId__r.APTS_Number_of_months__c!=null){
                            oPhysicalAsset.Warranty__c = oAssetLineItem.Apttus_Config2__AttributeValueId__r.APTS_Number_of_months__c;
                        }
                        if(oAssetLineItem.Apttus_Config2__AttributeValueId__r.APTS_Merchant__c!=null){
                            oPhysicalAsset.Merchant__c = oAssetLineItem.Apttus_Config2__AttributeValueId__r.APTS_Merchant__c;
                        }
                        if(oAssetLineItem.Apttus_Config2__AttributeValueId__r.APTS_WTS_Changed_By__c!=null){
                            oPhysicalAsset.WTSChangedBy__c = oAssetLineItem.Apttus_Config2__AttributeValueId__r.APTS_WTS_Changed_By__c;
                        }
                        /*if(oAssetLineItem.Apttus_Config2__AttributeValueId__r.APTS_First_Line_Response_Time__c!=null){
                            oPhysicalAsset.ResponseTimeS15__c=oAssetLineItem.Apttus_Config2__AttributeValueId__r.APTS_First_Line_Response_Time__c;
                        }*/
                        if(oAssetLineItem.Apttus_Config2__AttributeValueId__r.APTS_Type_Of_Contract__c!=null){
                            oPhysicalAsset.TypeOfContract__c = oAssetLineItem.Apttus_Config2__AttributeValueId__r.APTS_Type_Of_Contract__c;
                        }
                        ///=======From Agreement==========
                        if(oAssetLineItem.APTS_relatedlist_agreement__c!=null){
                            oPhysicalAsset.ActiveContract__c = oAssetLineItem.APTS_relatedlist_agreement__r.Apttus__Status__c!=null && oAssetLineItem.APTS_relatedlist_agreement__r.Apttus__Status__c.equalsIgnoreCase('Activated') || oAssetLineItem.APTS_relatedlist_agreement__r.Apttus__Status__c.equalsIgnoreCase('Being Amended');
                            oPhysicalAsset.AgreementRecordType__c = oAssetLineItem.APTS_relatedlist_agreement__r.RecordType.Name;
                            oPhysicalAsset.Routesales__c =  oAssetLineItem.APTS_relatedlist_agreement__r.APTS_Routesales__c;
                        }

                        //Updating Warranty start date only for CTC case for Sales.
                        if(oAssetLineItem.APTS_Contract_Change__c && oAssetLineItem.APTS_Type_Of_Contract__c!=null && oAssetLineItem.APTS_Type_Of_Contract__c.equalsIgnoreCase('Sales')){
                            oPhysicalAsset.WarrantyStartDate__c=System.TODAY();
                        }

                        //=========Updating Agreement PO details=========, v6 Commented the below logic
                        /*if(!oAgreementPODetailsMap.isEmpty()) {
                            if (oAgreementPODetailsMap.get(oAssetLineItem.APTS_relatedlist_agreement__c+'Machine')!=null) {
                                    APTS_Agreement_PO_Details__c machinePODetails = oAgreementPODetailsMap.get(oAssetLineItem.APTS_relatedlist_agreement__c+'Machine');
                                    oPhysicalAsset.PONumberRequiredMachines__c = (machinePODetails.APTS_PO_Number_Required__c != null) ? machinePODetails.APTS_PO_Number_Required__c : oPhysicalAsset.PONumberRequiredMachines__c;
                                    oPhysicalAsset.PONumberTypeMachines__c = (machinePODetails.APTS_PO_Number_Type__c != null) ? machinePODetails.APTS_PO_Number_Type__c : oPhysicalAsset.PONumberTypeMachines__c;
                                    oPhysicalAsset.PONumberMachines__c = (machinePODetails.APTS_PO_Number__c != null) ? machinePODetails.APTS_PO_Number__c : oPhysicalAsset.PONumberMachines__c;
                            }
                            if (oAgreementPODetailsMap.get(oAssetLineItem.APTS_relatedlist_agreement__c+'Services')!=null) {
                                    APTS_Agreement_PO_Details__c servicesPODetails = oAgreementPODetailsMap.get(oAssetLineItem.APTS_relatedlist_agreement__c+'Services');
                                    oPhysicalAsset.PONumberRequiredServices__c = (servicesPODetails.APTS_PO_Number_Required__c != null) ? servicesPODetails.APTS_PO_Number_Required__c : oPhysicalAsset.PONumberRequiredServices__c;
                                    oPhysicalAsset.PONumberServices__c = (servicesPODetails.APTS_PO_Number__c != null) ? servicesPODetails.APTS_PO_Number__c : oPhysicalAsset.PONumberServices__c;
                                    oPhysicalAsset.PONumberTypeServices__c = (servicesPODetails.APTS_PO_Number_Type__c != null) ? servicesPODetails.APTS_PO_Number_Type__c : oPhysicalAsset.PONumberTypeServices__c;
                            }
                        }*/
                        
                        //=======From Sold to Account========
                        oPhysicalAsset.SalesOrganization__c = oAssetLineItem.Apttus_Config2__AccountId__r.Sales_Organization__c;

                        /*###===Primary l1 physical asset=========## This section will be used Only for Primary l1 related field updates*/
                        if(oAssetLineItem.APTS_Is_Primary_L1_Line__c){
                            Id bundleassetid = oAssetLineItem.Apttus_Config2__BundleAssetId__c!=null ? oAssetLineItem.Apttus_Config2__BundleAssetId__c : oAssetLineItem.id;
                            System.debug('oAssetLineItem.APTS_Contract_Change__c=============>'+oAssetLineItem.APTS_Contract_Change__c);
                            System.debug('oAssetLineItem.APTS_Serial_Number__c=============>'+oAssetLineItem.APTS_Serial_Number__c);
                            System.debug('APTS_OLI_serial_number__c=============>'+oAssetLineItem.APTS_OLI_serial_number__c);
                            //populating unique number for Parent Pha
                            oPhysicalAsset.UniqueNumber__c = oAssetLineItem.Apttus_Config2__ProductId__r.APTS_Vendor_Code__c + oAssetLineItem.APTS_OLI_serial_number__c;
                         
                            //=========primary L1 LSP Details==========
                            if(oAssetLineItem.APTS_Order_LSP_Detail__c!=null){
                                oPhysicalAsset.Area__c =  oAssetLineItem.APTS_Order_LSP_Detail__r.APTS_Area__c;
                                oPhysicalAsset.Floor__c = oAssetLineItem.APTS_Order_LSP_Detail__r.APTS_Floor__c;
                                oPhysicalAsset.Building__c = oAssetLineItem.APTS_Order_LSP_Detail__r.APTS_Building__c;
                                oPhysicalAsset.CustomerReferenceNumber__c = oAssetLineItem.APTS_Order_LSP_Detail__r.APTS_CustomerReference__c;
                                oPhysicalAsset.SmokingArea__c = oAssetLineItem.APTS_Order_LSP_Detail__r.APTS_SmokingArea__c;
                                oPhysicalAsset.JDECrockeryVolumeSize__c = oAssetLineItem.APTS_Order_LSP_Detail__r.APTS_JDE_crockeryVolumeSize__c;
                            }
                            //Setting start date and end date for parent asset
                            oPhysicalAsset.StartDate__c = oAssetLineItem.Apttus_Config2__BundleAssetId__c!=null ? oAssetLineItem.Apttus_Config2__BundleAssetId__r.Apttus_Config2__StartDate__c : oAssetLineItem.Apttus_Config2__StartDate__c;
                            oPhysicalAsset.EndDate__c = oAssetLineItem.Apttus_Config2__BundleAssetId__c!=null ? oAssetLineItem.Apttus_Config2__BundleAssetId__r.Apttus_Config2__EndDate__c : oAssetLineItem.Apttus_Config2__EndDate__c;
                            //Technical services related coverage fields
                            System.debug('techServCoverageMap=============>'+techServCoverageMap);
                            System.debug('bundleassetid=============>'+bundleassetid);
                            if(!techServCoverageMap.isEmpty() && bundleassetid!=null && techServCoverageMap.get(bundleassetid)!=null){
                                if(techServCoverageMap.get(bundleassetid).APTS_Call_Out_Coverage_chk__c!=null && techServCoverageMap.get(bundleassetid).APTS_Call_Out_Coverage_chk__c.equalsIgnoreCase('Yes')){
                                    oPhysicalAsset.CallOutChargeCoverage__c = 100;
                                }
                                if(techServCoverageMap.get(bundleassetid).APTS_Spare_Parts_Coverage_chk__c!=null && techServCoverageMap.get(bundleassetid).APTS_Spare_Parts_Coverage_chk__c.equalsIgnoreCase('Yes')){
                                    oPhysicalAsset.SparePartCoverage__c = 100;
                                }
                                if(techServCoverageMap.get(bundleassetid).APTS_Labour_Coverage_chk__c!=null && techServCoverageMap.get(bundleassetid).APTS_Labour_Coverage_chk__c.equalsIgnoreCase('Yes')){
                                    oPhysicalAsset.LabourChargeCoverage__c = 100;    
                                }
                            }
                            //v3-Populating WaterfilterCoverage in Conversion flow, v6 commented WaterSystem check
                            if(/*oPhysicalAsset.WTSChangedBy__c!=null &&*/ !WaterFilterCoverageMap.isEmpty() && bundleassetid!=null /*&& WaterFilterCoverageMap.containskey(string.valueof(bundleassetid)+WaterSystem)*/ && WaterFilterCoverageMap.containskey(string.valueof(bundleassetid)+ValueAddedService)){
                                oPhysicalAsset.IncludesWTSCoverage__c = true;
                                oPhysicalAsset.WaterfilterCoverage__c = 100;
                                if(!parentPhysicalAssetMap.isEmpty() && parentPhysicalAssetMap.containsKey(oAssetLineItem.id) 
                                    && parentPhysicalAssetMap.get(oAssetLineItem.id) != null 
                                    && parentPhysicalAssetMap.get(oAssetLineItem.id).LastWTSDate__c != null){
                                    oPhysicalAsset.LastWTSDate__c = parentPhysicalAssetMap.get(oAssetLineItem.id).LastWTSDate__c;
                                }else{
                                    oPhysicalAsset.LastWTSDate__c = WaterFilterCoverageMap.get(string.valueof(bundleassetid)+ValueAddedService).Apttus_Config2__StartDate__c;
                                }
                                //oPhysicalAsset.LastWTSDate__c = ParentPhA != null && ParentPhA.LastWTSDate__c == null ? WaterFilterCoverageMap.get(string.valueof(bundleassetid)+ValueAddedService).Apttus_Config2__StartDate__c : ParentPhA.LastWTSDate__c; //v5
                            }
                            //Connectivity System options related fields
                            if(!connectivitySystemMap.isEmpty() && bundleassetid!=null && connectivitySystemMap.get(bundleassetid)){
                                oPhysicalAsset.Connected__c = 'Yes';
                                oPhysicalAsset.CounterReading__c = 'Yes';
                            }
                            //Preventive Maintainence related options related fields
                            if(!prevMaintainenceMap.isEmpty() && bundleassetid!=null && prevMaintainenceMap.get(bundleassetid)!=null){
                                oPhysicalAsset.IncludesPreventiveMaintenanceCoverage__c = true;
                                oPhysicalAsset.PreventiveMaintenanceCoverage__c = Decimal.valueOf('100.00');
                                if(prevMaintainenceMap.get(bundleassetid)=='0'){
                                    oPhysicalAsset.PreventiveMaintenanceInterval__c=null;
                                }else{
                                    oPhysicalAsset.PreventiveMaintenanceInterval__c=prevMaintainenceMap.get(bundleassetid);
                                }
                                if(!prevMaintainenceASLIMap.isEmpty() && prevMaintainenceASLIMap.containsKey(bundleassetid) 
                                    && !parentPhysicalAssetMap.isEmpty() && parentPhysicalAssetMap.containsKey(oAssetLineItem.id) 
                                    && parentPhysicalAssetMap.get(oAssetLineItem.id) != null && parentPhysicalAssetMap.get(oAssetLineItem.id).LastPreventiveMaintenanceDate__c != null){
                                    oPhysicalAsset.LastPreventiveMaintenanceDate__c = parentPhysicalAssetMap.get(oAssetLineItem.id).LastPreventiveMaintenanceDate__c;
                                }else{
                                    oPhysicalAsset.LastPreventiveMaintenanceDate__c = prevMaintainenceASLIMap.get(bundleassetid).Apttus_Config2__StartDate__c;
                                }
                                /*if(!prevMaintainenceASLIMap.isEmpty() && prevMaintainenceASLIMap.containsKey(bundleassetid)){
                                    oPhysicalAsset.LastPreventiveMaintenanceDate__c = ParentPhA != null && ParentPhA.LastPreventiveMaintenanceDate__c == null ? prevMaintainenceASLIMap.get(bundleassetid).Apttus_Config2__StartDate__c : ParentPhA.LastPreventiveMaintenanceDate__c; //v5
                                }*/
                                
                            }
                            //Week Days related options related fields
                            if(!weekDaysMap.isEmpty() && bundleassetid!=null && weekDaysMap.get(bundleassetid)!=null){
                                oPhysicalAsset.ServiceWindow__c = weekDaysMap.get(bundleassetid);
                            }
                            //Response time through custom setting
                            if(bundleassetid!=null && !responseTimeMap.isEmpty() && responseTimeMap.get(bundleassetid)!=null){
                                oPhysicalAsset.ResponseTime__c=responseTimeMap.get(bundleassetid);
                            }
                            //Populate Machine care field
                            System.debug('mCareMap=============>'+mCareMap);
                            if(bundleassetid!=null && !mCareMap.isEmpty() && mCareMap.get(bundleassetid)!=null){ 
                                List<String> concateString = mCareMap.get(bundleassetid).split(';');
                                System.debug('concateString=======>'+concateString);
                                if(!String.isBlank(concateString[0])){
                                    oPhysicalAsset.Machine_Care__c = concateString[0];
                                }
                                if(concateString[0].equalsIgnoreCase('Full Operating')){
                                    oPhysicalAsset.FullOperatingCoverage__c = Decimal.valueOf('100.00');
                                    oPhysicalAsset.CounterReading__c='Yes';
                                }
                                if(concateString[0].equalsIgnoreCase('Semi Operating')){
                                    oPhysicalAsset.CounterReading__c='Yes';
                                }
                                if(concateString.size()==2){
                                    if(!String.isBlank(concateString[1])){
                                        System.debug('concateString[1]============>'+concateString[1]);
                                        oPhysicalAsset.MachineCareHours__c = Decimal.valueOf(concateString[1]);
                                    }
                                }
                            }
                            //v4-S
                            if(autoRenewalBundleAssetSet.contains(bundleassetid)){
                                oPhysicalAsset.APTS_AutoRenew__c = true;
                            }
                            //v4-E
                            //V6-S
                            if(bundleassetid!=null && !responseTimeS15Map.isEmpty() && responseTimeS15Map.get(bundleassetid)!=null){
                                oPhysicalAsset.ResponseTimeS15__c=responseTimeS15Map.get(bundleassetid);
                            }
                            //V6-E
                        }
                        /*###====Option physical asset========### This section will be used Only for Option PHA field updates*/
                        if (oAssetLineItem.Apttus_Config2__LineType__c.equalsIgnoreCase('Option')) {
                            System.debug('APTS_OLI_serial_number__c====OPTION=========>'+oAssetLineItem.APTS_OLI_serial_number__c);
                            //Name for option physical asset
                            oPhysicalAsset.name = oAssetLineItem.Apttus_Config2__Description__c;
                            //Setting start date and end date for options
                            oPhysicalAsset.StartDate__c = oAssetLineItem.Apttus_Config2__StartDate__c;
                            oPhysicalAsset.EndDate__c = oAssetLineItem.Apttus_Config2__EndDate__c;
                            //Unique number for option and parent pha association w/o contract type change
                            if(ParentPhA!=null && oAssetLineItem.Apttus_Config2__OptionId__c!=null && oAssetLineItem.Apttus_Config2__OptionId__r.ProductCode!=null){
                                 //populating unique number for Option Pha
                                if(oAssetLineItem.APTS_OLI_serial_number__c!=null){
                                    oPhysicalAsset.UniqueNumber__c = oAssetLineItem.Apttus_Config2__OptionId__r.ProductCode + '_' + ParentPhA.UniqueNumber__c + '_' + oAssetLineItem.APTS_OLI_serial_number__c;
                                }else{
                                    oPhysicalAsset.UniqueNumber__c = oAssetLineItem.Apttus_Config2__OptionId__r.ProductCode + '_' + ParentPhA.UniqueNumber__c;
                                }
                                oPhysicalAsset.ParentPhysicalAsset__c=ParentPhA.id;
                                oPhysicalAsset.MerchantId__c = ParentPhA.MerchantId__c;
                            }
                            if(oAssetLineItem.APTS_Option_Group_Text__c!=null && oAssetLineItem.APTS_Option_Group_Text__c.containsIgnoreCase('Connectivity System')){
                                oPhysicalAsset.Connected__c='Yes';
                                oPhysicalAsset.CounterReading__c='Yes';
                            }
                            System.debug('oAssetLineItem.APTS_Contract_Change__c======OPTION=======>'+oAssetLineItem.APTS_Contract_Change__c);
                            System.debug('oPhysicalAsset.UniqueNumber__c=====OPTION========>'+oPhysicalAsset.UniqueNumber__c);
                            System.debug('oAssetLineItem.APTS_Is_Primary_L1_Asset__r=============>'+oAssetLineItem.APTS_Is_Primary_L1_Asset__c);
                            if(oAssetLineItem.APTS_Is_Primary_L1_Asset__c!=null){
                                System.debug('oAssetLineItem.APTS_Is_Primary_L1_Asset__r.APTS_OLI_serial_number__c=============>'+oAssetLineItem.APTS_Is_Primary_L1_Asset__r.APTS_OLI_serial_number__c);
                            }
                            //Unique number for option and parent pha association w contract type change
                            if(oAssetLineItem.Apttus_Config2__OptionId__r.ProductCode!=null &&  oAssetLineItem.Apttus_Config2__ProductId__r.APTS_Vendor_Code__c!=null 
                            && oAssetLineItem.APTS_Contract_Change__c && String.isBlank(oPhysicalAsset.UniqueNumber__c) 
                            && oAssetLineItem.APTS_Is_Primary_L1_Asset__c!=null && oAssetLineItem.APTS_Is_Primary_L1_Asset__r.APTS_OLI_serial_number__c!=null){
                                if(oAssetLineItem.APTS_OLI_serial_number__c!=null){
                                    oPhysicalAsset.UniqueNumber__c = oAssetLineItem.Apttus_Config2__OptionId__r.ProductCode + '_' + oAssetLineItem.Apttus_Config2__ProductId__r.APTS_Vendor_Code__c + oAssetLineItem.APTS_Is_Primary_L1_Asset__r.APTS_OLI_serial_number__c + '_' + oAssetLineItem.APTS_OLI_serial_number__c;
                                }else{
                                    oPhysicalAsset.UniqueNumber__c = oAssetLineItem.Apttus_Config2__OptionId__r.ProductCode + '_' + oAssetLineItem.Apttus_Config2__ProductId__r.APTS_Vendor_Code__c + oAssetLineItem.APTS_Is_Primary_L1_Asset__r.APTS_OLI_serial_number__c;
                                }
                                oPhysicalAsset.ParentPhysicalAsset__c=oAssetLineItem.APTS_Is_Primary_L1_Asset__r.APTS_Terminated_Asset_Line__r.APTS_Terminated_Physical_Asset__c;
                            }
                            //Associating record types for option
                            oPhysicalAsset.RecordTypeId = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get('Option').getRecordTypeId();

                            //Populate WTS coverage related fields
                           /* if(oPhysicalAsset.WTSChangedBy__c!=null && oPhysicalAsset.WTSChangedBy__c.equalsIgnoreCase('JDE Engineer')){
                                oPhysicalAsset.IncludesWTSCoverage__c = true;
                                oPhysicalAsset.WaterfilterCoverage__c = 100;
                            }*/
                            if(!parentLSPDetails.isEmpty() && parentLSPDetails.get(oAssetLineItem.APTS_Is_Primary_L1_Asset__c)!=null){
                                //=========From Option LSP Details==========
                                oPhysicalAsset.Area__c =  parentLSPDetails.get(oAssetLineItem.APTS_Is_Primary_L1_Asset__c).APTS_Area__c;
                                oPhysicalAsset.Floor__c = parentLSPDetails.get(oAssetLineItem.APTS_Is_Primary_L1_Asset__c).APTS_Floor__c;
                                oPhysicalAsset.Building__c = parentLSPDetails.get(oAssetLineItem.APTS_Is_Primary_L1_Asset__c).APTS_Building__c;
                                oPhysicalAsset.CustomerReferenceNumber__c = parentLSPDetails.get(oAssetLineItem.APTS_Is_Primary_L1_Asset__c).APTS_CustomerReference__c;
                                oPhysicalAsset.SmokingArea__c = parentLSPDetails.get(oAssetLineItem.APTS_Is_Primary_L1_Asset__c).APTS_SmokingArea__c;
                                oPhysicalAsset.JDECrockeryVolumeSize__c = parentLSPDetails.get(oAssetLineItem.APTS_Is_Primary_L1_Asset__c).APTS_JDE_crockeryVolumeSize__c;
                            }
                        }
                        if(physicalAssetUpsertMap.get(oAssetLineItem.id)==null){
                            physicalAssetUpsertMap.put(oAssetLineItem.id,oPhysicalAsset);
                        }
                    }
                }
            }
            System.debug('PHA FINAL KARAN physicalAssetUpsertMap================>'+physicalAssetUpsertMap);
            if(!physicalAssetUpsertMap.isEmpty()){
                Database.upsert(physicalAssetUpsertMap.values(),PhysicalAsset__c.Fields.UniqueNumber__c);
            }
            for(Apttus_Config2__AssetLineItem__c oAssetLineItem : refinedQueryList) {
                //Label to store option group indicators trigger pha creation
                PhysicalAsset__c ParentPhA;
                List<String> phaOptionGroupSet = System.Label.APTS_AllowedOptionGroupIndicators.split(',');
                 
                if(oAssetLineItem.APTS_Is_Primary_L1_Line__c ||
                (oAssetLineItem.Apttus_Config2__OptionId__c!=null && phaOptionGroupSet.contains(oAssetLineItem.Apttus_Config2__OptionId__r.APTS_Option_Group_Indicator__c))){
                    oAssetLineItem.APTS_Physical_Asset__c = physicalAssetUpsertMap.get(oAssetLineItem.id).id;
                    if(assetLineItemsUpdateMap.get(oAssetLineItem.id)==null){
                        assetLineItemsUpdateMap.put(oAssetLineItem.id,oAssetLineItem);
                    }
                }
            }
            if(!assetLineItemsUpdateMap.isEmpty()){
                APTS_AssetLineItemTriggerHandler.isSkipAssetlineitemTrigger = true;
                update assetLineItemsUpdateMap.values();
                APTS_AssetLineItemTriggerHandler.isSkipAssetlineitemTrigger = false;
            }
        }
        /*public static Map<String,APTS_Agreement_PO_Details__c> getAgreementPODetails(Set<Id> agreementIdSet) {
            Map<String,APTS_Agreement_PO_Details__c> poMap = new Map<String,APTS_Agreement_PO_Details__c> ();
            for (APTS_Agreement_PO_Details__c poDetails :[SELECT Id,
                 APTS_Agreement__c,
                 APTS_PO_Category__c,
                 APTS_PO_Expiration_Date__c,
                 APTS_PO_Number__c,
                 APTS_PO_Number_Required__c,
                 APTS_PO_Number_Type__c
                 FROM APTS_Agreement_PO_Details__c
                 WHERE APTS_Agreement__c IN :agreementIdSet]) {
                if(poMap.get(poDetails.APTS_Agreement__c+poDetails.APTS_PO_Category__c)==null){
                    poMap.put(poDetails.APTS_Agreement__c+poDetails.APTS_PO_Category__c, poDetails);
                }
            }
            return poMap;
        }*/
        public static void resetValuesToBlank(PhysicalAsset__c oPhysicalAsset){
            oPhysicalAsset.AccountLocation__c=null;
            oPhysicalAsset.ActiveContract__c=false;
            //oPhysicalAsset.Area__c=null;
            oPhysicalAsset.AssetStatus__c=null;
            //oPhysicalAsset.Building__c =null;
            oPhysicalAsset.CallOutChargeCoverage__c=null;
            oPhysicalAsset.City__c=null;
            oPhysicalAsset.Connected__c='No';
            oPhysicalAsset.ConsumptionPrice__c=null;
            oPhysicalAsset.CounterReading__c='No';
            oPhysicalAsset.Country__c=null;
            oPhysicalAsset.CupSize__c=null;
            //oPhysicalAsset.CustomerReferenceNumber__c=null;
            oPhysicalAsset.EndDate__c=null;
            //oPhysicalAsset.Floor__c=null;
            oPhysicalAsset.FullOperatingCoverage__c=null;
            oPhysicalAsset.HouseNumber__c=null;
            oPhysicalAsset.IncludesPreventiveMaintenanceCoverage__c=false;
            oPhysicalAsset.IncludesWTSCoverage__c=false;
            //oPhysicalAsset.JDECrockeryVolumeSize__c=null;
            oPhysicalAsset.LabourChargeCoverage__c=null;
            oPhysicalAsset.MachineCareHours__c=null;
            oPhysicalAsset.Merchant__c=null;
            oPhysicalAsset.OwnedByCustomer__c=false;
            //v7 muting updating logic
            /*oPhysicalAsset.PONumberMachines__c=null;
            oPhysicalAsset.PONumberRequiredMachines__c=null;
            oPhysicalAsset.PONumberRequiredServices__c=null;
            oPhysicalAsset.PONumberServices__c=null;
            oPhysicalAsset.PONumberTypeMachines__c=null;
            oPhysicalAsset.PONumberTypeServices__c=null;*/
            oPhysicalAsset.ParentPhysicalAsset__c=null;
            oPhysicalAsset.PostalCode__c=null;
            oPhysicalAsset.PreventiveMaintenanceCoverage__c=null;
            oPhysicalAsset.PreventiveMaintenanceInterval__c=null;
            oPhysicalAsset.Product__c=null;
            oPhysicalAsset.RefurbishedMachine__c=false;
            oPhysicalAsset.ResponseTimeS15__c=null;
            oPhysicalAsset.ResponseTime__c=null;
            oPhysicalAsset.Routesales__c=false;
            oPhysicalAsset.ShippingCountryISO__c=null;
            //oPhysicalAsset.SmokingArea__c=false;
            oPhysicalAsset.SoldTo__c=null;
            oPhysicalAsset.SparePartCoverage__c=null;
            oPhysicalAsset.StartDate__c=null;
            oPhysicalAsset.Street__c=null;
            oPhysicalAsset.TastePallet__c=null;
            oPhysicalAsset.TypeOfConsumption__c=null;
            oPhysicalAsset.TypeOfContract__c=null;
            oPhysicalAsset.UniqueNumber__c=null;
            oPhysicalAsset.WTSChangedBy__c=null;
            oPhysicalAsset.Warranty__c=null;
            oPhysicalAsset.WaterfilterCoverage__c=null;
            oPhysicalAsset.Machine_Care__c=null;
            oPhysicalAsset.SalesOrganization__c=null;
            oPhysicalAsset.ServiceWindow__c=null;
            //v4-S
            oPhysicalAsset.APTS_AutoRenew__c=false;
            //v4-E
           //oPhysicalAsset.WarrantyStartDate__c=null;
        }
        public static Map<String, String> getassetPHAfieldMapping(){
            Map<String, String> assetPHAfieldMapping = new Map<String, String>();
            
            for(APTS_ABO_ALI_PHA_field_mapping__mdt meta : [SELECT Id, APTS_Asset_line_item_field_API_name__c, APTS_Physical_asset_field_API_name__c FROM APTS_ABO_ALI_PHA_field_mapping__mdt]){
                assetPHAfieldMapping.put(meta.APTS_Physical_asset_field_API_name__c, meta.APTS_Asset_line_item_field_API_name__c);
            }
            return assetPHAfieldMapping;
        }

        public static void mapAssetPHAFields(PhysicalAsset__c phAsset,Apttus_Config2__AssetLineItem__c assetline,Map<String,String> assetPHAfieldMapping){
            for(String physicalAssetField : assetPHAfieldMapping.keySet()){
                if(assetPHAfieldMapping.get(physicalAssetField)!=null){
                    phAsset.put(physicalAssetField, assetline.get(assetPHAfieldMapping.get(physicalAssetField)));
                }
            }
        }
    }