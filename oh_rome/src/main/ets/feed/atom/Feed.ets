// Ported from ROME rome/src/main/java/com/rometools/rome/feed/atom/Feed.java (Apache-2.0)
import { WireFeed } from '../WireFeed';
import { SyndPerson } from '../synd/SyndPerson';
import { Category } from './Category';
import { Content } from './Content';
import { Entry } from './Entry';
import { Generator } from './Generator';
import { Link } from './Link';

export class Feed extends WireFeed {
  xmlBase: string | null = null;
  categories: Category[] = [];
  authors: SyndPerson[] = [];
  contributors: SyndPerson[] = [];
  generator: Generator | null = null;
  icon: string | null = null;
  id: string | null = null;
  logo: string | null = null;
  rights: string | null = null;
  subtitle: Content | null = null;
  titleEx: Content | null = null;
  updated: Date | null = null;
  alternateLinks: Link[] = [];
  otherLinks: Link[] = [];
  entries: Entry[] = [];
  // Atom 0.3 only.
  info: Content | null = null;
  // Atom 0.3 only.
  language: string | null = null;

  constructor(type?: string) {
    super(type);
  }

  get title(): string | null {
    return this.titleEx === null ? null : this.titleEx.value;
  }

  set title(title: string | null) {
    if (this.titleEx === null) {
      this.titleEx = new Content();
    }
    this.titleEx.value = title;
  }

  // Atom 0.3 name of subtitle.
  get tagline(): Content | null {
    return this.subtitle;
  }

  set tagline(tagline: Content | null) {
    this.subtitle = tagline;
  }

  // Atom 0.3 name of rights.
  get copyright(): string | null {
    return this.rights;
  }

  set copyright(copyright: string | null) {
    this.rights = copyright;
  }

  // Atom 0.3 name of updated.
  get modified(): Date | null {
    return this.updated;
  }

  set modified(modified: Date | null) {
    this.updated = modified;
  }
}
