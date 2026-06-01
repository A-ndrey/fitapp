String humanReadableFormError(
  Object error, {
  required String resourceName,
  required String fallback,
}) {
  final message = _extractMessage(error);
  if (_isGenericMessage(message)) {
    return fallback;
  }

  final normalized = message.toLowerCase();
  if (normalized.startsWith('duplicate ')) {
    return 'A $resourceName with this name already exists.';
  }
  if (normalized.startsWith('missing exercise id:')) {
    return 'One of the selected exercises is no longer available.';
  }
  if (normalized.startsWith('missing item id:')) {
    return 'One of the selected foods or recipes is no longer available.';
  }
  if (normalized.startsWith('missing training plan id:')) {
    return 'The selected training plan is no longer available.';
  }
  if (normalized.startsWith('missing ') && normalized.contains(' id:')) {
    return 'The selected $resourceName is no longer available.';
  }
  if (normalized.contains('cycle detected')) {
    return 'This recipe cannot include itself.';
  }

  return message;
}

String _extractMessage(Object error) {
  final message = switch (error) {
    ArgumentError(message: final value) => value?.toString() ?? '',
    StateError(message: final value) => value,
    Exception() => error.toString(),
    _ => error.toString(),
  };
  return _stripTechnicalPrefix(message.trim());
}

String _stripTechnicalPrefix(String message) {
  var current = message;
  const prefixes = [
    'Exception:',
    'Exception: ',
    'Bad state:',
    'Bad state: ',
    'Invalid argument(s):',
    'Invalid argument(s): ',
  ];
  var removedPrefix = true;
  while (removedPrefix) {
    removedPrefix = false;
    for (final prefix in prefixes) {
      if (current.startsWith(prefix)) {
        current = current.substring(prefix.length).trim();
        removedPrefix = true;
      }
    }
  }
  return current;
}

bool _isGenericMessage(String message) {
  final normalized = message.trim().toLowerCase();
  return normalized.isEmpty ||
      normalized == 'error' ||
      normalized == 'exception' ||
      normalized == 'unknown error' ||
      normalized == 'null';
}
