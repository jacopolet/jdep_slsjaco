/**
* @author        Marvin Gatchalian
* @date          15.February.2018
* @description   This class is made to map or wrap holiday with operating schedule object.
* @revision(s)
*/

public class TS_HolidayWrapper {

	Public class OpSched {
		
		public Id osId;
		public String typeOfContract;
		//modified by Archi
		public String cTask = '0' ;
		public String sTask = '0' ;
		public String lTask = '0';
		public String rTask = '0';
		public String timeIndicator = '0';
		////////////////////////
		/*public String cTask;
		public String sTask;
		public String lTask;
		public String rTask;
		public String timeIndicator;*/
		public Boolean isRinse;
		public Boolean is247;
		public Boolean isBusinessDay;
		public Boolean lpm = false;
		public Boolean lam = false;
		public Boolean forceSchedule = false;
		public Integer remainingSTask = 0;
		public Date actualDate;
		public Date postponed_LTask_Date;
		public String postponed_LTask = '0';
	} 
	

   	Public TS_HolidayWrapper ()  {
	
	}
	  
 	Public OpSched InitData (Date taskDate, OperatingSchedule__c os, Boolean isBusinessDayFromMap )  {
		DateTime scheduledDate = taskDate;
		scheduledDate = scheduledDate.addHours(13);
		String getRinseAPIName = Label.TS_Operating_Rinse + '_' + getWeekNumber(os.Start_Date__c, scheduledDate.date()) + '_' + scheduledDate.format('EEEE') + '__c';
        String getLargeAPIName = Label.TS_Operating_Large + '_' + getWeekNumber(os.Start_Date__c, scheduledDate.date()) + '_' + scheduledDate.format('EEEE') + '__c';
        String getsmallAPIName = Label.TS_Operating_Small + '_' + getWeekNumber(os.Start_Date__c, scheduledDate.date()) + '_' + scheduledDate.format('EEEE') + '__c';
		String getcupsAPIName  = Label.TS_Operating_Cups + '_' + getWeekNumber(os.Start_Date__c, scheduledDate.date()) + '_' + scheduledDate.format('EEEE') + '__c';
		
		System.debug('Init Date >>> ' + scheduledDate + '>>> API Name Small >>> ' + getsmallAPIName + '>>> Format' + scheduledDate.format('EEEE'));
		OpSched osSched = new OpSched();
		
		osSched.osId = os.id;
		osSched.typeOfContract = os.TypeofContract__c;
		osSched.is247 = os.OP_247Customer__c;
		osSched.cTask = String.valueOf(os.get(getcupsAPIName));     
		osSched.sTask = String.valueOf(os.get(getsmallAPIName));
		osSched.lTask = String.valueOf(os.get(getLargeAPIName));
		osSched.rTask = '0'; // default value is zero, this task only exist when there is a rinse task on holiday, which should be created on the next available business day.
		osSched.isRinse = (boolean) os.get(getRinseAPIName);
		osSched.isBusinessDay = isBusinessDayFromMap;
		osSched.actualDate = taskDate;
		osSched.forceSchedule = os.ForceScheduleToNextBusinessDay__c;
		Return osSched;
	}  

   
	public Map<Integer, OpSched> getFwdHolidayMap(Date taskDate, OperatingSchedule__c os, Map<Integer, boolean> futureHMap){
		Map<Integer, OpSched> localM = new Map<Integer, OpSched>();
		
		
		for (Integer eachDay :futureHMap.keySet()){
			system.debug('Index ' + eachDay + '--- ' + futureHMap.get(eachday)); 
			OpSched osSched = InitData (taskDate.addDays(eachDay), os, futureHMap.get(eachday)); 
			localM.put(eachDay, osSched);
		}
		System.debug('TS_HolidayWrapper--> getFwdHolidayMap: '+localM);
		Return localM;
	}
	
	public Map<Integer, OpSched> getBwkHolidayMap(Date taskDate, OperatingSchedule__c os, Map<Integer, boolean> backwardHMap){
		Map<Integer, OpSched> localM = new Map<Integer, OpSched>();
		
		for (Integer eachDay :backwardHMap.keySet()){
			OpSched osSched = InitData (taskDate.addDays(eachDay * -1), os, backwardHMap.get(eachday)); 
			localM.put(eachDay, osSched);
		}
		System.debug('TS_HolidayWrapper--> getBwkHolidayMap: '+localM);

		Return localM;
	}
	
	// To be moved to utility class to eliminate duplicate codes and make it reusable
	Integer getWeekNumber(Date startDate, Date scheduledDate){
        CustomLogging.push('getWeekNumber', 'TS_OperatingTasksBatch');
        Date d1 = startDate.toStartOfWeek();
        Date d2 = scheduledDate.toStartOfWeek();
        Integer numberOfWeeks = d1.daysBetween(d2) / 7;
        CustomLogging.pop();
        return Math.mod(numberOfWeeks, 2) == 0 ? 1 : 2;
    }

}