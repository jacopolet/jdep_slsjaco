/**********************************************************************************
 * @Author: Lavanya Ravindran
 * @Company: Accenture
 * @Description: Build in progress class for new machine order ux Test class - (Dummy Code for UI purpose ONLY)
 **********************************************************************************/

@isTest
public with sharing class APTS_CreateOrderNewUXCtrlTest {

  @isTest static void test_MachineOrder() {

       Account childAccount = APTS_TestUtils.createAccount();
            insert childAccount;
            
            // Create an opportunity for the child Account
            Opportunity opp = APTS_TestUtils.createOpportunity(childAccount.id);
            insert opp;
            
            // Create Price List
            Apttus_Config2__PriceList__c priceList = APTS_TestUtils.createPriceList();
            insert priceList;
            
            
            

            Apttus_Config2__PriceList__c CSPPriceList = APTS_TestUtils.createPriceList();
            CSPPriceList.APTS_PriceList_Type__c = 'CSP';
            CSPPriceList.Apttus_Config2__BasedOnPriceListId__c = priceList.id;
            CSPPriceList.Name= 'CSP PriceList';
            insert CSPPriceList;
            
              // Create a contact
            Contact con = APTS_TestUtils.createContact();
            insert con;
            
            // Create the quote (for the child account)
            Apttus_Proposal__Proposal__c quoteParent = APTS_TestUtils.getQuoteProposal(childAccount.id, opp.Id, 'Proposal', 'Test', priceList.id);
            insert quoteParent;

            // Create a product
            Product2 product = APTS_TestUtils.createProduct('Piazza DOro Estremo Bonen 1000 Gram', '26940998', 'Espresso');
            product.IsActive = true;
            insert product;
            
               // Create the quote (for the child account)
        /*    Apttus_Proposal__Proposal__c quoteParent = APTS_TestUtils.getQuoteProposal(childAccount.id, opp.Id, 'Proposal', 'Test', priceList.id);
            insert quoteParent;*/
            
            
              // Create and activate the agreement (for the parent account)
            Apttus__APTS_Agreement__c agreementParent = APTS_TestUtils.createAgreement(con.Id, quoteParent.Id, priceList.Id, childAccount.Id);
            agreementParent.Apttus__Status__c = 'Activated';
            agreementParent.Apttus__Status_Category__c = 'In Effect';
            agreementParent.Apttus__Contract_End_Date__c = Date.newInstance(2020, 12, 12);
            agreementParent.APTS_Routesales__c = TRUE;
            insert agreementParent;
            
             /* create Cer Records  **/
    
        APTS_Contract_Entitlement_Repository__c cerRecord =new APTS_Contract_Entitlement_Repository__c();
       // cerRecord.APTS_Agreement_Adjustment_Line_Item__c=aali.ID;
                                    cerRecord.APTS_Adjustment_Type__c='% Discount';
                                    cerRecord.APTS_Adjustment_Value__c=10;
                                    cerRecord.APTS_Agreement_Type__c='Standard Deal';
                                    cerRecord.APTS_Product__c=product.id;
                                    cerRecord.APTS_Sold_to_Party__c=childAccount.id;
                                    cerRecord.APTS_Is_Pending__c=false;
                                    insert cerRecord; 


//Neev ++ <<
    /* create Order **/
    
        Apttus_Config2__Order__c order = new Apttus_Config2__Order__c();
        order.Apttus_Config2__Status__c = 'Pending';
        order.Apttus_Config2__Type__c = 'Standard Order';
        order.Apttus_Config2__PriceListId__c = priceList.ID;
        order.Apttus_Config2__Source__c = 'Account';
      //  order.Apttus_Config2__BillingPreferenceId__c = billPrefID;
        order.Apttus_Config2__BillToAccountId__c = childAccount.id;
        order.Apttus_Config2__SoldToAccountId__c = childAccount.id;
        order.Apttus_Config2__ShipToAccountId__c = childAccount.id;
        order.Apttus_Config2__PricingDate__c = Date.today();
        order.Apttus_Config2__OrderStartDate__c = Date.today();
        order.Apttus_Config2__OrderEndDate__c = Date.today().addYears(1);
        //v101 ++ <<
        order.APTS_Requested_Delivery_Date__c = System.today().toStartOfWeek().addDays(3);
        order.APTS_Requested_De_Installation_Date__c = System.today().toStartOfWeek().addDays(7);
        order.APTS_Requested_Installation_Date__c = System.today().toStartOfWeek().addDays(7);
        order.APTS_Requested_Movement_Date__c = System.today();
        //v101 ++ >>
        insert order;
    
    
            
            APTS_CreateOrderNewUXCtrl.getOrder(childAccount.id);
            APTS_CreateOrderNewUXCtrl.getAgreement(childAccount.id);
            APTS_CreateOrderNewUXCtrl.getCER(childAccount.id);
            APTS_CreateOrderNewUXCtrl.getAccount(childAccount.id);


}
}