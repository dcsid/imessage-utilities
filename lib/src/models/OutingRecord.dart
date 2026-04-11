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


/** This is an auto generated class representing the OutingRecord type in your schema. */
class OutingRecord extends amplify_core.Model {
  static const classType = const _OutingRecordModelType();
  final String id;
  final String? _title;
  final String? _createdBy;
  final String? _payload;
  final amplify_core.TemporalDateTime? _closesAt;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  OutingRecordModelIdentifier get modelIdentifier {
      return OutingRecordModelIdentifier(
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
  
  String get payload {
    try {
      return _payload!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
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
  
  const OutingRecord._internal({required this.id, required title, required createdBy, required payload, closesAt, createdAt, updatedAt}): _title = title, _createdBy = createdBy, _payload = payload, _closesAt = closesAt, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory OutingRecord({String? id, required String title, required String createdBy, required String payload, amplify_core.TemporalDateTime? closesAt}) {
    return OutingRecord._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      title: title,
      createdBy: createdBy,
      payload: payload,
      closesAt: closesAt);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is OutingRecord &&
      id == other.id &&
      _title == other._title &&
      _createdBy == other._createdBy &&
      _payload == other._payload &&
      _closesAt == other._closesAt;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("OutingRecord {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("title=" + "$_title" + ", ");
    buffer.write("createdBy=" + "$_createdBy" + ", ");
    buffer.write("payload=" + "$_payload" + ", ");
    buffer.write("closesAt=" + (_closesAt != null ? _closesAt!.format() : "null") + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  OutingRecord copyWith({String? title, String? createdBy, String? payload, amplify_core.TemporalDateTime? closesAt}) {
    return OutingRecord._internal(
      id: id,
      title: title ?? this.title,
      createdBy: createdBy ?? this.createdBy,
      payload: payload ?? this.payload,
      closesAt: closesAt ?? this.closesAt);
  }
  
  OutingRecord copyWithModelFieldValues({
    ModelFieldValue<String>? title,
    ModelFieldValue<String>? createdBy,
    ModelFieldValue<String>? payload,
    ModelFieldValue<amplify_core.TemporalDateTime?>? closesAt
  }) {
    return OutingRecord._internal(
      id: id,
      title: title == null ? this.title : title.value,
      createdBy: createdBy == null ? this.createdBy : createdBy.value,
      payload: payload == null ? this.payload : payload.value,
      closesAt: closesAt == null ? this.closesAt : closesAt.value
    );
  }
  
  OutingRecord.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _title = json['title'],
      _createdBy = json['createdBy'],
      _payload = json['payload'],
      _closesAt = json['closesAt'] != null ? amplify_core.TemporalDateTime.fromString(json['closesAt']) : null,
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'title': _title, 'createdBy': _createdBy, 'payload': _payload, 'closesAt': _closesAt?.format(), 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'title': _title,
    'createdBy': _createdBy,
    'payload': _payload,
    'closesAt': _closesAt,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<OutingRecordModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<OutingRecordModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final TITLE = amplify_core.QueryField(fieldName: "title");
  static final CREATEDBY = amplify_core.QueryField(fieldName: "createdBy");
  static final PAYLOAD = amplify_core.QueryField(fieldName: "payload");
  static final CLOSESAT = amplify_core.QueryField(fieldName: "closesAt");
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "OutingRecord";
    modelSchemaDefinition.pluralName = "OutingRecords";
    
    modelSchemaDefinition.authRules = [
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.OWNER,
        ownerField: "owner",
        identityClaim: "cognito:username",
        provider: amplify_core.AuthRuleProvider.USERPOOLS,
        operations: const [
          amplify_core.ModelOperation.CREATE,
          amplify_core.ModelOperation.UPDATE,
          amplify_core.ModelOperation.DELETE,
          amplify_core.ModelOperation.READ
        ])
    ];
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: OutingRecord.TITLE,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: OutingRecord.CREATEDBY,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: OutingRecord.PAYLOAD,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: OutingRecord.CLOSESAT,
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

class _OutingRecordModelType extends amplify_core.ModelType<OutingRecord> {
  const _OutingRecordModelType();
  
  @override
  OutingRecord fromJson(Map<String, dynamic> jsonData) {
    return OutingRecord.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'OutingRecord';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [OutingRecord] in your schema.
 */
class OutingRecordModelIdentifier implements amplify_core.ModelIdentifier<OutingRecord> {
  final String id;

  /** Create an instance of OutingRecordModelIdentifier using [id] the primary key. */
  const OutingRecordModelIdentifier({
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
  String toString() => 'OutingRecordModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is OutingRecordModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}