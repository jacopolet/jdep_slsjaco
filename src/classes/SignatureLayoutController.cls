/*
Created by: Harold Marilag
Date: 7/28/2017
Description: Extension class for CostEstimate and Work Order Overview VF Page

*/
public with sharing class SignatureLayoutController {
    
    
    public WorkOrderLineItem woli { get; set; }
    public WorkOrderLineItem woliRecord { get; set; }
    private ApexPages.StandardSetController controller;
    public List<WorkOrderLineItem> childWOLI {get; set;}
    public Attachment signature {get; set;}
    public Attachment quoteSignature {get; set;}
    public Double totalCost{get; set;}
    
    public SignatureLayoutController(ApexPages.StandardController controller) {
        CustomLogging.push('SignatureLayoutController', 'SignatureLayoutController');
        woli = (WorkOrderLineItem)controller.getRecord(); 
        // woli = [Select Id, LineItemNumber from WorkOrderLineItem where Id = :woli.Id];
        
        childWOLI = [Select Id, LineItemNumber, Product2.Name, Quantity, WorkOrderLineItemType__c, EstimateMaterialCost__c, EstimatePartCost__c, MaterialCost__c, 
                     SparePartCost__c, EstimateTotalCost__c, TotalCost__c, ParentWorkOrderLineItemId from WorkOrderLineItem 
                     where ParentWorkOrderLineItemId = :woli.Id
                     and (WorkOrderLineItemType__c = 'UsedSpareParts' or WorkOrderLineItemType__c = 'Service Materials')];
        if(!childWOLI.isEmpty()){
            /*
try{            
// updated by Archi 4-oct 2017 
//signature = [Select Name, Id, CreatedDate, ParentId from Attachment where (ParentId = :woli.Id) and ((Name = :INT_Constants.CLICK_SIGNATUREFILE) OR ((Name like '%signature%') and (NOT Name like '%quote%'))) order by CreatedDate DESC limit 1];
signature = [Select Name, Id, CreatedDate, ParentId from Attachment where (ParentId = :woli.Id) and (Name like '%signature%') order by CreatedDate DESC limit 1];

}
catch(Exception e){
system.debug(e.getMessage());
}
try{  
//replaced by Archi 4-oct 2017 
//quoteSignature = [Select Name, Id, CreatedDate, ParentId from Attachment where (ParentId = :woli.Id) and ((Name = :INT_Constants.CLICK_QUOTESIGNATUREFILE) OR ((Name like '%signature%') and (Name like '%quote%'))) order by CreatedDate DESC limit 1];
quoteSignature = [Select Name, Id, CreatedDate, ParentId from Attachment where (ParentId = :woli.Id) and  (Name like '%quote%') order by CreatedDate DESC limit 1];          

}
catch(Exception e){
system.debug(e.getMessage());
}

*/  
            totalCost = 0;
            for(WorkOrderLineItem cw : childWOLI){
                if(cw.WorkOrderLineItemType__c == 'UsedSpareParts' && cw.EstimatePartCost__c != null){
                    totalCost = totalCost + double.valueOf(cw.EstimatePartCost__c);
                    
                }
                else if(cw.WorkOrderLineItemType__c == 'Service Materials' && cw.EstimateMaterialCost__c != null){
                    totalCost = totalCost + double.valueOf(cw.EstimateMaterialCost__c);
                }
            }
        }
        else{
            //childWOLI.add(new WorkOrderLineItem());
        }
        //moved by Archi  Archi 4-oct 2017 
        try{            
            // updated by Archi 4-oct 2017 
            //signature = [Select Name, Id, CreatedDate, ParentId from Attachment where (ParentId = :woli.Id) and ((Name = :INT_Constants.CLICK_SIGNATUREFILE) OR ((Name like '%signature%') and (NOT Name like '%quote%'))) order by CreatedDate DESC limit 1];
            signature = [Select Name, Id, CreatedDate, ParentId from Attachment where (ParentId = :woli.Id) and ((Name like '%signature%') and (NOT Name like '%quote%')) order by CreatedDate DESC limit 1];
            
        }
        catch(Exception e){
            system.debug(e.getMessage());
        }
        try{  
            //replaced by Archi 4-oct 2017 
            // quoteSignature = [Select Name, Id, CreatedDate, ParentId from Attachment where (ParentId = :woli.Id) and ((Name = :INT_Constants.CLICK_QUOTESIGNATUREFILE) OR ((Name like '%signature%') and (Name like '%quote%'))) order by CreatedDate DESC limit 1];
            quoteSignature = [Select Name, Id, CreatedDate, ParentId from Attachment where (ParentId = :woli.Id) and  (Name like '%quote%') order by CreatedDate DESC limit 1];          
            
        }
        catch(Exception e){
            system.debug(e.getMessage());
        }
        CustomLogging.pop();
    }
    
    
    
}