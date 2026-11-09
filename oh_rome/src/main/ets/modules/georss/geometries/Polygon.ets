// Ported from ROME rome-modules/src/main/java/com/rometools/modules/georss/geometries/Polygon.java (Apache-2.0)
import { AbstractRing } from './AbstractRing';
import { AbstractSurface } from './AbstractSurface';

export class Polygon extends AbstractSurface {
  exterior: AbstractRing | null = null;
  interior: AbstractRing[] = [];

  clone(): Polygon {
    const polygon = new Polygon();
    polygon.exterior = this.exterior === null ? null : this.exterior.clone();
    polygon.interior = this.interior.map((r: AbstractRing) => r.clone());
    return polygon;
  }
}
