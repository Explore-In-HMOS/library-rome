// Ported from ROME rome-modules/src/main/java/com/rometools/modules/georss/W3CGeoModuleImpl.java (Apache-2.0)
import { Module } from '../../feed/module/Module';
import { GeoRSSModule } from './GeoRSSModule';

export class W3CGeoModuleImpl extends GeoRSSModule {
  constructor() {
    super(GeoRSSModule.GEORSS_W3CGEO_URI);
  }

  clone(): Module {
    return this.cloneInto(new W3CGeoModuleImpl());
  }
}
