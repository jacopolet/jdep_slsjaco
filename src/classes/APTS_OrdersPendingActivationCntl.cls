/*************************************************************
@Name: APTS_OrdersPendingActivationCntl
@Author: Neev Shah
@CreateDate: 23-1-2019
@Description: Controller to activate Orders manually
@UsedBy: Activate Order page
******************************************************************/

public with sharing class APTS_OrdersPendingActivationCntl {
    private static final String NO_FAILED_ORDER = 'All Machine Orders are activated. No failed Order found.';
    private static final String SUCCESS_MSG = 'Machine got activated.';
    private static final String BILL_FREQ = 'Billing Frequency';
    private static final String BILL_PREF = 'Billing Preference';
    private static final String BILL_RULE = 'Billing Rule';
    private static final String ERROR_MSG = 'Try again';
    private static final String ERROR_NULL_BILL_FREQ = 'Cannot activate Order Line Item because the Billing Frequency is Null. Please contact OM Support Team.';
    private static final String ERROR_NULL_BILL_PREF = 'Cannot activate Order Line Item because the Billing Preference is Null. Please contact OM Support Team.';
    private static final String ERROR_NULL_BILL_RULE = 'Cannot activate Order Line Item because the Billing Rule is Null. Please contact OM Support Team.';
    private static final String ERROR_NULL_START_END_DATE = 'Cannot activate Order Line Item because start-end date are not correct. Please contact OM Support Team.';

    //variables for pagination
    public Boolean bDisableMore {get;set;}
    public Boolean bDisableLess {get;set;}
    private Integer iInitialCountToDisplay;
    private Integer iCountToDisplay;
    //variables for pagination

    public Id selectedOLIId {get;set;}
    public List < Apttus_Config2__OrderLineItem__c > listOLI {get;set;}
    private List < Apttus_Config2__OrderLineItem__c > listALLOLI {get;set;}


    public APTS_OrdersPendingActivationCntl() {
        bDisableMore = true;
        bDisableLess = true;
        iInitialCountToDisplay = 20;
        listOLI = new List < Apttus_Config2__OrderLineItem__c > ();
    }

    public void prepareData() {
        listALLOLI = [select id, APTS_Status__c, name, APTS_Requested_Installation_Date__c, Apttus_Config2__OrderId__c, Apttus_Config2__OrderId__r.name, Apttus_Config2__ProductId__r.name, Apttus_Config2__BillingPreferenceId__r.name from Apttus_Config2__OrderLineItem__c where APTS_Treated_By_Activation_Batch__c = true and Apttus_Config2__Status__c <> :APTS_OrderConstants.ACTIVATED and Apttus_Config2__IsPrimaryLine__c = true];
        
        if (listALLOLI == null || listALLOLI.isEmpty()) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.Severity.ERROR, NO_FAILED_ORDER));
        } else {
            
            if(listALLOLI.size() > iInitialCountToDisplay){
                iCountToDisplay =  iInitialCountToDisplay;
                bDisableMore = false;
            }else{
                iCountToDisplay = listALLOLI.size();             
            }

            prepareDisplayList(iCountToDisplay);
        }
    }

    public void loadMore() {
        try{
            bDisableLess = false;
            iCountToDisplay = iCountToDisplay + iInitialCountToDisplay;
            Integer iMaxCount = iCountToDisplay;
            //try {
            if (iCountToDisplay >= listALLOLI.size()) {
                iMaxCount = listALLOLI.size();
                bDisableMore = true;
            }
    
            listOLI.clear();
            prepareDisplayList(iMaxCount);
        } catch (Exception ex) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
    }

    public void loadLess() {

        bDisableMore = false;
        try{
            if ((iCountToDisplay - iInitialCountToDisplay) <= iInitialCountToDisplay) {
                iCountToDisplay = iInitialCountToDisplay;
                bDisableLess = true;
            } else {
                iCountToDisplay = iCountToDisplay - iInitialCountToDisplay;
            }
    
            listOLI.clear();
            prepareDisplayList(iCountToDisplay);
        } catch (Exception ex) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
    }
    
    private void prepareDisplayList(Integer cnt){
        Apttus_Config2__OrderLineItem__c oliTmp;
        for (Integer iIndex = 0; iIndex < cnt; iIndex++) {
            oliTmp = listALLOLI.get(iIndex);
            listOLI.add(oliTmp);
        }
    }

    
    //Method activate individual order line item
    public void activateOrderLineItem() {

        try {

            if (selectedOLIId != null) {
                Apttus_Config2__OrderLineItem__c oli = new Apttus_Config2__OrderLineItem__c();
                oli.Id = selectedOLIId;
                oli.Apttus_Config2__ActivatedDate__c = System.now();
                update oli;

                prepareData();

                ApexPages.addmessage(new ApexPages.message(ApexPages.Severity.INFO, SUCCESS_MSG));
            } else {
                ApexPages.addmessage(new ApexPages.message(ApexPages.Severity.ERROR, ERROR_MSG));
            }

        } catch (Exception ex) {
            String errMsg = ex.getMessage();
            errMsg = errMsg.contains(BILL_FREQ) ? ERROR_NULL_BILL_FREQ : errMsg;
            errMsg = errMsg.contains(BILL_PREF) ? ERROR_NULL_BILL_PREF : errMsg;
            errMsg = errMsg.contains(BILL_RULE) ? ERROR_NULL_BILL_RULE : errMsg;

            ApexPages.addmessage(new ApexPages.message(ApexPages.Severity.ERROR, errMsg));
        }
    }

}