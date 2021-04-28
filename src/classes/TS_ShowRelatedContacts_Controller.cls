/*
* @author        Francis Allen Alindogan
* @date          11.04.2020         
* @description   Controller class for TS Show Related Contacts
* @revision(s)
*/
public without sharing class TS_ShowRelatedContacts_Controller {

    public static Boolean hasException = false;
    public class TS_ShowRelatedContacts_ControllerException extends Exception {  }
    
    @AuraEnabled
    public static List<Contact> getRelatedContact (String recordId, String sobj){        
        List<SOBject> contacts = new List<SOBject>();       
        
        if(recordId != null && sobj != null) {

            try{
                //SELECT ContactId, Contact.Name FROM AccountContactRelation WHERE AccountId IN(Select Apttus_Config2__AccountId__c From Apttus_Config2__AccountLocation__c WHERE Id IN(:recordId))
                if(sobj == 'Apttus_Config2__AccountLocation__c'){
                	//contacts = [SELECT Id, Name, Main_Commercial_Person__c, Main_Service_Person__c, Account.Name, AccountId, RecordType.Name FROM Contact WHERE AccountId IN(SELECT Apttus_Config2__AccountId__c FROM Apttus_Config2__AccountLocation__c WHERE Id =:recordId) ORDER BY Main_Service_Person__c DESC,Account.Name ASC];    
                	String additionalFields = 'AccountId, ContactId, Contact.Name, Contact.AccountId, Contact.Main_Service_Person__c';  
            		String whereClause = 'AccountId IN(Select Apttus_Config2__AccountId__c From Apttus_Config2__AccountLocation__c WHERE Id IN';
                    String whereClauseSuffix = ')';
            		contacts = TS_CustomLookUpController.fetchLookUpValues(null,'AccountContactRelation',null, false, whereClause, additionalFields, null, whereClauseSuffix, recordId,
                                                                  		   false, null, null, null, null, 
                                                                   		   true, true, true);     
                }
                //SUBQUERY Select AccountLocation__r.Apttus_Config2__AccountId__c From PhysicalAsset__c WHERE Id IN(:recordId)
            	//MAINQUERY SELECT ContactId, Contact.Name FROM AccountContactRelation WHERE AccountId IN(SUBQUERY_RESULT)
                else if(sobj == 'PhysicalAsset__c'){
                   //contacts = [SELECT Id, Name, Main_Commercial_Person__c, Main_Service_Person__c, Account.Name, AccountId, RecordType.Name FROM Contact WHERE AccountId IN(SELECT SoldTo__c FROM PhysicalAsset__c WHERE Id =:recordId)  ORDER BY Main_Service_Person__c DESC,Account.Name ASC];    
                   String SUBQadditionalFields = 'AccountLocation__r.Apttus_Config2__AccountId__c';                
                   String SUBQwhereClause = 'Id IN';                               
                   String additionalFields = 'AccountId, ContactId, Contact.Name, Contact.AccountId, Contact.Main_Service_Person__c';      
                   String whereClause = 'AccountId IN';                        
	               contacts = TS_CustomLookUpController.fetchLookUpValues(null,'AccountContactRelation',null, false, whereClause, additionalFields, null, null, recordId,
                                                                   		  true, SUBQadditionalFields, 'PhysicalAsset__c', SUBQwhereClause, recordId, 
                                                                          true, true, true);  
                }
                
                //Exception for test class purposes
                if (Test.isRunningTest() && hasException) {
                    throw new TS_ShowRelatedContacts_ControllerException('Force to throw an exception');
                }

            } catch(Exception ex){
                System.debug(ex);
                CustomLogging.debugException(ex);
                CustomLogging.pop();
            }
        }        
        return contacts;    
    }
    
    @AuraEnabled
    public static List<AccountContactRelation> getRelatedAccConRelationship (String accString, String conString){        
        List<AccountContactRelation> returnList = new List<AccountContactRelation>();        
        
        if(accString != null && conString != null){
            try {
                List<String> AccList = accString.split(',');
                List<String> ConList = conString.split(',');    
        
                if(!AccList.isEmpty() && !ConList.isEmpty()){
                    returnList = [SELECT Id,AccountId,ContactId FROM AccountContactRelation WHERE AccountId IN:AccList AND ContactId IN:ConList];
                }
                
                //Exception for test class purposes
                if (Test.isRunningTest() && hasException) {
                    throw new TS_ShowRelatedContacts_ControllerException('Force to throw an exception');
                }

            } 
            catch(Exception ex){
                System.debug(ex);
                CustomLogging.debugException(ex);
                CustomLogging.pop();
            }                                        
        }
        return returnList;
    }
        
    @AuraEnabled
    public static Id getRecTypeId(String recordTypeLabel){
        Id recid = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(recordTypeLabel).getRecordTypeId();        
        return recid;
    } 
    
    @AuraEnabled        
    public static List<String> fetchRecordTypeValues(String mysObj){        
        List<String> returnJSON = new List<String>();
        Map <Integer, String> recordtypemap = new Map<Integer, String>();
        Integer ctr = 0;
        if(mysObj != null){                    
            SObjectType selectedsObject = Schema.getGlobalDescribe().get(mysObj);            
            List<Schema.RecordTypeInfo> recordtypes = selectedsObject.getDescribe().getRecordTypeInfos();                
            for(RecordTypeInfo rt : recordtypes){
                if(rt.getName() != 'Master')
                recordtypemap.put(ctr, rt.getName()+'||'+rt.getRecordTypeId());
                ctr++;
            }      
            returnJSON.add(JSON.serialize(recordtypemap));
		}                
        return returnJSON;
    }
}