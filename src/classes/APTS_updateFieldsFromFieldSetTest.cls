@isTest
public class APTS_updateFieldsFromFieldSetTest {

    @isTest
    static void testFieldeditValidation(){
        Product2 crtProd =  APTS_TestUtils.createProduct('TestPrd',string.valueof(system.today()),'Coffee');
        insert crtProd;
        Apttus_Config2__PriceList__c crtPrclst =  APTS_TestUtils.createPriceList();
        crtPrclst.APTS_PriceList_Type__c = 'CSP';
        insert crtPrclst;
        system.assertEquals('CSP', crtPrclst.APTS_PriceList_Type__c);
        Apttus_Config2__PriceListItem__c crtPrclstItm = APTS_TestUtils.createPriceListItem(crtPrclst.Id,crtProd.Id);
        insert crtPrclstItm;
        
        ApexPages.StandardController sc = new ApexPages.StandardController(crtPrclstItm);
        APTS_updateFieldsFromFieldSet tstFieldset = new APTS_updateFieldsFromFieldSet(sc);
        
        PageReference pageRef = Page.APTS_updateFieldSet;
        pageRef.getParameters().put('id', String.valueOf(crtPrclstItm.Id));
        Test.setCurrentPage(pageRef);
        tstFieldset.save();
    }
}