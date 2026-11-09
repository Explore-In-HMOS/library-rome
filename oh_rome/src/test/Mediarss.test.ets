import { describe, it, expect } from '@ohos/hypium';
import { MediaEntryModule } from '../main/ets/modules/mediarss/MediaEntryModule';
import { MediaModule } from '../main/ets/modules/mediarss/MediaModule';
import { Category } from '../main/ets/modules/mediarss/types/Category';
import { Community } from '../main/ets/modules/mediarss/types/Community';
import { Credit } from '../main/ets/modules/mediarss/types/Credit';
import { Embed, EmbedParam } from '../main/ets/modules/mediarss/types/Embed';
import { Expression } from '../main/ets/modules/mediarss/types/Expression';
import { Hash } from '../main/ets/modules/mediarss/types/Hash';
import { License } from '../main/ets/modules/mediarss/types/License';
import { Location } from '../main/ets/modules/mediarss/types/Location';
import { MediaContent } from '../main/ets/modules/mediarss/types/MediaContent';
import { MediaGroup } from '../main/ets/modules/mediarss/types/MediaGroup';
import { Metadata, MetadataRightsStatus } from '../main/ets/modules/mediarss/types/Metadata';
import { PeerLink } from '../main/ets/modules/mediarss/types/PeerLink';
import { PlayerReference } from '../main/ets/modules/mediarss/types/PlayerReference';
import { Price, PriceType } from '../main/ets/modules/mediarss/types/Price';
import { Rating } from '../main/ets/modules/mediarss/types/Rating';
import { Restriction, RestrictionRelationship, RestrictionType } from '../main/ets/modules/mediarss/types/Restriction';
import { Scene } from '../main/ets/modules/mediarss/types/Scene';
import { StarRating } from '../main/ets/modules/mediarss/types/StarRating';
import { Statistics } from '../main/ets/modules/mediarss/types/Statistics';
import { Status, StatusState } from '../main/ets/modules/mediarss/types/Status';
import { SubTitle } from '../main/ets/modules/mediarss/types/SubTitle';
import { Tag } from '../main/ets/modules/mediarss/types/Tag';
import { Text } from '../main/ets/modules/mediarss/types/Text';
import { Thumbnail } from '../main/ets/modules/mediarss/types/Thumbnail';
import { Time } from '../main/ets/modules/mediarss/types/Time';
import { UrlReference } from '../main/ets/modules/mediarss/types/UrlReference';
import { IllegalArgumentException } from '../main/ets/utils/Exceptions';
import { CREDIT_ROLES, FACTS, PROPERTIES, TAG_ORDER, TIME_PARSE, TIME_TO_STRING } from './MediarssCases';

// Same format as MediarssOracle.run: a Java exception becomes "<class>: <message>". IllegalArgumentException and its
// subclasses keep their class; other ported runtime exceptions are plain Errors, so only the message is compared; a
// null dereference (TypeError) stands for a message-less NPE.
function run(f: () => string): string {
  try {
    return f();
  } catch (e) {
    if (e instanceof TypeError) {
      return 'NullPointerException';
    }
    const error = e as Error;
    if (error instanceof IllegalArgumentException) {
      return `${error.name}: ${error.message}`;
    }
    return error.name === 'Error' ? 'Exception: ' + error.message : error.name;
  }
}

const ARGUMENT_EXCEPTIONS: string[] = ['IllegalArgumentException', 'NumberFormatException'];

function normalize(expected: string): string {
  const match = /^([A-Za-z]+Exception): ([\s\S]*)$/.exec(expected);
  return match === null || ARGUMENT_EXCEPTIONS.includes(match[1]) ? expected : 'Exception: ' + match[2];
}

function sameCases(cases: string[][], actual: (input: string) => string): string {
  return cases.filter((c: string[]) => actual(c[0]) !== normalize(c[1]))
    .map((c: string[]) =>
      `${JSON.stringify(c[0])}: expected ${JSON.stringify(c[1])}, got ${JSON.stringify(actual(c[0]))}`)
    .join('\n');
}

// Values beyond 2^53 lose precision as a number, so their toString cannot match Java's.
function timeParse(input: string): string {
  const t = Time.parse(input);
  return `${t.value} ${Math.abs(t.value) <= Number.MAX_SAFE_INTEGER ? t.toString() : '<imprecise>'}`;
}

function expectedTimeParse(expected: string): string {
  const match = /^(-?\d+) (.*)$/.exec(expected);
  if (match === null) {
    return expected;
  }
  const value = Number(match[1]);
  return `${value} ${Math.abs(value) <= Number.MAX_SAFE_INTEGER ? match[2] : '<imprecise>'}`;
}

function tagOrder(sequence: string): string {
  const community = new Community();
  sequence.split(' ').forEach((spec: string) => {
    const parts = spec.split(':');
    community.addTag(new Tag(parts[0], parts.length > 1 ? Number(parts[1]) : null));
  });
  return community.tags.map((tag: Tag) => `${tag.name}:${tag.weight}`).join(' ');
}

function metadataFields(m: Metadata): (Object | null)[] {
  return [m.hash, m.copyright, m.description, m.descriptionType, m.title, m.titleType, m.copyrightUrl, m.categories,
    m.credits, m.keywords, m.ratings, m.restrictions, m.text, m.thumbnail, m.community, m.comments, m.responses,
    m.backLinks, m.status, m.prices, m.embed, m.licenses, m.subTitles, m.peerLinks, m.locations, m.rights, m.scenes];
}

function metadataCloneFieldsNotShared(): string {
  const md = new Metadata();
  md.hash = new Hash(null, 'h');
  md.copyright = 'copyright';
  md.description = 'description';
  md.descriptionType = 'descriptionType';
  md.title = 'title';
  md.titleType = 'titleType';
  md.copyrightUrl = 'http://x/copyrightUrl';
  md.categories = [];
  md.credits = [];
  md.keywords = [];
  md.ratings = [];
  md.restrictions = [];
  md.text = [];
  md.thumbnail = [];
  md.community = new Community();
  md.comments = [];
  md.responses = [];
  md.backLinks = [];
  md.status = new Status();
  md.prices = [];
  md.embed = new Embed();
  md.licenses = [];
  md.subTitles = [];
  md.peerLinks = [];
  md.locations = [];
  md.rights = MetadataRightsStatus.official;
  md.scenes = [];
  const original = metadataFields(md);
  const copied = metadataFields(md.clone());
  const fresh = metadataFields(new Metadata());
  const notShared = original.filter((v: Object | null, i: number) => copied[i] !== v || fresh[i] === v);
  return `${original.length} fields, not shared: [${notShared.length === 0 ? '' : notShared.length}]`;
}

function facts(): string[][] {
  const f: string[][] = [];
  const md = new Metadata();
  md.categories = [new Category('s', 'l', 'v')];
  md.title = 't';
  const copy = md.clone();
  f.push(['metadataCloneSharesArrays', String(copy.categories === md.categories)]);
  f.push(['metadataCloneCopiesTitle', String(copy.title)]);
  f.push(['metadataCloneFieldsNotShared', metadataCloneFieldsNotShared()]);

  const entry = new MediaEntryModule();
  const content = new MediaContent(new UrlReference('http://x/a.mp4'));
  entry.mediaContents = [content];
  entry.mediaGroups = [new MediaGroup([content])];
  entry.metadata = md;
  entry.player = new PlayerReference('http://x/p');
  const entryCopy = entry.clone();
  f.push(['entryCloneCopiesArrays',
    String(entryCopy.mediaContents !== entry.mediaContents && entryCopy.mediaGroups !== entry.mediaGroups)]);
  f.push(['entryCloneSharesItems',
    String(entryCopy.mediaContents[0] === content && entryCopy.mediaGroups[0] === entry.mediaGroups[0])]);
  f.push(['entryCloneMetadataIsNew',
    String(entryCopy.metadata !== md && entryCopy.metadata!.categories === md.categories)]);
  f.push(['entryCloneSharesPlayer', String(entryCopy.player === entry.player)]);
  f.push(['entryCloneUri', entryCopy.uri]);
  f.push(['entryCloneNullMetadata', run(() => String(new MediaEntryModule().clone().metadata))]);
  const target = new MediaEntryModule();
  target.copyFrom(entry);
  f.push(['entryCopyFrom', String(target.mediaContents[0] === content && target.mediaContents !== entry.mediaContents &&
    target.metadata !== md && target.metadata!.title === 't' && target.player === entry.player)]);

  const feedModule = new MediaModule();
  feedModule.metadata = md;
  const feedCopy = feedModule.clone();
  f.push(['moduleCloneMetadataIsNew', String(feedCopy.metadata !== md && feedCopy.metadata!.title === 't')]);
  f.push(['moduleCloneNullMetadata', run(() => String(new MediaModule().clone()))]);
  const feedTarget = new MediaModule();
  feedTarget.copyFrom(feedModule);
  f.push(['moduleCopyFrom', String(feedTarget.metadata !== md && feedTarget.metadata!.title === 't')]);

  const player = new PlayerReference('http://x/p', 640, 480);
  f.push(['contentPlayerFromReference', String(new MediaContent(player).player === player)]);
  f.push(['contentUrlReferenceNoPlayer', String(new MediaContent(new UrlReference('http://x/a')).player)]);
  f.push(['contentNullReference', run(() => String(new MediaContent(null)))]);
  f.push(['urlReferenceToString', new UrlReference('http://x/a%20b?c#d').toString()]);
  f.push(['urlReferenceInvalid', run(() => String(new UrlReference('http://x/a b')))]);
  f.push(['urlReferenceNull', run(() => String(new UrlReference(null)))]);
  f.push(['playerReferenceNull', run(() => String(new PlayerReference(null)))]);

  const c0 = new MediaContent(new UrlReference('http://x/0'));
  const c1 = new MediaContent(new UrlReference('http://x/1'));
  c0.defaultContent = true;
  const group = new MediaGroup([c0, c1], 1);
  f.push(['groupDefaultIndex', `${group.defaultContentIndex} ${c0.defaultContent} ${c1.defaultContent}`]);
  group.defaultContentIndex = 5;
  f.push(['groupDefaultIndexOutOfRange', `${group.defaultContentIndex} ${c0.defaultContent} ${c1.defaultContent}`]);
  f.push(['groupNullIndex', run(() => String(new MediaGroup([c0], null)))]);
  f.push(['groupNullIndexEmpty', run(() => String(new MediaGroup([], null).defaultContentIndex))]);
  f.push(['groupNullContents', String(new MediaGroup([]).contents.length)]);

  f.push(['hashDefaultAlgorithm', new Hash(null, 'abc').algorithm]);
  f.push(['hashNullValue', run(() => String(new Hash('SHA-1', null)))]);
  f.push(['ratingNullScheme', run(() => String(new Rating(null, 'adult')))]);
  f.push(['ratingEqualsAdult', String(new Rating('urn:simple', 'adult').equals(Rating.ADULT))]);
  f.push(['ratingEqualsOther', String(new Rating('urn:simple', 'Adult').equals(Rating.ADULT) ||
    new Rating('urn:mpaa', 'adult').equals(Rating.ADULT) || Rating.ADULT.equals(Rating.NONADULT) ||
    Rating.ADULT.equals(null))]);
  f.push(['creditDefaults', `${new Credit(null, null, 'n').scheme} ${new Credit(null, null, 'n').role}`]);
  f.push(['creditNullName', run(() => String(new Credit('s', 'r', null)))]);
  f.push(['restrictionNullRelationship', run(() => String(new Restriction(null, RestrictionType.COUNTRY, 'us')))]);
  f.push(['restrictionNullValue',
    run(() => String(new Restriction(RestrictionRelationship.ALLOW, RestrictionType.COUNTRY, null)))]);
  f.push(['restrictionNullType', run(() => String(new Restriction(RestrictionRelationship.ALLOW, null, 'us')))]);
  f.push(['restrictionAllWithoutType', run(() => new Restriction(RestrictionRelationship.DENY, null, 'all').value)]);
  f.push(['restrictionNoneWithoutType', run(() => new Restriction(RestrictionRelationship.DENY, null, 'none').value)]);
  f.push(['restrictionAllUppercase', run(() => String(new Restriction(RestrictionRelationship.DENY, null, 'ALL')))]);
  f.push(['restrictionToStrings', [RestrictionRelationship.ALLOW, RestrictionRelationship.DENY, RestrictionType.COUNTRY,
    RestrictionType.SHARING, RestrictionType.URI].join(' ')]);
  f.push(['enumStrings', `[${[Expression.FULL, Expression.SAMPLE, Expression.NONSTOP].join(', ')}]` +
    `[${[PriceType.RENT, PriceType.PURCHASE, PriceType.PACKAGE, PriceType.SUBSCRIPTION].join(', ')}]` +
    `[${[StatusState.active, StatusState.blocked, StatusState.deleted].join(', ')}]` +
    `[${[MetadataRightsStatus.userCreated, MetadataRightsStatus.official].join(', ')}]`]);
  f.push(['constants', `${MediaModule.URI} ${Category.SCHEME_FLICKR_TAGS} ${Credit.SCHEME_EBU}`]);
  f.push(['tagDefaultWeight', String(new Tag('a').weight)]);
  f.push(['tagCompareNull',
    `${new Tag('a', 2).compareTo(null)} ${new Tag('a').compareTo(null)} ${new Tag('a', 0).compareTo(null)}`]);
  return f;
}

// The golden comparator maps a private "_x" field to the Java property "x".
function jsonKeys(value: Object): string {
  const obj = JSON.parse(JSON.stringify(value)) as Record<string, Object>;
  return Object.keys(obj).map((k: string) => k.startsWith('_') ? k.substring(1) : k).sort().join(' ');
}

function serializedKeys(name: string): string {
  const content = new MediaContent(new UrlReference('http://x/a'));
  const instances: Record<string, Object> = {
    'MediaModule': new MediaModule(),
    'MediaEntryModule': new MediaEntryModule(),
    'Category': new Category(null, null, null),
    'Community': new Community(),
    'Credit': new Credit(null, null, 'n'),
    'Embed': new Embed(),
    'Embed.Param': new EmbedParam(),
    'Hash': new Hash(null, 'h'),
    'License': new License(),
    'Location': new Location(),
    'MediaContent': content,
    'MediaGroup': new MediaGroup([content]),
    'Metadata': new Metadata(),
    'PeerLink': new PeerLink(),
    'PlayerReference': new PlayerReference('http://x/p'),
    'Price': new Price(),
    'Rating': new Rating('s', 'v'),
    'Restriction': new Restriction(RestrictionRelationship.ALLOW, null, 'all'),
    'Scene': new Scene(),
    'StarRating': new StarRating(),
    'Statistics': new Statistics(),
    'Status': new Status(),
    'SubTitle': new SubTitle(),
    'Tag': new Tag('t'),
    'Text': new Text(null, null),
    'Thumbnail': new Thumbnail(null),
    'Time': new Time(0),
    'UrlReference': new UrlReference('http://x/a')
  };
  const instance = instances[name];
  return instance === undefined ? 'no instance' : jsonKeys(instance);
}

export default function mediarssTest() {
  describe('Mediarss', () => {
    // Ported from ROME's TimeTest.testToString.
    it('timeToStringParsesBack', 0, () => {
      const t = Time.parse('12:05:35.3');
      expect(Time.parse(t.toString()).toString()).assertEqual(t.toString());
      expect(Time.parse('3:54.00001').toString()).assertEqual('00:03:54.0');
    });

    it('timeParseMatchesRome', 0, () => {
      const cases = TIME_PARSE.map((c: string[]) => [c[0], expectedTimeParse(c[1])]);
      expect(sameCases(cases, (input: string) => run(() => timeParse(input)))).assertEqual('');
    });

    it('timeToStringMatchesRome', 0, () => {
      expect(sameCases(TIME_TO_STRING, (ms: string) => new Time(Number(ms)).toString())).assertEqual('');
    });

    it('communityTagsKeepTreeSetOrder', 0, () => {
      expect(sameCases(TAG_ORDER, tagOrder)).assertEqual('');
    });

    it('creditRoleIsLowercased', 0, () => {
      expect(sameCases(CREDIT_ROLES, (role: string) => String(new Credit(null, role, 'n').role))).assertEqual('');
    });

    it('serializedKeysMatchJavaBeanProperties', 0, () => {
      expect(sameCases(PROPERTIES, serializedKeys)).assertEqual('');
    });

    it('modelBehaviorMatchesRome', 0, () => {
      const actual = facts();
      expect(actual.map((f: string[]) => f[0]).join(' ')).assertEqual(FACTS.map((f: string[]) => f[0]).join(' '));
      expect(sameCases(FACTS, (key: string) => actual.find((f: string[]) => f[0] === key)![1])).assertEqual('');
    });
  });
}
