/**********************
Purpose: 
Revision History:
#No    Name         Date        Purpose
1.0    Nagavi       15/01/2017  Created the class to handle logics related to snding updates to SAP PO
************************/
public with sharing class APTS_ProdClassificationTriggerHandler implements ITriggerHandler {
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
         if (TriggerSettings__c.getInstance().ProdClassificationTrigger__c) {
           disabled=false;
         } 
         else {
           disabled=isTriggerDisabled;
         }
         System.debug('disabled'+disabled); 
       return disabled;
     }
     catch(Exception e) {
      /*throw new ApplicationException(e);*/
       APTS_CustomLogging.createErrorLog(e.getTypeName(), APTS_CPQConstants.APEX_NAME, e.getStackTraceString() ,'ProdClassificationTrigger__c', APTS_CPQConstants.EXCEPTION_ID, APTS_CPQConstants.CPQ,false,true,APTS_CPQConstants.CPQ_ERROR_EMAIL,true);
     return false;
     }
    }
  /*@methodName- beforeInsert
  *@description- method is used to call logic 
  *@param- Pass the 
  *@return- no returntype
  */
    public void beforeInsert(List<SObject> newProdClassificationList){
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
    public void beforeUpdate(List<SObject> newProdClassificationList, Map<Id, SObject> newProdClassificationMap, List<SObject> oldProdClassificationList, Map<Id, SObject> oldProdClassificationMap){
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
    public void beforeDelete(List<SObject> oldProdClassificationList, Map<Id, SObject> oldProdClassificationMap){
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
    public void afterInsert(List<SObject> newProdClassificationList, Map<Id, SObject> newProdClassificationMap){
      //Logic to check if the product is active and it is newly inserted.If so will trigger digital product
      try{
        onAfterInsertProdClassification((List<Apttus_Config2__ProductClassification__c>)newProdClassificationList);  
      }catch(DmlException e) {
      /*throw new ApplicationException(e);*/
       APTS_CustomLogging.createErrorLog(e.getTypeName(), APTS_CPQConstants.APEX_NAME, e.getStackTraceString() ,'ProdClassificationTrigger__c', APTS_CPQConstants.EXCEPTION_ID, APTS_CPQConstants.CPQ,false,true,APTS_CPQConstants.CPQ_ERROR_EMAIL,true);}

    }
    /*@methodName- afterUpdate
  *@description- method is used to call logic related to the after update event
  *@param- Pass the new and old records as list and Map from trigger
  *@return- no returntype
  */
    public void afterUpdate(List<SObject> newProdClassificationList , Map<Id, SObject> newProdClassificationMap, List<SObject> oldProdClassificationList, Map<Id, SObject> oldProdClassificationMap){
       //Logic to check if the product's isactive field has changed.If so will trigger digital pricing
      try{
        //onAfterUpdateProdClassification((Map<Id, Apttus_Config2__ProductClassification__c>)newProdClassificationMap,(Map<Id, Apttus_Config2__ProductClassification__c>)oldProdClassificationMap);
      }catch(DmlException e) {
     /* throw new ApplicationException(e);*/
       APTS_CustomLogging.createErrorLog(e.getTypeName(), APTS_CPQConstants.APEX_NAME, e.getStackTraceString() ,'ProdClassificationTrigger__c', APTS_CPQConstants.EXCEPTION_ID, APTS_CPQConstants.CPQ,false,true,APTS_CPQConstants.CPQ_ERROR_EMAIL,true);
       }
    }
    /*@methodName- afterDelete
  *@description- method is used to call logic related to the afterDelete event
  *@param- Pass the 
  *@return- no returntype
  */
    public void afterDelete(List<SObject> oldProdClassificationList, Map<Id, SObject> oldProdClassificationMap){
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
    public void afterUndelete(List<SObject> newProdClassificationList, Map<Id, SObject> newProdClassificationMap){
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
     public static void onAfterInsertProdClassification(List<Apttus_Config2__ProductClassification__c> newProdClassificationList){
        try{
         Set<Id> prodClassificationIdsToBeSentToSAPPO= new Set<Id>();
           for(Apttus_Config2__ProductClassification__c prodClass:newProdClassificationList){
               if(prodClass.APTS_Product_Active__c && APTS_IntegrationLogHandlerUtility.checkIfWebshopIsValid(prodClass.APTS_Product_Enabled_for_web_shop_s__c)){
                   System.debug('inside');
                   prodClassificationIdsToBeSentToSAPPO.add(prodClass.Apttus_Config2__ProductId__c);   
               }    
           }
           
           if(!prodClassificationIdsToBeSentToSAPPO.isEmpty()){
             APTS_IntegrationLogHandlerUtility.checkAndCreateIntegrationLogs(prodClassificationIdsToBeSentToSAPPO);      
           }
         }catch(Exception e) {
         /*throw new ApplicationException(e);*/
          APTS_CustomLogging.createErrorLog(e.getTypeName(), APTS_CPQConstants.APEX_NAME, e.getStackTraceString() ,'ProdClassificationTrigger__c', APTS_CPQConstants.EXCEPTION_ID, APTS_CPQConstants.CPQ,false,true,APTS_CPQConstants.CPQ_ERROR_EMAIL,true);
          }
     }
     /*@methodName- onAfterUpdateProduct2
   *@description- method is used to call logic related to the after update event
   *@param- Pass the map of new and old records
   *@return- no returntype
   */
    /*public static void onAfterUpdateProdClassification(Map<Id, Apttus_Config2__ProductClassification__c> newProdClassificationMap,Map<Id, Apttus_Config2__ProductClassification__c> oldProdClassificationMap){
        try{
        Set<Id> prodClassificationIdsToBeSentToSAPPO=new Set<Id>();
        List<Schema.FieldSetMember> relatedFieldSet=new List<Schema.FieldSetMember>();
        relatedFieldSet=APTS_IntegrationLogHandlerUtility.readFieldSet('APTS_ProdClassForDigitalIntegration','Apttus_Config2__ProductClassification__c');    
        //List<Product2> productsToBeSentToSAPPO=  new List<Product2>();
           for(Id prodClass:newProdClassificationMap.keySet()){
               if(newProdClassificationMap.get(prodClass).APTS_Product_Active__c && APTS_IntegrationLogHandlerUtility.checkIfWebshopIsValid(newProdClassificationMap.get(prodClass).APTS_Product_Enabled_for_web_shop_s__c) &&
                   APTS_IntegrationLogHandlerUtility.checkIfValidToSend(newProdClassificationMap.get(prodClass),oldProdClassificationMap.get(prodClass),relatedFieldSet)){
                        prodClassificationIdsToBeSentToSAPPO.add(newProdClassificationMap.get(prodClass).Apttus_Config2__ProductId__c);   
               }    
           }
           
           if(!prodClassificationIdsToBeSentToSAPPO.isEmpty()){
             APTS_IntegrationLogHandlerUtility.checkAndCreateIntegrationLogs(prodClassificationIdsToBeSentToSAPPO);      
           }
        }catch(Exception e) {throw new ApplicationException(e);}
     }*/
}