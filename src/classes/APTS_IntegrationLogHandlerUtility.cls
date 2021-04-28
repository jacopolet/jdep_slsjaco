/*******************
Purpose: 
Revision History:
#No     Name        Date        Purpose
1.0     Nagavi      15/01/2017  Created the class to include all logics related to integration logs
************************/
public with sharing class APTS_IntegrationLogHandlerUtility {
    public class ApplicationException extends Exception {}
        
    //Insert logs for product 
    public static void createIntegrationLogs(Set<Id> newItemsList){
        List<Integration_Log__c> logsList=new List<Integration_Log__c>();
        try{
            for(Id obj:newItemsList){
                Integration_Log__c temp=new Integration_Log__c();
                temp.Object__c=APTS_CPQConstants.PRODUCT2;
                temp.Object_Id__c=obj;
                temp.Ready_To_Be_Sent__c=true;
                temp.Integration_Status__c =APTS_CPQConstants.INITIAL;
                
                logsList.add(temp);
            }
        
            if(!logsList.IsEmpty()){
            
                insert logsList;
            }
       }
       catch(exception e){
           APTS_CustomLogging.createErrorLog(e.getTypeName(),'Apex', e.getStackTraceString() ,'APTS_IntegrationLogHandlerUtility',null,'CPQ',false,false,null,true);         
       }
    }
    
       
    //Check the existing logs before inserting new logs on Product or PLI updates
    public static void checkAndCreateIntegrationLogs(Set<Id> newItemsList){
        List<Integration_Log__c> logsToBeInserted=new List<Integration_Log__c>();
        //set<Id> relatedProdIds=new set<Id>();
        set<Id> logSet=new set<Id>();
        List<Integration_Log__c> existingLogsList=new List<Integration_Log__c>();
        try { 
            //Get the list of product Ids from the list
                    
            if(!newItemsList.isEmpty()){
                //Query the existing logs
                
                existingLogsList=[Select id,Object_Id__c,Integration_Status__c from Integration_Log__c where Object_Id__c IN:newItemsList];
            }
            
            if(!existingLogsList.isEmpty()){
                for(Integration_Log__c log:existingLogsList){
                    if(log.Integration_Status__c==APTS_CPQConstants.INITIAL || log.Integration_Status__c==APTS_CPQConstants.OUTBOUNDTRIGGERED){
                        logSet.add(log.Object_Id__c);       
                    }           
                }    
            }
            
            //Iterate over the new records and insert new logs accordingly
            for(Id obj:newItemsList){
                
                if(logSet.isEmpty() || (!logSet.isEmpty() && !logSet.contains(obj))){
                   
                    Integration_Log__c temp=new Integration_Log__c();
                    temp.Object__c=APTS_CPQConstants.PRODUCT2;
                    temp.Object_Id__c=obj;
                    temp.Ready_To_Be_Sent__c=true;
                    temp.Integration_Status__c =APTS_CPQConstants.INITIAL;
                
                    logsToBeInserted.add(temp);
                }
            }
        
            if(!logsToBeInserted.IsEmpty()){
                
                    insert logsToBeInserted;
                
            }
        }
        catch(exception e){
            APTS_CustomLogging.createErrorLog(e.getTypeName(),'Apex', e.getStackTraceString() ,'APTS_IntegrationLogHandlerUtility',null,'CPQ',false,false,null,true);     
        }
    }
    
    // Function for retrieving a Field Set for any object
    public static List<Schema.FieldSetMember> readFieldSet(String fieldSetName, String ObjectName)
    {
        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe(); 
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(ObjectName);
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);
    
        return fieldSetObj.getFields(); 
    }  

   public static Boolean checkIfValidToSend(Sobject newRecord, Sobject oldRecord,List<Schema.FieldSetMember> relatedFieldSet){
      //Check if the required fields have been updated in new and old records
      Boolean temp=false;
      try{
                   
          //Get the list of fields to be checked for updates via fieldset
          List<String> fieldList=new List<String>();
          for(Schema.FieldSetMember f : relatedFieldSet) {
              fieldList.add(f.getFieldPath());
          }
           
         if(!fieldList.IsEmpty()){
              for(string str:fieldList){
                  if(newRecord.get(str)!=oldRecord.get(str)){
                      temp=true;
                      //return temp;
                  }
              }    
          }
                    
        }catch(Exception e) {
            APTS_CustomLogging.createErrorLog(e.getTypeName(),'Apex', e.getStackTraceString() ,'APTS_IntegrationLogHandlerUtility',null,'CPQ',false,false,null,true);
            
        }      
        return temp;
    }
    
    Public Static Set<String> getEnabledWebshops(){
        String enabledWebshops=APTS_Webshop_Enabled__c.getInstance().Webshops_to_Be_Enabled__c;
        Set<String> webshopSet=new Set<String>();
        List<String> webshopList=new List<String>();
        if(enabledWebshops!=null){
            webshopList=enabledWebshops.split(';');  
            webshopSet.addAll(webshopList);
        }
        return webshopSet;
    }
    
    public static Boolean checkIfWebshopIsValid(String enabledProdWS){
        Boolean isValid=false;
        
        Set<string> enabledWebshops=new Set<string>();  
        enabledWebshops=getEnabledWebshops();
        
        Set<string> availableWebShops=new Set<String>();
        List<String> webshopList=new List<String>();
        if(enabledProdWS!=null){
            webshopList=enabledProdWS.split(';');  
            availableWebShops.addAll(webshopList);
        }
        
        if(!enabledWebshops.isEmpty() && !availableWebShops.isEmpty()){
            for(String str:availableWebShops){
                if(enabledWebshops.contains(str)){
                    isValid=true;
                    break;
                }    
            }
                
        }
        return isValid;
    }
    
    public static set<String> getProdWebshops(String prodWShop){
        Set<string> availableWebShops=new Set<String>();
        List<String> webshopList=new List<String>();
        if(prodWShop!=null){
            webshopList=prodWShop.split(';');  
            availableWebShops.addAll(webshopList);
        }
        return availableWebShops;
    }
    
    public static string getWebShopString(Set<String> webShopSet){
        String temp='';
        for(String str:webShopSet){
            if(temp==''){
                temp=str;
            }
            else{
                temp=temp+';'+str;
            }
        }
        
        return temp;
    }
    
}