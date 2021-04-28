/*************************************************************
@Name: APTS_OrderWSUtils
@Author: Galin Georgiev
@CreateDate: 16-03-2018 
@Description: Order web service utils - Integration with SAP
@UsedBy:
******************************************************************/
//v100 16-03-2018 Galin Georgiev: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes
// V101 22.10.2018 Aarthi Pitchai - Added logic to set the PLANT code from ATP results to Line Item
// v102 Sanjay Nair - Defect 19412 - Change in calculation of Tax/VAT
// v103 30.10.2018 Aarthi Pitchai - Added logic to set the Additional charges based on ATP results at Line Item - Defect 20406
// v104 30.11.2018 Rajesh Patel - Added logic to set the ATP Status - Defect 22049
// v105 10.12.2018 Sanjay Nair  - Added logic to send Net List Price for ATP  - Defect 22112
// v106 19.12.2018 Sanjay Nair  - VAT Check ZM04  also   - Defect 22930
// v107 12.03.2019 Sethukkarasi  - BAPI Sales Order - Defect : 5445   

/*APTS_OrderWSUtils Class Body*/
public  without sharing class APTS_OrderWSUtils  {

    private static final String ATPSIMULATIONDOCTYPE = System.Label.APTS_ATPSimulationDocType;
    private static final String EMAIL = System.Label.APTS_Email;
    private static final String ATP_CHECK = 'ATP Check';
    private static final String WEBSERVICEFAILEDMSG = 'Calling ATP check web service failed.';
    private static final String TEST = 'test';
    private static final String SAP = 'SAP_';
    private static final String E = 'E';
    private static final String SALESORGONACCOUNTEMPTY = 'Sales organization on Account is empty!';
    private static final String DISTRIBUTIONCHANNELONACCOUNTEMPTY = 'Distribution channel on Account is empty!';
    private static final String DIVISIONONACCOUNTEMPTY = 'Division on Account is empty!';
    private static final String MAXREQUESTEDDELIVERYDATEEMPTY = 'Max requested delivery date is empty!';
    private static final String YYYYMMDD = 'yyyyMMdd';
    private static final String ZEROTHREE = '03';
    private static final String AG = 'AG';
    private static final String ZEROCHAR = '0';
    private static final Integer THOUSAND = 1000;
    private static final Integer ZERO = 0;
    private static final String ZWST = 'ZWST';
      //v106++<<<
    private static final String ZM04 = 'ZM04';
     //v106 -->>>
    private static final String EIGHTYONE = '81';
    private static final String ST = 'ST';

    private static final String ZS11 = 'ZS11';
    private static final String ZS10 = 'ZS10';
    //v105 ++<<<
    private static final String ZP01 = 'ZP01';
    private static final Integer TEN = 10;
    //v105 -->>>

    public static Map<ID, Decimal> lineItemToTAXMap = new Map<ID, Decimal>();
    public static Map<ID, Decimal> lineItemToAddChargeMap = new Map<ID, Decimal>();

    /* doATPCheck Method Body */
    public static APTS_ATPResultWrapper doATPCheck(Id objectId, Id cartId) {

        APTS_SAPWSFunctions.HTTPS_Port oSAPWSFunctions = new APTS_SAPWSFunctions.HTTPS_Port();
        oSAPWSFunctions.endpoint_x = APTS_SAP_Connection_Settings__c.getValues(ATP_CHECK).APTS_Endpoint__c;
        oSAPWSFunctions.clientCertName_x = APTS_SAP_Connection_Settings__c.getValues(ATP_CHECK).APTS_Certificate_Name__c;
        oSAPWSFunctions.timeout_x = Integer.valueOf(APTS_SAP_Connection_Settings__c.getValues(ATP_CHECK).APTS_Timeout__c * 1000);

        Apttus_Config2__Order__c oOrder = new Apttus_Config2__Order__c();
        Apttus_Config2__ProductConfiguration__c oConfiguration = new Apttus_Config2__ProductConfiguration__c();
        Map<Integer, Apttus_Config2__LineItem__c> itemNumberToOrderLineItemMap = new Map<Integer, Apttus_Config2__LineItem__c>();

        oOrder = [
                     SELECT Id,
                     Apttus_Config2__SoldToAccountId__r.Sales_Organization__c,
                     Apttus_Config2__SoldToAccountId__r.Distribution_Channel__c,
                     Apttus_Config2__SoldToAccountId__r.Division__c,
                     Apttus_Config2__SoldToAccountId__r.SAP_Customer_ID__c,
                     Apttus_Config2__ShipToAccountId__r.SAP_Customer_ID__c,
                     Apttus_Config2__BillToAccountId__r.SAP_Customer_ID__c
                     FROM Apttus_Config2__Order__c
                     WHERE Id = :objectId];

        oConfiguration = [SELECT APTS_Max_Requested_Delivery_Date__c FROM Apttus_Config2__ProductConfiguration__c WHERE Id = :cartId LIMIT 1]; // Added limit as a part of Novacop voilation

        Map<Id, Apttus_Config2__LineItem__c> idToLineItemMap = new Map<Id, Apttus_Config2__LineItem__c>([
                    SELECT Id,
                    Apttus_Config2__Quantity__c,
                    Apttus_Config2__ProductId__r.ProductCode,
                    Apttus_Config2__OptionId__r.ProductCode,
                    CurrencyIsoCode,
                    Apttus_Config2__HasOptions__c,
                    Apttus_Config2__ParentBundleNumber__c,
                    Apttus_Config2__Uom__c,
                    Apttus_Config2__ListPrice__c,
                    Apttus_Config2__PriceUom__c,
                    Apttus_Config2__SellingUom__c,
                    APTS_Plant_Code__c,
                    //v102 ++<<<
                    APTS_VATO__c,
                    //v102 -->>>
                    //v103 ++ <<
                    APTS_TAXO__c,
                    APTS_Additional_chargesO__c,
                    //v103 ++ >>
                    APTS_Requested_Delivery_Date__c,
                     //v105 ++<<<
                    Apttus_Config2__NetPrice__c
                      //v105 -->>>
                    FROM Apttus_Config2__LineItem__c
                    WHERE Apttus_Config2__ConfigurationId__c = :cartId]);

        APTS_SAPWSStructure.BAPISDHEAD ORDER_HEADER_IN = new APTS_SAPWSStructure.BAPISDHEAD();
        ORDER_HEADER_IN = getOrderHeaderIn(oOrder, oConfiguration);

        APTS_SAPWSStructure.ORDER_PARTNERS_element ORDER_PARTNERS = new APTS_SAPWSStructure.ORDER_PARTNERS_element();
        ORDER_PARTNERS = getSalesPartner(oOrder);

        APTS_SAPWSStructure.ORDER_ITEMS_IN_element ORDER_ITEMS_IN = new APTS_SAPWSStructure.ORDER_ITEMS_IN_element();
        ORDER_ITEMS_IN = getOrderItemsIn(idToLineItemMap, itemNumberToOrderLineItemMap);

        APTS_SAPWSStructure.BAPI_SALESORDER_SIMULATE_Response_element response = oSAPWSFunctions.doATPSimulation(
                    null, ORDER_HEADER_IN, null,
                    null, null, null,
                    null, null, null,
                    null, null, null,
                    null, ORDER_ITEMS_IN, null,
                    ORDER_PARTNERS, null, null,
                    null);

        if (response == null) {
            throw new ResultException(WEBSERVICEFAILEDMSG);
        }
        if (response.RETURN_x != null && response.RETURN_x.TYPE_x.equals(E)) {
            throw new ResultException(response.RETURN_x.MESSAGE);
        }

        List<Apttus_Config2__LineItem__c> lineItemsToUpdateList = new List<Apttus_Config2__LineItem__c>();
        List<Apttus_Config2__TaxBreakup__c> taxBreakupsToInsertList = new List<Apttus_Config2__TaxBreakup__c>();
        List<APTS_Order_Freight_Data__c> freightDataToInsertList = new List<APTS_Order_Freight_Data__c>();

        //calculate Freight Charge
        Map<Id, Decimal> lineItemToVATMap = new Map<Id, Decimal>(); //v102++
        taxBreakupsToInsertList = getTaxBreakups(itemNumberToOrderLineItemMap, response.ORDER_CONDITION_EX);
        lineItemToVATMap = getVATCharges(itemNumberToOrderLineItemMap, response.ORDER_CONDITION_EX); //v102++

        lineItemsToUpdateList = setATPResultsOnLineItems(itemNumberToOrderLineItemMap, response.ORDER_SCHEDULE_EX, response.ORDER_ITEMS_OUT, lineItemToVATMap);
        //TO DO freightDataToInsertList = getFreightData(itemNumberToOrderLineItemMap, response.ORDER_CONDITION_EX);

        APTS_ATPResultWrapper oATPResultWrapper = new APTS_ATPResultWrapper(lineItemsToUpdateList, taxBreakupsToInsertList, freightDataToInsertList);

        return oATPResultWrapper;
    }

    /* APTS_SAPXMLRequestWrapper Method Body */
    public static APTS_SAPXMLRequestWrapper prepareXMLRequest(Id objectId, Id cartId) {

        Apttus_Config2__Order__c oOrder = new Apttus_Config2__Order__c();
        Apttus_Config2__ProductConfiguration__c oConfiguration = new Apttus_Config2__ProductConfiguration__c();
        Map<Integer, Apttus_Config2__LineItem__c> itemNumberToOrderLineItemMap = new Map<Integer, Apttus_Config2__LineItem__c>();

        oOrder = [
                     SELECT Id,
                     Apttus_Config2__SoldToAccountId__r.Sales_Organization__c,
                     Apttus_Config2__SoldToAccountId__r.Distribution_Channel__c,
                     Apttus_Config2__SoldToAccountId__r.Division__c,
                     Apttus_Config2__SoldToAccountId__r.SAP_Customer_ID__c,
                     Apttus_Config2__ShipToAccountId__r.SAP_Customer_ID__c,
                     Apttus_Config2__BillToAccountId__r.SAP_Customer_ID__c
                     FROM Apttus_Config2__Order__c
                     WHERE Id = :objectId];

        oConfiguration = [SELECT APTS_Max_Requested_Delivery_Date__c FROM Apttus_Config2__ProductConfiguration__c WHERE Id = :cartId  LIMIT 1]; // Added limit as a part of Novacop voilation

        Map<Id, Apttus_Config2__LineItem__c> idToLineItemMap = new Map<Id, Apttus_Config2__LineItem__c>([
                    SELECT Id,
                    Apttus_Config2__Quantity__c,
                    Apttus_Config2__ProductId__r.ProductCode,
                    Apttus_Config2__OptionId__r.ProductCode,
                    CurrencyIsoCode,
                    Apttus_Config2__HasOptions__c,
                    Apttus_Config2__ParentBundleNumber__c,
                    Apttus_Config2__Uom__c,
                    Apttus_Config2__ListPrice__c,
                    Apttus_Config2__PriceUom__c,
                    Apttus_Config2__SellingUom__c,
                    APTS_Plant_Code__c,
                    //v102 ++<<<
                    APTS_VATO__c,
                    //v102 -->>>
                    //v105 ++<<<
                    Apttus_Config2__NetPrice__c
                      //v105 -->>>
                    FROM Apttus_Config2__LineItem__c
                    WHERE Apttus_Config2__ConfigurationId__c = :cartId]);

        APTS_SAPWSStructure.BAPISDHEAD ORDER_HEADER_IN = new APTS_SAPWSStructure.BAPISDHEAD();
        ORDER_HEADER_IN = getOrderHeaderIn(oOrder, oConfiguration);

        APTS_SAPWSStructure.ORDER_PARTNERS_element ORDER_PARTNERS = new APTS_SAPWSStructure.ORDER_PARTNERS_element();
        ORDER_PARTNERS = getSalesPartner(oOrder);

        APTS_SAPWSStructure.ORDER_ITEMS_IN_element ORDER_ITEMS_IN = new APTS_SAPWSStructure.ORDER_ITEMS_IN_element();
        ORDER_ITEMS_IN = getOrderItemsIn(idToLineItemMap, itemNumberToOrderLineItemMap);

        APTS_SAPXMLRequestWrapper oSAPXMLRequestWrapper = new APTS_SAPXMLRequestWrapper(ORDER_HEADER_IN, ORDER_PARTNERS, ORDER_ITEMS_IN, itemNumberToOrderLineItemMap);

        return oSAPXMLRequestWrapper;
    }

    /* setAsyncATPCheckResults Method Body */
    public static APTS_ATPResultWrapper setAsyncATPCheckResults(APTS_SAPWSStructure.BAPI_SALESORDER_SIMULATE_Response_element response, Map<Integer, Apttus_Config2__LineItem__c> itemNumberToOrderLineItemMap) {

        //try {
        if (response == null) {
            throw new ResultException(WEBSERVICEFAILEDMSG);
        }
        if (response.RETURN_x != null &&  response.RETURN_x.TYPE_x.equals(E)) {
            throw new ResultException(response.RETURN_x.MESSAGE);
        }

        List<Apttus_Config2__LineItem__c> lineItemsToUpdateList = new List<Apttus_Config2__LineItem__c>();
        List<Apttus_Config2__TaxBreakup__c> taxBreakupsToInsertList = new List<Apttus_Config2__TaxBreakup__c>();
        List<APTS_Order_Freight_Data__c> freightDataToInsertList = new List<APTS_Order_Freight_Data__c>();

        //v102++<< calculate Freight Charge
        Map<ID, Decimal> lineItemToVATMap = new Map<ID, Decimal>();

        taxBreakupsToInsertList = getTaxBreakups(itemNumberToOrderLineItemMap, response.ORDER_CONDITION_EX);
        lineItemToVATMap = getVATCharges(itemNumberToOrderLineItemMap, response.ORDER_CONDITION_EX);
        lineItemsToUpdateList = setATPResultsOnLineItems(itemNumberToOrderLineItemMap, response.ORDER_SCHEDULE_EX, response.ORDER_ITEMS_OUT, lineItemToVATMap);

        //TO DO freightDataToInsertList = getFreightData(itemNumberToOrderLineItemMap, response.ORDER_CONDITION_EX);
        //v102++>>

        APTS_ATPResultWrapper oATPResultWrapper = new APTS_ATPResultWrapper(lineItemsToUpdateList, taxBreakupsToInsertList, freightDataToInsertList);
        //} catch (Exception e) {
        //    APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id), 'OM', false, true, EMAIL, true);
        //}

        return oATPResultWrapper;
    }

    /* getOrderHeaderIn Method Body */
    public static APTS_SAPWSStructure.BAPISDHEAD getOrderHeaderIn(Apttus_Config2__Order__c oOrder, Apttus_Config2__ProductConfiguration__c oConfiguration) {

        checkForNull(oOrder.Apttus_Config2__SoldToAccountId__r.Sales_Organization__c, SALESORGONACCOUNTEMPTY);
        String salesOrg = removeSAPPrefix(oOrder.Apttus_Config2__SoldToAccountId__r.Sales_Organization__c);

        checkForNull(oOrder.Apttus_Config2__SoldToAccountId__r.Distribution_Channel__c, DISTRIBUTIONCHANNELONACCOUNTEMPTY);
        String distrCh = removeSAPPrefix(oOrder.Apttus_Config2__SoldToAccountId__r.Distribution_Channel__c);

        checkForNull(oOrder.Apttus_Config2__SoldToAccountId__r.Division__c, DIVISIONONACCOUNTEMPTY);
        String division = removeSAPPrefix(oOrder.Apttus_Config2__SoldToAccountId__r.Division__c);

        checkForNull(oConfiguration.APTS_Max_Requested_Delivery_Date__c, MAXREQUESTEDDELIVERYDATEEMPTY);
        DateTime reqDate = oConfiguration.APTS_Max_Requested_Delivery_Date__c;

        APTS_SAPWSStructure.BAPISDHEAD ORDER_HEADER_IN = new APTS_SAPWSStructure.BAPISDHEAD();

        ORDER_HEADER_IN.DOC_TYPE = ATPSIMULATIONDOCTYPE;//'XA06';//'XA01'; oOrder.APTS_SAP_OrderType__c;
        ORDER_HEADER_IN.SALES_ORG = salesOrg;//'0333';
        ORDER_HEADER_IN.DISTR_CHAN = distrCh;//'10';
        ORDER_HEADER_IN.DIVISION = division;//'20';
        ORDER_HEADER_IN.REQ_DATE_H = reqDate.format(YYYYMMDD);
        ORDER_HEADER_IN.SHIP_COND = ZEROTHREE;

        return ORDER_HEADER_IN;
    }

    /* getSalesPartner Method Body */
    public static APTS_SAPWSStructure.ORDER_PARTNERS_element getSalesPartner(Apttus_Config2__Order__c oOrder) {

        APTS_SAPWSStructure.ORDER_PARTNERS_element ORDER_PARTNERS = new APTS_SAPWSStructure.ORDER_PARTNERS_element();

        ORDER_PARTNERS.item = new List<APTS_SAPWSStructure.BAPIPARTNR>();

        APTS_SAPWSStructure.BAPIPARTNR BAPIPARTNR = new APTS_SAPWSStructure.BAPIPARTNR();

        BAPIPARTNR.PARTN_ROLE = AG;
        BAPIPARTNR.PARTN_NUMB = addZero(oOrder.Apttus_Config2__SoldToAccountId__r.SAP_Customer_ID__c, 10);
        BAPIPARTNR.ITM_NUMBER = ZEROCHAR;

        ORDER_PARTNERS.item.add(BAPIPARTNR);

        return ORDER_PARTNERS;
    }

    /* getOrderItemsIn Method Body */
    public static APTS_SAPWSStructure.ORDER_ITEMS_IN_element getOrderItemsIn(Map<Id, Apttus_Config2__LineItem__c> idToLineItemMap, Map<Integer, Apttus_Config2__LineItem__c> itemNumberToOrderLineItemMap) {

        APTS_SAPWSStructure.ORDER_ITEMS_IN_element ORDER_ITEMS_IN = new APTS_SAPWSStructure.ORDER_ITEMS_IN_element();
        String sSalesUnit;
        ORDER_ITEMS_IN.item = new List<APTS_SAPWSStructure.BAPIITEMIN>();
        Integer itemCounter = ZERO;
        Decimal NetListPrice = 0;

        for (Apttus_Config2__LineItem__c oLineItem : idToLineItemMap.values()) {
            if (!oLineItem.Apttus_Config2__HasOptions__c && oLineItem.Apttus_Config2__ParentBundleNumber__c == null
                    || oLineItem.Apttus_Config2__OptionId__r != null && oLineItem.Apttus_Config2__OptionId__r.ProductCode.startsWith(EIGHTYONE)) {
                Integer counterStep = oLineItem.Apttus_Config2__OptionId__r != null && oLineItem.Apttus_Config2__OptionId__r.ProductCode.startsWith(EIGHTYONE) ? 100 : 10;
                itemCounter += counterStep;
                APTS_SAPWSStructure.BAPIITEMIN BAPIITEMIN = new APTS_SAPWSStructure.BAPIITEMIN();
                BAPIITEMIN.ITM_NUMBER = addZero(String.valueOf(itemCounter), 6);
                String sMaterial = oLineItem.Apttus_Config2__OptionId__r != null
                                   ? oLineItem.Apttus_Config2__OptionId__r.ProductCode
                                   : oLineItem.Apttus_Config2__ProductId__r.ProductCode;

                BAPIITEMIN.MATERIAL = addZero(sMaterial, 18);//'55000267';
                BAPIITEMIN.TARGET_QTY = (oLineItem.Apttus_Config2__Quantity__c * THOUSAND).setScale(ZERO).toPlainString();
                BAPIITEMIN.REQ_QTY = (oLineItem.Apttus_Config2__Quantity__c * THOUSAND).setScale(ZERO).toPlainString();
                            
                //v105 ++<<<
                NetListPrice = oLineItem.Apttus_Config2__NetPrice__c != null ? oLineItem.Apttus_Config2__NetPrice__c : 0;
                
                BAPIITEMIN.COND_TYPE = ZP01;
                BAPIITEMIN.COND_VALUE  = NetListPrice.setscale(9).toPlainString();
                BAPIITEMIN.COND_P_UNT  = (oLineItem.Apttus_Config2__Quantity__c * TEN).setScale(ZERO).toPlainString();
                
               //V107 ++<<< 
                if(Integer.valueof(BAPIITEMIN.COND_P_UNT) > 99999)
                {
                BAPIITEMIN.COND_P_UNT = String.valueof(Integer.valueOf(BAPIITEMIN.COND_P_UNT)/100);
                BAPIITEMIN.COND_VALUE = String.valueof(Integer.valueOf(BAPIITEMIN.COND_VALUE)/100);
                }
               //V107 -->>>
               
               //v105 -->>>  

                if (oLineItem.Apttus_Config2__SellingUom__c != null) {
                    sSalesUnit = removeSAPPrefix(oLineItem.Apttus_Config2__SellingUom__c);
                } else {
                    sSalesUnit = ST;
                }
                //BAPIITEMIN.SALES_UNIT = sSalesUnit; //'ST'
                BAPIITEMIN.T_UNIT_ISO = sSalesUnit;
                BAPIITEMIN.S_UNIT_ISO = sSalesUnit;
                ORDER_ITEMS_IN.item.add(BAPIITEMIN);
                itemNumberToOrderLineItemMap.put(itemCounter, oLineItem);
            }
        }

        return ORDER_ITEMS_IN;
    }

    /* setATPResultsOnLineItems Method Body */
    public static List<Apttus_Config2__LineItem__c> setATPResultsOnLineItems(Map<Integer, Apttus_Config2__LineItem__c> itemNumberToOrderLineItemMap, APTS_SAPWSStructure.ORDER_SCHEDULE_EX_element responseLI, APTS_SAPWSStructure.ORDER_ITEMS_OUT_element responseOutLI, Map<ID, Decimal> lineItemToVATMap ) {

        List<Apttus_Config2__LineItem__c> lineItemsToUpdateList = new List<Apttus_Config2__LineItem__c>();
        Set<Id> lineItemsToUpdateSet = new Set<Id>();
        Map<Integer, string> itemNumberToPlantCodeMap = new Map<Integer, string>();
        //V101++<<
        try {
            if (responseOutLI != null) {

                for (APTS_SAPWSStructure.BAPIITEMEX bapiOutElement : responseOutLI.item) {
                    String strPlantCode = String.ValueOf(bapiOutElement.PLANT);
                    itemNumberToPlantCodeMap.put(Integer.valueOf(bapiOutElement.ITM_NUMBER), strPlantCode);
                }
            }
        } catch (Exception ex) {
            System.debug('Exception occurred while reading PLANT code from ATP Response:: Exception Message :: ' + ex.getMessage());
        }
        //V101++>>

        if (responseLI != null) {
            for (APTS_SAPWSStructure.BAPISDHEDU bapischedu : responseLI.item) {
                Decimal confirmedQty = Decimal.valueOf(bapischedu.CONFIR_QTY);
                Apttus_Config2__LineItem__c oLineItem = (Apttus_Config2__LineItem__c)itemNumberToOrderLineItemMap.get(Integer.valueOf(bapischedu.ITM_NUMBER));
                if (oLineItem != null) {
                    if (confirmedQty > ZERO) {

                        oLineItem.APTS_Expected_Delivery_Date__c = Date.valueOf(bapischedu.REQ_DATE + ' ' + bapischedu.REQ_TIME);
                        oLineItem.APTS_Expected_Delivery_Quantity__c = confirmedQty;
                        
                        //commented as ATP clear should happen if Quantity and Dates match
                        //oLineItem.APTS_ATP_Cleared__c = true;

                        //V101++<<
                        if (!itemNumberToPlantCodeMap.isEmpty()) {
                            oLineItem.APTS_Plant_Code__c = itemNumberToPlantCodeMap.get(Integer.valueOf(bapischedu.ITM_NUMBER));
                        }
                        //V101++>>

                        //v102++<< calculate Freight Charge
                        oLineItem.APTS_VATO__c = lineItemToVATMap.get(oLineItem.ID) != null ? lineItemToVATMap.get(oLineItem.ID) : 0;
                        //v102++>>

                        //v103 ++ <<
                        if (!lineItemToTAXMap.isEmpty()) {
                            oLineItem.APTS_TAXO__c = lineItemToTAXMap.get(oLineItem.ID) != null ? lineItemToTAXMap.get(oLineItem.ID) : 0;
                        }
                        if (!lineItemToAddChargeMap.isEmpty()) {
                            oLineItem.APTS_Additional_chargesO__c = lineItemToAddChargeMap.get(oLineItem.ID) != null ? lineItemToAddChargeMap.get(oLineItem.ID) : 0;
                        }
                        //v103 ++ >>

                        //v104 ++ <<
                    }

                    //commented as ATP clear should happen if Quantity and Dates match
                    /* else if (confirmedQty == null || confirmedQty == 0) {
                        oLineItem.APTS_ATP_Cleared__c = false;
                    }*/
                    // qty 10 confQty 20 and req date == expected date
                    oLineItem.APTS_ATP_Cleared__c = oLineItem.Apttus_Config2__Quantity__c != null && oLineItem.APTS_Requested_Delivery_Date__c != null ? true : false;
                    
                    if (!lineItemsToUpdateSet.contains(oLineItem.Id)) {
                        lineItemsToUpdateSet.add(oLineItem.Id);
                        lineItemsToUpdateList.add(oLineItem);
                    }
                    //v104 ++ >>
                }
            }
        }

        return lineItemsToUpdateList;
    }

    /* getTaxBreakups Method Body */
    public static List<Apttus_Config2__TaxBreakup__c> getTaxBreakups(Map<Integer, Apttus_Config2__LineItem__c> itemNumberToOrderLineItemMap, APTS_SAPWSStructure.ORDER_CONDITION_EX_element responseTLI) {

        List<Apttus_Config2__TaxBreakup__c> taxBreakupsToInsertList = new List<Apttus_Config2__TaxBreakup__c>();
        //v102++<< ZWST is not applicable for Total Tax
        // Set<String> taxCondTypeSet = new Set<String> {'ZWST', 'Z610', 'YD48', 'YD49', 'YD50', 'YD51', 'YD52', 'YD53', 'YD54'};
        Set<String> taxCondTypeSet = new Set<String> {'Z610', 'Z710', 'Z619', 'YD48', 'YD49', 'YD50', 'YD51', 'YD52', 'YD53', 'YD54'};
        //v102++>>

        if (responseTLI != null) {
            for (APTS_SAPWSStructure.BAPICOND bapicond : responseTLI.item) {

                String sItemNumber = bapicond.ITM_NUMBER;
                String sCondType = bapicond.COND_TYPE;
                Decimal dCondValue = Decimal.valueOf(bapicond.CONDVALUE);

                Apttus_Config2__LineItem__c oLineItem = (Apttus_Config2__LineItem__c)itemNumberToOrderLineItemMap.get(Integer.valueOf(sItemNumber));

                if (oLineItem != null) {
                    //Tax
                    if (taxCondTypeSet.contains(sCondType)) {
                        Apttus_Config2__TaxBreakup__c oTaxBreakup = new Apttus_Config2__TaxBreakup__c();
                        oTaxBreakup.Apttus_Config2__LineItemId__c = oLineItem.Id;
                        oTaxBreakup.Apttus_Config2__TaxAmount__c = dCondValue;
                        oTaxBreakup.Apttus_Config2__Sequence__c = 1;
                        oTaxBreakup.CurrencyIsoCode = oLineItem.CurrencyIsoCode;//'EUR';
                        taxBreakupsToInsertList.add(oTaxBreakup);
                    }
                }
            }
        }

        return taxBreakupsToInsertList;
    }

    /* v102++<< VAT Charge Calculation */
    public static Map<Id, Decimal> getVATCharges(Map<Integer, Apttus_Config2__LineItem__c> itemNumberToOrderLineItemMap, APTS_SAPWSStructure.ORDER_CONDITION_EX_element responseTLI) {

        String sVatCondType = ZWST;
        Map<Id, Decimal> lineItemToVATMap = new Map<Id, Decimal>();

        //v103 ++ <<
        String sTAXCondType = ZS10;
        string sAdditionalChargeCondType = ZS11;
        lineItemToTAXMap = new Map<ID, Decimal>();
        lineItemToAddChargeMap = new Map<ID, Decimal>();
        //v103 ++ >>

        if (responseTLI != null) {
            for (APTS_SAPWSStructure.BAPICOND bapicond : responseTLI.item) {

                String sItemNumber = bapicond.ITM_NUMBER;
                String sCondType = bapicond.COND_TYPE;
                Decimal dCondValue = Decimal.valueOf(bapicond.CONDVALUE);

                Apttus_Config2__LineItem__c oLineItem = (Apttus_Config2__LineItem__c)itemNumberToOrderLineItemMap.get(Integer.valueOf(sItemNumber));

                if (oLineItem != null) {
                    //v106++<<< VAT check both ZWST or ZM04   Defect 22930
                    if (sCondType.equals(ZWST) || sCondType.equals(ZM04)) {
                        lineItemToVATMap.put(oLineItem.ID, dCondValue);
                    }
                    //v106 -->>> VAT changes - 
                    //TAX
                    else if (sCondType.equals(sTAXCondType)) {
                        lineItemToTAXMap.put(oLineItem.ID, dCondValue);
                    }
                    //Additional Charge
                    else if (sCondType.equals(sAdditionalChargeCondType)) {
                        lineItemToAddChargeMap.put(oLineItem.ID, dCondValue);
                    }
                }
            }
        }
        return lineItemToVATMap;
    }
    //v102++>>  VAT Charge Calculation

    /*public static List<APTS_Order_Freight_Data__c> getFreightData(Map<Integer, Apttus_Config2__LineItem__c> itemNumberToOrderLineItemMap, APTS_SAPWSStructure.ORDER_CONDITION_EX_element responseTLI) {

        List<APTS_Order_Freight_Data__c> freightDataToInsertList = new List<APTS_Order_Freight_Data__c>();
        //try {
        if (responseTLI != null) {
            for (APTS_SAPWSStructure.BAPICOND bapicond : responseTLI.item) {

                String sItemNumber = bapicond.ITM_NUMBER;
                String sCondType = bapicond.COND_TYPE;
                Decimal dCondValue = Decimal.valueOf(bapicond.CONDVALUE);

                Apttus_Config2__LineItem__c oLineItem = (Apttus_Config2__LineItem__c)itemNumberToOrderLineItemMap.get(Integer.valueOf(sItemNumber));

                if (oLineItem != null) {
                    //Freight charges
                    if (sCondType.equals(TEST)) {
                        APTS_Order_Freight_Data__c oFreightData = new APTS_Order_Freight_Data__c();
                        oFreightData.APTS_Sequence__c = 1;
                        oFreightData.APTS_Freight_Amount__c = 50;
                        oFreightData.APTS_Line_Item__c = oLineItem.Id;
                        freightDataToInsertList.add(oFreightData);
                    }
                }
            }
        }
        //} catch (Exception e) {
        //    APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id), 'OM', false, true, EMAIL, true);
        //}
        return freightDataToInsertList;
    }*/

    /* removeSAPPrefix Method body */
    private static String removeSAPPrefix(String prefixedValue) {

        if (prefixedValue.startsWith(SAP)) {
            prefixedValue = prefixedValue.substring(4);
        }

        return prefixedValue;
    }

    /* addZero Method body */
    private static String addZero(String sField, Integer sLength) {

        while (sField.length() < sLength) {
            sField = ZEROCHAR + sField;
        }
         
        return sField;                     
    }

    /* checkForNull Method body */
    private static void checkForNull(Object oFeildValue, String Message) {
        if (oFeildValue == null) {
            throw new MissingDataException(Message);
        }
    }

    /* MissingDataException Class body */
    private class MissingDataException extends Exception {}
    /* ResultException Class body */
    private class ResultException extends Exception {}
    /* ValidationException Class body */
    private class ValidationException extends Exception {}

}