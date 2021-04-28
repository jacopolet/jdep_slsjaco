public with sharing class TS_WorkOrderDocumentControllerSales {    
    public ContentDocumentLink signature {get; set;}
    public Attachment quoteSignature {get; set;}

    public List<ContentDocumentLink> signatureList {get; set;}
    
    public List<WorkOrderLineItem> woliRecords { get; set; }
    public List<WorkOrderLineItem> childwoliRecords { get; set; }

    public Double totalCost = 0;
    public String totalCostStr {get; set;}
    public static Boolean initialized = false;

    public Case caseRecord { get; set; }
    public String caseRecordId { 
        get;
        set {
            caseRecordId = value;
            if (!initialized) {
                initializeComponent();
                initialized = true;
            }
        }
    }
    
    public void initializeComponent() {        
        CustomLogging.push('initializeComponent', 'TS_WorkOrderDocumentControllerSales');
        
        List<String> validwoTypes = new List<String>{'S40', 'S41', 'S43'};
        Id taskId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Register Task').getRecordTypeId();

        System.debug('XEN caseRecordId: ' + caseRecordId);

        //GET CASE RECORD
        caseRecord = [SELECT Id, CaseNumber, toLabel(SubType__c), SignatureDepartmentPhone__c, SignatureDepartmentEmail__c, TS_TotalCostSales__c FROM Case WHERE Id =: caseRecordId];

        //GET TASK RECORDS
        woliRecords = [SELECT Id, toLabel(WorkOrderType__c), PhysicalAsset__r.SerialNumber__c, PhysicalAsset__r.ProductDescription__c, AccountLocation__r.Name, StartDate__c,WorkOrder.Account.Name, ExecutingEngineer__c, ExecutingEngineer__r.EmployeeFirstName__c,ExecutingEngineer__r.EmployeeLastName__c, Workquarters_Unit_Price__c, WorkQuarters__c, Labor_Cost__c, TS_Total_Cost_Labor_Price__c, TS_Total_Estimate_Labor_Price__c,Estimate_Work_Quarters__c,EstimateLabor__c,TotalCost__c,MaterialCost__c,SparePartCost__c,EstimateTotalCost__c,ExternalCompletionNote__c, Case__r.CaseNumber, Case__r.SignatureDepartmentPhone__c, Case__r.SignatureDepartmentEmail__c, toLabel(Case__r.SubType__c), JDELineItemNumber__c, toLabel(WorkOrderLineItemType__c) FROM WorkOrderLineItem WHERE Case__c =: caseRecordId AND WorkOrderType__c IN: validwoTypes AND RecordTypeId =: taskId];

        List<String> parentIdList = new List<String>();
        if(!woliRecords.isEmpty()){

        for(WorkOrderLineItem wo : woliRecords){
            System.debug(wo);
            parentIdList.add(wo.Id);
          }

          childwoliRecords = [SELECT Id, LineItemNumber, Product2.Name,tolabel(WorkOrderLineItemType__c), ParentWorkOrderLineItemId, ParentWorkOrderLineItem.JDELineItemNumber__c, TS_Sub_Total_Cost_Price__c, TS_Sub_Total_Estimated_Price__c, Unit_Price__c, Estimate_Quantity__c, EstimatePartCost__c, EstimateMaterialCost__c,IsLabour__c,EstimateTotalCost__c, Quantity, SparePartCost__c, MaterialCost__c, TotalCost__c FROM WorkOrderLineItem  WHERE ParentWorkOrderLineItemId IN: parentIdList AND (WorkOrderLineItemType__c = 'UsedSpareParts' OR (WorkOrderLineItemType__c = 'Service Materials')) AND IsReadyToSummarize__c = false ORDER BY WorkOrderLineItemType__c, CreatedDate];

          //CALCULATE TOTAL COST
          if(!childwoliRecords.isEmpty()){
            for(WorkOrderLineItem woli : childwoliRecords){
                totalCost = totalCost + (woli.TS_Sub_Total_Cost_Price__c == null ? 0 : woli.TS_Sub_Total_Cost_Price__c);
            }

            totalCostStr = String.valueOf(totalCost);
          }
        }
        
        /* if(!childWOLI.isEmpty()){          
            totalCost = 0;
            for(WorkOrderLineItem cw : childWOLI){
                if(cw.WorkOrderLineItemType__c == 'UsedSpareParts' && cw.EstimatePartCost__c != null){
                    totalCost = totalCost + double.valueOf(cw.EstimatePartCost__c);
                    
                }
                else if(cw.WorkOrderLineItemType__c == 'Service Materials' && cw.EstimateMaterialCost__c != null){
                    totalCost = totalCost + double.valueOf(cw.EstimateMaterialCost__c);
                }
            }
        } */
        
        
        try{            
            /* signatureList = [Select Name, Id, CreatedDate, ParentId from Attachment where (ParentId =: caseRecordId) and ((Name like '%signature%') and (NOT Name like '%quote%')) order by CreatedDate DESC limit 1]; */

            signatureList = [SELECT Id, ContentDocumentId, ContentDocument.LatestPublishedVersionId, ContentDocument.Title FROM ContentDocumentLink WHERE (LinkedEntityId =: caseRecordId OR LinkedEntityId IN: parentIdList) AND ContentDocument.Title LIKE '%signature%'];

            //XR 5.28.2018
            if(!signatureList.isEmpty()){
              signature = signatureList[0];
            }
            
        }
        catch(Exception e){
            system.debug(e.getMessage());
        }

        /* try{  
            quoteSignatureList = [Select Name, Id, CreatedDate, ParentId from Attachment where (ParentId = :woliRecord.Id) and  (Name like '%quote%') order by CreatedDate DESC limit 1];

            //XR 5.28.2018
            if(!quoteSignatureList.isEmpty()){
              quoteSignature = quoteSignatureList[0];
            }         
            
        }
        catch(Exception e){
            system.debug(e.getMessage());
        } */

        CustomLogging.pop();
    }
}