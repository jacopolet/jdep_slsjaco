/**********************
Purpose: 
Revision History:
#No    Name         Date        Purpose
1.0    Nagavi       15/01/2017  Created the class to handle logics related to snding updates to SAP PO
************************/
public with sharing class APTS_ProdOptionCompTriggerHandler implements ITriggerHandler {
  public static Boolean isTriggerDisabled = true;
  public class ApplicationException extends Exception {}
  /*@methodName- IsDisabled
  *@description- method is used to prevent recursion
  *@param- empty
  *@return- returns boolean
  */
  public Boolean isDisabled(){
     try{
         Boolean disabled=false;
         if (TriggerSettings__c.getInstance().ProdOptionCompTrigger__c) {
           disabled=false;
         } 
         else {
           disabled=isTriggerDisabled;
         }
       return disabled;
     }catch(Exception e) {throw new ApplicationException(e);}
    }
  /*@methodName- beforeInsert
  *@description- method is used to call logic 
  *@param- Pass the 
  *@return- no returntype
  */
    public void beforeInsert(List<SObject> newProdOptionCompList){
      /*try{}
      catch(Exception e) {
        throw new ApplicationException(e);
      }*/
    } 
 
    /*@methodName- beforeUpdate
  *@description- method is used to call logic 
  *@param- Pass the 
  *@return- no returntype
  */
    public void beforeUpdate(List<SObject> newProdOptionCompList, Map<Id, SObject> newProdOptionCompMap, List<SObject> oldProdOptionCompList, Map<Id, SObject> oldProdOptionCompMap){
      /*try{}
      catch(Exception e) {
        throw new ApplicationException(e);
      }*/
    }
    
    /*@methodName- beforeDelete
  *@description- method is used to call logic related to the beforeDelete event
  *@param- Pass the 
  *@return- no returntype
  */
    public void beforeDelete(List<SObject> oldProdOptionCompList, Map<Id, SObject> oldProdOptionCompMap){
      /*try{}
      catch(Exception e) {
        throw new ApplicationException(e);
      }*/ 
    }
 
  /*@methodName- afterInsert
  *@description- method is used to call logic related to the after insert event
  *@param- Pass the new records as list and Map
  *@return- no returntype
  */
    public void afterInsert(List<SObject> newProdOptionCompList, Map<Id, SObject> newProdOptionCompMap){
      //Logic to check if the product is active and it is newly inserted.If so will trigger digital product
      try{
        onAfterInsertProdOptionComp((List<Apttus_Config2__ProductOptionComponent__c>)newProdOptionCompList);  
      }catch(DmlException e) {throw new ApplicationException(e);}

    }
    /*@methodName- afterUpdate
  *@description- method is used to call logic related to the after update event
  *@param- Pass the new and old records as list and Map from trigger
  *@return- no returntype
  */
    public void afterUpdate(List<SObject> newProdOptionCompList , Map<Id, SObject> newProdOptionCompMap, List<SObject> oldProdOptionCompList, Map<Id, SObject> oldProdOptionCompMap){
       //Logic to check if the product's isactive field has changed.If so will trigger digital pricing
      try{
        onAfterUpdateProdOptionComp((Map<Id, Apttus_Config2__ProductOptionComponent__c>)newProdOptionCompMap,(Map<Id, Apttus_Config2__ProductOptionComponent__c>)oldProdOptionCompMap);
      }catch(DmlException e) {throw new ApplicationException(e);}
    }
    /*@methodName- afterDelete
  *@description- method is used to call logic related to the afterDelete event
  *@param- Pass the 
  *@return- no returntype
  */
    public void afterDelete(List<SObject> oldProdOptionCompList, Map<Id, SObject> oldProdOptionCompMap){
      /*try{}
      catch(Exception e) {
        throw new ApplicationException(e);
      } */
    }
    /*@methodName- afterUndelete
  *@description- method is used to call logic related to the afterUndelete event
  *@param- Pass the 
  *@return- no returntype
  */
    public void afterUndelete(List<SObject> newProdOptionCompList, Map<Id, SObject> newProdOptionCompMap){
      /*try{}
      catch(Exception e) {
        throw new ApplicationException(e);
      } */
    }
    
    /*************** Business Logic Methods ***********************/
    /*@methodName- onAfterInsertProduct2
  *@description- method is used to call logic related to the after insert event
  *@param- Pass only the records to be processed as a list
  *@return- no returntype
  */
     public static void onAfterInsertProdOptionComp(List<Apttus_Config2__ProductOptionComponent__c> newProdOptionCompList){
        try{
         Set<Id> prodOptionCompIdsToBeSentToSAPPO=  new Set<Id>();
           for(Apttus_Config2__ProductOptionComponent__c prodOpt:newProdOptionCompList){
               if(prodOpt.APTS_Product_Active__c && APTS_IntegrationLogHandlerUtility.checkIfWebshopIsValid(prodOpt.APTS_Product_Enabled_for_web_shop_s__c)){
                  prodOptionCompIdsToBeSentToSAPPO.add(prodOpt.Apttus_Config2__ComponentProductId__c);   
               }    
           }
           
           if(!prodOptionCompIdsToBeSentToSAPPO.isEmpty()){
             APTS_IntegrationLogHandlerUtility.checkAndCreateIntegrationLogs(prodOptionCompIdsToBeSentToSAPPO);      
           }
         }catch(Exception e) {throw new ApplicationException(e);}
     }
     /*@methodName- onAfterUpdateProduct2
   *@description- method is used to call logic related to the after update event
   *@param- Pass the map of new and old records
   *@return- no returntype
   */
    public static void onAfterUpdateProdOptionComp(Map<Id, Apttus_Config2__ProductOptionComponent__c> newProdOptionCompMap,Map<Id, Apttus_Config2__ProductOptionComponent__c> oldProdOptionCompMap){
        try{
        Set<Id> prodOptionCompIdsToBeSentToSAPPO=new Set<Id>();
        List<Schema.FieldSetMember> relatedFieldSet=new List<Schema.FieldSetMember>();
        relatedFieldSet=APTS_IntegrationLogHandlerUtility.readFieldSet('APTS_ProdOptForDigitalIntegration','Apttus_Config2__ProductOptionComponent__c');    
        //List<Product2> productsToBeSentToSAPPO=  new List<Product2>();
           for(Id prodOptId:newProdOptionCompMap.keySet()){
               if(newProdOptionCompMap.get(prodOptId).APTS_Product_Active__c && APTS_IntegrationLogHandlerUtility.checkIfWebshopIsValid(newProdOptionCompMap.get(prodOptId).APTS_Product_Enabled_for_web_shop_s__c) &&
                   APTS_IntegrationLogHandlerUtility.checkIfValidToSend(newProdOptionCompMap.get(prodOptId),oldProdOptionCompMap.get(prodOptId),relatedFieldSet)){
                        prodOptionCompIdsToBeSentToSAPPO.add(newProdOptionCompMap.get(prodOptId).Apttus_Config2__ComponentProductId__c);   
               }    
           }
           
           if(!prodOptionCompIdsToBeSentToSAPPO.isEmpty()){
             APTS_IntegrationLogHandlerUtility.checkAndCreateIntegrationLogs(prodOptionCompIdsToBeSentToSAPPO);      
           }
        }catch(Exception e) {throw new ApplicationException(e);}
     }
}