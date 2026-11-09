// Ported from ROME rome-modules/src/main/java/com/rometools/modules/georss/geometries/PositionList.java (Apache-2.0)
export class PositionList {
  private latitudes: number[] = [];
  private longitudes: number[] = [];

  clone(): PositionList {
    const list = new PositionList();
    list.latitudes = this.latitudes.slice();
    list.longitudes = this.longitudes.slice();
    return list;
  }

  size(): number {
    return this.latitudes.length;
  }

  getLongitude(pos: number): number {
    return this.longitudes[pos];
  }

  getLatitude(pos: number): number {
    return this.latitudes[pos];
  }

  add(latitude: number, longitude: number): void {
    this.latitudes.push(latitude);
    this.longitudes.push(longitude);
  }

  insert(pos: number, latitude: number, longitude: number): void {
    this.latitudes.splice(pos, 0, latitude);
    this.longitudes.splice(pos, 0, longitude);
  }

  replace(pos: number, latitude: number, longitude: number): void {
    this.latitudes[pos] = latitude;
    this.longitudes[pos] = longitude;
  }

  remove(pos: number): void {
    this.latitudes.splice(pos, 1);
    this.longitudes.splice(pos, 1);
  }
}
