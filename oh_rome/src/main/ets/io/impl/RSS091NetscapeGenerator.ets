// Ported from ROME rome/src/main/java/com/rometools/rome/io/impl/RSS091NetscapeGenerator.java (Apache-2.0)
import { DocType, Document, Element } from '../../xml/Dom';
import { RSS091UserlandGenerator } from './RSS091UserlandGenerator';
import { ELEMENT_NAME, PUBLIC_ID, SYSTEM_ID } from './RSS091NetscapeParser';

export class RSS091NetscapeGenerator extends RSS091UserlandGenerator {
  constructor(type: string = 'rss_0.91N', version: string = '0.91') {
    super(type, version);
  }

  protected createDocument(root: Element): Document {
    const doc = new Document(root);
    doc.setDocType(new DocType(ELEMENT_NAME, PUBLIC_ID, SYSTEM_ID));
    return doc;
  }

  protected getTextInputLabel(): string {
    return 'textinput';
  }

  protected isHourFormat24(): boolean {
    return false;
  }
}
