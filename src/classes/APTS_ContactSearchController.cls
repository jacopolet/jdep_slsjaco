/*************************************************************
@Name: APTS_ContactSearchController
@Author: Aarthi Pitchai
@CreateDate: 07-11-2019
@Description: Controller to search and select primary contact from Sold To Account and its hierarchy
@UsedBy: search contact button on Order header layout
******************************************************************/
//v100 07-11-2019 Aarthi Pitchai : Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes
//v101 25-11-2019 Renuka: QTCFLEX1-1720- Changed checkbox to Radio button for selecting Contacts
public without sharing class APTS_ContactSearchController {

    private Id accountId;
    private Id orderId;
    private Id orderType;
    private Account initialAccount;
    private Map<Id, Account> idToAccountMap;
    
    private Set<Id> accountSet ;  
    
    private Integer iInitialCountToDisplay;
    private Integer iCountToDisplay;   

    
   
    public Map<String, Contact> contactNameSetCheckDisplayMap;
    public Map<String, Contact> contactNameSetCheckDisplayMapAll;

    public List<ContactWrapper> contactWrapperList {get; set;}    
    public String sContactName {get; set;}
    public String sAllContactsByName {get; set;}
    public Boolean bShowContacts  {get; set;}
    public Boolean bDisableContactName {get; set;}
    public Boolean bUpdateOrder {get; set;}
    public Boolean bShowNoContacts {get; set;}
    public Map<String, String> contactDetails;
    public Integer displayMoreContactsByFive;
    public Integer displayMoreContactsByFiveTemp;
    public Set<String> ContactNameSetCheck;
    
    public Set<String> ContactNameSetCheckDisplay;
    public List<Contact> addContactEmailOnSearchByName;
    public Integer iRemainContact;
    public Boolean bRemainContact;
    public Integer iMoreContacts;
    public Integer iCount;
    public Integer iTotalRecords;
    public Integer iInitialContacts;
    public Integer iLoadLess;
    public Boolean bErrorOccurred {get; set;}
    public String sAllContacts {get; set;}
    public Boolean bDisableMore {get; set;}
    public Boolean bDisableLess {get; set;}
    public Boolean bShowCreate {get; set;}    
    public List<Contact> filterContactByName {get; set;}
    public Id primarycontact {get; set;}
    public String SelectedId{get;set;}

    public APTS_ContactSearchController() {

        accountId = ApexPages.currentPage().getParameters().get('AccountId');
        orderId = ApexPages.currentPage().getParameters().get('Id');
        bShowContacts = true;
        sContactName = null;
        bDisableMore = true;
        bDisableLess = true;
        bShowCreate = true;       
        bShowContacts = true;        
        bDisableContactName = true;
        bUpdateOrder = true;
        bShowNoContacts = true;
        iRemainContact = 0;
        iMoreContacts = 5;
        iCount = 0;
        iTotalRecords = 0;
        iInitialContacts = 7;
        displayMoreContactsByFive = 7;
        displayMoreContactsByFiveTemp = 0;
        bRemainContact = false;
        iLoadLess = 0;     

        idToAccountMap = new Map<Id, Account>();
        accountSet = new Set<Id> ();        
        doSOQLS();   
        primaryContact = setPrimaryContact();        
        loadContacts();      
    }
    public Map<Id, Contact> getContactDetails(Set<Id> accountSet)
    {
        Map<Id, Contact> idToContactMap = new Map<Id, Contact>([
                    SELECT Id, Name, Function__c, Main_Commercial_Person__c, Main_Service_Person__c FROM Contact WHERE Id IN (SELECT ContactId FROM AccountContactRelation WHERE AccountId IN: accountSet) and isActive__c = true]);
        return idToContactMap;
    }
    public id setPrimaryContact()
    {
        ID contactID = null;
        Apttus_Config2__Order__c oOrder = [Select id, APTS_Order_Type__c, Apttus_Config2__PrimaryContactId__c from Apttus_Config2__Order__c where id = :orderId];
        if(oOrder != null)
        {
            string orderType = (oOrder.APTS_Order_Type__c != 'Admin Order')? ((oOrder.APTS_Order_Type__c == 'Machine Order') ? APTS_OrderConstants.MACHINE_ORDER : APTS_OrderConstants.STANDARD) : null;
           if(orderType != null)
           {
               if(oOrder.Apttus_Config2__PrimaryContactId__c == null)
               {
               Map<Id, Contact> idToContactMap = getContactDetails(accountSet);
               contactID = APTS_OrderUtils.getPrimaryContactId(idToContactMap, orderType);
               }
               else
                   contactID = oOrder.Apttus_Config2__PrimaryContactId__c;
           }
        }
        return contactID;
    }

    public void doSOQLS() {

        Map<Id, Account> initialAccountMap = new  Map<Id, Account>([
                    SELECT Id,
                    APTS_Ultimate_Parent_Id__c,
                    APTS_Account_Level__c,
                    SAP_Customer_ID__c,
                    Apttus_Config2__BillingPreferenceId__c,
                    Apttus_Config2__PaymentTermId__c,
                    Language__c,
                    Sales_Organization__c,
                    Division__c,
                    Distribution_Channel__c,
                    Bill_To_Payer_Account__c,
                    Related_Payer_Account__c,
                    APTS_Price_List__c,
                    Partner__c,
                    Billing_header_text__c,
                    ParentId,
                    Parent.Parent.Id
                    FROM Account
                    WHERE Id = :accountId LIMIT 1]);

        initialAccount = initialAccountMap.get(accountId);

        if (initialAccount != null && initialAccount.Id != initialAccount.APTS_Ultimate_Parent_Id__c) {

            accountSet.add(initialAccount.Id);
            if (initialAccount.ParentId != null) {accountSet.add(initialAccount.ParentId);}
            if (initialAccount.Parent.Parent.Id != null) {accountSet.add(initialAccount.Parent.Parent.Id);}

        } else {

            accountSet.add(initialAccount.Id);
        }
        system.debug(+accountSet);
    }

    public void loadContacts() {
      try {
            if (bShowContacts) {

                contactDetails = new Map<String, String>();
                contactWrapperList = new List<ContactWrapper>();
                contactNameSetCheck = new Set<String>();
                contactNameSetCheckDisplay = new Set<String>();
                contactNameSetCheckDisplayMap = new Map<String, Contact>();
                contactNameSetCheckDisplayMapAll = new Map<String, Contact>();
                bDisableMore = false;
                bDisableContactName = false;
                bUpdateOrder = false;
                bShowCreate = true;
              List<Contact> contactList = [SELECT Id,Name, Email, AccountId, Account.Name, Function__c, Main_Commercial_Person__c
                                                       From Contact
                                                       WHERE AccountId IN :accountSet and IsActive__c = true];


                for (Contact oContact : contactList) {
                    contactDetails.put(oContact.Id, oContact.Name);
                    contactNameSetCheck.add(oContact.Name.replaceAll( '\\s+', ''));
                }
                filterContactByName = contactList;
                iTotalRecords = filterContactByName.size();
                iRemainContact = iTotalRecords-1;
                for (Integer i = 0; i < filterContactByName.size(); i++) {
                    contactNameSetCheckDisplayMapAll.put(filterContactByName[i].Name.replaceAll( '\\s+', ''), filterContactByName[i]);
                }
                if (filterContactByName.size() < displayMoreContactsByFive) {
                    for (Integer i = 0; i < filterContactByName.size(); i++) {
                        Boolean bPrimary = (filterContactByName[iRemainContact].Id == primaryContact);
                        ContactWrapper oContactwrapper = new ContactWrapper(false, filterContactByName[iRemainContact], bPrimary);
                        contactWrapperList.add(oContactwrapper);
                        contactNameSetCheckDisplay.add(filterContactByName[i].Name.replaceAll( '\\s+', ''));
                        contactNameSetCheckDisplayMap.put(filterContactByName[i].Name.replaceAll( '\\s+', ''), filterContactByName[i]);
                        iRemainContact = iRemainContact - 1;
                        bDisableMore = true;
                    }
                } else {
                    for (Integer i = 0; i < displayMoreContactsByFive; i++) {
                        Boolean bPrimary = (filterContactByName[iRemainContact].Id == primaryContact);
                        ContactWrapper oContactwrapper = new ContactWrapper(false, filterContactByName[iRemainContact], bPrimary);
                        contactWrapperList.add(oContactwrapper);
                        contactNameSetCheckDisplay.add(filterContactByName[i].Name.replaceAll( '\\s+', ''));
                        contactNameSetCheckDisplayMap.put(filterContactByName[i].Name.replaceAll( '\\s+', ''), filterContactByName[i]);
                        iRemainContact = iRemainContact - 1;
                    }
                } 
            }

            if (filterContactByName.isEmpty()) {
                bDisableMore = true;
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, ' There are no Contacts related to in this account.'));
            }            
            bShowContacts = true;
            
        } catch (Exception ex) {raiseError(ex, ' Looks like something went wrong' + ex.getStackTraceString());}
        
    }
    public void addContactsOnSearchByName() {
        try {
            loadContacts();
            Integer iIndexRemove = 0;
            Integer iIndexSize = 0;
            String sContactNamewoSpacess = sContactName.replaceAll( '\\s+', '');
            addContactEmailOnSearchByName = new List<Contact>();            

            if (!String.isBlank(sContactNamewoSpacess) && (contactNameSetCheckDisplayMap.containsKey(sContactNamewoSpacess)) && (!sContactNamewoSpacess.equalsIgnoreCase('NoResultsFound'))) {

                Contact objContact = new Contact();
                objContact = null;
                for(string contactName :contactNameSetCheckDisplayMapAll.KeySet())
                {
                    if(contactName.contains(sContactNamewoSpacess))
                    {
                        objContact = contactNameSetCheckDisplayMapAll.get(contactName);
                        break;
                    }
                }
                
                if(objContact != null)
                {
                addContactEmailOnSearchByName.add(objContact);
                Boolean bPrimary = (addContactEmailOnSearchByName[0].Id == primaryContact);
                ContactWrapper contactwrapper = new ContactWrapper(false, addContactEmailOnSearchByName[0], bPrimary);
                contactWrapperList.clear();
                contactWrapperList.add(contactwrapper);
                contactNameSetCheckDisplay.add(sContactNamewoSpacess);
                contactNameSetCheckDisplayMap.put(sContactNamewoSpacess, objContact);
                for (Contact oContactRemove : filterContactByName) {
                    string contName = (oContactRemove.Name).replaceAll( '\\s+', '');
                    if (contName.contains(sContactNamewoSpacess)) {
                        iIndexRemove = iIndexSize;
                    }
                    iIndexSize++;
                }
                filterContactByName.remove(iIndexRemove);
                iTotalRecords = filterContactByName.size() + 1;
                iRemainContact = iTotalRecords - contactWrapperList.size();
                bDisableMore = (iRemainContact == 0) ? true : false;
                }
                else
                    errorMessageForNoContacts(sContactName);
            } else if (sContactNamewoSpacess.equalsIgnoreCase('NoResultsFound')) {
                errorMessageForNoContacts(sContactName);
            } else {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, ' The contact you have selected is already added to the order'));
            }
        } catch (Exception ex) {raiseError(ex, 'Looks like something went wrong' + ex.getStackTraceString());}
        
    }
    //V100++ ++<<
    public void updateOrder() {

       try
       {
           Apttus_Config2__Order__c oOrderToUpdate = new Apttus_Config2__Order__c();
           oOrderToUpdate.Id = orderId;
           Contact oSelectedContact;

            for (ContactWrapper oContactWrapper : contactWrapperList) {
                //v101++<< - Starts
                if(SelectedId!=null && oContactWrapper.oContact.Id == SelectedId){
                    oSelectedContact = oContactWrapper.oContact;
                }
                /*if (oContactWrapper.selected) {
                    oSelectedContact = oContactWrapper.oContact;
                }*/
                //v101 Ends++>>
            }
            if(oSelectedContact != null)
            {
               oOrderToUpdate.Apttus_Config2__PrimaryContactId__c = oSelectedContact.Id;
               Database.Update(oOrderToUpdate, false);
           }
           bErrorOccurred = false;
       }
       catch(Exception ex)
       {
           raiseError(ex, 'Error in order Update!' + ex.getStackTraceString());
       }

    }
    public PageReference goToOrder() {

        PageReference pageRef = null;

        try {
            if (!bErrorOccurred) {
                pageRef  = new PageReference('/'+ orderId);
            }
        } catch (Exception e) {  ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, APTS_OrderConstants.ERROR_WHILE_REDIRECT_TO_CART));  }

        return pageRef;
    }   
      
    //V100++ ++>>
    public void searchContactsByName() {
        try {
            sAllContactsByName = '[';

            String searchStr = ApexPages.currentPage().getParameters().get(APTS_OrderConstants.FIRST_PARAM);
            Set<String> filteredContactNameSet = new Set<String>();
            for (String sContactName : ContactDetails.values()) {
                if (sContactName.containsIgnoreCase(searchStr)) {
                    filteredContactNameSet.add(sContactName);
                }
            }
            if (!filteredContactNameSet.isEmpty()) {
                Integer count = filteredContactNameSet.size();
                Integer iId = 0;
                for (String sName : filteredContactNameSet) {

                    sAllContactsByName += '{\'label\':\'' + sName + '\',\'value\':\'' + iId +  '\'}';
                    if (--count != 0) {
                        sAllContactsByName += ',';
                    }
                    iId++;
                }
            }
            if ((searchStr != null) && filteredContactNameSet.isEmpty()) {
                if (searchStr.equalsIgnoreCase('No Results Found')) {
                    errorMessageForNoContacts(searchStr);
                } else {
                    sAllContactsByName = '[{\'label\':\'' + 'No Results Found' + '\',\'value\':\'' + '0'  +  '\'}';
                }
            }

            sAllContactsByName += ']';

        } catch (Exception ex) {raiseError(ex, ' Looks like something went wrong' + ex.getStackTraceString());}
    }

    public void errorMessageForNoContacts(String searchString) {

        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, ' No contact records found with the provided criteria'));

    }    
    public void resetContactSearch() {
        sContactName = null;
        loadContacts();
    }

    public void loadMore() {
        try {
            if (iRemainContact > 0 || iRemainContact ==0) {
                bDisableLess = false;
                iMoreContacts = 5 ;
                system.debug('contactWrapperList size'+contactWrapperList.size());
                system.debug(+contactWrapperList);
                //iRemainContact = iTotalRecords - contactWrapperList.size();
                if (iMoreContacts >= iRemainContact) {
                    iCount = iRemainContact;
                } else {
                    iCount = iMoreContacts;
                }
                for (Integer iIndex = 0; iIndex <= iCount; iIndex++) {
                    Integer listIndex = iIndex + iInitialContacts;
                    Boolean bPrimary = (filterContactByName[iRemainContact].Id == primaryContact);
                   ContactWrapper contwrapper = new ContactWrapper(false, filterContactByName[iRemainContact], bPrimary);
                   contactWrapperList.add(contwrapper);
                    iRemainContact = iRemainContact - 1;
                    iLoadLess = iCount ;
                    /*if(iRemainContact ==0){
                        ContactWrapper contwrappero = new ContactWrapper(false, filterContactByName[iRemainContact], bPrimary);
                        contactWrapperList.add(contwrappero);
                    }*/
                }
            } else {
                bDisableMore = true;
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, ' Look\'s like you have reached the end of the Contact list'));
            }
        } catch (Exception ex) {raiseError(ex, 'Looks like something went wrong' + ex.getStackTraceString());}
    }

    public void loadLess() {
        try {
            Integer iTemp = 0 ;
            if (iLoadLess > 0 || iLoadLess ==0) {
                bDisableMore = false;
                iLoadLess = contactWrapperList.size() - iInitialContacts;
                if ((contactWrapperList.size() - iInitialContacts) <= iInitialContacts) {
                    if(iLoadLess > iMoreContacts )
                    iCount = iMoreContacts;
                    //bDisableLess = true;
                } else {
                    iCount = iInitialContacts;
                }
                iTemp = iCount;
                for (Integer iIndex = iTemp; iIndex >= 0; --iIndex) {
                    contactWrapperList.remove(contactWrapperList.size() - 1);
                    iLoadLess = iLoadLess - 1;
                    iRemainContact = iRemainContact + 1;
                }
            } else {
                bDisableLess = true;
                bDisableMore = false;

                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, ' Look\'s like you have reached the end of the Contact list'));
            }
        } catch (Exception ex) {raiseError(ex, 'Looks like something went wrong' + ex.getStackTraceString());}

    }     

    public PageReference back() {

        PageReference pageRef;

        pageRef = new PageReference('/' + orderId);

        return pageRef;
    }

    private void raiseError(Exception ex, String sMessage) {

        APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString() + ':: ' + ex.getMessage(), 'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id), 'OM', false, true, null, true);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, sMessage + ex.getStackTraceString()));
        bErrorOccurred = true;
    }   
    //v101++<< Starts-- Added this method to get the selected contact using radio button  
    public pagereference getSelected() {
        SelectedId = System.currentPagereference().getParameters().get('selectedId');
        return null;
    }
    //v101 Ends-->>
    public without sharing class ContactWrapper {
        public Boolean selected {get; set;}
        public Contact oContact {get; set;}
        public Boolean isPrimaryContact {get;set;}           
        public ContactWrapper() {
            this.selected = false;
            this.oContact = null;   
            this.isPrimaryContact = false;             
        }
        public ContactWrapper(Boolean selected, Contact oContact, Boolean bPrimaryContact) {
            this.selected = selected;
            this.oContact = oContact;    
            this.isPrimaryContact = bPrimaryContact;
        }
    }
}