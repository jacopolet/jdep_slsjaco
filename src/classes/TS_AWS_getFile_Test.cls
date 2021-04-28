/**
* @author        Harold Marilag
* @date          7.7.2017           
* @description   Test Class for TS_AWS_getToken
* @revision(s)
*/
@isTest
public class TS_AWS_getFile_Test {
    

@isTest  static  void testGetAWSFile() {
/*
        String username = 'integration@JDEDev01';
        String password = 'ClickJDE2016';
        String endpoint = 'https://eu01-int.cloud.clicksoftware.com//SO/api/S3Token';
             */   
        QueueableAPILogin_Mock awsfileresult= new QueueableAPILogin_Mock();       
        awsfileresult.body = '{"User": null, "Bucket": "eu01-s3-store", "AccessKeyId": "ASIAJWHUXVYYGGXO272Q", "SecretAccessKey": "vCVHLTRnMQInW4bxFVqNrh3RA3C/iEoiUvA5qhgd", "Token": "FQoDYXdzEOr//////////wEaDBMeLgAq9I5kToJjdSK+AhCFUgs4+79ft9RXLAlWhiXw6v3EzSV/OJeGMfVh/2wKVTx60kxgO26ppNj7Gy0UHFZ6yH+m0vXgt4LB0ETLxMCLqf+zuyDOHUCLoxihN0SUoG7s/80ROQqyHXEnk0RUbhZdaYIFlguGGBEkq56PEqPI7oiebS/PdtKvFjKS8skNOLAVk+LMK1KIUGszFO4gMHbMRW0bBMWhTB+qXBe9EJNmsDEqfXxKUzF7xFy+Aypl5DA6ZY1TSDyNUXx6CCmMQfewlKNg932SsLLj+7CAzYLpvjqLm+vHUd0iAZxMP3FqqdoHKjh1BBWVfhzSuH0YKpdxI706HzsHTBxPQ0y79Oq59ZEDjcEylez0fdULjVQ7zE0B7O3Qh92dBqPmtetLhfWpr88H3zUezvk+1CKRqzaPadTnTMdArsOWdqsDISiXqu3KBQ==", "Expiration": "2017-07-04T16:43:03+00:00", "AWSRegion": "eu-central-1"}';
        awsfileresult.callstatus =200;
        Test.setMock(HttpCalloutMock.class, awsfileresult);
       //TS_AWS_getToken file = new TS_AWS_getToken();
		//TS_AWS_getToken.AWSTokenResult tr =    aws.gettoken(username, password, endpoint);
        String laccesskeyid = '123';
        String lsecretkey= '456';
        String ltoken='789';
        String lregion= 'eu-central-1';
        String lendpoint ='https://eu01-s3-store.s3.amazonaws.com';
        String lpayload = '';
        String lquery='';
        String lresource  ='/jdedev01/%28S3%29b0f8a244%28S3%29_MasterData_Relations_Dic.jpg';
        TS_AWS_getFile gf = new TS_AWS_getFile();
        HttpResponse awsfile = gf.sendRequest(laccesskeyid,lsecretkey,  ltoken, lregion, lresource, lendpoint,lpayload, lquery);
        system.assertNotEquals(null, awsfile.getBody());
        //system.debug(awsfile);*/

      }

@isTest static  void testGetAWSFileQuerry() {
/*
        String username = 'integration@JDEDev01';
        String password = 'ClickJDE2016';
        String endpoint = 'https://eu01-int.cloud.clicksoftware.com//SO/api/S3Token';
             */   
        QueueableAPILogin_Mock awsfileresult= new QueueableAPILogin_Mock();       
        awsfileresult.body = '{"User": null, "Bucket": "eu01-s3-store", "AccessKeyId": "ASIAJWHUXVYYGGXO272Q", "SecretAccessKey": "vCVHLTRnMQInW4bxFVqNrh3RA3C/iEoiUvA5qhgd", "Token": "FQoDYXdzEOr//////////wEaDBMeLgAq9I5kToJjdSK+AhCFUgs4+79ft9RXLAlWhiXw6v3EzSV/OJeGMfVh/2wKVTx60kxgO26ppNj7Gy0UHFZ6yH+m0vXgt4LB0ETLxMCLqf+zuyDOHUCLoxihN0SUoG7s/80ROQqyHXEnk0RUbhZdaYIFlguGGBEkq56PEqPI7oiebS/PdtKvFjKS8skNOLAVk+LMK1KIUGszFO4gMHbMRW0bBMWhTB+qXBe9EJNmsDEqfXxKUzF7xFy+Aypl5DA6ZY1TSDyNUXx6CCmMQfewlKNg932SsLLj+7CAzYLpvjqLm+vHUd0iAZxMP3FqqdoHKjh1BBWVfhzSuH0YKpdxI706HzsHTBxPQ0y79Oq59ZEDjcEylez0fdULjVQ7zE0B7O3Qh92dBqPmtetLhfWpr88H3zUezvk+1CKRqzaPadTnTMdArsOWdqsDISiXqu3KBQ==", "Expiration": "2017-07-04T16:43:03+00:00", "AWSRegion": "eu-central-1"}';
        awsfileresult.callstatus =404;
        Test.setMock(HttpCalloutMock.class, awsfileresult);
       //TS_AWS_getToken file = new TS_AWS_getToken();
		//TS_AWS_getToken.AWSTokenResult tr =    aws.gettoken(username, password, endpoint);
        String laccesskeyid = '123';
        String lsecretkey= '456';
        String ltoken='789';
        String lregion= 'eu-central-1';
        String lendpoint ='https://eu01-s3-store.s3.amazonaws.com';
        String lpayload = '1234';
        String lquery='id:1234';
        String lresource  ='/jdedev01/%28S3%29b0f8a244%28S3%29_MasterData_Relations_Dic.jpg';
        TS_AWS_getFile gf = new TS_AWS_getFile();
        HttpResponse awsfile = gf.sendRequest(laccesskeyid,lsecretkey,  ltoken, lregion, lresource, lendpoint,lpayload, lquery);
        system.assertNotEquals(null, awsfile.getBody());
        //system.debug(awsfile);*/

      }


}