// Ported from ROME rome-modules/src/main/java/com/rometools/modules/georss/W3CGeoParser.java (Apache-2.0)
import { Element } from '../../xml/Dom';
import { Module } from '../../feed/module/Module';
import { ModuleParser } from '../../io/ModuleParser';
import { Doubles } from '../../utils/Doubles';
import { Strings } from '../../utils/Strings';
import { GeoRSSModule } from './GeoRSSModule';
import { W3CGeoModuleImpl } from './W3CGeoModuleImpl';
import { Point } from './geometries/Point';
import { Position } from './geometries/Position';

export class W3CGeoParser implements ModuleParser {
  getNamespaceUri(): string {
    return GeoRSSModule.GEORSS_W3CGEO_URI;
  }

  parse(element: Element): Module | null {
    return W3CGeoParser.parseW3C(element);
  }

  static parseW3C(element: Element): Module | null {
    let geoRSSModule: GeoRSSModule | null = null;
    const pointElement = element.getChild('Point', GeoRSSModule.W3CGEO_NS) ?? element;
    const lat = pointElement.getChild('lat', GeoRSSModule.W3CGEO_NS);
    const lng = pointElement.getChild('long', GeoRSSModule.W3CGEO_NS) ??
      pointElement.getChild('lon', GeoRSSModule.W3CGEO_NS);
    if (lat !== null && lng !== null) {
      geoRSSModule = new W3CGeoModuleImpl();
      if (Strings.trimToNull(lat.getText()) !== null && Strings.trimToNull(lng.getText()) !== null) {
        const latitude = Doubles.parse(lat.getText());
        if (latitude === null) {
          return null;
        }
        const longitude = Doubles.parse(lng.getText());
        if (longitude === null) {
          return null;
        }
        geoRSSModule.geometry = new Point(new Position(latitude, longitude));
      }
    }
    return geoRSSModule;
  }
}
