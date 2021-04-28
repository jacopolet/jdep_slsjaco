/**
* @author        Marvin Gatchalian
* @date          2.mar.2018
* @description   This class is made to map or wrap Products with Price List Item informations.
* @revision(s)
*/

public class TS_ProductsWrapper {
	public Decimal listPrice {get;set;}
	public String salesOrg {get;set;}
	public Apttus_Config2__PriceListItem__c pli;
    
}