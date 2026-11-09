// Ported from ROME rome-modules/src/main/java/com/rometools/modules/georss/GMLModuleImpl.java (Apache-2.0)
import { Module } from '../../feed/module/Module';
import { GeoRSSModule } from './GeoRSSModule';

export class GMLModuleImpl extends GeoRSSModule {
  constructor() {
    super(GeoRSSModule.GEORSS_GML_URI);
  }

  clone(): Module {
    return this.cloneInto(new GMLModuleImpl());
  }
}
