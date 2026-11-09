import { Chips, CodeBox, ErrorBox, Note, PageFrame } from '../components/Widgets';
import { convertTo, outputTypes, readBack } from '../logic/Convert';
import { Store } from '../logic/Store';

@Component
export struct ConvertPage {
  @State selected: string = '';
  @State xml: string = '';
  @State check: string = '';
  @State errorHeading: string = '';
  @State errorMessage: string = '';
  private types: string[] = outputTypes();

  private convert(feedType: string): void {
    this.selected = feedType;
    const source = Store.source;
    if (source === null) {
      return;
    }
    const result = convertTo(source, feedType);
    this.xml = result.xml ?? '';
    this.check = result.xml === null ? '' : readBack(result.xml);
    this.errorHeading = result.error === null ? '' : result.error.title;
    this.errorMessage = result.error === null ? '' : result.error.message;
  }

  build() {
    PageFrame({ title: 'Convert' }) {
      Note({ text: `${Store.feed?.feedType ?? ''} to:` })
      Chips({
        options: this.types,
        selected: this.selected,
        onPick: (feedType: string) => {
          this.convert(feedType);
        }
      })
      if (this.errorHeading !== '') {
        ErrorBox({ heading: this.errorHeading, message: this.errorMessage })
      }
      if (this.check !== '') {
        Note({ text: this.check })
      }
      if (this.xml !== '') {
        CodeBox({ code: this.xml })
      }
    }
  }
}
