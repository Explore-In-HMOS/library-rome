// Ported from ROME rome-modules/src/main/java/com/rometools/modules/georss/GeoRSSModule.java (Apache-2.0)
import { Module, ModuleImpl } from '../../feed/module/Module';
import { Namespace } from '../../xml/Dom';
import { AbstractGeometry } from './geometries/AbstractGeometry';
import { Point } from './geometries/Point';
import { Position } from './geometries/Position';

export abstract class GeoRSSModule extends ModuleImpl {
  static readonly version: string = '0.9.8';
  static readonly GEORSS_GEORSS_URI: string = 'http://www.georss.org/georss';
  static readonly GEORSS_W3CGEO_URI: string = 'http://www.w3.org/2003/01/geo/wgs84_pos#';
  static readonly GEORSS_GML_URI: string = 'http://www.opengis.net/gml';
  static readonly SIMPLE_NS: Namespace = Namespace.getNamespace('georss', GeoRSSModule.GEORSS_GEORSS_URI);
  static readonly W3CGEO_NS: Namespace = Namespace.getNamespace('geo', GeoRSSModule.GEORSS_W3CGEO_URI);
  static readonly GML_NS: Namespace = Namespace.getNamespace('gml', GeoRSSModule.GEORSS_GML_URI);
  geometry: AbstractGeometry | null = null;
  elev: number | null = null;
  floor: number | null = null;
  radius: number | null = null;
  featureTypeTag: string | null = null;
  relationshipTag: string | null = null;
  featureNameTag: string | null = null;

  get position(): Position | null {
    return this.geometry instanceof Point ? (this.geometry as Point).position : null;
  }

  set position(pos: Position | null) {
    if (pos !== null) {
      this.geometry = new Point(pos);
    }
  }

  // Like Java, copies only the geometry and throws when the other module has none.
  copyFrom(obj: Module): void {
    this.geometry = (obj as GeoRSSModule).geometry!.clone();
  }

  protected cloneInto(module: GeoRSSModule): GeoRSSModule {
    module.geometry = this.geometry === null ? null : this.geometry.clone();
    module.elev = this.elev;
    module.floor = this.floor;
    module.radius = this.radius;
    module.featureTypeTag = this.featureTypeTag;
    module.relationshipTag = this.relationshipTag;
    module.featureNameTag = this.featureNameTag;
    return module;
  }
}
