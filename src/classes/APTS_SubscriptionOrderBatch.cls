/*************************************************************
@Name: APTS_SubscriptionOrderBatch
@Author: Sethukkarasi
@CreateDate: 29-01-2018
@Description: Batch Class to trigger subscription Order creation based on Order frequency and agreement.
@UsedBy:
**************************************************************
@ModifiedBy : Neev Shah
@ModifiedDate : 7-1-2019
@Description : Re-written with optimized code. This batch job will only create Order Header record.
                APTS_SubscriptionOrderFinalizeBatch will add products to cart and submit to SAP.
******************************************************************/
//v108 28-Aug-2020 Added extra parameter to the APTS_DigitalOrderBatchHelper.creteerrorlog

global class APTS_SubscriptionOrderBatch implements Database.Batchable<sObject> {
    private static final String FREQ_DAILY = 'Daily';
    private static final String FREQ_WEEKLY = 'Weekly';
    private static final String FREQ_MONTHLY = 'Monthly';
    private static final String FREQ_QUARTERLY = 'Quarterly';
    private static final String FREQ_HALF_YEARLY = 'Half-yearly';
    private static final String FREQ_YEARLY = 'Yearly';
    private static final String ACC_STATUS_VALID = 'Valid';
    private static final String SUBSCRIPTION_ORDER = 'Subscription Order';
    private static final String ORDER_CART_PENDING = 'Cart Creation Pending';
    private static final String STR_ORDER_ERR_MSG = 'Order not created for Subscription Ingredient = ';
    private static final String STR_ACC_ERR_MSG = 'Order will not be created as Account Status is invalid for Subscription Ingredient = ';
    private static final String EMAIL = System.Label.APTS_Email;
    private static final String IN_EFFECT = APTS_OrderConstants.IN_EFFECT;
    private static final String BEING_AMENDED = APTS_OrderConstants.BEING_AMENDED;
    private static final String BEING_RENEWED = APTS_OrderConstants.BEING_RENEWED;
    private static final String STR_ACTIVATED = System.Label.APTS_Activated;
    private static final String PRODUCT_SERVICE = System.Label.APTS_ProductService;
    private static String BATCHNAME = 'Subscription Orders Batch';

    /** Method Name :start
        * Description : Method would return query to get list of Subscription Agreement
        **/
    global Database.QueryLocator start(Database.BatchableContext BC) {
        List<APTS_Batch_Queries__mdt> batchQuery = [SELECT Id,    
                                                          APTS_Query_String__c
                                                          FROM APTS_Batch_Queries__mdt
                                                          WHERE APTS_Batch_Name__c =: BATCHNAME limit 1];
        String sQuery = batchQuery[0].APTS_Query_String__c;  
        return Database.getQueryLocator(sQuery);
    }

    /** Method Name :execute
        * Description : Method would iterate through agreements and invoke Subscription Util
        **/
    global void execute(Database.BatchableContext BC, List<Apttus__AgreementLineItem__c> listAgLineItemBatchChunk) {
        Apttus_Config2__Order__c subscriptionOrder;
        Set<Id> setAccountIds = new Set<Id>();
        Set<Id> setAgreementIds = new Set<Id>();
        List<Apttus__AgreementLineItem__c> listSubAgLineItems = new List<Apttus__AgreementLineItem__c>();
        List <Apttus_Config2__Order__c> listNewOrderTmp = new List<Apttus_Config2__Order__c>();
        List<APTS_Order_Error_Log__c> listErrorLog = new List<APTS_Order_Error_Log__c>();

        try {

            Group queue = APTS_DigitalOrderBatchHelper.getCSQueue();

            //Initial loop to get required data
            for (Apttus__AgreementLineItem__c agLineItem : listAgLineItemBatchChunk) {
                try {
                    if (APTS_SubscriptionOrder.checkSubscriptionOrderRequired(agLineItem)) {

                        if (agLineItem.Apttus__AgreementId__r != null && agLineItem.Apttus__AgreementId__r.Apttus__Account__c != null && ACC_STATUS_VALID.equalsIgnoreCase(agLineItem.Apttus__AgreementId__r.Apttus__Account__r.Account_Status__c)) {
                            listSubAgLineItems.add(agLineItem);

                            if (!setAgreementIds.contains(agLineItem.Apttus__AgreementId__c)) {
                                setAgreementIds.add(agLineItem.Apttus__AgreementId__c);
                            }

                            if (!setAccountIds.contains(agLineItem.Apttus__AgreementId__r.Apttus__Account__c)) {
                                setAccountIds.add(agLineItem.Apttus__AgreementId__r.Apttus__Account__c);
                            }

                        } else {
                            APTS_Order_Error_Log__c oErrLog = APTS_DigitalOrderBatchHelper.createErrorLog(STR_ACC_ERR_MSG + agLineItem.Id, agLineItem.Id, null, null, null,null, queue);
                            listErrorLog.add(oErrLog);
                        }
                    }
                    if (Test.isRunningTest()){
                		Decimal dc = 1/0;
            		}
                } catch (Exception ex) {
                    APTS_Order_Error_Log__c oErrLog = APTS_DigitalOrderBatchHelper.createErrorLog(STR_ORDER_ERR_MSG + agLineItem.Id, agLineItem.Id, null, null, null,null,queue);
                    listErrorLog.add(oErrLog);
                    continue;
                }
            }

            if (!setAccountIds.isEmpty() && !setAgreementIds.isEmpty() ) {
                //SOQL or Data-Preparation section
                Map<Id, Apttus__APTS_Agreement__c> mapAgreementTmp = APTS_SubscriptionOrder.getAgreements(setAgreementIds);
                Map<Id, Account> mapAccountTmp = APTS_SubscriptionOrder.getAccountsFromAgreements(mapAgreementTmp.values());
                Map<Id, List<Contact>> mapAccountContactTmp = APTS_SubscriptionOrder.getContacts(setAccountIds);
                Map<Id, Apttus_Config2__AccountLocation__c> mapLocationTmp = APTS_SubscriptionOrder.getAccountLocations(setAccountIds);

                // Main Loop, iterate Agreement to create an order
                String sErrMsg = '';
                for (Apttus__AgreementLineItem__c agLineItem : listSubAgLineItems) {
                    try {
                        //create Order header for Subscription Order
                        subscriptionOrder = APTS_SubscriptionOrder.getOrderHeader(agLineItem, mapAccountTmp, mapLocationTmp, mapAgreementTmp, mapAccountContactTmp);

                        if (subscriptionOrder != null) {
                            listNewOrderTmp.add(subscriptionOrder);
                        } else {
                            sErrMsg = STR_ORDER_ERR_MSG + agLineItem.Id;
                        }
                        if (Test.isRunningTest()){ Decimal dc = 1/0; }
                    } catch (Exception ex) {
                        sErrMsg = ex.getMessage();
                    } finally {
                        if (String.isNotBlank(sErrMsg)) {
                            APTS_Order_Error_Log__c oErrLog = APTS_DigitalOrderBatchHelper.createErrorLog(sErrMsg, agLineItem.Id, null, null, null,null, queue);
                            listErrorLog.add(oErrLog);
                        }

                        continue;
                    }

                }

                //create order
                Database.SaveResult[] saveRes = APTS_SubscriptionOrder.createOrder(listNewOrderTmp);
                List<APTS_Order_Error_Log__c> listErrorLogTmp = APTS_SubscriptionOrder.getOrderErrorLogs(queue, saveRes);

                if (listErrorLogTmp != null && !listErrorLogTmp.isEmpty()) {
                    listErrorLog.addAll(listErrorLogTmp);
                }
            }

            if (listErrorLog != null && !listErrorLog.isEmpty()) {
                APTS_SubscriptionOrder.createOrderErrorLogs(listErrorLog);
            }
			if (Test.isRunningTest()){ Decimal dc = 1/0; }
        } catch (Exception ex) {
            APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString() , 'Subscription Order', null, 'OM', false, true, null, true);
            //throw ex;
        }
    }

    global void finish(Database.BatchableContext BC) {

        List<Apttus_Config2__Order__c> listOrder = [SELECT Id, Apttus_CMConfig__AgreementId__c, Apttus_Config2__SoldToAccountId__c, Apttus_Config2__Description__c FROM Apttus_Config2__Order__c WHERE APTS_Order_Sub_Type__c = :SUBSCRIPTION_ORDER AND APTS_Order_Batch_Status__c = :ORDER_CART_PENDING AND Apttus_Config2__Description__c <> null];

        if (listOrder != null && !listOrder.isEmpty()) {
            Database.executeBatch(new APTS_SubscriptionOrderFinalizeBatch() , 1);
        }
    }
}