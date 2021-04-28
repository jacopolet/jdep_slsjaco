/*
* @author        Xen Reyes
* @date          Feb 1, 2019
* @description   Controller class for TS_ClickPollingCheck lightning component.
* @revision(s)
*/
public with sharing class TS_ClickPollingCheckController {
	
	@AuraEnabled
	public static String getStatus(){

		String resp;
		try{
			TS_ClickHealthCheck.JDEServiceOptimizationPort port = new TS_ClickHealthCheck.JDEServiceOptimizationPort();
			resp = port.CheckServerHealth();
		} catch (Exception e){
            
            if(Test.isRunningTest()){
                System.debug(e);
            } else {
             	resp = JSON.serialize(e);   
            }
		}
		
		return resp;
	}
}