/*************************************************************
@Name: APTS_FinalizeSwapOrderController
@Author: Neev Shah
@CreateDate: 10-05-2018
@Description: APTS_FinalizeSwapOrderController to,
                1. finalize current cart
                2. redirect swap order page to contracted product page
******************************************************************/
public with sharing class APTS_FinalizeSwapOrderController {

    private static final String EMAIL = System.Label.APTS_Email;
    private static final String TECH_SWAP = System.Label.APTS_Technical_Swap;
    private static final String COM_SWAP = System.Label.APTS_Commercial_Swap;

    public PageReference redirectToContractedPage() {
        PageReference oPageRef = NULL;
        String businessObjectId = NULL;
        String currentCartId = NULL;

        try {

            businessObjectId = ApexPages.currentPage().getParameters().get('businessObjectId');
            currentCartId = ApexPages.currentPage().getParameters().get('id');

            if (String.isNotBlank(businessObjectId) && String.isNotBlank(currentCartId)) {
                //Finalize
                APTS_OrderUtils.finalizeCart(currentCartId);

                //Syncronize
                Boolean isSuccess = APTS_OrderUtils.syncCart(currentCartId);

                if (isSuccess) {
                    //get child Order
                    List<Apttus_Config2__Order__c> listOrder = [select id, APTS_Order_Sub_Type__c, Apttus_Config2__ParentOrderId__c from Apttus_Config2__Order__c where Apttus_Config2__ParentOrderId__c = :businessObjectId limit 1];

                    if (!listOrder.isEmpty()) {
                        Apttus_Config2__Order__c oOrder = listOrder[0];

                        //If Technical Swap, we clone cart
                        if (TECH_SWAP.equalsIgnoreCase(oOrder.APTS_Order_Sub_Type__c)) {
                            List<Apttus_Config2__ProductConfiguration__c> listConfig = [select id, Apttus_Config2__OrderId__c from Apttus_Config2__ProductConfiguration__c where Apttus_Config2__OrderId__r.Apttus_Config2__ParentOrderId__c = :businessObjectId limit 1];
                            if (!listConfig.isEmpty()){
                                //Get Line Items
                                String soql = getCreatableFieldsSOQL('Apttus_Config2__AssetLineItemId__r.APTS_Order_LSP_Detail__c', 'Apttus_Config2__LineItem__c', 'Apttus_Config2__ConfigurationId__c=\'' + currentCartId + '\'');
                                List<Apttus_Config2__LineItem__c> listLineItems = (List<Apttus_Config2__LineItem__c>)Database.query(soql);
                                System.debug('listLineItems = ' + listLineItems);
                                
                                //clone line items
                                if (!listLineItems.isEmpty()) {
                                    List<Apttus_Config2__LineItem__c> newLineItems = listLineItems.deepClone();
                                    System.debug('newLineItems = ' + newLineItems);
                                    for (Apttus_Config2__LineItem__c oLineItem : newLineItems) {
                                        System.debug('config id = ' + listConfig[0].Id);
                                        System.debug(' oLineItem = ' + oLineItem);
                                        
                                        if(oLineItem.Apttus_Config2__AssetLineItemId__c != NULL && oLineItem.APTS_Order_LSP_Detail__c == NULL){
                                            oLineItem.APTS_Order_LSP_Detail__c = oLineItem.Apttus_Config2__AssetLineItemId__r.APTS_Order_LSP_Detail__c;
                                        }

                                        oLineItem.Apttus_Config2__ConfigurationId__c = listConfig[0].Id;
                                        oLineItem.Apttus_Config2__PricingStatus__c = 'Pending';
                                        oLineItem.Apttus_Config2__LineStatus__c = 'Swapped';
                                        oLineItem.Apttus_Config2__AssetLineItemId__c = NULL;
                                        oLineItem.Apttus_Config2__AdjustmentType__c = 'Price Override';
                                        oLineItem.Apttus_Config2__AdjustmentAmount__c = 0;
                                        System.debug('oLineItem = ' + oLineItem);
                                    }
                                    insert newLineItems;
                                    System.debug('newLineItems = ' + newLineItems);

                                    System.enqueueJob(new APTS_RepriceFinalizationQueue(listConfig[0].Id));
                                    oPageRef = new PageReference('/' + businessObjectId);
                                }
                            }
                        } else if (COM_SWAP.equalsIgnoreCase(oOrder.APTS_Order_Sub_Type__c)) {
                            oPageRef = new PageReference('/apex/Apttus_Config2__OrderConfiguration?id=' + oOrder.Id + '&flow=NGMachineOrder&launchState=cart');
                        }
                        oPageRef.setRedirect(true);
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Exception = ' +  e.getMessage());
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString(), 'Apttus_Config2__ProductConfiguration__c', currentCartId, 'OM', false, false, EMAIL, true);
        }

        return oPageRef;
    }

    // Returns a dynamic SOQL statement for the whole object, includes only creatable fields since we will be inserting a cloned result of this query
    private string getCreatableFieldsSOQL(String additionalFields, String objectName, String whereClause) {

        String selects = '';

        if (whereClause == null || whereClause == '') { return null; }

        // Get a map of field name and field token
        Map<String, Schema.SObjectField> fMap = Schema.getGlobalDescribe().get(objectName.toLowerCase()).getDescribe().Fields.getMap();
        list<string> selectFields = new list<string>();

        if (fMap != null) {
            for (Schema.SObjectField ft : fMap.values()) { // loop through all field tokens (ft)
                Schema.DescribeFieldResult fd = ft.getDescribe(); // describe each field (fd)
                if (fd.isCreateable()) { // field is creatable
                    selectFields.add(fd.getName());
                }
            }
        }

        if (!selectFields.isEmpty()) {
            for (string s : selectFields) {
                selects += s + ',';
            }
            if(String.isNotBlank(additionalFields)){
                selects += additionalFields + ',';
            }
            if (selects.endsWith(',')) {selects = selects.substring(0, selects.lastIndexOf(','));}

        }

        return 'SELECT ' + selects + ' FROM ' + objectName + ' WHERE ' + whereClause;

    }
}