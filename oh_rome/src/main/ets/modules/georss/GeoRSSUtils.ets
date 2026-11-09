// Ported from ROME rome-modules/src/main/java/com/rometools/modules/georss/GeoRSSUtils.java (Apache-2.0)
import { Extendable } from '../../feed/module/Module';
import { GeoRSSModule } from './GeoRSSModule';

export class GeoRSSUtils {
  // Java's getGeoRSS(SyndEntry) and getGeoRSS(SyndFeed) in one: gml first, then simple, then W3C geo.
  static getGeoRSS(extendable: Extendable): GeoRSSModule | null {
    for (const uri of [GeoRSSModule.GEORSS_GML_URI, GeoRSSModule.GEORSS_GEORSS_URI, GeoRSSModule.GEORSS_W3CGEO_URI]) {
      const module = extendable.getModule(uri);
      if (module !== null) {
        return module as GeoRSSModule;
      }
    }
    return null;
  }
}
