import { CODE_BACKGROUND, SECONDARY_TEXT, TEXT } from '../common/Theme';
import { ActionButton, ErrorBox, Note, PageFrame, Tile } from '../components/Widgets';
import { describeError, ErrorKind } from '../logic/Errors';
import { fetchFeed } from '../logic/Fetch';
import { parseOpml, Subscription, subscriptionsOf } from '../logic/Opml';
import { PRESETS_OPML } from '../logic/Presets';
import { FeedSource, parseDetailed } from '../logic/Source';
import { Store } from '../logic/Store';
import { formatBytes } from '../logic/Text';

@Component
export struct ReaderPage {
  @Consume('stack') stack: NavPathStack;
  @State subscriptions: Subscription[] = [];
  @State url: string = '';
  @State loading: string = '';
  @State status: string = '';
  @State errorHeading: string = '';
  @State errorMessage: string = '';

  aboutToAppear(): void {
    try {
      this.subscriptions = Store.added.concat(subscriptionsOf(parseOpml(PRESETS_OPML)));
    } catch (e) {
      const error = describeError(ErrorKind.PARSE, e as Object);
      this.errorHeading = `Preset list: ${error.title}`;
      this.errorMessage = error.message;
      this.subscriptions = Store.added.slice();
    }
  }

  private showError(heading: string, message: string): void {
    this.errorHeading = heading;
    this.errorMessage = message;
  }

  private async open(subscription: Subscription): Promise<void> {
    if (this.loading !== '') {
      return;
    }
    this.loading = subscription.url;
    this.errorHeading = '';
    this.status = `Fetching ${subscription.name}…`;
    const result = await fetchFeed(subscription.url);
    this.loading = '';
    if (result.error !== null || result.bytes === null) {
      this.status = '';
      this.showError(`${subscription.name}: ${result.error?.title ?? 'No body'}`, result.error?.message ?? '');
      return;
    }
    this.status = `${subscription.name}: ${formatBytes(result.bytes.length)} in ${result.ms} ms` +
      (result.contentType === '' ? '' : `, ${result.contentType}`);
    const source = FeedSource.ofHttp(subscription.name, subscription.url, result.bytes, result.contentType);
    const start = Date.now();
    try {
      const parsed = parseDetailed(source);
      this.status += `, decoded as ${parsed.encoding}, parsed in ${Date.now() - start} ms`;
      Store.open(source, parsed.feed);
      this.stack.pushPathByName('feed', null);
    } catch (e) {
      const error = describeError(ErrorKind.PARSE, e as Object);
      this.showError(`${subscription.name}: ${error.title}`, error.message);
    }
  }

  private addUrl(): void {
    const url = this.url.trim();
    if (!/^https?:\/\/\S+$/.test(url)) {
      this.showError('Not a feed URL', 'Enter an address that starts with http:// or https://');
      return;
    }
    let subscription = this.subscriptions.find((s: Subscription) => s.url === url);
    if (subscription === undefined) {
      subscription = new Subscription(url.replace(/^https?:\/\//, ''), 'Added by you', url, 'Added');
      Store.added.unshift(subscription);
      this.subscriptions = [subscription].concat(this.subscriptions);
    }
    this.url = '';
    this.open(subscription);
  }

  build() {
    PageFrame({ title: 'Reader' }) {
      TextInput({ placeholder: 'https://example.com/feed.xml', text: this.url })
        .fontSize(13)
        .fontColor(TEXT)
        .placeholderColor(SECONDARY_TEXT)
        .backgroundColor(CODE_BACKGROUND)
        .type(InputType.URL)
        .onChange((value: string) => {
          this.url = value;
        })
        .onSubmit(() => {
          this.addUrl();
        })
      ActionButton({
        label: 'Subscribe and open',
        active: this.url.trim() !== '' && this.loading === '',
        onTap: () => {
          this.addUrl();
        }
      })
      if (this.status !== '') {
        Note({ text: this.status })
      }
      if (this.errorHeading !== '') {
        ErrorBox({ heading: this.errorHeading, message: this.errorMessage })
      }
      ForEach(this.subscriptions, (subscription: Subscription) => {
        Tile({
          title: subscription.url === this.loading ? `${subscription.name} (loading…)` : subscription.name,
          subtitle: subscription.note === '' ? subscription.url : `${subscription.note} · ${subscription.group}`,
          onTap: () => {
            this.open(subscription);
          }
        })
      }, (subscription: Subscription) => `${subscription.url}|${subscription.url === this.loading}`)
      Tile({
        title: 'Paste XML instead',
        subtitle: 'For a feed you have as text',
        onTap: () => {
          this.stack.pushPathByName('paste', null);
        }
      })
    }
  }
}
