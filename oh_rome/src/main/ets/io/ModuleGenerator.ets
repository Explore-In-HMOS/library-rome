// Ported from ROME rome/src/main/java/com/rometools/rome/io/ModuleGenerator.java (Apache-2.0)
import { Element, Namespace } from '../xml/Dom';
import { Module } from '../feed/module/Module';

export interface ModuleGenerator {
  getNamespaceUri(): string;

  getNamespaces(): Namespace[];

  generate(module: Module, element: Element): void;
}
