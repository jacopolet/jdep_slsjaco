/**
* Class Name : APTS_SearchPhysicalAssetController 
* Description :  Apex controller for 'APTS_searchPhysicalAsset' Lightning Component to update the Asset Line Item record
* Author : Nirmal Vijaya Kumar
* Date Created : 03/06/2018
**/
public without sharing class APTS_SearchPhysicalAssetController{
    
    /**Method Name : searchAssetLineItem
    * Description : Method which returns the Asset Line Item with Serial Number specified in the input parameter
    */
    @AuraEnabled
    public static Apttus_Config2__AssetLineItem__c searchAssetLineItem(String searchKey){
     
       // return [SELECT Id, Name, APTS_Physical_Asset_Id__r.SerialNumber__c FROM Apttus_Config2__AssetLineItem__c 
       //         WHERE APTS_Physical_Asset_Id__r.SerialNumber__c =: searchKey LIMIT 1][0];
        //Added by Abhishek K to Change Field
        return [SELECT Id, Name, APTS_Physical_Asset__r.SerialNumber__c FROM Apttus_Config2__AssetLineItem__c 
                WHERE APTS_Physical_Asset__r.SerialNumber__c =: searchKey LIMIT 1][0];
    }

    /**Method Name : updateAssetLineItem
    * Description : Method which updates the Asset Line Item with Serial Number specified in the input parameter
    */
    @AuraEnabled
    public static Boolean updateAssetLineItem(Id assetId,String serialNo){
        PhysicalAsset__c phyAsset= [SELECT Id, Name, SerialNumber__c FROM PhysicalAsset__c 
                                   WHERE SerialNumber__c =: serialNo  LIMIT 1][0];
        Apttus_Config2__AssetLineItem__c  aliToUpdate = new Apttus_Config2__AssetLineItem__c(); 
        aliToUpdate.Id = assetId;
        //aliToUpdate.APTS_Physical_Asset_Id__c = phyAsset.Id;
        aliToUpdate.APTS_Physical_Asset__c= phyAsset.Id; //Added by Abhishek K to Change Field
        Database.SaveResult srList;
        try{
             srList = Database.update(alitoupdate,False);
        }
         catch(Exception e)
        {        
        APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'APTS_SearchPhysicalAssetController', null,'CLM',false,false,null,true);
        }
        
        return (srList.isSuccess() ? true : false);
    }
}