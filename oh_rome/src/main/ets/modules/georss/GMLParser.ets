// Ported from ROME rome-modules/src/main/java/com/rometools/modules/georss/GMLParser.java (Apache-2.0)
import { Element } from '../../xml/Dom';
import { Module } from '../../feed/module/Module';
import { ModuleParser } from '../../io/ModuleParser';
import { Doubles } from '../../utils/Doubles';
import { Strings } from '../../utils/Strings';
import { GeoRSSModule } from './GeoRSSModule';
import { GMLModuleImpl } from './GMLModuleImpl';
import { Envelope } from './geometries/Envelope';
import { LinearRing } from './geometries/LinearRing';
import { LineString } from './geometries/LineString';
import { Point } from './geometries/Point';
import { Polygon } from './geometries/Polygon';
import { Position } from './geometries/Position';
import { PositionList } from './geometries/PositionList';

// Java's String.split("\\s+").
export const JAVA_WHITESPACE: RegExp = /[ \t\n\x0B\f\r]+/;

// Double.parseDouble on coord[from] .. coord[from + count - 1] in order: null at the first NumberFormatException, and
// an index past the end throws, as a Java array does.
export function parseCoordinates(coord: string[], from: number, count: number): number[] | null {
  const values: number[] = [];
  for (let i = from; i < from + count; i++) {
    if (i >= coord.length) {
      throw new Error(`Index ${i} out of bounds for length ${coord.length}`);
    }
    const value = Doubles.parse(coord[i]);
    if (value === null) {
      return null;
    }
    values.push(value);
  }
  return values;
}

function coordinates(element: Element): string[] {
  return Strings.trimToEmpty(element.getText()).split(JAVA_WHITESPACE);
}

function parsePosList(element: Element): PositionList | null {
  const coord = coordinates(element);
  const posList = new PositionList();
  for (let i = 0; i < coord.length; i += 2) {
    const pair = parseCoordinates(coord, i, 2);
    if (pair === null) {
      return null;
    }
    posList.add(pair[0], pair[1]);
  }
  return posList;
}

export class GMLParser implements ModuleParser {
  getNamespaceUri(): string {
    return GeoRSSModule.GEORSS_GEORSS_URI;
  }

  parse(element: Element): Module | null {
    return GMLParser.parseGML(element);
  }

  static parseGML(element: Element): Module | null {
    let geoRSSModule: GeoRSSModule | null = null;
    const pointElement = element.getChild('Point', GeoRSSModule.GML_NS);
    const lineStringElement = element.getChild('LineString', GeoRSSModule.GML_NS);
    const polygonElement = element.getChild('Polygon', GeoRSSModule.GML_NS);
    const envelopeElement = element.getChild('Envelope', GeoRSSModule.GML_NS);
    if (pointElement !== null) {
      const posElement = pointElement.getChild('pos', GeoRSSModule.GML_NS);
      if (posElement !== null) {
        geoRSSModule = new GMLModuleImpl();
        const pos = parseCoordinates(coordinates(posElement), 0, 2);
        if (pos === null) {
          return null;
        }
        geoRSSModule.geometry = new Point(new Position(pos[0], pos[1]));
      }
    } else if (lineStringElement !== null) {
      const posListElement = lineStringElement.getChild('posList', GeoRSSModule.GML_NS);
      if (posListElement !== null) {
        geoRSSModule = new GMLModuleImpl();
        const positionList = parsePosList(posListElement);
        if (positionList === null) {
          return null;
        }
        geoRSSModule.geometry = new LineString(positionList);
      }
    } else if (polygonElement !== null) {
      let poly: Polygon | null = null;
      const exteriorElement = polygonElement.getChild('exterior', GeoRSSModule.GML_NS);
      const exteriorRing = exteriorElement === null ? null :
        exteriorElement.getChild('LinearRing', GeoRSSModule.GML_NS);
      const exteriorPosList = exteriorRing === null ? null : exteriorRing.getChild('posList', GeoRSSModule.GML_NS);
      if (exteriorPosList !== null) {
        poly = new Polygon();
        const positionList = parsePosList(exteriorPosList);
        if (positionList === null) {
          return null;
        }
        poly.exterior = new LinearRing(positionList);
      }
      for (const interiorElement of polygonElement.getChildren('interior', GeoRSSModule.GML_NS)) {
        const linearRingElement = interiorElement.getChild('LinearRing', GeoRSSModule.GML_NS);
        const posListElement = linearRingElement === null ? null :
          linearRingElement.getChild('posList', GeoRSSModule.GML_NS);
        if (posListElement !== null) {
          if (poly === null) {
            poly = new Polygon();
          }
          const positionList = parsePosList(posListElement);
          if (positionList === null) {
            return null;
          }
          poly.interior.push(new LinearRing(positionList));
        }
      }
      if (poly !== null) {
        geoRSSModule = new GMLModuleImpl();
        geoRSSModule.geometry = poly;
      }
    } else if (envelopeElement !== null) {
      const lowerElement = envelopeElement.getChild('lowerCorner', GeoRSSModule.GML_NS);
      const upperElement = envelopeElement.getChild('upperCorner', GeoRSSModule.GML_NS);
      if (lowerElement !== null && upperElement !== null) {
        geoRSSModule = new GMLModuleImpl();
        const lower = parseCoordinates(coordinates(lowerElement), 0, 2);
        if (lower === null) {
          return null;
        }
        const upper = parseCoordinates(coordinates(upperElement), 0, 2);
        if (upper === null) {
          return null;
        }
        geoRSSModule.geometry = new Envelope(lower[0], lower[1], upper[0], upper[1]);
      }
    }
    return geoRSSModule;
  }
}
