public class CaseWidgetOriginUtil {
  public static String normalizeOrigin(String origin) {
    if (String.isBlank(origin)) {
      return null;
    }

    String normalized = origin.trim().toLowerCase();
    if (normalized.startsWith('https://')) {
      normalized = normalized.substring(8);
    } else if (normalized.startsWith('http://')) {
      normalized = normalized.substring(7);
    }

    Integer slashIndex = normalized.indexOf('/');
    if (slashIndex >= 0) {
      normalized = normalized.substring(0, slashIndex);
    }

    normalized = normalized.trim();
    return String.isBlank(normalized) ? null : normalized;
  }
}
