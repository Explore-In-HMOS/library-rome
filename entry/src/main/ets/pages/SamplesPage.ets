import { ErrorBox, PageFrame, Tile } from '../components/Widgets';
import { describeError, ErrorKind } from '../logic/Errors';
import { FeedSource, parseSource } from '../logic/Source';
import { Store } from '../logic/Store';
import { Sample, SAMPLES } from '../samples/Samples';

@Component
export struct SamplesPage {
  @Consume('stack') stack: NavPathStack;
  @State errorHeading: string = '';
  @State errorMessage: string = '';

  private open(sample: Sample): void {
    const source = FeedSource.ofText(`Sample: ${sample.name}`, sample.xml);
    try {
      Store.open(source, parseSource(source));
      this.errorHeading = '';
      this.stack.pushPathByName('feed', null);
    } catch (e) {
      const error = describeError(ErrorKind.PARSE, e as Object);
      this.errorHeading = `${sample.name}: ${error.title}`;
      this.errorMessage = error.message;
    }
  }

  build() {
    PageFrame({ title: 'Samples' }) {
      if (this.errorHeading !== '') {
        ErrorBox({ heading: this.errorHeading, message: this.errorMessage })
      }
      ForEach(SAMPLES, (sample: Sample) => {
        Tile({
          title: sample.name,
          subtitle: `${sample.xml.length} characters`,
          onTap: () => {
            this.open(sample);
          }
        })
      }, (sample: Sample) => sample.name)
    }
  }
}
