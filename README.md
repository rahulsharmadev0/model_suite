# Model Suite for Dart

A powerful macro-based code generation library for Dart that helps reduce boilerplate in model classes.

> **⚠️ Early Development Warning**
> This is an experimental proof of concept showcasing Dart macros. Due to the evolving nature of Dart's macro system, some features may be incomplete or unstable.

## Features

- 🏗️ Automated Constructor Generation
- 🔄 JSON Serialization/Deserialization
- ✨ Copy With Implementation
- 🎯 Equality Comparisons
- 📝 ToString Generation

## Available Macros

- `@Model` - Comprehensive model generation (includes all features)
- `@JsonModel` - JSON serialization only
- `@EqualityModel` - Equality implementation only
- `@CopyWithModel` - Copy with functionality only
- `@ToStringModel` - ToString implementation only
- `@ConstructorModel` - Constructor generation only

## Usage

1. Add to your `pubspec.yaml`:
```yaml
dependencies:
  model_suite: ^0.1.0
```

2. Basic usage example:
```dart
import 'package:model_suite/model_suite.dart';

@Model()
class Person {
  final String name;
  final int age;
  
  // Constructor and all helper methods will be generated automatically
}
```

3. Selective features:
```dart
@JsonModel()
class Config {
  final Map<String, dynamic> settings;
  
  // Only JSON serialization methods will be generated
}
```

## Configuration

### Model Macro Options

- `constructorName` - Specify a custom constructor name
- `superConstructorName` - Specify the super constructor name for inheritance

## Requirements

- Dart SDK: `>=3.0.0 <4.0.0`
- Macro support enabled in your Dart environment

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

## License

This project is licensed under the MIT License - see the LICENSE file for details.



