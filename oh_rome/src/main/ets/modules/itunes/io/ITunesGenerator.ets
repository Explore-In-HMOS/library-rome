// Ported from ROME rome-modules/src/main/java/com/rometools/modules/itunes/io/ITunesGenerator.java (Apache-2.0)
import { Element, Namespace } from '../../../xml/Dom';
import { Module } from '../../../feed/module/Module';
import { ModuleGenerator } from '../../../io/ModuleGenerator';
import { EntryInformation } from '../EntryInformation';
import { FeedInformation } from '../FeedInformation';
import { ITunes } from '../ITunes';

const NAMESPACE: Namespace = Namespace.getNamespace(ITunes.PREFIX, ITunes.URI);

export class ITunesGenerator implements ModuleGenerator {
  getNamespaceUri(): string {
    return ITunes.URI;
  }

  getNamespaces(): Namespace[] {
    return [NAMESPACE];
  }

  generate(module: Module, element: Element): void {
    let root = element;
    while (root.getParentElement() !== null) {
      root = root.getParentElement()!;
    }
    root.addNamespaceDeclaration(NAMESPACE);
    if (!(module instanceof ITunes)) {
      return;
    }
    const itunes = module as ITunes;
    if (itunes instanceof FeedInformation) {
      const info = itunes as FeedInformation;
      const owner = this.generateSimpleElement('owner', '');
      owner.addContent(this.generateSimpleElement('email', info.ownerEmailAddress));
      owner.addContent(this.generateSimpleElement('name', info.ownerName));
      element.addContent(owner);
      for (const cat of info.categories) {
        const category = this.generateSimpleElement('category', '');
        category.setAttribute('text', cat.name!);
        for (const subcategory of cat.subcategories) {
          const subcat = this.generateSimpleElement('category', '');
          subcat.setAttribute('text', subcategory.name!);
          category.addContent(subcat);
        }
        element.addContent(category);
      }
      if (info.type !== null) {
        element.addContent(this.generateSimpleElement('type', info.type));
      }
      if (info.complete) {
        element.addContent(this.generateSimpleElement('complete', 'yes'));
      }
      if (info.newFeedUrl !== null) {
        element.addContent(this.generateSimpleElement('new-feed-url', info.newFeedUrl));
      }
    } else if (itunes instanceof EntryInformation) {
      const info = itunes as EntryInformation;
      if (info.duration !== null) {
        element.addContent(this.generateSimpleElement('duration', info.duration.toString()));
      }
      if (info.closedCaptioned) {
        element.addContent(this.generateSimpleElement('isClosedCaptioned', 'yes'));
      }
      if (info.order !== null) {
        element.addContent(this.generateSimpleElement('order', String(info.order)));
      }
      if (info.episodeType !== null) {
        element.addContent(this.generateSimpleElement('episodeType', info.episodeType));
      }
      if (info.season !== null && info.season > 0) {
        element.addContent(this.generateSimpleElement('season', String(info.season)));
      }
      if (info.episode !== null && info.episode > 0) {
        element.addContent(this.generateSimpleElement('episode', String(info.episode)));
      }
      if (info.title !== null) {
        element.addContent(this.generateSimpleElement('title', info.title));
      }
    }
    if (itunes.author !== null) {
      element.addContent(this.generateSimpleElement('author', itunes.author));
    }
    if (itunes.block) {
      element.addContent(this.generateSimpleElement('block', 'Yes'));
    }
    if (itunes.explicitNullable !== null) {
      element.addContent(this.generateSimpleElement('explicit', itunes.explicitNullable ? 'yes' : 'no'));
    }
    const href = itunes.image ?? itunes.imageUri;
    if (href !== null) {
      const image = this.generateSimpleElement('image', '');
      image.setAttribute('href', href);
      element.addContent(image);
    }
    element.addContent(this.generateSimpleElement('keywords', itunes.keywords.join(', ')));
    if (itunes.subtitle !== null) {
      element.addContent(this.generateSimpleElement('subtitle', itunes.subtitle));
    }
    if (itunes.summary !== null) {
      element.addContent(this.generateSimpleElement('summary', itunes.summary));
    }
  }

  // JDOM's addContent(String) adds an empty Text for null.
  protected generateSimpleElement(name: string, value: string | null): Element {
    const element = new Element(name, NAMESPACE);
    element.addContent(value ?? '');
    return element;
  }
}
