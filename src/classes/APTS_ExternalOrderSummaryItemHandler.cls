/*******************************************************************************************
Name            : APTS_ExternalOrderSummaryItemHandler
Created By      : Beulah Ann Thomas
Created Date    : 07/23/2018
Description     : Handler class of External Order Line Item 
                    'APTS_ExternalOrderSummaryItemTrigger'.
Version history : v1.0 - Created
Test Class      : APTS_VolumeObligationLineItemsTest(100% code coverage)
*********************************************************************************************/
public with sharing class APTS_ExternalOrderSummaryItemHandler implements ITriggerHandler
{

    private static boolean triggerDisabled = false;

    public Boolean isDisabled() 
    {
        system.debug('triggerDisabled--'+ triggerDisabled);
        return triggerDisabled;
    }   
    
    public void afterUpdate(List<SObject> newList, Map<Id, SObject> newItems,
                             List<SObject> oldList, Map<Id, SObject> oldItems)
    {
    
    }
    
    public void beforeInsert(List<SObject> newItems)
    {
     
    }
     
    public void afterInsert(List<SObject> newList, Map<Id, SObject> newItems)
    {
      try{
          APTS_BIRUtils.createVolumeOLIForExternalOLI(newList, newItems);
          system.debug('external line item, insert--'+ newItems);
      }catch(Exception e){
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Order','','CPQ',false,true,'cpqerror@accenture.com',true);             
      } 
    }
    
     
    public void beforeUpdate(List<SObject> newList, Map<Id, SObject> newItems,
                             List<SObject> oldList, Map<Id, SObject> oldItems)
    {
    
    }
    
    public void beforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems){}

    public void afterDelete(List<SObject> oldList, Map<Id, SObject> oldItems){}

     /* After undeleting records. */
    public void afterUndelete(List<SObject> newList, Map<Id, SObject> newItems){}
    
}