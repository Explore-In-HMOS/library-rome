// Ported from ROME rome-modules/src/main/java/com/rometools/modules/itunes/{ITunes,AbstractITunesObject}.java (Apache-2.0)
import { ModuleImpl } from '../../feed/module/Module';

export abstract class ITunes extends ModuleImpl {
  static readonly URI: string = 'http://www.itunes.com/dtds/podcast-1.0.dtd';
  static readonly RDF_URI: string = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#';
  static readonly PREFIX: string = 'itunes';

  author: string | null = null;
  block: boolean = false;
  explicitNullable: boolean | null = null;
  // java.net.URL in ROME; holds its toString().
  image: string | null = null;
  imageUri: string | null = null;
  keywords: string[] = [];
  subtitle: string | null = null;
  summary: string | null = null;

  constructor() {
    super(ITunes.URI);
  }

  get explicit(): boolean {
    return this.explicitNullable ?? false;
  }

  set explicit(explicit: boolean) {
    this.explicitNullable = explicit;
  }
}
