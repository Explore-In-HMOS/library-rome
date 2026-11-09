// Ported from ROME rome-modules/src/main/java/com/rometools/modules/mediarss/types/Metadata.java (Apache-2.0)
import { Category } from './Category';
import { Community } from './Community';
import { Credit } from './Credit';
import { Embed } from './Embed';
import { Hash } from './Hash';
import { License } from './License';
import { Location } from './Location';
import { PeerLink } from './PeerLink';
import { Price } from './Price';
import { Rating } from './Rating';
import { Restriction } from './Restriction';
import { Scene } from './Scene';
import { Status } from './Status';
import { SubTitle } from './SubTitle';
import { Text } from './Text';
import { Thumbnail } from './Thumbnail';

export enum MetadataRightsStatus {
  userCreated = 'userCreated',
  official = 'official'
}

export class Metadata {
  hash: Hash | null = null;
  copyright: string | null = null;
  description: string | null = null;
  descriptionType: string | null = null;
  title: string | null = null;
  titleType: string | null = null;
  copyrightUrl: string | null = null;
  categories: Category[] = [];
  credits: Credit[] = [];
  keywords: string[] = [];
  ratings: Rating[] = [];
  restrictions: Restriction[] = [];
  text: Text[] = [];
  thumbnail: Thumbnail[] = [];
  community: Community | null = null;
  comments: string[] = [];
  responses: string[] = [];
  backLinks: string[] = [];
  status: Status | null = null;
  prices: Price[] = [];
  embed: Embed | null = null;
  licenses: License[] = [];
  subTitles: SubTitle[] = [];
  peerLinks: PeerLink[] = [];
  locations: Location[] = [];
  rights: MetadataRightsStatus | null = null;
  scenes: Scene[] = [];

  // Shallow, as in Java: the copy shares the arrays and the objects in them.
  clone(): Metadata {
    const md = new Metadata();
    md.categories = this.categories;
    md.copyright = this.copyright;
    md.copyrightUrl = this.copyrightUrl;
    md.credits = this.credits;
    md.description = this.description;
    md.descriptionType = this.descriptionType;
    md.hash = this.hash;
    md.keywords = this.keywords;
    md.ratings = this.ratings;
    md.text = this.text;
    md.thumbnail = this.thumbnail;
    md.title = this.title;
    md.titleType = this.titleType;
    md.restrictions = this.restrictions;
    md.backLinks = this.backLinks;
    md.community = this.community;
    md.comments = this.comments;
    md.responses = this.responses;
    md.status = this.status;
    md.prices = this.prices;
    md.embed = this.embed;
    md.licenses = this.licenses;
    md.subTitles = this.subTitles;
    md.peerLinks = this.peerLinks;
    md.locations = this.locations;
    md.rights = this.rights;
    md.scenes = this.scenes;
    return md;
  }
}
