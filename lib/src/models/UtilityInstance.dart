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
import 'package:collection/collection.dart';


/** This is an auto generated class representing the UtilityInstance type in your schema. */
class UtilityInstance extends amplify_core.Model {
  static const classType = const _UtilityInstanceModelType();
  final String id;
  final String? _title;
  final String? _createdBy;
  final List<String>? _participants;
  final amplify_core.TemporalDateTime? _startsAt;
  final amplify_core.TemporalDateTime? _endsAt;
  final amplify_core.TemporalDateTime? _closesAt;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  UtilityInstanceModelIdentifier get modelIdentifier {
      return UtilityInstanceModelIdentifier(
        id: id
      );
  }
  
  String get title {
    try {
      return _title!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String get createdBy {
    try {
      return _createdBy!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  List<String>? get participants {
    return _participants;
  }
  
  amplify_core.TemporalDateTime? get startsAt {
    return _startsAt;
  }
  
  amplify_core.TemporalDateTime? get endsAt {
    return _endsAt;
  }
  
  amplify_core.TemporalDateTime? get closesAt {
    return _closesAt;
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const UtilityInstance._internal({required this.id, required title, required createdBy, participants, startsAt, endsAt, closesAt, createdAt, updatedAt}): _title = title, _createdBy = createdBy, _participants = participants, _startsAt = startsAt, _endsAt = endsAt, _closesAt = closesAt, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory UtilityInstance({String? id, required String title, required String createdBy, List<String>? participants, amplify_core.TemporalDateTime? startsAt, amplify_core.TemporalDateTime? endsAt, amplify_core.TemporalDateTime? closesAt}) {
    return UtilityInstance._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      title: title,
      createdBy: createdBy,
      participants: participants != null ? List<String>.unmodifiable(participants) : participants,
      startsAt: startsAt,
      endsAt: endsAt,
      closesAt: closesAt);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UtilityInstance &&
      id == other.id &&
      _title == other._title &&
      _createdBy == other._createdBy &&
      DeepCollectionEquality().equals(_participants, other._participants) &&
      _startsAt == other._startsAt &&
      _endsAt == other._endsAt &&
      _closesAt == other._closesAt;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("UtilityInstance {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("title=" + "$_title" + ", ");
    buffer.write("createdBy=" + "$_createdBy" + ", ");
    buffer.write("participants=" + (_participants != null ? _participants!.toString() : "null") + ", ");
    buffer.write("startsAt=" + (_startsAt != null ? _startsAt!.format() : "null") + ", ");
    buffer.write("endsAt=" + (_endsAt != null ? _endsAt!.format() : "null") + ", ");
    buffer.write("closesAt=" + (_closesAt != null ? _closesAt!.format() : "null") + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  UtilityInstance copyWith({String? title, String? createdBy, List<String>? participants, amplify_core.TemporalDateTime? startsAt, amplify_core.TemporalDateTime? endsAt, amplify_core.TemporalDateTime? closesAt}) {
    return UtilityInstance._internal(
      id: id,
      title: title ?? this.title,
      createdBy: createdBy ?? this.createdBy,
      participants: participants ?? this.participants,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      closesAt: closesAt ?? this.closesAt);
  }
  
  UtilityInstance copyWithModelFieldValues({
    ModelFieldValue<String>? title,
    ModelFieldValue<String>? createdBy,
    ModelFieldValue<List<String>?>? participants,
    ModelFieldValue<amplify_core.TemporalDateTime?>? startsAt,
    ModelFieldValue<amplify_core.TemporalDateTime?>? endsAt,
    ModelFieldValue<amplify_core.TemporalDateTime?>? closesAt
  }) {
    return UtilityInstance._internal(
      id: id,
      title: title == null ? this.title : title.value,
      createdBy: createdBy == null ? this.createdBy : createdBy.value,
      participants: participants == null ? this.participants : participants.value,
      startsAt: startsAt == null ? this.startsAt : startsAt.value,
      endsAt: endsAt == null ? this.endsAt : endsAt.value,
      closesAt: closesAt == null ? this.closesAt : closesAt.value
    );
  }
  
  UtilityInstance.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _title = json['title'],
      _createdBy = json['createdBy'],
      _participants = json['participants']?.cast<String>(),
      _startsAt = json['startsAt'] != null ? amplify_core.TemporalDateTime.fromString(json['startsAt']) : null,
      _endsAt = json['endsAt'] != null ? amplify_core.TemporalDateTime.fromString(json['endsAt']) : null,
      _closesAt = json['closesAt'] != null ? amplify_core.TemporalDateTime.fromString(json['closesAt']) : null,
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'title': _title, 'createdBy': _createdBy, 'participants': _participants, 'startsAt': _startsAt?.format(), 'endsAt': _endsAt?.format(), 'closesAt': _closesAt?.format(), 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'title': _title,
    'createdBy': _createdBy,
    'participants': _participants,
    'startsAt': _startsAt,
    'endsAt': _endsAt,
    'closesAt': _closesAt,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<UtilityInstanceModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<UtilityInstanceModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final TITLE = amplify_core.QueryField(fieldName: "title");
  static final CREATEDBY = amplify_core.QueryField(fieldName: "createdBy");
  static final PARTICIPANTS = amplify_core.QueryField(fieldName: "participants");
  static final STARTSAT = amplify_core.QueryField(fieldName: "startsAt");
  static final ENDSAT = amplify_core.QueryField(fieldName: "endsAt");
  static final CLOSESAT = amplify_core.QueryField(fieldName: "closesAt");
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "UtilityInstance";
    modelSchemaDefinition.pluralName = "UtilityInstances";
    
    modelSchemaDefinition.authRules = [
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.PUBLIC,
        provider: amplify_core.AuthRuleProvider.APIKEY,
        operations: const [
          amplify_core.ModelOperation.CREATE,
          amplify_core.ModelOperation.UPDATE,
          amplify_core.ModelOperation.DELETE,
          amplify_core.ModelOperation.READ
        ])
    ];
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: UtilityInstance.TITLE,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: UtilityInstance.CREATEDBY,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: UtilityInstance.PARTICIPANTS,
      isRequired: false,
      isArray: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.collection, ofModelName: amplify_core.ModelFieldTypeEnum.string.name)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: UtilityInstance.STARTSAT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: UtilityInstance.ENDSAT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: UtilityInstance.CLOSESAT,
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

class _UtilityInstanceModelType extends amplify_core.ModelType<UtilityInstance> {
  const _UtilityInstanceModelType();
  
  @override
  UtilityInstance fromJson(Map<String, dynamic> jsonData) {
    return UtilityInstance.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'UtilityInstance';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [UtilityInstance] in your schema.
 */
class UtilityInstanceModelIdentifier implements amplify_core.ModelIdentifier<UtilityInstance> {
  final String id;

  /** Create an instance of UtilityInstanceModelIdentifier using [id] the primary key. */
  const UtilityInstanceModelIdentifier({
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
  String toString() => 'UtilityInstanceModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is UtilityInstanceModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}