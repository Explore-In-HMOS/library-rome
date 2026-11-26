import { deviceInfo } from '@kit.BasicServicesKit';
import { WireFeedInput, WireFeedOutput } from '@explore-in-hmos/oh_rome';
import { ROUND } from '../common/Theme';
import { PageFrame, SectionView } from '../components/Widgets';
import { DetailRow, Section } from '../logic/Describe';

// The package version is in oh_rome/oh-package.json5; update both together.
export const LIBRARY_VERSION = '1.0.0';

function sections(): Section[] {
  return [
    new Section('Library', [
      new DetailRow('Package', `@explore-in-hmos/oh_rome ${LIBRARY_VERSION}`),
      new DetailRow('Origin', 'ArkTS port of ROME (github.com/rometools/rome) at commit 6b4a7e8'),
      new DetailRow('License', 'Apache-2.0, like ROME. The XML code follows JDOM 2.0.6.1 (JDOM license).'),
      new DetailRow('Network', 'The library fetches nothing; this demo downloads feeds with @kit.NetworkKit and passes the bytes in.')
    ]),
    new Section('Formats', [
      new DetailRow('Reads', WireFeedInput.getSupportedFeedTypes().sort().join(', ')),
      new DetailRow('Writes', WireFeedOutput.getSupportedFeedTypes().sort().join(', '))
    ]),
    new Section('Device', [
      new DetailRow('Type', deviceInfo.deviceType),
      new DetailRow('Round-screen layout', ROUND ? 'yes' : 'no')
    ])
  ];
}

@Component
export struct AboutPage {
  private sections: Section[] = sections();

  build() {
    PageFrame({ title: 'About' }) {
      ForEach(this.sections, (section: Section) => {
        SectionView({ section: section })
      }, (section: Section) => section.title)
    }
  }
}
