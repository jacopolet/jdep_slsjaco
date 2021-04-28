/*************************************************************
@Name: APTS_CreateDebitMemoOrderFromAccount
@Author: Ankit Joshi
@CreateDate: 03-07-2018
@Description: Create Debit Memo Order from Account
@UsedBy: Create Debit Memo button on Account page
***************************************************************/
//v101 Renuka : Defect#6048 Setting PriceList in the DebitOrder is modified.
//v102 13-Nov-2019 Renuka: QTCFLEX1-1583 Enable BTP checkbox logic for Credit and Debit memo orders

public with sharing class APTS_CreateDebitMemoOrderFromAccount{

    private final Apttus__APTS_Agreement__c oAgreement;
    private Id accountId;
    private String sType;
    private Account initialAccount;
    private static final String DEBIT_MEMO = System.Label.APTS_DebitMemo;
    private static final String ID = System.Label.APTS_Id;
    private static final String TYPE = System.Label.APTS_Type;
    private static final String IN_EFFECT = System.Label.APTS_In_Effect;
    private static final String ACTIVATED = System.Label.APTS_Activated;
    private static final String ACCOUNT = System.Label.APTS_Account;
    private static final String APEX = 'Apex';
    private static final String BIR = 'BIR';
    private static final String SLASH = '/';
    private static final String EXCEPTION_OCCURED = 'Exception: ';
    private static final String XD01 = System.Label.APTS_XD01;
    private static final String ORDER = 'Order';
    private static final String SAP = 'SAP_';
    private static final String STANDARD = 'Standard';
    private static final String STANDARD_DEAL = 'Standard Deal';
    private static final string SINGLEINVOICE = 'Single Invoice';
    private static final string NO= 'No';
    
    public Apttus_Config2__Order__c oOrder {get; set;}
    
    /** Controller Constructor 
    * Description : will be invoked on Page load
    **/
    public APTS_CreateDebitMemoOrderFromAccount() {

        accountId = ApexPages.currentPage().getParameters().get(ID);
        sType = ApexPages.currentPage().getParameters().get(TYPE);               
    }
    
    /** MethodName : createOrder 
    * Description : It is used to create the Order when Debit Memo button on Account is clicked
    **/
    public PageReference createOrder() {

        try{
            PageReference pageRef;
            Id standardAccountId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get(STANDARD_DEAL).getRecordTypeId();

            initialAccount = [SELECT Id, Ultimate_Parent_Account__c, APTS_Account_Level__c,
                          Language__c, Apttus_Config2__BillingPreferenceId__c, Apttus_Config2__PaymentTermId__c,
                          Bill_To_Payer_Account__c, Related_Payer_Account__c,APTS_Price_List__c,
                          /*Related_Bill_to_Machines_Services__c,*/ Related_Payer_Machines_Services__c,
                          Sales_Organization__c, Division__c, Distribution_Channel__c, Partner__c, Description,
                          (Select Id,APTS_Payer_Ingredients__c,APTS_Bill_to_Party_Ingredients__c,APTS_Check_on_Account_Ingredients__c from Apttus__R00N50000001Xl0UEAS__r
                            WHERE RecordTypeId =: standardAccountId and Apttus__Status__c =: ACTIVATED order by LastModifiedDate desc)
                          FROM Account
                          WHERE Id = :accountId limit 1];

            oOrder = new Apttus_Config2__Order__c();
            oOrder = APTS_OrderUtils.setOrderHeaderMandatoryFields(oOrder, sType);
            oOrder.Apttus_Config2__Source__c = ACCOUNT;
            oOrder.Apttus_Config2__Description__c = initialAccount.Description;

            APTS_OrderUtils.setOrderHeader(oOrder, initialAccount);
            
            //Set partner Functions for Order
            if(initialAccount.Apttus__R00N50000001Xl0UEAS__r != null && initialAccount.Apttus__R00N50000001Xl0UEAS__r.size() > 0){
                oOrder.APTS_Payer__c = initialAccount.Apttus__R00N50000001Xl0UEAS__r[0].APTS_Payer_Ingredients__c;
                oOrder.APTS_PayerIngredients__c = initialAccount.Apttus__R00N50000001Xl0UEAS__r[0].APTS_Payer_Ingredients__c;
                oOrder.APTS_Bill_to_Party_Ingredients_and_Payer__c = initialAccount.Apttus__R00N50000001Xl0UEAS__r[0].APTS_Bill_to_Party_Ingredients__c;
                //Added to fix defect #21150 and #21148
                oOrder.Apttus_CMConfig__AgreementId__c=initialAccount.Apttus__R00N50000001Xl0UEAS__r[0].Id;
                //v102 ++<< Added If condition
                if(!initialAccount.Apttus__R00N50000001Xl0UEAS__r[0].APTS_Check_on_Account_Ingredients__c){
                    APTS_BIRUtils.setInvoiceDataForDB(initialAccount.Apttus__R00N50000001Xl0UEAS__r[0], oOrder);    
                }
            }
            else{
                oOrder.APTS_Payer__c = initialAccount.Related_Payer_Account__c;
                oOrder.APTS_PayerIngredients__c = initialAccount.Related_Payer_Account__c;
                oOrder.APTS_Bill_to_Party_Ingredients_and_Payer__c = initialAccount.Bill_To_Payer_Account__c;
               
            }            
            oOrder.APTS_InvoiceType__c =SINGLEINVOICE;
            oOrder.APTS_Invoice_List_Indicator__c = NO;
            //Populate Pricelist on Order based on the Account's Sales Org
            /*Map<string, string> salesOrgMap = new Map<string, string>();
            Schema.DescribeFieldResult salesOrgList = Schema.sObjectType.Account.fields.Sales_Organization__c.getSObjectField().getDescribe();
            for(Schema.PicklistEntry salesOrgRec : salesOrgList.getPicklistValues()){
              salesOrgMap.put(salesOrgRec.getValue(), salesOrgRec.getLabel());
            }
            string accSalesOrg = (initialAccount.Sales_Organization__c).length() > 4 ? (initialAccount.Sales_Organization__c).substring(4) : initialAccount.Sales_Organization__c;
            for(Apttus_Config2__PriceList__c priceList : [Select id from Apttus_Config2__PriceList__c where APTS_SalesOrg__c =: accSalesOrg ]){
                oOrder.Apttus_Config2__PriceListId__c = priceList.Id;
            }*/ 
            //Defect#6048 Setting PriceList in the DebitOrder from APTS_DefaultPriceList class.          
            APTS_DefaultPriceList oDefaultPriceList = new APTS_DefaultPriceList();
            oOrder.Apttus_Config2__PriceListId__c = oDefaultPriceList.getDefaultPriceListId(initialAccount);
            
            Database.insert(oOrder);
            pageRef = new ApexPages.StandardController(oOrder).view();
            return pageRef;
        }catch(Exception ex){
            APTS_CustomLogging.createErrorLog(ex.getTypeName(), APEX, ex.getMessage() , ACCOUNT , ApexPages.currentPage().getParameters().get(Label.APTS_Id),BIR,false,false,null,true);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, EXCEPTION_OCCURED+ex.getMessage()));
            return null;
        }
    }
     
    /** Method Name : back()
    * Description : Will redirect to Account Header detail page
    **/   
    public PageReference back() {
        try{
            return new PageReference(SLASH + accountId);
        }catch(Exception ex){
            APTS_CustomLogging.createErrorLog(ex.getTypeName(), APEX, ex.getMessage() , ACCOUNT , ApexPages.currentPage().getParameters().get(Label.APTS_Id),BIR,false,false,null,true);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, EXCEPTION_OCCURED+ex.getMessage()));
            return null;
        }
    }
}