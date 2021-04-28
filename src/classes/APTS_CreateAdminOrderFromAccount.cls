/*************************************************************
@Name: APTS_CreateAdminOrderFromAccount
@Author: V. Shankaranarayanan
@CreateDate: 28-05-2018
@Description: Create Admin Order from Account
@UsedBy: Create Admin Order button on Account page
******************************************************************/
public with sharing class APTS_CreateAdminOrderFromAccount {

    private final Apttus__APTS_Agreement__c oAgreement;
    private Id accountId;
    private String sType;
    private Account initialAccount;
    private static final String CONVERSION = System.Label.APTS_ConversionOrder;
    private static final String INSTALLATION = System.Label.APTS_Installation;
    private static final String DE_INSTALLATION = System.Label.APTS_De_installation;
    private static final String INTERNAL_MOVEMENT = System.Label.APTS_Internal_Movement;
    private static final String ADMIN = System.Label.APTS_AdminOrder;
    private static final String ID = System.Label.APTS_Id;
    private static final String TYPE = System.Label.APTS_Type;
    private static final String IN_EFFECT = System.Label.APTS_In_Effect;
    private static final String ACTIVATED = System.Label.APTS_Activated;
    private static final String RENEWAL = 'Renewal';
    private static final String AGREEMENT_CHANGES = 'Agreement Changes';
    private static final String EXTERNAL_MOVEMENT_WITH_CONTRACT_CHANGE = 'External Movement With Contract Change';
    private static final String EXTERNAL_MOVEMENT_WITHOUT_CONTRACT_CHANGE = 'External Movement Without Contract Change';
    private static final String ACCOUNT = System.Label.APTS_Account;
    //private static final String XA13 = System.Label.APTS_XA13;

    public Apttus_Config2__Order__c oOrder {get; set;}
    public List<AgreementWrapper> agreementWrapperList {get; set;}
    public List<AgreementWrapper> agreementWrapperTmpList {get; set;}
    public Boolean bShowAgreements {get; set;}
    public Boolean bShowCreate {get; set;}
    public Map<Id, Apttus__APTS_Agreement__c> agrmntMap;
    public Map<String, Set<ID>> amendagr;
    Set<Id> amendSet;
    Set<Id> agreementSet;

    public APTS_CreateAdminOrderFromAccount() {

        accountId = ApexPages.currentPage().getParameters().get(ID);
        sType = ApexPages.currentPage().getParameters().get(TYPE);
        bShowAgreements = false;
        bShowCreate = true;

        initialAccount = [SELECT Id, Ultimate_Parent_Account__c, APTS_Account_Level__c,
                          Language__c, Apttus_Config2__BillingPreferenceId__c, Apttus_Config2__PaymentTermId__c,
                          Bill_To_Payer_Account__c, Related_Payer_Account__c,
                          /*Related_Bill_to_Machines_Services__c,*/ Related_Payer_Machines_Services__c,
                          Sales_Organization__c, Division__c, Distribution_Channel__c, Partner__c
                          FROM Account
                          WHERE Id = :accountId];

        oOrder = new Apttus_Config2__Order__c();
        oOrder = APTS_OrderUtils.setOrderHeaderMandatoryFields(oOrder, sType);

        agreementWrapperList = new List<AgreementWrapper>();
        agreementWrapperTmpList = new List<AgreementWrapper>();
        agrmntMap = new Map<Id, Apttus__APTS_Agreement__c>([SELECT Id, Name, RecordTypeId, Apttus_CMConfig__PriceListId__c, Apttus_CMConfig__PONumber__c,
                Apttus_CMConfig__BillingPreferenceId__c, Apttus_CMConfig__PaymentTermId__c, Apttus__Status_Category__c,
                Apttus__Status__c, Apttus__Contract_Start_Date__c, Apttus__Contract_End_Date__c,
                Apttus__Account__r.APTS_Account_Level__c, Apttus__Account__r.Name, Apttus__Primary_Contact__c,
                APTS_Language__c, APTS_Bill_to_Party_Ingredients__c, APTS_Payer_Ingredients__c, APTS_Bill_to_Party_MachServ__c,
                APTS_Payer_Machines_Services__c, Apttus__Account__c, Apttus__Version_Number__c,
                APTS_Check_on_Account_Machines__c,APTS_Check_on_Account_Ingredients__c
                FROM Apttus__APTS_Agreement__c
                WHERE Apttus__Account__c = : accountId AND Apttus__Status_Category__c = : IN_EFFECT AND Apttus__Status__c = : ACTIVATED]);

        amendagr = new Map<String, Set<ID>>();

        amendSet = new Set<ID>();
        agreementSet = new Set<ID>();

        for (Apttus__APTS_Agreement__c parseAg : agrmntMap.values()) {
            if (parseAg.Apttus__Version_Number__c > 0) {
                amendSet.add(parseAg.Id);
            }
            //agreementSet.add(parseAg.Id)
        }
        if (!agrmntMap.isEmpty()) {
            bShowAgreements = true;
        }
        /*for(Apttus__APTS_Agreement__c aggr : agrmntMap.values()){
            AgreementWrapper oAgreementWrapper = new AgreementWrapper(false, aggr);
            agreementWrapperList.add(oAgreementWrapper);
        }*/
        queryAgreements(agrmntMap.keySet());
        agreementWrapperTmpList.addAll(agreementWrapperList);
    }

    public List<SelectOption> getOrderSubTypePicklist() {
        List<SelectOption> options = new List<SelectOption>();
        if (sType.equals(ADMIN)) {
            options.add(new SelectOption(INSTALLATION, INSTALLATION));
            options.add(new SelectOption(DE_INSTALLATION, DE_INSTALLATION));
            options.add(new SelectOption(CONVERSION, CONVERSION));
            options.add(new SelectOption(INTERNAL_MOVEMENT, INTERNAL_MOVEMENT));
            options.add(new SelectOption(EXTERNAL_MOVEMENT_WITH_CONTRACT_CHANGE, EXTERNAL_MOVEMENT_WITH_CONTRACT_CHANGE));
            options.add(new SelectOption(EXTERNAL_MOVEMENT_WITHOUT_CONTRACT_CHANGE, EXTERNAL_MOVEMENT_WITHOUT_CONTRACT_CHANGE));
            options.add(new SelectOption(RENEWAL, RENEWAL));
            options.add(new SelectOption(AGREEMENT_CHANGES, AGREEMENT_CHANGES));
        }
        return options;
    }

    public PageReference createOrder() {

        try {
            PageReference pageRef;
            if (oOrder.APTS_Order_Sub_Type__c != null) {
                oOrder.Apttus_Config2__Source__c = ACCOUNT;
                //oOrder.APTS_SAP_OrderType__c = XA13;
                Apttus__APTS_Agreement__c oSelectedAgreement;
                for (AgreementWrapper oAgreementWrapper : agreementWrapperList) {
                    if (oAgreementWrapper.selected) {
                        oSelectedAgreement = oAgreementWrapper.oAgreement;
                    }
                }
                APTS_OrderUtils.setOrderHeader(oOrder, oSelectedAgreement, initialAccount);
                Database.insert(oOrder);
                pageRef = new ApexPages.StandardController(oOrder).view();
                return pageRef;
            } else {
                return null;
            }
        }catch (Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getMessage() , 'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id), 'CLM', false, false, null, true);return null;}
    }

    public void setOrderSubType() {
       
        if(String.IsNotBlank(oOrder.APTS_Order_Sub_Type__c)){
            if (oOrder.APTS_Order_Sub_Type__c.equals(INSTALLATION) || oOrder.APTS_Order_Sub_Type__c.equals(DE_INSTALLATION) || oOrder.APTS_Order_Sub_Type__c.equals(INTERNAL_MOVEMENT)) {
                queryAgreements(agrmntMap.keySet());
            } else if (oOrder.APTS_Order_Sub_Type__c.equals(CONVERSION) || oOrder.APTS_Order_Sub_Type__c.equals(RENEWAL) || oOrder.APTS_Order_Sub_Type__c.equals(AGREEMENT_CHANGES) || oOrder.APTS_Order_Sub_Type__c.equals(EXTERNAL_MOVEMENT_WITHOUT_CONTRACT_CHANGE) || oOrder.APTS_Order_Sub_Type__c.equals(EXTERNAL_MOVEMENT_WITH_CONTRACT_CHANGE)) {
                queryAgreements(amendSet);
            }
        }
    }

    public void queryAgreements(Set<ID> agreementIds) {
        agreementWrapperList.clear();
        List<AgreementWrapper> agLst = new List<AgreementWrapper>();
        for (ID newId : agreementIds) {
            agLst.add(new AgreementWrapper(false, agrmntMap.get(newId)));
        }
        agreementWrapperList.addAll(agLst);
    }

    public PageReference back() {
        return new PageReference('/' + accountId);
    }

    public PageReference proceedNext() {
        return new PageReference('/apex/APTS_LegalEntityChange?id=' + accountId + '&subType=' + oOrder.APTS_Order_Sub_Type__c);
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