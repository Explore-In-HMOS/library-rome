import { LengthMetrics } from '@kit.ArkUI';
import {
  BACKGROUND, CHIP, CHIP_SELECTED, CODE_BACKGROUND, DIVIDER, END_PADDING, ERROR_TEXT, ROUND, SECONDARY_TEXT,
  SIDE_PADDING, TEXT
} from '../common/Theme';
import { DetailRow, Section } from '../logic/Describe';

// Long XML in one Text is slow to lay out on a watch; the rest is summarised.
const CODE_MAX_CHARS = 20000;

// Every page: its own header instead of the system title bar (whose colors follow the system theme, not ours), and
// one scrolling column inside the round-screen padding.
@Component
export struct PageFrame {
  @Consume('stack') stack: NavPathStack;
  title: string = '';
  @BuilderParam content: () => void;

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 8 }) {
          Row({ space: 8 }) {
            if (!ROUND) {
              Text('‹ Back')
                .fontSize(14)
                .fontColor(SECONDARY_TEXT)
                .onClick(() => {
                  this.stack.pop();
                })
            }
            Text(this.title)
              .fontSize(ROUND ? 16 : 20)
              .fontWeight(FontWeight.Bold)
              .fontColor(TEXT)
              .layoutWeight(1)
              .textAlign(ROUND ? TextAlign.Center : TextAlign.Start)
          }
          .width('100%')

          this.content()
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding({ left: SIDE_PADDING, right: SIDE_PADDING, top: END_PADDING, bottom: END_PADDING })
      }
      .width('100%')
      .height('100%')
      .align(Alignment.Top)
      .scrollBar(BarState.Off)
    }
    .hideTitleBar(true)
    .backgroundColor(BACKGROUND)
  }
}

@Component
export struct Tile {
  @Prop title: string = '';
  @Prop subtitle: string = '';
  onTap: () => void = () => {
  };

  build() {
    Column({ space: 2 }) {
      Text(this.title).fontSize(15).fontColor(TEXT)
      if (this.subtitle !== '') {
        Text(this.subtitle).fontSize(12).fontColor(SECONDARY_TEXT)
      }
      Divider().color(DIVIDER).strokeWidth(0.5).margin({ top: 8 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({ top: 8 })
    .onClick(() => {
      this.onTap();
    })
  }
}

@Component
export struct Chips {
  options: string[] = [];
  @Prop selected: string = '';
  onPick: (option: string) => void = () => {
  };

  build() {
    Flex({ wrap: FlexWrap.Wrap, space: { main: LengthMetrics.vp(6), cross: LengthMetrics.vp(6) } }) {
      ForEach(this.options, (option: string) => {
        Button(option)
          .fontSize(12)
          .height(28)
          .backgroundColor(option === this.selected ? CHIP_SELECTED : CHIP)
          .fontColor(TEXT)
          .fontWeight(option === this.selected ? FontWeight.Bold : FontWeight.Normal)
          .onClick(() => {
            this.onPick(option);
          })
      }, (option: string) => option)
    }
    .width('100%')
  }
}

@Component
export struct ActionButton {
  @Prop label: string = '';
  @Prop active: boolean = true;
  onTap: () => void = () => {
  };

  build() {
    Button(this.label)
      .fontSize(14)
      .height(36)
      .width('100%')
      .backgroundColor(this.active ? CHIP_SELECTED : CHIP)
      .fontColor(this.active ? TEXT : SECONDARY_TEXT)
      .enabled(this.active)
      .onClick(() => {
        this.onTap();
      })
  }
}

@Component
export struct ErrorBox {
  @Prop heading: string = '';
  @Prop message: string = '';

  build() {
    Column({ space: 4 }) {
      Text(this.heading).fontSize(14).fontWeight(FontWeight.Bold).fontColor(ERROR_TEXT)
      Text(this.message).fontSize(13).fontColor(TEXT).wordBreak(WordBreak.BREAK_WORD)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(10)
    .borderRadius(8)
    .backgroundColor(CODE_BACKGROUND)
  }
}

@Component
export struct Note {
  @Prop text: string = '';

  build() {
    Text(this.text).fontSize(12).fontColor(SECONDARY_TEXT).width('100%')
  }
}

@Component
export struct CodeBox {
  @Prop code: string = '';

  build() {
    Column({ space: 4 }) {
      if (this.code.length > CODE_MAX_CHARS) {
        Text(`Showing the first ${CODE_MAX_CHARS} of ${this.code.length} characters.`)
          .fontSize(11)
          .fontColor(SECONDARY_TEXT)
      }
      Text(this.code.length > CODE_MAX_CHARS ? this.code.substring(0, CODE_MAX_CHARS) : this.code)
        .fontSize(10)
        .fontFamily('monospace')
        .fontColor(TEXT)
        .wordBreak(WordBreak.BREAK_ALL)
        .copyOption(CopyOptions.LocalDevice)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(8)
    .borderRadius(8)
    .backgroundColor(CODE_BACKGROUND)
  }
}

@Component
export struct SectionView {
  section: Section = new Section('', []);

  build() {
    Column({ space: 6 }) {
      Text(this.section.title).fontSize(13).fontWeight(FontWeight.Bold).fontColor(SECONDARY_TEXT)
      ForEach(this.section.rows, (row: DetailRow) => {
        Column({ space: 1 }) {
          Text(row.label).fontSize(11).fontColor(SECONDARY_TEXT)
          Text(row.value).fontSize(14).fontColor(TEXT).wordBreak(WordBreak.BREAK_WORD)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }, (row: DetailRow, index: number) => `${index}:${row.label}`)
      Divider().color(DIVIDER).strokeWidth(0.5)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}
