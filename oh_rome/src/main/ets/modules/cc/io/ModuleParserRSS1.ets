// Ported from ROME rome-modules/src/main/java/com/rometools/modules/cc/io/ModuleParserRSS1.java (Apache-2.0)
import { Element, Namespace } from '../../../xml/Dom';
import { Module } from '../../../feed/module/Module';
import { ModuleParser } from '../../../io/ModuleParser';
import { CreativeCommons } from '../CreativeCommons';
import { findBehaviourByValue, License, LicenseBehaviour } from '../types/License';

const NS: Namespace = Namespace.getNamespace(CreativeCommons.RSS1_URI);
const RDF: Namespace = Namespace.getNamespace(CreativeCommons.RDF_URI);

function behaviours(licenseTag: Element, name: string): (LicenseBehaviour | null)[] {
  return licenseTag.getChildren(name, NS).map((tag: Element) => findBehaviourByValue(tag.getAttributeValue('resource', RDF)));
}

export class ModuleParserRSS1 implements ModuleParser {
  // A cc:license without rdf:resource throws, as ROME's NullPointerException does.
  parse(element: Element): Module | null {
    const module = new CreativeCommons();
    let root = element;
    while (root.getParentElement() !== null) {
      root = root.getParentElement()!;
    }
    const allLicenses: License[] = [];
    for (const licenseTag of root.getChildren('License', NS)) {
      const licenseURI = licenseTag.getAttributeValue('about', RDF);
      if (licenseURI === null) {
        continue;
      }
      License.findByValue(licenseURI);
      const permits = behaviours(licenseTag, 'permits');
      const requires = behaviours(licenseTag, 'requires');
      allLicenses.push(new License(licenseURI, requires, permits));
    }
    module.allLicenses = allLicenses;

    const licenses = element.getChildren('license', NS)
      .map((tag: Element) => License.findByValue(tag.getAttributeValue('resource', RDF)!));
    if (licenses.length > 0) {
      module.licenses = licenses;
    }
    return module;
  }

  getNamespaceUri(): string {
    return CreativeCommons.RSS1_URI;
  }
}
