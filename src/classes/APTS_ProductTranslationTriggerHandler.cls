/**********************
Purpose: 
Revision History:
#No    Name         Date        Purpose
1.0    Nagavi       15/01/2017  Created the class to handle logics related to snding updates to SAP PO
2.0	   Jason		7/17/2017	Added Custom Logging
************************/
public with sharing class APTS_ProductTranslationTriggerHandler implements ITriggerHandler {
  public static Boolean isTriggerDisabled = true;
  public class ApplicationException extends Exception {}
  /*@methodName- IsDisabled
  *@description- method is used to prevent recursion
  *@param- empty
  *@return- returns boolean
  */
  public Boolean isDisabled(){
         Boolean disabled=false;
         if(TriggerSettings__c.getInstance().ProductTranslationTrigger__c) { 
           disabled=false;
         } 
         else{
           disabled=isTriggerDisabled;
         }
       return disabled;
    }
  /*@methodName- beforeInsert
  *@description- method is used to call logic 
  *@param- Pass the 
  *@return- no returntype
  */
    public void beforeInsert(List<SObject> newProdTranslationList){
      /*try{
                 
          //UpdateProdTranslationWithProdId((List<Apttus_Config2__ProductTranslation__c>)newProdTranslationList);
      }
      catch(Exception e) {
        system.debug('error'+e.getMessage());
        //throw new ApplicationException(e);
      }*/
    } 
 
    /*@methodName- beforeUpdate
  *@description- method is used to call logic 
  *@param- Pass the 
  *@return- no returntype
  */
    public void beforeUpdate(List<SObject> newProdTranslationList, Map<Id, SObject> newProdTranslationMap, List<SObject> oldProdTranslationList, Map<Id, SObject> oldProductTranslationMap){
      /*try{ 
          //SAPPO overrides the product lookup each time it upserts and hence the logic to update t
         List<Apttus_Config2__ProductTranslation__c> prodTransToBeUpdated=new List<Apttus_Config2__ProductTranslation__c>();
          for(Apttus_Config2__ProductTranslation__c prodTr :(List<Apttus_Config2__ProductTranslation__c>)newProdTranslationList){
              if(String.IsBlank(prodTr.Apttus_Config2__ProductId__c)){
                  prodTransToBeUpdated.add(prodTr);
              }
          }
          
          if(!prodTransToBeUpdated.IsEmpty()){
              UpdateProdTranslationWithProdId(prodTransToBeUpdated);    
          }
      }
      catch(Exception e) {
        throw new ApplicationException(e);
      }*/
    }
    
    /*@methodName- beforeDelete
  *@description- method is used to call logic related to the beforeDelete event
  *@param- Pass the 
  *@return- no returntype
  */
    public void beforeDelete(List<SObject> oldProdTranslationList, Map<Id, SObject> oldProductTranslationMap){
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
    public void afterInsert(List<SObject> newProdTranslationList, Map<Id, SObject> newProdTranslationMap){
      //Logic to check if the product is active and it is newly inserted.If so will trigger digital pricing
      try{
        onAfterInsertProdTranslation((List<Apttus_Config2__ProductTranslation__c>)newProdTranslationList);  
      }catch(DmlException ex) {
	  // Modified by Saranya Rajagopal Date: 14th sep 2018
	  APTS_CustomLogging.createErrorLog(ex.getTypeName(), APTS_CPQConstants.APEX_NAME, ex.getStackTraceString() ,APTS_CPQConstants.LABEL_PRODUCT_TRANSLATION, null,APTS_CPQConstants.CPQ,false,true,APTS_CPQConstants.CPQ_ERROR_EMAIL,true);}

    }
    /*@methodName- afterUpdate
  *@description- method is used to call logic related to the after update event
  *@param- Pass the new and old records as list and Map from trigger
  *@return- no returntype
  */
    public void afterUpdate(List<SObject> newProdTranslationList , Map<Id, SObject> newProdTranslationMap, List<SObject> oldProdTranslationList, Map<Id, SObject> oldProductTranslationMap){
       //Logic to check if the product's isactive field has changed.If so will trigger digital pricing
      try{
        onAfterUpdateProdTranslation((Map<Id, Apttus_Config2__ProductTranslation__c>)newProdTranslationMap,(Map<Id, Apttus_Config2__ProductTranslation__c>)oldProductTranslationMap);
      }catch(DmlException ex) {
	  // Modified by Saranya Rajagopal Date: 14th sep 2018
	  APTS_CustomLogging.createErrorLog(ex.getTypeName(), APTS_CPQConstants.APEX_NAME, ex.getStackTraceString() ,APTS_CPQConstants.LABEL_PRODUCT_TRANSLATION, null,APTS_CPQConstants.CPQ,false,true,APTS_CPQConstants.CPQ_ERROR_EMAIL,true);}
    }
    /*@methodName- afterDelete
  *@description- method is used to call logic related to the afterDelete event
  *@param- Pass the 
  *@return- no returntype
  */
    public void afterDelete(List<SObject> oldProdTranslationList, Map<Id, SObject> oldProductTranslationMap){
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
    public void afterUndelete(List<SObject> newProdTranslationList, Map<Id, SObject> newProdTranslationMap){
      /*try{}
      catch(Exception e) {
        throw new ApplicationException(e);
      } */
    }
    
    /*************** Business Logic Methods ***********************/
    
    /*@methodName- UpdateProdTranslationWithProdId
  *@description- method is used to update the product lookup on translation record on before insert and update
  *@param- Pass only the records to be processed as a list
  *@return- no returntype
  */
    /* public static void UpdateProdTranslationWithProdId(List<Apttus_Config2__ProductTranslation__c> newProdTranslationList){
        try{
           Set<String> relatedProductCodes=  new Set<String>();
           List<Product2> relatedProducts=new List<Product2>();
           Map<String,Id> prodCodeIdMap=new Map<String,Id>();
           
           for(Apttus_Config2__ProductTranslation__c prodTrans:newProdTranslationList){
               relatedProductCodes.add(prodTrans.Apttus_Config2__ProductCode__c);      
           }
           system.debug('relatedProductCodes'+relatedProductCodes);
           if(!relatedProductCodes.isEmpty()){
               relatedProducts=getProducts(relatedProductCodes); 
               system.debug('relatedProducts'+relatedProducts);
               if(!relatedProducts.IsEmpty()){
                   for(Product2 prod : relatedProducts){
                       prodCodeIdMap.put(prod.ProductCode,prod.Id);    
                   }
               }     
           }
           system.debug('prodCodeIdMap'+prodCodeIdMap);
           for(Apttus_Config2__ProductTranslation__c pT : newProdTranslationList){
               if(prodCodeIdMap.containsKey(pT.Apttus_Config2__ProductCode__c)){
                   pT.Apttus_Config2__ProductId__c=prodCodeIdMap.get(pT.Apttus_Config2__ProductCode__c);   
               }      
           }
           system.debug('newProdTranslationList'+newProdTranslationList);
         }catch(Exception e) {
         throw new ApplicationException(e);
         }
     }*/
     
     /*@methodName- getProducts
  *@description- method to get the related products
  *@param- Pass only the records to be processed as a list
  *@return- no returntype
  */
   public static List<Product2> getProducts(Set<String> relatedProductCodes){
        try{
            return [Select Id,ProductCode from Product2 where ProductCode IN :relatedProductCodes];
        }catch(Exception ex) {
		// Modified by Saranya Rajagopal Date: 14th sep 2018
		APTS_CustomLogging.createErrorLog(ex.getTypeName(),APTS_CPQConstants.APEX_NAME, ex.getStackTraceString() ,APTS_CPQConstants.LABEL_PRODUCT_TRANSLATION, null,APTS_CPQConstants.CPQ,false,true,APTS_CPQConstants.CPQ_ERROR_EMAIL,true);return null;}
   }
   
    /*@methodName- onAfterInsertProduct2
  *@description- method is used to call logic related to the after insert event
  *@param- Pass only the records to be processed as a list
  *@return- no returntype
  */
     public static void onAfterInsertProdTranslation(List<Apttus_Config2__ProductTranslation__c> newProdTranslationList){
        try{
         Set<Id> productTransIdsToBeSentToSAPPO=  new Set<Id>();
           for(Apttus_Config2__ProductTranslation__c prodTrans:newProdTranslationList){
               system.debug('inside trans'+prodTrans.APTS_Product_active__c);
               if(prodTrans.APTS_Product_active__c && APTS_IntegrationLogHandlerUtility.checkIfWebshopIsValid(prodTrans.APTS_Product_Enabled_for_web_shop_s__c)){
                  productTransIdsToBeSentToSAPPO.add(prodTrans.Apttus_Config2__ProductId__c);   
               }    
           }
           
           if(!productTransIdsToBeSentToSAPPO.isEmpty()){
             APTS_IntegrationLogHandlerUtility.checkAndCreateIntegrationLogs(productTransIdsToBeSentToSAPPO);      
           }
         }catch(Exception ex) {APTS_CustomLogging.createErrorLog(ex.getTypeName(),APTS_CPQConstants.APEX_NAME, ex.getStackTraceString() ,APTS_CPQConstants.LABEL_PRODUCT_TRANSLATION, null,APTS_CPQConstants.CPQ,false,true,APTS_CPQConstants.CPQ_ERROR_EMAIL,true);}
     }
     
     /*@methodName- onAfterUpdateProduct2
   *@description- method is used to call logic related to the after update event
   *@param- Pass the map of new and old records
   *@return- no returntype
   */
    public static void onAfterUpdateProdTranslation(Map<Id, Apttus_Config2__ProductTranslation__c> newProductTranslationMap,Map<Id, Apttus_Config2__ProductTranslation__c> oldProductTranslationMap){
        try{
        Set<Id> prodTranslationIdsToBeSentToSAPPO=new Set<Id>();
        List<Schema.FieldSetMember> relatedFieldSet=new List<Schema.FieldSetMember>();
        relatedFieldSet=APTS_IntegrationLogHandlerUtility.readFieldSet(APTS_CPQConstants.APTS_PROD_TRANS, APTS_CPQConstants.APTS_CONFIG_PROD_TRANS);
        //List<Product2> productsToBeSentToSAPPO=  new List<Product2>();
           for(Id prodId:newProductTranslationMap.keySet()){
               if(newProductTranslationMap.get(prodId).APTS_Product_active__c && APTS_IntegrationLogHandlerUtility.checkIfWebshopIsValid(newProductTranslationMap.get(prodId).APTS_Product_Enabled_for_web_shop_s__c) &&
                   APTS_IntegrationLogHandlerUtility.checkIfValidToSend(newProductTranslationMap.get(prodId),oldProductTranslationMap.get(prodId),relatedFieldSet)){
                        System.debug('inside 1');
                        prodTranslationIdsToBeSentToSAPPO.add(newProductTranslationMap.get(prodId).Apttus_Config2__ProductId__c);   
               }    
           }
           
           if(!prodTranslationIdsToBeSentToSAPPO.isEmpty()){
             APTS_IntegrationLogHandlerUtility.checkAndCreateIntegrationLogs(prodTranslationIdsToBeSentToSAPPO);      
           }
        }catch(Exception ex) {
		// Modified by Saranya Rajagopal Date: 14th sep 2018
		APTS_CustomLogging.createErrorLog(ex.getTypeName(),APTS_CPQConstants.APEX_NAME, ex.getStackTraceString() ,APTS_CPQConstants.LABEL_PRODUCT_TRANSLATION, null,APTS_CPQConstants.CPQ,false,true,APTS_CPQConstants.CPQ_ERROR_EMAIL,true);}
     }

      
}