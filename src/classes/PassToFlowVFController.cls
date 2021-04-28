////
////    Glenn Serrano
////    Nov. 20, 2019 Apex for VF Page
////
public without sharing class PassToFlowVFController {
    
    public string[] SelectedIDs{get;set;}
    
    public PassToFlowVFController(ApexPages.StandardSetController listviewcontroller){
        SelectedIDs = new string[]{};
        for(Operational_Tasks__c ot : (Operational_Tasks__c[])listviewcontroller.getSelected()){
            SelectedIDs.add(ot.Id);
        }
    }
}