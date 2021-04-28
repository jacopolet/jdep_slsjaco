//-------------------------------------------------------------------------------------------//
// Author       :   C.ARAGON - Accenture
// Created Date :   March 03, 2017
// Usage        :   Constant Class for Sales and Marketing Team
//-------------------------------------------------------------------------------------------//
@isTest
public class SM_Constants {
    
    //Author: C.ARAGON - Accenture
    //Usage: Constant for recordtype of account record.
    public static String EndCustomerValidation = 'Customer Validation';
    public static String EndAdministrativeAddressValidation = 'Administrative Address Validation';
    public static String Customer = 'Customer';
    public static String AdministrativeAddress = 'Administrative Address';
    public static String Prospect = 'Prospect';
    public static String ProspectInvalid = 'Prospect Invalid';
    public static String ProspectValid = 'Prospect Valid'; //Alvin
    public static final string CREDITWORTHINESS_FLAG_RED = 'Red';
    public static String JDECompany = 'JDE Company';
    public static String Supplier = 'Supplier';
    public static String Competitor = 'Competitor';
    public static String PurchasingOrg = 'Purchasing Organization';
    public static String AccountServiceProvider = 'Operational Account';
    public static String PromotionRequested = 'Promotion Requested';
    public static String AdministrativeAddressValid = 'Administrative Address Valid';
    public static String AdministrativeAddressInvalid = 'Administrative Address Invalid';
	
	public static Id AutomatedTask = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
	
	//Usage: Get record type id of account
	public static Id recordTypeIdCustomer = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.Customer).getRecordTypeId();
	public static Id recordTypeIdProspectInvalid = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.ProspectInvalid).getRecordTypeId();
	public static Id recordTypeIdPromotionRequested = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.PromotionRequested).getRecordTypeId();
    public static Id recordTypeIdAccountServiceProvider =  Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.AccountServiceProvider).getRecordTypeId();
    public static Id recordTypeIdProspectValid = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.ProspectValid).getRecordTypeId();
    public static Id recordTypeIdAdministrativeAddressValid = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.AdministrativeAddressValid).getRecordTypeId();
    public static Id recordTypeIdEndCustomerValidation = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.EndCustomerValidation).getRecordTypeId();
	public static Id recordTypeIdAdministrativeAddress = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.AdministrativeAddress).getRecordTypeId();
	public static Id recordTypeIdAdministrativeAddressValidation = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.EndAdministrativeAddressValidation).getRecordTypeId();
    public static Id recordTypeIdServiceProvider = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.AccountServiceProvider).getRecordTypeId();
    public static Id recordTypeIdCompetitor = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.Competitor).getRecordTypeId();
    public static Id recordTypeIdAdministrativeAddressInvalid = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.AdministrativeAddressInvalid).getRecordTypeId();
    public static Id recordTypeIdProspect = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.Prospect).getRecordTypeId();
    
    //Account Location record type ID
    public static Id recordTypeIdAccountLocationValidation = Schema.SObjectType.Apttus_Config2__AccountLocation__c.getRecordTypeInfosByName().get('Account Location Validation').getRecordTypeId();
    public static Id recordTypeIdAccountLocation = Schema.SObjectType.Apttus_Config2__AccountLocation__c.getRecordTypeInfosByName().get('Account Location').getRecordTypeId();
    
    //Usage: Constant for recordtype of account location
    public static String AccountLocationRO = 'Account Location RO';
    
    //Usage: Constant for recordtype of contact record.
    public static String ContactServiceProvider = 'Operational Contact'; 
    public static String ContactStandard = 'Contact Standard';
    
    //Usage: Update Request Logic Status.
    public static String UpdateRequestValidated = 'Request Updated';
    public static String NoUpdateRequest = 'No Update Request';
    public static String UpdateRequestValidationRequired = 'Update Request Validated';
    public static String UpdateRequestValidationReq = 'Update Request Validation Required';
    public static String UpdateRequestDeclined = 'Update Request Declined';
    public static String ApprovalPending = 'Approval Pending';
    public static String ApprovalDeclined = 'Approval Declined';
    public static String ApprovalApproved = 'Approval Validated';
    public static String ApprovalRecall = 'Approval Recalled';
    public static String SAPIntegSuccessful = 'SAP Integration Successful';
    public static String SAPIntegFailed = 'SAP Integration Failed';
    
    //Usage: Profile Names
    public static String SystemAdmin = 'System Administrator';
    public static String SystemDev = 'System Developer';
    public static String PRFSales = 'PRF Sales';
    public static String JDEEndUser = 'JDE - End User - Basic Internal';
    public static String JDEDigital = 'JDE-Integration-Digital';
	public static String JDESAP = 'JDE-Integration-SAP';
    public static String JDECTI = 'JDE-Integration-CTI';
    public static String JDEMARKETING = 'JDE-Integration-Marketing Cloud';
    
    //Author: J.SAMANIEGO - Accenture
    //Usage: Constant for recordtype of account value estimation record.
    public static String AVEPrice = 'Account Value Estimation Price P';
    public static String AVESize = 'Account Value Estimation Size Q';
    
    //Author: J.AZANA - Accenture
    //Usage: Constants for automatic oppotunity creation when using the 'New Quote with Opportunity' button
    public static final String CurrencyIsoCodeValue = 'EUR';
    public static final String GoToMarketValue = 'Direct';
    public static final String NameValue = 'Name';
    public static final String RecTypeNameValue = 'Standard Opportunity';
    public static final String StageNameValue = 'Open';
    public static final String TypeValue = 'Prospect';
    
    public static final String OppPrfPartnerRT = 'PRF Partner Opportunity'; 
    public static final String OppTenderRT = 'Tender Opportunity';
    public static final String OppStandardRT = 'Standard Opportunity';
    
    //Author: G.Serrano
    //Usage Constants for Case and Physical Asset

    public static final String qualifyCaseRTlabel = 'Qualify Case';
    public static final String machinePhysicalAssetRTlabel = 'Machine';

    //Author: G.Serrano
    //Usage get record Type if or opportunity
    
    public static Id recordTypeIdStandardOpportunity = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(SM_Constants.OppStandardRT).getRecordTypeId();
    
    //Usage get Qualify Case record type ID / Physical Asset Record Type ID
    public static Id recordTypeIdQualifyCase = Schema.SObjectType.Case.getRecordTypeInfosByName().get(SM_Constants.qualifyCaseRTlabel).getRecordTypeId();
    public static Id recordTypeIdMachine = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get(SM_Constants.machinePhysicalAssetRTlabel).getRecordTypeId();

    //Author: J.AZANA - Accenture
    //Usage: Constants for account territory assignment
    public static final String modelRecTypeGenerating = 'Territory Model Generating';
    public static final String modelRecTypeGenerated = 'Results Generated';
    public static final String modelRecTypeCompleted = 'Completed';
    public static final String modelStatusGenerating = 'Generating Results (Preview)';
    public static final String modelStatusGenerated = 'Results Generated (Preview)';
    public static final String modelStatusApplying = 'Applying on Accounts';
    public static final String modelStatusComplete = 'Complete';
    public static final String modelStatusDeleteFailed = 'Failed to Delete Existing Results';
    public static final String modelStatusGenerateFailed = 'Failed to Generate Results';
    public static final String modelStatusApplyFailed = 'Failed to Apply on Accounts';
    
    //Author: C.ARAGON - Accenture
    //Usage: Constants for Contact Strategy
    public static String NLSB = 'NL Small Business';
    public static String NLMB = 'NL Medium Business';
    public static String FRA = 'Task Queue France';
    public static String ESP = 'Task Queue Spain';
    public static String IRL = 'Task Queue Ireland';
    public static String DEU = 'Task Queue Germany';
    public static String GBR = 'Task Queue United Kingdom';
    public static String BEL = 'Task Queue Belgium';
    public static String DNK = 'Task Queue Denmark';
    public static String SWE = 'Task Queue Sweden';
    public static String NOR = 'Task Queue Norway';
    public static String queue = 'Queue';
    public static String Netherlands = 'Netherlands';
    public static String Belgium = 'Belgium';
    public static String Ireland = 'Ireland';
    public static String Sweden = 'Sweden';
    public static String Denmark = 'Denmark';
    public static String Germany = 'Germany';
    public static String Spain = 'Spain';
    public static String GB = 'Great Britain';
    public static String UK = 'United Kingdom';
    public static String Norway = 'Norway';
    public static String SystemAdministrator = 'System Administrator';
    public static String InsufficientDeletion = 'You cannot delete this record. Insufficient Access';
    public static String dateFormat = 'MMM';
    public static String accountPrefix = '001';
    public static String accountLocationPrefix = 'a2R';
    public static String contactPrefix = '003';
    public static String queuePrefix = '00G';
    public static String oppPrefix = '006';
    public static String NPSPrefix = 'a7B';
    public static String casePrefix = '500';
    public static String leadPrefix = '00Q';
    public static String EXP = 'EXP';
    public static String FOLLUP = 'FOLL UP';
    public static String RM = 'RM';
    public static String MPO = 'MPO';
    public static String RMMPO = 'RM + MPO';
    public static String CAMP = 'CAMPAIGN';
    public static String INBOUNDCALL = 'INBOUND CALL';
    public static String ONLINEINFORMATIONREQUEST = 'ONLINE INFORMATION REQUEST';
    public static String ONLINEQUOTEREQUEST = 'ONLINE QUOTE REQUEST';
    public static String REFERRALPARTNER = 'REFERRAL PARTNER';
    public static String REFERRALEMPLOYEE = 'REFERRAL EMPLOYEE';
    public static String REFERRALTECHNICIAN = 'REFERRAL TECHNICIAN';
    public static String REFERRALROUTESALES = 'REFERRAL ROUTESALES';
    public static String REFERRALCUSTOMER = 'REFERRAL CUSTOMER';
    public static String REFERRALBUYINGGROUP = 'REFERRAL BUYING GROUP';
    public static String COLDAQCUISITION = 'COLD AQCUISITION';
    public static String TAILORMADEAGREEMENT = 'TAILOR-MADE AGREEMENT';
    public static String STANDAGREEMENT = 'STAND AGREEMENT';
    public static String CMDCHANGE = 'CMD CHANGE';
    public static String SIGNEDCONTRACT = 'SIGNED CONTRACT';
    public static String GENERICREQUEST = 'GENERIC REQUEST';
    public static String REPORTREQUEST = 'REPORT REQUEST';
    public static String CONTACTREQUEST = 'CONTACT REQUEST';
    public static String OTHERREQUEST = 'OTHER REQUEST';
    public static String ONLINEINFORMATIONREQUESTMC = 'ONLINE INFORMATION REQUEST MC';
    public static String ONLINEQUOTEREQUESTMC = 'ONLINE QUOTE REQUEST MC';
    public static String ENDWARR = 'END WARR';
    public static String PROMOTION = 'PROMOTION';
    public static String NEWPRODUCTINTRO = 'NEW PRODUCT INTRO';
    public static String CROSSUPSELL = 'DEEP/CROSS/UP SELL';
    public static String PRODUCTCHANGE = 'PRODUCT CHANGE';
    public static String TRADESHOWEVENT = 'TRADE SHOW/EVENT';
    public static String NEWSTARTEDCOMPANY = 'NEW STARTED COMPANY';
    public static String COMPANYCHANGE = 'COMPANY CHANGE';
    public static String PROSPECTLIST = 'PROSPECT LIST';
    public static String NPS = 'NPS';
    public static String WARMWELCOMEFOLLUP = 'WARM WELCOME FOLL UP';
    public static String FIRSTORDERSURVEY = 'FIRST ORDER SURVEY';
    public static String AFTINSTAL = 'AFT INSTAL';
    public static String MOVEMNT = 'MOVEMNT';
    public static String MPV = 'MPV';
    public static String KPISLA = 'KPI-SLA CHECK';
    public static String BUDGETS = 'BUDGET CHECK';
    public static String ONETIMEBONUS = 'ONE-TIME BONUS';
    public static String INDEXATION = 'INDEXATION NON STD';
    public static String RENTBUY = 'RENT-BUY';
    public static String PONUMBER = 'P.O. NUMBER REQUEST';
    public static String VOLUMEOBLIGATION = 'VOLUME OBLIG CHECK';
    public static String FIXEDPAYMENTTERMS = 'FIXED PAYMENT TERMS';
    public static String SELLOUTDATA = 'SELL-OUT DATA';
    public static String TT = ' [Touchpoint Type] ';
    public static String CAL = ' [Contract Asset Lifetime]';
    public static String RTAutomated = 'Automated';
    public static String RTInbound = 'Inbound';
    public static String Email = 'Email';
    public static String OUTBOUNDCALL = 'OUTBOUND CALL';
    public static String SUBSCRORDER = 'SUBSCR ORDER ALERT';
    public static String CREDITLIMITALERT = 'CREDIT LIMIT ALERT';
    public static String VOLUMEOBLIGSETTL = 'VOLUME OBLIG SETTL';
    public static String KPISLASETTL = 'KPI-SLA SETTL';
    public static String FIXEDTERMCHECK = 'FIXED TERM CHECK';
    public static String FIXEDTERMSSETTL = 'FIXED TERMS SETTL';
    public static String AGREEMENTRENEWAL = '3+1+1 AGREEMENT RENEWAL';
    public static String ASSETRENEWAL = '3+1+1 ASSET RENEWAL';
    public static String ASSETSCHECKAGREEMENT = 'TERMINATED ASSETS - CHECK AGREEMENT';
    public static String ASSETTERMINATIONCMR = 'RENEWED ASSET TERMINATION CMR';
    public static String INDEXATIONNONSTD = 'INDEXATION NON STD';
    public static String CASEFOLLUP = 'CASE FOLL UP';
    public static String ACCOUNTBLOCKRELEASE = 'ACCOUNT BLOCK RELEASE REQUEST';
    public static String CALLLISTINGREDIENTS = 'CALL LIST INGREDIENTS';
    public static String ROUTESALESRESCHEDULING = 'ROUTE SALES RESCHEDULING';
    public static String ONLINEMASTERDATACHANGE = 'ONLINE MASTER DATA CHANGE REQ';
    public static String MACHINECASEWITHNOWARRANTY = 'MACHINE CASE WITH NO WARRANTY';
    public static String INSTALLATIONDEINSTALLATION = 'INSTALLATION / DE-INSTALLATION';
    public static String MOVEMENTADMIN = 'MOVEMNT (ADMIN)';
    public static String BREAKDOWN = 'BREAKDOWN';
    public static String MACHINESWAP = 'MACHINE SWAP';
    public static String COUNTERREADINGS = 'COUNTER READINGS';
    public static String EINVOICINGREQUEST = 'E-INVOICING REQUEST';
    public static String MANUAL = 'MANUAL';
    public static String REMINDER = 'REMINDER';
    public static String CREDITCHECK = 'CREDIT CHECK';
    public static String ONLINEGENERALREQUESTMC = 'ONLINE GENERAL REQUEST MC';
    public static String ONLINECAMPAIGN  = 'ONLINE CAMPAIGN';
    public static String LEADNURTURING = 'LEAD NURTURING';
    public static String CONVERSIONMACHINE = 'CONVERSION (MACHINE)';
    public static String CONVERSIONSERVICE = 'CONVERSION (SERVICE)';
    public static String SAP0111 = 'SAP_0111';
    public static String SAP6706 = 'SAP_6706';
    public static String SAP0080 = 'SAP_0080';
    public static String SAP6709 = 'SAP_6709';
    public static String SAP6712 = 'SAP_6712';
    public static String SAP6750 = 'SAP_6750';
    public static String SAP0333 = 'SAP_0333';
    public static String SAP0975 = 'SAP_0975';
    public static String SAP0976 = 'SAP_0976';
    public static String SAP6864 = 'SAP_6864';


    //Author: A.LOMOD = Accenture
    //Usage: Constants for Lead
    public static final String LeadRecTypePRFPartner = 'PRF Partner Lead';
    public static final String LeadRecTypeStandard = 'Standard Lead';
    
    //Usage: Constants for Opportunity
    public static final String OpptRecTypeTender = 'Tender Opportunity';
    public static final String OpptRecTypeStandard = 'Standard Opportunity';
    
    //Author: G.Serrano = Accenture
    //Usage: Constants for Sic Codes
    public static String HighSegmentBiz = 'Business';
    public static String HighSegmentHC = 'Health & Care';
    public static String HighSegmentEduc = 'Education';
    public static String HighSegmentResBar = 'Rest. Cafes & Bars';
    public static String HighSegmentHotGam = 'Hotels and Gaming';
    public static String HighSegmentQckCof = 'Quick Ser & Coffee';
    public static String HighSegmentConRet = 'Convenience & Retail';
    public static String HighSegmentLeis = 'Leisure';
    public static String SPKLSmallB = 'SAP_A';
    public static String SPKLMediumB = 'SAP_B';
    public static String SPKLLargeB = 'SAP_C';
    public static String SPKLHealth = 'SAP_D';
    public static String SPKLEduc = 'SAP_E';
    public static String SPKLResBar = 'SAP_F';
    public static String SPKLHotGam = 'SAP_G';
    public static String SPKLQckCof = 'SAP_H';
    public static String SPKLConRet = 'SAP_I';
    public static String SPKLLeis = 'SAP_J';
    public static String SSHealthServices = 'Health and allied services';
    public static String SSDocDentEtc = 'Doctors, Dentists and other practitioners';
    public static String SSEducElemSec = 'Elementary and Secondary schools';
    public static String SSEducEtcEduc = 'Other Education';
    public static String SSEducEduc = 'Education';
    public static String InsufficientAddorUpdate = 'Insufficient access on inserting/updating customer record. Only country super user are allowed';
	
	//Account constant
	public static String NotValid = 'Not Valid';
    
    public static Map<String, String> fetchCountrySU(){

           Map<String, String> countrySU = new Map<String, String>();
           Country_SU__c csu = Country_SU__c.getInstance();           
           
           countrySU.put('Netherlands', csu.SU_Netherlands__c);
           countrySU.put('Belgium', csu.SU_Belgium__c);
           countrySU.put('Denmark', csu.SU_Denmark__c);
           countrySU.put('Germany', csu.SU_Germany__c);
           countrySU.put('Ireland', csu.SU_Ireland__c);
           countrySU.put('Spain', csu.SU_Spain__c);
           countrySU.put('Sweden', csu.SU_Sweden__c);
           countrySU.put('UK', csu.SU_UK__c);

        return countrySU;
    }

    //Author: Glenn
    //Data Use Purpose Strings
    public static String Marketing = 'marketing';
    public static String Survey = 'survey';
    public static String Profiling = 'profiling';
}