/**
 * Class Name: ContactTriggerHandler
 * @author: Jed Samaniego - Accenture
 * Date: 23-Nov-2017
 * Requirement: Trigger for Contact
 * @description: 
 *
 */
public with sharing class ContactTriggerHandler implements ITriggerHandler{
    Map<Id, Contact> oldMap = new  Map<Id, Contact>();
    public static Boolean isTriggerDisabled = true;
    private static final User u = UserDAO.userInformation();

    
    public void beforeInsert(List<Contact> newContactList){
        validateMainContact(newContactList);
        validateMainService(newContactList);
        generateHash(newContactList, oldMap);
    } 
 

    public void beforeUpdate(List<Contact> newContactList, Map<Id, SObject> newItems, List<Contact> oldList, Map<Id, SObject> oldContactMap){
        Map<Id, Contact> oldMapCon = (Map<Id, Contact>) oldContactMap;
        validateMainContact(newContactList);
        validateMainService(newContactList);
        generateHash(newContactList, oldMapCon);
        updateRecordTypeId(newContactList, oldMapCon);
    }
 
    public void beforeDelete(List<Contact> oldList, Map<Id, SObject> oldItems){
    
    }
 
    public void afterInsert(List<Contact> newContactList, Map<Id, SObject> newItems){
        OnInsertCreateIntegrationLog(newContactList);
        createIndividual(newContactList);
    }
 
    public void afterUpdate(List<Contact> newContactList , Map<Id, SObject> newItems, List<Contact> oldList, Map<Id, SObject> oldContactMap){
        if (checkRecursive.run == true) {
            Map<Id, Contact> oldConMap = (Map<Id, Contact>) oldContactMap;
            OnUpdateCreateIntegrationLog(newContactList, oldConMap);
            if (TriggerSettings__c.getInstance().ConsentTrigger__c == true){
                consentUpdateFromBoomi(newContactList, oldConMap);
                updateconsentonarchive(newContactList, oldConMap);
            }
        }
    }
 
    public void afterDelete(List<Contact>oldList, Map<Id, SObject> oldItems){
        
    }
 
    public void afterUndelete(List<Contact> newList, Map<Id, SObject> newItems){
        
    }
    
    public Boolean IsDisabled(){
        if (TriggerSettings__c.getInstance().ContactTrigger__c == true) {
            return false;
        } else {
            return isTriggerDisabled;
        }
    }
    
    /**
     * Method Name: validateMainContact
     * @author: Jed Samaniego
     * Date: 23-Nov-2017
     * Requirement: 
     * @description: 
     *
     */

    public static void validateMainContact (List<Contact> newContactList){
        CustomLogging.push('validateMainContact', 'ContactTriggerHandler');
        Set<Id> accountSet = new Set<id>();
        List<Contact> xList = new List<Contact>();
        List<Contact> contactList = new List<Contact>();
        
        try {
            for (Contact c : newContactList){
                accountSet.add(c.AccountId);
            }
            
            contactList = [Select Id, AccountId, Main_Commercial_Person__c, Name from Contact where AccountId in: accountSet and id not in: newContactList];

            if (!contactList.IsEMpty()){
                for (Contact con : ContactList){
                    if (con.Main_Commercial_Person__c == True) {
                        xList.add(con);
                    }
                }
    
                for (Contact conError : newContactList){
                    for (Contact x : xList) {
                        if (conError.AccountId == x.AccountId && conError.Main_Commercial_Person__c == True && conError.Id <> x.Id){
                            //conError.adderror('ERROR: There is already an Identical Record: <a href=\''+URL.getSalesforceBaseUrl().toExternalForm() + '/' + x.Id +'>Go to Dupe Record</a>', false);
                            conError.addError('Only one Main Commercial Person per Account is allowed, ' + x.Name + ' is already the Main Commercial Person'); 
                        }
                    }    
                }        
            }  
        } catch(Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();      
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        CustomLogging.pop();   
    }
    
    /**
     * Method Name: OnInsertCreateIntegrationLog
     * @author: Alvin Lomod
     * Date: 06-December-2017
     * Requirement: KASM-567
     * @description: Create Integration Log when Contact is created
     *
     */
    
    public static void OnInsertCreateIntegrationLog (List<Contact> newContactList){
        
        CustomLogging.push('OnInsertCreateIntegrationLog', 'ContactTriggerHandler');
        
        List<Integration_Log__c> integLogsList = new List<Integration_Log__c>();
        
        //Avoid creating iLog if Contact is created by user with this profile
        Id userProfileId = Userinfo.getProfileId();
        Id IntegDigitalProf = [Select Id from Profile Where Name =: 'JDE-Integration-Digital' LIMIT 1].Id;
        Id recordTypeIdServiceProvider = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(SM_Constants.ContactServiceProvider).getRecordTypeId();
        Map<String, Boolean> contactDigital = UserDAO.digitalIntegrationInformation('Contact');
        for(Contact con : newContactList){
            
            //create Integration Log is SAP PO Updated is false
            if (con.Sales_Organization__c != Null) {
                if(!con.SAP_PO_Updated__c && con.RecordTypeId != recordTypeIdServiceProvider && con.Batch_Import_Flag__c == false && contactDigital.get(con.Sales_Organization__c)){
                    integLogsList.add(new Integration_Log__c(Object_Id__c = con.Id,
                                                             Object__c = 'Contact Digital',
                                                             Integration_Status__c = INT_Constants.INITIAL,
                                                             Contact__c = con.Id));
                    
                }
            }
            
            
        }
                              
        try
        {
            if (!integLogsList.isEmpty()) {
                insert integLogsList;
                checkRecursive.run = false;
                system.debug(integLogsList);
            }
        }
        catch(Exception ex)
        {
            CustomLogging.debugException(ex);
            CustomLogging.pop();      
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        CustomLogging.pop();   
    }
    
    /**
     * Method Name: OnUpdateCreateIntegrationLog
     * @author: Alvin Lomod
     * Date: 06-December-2017
     * Requirement: KASM-567
     * @description: Create Integration Log when Contact is updated
     *
     */
    
    public static void OnUpdateCreateIntegrationLog (List<Contact> newContactList, Map<Id, Contact> oldContactMap){
        
        CustomLogging.push('OnUpdateCreateIntegrationLog', 'ContactTriggerHandler');
        
        List<Integration_Log__c> integLogsList = new List<Integration_Log__c>();
        Id recordTypeIdServiceProvider = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(SM_Constants.ContactServiceProvider).getRecordTypeId();
        Set<String> EPIfieldSet = new Set<String>();
        Map<String, Boolean> contactDigital = UserDAO.digitalIntegrationInformation('Contact');
        //dynamically get the fields from the field set and then use the same for comparison in the trigger. For EPI iLog
        for(Schema.FieldSetMember fields :Schema.SObjectType.Contact.fieldSets.getMap().get('EPI_Contact_Field_Set').getFields()){
            EPIfieldSet.add(fields.getFieldPath());
        }
        
        for(Contact con : newContactList){
            
            //create Integration Log is SAP PO Updated is false and following fields are updated
            //list of fields came from FD_INT_Digital_031_Customer Master Data Contact Data SFDC-EPISERVER.xls
            
            //check if at least one of the fields were updated
            Contact oldCon = (Contact)oldContactMap.get(con.Id);
            set<String> changedEPIFieldSet  = new Set<String>();
            for(string s: EPIfieldSet)
            {
                if(con.get(s) != oldCon.get(s))
                {
                    changedEPIFieldSet.add(s);//adding fields whose value changed
                }
            }
            
            if(!con.SAP_PO_Updated__c && changedEPIFieldSet.size() > 0 && con.RecordTypeId != recordTypeIdServiceProvider && con.Batch_Import_Flag__c == false && contactDigital.get(con.Sales_Organization__c)){
            
                integLogsList.add(new Integration_Log__c(Object_Id__c = con.Id,
                                                     Object__c = 'Contact Digital',
                                                     Integration_Status__c = INT_Constants.INITIAL,
                                                     Contact__c = con.Id));
            
            }
            
        }
        
        try
        {
            if (!integLogsList.isEmpty()) {   
                insert integLogsList;
                checkRecursive.run = false;
                system.debug(integLogsList);
            }
        }
        catch(Exception ex)
        {
            CustomLogging.debugException(ex);
            CustomLogging.pop();      
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        CustomLogging.pop();   
        
    }
    
    /**
     * Method Name: validateMainService
     * @author: Alvin Lomod
     * Date: 05-Feb-2018
     * Requirement: KASM-568
     * @description: Only 1 contact related to a single ‘direct’ account can be marked as ‘Main Service' contact person. One contact person can have both the Main Commercial Checkbox as well as the Main Service checkbox checked
     *
     */

    public static void validateMainService (List<Contact> newContactList){
        CustomLogging.push('validateMainService', 'ContactTriggerHandler');
        Set<Id> accountSet = new Set<id>();
        List<Contact> xList = new List<Contact>();
        List<Contact> contactList = new List<Contact>();
        try {
            for (Contact c : newContactList){
                accountSet.add(c.AccountId);
            }
            contactList = [Select Id, AccountId, Main_Service_Person__c, Name from Contact where AccountId in: accountSet and id not in: newContactList];
                
            if (!contactList.IsEmpty()){
                for (Contact con : ContactList){
                    if (con.Main_Service_Person__c == True) {
                        xList.add(con);
                    }
                }
    
                for (Contact conError : newContactList){
                    for (Contact x : xList) {
                        if (conError.AccountId == x.AccountId && conError.Main_Service_Person__c == True && conError.Id <> x.Id){
                            //conError.adderror('ERROR: There is already an Identical Record: <a href=\''+URL.getSalesforceBaseUrl().toExternalForm() + '/' + x.Id +'>Go to Dupe Record</a>', false);
                            conError.addError('Only one Main Service Person per Account is allowed, ' + x.Name + ' is already the Main Service Person'); 
                        }
                    }    
                }        
            }     
        } catch(Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();      
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        CustomLogging.pop();   
    }
    
    /**
     * Contact Management New Functionality
     * @author: Glenn Serrano
     * Date: 18 - June - 2020
     * Requirement: DOS-1596
     * @description: As a marketing manager I want to be able to store consent information so that JDE is compliant
     *
     */

    public static void createIndividual(List<Contact> newContactList){
        CustomLogging.push('createIndividual', 'ContactTriggerHandler');
        try{
            List<Contact> contactFiltered = new List<Contact>();
            if (!newContactList.isEmpty()){
                for (Contact c : newContactList){
                    if (c.LastName != null && c.Being_Converted__c == false && c.IndividualId == null){
                        contactFiltered.add(c);
                    }
                }

                if (!contactFiltered.isEmpty()){
                    SM_ContactUtil.createIndividual(contactFiltered);
                }
            }

        } catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop();   
    }

    /**
     * Conesnt Management New Functionality
     * @author: Glenn Serrano
     * Date: 1 - September - 2020
     * Requirement: DOS-1628
     * @description: As a marketing manager I want to ensure that personal data is not sent when using URLS so that JDE is compliant
     *
     */

    public static void generateHash(List<Contact> newContactList, Map<Id, Contact>  oldContactMap){
        CustomLogging.push('generateHash', 'ContactTriggerhandler');
        try{
            List<Contact> ContactFiltered = new List<Contact>();
            if (!newContactList.isEmpty()){
                for (Contact c : newContactList){
                    if (checkemailneworupdate(c, oldContactMap)){
                        ContactFiltered.add(c);
                    }
                }

                if (!ContactFiltered.isEmpty()){
                    SM_ContactUtil.generateHash(ContactFiltered);
                }
            }

        } catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop();   
    }

    private static Boolean checkemailneworupdate(Contact con, Map<Id, Contact> oldContactMap){
        Contact oldContact;
        Boolean Contactupdate = false;
        if (!oldContactMap.isEmpty()){
            oldContact = oldContactMap.get(con.Id);
            if (con.Email != oldContact.Email){
                Contactupdate = true;
            }
        }
        else {
            if (con.Email != null){
                Contactupdate = true;
            }
        }
        return Contactupdate;
    }

    /**
     * Conesnt Management New Functionality
     * @author: Glenn Serrano
     * Date: 1 - September - 2020
     * Requirement: DOS-1628
     * @description: As a marketing manager I want to ensure that personal data is not sent when using URLS so that JDE is compliant
     *
     */

    public static void consentUpdateFromBoomi(List<Contact> newContactList, Map<Id, Contact>  oldContactMap){
        CustomLogging.push('consentUpdateFromBoomi', 'ContactTriggerhandler');
        try{
            List<Contact> ContactFiltered = new List<Contact>();
            Set<Id> indids = new Set<Id>();
            if (!newContactList.isEmpty()){
                Contact oldContact;
                for (Contact c : newContactList){
                    oldContact = oldContactMap.get(c.Id);
                    System.debug('IndID: ' + c.IndividualId + c.Consent_Status_Marketing__c + oldContact.Consent_Status_Marketing__c);
                    if (c.IndividualId != null && u.Profile.Name == SM_Constants.JDEDigital && ((c.Consent_Status_Marketing__c != oldContact.Consent_Status_Marketing__c) || 
                        (c.Consent_Status_Profiling__c != oldContact.Consent_Status_Profiling__c) || (c.Consent_Status_Surveys__c != oldContact.Consent_Status_Surveys__c)) || 
                        ((c.Consent_Version_Marketing__c != oldContact.Consent_Version_Marketing__c || c.Consent_Version_Profiling__c != oldContact.Consent_Version_Profiling__c ||
                        c.Consent_Version_Surveys__c != oldContact.Consent_Version_Surveys__c))){
                        ContactFiltered.add(c);
                        indids.add(c.IndividualId);
                    }
                }

                if (!ContactFiltered.isEmpty()){
                    SM_ContactUtil.consentUpdateFromBoomi(ContactFiltered, oldContactMap, indids);
                }
            }

        } catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop();   
    }
    

    /**
     * Conesnt Management New Functionality
     * @author: Glenn Serrano
     * Date: 23 - September - 2020
     * Requirement: DOS-1615
     * @description: As a local marketing manager I want the consent status to be set to Opt-Out if the contact is archived
     *
     */

    public static void updateconsentonarchive(List<Contact> newContactList, Map<Id, Contact>  oldContactMap){
        CustomLogging.push('updateconsentonarchive', 'ContactTriggerhandler');
        try{
            List<Contact> ContactFiltered = new List<Contact>();
            Set<Id> indids = new Set<Id>();
            if (!newContactList.isEmpty()){
                Contact oldContact;
                for (Contact c : newContactList){
                    oldContact = oldContactMap.get(c.Id);
                    if (c.Contact_Status__c != oldContact.Contact_Status__c && c.Archiving_Flag__c != oldContact.Archiving_Flag__c && c.Contact_Status__c == 'Not Valid' && 
                        c.Archiving_Flag__c == true){
                        ContactFiltered.add(c);
                        indids.add(c.IndividualId);
                    }
                }

                if (!ContactFiltered.isEmpty()){
                    SM_ContactUtil.updateconsentonarchive(ContactFiltered, oldContactMap, indids);
                }
            }

        } catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop();   
    }
	 
     /**
     * Update to Standard Contact
     * @author: Karen Hung
     * Date: 26 - October - 2020
     * Requirement: DOO-4525
     * @description: Upgrade Operational Contact (prev. Service Provider) to a Standard Contact
     */
    
    public static void updateRecordTypeId (List<Contact> newContactList, Map<Id, Contact>  oldContactMap){
     	CustomLogging.push('updateRecordTypeId', 'ContactTriggerhandler');
        try{
            List<Contact> ContactFiltered = new List<Contact>();
            String opsContactType = TS_UtilityClass.getRecordTypeIdByName(TS_Constants.OBJ_APINAME_CONTACT, SM_Constants.ContactServiceProvider);
            if (!newContactList.isEmpty()){
                for (Contact c : newContactList){
                    if(c.RecordtypeId == opsContactType && c.Convert_to_Standard_Contact__c != oldContactMap.get(c.Id).Convert_to_Standard_Contact__c && c.Convert_to_Standard_Contact__c == true){
                    	ContactFiltered.add(c);    
                    }                    
                }
                if (!ContactFiltered.isEmpty()){
                   SM_ContactUtil.updateRecordTypeId(ContactFiltered);
                }
            }
            
        }catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop();  
    }
}