import { describe, it, expect } from '@ohos/hypium';
import { Content } from '../main/ets/feed/atom/Content';
import { Channel } from '../main/ets/feed/rss/Channel';
import { SyndFeed } from '../main/ets/feed/synd/SyndFeed';
import { IllegalArgumentException, NumberFormatException } from '../main/ets/utils/Exceptions';
import { BigDecimal, currencyInstance } from '../main/ets/utils/JavaMath';
import { Comment, Document, Element, ProcessingInstruction, Text } from '../main/ets/xml/Dom';
import { Format } from '../main/ets/xml/Format';
import {
  IllegalAddException, IllegalDataException, IllegalNameException, IllegalTargetException
} from '../main/ets/xml/Verifier';

function thrown(run: () => void): Error {
  try {
    run();
  } catch (e) {
    return e as Error;
  }
  return new Error('no error');
}

export default function exceptionsTest() {
  describe('Exceptions', () => {
    it('subclassesKeepInstanceofAndName', 0, () => {
      const errors: Error[] = [new IllegalArgumentException('m'), new NumberFormatException('m'),
        new IllegalNameException('n', 'element', 'r'), new IllegalDataException('d', 'comment', 'r'),
        new IllegalTargetException('t', 'r'), new IllegalAddException('m')];
      expect(errors.map((e: Error) => e.name).join(',')).assertEqual('IllegalArgumentException,NumberFormatException,' +
        'IllegalNameException,IllegalDataException,IllegalTargetException,IllegalAddException');
      expect(errors.every((e: Error) => e instanceof Error && e instanceof IllegalArgumentException)).assertTrue();
      expect(errors[0].message).assertEqual('m');
      expect(errors[1] instanceof NumberFormatException).assertTrue();
      expect(errors[0] instanceof NumberFormatException).assertFalse();
      expect(errors[2] instanceof IllegalNameException).assertTrue();
      expect(errors[3] instanceof IllegalDataException).assertTrue();
      expect(errors[4] instanceof IllegalTargetException).assertTrue();
      expect(errors[5] instanceof IllegalAddException).assertTrue();
      expect(errors[2] instanceof IllegalDataException || errors[3] instanceof IllegalNameException).assertFalse();
      expect(new Error('m') instanceof IllegalArgumentException).assertFalse();
    });

    it('romeSitesThrowIllegalArgumentException', 0, () => {
      const hour = thrown(() => { new Channel('rss_2.0').skipHours = [25]; });
      expect(hour instanceof IllegalArgumentException).assertTrue();
      expect(`${hour.name}: ${hour.message}`).assertEqual('IllegalArgumentException: Invalid hour [25]');
      expect(thrown(() => { new Channel('rss_2.0').skipDays = ['funday']; }).name)
        .assertEqual('IllegalArgumentException');
      expect(thrown(() => { new Content().mode = 'XML'; }).name).assertEqual('IllegalArgumentException');
      expect(thrown(() => { new SyndFeed().createWireFeed('rss_9.9'); }).name).assertEqual('IllegalArgumentException');
      expect(thrown(() => { new SyndFeed().createWireFeed(); }).name).assertEqual('IllegalArgumentException');
    });

    it('jdkSitesThrowTheJdkClass', 0, () => {
      expect(thrown(() => { BigDecimal.parse('x'); }) instanceof NumberFormatException).assertTrue();
      expect(thrown(() => { currencyInstance('ab'); }).name).assertEqual('IllegalArgumentException');
    });

    it('domSitesThrowTheJdomClass', 0, () => {
      expect(thrown(() => { new Element('1a'); }).name).assertEqual('IllegalNameException');
      expect(thrown(() => { new Text('\u0000'); }).name).assertEqual('IllegalDataException');
      expect(thrown(() => { new ProcessingInstruction('xml', ''); }).name).assertEqual('IllegalTargetException');
      const strategy = Format.getRawFormat().getEscapeStrategy();
      const truncated = thrown(() => { Format.escapeText(strategy, null, 'a\ud83d'); });
      expect(`${truncated.name}: ${truncated.message}`)
        .assertEqual('IllegalDataException: Surrogate pair 0xd83dtruncated');
      expect(thrown(() => { Format.escapeAttribute(strategy, '\ud83dx'); }).name).assertEqual('IllegalDataException');
      const child = new Element('c');
      new Element('a').addContent(child);
      expect(thrown(() => { new Element('b').addContent(child); }).name).assertEqual('IllegalAddException');
      const comment = new Comment('c');
      new Document().addContent(comment);
      const cast = thrown(() => { new Element('b').addContent(comment); });
      expect(`${cast.name}: ${cast.message}`).assertEqual('Error: class org.jdom2.Comment cannot be cast to class ' +
        'org.jdom2.Element (org.jdom2.Comment and org.jdom2.Element are in unnamed module of loader \'app\')');
    });
  });
}
