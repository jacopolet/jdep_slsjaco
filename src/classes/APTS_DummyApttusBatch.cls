/*
Class Owner - Lavanya 
Dexcription - Apex class that identifies the Products with wrong hierarchies untill Apttus Category OOB Batch works as expected.
*/

global class APTS_DummyApttusBatch implements Database.Batchable<sObject>,Database.Stateful{

public Map<Id,Set<String>> mapProductHierarchy = new Map<Id,Set<String>>();
/** Method Name : start
    * Description : start method of Batch class
    **/
    global Database.QueryLocator start(Database.BatchableContext batchContext){
    String query = 'Select Apttus_Config2__ChildProductId__c,Apttus_Config2__ParentClassificationId__r.Name,Apttus_Config2__ParentClassificationId__c from Apttus_Config2__ProductHierarchyView__c';
        return Database.getQueryLocator(query);
    }
    
    /** Method Name : execute
    * Description : execute method of Batch class
    **/
    global void execute(Database.BatchableContext batchContext, List<Apttus_Config2__ProductHierarchyView__c> records){
    for(Apttus_Config2__ProductHierarchyView__c instView : records){
   
                        if(instView.Apttus_Config2__ChildProductId__c != NULL && instView.Apttus_Config2__ParentClassificationId__c != NULL)
    {
if(mapProductHierarchy.containskey(instView.Apttus_Config2__ChildProductId__c))
                        {
                           Set<String> setView = new Set<String>();
                            setView = mapProductHierarchy.get(instView.Apttus_Config2__ChildProductId__c);
                            setView.add(instView.Apttus_Config2__ParentClassificationId__r.Name);
                            mapProductHierarchy.put(instView.Apttus_Config2__ChildProductId__c,setView);                            
                            
                        }
                        else
                        {
                             Set<String> setView = new Set<String>();
                             setView.add(instView.Apttus_Config2__ParentClassificationId__r.Name);
                             mapProductHierarchy.put(instView.Apttus_Config2__ChildProductId__c,setView);
                        } 
    }


                                            
}
                                            
  }    
        
         global void finish(Database.BatchableContext batchContext){

for(Id instProdId : mapProductHierarchy.keySet())
{
    Set<String> setView = new Set<String>();
    List<String> newString = new List<String>();
    setView = mapProductHierarchy.get(instProdId);    
    newString.addAll(setView);
    if(setView.size()>1)
   APTS_CustomLogging.createErrorLog('Hierarchy Updated','Apex',instProdId,newString[0],null,'CPQ',false,false,null,true);
   
}

}
}