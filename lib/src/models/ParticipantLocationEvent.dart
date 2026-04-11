/*
* Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
*
* Licensed under the Apache License, Version 2.0 (the "License").
* You may not use this file except in compliance with the License.
* A copy of the License is located at
*
*  http://aws.amazon.com/apache2.0
*
* or in the "license" file accompanying this file. This file is distributed
* on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
* express or implied. See the License for the specific language governing
* permissions and limitations under the License.
*/

// NOTE: This file is generated and may not follow lint rules defined in your app
// Generated files can be excluded from analysis in analysis_options.yaml
// For more info, see: https://dart.dev/guides/language/analysis-options#excluding-code-from-analysis

// ignore_for_file: public_member_api_docs, annotate_overrides, dead_code, dead_codepublic_member_api_docs, depend_on_referenced_packages, file_names, library_private_types_in_public_api, no_leading_underscores_for_library_prefixes, no_leading_underscores_for_local_identifiers, non_constant_identifier_names, null_check_on_nullable_type_parameter, override_on_non_overriding_member, prefer_adjacent_string_concatenation, prefer_const_constructors, prefer_if_null_operators, prefer_interpolation_to_compose_strings, slash_for_doc_comments, sort_child_properties_last, unnecessary_const, unnecessary_constructor_name, unnecessary_late, unnecessary_new, unnecessary_null_aware_assignments, unnecessary_nullable_for_final_variable_declarations, unnecessary_string_interpolations, use_build_context_synchronously

import 'ModelProvider.dart';
import 'package:amplify_core/amplify_core.dart' as amplify_core;


/** This is an auto generated class representing the ParticipantLocationEvent type in your schema. */
class ParticipantLocationEvent extends amplify_core.Model {
  static const classType = const _ParticipantLocationEventModelType();
  final String id;
  final String? _participantName;
  final String? _utilityId;
  final String? _destinationStopId;
  final String? _statusMessage;
  final bool? _isBusy;
  final String? _shareMode;
  final double? _lat;
  final double? _lng;
  final double? _speedMps;
  final amplify_core.TemporalDateTime? _sharedAt;
  final amplify_core.TemporalDateTime? _expiresAt;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  ParticipantLocationEventModelIdentifier get modelIdentifier {
      return ParticipantLocationEventModelIdentifier(
        id: id
      );
  }
  
  String get participantName {
    try {
      return _participantName!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String get utilityId {
    try {
      return _utilityId!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String? get destinationStopId {
    return _destinationStopId;
  }
  
  String? get statusMessage {
    return _statusMessage;
  }
  
  bool? get isBusy {
    return _isBusy;
  }
  
  String get shareMode {
    try {
      return _shareMode!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  double get lat {
    try {
      return _lat!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  double get lng {
    try {
      return _lng!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  double? get speedMps {
    return _speedMps;
  }
  
  amplify_core.TemporalDateTime get sharedAt {
    try {
      return _sharedAt!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  amplify_core.TemporalDateTime? get expiresAt {
    return _expiresAt;
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const ParticipantLocationEvent._internal({required this.id, required participantName, required utilityId, destinationStopId, statusMessage, isBusy, required shareMode, required lat, required lng, speedMps, required sharedAt, expiresAt, createdAt, updatedAt}): _participantName = participantName, _utilityId = utilityId, _destinationStopId = destinationStopId, _statusMessage = statusMessage, _isBusy = isBusy, _shareMode = shareMode, _lat = lat, _lng = lng, _speedMps = speedMps, _sharedAt = sharedAt, _expiresAt = expiresAt, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory ParticipantLocationEvent({String? id, required String participantName, required String utilityId, String? destinationStopId, String? statusMessage, bool? isBusy, required String shareMode, required double lat, required double lng, double? speedMps, required amplify_core.TemporalDateTime sharedAt, amplify_core.TemporalDateTime? expiresAt}) {
    return ParticipantLocationEvent._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      participantName: participantName,
      utilityId: utilityId,
      destinationStopId: destinationStopId,
      statusMessage: statusMessage,
      isBusy: isBusy,
      shareMode: shareMode,
      lat: lat,
      lng: lng,
      speedMps: speedMps,
      sharedAt: sharedAt,
      expiresAt: expiresAt);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ParticipantLocationEvent &&
      id == other.id &&
      _participantName == other._participantName &&
      _utilityId == other._utilityId &&
      _destinationStopId == other._destinationStopId &&
      _statusMessage == other._statusMessage &&
      _isBusy == other._isBusy &&
      _shareMode == other._shareMode &&
      _lat == other._lat &&
      _lng == other._lng &&
      _speedMps == other._speedMps &&
      _sharedAt == other._sharedAt &&
      _expiresAt == other._expiresAt;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("ParticipantLocationEvent {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("participantName=" + "$_participantName" + ", ");
    buffer.write("utilityId=" + "$_utilityId" + ", ");
    buffer.write("destinationStopId=" + "$_destinationStopId" + ", ");
    buffer.write("statusMessage=" + "$_statusMessage" + ", ");
    buffer.write("isBusy=" + (_isBusy != null ? _isBusy!.toString() : "null") + ", ");
    buffer.write("shareMode=" + "$_shareMode" + ", ");
    buffer.write("lat=" + (_lat != null ? _lat!.toString() : "null") + ", ");
    buffer.write("lng=" + (_lng != null ? _lng!.toString() : "null") + ", ");
    buffer.write("speedMps=" + (_speedMps != null ? _speedMps!.toString() : "null") + ", ");
    buffer.write("sharedAt=" + (_sharedAt != null ? _sharedAt!.format() : "null") + ", ");
    buffer.write("expiresAt=" + (_expiresAt != null ? _expiresAt!.format() : "null") + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  ParticipantLocationEvent copyWith({String? participantName, String? utilityId, String? destinationStopId, String? statusMessage, bool? isBusy, String? shareMode, double? lat, double? lng, double? speedMps, amplify_core.TemporalDateTime? sharedAt, amplify_core.TemporalDateTime? expiresAt}) {
    return ParticipantLocationEvent._internal(
      id: id,
      participantName: participantName ?? this.participantName,
      utilityId: utilityId ?? this.utilityId,
      destinationStopId: destinationStopId ?? this.destinationStopId,
      statusMessage: statusMessage ?? this.statusMessage,
      isBusy: isBusy ?? this.isBusy,
      shareMode: shareMode ?? this.shareMode,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      speedMps: speedMps ?? this.speedMps,
      sharedAt: sharedAt ?? this.sharedAt,
      expiresAt: expiresAt ?? this.expiresAt);
  }
  
  ParticipantLocationEvent copyWithModelFieldValues({
    ModelFieldValue<String>? participantName,
    ModelFieldValue<String>? utilityId,
    ModelFieldValue<String?>? destinationStopId,
    ModelFieldValue<String?>? statusMessage,
    ModelFieldValue<bool?>? isBusy,
    ModelFieldValue<String>? shareMode,
    ModelFieldValue<double>? lat,
    ModelFieldValue<double>? lng,
    ModelFieldValue<double?>? speedMps,
    ModelFieldValue<amplify_core.TemporalDateTime>? sharedAt,
    ModelFieldValue<amplify_core.TemporalDateTime?>? expiresAt
  }) {
    return ParticipantLocationEvent._internal(
      id: id,
      participantName: participantName == null ? this.participantName : participantName.value,
      utilityId: utilityId == null ? this.utilityId : utilityId.value,
      destinationStopId: destinationStopId == null ? this.destinationStopId : destinationStopId.value,
      statusMessage: statusMessage == null ? this.statusMessage : statusMessage.value,
      isBusy: isBusy == null ? this.isBusy : isBusy.value,
      shareMode: shareMode == null ? this.shareMode : shareMode.value,
      lat: lat == null ? this.lat : lat.value,
      lng: lng == null ? this.lng : lng.value,
      speedMps: speedMps == null ? this.speedMps : speedMps.value,
      sharedAt: sharedAt == null ? this.sharedAt : sharedAt.value,
      expiresAt: expiresAt == null ? this.expiresAt : expiresAt.value
    );
  }
  
  ParticipantLocationEvent.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _participantName = json['participantName'],
      _utilityId = json['utilityId'],
      _destinationStopId = json['destinationStopId'],
      _statusMessage = json['statusMessage'],
      _isBusy = json['isBusy'],
      _shareMode = json['shareMode'],
      _lat = (json['lat'] as num?)?.toDouble(),
      _lng = (json['lng'] as num?)?.toDouble(),
      _speedMps = (json['speedMps'] as num?)?.toDouble(),
      _sharedAt = json['sharedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['sharedAt']) : null,
      _expiresAt = json['expiresAt'] != null ? amplify_core.TemporalDateTime.fromString(json['expiresAt']) : null,
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'participantName': _participantName, 'utilityId': _utilityId, 'destinationStopId': _destinationStopId, 'statusMessage': _statusMessage, 'isBusy': _isBusy, 'shareMode': _shareMode, 'lat': _lat, 'lng': _lng, 'speedMps': _speedMps, 'sharedAt': _sharedAt?.format(), 'expiresAt': _expiresAt?.format(), 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'participantName': _participantName,
    'utilityId': _utilityId,
    'destinationStopId': _destinationStopId,
    'statusMessage': _statusMessage,
    'isBusy': _isBusy,
    'shareMode': _shareMode,
    'lat': _lat,
    'lng': _lng,
    'speedMps': _speedMps,
    'sharedAt': _sharedAt,
    'expiresAt': _expiresAt,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<ParticipantLocationEventModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<ParticipantLocationEventModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final PARTICIPANTNAME = amplify_core.QueryField(fieldName: "participantName");
  static final UTILITYID = amplify_core.QueryField(fieldName: "utilityId");
  static final DESTINATIONSTOPID = amplify_core.QueryField(fieldName: "destinationStopId");
  static final STATUSMESSAGE = amplify_core.QueryField(fieldName: "statusMessage");
  static final ISBUSY = amplify_core.QueryField(fieldName: "isBusy");
  static final SHAREMODE = amplify_core.QueryField(fieldName: "shareMode");
  static final LAT = amplify_core.QueryField(fieldName: "lat");
  static final LNG = amplify_core.QueryField(fieldName: "lng");
  static final SPEEDMPS = amplify_core.QueryField(fieldName: "speedMps");
  static final SHAREDAT = amplify_core.QueryField(fieldName: "sharedAt");
  static final EXPIRESAT = amplify_core.QueryField(fieldName: "expiresAt");
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "ParticipantLocationEvent";
    modelSchemaDefinition.pluralName = "ParticipantLocationEvents";
    
    modelSchemaDefinition.authRules = [
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.OWNER,
        ownerField: "owner",
        identityClaim: "cognito:username",
        provider: amplify_core.AuthRuleProvider.USERPOOLS,
        operations: const [
          amplify_core.ModelOperation.CREATE,
          amplify_core.ModelOperation.DELETE
        ]),
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.PRIVATE,
        operations: const [
          amplify_core.ModelOperation.READ
        ])
    ];
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantLocationEvent.PARTICIPANTNAME,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantLocationEvent.UTILITYID,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantLocationEvent.DESTINATIONSTOPID,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantLocationEvent.STATUSMESSAGE,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantLocationEvent.ISBUSY,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.bool)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantLocationEvent.SHAREMODE,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantLocationEvent.LAT,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.double)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantLocationEvent.LNG,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.double)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantLocationEvent.SPEEDMPS,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.double)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantLocationEvent.SHAREDAT,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantLocationEvent.EXPIRESAT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.nonQueryField(
      fieldName: 'createdAt',
      isRequired: false,
      isReadOnly: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.nonQueryField(
      fieldName: 'updatedAt',
      isRequired: false,
      isReadOnly: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
  });
}

class _ParticipantLocationEventModelType extends amplify_core.ModelType<ParticipantLocationEvent> {
  const _ParticipantLocationEventModelType();
  
  @override
  ParticipantLocationEvent fromJson(Map<String, dynamic> jsonData) {
    return ParticipantLocationEvent.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'ParticipantLocationEvent';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [ParticipantLocationEvent] in your schema.
 */
class ParticipantLocationEventModelIdentifier implements amplify_core.ModelIdentifier<ParticipantLocationEvent> {
  final String id;

  /** Create an instance of ParticipantLocationEventModelIdentifier using [id] the primary key. */
  const ParticipantLocationEventModelIdentifier({
    required this.id});
  
  @override
  Map<String, dynamic> serializeAsMap() => (<String, dynamic>{
    'id': id
  });
  
  @override
  List<Map<String, dynamic>> serializeAsList() => serializeAsMap()
    .entries
    .map((entry) => (<String, dynamic>{ entry.key: entry.value }))
    .toList();
  
  @override
  String serializeAsString() => serializeAsMap().values.join('#');
  
  @override
  String toString() => 'ParticipantLocationEventModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is ParticipantLocationEventModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}