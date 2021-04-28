/**
 * @author        Francis Allen Alindogan
 * @date          November 16, 2020
 * @description   Apex batch class used to delete operational contact with an incativity on cases
 * @revision(s)
 */

global without sharing class TS_DeleteOperationalContact_Batch implements Database.Batchable<Contact>{    
    
    //EXCEPTION VARIABLES
    private Date runDate;
    public static Boolean hasException = false;
    public class TS_DeleteOperationalContact_BatchException extends Exception {}    
    
     global TS_DeleteOperationalContact_Batch(Integer addedDays) {
        CustomLogging.push('TS_DeleteOperationalContact_Batch', 'TS_DeleteOperationalContact_Batch');
        if (addedDays == 0 || addedDays == null){
            runDate = date.today();
        }else{
            runDate = date.today().addDays(addedDays);
        }        
        CustomLogging.pop();
    }

    
    global Iterable<Contact> start(Database.BatchableContext bc) {   
        CustomLogging.push(TS_Constants.CONST_START, 'TS_DeleteOperationalContact_Batch');
        CustomLogging.pop();
        String operationalConId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(TS_Constants.TS_CONTACT_RECORDTYPE_OPERATIONALCONTACT).getRecordTypeId();            		
        Integer threshold  = 0 - Integer.valueOf(Label.TS_DeleteOperationalContactThreshold);
        Date dateThreshold = runDate.AddMonths(threshold);  

        //GET ALL CONTACTS       
        List<Contact> conResult = [SELECT Id, Name, Email, Phone FROM Contact WHERE 
                                   Exclude_in_Purging_Operational__c = false AND
                                   Last_Relevant_Activity_Date__c <> null AND
                                   Last_Relevant_Activity_Date__c < :dateThreshold AND //LESS THAN DATE THRESHOLD
								   RecordTypeId =: operationalConId AND //OPERATIONAL CONTACTS ONLY
                                   Id NOT IN (SELECT ContactId
                                              FROM Case
                                              WHERE 											 
                                              Status NOT IN(:TS_Constants.STATUS_CANCELED, :TS_Constants.STATUS_CLOSED) AND 
                                              ContactId != null) //NO OPEN CASE
                                   	AND Id NOT IN (SELECT ContactId FROM User WHERE ContactId !=null)
                                  ];            
    	return conResult;            			               
    }
    
    global void execute(Database.BatchableContext bc, List<Contact> scope){        
        CustomLogging.push(TS_Constants.CONST_EXECUTE, 'TS_DeleteOperationalContact_Batch');
        List<List<SObject>> soslResult = New List<List<SObject>>();
        List<Contact> forDeletion = new List<Contact>();
        List<Case> forContactRemoval = new List<Case>();
        Map<Id, Contact> conMap = new Map<Id, Contact>();
                
        String stringQuery = '\'';
        Integer stringCtr = 0;
        
        if(!scope.isEmpty()){
            //CREATE SOSL QUERY STRING        
            for(Contact con : scope){
                stringQuery = stringQuery + con.Id +' OR ';  //FORMAT 'keyWord1 OR keyWord2'
                stringCtr++;                
                conMap.put(con.Id, con);
            }			          
            
            //REMOVE "OR " SUFFIX 
            if(stringCtr > 0){
                stringQuery = stringQuery.subString(0,stringQuery.length()-4);       
            }
            stringQuery = stringQuery + '\'';
            
            //GET ALL CASES,CONTRACTS,SERVICE CONTRACTS,PARTNER USER OR CUSTOMER PORTAL USERS            
            soslResult = [FIND :stringQuery IN ALL FIELDS RETURNING 
                          Case(Id, ContactId), 
                          Contract(Id, CustomerSignedId), 
                          ServiceContract(Id, ContactId),
                          User(Id, ContactId, Profile.Name, Profile.UserLicense.Name)];            
        }
                                
        //ASSIGN VALUE FROM SOSL                
        List<Case> cseList = ((List<Case>) soslResult[0]);
        List<Contract> ctractList = ((List<Contract>) soslResult[1]);        
        List<ServiceContract> srvCtractList = ((List<ServiceContract>) soslResult[2]);               
        List<User> userList = ((List<User>) soslResult[3]);
        
        List<CaseComment> cseCmList = new List<CaseComment>();
        Set<String> exclusionSet = new Set<String>();
                            
        //CHECK RELATED CASE
        /*
        for(Case cse : cseList){
            if(cse.ContactId != null){
            	exclusionSet.add(cse.ContactId);    
            }               
        }*/
        
                
        //CHECK RELATED CONTRACT		
        for(Contract ctract : ctractList){
            if(ctract.CustomerSignedId != null){
            	exclusionSet.add(ctract.CustomerSignedId);    
            }            
        }

        //CHECK RELATED SERVICE CONTRACT                                            
        for(ServiceContract srv : srvCtractList){
            if(srv.ContactId != null){
            	exclusionSet.add(srv.ContactId);    
            }			
        }
               		              		        
        //DELETE CONTACTS WITHOUT RELATION
		for(Contact con : scope){                                    
            if(!exclusionSet.contains(con.Id)){
				forDeletion.add(con);
            }                                             
		} 
                                                
        if(!forDeletion.isEmpty()){                        
         	List<Case> relatedCse = [SELECT Id, ContactId FROM Case WHERE ContactId IN:forDeletion];
            if(!relatedCse.isEmpty()){
                for(Case cse : relatedCse){         
                    
                    //CREATE CASE COMMENT 
                    if(!conMap.isEmpty() && conMap.get(cse.ContactId) != null){
                        String conName =  conMap.get(cse.ContactId).Name  != null ? conMap.get(cse.ContactId).Name : '';
                        String conEmail = conMap.get(cse.ContactId).Email != null ? conMap.get(cse.ContactId).Email : '';
                        String conPhone = conMap.get(cse.ContactId).Phone != null ? conMap.get(cse.ContactId).Phone : '';
                    	CaseComment cseCm = new CaseComment();                             
                    	cseCm.CommentBody = 'Deleted operational contact due to inactivity.\n' + 
 											'Info: '+ conName +'; '+ conEmail +'; '+ conPhone;
                        cseCm.ParentId = cse.Id;                                                
                    	cseCmList.add(cseCm);    
                    }  
                    
                    //DISASSOCIATE ALL CASES FROM CONTACT
                    cse.ContactId = null;
                	forContactRemoval.add(cse);
                }                                                                
            }
                    	
        	try {                
                //REMOVE CONTACT FROM CASES
                if(!forContactRemoval.isEmpty()){
                    Database.SaveResult[] saveResults_Case = Database.update(forContactRemoval, false);
                    DATABASE_LOGGING(saveResults_Case, null, 'Case Update');                                                    
                }                                
                //INSERT CASE COMMENTS
                if(!cseCmList.isEmpty()){
                    Database.SaveResult[] updateResults_CaseComment= Database.insert(cseCmList, false);
                    DATABASE_LOGGING(updateResults_CaseComment, null, 'Case Comment Insert');                    
                }
                
            	//DELETE CONTACTS
            	Database.DeleteResult[] deleteResults_Contact = Database.delete(forDeletion, false);
				DATABASE_LOGGING(null, deleteResults_Contact, 'Contact Delete');    
                
				if(Test.isRunningTest() && hasException){
                	throw new TS_DeleteOperationalContact_BatchException('Force to throw an exception');
            	}
    		}
            catch(Exception ex){
                System.debug(ex);
                CustomLogging.debugException(ex);
                CustomLogging.pop();
            }
        }                
    }
    
    global void finish(Database.BatchableContext bc){	
        CustomLogging.push('finish', 'TS_DeleteOperationalContact_Batch');
    }
    
     public void DATABASE_LOGGING (List<Database.SaveResult> saveResultList, List<Database.DeleteResult> deleteResultList, String description) {
        CustomLogging.push('TS_DeleteOperationalContact_Batch', 'TS_DeleteOperationalContact_Batch');

        try{            
            //Custom Logging for Database.Error
            Set<String> exception_List_batch = new Set<String>();

            /* Create error message to each Database.Error. */
            if(saveResultList != null && !saveResultList.isEmpty()){
                for (Database.SaveResult sr: saveResultList) {
                    if (!sr.isSuccess()) {
                        //Operation failed. Get error details               
                        for(Database.Error err : sr.getErrors()) {
                            String msg = TS_Constants.ERRBATCH_MSG_01 + err.getStatusCode() + ': ' + err.getMessage() + ': ' + err.getFields();
                            exception_List_batch.add(msg);
                        }
                    }
                }
            }
            
            if(deleteResultList != null && !deleteResultList.isEmpty()){
                for (Database.DeleteResult sr: deleteResultList) {
                    if (!sr.isSuccess()) {
                        //Operation failed. Get error details               
                        for(Database.Error err : sr.getErrors()) {
                            String msg = TS_Constants.ERRBATCH_MSG_01 + err.getStatusCode() + ': ' + err.getMessage() + ': ' + err.getFields();
                            exception_List_batch.add(msg);
                        }
                    }
                }
            }

            //Create custom log record per batch if there is an error.
            if(!exception_List_batch.isEmpty()){
                String mainMessage = '';

                for(String err : exception_List_batch){
                    mainMessage = err + '\n';
                }
                //CREATE CUSTOM LOG
                Custom_Log__c log = new Custom_Log__c(
                    StackTrace__c = 'Delete Operational Contact_Batch: ' + description,
                    Message__c = mainMessage,
                    ExceptionType__c = TS_Constants.DATABASE_ERROR);
                insert log;
            }

            if(Test.isRunningTest() && hasException){
                throw new TS_DeleteOperationalContact_BatchException('Force to throw an exception');
            }

        }catch(Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        CustomLogging.pop();
    }
}