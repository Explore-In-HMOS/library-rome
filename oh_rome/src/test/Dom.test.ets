import { describe, it, expect } from '@ohos/hypium';
import { CDATA, Comment, Document, DocType, Element, Namespace, ProcessingInstruction, Text } from '../main/ets/xml/Dom';

const ATOM: Namespace = Namespace.getNamespace('http://www.w3.org/2005/Atom');
const DC: Namespace = Namespace.getNamespace('dc', 'http://purl.org/dc/elements/1.1/');

export default function domTest() {
  describe('Dom', () => {
    it('namespacesAreEqualByUriOnly', 0, () => {
      expect(Namespace.getNamespace('a', 'urn:x').equals(Namespace.getNamespace('b', 'urn:x'))).assertTrue();
      expect(Namespace.getNamespace('a', 'urn:x').equals(Namespace.getNamespace('a', 'urn:y'))).assertFalse();
      expect(Namespace.getNamespace('') === Namespace.NO_NAMESPACE).assertTrue();
    });

    it('getChildWithoutNamespaceMatchesOnlyNoNamespace', 0, () => {
      const root = new Element('feed', ATOM);
      root.addContent(new Element('title', ATOM).setText('atom title'));
      root.addContent(new Element('title').setText('plain title'));
      expect(root.getChild('title')!.getText()).assertEqual('plain title');
      expect(root.getChild('title', ATOM)!.getText()).assertEqual('atom title');
      expect(root.getChild('missing')).assertNull();
      expect(root.getChildText('title', ATOM)).assertEqual('atom title');
      expect(root.getChildText('missing')).assertNull();
    });

    it('getChildrenVariants', 0, () => {
      const root = new Element('channel');
      root.addContent(new Element('item'));
      root.addContent(new Element('item'));
      root.addContent(new Element('creator', DC));
      root.addContent('text');
      expect(root.getChildren().length).assertEqual(3);
      expect(root.getChildren('item').length).assertEqual(2);
      expect(root.getChildren('creator').length).assertEqual(0);
      expect(root.getChildren('creator', DC).length).assertEqual(1);
    });

    it('textValueAndJavaTrim', 0, () => {
      const e = new Element('description');
      e.addContent('  a ');
      e.addContent(new Element('b').setText('nested'));
      e.addContent(new CDATA('c '));
      e.addContent(new Comment('ignored'));
      expect(e.getText()).assertEqual('  a c ');
      expect(e.getValue()).assertEqual('  a nestedc ');
      expect(e.getTextTrim()).assertEqual('a c ');
    });

    it('attributes', 0, () => {
      const e = new Element('enclosure');
      e.setAttribute('url', 'http://a');
      e.setAttribute('url', 'http://b');
      e.setAttribute('about', 'x', Namespace.getNamespace('rdf', 'http://www.w3.org/1999/02/22-rdf-syntax-ns#'));
      expect(e.getAttributes().length).assertEqual(2);
      expect(e.getAttributeValue('url')).assertEqual('http://b');
      expect(e.getAttributeValue('about')).assertNull();
      expect(e.getAttributeValue('about', Namespace.getNamespace('http://www.w3.org/1999/02/22-rdf-syntax-ns#')))
        .assertEqual('x');
      const url = e.getAttribute('url')!;
      expect(url.getParent() === e).assertTrue();
      expect(e.removeAttribute('url')).assertTrue();
      expect(e.hasAttributes()).assertTrue();
    });

    it('contentHasSingleParent', 0, () => {
      const a = new Element('a');
      const b = new Element('b');
      const child = new Element('child');
      a.addContent(child);
      let threw = false;
      try {
        b.addContent(child);
      } catch (e) {
        threw = true;
      }
      expect(threw).assertTrue();
      child.detach();
      b.addContent(child);
      expect(child.getParentElement() === b).assertTrue();
      expect(a.getContentSize()).assertEqual(0);
    });

    it('cloneIsDeepAndDetached', 0, () => {
      const root = new Element('root');
      const item = new Element('item');
      item.setAttribute('id', '1');
      item.addContent(new Element('title').setText('t'));
      root.addContent(item);
      const copy = item.clone();
      expect(copy.getParent()).assertNull();
      copy.getChild('title')!.setText('changed');
      copy.setAttribute('id', '2');
      expect(item.getChildText('title')).assertEqual('t');
      expect(item.getAttributeValue('id')).assertEqual('1');
    });

    it('namespaceResolvesThroughParents', 0, () => {
      const root = new Element('rss');
      root.addNamespaceDeclaration(DC);
      const channel = new Element('channel');
      root.addContent(channel);
      expect(channel.getNamespace('dc')!.getURI()).assertEqual(DC.getURI());
      expect(channel.getNamespace('xml')!.getURI()).assertEqual(Namespace.XML_NAMESPACE.getURI());
      expect(channel.getNamespace('nope')).assertNull();
      expect(new Element('creator', DC).getQualifiedName()).assertEqual('dc:creator');
    });

    it('removeContent', 0, () => {
      const e = new Element('e');
      const t = new Text('x');
      e.addContent(t);
      e.addContent(new Element('y'));
      expect(e.removeContent(new Text('other')).length).assertEqual(0);
      expect(e.removeContent(t).length).assertEqual(1);
      expect(t.getParent()).assertNull();
      expect(e.removeContent().length).assertEqual(1);
      expect(e.getContentSize()).assertEqual(0);
    });

    it('documentPutsANewDocTypeFirst', 0, () => {
      const doc = new Document(new Element('rss'));
      doc.addContentAt(0, new ProcessingInstruction('xml-stylesheet', 'type="text/xsl" href=\'style.xsl\''));
      doc.setDocType(new DocType('rss', '-//Netscape Communications//DTD RSS 0.91//EN', 'http://my.netscape.com/publish/formats/rss-0.91.dtd'));
      const content = doc.getContent();
      expect(content.length).assertEqual(3);
      expect(content[0] instanceof DocType).assertTrue();
      expect(content[1] instanceof ProcessingInstruction).assertTrue();
      expect(doc.getRootElement().getName()).assertEqual('rss');
      expect(doc.getDocType()!.getPublicID()).assertEqual('-//Netscape Communications//DTD RSS 0.91//EN');
      doc.setRootElement(new Element('feed'));
      expect(doc.getContent().length).assertEqual(3);
      expect(doc.getRootElement().getName()).assertEqual('feed');
    });

    it('processingInstructionPseudoAttributes', 0, () => {
      const pi = new ProcessingInstruction('xml-stylesheet', 'type="text/xsl" href=\'style.xsl\'');
      expect(pi.getPseudoAttributeValue('type')).assertEqual('text/xsl');
      expect(pi.getPseudoAttributeValue('href')).assertEqual('style.xsl');
      expect(pi.getPseudoAttributeValue('media')).assertNull();
    });
  });
}
