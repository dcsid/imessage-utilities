const amplifyConfig = r'''{
  "auth": {
    "user_pool_id": "us-east-1_XQ4v4z0Lu",
    "aws_region": "us-east-1",
    "user_pool_client_id": "14r71m9rg56evpivaf60t48ak6",
    "identity_pool_id": "us-east-1:cec54f1e-c922-4c06-b89e-bb20c8065dc1",
    "mfa_methods": [],
    "standard_required_attributes": [
      "email"
    ],
    "username_attributes": [
      "email"
    ],
    "user_verification_types": [
      "email"
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
    "url": "https://pekbbpninjcfhld3f4u6vnvdbu.appsync-api.us-east-1.amazonaws.com/graphql",
    "aws_region": "us-east-1",
    "api_key": "da2-peyazqjzcbe4xhmwj6nlugteba",
    "default_authorization_type": "API_KEY",
    "authorization_types": [
      "AMAZON_COGNITO_USER_POOLS",
      "AWS_IAM"
    ],
    "model_introspection": {
      "version": 1,
      "models": {
        "UtilityInstance": {
          "name": "UtilityInstance",
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
            "participants": {
              "name": "participants",
              "isArray": true,
              "type": "String",
              "isRequired": false,
              "attributes": [],
              "isArrayNullable": true
            },
            "startsAt": {
              "name": "startsAt",
              "isArray": false,
              "type": "AWSDateTime",
              "isRequired": false,
              "attributes": []
            },
            "endsAt": {
              "name": "endsAt",
              "isArray": false,
              "type": "AWSDateTime",
              "isRequired": false,
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
          "pluralName": "UtilityInstances",
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
                    "allow": "public",
                    "provider": "apiKey",
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
              "type": "ID",
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
                    "allow": "public",
                    "provider": "apiKey",
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
        }
      },
      "enums": {},
      "nonModels": {}
    }
  },
  "version": "1.4"
}''';