import 'package:flutter_test/flutter_test.dart';
import 'package:medic/utils/form_validators.dart';

void main() {
  group('FormValidators.email', () {
    test('rejects bare gail.com and gmail.com', () {
      expect(FormValidators.email('gail.com'), isNotNull);
      expect(FormValidators.email('gmail.com'), isNotNull);
    });

    test('rejects typo domain user@gail.com', () {
      final err = FormValidators.email('user@gail.com');
      expect(err, isNotNull);
      expect(err, contains('gmail.com'));
    });

    test('accepts proper emails', () {
      expect(FormValidators.email('user@gmail.com'), isNull);
      expect(FormValidators.email('name.gail@company.co.in'), isNull);
    });

    test('rejects malformed emails', () {
      expect(FormValidators.email(''), isNotNull);
      expect(FormValidators.email('@gmail.com'), isNotNull);
      expect(FormValidators.email('user@'), isNotNull);
      expect(FormValidators.email('user@gmail'), isNotNull);
      expect(FormValidators.email('user@@gmail.com'), isNotNull);
    });
  });
}
