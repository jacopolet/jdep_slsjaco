/*************************************************************
  @Name: APTS_AcceptOrder
  @Author: Shanmuga/Jagan
  @CreateDate: 15-04-2019
  @Description: Invoked from Accept Order button for creating Conversion Order
  @Test Class : Covered by APTS_AcceptOrder_Test
  @UsedBy: Create Accept button on Order page
  ******************************************************************/
//V101 13-Mar-2020: Renuka: DQ-472 New Debit flow changes
//V102 22-06-2020 Venky Muppalaneni: DQ-3038 Implementing new error handling 
//V103 04-08-2020 Nikunj Soni: DQ-3483 List has no rows for assignment to SObject
public without sharing class APTS_AcceptOrder {

    Id orderId;
    List<Integration_Log__c> integrationLogToInsertList = new List<Integration_Log__c> ();
    List<Apttus_Config2__OrderLineItem__c> oliList = new List<Apttus_Config2__OrderLineItem__c> ();
    List<Apttus_Config2__OrderLineItem__c> oliListToUpdate = new List<Apttus_Config2__OrderLineItem__c> ();
    List<Apttus_Config2__Order__c> listToUpdateOrderInvoiceStatus = new List<Apttus_Config2__Order__c> ();
    private static final String ACTIVATED = System.Label.APTS_Activated;
    private static final String INVOICINGSTATUS = 'Sent For Invoicing';
    private static final String XD01 = 'XD01';

    private static final String ID = System.Label.APTS_Id;

    public PageReference submitOrder() {
        PageReference pageRef = null;
        orderId = ApexPages.currentPage().getParameters().get(ID);
        APTS_OrderTriggerHandler.isTriggerDisabled = TRUE;
        //v102 ++ <<
        APTS_CustomErrorLogging.assignTransactionId(null);
        //v102 ++ >>
        //APTS_OrderUtils.stopOrderTrigger();
        try {
        //v103 ++ <<
           oliList = [Select Id, Apttus_Config2__Status__c, APTS_Status__c, Apttus_Config2__StartDate__c,Apttus_Config2__OrderId__c,Apttus_Config2__OrderId__r.APTS_Accept_Order_Check__c,Apttus_Config2__OrderId__r.Apttus_Config2__Status__c,
                      Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c,Apttus_Config2__OrderId__r.APTS_Order_Type__c ,Apttus_Config2__OrderId__r.APTS_Status__c, Apttus_Config2__OrderId__r.APTS_Remove_Billing_Block_Indicator__c, Apttus_Config2__OrderId__r.APTS_Billing_Date__c From Apttus_Config2__OrderLineItem__c Where Apttus_Config2__OrderId__c = :orderId]; 
         //  List<Apttus_Config2__Order__c> lstOrder = [SELECT Id, APTS_Accept_Order_Check__c, Apttus_Config2__Status__c, APTS_SAP_OrderType__c,
          //           APTS_Order_Type__c, APTS_Status__c, APTS_Remove_Billing_Block_Indicator__c, APTS_Billing_Date__c
            //         FROM Apttus_Config2__Order__c WHERE Id = :orderId AND APTS_Accept_Order_Check__c = false];
            
            if(oliList.size() > 0)
            {         
                for(Apttus_Config2__OrderLineItem__c oli: oliList)
                {
                    if(oli.Apttus_Config2__OrderId__c != null)
                    {
                        if(!oli.Apttus_Config2__OrderId__r.APTS_Accept_Order_Check__c)
                        {
                            oli.Apttus_Config2__OrderId__r.APTS_Accept_Order_Check__c = true;
                
                            if (oli.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c == XD01) {
                                oli.Apttus_Config2__OrderId__r.Apttus_Config2__Status__c = ACTIVATED;
                                oli.Apttus_Config2__OrderId__r.APTS_Status__c = APTS_BIRUtils.INVOICINGSTATUS; //v130
                                oli.Apttus_Config2__OrderId__r.APTS_Remove_Billing_Block_Indicator__c = true;
                                oli.Apttus_Config2__OrderId__r.APTS_Billing_Date__c = system.today();
                                integrationLogToInsertList.add(APTS_OrderUtils.createIntegrationLog(oli.Apttus_Config2__OrderId__r));                                             
                            } else {
                                System.enqueueJob(new APTS_AcceptOrderQueue(orderId));
                            }
                            listToUpdateOrderInvoiceStatus.add(oli.Apttus_Config2__OrderId__r);
                        }
                        if (oli.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c == XD01) {
                            oli.APTS_Status__c = ACTIVATED;
                            oli.Apttus_Config2__Status__c = ACTIVATED;
                            oli.Apttus_Config2__ActivatedDate__c = oli.Apttus_Config2__StartDate__c;
                            oliListToUpdate.add(oli);
                        }
                    }
                }
                if(!listToUpdateOrderInvoiceStatus.isEmpty()){
                    update listToUpdateOrderInvoiceStatus;
                }
                if (!integrationLogToInsertList.isEmpty()){
                    insert integrationLogToInsertList;
                }
                if (!oliListToUpdate.isEmpty()) {
                     update oliListToUpdate;
                }
            }
            //v103 ++ >>
            pageRef = new PageReference('/' + orderId);
            pageRef.setRedirect(true);
        } catch(exception e) {
            //v102 ++ <<
            APTS_CustomErrorLogging.createErrorLog('APTS_AcceptOrderQueue', 'Apex', e.getTypeName() + ':' + e.getMessage() + '__StackTrace:_' + e.getStackTraceString(), 'Order',
                                                   orderId, 'OM', false, false, null, true, orderId, null, e.getmessage());
            
            pageRef = new PageReference('/' + orderId);
            pageRef.setRedirect(true);
        }
        APTS_CustomErrorLogging.saveErrorLog();
        //v102 ++ >>
        return pageRef;
    }
}