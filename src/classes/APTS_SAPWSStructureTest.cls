/*************************************************************
@Name: APTS_SAPWSStructureTest
@Author: Galin Georgiev
@CreateDate: 19-02-2018
@Description: SAP Structure test class 
@UsedBy: APTS_SAPWSStructure
******************************************************************/
//v100 19-02-2018 Galin Georgiev: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes

@isTest
private with sharing class APTS_SAPWSStructureTest {

	@isTest static void test_SAPWSStructure() {

		test.startTest();

		APTS_SAPWSStructure.MESSAGETABLE_element oMESSAGETABLE_element = new APTS_SAPWSStructure.MESSAGETABLE_element();
		APTS_SAPWSStructure.ORDER_SCHEDULE_EX_element oORDER_SCHEDULE_EX_element = new APTS_SAPWSStructure.ORDER_SCHEDULE_EX_element();
		APTS_SAPWSStructure.BAPISDHEDU oBAPISDHEDU = new APTS_SAPWSStructure.BAPISDHEDU();
		APTS_SAPWSStructure.BAPICCARD_EX oBAPICCARD_EX = new APTS_SAPWSStructure.BAPICCARD_EX();
		APTS_SAPWSStructure.BAPICUPRT oBAPICUPRT = new APTS_SAPWSStructure.BAPICUPRT();
		APTS_SAPWSStructure.ORDER_SCHEDULE_IN_element oORDER_SCHEDULE_IN_element = new APTS_SAPWSStructure.ORDER_SCHEDULE_IN_element();
		APTS_SAPWSStructure.BAPICUINS oBAPICUINS = new APTS_SAPWSStructure.BAPICUINS();
		APTS_SAPWSStructure.ORDER_CFGS_REF_element oORDER_CFGS_REF_element = new APTS_SAPWSStructure.ORDER_CFGS_REF_element();
		APTS_SAPWSStructure.ORDER_CFGS_VALUE_element oORDER_CFGS_VALUE_element = new APTS_SAPWSStructure.ORDER_CFGS_VALUE_element();
		APTS_SAPWSStructure.BAPISCHDL oBAPISCHDL = new APTS_SAPWSStructure.BAPISCHDL();
		APTS_SAPWSStructure.BAPI_SALESORDER_SIMULATE_element oBAPI_SALESORDER_SIMULATE_element = new APTS_SAPWSStructure.BAPI_SALESORDER_SIMULATE_element();
		APTS_SAPWSStructure.BAPI_SALESORDER_SIMULATE_Response_element oBAPI_SALESORDER_SIMULATE_Response_element = new APTS_SAPWSStructure.BAPI_SALESORDER_SIMULATE_Response_element();
		APTS_SAPWSStructure.ORDER_CONDITION_EX_element oORDER_CONDITION_EX_element = new APTS_SAPWSStructure.ORDER_CONDITION_EX_element();
		APTS_SAPWSStructure.PARTNERADDRESSES_element oPARTNERADDRESSES_element = new APTS_SAPWSStructure.PARTNERADDRESSES_element();
		APTS_SAPWSStructure.BAPIITEMIN oBAPIITEMIN = new APTS_SAPWSStructure.BAPIITEMIN();
		APTS_SAPWSStructure.BAPIITEMEX oBAPIITEMEX = new APTS_SAPWSStructure.BAPIITEMEX();
		APTS_SAPWSStructure.BAPIRETURN oBAPIRETURN = new APTS_SAPWSStructure.BAPIRETURN();
		APTS_SAPWSStructure.BAPISHIPTO oBAPISHIPTO = new APTS_SAPWSStructure.BAPISHIPTO();
		APTS_SAPWSStructure.BAPIADDR1 oBAPIADDR1 = new APTS_SAPWSStructure.BAPIADDR1();
		APTS_SAPWSStructure.BAPICUBLB oBAPICUBLB = new APTS_SAPWSStructure.BAPICUBLB();
		APTS_SAPWSStructure.BAPIPAYER oBAPIPAYER = new APTS_SAPWSStructure.BAPIPAYER();
		APTS_SAPWSStructure.BAPIPAREX oBAPIPAREX = new APTS_SAPWSStructure.BAPIPAREX();
		APTS_SAPWSStructure.ORDER_CCARD_EX_element oORDER_CCARD_EX_element = new APTS_SAPWSStructure.ORDER_CCARD_EX_element();
		APTS_SAPWSStructure.ORDER_PARTNERS_element oORDER_PARTNERS_element = new APTS_SAPWSStructure.ORDER_PARTNERS_element();
		APTS_SAPWSStructure.ORDER_CCARD_element oORDER_CCARD_element = new APTS_SAPWSStructure.ORDER_CCARD_element();		
		APTS_SAPWSStructure.BAPICOND oBAPICOND = new APTS_SAPWSStructure.BAPICOND();
		APTS_SAPWSStructure.BAPISOLDTO oBAPISOLDTO = new APTS_SAPWSStructure.BAPISOLDTO();
		APTS_SAPWSStructure.BAPICUCFG oBAPICUCFG = new APTS_SAPWSStructure.BAPICUCFG();
		APTS_SAPWSStructure.BAPIRET2 oBAPIRET2 = new APTS_SAPWSStructure.BAPIRET2();
		APTS_SAPWSStructure.ORDER_CFGS_PART_OF_element oORDER_CFGS_PART_OF_element = new APTS_SAPWSStructure.ORDER_CFGS_PART_OF_element();
		APTS_SAPWSStructure.BAPICUVAL oBAPICUVAL = new APTS_SAPWSStructure.BAPICUVAL();
		APTS_SAPWSStructure.EXTENSIONIN_element oEXTENSIONIN_element = new APTS_SAPWSStructure.EXTENSIONIN_element();
		APTS_SAPWSStructure.BAPIINCOMP oBAPIINCOMP = new APTS_SAPWSStructure.BAPIINCOMP();
		APTS_SAPWSStructure.BAPIPARTNR oBAPIPARTNR = new APTS_SAPWSStructure.BAPIPARTNR();
		APTS_SAPWSStructure.BAPISDHEAD oBAPISDHEAD = new APTS_SAPWSStructure.BAPISDHEAD();
		APTS_SAPWSStructure.BAPICCARD oBAPICCARD = new APTS_SAPWSStructure.BAPICCARD();

		test.stopTest();		
	}

}