// Ported from ROME rome-modules/src/main/java/com/rometools/modules/georss/geometries/Point.java (Apache-2.0)
import { AbstractGeometricPrimitive } from './AbstractGeometricPrimitive';
import { Position } from './Position';

export class Point extends AbstractGeometricPrimitive {
  position: Position;

  constructor(position: Position = new Position()) {
    super();
    this.position = position;
  }

  clone(): Point {
    return new Point(this.position.clone());
  }
}
