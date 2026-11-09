// Ported from ROME rome/src/main/java/com/rometools/rome/feed/rss/Channel.java (Apache-2.0)
import { IllegalArgumentException } from '../../utils/Exceptions';
import { Dates } from '../../utils/Dates';
import { WireFeed } from '../WireFeed';
import { Category } from './Category';
import { Cloud } from './Cloud';
import { Image } from './Image';
import { Item } from './Item';
import { TextInput } from './TextInput';

const DAYS: string[] = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];

export class Channel extends WireFeed {
  static readonly SUNDAY: string = 'sunday';
  static readonly MONDAY: string = 'monday';
  static readonly TUESDAY: string = 'tuesday';
  static readonly WEDNESDAY: string = 'wednesday';
  static readonly THURSDAY: string = 'thursday';
  static readonly FRIDAY: string = 'friday';
  static readonly SATURDAY: string = 'saturday';

  title: string | null = null;
  description: string | null = null;
  link: string | null = null;
  uri: string | null = null;
  image: Image | null = null;
  items: Item[] = [];
  textInput: TextInput | null = null;
  language: string | null = null;
  rating: string | null = null;
  copyright: string | null = null;
  private _pubDate: Date | null = null;
  private _lastBuildDate: Date | null = null;
  docs: string | null = null;
  managingEditor: string | null = null;
  webMaster: string | null = null;
  private _skipHours: number[] = [];
  private _skipDays: string[] = [];
  cloud: Cloud | null = null;
  categories: Category[] = [];
  generator: string | null = null;
  ttl: number = -1;

  get pubDate(): Date | null {
    return Dates.copy(this._pubDate);
  }

  set pubDate(pubDate: Date | null) {
    this._pubDate = Dates.copy(pubDate);
  }

  get lastBuildDate(): Date | null {
    return Dates.copy(this._lastBuildDate);
  }

  set lastBuildDate(lastBuildDate: Date | null) {
    this._lastBuildDate = Dates.copy(lastBuildDate);
  }

  get skipHours(): number[] {
    return this._skipHours;
  }

  set skipHours(skipHours: number[]) {
    for (const hour of skipHours) {
      if (hour < 0 || hour > 24) {
        throw new IllegalArgumentException('Invalid hour [' + hour + ']');
      }
    }
    this._skipHours = skipHours;
  }

  get skipDays(): string[] {
    return this._skipDays;
  }

  // Lowercases the given list in place, up to the first invalid day.
  set skipDays(skipDays: string[]) {
    for (let i = 0; i < skipDays.length; i++) {
      const day = skipDays[i].toLowerCase();
      if (!DAYS.includes(day)) {
        throw new IllegalArgumentException('Invalid day [' + day + ']');
      }
      skipDays[i] = day;
    }
    this._skipDays = skipDays;
  }
}
