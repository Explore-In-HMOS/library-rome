// Ported from ROME rome/src/main/java/com/rometools/rome/io/impl/DCModuleParser.java (Apache-2.0)
import { Element, Namespace } from '../../xml/Dom';
import { DCModule, DCSubject } from '../../feed/module/DCModule';
import { Module } from '../../feed/module/Module';
import { ModuleParser } from '../ModuleParser';
import { DateParser } from './DateParser';

const RDF_URI: string = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#';
const TAXO_URI: string = 'http://purl.org/rss/1.0/modules/taxonomy/';

const DC_NS: Namespace = Namespace.getNamespace(DCModule.URI);
const RDF_NS: Namespace = Namespace.getNamespace(RDF_URI);
const TAXO_NS: Namespace = Namespace.getNamespace(TAXO_URI);

export class DCModuleParser implements ModuleParser {
  getNamespaceUri(): string {
    return DCModule.URI;
  }

  parse(dcRoot: Element): Module | null {
    let foundSomething = false;
    const dcm = new DCModule();

    const titles = dcRoot.getChildren('title', DC_NS);
    if (titles.length > 0) {
      foundSomething = true;
      dcm.titles = this.parseElementList(titles);
    }

    const creators = dcRoot.getChildren('creator', DC_NS);
    if (creators.length > 0) {
      foundSomething = true;
      dcm.creators = this.parseElementList(creators);
    }

    const subjects = dcRoot.getChildren('subject', DC_NS);
    if (subjects.length > 0) {
      foundSomething = true;
      dcm.subjects = this.parseSubjects(subjects);
    }

    const descriptions = dcRoot.getChildren('description', DC_NS);
    if (descriptions.length > 0) {
      foundSomething = true;
      dcm.descriptions = this.parseElementList(descriptions);
    }

    const publishers = dcRoot.getChildren('publisher', DC_NS);
    if (publishers.length > 0) {
      foundSomething = true;
      dcm.publishers = this.parseElementList(publishers);
    }

    const contributors = dcRoot.getChildren('contributor', DC_NS);
    if (contributors.length > 0) {
      foundSomething = true;
      dcm.contributors = this.parseElementList(contributors);
    }

    const dates = dcRoot.getChildren('date', DC_NS);
    if (dates.length > 0) {
      foundSomething = true;
      dcm.dates = this.parseElementListDate(dates);
    }

    const types = dcRoot.getChildren('type', DC_NS);
    if (types.length > 0) {
      foundSomething = true;
      dcm.types = this.parseElementList(types);
    }

    const formats = dcRoot.getChildren('format', DC_NS);
    if (formats.length > 0) {
      foundSomething = true;
      dcm.formats = this.parseElementList(formats);
    }

    const identifiers = dcRoot.getChildren('identifier', DC_NS);
    if (identifiers.length > 0) {
      foundSomething = true;
      dcm.identifiers = this.parseElementList(identifiers);
    }

    const sources = dcRoot.getChildren('source', DC_NS);
    if (sources.length > 0) {
      foundSomething = true;
      dcm.sources = this.parseElementList(sources);
    }

    const languages = dcRoot.getChildren('language', DC_NS);
    if (languages.length > 0) {
      foundSomething = true;
      dcm.languages = this.parseElementList(languages);
    }

    const relations = dcRoot.getChildren('relation', DC_NS);
    if (relations.length > 0) {
      foundSomething = true;
      dcm.relations = this.parseElementList(relations);
    }

    const coverages = dcRoot.getChildren('coverage', DC_NS);
    if (coverages.length > 0) {
      foundSomething = true;
      dcm.coverages = this.parseElementList(coverages);
    }

    const rights = dcRoot.getChildren('rights', DC_NS);
    if (rights.length > 0) {
      foundSomething = true;
      dcm.rightsList = this.parseElementList(rights);
    }

    return foundSomething ? dcm : null;
  }

  protected getTaxonomy(desc: Element): string | null {
    const topic = desc.getChild('topic', TAXO_NS);
    if (topic !== null) {
      const resource = topic.getAttribute('resource', RDF_NS);
      if (resource !== null) {
        return resource.getValue();
      }
    }
    return null;
  }

  protected parseSubjects(eList: Element[]): DCSubject[] {
    const subjects: DCSubject[] = [];
    for (const eSubject of eList) {
      const description = eSubject.getChild('Description', RDF_NS);
      if (description !== null) {
        const taxonomy = this.getTaxonomy(description);
        for (const value of description.getChildren('value', RDF_NS)) {
          const subject = new DCSubject();
          subject.taxonomyUri = taxonomy;
          subject.value = value.getText();
          subjects.push(subject);
        }
      } else {
        const subject = new DCSubject();
        subject.value = eSubject.getText();
        subjects.push(subject);
      }
    }
    return subjects;
  }

  protected parseElementList(elements: Element[]): string[] {
    return elements.map((element: Element) => element.getText());
  }

  // ROME adds null for an unparseable date; DCModule.dates cannot hold null, so such dates are left out.
  protected parseElementListDate(elements: Element[]): Date[] {
    const values: Date[] = [];
    for (const element of elements) {
      const date = DateParser.parseDate(element.getText());
      if (date !== null) {
        values.push(date);
      }
    }
    return values;
  }
}
