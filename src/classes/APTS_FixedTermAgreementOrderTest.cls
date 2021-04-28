@isTest
public class APTS_FixedTermAgreementOrderTest{

    public static testMethod void activeFixedTermOrderTest(){
        test.startTest();
        Apttus__APTS_Agreement__c agrt = new Apttus__APTS_Agreement__c(name = 'Test Fixed term');
        insert agrt;
        
        PageReference pageRef = Page.APTS_UpdateOrderFixedTerm;
        Test.setCurrentPage(pageRef);
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(agrt);
        ApexPages.currentPage().getParameters().put('agrmentId',agrt.id);
        Apttus_Config2__Order__c ord1 = new Apttus_Config2__Order__c(APTS_Order_Type__c = 'Admin Order',Apttus_Config2__Status__c='Draft',Apttus_CMConfig__AgreementId__c=agrt.id, APTS_Name__c = System.Label.APTS_BIR_FixedTerm_Dummy);
        insert ord1;
        Apttus_Config2__Order__c ord2 = new Apttus_Config2__Order__c(APTS_Order_Type__c = 'Admin Order',Apttus_Config2__Status__c='Draft',Apttus_CMConfig__AgreementId__c=agrt.id, APTS_Name__c = System.Label.APTS_BIR_FixedTerm_Dummy);
        insert ord2;
        APTS_FixedTermAgreementOrder fxdord = new APTS_FixedTermAgreementOrder(sc);
        
        fxdord.activeFixedTermOrder();
        system.assertEquals('Admin Order',ord2.APTS_Order_Type__c);
        test.stopTest();
    }

    public static testMethod void activeFixedTermOrderTest2(){
        test.startTest();
        Apttus__APTS_Agreement__c agrt = new Apttus__APTS_Agreement__c(name = 'Test Fixed term');
        insert agrt;
        
        PageReference pageRef = Page.APTS_UpdateOrderFixedTerm;
        Test.setCurrentPage(pageRef);
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(agrt);
        ApexPages.currentPage().getParameters().put('agrmentId',agrt.id);
        Apttus_Config2__Order__c ord1 = new Apttus_Config2__Order__c(APTS_Order_Type__c = 'Admin Order',Apttus_Config2__Status__c='Draft',Apttus_CMConfig__AgreementId__c=agrt.id, APTS_Name__c = System.Label.APTS_BIR_FixedTerm_Dummy);
        insert ord1;
        system.assertEquals('Admin Order',ord1.APTS_Order_Type__c);
        APTS_FixedTermAgreementOrder fxdord = new APTS_FixedTermAgreementOrder(sc);
        
        fxdord.activeFixedTermOrder();
        test.stopTest();
    }
}