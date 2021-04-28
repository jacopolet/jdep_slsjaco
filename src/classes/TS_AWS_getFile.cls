public class TS_AWS_getFile {
    
    /*
Author:     Archi Delphinanto / Harold Marilag
Created date: 06-07-2017
Objective:    Get file  Amazon Web Service S3 with the given inputs 
Input:      use TS_AWS_GetToken or put String laccesskeyid,String lsecretkey, String ltoken, String lregion, String lresource, String lendpoint, String lpayload, String lquery
output:     HTTP response 
*/
    
    // Not used externally, so we hide these values
    Map<String, String> queryParams;
    Map<String, String> headerParams;
    String payloadSha256;
    Blob signingKey;
    DateTime requestTime; 
    public enum HttpMethod { XGET, XPUT, XHEAD, XOPTIONS, XDELETE, XPOST }
    
    public TS_AWS_getFile() {
        try{
            requestTime = DateTime.now();
            queryParams = new Map<String, String>();
            headerParams = new Map<String, String>();
            //payload = Blob.valueOf('');
        }
        catch(Exception e){
            system.debug('TS_AWS_getFile - Constructor, query param: ' + e.getMessage());
        }
    }
    private String createStringToSign(String[] signedHeaders, string ltime, string lregion, string lservice,  Url lendpoint, String lresource, String lquerystring, string lpayloadSha256, HttpMethod hmethod) {
        CustomLogging.push('createStringToSign', 'TS_AWS_getFile');
        System.debug('before create canonical request, headerKeys: '+signedHeaders);
        String canreq = createCanonicalRequest(signedHeaders,  lendpoint, lresource, lquerystring, lpayloadSha256, hmethod);
        // System.debug('Canonical Request: '  + canreq);
        System.debug('after create canonical request, headerKeys: '+signedHeaders);
        string cts=String.join(
            new String[] {
                'AWS4-HMAC-SHA256',
                    headerParams.get('x-amz-date'),
                    String.join(new String[] { ltime, lregion, lservice, 'aws4_request' },'/'),
                    EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueof(canreq)))
                    },
            '\n'
        );
        System.debug('TS_AWS_GetFile-createStringToSing, output String to sign: '+cts);
        CustomLogging.pop();
        return cts;
    }
    
    String createCanonicalRequest(String[] headerKeys, Url lendpoint, String lresource, String lquerystring, string lpayloadSha256, HttpMethod hmethod) {
        CustomLogging.push('createCanonicalRequest', 'TS_AWS_getFile');
        String ccr =         String.join(
            new String[] {
                hmethod.name().removeStart('X'),    //  METHOD
                    new Url(lendpoint, lresource).getPath(),  //  RESOURCE
                    createCanonicalQueryString(),    //  CANONICAL QUERY STRING
                    createCanonicalHeaders(headerKeys),  //  CANONICAL HEADERS
                    String.join(headerKeys, ';'),    //  SIGNED HEADERS
                    lpayloadSha256        //  SHA256 PAYLOAD
                    },
            '\n'
        );
        System.debug('Canonical request: '+ccr);
        System.debug('headerKeys: '+headerKeys);
        CustomLogging.pop();
        return ccr ;
    }
    /*
private void setQueryParam(String key, String value) {
queryParams.put(key, uriEncode(value));
}
*/
    private String createCanonicalQueryString() {
        CustomLogging.push('createCanonicalQueryString', 'TS_AWS_getFile');
        String[] results = new String[0];
        List<String> keys = new List<String>(queryParams.keySet());
        
        keys.sort();
        for(String key: keys) {
            results.add(key+'='+queryParams.get(key));
        }
        CustomLogging.pop();
        return String.join(results, '&');
    }
    
    String createCanonicalHeaders(String[] keys) {
        CustomLogging.push('createCanonicalHeaders', 'TS_AWS_getFile');
        // keys.addAll(headerParams.keySet());
        keys.sort();
        String[] results = new String[0];
        for(String key: keys) {
            results.add(key+':'+headerParams.get(key));
        }
        String canheader = String.join(results, '\n')+'\n';
        CustomLogging.pop();
        return canheader;
    }
    private HttpResponse sendRequest(Set<Integer> validCodes, String laccesskeyid,String lsecretkey, String ltoken, String lregion, String lresource, String lendpoint, String lpayload, String lquery) {
        CustomLogging.push('sendRequest', 'TS_AWS_getFile'); 
        // HttpRequest request = createRequest( laccesskeyid, lsecretkey, ltoken, lregion, lresource, lendpoint, lpayload,  lquery);
        // HttpResponse response = !Test.isRunningTest() ? new Http().send(request) : new HttpResponse();
        
        HttpRequest request;
        HttpResponse response;
        try{
            request = createRequest( laccesskeyid, lsecretkey, ltoken, lregion, lresource, lendpoint, lpayload,  lquery);
            response =  new Http().send(request);                
        }
        catch(Exception e){
            system.debug('TS_AWS_getFile - sendRequest, request or response error: ' + e.getMessage());
        }
        
        System.debug('------ AWS sendRequest --------- ' );
        System.debug('HTTPResponse REAL res ' + response);
        System.debug('HTTPResponse REAL res.getStatus ' + response.getStatus());
        System.debug('HTTPResponse REAL res.getBody() ' + response.getBody());
        system.debug('request: '+request);
        CustomLogging.pop();
        return response;
    }
    
    //  Same as above, but assume that only 200 is valid
    //  This method exists because most of the time, 200 is what we expect
    public HttpResponse sendRequest(String laccesskeyid,String lsecretkey, String ltoken, String lregion, String lresource, String lendpoint, String lpayload, String lquery) {
        CustomLogging.push('sendRequest', 'TS_AWS_getFile');
        CustomLogging.pop();
        return sendRequest(new Set<Integer> { 200 }, laccesskeyid, lsecretkey, ltoken, lregion,lresource, lendpoint, lpayload,  lquery);
    }
    // Add put REST headers into headerparams list
    private void setHeader(String key, String value) {
        CustomLogging.push('setHeader', 'TS_AWS_getFile');
        CustomLogging.pop();
        headerParams.put(key.toLowerCase('EN'), value);
    }
    
    private Blob createSigningKey(String secretaccessKey, string lregion, String lservice) {
        CustomLogging.push('createSigningKey', 'TS_AWS_getFile');
        Blob datekey = Crypto.generateMac('hmacSHA256', Blob.valueOf(requestTime.formatGMT('YYYYMMdd')), Blob.valueOf('AWS4'+secretaccessKey));
        Blob regionkey = Crypto.generateMac('hmacSHA256', Blob.valueOf(lregion),datekey);
        Blob dateregionservicekey = Crypto.generateMac('hmacSHA256', Blob.valueOf(lservice),regionkey);
        Blob lsigningkey =  Crypto.generateMac('hmacSHA256', Blob.valueOf('aws4_request'),dateregionservicekey);      
        System.debug('Signing key:  '+string.valueof(lsigningkey));
        CustomLogging.pop();
        return lsigningkey;
    }
    
    private HttpRequest createRequest(String laccesskeyid,String lsecretkey, String ltoken, String lregion, String lresource, String lendpoint, String lpayload, String lquery) {
        CustomLogging.push('createRequest', 'TS_AWS_getFile');
        //input required: accesskey, secretkey, url, token, aws region,
        //payload is set empty 
        
        
        //-------set headers-----------//
        setHeader('x-amz-security-token', ltoken); 
        setHeader('x-amz-date', requestTime.formatGMT('YYYYMMdd\'T\'HHmmss\'Z\''));
        
        
        //-------set request---------//
        HttpRequest request = new HttpRequest();
        
        //-------set method---------//
        HttpMethod hmethod = HttpMethod.XGET; //fixed the method with GET
        request.setMethod(hmethod.name().removeStart('X'));
        
        //------set payload ---------//
        Blob payload = Blob.valueOf(lpayload);
        if(payload.size() > 0) {
            payloadSha256 = EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', payload));
            setHeader('x-amz-content-sha256', payloadSha256);
            setHeader('Content-MD5', EncodingUtil.base64Encode(Crypto.generateDigest('MD5', payload)));
            setHeader('Content-Length', String.valueOf(payload.size()));
            request.setBodyAsBlob(payload);
        }else{
            payloadSha256='e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'; //hashkey of empty string
            setHeader('x-amz-content-sha256', payloadSha256);
        }
        
        //---set final end point and query string if any -------//        
        Url lurlendpoint = new Url(lendpoint);
        String finalEndpoint = new Url(lurlendpoint, lresource).toExternalForm(), 
            queryString = '';
        
        if(lquery != '') {
            finalEndpoint += '?'+lquery;
        }
        
        setHeader('host', lurlendpoint.getHost());
        
        System.debug('Final Endpoint:  ' + finalEndpoint);
        System.debug('Canonical Query String:  ' + lquery);
        request.setEndpoint(finalEndpoint);
        
        //------ put header params in request headers ------------//
        List <String> headerKeys = new List <String>();//[];
        for(String key: headerParams.keySet()) {
            request.setHeader(key, headerParams.get(key));
            headerKeys.add(key);
        }
        
        System.debug('header parameters: '  +headerParams);
        System.debug('headerKeys parameters: '  +headerKeys);
        
        String reqTime = requestTime.formatGMT('YYYYMMdd');
        String lservice = 's3';
        String lpayloadSha256 = payloadSha256;
        String strtosign = createStringToSign(headerKeys, reqTime, lregion, lservice,  lurlendpoint, lresource, lquery,  lpayloadSha256, hmethod) ;
        Blob signingkey = createSigningKey(lsecretkey,  lregion, lservice);
        String awssign= EncodingUtil.convertToHex(Crypto.generateMac('hmacSHA256', Blob.valueOf(strtosign), signingkey));        
        request.setHeader( 'Authorization', String.format( 'AWS4-HMAC-SHA256 Credential={0},SignedHeaders={1},Signature={2}', new String[] {
            String.join(new String[] { laccesskeyid, requestTime.formatGMT('YYYYMMdd'), lregion, lservice, 'aws4_request' },'/'),
                String.join(headerKeys,';'),awssign}
                                                         ));
        
        System.debug('Authorization Header: ' + request.getHeader('Authorization'));
        CustomLogging.pop();
        return request;
    }
    
    
}