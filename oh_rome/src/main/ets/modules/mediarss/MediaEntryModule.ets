// Ported from ROME rome-modules/src/main/java/com/rometools/modules/mediarss/{MediaEntryModule,MediaEntryModuleImpl}.java (Apache-2.0)
import { Module } from '../../feed/module/Module';
import { MediaModule } from './MediaModule';
import { MediaContent } from './types/MediaContent';
import { MediaGroup } from './types/MediaGroup';

export class MediaEntryModule extends MediaModule {
  mediaContents: MediaContent[] = [];
  mediaGroups: MediaGroup[] = [];

  // Copies the arrays but shares the contents and groups in them, as in Java.
  clone(): MediaEntryModule {
    const m = new MediaEntryModule();
    m.mediaContents = this.mediaContents.slice();
    m.mediaGroups = this.mediaGroups.slice();
    m.metadata = this.metadata === null ? null : this.metadata.clone();
    m.player = this.player;
    return m;
  }

  copyFrom(obj: Module): void {
    const other = (obj as MediaEntryModule).clone();
    this.mediaContents = other.mediaContents;
    this.mediaGroups = other.mediaGroups;
    this.metadata = other.metadata;
    this.player = other.player;
  }
}
