/**
* @author        Paul Jarred Aguiling
* @date          5.24.2018        
* @description   KTS-1715: Controller class for TS_CreateOrderReqPartsAndSvcMaterials lightning component.
* @revision(s)
*/
public with sharing class TS_CreateOrderSvcPartsController {

    public static Map<String, String> mapWarranty = new Map<String, String>();
    
    /**
    * @author         Paul Jarred Aguiling
    * @date           05.24.2018
    * @description    Method responsible for getting billing info picklist values
    * @revision(s)
    */ 
    @AuraEnabled
    public static List<String> fetchPicklistValues(String objectName, String fieldAPI) {
        CustomLogging.push('fetchPicklistValues', 'TS_CloseTaskWOLIController');
        List<String> labelValueList = new List<String>();
        Schema.DescribeSObjectResult sobjectType = Schema.getGlobalDescribe().get(objectName).getDescribe();
        Schema.DescribeFieldResult sObjectResult = sobjectType.fields.getMap().get(fieldAPI).getDescribe();
        List<Schema.PicklistEntry> pick_list_values = sObjectResult.getPickListValues();
        for (Schema.PicklistEntry a : pick_list_values) {
            labelValueList.add(a.getLabel());
            mapWarranty.put(a.getLabel(), a.getValue());
        }
        CustomLogging.pop();
        return labelValueList;
    }

    /**
    * @author         Paul Jarred Aguiling
    * @date           05.24.2018
    * @description    Wrapper class responsible for mapping list of records returned from client side
    * @revision(s)
    */ 
    public class WorkOrderLineItemWrapperClass {
        public String partType;
        public Boolean existing;
        public Boolean directTo;  
        public String woPBId;
        public String taskpbEntryId;
        public String matType;
        public Integer quantity;
        public PriceBookEntry wolipbEntry;
        public String billingInfo;
    }

    /**
    * @author         Paul Jarred Aguiling
    * @date           05.24.2018
    * @description    Method responsible for generating WO and WOLI
    * @revision(s)
    */ 
    @AuraEnabled
    public static String convertOrderServer(String recordId, String woliList){
        CustomLogging.push('convertOrderServer', 'TS_CreateOrderSvcPartsController');
        System.debug('convertOrderServer');

        String result = 'SUCCESS';
        List<WorkOrder> woToInsert = new List<WorkOrder>();
        List<WorkOrderLineItem> parentWoliToInsert = new List<WorkOrderLineItem>(); 
        List<WorkOrderLineItem> childWoliToInsert = new List<WorkOrderLineItem>();
        List<TS_CreateOrderSvcPartsController.WorkOrderLineItemWrapperClass> listWoli = 
                (List<TS_CreateOrderSvcPartsController.WorkOrderLineItemWrapperClass>) System.JSON.deserialize(woliList, List<TS_CreateOrderSvcPartsController.WorkOrderLineItemWrapperClass>.Class);

        //Check if client work order line item list is not empty
        if (listWoli != null && listWoli.size() > 0) {
            //Retrieve API value for Warranty picklist field
            fetchPicklistValues('WorkOrderLineItem', 'Warranty__c');

            try {
                //Retrieve case record
                Case caseRec = getCaseRecord(recordId);

	            //Update parent case record
	            caseRec.Status = Label.TS_Status_InProgress;
	            caseRec.CaseSubStatus__c = 'Order Open';
	            caseRec.CreatedOrderedManually__c = true;
                caseRec.AddRequiredPartsandMaterials__c = true;
                caseRec.SLARecalculation__c = true; //DOO-5274 XEN REYES - Jan. 26, 2020
	            update caseRec;

                //TO CAPTURE OWNER ID CHANGE
                Case caseRec2 = getCaseRecord(recordId);

                //Create and insert work order record
                WorkOrder wo = new WorkOrder();
                wo.CaseId = caseRec.Id;
                wo.PriceBook2Id = listWoli.get(0).woPBId;
                wo.SalesOrganization__c = caseRec.SalesOrganization__c;
                wo.OwnerID = caseRec2.OwnerId;
                wo.Status = Label.TS_Status_Open;
                woToInsert.add(wo);
                System.debug(wo);
                insert wo;

                //Create and insert work order line item record type task
                WorkOrderLineItem parentWoli = createWorkOrderLineItem(Label.TS_Type_Task, caseRec.SubType__c, listWoli.get(0).taskpbEntryId, caseRec, null);
                parentWoli.Case__c = wo.CaseId;
                parentWoli.WorkOrderId = wo.Id;

                //when there's a required parts we need to indicate the task woli to be scheduled manually 
                for (TS_CreateOrderSvcPartsController.WorkOrderLineItemWrapperClass wrapper: listWoli) {
					if (Label.TS_Type_ReqSpareparts.equals(wrapper.partType)) {
						parentWoli.ScheduleManually__c = true;
						break;
					}
				}

                insert parentWoli;

                //Create and insert work order line item records for service materials and required parts
                for (TS_CreateOrderSvcPartsController.WorkOrderLineItemWrapperClass wrapper: listWoli) {
                    WorkOrderLineItem childWoli = createWorkOrderLineItem(wrapper.partType, caseRec.SubType__c, wrapper.wolipbEntry.Id, null, wrapper);
                    childWoli.Case__c = parentWoli.Case__c;
                    childWoli.WorkOrderId = parentWoli.WorkOrderId;
                    childWoli.ParentWorkOrderLineItemId = parentWoli.Id;
                    childWoliToInsert.add(childWoli);
                }

                if (!childWoliToInsert.isEmpty()) { 
                    insert childWoliToInsert;

                    //Set the flagging field pf the task to activate creation of integration log 
                    //that includes the sub wolis/service materials and required parts
                    parentWoli.AddPartsandMaterialsIntegration__c = true;
                    update parentWoli;
                }

            } catch(Exception ex) {
                CustomLogging.debugException(ex);
                CustomLogging.pop();
                System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());

                String err = ex.getMessage();
                return err.substringAfter(',');
            }
        }
            
        CustomLogging.pop();
        return result;
    }

    /**
    * @author         Paul Jarred Aguiling
    * @date           05.28.2018   
    * @description    Method responsible for setting work order line item values
    * @revision(s)
    */ 
    private static WorkOrderLineItem createWorkOrderLineItem(String woliType, String woType, 
                                                      String pbEntryId, Case caseRec,
                                                      TS_CreateOrderSvcPartsController.WorkOrderLineItemWrapperClass wrapper) {
        CustomLogging.push('createWorkOrderLineItem', 'TS_CreateOrderSvcPartsController');

        WorkOrderLineItem woli = new WorkOrderLineItem();
        woli.Status = Label.TS_Status_Open;
        woli.WorkOrderLineItemType__c = woliType;
        woli.PricebookEntryId = pbEntryId;
        //woli.WorkOrderType__c = type; //Karen Hung May 6, 2019 DOO-125 

        //Map fields for Required Parts
        if (Label.TS_Type_ReqSpareparts.equals(woliType)) {
            woli.RecordTypeId = TS_UtilityClass.getRecordTypeIdByName(Label.TS_Obj_API_Name_WOLI, Label.TS_WOLI_RecordType_RegReqPart);
            woli.Warranty__c = mapWarranty.get(wrapper.billingInfo) != null? mapWarranty.get(wrapper.billingInfo) : null;
            woli.Quantity = wrapper.quantity;
            woli.AddPartsandMaterialsIntegration__c = true;
            
            //DOO-4769 XEN REYES August 18, 2020
            woli.DirectToCustomer__c = wrapper.directTo;

        //Map fields for Service Materials
        } else if (Label.TS_Type_Service_Materials.equals(woliType)) {
            woli.RecordTypeId = TS_UtilityClass.getRecordTypeIdByName(Label.TS_Obj_API_Name_WOLI, Label.TS_WOLI_RecordType_RegServMat);
            woli.Warranty__c = mapWarranty.get(wrapper.billingInfo) != null? mapWarranty.get(wrapper.billingInfo) : null;
            woli.Quantity = wrapper.quantity;
            woli.AddPartsandMaterialsIntegration__c = true;
        //Map fields for Task
        } else if (Label.TS_Type_Task.equals(woliType)) {
            woli.AccountLocation__c = caseRec.AccountLocation__c;
            woli.AlternativeMachine__c = caseRec.AlternativeMachine__c;
            woli.BookAppointmentFinish__c = caseRec.BookingAppointmentFinish__c;
            woli.BookAppointmentStart__c = caseRec.BookingAppointmentStart__c;
            woli.Description = caseRec.Description;
            woli.EarliestAppointmentTime__c = caseRec.EarliestAppointmentTime__c;
            woli.EarlyStart__c = caseRec.EarlyStartDate__c;
            woli.ExcludedEngineer__c = caseRec.AccountLocation__c != null? caseRec.AccountLocation__r.ExcludedEngineer__c : null;
            woli.PreferredEngineer__c = caseRec.AccountLocation__c != null? caseRec.AccountLocation__r.PreferredEngineer__c : null;
            woli.IgnoreCalendar__c = caseRec.IgnoreCalendar__c;
            woli.IsCoffeeRunning__c = caseRec.CoffeeIsRunning__c;
            woli.LatestAppointmentTime__c = caseRec.LatestAppointmentDate__c;
            woli.PhysicalAsset__c = caseRec.PhysicalAsset__c;
            woli.RepeatVisit__c = caseRec.RepeatVisit__c;
            woli.RequiredEngineer__c = caseRec.RequiredEngineer__c;
            woli.SLADate__c = caseRec.SLADate__c;
            woli.Subject = caseRec.Subject;
            woli.Created_Manually__c = true;
            woli.WorkOrderType__c = woType; //Karen Hung May 6, 2019 DOO-125 
        }

        CustomLogging.pop();  
        return woli;
    }

    /**
    * @author         Paul Jarred Aguiling
    * @date           05.28.2018   
    * @description    Method responsible for getting the case record
    * @revision(s)
    */ 
    private static Case getCaseRecord(String recId) {
        CustomLogging.push('getCaseRecord', 'TS_CreateOrderSvcPartsController');

        Case casrec = [SELECT Id, SubType__c,
        					 SalesOrganization__c,
                              AccountLocation__c, 
                              AlternativeMachine__c,
                              BookingAppointmentFinish__c,
                              BookingAppointmentStart__c,
                              Description,
                              EarliestAppointmentTime__c,
                              EarlyStartDate__c,
                              AccountLocation__r.ExcludedEngineer__c,
                              AccountLocation__r.PreferredEngineer__c,
                              IgnoreCalendar__c,
                              CoffeeIsRunning__c,
                              LatestAppointmentDate__c,
                              PhysicalAsset__c,
                              RepeatVisit__c,
                              RequiredEngineer__c,
                              SLADate__c,
                              ScheduleManually__c,
                              Subject,
                              OwnerId,
                              RecordType.DeveloperName
                       FROM Case WHERE Id = :recId LIMIT 1];
        
        CustomLogging.pop();  
        return casrec;
    }

    /**
    * @author         Paul Jarred Aguiling
    * @date           05.24.2018
    * @description    Method responsible for getting the pricebookentry Id
    * @revision(s)
    */ 
    @AuraEnabled
    public static Object retrievePricebookEntry(String salesOrg, String productId) {
        CustomLogging.push('retrievePricebook', 'TS_CreateOrderSvcPartsController');

        try {
            //Collect all price book entry based on sales org of case record
            PriceBookEntry pbe = [SELECT Id, PriceBook2Id, Product2Id 
                              FROM PriceBookEntry WHERE Sales_Organization__c = :salesOrg
                              AND Product2Id = :productId
                              AND IsActive = true LIMIT 1];

            return pbe;
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }

        CustomLogging.pop();
        return null;
    }
}