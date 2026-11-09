// Ported from ROME rome-modules/src/main/java/com/rometools/modules/opensearch/{OpenSearchModule,impl/OpenSearchModuleImpl}.java (Apache-2.0)
import { Module, ModuleImpl } from '../../feed/module/Module';
import { Link } from '../../feed/atom/Link';
import { OSQuery } from './entity/OSQuery';
import { OpenSearchResponse } from './OpenSearchResponse';

export class OpenSearchModule extends ModuleImpl implements OpenSearchResponse {
  static readonly URI: string = 'http://a9.com/-/spec/opensearch/1.1/';
  totalResults: number = -1;
  startIndex: number = 1;
  itemsPerPage: number = -1;
  link: Link | null = null;
  queries: OSQuery[] = [];

  constructor() {
    super(OpenSearchModule.URI);
  }

  addQuery(query: OSQuery): void {
    this.queries.push(query);
  }

  // ModuleImpl.clone is CloneableBean: link and queries are cloned.
  clone(): OpenSearchModule {
    const m = new OpenSearchModule();
    m.itemsPerPage = this.itemsPerPage;
    if (this.link !== null) {
      m.link = this.link.clone();
    }
    m.queries = this.queries.map((q: OSQuery) => q.clone());
    m.startIndex = this.startIndex;
    m.totalResults = this.totalResults;
    return m;
  }

  // Unlike clone, shares the link and appends clones of the queries.
  copyFrom(obj: Module): void {
    const osm = obj as OpenSearchModule;
    this.totalResults = osm.totalResults;
    this.itemsPerPage = osm.itemsPerPage;
    this.startIndex = osm.startIndex;
    this.link = osm.link;
    for (const q of osm.queries) {
      this.queries.push(q.clone());
    }
  }
}
