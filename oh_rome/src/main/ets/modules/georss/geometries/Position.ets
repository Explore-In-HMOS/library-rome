// Ported from ROME rome-modules/src/main/java/com/rometools/modules/georss/geometries/Position.java (Apache-2.0)
export class Position {
  latitude: number;
  longitude: number;

  constructor(latitude: number = NaN, longitude: number = NaN) {
    this.latitude = latitude;
    this.longitude = longitude;
  }

  clone(): Position {
    return new Position(this.latitude, this.longitude);
  }
}
