// Ported from ROME rome-modules/src/main/java/com/rometools/modules/georss/SimpleParser.java (Apache-2.0)
import { Element } from '../../xml/Dom';
import { Module } from '../../feed/module/Module';
import { ModuleParser } from '../../io/ModuleParser';
import { Doubles } from '../../utils/Doubles';
import { Integers } from '../../utils/Integers';
import { Strings } from '../../utils/Strings';
import { GeoRSSModule } from './GeoRSSModule';
import { GMLParser, JAVA_WHITESPACE, parseCoordinates } from './GMLParser';
import { SimpleModuleImpl } from './SimpleModuleImpl';
import { Envelope } from './geometries/Envelope';
import { LinearRing } from './geometries/LinearRing';
import { LineString } from './geometries/LineString';
import { Point } from './geometries/Point';
import { Polygon } from './geometries/Polygon';
import { Position } from './geometries/Position';
import { PositionList } from './geometries/PositionList';

function parsePosList(element: Element): PositionList | null {
  const coordinates = Strings.trimToNull(element.getText());
  if (coordinates === null) {
    return null;
  }
  const posList = new PositionList();
  const coord = coordinates.split(JAVA_WHITESPACE);
  for (let i = 0; i < coord.length; i += 2) {
    const pair = parseCoordinates(coord, i, 2);
    if (pair === null) {
      return null;
    }
    posList.add(pair[0], pair[1]);
  }
  return posList;
}

export class SimpleParser implements ModuleParser {
  getNamespaceUri(): string {
    return GeoRSSModule.GEORSS_GEORSS_URI;
  }

  parse(element: Element): Module | null {
    return SimpleParser.parseSimple(element);
  }

  static parseSimple(element: Element): Module | null {
    const pointElement = element.getChild('point', GeoRSSModule.SIMPLE_NS);
    const lineElement = element.getChild('line', GeoRSSModule.SIMPLE_NS);
    const polygonElement = element.getChild('polygon', GeoRSSModule.SIMPLE_NS);
    const boxElement = element.getChild('box', GeoRSSModule.SIMPLE_NS);
    const whereElement = element.getChild('where', GeoRSSModule.SIMPLE_NS);
    const featureNameTagElement = element.getChild('featurename', GeoRSSModule.SIMPLE_NS);
    const featureTypeTagElement = element.getChild('featuretypetag', GeoRSSModule.SIMPLE_NS);
    const relationshipTagElement = element.getChild('relationshiptag', GeoRSSModule.SIMPLE_NS);
    const elevElement = element.getChild('elev', GeoRSSModule.SIMPLE_NS);
    const floorElement = element.getChild('floor', GeoRSSModule.SIMPLE_NS);
    const radiusElement = element.getChild('radius', GeoRSSModule.SIMPLE_NS);
    let geoRSSModule: GeoRSSModule | null = null;
    if (pointElement !== null) {
      const coordinates = Strings.trimToNull(pointElement.getText());
      if (coordinates !== null) {
        const coord = coordinates.split(JAVA_WHITESPACE);
        if (coord.length === 2) {
          const latitude = Doubles.parse(coord[0]);
          const longitude = Doubles.parse(coord[1]);
          if (latitude !== null && longitude !== null) {
            geoRSSModule = new SimpleModuleImpl();
            geoRSSModule.geometry = new Point(new Position(latitude, longitude));
          }
        }
      }
    } else if (lineElement !== null) {
      const posList = parsePosList(lineElement);
      if (posList !== null) {
        geoRSSModule = new SimpleModuleImpl();
        geoRSSModule.geometry = new LineString(posList);
      }
    } else if (polygonElement !== null) {
      const posList = parsePosList(polygonElement);
      if (posList !== null) {
        const poly = new Polygon();
        poly.exterior = new LinearRing(posList);
        geoRSSModule = new SimpleModuleImpl();
        geoRSSModule.geometry = poly;
      }
    } else if (boxElement !== null) {
      const coordinates = Strings.trimToNull(boxElement.getText());
      if (coordinates !== null) {
        const box = parseCoordinates(coordinates.split(JAVA_WHITESPACE), 0, 4);
        if (box === null) {
          return null;
        }
        geoRSSModule = new SimpleModuleImpl();
        geoRSSModule.geometry = new Envelope(box[0], box[1], box[2], box[3]);
      }
    } else if (whereElement !== null) {
      geoRSSModule = GMLParser.parseGML(whereElement) as GeoRSSModule | null;
    }
    if (geoRSSModule !== null) {
      if (featureTypeTagElement !== null) {
        geoRSSModule.featureTypeTag = featureTypeTagElement.getText();
      }
      if (featureNameTagElement !== null) {
        geoRSSModule.featureNameTag = featureNameTagElement.getText();
      }
      if (relationshipTagElement !== null) {
        geoRSSModule.relationshipTag = relationshipTagElement.getText();
      }
      if (elevElement !== null) {
        geoRSSModule.elev = Doubles.parse(elevElement.getText());
      }
      if (floorElement !== null) {
        geoRSSModule.floor = Integers.parse(floorElement.getText());
      }
      if (radiusElement !== null) {
        geoRSSModule.radius = Doubles.parse(radiusElement.getText());
      }
    }
    return geoRSSModule;
  }
}
