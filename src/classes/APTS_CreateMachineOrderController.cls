/*************************************************************
@Name: APTS_CreateMachineOrder
@Author: Galin Georgiev
@CreateDate: 02-01-2018
@Description: Create Machine Order from Account
@UsedBy: Create Order button on Account page
******************************************************************/
//v100 02-01-2018 Galin Georgiev: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes 
//V101 16.01.2019 Venky Muppalaneni: FD 2168 : added the columns in select list of agreement
//v102 05.04.2019 Akanksha : CR 2259 : ABO Deinstall flow
//V103 10.04.2019 Neev Shah : Defect#5930 -- order creation for Being Renewed Agreement, removed Expired Status
//V104 16-05-2019  Sethu: DOQOM-37 Populate picking list text on the order from Account location
//v105 28-05-2019 Akanksha: DOK31-246 Adding where condition in the agreement query to filter out Registration form
//V106 14-Oct-2019 Aarthi Pitchai: QTCFLEX1-1451 Remove the logic to set customer comments and picking list text
//v107 9-Sept-2020 Sneha Jaiwant: DQ2456 Agreements with the end date in future
//v108 20-1-2021 Sneha: DQ4891 Unsuccessful Trial - Normal de-installation process/different SAP order type (XB23)


public with sharing class APTS_CreateMachineOrderController {

    private final Apttus__APTS_Agreement__c oAgreement;
    private Id accountId;
    private Id locId;
    private Account initialAccount;
    private Set<Id> accountIdSet;
    //private Map<Id, Account> idToAccountMap;

    private Set<Id> allAgreementIdSet = new Set<Id>();
    private Set<Id> amendedAgreementIdSet = new Set<Id>();
    private Set<Id> cancelledAgreementIdSet = new Set<Id>();
    private Set<Id> fullyCancelledAgreementIdSet = new Set<Id>();
    private Set<Id> expiredAgreementIdSet = new Set<Id>();

    public Apttus_Config2__Order__c oOrder {get; set;}
    public List<AgreementWrapper> agreementWrapperList {get; set;}
    public List<AgreementWrapper> agreementWrapperTmpList {get; set;}
    public Map<Id, APTS_Agreement_PO_Details__c> agreementPODetailsMap;

    public Boolean bShowAgreements {get; set;}
    public Boolean bShowCreate {get; set;}
    //v107
    public Boolean isEndPast {get; set;}

    public Boolean bTechSwap {get; set;}
    public Date deInstallDate {get; set;}

    public Boolean bFirstClickOnAgreement {get; set;}
    
    //sneha
    public Boolean isTrial{get; set;}

    public APTS_CreateMachineOrderController() {

        accountId = ApexPages.currentPage().getParameters().get(APTS_OrderConstants.ID);
        locId = ApexPages.currentPage().getParameters().get(APTS_OrderConstants.LOCID);

        bShowAgreements = true;
        bFirstClickOnAgreement = true;
        bShowCreate = true;
        bTechSwap = false;
        //v107
        isEndPast = false;
        isTrial=false;

        agreementWrapperList = new List<AgreementWrapper>();
        agreementWrapperTmpList = new List<AgreementWrapper>();
        accountIdSet = new Set<Id>();

        deInstallDate = APTS_OrderUtils.getTheNextMonday();

        oOrder = new Apttus_Config2__Order__c();
        oOrder.APTS_Order_Type__c = APTS_OrderConstants.MACHINE_ORDER;

        oOrder.Apttus_Config2__Source__c = APTS_OrderConstants.ACCOUNT;
        oOrder = APTS_OrderUtils.setOrderHeaderMandatoryFields(oOrder, APTS_OrderConstants.MACHINE_ORDER);

        Map<Id, Contact> idToContactMap = APTS_OrderUtils.getAllContacts(accountId);
        oOrder.Apttus_Config2__PrimaryContactId__c = APTS_OrderUtils.getPrimaryContactId(idToContactMap, APTS_OrderConstants.MACHINE_ORDER);
        
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
                    Related_Payer_Machines_Services__c,
                    Billing_header_text__c,
                    ParentId,
                    Parent.Parent.Id,
                    //v102 ++ <<
                    APTS_Price_List__c
                    //v102 ++ >>
                    FROM Account
                    WHERE Id = :accountId]);

        initialAccount = initialAccountMap.get(accountId);
        accountIdSet.add(initialAccount.Id);

        if (initialAccount != null && initialAccount.Id != initialAccount.APTS_Ultimate_Parent_Id__c) {
            if (initialAccount.ParentId != null) {accountIdSet.add(initialAccount.ParentId);}
            if (initialAccount.Parent.Parent.Id != null) {accountIdSet.add(initialAccount.Parent.Parent.Id);}
        }
        /*
                if (initialAccount.Id != initialAccount.APTS_Ultimate_Parent_Id__c) {
                    Map<Id, Account> idToAccountMapTmp = new Map<Id, Account>([SELECT Id, APTS_Account_Level__c FROM Account WHERE APTS_Ultimate_Parent_Id__c = :initialAccount.APTS_Ultimate_Parent_Id__c]);
                    idToAccountMap = filterAccounts(initialAccount, idToAccountMapTmp);
                } else {
                    idToAccountMap = initialAccountMap;
                }
        */
    }

    public void loadAgreements() {

        if (bFirstClickOnAgreement) {

            Map<Id, Apttus__APTS_Agreement__c> idToAgreementTmpMap = new Map<Id, Apttus__APTS_Agreement__c>([
                        SELECT Id, Name, RecordTypeId, Apttus_CMConfig__PriceListId__c, Apttus_CMConfig__PONumber__c,
                        Apttus_CMConfig__BillingPreferenceId__c, Apttus_CMConfig__PaymentTermId__c, Apttus__Status_Category__c,
                        Apttus__Status__c, Apttus__Contract_Start_Date__c, Apttus__Contract_End_Date__c,
                        Apttus__Account__r.APTS_Account_Level__c, Apttus__Account__r.Name, Apttus__Primary_Contact__c,
                        APTS_Language__c, APTS_Bill_to_Party_Ingredients__c, APTS_Payer_Ingredients__c, APTS_Bill_to_Party_MachServ__c,
                        APTS_Payer_Machines_Services__c, Apttus__Account__c, Apttus__Version_Number__c, APTS_Location__c, APTS_Location__r.Billing_header_text__c,
                        APTS_Location__r.Delivery_text__c,
                        //V104 ++<<
                        APTS_Location__r.Picking_list_text__c,
                        //V104 ++>>
                        //V102++>>
                        APTS_Check_on_Account_Machines__c,
                        APTS_Check_on_Account_Ingredients__c
                        //V102++<<
                        FROM Apttus__APTS_Agreement__c
                        WHERE Apttus__Account__c IN :accountIdSet AND //:idToAccountMap.keySet() AND
                        ((Apttus__Status_Category__c = :APTS_OrderConstants.IN_EFFECT AND Apttus__Status__c = :APTS_OrderConstants.ACTIVATED) OR
                         (Apttus__Status_Category__c = :APTS_OrderConstants.IN_EFFECT AND Apttus__Status__c = :APTS_OrderConstants.BEING_AMENDED) OR
                         (Apttus__Status_Category__c = :APTS_OrderConstants.IN_EFFECT AND Apttus__Status__c = :APTS_OrderConstants.BEING_RENEWED) ) AND //v105
                          RecordType.Name != :APTS_OrderConstants.REGISTRATION_FORM]);
            System.debug('yyyy' + idToAgreementTmpMap);

            Map<Id, Apttus__AgreementLineItem__c> idToAgreementLineItemMap = new Map<Id, Apttus__AgreementLineItem__c>([
                        SELECT Id,
                        Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c,
                        Apttus__AgreementId__c,
                        Apttus_CMConfig__LineStatus__c,
                        Apttus__AgreementId__r.Apttus__Version_Number__c,
                        Apttus_CMConfig__HasOptions__c,
                        Apttus__ProductId__c,
                        Apttus__Quantity__c
                        FROM Apttus__AgreementLineItem__c
                        WHERE Apttus__AgreementId__c IN :idToAgreementTmpMap.keySet()]);

            Map<String, Apttus__APTS_Agreement__c> sortCriteriaToAgreementMap = new Map<String, Apttus__APTS_Agreement__c>();
            Integer iCountStandardDeal = 0;
            Integer iCountConsumptionsModel = 0;

            Map<Id, Apttus__APTS_Agreement__c> idToAgreementMap = new Map<Id, Apttus__APTS_Agreement__c>();

            idToAgreementMap = filterMachineAgreements(idToAgreementTmpMap, idToAgreementLineItemMap);
            amendedAgreementIdSet = getAmendedAgreements(idToAgreementMap, idToAgreementLineItemMap);
            cancelledAgreementIdSet = getCancelledAgreements(idToAgreementMap, idToAgreementLineItemMap);
            fullyCancelledAgreementIdSet = getFullyCancelledAgreements(idToAgreementMap, idToAgreementLineItemMap);
            expiredAgreementIdSet = getExpiredAgreements(idToAgreementMap);

            for (Apttus__APTS_Agreement__c oAgreement : idToAgreementMap.values()) {
                String sSortCriteria;
                String sAccountLevel = oAgreement.Apttus__Account__r.APTS_Account_Level__c.substring(0, 1);
                String sInitialAccountLevel = initialAccount.APTS_Account_Level__c.substring(0, 1);
                if (sAccountLevel <= sInitialAccountLevel) {
                  if(oAgreement.Apttus__Contract_End_Date__c >= system.today() ){
                    String sRecordType = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosById().get(oAgreement.RecordTypeId).getname();

                    if (sRecordType == APTS_OrderConstants.STANDARD_DEAL) {
                        sSortCriteria = APTS_OrderConstants.AA + sAccountLevel + iCountStandardDeal;
                        iCountStandardDeal++;
                    } else {
                        sSortCriteria = APTS_OrderConstants.BB + sAccountLevel + iCountConsumptionsModel;
                        iCountConsumptionsModel++;
                    }
                    sortCriteriaToAgreementMap.put(sSortCriteria, oAgreement);
                }
                }
                
            }
             //v107
            if((sortCriteriaToAgreementMap.isEmpty() && sortCriteriaToAgreementMap.size() ==0) &&(!idToAgreementMap.isEmpty() && idToAgreementMap.size() >=1) ){
            isEndPast = true;
            }
            //v107
            

            List<String> sortCriteriaList = new List<String>(sortCriteriaToAgreementMap.keySet());
            sortCriteriaList.sort();

            if (iCountStandardDeal > 0) {
                String sSortCriteria = sortCriteriaList.get(iCountStandardDeal - 1);
                AgreementWrapper oAgreementWrapper = new AgreementWrapper(false, sortCriteriaToAgreementMap.get(sSortCriteria));
                agreementWrapperList.add(oAgreementWrapper);
            }

            if (iCountConsumptionsModel > 0) {
                String sSortCriteria = sortCriteriaList.get(iCountStandardDeal + iCountConsumptionsModel - 1);
                AgreementWrapper oAgreementWrapper = new AgreementWrapper(false, sortCriteriaToAgreementMap.get(sSortCriteria));
                agreementWrapperList.add(oAgreementWrapper);
            }
            agreementWrapperTmpList.addAll(agreementWrapperList);
            

            bFirstClickOnAgreement = false;

            filterAgreements();
            checkHidden();

            if (agreementWrapperList.size() == 1) {
                agreementWrapperList[0].selected = true;
            }
        }
    }

    public Map<Id, Account> filterAccounts(Account initialAccount, Map<Id, Account> idToAccountMapTmp) {

        Map<Id, Account> idToAccountMap = new Map<Id, Account>();
        String sInitialAccountLevel = initialAccount.APTS_Account_Level__c.substring(0, 1);
        String sAccountLevel;

        idToAccountMap.put(initialAccount.Id, initialAccount);

        for (Account oAccount : idToAccountMapTmp.values()) {

            sAccountLevel = oAccount.APTS_Account_Level__c.substring(0, 1);
            if (sAccountLevel < sInitialAccountLevel) {
                idToAccountMap.put(oAccount.Id, oAccount);
            }
        }

        return idToAccountMap;
    }

    public Map<Id, Apttus__APTS_Agreement__c> filterMachineAgreements(Map<Id, Apttus__APTS_Agreement__c> idToAgreementTmpMap, Map<Id, Apttus__AgreementLineItem__c> idToAgreementLineItemMap) {

        Map<Id, Apttus__APTS_Agreement__c> idToAgreementMap = new Map<Id, Apttus__APTS_Agreement__c>();

        Set<Id> agreementIdWithBundleSet = new Set<Id>();
        //try{
        for (Apttus__AgreementLineItem__c oAgreementLineItem : idToAgreementLineItemMap.values()) {
            if (oAgreementLineItem.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c == APTS_OrderConstants.BUNDLE) {
                agreementIdWithBundleSet.add(oAgreementLineItem.Apttus__AgreementId__c);
            }
        }

        for (Id agreementIdWithBundle : agreementIdWithBundleSet) {
            idToAgreementMap.put(agreementIdWithBundle, idToAgreementTmpMap.get(agreementIdWithBundle));
            allAgreementIdSet.add(agreementIdWithBundle);
        }
        //} catch (Exception e) {
        //    APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id), 'OM', false, true, APTS_OrderConstants.EMAIL, true);
        //}
        return idToAgreementMap;
    }

    public Set<Id> getAmendedAgreements(Map<Id, Apttus__APTS_Agreement__c> idToAgreementTmpMap, Map<Id, Apttus__AgreementLineItem__c> idToAgreementLineItemMap) {

        Set<Id> amendedAgreementIdSet = new Set<Id>();

        Set<Id> agreementIdExistingSet = new Set<Id>();
        Set<Id> agreementIdAmendedSet = new Set<Id>();
        Set<Id> agreementIdAllSet = new Set<Id>();

        //try{
        for (Apttus__AgreementLineItem__c oAgreementLineItem : idToAgreementLineItemMap.values()) {

            if (oAgreementLineItem.Apttus__AgreementId__r.Apttus__Version_Number__c > 0 && oAgreementLineItem.Apttus_CMConfig__LineStatus__c == APTS_OrderConstants.EXISTING) {
                agreementIdExistingSet.add(oAgreementLineItem.Apttus__AgreementId__c);
                agreementIdAllSet.add(oAgreementLineItem.Apttus__AgreementId__c);
            }
            if (oAgreementLineItem.Apttus__AgreementId__r.Apttus__Version_Number__c > 0 && oAgreementLineItem.Apttus_CMConfig__LineStatus__c == APTS_OrderConstants.AMENDED) {
                agreementIdAmendedSet.add(oAgreementLineItem.Apttus__AgreementId__c);
                agreementIdAllSet.add(oAgreementLineItem.Apttus__AgreementId__c);
            }
        }

        for (Id agreementId : agreementIdAllSet) {

            if (agreementIdExistingSet.contains(agreementId) || agreementIdAmendedSet.contains(agreementId)) {
                amendedAgreementIdSet.add(agreementId);
            }
        }
        //} catch (Exception e) {
        //    APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id), 'OM', false, true, APTS_OrderConstants.EMAIL, true);
        //}
        return amendedAgreementIdSet;
    }

    public Set<Id> getCancelledAgreements(Map<Id, Apttus__APTS_Agreement__c> idToAgreementTmpMap, Map<Id, Apttus__AgreementLineItem__c> idToAgreementLineItemMap) {

        Set<Id> cancelledAgreementIdSet = new Set<Id>();

        //try{
        for (Apttus__AgreementLineItem__c oAgreementLineItem : idToAgreementLineItemMap.values()) {

            if (oAgreementLineItem.Apttus__AgreementId__r.Apttus__Version_Number__c > 0 && oAgreementLineItem.Apttus_CMConfig__LineStatus__c == APTS_OrderConstants.CANCELLED) {
                cancelledAgreementIdSet.add(oAgreementLineItem.Apttus__AgreementId__c);
            }
        }
        //} catch (Exception e) {
        //    APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id), 'OM', false, true, APTS_OrderConstants.EMAIL, true);
        //}
        return cancelledAgreementIdSet;
    }

    public Set<Id> getFullyCancelledAgreements(Map<Id, Apttus__APTS_Agreement__c> idToAgreementTmpMap, Map<Id, Apttus__AgreementLineItem__c> idToAgreementLineItemMap) {

        Set<Id> fullyCancelledAgreementIdSet = new Set<Id>();
        Map<Id, List<Decimal>> agreementIdToCountListMap = new Map<Id, List<Decimal>>();
        //try{
        for (Apttus__AgreementLineItem__c oAgreementLineItem : idToAgreementLineItemMap.values()) {

            List<Decimal> countList = agreementIdToCountListMap.get(oAgreementLineItem.Apttus__AgreementId__c);

            if (countList == null) {
                countList = new List<Decimal> {0, 0};
            }

            if (oAgreementLineItem.Apttus__AgreementId__r.Apttus__Version_Number__c > 0 && oAgreementLineItem.Apttus_CMConfig__LineStatus__c == APTS_OrderConstants.CANCELLED && oAgreementLineItem.Apttus_CMConfig__HasOptions__c) {
                countList[0] = countList[0] + oAgreementLineItem.Apttus__Quantity__c;
            } else if (oAgreementLineItem.Apttus__AgreementId__r.Apttus__Version_Number__c > 0 && oAgreementLineItem.Apttus_CMConfig__LineStatus__c == APTS_OrderConstants.LABEL_NEW && oAgreementLineItem.Apttus_CMConfig__HasOptions__c) {
                countList[1] = countList[1] + oAgreementLineItem.Apttus__Quantity__c;
            }

            agreementIdToCountListMap.put(oAgreementLineItem.Apttus__AgreementId__c, countList);
        }

        for (Id agreementId : agreementIdToCountListMap.keySet()) {

            List<Decimal> countList = agreementIdToCountListMap.get(agreementId);
            if (countList[0] != 0 && countList[1] != 0 && countList[0] == countList[1]) {
                fullyCancelledAgreementIdSet.add(agreementId);
            }
        }
        //} catch (Exception e) {
        //    APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id), 'OM', false, true, APTS_OrderConstants.EMAIL, true);
        //}
        return fullyCancelledAgreementIdSet;
    }

    public Set<Id> getExpiredAgreements(Map<Id, Apttus__APTS_Agreement__c> idToAgreementTmpMap) {

        Set<Id> expiredAgreementIdSet = new Set<Id>();

        for (Apttus__APTS_Agreement__c oAgreement : idToAgreementTmpMap.values()) {

            if (oAgreement.Apttus__Status_Category__c == APTS_OrderConstants.EXPIRED) {
                expiredAgreementIdSet.add(oAgreement.Id);
             
            }
        }

        return expiredAgreementIdSet;
    }


    public List<SelectOption> getOrderSubTypePicklist() {

        List<SelectOption> options = new List<SelectOption>();

        options.add(new SelectOption(APTS_OrderConstants.INSTALLATION, APTS_OrderConstants.INSTALLATION));
        options.add(new SelectOption(APTS_OrderConstants.DE_INSTALLATION, APTS_OrderConstants.DE_INSTALLATION));
        options.add(new SelectOption(APTS_OrderConstants.INTERNAL_MOVEMENT, APTS_OrderConstants.INTERNAL_MOVEMENT));
        options.add(new SelectOption(APTS_OrderConstants.EXTERNAL_MOVEMENT_WITH_CONTRACT_CHANGE, APTS_OrderConstants.EXTERNAL_MOVEMENT_WITH_CONTRACT_CHANGE));
        options.add(new SelectOption(APTS_OrderConstants.EXTERNAL_MOVEMENT_WITHOUT_CONTRACT_CHANGE, APTS_OrderConstants.EXTERNAL_MOVEMENT_WITHOUT_CONTRACT_CHANGE));
        options.add(new SelectOption(APTS_OrderConstants.TECHNICAL_SWAP, APTS_OrderConstants.TECHNICAL_SWAP));
        options.add(new SelectOption(APTS_OrderConstants.COMMERCIAL_SWAP, APTS_OrderConstants.COMMERCIAL_SWAP));
        options.add(new SelectOption(APTS_OrderConstants.CONVERSION, APTS_OrderConstants.CONVERSION));

        return options;
    }

    public void checkHidden() {

        if (!bFirstClickOnAgreement) {

            ApexPages.getMessages().clear();

            if (agreementWrapperList.size() >= 1) {
                agreementWrapperList[0].selected = true;
            }

            if (!agreementWrapperList.isEmpty()) {
                bShowAgreements = true;
                bShowCreate = true;
            } else {
                //v102  ++ << Hiding agreement section
                if (APTS_OrderConstants.DE_INSTALLATION.equalsIgnoreCase(oOrder.APTS_Order_Sub_Type__c)) {
                    bShowCreate = true;
                }
                //v102 ++ >>
                 //v107  ++ <<
               else if(isEndPast){
                 ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, APTS_OrderConstants.Past_EndDate));

                 bShowCreate = false;
                }
                //v107  ++ >>
                else {
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, APTS_OrderConstants.NO_AGREEMENT));
                    bShowAgreements = false;
                    bShowCreate = false;
                }
            }
        }
        //v102  ++ << Hiding agreement section
        bShowAgreements = APTS_OrderConstants.DE_INSTALLATION.equalsIgnoreCase(oOrder.APTS_Order_Sub_Type__c) ? false : bShowAgreements;
        //v102 ++ >>
    }

    public void filterAgreements() {
        
        //v102  ++ << Hiding agreement section
        bShowAgreements = APTS_OrderConstants.DE_INSTALLATION.equalsIgnoreCase(oOrder.APTS_Order_Sub_Type__c) ? false : true;
        //v102 ++ >>
        if (bShowAgreements && !bFirstClickOnAgreement) {

            agreementWrapperList.clear();
            agreementWrapperList.addAll(agreementWrapperTmpList);
            Set<Id> allAgreementIdTmpSet = new Set<Id>();
            allAgreementIdTmpSet.addAll(allAgreementIdSet);
            bTechSwap = false;

            if (oOrder.APTS_Order_Sub_Type__c == APTS_OrderConstants.CONVERSION) {
                //Show only amended agreements
                if (!amendedAgreementIdSet.isEmpty()) {
                    allAgreementIdTmpSet.removeAll(amendedAgreementIdSet);
                }

                filterRecords(allAgreementIdTmpSet);
            } else if (oOrder.APTS_Order_Sub_Type__c == APTS_OrderConstants.EXTERNAL_MOVEMENT_WITH_CONTRACT_CHANGE) {
                //Show only cancelled
                if (!cancelledAgreementIdSet.isEmpty()) {
                    allAgreementIdTmpSet.removeAll(cancelledAgreementIdSet);
                }

                filterRecords(allAgreementIdTmpSet);
            } else if (oOrder.APTS_Order_Sub_Type__c == APTS_OrderConstants.INTERNAL_MOVEMENT || oOrder.APTS_Order_Sub_Type__c == APTS_OrderConstants.EXTERNAL_MOVEMENT_WITHOUT_CONTRACT_CHANGE) {
                //For movement orders remove only fully canceled agreements
                filterRecords(fullyCancelledAgreementIdSet);
            }
            //v102 ++ << Removed deinstall condition for filtering cancelled agreement line item -- commenting
            /*else if (oOrder.APTS_Order_Sub_Type__c == APTS_OrderConstants.DE_INSTALLATION) {
                //Show only cancelled
                if (!cancelledAgreementIdSet.isEmpty()) {
                    allAgreementIdTmpSet.removeAll(cancelledAgreementIdSet);
                }

                filterRecords(allAgreementIdTmpSet);
            }*/ //v102 ++ >>
            else {
                //For all other types remove expired
                filterRecords(expiredAgreementIdSet);
            }

            if (APTS_OrderConstants.TECHNICAL_SWAP.equalsIgnoreCase(oOrder.APTS_Order_Sub_Type__c)) {
                bTechSwap = true;
            }
        }
    }

    public void filterRecords(Set<Id> recordsToRemoveSet) {

        if (!recordsToRemoveSet.isEmpty()) {

            for (Integer iIndex = 0; iIndex < agreementWrapperList.size(); iIndex++) {

                AgreementWrapper oAgreementWrapper = agreementWrapperList.get(iIndex);

                if (recordsToRemoveSet.contains(oAgreementWrapper.oAgreement.Id)) {
                    agreementWrapperList.remove(iIndex);
                    iIndex--;
                }
            }
        }
    }

    public PageReference createOrder() {

        //try{
        if (validate()) {
            PageReference pageRef;

            Apttus__APTS_Agreement__c oSelectedAgreement;
            
           //v102 ++ <<  agreement selection if order is not deinstallation order
            if (oOrder.APTS_Order_Sub_Type__c != APTS_OrderConstants.DE_INSTALLATION) {
                for (AgreementWrapper oAgreementWrapper : agreementWrapperList) {
                    if (oAgreementWrapper.selected) {
                        oSelectedAgreement = oAgreementWrapper.oAgreement;
                    }
                }
            }
            //v102 ++ >>
            
            if (oSelectedAgreement != null) {
                APTS_OrderUtils.setOrderHeader(oOrder, oSelectedAgreement, initialAccount);
            }
            //v102 ++ << Calling method without Agreement
            else {
                APTS_OrderUtils.setOrderHeader(oOrder, initialAccount);
            }
            //v102 ++ >>
            //If Order from Account than get location from Account
            if (locId == null) {
                locId = APTS_OrderUtils.getAccountLocationId(initialAccount);                  
            } 
            oOrder.Apttus_Config2__LocationId__c = locId;

            if (initialAccount.Billing_header_text__c != null && initialAccount.Billing_header_text__c.length() > 255) {
                oOrder.APTS_Invoice_Remark__c = initialAccount.Billing_header_text__c.left(255);
            } else {
                oOrder.APTS_Invoice_Remark__c = initialAccount.Billing_header_text__c;
            }

            if (oOrder.APTS_Order_Sub_Type__c == APTS_OrderConstants.TECHNICAL_SWAP) {
                //Technical swap section
                oOrder.Apttus_Config2__Source__c = APTS_OrderConstants.ACCOUNT;
                oOrder.APTS_Requested_Delivery_Date__c = deInstallDate;
                oOrder.APTS_Requested_Installation_Date__c = deInstallDate;
                oOrder.APTS_Requested_De_Installation_Date__c = (DateTime) deInstallDate;
                oOrder.APTS_SAP_OrderType__c = APTS_OrderConstants.XA13;

                Database.insert(oOrder);

                //create deinstall order
                Apttus_Config2__Order__c oDeInstallOrder = oOrder.clone(false, false, false, false);
                oDeInstallOrder.APTS_SAP_OrderType__c = oOrder.APTS_SAP_OrderType__c = APTS_OrderConstants.XB13;
                oDeInstallOrder.Apttus_Config2__ParentOrderId__c = oOrder.Id;

                Database.insert(oDeInstallOrder);

                APTS_OrderUtils.createCart(oDeInstallOrder.Id);

                pageRef = new PageReference('/apex/Apttus_Config2__OrderConfiguration?flow=NGMachineSwapOrder&launchState=assets&id=' + oOrder.Id);

            } else if (oOrder.APTS_Order_Sub_Type__c == APTS_OrderConstants.COMMERCIAL_SWAP) {
                //DE_INSTALLATION
                oOrder.Apttus_Config2__Source__c = APTS_OrderConstants.ACCOUNT;
                oOrder.APTS_SAP_OrderType__c = APTS_OrderConstants.XB13;
                oOrder.APTS_Requested_Installation_Date__c = null;

                Database.insert(oOrder);

                pageRef = new PageReference('/apex/APTS_DeInstallOrder');
                pageRef.getParameters().put(APTS_OrderConstants.ID, oOrder.Id);

            } 
            //v102 ++ << Added condition for deinstall by removing old one
            else if (oOrder.APTS_Order_Sub_Type__c == APTS_OrderConstants.DE_INSTALLATION) {
                oOrder.Apttus_Config2__Source__c = APTS_OrderConstants.ACCOUNT;
                //v108++<<
                if(isTrial){
                oOrder.APTS_SAP_OrderType__c = APTS_OrderConstants.XB23;
                }
                //v108++>>
                else{
                oOrder.APTS_SAP_OrderType__c = APTS_OrderConstants.XB13;
                }
                oOrder.APTS_Requested_Installation_Date__c = null;
                oOrder.APTS_Requested_De_Installation_Date__c = DateTime.newInstance(deInstallDate.year(), deInstallDate.month(), deInstallDate.day());
                oOrder.APTS_Requested_Delivery_Date__c = APTS_OrderUtils.checkRequestedDeliveryDateInWorkingHours(oOrder, deInstallDate);
                
                APTS_DefaultPriceList oDefaultPriceList = new APTS_DefaultPriceList();
                oOrder.Apttus_Config2__PriceListId__c = oDefaultPriceList.getDefaultPriceListId(initialAccount);
               
                
                Database.insert(oOrder);
                pageRef = new ApexPages.StandardController(oOrder).view();
                
            } //v102 ++ >>
            else if (oOrder.APTS_Order_Sub_Type__c == APTS_OrderConstants.INTERNAL_MOVEMENT) {
                //INTERNAL_MOVEMENT
                oOrder.Apttus_Config2__Source__c = APTS_OrderConstants.ACCOUNT;
                oOrder.APTS_SAP_OrderType__c = APTS_OrderConstants.XA14;

                Database.insert(oOrder);

                pageRef = new PageReference('/apex/APTS_InternalMovementOrder');
                pageRef.getParameters().put(APTS_OrderConstants.AID, initialAccount.Id);
                pageRef.getParameters().put(APTS_OrderConstants.ID, oOrder.Id);

            } else if (oOrder.APTS_Order_Sub_Type__c == APTS_OrderConstants.EXTERNAL_MOVEMENT_WITH_CONTRACT_CHANGE || oOrder.APTS_Order_Sub_Type__c == APTS_OrderConstants.EXTERNAL_MOVEMENT_WITHOUT_CONTRACT_CHANGE) {
                //External Movement
                oOrder.Apttus_Config2__Source__c = APTS_OrderConstants.ACCOUNT;
                oOrder.APTS_SAP_OrderType__c = APTS_OrderConstants.XA14;

                Database.insert(oOrder);

                if (oOrder.APTS_Order_Sub_Type__c == APTS_OrderConstants.EXTERNAL_MOVEMENT_WITH_CONTRACT_CHANGE) {
                    //with contract change
                    pageRef = new PageReference('/apex/APTS_ExternalMovementOrderWCC');
                } else {
                    //without contract change
                    pageRef = new PageReference('/apex/APTS_ExternalMovementOrderWOCC');
                }

                pageRef.getParameters().put(APTS_OrderConstants.AID, initialAccount.Id);
                pageRef.getParameters().put(APTS_OrderConstants.ID, oOrder.Id);

            } else if (oOrder.APTS_Order_Sub_Type__c == APTS_OrderConstants.CONVERSION) {
                //Conversion order
                oOrder.Apttus_Config2__Source__c = APTS_OrderConstants.ACCOUNT;
                oOrder.APTS_SAP_OrderType__c = APTS_OrderConstants.XA13;

                Database.insert(oOrder);
                pageRef = new ApexPages.StandardController(oOrder).view();

            } else {
                //Create install machine order
                oOrder.Apttus_Config2__Source__c = APTS_OrderConstants.ACCOUNT;

                if (oSelectedAgreement != null) {
                    oOrder = APTS_OrderUtils.setOrderHeader(oOrder, oSelectedAgreement, initialAccount);
                } else {
                    oOrder = APTS_OrderUtils.setOrderHeader(oOrder, initialAccount);
                    APTS_DefaultPriceList oDefaultPriceList = new APTS_DefaultPriceList();
                    oOrder.Apttus_Config2__PriceListId__c = oDefaultPriceList.getDefaultPriceListId(initialAccount);
                }
                //v108++<<
                if(isTrial){
                    oOrder.APTS_SAP_OrderType__c = APTS_OrderConstants.XA23;
                    }
                    else{
                    oOrder.APTS_SAP_OrderType__c = APTS_OrderConstants.XA13;
                    }
                    //v108++>>
                Database.insert(oOrder);
                pageRef = new ApexPages.StandardController(oOrder).view();

            }
            //} catch (Exception e) {
            //    APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id), 'OM', false, true, APTS_OrderConstants.EMAIL, true);
            //}
            return pageRef;
        } else {
            return null;
        }
    }

    private Boolean validate() {

        Boolean bResult = true;
        //v102 ++ << below code will run only if agreements are visible
        //if user click on create order before clicking on agreement section
        if (bShowAgreements) {
            //if user click on create order before clicking on agreement section
            if (bFirstClickOnAgreement) {

                loadAgreements();
                if (agreementWrapperList.isEmpty()) {
                    bResult = false;
                }
            }
            //v102 ++ >>
        

            Integer iSelectedCount = 0;

            for (AgreementWrapper oAgreementWrapper : agreementWrapperList) {
                if (oAgreementWrapper.selected) {
                    iSelectedCount++;
                }
            }

            if (iSelectedCount > 1) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, APTS_OrderConstants.ONE_AGREEMENT));
                bResult = false;
            }
            if (iSelectedCount == 0) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, APTS_OrderConstants.SELECT_AN_AGREEMENT));
                bResult = false;
            }
            if (APTS_OrderConstants.TECHNICAL_SWAP.equalsIgnoreCase(oOrder.APTS_Order_Sub_Type__c)) {
                if (deInstallDate != null) {
                    DateTime myDateTime = (DateTime) deInstallDate;
                    String dayOfWeek = myDateTime.format('E');

                    if (!APTS_OrderConstants.MONDAY.equalsIgnoreCase(dayOfWeek)) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, APTS_OrderConstants.REQUEST_INSTALLATION_DATE_ON_MONDAY));
                        bResult = false;
                    }
                } else {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, APTS_OrderConstants.REQUESTED_DATE_NOT_BLANK));
                    bResult = false;
                }
            }
        }
        //} catch (Exception e) {
        //    APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id), 'OM', false, true, APTS_OrderConstants.EMAIL, true);
        //}
        return bResult;
    }

    public PageReference back() {

        PageReference pageRef;
        pageRef = new PageReference('/' + accountId);
        return pageRef;
    }

    public with sharing class AgreementWrapper {

        public Boolean selected {get; set;}
        public Apttus__APTS_Agreement__c oAgreement {get; set;}
        public String sAgreementRecordType {get; set;}

        public AgreementWrapper(Boolean selected, Apttus__APTS_Agreement__c oAgreement) {

            this.selected = selected;
            this.oAgreement = oAgreement;
            this.sAgreementRecordType = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosById().get(oAgreement.RecordTypeId).getname();
        }
    }
}