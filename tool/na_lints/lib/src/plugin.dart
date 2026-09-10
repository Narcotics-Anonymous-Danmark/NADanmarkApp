import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:na_lints/src/rules/avoid_bool_type.dart';
import 'package:na_lints/src/rules/avoid_build_helper_methods.dart';
import 'package:na_lints/src/rules/avoid_comments.dart';
import 'package:na_lints/src/rules/avoid_default_parameter_values.dart';
import 'package:na_lints/src/rules/avoid_material_cupertino_import.dart';
import 'package:na_lints/src/rules/avoid_non_null_assertion.dart';
import 'package:na_lints/src/rules/avoid_nullable_types.dart';
import 'package:na_lints/src/rules/avoid_stateful_widget.dart';
import 'package:na_lints/src/rules/avoid_wildcard_switch.dart';
import 'package:na_lints/src/rules/no_direct_datetime_now_or_timer.dart';
import 'package:na_lints/src/rules/prefer_named_parameters.dart';

const List<LintRule> naLintRules = [
  AvoidNonNullAssertion(),
  AvoidNullableTypes(),
  AvoidBoolType(),
  AvoidWildcardSwitch(),
  AvoidComments(),
  AvoidMaterialCupertinoImport(),
  AvoidStatefulWidget(),
  AvoidBuildHelperMethods(),
  NoDirectDateTimeNowOrTimer(),
  PreferNamedParameters(),
  AvoidDefaultParameterValues(),
];

final class NaLintsPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(final CustomLintConfigs configs) => naLintRules;
}
