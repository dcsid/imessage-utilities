import { type ClientSchema, a, defineData } from '@aws-amplify/backend';

const schema = a.schema({
  UtilityInstance: a
    .model({
      title: a.string().required(),
      createdBy: a.string().required(),
      participants: a.string().array(),
      startsAt: a.datetime(),
      endsAt: a.datetime(),
      closesAt: a.datetime(),
    })
    .authorization((allow) => [allow.publicApiKey()]),

  ParticipantLocationEvent: a
    .model({
      participantName: a.string().required(),
      utilityId: a.id().required(),
      lat: a.float().required(),
      lng: a.float().required(),
      sharedAt: a.datetime().required(),
      expiresAt: a.datetime(),
    })
    .authorization((allow) => [allow.publicApiKey()]),
});

export type Schema = ClientSchema<typeof schema>;

export const data = defineData({
  schema,
  authorizationModes: {
    defaultAuthorizationMode: 'apiKey',
    apiKeyAuthorizationMode: {
      expiresInDays: 30,
    },
  },
});
