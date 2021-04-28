public with sharing class WorkOrderLineItemList {
    
    public list<workorderlineitem> wolis {get;set;}
    public list<workorderlineitem> openWolis {get;set;}
    public list<workorderlineitem> closedWolis {get;set;}
    public boolean isOpen{get;set;}
    private ApexPages.StandardSetController ssc;
    public Map<String, String> picklistLabelMap { get;set;}
    public boolean hasWolis{get;set;}
    
    
    public WorkOrderLineItemList(){
        CustomLogging.push('WorkOrderLineItemList', 'WorkOrderLineItemList');
        
        hasWolis=false;
        picklistLabelMap = new Map<String, String>();
        Schema.DescribeFieldResult picklistDescribe = WorkOrderLineItem.WorkOrderType__c.getDescribe();
        List<PicklistEntry> entryList = picklistDescribe.getPicklistValues();
        for(PicklistEntry entry : entryList)
        {
            picklistLabelMap.put(entry.getValue(), entry.getLabel());
        }
        system.debug('picklistLabelMap is:'+picklistLabelMap);
        
        isOpen=true;
        dateTime EndDate;
        openWolis= new list<workorderlineitem>();
        closedWolis= new list<workorderlineitem>();
        wolis=[select id,workorderid,case__r.Account.name,startdate__c,LineItemNumber,AccountLocation__r.Shipping_Street_Only__c,AccountLocation__r.Shipping_House_Number__c,
               ParentWorkOrderLineItem.jdelineitemnumber__c, WorkOrderLineItemType__c,status,ExecutingEngineer__c,ExecutingEngineer__r.RelatedUser__c,jdelineitemnumber__c, 
               ParentWorkOrderLineItemId,LatestAppointmentTime__c,BookAppointmentFinish__c,SLADate__c,WorkOrderType__c,  toLabel(WorkOrderType__c) WorkOrderTypeLabel,
               OutsideSLA__c,description,subject
               from workorderlineitem
               where WorkOrderLineItemType__c='Task' and ExecutingEngineer__r.RelatedUser__c =: userinfo.getUserId() limit 20];
        system.debug('Wolis are:'+wolis);
        if(!wolis.isEmpty()){
            hasWolis=true;
            for(Workorderlineitem w:wolis){
                
                if(w.BookAppointmentFinish__c!=null){
                    EndDate=w.BookAppointmentFinish__c;
                }
                else if(w.LatestAppointmentTime__c!=null){
                    if(w.SLADate__c!=null && !w.OutsideSLA__c){
                        EndDate=w.SLADate__c;
                    }
                    else{
                        EndDate=w.LatestAppointmentTime__c;
                    }
                    
                }else if(w.SLADate__c!=null){
                    EndDate=w.SLADate__c;
                }
                //using the below fields just as placeholders to show formatted datetime values on the page. To avoid using a wrapper class.
                
                if(EndDate!=null){
                    w.description=EndDate.format('dd-MM-yyyy hh:mm');    
                }
                if(w.startDate__c!=null){
                    w.subject=w.startDate__c.format('dd-MM-yyyy hh:mm');
                }
                if(w.status!='Completed' && w.status!='Open' && w.status!='Canceled'){
                    openWolis.add(w);     
                }
                else if(w.status=='Completed'){
                    closedWolis.add(w);
                }
                system.debug('w is:'+w.id);
            }
        }
        
        CustomLogging.pop();
    }
}