/*
* @author        Archi Delphinanto
* @date                 
* @description   Controller class for TS_RecordHeader/TS_createCaseRecord/TS_createCaseRecordFS Lightning Component
* @revision(s)   4 May 2018, Archi Delphinanto implemented Object Level (Access) Security, as part of Code Review actions.
                 27 Sep 2018, Karen Hung added method checkEmailDomain for beforeinsert, part of a user story
*/
public with sharing class EmailMessageTriggerHandler implements ITriggerHandler{
    public static Boolean isTriggerDisabled = true;
    public static Boolean hasException = false;
    public class EmailMessageTriggerHandlerException extends Exception {  }
    
    public void BeforeInsert(List<SObject> newItems){
        /* EmailMessageTriggerHandler.updateContactEmailAddress updateCon = new EmailMessageTriggerHandler.updateContactEmailAddress();
        updateCon.updateContactEmail(newItems);
        checkEmailDomain(newItems); */
        //getMessageBody(newItems);
    }
    
    public void BeforeUpdate(List<SObject> newList, Map<Id, SObject> newMapItems, List<SObject> oldList, Map<Id, SObject> oldMapItems) { 
    }
    
    public void BeforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems){ 
    }
    
    public void AfterInsert(List<SObject> newList, Map<Id, SObject> newMapItems){
        System.debug('EmailMessageTriggerHandler - AfterInsert');
        
        //Added as part of security best practice, CRUD check on the object      
        Boolean hasAccessRightOnEmailMessage  = TS_UtilityClass.isSObjectAccessible(new String[] {'EmailMessage' });
        Boolean hasUpdateRightOnCase  = TS_UtilityClass.isSObjectUpdateable(new String[] {'Case' });
        Boolean hasAccessRightOnCountrySetting  = TS_UtilityClass.isSObjectAccessible(new String[] {'CountrySetting__c' });
        
        if (hasAccessRightOnEmailMessage && hasUpdateRightOnCase && hasAccessRightOnCountrySetting) {
            updateCaseSalesOrg(newList);
        }
        
        /* 25-10-2017 deactivated as per  JIRA: 597 Sales org liogic cuases email auto set to "read" now solved with Record types instead <Bas Hoeberigs>        
        deleteEmailMessageRelation(newList); */
    }    
    
    public void AfterUpdate(List<SObject> newList , Map<Id, SObject> newMapItems, List<SObject> oldList, Map<Id, SObject> oldMapItems){
    }
    
    public void AfterDelete(List<SObject> oldList, Map<Id, SObject> oldMapItems){
    }
    
    public void AfterUndelete(List<SObject> newList, Map<Id, SObject> newMapItems){        
    }
    
    public Boolean IsDisabled() {
        if (TriggerSettings__c.getInstance().EmailMessageTrigger__c) {
            return false;
        } else {
            return isTriggerDisabled;
        }
    }

    /*
    * Ata Khan
    * 19.2.2019
     * Method to check the EmailMessages and pullout the textbody of the incoming message. This is a workaround for the limit of 32K characters in the email message on case object.
    */
    /* public void getMessageBody(List<EmailMessage> newItems){
        String s = 'On ';
        String month = system.now().format('MMM');//Integer.valueof(String.valueof(Date.today()).split('-')[1]);
        String todayDate = system.now().format('d');//Integer.valueof(String.valueof(Date.today()).split(' ')[0].split('-')[2]);
        String dayofWeek = system.now().format('E');
        String year = system.now().format('Y');
        s = s + dayofWeek + ', ' + month + ' ' + todayDate + ', ' + year;
        system.debug(s);
        for(EmailMessage em: newItems){
            if(em.Incoming == true && String.isNotBlank(em.ParentId) && String.isNotBlank(em.RelatedToId) && em.RelatedToId.getsobjecttype() == Schema.Case.getSObjectType()){
                String textmsg = em.TextBody;
                textmsg = textmsg.replace('> > >', '<br/>').replace('>>>', '<br/>').replace('> >', '<br/>').replace('\r\n', '<br/>').replace('>', '<br/>');
                textmsg = textmsg.replace(s,'<br/>'+s).replace('<br/> <br/>'+s,'<br/>'+s);
                //em.HtmlBody = textmsg.replace('> > >', '<br/>').replace('>>>', '<br/>').replace('> >', '<br/>').replace('\r\n', '<br/>').replace('>', '<br/>');
                em.HtmlBody = textmsg;
                System.debug('I am in if condition');
            }
            System.debug('Email Message:2:::'+em.Htmlbody);
        }
    } */

    /* Method to update the salesorg on a case based on the ToAddress on the emailmessage sent in salesforce
       ToAddress will be looked into the country setting and the corresponding country value will be picked.
       Modified by Ata to include default from address on Case record for email-to-case scenario.
    */
    public void updateCaseSalesOrg(List<EmailMessage> newItems){
        CustomLogging.push('updateCaseSalesOrg', 'EmailMessageTriggerHandler');
        Set<Id> caseIds = new Set<Id>();
        Map<String, CountrySetting__c> map_countrySettings = new Map<String, CountrySetting__c>();
        List<Case> parentCases = new list<Case>();
        Set<String> mailList = new Set<String>();
        for(EmailMessage em: newItems){
            if(em.incoming==true && em.parentId!=null){
                caseIds.add(em.parentId);
            }
            
            /* mailList.add(em.FromAddress);
            mailList.add(em.ToAddress);
            System.debug('FromAddress:'+em.FromAddress);
            System.debug('To Address::'+em.ToAddress); */

            //HANDLE multiple toAddress for correct Sales Organization assignment
            String STR_TOADDRESS = em.toAddress;
            if(!String.isBlank(STR_TOADDRESS)){
                if(STR_TOADDRESS.contains(';')){
                    STR_TOADDRESS = STR_TOADDRESS.deleteWhitespace();
                    mailList.addall(STR_TOADDRESS.split(';'));
                } else{
                    mailList.add(STR_TOADDRESS);
                }
            }
            
            /* String STR_FROMADDRESS = em.FromAddress;
            if(!String.isBlank(STR_FROMADDRESS)){
                if(STR_FROMADDRESS.contains(';')){
                    STR_FROMADDRESS = STR_FROMADDRESS.deleteWhitespace();
                    mailList.addall(STR_FROMADDRESS.split(';'));
                } else{
                    mailList.add(STR_FROMADDRESS);
                }
            } */

            //DOO-5122 - Xen Reyes - Dec. 1, 2020
            String STR_CCADDRESS = em.CcAddress;
            if(!String.isBlank(STR_CCADDRESS)){
                if(STR_CCADDRESS.contains(';')){
                    STR_CCADDRESS = STR_CCADDRESS.deleteWhitespace();
                    mailList.addall(STR_CCADDRESS.split(';'));
                } else{
                    mailList.add(STR_CCADDRESS);
                }
            }

        }

        if(!caseIds.isEmpty()){
            String recType = Schema.SObjectType.CountrySetting__c.getRecordTypeInfosByName().get('Country Email Rules').getRecordTypeId();
            for(CountrySetting__c c: [SELECT Id, email__c, country__c, Inbound_email__c FROM CountrySetting__c WHERE CaseType__c = 'Qualify Case' AND Active__c = true AND recordtypeId =: recType AND Inbound_email__c IN : mailList]){
                
                /* if(!map_countrySettings.containsKey(c.email__c)){
                    map_countrySettings.put(c.email__c,c);
                }*/
                //DOO-5122 - Xen Reyes - Dec. 1, 2020
                if(!map_countrySettings.containsKey(c.Inbound_email__c)){
                    map_countrySettings.put(c.Inbound_email__c,c);
                }
            }
        }

        System.debug('map_countrySettings::'+map_countrySettings);
        if(!map_countrySettings.isEmpty()){
            for(EmailMessage em: newItems){

                Boolean matchFound = false;
                if(em.incoming == true && em.parentId!=null){
                    
                    System.debug('Email Messaging Record:');
                    System.debug(em);

                    /* HANDLE multiple toAddress for correct Sales Organization assignment
                    XEN REYES Feb. 7, 2019 */
                    
                    //Added by Ata to check if comma is present in the toemail address
                    List<String> toAddressList = new List<String>();
                    if(em.toAddress != null){
                        String str = em.toAddress;
                        str = str.deleteWhitespace();

                        if(str.contains(';')){
                            toAddressList.addall(str.split(';'));
                        } else{
                            toAddressList.add(str);
                        }
                    }
                    
                    //GET THE ADDRESSES IN CC
                    //DOO-5122 - Xen Reyes - Dec. 1, 2020
                    List<String> ccAddressList = new List<String>();
                    if(em.CcAddress != null){
                        String str_cc = em.CcAddress;
                        str_cc = str_cc.deleteWhitespace();

                        if(str_cc.contains(';')){
                            ccAddressList.addall(str_cc.split(';'));
                        } else{
                            ccAddressList.add(str_cc);
                        }
                    }

                    if(!toAddressList.isEmpty()){
                        for(String strVar : toAddressList){
                            if(map_countrySettings.containsKey(strVar)){
                                if(map_countrySettings.get(strVar).country__c != null){
                                    Case cse = new Case(    Id = em.parentId, 
                                                            SalesOrganization__c = map_countrySettings.get(strVar).country__c,
                                                            Default_From_Address__c = map_countrySettings.get(strVar).email__c, 
                                                            Country_Setting_Signature_Record__c=map_countrySettings.get(strVar).Id);
                                    parentCases.add(cse);
                                    matchFound = true;
                                    break;
                                }
                            }
                        }
                    }

                    //CHECK ONLY CC IF MATCH NOT FOUND
                    //DOO-5122 - Xen Reyes - Dec. 1, 2020
                    if(!matchFound && !ccAddressList.isEmpty()){
                        for(String strVar : ccAddressList){
                            if(map_countrySettings.containsKey(strVar)){
                                if(map_countrySettings.get(strVar).country__c != null){
                                    Case cse = new Case(    Id = em.parentId, 
                                                            SalesOrganization__c = map_countrySettings.get(strVar).country__c,
                                                            Default_From_Address__c = map_countrySettings.get(strVar).email__c, 
                                                            Country_Setting_Signature_Record__c=map_countrySettings.get(strVar).Id);
                                    parentCases.add(cse);
                                    break;
                                }
                            }
                        }
                    }
                    
                    System.debug('Parent Cases To Update:');
                    System.debug(parentCases);
                }
            }
            
            try{
                if(!parentCases.isEmpty() && Schema.sObjectType.Case.isUpdateable()){
                    CaseTriggerHandler.caseEntitlementRunOnce = true; 
                    CaseTriggerHandler.emailToCase = true;
                    update parentCases;
                }
            
                if (Test.isRunningTest() && hasException) {
                    throw new EmailMessageTriggerHandlerException('Force to throw an exception');
                }
            }
            catch(Exception ex){
                CustomLogging.debugException(ex);
                CustomLogging.pop();
                System.debug(ex);
            }
        }
        
        CustomLogging.pop();
    }
}