// Ported from ROME rome-modules/src/main/java/com/rometools/modules/georss/SimpleGenerator.java (Apache-2.0)
import { Element, Namespace } from '../../xml/Dom';
import { Module } from '../../feed/module/Module';
import { ModuleGenerator } from '../../io/ModuleGenerator';
import { javaDoubleString } from '../../utils/JavaMath';
import { GeoRSSModule } from './GeoRSSModule';
import { Envelope } from './geometries/Envelope';
import { LinearRing } from './geometries/LinearRing';
import { LineString } from './geometries/LineString';
import { Point } from './geometries/Point';
import { Polygon } from './geometries/Polygon';
import { PositionList } from './geometries/PositionList';

function posListToString(posList: PositionList): string {
  let sb = '';
  for (let i = 0; i < posList.size(); ++i) {
    sb += javaDoubleString(posList.getLatitude(i)) + ' ' + javaDoubleString(posList.getLongitude(i)) + ' ';
  }
  return sb;
}

export class SimpleGenerator implements ModuleGenerator {
  getNamespaceUri(): string {
    return GeoRSSModule.GEORSS_GEORSS_URI;
  }

  getNamespaces(): Namespace[] {
    return [GeoRSSModule.SIMPLE_NS];
  }

  // ROME logs and skips geometries the simple format cannot hold; a null geometry or exterior ring throws there.
  generate(module: Module, element: Element): void {
    // As in ROME, which re-reads element's parent: an element with an Element grandparent loops forever.
    let root = element;
    while (root.getParent() !== null && root.getParent() instanceof Element) {
      root = element.getParent() as Element;
    }
    root.addNamespaceDeclaration(GeoRSSModule.SIMPLE_NS);

    const geoRSSModule = module as GeoRSSModule;
    const geometry = geoRSSModule.geometry;
    if (geometry instanceof Point) {
      const pos = (geometry as Point).position;
      const pointElement = new Element('point', GeoRSSModule.SIMPLE_NS);
      pointElement.addContent(javaDoubleString(pos.latitude) + ' ' + javaDoubleString(pos.longitude));
      element.addContent(pointElement);
    } else if (geometry instanceof LineString) {
      const lineElement = new Element('line', GeoRSSModule.SIMPLE_NS);
      lineElement.addContent(posListToString((geometry as LineString).positionList));
      element.addContent(lineElement);
    } else if (geometry instanceof Polygon) {
      const ring = (geometry as Polygon).exterior;
      if (ring instanceof LinearRing) {
        const polygonElement = new Element('polygon', GeoRSSModule.SIMPLE_NS);
        polygonElement.addContent(posListToString((ring as LinearRing).positionList));
        element.addContent(polygonElement);
      } else if (ring === null) {
        throw new Error('GeoRSS simple: polygon without exterior ring');
      }
    } else if (geometry instanceof Envelope) {
      const envelope = geometry as Envelope;
      const boxElement = new Element('box', GeoRSSModule.SIMPLE_NS);
      boxElement.addContent(javaDoubleString(envelope.minLatitude) + ' ' + javaDoubleString(envelope.minLongitude) +
        ' ' + javaDoubleString(envelope.maxLatitude) + ' ' + javaDoubleString(envelope.maxLongitude));
      element.addContent(boxElement);
    } else if (geometry === null) {
      throw new Error('GeoRSS simple: module without geometry');
    }
    if (geoRSSModule.featureNameTag !== null) {
      const featureNameElement = new Element('featurename', GeoRSSModule.SIMPLE_NS);
      featureNameElement.addContent(geoRSSModule.featureNameTag);
      element.addContent(featureNameElement);
    }
  }
}
