// Ported from ROME rome-modules/src/main/java/com/rometools/modules/itunes/{EntryInformation,EntryInformationImpl}.java (Apache-2.0)
import { Module } from '../../feed/module/Module';
import { parseUrl } from '../../utils/JavaNet';
import { ITunes } from './ITunes';
import { Duration } from './types/Duration';

export class EntryInformation extends ITunes {
  duration: Duration | null = null;
  closedCaptioned: boolean = false;
  order: number | null = null;
  episodeType: string | null = null;
  season: number | null = null;
  episode: number | null = null;
  title: string | null = null;

  copyFrom(obj: Module): void {
    const info = obj as EntryInformation;
    this.author = info.author;
    this.block = info.block;
    if (info.duration !== null) {
      this.duration = new Duration(info.duration.milliseconds);
    }
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
    this.subtitle = info.subtitle;
    this.summary = info.summary;
    this.closedCaptioned = info.closedCaptioned;
    this.order = info.order;
    this.episodeType = info.episodeType;
    this.season = info.season;
    this.episode = info.episode;
    this.title = info.title;
  }

  clone(): EntryInformation {
    const info = new EntryInformation();
    info.copyFrom(this);
    return info;
  }
}
