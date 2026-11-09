// Ported from ROME rome/src/main/java/com/rometools/rome/io/impl/RSS091NetscapeParser.java (Apache-2.0)
import { Document } from '../../xml/Dom';
import { RSS091UserlandParser } from './RSS091UserlandParser';

export const ELEMENT_NAME: string = 'rss';
export const PUBLIC_ID: string = '-//Netscape Communications//DTD RSS 0.91//EN';
export const SYSTEM_ID: string = 'http://my.netscape.com/publish/formats/rss-0.91.dtd';

export class RSS091NetscapeParser extends RSS091UserlandParser {
  constructor(type: string = 'rss_0.91N') {
    super(type);
  }

  isMyType(document: Document): boolean {
    const rssRoot = document.getRootElement();
    const version = rssRoot.getAttribute('version');
    const docType = document.getDocType();
    return rssRoot.getName() === ELEMENT_NAME && version !== null && version.getValue() === this.getRSSVersion() &&
      docType !== null && docType.getElementName() === ELEMENT_NAME && docType.getPublicID() === PUBLIC_ID &&
      docType.getSystemID() === SYSTEM_ID;
  }

  protected getTextInputLabel(): string {
    return 'textinput';
  }
}
