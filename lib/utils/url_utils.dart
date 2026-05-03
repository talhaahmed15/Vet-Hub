String sanitizeRemoteUrl(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return url;
  return trimmed.replaceAll("'", "%27").replaceAll(' ', '%20');
}
