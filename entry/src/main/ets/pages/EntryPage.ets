import { PageFrame, SectionView } from '../components/Widgets';
import { entrySections, Section } from '../logic/Describe';
import { Store } from '../logic/Store';

@Component
export struct EntryPage {
  @State sections: Section[] = [];

  aboutToAppear(): void {
    if (Store.entry !== null) {
      this.sections = entrySections(Store.entry);
    }
  }

  build() {
    PageFrame({ title: 'Entry' }) {
      ForEach(this.sections, (section: Section) => {
        SectionView({ section: section })
      }, (section: Section, index: number) => `${index}:${section.title}`)
    }
  }
}
