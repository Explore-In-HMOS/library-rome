// Ported from ROME rome-modules/src/main/java/com/rometools/modules/mediarss/types/Location.java (Apache-2.0)
import { GeoRSSModule } from '../../georss/GeoRSSModule';
import { Time } from './Time';

export class Location {
  description: string | null = null;
  start: Time | null = null;
  end: Time | null = null;
  geoRss: GeoRSSModule | null = null;
}
