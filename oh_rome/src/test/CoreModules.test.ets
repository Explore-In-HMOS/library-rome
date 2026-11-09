import { afterAll, beforeAll, describe, expect, it } from '@ohos/hypium';
import { Element, Namespace } from '../main/ets/xml/Dom';
import { DCModule, DCSubject } from '../main/ets/feed/module/DCModule';
import { SyModule } from '../main/ets/feed/module/SyModule';
import { ModuleGenerator } from '../main/ets/io/ModuleGenerator';
import { ModuleParser } from '../main/ets/io/ModuleParser';
import { DateParser } from '../main/ets/io/impl/DateParser';
import { DCModuleGenerator } from '../main/ets/io/impl/DCModuleGenerator';
import { DCModuleParser } from '../main/ets/io/impl/DCModuleParser';
import { registerCorePlugins } from '../main/ets/io/impl/DefaultPlugins';
import { PluginRegistry } from '../main/ets/io/impl/PluginRegistry';
import { SyModuleGenerator } from '../main/ets/io/impl/SyModuleGenerator';
import { SyModuleParser } from '../main/ets/io/impl/SyModuleParser';

const DC_NS: Namespace = Namespace.getNamespace('dc', DCModule.URI);
const SY_NS: Namespace = Namespace.getNamespace('sy', SyModule.URI);
const RDF_NS: Namespace = Namespace.getNamespace('rdf', 'http://www.w3.org/1999/02/22-rdf-syntax-ns#');
const TAXO_NS: Namespace = Namespace.getNamespace('taxo', 'http://purl.org/rss/1.0/modules/taxonomy/');

function child(parent: Element, name: string, ns: Namespace, text: string): Element {
  const e = new Element(name, ns);
  e.setText(text);
  parent.addContent(e);
  return e;
}

function describeChildren(element: Element): string {
  return element.getChildren().map((e: Element) => e.getNamespacePrefix() + ':' + e.getName() + '=' + e.getText())
    .join('|');
}

function parserKinds(list: ModuleParser[]): string {
  return list.map((p: ModuleParser) =>
    (p instanceof SyModuleParser ? 'Sy' : (p instanceof DCModuleParser ? 'DC' : '?'))).join(',');
}

function generatorKinds(list: ModuleGenerator[]): string {
  return list.map((g: ModuleGenerator) =>
    (g instanceof SyModuleGenerator ? 'Sy' : (g instanceof DCModuleGenerator ? 'DC' : '?'))).join(',');
}


function thrown(action: () => void): string {
  try {
    action();
  } catch (e) {
    const error = e as Error;
    return error.name === 'Error' ? error.message : `${error.name}: ${error.message}`;
  }
  return 'nothing thrown';
}

export default function coreModulesTest() {
  describe('CoreModules', () => {
    let previousTimeZone = DateParser.getDefaultTimeZone();

    beforeAll(() => {
      previousTimeZone = DateParser.getDefaultTimeZone();
      DateParser.setDefaultTimeZone('UTC');
    });

    afterAll(() => {
      DateParser.setDefaultTimeZone(previousTimeZone);
    });

    it('dcParserReadsEveryElementList', 0, () => {
      const root = new Element('item');
      child(root, 'title', DC_NS, 'T1');
      child(root, 'title', DC_NS, 'T2');
      child(root, 'title', Namespace.NO_NAMESPACE, 'not dc');
      child(root, 'creator', DC_NS, ' C ');
      child(root, 'date', DC_NS, '2005-07-19T17:00:42Z');
      child(root, 'date', DC_NS, 'Tue, 19 Jul 2005 17:00:42 GMT');
      child(root, 'rights', DC_NS, 'R');
      child(root, 'language', DC_NS, 'en');
      child(root, 'contributor', DC_NS, 'K');
      child(root, 'coverage', DC_NS, 'V');
      child(root, 'relation', DC_NS, 'L');
      child(root, 'source', DC_NS, 'S');
      child(root, 'identifier', DC_NS, 'I');
      child(root, 'format', DC_NS, 'F');
      child(root, 'type', DC_NS, 'Y');
      child(root, 'publisher', DC_NS, 'P');
      child(root, 'description', DC_NS, 'D');
      const dc = new DCModuleParser().parse(root) as DCModule;
      expect(dc.titles.join('|')).assertEqual('T1|T2');
      expect(dc.creators.join('|')).assertEqual(' C ');
      expect(dc.dates.length).assertEqual(2);
      expect(dc.dates[0].getTime()).assertEqual(1121792442000);
      expect(dc.dates[1].getTime()).assertEqual(1121792442000);
      expect(dc.rightsList.join('|')).assertEqual('R');
      expect([dc.language, dc.contributor, dc.coverage, dc.relation, dc.source, dc.identifier, dc.format, dc.type,
        dc.publisher, dc.description].join('|')).assertEqual('en|K|V|L|S|I|F|Y|P|D');
      expect(dc.subjects.length).assertEqual(0);
    });

    it('dcParserReadsSubjectsAndTaxonomies', 0, () => {
      const root = new Element('item');
      child(root, 'subject', DC_NS, 'plain');
      const subject = new Element('subject', DC_NS);
      const description = new Element('Description', RDF_NS);
      const topic = new Element('topic', TAXO_NS);
      topic.setAttribute('resource', 'http://tax/1', RDF_NS);
      description.addContent(topic);
      child(description, 'value', RDF_NS, 'v1');
      child(description, 'value', RDF_NS, 'v2');
      subject.addContent(description);
      root.addContent(subject);
      const dc = new DCModuleParser().parse(root) as DCModule;
      expect(dc.subjects.map((s: DCSubject) => s.taxonomyUri + '=' + s.value).join('|'))
        .assertEqual('null=plain|http://tax/1=v1|http://tax/1=v2');
    });

    it('dcParserReturnsNullWithoutDcElements', 0, () => {
      const root = new Element('item');
      child(root, 'title', Namespace.NO_NAMESPACE, 'x');
      expect(new DCModuleParser().parse(root)).assertNull();
    });

    it('dcGeneratorWritesRomeOrder', 0, () => {
      const dc = new DCModule();
      dc.rightsList = ['R'];
      dc.titles = ['T1', 'T2'];
      dc.dates = [new Date(1121792442000), new Date(0)];
      const subject = new DCSubject();
      subject.value = 'plain';
      dc.subjects = [subject];
      dc.creator = 'C';
      const element = new Element('item');
      new DCModuleGenerator().generate(dc, element);
      expect(describeChildren(element)).assertEqual(
        'dc:title=T1|dc:title=T2|dc:creator=C|dc:subject=plain|dc:date=2005-07-19T17:00:42Z|' +
          'dc:date=1970-01-01T00:00:00Z|dc:rights=R');
      expect(new DCModuleGenerator().getNamespaces().map((n: Namespace) => n.getPrefix()).join(','))
        .assertEqual('dc,rdf,taxo');
    });

    it('dcGeneratorWritesTaxonomySubjects', 0, () => {
      const dc = new DCModule();
      const subject = new DCSubject();
      subject.taxonomyUri = 'http://tax/1';
      subject.value = 'v';
      dc.subjects = [subject, new DCSubject()];
      const element = new Element('item');
      new DCModuleGenerator().generate(dc, element);
      const subjects = element.getChildren('subject', DC_NS);
      expect(subjects.length).assertEqual(2);
      const description = subjects[0].getChild('Description', RDF_NS)!;
      expect(description.getChild('topic', TAXO_NS)!.getAttributeValue('resource', RDF_NS)).assertEqual('http://tax/1');
      expect(description.getChildText('value', RDF_NS)).assertEqual('v');
      expect(subjects[1].getContentSize()).assertEqual(1);
      expect(subjects[1].getText()).assertEqual('');
    });

    it('dcRoundTrip', 0, () => {
      const dc = new DCModule();
      dc.titles = ['a', 'b'];
      dc.date = new Date(1121792442000);
      dc.languages = ['en'];
      const element = new Element('item');
      new DCModuleGenerator().generate(dc, element);
      const parsed = new DCModuleParser().parse(element) as DCModule;
      expect(parsed.titles.join('|')).assertEqual('a|b');
      expect(parsed.date!.getTime()).assertEqual(1121792442000);
      expect(parsed.language).assertEqual('en');
    });

    it('syParserReadsAllFields', 0, () => {
      const root = new Element('channel');
      child(root, 'updatePeriod', SY_NS, ' daily\n');
      child(root, 'updateFrequency', SY_NS, ' 2 ');
      child(root, 'updateBase', SY_NS, '2000-01-01T12:00+00:00');
      const sy = new SyModuleParser().parse(root) as SyModule;
      expect(sy.updatePeriod).assertEqual(SyModule.DAILY);
      expect(sy.updateFrequency).assertEqual(2);
      expect(sy.updateBase!.getTime()).assertEqual(Date.UTC(2000, 0, 1, 12, 0, 0));
    });

    it('syParserFailsLikeRome', 0, () => {
      const root = new Element('channel');
      expect(new SyModuleParser().parse(root)).assertNull();
      child(root, 'updatePeriod', SY_NS, 'often');
      expect(thrown(() => new SyModuleParser().parse(root))).assertEqual('IllegalArgumentException: Invalid period [often]');
      const other = new Element('channel');
      child(other, 'updateFrequency', SY_NS, '1.5');
      expect(thrown(() => new SyModuleParser().parse(other))).assertEqual('NumberFormatException: For input string: "1.5"');
    });

    it('syGeneratorWritesRomeOrder', 0, () => {
      const sy = new SyModule();
      const empty = new Element('channel');
      new SyModuleGenerator().generate(sy, empty);
      expect(describeChildren(empty)).assertEqual('sy:updateFrequency=0');
      sy.updatePeriod = SyModule.HOURLY;
      sy.updateFrequency = 3;
      sy.updateBase = new Date(946728000000);
      const element = new Element('channel');
      new SyModuleGenerator().generate(sy, element);
      expect(describeChildren(element))
        .assertEqual('sy:updatePeriod=hourly|sy:updateFrequency=3|sy:updateBase=2000-01-01T12:00:00Z');
    });

    it('syModuleCloneCopiesValues', 0, () => {
      const sy = new SyModule();
      sy.updatePeriod = SyModule.WEEKLY;
      sy.updateFrequency = 7;
      sy.updateBase = new Date(5);
      const copy = sy.clone();
      sy.updateBase.setTime(6);
      expect(copy.updatePeriod).assertEqual('weekly');
      expect(copy.updateFrequency).assertEqual(7);
      expect(copy.updateBase!.getTime()).assertEqual(5);
      expect(copy.uri).assertEqual(SyModule.URI);
    });

    // SyModuleImpl.copyFrom on Temurin 17.0.17+10: null source properties leave the target's value.
    it('syModuleCopyFromSkipsNullSourceValues', 0, () => {
      const target = new SyModule();
      target.updatePeriod = SyModule.DAILY;
      target.updateFrequency = 5;
      target.updateBase = new Date(5);
      target.copyFrom(new SyModule());
      expect(target.updatePeriod).assertEqual('daily');
      expect(target.updateFrequency).assertEqual(0);
      expect(target.updateBase!.getTime()).assertEqual(5);
    });

    it('registersCoreModulesInRomePropertiesOrder', 0, () => {
      const registry = new PluginRegistry();
      registerCorePlugins(registry);
      for (const feedType of ['rss_1.0', 'atom_0.3', 'atom_1.0']) {
        expect(parserKinds(registry.getModuleParsers(feedType + '.feed'))).assertEqual('Sy,DC');
        expect(parserKinds(registry.getModuleParsers(feedType + '.item'))).assertEqual('DC');
        expect(generatorKinds(registry.getModuleGenerators(feedType + '.feed'))).assertEqual('Sy,DC');
        expect(generatorKinds(registry.getModuleGenerators(feedType + '.item'))).assertEqual('DC');
      }
      for (const scope of ['rss_2.0.feed', 'rss_2.0.item', 'rss_2.0wNS.feed', 'rss_2.0wNS.item']) {
        expect(parserKinds(registry.getModuleParsers(scope))).assertEqual('DC');
      }
      expect(generatorKinds(registry.getModuleGenerators('rss_2.0.feed'))).assertEqual('DC');
      expect(generatorKinds(registry.getModuleGenerators('rss_2.0.item'))).assertEqual('DC');
      expect(registry.getModuleGenerators('rss_2.0wNS.feed').length).assertEqual(0);
      expect(registry.getModuleParsers('rss_0.91U.item').length).assertEqual(0);
    });
  });
}
