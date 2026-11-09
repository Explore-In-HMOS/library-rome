// Ported from ROME rome-modules/src/main/java/com/rometools/modules/georss/geometries/Envelope.java (Apache-2.0)
import { AbstractGeometry } from './AbstractGeometry';

export class Envelope extends AbstractGeometry {
  minLatitude: number;
  minLongitude: number;
  maxLatitude: number;
  maxLongitude: number;

  constructor(minLatitude: number = NaN, minLongitude: number = NaN, maxLatitude: number = NaN,
    maxLongitude: number = NaN) {
    super();
    this.minLatitude = minLatitude;
    this.minLongitude = minLongitude;
    this.maxLatitude = maxLatitude;
    this.maxLongitude = maxLongitude;
  }

  clone(): Envelope {
    return new Envelope(this.minLatitude, this.minLongitude, this.maxLatitude, this.maxLongitude);
  }
}
