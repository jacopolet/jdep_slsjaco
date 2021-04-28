/*************************************************************
@Name: APTS_PricingCallBack
@Author: Galin Georgiev
@CreateDate: 31-01-2018
@Description: Additional pricing logic
@UsedBy: Reprice
******************************************************************/
//v100 31-01-2018 Galin Georgiev: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes
//v101 31.01.2018 Shahul: CPQ_Stream rQTC-Pricing-004-Pricing Model FD
//v102 06.02.2018 Galin : Populate requested delivery date from order header to line items.
//v103 05/03/2018 Hari : Populate Service Price Pricelist item.
//v104 16/03/2018 Balashanthi : Setting Billing Preference, Payment Term, billing rule on Line Item based on Billing setting record related to agreement
//v105 04/05/2018 Balashanthi : Changed the method name to overrideBillingFieldsOnLineItem from setBillingKeyFieldsOnLineItem and also clubbed the logic of setBillingKeyFieldsOnOrderLineItem to overrideBillingFieldsOnLineItem method
//v106 27/06/2018 Raul Orozco : Kauri Defect # 16171
//v107 28/06/2018 Neev Shah : Technical Swap, add LSP Details from Old Asset Line Item
//v108 29/06/2018 Raul Orozco : Change related with incorrect validation of UOM
//v109 25/07/2018 Ariel Quesada: Additions to roll up option price to base extended price when there is no base price in the line
//v110 06/08/2018 Aarthi Pitchai: Added changes to cascade the primary contact from Order Header to Line Item
//v111 14/08/2018 Sethukkrasi: Added changes to cascade the primary account details from Order Header to Line Item
//v112 28/08/2018 Raul Orozco: Query onPriceItemSet removed to avoid SOQL limit issues
//v113 31/08/2018 Aarthi Pitchai: Added logic to populate the Line Item end date based on Selling term
//v114 18/10/2018 Sanjay Nair : Defect 20305  for orders The Line item end date should be changed to start date + selling term (-1)
//v115 -15/11/2018 Lavanya: Waranty chanes for Amend and Non Amend Scenarios
//v116 07/12/2018 Balashanthi : Changes for Defect # 22391 Too many 101 SOQL error during more than line items in the cart
//v117 12/12/2018 Rajesh : Changes for Defect #22270 Triangular Invoicing include Boomerang Invoicing checkbox for identify order.
//v118 12/17/2018 Lavanya : Selling Term Updation for Cancelled Line Items - Defect 22389
//v119 02/01/2019 Balashanthi : CR 2177 - Billing Frequency from Agreement
//v120 01/04/2019 Lavanya -CR2172- Date logic for Ammend/Renew/New Use cases
//v121 07/01/2019 Aarthi : Defect Fix for 23417 - Commented out the lines to set the location based on Agreement in Order Cart
//v122 19/01/2019 Aarthi : CR# 2204 - Commented out the lines to set the End date in Order Cart
//v123 24/01/2019 Aarthi : Defect # 23855 - Added condition to calculate the end date in order cart for all Agreement subTypes, except fixed End date
//v124 24/01/2019 Karan - Default selling UOM issue fix | conflicting with Amendment dates case.
//v125 27/02/2019 Akanksha : Defect # 5463
//v126 12/03/2019 Sanjay  : Defect # 5873 - in Case of Consignment Fillup - XA03 - Price should be zero
//v127 29/03/2019 Kushal  : Indexation CR - bypassing PCB methods for Indexation Order
//v128 21/06/2019 Aarthi  : DOQBI-457 - Set End date on Line Item for Fixed End date type of contract
//v129 25/06/2019 Akanksha : DOK31-263 - For setting Requested installation date - adding condition for XA14
//v130 9JUL2019   Lavanya  : Setting Apttus_Config2__BillingFrequency__c values in Cart-https://jdecoffee.atlassian.net/browse/QTCFLEX1-549
//v131 6/11/2019 Renuka: QTCFLEX1-1599 Setting BillingFrequency in Credit Memo order
//v132 19/11/2019 Renuka: QTCFLEX1-1583 Setting Billing fields directly from Order, if lineItems are orginated from Order. 
//v133 17/12/2019 Karan: DFT2C-1745 Auto-renewal daily job + restoring auto renewal flag
//v134 11/2/2020 Lavanya:DQ-56 , Asset contract change S.No and Termination AssetLine Population and Warranty Enable PAR
//v135 23/07/2020 Manisha: DQ-3214, Populating Requested Delivery Date and Installation contact for De-Installation flow.
//v136 25/09/2020 Shahuk: DQ-3948, Default Stop RTR Transactions from asset line item.
//v137 11/05/2020 Lavanya DQ-3797 Operating orders Selling UOM issue
//v138 06/11/2020 Renuka: DQ-3907 Cascade xc09 block to ASLI
//v139 01/22/2021 Aarthi: DQ-5095 ReOrder Changes - Selling UOM
//v140 02/02/2021 Aarthi: DQ-4114 Freight Charges - Price Matrix for Germany

global with sharing class APTS_PricingCallBack implements Apttus_Config2.CustomClass.IPricingCallback3 {
    
    private Apttus_Config2.ProductConfiguration cart = null;
    private Apttus_Config2.CustomClass.PricingMode mode = null;
    private Id prodConfigId;
    private static final String Upgraded = 'Upgraded';
    //v102++<<
    private static final String NGSTANDARD_ORDER = System.Label.APTS_NGStandardOrder;
    private static final String NGADMIN_ORDER = System.Label.APTS_NGAdminOrder;
    private static final String NGMACHINE_ORDER = System.Label.APTS_NGMachineOrder;
    private static final String NGDEFAULT_AGREEMENT='NGDefault';
    private String sFlow;
    private Date dtInitialRequestedDelivaryDate;
    //v103++>>
    //Private static Decimal sumcoverage;
    public String OFFERING = '' ;
    public String productOptionGroup = '' ;
    public String CategoryHierachy = '';
    public String CONSUMPTION = '';
    public String BUSINESS_OBJECT_TYPE_AGR = ''; 
    public Decimal netPriceRollup = 0;  
    public List<Apttus_Config2.LineItem> frieghtChargesList = new List<Apttus_Config2.LineItem>();
    //public List<Apttus_Config2.LineItem> DateUpdateList = new List<Apttus_Config2.LineItem>();
    //v124
    public Map<Id,boolean> pendingLineItemMap = new Map<Id,boolean>();
    //DQ-56
     public Map<Id, Apttus_Config2__LineItem__c> MapCancelledLines=new Map<Id, Apttus_Config2__LineItem__c>();
    public Map<Id, Apttus_Config2__LineItem__c> MapNewLines= new Map<Id, Apttus_Config2__LineItem__c>();
    public static final String Cancelled = 'Cancelled';
    public static final String STR_NEW = 'New';
    public static final String OPTION = 'Option';
    public static final String MenuOption ='04';
    public static final String ConnectivitySystem='0106';
    //DQ-56
    //v110++<<
    
    private static final String NGRSO_ORDER = System.Label.APTS_NGRSOOrder;
    //v110++>>
    //v116++<<
    public static Map<Id,Map<String,APTS_Billing_Settings__c>> agreementBillingSettingMap = new Map<Id,Map<String,APTS_Billing_Settings__c>>();
    private static final String AGREEMENT = 'Agreement';
    private static final String CONVERSIONORDER = 'Conversion Order';
    private static final String ORDER = 'Order';
    private static final String RENEWAL = 'Renewal';
    private static final String PHYSICALMOVEMENT = 'External Movement With Contract Change';
    private static final String PHYSICALMOVEMENTWITHOUT = 'External Movement Without Contract Change';
    private static final String PHYSICALINTERNALMOVEMENT= 'Internal Movement';
    public static Map<Id,Apttus_Config2__Order__c> orderAgreementMap = new Map<Id,Apttus_Config2__Order__c>();
    //v116++>>
  //v127++<<
  public static String orderSubType;
    //v127++>>

    //v138++<<
    private Set<String> orderSubSubTypes = new Set<String>{'Discounts','Billing Settings','Termination','Add/Remove Options'};
    //v138++>>

    global void start(Apttus_Config2.ProductConfiguration cart) {
        
        this.cart = cart;
        
        prodConfigId = cart.getConfigSO().Id;
        //v102++<<
    //v127++<<
    orderSubType = cart.getConfigSO().Order_Sub_Type__c;
    //v127++>>
        sFlow = cart.getConfigSO().APTS_Flow__c;
        dtInitialRequestedDelivaryDate = cart.getConfigSO().APTS_Requested_Delivery_Date__c;
        //v102++>>
        
        //v116++<<
    //v127++<<
    if(orderSubType != APTS_CPQConstants.ORDERSUBTYPEINDEXATION 
       && orderSubType != APTS_PricingCallBack.CONVERSIONORDER
       && orderSubType != APTS_PricingCallBack.RENEWAL){
    //v127++>>
        if(cart.getConfigSO().Apttus_Config2__BusinessObjectType__c.equalsIgnoreCase(AGREEMENT)
           && cart.getConfigSO().Apttus_CMConfig__AgreementId__c != null
           && !agreementBillingSettingMap.containsKey(cart.getConfigSO().Apttus_CMConfig__AgreementId__c)){
               // Retrieve Agreement's Billing setting
               Map<Id,Map<String,APTS_Billing_Settings__c>> tempMap = APTS_BIRUtils.retrieveBillingSetting(cart.getConfigSO().Apttus_CMConfig__AgreementId__c);
               if(!tempMap.isEmpty()){
                   // saving it in a global variable to use in AfterPricing Method
                   agreementBillingSettingMap.putAll(tempMap);

               }
               
           }else{
               if(cart.getConfigSO().Apttus_Config2__BusinessObjectType__c.equalsIgnoreCase(ORDER)
                  && cart.getConfigSO().Apttus_Config2__OrderId__c != null){
                      
                      Map<Id,Apttus_Config2__Order__c> temporderAgreementMap =  APTS_BIRUtils.retrieveAgreement(cart.getConfigSO().Apttus_Config2__OrderId__c);
                        if(!temporderAgreementMap.isEmpty()){
                            // saving  in a global variable to avoid the below SOQL to fire again 
                            orderAgreementMap.putAll(temporderAgreementMap);// Save it in a global variable
                        }
                        //Commented below part of code v132<<++
                      /*if(!orderAgreementMap.containsKey(cart.getConfigSO().Apttus_Config2__OrderId__c)){
                          
                          // find the agreement associated to that order
                          Map<Id,Apttus_Config2__Order__c> temporderAgreementMap =  APTS_BIRUtils.retrieveAgreement(cart.getConfigSO().Apttus_Config2__OrderId__c);
                          if(!temporderAgreementMap.isEmpty()){
                              // saving  in a global variable to avoid the below SOQL to fire again 
                              orderAgreementMap.putAll(temporderAgreementMap);// Save it in a global variable
                          }
                      }
                      //Commented below part of code v132<<++
                      /*if(!orderAgreementMap.isEmpty()
                         && orderAgreementMap.containsKey(cart.getConfigSO().Apttus_Config2__OrderId__c)
                         && orderAgreementMap.get(cart.getConfigSO().Apttus_Config2__OrderId__c) != null
                         && !agreementBillingSettingMap.containsKey(orderAgreementMap.get(cart.getConfigSO().Apttus_Config2__OrderId__c))){
                             // Retrieve Billing setting data for that Agreement associated to Order
                             Map<Id,Map<String,APTS_Billing_Settings__c>> tempMapBS = APTS_BIRUtils.retrieveBillingSetting(orderAgreementMap.get(cart.getConfigSO().Apttus_Config2__OrderId__c));
                             if(!tempMapBS.isEmpty()){
                                 // saving it in a global variable to use in AfterPricing Method
                                 agreementBillingSettingMap.putAll(tempMapBS);
                                 
                             }
                             
                      }*/  
                  }
           }
        //v116++>>
    //v127++<<
    }
    //v127++>>
        
    }
    
    global void setMode(Apttus_Config2.CustomClass.PricingMode mode) {
        this.mode = mode;
    }
   
    global void onPriceItemSet(Apttus_Config2__PriceListItem__c itemSO, Apttus_Config2.LineItem lineItemMO) {
     
        Apttus_Config2__LineItem__c oLineItem= lineItemMO.getLineItemSO();
        
        if( oLineItem.Apttus_Config2__AssetLineItemId__c!=null && oLineItem.Apttus_Config2__LineType__c == 'Option'){  
            oLineItem.Apttus_Config2__IsCustomPricing__c = true;
            //if(oLineItem.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__BasePrice__c!=null) oLineItem.Apttus_Config2__BasePrice__c = oLineItem.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__BasePrice__c;
            //if(oLineItem.Apttus_Config2__AssetLineItemId__r.APTS_BasePriceOverride__c!=null) oLineItem.Apttus_Config2__BasePriceOverride__c = oLineItem.Apttus_Config2__AssetLineItemId__r.APTS_BasePriceOverride__c;
        }
        
        
        //v127++<<
        if(orderSubType != APTS_CPQConstants.ORDERSUBTYPEINDEXATION 
          && orderSubType != APTS_PricingCallBack.CONVERSIONORDER
          && orderSubType != APTS_PricingCallBack.RENEWAL
          &&orderSubType !=APTS_PricingCallBack.PHYSICALMOVEMENT
          &&orderSubType !=APTS_PricingCallBack.PHYSICALMOVEMENTWITHOUT
          &&orderSubType !=APTS_PricingCallBack.PHYSICALINTERNALMOVEMENT){
          //v132<<++
          if(!orderAgreementMap.isEmpty() 
            && orderAgreementMap.containsKey(oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__c)){
              oLineItem.Apttus_Config2__BillingPreferenceId__c = orderAgreementMap.get(oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__c).Apttus_Config2__BillingPreferenceId__c;
              oLineItem.Apttus_Config2__BillingRule__c = orderAgreementMap.get(oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__c).Apttus_Config2__BillingPreferenceId__r.APTS_Billing_Rule_Contract__c;
              oLineItem.Apttus_Config2__PaymentTermId__c = orderAgreementMap.get(oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__c).Apttus_Config2__PaymentTermId__c;
              oLineItem.APTS_Payment_Method__c = orderAgreementMap.get(oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__c).APTS_Payment_Method__c;
          }else{
            //v119 >> Changes Added by Balashanthi for CR 2177 Starts
            APTS_BIRUtils.overrideBillingFieldsOnLineItem(oLineItem,agreementBillingSettingMap);
            //v119 >> Changes Added by Balashanthi for CR 2177 Ends
          }//v132++>>
      }
      //v127++>>
    }
    
    global void beforePricing(Apttus_Config2.ProductConfiguration.LineItemColl itemColl) {
        
        
        List<Apttus_Config2.LineItem> lineItemList = itemColl.getAllLineItems();
        List<Apttus_Config2__LineItem__c> allLineItemList = getLineItems(lineItemList);
        //Waranty
        /*Integer TempContractTerm;
        Integer TempWaranty;
        Date today;     
        Map<Decimal,Date> mapAmendDate = new Map<Decimal,Date>();
        Map<Decimal,List<Id>> mapConditionAmend = new  Map<Decimal,List<Id>>();*/
        
        
        Decimal indexPerct;
        Id aggid, aggidfororder;
        String aggcountry, indexcategory;
        List<APTS_Indexation_Executing__c> indexexeclst = new List<APTS_Indexation_Executing__c>();
        List<String> catgryhierarchy = new List<String>();
        Date TempDate;
        Integer TempContractTerm;
        Map<String, List<String>> oIndexContractMap = new Map<String, List<String>>();
        List<String> ingredientOptionGroupIndicators = System.Label.APTS_ingredients_OG_indicators.split(',');
        List<String> priceTypesAutoAssetRenewals = System.Label.APTS_Allowable_price_type_auto_renewals.split(',');
        Map<decimal,decimal> mapQuantity = new Map<decimal,decimal>();

       
        if (mode == Apttus_Config2.CustomClass.PricingMode.BASEPRICE) {
          for (Apttus_Config2.LineItem configLineItem : lineItemList) {
              Apttus_Config2__LineItem__c oLineItem = configLineItem.getLineItemSO(); 
              if(oLineItem.Apttus_Config2__AssetLineItemId__r.APTS_Stop_RtR_Transactions_from__c!=null){
              oLineItem.APTS_Stop_RtR_Transactions_from__c=oLineItem.Apttus_Config2__AssetLineItemId__r.APTS_Stop_RtR_Transactions_from__c;
              }else{oLineItem.APTS_Stop_RtR_Transactions_from__c=system.today().adddays(10000);}
              //v135++<<
              //Populating Requested Delivery Date and Installation contact for De-Installation flow
              if(sFlow==APTS_OrderConstants.NG_MACHINEDEINSTALLORDER){
              oLineItem.APTS_Installation_Contact__c = oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.Apttus_Config2__PrimaryContactId__c;
              oLineItem.APTS_Requested_Delivery_Date__c = dtInitialRequestedDelivaryDate;
              }
              //v135++>>
              //DQ-56 Warranty PAR Enabling Logic from Asset Contract Change         
              if(oLineItem.APTS_Type_of_Contract__c != null && oLineItem.Apttus_Config2__LineStatus__c  == Upgraded  && !oLineItem.APTS_OldContractCheck__c)
              {oLineItem.APTS_CTC_Old_TOC__c = oLineItem.APTS_Type_of_Contract__c; olineItem.APTS_OldContractCheck__c=true;}      
       
              
              //Defect Fix #23420
            if(oLineItem.Apttus_Config2__IsPrimaryLine__c) {
               mapQuantity.put(oLineItem.Apttus_Config2__ParentBundleNumber__c,oLineItem.Apttus_Config2__Quantity__c);
            }
              if (sFlow == NGSTANDARD_ORDER || sFlow == NGMACHINE_ORDER || sFlow == NGRSO_ORDER || sFlow == APTS_OrderConstants.NGSTANDARD_ORDERWOC || sFlow == APTS_OrderConstants.NGRSO_ORDERWOC) {
                if(oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.Apttus_Config2__OrderStartDate__c!=null &&oLineItem.APTS_Agreement_Line_Item__r.Apttus_CMConfig__AttributeValueId__r.APTS_Number_of_months__c!=null){
                TempDate=oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.Apttus_Config2__OrderStartDate__c.addMonths(Integer.ValueOf(oLineItem.APTS_Agreement_Line_Item__r.Apttus_CMConfig__AttributeValueId__r.APTS_Number_of_months__c));}

                 if(oLineItem.APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingTerm__c!=null){TempContractTerm=Integer.valueof(oLineItem.APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingTerm__c);}
                if(oLineItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.Apttus_Config2__Label__c=='Technical Service'&&TempDate!=null&&TempContractTerm!=null){
                oLineItem.Apttus_Config2__StartDate__c = TempDate;
                oLineItem.Apttus_Config2__SellingTerm__c=null;
                oLineItem.Apttus_Config2__EndDate__c = TempDate.addmonths(TempContractTerm);
                //oLineItem.Apttus_Config2__EndDate__c=null;

                //System.today().addmonths(7);
              }//configLineItem.updatePrice();
            }
            if(oLineItem.Apttus_Config2__IsPrimaryLine__c==false&&oLineItem.Apttus_Config2__LineType__c=='Product/Service' && !mapQuantity.isEmpty() && mapQuantity.get(oLineItem.Apttus_Config2__ParentBundleNumber__c)!=null){
              oLineItem.Apttus_Config2__Quantity__c=mapQuantity.get(oLineItem.Apttus_Config2__ParentBundleNumber__c);
            }               
            if(oLineItem.Apttus_Config2__LineStatus__c == 'Cancelled' && oLineItem.Apttus_Config2__SellingTerm__c < 1){ //Defect 22389{
              oLineItem.Apttus_Config2__SellingTerm__c=1;            
            }
            //v126++<<
            if (oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__c != null && oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c != null && oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c == APTS_OrderConstants.XA03)
            { 
                oLineItem.Apttus_Config2__BasePriceOverride__c = 0;                 
            }
             //AUTO RENEWALS CHANGES | CASCADE AUTO RENEWAL FLAG FROM AGREEMENT TO CONFIG
            if(oLineItem.Apttus_Config2__ConfigurationId__c!=null &&
              oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__c!=null &&
              oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.Apttus__Auto_Renewal__c){
              if(oLineItem.Apttus_Config2__ProductId__r.APTS_Sales_Catalog__c!=null && (oLineItem.Apttus_Config2__ProductId__r.APTS_Sales_Catalog__c.startsWith('04') || oLineItem.Apttus_Config2__ProductId__r.APTS_Sales_Catalog__c.startsWith('0701'))){
                oLineItem.Apttus_Config2__AutoRenew__c = true; 
              }else{
                oLineItem.Apttus_Config2__AutoRenew__c = false;
              }
            }
            //AUTO RENEWALS CHANGES | CASCADE START DATE AND END DATE FROM ORDER TO LINE ITEMS
            Date scopeEndDate = Date.valueOf(System.today()+Integer.valueOf(System.Label.APTS_Auto_renewal_scope_date));
            if(oLineItem.Apttus_Config2__ConfigurationId__c!=null &&
              oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__c!=null &&
              oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Auto_renewal_staging_source_id__c!=null &&
              oLineItem.Apttus_Config2__AssetLineItemId__c!=null &&
              //v133<----
              oLineItem.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__EndDate__c <= scopeEndDate &&
              //v133---->
              priceTypesAutoAssetRenewals.contains(oLineItem.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__PriceType__c) && 
              oLineItem.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__AssetStatus__c == 'Activated' && 
              oLineItem.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__AutoRenew__c){
                  oLineItem.Apttus_Config2__StartDate__c = oLineItem.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__EndDate__c.addDays(1);
                  oLineItem.Apttus_Config2__EndDate__c = oLineItem.Apttus_Config2__StartDate__c.addMonths(12).addDays(-1);
                  //oLineItem.Apttus_Config2__StartDate__c = oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.Apttus_Config2__OrderStartDate__c;
                  //oLineItem.Apttus_Config2__EndDate__c = oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.Apttus_Config2__OrderEndDate__c;
                  oLineItem.Apttus_Config2__LineStatus__c='Renewed';
                  oLineItem.Apttus_Config2__AutoRenew__c = true;
            }
            //v138++<<            
            if( oLineItem.Apttus_Config2__LineType__c != null &&
                oLineItem.Apttus_Config2__LineStatus__c!=null &&  
                oLineItem.Apttus_Config2__ConfigurationId__c!=null && 
                oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__c!=null && 
                oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Sub_Type__c!=null)
            {
                if(orderSubSubTypes.contains(oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Sub_Type__c)){
                    olineItem.APTS_Credit_Proposal_XC09_Block__c = olineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Credit_Proposal_XC09_Block__c;
                }
            } //V138++>>
            
            /* AUTO RENEWALS CHANGES
            if(oLineItem.Apttus_Config2__ConfigurationId__c!=null &&
              oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__c!=null &&
              oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.Apttus__Auto_Renewal__c){
              if(oLineItem.Apttus_Config2__ProductId__r.APTS_Sales_Catalog__c.startsWith('04')){
                oLineItem.Apttus_Config2__AutoRenew__c = true; 
                oLineItem.Apttus_Config2__AutoRenewalTerm__c = 12;
                oLineItem.Apttus_Config2__AutoRenewalType__c = 'Fixed';
              }else{
                oLineItem.Apttus_Config2__AutoRenew__c = false;
                oLineItem.Apttus_Config2__AutoRenewalTerm__c = null;
                oLineItem.Apttus_Config2__AutoRenewalType__c = null;
              }
            }
            */
            //v126 -- >>
            //Set Custom quantity | only for matrices
            /*if(oLineItem.Apttus_Config2__Quantity__c!=null &&  oLineItem.Apttus_Config2__Quantity__c!=0 &&
              oLineItem.APTS_Default_Selling_UOM__c!=null && 
              (oLineItem.Apttus_Config2__PriceListItemId__r.APTS_Default_selling_UOM__c!=oLineItem.Apttus_Config2__PriceListItemId__r.Apttus_Config2__PriceUom__c) && 
              oLineItem.APTS_UOM_conversion_factor__c!=null && oLineItem.Apttus_Config2__PriceListItemId__r.Apttus_Config2__PriceListId__r.Apttus_Config2__BasedOnPriceListId__c!=null &&
              oLineItem.Apttus_Config2__PriceListItemId__r.Apttus_Config2__NumberOfMatrices__c!=0){
                oLineItem.APTS_UOM_based_quantity__c   = oLineItem.Apttus_Config2__Quantity__c * oLineItem.APTS_UOM_conversion_factor__c;
            }*/

          }
        }

        //Here we can add logic executed before pricing engine only for updated line items
        if (mode == Apttus_Config2.CustomClass.PricingMode.ADJUSTMENT) {
                        
            for (Apttus_Config2.LineItem configLineItem : lineItemList) {
                Apttus_Config2__LineItem__c oLineItem = configLineItem.getLineItemSO();
                //v137  DQ-3797 Operating orders Selling UOM issue
                //v117++<< added condition on 12 Dec 2018 oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Boomerang_Invoicing__c == true
                //V139 Added additional condition with source of order creation
                if(((oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__BusinessObjectType__c == APTS_CPQConstants.LABEL_ORDER && oLineItem.APTS_Agreement_Line_Item__c==null && oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Source_Order_Number__c==null && (oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__c!=null && !(oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Boomerang_Invoicing__c == true) && (oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Source_of_Order_Creation__c != 'Reorder'))) || 
                    oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__BusinessObjectType__c == APTS_CPQConstants.LABEL_AGREEEMENT) &&
                   !oLineItem.APTS_is_selling_UOM_defaulted__c && 
                   !oLineItem.Apttus_Config2__ProductId__r.name.equalsIgnoreCase(System.Label.APTS_FREIGHT_CHARGES_PRODUCT_NAME) && 
                   oLineItem.Apttus_Config2__PriceListItemId__c!=null && oLineItem.Apttus_Config2__PriceListItemId__r.Apttus_Config2__PriceUom__c!=null && oLineItem.Apttus_Config2__PriceListItemId__r.APTS_Default_selling_UOM__c!=null && !oLineItem.Apttus_Config2__HasOptions__c && 
                   (oLineItem.Apttus_Config2__OptionId__c==null || 
                    (oLineItem.Apttus_Config2__OptionId__c!=null && oLineItem.Apttus_Config2__OptionId__r.APTS_Option_Group_Indicator__c!=null && ingredientOptionGroupIndicators.contains(oLineItem.Apttus_Config2__OptionId__r.APTS_Option_Group_Indicator__c)))
                     &&
                    oLineItem.Apttus_Config2__PriceListItemId__r.Apttus_Config2__NumberOfMatrices__c==0){
                        //v117++>>
                        oLineItem.Apttus_Config2__SellingUom__c=oLineItem.Apttus_Config2__PriceListItemId__r.APTS_Default_selling_UOM__c;
                        oLineItem.APTS_is_selling_UOM_defaulted__c=true;
                    if(oLineItem.Apttus_Config2__PriceListItemId__r.APTS_Default_selling_UOM__c!=oLineItem.Apttus_Config2__PriceListItemId__r.Apttus_Config2__PriceUom__c){
                        oLineItem.Apttus_Config2__PricingStatus__c=APTS_CPQConstants.LABEL_PRICING_PENDING;
                        //v124
                        if(pendingLineItemMap.get(oLineItem.id)==null){
                            pendingLineItemMap.put(oLineItem.id,true);
                        }
                    }
                }
                if(oLineItem.Apttus_Config2__LineType__c.equalsIgnoreCase('Option') && 
                    oLineItem.Apttus_Config2__LineStatus__c!=null &&  
                    oLineItem.Apttus_Config2__ConfigurationId__c!=null && 
                    oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__c!=null && 
                    oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Sub_Type__c!=null &&  
                    oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Sub_Type__c.equalsIgnoreCase('Add/Remove Options')){
                    if(oLineItem.Apttus_Config2__PriceAdjustment__c==null &&
                       oLineItem.Apttus_Config2__LineStatus__c.equalsIgnoreCase('Cancelled')){
                        oLineItem.Apttus_Config2__PriceAdjustment__c=oLineItem.Apttus_Config2__AdjustedPrice__c; 
                    }
                }
            }
    //v127++<<
        }
    //v127++>>
    } 
    
    global void beforePricingLineItem(Apttus_Config2.ProductConfiguration.LineItemColl itemColl, Apttus_Config2.LineItem lineItemMO) {
    //v127++<<
        //if(orderSubType != APTS_CPQConstants.ORDERSUBTYPEINDEXATION){
    //v127++>>  
        Apttus_Config2__LineItem__c oLineItem = lineItemMO.getLineItemSO();
         Integer TempContractTerm;
            Integer TempWaranty;
            Date today;     
            Map<Decimal,Date> mapAmendDate = new Map<Decimal,Date>();
            Map<Decimal,List<Id>> mapConditionAmend = new  Map<Decimal,List<Id>>();
            
        //V110++<<
        //13 Aug 2018 - Aarthi - Added below to set the Requested delivery date at Line item for Standard Return orders.
        oLineItem.APTS_Requested_Delivery_Date__c = dtInitialRequestedDelivaryDate;
        //V110++>>
        if (sFlow == NGMACHINE_ORDER && oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Requested_Installation_Date__c != null) { //v129
            oLineItem.APTS_Requested_Delivery_Date__c = dtInitialRequestedDelivaryDate;
            oLineItem.APTS_Requested_Installation_Date__c = oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Requested_Installation_Date__c;
        } else if (sFlow == NGSTANDARD_ORDER || sFlow == NGRSO_ORDER || sFlow == APTS_OrderConstants.NGSTANDARD_ORDERWOC || sFlow == APTS_OrderConstants.NGRSO_ORDERWOC) {
            if (oLineItem.Apttus_Config2__ConfigurationId__r.APTS_Max_Requested_Delivery_Date__c == null) {
                oLineItem.APTS_Requested_Delivery_Date__c = dtInitialRequestedDelivaryDate;
            } else if (oLineItem.Apttus_Config2__ConfigurationId__r.APTS_Max_Requested_Delivery_Date__c != oLineItem.APTS_Requested_Delivery_Date__c) {
                oLineItem.APTS_Requested_Delivery_Date__c = oLineItem.Apttus_Config2__ConfigurationId__r.APTS_Max_Requested_Delivery_Date__c;
            }
            //v126++<<
            // if(oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c == 'XA03') {oLineItem.Apttus_Config2__BasePriceOverride__c = 0;     }
            //v126-->>
        }
        
        if (sFlow == NGSTANDARD_ORDER || sFlow == NGMACHINE_ORDER || sFlow == NGRSO_ORDER || sFlow == APTS_OrderConstants.NGSTANDARD_ORDERWOC || sFlow == APTS_OrderConstants.NGRSO_ORDERWOC) 
        {
            
           oLineItem.Apttus_Config2__LocationId__c = oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.Apttus_Config2__LocationId__c;
           
            //v110++<<
            oLineItem.APTS_Installation_Contact__c = oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.Apttus_Config2__PrimaryContactId__c;
            //v110++>>      
            //V113++<<           
            //31-Aug-2018 - Added below to populate the Order Line Item end date based on Selling term
            //v114++<<
            //18-10-18 - changed to logic to populate end date = start date + selling term  -1 
          /*  if(oLineItem.APTS_Type_of_Contract__c!='Sales'&&oLineItem.Apttus_Config2__AttributeValueId__r.APTS_Number_of_months__c==null&&
            !oLineItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.Apttus_Config2__Label__c.equalsIgnorecase('Technical Service')&&
            oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.Apttus_Config2__OrderStartDate__c!=null){
            oLineItem.Apttus_Config2__StartDate__c = oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.Apttus_Config2__OrderStartDate__c;
          }

          if(oLineItem.APTS_Agreement_Line_Item__r.APTS_Type_of_Contract__c=='Sales'&&oLineItem.APTS_Agreement_Line_Item__r.APTS_Option_Group_Text__c=='Technical Service'&&
            oLineItem.APTS_Agreement_Line_Item__r.Apttus_CMConfig__AttributeValueId__r.APTS_Number_of_months__c!=null){
            oLineItem.Apttus_Config2__StartDate__c=oLineItem.Apttus_Config2__StartDate__c.addMonths(Integer.ValueOf(oLineItem.APTS_Agreement_Line_Item__r.Apttus_CMConfig__AttributeValueId__r.APTS_Number_of_months__c)).adddays(-1);
            oLineItem.Apttus_Config2__PricingStatus__c  = 'Pending';
          }*/
            if(oLineItem.APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingTerm__c != null &&   oLineItem.APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingTerm__c != 0)
            {
                //v122
                //oLineItem.Apttus_Config2__EndDate__c = oLineItem.Apttus_Config2__StartDate__c.addMonths(Integer.ValueOf(oLineItem.APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingTerm__c)).adddays(-1);            
                //oLineItem.Apttus_Config2__SellingTerm__c = oLineItem.APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingTerm__c;
               }
      
      //v126<<--
             if(oLineItem.Apttus_Config2__PriceType__c=='One Time'&&oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c == APTS_OrderConstants.XA14 && oLineItem.Apttus_Config2__AssetLineItemId__c!=null && oLineItem.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__StartDate__c != NULL && oLineItem.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__EndDate__c != NULL){
                oLineItem.Apttus_Config2__StartDate__c = oLineItem.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__StartDate__c;
                oLineItem.Apttus_Config2__EndDate__c = oLineItem.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__EndDate__c;
            }
            //v126-->>
            
            if(oLineItem.Apttus_Config2__LineStatus__c == 'Cancelled' && oLineItem.Apttus_Config2__SellingTerm__c < 1)
            {
                oLineItem.Apttus_Config2__SellingTerm__c=1;        //Defect 22389       
            }
            //V113++>>
            //V114++>>
            //v125++<<
            if(oLineItem.APTS_Agreement_Line_Item__c != null && oLineItem.APTS_Agreement_Line_Item__r.Apttus_CMConfig__BillingFrequency__c != null&&oLineItem.Apttus_Config2__IsOptionRollupLine__c==false) {
                oLineItem.Apttus_Config2__BillingFrequency__c = oLineItem.APTS_Agreement_Line_Item__r.Apttus_CMConfig__BillingFrequency__c;
            }else if(oLineItem.APTS_Agreement_Line_Item__c != null && oLineItem.APTS_Agreement_Line_Item__r.Apttus_CMConfig__BillingFrequency__c != null&&oLineItem.Apttus_Config2__IsOptionRollupLine__c==true){
              String CTTOC=oLineItem.APTS_Type_of_Contract__c+';'+oLineItem.Apttus_Config2__ChargeType__c;
              APTS_Billing_Frequency__c BF=APTS_Billing_Frequency__c.getvalues(CTTOC);
              if(BF!=null){oLineItem.Apttus_Config2__BillingFrequency__c=BF.APTS_Biiling_Frequency__c;}
            }
            //v125++>>
            
        }
        
        //v111++<<
        //v121++ <<
       /* if(oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__c != null)
        {
             oLineItem.Apttus_Config2__LocationId__c = oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.APTS_Location__c; 
        } */
        //v121++ >>
        oLineItem.Apttus_Config2__BillToAccountId__c = oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__BillToAccountId__c;
        oLineItem.Apttus_Config2__ShipToAccountId__c  = oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__ShipToAccountId__c;

        //v111++>>
    //v127++<<
    //}
    //v127++>>
    } 
    
    
    global void afterPricing(Apttus_Config2.ProductConfiguration.LineItemColl itemColl) {
    //v127++<<
        //if(orderSubType != APTS_CPQConstants.ORDERSUBTYPEINDEXATION){
    //v127++>>
        Boolean allinCoverage = False;
        Boolean basiccoverage = False;
        Decimal coverageSum = 0;
        Decimal calloutcoveragesum = 0;
        Decimal labourcoveragesum = 0;
        Decimal sparepartscoveragesum = 0;
        Set<ID> bundleCoverageSet = new Set<Id>();
        Map<String,boolean> hasCOCMap = new Map<String,boolean>();
        Map<String,boolean> hasSPCMap = new Map<String,boolean>();
        Map<String,boolean> hasLCMap = new Map<String,boolean>();
        Map<String,String> totalCoverageMap = new Map<String,String>();
        Map<String,Integer> bundleWarrentyMap = new Map<String,Integer>();
        Map<Decimal,Date> mapAmendDate = new Map<Decimal,Date>(); 
        Map<String,Apttus_Config2__AssetLineItem__c> mapAssetEndDate = new Map<String,Apttus_Config2__AssetLineItem__c>();
        Map<String,Apttus_Config2__AssetLineItem__c> primaryLineAssetMap = new Map<String,Apttus_Config2__AssetLineItem__c>();    
        Map<Decimal,List<Id>> mapConditionAmend = new  Map<Decimal,List<Id>>(); 
        List<Apttus_Config2.LineItem> lineItemList = itemColl.getAllLineItems();
        List<Apttus_Config2__LineItem__c> allLineItemList = getLineItems(lineItemList);
        //DateUpdateList = itemColl.getAllLineItems();
      
        // Added for Testing
        if(mode == Apttus_Config2.CustomClass.PricingMode.BASEPRICE){
            
            for (Apttus_Config2__LineItem__c oLineItem : allLineItemList) {
                oLineItem.APTS_Agreement__c = oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__c; //Added by Juhi Rawal(Apttus) on 11th Apr,2018 for populating Agreement on Line Item.
                if (sFlow == 'NGDefault') {
                    oLineItem.Apttus_Config2__LocationId__c = oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.APTS_Location__c;
                }
                Offering =  oLineItem.Apttus_Config2__ClassificationId__r.Apttus_Config2__HierarchyId__r.Name;
                productOptionGroup = oLineItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.Apttus_Config2__Label__c;
                CategoryHierachy = oLineItem.APTS_Category_Hierarchy_Text__c;
                
                BUSINESS_OBJECT_TYPE_AGR = oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__BusinessObjectType__c;
                
                CONSUMPTION = oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.RecordType.Name;
                
                if (BUSINESS_OBJECT_TYPE_AGR.equals('Agreement') && CONSUMPTION.equals('Consumptions Model')) { //If those prodConfig id satisfies the value of Agreement object and Record type = Consumption
                    if (Offering.equals('Machines') || CategoryHierachy.equals('Concepts | Coffee Kitchen')) {
                        oLineItem.APTS_Unlimited_Machine_Ordering__c = true; //if the Category is as above, then make this field as true
                    }
                }
            }
            for (Apttus_Config2__LineItem__c oLineItem : allLineItemList) {
                //populate Bill To Line Item Fields
                if (!string.isBlank(Offering) && !string.isBlank(CategoryHierachy)) {
                    
                    if ((oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r != null && oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.APTS_Bill_to_Party_Ingredients__c != null &&                                 Offering != null && CategoryHierachy != null && productOptionGroup != null)) {
                        
                        if (Offering.contains('&More') || Offering.contains('Tea') || Offering.contains('Coffee') || CategoryHierachy.contains('Concepts | Subscription')                                     || (CategoryHierachy.contains('Concepts | Coffee Kitchen') && productOptionGroup.contains('Ingredients')) || (Offering.contains('Machines') && productOptionGroup.contains('Ingredients'))) {
                            oLineItem.APTS_Bill_to_Party_Ingredients_and_Payer__c = oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.APTS_Bill_to_Party_Ingredients__c;
                            oLineItem.APTS_PayerIngredients__c = oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.APTS_Bill_to_Party_Ingredients__c;
                            
                        }
                        
                        if ((Offering.contains('Machines') && !productOptionGroup.contains('Ingredients')) || Offering.contains('Services') || Offering.contains('Spare Parts')                                     || (CategoryHierachy.contains('Concepts | Coffee Kitchen') && !productOptionGroup.contains('Ingredients')) || CategoryHierachy.contains('Concepts | Other')) {
                            oLineItem.APTS_Bill_to_Party_Machines_Services__c = oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.APTS_Bill_to_Party_MachServ__c;
                            oLineItem.APTS_PayerMachinesServices__c = oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.APTS_Bill_to_Party_MachServ__c;
                            
                        }
                    }
                    
                }                
                
            }
            
            for (Apttus_Config2.LineItem configLineItem : lineItemList) {
                Apttus_Config2__LineItem__c oLineItem = configLineItem.getLineItemSO();
                
                //for (Apttus_Config2__LineItem__c oLineItem : allLineItemList){
                if (oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.Apttus__Account__c != null) {
                    oLineItem.APTS_Sold_to_Party__c = oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.Apttus__Account__c ;
                }
                /*if (sFlow == NGSTANDARD_ORDER || sFlow == NGMACHINE_ORDER || sFlow == NGRSO_ORDER || sFlow == APTS_OrderConstants.NGSTANDARD_ORDERWOC || sFlow == APTS_OrderConstants.NGRSO_ORDERWOC) {
                system.debug('++++++'+oLineItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.Apttus_Config2__Label__c);
                system.debug('+++++'+oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.Apttus_Config2__OrderStartDate__c);
                system.debug('++++++'+oLineItem.APTS_Agreement_Line_Item__r.Apttus_CMConfig__AttributeValueId__r.APTS_Number_of_months__c);
                Date TempDate=oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.Apttus_Config2__OrderStartDate__c.addMonths(Integer.ValueOf(oLineItem.APTS_Agreement_Line_Item__r.Apttus_CMConfig__AttributeValueId__r.APTS_Number_of_months__c));
                system.debug('+++Shah++'+TempDate);

                 Integer TempContractTerm;
                 TempContractTerm=Integer.valueof(oLineItem.APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingTerm__c);
                if(oLineItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.Apttus_Config2__Label__c=='Technical Service'){
                system.debug('+++Shah++'+TempDate);
                oLineItem.Apttus_Config2__StartDate__c = TempDate;
                oLineItem.Apttus_Config2__SellingTerm__c=null;
                oLineItem.Apttus_Config2__EndDate__c = TempDate.addmonths(TempContractTerm);
                //oLineItem.Apttus_Config2__EndDate__c=null;

                //System.today().addmonths(7);
              }configLineItem.updatePrice();
            }*/
                
                 
            }           
            
        }
       
        //V104 ++ >>> Changes by Balashanthi starts
        // Below method will set Billing Key info fields on Line Item based on Billing setting record associated with agreement
        //APTS_BIRUtils.overrideBillingFieldsOnLineItem(allLineItemList,agreementBillingSettingMap);
        //APTS_BIRUtils.overrideBillingFieldsOnLineItem(allLineItemList);
        //V104 ++ >>> Changes by Balashanthi Ends
        
        //V107 ++ <<Technical Swap, add LSP Details from Old Asset Line Item, merge this code with BIR Utils overrideBillingFieldsOnLineItem method
        
        
        for (Apttus_Config2__LineItem__c oLineItem : allLineItemList) {
            if (oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__BusinessObjectType__c == 'Order' && oLineItem.Apttus_Config2__IsPrimaryLine__c == TRUE &&                   oLineItem.Apttus_Config2__OptionId__c == null &&                    oLineItem.Apttus_Config2__AssetLineItemId__c != null &&                     oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__c != null &&                  oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c == 'Technical Swap') {
                oLineItem.APTS_Order_LSP_Detail__c = oLineItem.Apttus_Config2__AssetLineItemId__r.APTS_Order_LSP_Detail__c;break;
            }
        }
        if (mode == Apttus_Config2.CustomClass.PricingMode.ADJUSTMENT) { 
        
        //DQ-56 Serial Number and termination AssetLine Look up copy 
        for (Apttus_Config2__LineItem__c oLineItem : allLineItemList) {
        if((oLineItem.Apttus_Config2__ConfigurationId__c!= null && oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__c!=null &&  oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Contract_Change__c!= null && oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Contract_Change__c.equalsIgnoreCase('Yes') && mapNewLines != null && mapCancelledLines!=null && mapNewLines.size()>0 && mapCancelledLines.size()>0))
        PrimaryLineSwapforContractChange(mapNewLines,mapCancelledLines);
        }

          /*if (sFlow == NGSTANDARD_ORDER || sFlow == NGMACHINE_ORDER || sFlow == NGRSO_ORDER || sFlow == APTS_OrderConstants.NGSTANDARD_ORDERWOC || sFlow == APTS_OrderConstants.NGRSO_ORDERWOC) {
                for (Apttus_Config2.LineItem configLineItem : LineItemList) {
                Apttus_Config2__LineItem__c oLineItem = configLineItem.getLineItemSO();
              if(oLineItem.APTS_Agreement_Line_Item__r.APTS_Type_of_Contract__c=='Sales'&&oLineItem.APTS_Agreement_Line_Item__r.APTS_Option_Group_Text__c=='Technical Service'&&
              oLineItem.APTS_Agreement_Line_Item__r.Apttus_CMConfig__AttributeValueId__r.APTS_Number_of_months__c!=null){
              oLineItem.Apttus_Config2__StartDate__c=oLineItem.Apttus_Config2__StartDate__c.addMonths(Integer.ValueOf(oLineItem.APTS_Agreement_Line_Item__r.Apttus_CMConfig__AttributeValueId__r.APTS_Number_of_months__c)).adddays(-1);
              oLineItem.Apttus_Config2__EndDate__c=null;
              oLineItem.Apttus_Config2__SellingTerm__c=oLineItem.APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingTerm__c;
              oLineItem.Apttus_Config2__PricingStatus__c  = 'Pending';
            }
            configLineItem.updatePrice();
            }
      
          }*/
            for (Apttus_Config2__LineItem__c oLineItem : allLineItemList) {
              if(oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__BusinessObjectType__c==APTS_CPQConstants.LABEL_AGREEEMENT || (oLineItem.Apttus_Config2__AssetLineItemId__c==null&&oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__BusinessObjectType__c == APTS_CPQConstants.LABEL_ORDER&&oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c==CONVERSIONORDER)){
                String CTTOC=oLineItem.APTS_Type_of_Contract__c+';'+oLineItem.Apttus_Config2__ChargeType__c;
                
                    if(CTTOC!=''&&(!oLineItem.APTS_Default_Billing_Frequency__c || (olineItem.APTS_Type_of_Contract__c != oLineItem.APTS_old_toc__c&&oLineItem.APTS_Default_Billing_Frequency__c))&&oLineItem.APTS_Type_of_Contract__c=='Consumption'&&oLineItem.Apttus_Config2__ChargeType__c=='Additional Service Fee')
                    { 
                        APTS_Billing_Frequency__c BF1=APTS_Billing_Frequency__c.getvalues('Consumption;Additional Service');
                        if(BF1!=null){oLineItem.Apttus_Config2__BillingFrequency__c=BF1.APTS_Biiling_Frequency__c;oLineItem.APTS_Default_Billing_Frequency__c=true;}
                    }
                    else if(CTTOC!=''&&(!oLineItem.APTS_Default_Billing_Frequency__c || (olineItem.APTS_Type_of_Contract__c != oLineItem.APTS_old_toc__c&&oLineItem.APTS_Default_Billing_Frequency__c)))
                    {
                        APTS_Billing_Frequency__c BF=APTS_Billing_Frequency__c.getvalues(CTTOC);
                        if(BF!=null){oLineItem.Apttus_Config2__BillingFrequency__c=BF.APTS_Biiling_Frequency__c;oLineItem.APTS_Default_Billing_Frequency__c=true;}
                    }
                oLineItem.APTS_old_toc__c = oLineItem.APTS_Type_of_Contract__c;        
              }    
              //<<V131++
              if(oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__BusinessObjectType__c == APTS_CPQConstants.LABEL_ORDER  
                   && oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c==APTS_BIRUtils.CREDITSAPORDERTYPE ){
                oLineItem.Apttus_Config2__BillingFrequency__c=APTS_BIRUtils.ONETIME ;
              }     
                //CSP based list price
                /*if(oLineItem.Apttus_Config2__PriceListItemId__r.APTS_Master_list_price__c!=null){-- Commenting for moving to dsg1 purpose 
oLineItem.APTS_List_price__c=oLineItem.Apttus_Config2__PriceListItemId__r.APTS_Master_list_price__c;
}*/
                //custom pricing logic for coverage products (All in coverage & Basic coverage)  
                if(oLineItem.Apttus_Config2__OptionId__c!=null && ((oLineItem.Apttus_Config2__PriceListItemId__r.APTS_Call_Out_Coverage__c!=null && oLineItem.Apttus_Config2__PriceListItemId__r.APTS_Call_Out_Coverage__c!=0) || (oLineItem.Apttus_Config2__PriceListItemId__r.APTS_Labour_Coverage__c!=null && oLineItem.Apttus_Config2__PriceListItemId__r.APTS_Labour_Coverage__c!=0) || (oLineItem.Apttus_Config2__PriceListItemId__r.APTS_Spare_Parts_Coverage__c!=null && oLineItem.Apttus_Config2__PriceListItemId__r.APTS_Spare_Parts_Coverage__c!=0))){
                    bundleCoverageSet.add(oLineItem.Apttus_Config2__ProductId__c);
                }
                if(olineItem.Apttus_Config2__LineStatus__c!=null && olineItem.Apttus_Config2__LineStatus__c.equalsIgnoreCase('New') && oLineItem.Apttus_Config2__OptionId__c!=null && (oLineItem.Apttus_Config2__OptionId__r.Name.equals(system.label.APTS_All_in_Coverage_Draft) || oLineItem.Apttus_Config2__OptionId__r.Name.equals(system.label.APTS_Basic_Coverage_Draft))){
                    if (oLineItem.Apttus_Config2__AttributeValueId__r.APTS_Call_Out_Coverage_chk__c  != null &&
                        oLineItem.Apttus_Config2__AttributeValueId__r.APTS_Call_Out_Coverage_chk__c.equals('Yes')) {
                            if(hasCOCMap.get(oLineItem.Apttus_Config2__ProductId__c+String.valueOf(oLineItem.Apttus_Config2__ParentBundleNumber__c))==null){
                                hasCOCMap.put(oLineItem.Apttus_Config2__ProductId__c+String.valueOf(oLineItem.Apttus_Config2__ParentBundleNumber__c),true);
                            }
                        }
                    if (oLineItem.Apttus_Config2__AttributeValueId__r.APTS_Labour_Coverage_chk__c != null &&
                        oLineItem.Apttus_Config2__AttributeValueId__r.APTS_Labour_Coverage_chk__c.equals('Yes')) {
                            if(hasLCMap.get(oLineItem.Apttus_Config2__ProductId__c+String.valueOf(oLineItem.Apttus_Config2__ParentBundleNumber__c))==null){
                                hasLCMap.put(oLineItem.Apttus_Config2__ProductId__c+String.valueOf(oLineItem.Apttus_Config2__ParentBundleNumber__c),true);
                            }
                        }
                    
                    if (oLineItem.Apttus_Config2__AttributeValueId__r.APTS_Spare_Parts_Coverage_chk__c != null &&
                        oLineItem.Apttus_Config2__AttributeValueId__r.APTS_Spare_Parts_Coverage_chk__c.equals('Yes') ) {
                        if(hasSPCMap.get(oLineItem.Apttus_Config2__ProductId__c+String.valueOf(oLineItem.Apttus_Config2__ParentBundleNumber__c))==null){
                            hasSPCMap.put(oLineItem.Apttus_Config2__ProductId__c+String.valueOf(oLineItem.Apttus_Config2__ParentBundleNumber__c),true);
                        }
                    }
                }
                //Capture all maps needed - Karan | CR - 2172
                populateAllAmmendmentMaps(oLineItem,bundleWarrentyMap,mapConditionAmend,mapAmendDate,mapAssetEndDate);
                if(oLineItem.Apttus_Config2__ChargeType__c!=null && 
                    oLineItem.Apttus_Config2__ProductId__c!=null && 
                    oLineItem.Apttus_Config2__HasOptions__c && 
                    oLineItem.Apttus_Config2__AssetLineItemId__c!=null && 
                    oLineItem.Apttus_Config2__IsPrimaryLine__c &&
                    oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__c!=null && 
                    oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Sub_Type__c!=null &&  
                    oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Sub_Type__c.equalsIgnoreCase('Add/Remove Options')){  
                    if(primaryLineAssetMap.get(oLineItem.Apttus_Config2__ProductId__c+String.valueOf(oLineItem.Apttus_Config2__LineNumber__c))==null){
                      primaryLineAssetMap.put(oLineItem.Apttus_Config2__ProductId__c+String.valueOf(oLineItem.Apttus_Config2__LineNumber__c),oLineItem.Apttus_Config2__AssetLineItemId__r);
                    }
                }
            }
            for (Apttus_Config2__LineItem__c oLineItem : allLineItemList) {
                if (oLineItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__ParentOptionGroupId__r.Apttus_Config2__Label__c != null && oLineItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__ParentOptionGroupId__r.Apttus_Config2__Label__c.equals(system.label.APTS_Machines) && bundleCoverageSet.contains(oLineItem.Apttus_Config2__ProductId__c) && oLineItem.Apttus_Config2__PriceListItemId__c != null) {
                    if (!hasCOCMap.isEmpty() && hasCOCMap.get(oLineItem.Apttus_Config2__ProductId__c+String.valueOf(oLineItem.Apttus_Config2__ParentBundleNumber__c))!=null) {
                        if (oLineItem.Apttus_Config2__PriceListItemId__r.APTS_Call_Out_Coverage__c != null) {
                            coverageSum += oLineItem.Apttus_Config2__PriceListItemId__r.APTS_Call_Out_Coverage__c;
                            calloutcoveragesum += oLineItem.Apttus_Config2__PriceListItemId__r.APTS_Call_Out_Coverage__c;
                        }
                    }
                    if (!hasLCMap.isEmpty() && hasLCMap.get(oLineItem.Apttus_Config2__ProductId__c+String.valueOf(oLineItem.Apttus_Config2__ParentBundleNumber__c))!=null) {
                        if (oLineItem.Apttus_Config2__PriceListItemId__r.APTS_Labour_Coverage__c != null) {
                            coverageSum += oLineItem.Apttus_Config2__PriceListItemId__r.APTS_Labour_Coverage__c;
                            labourcoveragesum += oLineItem.Apttus_Config2__PriceListItemId__r.APTS_Labour_Coverage__c;
                        }
                    }
                    if (!hasSPCMap.isEmpty() && hasSPCMap.get(oLineItem.Apttus_Config2__ProductId__c+String.valueOf(oLineItem.Apttus_Config2__ParentBundleNumber__c))!=null) {
                        if (oLineItem.Apttus_Config2__PriceListItemId__r.APTS_Spare_Parts_Coverage__c != null) {
                            coverageSum += oLineItem.Apttus_Config2__PriceListItemId__r.APTS_Spare_Parts_Coverage__c;
                            sparepartscoveragesum += oLineItem.Apttus_Config2__PriceListItemId__r.APTS_Spare_Parts_Coverage__c;
                        }
                    }
                }
                //Total coverge calculation | COC + LCC + SPC
                if(totalCoverageMap.get(oLineItem.Apttus_Config2__ProductId__c+String.valueOf(oLineItem.Apttus_Config2__ParentBundleNumber__c))==null){
                    totalCoverageMap.put(oLineItem.Apttus_Config2__ProductId__c+String.valueOf(oLineItem.Apttus_Config2__ParentBundleNumber__c),coverageSum+';'+labourcoveragesum+';'+sparepartscoveragesum+';'+calloutcoveragesum);
                }else{
                    totalCoverageMap.remove(oLineItem.Apttus_Config2__ProductId__c+String.valueOf(oLineItem.Apttus_Config2__ParentBundleNumber__c));
                    totalCoverageMap.put(oLineItem.Apttus_Config2__ProductId__c+String.valueOf(oLineItem.Apttus_Config2__ParentBundleNumber__c),coverageSum+';'+labourcoveragesum+';'+sparepartscoveragesum+';'+calloutcoveragesum);
                }
                //Added by Karan | Freight charges
                if(oLineItem.Apttus_Config2__LineType__c==APTS_CPQConstants.PROD_SERV_LABEL && !oLineItem.Apttus_Config2__ProductId__r.name.equalsIgnoreCase(System.Label.APTS_FREIGHT_CHARGES_PRODUCT_NAME)){
                    netPriceRollup += oLineItem.Apttus_Config2__NetPrice__c;
                }
            }
            for (Apttus_Config2.LineItem configLineItem : lineItemList) {
                Apttus_Config2__LineItem__c oLineItem = configLineItem.getLineItemSO();
                if (!totalCoverageMap.isEmpty() && totalCoverageMap.get(oLineItem.Apttus_Config2__ProductId__c+String.valueOf(oLineItem.Apttus_Config2__ParentBundleNumber__c))!=null && system.label.APTS_Service_Fee.equals(oLineItem.Apttus_Config2__ChargeType__c) && (oLineItem.Apttus_Config2__OptionId__c != null && (oLineItem.Apttus_Config2__OptionId__r.Name.equals(system.label.APTS_All_in_Coverage_Draft) || oLineItem.Apttus_Config2__OptionId__r.Name.equals(system.label.APTS_Basic_Coverage_Draft)))){   
                    List<String> coverageValueList = totalCoverageMap.get(oLineItem.Apttus_Config2__ProductId__c+String.valueOf(oLineItem.Apttus_Config2__ParentBundleNumber__c)).split(';');
                    if(!coverageValueList.isEmpty() && coverageValueList[0]!=null){
                        oLineItem.Apttus_Config2__BasePrice__c= Decimal.valueof(coverageValueList[0]);
                    }
                    if(!coverageValueList.isEmpty() && coverageValueList[1]!=null){
                        oLineItem.APTS_Cumulative_Labour_coverage__c = Decimal.valueof(coverageValueList[1]);
                    }
                    if(!coverageValueList.isEmpty() && coverageValueList[2]!=null){
                        oLineItem.APTS_Cumulative_Spare_Parts_Coverage__c = Decimal.valueof(coverageValueList[2]);
                    }
                    if(!coverageValueList.isEmpty() && coverageValueList[3]!=null){
                        oLineItem.APTS_Cumulative_Call_Out_Coverage__c = Decimal.valueof(coverageValueList[3]);
                    }
                    configLineItem.updatePrice();
                }
                
                if(oLineItem.Apttus_Config2__AssetLineItemId__c!=null){ 
                /*system.debug('Came inside asset loop');
                system.debug('Came inside asset loop'+oLineItem.Apttus_Config2__AssetLineItemId__r.APTS_BasePriceOverride__c);
                system.debug('Came inside asset loop'+oLineItem.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__BasePrice__c);*/
                //v133 <--- Restore the auto-renew flag on renewal more than once
                oLineItem.APTS_Original_start_date__c = oLineItem.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__OriginalStartDate__c;
                if(oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Auto_renewal_staging_source_id__c!=null ||
                (oLineItem.Apttus_Config2__ConfigurationId__c!=null && 
                oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__c!=null && 
                oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Sub_Type__c!=null)){
                    oLineItem.Apttus_Config2__AutoRenew__c=oLineItem.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__AutoRenew__c;
                }
                //v133 --->
                if(oLineItem.Apttus_Config2__LineType__c == 'Option'){
                    if(oLineItem.Apttus_Config2__AssetLineItemId__r.APTS_BasePriceOverride__c!=null && !oLineItem.APTS_is_Indexation_skip__c){
                      if(oLineItem.Apttus_Config2__LineStatus__c=='Renewed'){
                          oLineItem.Apttus_Config2__BasePriceOverride__c = oLineItem.Apttus_Config2__AssetLineItemId__r.APTS_BasePriceOverride__c;
                          //oLineItem.Apttus_Config2__AutoRenew__c=oLineItem.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__AutoRenew__c;
                      }
                      if(oLineItem.Apttus_Config2__LineStatus__c!='Renewed' && !oLineItem.APTS_is_BPO_defaulted_Amendment__c){
                          oLineItem.APTS_is_BPO_defaulted_Amendment__c=true;
                          //oLineItem.Apttus_Config2__AutoRenew__c=oLineItem.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__AutoRenew__c;
                          oLineItem.Apttus_Config2__BasePriceOverride__c = oLineItem.Apttus_Config2__AssetLineItemId__r.APTS_BasePriceOverride__c;
                      }
                    }
                    if(oLineItem.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__BasePrice__c!=null){
                        oLineItem.Apttus_Config2__ListPrice__c = oLineItem.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__ListPrice__c;
                        oLineItem.Apttus_Config2__BasePrice__c= oLineItem.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__BasePrice__c;
                    }
                 }
                 if(oLineItem.Apttus_Config2__ConfigurationId__c!=null &&
                    oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__c!=null && 
                    oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Type__c=='Admin Order' && 
                    oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c=='Renewal'){
                        oLineItem.Apttus_Config2__SellingTerm__c=null;
                 }
                    configLineItem.updatePrice();
                }
                //Added by Karan | Freight charges
                if(oLineItem.Apttus_Config2__ProductId__c!=null && oLineItem.Apttus_Config2__ProductId__r.name.equalsIgnoreCase(System.Label.APTS_FREIGHT_CHARGES_PRODUCT_NAME) && oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__BusinessObjectType__c == APTS_CPQConstants.LABEL_ORDER){
                    frieghtChargesList.add(configLineItem);
                }
                // Added as part for Tax CR | on reprice, initialize all tax values to 0 and is tax calculate flag to false
                if (oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__BusinessObjectType__c == APTS_CPQConstants.LABEL_AGREEEMENT && oLineItem.APTS_is_Tax_and_VAT_calculated__c) {
                    oLineItem.APTS_Additional_charges__c = null;
                    oLineItem.APTS_Tax__c = null;
                    oLineItem.APTS_VAT__c = null;
                    oLineItem.APTS_VAT_classifier_0__c = null;
                    oLineItem.APTS_VAT_classifier_1__c = null;
                    oLineItem.APTS_VAT_classifier_2__c = null;
                    oLineItem.APTS_VAT_classifier_3__c = null;
                    oLineItem.APTS_VAT_classifier_4__c = null;
                    oLineItem.APTS_VAT_classifier_5__c = null;
                    oLineItem.APTS_VAT_classifier_6__c = null;
                    oLineItem.APTS_Net_Price_Inc_taxes__c = null;
                    oLineItem.APTS_is_Tax_and_VAT_calculated__c = false;
                }
                //Execute all Date logic - Karan | CR - 2172
                
                if(oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__BusinessObjectType__c==APTS_CPQConstants.LABEL_AGREEEMENT && oLineItem.Apttus_Config2__LineStatus__c=='New')
                {
                    dateCalculationLogic(oLineItem,bundleWarrentyMap,mapConditionAmend,mapAmendDate,mapAssetEndDate);
                    if(pendingLineItemMap.isEmpty()  || (!pendingLineItemMap.isEmpty() && pendingLineItemMap.get(oLineItem.id)!=null && !pendingLineItemMap.get(oLineItem.id))){
                     configLineItem.updatePrice();
                  }
                }
                //Code Added for ABO CR - 2288 by Sofiya
                if(oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__BusinessObjectType__c==APTS_CPQConstants.LABEL_ORDER && oLineItem.Apttus_Config2__LineStatus__c=='New' && oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Type__c == 'Admin Order' && sFlow == NGADMIN_ORDER){
                    dateCalculationLogicforOrders(oLineItem,bundleWarrentyMap,mapConditionAmend,mapAmendDate,mapAssetEndDate);
                    //v124
                    if(oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Contract_Change__c!= null && oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Contract_Change__c.equalsIgnoreCase('yes') && olineItem.Apttus_Config2__PriceType__c.equalsIgnoreCase('One Time')){
                        olineitem.Apttus_Config2__EndDate__c = olineitem.Apttus_Config2__StartDate__c.addmonths(1).addDays(-1);
                    }
                  
                    if(pendingLineItemMap.isEmpty()  || (!pendingLineItemMap.isEmpty() && pendingLineItemMap.get(oLineItem.id)!=null && !pendingLineItemMap.get(oLineItem.id))){
                     configLineItem.updatePrice();
                  }
               }
                
                 //Code Added for ABO CR - 2288 by Sofiya
               //DQ-2541 | 17-June-20 | Apttus workaround for Delta amount at last (Needs to be removed post Patch is provided) -START
              if(oLineItem.Apttus_Config2__LineType__c.equalsIgnoreCase('Option') && oLineItem.Apttus_Config2__LineStatus__c.equalsIgnoreCase('Existing') && oLineItem.Apttus_Config2__AssetLineItemId__c!=null && oLineItem.Apttus_Config2__NetPrice__c!= oLineItem.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__NetPrice__c){
                  oLineItem.Apttus_Config2__LineStatus__c='Amended'; 
               }
              if(oLineItem.Apttus_Config2__LineType__c.equalsIgnoreCase('Option') && 
               oLineItem.Apttus_Config2__LineStatus__c!=null && 
               oLineItem.Apttus_Config2__LineStatus__c.equalsIgnoreCase('New') &&  
               oLineItem.Apttus_Config2__ConfigurationId__c!=null && 
               oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__c!=null && 
               oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Sub_Type__c!=null &&  
               oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Sub_Type__c.equalsIgnoreCase('Add/Remove Options')){
                    if(!primaryLineAssetMap.isEmpty() 
                    && oLineItem.Apttus_Config2__ProductId__c!=null 
                    && oLineItem.Apttus_Config2__ChargeType__c!=null 
                    && primaryLineAssetMap.get(oLineItem.Apttus_Config2__ProductId__c+String.valueOf(oLineItem.Apttus_Config2__LineNumber__c))!=null){
                        olineItem.Apttus_Config2__LocationId__c=primaryLineAssetMap.get(oLineItem.Apttus_Config2__ProductId__c+String.valueOf(oLineItem.Apttus_Config2__LineNumber__c)).Apttus_Config2__LocationId__c;
                    }
                    olineItem.Apttus_Config2__BillingFrequency__c=olineItem.APTS_Billing_frequency_New_UX__c;
                    olineItem.Apttus_Config2__StartDate__c=olineItem.APTS_Start_Date_New_UX__c;
                    olineItem.Apttus_Config2__EndDate__c=olineItem.APTS_End_Date_New_UX__c;
                    olineItem.Apttus_Config2__AutoRenew__c=olineItem.APTS_Auto_renew_New_UX__c;
                    if(olineItem.Apttus_Config2__ChargeType__c.equalsIgnorecase('Rental Fee')){
                        olineItem.Apttus_Config2__ListPrice__c=olineItem.APTS_List_Price_New_UX__c;
                        olineItem.Apttus_Config2__BasePrice__c=olineItem.APTS_List_Price_New_UX__c;
                    }
                    olineItem.Apttus_Config2__SellingTerm__c=null;
                    
                    
                    configLineItem.updatePrice();
               }
               
                 if(oLineItem.APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingTerm__c != null &&   oLineItem.APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingTerm__c != 0)
            {
                //v122
                //oLineItem.Apttus_Config2__EndDate__c = oLineItem.Apttus_Config2__StartDate__c.addMonths(Integer.ValueOf(oLineItem.APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingTerm__c)).adddays(-1);            
                //oLineItem.Apttus_Config2__SellingTerm__c = oLineItem.APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingTerm__c;
                //v123 ++ <<
                if(oLineItem.APTS_Agreement_Line_Item__r != null && oLineItem.APTS_Agreement_Line_Item__r.Apttus__AgreementId__c != null)
                {
                    //V128 ++ <<
                    if(oLineItem.APTS_Agreement_Line_Item__r.Apttus__AgreementId__r.Apttus__Subtype__c == 'Fixed End date')
                    {
                        oLineItem.Apttus_Config2__EndDate__c = oLineItem.APTS_Agreement_Line_Item__r.Apttus_CMConfig__EndDate__c;  
                       // oLineItem.Apttus_Config2__PricingStatus__c  = 'Pending';          
                    }
                    else{
                        oLineItem.Apttus_Config2__SellingTerm__c = oLineItem.APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingTerm__c;
                        if(oLineItem.Apttus_Config2__LineType__c!='Product/Service'){
                        oLineItem.Apttus_Config2__EndDate__c = oLineItem.Apttus_Config2__StartDate__c.addMonths(Integer.ValueOf(oLineItem.APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingTerm__c)).adddays(-1);}
                    } //V128 ++ >>
                    // DFT2C-1548 fixes - start
                    oLineItem.Apttus_Config2__AutoRenew__c = oLineItem.APTS_Agreement_Line_Item__r.Apttus_CMConfig__AutoRenew__c;
                    configLineItem.updatePrice();
                    // DFT2C-1548 fixes - end
                }       
                //v123 ++ >>
            }
              
               //DQ-2541 | 17-June-20 | Apttus workaround for Delta amount at last (Needs to be removed post Patch is provided) - END
            }     
        }
    //v127++<<
    //} 
    //v127++>>
    }
    
    global void afterPricingLineItem(Apttus_Config2.ProductConfiguration.LineItemColl itemColl, Apttus_Config2.LineItem lineItemMO) {
      
    List<Apttus_Config2.LineItem> lineItemList = itemColl.getAllLineItems();
    List<Apttus_Config2__LineItem__c> allLineItemList = getLineItems(lineItemList);
    for (Apttus_Config2__LineItem__c oLineItem : allLineItemList) {
    if(oLineItem.Apttus_Config2__LineStatus__c==Cancelled)
    mapCancelledLines.put(oLineItem.id,oLineItem);
    else if(oLineItem.Apttus_Config2__LineStatus__c==STR_NEW)
    mapNewLines.put(oLineItem.id,oLineItem);
    }
        
    }    
    
    global void finish() {
        //Added by Karan | Freight charges
    //v127++<<
        if(!frieghtChargesList.isEmpty()){
    //v127++>>
            List<APTS_Freight_Charge_Details__c> lstFreightChargeDetails = APTS_Freight_Charge_Details__c.getall().values();//V140 ++ <<>>
            for (Apttus_Config2.LineItem configLineItem : frieghtChargesList) {
                Apttus_Config2__LineItem__c oLineItem = configLineItem.getLineItemSO();
                if(netPriceRollup > oLineItem.Apttus_Config2__ConfigurationId__r.APTS_Threshold__c){
                    oLineItem.Apttus_Config2__BasePrice__c=0;
                }else{
                    boolean bSpecificLPO = (oLineItem.Apttus_Config2__PriceListId__c != null && oLineItem.Apttus_Config2__PriceListId__r.APTS_Region__c  == 'SAP_6712'); //V140 ++ <<>>
                    oLineItem.Apttus_Config2__BasePrice__c = (bSpecificLPO ? getFreightChargeLPO(lstFreightChargeDetails, netPriceRollup) : oLineItem.Apttus_Config2__ListPrice__c); //V140 ++ << Modified >>   
                }
                configLineItem.updatePrice();
            }
        }
    }
    //v102++<<
    private static List<Apttus_Config2__LineItem__c> getLineItems(List<Apttus_Config2.LineItem> allLineList) {
        
        List<Apttus_Config2__LineItem__c> lineItemList = new List<Apttus_Config2__LineItem__c>();
        for (Apttus_Config2.LineItem oLineItemMO : allLineList) {
            lineItemList.add(oLineItemMO.getLineItemSO());
        }
        
        return lineItemList;
    }
    
                    

    //Lavanya DATE LOGIC START | CR - 2172
    
    //Method Owner- Karan . Method Logic - Create reusable Maps used for Ammendment Start date and end date population(Technical services + other products) | CR - 2172
    public void populateAllAmmendmentMaps(Apttus_Config2__LineItem__c oLineItem,Map<String,Integer> bundleWarrentyMap,Map<Decimal,List<Id>> mapConditionAmend,Map<Decimal,Date> mapAmendDate,Map<String,Apttus_Config2__AssetLineItem__c> mapAssetEndDate){
        //Create Warrenty Bundle Map
        if(oLineItem.Apttus_Config2__HasOptions__c && oLineItem.Apttus_Config2__AttributeValueId__r.APTS_Number_of_months__c!=null){
            bundleWarrentyMap.put(oLineItem.Apttus_Config2__ProductId__c+String.valueOf(oLineItem.Apttus_Config2__PrimaryLineNumber__c),Integer.valueOf(oLineItem.Apttus_Config2__AttributeValueId__r.APTS_Number_of_months__c));
            
        } 
        //Populate Amend Condition Map
        if(oLineItem.Apttus_Config2__AssetLineItemId__c!=null){
            if(mapConditionAmend.get(oLineItem.Apttus_Config2__LineNumber__c)==null){
                mapConditionAmend.put(oLineItem.Apttus_Config2__LineNumber__c,new List<ID>{oLineItem.Apttus_Config2__AssetLineItemId__c});
            }else{
                mapConditionAmend.get(oLineItem.Apttus_Config2__LineNumber__c).add(oLineItem.Apttus_Config2__AssetLineItemId__c);
            }
        }
        if(oLineItem.Apttus_Config2__ChargeType__c!=null && oLineItem.Apttus_Config2__ProductId__c!=null && oLineItem.Apttus_Config2__HasOptions__c && oLineItem.Apttus_Config2__AssetLineItemId__c!=null){  
            if(mapAssetEndDate.get(oLineItem.Apttus_Config2__ProductId__c+oLineItem.Apttus_Config2__ChargeType__c+oLineItem.Apttus_Config2__LineNumber__c)==null){
              mapAssetEndDate.put(oLineItem.Apttus_Config2__ProductId__c+oLineItem.Apttus_Config2__ChargeType__c+oLineItem.Apttus_Config2__LineNumber__c,oLineItem.Apttus_Config2__AssetLineItemId__r);
            }
        } 
        //Populate Machine specific end date map
        if(oLineItem.Apttus_Config2__LineNumber__c!= NULL && oLineItem.Apttus_Config2__AssetLineItemId__c != NULL && oLineItem.Apttus_Config2__ProductOptionId__c != NULL) 
        {   
            //changing end date logic
            if(oLineItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.Apttus_Config2__Label__c.equalsIgnorecase('Machine')){  
                if(mapAmendDate.get(oLineItem.Apttus_Config2__LineNumber__c)==null){
                  mapAmendDate.put(oLineItem.Apttus_Config2__LineNumber__c,oLineItem.Apttus_Config2__EndDate__c);
                }
            } 
        } 
    } 
/* CR-2172- Method Owner - Lavanya- To calculate Dates for Amend, New, Renewal, Original Lineitem scenatio*/  
 public void dateCalculationLogic(Apttus_Config2__LineItem__c oLineItem,Map<String,Integer> bundleWarrentyMap,Map<Decimal,List<Id>> mapConditionAmend,Map<Decimal,Date> mapAmendDate,Map<String,Apttus_Config2__AssetLineItem__c> mapAssetEndDate)
    { 
     //Lavanya . Method Logic -- NEW LINE for NEW and Ammend Scenario
    if((oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.APTS_Agreement_Request__c == 'New' || oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.APTS_Agreement_Request__c == 'Amendment' || oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.APTS_Agreement_Request__c == 'Renewal') && oLineItem.Apttus_Config2__LineStatus__c=='New' && oLineItem.Apttus_Config2__AssetLineItemId__c==null && !oLineItem.APTS_Is_DateDefaulted_NewLI__c && oLineItem.Apttus_Config2__DerivedFromId__c == null && mapConditionAmend.isEmpty()){
       if(oLineItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.Apttus_Config2__Label__c!= null && oLineItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.Apttus_Config2__Label__c.equalsIgnorecase('Technical Service') && oLineItem.APTS_Type_of_Contract__c=='Sales'){
        if(!bundleWarrentyMap.isEmpty() && bundleWarrentyMap.get(oLineItem.Apttus_Config2__ProductId__c+String.valueOf(oLineItem.Apttus_Config2__ParentBundleNumber__c))!=null){             
          Integer warrenty = Integer.valueof(bundleWarrentyMap.get(oLineItem.Apttus_Config2__ProductId__c+String.valueOf(oLineItem.Apttus_Config2__ParentBundleNumber__c)));            
          oLineItem.Apttus_Config2__StartDate__c=oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.Apttus__Contract_Start_Date__c.addmonths(warrenty); 
          olineItem.APTS_Is_DateDefaulted_NewLI__c = true;   
        } else
            oLineItem.Apttus_Config2__StartDate__c=oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.Apttus__Contract_Start_Date__c;                     
        }
    else
    {
        oLineItem.Apttus_Config2__StartDate__c=oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.Apttus__Contract_Start_Date__c;            
        olineItem.APTS_Is_DateDefaulted_NewLI__c = true;
    }
     oLineItem.Apttus_Config2__EndDate__c=oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.Apttus__Contract_End_Date__c;
     oLineItem.Apttus_Config2__SellingTerm__c=null;  
    } 
  
        //Lavanya . Method Logic -Agreement Request Ammend Scenario Logic -- ORIGINAL LINE 
    
    if(oLineItem.Apttus_Config2__LineStatus__c=='New' && !oLineItem.APTS_Is_DateDefaulted_OriginalLI__c && oLineItem.Apttus_Config2__DerivedFromId__c != null && ((mapConditionAmend.isEmpty() && oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.APTS_Agreement_Request__c == 'Amendment') || (oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.APTS_Agreement_Request__c == 'Renewal'))){   
       oLineItem.Apttus_Config2__EndDate__c=oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.Apttus__Contract_End_Date__c;
        if(oLineItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.Apttus_Config2__Label__c!= null && oLineItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.Apttus_Config2__Label__c.equalsIgnorecase('Technical Service') && oLineItem.APTS_Type_of_Contract__c=='Sales'){
        if(!bundleWarrentyMap.isEmpty() && bundleWarrentyMap.get(oLineItem.Apttus_Config2__ProductId__c+String.valueOf(oLineItem.Apttus_Config2__ParentBundleNumber__c))!=null) {             
          Integer warrenty = Integer.valueof(bundleWarrentyMap.get(oLineItem.Apttus_Config2__ProductId__c+String.valueOf(oLineItem.Apttus_Config2__ParentBundleNumber__c)));                      
          oLineItem.Apttus_Config2__StartDate__c=oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.Apttus__Contract_Start_Date__c.addmonths(warrenty);          
          oLineItem.APTS_Is_DateDefaulted_OriginalLI__c = true;
        }else            
        oLineItem.Apttus_Config2__StartDate__c=oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.Apttus__Contract_Start_Date__c;
        }  
        else
           {
            oLineItem.Apttus_Config2__StartDate__c=oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.Apttus__Contract_Start_Date__c;
            oLineItem.APTS_Is_DateDefaulted_OriginalLI__c = true;
           }
        oLineItem.Apttus_Config2__SellingTerm__c=null;        
    }
   }
    
 //Code Added for ABO CR - 2288 by Sofiya   
 public void dateCalculationLogicforOrders(Apttus_Config2__LineItem__c oLineItem,Map<String,Integer> bundleWarrentyMap,Map<Decimal,List<Id>> mapConditionAmend,Map<Decimal,Date> mapAmendDate,Map<String,Apttus_Config2__AssetLineItem__c> mapAssetEndDate){
    //Lavanya . Method Logic -Order ABO Scenario Logic -- START DATE AND END DATE (MERGED)- Inclusion of DQ-56 Contract Change Logic
    
    if((oLineItem.Apttus_Config2__LineStatus__c=='New'  && mapConditionAmend.keySet().contains(oLineItem.Apttus_Config2__LineNumber__c) && oLineItem.Apttus_Config2__DerivedFromId__c == null && oLineItem.Apttus_Config2__LineType__c == 'Option') || (oLineItem.Apttus_Config2__LineStatus__c=='New' && oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Contract_Change__c!= null && oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Contract_Change__c.equalsIgnoreCase('Yes'))){
                
        if(!oLineItem.APTS_Is_DateDefaulted_AmendSD__c){ 
           if(oLineItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.Apttus_Config2__Label__c!= null
 && oLineItem.Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.Apttus_Config2__Label__c.equalsIgnorecase('Technical Service') 
 && oLineItem.APTS_Type_of_Contract__c=='Sales' && !bundleWarrentyMap.isEmpty() && bundleWarrentyMap.get(oLineItem.Apttus_Config2__ProductId__c+String.valueOf(oLineItem.Apttus_Config2__ParentBundleNumber__c))!=null
 && ((oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Type__c!= 'Admin Order' && sFlow!= NGADMIN_ORDER) || 
            (oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Contract_Change__c!= null && oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Contract_Change__c.equalsIgnoreCase('Yes'))))
            {
                Integer warrenty = Integer.valueof(bundleWarrentyMap.get(oLineItem.Apttus_Config2__ProductId__c+String.valueOf(oLineItem.Apttus_Config2__ParentBundleNumber__c)));   
                if (oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Contract_Change__c!= null && oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Contract_Change__c.equalsIgnoreCase('Yes'))
                 oLineItem.Apttus_Config2__StartDate__c =  oLineItem.Apttus_Config2__StartDate__c.addmonths(warrenty);   
                 else                        
                oLineItem.Apttus_Config2__StartDate__c = System.today().addmonths(warrenty); 
                            
            }
            else
            {
                 if (oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Contract_Change__c!= null && oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Contract_Change__c.equalsIgnoreCase('Yes'))
                 oLineItem.Apttus_Config2__StartDate__c =  oLineItem.Apttus_Config2__StartDate__c; 
                 else
                oLineItem.Apttus_Config2__StartDate__c = System.today();
               
            }
          oLineItem.Apttus_Config2__SellingTerm__c = null;
          oLineItem.APTS_Is_DateDefaulted_AmendSD__c=true;
        }
        if(!oLineItem.APTS_Is_DateDefaulted_AmendED__c && oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Contract_Change__c!= null && oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Contract_Change__c.equalsIgnoreCase('No')){
          /*if(!mapAmendDate.isEmpty() && mapAmendDate.get(oLineItem.Apttus_Config2__LineNumber__c) != NULL){                
            Date d = mapAmendDate.get(oLineItem.Apttus_Config2__LineNumber__c);   
            if(d!= NULL) {oLineItem.Apttus_Config2__EndDate__c= d;}
            oLineItem.APTS_Is_DateDefaulted_AmendED__c= true;
          }*/

          if(!mapAssetEndDate.isEmpty() 
          && oLineItem.Apttus_Config2__ProductId__c!=null 
          && oLineItem.Apttus_Config2__ChargeType__c!=null 
          && mapAssetEndDate.get(oLineItem.Apttus_Config2__ProductId__c+oLineItem.Apttus_Config2__ChargeType__c+oLineItem.Apttus_Config2__LineNumber__c)!=null){
            if(mapAssetEndDate.get(oLineItem.Apttus_Config2__ProductId__c+oLineItem.Apttus_Config2__ChargeType__c+oLineItem.Apttus_Config2__LineNumber__c).Apttus_Config2__EndDate__c!=null){
                oLineItem.Apttus_Config2__EndDate__c = mapAssetEndDate.get(oLineItem.Apttus_Config2__ProductId__c+oLineItem.Apttus_Config2__ChargeType__c+oLineItem.Apttus_Config2__LineNumber__c).Apttus_Config2__EndDate__c;   
            }
            if(mapAssetEndDate.get(oLineItem.Apttus_Config2__ProductId__c+oLineItem.Apttus_Config2__ChargeType__c+oLineItem.Apttus_Config2__LineNumber__c).Apttus_Config2__BillingPreferenceId__c!=null){
                oLineItem.Apttus_Config2__BillingPreferenceId__c = mapAssetEndDate.get(oLineItem.Apttus_Config2__ProductId__c+oLineItem.Apttus_Config2__ChargeType__c+oLineItem.Apttus_Config2__LineNumber__c).Apttus_Config2__BillingPreferenceId__c;
            }
            if(mapAssetEndDate.get(oLineItem.Apttus_Config2__ProductId__c+oLineItem.Apttus_Config2__ChargeType__c+oLineItem.Apttus_Config2__LineNumber__c).APTS_Payment_Method__c!=null){
                oLineItem.APTS_Payment_Method__c = mapAssetEndDate.get(oLineItem.Apttus_Config2__ProductId__c+oLineItem.Apttus_Config2__ChargeType__c+oLineItem.Apttus_Config2__LineNumber__c).APTS_Payment_Method__c;
            }
            if(mapAssetEndDate.get(oLineItem.Apttus_Config2__ProductId__c+oLineItem.Apttus_Config2__ChargeType__c+oLineItem.Apttus_Config2__LineNumber__c).Apttus_Config2__PaymentTermId__c!=null){
                oLineItem.Apttus_Config2__PaymentTermId__c = mapAssetEndDate.get(oLineItem.Apttus_Config2__ProductId__c+oLineItem.Apttus_Config2__ChargeType__c+oLineItem.Apttus_Config2__LineNumber__c).Apttus_Config2__PaymentTermId__c;
            }
            oLineItem.APTS_Is_DateDefaulted_AmendED__c= true;
          } 
        }
    }
    
    }
    
    /* DQ-56 Contract change Serial Number and Old AssetLine Copy Logic - Primary Line Swapping based on Contract change */   
    public void PrimaryLineSwapforContractChange(Map<Id,Apttus_Config2__LineItem__c> mapNewLines, Map<Id,Apttus_Config2__LineItem__c> mapCancelledLines){
     for(Apttus_Config2__LineItem__c l : mapNewLines.values()){ //New Lines
    for(Apttus_Config2__LineItem__c ali : mapCancelledLines.values()){ //Cancelled Lines
    //Master Primary Line Swapping Logic 
    
   
    if(l.Apttus_Config2__LineType__c!=OPTION && ali.Apttus_Config2__LineType__c!=OPTION &&  l.Apttus_Config2__ProductId__c==ali.Apttus_Config2__ProductId__c)
    { 
    if(ali.APTS_PrimaryL1__c==true && l.APTS_PrimaryL1__c==true)
    {
    l.APTS_Terminated_Asset_Line__c = ali.Apttus_Config2__AssetLineItemId__c; 
    l.APTS_Serial_Number2__c = ali.APTS_Serial_Number__c;
    }
    
    } 
    
    if(l.Apttus_Config2__LineType__c==OPTION && ali.Apttus_Config2__LineType__c==OPTION && l.Apttus_Config2__ProductOptionId__c==ali.Apttus_Config2__ProductOptionId__c &&  l.Apttus_Config2__ProductId__c==ali.Apttus_Config2__ProductId__c)
    {
    l.APTS_Terminated_Asset_Line__c= ali.Apttus_Config2__AssetLineItemId__c; 
   /* if(l.Apttus_Config2__OptionId__r.APTS_Option_Group_Indicator__c == MenuOption && ali.Apttus_Config2__OptionId__r.APTS_Option_Group_Indicator__c == MenuOption)
    l.APTS_Serial_Number2__c = ali.APTS_Serial_Number__c;
    if(l.Apttus_Config2__OptionId__r.APTS_Option_Group_Indicator__c == ConnectivitySystem && ali.Apttus_Config2__OptionId__r.APTS_Option_Group_Indicator__c == ConnectivitySystem)
    l.APTS_Serial_Number2__c = ali.APTS_Serial_Number__c;*/
    if(ali.APTS_Serial_Number__c!= null)
    l.APTS_Serial_Number2__c = ali.APTS_Serial_Number__c;    
    }   
    if(l.Apttus_Config2__LineType__c!=OPTION && ali.Apttus_Config2__LineType__c!=OPTION &&  l.Apttus_Config2__ProductId__c==ali.Apttus_Config2__ProductId__c && l.APTS_PrimaryL1__c!=true && ali.APTS_PrimaryL1__c != true && ali.Apttus_Config2__ChargeType__c==l.Apttus_Config2__ChargeType__c)
    {l.APTS_Terminated_Asset_Line__c= ali.Apttus_Config2__AssetLineItemId__c;}                                          
          
    }
    }
    
    }
    //V140 ++ <<
    Public Decimal getFreightChargeLPO(List< APTS_Freight_Charge_Details__c> lstFreightChargeDetails, Decimal netPriceRollup){
        Decimal oListPriceOverride = 0;
        if(!lstFreightChargeDetails.isEmpty())
        {
            for(APTS_Freight_Charge_Details__c oFreightCharge : lstFreightChargeDetails){
                if(oFreightCharge.APTS_IsActive__c)
                {
                    Decimal fromPriceRange = (oFreightCharge.APTS_Range_From__c == 0) ? oFreightCharge.APTS_Range_From__c : oFreightCharge.APTS_Range_From__c + APTS_OrderConstants.ROUNDOFF_RANGE_FROM_VALUE;
                    Decimal toPriceRange = oFreightCharge.APTS_Range_To__c + APTS_OrderConstants.ROUNDOFF_RANGE_TO_VALUE;
                    if(netPriceRollup < toPriceRange && netPriceRollup > fromPriceRange )
                    {
                        oListPriceOverride = oFreightCharge.APTS_ListPriceOverride__c;
                        break;
                    } 
                }                             
            }
        }
        return oListPriceOverride;
    }
    //V140 ++ >>  
}