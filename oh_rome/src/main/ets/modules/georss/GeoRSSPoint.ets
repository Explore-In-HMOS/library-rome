// Ported from ROME rome-modules/src/main/java/com/rometools/modules/georss/GeoRSSPoint.java (Apache-2.0)
export class GeoRSSPoint {
  latitude: number = 0;
  longitude: number = 0;

  clone(): GeoRSSPoint {
    const point = new GeoRSSPoint();
    point.latitude = this.latitude;
    point.longitude = this.longitude;
    return point;
  }
}
