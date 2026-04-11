const amplifyConfig = r'''{
  "auth": {
    "user_pool_id": "us-east-1_DEobSEwDX",
    "aws_region": "us-east-1",
    "user_pool_client_id": "1n7an49kft6c6h37rjchovq7hv",
    "identity_pool_id": "us-east-1:ae7d9b70-154a-4ef1-84b4-5b6d1d615170",
    "mfa_methods": [],
    "standard_required_attributes": [],
    "username_attributes": [
      "email",
      "phone_number"
    ],
    "user_verification_types": [
      "email",
      "phone_number"
    ],
    "groups": [],
    "mfa_configuration": "NONE",
    "password_policy": {
      "min_length": 8,
      "require_lowercase": true,
      "require_numbers": true,
      "require_symbols": true,
      "require_uppercase": true
    },
    "unauthenticated_identities_enabled": true
  },
  "data": {
    "url": "https://jmqtxotnyjhmjekb35k3xwsseq.appsync-api.us-east-1.amazonaws.com/graphql",
    "aws_region": "us-east-1",
    "default_authorization_type": "AMAZON_COGNITO_USER_POOLS",
    "authorization_types": [
      "AWS_IAM"
    ],
    "model_introspection": {
      "version": 1,
      "models": {
        "OutingRecord": {
          "name": "OutingRecord",
          "fields": {
            "id": {
              "name": "id",
              "isArray": false,
              "type": "ID",
              "isRequired": true,
              "attributes": []
            },
            "title": {
              "name": "title",
              "isArray": false,
              "type": "String",
              "isRequired": true,
              "attributes": []
            },
            "createdBy": {
              "name": "createdBy",
              "isArray": false,
              "type": "String",
              "isRequired": true,
              "attributes": []
            },
            "payload": {
              "name": "payload",
              "isArray": false,
              "type": "String",
              "isRequired": true,
              "attributes": []
            },
            "closesAt": {
              "name": "closesAt",
              "isArray": false,
              "type": "AWSDateTime",
              "isRequired": false,
              "attributes": []
            },
            "createdAt": {
              "name": "createdAt",
              "isArray": false,
              "type": "AWSDateTime",
              "isRequired": false,
              "attributes": [],
              "isReadOnly": true
            },
            "updatedAt": {
              "name": "updatedAt",
              "isArray": false,
              "type": "AWSDateTime",
              "isRequired": false,
              "attributes": [],
              "isReadOnly": true
            }
          },
          "syncable": true,
          "pluralName": "OutingRecords",
          "attributes": [
            {
              "type": "model",
              "properties": {}
            },
            {
              "type": "auth",
              "properties": {
                "rules": [
                  {
                    "provider": "userPools",
                    "ownerField": "owner",
                    "allow": "owner",
                    "identityClaim": "cognito:username",
                    "operations": [
                      "create",
                      "update",
                      "delete",
                      "read"
                    ]
                  }
                ]
              }
            }
          ],
          "primaryKeyInfo": {
            "isCustomPrimaryKey": false,
            "primaryKeyFieldName": "id",
            "sortKeyFieldNames": []
          }
        },
        "ParticipantLocationEvent": {
          "name": "ParticipantLocationEvent",
          "fields": {
            "id": {
              "name": "id",
              "isArray": false,
              "type": "ID",
              "isRequired": true,
              "attributes": []
            },
            "participantName": {
              "name": "participantName",
              "isArray": false,
              "type": "String",
              "isRequired": true,
              "attributes": []
            },
            "utilityId": {
              "name": "utilityId",
              "isArray": false,
              "type": "String",
              "isRequired": true,
              "attributes": []
            },
            "destinationStopId": {
              "name": "destinationStopId",
              "isArray": false,
              "type": "String",
              "isRequired": false,
              "attributes": []
            },
            "statusMessage": {
              "name": "statusMessage",
              "isArray": false,
              "type": "String",
              "isRequired": false,
              "attributes": []
            },
            "isBusy": {
              "name": "isBusy",
              "isArray": false,
              "type": "Boolean",
              "isRequired": false,
              "attributes": []
            },
            "shareMode": {
              "name": "shareMode",
              "isArray": false,
              "type": "String",
              "isRequired": true,
              "attributes": []
            },
            "lat": {
              "name": "lat",
              "isArray": false,
              "type": "Float",
              "isRequired": true,
              "attributes": []
            },
            "lng": {
              "name": "lng",
              "isArray": false,
              "type": "Float",
              "isRequired": true,
              "attributes": []
            },
            "speedMps": {
              "name": "speedMps",
              "isArray": false,
              "type": "Float",
              "isRequired": false,
              "attributes": []
            },
            "sharedAt": {
              "name": "sharedAt",
              "isArray": false,
              "type": "AWSDateTime",
              "isRequired": true,
              "attributes": []
            },
            "expiresAt": {
              "name": "expiresAt",
              "isArray": false,
              "type": "AWSDateTime",
              "isRequired": false,
              "attributes": []
            },
            "createdAt": {
              "name": "createdAt",
              "isArray": false,
              "type": "AWSDateTime",
              "isRequired": false,
              "attributes": [],
              "isReadOnly": true
            },
            "updatedAt": {
              "name": "updatedAt",
              "isArray": false,
              "type": "AWSDateTime",
              "isRequired": false,
              "attributes": [],
              "isReadOnly": true
            }
          },
          "syncable": true,
          "pluralName": "ParticipantLocationEvents",
          "attributes": [
            {
              "type": "model",
              "properties": {}
            },
            {
              "type": "auth",
              "properties": {
                "rules": [
                  {
                    "provider": "userPools",
                    "ownerField": "owner",
                    "allow": "owner",
                    "operations": [
                      "create",
                      "delete"
                    ],
                    "identityClaim": "cognito:username"
                  },
                  {
                    "allow": "private",
                    "operations": [
                      "read"
                    ]
                  }
                ]
              }
            }
          ],
          "primaryKeyInfo": {
            "isCustomPrimaryKey": false,
            "primaryKeyFieldName": "id",
            "sortKeyFieldNames": []
          }
        }
      },
      "enums": {},
      "nonModels": {}
    }
  },
  "version": "1.4"
}''';