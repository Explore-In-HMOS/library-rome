// Ported from ROME rome-modules/src/main/java/com/rometools/modules/opensearch/entity/OSQuery.java (Apache-2.0)

export class OSQuery {
  role: string | null = null;
  startPage: number = -1;
  totalResults: number = -1;
  osd: string | null = null;
  title: string | null = null;
  searchTerms: string | null = null;

  // CloneableBean: properties that are null in the source keep the new instance's value.
  clone(): OSQuery {
    const q = new OSQuery();
    if (this.osd !== null) {
      q.osd = this.osd;
    }
    if (this.role !== null) {
      q.role = this.role;
    }
    if (this.searchTerms !== null) {
      q.searchTerms = this.searchTerms;
    }
    q.startPage = this.startPage;
    if (this.title !== null) {
      q.title = this.title;
    }
    q.totalResults = this.totalResults;
    return q;
  }
}
