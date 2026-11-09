// Ported from ROME rome/src/main/java/com/rometools/rome/feed/module/{DCModule,DCModuleImpl,DCSubject,DCSubjectImpl}.java (Apache-2.0)
import { Lists } from '../../utils/Lists';
import { Module, ModuleImpl } from './Module';

export class DCSubject {
  taxonomyUri: string | null = null;
  value: string | null = null;

  clone(): DCSubject {
    const copy = new DCSubject();
    copy.taxonomyUri = this.taxonomyUri;
    copy.value = this.value;
    return copy;
  }
}

// The plural lists hold the data; each singular property reads the first entry and writes a one-entry
// list. Java stores [null] when a singular setter gets null; here it stores [].
export class DCModule extends ModuleImpl {
  static readonly URI: string = 'http://purl.org/dc/elements/1.1/';
  titles: string[] = [];
  creators: string[] = [];
  subjects: DCSubject[] = [];
  descriptions: string[] = [];
  publishers: string[] = [];
  contributors: string[] = [];
  dates: Date[] = [];
  types: string[] = [];
  formats: string[] = [];
  identifiers: string[] = [];
  sources: string[] = [];
  languages: string[] = [];
  relations: string[] = [];
  coverages: string[] = [];
  rightsList: string[] = [];

  constructor() {
    super(DCModule.URI);
  }

  get title(): string | null {
    return Lists.firstEntry(this.titles);
  }

  set title(value: string | null) {
    this.titles = value === null ? [] : [value];
  }

  get creator(): string | null {
    return Lists.firstEntry(this.creators);
  }

  set creator(value: string | null) {
    this.creators = value === null ? [] : [value];
  }

  get subject(): DCSubject | null {
    return Lists.firstEntry(this.subjects);
  }

  set subject(value: DCSubject | null) {
    this.subjects = value === null ? [] : [value];
  }

  get description(): string | null {
    return Lists.firstEntry(this.descriptions);
  }

  set description(value: string | null) {
    this.descriptions = value === null ? [] : [value];
  }

  get publisher(): string | null {
    return Lists.firstEntry(this.publishers);
  }

  set publisher(value: string | null) {
    this.publishers = value === null ? [] : [value];
  }

  get contributor(): string | null {
    return Lists.firstEntry(this.contributors);
  }

  set contributor(value: string | null) {
    this.contributors = value === null ? [] : [value];
  }

  get date(): Date | null {
    return Lists.firstEntry(this.dates);
  }

  set date(value: Date | null) {
    this.dates = value === null ? [] : [value];
  }

  get type(): string | null {
    return Lists.firstEntry(this.types);
  }

  set type(value: string | null) {
    this.types = value === null ? [] : [value];
  }

  get format(): string | null {
    return Lists.firstEntry(this.formats);
  }

  set format(value: string | null) {
    this.formats = value === null ? [] : [value];
  }

  get identifier(): string | null {
    return Lists.firstEntry(this.identifiers);
  }

  set identifier(value: string | null) {
    this.identifiers = value === null ? [] : [value];
  }

  get source(): string | null {
    return Lists.firstEntry(this.sources);
  }

  set source(value: string | null) {
    this.sources = value === null ? [] : [value];
  }

  get language(): string | null {
    return Lists.firstEntry(this.languages);
  }

  set language(value: string | null) {
    this.languages = value === null ? [] : [value];
  }

  get relation(): string | null {
    return Lists.firstEntry(this.relations);
  }

  set relation(value: string | null) {
    this.relations = value === null ? [] : [value];
  }

  get coverage(): string | null {
    return Lists.firstEntry(this.coverages);
  }

  set coverage(value: string | null) {
    this.coverages = value === null ? [] : [value];
  }

  get rights(): string | null {
    return Lists.firstEntry(this.rightsList);
  }

  set rights(value: string | null) {
    this.rightsList = value === null ? [] : [value];
  }

  clone(): DCModule {
    const copy = new DCModule();
    copy.copyFrom(this);
    return copy;
  }

  copyFrom(obj: Module): void {
    const dc = obj as DCModule;
    this.titles = dc.titles.slice();
    this.creators = dc.creators.slice();
    this.subjects = dc.subjects.map((s: DCSubject) => s.clone());
    this.descriptions = dc.descriptions.slice();
    this.publishers = dc.publishers.slice();
    this.contributors = dc.contributors.slice();
    this.dates = dc.dates.map((d: Date) => new Date(d.getTime()));
    this.types = dc.types.slice();
    this.formats = dc.formats.slice();
    this.identifiers = dc.identifiers.slice();
    this.sources = dc.sources.slice();
    this.languages = dc.languages.slice();
    this.relations = dc.relations.slice();
    this.coverages = dc.coverages.slice();
    this.rightsList = dc.rightsList.slice();
  }
}
