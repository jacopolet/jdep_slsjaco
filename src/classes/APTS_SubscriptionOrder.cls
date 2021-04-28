/*************************************************************
@Name: APTS_SubscriptionOrder
@Author: Neev Shah
@CreateDate: 01-03-2018
@Description: Subscription Order class
@UsedBy:
******************************************************************
//V100 14-Oct-2018 Aarthi Pitchai - Updated existing logic to default primary contact Id on Subscription Order
******************************************************************
@ModifiedBy : Neev Shah
@ModifiedDate : 7-1-2019
@Description : Re-written with optimized code. This class will have act as utils class for APTS_SubscriptionOrderBatch and APTS_SubscriptionOrderFinalizeBatch
******************************************************************/
//V101 14-Oct-2019 Aarthi Pitchai QTCFLEX1-1451 Remove the logic to set customer comments and picking list text
//v102 27-Aug-2020 DQ-2949 Sneha Jaiwant-paasing extra parameter  in createErrorLog

public with sharing class APTS_SubscriptionOrder {
    private static final String FREQ_DAILY = 'Daily';
    private static final String FREQ_WEEKLY = 'Weekly';
    private static final String FREQ_MONTHLY = 'Monthly';
    private static final String FREQ_QUARTERLY = 'Quarterly';
    private static final String FREQ_HALF_YEARLY = 'Half-yearly';
    private static final String FREQ_YEARLY = 'Yearly';
    private static final String STANDARD_ORDER = 'Standard Order';
    private static final String SUBSCRIPTION_ORDER = 'Subscription Order';
    private static final String SUBSCRIPTION_ORDER_EXCEPTION = 'Subscription Order Exception';
    private static final String AFFECTED_FIELD = ' affected fields : ';
    private static final String YES = 'Yes';
    private static final String TASKCRUD = 'Task';
    private static final String STR_COMPLETED = 'Completed';
    private static final String XA01 = System.Label.APTS_XA01;
    private static final String TYPE_STANDARD = System.Label.APTS_Standard;
    private static final String TASK_OPEN = System.Label.APTS_Open;
    private static final String SUBSCRIPTION_TASK_GUIDANCE = System.Label.APTS_Subscription_Task_Guidance;
    private static final String EMAIL = System.Label.APTS_Email;
    private static final Date sysDT = System.today();


    /** Method Name :getAgreements
        * Description : Method would check if subscription order is required or not
        **/
    public static Boolean checkSubscriptionOrderRequired(Apttus__AgreementLineItem__c agLineItem) {
        Boolean isRequired = TRUE;

        try {

            if (agLineItem.Apttus_CMConfig__AttributeValueId__c == null || agLineItem.Apttus_CMConfig__AttributeValueId__r.APTS_Order_Frequency__c == null) {
                return false;
            }

            if (agLineItem != NULL && agLineItem.APTS_Last_Processed_for_Subscription__c != NULL && String.isNotBlank(agLineItem.Apttus_CMConfig__AttributeValueId__c)) {
                Date dtLastProcessed = agLineItem.APTS_Last_Processed_for_Subscription__c.date();

                isRequired = FREQ_DAILY.equalsIgnoreCase(agLineItem.Apttus_CMConfig__AttributeValueId__r.APTS_Order_Frequency__c) && dtLastProcessed.daysBetween(System.today()) < 1 ? FALSE : isRequired;
                isRequired = FREQ_WEEKLY.equalsIgnoreCase(agLineItem.Apttus_CMConfig__AttributeValueId__r.APTS_Order_Frequency__c) && dtLastProcessed.daysBetween(System.today()) < 7 ? FALSE : isRequired;
                isRequired = FREQ_MONTHLY.equalsIgnoreCase(agLineItem.Apttus_CMConfig__AttributeValueId__r.APTS_Order_Frequency__c) && dtLastProcessed.monthsBetween(System.today()) < 1 ? FALSE : isRequired;
                isRequired = FREQ_QUARTERLY.equalsIgnoreCase(agLineItem.Apttus_CMConfig__AttributeValueId__r.APTS_Order_Frequency__c) && dtLastProcessed.monthsBetween(System.today()) < 3 ?  FALSE : isRequired;
                isRequired = FREQ_HALF_YEARLY.equalsIgnoreCase(agLineItem.Apttus_CMConfig__AttributeValueId__r.APTS_Order_Frequency__c) && dtLastProcessed.monthsBetween(System.today()) < 6 ?  FALSE : isRequired;
                isRequired = FREQ_YEARLY.equalsIgnoreCase(agLineItem.Apttus_CMConfig__AttributeValueId__r.APTS_Order_Frequency__c) && dtLastProcessed.monthsBetween(System.today()) < 12 ?  FALSE : isRequired;
            }

        } catch (Exception ex) {
            throw ex;
        }

        return isRequired;
    }

    /** Method Name :getAgreements
        * Description : Method would return map of agreements
        **/
    public static Map<Id, Apttus__APTS_Agreement__c> getAgreements(final Set<Id> setAgreementIds) {
        Map<Id, Apttus__APTS_Agreement__c> mapAgreementTmp;

        try {

            mapAgreementTmp = new Map<Id, Apttus__APTS_Agreement__c>(
                [SELECT Id, Name, RecordTypeId,  APTS_Language__c, APTS_Location__c,
                 Apttus_CMConfig__PONumber__c, Apttus_CMConfig__PaymentTermId__c,
                 Apttus_CMConfig__PriceListId__c, Apttus_CMConfig__BillingPreferenceId__c,
                 Apttus__Contract_Start_Date__c, Apttus__Contract_End_Date__c, Apttus__Primary_Contact__c,
                 Apttus__Account__c, Apttus_CMConfig__BillToAccountId__c, APTS_Bill_to_Party_Ingredients__c,
                 APTS_Payer_Ingredients__c, APTS_Bill_to_Party_MachServ__c, APTS_Payer_Machines_Services__c,
                 Apttus__Account__r.APTS_Price_List__c, Apttus__Account__r.SAP_Customer_ID__c,
                 Apttus__Account__r.Division__c, Apttus__Account__r.Bill_To_Payer_Account__c,
                 Apttus__Account__r.Language__c, Apttus__Account__r.Customer_Relations_1__c,
                 Apttus__Account__r.Partner__c, Apttus__Account__r.Sales_Organization__c,
                 Apttus__Account__r.OwnerId, Apttus__Account__r.Distribution_Channel__c,
                 Apttus__Account__r.Billing_header_text__c,
                 APTS_Check_on_Account_Machines__c,APTS_Check_on_Account_Ingredients__c
                 FROM Apttus__APTS_Agreement__c WHERE Id = :setAgreementIds
                         AND Apttus__Contract_Start_Date__c <= :sysDT
                         AND Apttus__Contract_End_Date__c >= :sysDT]);

        } catch (Exception ex) {
            throw ex;
        }

        return mapAgreementTmp;
    }

    /** Method Name :getAgreements
        * Description : Method would return map of Account from list of Agreements
        **/
    public static Map<Id, Account> getAccountsFromAgreements(List<Apttus__APTS_Agreement__c> listAgreementsTmp) {
        Map<Id, Account> mapAccountTmp = new Map<Id, Account>();

        try {
            Account accountTmp;

            for (Apttus__APTS_Agreement__c agreementTmp : listAgreementsTmp) {
                accountTmp = new Account();
                accountTmp.Id = agreementTmp.Apttus__Account__c;
                accountTmp.Sales_Organization__c = agreementTmp.Apttus__Account__r.Sales_Organization__c;
                accountTmp.Partner__c = agreementTmp.Apttus__Account__r.Partner__c;
                accountTmp.Language__c = agreementTmp.Apttus__Account__r.Language__c;
                accountTmp.Division__c = agreementTmp.Apttus__Account__r.Division__c;
                accountTmp.Distribution_Channel__c = agreementTmp.Apttus__Account__r.Distribution_Channel__c;
                accountTmp.Bill_To_Payer_Account__c = agreementTmp.Apttus__Account__r.Bill_To_Payer_Account__c;
                accountTmp.APTS_Price_List__c = agreementTmp.Apttus__Account__r.APTS_Price_List__c;
                accountTmp.SAP_Customer_ID__c = agreementTmp.Apttus__Account__r.SAP_Customer_ID__c;
                accountTmp.Customer_Relations_1__c = agreementTmp.Apttus__Account__r.Customer_Relations_1__c;
                accountTmp.OwnerId = agreementTmp.Apttus__Account__r.OwnerId;
                accountTmp.Billing_header_text__c = agreementTmp.Apttus__Account__r.Billing_header_text__c;
                mapAccountTmp.put(accountTmp.Id, accountTmp);
            }

        } catch (Exception ex) {
            throw ex;
        }

        return mapAccountTmp;
    }

    /** Method Name :getAgreements
        * Description : Method would return map of contacts from set of Account Ids
        **/
    public static Map<Id, List<Contact>> getContacts(Set<Id> setAccountIds) {
        Map<Id, List<Contact>> mapContactTmp = new Map<Id, List<Contact>>();
        List<Contact> listContactsTmp;

        try {

            //default contact
            //V100 ++ <<
            //14-Oct-2018 Aarthi Pitchai - Modified the below query as part of Defect Fix #20091
            for (Contact contactTmp : [SELECT Id, AccountId, Name, Function__c, Main_Commercial_Person__c, Main_Service_Person__c
                                       FROM Contact
                                       WHERE Id IN (SELECT ContactId FROM AccountContactRelation WHERE AccountId = :setAccountIds)]) {

                listContactsTmp = mapContactTmp.get(contactTmp.AccountId);
                listContactsTmp = listContactsTmp == null ? new List<Contact>() : listContactsTmp;
                listContactsTmp.add(contactTmp);
                mapContactTmp.put(contactTmp.AccountId, listContactsTmp);

            }
        } catch (Exception ex) {
            throw ex;
        }

        return mapContactTmp;
    }

    /** Method Name :getAgreements
        * Description : Method would return map of account locations from set of Account Ids
        **/
    public static Map<Id, Apttus_Config2__AccountLocation__c> getAccountLocations(Set<Id> setAccountIds) {
        Map<Id, Apttus_Config2__AccountLocation__c> mapLocationTmp = new Map<Id, Apttus_Config2__AccountLocation__c>();

        try {

            for (Apttus_Config2__AccountLocation__c locationTmp : [SELECT Id, Apttus_Config2__AccountId__c, Apttus_Config2__AccountId__r.SAP_Customer_ID__c, SAP_Customer_ID__c,
                    Billing_header_text__c, Delivery_text__c
                    FROM Apttus_Config2__AccountLocation__c
                    WHERE Apttus_Config2__AccountId__c <> null AND Apttus_Config2__AccountId__c = :setAccountIds]) {

                if (locationTmp.SAP_Customer_ID__c == locationTmp.Apttus_Config2__AccountId__r.SAP_Customer_ID__c) {
                    mapLocationTmp.put(locationTmp.Apttus_Config2__AccountId__c, locationTmp);
                }
            }
        } catch (Exception ex) {
            throw ex;
        }

        return mapLocationTmp;
    }

    /** Method Name :getOrderHeader
        * Description : Method would return record of Order
        **/
    public static Apttus_Config2__Order__c getOrderHeader(Apttus__AgreementLineItem__c agLineItem, Map<Id, Account> mapAccountTmp, Map<Id, Apttus_Config2__AccountLocation__c> mapLocationTmp, Map<Id, Apttus__APTS_Agreement__c> mapAgreementTmp, Map<Id, List<Contact>> mapAccountContactTmp) {
        Apttus_Config2__Order__c subscriptionOrder;

        if (mapAgreementTmp == null || mapAccountTmp == null) {
            return null;
        }

        //Agreement details
        Apttus__APTS_Agreement__c agreementTmp = mapAgreementTmp.get(agLineItem.Apttus__AgreementId__c);
        //if Agreement is null, data must be corrupted so iterate next record
        if (agreementTmp != null) {
            //Account details
            Account accountTmp = mapAccountTmp.get(agreementTmp.Apttus__Account__c);
            //if Account is null, data must be corrupted so iterate next record
            if (accountTmp != null) {
                //Location details
                Apttus_Config2__AccountLocation__c locationTmp;
                if (mapLocationTmp != null) {
                    locationTmp = mapLocationTmp.get(agreementTmp.Apttus__Account__c);
                }


                //Contact details
                Map<Id, Contact> mapContactTmp;

                if (mapAccountContactTmp != null) {
                    List<Contact> listContactsTmp = mapAccountContactTmp.get(agreementTmp.Apttus__Account__c);
                    if (listContactsTmp != null) {
                        mapContactTmp = new Map<Id, Contact> (listContactsTmp);
                    }
                }

                //create Order header for Subscription Order
                subscriptionOrder = getOrderHeaderDetails(agLineItem.Id, accountTmp, agreementTmp, locationTmp, mapContactTmp);
            }
        }

        return subscriptionOrder;
    }

    /** Method Name :getOrderHeaderDetails
        * Description : Method would return record of Order
        **/
    public static Apttus_Config2__Order__c getOrderHeaderDetails(Id agLineItemIdTmp, Account accountTmp, Apttus__APTS_Agreement__c agreementTmp, Apttus_Config2__AccountLocation__c locationTmp, Map<Id, Contact> mapContactTmp) {
        Apttus_Config2__Order__c oOrder;

        try {

            if (accountTmp != null && agreementTmp != null) {
                oOrder = new Apttus_Config2__Order__c();
                oOrder.APTS_Order_Type__c = STANDARD_ORDER;
                oOrder.APTS_Order_Sub_Type__c = SUBSCRIPTION_ORDER;
                oOrder.APTS_SAP_OrderType__c = XA01;
                oOrder = APTS_OrderUtils.setOrderHeader(oOrder, accountTmp);
                oOrder = APTS_OrderUtils.setOrderHeader(oOrder, agreementTmp, accountTmp);
                oOrder.RecordTypeId = Schema.SObjectType.Apttus_Config2__Order__c.getRecordTypeInfosByName().get(STANDARD_ORDER).getRecordTypeId();
                oOrder.Apttus_Config2__OrderDate__c = System.today();

                oOrder.Apttus_Config2__BillToAccountId__c = agreementTmp.Apttus__Account__c;
                oOrder.APTS_Payer__c = agreementTmp.Apttus__Account__c;
                oOrder.Apttus_Config2__PrimaryContactId__c = agreementTmp.Apttus__Primary_Contact__c;
                oOrder.Apttus_Config2__LocationId__c = agreementTmp.APTS_Location__c;
                oOrder.Apttus_Config2__OrderStartDate__c = agreementTmp.Apttus__Contract_Start_Date__c;
                oOrder.Apttus_Config2__OrderEndDate__c = agreementTmp.Apttus__Contract_End_Date__c;
                oOrder.APTS_Order_Batch_Status__c = APTS_OrderConstants.STR_ORDER_CART_PENDING;
                oOrder.Apttus_Config2__Description__c = agLineItemIdTmp;

                //default delivery date
                //oOrder.APTS_Requested_Delivery_Date__c = APTS_OrderUtils.getRequestedDeliveryDate();

                //default location
                oOrder.Apttus_Config2__LocationId__c = oOrder.Apttus_Config2__LocationId__c == null && locationTmp != null ? locationTmp.Id : oOrder.Apttus_Config2__LocationId__c;

                //default contact
                if (oOrder.Apttus_Config2__PrimaryContactId__c == null && mapContactTmp != null) {
                    oOrder.Apttus_Config2__PrimaryContactId__c = APTS_OrderUtils.getPrimaryContactId(mapContactTmp, TYPE_STANDARD);
                }

                //extra fields
                //oOrder.APTS_Invoice_Remark__c = locationTmp != null ? locationTmp.Billing_header_text__c : oOrder.APTS_Invoice_Remark__c;
               //V101 //oOrder.APTS_Customer_Comments__c = locationTmp != null ? locationTmp.Delivery_text__c : oOrder.APTS_Customer_Comments__c;

                if (accountTmp.Billing_header_text__c != null && accountTmp.Billing_header_text__c.length() > 255) {
                    oOrder.APTS_Invoice_Remark__c = accountTmp.Billing_header_text__c.left(255);
                } else {
                    oOrder.APTS_Invoice_Remark__c = accountTmp.Billing_header_text__c;
                }
            }
        } catch (Exception ex) {
            throw ex;
        }

        return oOrder;
    }

    /** Method Name :createOrder
        * Description : Method would insert list of Orders and prepare list of error logs
        **/
    public static Database.SaveResult[] createOrder(List<Apttus_Config2__Order__c> listNewOrders) {
        Database.SaveResult[] srList;
        try {
            if (listNewOrders != null && !listNewOrders.isEmpty()) {
                srList = Database.insert(listNewOrders, false);
            }

        } catch (Exception ex) {
            throw ex;
        }

        return srList;
    }

    /** Method Name :createInsertErrorLog
        * Description : Method would return list of Error log for Order Insert
        **/
    public static List<APTS_Order_Error_Log__c> getOrderErrorLogs(Group queue, Database.SaveResult[] listOrderInsertResuneslt) {
        List<APTS_Order_Error_Log__c> listErrorLog = new List<APTS_Order_Error_Log__c>();

        try {
            String sErrMsg = '';
            APTS_Order_Error_Log__c oErrLog;

            for (Database.SaveResult sr : listOrderInsertResuneslt) {
                if (!sr.isSuccess()) {
                    sErrMsg = SUBSCRIPTION_ORDER_EXCEPTION;

                    for (Database.Error err : sr.getErrors()) {
                        sErrMsg += err.getMessage() + AFFECTED_FIELD + err.getFields();

                    }
                    //v102 passing extra parameter to createerrorlog
                    oErrLog = APTS_DigitalOrderBatchHelper.createErrorLog(sErrMsg, null, null, null, null,null, queue);
                    listErrorLog.add(oErrLog);
                }
            }
        } catch (Exception ex) {
            throw ex;
        }

        return listErrorLog;
    }

    /** Method Name :createInsertErrorLog
        * Description : Method would return list of Error log for Order Insert
        **/
    public static List<APTS_Order_Error_Log__c> createOrderErrorLogs(List<APTS_Order_Error_Log__c> listErrorLog) {

        try {
            Database.SaveResult[] saveRes1 = Database.insert(listErrorLog, false);
            String errMsg = '';

            for (Database.SaveResult sr : saveRes1) {

                for (Database.Error err : sr.getErrors()) {
                    errMsg += err.getMessage();
                }
            }

            if (String.isNotBlank(errMsg)) {
                APTS_CustomLogging.createErrorLog('Error while Order Error Log creation', 'Apex', errMsg , 'Subscription Order', null, 'OM', false, true, EMAIL, true);
            }
        } catch (Exception ex) {
            throw ex;
        }

        return listErrorLog;
    }

    /** Method Name :finalAction
        * Description : Method would do final action after subscription order has been created
        **/
    public static void finalAction(Set<Id> setOrderId) {
        Id ownerIdTmp = UserInfo.getUserId();
        Set<Id> setOrderIdToSubmit = new Set<Id>();
        List<Task> listTaskToCreate = new List<Task>();
        List<Apttus__AgreementLineItem__c> listAgLIToUpdate = new List<Apttus__AgreementLineItem__c>();
        Map<Id, Apttus_Config2__OrderLineItem__c> mapAgLIId = new Map<Id, Apttus_Config2__OrderLineItem__c>();
        List<Apttus_Config2__Order__c> listOrderUpdate = new List<Apttus_Config2__Order__c>();

        try {

            //prepare map of Agreement Line Item Id and Order Line Item
            for (Apttus_Config2__OrderLineItem__c oliTmp : [select Id, Apttus_Config2__DerivedFromId__r.APTS_Agreement_Line_Item__c, Apttus_Config2__OrderId__c, Apttus_Config2__OrderId__r.Apttus_Config2__SoldToAccountId__r.Customer_Relations_1__c, Apttus_Config2__OrderId__r.Apttus_CMConfig__AgreementId__r.OwnerId from Apttus_Config2__OrderLineItem__c where Apttus_Config2__OrderId__c = : setOrderId AND Apttus_Config2__LineType__c  = 'Product/Service' AND Apttus_Config2__IsPrimaryLine__c  = true]) {
                mapAgLIId.put(oliTmp.Apttus_Config2__DerivedFromId__r.APTS_Agreement_Line_Item__c, oliTmp);
            }

            //Iterate through Agreement Line item id and create task or submit to SAP for Order
            for (Apttus__AgreementLineItem__c agLITmp : [SELECT Id, APTS_Last_Processed_for_Subscription__c, Apttus_CMConfig__AttributeValueId__r.APTS_Contact_Customer_Before_Delivery__c FROM Apttus__AgreementLineItem__c WHERE Id = :mapAgLIId.keySet()]) {
                Apttus_Config2__OrderLineItem__c oliTmp = mapAgLIId.get(agLITmp.Id);

                if (oliTmp != null && oliTmp.Apttus_Config2__OrderId__c != null) {
                    system.debug('contact cust = ' + agLITmp.Apttus_CMConfig__AttributeValueId__r.APTS_Contact_Customer_Before_Delivery__c);
                    if (YES.equalsIgnoreCase(agLITmp.Apttus_CMConfig__AttributeValueId__r.APTS_Contact_Customer_Before_Delivery__c)) {
                        if (oliTmp.Apttus_Config2__OrderId__r.Apttus_Config2__SoldToAccountId__r != null && oliTmp.Apttus_Config2__OrderId__r.Apttus_Config2__SoldToAccountId__r.Customer_Relations_1__c != null) {
                            ownerIdTmp = oliTmp.Apttus_Config2__OrderId__r.Apttus_Config2__SoldToAccountId__r.Customer_Relations_1__c;
                        }

                        if (oliTmp.Apttus_Config2__OrderId__r.Apttus_CMConfig__AgreementId__r != null && oliTmp.Apttus_Config2__OrderId__r.Apttus_CMConfig__AgreementId__r.OwnerId != null) {
                            ownerIdTmp = oliTmp.Apttus_Config2__OrderId__r.Apttus_CMConfig__AgreementId__r.OwnerId;
                        }

                        Task taskTmp = getSubscriptionTask(ownerIdTmp, oliTmp.Apttus_Config2__OrderId__c);

                        if (taskTmp != null) {
                            listTaskToCreate.add(taskTmp);
                        }
                    } else {
                        setOrderIdToSubmit.add(oliTmp.Apttus_Config2__OrderId__c);
                    }

                    Apttus_Config2__Order__c orderObj = new Apttus_Config2__Order__c();
                    orderObj.Id = oliTmp.Apttus_Config2__OrderId__c;
                    orderObj.APTS_Order_Batch_Status__c = STR_COMPLETED;
                    listOrderUpdate.add(orderObj);

                    agLITmp.APTS_Last_Processed_for_Subscription__c = DateTime.now();
                    listAgLIToUpdate.add(agLITmp);
                }
            }

            if (listOrderUpdate != null && !listOrderUpdate.isEmpty()) {
                Database.update(listOrderUpdate, false);
            }

            if (listTaskToCreate != null && !listTaskToCreate.isEmpty()) {
                DescribeSObjectResult objResultTask = APTS_OTCUtil.getsObjectAccess(TASKCRUD); // CRUD/FLS Check
                Database.insert(listTaskToCreate, false);
            }

            if (setOrderIdToSubmit != null && !setOrderIdToSubmit.isEmpty()) {
                APTS_OrderUtils.submitMultipleOrders(setOrderIdToSubmit);
            }

            if (listAgLIToUpdate != null && !listAgLIToUpdate.isEmpty()) {
                Database.update(listAgLIToUpdate, false);
            }

        } catch (Exception ex) {
            throw ex;
        }
    }

    public static Task getSubscriptionTask(Id ownerIdTmp, Id orderId) {
        Task taskTmp = new Task();

        try {

            taskTmp = new Task(whatid = orderId,
                               Status = TASK_OPEN, OwnerId = ownerIdTmp,
                               Subject = SUBSCRIPTION_ORDER,
                               ActivityDate = System.today(),
                               Guidance__c = SUBSCRIPTION_TASK_GUIDANCE,
                               OTC_relevant_flag__c = true);

        } catch (Exception ex) {
            throw ex;
        }

        return taskTmp;
    }

    public static List<Apttus_Config2__Order__c> getValidOrderList(List<Apttus_Config2__Order__c> listOrderBatchChunck) {
        List<Apttus_Config2__Order__c> listOrderChunck = new List<Apttus_Config2__Order__c>();

        try {
            Apttus_Config2__Order__c orderObj;
            Map<Id, Apttus_Config2__Order__c> mapOrderChunck = new Map<Id, Apttus_Config2__Order__c>(listOrderBatchChunck);
            for (Apttus_Config2__Order__c orderTmp : [select id, (select id from Apttus_Config2__OrderLineItems__r) from Apttus_Config2__Order__c where id = :mapOrderChunck.keySet()]) {
                if (orderTmp.Apttus_Config2__OrderLineItems__r == null || orderTmp.Apttus_Config2__OrderLineItems__r.isEmpty()) {
                    orderObj = mapOrderChunck.get(orderTmp.Id);
                    if (orderObj != null) {
                        listOrderChunck.add(orderObj);
                    }
                }
            }
        } catch (Exception ex) {
            throw ex;
        }
        return listOrderChunck;
    }

    public static Map<Id, Id> createCartAddProduct(Set<Id> setOrderId, Set<Id> setAgreementId, List<Apttus_Config2__Order__c> listOrderBatchChunck) {
        Id cartId;
        Boolean hasCart;
        Apttus__AgreementLineItem__c subscriptionBundleLine;
        Set<Id> setBundleIds;
        Map<Id, Id> mapNewCartId = new Map<Id, Id>();
        List<Apttus__AgreementLineItem__c> listSubscriptionOptionLines;
        Map<Id, Id> mapOrderCartID;
        Map<Id, List<Apttus__AgreementLineItem__c>> mapSubscriptionLineItem;

        try {

            //check if there are any cart availble
            mapOrderCartID = getCart (setOrderId);

            //map of all subscription agreement line items
            mapSubscriptionLineItem = getSubscriptionLineItems(setAgreementId);
            //map of all primary bundle line item

            if (mapSubscriptionLineItem != null) {

                //system.debug('listSubscriptionOrder = ' + listSubscriptionOrder);

                for (Apttus_Config2__Order__c newOrder : listOrderBatchChunck) {
                    try {
                        hasCart = mapOrderCartID != null && mapOrderCartID.containsKey(newOrder.Id) ? true : false;

                        if (!hasCart) {
                            //create cart
                            cartId = APTS_OrderUtils.createCart(newOrder.Id);
                            //add products

                            //get list of Bundle/Machine config
                            listSubscriptionOptionLines = mapSubscriptionLineItem.get(newOrder.Apttus_Config2__Description__c);
                            subscriptionBundleLine = getSubscriptionBundleLine(listSubscriptionOptionLines);
                            APTS_AdjustmentLineItemCallback.setIsDisabled(TRUE);
                            Decimal dcLineNumbers = APTS_OrderUtils.addAgreementLineItemToCart(cartId, subscriptionBundleLine, listSubscriptionOptionLines);
                            APTS_AdjustmentLineItemCallback.setIsDisabled(FALSE);

                            if (dcLineNumbers != null) {
                                mapNewCartId.put(cartId, newOrder.Apttus_Config2__SoldToAccountId__c);
                            }
                        }
                    } catch (Exception ex) {
                        //order level exception
                        continue;
                    }
                }

                updateAttributes(mapNewCartId.keySet());
            }

        } catch (Exception ex) {
            throw ex;
        }

        return mapNewCartId;
    }


    public static Map<Id, List<Apttus_Config2__LineItem__c>> getCartLineItems(Set<Id> setNewCartId) {
        Map<Id, List<Apttus_Config2__LineItem__c>> mapCartLineItems = new Map<Id, List<Apttus_Config2__LineItem__c>>();
        List<Apttus_Config2__LineItem__c> listLineItems;

        for (Apttus_Config2__LineItem__c lineItemTmp : [SELECT   Id, Apttus_Config2__LineType__c,
                Apttus_Config2__ProductId__c, Apttus_Config2__OptionId__c, APTS_Source_Line_Number__c,
                Apttus_Config2__SellingUom__c, Apttus_Config2__ConfigurationId__c
                FROM Apttus_Config2__LineItem__c
                WHERE Apttus_Config2__ConfigurationId__c = :setNewCartId]) {
            listLineItems = mapCartLineItems.get(lineItemTmp.Apttus_Config2__ConfigurationId__c);
            listLineItems = listLineItems != null ? listLineItems : new List<Apttus_Config2__LineItem__c>();
            listLineItems.add(lineItemTmp);
            mapCartLineItems.put(lineItemTmp.Apttus_Config2__ConfigurationId__c, listLineItems);

        }

        return mapCartLineItems;
    }

    public static void addAdjustments(Id accountId, Id cartId, List<Apttus_Config2__LineItem__c> listCartLineItems) {
        Apttus_CPQApi.CPQ.AdjustmentItemCollDO adjItemColl;
        List<Apttus_CPQApi.CPQ.AdjustmentItemCollDO> adjItemColls = new List< Apttus_CPQApi.CPQ.AdjustmentItemCollDO>();
        Map<ID, List<APTS_Contract_Entitlement_Repository__c>> cerprdmap = APTS_CERUtility.getContractedProductsWithDiscounts(accountId, cartId, FALSE);

        for (Apttus_Config2__LineItem__c lineItem : listCartLineItems) {
            adjItemColl = new  Apttus_CPQApi.CPQ.AdjustmentItemCollDO();
            adjItemColl.LineItemId = lineItem.Id;
            adjItemColl.AdjustmentItems = new List<Apttus_Config2__AdjustmentLineItem__c>();

            // Add CER Adjustments
            Map<String, Apttus_Config2__AdjustmentLineItem__c> mapTemp = APTS_AdjustmentLineItemCallback.getCERAdjustmentLineItems('Order', lineItem, cerprdmap);
            if (mapTemp != null && !mapTemp.isEmpty() && mapTemp.values() != null) {
                adjItemColl.AdjustmentItems.addAll(mapTemp.values());

                if (adjItemColl.AdjustmentItems != null && !adjItemColl.AdjustmentItems.isEmpty()) {
                    adjItemColls.add(adjItemColl);
                }
            }
        }

        if (adjItemColls != null && !adjItemColls.isEmpty() ) {
            Apttus_CPQApi.CPQ.UpdateManualAdjustmentsRequestDO request = new Apttus_CPQApi.CPQ.UpdateManualAdjustmentsRequestDO();
            request.CartId = cartId;
            request.AdjustmentItemColls = adjItemColls;

            if (!Test.isRunningTest()) {
                Apttus_CPQApi.CPQ.UpdateManualAdjustmentsResponseDO result =  Apttus_CPQApi.CPQWebService.updateManualAdjustmentsForCart(request);
            }
        }
    }

    public static void applyConstraintsRule(Id cartId) {
        //constraint rules
        Apttus_CPQApi.CPQWebService.associateConstraintRules(cartId, null);
        Apttus_CPQApi.CPQWebService.applyConstraintRules(cartId, false);
    }

    public static Apttus__AgreementLineItem__c getSubscriptionBundleLine(List<Apttus__AgreementLineItem__c> listSubscriptionLineItemTmp) {
        Apttus__AgreementLineItem__c agLineItem;
        for (Apttus__AgreementLineItem__c agLineItemTmp : listSubscriptionLineItemTmp) {
            if (agLineItemTmp.Apttus_CMConfig__OptionId__c == null) {
                agLineItem = agLineItemTmp;
                break;
            }
        }

        return agLineItem;
    }

    public static Map<Id, Id> getCart(final Set<Id> setOrderId) {
        Map<Id, Id> mapOrderCartIdTmp = new Map<Id, Id>();

        for (Apttus_Config2__ProductConfiguration__c prodConfig : [SELECT Id, Apttus_Config2__OrderId__c FROM Apttus_Config2__ProductConfiguration__c
                WHERE Apttus_Config2__BusinessObjectType__c = 'Order'
                        AND Apttus_Config2__BusinessObjectId__c  IN :setOrderId
                        AND Apttus_Config2__OrderId__c IN :setOrderId]) {
            mapOrderCartIdTmp.put(prodConfig.Id, prodConfig.Apttus_Config2__OrderId__c);
        }

        return mapOrderCartIdTmp;
    }

    public static Map<Id, List<Apttus__AgreementLineItem__c>> getSubscriptionLineItems(final Set<Id> setAgreementId) {
        Set<Id> setAgLineItemId = new Set<Id>();
        List<Apttus__AgreementLineItem__c> listAgLineItemTmp;
        List<Apttus__AgreementLineItem__c> listAllAgLineItems;
        Map<String, Id> mapBundleLineItem = new Map<String, Id>();
        Map<Id, List<Apttus__AgreementLineItem__c>> mapAgremeentLine = new Map<Id, List<Apttus__AgreementLineItem__c>>();

        try {

            //Initial loop fetches all agreement line item of Agreement
            for (Apttus__AgreementLineItem__c agLineItemTmp : [SELECT id, Apttus__AgreementId__c,
                    Apttus_CMConfig__LineNumber__c, Apttus_CMConfig__AttributeValueId__c, Apttus__ProductId__c,
                    Apttus_CMConfig__OptionId__c, Apttus_CMConfig__ChargeType__c, Apttus_CMConfig__PriceListItemId__c,
                    Apttus__Quantity__c, Apttus_CMConfig__SellingFrequency__c, Apttus_CMConfig__SellingTerm__c,
                    Apttus_CMConfig__AdjustmentType__c, Apttus_CMConfig__AdjustmentAmount__c, Apttus_CMConfig__LineType__c,
                    Apttus_CMConfig__Comments__c, APTS_Last_Processed_for_Subscription__c, Apttus_CMConfig__IsPrimaryLine__c,
                    Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c, Apttus_CMConfig__ProductOptionId__c,
                    Apttus_CMConfig__ProductOptionId__r.Apttus_Config2__ComponentProductId__c, Apttus_CMConfig__ClassificationId__c,
                    Apttus_CMConfig__ClassificationHierarchy__c, Apttus_CMConfig__AttributeValueId__r.APTS_Order_Frequency__c, Apttus_CMConfig__SellingUom__c
                    FROM Apttus__AgreementLineItem__c
                    WHERE Apttus__AgreementId__c IN :setAgreementId AND Apttus_CMConfig__IsPrimaryLine__c = true LIMIT 10000]) {

                listAllAgLineItems = listAllAgLineItems != null ? listAllAgLineItems : new List<Apttus__AgreementLineItem__c>();
                listAllAgLineItems.add(agLineItemTmp);

                if (agLineItemTmp.Apttus_CMConfig__OptionId__c == null && APTS_SubscriptionOrder.checkSubscriptionOrderRequired(agLineItemTmp)) {
                    mapBundleLineItem.put(agLineItemTmp.Apttus__AgreementId__c + '_' + agLineItemTmp.Apttus_CMConfig__LineNumber__c, agLineItemTmp.Id);
                }
            }

            //Second iteration prepare map of Subscription Line Item Id and list of primary Agreement line items of bundle (product and options both)
            for (Apttus__AgreementLineItem__c agLineItemTmp : listAllAgLineItems) {
                Id bundleId = mapBundleLineItem.get(agLineItemTmp.Apttus__AgreementId__c + '_' + agLineItemTmp.Apttus_CMConfig__LineNumber__c);

                if (bundleId != null) {
                    listAgLineItemTmp = mapAgremeentLine.get(bundleId);
                    listAgLineItemTmp = listAgLineItemTmp != null ? listAgLineItemTmp : new List<Apttus__AgreementLineItem__c>();
                    listAgLineItemTmp.add(agLineItemTmp);
                    mapAgremeentLine.put(bundleId, listAgLineItemTmp);
                }
            }

        } catch (Exception ex) {
            throw ex;
        }

        return mapAgremeentLine;
    }

    public static Map<Id, Set<Id>> getAgreementBundles(Map<Id, List<Apttus__AgreementLineItem__c>> mapSubscriptionLineItem) {
        Map<Id, Set<Id>> mapAgreementBundles = new Map<Id, Set<Id>>();
        Set<Id> setAgLineItemIdTmp;

        //iterate agreement line item ids
        for (Id agLineItemIdTmp : mapSubscriptionLineItem.keySet()) {

            //iterate agreement line item of one bundle, if primary line found than break loop
            for (Apttus__AgreementLineItem__c agLineItemTmp : mapSubscriptionLineItem.get(agLineItemIdTmp)) {
                if (agLineItemTmp.Apttus_CMConfig__OptionId__c == null) {
                    setAgLineItemIdTmp = mapAgreementBundles.get(agLineItemTmp.Apttus__AgreementId__c);
                    setAgLineItemIdTmp = setAgLineItemIdTmp != null ? setAgLineItemIdTmp : new Set<Id>();
                    if (!setAgLineItemIdTmp.contains(agLineItemTmp.Id)) {
                        setAgLineItemIdTmp.add(agLineItemTmp.Id);
                    }
                    mapAgreementBundles.put(agLineItemTmp.Apttus__AgreementId__c, setAgLineItemIdTmp);
                    break;
                }
            }
        }

        return mapAgreementBundles;
    }

    public static void updateAttributes(Set<Id> setNewCartId) {
        if (setNewCartId != null && !setNewCartId.isEmpty()) {
            Apttus_Config2__ProductAttributeValue__c attributeTmp;
            List<Apttus_Config2__ProductAttributeValue__c> listAttributesToUpdate = new List<Apttus_Config2__ProductAttributeValue__c>();

            for (Apttus_Config2__LineItem__c lineItem : [select id, Apttus_Config2__AttributeValueId__c, Apttus_Config2__AttributeValueId__r.APTS_Type_of_contract__c, APTS_Agreement_Line_Item__r.Apttus_CMConfig__AttributeValueId__r.APTS_Type_of_contract__c from Apttus_Config2__LineItem__c where Apttus_Config2__ConfigurationId__c IN :setNewCartId AND Apttus_Config2__HasAttributes__c = true]) {
                if (lineItem.Apttus_Config2__AttributeValueId__c != null && lineItem.APTS_Agreement_Line_Item__r != null && lineItem.APTS_Agreement_Line_Item__r.Apttus_CMConfig__AttributeValueId__r != null) {
                    attributeTmp = new Apttus_Config2__ProductAttributeValue__c();
                    attributeTmp.Id = lineItem.Apttus_Config2__AttributeValueId__c;
                    attributeTmp.APTS_Type_of_contract__c = lineItem.APTS_Agreement_Line_Item__r.Apttus_CMConfig__AttributeValueId__r.APTS_Type_of_contract__c;
                    listAttributesToUpdate.add(attributeTmp);
                }
            }

            if (listAttributesToUpdate != null && !listAttributesToUpdate.isEmpty()) {
                Database.update(listAttributesToUpdate, false);
            }
        }
    }

    public static void repriceCart(Id cartId) {
        //Reprice
        Boolean isPricePending = true;
        while (isPricePending) {
            isPricePending = APTS_OrderUtils.repriceCart(cartId);
            if (!isPricePending) {
                break;
            }
        }
    }

    public static Boolean finalizeCart(Id cartId) {
        //Finalize
        APTS_OrderUtils.finalizeCart(cartId);

        //Syncronize
        Boolean isSuccess = APTS_OrderUtils.syncCart(cartId);

        return isSuccess;
    }
}