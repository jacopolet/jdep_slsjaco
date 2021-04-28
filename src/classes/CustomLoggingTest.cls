/*
* @author        Harold Marilag
* @date          23.05.2017          
* @description   Test class responsible for the SalesTriggerController 
* @revision(s)
*/
@isTest
private class CustomLoggingTest {
    static testMethod void testCustomLogging(){
        
        CustomLogging.push('testCustomLogging', 'CustomLoggingTest');
        
        Account newAccount = new Account(Name='Sample Account', Phone='sample phone');
        try{
            insert newAccount;
        }
        catch(Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();
        }
        List<Account> resultLst = [Select id from Account where id =: newAccount.Id];
        System.assertEquals(1,resultLst.size());
             
    }
    static testMethod void testDebug(){
        
        CustomLogging.push('testDebug', 'CustomLoggingTest');
        
        List<Account> acctList = TS_TestDataFactory.createAccounts(1);
        Account acct = acctList.get(0);
        
        try{
            acct.Phone='sample phone';
            update acct;
        }
        catch (Exception e){
            CustomLogging.debugException(e);
            CustomLogging.debug(e.getMessage());
            CustomLogging.pop();
        }
        
        System.assertEquals(null,acct.Id);
        
    }
    static testMethod void testDebugException(){
        
        CustomLogging.push('testDebugException', 'CustomLoggingTest');
        Account acct = new Account(Name=null);
        
        try{
            insert acct;
        }
        catch(Exception e){
            CustomLogging.debugException(e);
            CustomLogging.debugException(e.getMessage());
            CustomLogging.debug(e.getMessage());
            CustomLogging.pop();
        }
        
        System.assertEquals(null,acct.Id);

        //testSetInConstructor
        CustomLogging.setInConstuctor();
        CustomLogging.unsetInConstuctor();
        
    }

    
}