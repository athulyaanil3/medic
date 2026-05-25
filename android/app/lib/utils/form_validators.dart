/// Client-side validation for auth and profile forms.
class FormValidators {
  /// Stricter pattern: local@domain.tld (TLD 2–63 letters).
  static final RegExp _emailPattern = RegExp(
    r'^[a-zA-Z0-9](?:[a-zA-Z0-9._%+\-]*[a-zA-Z0-9])?@[a-zA-Z0-9](?:[a-zA-Z0-9\-]*[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9\-]*[a-zA-Z0-9])?)*\.[a-zA-Z]{2,63}$',
  );

  /// Domains that are almost always typos (not real mail providers for most users).
  static const Map<String, String> _domainTypos = {
    'gail.com': 'gmail.com',
    'gmial.com': 'gmail.com',
    'gmai.com': 'gmail.com',
    'gamil.com': 'gmail.com',
    'gnail.com': 'gmail.com',
    'yaho.com': 'yahoo.com',
    'yhoo.com': 'yahoo.com',
    'hotmial.com': 'hotmail.com',
    'outlok.com': 'outlook.com',
  };

  static String? email(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Email is required';
    if (trimmed.length > 254) return 'Email is too long';
    if (trimmed.contains(' ')) return 'Email cannot contain spaces';

    // Reject bare domain names like "gail.com" or "gmail.com" (no @).
    if (!trimmed.contains('@')) {
      final asDomain = trimmed.toLowerCase();
      if (asDomain.contains('.') && !asDomain.startsWith('.') && !asDomain.endsWith('.')) {
        final typo = _domainTypos[asDomain];
        if (typo != null) {
          return 'Enter a full email (e.g. you@$typo), not just $asDomain';
        }
        return 'Email must include @ (e.g. you@gmail.com)';
      }
      return 'Email must include @ (e.g. you@gmail.com)';
    }

    final atIndex = trimmed.indexOf('@');
    if (trimmed.lastIndexOf('@') != atIndex) {
      return 'Email can only contain one @';
    }

    final local = trimmed.substring(0, atIndex);
    final domain = trimmed.substring(atIndex + 1).toLowerCase();

    if (local.isEmpty) return 'Enter the part before @';
    if (local.length > 64) return 'Email username is too long';
    if (domain.isEmpty) return 'Enter a domain after @ (e.g. gmail.com)';
    if (!domain.contains('.')) {
      return 'Domain must include a dot (e.g. gmail.com)';
    }

    final typoHint = _domainTypos[domain];
    if (typoHint != null) {
      return 'Did you mean $local@$typoHint? ("$domain" is not a common email provider)';
    }

    final labels = domain.split('.');
    if (labels.any((label) => label.isEmpty)) {
      return 'Enter a valid email address';
    }

    final tld = labels.last;
    if (tld.length < 2) {
      return 'Use a valid domain extension (e.g. .com, .in)';
    }
    if (!RegExp(r'^[a-zA-Z]{2,63}$').hasMatch(tld)) {
      return 'Enter a valid email address';
    }

    if (!_emailPattern.hasMatch(trimmed)) {
      return 'Enter a valid email address';
    }

    return null;
  }

  static String? password(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    if (value.contains(' ')) return 'Password cannot contain spaces';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != password) return 'Passwords do not match';
    return null;
  }
}
