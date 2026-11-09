// Ported from ROME rome-modules/src/main/java/com/rometools/modules/opensearch/impl/OpenSearchModuleParser.java (Apache-2.0)
import { Element, Namespace, Parent } from '../../../xml/Dom';
import { Module } from '../../../feed/module/Module';
import { Link } from '../../../feed/atom/Link';
import { ModuleParser } from '../../../io/ModuleParser';
import { Integers } from '../../../utils/Integers';
import { parseJavaInt } from '../../../utils/JavaMath';
import { JavaUrl, MalformedURLException, parseUrl } from '../../../utils/JavaNet';
import { NumberFormatException } from '../../../utils/Exceptions';
import { OSQuery } from '../entity/OSQuery';
import { OpenSearchModule } from '../OpenSearchModule';

const OS_NS: Namespace = Namespace.getNamespace('opensearch', OpenSearchModule.URI);

function parseQuery(e: Element): OSQuery {
  const query = new OSQuery();
  query.role = e.getAttributeValue('role');
  query.osd = e.getAttributeValue('osd');
  query.searchTerms = e.getAttributeValue('searchTerms');
  query.title = e.getAttributeValue('title');
  // One try for both, as in ROME: a bad totalResults also skips startPage.
  try {
    let att = e.getAttributeValue('totalResults');
    if (att !== null) {
      query.totalResults = parseJavaInt(att);
    }
    att = e.getAttributeValue('startPage');
    if (att !== null) {
      query.startPage = parseJavaInt(att);
    }
  } catch (ex) {
    if (!(ex instanceof NumberFormatException)) {
      throw ex as Error;
    }
  }
  return query;
}

// ROME resolves a relative href as "" (not the href) against the xml:base chain.
function parseLink(e: Element, baseURI: JavaUrl | null): Link {
  const link = new Link();
  let att = e.getAttributeValue('rel');
  if (att !== null) {
    link.rel = att;
  }
  att = e.getAttributeValue('type');
  if (att !== null) {
    link.type = att;
  }
  att = e.getAttributeValue('href');
  if (att !== null) {
    link.href = isRelativeURI(att) ? resolveURI(baseURI, e, '') : att;
  }
  att = e.getAttributeValue('hreflang');
  if (att !== null) {
    link.hreflang = att;
  }
  return link;
}

function isRelativeURI(uri: string): boolean {
  return !(uri.startsWith('http://') || uri.startsWith('https://') || uri.startsWith('/'));
}

function resolveURI(baseURI: JavaUrl | null, parent: Parent | null, url: string): string {
  url = url === '.' || url === './' ? '' : url;
  if (isRelativeURI(url) && parent !== null && parent instanceof Element) {
    const element = parent as Element;
    const baseAtt = element.getAttribute('base', Namespace.XML_NAMESPACE);
    let xmlBase = baseAtt === null ? '' : baseAtt.getValue();
    if (!isRelativeURI(xmlBase) && !xmlBase.endsWith('/')) {
      xmlBase = xmlBase.substring(0, xmlBase.lastIndexOf('/') + 1);
    }
    return resolveURI(baseURI, element.getParent(), xmlBase + url);
  } else if (isRelativeURI(url) && parent === null) {
    return (baseURI === null ? 'null' : baseURI.toString()) + url;
  } else if (baseURI !== null && url.startsWith('/')) {
    let hostURI = baseURI.protocol + '://' + baseURI.host;
    if (baseURI.port !== baseURI.defaultPort) {
      hostURI = hostURI + ':' + baseURI.port;
    }
    return hostURI + url;
  }
  return url;
}

// A link without href throws, as ROME's NullPointerException does.
function findBaseURI(root: Element): JavaUrl | null {
  for (const link of root.getChildren('link', OS_NS)) {
    let href = link.getAttribute('href')!.getValue();
    const rel = link.getAttribute('rel', OS_NS);
    if (rel === null || rel.getValue() === 'alternate') {
      href = resolveURI(null, link, href);
      try {
        return parseUrl(href);
      } catch (e) {
        if (!(e instanceof MalformedURLException)) {
          throw e as Error;
        }
      }
    }
  }
  return null;
}

export class OpenSearchModuleParser implements ModuleParser {
  getNamespaceUri(): string {
    return OpenSearchModule.URI;
  }

  parse(dcRoot: Element): Module | null {
    const baseURI = findBaseURI(dcRoot);
    let foundSomething = false;
    const osm = new OpenSearchModule();

    let e = dcRoot.getChild('totalResults', OS_NS);
    if (e !== null) {
      const totalResults = Integers.parse(e.getText());
      if (totalResults !== null) {
        osm.totalResults = totalResults;
        foundSomething = true;
      }
    }
    e = dcRoot.getChild('itemsPerPage', OS_NS);
    if (e !== null) {
      const itemsPerPage = Integers.parse(e.getText());
      if (itemsPerPage !== null) {
        osm.itemsPerPage = itemsPerPage;
        foundSomething = true;
      }
    }
    e = dcRoot.getChild('startIndex', OS_NS);
    if (e !== null) {
      const startIndex = Integers.parse(e.getText());
      if (startIndex !== null) {
        osm.startIndex = startIndex;
        foundSomething = true;
      }
    }

    const queries = dcRoot.getChildren('Query', OS_NS);
    if (queries.length > 0) {
      osm.queries = queries.map((q: Element) => parseQuery(q));
    }

    e = dcRoot.getChild('link', OS_NS);
    if (e !== null) {
      osm.link = parseLink(e, baseURI);
    }

    return foundSomething ? osm : null;
  }
}
