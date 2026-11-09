// Ported from ROME rome/src/main/java/com/rometools/rome/io/impl/SyModuleParser.java (Apache-2.0)
import { Element, Namespace } from '../../xml/Dom';
import { Module } from '../../feed/module/Module';
import { SyModule } from '../../feed/module/SyModule';
import { parseJavaInt } from '../../utils/JavaMath';
import { Strings } from '../../utils/Strings';
import { ModuleParser } from '../ModuleParser';
import { DateParser } from './DateParser';

export class SyModuleParser implements ModuleParser {
  getNamespaceUri(): string {
    return SyModule.URI;
  }

  private getDCNamespace(): Namespace {
    return Namespace.getNamespace(SyModule.URI);
  }

  parse(syndRoot: Element): Module | null {
    let foundSomething = false;
    const sm = new SyModule();

    const updatePeriod = syndRoot.getChild('updatePeriod', this.getDCNamespace());
    if (updatePeriod !== null) {
      foundSomething = true;
      sm.updatePeriod = Strings.trim(updatePeriod.getText());
    }

    const updateFrequency = syndRoot.getChild('updateFrequency', this.getDCNamespace());
    if (updateFrequency !== null) {
      foundSomething = true;
      sm.updateFrequency = parseJavaInt(Strings.trim(updateFrequency.getText())!);
    }

    const updateBase = syndRoot.getChild('updateBase', this.getDCNamespace());
    if (updateBase !== null) {
      foundSomething = true;
      sm.updateBase = DateParser.parseDate(updateBase.getText());
    }

    return foundSomething ? sm : null;
  }
}
