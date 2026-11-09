// Ported from ROME rome-modules/src/main/java/com/rometools/modules/opensearch/OpenSearchResponse.java (Apache-2.0)
import { Link } from '../../feed/atom/Link';
import { OSQuery } from './entity/OSQuery';

export interface OpenSearchResponse {
  totalResults: number;
  startIndex: number;
  itemsPerPage: number;
  link: Link | null;
  queries: OSQuery[];

  addQuery(query: OSQuery): void;
}
