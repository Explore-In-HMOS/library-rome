import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { ErrorInfo, ErrorKind } from './Errors';

export class FetchResult {
  readonly bytes: Uint8Array | null;
  readonly error: ErrorInfo | null;
  readonly contentType: string;
  readonly ms: number;

  constructor(bytes: Uint8Array | null, error: ErrorInfo | null, contentType: string, ms: number) {
    this.bytes = bytes;
    this.error = error;
    this.contentType = contentType;
    this.ms = ms;
  }
}

const CONNECT_TIMEOUT_MS = 15000;
const READ_TIMEOUT_MS = 30000;

// The body comes back as bytes on purpose: the library's XmlReader picks the encoding from the BOM and the XML prolog,
// as ROME does, so a non-UTF-8 feed is decoded by the library and not by the HTTP stack.
export async function fetchFeed(url: string): Promise<FetchResult> {
  const start = Date.now();
  const request = http.createHttp();
  const header: Record<string, string> = {
    'Accept': 'application/rss+xml, application/atom+xml, application/rdf+xml, application/xml, text/xml, */*'
  };
  try {
    const response = await request.request(url, {
      method: http.RequestMethod.GET,
      expectDataType: http.HttpDataType.ARRAY_BUFFER,
      connectTimeout: CONNECT_TIMEOUT_MS,
      readTimeout: READ_TIMEOUT_MS,
      header: header
    });
    const ms = Date.now() - start;
    const headers = response.header as Record<string, string>;
    const contentType = headers['content-type'] ?? headers['Content-Type'] ?? '';
    if (response.responseCode < 200 || response.responseCode >= 300) {
      return new FetchResult(null, new ErrorInfo(ErrorKind.HTTP, `HTTP ${response.responseCode}`,
        `The server answered ${response.responseCode} for ${url}`), contentType, ms);
    }
    if (!(response.result instanceof ArrayBuffer)) {
      return new FetchResult(null, new ErrorInfo(ErrorKind.NETWORK, 'Unexpected body',
        'The HTTP stack did not return the body as bytes'), contentType, ms);
    }
    return new FetchResult(new Uint8Array(response.result as ArrayBuffer), null, contentType, ms);
  } catch (e) {
    const error = e as BusinessError;
    return new FetchResult(null, new ErrorInfo(ErrorKind.NETWORK, `Code ${error.code}`, error.message ?? String(e)), '',
      Date.now() - start);
  } finally {
    request.destroy();
  }
}
