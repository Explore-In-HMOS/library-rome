// Ported from ROME rome-modules/src/main/java/com/rometools/modules/mediarss/types/MediaContent.java (Apache-2.0)
import { Expression } from './Expression';
import { Metadata } from './Metadata';
import { PlayerReference } from './PlayerReference';
import { Reference } from './Reference';

export class MediaContent {
  expression: Expression | null = null;
  bitrate: number | null = null;
  framerate: number | null = null;
  samplingrate: number | null = null;
  audioChannels: number | null = null;
  height: number | null = null;
  width: number | null = null;
  duration: number | null = null;
  fileSize: number | null = null;
  metadata: Metadata | null = null;
  player: PlayerReference | null = null;
  private _reference: Reference;
  language: string | null = null;
  medium: string | null = null;
  type: string | null = null;
  defaultContent: boolean = false;

  constructor(reference: Reference | null) {
    if (reference === null) {
      throw new Error('You must provide either a PlayerReference or URL reference.');
    }
    this._reference = reference;
    this.reference = reference;
  }

  get reference(): Reference {
    return this._reference;
  }

  set reference(reference: Reference) {
    this._reference = reference;
    if (reference instanceof PlayerReference) {
      this.player = reference;
    }
  }
}
