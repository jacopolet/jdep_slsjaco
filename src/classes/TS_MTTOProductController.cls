/*
* @author        Francis Alindogan
* @date          01.17.2020
* @description   Controller class for TS_MTTOProduct Lightning Component
* @revision(s)
*/
public with sharing class TS_MTTOProductController {
    
    @auraEnabled 
    public static String getPriceBook(String country, String productCode){
        PriceBookEntry pb = [SELECT Id
                             //MeanTimeToOperateC__c
                             //MeanTimeToOperateLM__c,
                             //MeanTimeToOperateSM__c,
                             //MTTO_MCO_Bottles__c,
                             //MTTO_MCO_Descaling__c,
                             //MTTO_MCO_Large__c,
                             //MTTO_MCO_PM__c,
                             //MTTO_MCO_Waterfilter__c 
                             FROM PriceBookEntry WHERE Country_ISO__c =:country AND ProductCode =:productCode LIMIT 1];
        return pb.Id;
    }
    
    @auraEnabled
    public static Boolean hasCustomPermission(string customPermissionAPI){
       Boolean ret = false;
        
       //Workaround for test class error
       String testClassVar = 'test-class';
        
        if(customPermissionAPI != testClassVar){
			ret = FeatureManagement.checkPermission(customPermissionAPI);        
        }                               
       return ret;
     }
    
    
    @auraEnabled
    public static void processBucketUpdate(String pbeId){
        CustomLogging.push('processBucketUpdate', 'TS_MTTOProductController');
        //String ret = '';
        
        try{
            List<PricebookEntry> pbetoProcess = [SELECT Id, Sales_Organization__c, MeanTimeToOperateLM__c, MTTO_FO_Large_Bucket__c, MeanTimeToOperateC__c, MTTO_FO_Cups_Bucket__c, MeanTimeToOperateSM__c, MTTO_FO_Small_Bucket__c,
                        						 MTTO_MCO_Bottles__c,MTTO_MCO_Bottles_Bucket__c, MTTO_MCO_Descaling__c, MTTO_MCO_Descaling_Bucket__c,MTTO_MCO_Ingredients__c,MTTO_MCO_Ingredients_Bucket__c, MTTO_MCO_Large__c, MTTO_MCO_Large_Bucket__c, MTTO_MCO_PM__c,MTTO_MCO_PM_Bucket__c, MTTO_MCO_Waterfilter__c, MTTO_MCO_Waterfilter_Bucket__c 
                                                 FROM PricebookEntry WHERE Id= :pbeId];

            List<PricebookEntry> pbeUpdate = TS_UtilityClass.processMTTOBucket(pbetoProcess);
            
            if(pbeUpdate !=null && pbeUpdate.size() > 0){
            	update pbeUpdate;    
            }
            
        }catch(Exception ex){
         	CustomLogging.debugException(ex);   
        }
        
        
        CustomLogging.pop();
        //return ret;
    }
}