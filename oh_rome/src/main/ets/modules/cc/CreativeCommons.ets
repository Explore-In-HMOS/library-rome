// Ported from ROME rome-modules/src/main/java/com/rometools/modules/cc/{CreativeCommons,CreativeCommonsImpl}.java (Apache-2.0)
import { Module, ModuleImpl } from '../../feed/module/Module';
import { License } from './types/License';

export class CreativeCommons extends ModuleImpl {
  static readonly URI: string = 'rome:CreativeCommons';
  static readonly RDF_URI: string = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#';
  static readonly RSS2_URI: string = 'http://backend.userland.com/creativeCommonsRssModule';
  static readonly RSS1_URI: string = 'http://web.resource.org/cc/';
  allLicenses: License[] | null = null;
  licenses: License[] | null = null;

  constructor() {
    super(CreativeCommons.URI);
  }

  clone(): CreativeCommons {
    const clone = new CreativeCommons();
    clone.copyFrom(this);
    return clone;
  }

  // A new allLicenses array; licenses is shared.
  copyFrom(obj: Module): void {
    const source = obj as CreativeCommons;
    this.allLicenses = source.allLicenses === null ? null : source.allLicenses.slice();
    this.licenses = source.licenses;
  }
}
