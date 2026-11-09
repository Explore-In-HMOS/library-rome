import { CODE_BACKGROUND, SECONDARY_TEXT, TEXT } from '../common/Theme';
import { ActionButton, Chips, CodeBox, ErrorBox, Note, PageFrame } from '../components/Widgets';
import { generateFeed, outputTypes, readBack } from '../logic/Convert';

@Component
export struct GeneratePage {
  @State selected: string = 'rss_2.0';
  @State title: string = 'My demo feed';
  @State entryTitle: string = 'Hello from HarmonyOS';
  @State xml: string = '';
  @State check: string = '';
  @State errorHeading: string = '';
  @State errorMessage: string = '';
  private types: string[] = outputTypes();

  private generate(): void {
    const result = generateFeed(this.selected, this.title, this.entryTitle, new Date());
    this.xml = result.xml ?? '';
    this.check = result.xml === null ? '' : readBack(result.xml);
    this.errorHeading = result.error === null ? '' : result.error.title;
    this.errorMessage = result.error === null ? '' : result.error.message;
  }

  build() {
    PageFrame({ title: 'Generate' }) {
      Chips({
        options: this.types,
        selected: this.selected,
        onPick: (feedType: string) => {
          this.selected = feedType;
        }
      })
      Note({ text: 'Feed title' })
      TextInput({ text: this.title })
        .fontSize(13)
        .fontColor(TEXT)
        .placeholderColor(SECONDARY_TEXT)
        .backgroundColor(CODE_BACKGROUND)
        .onChange((value: string) => {
          this.title = value;
        })
      Note({ text: 'First entry title' })
      TextInput({ text: this.entryTitle })
        .fontSize(13)
        .fontColor(TEXT)
        .placeholderColor(SECONDARY_TEXT)
        .backgroundColor(CODE_BACKGROUND)
        .onChange((value: string) => {
          this.entryTitle = value;
        })
      ActionButton({
        label: `Generate ${this.selected}`,
        onTap: () => {
          this.generate();
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
