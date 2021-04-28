/*************************************************************
@Name: APTS_SAPXMLRequestWrapper
@Author: Galin Georgiev
@CreateDate: 11-04-2018
@Description: SAP XML Request wrapper class
@UsedBy: APTS_PreviewOrderController, APTS_SWOrderUtils
******************************************************************/
public with sharing class APTS_SAPXMLRequestWrapper {
	
	public APTS_SAPWSStructure.BAPISDHEAD ORDER_HEADER_IN;
	public APTS_SAPWSStructure.ORDER_PARTNERS_element ORDER_PARTNERS;
	public APTS_SAPWSStructure.ORDER_ITEMS_IN_element ORDER_ITEMS_IN; 

	public Map<Integer, Apttus_Config2__LineItem__c> itemNumberToOrderLineItemMap;

	public APTS_SAPXMLRequestWrapper(APTS_SAPWSStructure.BAPISDHEAD ORDER_HEADER_IN, APTS_SAPWSStructure.ORDER_PARTNERS_element ORDER_PARTNERS, APTS_SAPWSStructure.ORDER_ITEMS_IN_element ORDER_ITEMS_IN, Map<Integer, Apttus_Config2__LineItem__c> itemNumberToOrderLineItemMap) {
		
		this.ORDER_HEADER_IN = ORDER_HEADER_IN;
		this.ORDER_PARTNERS = ORDER_PARTNERS;
		this.ORDER_ITEMS_IN = ORDER_ITEMS_IN;
		this.itemNumberToOrderLineItemMap = itemNumberToOrderLineItemMap;
	}
}