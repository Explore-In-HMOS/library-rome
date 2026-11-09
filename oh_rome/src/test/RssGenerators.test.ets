import { describe, expect, it } from '@ohos/hypium';
import { Format } from '../main/ets/xml/Format';
import { XMLOutputter } from '../main/ets/xml/XmlOutputter';
import { parseXml } from '../main/ets/xml/XmlParser';
import { Channel } from '../main/ets/feed/rss/Channel';
import { Description } from '../main/ets/feed/rss/Description';
import { Item } from '../main/ets/feed/rss/Item';
import { TextInput } from '../main/ets/feed/rss/TextInput';
import { RSS091NetscapeGenerator } from '../main/ets/io/impl/RSS091NetscapeGenerator';
import { RSS091NetscapeParser } from '../main/ets/io/impl/RSS091NetscapeParser';
import { RSS091UserlandGenerator } from '../main/ets/io/impl/RSS091UserlandGenerator';
import { assertGolden, fixture } from './golden/Golden';
import { FIXTURES } from './RssParsers.test';

// The golden rss_0.91N fixture fails to generate (language too long), so its DOCTYPE output is checked here. Expected
// output is ROME 6b4a7e8's WireFeedOutput.outputString for the same channel, on Temurin 17.0.17+10.
const NETSCAPE_XML: string = ['<?xml version="1.0" encoding="UTF-8"?>',
  '<!DOCTYPE rss PUBLIC "-//Netscape Communications//DTD RSS 0.91//EN" "http://my.netscape.com/publish/formats/rss-0.91.dtd">',
  '<rss version="0.91">', '  <channel>', '    <title>t</title>', '    <link>http://x/</link>',
  '    <description>d</description>', '    <language>en</language>',
  '    <pubDate>Thu, 01 Jan 1970 00:00:00 GMT</pubDate>', '    <skipHours>', '      <hour>0</hour>',
  '      <hour>23</hour>', '    </skipHours>', '    <textinput>', '      <title>s</title>',
  '      <description>q</description>', '      <name>n</name>', '      <link>http://x/s</link>', '    </textinput>',
  '    <item>', '      <title>i</title>', '      <link>http://x/i</link>',
  '      <description>&lt;b&gt;x&lt;/b&gt;</description>', '    </item>', '  </channel>', '</rss>', ''].join('\r\n');

function netscapeChannel(): Channel {
  const channel = new Channel('rss_0.91N');
  channel.title = 't';
  channel.link = 'http://x/';
  channel.description = 'd';
  channel.language = 'en';
  channel.pubDate = new Date(0);
  channel.skipHours = [0, 23];
  const textInput = new TextInput();
  textInput.title = 's';
  textInput.description = 'q';
  textInput.name = 'n';
  textInput.link = 'http://x/s';
  channel.textInput = textInput;
  const item = new Item();
  item.title = 'i';
  item.link = 'http://x/i';
  const description = new Description();
  description.value = '<b>x</b>';
  item.description = description;
  channel.items = [item];
  return channel;
}

export default function rssGeneratorsTest() {
  describe('RssGeneratorsGolden', () => {
    FIXTURES.forEach((id: string) => {
      it(`roundtrip.xml ${id}`, 0, () => {
        assertGolden(id, 'core', 'roundtrip.xml');
      });
    });

    // ROME has no roundtrip golden where generating failed (rss_0.91N, rss_0.91U, dublin-core-date).
    FIXTURES.filter((id: string) => fixture(id).has('core', 'roundtrip')).forEach((id: string) => {
      it(`roundtrip ${id}`, 0, () => {
        assertGolden(id, 'core', 'roundtrip');
      });
    });
  });

  describe('RssGenerators', () => {
    it('netscapeWritesDoctypeAndParsesBack', 0, () => {
      const xml = new XMLOutputter(Format.getPrettyFormat()).outputString(
        new RSS091NetscapeGenerator().generate(netscapeChannel()));
      expect(xml).assertEqual(NETSCAPE_XML);
      expect(new RSS091NetscapeParser().isMyType(parseXml(xml, true))).assertTrue();
    });

    it('userlandRejectsHourZero', 0, () => {
      let message = '';
      try {
        new RSS091UserlandGenerator().generate(netscapeChannel());
      } catch (e) {
        message = (e as Error).message;
      }
      expect(message).assertEqual('Invalid hour value 0, it must be between 1 and 24');
    });
  });
}
