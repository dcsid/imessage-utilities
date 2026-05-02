import { defineAuth } from '@aws-amplify/backend';

// Email-only on purpose. Cognito SMS verification incurs per-message SNS
// charges, so phone login is intentionally disabled until/unless the
// owner explicitly turns it on.
export const auth = defineAuth({
  loginWith: {
    email: true,
  },
  userAttributes: {
    email: {
      required: true,
      mutable: true,
    },
  },
  accountRecovery: 'EMAIL_ONLY',
});
