import { BACKGROUND, END_PADDING, ROUND, SECONDARY_TEXT, SIDE_PADDING, TEXT } from '../common/Theme';
import { Tile } from '../components/Widgets';
import { AboutPage } from './AboutPage';
import { ConvertPage } from './ConvertPage';
import { EntryPage } from './EntryPage';
import { FeedPage } from './FeedPage';
import { GeneratePage } from './GeneratePage';
import { OpmlPage } from './OpmlPage';
import { PastePage } from './PastePage';
import { ReaderPage } from './ReaderPage';
import { SamplesPage } from './SamplesPage';

class MenuItem {
  readonly route: string;
  readonly title: string;
  readonly note: string;

  constructor(route: string, title: string, note: string) {
    this.route = route;
    this.title = title;
    this.note = note;
  }
}

const MENU: MenuItem[] = [
  new MenuItem('reader', 'Reader', 'Real feeds from the web, or any feed URL'),
  new MenuItem('samples', 'Samples', 'Bundled feeds for every format and module, offline'),
  new MenuItem('paste', 'Paste XML', 'Parse a feed you paste in'),
  new MenuItem('generate', 'Generate', 'Build a feed from scratch in any format'),
  new MenuItem('opml', 'OPML', 'Read and write a subscription list'),
  new MenuItem('about', 'About', 'Version, origin, license, formats')
];

@Entry
@Component
struct Index {
  @Provide('stack') stack: NavPathStack = new NavPathStack();

  @Builder
  routes(name: string) {
    if (name === 'reader') {
      ReaderPage()
    } else if (name === 'samples') {
      SamplesPage()
    } else if (name === 'paste') {
      PastePage()
    } else if (name === 'feed') {
      FeedPage()
    } else if (name === 'entry') {
      EntryPage()
    } else if (name === 'convert') {
      ConvertPage()
    } else if (name === 'generate') {
      GeneratePage()
    } else if (name === 'opml') {
      OpmlPage()
    } else if (name === 'about') {
      AboutPage()
    }
  }

  build() {
    Navigation(this.stack) {
      Scroll() {
        Column({ space: 4 }) {
          Text('oh_rome')
            .fontSize(ROUND ? 18 : 24)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT)
            .width('100%')
            .textAlign(ROUND ? TextAlign.Center : TextAlign.Start)
          Text('RSS, Atom and OPML for HarmonyOS')
            .fontSize(12)
            .fontColor(SECONDARY_TEXT)
            .width('100%')
            .textAlign(ROUND ? TextAlign.Center : TextAlign.Start)
          ForEach(MENU, (item: MenuItem) => {
            Tile({
              title: item.title,
              subtitle: item.note,
              onTap: () => {
                this.stack.pushPathByName(item.route, null);
              }
            })
          }, (item: MenuItem) => item.route)
        }
        .width('100%')
        .padding({ left: SIDE_PADDING, right: SIDE_PADDING, top: END_PADDING, bottom: END_PADDING })
      }
      .width('100%')
      .height('100%')
      .align(Alignment.Top)
      .scrollBar(BarState.Off)
    }
    .navDestination(this.routes)
    .mode(NavigationMode.Stack)
    .hideTitleBar(true)
    .hideToolBar(true)
    .backgroundColor(BACKGROUND)
  }
}
