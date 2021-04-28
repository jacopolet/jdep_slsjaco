/**
* @author        Rey Austral
* @date          9.28.2017           
* @description   Controller for TS_CustomLookUp (Lightning Component)
* @revision(s)	
				11/26/2020 Francis Allen Alindogan 				
				1. Standard query with like (ORIGINAL SCENARIO)
				2. Query with subselect (ADDED NEW SCENARIO)
				3. Added limit override				
*/
public with sharing class TS_CustomLookUpController {
    
    public static Boolean hasException = false;
    public class TS_CustomLookUpControllerException extends Exception {}

    @AuraEnabled
    public static List < sObject > fetchLookUpValues(String searchKeyWord, String ObjectName, String subLabel, Boolean filterResults, String whereClause, String additionalFields, String nameOrClause, String whereClauseSuffix, String searchId,
                                                     Boolean hasNestedSubSelect, String SUBQadditionalFields, String SUBQObjectName, String SUBQwhereClause, String SUBQKeyWord,    
                                                     Boolean ignoreLimit, Boolean isExact, Boolean isFromCaseRegistration) {
        system.debug('ObjectName-->' + ObjectName);		
                                                         
		//INITIALIZE
		String sQuery;
        String subQuery;
		List <sObject> returnList = new List <sObject>();  
                                                         
        //FOR STANDARD QUERY Dynamic SOQL Query For Fetch Record List with LIMIT 5                                               	
        String searchKey = searchKeyWord + '%';
        subLabel = String.isNotEmpty(subLabel) ? ',' + subLabel : '';
        additionalFields = String.isNotEmpty(additionalFields) ? ',' + additionalFields : '';        
        whereClause = String.isNotEmpty(whereClause) ? 'AND ' + whereClause : '';
        nameOrClause = String.isNotEmpty(nameOrClause) ? '(Name LIKE: searchKey OR ' + nameOrClause + ') ' : 'Name LIKE: searchKey ';
		whereClauseSuffix = whereClauseSuffix != null ? whereClauseSuffix : '';
		        
		//FOR NESTED WITH SUBQUERY		                                                                                                                                                                                           
        hasNestedSubSelect = hasNestedSubSelect != null ? hasNestedSubSelect : false;
		ignoreLimit = ignoreLimit != null ? ignoreLimit : false; 
		isExact = isExact != null ? isExact : false; 
		SUBQadditionalFields = SUBQadditionalFields != null ? SUBQadditionalFields : '';                                                         
		SUBQObjectName = SUBQObjectName != null ? SUBQObjectName : '';
		SUBQwhereClause = SUBQwhereClause != null ? SUBQwhereClause : '';
		SUBQKeyWord = SUBQKeyWord != null ? SUBQKeyWord : '';
                		
        try{                       
            //FOR NESTED SUB SELECT			
            if(hasNestedSubSelect == true){  
				if(SUBQKeyWord != null){ 
                    //SELECT :SUBQADDITIONALFIELDS FROM :SUBJOBJECTNAME WHERE :SUBQWHERECLAUSE IN(:SUBQKEYWORD)
                    subQuery = 'select '
                                + string.escapeSingleQuotes(SUBQadditionalFields) 
                                + ' from ' 
                                + string.escapeSingleQuotes(SUBQObjectName) 
                                + ' where '                             
                                + string.escapeSingleQuotes(SUBQwhereClause)
                                + '(\'' + string.escapeSingleQuotes(SUBQKeyWord) +'\')'; 
                                                                        
                    List<sObject> subQueryRecords = Database.query(subQuery);                    
                    List<String> subQueryFieldsSplit = SUBQadditionalFields.split('\\.'); 
                    String subQueryRecordsString = '';
                    Integer nullFieldsCtr = 0;
                    
                    system.debug('subselectQuery '+ subQuery);
                    
                    //START MAIN QUERY                                                                                                                                                                                      
                    if(!subQueryRecords.isEmpty()){    					
                         for(sObject sObj: subQueryRecords){                                   
                             if(subQueryFieldsSplit[0] != null && subQueryFieldsSplit[1] != null && sObj.getSobject(subQueryFieldsSplit[0]) != null && sObj.getSobject(subQueryFieldsSplit[0]).get(subQueryFieldsSplit[1]) != null){
                                //TO CONVERT Relationship.FieldName(AccountLocation__r.Apttus_Config2__AccountId__c) TO FieldName (Apttus_Config2__AccountId__c)
                           		subQueryRecordsString = subQueryRecordsString + '\'' + sObj.getSobject(subQueryFieldsSplit[0]).get(subQueryFieldsSplit[1]) + '\',';                                       
                             }                  
                             else {                                 
                                nullFieldsCtr++;
                             }
                        }             
                        
                        if(!subQueryRecords.isEmpty() && subQueryRecords.size() != nullFieldsCtr){
                            //SELECT :SUBLABEL :ADDITIONALFIELDS FROM :OBJECTNAME WHERE NAME != NULL AND :WHERECLAUSE IN(:SUBQUERY_RESULT) :WHERECLAUSESUFFIX LIMIT 5
                            sQuery =  'select id ' 
                                            + string.escapeSingleQuotes(subLabel) 
                                            + string.escapeSingleQuotes(additionalFields) 
                                            + ' from ' 
                                            + string.escapeSingleQuotes(ObjectName) 
                                            + ' where id != null '
                                            + string.escapeSingleQuotes(whereClause)    
                                            + '(' + subQueryRecordsString.substring(0,subQueryRecordsString.length()-1) +')'                                   
                                            + string.escapeSingleQuotes(whereClauseSuffix) 
                                            + ' limit 5'; 
                        }                                                
                    }   
            	}
            }    
            else if(isExact == true) {    
                if(searchId != null){
                    sQuery =  'select id ' 
                                    + string.escapeSingleQuotes(subLabel) 
                                    + string.escapeSingleQuotes(additionalFields) 
                                    + ' from ' 
                                    + string.escapeSingleQuotes(ObjectName) 
                                    + ' where id != null '
                                    + string.escapeSingleQuotes(whereClause) 
                        			+ '(\'' + string.escapeSingleQuotes(searchId) + '\')' 
                                    + string.escapeSingleQuotes(whereClauseSuffix)
                                    + ' limit 5';
                }
            }
            //STANDARD QUERY
            else {        
                if(!filterResults){                    
                    sQuery =  'select id, Name' 
                                    + subLabel
                                    + ' from ' 
                                    + ObjectName
                                    + ' where Name LIKE: searchKey order by createdDate DESC limit 5';
                } 
                else {                    
                    sQuery =  'select id, Name' 
                                    + subLabel
                                    + additionalFields
                                    + ' from ' 
                                    + ObjectName
                                    + ' where '
                                    + nameOrClause
                                    + whereClause
                                    + ' ORDER BY createdDate DESC limit 5';
                }
            }            
            
            //REMOVE LIMIT 5 
            if(ignoreLimit == true && sQuery != null && sQuery != ''){
                List<String> splitString = sQuery.split('limit');
                sQuery = splitString[0];
            }
            
            System.debug('sQuery ' + sQuery);
            System.debug('ignoreLimit ' + ignoreLimit);

            List <sObject> lstOfRecords = new List<sObject>();
            if(sQuery != null){
            	
                //APPLICABLE TO CASEREGISTRATION ONLY
                //TO CHECK INDIRECT CONTACT FROM ACCOUNT
                if(isFromCaseRegistration == true){
                                         
                    Set<Id> conIdList = new Set<Id>();
                    Set<Id> mainConId = new Set<Id>();
                    List<SObject> topResult = new List<SObject>();
                    List<SObject> botResult = new List<SObject>();
                                            
                    List<sObject> sobjList = Database.query(sQuery);                     
                    for(sObject sobj : sobjList){                      
                      String contactId = (String) sobj.getSObject('Contact').get('Id');      
           			  conIdList.add(contactId);                                                 
                                              
                      String contactAccountId = (String) sobj.getSObject('Contact').get('AccountId');      
                      String relationshipAccountId = (String) sobj.get('AccountId');   
                      Boolean mainServicePerson = (Boolean) sobj.getSObject('Contact').get('Main_Service_Person__c');      
                      //GET ALL DIRECT CONTACT + MAINSERVICEPERSON
                      if(contactAccountId == relationshipAccountId && mainServicePerson == true){                          
                            mainConId.add(contactId);
                      }
                    }
                    
                    if(!conIdList.isEmpty()){
                        //GET ALL CONTACTS FROM ACCOUNT CONTACT RELATION, DONT CHANGE FIELDS QUERIED
                        List<SObject> conList = [SELECT Id, Name, Main_Commercial_Person__c, Main_Service_Person__c, Account.Name, AccountId, RecordType.Name FROM Contact WHERE Id IN:conIdList ORDER BY NAME ASC];
                        if(!conList.isEmpty()){
                            if(!mainConId.isEmpty()){
                                for(SObject con : conList){
                                    //IF MAIN CONTACT ADD ON THE TOP LIST
                                    if(mainConId.contains(con.Id)){
                                        topResult.add(con);
                                    }	
                                    //IF NOT MAIN CONTACT ADD ON BOTTOM LIST
                                    else {
                                        botResult.add(con);
                                    }                                
                            	}
                                
                                if(!topResult.isEmpty()){
                                    returnList.addAll(topResult);
                                }
                                if(!botResult.isEmpty()){
                                    returnList.addAll(botResult);
                                }
                            }
                            else {
                                returnList.addAll(conList);
                            }                                                        
                        }
                    }
                                                     
                }
                
                //FROM OTHER SOURCES
                else {
                    lstOfRecords = Database.query(sQuery);
                    if(!lstOfRecords.isEmpty()){
                        for (sObject obj: lstOfRecords) {
                            returnList.add(obj);
                        }
                	}  
                }                                                  
            }
                        
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_CustomLookUpControllerException('Force to throw an exception');
            }
                
        } catch(Exception ex){
            System.debug(ex);
            CustomLogging.debugException(ex);
            CustomLogging.pop();
        }
        
        return returnList;
    }
}