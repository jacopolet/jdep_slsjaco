/**
* @author        Paul Jarred Aguiling
* @date          01.10.2018     
* @description   Class responsible for the Installation Flows
* @revision(s)   02.08.2018 Adrian Reyes: Added Potential Round-Trip mapping from work order trigger to case
*                5.17.2018 Paul Aguiling: KTS-1751 Updated createWorkOrderLineItem() and KTS-1475 createConversionOrder()
*                7.13.2018 Paul Aguiling: KTS-1935 Updated createCaseRecords()
*                12.6.2018 Karen Hung : added machine care mapping for installation KTS-2388
*                21/05/2019 Ata       : Added logic to make scheduledManually true when LSPRequired is true on WOLI
*                28/06/2019 Ata       : added code to fill Account and contact lookup value while WorkOrder creation
* 
* */
public with sharing class TS_SalesTriggerController {

    private Id caseRecTypeId = null;
    private Map<Id, PriceBookEntry> map_ProductandPricebooks = new Map<Id, PriceBookEntry>();
    private Map<String, Boolean> map_SalesOrgData = new Map<String, Boolean>(); //KTS-1993 Map to check APTS_LSP_Required__c
    public static Boolean hasException = false;
    Map<String,CountrySetting__c> countryScheduleDateTimeSettingsMap;
    Map<String,CountrySetting__c> countryDefaultBusinessHoursMap;
    
    //XEN REYES Nov. 14, 2019 DOO-2650
    Map<String, Map<Boolean, CountrySetting__c>> countrySchedulingRulesMap;

    public TS_SalesTriggerController() {
        WorkOrderTriggerObjectHandler.fromSalesTrigger = true;
        //caseRecTypeId = TS_UtilityClass.getRecordTypeIdByName(Label.TS_Obj_API_Name_Case, Label.TS_Case_Type_FieldServiceDefault);
        countryScheduleDateTimeSettingsMap = getCountryScheduleDateTimeSettingsMap();
        countryDefaultBusinessHoursMap = getCountryDefaultBusinessHoursMap();

        //XEN REYES Nov. 14, 2019 DOO-2650
        countrySchedulingRulesMap = getCountrySchedulingRulesMap();
    }

    /**
    * @author         Paul Jarred Aguiling
    * @date           01.10.2018
    * @description    Method responsible for throwing an exception
    * @revision(s)
    */ 
    public class TS_SalesTriggerCtrlHandlerException extends Exception {}

    /**
    * @author         Paul Jarred Aguiling
    * @date           01.10.2018   
    * @description    Method responsible for retrieving Work Order Trigger Records 
    * @revision(s)
    */ 
    public void getWorkOrderTriggerRecords(List<Id> parentOrderIds) {
        CustomLogging.push('getWorkOrderTriggerRecords', 'TS_SalesTriggerController'); 
        Map<Id, List<WorkOrderTrigger__c>> lineItemMap = new Map<Id, List<WorkOrderTrigger__c>>();
        List<WorkOrderTrigger__c> headerList = new List<WorkOrderTrigger__c>();
        Set<Id> lineItemProductIds = new Set<Id>();
        Set<String> headerSalesOrgs = new Set<String>();
        List<WorkOrderTrigger__c> workOrderTriggerList = new List<WorkOrderTrigger__c>();

        try {

            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_SalesTriggerCtrlHandlerException('Force to throw an exception');
            }

            System.debug('===Get Work Order Trigger Records===');
            if (parentOrderIds != null && !parentOrderIds.isEmpty()) {
                //Retrieve work order triggers based on parent order ids executed from the platform event (Work Order Trigger Event)
                workOrderTriggerList = [SELECT Id, Name, Type__c, OrderType__c, ParentOrder__c, Subject__c, Machine_Care__c, //Karen Hung 06.12.2018 KTS-2388
                                                 Description__c, AccountLocation__c, PlugPlay__c,
                                                 Workshop__c, OrderLineItem__c, Load_ID__c,
                                                 RequestedActivityDate__c, Stopover__c, Product__c,
                                                 SalesOrganization__c, IsProject__c, ProjectNumber__c,
                                                 PickingDate__c, ScheduleExceptions__c, DeInstall_NonJDEMachine__c,
                                                 RefurbishedMachine__c, CustomerReference__c, CommercialMachine__c,
                                                 StairClimber__c, SmokingArea__c, Requires_LSP__c,
                                                 OwnedByCustomer__c, ConfigurationFileURL__c,
                                                 Building__c, ConfigurationManualAgreementsURL__c,
                                                 Floor__c, Area__c, JDE_crockeryVolumeSize__c,
                                                 OwnerId, ServiceContact__c, StopoverCountry__c,
                                                 StopoverPostalCode__c, StopoverStreetAndHouseNumber__c, 
                                                 StopoverCity__c, ReturnProduct__c,
                                                 PhysicalAsset__c, IncludesWaterfilterCoverage__c,
                                                 PhysicalAsset__r.Building__c, PhysicalAsset__r.Floor__c,
                                                 PhysicalAsset__r.Area__c, PhysicalAsset__r.CustomerReferenceNumber__c,
                                                 OrderSubType__c, ChildOrder__c, DependentDeInstallation__c,
                                                 PhysicalAsset__r.OwnedByCustomer__c, AdditionalServiceContact__c, PotentialRoundTrip__c,
                                                 PO_Number__c, FaultConfiguration__c, ExternalMovement__c
                                                 //PO_Number__c, Product__r.APTS_LSP_Required__c, FaultConfiguration__c,
                                          FROM WorkOrderTrigger__c 
                                          WHERE ParentOrder__c IN :parentOrderIds];
            }

            //Iterate WOT records and group them per parent order with the format of 1 header record has option and line item records 
            for (WorkOrderTrigger__c wotRec: workOrderTriggerList) {

                //Get all line item record type
                if (Label.TS_WOTType_LineItem.equals(wotRec.Type__c)) {

                    //Group line item per parent order
                    if (lineItemMap.containsKey(wotRec.ParentOrder__c)) {
                        lineItemMap.get(wotRec.ParentOrder__c).add(wotRec);
                    } else {
                        lineItemMap.put(wotRec.ParentOrder__c, new List<WorkOrderTrigger__c>{wotRec});
                    }

                    lineItemProductIds.add(wotRec.Product__c); //Set of products used in getting pricebook entries
                }

                //Get all header record type
                if (Label.TS_WOTType_Header.equals(wotRec.Type__c)) {
                    headerList.add(wotRec);
                    headerSalesOrgs.add(wotRec.SalesOrganization__c); //Set of sales organizaion used in getting pricebook entries
                }
            }

            //WOT records will be group per Order Type (Installation, Deinstallation, Conversion, Movement, Swap, Conversion)
            Map<Id, List<WorkOrderTrigger__c>> headerMap = new Map<Id, List<WorkOrderTrigger__c>>();
            Map<Id, List<WorkOrderTrigger__c>> headerInstallationMap = new Map<Id, List<WorkOrderTrigger__c>>();
            Map<Id, List<WorkOrderTrigger__c>> headerDeInstallationMap = new Map<Id, List<WorkOrderTrigger__c>>();
            Map<Id, List<WorkOrderTrigger__c>> headerSwapMap = new Map<Id, List<WorkOrderTrigger__c>>();
            Map<Id, List<WorkOrderTrigger__c>> headerMovementMap = new Map<Id, List<WorkOrderTrigger__c>>();
            Map<Id, List<WorkOrderTrigger__c>> headerConversionMap = new Map<Id, List<WorkOrderTrigger__c>>();

            Set<String> listOfSalesOrg = new Set<String>();//KTS-1993
            Set<String> listOfProducts = new Set<String>();//KTS-1993

            for (WorkOrderTrigger__c wotRec: headerList) {

                //Create a map of all header and related line item record that will be used 
                //retrieving price book entries
                headerMap.put(wotRec.id, lineItemMap.get(wotRec.ParentOrder__c));

                //Scenario: Installation Order
                if (Label.TS_WOTOrderType_Installation.equals(wotRec.OrderType__c)) {
                    headerInstallationMap.put(wotRec.id, lineItemMap.get(wotRec.ParentOrder__c));
                //Scenario: De-Installation Order
                } else if (Label.TS_WOTOrderType_DeInstallation.equals(wotRec.OrderType__c)) {
                    headerDeInstallationMap.put(wotRec.id, lineItemMap.get(wotRec.ParentOrder__c));
                //Scenario: Swap Order
                } else if (Label.TS_WOTOrderType_Swap.equals(wotRec.OrderType__c)) {
                    //Get the de-installation order line items
                    headerSwapMap.put(wotRec.id, lineItemMap.get(wotRec.ParentOrder__c));
                    
                    //Get the installation order line items
                    if (wotRec.ChildOrder__c != null) {
                        for (WorkOrderTrigger__c wotRecChild: lineItemMap.get(wotRec.ChildOrder__c)) {
                            headerSwapMap.get(wotRec.id).add(wotRecChild);
                        }

                    }
                //Scenario: Movement Order
                } else if (Label.TS_WOTOrderType_Movement.equals(wotRec.OrderType__c)) {
                    //Get the de-installation order line items
                    headerMovementMap.put(wotRec.id, lineItemMap.get(wotRec.ParentOrder__c));

                    //Get the installation order line items
                    if (wotRec.ChildOrder__c != null) {
                        for (WorkOrderTrigger__c wotRecChild: lineItemMap.get(wotRec.ChildOrder__c)) {
                            headerMovementMap.get(wotRec.id).add(wotRecChild);
                        }
                    }
                //Scenario: Conversion Order
                } else if (Label.TS_WOTOrderType_Conversion.equals(wotRec.OrderType__c)) {
                    //Get the de-installation order line items
                    headerConversionMap.put(wotRec.id, lineItemMap.get(wotRec.ParentOrder__c));

                    //KTS-1993
                    listOfSalesOrg.add(wotRec.SalesOrganization__c.removeStart(TS_Constants.PREFIX_SAP));//Format value Ex. SAP_0333 to 0333
                    listOfProducts.add(wotRec.Product__c);
                    
                    //Get the installation order line items
                    //if (wotRec.ChildOrder__c != null) {
                    //    for (WorkOrderTrigger__c wotRecChild: lineItemMap.get(wotRec.ChildOrder__c)) {
                    //        headerConversionMap.get(wotRec.id).add(wotRecChild);
                    //    }
                    //}
                }
            }

            //Check if products and sales organization are not empty before executing SOQL
            if (!lineItemProductIds.isEmpty() || !headerSalesOrgs.isEmpty()) {

                //Collect all price book entry based on the product Id of line item and sales org of header record
                for (PriceBookEntry priceBookEnt: [SELECT Id, PriceBook2Id, Product2Id, Sales_Organization__c  
                                                   FROM PriceBookEntry WHERE Product2Id IN :lineItemProductIds 
                                                   AND Sales_Organization__c IN :headerSalesOrgs
                                                   AND IsActive = true]) {

                    //Iterate header records
                    for (WorkOrderTrigger__c wotRec: headerList) {
                        for (WorkOrderTrigger__c lineItemWOT: headerMap.get(wotRec.Id)) {
                            //Match headers sales org and line items product to pricebook results
                            if (wotRec.SalesOrganization__c == priceBookEnt.Sales_Organization__c 
                                && lineItemWOT.Product__c == priceBookEnt.Product2Id) {
                                map_ProductandPricebooks.put(lineItemWOT.Id, priceBookEnt);
                            }
                        }
                    } 
                }
            }

            //Scenario 1: Installation Order
            if (!headerInstallationMap.isEmpty()) {
                createInstallationOrder(headerInstallationMap, headerList);
            }

            //Scenario 2: De-Installation Order
            if (!headerDeInstallationMap.isEmpty()) {
                createDeInstallationOrder(headerDeInstallationMap, headerList);
            }

            //Scenario 3: Swap Order
            if (!headerSwapMap.isEmpty()) {
                createSwapOrder(headerSwapMap, headerList);
            }

            //Scenario 4: Movement Order
            if (!headerMovementMap.isEmpty()) {
                createMovementOrder(headerMovementMap, headerList);
            }

            //Scenario 5: Conversion Order
            if (!headerConversionMap.isEmpty()) {
                //Fetch the corresponding Sales Org Data record by using the Sales Org and Product Id from the Work Order Trigger. 
                //By Querying on Sales Org Data Name (APTS_Sales_Org_Data_Name__c) and APTS_Product__c using the sales org and 
                //product id of the option to be added on the work order trigger table.
                for (APTS_Sales_Org_Data__c salesOrg : [SELECT Id, APTS_Sales_Org_Data_Name__c, APTS_Product__c, APTS_LSP_Required__c
                                                        FROM APTS_Sales_Org_Data__c 
                                                        WHERE APTS_Sales_Org_Data_Name__c IN:listOfSalesOrg
                                                        AND APTS_Product__c IN:listOfProducts]) {

                    //Check fields if null to avoid exceptions
                    if (salesOrg.APTS_Sales_Org_Data_Name__c != null 
                        && salesOrg.APTS_Product__c != null 
                        && !map_SalesOrgData.containsKey(salesOrg.APTS_Sales_Org_Data_Name__c + salesOrg.APTS_Product__c)) {
                        map_SalesOrgData.put(salesOrg.APTS_Sales_Org_Data_Name__c + salesOrg.APTS_Product__c, salesOrg.APTS_LSP_Required__c);
                    }
                }

                createConversionOrder(headerConversionMap, headerList);
            }

        }catch(Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }     

        CustomLogging.pop();
    }

    /**
    * @author         Paul Jarred Aguiling
    * @date           01.10.2018   
    * @description    Method responsible for creating Installation Order records
    * @revision(s)
    */ 
    private void createInstallationOrder(Map<Id, List<WorkOrderTrigger__c>> headerMap, List<WorkOrderTrigger__c> headerList) {
        CustomLogging.push('createInstallationOrder', 'TS_SalesTriggerController');
        List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
        List<WorkOrderLineItem> pickUpWOTList = new List<WorkOrderLineItem>();
        List<Case> caseToInsert = new List<Case>();
        Map<String, String> caseMap = new Map<String, String>();
        Map<String, WorkOrder> woMap = new Map<String, WorkOrder>();
        Map<String, WorkOrderLineItem> woliToMap = new Map<String, WorkOrderLineItem>();
        List<WorkOrderLineItem> woliListToInsert = new List<WorkOrderLineItem>(); 
        List<Apttus_Config2__Order__c> orderToUpdate = new List<Apttus_Config2__Order__c>();
        Set<Id> checkDuplicateOrderId = new Set<Id>();

        //Loop WOT header records with attach WOT line item/option records
        for (WorkOrderTrigger__c wotRec: headerList) {
            if (Label.TS_WOTOrderType_Installation.equals(wotRec.OrderType__c)) {
                //######### Create Work Order Line Item #######//    
                Map<Id, Id> accountLocationMap = new Map<Id, Id>();
                Set<Id> checkAccountLocation = new Set<Id>();

                //Collect and check WOT records if they have different account location records
                for (WorkOrderTrigger__c lineItemWOT: headerMap.get(wotRec.Id)) {
                    if (lineItemWOT.AccountLocation__c != null && checkAccountLocation.add(lineItemWOT.AccountLocation__c)) {
                        accountLocationMap.put(lineItemWOT.AccountLocation__c, lineItemWOT.Id);
                    }       
                }

                //Flag to dertermine if there are different account location per WOT record
                Boolean hasDiffAccountLocation = checkAccountLocation.size() > 1? true : false;

                //Construct WOLI records based on WOT records criteria for account location and if it has a stopover
                for (WorkOrderTrigger__c lineItemWOT: headerMap.get(wotRec.Id)) {
                    String woliExternalRef = hasDiffAccountLocation? accountLocationMap.get(lineItemWOT.AccountLocation__c) : wotRec.Id;
                    WorkOrderLineItem woli = createWorkOrderLineItem(lineItemWOT, Label.TS_Type_Task, Label.TS_Order_S40, TS_Constants.WOLI_LOADID_INSTALL, woliExternalRef, TS_Constants.WOLI_SBJDESC_INSTALLATION);
                    woliList.add(woli);

                    if (lineItemWOT.Stopover__c) {
                       WorkOrderLineItem woli2 = createWorkOrderLineItem(lineItemWOT, Label.TS_Type_Task, Label.TS_Case_SubType_PickUp, TS_Constants.WOLI_LOADID_PICKUP, woliExternalRef, TS_Constants.WOLI_SBJDESC_PICKUP);
                       pickUpWOTList.add(woli2);
                    }
                }
                //######### Create Work Order Line Item #######//                  

                //######### Create Case #######//
                //Construct product and case mapping per WOT record considering the different account location
                if (hasDiffAccountLocation) {
                    for (Id lineItemID: accountLocationMap.values()) {
                        Case cse = createCaseRecords(wotRec, Label.TS_Case_Origin_SalesOrder, Label.TS_Order_S40, Label.TS_Case_Type_FieldService, Label.TS_Status_InProgress, caseRecTypeId, lineItemID);
                        caseMap.put(cse.CaseExternalReference__c, lineItemID);
                        caseToInsert.add(cse);
                    }
                } else {                    
                    Case cse = createCaseRecords(wotRec, Label.TS_Case_Origin_SalesOrder, Label.TS_Order_S40, Label.TS_Case_Type_FieldService, Label.TS_Status_InProgress, caseRecTypeId, String.valueOf(wotRec.Id));
                    caseMap.put(cse.CaseExternalReference__c, wotRec.Id);
                    caseToInsert.add(cse);
                }
                //######### Create Case #######//
            }
        }
        
        //Insert Case Records
        if (!caseToInsert.isEmpty())
            insert caseToInsert;

        //Invoke getCaseOwnerId method
        Map<Id, Case> caseMapWO = getCaseOwnerId(caseToInsert);

        //XEN REYES Nov. 14, 2019 DOO-2650
        Map<Id, Case> woCasemap = new Map<Id, Case>();

        //Create and insert work order records
        for (Case cse: caseToInsert) {
            WorkOrder wo = new WorkOrder();
            wo.CaseId = cse.Id;
            wo.ContactId = cse.ContactId;
            wo.AccountId = cse.AccountId;
            wo.OwnerID = caseMapWO.get(cse.Id).OwnerId;
            wo.Status = Label.TS_Status_Open;
            wo.LoadID__c = cse.LoadID__c.replace(TS_Constants.LOADID_TEXT_CASE, TS_Constants.LOADID_TEXT_WO);
            wo.PriceBook2Id = getWOPriceBook(headerMap, cse.CaseExternalReference__c);
            wo.SalesOrganization__c = cse.SalesOrganization__c;
            woMap.put(caseMap.get(cse.CaseExternalReference__c), wo);

            //XEN REYES Nov. 14, 2019 DOO-2650
            woCasemap.put(caseMap.get(cse.CaseExternalReference__c), cse);

            //KTS-1482 Update Apttus Order Object to stamp created case
            if (checkDuplicateOrderId.add(cse.ApptusOrder__c)) {
                Apttus_Config2__Order__c order = new Apttus_Config2__Order__c();
                order.Id = cse.ApptusOrder__c;
                order.APTS_Case__c = cse.Id;
                orderToUpdate.add(order);
            }
        }

        
        if (!orderToUpdate.isEmpty() && Schema.sObjectType.Apttus_Config2__Order__c.isUpdateable())
            update orderToUpdate;
        
        if (!woMap.isEmpty())
            insert woMap.values();

        //Create and insert work order line item records for pick up scenario
        for (WorkOrderLineItem woli: pickUpWOTList) {
            woli.Case__c = woMap.get(woli.WOLIExternalReference__c).CaseId;
            woli.WorkOrderId = woMap.get(woli.WOLIExternalReference__c).Id;
            woliToMap.put(formatLoadIdText(woli.LoadID__c, TS_Constants.WOLI_LOADID_PICKUP), woli);
        }
        
        if (!woliToMap.isEmpty())
            insert woliToMap.values();

        for (WorkOrderLineItem woli: woliList) {
            //Create the woli line item records and 
            //check if woli has a stopoever to stampe pickup woli line item
            //otherwise do the normal mapping
            if (woli.RequiresStopover__c) {
                String resultId = formatLoadIdText(woli.LoadID__c, TS_Constants.WOLI_LOADID_INSTALL);
                woli.Case__c = woliToMap.get(resultId).Case__c;
                woli.WorkOrderId = woliToMap.get(resultId).WorkOrderId;
                woli.DependentWOLI__c = woliToMap.get(resultId).Id; 
            } else {
                woli.Case__c = woMap.get(woli.WOLIExternalReference__c).CaseId;
                woli.WorkOrderId = woMap.get(woli.WOLIExternalReference__c).Id;   
            }

            //XEN REYES Nov. 14, 2019 DOO-2650
            if(woli.RequiresLSP__c == true) {
                WorkOrder wo_var = woMap.get(woli.WOLIExternalReference__c);
                if(countrySchedulingRulesMap.containsKey(wo_var.SalesOrganization__c)){
                    Case cs_var = woCasemap.get(woli.WOLIExternalReference__c);
                    if(countrySchedulingRulesMap.get(wo_var.SalesOrganization__c).containsKey(cs_var.PotentialRoundTrip__c)){
                        CountrySetting__c cSet_var = countrySchedulingRulesMap.get(wo_var.SalesOrganization__c).get(cs_var.PotentialRoundTrip__c);
                        if(cSet_var.DeliveryOffset__c == 0){
                            woli.ScheduleManually__c = true;
                        }
                    }
                }
            }

            woliListToInsert.add(woli); 
        }

        
        if (!woliListToInsert.isEmpty())
            insert woliListToInsert;

        //Group the created task to be able to determine in CLICK using the JDE Line Item Numnber stamped in GroupingIndicator__c
        List<WorkOrderLineItem> listOfAllWolis = new List<WorkOrderLineItem>();
        listOfAllWolis.addAll(woliToMap.values());
        listOfAllWolis.addAll(woliListToInsert);
        updateChildWolisGrouping(listOfAllWolis);

        CustomLogging.pop();  
    }

    /**
    * @author         Paul Jarred Aguiling
    * @date           01.10.2018   
    * @description    Method responsible for creating De-Installation Order records
    * @revision(s)
    */ 
    private void createDeInstallationOrder(Map<Id, List<WorkOrderTrigger__c>> headerMap, List<WorkOrderTrigger__c> headerList) {
        CustomLogging.push('createDeInstallationOrder', 'TS_SalesTriggerController');
        List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
        List<WorkOrderLineItem> dropOffWOTList = new List<WorkOrderLineItem>();
        List<Case> caseToInsert = new List<Case>();
        Map<String, String> caseMap = new Map<String, String>();
        Map<String, WorkOrder> woMap = new Map<String, WorkOrder>();
        Map<String, WorkOrderLineItem> woliToMap = new Map<String, WorkOrderLineItem>();
        List<WorkOrderLineItem> woliListToInsert = new List<WorkOrderLineItem>(); 
        List<Apttus_Config2__Order__c> orderToUpdate = new List<Apttus_Config2__Order__c>();
        Set<Id> checkDuplicateOrderId = new Set<Id>();

        //Loop WOT header records with attach WOT line item/option records
        for (WorkOrderTrigger__c wotRec: headerList) {
            if (Label.TS_WOTOrderType_DeInstallation.equals(wotRec.OrderType__c)) {
                //######### Create Work Order Line Item #######//    
                Map<Id, Id> accountLocationMap = new Map<Id, Id>();
                Set<Id> checkAccountLocation = new Set<Id>();

                //Collect and check WOT records if they have different account location records
                for (WorkOrderTrigger__c lineItemWOT: headerMap.get(wotRec.Id)) {
                    if (lineItemWOT.AccountLocation__c != null && checkAccountLocation.add(lineItemWOT.AccountLocation__c)) {
                        accountLocationMap.put(lineItemWOT.AccountLocation__c, lineItemWOT.Id);
                    }       
                }

                //Flag to dertermine if there are different account location per WOT record
                Boolean hasDiffAccountLocation = checkAccountLocation.size() > 1? true : false;

                //Construct WOLI records based on WOT records criteria for account location and if it has a stopover
                for (WorkOrderTrigger__c lineItemWOT: headerMap.get(wotRec.Id)) {
                    String woliExternalRef = hasDiffAccountLocation? accountLocationMap.get(lineItemWOT.AccountLocation__c) : wotRec.Id;
                    WorkOrderLineItem woli = createWorkOrderLineItem(lineItemWOT, Label.TS_Type_Task, Label.TS_Order_S41, TS_Constants.WOLI_LOADID_DEINSTALL, woliExternalRef, TS_Constants.WOLI_SBJDESC_DEINSTALLATION);
                    woliList.add(woli);

                    if (lineItemWOT.Stopover__c) {
                       WorkOrderLineItem woli2 = createWorkOrderLineItem(lineItemWOT, Label.TS_Type_Task, Label.TS_Case_SubType_PickUp, TS_Constants.WOLI_LOADID_DROPOFF, woliExternalRef, TS_Constants.WOLI_SBJDESC_DROPOFF);
                       dropOffWOTList.add(woli2);
                    }
                }
                //######### Create Work Order Line Item #######//                  

                //######### Create Case #######//
                //Construct product and case mapping per WOT record considering the different account location
                if (hasDiffAccountLocation) {
                    for (Id lineItemID: accountLocationMap.values()) {
                        Case cse = createCaseRecords(wotRec, Label.TS_Case_Origin_SalesOrder, Label.TS_Order_S41, Label.TS_Case_Type_FieldService, Label.TS_Status_InProgress, caseRecTypeId, lineItemID);
                        caseMap.put(cse.CaseExternalReference__c, lineItemID);
                        caseToInsert.add(cse);
                    }
                } else {                    
                    Case cse = createCaseRecords(wotRec, Label.TS_Case_Origin_SalesOrder, Label.TS_Order_S41, Label.TS_Case_Type_FieldService, Label.TS_Status_InProgress, caseRecTypeId, String.valueOf(wotRec.Id));
                    caseMap.put(cse.CaseExternalReference__c, wotRec.Id);
                    caseToInsert.add(cse);
                }
                //######### Create Case #######//
            }
        }
        
        //Insert Case Records
        if (!caseToInsert.isEmpty())
            insert caseToInsert;

        //Invoke getCaseOwnerId method
        Map<Id, Case> caseMapWO = getCaseOwnerId(caseToInsert);

        //XEN REYES Nov. 14, 2019 DOO-2650
        Map<Id, Case> woCasemap = new Map<Id, Case>();

        //Create and insert work order records
        for (Case cse: caseToInsert) {
            WorkOrder wo = new WorkOrder();
            wo.CaseId = cse.Id;
            wo.ContactId = cse.ContactId;
            wo.AccountId = cse.AccountId;
            wo.OwnerID = caseMapWO.get(cse.Id).OwnerId;
            wo.Status = Label.TS_Status_Open;
            wo.LoadID__c = cse.LoadID__c.replace(TS_Constants.LOADID_TEXT_CASE, TS_Constants.LOADID_TEXT_WO);
            wo.PriceBook2Id = getWOPriceBook(headerMap, cse.CaseExternalReference__c); 
            wo.SalesOrganization__c = cse.SalesOrganization__c;           
            woMap.put(caseMap.get(cse.CaseExternalReference__c), wo);

            //XEN REYES Nov. 14, 2019 DOO-2650
            woCasemap.put(caseMap.get(cse.CaseExternalReference__c), cse);

            //KTS-1482 Update Apttus Order Object to stamp created case
            if (checkDuplicateOrderId.add(cse.ApptusOrder__c)) {
                Apttus_Config2__Order__c order = new Apttus_Config2__Order__c();
                order.Id = cse.ApptusOrder__c;
                order.APTS_Case__c = cse.Id;
                orderToUpdate.add(order);
            }
        }

        if (!orderToUpdate.isEmpty() && Schema.sObjectType.Apttus_Config2__Order__c.isUpdateable())
            update orderToUpdate;

        if (!woMap.isEmpty())
            insert woMap.values();

        //Create and insert work order line item records for line item scenario
        for (WorkOrderLineItem woli: woliList) {
            woli.Case__c = woMap.get(woli.WOLIExternalReference__c).CaseId;
            woli.WorkOrderId = woMap.get(woli.WOLIExternalReference__c).Id;
            woliToMap.put(formatLoadIdText(woli.LoadID__c, TS_Constants.WOLI_LOADID_DEINSTALL), woli);

            //XEN REYES Nov. 14, 2019 DOO-2650
            if(woli.RequiresLSP__c == true) {
                WorkOrder wo_var = woMap.get(woli.WOLIExternalReference__c);
                if(countrySchedulingRulesMap.containsKey(wo_var.SalesOrganization__c)){
                    Case cs_var = woCasemap.get(woli.WOLIExternalReference__c);
                    if(countrySchedulingRulesMap.get(wo_var.SalesOrganization__c).containsKey(cs_var.PotentialRoundTrip__c)){
                        CountrySetting__c cSet_var = countrySchedulingRulesMap.get(wo_var.SalesOrganization__c).get(cs_var.PotentialRoundTrip__c);
                        if(cSet_var.PickupOffset__c == 0){
                            woli.ScheduleManually__c = true;
                        }
                    }
                }
            }
        }

        if (!woliToMap.isEmpty())
            insert woliToMap.values();

        //Create and insert woli pick up/drop off line item records with dependent woli scenario
        for (WorkOrderLineItem woli: dropOffWOTList) {
            String resultId = formatLoadIdText(woli.LoadID__c, TS_Constants.WOLI_LOADID_DROPOFF);
            woli.Case__c = woliToMap.get(resultId).Case__c;
            woli.WorkOrderId = woliToMap.get(resultId).WorkOrderId;
            woli.DependentWOLI__c = woliToMap.get(resultId).Id;

            woliListToInsert.add(woli); 
        }

        if (!woliListToInsert.isEmpty())
            insert woliListToInsert;

        //Group the created task to be able to determine in CLICK using the JDE Line Item Numnber stamped in GroupingIndicator__c
        List<WorkOrderLineItem> listOfAllWolis = new List<WorkOrderLineItem>();
        listOfAllWolis.addAll(woliToMap.values());
        listOfAllWolis.addAll(woliListToInsert);
        updateChildWolisGrouping(listOfAllWolis);

        CustomLogging.pop();  
    }

    /**
    * @author         Paul Jarred Aguiling
    * @date           01.10.2018   
    * @description    Method responsible for creating Swap Order records
    * @revision(s)
    */ 
    private void createSwapOrder(Map<Id, List<WorkOrderTrigger__c>> headerMap, List<WorkOrderTrigger__c> headerList) {
        CustomLogging.push('createSwapOrder', 'TS_SalesTriggerController');
        List<WorkOrderLineItem> parentDeinstallWoliList = new List<WorkOrderLineItem>();
        List<WorkOrderLineItem> pickUpWOTList = new List<WorkOrderLineItem>();
        List<WorkOrderLineItem> childWOLIList = new List<WorkOrderLineItem>();
        List<Case> caseToInsert = new List<Case>();
        Map<String, String> caseMap = new Map<String, String>();
        Map<String, WorkOrder> woMap = new Map<String, WorkOrder>();
        Map<String, WorkOrderLineItem> pickUpWoliMap = new Map<String, WorkOrderLineItem>();
        Map<String, WorkOrderLineItem> deinstallWoliMap = new Map<String, WorkOrderLineItem>();
        Map<String, WorkOrderLineItem> installWoliMap = new Map<String, WorkOrderLineItem>();
        List<WorkOrderLineItem> dropOfflistToInsert = new List<WorkOrderLineItem>();
        List<Apttus_Config2__Order__c> orderToUpdate = new List<Apttus_Config2__Order__c>();
        Set<Id> checkDuplicateOrderId = new Set<Id>();

        //Loop WOT header records with attach WOT line item/option records
        for (WorkOrderTrigger__c wotRec: headerList) {
            if (Label.TS_WOTOrderType_Swap.equals(wotRec.OrderType__c)) {
                //######### Create Work Order Line Item #######//    
                Map<Id, Id> accountLocationMap = new Map<Id, Id>();
                Set<Id> checkAccountLocation = new Set<Id>();

                //Collect and check WOT records if they have different account location records
                for (WorkOrderTrigger__c lineItemWOT: headerMap.get(wotRec.Id)) {
                    if (lineItemWOT.AccountLocation__c != null && checkAccountLocation.add(lineItemWOT.AccountLocation__c)) {
                        accountLocationMap.put(lineItemWOT.AccountLocation__c, lineItemWOT.Id);
                    }       
                }

                //Flag to dertermine if there are different account location per WOT record
                Boolean hasDiffAccountLocation = checkAccountLocation.size() > 1? true : false;

                //Construct WOLI records based on WOT records criteria for account location and if it has a stopover
                for (WorkOrderTrigger__c lineItemWOT: headerMap.get(wotRec.Id)) {
                    String woliExternalRef = hasDiffAccountLocation? accountLocationMap.get(lineItemWOT.AccountLocation__c) : wotRec.Id;

                    if (Label.TS_WOTOrderType_Installation.equals(lineItemWOT.OrderSubType__c)) {
                        WorkOrderLineItem woliInstall = createWorkOrderLineItem(lineItemWOT, Label.TS_Type_Task, Label.TS_Order_S40, TS_Constants.WOLI_LOADID_INSTALL, woliExternalRef, TS_Constants.WOLI_SBJDESC_INSTALLATION);
                        childWOLIList.add(woliInstall);

                        if (lineItemWOT.Stopover__c) {
                           WorkOrderLineItem woliPickUp = createWorkOrderLineItem(lineItemWOT, Label.TS_Type_Task, Label.TS_Case_SubType_PickUp, TS_Constants.WOLI_LOADID_PICKUP, woliExternalRef, TS_Constants.WOLI_SBJDESC_PICKUP);
                           pickUpWOTList.add(woliPickUp);
                        }
                    } else if (Label.TS_WOTOrderType_DeInstallation.equals(lineItemWOT.OrderSubType__c)) {
                        WorkOrderLineItem woliDeinstall = createWorkOrderLineItem(lineItemWOT, Label.TS_Type_Task, Label.TS_Order_S41, TS_Constants.WOLI_LOADID_DEINSTALL, woliExternalRef, TS_Constants.WOLI_SBJDESC_DEINSTALLATION);
                        parentDeinstallWoliList.add(woliDeinstall);

                        if (lineItemWOT.Stopover__c) {
                           WorkOrderLineItem woliDropOff = createWorkOrderLineItem(lineItemWOT, Label.TS_Type_Task, Label.TS_Case_SubType_PickUp, TS_Constants.WOLI_LOADID_DROPOFF, woliExternalRef, TS_Constants.WOLI_SBJDESC_DROPOFF);
                           childWOLIList.add(woliDropOff);
                        }
                    }
                }

                //######### Create Work Order Line Item #######//

                //######### Create Case #######//
                //Construct product and case mapping per WOT record considering the different account location
                if (hasDiffAccountLocation) {
                    for (Id lineItemID: accountLocationMap.values()) {
                        Case cse = createCaseRecords(wotRec, Label.TS_Case_Origin_SalesOrder, Label.TS_Case_SubType_Swap, Label.TS_Case_Type_FieldService, Label.TS_Status_InProgress, caseRecTypeId, lineItemID);
                        caseMap.put(cse.CaseExternalReference__c, lineItemID);
                        caseToInsert.add(cse);
                    }
                } else {                    
                    Case cse = createCaseRecords(wotRec, Label.TS_Case_Origin_SalesOrder, Label.TS_Case_SubType_Swap, Label.TS_Case_Type_FieldService, Label.TS_Status_InProgress, caseRecTypeId, String.valueOf(wotRec.Id));
                    caseMap.put(cse.CaseExternalReference__c, wotRec.Id);
                    caseToInsert.add(cse);
                }
                //######### Create Case #######//
            }
        }
        

        //Insert Case Records
        if (!caseToInsert.isEmpty())
            insert caseToInsert;


        //Invoke getCaseOwnerId method
        Map<Id, Case> caseMapWO = getCaseOwnerId(caseToInsert);

        //Create and insert work order records
        for (Case cse: caseToInsert) {
            WorkOrder wo = new WorkOrder();
            wo.CaseId = cse.Id;
            wo.ContactId = cse.ContactId;
            wo.AccountId = cse.AccountId;
            wo.OwnerID = caseMapWO.get(cse.Id).OwnerId;
            wo.Status = Label.TS_Status_Open;
            wo.LoadID__c = cse.LoadID__c.replace(TS_Constants.LOADID_TEXT_CASE, TS_Constants.LOADID_TEXT_WO);
            wo.PriceBook2Id = getWOPriceBook(headerMap, cse.CaseExternalReference__c);
            wo.SalesOrganization__c = cse.SalesOrganization__c;
            woMap.put(caseMap.get(cse.CaseExternalReference__c), wo);

            //KTS-1482 Update Apttus Order Object to stamp created case
            if (checkDuplicateOrderId.add(cse.ApptusOrder__c)) {
                Apttus_Config2__Order__c order = new Apttus_Config2__Order__c();
                order.Id = cse.ApptusOrder__c;
                order.APTS_Case__c = cse.Id;
                orderToUpdate.add(order);
            }
        }

        if (!orderToUpdate.isEmpty() && Schema.sObjectType.Apttus_Config2__Order__c.isUpdateable())
            update orderToUpdate;


        if (!woMap.isEmpty())
            insert woMap.values();

        //Create and insert work order line item records for pick up
        for (WorkOrderLineItem woli: pickUpWOTList) {
            woli.Case__c = woMap.get(woli.WOLIExternalReference__c).CaseId;
            woli.WorkOrderId = woMap.get(woli.WOLIExternalReference__c).Id;
            pickUpWoliMap.put(formatLoadIdText(woli.LoadID__c, TS_Constants.WOLI_LOADID_PICKUP), woli);
        }

        if (!pickUpWoliMap.isEmpty())
            insert pickUpWoliMap.values();

        //Create and insert work order line item de-installation line items
        for (WorkOrderLineItem woli: parentDeinstallWoliList) {
            String resultId = formatLoadIdText(woli.LoadID__c, TS_Constants.WOLI_LOADID_DEINSTALL);
            
            if (pickUpWoliMap.get(resultId) != null) {
                woli.Case__c = pickUpWoliMap.get(resultId).Case__c;
                woli.WorkOrderId = pickUpWoliMap.get(resultId).WorkOrderId;
                woli.DependentWOLI__c = pickUpWoliMap.get(resultId).Id; 
                deinstallWoliMap.put(resultId, woli); 
            } else {
                woli.Case__c = woMap.get(woli.WOLIExternalReference__c).CaseId;
                woli.WorkOrderId = woMap.get(woli.WOLIExternalReference__c).Id;
                deinstallWoliMap.put(resultId, woli); 

            }
        }

        if (!deinstallWoliMap.isEmpty())
            insert deinstallWoliMap.values();


        //Create and insert work order line item records for installation dependent on woli de-installation record
        for (WorkOrderLineItem woli: childWOLIList) {

            if (Label.TS_Order_S40.equals(woli.WorkOrderType__c)) {
                String resultId = formatLoadIdText(woli.LoadID__c, TS_Constants.WOLI_LOADID_INSTALL);
                if(resultId != null && resultId !='' && resultId != 'null'){// Added by Ritesh kumar to avoid the null Exception (13-09-2018)                    woli.Case__c = deinstallWoliMap.get(resultId).Case__c;
                    woli.Case__c = deinstallWoliMap.get(resultId).Case__c;
                    woli.WorkOrderId = deinstallWoliMap.get(resultId).WorkOrderId;
                    woli.DependentWOLI__c = deinstallWoliMap.get(resultId).Id; 
                    //woli.Case__c = woMap.get(woli.WOLIExternalReference__c).CaseId;//Added by Ritesh Kumar(13-09-2018) : To Add WOLI With case.
                    installWoliMap.put(resultId, woli);
                    
                }else{//Added by Ritesh kumar (14-09-2018): to add case and workorderId when resultid is null.
                    woli.Case__c = woMap.get(woli.WOLIExternalReference__c).CaseId;
                    woli.WorkOrderId = woMap.get(woli.WOLIExternalReference__c).Id;
                    installWoliMap.put(resultId, woli);
                }

            }
        }

        if (!installWoliMap.isEmpty())
            insert installWoliMap.values();
        //Create and insert work order line item drop off
        for (WorkOrderLineItem woli: childWOLIList) {
            if (woli.RequiresStopover__c && Label.TS_Case_SubType_PickUp.equals(woli.WorkOrderType__c)) {  
                String resultId = formatLoadIdText(woli.LoadID__c, TS_Constants.WOLI_LOADID_DROPOFF);
                    woli.Case__c = installWoliMap.get(resultId).Case__c;
                    woli.WorkOrderId = installWoliMap.get(resultId).WorkOrderId;
                    woli.DependentWOLI__c = installWoliMap.get(resultId).Id; 
                    dropOfflistToInsert.add(woli);          
            }
        }

        if (!dropOfflistToInsert.isEmpty())
            insert dropOfflistToInsert;

        //Group the created task to be able to determine in CLICK using the JDE Line Item Numnber stamped in GroupingIndicator__c
        List<WorkOrderLineItem> listOfAllWolis = new List<WorkOrderLineItem>();
        listOfAllWolis.addAll(pickUpWoliMap.values());
        listOfAllWolis.addAll(deinstallWoliMap.values());
        listOfAllWolis.addAll(installWoliMap.values());
        listOfAllWolis.addAll(dropOfflistToInsert);
        updateChildWolisGrouping(listOfAllWolis);

        CustomLogging.pop();  
    }

    /**
    * @author         Paul Jarred Aguiling
    * @date           01.10.2018   
    * @description    Method responsible for creating Movement Order records
    * @revision(s)
    */ 
    private void createMovementOrder(Map<Id, List<WorkOrderTrigger__c>> headerMap, List<WorkOrderTrigger__c> headerList) {
        CustomLogging.push('createMovementOrder', 'TS_SalesTriggerController');
        List<WorkOrderLineItem> parentWOLIList = new List<WorkOrderLineItem>();
        List<WorkOrderLineItem> childWOLIList = new List<WorkOrderLineItem>();
        List<Case> caseToInsert = new List<Case>();
        Map<String, String> caseMap = new Map<String, String>();
        Map<String, WorkOrder> woMap = new Map<String, WorkOrder>();
        Map<String, WorkOrderLineItem> woliToMap = new Map<String, WorkOrderLineItem>();
        List<WorkOrderLineItem> woliListToInsert = new List<WorkOrderLineItem>(); 
        List<Apttus_Config2__Order__c> orderToUpdate = new List<Apttus_Config2__Order__c>();
        Set<Id> checkDuplicateOrderId = new Set<Id>();

        //Loop WOT header records with attach WOT line item/option records
        for (WorkOrderTrigger__c wotRec: headerList) {
            if (Label.TS_WOTOrderType_Movement.equals(wotRec.OrderType__c)) {
                //######### Create Work Order Line Item #######//    
                //Map<Id, Id> accountLocationMap = new Map<Id, Id>();
                //Set<Id> checkAccountLocation = new Set<Id>();
                
                //Collect and check WOT records if they have different account location records
                //for (WorkOrderTrigger__c lineItemWOT: headerMap.get(wotRec.Id)) {
                //    if (lineItemWOT.AccountLocation__c != null && checkAccountLocation.add(lineItemWOT.AccountLocation__c)) {
                //        accountLocationMap.put(lineItemWOT.AccountLocation__c, lineItemWOT.Id);    
                //    }      
                //}

                //Flag to dertermine if there are different account location per WOT record
                //Boolean hasDiffAccountLocation = checkAccountLocation.size() > 1? true : false;

                //Construct WOLI records based on WOT records criteria for account location and if it has a stopover
                for (WorkOrderTrigger__c lineItemWOT: headerMap.get(wotRec.Id)) {
                    //String woliExternalRef = hasDiffAccountLocation? accountLocationMap.get(lineItemWOT.AccountLocation__c) : wotRec.Id;
                    
                    //if (Label.TS_WOTOrderType_Installation.equals(lineItemWOT.OrderSubType__c)) {
                    //    WorkOrderLineItem woliInstall = createWorkOrderLineItem(lineItemWOT, Label.TS_Type_Task, Label.TS_Order_S40, TS_Constants.WOLI_LOADID_INSTALL, woliExternalRef, TS_Constants.WOLI_SBJDESC_INSTALLATION);
                    //    childWOLIList.add(woliInstall);
                    //} else if (Label.TS_WOTOrderType_DeInstallation.equals(lineItemWOT.OrderSubType__c)) {
                    //    WorkOrderLineItem woliDeinstall = createWorkOrderLineItem(lineItemWOT, Label.TS_Type_Task, Label.TS_Order_S41, TS_Constants.WOLI_LOADID_DEINSTALL, woliExternalRef, TS_Constants.WOLI_SBJDESC_DEINSTALLATION);
                    //    parentWOLIList.add(woliDeinstall);
                    //}
                    
                    if (Label.TS_WOTOrderType_Installation.equals(lineItemWOT.OrderSubType__c)) {
                        WorkOrderLineItem woliInstall = createWorkOrderLineItem(lineItemWOT, Label.TS_Type_Task, Label.TS_Order_S40, TS_Constants.WOLI_LOADID_INSTALL, wotRec.Id, TS_Constants.WOLI_SBJDESC_INSTALLATION);
                        childWOLIList.add(woliInstall);
                    } else if (Label.TS_WOTOrderType_DeInstallation.equals(lineItemWOT.OrderSubType__c)) {
                        WorkOrderLineItem woliDeinstall = createWorkOrderLineItem(lineItemWOT, Label.TS_Type_Task, Label.TS_Order_S41, TS_Constants.WOLI_LOADID_DEINSTALL, wotRec.Id, TS_Constants.WOLI_SBJDESC_DEINSTALLATION);
                        parentWOLIList.add(woliDeinstall);
                    }
                }
                //######### Create Work Order Line Item #######//                  

                //######### Create Case #######//
                //Construct product and case mapping per WOT record considering the different account location
                //if (hasDiffAccountLocation) {
                //    for (Id lineItemID: accountLocationMap.values()) {
                //        Case cse = createCaseRecords(wotRec, Label.TS_Case_Origin_SalesOrder, Label.TS_WOTOrderType_Movement, Label.TS_Case_Type_FieldService, Label.TS_Status_InProgress, caseRecTypeId, lineItemID);
                //        caseMap.put(cse.CaseExternalReference__c, lineItemID);
                //        caseToInsert.add(cse);
                //    }
                //} else {                    
                    Case cse = createCaseRecords(wotRec, Label.TS_Case_Origin_SalesOrder, Label.TS_WOTOrderType_Movement, Label.TS_Case_Type_FieldService, Label.TS_Status_InProgress, caseRecTypeId, String.valueOf(wotRec.Id));
                    caseMap.put(cse.CaseExternalReference__c, wotRec.Id);
                    caseToInsert.add(cse);
                //}
                //######### Create Case #######//
            }
        }
        
        //Insert Case Records
        if (!caseToInsert.isEmpty())
            insert caseToInsert;

        //Invoke getCaseOwnerId method
        Map<Id, Case> caseMapWO = getCaseOwnerId(caseToInsert);

        //Create and insert work order records
        for (Case cse: caseToInsert) {
            WorkOrder wo = new WorkOrder();
            wo.CaseId = cse.Id;
            wo.ContactId = cse.ContactId;
            wo.AccountId = cse.AccountId;
            wo.OwnerID = caseMapWO.get(cse.Id).OwnerId;
            wo.Status = Label.TS_Status_Open;
            wo.LoadID__c = cse.LoadID__c.replace(TS_Constants.LOADID_TEXT_CASE, TS_Constants.LOADID_TEXT_WO);
            wo.PriceBook2Id = getWOPriceBook(headerMap, cse.CaseExternalReference__c);
            wo.SalesOrganization__c = cse.SalesOrganization__c;
            woMap.put(caseMap.get(cse.CaseExternalReference__c), wo);

            //KTS-1482 Update Apttus Order Object to stamp created case
            if (checkDuplicateOrderId.add(cse.ApptusOrder__c)) {
                Apttus_Config2__Order__c order = new Apttus_Config2__Order__c();
                order.Id = cse.ApptusOrder__c;
                order.APTS_Case__c = cse.Id;
                orderToUpdate.add(order);
            }
        }

        if (!orderToUpdate.isEmpty() && Schema.sObjectType.Apttus_Config2__Order__c.isUpdateable())
            update orderToUpdate;

        if (!woMap.isEmpty())
            insert woMap.values();

        //Create and insert work order line item records for line item scenario
        for (WorkOrderLineItem woli: parentWOLIList) {
            woli.Case__c = woMap.get(woli.WOLIExternalReference__c).CaseId;
            woli.WorkOrderId = woMap.get(woli.WOLIExternalReference__c).Id;
            //Added by Ata
            //Check if LSP required is true and mark the WOLI as Scheduled Manually
            if(woli.RequiresLSP__c == true) {
                woli.ScheduleManually__c = true;
            }
            woliToMap.put(formatLoadIdText(woli.LoadID__c, TS_Constants.WOLI_LOADID_DEINSTALL), woli);
        }

        if (!woliToMap.isEmpty())
            insert woliToMap.values();

        //Create and insert woli pick up/drop off line item records with dependent woli scenario
        for (WorkOrderLineItem woli: childWOLIList) {
            String resultId = formatLoadIdText(woli.LoadID__c, TS_Constants.WOLI_LOADID_INSTALL);
            woli.Case__c = woliToMap.get(resultId).Case__c;
            woli.WorkOrderId = woliToMap.get(resultId).WorkOrderId;
            woli.DependentWOLI__c = woliToMap.get(resultId).Id;
            //Added by Ata
            //Check if LSP required is true and mark the WOLI as Scheduled Manually
            if(woli.RequiresLSP__c == true) {
                woli.ScheduleManually__c = true;
            }
            woliListToInsert.add(woli); 
        }

        if (!woliListToInsert.isEmpty())
            insert woliListToInsert;

        //Group the created task to be able to determine in CLICK using the JDE Line Item Numnber stamped in GroupingIndicator__c
        List<WorkOrderLineItem> listOfAllWolis = new List<WorkOrderLineItem>();
        listOfAllWolis.addAll(woliToMap.values());
        listOfAllWolis.addAll(woliListToInsert);
        updateChildWolisGrouping(listOfAllWolis);

        CustomLogging.pop();  
    }

    /**
    * @author         Paul Jarred Aguiling
    * @date           01.10.2018   
    * @description    Method responsible for creating Conversion Order records
    * @revision(s)    5.17.2018 Paul Aguiling: KTS-1475 Added fault configuration for deinstallation orders  
    */ 
    private void createConversionOrder(Map<Id, List<WorkOrderTrigger__c>> headerMap, List<WorkOrderTrigger__c> headerList) {
        CustomLogging.push('createConversionOrder', 'TS_SalesTriggerController');
        List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
        List<Case> caseToInsert = new List<Case>();
        Map<String, String> caseMap = new Map<String, String>();
        Map<String, WorkOrder> woMap = new Map<String, WorkOrder>();
        Map<String, WorkOrderLineItem> woliToMap = new Map<String, WorkOrderLineItem>();
        List<WorkOrderLineItem> woliListToInsert = new List<WorkOrderLineItem>(); 
        List<Apttus_Config2__Order__c> orderToUpdate = new List<Apttus_Config2__Order__c>();
        Set<Id> checkDuplicateOrderId = new Set<Id>();

        //Loop WOT header records with attach WOT line item/option records
        for (WorkOrderTrigger__c wotRec: headerList) {
            if (Label.TS_WOTOrderType_Conversion.equals(wotRec.OrderType__c)) {
                //######### Create Work Order Line Item #######//    
                Map<Id, Id> accountLocationMap = new Map<Id, Id>();
                Set<Id> checkAccountLocation = new Set<Id>();

                //Collect and check WOT records if they have different account location records
                for (WorkOrderTrigger__c lineItemWOT: headerMap.get(wotRec.Id)) {
                    if (lineItemWOT.AccountLocation__c != null && checkAccountLocation.add(lineItemWOT.AccountLocation__c)) {
                        accountLocationMap.put(lineItemWOT.AccountLocation__c, lineItemWOT.Id);
                    }       
                }

                //Flag to dertermine if there are different account location per WOT record
                Boolean hasDiffAccountLocation = checkAccountLocation.size() > 1? true : false;

                //Construct WOLI records based on WOT records criteria for account location and if it has a stopover
                for (WorkOrderTrigger__c lineItemWOT: headerMap.get(wotRec.Id)) {
                    String woliExternalRef = hasDiffAccountLocation? accountLocationMap.get(lineItemWOT.AccountLocation__c) : wotRec.Id;
                    
                    if (Label.TS_WOTOrderType_Installation.equals(lineItemWOT.OrderSubType__c)) {
                        WorkOrderLineItem woliInstall = createWorkOrderLineItem(lineItemWOT, Label.TS_Type_Task, Label.TS_Order_S43, TS_Constants.WOLI_LOADID_INSTALL, woliExternalRef, 'Add Option');
                        woliInstall.ConfigurationChangeRequest__c = Label.TS_Subject_Add;
                        woliInstall.FaultConfiguration__c = lineItemWOT.FaultConfiguration__c;
                        woliList.add(woliInstall);
                    } else if (Label.TS_WOTOrderType_DeInstallation.equals(lineItemWOT.OrderSubType__c)) {
                        WorkOrderLineItem woliDeinstall = createWorkOrderLineItem(lineItemWOT, Label.TS_Type_Task, Label.TS_Order_S43, TS_Constants.WOLI_LOADID_DEINSTALL, woliExternalRef, 'Remove Option');
                        woliDeinstall.ConfigurationChangeRequest__c = Label.TS_Subject_Remove;
                        woliDeinstall.FaultConfiguration__c = lineItemWOT.FaultConfiguration__c;
                        woliList.add(woliDeinstall);
                    }
                }
                //######### Create Work Order Line Item #######//                  

                //######### Create Case #######//
                //Construct product and case mapping per WOT record considering the different account location
                if (hasDiffAccountLocation) {
                    for (Id lineItemID: accountLocationMap.values()) {
                        Case cse = createCaseRecords(wotRec, Label.TS_Case_Origin_SalesOrder, Label.TS_WOTOrderType_Conversion, Label.TS_Case_Type_FieldService, Label.TS_Status_InProgress, caseRecTypeId, lineItemID);
                        caseMap.put(cse.CaseExternalReference__c, lineItemID);
                        caseToInsert.add(cse);
                    }
                } else {                    
                    Case cse = createCaseRecords(wotRec, Label.TS_Case_Origin_SalesOrder, Label.TS_WOTOrderType_Conversion, Label.TS_Case_Type_FieldService, Label.TS_Status_InProgress, caseRecTypeId, String.valueOf(wotRec.Id));
                    caseMap.put(cse.CaseExternalReference__c, wotRec.Id);
                    caseToInsert.add(cse);
                }
                //######### Create Case #######//
            }
        }
        
        //Insert Case Records
        if (!caseToInsert.isEmpty())
            insert caseToInsert;

        //Invoke getCaseOwnerId method
        Map<Id, Case> caseMapWO = getCaseOwnerId(caseToInsert);

        //Create and insert work order records
        for (Case cse: caseToInsert) {
            WorkOrder wo = new WorkOrder();
            wo.CaseId = cse.Id;
            wo.ContactId = cse.ContactId;
            wo.AccountId = cse.AccountId;
            wo.OwnerID = caseMapWO.get(cse.Id).OwnerId;
            wo.Status = Label.TS_Status_Open;
            wo.LoadID__c = cse.LoadID__c.replace(TS_Constants.LOADID_TEXT_CASE, TS_Constants.LOADID_TEXT_WO);
            wo.PriceBook2Id = getWOPriceBook(headerMap, cse.CaseExternalReference__c);
            wo.SalesOrganization__c = cse.SalesOrganization__c;
            woMap.put(caseMap.get(cse.CaseExternalReference__c), wo);

            //KTS-1482 Update Apttus Order Object to stamp created case
            if (checkDuplicateOrderId.add(cse.ApptusOrder__c)) {
                Apttus_Config2__Order__c order = new Apttus_Config2__Order__c();
                order.Id = cse.ApptusOrder__c;
                order.APTS_Case__c = cse.Id;
                orderToUpdate.add(order);
            }
        }

        if (!orderToUpdate.isEmpty() && Schema.sObjectType.Apttus_Config2__Order__c.isUpdateable())
            update orderToUpdate;

        if (!woMap.isEmpty())
            insert woMap.values();

        //Create and insert work order line item records for line item scenario
        for (WorkOrderLineItem woli: woliList) {
            woli.Case__c = woMap.get(woli.WOLIExternalReference__c).CaseId;
            woli.WorkOrderId = woMap.get(woli.WOLIExternalReference__c).Id;
            woliToMap.put(formatLoadIdText(woli.LoadID__c, TS_Constants.WOLI_LOADID_DEINSTALL), woli);
        }

        if (!woliToMap.isEmpty())
            insert woliToMap.values();

        //Group the created task to be able to determine in CLICK using the JDE Line Item Numnber stamped in GroupingIndicator__c
        List<WorkOrderLineItem> listOfAllWolis = new List<WorkOrderLineItem>();
        listOfAllWolis.addAll(woliToMap.values());
        updateChildWolisGrouping(listOfAllWolis);

        //Create and insert woli pick up/drop off line item records with dependent woli scenario
        //for (WorkOrderLineItem woli: childWOLIList) {
        //    String resultId = formatLoadIdText(woli.LoadID__c, TS_Constants.WOLI_LOADID_INSTALL);
        //    woli.Case__c = woliToMap.get(resultId).Case__c;
        //    woli.WorkOrderId = woliToMap.get(resultId).WorkOrderId;
        //    woli.DependentWOLI__c = woliToMap.get(resultId).Id; 
        //    woliListToInsert.add(woli); 
        //}

        //if (!woliListToInsert.isEmpty())
        //    insert woliListToInsert;

        CustomLogging.pop();  
    }

    /**
    * @author         Paul Jarred Aguiling
    * @date           01.10.2018   
    * @description    Method responsible for stamping the correct pricebook
    * @revision(s)    5.17.2018 Paul Aguiling [KTS-1751]: Added External Movement Mapping to WOLI
    */ 
    private Id getWOPriceBook(Map<Id, List<WorkOrderTrigger__c>> headerMap, String externalRef) {
        CustomLogging.push('getWOPriceBook', 'TS_SalesTriggerController');
        Id resultId = null;

        //Associate the correct PriceBook2Id to work order record through map_ProductandPricebooks
        if (headerMap.get(externalRef) != null) {
            for (WorkOrderTrigger__c lineItemWOT: headerMap.get(externalRef)) {
                resultId = map_ProductandPricebooks.get(lineItemWOT.Id) != null? map_ProductandPricebooks.get(lineItemWOT.Id).PriceBook2Id : null;

                if (resultId != null) {break;}
            }
        } else {
            resultId = map_ProductandPricebooks.get(externalRef) != null? map_ProductandPricebooks.get(externalRef).PriceBook2Id : null;
        }

        CustomLogging.pop();
        return resultId;
    }

    /**
    * @author         Paul Jarred Aguiling
    * @date           01.10.2018   
    * @description    Method responsible for text adjustment in the LOAD Id field
    * @revision(s)
    */ 
    private String formatLoadIdText(String textToFormat, String textToRemove) {
        CustomLogging.push('formatLoadIdText', 'TS_SalesTriggerController');
        CustomLogging.pop();
        return textToFormat.removeStartIgnoreCase(textToRemove);
    }

    /**
    * @author         Paul Jarred Aguiling
    * @date           01.10.2018   
    * @description    Method responsible for setting work order line item values
    * @revision(s)
    */ 
    private WorkOrderLineItem createWorkOrderLineItem(WorkOrderTrigger__c wotRec, String woliType, String type, 
                                                      String loadIdText, String externalRef, String sbjDesc) {
        CustomLogging.push('createWorkOrderLineItem', 'TS_SalesTriggerController');

        WorkOrderLineItem woli = new WorkOrderLineItem();
        woli.Status = Label.TS_Status_Open;
        woli.WorkOrderLineItemType__c = woliType;
        woli.WorkOrderType__c = type;
        woli.AccountLocation__c = wotRec.AccountLocation__c;
        woli.Plug_Play__c = wotRec.PlugPlay__c;
        woli.WorkshopActivity__c = wotRec.Workshop__c;
        woli.OrderLineItem__c = wotRec.OrderLineItem__c;
        //woli.Order = wotRec.ParentOrder__c;
        woli.WOLIExternalReference__c = externalRef; 
        woli.PricebookEntryId = map_ProductandPricebooks.get(wotRec.Id) != null? map_ProductandPricebooks.get(wotRec.Id).Id : null;
        woli.RequiresStopover__c = wotRec.Stopover__c;

        //Getting the right dependent wolis
        if (!Label.TS_WOTOrderType_Conversion.equals(wotRec.OrderType__c) && Label.TS_WOTOrderType_Installation.equals(wotRec.OrderSubType__c)) {
            woli.LoadID__c = loadIdText + wotRec.DependentDeInstallation__c;
        } else {
            woli.LoadID__c = loadIdText + wotRec.Id;
        }

        //Mapping specifically for de-installation items 
        if (Label.TS_WOTOrderType_DeInstallation.equals(wotRec.OrderType__c) || Label.TS_WOTOrderType_DeInstallation.equals(wotRec.OrderSubType__c)) {
            //woli.CollectCounters__c = wotRec.CollectCounters__c;
            woli.ReturnProduct__c = wotRec.ReturnProduct__c;
            woli.PhysicalAsset__c = wotRec.PhysicalAsset__c;
        }

        //Mapping specifically for conversion installation items to set add option (AddOption__c) checkbox
        if (Label.TS_WOTOrderType_Conversion.equals(wotRec.OrderType__c) && Label.TS_WOTOrderType_Installation.equals(wotRec.OrderSubType__c)) {
                woli.AddOption__c = true;
                //KTS-1507: LSP delivery date for conversion orders
                //woli.OptionDeliveredbyLSP__c = wotRec.Product__r != null? wotRec.Product__r.APTS_LSP_Required__c : false;
                woli.OptionDeliveredbyLSP__c = map_SalesOrgData.get(wotRec.SalesOrganization__c.removeStart(TS_Constants.PREFIX_SAP) + wotRec.Product__c);//KTS-1993
        }

        //Mapping specifically for installation items 
        if (Label.TS_WOTOrderType_Movement.equals(wotRec.OrderType__c) && Label.TS_WOTOrderType_Installation.equals(wotRec.OrderSubType__c)) {
            woli.PhysicalAsset__c = wotRec.PhysicalAsset__c;
        }

        //Karen Hung 06.12.2018 KTS-2388
        if(TS_Constants.ORDER_INSTYPE_INSTALLATION.equals(wotRec.OrderType__c)){
            woli.MachineCare__c = wotRec.Machine_Care__c; //Karen Hung 06.12.2018 KTS-2388
        }

        //Mapping for movement orders for external movement and movement of WOLI
        if (Label.TS_WOTOrderType_Movement.equals(wotRec.OrderType__c)) {
            woli.Movement__c = true;
            woli.ExternalMovement__c = wotRec.ExternalMovement__c;
        }

        //Check mapping for stop over and non-stop over items
        //if (wotRec.Stopover__c != null && wotRec.Stopover__c) {
        if (TS_Constants.WOLI_SBJDESC_PICKUP.equals(sbjDesc) || TS_Constants.WOLI_SBJDESC_DROPOFF.equals(sbjDesc)) {
            woli.Country__c = wotRec.StopoverCountry__c;
            woli.PostalCode__c = wotRec.StopoverPostalCode__c;
            woli.StreetAndHouseNumber__c = wotRec.StopoverStreetAndHouseNumber__c;
            woli.City__c = wotRec.StopoverCity__c;
            woli.Subject = sbjDesc;
            woli.Description = sbjDesc;
        } else {
            woli.DeInstall_NonJDEMachine__c = wotRec.DeInstall_NonJDEMachine__c;
            woli.RefurbishedMachine__c = wotRec.RefurbishedMachine__c;
            woli.CommercialMachine__c = wotRec.CommercialMachine__c;
            woli.StairNeeded__c = wotRec.StairClimber__c;
            woli.SmokingArea__c = wotRec.SmokingArea__c;
            woli.RequiresLSP__c = wotRec.Requires_LSP__c;
            woli.ConfigurationFileURL__c = wotRec.ConfigurationFileURL__c;
            woli.ConfigurationManualAgreementsURL__c = wotRec.ConfigurationManualAgreementsURL__c;
            woli.JDECrockeryVolumeSize__c = wotRec.JDE_crockeryVolumeSize__c;
            woli.IncludesWaterfilterCoverage__c = wotRec.IncludesWaterfilterCoverage__c;


            if (Label.TS_WOTOrderType_Conversion.equals(wotRec.OrderType__c)) {
                woli.OwnedByCustomer__c = wotRec.PhysicalAsset__r.OwnedByCustomer__c;
                woli.Subject = sbjDesc;
                woli.Description = sbjDesc;
            } else {
                woli.OwnedByCustomer__c = wotRec.OwnedByCustomer__c;
                woli.Subject = wotRec.Subject__c;
                woli.Description = wotRec.Description__c;
            }

            if (Label.TS_WOTOrderType_DeInstallation.equals(wotRec.OrderType__c) 
                || (Label.TS_WOTOrderType_Conversion.equals(wotRec.OrderType__c) 
                    && Label.TS_WOTOrderType_Installation.equals(wotRec.OrderSubType__c))) {
                woli.Building__c = wotRec.PhysicalAsset__r.Building__c;
                woli.Floor__c = wotRec.PhysicalAsset__r.Floor__c;
                woli.Area__c = wotRec.PhysicalAsset__r.Area__c;
                woli.CustomerReference__c = wotRec.PhysicalAsset__r.CustomerReferenceNumber__c;
            } else {
                woli.Building__c = wotRec.Building__c;
                woli.Floor__c = wotRec.Floor__c;
                woli.Area__c = wotRec.Area__c;
                woli.CustomerReference__c = wotRec.CustomerReference__c;
            }
        }

        if (wotRec.RequestedActivityDate__c != null) {
            Date newDate = wotRec.RequestedActivityDate__c;
            woli.EarlyStart__c = DateTime.newInstance(newDate.year(), newDate.month(), newDate.day(), 8, 0, 0);
            newDate = newDate + 4; //Add 4 days to reach Friday
            woli.SLADate__c = DateTime.newInstance(newDate.year(), newDate.month(), newDate.day(), 17, 0, 0);
        }

        CustomLogging.pop();  

        return woli;
    }

    /**
    * @author         Paul Jarred Aguiling
    * @date           01.10.2018   
    * @description    Method responsible for setting case values
    * @revision(s)
    */ 
    private Case createCaseRecords(WorkOrderTrigger__c wotRec, String cseorigin, String subtype, String cseType, 
                                   String status, Id caseRecTypeId, String caseExternalID) {
        CustomLogging.push('createCaseRecords', 'TS_SalesTriggerController');

        Case cse = new Case();
        cse.Origin = cseorigin; 
        cse.Type = cseType;
        cse.SubType__c = subtype;
        cse.Status = status;
        cse.Subject = wotRec.Subject__c;
        cse.Description = wotRec.Description__c;
        cse.SalesOrganization__c = wotRec.SalesOrganization__c;
        cse.ContactId = wotRec.ServiceContact__c;
        cse.IsProject__c = wotRec.IsProject__c;
        cse.ProjectNumber__c = wotRec.ProjectNumber__c != null? wotRec.ProjectNumber__c : null;
        cse.PickingDate__c = wotRec.PickingDate__c;
        cse.ScheduleManually__c = wotRec.ScheduleExceptions__c;
        cse.CaseExternalReference__c = caseExternalID;
        cse.LoadID__c = 'CASE-' + wotRec.Id;
        cse.ApptusOrder__c = wotRec.ParentOrder__c;
        cse.ChildOrder__c = wotRec.ChildOrder__c;
        cse.SecondaryContact__c = wotRec.AdditionalServiceContact__c;
        cse.WorkOrderTrigger__c = wotRec.Id;
        cse.PotentialRoundTrip__c = wotRec.PotentialRoundTrip__c;
        cse.PO_Number__c = wotRec.PO_Number__c;

        //XEN REYES Jan. 23, 2019 KTS-2196: This is to ensure that even if the default owner is Individual, the case will be routed to the correct queue.
        cse.AssignToQueue__c = true;
        cse.TS_IsGeneratedFromBatch__c = true;
        
        if (wotRec.RequestedActivityDate__c != null) {
            Date newDate = wotRec.RequestedActivityDate__c;
            cse.EarlyStartDate__c = DateTime.newInstance(newDate.year(), newDate.month(), newDate.day(), 8, 0, 0);
            newDate = newDate + 4; //Add 4 days to reach Friday
            cse.SLADate__c = DateTime.newInstance(newDate.year(), newDate.month(), newDate.day(), 17, 0, 0);
        }

        //Calculate Customer and LSP Schedule Dates
        CountrySetting__c countryScheduleDateTimeSettings = countryScheduleDateTimeSettingsMap.get(cse.SalesOrganization__c + '-' + wotRec.OrderType__c);
        CountrySetting__c countryDefaultBusinessHours = countryDefaultBusinessHoursMap.get(cse.SalesOrganization__c);
        System.debug(' ### cse.PickingDate__c ### ' + cse.PickingDate__c);
        System.debug(' ### cse.EarlyStartDate__c ### ' + cse.EarlyStartDate__c);
        System.debug(' ### countryScheduleDateTimeSettings ### ' + countryScheduleDateTimeSettings);
        System.debug(' ### countryDefaultBusinessHours ### ' + countryDefaultBusinessHours);
        if(countryScheduleDateTimeSettings != null && countryDefaultBusinessHours != null){
            cse.LSPScheduleDate__c = getLSPScheduleDate(cse, countryScheduleDateTimeSettings, countryDefaultBusinessHours);
            cse.CustomerScheduleDate__c = getCustomerScheduleDate(cse, countryScheduleDateTimeSettings, countryDefaultBusinessHours);

            System.debug(' ### cse.LSPScheduleDate__c ### ' + cse.LSPScheduleDate__c);
            System.debug(' ### cse.CustomerScheduleDate__c ### ' + cse.CustomerScheduleDate__c);
            
            //KTS-1935: Change the customer schedule and lsp date to today if calculated date is in the past - START
            
            //KTS-2257: Include equal to today in the criteria, not just greater than. XEN REYES Feb 11, 2019
            if (Date.today() >= cse.CustomerScheduleDate__c) {
                cse.ScheduleManually__c = true;
                cse.CustomerScheduleDate__c = TS_UtilityClass.getWorkingDate(countryDefaultBusinessHours.Business_Hours__c, Date.today());
            }

            //KTS-2257: Include equal to today in the criteria, not just greater than. XEN REYES Feb 11, 2019
            if (Date.today() >= cse.LSPScheduleDate__c) {
                Time lspScheduleTime = Time.newInstance(Integer.valueOf(countryScheduleDateTimeSettings.LSPScheduleTimeOffset__c), 0, 0, 0);
                Date lspSched = TS_UtilityClass.getWorkingDate(countryDefaultBusinessHours.Business_Hours__c, Date.today());
                cse.LSPScheduleDate__c = DateTime.newInstance(lspSched, lspScheduleTime);
            }
            //KTS-1935: Change the customer schedule and lsp date to today if calculated date is in the past - END
        }
        
        CustomLogging.pop();

        return cse;
    }

    /**
    * @author         Paul Jarred Aguiling
    * @date           03.07.2018   
    * @description    Method responsible for getting case owner id via assignment rule
    * @revision(s)
    */ 
    private static Map<Id, Case> getCaseOwnerId(List<Case> caseToInsert) {
        CustomLogging.push('getCaseOwnerId', 'TS_SalesTriggerController');
        Set<Id> cseIds = new Set<Id>();
        Map<Id, Case> caseMapWO = new Map<Id, Case>();
        //Iterate case Ids
        for (Case cse: caseToInsert) {
            cseIds.add(cse.Id);
        }

        //Query ownerId updated by assignment rule
        if (!cseIds.isEmpty()) {
            caseMapWO = new Map<Id, Case>([SELECT OwnerId, Owner.Name FROM Case WHERE Id IN :cseIds]);
        }

        CustomLogging.pop();
        return caseMapWO;
    }
    
    /**
    * @author         Adrian Reyes
    * @date           02.12.2018   
    * @description    Method to retrieve country schedule date/time settings
    * @revision(s)
    */ 
    public static Map<String,CountrySetting__c> getCountryScheduleDateTimeSettingsMap() {
        CustomLogging.push('getCountryScheduleDateTimeSettingsMap', 'TS_SalesTriggerController');

        Map<String,CountrySetting__c> countryScheduleDateTimeSettingsMap = new Map<String,CountrySetting__c>();
        for(CountrySetting__c countrySetting: [SELECT Country__c, OrderType__c, CustomerScheduleDateOffset__c, LSPScheduleDateOffset__c, LSPScheduleTimeOffset__c FROM CountrySetting__c WHERE RecordType.DeveloperName = 'CountryScheduleDateTimeSettings' AND Active__c = true])
            countryScheduleDateTimeSettingsMap.put(countrySetting.Country__c + '-' + countrySetting.OrderType__c, countrySetting);
        
        CustomLogging.pop();

        return countryScheduleDateTimeSettingsMap;
    }
    
    /**
    * @author         Adrian Reyes
    * @date           02.12.2018   
    * @description    Method to retrieve country default business hours
    * @revision(s)
    */ 
    public static Map<String,CountrySetting__c> getCountryDefaultBusinessHoursMap() {
        CustomLogging.push('getCountryDefaultBusinessHoursMap', 'TS_SalesTriggerController');
        Map<String,CountrySetting__c> countryDefaultBusinessHoursMap = new Map<String,CountrySetting__c>();

        for(CountrySetting__c countrySetting: [SELECT Country__c, Business_Hours__c FROM CountrySetting__c WHERE RecordType.DeveloperName = 'CountryDefaultBusinessHours' AND Active__c = true])
            countryDefaultBusinessHoursMap.put(countrySetting.Country__c, countrySetting);
        
        CustomLogging.pop();

        return countryDefaultBusinessHoursMap;
    }

    /**
    * @author         Abram Vixen Reyes
    * @date           Nov. 14, 2019
    * @description    Method to retrieve country scheduling rules
    * @revision(s)
    */ 
    public static Map<String, Map<Boolean, CountrySetting__c>> getCountrySchedulingRulesMap() {
        CustomLogging.push('getCountrySchedulingRulesMap', 'TS_SalesTriggerController');
        Map<String, Map<Boolean, CountrySetting__c>> countrySchedulingRulesMap = new Map<String, Map<Boolean, CountrySetting__c>>();

        for(CountrySetting__c countrySetting: [SELECT Country__c, DeliveryOffset__c, PickupOffset__c, RoundTrip__c FROM CountrySetting__c WHERE RecordType.DeveloperName = 'Country_Scheduling_Rules' AND Active__c = true]){
            if(countrySchedulingRulesMap.containsKey(countrySetting.Country__c)){
                if(!countrySchedulingRulesMap.get(countrySetting.Country__c).containsKey(countrySetting.RoundTrip__c)){
                    countrySchedulingRulesMap.get(countrySetting.Country__c).put(countrySetting.RoundTrip__c, countrySetting);
                }
            } else {
                Map<Boolean, CountrySetting__c> map_var = new Map<Boolean, CountrySetting__c>();
                map_var.put(countrySetting.RoundTrip__c, countrySetting);
                countrySchedulingRulesMap.put(countrySetting.Country__c, map_var);
            }
        }

        System.debug('countrySchedulingRulesMap: ' + countrySchedulingRulesMap);
        
        CustomLogging.pop();
        return countrySchedulingRulesMap;
    }
    
    /**
    * @author        Adrian Reyes
    * @date          02.12.2018           
    * @description   Method used to calculate Customer Schedule Date
    * @revision(s)
    */
    public static Date getCustomerScheduleDate(Case c, CountrySetting__c countryScheduleDateTimeSettings, CountrySetting__c countryDefaultBusinessHours) {
        CustomLogging.push('getCustomerScheduleDate', 'TS_SalesTriggerController');
        DateTime customerScheduleDate;
        Integer customerScheduleDateOffset = Integer.valueOf(countryScheduleDateTimeSettings.CustomerScheduleDateOffset__c);

        //This applies to all order types
        if (c.LSPScheduleDate__c != null) {
            customerScheduleDate = c.LSPScheduleDate__c;
        } else {
            return null;
        }
        
        DateTime nextStartDate = BusinessHours.nextStartDate(countryDefaultBusinessHours.Business_Hours__c, customerScheduleDate);
        customerScheduleDate = customerScheduleDate.date() != nextStartDate.date() ? BusinessHours.add(countryDefaultBusinessHours.Business_Hours__c, nextStartDate, -1000) : nextStartDate;
        customerScheduleDate = getPrevBusinessDay(countryDefaultBusinessHours.Business_Hours__c, customerScheduleDate, customerScheduleDateOffset);
        CustomLogging.pop();
        return customerScheduleDate.date();
    }


    /**
    * @author        Adrian Reyes
    * @date          02.12.2018           
    * @description   Method used to calculate LSP Schedule Date
    * @revision(s)
    */
    public static DateTime getLSPScheduleDate(Case c, CountrySetting__c countryScheduleDateTimeSettings, CountrySetting__c countryDefaultBusinessHours) {
        CustomLogging.push('getLSPScheduleDate', 'TS_SalesTriggerController');
        DateTime lspScheduleDate;

        Integer lspScheduleDateOffset = Integer.valueOf(countryScheduleDateTimeSettings.LSPScheduleDateOffset__c);
        if((c.SubType__c == Label.TS_Order_S40 || c.SubType__c == Label.TS_Case_SubType_Swap || c.SubType__c == Label.TS_WOTOrderType_Conversion) && c.PickingDate__c != null)
            lspScheduleDate =  c.PickingDate__c;
        else if((c.SubType__c == Label.TS_Order_S41 || c.SubType__c == Label.TS_Order_Instype_Movement || c.SubType__c == Label.TS_WOTOrderType_Conversion) && c.EarlyStartDate__c != null)
            lspScheduleDate = c.EarlyStartDate__c;
        else
            return null;
        
        DateTime nextStartDate = BusinessHours.nextStartDate(countryDefaultBusinessHours.Business_Hours__c, lspScheduleDate);
        lspScheduleDate = lspScheduleDate.date() != nextStartDate.date() ? BusinessHours.add(countryDefaultBusinessHours.Business_Hours__c, nextStartDate, -1000) : nextStartDate;
        lspScheduleDate = getPrevBusinessDay(countryDefaultBusinessHours.Business_Hours__c, lspScheduleDate, lspScheduleDateOffset);
        Time lspScheduleTime = Time.newInstance(Integer.valueOf(countryScheduleDateTimeSettings.LSPScheduleTimeOffset__c), 0, 0, 0);
        lspScheduleDate = DateTime.newInstance(lspScheduleDate.date(), lspScheduleTime);
        CustomLogging.pop();
        return lspScheduleDate;
    }


    /**
    * @author        Paul Jarred Aguiling
    * @date          3.27.2018           
    * @description   Method used to get business day
    * @revision(s)
    */
    public static DateTime getPrevBusinessDay(Id businessHoursId, DateTime targetDate, Integer offSet) {
        CustomLogging.push('getPrevBusinessDay', 'TS_SalesTriggerController');

        Integer newOffSet = offSet != null? offSet : 0;
        DateTime newTargetDate = targetDate; 

        //Use offset param to indicate the loop count
        for (Integer i = 1; i <= newOffSet; i++) {
            newTargetDate = newTargetDate.addDays(-1); //Deduct 1 day before calculating business day

            //Check for days falling on weekends in 24/7 business hours 
            if (Label.TS_SLA_Saturday.equals(TS_UtilityClass.getReadableDay(newTargetDate.date()))) {
                newTargetDate = newTargetDate.addDays(-1);
            } else if (Label.TS_SLA_Sunday.equals(TS_UtilityClass.getReadableDay(newTargetDate.date()))) {
                newTargetDate = newTargetDate.addDays(-2);
            } 

            //Check the working day after validating weekend dates
            while(!BusinessHours.isWithin(businessHoursId, newTargetDate)) {
                newTargetDate = newTargetDate.addDays(-1);
            }
        }

        CustomLogging.pop();
        return newTargetDate;
    }

    /**
    * @author        Paul Jarred Aguiling
    * @date          6.22.2018           
    * @description   Group the created task to be able to determine in CLICK using 
    *                the JDE Line Item Numnber stamped in GroupingIndicator__c
    * @revision(s)
    */
    public void updateChildWolisGrouping(List<WorkOrderLineItem> listOfAllWolis) {
        CustomLogging.push('updateChildWolisGrouping', 'TS_SalesTriggerController');
        List<WorkOrderLineItem> wolisToUpdate = new List<WorkOrderLineItem>();
        Set<Id> setOfIds = new Set<Id>();
        System.debug('listOfAllWolis size >>>>> ' + listOfAllWolis.size());  
        
        //Get the list of Ids to locate the first task craeted
        for (WorkOrderLineItem woli: listOfAllWolis) {
            setOfIds.add(woli.Id);
        }

        //Query the AutoNumber fields to get the generated value
        if (!setOfIds.isEmpty() && setOfIds.size() > 1) {
            List<WorkOrderLineItem> listOfAllWolis2 = [SELECT Id, LineItemNumber, WorkOrderLineItemNumber__c, JDELineItemNumber__c 
                                       FROM WorkOrderLineItem 
                                       WHERE Id IN :setOfIds 
                                       ORDER BY LineItemNumber];

            String lineNumber = '00000001';

            //Update the child wolis GroupingIndicator__c and stamp the parent woli JDELineItemNumber__c
            for (WorkOrderLineItem woli: listOfAllWolis2) {
                if (!lineNumber.equals(woli.LineItemNumber)) {
                    WorkOrderLineItem woliToUpdate = new WorkOrderLineItem();
                    woliToUpdate.Id = woli.Id;
                    woliToUpdate.GroupingIndicator__c = listOfAllWolis2.get(0).JDELineItemNumber__c;
                    wolisToUpdate.add(woliToUpdate);
                }
            }

            //Perform update on child wolis
            if (!wolisToUpdate.isEmpty()) {
                update wolisToUpdate;
            }
            
            System.debug('wolisToUpdate size >>>>> ' + wolisToUpdate.size());
        }

        CustomLogging.pop();
    }
}