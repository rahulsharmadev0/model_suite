import 'package:macros/macros.dart';

extension FunctionUtils on FunctionDeclaration {
  /// All parameters for this function.
  Iterable<FormalParameterDeclaration> get parameters => positionalParameters.followedBy(namedParameters);
}

/// A diagnostic reported from a [Macro].
class MacroException extends DiagnosticException {
  MacroException(String message, {Severity severity = Severity.error, DiagnosticTarget? target})
      : super(Diagnostic(DiagnosticMessage(message, target: target), severity));
}
