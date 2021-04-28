//-------------------------------------------------------------------------------------------//
// Author       :   Rey Austral
// Created Date :   Oct 13, 2017
// Usage        :   Class to generate the content of the cost estimate report, Controller for TS_CostEstimate and TS_WorkOrderOverview apex component
//-------------------------------------------------------------------------------------------//
public with sharing class TS_WorkOrderDocumentController {
    public List<WorkOrderLineItem> childWOLI {get; set;}
    
    public Attachment signature {get; set;}
    public Attachment quoteSignature {get; set;}

    //XR 5.28.2018
    public List<Attachment> signatureList {get; set;}
    public List<Attachment> quoteSignatureList {get; set;}

    public Boolean isSalesOrder {get; set;}

    public Double totalCost{get; set;}
    public static Boolean initialized = false;
    public WorkOrderLineItem labourRecord { get; set; }
    public WorkOrderLineItem woliRecord { get; set; }
    public String woliRecordId { 
        get; 
        set {
            woliRecordId = value;
            //woliRecordId = '1WL4E0000004qVLWAY';
            if (!initialized) {
                initializeComponent();
                initialized = true;
            }
        }
    }
    
    public void initializeComponent() {        
        CustomLogging.push('initializeComponent', 'TS_WorkOrderDocumentController');
        
        woliRecord = [SELECT Id,
                      toLabel(FaultLocationCategory__c),toLabel(FaultCode__c),toLabel(DefectCode__c),toLabel(CompletionCode__c),CustomerReference__c,Building__c,Floor__c,Area__c,AccountLocation__c,AccountLocation__r.Name,Description,ProductDescription__c,StartDate__c,WorkOrder.Account.Name,ExecutingEngineer__c,ExecutingEngineer__r.EmployeeFirstName__c,ExecutingEngineer__r.EmployeeLastName__c ,
                      Workquarters_Unit_Price__c, toLabel(Warranty__c), WorkQuarters__c, Labor_Cost__c, TS_Total_Cost_Labor_Price__c, TS_Total_Estimate_Labor_Price__c,
                      Estimate_Work_Quarters__c,EstimateLabor__c,TotalCost__c,MaterialCost__c,SparePartCost__c,EstimateTotalCost__c,ExternalCompletionNote__c, ListPrice, EndDate__c,
                      
                      //CASE COMPONENTS
                      Case__r.Subject,Case__r.CaseNumber, Case__r.SignatureDepartmentPhone__c, Case__r.SignatureDepartmentEmail__c, toLabel(Case__r.SubType__c), Case__r.PO_Number__c,

                      //ADDITIONAL PHYSICAL ASSET FIELDS
                      PhysicalAsset__r.Building__c, PhysicalAsset__r.Floor__c, PhysicalAsset__r.Area__c, PhysicalAsset__r.SerialNumber__c,PhysicalAsset__r.CustomerReferenceNumber__c,
                      
                      //CONTACT RELATED
                      Contact_Salutation__c, ContactLastName__c

                      FROM WorkOrderLineItem WHERE Id =: woliRecordId]; 
        
        childWOLI = [SELECT Id, LineItemNumber,toLabel(Warranty__c), Product2.Name,tolabel(WorkOrderLineItemType__c),
                     ParentWorkOrderLineItemId, TS_Sub_Total_Cost_Price__c, TS_Sub_Total_Estimated_Price__c, CurrencyIsoCode,

                     //FOR COST ESTIMATE (N/A)
                     Unit_Price__c, Estimate_Quantity__c, EstimatePartCost__c, EstimateMaterialCost__c, IsLabour__c,EstimateTotalCost__c,

                     //FOR FINAL COST TABLE
                     Quantity, SparePartCost__c, MaterialCost__c, TotalCost__c, ListPrice, UnitPrice

                     FROM WorkOrderLineItem 
                     WHERE ParentWorkOrderLineItemId = : woliRecord.Id
                     AND (WorkOrderLineItemType__c = 'UsedSpareParts' OR (WorkOrderLineItemType__c = 'Service Materials')) and IsReadyToSummarize__c = false
                     ORDER BY WorkOrderLineItemType__c, CreatedDate];

        if(!childWOLI.isEmpty()){          
            totalCost = 0;

            for(WorkOrderLineItem cw : childWOLI){

                if(cw.WorkOrderLineItemType__c == 'Used parts' && cw.TS_Sub_Total_Cost_Price__c != null){
                    totalCost = totalCost + double.valueOf(cw.TS_Sub_Total_Cost_Price__c);

                } else if(cw.WorkOrderLineItemType__c == 'Service Materials' && cw.TS_Sub_Total_Cost_Price__c != null){
                    totalCost = totalCost + double.valueOf(cw.TS_Sub_Total_Cost_Price__c);
                }
                
                /* if(cw.WorkOrderLineItemType__c == 'Service Materials' && cw.IsLabour__c){
                    labourRecord = cw;
                } */
            }
        }
      
        try{            
            signatureList = [Select Name, Id, CreatedDate, ParentId from Attachment where (ParentId = :woliRecord.Id) and ((Name like '%signature%') and (NOT Name like '%quote%')) order by CreatedDate DESC limit 1];
            if(!signatureList.isEmpty()){
              signature = signatureList[0];
            }
            
        } catch(Exception e){
            system.debug(e.getMessage());
        }

        try{  
            quoteSignatureList = [Select Name, Id, CreatedDate, ParentId from Attachment where (ParentId = :woliRecord.Id) and  (Name like '%quote%') order by CreatedDate DESC limit 1];
            if(!quoteSignatureList.isEmpty()){
              quoteSignature = quoteSignatureList[0];
            }         
            
        } catch(Exception e){
            system.debug(e.getMessage());
        }

        CustomLogging.pop();
    }
}