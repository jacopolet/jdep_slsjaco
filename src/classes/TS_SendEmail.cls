//-------------------------------------------------------------------------------------------//
// Author       :   Karen Hung
// Created Date :   October 6, 2020
// Usage        :   DOO-4969 class to handle send email logic/ journey trigger creation
//-------------------------------------------------------------------------------------------/
public without sharing class TS_SendEmail {
  public static Boolean hasException = false;
  public class TS_SendEmailException extends Exception {
  }
	/*
     * Karen Hung
     * 06.10.2020
     * DOO-4969 Method to process logic from TS_Send Email From Case and added fixed by phone & case cancelation scenario
     */
    public void SENDFROMCASE(List<Case> casetoProcess){
        CustomLogging.push('SENDFROMCASE', 'TS_SendEmail');

        Set<Id> contactIdSet = new Set<Id>();
        Set<String> salesOrgSet = new Set<String>();
        List<Journey_Trigger__c> jTriggerToInsert = new List<Journey_Trigger__c>();
        Map<Id, Case> caseToUpdateMap = new Map<Id, Case>();
        Map<Case, Contact> caseContactMap = new Map<Case, Contact>();
        List<TS_EmailUtility.TS_EmailAttributes> emailsForSending = new List<TS_EmailUtility.TS_EmailAttributes>();
        Map<String, CountrySetting__c> countryKnownMap  = new Map<String, CountrySetting__c>();
        Map<String, CountrySetting__c> countryUnknownMap  = new Map<String, CountrySetting__c>();
        Map<String, CountrySetting__c> countryStakeholderMap = new Map<String, CountrySetting__c>();
        Map<String, CountrySetting__c> countryCancelationMap = new Map<String, CountrySetting__c>();
        Map<String, CountrySetting__c> countryCancelationSHMap = new Map<String, CountrySetting__c>();
        Map<String, CountrySetting__c> countryClosureMap = new Map<String, CountrySetting__c>();
        Map<String, CountrySetting__c> countryClosureSHMap = new Map<String, CountrySetting__c>();
        Map<Case, String> forAdditionalContactsMap = new Map<Case, String>();
        //DOO 5243 - Pandian Sundaramoorthy - March 22, 2021
        List<String> regularList = System.Label.TS_Case_Origin_Regular.split(',');

        try{
            for(Case caseRec : casetoProcess){
                contactIdSet.add(caseRec.ContactId);
                salesOrgSet.add(caseRec.SalesOrganization__c);
            }

            Map<Id, Contact> contactMap = new Map<Id, Contact>([SELECT Id, CaseClosureNotification__c, CaseCreationNotification__c, Communication_Preference__c, Email, Preferred_Language__c 
                                                                FROM Contact
                                                                WHERE Id IN :contactIdSet]);
           
            Map<Id, Case> caseExtMap = new Map<Id, Case>([SELECT Id, AccountLocation__r.Name, PhysicalAsset__r.ProductDescription__c, PhysicalAsset__r.SerialNumber__c, PhysicalAsset__r.Building__c, PhysicalAsset__r.Floor__c, PhysicalAsset__r.Area__c, PhysicalAsset__r.CustomerReferenceNumber__c
                                                          FROM Case WHERE Id IN :casetoProcess]);

            List<CountrySetting__c> countrySettingList = getCountrySettings(salesOrgSet);
            Map<String, CountrySetting__c> countryContactMap = new Map<String, CountrySetting__c>();
            String operationalRecordId = TS_UtilityClass.getRecordTypeIdByName(TS_Constants.OBJ_APINAME_CONTACT, TS_Constants.TS_CONTACT_RECORDTYPE_OPERATIONALCONTACT);


            //Get account mapping detail for unknown contact and sending method for each journey trigger subtype
            if(!countrySettingList.isEmpty()){
                for(CountrySetting__c cset : countrySettingList){
                    if(cset.RecordType.DeveloperName == TS_Constants.TS_COUNTRYSETTING_RECORDTYPE_COUNTRY_UNKNOWN_CONTACT){

                        countryContactMap.put(cset.Country__c, cset);

                    }else if(cset.Journey_Trigger_SubType__c == TS_Constants.CASE_CREATION_NOTIF_KNOWN_CUSTOMER ){

                        countryKnownMap.put(cset.Country__c+cset.Origin__c, cset);  

                    }else if(cset.Journey_Trigger_SubType__c == TS_Constants.CASE_CREATION_NOTIF_UNKNOWN_CUSTOMER){

                        countryUnknownMap.put(cset.Country__c+cset.Origin__c, cset);

                    }else if(cset.Journey_Trigger_SubType__c == TS_Constants.CASE_CREATION_NOTIF_STAKEHOLDER){

                        countryStakeholderMap.put(cset.Country__c+cset.Origin__c, cset);

                    }else if(cset.Journey_Trigger_SubType__c == TS_Constants.CASE_CANCEL_NOTIF_KNOWN_CUSTOMER){

                        countryCancelationMap.put(cset.Country__c+cset.Origin__c, cset);

                    }else if(cset.Journey_Trigger_SubType__c == TS_Constants.CASE_CANCEL_NOTIF_STAKEHOLDER ){
                        
                        countryCancelationSHMap.put(cset.Country__c+cset.Origin__c, cset);

                    }else if(cset.Journey_Trigger_SubType__c == TS_Constants.CASE_CLOSURE_NOTIF_KNOWN_CUSTOMER){
                        
                        countryClosureMap.put(cset.Country__c+cset.Origin__c, cset);

                    }else if(cset.Journey_Trigger_SubType__c == TS_Constants.CASE_CLOSURE_NOTIF_STAKEHOLDER){
                        
                        countryClosureSHMap.put(cset.Country__c+cset.Origin__c, cset);

                    }     
                }
            }

            for(Case eachCase : casetoProcess){
                Contact caseContact = new Contact();
                if(contactMap.containsKey(eachCase.ContactId)){
                    caseContact = contactMap.get(eachCase.ContactId);
                }
    
                Case caseRecUpdate = new Case();
                caseRecUpdate.Id = eachCase.Id;
                //DOO 5243 - Pandian Sundaramoorthy - March 22, 2021
                String originValue;
                if(eachCase.Origin != null){
                    originValue = regularList.contains(eachCase.Origin) ? TS_Constants.REGULAR : eachCase.Origin;
                    if(originValue.equalsIgnoreCase('IOT')){
                        originValue = 'IoT';
                    }
                }
                //Create Contact First
                if(eachCase.SalesOrganization__c != null && eachCase.SuppliedEmail != null && eachCase.ContactId == null && eachCase.Contact_Created__c == false){
    
                    CountrySetting__c cset = countryContactMap.get(eachCase.SalesOrganization__c);
                    if(cset !=null && cset.Account__c != null && cset.User__c != null && cset.Language__c != null){
                        
                        //create operational contact            
                        Contact conRec = new Contact(
                        ATANotification__c = true,
                        AccountId = cset.Account__c,
                        CaseClosureNotification__c = true,
                        CaseCreationNotification__c = true,
                        CaseDelayNotification__c = true,
                        Communication_Preference__c = TS_Constants.EMAIL,
                        ETANotification__c = true,
                        Email = eachCase.SuppliedEmail,
                        Function__c = TS_Constants.TS_ConFunction_ServiceContact,
                        LastName = eachCase.SuppliedName != null ? eachCase.SuppliedName : TS_Constants.UNKNOWN_CONTACT,
                        OwnerId = cset.User__c,
                        Preferred_Language__c = cset.Language__c,
                        RecordtypeId = operationalRecordId,
                        Sales_Organization__c = eachCase.SalesOrganization__c);
    
                        //prep for case update contact id after contact insertion
                        caseContactMap.put(caseRecUpdate, conRec);
                    }
                
                //SCENARIO 1 : Case create notification to known Contact
                }else if(eachCase.SalesOrganization__c != null && eachCase.ContactId != null && caseContact != null && caseContact.CaseCreationNotification__c == true &&
                        eachCase.NoCaseCreationNotification__c == false && eachCase.Sent_Case_Create_Notification_to_Contact__c == false && caseContact.Email != null &&
                        caseContact.Communication_Preference__c == TS_Constants.EMAIL && eachCase.Contact_Created__c == false && eachCase.Type == TS_Constants.CASE_TYPE_FIELDSERVICE &&
                        (eachCase.Status == TS_Constants.TS_Status_Open || eachCase.Status == TS_Constants.TS_Status_New) && eachCase.Origin != null){
    					
                          if(countryKnownMap.containsKey(eachCase.SalesOrganization__c+originValue)){
                            
                            String sendingMethod = countryKnownMap.get(eachCase.SalesOrganization__c+originValue).Sending_Method__c;
                            
                            //Create Journey Trigger if send via MC
                            if(sendingMethod == TS_Constants.SEND_VIA_MC){
                                      
                                Journey_Trigger__c jTrigger = createJT(TS_Constants.CASE_CREATION_NOTIF_KNOWN_CUSTOMER, eachCase.Id, eachCase.ContactId, TS_Constants.CASE_CREATE, null, null, caseExtMap.get(eachCase.Id), countryKnownMap.get(eachCase.SalesOrganization__c+originValue).Origin__c);
                                jTriggerToInsert.add(jTrigger);
    
                                //for case update
                                caseRecUpdate.Sent_Case_Create_Notification_to_Contact__c = true;
                                caseToUpdateMap.put(caseRecUpdate.Id, caseRecUpdate);
                                
                            
                            //Send email via apex if Send Via Salesforce Platform
                            }else if(sendingMethod == TS_Constants.SEND_VIA_SF_PLATFORM){
                                
                                //Send Case Creation for a Known Customer
                                emailsForSending.add(sendEmailViaApex(TS_Constants.CASE_CREATION_KNOWN_CUSTOMER, eachCase.Default_From_Address__c, eachCase.Id, eachCase.SalesOrganization__c, eachCase.ContactId, caseContact.Email, TS_Constants.ACKNOWLEDGEMENT, caseContact.Preferred_Language__c));
                                
                                //for case update
                                caseRecUpdate.Sent_Case_Create_Notification_to_Contact__c = true;
                                caseToUpdateMap.put(caseRecUpdate.Id, caseRecUpdate);
                            } 
                        }
    
                        //check for additional case contact
                        forAdditionalContactsMap.put(eachCase, eachCase.AccountLocation__c);
    
                //SCENARIO 2: Case create notification to unknown Contact
                }else if(eachCase.SalesOrganization__c != null && eachCase.SuppliedEmail != null && eachCase.Sent_Case_Create_Notification_to_Contact__c == false &&
                        eachCase.ContactId != null && eachCase.Contact_Created__c == true && caseContact != null && caseContact.CaseCreationNotification__c == true &&
                        eachCase.NoCaseCreationNotification__c == false && caseContact.Email != null && caseContact.Communication_Preference__c == TS_Constants.EMAIL &&
                        eachCase.Type == TS_Constants.TS_CASE_RECORDTYPE_QUALIFYCASE && eachCase.Origin != null){
                       
                        if(countryUnknownMap.containsKey(eachCase.SalesOrganization__c+originValue)){
    
                            //Create Journey Trigger if send via MC
                            if(countryUnknownMap.get(eachCase.SalesOrganization__c+originValue).Sending_Method__c == TS_Constants.SEND_VIA_MC){
                                    
                                Journey_Trigger__c jTrigger = createJT(TS_Constants.CASE_CREATION_NOTIF_UNKNOWN_CUSTOMER, eachCase.Id, eachCase.ContactId, TS_Constants.CASE_CREATE, null, null, caseExtMap.get(eachCase.Id), countryUnknownMap.get(eachCase.SalesOrganization__c+originValue).Origin__c);
                                jTriggerToInsert.add(jTrigger);
    
                                //for case update
                                caseRecUpdate.Sent_Case_Create_Notification_to_Contact__c = true;
                                caseToUpdateMap.put(caseRecUpdate.Id, caseRecUpdate);
                            
                            //Send email via apex if Send Via Salesforce Platform
                            }else if(countryUnknownMap.get(eachCase.SalesOrganization__c+originValue).Sending_Method__c == TS_Constants.SEND_VIA_SF_PLATFORM){
                                
                                //Send Case Creation Unknown Customer
                                emailsForSending.add(sendEmailViaApex(TS_Constants.CASE_CREATION_UNKNOWN_CUSTOMER, eachCase.Default_From_Address__c, eachCase.Id, eachCase.SalesOrganization__c, eachCase.ContactId, caseContact.Email, TS_Constants.ACKNOWLEDGEMENT, caseContact.Preferred_Language__c));
                                
                                //for case update
                                caseRecUpdate.Sent_Case_Create_Notification_to_Contact__c = true;
                                caseToUpdateMap.put(caseRecUpdate.Id, caseRecUpdate);
                            }  
                        }

    
                //SCENARIO 3: Case create contact - Only Stakeholder + criteria for cancelation and closure
                }else if(/*caseContact != null && 
                        (eachCase.NoCaseCreationNotification__c == true || caseContact.CaseCreationNotification__c == false || caseContact.Communication_Preference__c != 'Email' || caseContact.Email == null) &&
                        eachCase.AccountLocation__c != null && eachCase.Type == 'Field Service' && 
                        (eachCase.Status == 'Open' || eachCase.Status == 'New') &&
                        eachCase.Sent_Case_Create_Notif_to_Stakeholder__c == false && eachCase.NoStakeholderNotification__c == false*/
                        caseContact != null &&
                        eachCase.AccountLocation__c != null && 
                        eachCase.Type == TS_Constants.CASE_TYPE_FIELDSERVICE && 
                        eachCase.NoStakeholderNotification__c == false &&
                        
                        (caseContact.Communication_Preference__c != TS_Constants.EMAIL || caseContact.Email == null ||
                        //Case creation
                        ((eachCase.NoCaseCreationNotification__c == true || caseContact.CaseCreationNotification__c == false ) &&  
                        (eachCase.Status == TS_Constants.TS_Status_Open || eachCase.Status == TS_Constants.STATUS_NEW) &&
                        eachCase.Sent_Case_Create_Notif_to_Stakeholder__c == false) ||
                        //Case cancelation
                        ((eachCase.NoCaseCreationNotification__c == true || caseContact.CaseCreationNotification__c == false ) &&  
                        eachCase.Status == TS_Constants.STATUS_CANCELED &&
                        eachCase.Sent_Case_Cancel_Notif_to_Stakeholder__c == false) ||
                        //Case Closure
                        ((eachCase.NoCaseClosureNotification__c == true || caseContact.CaseClosureNotification__c == false ) &&  
                        eachCase.Status == TS_Constants.STATUS_CLOSED && eachCase.External_Solution__c != null &&
                        eachCase.Sent_Case_Closure_Notif_to_Stakeholder__c == false)
                        ) && eachCase.Origin != null                       
                        ){              
    
                        forAdditionalContactsMap.put(eachCase, eachCase.AccountLocation__c);
                        caseToUpdateMap.put(caseRecUpdate.Id, caseRecUpdate);
    
                //SCENARIO 4: FS Case Cancellation
                }else if (eachCase.SalesOrganization__c != null && eachCase.ContactId != null && caseContact != null && caseContact.CaseCreationNotification__c == true &&
                          eachCase.NoCaseCreationNotification__c == false && eachCase.Sent_Case_Cancelation_Notif_to_Contact__c == false && caseContact.Email != null && 
                          caseContact.Communication_Preference__c == TS_Constants.EMAIL && eachCase.Contact_Created__c == false && eachCase.Type == TS_Constants.CASE_TYPE_FIELDSERVICE &&
                          eachCase.Status == TS_Constants.STATUS_CANCELED && eachCase.Origin != null){
                	
                    if(countryCancelationMap.containsKey(eachCase.SalesOrganization__c+originValue)){
    
                        //Create Journey Trigger if send via MC
                        if(countryCancelationMap.get(eachCase.SalesOrganization__c+originValue).Sending_Method__c == TS_Constants.SEND_VIA_MC){
                                    
                            Journey_Trigger__c jTrigger = createJT(TS_Constants.CASE_CANCEL_NOTIF_KNOWN_CUSTOMER, eachCase.Id, eachCase.ContactId, TS_Constants.CASE_CANCELATION, null, null, caseExtMap.get(eachCase.Id), countryCancelationMap.get(eachCase.SalesOrganization__c+originValue).Origin__c);
                            jTriggerToInsert.add(jTrigger);
    
                            //for case update
                            caseRecUpdate.Sent_Case_Cancelation_Notif_to_Contact__c = true;
                            caseToUpdateMap.put(caseRecUpdate.Id, caseRecUpdate);
                        
                        //Send email via apex if Send Via Salesforce Platform
                        }/*else if(countryCancelationMap.get(eachCase.SalesOrganization__c) == 'Send via Salesforce Platform'){
                                
                        } */
    
                    }
    
                    //check for additional case contact
                    if(eachCase.AccountLocation__c != null) forAdditionalContactsMap.put(eachCase, eachCase.AccountLocation__c);
    
                //SCENARIO 5: FS Case Fixed by Phone
                }else if(eachCase.SalesOrganization__c != null && eachCase.ContactId != null && caseContact != null && caseContact.CaseClosureNotification__c == true &&
                        eachCase.NoCaseClosureNotification__c == false && caseContact.Email != null && eachCase.Sent_Case_Closure_Notif_to_Contact__c == false &&
                        caseContact.Communication_Preference__c == TS_Constants.EMAIL && eachCase.Contact_Created__c == false && eachCase.Type == TS_Constants.CASE_TYPE_FIELDSERVICE &&
                        eachCase.Status == TS_Constants.STATUS_CLOSED && eachCase.External_Solution__c != null && eachCase.Origin != null){
    				
                    if(countryClosureMap.containsKey(eachCase.SalesOrganization__c+originValue)){
    
                        //Create Journey Trigger if send via MC
                        if(countryClosureMap.get(eachCase.SalesOrganization__c+originValue).Sending_Method__c == TS_Constants.SEND_VIA_MC){
                                    
                            Journey_Trigger__c jTrigger = createJT(TS_Constants.CASE_CLOSURE_NOTIF_KNOWN_CUSTOMER, eachCase.Id, eachCase.ContactId, TS_Constants.CASE_CLOSURE_FIXED_BY_PHONE, null, null, caseExtMap.get(eachCase.Id), countryClosureMap.get(eachCase.SalesOrganization__c+originValue).Origin__c);
                            jTriggerToInsert.add(jTrigger);
    
                            //for case update
                            caseRecUpdate.Sent_Case_Closure_Notif_to_Contact__c = true;
                            caseToUpdateMap.put(caseRecUpdate.Id, caseRecUpdate);
                        
                        //Send email via apex if Send Via Salesforce Platform
                        }/*else if(countryClosureMap.get(eachCase.SalesOrganization__c) == 'Send via Salesforce Platform'){
                            
                        }*/  
    
                    }
    
                    //check for additional case contact
                    if(eachCase.AccountLocation__c != null) forAdditionalContactsMap.put(eachCase, eachCase.AccountLocation__c);
    
                }
    
            }
    
            //send email/create journey trigger for stakeholder
            if(forAdditionalContactsMap != null){
                Map<Id, Apttus_Config2__AccountLocation__c> accLocMap = new Map<Id, Apttus_Config2__AccountLocation__c>([SELECT Id, Additional_Case_Contact__c, 
                                                                                                                         Additional_Case_Contact__r.CaseCreationNotification__c, Additional_Case_Contact__r.CaseClosureNotification__c,
                                                                                                                        Additional_Case_Contact__r.Communication_Preference__c, Additional_Case_Contact__r.Email, Additional_Case_Contact__r.Preferred_Language__c,
                                                                                                                        Second_Additional_Case_Contact__c, Second_Additional_Case_Contact__r.CaseCreationNotification__c, Second_Additional_Case_Contact__r.CaseClosureNotification__c,
                                                                                                                        Second_Additional_Case_Contact__r.Communication_Preference__c, Second_Additional_Case_Contact__r.Email, Second_Additional_Case_Contact__r.Preferred_Language__c,
                                                                                                                        StakeholderNotification__c FROM Apttus_Config2__AccountLocation__c
                                                                                                                        WHERE Id IN :forAdditionalContactsMap.values()]);
                
                for(Case cse : forAdditionalContactsMap.keySet()){
                    Case caseRecUpdate =  caseToUpdateMap.get(cse.Id);
                    //DOO 5243 - Pandian Sundaramoorthy - March 22, 2021
    				String originValue;
                    if(cse.Origin != null){
                        originValue = regularList.contains(cse.Origin) ? TS_Constants.REGULAR : cse.Origin;
                        if(originValue.equalsIgnoreCase('IOT')){
                            originValue = 'IoT';
                        }
                    }
                    
                    Apttus_Config2__AccountLocation__c caseLoc =  accLocMap.get(forAdditionalContactsMap.get(cse));
                                    
                    //check basic stakeholder conditions
                    if(caseLoc != null && caseLoc.StakeholderNotification__c == true && cse.Type == TS_Constants.CASE_TYPE_FIELDSERVICE && cse.NoStakeholderNotification__c == false && 
                      (cse.Sent_Case_Create_Notif_to_Stakeholder__c == false || cse.Sent_Case_Cancel_Notif_to_Stakeholder__c == false || cse.Sent_Case_Closure_Notif_to_Stakeholder__c == false) && cse.Origin != null){
                        
                        //general criteria for ADDITIONAL STAKEHOLDER 1 & 2
                        if( (caseLoc.Additional_Case_Contact__c != null && 
                            caseLoc.Additional_Case_Contact__r.Email != null && 
                            caseLoc.Additional_Case_Contact__r.Communication_Preference__c == TS_Constants.EMAIL) ||
                            //check second stakeholder
                            (caseLoc.Second_Additional_Case_Contact__c != null && 
                            caseLoc.Second_Additional_Case_Contact__r.Email != null && 
                            caseLoc.Second_Additional_Case_Contact__r.Communication_Preference__c == TS_Constants.EMAIL)){
                            
                            //1. Stakeholder Case Creation 
                            if(countryStakeholderMap.get(cse.SalesOrganization__c+originValue) != null &&
                               cse.Sent_Case_Create_Notif_to_Stakeholder__c == false &&
                               (cse.Status == TS_Constants.TS_Status_Open || cse.Status == TS_Constants.STATUS_NEW)){
    
                                String sendingMethod = countryStakeholderMap.get(cse.SalesOrganization__c+originValue).Sending_Method__c;
    
                                //1a. First stakeholder checking
                                if(caseLoc.Additional_Case_Contact__c != null && caseLoc.Additional_Case_Contact__r.Email != null && caseLoc.Additional_Case_Contact__r.CaseCreationNotification__c == true && caseLoc.Additional_Case_Contact__r.Communication_Preference__c == TS_Constants.EMAIL && caseLoc.Additional_Case_Contact__r.Email != null){
                                    if(sendingMethod == TS_Constants.SEND_VIA_MC){
    
                                        Journey_Trigger__c jTrigger1 = createJT(TS_Constants.CASE_CREATION_NOTIF_STAKEHOLDER, cse.Id, caseLoc.Additional_Case_Contact__c, TS_Constants.CASE_CREATE, null, null, caseExtMap.get(cse.Id), countryStakeholderMap.get(cse.SalesOrganization__c+originValue).Origin__c);
                                        jTriggerToInsert.add(jTrigger1);
            
                                        //for case update
                                        caseRecUpdate.Sent_Case_Create_Notif_to_Stakeholder__c = true;
                                        caseToUpdateMap.put(caseRecUpdate.Id, caseRecUpdate);
    
                                    }else if(sendingMethod == TS_Constants.SEND_VIA_SF_PLATFORM){
                                        
                                        //Send Case Creation for a Known Customer
                                        emailsForSending.add(sendEmailViaApex(TS_Constants.STAKEHOLDER_NOTIF_OPEN, cse.Default_From_Address__c, cse.Id, cse.SalesOrganization__c, caseLoc.Additional_Case_Contact__c, caseLoc.Additional_Case_Contact__r.Email, TS_Constants.STAKEHOLDER, caseLoc.Additional_Case_Contact__r.Preferred_Language__c));
                                        
                                        //for case update
                                        caseRecUpdate.Sent_Case_Create_Notif_to_Stakeholder__c = true;
                                        caseToUpdateMap.put(caseRecUpdate.Id, caseRecUpdate);    
        
                                    }
                                }
    
                                //1b. Second stakeholder checking
                                if(caseLoc.Second_Additional_Case_Contact__c != null && caseLoc.Second_Additional_Case_Contact__r.Email != null && caseLoc.Second_Additional_Case_Contact__r.CaseCreationNotification__c == true && caseLoc.Second_Additional_Case_Contact__r.Communication_Preference__c == TS_Constants.EMAIL){
                                    if(sendingMethod == TS_Constants.SEND_VIA_MC){                               
                                      
                                        Journey_Trigger__c jTrigger2 = createJT(TS_Constants.CASE_CREATION_NOTIF_STAKEHOLDER, cse.Id, caseLoc.Second_Additional_Case_Contact__c, TS_Constants.CASE_CREATE, null, null, caseExtMap.get(cse.Id), countryStakeholderMap.get(cse.SalesOrganization__c+originValue).Origin__c);
                                        jTriggerToInsert.add(jTrigger2);
            
                                        //for case update
                                        caseRecUpdate.Sent_Case_Create_Notif_to_Stakeholder__c = true;
                                        caseToUpdateMap.put(caseRecUpdate.Id, caseRecUpdate);
        
                                    }else if(sendingMethod == TS_Constants.SEND_VIA_SF_PLATFORM){
                                        
                                        //Send Case Creation for a Known Customer
                                        emailsForSending.add(sendEmailViaApex(TS_Constants.STAKEHOLDER_NOTIF_OPEN, cse.Default_From_Address__c, cse.Id, cse.SalesOrganization__c, caseLoc.Second_Additional_Case_Contact__c, caseLoc.Second_Additional_Case_Contact__r.Email, TS_Constants.STAKEHOLDER, caseLoc.Second_Additional_Case_Contact__r.Preferred_Language__c));
                                        
                                        //for case update
                                        caseRecUpdate.Sent_Case_Create_Notif_to_Stakeholder__c = true;
                                        caseToUpdateMap.put(caseRecUpdate.Id, caseRecUpdate);    
        
                                    }
                                }   
    
                            //2. Stakeholder Case Cancelation    
                            }else if(countryCancelationSHMap.get(cse.SalesOrganization__c+originValue) != null &&
                                     cse.Sent_Case_Cancel_Notif_to_Stakeholder__c == false && 
                                     cse.Status == TS_Constants.STATUS_CANCELED){
    
                                String sendingMethodCancelation = countryCancelationSHMap.get(cse.SalesOrganization__c+originValue).Sending_Method__c;
                                
                                //2a. First stakeholder checking
                                if(caseLoc.Additional_Case_Contact__c != null && caseLoc.Additional_Case_Contact__r.Email != null && caseLoc.Additional_Case_Contact__r.CaseCreationNotification__c == true && caseLoc.Additional_Case_Contact__r.Communication_Preference__c == TS_Constants.EMAIL){
                                    if(sendingMethodCancelation == TS_Constants.SEND_VIA_MC){
    
                                        Journey_Trigger__c jTrigger1 = createJT(TS_Constants.CASE_CANCEL_NOTIF_STAKEHOLDER, cse.Id, caseLoc.Additional_Case_Contact__c, TS_Constants.CASE_CANCELATION, null, null, caseExtMap.get(cse.Id), countryCancelationSHMap.get(cse.SalesOrganization__c+originValue).Origin__c);
                                        jTriggerToInsert.add(jTrigger1);                    
            
                                        //for case update
                                        caseRecUpdate.Sent_Case_Cancel_Notif_to_Stakeholder__c = true;
                                        caseToUpdateMap.put(caseRecUpdate.Id, caseRecUpdate);
        
                                    }/*else if(sendingMethodCancelation =='Send via Salesforce Platform'){
        
                                        
        
                                    }*/
                                }
                                //2b. Second stakeholder checking
                                if(caseLoc.Second_Additional_Case_Contact__c != null && caseLoc.Second_Additional_Case_Contact__r.Email != null && caseLoc.Second_Additional_Case_Contact__r.CaseCreationNotification__c == true && caseLoc.Second_Additional_Case_Contact__r.Communication_Preference__c == TS_Constants.EMAIL){
                                    if(sendingMethodCancelation == TS_Constants.SEND_VIA_MC){
                                        
                                        Journey_Trigger__c jTrigger2 = createJT(TS_Constants.CASE_CANCEL_NOTIF_STAKEHOLDER, cse.Id, caseLoc.Second_Additional_Case_Contact__c, TS_Constants.CASE_CANCELATION, null, null, caseExtMap.get(cse.Id), countryCancelationSHMap.get(cse.SalesOrganization__c+originValue).Origin__c);
                                        jTriggerToInsert.add(jTrigger2);
            
                                        //for case update
                                        caseRecUpdate.Sent_Case_Cancel_Notif_to_Stakeholder__c = true;
                                        caseToUpdateMap.put(caseRecUpdate.Id, caseRecUpdate);
        
                                    }/*else if(sendingMethodCancelation =='Send via Salesforce Platform'){
        
                                           
        
                                    }*/
                                }
    
                            //3. Stakeholder Case Closure -  Fixed by Phone                   
                            }else if(countryClosureSHMap.get(cse.SalesOrganization__c+originValue) != null &&
                                     cse.Sent_Case_Closure_Notif_to_Stakeholder__c == false &&
                                     cse.Status == TS_Constants.STATUS_CLOSED && cse.External_Solution__c != null){
    
                                String sendingMethodClosure = countryClosureSHMap.get(cse.SalesOrganization__c+originValue).Sending_Method__c;
                                
                                //3a. First stakeholder checking
                                if(caseLoc.Additional_Case_Contact__c != null && caseLoc.Additional_Case_Contact__r.Email != null && caseLoc.Additional_Case_Contact__r.CaseClosureNotification__c == true && caseLoc.Additional_Case_Contact__r.Communication_Preference__c == TS_Constants.EMAIL){
                                    if(sendingMethodClosure == TS_Constants.SEND_VIA_MC){
    
                                        Journey_Trigger__c jTrigger1 = createJT(TS_Constants.CASE_CLOSURE_NOTIF_STAKEHOLDER, cse.Id, caseLoc.Additional_Case_Contact__c, TS_Constants.CASE_CLOSURE_FIXED_BY_PHONE, null, null, caseExtMap.get(cse.Id), countryClosureSHMap.get(cse.SalesOrganization__c+originValue).Origin__c);
                                        jTriggerToInsert.add(jTrigger1);
            
                                        //for case update
                                        caseRecUpdate.Sent_Case_Closure_Notif_to_Stakeholder__c = true;
                                        caseToUpdateMap.put(caseRecUpdate.Id, caseRecUpdate);
        
                                    }/*else if(sendingMethodClosure =='Send via Salesforce Platform'){        
                                        
        
                                    }*/
                                }
    
                                //3b. Second stakeholder checking
                                if(caseLoc.Second_Additional_Case_Contact__c != null && caseLoc.Second_Additional_Case_Contact__r.Email != null && caseLoc.Second_Additional_Case_Contact__r.CaseClosureNotification__c == true && caseLoc.Second_Additional_Case_Contact__r.Communication_Preference__c == TS_Constants.EMAIL){
                                    if(sendingMethodClosure == TS_Constants.SEND_VIA_MC){
                                        
                                        Journey_Trigger__c jTrigger2 = createJT(TS_Constants.CASE_CLOSURE_NOTIF_STAKEHOLDER, cse.Id, caseLoc.Second_Additional_Case_Contact__c,TS_Constants.CASE_CLOSURE_FIXED_BY_PHONE, null, null, caseExtMap.get(cse.Id), countryClosureSHMap.get(cse.SalesOrganization__c+originValue).Origin__c);
                                        jTriggerToInsert.add(jTrigger2);
            
                                        //for case update
                                        caseRecUpdate.Sent_Case_Closure_Notif_to_Stakeholder__c = true;
                                        caseToUpdateMap.put(caseRecUpdate.Id, caseRecUpdate);
        
                                    }/*else if(sendingMethodClosure =='Send via Salesforce Platform'){
          
        
                                    }*/
                                }
                            }
                        }
                    }
                }
            }

       

            //Insert contact records
            if(!caseContactMap.values().isEmpty()){
                insert caseContactMap.values();
            }

            //Update case Record with contact id
            if(caseContactMap != null){
                for(Case perCase : caseContactMap.keySet()){
                    perCase.ContactId = caseContactMap.get(perCase).Id;
                    perCase.Contact_Created__c = true;
                    caseToUpdateMap.put(perCase.Id, perCase);
                }
            }

            //Insert Journey Triggers
            if(!jTriggerToInsert.isEmpty()){
                insert jTriggerToInsert;
            }

            //send emails
            if(!emailsForSending.isEmpty()){
                TS_EmailUtility.sendEmailWithAttachment(emailsForSending);    
            }

            //update case if sent notification
            if(!caseToUpdateMap.values().isEmpty()){
                update caseToUpdateMap.values();
            }
        }catch (Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();
            System.debug(e.getMessage() + '\n' + e.getStackTraceString()); 
        }
       
        
        CustomLogging.pop();
    }

    /*Method to query country setting*/
    public List<CountrySetting__c> getCountrySettings(Set<String> countries){
        CustomLogging.push('getCountrySettings', 'TS_SendEmail');
        //Get country settings

        List<String> journeyTriggerTypes = new List<String>{TS_Constants.CASE_CREATE, TS_Constants.CASE_CANCELATION, TS_Constants.CASE_CLOSURE_FIXED_BY_PHONE};
        List<CountrySetting__c> countrySetList = [SELECT Name, RecordType.DeveloperName, Country__c, Account__c, Language__c,
                                                    User__c,
                                                    Sending_Method__c,
                                                    Journey_Trigger_Type__c, Journey_Trigger_Subtype__c, Origin__c 
                                                    FROM CountrySetting__c 
                                                    WHERE Country__c IN :countries 
                                                    AND (RecordType.DeveloperName = :TS_Constants.TS_COUNTRYSETTING_RECORDTYPE_COUNTRY_UNKNOWN_CONTACT
                                                    OR Journey_Trigger_Type__c IN :journeyTriggerTypes)
                                                    AND Active__c = true];
        
        CustomLogging.pop(); 
        return countrySetList;
    }

    /*method to send email via apex*/
    public TS_EmailUtility.TS_EmailAttributes sendEmailViaApex(String templateName, String defaultFromAdd, String recId, String salesOrg, String contactId, String contactEmail, String templateType, String language){
        CustomLogging.push('sendEmailViaApex', 'TS_SendEmail');

        TS_EmailUtility.TS_EmailAttributes attributes = new TS_EmailUtility.TS_EmailAttributes();
        attributes.emailAddress = contactEmail;
        attributes.emailfromAddress = defaultFromAdd;
        attributes.emailTemplateName = templateName;
        attributes.emailTemplateType = templateType;
        attributes.hasEmailMessage = false;
        attributes.hasToGenerateLink = false;
        attributes.recordId = recId;
        attributes.selectedCountry = salesOrg;
        attributes.selectedlanguage = language;
        attributes.targetRecipientId = contactId;

        CustomLogging.pop();
        return attributes; 
    }

    /*for Journey Trigger Creation*/
    public Journey_Trigger__c createJT(String jtSubType, String caseId, String contactId, String triggerType, String workOrderId, String woliId, Case caseRec, String origin){
        CustomLogging.push('createJT', 'TS_SendEmail');
        Journey_Trigger__c jt = new Journey_Trigger__c(
            Case__c = caseId,
            Channel__c = TS_Constants.EMAIL,
            Contact__c = contactId,
            Journey_Trigger_SubType__c = jtSubType,
            Journey_Trigger_Type__c = triggerType,
            Origin__c = origin,
            Work_Order__c = workOrderId,
            Work_Order_Line_Item__c = woliId,
            Parsing_Text__c = (caseRec.AccountLocation__r.Name != null ? caseRec.AccountLocation__r.Name : '') + '|' + 
            				  (caseRec.PhysicalAsset__r.ProductDescription__c != null ? caseRec.PhysicalAsset__r.ProductDescription__c : '') + '|' + 
            				  (caseRec.PhysicalAsset__r.SerialNumber__c != null ? caseRec.PhysicalAsset__r.SerialNumber__c : '') + '|' + 
            				  (caseRec.PhysicalAsset__r.Building__c != null ? caseRec.PhysicalAsset__r.Building__c : '') +  '|' + 
            				  (caseRec.PhysicalAsset__r.Floor__c != null ? caseRec.PhysicalAsset__r.Floor__c : '') + '|' + 
            				  (caseRec.PhysicalAsset__r.Area__c != null ? caseRec.PhysicalAsset__r.Area__c : '') + '|' + 
            				  (caseRec.PhysicalAsset__r.CustomerReferenceNumber__c != null ? caseRec.PhysicalAsset__r.CustomerReferenceNumber__c : '')
        );
        CustomLogging.pop(); 
        return jt;
    }
    
  /*
   * Abram Vixen Reyes
   * 06.10.2020
   * DOO-4927 Method to process logic from TS_Send Email From WOLI and added Survey Invitation creation
   * TS_AttachPDF_Batch_Test class will be responsible for SENDFROMWOLI method test coverage
   */
  public static void SENDFROMWOLI(List<WorkOrderLineItem> toProcess) {
    CustomLogging.push('SENDFROMWOLI', 'TS_SendEmail');

    try{
        	List<String> regularList = System.Label.TS_Case_Origin_Regular.split(',');
            //GET COUNTRY SETTINGS TO CHECK FOR SENDING METHOD
            List<CountrySetting__c> csList = [SELECT Id, Country__c, Channel__c, Sending_Method__c, Journey_Trigger_Type__c, Journey_Trigger_SubType__c, Survey__c, Origin__c FROM CountrySetting__c  WHERE RecordType.Name = 'Journey Trigger'
                                                                                AND (Journey_Trigger_Type__c = 'Fulfillment Closure' OR Journey_Trigger_Type__c = 'Received in Mobile Notification')
                                                                                AND (Journey_Trigger_SubType__c LIKE 'Fulfillment Summary Notification for Single Task to%' OR Journey_Trigger_SubType__c LIKE 'Received in Mobile Notification%') 
                                                                                AND Active__c = true];
            
            //CREATE MAP OF MAP OF COUNTRY SETTINGS WITH KEYS OF COUNTRY, JOURNEY TRIGGER TYPE, JOURNEY TRIGGER TYPE
            Map<String, Map<String, Map<String, CountrySetting__c>>> csMainMap = new Map<String, Map<String, Map<String, CountrySetting__c>>>();
            if(!csList.isEmpty()){
                for(CountrySetting__c csvar : csList){
                    if(csMainMap.containsKey(csvar.Country__c+csvar.Origin__c)){
                        if(csMainMap.get(csvar.Country__c+csvar.Origin__c).containsKey(csvar.Journey_Trigger_Type__c)){
                            if(!csMainMap.get(csvar.Country__c+csvar.Origin__c).get(csvar.Journey_Trigger_Type__c).containsKey(csvar.Journey_Trigger_SubType__c)){
                                csMainMap.get(csvar.Country__c+csvar.Origin__c).get(csvar.Journey_Trigger_Type__c).put(csvar.Journey_Trigger_SubType__c, csvar);
                            }
                        } else {
                            csMainMap.get(csvar.Country__c+csvar.Origin__c).put(csvar.Journey_Trigger_Type__c, new Map<String, CountrySetting__c>{csvar.Journey_Trigger_SubType__c => csvar});
                        }
                    } else {
                        csMainMap.put(csvar.Country__c+csvar.Origin__c, new Map<String, Map<String, CountrySetting__c>>{csvar.Journey_Trigger_Type__c => new Map<String, CountrySetting__c>{csvar.Journey_Trigger_SubType__c => csvar}});
                    }
                }
            }
        
            //GET ALL WORK ORDER LINE ITEM INFORMATION - Initial WOLI checker is on WorkOrderLineItemTriggerHandler
            List<WorkOrderLineItem> woliList = [SELECT Id, 
                                                        JDELineItemNumber__c,
                                                        WorkOrderId,
                                                        WorkOrderLineItemType__c,
                                                        ParentWorkOrderLineItemId,
                                                        ReadytosendEmail__c,
                                                        Status,
                                                        Fulfillment_Notification_Sent__c,
                                                        WorkOrderType__c,
                                                        QuotingSignature__c,
                                                        ReturnNeeded__c,
                                                        Case__c,
                                                		Case__r.Origin,
                                                        Case__r.CaseNumber,
                                                        Case__r.AccountLocation__c,
                                                        Case__r.Default_From_Address__c,
                                                        Case__r.NoCaseClosureNotification__c,
                                                		Case__r.NoATANotification__c,
                                                        Case__r.NoStakeholderNotification__c,
                                                        Case__r.SalesOrganization__c,
                                                        Case__r.ContactId,
                                                        Case__r.Contact.Name,
                                                        Case__r.Contact.CaseClosureNotification__c,
                                                		Case__r.Contact.ATANotification__c,
                                                        Case__r.Contact.Communication_Preference__c,
                                                        Case__r.Contact.Email,
                                                        Case__r.Contact.Preferred_Language__c,
                                                        Case__r.AccountLocation__r.Additional_Case_Contact__c,
                                                        Case__r.AccountLocation__r.Second_Additional_Case_Contact__c,
                                                        Case__r.AccountLocation__r.StakeholderNotification__c,
                                                        Case__r.AccountLocation__r.Additional_Case_Contact__r.CaseClosureNotification__c,
                                                		Case__r.AccountLocation__r.Additional_Case_Contact__r.ATANotification__c,
                                                        Case__r.AccountLocation__r.Additional_Case_Contact__r.Communication_Preference__c,
                                                        Case__r.AccountLocation__r.Additional_Case_Contact__r.Email,
                                                        Case__r.AccountLocation__r.Additional_Case_Contact__r.Preferred_Language__c,
                                                        Case__r.AccountLocation__r.Second_Additional_Case_Contact__r.CaseClosureNotification__c,
                                                		Case__r.AccountLocation__r.Second_Additional_Case_Contact__r.ATANotification__c,
                                                        Case__r.AccountLocation__r.Second_Additional_Case_Contact__r.Communication_Preference__c,
                                                        Case__r.AccountLocation__r.Second_Additional_Case_Contact__r.Email,
                                                        Case__r.AccountLocation__r.Second_Additional_Case_Contact__r.Preferred_Language__c
                                                        FROM WorkOrderlineItem WHERE Id IN: toProcess];
        
            if(!woliList.isEmpty()){
        
                List<Journey_Trigger__c> jtToInsert = new List<Journey_Trigger__c>();
                List<TS_EmailUtility.TS_EmailAttributes> emailsForSending = new List<TS_EmailUtility.TS_EmailAttributes>();
                List<WorkOrderLineItem> woliToUpdate = new List<WorkOrderLineItem>();
                List<SurveyInvitation> surveyInvitationToInsert = new List<SurveyInvitation>();
                Map<String, SurveySubject> surveySubjectToInsert = new Map<String, SurveySubject>();

                List<APTS_SalesOrg_Settings__mdt> salesOrgSettings = [SELECT Sales_Organization__c, Customer_Community_Name__c FROM APTS_SalesOrg_Settings__mdt];
                Set<String> communityNames = new Set<String>();
                Map<String, Id> salesOrgSettingsMap = new Map<String, Id>();
                // not filtering since number will always be very low and can save filter.
                List<Network> communities = [SELECT Id, Name FROM Network LIMIT 100];
                for(APTS_SalesOrg_Settings__mdt s : salesOrgSettings) {
                    for(Network n : communities) {
                        if (s.Customer_Community_Name__c == n.Name) {
                            salesOrgSettingsMap.put(s.Sales_Organization__c, n.Id);
                            break;
                        }
                    }
                }
        
                for(WorkOrderLineItem woliVar : woliList){
        
                    //CHECK IF SEND VIA EMAIL OR APEX FOR CUSTOMER OR STAKEHOLDER
                    CountrySetting__c customerJourneyCountrySettings;
                    CountrySetting__c stakeholderJourneyCountrySettings;
                    CountrySetting__c customerMobileNotificationSettings;
                    CountrySetting__c stakeholderMobileNotificationSettings;
                    //DOO 5243 - Pandian Sundaramoorthy - March 22, 2021
                    String originValue;
                    if(woliVar.Case__r.Origin != null){
                        originValue = regularList.contains(woliVar.Case__r.Origin) ? TS_Constants.REGULAR : woliVar.Case__r.Origin;
                        if(originValue.equalsIgnoreCase('IOT')){
                            originValue = 'IoT';
                        }
                    }
                    if(woliVar.Case__r.Origin != null && csMainMap.containsKey(woliVar.Case__r.SalesOrganization__c+originValue)){
                        if(csMainMap.get(woliVar.Case__r.SalesOrganization__c+originValue).containsKey('Fulfillment Closure')){
                            if(csMainMap.get(woliVar.Case__r.SalesOrganization__c+originValue).get('Fulfillment Closure').containsKey('Fulfillment Summary Notification for Single Task to Customer')){
                                customerJourneyCountrySettings = csMainMap.get(woliVar.Case__r.SalesOrganization__c+originValue).get('Fulfillment Closure').get('Fulfillment Summary Notification for Single Task to Customer');
                            }
        
                            if(csMainMap.get(woliVar.Case__r.SalesOrganization__c+originValue).get('Fulfillment Closure').containsKey('Fulfillment Summary Notification for Single Task to Stakeholder')){
                                stakeholderJourneyCountrySettings = csMainMap.get(woliVar.Case__r.SalesOrganization__c+originValue).get('Fulfillment Closure').get('Fulfillment Summary Notification for Single Task to Stakeholder');
                            }
                        }
                        if(csMainMap.get(woliVar.Case__r.SalesOrganization__c+originValue).containsKey('Received in Mobile Notification')){
                            if(csMainMap.get(woliVar.Case__r.SalesOrganization__c+originValue).get('Received in Mobile Notification').containsKey('Received in Mobile Notification Customer')){
                                customerMobileNotificationSettings = csMainMap.get(woliVar.Case__r.SalesOrganization__c+originValue).get('Received in Mobile Notification').get('Received in Mobile Notification Customer');
                            }
                            
                            if(csMainMap.get(woliVar.Case__r.SalesOrganization__c+originValue).get('Received in Mobile Notification').containsKey('Received in Mobile Notification Stakeholder')){
                                stakeholderMobileNotificationSettings = csMainMap.get(woliVar.Case__r.SalesOrganization__c+originValue).get('Received in Mobile Notification').get('Received in Mobile Notification Stakeholder');
                            }
                        }
                    }
                    
                    //CHECK REQUIRED TEMPLATE AND SENDING METHOD & DETERMINE IF SURVEY INVITATION IS NEEDED
                    String emailTemplateApex;
                    if(woliVar.QuotingSignature__c != null && woliVar.ReturnNeeded__c == true){ //ESTIMATE, SUMMARY AND RETURN NEEDED
                        emailTemplateApex = 'TS_FS_Est_Work_Sum_Return';
                    } else if(woliVar.QuotingSignature__c != null && woliVar.ReturnNeeded__c == false){ //SUMMARY AND RETURN NEEDED
                        emailTemplateApex = 'TS_FS_Work_Sum_Return';
                    } else if(woliVar.QuotingSignature__c == null && woliVar.ReturnNeeded__c == true){ //ESTIMATE & SUMMARY ONLY
                        emailTemplateApex = 'TS_FS_Cost_Est_Work_Sum';
                    } else if(woliVar.QuotingSignature__c == null && woliVar.ReturnNeeded__c == false){ //SUMMARY ONLY
                        emailTemplateApex = 'TS_FS_Work_Summary_only';
                    }
        			
                    //SEND EMAIL TO PRIMARY CONTACT(For Fulfillment Closure)
                    if( woliVar.Case__r.NoCaseClosureNotification__c == false
                        && woliVar.Case__r.Contact.CaseClosureNotification__c == true
                        && woliVar.Case__r.Contact.Communication_Preference__c == 'Email'
                        && woliVar.Case__r.Contact.Email != null && woliVar.Status == 'Completed'
                        ){
        
                            String sendingMethodCustomer;
                            if(customerJourneyCountrySettings != null){
                                sendingMethodCustomer = customerJourneyCountrySettings.Sending_Method__c;
                            }

                            if(sendingMethodCustomer == 'Send via MC'){
                                
                                //CREATE SURVEY INVITATION
                                if(woliVar.ReturnNeeded__c == false && customerJourneyCountrySettings.Survey__c != null){

                                    String externlRef = String.valueOf(woliVar.Id) + String.valueOf(woliVar.Case__r.ContactId) + String.valueOf(customerJourneyCountrySettings.Journey_Trigger_SubType__c);
                                    String invitationName = 'Case#: ' + String.valueOf(woliVar.Case__r.CaseNumber) + ' Task#: ' + String.valueOf(woliVar.JDELineItemNumber__c) + ' ' + String.valueOf(woliVar.Case__r.Contact.Name);
                                    String communityIdSalesOrgSettings = salesOrgSettingsMap.containsKey(woliVar.Case__r.SalesOrganization__c) ? salesOrgSettingsMap.get(woliVar.Case__r.SalesOrganization__c) : null;
                                    surveyInvitationToInsert.add(new SurveyInvitation(ParticipantId = woliVar.Case__r.ContactId,
                                                                                      SurveyId = customerJourneyCountrySettings.Survey__c,
                                                                                      Name = invitationName,
                                                                                      External_Reference__c = externlRef,
                                                                                      OptionsAllowGuestUserResponse = true,
                                                                                      CommunityId = communityIdSalesOrgSettings));

                                    surveySubjectToInsert.put(externlRef, new SurveySubject(Name = invitationName,SubjectId = woliVar.Case__r.Id));
                                }
        
                                //CREATE JOURNEY TRIGGER
                                jtToInsert.add(new Journey_Trigger__c(Case__c = woliVar.Case__c,
                                                                        Channel__c = 'Email',
                                                                        Contact__c = woliVar.Case__r.ContactId,
                                                                        Journey_Trigger_SubType__c = customerJourneyCountrySettings.Journey_Trigger_SubType__c,
                                                                        Journey_Trigger_Type__c = customerJourneyCountrySettings.Journey_Trigger_Type__c,
                                                                      	Origin__c = customerJourneyCountrySettings.Origin__c,
                                                                        Work_Order_Line_Item__c = woliVar.Id,
                                                                        Work_Order__c = woliVar.WorkOrderId));
                                                                                                
                                                                        
                            } else if(sendingMethodCustomer == 'Send via Salesforce Platform'){
                                
                                TS_EmailUtility.TS_EmailAttributes attributes = new TS_EmailUtility.TS_EmailAttributes();
                                attributes.emailAddress = woliVar.Case__r.Contact.Email;
                                attributes.emailfromAddress = woliVar.Case__r.Default_From_Address__c;
                                attributes.emailTemplateName = emailTemplateApex;
                                attributes.emailTemplateType = 'Fulfillment Summary';
                                attributes.hasEmailMessage = true;
                                attributes.hasToGenerateLink = false;
                                attributes.recordId = woliVar.Id;
                                attributes.selectedCountry = woliVar.Case__r.SalesOrganization__c;
                                attributes.selectedlanguage = woliVar.Case__r.Contact.Preferred_Language__c;
                                attributes.targetRecipientId = woliVar.Case__r.ContactId;
                                emailsForSending.add(attributes);
                            }
                            
                        	//UPDATE WOLI FULFILLMENT NOTIFICATION SENT
                    		woliVar.Fulfillment_Notification_Sent__c = true;
                    		woliToUpdate.add(woliVar);    
                    }
                    //DOO 5249 - Pandian Sundaramoorthy - March 25, 2021
                    //SEND EMAIL TO PRIMARY CONTACT(For Received in Mobile Notification)
                    else if( woliVar.Case__r.NoATANotification__c == false
                        	 && woliVar.Case__r.Contact.ATANotification__c == true
                        	 && woliVar.Case__r.Contact.Communication_Preference__c == 'Email' 
                             && woliVar.Case__r.Contact.Email != null 
                             && woliVar.Status == 'Received'
                             ){
        
                            String sendingMethodCustomer;
                            if(customerMobileNotificationSettings != null){
                                sendingMethodCustomer = customerMobileNotificationSettings.Sending_Method__c;
                            }

                            if(sendingMethodCustomer == 'Send via MC'){
                                
                                //CREATE SURVEY INVITATION
                                if(woliVar.ReturnNeeded__c == false && customerMobileNotificationSettings.Survey__c != null){

                                    String externlRef = String.valueOf(woliVar.Id) + String.valueOf(woliVar.Case__r.ContactId) + String.valueOf(customerMobileNotificationSettings.Journey_Trigger_SubType__c);
                                    String invitationName = 'Case#: ' + String.valueOf(woliVar.Case__r.CaseNumber) + ' Task#: ' + String.valueOf(woliVar.JDELineItemNumber__c) + ' ' + String.valueOf(woliVar.Case__r.Contact.Name);
                                    String communityIdSalesOrgSettings = salesOrgSettingsMap.containsKey(woliVar.Case__r.SalesOrganization__c) ? salesOrgSettingsMap.get(woliVar.Case__r.SalesOrganization__c) : null;
                                    surveyInvitationToInsert.add(new SurveyInvitation(ParticipantId = woliVar.Case__r.ContactId,
                                                                                      SurveyId = customerMobileNotificationSettings.Survey__c,
                                                                                      Name = invitationName,
                                                                                      External_Reference__c = externlRef,
                                                                                      OptionsAllowGuestUserResponse = true,
                                                                                      CommunityId = communityIdSalesOrgSettings));

                                    surveySubjectToInsert.put(externlRef, new SurveySubject(Name = invitationName,SubjectId = woliVar.Case__r.Id));
                                }
        
                                //CREATE JOURNEY TRIGGER
                                jtToInsert.add(new Journey_Trigger__c(Case__c = woliVar.Case__c,
                                                                        Channel__c = 'Email',
                                                                        Contact__c = woliVar.Case__r.ContactId,
                                                                        Journey_Trigger_SubType__c = customerMobileNotificationSettings.Journey_Trigger_SubType__c,
                                                                        Journey_Trigger_Type__c = customerMobileNotificationSettings.Journey_Trigger_Type__c,
                                                                      	Origin__c = customerMobileNotificationSettings.Origin__c,
                                                                        Work_Order_Line_Item__c = woliVar.Id,
                                                                        Work_Order__c = woliVar.WorkOrderId));
                                                                                                
                                                                        
                            } /*else if(sendingMethodCustomer == 'Send via Salesforce Platform'){
                               
                            } */
                            
                        	//UPDATE WOLI Received in Mobile NOTIFICATION SENT
                        	woliVar.Sent_to_Mobile_Notif_Sent__c = true;
                    		woliToUpdate.add(woliVar);    
                    }
        
                    //CHECK IF SEND EMAIL TO STAKEHOLDERS
                    if((woliVar.Case__r.AccountLocation__r.Additional_Case_Contact__c != null
                        || woliVar.Case__r.AccountLocation__r.Second_Additional_Case_Contact__c != null) 
                        && woliVar.Case__r.AccountLocation__r.StakeholderNotification__c == true
                        && woliVar.Case__r.NoStakeholderNotification__c == false){
        
                            //SEND EMAIL TO ADDITIONAL STAKEHOLDER 1(For Fulfillment Closure)                        
                            if( woliVar.Case__r.AccountLocation__r.Additional_Case_Contact__c != null
                                && woliVar.Case__r.AccountLocation__r.Additional_Case_Contact__r.CaseClosureNotification__c == true
                                && woliVar.Case__r.AccountLocation__r.Additional_Case_Contact__r.Communication_Preference__c == 'Email'
                                && woliVar.Case__r.AccountLocation__r.Additional_Case_Contact__r.Email != null
                                && woliVar.Status == 'Completed'
                                ){
        
                                    String sendingMethodStakeholder1;
                                    if(stakeholderJourneyCountrySettings != null){
                                        sendingMethodStakeholder1 = stakeholderJourneyCountrySettings.Sending_Method__c;
                                    }
                                
                                    if(sendingMethodStakeholder1 == 'Send via MC'){
                                        jtToInsert.add(new Journey_Trigger__c(Case__c = woliVar.Case__c,
                                                                        Channel__c = 'Email',
                                                                        Contact__c = woliVar.Case__r.AccountLocation__r.Additional_Case_Contact__c,
                                                                        Journey_Trigger_SubType__c = stakeholderJourneyCountrySettings.Journey_Trigger_SubType__c,
                                                                        Journey_Trigger_Type__c = stakeholderJourneyCountrySettings.Journey_Trigger_Type__c,
                                                                        Origin__c = stakeholderJourneyCountrySettings.Origin__c,
                                                                        Work_Order_Line_Item__c = woliVar.Id,
                                                                        Work_Order__c = woliVar.WorkOrderId));
                                        
                                    } else if(sendingMethodStakeholder1 == 'Send via Salesforce Platform'){
                                        
                                        TS_EmailUtility.TS_EmailAttributes attributes = new TS_EmailUtility.TS_EmailAttributes();
                                        attributes.emailAddress = woliVar.Case__r.AccountLocation__r.Additional_Case_Contact__r.Email;
                                        attributes.emailfromAddress = woliVar.Case__r.Default_From_Address__c;
                                        attributes.emailTemplateName = emailTemplateApex;
                                        attributes.emailTemplateType = 'Fulfillment Summary';
                                        attributes.hasEmailMessage = true;
                                        attributes.hasToGenerateLink = false;
                                        attributes.recordId = woliVar.Id;
                                        attributes.selectedCountry = woliVar.Case__r.SalesOrganization__c;
                                        attributes.selectedlanguage = woliVar.Case__r.AccountLocation__r.Additional_Case_Contact__r.Preferred_Language__c;
                                        attributes.targetRecipientId = woliVar.Case__r.AccountLocation__r.Additional_Case_Contact__c;
                                        emailsForSending.add(attributes);
                                    }
                            }
                            //DOO 5249 - Pandian Sundaramoorthy - March 25, 2021
                            //SEND EMAIL TO ADDITIONAL STAKEHOLDER 1(For Received in Mobile Notification)                        
                            else if( woliVar.Case__r.AccountLocation__r.Additional_Case_Contact__c != null
                                     && woliVar.Case__r.AccountLocation__r.Additional_Case_Contact__r.ATANotification__c == true
                                	 && woliVar.Case__r.AccountLocation__r.Additional_Case_Contact__r.Communication_Preference__c == 'Email'
                                	 && woliVar.Case__r.AccountLocation__r.Additional_Case_Contact__r.Email != null
                                	 && woliVar.Status == 'Received'
                                	 ){
        
                                    String sendingMethodStakeholder1;
                                    if(stakeholderMobileNotificationSettings != null){
                                        sendingMethodStakeholder1 = stakeholderMobileNotificationSettings.Sending_Method__c;
                                    }
                                
                                    if(sendingMethodStakeholder1 == 'Send via MC'){
                                        jtToInsert.add(new Journey_Trigger__c(Case__c = woliVar.Case__c,
                                                                        Channel__c = 'Email',
                                                                        Contact__c = woliVar.Case__r.AccountLocation__r.Additional_Case_Contact__c,
                                                                        Journey_Trigger_SubType__c = stakeholderMobileNotificationSettings.Journey_Trigger_SubType__c,
                                                                        Journey_Trigger_Type__c = stakeholderMobileNotificationSettings.Journey_Trigger_Type__c,
                                                                        Origin__c = stakeholderMobileNotificationSettings.Origin__c,
                                                                        Work_Order_Line_Item__c = woliVar.Id,
                                                                        Work_Order__c = woliVar.WorkOrderId));
                                        
                                    } /*else if(sendingMethodStakeholder1 == 'Send via Salesforce Platform'){
                                      
                                    }*/
                            }
        
                            //SEND EMAIL TO ADDITIONAL STAKEHOLDER 2(For Fulfillment Closure) 
                            if( woliVar.Case__r.AccountLocation__r.Second_Additional_Case_Contact__c != null
                                && woliVar.Case__r.AccountLocation__r.Second_Additional_Case_Contact__r.CaseClosureNotification__c == true
                                && woliVar.Case__r.AccountLocation__r.Second_Additional_Case_Contact__r.Communication_Preference__c == 'Email'
                                && woliVar.Case__r.AccountLocation__r.Second_Additional_Case_Contact__r.Email != null
                                && woliVar.Status == 'Completed'
                                ){
        
                                    String sendingMethodStakeholder2;
                                    if(stakeholderJourneyCountrySettings != null){
                                        sendingMethodStakeholder2 = stakeholderJourneyCountrySettings.Sending_Method__c;
                                    }
                                
                                    if(sendingMethodStakeholder2 == 'Send via MC'){
                                        jtToInsert.add(new Journey_Trigger__c(Case__c = woliVar.Case__c,
                                                                        Channel__c = 'Email',
                                                                        Contact__c = woliVar.Case__r.AccountLocation__r.Second_Additional_Case_Contact__c,
                                                                        Journey_Trigger_SubType__c = stakeholderJourneyCountrySettings.Journey_Trigger_SubType__c,
                                                                        Journey_Trigger_Type__c = stakeholderJourneyCountrySettings.Journey_Trigger_Type__c,
                                                                        Origin__c = stakeholderJourneyCountrySettings.Origin__c,
                                                                        Work_Order_Line_Item__c = woliVar.Id,
                                                                        Work_Order__c = woliVar.WorkOrderId));
                                        
                                    } else if(sendingMethodStakeholder2 == 'Send via Salesforce Platform'){
                                        
                                        TS_EmailUtility.TS_EmailAttributes attributes = new TS_EmailUtility.TS_EmailAttributes();
                                        attributes.emailAddress = woliVar.Case__r.AccountLocation__r.Second_Additional_Case_Contact__r.Email;
                                        attributes.emailfromAddress = woliVar.Case__r.Default_From_Address__c;
                                        attributes.emailTemplateName = emailTemplateApex;
                                        attributes.emailTemplateType = 'Fulfillment Summary';
                                        attributes.hasEmailMessage = true;
                                        attributes.hasToGenerateLink = false;
                                        attributes.recordId = woliVar.Id;
                                        attributes.selectedCountry = woliVar.Case__r.SalesOrganization__c;
                                        attributes.selectedlanguage = woliVar.Case__r.AccountLocation__r.Second_Additional_Case_Contact__r.Preferred_Language__c;
                                        attributes.targetRecipientId = woliVar.Case__r.AccountLocation__r.Second_Additional_Case_Contact__c;
                                        emailsForSending.add(attributes);
                                    }
                            }
                            //DOO 5249 - Pandian Sundaramoorthy - March 25, 2021
                            //SEND EMAIL TO ADDITIONAL STAKEHOLDER 2(For Received in Mobile Notification) 
                            else if( woliVar.Case__r.AccountLocation__r.Second_Additional_Case_Contact__c != null
                                	 && woliVar.Case__r.AccountLocation__r.Second_Additional_Case_Contact__r.ATANotification__c == true 
                                     && woliVar.Case__r.AccountLocation__r.Second_Additional_Case_Contact__r.Communication_Preference__c == 'Email'
                                	 && woliVar.Case__r.AccountLocation__r.Second_Additional_Case_Contact__r.Email != null
                                	 && woliVar.Status == 'Received'
                                	 ){
        
                                    String sendingMethodStakeholder2;
                                    if(stakeholderMobileNotificationSettings != null){
                                        sendingMethodStakeholder2 = stakeholderMobileNotificationSettings.Sending_Method__c;
                                    }
                                
                                    if(sendingMethodStakeholder2 == 'Send via MC'){
                                        jtToInsert.add(new Journey_Trigger__c(Case__c = woliVar.Case__c,
                                                                        Channel__c = 'Email',
                                                                        Contact__c = woliVar.Case__r.AccountLocation__r.Second_Additional_Case_Contact__c,
                                                                        Journey_Trigger_SubType__c = stakeholderMobileNotificationSettings.Journey_Trigger_SubType__c,
                                                                        Journey_Trigger_Type__c = stakeholderMobileNotificationSettings.Journey_Trigger_Type__c,
                                                                        Origin__c = stakeholderMobileNotificationSettings.Origin__c,
                                                                        Work_Order_Line_Item__c = woliVar.Id,
                                                                        Work_Order__c = woliVar.WorkOrderId));
                                        
                                    } /*else if(sendingMethodStakeholder2 == 'Send via Salesforce Platform'){
                                      
                                    }*/
                            }
        
                    }
        
                 }
            
                //INSERT JOURNEY TRIGGERS AND SURVEY INVITATION
                if(!jtToInsert.isEmpty()){
                    
                    Map<String, SurveyInvitation> surveyInviteMap = new Map<String, SurveyInvitation>();
                    if(!surveyInvitationToInsert.isEmpty()){
                        Database.SaveResult[] srList = Database.insert(surveyInvitationToInsert, false);
                        for(Database.SaveResult sr : srList) {
                            if (sr.isSuccess()) {
                                // Operation was successful, so get the ID of the record that was processed
                                System.debug('Successfully inserted account. Id: ' + sr.getId());
                            } else {
                                // Operation failed, so get all errors                
                                for(Database.Error err : sr.getErrors()) {
                                    System.debug('The following error has occurred.');                    
                                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                                    System.debug('Fields that affected this error: ' + err.getFields());
                                }
                            }
                        }
                            
                        for(SurveyInvitation surInv_var : surveyInvitationToInsert) {
                            surveyInviteMap.put(surInv_var.External_Reference__c, surInv_var);
                            surveySubjectToInsert.get(surInv_var.External_Reference__c).ParentId = surInv_var.Id;
                        }
                    }

                    for(Journey_Trigger__c jt_var : jtToInsert){
                        String keyStr = String.valueOf(jt_var.Work_Order_Line_Item__c) + String.valueOf(jt_var.Contact__c) + String.valueOf(jt_var.Journey_Trigger_SubType__c);
                        jt_var.Survey_Invitation__c = surveyInviteMap.containsKey(keyStr) ? surveyInviteMap.get(keyStr).Id : null;
                    }
                    Database.insert(jtToInsert, false);

                    List<SurveySubject> ssInsert = new List<SurveySubject>();
                    for (SurveySubject ss : surveySubjectToInsert.values()) {
                        if (ss.ParentId != null) {
                            ssInsert.add(ss);
                        }
                    }
                    Database.insert(ssInsert, false);
                }
                
                //SEND EMAIL VIA APEX EMAIL UTILITY
                if(!emailsForSending.isEmpty()){
                    TS_EmailUtility.sendEmailWithAttachment(emailsForSending);    
                }
            
                //UPDATE WORK ORDER LINE ITEM - NOTIFICATION SENT
                if(!woliToUpdate.isEmpty()){
                    Database.update(woliToUpdate, false);
                }
                
            }
        } catch (Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        
        CustomLogging.pop();
    }
}