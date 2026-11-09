import { CODE_BACKGROUND, SECONDARY_TEXT, TEXT } from '../common/Theme';
import { ActionButton, ErrorBox, Note, PageFrame } from '../components/Widgets';
import { describeError, ErrorKind } from '../logic/Errors';
import { FeedSource, parseSource } from '../logic/Source';
import { Store } from '../logic/Store';

@Component
export struct PastePage {
  @Consume('stack') stack: NavPathStack;
  @State xml: string = '';
  @State errorHeading: string = '';
  @State errorMessage: string = '';

  private parse(): void {
    const source = FeedSource.ofText('Pasted XML', this.xml);
    try {
      Store.open(source, parseSource(source));
      this.errorHeading = '';
      this.stack.pushPathByName('feed', null);
    } catch (e) {
      const error = describeError(ErrorKind.PARSE, e as Object);
      this.errorHeading = error.title;
      this.errorMessage = error.message;
    }
  }

  build() {
    PageFrame({ title: 'Paste XML' }) {
      Note({ text: 'Paste a whole RSS, Atom or OPML document. Text is parsed as is: only bytes go through the encoding detection.' })
      TextArea({ placeholder: '<rss version="2.0">…', text: this.xml })
        .height(160)
        .fontSize(12)
        .fontColor(TEXT)
        .placeholderColor(SECONDARY_TEXT)
        .backgroundColor(CODE_BACKGROUND)
        .onChange((value: string) => {
          this.xml = value;
        })
      ActionButton({
        label: 'Parse',
        active: this.xml.trim() !== '',
        onTap: () => {
          this.parse();
        }
      })
      if (this.errorHeading !== '') {
        ErrorBox({ heading: this.errorHeading, message: this.errorMessage })
      }
    }
  }
}
