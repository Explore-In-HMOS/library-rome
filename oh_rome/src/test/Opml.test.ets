import { describe, expect, it } from '@ohos/hypium';
import { Opml } from '../main/ets/opml/feed/opml/Opml';
import { Outline } from '../main/ets/opml/feed/opml/Outline';
import { OPML20Generator } from '../main/ets/opml/io/impl/OPML20Generator';
import { assertGolden, fixture } from './golden/Golden';

const OPML_FIXTURES: string[] = ['opml/opml_1.0.xml', 'opml/opml_1.0_links.xml', 'opml/opml_2.0.xml'];

function categoryOf(categories: string[]): string | null {
  const outline = new Outline('outline1', null);
  outline.categories = categories;
  const opml = new Opml();
  opml.feedType = 'opml_2.0';
  opml.title = 'title';
  opml.outlines = [outline];
  const document = new OPML20Generator().generate(opml);
  return document.getRootElement().getChild('body')!.getChildren('outline')[0].getAttributeValue('category');
}

export default function opmlTest() {
  describe('Opml', () => {
    for (const id of OPML_FIXTURES) {
      for (const kind of fixture(id).kinds('opml')) {
        it(`golden_${id}_${kind}`.replace(/[^A-Za-z0-9]/g, '_'), 0, () => {
          assertGolden(id, 'opml', kind);
        });
      }
    }

    // OPML20GeneratorTest. testOutputOfNullCategory is not ported: categories is string[] and cannot hold null.
    it('outputOfEmptyCategory', 0, () => {
      expect(categoryOf([''])).assertNull();
    });

    it('outputOfBlankCategory', 0, () => {
      expect(categoryOf([' '])).assertNull();
    });

    it('outputOfOneCategory', 0, () => {
      expect(categoryOf(['category1'])).assertEqual('category1');
    });

    it('outputOfMultipleCategories', 0, () => {
      expect(categoryOf(['category1', 'category2'])).assertEqual('category1,category2');
    });
  });
}
