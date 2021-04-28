@isTest
private class EventWhoIdWhatId_Test { 
    private static testMethod void createEventWithwhatIdandWhoId() {
        Opportunity opp = new Opportunity();
        opp.name = 'test opp 1';
        opp.StageName = 'Oferecer projeto/orçamento';
        opp.LeadSource = 'Google';
        opp.CloseDate = system.today();
        test.startTest();
        insert opp;
        
        Event e = new Event();
        e.WhatID = opp.id;
        e.Subject='Donni';
        e.DurationInMinutes=8;
        e.ActivityDateTime=System.today();

        insert e;  
        
        EventWhoIdWhatId.assignWhatIdWhoID(New Id[] {e.Id});
        test.stopTest();
        
        List<Event> getEvent = new List<Event>([Select Id, WhatId FROM Event WHERE Id = :e.Id]); 
        
        system.assert(getEvent[0].WhatId != Null);

    }
}