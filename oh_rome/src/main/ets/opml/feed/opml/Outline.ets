// Ported from ROME rome-opml/src/main/java/com/rometools/opml/feed/opml/Outline.java (Apache-2.0)
import { Module } from '../../../feed/module/Module';
import { JavaUrl } from '../../../utils/JavaNet';
import { Attribute } from './Attribute';

export class Outline {
  created: Date | null = null;
  attributes: Attribute[] = [];
  categories: string[] = [];
  children: Outline[] = [];
  modules: Module[] = [];
  text: string | null = null;
  title: string | null = null;
  type: string | null = null;
  breakpoint: boolean = false;
  comment: boolean = false;

  constructor(type: string | null = null, text: string | null = null) {
    this.type = type;
    this.text = text;
  }

  // Java's Outline(String title, URL xmlUrl, URL htmlUrl) constructor.
  static rss(title: string | null, xmlUrl: JavaUrl | null, htmlUrl: JavaUrl | null): Outline {
    const outline = new Outline('rss');
    outline.title = title;
    if (xmlUrl !== null) {
      outline.attributes.push(new Attribute('xmlUrl', xmlUrl.toString()));
    }
    if (htmlUrl !== null) {
      outline.attributes.push(new Attribute('htmlUrl', htmlUrl.toString()));
    }
    return outline;
  }

  get url(): string | null {
    return this.getAttributeValue('url');
  }

  get htmlUrl(): string | null {
    return this.getAttributeValue('htmlUrl');
  }

  get xmlUrl(): string | null {
    return this.getAttributeValue('xmlUrl');
  }

  getAttributeValue(name: string): string | null {
    const attribute = this.attributes.find((a: Attribute) => a.name === name);
    return attribute === undefined ? null : attribute.value;
  }
}
