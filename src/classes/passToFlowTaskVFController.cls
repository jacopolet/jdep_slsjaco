////
////    Glenn Serrano
////    May 19, 2020 Apex for Passing Selected Values from VF Page to Flow
////
public without sharing class passToFlowTaskVFController {
    
    public String[] SelectedIDs{get;set;}
    
    public passToFlowTaskVFController (ApexPages.StandardSetController listviewcontroller){
        SelectedIDs = new String[]{};
        for(Task t : (Task[])listviewcontroller.getSelected()){
            SelectedIDs.add(t.Id);
        }
    }
}