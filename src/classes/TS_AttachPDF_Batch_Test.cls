/**
* @author        Karen Hung
* @date          9.17.2018
* @description   Test class for TS_AttachPDF_Batch
* @revision(s)
*/
@isTest
public class TS_AttachPDF_Batch_Test {
    static Account acct;
    static Contact con;
    static Case c;
    static Case c2;
    static Case c3;
    static WorkOrder wo;
    static WorkOrder wo2;
    static WorkOrder wo3;
    static Apttus_Config2__AssetLineItem__c ali;
    static Apttus_Config2__Order__c order;
    static Apttus_Config2__OrderLineItem__c oli;
    static WorkOrderLineItem woli;
    static WorkOrderLineItem dummyWoli;
    static WorkOrderLineItem woli2;
    static WorkOrderLineItem dummyWoli2;
    static WorkOrderLineItem woli3;
    static WorkOrderLineItem dummyWoli3;
    static PhysicalAsset__c pa;
    
    /**
    * @author        Karen Hung
    * @date          9.17.2018        
    * @description   Method responsible for creating test data
    * @revision(s)
    */
    @testSetup
    static void dataSetup(){
        
        acct = new Account(Name='Account', Phone='+31302979119');
        database.insert(acct);
        
        con = TS_TestDataFactory.createContact();  
        con.Preferred_Language__c = 'SAP_EN';
        con.Communication_Preference__c = 'Email';
        con.Email = 'test@test.com';
        database.insert(con);
        
        Apttus_Config2__AccountLocation__c accLocation = TS_TestDataFactory.createAccountLocationTest('454545577868',acct.Id );
        accLocation.Additional_Case_Contact__c = con.Id;
        accLocation.Second_Additional_Case_Contact__c = con.Id;
        accLocation.StakeholderNotification__c = true;
        database.insert(accLocation);

        List<Case> caseList = new List<Case>();
        c = TS_TestDataFactory.createFieldServiceCase();
        c.ContactId = con.Id;
        c.SubType__c = 'S10';
        c.SalesOrganization__c= 'SAP_0333';
        c.AccountLocation__c = accLocation.Id;
        caseList.add(c);   
        
        c2 = TS_TestDataFactory.createFieldServiceCase();
        c2.ContactId = con.Id;
        c2.SubType__c = 'S10';
        c2.SalesOrganization__c= 'SAP_0333';
        c.AccountLocation__c = accLocation.Id;
        c2.Origin = 'Sales Order';
        c2.Status = 'Closed';
        caseList.add(c2); 
        
        c3 = TS_TestDataFactory.createFieldServiceCase();
        c3.ContactId = con.Id;
        c3.SubType__c = 'S10';
        c3.SalesOrganization__c= 'SAP_0333';
        c3.AccountLocation__c = accLocation.Id;
        c3.Origin = 'Regular';
        c3.Status = 'Closed';
        caseList.add(c3);  
        
        database.insert(caseList);
        
        List<WorkOrder> woList = new List<WorkOrder>();
        wo = TS_TestDataFactory.createWorkOrder();
        wo.CaseId = c.Id;
        wo.WorkOrderType__c = Label.TS_Case_SubType_CorrectMaint;
        wo.ContactId = con.Id;
        wo.SalesOrganization__c = 'SAP_0333';
        woList.add(wo);
        
        wo2 = TS_TestDataFactory.createWorkOrder();
        wo2.CaseId = c2.Id;
        wo2.WorkOrderType__c = Label.TS_Case_SubType_CorrectMaint;
        wo2.ContactId = con.Id;
        wo2.SalesOrganization__c = 'SAP_0333';
        woList.add(wo2);
        
        wo3 = TS_TestDataFactory.createWorkOrder();
        wo3.CaseId = c2.Id;
        wo3.WorkOrderType__c = Label.TS_Case_SubType_CorrectMaint;
        wo3.ContactId = con.Id;
        wo3.SalesOrganization__c = 'SAP_0333';
        woList.add(wo3);
        
        database.insert(woList);
        
        ali = TS_TestDataFactory.createAssetLineItem();
        ali.Name = Label.TS_Assetlinitem_PrevMain;
        ali.Apttus_Config2__IsPrimaryLine__c = true;
        ali.Apttus_Config2__AssetStatus__c = 'Activated';
        ali.Apttus_Config2__AccountId__c = acct.Id;
        ali.Apttus_Config2__BillToAccountId__c = acct.Id;
        database.insert(ali);
        
        order = TS_TestDataFactory.createOrderRecord('Draft', 'New');
        //order.APTS_Interface_To_SAP__c = true;
        order.Apttus_Config2__ShipToAccountId__c = acct.Id;
        order.Apttus_Config2__SoldToAccountId__c = acct.Id;
        order.Apttus_Config2__BillToAccountId__c = acct.Id;
        database.insert(order);
        
        oli = new Apttus_Config2__OrderLineItem__c();
        oli.Apttus_Config2__OrderId__c = order.Id;
        oli.Apttus_Config2__Quantity__c = 1.0;
        oli.Apttus_Config2__AssetLineItemId__c = ali.Id;
        database.insert(oli);
        
        product2 pd = TS_TestDataFactory.createProductTest('ProductTest','ZSPR');
        database.insert(pd);
        
        
        Id recordType =  TS_UtilityClass.getRecordTypeIdByName('PhysicalAsset__c', 'Machine');
        pa = TS_TestDataFactory.createPhysicalAssetTest(recordType, pd.Id,'SAP_0333', acct.Id, accLocation.Id, 'building', 'floor', null, 'Full Operating');
        database.insert(pa);
        
        List<WorkOrderLineItem> parentWolis = new List<WorkOrderLineItem>();
        woli = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);  //parent woli
        woli.Case__c = c.Id;
        woli.WorkOrderId = wo.id;
        woli.WorkOrderLineItemType__c = Label.TS_Type_Task;
        woli.workOrderType__c = 'S10';
        woli.AssetLineItem__c = ali.Id;
        woli.OrderLineItem__c = oli.Id;
        woli.EndDate__c = DateTime.now();
        woli.Status = 'Completed';
        woli.PhysicalAsset__c = pa.id;
        woli.QuotingSignature__c = '  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';
        woli.Signature__c = '  /9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/2wBDAQkJCQwLDBgNDRgyIRwhMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjL/wAARCAA9APoDASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwD0PwZ4M8K3XgXw9cXHhnRpp5dMtnkkksImZ2MSkkkrkknvW5/wgng//oVND/8ABdD/APE0eBP+SeeGf+wVa/8Aopa6CgDn/wDhBPB//QqaH/4Lof8A4mj/AIQTwf8A9Cpof/guh/8Aia6CigDn/wDhBPB//QqaH/4Lof8A4mj/AIQTwf8A9Cpof/guh/8Aia6CigDn/wDhBPB//QqaH/4Lof8A4mj/AIQTwf8A9Cpof/guh/8Aia6CigDn/wDhBPB//QqaH/4Lof8A4mj/AIQTwf8A9Cpof/guh/8Aia6CigDn/wDhBPB//QqaH/4Lof8A4mj/AIQTwf8A9Cpof/guh/8Aia1NS1bTdGt1uNU1C0sYGfYsl1MsSlsE4BYgZwDx7Gsv/hO/B/8A0Neh/wDgxh/+KoAP+EE8H/8AQqaH/wCC6H/4mj/hBPB//QqaH/4Lof8A4mj/AITvwf8A9DXof/gxh/8Aiqy9S+LXgPSrhYLjxLaO7JvBtVe4XGSOWjVgDx0znp6igDU/4QTwf/0Kmh/+C6H/AOJo/wCEE8H/APQqaH/4Lof/AImuf/4Xb8PP+hh/8krj/wCN0f8AC7fh5/0MP/klcf8AxugDoP8AhBPB/wD0Kmh/+C6H/wCJo/4QTwf/ANCpof8A4Lof/ia5/wD4Xb8PP+hh/wDJK4/+N0f8Lt+Hn/Qw/wDklcf/ABugDoP+EE8H/wDQqaH/AOC6H/4mj/hBPB//AEKmh/8Aguh/+Jrn/wDhdvw8/wChh/8AJK4/+N1hz/tFeDYbiWJLTWZ0Ryqyx28YVwD94bpAcHryAfUCgDvP+EE8H/8AQqaH/wCC6H/4mj/hBPB//QqaH/4Lof8A4mvP/wDho7wf/wBA3XP+/EP/AMdo/wCGjvB//QN1z/vxD/8AHaAPQP8AhBPB/wD0Kmh/+C6H/wCJo/4QTwf/ANCpof8A4Lof/ia8/wD+GjvB/wD0Ddc/78Q//HasWP7Q3gq7vI4JotVso2zmee3UomATyEdm56cA9fTmgDuP+EE8H/8AQqaH/wCC6H/4mj/hBPB//QqaH/4Lof8A4mtDRNb07xHo8GraTcfaLGfd5cuxk3bWKnhgCOQRyK0KAOf/AOEE8H/9Cpof/guh/wDiaP8AhBPB/wD0Kmh/+C6H/wCJroKKAOf/AOEE8H/9Cpof/guh/wDiaP8AhBPB/wD0Kmh/+C6H/wCJroKKAOf/AOEE8H/9Cpof/guh/wDia+PPGcENr468Q29vFHDBFqdykccahVRRKwAAHAAHavuOviDx3/yUPxN/2Fbr/wBGtQB9f+BP+SeeGf8AsFWv/opa3J54bW3luLiWOGCJC8kkjBVRQMkkngADvXH6Pp19q/wc0XT9N1WTSru40e0RL2OPe0Q8tN2BkclcjIIIzkcivBNX8CXV5451a10S/vvEfiG2uxNcSLpUC2ZmY+YwkkaYovIcbWTBZSuKAPoe++I/grT7OS6m8UaU8aYyILlZnOSBwiEsevYcdelY/wDwuPwrd/u9DXVdeuhy1rpmnSvIid3IcKNoOB16sOK4jwt8N/iRHeWmoTXvhzQZBvy8GkWj3MPDLxsiCnPs/RvXitfW/g94p8R+eurfEy+uIZ9vmW/2IpC23GP3SyhByAeB1560AF/+0R4bs/tMH9ia4t9DuTyLiGOLEgyNrneSvIweCR6HpWRdfGfxfe+Rc6RpfhW0tZIlby77XLeSTJ5yf30ZXgj5SuQQc+gr/wDDMv8A1N3/AJTf/ttH/DMv/U3f+U3/AO20Ab//AAnfjD/oa/hV/wCDGb/4qo4L/Wmt4muPjt4fjnKAyJHaWTqrY5AYsCRnvgZ9BWJ/wzL/ANTd/wCU3/7bR/wzL/1N3/lN/wDttAGv9itdQ1H7Trnx286MReWsemX0Fhg5yCdjlT1P8OTxzgYqPUvCPw+1m3W31T4r6lfQK+9Y7rxFbyqGwRkBlIzgnn3NZn/DMv8A1N3/AJTf/ttH/DMv/U3f+U3/AO20Ac34e8C+Ada1nV/7Q8T2mmaTYXD2Vov9pRfaLwq2ftDM42bCDhdigED1Us/WWHw2+EFjqNtef8JrBceRKsvk3Gq2jxybSDtddvKnGCO4ry/XPANn4evL3StQ8RQQ61HdtFa2jxDZLDjMcskocrDv6BW5G5S21SXHWaB+zr4j1BFl1rULTSUZCfLUfaJVYNgBgpCYIychz2464APW/wDi0H/Ujf8AkpR/xaD/AKkb/wAlK4D/AIZl/wCpu/8AKb/9to/4Zl/6m7/ym/8A22gD0OCf4TWtxFcW8vgqGeJw8ckbWqsjA5BBHIIPetz/AITvwf8A9DXof/gxh/8Aiq8kg/ZnhW4ia48VySQBwZEjsAjMueQGMhAOO+Dj0Nbf/DOPg/8A6CWuf9/4f/jVAHoH/Cd+D/8Aoa9D/wDBjD/8VR/wnfg//oa9D/8ABjD/APFV5nqXwH+H2jW63GqeItSsYGfYsl1e28SlsE4BaMDOAePY1iX3w4+Den2cl1N46neNMZEGoW8znJA4RIyx69hx16UAez/8J34P/wChr0P/AMGMP/xVH/Cd+D/+hr0P/wAGMP8A8VXgH/CPfAz/AKHPXP8Avy3/AMj1oWugfD3R9Onk1H4dfEC7jj3SvdX1o0floBzkxuihRgnJHc846AHt/wDwnfg//oa9D/8ABjD/APFUf8J34P8A+hr0P/wYw/8AxVfLni+bwhLb2OpeGPDEdnZrcDi41gSyXK45WW2EhljGVIDBhwfVlx3GlfDS/wDEWl29xafDjRtEdUxKdY1K9zO3QlIkcPGAVPD5yGXBPJIB7X/wnfg//oa9D/8ABjD/APFUf8J34P8A+hr0P/wYw/8AxVeYaZ+zXo8Xm/2t4gvrrOPL+yQpb7euc7t+7t0xjB6543774G/D2LQ5Elt57PyYgZdRN6wdQuCztuJjGQDn5cDJwBxgA7D/AITvwf8A9DXof/gxh/8Aiqy9S+LXgPSrhYLjxLaO7JvBtVe4XGSOWjVgDx0znp6ivJH0/wAKeGfFvh7SdE1zQ/Ednd6hBbvYXOk21y6wysVZ2u1X5mDchcgjK8FRz7/pmhaPonm/2TpVjYedjzPslukW/GcZ2gZxk9fU0Acf/wALt+Hn/Qw/+SVx/wDG6P8Ahdvw8/6GH/ySuP8A43XoFFAHn/8Awu34ef8AQw/+SVx/8bo/4Xb8PP8AoYf/ACSuP/jdegUUAYc/jTwra3EtvceJdGhnicpJHJfxKyMDgggtkEHtXx547/5KH4m/7Ct1/wCjWr6//wCEE8H/APQqaH/4Lof/AImvjzxnBDa+OvENvbxRwwRancpHHGoVUUSsAABwAB2oA+w/An/JPPDP/YKtf/RS1h+M9EvtI1RPHHhXTY7nWoE8nULUHBv7Tgso4J81SqFSOcLj58KtbngT/knnhn/sFWv/AKKWugoA8/8A+Fp/9SF45/8ABP8A/Z0f8LT/AOpC8c/+Cf8A+zr0CigDz/8A4Wn/ANSF45/8E/8A9nUkHxNa5uIoE8CeNQ8jhFMmlqigk45ZnAUe5IA713lFAHn/APwtP/qQvHP/AIJ//s6P+Fp/9SF45/8ABP8A/Z16BRQB5/8A8LT/AOpC8c/+Cf8A+zqODxn8Qbm3inT4XyBJEDqJNbhRgCM8qygqfYgEd69EooA8T8Z6X4p8Zok938KY4tUt0xaX39t2zmMhgwDoRtlTI5RwRhmxjJNcJbaN4k8M7bOLwV4ysL5Ikju5tA1ORIbphkq5xFKC2Gwdr7Qc4C8ivqeigD5Y0zxh4ntdRlhsviB/ZEk8ohaw8QyzXU1s6kqQ8j2xjTnJONuARu5WvQ9KufE18lvDP8bfD41CZ9gtrS1tJwWLYUKSVLE8cbRycc9a9gnghureW3uIo5oJUKSRyKGV1IwQQeCCO1c/P8PvBtzbywP4V0YJIhRjHZRowBGOGUAqfcEEdqAOT1P4c+OdX8r7T8VL6Pys7fsmni2znGc+VIu7p3zjnHU1gan8A9Y1vyv7W+Il9f8Ak58v7XavLszjON0xxnA6egrr/wDhSXw8/wChe/8AJ24/+OUf8KS+Hn/Qvf8Ak7cf/HKAOM039nifSrhp7fxXaO7JsIutCiuFxkHhZHYA8dcZ6+pqnd6Zp3g28F0fij4csr6CVoc2XhezeeJ8EMCsWXXgMDkD0PWvR0+EHgSPTprBdCxazSxzSJ9rn+Z0DhTnfngSP+fsK6DRvCnh/wAPbDpGi2NlIsQh82GBRIyDHDPjc3QE5JyRk80AeKSeIfilfvDF4Z1bxBqZmfMVxc+G7eztZYtpIkWVyRggAgMFyD64B39W+DvijxTcafqHiPx3Hc3loilIjpSPBG2QWAXcquCRglk+YAZGBgeyUUAeT2Pwm8QaZeR3lh4v0q0uo87JoPClnG65BBww5GQSPxroLDwx47t9Rtprz4i/a7WOVXmt/wCxII/NQEFk3A5XIyMjpmu4ooA8/wD+EE8Vah+61z4karNaj5lXTLWKwkD9ATImSVwT8uOTg9qkg+D/AIP+0RXmpWl3rOoI4d73U7ySaSYg/LvGQjAABcFcYABzXeUUAZ+maFo+ieb/AGTpVjYedjzPslukW/GcZ2gZxk9fU1oUUUAFFFFABRRRQAV8QeO/+Sh+Jv8AsK3X/o1q+36+IPHf/JQ/E3/YVuv/AEa1AH1/4E/5J54Z/wCwVa/+ilroK+cNC/aH/sTw9pmk/wDCLed9htIrbzf7Q279iBd2PLOM4zjJrQ/4aa/6lH/ypf8A2qgD3+ivAP8Ahpr/AKlH/wAqX/2qj/hpr/qUf/Kl/wDaqAPf6K8A/wCGmv8AqUf/ACpf/aqP+Gmv+pR/8qX/ANqoA9/orwD/AIaa/wCpR/8AKl/9qo/4aa/6lH/ypf8A2qgD3+ivAP8Ahpr/AKlH/wAqX/2qj/hpr/qUf/Kl/wDaqAPf6K8A/wCGmv8AqUf/ACpf/aqP+Gmv+pR/8qX/ANqoA9/orwD/AIaa/wCpR/8AKl/9qo/4aa/6lH/ypf8A2qgD3+ivAP8Ahpr/AKlH/wAqX/2qj/hpr/qUf/Kl/wDaqAPf6K8A/wCGmv8AqUf/ACpf/aqP+Gmv+pR/8qX/ANqoA9/orwD/AIaa/wCpR/8AKl/9qo/4aa/6lH/ypf8A2qgD3+ivAP8Ahpr/AKlH/wAqX/2qj/hpr/qUf/Kl/wDaqAPf6K8A/wCGmv8AqUf/ACpf/aqP+Gmv+pR/8qX/ANqoA9/orwD/AIaa/wCpR/8AKl/9qo/4aa/6lH/ypf8A2qgD3+ivAP8Ahpr/AKlH/wAqX/2qj/hpr/qUf/Kl/wDaqAPf6K8A/wCGmv8AqUf/ACpf/aqP+Gmv+pR/8qX/ANqoA9/r4g8d/wDJQ/E3/YVuv/RrV7B/w01/1KP/AJUv/tVeH67qf9t+IdT1byfJ+3Xctz5W7ds3uW25wM4zjOBQB//Z';
        parentWolis.add(woli);
        
        woli2 = TS_TestDataFactory.createWorkOrderLineItem(wo2.Id);//parent woli
        woli2.Case__c = c2.Id;
        woli2.WorkOrderId = wo2.id;
        woli2.WorkOrderLineItemType__c = Label.TS_Type_Task;
        woli.workOrderType__c = 'S10';
        woli2.AssetLineItem__c = ali.Id;
        woli2.OrderLineItem__c = oli.Id;
        woli2.EndDate__c = DateTime.now();
        woli2.Status = 'Completed';
        woli2.PhysicalAsset__c = pa.id;
        parentWolis.add(woli2);
        
        woli3 = TS_TestDataFactory.createWorkOrderLineItem(wo3.Id);//parent woli
        woli3.Case__c = c3.Id;
        woli3.WorkOrderId = wo3.id;
        woli3.WorkOrderLineItemType__c = Label.TS_Type_Task;
        woli3.workOrderType__c = 'S10';
        woli3.AssetLineItem__c = ali.Id;
        woli3.OrderLineItem__c = oli.Id;
        woli3.EndDate__c = DateTime.now();
        woli3.Status = 'Scheduled';
        woli3.PhysicalAsset__c = pa.id;
        parentWolis.add(woli3);
        database.insert(parentWolis);        
        
        List<WorkOrderLineItem> dummies = new List<WorkOrderLineItem>();
        dummyWoli = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);//dummy woli
        dummyWoli.ParentWorkOrderLineItemId = woli.id;
        dummyWoli.RecordTypeId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Register Service Material').getRecordTypeId();
        dummyWoli.IsReadyToSummarize__c = true;
        dummyWoli.Case__c = c.Id;
        dummies.add(dummyWoli);
        
        dummyWoli2 = TS_TestDataFactory.createWorkOrderLineItem(wo2.Id); 
        dummyWoli2.ParentWorkOrderLineItemId = woli2.id;
        dummyWoli2.RecordTypeId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Register Service Material').getRecordTypeId();
        dummyWoli2.IsReadyToSummarize__c = true;
        dummyWoli2.Case__c = c2.Id;
        dummies.add(dummyWoli2);
        database.insert(dummies);

        //JOURNEY TRIGGER COUNTRY SETTING
        List<CountrySetting__c> csList = new List<CountrySetting__c>();
        CountrySetting__c cs_be_customer = new CountrySetting__c();
        cs_be_customer.Name = 'BE - Fulfillment Closure - Customer';
        cs_be_customer.Country__c = 'SAP_0333';
        cs_be_customer.Channel__c = 'Email';
        cs_be_customer.Journey_Trigger_Type__c = 'Fulfillment Closure';
        cs_be_customer.Journey_Trigger_SubType__c = 'Fulfillment Summary Notification for Single Task to Customer';
        cs_be_customer.Sending_Method__c = 'Send via MC';
        cs_be_customer.Active__c = true;
        cs_be_customer.RecordTypeId = Schema.SObjectType.CountrySetting__c.getRecordTypeInfosByName().get('Journey Trigger').getRecordTypeId();
        cs_be_customer.Origin__c = 'Regular';
        csList.add(cs_be_customer);
        
        CountrySetting__c cs_be_mobileNotification_customer = new CountrySetting__c();
        cs_be_mobileNotification_customer.Name = 'BE - Sent to Mobile - Customer';
        cs_be_mobileNotification_customer.Country__c = 'SAP_0333';
        cs_be_mobileNotification_customer.Channel__c = 'Email';
        cs_be_mobileNotification_customer.Journey_Trigger_Type__c = 'Received in Mobile Notification';
        cs_be_mobileNotification_customer.Journey_Trigger_SubType__c = 'Received in Mobile Notification Customer';
        cs_be_mobileNotification_customer.Sending_Method__c = 'Send via MC';
        cs_be_mobileNotification_customer.Active__c = true;
        cs_be_mobileNotification_customer.RecordTypeId = Schema.SObjectType.CountrySetting__c.getRecordTypeInfosByName().get('Journey Trigger').getRecordTypeId();
        cs_be_mobileNotification_customer.Origin__c = 'Regular';
        csList.add(cs_be_mobileNotification_customer);

        CountrySetting__c cs_be_stakeholder = new CountrySetting__c();
        cs_be_stakeholder.Name = 'BE - Fulfillment Closure - Stakeholder';
        cs_be_stakeholder.Country__c = 'SAP_0333';
        cs_be_stakeholder.Channel__c = 'Email';
        cs_be_stakeholder.Journey_Trigger_Type__c = 'Fulfillment Closure';
        cs_be_stakeholder.Journey_Trigger_SubType__c = 'Fulfillment Summary Notification for Single Task to Stakeholder';
        cs_be_stakeholder.Sending_Method__c = 'Send via MC';
        cs_be_stakeholder.Active__c = true;
        cs_be_stakeholder.RecordTypeId = Schema.SObjectType.CountrySetting__c.getRecordTypeInfosByName().get('Journey Trigger').getRecordTypeId();
        cs_be_stakeholder.Origin__c = 'Regular';
        csList.add(cs_be_stakeholder);
        
        CountrySetting__c cs_be_mobileNotification_stakeholder = new CountrySetting__c();
        cs_be_mobileNotification_stakeholder.Name = 'BE - Sent to Mobile - Stakeholder';
        cs_be_mobileNotification_stakeholder.Country__c = 'SAP_0333';
        cs_be_mobileNotification_stakeholder.Channel__c = 'Email';
        cs_be_mobileNotification_stakeholder.Journey_Trigger_Type__c = 'Received in Mobile Notification';
        cs_be_mobileNotification_stakeholder.Journey_Trigger_SubType__c = 'Received in Mobile Notification Stakeholder';
        cs_be_mobileNotification_stakeholder.Sending_Method__c = 'Send via MC';
        cs_be_mobileNotification_stakeholder.Active__c = true;
        cs_be_mobileNotification_stakeholder.RecordTypeId = Schema.SObjectType.CountrySetting__c.getRecordTypeInfosByName().get('Journey Trigger').getRecordTypeId();
        cs_be_mobileNotification_stakeholder.Origin__c = 'Regular';
        csList.add(cs_be_mobileNotification_stakeholder);

        database.insert(csList);

    }
    
    /**
    * @author        Karen Hung
    * @date          9.18.2018        
    * @description   Method responsible for execution of batch
    * @revision(s)
    */
    static testMethod void attachTest_emailMC(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        TriggerSettings__c trg = TriggerSettings__c.getOrgDefaults();
        trg.WorkOrderLineItemTrigger__c = true;
        upsert trg;
        
        System.runAs(u) {
            //For Received in Mobile Notification
            List<WorkOrderLineItem> lineItemList1 = [SELECT Id,Status FROM WorkOrderLineItem WHERE Status = 'Scheduled' LIMIT 1];
       		lineItemList1[0].status = 'Received';
        	update lineItemList1[0];
           
            test.startTest();
                TS_AttachPDF_Batch attachPDF = new TS_AttachPDF_Batch();
                Database.executeBatch(attachPDF);
                System.assertEquals(dummyWoli, null);
            test.stopTest();
            
            List<WorkOrderLineItem> lineItemList2 = [SELECT Id,Status,Sent_to_Mobile_Notif_Sent__c FROM Workorderlineitem WHERE Status = 'Received' LIMIT 1];
            system.assertEquals(true, lineItemList2[0].Sent_to_Mobile_Notif_Sent__c);
        }
    }

    /**
    * @author        Abram Vixen Reyes
    * @date          October 21, 2020
    * @description   Test class for WorkOrderLineItemTriggerHandler.SendEmail -> Send via Salesforce Platform
    * @revision(s)
    */
    static testMethod void attachTest_emailApex(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        TriggerSettings__c trg = TriggerSettings__c.getOrgDefaults();
        trg.WorkOrderLineItemTrigger__c = true;
        upsert trg;

        Id recType = Schema.SObjectType.CountrySetting__c.getRecordTypeInfosByName().get('Journey Trigger').getRecordTypeId();
        List<CountrySetting__c> csList = [SELECT Id, Sending_Method__c FROM CountrySetting__c WHERE RecordTypeId =: recType];
        if(!csList.isEmpty()){
        	for(CountrySetting__c csvar : csList){
        		csvar.Sending_Method__c = 'Send via Salesforce Platform';
        	}
        	update csList;
        }
        
        System.runAs(u) {
           
            test.startTest();
                TS_AttachPDF_Batch attachPDF = new TS_AttachPDF_Batch();
                Database.executeBatch(attachPDF);
                System.assertEquals(dummyWoli, null);
            test.stopTest();
        }
    }
    
}