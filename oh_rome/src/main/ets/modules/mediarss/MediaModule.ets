// Ported from ROME rome-modules/src/main/java/com/rometools/modules/mediarss/{MediaModule,MediaModuleImpl}.java (Apache-2.0)
import { Module, ModuleImpl } from '../../feed/module/Module';
import { Metadata } from './types/Metadata';
import { PlayerReference } from './types/PlayerReference';

export class MediaModule extends ModuleImpl {
  static readonly URI: string = 'http://search.yahoo.com/mrss/';
  metadata: Metadata | null = null;
  player: PlayerReference | null = null;

  constructor() {
    super(MediaModule.URI);
  }

  // Like Java, throws when metadata is null.
  clone(): MediaModule {
    const m = new MediaModule();
    m.metadata = this.metadata!.clone();
    m.player = this.player;
    return m;
  }

  copyFrom(obj: Module): void {
    const m = obj as MediaModule;
    this.metadata = m.metadata!.clone();
    this.player = m.player;
  }
}
