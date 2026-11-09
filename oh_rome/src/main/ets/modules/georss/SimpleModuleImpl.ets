// Ported from ROME rome-modules/src/main/java/com/rometools/modules/georss/SimpleModuleImpl.java (Apache-2.0)
import { Module } from '../../feed/module/Module';
import { GeoRSSModule } from './GeoRSSModule';

export class SimpleModuleImpl extends GeoRSSModule {
  constructor() {
    super(GeoRSSModule.GEORSS_GEORSS_URI);
  }

  clone(): Module {
    return this.cloneInto(new SimpleModuleImpl());
  }
}
