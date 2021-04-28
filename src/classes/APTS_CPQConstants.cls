/*******************************************************************************************************************
* @author       Karan Khatri
* @date         13th April 2018
* @description  Storing CPQ string constants
********************************************************************************************************************/
public class APTS_CPQConstants {

    //Constructor for code coverage since variables are not considered for code coverage
    public APTS_CPQConstants(){}
    
    //Labels
    public static final String LABEL_PROMOTION = 'Promotion';
    public static final String LABEL_TPR = 'TPR';
    public static final String LABEL_BUCKET1 = 'Bucket 1';
    public static final String LABEL_BUCKET2 = 'Bucket 2';
    public static final String LABEL_BUCKET3 = 'Bucket 3';
    public static final String LABEL_BUCKET4 = 'Bucket 4';
    public static final String LABEL_BUCKET5='Bucket 5';
    public static final String LABEL_BUCKET6='Bucket 6';
    public static final String LABEL_ConsignmentIngredients = 'Consignment Ingredients';
    public static final String LABEL_COUPANS_LOYALTY = 'ZP10';
    public static final String LABEL_TPR_100_DISCOUNT = 'ZX05';
    public static final String LABEL_ZX10 = 'ZX10';
    public static final String LABEL_SUB_TYPE_PROMOTION = 'ZP08';
    public static final String LABEL_PRICING_PENDING = 'Pending';
    public static final String LABEL_ORDER = 'Order';
    public static final String LABEL_OBD ='Order Based Discount';
    public static final String LABEL_OBD_API ='Z618';
    public static final String LABEL_AGREEEMENT = 'Agreement';
    public static final String SALES_PRICE = 'Sales Price';
    public static final String SERVICE_FEE = 'Service Fee';
    public static final String RENTAL_FEE = 'Rental Fee';
    public static final String CONSUMPTION = 'Consumption';
    public static final String CONSUMPTION_CATEGORY = 'Consumption Category';
    public static final String PPR = 'PPR';
    public static final String PPR_ZP06 = 'ZP06';
    public static final String DISCOUNT = '% Discount';
    public static final String NO_CATEGORY = '-- No Category Associated --';
    public static final String LABEL_COFFEE = 'Coffee';
    public static final String LABEL_CONVERSIONMACHINES = 'Conversion Machines';
    public static final String LABEL_TEA = 'Tea';
    public static final String LABEL_MACHINE = 'Machine';
    public static final String LABEL_SERVICE = 'Service';
    public static final String LABEL_MACHINES = 'Machines';
    public static final String LABEL_SERVICES = 'Services';
    public static final String LABEL_INGREDIENTS= 'Ingredients';
    public static final String LABEL_YOCI = 'YOCI';
    public static final String LABEL_YOFT = 'YOFT';
    public static final String LABEL_OPERATINGSERVICE = 'Operating Service';
    public static final String LABEL_CONCEPTS= 'Concepts';
    public static final String PIECE_UOM_API= 'SAP_PCE';
    public static final String LABEL_PIECE= 'Piece';
    public static final String TAX_DISP_CODE= 'Z619';
    public static final String LABEL_ONE_TIME= 'One Time';
    public static final String LABEL_MONTHLY= 'Monthly';
    public static final String LABEL_BILL_IN_ADVANCE= 'Bill In Advance';
    public static final String LABEL_BILL_IN_ARREARS= 'Bill In Arrears';
    public static final string PRODUCT2 = 'Product2';
    public static final string PRICELISTITEM = 'Apttus_Config2__PriceListItem__c';  
    public static final string INITIAL = 'Initial';
    public static final string OUTBOUNDTRIGGERED = 'Outbound Message Triggered';
    public static final string LABEL_YES = 'Yes';
    public static final String BOX_UOM_API= 'SAP_BX';
    public static final String KG_UOM_API= 'SAP_KGM';
    public static final String LABEL_PRICING_COMPLETE= 'Complete';
    public static final String PROD_SERV_LABEL = 'Product/Service';
    public static final String TIERED_RATE_LABEL = 'Tiered Rate';
    public static final String PER_UNIT  = 'Per Unit';
    public static final String USAGE_LABEL = 'Usage';
    public static final String DIGITAL_ORDER = 'Digital Order';
    public static final String ROUTE_SALES_ORDER = 'Route Sales Order';
    public static final String OPERATING_ORDER = 'Operating Order';
    public static final String TECH_SERV_OGI = '0201';
    public static final String CONNECTIVITY_SYSTEMS_OGI = '0106';
    public static final String CONNECTED_COFFEE_MACHINES_OGI = '0206';
    public static final String MACHINES_SCI = '04';
    public static final String EMPTY_STRING = ' ';
    //URL parameters

    // SEPERATORS
    public static final String PIPE_SIGN = ' | ';
    
    
    // Modified by Saranya Rajagopal Date: 13th sep 2018 
    
    public static final String COMMA_SIGN = ',';
    public static final String DOUBLE_SIGH ='"';
    public static final String SPACE_SIGN = ''; 
    public static final String HI_FUN = '-'; 
    public static final String BACKSPACE_SIGN = '/';
    public static final String LABEL_EFF = 'EFF';
    public static final String LABEL_BDF = 'BDF';
    public static final String LABEL_BMC = 'BMC';
    public static final String LABEL_BIR = 'BIR';
    public static final String LABEL_FIXED_TERM = 'Fixed Term';
    public static final String LABEL_DATE_LIMIT = 'Dates should be within Agreement Dates Limit between';
    public static final String LABEL_ANDD ='AND';
    public static final String LABEL_DELETED ='Else this Adjustment will be deleted';
    public static final String LABEL_Exist_Agreement ='No configuration exists for the Agreement';
    public static final String LABEL_Message ='No Machine selected for the configuration';
    public static final String LABEL_Saved ='Saved';
    public static final String LABEL_Flow='flow';
    public static final String LABEL_CONFIGID='configRequestId';
    public static final String LABEL_ID ='id';
    public static final String LABEL_ADJUSTMENTLINEITEM='Adjustment Line Item';
    public static final String SALE_TGR_HDLR = 'APTS_SalesOrgDataTriggerHandler ';
    public static final String DIRECT = 'Direct';
    public static final String EX_ABHI_MAIL = 'abhishek.kolipey@accenture.com, v.shankaranarayanan@accenture.com';
    public static final String PRD_CONFIG = 'Product Configuration';
    public static final String EX_JO_MAIL ='ajoshi@apttus.com';
    public static final String SCRIPTVAR ='<script> disableAll(); </script>';
    public static final String CLOSE_SCRIPTVAR = '<script> closeWindow(true,false); </script>';
    public static final String CLOSE_SCRIPTVAR2 = '<script> closeWindow(false,true); </script>';
    public static final String CLOSE_SCRIPTVAR3 = '<script> closeWindow(false,false); </script>';
    public static final String LABEL_PRODUCT_TRANSLATION='Product Translation';
    public static final String LABEL_ADJUSTSCOERAGECONTROLLER='APTS_AdjustTSCoverageController';
    public static final String LABEL_AGREEMENTMESSAGE='No Technical Services Configuration is there for this Agreement';
    public static final String LABEL_PENDINGBILLING='Pending Billing';
    public static final String LABEL_INVOICED='Invoiced';
    public static final String LABEL_OPTION='Option';
    public static final String LABEL_RECURRING='Recurring';
    public static final String LABEL_FREEONLOAN='Free On Loan';
    public static final String LABEL_ACTIVATED='Activated';
    public static final String LABEL_RENEWED='Renewed';
    public static final String PENALTY='Penalty Calculation';
    public static final String EXCEPTIONMESSAGE ='Exception Occurred Please Try Again';
    public static final String APTS_PROD_TRANS = 'APTSProdTranslationForDigitalIntegration';
    public static final String APTS_CONFIG_PROD_TRANS = 'Apttus_Config2__ProductTranslation__c';
    public static final String APTS_ADJUST_LI = 'APTS_AdjustmentLineItemCallback';
    
    //******************************************* // Rajesh Added 
    
    public static final String AGREEMENT_ID = 'Apttus_CMConfig__AgreementId__c';
    public static final String NUM_REC = 'numRec';    
    // Exception     
    public static final String APEX_NAME ='Apex';
    public static final String INCENTIVE ='Incentive';
    public static final String EXCEPTION_ID ='';
    public static final String CPQ ='CPQ';
    public static final String CPQ_ERROR_EMAIL='cpqerror@accenture.com';
    
    //  APTS_CalculateTaxesCtrl
    
    public static final String TAX_ID= 'id';
    public static final String NRML_ID= 'id';
    public static final String FLOW = 'flow';
    public static final String CONFIG_REQUEST_ID = 'configRequestId'; 
    public static final String LAUNCH_STATE = 'launchState';
    public static final String CART = 'cart';
    public static final String LINE_ITEM = 'Line item';
    public static final String BSN_OBJ_ID = 'businessObjectId';
    public static final String KK_EAMIL = 'kkhatri@apttus.com, shahul.nizam.moideen@accenture.com'; 
       
    // APTS_CustomLogging
    
    public static final String TEST_MAIL = 'test@test.com';
    public static final String EAMIL_CONTENT = 'Exception Occurred for ';
    public static final String CONTENT1 = ' of type ';
    public static final String CONTENT2 = 'Hi<br></br>Please find below the Exception that has occurred ';
    public static final String CONTENT3 = '<br></br><b>Name</b> : ';
    public static final String CONTENT4 = '<br></br><b>Object Name</b> : ';
    public static final String CONTENT5 = '<br></br><b>Object Id</b> : ';
    public static final String CONTENT6 = '<br></br>';
    public static final String CONTENT7 = 'Apttus Admin';
    
    // APTS_PriceListItemTriggerTest
    
    public static final String NL = 'NL';
    public static final String ALISE = 'standt';
    public static final String USR_EMAIL = 'ample@testUser.com';
    public static final String USR_ENCODING_KEY = 'UTF-8';
    public static final String USR_LNAME = 'Testing';
    public static final String USR_LNG_KEY = 'en_US';
    public static final String USR_TIMEZONE = 'America/Los_Angeles';
    public static final String USR_NAME = 'sample@testUserjde.com';
    public static final String USR_SALES_ORG = 'SAP_0333';
    
    //  APTS_ProductRedistributionBatch_Test
    
    public static final String PRD_NAME = 'Response Time 16';
    public static final String PRD_NAME1 = 'MACHINE DETAILS';
    public static final String PRD_NAME2 = 'TEST';
    public static final String PRD_CODE = 'P111456';
    public static final String PRD_SALE_CAT = '040198,04';
    public static final String PRD_OPTION_INDICATOR = '0301';
    public static final String PRD_TYPE = 'Bundle';
    public static final String PRD_MATERIAL_TYPE = 'ZOPT';
    public static final String PRD_MATERIAL_TYPE1 = 'ZSER';
    public static final String PRD_BL = 'BL';
    public static final String PRD_HI = 'HI';
    public static final String PRD_SALS_ORG = 'SAP_0333';
    public static final String PRD_SALES_CAT = '00';
    public static final String PRD_OPTION_INDI = '04';
    public static final String PRD_NME = 'ALL IN COVERAGE';
    public static final String PRD_GRP_INDI = '020178'; 
    public static final String CAT_HYR = '040198';
    public static final String CAT_HYR_OPTION1 = '0301';   
    public static final String EXPRES_TEST = 'Expression for Test';
    public static final String TEST_TRANS = 'Test Trans';
    public static final String BL_SAP_01= 'BL|SAP_01';
    public static final String TEST_ATT_GRP = 'Test Attribute Group';
    public static final String APTS_PAV = 'Apttus_Config2__ProductAttributeValue__c';
    public static final String AG_MACH = 'AG|MACHINEDETAILS';
    public static final String TEST_NM = 'Test';
    public static final String TEST_PRD_GRP = 'Test Product Group';
    public static final String PG_RES = 'PG|RESPONSETIME16HRS';
    public static final String AG_ONETIME = 'AG|ONETIMEPURCHASE';
    public static final String SAP_01 = 'SAP_01';
    public static final String TEST_SALES_ORG = 'Test Sales Org Data';
    public static final String CODE_0333 = '0333';
    public static final String PG_OFFERING = 'PG:Offering:040198';
    public static final String PG_COFFEE = 'PG|COFFEEBEANSRR';
    public static final String PG_OFFER_O4 = 'PG:Offering:04';    
    public static final String PG_MACH = 'PG|MACHINEINSTANTRR';
    public static final String AG_OFFERING = 'AG:Offering:04';
    public static final String AG_MATCH = 'AG|MACHINEDETAILS';
    public static final String PG_NAME_TIME = 'PG:NAME:ResponseTime16';    
    public static final String AG_OPTION = 'AG:Option:0102';
    public static final String AG_NAME = 'AG:NAME:All';
    public static final String AG_ALLINCOVERAGE = 'AG|ALLINCOVERAGE';
    
    
    // APTS_PenaltyCalculationCtrl  
    public static final String PRD_CONFIG1 = 'prodconfig';
    public static final String IDS = 'ids';
    public static final String AT_THE_RATE = '@';
    public static final String EX_OCCUR = 'Exception Occurred Please Cancel the Operation and Try Again';
    public static final String NET_PRICE = 'Apttus_Config2__NetPrice__c';
    public static final String AGR_ID = 'agrid';
    public static final String URL ='/apex/APTS_AssetInstalledProducts?id=';
    public static final String URL1 = '&businessObjectId=';
    public static final String ABHI_MAIL = 'abhishek.kolipey@accenture.com';
    
    
    //APTS_CreditMemoLineItemHandlerTest   
    
    public static final String ACC_NAME = 'Test Account';
    public static final String TEST_LOC = 'Test Loc';
    public static final String PART_FULFILL = 'Partially Fulfilled';
    public static final String DRAFT = 'Draft';
    public static final String TESTCOFFEE = 'TestCoffee';
    public static final String ONE23 = '123';
    public static final String STANDALONE = 'Standalone';
    
    //APTS_VolumeObligationTriggerHandler
    public static final String SUBSUBCATEGORY = 'SubSubCategory';
    public static final String SUBCATEGORY = 'SubCategory';
    public static final String PRODUCT = 'Product';
    public static final String ROUTESALES = 'Routesales';
    public static final String LSP = 'LSP';
    public static final String INDIRECT_CHANNEL = 'Indirect channel';
    
    //APTS_RegenerateDiscountsController
    public static final String CER_INSERT = 'Insert';
    public static final String CER_UPDATE = 'Update';
    public static final String CER_DELETE  = 'Delete';
    public static final String CER_TERMINATED = 'Terminated';
    public static final String ORDERSUBTYPEINDEXATION= 'Indexation';
   
    //*************************************************

}