const amplifyConfig = r'''{
  "auth": {
    "user_pool_id": "us-east-1_IIs0jmA7x",
    "aws_region": "us-east-1",
    "user_pool_client_id": "3sgv5igti6dugprut9db4s64ut",
    "identity_pool_id": "us-east-1:2da52d3b-c9fd-44ef-a948-75ba923bdc53",
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
  "version": "1.4"
}''';