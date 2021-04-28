/*************************************************************
@Name: APTS_RetrieveInvoiceLineItemController
@Author: Balashanthi A
@CreateDate: 18-06-2018
@Description: Used to fetch the Invoice LIs from SAP and create Credit Memo, Credit Memo LIs
@UsedBy: APTS_RetrieveInvoiceLineItemFromSAP.page
******************************************************************/
//v101 05-07-2018 Ankit Joshi : Modified the methods getInvoiceLineItemsFromSAP(),retrieveInvoiceLineItemFromSAP(),createCreditMemo() etc
//v102 29-01-2020 Renuka: DQ-525- Incorrect Net price and missing functions
//v103 20-03-2020 Renuka: DQ-472 Create Debit Memo from Invoice
//v104 01-12-2020 Renuka: DQ-3116 DebitMemo from Invoice flow- removed Clone and copied only required fields.
//v105 05-02-2021 Manisha: DQ-5130 Cascading PO Number on Credit Memo and to Credit memo order
public with sharing class APTS_RetrieveInvoiceLineItemController{
    
    public Id currentRecordId;
    public Apttus_Billing__Invoice__c invoice{get;set;}
    public InvoiceWrapper oInvoiceRecord {get;set;}
    public List<InvoiceLineItemWrapper> invoiceLineItemWrapperList {get; set;}
    public List<Apttus_Billing__InvoiceLineItem__c> listInvoiceLineitems {get;set;}
    public Apttus_Billing__InvoiceLineItem__c oSelectedLineItem {get; set;}
    public Boolean hideSpinner{get;set;}
    public String  warningMessage {get; set;}
    public Boolean showDiv {get; set;}
    private static final String ORDERLINEITEM = 'Apttus_Config2__OrderLineItem__c';
    private static final String ADJUSTLINEITESOBJ ='Apttus_Config2__OrderAdjustmentLineItem__c';
    private static final String ORDER= 'Apttus_Config2__Order__c';
    private static final String EXCEPTION_OCCURED = 'Exception occurred :';
    private static final String CREDIT_AMT_VALIDATION = System.Label.APTS_Credit_Amount_Validation;
    private static final String INVOICELI_VALIDATION = System.Label.APTS_Select_One_InvoiceLI;
    private static final String ID = 'Id';
    private static final String BLANK_STRING = '';
    private static final String SLASH = '/';
    private static final String REASONCODEAPI = 'Apttus_Billing__ReasonCode__c';
    public static final String VISUALFORCE = 'Visualforce';
    private static final String APEX = 'Apex';
    private static final String INVOICETEXT = 'Invoice';
    private static final String BIR = 'BIR';
    private static final String LINETYPE = 'Product/Service';
    set<String> setInvPrf = new Set<String>{'P001','P002','P003','P004'};
    
    /** Controller Constructor 
    * Description : will be invoked on Page load
    **/
    public APTS_RetrieveInvoiceLineItemController(ApexPages.StandardController controller){
        currentRecordId = ApexPages.currentPage().getParameters().get(ID);
        warningMessage = 'You have used a base price override for one of the line items, please note that for these line items original adjustments are not being taken into account';  
        showDiv = false;
    }

    /** Method Name : getInvoiceLineItemsFromSAP()  
    * Description : Used to fetch the Invoice details
    **/
    public PageReference getInvoiceLineItemsFromSAP(){
    
        try{
            // Fetching Current Invoice Header Details
            if(currentRecordId != null){
                invoice = [SELECT Id,
                                name, 
                                Apttus_Billing__BillToAccountId__c, 
                                Apttus_Billing__LocationId__c,
                                Apttus_Billing__SoldToAccountId__c, 
                                Apttus_Billing__Status__c,
                                Apttus_Billing__TotalInvoiceAmount__c,
                                APTS_Total_Credit_Amount__c,
                                APTS_External_Invoice_Number__c,
                                APTTUS_BILLING__SHIPTOACCOUNTID__C
                            FROM Apttus_Billing__Invoice__c where Id =: currentRecordId 
                            LIMIT 50000];
                //v105
                listInvoiceLineitems = getInvoiceLineItemDetails(currentRecordId);
                String strPONumber;
                if(listInvoiceLineitems[0].APTS_AdminOrder_Line__c!=null){
                 strPONumber = listInvoiceLineitems[0].APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__PONumber__c;
                 system.debug('PO NUmberrr :' +strPONumber);
                }
                else if(listInvoiceLineitems[0].APTS_Order_Line__c!=null){
                strPONumber = listInvoiceLineitems[0].APTS_Order_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__PONumber__c;
                system.debug('PO NUmberrr :' +strPONumber);
                }
                oInvoiceRecord = new InvoiceWrapper(invoice,BLANK_STRING,BLANK_STRING, strPONumber,BLANK_STRING);
                invoiceLineItemWrapperList = retrieveInvoiceLineItemFromSAP(invoice,listInvoiceLineitems);
                hideSpinner = true; 
            }
            
        }catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, EXCEPTION_OCCURED+e.getMessage()));
            APTS_CustomLogging.createErrorLog(e.getTypeName(), APEX, e.getStackTraceString() ,INVOICETEXT, currentRecordId ,BIR,false,true, null , true);
            return null;}
        
        return null;
    }
    //v105
      Public List<Apttus_Billing__InvoiceLineItem__c> getInvoiceLineItemDetails(Id invoiceId) {
          List<Apttus_Billing__InvoiceLineItem__c> lstInvoiceLineitems = [SELECT Id,
                                                                                Name,
                                                                                Apttus_Billing__InvoiceId__c,
                                                                                APTS_Product__c,
                                                                                Apttus_Billing__InvoiceId__r.APTS_External_Invoice_Number__c,
                                                                                Apttus_Billing__Amount__c,
                                                                                Apttus_Billing__AssetLineItemId__c,
                                                                                Apttus_Billing__BillToAccountId__c,
                                                                                APTS_External_Invoice_Line_Number__c,
                                                                                Apttus_Billing__Quantity__c,
                                                                                APTS_Order_Line__c,
                                                                                APTS_Order_Line__r.Apttus_Config2__Quantity__c,
                                                                                APTS_Order_Line__r.Apttus_Config2__NetUnitPrice__c,
                                                                                APTS_Order_Line__r.Apttus_Config2__NetPrice__c,
                                                                                APTS_Order_Line__r.Apttus_Config2__BasePriceOverride__c,
                                                                                APTS_Order_Line__r.Apttus_Config2__BasePrice__c,
                                                                                APTS_Order_Line__r.Apttus_Config2__OrderId__c,
                                                                                APTS_Order_Line__r.Apttus_Config2__OrderId__r.Derived_From_Order__c,
                                                                                APTS_Order_Line__r.Apttus_Config2__OrderId__r.APTS_InvoiceDeliveryPreference__c,
                                                                                APTS_Order_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__PONumber__c,
                                                                                APTS_AdminOrder_Line__c,
                                                                                APTS_AdminOrder_Line__r.Apttus_Config2__LineType__c,
                                                                                APTS_AdminOrder_Line__r.Apttus_Config2__Quantity__c,
                                                                                APTS_AdminOrder_Line__r.Apttus_Config2__NetUnitPrice__c,
                                                                                APTS_AdminOrder_Line__r.Apttus_Config2__NetPrice__c,
                                                                                APTS_AdminOrder_Line__r.Apttus_Config2__BasePriceOverride__c,
                                                                                APTS_AdminOrder_Line__r.Apttus_Config2__BasePrice__c,
                                                                                APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__c,
                                                                                APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.Derived_From_Order__c,
                                                                                APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.APTS_InvoiceDeliveryPreference__c,
                                                                                APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.Apttus_Config2__PONumber__c,
                                                                                APTS_AdminOrder_Line__r.APTS_Original_Order_Line_Item__r.Apttus_Config2__DerivedFromId__c

                                                                            FROM Apttus_Billing__InvoiceLineItem__c WHERE Apttus_Billing__InvoiceId__c =: invoiceId limit 50000];
      return lstInvoiceLineitems;
      }
    /** Method Name : retrieveInvoiceLineItemFromSAP()
    * Description : Will Invoke SAP call and fetch Invoice Line item
    **/
    public List<InvoiceLineItemWrapper> retrieveInvoiceLineItemFromSAP(Apttus_Billing__Invoice__c invoice,List<Apttus_Billing__InvoiceLineItem__c> lstInvoiceLineitems){

        try{
            List<InvoiceLineItemWrapper> invoiceLineItemWrapperList1 = new List<InvoiceLineItemWrapper>();
            List<Apttus_Billing__InvoiceLineItem__c> recList = new List<Apttus_Billing__InvoiceLineItem__c>();
            InvoiceLineItemWrapper lineItemWrapper;
            integer counter =0;
            Decimal availableCreditAmount=0;
            
            for(Apttus_Billing__InvoiceLineItem__c  invoiceLineItem  : listInvoiceLineitems ){
                availableCreditAmount=0;

                if(null == invoiceLineItem.Apttus_Billing__Quantity__c){
                    invoiceLineItem.Apttus_Billing__Quantity__c =1;
                }
                if(null == invoiceLineItem.Apttus_Billing__Amount__c){
                    invoiceLineItem.Apttus_Billing__Amount__c = 0;
                }
                //<<++v102Starts
                if(invoiceLineItem.APTS_AdminOrder_Line__c != null){
                    if(invoiceLineItem.APTS_AdminOrder_Line__r.Apttus_Config2__NetPrice__c != null 
                        && invoiceLineItem.APTS_AdminOrder_Line__r.Apttus_Config2__Quantity__c!=null 
                        && invoiceLineItem.APTS_AdminOrder_Line__r.Apttus_Config2__NetPrice__c>0){
                        //if(invoiceLineItem.APTS_AdminOrder_Line__r.Apttus_Config2__NetPrice__c>0){
                            availableCreditAmount = (invoiceLineItem.APTS_AdminOrder_Line__r.Apttus_Config2__NetPrice__c/invoiceLineItem.APTS_AdminOrder_Line__r.Apttus_Config2__Quantity__c)*invoiceLineItem.Apttus_Billing__Quantity__c;
                        //}else if(invoiceLineItem.APTS_AdminOrder_Line__r.Apttus_Config2__NetPrice__c==0){
                        //    availableCreditAmount = 0.0;
                        //}
                    }else if(invoiceLineItem.APTS_AdminOrder_Line__r.Apttus_Config2__BasePriceOverride__c != null && invoiceLineItem.APTS_AdminOrder_Line__r.Apttus_Config2__BasePriceOverride__c>0){
                        availableCreditAmount = invoiceLineItem.APTS_AdminOrder_Line__r.Apttus_Config2__BasePriceOverride__c*invoiceLineItem.Apttus_Billing__Quantity__c;
                    }else if(invoiceLineItem.APTS_AdminOrder_Line__r.Apttus_Config2__BasePrice__c != null && invoiceLineItem.APTS_AdminOrder_Line__r.Apttus_Config2__BasePrice__c>0){
                        availableCreditAmount = invoiceLineItem.APTS_AdminOrder_Line__r.Apttus_Config2__BasePrice__c*invoiceLineItem.Apttus_Billing__Quantity__c;
                    }
                }else if(invoiceLineItem.APTS_Order_Line__c != null){
                    if(invoiceLineItem.APTS_Order_Line__r.Apttus_Config2__NetPrice__c != null && invoiceLineItem.APTS_Order_Line__r.Apttus_Config2__Quantity__c!=null){
                        if(invoiceLineItem.APTS_Order_Line__r.Apttus_Config2__NetPrice__c>0){
                            availableCreditAmount = (invoiceLineItem.APTS_Order_Line__r.Apttus_Config2__NetPrice__c/invoiceLineItem.APTS_Order_Line__r.Apttus_Config2__Quantity__c)*invoiceLineItem.Apttus_Billing__Quantity__c;
                        }else if(invoiceLineItem.APTS_Order_Line__r.Apttus_Config2__NetPrice__c == 0){
                            availableCreditAmount = 0.0;
                        }
                    }else if(invoiceLineItem.APTS_Order_Line__r.Apttus_Config2__BasePriceOverride__c != null && invoiceLineItem.APTS_Order_Line__r.Apttus_Config2__BasePriceOverride__c>0){
                        availableCreditAmount = invoiceLineItem.APTS_Order_Line__r.Apttus_Config2__BasePriceOverride__c*invoiceLineItem.Apttus_Billing__Quantity__c;
                    }else if(invoiceLineItem.APTS_Order_Line__r.Apttus_Config2__BasePrice__c != null && invoiceLineItem.APTS_Order_Line__r.Apttus_Config2__BasePrice__c>0){
                        availableCreditAmount = invoiceLineItem.APTS_Order_Line__r.Apttus_Config2__BasePrice__c*invoiceLineItem.Apttus_Billing__Quantity__c;
                    }
                }else{
                    availableCreditAmount=0.0;
                }//>>++v102 Ends
                lineItemWrapper = new InvoiceLineItemWrapper(false,invoiceLineItem,(availableCreditAmount/invoiceLineItem.Apttus_Billing__Quantity__c).setScale(2),1,counter++,
                                                            availableCreditAmount/invoiceLineItem.Apttus_Billing__Quantity__c,false,
                                                            availableCreditAmount.setScale(2),0.0,0.0);
                invoiceLineItemWrapperList1.add(lineItemWrapper);
            }
            
            return invoiceLineItemWrapperList1;
        }catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, EXCEPTION_OCCURED+e.getMessage()));
            APTS_CustomLogging.createErrorLog(e.getTypeName(), VISUALFORCE, e.getStackTraceString() ,INVOICETEXT, ApexPages.currentPage().getParameters().get(Label.APTS_Id),BIR,false,true, null , true);
            return null;
        }
    }
    /** Method Name : createCreditMemo()
    * Description : Will create Credit Memo, Credit Memo Line Items based on selected Invoice LIs
    **/
    public PageReference createCreditMemo(){
        Apttus_Billing__CreditMemo__c creditMemo = new Apttus_Billing__CreditMemo__c();
        try{
            if ((Apttus_Billing__CreditMemo__c.sObjectType.getDescribe().isCreateable())&& (Apttus_Billing__CreditMemoLineItem__c.sObjectType.getDescribe().isCreateable())){
            set<Id> selectedList = new set<Id>();
            oSelectedLineItem = null;
            boolean creditAmtExceeded = false;
            boolean noOli=false;
            for (InvoiceLineItemWrapper oInvoiceLineItemWrapper : invoiceLineItemWrapperList) {

                if (oInvoiceLineItemWrapper.selected) {
                    selectedList.add(oInvoiceLineItemWrapper.oInvoiceLineItem.Id);
                    /*if(oInvoiceLineItemWrapper.creditAmount > oInvoiceLineItemWrapper.availableCreditAmount){
                        creditAmtExceeded = true;
                        break;
                    }*/
                    if(oInvoiceLineItemWrapper.creditAmount == 0 && oInvoiceLineItemWrapper.debitAmtBpo == 0){
                        noOli=true;
                    }
                }

            }
            if(selectedList.isEmpty()){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, INVOICELI_VALIDATION));
                return null;
            }
            /*if(creditAmtExceeded){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CREDIT_AMT_VALIDATION));
                return null;
            }*/
            if(noOli){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'To Proceed deselect the Item with 0 Credit Amount' ));
                return null;
            }

            //Create Credit Memo Header here
            //Apttus_Billing__CreditMemo__c creditMemo = new Apttus_Billing__CreditMemo__c();
            //SAP ID field in FD - create new if required
            creditMemo.Apttus_Billing__InvoiceID__c = oInvoiceRecord.oInvoice.Id;
            creditMemo.Apttus_Billing__BillToAccountId__c = oInvoiceRecord.oInvoice.Apttus_Billing__BillToAccountId__c;
            creditMemo.Apttus_Billing__Status__c = oInvoiceRecord.oInvoice.Apttus_Billing__Status__c;
            creditMemo.Apttus_Billing__ReasonCode__c = oInvoiceRecord.reasonCode; 
            creditMemo.Apttus_Billing__Description__c = oInvoiceRecord.description;
            creditMemo.Apttus_Billing__CreditAmount__c = oInvoiceRecord.oInvoice.APTS_Total_Credit_Amount__c;
            creditMemo.APTS_PO_Number__c = oInvoiceRecord.ponumber;
            creditMemo.APTS_Assignment__c = oInvoiceRecord.assignment;
            if(oInvoiceRecord.oInvoice.Apttus_Billing__SoldToAccountId__c != null){
                creditMemo.APTS_Sold_To_Account__c = oInvoiceRecord.oInvoice.Apttus_Billing__SoldToAccountId__c;
            }
            insert creditMemo;

            List<Apttus_Billing__CreditMemoLineItem__c> creditMemoLIList = new List<Apttus_Billing__CreditMemoLineItem__c>();

            //Create Credit Memo Line Items here
            Apttus_Billing__CreditMemoLineItem__c cmli = null;
            for (InvoiceLineItemWrapper oInvoiceLineItemWrapper : invoiceLineItemWrapperList) {

                if (oInvoiceLineItemWrapper.selected) {

                    cmli = new Apttus_Billing__CreditMemoLineItem__c();
                    cmli.Apttus_Billing__CreditMemoId__c = creditMemo.Id;
                    cmli.Apttus_Billing__InvoiceLineItemId__c = oInvoiceLineItemWrapper.oInvoiceLineItem.Id;
                    cmli.Apttus_Billing__Amount__c = oInvoiceLineItemWrapper.creditAmount;
                    if(oInvoiceLineItemWrapper.quantity != null && oInvoiceLineItemWrapper.quantity != 0){
                        cmli.Apttus_Billing__Quantity__c = oInvoiceLineItemWrapper.quantity;
                    }else{
                        cmli.Apttus_Billing__Quantity__c = oInvoiceLineItemWrapper.oInvoiceLineItem.Apttus_Billing__Quantity__c;
                    }
                    cmli.APTS_Product__c = oInvoiceLineItemWrapper.oInvoiceLineItem.APTS_Product__c;
                    cmli.APTS_BPO__c = oInvoiceLineItemWrapper.basePriceOverride;
                    creditMemoLIList.add(cmli);
                }
            }

            if(!creditMemoLIList.isEmpty()){
                insert creditMemoLIList;
            }
               }
            PageReference pageRef;
            if(creditMemo.Id != null){
                pageRef = new PageReference(SLASH + creditMemo.Id);
                return pageRef;
            }
            return null;
        
    }catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, EXCEPTION_OCCURED+e.getMessage()));
            APTS_CustomLogging.createErrorLog(e.getTypeName(), VISUALFORCE, e.getStackTraceString() ,INVOICETEXT, ApexPages.currentPage().getParameters().get(Label.APTS_Id),BIR,false,true, null , true);
            return null;
        }
        
    }

    /** Method Name : createDebitMemo()
    * Description : Will create Debit Memo, Debit Memo Line Items based on selected Invoice LIs
    **///v103<<++ Starts
    public PageReference createDebitMemo(){
        Apttus_Config2__Order__c newOrder = new Apttus_Config2__Order__c();
        Apttus_Config2__OrderLineItem__c newOLI;
        try{
            if ((Apttus_Config2__Order__c.sObjectType.getDescribe().isCreateable())&& (Apttus_Config2__OrderLineItem__c.sObjectType.getDescribe().isCreateable())){
                set<Id> selectedList = new set<Id>();
                oSelectedLineItem = null;
                boolean creditAmtExceeded = false;
                boolean noOli=false;
                Apttus_Billing__InvoiceLineItem__c InvoiceToOrder = new Apttus_Billing__InvoiceLineItem__c();
                List<InvoiceLineItemWrapper> selectedWrapperList = new List<InvoiceLineItemWrapper>();
                Set<Id> orderLineItemIdSet = new Set<Id>();

                for (InvoiceLineItemWrapper oInvoiceLineItemWrapper : invoiceLineItemWrapperList) {

                    if (oInvoiceLineItemWrapper.selected) {
                        selectedList.add(oInvoiceLineItemWrapper.oInvoiceLineItem.Id);
                        InvoiceToOrder=oInvoiceLineItemWrapper.oInvoiceLineItem;
                        selectedWrapperList.add(oInvoiceLineItemWrapper);
                        /*if(oInvoiceLineItemWrapper.creditAmount > oInvoiceLineItemWrapper.availableCreditAmount){
                            creditAmtExceeded = true;
                            break;
                        }
                        if(oInvoiceLineItemWrapper.debitAmtBpo > oInvoiceLineItemWrapper.availableCreditAmount){
                            creditAmtExceeded = true;
                            break;
                        }
                        if(oInvoiceLineItemWrapper.creditAmount == 0 && ){
                            noOli=true;
                        }*/
                        if(oInvoiceLineItemWrapper.oInvoiceLineItem.APTS_AdminOrder_Line__c!=null ){
                            orderLineItemIdSet.add(oInvoiceLineItemWrapper.oInvoiceLineItem.APTS_AdminOrder_Line__c);
                        }else if(oInvoiceLineItemWrapper.oInvoiceLineItem.APTS_Order_Line__c!=null){
                            orderLineItemIdSet.add(oInvoiceLineItemWrapper.oInvoiceLineItem.APTS_Order_Line__c);
                        }
                    }
                }
                if(selectedList.isEmpty()){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, INVOICELI_VALIDATION));
                    return null;
                }
                /*if(creditAmtExceeded){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Debit Amount cannot be greater than the Available Debit from Order'));
                    return null;
                }
                if(noOli){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Do not choose the Bundle Header' ));
                    return null;
                }*/

                Map<String, String> invoiceDeliveryPreferenceMap = new Map<String, String>();
                for(APTS_Invoice_Delivery_Preference__mdt meta : [SELECT Id, MasterLabel, APTS_Value__c FROM APTS_Invoice_Delivery_Preference__mdt where MasterLabel NOT IN :setInvPrf ]){
                    invoiceDeliveryPreferenceMap.put(meta.MasterLabel, meta.APTS_Value__c);
                }

                //Create Debit Memo Order
                if(null != InvoiceToOrder.APTS_AdminOrder_Line__c){
                    newOrder = createAdminOrder(newOrder,InvoiceToOrder.APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__c,oInvoiceRecord);
                    newOrder.Derived_From_Order__c = InvoiceToOrder.APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.Derived_From_Order__c;
                    if(invoiceDeliveryPreferenceMap.containsKey(InvoiceToOrder.APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.APTS_InvoiceDeliveryPreference__c)){
                        newOrder.APTS_InvoiceDeliveryPreference__c = invoiceDeliveryPreferenceMap.get(InvoiceToOrder.APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.APTS_InvoiceDeliveryPreference__c);
                    }
                    else {
                        newOrder.APTS_InvoiceDeliveryPreference__c = InvoiceToOrder.APTS_AdminOrder_Line__r.Apttus_Config2__OrderId__r.APTS_InvoiceDeliveryPreference__c;
                    }
                }else if(null != InvoiceToOrder.APTS_Order_Line__c){
                    newOrder = createAdminOrder(newOrder,InvoiceToOrder.APTS_Order_Line__r.Apttus_Config2__OrderId__c,oInvoiceRecord);
                    newOrder.Derived_From_Order__c = InvoiceToOrder.APTS_Order_Line__r.Apttus_Config2__OrderId__r.Derived_From_Order__c;
                    if(invoiceDeliveryPreferenceMap.containsKey(InvoiceToOrder.APTS_Order_Line__r.Apttus_Config2__OrderId__r.APTS_InvoiceDeliveryPreference__c)){
                        newOrder.APTS_InvoiceDeliveryPreference__c = invoiceDeliveryPreferenceMap.get(InvoiceToOrder.APTS_Order_Line__r.Apttus_Config2__OrderId__r.APTS_InvoiceDeliveryPreference__c);
                    }
                    else {
                        newOrder.APTS_InvoiceDeliveryPreference__c = InvoiceToOrder.APTS_Order_Line__r.Apttus_Config2__OrderId__r.APTS_InvoiceDeliveryPreference__c;
                    }
                }

                Database.SaveResult insertedResultList = Database.Insert(newOrder,false);
                
                List<Apttus_Config2__OrderLineItem__c> oldOLIList = new List<Apttus_Config2__OrderLineItem__c>();
                String fetchExistingOLI = 'SELECT '  
                    + APTS_Utility.getObjectFields('Apttus_Config2__OrderLineItem__c')  
                    + ' FROM Apttus_Config2__OrderLineItem__c WHERE Id In :orderLineItemIdSet';
                Map<Id, Apttus_Config2__OrderLineItem__c> oldOLIMap = new Map<Id, Apttus_Config2__OrderLineItem__c>(oldOLIList=Database.query(fetchExistingOLI));

                Set<Id> oliWithBPOSet=new Set<Id>();
    
                Map<Id,Apttus_Config2__OrderLineItem__c> mapOLIToInsert = new Map<Id,Apttus_Config2__OrderLineItem__c>();
                //Creating OrderLineItems for selected InvoiceLineItems.
                for (InvoiceLineItemWrapper oInvoiceLineItemWrapper : selectedWrapperList) {
                    newOLI = new Apttus_Config2__OrderLineItem__c();
                    if(null != oInvoiceLineItemWrapper.oInvoiceLineItem.APTS_AdminOrder_Line__r 
                        && oldOLIMap.containsKey(oInvoiceLineItemWrapper.oInvoiceLineItem.APTS_AdminOrder_Line__r.Id)){
                        newOLI = createOrderLineItems(newOLI,oldOLIMap.get(oInvoiceLineItemWrapper.oInvoiceLineItem.APTS_AdminOrder_Line__r.Id),
                                                        oInvoiceLineItemWrapper);
                        newOLI.Apttus_Config2__OrderId__c=newOrder.Id;
                        newOLI.Apttus_Config2__DerivedFromId__c = oInvoiceLineItemWrapper.oInvoiceLineItem.APTS_AdminOrder_Line__r.APTS_Original_Order_Line_Item__r.Apttus_Config2__DerivedFromId__c;
                        mapOLIToInsert.put(oInvoiceLineItemWrapper.oInvoiceLineItem.APTS_AdminOrder_Line__r.Id,newOLI);
                        if(oInvoiceLineItemWrapper.bpoAmount >0){
                            oliWithBPOSet.add(oInvoiceLineItemWrapper.oInvoiceLineItem.APTS_AdminOrder_Line__r.Id);
                        }
                    }else if(null != oInvoiceLineItemWrapper.oInvoiceLineItem.APTS_Order_Line__r 
                        && oldOLIMap.containsKey(oInvoiceLineItemWrapper.oInvoiceLineItem.APTS_Order_Line__r.Id)){
                        newOLI = createOrderLineItems(newOLI,oldOLIMap.get(oInvoiceLineItemWrapper.oInvoiceLineItem.APTS_Order_Line__r.Id),
                                                        oInvoiceLineItemWrapper);
                        newOLI.Apttus_Config2__OrderId__c=newOrder.Id;
                        mapOLIToInsert.put(oInvoiceLineItemWrapper.oInvoiceLineItem.APTS_Order_Line__r.Id,newOLI);
                        if(oInvoiceLineItemWrapper.bpoAmount >0){
                            oliWithBPOSet.add(oInvoiceLineItemWrapper.oInvoiceLineItem.APTS_Order_Line__r.Id);
                        }
                    }
                    
                }
                if(!mapOLIToInsert.values().isEmpty()){
                    insert mapOLIToInsert.values();
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
                        if(!oliWithBPOSet.contains(tmpOALI.Apttus_Config2__LineItemId__c) 
                            && mapOLIToInsert.containsKey(tmpOALI.Apttus_Config2__LineItemId__c)){
                            Decimal qty=mapOLIToInsert.get(tmpOALI.Apttus_Config2__LineItemId__c).Apttus_Config2__Quantity__c;
                            Apttus_Config2__OrderAdjustmentLineItem__c newOALI = tmpOALI;
                            newOALI.Apttus_Config2__LineItemId__c = mapOLIToInsert.get(tmpOALI.Apttus_Config2__LineItemId__c).Id;
                            newOALI.Id = NULL;
                            newOALI.Apttus_Config2__IncentiveAdjustmentAmount__c = newOALI.Apttus_Config2__IncentiveAdjustmentAmount__c*qty;
                            lstOALIInsert.add(newOALI);
                        }
                    }
                }
                DescribeSObjectResult objResultLSP2 = APTS_OTCUtil.getsObjectAccess(ADJUSTLINEITESOBJ);    
                if(lstOALIInsert != NULL && lstOALIInsert.size() > 0){
                    if(objResultLSP2!=null && objResultLSP2.isCreateable()){
                        insert lstOALIInsert;
                    }
                }
            }
            PageReference pageRef;
            if(newOrder.Id != null){
                pageRef = new PageReference(SLASH + newOrder.Id);
                return pageRef;
            }
            return null;
        }catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, EXCEPTION_OCCURED+e.getMessage()));
            APTS_CustomLogging.createErrorLog(e.getTypeName(), VISUALFORCE, e.getStackTraceString() ,INVOICETEXT, ApexPages.currentPage().getParameters().get(Label.APTS_Id),BIR,false,true, null , true);
            return null;
        }
    }
    public static Apttus_Config2__Order__c createAdminOrder(Apttus_Config2__Order__c newOrder, Id oldOrderId, 
                                    InvoiceWrapper invoiceRecord){
        Apttus_Config2__Order__c existingOrder = new Apttus_Config2__Order__c();
        String fetchExistingOrder = 'SELECT '  
            + APTS_Utility.getObjectFields('Apttus_Config2__Order__c')  
            + ' FROM Apttus_Config2__Order__c WHERE Id =: oldOrderId';
        existingOrder = Database.query(fetchExistingOrder);
        
        //newOrder = existingOrder.clone(); commented v104 
        //newOrder.OwnerId=UserInfo.getUserId();
        newOrder.APTS_External_Invoice_Number__c = invoiceRecord.oInvoice.APTS_External_Invoice_Number__c;
        newOrder.RecordTypeId = Schema.SObjectType.Apttus_Config2__Order__c.getRecordTypeInfosByName().get(APTS_BIRUtils.ADMINORDER).getRecordTypeId();
        newOrder.Apttus_Config2__ShipToAccountId__c =  invoiceRecord.oInvoice.Apttus_Billing__ShipToAccountId__c;
        newOrder.Apttus_Config2__Status__c = 'Draft';
        newOrder.APTS_Status__c = 'Draft';
        newOrder.APTS_Order_Sub_Type__c = '';
        newOrder.APTS_Order_Type__c = 'Debit Memo';
        newOrder.APTS_Remove_Billing_Block_Indicator__c = true;
        newOrder.Apttus_Config2__OrderStartDate__c = Date.today();
        newOrder.APTS_SAP_OrderType__c = 'XD01';
        newOrder.Apttus_Config2__Description__c = invoiceRecord.description;
        newOrder.APTS_Assignment__c = invoiceRecord.assignment;
        newOrder.APTS_Order_Reason__c = invoiceRecord.reasonCode; 
        newOrder.APTS_Invoice__c = invoiceRecord.oInvoice.Id;
        newOrder.APTS_InvoiceType__c ='Single Invoice';
        newOrder.APTS_Invoice_List_Indicator__c = 'No';
        newOrder.APTS_Configuration_Status__c ='Finalized';
        newOrder.APTS_External_Invoice_Number__c = invoiceRecord.oInvoice.APTS_External_Invoice_Number__c;
        newOrder.Apttus_Config2__PrimaryContactId__c = existingOrder.Apttus_Config2__PrimaryContactId__c;
        newOrder.APTS_Payment_Method_Code__c =  existingOrder.APTS_Payment_Method_Code__c;
        newOrder.APTS_Payment_Method__c = existingOrder.APTS_Payment_Method__c;
        newOrder.Apttus_Config2__PaymentTermId__c = existingOrder.Apttus_Config2__PaymentTermId__c;
        newOrder.Apttus_Config2__BillingPreferenceId__c = existingOrder.Apttus_Config2__BillingPreferenceId__c;
        newOrder.Apttus_Config2__PriceListId__c = existingOrder.Apttus_Config2__PriceListId__c;
        newOrder.Apttus_CMConfig__AgreementId__c = existingOrder.Apttus_CMConfig__AgreementId__c;
        newOrder.Apttus_Config2__SoldToAccountId__c = existingOrder.Apttus_Config2__SoldToAccountId__c;
        newOrder.Apttus_Config2__BillToAccountId__c = existingOrder.Apttus_Config2__BillToAccountId__c;
        newOrder.APTS_Bill_to_Party_Ingredients_and_Payer__c = existingOrder.APTS_Bill_to_Party_Ingredients_and_Payer__c;
        newOrder.APTS_Bill_to_Party_Machines_Services__c = existingOrder.APTS_Bill_to_Party_Machines_Services__c;
        newOrder.APTS_Payer__c = existingOrder.APTS_Payer__c;
        newOrder.APTS_PayerIngredients__c = existingOrder.APTS_PayerIngredients__c;
        newOrder.APTS_PayerMachinesServices__c = existingOrder.APTS_PayerMachinesServices__c;
        newOrder.Apttus_Config2__LocationId__c = existingOrder.Apttus_Config2__LocationId__c;
        newOrder.Apttus_Config2__PricingDate__c = existingOrder.Apttus_Config2__PricingDate__c;
        newOrder.Apttus_Config2__PONumber__c = existingOrder.Apttus_Config2__PONumber__c;
        newOrder.Apttus_Config2__PODate__c = existingOrder.Apttus_Config2__PODate__c;
        newOrder.APTS_Division__c =  existingOrder.APTS_Division__c;
        newOrder.APTS_Distribution_Channel__c = existingOrder.APTS_Distribution_Channel__c;
        newOrder.APTS_Sales_Organization__c = existingOrder.APTS_Sales_Organization__c;
        
        return newOrder;
    }

    public static Apttus_Config2__OrderLineItem__c createOrderLineItems(Apttus_Config2__OrderLineItem__c newOli, 
                                                                        Apttus_Config2__OrderLineItem__c oldOli, 
                                                                        InvoiceLineItemWrapper oInvoiceLineItemWrapper){
        /*newOli = oldOli; Commented v104
        newOli.Id = NULL;
        newOli.CreatedById = UserInfo.getUserId();*/
        newOLI.APTS_Item_Relevant_for_SAP__c = true;
        newOLI.Apttus_Config2__StartDate__c = Date.today();
        newOLI.Apttus_Config2__EndDate__c = Date.today();
        newOLI.Apttus_Config2__ActivatedDate__c = Date.today();
        newOLI.Apttus_Config2__ReadyForBillingDate__c = Date.today();
        newOLI.APTS_Status__c = 'Draft';
        newOLI.Apttus_Config2__Status__c = 'Draft';
        newOLI.APTS_SAP_OrderType__c = 'XD01';
        newOLI.Apttus_Config2__Quantity__c = oInvoiceLineItemWrapper.quantity;
        newOLI.Apttus_Config2__ClassificationId__c = oldOli.Apttus_Config2__ClassificationId__c;
        newOLI.Apttus_Config2__ClassificationHierarchy__c = oldOli.Apttus_Config2__ClassificationHierarchy__c;
        newOLI.APTS_BillingSchedule__c = NULL;
        newOLI.Apttus_Config2__IsPrimaryLine__c = oldOli.Apttus_Config2__IsPrimaryLine__c;
        newOLI.Apttus_Config2__LineType__c = oldOli.Apttus_Config2__LineType__c;
        newOLI.Apttus_Config2__HasOptions__c = oldOli.Apttus_Config2__HasOptions__c;
        newOLI.Apttus_Config2__ChargeType__c = oldOli.Apttus_Config2__ChargeType__c;
        newOLI.APTS_Original_Order_Line_Item__c = oldOli.APTS_Original_Order_Line_Item__c;
        newOLI.APTS_Option_Group_Text__c = oldOli.APTS_Option_Group_Text__c;
        newOLI.APTS_Cumulative_Call_Out_Coverage__c = oldOli.APTS_Cumulative_Call_Out_Coverage__c;
        newOLI.APTS_Cumulative_Labour_coverage__c = oldOli.APTS_Cumulative_Labour_coverage__c;
        newOLI.APTS_Cumulative_Spare_Parts_Coverage__c = oldOli.APTS_Cumulative_Spare_Parts_Coverage__c;
        newOLI.Apttus_Config2__DerivedFromId__c = oldOli.Apttus_Config2__DerivedFromId__c;
        newOLI.Apttus_Config2__ConfigurationId__c = oldOli.Apttus_Config2__ConfigurationId__c;
        newOLI.APTS_Type_of_Contract__c = oldOli.APTS_Type_of_Contract__c;
        newOLI.Apttus_Config2__ProductId__c = oldOli.Apttus_Config2__ProductId__c;
        newOLI.Apttus_CMConfig__AgreementId__c = oldOli.Apttus_CMConfig__AgreementId__c;
        newOLI.Apttus_Config2__SellingUom__c = oldOli.Apttus_Config2__SellingUom__c;
        newOLI.Apttus_Config2__AssetLineItemId__c = oldOli.Apttus_Config2__AssetLineItemId__c;
        newOLI.APTS_Refurbished_or_New__c = oldOli.APTS_Refurbished_or_New__c;
        newOLI.APTS_Payment_Method__c = oldOli.APTS_Payment_Method__c;
        newOLI.Apttus_Config2__PaymentTermId__c = oldOli.Apttus_Config2__PaymentTermId__c;
        newOLI.Apttus_Config2__BillingPreferenceId__c = oldOli.Apttus_Config2__BillingPreferenceId__c;
        newOLI.Apttus_Config2__BillingRule__c = oldOli.Apttus_Config2__BillingRule__c;
        newOLI.Apttus_Config2__BillingFrequency__c = oldOli.Apttus_Config2__BillingFrequency__c;
        newOLI.Apttus_Config2__BillToAccountId__c = oldOli.Apttus_Config2__BillToAccountId__c;
        newOLI.Apttus_Config2__SellingFrequency__c = oldOli.Apttus_Config2__SellingFrequency__c;
        newOLI.Apttus_Config2__OptionId__c = oldOli.Apttus_Config2__OptionId__c;
        newOLI.Apttus_Config2__PriceType__c = oldOli.Apttus_Config2__PriceType__c;
        newOLI.Apttus_Config2__LineNumber__c = oldOli.Apttus_Config2__LineNumber__c;
        newOLI.Apttus_Config2__ItemSequence__c = oldOli.Apttus_Config2__ItemSequence__c;
        newOLI.Apttus_Config2__PriceListId__c = oldOli.Apttus_Config2__PriceListId__c;
        newOLI.Apttus_Config2__PriceListItemId__c = oldOli.Apttus_Config2__PriceListItemId__c;
        newOLI.Apttus_Config2__ListPrice__c = NULL;
        
        if(oldOli.Apttus_Config2__BasePriceOverride__c>0){
            newOLI.Apttus_Config2__BasePrice__c=oldOli.Apttus_Config2__BasePriceOverride__c;
        }else{
            newOLI.Apttus_Config2__BasePrice__c = oldOli.Apttus_Config2__BasePrice__c;
        }
        
        if(oInvoiceLineItemWrapper.bpoAmount >0){
            newOLI.Apttus_Config2__BasePriceOverride__c= oInvoiceLineItemWrapper.bpoAmount;
            newOLI.Apttus_Config2__NetPrice__c=oInvoiceLineItemWrapper.debitAmtBpo;
        }else{
            newOLI.Apttus_Config2__BasePriceOverride__c= null;
            newOLI.Apttus_Config2__NetPrice__c=oInvoiceLineItemWrapper.creditAmount;
        }
        return newOLI;
    }
    //v103++>> Ends
    /** Inner Class Name : InvoiceLineItemWrapper
    * Description : This inner class will hold Invoice Line Item record
    **/
    public with sharing class InvoiceLineItemWrapper{
        public Boolean selected {get; set;}
        public Apttus_Billing__InvoiceLineItem__c oInvoiceLineItem {get; set;}
        public Decimal creditAmount {get;set;}
        public Integer quantity {get;set;}
        public Integer index{get;set;}
        public Decimal perUnit{get;set;}
        public Boolean basePriceOverride{get;set;}
        public Decimal availableCreditAmount{get;set;}
        public Decimal bpoAmount{get;set;}
        public Decimal debitAmtBpo{get;set;}
        

        /** InvoiceLineItemWrapper controller
        * Description : Will be invoked on initialization of the class and holds Record selection, Invoice LI and user entered credit amount
        **/
        public InvoiceLineItemWrapper(Boolean selected, Apttus_Billing__InvoiceLineItem__c oInvoiceLineItem, 
                                        Decimal creditAmount,Integer quantity, Integer index,Decimal perUnit,
                                        Boolean basePriceOverride, Decimal availableCreditAmount,
                                        Decimal bpoAmount, Decimal debitAmtBpo) {
            this.selected = selected;
            this.oInvoiceLineItem = oInvoiceLineItem;
            this.creditAmount = creditAmount;
            this.quantity = quantity;
            this.index = index;
            this.perUnit = perUnit;
            this.basePriceOverride = basePriceOverride;
            this.availableCreditAmount = availableCreditAmount;
            this.bpoAmount = bpoAmount;
            this.debitAmtBpo = debitAmtBpo;
        }
    }

    /** Inner Class Name : InvoiceWrapper
    * Description : This inner class will hold Invoice record
    **/
    public with sharing class InvoiceWrapper{
        public Apttus_Billing__Invoice__c oInvoice {get; set;}
        public string reasonCode {get;set;}
        public string description {get;set;}
        public string ponumber {get;set;}
        public string assignment {get;set;}

        /** InvoiceWrapper controller
        * Description : Will be invoked on initialization of the class and holds Invoice record, Reason Code, Description and PO Number
        **/
        public InvoiceWrapper(Apttus_Billing__Invoice__c oInvoice, String reasonCode, String description,String ponumber,String assignment) {
            this.oInvoice = oInvoice;
            this.reasonCode = reasonCode;
            this.description = description;
            this.ponumber = ponumber;
            this.assignment=assignment;
        }
    }

    /*
    Method: getPicklistValues
    Description: Method returns the picklist value from the field Apttus_Billing__ReasonCode__c of object Apttus_Billing__CreditMemo__c
    */
    public list<SelectOption> getPicklistValues ()
    {

        try{
            SObject obj = new Apttus_Billing__CreditMemo__c();
            String fld = REASONCODEAPI;
            list<SelectOption> options = new list<SelectOption>();

            // Get the object type of the SObject.
            Schema.sObjectType objType = obj.getSObjectType();

             // Describe the SObject using its object type.
             Schema.DescribeSObjectResult objDescribe = objType.getDescribe();   

             // Get a map of fields for the SObject
             map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap(); 

             // Get the list of picklist values for this field.
             list<Schema.PicklistEntry> values = fieldMap.get(fld).getDescribe().getPickListValues();

             // Add these values to the selectoption list.
             SelectOption so = null;
             for (Schema.PicklistEntry a : values)
             { 
                //so = new SelectOption(a.getLabel(), a.getValue());
                so = new SelectOption(a.getValue(), a.getLabel());
                options.add(so); 
             }
             return options;
             }catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, EXCEPTION_OCCURED+e.getMessage()));
            APTS_CustomLogging.createErrorLog(e.getTypeName(), APEX, e.getStackTraceString() ,INVOICETEXT, ApexPages.currentPage().getParameters().get(Label.APTS_Id),BIR,false,true, null , true);
            return null;
        }
    }

    /** Method Name : cancel()
    * Description : Will redirect to invoice Header detail page
    **/
     public PageReference cancel() {

        try{

            PageReference pageRef;

            pageRef = new PageReference(SLASH + currentRecordId);

            return pageRef;
        }catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, EXCEPTION_OCCURED+e.getMessage()));
            APTS_CustomLogging.createErrorLog(e.getTypeName(), APEX, e.getStackTraceString() ,INVOICETEXT, ApexPages.currentPage().getParameters().get(Label.APTS_Id),BIR,false,true, null , true);
            return null;
        }
    }
    //Method to calcualte Credit Amount from user input quantity
    public void getCalculatedAmount(){

        String indexStr = ApexPages.currentPage().getParameters().get('index');
        InvoiceLineItemWrapper wrpInv = invoiceLineItemWrapperList[Integer.valueof(indexStr)];
        wrpInv.creditAmount = (wrpInv.quantity*wrpInv.perUnit).setscale(2);
        wrpInv.debitAmtBpo = (wrpInv.quantity*wrpInv.bpoAmount).setscale(2);
        wrpInv.basePriceOverride = true;
        showDiv = true;
    }
}