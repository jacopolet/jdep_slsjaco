public without sharing class WorkOrderTriggerHandler implements ITriggerHandler{
    
    public static Boolean isTriggerDisabled = true;
    private static Map<Id, WorkOrder> extWoNewMap = null;
    public static Boolean hasException = false;
    public class WorkOrderTriggerHandlerException extends Exception {}
    
    //Karen Hung 19/1/2021 DOO-5166
    public static Map<Id,TS_Feature_Flag__mdt> featureFlags =  new Map<Id,TS_Feature_Flag__mdt>([SELECT Id, QualifiedApiName, Enable__c FROM TS_Feature_Flag__mdt WHERE QualifiedApiName != null]);
    public static Boolean surveySettingEnabled = false;
	public static Boolean provideAccessEnabled = false;
    public static Boolean operatingBucketEnabled = false;
    
    public void BeforeInsert(List<SObject> newItems) {
        if(TS_UtilityClass.isSObjectAccessible(new String[]{'Case'}) || TS_UtilityClass.isSObjectAccessible(new String[]{'PhysicalAsset__c'}))
            validateOneOrderOnly(newItems);// Chi: potential overlaping with counter reading and operating task

        System.debug('XEN 9/7 ' + newItems);
        createWOfromPA(newItems); // Francis Allen Alindogan 03/19/2020 DOO-4256
        populateCurrencyCode(newItems); // 02.10.2018 Karen Hung
    }
    
    public void BeforeUpdate(List<SObject> newList, Map<Id, SObject> newMapItems, List<SObject> oldList, Map<Id, SObject> oldMapItems) {  
        
        
    }
    
    public void BeforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems){
        
    }
    
    public void AfterInsert(List<SObject> newList, Map<Id, SObject> newMapItems){
        if(!featureFlags.isEmpty()){
            for(TS_Feature_Flag__mdt flag : featureFlags.values()){
                if(flag.Enable__c && !Test.isRunningTest()){
                    if(flag.QualifiedApiName == 'DOO_5166_Indicate_Survey') surveySettingEnabled = true;
                    if(flag.QualifiedApiName == 'DOO_5269_Operating_Task_Bucket') operatingBucketEnabled = true;                        
                }                
            }
        }
        if ((extWoNewMap == null && newMapItems != null) || !extWoNewMap.keySet().containsAll(newMapItems.keySet())) {
            extWoNewMap = getExtWoNewMap(newMapItems.keySet());
        }
        createTask(newList);
        calculateLSPDate(newList); //DOO - 4749 08.06.2020 Francis Allen Alindogan
        
    }
    
    public void AfterUpdate(List<SObject> newList , Map<Id, SObject> newMapItems, List<SObject> oldList, Map<Id, SObject> oldMapItems){
        List<WorkOrder> newWorkOrders = (List<WorkOrder>) newList;
        Map<Id, WorkOrder> oldMap = (Map<Id, WorkOrder>) oldMapItems;
        Map<Id, WorkOrder> newMap = (Map<Id, WorkOrder>) newMapItems;

        //Karen Hung
        updateRelatedItems(newWorkOrders, oldMap, newMap);     
        calculateLSPDate(newList); //DOO - 4749 08.06.2020 Francis Allen Alindogan
        if(!featureFlags.isEmpty()){
            for(TS_Feature_Flag__mdt flag : featureFlags.values()){
                if(flag.Enable__c && !Test.isRunningTest()){                       
                    if(flag.QualifiedApiName == 'DOO_5307_Reinitiate_engineer_access'){
                        provideAccessEnabled = true;
                    }    
                }                
            }
        }
        if(provideAccessEnabled)reInitiateAccess(newWorkOrders,oldMap);
        /* Commented out by - Marvin Gatchalian       
        /* The logic below is old implementation of LSP Dates computation, it has been moved to Process Builder.  
        /* Ref docs: KTS-393, KTS-246, KTS-386, KTS-1414 - Confirmed by Adrian
        /* Do not re-enable this as the SOQL getCountrySettings and coollectWorkOrderDetails 
        /* are being fired every time this trigger is being called.
        /* Also, each method has been removed. Please remove this entire comment if there is new logic to be placed here.
        /* This is just for reference or tracking.
        
        map<string,list<CountrySetting__c>> map_SalesOrgCountrySetting= new map<string,list<CountrySetting__c>>();
        if(map_SalesOrgCountrySetting.isEmpty())
            map_SalesOrgCountrySetting=getCountrySettings();
        
        list<WorkOrder> WorkOrders= coollectWorkOrderDetails(newList);
        LSPDelDateForNewAndReplace(WorkOrders,oldMapItems,map_SalesOrgCountrySetting);
        LSPDelDateForAddOn(WorkOrders,oldMapItems,map_SalesOrgCountrySetting);
        LSPPickUpDate(WorkOrders,oldMapItems,map_SalesOrgCountrySetting); 
        CalculateScheduleDate(WorkOrders,oldMapItems,map_SalesOrgCountrySetting);
        */
    }
    
    public void AfterDelete(List<SObject> oldList, Map<Id, SObject> oldMapItems){
        
    }
    
    public void AfterUndelete(List<SObject> newList, Map<Id, SObject> newMapItems){
        
    }
    
    public Boolean IsDisabled() {
        if (TriggerSettings__c.getInstance().WorkOrderTrigger__c) {
            return false;
        } else {
            return isTriggerDisabled;
        }
    }
    
    
    //XEN REYES 12.15.2017
    public void validateOneOrderOnly(List<SObject> woList){
        CustomLogging.push('validateOneOrderOnly', 'WorkOrderTriggerHandler');

        Set<Id> caseIdSet = new Set<Id>();
        Map<Id, Case> caseMap = new Map<Id, Case>();
        Map<Id, Integer> caseIdWOCountMap = new Map<Id, Integer>();

        for(WorkOrder w : (List<WorkOrder>) woList){
            //updated by Archi to avoid unnecessary execution by counter reading and operating task that dont have case.
            if (!(w.WorkOrderType__c == TS_Constants.WO_TYPE_S20_MACHINECARE || w.WorkOrderType__c == TS_Constants.WO_TYPE_S21_COUNTERREADING || w.WorkOrderType__c == TS_Constants.WO_TYPE_S22_COUNTERREADINGFUP )) {
                caseIdSet.add(w.CaseId);    
            }
            
        }

        if(caseIdSet.size() != 0){
            caseMap = new Map<Id, Case>([SELECT Id, CreatedOrderedManually__c, Work_Order_Count__c 
                                         FROM Case WHERE Id IN:caseIdSet]);

            if(caseMap.size() != 0){
                for(WorkOrder w : (List<WorkOrder>) woList){
                    if(caseMap.get(w.CaseId).Work_Order_Count__c > 0){
                        w.addError('You cannot convert the case twice.');
                    }
                }
            }
        }
        CustomLogging.pop();
    }
    
    //Karen Hung 04.10.2018 populate WO's currency iso code based on currency code mappings in country setting
    public void populateCurrencyCode(List<SObject> woList){
        CustomLogging.push('populateCurrencyCode', 'WorkOrderTriggerHandler');
        Map<String,String> countryCurrencyMap = new Map<String,String>();
        String recTypeId = Schema.SObjectType.CountrySetting__c.getRecordTypeInfosByName().get(TS_Constants.TS_COUNTRYSETTING_RECORDTYPE_CURRENCYCODE).getRecordTypeId();
        List<CountrySetting__c> coSettingList = [SELECT Id, Active__c, Country__c, CurrencyIsoCode FROM CountrySetting__c WHERE Active__c = true AND RecordTypeId =:recTypeId];
        if(!coSettingList.isEmpty()){
            for(CountrySetting__c cs : coSettingList){
                countryCurrencyMap.put(cs.Country__c, cs.CurrencyIsoCode);
            }
        }
       	//populate the WO's
        for(WorkOrder wo : (List<WorkOrder>) woList){
            if(wo.SalesOrganization__c !=null && countryCurrencyMap.containsKey(wo.SalesOrganization__c)){
            	wo.CurrencyIsoCode =  countryCurrencyMap.get(wo.SalesOrganization__c);   
            }
        }
        CustomLogging.pop();        
    }

    /**
     * Karen Hung 28.02.2020
     * Method to update actual start and end dates of related wolis of operating route work orders; put muting in creation of iLog for this update
     */
    public void updateRelatedItems(List<WorkOrder> newOrders, Map<Id, WorkOrder> oldMapItems, Map<Id, WorkOrder> newMapItems){
        CustomLogging.push('updateRelatedItems', 'WorkOrderTriggerHandler');
        try{

            Set<String> woIds = new Set<String>();
      
            Id routetypeId =  TS_UtilityClass.getRecordTypeIdByName('WorkOrder', 'Operating (Route) Work Order');

            //get operating route workorders updated to dispatched
            for(WorkOrder wo : newOrders){
                if(oldMapItems.get(wo.Id).Status != newMapItems.get(wo.Id).Status && wo.Status == 'Dispatched' && wo.RecordtypeId == routeTypeId && wo.StartDate__c != null){
                    woIds.add(wo.Id);   
                }
            }

            Map<Id, WorkOrderLineItem> wolitoUpdate = new Map<Id, WorkOrderLineItem>([SELECT Id, StartDate__c, EndDate__c, WorkOrder.StartDate__c, WorkOrder.EndDate__c 
                                                                                     FROM WorkOrderLineItem 
                                                                                     WHERE WorkOrderId IN :woIds 
                                                                                     AND Status NOT IN ('Completed','Canceled')]);
            
            //update start and end dates of open related records of dispatched orders
            for(WorkOrderLineItem wolis : wolitoUpdate.values()){
                wolis.StartDate__c = wolis.WorkOrder.StartDate__c;
                wolis.EndDate__c = wolis.WorkOrder.EndDate__c;
            }

            if(!wolitoUpdate.values().isEmpty()){
                //mute integration log creation for this update
                WorkOrderLineItemTriggerHandler.isRouteOperating = true;
                WorkOrderLineItemTriggerHandler.LARGE_INSERT_MUTE = true;

                //update woli's
                database.update(wolitoUpdate.values());
            }

            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new WorkOrderTriggerHandlerException('Force to throw an exception');
            }

        }catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
        }
        CustomLogging.pop();     
    }

    /*
    * @author        Francis Allen Alindogan
    * @date          March 19, 2020
    * @description   Method to create Machine Care and Counter Reading WO  DOO-4256 DOO-4300
    * @revision(s)  
    */ 
    private void createWOfromPA(List<SObject> woList){
        CustomLogging.push('createWOfromPA', 'WorkOrderTriggerHandler');
        String CONST_WORKORDER_OP_RT = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('Operating (Route) Work Order').getRecordTypeId();
        String CONST_WORKORDER_OP_CR = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('Counter Reading').getRecordTypeId();
        String CONST_WORKORDER_OP_TYPE = TS_Constants.WO_TYPE_S20_MACHINECARE;
        String CONST_WORKORDER_CR_TYPE = TS_Constants.WO_TYPE_S22_COUNTERREADINGFUP;
        Set<Id> productSet = new Set<Id>();
        Set<Id> phyAssetSet = new Set<Id>();
        Set<String> salesOrganizationSet = new Set<string>();
        Map<Id,PhysicalAsset__c> phyAssetMap = new Map<Id,PhysicalAsset__c>();        
        List<PhysicalAsset__c> phyAssetList = new List<PhysicalAsset__c>();
        Map<String, String> countrySAPCodeMap = new Map<String, String>();
        Map<String, String> queueNameIdMap = new Map<String, String>();
        Map<Id, Route_Line_Item__c> paRouteMap = new Map<Id,Route_Line_Item__c>();
        
        countrySAPCodeMap = TS_UtilityClass.countrySAPCodeUtility();
        queueNameIdMap = TS_UtilityClass.queueNameIdMapUtility();

        //CHECK IF THERE ARE WORKORDERS TO BE PROCESSED
        for(WorkOrder workOrder : (List<WorkOrder>) woList){
            if(workOrder.Task_Activity_Type__c != null && 
               workOrder.OP_Physical_Asset__c != null
               ){
                phyAssetSet.add(workOrder.OP_Physical_Asset__c);
            }
        }            
     
        if(!phyAssetSet.isEmpty()){
            //GET ALL PHYSICAL ASSET DETAILS
            for(PhysicalAsset__c pa : [SELECT
                                        Id,
                                        AccountLocation__c,
                                        AccountLocation__r.Main_Service_Contact__c,
                                        AccountLocation__r.Apttus_Config2__AccountId__c,
                                        AccountLocation__r.SAP_Customer_ID__c,
                                        SalesOrganization__c,
                                        Building__c,
                                        Floor__c,
                                        LastPreventiveMaintenanceDate__c,
                                        LastWTSDate__c,
                                        Machine_Care__c,
                                        OP_PCB_Changed__c,
                                        OP_PreferredOperator__c,
                                        Product__c,
                                        PostalCode__c,
                                        Street__c                             
                                      FROM PhysicalAsset__c 
                                      WHERE Id IN: phyAssetSet
                                      AND SalesOrganization__c != null
                                      AND AccountLocation__c != null
                                      ]) {
                    phyAssetMap.put(pa.Id, pa);
            }

            //GET ALL ROUTE, ROUTELINEITEM DETAILS FOR MACHINE CARE
            for(Route_Line_Item__c rli : [SELECT Id, 
                                            RouteId__c, 
                                            RouteId__r.Required_Operator__c, 
                                            RouteId__r.Preferred_Operator__c, 
                                            RouteId__r.Name, 
                                            RouteId__r.Unique_Route_Number__c, 
                                            PhysicalAssetId__c 
                                            FROM Route_Line_Item__c 
                                            WHERE PhysicalAssetId__c IN :phyAssetSet
                                            AND RouteId__r.Unique_Route_Number__c != null
                                            AND RouteId__r.Name != null
                                            ]){
                paRouteMap.put(rli.PhysicalAssetId__c,rli);
            }

            for(WorkOrder workOrder : (List<WorkOrder>) woList){
                PhysicalAsset__c pa = phyAssetMap.get(workOrder.OP_Physical_Asset__c);

                if(workOrder.Task_Activity_Type__c != null){

                    if(workOrder.WorkOrderType__c == CONST_WORKORDER_OP_TYPE){
                        workOrder.RecordTypeId = CONST_WORKORDER_OP_RT;
                    }
                    if(workOrder.WorkOrderType__c == CONST_WORKORDER_CR_TYPE){
                        workOrder.RecordTypeId = CONST_WORKORDER_OP_CR;      
                    }

                    if(paRouteMap.containsKey(pa.Id)){
                        //ASSIGN REQUIRED OPERATOR IF NULL, ASSIGN PREFERRED OPERATOR
                        workOrder.Required_Operator__c = paRouteMap.get(pa.Id).RouteId__r.Required_Operator__c != null ? paRouteMap.get(pa.Id).RouteId__r.Required_Operator__c : null; 
                        if(workOrder.Required_Operator__c == null){
                            workOrder.Preferred_Operator__c = paRouteMap.get(pa.Id).RouteId__r.Preferred_Operator__c != null ? paRouteMap.get(pa.Id).RouteId__r.Preferred_Operator__c : null; 
                        }
                        workOrder.Route_Number__c = paRouteMap.get(pa.Id).RouteId__r.Unique_Route_Number__c;
                        workOrder.Route_Name__c = paRouteMap.get(pa.Id).RouteId__r.Name;
                    }

                    if(countrySAPCodeMap.containsKey(pa.SalesOrganization__c)){
                        if(queueNameIdMap.containsKey(countrySAPCodeMap.get(pa.SalesOrganization__c))){
                            workOrder.OwnerId = queueNameIdMap.get(countrySAPCodeMap.get(pa.SalesOrganization__c)) != null ? queueNameIdMap.get(countrySAPCodeMap.get(pa.SalesOrganization__c)) : UserInfo.getUserId();
                        } 
                    }

                    workOrder.AccountId = pa.AccountLocation__r.Apttus_Config2__AccountId__c != null ? pa.AccountLocation__r.Apttus_Config2__AccountId__c : null;
                    workOrder.Main_Service_Contact__c = pa.AccountLocation__r.Main_Service_Contact__c != null ? pa.AccountLocation__r.Main_Service_Contact__c : null;
                    workOrder.SalesOrganization__c = pa.SalesOrganization__c;
                    workOrder.Status = workOrder.Third_Party__c ? TS_Constants.WOLI_STATUS_SCHEDULED : TS_Constants.TS_Status_Open; //Karen Hung 26/2/2021 DOO-5308 
                    
                    productSet.add(pa.Product__c);                
                    salesOrganizationSet.add(pa.SalesOrganization__c);
                }  
            }                                          

            //GET PRICEBOOK ENTRY
            Map<String,PricebookEntry> pBMap = new Map<String,PricebookEntry>();
            Map<Id,Id> phyAssetRouteMap = getPhyAssetRouteMap(phyAssetSet);
            if (!(productSet.isEmpty() || salesOrganizationSet.isEmpty())) {
                for (PricebookEntry pbe : [SELECT Id, Product2Id, Pricebook2Id, Sales_Organization__c, MTTO_FO_Cups_Bucket__c, MTTO_FO_Large_Bucket__c, MTTO_FO_Small_Bucket__c, MTTO_MCO_Bottles_Bucket__c, 
                        MTTO_MCO_Descaling_Bucket__c, MTTO_MCO_Ingredients_Bucket__c, MTTO_MCO_Large_Bucket__c, MTTO_MCO_PM_Bucket__c, MTTO_MCO_Waterfilter_Bucket__c
                        FROM PricebookEntry
                        WHERE Product2Id IN: productSet AND 
                        Sales_Organization__c IN: salesOrganizationSet AND
                        isActive = true
                        ORDER BY Sales_Organization__c ASC
                    ]) {
                    String pbeMapKey = String.valueOf(pbe.Product2Id) + pbe.Sales_Organization__c;
                    pBMap.put(pbeMapKey, pbe);
                }  
            }

            //ASSIGN PRICEBOOK AND ROUTE      
            for(WorkOrder workOrder : (List<WorkOrder>) woList){
                PhysicalAsset__c pa = phyAssetMap.get(workOrder.OP_Physical_Asset__c);
                if( pa.Product__c != null && 
                    pa.SalesOrganization__c != null){
                        String priceBookKey = pa.Product__c + pa.SalesOrganization__c;
                        workOrder.Pricebook2Id = pBMap.get(priceBookKey) != null ? pBMap.get(priceBookKey).Pricebook2Id : null; 
                }
            }        
        }

    }
    
     /*
    * @author        Francis Allen Alindogan
    * @date          March 19, 2020
    * @description   Method to create Machine Care and Counter Reading Tasks DOO-4256
    * @revision(s)   
    */
    private void createTask(List<WorkOrder> newWOList){
        CustomLogging.push('createTask', 'WorkOrderTriggerHandler');
        String CONST_WOLI_OP_RT = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Operating Task').getRecordTypeId();
        String CONST_WOLI_CR_RT = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Counter Reading Task').getRecordTypeId();
        String CONST_CS_BH = Schema.SObjectType.CountrySetting__c.getRecordTypeInfosByName().get('Country Default Business Hours').getRecordTypeId();
        String CONST_WORKORDER_OP_TYPE = TS_Constants.WO_TYPE_S20_MACHINECARE;
        String CONST_WORKORDER_CR_TYPE = TS_Constants.WO_TYPE_S22_COUNTERREADINGFUP; 
        String CONST_COUNTER_OPERATING = 'CounterOperating';
        String CONST_Large = 'Large';
        String newOpSalesOrg = Label.TS_New_Operating_SalesOrg;
        String oldOpSalesOrg = Label.TS_Old_Operating_SalesOrg;    
        List<WorkOrder> forUpdateWOList = new List<WorkOrder>();
        List<CountrySetting__c> bhList = new List<CountrySetting__c>();
        Set<String> salesOrganizationSet = new Set<String>();
        Set<String> productSet = new Set<String>();
        Map<String,PricebookEntry> pBMap = new Map<String,PricebookEntry>();
        Map<String,DateTime> bhMap = null;
        Id CONST_CS_CS = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', Label.TS_OperatingTaskRecordType);
        
        Map<String, Set<String>> surveySettingMap = new Map<String, Set<String>>();
        if(surveySettingEnabled)  surveySettingMap = getSurveySetting();
        
        //CHECK IF THERE ARE WORKORDERS TO BE PROCESSED
        for(WorkOrder workOrder : newWOList){
            if(workOrder.Task_Activity_Type__c != null && 
               workOrder.OP_Physical_Asset__c != null
               ){
                forUpdateWOList.add(workOrder);
                salesOrganizationSet.add(workOrder.SalesOrganization__c);
                productSet.add(workOrder.Pricebook2Id);      
            }
        }   
        
        if(!forUpdateWOList.isEmpty()){

            //MUTE
            WorkOrderLineItemTriggerHandler.IS_OPERATING_TASK = true;

            //GET COUNTRY SETTINGS
            Map<String,CountrySetting__c> csMap = new Map<String,CountrySetting__c>();
            for(CountrySetting__c cs : [SELECT Id, 
                                        Country__c, DefaultStartTime__c, DefaultEndTime__c, NumberDayToLookup__c, Business_Hours__r.Id, 
                                        Business_Hours__c, 
                                        RecordTypeId
                                        FROM CountrySetting__c
                                        WHERE Country__c IN :salesOrganizationSet
                                        And Active__c = TRUE
                                        And (RecordTypeId =:CONST_CS_CS OR RecordTypeId =: CONST_CS_BH)
                                        ]){
                String key = cs.Country__c + String.valueOf(cs.RecordTypeId);
                csMap.put(key, cs);

                //ADD TO BUSINESS HOURS LIST
                if(cs.RecordTypeId == CONST_CS_BH){
                    bhList.add(cs);
                }
            }

            //GET PRICEBOOK
            if (!(productSet.isEmpty() && salesOrganizationSet.isEmpty())) {
                for (PricebookEntry pbe: [SELECT Id, Product2Id, Pricebook2Id, Sales_Organization__c,MTTO_FO_Cups_Bucket__c, MTTO_FO_Large_Bucket__c, MTTO_FO_Small_Bucket__c, MTTO_MCO_Bottles_Bucket__c, 
                        MTTO_MCO_Descaling_Bucket__c, MTTO_MCO_Ingredients_Bucket__c, MTTO_MCO_Large_Bucket__c, MTTO_MCO_PM_Bucket__c, MTTO_MCO_Waterfilter_Bucket__c
                        FROM PricebookEntry
                        WHERE Pricebook2Id IN: productSet AND 
                        Sales_Organization__c IN: salesOrganizationSet AND
                        isActive = true
                        ORDER BY Sales_Organization__c ASC
                    ]) {
                    String pbeMapKey = String.valueOf(pbe.Product2Id) + pbe.Sales_Organization__c;
                    pBMap.put(pbeMapKey, pbe);
                }  
            }
            
            //Karen Hung 2/3/2021 DOO-5269
            Map<String, String> activityAPIMap = new Map<String, String>{'Large' => 'MTTO_FO_Large_Bucket__c', 
                														 'Cups' => 'MTTO_FO_Cups_Bucket__c',
                														 'Small' => 'MTTO_FO_Small_Bucket__c'};
                                                                             
            Map<String, String> activityMCOAPIMap = new Map<String, String>{'Large' => 'MTTO_MCO_Large_Bucket__c',
                															'Preventive Maintenance' => 'MTTO_MCO_PM_Bucket__c', 
                                                                            'Waterfilter' => 'MTTO_MCO_Waterfilter_Bucket__c', 
                                                                            'Descaling' => 'MTTO_MCO_Descaling_Bucket__c', 
                                                                            'Bottle' => 'MTTO_MCO_Bottles_Bucket__c', 
                                                                            'Ingredients' => 'MTTO_MCO_Ingredients_Bucket__c'};
                                                                                
            Map<String, String> actComboAPIMap = new Map<String, String>{'L' => 'MTTO_MCO_Large_Bucket__c',
                                                                         'P' => 'MTTO_MCO_PM_Bucket__c', 
                                                                         'W' => 'MTTO_MCO_Waterfilter_Bucket__c', 
                                                                         'D' => 'MTTO_MCO_Descaling_Bucket__c', 
                                                                         'B' => 'MTTO_MCO_Bottles_Bucket__c', 
                                                                         'I' => 'MTTO_MCO_Ingredients_Bucket__c'};

            //GET BUSINESS HOURS
            TS_BusinessHoursChecker.getNextBusinessDay(bhList);
            bhMap = TS_BusinessHoursChecker.nextBusinessDayMap;
            
            //START WOLI CREATION 
            List<WorkOrderLineItem> woliInsertList = new List<WorkOrderLineItem>();
            for(WorkOrder wo : forUpdateWOList){
                Boolean isCounterOperating = false;

                WorkOrder workOrder = extWoNewMap.get(wo.Id);                
                List<String> task_activity_list = new List<String>();
                if(workOrder.Task_Activity_Type__c != null && workOrder.WorkOrderType__c != null){
                    //FOR MACHINE CARE
                    if(workOrder.WorkOrderType__c == CONST_WORKORDER_OP_TYPE){

                        //CHECK IF ACTIVITY TYPES WOULD BE COMBINED OR ITERATED
                        if(workOrder.OP_Physical_Asset__r.SalesOrganization__c != null && oldOpSalesOrg != null && oldOpSalesOrg.contains(workOrder.OP_Physical_Asset__r.SalesOrganization__c)){
                            //CHECK IF THE TASK HAS COUNTER
                            if(workOrder.Task_Activity_Type__c.contains(CONST_COUNTER_OPERATING)){
                                isCounterOperating = true;
                            }
                            //CREATE A LIST OF ACTIVITY TYPES
                            task_activity_list = workOrder.Task_Activity_Type__c.split(';');
                        }
                        else if(workOrder.OP_Physical_Asset__r.SalesOrganization__c != null && newOpSalesOrg != null && newOpSalesOrg.contains(workOrder.OP_Physical_Asset__r.SalesOrganization__c)){
                            task_activity_list.add(workOrder.Task_Activity_Type__c);
                        }
                        else {
                            continue; // SKIP THIS RECORD AND PROCEED TO NEXT WOLI IF SALES ORG IS NOT SUPPORTED
                        }
                    }

                    //FOR COUNTER READING
                    else if(workOrder.WorkOrderType__c == CONST_WORKORDER_CR_TYPE){
                        task_activity_list.add(workOrder.Task_Activity_Type__c);          
                    }

                    //START ITERATION FOR WOLI CREATION
                    for(String activity : task_activity_list){  

                        //SKIP CREATION OF WOLI IF COUNTEROPERATING SINCE ITS JUST AN IDENTIFIER
                        if(activity == CONST_COUNTER_OPERATING) {
                            continue;
                        }

                        WorkOrderLineItem woli = new WorkOrderLineItem();

                        //FIELDS APPLICABLE TO BOTH MC AND CR
                        woli.WorkOrderLineItemType__c = activity; 
                        woli.Status = TS_Constants.TS_Status_Open;

                        woli.WorkOrderId = workOrder.Id;
                        woli.WorkOrderType__c = workOrder.WorkOrderType__c;

                        woli.AccountLocation__c = workOrder.Account_Location__c;
                        woli.AccountLocationID__c = workOrder.Account_Location__r.SAP_Customer_ID__c != null ? workOrder.Account_Location__r.SAP_Customer_ID__c : null;

                        woli.PhysicalAsset__c = workOrder.OP_Physical_Asset__c;
                        woli.Building__c = workOrder.OP_Physical_Asset__r.Building__c != null ? workOrder.OP_Physical_Asset__r.Building__c : null;
                        woli.Floor__c = workOrder.OP_Physical_Asset__r.Floor__c != null ? workOrder.OP_Physical_Asset__r.Floor__c  : null;

						//Karen Hung DOO-5101 22.12.2020                        
						woli.Description = wo.Description;
                       
                        if(operatingBucketEnabled) woli.OPG_Source__c = 'Manual';
                        
                        String priceBookKey = String.valueOf(workOrder.OP_Physical_Asset__r.Product__c) + workOrder.OP_Physical_Asset__r.SalesOrganization__c;
                        if(pBMap.containsKey(priceBookKey)){
                            woli.PricebookEntryId = pBMap.get(priceBookKey) != null ? pBMap.get(priceBookKey).Id : null;
                            
                            //Karen Hung 2/3/2021 DOO-5269
                            if(operatingBucketEnabled  && workOrder.WorkOrderType__c != CONST_WORKORDER_CR_TYPE){
                                
                                PricebookEntry pbeRec = pBMap.get(priceBookKey);
                                //for NL
                                if(oldOpSalesOrg.contains(workOrder.OP_Physical_Asset__r.SalesOrganization__c)){
                                    
                                    woli.Operating_Bucket__c = String.valueOf(pbeRec?.get(activityAPIMap.get(activity)));
                                    
                                 //for DK/NO
                                }else if(newOpSalesOrg.contains(workOrder.OP_Physical_Asset__r.SalesOrganization__c)){
                                    //for single activity type
                                    if(activityMCOAPIMap.containsKey(activity)){
                                        
                                        woli.Operating_Bucket__c = String.valueOf(pbeRec.get(activityMCOAPIMap.get(activity)));
                                        
                                        //for combo activity type, get the largest bucket
                                    }else{
                                        List<String> woliMTTOs = new List<String>();
                                        //get the mtto bucket values and sort
                                        for(Integer i=0; i<woli.WorkOrderLineItemType__c.length(); i++){
                                            String mttoAPI = actComboAPIMap.get(woli.WorkOrderLineItemType__c?.substring(i, i+1));
                                            woliMTTOs.add(String.valueOf(pbeRec?.get(mttoAPI))); 
                                        }
                                        woliMTTOs.sort();
                                        //get the last index(biggest) of mtto bucket values
                                        woli.Operating_Bucket__c = woliMTTOs.size() > 0 ? woliMTTOs[woliMTTOs.size()-1] : null;        
                                    }                                        
                                }                                 
                            }   
                        }
                        
                        //Karen Hung 18/2/2021 DOO-5166 populate enabled survey in click
                        if(surveySettingEnabled && workOrder.Account_Location__r.Third_Party_Resource__c != null && surveySettingMap.containsKey(workOrder.SalesOrganization__c + workOrder.WorkOrderType__c + activity) && woli.WorkOrderLineItemType__c == TS_Constants.ACTIVITY_LARGE){
                            String surveyType;
                            List<String> surveyTypes = new List<String>();
                            surveyTypes.addAll(surveySettingMap.get(workOrder.SalesOrganization__c + woli.WorkOrderType__c + woli.WorkOrderLineItemType__c));
                            for(String surType : surveyTypes){
                                 surveyType = surveyType == null ? surType : (surveyType + ';' + surType);
                            }
                            woli.Enabled_Survey_in_Click__c = surveyType;   
                        }
                        
                         //Karen Hung DOO-5308 3PO Fields
                        if(workOrder.Third_Party__c == true){
                        	woli.Status = TS_Constants.WOLI_STATUS_SCHEDULED;
                            woli.ExecutingEngineer__c = workOrder.ExecutingEngineer__c;
                            woli.Travel_Start_Time__c = workOrder.Early_Start_Date__c;
                            woli.Travel_Stop_Time__c = workOrder.Early_Start_Date__c;
                            woli.StartDate__c = workOrder.Early_Start_Date__c;
                            woli.EndDate__c = workOrder.Early_Start_Date__c;
                        }
                        
                        String timeIndicator = '0';
                        boolean isTimeIndicatorExecutedOnce = false;
                        String CONST_AM_Time = 'AM';
                        String CONST_PM_Time = 'PM';
                        
                        if (!isTimeIndicatorExecutedOnce && !timeindicator.equals('0')) {
                            woli.OP_TimeIndicator__c = timeindicator == CONST_AM_Time || timeindicator == CONST_PM_Time ? timeindicator : null;
                            isTimeIndicatorExecutedOnce = true;
                        }

                        woli.OP_IsHoliday__c = false; 

                        //MC SPECIFIC FIELDS
                        if(workOrder.WorkOrderType__c == CONST_WORKORDER_OP_TYPE){
                            woli.RecordTypeId = CONST_WOLI_OP_RT;
                            
                            woli.EarlyStart__c = workOrder.Early_Start_Date__c;
                            woli.SLADate__c =  workOrder.SLA_Date__c;
                    
                            DateTime dt = workOrder.Early_Start_Date__c;
                            Date earlyStartDate= dt.date();

                            woli.isFromRoute__c = true;

                            //SET COUNTER VALUE FOR LARGE TASK
                            if(activity == CONST_Large && isCounterOperating == true){
                                woli.SendCounterReadingsOperating__c = true;
                            }
                        
                        }
                        
                        //CR SPECIFIC FIELDS
                        else if(workOrder.WorkOrderType__c == CONST_WORKORDER_CR_TYPE){
                            woli.RecordTypeId = CONST_WOLI_CR_RT;
                            woli.MachineCare__c = workOrder.OP_Physical_Asset__r.Machine_Care__c != null ? workOrder.OP_Physical_Asset__r.Machine_Care__c : null;
                            woli.streetandhouseNumber__c = workOrder.OP_Physical_Asset__r.Street__c != null ? workOrder.OP_Physical_Asset__r.Street__c : null;
                            woli.PostalCode__c = workOrder.OP_Physical_Asset__r.PostalCode__c != null ? workOrder.OP_Physical_Asset__r.PostalCode__c : null;
                            woli.OP_PCBchanged__c = workOrder.OP_Physical_Asset__r.OP_PCB_Changed__c != null ? workOrder.OP_Physical_Asset__r.OP_PCB_Changed__c : null;
                            woli.FilterChangeDate__c = workOrder.OP_Physical_Asset__r.LastWTSDate__c != null ? workOrder.OP_Physical_Asset__r.LastWTSDate__c : null;
                            woli.PreventiveMaintenancePerformedDate__c = workOrder.OP_Physical_Asset__r.LastPreventiveMaintenanceDate__c != null ? workOrder.OP_Physical_Asset__r.LastPreventiveMaintenanceDate__c : null;
                            woli.machinecare__c = workOrder.OP_Physical_Asset__r.Machine_Care__c != null ? workOrder.OP_Physical_Asset__r.Machine_Care__c : null;
                            
                            woli.TypeOfCounterReadingTask__c = 'Corrective';
                            woli.SendCounterReadings__c = true;
                            woli.isCRswoliisloaded__c = true;
                            woli.isFromRoute__c = false; 

                            if(bhMap.containsKey(workOrder.SalesOrganization__c)){
                                woli.SLADate__c = bhMap.get(workOrder.SalesOrganization__c) != null ? bhMap.get(workOrder.SalesOrganization__c) : null;
                            }

                            woli.RequiredEngineer__c = workOrder.Required_Operator__c != null ? workOrder.Required_Operator__c : null;
                            woli.OP_PreferredOperator__c = workOrder.Preferred_Operator__c != null ? workOrder.Preferred_Operator__c : null;
                            woli.Route_Name__c = workOrder.Route_Name__c != null ? workOrder.Route_Name__c : null ;
                            woli.Unique_Number__c = workOrder.Route_Number__c != null ? workOrder.Route_Number__c : null ;

                        }
                        
                        woliInsertList.add(woli);
                    }
                }   
            }

            if(!woliInsertList.isEmpty()){
                try{
                    insert woliInsertList;
                } 
                catch (Exception e){
                    System.debug(e);
                    CustomLogging.debugException(e);
                    CustomLogging.pop();
                }
            }

            //DOO-5166 17/2/2020 update Enabled Survey in Click field of workorders
            if(surveySettingEnabled && !forUpdateWOList.isEmpty()){
				TS_RouteTask_Batch rs = new TS_RouteTask_Batch();
                List<WorkOrder> forUpdateSurvey = rs.workOrderSurveys(forUpdateWOList);
                if(!forUpdateSurvey.isEmpty() && forUpdateSurvey !=null){
                    //update Suvey Field
                    Database.SaveResult[] saveResults2 = Database.update(forUpdateSurvey, false);
                    rs.INSERT_LOGGING(saveResults2, 'WorkOrder Survey Update');    
                }
            }            
            
        }
    }
    
     /*
    * @author        Karen Hung
    * @date          17.02.2021
    * @description   DOO-5166 to get survey settings
    * @revision(s)
    */
    public static Map<String, Set<String>> getSurveySetting(){
        CustomLogging.push('getSurveySetting', 'TS_CreateOperatingTaskController');
        Map<String, Set<String>> surveySettingMap = new Map<String, Set<String>>();
        List<CountrySetting__c> cList = [SELECT Id,Country__c,WorkOrderType__c, Activity_Type__c, Survey_Type__c FROM CountrySetting__c WHERE RecordType.Name='Country Survey' AND Active__c=true];
        if(!cList.isEmpty()){
            for(CountrySetting__c cset : cList){
                String taskKey = cset.Country__c + cset.WorkOrderType__c + cset.Activity_Type__c;
                if(surveySettingMap.containsKey(taskKey)){
                    surveySettingMap.get(taskKey).add(cset.Survey_Type__c);
                }else{
                    surveySettingMap.put(taskKey, new Set<String>{cset.Survey_Type__c});    
                }
                
            }    
        }
        CustomLogging.pop();
        return surveySettingMap;
    }

     /*
    * @author        Francis Allen Alindogan
    * @date          March 25, 2020
    * @description   Helper class to create Integration logs for Route type Operating WO/WOLI
    * @revision(s)   
    */
    public static void createOperatingIntegLog(List<SOBject> sObj){
        CustomLogging.push('createOperatingIntegLog', 'WorkOrderTriggerHandler');
        List<Integration_Log__c> integLogsToInsertList = new List<Integration_Log__c>();

        if(sObj != null){          
        List<WorkOrder> woList = (List<WorkOrder>) sObj;
           for(WorkOrder wo : woList){
                integLogsToInsertList.add(new Integration_Log__c( Object__c = INT_Constants.WOLI_CREATEUPDATE_OPERATINGROUTE_TASK,
                                                    Object_Id__c = wo.Id,
                                                    Work_Order__c = wo.Id,
                                                    Ready_To_Be_Sent__c = true,
                                                    Integration_Status__c = 'Initial',
                                                    Triggered_Timestamp__c = DateTime.now()));                
          }
        }                  
            
        if(!integLogsToInsertList.isEmpty()){
            try{
                insert integLogsToInsertList;
            } 
            catch (Exception e){
                System.debug(e);
                CustomLogging.debugException(e);
                CustomLogging.pop();
            }
        }   
    }
    
    /*
    * @author        Francis Allen Alindogan
    * @date          March 25, 2020
    * @description   Helper class to get Routes using PhysicalAsset
    * @revision(s)   
    */
    private Map<Id,Id> getPhyAssetRouteMap(Set<Id> paIds){
        CustomLogging.push('getPhyAssetRouteMap', 'WorkOrderTriggerHandler');
        Map<Id,Id> phyAssetRliMap = new Map<Id,Id>();
        if(paIds != null){
            List<AggregateResult> listOfRli = [   SELECT PhysicalAssetId__c, RouteId__c
                                                    FROM Route_Line_Item__c 
                                                    WHERE RouteId__c != null
                                                    AND (PhysicalAssetId__r.AssetStatus__c = :TS_Constants.PA_STATUS_ACTIVATED OR PhysicalAssetId__r.AssetStatus__c = :TS_Constants.PA_STATUS_PENDINGCANCELATION)
                                                    AND PhysicalAssetId__c IN: paIds
                                                    GROUP BY PhysicalAssetId__c, RouteId__c
                                                ];

            for(AggregateResult rli : listOfRli){
                phyAssetRliMap.put((Id)rli.get('PhysicalAssetId__c'), (Id)rli.get('RouteId__c'));
            }                                            
         }
         return phyAssetRliMap;
    }

    /*
    * @author        Francis Allen Alindogan
    * @date          March 25, 2020
    * @description   Helper class to check if the Route is for Click Integration
    * @revision(s)   
    */
    public static void checkForIntegration(List<WorkOrderLineItem> woliList){	
        CustomLogging.push('checkForIntegration', 'WorkOrderTriggerHandler');
        String integType = 'Click - RouteOperatingTask_Item';
        String integStatus = 'Target System Success';
        Set<Id> woComplete = new Set<Id>();
        Set<Id> woIncomplete = new Set<Id>();
        Set<Id> woliWithSuccessInteg = new Set<Id>();
        Set<Id> woFromWoliList = new Set<Id>();
        
        //GET ALL WORKORDERS                                                  
        for(WorkOrderLineItem woli : woliList){
            woFromWoliList.add(woli.WorkOrderId);
        }


        if(woFromWoliList != null){
            //GET ALL RELATED WOLI
            List<WorkOrderLineitem> allWoliList = [SELECT Id, WorkOrderId
                                                    FROM WorkOrderLineItem
                                                    WHERE WorkOrderId IN:woFromWoliList
                                                    ];
            
            //GET ALL WOLI INTEG LOG
            List<AggregateResult> listOfIntegLog = [SELECT Integration_Status__c, Work_Order_Line_Item__c
                                                    FROM Integration_Log__c 
                                                    WHERE Work_Order_Line_Item__c IN: allWoliList
                                                    AND Integration_Status__c =: integStatus
                                                    AND Object__c =: integType
                                                    GROUP BY Integration_Status__c, Work_Order_Line_Item__c
                                                	];

            //UNIQUE IDS OF WOLI WITH SUCCESS INTEG LOG   
            for(AggregateResult ilog : listOfIntegLog){
                woliWithSuccessInteg.add((Id)ilog.get('Work_Order_Line_Item__c'));
            }              
            
            if(allWoliList != null ){
                for(WorkOrderLineItem woli : allWoliList){
                    //CONSOLIDATE ALL WO WITH WOLI SUCCESS INTEGRATION
                    if(woliWithSuccessInteg.contains(woli.Id)){
                        woComplete.add(woli.WorkOrderId);
                    }
                    //CONSOLIDATE ALL WO WITH STILL MISSING WOLI INTEGRATION
                    else {
                        woIncomplete.add(woli.WorkOrderId);
                    }
                }
            }


            //REMOVE INCOMPLETE WO ID
            for(Id woId: woFromWoliList){
                if(woIncomplete.contains(woId)){
                    woComplete.remove(woId);
                }
            }

            if(woComplete != null && woComplete.size() > 0){

                List<WorkOrder> forUpdateWOList = new List<WorkOrder>();
                forUpdateWOList = [SELECT
                                        Id,
                                        Early_Start_Date__c,
                                        Pricebook2Id,
                                        Status,
                                        SLA_Date__c,
                                        Account_Location__c,
                                        Account_Location__r.Main_Service_Contact__c,
                                        Account_Location__r.Apttus_Config2__AccountId__c,
                                        Account_Location__r.SAP_Customer_ID__c,
                                        OP_Physical_Asset__c,
                                        OP_Physical_Asset__r.Product__c, 
                                        OP_Physical_Asset__r.SalesOrganization__c,
                                        OP_Physical_Asset__r.Building__c,
                                        OP_Physical_Asset__r.Floor__c,
                                        OP_Physical_Asset__r.OP_PreferredOperator__c,
                                        OP_Physical_Asset__r.Machine_Care__c,
                                        Task_Activity_Type__c
                            
                                     FROM WorkOrder 
                                     WHERE Id 
                                     IN: woComplete
									 AND Third_Party__c = false];

                createOperatingIntegLog(forUpdateWOList);
            }
        }
    } 


     /*
    * @author        Francis Allen Alindogan
    * @date          April 08, 2020
    * @description   Helper class to get additional information from the workorder
    * @revision(s)   
    */
    private Map<Id,WorkOrder> getExtWoNewMap(Set<Id> woIds){
        CustomLogging.push('getExtWoNewMap', 'WorkOrderTriggerHandler');
        Map<Id, WorkOrder> extWoNewMap = new Map<Id, WorkOrder>();

        if (woIds != null && !woIds.isEmpty()) {
            extWoNewMap = new Map<Id, WorkOrder>(
                [SELECT Id,
                    Early_Start_Date__c,
                    Pricebook2Id,
                    Status,
                    SLA_Date__c,
                    Account_Location__c,
                    Account_Location__r.Main_Service_Contact__c,
                    Account_Location__r.Apttus_Config2__AccountId__c,
                    Account_Location__r.SAP_Customer_ID__c,
                 	Account_Location__r.Third_Party_Resource__c,
                    ExecutingEngineer__c,
                    Third_Party__c,
                    OP_Physical_Asset__c,
                    OP_Physical_Asset__r.SalesOrganization__c,
                    OP_Physical_Asset__r.Building__c,
                    OP_Physical_Asset__r.Floor__c,
                    OP_Physical_Asset__r.LastPreventiveMaintenanceDate__c,
                    OP_Physical_Asset__r.LastWTSDate__c,
                    OP_Physical_Asset__r.Machine_Care__c,
                    OP_Physical_Asset__r.OP_PCB_Changed__c,
                    OP_Physical_Asset__r.OP_PreferredOperator__c,
                    OP_Physical_Asset__r.Product__c,
                    OP_Physical_Asset__r.PostalCode__c,
                    OP_Physical_Asset__r.Street__c,
                    Route_Name__c,
                    Route_Number__c,
                    Preferred_Operator__c,
                    Required_Operator__c,
                    WorkOrderType__c,
                    Task_Activity_Type__c,
                    SalesOrganization__c
                FROM WorkOrder
                WHERE Id IN :woIds
                ]);
        }
        
        return extWoNewMap;
    }

    /*
    * @author        Francis Allen Alindogan
    * @date          Aug 6, 2020
    * @description   DOO - 4749 Method to replace TS_CalculateLSPDates processbuilder
    * @revision(s)   
    */
    public void calculateLSPDate (List<SObject> newList){
        CustomLogging.push('calculateLSPDate', 'WorkOrderTriggerHandler');
        String woRecordTypeId = TS_UtilityClass.getRecordTypeIdByName(TS_Constants.OBJ_APINAME_WO, TS_Constants.TS_WO_RECORDTYPE_OPERATINGROUTEWO);   
        List<Id> woIds = new List<Id>();   
        for(WorkOrder wo : (List<WorkOrder>) newList){
            if( wo.RecordTypeId != null &&
                wo.RecordTypeId != woRecordTypeId &&
                wo.Status != TS_Constants.STATUS_COMPLETED &&
                wo.Status != TS_Constants.STATUS_CANCELED){
                    
                if( wo.S40_Notice_Count__c == wo.S40TotalCount__c &&
                    wo.S41NoticeCount__c == wo.S41TotalCount__c &&
                    wo.S43NoticeCount__c == wo.S43TotalCount__c &&
                    wo.RequiresLSP__c == true &&
                    wo.Manual_WOLI_Count__c == 0){

                    woIds.add(wo.Id); 

                }
            }                                                
        }

        if(!woIds.isEmpty() && woIds.size() > 0){            
            TS_LSPDatesCalculator.calculateLSPDates(woIds); 
        }
        CustomLogging.pop();    
    }
    
   /*
    * @author        Karen Hung
    * @date          
    * @description   DOO -5307 Reinitiate engineer access when owner id was updated
    * @revision(s)   
    */
    public void reInitiateAccess (List<WorkOrder> newList, Map<Id, WorkOrder> oldMapItems){
        CustomLogging.push('reInitiateAccess', 'WorkOrderTriggerHandler');
        String woRecordTypeId = TS_UtilityClass.getRecordTypeIdByName(TS_Constants.OBJ_APINAME_WO, TS_Constants.TS_WO_RECORDTYPE_OPERATINGROUTEWO);   
        List<Id> woIds = new List<Id>();
        List<WorkOrderLineItem> woliforAccess = new List<WorkOrderLineItem>();
        for(WorkOrder wo : [SELECT Id, OwnerId,(SELECT Id,WorkOrderLineItemType__c,WorkOrderType__c,ExecutingEngineer__c,Case__c, Case__r.AccountId, Case__r.Contact.AccountId, Case__r.SecondaryContact__r.AccountId,
                        	PhysicalAsset__c, WorkOrderId, AccountLocation__c,
                        	AccountLocation__r.Apttus_Config2__AccountId__c,ExecutingEngineer__r.RelatedUser__c FROM WorkOrderLineItems WHERE ExecutingEngineer__c !=null) 
                            FROM WorkOrder WHERE Id IN :newList AND Status != :TS_Constants.STATUS_COMPLETED]){
            if(!wo.WorkOrderLineItems.isEmpty() && wo.OwnerId != oldMapItems.get(wo.Id)?.OwnerId){
                for(WorkOrderLineItem woli : wo.WorkOrderLineItems){
                	woliforAccess.add(woli);   
                }
            }                                               
        }
        
        if(!woliforAccess.isEmpty()){            
            WorkOrderLineItemTriggerHandler.reinitiateAccessEnabled = true;
            WorkOrderLineItemTriggerHandler.woliTriggerHandlerClassWithoutSharing cc = new WorkOrderLineItemTriggerHandler.woliTriggerHandlerClassWithoutSharing();
            cc.provideEngineerAccessWithoutSharing(woliforAccess, null);    
        }

        CustomLogging.pop();    
    }

}