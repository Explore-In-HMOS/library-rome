// Ported from ROME rome-modules/src/main/java/com/rometools/modules/content/{ContentModule,ContentModuleImpl}.java (Apache-2.0)
import { Module, ModuleImpl } from '../../feed/module/Module';
import { ContentItem } from './ContentItem';

export class ContentModule extends ModuleImpl {
  static readonly URI: string = 'http://purl.org/rss/1.0/modules/content/';
  static readonly RDF_URI: string = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#';
  encodeds: string[] = [];
  contents: string[] = [];
  contentItems: ContentItem[] = [];

  constructor() {
    super(ContentModule.URI);
  }

  // ModuleImpl.clone is CloneableBean's deep clone: new lists, each ContentItem cloned.
  clone(): ContentModule {
    const copy = new ContentModule();
    copy.encodeds = this.encodeds.slice();
    copy.contents = this.contents.slice();
    copy.contentItems = this.contentItems.map((item: ContentItem) => item.clone());
    return copy;
  }

  copyFrom(obj: Module): void {
    const cm = obj as ContentModule;
    this.encodeds = cm.encodeds;
    this.contentItems = cm.contentItems;
    this.contents = cm.contents;
  }
}
