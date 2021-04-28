////
////    Catherine Aragon
////    June 12, 2020 Apex for Passing Selected Values from VF Page to Flow
////
public without sharing class SM_FilterTaskId {
    public String[] SelectedIDs{get;set;}
    public SM_FilterTaskId (ApexPages.StandardSetController listviewcontroller){
        SelectedIDs = new String[]{};
        for(Task t : (Task[])listviewcontroller.getSelected()){
            SelectedIDs.add(t.Id);
        }
    }
}