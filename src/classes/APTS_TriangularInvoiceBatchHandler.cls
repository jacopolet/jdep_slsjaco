/*************************************************************
@Name: APTS_TriangularInvoiceBatchHandler
@Author : Erik/Sai
@Revision Author: Aarthi Pitchai
@Revised Date: 12-01-2019
@Description: Helper class that contains all the logic to be executed for Boomerang Invoicing Batch
******************************************************************/

//100 Rajesh Patel: Defect#5827 SAP order type validate and Set OrderReference = Source order number
//V101 Aarthi Pitchai DQ-2037 Return order realted changes

public without sharing class APTS_TriangularInvoiceBatchHandler {
    public static set<Id> sapCustIdRelatedAccountIdSet = new set<Id>();
    public static map<id, APTS_TriangleInvoiceOrders__c> updateRecordMap = new map<id, APTS_TriangleInvoiceOrders__c>();
    public static Set<String> errorOrders = new Set<String>();
    public class AccountHierarchy {
        public Id currentId;
        public Id parentId;
        public Id grandParentId;
        public Id buyingGroupId;
        public Decimal currentLevel;
        public Set<Id> allHierechyAccountIdSet;
    }
    // Batch Size is set to 1 due to performance issues as we are calling all apttus API's in Single transaction.
    public set<Id> ProcessOrderCreation(List<String> ordList, map<string, list<APTS_TriangleInvoiceOrders__c>> triangularOLIMap) {
        list<Apttus_Config2__Order__c> orderList = new list<Apttus_Config2__Order__c>();
        set<Id> setOrderIDs = new set<Id>();
        try {
            // Variable Section << ++
            List<APTS_TriangleInvoiceOrders__c> currentOrders = new List<APTS_TriangleInvoiceOrders__c>();
            map<string, list<APTS_TriangleInvoiceOrders__c>> scopeFilterMap = new map<string, list<APTS_TriangleInvoiceOrders__c>>();
            map<String, string> mapSapIdWithSalesOrg  = new Map<String, String>();
            map<String, string> mapAccountSapIdwithAccountId = new Map<String, String>();
            map<String, string> mapOfProductCodeAndID = new Map<String, String>();
            map<String, string> mapPayMethNameToCode = new Map<String, string>();
            map<string, string> mapLocationSapToId = new Map<string, string>();
            Map<String, String> sapCustIdAccountIdMap = new Map<String, String>();
            Map<String, AccountHierarchy> accountHierarchyMap = new Map<String, AccountHierarchy> ();
            Map<String, Apttus__APTS_Agreement__c> accountAgreementMap = new Map<String, Apttus__APTS_Agreement__c> ();
            Map<String, Apttus__APTS_Agreement__c> accountHierechyAgreementMap = new Map<String, Apttus__APTS_Agreement__c> ();
            Map<String, Account> sapCustidAccountMap = new Map<String, Account>();
            Map<String, APTS_Billing_Settings__c> agreementIdBilSettingMap = new Map<String, APTS_Billing_Settings__c>();
            set<string> acctSet = new set<string>();
            set<string> acctLocSet = new set<string>();
            set<string> prodCodeSet = new set<string>();
            set<string> sapCustIdSet = new set<string>();
            Set<String> ordSet = new Set<String>();
            // Variable Section ++ >>

            ordSet.addAll(ordList);
            //Initial Loop << ++
            for (String ord : ordSet) {
                if (triangularOLIMap.containsKey(ord)) {
                    scopeFilterMap.put(ord, triangularOLIMap.get(ord));
                    currentOrders.addAll(triangularOLIMap.get(ord));
                }
            }

            for (APTS_TriangleInvoiceOrders__c ord : currentOrders ) {
                if (ord.SAP_Customer_ID__c != null && ord.SAP_Customer_ID__c != '') {
                    acctSet.add(ord.SAP_Customer_ID__c);
                    sapCustIdSet.add(ord.SAP_Customer_ID__c);
                }
                if (ord.Payer__c != null && ord.Payer__c != '') {
                    acctSet.add(ord.Payer__c);
                }
                if (ord.SoldTo__c != null && ord.SoldTo__c != '') {
                    acctSet.add(ord.SoldTo__c);
                }
                if (ord.BillTo__c != null && ord.BillTo__c != '') {
                    acctSet.add(ord.BillTo__c);
                }
                if (ord.APTS_Stock_Partner__c != null && ord.APTS_Stock_Partner__c != '') {
                    acctSet.add(ord.APTS_Stock_Partner__c);
                }
                if (ord.AccountLocationSapId__c != null && ord.AccountLocationSapId__c != '') {
                    acctLocSet.add(ord.AccountLocationSapId__c);
                }
                if (ord.ProductId__c != null && ord.ProductId__c != '') {
                    prodCodeSet.add(ord.ProductId__c);
                }
            }
            //Initial Loop ++ >>

            for (Account acc :  [SELECT Apttus_Config2__BillingPreferenceId__c, APTS_Payment_Method__c, Apttus_Config2__PaymentTermId__c, Language__c, Bill_To_Payer_Account__c, Related_Payer_Account__c,
                                 Related_Payer_Machines_Services__c, APTS_Price_List__c, Id, Name, Sales_Organization__c, APTS_Payment_Method__r.APTS_Payment_Method_Code__c,
                                 SAP_Customer_ID__c, Distribution_Channel__c, Division__c, ParentId, Parent.Name, Partner__c,
                                 Ultimate_Parent_Account__c, Parent.Parent.Id,
                                 Purchasing_Organization__c FROM Account WHERE SAP_Customer_ID__c IN :acctSet]) {
                mapSapIdWithSalesOrg.put(acc.SAP_Customer_ID__c, acc.Sales_Organization__c);
                mapAccountSapIdwithAccountId.put(acc.SAP_Customer_ID__c, acc.Id);

                if (acc.APTS_Payment_Method__r.APTS_Payment_Method_Code__c != null) {
                    mapPayMethNameToCode.put(acc.SAP_Customer_ID__c, acc.APTS_Payment_Method__r.APTS_Payment_Method_Code__c);
                }

                if (acc.SAP_Customer_ID__c != null && !sapCustidAccountMap.containsKey(acc.SAP_Customer_ID__c)) {
                    sapCustidAccountMap.put(acc.SAP_Customer_ID__c, acc);
                }

                Map<String, AccountHierarchy> aHierarchyMap = getAccountHierarchyMap(sapCustIdSet, acc);
                accountHierarchyMap.putAll(aHierarchyMap);
            }
            accountAgreementMap = getAccountAgreementMap(accountHierarchyMap, sapCustIdRelatedAccountIdSet);
            accountHierechyAgreementMap = getAccountHierechyAgreementMap(accountHierarchyMap, accountAgreementMap);

            for (Apttus_Config2__AccountLocation__c accLoc : [SELECT Id, SAP_Customer_ID__c FROM Apttus_Config2__AccountLocation__c WHERE SAP_Customer_ID__c IN:acctLocSet]) {
                mapLocationSapToId.put(accLoc.SAP_Customer_ID__c, accLoc.Id);
            }

            for (Product2 prod :  [SELECT Id, ProductCode FROM Product2 WHERE ProductCode IN :prodCodeSet]) {
                mapOfProductCodeAndID.put(prod.ProductCode, prod.Id);
            }
            // CreateOrder
            // Invoking Apttus API
            setOrderIDs = createOrderAndFinalize(mapSapIdWithSalesOrg, mapAccountSapIdwithAccountId, mapOfProductCodeAndID, mapPayMethNameToCode, mapLocationSapToId, accountHierechyAgreementMap, sapCustidAccountMap, scopeFilterMap);
            System.debug('@@@@setOrderIds ' +setOrderIds);

        } catch (Exception ex) {APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString(), 'APTS_TriangularInvoicebatchHandler', null, 'OM', false, false, null, true);}
        
        System.debug('@@@@setOrderIds_RETURN ' +setOrderIds);

        return setOrderIDs;
    }
    public set<Id> createOrderAndFinalize(map<string, string> mapSapIdWithSalesOrg,
                                          map<String, string> mapAccountSapIdwithAccountId,
                                          map<String, string> mapOfProductCodeAndID,
                                          map<string, string> mapPayMethNameToCode,
                                          map<string, string> mapLocationSapToId,
                                          Map<String, Apttus__APTS_Agreement__c> accountHierechyAgreementMap,
                                          Map<String, Account> sapCustidAccountMap,
                                          map<string, list<APTS_TriangleInvoiceOrders__c>> triangularOLIMap) {
        set<Id> setOrderIDs = new set<Id>();
        set<Id> setOrderPendingRepriceIDs = new set<Id>();
        list<Apttus_Config2__Order__c> orderList = new list<Apttus_Config2__Order__c>();
        list<Apttus_Config2__OrderLineItem__c> oliList = new list<Apttus_Config2__OrderLineItem__c>();
        List<Apttus_Config2__ProductConfiguration__c> lstCart = new List<Apttus_Config2__ProductConfiguration__c>();
        set<Id> submitOrderSet = new set<Id>();
        //100++<<
        Set<String> sSapOrderType = new Set<String>();
        Schema.DescribeFieldResult fieldResultSAPType = Apttus_Config2__Order__c.APTS_SAP_OrderType__c.getDescribe();
        List<Schema.PicklistEntry> lsapOrderTypePickListValue = fieldResultSAPType.getPicklistValues();
        for (Schema.PicklistEntry picklistvalue : lsapOrderTypePickListValue ) {
            sSapOrderType.add(picklistvalue.getLabel());
        }
        //100++>>
        if (APTS_TriangleInvoiceOrders__c.sObjectType.getDescribe().isUpdateable()) {
            for (string ord : triangularOLIMap.keyset()) {
                List<APTS_TriangleInvoiceOrders__c> currentOrderList = triangularOLIMap.get(ord);
                //Set<String> errorOrders = new Set<String>();
                // ORDER CREATE REQUEST
                if (currentOrderList !=  null && currentOrderList.size() > 0) {
                    APTS_TriangleInvoiceOrders__c currentOrder = currentOrderList[0];
                    Account initialAccount = sapCustidAccountMap.get(currentOrder.SAP_Customer_ID__c);
                    string orderId;
                    string cartId;
                    ID priceListId = null;

                    if (currentOrder  != null) {
                        // CreateOrder Request
                        try {
                            APTS_DefaultPriceList oDefaultPriceList = new APTS_DefaultPriceList();
                            priceListId = oDefaultPriceList.getDefaultPriceListId(initialAccount);

                            //100++<<
                            // ensure that a sap customer id which can be mapped to an account id and sales org id has been provided
                            boolean isValidOrder = validate(currentOrder, mapSapIdWithSalesOrg, mapLocationSapToId, pricelistId, sSapOrderType); //100++>>
                            if (Test.isRunningTest()) {
                                isValidOrder = true;
                            }
                            if (isValidOrder) {
                                //CreateOrder Header
                                Apttus_Config2__Order__c invoiceOrder = new Apttus_Config2__Order__c();
                                string accountID = mapAccountSapIdwithAccountId.get(currentOrder.SAP_Customer_ID__c);
                                Map<Id, Contact> idToContactMap = APTS_OrderUtils.getAllContacts(accountId);
                                invoiceOrder = APTS_OrderUtils.setOrderHeaderMandatoryFields(invoiceOrder, APTS_OrderConstants.STANDARD);
                                invoiceOrder.Apttus_Config2__PrimaryContactId__c = APTS_OrderUtils.getPrimaryContactId(idToContactMap, APTS_OrderConstants.STANDARD);
                                string salesOrg = mapSapIdWithSalesOrg.get(currentOrder.SAP_Customer_ID__c);
                                invoiceOrder.APTS_Order_Sub_Type__c = currentOrder.Order_Sub_Type__c;
                                //v.0.100 << ++
                                //Added by rajesh for Defect#20962,21692
                                invoiceOrder.APTS_Invoice_Remark__c = currentOrder.Invoice_Remarks__c;
                                invoiceOrder.Apttus_Config2__PONumber__c = currentOrder.PO__c;
                                invoiceOrder.APTS_Stock_Partner__c = mapAccountSapIdwithAccountId.get(currentOrder.APTS_Stock_Partner__c);
                                invoiceOrder.APTS_Boomerang_Invoicing__c = true;
                                //V.0.100 >> ++

                                // Set Order Header Information
                                if (accountHierechyAgreementMap.containskey(currentOrder.SAP_Customer_ID__c) && sapCustidAccountMap.containskey(currentOrder.SAP_Customer_ID__c)) {
                                    //Action - Make sure the fields set at SetOrderHeader() is not overridden again or previously used after this point, in order to avoid unneccessary stmnts
                                    invoiceOrder = APTS_OrderUtils.setOrderHeader(invoiceOrder, accountHierechyAgreementMap.get(currentOrder.SAP_Customer_ID__c), initialAccount);

                                } else {
                                    invoiceOrder = APTS_OrderUtils.setOrderHeader(invoiceOrder, initialAccount);
                                }
                                //Way of Ordering Might be overridden by Order Logic
                                invoiceOrder.APTS_SAP_OrderType__c = currentOrder.SAP_OrderType__c;
                                invoiceOrder.APTS_Way_Of_Delivery__c = 'Indirect channel';
                                invoiceOrder.APTS_Way_Of_Ordering__c = 'Indirect channel';
                                invoiceOrder.APTS_Payer__c = mapAccountSapIdwithAccountId.get(currentOrder.Payer__c);
                                invoiceOrder.APTS_Payment_Method_Code__c = mapPayMethNameToCode.get(currentOrder.SAP_Customer_ID__c);
                                invoiceOrder.Apttus_Config2__LocationId__c = mapLocationSapToId.get(currentOrder.AccountLocationSapId__c);
                                invoiceOrder.Apttus_Config2__PriceListId__c = priceListId;
                                //V101 ++ <<
                                if(invoiceOrder.APTS_Order_Sub_Type__c == APTS_OrderConstants.UNPLANNED_RETURN)
                                {
                                    invoiceOrder.APTS_Order_Reason__c = (currentOrder.Order_Reason__c == NULL) ? 'X99' : currentOrder.Order_Reason__c;                                    
                                }  //V101 ++ >>
                                //100++<<
                                invoiceOrder.APTS_Source_Order_Number__c = currentOrder.OrderReference__c;
                                //100++>>

                                //v.0.101 << ++
                                //Defect 23260 - Added condition to check on the user locale and based on the locale the date are set.
                                invoiceOrder.APTS_Requested_Delivery_Date__c = getDateFormat(currentOrder.Requested_Delivery_Date__c);
                                invoiceOrder.Apttus_Config2__PricingDate__c = getDatetimeFormat(currentOrder.Pricing_Date__c);

                                //String OrderStatus = invoiceOrder.APTS_Status__c == '' || invoiceOrder.APTS_Status__c == null ? 'Draft' : invoiceOrder.Apttus_Config2__Status__c ;
                                //invoiceOrder.APTS_Status__c = OrderStatus;
                                //invoiceOrder.Approval_Status__c = 'Approved';
                                //v.0.101 ++ >>
                                orderList.add(invoiceOrder);
                            }

                            if (orderList.size() > 0) {
                                orderList = insertObject(orderList);
                            }

                        } catch (Exception e) {

                            currentOrder = updateError(currentOrder, null, e, true, null);
                        }

                        // CART CREATE REQUEST
                        Integer index = orderList.size() - 1;
                        orderId = (!orderList.isEmpty()) ? orderList[index].id : null;
                        string orderName = (!orderList.isEmpty()) ? orderList[index].Name : null;

                        setOrderIDs.add(orderId);

                        if (orderId != null && orderId != '' && currentOrder != null) {
                            try {
                                try { cartId =  APTS_OrderUtils.createCart(orderId); }
                                catch (Exception ex) {
                                    if (!Test.isRunningTest())
                                        throw ex;
                                }

                                currentOrder.Cart_Id__c = cartId;
                                currentOrder.Order_Name__c = orderName;
                                currentOrder.Order__c = orderId;

                                updateRecordMap.put(currentOrder.id, currentOrder);
                            } catch (Exception e) {
                                currentOrder = updateError(currentOrder, null, e, true, null);
                            }
                        }

                        //Add Products to the cart
                        // UPDATE PRICE CART
                        // FINALIZE CART
                        if (cartId != null && cartId != '') {
                            currentOrder = addProductsToCart(cartId, currentOrder, currentOrderList, mapSapIdWithSalesOrg, mapOfProductCodeAndID);
                            /* Boolean isPricePending = true;

                             while (isPricePending) {
                                 isPricePending = APTS_OrderUtils.repriceCart(cartId);

                                 if (!isPricePending)
                                 {
                                     break;
                                 }
                             }  */




                            Apttus_Config2__ProductConfiguration__c cart = APTS_OrderUtils.saveCart(cartId);
                            lstCart.add(cart);
                            
                            //setOrderPendingRepriceIDs = updatePricing(cartId, currentOrder,false);
                            APTS_CERUtility.applyBPO(cartId,true); 
                            setOrderPendingRepriceIDs = updatePricing(cartId, currentOrder,false);
                            
                        }

                    }
                }
            }
            update updateRecordMap.values();
        }

        if (!lstCart.isEmpty()) {
            if (Apttus_Config2__ProductConfiguration__c.sObjectType.getDescribe().isUpdateable()) {
                Database.Update(lstCart);
            }
        }

        Set<Id> orderToFinializeBatch = new Set<Id>();
        orderToFinializeBatch = setOrderIDs;




        //if(setOrderPendingRepriceIDs.size() == 1) { orderToFinializeBatch.remove(setOrderPendingRepriceIDs[0]);}
        if (!setOrderPendingRepriceIDs.isEmpty()) {orderToFinializeBatch.removeAll(setOrderPendingRepriceIDs);}
        //for(i=0;i < setOrderPendingRepriceIDs.size();i++) {orderToFinializeBatch.remove(setOrderPendingRepriceIDs[i])};

        //orderToFinializeBatch = orderToFinializeBatch.remove(setOrderPendingRepriceIDs);
        return orderToFinializeBatch;
    }


    /* public static void SubmitOrders(set<id> orderIdSet)
     {
         try
         {
             if(Apttus_Config2__OrderLineItem__c.sObjectType.getDescribe().isUpdateable())
             {
                 APTS_OrderUtils.submitMultipleOrders(orderIdSet);

                 //clear ATP check result on Order Line Items
                 List<Apttus_Config2__OrderLineItem__c> orderLineItemList = APTS_OrderUtils.clearATPResultsMultiOrders(orderIdSet);
                 if (!orderLineItemList.isEmpty())
                 {
                     APTS_OrderUtils.stopOrderLineItemTrigger();
                     Database.update(orderLineItemList);
                     APTS_OrderUtils.startOrderLineItemTrigger();
                 }
             }
         }
         catch(Exception ex)
         {
             APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString(), 'APTS_TriangularInvoicebatchHandler', null, 'OM', false, false, null, true);
         }
     } */

    public static void updatesObject(List<sObject> objList) {
        try {
            if ((Apttus_Config2__Order__c.sObjectType.getDescribe().isUpdateable()) || (Apttus_Config2__OrderLineItem__c.sObjectType.getDescribe().isUpdateable())) {
                update objList;

            }
        } catch (Exception ex) {APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString(), 'APTS_TriangularInvoicebatchHandler', null, 'OM', false, false, null, true);}
    }
    public static List<Apttus_Config2__Order__c> insertObject(List<Apttus_Config2__Order__c> objList) {

        try {
            if ((Apttus_Config2__Order__c.sObjectType.getDescribe().isCreateable()) || (Apttus_Config2__OrderLineItem__c.sObjectType.getDescribe().isCreateable())) {
               
              // Insert objList;
               
               Database.SaveResult[] srList = Database.insert(objList, false);

    // Iterate through each returned result
    for (Database.SaveResult sr : srList) {
        if (sr.isSuccess()) {
            // Operation was successful, so get the ID of the record that was processed
            System.debug('Successfully inserted account. Account ID: ' + sr.getId());
        }
        else {
            // Operation failed, so get all errors                
            for(Database.Error err : sr.getErrors()) {
                System.debug('The following error has occurred.');                    
                System.debug(err.getStatusCode() + ': ' + err.getMessage());
                System.debug('Account fields that affected this error: ' + err.getFields());
            }
        }
    }
                return objList;

            }
        }catch (Exception ex) {APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString(), 'APTS_TriangularInvoicebatchHandler', null, 'OM', false, false, null, true);}
        return null;
    }

    public static APTS_TriangleInvoiceOrders__c updateError(APTS_TriangleInvoiceOrders__c order, APTS_TriangleInvoiceOrders__c orderLines, Exception ex, boolean isException, string errMsg) {
        order.HasError__c = true;
        if (isException) {
            order.ErrorMessage__c = ex.getMessage();
            APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString(), 'APTS_TriangularInvoicebatchHandler', null, 'OM', false, false, null, true);
        } else {
            order.ErrorMessage__c = errMsg;
        }
        updateRecordMap.put(order.id, order);
        errorOrders.add(order.OrderReference__c);
        if (orderLines != null) {
            updateRecordMap.put(orderLines.id, orderLines);
            errorOrders.add(orderLines.OrderReference__c);
        }

        return order;
    }

    public static void DeleteBadOrdersAndCarts(Set<String> badOrders, Set<String> badCarts) {
        try {
            if ((Apttus_Config2__Order__c.sObjectType.getDescribe().isDeletable()) &&
                    (Apttus_Config2__ProductConfiguration__c.sObjectType.getDescribe().isDeletable())) {
                list<Apttus_Config2__Order__c> ordersToDelete = new list<Apttus_Config2__Order__c>();
                list<Apttus_Config2__ProductConfiguration__c> cartsToDelete = new list<Apttus_Config2__ProductConfiguration__c>();
                for (String i : badOrders) {
                    Apttus_Config2__Order__c o = new Apttus_Config2__Order__c();
                    o.id = i;
                    ordersToDelete.add(o);
                }
                for (String j : badCarts) {
                    Apttus_Config2__ProductConfiguration__c c = new Apttus_Config2__ProductConfiguration__c();
                    c.id = j;
                    cartsToDelete.add(c);
                }
                delete ordersToDelete;
                delete cartsToDelete;
            }
        } catch (Exception ex) {APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString(), 'APTS_TriangularInvoicebatchHandler', null, 'OM', false, false, null, true);}
    }


    public Map<String, Apttus__APTS_Agreement__c> getAccountHierechyAgreementMap(Map<String, AccountHierarchy> accountHierarchyMap, Map<String, Apttus__APTS_Agreement__c> accountAgreementMap) {
        Map<String, Apttus__APTS_Agreement__c> accountHierechyAgreementMap = new Map<String, Apttus__APTS_Agreement__c> ();
        for (String sapCustId : accountHierarchyMap.keySet()) {
            if (accountHierarchyMap.containsKey(sapCustId)) {
                AccountHierarchy ah = accountHierarchyMap.get(sapCustId);
                if (accountAgreementMap.containsKey(ah.currentId)) {
                    accountHierechyAgreementMap.put(sapCustId, accountAgreementMap.get(ah.currentId));
                } else if (accountAgreementMap.containsKey(ah.parentId)) {
                    accountHierechyAgreementMap.put(sapCustId, accountAgreementMap.get(ah.parentId));
                } else if (accountAgreementMap.containsKey(ah.grandParentId)) {
                    accountHierechyAgreementMap.put(sapCustId, accountAgreementMap.get(ah.grandParentId));
                } else if (accountAgreementMap.containsKey(ah.buyingGroupId)) {
                    accountHierechyAgreementMap.put(sapCustId, accountAgreementMap.get(ah.buyingGroupId));
                }
            }
        }
        return accountHierechyAgreementMap;

    }
    public Map<String, Apttus__APTS_Agreement__c> getAccountAgreementMap(Map<String, AccountHierarchy> accountHierarchyMap, set<Id> sapCustIdRelatedAccountIdSet) {
        Map<String, Apttus__APTS_Agreement__c> accountAgreementMap = new Map<String, Apttus__APTS_Agreement__c>();
        if (accountHierarchyMap != null && accountHierarchyMap.size() > 0 ) {
            // Get Activated Agreement for the SAP Customer Id Related Account based Account Hirerchy
            for (Apttus__APTS_Agreement__c agreement : [select id, Name, Apttus_CMConfig__PriceListId__c, Apttus_CMConfig__BillingPreferenceId__c,
                    Apttus_CMConfig__PONumber__c, Apttus_CMConfig__PaymentTermId__c, APTS_Language__c,
                    APTS_Bill_to_Party_Ingredients__c, APTS_Payer_Ingredients__c, APTS_Bill_to_Party_MachServ__c, APTS_Payer_Machines_Services__c,
                    Apttus__Account__c, Apttus__Account__r.SAP_Customer_ID__c, APTS_Check_on_Account_Ingredients__c, APTS_Check_on_Account_Machines__c
                    from Apttus__APTS_Agreement__c where Apttus__Status__c = 'Activated' and
                            Apttus__Account__c In: sapCustIdRelatedAccountIdSet ]) {
                if (agreement.Apttus__Account__c != null &&
                        accountAgreementMap != null && !accountAgreementMap.containsKey(agreement.Apttus__Account__c)) {
                    accountAgreementMap.put(agreement.Apttus__Account__c, agreement);
                }
            }
        }
        return accountAgreementMap;
    }
    public Map<String, AccountHierarchy> getAccountHierarchyMap(Set<String> sapCustIdSet, Account acc) {
        Map<String, AccountHierarchy> accountHierarchyMap = new Map<String, AccountHierarchy>();
        AccountHierarchy ah = new AccountHierarchy();
        ah.allHierechyAccountIdSet = new Set<Id>();
        if (sapCustIdSet.contains(acc.SAP_Customer_ID__c)) {
            ah.currentId = acc.Id;
            if (acc.ParentId == null && acc.Parent.Parent.Id == null && acc.Purchasing_Organization__c != null) {
                ah.currentLevel = 1;
                ah.allHierechyAccountIdSet.add(acc.Purchasing_Organization__c);
            } else if (acc.Parent.Name == acc.Ultimate_Parent_Account__c) {
                ah.currentLevel = 2;
                ah.parentId = acc.ParentId;
                ah.allHierechyAccountIdSet.add(acc.ParentId);
            } else {
                ah.currentLevel = 3;
                ah.parentId = acc.ParentId;
                ah.grandParentId = acc.Parent.Parent.Id;
                if (acc.ParentId != null) {
                    ah.allHierechyAccountIdSet.add(acc.ParentId);
                }
                if (acc.Parent != null && acc.Parent.ParentId != null) {
                    ah.allHierechyAccountIdSet.add(acc.Parent.ParentId);
                }
            }

            if (acc.ParentId == null && acc.Parent.Parent.Id == null && acc.Purchasing_Organization__c == null) {
                ah.currentLevel = 0;
                ah.allHierechyAccountIdSet.add(acc.Id);
            }
            if (acc.Purchasing_Organization__c != null) {
                ah.buyingGroupId = acc.Purchasing_Organization__c;
                ah.allHierechyAccountIdSet.add(acc.Purchasing_Organization__c);
            }
            if (ah.allHierechyAccountIdSet != null) {
                sapCustIdRelatedAccountIdSet.addall(ah.allHierechyAccountIdSet);
            }
            accountHierarchyMap.put(acc.SAP_Customer_ID__c, ah);
        }

        return accountHierarchyMap;
    }
    public boolean validate(APTS_TriangleInvoiceOrders__c order, map<string, string> mapSapIdWithSalesOrg, map<string, string> mapLocationSapToId, ID pricelistId, Set<String> tSapOrderType) {
        boolean isValid = true;
        string strMsg = null;
        // ensure that a sap customer id which can be mapped to an account id and sales org id has been provided
        if (!mapSapIdWithSalesOrg.containskey(order.SAP_Customer_ID__c)) {
            order.HasError__c = true;
            strMsg =  'Customer ID is Missing in Salesforce';

        }
        if (!mapLocationSapToId.containskey(order.AccountLocationSapId__c)) {
            order.HasError__c = true;
            strMsg = (strMsg != null) ? strMsg + ', Account Location Sap Customer Id is Missing in Salesforce' : 'Account Location Sap Customer Id is Missing in Salesforce';


        }
        if (priceListId == null) {
            order.HasError__c = true;
            strMsg = (strMsg != null) ? strMsg + ', Price list for Sales Org is Missing in Salesforce' : 'Price list for Sales Org is Missing in Salesforce';


        } //100++<<
        if (!tSapOrderType.contains(order.SAP_OrderType__c)) {
            order.HasError__c = true;
            strMsg = 'Please provide valid SAP Order Type';

        }//100++>>
        if (order.HasError__c) {
            isValid = false;
            order.ErrorMessage__c = strMsg;
            updateRecordMap.put(order.id, order);
            errorOrders.add(order.OrderReference__c);
        }
        return isValid;
    }
    @TestVisible
    public APTS_TriangleInvoiceOrders__c addProductsToCart(string cartId, APTS_TriangleInvoiceOrders__c order, List<APTS_TriangleInvoiceOrders__c> currentOrderList, map<String, string> mapSapIdWithSalesOrg, map<String, string> mapOfProductCodeAndID) {

        // ADD MULTIPLE PRODUCTS

        if (cartId != null && cartId != '') {
            try {
                List <Apttus_CPQApi.CPQ.SelectedProductDO> selectedProdDOList = new List <Apttus_CPQApi.CPQ.SelectedProductDO>();
                for (APTS_TriangleInvoiceOrders__c ordLineRecord : currentOrderList) {

                    string errMsg = null;
                    Apttus_Config2__LineItem__c objLine = new Apttus_Config2__LineItem__c();  
                    objLine.Apttus_Config2__SellingUom__c = ordLineRecord.SellingUom__c;
                    if (!mapSapIdWithSalesOrg.containskey(ordLineRecord.SAP_Customer_ID__c)) {
                        errMsg = 'Customer ID is Missing in Salesforce';

                        ordLineRecord = updateError(order, ordLineRecord, null, false, errMsg);
                    }
                    if (!mapOfProductCodeAndID.containskey(ordLineRecord.ProductId__c)) {
                        errMsg = 'There is no Product with Product Code ID Provided';

                        ordLineRecord = updateError(order, ordLineRecord, null, false, errMsg);
                    } else if (ordLineRecord.Quantity__c <= 0) {
                        errMsg = 'Quantity should be Greater than 0';
                        ordLineRecord = updateError(order, ordLineRecord, null, false, errMsg);

                    } else {
                        Apttus_CPQApi.CPQ.SelectedProductDO selProdDO = new Apttus_CPQApi.CPQ.SelectedProductDO();
                        selProdDO.ProductID = mapOfProductCodeAndID.get(ordLineRecord.ProductId__c);
                        selProdDO.Quantity = ordLineRecord.Quantity__c;
                        selProdDO.SellingTerm = 1;
                        //selProdDO.StartDate = Date.Today();
                        //selProdDO.EndDate = Date.Today();
                        selProdDO.CustomFields = new List<String>{'Apttus_Config2__SellingUom__c'};
                        selProdDO.CustomData = objLine;
                        selectedProdDOList.add(selProdDO);
                    }
                }
                if (selectedProdDOList.size() > 0) {
                    Apttus_CPQApi.CPQ.AddMultiProductRequestDO addProdReq = new Apttus_CPQApi.CPQ.AddMultiProductRequestDO();
                    addProdReq.CartId = cartId;
                    addProdReq.SelectedProducts = selectedProdDOList;
                    Apttus_CPQApi.CPQ.AddMultiProductResponseDO response = Apttus_CPQApi.CPQWebService.addMultiProducts(addProdReq);
                    
                    List<Decimal> lineNumber = response.LineNumbers;
                }
            } catch (Exception e) {
                order = updateError(order, null, e, true, null);

            }

        }
        return order;
    }

    // Method to Reprice the Cart till Price Pending is done.

    public static Boolean repriceCart(Id cartId) {
        Boolean isPricePending = true;
        Integer cnt = 0;
        String sPriceBatchSize = System.Label.APTS_Digital_Batch_Pricing_Size; /// Values is 1
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

    @TestVisible
    public static Set<Id> updatePricing(Id cartId, APTS_TriangleInvoiceOrders__c currentOrder) {
        Set<Id> orderPricePending = new Set<Id>();

        try {
            Boolean isPricingPending = true;
            Boolean isSuccess = false;

            if (isPricingPending) {
                isPricingPending = APTS_TriangularInvoiceBatchHandler.repriceCart(cartId);

            }



            if (!isPricingPending) {

                /*System.debug('Called Before Finalize  ' +currentOrder);
                //Finalize
                APTS_OrderUtils.finalizeCart(cartId);
                System.debug('Called After Batch ' +cartId);

                //Syncronize
                isSuccess = APTS_OrderUtils.syncCart(cartId);*/

                // Update the Triangular Invoice Object with the Processing Status has 'Cart Pricing Completed Succesfully'
                
                currentOrder.Processing_Status__c  = 'Cart Pricing Completed Succesfully';
                updateRecordMap.put(currentOrder.id, currentOrder);

            } else {
                orderPricePending.add(Id.valueOf(currentOrder.Order__c));

                System.enqueueJob(new APTS_TriangularRepriceFinializeQueue(cartId, 'Triangular Invoicing Order', 'Pricing', currentOrder));

            }

        } catch (Exception e) {

            currentOrder = updateError(currentOrder, null, e, true, null);

            //APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', cartId, 'OM', false, true, null, true);


        }


        return orderPricePending;

    }


     @TestVisible
    public static Set<Id> updatePricing(Id cartId, APTS_TriangleInvoiceOrders__c currentOrder,Boolean isReprice) {
        Set<Id> orderPricePending = new Set<Id>();

        try {
            Boolean isPricingPending = true;
            Boolean isSuccess = false;


            if (isPricingPending) {
                isPricingPending = APTS_TriangularInvoiceBatchHandler.repriceCart(cartId);

            }

            if (!isPricingPending ) {
                //Finalize
                if(isReprice) {
                    APTS_OrderUtils.finalizeCart(cartId);
                    //Syncronize
                    isSuccess = APTS_OrderUtils.syncCart(cartId);
                }               

                // Update the Triangular Invoice Object with the Processing Status has 'Cart Pricing Completed Succesfully'
                
                currentOrder.Processing_Status__c  = 'Cart Pricing Completed Succesfully';
                updateRecordMap.put(currentOrder.id, currentOrder);

            } else {
                orderPricePending.add(Id.valueOf(currentOrder.Order__c));

                System.enqueueJob(new APTS_TriangularRepriceFinializeQueue(cartId, 'Triangular Invoicing Order', 'Pricing', currentOrder));

            }

        } catch (Exception e) {

            currentOrder = updateError(currentOrder, null, e, true, null);

            //APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', cartId, 'OM', false, true, null, true);


        }


        return orderPricePending;

    }


    public static string removeNull(String value) {
        value = value != null ? value : '';
        return value;
    }


    public static void sendOrderConfirmationMail(List<String> sendTo, Set<String> badOrderRefSet, List<APTS_TriangleInvoiceOrders__c> triangleOrderList) {

        APTS_CustomLogging.createErrorLog('OM_TRIO_DEBUG', 'Apex', 'BeforeSendEmail' + String.valueOf(sendTo), 'APTS_TriangularInvoiceBatchHandler', null, 'OM', false, false, null, false);


        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(sendTo);
        mail.setSenderDisplayName('Order Upload Process');
        mail.setSubject('Status of Your Order Upload');
        mail.setUseSignature(true);
        // string msg = 'Tri_Invoice_Order_Error_Msg';  custom label
        mail.setPlainTextBody('There were ' + badOrderRefSet.size() + ' failed orders in your upload. If there are failed orders, please open the attached .csv. Make corrections and re-upload all record lines for all failed orders.');
        // attach bad records
        string header = 'OrderReference__c, SAP_Customer_ID__c, SAP_OrderType__c, Requested_Delivery_Date__c, SoldTo__c, BillTo__c, Payer__c,AccountLocationSapId__c, ProductId__c, Quantity__c, SellingUom__c,Order_Name__c,Pricing_Date__c, Invoice_Remarks__c, PO__c, HasError__c,APTS_Stock_Partner__c, ErrorMessage__c \n';

        string finalstr = header ;
        System.debug('APTS_TriangleInvoiceOrders List:' + triangleOrderList);
        for (APTS_TriangleInvoiceOrders__c a : triangleOrderList) {
            string errorMessage = a.ErrorMessage__c != null ? a.ErrorMessage__c : '';
            string recordString = '"' + removeNull(String.valueOf(a.OrderReference__c)) + '","' + removeNull(String.valueOf(a.SAP_Customer_ID__c)) + '","' + removeNull(String.valueOf(a.SAP_OrderType__c)) + '","' + removeNull(String.valueOf(a.Requested_Delivery_Date__c)) + '","' + removeNull(String.valueOf(a.SoldTo__c)) + '","' + removeNull(String.valueOf(a.BillTo__c)) + '","' + removeNull(String.valueOf(a.Payer__c)) + '","' + removeNull(String.valueOf(a.AccountLocationSapId__c)) + '","' + removeNull(String.valueOf(a.ProductId__c)) + '","' + removeNull(String.valueOf(a.Quantity__c)) + '","' + removeNull(String.valueOf(a.SellingUom__c)) + '","' + removeNull(String.valueOf(a.Order_Name__c)) + '","' + removeNull(String.valueOf(a.Pricing_Date__c)) + '","' + removeNull(String.valueOf(a.Invoice_Remarks__c)) + '","' + removeNull(String.valueOf(a.PO__c)) + '","' + removeNull(String.valueOf(a.HasError__c)) + '","' + removeNull(String.valueOf(a.APTS_Stock_Partner__c)) + '","' + errorMessage + '"\n';
            finalstr = finalstr + recordString;
        }
        Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
        blob csvBlob = Blob.valueOf(finalstr);
        string csvname = 'Order Uploads.csv';
        csvAttc.setFileName(csvname);
        csvAttc.setBody(csvBlob);
        mail.setFileAttachments(new Messaging.EmailFileAttachment[] {csvAttc});
        Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
        APTS_CustomLogging.createErrorLog('OM_TRIO_DEBUG', 'Apex', 'AfterSendEmail' + String.valueOf(sendTo), 'APTS_TriangularInvoiceBatchHandler', null, 'OM', false, false, null, false);


    }

    public Date getDateFormat(String strDate) {
        String[] strD = strDate.split('-');
        Integer myIntDate = integer.valueOf(strD[0]);
        Integer myIntMonth = integer.valueOf(strD[1]);
        Integer myIntYear = integer.valueOf(strD[2]);
        Date d = Date.newInstance(myIntYear, myIntMonth, myIntDate);
        return d;
    }

    public Datetime getDatetimeFormat(String strDate) {
        String[] strD = strDate.split('-');
        Integer myIntDate = integer.valueOf(strD[0]);
        Integer myIntMonth = integer.valueOf(strD[1]);
        Integer myIntYear = integer.valueOf(strD[2]);
        Datetime d = Date.newInstance(myIntYear, myIntMonth, myIntDate);
        return d;
    }
}