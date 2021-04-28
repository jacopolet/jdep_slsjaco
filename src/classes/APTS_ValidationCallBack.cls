/*************************************************************
@Name: APTS_ValidationCallBack
@Author: Galin Georgiev
@CreateDate: 31-01-2018
@Description: Validation of cart
@UsedBy: Finalize
******************************************************************/
//v100 31-01-2018 Galin Georgiev: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes
//v101 21-02-2018 Neev Shah: Page Action was skipped for test class
//v102 27-07-2018 Aarthi Pitchai: Order Bundle details related Validation
//v103 24-08-2018 Neev Shah: Optimization and Commrcial Swap
//v104 13-09-2018 Ariel Quesada: Tweaks to negative adjustments validations
//v105 26-10-2018 Karan Khatri:  Restrict to it reprice before finalize cart. Done for seeing correct bundle rollups for all in coverage option
//v106 14-01-2019 Jaya Keerthana: End date should be greater than start date
//v107 14-03-2019 Nikita Modi: End date should be greater than start date : Excluding this for Movement Order XA14
//v108 09-04-2019 Akanksha: Added condition to check cancelled line status or not for de-installation (ABO flow)
//v109 16-08-2019 Nikita: Added condition to check start date > end date for ALI ; QTCFLEX1-624
//v110 11-09-2019 Akanksha: QTCFLEX1-1214 Changed error to warning for tax calculation
//v111 18/12/2020 Lavanya - DQ-4499 - Modification of CER Adjustment Restriction
//v112 23/12/2020 Shahul- DQ-4719 - Block more than 100 % Discount
//v113 1/2/2021 Manisha - DQ-4874- Modification of check on OLI status instead of Order status for de-installation 

global with sharing class APTS_ValidationCallBack implements Apttus_Config2.CustomClass.IValidationCallback2 {
    private static final String NGSTANDARD_ORDER = System.Label.APTS_NGStandardOrder;
    private static final String CERChangeLabel1 = 'CER Adjustments have been modified for Product - ';
    private static final String CERChangeLabel2 = '. Kindly delete existing Adjustments for this Product, you will find CER adjustment to be automatically added';
    private static final String NGMACHINE_ORDER = System.Label.APTS_NGMachineOrder;
    private static final String NGDEFAULT = 'NGDefault';
    private static final String DISCLAIMER = System.Label.APTS_DiscountDisclaimer;
    private static final String ATP_NOT_DONE = System.Label.APTS_ATP_Not_Done;
    private static final String NOT_ENOUGH_QUANTITY = System.Label.APTS_Not_Enough_Quantity;
    private static final String FINALIZED = System.Label.APTS_Finalized;
    private static final String PAGEACTION = System.Label.APTS_pageAction;
    private static final String FINALIZE = System.Label.APTS_Finalize;
    private static final String PENDING = System.Label.APTS_Pending;
    private static final String DUPLICATESUBTYPE = 'LineItems cannot have Adjustments of same Type and SubType';
    private static final String EMPTYSUBTYPE = 'Adjustment Sub type is empty for ';
    private static final String BUNDLE_DETAILS_NOT_SET = 'Please fill up the Bundle details';
    private static final String PRODUCT_SERVICE = 'Product/Service';
    private static final String MACHINE_ORDER = 'Machine Order';
    private static final String LINE_STATUS_CANCEL = 'Cancelled';
    private static final String ADJUSTMENTTYPE_DIS_PER = '% Discount';
    private static final String ADJUSTMENTTYPE_DIS_AMNT = 'Discount Amount';
    private static final String ADJUSTMENTTYPE_MARK_PER = '% Markup';
    private static final String NG_MACHINE_SWAP_ORDER = 'NGMachineSwapOrder';
    private static final String DUP_SERIAL_NUM = 'Duplicate serial number found. Please review Serial Number2 on all Machine.';
    private static final String INVALID_SERIAL_NUM = ' Invalid Serial Number(s). Plesae provide existing serial number(s).';
    private static final String DIS_PER_100 = 'Discount % cannot be more than 100%. If you finalize this agreement, no adjustment line items will be created.';
    private static final String DISCOUNT_MORE_100 = System.Label.APTS_NegativeDiscount;
    private static final String DIS_AMNT_100 = 'Discount amount cannot be greater than the Net price. If you finalize this agreement, no adjustment line items will be created.';
    private static final String INFLATION_VALIDATION_MESSAGE = 'Inflation type of Adjustment Line Items cannot be modified!';
    private static final String END_START_DATE_MESSAGE ='End date cannot be earlier than Start date';
    private static final String ASSET_SUB_TYPE_INFLATION = 'ZP02';
    private static final String NOT_ALLOWED_IN_DEINSTALL = 'Renew/Amend Action is not allowed in De-installation cart.';
    private static final String DEINSTALLATION_ORDER = 'De-installation';
    private Boolean bIsPricePending = false;
    private String sFlow;
    private String sPageAction;
    private Date dtRequestedDelivaryDate;
    private Apttus_Config2__Order__c oOrder;

    /* Code to validate the products selected Loops through the shopping cart */
    global Apttus_Config2.CustomClass.ValidationResult validateCart(Apttus_Config2.ProductConfiguration cart) {
        //variable section ++ <<
        Boolean isFinalizePageAction = false;
        Integer iNumBundleLine = 0, iNumLSPDetails = 0;
        Set<String> setSerialNum2 = new Set<String>();
        Map<String, Decimal> coverageMap = new Map<String, Decimal>();
        //Map<Id, List<Apttus_Config2__AdjustmentLineItem__c>> mapLineItemAdjDisclaimer;
        Map<Id, Apttus_Config2__LineItem__c> mapLineItems = new Map<Id, Apttus_Config2__LineItem__c>();
        list<Apttus_Config2__AdjustmentLineItem__c> ListDisc = new list<Apttus_Config2__AdjustmentLineItem__c>();
        //variable section ++ >>

        //Initialization
        Map<Id, List<Apttus_Config2__AdjustmentLineItem__c>> mapLineItemAdjDisclaimer= new Map<Id, List<Apttus_Config2__AdjustmentLineItem__c>>();
        Apttus_Config2.CustomClass.validationResult result = new Apttus_Config2.CustomClass.ValidationResult(true);
        Apttus_Config2__ProductConfiguration__c oCart = cart.getConfigSO();
        List<Apttus_Config2.LineItem> allLines = cart.getLineItems();
        List<Apttus_Config2.ProductConfiguration.LineItemColl> allLines1 = cart.getLineItemCollsInCurrentBatch();
        
        
        Map<String, String> mapValues = Apttus_Config2.RuntimeContext.getParameters();
        sPageAction = mapValues.get(PAGEACTION);
        sFlow = oCart.APTS_Flow__c;
        Set<ID> assetLineItemIDSet = new Set<ID>();
        Set<ID> primaryLineBundleAssetIdSet = new Set<ID>();
        List<String> deInstallationABOFlows = System.Label.APTS_DeInstallationABOFlows.split(',');
        //v103 ++ <<
        if (Test.isRunningTest() || sPageAction == FINALIZE) {
            isFinalizePageAction = true;
        }
 
        //Initial Loop to prepare map or set of data
        for (Apttus_Config2.LineItem oLineItemMO : allLines) {
            //prepare map of Line Item
            Apttus_Config2__LineItem__c oLineItem = oLineItemMO.getLineItemSO();
            mapLineItems.put(oLineItem.Id, oLineItem);
            //v105 | fix for Defect #20310 | Karan Khatri | Restrict to it reprice before finalize cart. Done for seeing correct bundle rollups for all in coverage option 
            if(isFinalizePageAction && oLineItem.Apttus_Config2__ChargeType__c!=null && oLineItem.Apttus_Config2__NetPrice__c!=null && oLineItem.Apttus_Config2__NetPrice__c!=0 && system.label.APTS_Service_Fee.equals(oLineItem.Apttus_Config2__ChargeType__c) && oLineItem.Apttus_Config2__OptionId__c!=null && (oLineItem.Apttus_Config2__OptionId__r.Name.equals(system.label.APTS_All_in_Coverage_Draft) || oLineItem.Apttus_Config2__OptionId__r.Name.equals(system.label.APTS_Basic_Coverage_Draft))){
                if(coverageMap.get(oLineItem.Apttus_Config2__ProductId__c+String.valueOf(oLineItem.Apttus_Config2__ParentBundleNumber__c))==null){
                    coverageMap.put(oLineItem.Apttus_Config2__ProductId__c+String.valueOf(oLineItem.Apttus_Config2__ParentBundleNumber__c),oLineItem.Apttus_Config2__NetPrice__c);
                }
            }
            //v105
            assetLineItemIDSet.add(oLineItem.Apttus_Config2__AssetLineItemId__c);
        }
        
        //get all adjustment line items for cart line items 
        mapLineItemAdjDisclaimer= getAdjustmentMap(mapLineItems.keySet());  
        
        //Validate data based on business scenerios
        for (Apttus_Config2.LineItem oLineItemMO : allLines) {   
            Apttus_Config2__LineItem__c oLineItem = oLineItemMO.getLineItemSO();
           
            if(oLineItem.Apttus_Config2__OptionId__c!=null && oLineItem.Apttus_Config2__OptionId__r.name.containsignorecase('Fixed Term'))
            {
                if(oLineItem.Apttus_Config2__BasePriceOverride__c == null || oLineItem.Apttus_Config2__BasePriceOverride__c == 0)
                {
                    //System.debug('** Abhishek Validation'+oLineItem.Apttus_Config2__OptionId__r.name+oLineItem.Apttus_Config2__BasePriceOverride__c);
                    result.isSuccess = false;
                    result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, Label.APTS_MANDATE_BPO));
                    return result;
                }            
            }
      //Check billing Frequency is not empty
            
            if(oLineItem.Apttus_Config2__BillingFrequency__c==null&&isFinalizePageAction){
                    result.isSuccess = false;
                    result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, Label.APTS_Mandate_Billing_Frequency));
                    return result;
                }
                //DQ-4719--START--v112
            if((!oLineItem.Apttus_Config2__LineStatus__c.equalsignorecase(LINE_STATUS_CANCEL)&&oLineItem.Apttus_Config2__NetPrice__c<0&&isFinalizePageAction&&oLineItem.Apttus_Config2__LineType__c=='Option')||(!oLineItem.Apttus_Config2__LineStatus__c.equalsignorecase(LINE_STATUS_CANCEL)&&oLineItem.Apttus_Config2__NetPrice__c<0&&isFinalizePageAction&&oLineItem.Apttus_Config2__LineType__c=='Product/Service' &&oLineItem.Apttus_Config2__HasOptions__c==false)){
                    result.isSuccess = false;
                    result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, DISCOUNT_MORE_100));
                    return result;
                }
                //DQ-4719--END--v112
            if (oCart.Apttus_Config2__NumberOfItems__c >= 170) {
                        result.isSuccess = true;
                        result.Messages.add(new ApexPages.Message(ApexPages.Severity.WARNING, System.Label.APTS_Restrict_Finalize_Many_Line_Items));
                        return result;
                    }
            //check if pricing pending on any line item
            if (oLineItem.Apttus_Config2__PricingStatus__c == PENDING) {
                bIsPricePending = true;
            }
            else if (!bIsPricePending && isFinalizePageAction) {
                //v105 | fix for Defect #20310 | Karan Khatri | Restrict to it reprice before finalize cart. Done for seeing correct bundle rollups for all in coverage option 
                if(!oLineItem.Apttus_Config2__LineStatus__c.equalsignorecase(LINE_STATUS_CANCEL) && !coverageMap.isEmpty() && oLineItem.Apttus_Config2__ChargeType__c!=null && system.label.APTS_Service_Fee.equals(oLineItem.Apttus_Config2__ChargeType__c) && oLineItem.Apttus_Config2__OptionId__c==null && oLineItem.Apttus_Config2__ProductId__c!=null && oLineItem.Apttus_Config2__PrimaryLineNumber__c!=null && coverageMap.get(oLineItem.Apttus_Config2__ProductId__c+String.valueOf(oLineItem.Apttus_Config2__PrimaryLineNumber__c))!=null && (coverageMap.get(oLineItem.Apttus_Config2__ProductId__c+String.valueOf(oLineItem.Apttus_Config2__PrimaryLineNumber__c))>oLineItem.Apttus_Config2__NetPrice__c)){
                    result.isSuccess = false;
                    result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, Label.APTS_ClickReprice));
                    return result;
                }
                
                //v105
                //v106 |defect 23631 - End date should be greater than start date
                if(oLineItem.Apttus_Config2__StartDate__c > oLineItem.Apttus_Config2__EndDate__c&&oLineItem.Apttus_Config2__LineStatus__c!=LINE_STATUS_CANCEL 
                    && oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c != 'XA14'){ //v107
                result.isSuccess = false;
                    result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, Label.APTS_Restrictdates));
                    return result;
                }
                //v106
                
                //if Finalizing
                if (NGMACHINE_ORDER.equalsIgnoreCase(sFlow)) {
                    //prepare map of LSP Details
                    if (PRODUCT_SERVICE.equalsIgnoreCase(oLineItem.Apttus_Config2__LineType__c) && oLineItem.Apttus_Config2__HasOptions__c) {
                        if (oLineItem.Apttus_Config2__IsPrimaryLine__c) {
                            iNumBundleLine ++;
                        }
                        if (oLineItem.APTS_Order_LSP_Detail__c != null) {
                            iNumLSPDetails ++;
                        }
                    }

                    //prepare set of SerialNumber2
                    //filter on product/service
                    if (oLineItem.APTS_Serial_Number2__c != NULL) {
                        if (!setSerialNum2.contains(oLineItem.APTS_Serial_Number2__c)) {
                            setSerialNum2.add(oLineItem.APTS_Serial_Number2__c);
                        } else {
                            result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, DUP_SERIAL_NUM));
                            result.isSuccess = false;
                            return result;
                        }
                    }
                }else if (NGSTANDARD_ORDER.equalsIgnoreCase(sFlow)) {
                    //Standard Order Cart
                    /*if (!oLineItem.APTS_ATP_Cleared__c) {
                        result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, ATP_NOT_DONE));
                        result.isSuccess = false;
                        return result;
                    } else if (oLineItem.Apttus_Config2__Quantity__c > oLineItem.APTS_Expected_Delivery_Quantity__c) {
                        result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, NOT_ENOUGH_QUANTITY));
                        result.isSuccess = false;
                        return result;
                    }*/
                    }else  if (oCart != null && oCart.Apttus_Config2__BusinessObjectType__c != NULL && APTS_CPQConstants.LABEL_AGREEEMENT.equalsIgnoreCase(oCart.Apttus_Config2__BusinessObjectType__c)) {
                        // First validation: Tax calculations
                        if (!Test.isRunningTest()) {
                            if(oLineItem.APTS_Serial_Number__c != NULL && oLineItem.Apttus_Config2__AssetLineItemId__c != NULL && oLineItem.APTS_Asset_Change_type__c == NULL  && oLineItem.Apttus_Config2__LineType__c == APTS_CPQConstants.PROD_SERV_LABEL ) {
                                result.isSuccess = false;
                                result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.APTS_Restrict_Finalize_Asset_Change));
                                return result;

                            }
                        }
                        if (!oLineItem.APTS_is_Tax_and_VAT_calculated__c &&
                                    (!oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.APTS_Exclude_TAX__c
                                     || !oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.APTS_Exclude_VAT__c)) {
                                //v110 << ++
                                result.isSuccess = true;
                             result.Messages.add(new ApexPages.Message(ApexPages.Severity.WARNING, System.Label.APTS_Restrict_Finalize_tax_calculate));
                             //v110 ++ >>
                             return result;
                         }
                    if (oCart.Apttus_Config2__NumberOfItems__c >= 170) {
                        result.isSuccess = false;
                        result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.APTS_Restrict_Finalize_Many_Line_Items));
                        return result;
                    }
                }
            }
            /* Defect # 19547 | commented changes for restricting adjustments to bundles 
//Added as part of defect 18545 | Karan Khatri | Restrict base price override for bundles
if (oLineItem.Apttus_Config2__HasOptions__c && ((oLineItem.Apttus_Config2__BasePriceOverride__c != null && oLineItem.Apttus_Config2__BasePriceOverride__c != 0))){
result.isSuccess = false;
result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, System.label.APTS_RestrictBPOforBundles));
return result;
}*/
            
            // 104 >> validate negative amounts | Defect # 21815 Skip validation for Bundle header 
            
            if (oLineItem.Apttus_Config2__LineStatus__c != LINE_STATUS_CANCEL && !oLineItem.Apttus_Config2__HasOptions__c) {        
                if(oLineItem.Apttus_Config2__ProductId__r.APTS_Category_Adjustments_Product__c!=true){       
                    if (oLineItem.Apttus_Config2__NetPrice__c < 0 ){
                        result.isSuccess = false;
                        result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, DIS_AMNT_100));
                        return result;
                    }
                    }
                }
            //v108 ++ <<
            if(oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c == APTS_OrderConstants.DE_INSTALLATION) {
                if(oLineItem.Apttus_Config2__LineStatus__c != LINE_STATUS_CANCEL && (oLineItem.Apttus_Config2__LineStatus__c == APTS_OrderConstants.AMENDED || oLineItem.Apttus_Config2__LineStatus__c == APTS_OrderConstants.RENEWED)) {
                    result.isSuccess = false;
                    result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, NOT_ALLOWED_IN_DEINSTALL));
                    return result;
                }               
            }
            //v108 ++ >>
            if(!bIsPricePending && isFinalizePageAction && olineItem.Apttus_Config2__AssetLineItemId__c!=null){
                if(oLineItem.Apttus_Config2__LineType__c!=null && oLineItem.Apttus_Config2__LineType__c.equalsIgnoreCase('Option') && olineItem.Apttus_Config2__StartDate__c!=null && olineItem.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__OriginalStartDate__c!=null && olineItem.Apttus_Config2__StartDate__c < olineItem.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__OriginalStartDate__c){
                    result.isSuccess = false;
                    result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR,System.Label.APTS_OriginalStartDateABOError));
                    return result;
                }
                if(olineItem.Apttus_Config2__HasOptions__c && olineItem.Apttus_Config2__IsPrimaryLine__c){
                    primaryLineBundleAssetIdSet.add(olineItem.Apttus_Config2__AssetLineItemId__c);
                   }
            }
            
        }
        //v103 ++ >>
        
  
        //ListDisc.mapLineItemAdjDisclaimer.values();
        
        for(list<Apttus_Config2__AdjustmentLineItem__c> listALI : mapLineItemAdjDisclaimer.values()){
            ListDisc.addall(listALI);
        }   
        for (Apttus_Config2__AdjustmentLineItem__c ALI :ListDisc) {
      
            if(ALI.APTS_Adjustment_Source__c.equalsignorecase('Parent') && NGDEFAULT.equalsIgnoreCase(sFlow)){
                result.Messages.add(new ApexPages.Message(ApexPages.Severity.WARNING,DISCLAIMER));
                result.isSuccess = true;
                return result;   
            }
           
            if(ALI.APTS_Asset_Sub_Type__c == ASSET_SUB_TYPE_INFLATION && (ALI.APTS_Asset_Adjustment_Amount__c != ALI.Apttus_Config2__AdjustmentAmount__c || ALI.APTS_Asset_Sub_Type__c != ALI.Apttus_Config2__SubType__c))
            {               
                result.isSuccess = false;
                result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, INFLATION_VALIDATION_MESSAGE));
                return result;
            }
            //v109 <<++
           
            if(ALI.APTS_End_Date__c < ALI.APTS_Start_Date__c){
                result.isSuccess = false;
                result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, END_START_DATE_MESSAGE));
                return result;
            }
            //v109-->>
        }
        /*Defect # 19547 | commented changes for restricting adjustments to bundles 
        for (Apttus_Config2__AdjustmentLineItem__c ALI :ListDisc) {
           if(ALI.Apttus_Config2__LineItemId__r.Apttus_Config2__HasOptions__c){
                result.isSuccess = false;
                result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, System.label.APTS_RestricAdjustmentsforBundles));
                return result;
            }
        }*/

        //IF Machine Order Flow
       
        if (NGMACHINE_ORDER.equalsIgnoreCase(sFlow) && !bIsPricePending && isFinalizePageAction) {
            //if LSP Details populated on all bundles or not
            if (iNumLSPDetails < iNumBundleLine) {
                result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, BUNDLE_DETAILS_NOT_SET));
                result.isSuccess = false;
                return result;
            } else if (!setSerialNum2.isEmpty()) {
                //validate serialnumber2 conditons for commercial swap
                Set<String> setActSerialNum = new Set<String>();
                for (PhysicalAsset__c oPhyAsset :  [SELECT id, SerialNumber__c FROM PhysicalAsset__c WHERE SerialNumber__c IN :setSerialNum2]) {
                    setActSerialNum.add(oPhyAsset.SerialNumber__c);
                }

                String message = '';
                Integer cnt = 0;
                // Iterate the different LineItems
                for (String sSerNum2 : setSerialNum2) {
                    Boolean isSerExists = setActSerialNum.contains(sSerNum2);

                    if (!isSerExists) {
                        result.isSuccess = false;
                        message += sSerNum2 + ' ';
                        cnt ++;
                    }
                }

                if (!result.isSuccess) {
                    message += cnt > 1 ? ' are' : ' is';
                    message += INVALID_SERIAL_NUM;
                    result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, message));
                    return result;
                }
            } else {
                //get adjustments
                Map<Id, List<Apttus_Config2__AdjustmentLineItem__c>> mapLineItemAdjs = getAdjustmentMap(mapLineItems.keySet());

                // Iterate the different LineItems
                for (Apttus_Config2__LineItem__c oLineItem : mapLineItems.values()) {
                    if (oLineItem.Apttus_Config2__LineStatus__c != LINE_STATUS_CANCEL) {
                        
                        //validate adjustments
                        if (mapLineItemAdjs != NULL && mapLineItemAdjs.containsKey(oLineItem.Id)) {
                            String errMsg = validateAdjustments(oLineItem, mapLineItemAdjs.get(oLineItem.Id));
                            if (errMsg != NULL) {
                                result.isSuccess = false;
                                result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, errMsg));
                                return result;
                            }
                        }
                    }
                }
            }
        } else if (!bIsPricePending && isFinalizePageAction) {
            
           
            Map<Id, List<Apttus_Config2__AdjustmentLineItem__c>> mapLineItemAdjs = getAdjustmentMap(mapLineItems.keySet());

            // Iterate the different LineItems
            if (mapLineItemAdjs != NULL && !mapLineItemAdjs.isEmpty()) {
                for (Apttus_Config2__LineItem__c oLineItem : mapLineItems.values()) {
                    if (oLineItem.Apttus_Config2__LineStatus__c != LINE_STATUS_CANCEL) {
                        //validate adjustments
                        if (mapLineItemAdjs.containsKey(oLineItem.Id)) {                     
                            String errMsg = validateAdjustments(oLineItem, mapLineItemAdjs.get(oLineItem.Id)); 
                               if (errMsg != NULL) {
                                result.isSuccess = false;
                                result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, errMsg));
                                return result;
                            }
                        }

                    }
                }
            }
            if(!deInstallationABOFlows.isEmpty() && deInstallationABOFlows.contains(sFlow)){
                Map<Id,Boolean> hasDeInstallationOrdersMap = validateIfDeinstallationOrder(primaryLineBundleAssetIdSet);
                if(!hasDeInstallationOrdersMap.isEmpty()){
                    for (Apttus_Config2__LineItem__c oLineItem : mapLineItems.values()) {
                        if(olineItem.Apttus_Config2__AssetLineItemId__c!=null && olineItem.Apttus_Config2__HasOptions__c && olineItem.Apttus_Config2__IsPrimaryLine__c && hasDeInstallationOrdersMap.get(olineItem.Apttus_Config2__AssetLineItemId__c)){
                            result.isSuccess = false;
                            result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR,System.Label.APTS_DeInstallationABOError));
                            return result;
                        }
                    }
                }
            }
        }
         for(list<Apttus_Config2__AdjustmentLineItem__c> ListAdjust : mapLineItemAdjDisclaimer.values()){
         for(Apttus_Config2__AdjustmentLineItem__c instALI : ListAdjust)
         {
         if(instALI.Apttus_Config2__SubType__c == null)
            { 
                result.isSuccess = false;
                result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR,EMPTYSUBTYPE+instALI.Apttus_Config2__LineItemId__r.Apttus_Config2__Description__c+'.Please re-enter and click on reprice'));
                return result;
            }
        }
         }
        //Added by Karan | Restrict user to calculate tax before Finalize click -- END
        //v101 end
        //System.debug('*** validation callback end');
        return result;
    }

    // Code to validate the ramp lines Loops through the ramp lines
    global Apttus_Config2.CustomClass.ValidationResult validateRampLineItems(Apttus_Config2.ProductConfiguration cart, List<Apttus_Config2.LineItem> rampLineItems) {
        Apttus_Config2.CustomClass.ValidationResult result = new Apttus_Config2.CustomClass.ValidationResult(true);
        return result;
    }

    // Code to validate the assets passes cart and asset lines modified
    global Apttus_Config2.CustomClass.ValidationResult validateAssetItems(Apttus_Config2.ProductConfiguration cart, List<Apttus_Config2__TempRenew__c> assetItems) {
        Apttus_Config2.CustomClass.ValidationResult result = new Apttus_Config2.CustomClass.ValidationResult(true);
        return result;
    }

    //get Adjustment line items
    private Map<Id, List<Apttus_Config2__AdjustmentLineItem__c>> getAdjustmentMap(Set<Id> setLineItemIds) {
        Map<Id, List<Apttus_Config2__AdjustmentLineItem__c>> mapLineItemAdjs = new Map<Id, List<Apttus_Config2__AdjustmentLineItem__c>>();
        for (Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem : [SELECT Id,APTS_CER__r.APTS_Start_Date__c, APTS_CER__r.APTS_End_Date__c, APTS_Discount_Type__c,APTS_CER__c, APTS_CER__r.APTS_Adjustment_Value__c,APTS_CER__r.APTS_Adjustment_Type__c,APTS_CER__r.APTS_UOM__c,APTS_CER__r.APTS_Sub_Type__c,IsDeleted, Name, CurrencyIsoCode, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById,
                SystemModstamp, LastActivityDate, LastViewedDate, LastReferencedDate, Apttus_Config2__LineItemId__c,APTS_Adjustment_Source__c,
                Apttus_Config2__AdjustmentAmount__c, Apttus_Config2__AdjustmentAppliesTo__c, Apttus_Config2__AdjustmentType__c,
                Apttus_Config2__BenefitQuantity__c, Apttus_Config2__CouponCode__c, Apttus_Config2__IncentiveAdjustmentAmount__c,
                Apttus_Config2__IncentiveCode__c, Apttus_Config2__IncentiveId__c, Apttus_Config2__IsModifiable__c, Apttus_Config2__LineNumber__c,
                Apttus_Config2__LineType__c, Apttus_Config2__PriceRuleEntryId__c, Apttus_Config2__PriceRuleId__c, Apttus_Config2__SubType__c,
                Apttus_Config2__Type__c, Apttus_Config2__UnitAdjustment__c, Apttus_Config2__AdjustmentUom__c,Apttus_Config2__LineItemId__r.Apttus_Config2__Description__c,Apttus_Config2__Bucket__c,
                Apttus_Config2__RunningTotalAdjustedPrice__c, Apttus_Config2_SellingUom__c, APTS_AdjustmentLineItemExtId__c,
                APTS_LineItemExtId__c, APTS_AgreementExtId__c, APTS_ConversionId__c, APTS_MigrationDate__c, APTS_SourceSystem__c,
                APTS_Break_up_Adjustment_Price__c, APTS_Condition_Type__c, APTS_Custom_Adjustment_Amount__c, APTS_Adjustment_Type__c,
                APTS_End_Date__c, APTS_Is_Primary__c, APTS_Start_Date__c, APTS_UoM__c, APTS_Agreement_Number__c, Agreement_LineItem_Id__c,Apttus_Config2__LineItemId__r.Apttus_Config2__HasOptions__c,
                APTS_Temp_Id_String__c, APTS_Sub_Category__c, APTS_Sub_Sub_Category__c, APTS_Copied_Category_Adjustments__c ,Apttus_Config2__LineItemId__r.Apttus_Config2__StartDate__c,Apttus_Config2__LineItemId__r.Apttus_Config2__EndDate__c, 
                APTS_Asset_Sub_Type__c, APTS_Asset_Adjustment_Amount__c 
                FROM Apttus_Config2__AdjustmentLineItem__c
                WHERE Apttus_Config2__LineItemId__c = :setLineItemIds]) {
            if (mapLineItemAdjs.containsKey(adjustmentLineItem.Apttus_Config2__LineItemId__c)) {
                mapLineItemAdjs.get(adjustmentLineItem.Apttus_Config2__LineItemId__c).add(adjustmentLineItem);
            } else {
                mapLineItemAdjs.put(adjustmentLineItem.Apttus_Config2__LineItemId__c, new List<Apttus_Config2__AdjustmentLineItem__c> {adjustmentLineItem});
            }
        }
        return mapLineItemAdjs;
    }
    
    private string validateAdjustments(Apttus_Config2__LineItem__c oLineItem, List<Apttus_Config2__AdjustmentLineItem__c> listAdjustments) {
        String errMsg; 
       //Frame the Map with Adjustment SubType as key , so as to get the number of Adjustments with sameSubtype in a LineItem 
        Map<String,Set<Id>> MapAdjSubtype = new  Map<String,Set<Id>>(); 
        Set<Id> setchangedAdj = new set<Id>();
        if(listAdjustments != NULL && listAdjustments.size()>0){
        for (Apttus_Config2__AdjustmentLineItem__c ALI : listAdjustments) {
      
     //DQ-4499   
     if(ALI.APTS_CER__c != null && ALI.APTS_Discount_Type__c == 'Auto' && (
        ALI.APTS_CER__r.APTS_Adjustment_Type__c != ALI.Apttus_Config2__AdjustmentType__c ||
        ALI.Apttus_Config2__AdjustmentUom__c != ALI.APTS_CER__r.APTS_UOM__c ||
        ALI.APTS_CER__r.APTS_Sub_Type__c != ALI.Apttus_Config2__SubType__c ||
        ALI.APTS_CER__r.APTS_Adjustment_Value__c != ALI.Apttus_Config2__AdjustmentAmount__c))
        {setchangedAdj.add(ALI.id);} 
       
            if(MapAdjSubtype.containsKey(ALI.Apttus_Config2__SubType__c))
            {   
                Set<Id> tempSetid = new Set<Id>();
                tempSetid=MapAdjSubtype.get(ALI.Apttus_Config2__SubType__c);
                tempSetid.add(ALI.id);
                MapAdjSubtype.put(ALI.Apttus_Config2__SubType__c,tempSetId);
            }
            else
            {
                Set<Id> tempSetid = new Set<Id>();
                tempSetid.add(ALI.id);
                MapAdjSubtype.put(ALI.Apttus_Config2__SubType__c,tempSetId);       
            }
        }  
        }
        //DQ-4499
        if(setchangedAdj != null && setchangedAdj.size()>0)       
       { errMsg = CERChangeLabel1+olineItem.Apttus_Config2__Description__c+CERChangeLabel2 ;}
        
        for(String instSubtype : MapAdjSubtype.keySet())
        {
            Set<Id> MultipleAdj = new Set<Id>();
            MultipleAdj = MapAdjSubtype.get(instSubtype);
            if(MultipleAdj.size()>1)
            errMsg = DUPLICATESUBTYPE;    //Built as part as DOQCP-49
            
        }
        
        // for (Apttus_Config2__AdjustmentLineItem__c ALI : listAdjustments) {
        //     // Internal validation per Adjustment Line Item

        //     // Section from Abhishek commented for now, to deploy in QAS3
        //     // Added by Abhishek K for Date Validation
        //     if(ALI.APTS_Start_Date__c < ALI.Apttus_Config2__LineItemId__r.Apttus_Config2__StartDate__c ||   ALI.APTS_End_Date__c > ALI.Apttus_Config2__LineItemId__r.Apttus_Config2__EndDate__c)
        //     {
        //          errMsg += 'Adjustment line item dates should be in range of the Line item.';
        //     }
        // }
        return errMsg;
    }
    public static Map<Id,Boolean> validateIfDeinstallationOrder(Set<Id> bundleAssetId){
        Map<Id,Boolean> hasDeInstallationOrdersMap = new Map<Id,Boolean>();
        List<String> deInstallationOrderStatus = System.Label.APTS_DeInstallationABOStatus.split(',');

        For(Apttus_Config2__OrderLineItem__c deInstallOrderObj : [select id,Apttus_Config2__AssetLineItemId__c from Apttus_Config2__OrderLineItem__c where Apttus_Config2__AssetLineItemId__c =: bundleAssetId and Apttus_Config2__AssetLineItemId__r.Apttus_Config2__AssetStatus__c='Activated' and Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c =: DEINSTALLATION_ORDER and ( APTS_Status__c IN: deInstallationOrderStatus)]){
		if(hasDeInstallationOrdersMap.get(deInstallOrderObj.Apttus_Config2__AssetLineItemId__c)==null){
                hasDeInstallationOrdersMap.put(deInstallOrderObj.Apttus_Config2__AssetLineItemId__c,true);
            }
        }
        return hasDeInstallationOrdersMap;
    }
}