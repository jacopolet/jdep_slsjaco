@IsTest
public with sharing class APTS_CreditMemoApprovalEmailTest
{

public static TestMethod void testCredit()
{
Account testAccount = APTS_TestUtils.createOrganisationproduct();
        insert testAccount;
        
    Apttus_Billing__Invoice__c invoice = APTS_TestUtils.createInvoice(testAccount.id);
    insert invoice;
    
    case cas = APTS_TestUtils.createcase(testAccount.id);
    insert cas;
    
    Apttus_Config2__AccountLocation__c loc = APTS_TestUtils.createAccountLocation(testAccount.id);
    insert loc;
        
    Apttus_Billing__CreditMemo__c  credMemo = APTS_TestUtils.createCreditMemo(testAccount.id,invoice.id,loc.id,cas.id);
    insert credMemo ;
    
    APTS_CreditMemoApprovalEmailController ac = new APTS_CreditMemoApprovalEmailController();
    ac.creditMemoId  = credMemo.id;
    ac.getCreditMemo();
    ac.getCreditMemoLineItems();

}

}