// Ported from ROME rome-modules/src/main/java/com/rometools/modules/georss/W3CGeoGenerator.java (Apache-2.0)
import { Element, Namespace } from '../../xml/Dom';
import { Module } from '../../feed/module/Module';
import { ModuleGenerator } from '../../io/ModuleGenerator';
import { javaDoubleString } from '../../utils/JavaMath';
import { GeoRSSModule } from './GeoRSSModule';
import { Point } from './geometries/Point';

export class W3CGeoGenerator implements ModuleGenerator {
  private static isShort: boolean = true;

  static enableDefaultPointElement(): void {
    W3CGeoGenerator.isShort = false;
  }

  getNamespaceUri(): string {
    return GeoRSSModule.GEORSS_W3CGEO_URI;
  }

  getNamespaces(): Namespace[] {
    return [GeoRSSModule.W3CGEO_NS];
  }

  // ROME prints and skips non-point geometries; a null geometry throws there.
  generate(module: Module, element: Element): void {
    // As in ROME, which re-reads element's parent: an element with an Element grandparent loops forever.
    let root = element;
    while (root.getParent() !== null && root.getParent() instanceof Element) {
      root = element.getParent() as Element;
    }
    root.addNamespaceDeclaration(GeoRSSModule.W3CGEO_NS);

    let pointElement = element;
    if (!W3CGeoGenerator.isShort) {
      pointElement = new Element('Point', GeoRSSModule.W3CGEO_NS);
      element.addContent(pointElement);
    }
    const geometry = (module as GeoRSSModule).geometry;
    if (geometry instanceof Point) {
      const pos = (geometry as Point).position;
      const latElement = new Element('lat', GeoRSSModule.W3CGEO_NS);
      latElement.addContent(javaDoubleString(pos.latitude));
      pointElement.addContent(latElement);
      const lngElement = new Element('long', GeoRSSModule.W3CGEO_NS);
      lngElement.addContent(javaDoubleString(pos.longitude));
      pointElement.addContent(lngElement);
    } else if (geometry === null) {
      throw new Error('W3C Geo: module without geometry');
    }
  }
}
