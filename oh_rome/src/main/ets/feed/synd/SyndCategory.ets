// Ported from ROME rome/src/main/java/com/rometools/rome/feed/synd/{SyndCategory,SyndCategoryImpl}.java (Apache-2.0)

// Java backs name/taxonomyUri with a DCSubject; here they are plain fields and SyndFeed.categories
// converts to and from the DC subjects.
export class SyndCategory {
  name: string | null = null;
  taxonomyUri: string | null = null;
  label: string | null = null;
}
