/**
* @author        Marvin Gatchalian
* @date          04.25.2018
* @description   Class used to Execute Flow with bulkified records
* @revision(s)
*/
    
global without sharing class TS_FlowProcessor {
    
    public static Boolean hasException = false;
    public class TS_FlowProcessorException extends Exception {}
    
    /**
    * @author        Marvin Gatchalian
    * @date          04.25.2018           
    * @description   Method used to Execute TS_Fixed_Costs_Bulkify Flow, the selected fields are being used in the said flow.
    * @revision(s)
    */
    public static void executeFixCostFlow(List<Id> workOrderLineItemIDs, Map<Id, SObject> newMapItems) {
        CustomLogging.push('executeFixCostFlow', 'TS_FlowProcessor');

        Id csRtID = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', 'Fixed Costs');
        List<WorkOrderLineItem> woliBulk = new List<WorkOrderLineItem>();
        Set<String> woType = new Set<String>();
        Set<String> salesOrg = new Set<String>();
        List<CountrySetting__c> countrySettingsBulk = new List<CountrySetting__c>();
        Map<Id, WorkOrderLineItem> newWOLIMap =  (Map<Id, WorkOrderLineItem>) newMapItems;

        List<WorkOrderLineItem> woliForFixCost = [SELECT Id, TS_CaseOrigin__c, PhysicalAsset__c, Case__c, WorkOrderId, WorkOrderType__c, Case__r.SalesOrganization__c, 
                                                    Case__r.PhysicalAsset__c, WorkOrder.PriceBook2Id, RecordTypeId,  
                                                    Case__r.ProductId, PricebookEntryId, PricebookEntry.TS_ProductGroup__c, 
                                                    Case__r.PhysicalAsset__r.ActiveWarranty__c, 
                                                    Case__r.Country_Setting_Signature_Record__r.IsLabour__c, 
                                                    PricebookEntry.Product2.Material_group__c, Case__r.TS_Disaster_Recovery_Id__c,
                                                    Case__r.PhysicalAsset__r.LabourChargeCoverage__c, Status, 
                                                    Case__r.PhysicalAsset__r.WaterfilterCoverage__c, ServiceMaterialsLoaded__c,
                                                    Case__r.PhysicalAsset__r.CallOutChargeCoverage__c, 
                                                    Case__r.PhysicalAsset__r.SparePartCoverage__c ,
                                                    Case__r.PhysicalAsset__r.FullOperatingCoverage__c, 
                                                    Case__r.PhysicalAsset__r.PreventiveMaintenanceCoverage__c,
                                                    Case__r.PhysicalAsset__r.AssetStatus__c,
                                                    Case__r.PhysicalAsset__r.EndDate__c,

                                                    PhysicalAsset__r.ActiveWarranty__c,
                                                    PhysicalAsset__r.EndDate__c,
                                                    PhysicalAsset__r.AssetStatus__c,
                                                    PhysicalAsset__r.LabourChargeCoverage__c,
                                                    PhysicalAsset__r.CallOutChargeCoverage__c,
                                                    PhysicalAsset__r.WaterfilterCoverage__c,
                                                    PhysicalAsset__r.SparePartCoverage__c,
                                                    PhysicalAsset__r.FullOperatingCoverage__c,
                                                    PhysicalAsset__r.PreventiveMaintenanceCoverage__c

                                                    FROM WorkOrderLineItem WHERE Id IN :workOrderLineItemIDs];
        
        System.debug ('Marvin +++ woliForFixCost ' + woliForFixCost.size());
        System.debug ('Marvin +++ woliForFixCost ' + woliForFixCost);

        for (WorkOrderLineItem eachWoli :woliForFixCost) {
                        
            //if (eachWoli.status == TS_Constants.WOLI_STATUS_SCHEDULED &&
            WorkOrderLineItem newWOLI = newWOLIMap.get(eachWoli.Id);

            System.debug ('Marvin +++ newWOLI.Status' + newWOLI.Status); 

            if ((newWOLI.Status == TS_Constants.WOLI_STATUS_SCHEDULED 
                 //DOO-5357 Pandian Sundaramoorthy April 8, 2021
               	 || newWoli.Status == TS_Constants.WOLI_STATUS_DISPATCHED
                 || newWoli.Status == TS_Constants.WOLI_STATUS_RECEIVED)
                 //eachWoli.WorkOrderType__c == TS_Constants.CASE_SUBTYPE_CORRECTMAINTAPI &&
                 && eachWoli.ServiceMaterialsLoaded__c == false){
                
                //FIX FOR PHYSICAL ASSET empty in WOLI - Reason: if the field is null, it is not queried in the woliForFixCost. This is checked in the flow.
                /* if(eachWoli.PhysicalAsset__c == null){
                    eachWoli.PhysicalAsset__c = null;
                } */

                woliBulk.add(eachWoli);
                salesOrg.add(eachWoli.Case__r.SalesOrganization__c);
                woType.add(eachWoli.WorkOrderType__c);
            }
        }
        
        countrySettingsBulk = [SELECT Product__c, Country__c, WorkOrderType__c, IsLabour__c, Product__r.Material_group__c
                               FROM CountrySetting__c 
                               WHERE WorkOrderType__c IN: woType 
                               AND Country__c IN: salesOrg 
                               AND Active__c = true 
                               AND RecordTypeId =: csRtID];
                              
        System.debug ('Marvin +++ countrySettingsBulk : ' + countrySettingsBulk); 

        try {  
            if (!woliBulk.isEmpty() && !countrySettingsBulk.isEmpty()) {
                
                /* Map<String, Object> params = new Map<String, Object>();
                params.put('WorkOrderLineItemCollection', woliBulk);
                params.put('CountrySettingsCollection', countrySettingsBulk);
                Flow.Interview.TS_Fixed_Costs_Bulkify fixCostFlow = new Flow.Interview.TS_Fixed_Costs_Bulkify(params);
                fixCostFlow.start();
                
                System.debug('Marvin >>>' + fixCostFlow.testVar); */

                //SERVICE MATERIALS TO INSERT
                List<WorkOrderLineItem> woliServMaterialToInsertList = new List<WorkOrderLineItem>();
                List<WorkOrderLineItem> parentWOLItoUpdateList = new List<WorkOrderLineItem>();

                List<String> supportedStatus = new List<String>{'Activated', 'Pending Activation', 'Pending Cancellation'};

                //GET WOLI SERVICE MATERIALS RECORDTYPE ID
                Id woli_servMaterial = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Register Service Material').getRecordTypeId();

                //GET FIXED COST SETTINGS PER COUNTRY PER WORK ORDER TYPE
                Map<String, Map<String, List<CountrySetting__c>>> csPerCountryPerTypeMap = new Map<String, Map<String, List<CountrySetting__c>>>();
                Set<Id> productIdSet = new Set<Id>();
                Set<String> countrySet = new Set<String>();
                Set<String> countrySetTrim = new Set<String>();
                for(CountrySetting__c cs_var : countrySettingsBulk){
                    
                    if(csPerCountryPerTypeMap.containsKey(cs_var.Country__c)){
                        if(csPerCountryPerTypeMap.get(cs_var.Country__c).containsKey(cs_var.WorkOrderType__c)){
                            csPerCountryPerTypeMap.get(cs_var.Country__c).get(cs_var.WorkOrderType__c).add(cs_var);
                        } else {
                            csPerCountryPerTypeMap.get(cs_var.Country__c).put(cs_var.WorkOrderType__c, new List<CountrySetting__c>{cs_var});
                        }
                    } else {
                        csPerCountryPerTypeMap.put(cs_var.Country__c, new Map<String, List<CountrySetting__c>>{cs_var.WorkOrderType__c => new List<CountrySetting__c>{cs_var}});
                    }

                    productIdSet.add(cs_var.Product__c);
                    countrySet.add(cs_var.Country__c);
                    countrySetTrim.add(cs_var.Country__c.right(4));
                }
                
                System.debug('csPerCountryPerTypeMap ' + csPerCountryPerTypeMap);

                if(!productIdSet.isEmpty() && !countrySet.isEmpty()){

                    //GET PRICEBOOKENTRY ID FOR EACH COUNTRY SETTINGS PRODUCT
                    List<PricebookEntry> pbEntryList = [SELECT Id, IsActive, Product2Id, Pricebook2.Sales_Organization__c FROM PricebookEntry WHERE Product2Id IN: productIdSet AND Pricebook2.Sales_Organization__c IN: countrySet AND IsActive = true];
                    Map<String, PricebookEntry> prodCountryPbeMap = new Map<String, PricebookEntry>();
                    if(!pbEntryList.isEmpty()){
                        for(PricebookEntry pbe_var : pbEntryList){
                           prodCountryPbeMap.put(String.valueOf(pbe_var.Product2Id + pbe_var.Pricebook2.Sales_Organization__c), pbe_var);
                        }
                    }
                    
                    System.debug('prodCountryPbeMap ' + prodCountryPbeMap);

                    //GET MATERIAL PRICING GROUP ID FOR EACH PRODUCT
                    List<APTS_Sales_Org_Data__c> salesOrgDataList = [SELECT Id, APTS_Material_Pricing_Group_ID__c, APTS_Product__c, APTS_Sales_Org_Data_Name__c FROM APTS_Sales_Org_Data__c WHERE APTS_Product__c IN: productIdSet AND APTS_Sales_Org_Data_Name__c IN: countrySetTrim];
                    Map<String, APTS_Sales_Org_Data__c> prodCountrySalesOrgDataMap = new Map<String, APTS_Sales_Org_Data__c>();
                    if(!salesOrgDataList.isEmpty()){
                        for(APTS_Sales_Org_Data__c sod_var : salesOrgDataList){
                            prodCountrySalesOrgDataMap.put(String.valueOf(sod_var.APTS_Product__c + 'SAP_' + sod_var.APTS_Sales_Org_Data_Name__c),sod_var);
                        }
                    }
                    
                    System.debug('prodCountrySalesOrgDataMap ' + prodCountrySalesOrgDataMap);

                    //ITERATE EACH SCHEDULED JOBS & RESPECTIVE COUNTRY SETTINGS
                    for(WorkOrderLineItem woli_var : woliBulk){
                        
                        Boolean hasCountrySettings = false;
                        if(csPerCountryPerTypeMap.containsKey(woli_var.Case__r.SalesOrganization__c)){
                            if(csPerCountryPerTypeMap.get(woli_var.Case__r.SalesOrganization__c).containsKey(woli_var.WorkOrderType__c)) hasCountrySettings = true;
                        }

                        if(!hasCountrySettings) continue;

                        for(CountrySetting__c cs_var : csPerCountryPerTypeMap.get(woli_var.Case__r.SalesOrganization__c).get(woli_var.WorkOrderType__c)){
                            
                            WorkOrderLineItem newServMat = new WorkOrderLineItem();
                            newServMat.Case__c = woli_var.Case__c;
                            newServMat.ParentWorkOrderLineItemId = woli_var.Id;
                            newServMat.RecordTypeId = woli_servMaterial;
                            newServMat.PricebookEntryId = prodCountryPbeMap.get(String.valueOf(cs_var.Product__c + cs_var.Country__c)).Id;
                            newServMat.WorkOrderId = woli_var.WorkOrderId;
                            newServMat.WorkOrderLineItemType__c = 'Service Materials';
                            newServMat.Quantity = 1;
                            newServMat.IsLabour__c = cs_var.IsLabour__c;

                            //CHECK IF THE WOLI IS SALES ORDER OR NO ASSET
                            if(woli_var.TS_CaseOrigin__c == 'Sales Order' || woli_var.PhysicalAsset__c == null){

                                if(woli_var.PhysicalAsset__c == null){
                                    newServMat.Warranty__c = 'None';
                                    newServMat.Discount = 0;
                                }

                            } else {
								
                                //GET MATERIAL PRICING GROUP OF THE PRODUCT TO INSERT FROM COUNTRY SETTING
                                String matGroupId = '';
                                if(prodCountrySalesOrgDataMap.containsKey(cs_var.Product__c + cs_var.Country__c)) matGroupId = prodCountrySalesOrgDataMap.get(cs_var.Product__c + cs_var.Country__c).APTS_Material_Pricing_Group_ID__c;
                                
                                if(woli_var.PhysicalAsset__r.ActiveWarranty__c){
                                   
                                    //CHECK IF PRODUCT IS CHARGEABLE
                                    if(matGroupId == 'SAP_03'){
                                        newServMat.Warranty__c = 'None';
                                        newServMat.Discount = 0;
                                    } else {
                                        newServMat.Warranty__c = 'K1';
                                        newServMat.Discount = 100;
                                    }

                                } else {

                                    //IF MACHINE IS WITHIN/UNDER CONTRACT
                                    if(	woli_var.PhysicalAsset__r.EndDate__c >= Date.today() 
                                       	&& supportedStatus.contains(woli_var.PhysicalAsset__r.AssetStatus__c)
                                      	&& matGroupId != null
                                   		&& matGroupId != ''){
                                        
                                        Boolean always_chargeable = false;

                                        //CALL OUT CHARGE    
                                        if(matGroupId == 'SAP_30'){
                                            if(woli_var.PhysicalAsset__r.CallOutChargeCoverage__c != 0 && woli_var.PhysicalAsset__r.CallOutChargeCoverage__c != null){
                                                newServMat.Warranty__c = 'YR';
                                                newServMat.Discount = woli_var.PhysicalAsset__r.CallOutChargeCoverage__c;    
                                            } else always_chargeable = true;
                                        }

                                        //CONTRACT DEPENDENT / SPARE PART
                                        else if(matGroupId == 'SAP_04'){
                                            if(woli_var.PhysicalAsset__r.SparePartCoverage__c != 0 && woli_var.PhysicalAsset__r.SparePartCoverage__c != null){
                                                newServMat.Warranty__c = 'YR';
                                                newServMat.Discount = woli_var.PhysicalAsset__r.SparePartCoverage__c;
                                            } else always_chargeable = true;
                                        } 

                                        //LABOUR CHARGE
                                        else if(matGroupId == 'SAP_33'){
                                            if(woli_var.PhysicalAsset__r.LabourChargeCoverage__c != 0 && woli_var.PhysicalAsset__r.LabourChargeCoverage__c != null){
                                                newServMat.Warranty__c = 'YR';
                                                newServMat.Discount = woli_var.PhysicalAsset__r.LabourChargeCoverage__c;
                                            } else always_chargeable = true;
                                        }

                                        //WATERFILTER COVERAGE
                                        else if(matGroupId == 'SAP_05'){
                                            if(woli_var.PhysicalAsset__r.WaterfilterCoverage__c != 0 && woli_var.PhysicalAsset__r.WaterfilterCoverage__c != null){
                                                newServMat.Warranty__c = 'YR';
                                                newServMat.Discount = woli_var.PhysicalAsset__r.WaterfilterCoverage__c;
                                            } else always_chargeable = true;
                                        }

                                        //FULL OPERATING COVERAGE
                                        else if(matGroupId == 'SAP_32'){
                                            if(woli_var.PhysicalAsset__r.FullOperatingCoverage__c != 0 && woli_var.PhysicalAsset__r.FullOperatingCoverage__c != null){
                                                newServMat.Warranty__c = 'YR';
                                                newServMat.Discount = woli_var.PhysicalAsset__r.FullOperatingCoverage__c;
                                            } else always_chargeable = true;                                           
                                        }

                                        //PREVENTIVE MAINTENANCE COVERAGE
                                        else if(matGroupId == 'SAP_31'){
                                            if(woli_var.PhysicalAsset__r.PreventiveMaintenanceCoverage__c != 0 && woli_var.PhysicalAsset__r.PreventiveMaintenanceCoverage__c != null){
                                                newServMat.Warranty__c = 'YR';
                                                newServMat.Discount = woli_var.PhysicalAsset__r.PreventiveMaintenanceCoverage__c;
                                            } else always_chargeable = true;                                                
                                        }

                                        //ALWAYS CHARGEABLE
                                        else if(matGroupId == 'SAP_03') always_chargeable = true;
                                        else continue;

                                        if(always_chargeable){
                                            newServMat.Warranty__c = 'None';
                                            newServMat.Discount = 0;
                                        }

                                    } else {
                                        newServMat.Warranty__c = 'None';
                                        newServMat.Discount = 0;
                                        
                                        //IF NO SALES ORG DATA
                                        //DOO-5285 XEN REYES Feb 1, 2021
                                        if(matGroupId == null || matGroupId == '') newServMat.AdditionalDetails__c = 'No billing information due to no Sales Org data found.';
                                    }
                                }
                            }

                            woliServMaterialToInsertList.add(newServMat);

                        }

                        //UPDATE THE PARENT WOLI
                        
                        WorkOrderLineItem woliTriggerInstanceVar = newWOLIMap.get(woli_var.Id);
                        
                        /*
                        //Warranty is Active
                        if(woli_var.PhysicalAsset__r.ActiveWarranty__c){
                            woliTriggerInstanceVar.Discount = 100;
                            woliTriggerInstanceVar.Warranty__c = 'K1';
                        } 
                        
                        //Only Contract is Active
                        else if(woli_var.PhysicalAsset__r.EndDate__c >= Date.today() && supportedStatus.contains(woli_var.PhysicalAsset__r.AssetStatus__c)){
                            woliTriggerInstanceVar.Discount = woli_var.PhysicalAsset__r.LabourChargeCoverage__c;
                            woliTriggerInstanceVar.Warranty__c = 'YR';
                        } 

                        else {
                            woliTriggerInstanceVar.Discount = 0;
                            woliTriggerInstanceVar.Warranty__c = 'None';
                        }
						*/
                        
                        woliTriggerInstanceVar.ServiceMaterialsLoaded__c = true;
                        //parentWOLItoUpdateList.add(woli_var);
                    }

                    if(!woliServMaterialToInsertList.isEmpty()){
                        WorkOrderLineItemTriggerHandler.FIXED_COST_DONE = true;
                        WorkOrderLineItemTriggerHandler.isNotBatchExecution = false;
                        WorkOrderLineItemTriggerHandler.IS_OPERATING_TASK = true;
                        insert woliServMaterialToInsertList;
                    }

                    /* if(!parentWOLItoUpdateList.isEmpty()){
                        update parentWOLItoUpdateList;
                    }*/
                }
            }
            
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_FlowProcessorException('Force to throw an exception');
            }
            
        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        
        CustomLogging.pop();
        
    }

    /*
    * @author        Abram Vixen Reyes
    * @date          August 27, 2020
    * @description   DOO - 4743 Process builder to trigger: Fixed Costs and Warranty
    * @revision(s)   
    */
    public static void executeWarrantyFlow(Map<Id, WorkOrderLineItem> extWoliNewMap, List<WorkOrderLineItem> toProcess, Set<Id> productIdSet, Set<String> countrySetTrim, Map<Id,sObject> oldMapItems) {
        CustomLogging.push('executeWarrantyFlow', 'TS_FlowProcessor');

        try{
            
            //DOO-5285 XEN REYES Feb 1, 2021
            List<String> supportedStatus = new List<String>{'Activated', 'Pending Activation', 'Pending Cancellation'};
                
            Map<String, APTS_Sales_Org_Data__c> prodCountrySalesOrgDataMap = new Map<String, APTS_Sales_Org_Data__c>();
            if(!productIdSet.isEmpty() && !countrySetTrim.isEmpty()){
                
                //GET MATERIAL PRICING GROUP ID FOR EACH PRODUCT
                List<APTS_Sales_Org_Data__c> salesOrgDataList = [SELECT Id, APTS_Material_Pricing_Group_ID__c, APTS_Product__c, APTS_Sales_Org_Data_Name__c FROM APTS_Sales_Org_Data__c WHERE APTS_Product__c IN: productIdSet AND APTS_Sales_Org_Data_Name__c IN: countrySetTrim];
                
                System.debug('salesOrgDataList: ' + salesOrgDataList);
                
                if(!salesOrgDataList.isEmpty()){
                    for(APTS_Sales_Org_Data__c sod_var : salesOrgDataList){
                        prodCountrySalesOrgDataMap.put(String.valueOf(sod_var.APTS_Product__c + 'SAP_' + sod_var.APTS_Sales_Org_Data_Name__c),sod_var);
                    }
                }
            }

            List<WorkOrderLineItem> woliToUpdate = new List<WorkOrderLineItem>();
            Map<Id,WorkOrderLineItem> oldWoliMap = new Map<Id,WorkOrderLineItem>();

            //GET PREVIOUS VALUES OF PARTS WHEN PARTS UPDATE
            oldWoliMap = (Map<Id,WorkOrderLineItem>) oldMapItems;

            for(WorkOrderLineItem newWoli : (List<WorkOrderLineItem>) toProcess){                
                WorkOrderLineItem extWOLI = new WorkOrderLineItem();
                
                Boolean notChangeToZ1 = false;
                extWOLI = extWoliNewMap.containsKey(newWoli.Id) ? extWoliNewMap.get(newWoli.Id) : new WorkOrderLineItem();
                if(newWoli.Warranty__c != oldWoliMap.get(newWoli.Id).Warranty__c && newWoli.Warranty__c != TS_Constants.WARRANTY_Z1){
                    //Z1 -> Coulance (Goodwill) && C1 -> To be Paid by Customer
                    notChangeToZ1 = true;
                }
                
                //Part is Completed (Non-Coulance)
                if( notChangeToZ1 || newWoli.Warranty__c == TS_Constants.WARRANTY_DEFAULT || newWoli.Warranty__c == TS_Constants.WARRANTY_C1){
                    
                    Boolean always_chargeable = false;
                    if(	extWOLI.ParentWorkOrderLineItemId != null
                        && extWOLI.ParentWorkOrderLineItem.PhysicalAsset__c != null
                       	&& extWOLI.ParentWorkOrderLineItem.PhysicalAsset__r.AssetStatus__c != 'Cancelled'){
                       
                       	/* && extWOLI.ParentWorkOrderLineItem.Case__c != null
                        && extWOLI.ParentWorkOrderLineItem.Case__r.PhysicalAsset__c != null
                        && extWOLI.ParentWorkOrderLineItem.Case__r.PhysicalAsset__r.AssetStatus__c != 'Cancelled'){ */
                            
                        //GET MATERIAL PRICING GROUP OF THE PRODUCT TO INSERT FROM COUNTRY SETTING
                        String matGroupId = '';
                        if(prodCountrySalesOrgDataMap.containsKey(newWOLI.Product2Id + extWOLI.WorkOrder.SalesOrganization__c)) {
                            matGroupId = prodCountrySalesOrgDataMap.get(newWOLI.Product2Id + extWOLI.WorkOrder.SalesOrganization__c).APTS_Material_Pricing_Group_ID__c;
                        }

                        if(matGroupId == 'SAP_03'){
                            always_chargeable = true;
                        } else if (newWoli.Warranty__c == TS_Constants.WARRANTY_C1){
                            newWoli.Warranty__c = 'C1';
                            newWoli.Discount = 0;
                        } else if (newWoli.Warranty__c == TS_Constants.WARRANTY_Z1){
                            newWoli.Warranty__c = 'Z1';
                            newWoli.Discount = 100;
                        } else{
                            
                            //CHECK FOR MACHINE WARRANTY
                            if(extWOLI.ParentWorkOrderLineItem.PhysicalAsset__r.ActiveWarranty__c){
                                newWoli.Warranty__c = 'K1';
                                newWoli.Discount = 100;
                            
                            //CHECK FOR CONTRACT DISCOUNTS
                            } else {

                                //IF MACHINE IS WITHIN/UNDER CONTRACT
                                //DOO-5285 XEN REYES Feb 1, 2021
                                if(	extWOLI.ParentWorkOrderLineItem.PhysicalAsset__r.EndDate__c >= Date.today() 
                                   	&& supportedStatus.contains(extWOLI.ParentWorkOrderLineItem.PhysicalAsset__r.AssetStatus__c)
                                  	&& matGroupId != null
                                   	&& matGroupId != ''){
                                  
                                    //CALL OUT CHARGE    
                                    if(matGroupId == 'SAP_30'){
                                        if(extWOLI.ParentWorkOrderLineItem.PhysicalAsset__r.CallOutChargeCoverage__c != 0 && extWOLI.ParentWorkOrderLineItem.PhysicalAsset__r.CallOutChargeCoverage__c != null){
                                            newWoli.Warranty__c = 'YR';
                                            newWoli.Discount = extWOLI.ParentWorkOrderLineItem.PhysicalAsset__r.CallOutChargeCoverage__c;    
                                        } else always_chargeable = true;
                                    }

                                    //CONTRACT DEPENDENT / SPARE PART
                                    else if(matGroupId == 'SAP_04'){
                                        if(extWOLI.ParentWorkOrderLineItem.PhysicalAsset__r.SparePartCoverage__c != 0 && extWOLI.ParentWorkOrderLineItem.PhysicalAsset__r.SparePartCoverage__c != null){
                                            newWoli.Warranty__c = 'YR';
                                            newWoli.Discount = extWOLI.ParentWorkOrderLineItem.PhysicalAsset__r.SparePartCoverage__c;
                                        } else always_chargeable = true;
                                    }
                                    
                                    //LABOUR CHARGE
                                    //DOO-5285 XEN REYES Feb 1, 2021
                                    else if(matGroupId == 'SAP_33'){
                                        if(extWOLI.ParentWorkOrderLineItem.PhysicalAsset__r.LabourChargeCoverage__c != 0 && extWOLI.ParentWorkOrderLineItem.PhysicalAsset__r.LabourChargeCoverage__c != null){
                                            newWoli.Warranty__c = 'YR';
                                            newWoli.Discount = extWOLI.ParentWorkOrderLineItem.PhysicalAsset__r.LabourChargeCoverage__c;
                                        } else always_chargeable = true;
                                    }

                                    //WATERFILTER COVERAGE
                                    else if(matGroupId == 'SAP_05'){
                                        if(extWOLI.ParentWorkOrderLineItem.PhysicalAsset__r.WaterfilterCoverage__c != 0 && extWOLI.ParentWorkOrderLineItem.PhysicalAsset__r.WaterfilterCoverage__c != null){
                                            newWoli.Warranty__c = 'YR';
                                            newWoli.Discount = extWOLI.ParentWorkOrderLineItem.PhysicalAsset__r.WaterfilterCoverage__c;
                                        } else always_chargeable = true;
                                    }

                                    //FULL OPERATING COVERAGE
                                    else if(matGroupId == 'SAP_32'){
                                        if(extWOLI.ParentWorkOrderLineItem.PhysicalAsset__r.FullOperatingCoverage__c != 0 && extWOLI.ParentWorkOrderLineItem.PhysicalAsset__r.FullOperatingCoverage__c != null){
                                            newWoli.Warranty__c = 'YR';
                                            newWoli.Discount = extWOLI.ParentWorkOrderLineItem.PhysicalAsset__r.FullOperatingCoverage__c;
                                        } else always_chargeable = true;                                           
                                    }

                                    //PREVENTIVE MAINTENANCE COVERAGE
                                    else if(matGroupId == 'SAP_31'){
                                        if(extWOLI.ParentWorkOrderLineItem.PhysicalAsset__r.PreventiveMaintenanceCoverage__c != 0 && extWOLI.ParentWorkOrderLineItem.PhysicalAsset__r.PreventiveMaintenanceCoverage__c != null){
                                            newWoli.Warranty__c = 'YR';
                                            newWoli.Discount = extWOLI.ParentWorkOrderLineItem.PhysicalAsset__r.PreventiveMaintenanceCoverage__c;
                                        } else always_chargeable = true;                                                
                                    }
                                }
                                
                                //DOO-5116 Xen Reyes 4/1/2021
                                else {
                                    newWoli.Warranty__c = 'None';
                                    newWoli.Discount = 0;
                                    
                                    //IF NO SALES ORG DATA
                                    //DOO-5285 XEN REYES Feb 1, 2021
                                    if(matGroupId == null || matGroupId == '') newWoli.AdditionalDetails__c = 'No billing information due to no Sales Org data found.';
                                }

                            }
                        }
                        
                    } else always_chargeable = true;

                    if(always_chargeable){
                        newWoli.Warranty__c = 'None';
                        newWoli.Discount = 0;
                    }
                }

                //Part is Completed (Coulance)
                else if(newWoli.Warranty__c == TS_Constants.WARRANTY_Z1){
                    newWoli.Discount = 100;
                }
            }
            
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_FlowProcessorException('Force to throw an exception');
            }
            
        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }

        CustomLogging.pop();
    }
    
}