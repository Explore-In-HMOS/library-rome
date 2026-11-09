import { SECONDARY_TEXT, TEXT } from '../common/Theme';
import { ActionButton, CodeBox, ErrorBox, Note, PageFrame } from '../components/Widgets';
import { describeError, ErrorKind } from '../logic/Errors';
import { exportOpml, OutlineRow, outlineRows, parseOpml, subscriptionsOf } from '../logic/Opml';
import { PRESETS_OPML } from '../logic/Presets';
import { Store } from '../logic/Store';

@Component
export struct OpmlPage {
  @State rows: OutlineRow[] = [];
  @State heading: string = '';
  @State exported: string = '';
  @State check: string = '';
  @State errorHeading: string = '';
  @State errorMessage: string = '';

  aboutToAppear(): void {
    try {
      const opml = parseOpml(PRESETS_OPML);
      this.heading = `${opml.feedType}: "${opml.title ?? ''}", ${opml.outlines.length} top-level outlines`;
      this.rows = outlineRows(opml);
    } catch (e) {
      const error = describeError(ErrorKind.PARSE, e as Object);
      this.errorHeading = error.title;
      this.errorMessage = error.message;
    }
  }

  private export(): void {
    try {
      const subscriptions = Store.added.concat(subscriptionsOf(parseOpml(PRESETS_OPML)));
      this.exported = exportOpml('oh_rome demo export', subscriptions);
      const back = parseOpml(this.exported);
      this.check = `Read back as ${back.feedType}: ${back.outlines.length} outlines`;
      this.errorHeading = '';
    } catch (e) {
      const error = describeError(ErrorKind.CONVERT, e as Object);
      this.errorHeading = error.title;
      this.errorMessage = error.message;
    }
  }

  build() {
    PageFrame({ title: 'OPML' }) {
      Note({ text: `The Reader's preset list, read with the library's OPML parser. ${this.heading}` })
      if (this.errorHeading !== '') {
        ErrorBox({ heading: this.errorHeading, message: this.errorMessage })
      }
      ForEach(this.rows, (row: OutlineRow) => {
        Column({ space: 1 }) {
          Text(row.text).fontSize(row.url === null ? 14 : 13).fontColor(TEXT)
            .fontWeight(row.url === null ? FontWeight.Bold : FontWeight.Normal)
          if (row.url !== null) {
            Text(row.url).fontSize(11).fontColor(SECONDARY_TEXT).wordBreak(WordBreak.BREAK_ALL)
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding({ left: row.depth * 12, top: 4, bottom: 4 })
      }, (row: OutlineRow, index: number) => `${index}:${row.text}`)
      ActionButton({
        label: 'Export subscriptions as OPML 2.0',
        onTap: () => {
          this.export();
        }
      })
      if (this.check !== '') {
        Note({ text: this.check })
      }
      if (this.exported !== '') {
        CodeBox({ code: this.exported })
      }
    }
  }
}
