/**
* @author        Marvin Gatchalian
* @date          19.feb.2018
* @description   Utility class for Operating tasks related.
* @revision(s)
*/


public with sharing class TS_OperatingTaskUtility {
    
    public Map<Integer, boolean>  getFutureHolidayMap(Integer dLookup, String bhId, date startdate){
        CustomLogging.push('getFutureHolidayMap', 'TS_OperatingTaskUtility');
    	Map<Integer, boolean> futureHmap = new Map<Integer, boolean >();
    	DateTime idatetime = DateTime.newInstance(startdate, Time.newInstance(12,0,0,0));//assuming 12:00 o'clock is the hour in a business day.
    	for (Integer i = 0; i<= dlookup; i++){          
        	boolean is_i_a_businessday = Businesshours.isWithin(bhId, idatetime);
        	system.debug ('DayMAPFRW -- ' + i + ' ' + idatetime + '/IsBusiness Day --> ' + is_i_a_businessday);
        	futureHmap.put(i, is_i_a_businessday);
        	idatetime = idatetime.addDays(1);
        	
    	}
        
        CustomLogging.pop();
    	return futureHmap;
    }
    
    public Map<Integer, boolean>  getPastHolidayMap(Integer dLookup, String bhId, date startdate){
        CustomLogging.push('getPastHolidayMap', 'TS_OperatingTaskUtility');
    	Map<Integer, boolean> pastHmap = new Map<Integer, boolean >();
    	DateTime idatetime = DateTime.newInstance(startdate, Time.newInstance(12,0,0,0));//assuming 12:00 o'clock is the hour in a business day.
        for (Integer i = 0; i<= dlookup; i++){          
        	boolean is_i_a_businessday = Businesshours.isWithin(bhId, idatetime);
        	system.debug ('DayMAPBAK -- ' + i + ' ' + idatetime + '/IsBusiness Day --> ' + is_i_a_businessday);
        	pastHmap.put(i, is_i_a_businessday);
        	idatetime = idatetime.addDays(-1);
        }
        
        CustomLogging.pop();
    	return pastHmap;
    }
    
}