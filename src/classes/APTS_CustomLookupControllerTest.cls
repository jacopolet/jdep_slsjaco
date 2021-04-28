@isTest
public with sharing class APTS_CustomLookupControllerTest {

 
    @isTest
    static void testUtil(){
        APTS_CustomLookupController.getLookupResults('Account', 'Test', 'Name', '','', null);
    }
}