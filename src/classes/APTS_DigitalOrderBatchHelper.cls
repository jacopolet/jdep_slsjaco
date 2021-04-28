/*************************************************************
@Name: APTS_DigitalOrderBatchHelper
@Author: Neev Shah
@CreateDate: 3-04-2018
@Description: A class who have common methods for Digital Order
******************************************************************/
//v101 17-oct-2018 Lodewijk : Setting oDigOrder.APTS_External_Total_Order_Adjustment__c based on  - objWrapper.TotalOrderAdjustment Defect #20073
//v102 18-oct-2018 Akanksha : Changed logic for calculating price difference for defect #20068
//v103 11-Feb-2019 Sanjay :  Removed Freight Constraint Rule and added as part of add products - Defect # 4812
//v104 20-Feb-2019 Rajesh : Defect#4920 don't take Location from Agreement as Agreement can be Parent / Grand Parent Agreement, primary contact from accoun
//v105 29-Mar-2019 : Neev Shah : 6353 - Account Parent Hierarchy to set Agreement on Order Header
//v106 11-Apr-2019 : Neev Shah : 6500 - Duplicate Source Order Number validation RSO
//v107 12-Jul-2019 : Akanksha : DFT2C-420 - paasing extra parameter accounthierarchy in creatersoorderheaders
//v108 26-Aug-2019 : Venky : DFT2C-208 - Base price over ride for Digital and RSO from CER
//v109 25-Nov-2019 Aarthi Pitchai - Avoid cart finalization without PLIs
//v110 27-Aug-2020 Sneha Jaiwant-paasing extra parameter interfaceLogId in createErrorLog
//v111 14-Sep-2020 Sneha Jaiwant:DQ 3727-Create Error log if the agreement enddate is past.
//V112 25-Nov-2020 Aarthi Pitchai - Restrict auto submission of German webshop orders

public without sharing class APTS_DigitalOrderBatchHelper {
    private static final Decimal PRICING_DIFF_PRECISION_VALUE = 0.001 ;
    private static final String STATUS_INPROGRESS = 'InProgress';
    private static final String STR_YES = 'Yes';
    private static final String STR_NO = 'No';
    private static final String STR_STANDARD = System.Label.APTS_Standard;
    private static final String IN_EFFECT = 'In Effect';
    private static final String ACTIVATED = 'Activated';
    private static final String STANDARD_DEAL = 'Standard Deal';
    private static final String DIGITAL = 'Digital';
    private static final String STANDARD_ORDER = System.Label.APTS_Standard_Order;
    private static final String XA01 = System.Label.APTS_XA01;
    private static final String STATUS_NEW = System.Label.APTS_New;
    private static final String SUB_TYPE_DIGITAL = System.Label.APTS_Order_Type_Digital;
    private static final String TYPE_OPERATING = System.Label.APTS_Order_Type_Operating;
    private static final String TYPE_ROUTE_SALES = System.Label.APTS_Order_Type_Route_Sales;
    private static final String EMAIL = System.Label.APTS_Email;
    private static final String ZOLP = System.Label.APTS_ZOLP;
    // v103++<<
    private static final String FREIGHT_CHARGE = System.Label.APTS_FREIGHT_CHARGE;
    // v103 -->>
//v110
public static Map<String,Id> mapInterfaceOlog;

    //wrapper class used to return data
    public without sharing class EPIOrderCreationResp {
        public Map<Id, APTS_DOEPIReqWrapper> mapDigitalWrapper {get; set;}
        public Map<Id, Apttus_Config2__Order__c> mapLogIdNewOrders {get; set;}
    }

    /** Method : createErrorLog
    ** Description : method would return instance of Error Log
    **/
    public static APTS_Order_Error_Log__c createErrorLog(String sErrMsg, String sSourceOrder, String sSourceOrderLineNumber, Id orderId, Id orderLineItemId,Id interfaceLogId, Group queue) {
        APTS_Order_Error_Log__c oError = new APTS_Order_Error_Log__c();
        oError.APTS_Status__c = STATUS_NEW;
        oError.APTS_Error_Message__c = sErrMsg;
        oError.APTS_Source_Order_Number__c = sSourceOrder;
        oError.APTS_Source_Line_Number__c = sSourceOrderLineNumber;
        oError.APTS_Order_Number__c = orderId;
        oError.APTS_Order_Line_Item__c = orderLineItemId;
        oError.OwnerId = queue != null ? queue.Id : UserInfo.getUserId();
        //v110
       oError.APTS_Interface_Log__c= interfaceLogId;
        //v110

        return oError;
    }


    /** Method : getJSONStr
    ** Description : method would process EPI Interface Logs and prepare JSONStr to deserial
    **/
    public static Map<Id, APTS_DOEPIReqWrapper> getDigitalOrderData(Group queue, List<APTS_Order_Interface_Log__c> listEPILog) {
        Id currIdForException;
        List<APTS_Order_Interface_Log__c> listToUpdate = new List<APTS_Order_Interface_Log__c>();
        Map<Id, String> mapJSONStr = new Map<Id, String>();
        Map<Id, APTS_DOEPIReqWrapper> mapDigitalWrapper = new Map<Id, APTS_DOEPIReqWrapper>();

        try {

            //prepare map of Id and JSON string from parent records
            for (APTS_Order_Interface_Log__c oLog : listEPILog) {
                currIdForException = oLog.Id;
                oLog.APTS_Status__c = STATUS_INPROGRESS;
                listToUpdate.add(oLog);
                mapJSONStr.put(oLog.Id, oLog.APTS_Message__c);
            }

            //update Interface record's status to Inprogress so no other batch will pick this record
            if (!listToUpdate.isEmpty()) {
                Database.update(listToUpdate, FALSE);
            }

            String sJSONStr, sErrMsg;
            APTS_DOEPIReqWrapper objWrapper;
            APTS_Order_Error_Log__c oErrLog;
            List<APTS_Order_Error_Log__c> listErrorLog = new List<APTS_Order_Error_Log__c>();

            //prepare string json from child interface logs
            for (APTS_Order_Interface_Log__c oChildLog : [SELECT id, APTS_SourceOrderNumber__c, APTS_Message__c, APTS_Parent_Log__c, APTS_Sequence__c, APTS_Status__c
                    FROM APTS_Order_Interface_Log__c WHERE APTS_Parent_Log__c = : mapJSONStr.keySet() AND APTS_Status__c = : STATUS_NEW
                            ORDER BY APTS_Sequence__c]) {

                sJSONStr = mapJSONStr.containsKey(oChildLog.APTS_Parent_Log__c) ? mapJSONStr.get(oChildLog.APTS_Parent_Log__c) :  '';
                sJSONStr += oChildLog.APTS_Message__c;
                mapJSONStr.put(oChildLog.APTS_Parent_Log__c, sJSONStr);
            }


            for (Id interfaceLogId : mapJSONStr.keySet()) {
                currIdForException = interfaceLogId;
                sJSONStr = mapJSONStr.get(interfaceLogId);

                if (String.isNotBlank(sJSONStr)) {
                    try {

                        //deserilize JSONstr
                        objWrapper = (APTS_DOEPIReqWrapper)JSON.deserialize(sJSONStr, APTS_DOEPIReqWrapper.class);

                        if ('Digital' == objWrapper.Source) {
                            sErrMsg = APTS_DigitalOrderUtils.validateData(objWrapper);
                        } else {
                            sErrMsg = APTS_RSOOrderUtils.validateRSOData(objWrapper);
                        }

                    } catch (Exception jsonEx) {

                        sErrMsg = 'JSON formatting issue with source number = ' + interfaceLogId;
                        sErrMsg += '\n ' + jsonEx.getMessage();

                    } finally {

                        if (String.isNotBlank(sErrMsg)) {
                            oErrLog = createErrorLog(sErrMsg, interfaceLogId, NULL, NULL, NULL,interfaceLogId, queue);
                            listErrorLog.add(oErrLog);
                        } else {
                            mapDigitalWrapper.put(interfaceLogId, objWrapper);
                        }
                    }

                }
            }

            if (!listErrorLog.isEmpty()) {
                Database.insert(listErrorLog);
            }

        } catch (Exception oEx) {
            APTS_CustomLogging.createErrorLog(oEx.getTypeName(), 'Apex', oEx.getStackTraceString(), 'Digital Order', currIdForException, 'OM', false, true, null, true);
        }

        return mapDigitalWrapper;
    }

    public static EPIOrderCreationResp createExternalOrderHeader(String stype, Group queue, List<APTS_Order_Interface_Log__c> listEPILog) {
        EPIOrderCreationResp oResp = new EPIOrderCreationResp();
        Map<Id, APTS_DOEPIReqWrapper> mapLogWrapper;
        try {
            //update Interface logs status to "In Progress" to avoid duplicate Orders and prepare JSON Strings
            mapLogWrapper = getDigitalOrderData(queue, listEPILog);

            if (mapLogWrapper == null || mapLogWrapper.isEmpty()) {
                return oResp;
            }

            if (APTS_OrderConstants.ORDER_TYPE_DIGITAL.equalsIgnoreCase(stype)) {
                oResp = processDigitalOrders(queue, listEPILog);
            } else {
                oResp = createRSOOrderHeaders(queue, listEPILog, mapLogWrapper);
            }

            if (oResp != null && oResp.mapLogIdNewOrders != null && !oResp.mapLogIdNewOrders.isEmpty() && oResp.mapLogIdNewOrders.values() != null) {
                //Align with S&M team for below flag to avoid Account Triggers
                //AccountTriggerHandler.isBatchRun = true;
                Database.SaveResult[] srList =  Database.insert(oResp.mapLogIdNewOrders.values(), false);
                String sErrMsg;
                APTS_Order_Error_Log__c oErrLog;
                List<APTS_Order_Error_Log__c> listErrorLog = new List<APTS_Order_Error_Log__c>();

                //insert all error in error log
                for (Database.SaveResult sr : srList) {
                    if (!sr.isSuccess()) {
                        sErrMsg = '';

                        for (Database.Error err : sr.getErrors()) {
                            sErrMsg += err.getMessage() + ' affected fields : ' + err.getFields();

                        }

                        oErrLog = APTS_DigitalOrderBatchHelper.createErrorLog(sErrMsg, listEPILog[0].APTS_SourceOrderNumber__c, null, null, null,listEPILog[0].id, queue);
                        listErrorLog.add(oErrLog);
                    }
                }
                if (!listErrorLog.isEmpty()) {
                    Database.insert(listErrorLog);
                }
            }
        } catch (Exception Ex) {  }
        return oResp;
    }

    public static EPIOrderCreationResp processDigitalOrders(Group queue, List<APTS_Order_Interface_Log__c> listEPILog) {
        String currIdForException = null;
        EPIOrderCreationResp oResp = new EPIOrderCreationResp();
        
        try {
            //update Interface logs status to "In Progress" to avoid duplicate Orders and prepare JSON Strings
            Map<Id, APTS_DOEPIReqWrapper> mapDigitalOrderWrapper = getDigitalOrderData(queue, listEPILog);

            if (mapDigitalOrderWrapper == null || mapDigitalOrderWrapper.isEmpty()) {
                return oResp;
            }

            APTS_DOEPIReqWrapper oDigitalWrapper;
            Set<Id> setSoldToId = new Set<Id>();
            Set<String> setSerialNumber = new Set<String>();

            //********* Initial Loop ***********//
            for (Id interfaceLogId : mapDigitalOrderWrapper.keySet()) {

                oDigitalWrapper = mapDigitalOrderWrapper.get(interfaceLogId);
                if (oDigitalWrapper != NULL && oDigitalWrapper.OrderLineItems != null) {
                    setSoldToId.add(oDigitalWrapper.SalesforceAccountID);
                    setSerialNumber.add(oDigitalWrapper.SourceOrderNumber);
                }

            }
            //********* Initial Loop ***********//

            //****** SOQL Section ********//

            Apttus_Config2__PaymentTerm__c oPrepaidPT = APTS_DigitalOrderUtils.getDefaultPaymentTerm();
            Map<Id, Account> mapAccount = APTS_DigitalOrderUtils.getAccounts(setSoldToId);
            Map<Id, Contact> mapContancts = APTS_DigitalOrderUtils.getContacts(setSoldToId);
            Map<Id, Apttus__APTS_Agreement__c> mapStandardAgs = new Map<Id, Apttus__APTS_Agreement__c>();
            Map<Id, APTS_Billing_Settings__c> mapBS = new Map<Id, APTS_Billing_Settings__c>();
            Map<String, Id> mapExistingOrder = new Map<String, Id>();

            if (mapAccount != null) {
                APTS_RSOOrderUtils.AccountHierarchyWrapper oAccHierachyWrap = APTS_RSOOrderUtils.getAccountHierarchyId(mapAccount.values());
                //v105 - BSS Defect #6353 - Account Parent hierarchy to set Agreement on Order Header
                mapStandardAgs = APTS_DigitalOrderUtils.getDigitalAgreements(oAccHierachyWrap.setAccountToVisitId, oAccHierachyWrap.setAllAccountId, oAccHierachyWrap.mapParentId, oAccHierachyWrap.mapGrandParentId);              
                if (mapStandardAgs != null) {
                    Set<Id> setAgIds = new Set<Id>();

                    for (Apttus__APTS_Agreement__c agTmp : mapStandardAgs.values()) {
                        setAgIds.add(agTmp.Id);
                    }

                    //Map of mapBS used for setting up payment method
                    for (APTS_Billing_Settings__c obs :  [Select Id, APTS_Payment_Method__c, APTS_Agreement_ID__c from APTS_Billing_Settings__c where APTS_Agreement_ID__c = :setAgIds]) {
                        mapBS.put(obs.APTS_Agreement_ID__c, obs);
                    }
                }
            }

            for (Apttus_Config2__Order__c oOrder : [SELECT id, APTS_Source_Order_Number__c FROM Apttus_Config2__Order__c WHERE APTS_Source_Order_Number__c IN :setSerialNumber]) {
                mapExistingOrder.put(oOrder.APTS_Source_Order_Number__c, oOrder.Id);
            }

            //****** SOQL Section ********//


            Map<Id, Apttus_Config2__Order__c> mapLogIdNewOrders = new Map<Id, Apttus_Config2__Order__c>();
            for (Id interfaceLogId : mapDigitalOrderWrapper.keySet()) {
                APTS_DOEPIReqWrapper oWrap = mapDigitalOrderWrapper.get(interfaceLogId);
                Id existingOrder =  mapExistingOrder.get(oWrap.SourceOrderNumber);

                if (oWrap != null && existingOrder == null) {
                    Apttus_Config2__Order__c oNewOrder = APTS_DigitalOrderUtils.createOrderHeader(oWrap, mapAccount, mapContancts, mapStandardAgs, oPrepaidPT, mapBS);

                    if (oNewOrder != null) {
                        mapLogIdNewOrders.put(interfaceLogId, oNewOrder);
                    }
                }
            }

            if (!mapLogIdNewOrders.isEmpty()) {
                //Database.SaveResult[] srList =  Database.insert(mapLogIdNewOrders.values(), false);

                oResp.mapLogIdNewOrders = mapLogIdNewOrders;
                oResp.mapDigitalWrapper = mapDigitalOrderWrapper;
            }


        } catch (Exception ex) {
            APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString(), 'Digital Order', currIdForException, 'OM', false, true, null, true);
            throw ex;
        }

        return oResp;
    }


    public static EPIOrderCreationResp createRSOOrderHeaders(Group csQueue, List<APTS_Order_Interface_Log__c> listEPILog, Map<Id, APTS_DOEPIReqWrapper> mapRSOLogWrapper) {
        EPIOrderCreationResp oResp = new EPIOrderCreationResp();
        APTS_Order_Error_Log__c oErrLog;
        List<APTS_Order_Error_Log__c> listErrorLog = new List<APTS_Order_Error_Log__c>();
        

        try {
            Set<id> setSoldToId = new Set<id>();
            Set<String> setSAPEmpNumbers = new Set<String>();
            Set<String> setSourceOrderNumber = new Set<String>();
            

            for (Id logId : mapRSOLogWrapper.keySet()) {
                APTS_DOEPIReqWrapper oWrapper = mapRSOLogWrapper.get(logId);
                setSoldToId.add(oWrapper.SalesforceAccountID);
                setSAPEmpNumbers.add(oWrapper.RSOEmployeeEmail);
                //v106
                setSourceOrderNumber.add(oWrapper.SourceOrderNumber);
            }
          
            //********* SOQL Section **********//
            Id routeSalesRecordTypeId = Schema.SObjectType.Apttus_Config2__Order__c.getRecordTypeInfosByName().get(APTS_OrderConstants.ORDER_TYPE_ROUTESALES).getRecordTypeId();
            Id operatingRecordTypeId = Schema.SObjectType.Apttus_Config2__Order__c.getRecordTypeInfosByName().get(APTS_OrderConstants.ORDER_TYPE_OPERATING).getRecordTypeId();
            Map<String, String> mapSAPEmpNumber = APTS_RSOOrderUtils.getSAPNumber(setSAPEmpNumbers);
            //v104 ++ <<
            Map<id, Contact> mapPrimaryContact = APTS_OrderUtils.getPrimaryContactsRSO('Standard', setSoldToId);
            Map<id, Apttus_Config2__AccountLocation__c> mapAccountLocation = APTS_OrderUtils.getAccountLocation(setSoldToId);
            //v104 ++>>
            Map<Id, Account> mapAccount = APTS_RSOOrderUtils.getAccounts(setSoldToId);
            Map<Id, List<Apttus__APTS_Agreement__c>> mapSoldToAg;
            Map<Id, List<APTS_Agreement_PO_Details__c>> mapAgPODetails;
            Map<String, Apttus_Config2__Order__c> mapExistingOrder = new Map<String, Apttus_Config2__Order__c>();
            APTS_RSOOrderUtils.AccountHierarchyWrapper oAccHierachyWrap = new APTS_RSOOrderUtils.AccountHierarchyWrapper();
            if (mapAccount != null) {
                oAccHierachyWrap = APTS_RSOOrderUtils.getAccountHierarchyId(mapAccount.values());
                //defect 5930 being renewed agreement :  get all agreements from Parent and Grand Parent Hierarchy
                mapSoldToAg = APTS_RSOOrderUtils.getRSOAgreements(oAccHierachyWrap);
                if (mapSoldToAg != null) {
                    Set<Id> setAgTmp = new Set<Id>();
                    List<Apttus__APTS_Agreement__c> listAgTmp;

                    for (Id accId : mapSoldToAg.keySet()) {
                        listAgTmp = mapSoldToAg.get(accId);

                        for (Apttus__APTS_Agreement__c agTmp : listAgTmp) {
                            setAgTmp.add(agTmp.Id);
                        }
                    }

                    mapAgPODetails = APTS_RSOOrderUtils.getPODetails(setAgTmp);
                }
            }

            //v106 -- 6500 - duplicate Source Order Number Validation <<--
            for (Apttus_Config2__Order__c oOrder : [SELECT Name, APTS_Source_Order_Number__c, APTS_Route_Sales_Employee_Id__c FROM Apttus_Config2__Order__c WHERE APTS_Source_Order_Number__c IN :setSourceOrderNumber]) {
                if (String.isNotBlank(oOrder.APTS_Route_Sales_Employee_Id__c)) {
                    mapExistingOrder.put(oOrder.APTS_Source_Order_Number__c + '_' + oOrder.APTS_Route_Sales_Employee_Id__c, oOrder);
                }                
            }
            //v106 -- 6500 - duplicate Source Order Number Validation -->>

            //********* Main Loop ************//
            String userEmployeeNumber, orderEmployeeNumber;
            Account oacc;
            Contact oCont;
            APTS_DOEPIReqWrapper oWrap;
            Apttus_Config2__Order__c oExistingOrder;
            Apttus_Config2__Order__c oNewOrder;
            Apttus_Config2__AccountLocation__c accLocaion;
            List<Apttus__APTS_Agreement__c> listag;
            Map<Id, Apttus_Config2__Order__c> mapLogIdNewOrders = new Map<Id, Apttus_Config2__Order__c>();

            for (Id logId : mapRSOLogWrapper.keySet()) {
                oWrap = mapRSOLogWrapper.get(logId);

                if (oWrap != null) {
                    //v106 -- 6500 - duplicate Source Order Number Validation --<<
                    userEmployeeNumber = String.isNotBlank(oWrap.RSOEmployeeEmail) ? mapSAPEmpNumber.get(oWrap.RSOEmployeeEmail.toLowerCase()) : null;
                    oExistingOrder = String.isNotBlank(userEmployeeNumber) ? mapExistingOrder.get(oWrap.SourceOrderNumber + '_' + userEmployeeNumber) : null;
                    orderEmployeeNumber =  oExistingOrder != null ? oExistingOrder.APTS_Route_Sales_Employee_Id__c : null;

                    if (oExistingOrder != null && String.isNotBlank(orderEmployeeNumber) && String.isNotBlank(userEmployeeNumber) && orderEmployeeNumber.equalsIgnoreCase(userEmployeeNumber)) {
                        //duplicate order
                        oErrLog = APTS_DigitalOrderBatchHelper.createErrorLog('Duplicate Order found. Old Order -> ' + oExistingOrder.Name, oWrap.SourceOrderNumber, null, null, null,logId , csQueue);
                        listErrorLog.add(oErrLog);
                    } else {
                        //v106 -- 6500 - duplicate Source Order Number Validation -->>
                        oacc = mapAccount.get(oWrap.SalesforceAccountID);
                        //v104 ++ <<
                        oCont = String.isNotBlank(oWrap.SalesforceAccountID) ? mapPrimaryContact.get(oWrap.SalesforceAccountID) : null;
                        accLocaion = String.isNotBlank(oWrap.SalesforceAccountID) ? mapAccountLocation.get(oWrap.SalesforceAccountID) : null;
                        //v104 ++ >>
                        if (oacc != null) {
                            listag = mapSoldToAg != null ? mapSoldToAg.get(oacc.Id) : null;
                            oNewOrder = APTS_RSOOrderUtils.createOrderHeader(routeSalesRecordTypeId, operatingRecordTypeId, oWrap, oAcc, listag, mapAgPODetails, oCont, accLocaion, oAccHierachyWrap) ;
                            //changed due to case issues
                            //oNewOrder.APTS_Route_Sales_Employee_Id__c = mapSAPEmpNumber.get(oWrap.RSOEmployeeEmail);
                            if (String.isNotBlank(oWrap.RSOEmployeeEmail)) {
                                oNewOrder.APTS_Route_Sales_Employee_Id__c = userEmployeeNumber;
                            }

                            if (oNewOrder != null) {
                                mapLogIdNewOrders.put(logId, oNewOrder);

                            } else {
                                //invalid order
                                oErrLog = APTS_DigitalOrderBatchHelper.createErrorLog('Error while Order Creation', oWrap.SourceOrderNumber, null,null, null,logId , csQueue);
                                listErrorLog.add(oErrLog);
                            }
                        } else {
                            //invalid order
                            oErrLog = APTS_DigitalOrderBatchHelper.createErrorLog('Sold To not found', oWrap.SourceOrderNumber, null,null, null,logId , csQueue);
                            listErrorLog.add(oErrLog);
                        }
                    }
                } else {
                    //invalid order
                    oErrLog = APTS_DigitalOrderBatchHelper.createErrorLog('Corrupted JSON for Log Id -> ' + logId, logId, null,null, null,logId , csQueue);
                    listErrorLog.add(oErrLog);
                }
            }

            if (!mapLogIdNewOrders.isEmpty()) {
                oResp.mapLogIdNewOrders = mapLogIdNewOrders;
                oResp.mapDigitalWrapper = mapRSOLogWrapper;
            }

        } catch (Exception ex) {
            oErrLog = APTS_DigitalOrderBatchHelper.createErrorLog(ex.getMessage(), null, listEPILog[0].APTS_SourceOrderNumber__c, null, null,listEPILog[0].id, csQueue);
            listErrorLog.add(oErrLog);
            APTS_CustomLogging.createErrorLog(ex.getMessage(), 'Apex', ex.getStackTraceString(), 'RSO Order', null, 'OM', false, true, null, true);

        } finally {
            if (!listErrorLog.isEmpty()) {
                Database.insert(listErrorLog);
            }

        }

        return oResp;
    }

    public static Map<String, APTS_DOEPIReqWrapper.EPIOrderLI> createCartAddProdcts(Group queue, Map<Id, APTS_DOEPIReqWrapper> mapDigitalOrderWrapper, Map<Id, Apttus_Config2__Order__c> mapLogIdNewOrders,Map<String, ID> mapInterfacelog) {
        Map<String, APTS_DOEPIReqWrapper.EPIOrderLI> mapEPIOLI = new Map<String, APTS_DOEPIReqWrapper.EPIOrderLI>();

        try {
            //********* Local Variables *********//
            Set<String> setProductCode = new Set<String>();
            Set<String> setProductId = new Set<String>();
            List<APTS_OneTimeAddress__c> addressLst = new List<APTS_OneTimeAddress__c>();
            List<Apttus_Config2__ProductConfiguration__c> listCartToSave = new List<Apttus_Config2__ProductConfiguration__c>();
            Map<String, List<APTS_DOEPIReqWrapper.EPIAdjustmentLI>> mapEPIAdjustmentList = new Map<String, List<APTS_DOEPIReqWrapper.EPIAdjustmentLI>>();
            //********* Local Variables *********//

            for (Id interfaceLogId : mapDigitalOrderWrapper.keySet()) {

                APTS_DOEPIReqWrapper oWrap = mapDigitalOrderWrapper.get(interfaceLogId);

                if (oWrap != NULL && oWrap.OrderLineItems != null) {

                    //Loop EPIOrderLineItems
                    for (APTS_DOEPIReqWrapper.EPIOrderLI oEPILI : oWrap.OrderLineItems) {
                        if ('Digital' == oWrap.Source) {
                            setProductCode.add(oEPILI.ProductCode);
                        } else {
                            setProductId.add(oEPILI.ProductId);
                        }

                        mapEPIOLI.put(oEPILI.SourceLineNumber, oEPILI);

                        if (oEPILI.Adjustments != null && !oEPILI.Adjustments.isEmpty()) {
                            mapEPIAdjustmentList.put(oEPILI.SourceLineNumber, oEPILI.Adjustments);
                        }
                    }
                }

            }

            //********* SOQL Section ***********//

            Map<String, Product2> mapProductCodes = null;
            if (!setProductCode.isEmpty()) {
                setProductCode.add(FREIGHT_CHARGE);
                mapProductCodes = getProductCodes(setProductCode);
            } else {
                mapProductCodes = new Map<String, Product2> ([SELECT id FROM Product2 WHERE Id IN :setProductId]);
            }
            //********* SOQL Section ***********//


            for (Id interfaceLogId : mapLogIdNewOrders.keySet()) {
                Apttus_Config2__Order__c oNewOrder = mapLogIdNewOrders.get(interfaceLogId);
                APTS_DOEPIReqWrapper oWrap = mapDigitalOrderWrapper.get(interfaceLogId);

                if (oNewOrder.Id != null && oWrap != null) {

                    try {

                        //create cart
                        Id cartId = APTS_OrderUtils.createCart(oNewOrder.Id);

                        if (DIGITAL.equalsIgnoreCase(oWrap.Source)) {
                            addressLst = addAddress(oNewOrder.Id, oWrap);

                            // v103++<<
                            Boolean FreeFreightcharge = APTS_OrderUtils.checkfreefreight(cartId);
                            if (!FreeFreightcharge) {
                                APTS_DOEPIReqWrapper.EPIOrderLI oLI = new APTS_DOEPIReqWrapper.EPIOrderLI();
                                oLI.ProductCode = FREIGHT_CHARGE;
                                oLI.Quantity = 1;
                                oWrap.OrderLineItems.add(oLI);
                            }
                            // v103 -->>
                        }

                        //add products
                        if (cartId != null) {
                            addProductsToCart(oNewOrder.Id, cartId, oWrap, queue, mapProductCodes, mapEPIAdjustmentList,mapInterfacelog);
                            repriceCart(cartId);
                            APTS_CERUtility.applyBPO(cartId,true); 
                             repriceCart(cartId);
                            //save configuration
                            Apttus_Config2__ProductConfiguration__c cartObj = APTS_OrderUtils.saveCart(cartId);
                            listCartToSave.add(cartObj);
                        }
                        // ++ >> Akanksha- Added code for rest parts

                    } catch (Exception ex) {
                        throw ex;
                    }
                }
            }

            if (addressLst != null && addressLst.size() > 0) {
                Database.insert(addressLst, false);
            }

            if (listCartToSave != null && !listCartToSave.isEmpty()) {
                Database.update(listCartToSave);
            }

        } catch (Exception cartEx) {
            throw cartEx;
        }

        return mapEPIOLI;
    }

    public static Boolean repriceCart(Id cartId) {
        Boolean isPricePending = true;
        Integer cnt = 0;
        String sPriceBatchSize = System.Label.APTS_Digital_Batch_Pricing_Size;
        Integer iPriceBatchSize = sPriceBatchSize != null ? Integer.valueOf(sPriceBatchSize) : 1;

        while (isPricePending) {
            APTS_AdjustmentLineItemCallback.setIsDisabled(true);
            isPricePending = APTS_OrderUtils.repriceCart(cartId);

            //price in loop until n time(s) to avoid "too many SOQL error"
            cnt ++;
            if (!isPricePending || cnt > iPriceBatchSize) {
                break;
            }
        }

        return isPricePending;
    }

    public static Boolean finalizeCart(Boolean isPricingPending,Id cartId,Map<String, Id> mapInterface) {
        Boolean isSuccess = FALSE;

        try {

            if (isPricingPending) {
                isPricingPending = APTS_DigitalOrderBatchHelper.repriceCart(cartId);
            }
            if (!isPricingPending) {            
                //Check if all line items have pricelistItem associated with it
                //V109 ++ <<
                boolean bProceedWithFinalize = checkIfReadyToFinalise(cartId,mapInterface);
                if(bProceedWithFinalize) //V109 ++ >>
                {
                    //Finalize
                    APTS_OrderUtils.finalizeCart(cartId);
                    //Syncronize
                    isSuccess = APTS_OrderUtils.syncCart(cartId);
                }
            } else {
                System.enqueueJob(new APTS_RepriceFinalizationQueue(cartId, 'Digital', 'Pricing'));
            }

        } catch (Exception e) {
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', cartId, 'OM', false, true, null, true);

        }

        return isSuccess;
    }

    /** Method : updateOLIAndsubmit
    ** Description : method would update OrderLineItem with custom fields
    **/
    public static void updateOLIAndsubmit(Group queue, Set<Id> setOrderId, Map<String, APTS_DOEPIReqWrapper.EPIOrderLI> mapEPIOLI, Map<String, Id> mapInterface) {
        List<APTS_Order_Error_Log__c> listErrorLog = new List<APTS_Order_Error_Log__c>();

        try {
            Boolean isPriceDiff = FALSE;
            Boolean isProspect = FALSE;
            Boolean hasPOExpired = FALSE;
            Decimal totalInEPI = 0.000;
            Decimal totalInApttus = 0.000;
            Decimal totalDiff = 0.000;
            Boolean isNotValidAccount = FALSE;
            Boolean isOrderEndPast= FALSE;//v111
            Boolean bRestrictedSalesOrg = FALSE; //V112 ++ <<>>

            List<sObject> listToUpdate = new List<sObject>();

            if (mapEPIOLI != null) {
                for (Apttus_Config2__OrderLineItem__c oli : [SELECT id, APTS_Source_Line_Number__c
                        FROM Apttus_Config2__OrderLineItem__c
                        WHERE Apttus_Config2__OrderId__c IN :setOrderId
                                                            ]) {

                    APTS_DOEPIReqWrapper.EPIOrderLI oEPILineItem = mapEPIOLI.get(oli.APTS_Source_Line_Number__c);

                    if (oEPILineItem != null) {
                        //Only for Digital Order
                        oli.APTS_Ext_Line_Item_Adjustment_Amount__c = oEPILineItem.LineItemAdjustmentAmount;
                        oli.APTS_External_Line_Item_List_Price__c = oEPILineItem.LineItemListPrice;
                        oli.APTS_External_Line_Item_VAT_Amount__c = oEPILineItem.LineItemVATAmount;
                        oli.APTS_External_Line_Item_Adjusted_Price__c = oEPILineItem.LineItemAdustedPrice;
                        oli.APTS_External_Line_Item_Tax_Amount__c = oEPILineItem.LineItemTaxAmount;

                        //updated for Routesales & Operating Orders
                        oli.APTS_Reason_Code__c = oEPILineItem.ReasonCode;

                        listToUpdate.add(oli);
                    }

                }
            }


            Set<Id> setOrderToSubmit = new Set<Id>();
            for (Apttus_Config2__Order__c oId : [SELECT id, OwnerId, APTS_Source_Order_Number__c, APTS_Order_Type__c, APTS_Order_Sub_Type__c,
                                                 APTS_Adjusted_net_price__c, APTS_External_Total_Order_Amount__c,
                                                 APTS_External_Total_Adjusted_Price__c, APTS_External_Total_Shipping_costs__c,
                                                 APTS_External_Total_Order_Adjustment__c, Apttus_Config2__PONumber__c,
                                                 Apttus_Config2__SoldToAccountId__c,
                                                 Apttus_Config2__SoldToAccountId__r.SAP_Customer_ID__c,
                                                 Apttus_Config2__SoldToAccountId__r.Account_Status__c,Apttus_CMConfig__AgreementId__r.Apttus__Contract_End_Date__c,
                                                 APTS_Sales_Organization__c //V112 ++ <<>>
                                                 FROM Apttus_Config2__Order__c
                                                 WHERE Id IN :setOrderId
                                                ]) {
                isPriceDiff = FALSE;
                isProspect = FALSE;
                hasPOExpired = FALSE;
                isNotValidAccount = FALSE;
                totalInEPI = 0.000;
                totalInApttus = 0.000;
                totalDiff = 0.000;
                bRestrictedSalesOrg = FALSE; //V112 ++ <<>>
                //v111
                isOrderEndPast=FALSE;
                isOrderEndPast= oId.Apttus_CMConfig__AgreementId__r.Apttus__Contract_End_Date__c < system.today();

                //prospect customer
                isProspect = oId.Apttus_Config2__SoldToAccountId__r == null ||  oId.Apttus_Config2__SoldToAccountId__r.SAP_Customer_ID__c == NULL  ? true : false;

                //PO validation
                hasPOExpired = APTS_OrderConstants.PO_HAS_EXPIRED.equalsIgnoreCase(oId.Apttus_Config2__PONumber__c) ? true : false;

                //pricing validation in case of digital order
                if (SUB_TYPE_DIGITAL.equalsIgnoreCase(oId.APTS_Order_Sub_Type__c)) {
                    totalInEPI += oId.APTS_External_Total_Adjusted_Price__c != null ? oId.APTS_External_Total_Adjusted_Price__c : 0;
                    totalInEPI += oId.APTS_External_Total_Shipping_costs__c != null ? oId.APTS_External_Total_Shipping_costs__c : 0;
                    totalInEPI -= oId.APTS_External_Total_Order_Adjustment__c != null ? oId.APTS_External_Total_Order_Adjustment__c : 0;
                    totalInApttus = oId.APTS_Adjusted_net_price__c != null ? oId.APTS_Adjusted_net_price__c : 0;
                    totalDiff = Math.abs(totalInEPI - totalInApttus);
                    isPriceDiff = totalInApttus < 0 || totalInEPI < 0 || totalDiff >= PRICING_DIFF_PRECISION_VALUE ? true : false;
                }

                //account status validation
                isNotValidAccount = oId.Apttus_Config2__SoldToAccountId__c == null || oId.Apttus_Config2__SoldToAccountId__r.Account_Status__c != 'Valid' ? true : false;
                //V112 ++ << - Stop the Auto order submission for Germany
                if (SUB_TYPE_DIGITAL.equalsIgnoreCase(oId.APTS_Order_Sub_Type__c)) {
                    bRestrictedSalesOrg = (oId.APTS_Sales_Organization__c == 'SAP_6712');
                }//V112 ++ >>

                if (isProspect || hasPOExpired || isPriceDiff || isNotValidAccount ||isOrderEndPast || bRestrictedSalesOrg) {
                    oId.OwnerId = queue.Id;
                    listToUpdate.add(oId);
                    //v111 ++<<
                    String sErrMsg = isOrderEndPast? 'The agreement end date is in the past, please renew the agreement' : null;
                    //v111 ++>>
                    sErrMsg = sErrMsg == null && isProspect ? 'Prospect Customer' : sErrMsg;
                    sErrMsg = sErrMsg == null && hasPOExpired ? 'PO Expired' : sErrMsg;
                    sErrMsg = sErrMsg == null && isNotValidAccount ? 'Account Status Not Valid' : sErrMsg;
                    sErrMsg = sErrMsg == null && isPriceDiff ? 'Total miss-match' : sErrMsg;
                    sErrMsg = bRestrictedSalesOrg ? (sErrMsg == null ? 'German webshop order' : sErrMsg + '; German webshop order') : sErrMsg; //V112 ++ <<>>
                    APTS_Order_Error_Log__c oErrLog = createErrorLog(sErrMsg, oId.APTS_Source_Order_Number__c, NULL, oId.id, NULL,mapInterface != null && mapInterface.containskey(oId.APTS_Source_Order_Number__c) ? mapInterface.get(oId.APTS_Source_Order_Number__c) : null, queue);
                    if (oErrLog != null) {
                        listErrorLog.add(oErrLog);
                    }
                } else {
                    setOrderToSubmit.add(oId.id);
                }
            }
            if (!listToUpdate.isEmpty()) {
                APTS_OrderUtils.stopOrderLineItemTrigger();
                Database.update(listToUpdate, false);
                APTS_OrderUtils.startOrderLineItemTrigger();

                if (!setOrderToSubmit.isEmpty()) {
                    APTS_OrderUtils.submitMultipleOrders(setOrderToSubmit);
                }
            }


        } catch (Exception oEx) {
            APTS_Order_Error_Log__c oErrLog = createErrorLog(oEx.getStackTraceString(), NULL, NULL, NULL, NULL,NULL, queue);
            if (oErrLog != null) {
                listErrorLog.add(oErrLog);
            }

            APTS_CustomLogging.createErrorLog(oEx.getTypeName(), 'Apex', oEx.getStackTraceString() , 'Order', NULL , 'OM', false, true, null, true);

        } finally {

            if (!listErrorLog.isEmpty()) {
                Database.insert(listErrorLog, false);
            }
        }
    }

    /** Method : getStatusInterfaceLog
    ** Description : method returns current status of Interface log
    **/
    public static List<APTS_Order_Interface_Log__c> getStatusInterfaceLog(Group queue, Set<Id> setInterfaceId) {
        List<APTS_Order_Interface_Log__c> listLog = new List<APTS_Order_Interface_Log__c>();

        try {
            Id logid;
            APTS_Order_Interface_Log__c olg;
            Map<String, Id> mapInterface = new Map<String, Id>();
            Map<String, Boolean> mapOLIExists = new Map<String, Boolean>();

            //find source order number
            for (APTS_Order_Interface_Log__c olog : [SELECT id,  APTS_SourceOrderNumber__c FROM APTS_Order_Interface_Log__c WHERE Id IN :setInterfaceId]) {
                mapInterface.put(olog.APTS_SourceOrderNumber__c, olog.Id);
            }

            /*if (isOrderCreation) {
                //find order line item with source number
                for (Apttus_Config2__Order__c oOrder : [SELECT Id, APTS_Source_Order_Number__c FROM Apttus_Config2__Order__c
                                                        WHERE APTS_Source_Order_Number__c IN :mapInterface.keySet() AND APTS_Source_Order_Number__c != null]) {

                    if (oli.Apttus_Config2__OrderId__r != null && !mapOLIExists.containsKey(oli.Apttus_Config2__OrderId__r.APTS_Source_Order_Number__c)) {
                        mapOLIExists.put(oOrder.APTS_Source_Order_Number__c, true);
                    }
                }
            } else {*/
            //find order line item with source number
            for (Apttus_Config2__OrderLineItem__c oli : [SELECT id, Apttus_Config2__OrderId__r.APTS_Source_Order_Number__c
                    FROM Apttus_Config2__OrderLineItem__c
                    WHERE Apttus_Config2__OrderId__r.APTS_Source_Order_Number__c IN :mapInterface.keySet()
                    AND Apttus_Config2__OrderId__r.APTS_Source_Order_Number__c != null]) {

                if (oli.Apttus_Config2__OrderId__r != null && !mapOLIExists.containsKey(oli.Apttus_Config2__OrderId__r.APTS_Source_Order_Number__c)) {
                    mapOLIExists.put(oli.Apttus_Config2__OrderId__r.APTS_Source_Order_Number__c, true);
                }
            }
            //}

            //Change Order Interface Log to completed
            for (String srn : mapInterface.keySet()) {
                logid  = mapInterface.get(srn);
                olg = new APTS_Order_Interface_Log__c();
                olg.Id = logid;
                olg.APTS_Status__c = mapOLIExists.containsKey(srn) ? 'Completed' : 'Error';
                listLog.add(olg);
            }

        } catch (Exception ex) {
            throw ex;
        }

        return listLog;
    }


    /** Method : addAddress
    ** Description : method returns onetime address object
    **/
    private static List<APTS_OneTimeAddress__c> addAddress(ID digiOrderID, APTS_DOEPIReqWrapper objWrapper) {
        List<APTS_OneTimeAddress__c> addressLst = new List<APTS_OneTimeAddress__c>();
        APTS_OneTimeAddress__c objShipTo = STR_YES.equalsIgnoreCase(objWrapper.ShipToOverride) ? getOneTimeAddress(digiOrderID, 'ShipTo', objWrapper) : null;
        if (objShipTo != null) {
            addressLst.add(objShipTo);
        }

        APTS_OneTimeAddress__c objSoldTo = STR_YES.equalsIgnoreCase(objWrapper.OneTimeCustomer) ? getOneTimeAddress(digiOrderID, 'SoldTo', objWrapper) : null;
        if (objSoldTo != null) {
            addressLst.add(objSoldTo);
        }

        APTS_OneTimeAddress__c objPayerTo = STR_YES.equalsIgnoreCase(objWrapper.OneTimeCustomer) ? getOneTimeAddress(digiOrderID, 'PayerTo', objWrapper) : null;
        if (objPayerTo != null) {
            addressLst.add(objPayerTo);
        }

        APTS_OneTimeAddress__c objBillTo = STR_YES.equalsIgnoreCase(objWrapper.BillToOverride) ? getOneTimeAddress(digiOrderID, 'BillTo', objWrapper) : null;
        if (objBillTo != null) {
            addressLst.add(objBillTo);
        }

        return addressLst;
    }


    /** Method : getOneTimeAddress
    ** Description : method returns onetime address object
    **/
    private static APTS_OneTimeAddress__c getOneTimeAddress(ID digiOrderID, String sAddType, APTS_DOEPIReqWrapper objWrapper) {
        APTS_OneTimeAddress__c objOTA = new APTS_OneTimeAddress__c();
        Boolean isShipToFields = 'ShipTo'.equalsIgnoreCase(sAddType) || 'SoldTo'.equalsIgnoreCase(sAddType) || 'PayerTo'.equalsIgnoreCase(sAddType) ? true : false;

        objOTA.APTS_Order_ID__c = digiOrderID;
        objOTA.APTS_One_Time_City__c = isShipToFields ? objWrapper.ShipToCity : objWrapper.BillToCity;
        objOTA.APTS_One_Time_Country__c = isShipToFields ? objWrapper.ShipToCountry : objWrapper.BillToCountry;
        objOTA.APTS_One_Time_Postal_Code__c = isShipToFields ? objWrapper.ShipToPostalCode : objWrapper.BillToPostalCode;
        objOTA.APTS_One_Time_Street__c = isShipToFields ? objWrapper.ShipToStreetOnly : objWrapper.BillToStreetOnly;
        objOTA.APTS_One_Time_House_Number__c = isShipToFields ? objWrapper.ShipToHouseNumber : objWrapper.BillToHouseNumber;
        objOTA.APTS_One_Time_House_Number_Supplement__c = isShipToFields ? objWrapper.ShipToHouseNumberSupplement : objWrapper.BillToHouseNumberSupplement;
        objOTA.APTS_One_Time_Company_Name__c = isShipToFields ? objWrapper.ShipToCompanyName : objWrapper.BillToCompanyName;
        objOTA.APTS_One_Time_Contact_Name__c = isShipToFields ? objWrapper.OneTimeContactName :  objWrapper.BillToContactName;
        objOTA.APTS_One_Time_Email__c = isShipToFields ? objWrapper.OneTimeEmail : objWrapper.BillToEmail;
        objOTA.APS_Address_Type__c = isShipToFields && 'SoldTo'.equalsIgnoreCase(sAddType) ?  'AG' :  null;
        objOTA.APS_Address_Type__c = isShipToFields && 'ShipTo'.equalsIgnoreCase(sAddType) ?  'WE' : objOTA.APS_Address_Type__c;
        objOTA.APS_Address_Type__c = isShipToFields && 'PayerTo'.equalsIgnoreCase(sAddType) ?  'RG' : objOTA.APS_Address_Type__c;
        objOTA.APS_Address_Type__c = !isShipToFields ?  'RE' : objOTA.APS_Address_Type__c;

        return objOTA;
    }


    public static List<Decimal> addProductsToCart(Id newOrderId, Id cartId, APTS_DOEPIReqWrapper oWrap, Group queue, Map<String, Product2> mapProductCodes, Map<String, List<APTS_DOEPIReqWrapper.EPIAdjustmentLI>> mapEPIAdjustmentList,Map<String,ID> mapInterfacelog) {
        //invoke multiproduct api
        APTS_AdjustmentLineItemCallback.setIsDisabled(true);
        List<Decimal> listLineNumbers = addProductsViaAPI(newOrderId, cartId, oWrap, mapProductCodes, queue,mapInterfacelog);
        APTS_AdjustmentLineItemCallback.setIsDisabled(false);

        //add adjustment
        if (listLineNumbers != NULL && !listLineNumbers.isEmpty()) {

            //adjustments
            Apttus_CPQApi.CPQ.AdjustmentItemCollDO adjItemColl;
            List<Apttus_CPQApi.CPQ.AdjustmentItemCollDO> adjItemColls = new List< Apttus_CPQApi.CPQ.AdjustmentItemCollDO>();

            //get CER records
            Map<ID, List<APTS_Contract_Entitlement_Repository__c>> cerprdmap = APTS_CERUtility.getContractedProductsWithDiscounts(oWrap.SalesforceAccountID, cartId, FALSE);


            for (Apttus_Config2__LineItem__c lineItem : [SELECT   Id, Apttus_Config2__LineType__c,
                    Apttus_Config2__ProductId__c, Apttus_Config2__OptionId__c, APTS_Source_Line_Number__c,
                    Apttus_Config2__SellingUom__c
                    FROM Apttus_Config2__LineItem__c
                    WHERE Apttus_Config2__ConfigurationId__c = : cartId]) {

                adjItemColl = new  Apttus_CPQApi.CPQ.AdjustmentItemCollDO();
                adjItemColl.LineItemId = lineItem.Id;
                adjItemColl.AdjustmentItems = new List<Apttus_Config2__AdjustmentLineItem__c>();

                // Add CER Adjustments
                List<String> listAdjAppliesTo;
                Map<String, Apttus_Config2__AdjustmentLineItem__c> mapTemp = APTS_AdjustmentLineItemCallback.getCERAdjustmentLineItems('Order', lineItem, cerprdmap);
                if (mapTemp != null && !mapTemp.isEmpty() && mapTemp.values() != null) {
                    listAdjAppliesTo = new List<string>();
                    for (Apttus_Config2__AdjustmentLineItem__c adj : mapTemp.values()) {
                        listAdjAppliesTo.add(adj.Apttus_Config2__Bucket__c);
                    }
                    adjItemColl.AdjustmentItems.addAll(mapTemp.values());
                }

                // Add EPI adjustments
                if (mapEPIAdjustmentList != null && mapEPIAdjustmentList.containsKey(lineItem.APTS_Source_Line_Number__c)) {
                    List<APTS_DOEPIReqWrapper.EPIAdjustmentLI> listEPIAdjustments = mapEPIAdjustmentList.get(lineItem.APTS_Source_Line_Number__c);
                    String stype = 'Digital' == oWrap.Source ? 'Digital' : APTS_OrderConstants.RSOAPP ;
                    String sadjtype = 'Digital' == oWrap.Source ? APTS_OrderConstants.DISCOUNT_AMOUNT : APTS_OrderConstants.DISCOUNT;
                    List<Apttus_Config2__AdjustmentLineItem__c> listTempAdjustment = APTS_AdjustmentLineItemCallback.getDigitalAdjustmentLineItems(stype, 'TPR', sadjtype, lineItem, listAdjAppliesTo, listEPIAdjustments);

                    if (listTempAdjustment != null && !listTempAdjustment.isEmpty()) {
                        adjItemColl.AdjustmentItems.addAll(listTempAdjustment);
                    }
                }

                if (adjItemColl.AdjustmentItems != null && !adjItemColl.AdjustmentItems.isEmpty()) {
                    adjItemColls.add(adjItemColl);
                }

            }

            Apttus_CPQApi.CPQ.UpdateManualAdjustmentsRequestDO request = new Apttus_CPQApi.CPQ.UpdateManualAdjustmentsRequestDO();
            request.CartId = cartId;
            request.AdjustmentItemColls = adjItemColls;

            if (!Test.isRunningTest()) {
                //if adjustments available invoke API to add them
                if (adjItemColls != null && !adjItemColls.isEmpty() ) {
                    Apttus_CPQApi.CPQ.UpdateManualAdjustmentsResponseDO result =  Apttus_CPQApi.CPQWebService.updateManualAdjustmentsForCart(request);
                }

                //invoke constraint rules
                // v103++<< - Comment out the Constraint Rule API Call. Instead call manually.
                /*   Apttus_CPQApi.CPQWebService.associateConstraintRules(cartId, null);
                    Apttus_CPQApi.CPQWebService.applyConstraintRules(cartId, false); */
                // v103 -->>
                
            }
        }
        
        return listLineNumbers;
    }

    private static List<Decimal> addProductsViaAPI(Id orderId, Id cartId, APTS_DOEPIReqWrapper objWrapper, Map<String, Product2> mapProducts, Group queue,Map<String,ID> mapInterfacelog) {
        List<Decimal> listLineNumbers;
        List<Apttus_CPQApi.CPQ.SelectedProductDO> listStandaloneProduct = getProducts(orderId, objWrapper, mapProducts,mapInterfacelog,queue);

        if (!listStandaloneProduct.isEmpty()) {
            try {
                Apttus_CPQApi.CPQ.AddMultiProductResponseDO response = APTS_OrderUtils.addMultiProducts(listStandaloneProduct, cartId);
                listLineNumbers = response.LineNumbers != NULL && !response.LineNumbers.isEmpty() ?  response.LineNumbers : listLineNumbers;
            } catch (Exception ex) {

            }
        }

        return listLineNumbers;
    }

    private static List<Apttus_CPQApi.CPQ.SelectedProductDO> getProducts(Id orderId, APTS_DOEPIReqWrapper objWrapper, Map<String, Product2> mapProducts,Map<String,Id> mapInterfacelog, Group queue) {
        Apttus_CPQApi.CPQ.SelectedProductDO sProd = NULL;
        List<Apttus_CPQApi.CPQ.SelectedProductDO> listStandaloneProduct = new List<Apttus_CPQApi.CPQ.SelectedProductDO>();
        List<APTS_Order_Error_Log__c> listErrlog = new List<APTS_Order_Error_Log__c>();
       
        for (APTS_DOEPIReqWrapper.EPIOrderLI oEPILI : objWrapper.OrderLineItems) {
            Product2 oProd = 'Digital' == objWrapper.Source ? mapProducts.get(oEPILI.ProductCode) : mapProducts.get(oEPILI.ProductId);

            if (oProd != NULL) {
                Apttus_Config2__LineItem__c oLI = getLineItemWrapper(oProd.Id, oEPILI);
                sProd = APTS_OrderUtils.addStandaloneProductWithQuantity(oLI, Integer.valueOf(oEPILI.Quantity));
                if (sProd != NULL) {
                    listStandaloneProduct.add(sProd);
                }
            } else {
                APTS_Order_Error_Log__c oErrLog = createErrorLog('Exception in OrderLineItem update ', objWrapper.SourceOrderNumber, oEPILI.SourceLineNumber, orderId, NULL,mapInterfacelog != null && mapInterfacelog.containskey(objWrapper.SourceOrderNumber) ? mapInterfacelog.get(objWrapper.SourceOrderNumber) : null, queue);
                listErrlog.add(oErrLog);
            }
        }

        if (!listErrlog.isEmpty()) {
            Database.insert(listErrlog, FALSE);
        }

        return listStandaloneProduct;
    }

    private static Apttus_Config2__LineItem__c getLineItemWrapper(Id productId, APTS_DOEPIReqWrapper.EPIOrderLI oEPILI) {
        Apttus_Config2__LineItem__c oLineItem = new Apttus_Config2__LineItem__c();
        try {
            oLineItem.Apttus_Config2__StartDate__c = System.today();
            oLineItem.Apttus_Config2__EndDate__c = System.today();
            oLineItem.Apttus_Config2__Comments__c = 'Digital order';
            oLineItem.Apttus_Config2__ProductId__c = productId;
            oLineItem.Apttus_Config2__SellingUom__c = getSellingUOM(oEPILI.SellingUnitofMeasure);
            oLineItem.Apttus_Config2__Quantity__c = oEPILI.Quantity;
            oLineItem.APTS_Source_Line_Number__c = oEPILI.SourceLineNumber;
        } catch (Exception oEx) {
            APTS_CustomLogging.createErrorLog(oEx.getTypeName(), 'Apex', oEx.getStackTraceString() , 'Order', oEPILI.SourceLineNumber, 'OM', false, true, null, true);
            throw oEx;
        }
        return oLineItem;
    }

    public static Group getCSQueue() {
        Group csque = [SELECT Id FROM Group WHERE Name = :APTS_OrderConstants.CS_QUEUE and Type = 'Queue' LIMIT 1];
        return csque;
    }

    private static Map<String, Product2> getProductCodes(Set<String> setProductCode) {
        Map<String, Product2> mapProductCodes = new Map<String, Product2>();
        for (Product2 oProd :  [SELECT id, ProductCode, APTS_Replaced_by__c FROM product2 WHERE ProductCode = : setProductCode or APTS_Replaced_by__c = : setProductCode ]) {
            if (!setProductCode.contains(oProd.ProductCode) && oProd.APTS_Replaced_by__c != null) {
                mapProductCodes.put(oProd.APTS_Replaced_by__c , oProd);
            } else {
                mapProductCodes.put(oProd.ProductCode, oProd);
            }
        }
        return mapProductCodes;
    }

    private static string getSellingUOM(string value) {
        string label = null;
        try {

            if (value != null) {

                for (PickListEntry pe : Apttus_Config2__LineItem__c.Apttus_Config2__SellingUom__c.getDescribe().getPicklistValues()) {
                    //check if value is picklist API, sent as it is
                    label = value.equalsIgnoreCase(pe.getValue()) ? value : null;
                    //check if value is picklist Label than set API
                    label = label == null && value.equalsIgnoreCase(pe.getLabel()) ? pe.getValue() : label;

                    if (label != null) {
                        break;
                    }
                }

            }
        } catch (Exception ex) {
            throw ex;
        }
        return label;
    }
    //V109 ++ <<
    private static boolean checkIfReadyToFinalise(Id cartID,Map<String,Id> mapInterface)
    {
          boolean bAllPLI = true;
          ID orderID = null;
          string srnNumber = null;

         //Check if PLI exits on all Line Items. 
          if(cartID != null)            { 

                         
                //Get the list of line items
               for(Apttus_Config2__LineItem__c objLI : [SELECT Id, Apttus_Config2__PriceListItemId__c, Apttus_Config2__ConfigurationId__c, Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__c, Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Source_Order_Number__c FROM Apttus_Config2__LineItem__c WHERE Apttus_Config2__ConfigurationId__c =: cartID])
               {
                        if(string.IsBlank(objLI.Apttus_Config2__PriceListItemId__c))
                        {
                            orderID = objLI.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__c;
                            srnNumber = objLI.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Source_Order_Number__c;
                         
                            //Do not proceed with Finalization                           
                            bAllPLI = false;                           
                        }
               }  
               if(!bAllPLI)
               {          
                   Group queue = APTS_DigitalOrderBatchHelper.getCSQueue();   
                   String srn = orderID != null ? srnNumber : '';
                  
                   APTS_Order_Error_Log__c oErrLog = APTS_DigitalOrderBatchHelper.createErrorLog('Cart line items configured without Price List Item', srn, NULL, orderID, NULL,mapInterface != null && mapInterface.containskey(srn) ? mapInterface.get(srn):null, queue);
                    if (oErrLog != null) {
                       Database.Insert(oErrLog, false);
                    }
                    Apttus_Config2__Order__c oOrder = new Apttus_Config2__Order__c();
                    oOrder.Id = orderID;
                    oOrder.OwnerId = queue.Id;
                    if (oOrder != null) {
                       Database.Update(oOrder, false);
                    }
                    
               }
            }  
            return bAllPLI;                 
    }
    //V109 ++ >>
}