public with sharing class TS_CloseTaskController {
    /**
    * @author        Shashank Shekhar
    * @date          6.21.2017           
    * @description   Class primarily responsible in Task closure activity through a Work Order Line Item or Case
    * @revision(s)
    */
    
    public list < WorkOrderLineItem > lst_WOLI {
        get;
        set;
    }
    
    public integer upSize {
        get;
        set;
    }
    public WorkOrderLineItem woli {
        get;
        set;
    }
    public string PriceBookId {
        get;
        set;
    }
    public string productName {
        get;
        set;
    }
    public string RTType {
        get;
        set;
    }
    public integer rowNum {
        get;
        set;
    }
    public Boolean showParts {
        get;
        set;
    }
    public Boolean redirect {
        get;
        set;
    }
    public Boolean hideParts {
        get;
        set;
    }
    public string rType {
        get;
        set;
    }
    public Boolean showMachine {
        get;
        set;
    }
    public list < SelectOption > ActionType {
        get;
        set;
    }
    public string[] selectedKey {
        get;
        set;
    }
    public string NEN3140 {
        get;
        set;
    }
    public string LMRA {
        get;
        set;
    }
    public string HACCP {
        get;
        set;
    }
    public list < WorkOrderLineItem > lst_ServiceMaterial {
        get;
        set;
    }
    public datetime startTime {
        get;
        set;
    }
    public datetime stopTime {
        get;
        set;
    }
    public datetime travelStartTime {
        get;
        set;
    }
    public datetime travelStopTime {
        get;
        set;
    }

    //Constructor to be used when the page is called from the WOLI related list on Case. Same as the standard consutructor.
    public TS_CloseTaskController() {
        string WoliId = ApexPages.currentPage().getParameters().get('Id');
        //Assigns WOLI.Id to WOLIID if the page is called through Case.
        if (WoliId != null && !WoliId.startsWith('1WL')) {
            WoliId = ApexPages.currentPage().getParameters().get('woliId');
        }

        Woli = new WorkOrderLineItem();
        lst_ServiceMaterial = new list < workOrderLineItem > ();
        rowNum = 0;
        HACCP = '0';
        LMRA = '0';
        NEN3140 = '0';
        gotoPartDetails();
        ActionType = new list < SelectOption > ();
        ActionType.add(new SelectOption('Boiler Descaled', 'Boiler Descaled'));
        ActionType.add(new SelectOption('Valves/gaskets Replacement', 'Valves/gaskets Replacement'));
        ActionType.add(new SelectOption('Customer Instructed', 'Customer Instructed'));
        ActionType.add(new SelectOption('Service Check', 'Service Check'));

        string SMrecordTypeId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Register Service Material').getRecordTypeId();
        if (WoliId != null && WoliId.startsWith('1WL')) {
            woli = [SELECT id, ExecutingEngineer__c, Case__c, case__r.CaseNumber, WorkOrderId, IsCoffeeRunning__c, reviewneeded__c, 
                            ReturnNeeded__c, OpportunityType__c, OpportunitySubType__c, CompletionCode__c, ExternalCompletionNote__c, InternalCompletionNote__c, 
                            CommercialNote__c, WorkOrder.Pricebook2Id, workOrder.WorkOrderNumber, FaultCode__c, Defectcode__c, ExecutingEngineer__r.name, workQuarters__c, 
                            PhysicalLocation__c, WTSperformed__c, PreventiveMaintenanceDone__c, Machinenotes__c, IntervalWTS__c, WorkOrderType__c, 
                            ActionType__c,CoffeeRunsAfterVisit__c,CoffeeRunsUponArrival__c
            FROM WorkOrderLineItem where id = :WoliId];
            PriceBookId = woli.WorkOrder.Pricebook2Id;
            lst_ServiceMaterial = [select id, MaterialCost__c, pricebookentryId, 
                                    //pricebookentry.ProductNamehidden__c, 
                                    quantity, warranty__c from WorkOrderLineItem where ParentWorkOrderLineItemId = :WoliId and recordTypeId = :SMrecordTypeId];

        }

        upSize = 0;
        lst_WOLI = new list < WorkOrderLineItem > ();
    }
    
    //Method called on click of one of the buttons to Add Used parts, Missing parts and Service Materials
    //Everytime a button is clicked, a new WOLI record is instantiated and added in the list lst_WOLI.
    public void updateNumberOfParts() {
        string s = Apexpages.currentPage().getParameters().get('upSize');
        //rType is Coming from the page and is set based on the buttons clicked.
        rType = ApexPages.currentPage().getParameters().get('RTType');
        String ProdRecordTypeId;

        if (rType != null) {
            if (rType == 'UsedPart') ProdRecordTypeId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Register Used Part').getRecordTypeId();
            else if (rType == 'MissingPart') ProdRecordTypeId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Register Missing Part').getRecordTypeId();
            else if (rType == 'ServiceMaterial') ProdRecordTypeId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Register Service Material').getRecordTypeId();
        }
        if (s != null && s != '') {
            upsize = Integer.valueOf(s);
            if (upSize != 0 && upSize != null) {
                integer size = upSize - lst_WOLI.size();
                for (integer i = 0; i < size; i++) {
                    WorkOrderLineItem w = new WorkOrderLineItem();
                    if (upSize != 1) {
                        //using description field on the WOLI as a placeholder to show ProductName which is linked already. To avoid Wrapper class
                        lst_WOLI[lst_WOLI.size() - 1].description = Apexpages.currentPage().getParameters().get('productName');
                        if (lst_WOLI[lst_WOLI.size() - 1].pricebookentryId == null) {
                        }
                    }
                    if (rType != null) {
                        if (rType == 'UsedPart') {
                            w.subject = 'Used Part';
                        } else if (rType == 'MissingPart') {
                            w.subject = 'Missing Part';
                        } else if (rType == 'ServiceMaterial') {
                            w.subject = 'Service Material';
                        }
                        w.RecordTypeId = ProdRecordTypeId;
                    }
                    lst_WOLI.add(w);
                }
            }
        }
    }
    //Standard Constructor to be used when the page is called from the 'close task' quickAction on WOLI. Same as the default consutructor.
    public TS_CloseTaskController(ApexPages.StandardController controller) {
        Woli = new WorkOrderLineItem();
        lst_ServiceMaterial = new list < workOrderLineItem > ();
        rowNum = 0;
        HACCP = '0';
        LMRA = '0';
        NEN3140 = '0';
        startTime = system.Now();
        stopTime = System.Now();
        gotoPartDetails();
        string WoliId = ApexPages.currentPage().getParameters().get('Id');
        ActionType = new list < SelectOption > ();
        ActionType.add(new SelectOption('Boiler Descaled', 'Boiler Descaled'));
        ActionType.add(new SelectOption('Valves/gaskets Replacement', 'Valves/gaskets Replacement'));
        ActionType.add(new SelectOption('Customer Instructed', 'Customer Instructed'));
        ActionType.add(new SelectOption('Service Check', 'Service Check'));
        
        string SMrecordTypeId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Register Service Material').getRecordTypeId();
        //Looks for all the service materials which are already associated to the WOLI and collect in lst_ServiceMaterial.
        if (WoliId != null && WoliId.startsWith('1WL')) {
            woli = [SELECT id, ExecutingEngineer__c, Case__c, case__r.CaseNumber, WorkOrderId, IsCoffeeRunning__c, reviewneeded__c, 
                            ReturnNeeded__c, OpportunityType__c, OpportunitySubType__c, CompletionCode__c, ExternalCompletionNote__c, InternalCompletionNote__c, 
                            CommercialNote__c, WorkOrder.Pricebook2Id, workOrder.WorkOrderNumber, FaultCode__c, Defectcode__c, ExecutingEngineer__r.name, workQuarters__c, 
                            PhysicalLocation__c, WTSperformed__c, PreventiveMaintenanceDone__c, Machinenotes__c, IntervalWTS__c, WorkOrderType__c, 
                            ActionType__c,CoffeeRunsAfterVisit__c,CoffeeRunsUponArrival__c
            FROM WorkOrderLineItem where id = :WoliId];
            PriceBookId = woli.WorkOrder.Pricebook2Id;
            lst_ServiceMaterial = [select id, MaterialCost__c, pricebookentryId, 
                                   //pricebookentry.ProductNamehidden__c, 
                                   quantity, warranty__c 
                                   from WorkOrderLineItem where ParentWorkOrderLineItemId = :WoliId and recordTypeId = :SMrecordTypeId];

        }

        upSize = 0;
        lst_WOLI = new list < WorkOrderLineItem > ();
    }
    
    //Method called on click of Save and Close button on the page. It will save all the chil wolis and then save the original parent WOLI
    public pageReference CreateWolis() {
        List < WorkOrderLineItem > WOLIsToBeCreated = new List < WorkOrderLineItem > ();
        list < WorkOrderLineItem > updateSMWOLIs = new list < WorkOrderLineItem > ();
        pageReference pr = new PageReference('/' + woli.Id);
        if (startTime != null && stopTime != null) {
            Integer actualhours = Integer.valueOf((stopTime.getTime()) - startTime.getTime()) * 24;
            woli.actualduration__c = actualhours;
        }
        if (travelstartTime != null && travelstopTime != null) {
            Integer actualTravelHours = Integer.valueOf((travelstopTime.getTime()) - travelstartTime.getTime()) * 24;
            woli.ActualTravelTime__c = actualTravelHours;
        }
        //---- Archi added (7 November 2017):add dummy woli to trigger summary report and send email for task closure notification to customer --//
        
      //  if (woli !=null) addDummyWOLI2SMlist(woli);

        //---end Archi update ---//

        woli.status = 'Completed';
        if (!lst_WOLI.isEmpty()) {
            for (WorkOrderLineItem w: lst_WOLI) {
                if (w.pricebookentryId != null) {
                    w.WorkOrderId = woli.WorkOrderId;
                    w.Case__c = woli.Case__c;
                    w.ParentWorkOrderLineItemId = woli.id;
                    w.description = null;
                    w.status='Completed';
                    w.subject = null;
                    WOLIsToBeCreated.add(w);
                }
            }
            if (!lst_ServiceMaterial.isEmpty()) {
                for (WorkOrderLineItem wSM: lst_ServiceMaterial) {
                    updateSMWOLIs.add(wSM);
                }
                update updateSMWOLIs;
            }
            
            if (!WOLIsToBeCreated.isEmpty()) {
                insert WOLIsToBeCreated;
            }
            update woli;
        }
        pr.setredirect(true);
        return pr;
    }
    
    //Method used to remove a row of WOLI getting created by click of the buttons like Add Used Part/Missing Part or Service Material.
    //rowNo tell which row needs to be removed.
    public void remove() {
        string r = ApexPages.currentPage().getParameters().get('rowNo');
        if (r != null && lst_WOLI.size() >= Integer.valueOf(r)) {
            if (lst_WOLI[lst_WOLI.size() - 1].pricebookentryId != null) {}
            WorkOrderLineItem w = lst_WOLI.remove(Integer.valueOf(r) - 1);
            upSize = lst_WOLI.size();
        }
    }
/*
    //add dummy woli to service material list
    private void addDummyWOLI2SMlist(workOrderLineItem parentWoli) {
        string SMrecordTypeId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Register Service Material').getRecordTypeId();
        //create a dummy SM
        workOrderLineItem dummyWOLI = new workOrderLineItem ();
        dummyWOLI.recordTypeId = SMrecordTypeId;
        dummyWOLI.WorkOrderId = parentWoli.WorkOrderId;
        dummyWOLI.Case__c = parentWoli.Case__c;
        dummyWOLI.ParentWorkOrderLineItemId = parentWoli.id;
        dummyWOLI.description = null;
        dummyWOLI.status='Completed';
        dummyWOLI.subject = null;
        dummyWOLI.IsReadyToSummarize__c=true;
        lst_ServiceMaterial.add(dummyWOLI);
    }
    */
    //Navigates to the Machine Action page
    public void gotoMachineDetails() {
        showMachine = true;
        showParts = false;
        hideParts = false;
    }
    
    //Navigates to the Task Closure page
    public void gotoTaskClosure() {
        showMachine = false;
        redirect = false;
        hideParts = true;
    }
    
    //Navigates to the add Parts page
    public void gotoPartDetails() {
        showParts = true;
        hideParts = false;
        showMachine = false;
    }

}