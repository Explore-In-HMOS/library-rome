// Plain text for a small screen: tags dropped, common entities decoded, whitespace collapsed, cut to max characters.
export function plainText(html: string | null, max: number): string {
  if (html === null) {
    return '';
  }
  const text = html.replace(/<[^>]*>/g, ' ')
    .replace(/&nbsp;/g, ' ').replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&quot;/g, '"')
    .replace(/&#39;/g, '\'').replace(/&amp;/g, '&')
    .replace(/\s+/g, ' ').trim();
  return text.length > max ? `${text.substring(0, max - 1)}…` : text;
}

// UTC, so the same feed shows the same date on every device.
export function formatDate(date: Date | null): string {
  if (date === null) {
    return 'No date';
  }
  const iso = date.toISOString();
  return `${iso.substring(0, 10)} ${iso.substring(11, 16)} UTC`;
}

export function formatBytes(n: number): string {
  if (n < 1024) {
    return `${n} B`;
  }
  return n < 1024 * 1024 ? `${(n / 1024).toFixed(1)} KB` : `${(n / 1024 / 1024).toFixed(1)} MB`;
}
