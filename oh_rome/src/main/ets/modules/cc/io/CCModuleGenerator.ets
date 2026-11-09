// Ported from ROME rome-modules/src/main/java/com/rometools/modules/cc/io/CCModuleGenerator.java (Apache-2.0)
import { Element, Namespace } from '../../../xml/Dom';
import { Module } from '../../../feed/module/Module';
import { ModuleGenerator } from '../../../io/ModuleGenerator';
import { CreativeCommons } from '../CreativeCommons';

const RSS1: Namespace = Namespace.getNamespace('cc', CreativeCommons.RSS1_URI);
const RSS2: Namespace = Namespace.getNamespace('creativeCommons', CreativeCommons.RSS2_URI);
const RSS: Namespace = Namespace.getNamespace('http://purl.org/rss/1.0/');
const RDF: Namespace = Namespace.getNamespace('rdf', 'http://www.w3.org/1999/02/22-rdf-syntax-ns#');

export class CCModuleGenerator implements ModuleGenerator {
  generate(module: Module, element: Element): void {
    let root = element;
    while (root.getParentElement() !== null) {
      root = root.getParentElement()!;
    }
    if (RDF.equals(root.getNamespace()) || RSS.equals(root.getNamespace())) {
      this.generateRSS1(module as CreativeCommons, element);
    } else {
      this.generateRSS2(module as CreativeCommons, element);
    }
  }

  getNamespaces(): Namespace[] {
    return [RSS1, RSS2, RDF];
  }

  getNamespaceUri(): string {
    return CreativeCommons.URI;
  }

  // As in ROME: the requires elements repeat the permits, and null license arrays throw.
  private generateRSS1(module: CreativeCommons, element: Element): void {
    if (element.getName() === 'channel') {
      for (const element2 of module.allLicenses!) {
        const license = new Element('License', RSS1);
        license.setAttribute('about', element2.value, RDF);
        const permits = element2.permits;
        for (let j = 0; permits !== null && j < permits.length; j++) {
          const permit = new Element('permits', RSS1);
          permit.setAttribute('resource', permits[j]!.toString(), RDF);
          license.addContent(permit);
        }
        const requires = element2.permits;
        for (let j = 0; requires !== null && j < requires.length; j++) {
          const permit = new Element('requires', RSS1);
          permit.setAttribute('resource', requires[j]!.toString(), RDF);
          license.addContent(permit);
        }
        element.getParentElement()!.addContent(license);
      }
    }
    for (const license2 of module.licenses!) {
      const license = new Element('license', RSS1);
      license.setAttribute('resource', license2.value, RDF);
      element.addContent(license);
    }
  }

  private generateRSS2(module: CreativeCommons, element: Element): void {
    const licenses = module.licenses;
    for (let i = 0; licenses !== null && i < licenses.length; i++) {
      const license = new Element('license', RSS2);
      license.setText(licenses[i].value);
      element.addContent(license);
    }
  }
}
