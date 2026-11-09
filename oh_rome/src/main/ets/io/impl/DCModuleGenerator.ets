// Ported from ROME rome/src/main/java/com/rometools/rome/io/impl/DCModuleGenerator.java (Apache-2.0)
import { Attribute, Element, Namespace } from '../../xml/Dom';
import { DCModule, DCSubject } from '../../feed/module/DCModule';
import { Module } from '../../feed/module/Module';
import { ModuleGenerator } from '../ModuleGenerator';
import { DateParser } from './DateParser';

const DC_URI: string = 'http://purl.org/dc/elements/1.1/';
const TAXO_URI: string = 'http://purl.org/rss/1.0/modules/taxonomy/';
const RDF_URI: string = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#';

const DC_NS: Namespace = Namespace.getNamespace('dc', DC_URI);
const TAXO_NS: Namespace = Namespace.getNamespace('taxo', TAXO_URI);
const RDF_NS: Namespace = Namespace.getNamespace('rdf', RDF_URI);

export class DCModuleGenerator implements ModuleGenerator {
  getNamespaceUri(): string {
    return DC_URI;
  }

  // The iteration order of ROME's HashSet.
  getNamespaces(): Namespace[] {
    return [DC_NS, RDF_NS, TAXO_NS];
  }

  generate(module: Module, element: Element): void {
    const dcModule = module as DCModule;

    if (dcModule.title !== null) {
      element.addContent(this.generateSimpleElementList('title', dcModule.titles));
    }
    if (dcModule.creator !== null) {
      element.addContent(this.generateSimpleElementList('creator', dcModule.creators));
    }
    for (const dcSubject of dcModule.subjects) {
      element.addContent(this.generateSubjectElement(dcSubject));
    }
    if (dcModule.description !== null) {
      element.addContent(this.generateSimpleElementList('description', dcModule.descriptions));
    }
    if (dcModule.publisher !== null) {
      element.addContent(this.generateSimpleElementList('publisher', dcModule.publishers));
    }
    element.addContent(this.generateSimpleElementList('contributor', dcModule.contributors));
    if (dcModule.date !== null) {
      for (const date of dcModule.dates) {
        element.addContent(this.generateSimpleElement('date', DateParser.formatW3CDateTime(date)));
      }
    }
    if (dcModule.type !== null) {
      element.addContent(this.generateSimpleElementList('type', dcModule.types));
    }
    if (dcModule.format !== null) {
      element.addContent(this.generateSimpleElementList('format', dcModule.formats));
    }
    if (dcModule.identifier !== null) {
      element.addContent(this.generateSimpleElementList('identifier', dcModule.identifiers));
    }
    if (dcModule.source !== null) {
      element.addContent(this.generateSimpleElementList('source', dcModule.sources));
    }
    if (dcModule.language !== null) {
      element.addContent(this.generateSimpleElementList('language', dcModule.languages));
    }
    if (dcModule.relation !== null) {
      element.addContent(this.generateSimpleElementList('relation', dcModule.relations));
    }
    if (dcModule.coverage !== null) {
      element.addContent(this.generateSimpleElementList('coverage', dcModule.coverages));
    }
    if (dcModule.rights !== null) {
      element.addContent(this.generateSimpleElementList('rights', dcModule.rightsList));
    }
  }

  protected generateSubjectElement(subject: DCSubject): Element {
    const subjectElement = new Element('subject', DC_NS);
    const taxonomyUri = subject.taxonomyUri;
    const value = subject.value;
    if (taxonomyUri !== null) {
      const topicElement = new Element('topic', TAXO_NS);
      topicElement.setAttribute(new Attribute('resource', taxonomyUri, RDF_NS));
      const descriptionElement = new Element('Description', RDF_NS);
      descriptionElement.addContent(topicElement);
      if (value !== null) {
        const valueElement = new Element('value', RDF_NS);
        valueElement.addContent(value);
        descriptionElement.addContent(valueElement);
      }
      subjectElement.addContent(descriptionElement);
    } else {
      subjectElement.addContent(value ?? '');
    }
    return subjectElement;
  }

  protected generateSimpleElement(name: string, value: string): Element {
    const element = new Element(name, DC_NS);
    element.addContent(value);
    return element;
  }

  protected generateSimpleElementList(name: string, values: string[]): Element[] {
    return values.map((value: string) => this.generateSimpleElement(name, value));
  }
}
