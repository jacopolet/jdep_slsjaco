/*************************************************************
@Name: APTS_OrderConstants
@Author: Rajesh Patel
@CreateDate: 22-10-2018
@Description: Storing Order Management string constants
@UsedBy: OM Apex Class
******************************************************************/
//Please follow alphabetical order
//v100 22-10-2018 Rajesh Patel: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes
//v101 9-Sept-2020 Sneha Jaiwant: DQ2456 Agreements with the end date in future

public without sharing class APTS_OrderConstants {

     //Constructor for code coverage since variables are not considered for code coverage
     public APTS_OrderConstants() {}

     public static final String AA = 'a';
     public static final String ACCOUNT = 'Account';
     public static final String ACCOUNT_STATUS = 'Valid';
     public static final String ACTIVATED = 'Activated';
     public static final String ADDITIONAL_FEE = 'Additional Fee';
     public static final String AID = 'aId';
     public static final String AFTER_SAP_INITIAL = ' after SAP receives initial and before delivery is created';
     public static final String AGREEMENT_NO_VALID_ASSET_CANCELLED = 'Agreement do not have any valid asset to be cancelled!';
     public static final String AMENDED = 'Amended';
     public static final String APEX = 'Apex';
     public static final String APTS_SAPWSSTRUCTURE = 'APTS_SAPWSStructure';
     public static final String APTS_EMAIL = 's.j.ramanathan@accenture.com,preetha.ramesh@accenture.com';
     public static final String ATP_IS_SUCCESSFUL = 'ATP is successful';
     public static final String ATP_NOT_SUCCESS = 'ATP is not successful';
     public static final String ATP_OK = 'ATP OK';
     public static final String ATTACHMENT = 'Attachment';
     public static final String AMENDORDER_PAGEMESSAGE = 'Please be aware that if you change the Requested Installation Date, the Requested Delivery Date will automatically be updated to take the country specific delivery off-set into account. If you wish to update the Requested Delivery Date seperately, please use the Amend Order functionality again and only update the Requested Delivery Date';
     public static final String AGREEMENT_STATUS_IN_EFFECT = 'In Effect';
     public static final String AGREEMENT_STATUS_ACTIVATED = 'Activated';

     public static final String BB = 'b';
     public static final String BEFORE_SAP_CREATE = ' before SAP creates delivery';
     public static final String BEING_AMENDED = 'Being Amended';
     public static final String BEING_RENEWED = 'Being Renewed';
     public static final String BILL_TO = 'Bill To';
     public static final String BUSINESSOBJECTID = 'businessObjectId';
     public static final String BUNDLE = 'Bundle';

     public static final String COMMA = ',';
     public static final String COMFORT_OPERATING = 'Comfort Operating';
     public static final String CANCELLED = 'Cancelled';
     public static final String CANCELED = 'Canceled';
     public static final String CONFIG_ID = 'configId';
     public static final String COMMERCIAL_SWAP = 'Commercial Swap';
     public static final String CONFIRM_QUANTY_LESS_THAN_REQ_QUANTY = 'Confirmed quantity less than requested quantity';
     public static final String CONSIGNMENT_ISSUE = 'Consignment Issue for FSD';
     public static final String CONSIGNMENT_FILLUP = 'Consignment Fillup for FSD';
     public static final String CONSUMPTION = 'Consumption';
     public static final String CONSUMPTION_MODEL = 'Consumption Model';
     public static final String CONVERSION = 'Conversion';
     public static final String CONVERSION_ORDER = 'Conversion Order';
     public static final String CUSTOMER_SIGNATURE = 'Customer Signature';
     public static final String CUSTOMER_SIGNATURES = 'CustomerSignature_';
     public static final String CARTPAGEURL = '/apex/Apttus_Config2__Cart?configRequestId={0}&id={1}&flow={2}&launchState=cart#/cart';
     public static final String CONCEPTS_COFFEEKITCHEN = 'Concepts | Coffee Kitchen';
     public static final String COFFEE = 'Coffee';
     public static final String COFFEE_KITCHEN = 'Coffee Kitchen';
     public static final String CS_QUEUE = 'CS Queue';
     public static final String COMPLETELY_PROCESSED = 'Completely processed';
     public static final String CLOSED = 'Closed';
     public static final String OPEN_CASE_VALIDATION_CANCELLATION = 'All cases related to Order must be closed before Cancelling Machine. Please close case number (s) ';

     public static final String DE_INSTALLATION = 'De-Installation';
     public static final String DEINSTALL = 'Deinstall';
     public static final String DEINSTALLURL = '/apex/APTS_DeInstallOrder';
     public static final String DEINSTALLATION_DATE = 'Please enter Requested DeInstallation Date.';
     public static final String DISCOUNT = '% Discount';
     public static final String DISCOUNT_AMOUNT = 'Discount Amount';
     public static final String DOT_PNG = '.png';
     public static final String DRAFT = 'Draft';
     public static final String DEVELOPER_NAME_SCH_RULES = 'Country_Scheduling_Rules';
     public static final String DEVELOPER_NAME_SCH_RULES_INGRI = 'APTS_Country_Scheduling_Rules_Ingredients';
     public static final String DEVELOPER_NAME_BUS_HOURS = 'CountryDefaultBusinessHours';
     public static final Set<String> DEVELOPER_NAME_SET = new Set<String> {DEVELOPER_NAME_SCH_RULES, DEVELOPER_NAME_SCH_RULES_INGRI, DEVELOPER_NAME_BUS_HOURS};

     public static final String EE = 'E';
     public static final String EMAIL = 'Email';
     public static final String ERROR_IN_ASSET_CANCELATION = 'Error in asset cancelation';
     public static final String ERROR_IN_CART = 'Error in cart creation';
     public static final String ERROR_IN_CHANGE_OF_ASSETS = 'Error in change of assets';
     public static final String ERROR_WHILE_REDIRECT_TO_CART = 'Error while redirecting to cart';
     public static final String ERROR_WHILE_SAVING_CART = 'Error while saving the cart';
     public static final String ERROR_WHILE_UPDATING_PHYSICAL_ASSET = 'Error while updating Physical Assets';
     public static final String ERROR_WHILE_UPDATING_LSP = 'Error while updating LSP Details';
     public static final String EXTERNAL= 'External';
     public static final String EXTERNAL_MOVEMENT_WITH_CONTRACT_CHANGE = 'External Movement With Contract Change';
     public static final String EXTERNAL_MOVEMENT_WITH_CONTRACT_CHANGE_URL = '/apex/APTS_ExternalMovementOrderWCC';
     public static final String EXTERNAL_MOVEMENT_WITHOUT_CONTRACT_CHANGE_URL = '/apex/APTS_ExternalMovementOrderWOCC';
     public static final String ENTER_PO_NUMBER_MANUALLY = 'Enter PO Number Manually';
     public static final String EXTERNAL_MOVEMENT_WITHOUT_CONTRACT_CHANGE = 'External Movement Without Contract Change';
     public static final String EXISTING = 'Existing';
     public static final String EXPIRED = 'Expired';
     public static final String ERROR_QUANTITY_UPDATE = 'Error in quantity update';
     public static final String ERROR_WHILE_REPRICING_CART = 'Error while repricing the cart';
     public static final String ERROR_WHILE_FINALIZING_CART = 'Error while finalizing order cart';
     public static final String ERROR_WHILE_SYNCHRONIZING_CART = 'Error while sunchronizing order cart';
     public static final String ERROR_WHILE_SELECTING_PRODUCT = 'Whoops!. Looks like Product not Selected Or Quantity is 0';

     public static final String FIRST_PARAM = 'firstParam';
     public static final String FREE_ON_LOAN = 'Free On Loan';
     public static final String FIXED = 'Fixed';
     public static final String FINALIZED = 'Finalized';
     public static final String FLOW = 'flow';
     public static final String FULL_CO_OPERATING = 'Full Co Operating';
     public static final String FULL_OPERATING = 'Full Operating';
     public static final String FULFILLED = 'Fulfilled';

     public static final String ID = 'Id';
     public static final String IN_EFFECT = 'In Effect';
     public static final String IN_FULFILLMENT = 'In Fulfillment';
     public static final String INGREDIENTS = 'Ingredients';
     public static final String INSTALL = 'Install';
     public static final String INSTALL_PRODUCT_URL = '/apex/Apttus_Config2__OrderConfiguration?flow=NGMachineSwapOrder&launchState=assets&id=';
     public static final String INSTALLATION = 'Installation';
     public static final String INSTALLATION_DATE = 'Please enter Requested Installation Date.';
     public static final String INTERNAL_MOVEMENT = 'Internal Movement';
     public static final String INTERNAL_MOVEMENT_URL = '/apex/APTS_InternalMovementOrder';     
     public static final String INVALID_ACTION = 'Invalid Action';
     public static final String INVALID_ORDER = 'Invalid Order';
     public static final String INVALID_ORDER_ID = 'Invalid Order ID';
     public static final String INSTALL_DATE_NEXTMONDAY = 'InstallDate must be set to next Monday';

     public static final String LABEL_NEW = 'New';
     public static final String LABEL_NULL = '';
     public static final String LOCID = 'LocId';

     public static final String MARKUP = '% Markup';
     public static final String MARKUP_AMOUNT = 'Markup Amount';
     public static final String MONDAY = 'Mon';
     public static final String MODULO = '%';
     public static final String MOVEMENT = 'Movement';
     public static final String MOVEMENT_TO_DETAIL = 'Please enter Movement To Details.';
     public static final String MACHINE = 'Machine';
     public static final String MACHINECARE = 'Machine Care';
     public static final String MACHINE_ORDER = 'Machine Order';
     public static final String ADMIN_ORDER = 'Admin Order';
     public static final String MACHINESPRODUCT = 'SAP_04';
     public static final String MORE = '&More';
     public static final String MATERIAL_TYPE = 'ZSPR';
     public static final String MATERIAL_TYPE_ZFIN = 'ZFIN';
     public static final String MATERIAL_TYPE_ZCMA = 'ZCMA';
     public static final Set<String> MACHINE_ORDER_AG_STATUS = new Set<String> {ACTIVATED, BEING_AMENDED, BEING_RENEWED};

     public static final String NGDEFAULT = 'NGDefault';
     public static final String NGRSO_ORDER = 'NGRSOOrder';
     public static final String NGRSO_ORDERWOC = 'NGRSOOrderWOC';
     public static final String NGSTANDARD_ORDERWOC = 'NGStandardOrderWOC';
     public static final String NGSTANDARD_ORDER = 'NGStandardOrder';
     public static final String NG_MACHINEORDER = 'NGMachineOrder';  
     public static final String NG_ADMINORDER = 'NGAdminOrder';   
     public static final String NG_MACHINESWAPORDER = 'NGMachineSwapOrder';
     public static final String NO_AGREEMENT = 'Agreement is mandatory for Machine Orders. Please go back to the Account, have your Agreement in place & then place Machine Orders.';
     public static final String NO_ORDER = 'There is no order to return!';
     public static final String NG_MACHINEDEINSTALLORDER = 'NGMachineDeinstallOrder';   
    

     public static final String OM = 'OM';
     public static final String ONE_AGREEMENT = 'Select only one Agreement!';
     public static final String OPTION = 'Option';
     public static final String ORDER = 'Order';
     public static final String ORDER_CAN_ONLY = 'Order can only';
     public static final String ORDER_TYPE_OPERATING = 'Operating Order';
     public static final String ORDER_TYPE_ROUTESALES = 'Route Sales Order';
     public static final String ORDER_TYPE_DIGITAL = 'Digital Order';
     public static final String ORDER_TYPE_SUBSCRIPTION = 'Subscription Order';

     public static final String PAYER_TO = 'Payer To';
     public static final String PARTIALLY_FULFILLED = 'Partially Fulfilled';
     public static final String PENDING = 'Pending';
     public static final String PNG = 'png';
     public static final String POSITIVE_RETURN_QUANTITY = 'Return Quantity must be greater than 0!';
     public static final String PRICE_OVERRIDE = 'Price Override';
     public static final String PRIMARY_L1_ITEM = 'There is no Primary L1 Line!';
     public static final String PRODUCT_MANDATORY = 'Select at least one product to return!';
     public static final String PRODUCT_OR_SERVICE = 'Product/Service';
     public static final String PRODUCTS_FROM_ONE_ORDER = 'Select products from only one Order!';
     public static final String PO_HAS_EXPIRED = 'PO has expired';
     public static final String PARTIALORDERBATCH = 'PartialOrderBatch';
     //v101
     public static final String Past_EndDate = 'There is no active agreement with an end date in the future for this account';
     

     public static final String RENT = 'Rent';
     public static final String RENTAL_FEE = 'Rental Fee';
     public static final String RENTBUY = 'RentBuy';
     public static final String REJECT_REASON_REQ = 'Please enter reject reason before submit order to SAP';
     public static final String REQUEST_DEINSTALLATION_DATE_ON_MONDAY = 'Requested DeInstallation Date must be set to next Monday.';
     public static final String REQUEST_INSTALLATION_DATE_ON_MONDAY = 'Requested Installation Date must be set to next Monday.';
     public static final String REQUESTED_DATE_NOT_BLANK = 'Requested Date must not be blank.';
     public static final String RESPONSE_X = 'response_x';
     public static final String RETURNED = 'Returned';
     public static final String RETURN_QUANTITY_SHOULD_BE_LESS = 'Return Quantity cannot be greater than Fulfilled Quantity!';
     public static final String RSOAPP = 'RSOApp';
     public static final String RSO_ORDER_URL = '/RSOOrder/CustomerSignature/*';
     public static final String REQUIRED_DEINSTALL_DATE = 'De-InstallDate is required field';
     public static final String REQUIRED_INSTALL_DATE = 'InstallDate is required field';
     public static final String REORDER = 'Reorder';
     public static final String RENEWED = 'Renewed';
     public static final String REGISTRATION_FORM = 'Registration Form';
     public static final Decimal ROUNDOFF_RANGE_FROM_VALUE = 0.5;
     public static final Decimal ROUNDOFF_RANGE_To_VALUE = 0.4;
              
     public static final String SALES = 'Sales';
     public static final String SALES_PRICE = 'Sales Price';     
     public static final String SELECT_AN_AGREEMENT = 'Select an Agreement!';
     public static final String SEMI_OPERATING = 'Semi Operating';
     public static final String SERIAL_NUM = 'serialNum';
     public static final String SERVICE_CONTACT_FROM = 'Please enter Service Contact From.';
     public static final String SERVICE_CONTACT_TO = 'Please enter Service Contact To.';
     public static final String SERVICE_CONTACTFROM = 'serviceContactFrom';
     public static final String SERVICE_CONTACTTO = 'serviceContactTo';
     public static final String SERVICE_FEE = 'Service Fee';
     public static final String SHIP_TO = 'Ship To';
     public static final String SLASH = '/';
     public static final String SQUARE_BRACKET_CLOSE = ']';
     public static final String SQUARE_BRACKET_OPEN = '[';
     public static final String STANDARD = 'standard';
     public static final String STANDARD_DEAL = 'Standard Deal';
     public static final String STANDARD_ORDER = 'Standard Order';
     public static final String STANDARD_RETURN = 'Standard Return';
     public static final String STANDALONE = 'Standalone';
     public static final String STATUS_PENDING_CANCEL = 'Pending Cancellation';
     public static final String SOLD_TO = 'SOLD To';
     public static final String SUBSCRIPTION = 'Subscription';
     public static final String SUB_ERR_ORDER_IN_FUL = 'Please Undo this order to revert to the previous order, as the order has already been progressed futher by SAP';
     public static final String SWAPPED = 'Swapped';
     public static final String STR_ORDER_CART_PENDING = 'Cart Creation Pending';
     public static final String STR_ORDER_ADD_PROD_PENDING = 'Add Product Pending';
     public static final String STR_ORDER_CART_FINALIZE_PENDING = 'Cart Finalization Pending';
     public static final String SPARE_PART= 'Spare Parts';
     public static final String SUBMITTED = 'Submitted';
     public static final String SAP_TYPE = 'XA01,XA06,XA07';
     public static final Set<String> STANDARD_ORDER_AG_STATUS = new Set<String> {ACTIVATED, BEING_AMENDED, BEING_RENEWED};    

     public static final String TRAIL = 'Trial';
     public static final String TECHNICAL_SWAP = 'Technical Swap';  
     public static final String TYPE = 'type';
     public static final String TEA = 'Tea';

     public static final String UNPLANNED_RETURN = 'Unplanned Return';
     public static final String URN = 'urn:sap-com:document:sap:rfc:functions';
     public static final String USAGE_FEE = 'Usage Fee';
     public static final String USEADVANCEDAPPROVAL = 'useAdvancedApproval';
     public static final String USEDEALOPTIMIZER = 'useDealOptimizer';     

     public static final String VARIABLE = 'Variable';

     public static final String XA01 = 'XA01';
     public static final String XA03 = 'XA03';
     public static final String XA07 = 'XA07';
     public static final String XA13 = 'XA13';
     public static final String XA14 = 'XA14';
     public static final String XA23 = 'XA23';
     public static final String XB01 = 'XB01';
     public static final String XB02 = 'XB02';
     public static final String XB13 = 'XB13';
     public static final String XB23 = 'XB23';
     public static final String XD09 = 'XD09';
     public static final String XD12 = 'XD12';
     public static final String XD = 'XD';
     public static final String XL = 'XL';

     public static final String ZOLP = 'SAP_ZOLP';
     public static final String ZOPT= 'ZOPT';

}