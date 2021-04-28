/*************************************************************
@Name: APTS_ConversionOrderController
@Author: Galin Georgiev
@CreateDate: 23-04-2018
@Description: Create Conversion Order
@UsedBy: APTS_CreateOrderController
******************************************************************/
//v100 23-04-2018 Galin Georgiev: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes
//Added Custom logging --> Sethukkarasi

public with sharing class APTS_ConversionOrderController {

    private static final String CARTPAGEURL = System.Label.APTS_Cart_Page_Url;
    private static final String ID = System.Label.APTS_Id;
    private static final String FLOW = System.Label.APTS_Flow;
    private static final String OPTION = System.Label.APTS_Option;
    private static final String PRODUCT_MANDATORY = System.Label.APTS_Product_Mandatory;
    private static final String TEMPORARY_DEACTIVATED = 'Temporary Deactivated';

    private Id cartId;
    private Id orderId;
    private Id agreementId;
    private String sFlow;
    private Apttus_Config2__ProductConfiguration__c oProductConfiguration;
    private Map<Id, Apttus_Config2__LineItem__c> idToLineItemMap;
    private Map<String, Id> productIdAndLineNumberAndChargeTypeToLIIdMap;
    private static final String EMAIL = System.Label.APTS_Email;

    public List<AgreementWrapper> agreementWrapperList {get; set;}

    public APTS_ConversionOrderController() {

        cartId = ApexPages.currentPage().getParameters().get(ID);
        sFlow = ApexPages.currentPage().getParameters().get(FLOW);

        List<Apttus_Config2__ProductConfiguration__c> productConfigurationList = [
                    SELECT Id, Apttus_Config2__OrderId__c
                    FROM Apttus_Config2__ProductConfiguration__c
                    WHERE Id = :cartId];

        oProductConfiguration = productConfigurationList.get(0);
        orderId = oProductConfiguration.Apttus_Config2__OrderId__c;

        List<Apttus_Config2__Order__c> orderList = [
                    SELECT Id, Apttus_CMConfig__AgreementId__c
                    FROM Apttus_Config2__Order__c
                    WHERE Id = :orderId];

        Apttus_Config2__Order__c oOrder = orderList.get(0);
        agreementId = oOrder.Apttus_CMConfig__AgreementId__c;

        Map<Id, Apttus__APTS_Agreement__c> idToAgreementMap = new Map<Id, Apttus__APTS_Agreement__c>([
                    SELECT Id, Name, RecordTypeId,
                    Apttus__Contract_Start_Date__c, Apttus__FF_Agreement_Number__c
                    FROM Apttus__APTS_Agreement__c
                    WHERE Id = :agreementId]);

        Map<Id, Apttus__AgreementLineItem__c> idToAgreementLineItemMap = new Map<Id, Apttus__AgreementLineItem__c>([
                    SELECT Id, Apttus__AgreementId__c, Apttus__ProductId__r.Name, Apttus_CMConfig__LineStatus__c,
                    Apttus_CMConfig__AssetLineItemId__r.Apttus_Config2__Quantity__c, Apttus__Quantity__c, Apttus__NetPrice__c,
                    Apttus_CMConfig__HasOptions__c, Apttus_CMConfig__IsPrimaryLine__c, Apttus_CMConfig__LineType__c,
                    Apttus_CMConfig__LineNumber__c, Apttus_CMConfig__OptionId__r.Name, Apttus_CMConfig__DerivedFromId__c,
                    Apttus_CMConfig__AssetLineItemId__c, Apttus__ProductId__c, Apttus_CMConfig__OptionId__c,
                    Apttus_CMConfig__ChargeType__c
                    FROM Apttus__AgreementLineItem__c
                    WHERE Apttus__AgreementId__c IN :idToAgreementMap.keySet() AND Apttus_CMConfig__AssetLineItemId__r.APTS_Sub_Status__c <> :TEMPORARY_DEACTIVATED]);

        agreementWrapperList = new List<AgreementWrapper>();            
        productIdAndLineNumberAndChargeTypeToLIIdMap = new Map<String, Id>();

        Map<Id, List<Apttus__AgreementLineItem__c>> agreementIdToAgreementLineItemListMap = new Map<Id, List<Apttus__AgreementLineItem__c>>();

       //try{
        for (Apttus__AgreementLineItem__c oAgreementLineItem : idToAgreementLineItemMap.values()) {

            List<Apttus__AgreementLineItem__c> agreementLineItemList = agreementIdToAgreementLineItemListMap.get(oAgreementLineItem.Apttus__AgreementId__c);

            if (agreementLineItemList == null) {
                agreementLineItemList = new List<Apttus__AgreementLineItem__c>();
                agreementIdToAgreementLineItemListMap.put(oAgreementLineItem.Apttus__AgreementId__c, agreementLineItemList);
            }

            agreementLineItemList.add(oAgreementLineItem);

            if (!oAgreementLineItem.Apttus_CMConfig__IsPrimaryLine__c) {

                String sProductIdAndLNAndChargeType;

                if (oAgreementLineItem.Apttus_CMConfig__HasOptions__c) {
                    sProductIdAndLNAndChargeType = oAgreementLineItem.Apttus__ProductId__c + String.valueOf(oAgreementLineItem.Apttus_CMConfig__LineNumber__c) + oAgreementLineItem.Apttus_CMConfig__ChargeType__c;
                } else {
                    sProductIdAndLNAndChargeType = oAgreementLineItem.Apttus_CMConfig__OptionId__c + String.valueOf(oAgreementLineItem.Apttus_CMConfig__LineNumber__c) + oAgreementLineItem.Apttus_CMConfig__ChargeType__c;
                }

                productIdAndLineNumberAndChargeTypeToLIIdMap.put(sProductIdAndLNAndChargeType, oAgreementLineItem.Apttus_CMConfig__DerivedFromId__c);
            }
        }
          /* }
            catch(Exception e)
              {
        APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id),'OM',false,true, EMAIL, true);
              } */
              
        Map<Id, Map<Id, List<Id>>> agreementIdToBundleIdToOptionIdListMapMap = new Map<Id, Map<Id, List<Id>>>();

        //try{
        for (Id agreementId : agreementIdToAgreementLineItemListMap.keySet()) {

            List<Apttus__AgreementLineItem__c> agreementLineItemList = agreementIdToAgreementLineItemListMap.get(agreementId);

            Map<Id, List<Id>> bundleLIIdToOptionIdListMap = new Map<Id, List<Id>>();
            Map<Decimal, List<Id>> bundelLineNumberToOptionIdListMap = new Map<Decimal, List<Id>>();
            List<Id> optionIdList;

            for (Apttus__AgreementLineItem__c oAgreementLineItem : agreementLineItemList) {

                if (oAgreementLineItem.Apttus_CMConfig__LineType__c == OPTION) {

                    if (bundelLineNumberToOptionIdListMap.containsKey(oAgreementLineItem.Apttus_CMConfig__LineNumber__c)) {
                        optionIdList = bundelLineNumberToOptionIdListMap.get(oAgreementLineItem.Apttus_CMConfig__LineNumber__c);
                    } else {
                        optionIdList = new List<Id>();
                    }

                    optionIdList.add(oAgreementLineItem.Id);
                    bundelLineNumberToOptionIdListMap.put(oAgreementLineItem.Apttus_CMConfig__LineNumber__c, optionIdList);
                }
            }

            for (Apttus__AgreementLineItem__c oAgreementLineItem : agreementLineItemList) {

                if (oAgreementLineItem.Apttus_CMConfig__HasOptions__c && oAgreementLineItem.Apttus_CMConfig__IsPrimaryLine__c
                        && oAgreementLineItem.Apttus_CMConfig__LineStatus__c == 'Amended') {
                    bundleLIIdToOptionIdListMap.put(oAgreementLineItem.Id, bundelLineNumberToOptionIdListMap.get(oAgreementLineItem.Apttus_CMConfig__LineNumber__c));
                }
            }

            agreementIdToBundleIdToOptionIdListMapMap.put(agreementId, bundleLIIdToOptionIdListMap);
        }
          /* }
            catch(Exception e)
              {
        APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id),'OM',false,true, EMAIL, true);
              } */
              
       //try{
        for (Id agreementId : agreementIdToBundleIdToOptionIdListMapMap.keySet()) {

            List<APTS_AgreementLineItemWrapper> agreementLineItemWrapperList = new List<APTS_AgreementLineItemWrapper>();
            List<APTS_AgreementLineItemWrapper> agreementLineItemToDisplayWrapperList = new List<APTS_AgreementLineItemWrapper>();
            Map<Id, List<Id>> bundleIdToOptionIdListMap = agreementIdToBundleIdToOptionIdListMapMap.get(agreementId);
            
            for (Id bundleId : bundleIdToOptionIdListMap.keySet()) {

                Apttus__AgreementLineItem__c oBundleLineItem = idToAgreementLineItemMap.get(bundleId);
                List<Id> optionIdList = bundleIdToOptionIdListMap.get(bundleId);
                List<APTS_OptionLineItemWrapper> optionLineItemWrapperList = new List<APTS_OptionLineItemWrapper>();
                List<APTS_OptionLineItemWrapper> optionLineItemToDisplayWrapperList = new List<APTS_OptionLineItemWrapper>();
                for (Id optionId : optionIdList) {
                    APTS_OptionLineItemWrapper oOptionLineItemWrapper = new APTS_OptionLineItemWrapper(false, idToAgreementLineItemMap.get(optionId), 1);
                    optionLineItemWrapperList.add(oOptionLineItemWrapper);
                    if (idToAgreementLineItemMap.get(optionId).Apttus_CMConfig__LineStatus__c == 'New') {
                        optionLineItemToDisplayWrapperList.add(oOptionLineItemWrapper);
                    }
                }

                APTS_AgreementLineItemWrapper oAgreementLineItemWrapper = new APTS_AgreementLineItemWrapper(false, oBundleLineItem, optionLineItemWrapperList, optionLineItemToDisplayWrapperList, 1);
                agreementLineItemWrapperList.add(oAgreementLineItemWrapper);
            }

            Apttus__APTS_Agreement__c oAgreement = idToAgreementMap.get(agreementId);
            AgreementWrapper oAgreementWrapper = new AgreementWrapper(false, oAgreement, agreementLineItemWrapperList);
            agreementWrapperList.add(oAgreementWrapper);
        }
          /* }
            catch(Exception e)
              {
        APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id),'OM',false,true, EMAIL, true);
              } */
       
    }

    public void addSelectedToCart() {

        Set<Id> lineItemIdSet = new Set<Id>();
        Map<Decimal, Id> bundelLineNumberToLineItemIdMap = new Map<Decimal, Id>();

       //try{
        for (AgreementWrapper oAgreementWrapper : agreementWrapperList) {
            for (APTS_AgreementLineItemWrapper oAgreementLineItemWrapper : oAgreementWrapper.agreementLineItemWrapperList) {

                if (oAgreementLineItemWrapper.selected) {                                   

                    lineItemIdSet.add(oAgreementLineItemWrapper.oBundleLineItem.Apttus_CMConfig__DerivedFromId__c);                 
                    bundelLineNumberToLineItemIdMap.put(oAgreementLineItemWrapper.oBundleLineItem.Apttus_CMConfig__LineNumber__c, oAgreementLineItemWrapper.oBundleLineItem.Apttus_CMConfig__DerivedFromId__c);

                    for (APTS_OptionLineItemWrapper oOptionLineItemWrapper : oAgreementLineItemWrapper.optionLineItemWrapperList) {

                        lineItemIdSet.add(oOptionLineItemWrapper.oOptionLineItem.Apttus_CMConfig__DerivedFromId__c);
                    }                   
                }
            }
        }
          /* }
            catch(Exception e)
              {
        APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id),'OM',false,true, EMAIL, true);
              } */

        idToLineItemMap = APTS_OrderUtils.getLineItemDataAll(lineItemIdSet);

        Map<Decimal, List<Apttus_CPQApi.CPQ.SelectedOptionDO>> bundelLineNumberToOptionListMap = APTS_OrderUtils.prepareOptionsListAll(idToLineItemMap);

        //try{
        for (Decimal bundelLineNumber : bundelLineNumberToOptionListMap.keySet()) {

            Id oBundleLineItemId = bundelLineNumberToLineItemIdMap.get(bundelLineNumber);
            Apttus_Config2__LineItem__c oBundleLineItem = idToLineItemMap.get(oBundleLineItemId);
            APTS_OrderUtils.addBundleWithOptionsAll(cartId, oBundleLineItem, 1, bundelLineNumberToOptionListMap);
        }       
          /* }
            catch(Exception e)
              {
        APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id),'OM',false,true, EMAIL, true);
              } */
    }

    public PageReference backToCatalog() {

        PageReference pageRef;

        Map<String, String> parameterMap = ApexPages.currentPage().getParameters();
        Id tempObjectId = parameterMap.get('configRequestId');
        pageRef = new pagereference ('/apex/Apttus_Config2__Cart?configRequestId=' + tempObjectId + '&cartStatus=New&id=' + cartId + '&flow=' + sFlow + '#!/catalog');

        return pageRef;
    }

    public PageReference goToPricing() {

        PageReference pageRef;

        Map<String, String> parameterMap = ApexPages.currentPage().getParameters();
        Id tempObjectId = parameterMap.get('configRequestId');

        List<String> filterList = new String[] {tempObjectId, cartId, sFlow};
        String sCartPage = String.format(CARTPAGEURL, filterList);

        pageRef = new PageReference(sCartPage);

        return pageRef;
    }

    public void updateProductAttributeValues() {

        Map<Id, Apttus_Config2__LineItem__c> idToLineItemNewMap = new Map<Id, Apttus_Config2__LineItem__c>([
                    SELECT Id, Apttus_Config2__AttributeValueId__c, Apttus_Config2__DerivedFromId__c
                    FROM Apttus_Config2__LineItem__c
                    WHERE Apttus_Config2__ConfigurationId__c = :cartId]);

        List<Apttus_Config2__ProductAttributeValue__c> pavToUpdateList = APTS_OrderUtils.updateProductAttributeValues(idToLineItemNewMap, idToLineItemMap);

        if (!pavToUpdateList.isEmpty()) {
            Database.update(pavToUpdateList);
        }

        APTS_OrderUtils.repriceCart(cartId);
    }

    public void fixNonPrimaryLines() {

        Set<Id> nonPrimaryLineIdOldSet = new Set<Id>();

        List<Apttus_Config2__LineItem__c> lineItemToUpdateList = APTS_OrderUtils.fixNonPrimaryLines(cartId, productIdAndLineNumberAndChargeTypeToLIIdMap);
 //try{
 
        if (!lineItemToUpdateList.isEmpty()) {
            Database.update(lineItemToUpdateList);
        }
               
          /* }
            catch(Exception e)
              {
        APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id),'OM',false,true, EMAIL, true);
              } */
    }

    public with sharing class AgreementWrapper {

        public Boolean selected {get; set;}
        public Apttus__APTS_Agreement__c oAgreement {get; set;}
        public List<APTS_AgreementLineItemWrapper> agreementLineItemWrapperList {get; set;}
        public String sAgreementRecordType {get; set;}

        public AgreementWrapper(Boolean selected, Apttus__APTS_Agreement__c oAgreement, List<APTS_AgreementLineItemWrapper> agreementLineItemWrapperList) {

            this.selected = selected;
            this.oAgreement = oAgreement;
            this.agreementLineItemWrapperList = agreementLineItemWrapperList;
            this.sAgreementRecordType = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosById().get(oAgreement.RecordTypeId).getname();
        }
    }

    public class APTS_AgreementLineItemWrapper {

        public Boolean selected {get; set;}
        public Apttus__AgreementLineItem__c oBundleLineItem {get; set;}
        public List<APTS_OptionLineItemWrapper> optionLineItemWrapperList {get; set;}
        public List<APTS_OptionLineItemWrapper> optionLineItemWrapperToDisplayList {get; set;}
        public Integer iQuantity {get; set;}        

        public APTS_AgreementLineItemWrapper() {

            this.selected = false;
            this.oBundleLineItem = null;
            this.optionLineItemWrapperList = null;
            this.iQuantity = 0;         
        }

        public APTS_AgreementLineItemWrapper(Boolean selected, Apttus__AgreementLineItem__c oBundleLineItem, List<APTS_OptionLineItemWrapper> optionLineItemWrapperList, List<APTS_OptionLineItemWrapper> optionLineItemWrapperToDisplayList, Integer iQuantity) {

            this.selected = selected;
            this.oBundleLineItem = oBundleLineItem;
            this.optionLineItemWrapperList = optionLineItemWrapperList;
            this.optionLineItemWrapperToDisplayList = optionLineItemWrapperToDisplayList;
            this.iQuantity = iQuantity;         
        }
    }

    public class APTS_OptionLineItemWrapper {

        public Boolean selected {get; set;}
        public Apttus__AgreementLineItem__c oOptionLineItem {get; set;}
        public Integer iQuantity {get; set;}

        public APTS_OptionLineItemWrapper() {

            this.selected = false;
            this.oOptionLineItem = null;
            this.iQuantity = 0;
        }

        public APTS_OptionLineItemWrapper(Boolean selected, Apttus__AgreementLineItem__c oOptionLineItem, Integer iQuantity) {

            this.selected = selected;
            this.oOptionLineItem = oOptionLineItem;
            this.iQuantity = iQuantity;
        }
    }
}