/**
* @author        Paul Jarred Aguiling
* @date          6.14.2017          
* @description   Class responsible for creating mass case modification records
* @revision(s)   5.18.2018 Paul Aguiling: KTS-1678 Added getPAsContactList() and adjust case/WO/WOLI mappings
*/
global class CaseModificationBatch implements Database.Batchable<sObject>, Database.Stateful {

    private String queryStr = null;
    private Id caseRecTypeId = null;
    private List<Case> caseList = null;
    private String accountIds = null;
    private String accLocIds = null;
    private String productIds = null;
    private Exception[] errors = new Exception[0];

    /******************************************************************************
    * @author         Paul Jarred Aguiling
    * @date           6.14.2017
    * @description    Constructor of the class
    * @revision(s)
    ******************************************************************************/ 
    public CaseModificationBatch(List<Case> caseList, List<Id> accountIds, List<Id> accLocIds, List<Id> productIds) {
        caseRecTypeId = TS_UtilityClass.getRecordTypeIdByName(Label.TS_Obj_API_Name_Case, Label.TS_Case_RecordType_Field);
        this.caseList = caseList;
        this.accountIds = formatString(accountIds);
        this.accLocIds = formatString(accLocIds);
        this.productIds = formatString(productIds);
    }

    /******************************************************************************
    * @author         Paul Jarred Aguiling
    * @date           6.14.2017
    * @description    Method responsible for formatting SOQL query
    * @revision(s)
    ******************************************************************************/ 
    private String formatString(List<Id> idList) {
        List<String> formattedString = new List<String>();
        String result2 = null;

        for (Id value: idList) {
            formattedString.add('\'' + value + '\'');
        }

        if (!formattedString.isEmpty()) {
            result2 = 'IN (' + String.join(formattedString, ',') + ')';
        } else {
            result2 = '= NULL';
        }

        return result2;
    }

    /******************************************************************************
    * @author         Paul Jarred Aguiling
    * @date           6.14.2017
    * @description    This method is the start of the batch job
    * @revision(s)
    ******************************************************************************/ 
    global Database.QueryLocator start(Database.BatchableContext BC) {
        CustomLogging.push('start', 'CaseModificationBatch');

        String affixQuery = '';

        /* Jan. 17, 2019 - XEN REYES */
        if(accountIds != '= NULL' && accLocIds == '= NULL'){
            affixQuery = + 'AND SoldTo__c ' +  accountIds + ' ';
        } else if(accLocIds != '= NULL'){
            affixQuery = 'AND AccountLocation__c ' + accLocIds + ' ';
        }

        String cseOrg = caseList[0].SalesOrganization__c;

        queryStr = 'SELECT Id, Product__c, AccountLocation__c, SoldTo__c, SoldTo__r.Sales_Organization__c, SalesOrganization__c, RecordType.Name, '
                    + 'AccountLocation__r.Mini_Sales_Organization__c, AccountLocation__r.PreferredEngineer__c, AccountLocation__r.ExcludedEngineer__c, '
                    + 'ParentPhysicalAsset__c, ParentPhysicalAsset__r.RecordType.Name, '
                    + 'ParentPhysicalAsset__r.AccountLocation__c, ParentPhysicalAsset__r.Product__c ' 
                    + 'FROM PhysicalAsset__c WHERE AssetStatus__c = \'Activated\' '
                    + 'AND SalesOrganization__c = \'' + cseOrg + '\' ' //KTS-2196 9.27.2018
                    + 'AND ((RecordType.Name = \'Machine\' AND ParentPhysicalAsset__c = NULL) ' //KTS-2492 XEN REYES Jan. 16, 2019
                    + 'OR (RecordType.Name = \'Option\' AND ParentPhysicalAsset__c != NULL)) ' //KTS-2492 XEN REYES Jan. 16, 2019
                    + 'AND Product__c ' + productIds + ' ' + affixQuery
                    + 'AND MothballAssetIndicator__c = false'; //KTS-2196 9.27.2018 */

        System.debug('queryStr >>> ' + queryStr);
        
        CustomLogging.pop();

        return Database.getQueryLocator(queryStr);

    }

    /******************************************************************************
    * @author         Paul Jarred Aguiling
    * @date           6.14.2017
    * @description    Method responsible executing the main logic
    * @revision(s)
    ******************************************************************************/ 
    global void execute(Database.BatchableContext BC, List<PhysicalAsset__c> physicalAssetList) {
        CustomLogging.push('execute', 'CaseModificationBatch');
        
        List<WorkOrderLineItem> woliToInsert = new List<WorkOrderLineItem>();
        Map<String, Case> caseMap = new Map<String, Case>();
        Map<String, WorkOrder> woMap = new Map<String, WorkOrder>();
        List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
        Set<String> hasBundleId = new Set<String>();
        List<Case> caseToInsert = new List<Case>();
        Map<Id, Set<String>> priceBookMap = new Map<Id, Set<String>>();
        Map<Id, Set<String>> priceWOLIMap = new Map<Id, Set<String>>();
        Set<Id> checkOptionProduct = new Set<Id>();
        Date dateToday = Date.today();

        try {

            //Retrieve main service person/service contact/main contact/standard contact related to physical asset
            Map<Id, Id> map_physicalAssetContact = getPAsContactList(physicalAssetList);

            /* Jan. 17, 2019 XEN REYES */
            Case cse2 = new Case();
            Set<Id> product2IdSet = new Set<Id>();
            Set<String> salesOrganizationSet = new Set<String>();
            Set<Id> physicalAssetParentIdSet = new Set<Id>();
            List<PhysicalAsset__c> parentAssetsList = new  List<PhysicalAsset__c>();
            for (Case csList : caseList){
                cse2 = csList;
                break;
            }

            for (PhysicalAsset__c physicalAsset : physicalAssetList) {

                //######### Create Work Order Line Item #######//    
                WorkOrderLineItem woli = createWorkOrderLineItem(physicalAsset, Label.TS_Type_Task);
                woliList.add(woli);
                //######### Create Work Order Line Item #######//

                //######### Create Case #######//
                /* for (Case cse2: caseList) {
                    if (physicalAsset.SoldTo__c == cse2.AccountId
                        && physicalAsset.AccountLocation__c == cse2.AccountLocation__c
                        && physicalAsset.Product__c == cse2.ProductId) {
                        
                        Case cse = createCaseRecords(physicalAsset, Label.TS_Activity_Type_S60, cse2, Label.TS_Case_Type_FieldService, caseRecTypeId, map_physicalAssetContact);
                        caseToInsert.add(cse);

                        if (checkOptionProduct.add(cse2.ProductId)) {
                            priceBookMap.put(cse2.ProductId, cse.SalesOrganization__c);
                            priceWOLIMap.put(cse2.ProductId, physicalAsset.Id);
                        }

                        //Jan. 16, 2019 XEN REYES KTS-2492
                        if(physicalAsset.RecordType.Name == 'Option'){
                            priceBookMap.put(physicalAsset.ParentPhysicalAsset__r.Product__c, cse.SalesOrganization__c);
                            priceWOLIMap.put(physicalAsset.ParentPhysicalAsset__r.Product__c, physicalAsset.ParentPhysicalAsset__c);
                        }

                        break;
                    }
                } */
                //######### Create Case #######//
                
                Case cse = createCaseRecords(physicalAsset, Label.TS_Activity_Type_S60, cse2, Label.TS_Case_Type_FieldService, caseRecTypeId, map_physicalAssetContact);
                caseToInsert.add(cse);

                product2IdSet.add(cse2.ProductId);
                salesOrganizationSet.add(cse.SalesOrganization__c);
                    
                //Jan. 16, 2019 XEN REYES KTS-2492
                if(physicalAsset.RecordType.Name == 'Option'){
                    product2IdSet.add(physicalAsset.ParentPhysicalAsset__r.Product__c);
                    physicalAssetParentIdSet.add(physicalAsset.ParentPhysicalAsset__c);
                }
            }

            if(!physicalAssetParentIdSet.isEmpty()){
                parentAssetsList = [SELECT Id, Product__c, SalesOrganization__c FROM PhysicalAsset__c WHERE Id IN: physicalAssetParentIdSet];
            }

            //Get pricebook entry based on Product Id and Sales Organization
            //From pricebook entry we can retrieve the pricebook 
            Map<String, PriceBookEntry> priceMap = new Map<String, PriceBookEntry>();

            /* for (PriceBookEntry priceBookEnt: [SELECT Id, PriceBook2Id, Product2Id 
                                               FROM PriceBookEntry WHERE Product2Id IN :priceBookMap.keySet() 
                                               AND Sales_Organization__c IN:priceBookMap.values()
                                               AND IsActive = true]) {

                if (priceWOLIMap.get(priceBookEnt.Product2Id) != null){
                    priceMap.put(priceWOLIMap.get(priceBookEnt.Product2Id), priceBookEnt);
                }
            } */

            for (PriceBookEntry priceBookEnt: [SELECT Id, PriceBook2Id, Product2Id, Sales_Organization__c
                                               FROM PriceBookEntry WHERE Product2Id IN : product2IdSet 
                                               AND Sales_Organization__c IN: salesOrganizationSet
                                               AND IsActive = true]) {

                //Create PricebookEntryMap for Queried Assets
                for (PhysicalAsset__c physicalAsset : physicalAssetList) {
                    if(priceBookEnt.Sales_Organization__c == physicalAsset.SalesOrganization__c && 
                        priceBookEnt.Product2Id == physicalAsset.Product__c){
                        priceMap.put(physicalAsset.Id, priceBookEnt);
                    }
                }

                //Create PricebookEntryMap for Parent Assets of Options
                if(!parentAssetsList.isEmpty()){
                    for (PhysicalAsset__c physicalAsset : parentAssetsList) {
                        if(priceBookEnt.Sales_Organization__c == physicalAsset.SalesOrganization__c && 
                            priceBookEnt.Product2Id == physicalAsset.Product__c){
                            priceMap.put(physicalAsset.Id, priceBookEnt);
                        }
                    }
                }
                
            }

            //Insert Case Records
            if (!caseToInsert.isEmpty() && Schema.sObjectType.Case.isCreateable()) {
                insert caseToInsert;

                /*  GET ALL IDs of inserted case - Use this to reference the values that should be queried first before stamping to WO/WOLI.
                    These are the fields that are not originally in Case in create.
                    Xen Reyes - Jan. 16, 2019
                */
                Map<Id, Case> caseToInsertMap = new Map<Id,Case>(caseToInsert);
                Map<Id, Case> caseToInsertMapQueried = new Map<Id,Case>([SELECT Id, RepeatVisit__c FROM Case WHERE Id IN: caseToInsertMap.keySet()]);

                //Create and insert work order records
                for (Case cse: caseToInsert) {
                    WorkOrder wo = new WorkOrder();
                    wo.CaseId = cse.Id;
                    wo.OwnerID = cse.OwnerId;
                    wo.Status = Label.TS_Status_Open;
                    wo.ContactId = cse.ContactId;
                    wo.PriceBook2Id = priceMap != null && priceMap.get(cse.CaseExternalReference__c) != null? priceMap.get(cse.CaseExternalReference__c).PriceBook2Id : null;

                    //KTS-2492 XEN REYES Jan. 14, 2019
                    wo.SalesOrganization__c = cse.SalesOrganization__c;
                    wo.WorkOrderType__c = Label.TS_Activity_Type_S60;

                    woMap.put(cse.CaseExternalReference__c, wo);
                    caseMap.put(cse.CaseExternalReference__c, cse);
                }

                if (!woMap.isEmpty() && Schema.sObjectType.WorkOrder.isCreateable()){
                    insert woMap.values();
                }

                //Create and insert work order line item records
                for (WorkOrderLineItem woli: woliList) {
                    woli.Case__c = woMap.get(woli.WOLIExternalReference__c).CaseId;
                    woli.WorkOrderId = woMap.get(woli.WOLIExternalReference__c).Id;
                    woli.EarlyStart__c = caseMap.get(woli.WOLIExternalReference__c).EarlyStartDate__c;
                    woli.SLADate__c = caseMap.get(woli.WOLIExternalReference__c).SLADate__c;
                    woli.Subject = caseMap.get(woli.WOLIExternalReference__c).Subject;
                    woli.Description = caseMap.get(woli.WOLIExternalReference__c).Description;
                    woli.PricebookEntryId = priceMap != null && priceMap.get(woli.PhysicalAsset__c) != null? priceMap.get(woli.PhysicalAsset__c).Id : null;

                    //KTS-2189 XEN REYES 9.22.2018
                    woli.Re_active__c = caseMap.get(woli.WOLIExternalReference__c).Re_active__c;

                    //KTS-2492 XEN REYES Jan. 16, 2019
                    woli.RepeatVisit__c = caseToInsertMapQueried.get(woli.Case__c).RepeatVisit__c;
                    
                    //DateTime.newInstance(newDate.year(), newDate.month(), newDate.day(), 8, 0, 0);
                    //newDate = newDate + 4; //Add 4 days to reach Friday
                    //DateTime.newInstance(newDate.year(), newDate.month(), newDate.day(), 17, 0, 0);

                    woliToInsert.add(woli);
                }

                if (!woliToInsert.isEmpty() && Schema.sObjectType.WorkOrderLineItem.isCreateable()){
                    insert woliToInsert;
                }
            }

        } catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();
            System.debug(e);
            errors.add(e);
        }
        
        CustomLogging.pop();
    }


    /******************************************************************************
    * @author         Paul Jarred Aguiling
    * @date           6.14.2017
    * @description    Method responsible for final changes or updates whitin the batch of records
    * @revision(s)
    ******************************************************************************/ 
    global void finish(Database.BatchableContext BC) {
        CustomLogging.push('finish', 'CaseModificationBatch');

        System.debug('errors >> ' + errors);
        System.debug('caseList SIZE>> ' + caseList.size());
        
        if (errors.isEmpty() && Schema.sObjectType.Case.isUpdateable()) {
            List<Case> caseToUpdate = new List<Case>();
            for (Case cse: caseList) {
                
                // 10.09.2017 TSWS-496
                //cse.Status = Label.TS_Status_CompleteD;
                cse.Status = Label.TS_Status_Closed;
                caseToUpdate.add(cse);
            }

            update caseToUpdate;
        }

        CustomLogging.pop();
    }

    /******************************************************************************
    * @author         Paul Jarred Aguiling
    * @date           05.18.2018
    * @description    Method responsible for getting the contact list
    * @revision(s)
    ******************************************************************************/ 
    @TestVisible
    private Map<Id, Id> getPAsContactList(List<PhysicalAsset__c> physicalAssetList) {
        CustomLogging.push('getPAsContactList', 'CaseModificationBatch');
        Map<Id, List<Contact>> contactMap = new Map<Id, List<Contact>>();
        Map<Id, Id> phyContact = new Map<Id, Id>();
        List<Contact> mainServiceContactList = new List<Contact>();
        List<Contact> mainContactList = new List<Contact>();
        List<Contact> contactList = new List<Contact>();
        Set<Id> accountIds = new Set<Id>();

        //Iterate related accounts from the physical asset
        for (PhysicalAsset__c physicalAsset : physicalAssetList) {
            if (physicalAsset.SoldTo__c != null) {
                accountIds.add(physicalAsset.SoldTo__c);
            }
        }

        if (accountIds != null && !accountIds.isEmpty()) {
            //Iterate list of contacts from the physical asset account id
            for (Contact con: [SELECT Id, AccountId, Main_Service_Person__c, 
                                    Function__c, Main_Contact__c
                               FROM Contact 
                               WHERE AccountId IN :accountIds 
                               ORDER by CreatedDate DESC]) {

                //Add the right account to the child contacts
                if (contactMap.containsKey(con.AccountId)) {
                    contactMap.get(con.AccountId).add(con);
                } else {
                    contactMap.put(con.AccountId, new List<Contact>{con});
                }
            }

            //Iterate physical asset records to then assign the correct contact
            for (PhysicalAsset__c physicalAsset : physicalAssetList) {
                if (physicalAsset.SoldTo__c != null && contactMap.get(physicalAsset.SoldTo__c) != null) {
                    for (Contact con : contactMap.get(physicalAsset.SoldTo__c)) {
                        //Check if contact has Main Service Person
                        if (con.Main_Service_Person__c) {
                            phyContact.put(physicalAsset.Id, con.Id);
                            break;
                        //Check if contact has Service Contact
                        } else if (Label.TS_ConFunction_ServiceContact.equals(con.Function__c)){
                            mainServiceContactList.add(con);
                        //Check if contact has Main Contact
                        } else if (con.Main_Contact__c) {
                            mainContactList.add(con);     
                        //Add first available contact if the above conditions does not apply
                        } else {
                            contactList.add(con);
                        }
                    }

                    //Assign service contact to respective physical asset
                    if (phyContact.isEmpty() && !mainServiceContactList.isEmpty()) {
                        phyContact.put(physicalAsset.Id, mainServiceContactList.get(0).Id);
                    //Assign main contact to respective physical asset
                    } else if (phyContact.isEmpty() && !mainContactList.isEmpty()) {
                        phyContact.put(physicalAsset.Id, mainContactList.get(0).Id);
                    //Assign contact to respective physical asset
                    } else if (phyContact.isEmpty() && !contactList.isEmpty()) {
                        phyContact.put(physicalAsset.Id, contactList.get(0).Id);
                    }
                }
            }
        }

        return phyContact;
    }

    /******************************************************************************
    * @author         Paul Jarred Aguiling
    * @date           5.16.2017
    * @description    Method responsible for setting case values
    * @revision(s)
    ******************************************************************************/ 
    private Case createCaseRecords(PhysicalAsset__c physicalAsset, String subType, Case caseParent, String cseType, Id caseRecTypeId, Map<Id, Id> phyContactMap) {
        CustomLogging.push('createCaseRecords', 'SalesTriggerController');
        Case cse = new Case();
        cse.Type = cseType;
        cse.Subject = caseParent.Subject;
        cse.Description = caseParent.Description;
        cse.SubType__c = subtype;
        cse.Status = Label.TS_Status_InProgress;
        cse.EarlyStartDate__c = caseParent.EarlyStartDate__c;
        cse.SLADate__c = caseParent.SLADate__c;
        cse.ParentId = caseParent.Id;
        cse.Origin = Label.TS_Case_Origin_Manual;
        cse.AccountId = physicalAsset.SoldTo__c;
        cse.SalesOrganization__c = physicalAsset.AccountLocation__c != null? physicalAsset.AccountLocation__r.Mini_Sales_Organization__c: null;
        cse.OwnerId = caseParent.OwnerId;
        cse.CaseExternalReference__c = String.valueOf(physicalAsset.Id);

        /*XEN REYES Jan. 16, 2019 */
        if(physicalAsset.ParentPhysicalAsset__c != null){
            cse.PhysicalAsset__c = physicalAsset.ParentPhysicalAsset__c;
            cse.Fault_Configuration__c = physicalAsset.Id;
        } else {
            cse.PhysicalAsset__c = physicalAsset.Id;
        }

        //KTS-2189 XEN REYES 9.22.2018
        cse.Re_active__c = caseParent.Re_active__c;

        //Assigned the right contact based on the filtered child contacts of Sold to (Account)
        if (physicalAsset.SoldTo__c != null && phyContactMap != null && phyContactMap.get(physicalAsset.Id) != null) {
            cse.ContactId =  phyContactMap.get(physicalAsset.Id);
        }

        //XEN REYES Jan. 23, 2019 KTS-2196: This is to ensure that even if the default owner is Individual, the case will be routed to the correct queue.
        cse.AssignToQueue__c = true;
        cse.TS_IsGeneratedFromBatch__c = true;

        CustomLogging.pop();
        return cse;
    }

    /******************************************************************************
    * @author         Paul Jarred Aguiling
    * @date           5.16.2017
    * @description    Method responsible for setting work order line item values
    * @revision(s)
    ******************************************************************************/ 
    private WorkOrderLineItem createWorkOrderLineItem(PhysicalAsset__c physicalAsset, String type) {
        CustomLogging.push('createWorkOrderLineItem', 'SalesTriggerController');

        WorkOrderLineItem woli = new WorkOrderLineItem();
        woli.Status = Label.TS_Status_Open;
        woli.WorkOrderType__c = Label.TS_Activity_Type_S60;
        woli.WorkOrderLineItemType__c = type;
        woli.WOLIExternalReference__c = physicalAsset.Id;

        /*XEN REYES Jan. 16, 2019 */
        woli.PhysicalAsset__c = physicalAsset.Id;
        woli.AccountLocation__c = physicalAsset.AccountLocation__c;
        woli.PreferredEngineer__c = physicalAsset.AccountLocation__r.PreferredEngineer__c;
        woli.ExcludedEngineer__c = physicalAsset.AccountLocation__r.ExcludedEngineer__c;

        //Prefix with the Account Location of the Physical Asset Machine Record
        //(link via Parent Physical Asset if the found physical asset was an option)
        if (physicalAsset.ParentPhysicalAsset__c != null 
            && TS_Constants.PA_RECTYPE_MACHINE.equals(physicalAsset.ParentPhysicalAsset__r.RecordType.Name)) {
            woli.AccountLocation__c = physicalAsset.ParentPhysicalAsset__r.AccountLocation__c;
            woli.PhysicalAsset__c = physicalAsset.ParentPhysicalAsset__c;
        }

        //Stamp the physical asset option in fault configuration
        if (TS_Constants.PA_RECTYPE_OPTION.equals(physicalAsset.RecordType.Name)) {
            woli.FaultConfiguration__c = physicalAsset.Id;
        }
      
        CustomLogging.pop();  
        return woli;
    }
}