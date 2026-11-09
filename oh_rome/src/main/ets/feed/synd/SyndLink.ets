// Ported from ROME rome/src/main/java/com/rometools/rome/feed/synd/{SyndLink,SyndLinkImpl}.java (Apache-2.0)

export class SyndLink {
  href: string | null = null;
  rel: string | null = null;
  type: string | null = null;
  hreflang: string | null = null;
  title: string | null = null;
  length: number = 0;
}
