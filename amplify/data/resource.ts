import { type ClientSchema, a, defineData } from '@aws-amplify/backend';

const schema = a.schema({
  OutingRecord: a
    .model({
      title: a.string().required(),
      createdBy: a.string().required(),
      payload: a.string().required(),
      closesAt: a.datetime(),
    })
    .authorization((allow) => [allow.owner()]),
  ParticipantLocationEvent: a
    .model({
      participantName: a.string().required(),
      utilityId: a.string().required(),
      destinationStopId: a.string(),
      statusMessage: a.string(),
      isBusy: a.boolean(),
      shareMode: a.string().required(),
      lat: a.float().required(),
      lng: a.float().required(),
      speedMps: a.float(),
      sharedAt: a.datetime().required(),
      expiresAt: a.datetime(),
    })
    .authorization((allow) => [
      allow.owner().to(['create', 'delete']),
      allow.authenticated().to(['read']),
    ]),
});

export type Schema = ClientSchema<typeof schema>;

export const data = defineData({
  schema,
  authorizationModes: {
    defaultAuthorizationMode: 'userPool',
  },
});
