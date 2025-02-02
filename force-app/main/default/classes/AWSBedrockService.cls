public class AWSBedrockService {
    public static String invokeLLM( ) {
        AWS_Settings__mdt settings = [
            SELECT AWS_Region__c, Service_Name__c, Http_Method__c, 
                   AWS_Access_Key__c, AWS_Secret_Key__c, Endpoint__c
            FROM AWS_Settings__mdt
            LIMIT 1
        ];
        
        String AWS_REGION = settings.AWS_Region__c; 
        String SERVICE_NAME = settings.Service_Name__c;
        String HTTP_METHOD = settings.Http_Method__c;
        String AWS_ACCESS_KEY = settings.AWS_Access_Key__c; 
        String AWS_SECRET_KEY = settings.AWS_Secret_Key__c;
        String ENDPOINT = settings.Endpoint__c;
        
        String modelIdentifier = 'amazon.titan-text-lite-v1';
        String payload = '{"inputText": "write me a 50 words story about cat"}';
        String host = 'bedrock-runtime.ap-south-1.amazonaws.com';
        String canonicalUri = '/model/' + modelIdentifier + '/invoke';
        String contentHash = EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueOf(payload)));

        //headers and canonical query string
        String amzDate = getAmzDate();
        String dateStamp = amzDate.substring(0, 8);
        String credentialScope = dateStamp + '/' + AWS_REGION + '/' + SERVICE_NAME + '/' + 'aws4_request';

        Map<String, String> headers = new Map<String, String>{
            'host' => host,
            'x-amz-date' => amzDate,
            'x-amz-target' => 'AWSBedrock.InvokeModel'
        };

        String canonicalHeaders = buildCanonicalHeaders(headers);
        String signedHeaders = String.join(headers.keySet(), ';');

        //canonical request
        String canonicalRequest = HTTP_METHOD + '\n' +
            canonicalUri + '\n' +
            '' + '\n' + // No query needed for bedrock
            canonicalHeaders + '\n' +
            signedHeaders + '\n' +
            contentHash;

        //string to sign
        String algorithm = 'AWS4-HMAC-SHA256';
        String stringToSign = algorithm + '\n' +
            amzDate + '\n' +
            credentialScope + '\n' +
            EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueOf(canonicalRequest)));

        //signature
        Blob signingKey = getSignatureKey(AWS_SECRET_KEY, dateStamp, AWS_REGION, SERVICE_NAME);
        String signature = EncodingUtil.convertToHex(Crypto.generateMac('HmacSHA256', Blob.valueOf(stringToSign), signingKey));

        // authorization header
        String authorizationHeader = algorithm + ' Credential=' + AWS_ACCESS_KEY + '/' + credentialScope +
            ', SignedHeaders=' + signedHeaders +
            ', Signature=' + signature;

        //HTTP request
        HttpRequest req = new HttpRequest();
        req.setEndpoint(ENDPOINT);
        req.setMethod(HTTP_METHOD);
        req.setHeader('Authorization', authorizationHeader);
        req.setHeader('x-amz-date', amzDate);
        req.setHeader('Accept', 'application/json');
        req.setHeader('x-amz-target', 'AWSBedrock.InvokeModel');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(payload);

        Http http = new Http();
        HttpResponse res = http.send(req);
        if (res.getStatusCode() == 200) {
            system.debug('Model Output'+res.getBody());
            return res.getBody();
        } else {
            throw new CalloutException('Failed with status code ' + res.getStatusCode() + ': ' + res.getBody());
        }
    }

    //current AWS date format
    private static String getAmzDate() {
        return Datetime.now().formatGMT('yyyyMMdd\'T\'HHmmss\'Z\'');
    }

    //canonical headers
    private static String buildCanonicalHeaders(Map<String, String> headers) {
        List<String> sortedKeys = new List<String>(headers.keySet());
        sortedKeys.sort();
        List<String> canonicalHeaders = new List<String>();
        for (String key : sortedKeys) {
            canonicalHeaders.add(key.toLowerCase() + ':' + headers.get(key).trim());
        }
        return String.join(canonicalHeaders, '\n') + '\n';
    }

    //signing key
    private static Blob getSignatureKey(String key, String dateStamp, String regionName, String serviceName) {
        Blob kDate = Crypto.generateMac('HmacSHA256', Blob.valueOf(dateStamp), Blob.valueOf('AWS4' + key));
        Blob kRegion = Crypto.generateMac('HmacSHA256', Blob.valueOf(regionName), kDate);
        Blob kService = Crypto.generateMac('HmacSHA256', Blob.valueOf(serviceName), kRegion);
        Blob kSigning = Crypto.generateMac('HmacSHA256', Blob.valueOf('aws4_request'), kService);
        return kSigning;
    }
}