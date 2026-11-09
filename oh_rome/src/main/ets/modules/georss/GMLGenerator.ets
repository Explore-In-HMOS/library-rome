// Ported from ROME rome-modules/src/main/java/com/rometools/modules/georss/GMLGenerator.java (Apache-2.0)
import { Element, Namespace } from '../../xml/Dom';
import { Module } from '../../feed/module/Module';
import { ModuleGenerator } from '../../io/ModuleGenerator';
import { javaDoubleString } from '../../utils/JavaMath';
import { GeoRSSModule } from './GeoRSSModule';
import { AbstractRing } from './geometries/AbstractRing';
import { Envelope } from './geometries/Envelope';
import { LinearRing } from './geometries/LinearRing';
import { LineString } from './geometries/LineString';
import { Point } from './geometries/Point';
import { Polygon } from './geometries/Polygon';
import { PositionList } from './geometries/PositionList';

function createPosListElement(posList: PositionList): Element {
  const posElement = new Element('posList', GeoRSSModule.GML_NS);
  let sb = '';
  for (let i = 0; i < posList.size(); ++i) {
    sb += javaDoubleString(posList.getLatitude(i)) + ' ' + javaDoubleString(posList.getLongitude(i)) + ' ';
  }
  posElement.addContent(sb);
  return posElement;
}

function ringElement(name: string, ring: LinearRing): Element {
  const element = new Element(name, GeoRSSModule.GML_NS);
  const linearRingElement = new Element('LinearRing', GeoRSSModule.GML_NS);
  element.addContent(linearRingElement);
  linearRingElement.addContent(createPosListElement(ring.positionList));
  return element;
}

export class GMLGenerator implements ModuleGenerator {
  getNamespaceUri(): string {
    return GeoRSSModule.GEORSS_GML_URI;
  }

  getNamespaces(): Namespace[] {
    return [GeoRSSModule.GML_NS];
  }

  // ROME prints and skips geometries and rings GML cannot hold; a null geometry or exterior ring throws there.
  generate(module: Module, element: Element): void {
    // As in ROME, which re-reads element's parent: an element with an Element grandparent loops forever.
    let root = element;
    while (root.getParent() !== null && root.getParent() instanceof Element) {
      root = element.getParent() as Element;
    }
    root.addNamespaceDeclaration(GeoRSSModule.SIMPLE_NS);
    root.addNamespaceDeclaration(GeoRSSModule.GML_NS);

    const whereElement = new Element('where', GeoRSSModule.SIMPLE_NS);
    element.addContent(whereElement);

    const geometry = (module as GeoRSSModule).geometry;
    if (geometry instanceof Point) {
      const pos = (geometry as Point).position;
      const pointElement = new Element('Point', GeoRSSModule.GML_NS);
      whereElement.addContent(pointElement);
      const posElement = new Element('pos', GeoRSSModule.GML_NS);
      posElement.addContent(javaDoubleString(pos.latitude) + ' ' + javaDoubleString(pos.longitude));
      pointElement.addContent(posElement);
    } else if (geometry instanceof LineString) {
      const lineElement = new Element('LineString', GeoRSSModule.GML_NS);
      lineElement.addContent(createPosListElement((geometry as LineString).positionList));
      whereElement.addContent(lineElement);
    } else if (geometry instanceof Polygon) {
      const polygon = geometry as Polygon;
      const polygonElement = new Element('Polygon', GeoRSSModule.GML_NS);
      if (polygon.exterior instanceof LinearRing) {
        polygonElement.addContent(ringElement('exterior', polygon.exterior as LinearRing));
      } else if (polygon.exterior === null) {
        throw new Error('GeoRSS GML: polygon without exterior ring');
      }
      polygon.interior.forEach((ring: AbstractRing) => {
        if (ring instanceof LinearRing) {
          polygonElement.addContent(ringElement('interior', ring as LinearRing));
        }
      });
      whereElement.addContent(polygonElement);
    } else if (geometry instanceof Envelope) {
      const envelope = geometry as Envelope;
      const envelopeElement = new Element('Envelope', GeoRSSModule.GML_NS);
      whereElement.addContent(envelopeElement);
      const lowerElement = new Element('lowerCorner', GeoRSSModule.GML_NS);
      lowerElement.addContent(javaDoubleString(envelope.minLatitude) + ' ' + javaDoubleString(envelope.minLongitude));
      envelopeElement.addContent(lowerElement);
      const upperElement = new Element('upperCorner', GeoRSSModule.GML_NS);
      upperElement.addContent(javaDoubleString(envelope.maxLatitude) + ' ' + javaDoubleString(envelope.maxLongitude));
      envelopeElement.addContent(upperElement);
    } else if (geometry === null) {
      throw new Error('GeoRSS GML: module without geometry');
    }
  }
}
