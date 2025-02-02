# AWS Signature v4 Implementation using Apex Salesforce

This Apex class implements AWS Signature Version 4 authentication to interact with AWS Bedrock services from Salesforce.

## Features
- AWS Signature Version 4 authentication
- Integration with AWS Bedrock's Titan model
- Custom Metadata Type configuration for AWS credentials
- Support for invoking large language models (LLMs)
- Complete request signing implementation in Apex

## Prerequisites
- Salesforce Org with Apex access
- AWS Account with Bedrock service access
- IAM user with `bedrock:InvokeModel` permission
- AWS Access Key and Secret Key for authentication

## Setup

1. **Create Custom Metadata Type**
   - Create a Custom Metadata Type named `AWS_Settings` with these fields:
     - `AWS_Region__c` (Text, 50) - e.g., `ap-south-1`
     - `Service_Name__c` (Text, 50) - e.g., `bedrock`
     - `Http_Method__c` (Text, 10) - e.g., `POST`
     - `AWS_Access_Key__c` (Text, 255) - AWS IAM Access Key
     - `AWS_Secret_Key__c` (Text, 255) - AWS IAM Secret Key
     - `Endpoint__c` (Text, 255) - Service endpoint URL

2. **Configure AWS Settings**
   Create a record in `AWS_Settings__mdt` with your AWS configuration:
   ```json
   {
     "AWS_Region__c": "your-aws-region",
     "Service_Name__c": "bedrock",
     "Http_Method__c": "POST",
     "AWS_Access_Key__c": "YOUR_AWS_ACCESS_KEY",
     "AWS_Secret_Key__c": "YOUR_AWS_SECRET_KEY",
     "Endpoint__c": "https://bedrock-runtime.ap-south-1.amazonaws.com"
   }
   ```

## Usage

```apex
// Invoke the LLM model
String response = AWSBedrockService.invokeLLM();
System.debug('Model Response: ' + response);
```

## Security Considerations
- Store AWS credentials in Protected Custom Metadata
- Use encrypted fields for AWS Secret Key storage
- Follow least privilege principle for IAM permissions
- Regularly rotate AWS access keys

## Troubleshooting

**Common Issues:**
- 403 Forbidden: Verify IAM permissions and credentials
- 400 Bad Request: Check request payload format
- Signature mismatch: Verify canonical request calculation

**Debugging Tips:**
1. Check debug logs for:
   - Canonical request
   - String-to-sign
   - Generated signature
2. Verify:
   - Timestamp synchronization (UTC)
   - Region/service name matches
   - Endpoint URL correctness

## Example Response
```json
{
  "results": [
    {
      "outputText": "\nOnce upon a time, a curious tabby cat named Miso discovered a secret garden...",
      "completionReason": "FINISH"
    }
  ]
}
```

## References
- [AWS Signature Version 4 Documentation](https://docs.aws.amazon.com/general/latest/gr/signature-version-4.html)
- [AWS Bedrock Service Documentation](https://aws.amazon.com/bedrock/)
- [Salesforce HMAC SHA256 Implementation](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_classes_restful_crypto.htm)

