/**
* @author        Balashanthi A
* @date          21.02.2018           
* @description   Class which will create order on saving credit memo record
* @revision(s)   v101 - CR 2040 - Pranjal Mittal
******************************************************************/
//V102 - #5452 - Payer partner function on Admin order with Order subtype 'Credit memo' is incorrect - Nagavi
//V103 - Defect # 6023 - Credit memo- Wrong listprice
//v104 - QTCFLEX1-1583 - Enable checkbox logic for BillingFields
//v105 - DQ-2060 07/07/2020 - Payer Field should be one-to-one mapping if credit memo is created from Invoice
//v106 - DQ-4789 Renuka: FixTermBillingFlag mapping correction
//v107 - DQ-5130 Manisha: Cascading Po number from credit memo to order
//v108 - DQ-5736 Manisha: Cascading Assignment from credit memo to order

public without sharing class APTS_CreditMemoTriggerHandler implements ITriggerHandler{
    
private static final String ORDERLINEITEM = 'Apttus_Config2__OrderLineItem__c';
private static final String ADJUSTLINEITESOBJ ='Apttus_Config2__OrderAdjustmentLineItem__c';
private static final String INTEGRATIONSOBJ='Integration_Log__c';
private static final String SINGLEINVOICE='Single Invoice';
private static final String INGREDIENTS='Ingredients';    
private static final String MISC='Misc';
private static final String SALES='Sales';
private static final string PRINT ='P001';
private static final string EMAIL ='P002';
private static final string EDI ='P003';
private static final string CUSTPORT ='P004';
private static final string LOCK_MESSAGE = 'This Credit Memo is locked due to Approval';

    public boolean isDisabled(){
        Boolean triggerDisabled = false;
        try{
            TriggerSettings__c tiggerSettings =  TriggerSettings__c.getInstance();
            if(tiggerSettings.APTS_Credit_Memo_Trigger__c){
                triggerDisabled = true;
            }
        }
        catch(Exception e){
            triggerDisabled = false;
        }
        return triggerDisabled;
    }

    /** Method Name : beforeInsert
        * Description   : Method to get executed before Inserting a credit Memo record
        **/
    public void beforeInsert(List<SObject> newItems){try{}catch(Exception e){}} 

     /** Method Name : beforeUpdate
        *   Description : Method to get executed before Updating a credit Memo record
        **/ 
    public void beforeUpdate(List<SObject> newList, Map<Id, SObject> newItems, 
                                             List<SObject> oldList, Map<Id, SObject> oldItems){
        try{

         Map<Id, Apttus_Billing__CreditMemo__c> mapOldCreditMemo = (Map<Id, Apttus_Billing__CreditMemo__c>)oldItems;
          List<Apttus_Billing__CreditMemo__c> listNeeCreditMemo = (List<Apttus_Billing__CreditMemo__c>)newList;

          for(Apttus_Billing__CreditMemo__c crmemo : listNeeCreditMemo){
            if(mapOldCreditMemo.get(crmemo.Id).APTS_LockCreditMemo__c && crmemo.APTS_LockCreditMemo__c && mapOldCreditMemo.get(crmemo.Id).APTS_Approval_Status__c == crmemo.APTS_Approval_Status__c && !Test.isRunningTest()){
              crmemo.addError(LOCK_MESSAGE);
            }
          }
        }catch(Exception e){
            APTS_BIRUtils.logError(null,null,null,e,APTS_BIRUtils.TRIGGERVALUE,APTS_BIRUtils.ORDEROBJECTNAME,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,false);
        }
    }

     /** Method Name : beforeDelete
        *   Description : before Delete of credit Memo record
        **/
    public void beforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems){try{}catch(Exception e){}} 
     
     /** Method Name : afterInsert
        *   Description : afterInsert of credit Memo record
        **/
    public void afterInsert(List<SObject> newCMRHeaderList, Map<Id, SObject> newItems){try{}catch(Exception e){}}
 
     /*** Method Name  : afterUpdate
        * Description : afterUpdate of credit Memo record
        **/
    public void afterUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldItems){
        set<String> setInvPrf;
        // Variable declaration
        Map<Id,Apttus_Billing__Invoice__c> invoiceMap = new Map<Id,Apttus_Billing__Invoice__c>();
        //Map<Id,Case> caseMap = new Map<Id,Case>();
        Map<Id,Apttus_Config2__Order__c> orderToInsertMap = new Map<Id,Apttus_Config2__Order__c>();
        List<Integration_Log__c> integrationLogListToInsert = new List<Integration_Log__c>();
        //Map<Id,List<Apttus_Billing__CreditMemoLineItem__c>> creditLineItemMap = new Map<Id,List<Apttus_Billing__CreditMemoLineItem__c>>();
        Set<Id> invoiceId = new Set<Id>();
        //Set<Id> caseId = new Set<Id>();
        Set<Id> accountId = new Set<Id>();
        Set<Id> creditMemoId = new Set<Id>();
        Map<Id,Account> accountMap = new Map<Id,Account>();
        Map<Id, Apttus_Billing__InvoiceLineItem__c> mapInvoiceIdOrder = new Map<Id, Apttus_Billing__InvoiceLineItem__c>();
        Map<Id, Id> mapInvoiceIdBillingId = new Map<Id, Id>();
        Map<Id, Id> mapAccIdContactId = new Map<Id, Id>();
        Set<String> setSalesOrgManual = new Set<String>();
        Map<String, Apttus_Config2__PriceListItem__c> mapKeyPLI = new Map<String, Apttus_Config2__PriceListItem__c>();
        Map<String, Id> mapKeyPriceListId = new Map<String, Id>();
        Set<Id> orderLineItemUsed = new Set<Id>();
        Set<Id> setProductUsedManual = new Set<Id>();
        Map<Id,Apttus_Billing__CreditMemo__c> creditAgrAccMap = new Map<Id,Apttus_Billing__CreditMemo__c>();
        //Added as part of defect #21150 by Nagavi
        Set<Id> creditDemoContractId= new set<Id>();
        map<Id, APTS_Billing_Settings__c> contractBillingPrefMap= new map<Id, APTS_Billing_Settings__c>();
        map<Id,APTS_Agreement_PO_Details__c> mapContarctPOnum = new  map<Id,APTS_Agreement_PO_Details__c>();      

        try{
            Map<Id,Apttus_Billing__CreditMemo__c> creditMemoNew = (Map<Id,Apttus_Billing__CreditMemo__c>)newItems;
            Map<Id,Apttus_Billing__CreditMemo__c> creditMemoOld = (Map<Id,Apttus_Billing__CreditMemo__c>)oldItems;
            
             
            setInvPrf = new Set<String>{PRINT,EMAIL,EDI,CUSTPORT};
            // New Order Creation
            for(Apttus_Billing__CreditMemo__c creditMemo : creditMemoNew.values()){
                if (!APTS_BIRUtils.APPROVED.equalsIgnoreCase(creditMemoOld.get(creditMemo.Id).APTS_Approval_Status__c)
                        && APTS_BIRUtils.APPROVED.equalsIgnoreCase(creditMemo.APTS_Approval_Status__c)){
                    // Getting invoice Number from credit memo
                    if(creditMemo.Apttus_Billing__InvoiceID__c != null){
                        invoiceId.add(creditMemo.Apttus_Billing__InvoiceID__c);
                        
                        mapInvoiceIdBillingId.put(creditMemo.Apttus_Billing__InvoiceID__c, creditMemo.Id);
                    }

                    // Getting Sold to account from credit memo
                    if(creditMemo.APTS_Sold_To_Account__c  != null){
                        accountId.add(creditMemo.APTS_Sold_To_Account__c);   
                    }
                    
                    // Getting Bill to account from credit memo
                    if(creditMemo.Apttus_Billing__BillToAccountId__c  != null){
                        accountId.add(creditMemo.Apttus_Billing__BillToAccountId__c);   
                    }
                    creditMemoId.add(creditMemo.Id);
                }
            }

            if(creditMemoId.size() > 0){
                for(Apttus_Billing__CreditMemo__c crmemo : [Select id, APTS_Credit_Contract__c, APTS_Credit_Contract__r.APTS_Payer_Ingredients__c,
                                                                    APTS_Credit_Contract__r.APTS_Check_on_Account_Ingredients__c, 
                                                                    APTS_Sold_To_Account__r.Related_Payer_Account__c,APTS_Credit_Contract__r.APTS_Bill_to_Party_Ingredients__c,
                                                                    Apttus_Billing__BillToAccountId__c,Apttus_Billing__BillToAccountId__r.Related_Payer_Account__c, 
                                                                    Apttus_Billing__BillToAccountId__r.Bill_To_Payer_Account__c,
                                                                    APTS_Sold_To_Account__r.Apttus_Config2__BillingPreferenceId__c,
                                                                    APTS_Sold_To_Account__r.APTS_Payment_Method__c,
                                                                    APTS_Sold_To_Account__r.APTS_Payment_Method__r.APTS_Payment_Method_Code__c,
                                                                    APTS_Sold_To_Account__r.Apttus_Config2__PaymentTermId__c,
                                                                    APTS_Sold_To_Account__r.Bill_To_Payer_Account__r.Apttus_Config2__BillingPreferenceId__c,
                                                                    APTS_Sold_To_Account__r.Bill_To_Payer_Account__r.APTS_Payment_Method__c,
                                                                    APTS_Sold_To_Account__r.Bill_To_Payer_Account__r.APTS_Payment_Method__r.APTS_Payment_Method_Code__c,
                                                                    APTS_Sold_To_Account__r.Bill_To_Payer_Account__r.Apttus_Config2__PaymentTermId__c
                                                                     FROM Apttus_Billing__CreditMemo__c WHERE Id IN: creditMemoId LIMIT 50000]){
                    creditAgrAccMap.put(crmemo.Id, crmemo);
                //Added as part of defect #21150                                           
                if(crmemo.APTS_Credit_Contract__c != null){
                    creditDemoContractId.add(crmemo.APTS_Credit_Contract__c);
                }                                                       
                }
            }
            //Added as part of defect #21150 ; //Defect Fix : 22569- AS
            if(!creditDemoContractId.isEmpty()){
                for(APTS_Billing_Settings__c billSetting:[Select id,APTS_Agreement_ID__c,APTS_Agreement_Billing_Type__c,APTS_Invoice_Delivery_Preference__c,APTS_Billing_Preference_Setting__c,
                                                          APTS_Payment_Term_Setting__c,APTS_Payment_Method__c,APTS_Payment_Method__r.APTS_Payment_Method_Code__c  
                                                         from APTS_Billing_Settings__c where APTS_Agreement_ID__c IN:creditDemoContractId AND APTS_Agreement_Billing_Type__c=:INGREDIENTS LIMIT 50000]){
                    
                    contractBillingPrefMap.put(billSetting.APTS_Agreement_ID__c,billSetting);
                }
                //Defect Fix : 22569- AS
                for(APTS_Agreement_PO_Details__c IngPOnum : [select id,APTS_PO_Number__c,APTS_Agreement__c,APTS_PO_Expiration_Date__c  from APTS_Agreement_PO_Details__c where 
                                                            APTS_PO_Category__c =:INGREDIENTS and  APTS_Agreement__c  IN:creditDemoContractId order by LastModifiedDate desc limit 1
                                                            ]){
                    mapContarctPOnum.put(IngPOnum.APTS_Agreement__c,IngPOnum);
                }
            }
            Map<String, String> invoiceDeliveryPreferenceMap = new Map<String, String>();
            for(APTS_Invoice_Delivery_Preference__mdt meta : [SELECT Id, MasterLabel, APTS_Value__c FROM APTS_Invoice_Delivery_Preference__mdt where MasterLabel NOT IN :setInvPrf ]){
                invoiceDeliveryPreferenceMap.put(meta.MasterLabel, meta.APTS_Value__c);
            }
            system.debug('invoiceDeliveryPreferenceMap --> '+invoiceDeliveryPreferenceMap);

            if(invoiceId.size() > 0){
         // Invoice Map preparation
                for(Apttus_Billing__Invoice__c invoice :[SELECT Id, 
                                                                APTS_External_Invoice_Number__c,
                                                                Apttus_Billing__ShipToAccountId__c
                                                            FROM Apttus_Billing__Invoice__c
                                                            WHERE ID IN: invoiceId
                                                            LIMIT 50000]){
                    // Invoice Map
                    invoiceMap.put(invoice.Id, invoice);
                }
                
                for (Apttus_Billing__InvoiceLineItem__c tmpOrder : [SELECT Id, 
                                                                            APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.Derived_From_Order__c,
                                                                            APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.APTS_InvoiceDeliveryPreference__c,
                                                                            APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.APTS_Invoice_List_Indicator__c,
                                                                            APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.RecordTypeId,
                                                                            APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__Status__c,
                                                                            APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.APTS_Status__c,
                                                                            APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c,
                                                                            APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.APTS_Order_Type__c,
                                                                            APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.APTS_Remove_Billing_Block_Indicator__c,
                                                                            APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.APTS_InvoiceType__c,
                                                                            APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.APTS_Collective_Billing_Indicator__c,
                                                                            APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__PrimaryContactId__c,
                                                                            APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.APTS_Payment_Method__c,
                                                                            APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.APTS_Payment_Method__r.APTS_Payment_Method_Code__c,
                                                                            APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__PaymentTermId__c,
                                                                            APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__BillingPreferenceId__c,
                                                                            APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__PriceListId__c,
                                                                            APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.Apttus_CMConfig__AgreementId__c,
                                                                            APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__SoldToAccountId__c,
                                                                            APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__BillToAccountId__c,
                                                                            APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.APTS_Bill_to_Party_Ingredients_and_Payer__c,
                                                                            APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.APTS_Bill_to_Party_Machines_Services__c,
                                                                            APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.APTS_Payer__c,
                                                                            APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.APTS_PayerIngredients__c,
                                                                            APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.APTS_PayerMachinesServices__c,
                                                                            APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__LocationId__c,
                                                                            APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__OrderStartDate__c,
                                                                            APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__PricingDate__c,
                                                                            APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.APTS_Fix_Term_Billing_Flag__c,
                                                                            APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__PONumber__c,
                                                                            APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__PODate__c,
                                                                            APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.APTS_Sales_Organization__c,
                                                                            APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.APTS_Distribution_Channel__c,
                                                                            APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.APTS_Division__c,
                                                                            APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c,
                                                                            APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.APTS_Sold_To_SAP_Customer_ID__c,
                                                                            APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.APTS_Ship_To_Location_SAP_Customer_Id__c,
                                                                            APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.APTS_Bill_To_SAP_Customer_ID__c,
                                                                            APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.APTS_Payer_SAP_Customer_ID__c,
                                                                            APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__Description__c,
                                                                            APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.APTS_Order_Reason__c,
                                                                            APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__c,
                                                                            Apttus_Billing__InvoiceId__c,
                                                                            APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.Apttus_CMConfig__AgreementId__r.APTS_Fixed_Term_Type__c,
                                                                            APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.Apttus_CMConfig__AgreementId__r.Apttus_CMConfig__PONumber__c,
                                                                            APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__SoldToAccountId__r.Division__c,
                                                                            APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__SoldToAccountId__r.Distribution_Channel__c,
                                                                            APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__SoldToAccountId__r.Sales_Organization__c,
                                                                            APTS_Order_Line__r.Apttus_Config2__OrderId__r.Derived_From_Order__c,
                                                                            APTS_Order_Line__r.Apttus_Config2__OrderId__r.APTS_InvoiceDeliveryPreference__c,
                                                                            APTS_Order_Line__r.Apttus_Config2__OrderId__r.APTS_Invoice_List_Indicator__c,
                                                                            APTS_Order_Line__r.Apttus_Config2__OrderId__r.RecordTypeId,
                                                                            APTS_Order_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__Status__c,
                                                                            APTS_Order_Line__r.Apttus_Config2__OrderId__r.APTS_Status__c,
                                                                            APTS_Order_Line__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c,
                                                                            APTS_Order_Line__r.Apttus_Config2__OrderId__r.APTS_Order_Type__c,
                                                                            APTS_Order_Line__r.Apttus_Config2__OrderId__r.APTS_Remove_Billing_Block_Indicator__c,
                                                                            APTS_Order_Line__r.Apttus_Config2__OrderId__r.APTS_InvoiceType__c,
                                                                            APTS_Order_Line__r.Apttus_Config2__OrderId__r.APTS_Collective_Billing_Indicator__c,
                                                                            APTS_Order_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__PrimaryContactId__c,
                                                                            APTS_Order_Line__r.Apttus_Config2__OrderId__r.APTS_Payment_Method__c,
                                                                            APTS_Order_Line__r.Apttus_Config2__OrderId__r.APTS_Payment_Method__r.APTS_Payment_Method_Code__c,
                                                                            APTS_Order_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__PaymentTermId__c,
                                                                            APTS_Order_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__BillingPreferenceId__c,
                                                                            APTS_Order_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__PriceListId__c,
                                                                            APTS_Order_Line__r.Apttus_Config2__OrderId__r.Apttus_CMConfig__AgreementId__c,
                                                                            APTS_Order_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__SoldToAccountId__c,
                                                                            APTS_Order_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__BillToAccountId__c,
                                                                            APTS_Order_Line__r.Apttus_Config2__OrderId__r.APTS_Bill_to_Party_Ingredients_and_Payer__c,
                                                                            APTS_Order_Line__r.Apttus_Config2__OrderId__r.APTS_Bill_to_Party_Machines_Services__c,
                                                                            APTS_Order_Line__r.Apttus_Config2__OrderId__r.APTS_Payer__c,
                                                                            APTS_Order_Line__r.Apttus_Config2__OrderId__r.APTS_PayerIngredients__c,
                                                                            APTS_Order_Line__r.Apttus_Config2__OrderId__r.APTS_PayerMachinesServices__c,
                                                                            APTS_Order_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__LocationId__c,
                                                                            APTS_Order_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__OrderStartDate__c,
                                                                            APTS_Order_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__PricingDate__c,
                                                                            APTS_Order_Line__r.Apttus_Config2__OrderId__r.APTS_Fix_Term_Billing_Flag__c,
                                                                            APTS_Order_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__PONumber__c,
                                                                            APTS_Order_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__PODate__c,
                                                                            APTS_Order_Line__r.Apttus_Config2__OrderId__r.APTS_Sales_Organization__c,
                                                                            APTS_Order_Line__r.Apttus_Config2__OrderId__r.APTS_Distribution_Channel__c,
                                                                            APTS_Order_Line__r.Apttus_Config2__OrderId__r.APTS_Division__c,
                                                                            APTS_Order_Line__r.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c,
                                                                            APTS_Order_Line__r.Apttus_Config2__OrderId__r.APTS_Sold_To_SAP_Customer_ID__c,
                                                                            APTS_Order_Line__r.Apttus_Config2__OrderId__r.APTS_Ship_To_Location_SAP_Customer_Id__c,
                                                                            APTS_Order_Line__r.Apttus_Config2__OrderId__r.APTS_Bill_To_SAP_Customer_ID__c,
                                                                            APTS_Order_Line__r.Apttus_Config2__OrderId__r.APTS_Payer_SAP_Customer_ID__c,
                                                                            APTS_Order_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__Description__c,
                                                                            APTS_Order_Line__r.Apttus_Config2__OrderId__r.APTS_Order_Reason__c,
                                                                            APTS_Order_Line__r.Apttus_Config2__OrderId__c,
                                                                            APTS_Order_Line__r.Apttus_Config2__OrderId__r.Apttus_CMConfig__AgreementId__r.APTS_Fixed_Term_Type__c,
                                                                            APTS_Order_Line__r.Apttus_Config2__OrderId__r.Apttus_CMConfig__AgreementId__r.Apttus_CMConfig__PONumber__c,
                                                                            APTS_Order_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__SoldToAccountId__r.Division__c,
                                                                            APTS_Order_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__SoldToAccountId__r.Distribution_Channel__c,
                                                                            APTS_Order_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__SoldToAccountId__r.Sales_Organization__c
                                                                            FROM Apttus_Billing__InvoiceLineItem__c
                                                                            WHERE Apttus_Billing__InvoiceId__c IN: invoiceId 
                                                                            AND (APTS_AdminOrder_Line__c !=NULL OR APTS_Order_Line__c != NULL)
                                                                            LIMIT 50000]){
                    //Map of InvoideId-->Order
                    mapInvoiceIdOrder.put(tmpOrder.Apttus_Billing__InvoiceId__c, tmpOrder);
                }
            }
            //system.debug('mapInvoiceIdOrder==>'+mapInvoiceIdOrder);
            //system.debug('mapInvoiceIdOrder==>'+mapInvoiceIdOrder.size());
            if(accountId.size() > 0){
                 // Account Map preparation
                for(Account  accountData : [SELECT Id,
                                                    Sales_Organization__c, 
                                                    Division__c, 
                                                    Distribution_Channel__c,
                                                    APTS_Payment_Method__c,
                                                    APTS_Payment_Method__r.APTS_Payment_Method_Code__c,
                                                    Apttus_Config2__PaymentTermId__c,
                                                    Apttus_Config2__BillingPreferenceId__c,
                                                    Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Delivery_Preference__c,
                                                    Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Type__c
                                                FROM Account 
                                                WHERE ID IN: accountId
                                                LIMIT 1000]){
                    // Account Case Map
                    accountMap.put(accountData.Id, accountData);
                    setSalesOrgManual.add(accountData.Sales_Organization__c);
                }
                //system.debug('accountMap==>'+accountMap);
                //system.debug('accountMap==>'+accountMap.size());
                //Creation of AccountId-->ContactId map based of Main commercial person and Main Service Person (Manual Scenario)
                for(Contact tmpContact : [SELECT Id, AccountId, Main_Commercial_Person__c, Main_Service_Person__c FROM Contact
                                        WHERE (Main_Commercial_Person__c = true OR Main_Service_Person__c = true)
                                        AND AccountId IN :accountId LIMIT 50000]){
                    if(!mapAccIdContactId.containsKey(tmpContact.AccountId)){
                        mapAccIdContactId.put(tmpContact.AccountId, NULL);
                        if(tmpContact.Main_Service_Person__c == true){
                            mapAccIdContactId.put(tmpContact.AccountId,tmpContact.Id);
                        }
                        if(tmpContact.Main_Commercial_Person__c == true){
                            mapAccIdContactId.put(tmpContact.AccountId, tmpContact.Id);
                        }
                    }

                    if(mapAccIdContactId.containsKey(tmpContact.AccountId) && mapAccIdContactId.get(tmpContact.AccountId) != NULL){
                        if(tmpContact.Main_Service_Person__c == true){
                            mapAccIdContactId.put(tmpContact.AccountId, tmpContact.Id);
                        }
                        if(tmpContact.Main_Commercial_Person__c == true){
                            mapAccIdContactId.put(tmpContact.AccountId, tmpContact.Id);
                        }
                    }
                                            
                }
            }
            
            //List of Credit Line Items
            Map<Id, Apttus_Billing__CreditMemoLineItem__c> mapOLIIdCreditMemoLine = new Map<Id, Apttus_Billing__CreditMemoLineItem__c>();
            
            for(Apttus_Billing__CreditMemoLineItem__c tmpCreditLine : [SELECT Id,
                                                                            Apttus_Billing__InvoiceLineItemId__r.APTS_AdminOrder_Line__c,
                                                                            Apttus_Billing__InvoiceLineItemId__r.APTS_Order_Line__c,
                                                                            APTS_Product__c,
                                                                            Apttus_Billing__CreditMemoId__c,
                                                                            APTS_Product__r.Name,
                                                                            Apttus_Billing__CreditMemoId__r.Case__c,
                                                                            Apttus_Billing__Quantity__c,
                                                                            APTS_Quantity__c,
                                                                            APTS_BPO__c,
                                                                            Apttus_Billing__Amount__c
                                                                            FROM Apttus_Billing__CreditMemoLineItem__c
                                                                            WHERE Apttus_Billing__CreditMemoId__c IN: creditMemoNew.keySet() LIMIT 50000]){
                if(tmpCreditLine.Apttus_Billing__InvoiceLineItemId__r.APTS_AdminOrder_Line__c != null){
                    orderLineItemUsed.add(tmpCreditLine.Apttus_Billing__InvoiceLineItemId__r.APTS_AdminOrder_Line__c);
                }else if(tmpCreditLine.Apttus_Billing__InvoiceLineItemId__r.APTS_Order_Line__c != null){
                    orderLineItemUsed.add(tmpCreditLine.Apttus_Billing__InvoiceLineItemId__r.APTS_Order_Line__c);
                }
                setProductUsedManual.add(tmpCreditLine.APTS_Product__c);
                if(tmpCreditLine.Apttus_Billing__InvoiceLineItemId__r.APTS_AdminOrder_Line__c != NULL){
                    mapOLIIdCreditMemoLine.put(tmpCreditLine.Apttus_Billing__InvoiceLineItemId__r.APTS_AdminOrder_Line__c, tmpCreditLine);
                }else if(tmpCreditLine.Apttus_Billing__InvoiceLineItemId__r.APTS_Order_Line__c != null){
                    mapOLIIdCreditMemoLine.put(tmpCreditLine.Apttus_Billing__InvoiceLineItemId__r.APTS_Order_Line__c, tmpCreditLine);
                }else{
                    mapOLIIdCreditMemoLine.put(tmpCreditLine.Id, tmpCreditLine);
                }
            }
            //system.debug('mapOLIIdCreditMemoLine==>'+mapOLIIdCreditMemoLine);
            //system.debug('mapOLIIdCreditMemoLine==>'+mapOLIIdCreditMemoLine.size());
            //SOQL for fetching Price List and Price List Item (Manual Scenario)
            for(Apttus_Config2__PriceListItem__c tmpPLI : [SELECT Id, Apttus_Config2__PriceListId__c, APTS_Sales_Org__c,
                                                                Apttus_Config2__ProductId__c,
                                                                Apttus_Config2__BillingFrequency__c,
                                                                Apttus_Config2__BillingRule__c,
                                                                Apttus_Config2__PriceType__c
                                                                FROM Apttus_Config2__PriceListItem__c
                                                                WHERE APTS_Sales_Org__c IN :setSalesOrgManual
                                                                AND Apttus_Config2__ProductId__c IN :setProductUsedManual
                                                                AND Apttus_Config2__PriceListId__r.APTS_PriceList_Type__c = 'Direct'
                                                                AND Apttus_Config2__PriceListId__r.APTS_Region__c IN :setSalesOrgManual
                                                                AND Apttus_Config2__ChargeType__c = 'Sales Price'
                                                                AND Apttus_Config2__PriceListId__r.Apttus_Config2__Active__c = true LIMIT 50000]){
                mapKeyPLI.put((String) tmpPLI.APTS_Sales_Org__c + (String) tmpPLI.Apttus_Config2__ProductId__c, tmpPLI);
                mapKeyPriceListId.put((String) tmpPLI.APTS_Sales_Org__c, tmpPLI.Apttus_Config2__PriceListId__c);
            }
            //Creating order for Credit Memo in automated and manual scenario
            Apttus_Config2__Order__c newOrder = null;
            for(Apttus_Billing__CreditMemo__c creditMemoHeader : creditMemoNew.values()){
                if (!APTS_BIRUtils.APPROVED.equalsIgnoreCase(creditMemoOld.get(creditMemoHeader.Id).APTS_Approval_Status__c)
                                        && APTS_BIRUtils.APPROVED.equalsIgnoreCase(creditMemoHeader.APTS_Approval_Status__c)){
                    newOrder = new Apttus_Config2__Order__c();
                    newOrder.RecordTypeId = Schema.SObjectType.Apttus_Config2__Order__c.getRecordTypeInfosByName().get(APTS_BIRUtils.ADMINORDER).getRecordTypeId();
                    newOrder.Apttus_Config2__BillToAccountId__c = creditMemoHeader.Apttus_Billing__BillToAccountId__c;
                    Apttus_Config2__Order__c oOrder = NULL;
                    Apttus_Billing__InvoiceLineItem__c InvoiceToOrder = NULL;
                    newOrder.APTS_Credit_Memo__c = creditMemoHeader.Id;
                    if(creditMemoHeader.Apttus_Billing__CreditMemoDate__c != null){
                        newOrder.Apttus_Config2__PricingDate__c = creditMemoHeader.Apttus_Billing__CreditMemoDate__c;
                    }
                    if(!(String.isBlank(creditMemoHeader.Apttus_Billing__Description__c))){
                        newOrder.APTS_Invoice_Remark__c = creditMemoHeader.Apttus_Billing__Description__c;  
                    }
                    //v107
                    if(!String.isBlank(creditMemoHeader.APTS_PO_Number__c)){
                        newOrder.Apttus_Config2__PONumber__c = creditMemoHeader.APTS_PO_Number__c;
                    }
                    //v108
                    if(!String.isBlank(creditMemoHeader.APTS_Assignment__c)){
                        newOrder.APTS_Assignment__c = creditMemoHeader.APTS_Assignment__c;
                    }
                    newOrder.Apttus_Config2__LocationId__c = creditMemoHeader.Apttus_Billing__LocationId__c != null? 
                                                                creditMemoHeader.Apttus_Billing__LocationId__c : null;
                    newOrder.APTS_Order_Reason__c = creditMemoHeader.Apttus_Billing__ReasonCode__c;
                    newOrder.Apttus_Config2__Status__c = APTS_BIRUtils.ACTIVATED;
                    newOrder.APTS_Status__c = creditMemoHeader.Apttus_Billing__Status__c;
                    newOrder.APTS_SAP_OrderType__c = System.Label.APTS_SAP_ORDER_TYPE;
                    newOrder.APTS_Order_Type__c = System.Label.APTS_CREDIT_MEMO_ORDER_TYPE;
                    newOrder.APTS_Remove_Billing_Block_Indicator__c = true;
                    newOrder.Apttus_Config2__OrderStartDate__c = system.today();
                    newOrder.APTS_InvoiceType__c = SINGLEINVOICE;
                    newOrder.Apttus_Config2__ReadyForBillingDate__c = system.today();
                    newOrder.Apttus_Config2__ActivatedDate__c = system.today();
                    //newOrder.APTS_Billing_Date__c = system.today();
                    // Scenario 1: CMR attched to invoice not to Case Object (Automated)
                    if(creditMemoHeader.Apttus_Billing__InvoiceID__c != null
                        && !invoiceMap.isEmpty()
                        && invoiceMap.containskey(creditMemoHeader.Apttus_Billing__InvoiceID__c)
                        && invoiceMap.get(creditMemoHeader.Apttus_Billing__InvoiceID__c) != null){
                        Apttus_Billing__Invoice__c oInvoice = invoiceMap.get(creditMemoHeader.Apttus_Billing__InvoiceID__c);
                        InvoiceToOrder = mapInvoiceIdOrder.get(oInvoice.Id);
                        //Ship To Mapping
                        newOrder.Apttus_Config2__ShipToAccountId__c =  oInvoice.Apttus_Billing__ShipToAccountId__c != null? 
                                                                            oInvoice.Apttus_Billing__ShipToAccountId__c : null ;
                        
                        //External invoice number mapping
                        if(!String.isBlank(oInvoice.APTS_External_Invoice_Number__c)){
                            newOrder.APTS_External_Invoice_Number__c = oInvoice.APTS_External_Invoice_Number__c;
                        }
                        
                        
                        if(null != InvoiceToOrder &&  null != InvoiceToOrder.APTS_AdminOrder_Line__r){
                            newOrder.Derived_From_Order__c = InvoiceToOrder.APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.Derived_From_Order__c;
                            if(invoiceDeliveryPreferenceMap.containsKey(InvoiceToOrder.APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.APTS_InvoiceDeliveryPreference__c))
                                newOrder.APTS_InvoiceDeliveryPreference__c = invoiceDeliveryPreferenceMap.get(InvoiceToOrder.APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.APTS_InvoiceDeliveryPreference__c);
                            else 
                                newOrder.APTS_InvoiceDeliveryPreference__c = InvoiceToOrder.APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.APTS_InvoiceDeliveryPreference__c;
                            newOrder.APTS_Invoice_List_Indicator__c = 'No';
                            newOrder.RecordTypeId = Apttus_Config2__Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Admin Order').getRecordTypeId();
                            newOrder.Apttus_Config2__Status__c = 'Activated';
                            newOrder.APTS_Status__c = 'Activated';
                            newOrder.APTS_Order_Sub_Type__c = '';
                            newOrder.APTS_Order_Type__c = 'Credit Memo';
                            newOrder.APTS_Remove_Billing_Block_Indicator__c = true;
                            //newOrder.APTS_Collective_Billing_Indicator__c = InvoiceToOrder.APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.APTS_Collective_Billing_Indicator__c;
                            newOrder.Apttus_Config2__PrimaryContactId__c = InvoiceToOrder.APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__PrimaryContactId__c;
                            newOrder.APTS_Payment_Method__c = InvoiceToOrder.APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.APTS_Payment_Method__c;
                            if(newOrder.APTS_Payment_Method__c != null){
                                newOrder.APTS_Payment_Method_Code__c = InvoiceToOrder.APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.APTS_Payment_Method__r.APTS_Payment_Method_Code__c;
                            }
                            newOrder.Apttus_Config2__PaymentTermId__c = InvoiceToOrder.APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__PaymentTermId__c;
                            newOrder.Apttus_Config2__BillingPreferenceId__c = InvoiceToOrder.APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__BillingPreferenceId__c;
                            newOrder.Apttus_Config2__PriceListId__c = InvoiceToOrder.APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__PriceListId__c;
                            newOrder.Apttus_CMConfig__AgreementId__c = InvoiceToOrder.APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.Apttus_CMConfig__AgreementId__c;
                            newOrder.Apttus_Config2__SoldToAccountId__c = InvoiceToOrder.APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__SoldToAccountId__c;
                            newOrder.Apttus_Config2__BillToAccountId__c = InvoiceToOrder.APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__BillToAccountId__c;
                            newOrder.APTS_Bill_to_Party_Ingredients_and_Payer__c = InvoiceToOrder.APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.APTS_Bill_to_Party_Ingredients_and_Payer__c;
                            newOrder.APTS_Bill_to_Party_Machines_Services__c = InvoiceToOrder.APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.APTS_Bill_to_Party_Machines_Services__c;
                            newOrder.APTS_Payer__c = InvoiceToOrder.APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.APTS_Payer__c;//v105
                            newOrder.APTS_PayerIngredients__c = InvoiceToOrder.APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.APTS_PayerIngredients__c;
                            newOrder.APTS_PayerMachinesServices__c = InvoiceToOrder.APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.APTS_PayerMachinesServices__c;
                            newOrder.Apttus_Config2__LocationId__c = InvoiceToOrder.APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__LocationId__c;
                            newOrder.Apttus_Config2__OrderStartDate__c = Date.today();
                            newOrder.Apttus_Config2__PricingDate__c = InvoiceToOrder.APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__PricingDate__c;
                            newOrder.APTS_Fix_Term_Billing_Flag__c = InvoiceToOrder.APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.APTS_Fix_Term_Billing_Flag__c;
                            //v107-newOrder.Apttus_Config2__PONumber__c = InvoiceToOrder.APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__PONumber__c;
                            newOrder.Apttus_Config2__PODate__c = InvoiceToOrder.APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__PODate__c;
                            newOrder.APTS_SAP_OrderType__c = 'XC01';
                            newOrder.Apttus_Config2__Description__c = 'Created from Credit Memo ' + creditMemoHeader.Name;
                            newOrder.APTS_Order_Reason__c = creditMemoHeader.Apttus_Billing__ReasonCode__c;
                            newOrder.APTS_Invoice__c = InvoiceToOrder.Apttus_Billing__InvoiceId__c;
                            newOrder.APTS_Division__c =  InvoiceToOrder.APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__SoldToAccountId__r.Division__c;
                            newOrder.APTS_Distribution_Channel__c = InvoiceToOrder.APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__SoldToAccountId__r.Distribution_Channel__c;
                            newOrder.APTS_Sales_Organization__c = InvoiceToOrder.APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__SoldToAccountId__r.Sales_Organization__c;
                        }else{
                            if(null != InvoiceToOrder &&  null != InvoiceToOrder.APTS_Order_Line__r ){
                                
                                newOrder.Derived_From_Order__c = InvoiceToOrder.APTS_Order_Line__r.Apttus_Config2__OrderId__c;
                                if(invoiceDeliveryPreferenceMap.containsKey(InvoiceToOrder.APTS_Order_Line__r.Apttus_Config2__OrderId__r.APTS_InvoiceDeliveryPreference__c))
                                    newOrder.APTS_InvoiceDeliveryPreference__c = invoiceDeliveryPreferenceMap.get(InvoiceToOrder.APTS_Order_Line__r.Apttus_Config2__OrderId__r.APTS_InvoiceDeliveryPreference__c);
                                else 
                                    newOrder.APTS_InvoiceDeliveryPreference__c = InvoiceToOrder.APTS_Order_Line__r.Apttus_Config2__OrderId__r.APTS_InvoiceDeliveryPreference__c;
                                
                                newOrder.APTS_Invoice_List_Indicator__c = 'No';
                                newOrder.RecordTypeId = Apttus_Config2__Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Admin Order').getRecordTypeId();
                                newOrder.Apttus_Config2__Status__c = 'Activated';
                                newOrder.APTS_Status__c = 'Activated';
                                newOrder.APTS_Order_Sub_Type__c = '';
                                newOrder.APTS_Order_Type__c = 'Credit Memo';
                                newOrder.APTS_Remove_Billing_Block_Indicator__c = true;
                                //newOrder.APTS_Collective_Billing_Indicator__c = InvoiceToOrder.APTS_Order_Line__r.Apttus_Config2__OrderId__r.APTS_Collective_Billing_Indicator__c;
                                newOrder.Apttus_Config2__PrimaryContactId__c = InvoiceToOrder.APTS_Order_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__PrimaryContactId__c;
                                newOrder.APTS_Payment_Method__c = InvoiceToOrder.APTS_Order_Line__r.Apttus_Config2__OrderId__r.APTS_Payment_Method__c;
                                if(newOrder.APTS_Payment_Method__c != null){
                                    newOrder.APTS_Payment_Method_Code__c = InvoiceToOrder.APTS_Order_Line__r.Apttus_Config2__OrderId__r.APTS_Payment_Method__r.APTS_Payment_Method_Code__c;
                                }
                                newOrder.Apttus_Config2__PaymentTermId__c = InvoiceToOrder.APTS_Order_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__PaymentTermId__c;
                                newOrder.Apttus_Config2__BillingPreferenceId__c = InvoiceToOrder.APTS_Order_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__BillingPreferenceId__c;
                                newOrder.Apttus_Config2__PriceListId__c = InvoiceToOrder.APTS_Order_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__PriceListId__c;
                                newOrder.Apttus_CMConfig__AgreementId__c = InvoiceToOrder.APTS_Order_Line__r.Apttus_Config2__OrderId__r.Apttus_CMConfig__AgreementId__c;
                                newOrder.Apttus_Config2__SoldToAccountId__c = InvoiceToOrder.APTS_Order_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__SoldToAccountId__c;
                                newOrder.Apttus_Config2__BillToAccountId__c = InvoiceToOrder.APTS_Order_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__BillToAccountId__c;
                                newOrder.APTS_Bill_to_Party_Ingredients_and_Payer__c = InvoiceToOrder.APTS_Order_Line__r.Apttus_Config2__OrderId__r.APTS_Bill_to_Party_Ingredients_and_Payer__c;
                                newOrder.APTS_Bill_to_Party_Machines_Services__c = InvoiceToOrder.APTS_Order_Line__r.Apttus_Config2__OrderId__r.APTS_Bill_to_Party_Machines_Services__c;
                                newOrder.APTS_Payer__c = InvoiceToOrder.APTS_Order_Line__r.Apttus_Config2__OrderId__r.APTS_Payer__c;//v105
                                newOrder.APTS_PayerIngredients__c = InvoiceToOrder.APTS_Order_Line__r.Apttus_Config2__OrderId__r.APTS_PayerIngredients__c;
                                newOrder.APTS_PayerMachinesServices__c = InvoiceToOrder.APTS_Order_Line__r.Apttus_Config2__OrderId__r.APTS_PayerMachinesServices__c;
                                newOrder.Apttus_Config2__LocationId__c = InvoiceToOrder.APTS_Order_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__LocationId__c;
                                newOrder.Apttus_Config2__OrderStartDate__c = Date.today();
                                newOrder.Apttus_Config2__PricingDate__c = InvoiceToOrder.APTS_Order_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__PricingDate__c;
                                newOrder.APTS_Fix_Term_Billing_Flag__c = InvoiceToOrder.APTS_Order_Line__r.Apttus_Config2__OrderId__r.APTS_Fix_Term_Billing_Flag__c;
                                //v107-newOrder.Apttus_Config2__PONumber__c = InvoiceToOrder.APTS_Order_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__PONumber__c;
                                newOrder.Apttus_Config2__PODate__c = InvoiceToOrder.APTS_Order_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__PODate__c;
                                newOrder.APTS_SAP_OrderType__c = 'XC01';
                                newOrder.Apttus_Config2__Description__c = 'Created from Credit Memo ' + creditMemoHeader.Name;
                                newOrder.APTS_Order_Reason__c = creditMemoHeader.Apttus_Billing__ReasonCode__c;
                                newOrder.APTS_Invoice__c = InvoiceToOrder.Apttus_Billing__InvoiceId__c;
                                newOrder.APTS_Division__c =  InvoiceToOrder.APTS_Order_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__SoldToAccountId__r.Division__c;
                                newOrder.APTS_Distribution_Channel__c = InvoiceToOrder.APTS_Order_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__SoldToAccountId__r.Distribution_Channel__c;
                                newOrder.APTS_Sales_Organization__c = InvoiceToOrder.APTS_Order_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__SoldToAccountId__r.Sales_Organization__c;
                            }
                        }
                    }
                    else{  
                        newOrder.Derived_From_Order__c = NULL;
                        newOrder.APTS_Invoice_List_Indicator__c = 'No';
                        newOrder.RecordTypeId = Apttus_Config2__Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Admin Order').getRecordTypeId();
                        newOrder.Apttus_Config2__Status__c = 'Activated';
                        newOrder.APTS_Status__c = 'Activated';
                        newOrder.APTS_Order_Sub_Type__c = '';
                        newOrder.APTS_Order_Type__c = 'Credit Memo';
                        newOrder.APTS_Remove_Billing_Block_Indicator__c = true; 
                        
                        if(!accountMap.isEmpty()){
                            //Commented the below lines as part of defect #21150 
                            /*if(accountMap.containsKey(creditMemoHeader.APTS_Sold_To_Account__c)
                                && accountMap.get(creditMemoHeader.APTS_Sold_To_Account__c) != null){
                                newOrder.APTS_InvoiceDeliveryPreference__c = accountMap.get(creditMemoHeader.APTS_Sold_To_Account__c).Apttus_Config2__BillingPreferenceId__c != null ? accountMap.get(creditMemoHeader.APTS_Sold_To_Account__c).Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Delivery_Preference__c : APTS_BIRUtils.EMPTY_STRING;
                            }*/
                            
                            if(accountMap.containsKey(creditMemoHeader.Apttus_Billing__BillToAccountId__c)
                                && accountMap.get(creditMemoHeader.Apttus_Billing__BillToAccountId__c) != null){
                                //Modified as part of defect #21150 
                                if(creditAgrAccMap.get(creditMemoHeader.Id).APTS_Credit_Contract__c == null){
                                    newOrder.APTS_InvoiceDeliveryPreference__c = accountMap.get(creditMemoHeader.Apttus_Billing__BillToAccountId__c).Apttus_Config2__BillingPreferenceId__c != null ? accountMap.get(creditMemoHeader.Apttus_Billing__BillToAccountId__c).Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Delivery_Preference__c : APTS_BIRUtils.EMPTY_STRING;
                                }
                                newOrder.APTS_Payment_Method__c = accountMap.get(creditMemoHeader.Apttus_Billing__BillToAccountId__c).APTS_Payment_Method__c;
                                if(newOrder.APTS_Payment_Method__c != null){
                                    newOrder.APTS_Payment_Method_Code__c = accountMap.get(creditMemoHeader.Apttus_Billing__BillToAccountId__c).APTS_Payment_Method__r.APTS_Payment_Method_Code__c;
                                }
                                newOrder.Apttus_Config2__PaymentTermId__c = accountMap.get(creditMemoHeader.Apttus_Billing__BillToAccountId__c).Apttus_Config2__PaymentTermId__c;
                                newOrder.Apttus_Config2__BillingPreferenceId__c = accountMap.get(creditMemoHeader.Apttus_Billing__BillToAccountId__c).Apttus_Config2__BillingPreferenceId__c;
                                newOrder.APTS_Division__c =  accountMap.get(creditMemoHeader.Apttus_Billing__BillToAccountId__c).Division__c;
                                newOrder.APTS_Distribution_Channel__c = accountMap.get(creditMemoHeader.Apttus_Billing__BillToAccountId__c).Distribution_Channel__c;
                                newOrder.APTS_Sales_Organization__c = accountMap.get(creditMemoHeader.Apttus_Billing__BillToAccountId__c).Sales_Organization__c;
                            }
                        }
                        //Defect Fix : 22569- AS
                        if(null != creditMemoHeader.APTS_Credit_Contract__c){
                            newOrder.Apttus_CMConfig__AgreementId__c = creditMemoHeader.APTS_Credit_Contract__c;
                            newOrder.Apttus_Config2__PaymentTermId__c =contractBillingPrefMap.get(creditMemoHeader.APTS_Credit_Contract__c).APTS_Payment_Term_Setting__c;
                            newOrder.APTS_Payment_Method__c = contractBillingPrefMap.get(creditMemoHeader.APTS_Credit_Contract__c).APTS_Payment_Method__c;
                            newOrder.Apttus_Config2__BillingPreferenceId__c = contractBillingPrefMap.get(creditMemoHeader.APTS_Credit_Contract__c).APTS_Billing_Preference_Setting__c;
                            newOrder.APTS_Payment_Method_Code__c = contractBillingPrefMap.get(creditMemoHeader.APTS_Credit_Contract__c).APTS_Payment_Method__r.APTS_Payment_Method_Code__c;    
                            if(null != mapContarctPOnum.get(creditMemoHeader.APTS_Credit_Contract__c)){
                                newOrder.Apttus_Config2__PONumber__c = mapContarctPOnum.get(creditMemoHeader.APTS_Credit_Contract__c).APTS_PO_Number__c;
                                newOrder.Apttus_Config2__PODate__c = mapContarctPOnum.get(creditMemoHeader.APTS_Credit_Contract__c).APTS_PO_Expiration_Date__c;   
                            }
                        }

                        if(!creditAgrAccMap.isEmpty() && creditAgrAccMap.containsKey(creditMemoHeader.Id)){
                            if(creditAgrAccMap.get(creditMemoHeader.Id).APTS_Credit_Contract__c != null){
                                //newOrder.APTS_Payer__c = creditAgrAccMap.get(creditMemoHeader.Id).APTS_Credit_Contract__r.APTS_Payer_Ingredients__c;
                                //newOrder.APTS_PayerIngredients__c = creditAgrAccMap.get(creditMemoHeader.Id).APTS_Credit_Contract__r.APTS_Payer_Ingredients__c;
                                newOrder.APTS_Bill_to_Party_Ingredients_and_Payer__c = creditAgrAccMap.get(creditMemoHeader.Id).APTS_Credit_Contract__r.APTS_Bill_to_Party_Ingredients__c;
                                //v102
                                if(creditAgrAccMap.get(creditMemoHeader.Id).APTS_Credit_Contract__r.APTS_Check_on_Account_Ingredients__c){
                                    newOrder.APTS_Payer__c = (creditAgrAccMap.get(creditMemoHeader.Id).APTS_Sold_To_Account__r.Related_Payer_Account__c!=null ? creditAgrAccMap.get(creditMemoHeader.Id).APTS_Sold_To_Account__r.Related_Payer_Account__c : creditAgrAccMap.get(creditMemoHeader.Id).APTS_Sold_To_Account__c);
                                    newOrder.APTS_PayerIngredients__c = (creditAgrAccMap.get(creditMemoHeader.Id).APTS_Sold_To_Account__r.Related_Payer_Account__c!=null ? creditAgrAccMap.get(creditMemoHeader.Id).APTS_Sold_To_Account__r.Related_Payer_Account__c : creditAgrAccMap.get(creditMemoHeader.Id).APTS_Sold_To_Account__c);
                                    //v104 ++<<
                                    if(creditAgrAccMap.get(creditMemoHeader.Id).APTS_Sold_To_Account__r.Bill_To_Payer_Account__c!=null && creditAgrAccMap.get(creditMemoHeader.Id).APTS_Sold_To_Account__r.Bill_To_Payer_Account__r.Apttus_Config2__BillingPreferenceId__c!=null){
                                        newOrder.Apttus_Config2__BillingPreferenceId__c = creditAgrAccMap.get(creditMemoHeader.Id).APTS_Sold_To_Account__r.Bill_To_Payer_Account__r.Apttus_Config2__BillingPreferenceId__c;
                                    }
                                    newOrder.Apttus_Config2__PaymentTermId__c=creditAgrAccMap.get(creditMemoHeader.Id).APTS_Sold_To_Account__r.Bill_To_Payer_Account__r.Apttus_Config2__PaymentTermId__c;
                                    if(creditAgrAccMap.get(creditMemoHeader.Id).APTS_Sold_To_Account__r.Bill_To_Payer_Account__c!=null && creditAgrAccMap.get(creditMemoHeader.Id).APTS_Sold_To_Account__r.Bill_To_Payer_Account__r.APTS_Payment_Method__c!=null){
                                        newOrder.APTS_Payment_Method__c = creditAgrAccMap.get(creditMemoHeader.Id).APTS_Sold_To_Account__r.Bill_To_Payer_Account__r.APTS_Payment_Method__c;
                                        newOrder.APTS_Payment_Method_Code__c  = creditAgrAccMap.get(creditMemoHeader.Id).APTS_Sold_To_Account__r.Bill_To_Payer_Account__r.APTS_Payment_Method__r.APTS_Payment_Method_Code__c;
                                    }
                                    if(creditAgrAccMap.get(creditMemoHeader.Id).APTS_Sold_To_Account__r.Bill_To_Payer_Account__c==null){
                                        if(creditAgrAccMap.get(creditMemoHeader.Id).APTS_Sold_To_Account__r.Apttus_Config2__BillingPreferenceId__c!=null){
                                            newOrder.Apttus_Config2__BillingPreferenceId__c = creditAgrAccMap.get(creditMemoHeader.Id).APTS_Sold_To_Account__r.Apttus_Config2__BillingPreferenceId__c;
                                        }
                                        newOrder.Apttus_Config2__PaymentTermId__c=creditAgrAccMap.get(creditMemoHeader.Id).APTS_Sold_To_Account__r.Apttus_Config2__PaymentTermId__c;
                                        if(creditAgrAccMap.get(creditMemoHeader.Id).APTS_Sold_To_Account__r.APTS_Payment_Method__c!=null){
                                            newOrder.APTS_Payment_Method__c = creditAgrAccMap.get(creditMemoHeader.Id).APTS_Sold_To_Account__r.APTS_Payment_Method__c;
                                            newOrder.APTS_Payment_Method_Code__c  = creditAgrAccMap.get(creditMemoHeader.Id).APTS_Sold_To_Account__r.APTS_Payment_Method__r.APTS_Payment_Method_Code__c;
                                        }
                                    }
                                    //v104++>>
                                }
                                else {
                                    newOrder.APTS_Payer__c = (creditAgrAccMap.get(creditMemoHeader.Id).APTS_Credit_Contract__r.APTS_Payer_Ingredients__c!=null ? creditAgrAccMap.get(creditMemoHeader.Id).APTS_Credit_Contract__r.APTS_Payer_Ingredients__c : creditAgrAccMap.get(creditMemoHeader.Id).APTS_Sold_To_Account__c);
                                    newOrder.APTS_PayerIngredients__c = (creditAgrAccMap.get(creditMemoHeader.Id).APTS_Credit_Contract__r.APTS_Payer_Ingredients__c!=null ? creditAgrAccMap.get(creditMemoHeader.Id).APTS_Credit_Contract__r.APTS_Payer_Ingredients__c : creditAgrAccMap.get(creditMemoHeader.Id).APTS_Sold_To_Account__c);
                                }   
                                //v102
                                //Added as part of defect #21150 
                                if(null != contractBillingPrefMap.get(creditMemoHeader.APTS_Credit_Contract__c))
                                    newOrder.APTS_InvoiceDeliveryPreference__c = contractBillingPrefMap.get(creditMemoHeader.APTS_Credit_Contract__c).APTS_Invoice_Delivery_Preference__c;                                                                                                                                                                                                                                                                                                 
                            }
                            //v102
                            else if(creditAgrAccMap.get(creditMemoHeader.Id).APTS_Sold_To_Account__c != null){
                                newOrder.APTS_Payer__c = (creditAgrAccMap.get(creditMemoHeader.Id).APTS_Sold_To_Account__r.Related_Payer_Account__c!=null ? creditAgrAccMap.get(creditMemoHeader.Id).APTS_Sold_To_Account__r.Related_Payer_Account__c : creditAgrAccMap.get(creditMemoHeader.Id).APTS_Sold_To_Account__c);  
                                newOrder.APTS_PayerIngredients__c = (creditAgrAccMap.get(creditMemoHeader.Id).APTS_Sold_To_Account__r.Related_Payer_Account__c!=null ? creditAgrAccMap.get(creditMemoHeader.Id).APTS_Sold_To_Account__r.Related_Payer_Account__c : creditAgrAccMap.get(creditMemoHeader.Id).APTS_Sold_To_Account__c);
                            }
                            //v102
                            else if(creditAgrAccMap.get(creditMemoHeader.Id).Apttus_Billing__BillToAccountId__c != null){
                                //newOrder.APTS_Payer__c = creditAgrAccMap.get(creditMemoHeader.Id).Apttus_Billing__BillToAccountId__r.Related_Payer_Account__c;
                                newOrder.APTS_PayerIngredients__c = creditAgrAccMap.get(creditMemoHeader.Id).Apttus_Billing__BillToAccountId__r.Related_Payer_Account__c;
                                newOrder.APTS_Bill_to_Party_Ingredients_and_Payer__c = creditAgrAccMap.get(creditMemoHeader.Id).Apttus_Billing__BillToAccountId__r.Bill_To_Payer_Account__c;
                            }
                        }
                        newOrder.APTS_Collective_Billing_Indicator__c = false;
                        newOrder.Apttus_Config2__PrimaryContactId__c = mapAccIdContactId.get(creditMemoHeader.Apttus_Billing__BillToAccountId__c);
                        newOrder.Apttus_Config2__PriceListId__c = mapKeyPriceListId.get(accountMap.get(creditMemoHeader.Apttus_Billing__BillToAccountId__c).Sales_Organization__c);
                        
                        newOrder.Apttus_Config2__SoldToAccountId__c = creditMemoHeader.APTS_Sold_To_Account__c;
                       
                        newOrder.Apttus_Config2__BillToAccountId__c = creditMemoHeader.Apttus_Billing__BillToAccountId__c;
                        
                        newOrder.Apttus_Config2__LocationId__c = NULL;
                        newOrder.Apttus_Config2__OrderStartDate__c = Date.today();
                        newOrder.Apttus_Config2__PricingDate__c = Date.today();
                        newOrder.APTS_Fix_Term_Billing_Flag__c = NULL;
                        
                        newOrder.APTS_SAP_OrderType__c = 'XC01';
                        newOrder.Apttus_Config2__Description__c = 'Created from Credit Memo ' + creditMemoHeader.Name;
                        newOrder.APTS_Order_Reason__c = creditMemoHeader.Apttus_Billing__ReasonCode__c;
                        newOrder.APTS_Invoice__c = NULL;
                    }
                    if(InvoiceToOrder != NULL){
                        if(InvoiceToOrder.APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__c != NULL){
                            orderToInsertMap.put(InvoiceToOrder.APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__c , newOrder);
                        }else if(InvoiceToOrder.APTS_Order_Line__r.Apttus_Config2__OrderId__c != NULL){
                            orderToInsertMap.put(InvoiceToOrder.APTS_Order_Line__r.Apttus_Config2__OrderId__c , newOrder);
                        }
                    }else{
                            orderToInsertMap.put(creditMemoHeader.Case__c, newOrder);
                    }
                }  
            }
            //newOrder.APTS_Billing_Date__c = Date.today();
            system.debug('orderToInsertMap==>'+orderToInsertMap);
            //system.debug('orderToInsertMap==>'+orderToInsertMap.size());
            Id newOrderId;
            if(!orderToInsertMap.isEmpty()){
                Database.SaveResult[] insertedResultList = Database.Insert(orderToInsertMap.values(),false);
                for(Integer i=0;i<insertedResultList.size();i++){
                    if (insertedResultList.get(i).isSuccess()){
                        newOrderId=insertedResultList.get(i).getId();

                    }

                }
                APTS_BIRUtils.logError(null,insertedResultList,null,null,APTS_BIRUtils.TRIGGERVALUE,APTS_BIRUtils.ORDEROBJECTNAME,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,false); 
            }
            system.debug('orderToInsertMap.keySet()==>'+orderToInsertMap.keySet());
            system.debug('orderLineItemUsed==>'+orderLineItemUsed);
            //SOQL for fetching order line items (Automated Scenario)
            Map<Id, Apttus_Config2__OrderLineItem__c> mapOLIToInsert = new Map<Id, Apttus_Config2__OrderLineItem__c>();
            Set<Id> oliWithBPOSet=new Set<Id>();
            if(!orderToInsertMap.isEmpty() && newOrderId!=null 
                && !orderLineItemUsed.isEmpty()){
                Apttus_Config2__OrderLineItem__c newOLI = null;
                for(Apttus_Config2__OrderLineItem__c tmpOLI : [SELECT ID, Apttus_Config2__OrderId__c,
                                                                        Apttus_Config2__ClassificationId__c,
                                                                        Apttus_Config2__ClassificationHierarchy__c,
                                                                        APTS_BillingSchedule__c,
                                                                        APTS_Item_Relevant_for_SAP__c,
                                                                        Apttus_Config2__StartDate__c,
                                                                        Apttus_Config2__IsPrimaryLine__c,
                                                                        Apttus_Config2__LineType__c,
                                                                        Apttus_Config2__HasOptions__c,
                                                                        Apttus_Config2__ChargeType__c,
                                                                        APTS_Original_Order_Line_Item__c,
                                                                        Apttus_Config2__EndDate__c,
                                                                        APTS_Option_Group_Text__c,
                                                                        APTS_Cumulative_Call_Out_Coverage__c,
                                                                        APTS_Cumulative_Labour_coverage__c,
                                                                        APTS_Cumulative_Spare_Parts_Coverage__c,
                                                                        Apttus_Config2__DerivedFromId__c,
                                                                        Apttus_Config2__ConfigurationId__c,
                                                                        APTS_Type_of_Contract__c,
                                                                        Apttus_Config2__ProductId__c,
                                                                        Apttus_CMConfig__AgreementId__c,
                                                                        Apttus_Config2__Quantity__c,
                                                                        Apttus_Config2__SellingUom__c,
                                                                        Apttus_Config2__AssetLineItemId__c,
                                                                        APTS_Refurbished_or_New__c,
                                                                        APTS_Payment_Method__c,
                                                                        Apttus_Config2__PaymentTermId__c,
                                                                        Apttus_Config2__BillingPreferenceId__c,
                                                                        Apttus_Config2__BillingRule__c,
                                                                        Apttus_Config2__BillingFrequency__c,
                                                                        Apttus_Config2__BillToAccountId__c,
                                                                        Apttus_Config2__SellingFrequency__c,
                                                                        Apttus_Config2__OptionId__c,
                                                                        Apttus_Config2__PriceType__c,
                                                                        Apttus_Config2__ActivatedDate__c,
                                                                        Apttus_Config2__ReadyForBillingDate__c,
                                                                        APTS_Status__c,
                                                                        Apttus_Config2__Status__c,
                                                                        Apttus_Config2__LineNumber__c,
                                                                        Apttus_Config2__ItemSequence__c,
                                                                        APTS_SAP_OrderType__c,
                                                                        Apttus_Config2__PriceListId__c,
                                                                        Apttus_Config2__PriceListItemId__c,
                                                                        Apttus_Config2__ListPrice__c,
                                                                        Apttus_Config2__BasePrice__c,
                                                                        Apttus_Config2__BasePriceOverride__c,
                                                                        Apttus_Config2__AdjustedPrice__c,
                                                                        Apttus_Config2__NetPrice__c,
                                                                        Apttus_Config2__NetUnitPrice__c,
                                                                        APTS_Apttus_Order_Line_Item_Number__c,
                                                                        APTS_Salesforce_Unique_Item_Number__c,
                                                                        APTS_EAN_Code__c,
                                                                        Apttus_Config2__Description__c,
                                                                        APTS_Description__c,
                                                                        CurrencyIsoCode,
                                                                        APTS_Order_Line_SAP_ID__c,
                                                                        Apttus_Config2__OrderId__r.APTS_Invoice__c,
                                                                        Apttus_Config2__ProductId__r.Name
                                                                        FROM Apttus_Config2__OrderLineItem__c
                                                                        WHERE Id IN: orderLineItemUsed
                                                                        LIMIT 50000]){
                    newOLI = new Apttus_Config2__OrderLineItem__c();
                    //system.debug('orderLineItemUsed==>INSIDE AUTOMATED SCENARIO');
                    //newOLI.Apttus_Config2__OrderId__c = orderToInsertMap.get(tmpOLI.Apttus_Config2__OrderId__c).Id;
                    newOLI.Apttus_Config2__OrderId__c=newOrderId;
                    newOLI.Apttus_Config2__ClassificationId__c = tmpOLI.Apttus_Config2__ClassificationId__c;
                    newOLI.Apttus_Config2__ClassificationHierarchy__c = tmpOLI.Apttus_Config2__ClassificationHierarchy__c;
                    newOLI.APTS_BillingSchedule__c = NULL;
                    newOLI.APTS_Item_Relevant_for_SAP__c = true;
                    newOLI.Apttus_Config2__StartDate__c = Date.today();
                    newOLI.Apttus_Config2__IsPrimaryLine__c = tmpOLI.Apttus_Config2__IsPrimaryLine__c;
                    newOLI.Apttus_Config2__LineType__c = tmpOLI.Apttus_Config2__LineType__c;
                    newOLI.Apttus_Config2__HasOptions__c = tmpOLI.Apttus_Config2__HasOptions__c;
                    newOLI.Apttus_Config2__ChargeType__c = tmpOLI.Apttus_Config2__ChargeType__c;
                    newOLI.APTS_Original_Order_Line_Item__c = tmpOLI.APTS_Original_Order_Line_Item__c;
                    newOLI.Apttus_Config2__EndDate__c = Date.today();
                    newOLI.APTS_Option_Group_Text__c = tmpOLI.APTS_Option_Group_Text__c;
                    newOLI.APTS_Cumulative_Call_Out_Coverage__c = tmpOLI.APTS_Cumulative_Call_Out_Coverage__c;
                    newOLI.APTS_Cumulative_Labour_coverage__c = tmpOLI.APTS_Cumulative_Labour_coverage__c;
                    newOLI.APTS_Cumulative_Spare_Parts_Coverage__c = tmpOLI.APTS_Cumulative_Spare_Parts_Coverage__c;
                    newOLI.Apttus_Config2__DerivedFromId__c = tmpOLI.Apttus_Config2__DerivedFromId__c;
                    newOLI.Apttus_Config2__ConfigurationId__c = tmpOLI.Apttus_Config2__ConfigurationId__c;
                    newOLI.APTS_Type_of_Contract__c = tmpOLI.APTS_Type_of_Contract__c;
                    newOLI.Apttus_Config2__ProductId__c = tmpOLI.Apttus_Config2__ProductId__c;
                    newOLI.Apttus_CMConfig__AgreementId__c = tmpOLI.Apttus_CMConfig__AgreementId__c;
                    newOLI.Apttus_Config2__SellingUom__c = tmpOLI.Apttus_Config2__SellingUom__c;
                    newOLI.Apttus_Config2__AssetLineItemId__c = tmpOLI.Apttus_Config2__AssetLineItemId__c;
                    newOLI.APTS_Refurbished_or_New__c = tmpOLI.APTS_Refurbished_or_New__c;
                    newOLI.APTS_Payment_Method__c = tmpOLI.APTS_Payment_Method__c;
                    newOLI.Apttus_Config2__PaymentTermId__c = tmpOLI.Apttus_Config2__PaymentTermId__c;
                    newOLI.Apttus_Config2__BillingPreferenceId__c = tmpOLI.Apttus_Config2__BillingPreferenceId__c;
                    newOLI.Apttus_Config2__BillingRule__c = tmpOLI.Apttus_Config2__BillingRule__c;
                    newOLI.Apttus_Config2__BillingFrequency__c = tmpOLI.Apttus_Config2__BillingFrequency__c;
                    newOLI.Apttus_Config2__BillToAccountId__c = tmpOLI.Apttus_Config2__BillToAccountId__c;
                    newOLI.Apttus_Config2__SellingFrequency__c = tmpOLI.Apttus_Config2__SellingFrequency__c;
                    newOLI.Apttus_Config2__OptionId__c = tmpOLI.Apttus_Config2__OptionId__c;
                    newOLI.Apttus_Config2__PriceType__c = tmpOLI.Apttus_Config2__PriceType__c;
                    newOLI.Apttus_Config2__ActivatedDate__c = Date.today();
                    newOLI.Apttus_Config2__ReadyForBillingDate__c = Date.today();
                    newOLI.APTS_Status__c = 'Activated';
                    newOLI.Apttus_Config2__Status__c = 'Activated';
                    newOLI.Apttus_Config2__LineNumber__c = tmpOLI.Apttus_Config2__LineNumber__c;
                    newOLI.Apttus_Config2__ItemSequence__c = tmpOLI.Apttus_Config2__ItemSequence__c;
                    newOLI.APTS_SAP_OrderType__c = 'XC01';
                    newOLI.Apttus_Config2__PriceListId__c = tmpOLI.Apttus_Config2__PriceListId__c;
                    newOLI.Apttus_Config2__PriceListItemId__c = tmpOLI.Apttus_Config2__PriceListItemId__c;
                    newOLI.Apttus_Config2__ListPrice__c = NULL;
                    //system.debug('mapOLIIdCreditMemoLine Credit Automated Scenario==>'+mapOLIIdCreditMemoLine.get(tmpOLI.Id).Apttus_Billing__Amount__c);
                    if(!mapOLIIdCreditMemoLine.isEmpty()
                        && mapOLIIdCreditMemoLine.containsKey(tmpOLI.Id)
                        && mapOLIIdCreditMemoLine.get(tmpOLI.Id) != null){

                        if(mapOLIIdCreditMemoLine.get(tmpOLI.Id).APTS_BPO__c == true){
                            newOLI.Apttus_Config2__NetPrice__c = mapOLIIdCreditMemoLine.get(tmpOLI.Id).Apttus_Billing__Amount__c;
                            oliWithBPOSet.add(tmpOLI.Id); // Added as part of defect #21707
                        }
                        else{
                            newOLI.Apttus_Config2__NetPrice__c = tmpOLI.Apttus_Config2__NetPrice__c;
                        }
                        //<<++ V103 Added for defect # 6023 - Credit memo- Wrong listprice Starts 
                        newOLI.Apttus_Config2__BasePriceOverride__c = mapOLIIdCreditMemoLine.get(tmpOLI.Id).Apttus_Billing__Amount__c;
                        newOLI.Apttus_Config2__Quantity__c = mapOLIIdCreditMemoLine.get(tmpOLI.Id).APTS_Quantity__c;
                        if(newOLI.Apttus_Config2__Quantity__c>0)
                            newOLI.Apttus_Config2__BasePriceOverride__c = mapOLIIdCreditMemoLine.get(tmpOLI.Id).Apttus_Billing__Amount__c/newOLI.Apttus_Config2__Quantity__c;
                    }
                    newOLI.Apttus_Config2__AdjustedPrice__c = tmpOLI.Apttus_Config2__AdjustedPrice__c;
                    newOLI.APTS_EAN_Code__c = tmpOLI.APTS_EAN_Code__c;
                    newOLI.CurrencyIsoCode = tmpOLI.CurrencyIsoCode;
                    mapOLIToInsert.put(tmpOLI.Id, newOLI);
                }
            }
            //Creation of OLI for Manual Scenario
            Apttus_Config2__OrderLineItem__c newOLI = null;
            for(Apttus_Billing__CreditMemoLineItem__c tmpCreditLine : mapOLIIdCreditMemoLine.values()){
                Apttus_Billing__CreditMemo__c creditMemo = creditMemoNew.get(tmpCreditLine.Apttus_Billing__CreditMemoId__c);
                
                if(creditMemo.Apttus_Billing__InvoiceID__c == null
                    && !APTS_BIRUtils.APPROVED.equalsIgnoreCase(creditMemoOld.get(creditMemo.Id).APTS_Approval_Status__c)
                                        && APTS_BIRUtils.APPROVED.equalsIgnoreCase(creditMemo.APTS_Approval_Status__c)){
                    String key = '';
                    if(accountMap.containsKey(creditMemo.Apttus_Billing__BillToAccountId__c)
                        && accountMap.get(creditMemo.Apttus_Billing__BillToAccountId__c) != null){
                        if(accountMap.get(creditMemo.Apttus_Billing__BillToAccountId__c).Sales_Organization__c != null && tmpCreditLine.APTS_Product__c != null){
                            key = (String) accountMap.get(creditMemo.Apttus_Billing__BillToAccountId__c).Sales_Organization__c + (String) tmpCreditLine.APTS_Product__c;
                        }
                    }
                    newOLI = new Apttus_Config2__OrderLineItem__c();
                    newOLI.Apttus_Config2__OrderId__c = orderToInsertMap.get(creditMemo.Case__c).Id;
                    newOLI.Apttus_Config2__LineType__c = MISC;
                    newOLI.Apttus_Config2__ClassificationId__c = NULL;
                    newOLI.Apttus_Config2__ClassificationHierarchy__c = NULL;
                    newOLI.APTS_BillingSchedule__c = NULL;
                    newOLI.APTS_Item_Relevant_for_SAP__c = true;
                    newOLI.Apttus_Config2__StartDate__c = Date.today();
                    newOLI.Apttus_Config2__IsPrimaryLine__c = false;
                    //newOLI.Apttus_Config2__LineType__c = NULL;
                    newOLI.Apttus_Config2__HasOptions__c = false;
                    newOLI.Apttus_Config2__ChargeType__c = 'Sales Price';
                    newOLI.APTS_Original_Order_Line_Item__c = NULL;
                    newOLI.Apttus_Config2__EndDate__c = Date.today();
                    newOLI.APTS_Option_Group_Text__c = NULL;
                    newOLI.APTS_Cumulative_Call_Out_Coverage__c = NULL;
                    newOLI.APTS_Cumulative_Labour_coverage__c = NULL;
                    newOLI.APTS_Cumulative_Spare_Parts_Coverage__c = NULL;
                    newOLI.Apttus_Config2__DerivedFromId__c = NULL;
                    newOLI.Apttus_Config2__ConfigurationId__c = NULL;
                    newOLI.APTS_Type_of_Contract__c = NULL;
                    newOLI.Apttus_Config2__ProductId__c = tmpCreditLine.APTS_Product__c;
                    newOLI.Apttus_CMConfig__AgreementId__c = NULL;
                    newOLI.Apttus_Config2__Quantity__c = 1;
                    newOLI.Apttus_Config2__SellingUom__c = NULL;
                    newOLI.Apttus_Config2__AssetLineItemId__c = NULL;
                    newOLI.APTS_Refurbished_or_New__c = NULL;
                    newOLI.Apttus_Config2__BillToAccountId__c = creditMemo.Apttus_Billing__BillToAccountId__c;
                    newOLI.Apttus_Config2__SellingFrequency__c = NULL;
                    newOLI.Apttus_Config2__OptionId__c = NULL;
                    newOLI.Apttus_Config2__ActivatedDate__c = Date.today();
                    newOLI.Apttus_Config2__ReadyForBillingDate__c = Date.today();
                    newOLI.APTS_Status__c = 'Activated';
                    newOLI.Apttus_Config2__Status__c = 'Activated';
                    newOLI.Apttus_Config2__LineNumber__c = 1;
                    newOLI.Apttus_Config2__ItemSequence__c = 1;
                    newOLI.APTS_SAP_OrderType__c = 'XC01';
                    newOLI.Apttus_Config2__ListPrice__c = NULL;
                    newOLI.Apttus_Config2__BasePrice__c = NULL;
                    newOLI.APTS_Type_of_Contract__c = SALES;
                    //system.debug('mapOLIIdCreditMemoLine Credit Amount Manual Scenario==>'+mapOLIIdCreditMemoLine.get(tmpCreditLine.Id).Apttus_Billing__Amount__c);
                    if(!mapOLIIdCreditMemoLine.isEmpty()
                        && mapOLIIdCreditMemoLine.containsKey(tmpCreditLine.Id)
                        && mapOLIIdCreditMemoLine.get(tmpCreditLine.Id) != null){
                        newOLI.Apttus_Config2__NetPrice__c = mapOLIIdCreditMemoLine.get(tmpCreditLine.Id).Apttus_Billing__Amount__c;
                        newOLI.Apttus_Config2__BasePriceOverride__c = mapOLIIdCreditMemoLine.get(tmpCreditLine.Id).Apttus_Billing__Amount__c;
                    }
                    newOLI.Apttus_Config2__Description__c = tmpCreditLine.APTS_Product__r.Name;
                    newOLI.CurrencyIsoCode = creditMemo.CurrencyIsoCode;
                    if(key != null
                        && mapKeyPLI.containsKey(key)
                        && mapKeyPLI.get(key) != null){
                        newOLI.Apttus_Config2__PriceListId__c = mapKeyPLI.get(key).Apttus_Config2__PriceListId__c;
                        newOLI.Apttus_Config2__PriceListItemId__c = mapKeyPLI.get(key).Id;
                        newOLI.Apttus_Config2__BillingRule__c = mapKeyPLI.get(key).Apttus_Config2__BillingRule__c;
                        newOLI.Apttus_Config2__BillingFrequency__c =  mapKeyPLI.get(key).Apttus_Config2__BillingFrequency__c;
                        newOLI.Apttus_Config2__PriceType__c = mapKeyPLI.get(key).Apttus_Config2__PriceType__c;
                    }
                    if(accountMap.containsKey(creditMemo.Apttus_Billing__BillToAccountId__c) 
                        && accountMap.get(creditMemo.Apttus_Billing__BillToAccountId__c) != null){
                        newOLI.APTS_Payment_Method__c = accountMap.get(creditMemo.Apttus_Billing__BillToAccountId__c).APTS_Payment_Method__c;
                        newOLI.Apttus_Config2__PaymentTermId__c = accountMap.get(creditMemo.Apttus_Billing__BillToAccountId__c).Apttus_Config2__PaymentTermId__c;
                        newOLI.Apttus_Config2__BillingPreferenceId__c = accountMap.get(creditMemo.Apttus_Billing__BillToAccountId__c).Apttus_Config2__BillingPreferenceId__c;
                    }
                    //Defect Fix : 22569- AS
                    if(null !=contractBillingPrefMap.get(creditMemo.APTS_Credit_Contract__c)){
                        newOLI.Apttus_Config2__BillingPreferenceId__c =contractBillingPrefMap.get(creditMemo.APTS_Credit_Contract__c).APTS_Billing_Preference_Setting__c;
                        newOLI.Apttus_Config2__PaymentTermId__c =contractBillingPrefMap.get(creditMemo.APTS_Credit_Contract__c).APTS_Payment_Term_Setting__c;
                        newOLI.APTS_Payment_Method__c =contractBillingPrefMap.get(creditMemo.APTS_Credit_Contract__c).APTS_Payment_Method__c;
                    }
                    //v104++<<
                    if(creditAgrAccMap.get(creditMemo.Id).APTS_Credit_Contract__r.APTS_Check_on_Account_Ingredients__c){
                        newOLI.Apttus_Config2__BillingPreferenceId__c = orderToInsertMap.get(creditMemo.Case__c).Apttus_Config2__BillingPreferenceId__c;
                        newOLI.Apttus_Config2__PaymentTermId__c = orderToInsertMap.get(creditMemo.Case__c).Apttus_Config2__PaymentTermId__c;
                        newOLI.APTS_Payment_Method__c = orderToInsertMap.get(creditMemo.Case__c).APTS_Payment_Method__c;
                    }
                    //v104++>>
                    mapOLIToInsert.put(tmpCreditLine.Id, newOLI);
                }
            }
            system.debug('mapOLIToInsert ==>'+mapOLIToInsert);
            system.debug('mapOLIToInsert ==>'+mapOLIToInsert.size());
            DescribeSObjectResult objResultLSP = APTS_OTCUtil.getsObjectAccess(ORDERLINEITEM);
            if(!mapOLIToInsert.values().isEmpty()){
                if(objResultLSP!=null && (objResultLSP.isCreateable())){
                
                    Database.SaveResult[] insertedList = Database.insert(mapOLIToInsert.values(),false); 
                    APTS_BIRUtils.logError(null,insertedList,null,null,APTS_BIRUtils.TRIGGERVALUE,APTS_BIRUtils.ORDERLINEITEMOBJECTNAME,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,false);
                }
            }
        
            //SOQL for fetching Order Adjustment Line Item (Automated Scenario)
            List<Apttus_Config2__OrderAdjustmentLineItem__c> lstOALIInsert = new List<Apttus_Config2__OrderAdjustmentLineItem__c>();
            if(!mapOLIToInsert.isEmpty()){
                for(Apttus_Config2__OrderAdjustmentLineItem__c tmpOALI : [SELECT ID,
                                                                            APTS_Agreement_Number__c,
                                                                            APTS_Incentive_Adjustment_Amount__c,
                                                                            APTS_Incentive_Amount_Per_Billing_Period__c,
                                                                            APTS_Return_Adjustment_Price__c,
                                                                            Apttus_Config2__AdjustmentAmount__c,
                                                                            Apttus_Config2__AdjustmentAppliesTo__c,
                                                                            Apttus_Config2__AdjustmentType__c,
                                                                            Apttus_Config2__AdjustmentUom__c,
                                                                            Apttus_Config2__BenefitQuantity__c,
                                                                            Apttus_Config2__Bucket__c,
                                                                            Apttus_Config2__CouponCode__c,
                                                                            Apttus_Config2__IncentiveAdjustmentAmount__c,
                                                                            Apttus_Config2__IncentiveCode__c,
                                                                            Apttus_Config2__IncentiveId__c,
                                                                            Apttus_Config2__IsModifiable__c,
                                                                            Apttus_Config2__LineItemId__c,
                                                                            Apttus_Config2__LineNumber__c,
                                                                            Apttus_Config2__LineType__c,
                                                                            Apttus_Config2__PriceRuleEntryId__c,
                                                                            Apttus_Config2__PriceRuleId__c,
                                                                            Apttus_Config2__RunningTotalAdjustedPrice__c,
                                                                            Apttus_Config2__SubType__c,
                                                                            Apttus_Config2__Type__c,
                                                                            CurrencyIsoCode
                                                                            FROM Apttus_Config2__OrderAdjustmentLineItem__c
                                                                            WHERE Apttus_Config2__LineItemId__c IN :mapOLIToInsert.keySet()
                                                                            LIMIT 50000]){
                    // Added as part of defect #21707
                    if(!oliWithBPOSet.contains(tmpOALI.Apttus_Config2__LineItemId__c)){
                        Apttus_Config2__OrderAdjustmentLineItem__c newOALI = tmpOALI;
                        newOALI.Apttus_Config2__LineItemId__c = mapOLIToInsert.get(tmpOALI.Apttus_Config2__LineItemId__c).Id;
                        newOALI.Id = NULL;
                        lstOALIInsert.add(newOALI);
                    }
                }
            }
            system.debug('lstOALIInsert==>'+lstOALIInsert.size());
            system.debug('lstOALIInsert==>'+lstOALIInsert);
            DescribeSObjectResult objResultLSP2 = APTS_OTCUtil.getsObjectAccess(ADJUSTLINEITESOBJ);    
            if(lstOALIInsert != NULL && lstOALIInsert.size() > 0){
                if(objResultLSP2!=null && objResultLSP2.isCreateable()){
                    insert lstOALIInsert;
                }
            }

            // Integreation Log Insert
            if(!orderToInsertMap.isEmpty()){
                for(Apttus_Config2__Order__c order : orderToInsertMap.values()){
                    if(order.Id != null){
                        integrationLogListToInsert.add(APTS_OrderUtils.createIntegrationLog(order));
                    }
                }
                DescribeSObjectResult objResultLSP1 = APTS_OTCUtil.getsObjectAccess(INTEGRATIONSOBJ);
                if(!integrationLogListToInsert.isEmpty()){
                    if(objResultLSP1!=null && objResultLSP1.isCreateable()){
                        Database.Insert(integrationLogListToInsert, false);
                    }
                }
            }

        }catch(Exception e){
            system.debug('Exception occured after Insert Method****'+e);
            system.debug('Exception occured after Insert Method****'+e.getLineNumber());
            APTS_BIRUtils.logError(null,null,null,e,APTS_BIRUtils.TRIGGERVALUE,APTS_BIRUtils.ORDEROBJECTNAME,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,false);
        }
    }
 
     /*** Method Name  : afterDelete
        * Description : after Delete of credit memo record
        **/ 
    public void afterDelete(List<SObject> oldList, Map<Id, SObject> oldItems){try{}catch(Exception e){}}
     
     /*** Method Name  : afterUndelete
        * Description : after Undelete of credit memo record
        **/
    public void afterUndelete(List<SObject> newList, Map<Id, SObject> newItems){try{}catch(Exception e){}}
     
}