import { SyndEntry } from '@explore-in-hmos/oh_rome';
import { ActionButton, Note, PageFrame, SectionView, Tile } from '../components/Widgets';
import { entryKey, entrySummary, feedSections, Section } from '../logic/Describe';
import { Store } from '../logic/Store';
import { formatBytes } from '../logic/Text';

@Component
export struct FeedPage {
  @Consume('stack') stack: NavPathStack;
  @State sections: Section[] = [];
  @State entries: SyndEntry[] = [];
  @State origin: string = '';

  aboutToAppear(): void {
    const feed = Store.feed;
    const source = Store.source;
    if (feed === null || source === null) {
      return;
    }
    this.sections = feedSections(feed);
    this.entries = feed.entries;
    this.origin = `${source.label}, ${formatBytes(source.size)}` +
      (source.bytes === null ? ' of text' : ` of bytes, Content-Type: ${source.contentType ?? 'none'}`);
  }

  build() {
    PageFrame({ title: Store.feed?.title ?? 'Feed' }) {
      Note({ text: this.origin })
      ActionButton({
        label: 'Convert to another format',
        onTap: () => {
          this.stack.pushPathByName('convert', null);
        }
      })
      ForEach(this.sections, (section: Section) => {
        SectionView({ section: section })
      }, (section: Section) => section.title)
      ForEach(this.entries, (entry: SyndEntry, index: number) => {
        Tile({
          title: entry.title ?? '(no title)',
          subtitle: entrySummary(entry),
          onTap: () => {
            Store.entry = entry;
            this.stack.pushPathByName('entry', null);
          }
        })
      }, (entry: SyndEntry, index: number) => entryKey(entry, index))
    }
  }
}
