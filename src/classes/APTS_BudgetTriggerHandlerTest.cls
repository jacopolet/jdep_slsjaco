@isTest
private class APTS_BudgetTriggerHandlerTest{

    private static testMethod void testExecute() {
                
        Account testAccount = APTS_TestUtils.createGrandParentAccount();
        testAccount.Name = 'Test Account';
        Database.Insert(testAccount);
        
        Apttus_Config2__PriceList__c priceList = APTS_TestUtils.createPriceList();
        Database.Insert(priceList);
        
        Id recordtype = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get(System.Label.APTS_Standard_Deal).getRecordTypeId();
        
        
        Apttus__APTS_Agreement__c agrmnt = new Apttus__APTS_Agreement__c(Apttus__Account__c = testAccount.Id, 
                        Name = 'Test Agreement',RecordTypeId = recordtype,
                        Apttus__Contract_Start_Date__c = Date.today(), Apttus__Contract_End_Date__c = Date.today()+365, 
                        Apttus_CMConfig__PriceListId__c = priceList.id,Apttus__Subtype__c ='Fixed-Term-Fixed Costs',
                        Apttus__Status_Category__c = 'In Effect', Apttus__Status__c = 'Activated',APTS_Language__c = 'English');
        Database.Insert(agrmnt);
        
        APTS_Agreement_Budget__c budget = new APTS_Agreement_Budget__c();
        budget.Agreement__c = agrmnt.id;
        Database.Insert(budget);

        Map<ID,APTS_Agreement_Budget__c> budgetmap = new Map<ID,APTS_Agreement_Budget__c>();
        budgetmap.put(budget.id,budget);

        list<APTS_Agreement_Budget__c> budgetlist = new list<APTS_Agreement_Budget__c>();
        budgetlist.add(budget);

        budget.APTS_Start_Date__c = agrmnt.Apttus__Contract_Start_Date__c;
        Database.Update(budget);
        
        APTS_AgreementBudgetHandler handler = new APTS_AgreementBudgetHandler();
        handler.beforeDelete(null, null);
        handler.afterDelete(null, null);
        handler.afterUndelete(null, null);
        handler.afterInsert(budgetlist,budgetmap);
        handler.afterUpdate(budgetlist,budgetmap,budgetlist,budgetmap);
    }


}