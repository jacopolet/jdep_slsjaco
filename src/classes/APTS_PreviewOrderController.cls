/*************************************************************
@Name: APTS_PreviewOrderController
@Author: Galin Georgiev
@CreateDate: 04-01-2018
@Description: Order web service utils - Integration with SAP
@UsedBy:
******************************************************************/
//v100 16-03-2018 Galin Georgiev: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes

public without sharing class APTS_PreviewOrderController {

    private static final String ID = APTS_OrderConstants.ID;
    private static final String RETID = 'retId';
    private static final String FLOW = APTS_OrderConstants.Flow;
    private static final String NGSTANDARD_ORDER = APTS_OrderConstants.NGSTANDARD_ORDER;
    private static final String NGMACHINE_ORDER = APTS_OrderConstants.NG_MACHINEORDER;
    private static final String CARTPAGEURL = APTS_OrderConstants.CARTPAGEURL;
    private static final String EMAIL = APTS_OrderConstants.APTS_EMAIL;

    private Id cartId;
    private Id orderId;
    private String sFlow;

    public APTS_SAPWSFunctions.BAPI_SALESORDER_SIMULATE_Response_elementFuture responseFuture;
    public APTS_SAPXMLRequestWrapper oSAPXMLRequestWrapper;
    public List<Apttus_Config2__TaxBreakup__c> taxBreakupsToDeteList;

    public String sResult {get; set;}

    public APTS_PreviewOrderController() {

        cartId = ApexPages.currentPage().getParameters().get(ID);
        orderId = ApexPages.currentPage().getParameters().get(RETID);
        sFlow = ApexPages.currentPage().getParameters().get(FLOW);
    }

    public PageReference previewOrder() {

        PageReference pageRef;

        pageRef = doATPCheck();

        return pageRef;
    }

    public PageReference doATPCheck() {

        List<Apttus_Config2__LineItem__c> lineItemList = [
                    SELECT APTS_Expected_Delivery_Date__c, APTS_Expected_Delivery_Quantity__c, APTS_ATP_Cleared__c,
                    APTS_Plant_Code__c, Apttus_Config2__Quantity__c, Apttus_Config2__PricingStatus__c,
                    APTS_Requested_Delivery_Date__c
                    FROM Apttus_Config2__LineItem__c
                    WHERE Apttus_Config2__ConfigurationId__c = :cartId];

        Set<Id> lineItemIdSet = new Set<Id>();

        for (Apttus_Config2__LineItem__c oLineItem : lineItemList) {
            lineItemIdSet.add(oLineItem.Id);
        }

        List<Apttus_Config2__TaxBreakup__c> taxBreakupsToDeteList = [
                    SELECT Id
                    FROM Apttus_Config2__TaxBreakup__c
                    WHERE Apttus_Config2__LineItemId__c IN :lineItemIdSet];

        APTS_ATPResultWrapper oATPResultWrapper = new APTS_ATPResultWrapper();

        try {
            oATPResultWrapper = APTS_OrderWSUtils.doATPCheck(orderId, cartId);
        } catch (exception e) {
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getMessage() , 'Order', null, 'OM', false, true, null, true);
        }

        List<Apttus_Config2__LineItem__c> lineItemsToUpdateList = oATPResultWrapper.lineItemsToUpdateList;
        List<Apttus_Config2__TaxBreakup__c> taxBreakupsToInsertList = oATPResultWrapper.taxBreakupsToInsertList;
        List<APTS_Order_Freight_Data__c> freightDataToInsertList = oATPResultWrapper.freightDataToInsertList;

        if (!lineItemsToUpdateList.isEmpty()) {
            Database.update(lineItemsToUpdateList);
        }

        if (!taxBreakupsToDeteList.isEmpty()) {
            Database.delete(taxBreakupsToDeteList);
        }

        if (!taxBreakupsToInsertList.isEmpty()) {
            Database.insert(taxBreakupsToInsertList);
        }

        if (!freightDataToInsertList.isEmpty()) {
            Database.insert(freightDataToInsertList);
        }

        return goToCart();
    }

    public Continuation doAsyncATPCheck() {

        List<Apttus_Config2__LineItem__c> lineItemList = [
                    SELECT APTS_Expected_Delivery_Date__c, APTS_Expected_Delivery_Quantity__c, APTS_ATP_Cleared__c,
                    APTS_Plant_Code__c, Apttus_Config2__Quantity__c, Apttus_Config2__PricingStatus__c,
                    APTS_Requested_Delivery_Date__c
                    FROM Apttus_Config2__LineItem__c
                    WHERE Apttus_Config2__ConfigurationId__c = :cartId];

        Set<Id> lineItemIdSet = new Set<Id>();

        for (Apttus_Config2__LineItem__c oLineItem : lineItemList) {
            lineItemIdSet.add(oLineItem.Id);
        }

        taxBreakupsToDeteList = [
                                    SELECT Id
                                    FROM Apttus_Config2__TaxBreakup__c
                                    WHERE Apttus_Config2__LineItemId__c IN :lineItemIdSet];

        oSAPXMLRequestWrapper = APTS_OrderWSUtils.prepareXMLRequest(orderId, cartId);

        Integer TIMEOUT_INT_SECS = Integer.valueOf(APTS_SAP_Connection_Settings__c.getValues('ATP Check').APTS_Timeout__c * 1000);
        Continuation oContinuation = new Continuation(TIMEOUT_INT_SECS);
        oContinuation.continuationMethod = 'processResponse';

        APTS_SAPWSFunctions.AsyncHTTPS_Port oSAPWSFunctions = new APTS_SAPWSFunctions.AsyncHTTPS_Port();

        oSAPWSFunctions.endpoint_x = APTS_SAP_Connection_Settings__c.getValues('ATP Check').APTS_Endpoint__c;
        oSAPWSFunctions.clientCertName_x = APTS_SAP_Connection_Settings__c.getValues('ATP Check').APTS_Certificate_Name__c;
        oSAPWSFunctions.timeout_x = Integer.valueOf(APTS_SAP_Connection_Settings__c.getValues('ATP Check').APTS_Timeout__c * 1000);

        responseFuture = oSAPWSFunctions.doAsyncATPSimulation(
                             oContinuation, null, oSAPXMLRequestWrapper.ORDER_HEADER_IN,
                             null, null, null,
                             null, null, null,
                             null, null, null,
                             null, null, oSAPXMLRequestWrapper.ORDER_ITEMS_IN,
                             null, oSAPXMLRequestWrapper.ORDER_PARTNERS, null,
                             null, null);

        return oContinuation;
    }

    public Object processResponse() {

        APTS_SAPWSStructure.BAPI_SALESORDER_SIMULATE_Response_element response = responseFuture.getValue();
        APTS_ATPResultWrapper oATPResultWrapper = new APTS_ATPResultWrapper();
        oATPResultWrapper = APTS_OrderWSUtils.setAsyncATPCheckResults(response, oSAPXMLRequestWrapper.itemNumberToOrderLineItemMap);

        List<Apttus_Config2__LineItem__c> lineItemsToUpdateList = oATPResultWrapper.lineItemsToUpdateList;
        List<Apttus_Config2__TaxBreakup__c> taxBreakupsToInsertList = oATPResultWrapper.taxBreakupsToInsertList;
        List<APTS_Order_Freight_Data__c> freightDataToInsertList = oATPResultWrapper.freightDataToInsertList;

        if (!lineItemsToUpdateList.isEmpty()) {
            Database.update(lineItemsToUpdateList);
        }

        if (!taxBreakupsToDeteList.isEmpty()) {
            Database.delete(taxBreakupsToDeteList);
        }

        if (!taxBreakupsToInsertList.isEmpty()) {
            Database.insert(taxBreakupsToInsertList);
        }

        if (!freightDataToInsertList.isEmpty()) {
            Database.insert(freightDataToInsertList);
        }

        return goToCart();
    }

    public PageReference goToCart() {

        PageReference pageRef;

        Map<String, String> parameterMap = ApexPages.currentPage().getParameters();
        Id tempObjectId = parameterMap.get('configRequestId');

        List<String> filterList = new String[] {tempObjectId, cartId, sFlow};

        pageRef = new PageReference(String.format(CARTPAGEURL, filterList));

        return pageRef;
    }
}