// Ported from ROME rome/src/main/java/com/rometools/rome/io/impl/SyModuleGenerator.java (Apache-2.0)
import { Element, Namespace } from '../../xml/Dom';
import { Module } from '../../feed/module/Module';
import { SyModule } from '../../feed/module/SyModule';
import { ModuleGenerator } from '../ModuleGenerator';
import { DateParser } from './DateParser';

const SY_URI: string = 'http://purl.org/rss/1.0/modules/syndication/';
const SY_NS: Namespace = Namespace.getNamespace('sy', SY_URI);

export class SyModuleGenerator implements ModuleGenerator {
  getNamespaceUri(): string {
    return SY_URI;
  }

  getNamespaces(): Namespace[] {
    return [SY_NS];
  }

  generate(module: Module, element: Element): void {
    const syModule = module as SyModule;

    const updatePeriod = syModule.updatePeriod;
    if (updatePeriod !== null) {
      const updatePeriodElement = new Element('updatePeriod', SY_NS);
      updatePeriodElement.addContent(updatePeriod);
      element.addContent(updatePeriodElement);
    }

    const updateFrequencyElement = new Element('updateFrequency', SY_NS);
    updateFrequencyElement.addContent(String(syModule.updateFrequency));
    element.addContent(updateFrequencyElement);

    const updateBase = syModule.updateBase;
    if (updateBase !== null) {
      const updateBaseElement = new Element('updateBase', SY_NS);
      updateBaseElement.addContent(DateParser.formatW3CDateTime(updateBase));
      element.addContent(updateBaseElement);
    }
  }
}
