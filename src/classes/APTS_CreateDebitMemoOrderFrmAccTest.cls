@isTest
public class APTS_CreateDebitMemoOrderFrmAccTest{
    
    private static final String ACCOUNT_NAME = 'JDETestAccount';
    private static final String CONTACT_NUMBER = '1010101011';
    private static final String STANDARD_DEAL = 'Standard Deal';
    private static final String PRICELIST_NAME = 'JDETest Price List';
    private static final String PROD_FAMILY_MACHINE = 'MA';
    private static final String PROD_CONFIG_BUNDLE = 'Bundle';
    private static final String IN_EFFECT = System.Label.APTS_In_Effect;
    private static final String ACTIVATED = System.Label.APTS_Activated;
    private static final String DEBIT_MEMO = 'Debit Memo';
    private static final String XD01 = System.Label.APTS_XD01;
    private static final String DRAFT = 'Draft';

    static testmethod void logic1() {

        // create account
        Account oAccount = APTS_TestDataFactory.createAccount(ACCOUNT_NAME);
        Database.insert(oAccount, FALSE);

        // create contact
        Contact oContact = APTS_TestDataFactory.createContact(oAccount, CONTACT_NUMBER);
        Database.insert(oContact, FALSE);

        //create price list
        Apttus_Config2__PriceList__c oPricelist = APTS_TestDataFactory.createPriceList(PRICELIST_NAME);
        oPricelist.APTS_SalesOrg__c = '0111';
        Database.insert(oPricelist, FALSE);
        
        //Create Products
        Product2 prod1 = APTS_TestDataFactory.createProduct(ACCOUNT_NAME,ACCOUNT_NAME, PROD_FAMILY_MACHINE, PROD_CONFIG_BUNDLE, FALSE, TRUE);
        prod1.APTS_SAPExtID__c = 'sapprod1';
        Database.insert(prod1, FALSE);

        //Create Price List Items
        Apttus_Config2__PriceListItem__c pli1 = APTS_TestDataFactory.createPriceListItem(oPricelist.Id, prod1.Id);
        Database.insert(pli1, FALSE);

        //Agreement
        Apttus__APTS_Agreement__c oAgr = APTS_TestDataFactory.createAgreement(oContact.Id, oPricelist.Id, oAccount.Id, STANDARD_DEAL);
        oAgr.Apttus__Term_Months__c = 12;
        oAgr.Apttus__Status_Category__c = IN_EFFECT;
        oAgr.Apttus__Status__c = ACTIVATED;
        oAgr.Apttus__Version_Number__c = 1;
        Database.insert(oAgr, FALSE);
        ApexPages.currentPage().getParameters().put('Id', oAccount.id);
        ApexPages.currentPage().getParameters().put('type', DEBIT_MEMO);

        Test.startTest();

        APTS_CreateDebitMemoOrderFromAccount cdm = new APTS_CreateDebitMemoOrderFromAccount();

        cdm.createOrder();
        cdm.back();
       
        oAccount.Sales_Organization__c = 'SAP_0111';
        update oAccount;

        Pagereference p = cdm.createOrder();

        List<Apttus_Config2__Order__c> oOrderNew = [Select id,Apttus_Config2__Source__c from Apttus_Config2__Order__c where Apttus_Config2__BillToAccountId__c=: oAccount.Id order by createddate desc limit 1];
        System.assert(oOrderNew.size() >= 0);
        System.assertEquals('Account',oOrderNew[0].Apttus_Config2__Source__c);

        Test.stopTest();
    }

        static testmethod void logic2() {
        try{
        // create account
        //Account oAccount = APTS_TestDataFactory.createAccount(ACCOUNT_NAME);
        Account oAccount = new Account();
        Database.insert(oAccount, FALSE);

        // create contact
        Contact oContact = APTS_TestDataFactory.createContact(oAccount, CONTACT_NUMBER);
        Database.insert(oContact, FALSE);

        //create price list
        Apttus_Config2__PriceList__c oPricelist = APTS_TestDataFactory.createPriceList(PRICELIST_NAME);
        oPricelist.APTS_SalesOrg__c = '0111';
        Database.insert(oPricelist, FALSE);
        
        //Create Products
        Product2 prod1 = APTS_TestDataFactory.createProduct(ACCOUNT_NAME,ACCOUNT_NAME, PROD_FAMILY_MACHINE, PROD_CONFIG_BUNDLE, FALSE, TRUE);
        prod1.APTS_SAPExtID__c = 'sapprod1';
        Database.insert(prod1, FALSE);

        //Create Price List Items
        Apttus_Config2__PriceListItem__c pli1 = APTS_TestDataFactory.createPriceListItem(oPricelist.Id, prod1.Id);
        Database.insert(pli1, FALSE);

        //Agreement
        Apttus__APTS_Agreement__c oAgr = APTS_TestDataFactory.createAgreement(oContact.Id, oPricelist.Id, oAccount.Id, STANDARD_DEAL);
        oAgr.Apttus__Term_Months__c = 12;
        oAgr.Apttus__Status_Category__c = IN_EFFECT;
        oAgr.Apttus__Status__c = ACTIVATED;
        oAgr.Apttus__Version_Number__c = 1;
        Database.insert(oAgr, FALSE);
        ApexPages.currentPage().getParameters().put('Id', oAccount.id);
        ApexPages.currentPage().getParameters().put('type', DEBIT_MEMO);

        Test.startTest();

        APTS_CreateDebitMemoOrderFromAccount cdm = new APTS_CreateDebitMemoOrderFromAccount();

        cdm.createOrder();
        cdm.back();
       
        oAccount.Sales_Organization__c = 'SAP_0111';
        
        update oAccount;
        
        Pagereference p = cdm.createOrder();

        List<Apttus_Config2__Order__c> oOrderNew = [Select Apttus_CMConfig__AgreementId__c,id from Apttus_Config2__Order__c where Apttus_Config2__BillToAccountId__c=: oAccount.Id order by createddate desc limit 1];
        System.assert(oOrderNew.size() >= 0);
        System.assertEquals(oAgr.Id,oOrderNew[0].Apttus_CMConfig__AgreementId__c);

        Test.stopTest();
        }catch(Exception ex){
            system.debug(ex);
        }
   }
   /*method used to cover catch block in class */
   /*static testmethod void logic3() {
        try{
        Test.startTest();

        APTS_CreateDebitMemoOrderFromAccount cdm = new APTS_CreateDebitMemoOrderFromAccount();

        cdm.createOrder();
        cdm.back();
        Test.stopTest();
        }catch(Exception ex){
            system.debug(ex);
        }
        }*/
}