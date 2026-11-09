// Ported from ROME rome-modules/src/main/java/com/rometools/modules/itunes/{FeedInformation,FeedInformationImpl}.java (Apache-2.0)
import { Module } from '../../feed/module/Module';
import { parseUrl } from '../../utils/JavaNet';
import { ITunes } from './ITunes';
import { Category } from './types/Category';

export class FeedInformation extends ITunes {
  ownerName: string | null = null;
  ownerEmailAddress: string | null = null;
  categories: Category[] = [];
  complete: boolean = false;
  newFeedUrl: string | null = null;
  type: string | null = null;

  // The categories are shared with obj, not copied.
  copyFrom(obj: Module): void {
    const info = obj as FeedInformation;
    this.author = info.author;
    this.block = info.block;
    this.categories = info.categories.slice();
    this.complete = info.complete;
    this.newFeedUrl = info.newFeedUrl;
    this.explicitNullable = info.explicitNullable;
    if (info.image !== null) {
      try {
        this.image = parseUrl(info.image).toString();
      } catch (e) {
        // ROME logs the MalformedURLException and leaves image unset.
      }
    }
    if (info.imageUri !== null) {
      this.imageUri = info.imageUri;
    }
    this.keywords = info.keywords.slice();
    this.ownerEmailAddress = info.ownerEmailAddress;
    this.ownerName = info.ownerName;
    this.subtitle = info.subtitle;
    this.summary = info.summary;
    this.type = info.type;
  }

  clone(): FeedInformation {
    const info = new FeedInformation();
    info.copyFrom(this);
    return info;
  }
}
